// Windows renderer session primitives for CJGUI.
//
// HWND, D3D11 and DXGI objects stay inside a bounded session table. The Cangjie
// owner supplies scalar/POD identities and remains the document/event owner.
// This file deliberately returns named refusal statuses for scene/text work
// that is not installed yet; it never reports an empty renderer as presented.
#define COBJMACROS
#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x0A00
#define INITGUID
#include <initguid.h>
#include <windows.h>
#include <windowsx.h>
#include <d3d11.h>
#include <d3dcompiler.h>
#include <dwrite.h>
#include <dxgi.h>
#include <imm.h>
#include <errno.h>
#include <float.h>
#include <limits.h>
#include <math.h>
#include <winreg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cjgui_internal_renderer.h"
#include "cjgui_windows_wic.h"

#define CJGUI_WINDOWS_SESSION_CAPACITY 2
#define CJGUI_WINDOWS_EVENT_CAPACITY 256
#define CJGUI_WINDOWS_EVENT_TEXT_BUDGET (4u * 1024u * 1024u)
#define CJGUI_WINDOWS_SCENE_NODE_CAPACITY 1024
#define CJGUI_WINDOWS_TEXT_BYTE_CAPACITY (24u * 1024u * 1024u)
#define CJGUI_WINDOWS_TEXT_SCENE_TEXTURE_CAPACITY (24u * 1024u * 1024u)
#define CJGUI_WINDOWS_TEXT_SESSION_TEXTURE_CAPACITY (64u * 1024u * 1024u)
#define CJGUI_WINDOWS_TEXT_SESSION_SCRATCH_CAPACITY (32u * 1024u * 1024u)
#define CJGUI_WINDOWS_TEXT_FLIGHT_CAPACITY 4u
#define CJGUI_WINDOWS_TEXT_FLIGHT_LEASE_CAPACITY (CJGUI_WINDOWS_SCENE_NODE_CAPACITY * 3u)
#define CJGUI_WINDOWS_IMAGE_CACHE_CAPACITY 16u
#define CJGUI_WINDOWS_IMAGE_ENCODED_CAPACITY (8u * 1024u * 1024u)
#define CJGUI_WINDOWS_IMAGE_DECODED_CAPACITY (16u * 1024u * 1024u)
#define CJGUI_WINDOWS_IMAGE_SESSION_CAPACITY (32u * 1024u * 1024u)
#define CJGUI_WINDOWS_TEXT_FLIGHT_HASH_CAPACITY 4096u
#define CJGUI_WINDOWS_TEXT_RUN_CAPACITY 1024u
#define CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY (1024u * 1024u)
/* 通用有界准备（R7）。私有准备图不是 present 票据，也不随产品文件上限扩大：
   它拿一份独立的字节额度，节点数与已接受场景同界。退休队列给中途取消留下
   有界回收，容量不足时具名拒绝并保留旧 accepted。 */
#define CJGUI_WINDOWS_PREPARATION_BYTE_CAPACITY (8u * 1024u * 1024u)
/* 同时存活私有图上限：1 个正在准备 + 至多 3 个退休中。 */
#define CJGUI_WINDOWS_PREPARATION_GRAPH_CAPACITY 4u
/* 一次 advance 允许推进的最大单元数；退出条件还有绝对 deadline 与无进展。 */
#define CJGUI_WINDOWS_PREPARATION_UNIT_LIMIT 64u
/* 单个不可抢占排版/光栅单元预留的尾部额度（与共同 Mac 的 12ms 同口径）。 */
#define CJGUI_WINDOWS_PREPARATION_DEADLINE_RESERVE_NS 12000000ull
/* 一次退休持续回收的固定允许量；owner deadline 更早时以 deadline 为准。 */
#define CJGUI_WINDOWS_RETIREMENT_ALLOWANCE_NS 1000000ull
#define CJGUI_WINDOWS_CLASS L"CjguiWindowsRendererWindowV1"
#define CJGUI_WINDOWS_TITLE L"CJGUI"

typedef struct CjguiWindowsRendererSession CjguiWindowsRendererSession;

typedef struct CjguiWindowsTextTextureLease {
    uint32_t refs;
    uint64_t bytes;
    uint64_t *sessionBytesInUse;
    uint64_t *sessionCountInUse;
    ID3D11Texture2D *texture;
    ID3D11ShaderResourceView *view;
    /* Image CPU pixels are immutable and share exactly this lease lifetime.
       They let a replacement device restore a known-good image without reading
       a file that may now contain invalid bytes. Text leases leave these zero. */
    uint8_t *imagePixels, *imageEncoded;
    uint32_t imageEncodedLength;
    uint64_t imageStorageBytes;
    uint32_t imageWidth, imageHeight;
    uint64_t *imageCpuBytesInUse;
} CjguiWindowsTextTextureLease;

typedef struct CjguiWindowsImageResource {
    char *path, *identifier;
    uint64_t version, access;
    CjguiWindowsTextTextureLease *lease;
} CjguiWindowsImageResource;

typedef struct CjguiWindowsTextFlight {
    ID3D11Query *query;
    CjguiWindowsTextTextureLease *leases[CJGUI_WINDOWS_TEXT_FLIGHT_LEASE_CAPACITY];
    uint32_t leaseCount;
    uint8_t pending;
    uint8_t recording;
} CjguiWindowsTextFlight;

typedef struct CjguiWindowsTextRasterRect {
    double x, y, width, height;
} CjguiWindowsTextRasterRect;

typedef struct CjguiWindowsSceneNode {
    CjguiInternalRendererComposableNode node;
    CjguiInternalRendererComposableGeometry geometry;
    char *label;
    char *value;
    char *imageResourcePath;
    char *imageResourceId;
    uint64_t imageResourceVersion;
    CjguiWindowsTextTextureLease *imageLease;
    char *semanticId;
    char *bindingKey;
    char *rowKey;
    char *parentRowKey;
    char *semanticLabel;
    char *textRuns;
    IDWriteTextLayout *textLayout;
    IDWriteTextLayout *labelTextLayout;
    CjguiWindowsTextTextureLease *textLease;
    CjguiWindowsTextTextureLease *labelTextLease;
    ID3D11Texture2D *textTexture;
    ID3D11ShaderResourceView *textView;
    ID3D11Texture2D *labelTextTexture;
    ID3D11ShaderResourceView *labelTextView;
    uint32_t textTextureWidth;
    uint32_t textTextureHeight;
    uint32_t labelTextureWidth;
    uint32_t labelTextureHeight;
    double textLogicalOffsetX;
    double textLogicalWidth;
    double labelLogicalWidth;
    /* Private accepted viewport, in DWrite logical coordinates. The document
       and layout lease remain unchanged when this value moves. */
    double multilineScrollY;
    CjguiWindowsTextRasterRect textRasterRect, labelRasterRect;
    uint64_t textDpi;
    uint64_t layoutLease;
    /* 排版输入指纹：正文/label/约束盒/字体/DPI/文本装饰串相同时复用已有
       排版与租约，不因纯重设换 lease 误杀进行中的按压/选择连续性；
       任一真实排版输入变化即重建并换 lease，严格门继续生效。0 表未知。 */
    uint64_t textLayoutInputKey;
    uint64_t textMaskNonzeroPixels;
    uint64_t ownedBytes;
    uint8_t hasNode;
    uint8_t candidateValueStaged;
    uint8_t candidateRunsPending;
    /* configure retained this exact node/body/binding. Semantic identity
       setters may invalidate it; only an explicit node/body stage replaces it.
       nodeId/resourceId/kind/epoch have no independent mutating setter. */
    uint8_t candidateRetainedBindingValid;
    uint8_t hasGeometry;
} CjguiWindowsSceneNode;

typedef struct CjguiWindowsScene {
    uint64_t version;
    uint32_t count;
    uint64_t ownedBytes;
    CjguiWindowsSceneNode *nodes;
    uint8_t configured;
} CjguiWindowsScene;

typedef struct CjguiWindowsTextRunDeclaration {
    uint64_t nodeId;
    char *encoded;
} CjguiWindowsTextRunDeclaration;

typedef struct CjguiWindowsTextStyleRun {
    uint32_t start16;
    uint32_t end16;
    FLOAT fontSize;
    uint32_t fontWeight;
    uint32_t fontFamily;
    FLOAT red, green, blue, alpha;
    FLOAT backgroundRed, backgroundGreen, backgroundBlue, backgroundAlpha;
    uint8_t hasBackground;
    uint8_t selectionBackgroundOnly;
} CjguiWindowsTextStyleRun;

typedef struct CjguiWindowsTextColorEffect {
    const IUnknownVtbl *lpVtbl;
    volatile LONG refs;
    FLOAT red, green, blue, alpha;
} CjguiWindowsTextColorEffect;

typedef struct CjguiWindowsVertex {
    FLOAT x, y, u, v;
} CjguiWindowsVertex;

typedef struct CjguiWindowsTextRenderer CjguiWindowsTextRenderer;
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
typedef struct CjguiWindowsSceneContractTextDiagnostic {
    uint64_t glyphRunCalls;
    uint32_t glyphCount;
    uint32_t activeTextureType;
    FLOAT fontEmSize;
    int32_t analysisHr;
    int32_t boundsAliasHr;
    int32_t boundsClearTypeHr;
    int32_t alphaTextureHr;
    int32_t drawHr;
    int32_t rendererFailureHr;
    int32_t layoutMetricsHr;
    LONG aliasLeft, aliasTop, aliasRight, aliasBottom;
    LONG clearTypeLeft, clearTypeTop, clearTypeRight, clearTypeBottom;
    FLOAT layoutWidthIncludingTrailingWhitespace;
    FLOAT layoutHeight;
    uint32_t layoutLineCount;
    uint32_t reserved;
    uint64_t alphaTextureNonzero;
    uint64_t compositeWrites;
    uint64_t maskNonzero;
    uint64_t textureNonzero;
} CjguiWindowsSceneContractTextDiagnostic;
#endif
typedef struct CjguiWindowsTextRendererVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(CjguiWindowsTextRenderer *, REFIID, void **);
    ULONG (STDMETHODCALLTYPE *AddRef)(CjguiWindowsTextRenderer *);
    ULONG (STDMETHODCALLTYPE *Release)(CjguiWindowsTextRenderer *);
    HRESULT (STDMETHODCALLTYPE *IsPixelSnappingDisabled)(CjguiWindowsTextRenderer *, void *, BOOL *);
    HRESULT (STDMETHODCALLTYPE *GetCurrentTransform)(CjguiWindowsTextRenderer *, void *, DWRITE_MATRIX *);
    HRESULT (STDMETHODCALLTYPE *GetPixelsPerDip)(CjguiWindowsTextRenderer *, void *, FLOAT *);
    HRESULT (STDMETHODCALLTYPE *DrawGlyphRun)(CjguiWindowsTextRenderer *, void *, FLOAT, FLOAT,
        DWRITE_MEASURING_MODE, const DWRITE_GLYPH_RUN *, const DWRITE_GLYPH_RUN_DESCRIPTION *, IUnknown *);
    HRESULT (STDMETHODCALLTYPE *DrawUnderline)(CjguiWindowsTextRenderer *, void *, FLOAT, FLOAT,
        const DWRITE_UNDERLINE *, IUnknown *);
    HRESULT (STDMETHODCALLTYPE *DrawStrikethrough)(CjguiWindowsTextRenderer *, void *, FLOAT, FLOAT,
        const DWRITE_STRIKETHROUGH *, IUnknown *);
    HRESULT (STDMETHODCALLTYPE *DrawInlineObject)(CjguiWindowsTextRenderer *, void *, FLOAT, FLOAT,
        IDWriteInlineObject *, BOOL, BOOL, IUnknown *);
} CjguiWindowsTextRendererVtbl;

struct CjguiWindowsTextRenderer {
    const CjguiWindowsTextRendererVtbl *lpVtbl;
    ULONG refs;
    uint8_t *pixels;
    CjguiWindowsRendererSession *session;
    IDWriteFactory *factory;
    UINT width;
    UINT height;
    FLOAT pixelsPerDip;
    FLOAT rasterOriginX, rasterOriginY;
    FLOAT defaultRed, defaultGreen, defaultBlue, defaultAlpha;
    HRESULT failure;
    uint8_t budgetRejected;
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    CjguiWindowsSceneContractTextDiagnostic diagnostic;
#endif
};

/* installed-range 旁带：每笔已捕获输入一条 claim 记录（环形，连发时多笔在途）。
   框架按“先结算上一笔再取下一笔事件”的次序 claim/copy/ack；环形保留队列语义，
   避免第二笔捕获释放第一笔尚未 ACK 的载荷。 */
#define CJGUI_WINDOWS_RANGE_CLAIM_CAPACITY 32u

typedef struct CjguiWindowsRangeClaimEntry {
    uint64_t seq;
    uint64_t prevSeq;
    uint64_t observedAckSeq;
    int64_t observedAckVersion;
    uint64_t observedSourceStartByte;
    uint64_t observedSourceEndByte;
    uint32_t flags;
    uint32_t rangeStart16;
    uint32_t rangeLength16;
    uint32_t selectionStart16;
    uint32_t selectionEnd16;
    uint64_t sceneVersion;
    char *preBody;
    uint32_t preBodyLength;
    char *replacement;
    uint32_t replacementLength;
    char *postBody;
    uint32_t postBodyLength;
    int claimed;
} CjguiWindowsRangeClaimEntry;

/* UI 线程原始输入环：WndProc 只追加，不做会话逻辑。 */
#define CJGUI_WINDOWS_RAW_RING_CAPACITY 1024u

typedef struct CjguiWindowsRawRecord {
    uint32_t message;
    uint64_t wParam;
    int64_t lParam;
    int64_t modifiers;
    int64_t imeSlot;
    uint64_t wheelSceneVersion;
    uint64_t wheelCoordinateEpoch;
    uint32_t wheelLines;
} CjguiWindowsRawRecord;

/* IME 冻结槽：在 WndProc 回调当场拥有 RESULTSTR/COMPSTR，后续只消费冻结
   字节，不再读取当下 HIMC。slot=-1 表示无冻结内容（沿用既有实时读取）。 */
#define CJGUI_WINDOWS_IME_FROZEN_CAPACITY 16u

typedef struct CjguiWindowsImeFrozen {
    int used;
    uint32_t handledFlags;
    uint8_t readyForRetry;
    uint8_t retryablePressure;
    uint8_t needsResultUpdate;
    char *resultText;
    uint32_t resultBytes;
    char *markedText;
    uint32_t markedBytes;
    uint32_t cursor16;
    uint32_t flags;
    uint64_t compositionId;
    uint64_t bindingEpoch;
} CjguiWindowsImeFrozen;

/* UI dispatcher 命令环：C ABI 入口把会话逻辑封送到 UI 线程执行。
   phase 2 通用信封：堆分配，调用者栈在返回后永不被 UI 线程引用；
   会话只凭 token 在 UI 线程查找，代次与退役检查同在 UI 线程；
   等待一律有界：未开始超时为原子取消（COMMAND_TIMEOUT，可发新命令），
   已开始超时为保留结果（COMMAND_IN_FLIGHT，禁重发副作用，以 reap 取回）。
   UI 线程内重入直接执行，不向自己排队等待。 */
#define CJGUI_WINDOWS_CMD_RING_CAPACITY 64u
#define CJGUI_WINDOWS_CMD_HOLD_CAPACITY 4u
#define CJGUI_WINDOWS_CMD_TIMEOUT_MS 30000u

typedef enum CjguiWindowsCommandKind {
    CJGUI_WINDOWS_CMD_PUMP = 1,
    CJGUI_WINDOWS_CMD_DESTROY = 2,
    CJGUI_WINDOWS_CMD_STOP = 3,
    CJGUI_WINDOWS_CMD_GENERIC = 4
} CjguiWindowsCommandKind;

struct CjguiWindowsRendererSession;
typedef CjguiInternalRendererStatus (*CjguiWindowsUiProc)(
    struct CjguiWindowsRendererSession *s, void *ctx);
typedef void (*CjguiWindowsCtxFree)(void *ctx);

typedef struct CjguiWindowsCommand2 {
    uint64_t commandId;
    uint64_t token;
    uint64_t generation;
    uint32_t kind;
    char apiName[56];
    CjguiWindowsUiProc proc;
    void *ctx;
    CjguiWindowsCtxFree ctxFree;
    DWORD callerTid;
    CjguiInternalRendererStatus status;
    int started;
    int done;
    int cancelled;
    int orphaned;
    int fireAndForget;
    HANDLE doneEvent;
    uint64_t queuedNs;
} CjguiWindowsCommand2;

/* 门内待决输入：门保持期间捕获的原始意图，确认后按捕获顺序兑现；
   非确认结局（取消/取代/冲突/关闭）或满载时进入恢复槽具名保留。
   kind: 0 普通字符，1 导航/删除意图，2 组合更新，3 组合终态。 */
#define CJGUI_WINDOWS_DEFERRED_CAPACITY 32u
#define CJGUI_WINDOWS_DEFERRED_BYTES 262144u
#define CJGUI_WINDOWS_DEFERRED_IME_BYTES 65536u

typedef struct CjguiWindowsDeferredInput {
    uint64_t inputId;
    uint64_t bindingEpoch;
    uint64_t requestId;
    uint32_t kind;
    char *bytes;
    uint32_t length;
    char *extraBytes;
    uint32_t extraLength;
    int64_t modifiers;
    uint32_t repeatCount;
    uint64_t compositionId;
    uint32_t phase;
    uint32_t cursor16;
    uint8_t terminalQueued;
} CjguiWindowsDeferredInput;

#define CJGUI_WINDOWS_FINISH_CONFIRMED 1u
#define CJGUI_WINDOWS_FINISH_CANCELLED 2u
#define CJGUI_WINDOWS_FINISH_SUPERSEDED 3u
#define CJGUI_WINDOWS_FINISH_CONFLICT 4u
#define CJGUI_WINDOWS_FINISH_CLOSED 5u

#define CJGUI_WINDOWS_RECOVERY_NONE 0u
#define CJGUI_WINDOWS_RECOVERY_GATE_OUTCOME 1u
#define CJGUI_WINDOWS_RECOVERY_OVERFLOW 2u

#define CJGUI_WINDOWS_TRACE_CAPACITY 256u
typedef struct CjguiWindowsTraceRow {
    const char *stage;
    uint64_t clockNs,scene,seq,ownerVersion,a,b,c,d,e,f;
} CjguiWindowsTraceRow;

#define CJGUI_WINDOWS_OWNER_TRACE_CAPACITY 8192u
typedef struct CjguiWindowsOwnerTraceRow {
    uint64_t clockNs,session,turn,request,dispatch,generation,span;
    uint32_t kind,phase,tid;
} CjguiWindowsOwnerTraceRow;
static CjguiWindowsOwnerTraceRow g_windowsOwnerTrace[CJGUI_WINDOWS_OWNER_TRACE_CAPACITY];
static SRWLOCK g_windowsOwnerTraceLock = SRWLOCK_INIT;
static INIT_ONCE g_windowsOwnerTraceOnce = INIT_ONCE_STATIC_INIT;
static uint64_t g_windowsOwnerTraceCount;
static int g_windowsOwnerTraceEnabled;
static BOOL CALLBACK windows_owner_trace_init(PINIT_ONCE once,PVOID parameter,PVOID *context) {
    (void)once;(void)parameter;(void)context;
    const char *value=getenv("CJGUI_WINDOWS_TRACE_TIMING");
    g_windowsOwnerTraceEnabled=value && !strcmp(value,"1");
    return TRUE;
}
static int windows_owner_trace_enabled(void) {
    InitOnceExecuteOnce(&g_windowsOwnerTraceOnce,windows_owner_trace_init,NULL,NULL);
    return g_windowsOwnerTraceEnabled;
}
static void windows_owner_trace_dump(FILE *out);

struct CjguiWindowsRendererSession {
    uint64_t token;
    HWND hwnd;
    ID3D11Device *device;
    ID3D11DeviceContext *context;
    IDXGISwapChain *swapChain;
    ID3D11RenderTargetView *renderTarget;
    ID3D11VertexShader *sceneVertexShader;
    ID3D11PixelShader *sceneSolidPixelShader;
    ID3D11PixelShader *sceneMaskPixelShader;
    ID3D11InputLayout *sceneInputLayout;
    ID3D11Buffer *sceneVertexBuffer;
    ID3D11Buffer *sceneColorBuffer;
    ID3D11BlendState *sceneBlendState;
    ID3D11RasterizerState *sceneRasterizer;
    ID3D11SamplerState *sceneSampler;
    IDWriteFactory *writeFactory;
    /* 线程模型（完整 UI dispatcher，phase 1 覆盖 pump/destroy）：
       每个 session 由自持 UI（泵）线程拥有窗口、消息队列与全部会话逻辑；
       C ABI 入口把 pump/destroy 封送为命令并等待完成，其余导出函数按批
       次迁移中。命令在 UI 线程至多执行一次；调用者无限等待 doneEvent，
       UI 线程以有界切片推进。跨线程同步仅用小锁与事件，持有锁期间不做
       user32 调用与无限等待。 */
    CRITICAL_SECTION rawLock;
    CjguiWindowsRawRecord rawRing[CJGUI_WINDOWS_RAW_RING_CAPACITY];
    uint32_t rawHead;
    uint32_t rawTail;
    uint64_t rawDropped;
    uint8_t traceEnabled;
    uint64_t traceCount;
    CjguiWindowsTraceRow traceRows[CJGUI_WINDOWS_TRACE_CAPACITY];
    HANDLE rawWakeEvent;
    CRITICAL_SECTION cmdLock;
    CjguiWindowsCommand2 *cmdRing[CJGUI_WINDOWS_CMD_RING_CAPACITY];
    uint32_t cmdHead;
    uint32_t cmdTail;
    HANDLE cmdWakeEvent;
    int retiring;
    HANDLE pumpThread;
    DWORD pumpThreadId;
    DWORD ownerThreadId;
    int inputAttached;
    DWORD lastPumpTid;
    HANDLE pumpReadyEvent;
    HANDLE pumpStopEvent;
    CjguiInternalRendererStatus pumpThreadStatus;
    int pumpThreadRunning;
    uint32_t pendingCreateWidth;
    uint32_t pendingCreateHeight;
    CjguiInternalRendererEvent events[CJGUI_WINDOWS_EVENT_CAPACITY];
    CjguiInternalRendererPointerEventGeometry pointerGeometries[CJGUI_WINDOWS_EVENT_CAPACITY];
    uint64_t pointerSessionGenerations[CJGUI_WINDOWS_EVENT_CAPACITY];
    uint64_t pointerCoordinateEpochs[CJGUI_WINDOWS_EVENT_CAPACITY];
    char *eventTextPayloads[CJGUI_WINDOWS_EVENT_CAPACITY];
    uint32_t eventTextLengths[CJGUI_WINDOWS_EVENT_CAPACITY];
    uint32_t eventHead;
    uint32_t eventTail;
    uint32_t eventCount;
    uint32_t eventQueueFull;
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    int64_t contractMouseDiag[20];
    double contractMouseCoordinates[4];
#endif
    uint32_t eventTextBytes;
    uint32_t width;
    uint32_t height;
    uint32_t dpi;
    uint64_t dpiEpoch;
    uint32_t diagnosticTimingEnabled, failureDiagnosticCount;
    uint32_t compositionActive;
    uint32_t closeRequested;
    uint32_t minimized;
    uint32_t sourceInstallPending;
    uint64_t sourceInstallBindingEpoch;
    uint64_t sourceInstallRequestId;
    uint64_t sourceInstallGatedInputs;
    uint32_t sourceInstallProvisional;
    uint32_t sourceInstallOutcome;
    uint64_t sourceInstallProvisionalNonce;
    uint64_t sourceInstallNextNonce;
    uint64_t sourceInstallConfirmedBinding;
    uint64_t sourceInstallConfirmedRequest;
    CjguiWindowsDeferredInput deferredInputs[CJGUI_WINDOWS_DEFERRED_CAPACITY];
    uint32_t deferredHead;
    uint32_t deferredCount;
    uint64_t deferredBytes;
    uint64_t deferredNextId;
    uint64_t deferredDrops;
/* 恢复环必须一次装下结算瞬间全部待决：32 待决＋16 导航持留。
   耗尽即丢载荷，故容量按最坏同时结算证明为 48；drops 仅作防御计数。
   槽按完整输入记录转移责任：kind/修饰/重复/组字/相位/光标/额外载荷与
   主载荷一体保存，drain 经正常消费者取回时原样交还，不做无来源重放。 */
#define CJGUI_WINDOWS_RECOVERY_CAPACITY 48u
    struct {
        char *bytes;
        uint32_t length;
        char *extraBytes;
        uint32_t extraLength;
        uint32_t reason;
        uint32_t outcome;
        uint64_t inputId;
        uint64_t recordId;
        uint32_t handledParts;
        uint64_t bindingEpoch;
        uint64_t requestId;
        uint32_t kind;
        int64_t modifiers;
        uint32_t repeatCount;
        uint64_t compositionId;
        uint32_t phase;
        uint32_t cursor16;
    } recoverySlots[CJGUI_WINDOWS_RECOVERY_CAPACITY];
    uint32_t recoveryHead;
    uint32_t recoveryCount;
    uint64_t recoveryDrops;
    uint64_t recoveryNextId;
#define CJGUI_WINDOWS_INSTALL_OUTCOME_NONE 0u
#define CJGUI_WINDOWS_INSTALL_OUTCOME_INSTALLED 1u
#define CJGUI_WINDOWS_INSTALL_OUTCOME_OWNER_CONFIRMED 2u
#define CJGUI_WINDOWS_INSTALL_OUTCOME_OWNER_CANCELLED 3u
#define CJGUI_WINDOWS_INSTALL_OUTCOME_SUPERSEDED 4u
#define CJGUI_WINDOWS_INSTALL_OUTCOME_CONFLICT 5u
#define CJGUI_WINDOWS_INSTALL_OUTCOME_CLOSED 6u
    uint32_t navBarrierArmed;
    uint64_t navBarrierEpoch;
    uint32_t navReplayActive;
#define CJGUI_WINDOWS_NAV_HOLD_CAPACITY 16u
#define CJGUI_WINDOWS_NAV_HOLD_BYTES 65536u
    struct {
        uint32_t isDelete;
        char *bytes;
        uint32_t length;
        int64_t modifiers;
        uint64_t inputId;
        uint64_t bindingEpoch;
        uint64_t requestId;
    } navHold[CJGUI_WINDOWS_NAV_HOLD_CAPACITY];
    uint32_t navHoldHead;
    uint32_t navHoldCount;
    uint64_t navHoldBytes;
    // Windows 正常产品链的声明接受状态（无 OS 菜单栏 / 剪贴板投影）。
    uint64_t commandMenuProjectionVersion;
    uint32_t commandMenuPendingCount;
    uint32_t commandMenuAcceptedCount;
    uint64_t dataTransferProjectionVersion;
    uint32_t dataTransferPendingCount;
    uint64_t frameIndex;
    uint64_t sceneVersion;
    uint64_t resizeVersion;
    uint64_t textLayoutPreparationCount;
    uint64_t textRasterCount, textRasterBytes, textRasterMicros;
    uint64_t textUploadCount, textUploadBytes, textUploadMicros;
    uint64_t textTexturePeakBytes;
    uint64_t textPositionQueryCount;
    uint64_t textPositionLineMetricsCount;
    uint64_t sceneReadbackNonClearPixelCount;
    uint64_t sceneReadbackDarkPixelCount;
    uint64_t imageDecodeStartCount;
    uint64_t nextTextLayoutLease;
    uint64_t textTextureBytesInUse;
    uint64_t textScratchBytesInUse;
    uint64_t textTextureResourceCount;
    CjguiWindowsTextFlight textFlights[CJGUI_WINDOWS_TEXT_FLIGHT_CAPACITY];
    uint32_t textFlightCount;
    uint64_t sessionGeneration;
    uint64_t coordinateEpoch;
    uint64_t lastPumpedCoordinateEpoch;
    uint8_t multilineViewportEpochPending, multilineViewportPaintPending;
    uint64_t lastPumpedSessionGeneration;
    uint64_t focusedNodeId;
    int64_t focusedResourceId;
    uint32_t focusedNodeKind;
    uint32_t selectionStart16;
    uint32_t selectionEnd16;
    uint8_t *proxyValueUtf8;
    /* Pure paint state: no owner transaction, input ticket or binding mutation. */
    uint64_t selectionPaintDesiredKey;
    uint64_t selectionPaintStartedNs;
    uint64_t selectionPaintPresentedKey;
    uint8_t selectionPaintVisible;
    uint8_t selectionPaintPresentedVisible;
    uint8_t selectionPaintHasPresentation;

    uint32_t ownedTextSessionEnabled;
    uint64_t ownedTextSessionNodeId;
    int64_t ownedTextSessionResourceId;
    uint32_t ownedTextSessionNodeKind;
    uint64_t ownedTextSessionBindingEpoch;
    char *pendingOwnedInputBase;
    char *pendingOwnedInputValue;
    uint64_t pendingOwnedInputSceneVersion;
    uint64_t pendingOwnedInputBindingEpoch;
    uint64_t pendingOwnedInputNodeId;
    int64_t pendingOwnedInputResourceId;
    uint32_t pendingOwnedInputNodeKind;
    uint32_t pendingOwnedInputEventCount;
    /* ---- installed-range 旁带（Windows 生产者，喂给共享 CjguiInstalledRangeChain）---- */
    int rangeArmed;
    int rangeClosed;
    uint64_t rangeNonce;
    uint64_t rangeGeneration;
    uint64_t rangeWindowToken;
    uint64_t rangeBindingEpoch;
    uint64_t rangeContextEpoch;
    uint64_t rangeMirrorRevision;
    int64_t rangeOwnerVersion;
    uint64_t rangeSceneVersion;
    uint64_t rangeNodeId;
    int64_t rangeResourceId;
    uint64_t rangeSourceStart;
    uint64_t rangeSourceEnd;
    char *rangeBasisText;
    uint32_t rangeBasisTextLength;
    char *rangeChainBody;
    uint32_t rangeChainBodyLength;
    uint64_t rangeProxyGeneration;
    uint64_t rangeSelectionRevision;
    uint32_t rangeSelectionStart16;
    uint32_t rangeSelectionEnd16;
    uint64_t rangeAcceptedSeq;
    int64_t rangeAcceptedVersion;
    uint64_t rangeAcceptedSourceEnd;
    uint64_t rangeNextSeq;
    uint64_t rangePrevSeq;
    CjguiWindowsRangeClaimEntry rangeClaims[CJGUI_WINDOWS_RANGE_CLAIM_CAPACITY];
    uint32_t rangeClaimHead;
    uint32_t rangeClaimTail;
    uint16_t pendingHighSurrogate;
    uint64_t pendingHighSurrogateBindingEpoch;
    HIMC originalImeContext;
    HIMC ownedImeContext;
    uint64_t nextCompositionId;
    uint64_t activeCompositionId;
    uint64_t compositionBindingEpoch;
    uint64_t compositionSceneVersion;
    uint64_t compositionNodeId;
    int64_t compositionResourceId;
    uint32_t compositionNodeKind;
    uint32_t compositionReplacementStart16;
    uint32_t compositionReplacementLength16;
    uint32_t compositionState;
    uint32_t compositionTerminalReserved;
    uint32_t pointerTerminalReservedSlots;
    CjguiWindowsImeFrozen imeFrozen[CJGUI_WINDOWS_IME_FROZEN_CAPACITY];
    uint32_t imeFrozenCount;
    uint64_t imeFreezeMisses;
    uint32_t compositionGate;
    uint32_t compositionTerminalPhase;
    char *compositionBaseUtf8;
    char *compositionExpectedOwnerUtf8;
    char *pendingImeSuccessorUtf8;
    uint32_t pendingImeSuccessorBytes;
    uint32_t pendingImeSuccessorCursor16;
    uint32_t pendingImeSuccessorPresent;
    uint32_t pendingImeSuccessorReady;
    uint64_t pendingImeSuccessorInputId;
    uint64_t pendingImeSuccessorBindingEpoch;
    uint64_t pendingImeSuccessorRequestId;
    uint64_t pendingImeSuccessorCompositionId;
    uint64_t pendingImeSuccessorNodeId;
    int64_t pendingImeSuccessorResourceId;
    uint32_t pendingImeSuccessorNodeKind;
    uint64_t pendingImeSuccessorDeliveryCompositionId;
    char *pendingPngTransferIdentity;
    uint32_t pendingPngTransferCount;
    uint64_t presentationTicketNext;
    uint64_t presentationAcceptedCount;
    uint64_t presentationRejectedCount;
    uint64_t presentationQueryCount;
    uint64_t presentationAckCount;
    /* Only this POD receipt and these counters may cross the UI thread.
       g_sessionLock protects every access; GPU/scene objects remain UI owned. */
    CjguiInternalRendererPresentReceipt presentReceipt;
    uint64_t presentLastAckedTicket;
    uint64_t presentTicketAcceptedCount, presentTicketRejectedCount;
    uint64_t presentTicketDestroyRefusedCount;
    uint8_t presentReceiptPublished, presentClosing;
    uint64_t preparationId;
    uint64_t preparationProjectionVersion;
    /* ---- 通用有界场景准备（R7）----
       全部字段只由 UI（泵）线程的命令执行体访问；工作线程不读取后来变化的
       owner/Session，只消费 begin 时冻结的身份与 prepare 复制的不可变声明。
       私有图在 promote 之前对 accepted/present/输入完全不可见。 */
    uint8_t preparationActive;
    uint8_t preparationReady;
    uint32_t preparationNodeCount;
    uint32_t preparationStagedCount;
    uint32_t preparationPreparedCount;
    uint32_t preparationCursor;
    uint64_t preparationOwnedBytes;
    /* 活跃图 + 退休图的私有字节合计：取消/关闭后必须真实回落到 0，
       单元在飞期间不得虚减。 */
    uint64_t preparationLiveBytes;
    uint64_t preparationCopiedCount;
    uint64_t preparationUnitCount;
    uint64_t preparationDeadlineHits;
    uint64_t preparationStaleCount;
    uint64_t preparationBudgetRefusals;
    /* 冻结的准备对象身份：单元与提升只按这份副本判有效性。 */
    uint64_t preparationFrozenSessionGeneration;
    uint64_t preparationFrozenDeviceGeneration;
    uint64_t preparationFrozenDeviceRecoveryCount;
    uint64_t preparationFrozenResizeVersion;
    uint64_t preparationFrozenDpi;
    uint64_t preparationFrozenAcceptedVersion;
    uint64_t preparationFrozenBindingEpoch;
    uint64_t preparationFrozenFocusedNodeId;
    int64_t preparationFrozenFocusedResourceId;
    uint32_t preparationFrozenFocusedNodeKind;
    uint32_t preparationFrozenSelectionStart16;
    uint32_t preparationFrozenSelectionEnd16;
    uint64_t preparationFrozenPendingOwnedInputs;
    uint32_t preparationFrozenSourceInstallPending;
    char *preparationFrozenActiveBody;
    uint8_t *preparationState;
    CjguiWindowsSceneNode *preparationIncoming;
    CjguiWindowsScene preparationScene;
    /* 退休中的私有图：每个单元从尾部释放一个有界节点图（含纹理与排版）。
       单元在飞时槽位与字节都不假释放；回收延迟可单独测量。 */
    struct {
        CjguiWindowsScene scene;
        CjguiWindowsSceneNode *incoming;
        uint8_t *state;
        uint32_t nodeCount;
        uint32_t releaseCursor;
        uint64_t preparationId;
        uint64_t ownedBytes;
        /* 退休记录必须带原票身份：active 字段在取消时就归零，之后任何一行都不能
           再用当前 active 票回答“这张票回收了没有”。 */
        uint64_t cancelNs;
        uint64_t retiredNs;
        uint64_t sessionGeneration;
        uint64_t deviceGeneration;
        uint32_t releasedNodes;
        uint64_t releasedBytes;
    } preparationRetiring[CJGUI_WINDOWS_PREPARATION_GRAPH_CAPACITY];
    uint32_t preparationRetiringCount;
    uint64_t preparationRetiredGraphCount;
    uint64_t preparationRetiredNodeCount;
    uint64_t preparationRetiredBytes;
    uint64_t preparationCancelCount;
    /* 最近一次退休/回收的票（就地释放路径没有槽位，也必须有同票证据）。 */
    uint64_t preparationLastTicket;
    uint64_t preparationLastCancelNs;
    uint64_t preparationLastRetiredNs;
    uint64_t preparationLastReclaimNs;
    uint64_t preparationLastReleasedNodes;
    uint64_t preparationLastReleasedBytes;
    uint64_t preparationLastGraphNodes;
    uint64_t preparationLastGraphBytes;
    uint64_t preparationRetireAccountingErrors;
    uint64_t backgroundProjectionVersion;
    uint32_t backgroundMode;
    uint32_t backgroundColorScheme;
    CjguiWindowsScene candidateScene;
    CjguiWindowsScene acceptedScene;
    CjguiWindowsImageResource images[CJGUI_WINDOWS_IMAGE_CACHE_CAPACITY];
    uint64_t imageGpuBytesInUse, imageCpuBytesInUse, imageCountInUse, imageAccess;
    uint64_t deviceGeneration, deviceRecoveryCount;
    uint32_t graphicsRecoveryPending, graphicsRecoveryAttempts, controlledDeviceFault;
    uint32_t graphicsRecoveryControlled;
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    CjguiWindowsSceneContractTextDiagnostic sceneTextDiagnostic;
    uint32_t contractHoldTextFlights;
#endif
    CjguiWindowsTextRunDeclaration textRunDeclarations[CJGUI_WINDOWS_SCENE_NODE_CAPACITY];
    uint32_t textRunDeclarationCount;
    double clearRed;
    double clearGreen;
    double clearBlue;
    double clearAlpha;
    double caretX;
    double caretY;
    double caretWidth;
    double caretHeight;
    int64_t caretNodeId;
    CjguiInternalRendererPointerEventGeometry lastPointerGeometry;
    uint32_t mouseSelectionActive;
    uint32_t mouseCaptureActive;
    uint64_t mouseGestureEpoch;
    uint64_t mouseNodeId;
    uint64_t mouseProjectionVersion;
    int64_t mouseResourceId;
    uint32_t mouseNodeKind;
    uint32_t mouseNodeIndex;
    uint32_t mouseAnchor16;
    uint32_t mouseLastCaret16;
    uint32_t mousePressActive;
    uint32_t mousePressCancelled;
    uint32_t mousePressNodeIndex;
    uint32_t dbgPushLog[8];
    uint32_t dbgPushCount;
    uint64_t dbgUpNode;
    uint32_t dbgUpHitIndex;
    uint32_t dbgUpFlags;
    uint64_t dbgSceneDown;
    uint64_t dbgSceneUp;
    uint32_t dbgDownPushMark;
    uint32_t dbgUpEntryMark;
    /* UP 门控诊断（每次 DOWN 重置）：stage 记录本次 UP 走到的分支，
       reject 记录首个拒绝字段码，old/new 记录该字段冻结值/当前值
       （double 字段按位存 u64，探针按字段码解码），freshHit 记录与门控
       无关的 fresh hit-test 节点 id。upNode=0/upFlags=0 本身有两义性
       （门控早退与 fresh-hit 为空同形），必须与这组字段联判：
       0 none 1 down-reset 2 entry-gate-fail 3 gate-ok 4 terminal-pushed.
       reject: 0 none 1 gate-input-missing 2 nodeId 3 resourceId 4 nodeKind
       5 interactive 6 readOnly 7 bindingEpoch 8 frame-xywh 9 cornerRadius
       10 clip-rect-set 11 layoutLease 12 value 13 translate-xy
       14 geometry-clip-xy 15 geometry-clipCount 16 coordEpoch 17 entry-missing. */
    uint32_t dbgUpStage;
    uint32_t dbgUpReject;
    uint64_t dbgUpOld;
    uint64_t dbgUpNew;
    uint64_t dbgUpFreshHit;
    uint32_t dbgRawLog[8];
    uint32_t dbgRawCount;
    uint64_t mouseCoordinateEpoch;
    uint64_t mouseLayoutLease;
    uint64_t mouseNextGestureEpoch;
    double mouseLastX;
    double mouseLastY;
    CjguiInternalRendererComposableNode mouseFrozenNode;
    CjguiInternalRendererComposableGeometry mouseFrozenGeometry;
    char *mouseFrozenValue;
    char *formEventText;
    /* form_event_text 租约双槽：调用者拿到的指针在随后两次租约更新前保持有效，
       不被另一次 pump/destroy 提前释放。 */
    char *formEventTextLease;
    char *formEventTextPrev;
    uint64_t formEventTextLeaseId;
    /* 通用 UI dispatcher 信封环（phase 2：全部会话 API 封送，堆分配，有界等待）。
       命令只携带 token；会话查找与代次/退役检查一律在 UI 线程执行。 */
    struct CjguiWindowsCommand2 *cmdHold[CJGUI_WINDOWS_CMD_HOLD_CAPACITY];
    uint32_t cmdHoldHead;
    uint32_t cmdHoldCount;
    uint64_t cmdNextId;
    uint64_t orphanedCommands;
    uint64_t orphanedDropped;
    /* 正在 dispatch_sync 内等待的调用者数：phase-B 销毁 cmdLock/清零会话前
       有界等待其归零，否则超时方可能在锁删除后仍触碰 route。重入快路不同步
       等待，不计数。 */
    uint32_t cmdWaiters;
    uint8_t callerCleanupDeferred;
    /* 最近一次 UI 线程执行的命令身份（调用/执行/HWND tid＋API 名＋结果），
       供反例探针核 caller/execution/HWND，不作行为判据。 */
    DWORD lastExecCallerTid;
    DWORD lastExecTid;
    DWORD lastExecHwndTid;
    char lastExecApi[64];
    CjguiInternalRendererStatus lastExecStatus;
    HRESULT lastGraphicsFailure;
    uint32_t occupied;
};

/* Optional bounded diagnostics: record on the UI owner, batch-write only when
 * the existing file probe explicitly asks for TRACE. No per-input I/O. */
static void windows_trace(CjguiWindowsRendererSession *s,const char *stage,
    uint64_t a,uint64_t b,uint64_t c,uint64_t d,uint64_t e,uint64_t f) {
    if (!s || !s->traceEnabled) return;
    CjguiWindowsTraceRow *r=&s->traceRows[s->traceCount++ % CJGUI_WINDOWS_TRACE_CAPACITY];
    *r=(CjguiWindowsTraceRow){stage,cjgui_internal_renderer_owner_clock_ns(),
        s->candidateScene.configured?s->candidateScene.version:s->sceneVersion,
        s->rangePrevSeq,(uint64_t)s->rangeOwnerVersion,a,b,c,d,e,f};
}
static void windows_trace_dump(CjguiWindowsRendererSession *s,FILE *out) {
    uint64_t first=s->traceCount>CJGUI_WINDOWS_TRACE_CAPACITY?s->traceCount-CJGUI_WINDOWS_TRACE_CAPACITY:0;
    fprintf(out,"TRACE enabled=%u total=%llu retained=%llu\n",s->traceEnabled,
        (unsigned long long)s->traceCount,(unsigned long long)(s->traceCount-first));
    for(uint64_t i=first;i<s->traceCount;i++) {
        CjguiWindowsTraceRow *r=&s->traceRows[i%CJGUI_WINDOWS_TRACE_CAPACITY];
        fprintf(out,"TRACE_ROW index=%llu t_ns=%llu stage=%s scene=%llu seq=%llu owner=%llu a=%llu b=%llu c=%llu d=%llu e=%llu f=%llu\n",
            (unsigned long long)i,(unsigned long long)r->clockNs,r->stage,
            (unsigned long long)r->scene,(unsigned long long)r->seq,(unsigned long long)r->ownerVersion,
            (unsigned long long)r->a,(unsigned long long)r->b,(unsigned long long)r->c,
            (unsigned long long)r->d,(unsigned long long)r->e,(unsigned long long)r->f);
    }
}

static CjguiWindowsRendererSession g_sessions[CJGUI_WINDOWS_SESSION_CAPACITY];
static CRITICAL_SECTION g_sessionLock;
static INIT_ONCE g_sessionLockOnce = INIT_ONCE_STATIC_INIT;
static volatile LONG64 g_nextSessionToken = 0;
static volatile LONG64 g_nextSessionGeneration = 0;
static volatile LONG64 g_nextCoordinateEpoch = 0;
static volatile LONG64 g_nextCompositionId = 0;
static INIT_ONCE g_windowClassOnce = INIT_ONCE_STATIC_INIT;
static BOOL g_windowClassReady = FALSE;
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
static volatile LONG64 g_contractLiveTextTextureBytes = 0;
static volatile LONG g_contractLiveTextTextureResources = 0;
#endif

static CjguiInternalRendererStatus reap_text_flights(CjguiWindowsRendererSession *s);

static void drain_dispatcher_commands(CjguiWindowsRendererSession *s, int skipPumpAndDestroy);
static CjguiInternalRendererStatus windows_dispatch_sync(uint64_t token,
    const char *apiName, uint32_t kind, CjguiWindowsUiProc proc, void *ctx,
    CjguiWindowsCtxFree ctxFree, uint32_t timeoutMs, uint64_t *outCommandId);
static CjguiInternalRendererStatus cjgui_windows_pump_entry(uint64_t token,
    uint32_t timeoutMs, CjguiInternalRendererEvent *outEvent,
    uint64_t *outIdleWaitNs, int hasIdleOut);
static void cjgui_windows_fail_queued(CjguiWindowsRendererSession *s);
static void cjgui_windows_free_hold(CjguiWindowsRendererSession *s);
static void cjgui_windows_enqueue_stop(uint64_t token);

static int text_budget_reserve_scratch(CjguiWindowsRendererSession *s, uint64_t bytes) {
    if (!s || bytes > CJGUI_WINDOWS_TEXT_SESSION_SCRATCH_CAPACITY ||
        s->textScratchBytesInUse > CJGUI_WINDOWS_TEXT_SESSION_SCRATCH_CAPACITY - bytes ||
        s->textTextureBytesInUse > CJGUI_WINDOWS_TEXT_SESSION_TEXTURE_CAPACITY ||
        s->textTextureBytesInUse + s->textScratchBytesInUse >
            CJGUI_WINDOWS_TEXT_SESSION_TEXTURE_CAPACITY + CJGUI_WINDOWS_TEXT_SESSION_SCRATCH_CAPACITY - bytes)
        return 0;
    s->textScratchBytesInUse += bytes;
    return 1;
}

static void text_budget_release_scratch(CjguiWindowsRendererSession *s, uint64_t bytes) {
    if (!s) return;
    s->textScratchBytesInUse = s->textScratchBytesInUse >= bytes
        ? s->textScratchBytesInUse - bytes : 0u;
}

static int text_budget_reserve_texture(CjguiWindowsRendererSession *s, uint64_t bytes) {
    if (!s || bytes > CJGUI_WINDOWS_TEXT_SESSION_TEXTURE_CAPACITY ||
        s->textTextureBytesInUse > CJGUI_WINDOWS_TEXT_SESSION_TEXTURE_CAPACITY - bytes ||
        s->textScratchBytesInUse > CJGUI_WINDOWS_TEXT_SESSION_SCRATCH_CAPACITY ||
        s->textTextureBytesInUse + s->textScratchBytesInUse >
            CJGUI_WINDOWS_TEXT_SESSION_TEXTURE_CAPACITY + CJGUI_WINDOWS_TEXT_SESSION_SCRATCH_CAPACITY - bytes)
        return 0;
    s->textTextureBytesInUse += bytes;
    if (s->textTextureBytesInUse > s->textTexturePeakBytes)
        s->textTexturePeakBytes = s->textTextureBytesInUse;
    return 1;
}

static void text_budget_release_texture(CjguiWindowsRendererSession *s, uint64_t bytes) {
    if (!s) return;
    s->textTextureBytesInUse = s->textTextureBytesInUse >= bytes
        ? s->textTextureBytesInUse - bytes : 0u;
}

static int retain_text_texture_lease(CjguiWindowsTextTextureLease *lease) {
    if (!lease || lease->refs == UINT32_MAX) return 0;
    ++lease->refs;
    return 1;
}

static void release_text_texture_lease(CjguiWindowsTextTextureLease **slot) {
    if (!slot || !*slot) return;
    CjguiWindowsTextTextureLease *lease = *slot;
    *slot = NULL;
    if (lease->refs > 1u) { --lease->refs; return; }
    if (lease->view) ID3D11ShaderResourceView_Release(lease->view);
    if (lease->texture) ID3D11Texture2D_Release(lease->texture);
    if (lease->sessionBytesInUse && *lease->sessionBytesInUse >= lease->bytes)
        *lease->sessionBytesInUse -= lease->bytes;
    if (lease->imageCpuBytesInUse && *lease->imageCpuBytesInUse >= lease->imageStorageBytes)
        *lease->imageCpuBytesInUse -= lease->imageStorageBytes;
    free(lease->imagePixels);
    free(lease->imageEncoded);
    if (lease->sessionCountInUse && *lease->sessionCountInUse)
        --*lease->sessionCountInUse;
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    (void)InterlockedExchangeAdd64(&g_contractLiveTextTextureBytes, -(LONG64)lease->bytes);
    (void)InterlockedDecrement(&g_contractLiveTextTextureResources);
#endif
    free(lease);
}

static int windows_hresult_is_device_lost(HRESULT hr) {
    return hr == DXGI_ERROR_DEVICE_REMOVED || hr == DXGI_ERROR_DEVICE_RESET ||
        hr == DXGI_ERROR_DEVICE_HUNG;
}

static void release_text_flight_leases(CjguiWindowsRendererSession *s,
    CjguiWindowsTextFlight *flight) {
    if (!s || !flight) return;
    for (uint32_t i = 0; i < flight->leaseCount; ++i) {
        CjguiWindowsTextTextureLease *lease = flight->leases[i];
        if (lease) {
            release_text_texture_lease(&flight->leases[i]);
        }
    }
    flight->leaseCount = 0u;
    flight->recording = 0u;
    if (flight->pending && s->textFlightCount) --s->textFlightCount;
    flight->pending = 0u;
}

static CjguiInternalRendererStatus reap_text_flights(CjguiWindowsRendererSession *s) {
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    if (s->contractHoldTextFlights) return CJGUI_INTERNAL_RENDERER_OK;
#endif
    for (uint32_t i = 0; i < CJGUI_WINDOWS_TEXT_FLIGHT_CAPACITY; ++i) {
        CjguiWindowsTextFlight *flight = &s->textFlights[i];
        if (!flight->pending) continue;
        BOOL complete = FALSE;
        HRESULT hr = ID3D11DeviceContext_GetData(s->context,
            (ID3D11Asynchronous *)flight->query, &complete, sizeof(complete),
            D3D11_ASYNC_GETDATA_DONOTFLUSH);
        if (hr == S_OK && complete) {
            release_text_flight_leases(s, flight);
            continue;
        }
        if (hr == S_FALSE || (hr == S_OK && !complete)) continue;
        s->lastGraphicsFailure = hr;
        if (windows_hresult_is_device_lost(hr)) {
            // The device has declared every command on this generation dead;
            // no query can complete afterward, so retire its leases as one
            // terminal device-loss transition rather than pinning them forever.
            release_text_flight_leases(s, flight);
            continue;
        }
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus begin_text_flight(CjguiWindowsRendererSession *s,
    const CjguiWindowsScene *scene, CjguiWindowsTextFlight **outFlight) {
    if (!s || !scene || !outFlight) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outFlight = NULL;
    CjguiInternalRendererStatus status = reap_text_flights(s);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiWindowsTextFlight *flight = NULL;
    for (uint32_t i = 0; i < CJGUI_WINDOWS_TEXT_FLIGHT_CAPACITY; ++i) {
        if (!s->textFlights[i].pending && !s->textFlights[i].recording) {
            flight = &s->textFlights[i];
            break;
        }
    }
    if (!flight) return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
    if (!flight->query) {
        D3D11_QUERY_DESC desc;
        memset(&desc, 0, sizeof(desc));
        desc.Query = D3D11_QUERY_EVENT;
        HRESULT hr = ID3D11Device_CreateQuery(s->device, &desc, &flight->query);
        if (FAILED(hr) || !flight->query) {
            s->lastGraphicsFailure = FAILED(hr) ? hr : E_OUTOFMEMORY;
            return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        }
    }

    CjguiWindowsTextTextureLease *seen[CJGUI_WINDOWS_TEXT_FLIGHT_HASH_CAPACITY];
    memset(seen, 0, sizeof(seen));
    for (uint32_t i = 0; i < scene->count; ++i) {
        CjguiWindowsTextTextureLease *leases[3] = {
            scene->nodes[i].textLease, scene->nodes[i].labelTextLease, scene->nodes[i].imageLease};
        for (uint32_t which = 0; which < 3u; ++which) {
            CjguiWindowsTextTextureLease *lease = leases[which];
            if (!lease) continue;
            uintptr_t key = (uintptr_t)lease;
            uint32_t slot = (uint32_t)((key >> 4u) & (CJGUI_WINDOWS_TEXT_FLIGHT_HASH_CAPACITY - 1u));
            uint32_t probes = 0u;
            while (seen[slot] && seen[slot] != lease && probes < CJGUI_WINDOWS_TEXT_FLIGHT_HASH_CAPACITY) {
                slot = (slot + 1u) & (CJGUI_WINDOWS_TEXT_FLIGHT_HASH_CAPACITY - 1u);
                ++probes;
            }
            if (probes == CJGUI_WINDOWS_TEXT_FLIGHT_HASH_CAPACITY) {
                release_text_flight_leases(s, flight);
                return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
            }
            if (seen[slot] == lease) continue;
            if (flight->leaseCount >= CJGUI_WINDOWS_TEXT_FLIGHT_LEASE_CAPACITY ||
                !retain_text_texture_lease(lease)) {
                release_text_flight_leases(s, flight);
                return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
            }
            seen[slot] = lease;
            flight->leases[flight->leaseCount++] = lease;
        }
    }
    flight->recording = 1u;
    *outFlight = flight;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static void end_text_flight(CjguiWindowsRendererSession *s, CjguiWindowsTextFlight *flight) {
    if (!s || !flight || !flight->recording) return;
    ID3D11DeviceContext_End(s->context, (ID3D11Asynchronous *)flight->query);
    flight->recording = 0u;
    flight->pending = 1u;
    ++s->textFlightCount;
}

static CjguiInternalRendererStatus drain_text_flights(CjguiWindowsRendererSession *s,
    uint32_t timeoutMs) {
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!s->textFlightCount) return CJGUI_INTERNAL_RENDERER_OK;
    ID3D11DeviceContext_Flush(s->context);
    ULONGLONG deadline = GetTickCount64() + timeoutMs;
    while (s->textFlightCount) {
        CjguiInternalRendererStatus status = reap_text_flights(s);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
        if (!s->textFlightCount) return CJGUI_INTERNAL_RENDERER_OK;
        if (GetTickCount64() >= deadline) return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
        Sleep(1u);
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

static void release_text_flight_queries(CjguiWindowsRendererSession *s) {
    if (!s) return;
    for (uint32_t i = 0; i < CJGUI_WINDOWS_TEXT_FLIGHT_CAPACITY; ++i) {
        CjguiWindowsTextFlight *flight = &s->textFlights[i];
        if (flight->query && !flight->pending && !flight->recording) {
            ID3D11Query_Release(flight->query);
            flight->query = NULL;
        }
    }
}

static int utf8_offset_to_utf16(const char *value, uint64_t byteLength,
    uint64_t byteOffset, uint32_t *outUnits) {
    if (!value || !outUnits || byteOffset > byteLength) return 0;
    const uint8_t *bytes = (const uint8_t *)value;
    uint64_t byte = 0u;
    uint64_t units = 0u;
    while (byte < byteOffset) {
        uint8_t first = bytes[byte];
        uint64_t width = first < 0x80u ? 1u : (first & 0xe0u) == 0xc0u ? 2u :
            (first & 0xf0u) == 0xe0u ? 3u : (first & 0xf8u) == 0xf0u ? 4u : 0u;
        if (!width || width > byteOffset - byte || width > byteLength - byte) return 0;
        units += width == 4u ? 2u : 1u;
        byte += width;
    }
    if (byte != byteOffset || units > UINT32_MAX) return 0;
    *outUnits = (uint32_t)units;
    return 1;
}

static int parse_style_uint(char *field, uint32_t *out) {
    if (!field || !field[0] || !out) return 0;
    for (const unsigned char *p = (const unsigned char *)field; *p; ++p)
        if (*p < '0' || *p > '9') return 0;
    errno = 0;
    unsigned long long value = strtoull(field, NULL, 10);
    if (errno || value > UINT32_MAX) return 0;
    *out = (uint32_t)value;
    return 1;
}

static int parse_style_float(char *field, FLOAT *out) {
    if (!field || !field[0] || !out) return 0;
    char *end = NULL;
    errno = 0;
    double value = strtod(field, &end);
    if (errno || end == field || *end || !isfinite(value) || value < 0.0 || value > 512.0)
        return 0;
    *out = (FLOAT)value;
    return 1;
}

static CjguiInternalRendererStatus parse_style_run_list(const char *encoded,
    const char *value, CjguiWindowsTextStyleRun **outRuns, uint32_t *outCount) {
    if (!outRuns || !outCount) return CJGUI_INTERNAL_RENDERER_STYLE_RUN_INVALID;
    *outRuns = NULL;
    *outCount = 0u;
    size_t length = strnlen(encoded ? encoded : "", CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY + 1u);
    if (length > CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY)
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    if (!length) return CJGUI_INTERNAL_RENDERER_OK;
    uint32_t count = 1u;
    for (size_t i = 0; i < length; ++i) if (encoded[i] == ';') {
        if (count == CJGUI_WINDOWS_TEXT_RUN_CAPACITY)
            return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
        ++count;
    }
    char *copy = (char *)malloc(length + 1u);
    CjguiWindowsTextStyleRun *runs = (CjguiWindowsTextStyleRun *)calloc(count, sizeof(*runs));
    if (!copy || !runs) { free(copy); free(runs); return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR; }
    memcpy(copy, encoded, length + 1u);
    uint64_t valueBytes = value ? (uint64_t)strlen(value) : 0u;
    char *cursor = copy;
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_OK;
    for (uint32_t index = 0; index < count; ++index) {
        char *next = strchr(cursor, ';');
        if (next) *next = '\0';
        if (!cursor[0]) { status = CJGUI_INTERNAL_RENDERER_STYLE_RUN_INVALID; break; }
        char *fields[15] = {0};
        uint32_t fieldCount = 1u;
        fields[0] = cursor;
        for (char *p = cursor; *p; ++p) if (*p == ':') {
            *p = '\0';
            if (fieldCount >= 15u) { fieldCount = 16u; break; }
            fields[fieldCount++] = p + 1;
        }
        if (fieldCount != 9u && fieldCount != 14u && fieldCount != 15u) {
            status = CJGUI_INTERNAL_RENDERER_STYLE_RUN_INVALID; break;
        }
        CjguiWindowsTextStyleRun *run = &runs[index];
        uint32_t startByte = 0u, endByte = 0u, family = 0u, hasBackground = 0u;
        if (!parse_style_uint(fields[0], &startByte) || !parse_style_uint(fields[1], &endByte) ||
            !parse_style_float(fields[2], &run->fontSize) ||
            !parse_style_uint(fields[3], &run->fontWeight) ||
            !parse_style_uint(fields[4], &family) || family > 3u ||
            !parse_style_float(fields[5], &run->red) || !parse_style_float(fields[6], &run->green) ||
            !parse_style_float(fields[7], &run->blue) || !parse_style_float(fields[8], &run->alpha)) {
            status = CJGUI_INTERNAL_RENDERER_STYLE_RUN_INVALID; break;
        }
        run->fontFamily = family;
        if (fieldCount >= 14u) {
            if (!parse_style_uint(fields[9], &hasBackground) || hasBackground > 1u ||
                !parse_style_float(fields[10], &run->backgroundRed) ||
                !parse_style_float(fields[11], &run->backgroundGreen) ||
                !parse_style_float(fields[12], &run->backgroundBlue) ||
                !parse_style_float(fields[13], &run->backgroundAlpha)) {
                status = CJGUI_INTERNAL_RENDERER_STYLE_RUN_INVALID; break;
            }
        }
        run->hasBackground = (uint8_t)hasBackground;
        if (fieldCount == 15u) {
            uint32_t tag = 0u;
            if (!parse_style_uint(fields[14], &tag) || tag != 1u || !run->hasBackground) {
                status = CJGUI_INTERNAL_RENDERER_STYLE_RUN_INVALID; break;
            }
            run->selectionBackgroundOnly = 1u;
        }
        if (!run->selectionBackgroundOnly) {
            if (!(run->fontSize > 0.0f) || run->fontSize > 512.0f ||
                !(run->fontWeight == 0u || run->fontWeight == 1u ||
                  (run->fontWeight >= 100u && run->fontWeight <= 900u && run->fontWeight % 100u == 0u)) ||
                run->red > 1.0f || run->green > 1.0f || run->blue > 1.0f || run->alpha > 1.0f ||
                run->backgroundRed > 1.0f || run->backgroundGreen > 1.0f ||
                run->backgroundBlue > 1.0f || run->backgroundAlpha > 1.0f) {
                status = CJGUI_INTERNAL_RENDERER_STYLE_RUN_INVALID; break;
            }
        } else if (run->backgroundRed > 1.0f || run->backgroundGreen > 1.0f ||
            run->backgroundBlue > 1.0f || run->backgroundAlpha > 1.0f) {
            status = CJGUI_INTERNAL_RENDERER_STYLE_RUN_INVALID; break;
        }
        if (endByte <= startByte || (value && endByte > valueBytes)) {
            status = CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID; break;
        }
        if (value && (!utf8_offset_to_utf16(value, valueBytes, startByte, &run->start16) ||
            !utf8_offset_to_utf16(value, valueBytes, endByte, &run->end16) || run->end16 <= run->start16)) {
            status = CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID; break;
        }
        cursor = next ? next + 1 : cursor + strlen(cursor);
    }
    free(copy);
    if (status != CJGUI_INTERNAL_RENDERER_OK) { free(runs); return status; }
    *outRuns = runs;
    *outCount = count;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static uint64_t scene_unique_text_texture_bytes(const CjguiWindowsScene *scene,
    uint32_t excludedNodeIndex) {
    if (!scene || !scene->nodes) return 0u;
    uint64_t total = 0u;
    for (uint32_t i = 0; i < scene->count; ++i) {
        if (i == excludedNodeIndex) continue;
        CjguiWindowsTextTextureLease *leases[2] = {
            scene->nodes[i].textLease, scene->nodes[i].labelTextLease};
        for (uint32_t which = 0; which < 2u; ++which) {
            CjguiWindowsTextTextureLease *lease = leases[which];
            if (!lease) continue;
            int seen = 0;
            for (uint32_t prior = 0; prior <= i && !seen; ++prior) {
                if (prior == excludedNodeIndex) continue;
                uint32_t limit = prior == i ? which : 2u;
                for (uint32_t field = 0; field < limit; ++field) {
                    CjguiWindowsTextTextureLease *other = field == 0u
                        ? scene->nodes[prior].textLease : scene->nodes[prior].labelTextLease;
                    if (other == lease) { seen = 1; break; }
                }
            }
            if (!seen) {
                if (UINT64_MAX - total < lease->bytes) return UINT64_MAX;
                total += lease->bytes;
            }
        }
    }
    return total;
}

static CjguiInternalRendererStatus create_measured_text_layout(
    CjguiWindowsRendererSession *s, const char *utf8, double fontSize,
    uint32_t fontWeight, uint32_t fontFamily, float maxWidth, float maxHeight,
    IDWriteTextLayout **outLayout, DWRITE_TEXT_METRICS *outMetrics);
static CjguiWindowsTextColorEffect *create_text_color_effect(const FLOAT color[4]);
static CjguiWindowsSceneNode *scene_node_by_id(CjguiWindowsScene *scene, uint64_t nodeId);
static void position_windows_system_composition(CjguiWindowsRendererSession *s);
static int windows_utf8_offset_for_utf16(const char *utf8, uint32_t target,
    uint64_t *outByteOffset);
static CjguiInternalRendererStatus windows_validate_text_grapheme_boundary(
    const char *utf8, uint64_t length, uint64_t byteOffset, uint32_t *outUtf16);
CjguiInternalRendererStatus cjgui_internal_renderer_grapheme_cluster_range(
    const char *utf8, uint64_t declaredLength, uint64_t offsetByte,
    uint64_t *outStartByte, uint64_t *outEndByte);

enum {
    WINDOWS_COMPOSITION_IDLE = 0u,
    WINDOWS_COMPOSITION_MARKED = 1u,
    WINDOWS_COMPOSITION_END_PENDING = 2u,
    WINDOWS_COMPOSITION_TERMINAL_QUEUED = 3u,
    WINDOWS_COMPOSITION_RETIRED = 4u,
    WINDOWS_COMPOSITION_GATE_OPEN = 0u,
    WINDOWS_COMPOSITION_GATE_RETIRING = 1u,
    WINDOWS_COMPOSITION_GATE_RECOVERING = 2u,
    WINDOWS_COMPOSITION_GATE_CLOSED = 3u,
};

static int handle_windows_text_character(CjguiWindowsRendererSession *s,
    const WCHAR *text, uint32_t units, int64_t frozenModifiers,
    uint32_t repeatCount);
static int handle_windows_key_down(CjguiWindowsRendererSession *s, WPARAM key,
    int64_t frozenModifiers);
static int64_t windows_keyboard_modifiers(void);
static int handle_windows_ime_composition(CjguiWindowsRendererSession *s,
    LPARAM flags, int64_t imeSlot);
static int read_imm_utf8(HIMC context, DWORD index, char **outText,
    uint32_t *outBytes, uint32_t *outUnits);
static int handle_ime_core(CjguiWindowsRendererSession *s, LPARAM flags,
    int hasResult, char *resultText, uint32_t resultBytes, uint32_t resultUnits,
    int hasMarked, char *markedText, uint32_t markedBytes, uint32_t cursor16,
    CjguiWindowsImeFrozen *progress);
static void retry_kept_ime_frozen(CjguiWindowsRendererSession *s);

static void ime_frozen_free_slot(CjguiWindowsRendererSession *s, int64_t slot) {
    if (!s || slot < 0 ||
        slot >= (int64_t)CJGUI_WINDOWS_IME_FROZEN_CAPACITY) return;
    CjguiWindowsImeFrozen *frozen =
        &s->imeFrozen[(uint32_t)slot];
    if (!frozen->used) return;
    free(frozen->resultText);
    free(frozen->markedText);
    memset(frozen, 0, sizeof(*frozen));
    if (s->imeFrozenCount) s->imeFrozenCount -= 1u;
}

static void ime_frozen_free_all(CjguiWindowsRendererSession *s) {
    if (!s) return;
    for (uint32_t i = 0u; i < CJGUI_WINDOWS_IME_FROZEN_CAPACITY; ++i) {
        CjguiWindowsImeFrozen *frozen = &s->imeFrozen[i];
        free(frozen->resultText);
        free(frozen->markedText);
        memset(frozen, 0, sizeof(*frozen));
    }
    s->imeFrozenCount = 0u;
}

static int64_t freeze_ime_composition(CjguiWindowsRendererSession *s,
    LPARAM flags) {
    if (!s) return -1;
    HIMC context = ImmGetContext(s->hwnd);
    if (!context) return -1;
    char *resultText = NULL, *markedText = NULL;
    uint32_t resultBytes = 0u, resultUnits = 0u;
    uint32_t markedBytes = 0u, markedUnits = 0u;
    int hasResult = ((uint64_t)flags & (uint64_t)GCS_RESULTSTR) != 0u;
    int hasMarked = ((uint64_t)flags & (uint64_t)GCS_COMPSTR) != 0u;
    int resultOk = !hasResult || read_imm_utf8(context, GCS_RESULTSTR,
        &resultText, &resultBytes, &resultUnits);
    int markedOk = !hasMarked || read_imm_utf8(context, GCS_COMPSTR,
        &markedText, &markedBytes, &markedUnits);
    LONG cursorValue = hasMarked ? ImmGetCompositionStringW(context,
        GCS_CURSORPOS, NULL, 0u) : 0;
    ImmReleaseContext(s->hwnd, context);
    if (!resultOk || !markedOk) {
        free(resultText);
        free(markedText);
        s->imeFreezeMisses += 1u;
        return -1;
    }
    if (resultBytes > CJGUI_WINDOWS_DEFERRED_IME_BYTES ||
        markedBytes > CJGUI_WINDOWS_DEFERRED_IME_BYTES) {
        free(resultText);
        free(markedText);
        s->imeFreezeMisses += 1u;
        return -1;
    }
    for (uint32_t i = 0u; i < CJGUI_WINDOWS_IME_FROZEN_CAPACITY; ++i) {
        CjguiWindowsImeFrozen *frozen = &s->imeFrozen[i];
        if (frozen->used) continue;
        frozen->used = 1;
        frozen->resultText = resultText;
        frozen->resultBytes = resultBytes;
        frozen->markedText = markedText;
        frozen->markedBytes = markedBytes;
        frozen->cursor16 = cursorValue < 0 ? markedUnits : (uint32_t)cursorValue;
        frozen->flags = (uint32_t)flags;
        frozen->compositionId = s->activeCompositionId;
        frozen->bindingEpoch = s->ownedTextSessionBindingEpoch;
        s->imeFrozenCount += 1u;
        return (int64_t)i;
    }
    free(resultText);
    free(markedText);
    s->imeFreezeMisses += 1u;
    return -1;
}
static void end_windows_ime_composition(CjguiWindowsRendererSession *s);
static void clear_pending_owned_input(CjguiWindowsRendererSession *s);
static void range_disarm(CjguiWindowsRendererSession *s);
static int nav_barrier_release(CjguiWindowsRendererSession *s, int replay);
static int nav_intent_is_movement(const char *intent);
static int nav_intent_is_delete(const char *intent);
static int nav_barrier_hold_char(CjguiWindowsRendererSession *s,
    const char *insert, uint32_t insertLength, int64_t frozenModifiers);
static int nav_barrier_hold_delete(CjguiWindowsRendererSession *s,
    const char *intent, int64_t frozenModifiers);
static void finish_windows_composition_after_presentation(CjguiWindowsRendererSession *s);
static void start_pending_ime_successor(CjguiWindowsRendererSession *s);
static void synchronize_owned_proxy_after_presentation(CjguiWindowsRendererSession *s);

static uint64_t next_positive_counter(volatile LONG64 *counter) {
    LONG64 current = InterlockedCompareExchange64(counter, 0, 0);
    for (;;) {
        if (current < 0 || current == INT64_MAX) return 0u;
        LONG64 next = current + 1;
        LONG64 observed = InterlockedCompareExchange64(counter, next, current);
        if (observed == current) return (uint64_t)next;
        current = observed;
    }
}

static BOOL CALLBACK init_session_lock_once(PINIT_ONCE once, PVOID param, PVOID *ctx) {
    (void)once;
    (void)param;
    (void)ctx;
    InitializeCriticalSection(&g_sessionLock);
    return TRUE;
}

static void ensure_session_lock(void) {
    (void)InitOnceExecuteOnce(&g_sessionLockOnce, init_session_lock_once, NULL, NULL);
}

static CjguiWindowsRendererSession *find_session(uint64_t token) {
    if (token == 0) return NULL;
    ensure_session_lock();
    EnterCriticalSection(&g_sessionLock);
    CjguiWindowsRendererSession *found = NULL;
    for (uint32_t i = 0; i < CJGUI_WINDOWS_SESSION_CAPACITY; ++i) {
        if (g_sessions[i].occupied && g_sessions[i].token == token) {
            found = &g_sessions[i];
            break;
        }
    }
    LeaveCriticalSection(&g_sessionLock);
    return found;
}

/* ä¼è¯æææ§æ¥ï¼çº¿ç¨æ¨¡åè§æä»¶å¤´ï¼ï¼çªå£ä¸æ¶æ¯æ³µå½èªæ UI çº¿ç¨ï¼é©±å¨çº¿ç¨å¯ä»¥æ¯ä»»æ OS çº¿ç¨ï¼æ­¤å¤åªç¡®è®¤ä¼è¯å­å¨ï¼ä¸åå OS çº¿ç¨äº²åæ­è¨ã */
static CjguiInternalRendererStatus require_session(const CjguiWindowsRendererSession *s) {
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static void release_render_target(CjguiWindowsRendererSession *s) {
    if (s->renderTarget) {
        ID3D11RenderTargetView_Release(s->renderTarget);
        s->renderTarget = NULL;
    }
}

static void release_scene_pipeline(CjguiWindowsRendererSession *s) {
    if (s->sceneSampler) { ID3D11SamplerState_Release(s->sceneSampler); s->sceneSampler = NULL; }
    if (s->sceneRasterizer) { ID3D11RasterizerState_Release(s->sceneRasterizer); s->sceneRasterizer = NULL; }
    if (s->sceneBlendState) { ID3D11BlendState_Release(s->sceneBlendState); s->sceneBlendState = NULL; }
    if (s->sceneColorBuffer) { ID3D11Buffer_Release(s->sceneColorBuffer); s->sceneColorBuffer = NULL; }
    if (s->sceneVertexBuffer) { ID3D11Buffer_Release(s->sceneVertexBuffer); s->sceneVertexBuffer = NULL; }
    if (s->sceneInputLayout) { ID3D11InputLayout_Release(s->sceneInputLayout); s->sceneInputLayout = NULL; }
    if (s->sceneMaskPixelShader) { ID3D11PixelShader_Release(s->sceneMaskPixelShader); s->sceneMaskPixelShader = NULL; }
    if (s->sceneSolidPixelShader) { ID3D11PixelShader_Release(s->sceneSolidPixelShader); s->sceneSolidPixelShader = NULL; }
    if (s->sceneVertexShader) { ID3D11VertexShader_Release(s->sceneVertexShader); s->sceneVertexShader = NULL; }
}

static void release_graphics(CjguiWindowsRendererSession *s) {
    release_render_target(s);
    release_scene_pipeline(s);
    release_text_flight_queries(s);
    if (s->swapChain) { IDXGISwapChain_Release(s->swapChain); s->swapChain = NULL; }
    if (s->context) { ID3D11DeviceContext_Release(s->context); s->context = NULL; }
    if (s->device) { ID3D11Device_Release(s->device); s->device = NULL; }
    if (s->writeFactory) { IDWriteFactory_Release(s->writeFactory); s->writeFactory = NULL; }
}

static CjguiInternalRendererStatus create_render_target(CjguiWindowsRendererSession *s) {
    ID3D11Texture2D *backBuffer = NULL;
    HRESULT hr = IDXGISwapChain_GetBuffer(s->swapChain, 0, &IID_ID3D11Texture2D,
        (void **)&backBuffer);
    if (FAILED(hr)) { s->lastGraphicsFailure = hr; return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR; }
    hr = ID3D11Device_CreateRenderTargetView(s->device, (ID3D11Resource *)backBuffer,
        NULL, &s->renderTarget);
    ID3D11Texture2D_Release(backBuffer);
    if (FAILED(hr) || !s->renderTarget) {
        s->lastGraphicsFailure = hr;
        return CJGUI_INTERNAL_RENDERER_METAL_LAYER_UNAVAILABLE;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus create_scene_pipeline(CjguiWindowsRendererSession *s) {
    static const char source[] =
        "cbuffer ColorBuffer : register(b0) { float4 color; };\n"
        "struct VSIn { float2 pos : POSITION; float2 uv : TEXCOORD0; };\n"
        "struct VSOut { float4 pos : SV_POSITION; float2 uv : TEXCOORD0; };\n"
        "VSOut vs_main(VSIn i) { VSOut o; o.pos=float4(i.pos,0,1); o.uv=i.uv; return o; }\n"
        "float4 ps_solid(VSOut i) : SV_TARGET { return color; }\n"
        "Texture2D maskTexture : register(t0); SamplerState maskSampler : register(s0);\n"
        "float4 ps_mask(VSOut i) : SV_TARGET { float4 t=maskTexture.Sample(maskSampler,i.uv); return float4(t.rgb*color.rgb,t.a*color.a); }\n";
    ID3DBlob *vs = NULL, *solid = NULL, *mask = NULL, *errors = NULL;
    HRESULT hr = D3DCompile(source, sizeof(source) - 1u, "cjgui-windows-scene.hlsl",
        NULL, NULL, "vs_main", "vs_4_0", D3DCOMPILE_ENABLE_STRICTNESS, 0, &vs, &errors);
    if (FAILED(hr)) goto failed;
    if (errors) { ID3D10Blob_Release(errors); errors = NULL; }
    hr = D3DCompile(source, sizeof(source) - 1u, "cjgui-windows-scene.hlsl",
        NULL, NULL, "ps_solid", "ps_4_0", D3DCOMPILE_ENABLE_STRICTNESS, 0, &solid, &errors);
    if (FAILED(hr)) goto failed;
    if (errors) { ID3D10Blob_Release(errors); errors = NULL; }
    hr = D3DCompile(source, sizeof(source) - 1u, "cjgui-windows-scene.hlsl",
        NULL, NULL, "ps_mask", "ps_4_0", D3DCOMPILE_ENABLE_STRICTNESS, 0, &mask, &errors);
    if (FAILED(hr)) goto failed;
    hr = ID3D11Device_CreateVertexShader(s->device, ID3D10Blob_GetBufferPointer(vs),
        ID3D10Blob_GetBufferSize(vs), NULL, &s->sceneVertexShader);
    if (SUCCEEDED(hr)) hr = ID3D11Device_CreatePixelShader(s->device,
        ID3D10Blob_GetBufferPointer(solid), ID3D10Blob_GetBufferSize(solid), NULL,
        &s->sceneSolidPixelShader);
    if (SUCCEEDED(hr)) hr = ID3D11Device_CreatePixelShader(s->device,
        ID3D10Blob_GetBufferPointer(mask), ID3D10Blob_GetBufferSize(mask), NULL,
        &s->sceneMaskPixelShader);
    if (SUCCEEDED(hr)) {
        const D3D11_INPUT_ELEMENT_DESC elements[] = {
            {"POSITION", 0, DXGI_FORMAT_R32G32_FLOAT, 0, 0, D3D11_INPUT_PER_VERTEX_DATA, 0},
            {"TEXCOORD", 0, DXGI_FORMAT_R32G32_FLOAT, 0, 8, D3D11_INPUT_PER_VERTEX_DATA, 0}
        };
        hr = ID3D11Device_CreateInputLayout(s->device, elements, 2,
            ID3D10Blob_GetBufferPointer(vs), ID3D10Blob_GetBufferSize(vs), &s->sceneInputLayout);
    }
    if (SUCCEEDED(hr)) {
        D3D11_BUFFER_DESC desc; memset(&desc, 0, sizeof(desc));
        desc.ByteWidth = sizeof(CjguiWindowsVertex) * 4u;
        desc.Usage = D3D11_USAGE_DYNAMIC; desc.BindFlags = D3D11_BIND_VERTEX_BUFFER;
        desc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
        hr = ID3D11Device_CreateBuffer(s->device, &desc, NULL, &s->sceneVertexBuffer);
    }
    if (SUCCEEDED(hr)) {
        D3D11_BUFFER_DESC desc; memset(&desc, 0, sizeof(desc));
        desc.ByteWidth = 16u; desc.Usage = D3D11_USAGE_DYNAMIC;
        desc.BindFlags = D3D11_BIND_CONSTANT_BUFFER; desc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
        hr = ID3D11Device_CreateBuffer(s->device, &desc, NULL, &s->sceneColorBuffer);
    }
    if (SUCCEEDED(hr)) {
        D3D11_BLEND_DESC desc; memset(&desc, 0, sizeof(desc));
        desc.RenderTarget[0].BlendEnable = TRUE;
        desc.RenderTarget[0].SrcBlend = D3D11_BLEND_SRC_ALPHA;
        desc.RenderTarget[0].DestBlend = D3D11_BLEND_INV_SRC_ALPHA;
        desc.RenderTarget[0].BlendOp = D3D11_BLEND_OP_ADD;
        desc.RenderTarget[0].SrcBlendAlpha = D3D11_BLEND_ONE;
        desc.RenderTarget[0].DestBlendAlpha = D3D11_BLEND_INV_SRC_ALPHA;
        desc.RenderTarget[0].BlendOpAlpha = D3D11_BLEND_OP_ADD;
        desc.RenderTarget[0].RenderTargetWriteMask = D3D11_COLOR_WRITE_ENABLE_ALL;
        hr = ID3D11Device_CreateBlendState(s->device, &desc, &s->sceneBlendState);
    }
    if (SUCCEEDED(hr)) {
        D3D11_RASTERIZER_DESC desc; memset(&desc, 0, sizeof(desc));
        desc.FillMode = D3D11_FILL_SOLID; desc.CullMode = D3D11_CULL_NONE;
        desc.DepthClipEnable = TRUE; desc.ScissorEnable = TRUE;
        hr = ID3D11Device_CreateRasterizerState(s->device, &desc, &s->sceneRasterizer);
    }
    if (SUCCEEDED(hr)) {
        D3D11_SAMPLER_DESC desc; memset(&desc, 0, sizeof(desc));
        desc.Filter = D3D11_FILTER_MIN_MAG_LINEAR_MIP_POINT;
        desc.AddressU = D3D11_TEXTURE_ADDRESS_CLAMP; desc.AddressV = D3D11_TEXTURE_ADDRESS_CLAMP;
        desc.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP; desc.ComparisonFunc = D3D11_COMPARISON_NEVER;
        desc.MaxLOD = D3D11_FLOAT32_MAX;
        hr = ID3D11Device_CreateSamplerState(s->device, &desc, &s->sceneSampler);
    }
    if (vs) ID3D10Blob_Release(vs); if (solid) ID3D10Blob_Release(solid);
    if (mask) ID3D10Blob_Release(mask); if (errors) ID3D10Blob_Release(errors);
    if (FAILED(hr)) {
        s->lastGraphicsFailure = hr;
        release_scene_pipeline(s);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
failed:
    s->lastGraphicsFailure = hr;
    if (vs) ID3D10Blob_Release(vs); if (solid) ID3D10Blob_Release(solid);
    if (mask) ID3D10Blob_Release(mask); if (errors) ID3D10Blob_Release(errors);
    return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

static void bind_scene_pipeline(CjguiWindowsRendererSession *s) {
    UINT stride = sizeof(CjguiWindowsVertex), offset = 0;
    FLOAT factors[4] = {0, 0, 0, 0};
    ID3D11DeviceContext_IASetInputLayout(s->context, s->sceneInputLayout);
    ID3D11DeviceContext_IASetVertexBuffers(s->context, 0, 1, &s->sceneVertexBuffer, &stride, &offset);
    ID3D11DeviceContext_IASetPrimitiveTopology(s->context, D3D11_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP);
    ID3D11DeviceContext_VSSetShader(s->context, s->sceneVertexShader, NULL, 0);
    ID3D11DeviceContext_RSSetState(s->context, s->sceneRasterizer);
    ID3D11DeviceContext_OMSetBlendState(s->context, s->sceneBlendState, factors, 0xffffffffu);
    ID3D11DeviceContext_PSSetSamplers(s->context, 0, 1, &s->sceneSampler);
}

static CjguiInternalRendererStatus draw_scene_quad(CjguiWindowsRendererSession *s,
    FLOAT x, FLOAT y, FLOAT width, FLOAT height, const FLOAT color[4],
    ID3D11ShaderResourceView *maskView) {
    if (!s || !s->context || !s->width || !s->height || width <= 0.0f || height <= 0.0f)
        return CJGUI_INTERNAL_RENDERER_OK;
    FLOAT left = 2.0f * x / (FLOAT)s->width - 1.0f;
    FLOAT right = 2.0f * (x + width) / (FLOAT)s->width - 1.0f;
    FLOAT top = 1.0f - 2.0f * y / (FLOAT)s->height;
    FLOAT bottom = 1.0f - 2.0f * (y + height) / (FLOAT)s->height;
    const CjguiWindowsVertex vertices[4] = {
        {left, top, 0.0f, 0.0f}, {right, top, 1.0f, 0.0f},
        {left, bottom, 0.0f, 1.0f}, {right, bottom, 1.0f, 1.0f}
    };
    D3D11_MAPPED_SUBRESOURCE mapped;
    HRESULT hr = ID3D11DeviceContext_Map(s->context, (ID3D11Resource *)s->sceneVertexBuffer,
        0, D3D11_MAP_WRITE_DISCARD, 0, &mapped);
    if (FAILED(hr)) { s->lastGraphicsFailure = hr; return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR; }
    memcpy(mapped.pData, vertices, sizeof(vertices));
    ID3D11DeviceContext_Unmap(s->context, (ID3D11Resource *)s->sceneVertexBuffer, 0);
    hr = ID3D11DeviceContext_Map(s->context, (ID3D11Resource *)s->sceneColorBuffer,
        0, D3D11_MAP_WRITE_DISCARD, 0, &mapped);
    if (FAILED(hr)) { s->lastGraphicsFailure = hr; return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR; }
    memcpy(mapped.pData, color, 16u);
    ID3D11DeviceContext_Unmap(s->context, (ID3D11Resource *)s->sceneColorBuffer, 0);
    ID3D11DeviceContext_PSSetConstantBuffers(s->context, 0, 1, &s->sceneColorBuffer);
    ID3D11DeviceContext_PSSetShader(s->context,
        maskView ? s->sceneMaskPixelShader : s->sceneSolidPixelShader, NULL, 0);
    ID3D11DeviceContext_PSSetShaderResources(s->context, 0, 1, &maskView);
    ID3D11DeviceContext_Draw(s->context, 4, 0);
    if (maskView) {
        ID3D11ShaderResourceView *none = NULL;
        ID3D11DeviceContext_PSSetShaderResources(s->context, 0, 1, &none);
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus readback_scene_pixel_counts(CjguiWindowsRendererSession *s,
    uint64_t *outNonClear, uint64_t *outDark) {
    if (!s || !outNonClear || !outDark || !s->renderTarget || !s->device || !s->context)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outNonClear = 0u; *outDark = 0u;
    ID3D11Resource *resource = NULL;
    ID3D11RenderTargetView_GetResource(s->renderTarget, &resource);
    if (!resource) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ID3D11Texture2D *source = NULL;
    HRESULT hr = ID3D11Resource_QueryInterface(resource, &IID_ID3D11Texture2D, (void **)&source);
    ID3D11Resource_Release(resource);
    if (FAILED(hr) || !source) { s->lastGraphicsFailure = hr; return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR; }
    D3D11_TEXTURE2D_DESC desc; memset(&desc, 0, sizeof(desc));
    ID3D11Texture2D_GetDesc(source, &desc);
    desc.Usage = D3D11_USAGE_STAGING; desc.BindFlags = 0u;
    desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ; desc.MiscFlags = 0u;
    ID3D11Texture2D *staging = NULL;
    hr = ID3D11Device_CreateTexture2D(s->device, &desc, NULL, &staging);
    if (FAILED(hr) || !staging) {
        ID3D11Texture2D_Release(source); s->lastGraphicsFailure = hr;
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    ID3D11DeviceContext_CopyResource(s->context, (ID3D11Resource *)staging,
        (ID3D11Resource *)source);
    D3D11_MAPPED_SUBRESOURCE mapped; memset(&mapped, 0, sizeof(mapped));
    hr = ID3D11DeviceContext_Map(s->context, (ID3D11Resource *)staging, 0,
        D3D11_MAP_READ, 0u, &mapped);
    if (FAILED(hr)) {
        ID3D11Texture2D_Release(staging); ID3D11Texture2D_Release(source);
        s->lastGraphicsFailure = hr; return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint8_t expected[3] = {
        (uint8_t)lrint(fmax(0.0, fmin(1.0, s->clearBlue)) * 255.0),
        (uint8_t)lrint(fmax(0.0, fmin(1.0, s->clearGreen)) * 255.0),
        (uint8_t)lrint(fmax(0.0, fmin(1.0, s->clearRed)) * 255.0)
    };
    const uint8_t *base = (const uint8_t *)mapped.pData;
    for (UINT y = 0; y < desc.Height; ++y) {
        const uint8_t *row = base + (size_t)y * mapped.RowPitch;
        for (UINT x = 0; x < desc.Width; ++x) {
            const uint8_t *pixel = row + (size_t)x * 4u;
            int deltaB = abs((int)pixel[0] - expected[0]);
            int deltaG = abs((int)pixel[1] - expected[1]);
            int deltaR = abs((int)pixel[2] - expected[2]);
            if (deltaB > 4 || deltaG > 4 || deltaR > 4) ++*outNonClear;
            if (pixel[0] < 150u && pixel[1] < 150u && pixel[2] < 150u) ++*outDark;
        }
    }
    ID3D11DeviceContext_Unmap(s->context, (ID3D11Resource *)staging, 0);
    ID3D11Texture2D_Release(staging); ID3D11Texture2D_Release(source);
    return CJGUI_INTERNAL_RENDERER_OK;
}

#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
int cjgui_windows_scene_contract_readback_counts(uint64_t token,
    uint64_t *outNonClear, uint64_t *outDark, uint64_t *outMaskPixels) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (require_session(s) != CJGUI_INTERNAL_RENDERER_OK ||
        !outNonClear || !outDark || !outMaskPixels || !s->frameIndex) return 0;
    *outNonClear = s->sceneReadbackNonClearPixelCount;
    *outDark = s->sceneReadbackDarkPixelCount;
    *outMaskPixels = s->acceptedScene.count && s->acceptedScene.nodes[0].hasNode
        ? s->acceptedScene.nodes[0].textMaskNonzeroPixels : 0u;
    return 1;
}

int cjgui_windows_scene_contract_text_diagnostic(uint64_t token,
    CjguiWindowsSceneContractTextDiagnostic *outDiagnostic) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (require_session(s) != CJGUI_INTERNAL_RENDERER_OK || !outDiagnostic) return 0;
    *outDiagnostic = s->sceneTextDiagnostic;
    return 1;
}

int cjgui_windows_scene_contract_readback_text_texture(uint64_t token, uint64_t *outNonzero) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (require_session(s) != CJGUI_INTERNAL_RENDERER_OK || !outNonzero ||
        !s->acceptedScene.count || !s->acceptedScene.nodes[0].textTexture) return 0;
    *outNonzero = 0u;
    ID3D11Texture2D *source = s->acceptedScene.nodes[0].textTexture;
    D3D11_TEXTURE2D_DESC desc; memset(&desc, 0, sizeof(desc));
    ID3D11Texture2D_GetDesc(source, &desc);
    desc.Usage = D3D11_USAGE_STAGING; desc.BindFlags = 0u;
    desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ; desc.MiscFlags = 0u;
    ID3D11Texture2D *staging = NULL;
    HRESULT hr = ID3D11Device_CreateTexture2D(s->device, &desc, NULL, &staging);
    if (FAILED(hr) || !staging) return 0;
    ID3D11DeviceContext_CopyResource(s->context, (ID3D11Resource *)staging,
        (ID3D11Resource *)source);
    D3D11_MAPPED_SUBRESOURCE mapped; memset(&mapped, 0, sizeof(mapped));
    hr = ID3D11DeviceContext_Map(s->context, (ID3D11Resource *)staging, 0,
        D3D11_MAP_READ, 0u, &mapped);
    if (FAILED(hr)) { ID3D11Texture2D_Release(staging); return 0; }
    const uint8_t *base = (const uint8_t *)mapped.pData;
    for (UINT y = 0; y < desc.Height; ++y) {
        const uint8_t *row = base + (size_t)y * mapped.RowPitch;
        for (UINT x = 0; x < desc.Width; ++x) if (row[x] != 0u) ++*outNonzero;
    }
    ID3D11DeviceContext_Unmap(s->context, (ID3D11Resource *)staging, 0);
    ID3D11Texture2D_Release(staging);
    s->sceneTextDiagnostic.textureNonzero = *outNonzero;
    return 1;
}

int cjgui_windows_scene_contract_readback_color_counts(uint64_t token,
    uint64_t *outRedPixels, uint64_t *outGreenPixels) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (require_session(s) != CJGUI_INTERNAL_RENDERER_OK || !outRedPixels ||
        !outGreenPixels || !s->renderTarget) return 0;
    *outRedPixels = 0u;
    *outGreenPixels = 0u;
    ID3D11Resource *resource = NULL;
    ID3D11RenderTargetView_GetResource(s->renderTarget, &resource);
    if (!resource) return 0;
    ID3D11Texture2D *source = NULL;
    HRESULT hr = ID3D11Resource_QueryInterface(resource, &IID_ID3D11Texture2D,
        (void **)&source);
    ID3D11Resource_Release(resource);
    if (FAILED(hr) || !source) return 0;
    D3D11_TEXTURE2D_DESC desc; memset(&desc, 0, sizeof(desc));
    ID3D11Texture2D_GetDesc(source, &desc);
    desc.Usage = D3D11_USAGE_STAGING;
    desc.BindFlags = 0u;
    desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
    desc.MiscFlags = 0u;
    ID3D11Texture2D *staging = NULL;
    hr = ID3D11Device_CreateTexture2D(s->device, &desc, NULL, &staging);
    if (FAILED(hr) || !staging) { ID3D11Texture2D_Release(source); return 0; }
    ID3D11DeviceContext_CopyResource(s->context, (ID3D11Resource *)staging,
        (ID3D11Resource *)source);
    ID3D11Texture2D_Release(source);
    D3D11_MAPPED_SUBRESOURCE mapped; memset(&mapped, 0, sizeof(mapped));
    hr = ID3D11DeviceContext_Map(s->context, (ID3D11Resource *)staging, 0,
        D3D11_MAP_READ, 0u, &mapped);
    if (FAILED(hr)) { ID3D11Texture2D_Release(staging); return 0; }
    const uint8_t *base = (const uint8_t *)mapped.pData;
    for (UINT y = 0; y < desc.Height; ++y) {
        const uint8_t *row = base + (size_t)y * mapped.RowPitch;
        for (UINT x = 0; x < desc.Width; ++x) {
            const uint8_t *pixel = row + (size_t)x * 4u; // swapchain BGRA8
            if (pixel[2] >= 160u && pixel[1] <= 110u && pixel[0] <= 110u)
                ++*outRedPixels;
            if (pixel[1] >= 160u && pixel[2] <= 110u && pixel[0] <= 110u)
                ++*outGreenPixels;
        }
    }
    ID3D11DeviceContext_Unmap(s->context, (ID3D11Resource *)staging, 0);
    ID3D11Texture2D_Release(staging);
    return 1;
}

int cjgui_windows_scene_contract_input_layout_widths(uint64_t token, uint64_t nodeId,
    FLOAT *outActualWidth, FLOAT *outValueOnlyWidth) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (require_session(s) != CJGUI_INTERNAL_RENDERER_OK || !outActualWidth ||
        !outValueOnlyWidth) return 0;
    CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, nodeId);
    if (!node || !node->textLayout || !node->value) return 0;
    DWRITE_TEXT_METRICS actual; memset(&actual, 0, sizeof(actual));
    HRESULT hr = IDWriteTextLayout_GetMetrics(node->textLayout, &actual);
    if (FAILED(hr)) return 0;
    IDWriteTextLayout *valueLayout = NULL;
    DWRITE_TEXT_METRICS valueMetrics; memset(&valueMetrics, 0, sizeof(valueMetrics));
    CjguiInternalRendererStatus status = create_measured_text_layout(s, node->value,
        node->node.fontSize > 0.0 ? node->node.fontSize : 14.0,
        node->node.fontWeight, node->node.fontFamily, (FLOAT)node->node.width,
        (FLOAT)node->node.height, &valueLayout, &valueMetrics);
    if (status != CJGUI_INTERNAL_RENDERER_OK || !valueLayout) return 0;
    *outActualWidth = actual.widthIncludingTrailingWhitespace;
    *outValueOnlyWidth = valueMetrics.widthIncludingTrailingWhitespace;
    IDWriteTextLayout_Release(valueLayout);
    return 1;
}
#endif

#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
int cjgui_windows_contract_send_dpi_change(uint64_t token, uint32_t dpi) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (require_session(s) != CJGUI_INTERNAL_RENDERER_OK || !s->hwnd || dpi < 48u || dpi > 960u)
        return 0;
    (void)SendMessageW(s->hwnd, WM_DPICHANGED, MAKEWPARAM(dpi, dpi), 0);
    return s->dpi == dpi;
}

int cjgui_windows_contract_session_state(uint64_t token, uint32_t *outDpi,
    uint32_t *outPixelWidth, uint32_t *outPixelHeight, uint64_t *outTextureBytes,
    uint64_t *outTextureResources, uint64_t *outScratchBytes) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (require_session(s) != CJGUI_INTERNAL_RENDERER_OK || !outDpi ||
        !outPixelWidth || !outPixelHeight || !outTextureBytes ||
        !outTextureResources || !outScratchBytes) return 0;
    *outDpi = s->dpi;
    *outPixelWidth = s->width;
    *outPixelHeight = s->height;
    *outTextureBytes = s->textTextureBytesInUse;
    *outTextureResources = s->textTextureResourceCount;
    *outScratchBytes = s->textScratchBytesInUse;
    return 1;
}

int cjgui_windows_contract_node_text_state(uint64_t token, uint64_t nodeId,
    uint64_t *outLayoutLease, uint64_t *outTextDpi, uint32_t *outTextureWidth,
    uint32_t *outTextureHeight, uint64_t *outInkPixels) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (require_session(s) != CJGUI_INTERNAL_RENDERER_OK || !outLayoutLease ||
        !outTextDpi || !outTextureWidth || !outTextureHeight || !outInkPixels) return 0;
    CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, nodeId);
    if (!node || !node->textLayout) return 0;
    *outLayoutLease = node->layoutLease;
    *outTextDpi = node->textDpi;
    *outTextureWidth = node->textTextureWidth;
    *outTextureHeight = node->textTextureHeight;
    *outInkPixels = node->textMaskNonzeroPixels;
    return 1;
}

int cjgui_windows_contract_live_text_texture_usage(uint64_t *outBytes, uint32_t *outResources) {
    if (!outBytes || !outResources) return 0;
    LONG64 bytes = InterlockedCompareExchange64(&g_contractLiveTextTextureBytes, 0, 0);
    LONG resources = InterlockedCompareExchange(&g_contractLiveTextTextureResources, 0, 0);
    if (bytes < 0 || resources < 0) return 0;
    *outBytes = (uint64_t)bytes;
    *outResources = (uint32_t)resources;
    return 1;
}

int cjgui_windows_contract_set_hold_text_flights(uint64_t token, uint32_t hold) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (require_session(s) != CJGUI_INTERNAL_RENDERER_OK || hold > 1u) return 0;
    s->contractHoldTextFlights = hold;
    return 1;
}

int cjgui_windows_contract_text_flight_state(uint64_t token, uint32_t *outPendingFlights,
    uint32_t *outLeaseReferences, uint64_t *outReferencedBytes) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (require_session(s) != CJGUI_INTERNAL_RENDERER_OK || !outPendingFlights ||
        !outLeaseReferences || !outReferencedBytes) return 0;
    uint32_t pending = 0u, references = 0u;
    uint64_t bytes = 0u;
    for (uint32_t i = 0; i < CJGUI_WINDOWS_TEXT_FLIGHT_CAPACITY; ++i) {
        CjguiWindowsTextFlight *flight = &s->textFlights[i];
        if (!flight->pending) continue;
        ++pending;
        for (uint32_t j = 0; j < flight->leaseCount; ++j) {
            CjguiWindowsTextTextureLease *lease = flight->leases[j];
            if (!lease) continue;
            if (references == UINT32_MAX || UINT64_MAX - bytes < lease->bytes) return 0;
            ++references;
            bytes += lease->bytes;
        }
    }
    *outPendingFlights = pending;
    *outLeaseReferences = references;
    *outReferencedBytes = bytes;
    return 1;
}

int cjgui_windows_contract_drain_text_flights(uint64_t token, uint32_t timeoutMs) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (require_session(s) != CJGUI_INTERNAL_RENDERER_OK) return 0;
    return drain_text_flights(s, timeoutMs) == CJGUI_INTERNAL_RENDERER_OK;
}

int cjgui_windows_contract_mouse_diagnostic(uint64_t token, int64_t *outValues,
    double *outCoordinates) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (require_session(s) != CJGUI_INTERNAL_RENDERER_OK || !outValues || !outCoordinates)
        return 0;
    memcpy(outValues, s->contractMouseDiag, sizeof(s->contractMouseDiag));
    memcpy(outCoordinates, s->contractMouseCoordinates, sizeof(s->contractMouseCoordinates));
    return 1;
}

int cjgui_windows_contract_readback_node_text_alpha(uint64_t token, uint64_t nodeId,
    uint64_t *outNonzero) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (require_session(s) != CJGUI_INTERNAL_RENDERER_OK || !outNonzero) return 0;
    CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, nodeId);
    if (!node || !node->textTexture) return 0;
    *outNonzero = 0u;
    D3D11_TEXTURE2D_DESC desc; memset(&desc, 0, sizeof(desc));
    ID3D11Texture2D_GetDesc(node->textTexture, &desc);
    desc.Usage = D3D11_USAGE_STAGING; desc.BindFlags = 0u;
    desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ; desc.MiscFlags = 0u;
    ID3D11Texture2D *staging = NULL;
    HRESULT hr = ID3D11Device_CreateTexture2D(s->device, &desc, NULL, &staging);
    if (FAILED(hr) || !staging) return 0;
    ID3D11DeviceContext_CopyResource(s->context, (ID3D11Resource *)staging,
        (ID3D11Resource *)node->textTexture);
    D3D11_MAPPED_SUBRESOURCE mapped; memset(&mapped, 0, sizeof(mapped));
    hr = ID3D11DeviceContext_Map(s->context, (ID3D11Resource *)staging, 0,
        D3D11_MAP_READ, 0u, &mapped);
    if (FAILED(hr)) { ID3D11Texture2D_Release(staging); return 0; }
    const uint8_t *pixels = (const uint8_t *)mapped.pData;
    for (UINT y = 0; y < desc.Height; ++y) {
        const uint8_t *row = pixels + (size_t)y * mapped.RowPitch;
        for (UINT x = 0; x < desc.Width; ++x)
            if (row[(size_t)x * 4u + 3u] != 0u) ++*outNonzero;
    }
    ID3D11DeviceContext_Unmap(s->context, (ID3D11Resource *)staging, 0);
    ID3D11Texture2D_Release(staging);
    return 1;
}
#endif

static CjguiInternalRendererStatus resize_swap_chain(CjguiWindowsRendererSession *s,
    uint32_t width, uint32_t height) {
    if (!s || !s->swapChain || width == 0 || height == 0) return CJGUI_INTERNAL_RENDERER_OK;
    if (width == s->width && height == s->height) return CJGUI_INTERNAL_RENDERER_OK;
    ID3D11DeviceContext_OMSetRenderTargets(s->context, 0u, NULL, NULL);
    release_render_target(s);
    HRESULT hr = IDXGISwapChain_ResizeBuffers(s->swapChain, 0, width, height,
        DXGI_FORMAT_UNKNOWN, 0);
    if (FAILED(hr)) {
        s->lastGraphicsFailure = hr;
        if (windows_hresult_is_device_lost(hr)) {
            s->graphicsRecoveryPending = 1u;
            return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
        }
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    s->width = width;
    s->height = height;
    s->resizeVersion += 1;
    return create_render_target(s);
}

static int push_event_payload_internal(CjguiWindowsRendererSession *s,
    const CjguiInternalRendererEvent *event, const char *payload,
    uint32_t payloadLength, int terminal) {
    if (!s || !event) return 0;
    uint32_t terminalFlags = (uint32_t)terminal;
    uint32_t reserveBytes = s->compositionTerminalReserved && !(terminalFlags & 1u)
        ? CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY : 0u;
    uint32_t maxBytes = CJGUI_WINDOWS_EVENT_TEXT_BUDGET > reserveBytes
        ? CJGUI_WINDOWS_EVENT_TEXT_BUDGET - reserveBytes : 0u;
    uint32_t reserveSlots = (s->compositionTerminalReserved && !(terminalFlags & 1u) ? 1u : 0u) +
        (terminalFlags & 2u ? 0u : s->pointerTerminalReservedSlots);
    if (payloadLength > CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY ||
        s->eventTextBytes > maxBytes || payloadLength > maxBytes - s->eventTextBytes) {
        s->eventQueueFull = 1;
        return 0;
    }
    if (s->eventCount >= CJGUI_WINDOWS_EVENT_CAPACITY - reserveSlots) {
        s->eventQueueFull = 1;
        return 0;
    }
    char *copy = NULL;
    if (payloadLength) {
        if (!payload) {
            s->eventQueueFull = 1;
            return 0;
        }
        copy = (char *)malloc((size_t)payloadLength + 1u);
        if (!copy) {
            s->eventQueueFull = 1;
            return 0;
        }
        memcpy(copy, payload, payloadLength);
        copy[payloadLength] = '\0';
    }
    uint32_t slot = s->eventTail;
    s->events[slot] = *event;
    memset(&s->pointerGeometries[slot], 0, sizeof(s->pointerGeometries[slot]));
    s->pointerSessionGenerations[slot] = 0u;
    s->pointerCoordinateEpochs[slot] = 0u;
    s->eventTextPayloads[slot] = copy;
    s->eventTextLengths[slot] = payloadLength;
    s->eventTail = (s->eventTail + 1) % CJGUI_WINDOWS_EVENT_CAPACITY;
    s->eventCount += 1;
    s->eventTextBytes += payloadLength;
    if ((terminalFlags & 1u) && s->compositionTerminalReserved)
        s->compositionTerminalReserved = 0u;
    if (terminalFlags & 2u) s->pointerTerminalReservedSlots = 0u;
    return 1;
}

static int push_event_payload(CjguiWindowsRendererSession *s,
    const CjguiInternalRendererEvent *event, const char *payload, uint32_t payloadLength) {
    return push_event_payload_internal(s, event, payload, payloadLength, 0);
}

static int push_event(CjguiWindowsRendererSession *s,
    const CjguiInternalRendererEvent *event) {
    return push_event_payload(s, event, NULL, 0u);
}

static void enqueue_window_event(CjguiWindowsRendererSession *s, uint32_t kind) {
    CjguiInternalRendererEvent event;
    memset(&event, 0, sizeof(event));
    event.kind = kind;
    event.resourceId = -1;
    event.gesturePointerId = -1;
    event.replacementStart16 = -1;
    event.markedStart16 = -1;
    event.projectionVersion = s->sceneVersion;
    (void)push_event(s, &event);
}

static int windows_point_in_rounded_rect(double x, double y, double left, double top,
    double width, double height, double radius) {
    if (!isfinite(x) || !isfinite(y) || !isfinite(left) || !isfinite(top) ||
        !isfinite(width) || !isfinite(height) || width <= 0.0 || height <= 0.0)
        return 0;
    double right = left + width, bottom = top + height;
    if (x < left || x >= right || y < top || y >= bottom) return 0;
    if (!(radius > 0.0)) return 1;
    double limit = fmin(width, height) * 0.5;
    if (radius > limit) radius = limit;
    double nearestX = x < left + radius ? left + radius : x >= right - radius ? right - radius : x;
    double nearestY = y < top + radius ? top + radius : y >= bottom - radius ? bottom - radius : y;
    double dx = x - nearestX, dy = y - nearestY;
    return dx * dx + dy * dy <= radius * radius;
}

static void windows_clip_constraint(const CjguiWindowsSceneNode *entry, uint32_t index,
    double *x, double *y, double *width, double *height, double *radius) {
    const CjguiInternalRendererComposableNode *node = &entry->node;
    const CjguiInternalRendererComposableGeometry *geometry = &entry->geometry;
    switch (index) {
        case 0:
            *x = (double)node->clip0X + geometry->clip0X;
            *y = (double)node->clip0Y + geometry->clip0Y;
            *radius = node->clip0CornerRadius;
            break;
        case 1:
            *x = (double)node->clip1X + geometry->clip1X;
            *y = (double)node->clip1Y + geometry->clip1Y;
            *radius = node->clip1CornerRadius;
            break;
        case 2:
            *x = (double)node->clip2X + geometry->clip2X;
            *y = (double)node->clip2Y + geometry->clip2Y;
            *radius = node->clip2CornerRadius;
            break;
        default:
            *x = (double)node->clip3X + geometry->clip3X;
            *y = (double)node->clip3Y + geometry->clip3Y;
            *radius = node->clip3CornerRadius;
            break;
    }
    if (node->clipConstraintCount == 0u) {
        *x = (double)node->clipX;
        *y = (double)node->clipY;
        *width = (double)node->clipWidth;
        *height = (double)node->clipHeight;
        *radius = node->clipCornerRadius;
    } else {
        switch (index) {
            case 0: *width = (double)node->clip0Width; *height = (double)node->clip0Height; break;
            case 1: *width = (double)node->clip1Width; *height = (double)node->clip1Height; break;
            case 2: *width = (double)node->clip2Width; *height = (double)node->clip2Height; break;
            default: *width = (double)node->clip3Width; *height = (double)node->clip3Height; break;
        }
    }
}

static int windows_entry_contains_point(const CjguiWindowsRendererSession *s,
    const CjguiWindowsSceneNode *entry, double x, double y) {
    if (!s || !entry || !entry->hasNode || !entry->hasGeometry) return 0;
    const CjguiInternalRendererComposableNode *node = &entry->node;
    double nodeX = (double)node->x + entry->geometry.translateX;
    double nodeY = (double)node->y + entry->geometry.translateY;
    if (!windows_point_in_rounded_rect(x, y, nodeX, nodeY,
        (double)node->width, (double)node->height, node->cornerRadius)) return 0;
    uint32_t clipCount = node->clipConstraintCount ? node->clipConstraintCount : 1u;
    for (uint32_t i = 0; i < clipCount; ++i) {
        double clipX = 0.0, clipY = 0.0, clipWidth = 0.0, clipHeight = 0.0, radius = 0.0;
        windows_clip_constraint(entry, i, &clipX, &clipY, &clipWidth, &clipHeight, &radius);
        if (clipWidth <= 0.0 || clipHeight <= 0.0) {
            double scale = (double)(s->dpi ? s->dpi : 96u) / 96.0;
            clipX = 0.0; clipY = 0.0;
            clipWidth = (double)s->width / scale;
            clipHeight = (double)s->height / scale;
            radius = 0.0;
        }
        if (!windows_point_in_rounded_rect(x, y, clipX, clipY, clipWidth, clipHeight, radius))
            return 0;
    }
    return 1;
}

static CjguiWindowsSceneNode *windows_node_at_accepted_point(CjguiWindowsRendererSession *s,
    double x, double y, uint32_t *outIndex) {
    if (outIndex) *outIndex = UINT32_MAX;
    if (!s || !s->acceptedScene.configured) return NULL;
    for (uint32_t cursor = s->acceptedScene.count; cursor > 0u; --cursor) {
        uint32_t index = cursor - 1u;
        CjguiWindowsSceneNode *entry = &s->acceptedScene.nodes[index];
        if (!entry->hasNode || !entry->hasGeometry || !entry->node.isInteractive ||
            entry->node.isReadOnly || !windows_entry_contains_point(s, entry, x, y)) continue;
        if (outIndex) *outIndex = index;
        return entry;
    }
    return NULL;
}

static int64_t windows_pointer_integer(double coordinate) {
    if (!isfinite(coordinate)) return 0;
    if (coordinate >= (double)INT64_MAX) return INT64_MAX;
    if (coordinate <= (double)INT64_MIN) return INT64_MIN;
    return (int64_t)(coordinate >= 0.0 ? floor(coordinate + 0.5) : ceil(coordinate - 0.5));
}

static int windows_event_room(CjguiWindowsRendererSession *s, uint32_t events,
    uint32_t payloadBytes) {
    if (!s) return 0;
    uint32_t reserveBytes = s->compositionTerminalReserved ? CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY : 0u;
    uint32_t maxBytes = CJGUI_WINDOWS_EVENT_TEXT_BUDGET > reserveBytes
        ? CJGUI_WINDOWS_EVENT_TEXT_BUDGET - reserveBytes : 0u;
    uint32_t reserveSlots = (s->compositionTerminalReserved ? 1u : 0u) +
        s->pointerTerminalReservedSlots;
    if (events > CJGUI_WINDOWS_EVENT_CAPACITY - reserveSlots ||
        s->eventCount > CJGUI_WINDOWS_EVENT_CAPACITY - reserveSlots - events ||
        payloadBytes > CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY ||
        s->eventTextBytes > maxBytes || payloadBytes > maxBytes - s->eventTextBytes) {
        s->eventQueueFull = 1u;
        return 0;
    }
    return 1;
}

static int windows_push_node_event(CjguiWindowsRendererSession *s, uint32_t index,
    const CjguiWindowsSceneNode *entry, uint64_t projectionVersion, uint32_t kind,
    uint32_t selectionStart, uint32_t selectionEnd, double x, double y,
    uint64_t bindingEpoch, const char *payload) {
    if (!s || !entry || !entry->hasNode) return 0;
    uint32_t payloadBytes = payload ? (uint32_t)strlen(payload) : 0u;
    CjguiInternalRendererEvent event;
    memset(&event, 0, sizeof(event));
    event.kind = kind;
    event.recordIndex = index;
    event.selectionStart = selectionStart;
    event.selectionEnd = selectionEnd;
    event.nodeId = entry->node.nodeId;
    event.projectionVersion = projectionVersion;
    event.resourceId = entry->node.resourceId;
    event.nodeKind = entry->node.nodeKind;
    event.pointerX = windows_pointer_integer(x);
    event.pointerY = windows_pointer_integer(y);
    event.gesturePointerId = -1;
    event.replacementStart16 = -1;
    event.markedStart16 = -1;
    event.bindingEpoch = bindingEpoch;
    event.acceptedBindingEpoch = entry->node.acceptedBindingEpoch;
    uint32_t terminal = (kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_END ||
        kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_CANCEL ||
        kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_PRESS_END ||
        kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_PRESS_CANCEL) ? 2u : 0u;
    if (!push_event_payload_internal(s, &event, payload, payloadBytes, (int)terminal)) return 0;
    uint32_t slot = (s->eventTail + CJGUI_WINDOWS_EVENT_CAPACITY - 1u) % CJGUI_WINDOWS_EVENT_CAPACITY;
    CjguiInternalRendererPointerEventGeometry *geometry = &s->pointerGeometries[slot];
    geometry->present = 1u;
    geometry->kind = kind;
    geometry->nodeId = entry->node.nodeId;
    geometry->projectionVersion = projectionVersion;
    geometry->resourceId = entry->node.resourceId;
    geometry->nodeKind = entry->node.nodeKind;
    geometry->x = x;
    geometry->y = y;
    geometry->translateX = entry->geometry.translateX;
    geometry->translateY = entry->geometry.translateY;
    s->pointerSessionGenerations[slot] = s->sessionGeneration;
    s->pointerCoordinateEpochs[slot] = s->coordinateEpoch;
    s->dbgPushLog[s->dbgPushCount % 8u] = kind;
    s->dbgPushCount += 1u;
    return 1;
}

static int windows_is_text_input_node(uint32_t kind) {
    return kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
}

static int windows_is_pressable_node(uint32_t kind) {
    return kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE;
}

static void windows_free_mouse_target(CjguiWindowsRendererSession *s) {
    if (!s) return;
    free(s->mouseFrozenValue);
    s->mouseFrozenValue = NULL;
    memset(&s->mouseFrozenNode, 0, sizeof(s->mouseFrozenNode));
    memset(&s->mouseFrozenGeometry, 0, sizeof(s->mouseFrozenGeometry));
    s->mouseNodeId = 0u;
    s->mouseProjectionVersion = 0u;
    s->mouseResourceId = -1;
    s->mouseNodeKind = 0u;
    s->mouseNodeIndex = UINT32_MAX;
    s->mousePressNodeIndex = UINT32_MAX;
    s->mouseLayoutLease = 0u;
    s->mouseCoordinateEpoch = 0u;
    s->mouseAnchor16 = 0u;
    s->mouseLastCaret16 = 0u;
    s->mouseLastX = 0.0;
    s->mouseLastY = 0.0;
    s->mouseCaptureActive = 0u;
    s->mouseSelectionActive = 0u;
    s->mousePressActive = 0u;
    s->mousePressCancelled = 0u;
    s->mouseGestureEpoch = 0u;
}

static int windows_freeze_mouse_target(CjguiWindowsRendererSession *s, uint32_t index,
    const CjguiWindowsSceneNode *entry, double x, double y) {
    if (!s || !entry || !entry->hasNode || !entry->hasGeometry ||
        index >= s->acceptedScene.count) return 0;
    const char *value = entry->value ? entry->value : "";
    size_t valueBytes = strlen(value);
    char *copy = (char *)malloc(valueBytes + 1u);
    if (!copy) return 0;
    memcpy(copy, value, valueBytes + 1u);
    windows_free_mouse_target(s);
    s->mouseFrozenValue = copy;
    s->mouseFrozenNode = entry->node;
    s->mouseFrozenGeometry = entry->geometry;
    s->mouseNodeId = entry->node.nodeId;
    s->mouseResourceId = entry->node.resourceId;
    s->mouseNodeKind = entry->node.nodeKind;
    s->mouseNodeIndex = index;
    s->mousePressNodeIndex = index;
    s->mouseProjectionVersion = s->acceptedScene.version;
    s->mouseLayoutLease = entry->layoutLease;
    s->mouseCoordinateEpoch = s->coordinateEpoch;
    s->mouseLastX = x;
    s->mouseLastY = y;
    return 1;
}

static uint64_t windows_dbl_bits(double v) {
    uint64_t u = 0u;
    memcpy(&u, &v, sizeof(u));
    return u;
}

/* 鼠标目标门控：按冻结身份核对当前 accepted 条目。pressMode 只用于普通
   pressable 按压连续性：排版租约是纯绘制产物（按钮 label 重建即换 lease，
   框架 lease 与 macOS pressedRoutingNode 均不核它），按钮/标题值亦非动作
   身份，故跳过；BOOLEAN 值是开关状态本身，仍核。文字捕获/选择路径保持
   严格（排版/正文即 caret 依据）。首个失配字段码与前后值经 out 参数返回，
   供 UP 诊断一次定位实际失败分支。 */
static int windows_mouse_gate_check(const CjguiWindowsRendererSession *s,
    const CjguiWindowsSceneNode *entry, int pressMode,
    uint32_t *outReject, uint64_t *outOld, uint64_t *outNew) {
    uint32_t reject = 1u;
    uint64_t oldV = 0u, newV = 0u;
    int ok = 0;
    if (s && entry && entry->hasNode && entry->hasGeometry && s->mouseFrozenValue) {
        reject = 0u;
        const CjguiInternalRendererComposableNode *cur = &entry->node;
        const CjguiInternalRendererComposableNode *fro = &s->mouseFrozenNode;
        if (cur->nodeId != s->mouseNodeId) { reject = 2u; oldV = s->mouseNodeId; newV = cur->nodeId; }
        else if (cur->resourceId != s->mouseResourceId) { reject = 3u; oldV = (uint64_t)s->mouseResourceId; newV = (uint64_t)cur->resourceId; }
        else if (cur->nodeKind != s->mouseNodeKind) { reject = 4u; oldV = s->mouseNodeKind; newV = cur->nodeKind; }
        else if (cur->isInteractive != fro->isInteractive) { reject = 5u; oldV = fro->isInteractive; newV = cur->isInteractive; }
        else if (cur->isReadOnly != fro->isReadOnly) { reject = 6u; oldV = fro->isReadOnly; newV = cur->isReadOnly; }
        else if (cur->acceptedBindingEpoch != fro->acceptedBindingEpoch) { reject = 7u; oldV = fro->acceptedBindingEpoch; newV = cur->acceptedBindingEpoch; }
        else if (cur->x != fro->x) { reject = 8u; oldV = windows_dbl_bits(fro->x); newV = windows_dbl_bits(cur->x); }
        else if (cur->y != fro->y) { reject = 8u; oldV = windows_dbl_bits(fro->y); newV = windows_dbl_bits(cur->y); }
        else if (cur->width != fro->width) { reject = 8u; oldV = windows_dbl_bits(fro->width); newV = windows_dbl_bits(cur->width); }
        else if (cur->height != fro->height) { reject = 8u; oldV = windows_dbl_bits(fro->height); newV = windows_dbl_bits(cur->height); }
        else if (cur->cornerRadius != fro->cornerRadius) { reject = 9u; oldV = windows_dbl_bits(fro->cornerRadius); newV = windows_dbl_bits(cur->cornerRadius); }
        else if (cur->clipX != fro->clipX) { reject = 10u; oldV = windows_dbl_bits(fro->clipX); newV = windows_dbl_bits(cur->clipX); }
        else if (cur->clipY != fro->clipY) { reject = 10u; oldV = windows_dbl_bits(fro->clipY); newV = windows_dbl_bits(cur->clipY); }
        else if (cur->clipWidth != fro->clipWidth) { reject = 10u; oldV = windows_dbl_bits(fro->clipWidth); newV = windows_dbl_bits(cur->clipWidth); }
        else if (cur->clipHeight != fro->clipHeight) { reject = 10u; oldV = windows_dbl_bits(fro->clipHeight); newV = windows_dbl_bits(cur->clipHeight); }
        else if (cur->clipCornerRadius != fro->clipCornerRadius) { reject = 10u; oldV = windows_dbl_bits(fro->clipCornerRadius); newV = windows_dbl_bits(cur->clipCornerRadius); }
        else if (cur->clipConstraintCount != fro->clipConstraintCount) { reject = 10u; oldV = fro->clipConstraintCount; newV = cur->clipConstraintCount; }
        else if (cur->clip0X != fro->clip0X) { reject = 10u; oldV = windows_dbl_bits(fro->clip0X); newV = windows_dbl_bits(cur->clip0X); }
        else if (cur->clip0Y != fro->clip0Y) { reject = 10u; oldV = windows_dbl_bits(fro->clip0Y); newV = windows_dbl_bits(cur->clip0Y); }
        else if (cur->clip0Width != fro->clip0Width) { reject = 10u; oldV = windows_dbl_bits(fro->clip0Width); newV = windows_dbl_bits(cur->clip0Width); }
        else if (cur->clip0Height != fro->clip0Height) { reject = 10u; oldV = windows_dbl_bits(fro->clip0Height); newV = windows_dbl_bits(cur->clip0Height); }
        else if (cur->clip0CornerRadius != fro->clip0CornerRadius) { reject = 10u; oldV = windows_dbl_bits(fro->clip0CornerRadius); newV = windows_dbl_bits(cur->clip0CornerRadius); }
        else if (cur->clip1X != fro->clip1X) { reject = 10u; oldV = windows_dbl_bits(fro->clip1X); newV = windows_dbl_bits(cur->clip1X); }
        else if (cur->clip1Y != fro->clip1Y) { reject = 10u; oldV = windows_dbl_bits(fro->clip1Y); newV = windows_dbl_bits(cur->clip1Y); }
        else if (cur->clip1Width != fro->clip1Width) { reject = 10u; oldV = windows_dbl_bits(fro->clip1Width); newV = windows_dbl_bits(cur->clip1Width); }
        else if (cur->clip1Height != fro->clip1Height) { reject = 10u; oldV = windows_dbl_bits(fro->clip1Height); newV = windows_dbl_bits(cur->clip1Height); }
        else if (cur->clip1CornerRadius != fro->clip1CornerRadius) { reject = 10u; oldV = windows_dbl_bits(fro->clip1CornerRadius); newV = windows_dbl_bits(cur->clip1CornerRadius); }
        else if (cur->clip2X != fro->clip2X) { reject = 10u; oldV = windows_dbl_bits(fro->clip2X); newV = windows_dbl_bits(cur->clip2X); }
        else if (cur->clip2Y != fro->clip2Y) { reject = 10u; oldV = windows_dbl_bits(fro->clip2Y); newV = windows_dbl_bits(cur->clip2Y); }
        else if (cur->clip2Width != fro->clip2Width) { reject = 10u; oldV = windows_dbl_bits(fro->clip2Width); newV = windows_dbl_bits(cur->clip2Width); }
        else if (cur->clip2Height != fro->clip2Height) { reject = 10u; oldV = windows_dbl_bits(fro->clip2Height); newV = windows_dbl_bits(cur->clip2Height); }
        else if (cur->clip2CornerRadius != fro->clip2CornerRadius) { reject = 10u; oldV = windows_dbl_bits(fro->clip2CornerRadius); newV = windows_dbl_bits(cur->clip2CornerRadius); }
        else if (cur->clip3X != fro->clip3X) { reject = 10u; oldV = windows_dbl_bits(fro->clip3X); newV = windows_dbl_bits(cur->clip3X); }
        else if (cur->clip3Y != fro->clip3Y) { reject = 10u; oldV = windows_dbl_bits(fro->clip3Y); newV = windows_dbl_bits(cur->clip3Y); }
        else if (cur->clip3Width != fro->clip3Width) { reject = 10u; oldV = windows_dbl_bits(fro->clip3Width); newV = windows_dbl_bits(cur->clip3Width); }
        else if (cur->clip3Height != fro->clip3Height) { reject = 10u; oldV = windows_dbl_bits(fro->clip3Height); newV = windows_dbl_bits(cur->clip3Height); }
        else if (cur->clip3CornerRadius != fro->clip3CornerRadius) { reject = 10u; oldV = windows_dbl_bits(fro->clip3CornerRadius); newV = windows_dbl_bits(cur->clip3CornerRadius); }
        else if (!pressMode && entry->layoutLease != s->mouseLayoutLease) { reject = 11u; oldV = s->mouseLayoutLease; newV = entry->layoutLease; }
        else if ((!pressMode || cur->nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT) &&
            strcmp(entry->value ? entry->value : "", s->mouseFrozenValue) != 0) { reject = 12u; oldV = (uint64_t)strlen(s->mouseFrozenValue); newV = (uint64_t)strlen(entry->value ? entry->value : ""); }
        else if (entry->geometry.translateX != s->mouseFrozenGeometry.translateX) { reject = 13u; oldV = windows_dbl_bits(s->mouseFrozenGeometry.translateX); newV = windows_dbl_bits(entry->geometry.translateX); }
        else if (entry->geometry.translateY != s->mouseFrozenGeometry.translateY) { reject = 13u; oldV = windows_dbl_bits(s->mouseFrozenGeometry.translateY); newV = windows_dbl_bits(entry->geometry.translateY); }
        else if (entry->geometry.clip0X != s->mouseFrozenGeometry.clip0X) { reject = 14u; oldV = windows_dbl_bits(s->mouseFrozenGeometry.clip0X); newV = windows_dbl_bits(entry->geometry.clip0X); }
        else if (entry->geometry.clip0Y != s->mouseFrozenGeometry.clip0Y) { reject = 14u; oldV = windows_dbl_bits(s->mouseFrozenGeometry.clip0Y); newV = windows_dbl_bits(entry->geometry.clip0Y); }
        else if (entry->geometry.clip1X != s->mouseFrozenGeometry.clip1X) { reject = 14u; oldV = windows_dbl_bits(s->mouseFrozenGeometry.clip1X); newV = windows_dbl_bits(entry->geometry.clip1X); }
        else if (entry->geometry.clip1Y != s->mouseFrozenGeometry.clip1Y) { reject = 14u; oldV = windows_dbl_bits(s->mouseFrozenGeometry.clip1Y); newV = windows_dbl_bits(entry->geometry.clip1Y); }
        else if (entry->geometry.clip2X != s->mouseFrozenGeometry.clip2X) { reject = 14u; oldV = windows_dbl_bits(s->mouseFrozenGeometry.clip2X); newV = windows_dbl_bits(entry->geometry.clip2X); }
        else if (entry->geometry.clip2Y != s->mouseFrozenGeometry.clip2Y) { reject = 14u; oldV = windows_dbl_bits(s->mouseFrozenGeometry.clip2Y); newV = windows_dbl_bits(entry->geometry.clip2Y); }
        else if (entry->geometry.clip3X != s->mouseFrozenGeometry.clip3X) { reject = 14u; oldV = windows_dbl_bits(s->mouseFrozenGeometry.clip3X); newV = windows_dbl_bits(entry->geometry.clip3X); }
        else if (entry->geometry.clip3Y != s->mouseFrozenGeometry.clip3Y) { reject = 14u; oldV = windows_dbl_bits(s->mouseFrozenGeometry.clip3Y); newV = windows_dbl_bits(entry->geometry.clip3Y); }
        else if (entry->geometry.clipCount != s->mouseFrozenGeometry.clipCount) { reject = 15u; oldV = s->mouseFrozenGeometry.clipCount; newV = entry->geometry.clipCount; }
        else { ok = 1; }
    }
    if (outReject) *outReject = reject;
    if (outOld) *outOld = oldV;
    if (outNew) *outNew = newV;
    return ok;
}

static int windows_mouse_geometry_still_matches(const CjguiWindowsRendererSession *s,
    const CjguiWindowsSceneNode *entry) {
    return windows_mouse_gate_check(s, entry, 0, NULL, NULL, NULL);
}

static int windows_mouse_press_still_matches(const CjguiWindowsRendererSession *s,
    const CjguiWindowsSceneNode *entry,
    uint32_t *outReject, uint64_t *outOld, uint64_t *outNew) {
    return windows_mouse_gate_check(s, entry, 1, outReject, outOld, outNew);
}

static CjguiWindowsSceneNode *windows_current_mouse_target(CjguiWindowsRendererSession *s,
    uint32_t *outIndex, int pressMode,
    uint32_t *outReject, uint64_t *outOld, uint64_t *outNew) {
    if (outIndex) *outIndex = UINT32_MAX;
    if (outReject) *outReject = 0u;
    if (outOld) *outOld = 0u;
    if (outNew) *outNew = 0u;
    if (!s || !s->mouseNodeId) {
        if (outReject) *outReject = 17u;
        return NULL;
    }
    if (s->mouseCoordinateEpoch != s->coordinateEpoch) {
        if (outReject) *outReject = 16u;
        if (outOld) *outOld = s->mouseCoordinateEpoch;
        if (outNew) *outNew = s->coordinateEpoch;
        return NULL;
    }
    uint32_t index = UINT32_MAX;
    CjguiWindowsSceneNode *entry = scene_node_by_id(&s->acceptedScene, s->mouseNodeId);
    if (!entry) {
        if (outReject) *outReject = 17u;
        if (outOld) *outOld = s->mouseNodeId;
        return NULL;
    }
    uint32_t gateReject = 0u;
    uint64_t gateOld = 0u, gateNew = 0u;
    if (!windows_mouse_gate_check(s, entry, pressMode, &gateReject, &gateOld, &gateNew)) {
        if (outReject) *outReject = gateReject;
        if (outOld) *outOld = gateOld;
        if (outNew) *outNew = gateNew;
        return NULL;
    }
    for (uint32_t i = 0; i < s->acceptedScene.count; ++i)
        if (&s->acceptedScene.nodes[i] == entry) { index = i; break; }
    if (index == UINT32_MAX) {
        if (outReject) *outReject = 17u;
        return NULL;
    }
    s->mouseNodeIndex = index;
    if (outIndex) *outIndex = index;
    return entry;
}

static int windows_text_position_at(CjguiWindowsRendererSession *s,
    const CjguiWindowsSceneNode *entry, double x, double y, uint32_t *outUtf16) {
    if (!s || !entry || !outUtf16) return 0;
    uint64_t meta[8] = {0};
    double rect[4] = {0};
    CjguiInternalRendererStatus status = cjgui_internal_renderer_text_position_v1(
        s->token, entry->node.nodeId, s->acceptedScene.version, 1u, 0, 1u,
        0u, 0u, 0u, x, y, meta, rect);
    if (status != CJGUI_INTERNAL_RENDERER_OK || meta[6] > UINT32_MAX) return 0;
    *outUtf16 = (uint32_t)meta[6];
    return 1;
}

static int windows_focus_and_select_at(CjguiWindowsRendererSession *s, uint32_t index,
    CjguiWindowsSceneNode *entry, double x, double y, uint32_t *outUtf16) {
    if (!s || !entry || !outUtf16 || !windows_is_text_input_node(entry->node.nodeKind)) return 0;
    uint64_t meta[8] = {0};
    double rect[4] = {0};
    CjguiInternalRendererStatus status = cjgui_internal_renderer_text_position_v1(
        s->token, entry->node.nodeId, s->acceptedScene.version, 1u, 0, 1u,
        0u, 0u, 0u, x, y, meta, rect);
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    s->contractMouseDiag[7] = (int64_t)status;
    s->contractMouseDiag[8] = (int64_t)meta[6];
    s->contractMouseDiag[9] = (int64_t)s->eventCount;
#endif
    if (status != CJGUI_INTERNAL_RENDERER_OK || meta[6] > UINT32_MAX) return 0;
    size_t valueBytes = strlen(entry->value ? entry->value : "");
    int room = valueBytes <= UINT32_MAX && windows_event_room(s, 2u, (uint32_t)valueBytes);
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    s->contractMouseDiag[10] = room;
#endif
    if (!room) return 0;
    status = cjgui_internal_renderer_focus_composable_node(s->token, entry->node.nodeId);
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    s->contractMouseDiag[11] = (int64_t)status;
    s->contractMouseDiag[12] = s->hwnd && GetFocus() == s->hwnd ? 1 : 0;
#endif
    if (status != CJGUI_INTERNAL_RENDERER_OK) return 0;
    uint32_t caret = (uint32_t)meta[6];
    s->selectionStart16 = s->selectionEnd16 = caret;
    const char *value = s->proxyValueUtf8 ? (const char *)s->proxyValueUtf8 : "";
    int focusPushed = windows_push_node_event(s, index, entry, s->acceptedScene.version,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FOCUS, caret, caret,
        x, y, 0u, value);
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    s->contractMouseDiag[13] = focusPushed;
#endif
    if (!focusPushed) return 0;
    int selectionPushed = windows_push_node_event(s, index, entry, s->acceptedScene.version,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED, caret, caret,
        x, y, 0u, NULL);
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    s->contractMouseDiag[14] = selectionPushed;
    s->contractMouseDiag[15] = (int64_t)s->eventCount;
#endif
    if (!selectionPushed) return 0;
    *outUtf16 = caret;
    return 1;
}

static void windows_cancel_mouse_gesture(CjguiWindowsRendererSession *s) {
    if (!s) return;
    uint64_t binding = s->mouseGestureEpoch;
    CjguiWindowsSceneNode frozen;
    memset(&frozen, 0, sizeof(frozen));
    frozen.node = s->mouseFrozenNode;
    frozen.geometry = s->mouseFrozenGeometry;
    frozen.hasNode = s->mouseFrozenNode.nodeId != 0u;
    frozen.hasGeometry = frozen.hasNode;
    if (s->mouseCaptureActive) {
        if (!windows_push_node_event(s, s->mouseNodeIndex, &frozen,
            s->mouseProjectionVersion, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_CANCEL,
            0u, 0u, s->mouseLastX, s->mouseLastY, binding, NULL)) return;
    } else if (s->mousePressActive && !s->mousePressCancelled) {
        if (!windows_push_node_event(s, s->mousePressNodeIndex, &frozen, s->mouseProjectionVersion,
            CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_PRESS_CANCEL,
            0u, 0u, s->mouseLastX, s->mouseLastY, binding, NULL)) return;
    }
    windows_free_mouse_target(s);
    if (s->hwnd && GetCapture() == s->hwnd) ReleaseCapture();
}

static void windows_handle_mouse_down(CjguiWindowsRendererSession *s, LPARAM lParam) {
    if (!s || !s->hwnd) return;
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    s->contractMouseDiag[1] += 1;
    s->contractMouseDiag[2] = 1;
    s->contractMouseDiag[3] = s->acceptedScene.configured ? 1 : 0;
    s->contractMouseDiag[4] = (int64_t)s->acceptedScene.count;
    s->contractMouseDiag[5] = -1;
    s->contractMouseDiag[6] = 0;
    s->contractMouseDiag[7] = -999;
    s->contractMouseDiag[8] = -1;
    s->contractMouseDiag[9] = (int64_t)s->eventCount;
    s->contractMouseDiag[10] = -1;
    s->contractMouseDiag[11] = -999;
    s->contractMouseDiag[12] = s->hwnd && GetFocus() == s->hwnd ? 1 : 0;
    s->contractMouseDiag[13] = -1;
    s->contractMouseDiag[14] = -1;
    s->contractMouseDiag[15] = (int64_t)s->eventCount;
    s->contractMouseDiag[16] = -1;
    s->contractMouseDiag[17] = (int64_t)s->dpi;
    s->contractMouseDiag[18] = (int64_t)s->coordinateEpoch;
    s->contractMouseDiag[19] = (int64_t)s->acceptedScene.version;
    s->contractMouseCoordinates[0] = (double)GET_X_LPARAM(lParam);
    s->contractMouseCoordinates[1] = (double)GET_Y_LPARAM(lParam);
#endif
    if (s->mouseCaptureActive || s->mouseSelectionActive || s->mousePressActive)
        windows_cancel_mouse_gesture(s);
    double scale = (double)(s->dpi ? s->dpi : 96u) / 96.0;
    double x = (double)GET_X_LPARAM(lParam) / scale;
    double y = (double)GET_Y_LPARAM(lParam) / scale;
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    s->contractMouseDiag[2] = 2;
    s->contractMouseCoordinates[2] = x;
    s->contractMouseCoordinates[3] = y;
#endif
    uint32_t index = UINT32_MAX;
    CjguiWindowsSceneNode *entry = windows_node_at_accepted_point(s, x, y, &index);
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    s->contractMouseDiag[2] = 3;
    s->contractMouseDiag[5] = entry ? (int64_t)index : -1;
    s->contractMouseDiag[6] = entry ? (int64_t)entry->node.nodeId : 0;
#endif
    if (!entry) return;
    s->dbgSceneDown = s->acceptedScene.version;
    s->dbgDownPushMark = s->dbgPushCount;
    s->dbgUpStage = 1u;
    s->dbgUpReject = 0u;
    s->dbgUpOld = 0u;
    s->dbgUpNew = 0u;
    s->dbgUpFreshHit = 0ull;
    s->dbgUpNode = 0ull;
    s->dbgUpHitIndex = UINT32_MAX;
    s->dbgUpFlags = 0u;
    s->dbgSceneUp = 0u;
    s->dbgUpEntryMark = 0u;
    if (windows_is_text_input_node(entry->node.nodeKind)) {
        uint32_t caret = 0u;
        uint32_t requiredSlots = entry->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT ? 4u : 2u;
        uint32_t payloadBytes = (uint32_t)strlen(entry->value ? entry->value : "");
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
        s->contractMouseDiag[2] = 4;
#endif
        int room = windows_event_room(s, requiredSlots, payloadBytes);
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
        s->contractMouseDiag[16] = room;
#endif
        if (!room || !windows_freeze_mouse_target(s, index, entry, x, y)) return;
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
        s->contractMouseDiag[2] = 5;
#endif
        if (!windows_focus_and_select_at(s, index, entry, x, y, &caret)) {
            windows_free_mouse_target(s);
            return;
        }
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
        s->contractMouseDiag[2] = 6;
#endif
        s->mouseAnchor16 = caret;
        s->mouseLastCaret16 = caret;
        if (entry->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT) {
            if (s->mouseNextGestureEpoch == UINT64_MAX) {
                windows_free_mouse_target(s);
                return;
            }
            s->mouseGestureEpoch = ++s->mouseNextGestureEpoch;
            if (!s->mouseGestureEpoch || !windows_event_room(s, 2u, 0u) ||
                !windows_push_node_event(s, index, entry,
                s->acceptedScene.version, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_BEGIN,
                0u, 0u, x, y, s->mouseGestureEpoch, NULL)) {
                windows_free_mouse_target(s);
                return;
            }
            s->pointerTerminalReservedSlots = 1u;
            s->mouseCaptureActive = 1u;
        } else {
            s->mouseSelectionActive = 1u;
        }
        SetCapture(s->hwnd);
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
        s->contractMouseDiag[2] = 7;
#endif
        if (GetCapture() != s->hwnd) {
            if (s->mouseCaptureActive) windows_cancel_mouse_gesture(s);
            else windows_free_mouse_target(s);
        }
        return;
    }
    if (!windows_is_pressable_node(entry->node.nodeKind)) return;
    if (!windows_event_room(s, 3u, 0u) || s->mouseNextGestureEpoch == UINT64_MAX ||
        !windows_freeze_mouse_target(s, index, entry, x, y)) return;
    s->mouseGestureEpoch = ++s->mouseNextGestureEpoch;
    // 顺序不变量：按压租约必须在任何可能触发重发布的焦点事件之前入队。
    // 焦点事件会使应用在下一轮重新发布场景并递增版本号；随后到达的按压
    // 事件（携带旧版本号）会被严格版本相等检查拒绝，租约无法建立。先推
    // PRESS_BEGIN（建立租约），再推 FOCUS；租约连续性只看绑定身份，不受
    // 版本推进影响。
    if (!s->mouseGestureEpoch || !windows_push_node_event(s, index, entry,
        s->acceptedScene.version, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_PRESS_BEGIN,
        0u, 0u, x, y, s->mouseGestureEpoch, NULL) ||
        !windows_push_node_event(s, index, entry, s->acceptedScene.version,
            CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FOCUS,
            0u, 0u, x, y, 0u, NULL)) {
        windows_free_mouse_target(s);
        return;
    }
    s->pointerTerminalReservedSlots = 2u;
    s->mousePressActive = 1u;
    SetCapture(s->hwnd);
    if (GetCapture() != s->hwnd) windows_cancel_mouse_gesture(s);
}

static void windows_handle_mouse_move(CjguiWindowsRendererSession *s, LPARAM lParam) {
    if (!s || (!s->mouseCaptureActive && !s->mouseSelectionActive && !s->mousePressActive)) return;
    double scale = (double)(s->dpi ? s->dpi : 96u) / 96.0;
    double x = (double)GET_X_LPARAM(lParam) / scale;
    double y = (double)GET_Y_LPARAM(lParam) / scale;
    s->mouseLastX = x; s->mouseLastY = y;
    int pressMode = (!s->mouseCaptureActive && !s->mouseSelectionActive && s->mousePressActive);
    uint32_t index = UINT32_MAX;
    CjguiWindowsSceneNode *entry = windows_current_mouse_target(s, &index, pressMode, NULL, NULL, NULL);
    if (!entry) { windows_cancel_mouse_gesture(s); return; }
    if (s->mouseCaptureActive) {
        if (!windows_push_node_event(s, index, entry, s->acceptedScene.version,
            CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE,
            0u, 0u, x, y, s->mouseGestureEpoch, NULL)) windows_cancel_mouse_gesture(s);
        return;
    }
    if (s->mouseSelectionActive) {
        uint32_t caret = 0u;
        if (!windows_text_position_at(s, entry, x, y, &caret)) { windows_cancel_mouse_gesture(s); return; }
        s->mouseLastCaret16 = caret;
        s->selectionStart16 = s->mouseAnchor16 < caret ? s->mouseAnchor16 : caret;
        s->selectionEnd16 = s->mouseAnchor16 < caret ? caret : s->mouseAnchor16;
        if (!windows_push_node_event(s, index, entry, s->acceptedScene.version,
            CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED,
            s->selectionStart16, s->selectionEnd16, x, y, 0u, NULL)) windows_cancel_mouse_gesture(s);
        return;
    }
    uint32_t hitIndex = UINT32_MAX;
    CjguiWindowsSceneNode *hit = windows_node_at_accepted_point(s, x, y, &hitIndex);
    if (!hit || hit->node.nodeId != s->mouseNodeId || hit->node.resourceId != s->mouseResourceId ||
        hit->node.nodeKind != s->mouseNodeKind) {
        if (!s->mousePressCancelled) {
            s->mousePressCancelled = 1u;
            if (!windows_push_node_event(s, index, entry, s->mouseProjectionVersion,
                CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_PRESS_CANCEL,
                0u, 0u, x, y, s->mouseGestureEpoch, NULL)) windows_cancel_mouse_gesture(s);
        }
    }
}

static void windows_handle_mouse_up(CjguiWindowsRendererSession *s, LPARAM lParam) {
    if (!s) return;
    s->dbgUpEntryMark = s->dbgPushCount;
    s->dbgSceneUp = s->acceptedScene.version;
    if ((!s->mouseCaptureActive && !s->mouseSelectionActive && !s->mousePressActive)) return;
    double scale = (double)(s->dpi ? s->dpi : 96u) / 96.0;
    double x = (double)GET_X_LPARAM(lParam) / scale;
    double y = (double)GET_Y_LPARAM(lParam) / scale;
    s->mouseLastX = x; s->mouseLastY = y;
    int pressMode = (!s->mouseCaptureActive && !s->mouseSelectionActive && s->mousePressActive);
    uint32_t index = UINT32_MAX;
    uint32_t gateReject = 0u;
    uint64_t gateOld = 0u, gateNew = 0u;
    CjguiWindowsSceneNode *entry = windows_current_mouse_target(s, &index, pressMode,
        &gateReject, &gateOld, &gateNew);
    if (!entry) {
        s->dbgUpStage = 2u;
        s->dbgUpReject = gateReject;
        s->dbgUpOld = gateOld;
        s->dbgUpNew = gateNew;
        uint32_t freshIndex = UINT32_MAX;
        CjguiWindowsSceneNode *fresh = windows_node_at_accepted_point(s, x, y, &freshIndex);
        s->dbgUpFreshHit = fresh ? (uint64_t)fresh->node.nodeId : 0ull;
        s->dbgUpNode = 0ull;
        s->dbgUpHitIndex = UINT32_MAX;
        s->dbgUpFlags = 0u;
        windows_cancel_mouse_gesture(s);
        return;
    }
    s->dbgUpStage = 3u;
    s->dbgUpReject = 0u;
    s->dbgUpOld = 0u;
    s->dbgUpNew = 0u;
    if (s->mouseCaptureActive) {
        if (!windows_push_node_event(s, index, entry, s->acceptedScene.version,
            CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_END,
            0u, 0u, x, y, s->mouseGestureEpoch, NULL)) {
            windows_cancel_mouse_gesture(s);
            return;
        }
        windows_free_mouse_target(s);
        if (GetCapture() == s->hwnd) ReleaseCapture();
        return;
    }
    if (s->mouseSelectionActive) {
        uint32_t caret = 0u;
        if (windows_text_position_at(s, entry, x, y, &caret)) {
            s->selectionStart16 = s->mouseAnchor16 < caret ? s->mouseAnchor16 : caret;
            s->selectionEnd16 = s->mouseAnchor16 < caret ? caret : s->mouseAnchor16;
            (void)windows_push_node_event(s, index, entry, s->acceptedScene.version,
                CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED,
                s->selectionStart16, s->selectionEnd16, x, y, 0u, NULL);
        }
        windows_free_mouse_target(s);
        if (GetCapture() == s->hwnd) ReleaseCapture();
        return;
    }
    uint32_t hitIndex = UINT32_MAX;
    CjguiWindowsSceneNode *hit = windows_node_at_accepted_point(s, x, y, &hitIndex);
    int activates = !s->mousePressCancelled && hit && hit->node.nodeId == s->mouseNodeId &&
        hit->node.resourceId == s->mouseResourceId && hit->node.nodeKind == s->mouseNodeKind;
    s->dbgUpNode = hit ? (uint64_t)hit->node.nodeId : 0ull;
    s->dbgUpHitIndex = hitIndex;
    s->dbgUpFlags = (hit ? 1u : 0u) | (activates ? 2u : 0u) | (s->mousePressCancelled ? 4u : 0u);
    s->dbgUpFreshHit = hit ? (uint64_t)hit->node.nodeId : 0ull;
    s->dbgUpStage = 4u;
    uint64_t binding = s->mouseGestureEpoch;
    uint32_t kind = entry->node.nodeKind;
    if (!s->mousePressCancelled && !windows_push_node_event(s, index, entry, s->acceptedScene.version,
        activates ? CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_PRESS_END :
            CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_PRESS_CANCEL,
        0u, 0u, x, y, binding, NULL)) {
        windows_cancel_mouse_gesture(s);
        return;
    }
    if (activates) {
        uint32_t activationKind = kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT
            ? CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_BOOLEAN_CHANGED
            : CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE;
        const char *nextValue = NULL;
        if (activationKind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_BOOLEAN_CHANGED)
            nextValue = entry->value && strcmp(entry->value, "true") == 0 ? "false" : "true";
        (void)windows_push_node_event(s, index, entry, s->acceptedScene.version,
            activationKind, 0u, 0u, x, y, binding, nextValue);
    }
    windows_free_mouse_target(s);
    if (GetCapture() == s->hwnd) ReleaseCapture();
}

static void windows_cancel_mouse_on_coordinate_change(CjguiWindowsRendererSession *s) {
    if (s && (s->mouseCaptureActive || s->mouseSelectionActive || s->mousePressActive))
        windows_cancel_mouse_gesture(s);
}

/* UI 线程追加原始输入；wheel 同时冻结来源投影、坐标 epoch 与系统行单位。
   不修改 owner、选择或视口，所有 FIFO 转移仍由驱动消费边界完成。 */
/* Transfer the front wheel using its frozen projection and client coordinate.
   Capacity/allocation refusal retains the whole raw record in the same FIFO. */
static int scroll_windows_multiline_viewport(CjguiWindowsRendererSession *, uint32_t, int, UINT);

static int transfer_windows_wheel(CjguiWindowsRendererSession *s,
    const CjguiWindowsRawRecord *raw) {
    if (!s->acceptedScene.configured || raw->wheelSceneVersion != s->acceptedScene.version ||
        raw->wheelCoordinateEpoch != s->coordinateEpoch) return 1;
    int delta = (int)(SHORT)HIWORD((WPARAM)raw->wParam);
    if (!delta || !raw->wheelLines) return 1;
    double scale = (double)(s->dpi ? s->dpi : 96u) / 96.0;
    double x = (double)(SHORT)LOWORD((LPARAM)raw->lParam) / scale;
    double y = (double)(SHORT)HIWORD((LPARAM)raw->lParam) / scale;
    for (uint32_t cursor = s->acceptedScene.count; cursor > 0u; --cursor) {
        uint32_t index = cursor - 1u;
        CjguiWindowsSceneNode *entry = &s->acceptedScene.nodes[index];
        if (entry->hasNode && entry->hasGeometry &&
            entry->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT &&
            windows_entry_contains_point(s, entry, x, y))
            return scroll_windows_multiline_viewport(s, index, delta, raw->wheelLines);
        if (!entry->hasNode || !entry->hasGeometry ||
            (entry->node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA &&
                !entry->node.wheelScrollable) || !windows_entry_contains_point(s, entry, x, y)) continue;
        double lines = (double)delta / (double)WHEEL_DELTA *
            (double)(raw->wheelLines == WHEEL_PAGESCROLL ? 1u : raw->wheelLines);
        char payload[128];
        int n = snprintf(payload, sizeof(payload), "cjgui-wheel-v1|0|%.17g|0|0|0", lines);
        if (n <= 0 || n >= (int)sizeof(payload)) return 1;
        uint32_t slots = (s->compositionTerminalReserved ? 1u : 0u) + s->pointerTerminalReservedSlots;
        uint32_t bytes = s->compositionTerminalReserved ? CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY : 0u;
        /* A known full queue is backpressure, not an additional error event
           which would refill every just-freed slot and prevent convergence. */
        if (slots >= CJGUI_WINDOWS_EVENT_CAPACITY ||
            s->eventCount >= CJGUI_WINDOWS_EVENT_CAPACITY - slots ||
            bytes > CJGUI_WINDOWS_EVENT_TEXT_BUDGET ||
            (uint32_t)n > CJGUI_WINDOWS_EVENT_TEXT_BUDGET - bytes ||
            s->eventTextBytes > CJGUI_WINDOWS_EVENT_TEXT_BUDGET - bytes - (uint32_t)n) return 0;
        if (!windows_push_node_event(s, index, entry, raw->wheelSceneVersion,
            CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SCROLL, 0, 0, x, y, 0, payload)) return 0;
        uint32_t slot = (s->eventTail + CJGUI_WINDOWS_EVENT_CAPACITY - 1u) % CJGUI_WINDOWS_EVENT_CAPACITY;
        s->events[slot].modifierFlags = raw->modifiers;
        return 1;
    }
    return 1;
}

static void raw_ring_push_slot(CjguiWindowsRendererSession *s, uint32_t message,
    uint64_t wParam, int64_t lParam, int64_t modifiers, int64_t imeSlot) {
    if (!s) return;
    UINT wheelLines = 3u;
    if (message == WM_MOUSEWHEEL) SystemParametersInfoW(SPI_GETWHEELSCROLLLINES, 0, &wheelLines, 0);
    EnterCriticalSection(&s->rawLock);
    s->dbgRawLog[s->dbgRawCount % 8u] = message;
    s->dbgRawCount += 1u;
    uint32_t next = (s->rawHead + 1u) % CJGUI_WINDOWS_RAW_RING_CAPACITY;
    if (next != s->rawTail) {
        s->rawRing[s->rawHead].message = message;
        s->rawRing[s->rawHead].wParam = wParam;
        s->rawRing[s->rawHead].lParam = lParam;
        s->rawRing[s->rawHead].modifiers = modifiers;
        s->rawRing[s->rawHead].imeSlot = imeSlot;
        s->rawRing[s->rawHead].wheelSceneVersion = message == WM_MOUSEWHEEL ? s->acceptedScene.version : 0;
        s->rawRing[s->rawHead].wheelCoordinateEpoch = message == WM_MOUSEWHEEL ? s->coordinateEpoch : 0;
        s->rawRing[s->rawHead].wheelLines = wheelLines;
        s->rawHead = next;
        SetEvent(s->rawWakeEvent);
    } else {
        s->rawDropped += 1u;
    }
    LeaveCriticalSection(&s->rawLock);
}

static void raw_ring_push(CjguiWindowsRendererSession *s, uint32_t message,
    uint64_t wParam, int64_t lParam, int64_t modifiers) {
    raw_ring_push_slot(s, message, wParam, lParam, modifiers, -1);
}

/* 驱动线程专用：取一条原始输入；空返回 0。 */
static int raw_ring_pop(CjguiWindowsRendererSession *s, uint32_t *message,
    uint64_t *wParam, int64_t *lParam, int64_t *modifiers, int64_t *imeSlot) {
    int got = 0;
    EnterCriticalSection(&s->rawLock);
    if (s->rawHead != s->rawTail) {
        int wheel = s->rawRing[s->rawTail].message == WM_MOUSEWHEEL;
        if (wheel && !transfer_windows_wheel(s, &s->rawRing[s->rawTail])) {
            LeaveCriticalSection(&s->rawLock);
            return 0;
        }
        /* Already transferred once above; do not dispatch this wheel twice. */
        if (message) *message = wheel ? 0u : s->rawRing[s->rawTail].message;
        if (wParam) *wParam = s->rawRing[s->rawTail].wParam;
        if (lParam) *lParam = s->rawRing[s->rawTail].lParam;
        if (modifiers) *modifiers = s->rawRing[s->rawTail].modifiers;
        if (imeSlot) *imeSlot = s->rawRing[s->rawTail].imeSlot;
        CjguiWindowsRawRecord *raw=&s->rawRing[s->rawTail];
        if (raw->message==WM_KEYDOWN || raw->message==WM_CHAR || raw->message==WM_UNICHAR)
            windows_trace(s,"raw_pop",raw->message,raw->wParam,(uint64_t)raw->lParam,
                (uint64_t)raw->modifiers,s->rawHead,s->rawTail);
        s->rawTail = (s->rawTail + 1u) % CJGUI_WINDOWS_RAW_RING_CAPACITY;
        // All contiguous wheel records were frozen against one geometry.
        // Retire that batch before changing its coordinate epoch; later
        // pointer/navigation records then consume the resulting viewport.
        if (s->multilineViewportEpochPending &&
            (s->rawTail == s->rawHead || s->rawRing[s->rawTail].message != WM_MOUSEWHEEL)) {
            s->coordinateEpoch = next_positive_counter(&g_nextCoordinateEpoch);
            s->multilineViewportEpochPending = 0u;
            windows_cancel_mouse_on_coordinate_change(s);
        }
        got = 1;
    }
    LeaveCriticalSection(&s->rawLock);
    return got;
}

static LRESULT CALLBACK cjgui_window_proc(HWND hwnd, UINT message,
    WPARAM wParam, LPARAM lParam) {
    CjguiWindowsRendererSession *s = (CjguiWindowsRendererSession *)GetWindowLongPtrW(
        hwnd, GWLP_USERDATA);
    if (message == WM_NCCREATE) {
        CREATESTRUCTW *create = (CREATESTRUCTW *)lParam;
        s = (CjguiWindowsRendererSession *)create->lpCreateParams;
        if (s) {
            s->hwnd = hwnd;
            SetWindowLongPtrW(hwnd, GWLP_USERDATA, (LONG_PTR)s);
        }
        return TRUE;
    }
    if (!s) return DefWindowProcW(hwnd, message, wParam, lParam);
    if (message==WM_KEYDOWN || message==WM_KEYUP || message==WM_SYSKEYDOWN || message==WM_SYSKEYUP)
        windows_trace(s,"key",message,(uint64_t)wParam,(uint64_t)lParam,
            (uint64_t)windows_keyboard_modifiers(),(uint64_t)GetMessageExtraInfo(),
            ((uint64_t)(uintptr_t)GetKeyboardLayout(0)<<16)|(uint16_t)GetKeyState(VK_NUMLOCK));
    switch (message) {
        case WM_MOUSEWHEEL: {
            POINT point = { (LONG)(SHORT)LOWORD(lParam), (LONG)(SHORT)HIWORD(lParam) };
            if (!ScreenToClient(hwnd, &point)) return 0;
            raw_ring_push(s, message, (uint64_t)wParam,
                (int64_t)MAKELPARAM(point.x, point.y), windows_keyboard_modifiers());
            return 0;
        }
        case WM_CLOSE:
        case WM_SIZE:
        case WM_KILLFOCUS:
            raw_ring_push(s, (uint32_t)message, (uint64_t)wParam, (int64_t)lParam, 0);
            return 0;
        case WM_DPICHANGED: {
            /* lParam 是系统调用栈上的建议窗口矩形，不可跨线程记录：
               在此同步执行窗口重定位，再把 DPI/尺寸逻辑记为原始输入。 */
            const RECT *suggested = (const RECT *)(intptr_t)lParam;
            if (suggested) SetWindowPos(hwnd, NULL, suggested->left, suggested->top,
                suggested->right - suggested->left, suggested->bottom - suggested->top,
                SWP_NOACTIVATE | SWP_NOZORDER);
            raw_ring_push(s, (uint32_t)message, (uint64_t)wParam, 0, 0);
            return 0;
        }
        case WM_LBUTTONDOWN:
        case WM_LBUTTONDBLCLK:
        case WM_MOUSEMOVE:
        case WM_LBUTTONUP:
        case WM_CAPTURECHANGED:
        case WM_CANCELMODE:
        case WM_KEYDOWN:
        case WM_CHAR:
        case WM_UNICHAR:
        case WM_IME_STARTCOMPOSITION:
        case WM_IME_ENDCOMPOSITION:
            /* 只记录原始输入；修饰键在到达时刻冻结，随记录搬运，
               消费侧不再读取“当前”键盘状态。 */
            if (message == WM_IME_STARTCOMPOSITION)
                position_windows_system_composition(s);
            raw_ring_push(s, (uint32_t)message, (uint64_t)wParam, (int64_t)lParam,
                windows_keyboard_modifiers());
            if (message == WM_IME_STARTCOMPOSITION || message == WM_IME_ENDCOMPOSITION ||
                message == WM_KILLFOCUS) {
                return DefWindowProcW(hwnd, message, wParam, lParam);
            }
            return 0;
        case WM_IME_COMPOSITION: {
            /* 产生点冻结：当场拥有 RESULTSTR/COMPSTR，后续只消费冻结字节。 */
            int64_t slot = freeze_ime_composition(s, lParam);
            raw_ring_push_slot(s, (uint32_t)message, (uint64_t)wParam,
                (int64_t)lParam, windows_keyboard_modifiers(), slot);
            /* The system composition window displays preedit; RESULTSTR is
               consumed only by the frozen owner path. Never let the default
               IME window turn a result into a second WM_IME_CHAR/WM_CHAR edit. */
            LPARAM displayFlags = lParam & ~(LPARAM)(GCS_RESULTSTR |
                GCS_RESULTREADSTR | GCS_RESULTCLAUSE | GCS_RESULTREADCLAUSE);
            if (displayFlags || !lParam)
                return DefWindowProcW(hwnd, message, wParam, displayFlags);
            return 0;
        }
        case WM_IME_CHAR:
            if (s->ownedTextSessionEnabled) return 0;
            return DefWindowProcW(hwnd, message, wParam, lParam);
        case WM_SYSKEYDOWN:
        case WM_SYSKEYUP:
            /* 裸 ALT（上下文位=0，即无其他键同时按下）会让 DefWindowProc 进入
               系统菜单模式：其嵌套模态消息循环会卡住 owner 泵（实测：测试脚本
               向前台应用发送 ALT 解锁键后，应用回合停止推进、探针缝不再执行）。
               消费裸 ALT 的按下与抬起；带键组合（如 Alt+F4）仍走默认处理。 */
            if (wParam == VK_MENU && (lParam & (1 << 29)) == 0) return 0;
            break;
        case WM_APP + 0x351:
            if (wParam==0x43574735u) {
                WCHAR enabled[4]={0};
                if (GetEnvironmentVariableW(L"CJGUI_WINDOWS_ALLOW_DEVICE_FAULT_PROBE",enabled,4)==1 && enabled[0]==L'1')
                    s->controlledDeviceFault=1u;
            }
            return 0;
        case WM_ERASEBKGND:
            return 1; // D3D11 owns the client pixels.
        case WM_PAINT: {
            PAINTSTRUCT paint;
            BeginPaint(hwnd, &paint);
            EndPaint(hwnd, &paint);
            return 0;
        }
        case WM_NCDESTROY:
            SetWindowLongPtrW(hwnd, GWLP_USERDATA, 0);
            s->hwnd = NULL;
            break;
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

/* 驱动线程：把一条原始输入还原成原 WndProc 分支的完整处理。
   与旧 WndProc 的唯一区别：hwnd 取自会话；WM_DPICHANGED 的窗口重定位已在
   UI 线程同步完成，这里只做 DPI/尺寸逻辑。 */
static void dispatch_raw_message(CjguiWindowsRendererSession *s, uint32_t message,
    uint64_t wParam, int64_t lParam, int64_t frozenModifiers, int64_t imeSlot) {
    if (!s) return;
    HWND hwnd = s->hwnd;
    switch (message) {
        case WM_QUIT: {
            CjguiInternalRendererEvent event;
            memset(&event, 0, sizeof(event));
            event.kind = CJGUI_INTERNAL_RENDERER_EVENT_APPLICATION_EXIT_REQUESTED;
            event.projectionVersion = s->sceneVersion;
            (void)push_event_payload(s, &event, "quit", 4u);
            break;
        }
        case WM_CLOSE:
            windows_cancel_mouse_on_coordinate_change(s);
            s->closeRequested = 1;
            enqueue_window_event(s, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_CLOSE);
            break;
        case WM_SIZE: {
            windows_cancel_mouse_on_coordinate_change(s);
            uint32_t width = (uint32_t)((uint64_t)lParam & 0xffffu);
            uint32_t height = (uint32_t)(((uint64_t)lParam >> 16) & 0xffffu);
            s->minimized = ((uint32_t)wParam == SIZE_MINIMIZED);
            s->coordinateEpoch = next_positive_counter(&g_nextCoordinateEpoch);
            CjguiInternalRendererStatus resizeStatus = CJGUI_INTERNAL_RENDERER_OK;
            if (width && height && s->swapChain) resizeStatus = resize_swap_chain(s, width, height);
            if (width && height && (resizeStatus == CJGUI_INTERNAL_RENDERER_OK ||
                resizeStatus == CJGUI_INTERNAL_RENDERER_PRESENT_PENDING)) {
                double scale = (double)(s->dpi ? s->dpi : 96u) / 96.0;
                CjguiInternalRendererEvent event;
                memset(&event, 0, sizeof(event));
                event.kind = CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_RESIZED;
                event.resourceId = -1;
                event.gesturePointerId = -1;
                event.replacementStart16 = -1;
                event.markedStart16 = -1;
                event.selectionStart = (int32_t)floor((double)width / scale);
                event.selectionEnd = (int32_t)floor((double)height / scale);
                event.projectionVersion = s->sceneVersion;
                (void)push_event(s, &event);
            }
            break;
        }
        case WM_DPICHANGED: {
            windows_cancel_mouse_on_coordinate_change(s);
            uint32_t newDpi = (uint32_t)(wParam & 0xffffu);
            if (!newDpi) newDpi = GetDpiForWindow(hwnd);
            if (!newDpi) newDpi = 96u;
            if (newDpi != s->dpi) {
                s->dpi = newDpi;
                ++s->dpiEpoch;
                ++s->resizeVersion;
            }
            s->coordinateEpoch = next_positive_counter(&g_nextCoordinateEpoch);
            RECT client;
            if (GetClientRect(hwnd, &client)) {
                uint32_t width = (uint32_t)(client.right - client.left);
                uint32_t height = (uint32_t)(client.bottom - client.top);
                if (width && height && s->swapChain) (void)resize_swap_chain(s, width, height);
                if (width && height) {
                    double scale = (double)s->dpi / 96.0;
                    CjguiInternalRendererEvent event;
                    memset(&event, 0, sizeof(event));
                    event.kind = CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_RESIZED;
                    event.resourceId = -1;
                    event.gesturePointerId = -1;
                    event.replacementStart16 = -1;
                    event.markedStart16 = -1;
                    event.selectionStart = (int32_t)floor((double)width / scale);
                    event.selectionEnd = (int32_t)floor((double)height / scale);
                    event.projectionVersion = s->sceneVersion;
                    (void)push_event(s, &event);
                }
            }
            break;
        }
        case WM_KILLFOCUS:
            windows_cancel_mouse_on_coordinate_change(s);
            s->pendingHighSurrogate = 0u;
            s->pendingHighSurrogateBindingEpoch = 0u;
            if (s->compositionState == WINDOWS_COMPOSITION_MARKED)
                end_windows_ime_composition(s);
            break;
        case WM_LBUTTONDOWN:
        case WM_LBUTTONDBLCLK:
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
            s->contractMouseDiag[0] += 1;
#endif
            windows_handle_mouse_down(s, lParam);
            break;
        case WM_MOUSEMOVE:
            windows_handle_mouse_move(s, lParam);
            break;
        case WM_LBUTTONUP:
            windows_handle_mouse_up(s, lParam);
            break;
        case WM_CAPTURECHANGED:
        case WM_CANCELMODE:
            windows_cancel_mouse_on_coordinate_change(s);
            break;
        case WM_KEYDOWN:
            (void)handle_windows_key_down(s, (WPARAM)wParam, frozenModifiers);
            break;
        case WM_CHAR: {
            WCHAR unit = (WCHAR)wParam;
            if (s->compositionState != WINDOWS_COMPOSITION_IDLE || s->compositionActive)
                break; // IMM32 RESULTSTR is the single commit source while composing.
            (void)handle_windows_text_character(s, &unit, 1u, frozenModifiers,
                (uint32_t)((uint64_t)lParam & 0xffffu));
            break;
        }
        case WM_UNICHAR: {
            if (wParam == (uint64_t)UNICODE_NOCHAR) break;
            uint32_t scalar = (uint32_t)wParam;
            WCHAR units[2];
            uint32_t count = 1u;
            if (scalar > 0x10ffffu || (scalar >= 0xd800u && scalar <= 0xdfffu))
                scalar = 0xfffdu;
            if (scalar > 0xffffu) {
                scalar -= 0x10000u;
                units[0] = (WCHAR)(0xd800u + (scalar >> 10));
                units[1] = (WCHAR)(0xdc00u + (scalar & 0x3ffu));
                count = 2u;
            } else {
                units[0] = (WCHAR)scalar;
            }
            if (s->compositionState != WINDOWS_COMPOSITION_IDLE || s->compositionActive)
                break;
            (void)handle_windows_text_character(s, units, count, frozenModifiers, 1u);
            break;
        }
        case WM_IME_STARTCOMPOSITION:
            s->compositionActive = 1;
            break;
        case WM_IME_ENDCOMPOSITION:
            s->compositionActive = 0;
            end_windows_ime_composition(s);
            break;
        case WM_IME_COMPOSITION:
            if (s->ownedTextSessionEnabled) {
                (void)handle_windows_ime_composition(s, (LPARAM)lParam, imeSlot);
            }
            break;
        default:
            break;
    }
}

static BOOL CALLBACK register_window_class(PINIT_ONCE once, PVOID parameter,
    PVOID *context) {
    (void)once; (void)parameter; (void)context;
    WNDCLASSEXW wc;
    memset(&wc, 0, sizeof(wc));
    wc.cbSize = sizeof(wc);
    wc.style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
    wc.lpfnWndProc = cjgui_window_proc;
    wc.hInstance = GetModuleHandleW(NULL);
    wc.hCursor = LoadCursorW(NULL, MAKEINTRESOURCEW(32512));
    /* GWLP_USERDATA 存会话指针，必须预留窗口附加字节；否则是堆越界写
       （实测在 ShowWindow 等系统回调路径随机崩溃）。 */
    wc.cbWndExtra = sizeof(LONG_PTR);
    wc.lpszClassName = CJGUI_WINDOWS_CLASS;
    g_windowClassReady = RegisterClassExW(&wc) != 0 || GetLastError() == ERROR_CLASS_ALREADY_EXISTS;
    return TRUE;
}

static CjguiInternalRendererStatus create_device_for_window(CjguiWindowsRendererSession *s,
    uint32_t clientWidth, uint32_t clientHeight) {
    DXGI_SWAP_CHAIN_DESC scd;
    memset(&scd, 0, sizeof(scd));
    scd.BufferDesc.Width = clientWidth;
    scd.BufferDesc.Height = clientHeight;
    scd.BufferDesc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
    scd.BufferDesc.RefreshRate.Numerator = 60;
    scd.BufferDesc.RefreshRate.Denominator = 1;
    scd.SampleDesc.Count = 1;
    scd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    scd.BufferCount = 2;
    scd.OutputWindow = s->hwnd;
    scd.Windowed = TRUE;
    scd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;
    D3D_FEATURE_LEVEL requested[] = {
        D3D_FEATURE_LEVEL_11_1, D3D_FEATURE_LEVEL_11_0,
        D3D_FEATURE_LEVEL_10_1, D3D_FEATURE_LEVEL_10_0
    };
    D3D_FEATURE_LEVEL actual;
    HRESULT hr = D3D11CreateDeviceAndSwapChain(NULL, D3D_DRIVER_TYPE_HARDWARE, NULL,
        D3D11_CREATE_DEVICE_BGRA_SUPPORT, requested,
        (UINT)(sizeof(requested) / sizeof(requested[0])), D3D11_SDK_VERSION,
        &scd, &s->swapChain, &s->device, &actual, &s->context);
    if (hr == E_INVALIDARG) {
        hr = D3D11CreateDeviceAndSwapChain(NULL, D3D_DRIVER_TYPE_HARDWARE, NULL,
            D3D11_CREATE_DEVICE_BGRA_SUPPORT, requested + 1,
            (UINT)(sizeof(requested) / sizeof(requested[0]) - 1), D3D11_SDK_VERSION,
            &scd, &s->swapChain, &s->device, &actual, &s->context);
    }
    if (FAILED(hr)) {
        s->lastGraphicsFailure = hr;
        release_graphics(s);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    hr = DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, &IID_IDWriteFactory,
        (IUnknown **)&s->writeFactory);
    if (FAILED(hr) || !s->writeFactory) {
        s->lastGraphicsFailure = hr;
        release_graphics(s);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    s->width = clientWidth;
    s->height = clientHeight;
    CjguiInternalRendererStatus status = create_render_target(s);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        release_graphics(s);
        return status;
    }
    status = create_scene_pipeline(s);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        release_graphics(s);
        return status;
    }
    ++s->deviceGeneration;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus create_window_and_device(
    CjguiWindowsRendererSession *s, uint32_t clientWidth, uint32_t clientHeight) {
    if (!SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)) {
        DPI_AWARENESS_CONTEXT current = GetThreadDpiAwarenessContext();
        if (!AreDpiAwarenessContextsEqual(current, DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2))
            return CJGUI_INTERNAL_RENDERER_WINDOW_CREATE_FAILED;
    }
    if (!InitOnceExecuteOnce(&g_windowClassOnce, register_window_class, NULL, NULL) ||
        !g_windowClassReady) return CJGUI_INTERNAL_RENDERER_WINDOW_CREATE_FAILED;

    uint32_t initialDpi = GetDpiForSystem();
    if (!initialDpi) initialDpi = 96u;
    double initialScale = (double)initialDpi / 96.0;
    double initialClientWidth = ceil((double)clientWidth * initialScale);
    double initialClientHeight = ceil((double)clientHeight * initialScale);
    if (initialClientWidth > LONG_MAX || initialClientHeight > LONG_MAX)
        return CJGUI_INTERNAL_RENDERER_WINDOW_CREATE_FAILED;
    RECT rect = {0, 0, (LONG)initialClientWidth, (LONG)initialClientHeight};
    DWORD style = WS_OVERLAPPEDWINDOW;
    if (!AdjustWindowRectExForDpi(&rect, style, FALSE, 0, initialDpi))
        return CJGUI_INTERNAL_RENDERER_WINDOW_CREATE_FAILED;
    s->hwnd = CreateWindowExW(0, CJGUI_WINDOWS_CLASS, CJGUI_WINDOWS_TITLE, style,
        CW_USEDEFAULT, CW_USEDEFAULT, rect.right - rect.left, rect.bottom - rect.top,
        NULL, NULL, GetModuleHandleW(NULL), s);
    if (!s->hwnd) return CJGUI_INTERNAL_RENDERER_WINDOW_CREATE_FAILED;
    s->dpi = GetDpiForWindow(s->hwnd);
    if (!s->dpi) s->dpi = initialDpi;
    s->dpiEpoch = 1u;
    RECT clientRect;
    if (!GetClientRect(s->hwnd, &clientRect) || clientRect.right <= clientRect.left ||
        clientRect.bottom <= clientRect.top) {
        DestroyWindow(s->hwnd); s->hwnd = NULL;
        return CJGUI_INTERNAL_RENDERER_WINDOW_CREATE_FAILED;
    }
    clientWidth = (uint32_t)(clientRect.right - clientRect.left);
    clientHeight = (uint32_t)(clientRect.bottom - clientRect.top);

    CjguiInternalRendererStatus status=create_device_for_window(s,clientWidth,clientHeight);
    if (status!=CJGUI_INTERNAL_RENDERER_OK) {
        DestroyWindow(s->hwnd); s->hwnd=NULL; return status;
    }
    s->ownedImeContext = ImmCreateContext();
    if (!s->ownedImeContext) {
        DestroyWindow(s->hwnd);
        s->hwnd = NULL;
        release_graphics(s);
        return CJGUI_INTERNAL_RENDERER_WINDOW_CREATE_FAILED;
    }
    s->originalImeContext = ImmAssociateContext(s->hwnd, s->ownedImeContext);
    HIMC verifyImeContext = ImmGetContext(s->hwnd);
    int imeAssociated = verifyImeContext == s->ownedImeContext;
    if (verifyImeContext) ImmReleaseContext(s->hwnd, verifyImeContext);
    if (!imeAssociated) {
        (void)ImmAssociateContext(s->hwnd, s->originalImeContext);
        ImmDestroyContext(s->ownedImeContext);
        s->ownedImeContext = NULL;
        s->originalImeContext = NULL;
        DestroyWindow(s->hwnd);
        s->hwnd = NULL;
        release_graphics(s);
        return CJGUI_INTERNAL_RENDERER_WINDOW_CREATE_FAILED;
    }
    ShowWindow(s->hwnd, SW_SHOWNOACTIVATE);
    UpdateWindow(s->hwnd);
    // 新窗口主动取前台（等价 macOS activate）：前台锁下用 AttachThreadInput
    // 组合允许本进程把刚创建的窗口置前，否则隐藏/后台启动会让首屏不可见。
    {
        HWND foreground = GetForegroundWindow();
        DWORD foregroundThread = foreground ? GetWindowThreadProcessId(foreground, NULL) : 0u;
        DWORD appThread = GetWindowThreadProcessId(s->hwnd, NULL);
        DWORD currentThread = GetCurrentThreadId();
        if (foregroundThread && foregroundThread != currentThread)
            AttachThreadInput(currentThread, foregroundThread, TRUE);
        if (appThread && appThread != currentThread)
            AttachThreadInput(currentThread, appThread, TRUE);
        SetForegroundWindow(s->hwnd);
        BringWindowToTop(s->hwnd);
        SetActiveWindow(s->hwnd);
        SetFocus(s->hwnd);
        if (appThread && appThread != currentThread)
            AttachThreadInput(currentThread, appThread, FALSE);
        if (foregroundThread && foregroundThread != currentThread)
            AttachThreadInput(currentThread, foregroundThread, FALSE);
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

/* A failed synchronous frame has no outstanding presentation ticket. Retain
 * device recovery separately, and wake the existing UI message-pump owner. */
static void request_windows_graphics_recovery(CjguiWindowsRendererSession *s,int controlled) {
    s->graphicsRecoveryPending=1u;
    if (controlled) s->graphicsRecoveryControlled=1u;
    if (s->rawWakeEvent) SetEvent(s->rawWakeEvent);
}
static CjguiInternalRendererStatus windows_unsubmitted_present_status(
    CjguiWindowsRendererSession *s,CjguiInternalRendererStatus status) {
    if (status!=CJGUI_INTERNAL_RENDERER_PRESENT_PENDING) return status;
    return s->graphicsRecoveryPending ? CJGUI_INTERNAL_RENDERER_METAL_DEVICE_UNAVAILABLE :
        CJGUI_INTERNAL_RENDERER_METAL_COMMAND_BUFFER_UNAVAILABLE;
}

static CjguiInternalRendererStatus present_clear_color(
    CjguiWindowsRendererSession *s, double red, double green, double blue, double alpha) {
    if (!s || !s->device || !s->context || !s->swapChain || !s->renderTarget)
        return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    ID3D11DeviceContext_OMSetRenderTargets(s->context, 1, &s->renderTarget, NULL);
    D3D11_VIEWPORT viewport;
    viewport.TopLeftX = 0.0f; viewport.TopLeftY = 0.0f;
    viewport.Width = (FLOAT)s->width; viewport.Height = (FLOAT)s->height;
    viewport.MinDepth = 0.0f; viewport.MaxDepth = 1.0f;
    ID3D11DeviceContext_RSSetViewports(s->context, 1, &viewport);
    FLOAT color[4] = {(FLOAT)red, (FLOAT)green, (FLOAT)blue, (FLOAT)alpha};
    ID3D11DeviceContext_ClearRenderTargetView(s->context, s->renderTarget, color);
    HRESULT hr = IDXGISwapChain_Present(s->swapChain, 1, 0);
    if (FAILED(hr)) {
        s->lastGraphicsFailure = hr;
        if (windows_hresult_is_device_lost(hr)) {
            request_windows_graphics_recovery(s,0);
            return CJGUI_INTERNAL_RENDERER_METAL_DEVICE_UNAVAILABLE;
        }
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    s->frameIndex += 1;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus create_measured_text_layout_for_factory(
    IDWriteFactory *factory, HRESULT *outFailure, const char *utf8, double fontSize,
    uint32_t fontWeight, uint32_t fontFamily, float maxWidth, float maxHeight,
    IDWriteTextLayout **outLayout, DWRITE_TEXT_METRICS *outMetrics,uint64_t *timings) {
    uint64_t utfAt=timings?cjgui_internal_renderer_owner_clock_ns():0;
    if (!(fontWeight == 0u || fontWeight == 1u ||
          (fontWeight >= 100u && fontWeight <= 900u && fontWeight % 100u == 0u)) ||
        fontFamily > 3u) return CJGUI_INTERNAL_RENDERER_STYLE_RUN_INVALID;
    if (!factory || !utf8 || !outLayout || !outMetrics ||
        !isfinite(fontSize) || fontSize <= 0.0 || fontSize > 512.0 ||
        !isfinite(maxWidth) || maxWidth <= 0.0f || !isfinite(maxHeight) || maxHeight <= 0.0f)
        return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    *outLayout = NULL;
    memset(outMetrics, 0, sizeof(*outMetrics));
    size_t byteCount = strnlen(utf8, 1024u * 1024u + 1u);
    if (byteCount > 1024u * 1024u || byteCount > INT_MAX)
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    int wideCount = byteCount == 0 ? 0 : MultiByteToWideChar(CP_UTF8,
        MB_ERR_INVALID_CHARS, utf8, (int)byteCount, NULL, 0);
    if (byteCount != 0 && wideCount <= 0) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    WCHAR *wide = (WCHAR *)calloc((size_t)wideCount + 1u, sizeof(WCHAR));
    if (!wide) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (wideCount && MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8,
        (int)byteCount, wide, wideCount) != wideCount) {
        free(wide);
        return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    }
    const WCHAR *family = (fontFamily & 1u) ? L"Consolas" : L"Segoe UI";
    uint64_t writeAt=timings?cjgui_internal_renderer_owner_clock_ns():0;
    if(timings)timings[0]=writeAt-utfAt;
    DWRITE_FONT_STYLE style = fontFamily >= 2u ? DWRITE_FONT_STYLE_ITALIC : DWRITE_FONT_STYLE_NORMAL;
    uint32_t weightValue = fontWeight == 0u ? 400u : fontWeight == 1u ? 700u : fontWeight;
    IDWriteTextFormat *format = NULL;
    IDWriteTextLayout *layout = NULL;
    HRESULT hr = IDWriteFactory_CreateTextFormat(factory, family, NULL,
        (DWRITE_FONT_WEIGHT)weightValue, style,
        DWRITE_FONT_STRETCH_NORMAL, (FLOAT)fontSize, L"en-us", &format);
    if (SUCCEEDED(hr)) hr = IDWriteTextFormat_SetWordWrapping(format, DWRITE_WORD_WRAPPING_WRAP);
    if (SUCCEEDED(hr)) hr = IDWriteFactory_CreateTextLayout(factory, wide,
        (UINT32)wideCount, format, maxWidth, maxHeight, &layout);
    if (SUCCEEDED(hr)) hr = IDWriteTextLayout_GetMetrics(layout, outMetrics);
    if(timings)timings[1]=cjgui_internal_renderer_owner_clock_ns()-writeAt;
    free(wide);
    if (format) IDWriteTextFormat_Release(format);
    if (FAILED(hr) || !layout) {
        if (layout) IDWriteTextLayout_Release(layout);
        if (outFailure) *outFailure = hr;
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    *outLayout = layout;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus create_measured_text_layout(
    CjguiWindowsRendererSession *s, const char *utf8, double fontSize,
    uint32_t fontWeight, uint32_t fontFamily, float maxWidth, float maxHeight,
    IDWriteTextLayout **outLayout, DWRITE_TEXT_METRICS *outMetrics) {
    if (!s) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    uint64_t timings[2]={0};
    CjguiInternalRendererStatus result=create_measured_text_layout_for_factory(
        s->writeFactory,&s->lastGraphicsFailure,utf8,fontSize,fontWeight,fontFamily,
        maxWidth,maxHeight,outLayout,outMetrics,s->traceEnabled?timings:NULL);
    if(s->traceEnabled && utf8 && strlen(utf8)>8192u)
        windows_trace(s,"dwrite",strlen(utf8),timings[0],timings[1],(uint64_t)maxWidth,(uint64_t)maxHeight,result);
    if (result==CJGUI_INTERNAL_RENDERER_OK) s->textLayoutPreparationCount+=1u;
    return result;
}

static CjguiInternalRendererStatus create_styled_text_layout(
    CjguiWindowsRendererSession *s, CjguiWindowsSceneNode *node, const char *text,
    float maxWidth, float maxHeight, IDWriteTextLayout **outLayout,
    DWRITE_TEXT_METRICS *outMetrics) {
    CjguiInternalRendererStatus status = create_measured_text_layout(s, text,
        node->node.fontSize > 0.0 ? node->node.fontSize : 14.0,
        node->node.fontWeight, node->node.fontFamily, maxWidth, maxHeight,
        outLayout, outMetrics);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiWindowsTextStyleRun *runs = NULL;
    uint32_t count = 0u;
    status = parse_style_run_list(node->textRuns ? node->textRuns : "", text, &runs, &count);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        IDWriteTextLayout_Release(*outLayout);
        *outLayout = NULL;
        return status;
    }
    for (uint32_t i = 0; i < count && status == CJGUI_INTERNAL_RENDERER_OK; ++i) {
        CjguiWindowsTextStyleRun *run = &runs[i];
        if (run->selectionBackgroundOnly) continue;
        DWRITE_TEXT_RANGE range = {run->start16, run->end16 - run->start16};
        uint32_t weight = run->fontWeight == 0u ? 400u : run->fontWeight == 1u ? 700u : run->fontWeight;
        const WCHAR *family = (run->fontFamily & 1u) ? L"Consolas" : L"Segoe UI";
        DWRITE_FONT_STYLE style = run->fontFamily >= 2u
            ? DWRITE_FONT_STYLE_ITALIC : DWRITE_FONT_STYLE_NORMAL;
        HRESULT hr = IDWriteTextLayout_SetFontSize(*outLayout, run->fontSize, range);
        if (SUCCEEDED(hr)) hr = IDWriteTextLayout_SetFontWeight(*outLayout,
            (DWRITE_FONT_WEIGHT)weight, range);
        if (SUCCEEDED(hr)) hr = IDWriteTextLayout_SetFontFamilyName(*outLayout, family, range);
        if (SUCCEEDED(hr)) hr = IDWriteTextLayout_SetFontStyle(*outLayout, style, range);
        FLOAT color[4] = {run->red, run->green, run->blue, run->alpha};
        CjguiWindowsTextColorEffect *effect = SUCCEEDED(hr) ? create_text_color_effect(color) : NULL;
        if (SUCCEEDED(hr) && !effect) hr = E_OUTOFMEMORY;
        if (SUCCEEDED(hr)) hr = IDWriteTextLayout_SetDrawingEffect(*outLayout,
            (IUnknown *)effect, range);
        if (effect) ((IUnknown *)effect)->lpVtbl->Release((IUnknown *)effect);
        if (FAILED(hr)) {
            s->lastGraphicsFailure = hr;
            status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        }
    }
    free(runs);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        IDWriteTextLayout_Release(*outLayout);
        *outLayout = NULL;
        return status;
    }
    HRESULT hr = IDWriteTextLayout_GetMetrics(*outLayout, outMetrics);
    if (FAILED(hr)) {
        s->lastGraphicsFailure = hr;
        IDWriteTextLayout_Release(*outLayout);
        *outLayout = NULL;
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

static void text_renderer_composite(CjguiWindowsTextRenderer *r, RECT bounds,
    const uint8_t *mask, UINT maskWidth, UINT maskHeight, const FLOAT color[4]) {
    for (UINT row = 0; row < maskHeight; ++row) {
        LONG y = bounds.top + (LONG)row;
        if (y < 0 || (UINT)y >= r->height) continue;
        for (UINT column = 0; column < maskWidth; ++column) {
            LONG x = bounds.left + (LONG)column;
            if (x < 0 || (UINT)x >= r->width) continue;
            uint8_t *target = &r->pixels[((size_t)y * r->width + (UINT)x) * 4u];
            FLOAT sourceAlpha = ((FLOAT)mask[(size_t)row * maskWidth + column] / 255.0f) * color[3];
            if (sourceAlpha <= 0.0f) continue;
            FLOAT targetAlpha = (FLOAT)target[3] / 255.0f;
            FLOAT resultAlpha = sourceAlpha + targetAlpha * (1.0f - sourceAlpha);
            if (resultAlpha <= 0.0f) continue;
            const FLOAT components[3] = {color[0], color[1], color[2]};
            for (UINT component = 0; component < 3u; ++component) {
                FLOAT old = (FLOAT)target[component] / 255.0f;
                FLOAT blended = (components[component] * sourceAlpha +
                    old * targetAlpha * (1.0f - sourceAlpha)) / resultAlpha;
                target[component] = (uint8_t)lroundf(fminf(1.0f, fmaxf(0.0f, blended)) * 255.0f);
            }
            uint8_t alpha = (uint8_t)lroundf(fminf(1.0f, resultAlpha) * 255.0f);
            if (alpha > target[3]) {
                target[3] = alpha;
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
                ++r->diagnostic.compositeWrites;
#endif
            }
        }
    }
}

static void text_renderer_fill_rectangle(CjguiWindowsTextRenderer *r, FLOAT x, FLOAT y,
    FLOAT width, FLOAT height, const FLOAT color[4]) {
    if (!r || !r->pixels || !isfinite(x) || !isfinite(y) || !isfinite(width) ||
        !isfinite(height) || width <= 0.0f || height <= 0.0f) return;
    FLOAT scale = r->pixelsPerDip;
    LONG left = (LONG)floorf(x * scale);
    LONG top = (LONG)floorf(y * scale);
    LONG right = (LONG)ceilf((x + width) * scale);
    LONG bottom = (LONG)ceilf((y + height) * scale);
    if (left < 0) left = 0;
    if (top < 0) top = 0;
    if (right > (LONG)r->width) right = (LONG)r->width;
    if (bottom > (LONG)r->height) bottom = (LONG)r->height;
    for (LONG py = top; py < bottom; ++py) {
        for (LONG px = left; px < right; ++px) {
            uint8_t *pixel = &r->pixels[((size_t)py * r->width + (UINT)px) * 4u];
            pixel[0] = (uint8_t)lroundf(color[0] * 255.0f);
            pixel[1] = (uint8_t)lroundf(color[1] * 255.0f);
            pixel[2] = (uint8_t)lroundf(color[2] * 255.0f);
            pixel[3] = (uint8_t)lroundf(color[3] * 255.0f);
        }
    }
}

static HRESULT STDMETHODCALLTYPE text_renderer_query_interface(CjguiWindowsTextRenderer *r,
    REFIID iid, void **out) {
    if (!out) return E_POINTER;
    *out = NULL;
    if (IsEqualIID(iid, &IID_IUnknown) || IsEqualIID(iid, &IID_IDWritePixelSnapping) ||
        IsEqualIID(iid, &IID_IDWriteTextRenderer)) {
        *out = r;
        ++r->refs;
        return S_OK;
    }
    return E_NOINTERFACE;
}

static ULONG STDMETHODCALLTYPE text_renderer_add_ref(CjguiWindowsTextRenderer *r) {
    return ++r->refs;
}

static ULONG STDMETHODCALLTYPE text_renderer_release(CjguiWindowsTextRenderer *r) {
    if (r->refs) --r->refs;
    return r->refs;
}

static HRESULT STDMETHODCALLTYPE text_renderer_is_pixel_snapping_disabled(
    CjguiWindowsTextRenderer *r, void *context, BOOL *out) {
    (void)context;
    if (!r || !out) return E_POINTER;
    *out = FALSE;
    return S_OK;
}

static HRESULT STDMETHODCALLTYPE text_renderer_get_transform(CjguiWindowsTextRenderer *r,
    void *context, DWRITE_MATRIX *out) {
    (void)context;
    if (!r || !out) return E_POINTER;
    out->m11 = 1.0f; out->m12 = 0.0f; out->m21 = 0.0f; out->m22 = 1.0f;
    out->dx = 0.0f; out->dy = 0.0f;
    return S_OK;
}

static HRESULT STDMETHODCALLTYPE text_renderer_get_pixels_per_dip(CjguiWindowsTextRenderer *r,
    void *context, FLOAT *out) {
    (void)context;
    if (!r || !out) return E_POINTER;
    *out = r->pixelsPerDip;
    return S_OK;
}

static const IID IID_CJGUI_WINDOWS_TEXT_COLOR_EFFECT = {
    0x79b81e41, 0xe6af, 0x4e1d, {0x9b, 0x3d, 0x6d, 0x3d, 0xb2, 0x87, 0x82, 0x11}
};

static HRESULT STDMETHODCALLTYPE text_color_effect_query_interface(IUnknown *unknown,
    REFIID iid, void **out) {
    if (!out) return E_POINTER;
    *out = NULL;
    if (IsEqualIID(iid, &IID_IUnknown) || IsEqualIID(iid, &IID_CJGUI_WINDOWS_TEXT_COLOR_EFFECT)) {
        *out = unknown;
        unknown->lpVtbl->AddRef(unknown);
        return S_OK;
    }
    return E_NOINTERFACE;
}

static ULONG STDMETHODCALLTYPE text_color_effect_add_ref(IUnknown *unknown) {
    CjguiWindowsTextColorEffect *effect = (CjguiWindowsTextColorEffect *)unknown;
    return (ULONG)InterlockedIncrement(&effect->refs);
}

static ULONG STDMETHODCALLTYPE text_color_effect_release(IUnknown *unknown) {
    CjguiWindowsTextColorEffect *effect = (CjguiWindowsTextColorEffect *)unknown;
    LONG refs = InterlockedDecrement(&effect->refs);
    if (refs == 0) free(effect);
    return (ULONG)(refs < 0 ? 0 : refs);
}

static const IUnknownVtbl g_textColorEffectVtbl = {
    text_color_effect_query_interface,
    text_color_effect_add_ref,
    text_color_effect_release
};

static CjguiWindowsTextColorEffect *create_text_color_effect(const FLOAT color[4]) {
    if (!color) return NULL;
    CjguiWindowsTextColorEffect *effect = (CjguiWindowsTextColorEffect *)calloc(1u, sizeof(*effect));
    if (!effect) return NULL;
    effect->lpVtbl = &g_textColorEffectVtbl;
    effect->refs = 1;
    effect->red = color[0]; effect->green = color[1];
    effect->blue = color[2]; effect->alpha = color[3];
    return effect;
}

static HRESULT STDMETHODCALLTYPE text_renderer_draw_glyph_run(CjguiWindowsTextRenderer *r,
    void *context, FLOAT originX, FLOAT originY, DWRITE_MEASURING_MODE measuringMode,
    const DWRITE_GLYPH_RUN *glyphRun, const DWRITE_GLYPH_RUN_DESCRIPTION *description,
    IUnknown *drawingEffect) {
    (void)context; (void)description;
    if (!r || !glyphRun) return E_POINTER;
    FLOAT color[4] = {r->defaultRed, r->defaultGreen, r->defaultBlue, r->defaultAlpha};
    if (drawingEffect) {
        void *rawEffect = NULL;
        HRESULT effectHr = drawingEffect->lpVtbl->QueryInterface(drawingEffect,
            &IID_CJGUI_WINDOWS_TEXT_COLOR_EFFECT, &rawEffect);
        if (SUCCEEDED(effectHr) && rawEffect) {
            CjguiWindowsTextColorEffect *effect = (CjguiWindowsTextColorEffect *)rawEffect;
            color[0] = effect->red; color[1] = effect->green;
            color[2] = effect->blue; color[3] = effect->alpha * r->defaultAlpha;
            ((IUnknown *)rawEffect)->lpVtbl->Release((IUnknown *)rawEffect);
        }
    }
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    ++r->diagnostic.glyphRunCalls;
    r->diagnostic.glyphCount = glyphRun->glyphCount;
    r->diagnostic.fontEmSize = glyphRun->fontEmSize;
    r->diagnostic.activeTextureType = DWRITE_TEXTURE_CLEARTYPE_3x1;
    r->diagnostic.alphaTextureHr = E_PENDING;
#endif
    IDWriteFactory *factory = r->factory;
    if (!factory) return E_FAIL;
    IDWriteGlyphRunAnalysis *analysis = NULL;
    HRESULT hr = IDWriteFactory_CreateGlyphRunAnalysis(factory, glyphRun, r->pixelsPerDip, NULL,
        DWRITE_RENDERING_MODE_NATURAL, measuringMode, originX, originY, &analysis);
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    r->diagnostic.analysisHr = (int32_t)hr;
#endif
    if (FAILED(hr) || !analysis) return FAILED(hr) ? hr : E_FAIL;
    RECT bounds; memset(&bounds, 0, sizeof(bounds));
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    RECT aliasBounds; memset(&aliasBounds, 0, sizeof(aliasBounds));
    HRESULT aliasHr = IDWriteGlyphRunAnalysis_GetAlphaTextureBounds(analysis,
        DWRITE_TEXTURE_ALIASED_1x1, &aliasBounds);
    r->diagnostic.boundsAliasHr = (int32_t)aliasHr;
    r->diagnostic.aliasLeft = aliasBounds.left; r->diagnostic.aliasTop = aliasBounds.top;
    r->diagnostic.aliasRight = aliasBounds.right; r->diagnostic.aliasBottom = aliasBounds.bottom;
#endif
    hr = IDWriteGlyphRunAnalysis_GetAlphaTextureBounds(analysis,
        DWRITE_TEXTURE_CLEARTYPE_3x1, &bounds);
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    r->diagnostic.boundsClearTypeHr = (int32_t)hr;
    r->diagnostic.clearTypeLeft = bounds.left; r->diagnostic.clearTypeTop = bounds.top;
    r->diagnostic.clearTypeRight = bounds.right; r->diagnostic.clearTypeBottom = bounds.bottom;
#endif
    if (FAILED(hr)) { IDWriteGlyphRunAnalysis_Release(analysis); return hr; }
    LONG width = bounds.right - bounds.left, height = bounds.bottom - bounds.top;
    if (width <= 0 || height <= 0) { IDWriteGlyphRunAnalysis_Release(analysis); return S_OK; }
    if (width > 8192 || height > 8192 || (uint64_t)width * (uint64_t)height > 4u * 1024u * 1024u) {
        IDWriteGlyphRunAnalysis_Release(analysis);
        return E_OUTOFMEMORY;
    }
    size_t pixelCount = (size_t)width * (size_t)height;
    if (pixelCount > (size_t)UINT32_MAX / 3u || pixelCount > SIZE_MAX / 4u) {
        IDWriteGlyphRunAnalysis_Release(analysis);
        return E_OUTOFMEMORY;
    }
    size_t alphaBytes = pixelCount * 3u;
    size_t maskBytes = pixelCount;
    size_t callbackScratchBytes = alphaBytes + maskBytes;
    if (!text_budget_reserve_scratch(r->session, (uint64_t)callbackScratchBytes)) {
        IDWriteGlyphRunAnalysis_Release(analysis);
        r->budgetRejected = 1u;
        return E_OUTOFMEMORY;
    }
    uint8_t *alpha = (uint8_t *)malloc(alphaBytes);
    uint8_t *mask = (uint8_t *)malloc(maskBytes);
    if (!alpha || !mask) {
        free(alpha); free(mask);
        text_budget_release_scratch(r->session, (uint64_t)callbackScratchBytes);
        IDWriteGlyphRunAnalysis_Release(analysis);
        return E_OUTOFMEMORY;
    }
    hr = IDWriteGlyphRunAnalysis_CreateAlphaTexture(analysis, DWRITE_TEXTURE_CLEARTYPE_3x1,
        &bounds, alpha, (UINT32)alphaBytes);
    IDWriteGlyphRunAnalysis_Release(analysis);
    if (SUCCEEDED(hr)) {
        for (size_t i = 0; i < pixelCount; ++i) {
            unsigned int red = alpha[i * 3u];
            unsigned int green = alpha[i * 3u + 1u];
            unsigned int blue = alpha[i * 3u + 2u];
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
            if (red) ++r->diagnostic.alphaTextureNonzero;
            if (green) ++r->diagnostic.alphaTextureNonzero;
            if (blue) ++r->diagnostic.alphaTextureNonzero;
#endif
            mask[i] = (uint8_t)((red + green + blue + 1u) / 3u);
        }
        text_renderer_composite(r, bounds, mask, (UINT)width, (UINT)height, color);
    } else r->failure = hr;
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    r->diagnostic.alphaTextureHr = (int32_t)hr;
#endif
    free(alpha); free(mask);
    text_budget_release_scratch(r->session, (uint64_t)callbackScratchBytes);
    return hr;
}

static HRESULT STDMETHODCALLTYPE text_renderer_draw_decoration(CjguiWindowsTextRenderer *r,
    FLOAT originX, FLOAT originY, FLOAT width, FLOAT offset, FLOAT thickness) {
    if (!r || !r->pixels || !isfinite(originX) || !isfinite(originY) ||
        !isfinite(width) || !isfinite(offset) || !isfinite(thickness)) return E_INVALIDARG;
    FLOAT color[4] = {r->defaultRed, r->defaultGreen, r->defaultBlue, r->defaultAlpha};
    text_renderer_fill_rectangle(r, originX, originY + offset - thickness * 0.5f,
        width, fmaxf(1.0f, thickness), color);
    return S_OK;
}

static HRESULT STDMETHODCALLTYPE text_renderer_draw_underline(CjguiWindowsTextRenderer *r,
    void *context, FLOAT x, FLOAT y, const DWRITE_UNDERLINE *u, IUnknown *effect) {
    (void)context; (void)effect;
    return u ? text_renderer_draw_decoration(r, x, y, u->width, u->offset, u->thickness) : E_POINTER;
}

static HRESULT STDMETHODCALLTYPE text_renderer_draw_strikethrough(CjguiWindowsTextRenderer *r,
    void *context, FLOAT x, FLOAT y, const DWRITE_STRIKETHROUGH *strike, IUnknown *effect) {
    (void)context; (void)effect;
    return strike ? text_renderer_draw_decoration(r, x, y, strike->width,
        strike->offset, strike->thickness) : E_POINTER;
}

static HRESULT STDMETHODCALLTYPE text_renderer_draw_inline_object(CjguiWindowsTextRenderer *r,
    void *context, FLOAT x, FLOAT y, IDWriteInlineObject *object, BOOL sideways,
    BOOL rightToLeft, IUnknown *effect) {
    if (!object) return S_OK;
    return IDWriteInlineObject_Draw(object, context, (IDWriteTextRenderer *)r,
        x, y, sideways, rightToLeft, effect);
}

static const CjguiWindowsTextRendererVtbl g_textRendererVtbl = {
    text_renderer_query_interface, text_renderer_add_ref, text_renderer_release,
    text_renderer_is_pixel_snapping_disabled, text_renderer_get_transform,
    text_renderer_get_pixels_per_dip, text_renderer_draw_glyph_run,
    text_renderer_draw_underline, text_renderer_draw_strikethrough,
    text_renderer_draw_inline_object
};

static CjguiInternalRendererStatus apply_text_run_backgrounds(CjguiWindowsRendererSession *s,
    CjguiWindowsSceneNode *node, const char *runText, IDWriteTextLayout *layout,
    CjguiWindowsTextRenderer *renderer) {
    CjguiWindowsTextStyleRun *runs = NULL;
    uint32_t count = 0u;
    CjguiInternalRendererStatus status = parse_style_run_list(
        node->textRuns ? node->textRuns : "", runText ? runText : "", &runs, &count);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    for (uint32_t i = 0; i < count; ++i) {
        CjguiWindowsTextStyleRun *run = &runs[i];
        if (!run->hasBackground) continue;
        UINT32 metricCount = 0u;
        DWRITE_TEXT_RANGE range = {run->start16, run->end16 - run->start16};
        HRESULT hr = IDWriteTextLayout_HitTestTextRange(layout, range.startPosition,
            range.length, 0.0f, 0.0f, NULL, 0u, &metricCount);
        if (metricCount > 16384u || (FAILED(hr) && hr != E_NOT_SUFFICIENT_BUFFER)) {
            free(runs);
            s->lastGraphicsFailure = hr;
            return metricCount > 16384u ? CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED
                : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        }
        if (!metricCount) continue;
        uint64_t bytes = (uint64_t)metricCount * sizeof(DWRITE_HIT_TEST_METRICS);
        if (!text_budget_reserve_scratch(s, bytes)) {
            free(runs);
            return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
        }
        DWRITE_HIT_TEST_METRICS *metrics = (DWRITE_HIT_TEST_METRICS *)calloc(metricCount, sizeof(*metrics));
        if (!metrics) {
            text_budget_release_scratch(s, bytes);
            free(runs);
            return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        }
        UINT32 actualCount = 0u;
        hr = IDWriteTextLayout_HitTestTextRange(layout, range.startPosition,
            range.length, 0.0f, 0.0f, metrics, metricCount, &actualCount);
        if (FAILED(hr) || actualCount > metricCount) {
            free(metrics);
            text_budget_release_scratch(s, bytes);
            free(runs);
            s->lastGraphicsFailure = hr;
            return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        }
        FLOAT color[4] = {run->backgroundRed, run->backgroundGreen,
            run->backgroundBlue, run->backgroundAlpha};
        for (UINT32 rect = 0; rect < actualCount; ++rect) {
            if (metrics[rect].width > 0.0f && metrics[rect].height > 0.0f)
                text_renderer_fill_rectangle(renderer,
                    metrics[rect].left - renderer->rasterOriginX,
                    metrics[rect].top - renderer->rasterOriginY,
                    metrics[rect].width, metrics[rect].height, color);
        }
        free(metrics);
        text_budget_release_scratch(s, bytes);
    }
    free(runs);
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus rasterize_text_layout(CjguiWindowsRendererSession *s,
    CjguiWindowsSceneNode *node, const char *runText, IDWriteTextLayout *layout,
    double logicalWidth, double logicalHeight, double originX, double originY, int applyRuns,
    CjguiWindowsTextTextureLease **outLease,
    uint32_t *outWidth, uint32_t *outHeight, uint64_t *outNonzero) {
    if (outLease) *outLease = NULL;
    if (outWidth) *outWidth = 0u;
    if (outHeight) *outHeight = 0u;
    if (outNonzero) *outNonzero = 0u;
    if (!s || !node || !layout || !outLease || !outWidth || !outHeight || !outNonzero)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    FLOAT scale = (FLOAT)(s->dpi ? s->dpi : 96u) / 96.0f;
    double pixelWidth = ceil(logicalWidth * scale);
    double pixelHeight = ceil(logicalHeight * scale);
    if (!isfinite(pixelWidth) || !isfinite(pixelHeight) || pixelWidth < 1.0 || pixelHeight < 1.0 ||
        pixelWidth > 8192.0 || pixelHeight > 8192.0 || pixelWidth * pixelHeight > 4.0 * 1024.0 * 1024.0)
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    UINT width = (UINT)pixelWidth, height = (UINT)pixelHeight;
    uint64_t pixels = (uint64_t)width * (uint64_t)height;
    if (pixels > UINT64_MAX / 4u) return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    uint64_t textureBytes = pixels * 4u;
    uint64_t rasterStarted = cjgui_internal_renderer_owner_clock_ns();
    if (pixels > UINT64_MAX / 4u || !text_budget_reserve_scratch(s, textureBytes))
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    uint8_t *rgba = (uint8_t *)calloc((size_t)textureBytes, 1u);
    if (!rgba) {
        text_budget_release_scratch(s, textureBytes);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    CjguiWindowsTextRenderer renderer;
    memset(&renderer, 0, sizeof(renderer));
    renderer.lpVtbl = &g_textRendererVtbl; renderer.refs = 1u;
    renderer.pixels = rgba; renderer.width = width; renderer.height = height;
    renderer.session = s; renderer.factory = s->writeFactory;
    renderer.pixelsPerDip = scale; renderer.failure = S_OK;
    renderer.rasterOriginX = (FLOAT)originX;
    renderer.rasterOriginY = (FLOAT)originY;
    renderer.defaultRed = (FLOAT)node->node.textRed;
    renderer.defaultGreen = (FLOAT)node->node.textGreen;
    renderer.defaultBlue = (FLOAT)node->node.textBlue;
    renderer.defaultAlpha = (FLOAT)node->node.textAlpha;
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    DWRITE_TEXT_METRICS diagnosticMetrics; memset(&diagnosticMetrics, 0, sizeof(diagnosticMetrics));
    HRESULT metricsHr = IDWriteTextLayout_GetMetrics(layout, &diagnosticMetrics);
    renderer.diagnostic.layoutMetricsHr = (int32_t)metricsHr;
    renderer.diagnostic.layoutWidthIncludingTrailingWhitespace = diagnosticMetrics.widthIncludingTrailingWhitespace;
    renderer.diagnostic.layoutHeight = diagnosticMetrics.height;
    renderer.diagnostic.layoutLineCount = diagnosticMetrics.lineCount;
#endif
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_OK;
    if (applyRuns)
        status = apply_text_run_backgrounds(s, node, runText, layout, &renderer);
    HRESULT hr = status == CJGUI_INTERNAL_RENDERER_OK
        ? IDWriteTextLayout_Draw(layout, NULL, (IDWriteTextRenderer *)&renderer,
            -(FLOAT)originX, -(FLOAT)originY) : E_FAIL;
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    renderer.diagnostic.drawHr = (int32_t)hr;
    renderer.diagnostic.rendererFailureHr = (int32_t)renderer.failure;
    s->sceneTextDiagnostic = renderer.diagnostic;
#endif
    if (status != CJGUI_INTERNAL_RENDERER_OK || FAILED(hr) || FAILED(renderer.failure)) {
        free(rgba);
        text_budget_release_scratch(s, textureBytes);
        if (renderer.budgetRejected) return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
        s->lastGraphicsFailure = FAILED(renderer.failure) ? renderer.failure : hr;
        if (getenv("PHAROS_WINDOWS_TEST_PROBE_FILE"))
            fprintf(stderr,"CJGUI_WINDOWS_RASTER_FAIL node=%llu draw=%08lx renderer=%08lx runs=%d size=%ux%u\n",
                (unsigned long long)node->node.nodeId,(unsigned long)hr,(unsigned long)renderer.failure,applyRuns,width,height);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t maskNonzero = 0u;
    for (uint64_t i = 0; i < pixels; ++i)
        if (rgba[i * 4u + 3u] != 0u) ++maskNonzero;
    uint64_t rasterFinished = cjgui_internal_renderer_owner_clock_ns();
    ++s->textRasterCount;
    s->textRasterBytes += textureBytes;
    if (rasterStarted && rasterFinished >= rasterStarted)
        s->textRasterMicros += (rasterFinished - rasterStarted) / 1000u;
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    renderer.diagnostic.maskNonzero = maskNonzero;
    s->sceneTextDiagnostic = renderer.diagnostic;
#endif
    D3D11_TEXTURE2D_DESC desc; memset(&desc, 0, sizeof(desc));
    desc.Width = width; desc.Height = height; desc.MipLevels = 1; desc.ArraySize = 1;
    desc.Format = DXGI_FORMAT_R8G8B8A8_UNORM; desc.SampleDesc.Count = 1;
    desc.Usage = D3D11_USAGE_IMMUTABLE; desc.BindFlags = D3D11_BIND_SHADER_RESOURCE;
    D3D11_SUBRESOURCE_DATA initial; memset(&initial, 0, sizeof(initial));
    initial.pSysMem = rgba; initial.SysMemPitch = width * 4u;
    initial.SysMemSlicePitch = (UINT)textureBytes;
    if (!text_budget_reserve_texture(s, textureBytes)) {
        free(rgba);
        text_budget_release_scratch(s, textureBytes);
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    }
    ID3D11Texture2D *texture = NULL;
    ID3D11ShaderResourceView *view = NULL;
    uint64_t uploadStarted = cjgui_internal_renderer_owner_clock_ns();
    hr = ID3D11Device_CreateTexture2D(s->device, &desc, &initial, &texture);
    if (SUCCEEDED(hr)) hr = ID3D11Device_CreateShaderResourceView(s->device,
        (ID3D11Resource *)texture, NULL, &view);
    CjguiWindowsTextTextureLease *lease = SUCCEEDED(hr)
        ? (CjguiWindowsTextTextureLease *)calloc(1u, sizeof(*lease)) : NULL;
    free(rgba);
    text_budget_release_scratch(s, textureBytes);
    if (FAILED(hr) || !texture || !view || !lease) {
        if (lease) free(lease);
        if (view) ID3D11ShaderResourceView_Release(view);
        if (texture) ID3D11Texture2D_Release(texture);
        text_budget_release_texture(s, textureBytes);
        s->lastGraphicsFailure = FAILED(hr) ? hr : E_OUTOFMEMORY;
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t uploadFinished = cjgui_internal_renderer_owner_clock_ns();
    ++s->textUploadCount;
    s->textUploadBytes += textureBytes;
    if (uploadStarted && uploadFinished >= uploadStarted)
        s->textUploadMicros += (uploadFinished - uploadStarted) / 1000u;
    lease->refs = 1u; lease->bytes = textureBytes;
    lease->sessionBytesInUse = &s->textTextureBytesInUse;
    lease->sessionCountInUse = &s->textTextureResourceCount;
    lease->texture = texture; lease->view = view;
    s->textTextureResourceCount += 1u;
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    (void)InterlockedExchangeAdd64(&g_contractLiveTextTextureBytes, (LONG64)textureBytes);
    (void)InterlockedIncrement(&g_contractLiveTextTextureResources);
#endif
    *outLease = lease;
    *outWidth = width; *outHeight = height; *outNonzero = maskNonzero;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static void release_scene_node(CjguiWindowsSceneNode *node) {
    if (!node) return;
    free(node->label); free(node->value); free(node->imageResourcePath); free(node->imageResourceId);
    free(node->semanticId); free(node->bindingKey); free(node->rowKey);
    free(node->parentRowKey); free(node->semanticLabel); free(node->textRuns);
    release_text_texture_lease(&node->imageLease);
    if (node->textLease) release_text_texture_lease(&node->textLease);
    else {
        if (node->textView) ID3D11ShaderResourceView_Release(node->textView);
        if (node->textTexture) ID3D11Texture2D_Release(node->textTexture);
    }
    if (node->labelTextLease) release_text_texture_lease(&node->labelTextLease);
    else {
        if (node->labelTextView) ID3D11ShaderResourceView_Release(node->labelTextView);
        if (node->labelTextTexture) ID3D11Texture2D_Release(node->labelTextTexture);
    }
    if (node->textLayout) IDWriteTextLayout_Release(node->textLayout);
    if (node->labelTextLayout) IDWriteTextLayout_Release(node->labelTextLayout);
    memset(node, 0, sizeof(*node));
}

static void release_scene(CjguiWindowsScene *scene) {
    if (!scene) return;
    for (uint32_t i = 0; i < scene->count; ++i) release_scene_node(&scene->nodes[i]);
    free(scene->nodes);
    memset(scene, 0, sizeof(*scene));
}

static char *copy_valid_utf8(const char *value, uint64_t maxBytes, uint64_t *outBytes,
    CjguiInternalRendererStatus *outStatus) {
    if (outBytes) *outBytes = 0u;
    if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_OK;
    if (!value) value = "";
    size_t length = strnlen(value, (size_t)maxBytes + 1u);
    if (length > maxBytes || length > INT_MAX) {
        if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
        return NULL;
    }
    if (length) {
        int units = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
            value, (int)length, NULL, 0);
        if (units <= 0) {
            if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
            return NULL;
        }
    }
    char *copy = (char *)malloc(length + 1u);
    if (!copy) {
        if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        return NULL;
    }
    memcpy(copy, value, length);
    copy[length] = '\0';
    if (outBytes) *outBytes = (uint64_t)length;
    return copy;
}

static int windows_text_node_kind(uint32_t kind) {
    return kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
}

static CjguiInternalRendererStatus clone_scene_node(CjguiWindowsSceneNode *out,
    const CjguiWindowsSceneNode *source) {
    if (!out || !source || !source->hasNode) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    memset(out, 0, sizeof(*out));
    out->imageResourceVersion = source->imageResourceVersion;
    if (source->imageLease) {
        if (!retain_text_texture_lease(source->imageLease)) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        out->imageLease = source->imageLease;
    }
    out->node = source->node;
    out->geometry = source->geometry;
    out->textTextureWidth = source->textTextureWidth;
    out->textTextureHeight = source->textTextureHeight;
    out->labelTextureWidth = source->labelTextureWidth;
    out->labelTextureHeight = source->labelTextureHeight;
    out->textLogicalOffsetX = source->textLogicalOffsetX;
    out->textLogicalWidth = source->textLogicalWidth;
    out->labelLogicalWidth = source->labelLogicalWidth;
    out->multilineScrollY = source->multilineScrollY;
    out->textRasterRect = source->textRasterRect;
    out->labelRasterRect = source->labelRasterRect;
    out->textDpi = source->textDpi;
    out->layoutLease = source->layoutLease;
    out->textLayoutInputKey = source->textLayoutInputKey;
    out->textMaskNonzeroPixels = source->textMaskNonzeroPixels;
    out->hasNode = source->hasNode;
    out->candidateRetainedBindingValid = source->candidateRetainedBindingValid;
    out->hasGeometry = 0u;
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_OK;
    uint64_t length = 0u;
#define CJGUI_WINDOWS_CLONE_STRING(field) \
    do { \
        out->field = copy_valid_utf8(source->field ? source->field : "", \
            CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY, &length, &status); \
        if (!out->field || status != CJGUI_INTERNAL_RENDERER_OK) goto failed; \
        out->ownedBytes += length; \
    } while (0)
    CJGUI_WINDOWS_CLONE_STRING(label);
    CJGUI_WINDOWS_CLONE_STRING(value);
    CJGUI_WINDOWS_CLONE_STRING(imageResourcePath);
    CJGUI_WINDOWS_CLONE_STRING(imageResourceId);
    CJGUI_WINDOWS_CLONE_STRING(semanticId);
    CJGUI_WINDOWS_CLONE_STRING(bindingKey);
    CJGUI_WINDOWS_CLONE_STRING(rowKey);
    CJGUI_WINDOWS_CLONE_STRING(parentRowKey);
    CJGUI_WINDOWS_CLONE_STRING(semanticLabel);
    CJGUI_WINDOWS_CLONE_STRING(textRuns);
#undef CJGUI_WINDOWS_CLONE_STRING
    out->textLayout = source->textLayout;
    if (out->textLayout) IDWriteTextLayout_AddRef(out->textLayout);
    out->labelTextLayout = source->labelTextLayout;
    if (out->labelTextLayout) IDWriteTextLayout_AddRef(out->labelTextLayout);
    if (source->textLease) {
        if (!retain_text_texture_lease(source->textLease)) goto failed;
        out->textLease = source->textLease;
        out->textTexture = source->textLease->texture;
        out->textView = source->textLease->view;
    } else {
        out->textTexture = source->textTexture;
        if (out->textTexture) ID3D11Texture2D_AddRef(out->textTexture);
        out->textView = source->textView;
        if (out->textView) ID3D11ShaderResourceView_AddRef(out->textView);
    }
    if (source->labelTextLease) {
        if (!retain_text_texture_lease(source->labelTextLease)) goto failed;
        out->labelTextLease = source->labelTextLease;
        out->labelTextTexture = source->labelTextLease->texture;
        out->labelTextView = source->labelTextLease->view;
    } else {
        out->labelTextTexture = source->labelTextTexture;
        if (out->labelTextTexture) ID3D11Texture2D_AddRef(out->labelTextTexture);
        out->labelTextView = source->labelTextView;
        if (out->labelTextView) ID3D11ShaderResourceView_AddRef(out->labelTextView);
    }
    return CJGUI_INTERNAL_RENDERER_OK;
failed:
    release_scene_node(out);
    return status;
}

static CjguiInternalRendererStatus copy_node_strings(CjguiWindowsSceneNode *out,
    const CjguiInternalRendererComposableNode *node, const char *label, const char *value,
    const char *imagePath, const char *imageId, const char *runs) {
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_OK;
    uint64_t length = 0u;
#define CJGUI_WINDOWS_COPY_STRING(field, input) \
    do { \
        out->field = copy_valid_utf8((input), CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY, \
            &length, &status); \
        if (!out->field || status != CJGUI_INTERNAL_RENDERER_OK) return status; \
        if (length > CJGUI_WINDOWS_TEXT_BYTE_CAPACITY - out->ownedBytes) \
            return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED; \
        out->ownedBytes += length; \
    } while (0)
    CJGUI_WINDOWS_COPY_STRING(label, label);
    CJGUI_WINDOWS_COPY_STRING(value, value);
    CJGUI_WINDOWS_COPY_STRING(imageResourcePath, imagePath);
    CJGUI_WINDOWS_COPY_STRING(imageResourceId, imageId);
    CJGUI_WINDOWS_COPY_STRING(semanticId, "");
    CJGUI_WINDOWS_COPY_STRING(bindingKey, "");
    CJGUI_WINDOWS_COPY_STRING(rowKey, "");
    CJGUI_WINDOWS_COPY_STRING(parentRowKey, "");
    CJGUI_WINDOWS_COPY_STRING(semanticLabel, "");
    CJGUI_WINDOWS_COPY_STRING(textRuns, runs);
#undef CJGUI_WINDOWS_COPY_STRING
    out->node = *node;
    out->geometry.nodeId = node->nodeId;
    out->geometry.clipCount = node->clipConstraintCount;
    out->hasNode = 1u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static int text_texture_bytes_for_box(CjguiWindowsRendererSession *s, double width,
    double height, uint64_t *outBytes) {
    if (!s || !outBytes || !isfinite(width) || !isfinite(height) || width <= 0.0 || height <= 0.0)
        return 0;
    double scale = (double)(s->dpi ? s->dpi : 96u) / 96.0;
    double pixelWidth = ceil(width * scale), pixelHeight = ceil(height * scale);
    if (!isfinite(pixelWidth) || !isfinite(pixelHeight) || pixelWidth < 1.0 || pixelHeight < 1.0 ||
        pixelWidth > 8192.0 || pixelHeight > 8192.0 || pixelWidth * pixelHeight > 4.0 * 1024.0 * 1024.0)
        return 0;
    uint64_t pixels = (uint64_t)pixelWidth * (uint64_t)pixelHeight;
    if (pixels > UINT64_MAX / 4u) return 0;
    *outBytes = pixels * 4u;
    return 1;
}

static uint64_t next_text_layout_lease(CjguiWindowsRendererSession *s) {
    if (!s) return 0u;
    ++s->nextTextLayoutLease;
    if (!s->nextTextLayoutLease) ++s->nextTextLayoutLease;
    return s->nextTextLayoutLease;
}

static uint64_t windows_fnv1a64(uint64_t seed, const void *data, size_t length) {
    const unsigned char *bytes = (const unsigned char *)data;
    uint64_t hash = seed ? seed : 1469598103934665603ull;
    for (size_t i = 0u; i < length; ++i) {
        hash ^= (uint64_t)bytes[i];
        hash *= 1099511628211ull;
    }
    return hash;
}

static uint64_t windows_text_layout_input_key(CjguiWindowsRendererSession *s,
    const CjguiWindowsSceneNode *node, const char *bodyText) {
    uint64_t key = 1469598103934665603ull;
    const CjguiInternalRendererComposableNode *n = node ? &node->node : NULL;
    uint32_t kind = n ? n->nodeKind : 0u;
    key = windows_fnv1a64(key, &kind, sizeof(kind));
    double fontSize = (n && n->fontSize > 0.0) ? n->fontSize : 14.0;
    key = windows_fnv1a64(key, &fontSize, sizeof(fontSize));
    uint32_t weight = n ? n->fontWeight : 0u;
    uint32_t family = n ? n->fontFamily : 0u;
    key = windows_fnv1a64(key, &weight, sizeof(weight));
    key = windows_fnv1a64(key, &family, sizeof(family));
    double width = n ? (double)n->width : 0.0;
    double height = n ? (double)n->height : 0.0;
    key = windows_fnv1a64(key, &width, sizeof(width));
    key = windows_fnv1a64(key, &height, sizeof(height));
    uint64_t dpi = s ? (uint64_t)s->dpi : 0u;
    key = windows_fnv1a64(key, &dpi, sizeof(dpi));
    uint32_t editable = (kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) ? 1u : 0u;
    key = windows_fnv1a64(key, &editable, sizeof(editable));
    const char *body = bodyText ? bodyText : "";
    key = windows_fnv1a64(key, body, strlen(body) + 1u);
    const char *label = (node && node->label) ? node->label : "";
    key = windows_fnv1a64(key, label, strlen(label) + 1u);
    const char *runs = (node && node->textRuns) ? node->textRuns : "";
    key = windows_fnv1a64(key, runs, strlen(runs) + 1u);
    if (!key) key = 1u;
    return key;
}

/* 光栅输入 = 排版输入＋节点级文字颜色（烘焙进纹理）。排版相同仅颜色变化
   时复用排版与租约、只重画纹理：命中/caret 连续性不受影响，pressed/focus
   变色仍能显示。 */
static uint64_t windows_text_raster_input_key(uint64_t layoutKey,
    double textRed, double textGreen, double textBlue, double textAlpha) {
    uint64_t key = windows_fnv1a64(layoutKey, &textRed, sizeof(textRed));
    key = windows_fnv1a64(key, &textGreen, sizeof(textGreen));
    key = windows_fnv1a64(key, &textBlue, sizeof(textBlue));
    key = windows_fnv1a64(key, &textAlpha, sizeof(textAlpha));
    if (!key) key = 1u;
    return key;
}

static void release_node_textures_only(CjguiWindowsSceneNode *node) {
    if (!node) return;
    if (node->textLease) release_text_texture_lease(&node->textLease);
    else {
        if (node->textView) ID3D11ShaderResourceView_Release(node->textView);
        if (node->textTexture) ID3D11Texture2D_Release(node->textTexture);
    }
    if (node->labelTextLease) release_text_texture_lease(&node->labelTextLease);
    else {
        if (node->labelTextView) ID3D11ShaderResourceView_Release(node->labelTextView);
        if (node->labelTextTexture) ID3D11Texture2D_Release(node->labelTextTexture);
    }
    node->textLease = NULL;
    node->labelTextLease = NULL;
    node->textTexture = NULL;
    node->textView = NULL;
    node->labelTextTexture = NULL;
    node->labelTextView = NULL;
    node->textTextureWidth = 0u;
    node->textTextureHeight = 0u;
    node->labelTextureWidth = 0u;
    node->labelTextureHeight = 0u;
    node->textMaskNonzeroPixels = 0u;
}

static int adopt_old_text_layout(CjguiWindowsSceneNode *next,
    CjguiWindowsSceneNode *old) {
    if (!next || !old || !old->textLayout) return 0;
    if (next->textLayout != old->textLayout) {
        next->textLayout = old->textLayout;
        IDWriteTextLayout_AddRef(next->textLayout);
    }
    if (next->labelTextLayout != old->labelTextLayout) {
        next->labelTextLayout = old->labelTextLayout;
        if (next->labelTextLayout) IDWriteTextLayout_AddRef(next->labelTextLayout);
    }
    if (next->textLease != old->textLease) {
        if (old->textLease && !retain_text_texture_lease(old->textLease)) return 0;
        next->textLease = old->textLease;
        if (next->textLease) {
            next->textTexture = next->textLease->texture;
            next->textView = next->textLease->view;
        } else {
            next->textTexture = old->textTexture;
            if (next->textTexture) ID3D11Texture2D_AddRef(next->textTexture);
            next->textView = old->textView;
            if (next->textView) ID3D11ShaderResourceView_AddRef(next->textView);
        }
    }
    if (next->labelTextLease != old->labelTextLease) {
        if (old->labelTextLease && !retain_text_texture_lease(old->labelTextLease)) return 0;
        next->labelTextLease = old->labelTextLease;
        if (next->labelTextLease) {
            next->labelTextTexture = next->labelTextLease->texture;
            next->labelTextView = next->labelTextLease->view;
        } else {
            next->labelTextTexture = old->labelTextTexture;
            if (next->labelTextTexture) ID3D11Texture2D_AddRef(next->labelTextTexture);
            next->labelTextView = old->labelTextView;
            if (next->labelTextView) ID3D11ShaderResourceView_AddRef(next->labelTextView);
        }
    }
    next->textTextureWidth = old->textTextureWidth;
    next->textTextureHeight = old->textTextureHeight;
    next->labelTextureWidth = old->labelTextureWidth;
    next->labelTextureHeight = old->labelTextureHeight;
    next->textLogicalOffsetX = old->textLogicalOffsetX;
    next->textLogicalWidth = old->textLogicalWidth;
    next->labelLogicalWidth = old->labelLogicalWidth;
    next->textRasterRect = old->textRasterRect;
    next->labelRasterRect = old->labelRasterRect;
    next->textDpi = old->textDpi;
    next->layoutLease = old->layoutLease;
    next->textLayoutInputKey = old->textLayoutInputKey;
    next->textMaskNonzeroPixels = old->textMaskNonzeroPixels;
    return 1;
}


/* DWrite layout remains in the original node-local box. Only its visible
   raster coverage changes; scrolling never grants input authority or changes
   a layout lease. Geometry must be supplied by this same candidate first. */
static CjguiWindowsTextRasterRect windows_text_raster_rect(
    CjguiWindowsRendererSession *s, const CjguiWindowsSceneNode *node,
    double bodyOffset, double boxWidth) {
    CjguiWindowsTextRasterRect result = {0};
    if (!s || !node->hasGeometry || !(boxWidth > 0.0) || node->node.height <= 0) return result;
    double scale = (double)(s->dpi ? s->dpi : 96u) / 96.0;
    double left = 0.0, top = 0.0, right = (double)s->width / scale, bottom = (double)s->height / scale;
    uint32_t count = node->node.clipConstraintCount ? node->node.clipConstraintCount : 1u;
    for (uint32_t i = 0; i < count; ++i) {
        double x, y, width, height, radius;
        windows_clip_constraint(node, i, &x, &y, &width, &height, &radius);
        if (width > 0.0 && height > 0.0) {
            left = fmax(left, x); top = fmax(top, y);
            right = fmin(right, x + width); bottom = fmin(bottom, y + height);
        }
    }
    double originX = node->node.x + node->geometry.translateX + bodyOffset;
    double contentHeight = (double)node->node.height;
    double originY = node->node.y + node->geometry.translateY;
    if (node->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) {
        DWRITE_TEXT_METRICS metrics = {0};
        if (!node->textLayout || FAILED(IDWriteTextLayout_GetMetrics(node->textLayout, &metrics))) return result;
        contentHeight = fmax(contentHeight, (double)metrics.height);
        left = fmax(left, node->node.x + node->geometry.translateX);
        right = fmin(right, node->node.x + node->geometry.translateX + node->node.width);
        top = fmax(top, originY);
        bottom = fmin(bottom, originY + node->node.height);
        originY -= node->multilineScrollY;
    }
    left = fmax(0.0, left - originX); top = fmax(0.0, top - originY);
    right = fmin(boxWidth, right - originX);
    bottom = fmin(contentHeight, bottom - originY);
    if (!(right > left && bottom > top)) return result;
    /* A finite AA guard snapped to the unchanged layout's pixel grid. Exact
       visual clipping still happens at draw; no viewport constraint reflows text. */
    result.x = fmax(0.0, floor((left - 2.0) * scale) / scale);
    result.y = fmax(0.0, floor((top - 2.0) * scale) / scale);
    result.width = fmin(boxWidth, ceil((right + 2.0) * scale) / scale) - result.x;
    result.height = fmin(contentHeight, ceil((bottom + 2.0) * scale) / scale) - result.y;
    return result;
}

static int text_raster_contains(CjguiWindowsTextRasterRect old,
    CjguiWindowsTextRasterRect wanted) {
    return old.width > 0.0 && old.height > 0.0 &&
        old.x <= wanted.x && old.y <= wanted.y &&
        old.x + old.width >= wanted.x + wanted.width &&
        old.y + old.height >= wanted.y + wanted.height;
}

static CjguiInternalRendererStatus prepare_scene_node_raster(CjguiWindowsRendererSession *s,
    CjguiWindowsScene *scene, uint32_t index, CjguiWindowsSceneNode *node) {
    if (!windows_text_node_kind(node->node.nodeKind) || !node->hasGeometry)
        return CJGUI_INTERNAL_RENDERER_OK;
    if (!node->textLayout || node->textDpi != s->dpi) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    if (node->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) {
        DWRITE_TEXT_METRICS metrics = {0};
        HRESULT hr = IDWriteTextLayout_GetMetrics(node->textLayout, &metrics);
        if (FAILED(hr)) { s->lastGraphicsFailure = hr; return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR; }
        node->multilineScrollY = fmin(fmax(0.0, node->multilineScrollY),
            fmax(0.0, (double)metrics.height - node->node.height));
    }
    const char *body = node->value ? node->value : "";
    if (node->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON && node->label && node->label[0])
        body = node->label;
    CjguiWindowsTextRasterRect bodyRect = {0}, labelRect = {0};
    if (body[0]) bodyRect = windows_text_raster_rect(s, node, node->textLogicalOffsetX, node->textLogicalWidth);
    if (node->labelTextLayout && node->label && node->label[0])
        labelRect = windows_text_raster_rect(s, node, 0.0, node->labelLogicalWidth);
    int bodyVisible = bodyRect.width > 0.0 && bodyRect.height > 0.0;
    int labelVisible = labelRect.width > 0.0 && labelRect.height > 0.0;
    if (!bodyVisible && !labelVisible) {
        release_node_textures_only(node);
        node->textRasterRect = bodyRect; node->labelRasterRect = labelRect;
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    if ((!bodyVisible || (node->textView && text_raster_contains(node->textRasterRect, bodyRect))) &&
        (!labelVisible || (node->labelTextView && text_raster_contains(node->labelRasterRect, labelRect))))
        return CJGUI_INTERNAL_RENDERER_OK;
    uint64_t bodyBytes = 0u, labelBytes = 0u;
    if ((bodyVisible && !text_texture_bytes_for_box(s, bodyRect.width, bodyRect.height, &bodyBytes)) ||
        (labelVisible && !text_texture_bytes_for_box(s, labelRect.width, labelRect.height, &labelBytes)))
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    uint64_t other = scene_unique_text_texture_bytes(scene, index);
    if (other > CJGUI_WINDOWS_TEXT_SCENE_TEXTURE_CAPACITY ||
        labelBytes > CJGUI_WINDOWS_TEXT_SCENE_TEXTURE_CAPACITY - other ||
        bodyBytes > CJGUI_WINDOWS_TEXT_SCENE_TEXTURE_CAPACITY - other - labelBytes)
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    CjguiWindowsTextTextureLease *bodyLease = NULL, *labelLease = NULL;
    uint32_t bw = 0, bh = 0, lw = 0, lh = 0; uint64_t bi = 0, li = 0;
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_OK;
    if (labelVisible)
        status = rasterize_text_layout(s, node, node->label, node->labelTextLayout,
            labelRect.width, labelRect.height, labelRect.x, labelRect.y, 0, &labelLease, &lw, &lh, &li);
    if (status == CJGUI_INTERNAL_RENDERER_OK && bodyVisible)
        status = rasterize_text_layout(s, node, body, node->textLayout,
            bodyRect.width, bodyRect.height, bodyRect.x, bodyRect.y, 1, &bodyLease, &bw, &bh, &bi);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        if (labelLease) release_text_texture_lease(&labelLease);
        if (bodyLease) release_text_texture_lease(&bodyLease);
        return status;
    }
    /* Allocate both replacements before dropping this candidate's old refs.
       Accepted and in-flight scenes keep their own immutable leases on failure. */
    release_node_textures_only(node);
    node->textLease = bodyLease; node->labelTextLease = labelLease;
    node->textTexture = bodyLease ? bodyLease->texture : NULL;
    node->textView = bodyLease ? bodyLease->view : NULL;
    node->labelTextTexture = labelLease ? labelLease->texture : NULL;
    node->labelTextView = labelLease ? labelLease->view : NULL;
    node->textTextureWidth = bw; node->textTextureHeight = bh;
    node->labelTextureWidth = lw; node->labelTextureHeight = lh;
    node->textRasterRect = bodyRect; node->labelRasterRect = labelRect;
    node->textMaskNonzeroPixels = bi + li;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus prepare_scene_node_text(CjguiWindowsRendererSession *s,
    CjguiWindowsScene *scene, uint32_t nodeIndex, CjguiWindowsSceneNode *node) {
    if (!windows_text_node_kind(node->node.nodeKind)) return CJGUI_INTERNAL_RENDERER_OK;
    if (s->graphicsRecoveryPending || !s->device || !s->context) return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
    CjguiInternalRendererStatus status = reap_text_flights(s);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    double nodeWidth = node->node.width, nodeHeight = node->node.height;
    double fontSize = node->node.fontSize > 0.0 ? node->node.fontSize : 14.0;
    const int editable = node->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT ||
        node->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT ||
        node->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT ||
        node->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    const char *body = node->value ? node->value : "";
    if (node->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON && node->label && node->label[0]) body = node->label;
    uint64_t prepareAt=s->traceEnabled?cjgui_internal_renderer_owner_clock_ns():0;
    uint64_t layoutKey = windows_text_layout_input_key(s, node, body);
    if (nodeIndex < scene->count) {
        CjguiWindowsSceneNode *old = &scene->nodes[nodeIndex];
        if (old->hasNode && old->node.nodeId == node->node.nodeId &&
            old->textLayoutInputKey == layoutKey && old->textLayout && adopt_old_text_layout(node, old)) {
            uint64_t rasterKey = windows_text_raster_input_key(layoutKey,
                node->node.textRed, node->node.textGreen, node->node.textBlue, node->node.textAlpha);
            uint64_t oldRasterKey = windows_text_raster_input_key(old->textLayoutInputKey,
                old->node.textRed, old->node.textGreen, old->node.textBlue, old->node.textAlpha);
            if (rasterKey != oldRasterKey) release_node_textures_only(node);
            CjguiInternalRendererStatus reused=prepare_scene_node_raster(s, scene, nodeIndex, node);
            if (s->traceEnabled && strlen(body)>8192u)
                windows_trace(s,"layout_reuse",node->node.nodeId,strlen(body),
                    cjgui_internal_renderer_owner_clock_ns()-prepareAt,0,0,reused);
            return reused;
        }
    }
    IDWriteTextLayout *labelLayout = NULL, *bodyLayout = NULL;
    DWRITE_TEXT_METRICS labelMetrics = {0}, bodyMetrics = {0};
    double labelWidth = 0.0, bodyOffset = 0.0, bodyWidth = nodeWidth;
    /* Multiline body is value-only, as on the common macOS path. Its
       semantic fallback label remains identity metadata, not inline content. */
    if (editable && node->node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT &&
        node->label && node->label[0]) {
        float constraint = (FLOAT)fmax(1.0, fmin(nodeWidth * 0.5, nodeWidth - 1.0));
        status = create_measured_text_layout(s, node->label, fontSize, node->node.fontWeight,
            node->node.fontFamily, constraint, (FLOAT)nodeHeight, &labelLayout, &labelMetrics);
        if (status != CJGUI_INTERNAL_RENDERER_OK) goto failed;
        labelWidth = fmin(constraint, fmax(0.0, labelMetrics.widthIncludingTrailingWhitespace));
        if (labelWidth <= 0.0) labelWidth = fmin(constraint, fontSize * 0.5);
        bodyOffset = fmin(nodeWidth, labelWidth + 8.0);
        bodyWidth = fmax(1.0, nodeWidth - bodyOffset);
    }
    uint64_t layoutAt=s->traceEnabled?cjgui_internal_renderer_owner_clock_ns():0;
    status = create_styled_text_layout(s, node, body, (FLOAT)bodyWidth, (FLOAT)nodeHeight,
        &bodyLayout, &bodyMetrics);
    uint64_t layoutNs=s->traceEnabled?cjgui_internal_renderer_owner_clock_ns()-layoutAt:0;
    if (status != CJGUI_INTERNAL_RENDERER_OK) goto failed;
    release_node_textures_only(node);
    if (node->textLayout) IDWriteTextLayout_Release(node->textLayout);
    if (node->labelTextLayout) IDWriteTextLayout_Release(node->labelTextLayout);
    node->textLayout = bodyLayout; node->labelTextLayout = labelLayout;
    node->textLogicalOffsetX = bodyOffset; node->textLogicalWidth = bodyWidth;
    node->labelLogicalWidth = labelWidth; node->textDpi = s->dpi;
    node->layoutLease = next_text_layout_lease(s); node->textLayoutInputKey = layoutKey;
    uint64_t rasterAt=s->traceEnabled?cjgui_internal_renderer_owner_clock_ns():0;
    status=prepare_scene_node_raster(s, scene, nodeIndex, node);
    if (s->traceEnabled && strlen(body)>8192u)
        windows_trace(s,"layout_new",node->node.nodeId,strlen(body),layoutNs,
            cjgui_internal_renderer_owner_clock_ns()-rasterAt,
            cjgui_internal_renderer_owner_clock_ns()-prepareAt,status);
    return status;
failed:
    if (labelLayout) IDWriteTextLayout_Release(labelLayout);
    if (bodyLayout) IDWriteTextLayout_Release(bodyLayout);
    return status;
}

/* Build replacement raster coverage before changing the accepted viewport.
   Allocation/GPU refusal preserves the entire raw wheel and old pixels. */
static int scroll_windows_multiline_viewport(CjguiWindowsRendererSession *s,
    uint32_t index, int delta, UINT wheelLines) {
    CjguiWindowsSceneNode *node = &s->acceptedScene.nodes[index];
    if (!node->textLayout || !node->layoutLease || node->textDpi != s->dpi ||
        node->node.height <= 0 || s->graphicsRecoveryPending) return 0;
    DWRITE_TEXT_METRICS metrics = {0};
    HRESULT hr = IDWriteTextLayout_GetMetrics(node->textLayout, &metrics);
    if (FAILED(hr) || !isfinite(metrics.height)) { s->lastGraphicsFailure = hr; return 0; }
    double lineHeight = metrics.lineCount ? (double)metrics.height / metrics.lineCount : node->node.fontSize * 1.25;
    double step = wheelLines == WHEEL_PAGESCROLL ? node->node.height : wheelLines * lineHeight;
    double offset = fmin(fmax(0.0, node->multilineScrollY - (double)delta / WHEEL_DELTA * step),
        fmax(0.0, (double)metrics.height - node->node.height));
    if (offset == node->multilineScrollY) return 1;
    CjguiWindowsSceneNode next;
    CjguiInternalRendererStatus st = clone_scene_node(&next, node);
    if (st != CJGUI_INTERNAL_RENDERER_OK) return 0;
    next.hasGeometry = node->hasGeometry;
    next.multilineScrollY = offset;
    st = prepare_scene_node_raster(s, &s->acceptedScene, index, &next);
    if (st != CJGUI_INTERNAL_RENDERER_OK) { release_scene_node(&next); return 0; }
    release_scene_node(node);
    *node = next;
    s->multilineViewportEpochPending = 1u;
    s->multilineViewportPaintPending = 1u;
    return 1;
}

static CjguiInternalRendererStatus validate_composable_node(
    const CjguiInternalRendererComposableNode *node, uint64_t version) {
    if (!node || !node->nodeId || node->projectionVersion != version ||
        node->nodeKind < CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL ||
        node->nodeKind > CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE ||
        node->width < 0 || node->height < 0 || node->width > 1000000 || node->height > 1000000 ||
        node->x < -1000000 || node->x > 1000000 || node->y < -1000000 || node->y > 1000000 ||
        node->clipWidth < 0 || node->clipHeight < 0 || node->clipConstraintCount > 4u)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    const double scalars[] = {node->cornerRadius, node->clipCornerRadius, node->fontSize,
        node->fillRed, node->fillGreen, node->fillBlue, node->fillAlpha,
        node->borderRed, node->borderGreen, node->borderBlue, node->borderAlpha,
        node->textRed, node->textGreen, node->textBlue, node->textAlpha,
        node->shadowOffsetX, node->shadowOffsetY, node->shadowBlurRadius, node->shadowSpread,
        node->shadowRed, node->shadowGreen, node->shadowBlue, node->shadowAlpha,
        node->gradientStartX, node->gradientStartY, node->gradientEndX, node->gradientEndY,
        node->gradientStop0Position, node->gradientStop0Red, node->gradientStop0Green,
        node->gradientStop0Blue, node->gradientStop0Alpha, node->gradientStop1Position,
        node->gradientStop1Red, node->gradientStop1Green, node->gradientStop1Blue,
        node->gradientStop1Alpha, node->gradientStop2Position, node->gradientStop2Red,
        node->gradientStop2Green, node->gradientStop2Blue, node->gradientStop2Alpha,
        node->gradientStop3Position, node->gradientStop3Red, node->gradientStop3Green,
        node->gradientStop3Blue, node->gradientStop3Alpha, node->effectGroupOpacity};
    for (size_t i = 0; i < sizeof(scalars) / sizeof(scalars[0]); ++i)
        if (!isfinite(scalars[i])) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    const double colors[] = {node->fillRed, node->fillGreen, node->fillBlue, node->fillAlpha,
        node->borderRed, node->borderGreen, node->borderBlue, node->borderAlpha,
        node->textRed, node->textGreen, node->textBlue, node->textAlpha};
    for (size_t i = 0; i < sizeof(colors) / sizeof(colors[0]); ++i)
        if (colors[i] < 0.0 || colors[i] > 1.0) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiWindowsSceneNode *scene_node_by_id(CjguiWindowsScene *scene, uint64_t nodeId) {
    if (!scene || !scene->nodes || nodeId == 0u) return NULL;
    for (uint32_t i = 0; i < scene->count; ++i)
        if (scene->nodes[i].hasNode && scene->nodes[i].node.nodeId == nodeId) return &scene->nodes[i];
    return NULL;
}

static CjguiWindowsTextRunDeclaration *text_runs_by_id(CjguiWindowsRendererSession *s,
    uint64_t nodeId) {
    for (uint32_t i = 0; s && i < s->textRunDeclarationCount; ++i)
        if (s->textRunDeclarations[i].nodeId == nodeId) return &s->textRunDeclarations[i];
    return NULL;
}

static CjguiInternalRendererStatus scene_configure(CjguiWindowsRendererSession *s,
    uint64_t projectionVersion, uint32_t nodeCount) {
    if (!s || !projectionVersion || !nodeCount || nodeCount > CJGUI_WINDOWS_SCENE_NODE_CAPACITY)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsScene next;
    memset(&next, 0, sizeof(next));
    next.nodes = (CjguiWindowsSceneNode *)calloc(nodeCount, sizeof(CjguiWindowsSceneNode));
    if (!next.nodes) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    next.version = projectionVersion;
    next.count = nodeCount;
    next.configured = 1u;
    uint32_t copied = s->acceptedScene.count < nodeCount ? s->acceptedScene.count : nodeCount;
    for (uint32_t i = 0; i < copied; ++i) {
        CjguiInternalRendererStatus status = clone_scene_node(&next.nodes[i], &s->acceptedScene.nodes[i]);
        if (status != CJGUI_INTERNAL_RENDERER_OK) {
            release_scene(&next);
            return status;
        }
        next.nodes[i].node.projectionVersion = projectionVersion;
        next.nodes[i].candidateValueStaged = 0u;
        next.nodes[i].candidateRunsPending = 0u;
        next.nodes[i].candidateRetainedBindingValid = 1u;
        next.ownedBytes += next.nodes[i].ownedBytes;
    }
    release_scene(&s->candidateScene);
    for (uint32_t i = 0u; i < s->textRunDeclarationCount; ++i)
        free(s->textRunDeclarations[i].encoded);
    s->textRunDeclarationCount = 0u;
    s->candidateScene = next;
    return CJGUI_INTERNAL_RENDERER_OK;
}

/* ---- 通用有界场景准备（R7）----
   begin 冻结本票身份并从 accepted 克隆一份私有图；prepare 只复制声明、几何与
   八个字符串（独立字节额度、同票不重复、越界即具名拒绝）；advance 在同一个
   绝对 deadline 内推进不可抢占的排版/光栅单元，未完成即让出；promote 先重核
   来源，再把同一份已准备资源交给 configure 建立的候选，由既有 Present 发布
   accepted；cancel 把私有图转入有界退休队列并按单元真实回收。ready 不是画面
   提交，也不是输入授权。私有图及其字段全部只由 UI（泵）线程的命令体访问。 */

static uint64_t windows_prep_clock_ns(void) {
    return cjgui_internal_renderer_owner_clock_ns();
}

static void windows_prep_log_ticket(const char *event, CjguiWindowsRendererSession *s,
    uint64_t a, uint64_t b, uint64_t ticket, uint64_t cancelNs, uint64_t retiredNs,
    uint64_t releasedNodes, uint64_t releasedBytes, uint64_t graphNodes, uint64_t graphBytes) {
    if (!getenv("PHAROS_WINDOWS_TEST_PROBE_FILE") || !s) return;
    fprintf(stderr,
        "CJGUI_WINDOWS_PREP event=%s clock_ns=%llu session=%llu prep=%llu a=%llu b=%llu "
        "active=%u ready=%u nodes=%u staged=%u prepared=%u cursors=%u units=%llu "
        "live=%llu retiring=%u retired_nodes=%llu retired_bytes=%llu "
        "deadline_hits=%llu stale=%llu budget_refusals=%llu cancels=%llu "
        "ticket=%llu cancel_ns=%llu retired_ns=%llu released_nodes=%llu released_bytes=%llu "
        "graph_nodes=%llu graph_bytes=%llu accounting_errors=%llu\n",
        event ? event : "?", (unsigned long long)cjgui_internal_renderer_owner_clock_ns(),
        (unsigned long long)s->token,
        (unsigned long long)s->preparationId, (unsigned long long)a, (unsigned long long)b,
        (unsigned)s->preparationActive, (unsigned)s->preparationReady,
        (unsigned)s->preparationNodeCount, (unsigned)s->preparationStagedCount,
        (unsigned)s->preparationPreparedCount, (unsigned)s->preparationCursor,
        (unsigned long long)s->preparationUnitCount,
        (unsigned long long)s->preparationLiveBytes, (unsigned)s->preparationRetiringCount,
        (unsigned long long)s->preparationRetiredNodeCount,
        (unsigned long long)s->preparationRetiredBytes,
        (unsigned long long)s->preparationDeadlineHits,
        (unsigned long long)s->preparationStaleCount,
        (unsigned long long)s->preparationBudgetRefusals,
        (unsigned long long)s->preparationCancelCount,
        (unsigned long long)ticket, (unsigned long long)cancelNs,
        (unsigned long long)retiredNs, (unsigned long long)releasedNodes,
        (unsigned long long)releasedBytes, (unsigned long long)graphNodes,
        (unsigned long long)graphBytes,
        (unsigned long long)s->preparationRetireAccountingErrors);
    fflush(stderr);
}

/* 具名证据行：只在探针环境变量存在时输出。反例按这些行判定“冻结副本、
   未 ready 拒提升、过期票、取消晚到、容量、batch deadline、退休责任”，
   不复制影子状态机。票身份取队首退休图；队列空时取最近一次退休/回收的票，
   因此取消之后仍然能回答“这张票回收完了没有”，而不是归零后的 active 票号。 */
static void windows_prep_log(const char *event, CjguiWindowsRendererSession *s,
    uint64_t a, uint64_t b) {
    if (!s) return;
    if (s->preparationRetiringCount > 0u) {
        windows_prep_log_ticket(event, s, a, b,
            s->preparationRetiring[0].preparationId,
            s->preparationRetiring[0].cancelNs,
            s->preparationRetiring[0].retiredNs,
            s->preparationRetiring[0].releasedNodes,
            s->preparationRetiring[0].releasedBytes,
            s->preparationRetiring[0].nodeCount,
            s->preparationRetiring[0].ownedBytes);
        return;
    }
    windows_prep_log_ticket(event, s, a, b, s->preparationLastTicket,
        s->preparationLastCancelNs, s->preparationLastRetiredNs,
        s->preparationLastReleasedNodes, s->preparationLastReleasedBytes,
        s->preparationLastGraphNodes, s->preparationLastGraphBytes);
}

static void windows_prep_release_scene_nodes(CjguiWindowsSceneNode *nodes, uint32_t count) {
    if (!nodes) return;
    for (uint32_t i = 0u; i < count; ++i) release_scene_node(&nodes[i]);
    free(nodes);
}

static void windows_prep_clear_active_fields(CjguiWindowsRendererSession *s) {
    s->preparationActive = 0u;
    s->preparationReady = 0u;
    s->preparationNodeCount = 0u;
    s->preparationStagedCount = 0u;
    s->preparationPreparedCount = 0u;
    s->preparationCursor = 0u;
    s->preparationOwnedBytes = 0u;
    s->preparationId = 0u;
    s->preparationProjectionVersion = 0u;
}

/* 一个声明单元的全部字符串；与 Mac 同口径，语义/绑定/行键也属于私有图。 */
static CjguiInternalRendererStatus windows_prep_copy_strings(CjguiWindowsSceneNode *out,
    const CjguiInternalRendererComposableNode *node, const char *label, const char *value,
    const char *semanticId, const char *bindingKey, const char *rowKey, const char *parentRowKey,
    const char *semanticLabel, const char *encodedRuns) {
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_OK;
    uint64_t length = 0u;
#define CJGUI_WIN_PREP_COPY(field, input) \
    do { \
        out->field = copy_valid_utf8((input), CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY, \
            &length, &status); \
        if (!out->field || status != CJGUI_INTERNAL_RENDERER_OK) return status; \
        out->ownedBytes += length; \
    } while (0)
    CJGUI_WIN_PREP_COPY(label, label);
    CJGUI_WIN_PREP_COPY(value, value);
    CJGUI_WIN_PREP_COPY(semanticId, semanticId);
    CJGUI_WIN_PREP_COPY(bindingKey, bindingKey);
    CJGUI_WIN_PREP_COPY(rowKey, rowKey);
    CJGUI_WIN_PREP_COPY(parentRowKey, parentRowKey);
    CJGUI_WIN_PREP_COPY(semanticLabel, semanticLabel);
    CJGUI_WIN_PREP_COPY(textRuns, encodedRuns);
#undef CJGUI_WIN_PREP_COPY
    out->node = *node;
    out->geometry.nodeId = node->nodeId;
    out->geometry.clipCount = node->clipConstraintCount;
    out->hasNode = 1u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

/* 回收一个有界单元：从队首尾部释放同一下标的已准备节点与在途声明。
   返回 1 表示本单元确实回收了资源；队列为空返回 0。 */
static int windows_prep_retire_unit(CjguiWindowsRendererSession *s) {
    if (!s || s->preparationRetiringCount == 0u) return 0;
    if (s->preparationRetiring[0].releaseCursor > 0u) {
        uint32_t cursor = s->preparationRetiring[0].releaseCursor - 1u;
        CjguiWindowsSceneNode *sceneNode = &s->preparationRetiring[0].scene.nodes[cursor];
        CjguiWindowsSceneNode *incoming = s->preparationRetiring[0].incoming
            ? &s->preparationRetiring[0].incoming[cursor] : NULL;
        uint64_t bytes = sceneNode->ownedBytes + (incoming ? incoming->ownedBytes : 0u);
        release_scene_node(sceneNode);
        if (incoming) release_scene_node(incoming);
        s->preparationRetiring[0].releaseCursor = cursor;
        s->preparationRetiring[0].releasedNodes += 1u;
        s->preparationRetiring[0].releasedBytes += bytes;
        if (bytes > s->preparationLiveBytes) {
            /* 记账本身就错了：不能靠夹到 0 掩盖，必须留下可数的误差。 */
            s->preparationLiveBytes = 0u;
            s->preparationRetireAccountingErrors += 1u;
        } else {
            s->preparationLiveBytes -= bytes;
        }
        s->preparationRetiredNodeCount += 1u;
        s->preparationRetiredBytes += bytes;
        return 1;
    }
    /* 节点已全部释放：此时才交还数组与槽位——这才是这张票真实回收完成的时刻。
       部分 drain 不能冒充完成，所以 reclaim_complete 只在槽位归还时发一次。 */
    uint64_t ticket = s->preparationRetiring[0].preparationId;
    uint64_t cancelNs = s->preparationRetiring[0].cancelNs;
    uint64_t retiredNs = s->preparationRetiring[0].retiredNs;
    uint64_t graphNodes = s->preparationRetiring[0].nodeCount;
    uint64_t graphBytes = s->preparationRetiring[0].ownedBytes;
    uint64_t releasedNodes = s->preparationRetiring[0].releasedNodes;
    uint64_t releasedBytes = s->preparationRetiring[0].releasedBytes;
    free(s->preparationRetiring[0].scene.nodes);
    free(s->preparationRetiring[0].incoming);
    free(s->preparationRetiring[0].state);
    memset(&s->preparationRetiring[0], 0, sizeof(s->preparationRetiring[0]));
    for (uint32_t i = 1u; i < s->preparationRetiringCount; ++i)
        s->preparationRetiring[i - 1u] = s->preparationRetiring[i];
    if (s->preparationRetiringCount > 0u)
        memset(&s->preparationRetiring[s->preparationRetiringCount - 1u], 0,
            sizeof(s->preparationRetiring[0]));
    s->preparationRetiringCount -= 1u;
    s->preparationRetiredGraphCount += 1u;
    if (releasedNodes != graphNodes) s->preparationRetireAccountingErrors += 1u;
    s->preparationLiveBytes = 0u;
    for (uint32_t i = 0u; i < s->preparationRetiringCount; ++i)
        s->preparationLiveBytes += s->preparationRetiring[i].ownedBytes;
    if (s->preparationActive) s->preparationLiveBytes += s->preparationOwnedBytes;
    uint64_t reclaimNs = windows_prep_clock_ns();
    s->preparationLastTicket = ticket;
    s->preparationLastCancelNs = cancelNs;
    s->preparationLastRetiredNs = retiredNs;
    s->preparationLastReclaimNs = reclaimNs;
    s->preparationLastReleasedNodes = releasedNodes;
    s->preparationLastReleasedBytes = releasedBytes;
    s->preparationLastGraphNodes = graphNodes;
    s->preparationLastGraphBytes = graphBytes;
    windows_prep_log_ticket("reclaim_complete", s, graphNodes, graphBytes, ticket,
        cancelNs, retiredNs, releasedNodes, releasedBytes, graphNodes, graphBytes);
    return 1;
}

/* 退休回收：一次最多一个固定允许量（1ms）或 owner deadline，二者取早。
   返回“是否可以开始新的准备”：两个以上退休图未回收时不接受新票。 */
static int windows_prep_drain(CjguiWindowsRendererSession *s, uint64_t ownerDeadline) {
    if (!s) return 0;
    uint64_t now = windows_prep_clock_ns();
    uint64_t limit = now + CJGUI_WINDOWS_RETIREMENT_ALLOWANCE_NS;
    if (ownerDeadline != 0u && ownerDeadline < limit) limit = ownerDeadline;
    uint32_t reclaimed = 0u;
    for (uint32_t unit = 0u; unit < 256u && s->preparationRetiringCount > 0u; ++unit) {
        if (windows_prep_clock_ns() >= limit) break;
        if (!windows_prep_retire_unit(s)) break;
        reclaimed += 1u;
    }
    if (reclaimed != 0u)
        windows_prep_log("drain", s, reclaimed, s->preparationRetiringCount < 2u ? 1u : 0u);
    return s->preparationRetiringCount < 2u;
}

/* 取消/关闭把活跃私有图转入退休队列；队列满时就地全部释放，绝不悬挂。
   enteredNs 是调用方进入本次操作的时刻（取消即为 cancel 进入时刻）。就地释放也算
   真实回收：那一分支原先既不计数也不发事件，会让“回收完成”只覆盖队列路径。 */
static void windows_prep_retire_active(CjguiWindowsRendererSession *s, uint64_t enteredNs) {
    if (!s || !s->preparationActive) return;
    uint64_t retiredNs = windows_prep_clock_ns();
    uint64_t ticket = s->preparationId;
    if (s->preparationRetiringCount >= CJGUI_WINDOWS_PREPARATION_GRAPH_CAPACITY) {
        uint64_t graphNodes = s->preparationNodeCount;
        uint64_t graphBytes = s->preparationOwnedBytes;
        release_scene(&s->preparationScene);
        windows_prep_release_scene_nodes(s->preparationIncoming, s->preparationNodeCount);
        free(s->preparationState);
        s->preparationIncoming = NULL;
        s->preparationState = NULL;
        s->preparationRetiredNodeCount += graphNodes;
        s->preparationRetiredBytes += graphBytes;
        s->preparationRetiredGraphCount += 1u;
        s->preparationLastTicket = ticket;
        s->preparationLastCancelNs = enteredNs;
        s->preparationLastRetiredNs = retiredNs;
        s->preparationLastReclaimNs = windows_prep_clock_ns();
        s->preparationLastReleasedNodes = graphNodes;
        s->preparationLastReleasedBytes = graphBytes;
        s->preparationLastGraphNodes = graphNodes;
        s->preparationLastGraphBytes = graphBytes;
        windows_prep_log_ticket("retire", s, ticket, graphNodes, ticket, enteredNs, retiredNs,
            0u, 0u, graphNodes, graphBytes);
        windows_prep_log_ticket("reclaim_complete", s, graphNodes, graphBytes, ticket,
            enteredNs, retiredNs, graphNodes, graphBytes, graphNodes, graphBytes);
    } else {
        uint32_t slot = s->preparationRetiringCount++;
        s->preparationRetiring[slot].scene = s->preparationScene;
        s->preparationRetiring[slot].incoming = s->preparationIncoming;
        s->preparationRetiring[slot].state = s->preparationState;
        s->preparationRetiring[slot].nodeCount = s->preparationNodeCount;
        s->preparationRetiring[slot].releaseCursor = s->preparationNodeCount;
        s->preparationRetiring[slot].preparationId = s->preparationId;
        s->preparationRetiring[slot].ownedBytes = s->preparationOwnedBytes;
        s->preparationRetiring[slot].cancelNs = enteredNs;
        s->preparationRetiring[slot].retiredNs = retiredNs;
        s->preparationRetiring[slot].sessionGeneration = s->sessionGeneration;
        s->preparationRetiring[slot].deviceGeneration = s->deviceGeneration;
        memset(&s->preparationScene, 0, sizeof(s->preparationScene));
        s->preparationIncoming = NULL;
        s->preparationState = NULL;
        s->preparationLastTicket = ticket;
        s->preparationLastCancelNs = enteredNs;
        s->preparationLastRetiredNs = retiredNs;
        s->preparationLastReleasedNodes = 0u;
        s->preparationLastReleasedBytes = 0u;
        s->preparationLastGraphNodes = s->preparationRetiring[slot].nodeCount;
        s->preparationLastGraphBytes = s->preparationRetiring[slot].ownedBytes;
        windows_prep_log_ticket("retire", s, ticket, s->preparationRetiring[slot].nodeCount,
            ticket, enteredNs, retiredNs, 0u, 0u,
            s->preparationRetiring[slot].nodeCount, s->preparationRetiring[slot].ownedBytes);
    }
    free(s->preparationFrozenActiveBody);
    s->preparationFrozenActiveBody = NULL;
    windows_prep_clear_active_fields(s);
}

/* 冻结来源是否仍是本票的来源：任何输入/选择/绑定/几何/设备代/正文变化都拒旧。
   只读本会话已接受事实，不用后来镜像补旧票。 */
static int windows_prep_source_matches(CjguiWindowsRendererSession *s) {
    if (!s || !s->preparationActive) return 0;
    if (s->sessionGeneration != s->preparationFrozenSessionGeneration) return 0;
    if (s->deviceGeneration != s->preparationFrozenDeviceGeneration) return 0;
    if (s->deviceRecoveryCount != s->preparationFrozenDeviceRecoveryCount) return 0;
    if (s->resizeVersion != s->preparationFrozenResizeVersion) return 0;
    if ((uint64_t)s->dpi != s->preparationFrozenDpi) return 0;
    if (s->acceptedScene.configured) {
        if (s->acceptedScene.version != s->preparationFrozenAcceptedVersion) return 0;
    } else if (s->preparationFrozenAcceptedVersion != 0u) {
        return 0;
    }
    if (s->ownedTextSessionBindingEpoch != s->preparationFrozenBindingEpoch) return 0;
    if (s->focusedNodeId != s->preparationFrozenFocusedNodeId ||
        s->focusedResourceId != s->preparationFrozenFocusedResourceId ||
        s->focusedNodeKind != s->preparationFrozenFocusedNodeKind) return 0;
    if (s->selectionStart16 != s->preparationFrozenSelectionStart16 ||
        s->selectionEnd16 != s->preparationFrozenSelectionEnd16) return 0;
    if (s->pendingOwnedInputEventCount != s->preparationFrozenPendingOwnedInputs) return 0;
    if (s->sourceInstallPending != s->preparationFrozenSourceInstallPending) return 0;
    if (s->preparationFrozenActiveBody) {
        const char *live = s->proxyValueUtf8 ? (const char *)s->proxyValueUtf8 : "";
        if (strcmp(live, s->preparationFrozenActiveBody) != 0) return 0;
    }
    return 1;
}

static void windows_prep_freeze_identity(CjguiWindowsRendererSession *s, uint64_t baseSceneVersion) {
    s->preparationFrozenSessionGeneration = s->sessionGeneration;
    s->preparationFrozenDeviceGeneration = s->deviceGeneration;
    s->preparationFrozenDeviceRecoveryCount = s->deviceRecoveryCount;
    s->preparationFrozenResizeVersion = s->resizeVersion;
    s->preparationFrozenDpi = (uint64_t)s->dpi;
    s->preparationFrozenAcceptedVersion = s->acceptedScene.configured ? s->acceptedScene.version
        : baseSceneVersion;
    s->preparationFrozenBindingEpoch = s->ownedTextSessionBindingEpoch;
    s->preparationFrozenFocusedNodeId = s->focusedNodeId;
    s->preparationFrozenFocusedResourceId = s->focusedResourceId;
    s->preparationFrozenFocusedNodeKind = s->focusedNodeKind;
    s->preparationFrozenSelectionStart16 = s->selectionStart16;
    s->preparationFrozenSelectionEnd16 = s->selectionEnd16;
    s->preparationFrozenPendingOwnedInputs = s->pendingOwnedInputEventCount;
    s->preparationFrozenSourceInstallPending = s->sourceInstallPending;
    free(s->preparationFrozenActiveBody);
    s->preparationFrozenActiveBody = NULL;
    if (s->proxyValueUtf8) {
        CjguiInternalRendererStatus copyStatus = CJGUI_INTERNAL_RENDERER_OK;
        s->preparationFrozenActiveBody = copy_valid_utf8((const char *)s->proxyValueUtf8,
            CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY, NULL, &copyStatus);
    }
}

static CjguiInternalRendererStatus begin_composable_preparation_impl(
    uint64_t token, uint64_t preparationId, uint64_t baseSceneVersion,
    uint64_t projectionVersion, uint32_t nodeCount) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!preparationId || !projectionVersion || !nodeCount ||
        nodeCount > CJGUI_WINDOWS_SCENE_NODE_CAPACITY)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (s->acceptedScene.configured && baseSceneVersion != s->acceptedScene.version) {
        windows_prep_log("begin_stale", s, baseSceneVersion, s->acceptedScene.version);
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    if (s->preparationActive) {
        windows_prep_log("begin_refused", s, 1u, s->preparationId);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    /* 退休有界且保持记账：没有真实回收完的旧图不接受新私有图额度。 */
    if (!windows_prep_drain(s, 0u) ||
        s->preparationRetiringCount + 1u >= CJGUI_WINDOWS_PREPARATION_GRAPH_CAPACITY) {
        ++s->preparationBudgetRefusals;
        windows_prep_log("begin_refused", s, 2u, s->preparationRetiringCount);
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    }
    CjguiWindowsScene prepSceneLocal;
    memset(&prepSceneLocal, 0, sizeof(prepSceneLocal));
    prepSceneLocal.nodes = (CjguiWindowsSceneNode *)calloc(nodeCount, sizeof(CjguiWindowsSceneNode));
    if (!prepSceneLocal.nodes) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    prepSceneLocal.version = projectionVersion;
    prepSceneLocal.count = nodeCount;
    prepSceneLocal.configured = 1u;
    CjguiWindowsSceneNode *incoming =
        (CjguiWindowsSceneNode *)calloc(nodeCount, sizeof(CjguiWindowsSceneNode));
    uint8_t *state = (uint8_t *)calloc(nodeCount, 1u);
    if (!incoming || !state) {
        free(prepSceneLocal.nodes); free(incoming); free(state);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint32_t copied = s->acceptedScene.count < nodeCount ? s->acceptedScene.count : nodeCount;
    for (uint32_t i = 0u; i < copied; ++i) {
        CjguiInternalRendererStatus status = clone_scene_node(&prepSceneLocal.nodes[i], &s->acceptedScene.nodes[i]);
        if (status != CJGUI_INTERNAL_RENDERER_OK) {
            release_scene(&prepSceneLocal);
            free(incoming); free(state);
            return status;
        }
        prepSceneLocal.nodes[i].node.projectionVersion = projectionVersion;
        prepSceneLocal.nodes[i].candidateValueStaged = 0u;
        prepSceneLocal.nodes[i].candidateRunsPending = 0u;
        prepSceneLocal.nodes[i].candidateRetainedBindingValid = 1u;
        prepSceneLocal.ownedBytes += prepSceneLocal.nodes[i].ownedBytes;
    }
    /* 冻结副本自身也吃这份私有额度：私有图总量有界，容量不足具名保旧。 */
    if (prepSceneLocal.ownedBytes > CJGUI_WINDOWS_PREPARATION_BYTE_CAPACITY) {
        uint64_t refusedBytes = prepSceneLocal.ownedBytes;
        release_scene(&prepSceneLocal);
        free(incoming); free(state);
        ++s->preparationBudgetRefusals;
        windows_prep_log("begin_refused", s, 3u, refusedBytes);
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    }
    s->preparationScene = prepSceneLocal;
    s->preparationIncoming = incoming;
    s->preparationState = state;
    s->preparationId = preparationId;
    s->preparationProjectionVersion = projectionVersion;
    s->preparationNodeCount = nodeCount;
    s->preparationStagedCount = 0u;
    s->preparationPreparedCount = 0u;
    s->preparationCursor = 0u;
    s->preparationOwnedBytes = prepSceneLocal.ownedBytes;
    s->preparationReady = 0u;
    s->preparationActive = 1u;
    s->preparationLiveBytes += prepSceneLocal.ownedBytes;
    windows_prep_freeze_identity(s, baseSceneVersion);
    windows_prep_log("begin", s, prepSceneLocal.version, prepSceneLocal.ownedBytes);
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus prepare_composable_node_impl(
    uint64_t token, uint64_t preparationId, uint32_t index,
    const CjguiInternalRendererComposableNode *node,
    const CjguiInternalRendererComposableGeometry *geometry,
    const char *label, const char *value, const char *semanticId,
    const char *bindingKey, const char *rowKey, const char *parentRowKey,
    const char *semanticLabel, const char *encodedRuns) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!s->preparationActive) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    if (s->preparationId != preparationId) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    if (s->preparationReady || index >= s->preparationNodeCount || !node || !geometry ||
        s->preparationState[index] != 0u)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiInternalRendererStatus status = validate_composable_node(node, s->preparationProjectionVersion);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    if (geometry->nodeId != node->nodeId || geometry->clipCount != node->clipConstraintCount ||
        geometry->reserved != 0u || geometry->clipCount > 4u)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    const double values[] = {geometry->translateX, geometry->translateY, geometry->clip0X,
        geometry->clip0Y, geometry->clip1X, geometry->clip1Y, geometry->clip2X, geometry->clip2Y,
        geometry->clip3X, geometry->clip3Y};
    for (size_t i = 0; i < sizeof(values) / sizeof(values[0]); ++i)
        if (!isfinite(values[i]) || values[i] < -1000000.0 || values[i] > 1000000.0)
            return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    /* 图像候选不进私有准备：声明在本平台不明，退回具名完整声明回退。 */
    if (node->nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE)
        return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
    CjguiWindowsSceneNode next;
    memset(&next, 0, sizeof(next));
    status = windows_prep_copy_strings(&next, node, label, value, semanticId, bindingKey,
        rowKey, parentRowKey, semanticLabel, encodedRuns);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        release_scene_node(&next);
        return status;
    }
    next.geometry = *geometry;
    next.hasGeometry = 1u;
    next.candidateValueStaged = 1u;
    next.candidateRunsPending = 0u;
    /* run/正文配对与 UTF-8 校验先过，未通过不占私有额度。 */
    CjguiWindowsTextStyleRun *runs = NULL;
    uint32_t runCount = 0u;
    status = parse_style_run_list(next.textRuns ? next.textRuns : "", next.value ? next.value : "",
        &runs, &runCount);
    free(runs);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        release_scene_node(&next);
        return status;
    }
    if (next.ownedBytes > CJGUI_WINDOWS_PREPARATION_BYTE_CAPACITY ||
        s->preparationOwnedBytes > CJGUI_WINDOWS_PREPARATION_BYTE_CAPACITY - next.ownedBytes) {
        uint64_t refusedBytes = next.ownedBytes;
        release_scene_node(&next);
        ++s->preparationBudgetRefusals;
        windows_prep_log("prepare_refused", s, index, refusedBytes);
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    }
    s->preparationIncoming[index] = next;
    s->preparationState[index] = 1u;
    s->preparationOwnedBytes += next.ownedBytes;
    s->preparationLiveBytes += next.ownedBytes;
    s->preparationStagedCount += 1u;
    s->preparationCopiedCount += 1u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

/* 推进一个不可抢占的排版/光栅单元。旧代（begin 克隆来的 accepted 同下标）
   只作为同一布局来源的复用来源；本平台不从别的图/容器借纹理。 */
static CjguiInternalRendererStatus windows_prep_advance_unit(CjguiWindowsRendererSession *s) {
    if (s->preparationPreparedCount >= s->preparationNodeCount) {
        s->preparationReady = 1u;
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    uint32_t index = s->preparationNodeCount;
    for (uint32_t i = s->preparationCursor; i < s->preparationNodeCount; ++i) {
        if (s->preparationState[i] == 2u) continue;
        /* 0 = 该笔声明尚未收到：让出，不在一次 advance 里轮询等待。 */
        if (s->preparationState[i] == 1u) index = i;
        break;
    }
    if (index >= s->preparationNodeCount) return CJGUI_INTERNAL_RENDERER_OK;
    CjguiWindowsSceneNode next = s->preparationIncoming[index];
    memset(&s->preparationIncoming[index], 0, sizeof(CjguiWindowsSceneNode));
    uint64_t incomingBytes = next.ownedBytes;
    uint64_t oldBytes = s->preparationScene.nodes[index].ownedBytes;
    next.hasGeometry = 1u;
    next.candidateValueStaged = 1u;
    next.candidateRunsPending = 0u;
    next.candidateRetainedBindingValid = 1u;
    CjguiInternalRendererStatus status =
        prepare_scene_node_text(s, &s->preparationScene, index, &next);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        if (status == CJGUI_INTERNAL_RENDERER_PRESENT_PENDING ||
            status == CJGUI_INTERNAL_RENDERER_METAL_DEVICE_UNAVAILABLE) {
            /* 设备丢失/恢复中：本笔声明不消费，旧 accepted 继续服务，下一轮重试。 */
            release_scene_node(&next);
            return CJGUI_INTERNAL_RENDERER_OK;
        }
        /* 本单元失败即整票失败（调用者会取消）；在途声明已释放，不重放同一票。 */
        release_scene_node(&next);
        s->preparationState[index] = 0u;
        if (s->preparationStagedCount > 0u) s->preparationStagedCount -= 1u;
        if (incomingBytes > s->preparationOwnedBytes) s->preparationOwnedBytes = 0u;
        else s->preparationOwnedBytes -= incomingBytes;
        if (incomingBytes > s->preparationLiveBytes) s->preparationLiveBytes = 0u;
        else s->preparationLiveBytes -= incomingBytes;
        return status;
    }
    release_scene_node(&s->preparationScene.nodes[index]);
    s->preparationScene.nodes[index] = next;
    s->preparationScene.ownedBytes = s->preparationScene.ownedBytes - oldBytes + incomingBytes;
    if (s->preparationOwnedBytes >= oldBytes) s->preparationOwnedBytes -= oldBytes;
    else s->preparationOwnedBytes = 0u;
    if (s->preparationLiveBytes >= oldBytes) s->preparationLiveBytes -= oldBytes;
    else s->preparationLiveBytes = 0u;
    s->preparationState[index] = 2u;
    s->preparationPreparedCount += 1u;
    s->preparationCursor = index + 1u;
    s->preparationUnitCount += 1u;
    if (s->preparationPreparedCount >= s->preparationNodeCount) s->preparationReady = 1u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

/* 一次 advance 调用里真正做完的准备批次。此前只有 prepare_refused 会留下事件，
   健康运行中"准备"这一步完全没有可归因的同步成本；这里让它与 begin/advance/
   promote/drain 分别计时，advance_yield 仍只表示"为什么提前返回"。 */
static void windows_prep_log_batch(CjguiWindowsRendererSession *s, uint32_t batchStart) {
    if (s->preparationPreparedCount == batchStart) return;
    windows_prep_log("prepare", s, s->preparationPreparedCount - batchStart,
        s->preparationLiveBytes);
}

static CjguiInternalRendererStatus advance_composable_preparation_impl(
    uint64_t token, uint64_t preparationId, uint64_t deadlineNs, uint32_t *outReady) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outReady) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outReady = 0u;
    if (!s->preparationActive) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    if (s->preparationId != preparationId) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    if (!windows_prep_source_matches(s)) {
        ++s->preparationStaleCount;
        windows_prep_log("advance_stale", s, deadlineNs, 0u);
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    if (s->preparationReady) {
        *outReady = 1u;
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    /* 图形设备不可用时让出而不是假完成；旧 accepted 继续服务输入。 */
    if (s->graphicsRecoveryPending || !s->device || !s->context) {
        windows_prep_log("advance_yield", s, 1u, 0u);
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    /* 同一绝对预算：deadline 为 0 的调用者保留原来的一个单元契约。 */
    const uint32_t unitLimit = deadlineNs ? CJGUI_WINDOWS_PREPARATION_UNIT_LIMIT : 1u;
    const uint32_t batchStart = s->preparationPreparedCount;
    for (uint32_t unit = 0u; unit < unitLimit; ++unit) {
        if (!windows_prep_source_matches(s)) {
            ++s->preparationStaleCount;
            windows_prep_log("advance_stale", s, deadlineNs, 1u);
            return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
        }
        uint64_t now = windows_prep_clock_ns();
        if (deadlineNs != 0u &&
            (now >= deadlineNs || deadlineNs - now < CJGUI_WINDOWS_PREPARATION_DEADLINE_RESERVE_NS)) {
            ++s->preparationDeadlineHits;
            windows_prep_log_batch(s, batchStart);
            windows_prep_log("advance_yield", s, 2u, deadlineNs);
            return CJGUI_INTERNAL_RENDERER_OK;
        }
        uint32_t preparedBefore = s->preparationPreparedCount;
        CjguiInternalRendererStatus status = windows_prep_advance_unit(s);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
        *outReady = s->preparationReady ? 1u : 0u;
        if (*outReady) {
            windows_prep_log_batch(s, batchStart);
            windows_prep_log("ready", s, s->preparationUnitCount, s->preparationLiveBytes);
            return CJGUI_INTERNAL_RENDERER_OK;
        }
        /* 声明尚未收齐或本单元没有推进：立刻让出。 */
        if (s->preparationPreparedCount == preparedBefore) {
            windows_prep_log_batch(s, batchStart);
            windows_prep_log("advance_yield", s, 3u, preparedBefore);
            return CJGUI_INTERNAL_RENDERER_OK;
        }
    }
    windows_prep_log_batch(s, batchStart);
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus promote_composable_preparation_impl(
    uint64_t token, uint64_t preparationId) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!s->preparationActive || s->preparationId != preparationId ||
        !s->preparationReady ||
        s->preparationPreparedCount != s->preparationNodeCount ||
        !s->candidateScene.configured ||
        s->candidateScene.version != s->preparationProjectionVersion ||
        s->candidateScene.count != s->preparationNodeCount) {
        windows_prep_log("promote_refused", s, s->preparationReady ? 1u : 0u,
            s->candidateScene.configured ? s->candidateScene.version : 0u);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    /* 最后一笔输入可能在本票最后单元之后到达：来源不再匹配就不发布。 */
    if (!windows_prep_source_matches(s)) {
        ++s->preparationStaleCount;
        windows_prep_log("promote_stale", s, preparationId, 0u);
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    /* 同一份已准备资源转交候选：不重排、不重栅格化。 */
    for (uint32_t i = 0u; i < s->preparationNodeCount; ++i) {
        CjguiWindowsSceneNode *target = &s->candidateScene.nodes[i];
        CjguiWindowsSceneNode *source = &s->preparationScene.nodes[i];
        if (s->preparationState[i] != 2u || !source->hasNode || !source->hasGeometry)
            return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        uint64_t oldBytes = target->ownedBytes;
        release_scene_node(target);
        *target = *source;
        memset(source, 0, sizeof(*source));
        s->candidateScene.ownedBytes = s->candidateScene.ownedBytes - oldBytes + target->ownedBytes;
        target->candidateValueStaged = 1u;
        target->candidateRunsPending = 0u;
        target->candidateRetainedBindingValid = 1u;
        if (target->ownedBytes <= s->preparationLiveBytes) {
            s->preparationLiveBytes -= target->ownedBytes;
        } else {
            s->preparationLiveBytes = 0u;
        }
    }
    release_scene(&s->preparationScene);
    windows_prep_release_scene_nodes(s->preparationIncoming, s->preparationNodeCount);
    free(s->preparationState);
    free(s->preparationFrozenActiveBody);
    s->preparationIncoming = NULL;
    s->preparationState = NULL;
    s->preparationFrozenActiveBody = NULL;
    /* 活跃图字节全部转交给候选；存活记账只余退休图。 */
    uint64_t retiredLive = 0u;
    for (uint32_t i = 0u; i < s->preparationRetiringCount; ++i)
        retiredLive += s->preparationRetiring[i].ownedBytes;
    s->preparationLiveBytes = retiredLive;
    windows_prep_clear_active_fields(s);
    windows_prep_log("promote", s, s->candidateScene.count, s->candidateScene.ownedBytes);
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus cancel_composable_preparation_impl(
    uint64_t token, uint64_t preparationId) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!s->preparationActive) return CJGUI_INTERNAL_RENDERER_OK;
    if (s->preparationId != preparationId) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ++s->preparationCancelCount;
    uint64_t liveBefore = s->preparationLiveBytes;
    /* 取消只做“逻辑退休”：私有图转入退休队列、槽位与字节保持记账。真实回收由
       drain/下一次 begin 的有界允许量推进（与共同 Mac 同责任划分），所以取消始终
       有界响应，而“回收完成”只能由真实释放证明，不能在这里假称。
       cancel 进入时刻与票身份写进退休记录：active 票号从这里开始就是 0，之后
       任何一行都只能按 ticket= 追这张票，不能拿归零后的 active 算回收。 */
    uint64_t cancelEnteredNs = windows_prep_clock_ns();
    windows_prep_retire_active(s, cancelEnteredNs);
    windows_prep_log_ticket("cancel", s, liveBefore, s->preparationLiveBytes,
        s->preparationLastTicket, cancelEnteredNs, s->preparationLastRetiredNs,
        s->preparationLastReleasedNodes, s->preparationLastReleasedBytes,
        s->preparationLastGraphNodes, s->preparationLastGraphBytes);
    return CJGUI_INTERNAL_RENDERER_OK;
}


static CjguiInternalRendererStatus configure_composable_scene_impl(
    uint64_t token, uint64_t projectionVersion, uint32_t nodeCount) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    return scene_configure(s, projectionVersion, nodeCount);
}

static CjguiInternalRendererStatus discard_composable_scene_candidate_impl(
    uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    release_scene(&s->candidateScene);
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus set_scene_geometry(CjguiWindowsRendererSession *s,
    uint64_t projectionVersion, uint32_t index,
    const CjguiInternalRendererComposableGeometry *geometry) {
    if (!s || !geometry || !s->candidateScene.configured ||
        projectionVersion != s->candidateScene.version || index >= s->candidateScene.count)
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    CjguiWindowsSceneNode *target = &s->candidateScene.nodes[index];
    if (!target->hasNode || target->node.nodeId != geometry->nodeId ||
        target->hasGeometry || geometry->clipCount != target->node.clipConstraintCount ||
        geometry->clipCount > 4u || geometry->reserved != 0u)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    const double values[] = {geometry->translateX, geometry->translateY,
        geometry->clip0X, geometry->clip0Y, geometry->clip1X, geometry->clip1Y,
        geometry->clip2X, geometry->clip2Y, geometry->clip3X, geometry->clip3Y};
    for (size_t i = 0; i < sizeof(values) / sizeof(values[0]); ++i)
        if (!isfinite(values[i]) || values[i] < -1000000.0 || values[i] > 1000000.0)
            return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    target->geometry = *geometry;
    target->hasGeometry = 1u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus set_composable_scene_geometry_impl(
    uint64_t token, uint64_t projectionVersion, uint32_t nodeIndex,
    const CjguiInternalRendererComposableGeometry *geometry) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    return set_scene_geometry(s, projectionVersion, nodeIndex, geometry);
}


static void release_image_resource(CjguiWindowsImageResource *r) {
    free(r->path); free(r->identifier); release_text_texture_lease(&r->lease);
    memset(r, 0, sizeof(*r));
}

static CjguiWindowsImageResource *find_image_resource(CjguiWindowsRendererSession *s,
    const char *path, const char *identifier, uint64_t version) {
    if (!path || !identifier) return NULL;
    for (uint32_t i=0; i<CJGUI_WINDOWS_IMAGE_CACHE_CAPACITY; ++i) {
        CjguiWindowsImageResource *r=&s->images[i];
        if (r->lease && r->version==version && !strcmp(r->path,path) && !strcmp(r->identifier,identifier))
            return r;
    }
    return NULL;
}

static CjguiInternalRendererStatus create_image_gpu(CjguiWindowsRendererSession *s,
    CjguiWindowsTextTextureLease *lease) {
    D3D11_TEXTURE2D_DESC d; memset(&d,0,sizeof(d));
    d.Width=lease->imageWidth; d.Height=lease->imageHeight;
    d.MipLevels=1; d.ArraySize=1; d.Format=DXGI_FORMAT_R8G8B8A8_UNORM;
    d.SampleDesc.Count=1; d.Usage=D3D11_USAGE_IMMUTABLE; d.BindFlags=D3D11_BIND_SHADER_RESOURCE;
    D3D11_SUBRESOURCE_DATA data={lease->imagePixels,d.Width*4u,0};
    HRESULT hr=ID3D11Device_CreateTexture2D(s->device,&d,&data,&lease->texture);
    if (SUCCEEDED(hr)) hr=ID3D11Device_CreateShaderResourceView(s->device,
        (ID3D11Resource*)lease->texture,NULL,&lease->view);
    if (FAILED(hr)) {
        if (lease->view) ID3D11ShaderResourceView_Release(lease->view);
        if (lease->texture) ID3D11Texture2D_Release(lease->texture);
        lease->view=NULL; lease->texture=NULL; s->lastGraphicsFailure=hr;
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus prepare_image(CjguiWindowsRendererSession *s,
    const char *path,const char *identifier,uint64_t version,const uint8_t *encoded,uint32_t length,
    CjguiWindowsImageResource **out) {
    *out=NULL;
    if (s->graphicsRecoveryPending || !s->device || !s->context) return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
    CjguiWindowsImageResource *cached=find_image_resource(s,path,identifier,version);
    if (cached) {
        if (encoded && (length!=cached->lease->imageEncodedLength ||
            memcmp(encoded,cached->lease->imageEncoded,length)!=0)) return CJGUI_INTERNAL_RENDERER_PNG_INVALID;
        cached->access=++s->imageAccess; *out=cached; return CJGUI_INTERNAL_RENDERER_OK;
    }
    if (!path || !identifier || strnlen(path,32768u)>=32768u || strnlen(identifier,32768u)>=32768u)
        return CJGUI_INTERNAL_RENDERER_PNG_INVALID;
    uint8_t *fileBytes=NULL;
    if (!encoded) {
        int units=MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,path,-1,NULL,0);
        if (units<=0) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
        WCHAR *wide=(WCHAR*)malloc((size_t)units*sizeof(WCHAR));
        if (!wide) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,path,-1,wide,units);
        HANDLE file=CreateFileW(wide,GENERIC_READ,FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE,
            NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL); free(wide);
        if (file==INVALID_HANDLE_VALUE) return CJGUI_INTERNAL_RENDERER_PNG_INVALID;
        LARGE_INTEGER size; DWORD read=0;
        if (!GetFileSizeEx(file,&size) || size.QuadPart<=0 || size.QuadPart>CJGUI_WINDOWS_IMAGE_ENCODED_CAPACITY) {
            CloseHandle(file); return CJGUI_INTERNAL_RENDERER_PNG_PAYLOAD_TOO_LARGE;
        }
        length=(uint32_t)size.QuadPart; fileBytes=(uint8_t*)malloc(length);
        if (!fileBytes) { CloseHandle(file); return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR; }
        int ok=ReadFile(file,fileBytes,length,&read,NULL) && read==length;
        CloseHandle(file);
        if (!ok) { free(fileBytes); return CJGUI_INTERNAL_RENDERER_PNG_INVALID; }
        encoded=fileBytes;
    }
    uint32_t width=0,height=0; uint64_t bytes=0;
    int decoded=cjgui_windows_wic_decode_png_rgba8(encoded,length,CJGUI_WINDOWS_IMAGE_ENCODED_CAPACITY,
        4096,4096,CJGUI_WINDOWS_IMAGE_DECODED_CAPACITY,NULL,0,&width,&height,&bytes);
    if (decoded!=CJGUI_WINDOWS_WIC_OUTPUT_TOO_SMALL) {
        free(fileBytes);
        return decoded==CJGUI_WINDOWS_WIC_DIMENSION_EXCEEDED ? CJGUI_INTERNAL_RENDERER_PNG_DIMENSION_EXCEEDED :
            decoded==CJGUI_WINDOWS_WIC_BUDGET_EXCEEDED ? CJGUI_INTERNAL_RENDERER_PNG_RESOURCE_BUDGET_EXCEEDED :
            CJGUI_INTERNAL_RENDERER_PNG_INVALID;
    }
    bytes=(uint64_t)width*height*4u;
    /* Admit CPU+GPU storage before allocating; no eviction of live scenes or flights. */
    uint64_t storageBytes=bytes+(uint64_t)length;
    if (s->imageCpuBytesInUse>CJGUI_WINDOWS_IMAGE_SESSION_CAPACITY || s->imageGpuBytesInUse>CJGUI_WINDOWS_IMAGE_SESSION_CAPACITY ||
        storageBytes>CJGUI_WINDOWS_IMAGE_SESSION_CAPACITY-s->imageCpuBytesInUse ||
        bytes>CJGUI_WINDOWS_IMAGE_SESSION_CAPACITY-s->imageGpuBytesInUse) {
        free(fileBytes); return CJGUI_INTERNAL_RENDERER_PNG_RESOURCE_BUDGET_EXCEEDED;
    }
    CjguiWindowsImageResource *slot=NULL;
    for (uint32_t i=0;i<CJGUI_WINDOWS_IMAGE_CACHE_CAPACITY;++i) {
        CjguiWindowsImageResource *r=&s->images[i];
        if (!r->lease) { slot=r; break; }
        if (r->lease->refs==1 && (!slot || r->access<slot->access)) slot=r;
    }
    if (!slot) { free(fileBytes); return CJGUI_INTERNAL_RENDERER_PNG_RESOURCE_BUDGET_EXCEEDED; }
    CjguiWindowsTextTextureLease *lease=(CjguiWindowsTextTextureLease*)calloc(1,sizeof(*lease));
    char *copyPath=_strdup(path),*copyId=_strdup(identifier);
    uint8_t *pixels=(uint8_t*)malloc((size_t)bytes),*encodedCopy=(uint8_t*)malloc(length);
    if (!lease || !copyPath || !copyId || !pixels || !encodedCopy) {
        free(lease);free(copyPath);free(copyId);free(pixels);free(encodedCopy);free(fileBytes);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    memcpy(encodedCopy,encoded,length);
    decoded=cjgui_windows_wic_decode_png_rgba8(encoded,length,CJGUI_WINDOWS_IMAGE_ENCODED_CAPACITY,
        4096,4096,CJGUI_WINDOWS_IMAGE_DECODED_CAPACITY,pixels,bytes,&width,&height,&bytes);
    free(fileBytes);
    if (decoded!=CJGUI_WINDOWS_WIC_OK) {
        free(lease);free(copyPath);free(copyId);free(pixels);free(encodedCopy);return CJGUI_INTERNAL_RENDERER_PNG_DECODE_FAILED;
    }
    lease->refs=1;lease->bytes=bytes;lease->imagePixels=pixels;
    lease->imageWidth=width;lease->imageHeight=height;lease->imageEncoded=encodedCopy;
    lease->imageEncodedLength=length;lease->imageStorageBytes=storageBytes;
    CjguiInternalRendererStatus status=create_image_gpu(s,lease);
    if (status!=CJGUI_INTERNAL_RENDERER_OK) {
        free(lease);free(copyPath);free(copyId);free(pixels);free(encodedCopy);return status;
    }
    lease->sessionBytesInUse=&s->imageGpuBytesInUse;lease->sessionCountInUse=&s->imageCountInUse;
    lease->imageCpuBytesInUse=&s->imageCpuBytesInUse;
    s->imageGpuBytesInUse+=bytes;s->imageCpuBytesInUse+=storageBytes;++s->imageCountInUse;
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    InterlockedExchangeAdd64(&g_contractLiveTextTextureBytes,(LONG64)bytes);
    InterlockedIncrement(&g_contractLiveTextTextureResources);
#endif
    release_image_resource(slot);
    slot->path=copyPath;slot->identifier=copyId;slot->version=version;
    slot->access=++s->imageAccess;slot->lease=lease;*out=slot;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus set_composable_scene_node_impl(
    uint64_t token, uint32_t nodeIndex, const CjguiInternalRendererComposableNode *node,
    const char *label, const char *value, const char *imageResourcePath,
    const char *imageResourceId, uint64_t imageResourceVersion) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!s->candidateScene.configured || nodeIndex >= s->candidateScene.count)
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    CjguiInternalRendererStatus status = validate_composable_node(node, s->candidateScene.version);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        if (getenv("PHAROS_WINDOWS_TEST_PROBE_FILE"))
            fprintf(stderr,"CJGUI_WINDOWS_NODE_VALIDATE_FAIL node=%llu kind=%u version=%llu target=%llu xywh=%lld,%lld,%lld,%lld clips=%u\n",
                (unsigned long long)node->nodeId,node->nodeKind,(unsigned long long)node->projectionVersion,
                (unsigned long long)s->candidateScene.version,(long long)node->x,(long long)node->y,
                (long long)node->width,(long long)node->height,node->clipConstraintCount);
        return status;
    }
    CjguiWindowsSceneNode next;
    memset(&next, 0, sizeof(next));
    CjguiWindowsTextRunDeclaration *declaration = text_runs_by_id(s, node->nodeId);
    uint64_t copiedAt=s->traceEnabled?cjgui_internal_renderer_owner_clock_ns():0;
    status = copy_node_strings(&next, node, label, value, imageResourcePath,
        imageResourceId, declaration ? declaration->encoded : "");
    if (s->traceEnabled && value && strlen(value)>8192u)
        windows_trace(s,"copy",node->nodeId,strlen(value),
            cjgui_internal_renderer_owner_clock_ns()-copiedAt,nodeIndex,s->candidateScene.count,status);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        release_scene_node(&next);
        return status;
    }
    if (next.ownedBytes > CJGUI_WINDOWS_TEXT_BYTE_CAPACITY -
        (s->candidateScene.ownedBytes - s->candidateScene.nodes[nodeIndex].ownedBytes)) {
        release_scene_node(&next);
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    }
    CjguiWindowsSceneNode *viewportOwner = scene_node_by_id(&s->acceptedScene, node->nodeId);
    if (node->nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT && viewportOwner &&
        viewportOwner->node.nodeKind == node->nodeKind && viewportOwner->node.resourceId == node->resourceId)
        next.multilineScrollY = viewportOwner->multilineScrollY;
    if (node->nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE) {
        CjguiWindowsImageResource *image=NULL;
        status=prepare_image(s,imageResourcePath,imageResourceId,imageResourceVersion,NULL,0,&image);
        if (status==CJGUI_INTERNAL_RENDERER_OK && retain_text_texture_lease(image->lease)) {
            next.imageLease=image->lease; next.imageResourceVersion=imageResourceVersion;
        } else if (status==CJGUI_INTERNAL_RENDERER_OK) status=CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    } else status = prepare_scene_node_text(s, &s->candidateScene, nodeIndex, &next);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        if (getenv("PHAROS_WINDOWS_TEST_PROBE_FILE"))
            fprintf(stderr,"CJGUI_WINDOWS_NODE_PREPARE_FAIL node=%llu kind=%u size=%lldx%lld font=%.2f dpi=%u body=%llu status=%d hr=%08lx\n",
                (unsigned long long)node->nodeId,node->nodeKind,(long long)node->width,(long long)node->height,
                node->fontSize,s->dpi,(unsigned long long)strlen(value?value:""),status,(unsigned long)s->lastGraphicsFailure);
        release_scene_node(&next);
        return status;
    }
    uint64_t oldOwnedBytes = s->candidateScene.nodes[nodeIndex].ownedBytes;
    release_scene_node(&s->candidateScene.nodes[nodeIndex]);
    s->candidateScene.ownedBytes -= oldOwnedBytes;
    next.candidateValueStaged = 1u;
    next.candidateRunsPending = 0u;
    s->candidateScene.nodes[nodeIndex] = next;
    s->candidateScene.ownedBytes += next.ownedBytes;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus set_composable_scene_node_bytes_impl(
    uint64_t token, uint32_t nodeIndex, const CjguiInternalRendererComposableNode *node,
    const char *label, const char *value, const char *imageResourcePath,
    const char *imageResourceId, uint64_t imageResourceVersion,
    const uint8_t *bytes, uint32_t length) {
    CjguiWindowsRendererSession *s=find_session(token);
    if (require_session(s)!=CJGUI_INTERNAL_RENDERER_OK) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!node || node->nodeKind!=CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE || !bytes || !length)
        return CJGUI_INTERNAL_RENDERER_PNG_INVALID;
    CjguiWindowsImageResource *image=NULL;
    CjguiInternalRendererStatus status=prepare_image(s,imageResourcePath,imageResourceId,imageResourceVersion,bytes,length,&image);
    if (status!=CJGUI_INTERNAL_RENDERER_OK) return status;
    return set_composable_scene_node_impl(token,nodeIndex,node,label,value,imageResourcePath,imageResourceId,imageResourceVersion);
}

static CjguiInternalRendererStatus set_composable_node_semantic_identity_impl(
    uint64_t token, uint32_t nodeIndex, const char *semanticId) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!s->candidateScene.configured || nodeIndex >= s->candidateScene.count ||
        !s->candidateScene.nodes[nodeIndex].hasNode) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_OK;
    uint64_t length = 0u;
    char *copy = copy_valid_utf8(semanticId, CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY, &length, &status);
    if (!copy || status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiWindowsSceneNode *target = &s->candidateScene.nodes[nodeIndex];
    CjguiWindowsSceneNode *oldViewport = scene_node_by_id(&s->acceptedScene, target->node.nodeId);
    if (!oldViewport || strcmp(oldViewport->semanticId ? oldViewport->semanticId : "", copy) != 0)
        target->multilineScrollY = 0.0;
    if (length > CJGUI_WINDOWS_TEXT_BYTE_CAPACITY -
        (s->candidateScene.ownedBytes - strlen(target->semanticId ? target->semanticId : ""))) {
        free(copy);
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    }
    s->candidateScene.ownedBytes -= strlen(target->semanticId ? target->semanticId : "");
    target->ownedBytes -= strlen(target->semanticId ? target->semanticId : "");
    if (strcmp(target->semanticId ? target->semanticId : "", copy) != 0)
        target->candidateRetainedBindingValid = 0u;
    free(target->semanticId);
    target->semanticId = copy;
    target->ownedBytes += length;
    s->candidateScene.ownedBytes += length;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus set_composable_node_semantic_metadata_impl(
    uint64_t token, uint32_t nodeIndex, const char *bindingKey, const char *rowKey,
    const char *parentRowKey, const char *semanticLabel) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!s->candidateScene.configured || nodeIndex >= s->candidateScene.count ||
        !s->candidateScene.nodes[nodeIndex].hasNode) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    const char *inputs[4] = {bindingKey, rowKey, parentRowKey, semanticLabel};
    char **fields[4] = {&s->candidateScene.nodes[nodeIndex].bindingKey,
        &s->candidateScene.nodes[nodeIndex].rowKey,
        &s->candidateScene.nodes[nodeIndex].parentRowKey,
        &s->candidateScene.nodes[nodeIndex].semanticLabel};
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_OK;
    char *copies[4] = {NULL, NULL, NULL, NULL};
    uint64_t lengths[4] = {0u, 0u, 0u, 0u};
    for (size_t i = 0; i < 4u; ++i) {
        copies[i] = copy_valid_utf8(inputs[i], CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY,
            &lengths[i], &status);
        if (!copies[i] || status != CJGUI_INTERNAL_RENDERER_OK) {
            for (size_t j = 0; j < 4u; ++j) free(copies[j]);
            return status;
        }
    }
    CjguiWindowsSceneNode *target = &s->candidateScene.nodes[nodeIndex];
    uint64_t oldBytes = 0u, newBytes = 0u;
    for (size_t i = 0; i < 4u; ++i) {
        oldBytes += strlen(*fields[i] ? *fields[i] : "");
        newBytes += lengths[i];
    }
    if (newBytes > oldBytes && newBytes - oldBytes >
        CJGUI_WINDOWS_TEXT_BYTE_CAPACITY - (s->candidateScene.ownedBytes - oldBytes)) {
        for (size_t i = 0; i < 4u; ++i) free(copies[i]);
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    }
    CjguiWindowsSceneNode *oldViewport = scene_node_by_id(&s->acceptedScene, target->node.nodeId);
    if (!oldViewport || strcmp(oldViewport->bindingKey ? oldViewport->bindingKey : "", copies[0]) != 0)
        target->multilineScrollY = 0.0;
    /* bindingKey encodes the shared window's full operation/field identity.
       Display label and hierarchy metadata do not change body ownership. */
    if (strcmp(target->bindingKey ? target->bindingKey : "", copies[0]) != 0)
        target->candidateRetainedBindingValid = 0u;
    for (size_t i = 0; i < 4u; ++i) { free(*fields[i]); *fields[i] = copies[i]; }
    target->ownedBytes = target->ownedBytes - oldBytes + newBytes;
    s->candidateScene.ownedBytes = s->candidateScene.ownedBytes - oldBytes + newBytes;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus set_composable_text_runs_impl(
    uint64_t token, uint64_t nodeId, const char *encoded) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_OK;
    uint64_t length = 0u;
    char *copy = copy_valid_utf8(encoded, CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY, &length, &status);
    if (!copy || status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiWindowsTextRunDeclaration *entry = text_runs_by_id(s, nodeId);
    CjguiWindowsSceneNode *candidate = scene_node_by_id(&s->candidateScene, nodeId);
    CjguiWindowsTextStyleRun *validatedRuns = NULL;
    uint32_t validatedCount = 0u;
    int candidateReady = candidate && candidate->candidateValueStaged;
    status = parse_style_run_list(copy, candidateReady ? candidate->value : NULL,
        &validatedRuns, &validatedCount);
    free(validatedRuns);
    if (status != CJGUI_INTERNAL_RENDERER_OK) { free(copy); return status; }
    char *candidateCopy = NULL;
    CjguiWindowsSceneNode next;
    memset(&next, 0, sizeof(next));
    uint32_t candidateIndex = 0u;
    uint64_t old = 0u;
    if (candidateReady) {
        candidateIndex = (uint32_t)(candidate - s->candidateScene.nodes);
        old = strlen(candidate->textRuns ? candidate->textRuns : "");
        if (length > old && length - old >
            CJGUI_WINDOWS_TEXT_BYTE_CAPACITY - (s->candidateScene.ownedBytes - old)) {
            free(copy);
            return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
        }
        candidateCopy = copy_valid_utf8(copy, CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY, NULL, &status);
        if (!candidateCopy || status != CJGUI_INTERNAL_RENDERER_OK) { free(copy); return status; }
        status = clone_scene_node(&next, candidate);
        if (status != CJGUI_INTERNAL_RENDERER_OK) { free(copy); free(candidateCopy); return status; }
        free(next.textRuns);
        next.textRuns = candidateCopy;
        candidateCopy = NULL;
        next.ownedBytes = next.ownedBytes - old + length;
        next.candidateValueStaged = 1u;
        next.candidateRunsPending = 0u;
        next.hasGeometry = candidate->hasGeometry;
        status = prepare_scene_node_text(s, &s->candidateScene, candidateIndex, &next);
        if (status != CJGUI_INTERNAL_RENDERER_OK) {
            release_scene_node(&next);
            free(copy);
            return status;
        }
    }
    if (!entry && s->textRunDeclarationCount >= CJGUI_WINDOWS_SCENE_NODE_CAPACITY) {
        free(copy); free(candidateCopy); release_scene_node(&next);
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    }
    if (candidateReady) {
        uint64_t oldOwnedBytes = candidate->ownedBytes;
        release_scene_node(candidate);
        s->candidateScene.nodes[candidateIndex] = next;
        s->candidateScene.ownedBytes = s->candidateScene.ownedBytes - oldOwnedBytes + next.ownedBytes;
    }
    if (!entry) {
        entry = &s->textRunDeclarations[s->textRunDeclarationCount++];
        entry->nodeId = nodeId;
        entry->encoded = NULL;
    }
    free(entry->encoded);
    entry->encoded = copy;
    if (candidate && !candidateReady) candidate->candidateRunsPending = 1u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus stage_window_background_impl(
    uint64_t token, uint64_t projectionVersion, uint32_t mode, uint32_t colorScheme) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (mode > 1u || colorScheme > 2u || !projectionVersion)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    s->backgroundProjectionVersion = projectionVersion;
    s->backgroundMode = mode;
    s->backgroundColorScheme = colorScheme;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus window_background_snapshot_impl(
    uint64_t token, CjguiInternalRendererWindowBackgroundSnapshot *outSnapshot) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outSnapshot) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    memset(outSnapshot, 0, sizeof(*outSnapshot));
    outSnapshot->acceptedSceneVersion = s->sceneVersion;
    outSnapshot->frameIndex = s->frameIndex;
    outSnapshot->requestRevision = s->backgroundProjectionVersion;
    outSnapshot->requestedMode = s->backgroundMode;
    outSnapshot->backend = 0u;
    outSnapshot->actualMode = 0u;
    outSnapshot->fallbackReason = s->backgroundMode ? 3u : 1u;
    outSnapshot->completion = s->backgroundMode ? 2u : 1u;
    outSnapshot->windowActive = GetForegroundWindow() == s->hwnd ? 1u : 0u;
    outSnapshot->colorScheme = s->backgroundColorScheme;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus composable_viewport_impl(
    uint64_t token, CjguiInternalRendererViewport *outViewport) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outViewport) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    double scale = (double)(s->dpi ? s->dpi : 96u) / 96.0;
    outViewport->width = (uint32_t)floor((double)s->width / scale);
    outViewport->height = (uint32_t)floor((double)s->height / scale);
    outViewport->resizeVersion = s->resizeVersion;
    outViewport->resourceCompletionVersion = 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus present_ticket_stats_impl(
    uint64_t token, CjguiInternalRendererPresentTicketStats *outStats) {
    if (!outStats) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    memset(outStats, 0, sizeof(*outStats));
    ensure_session_lock();
    EnterCriticalSection(&g_sessionLock);
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) { LeaveCriticalSection(&g_sessionLock); return CJGUI_INTERNAL_RENDERER_INVALID_SESSION; }
    outStats->nextTicketId = (int64_t)(s->presentationTicketNext + 1u);
    outStats->unackedTicketId = s->presentReceiptPublished ? (int64_t)s->presentReceipt.ticketId : 0;
    outStats->acceptedCount = (int64_t)s->presentTicketAcceptedCount;
    outStats->rejectedCount = (int64_t)s->presentTicketRejectedCount;
    outStats->queryCount = (int64_t)s->presentationQueryCount;
    outStats->ackCount = (int64_t)s->presentationAckCount;
    outStats->destroyRefusedCount = (int64_t)s->presentTicketDestroyRefusedCount;
    outStats->available = 1u;
    LeaveCriticalSection(&g_sessionLock);
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus acknowledge_present_impl(uint64_t token, uint64_t ticketId) {
    if (!ticketId) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ensure_session_lock();
    EnterCriticalSection(&g_sessionLock);
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus st = CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    if (!s) st = CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    else if (s->presentReceiptPublished && s->presentReceipt.ticketId == ticketId) {
        if (!s->presentReceipt.settled) st = CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
        else {
            memset(&s->presentReceipt, 0, sizeof(s->presentReceipt));
            s->presentReceiptPublished = 0u;
            s->presentLastAckedTicket = ticketId;
            ++s->presentationAckCount;
            st = CJGUI_INTERNAL_RENDERER_OK;
        }
    } else if (s->presentLastAckedTicket == ticketId) st = CJGUI_INTERNAL_RENDERER_OK;
    LeaveCriticalSection(&g_sessionLock);
    return st;
}

/* Called while holding g_sessionLock. A synchronous result stays private;
   only an exposed unknown result contributes to public ticket statistics. */
static void publish_present_receipt_locked(CjguiWindowsRendererSession *s) {
    if (s->presentReceiptPublished) return;
    s->presentReceiptPublished = 1u;
    if (s->presentReceipt.settled) {
        if (s->presentReceipt.decision == CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED)
            ++s->presentTicketAcceptedCount;
        else ++s->presentTicketRejectedCount;
    }
}


/* Device replacement is an explicit generation transition on the same UI
   thread/window. Document bytes, accepted bindings and DWrite geometry survive;
   GPU resources do not. No failed frame is promoted to accepted. */
static CjguiInternalRendererStatus recover_graphics(CjguiWindowsRendererSession *s,int controlled) {
    controlled=controlled || s->graphicsRecoveryControlled;
    if (controlled && s->context) {
        CjguiInternalRendererStatus drained=drain_text_flights(s,1000u);
        if (drained!=CJGUI_INTERNAL_RENDERER_OK) return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
    }
    s->graphicsRecoveryPending=1u;
    if (s->graphicsRecoveryAttempts>=3u) return CJGUI_INTERNAL_RENDERER_METAL_DEVICE_UNAVAILABLE;
    ++s->graphicsRecoveryAttempts;
    windows_cancel_mouse_on_coordinate_change(s);
    s->coordinateEpoch=next_positive_counter(&g_nextCoordinateEpoch);
    if (s->context) { ID3D11DeviceContext_ClearState(s->context); ID3D11DeviceContext_Flush(s->context); }
    for (uint32_t i=0;i<CJGUI_WINDOWS_TEXT_FLIGHT_CAPACITY;++i)
        release_text_flight_leases(s,&s->textFlights[i]);
    release_text_flight_queries(s);
    CjguiWindowsScene *scenes[2]={&s->acceptedScene,&s->candidateScene};
    for (uint32_t a=0;a<2;++a) for (uint32_t i=0;i<scenes[a]->count;++i)
        release_node_textures_only(&scenes[a]->nodes[i]);
    for (uint32_t i=0;i<CJGUI_WINDOWS_IMAGE_CACHE_CAPACITY;++i) {
        CjguiWindowsTextTextureLease *lease=s->images[i].lease;
        if (!lease) continue;
        if (lease->view) ID3D11ShaderResourceView_Release(lease->view);
        if (lease->texture) ID3D11Texture2D_Release(lease->texture);
        lease->view=NULL; lease->texture=NULL;
    }
    release_graphics(s);
    RECT rect;
    if (!s->hwnd || !GetClientRect(s->hwnd,&rect) || rect.right<=0 || rect.bottom<=0)
        return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
    CjguiInternalRendererStatus status=create_device_for_window(s,(uint32_t)rect.right,(uint32_t)rect.bottom);
    if (status!=CJGUI_INTERNAL_RENDERER_OK) return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
    for (uint32_t i=0;i<CJGUI_WINDOWS_IMAGE_CACHE_CAPACITY;++i) {
        CjguiWindowsTextTextureLease *lease=s->images[i].lease;
        if (lease && create_image_gpu(s,lease)!=CJGUI_INTERNAL_RENDERER_OK)
            return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
    }
    for (uint32_t a=0;a<2;++a) for (uint32_t i=0;i<scenes[a]->count;++i) {
        CjguiWindowsSceneNode *node=&scenes[a]->nodes[i];
        if (!windows_text_node_kind(node->node.nodeKind) || !node->textLayout) continue;
        const char *body=node->value ? node->value : "";
        if (node->node.nodeKind==CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON && node->label && node->label[0]) body=node->label;
        status=prepare_scene_node_raster(s,scenes[a],i,node);
        if (status!=CJGUI_INTERNAL_RENDERER_OK) return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
    }
    s->graphicsRecoveryPending=0u;s->graphicsRecoveryAttempts=0u;s->graphicsRecoveryControlled=0u;++s->deviceRecoveryCount;
    fprintf(stderr,"CJGUI_WINDOWS_DEVICE_RECOVERED token=%llu generation=%llu count=%llu hwnd=%p images=%llu\n",
        (unsigned long long)s->token,(unsigned long long)s->deviceGeneration,
        (unsigned long long)s->deviceRecoveryCount,(void*)s->hwnd,(unsigned long long)s->imageCountInUse);
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus prepare_candidate_pending_runs(
    CjguiWindowsRendererSession *s, uint32_t index) {
    CjguiWindowsSceneNode *candidate = &s->candidateScene.nodes[index];
    if (!candidate->candidateValueStaged && !candidate->candidateRetainedBindingValid)
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    if (!candidate->candidateRunsPending) return CJGUI_INTERNAL_RENDERER_OK;
    CjguiWindowsTextRunDeclaration *entry = text_runs_by_id(s, candidate->node.nodeId);
    if (!entry) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    const char *body = candidate->value ? candidate->value : "";
    if (candidate->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON &&
        candidate->label && candidate->label[0]) body = candidate->label;
    CjguiWindowsTextStyleRun *runs = NULL;
    uint32_t count = 0u;
    CjguiInternalRendererStatus status = parse_style_run_list(entry->encoded, body, &runs, &count);
    free(runs);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiWindowsSceneNode next;
    status = clone_scene_node(&next, candidate);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    uint64_t oldRunsBytes = strlen(next.textRuns ? next.textRuns : "");
    uint64_t newRunsBytes = 0u;
    char *copy = copy_valid_utf8(entry->encoded, CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY,
        &newRunsBytes, &status);
    if (!copy || status != CJGUI_INTERNAL_RENDERER_OK) {
        release_scene_node(&next);
        return status;
    }
    free(next.textRuns);
    next.textRuns = copy;
    next.ownedBytes = next.ownedBytes - oldRunsBytes + newRunsBytes;
    uint64_t otherBytes = s->candidateScene.ownedBytes - candidate->ownedBytes;
    if (otherBytes > CJGUI_WINDOWS_TEXT_BYTE_CAPACITY ||
        next.ownedBytes > CJGUI_WINDOWS_TEXT_BYTE_CAPACITY - otherBytes) {
        release_scene_node(&next);
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    }
    /* clone deliberately drops last-generation geometry eligibility. Here
       geometry was supplied to this candidate before Present, so retain it. */
    next.hasGeometry = candidate->hasGeometry;
    next.candidateValueStaged = candidate->candidateValueStaged;
    status = prepare_scene_node_text(s, &s->candidateScene, index, &next);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        release_scene_node(&next);
        return status;
    }
    next.candidateRunsPending = 0u;
    release_scene_node(candidate);
    *candidate = next;
    s->candidateScene.ownedBytes = otherBytes + next.ownedBytes;
    return CJGUI_INTERNAL_RENDERER_OK;
}


/* Geometry and color project the currently installed native choice. These
   helpers never create/finish a source install, write owner bytes, or move
   selection. They use the same body/layout/clip as the frame being drawn. */
static CjguiInternalRendererStatus windows_text_layout_units(const char*,uint64_t*,uint32_t*);
static CjguiWindowsSceneNode *windows_selection_paint_node(CjguiWindowsRendererSession *s,
    CjguiWindowsScene *scene) {
    if (!s || !s->hwnd || s->retiring || s->minimized || GetFocus()!=s->hwnd ||
        s->sourceInstallPending || s->pendingOwnedInputEventCount ||
        s->compositionState==WINDOWS_COMPOSITION_MARKED || !s->proxyValueUtf8) return NULL;
    CjguiWindowsSceneNode *n=scene_node_by_id(scene,s->focusedNodeId);
    if (!n || !n->hasGeometry || !n->layoutLease || !n->textLayout || n->textDpi!=s->dpi ||
        !n->node.isInteractive || n->node.isReadOnly ||
        n->node.resourceId!=s->focusedResourceId || n->node.nodeKind!=s->focusedNodeKind ||
        (n->node.nodeKind!=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT &&
         n->node.nodeKind!=CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT &&
         n->node.nodeKind!=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT)) return NULL;
    if (s->ownedTextSessionEnabled && (n->node.nodeId!=s->ownedTextSessionNodeId ||
        n->node.resourceId!=s->ownedTextSessionResourceId ||
        n->node.nodeKind!=s->ownedTextSessionNodeKind || !s->ownedTextSessionBindingEpoch)) return NULL;
    return n;
}
static uint64_t windows_selection_paint_key(CjguiWindowsRendererSession *s,
    CjguiWindowsScene *scene) {
    CjguiWindowsSceneNode *n=windows_selection_paint_node(s,scene);
    if (!n) return 0;
    uint64_t ids[]={s->sessionGeneration,n->node.nodeId,(uint64_t)n->node.resourceId,
        n->node.nodeKind,n->layoutLease,n->textLayoutInputKey,s->dpi,
        s->selectionStart16,s->selectionEnd16,s->ownedTextSessionBindingEpoch,
        s->rangeProxyGeneration,s->rangeSelectionRevision,(uint64_t)s->rangeOwnerVersion};
    double geometry[]={n->node.x,n->node.y,n->node.width,n->node.height,
        n->geometry.translateX,n->geometry.translateY,n->node.clipX,n->node.clipY,
        n->node.clipWidth,n->node.clipHeight,n->textLogicalOffsetX,n->multilineScrollY};
    uint64_t key=windows_fnv1a64(1469598103934665603ull,ids,sizeof(ids));
    key=windows_fnv1a64(key,geometry,sizeof(geometry));
    if (!key) key=1;
    /* A paint key is bookkeeping, never a substitute for full proxy bytes. */
    if (strcmp((const char*)s->proxyValueUtf8,n->value?n->value:"")!=0) return 0;
    return key;
}
static void update_windows_selection_paint(CjguiWindowsRendererSession *s,
    CjguiWindowsScene *scene) {
    uint64_t key=windows_selection_paint_key(s,scene);
    uint64_t now=cjgui_internal_renderer_owner_clock_ns();
    if (key!=s->selectionPaintDesiredKey) {
        s->selectionPaintDesiredKey=key;s->selectionPaintStartedNs=now;
    }
    s->selectionPaintVisible=key!=0;
    UINT blink=GetCaretBlinkTime();
    if (key && s->selectionStart16==s->selectionEnd16 && blink && blink!=INFINITE) {
        uint64_t elapsed=now>=s->selectionPaintStartedNs?now-s->selectionPaintStartedNs:0;
        s->selectionPaintVisible=((elapsed/((uint64_t)blink*1000000ull))&1u)==0u;
    }
}
static CjguiInternalRendererStatus draw_windows_selection_paint(CjguiWindowsRendererSession *s,
    CjguiWindowsSceneNode *n,FLOAT scale,FLOAT opacity,int caret) {
    if (!s->selectionPaintDesiredKey || !s->selectionPaintVisible ||
        n->node.nodeId!=s->focusedNodeId || !n->textLayout) return CJGUI_INTERNAL_RENDERER_OK;
    uint32_t a=s->selectionStart16,z=s->selectionEnd16;
    if (z<a) { uint32_t t=a;a=z;z=t; }
    if ((a==z)!=!!caret) return CJGUI_INTERNAL_RENDERER_OK;
    uint64_t bytes=0;uint32_t units=0;
    CjguiInternalRendererStatus st=windows_text_layout_units(n->value?n->value:"",&bytes,&units);
    if (st!=CJGUI_INTERNAL_RENDERER_OK || z>units) return CJGUI_INTERNAL_RENDERER_OK;
    FLOAT x=(FLOAT)(n->node.x+n->geometry.translateX+n->textLogicalOffsetX);
    FLOAT y=(FLOAT)(n->node.y+n->geometry.translateY-n->multilineScrollY);
    if (caret) {
        FLOAT localX=0,localY=0;DWRITE_HIT_TEST_METRICS hit={0};
        HRESULT hr=IDWriteTextLayout_HitTestTextPosition(n->textLayout,a,FALSE,&localX,&localY,&hit);
        if (FAILED(hr)) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        FLOAT color[4]={(FLOAT)n->node.textRed,(FLOAT)n->node.textGreen,
            (FLOAT)n->node.textBlue,(FLOAT)n->node.textAlpha*opacity};
        return draw_scene_quad(s,(x+localX)*scale,(y+localY)*scale,scale,
            (hit.height>0?hit.height:(FLOAT)(n->node.fontSize*1.25))*scale,color,NULL);
    }
    DWRITE_HIT_TEST_METRICS local[32],*rects=local;UINT32 count=0;
    HRESULT hr=IDWriteTextLayout_HitTestTextRange(n->textLayout,a,z-a,x,y,local,32,&count);
    uint64_t scratch=0;
    if (hr==HRESULT_FROM_WIN32(ERROR_INSUFFICIENT_BUFFER)) {
        if (!count || count>units+1u) return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
        scratch=(uint64_t)count*sizeof(*rects);
        if (!text_budget_reserve_scratch(s,scratch)) return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
        rects=(DWRITE_HIT_TEST_METRICS*)malloc((size_t)scratch);
        if (!rects) { text_budget_release_scratch(s,scratch);return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR; }
        UINT32 capacity=count;
        hr=IDWriteTextLayout_HitTestTextRange(n->textLayout,a,z-a,x,y,rects,capacity,&count);
        if (count>capacity) hr=HRESULT_FROM_WIN32(ERROR_INSUFFICIENT_BUFFER);
    }
    st=FAILED(hr)?CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR:CJGUI_INTERNAL_RENDERER_OK;
    FLOAT color[4]={0.15f,0.45f,0.9f,0.28f*opacity};
    for (UINT32 i=0;i<count&&st==CJGUI_INTERNAL_RENDERER_OK;i++) {
        DWRITE_HIT_TEST_METRICS *r=&rects[i];
        if (r->width>0&&r->height>0) st=draw_scene_quad(s,r->left*scale,r->top*scale,
            r->width*scale,r->height*scale,color,NULL);
    }
    if (scratch) { free(rects);text_budget_release_scratch(s,scratch); }
    return st;
}
static CjguiInternalRendererStatus draw_windows_scene(CjguiWindowsRendererSession *s,
    CjguiWindowsScene *scene) {
    update_windows_selection_paint(s,scene);
    if (!s->sceneVertexShader || !s->sceneInputLayout || !s->renderTarget)
        return CJGUI_INTERNAL_RENDERER_METAL_LAYER_UNAVAILABLE;
    CjguiWindowsTextFlight *flight = NULL;
    CjguiInternalRendererStatus status = begin_text_flight(s, scene, &flight);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    ID3D11DeviceContext_OMSetRenderTargets(s->context, 1, &s->renderTarget, NULL);
    D3D11_VIEWPORT viewport = {0.0f, 0.0f, (FLOAT)s->width, (FLOAT)s->height, 0.0f, 1.0f};
    ID3D11DeviceContext_RSSetViewports(s->context, 1, &viewport);
    FLOAT clear[4] = {(FLOAT)s->clearRed, (FLOAT)s->clearGreen,
        (FLOAT)s->clearBlue, (FLOAT)s->clearAlpha};
    ID3D11DeviceContext_ClearRenderTargetView(s->context, s->renderTarget, clear);
    bind_scene_pipeline(s);
    FLOAT scale = (FLOAT)(s->dpi ? s->dpi : 96u) / 96.0f;
    status = CJGUI_INTERNAL_RENDERER_OK;
    for (uint32_t i = 0; i < scene->count && status == CJGUI_INTERNAL_RENDERER_OK; ++i) {
        CjguiWindowsSceneNode *entry = &scene->nodes[i];
        CjguiInternalRendererComposableNode *node = &entry->node;
        FLOAT x = ((FLOAT)node->x + (FLOAT)entry->geometry.translateX) * scale;
        FLOAT y = ((FLOAT)node->y + (FLOAT)entry->geometry.translateY) * scale;
        FLOAT width = (FLOAT)node->width * scale;
        FLOAT height = (FLOAT)node->height * scale;
        LONG clipLeft = (LONG)floor((double)node->clipX * scale);
        LONG clipTop = (LONG)floor((double)node->clipY * scale);
        LONG clipRight = node->clipWidth > 0
            ? (LONG)ceil((double)(node->clipX + node->clipWidth) * scale) : (LONG)s->width;
        LONG clipBottom = node->clipHeight > 0
            ? (LONG)ceil((double)(node->clipY + node->clipHeight) * scale) : (LONG)s->height;
        if (clipLeft < 0) clipLeft = 0;
        if (clipTop < 0) clipTop = 0;
        if (clipRight > (LONG)s->width) clipRight = (LONG)s->width;
        if (clipBottom > (LONG)s->height) clipBottom = (LONG)s->height;
        if (clipRight <= clipLeft || clipBottom <= clipTop) continue;
        D3D11_RECT scissor = {clipLeft, clipTop, clipRight, clipBottom};
        ID3D11DeviceContext_RSSetScissorRects(s->context, 1, &scissor);
        FLOAT opacity = (FLOAT)node->effectGroupOpacity;
        if (!(opacity > 0.0f && opacity <= 1.0f)) opacity = 1.0f;
        if (node->fillAlpha > 0.0) {
            FLOAT fill[4] = {(FLOAT)node->fillRed, (FLOAT)node->fillGreen,
                (FLOAT)node->fillBlue, (FLOAT)node->fillAlpha * opacity};
            status = draw_scene_quad(s, x, y, width, height, fill, NULL);
        }
        FLOAT borderWidth = (FLOAT)node->borderWidth * scale;
        if (status == CJGUI_INTERNAL_RENDERER_OK && borderWidth > 0.0f && node->borderAlpha > 0.0) {
            FLOAT border[4] = {(FLOAT)node->borderRed, (FLOAT)node->borderGreen,
                (FLOAT)node->borderBlue, (FLOAT)node->borderAlpha * opacity};
            if (borderWidth > width) borderWidth = width;
            if (borderWidth > height) borderWidth = height;
            status = draw_scene_quad(s, x, y, width, borderWidth, border, NULL);
            if (status == CJGUI_INTERNAL_RENDERER_OK && height > borderWidth)
                status = draw_scene_quad(s, x, y + height - borderWidth, width, borderWidth, border, NULL);
            if (status == CJGUI_INTERNAL_RENDERER_OK && height > 2.0f * borderWidth)
                status = draw_scene_quad(s, x, y + borderWidth, borderWidth,
                    height - 2.0f * borderWidth, border, NULL);
            if (status == CJGUI_INTERNAL_RENDERER_OK && height > 2.0f * borderWidth && width > borderWidth)
                status = draw_scene_quad(s, x + width - borderWidth, y + borderWidth,
                    borderWidth, height - 2.0f * borderWidth, border, NULL);
        }
        if (status == CJGUI_INTERNAL_RENDERER_OK && entry->imageLease && entry->imageLease->view) {
            FLOAT ink[4]={1.0f,1.0f,1.0f,opacity};
            status=draw_scene_quad(s,x,y,width,height,ink,entry->imageLease->view);
        }
        if (node->nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) {
            scissor.left = (LONG)fmax(scissor.left, floor(x));
            scissor.top = (LONG)fmax(scissor.top, floor(y));
            scissor.right = (LONG)fmin(scissor.right, ceil(x + width));
            scissor.bottom = (LONG)fmin(scissor.bottom, ceil(y + height));
            if (scissor.right <= scissor.left || scissor.bottom <= scissor.top) continue;
            ID3D11DeviceContext_RSSetScissorRects(s->context, 1, &scissor);
        }
        if (status == CJGUI_INTERNAL_RENDERER_OK) {
            status=draw_windows_selection_paint(s,entry,scale,opacity,0);
        }
        if (status == CJGUI_INTERNAL_RENDERER_OK && entry->labelTextView &&
            node->textAlpha > 0.0 && entry->labelTextureWidth && entry->labelTextureHeight) {
            FLOAT ink[4] = {1.0f, 1.0f, 1.0f, opacity};
            status = draw_scene_quad(s, x + (FLOAT)entry->labelRasterRect.x * scale,
                y + (FLOAT)entry->labelRasterRect.y * scale,
                (FLOAT)entry->labelTextureWidth, (FLOAT)entry->labelTextureHeight, ink, entry->labelTextView);
        }
        if (status == CJGUI_INTERNAL_RENDERER_OK && entry->textView &&
            node->textAlpha > 0.0 && entry->textTextureWidth && entry->textTextureHeight) {
            FLOAT ink[4] = {1.0f, 1.0f, 1.0f, opacity};
            status = draw_scene_quad(s, x + (FLOAT)(entry->textLogicalOffsetX + entry->textRasterRect.x) * scale,
                y + (FLOAT)(entry->textRasterRect.y - entry->multilineScrollY) * scale,
                (FLOAT)entry->textTextureWidth, (FLOAT)entry->textTextureHeight, ink, entry->textView);
        }
        if (status == CJGUI_INTERNAL_RENDERER_OK) {
            status=draw_windows_selection_paint(s,entry,scale,opacity,1);
        }
    }
    end_text_flight(s, flight);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    return CJGUI_INTERNAL_RENDERER_OK;
}
static CjguiInternalRendererStatus present_composable_scene_impl(
    uint64_t token, CjguiInternalRendererFrameObservation *outObservation) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outObservation || !s->candidateScene.configured)
        return CJGUI_INTERNAL_RENDERER_SCENE_NOT_STAGED;
    if (s->graphicsRecoveryPending) {
        request_windows_graphics_recovery(s,0);
        return CJGUI_INTERNAL_RENDERER_METAL_DEVICE_UNAVAILABLE;
    }
    memset(outObservation, 0, sizeof(*outObservation));
    for (uint32_t i = 0; i < s->candidateScene.count; ++i) {
        CjguiWindowsSceneNode *node = &s->candidateScene.nodes[i];
        if (!node->hasNode || !node->hasGeometry ||
            node->node.projectionVersion != s->candidateScene.version ||
            node->geometry.nodeId != node->node.nodeId ||
            node->geometry.clipCount != node->node.clipConstraintCount)
            return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
        CjguiInternalRendererStatus prepared = prepare_candidate_pending_runs(s, i);
        if (prepared != CJGUI_INTERNAL_RENDERER_OK) return windows_unsubmitted_present_status(s,prepared);
        prepared = prepare_scene_node_raster(s, &s->candidateScene, i, node);
        if (prepared != CJGUI_INTERNAL_RENDERER_OK) return windows_unsubmitted_present_status(s,prepared);
        if (windows_text_node_kind(node->node.nodeKind) &&
            (!node->textLayout || node->textDpi != s->dpi))
            return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    uint64_t drawAt=s->traceEnabled?cjgui_internal_renderer_owner_clock_ns():0;
    CjguiInternalRendererStatus status=draw_windows_scene(s,&s->candidateScene);
    windows_trace(s,"draw",s->candidateScene.count,s->candidateScene.ownedBytes,
        s->traceEnabled?cjgui_internal_renderer_owner_clock_ns()-drawAt:0,status,0,0);
    if (status!=CJGUI_INTERNAL_RENDERER_OK) return windows_unsubmitted_present_status(s,status);
    FLOAT scale=(FLOAT)(s->dpi?s->dpi:96u)/96.0f;
    if (s->frameIndex == 0u) {
        uint64_t nonClearPixels = 0u, darkPixels = 0u;
        status = readback_scene_pixel_counts(s, &nonClearPixels, &darkPixels);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
        s->sceneReadbackNonClearPixelCount = nonClearPixels;
        s->sceneReadbackDarkPixelCount = darkPixels;
    }
    int controlled=s->controlledDeviceFault!=0u;
    s->controlledDeviceFault=0u;
    uint64_t presentAt=s->traceEnabled?cjgui_internal_renderer_owner_clock_ns():0;
    HRESULT hr = controlled ? DXGI_ERROR_DEVICE_RESET : IDXGISwapChain_Present(s->swapChain, 1, 0);
    windows_trace(s,"present",s->candidateScene.count,s->candidateScene.ownedBytes,
        s->traceEnabled?cjgui_internal_renderer_owner_clock_ns()-presentAt:0,(uint32_t)hr,
        s->deviceGeneration,controlled);
    if (FAILED(hr)) {
        s->lastGraphicsFailure = hr;
        ++s->presentationRejectedCount;
        if (windows_hresult_is_device_lost(hr)) {
            request_windows_graphics_recovery(s,controlled);
            return CJGUI_INTERNAL_RENDERER_METAL_DEVICE_UNAVAILABLE;
        }
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    release_scene(&s->acceptedScene);
    s->acceptedScene = s->candidateScene;
    memset(&s->candidateScene, 0, sizeof(s->candidateScene));
    s->sceneVersion = s->acceptedScene.version;
    ++s->frameIndex;
    ++s->presentationAcceptedCount;
    s->selectionPaintPresentedKey=s->selectionPaintDesiredKey;
    s->selectionPaintPresentedVisible=s->selectionPaintVisible;
    s->selectionPaintHasPresentation=1;
    synchronize_owned_proxy_after_presentation(s);
    finish_windows_composition_after_presentation(s);
    outObservation->frameIndex = s->frameIndex;
    outObservation->drawableWidthPixels = s->width;
    outObservation->drawableHeightPixels = s->height;
    outObservation->contentsScale = scale;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus prepare_composable_image_resource_impl(
    uint64_t token, const char *resourcePath, const char *resourceId,
    uint64_t resourceVersion, uint32_t *outState) {
    CjguiWindowsRendererSession *s=find_session(token);
    if (require_session(s)!=CJGUI_INTERNAL_RENDERER_OK) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!outState) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsImageResource *image=NULL;
    CjguiInternalRendererStatus status=prepare_image(s,resourcePath,resourceId,resourceVersion,NULL,0,&image);
    *outState=status==CJGUI_INTERNAL_RENDERER_OK ? 2u : 3u;
    return status;
}

static CjguiInternalRendererStatus composable_image_resource_state_impl(
    uint64_t token, const char *resourcePath, const char *resourceId,
    uint64_t resourceVersion, uint32_t *outState) {
    CjguiWindowsRendererSession *s=find_session(token);
    if (require_session(s)!=CJGUI_INTERNAL_RENDERER_OK) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!outState) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outState=find_image_resource(s,resourcePath,resourceId,resourceVersion) ? 2u : 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus pop_event(CjguiWindowsRendererSession *s,
    CjguiInternalRendererEvent *outEvent) {
    if (s->eventCount == 0) return CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY;
    uint32_t slot = s->eventHead;
    *outEvent = s->events[slot];
    s->lastPointerGeometry = s->pointerGeometries[slot];
    uint64_t pointerSessionGeneration = s->pointerSessionGenerations[slot];
    uint64_t pointerCoordinateEpoch = s->pointerCoordinateEpochs[slot];
    memset(&s->pointerGeometries[slot], 0, sizeof(s->pointerGeometries[slot]));
    if (s->lastPointerGeometry.present &&
        s->lastPointerGeometry.kind == outEvent->kind &&
        s->lastPointerGeometry.nodeId == outEvent->nodeId &&
        s->lastPointerGeometry.projectionVersion == outEvent->projectionVersion &&
        pointerSessionGeneration == s->sessionGeneration && pointerCoordinateEpoch != 0u) {
        s->lastPumpedSessionGeneration = pointerSessionGeneration;
        s->lastPumpedCoordinateEpoch = pointerCoordinateEpoch;
    } else {
        s->lastPumpedSessionGeneration = 0u;
        s->lastPumpedCoordinateEpoch = 0u;
    }
    s->pointerSessionGenerations[slot] = 0u;
    s->pointerCoordinateEpochs[slot] = 0u;
    free(s->formEventText);
    s->formEventText = s->eventTextPayloads[slot];
    if (s->eventTextBytes >= s->eventTextLengths[slot])
        s->eventTextBytes -= s->eventTextLengths[slot];
    else
        s->eventTextBytes = 0u;
    s->eventTextPayloads[slot] = NULL;
    s->eventTextLengths[slot] = 0u;
    s->eventHead = (s->eventHead + 1u) % CJGUI_WINDOWS_EVENT_CAPACITY;
    s->eventCount -= 1u;
    if (s->eventQueueFull) {
        s->eventQueueFull = 0;
        CjguiInternalRendererEvent full;
        memset(&full, 0, sizeof(full));
        full.kind = CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_INPUT_QUEUE_FULL;
        full.resourceId = -1;
        full.gesturePointerId = -1;
        full.replacementStart16 = -1;
        full.markedStart16 = -1;
        full.projectionVersion = s->sceneVersion;
        (void)push_event(s, &full);
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

static void initialize_empty_event(CjguiInternalRendererEvent *event) {
    memset(event, 0, sizeof(*event));
    event->resourceId = -1;
    event->gesturePointerId = -1;
    event->replacementStart16 = -1;
    event->markedStart16 = -1;
}


/* On the existing bounded UI pump, repaint only a changed native choice or
   blink phase. Accepted projection/selection and any candidate stay intact. */
static CjguiInternalRendererStatus refresh_windows_selection_paint(CjguiWindowsRendererSession *s) {
    if (!s || !s->acceptedScene.configured || s->retiring || s->minimized ||
        s->graphicsRecoveryPending || !s->renderTarget) return CJGUI_INTERNAL_RENDERER_OK;
    update_windows_selection_paint(s,&s->acceptedScene);
    if (!s->multilineViewportPaintPending && (!s->selectionPaintHasPresentation ||
        (s->selectionPaintDesiredKey==s->selectionPaintPresentedKey &&
         s->selectionPaintVisible==s->selectionPaintPresentedVisible))) return CJGUI_INTERNAL_RENDERER_OK;
    CjguiInternalRendererStatus st=draw_windows_scene(s,&s->acceptedScene);
    if (st!=CJGUI_INTERNAL_RENDERER_OK) return st;
    HRESULT hr=IDXGISwapChain_Present(s->swapChain,1,0);
    if (FAILED(hr)) {
        s->lastGraphicsFailure=hr;++s->presentationRejectedCount;
        if (windows_hresult_is_device_lost(hr)) {
            (void)recover_graphics(s,0);return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
        }
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    ++s->frameIndex;++s->presentationAcceptedCount;
    s->multilineViewportPaintPending=0u;
    s->selectionPaintPresentedKey=s->selectionPaintDesiredKey;
    s->selectionPaintPresentedVisible=s->selectionPaintVisible;
    return CJGUI_INTERNAL_RENDERER_OK;
}
static CjguiInternalRendererStatus pump_windows_messages(
    CjguiWindowsRendererSession *s, uint32_t timeoutMs,
    CjguiInternalRendererEvent *outEvent, uint64_t *outIdleWaitNs) {
    /* 驱动线程（任意 OS 线程）：先把原始输入环排空为 CJGUI 事件，再取首个；
       空且有预算时在唤醒事件上等待（UI 线程每条原始输入都会 signal）。
       零超时表示不等待，但已就绪的原始输入仍被搬运（与旧语义一致且更公平）。 */
    if (!outEvent) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    initialize_empty_event(outEvent);
    if (outIdleWaitNs) *outIdleWaitNs = 0;
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!s->hwnd) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    s->lastPumpTid = GetCurrentThreadId();
    start_pending_ime_successor(s);
    if (timeoutMs > 16u) timeoutMs = 16u;
    uint64_t started = cjgui_internal_renderer_owner_clock_ns();
    uint32_t remaining = timeoutMs;
    for (;;) {
        uint32_t message = 0u;
        uint64_t wParam = 0u;
        int64_t lParam = 0;
        int64_t frozenModifiers = 0;
        int64_t imeSlot = -1;
        while (raw_ring_pop(s, &message, &wParam, &lParam, &frozenModifiers,
            &imeSlot)) {
            dispatch_raw_message(s, message, wParam, lParam, frozenModifiers,
                imeSlot);
        }
        /* ResizeBuffers can lose the device before the app begins staging its
           next scene. Resolve that obligation on this same UI thread before
           returning the resize/input event; scene setters cannot prepare on
           an invalid device. Recovery itself retains the accepted authority. */
        if (s->graphicsRecoveryPending) (void)recover_graphics(s, 0);
        retry_kept_ime_frozen(s);
        CjguiInternalRendererStatus paint=refresh_windows_selection_paint(s);
        if (paint!=CJGUI_INTERNAL_RENDERER_OK && paint!=CJGUI_INTERNAL_RENDERER_PRESENT_PENDING) return paint;
        CjguiInternalRendererStatus popped = pop_event(s, outEvent);
        if (popped == CJGUI_INTERNAL_RENDERER_OK) return popped;
        if (remaining == 0u) return CJGUI_INTERNAL_RENDERER_OK;
        HANDLE waitHandles[2] = { s->rawWakeEvent, s->cmdWakeEvent };
        DWORD waited = MsgWaitForMultipleObjectsEx(2, waitHandles, remaining,
            QS_ALLINPUT, MWMO_INPUTAVAILABLE);
        if (waited == WAIT_FAILED) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        if (WaitForSingleObject(s->pumpStopEvent, 0) == WAIT_OBJECT_0) {
            return CJGUI_INTERNAL_RENDERER_OK;
        }
        MSG drained;
        while (PeekMessageW(&drained, NULL, 0, 0, PM_REMOVE)) {
            if (drained.message == WM_QUIT) {
                raw_ring_push(s, (uint32_t)WM_QUIT, 0u, 0, 0);
                continue;
            }
            TranslateMessage(&drained);
            DispatchMessageW(&drained);
        }
        drain_dispatcher_commands(s, 1);
        if (outIdleWaitNs) {
            uint64_t now = cjgui_internal_renderer_owner_clock_ns();
            *outIdleWaitNs = now >= started ? now - started : 0u;
        }
        uint64_t now = cjgui_internal_renderer_owner_clock_ns();
        uint64_t spentMs = now >= started ? (now - started) / 1000000ull : 0ull;
        uint32_t nextRemaining = spentMs >= (uint64_t)timeoutMs ? 0u
            : (uint32_t)((uint64_t)timeoutMs - spentMs);
        if (nextRemaining == 0u) {
            /* 截止前再看一次，避免唤醒与排空间隙丢事件。 */
            int64_t deadlineFrozen = 0;
            int64_t deadlineIme = -1;
            while (raw_ring_pop(s, &message, &wParam, &lParam, &deadlineFrozen,
                &deadlineIme)) {
                dispatch_raw_message(s, message, wParam, lParam,
                    deadlineFrozen, deadlineIme);
            }
            retry_kept_ime_frozen(s);
            popped = pop_event(s, outEvent);
            if (popped == CJGUI_INTERNAL_RENDERER_OK) return popped;
            return CJGUI_INTERNAL_RENDERER_OK;
        }
        remaining = nextRemaining;
    }
}


static CjguiInternalRendererStatus finish_source_install_impl(uint64_t token,
    uint64_t requestId, uint32_t outcome, uint64_t receiptNonce);

static CjguiInternalRendererStatus set_source_install_gate_impl(
    uint64_t token, uint64_t bindingEpoch, uint64_t requestId, uint8_t pending) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (pending > 1u) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (pending) {
        if (bindingEpoch == 0u || requestId == 0u)
            return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
        if (s->sourceInstallPending &&
            (s->sourceInstallBindingEpoch != bindingEpoch ||
             s->sourceInstallRequestId != requestId)) {
            CjguiInternalRendererStatus settled = finish_source_install_impl(token,
                s->sourceInstallRequestId, CJGUI_WINDOWS_FINISH_SUPERSEDED, 0u);
            if (settled != CJGUI_INTERNAL_RENDERER_OK) return settled;
        } else {
            s->sourceInstallOutcome = CJGUI_WINDOWS_INSTALL_OUTCOME_NONE;
        }
        s->sourceInstallBindingEpoch = bindingEpoch;
        s->sourceInstallRequestId = requestId;
        s->sourceInstallPending = 1u;
        s->sourceInstallProvisional = 0u;
        /* 新门 armed 不得重放导航屏障：屏障只由其导航裁决后的新安装确认
           释放（或取消类结算具名回收）；此处提前重放会把持留输入投到
           尚未安装的新选区之前。超期屏障随下一次确认或销毁闭合。 */
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    if (!s->sourceInstallPending) return CJGUI_INTERNAL_RENDERER_OK;
    if (s->sourceInstallBindingEpoch != bindingEpoch || s->sourceInstallRequestId != requestId)
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    return finish_source_install_impl(token, requestId,
        s->sourceInstallProvisional ? CJGUI_WINDOWS_FINISH_CONFIRMED :
        CJGUI_WINDOWS_FINISH_CANCELLED, s->sourceInstallProvisionalNonce);
}

static CjguiInternalRendererStatus diagnostic_resources_impl(
    uint64_t token, CjguiInternalRendererDiagnosticResources *outResources) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outResources) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    memset(outResources, 0, sizeof(*outResources));
    outResources->sceneVersion = s->sceneVersion;
    outResources->frameIndex = s->frameIndex;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus diagnostic_timing_impl(
    uint64_t token, CjguiInternalRendererDiagnosticTiming *outTiming) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outTiming) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    memset(outTiming, 0, sizeof(*outTiming));
    LARGE_INTEGER frequency;
    outTiming->sceneVersion = s->sceneVersion;
    outTiming->frameIndex = s->frameIndex;
    outTiming->enabled = s->diagnosticTimingEnabled;
    outTiming->clockAvailable = QueryPerformanceFrequency(&frequency) && frequency.QuadPart > 0;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus node_rect_impl(uint64_t token,
    uint64_t nodeId, int64_t *outX, int64_t *outY, int64_t *outWidth, int64_t *outHeight) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (outX) *outX = 0;
    if (outY) *outY = 0;
    if (outWidth) *outWidth = 0;
    if (outHeight) *outHeight = 0;
    CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, nodeId);
    if (!node) return CJGUI_INTERNAL_RENDERER_SCENE_NOT_STAGED;
    if (outX) *outX = node->node.x;
    if (outY) *outY = node->node.y;
    if (outWidth) *outWidth = node->node.width;
    if (outHeight) *outHeight = node->node.height;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus windows_validate_text_grapheme_boundary(
    const char *utf8, uint64_t length, uint64_t byteOffset, uint32_t *outUtf16) {
    if (!utf8 || !outUtf16 || byteOffset > length ||
        !utf8_offset_to_utf16(utf8, length, byteOffset, outUtf16))
        return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    if (!length) return byteOffset == 0u ? CJGUI_INTERNAL_RENDERER_OK
        : CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    uint64_t probe = byteOffset == length ? byteOffset - 1u : byteOffset;
    uint64_t start = 0u, end = 0u;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_grapheme_cluster_range(
        utf8, length, probe, &start, &end);
    if (status == CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED)
        return CJGUI_INTERNAL_RENDERER_VISUAL_NAV_UNSUPPORTED;
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    return (byteOffset == length ? end == length : start == byteOffset)
        ? CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
}

static CjguiInternalRendererStatus windows_accepted_text_node(
    CjguiWindowsRendererSession *s, uint64_t nodeId, uint64_t expectedSceneVersion,
    CjguiWindowsSceneNode **outNode) {
    if (!s || !outNode) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outNode = NULL;
    if (expectedSceneVersion && expectedSceneVersion != s->sceneVersion)
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    if (!s->acceptedScene.configured || !s->acceptedScene.count)
        return CJGUI_INTERNAL_RENDERER_SCENE_NOT_STAGED;
    CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, nodeId);
    if (!node) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    if (!node->textLayout || !node->layoutLease)
        return CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY;
    if (node->textDpi != s->dpi) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    *outNode = node;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static const char *windows_text_layout_value(const CjguiWindowsSceneNode *node) {
    if (!node) return "";
    if (node->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON &&
        node->label && node->label[0]) return node->label;
    return node->value ? node->value : "";
}

static CjguiInternalRendererStatus windows_text_layout_units(
    const char *utf8, uint64_t *outBytes, uint32_t *outUnits) {
    if (!utf8 || !outBytes || !outUnits) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint64_t bytes = strnlen(utf8, CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY + 1u);
    if (bytes > CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY)
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    int units = bytes ? MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
        utf8, (int)bytes, NULL, 0) : 0;
    if (bytes && units <= 0) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    *outBytes = bytes;
    *outUnits = (uint32_t)units;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus windows_get_line_metrics(
    CjguiWindowsRendererSession *s, IDWriteTextLayout *layout,
    DWRITE_LINE_METRICS **outLines, UINT32 *outCount, uint64_t *outReservedBytes) {
    if (!s || !layout || !outLines || !outCount || !outReservedBytes)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outLines = NULL; *outCount = 0u; *outReservedBytes = 0u;
    DWRITE_TEXT_METRICS metrics; memset(&metrics, 0, sizeof(metrics));
    HRESULT hr = IDWriteTextLayout_GetMetrics(layout, &metrics);
    if (FAILED(hr)) { s->lastGraphicsFailure = hr; return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR; }
    if (metrics.lineCount > 16384u)
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    if (!metrics.lineCount) return CJGUI_INTERNAL_RENDERER_OK;
    uint64_t bytes = (uint64_t)metrics.lineCount * sizeof(DWRITE_LINE_METRICS);
    if (!text_budget_reserve_scratch(s, bytes))
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    DWRITE_LINE_METRICS *lines = (DWRITE_LINE_METRICS *)calloc(metrics.lineCount, sizeof(*lines));
    if (!lines) {
        text_budget_release_scratch(s, bytes);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    UINT32 actual = 0u;
    hr = IDWriteTextLayout_GetLineMetrics(layout, lines, metrics.lineCount, &actual);
    if (FAILED(hr) || actual > metrics.lineCount) {
        free(lines);
        text_budget_release_scratch(s, bytes);
        s->lastGraphicsFailure = hr;
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    *outLines = lines;
    *outCount = actual;
    *outReservedBytes = bytes;
    ++s->textPositionLineMetricsCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static void windows_release_line_metrics(CjguiWindowsRendererSession *s,
    DWRITE_LINE_METRICS **lines, uint64_t reservedBytes) {
    if (lines && *lines) { free(*lines); *lines = NULL; }
    if (reservedBytes) text_budget_release_scratch(s, reservedBytes);
}

static UINT32 windows_line_for_top(const DWRITE_LINE_METRICS *lines, UINT32 count,
    FLOAT wantedTop, UINT32 *outStart, UINT32 *outLength) {
    UINT32 start = 0u, best = 0u, bestStart = 0u, bestLength = count ? lines[0].length : 0u;
    FLOAT top = 0.0f, bestDistance = FLT_MAX;
    for (UINT32 i = 0u; i < count; ++i) {
        FLOAT distance = fabsf(top - wantedTop);
        if (distance < bestDistance) {
            best = i; bestStart = start; bestLength = lines[i].length; bestDistance = distance;
        }
        start += lines[i].length;
        top += lines[i].height;
    }
    if (outStart) *outStart = bestStart;
    if (outLength) *outLength = bestLength;
    return best;
}

static int windows_previous_scalar_unit(const char *utf8, uint64_t byteOffset,
    uint32_t endUnit, uint32_t *outUnit) {
    if (!utf8 || !outUnit || !byteOffset || !endUnit) return 0;
    const uint8_t *bytes = (const uint8_t *)utf8;
    uint64_t start = byteOffset - 1u;
    while (start > 0u && (bytes[start] & 0xc0u) == 0x80u) --start;
    uint8_t lead = bytes[start];
    uint32_t units = (lead & 0xf8u) == 0xf0u ? 2u : 1u;
    if (endUnit < units) return 0;
    *outUnit = endUnit - units;
    return 1;
}

static uint64_t windows_position_stop_id(uint32_t unit, uint32_t side) {
    return ((uint64_t)unit << 2u) | ((uint64_t)(side & 1u) << 1u) | 1u;
}

static CjguiInternalRendererStatus windows_text_position_units(
    CjguiWindowsRendererSession *s, CjguiWindowsSceneNode *node, uint32_t units,
    uint32_t totalUnits, uint64_t byteLength, uint32_t side,
    DWRITE_HIT_TEST_METRICS *outHit, FLOAT *outX, FLOAT *outY) {
    if (!s || !node || !node->textLayout || !outHit || !outX || !outY || side > 1u ||
        units > totalUnits) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    memset(outHit, 0, sizeof(*outHit));
    *outX = 0.0f; *outY = 0.0f;
    if (totalUnits == 0u || byteLength == 0u) {
        DWRITE_TEXT_METRICS metrics; memset(&metrics, 0, sizeof(metrics));
        HRESULT hr = IDWriteTextLayout_GetMetrics(node->textLayout, &metrics);
        if (FAILED(hr)) { s->lastGraphicsFailure = hr; return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR; }
        outHit->textPosition = 0u; outHit->length = 0u; outHit->left = 0.0f;
        outHit->top = 0.0f; outHit->width = 1.0f; outHit->height = metrics.height;
        outHit->isText = TRUE;
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    const char *text = windows_text_layout_value(node);
    UINT32 position = units;
    BOOL trailing = FALSE;
    if (side == 0u && units > 0u) {
        if (!windows_previous_scalar_unit(text, byteLength, units, &position))
            return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
        trailing = TRUE;
    } else if (units >= totalUnits) {
        if (!windows_previous_scalar_unit(text, byteLength, totalUnits, &position))
            return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
        trailing = TRUE;
    }
    HRESULT hr = IDWriteTextLayout_HitTestTextPosition(node->textLayout, position,
        trailing, outX, outY, outHit);
    if (FAILED(hr)) { s->lastGraphicsFailure = hr; return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR; }
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus windows_position_from_units(
    CjguiWindowsRendererSession *s, CjguiWindowsSceneNode *node, uint32_t units,
    uint32_t totalUnits, uint64_t byteLength, uint32_t side, uint64_t *outMeta,
    double *outRect) {
    FLOAT localX = 0.0f, localY = 0.0f;
    DWRITE_HIT_TEST_METRICS hit; memset(&hit, 0, sizeof(hit));
    CjguiInternalRendererStatus status = windows_text_position_units(s, node, units,
        totalUnits, byteLength, side, &hit, &localX, &localY);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    DWRITE_LINE_METRICS *lines = NULL; UINT32 lineCount = 0u; uint64_t lineBytes = 0u;
    status = windows_get_line_metrics(s, node->textLayout, &lines, &lineCount, &lineBytes);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    UINT32 lineStart = 0u;
    (void)windows_line_for_top(lines, lineCount, hit.top, &lineStart, NULL);
    windows_release_line_metrics(s, &lines, lineBytes);
    if (outMeta) {
        memset(outMeta, 0, 8u * sizeof(uint64_t));
        outMeta[0] = node->layoutLease;
        outMeta[1] = windows_position_stop_id(units, side);
        uint64_t byte = 0u;
        if (!windows_utf8_offset_for_utf16(windows_text_layout_value(node), units, &byte) ||
            byte > UINT32_MAX) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
        outMeta[2] = byte;
        outMeta[3] = side;
        outMeta[4] = side;
        outMeta[5] = lineStart;
        outMeta[6] = units;
    }
    if (outRect) {
        memset(outRect, 0, 4u * sizeof(double));
        outRect[0] = (double)node->node.x + node->geometry.translateX +
            node->textLogicalOffsetX + localX;
        outRect[1] = (double)node->node.y + node->geometry.translateY - node->multilineScrollY + localY;
        outRect[2] = 1.0;
        outRect[3] = hit.height > 0.0f ? hit.height :
            (node->node.fontSize > 0.0 ? node->node.fontSize * 1.25 : 18.0);
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

/* A source input has no product-drawn caret declaration. Resolve its insertion
   point from the same accepted DWrite body and installed selection instead of
   leaving IMM32 at its default screen corner. This only positions system UI:
   it neither changes the selection nor authorizes an owner transaction. */
static void position_windows_system_composition(CjguiWindowsRendererSession *s) {
    if (!s || !s->hwnd || GetFocus() != s->hwnd || s->sourceInstallPending) return;
    CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, s->focusedNodeId);
    if (!node || node->node.resourceId != s->focusedResourceId ||
        node->node.nodeKind != s->focusedNodeKind || !node->textLayout ||
        !node->hasGeometry || !node->layoutLease) return;
    uint64_t bytes = 0u; uint32_t units = 0u;
    if (windows_text_layout_units(windows_text_layout_value(node), &bytes, &units) !=
        CJGUI_INTERNAL_RENDERER_OK || s->selectionStart16 > units) return;
    double rect[4] = {0};
    if (windows_position_from_units(s, node, s->selectionStart16, units, bytes,
        1u, NULL, rect) != CJGUI_INTERNAL_RENDERER_OK) return;
    HIMC context = ImmGetContext(s->hwnd);
    if (!context) return;
    double scale = (double)(s->dpi ? s->dpi : 96u) / 96.0;
    COMPOSITIONFORM composition; memset(&composition, 0, sizeof(composition));
    composition.dwStyle = CFS_POINT;
    composition.ptCurrentPos.x = (LONG)lround(rect[0] * scale);
    composition.ptCurrentPos.y = (LONG)lround(rect[1] * scale);
    (void)ImmSetCompositionWindow(context, &composition);
    CANDIDATEFORM candidate; memset(&candidate, 0, sizeof(candidate));
    candidate.dwStyle = CFS_CANDIDATEPOS;
    candidate.ptCurrentPos.x = composition.ptCurrentPos.x;
    candidate.ptCurrentPos.y = (LONG)lround((rect[1] + rect[3]) * scale);
    (void)ImmSetCandidateWindow(context, &candidate);
    ImmReleaseContext(s->hwnd, context);
}

static CjguiInternalRendererStatus windows_position_from_point(
    CjguiWindowsRendererSession *s, CjguiWindowsSceneNode *node, uint64_t byteLength,
    uint32_t totalUnits, double sceneX, double sceneY, uint64_t *outMeta, double *outRect) {
    if (!isfinite(sceneX) || !isfinite(sceneY)) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    FLOAT originX = (FLOAT)((double)node->node.x + node->geometry.translateX + node->textLogicalOffsetX);
    FLOAT originY = (FLOAT)((double)node->node.y + node->geometry.translateY - node->multilineScrollY);
    FLOAT localX = (FLOAT)(sceneX - originX), localY = (FLOAT)(sceneY - originY);
    BOOL trailing = FALSE, inside = FALSE;
    DWRITE_HIT_TEST_METRICS hit; memset(&hit, 0, sizeof(hit));
    HRESULT hr = IDWriteTextLayout_HitTestPoint(node->textLayout, localX, localY,
        &trailing, &inside, &hit);
    if (FAILED(hr)) { s->lastGraphicsFailure = hr; return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR; }
    (void)inside;
    uint64_t valueByteLength = 0u; uint32_t valueUnits = 0u;
    CjguiInternalRendererStatus status = windows_text_layout_units(
        windows_text_layout_value(node), &valueByteLength, &valueUnits);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    if (valueByteLength != byteLength || valueUnits != totalUnits)
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    uint64_t candidateUnits64 = (uint64_t)hit.textPosition + (trailing ? hit.length : 0u);
    if (candidateUnits64 > totalUnits) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    uint64_t candidateByte = 0u;
    if (!windows_utf8_offset_for_utf16(windows_text_layout_value(node),
        (uint32_t)candidateUnits64, &candidateByte)) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    uint32_t candidateUnits = 0u;
    uint32_t side = trailing ? 0u : 1u;
    status = windows_validate_text_grapheme_boundary(windows_text_layout_value(node),
        byteLength, candidateByte, &candidateUnits);
    if (status == CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID && byteLength) {
        uint64_t clusterStart = 0u, clusterEnd = 0u;
        uint64_t probe = candidateByte < byteLength ? candidateByte : byteLength - 1u;
        status = cjgui_internal_renderer_grapheme_cluster_range(
            windows_text_layout_value(node), byteLength, probe, &clusterStart, &clusterEnd);
        if (status == CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED)
            return CJGUI_INTERNAL_RENDERER_VISUAL_NAV_UNSUPPORTED;
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
        uint32_t startUnits = 0u, endUnits = 0u;
        if (!utf8_offset_to_utf16(windows_text_layout_value(node), byteLength,
            clusterStart, &startUnits) || !utf8_offset_to_utf16(windows_text_layout_value(node),
            byteLength, clusterEnd, &endUnits)) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
        uint64_t startMeta[8] = {0}, endMeta[8] = {0}; double startRect[4] = {0}, endRect[4] = {0};
        CjguiInternalRendererStatus a = windows_position_from_units(s, node, startUnits,
            totalUnits, byteLength, 1u, startMeta, startRect);
        CjguiInternalRendererStatus b = windows_position_from_units(s, node, endUnits,
            totalUnits, byteLength, 0u, endMeta, endRect);
        if (a != CJGUI_INTERNAL_RENDERER_OK || b != CJGUI_INTERNAL_RENDERER_OK)
            return a != CJGUI_INTERNAL_RENDERER_OK ? a : b;
        double startDistance = fabs(startRect[0] - sceneX) + 2.0 * fabs(startRect[1] - sceneY);
        double endDistance = fabs(endRect[0] - sceneX) + 2.0 * fabs(endRect[1] - sceneY);
        if (startDistance <= endDistance) {
            if (outMeta) memcpy(outMeta, startMeta, sizeof(startMeta));
            if (outRect) memcpy(outRect, startRect, sizeof(startRect));
            return CJGUI_INTERNAL_RENDERER_OK;
        }
        if (outMeta) memcpy(outMeta, endMeta, sizeof(endMeta));
        if (outRect) memcpy(outRect, endRect, sizeof(endRect));
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    return windows_position_from_units(s, node, candidateUnits, totalUnits,
        byteLength, side, outMeta, outRect);
}

static CjguiInternalRendererStatus text_position_v1_impl(
    uint64_t token, uint64_t nodeId, uint64_t expectedSceneVersion, uint32_t op,
    int64_t displayByte, uint32_t renderSide, uint64_t layoutLease, uint64_t stopId,
    uint32_t direction, double x, double y, uint64_t *meta, double *rect) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!meta || !rect) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    memset(meta, 0, 8u * sizeof(uint64_t));
    memset(rect, 0, 4u * sizeof(double));
    if (op > 3u || direction > 1u || renderSide > 2u || !isfinite(x) || !isfinite(y))
        return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    CjguiWindowsSceneNode *node = NULL;
    CjguiInternalRendererStatus status = windows_accepted_text_node(
        s, nodeId, expectedSceneVersion, &node);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    uint64_t byteLength = 0u; uint32_t totalUnits = 0u;
    status = windows_text_layout_units(windows_text_layout_value(node), &byteLength, &totalUnits);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    ++s->textPositionQueryCount;

    uint32_t resolvedSide = renderSide == 0u ? 0u : 1u;
    uint32_t units = 0u;
    if (op != 1u) {
        if (displayByte < 0) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
        status = windows_validate_text_grapheme_boundary(windows_text_layout_value(node),
            byteLength, (uint64_t)displayByte, &units);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
        if (layoutLease || stopId) {
            if (!layoutLease || !stopId || layoutLease != node->layoutLease ||
                (stopId & 1u) == 0u || (uint32_t)(stopId >> 2u) != units)
                return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
            resolvedSide = (uint32_t)((stopId >> 1u) & 1u);
        }
    }

    if (op == 0u)
        return windows_position_from_units(s, node, units, totalUnits, byteLength,
            resolvedSide, meta, rect);
    if (op == 1u)
        return windows_position_from_point(s, node, byteLength, totalUnits, x, y, meta, rect);

    FLOAT currentX = 0.0f, currentY = 0.0f;
    DWRITE_HIT_TEST_METRICS currentHit; memset(&currentHit, 0, sizeof(currentHit));
    status = windows_text_position_units(s, node, units, totalUnits, byteLength,
        resolvedSide, &currentHit, &currentX, &currentY);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;

    if (op == 2u) {
        if ((!direction && displayByte == 0) || (direction && (uint64_t)displayByte == byteLength)) {
            if (currentHit.bidiLevel & 1u) return CJGUI_INTERNAL_RENDERER_VISUAL_NAV_UNSUPPORTED;
            status = windows_position_from_units(s, node, units, totalUnits, byteLength,
                resolvedSide, meta, rect);
            if (status == CJGUI_INTERNAL_RENDERER_OK) meta[7] = 1u;
            return status;
        }
        uint64_t clusterStart = 0u, clusterEnd = 0u;
        uint64_t probe = direction ? (uint64_t)displayByte : (uint64_t)displayByte - 1u;
        status = cjgui_internal_renderer_grapheme_cluster_range(
            windows_text_layout_value(node), byteLength, probe, &clusterStart, &clusterEnd);
        if (status == CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED)
            return CJGUI_INTERNAL_RENDERER_VISUAL_NAV_UNSUPPORTED;
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
        uint64_t targetByte = direction ? clusterEnd : clusterStart;
        uint32_t targetUnits = 0u;
        status = windows_validate_text_grapheme_boundary(windows_text_layout_value(node),
            byteLength, targetByte, &targetUnits);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
        DWRITE_HIT_TEST_METRICS targetHit; memset(&targetHit, 0, sizeof(targetHit));
        FLOAT targetX = 0.0f, targetY = 0.0f;
        status = windows_text_position_units(s, node, targetUnits, totalUnits,
            byteLength, 1u, &targetHit, &targetX, &targetY);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
        if (fabsf(targetY - currentY) < 0.5f &&
            (direction ? targetX <= currentX + 0.01f : targetX >= currentX - 0.01f))
            return CJGUI_INTERNAL_RENDERER_VISUAL_NAV_UNSUPPORTED;
        return windows_position_from_units(s, node, targetUnits, totalUnits,
            byteLength, 1u, meta, rect);
    }

    DWRITE_LINE_METRICS *lines = NULL; UINT32 lineCount = 0u; uint64_t lineBytes = 0u;
    status = windows_get_line_metrics(s, node->textLayout, &lines, &lineCount, &lineBytes);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    if (!lineCount) {
        windows_release_line_metrics(s, &lines, lineBytes);
        return CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY;
    }
    UINT32 currentLine = windows_line_for_top(lines, lineCount, currentHit.top, NULL, NULL);
    if ((!direction && currentLine == 0u) ||
        (direction && currentLine + 1u >= lineCount)) {
        windows_release_line_metrics(s, &lines, lineBytes);
        status = windows_position_from_units(s, node, units, totalUnits, byteLength,
            resolvedSide, meta, rect);
        if (status == CJGUI_INTERNAL_RENDERER_OK) meta[7] = 1u;
        return status;
    }
    UINT32 targetLine = direction ? currentLine + 1u : currentLine - 1u;
    FLOAT targetTop = 0.0f;
    for (UINT32 i = 0u; i < targetLine; ++i) targetTop += lines[i].height;
    FLOAT targetY = targetTop + lines[targetLine].height * 0.5f;
    windows_release_line_metrics(s, &lines, lineBytes);
    double preferredX = x;
    if (preferredX == 0.0) {
        double currentRect[4] = {0}; uint64_t currentMeta[8] = {0};
        status = windows_position_from_units(s, node, units, totalUnits, byteLength,
            resolvedSide, currentMeta, currentRect);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
        preferredX = currentRect[0];
    }
    double targetSceneY = (double)node->node.y + node->geometry.translateY + targetY;
    return windows_position_from_point(s, node, byteLength, totalUnits,
        preferredX, targetSceneY, meta, rect);
}

static CjguiInternalRendererStatus text_position_stats_v1_impl(
    uint64_t token, uint64_t *counts) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!counts) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    counts[0] = s->textLayoutPreparationCount;
    counts[1] = s->textPositionQueryCount;
    counts[2] = s->textPositionLineMetricsCount;
    counts[3] = 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus text_geometry_caret_impl(
    uint64_t token, int64_t nodeId, int64_t displayByte, double caretWidthPt,
    uint64_t expectedSceneVersion, uint32_t affinity, double *outX, double *outY,
    double *outWidth, double *outHeight) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (outX) *outX = 0.0; if (outY) *outY = 0.0;
    if (outWidth) *outWidth = 0.0; if (outHeight) *outHeight = 0.0;
    if (!outX || !outY || !outWidth || !outHeight) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (affinity > 2u || !isfinite(caretWidthPt) || caretWidthPt < 0.0)
        return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    uint64_t meta[8] = {0}; double rect[4] = {0};
    CjguiInternalRendererStatus status = cjgui_internal_renderer_text_position_v1(token,
        (uint64_t)nodeId, expectedSceneVersion, 0u, displayByte, affinity,
        0u, 0u, 0u, 0.0, 0.0, meta, rect);
    if (status == CJGUI_INTERNAL_RENDERER_OK) {
        *outX = rect[0]; *outY = rect[1];
        *outWidth = caretWidthPt > 0.0 ? caretWidthPt : 1.0;
        *outHeight = rect[3];
    }
    return status;
}

static CjguiInternalRendererStatus text_visual_neighbor_impl(
    uint64_t token, uint64_t nodeId, int64_t displayByte, uint32_t left,
    uint64_t expectedSceneVersion, uint32_t caretAffinity,
    uint32_t *outNeighborByte, uint32_t *outAffinity) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outNeighborByte || !outAffinity) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint64_t meta[8] = {0}; double rect[4] = {0};
    CjguiInternalRendererStatus status = cjgui_internal_renderer_text_position_v1(token,
        nodeId, expectedSceneVersion, 2u, displayByte, caretAffinity, 0u, 0u,
        left ? 0u : 1u, 0.0, 0.0, meta, rect);
    if (status == CJGUI_INTERNAL_RENDERER_OK) {
        *outNeighborByte = (uint32_t)meta[2];
        *outAffinity = (uint32_t)meta[3];
    }
    return status;
}

static CjguiInternalRendererStatus query_present_impl(uint64_t token,
    uint64_t ticketId, CjguiInternalRendererPresentReceipt *outReceipt) {
    if (!outReceipt || !ticketId) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    memset(outReceipt, 0, sizeof(*outReceipt));
    outReceipt->ticketId = ticketId;
    ensure_session_lock();
    EnterCriticalSection(&g_sessionLock);
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) { LeaveCriticalSection(&g_sessionLock); return CJGUI_INTERNAL_RENDERER_INVALID_SESSION; }
    ++s->presentationQueryCount;
    if (s->presentReceiptPublished && s->presentReceipt.ticketId == ticketId)
        *outReceipt = s->presentReceipt;
    LeaveCriticalSection(&g_sessionLock);
    return CJGUI_INTERNAL_RENDERER_OK;
}

typedef struct CjguiWindowsIcuBreakApi {
    HMODULE module;
    void *(__cdecl *open)(int32_t, const char *, const WCHAR *, int32_t, int32_t *);
    void (__cdecl *close)(void *);
    int32_t (__cdecl *isBoundary)(void *, int32_t);
    int32_t (__cdecl *preceding)(void *, int32_t);
    int32_t (__cdecl *following)(void *, int32_t);
} CjguiWindowsIcuBreakApi;

static CjguiWindowsIcuBreakApi g_icuBreakApi;
static INIT_ONCE g_icuBreakOnce = INIT_ONCE_STATIC_INIT;

static FARPROC icu_export(HMODULE module, const char *baseName) {
    FARPROC symbol = GetProcAddress(module, baseName);
    if (symbol) return symbol;
    char versioned[48];
    for (unsigned version = 3u; version <= 99u; ++version) {
        (void)snprintf(versioned, sizeof(versioned), "%s_%u", baseName, version);
        symbol = GetProcAddress(module, versioned);
        if (symbol) return symbol;
    }
    return NULL;
}

static BOOL CALLBACK initialize_icu_break_api(PINIT_ONCE once, PVOID parameter,
    PVOID *context) {
    (void)once; (void)parameter; (void)context;
    HMODULE module = LoadLibraryExW(L"icu.dll", NULL, LOAD_LIBRARY_SEARCH_SYSTEM32);
    if (!module) return TRUE;
    CjguiWindowsIcuBreakApi api; memset(&api, 0, sizeof(api));
    api.module = module;
    api.open = (void *(__cdecl *)(int32_t, const char *, const WCHAR *, int32_t, int32_t *))
        icu_export(module, "ubrk_open");
    api.close = (void (__cdecl *)(void *))icu_export(module, "ubrk_close");
    api.isBoundary = (int32_t (__cdecl *)(void *, int32_t))icu_export(module, "ubrk_isBoundary");
    api.preceding = (int32_t (__cdecl *)(void *, int32_t))icu_export(module, "ubrk_preceding");
    api.following = (int32_t (__cdecl *)(void *, int32_t))icu_export(module, "ubrk_following");
    if (api.open && api.close && api.isBoundary && api.preceding && api.following)
        g_icuBreakApi = api;
    else
        FreeLibrary(module);
    return TRUE;
}

static int utf8_utf16_boundary_map(const char *utf8, uint64_t byteCount,
    int32_t wideCount, uint64_t *unitToByte) {
    if (!utf8 || !unitToByte || wideCount < 0) return 0;
    for (int32_t i = 0; i <= wideCount; ++i) unitToByte[i] = UINT64_MAX;
    uint64_t byte = 0u; int32_t unit = 0;
    unitToByte[0] = 0u;
    while (byte < byteCount) {
        uint8_t lead = (uint8_t)utf8[byte];
        uint32_t byteLength = lead < 0x80u ? 1u :
            ((lead & 0xE0u) == 0xC0u ? 2u : ((lead & 0xF0u) == 0xE0u ? 3u : 4u));
        if (byte + byteLength > byteCount) return 0;
        uint32_t unitLength = byteLength == 4u ? 2u : 1u;
        if (unit + (int32_t)unitLength > wideCount) return 0;
        if (unitLength == 2u) unitToByte[unit + 1] = UINT64_MAX;
        unit += (int32_t)unitLength;
        byte += byteLength;
        unitToByte[unit] = byte;
    }
    return unit == wideCount;
}

CjguiInternalRendererStatus cjgui_internal_renderer_grapheme_cluster_range(
    const char *utf8, uint64_t declaredLength, uint64_t offsetByte,
    uint64_t *outStartByte, uint64_t *outEndByte) {
    if (!utf8 || !outStartByte || !outEndByte)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outStartByte = 0u; *outEndByte = 0u;
    if (strlen(utf8) != declaredLength) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    if (offsetByte >= declaredLength) return CJGUI_INTERNAL_RENDERER_GRAPHEME_BOUNDARY_INVALID;
    if (declaredLength > CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY)
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    int wideCount = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8,
        (int)declaredLength, NULL, 0);
    if (wideCount <= 0) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    (void)InitOnceExecuteOnce(&g_icuBreakOnce, initialize_icu_break_api, NULL, NULL);
    if (!g_icuBreakApi.open || !g_icuBreakApi.close || !g_icuBreakApi.isBoundary ||
        !g_icuBreakApi.preceding || !g_icuBreakApi.following)
        return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
    WCHAR *wide = (WCHAR *)calloc((size_t)wideCount, sizeof(WCHAR));
    uint64_t *unitToByte = (uint64_t *)malloc(((size_t)wideCount + 1u) * sizeof(uint64_t));
    if (!wide || !unitToByte) { free(wide); free(unitToByte); return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR; }
    if (MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8,
        (int)declaredLength, wide, wideCount) != wideCount ||
        !utf8_utf16_boundary_map(utf8, declaredLength, wideCount, unitToByte)) {
        free(wide); free(unitToByte); return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    }
    uint64_t scalarByte = 0u; int32_t scalarUnit = 0;
    while (scalarByte < declaredLength) {
        uint8_t lead = (uint8_t)utf8[scalarByte];
        uint32_t byteLength = lead < 0x80u ? 1u :
            ((lead & 0xE0u) == 0xC0u ? 2u : ((lead & 0xF0u) == 0xE0u ? 3u : 4u));
        if (offsetByte < scalarByte + byteLength) break;
        scalarByte += byteLength;
        scalarUnit += byteLength == 4u ? 2 : 1;
    }
    int32_t icuError = 0;
    void *iterator = g_icuBreakApi.open(0, "root", wide, wideCount, &icuError);
    if (!iterator || icuError > 0) {
        if (iterator) g_icuBreakApi.close(iterator);
        free(wide); free(unitToByte); return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
    }
    int32_t startUnit = g_icuBreakApi.isBoundary(iterator, scalarUnit)
        ? scalarUnit : g_icuBreakApi.preceding(iterator, scalarUnit);
    int32_t endUnit = g_icuBreakApi.following(iterator, scalarUnit);
    g_icuBreakApi.close(iterator);
    CjguiInternalRendererStatus result = CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
    if (startUnit >= 0 && endUnit > startUnit && endUnit <= wideCount &&
        unitToByte[startUnit] != UINT64_MAX && unitToByte[endUnit] != UINT64_MAX) {
        *outStartByte = unitToByte[startUnit];
        *outEndByte = unitToByte[endUnit];
        result = *outEndByte > *outStartByte ? CJGUI_INTERNAL_RENDERER_OK
            : CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
    }
    free(wide); free(unitToByte);
    return result;
}

CjguiInternalRendererStatus cjgui_internal_renderer_composed_prefix_utf8_length(
    const char *utf8, uint64_t inputBytes, uint64_t maxOutputBytes,
    uint64_t maxClusters, uint8_t inputComplete, uint64_t *outPrefixBytes) {
    if (!outPrefixBytes || (!utf8 && inputBytes != 0u) || inputBytes > 2048u ||
        inputBytes > INT_MAX || inputComplete > 1u)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outPrefixBytes = 0u;
    if (inputBytes == 0u) return CJGUI_INTERNAL_RENDERER_OK;
    if (strlen(utf8) != inputBytes) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    int wideCount = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8,
        (int)inputBytes, NULL, 0);
    if (wideCount <= 0) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    (void)InitOnceExecuteOnce(&g_icuBreakOnce, initialize_icu_break_api, NULL, NULL);
    if (!g_icuBreakApi.open || !g_icuBreakApi.close || !g_icuBreakApi.following)
        return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
    WCHAR *wide = (WCHAR *)calloc((size_t)wideCount, sizeof(WCHAR));
    uint64_t *unitToByte = (uint64_t *)malloc(((size_t)wideCount + 1u) * sizeof(uint64_t));
    if (!wide || !unitToByte) { free(wide); free(unitToByte); return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR; }
    if (MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8,
        (int)inputBytes, wide, wideCount) != wideCount ||
        !utf8_utf16_boundary_map(utf8, inputBytes, wideCount, unitToByte)) {
        free(wide); free(unitToByte); return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    }
    int32_t icuError = 0;
    void *iterator = g_icuBreakApi.open(0, "root", wide, wideCount, &icuError);
    if (!iterator || icuError > 0) {
        if (iterator) g_icuBreakApi.close(iterator);
        free(wide); free(unitToByte); return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
    }
    int32_t unit = 0;
    uint64_t clusters = 0u;
    CjguiInternalRendererStatus result = CJGUI_INTERNAL_RENDERER_OK;
    while (unit < wideCount) {
        int32_t endUnit = g_icuBreakApi.following(iterator, unit);
        if (endUnit <= unit || endUnit > wideCount || unitToByte[endUnit] == UINT64_MAX) {
            result = CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
            break;
        }
        uint64_t endByte = unitToByte[endUnit];
        if ((!inputComplete && endByte == inputBytes) || endByte > maxOutputBytes ||
            clusters >= maxClusters) break;
        *outPrefixBytes = endByte;
        ++clusters;
        unit = endUnit;
    }
    g_icuBreakApi.close(iterator);
    free(wide); free(unitToByte);
    return result;
}

static CjguiInternalRendererStatus measure_composable_multiline_natural_height_impl(
    uint64_t token, const char *text, double fontSize, uint32_t fontWeight,
    uint32_t fontFamily, uint32_t contentWidth, uint32_t *outHeight) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!text || !outHeight || contentWidth == 0u) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    *outHeight = 0u;
    IDWriteTextLayout *layout = NULL;
    DWRITE_TEXT_METRICS metrics;
    CjguiInternalRendererStatus status = create_measured_text_layout(s, text,
        fontSize, fontWeight, fontFamily, (FLOAT)contentWidth, 100000.0f, &layout, &metrics);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    double height = ceil((double)metrics.height);
    if (!isfinite(height) || height < 0.0 || height > 1000000.0) {
        IDWriteTextLayout_Release(layout);
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    }
    *outHeight = (uint32_t)height;
    IDWriteTextLayout_Release(layout);
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus measure_composable_text_impl(
    uint64_t token, const char *text, double fontSize, uint32_t fontWeight,
    uint32_t fontFamily, uint32_t maximumWidth,
    CjguiInternalRendererTextMeasurement *outMeasurement) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!text || !outMeasurement) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    memset(outMeasurement, 0, sizeof(*outMeasurement));
    float width = maximumWidth == 0u ? 100000.0f : (FLOAT)maximumWidth;
    IDWriteTextLayout *layout = NULL;
    DWRITE_TEXT_METRICS metrics;
    CjguiInternalRendererStatus status = create_measured_text_layout(s, text,
        fontSize, fontWeight, fontFamily, width, 100000.0f, &layout, &metrics);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    if (metrics.lineCount > 65536u) {
        IDWriteTextLayout_Release(layout);
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    }
    DWRITE_LINE_METRICS *lines = metrics.lineCount
        ? (DWRITE_LINE_METRICS *)calloc(metrics.lineCount, sizeof(DWRITE_LINE_METRICS)) : NULL;
    UINT32 actualLines = 0u;
    HRESULT hr = metrics.lineCount && !lines ? E_OUTOFMEMORY
        : IDWriteTextLayout_GetLineMetrics(layout, lines, metrics.lineCount, &actualLines);
    double baseline = 0.0, lineHeight = 0.0;
    if (SUCCEEDED(hr) && actualLines) {
        baseline = lines[0].baseline;
        lineHeight = lines[0].height;
    }
    free(lines);
    if (FAILED(hr)) {
        IDWriteTextLayout_Release(layout);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    double measuredWidth = ceil((double)metrics.widthIncludingTrailingWhitespace);
    double measuredHeight = ceil((double)metrics.height);
    if (measuredWidth > UINT32_MAX || measuredHeight > UINT32_MAX ||
        baseline > UINT32_MAX || lineHeight > UINT32_MAX) {
        IDWriteTextLayout_Release(layout);
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    }
    outMeasurement->width = (uint32_t)measuredWidth;
    outMeasurement->height = (uint32_t)measuredHeight;
    outMeasurement->lineHeight = (uint32_t)ceil(lineHeight);
    outMeasurement->baseline = (uint32_t)ceil(baseline);
    IDWriteTextLayout_Release(layout);
    return CJGUI_INTERNAL_RENDERER_OK;
}

// 环境变量门控的 Windows 测试探针：把 accepted 场景节点的几何换算为屏幕坐标，
// 供 guest 侧用真实 SendInput 点击（导航与输入同走系统队列）。默认关闭；
// 产品正常运行不受影响（未设置 PHAROS_WINDOWS_TEST_PROBE_FILE 时零开销）。
static void windows_test_probe_tick(CjguiWindowsRendererSession *s) {
    const char *path = getenv("PHAROS_WINDOWS_TEST_PROBE_FILE");
    if (!path || !path[0] || !s || !s->hwnd) return;
    FILE *fp = fopen(path, "rb");
    if (!fp) return;
    char request[64];
    memset(request, 0, sizeof(request));
    size_t got = fread(request, 1u, sizeof(request) - 1u, fp);
    fclose(fp);
    if (got == 0u) return;
    // 单次语义：请求处理前先清空文件，避免每个 pump 重复执行同一请求。
    {
        FILE *clear = fopen(path, "wb");
        if (clear) fclose(clear);
    }
    unsigned long long positionNode = 0ull;
    unsigned int positionUnits = 0u;
    if (sscanf(request, "TEXT_POSITION %llu %u", &positionNode, &positionUnits) == 2) {
        char outputPath[1024]; snprintf(outputPath, sizeof(outputPath), "%s.out", path);
        FILE *output = fopen(outputPath, "wb");
        CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, (uint64_t)positionNode);
        const char *body = node ? windows_text_layout_value(node) : NULL;
        uint64_t byte = 0u, totalBytes = 0u; uint32_t totalUnits = 0u;
        uint64_t meta[8] = {0}; double rect[4] = {0};
        CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
        if (body && windows_text_layout_units(body, &totalBytes, &totalUnits) == CJGUI_INTERNAL_RENDERER_OK &&
            totalBytes <= 262144u && windows_utf8_offset_for_utf16(body, positionUnits, &byte)) {
            status = text_position_v1_impl(s->token, positionNode, s->acceptedScene.version,
                0u, (int64_t)byte, 1u, 0u, 0u, 0u, 0.0, 0.0, meta, rect);
        }
        if (output) {
            POINT point = {0, 0};
            double scale = (double)(s->dpi ? s->dpi : 96u) / 96.0;
            if (status == CJGUI_INTERNAL_RENDERER_OK) {
                point.x = (LONG)lround(rect[0] * scale);
                point.y = (LONG)lround((rect[1] + rect[3] / 2.0) * scale);
                if (!ClientToScreen(s->hwnd, &point)) status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
            }
            fprintf(output, "TEXT_POSITION_RESULT node=%llu units=%u status=%d scene=%llu lease=%llu screen=%ld,%ld rect=%.6f,%.6f,%.6f,%.6f body_bytes=%llu body_hash=%llu\n",
                positionNode, positionUnits, (int)status,
                (unsigned long long)s->acceptedScene.version, (unsigned long long)meta[0],
                point.x, point.y, rect[0], rect[1], rect[2], rect[3],
                (unsigned long long)totalBytes,
                (unsigned long long)(body ? windows_fnv1a64(1469598103934665603ull, body, (size_t)totalBytes) : 0u));
            fclose(output);
        }
        return;
    }
    unsigned long long nodeId = 0ull;
    int matchedRect = sscanf(request, "NODE_RECT %llu", &nodeId);
    unsigned long long clickId = 0ull;
    int matchedClick = sscanf(request, "CLICK_NODE %llu", &clickId);
    int matchedMouseDiag = (strcmp(request, "MOUSE_DIAG") == 0);
    if (strcmp(request, "TRACE") == 0) {
        char outputPath[1024];_snprintf(outputPath,sizeof(outputPath),"%s.out",path);
        FILE *output=fopen(outputPath,"wb");
        if(output){windows_trace_dump(s,output);fclose(output);}
        return;
    }
    if (strcmp(request, "INPUT_STATE") == 0) {
        char outputPath[1024];_snprintf(outputPath,sizeof(outputPath),"%s.out",path);
        FILE *output=fopen(outputPath,"wb");
        if(output) {
            fprintf(output,"INPUT_STATE scene=%llu node=%llu selection=%u:%u gate_pending=%u gate_request=%llu gate_binding=%llu provisional=%u outcome=%u receipt=%llu armed=%d closed=%d nonce=%llu generation=%llu binding=%llu context=%llu mirror=%llu owner=%lld proxy=%llu range_scene=%llu previous=%llu accepted=%llu accepted_version=%lld range_selection=%u:%u head=%u tail=%u\n",
                (unsigned long long)s->sceneVersion,(unsigned long long)s->focusedNodeId,
                s->selectionStart16,s->selectionEnd16,s->sourceInstallPending,
                (unsigned long long)s->sourceInstallRequestId,(unsigned long long)s->sourceInstallBindingEpoch,
                s->sourceInstallProvisional,s->sourceInstallOutcome,(unsigned long long)s->sourceInstallProvisionalNonce,
                s->rangeArmed,s->rangeClosed,(unsigned long long)s->rangeNonce,(unsigned long long)s->rangeGeneration,
                (unsigned long long)s->rangeBindingEpoch,(unsigned long long)s->rangeContextEpoch,
                (unsigned long long)s->rangeMirrorRevision,(long long)s->rangeOwnerVersion,
                (unsigned long long)s->rangeProxyGeneration,(unsigned long long)s->rangeSceneVersion,
                (unsigned long long)s->rangePrevSeq,(unsigned long long)s->rangeAcceptedSeq,
                (long long)s->rangeAcceptedVersion,s->rangeSelectionStart16,s->rangeSelectionEnd16,
                s->rangeClaimHead,s->rangeClaimTail);
            fclose(output);
        }
        return;
    }
    if (strcmp(request, "OWNER_TRACE") == 0) {
        char outputPath[1024];_snprintf(outputPath,sizeof(outputPath),"%s.out",path);
        FILE *output=fopen(outputPath,"wb");
        if(output){windows_owner_trace_dump(output);fclose(output);}
        return;
    }
    if (strcmp(request, "WORKLOAD") == 0) {
        char outputPath[1024];
        _snprintf(outputPath, sizeof(outputPath), "%s.out", path);
        FILE *output = fopen(outputPath, "wb");
        if (output) {
            fprintf(output, "WORKLOAD scene=%llu frame=%llu clock_ns=%llu layouts=%llu raster_count=%llu raster_bytes=%llu raster_us=%llu upload_count=%llu upload_bytes=%llu upload_us=%llu live_bytes=%llu peak_live_bytes=%llu resources=%llu scratch_bytes=%llu device_generation=%llu recovery_count=%llu recovery_pending=%u recovery_attempts=%u last_hr=%08lx controlled_pending=%u\n",
                (unsigned long long)s->sceneVersion, (unsigned long long)s->frameIndex,
                (unsigned long long)cjgui_internal_renderer_owner_clock_ns(),
                (unsigned long long)s->textLayoutPreparationCount,
                (unsigned long long)s->textRasterCount, (unsigned long long)s->textRasterBytes,
                (unsigned long long)s->textRasterMicros,
                (unsigned long long)s->textUploadCount, (unsigned long long)s->textUploadBytes,
                (unsigned long long)s->textUploadMicros,
                (unsigned long long)s->textTextureBytesInUse,
                (unsigned long long)s->textTexturePeakBytes,
                (unsigned long long)s->textTextureResourceCount,
                (unsigned long long)s->textScratchBytesInUse,
                (unsigned long long)s->deviceGeneration,
                (unsigned long long)s->deviceRecoveryCount,
                s->graphicsRecoveryPending, s->graphicsRecoveryAttempts,
                (unsigned long)s->lastGraphicsFailure, s->controlledDeviceFault);
            fclose(output);
        }
        return;
    }
    double hitX = 0.0, hitY = 0.0;
    int matchedHittest = (sscanf(request, "HITTEST %lf %lf", &hitX, &hitY) == 2);
    unsigned long long downId = 0ull;
    int matchedDown = sscanf(request, "DOWN_NODE %llu", &downId);
    unsigned long long upId = 0ull;
    int matchedUp = sscanf(request, "UP_NODE %llu", &upId);
    if (matchedRect != 1 && matchedClick != 1 && !matchedMouseDiag && !matchedHittest &&
        matchedDown != 1 && matchedUp != 1) return;
    if (matchedClick == 1 && clickId != 0ull) {
        // 进程内测试点击：owner 线程直接向自己的窗口发送真实鼠标消息，
        // 复用与物理点击相同的 WndProc/命中/事件路径；仅测试探针门控。
        CjguiWindowsSceneNode *clickNode = scene_node_by_id(&s->acceptedScene, clickId);
        char clickPath[1024];
        _snprintf(clickPath, sizeof(clickPath), "%s.out", path);
        FILE *clickOut = fopen(clickPath, "wb");
        if (!clickOut) return;
        if (!clickNode || !clickNode->hasNode) {
            fprintf(clickOut, "CLICK_RESULT %llu missing\n", clickId);
            fclose(clickOut);
            return;
        }
        double clickScale = (double)(s->dpi ? s->dpi : 96u) / 96.0;
        int clickCx = (int)(((double)clickNode->node.x + (double)clickNode->node.width / 2.0) * clickScale);
        int clickCy = (int)(((double)clickNode->node.y + (double)clickNode->node.height / 2.0) * clickScale);
        if (clickCx < 1) clickCx = 1;
        if (clickCy < 1) clickCy = 1;
        LPARAM clickPoint = MAKELPARAM(clickCx, clickCy);
        SendMessageW(s->hwnd, WM_LBUTTONDOWN, MK_LBUTTON, clickPoint);
        SendMessageW(s->hwnd, WM_LBUTTONUP, 0u, clickPoint);
        fprintf(clickOut, "CLICK_RESULT %llu at=%d,%d\n", clickId, clickCx, clickCy);
        fclose(clickOut);
        return;
    }
    if (matchedDown == 1 && downId != 0ull) {
        /* 分步定位：只发 DOWN 不发 UP，区分 dispatch 直接失败与 UP 配对假象。 */
        CjguiWindowsSceneNode *downNode = scene_node_by_id(&s->acceptedScene, downId);
        char downPath[1024];
        _snprintf(downPath, sizeof(downPath), "%s.out", path);
        FILE *downOut = fopen(downPath, "wb");
        if (!downOut) return;
        if (!downNode || !downNode->hasNode) {
            fprintf(downOut, "DOWN_RESULT %llu missing\n", downId);
            fclose(downOut);
            return;
        }
        double downScale = (double)(s->dpi ? s->dpi : 96u) / 96.0;
        int downCx = (int)(((double)downNode->node.x + (double)downNode->node.width / 2.0) * downScale);
        int downCy = (int)(((double)downNode->node.y + (double)downNode->node.height / 2.0) * downScale);
        if (downCx < 1) downCx = 1;
        if (downCy < 1) downCy = 1;
        SendMessageW(s->hwnd, WM_LBUTTONDOWN, MK_LBUTTON, MAKELPARAM(downCx, downCy));
        fprintf(downOut, "DOWN_RESULT %llu at=%d,%d\n", downId, downCx, downCy);
        fclose(downOut);
        return;
    }
    if (matchedUp == 1 && upId != 0ull) {
        /* 分步定位：只发 UP 不发 DOWN，与 DOWN_NODE 配对使用。 */
        CjguiWindowsSceneNode *upNode = scene_node_by_id(&s->acceptedScene, upId);
        char upPath[1024];
        _snprintf(upPath, sizeof(upPath), "%s.out", path);
        FILE *upOut = fopen(upPath, "wb");
        if (!upOut) return;
        if (!upNode || !upNode->hasNode) {
            fprintf(upOut, "UP_RESULT %llu missing\n", upId);
            fclose(upOut);
            return;
        }
        double upScale = (double)(s->dpi ? s->dpi : 96u) / 96.0;
        int upCx = (int)(((double)upNode->node.x + (double)upNode->node.width / 2.0) * upScale);
        int upCy = (int)(((double)upNode->node.y + (double)upNode->node.height / 2.0) * upScale);
        if (upCx < 1) upCx = 1;
        if (upCy < 1) upCy = 1;
        SendMessageW(s->hwnd, WM_LBUTTONUP, 0u, MAKELPARAM(upCx, upCy));
        fprintf(upOut, "UP_RESULT %llu at=%d,%d\n", upId, upCx, upCy);
        fclose(upOut);
        return;
    }
    if (matchedMouseDiag) {
        /* posted 鼠标管线可见性：raw 环深度、事件数、按压/选择/捕获标志、
           焦点归属。零开销门控（同文件探针），供 posted-click 定层。 */
        char diagPath[1024];
        _snprintf(diagPath, sizeof(diagPath), "%s.out", path);
        FILE *diagOut = fopen(diagPath, "wb");
        if (!diagOut) return;
        uint32_t rawDepth = (s->rawHead + CJGUI_WINDOWS_RAW_RING_CAPACITY -
            s->rawTail) % CJGUI_WINDOWS_RAW_RING_CAPACITY;
        int focused = s->hwnd && GetFocus() == s->hwnd ? 1 : 0;
        int pl0 = -1, pl1 = -1, pl2 = -1, pl3 = -1;
        if (s->dbgPushCount >= 1u) pl3 = (int)s->dbgPushLog[(s->dbgPushCount - 1u) % 8u];
        if (s->dbgPushCount >= 2u) pl2 = (int)s->dbgPushLog[(s->dbgPushCount - 2u) % 8u];
        if (s->dbgPushCount >= 3u) pl1 = (int)s->dbgPushLog[(s->dbgPushCount - 3u) % 8u];
        if (s->dbgPushCount >= 4u) pl0 = (int)s->dbgPushLog[(s->dbgPushCount - 4u) % 8u];
        int r0 = -1, r1 = -1, r2 = -1, r3 = -1;
        if (s->dbgRawCount >= 1u) r3 = (int)s->dbgRawLog[(s->dbgRawCount - 1u) % 8u];
        if (s->dbgRawCount >= 2u) r2 = (int)s->dbgRawLog[(s->dbgRawCount - 2u) % 8u];
        if (s->dbgRawCount >= 3u) r1 = (int)s->dbgRawLog[(s->dbgRawCount - 3u) % 8u];
        if (s->dbgRawCount >= 4u) r0 = (int)s->dbgRawLog[(s->dbgRawCount - 4u) % 8u];
        fprintf(diagOut, "MOUSE_DIAG rawDepth=%u eventCount=%u press=%u sel=%u cap=%u focused=%d pushTotal=%u last4=%d,%d,%d,%d upNode=%llu upFlags=%u sceneDown=%llu sceneUp=%llu downMark=%u upMark=%u rawTotal=%u rawLast4=%d,%d,%d,%d upStage=%u upReject=%u upOld=%llu upNew=%llu upFresh=%llu\n",
            rawDepth, s->eventCount, s->mousePressActive, s->mouseSelectionActive,
            s->mouseCaptureActive, focused, s->dbgPushCount, pl0, pl1, pl2, pl3,
            (unsigned long long)s->dbgUpNode, s->dbgUpFlags,
            (unsigned long long)s->dbgSceneDown, (unsigned long long)s->dbgSceneUp,
            s->dbgDownPushMark, s->dbgUpEntryMark, s->dbgRawCount, r0, r1, r2, r3,
            s->dbgUpStage, s->dbgUpReject,
            (unsigned long long)s->dbgUpOld, (unsigned long long)s->dbgUpNew,
            (unsigned long long)s->dbgUpFreshHit);
        fclose(diagOut);
        return;
    }
    if (matchedHittest) {
        /* 分层定位：与 mouse_down 完全相同的命中路径（/scale + acceptedScene
           逆序 + interactive/readonly + contains），报告实际命中的条目。 */
        char hitPath[1024];
        _snprintf(hitPath, sizeof(hitPath), "%s.out", path);
        FILE *hitOut = fopen(hitPath, "wb");
        if (!hitOut) return;
        double hitScale = (double)(s->dpi ? s->dpi : 96u) / 96.0;
        double cssX = hitX / hitScale, cssY = hitY / hitScale;
        uint32_t hitIndex = UINT32_MAX;
        CjguiWindowsSceneNode *hit = windows_node_at_accepted_point(s, cssX, cssY, &hitIndex);
        if (!hit) {
            fprintf(hitOut, "HITTEST none css=%.1f,%.1f configured=%d count=%u\n",
                cssX, cssY, s->acceptedScene.configured ? 1 : 0, s->acceptedScene.count);
        } else {
            fprintf(hitOut, "HITTEST index=%u nodeId=%llu kind=%d interactive=%d readonly=%d css=%.1f,%.1f\n",
                hitIndex, (unsigned long long)hit->node.nodeId, (int)hit->node.nodeKind,
                hit->node.isInteractive ? 1 : 0, hit->node.isReadOnly ? 1 : 0, cssX, cssY);
        }
        fclose(hitOut);
        return;
    }
    nodeId = nodeId;
    CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, nodeId);
    char outPath[1024];
    _snprintf(outPath, sizeof(outPath), "%s.out", path);
    FILE *out = fopen(outPath, "wb");
    if (!out) return;
    if (!node) {
        fprintf(out, "NODE_RECT_RESULT %llu missing\n", nodeId);
    } else {
        double scale = (double)(s->dpi ? s->dpi : 96u) / 96.0;
        int cw = (int)((double)node->node.width * scale);
        int ch = (int)((double)node->node.height * scale);
        POINT center;
        center.x = (LONG)((double)node->node.x * scale) + cw / 2;
        center.y = (LONG)((double)node->node.y * scale) + ch / 2;
        ClientToScreen(s->hwnd, &center);
        RECT client;
        RECT windowRect;
        memset(&client, 0, sizeof(client));
        memset(&windowRect, 0, sizeof(windowRect));
        GetClientRect(s->hwnd, &client);
        GetWindowRect(s->hwnd, &windowRect);
        POINT clickPoint;
        long long clientClickX = 0;
        long long clientClickY = 0;
        {
            long long innerX = (long long)node->node.x +
                ((long long)node->node.width > 24 ? 12 : (long long)node->node.width / 2);
            clientClickX = (long long)((double)innerX * scale);
            clientClickY = (long long)(((double)node->node.y + (double)node->node.height / 2.0) * scale);
            clickPoint.x = (LONG)clientClickX;
            clickPoint.y = (LONG)clientClickY;
            ClientToScreen(s->hwnd, &clickPoint);
        }
        double layoutWidth = 0.0;
        double layoutHeight = 0.0;
        CjguiWindowsSceneNode *root = scene_node_by_id(&s->acceptedScene, 100ull);
        if (root && root->node.width > 0 && root->node.height > 0) {
            layoutWidth = (double)root->node.width;
            layoutHeight = (double)root->node.height;
        }
        fprintf(out, "NODE_RECT_RESULT %llu screen=%ld,%ld click=%ld,%ld client_click=%lld,%lld size=%dx%d client=%ldx%ld dpi=%u node_rect=%lld,%lld,%lld,%lld frac=%.6f,%.6f winrect=%ld,%ld,%ld,%ld layout=%.1fx%.1f kind=%d interactive=%d readonly=%d hasNode=%d hasGeom=%d tr=%.1f,%.1f\n",
            nodeId, (long)center.x, (long)center.y, (long)clickPoint.x, (long)clickPoint.y,
            clientClickX, clientClickY, cw, ch,
            (long)(client.right - client.left), (long)(client.bottom - client.top),
            (unsigned)s->dpi,
            (long long)node->node.x, (long long)node->node.y,
            (long long)node->node.width, (long long)node->node.height,
            layoutWidth > 0.0 ? ((double)node->node.x + (double)node->node.width / 2.0) / layoutWidth : 0.0,
            layoutHeight > 0.0 ? ((double)node->node.y + (double)node->node.height / 2.0) / layoutHeight : 0.0,
            (long)windowRect.left, (long)windowRect.top, (long)windowRect.right, (long)windowRect.bottom,
            layoutWidth, layoutHeight,
            (int)node->node.nodeKind,
            node->node.isInteractive ? 1 : 0, node->node.isReadOnly ? 1 : 0,
            node->hasNode ? 1 : 0, node->hasGeometry ? 1 : 0,
            node->geometry.translateX, node->geometry.translateY);
    }
    fclose(out);
}

static void windows_ensure_pump_input_attached(CjguiWindowsRendererSession *s) {
    if (!s || s->pumpThreadId == 0u) return;
    DWORD selfTid = GetCurrentThreadId();
    if (selfTid != s->pumpThreadId)
        (void)AttachThreadInput(s->pumpThreadId, selfTid, TRUE);
}

CjguiInternalRendererStatus cjgui_internal_renderer_pump_event_measured(
    uint64_t token, uint32_t timeoutMs, CjguiInternalRendererEvent *outEvent,
    uint64_t *outIdleWaitNs) {
    return cjgui_windows_pump_entry(token, timeoutMs, outEvent, outIdleWaitNs, 1);
}

CjguiInternalRendererStatus cjgui_internal_renderer_pump_event(
    uint64_t token, uint32_t timeoutMs, CjguiInternalRendererEvent *outEvent) {
    return cjgui_windows_pump_entry(token, timeoutMs, outEvent, NULL, 0);
}

static CjguiInternalRendererStatus pumped_pointer_geometry_impl(
    uint64_t token, CjguiInternalRendererPointerEventGeometry *outGeometry) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outGeometry) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outGeometry = s->lastPointerGeometry;
    memset(&s->lastPointerGeometry, 0, sizeof(s->lastPointerGeometry));
    return CJGUI_INTERNAL_RENDERER_OK;
}

static int32_t owner_consumed_pointer_coordinate_lifetime_impl(
    uint64_t token, uint64_t *outSessionGeneration, uint64_t *outCoordinateEpoch) {
    if (outSessionGeneration) *outSessionGeneration = 0u;
    if (outCoordinateEpoch) *outCoordinateEpoch = 0u;
    CjguiWindowsRendererSession *s = find_session(token);
    if (require_session(s) != CJGUI_INTERNAL_RENDERER_OK ||
        !outSessionGeneration || !outCoordinateEpoch) return 0;
    if (s->lastPumpedSessionGeneration != s->sessionGeneration ||
        s->lastPumpedCoordinateEpoch != s->coordinateEpoch) {
        s->lastPumpedSessionGeneration = 0u;
        s->lastPumpedCoordinateEpoch = 0u;
        return 0;
    }
    *outSessionGeneration = s->lastPumpedSessionGeneration;
    *outCoordinateEpoch = s->lastPumpedCoordinateEpoch;
    s->lastPumpedSessionGeneration = 0u;
    s->lastPumpedCoordinateEpoch = 0u;
    return 1;
}

static const char *form_event_text_impl(uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    return require_session(s) == CJGUI_INTERNAL_RENDERER_OK && s->formEventText
        ? s->formEventText : "";
}

int32_t cjgui_macos_reduce_motion_enabled(void) {
    BOOL clientAnimations = TRUE;
    return SystemParametersInfoW(SPI_GETCLIENTAREAANIMATION, 0, &clientAnimations, 0)
        ? (clientAnimations ? 0 : 1) : 0;
}

int32_t cjgui_macos_effective_dark_mode(void) {
    DWORD light = 1u, bytes = sizeof(light);
    LONG result = RegGetValueW(HKEY_CURRENT_USER,
        L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
        L"AppsUseLightTheme", RRF_RT_REG_DWORD, NULL, &light, &bytes);
    return result == ERROR_SUCCESS && light == 0u ? 1 : 0;
}

int32_t cjgui_macos_window_visible(int64_t windowNumber) {
    HWND hwnd = (HWND)(intptr_t)windowNumber;
    return hwnd && IsWindow(hwnd) && IsWindowVisible(hwnd) ? 1 : 0;
}

int32_t cjgui_macos_window_minimized(int64_t windowNumber) {
    HWND hwnd = (HWND)(intptr_t)windowNumber;
    return hwnd && IsWindow(hwnd) && IsIconic(hwnd) ? 1 : 0;
}

/* ---- UI dispatcher 命令机制（phase 1：pump/destroy 封送） ----
   会话逻辑在 UI（泵）线程执行；C ABI 入口封送命令并等待完成。
   每条命令至多执行一次：started 由 UI 线程置位；cancelled 仅 destroy-A
   对尚未开始的排队命令置位。调用者无限等待 doneEvent；UI 线程以有界
   切片推进，保证完成；线程消亡只可能发生在 destroy 回收路径，其等待者
   均已先结算。栈上命令块依赖此等待不变式，禁止提前返回。 */
static int cmd_ring_full_locked(CjguiWindowsRendererSession *s) {
    return ((s->cmdHead + 1u) % CJGUI_WINDOWS_CMD_RING_CAPACITY) == s->cmdTail;
}

static int queue_owned_range_replace(CjguiWindowsRendererSession *s,
    const char *insert, uint32_t insertLength, int64_t frozenModifiers,
    uint32_t repeatCount);
static int enqueue_windows_navigation(CjguiWindowsRendererSession *s,
    const char *intent, int64_t frozenModifiers);
static void deferred_free_entry(CjguiWindowsDeferredInput *entry);
static void deferred_clear(CjguiWindowsRendererSession *s);
static void recovery_clear(CjguiWindowsRendererSession *s);
static int stash_recovery(CjguiWindowsRendererSession *s, uint32_t reason,
    uint32_t outcome, uint64_t inputId, uint64_t bindingEpoch,
    uint64_t requestId, uint32_t kind, const char *bytes, uint32_t length,
    const char *extraBytes, uint32_t extraLength, int64_t modifiers,
    uint32_t repeatCount, uint64_t compositionId, uint32_t phase,
    uint32_t cursor16);
static int stash_recovery_entry(CjguiWindowsRendererSession *s, uint32_t reason,
    uint32_t outcome, const CjguiWindowsDeferredInput *entry);
static int nav_barrier_stash_to_recovery(CjguiWindowsRendererSession *s,
    uint32_t outcome);
static void settle_gate_locked(CjguiWindowsRendererSession *s,
    uint32_t outcome);
static int begin_windows_composition(CjguiWindowsRendererSession *s);
static int queue_windows_composition_update(CjguiWindowsRendererSession *s,
    const char *text, uint32_t textBytes, uint32_t cursor16);
static int queue_windows_composition_terminal(CjguiWindowsRendererSession *s,
    uint32_t phase, const char *text, uint32_t textBytes);
static int remember_ime_successor(CjguiWindowsRendererSession *s,
    const char *text, uint32_t textBytes, uint32_t cursor16,
    uint64_t inputId, uint64_t bindingEpoch, uint64_t requestId,
    uint64_t compositionId);
static void clear_pending_ime_successor(CjguiWindowsRendererSession *s);
static int recover_pending_ime_successor(CjguiWindowsRendererSession *s,
    uint32_t outcome);

static void destroy_ui_phase_a(CjguiWindowsRendererSession *s) {
    s->retiring = 1;
    /* The destroy command preflights every recovery transfer and ACK before
       setting retiring. Phase A never discards a held input record. */
    EnterCriticalSection(&s->cmdLock);
    for (uint32_t i = s->cmdTail; i != s->cmdHead;
         i = (i + 1u) % CJGUI_WINDOWS_CMD_RING_CAPACITY) {
        CjguiWindowsCommand2 *queued = s->cmdRing[i % CJGUI_WINDOWS_CMD_RING_CAPACITY];
        if (queued && !queued->done && !queued->started) {
            queued->cancelled = 1;
        }
    }
    LeaveCriticalSection(&s->cmdLock);
    windows_cancel_mouse_gesture(s);
    windows_free_mouse_target(s);
    s->compositionGate = WINDOWS_COMPOSITION_GATE_RETIRING;
    s->compositionState = WINDOWS_COMPOSITION_RETIRED;
    s->compositionActive = 0u;
    s->pendingHighSurrogate = 0u;
    s->pendingHighSurrogateBindingEpoch = 0u;
    clear_pending_owned_input(s);
    range_disarm(s);
    clear_pending_ime_successor(s);
    if (s->hwnd) {
        HIMC context = ImmGetContext(s->hwnd);
        if (context) {
            (void)ImmNotifyIME(context, NI_COMPOSITIONSTR, CPS_CANCEL, 0u);
            ImmReleaseContext(s->hwnd, context);
        }
        (void)ImmAssociateContext(s->hwnd, s->originalImeContext);
    }
    if (s->ownedImeContext) {
        ImmDestroyContext(s->ownedImeContext);
        s->ownedImeContext = NULL;
    }
    if (s->inputAttached && s->pumpThreadId != 0u && s->ownerThreadId != 0u &&
        s->pumpThreadId != s->ownerThreadId) {
        (void)AttachThreadInput(s->pumpThreadId, s->ownerThreadId, FALSE);
        s->inputAttached = 0;
    }
}

static void destroy_caller_phase_b(CjguiWindowsRendererSession *s) {
    /* 图形资源已在 UI 线程的 destroy 命令内释放；此处只收内存、句柄与槽位。 */
    EnterCriticalSection(&s->cmdLock);
    if (s->cmdWaiters) {
        /* pump 已 join；最后一个等待者负责内存收尾。不能按墙钟截止删锁。 */
        s->callerCleanupDeferred = 1u;
        LeaveCriticalSection(&s->cmdLock);
        return;
    }
    LeaveCriticalSection(&s->cmdLock);
    cjgui_windows_free_hold(s);
    deferred_clear(s);
    recovery_clear(s);
    ime_frozen_free_all(s);
    nav_barrier_release(s, 0);
    release_scene(&s->candidateScene);
    release_scene(&s->acceptedScene);
    /* 私有准备图与退休图在会话销毁时全部释放：不留悬挂的槽位或字节。 */
    release_scene(&s->preparationScene);
    windows_prep_release_scene_nodes(s->preparationIncoming, s->preparationNodeCount);
    free(s->preparationState);
    free(s->preparationFrozenActiveBody);
    s->preparationIncoming = NULL;
    s->preparationState = NULL;
    s->preparationFrozenActiveBody = NULL;
    while (s->preparationRetiringCount > 0u) {
        uint32_t slot = 0u;
        release_scene(&s->preparationRetiring[slot].scene);
        windows_prep_release_scene_nodes(s->preparationRetiring[slot].incoming,
            s->preparationRetiring[slot].nodeCount);
        free(s->preparationRetiring[slot].state);
        memset(&s->preparationRetiring[slot], 0, sizeof(s->preparationRetiring[0]));
        for (uint32_t i = 1u; i < s->preparationRetiringCount; ++i)
            s->preparationRetiring[i - 1u] = s->preparationRetiring[i];
        memset(&s->preparationRetiring[s->preparationRetiringCount - 1u], 0,
            sizeof(s->preparationRetiring[0]));
        s->preparationRetiringCount -= 1u;
    }
    s->preparationLiveBytes = 0u;
    windows_prep_clear_active_fields(s);
    for (uint32_t i=0;i<CJGUI_WINDOWS_IMAGE_CACHE_CAPACITY;++i) release_image_resource(&s->images[i]);
    for (uint32_t i = 0; i < s->textRunDeclarationCount; ++i)
        free(s->textRunDeclarations[i].encoded);
    free(s->proxyValueUtf8);
    free(s->pendingPngTransferIdentity);
    for (uint32_t i = 0; i < CJGUI_WINDOWS_EVENT_CAPACITY; ++i)
        free(s->eventTextPayloads[i]);
    free(s->formEventText);
    free(s->formEventTextLease);
    free(s->formEventTextPrev);
    s->formEventText = NULL;
    s->formEventTextLease = NULL;
    s->formEventTextPrev = NULL;
    free(s->compositionBaseUtf8);
    free(s->compositionExpectedOwnerUtf8);
    if (s->rawWakeEvent) CloseHandle(s->rawWakeEvent);
    if (s->pumpReadyEvent) CloseHandle(s->pumpReadyEvent);
    if (s->pumpStopEvent) CloseHandle(s->pumpStopEvent);
    if (s->cmdWakeEvent) CloseHandle(s->cmdWakeEvent);
    DeleteCriticalSection(&s->rawLock);
    DeleteCriticalSection(&s->cmdLock);
    ensure_session_lock();
    EnterCriticalSection(&g_sessionLock);
    memset(s, 0, sizeof(*s));
    LeaveCriticalSection(&g_sessionLock);
}

/* 调用时持有 cmdLock；返回后不再引用 session。phase-B 延期的唯一
   接收方是最后一个等待者，其命令 ctx/信封仍由自己的退出路径处理。 */
static void release_dispatcher_waiter_locked(CjguiWindowsRendererSession *s) {
    s->cmdWaiters -= 1u;
    int cleanup = !s->cmdWaiters && s->callerCleanupDeferred;
    if (cleanup) s->callerCleanupDeferred = 0u;
    LeaveCriticalSection(&s->cmdLock);
    if (cleanup) destroy_caller_phase_b(s);
}

/* cmdLock 内完成通知、归属移交和可回收完成发布。离开锁后执行方不再
   访问信封；等待方也必须在同一锁内认领结果，通知唤醒不等于交接完成。 */
static void complete_dispatcher_command(CjguiWindowsRendererSession *s,
    CjguiWindowsCommand2 *cmd, CjguiInternalRendererStatus status) {
    if (status==CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR && s->failureDiagnosticCount<32u &&
        getenv("PHAROS_WINDOWS_TEST_PROBE_FILE")) {
        ++s->failureDiagnosticCount;
        fprintf(stderr,"CJGUI_WINDOWS_API_FAIL api=%s cmd=%llu scene=%llu candidate=%llu hr=%08lx\n",cmd->apiName,
            (unsigned long long)cmd->commandId,(unsigned long long)s->sceneVersion,
            (unsigned long long)s->candidateScene.version,(unsigned long)s->lastGraphicsFailure);
    }
    EnterCriticalSection(&s->cmdLock);
    cmd->status = status;
    if (cmd->fireAndForget) {
        if (cmd->ctxFree) cmd->ctxFree(cmd->ctx);
        if (cmd->doneEvent) CloseHandle(cmd->doneEvent);
        free(cmd);
    } else if (cmd->orphaned) {
        cmd->done = 1;
        if (s->cmdHoldCount < CJGUI_WINDOWS_CMD_HOLD_CAPACITY) {
            s->cmdHold[(s->cmdHoldHead + s->cmdHoldCount) %
                CJGUI_WINDOWS_CMD_HOLD_CAPACITY] = cmd;
            s->cmdHoldCount += 1u;
        } else {
            s->orphanedDropped += 1u;
            if (cmd->ctxFree) cmd->ctxFree(cmd->ctx);
            if (cmd->doneEvent) CloseHandle(cmd->doneEvent);
            free(cmd);
        }
    } else {
        if (cmd->doneEvent) SetEvent(cmd->doneEvent);
        cmd->done = 1;
    }
    LeaveCriticalSection(&s->cmdLock);
}

/* 通用命令执行（只在 UI 线程调用）：按 token 查找会话并核代次/退役，
   再运行 proc；记录调用/执行/HWND tid 身份。调用者栈永不被引用。 */
static void execute_dispatcher_command(CjguiWindowsRendererSession *hint,
    CjguiWindowsCommand2 *cmd) {
    DWORD self = GetCurrentThreadId();
    CjguiWindowsRendererSession *s = find_session(cmd->token);
    if (!s || s->pumpThreadId == 0u || self != s->pumpThreadId) {
        complete_dispatcher_command(hint, cmd, CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR);
        return;
    }
    if (cmd->cancelled || s->retiring ||
        (cmd->generation != 0u && cmd->generation != s->sessionGeneration)) {
        complete_dispatcher_command(s, cmd, CJGUI_INTERNAL_RENDERER_INVALID_SESSION);
        return;
    }
    cmd->started = 1;
    uint64_t executeAt=s->traceEnabled?cjgui_internal_renderer_owner_clock_ns():0;
    cmd->status = cmd->proc(s, cmd->ctx);
    if (s->traceEnabled) {
        const char *traceStage = !strcmp(cmd->apiName,"present") ? "dispatch" :
            !strcmp(cmd->apiName,"claim_range") ? "dispatch_range_claim" :
            !strcmp(cmd->apiName,"copy_bytes") ? "dispatch_range_copy" :
            !strcmp(cmd->apiName,"ack_range") ? "dispatch_range_ack" : NULL;
        if (traceStage)
            windows_trace(s,traceStage,cmd->commandId,executeAt-cmd->queuedNs,
                cjgui_internal_renderer_owner_clock_ns()-executeAt,cmd->status,cmd->callerTid,self);
    }
    s->lastExecCallerTid = cmd->callerTid;
    s->lastExecTid = self;
    {
        DWORD hwndTid = 0u;
        if (s->hwnd) hwndTid = GetWindowThreadProcessId(s->hwnd, NULL);
        s->lastExecHwndTid = hwndTid ? hwndTid : self;
    }
    {
        size_t n = 0;
        while (n + 1u < sizeof(s->lastExecApi) && cmd->apiName[n]) {
            s->lastExecApi[n] = cmd->apiName[n];
            ++n;
        }
        s->lastExecApi[n] = '\0';
    }
    s->lastExecStatus = cmd->status;
    complete_dispatcher_command(s, cmd, cmd->status);
}

static void drain_dispatcher_commands(CjguiWindowsRendererSession *s, int skipPumpAndDestroy) {
    for (;;) {
        CjguiWindowsCommand2 *cmd = NULL;
        EnterCriticalSection(&s->cmdLock);
        if (s->cmdHead != s->cmdTail) {
            CjguiWindowsCommand2 *front = s->cmdRing[s->cmdTail % CJGUI_WINDOWS_CMD_RING_CAPACITY];
            if (skipPumpAndDestroy && front &&
                (front->kind == CJGUI_WINDOWS_CMD_PUMP || front->kind == CJGUI_WINDOWS_CMD_DESTROY)) {
                LeaveCriticalSection(&s->cmdLock);
                return;
            }
            cmd = front;
            s->cmdTail = (s->cmdTail + 1u) % CJGUI_WINDOWS_CMD_RING_CAPACITY;
            /* 出队即认领（锁内）：超时方看到 started 即不得释放，
               只能走 in-flight 移交；杜绝“已出队、未 started”窗口的释放竞态。 */
            cmd->started = 1;
        }
        LeaveCriticalSection(&s->cmdLock);
        if (!cmd) return;
        execute_dispatcher_command(s, cmd);
    }
}

/* 通用同步封送：调用者只给 token；路由快照读锁保护，会话解析与
   代次/退役检查在 UI 线程；堆信封，调用者栈返回后永不被引用。 */
static CjguiInternalRendererStatus windows_dispatch_sync(uint64_t token,
    const char *apiName, uint32_t kind, CjguiWindowsUiProc proc, void *ctx,
    CjguiWindowsCtxFree ctxFree, uint32_t timeoutMs, uint64_t *outCommandId) {
    if (outCommandId) *outCommandId = 0u;
    if (!proc) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    DWORD caller = GetCurrentThreadId();
    CjguiWindowsRendererSession *route = find_session(token);
    if (!route) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    DWORD uiTid = route->pumpThreadId;
    uint64_t generation = route->sessionGeneration;
    int retiring = route->retiring;
    int running = route->pumpThreadRunning;
    if (retiring) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (uiTid != 0u && caller == uiTid) {
        CjguiWindowsRendererSession *s = find_session(token);
        if (!s || s->sessionGeneration != generation || s->retiring)
            return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        CjguiInternalRendererStatus st = proc(s, ctx);
        s->lastExecCallerTid = caller;
        s->lastExecTid = caller;
        {
            DWORD hwndTid = 0u;
            if (s->hwnd) hwndTid = GetWindowThreadProcessId(s->hwnd, NULL);
            s->lastExecHwndTid = hwndTid ? hwndTid : caller;
        }
        {
            size_t n = 0;
            if (apiName) while (n + 1u < sizeof(s->lastExecApi) && apiName[n]) {
                s->lastExecApi[n] = apiName[n];
                ++n;
            }
            s->lastExecApi[n] = '\0';
        }
        s->lastExecStatus = st;
        return st;
    }
    if (!running || uiTid == 0u) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    CjguiWindowsCommand2 *cmd =
        (CjguiWindowsCommand2 *)calloc(1u, sizeof(CjguiWindowsCommand2));
    if (!cmd) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    HANDLE doneEvent = CreateEventW(NULL, FALSE, FALSE, NULL);
    if (!doneEvent) {
        free(cmd);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    cmd->token = token;
    cmd->generation = generation;
    cmd->kind = kind;
    cmd->queuedNs=route->traceEnabled?cjgui_internal_renderer_owner_clock_ns():0;
    if (apiName) {
        size_t n = 0;
        while (n + 1u < sizeof(cmd->apiName) && apiName[n]) {
            cmd->apiName[n] = apiName[n];
            ++n;
        }
    }
    cmd->proc = proc;
    cmd->ctx = ctx;
    cmd->ctxFree = ctxFree;
    cmd->callerTid = caller;
    cmd->status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    cmd->doneEvent = doneEvent;
    EnterCriticalSection(&route->cmdLock);
    if (route->retiring || route->sessionGeneration != generation) {
        LeaveCriticalSection(&route->cmdLock);
        CloseHandle(doneEvent);
        free(cmd);
        return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    if (cmd_ring_full_locked(route)) {
        LeaveCriticalSection(&route->cmdLock);
        CloseHandle(doneEvent);
        free(cmd);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    EnterCriticalSection(&g_sessionLock);
    cmd->commandId = ++route->cmdNextId;
    LeaveCriticalSection(&g_sessionLock);
    if (cmd->commandId == 0u) cmd->commandId = 1u;
    route->cmdRing[route->cmdHead % CJGUI_WINDOWS_CMD_RING_CAPACITY] = cmd;
    route->cmdHead = (route->cmdHead + 1u) % CJGUI_WINDOWS_CMD_RING_CAPACITY;
    route->cmdWaiters += 1u;
    SetEvent(route->cmdWakeEvent);
    LeaveCriticalSection(&route->cmdLock);
    DWORD waited = WaitForSingleObject(doneEvent, timeoutMs);
    if (waited != WAIT_OBJECT_0) {
        /* 超时：出队认领与取消标记都在 cmdLock 内完成，此处锁内一次读完
           started/cancelled/done，再决定摘除、成功认领还是移交；杜绝释放竞态。
           done 置位意味着 UI 线程已完成本命令（F1 保证其通知/移交决定与
           orphaned 读取原子）：done 且未 orphaned 即正常完成，走成功认领，
           不得按超时释放或转 in-flight；done 且已 orphaned 说明信封已入 hold，
           只转 IN_FLIGHT 供 reap 取回。 */
        int wasStarted = 0;
        int wasCancelled = 0;
        int wasDone = 0;
        int wasOrphaned = 0;
        int removed = 0;
        CjguiInternalRendererStatus doneStatus = CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT;
        EnterCriticalSection(&route->cmdLock);
        wasStarted = cmd->started;
        wasCancelled = cmd->cancelled;
        wasDone = cmd->done;
        wasOrphaned = cmd->orphaned;
        if (wasDone && !wasOrphaned) {
            doneStatus = cmd->cancelled
                ? CJGUI_INTERNAL_RENDERER_INVALID_SESSION : cmd->status;
        }
        if (!wasStarted && !wasCancelled && !wasDone) {
            uint32_t w = route->cmdTail;
            while (w != route->cmdHead) {
                if (route->cmdRing[w % CJGUI_WINDOWS_CMD_RING_CAPACITY] == cmd) {
                    uint32_t v = w;
                    while (v != route->cmdHead) {
                        uint32_t nxt = (v + 1u) % CJGUI_WINDOWS_CMD_RING_CAPACITY;
                        if (nxt == route->cmdHead) break;
                        route->cmdRing[v % CJGUI_WINDOWS_CMD_RING_CAPACITY] =
                            route->cmdRing[nxt % CJGUI_WINDOWS_CMD_RING_CAPACITY];
                        v = nxt;
                    }
                    route->cmdHead = (route->cmdHead + CJGUI_WINDOWS_CMD_RING_CAPACITY - 1u) %
                        CJGUI_WINDOWS_CMD_RING_CAPACITY;
                    removed = 1;
                    break;
                }
                w = (w + 1u) % CJGUI_WINDOWS_CMD_RING_CAPACITY;
            }
            if (removed) {
                cmd->cancelled = 1;
                cmd->done = 1;
            }
        }
        if (!wasStarted && !removed) wasCancelled = cmd->cancelled;
        if (wasDone && !wasOrphaned) {
            release_dispatcher_waiter_locked(route);
            CloseHandle(doneEvent);
            free(cmd);
            return doneStatus;
        }
        if (wasDone && wasOrphaned) {
            if (outCommandId) *outCommandId = cmd->commandId;
            release_dispatcher_waiter_locked(route);
            return CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT;
        }
        if (wasStarted && outCommandId) *outCommandId = cmd->commandId;
        if (wasStarted) {
            /* 已认领（出队）或正在执行：转 in-flight。信封/ctx/句柄一律移交
               hold，由 reap 或 teardown 单次回收；调用者不得释放、不得重发。 */
            cmd->orphaned = 1;
            route->orphanedCommands += 1u;
        }
        release_dispatcher_waiter_locked(route);
        if (wasStarted) {
            return CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT;
        }
        if (removed || wasCancelled) {
            /* 摘除成功或关闭已取消：ctx 按“除 IN_FLIGHT 外失败由 wrapper
               释放”约定归调用者；信封就地释放（此前漏 free）。 */
            if (ctxFree) ctxFree(ctx);
            CloseHandle(doneEvent);
            free(cmd);
            return wasCancelled ? CJGUI_INTERNAL_RENDERER_INVALID_SESSION
                                : CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT;
        }
        /* 防御：未认领、未取消、环中无此命令——正常不可能到达；
           按超时释放，避免泄漏（此时无另一方能拥有它）。 */
        if (ctxFree) ctxFree(ctx);
        CloseHandle(doneEvent);
        free(cmd);
        return CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT;
    }
    EnterCriticalSection(&route->cmdLock);
    CjguiInternalRendererStatus status = cmd->cancelled
        ? CJGUI_INTERNAL_RENDERER_INVALID_SESSION : cmd->status;
    release_dispatcher_waiter_locked(route);
    CloseHandle(doneEvent);
    /* 成功/取消唤醒：信封由等待方一次释放（此前漏 free，常驻泄漏）；
       ctx 仍归调用者（各 wrapper 的非 TIMEOUT/IN_FLIGHT 分支释放）。 */
    free(cmd);
    return status;
}

typedef struct CjguiWindowsPumpCtx {
    uint32_t timeoutMs;
    int hasIdleOut;
    CjguiInternalRendererEvent outEvent;
    uint64_t outIdleNs;
} CjguiWindowsPumpCtx;

static void cjgui_windows_free_ctx(void *ctx) {
    free(ctx);
}

static char *cjgui_windows_dup_string(const char *value) {
    if (!value) return NULL;
    size_t length = strlen(value) + 1u;
    char *copy = (char *)malloc(length);
    if (!copy) return NULL;
    memcpy(copy, value, length);
    return copy;
}

static uint8_t *cjgui_windows_dup_bytes(const void *bytes, uint32_t length) {
    if (!bytes) return NULL;
    uint8_t *copy = (uint8_t *)malloc(length ? length : 1u);
    if (!copy) return NULL;
    if (length) memcpy(copy, bytes, length);
    return copy;
}

static CjguiInternalRendererStatus cjgui_windows_pump_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    CjguiWindowsPumpCtx *ctx = (CjguiWindowsPumpCtx *)raw;
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    windows_ensure_pump_input_attached(s);
    windows_test_probe_tick(s);
    uint64_t idleNs = 0u;
    CjguiInternalRendererStatus st = pump_windows_messages(s, ctx->timeoutMs,
        &ctx->outEvent, ctx->hasIdleOut ? &idleNs : NULL);
    if (ctx->hasIdleOut) ctx->outIdleNs = idleNs;
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_pump_entry(uint64_t token,
    uint32_t timeoutMs, CjguiInternalRendererEvent *outEvent,
    uint64_t *outIdleWaitNs, int hasIdleOut) {
    if (!outEvent) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsPumpCtx *ctx =
        (CjguiWindowsPumpCtx *)calloc(1u, sizeof(CjguiWindowsPumpCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->timeoutMs = timeoutMs;
    ctx->hasIdleOut = hasIdleOut;
    {
        CjguiWindowsRendererSession *hold = find_session(token);
        if (hold) {
            EnterCriticalSection(&hold->cmdLock);
            CjguiWindowsCommand2 *front = NULL;
            if (hold->cmdHoldCount > 0u) {
                front = hold->cmdHold[hold->cmdHoldHead %
                    CJGUI_WINDOWS_CMD_HOLD_CAPACITY];
            }
            if (front && front->kind == CJGUI_WINDOWS_CMD_PUMP && front->done) {
                CjguiWindowsPumpCtx *retained = (CjguiWindowsPumpCtx *)front->ctx;
                hold->cmdHoldHead = (hold->cmdHoldHead + 1u) %
                    CJGUI_WINDOWS_CMD_HOLD_CAPACITY;
                hold->cmdHoldCount -= 1u;
                LeaveCriticalSection(&hold->cmdLock);
                if (retained) *outEvent = retained->outEvent;
                if (hasIdleOut && outIdleWaitNs) *outIdleWaitNs = 0u;
                if (front->ctxFree) front->ctxFree(front->ctx);
                if (front->doneEvent) CloseHandle(front->doneEvent);
                free(front);
                free(ctx);
                return CJGUI_INTERNAL_RENDERER_OK;
            }
            LeaveCriticalSection(&hold->cmdLock);
        }
    }
    uint64_t cmdId = 0u;
    uint32_t waitMs = (timeoutMs > 16u ? 16u : timeoutMs) +
        CJGUI_WINDOWS_CMD_TIMEOUT_MS;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "pump_event",
        CJGUI_WINDOWS_CMD_PUMP, cjgui_windows_pump_proc, ctx,
        cjgui_windows_free_ctx, waitMs, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outEvent = ctx->outEvent;
        if (hasIdleOut && outIdleWaitNs) *outIdleWaitNs = ctx->outIdleNs;
    }
    /* 与其余 wrapper 同约定：TIMEOUT 的 ctx 已由核心经 ctxFree 释放，
       IN_FLIGHT 的 ctx 归 hold/reap；此处只释放其余失败与成功。 */
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
static DWORD g_testDestroyExecTid;
#endif

static CjguiInternalRendererStatus cjgui_windows_destroy_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)raw;
    if (s->retiring) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    EnterCriticalSection(&g_sessionLock);
    if (s->presentReceipt.ticketId) {
        ++s->presentTicketDestroyRefusedCount;
        LeaveCriticalSection(&g_sessionLock);
        return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
    }
    LeaveCriticalSection(&g_sessionLock);
    CjguiInternalRendererStatus flightStatus = drain_text_flights(s, 5000u);
    if (flightStatus != CJGUI_INTERNAL_RENDERER_OK) return flightStatus;
    if (s->sourceInstallPending) {
        CjguiInternalRendererStatus settled = finish_source_install_impl(s->token,
            s->sourceInstallRequestId, CJGUI_WINDOWS_FINISH_CLOSED, 0u);
        if (settled != CJGUI_INTERNAL_RENDERER_OK) return settled;
    } else if (!nav_barrier_stash_to_recovery(s, CJGUI_WINDOWS_INSTALL_OUTCOME_CLOSED)) {
        return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
    }
    if (!recover_pending_ime_successor(s, CJGUI_WINDOWS_INSTALL_OUTCOME_CLOSED))
        return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
    for (uint32_t i = 0u; i < CJGUI_WINDOWS_IME_FROZEN_CAPACITY; ++i) {
        CjguiWindowsImeFrozen *f = &s->imeFrozen[i];
        if (!f->used) continue;
        if (!stash_recovery(s, CJGUI_WINDOWS_RECOVERY_GATE_OUTCOME,
            CJGUI_WINDOWS_INSTALL_OUTCOME_CLOSED, s->deferredNextId++,
            f->bindingEpoch, s->sourceInstallRequestId, 3u,
            f->resultText, f->resultBytes, f->markedText, f->markedBytes,
            0, 1u, f->compositionId, 0u, f->cursor16))
            return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
        uint32_t slot = (s->recoveryHead + s->recoveryCount - 1u) % CJGUI_WINDOWS_RECOVERY_CAPACITY;
        s->recoverySlots[slot].handledParts = (uint32_t)f->handledFlags;
        ime_frozen_free_slot(s, (int64_t)i);
    }
    if (s->recoveryCount) return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
    destroy_ui_phase_a(s);
    release_graphics(s);
    cjgui_windows_fail_queued(s);
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    g_testDestroyExecTid = GetCurrentThreadId();
#endif
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus cjgui_windows_stop_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)raw;
    raw_ring_push(s, (uint32_t)WM_QUIT, 0u, 0, 0);
    SetEvent(s->rawWakeEvent);
    return CJGUI_INTERNAL_RENDERER_OK;
}

static void cjgui_windows_fail_queued(CjguiWindowsRendererSession *s) {
    for (;;) {
        CjguiWindowsCommand2 *cmd = NULL;
        EnterCriticalSection(&s->cmdLock);
        if (s->cmdHead != s->cmdTail) {
            cmd = s->cmdRing[s->cmdTail % CJGUI_WINDOWS_CMD_RING_CAPACITY];
            s->cmdTail = (s->cmdTail + 1u) % CJGUI_WINDOWS_CMD_RING_CAPACITY;
            /* 摘除即认领执行责任。完成发布前的超时只能移交为 orphaned，
               不得释放已由关闭方持有的信封。 */
            cmd->started = 1;
            cmd->cancelled = 1;
        }
        LeaveCriticalSection(&s->cmdLock);
        if (!cmd) return;
        complete_dispatcher_command(s, cmd, CJGUI_INTERNAL_RENDERER_INVALID_SESSION);
    }
}

static void cjgui_windows_free_hold(CjguiWindowsRendererSession *s) {
    EnterCriticalSection(&s->cmdLock);
    while (s->cmdHoldCount > 0u) {
        CjguiWindowsCommand2 *cmd = s->cmdHold[s->cmdHoldHead %
            CJGUI_WINDOWS_CMD_HOLD_CAPACITY];
        s->cmdHoldHead = (s->cmdHoldHead + 1u) % CJGUI_WINDOWS_CMD_HOLD_CAPACITY;
        s->cmdHoldCount -= 1u;
        LeaveCriticalSection(&s->cmdLock);
        if (cmd->ctxFree) cmd->ctxFree(cmd->ctx);
        if (cmd->doneEvent) CloseHandle(cmd->doneEvent);
        free(cmd);
        EnterCriticalSection(&s->cmdLock);
    }
    LeaveCriticalSection(&s->cmdLock);
}

static void cjgui_windows_enqueue_stop(uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s || s->retiring || s->pumpThreadId == 0u || !s->pumpThreadRunning) return;
    CjguiWindowsCommand2 *cmd =
        (CjguiWindowsCommand2 *)calloc(1u, sizeof(CjguiWindowsCommand2));
    if (!cmd) return;
    cmd->token = token;
    cmd->generation = s->sessionGeneration;
    cmd->kind = CJGUI_WINDOWS_CMD_STOP;
    cmd->apiName[0] = 's'; cmd->apiName[1] = 't'; cmd->apiName[2] = 'o';
    cmd->apiName[3] = 'p'; cmd->apiName[4] = '\0';
    cmd->proc = cjgui_windows_stop_proc;
    cmd->callerTid = GetCurrentThreadId();
    cmd->fireAndForget = 1;
    EnterCriticalSection(&s->cmdLock);
    if (s->retiring || cmd_ring_full_locked(s)) {
        LeaveCriticalSection(&s->cmdLock);
        free(cmd);
        return;
    }
    EnterCriticalSection(&g_sessionLock);
    cmd->commandId = ++s->cmdNextId;
    LeaveCriticalSection(&g_sessionLock);
    s->cmdRing[s->cmdHead % CJGUI_WINDOWS_CMD_RING_CAPACITY] = cmd;
    s->cmdHead = (s->cmdHead + 1u) % CJGUI_WINDOWS_CMD_RING_CAPACITY;
    SetEvent(s->cmdWakeEvent);
    LeaveCriticalSection(&s->cmdLock);
}

/* 取回保留的已完成孤儿命令（禁重发副作用后的状态查询）。 */
CjguiInternalRendererStatus cjgui_internal_renderer_reap_orphaned_command(
    uint64_t token, uint64_t *outCommandId,
    CjguiInternalRendererStatus *outStatus) {
    if (outCommandId) *outCommandId = 0u;
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    EnterCriticalSection(&s->cmdLock);
    CjguiWindowsCommand2 *cmd = NULL;
    if (s->cmdHoldCount > 0u) {
        cmd = s->cmdHold[s->cmdHoldHead % CJGUI_WINDOWS_CMD_HOLD_CAPACITY];
        s->cmdHoldHead = (s->cmdHoldHead + 1u) % CJGUI_WINDOWS_CMD_HOLD_CAPACITY;
        s->cmdHoldCount -= 1u;
    }
    LeaveCriticalSection(&s->cmdLock);
    if (!cmd) return CJGUI_INTERNAL_RENDERER_OK;
    if (outCommandId) *outCommandId = cmd->commandId;
    if (outStatus) *outStatus = cmd->status;
    if (cmd->ctxFree) cmd->ctxFree(cmd->ctx);
    if (cmd->doneEvent) CloseHandle(cmd->doneEvent);
    free(cmd);
    return CJGUI_INTERNAL_RENDERER_OK;
}

/* 最近一次 UI 线程执行的命令身份：调用/执行/HWND tid＋API 名＋结果。 */
void cjgui_internal_renderer_debug_last_exec_identity(uint64_t token,
    uint64_t *outCallerTid, uint64_t *outExecTid, uint64_t *outHwndTid,
    char *outApi, uint64_t apiCapacity, int *outStatus) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) return;
    EnterCriticalSection(&s->cmdLock);
    DWORD caller = s->lastExecCallerTid;
    DWORD exec = s->lastExecTid;
    DWORD hwnd = s->lastExecHwndTid;
    int st = (int)s->lastExecStatus;
    char api[64];
    memcpy(api, s->lastExecApi, sizeof(api));
    LeaveCriticalSection(&s->cmdLock);
    if (outCallerTid) *outCallerTid = (uint64_t)caller;
    if (outExecTid) *outExecTid = (uint64_t)exec;
    if (outHwndTid) *outHwndTid = (uint64_t)hwnd;
    if (outApi && apiCapacity) {
        uint64_t n = 0u;
        while (n + 1u < apiCapacity && n < sizeof(api) && api[n]) {
            outApi[n] = api[n];
            ++n;
        }
        outApi[n] = '\0';
    }
    if (outStatus) *outStatus = st;
}

static DWORD WINAPI pump_thread_main(LPVOID param) {
    CjguiWindowsRendererSession *s = (CjguiWindowsRendererSession *)param;
    s->pumpThreadId = GetCurrentThreadId();
    /* 窗口与其消息队列归属本线程；D3D 设备同线程创建以保持归属一致。 */
    CjguiInternalRendererStatus status =
        create_window_and_device(s, s->pendingCreateWidth, s->pendingCreateHeight);
    s->pumpThreadStatus = status;
    SetEvent(s->pumpReadyEvent);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return 1;
    MSG message;
    HANDLE waitHandles[2] = { s->pumpStopEvent, s->cmdWakeEvent };
    for (;;) {
        DWORD wait = MsgWaitForMultipleObjectsEx(2, waitHandles, INFINITE,
            QS_ALLINPUT, MWMO_INPUTAVAILABLE);
        if (wait == WAIT_OBJECT_0) break;
        if (wait == WAIT_FAILED) {
            s->pumpThreadStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
            break;
        }
        while (PeekMessageW(&message, NULL, 0, 0, PM_REMOVE)) {
            if (message.message == WM_QUIT) {
                /* 线程消息（含 PostThreadMessage 的停止语义）记为原始退出，由
                   驱动侧转为 APPLICATION_EXIT_REQUESTED 事件。 */
                raw_ring_push(s, (uint32_t)WM_QUIT, 0u, 0, 0);
                continue;
            }
            TranslateMessage(&message);
            DispatchMessageW(&message);
        }
        drain_dispatcher_commands(s, 0);
    }
    /* 在窗口线程拆窗口；D3D 资源由驱动侧 destroy 在 join 后释放。 */
    if (s->hwnd) {
        DestroyWindow(s->hwnd);
        s->hwnd = NULL;
    }
    return 0;
}

/* ---- phase-2 导出封送层：C ABI 不变，执行一律进 UI 线程 ----
   约定：ctx 首字段恒为 token；IN 字符串/字节深拷贝；OUT 一律进 ctx 值域，
   OK 才回拷调用者指针；TIMEOUT 已由核心释放 ctx，IN_FLIGHT 归 hold 所有，
   其余失败由 wrapper 释放。 */

static CjguiInternalRendererStatus present_composable_scene_impl(uint64_t token,
    CjguiInternalRendererFrameObservation *outObservation);
static CjguiInternalRendererStatus present_clear_impl(uint64_t token,
    const CjguiInternalRendererClearColor *color,
    CjguiInternalRendererFrameObservation *outObservation);
static CjguiInternalRendererStatus acknowledge_present_impl(uint64_t token,
    uint64_t ticketId);
static CjguiInternalRendererStatus focus_composable_node_impl(uint64_t token,
    uint64_t nodeId);
static CjguiInternalRendererStatus activate_window_impl(uint64_t token);
static CjguiInternalRendererStatus set_window_title_impl(uint64_t token,
    const char *title);
static CjguiInternalRendererStatus request_close_impl(uint64_t token);
static CjguiInternalRendererStatus cancel_composable_pointer_capture_impl(
    uint64_t token);
static CjguiInternalRendererStatus cancel_composable_pointer_capture_epoch_impl(
    uint64_t token, uint64_t gestureEpoch);
static CjguiInternalRendererStatus cancel_composable_pointer_capture_gesture_key_impl(
    uint64_t token, uint64_t appInstance, uint64_t componentInstance,
    uint64_t surfaceGeneration, int64_t pointerId, uint64_t gestureEpoch);
static CjguiInternalRendererStatus composable_viewport_impl(uint64_t token,
    CjguiInternalRendererViewport *outViewport);
static CjguiInternalRendererStatus set_composable_scene_geometry_impl(
    uint64_t token, uint64_t projectionVersion, uint32_t nodeIndex,
    const CjguiInternalRendererComposableGeometry *geometry);
static CjguiInternalRendererStatus set_source_install_gate_impl(uint64_t token,
    uint64_t bindingEpoch, uint64_t requestId, uint8_t pending);
static CjguiInternalRendererStatus install_owned_source_selection_impl(
    uint64_t token, uint64_t nodeId, int64_t resourceId, uint64_t sceneVersion,
    uint64_t bindingEpoch, uint64_t requestId, uint64_t deadlineNs,
    const char *expectedValue, uint32_t selectionStart, uint32_t selectionEnd,
    uint32_t *outSelectionStart, uint32_t *outSelectionEnd, uint8_t *outDeferred);
static CjguiInternalRendererStatus restore_composable_selection_impl(
    uint64_t token, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
    uint64_t sceneVersion, const char *expectedValue, uint32_t selectionStart,
    uint32_t selectionEnd, uint32_t *outSelectionStart, uint32_t *outSelectionEnd);
static CjguiInternalRendererStatus read_composable_selection_impl(uint64_t token,
    uint64_t nodeId, int64_t resourceId, uint32_t nodeKind, uint64_t sceneVersion,
    const char *expectedValue, uint32_t *outSelectionStart,
    uint32_t *outSelectionEnd);
static CjguiInternalRendererStatus set_composable_owned_text_session_impl(
    uint64_t token, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
    uint64_t bindingEpoch, uint32_t enabled);
static CjguiInternalRendererStatus recover_active_text_proxy_impl(uint64_t token,
    uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
    const char *acceptedValue, uint32_t *outSelectionStart,
    uint32_t *outSelectionEnd);
static CjguiInternalRendererStatus reanchor_composition_impl(uint64_t token,
    uint64_t nodeId, int64_t resourceId, uint32_t nodeKind, uint64_t sceneVersion,
    const char *newBaseText, uint32_t replacementStart16,
    uint32_t replacementLength16, uint32_t *outMechanism,
    uint32_t *outMarkedStart16, uint32_t *outMarkedLength16,
    uint32_t *outInnerStart16, uint32_t *outInnerEnd16);
static CjguiInternalRendererStatus arm_composition_reanchor_impl(uint64_t token,
    uint64_t nodeId, int64_t resourceId, uint32_t nodeKind, const char *baseText,
    uint32_t replacementStart16, uint32_t replacementLength16);
static int32_t cancel_composition_impl(uint64_t token, int32_t *outHadMarked,
    int32_t *outCancelReturned);
static CjguiInternalRendererStatus installed_range_arm_impl(uint64_t token,
    const CjguiInternalInstalledRangeCandidate *candidate);
static CjguiInternalRendererStatus installed_range_receipt_impl(uint64_t token,
    uint64_t nonce, CjguiInternalInstalledRangeReceipt *receipt);
static CjguiInternalRendererStatus installed_range_active_receipt_impl(
    uint64_t token, uint64_t nonce, CjguiInternalInstalledRangeReceipt *receipt);
static CjguiInternalRendererStatus installed_range_activate_impl(uint64_t token,
    uint64_t nonce, uint64_t proxyGeneration, uint64_t selectionRevision);
static CjguiInternalRendererStatus installed_range_cancel_impl(uint64_t token,
    uint64_t nonce);
static CjguiInternalRendererStatus claim_last_pumped_range_impl(uint64_t token,
    uint64_t node, int64_t resource, uint64_t binding, uint64_t scene,
    CjguiInternalInstalledRangeIntent *intent);
static CjguiInternalRendererStatus copy_claimed_range_bytes_impl(uint64_t token,
    uint64_t seq, uint8_t *preBody, uint32_t preCapacity, uint8_t *replacement,
    uint32_t replacementCapacity, uint8_t *postBody, uint32_t postCapacity);
static CjguiInternalRendererStatus ack_installed_range_impl(uint64_t token,
    const CjguiInternalInstalledRangeIntent *intent, uint32_t accepted,
    int64_t versionAfter);
static CjguiInternalRendererStatus release_installed_range_impl(uint64_t token,
    uint64_t document, uint64_t binding);
static int32_t declare_input_caret_impl(uint64_t token, int64_t nodeId,
    double x, double y, double width, double height);
static CjguiInternalRendererStatus pumped_pointer_geometry_impl(uint64_t token,
    CjguiInternalRendererPointerEventGeometry *outGeometry);
static int32_t owner_consumed_pointer_coordinate_lifetime_impl(uint64_t token,
    uint64_t *outSessionGeneration, uint64_t *outCoordinateEpoch);
static const char *form_event_text_impl(uint64_t token);
static CjguiInternalRendererStatus node_rect_impl(uint64_t token, uint64_t nodeId,
    int64_t *outX, int64_t *outY, int64_t *outWidth, int64_t *outHeight);
static CjguiInternalRendererStatus query_present_impl(uint64_t token,
    uint64_t ticketId, CjguiInternalRendererPresentReceipt *outReceipt);
static CjguiInternalRendererStatus hit_test_composable_text_impl(uint64_t token,
    uint64_t nodeId, double x, double y, uint64_t expectedSceneVersion,
    uint32_t *outByteOffset, uint32_t *outAffinity);
static CjguiInternalRendererStatus text_position_v1_impl(uint64_t token,
    uint64_t nodeId, uint64_t expectedSceneVersion, uint32_t op,
    int64_t displayByte, uint32_t renderSide, uint64_t layoutLease,
    uint64_t stopId, uint32_t direction, double x, double y, uint64_t *meta,
    double *rect);
static uint64_t coordinate_lifetime_impl(uint64_t token,
    uint64_t *outSessionGeneration);
static CjguiInternalRendererStatus window_activation_state_impl(uint64_t token,
    int32_t *outKey, int32_t *outMain, int32_t *outAppActive);
static CjguiInternalRendererStatus window_frame_impl(uint64_t token,
    int64_t *outX, int64_t *outY, int64_t *outWidth, int64_t *outHeight);
static int replay_deferred_composition(CjguiWindowsRendererSession *s,
    CjguiWindowsDeferredInput *entry) {
    if (!s || !entry || (entry->kind != 2u && entry->kind != 3u)) return 0;
    if (entry->terminalQueued) {
        return !entry->extraBytes || remember_ime_successor(s,
            entry->extraBytes, entry->extraLength, entry->cursor16,
            entry->inputId, entry->bindingEpoch, entry->requestId,
            entry->compositionId);
    }
    if (s->compositionState == WINDOWS_COMPOSITION_IDLE) {
        if (!begin_windows_composition(s)) return 0;
    }
    if (s->compositionState != WINDOWS_COMPOSITION_MARKED) return 0;
    if (entry->compositionId != 0u &&
        entry->compositionId != s->activeCompositionId) return 0;
    if (s->compositionBindingEpoch != entry->bindingEpoch) return 0;
    if (entry->kind == 2u) {
        return queue_windows_composition_update(s,
            entry->bytes ? entry->bytes : "", entry->length, entry->cursor16);
    }
    int done = queue_windows_composition_terminal(s, entry->phase,
        entry->bytes ? entry->bytes : "", entry->length);
    if (!done) return 0;
    entry->terminalQueued = 1u;
    return !entry->extraBytes || remember_ime_successor(s,
        entry->extraBytes, entry->extraLength, entry->cursor16,
        entry->inputId, entry->bindingEpoch, entry->requestId,
        entry->compositionId);
}

static void deferred_free_entry(CjguiWindowsDeferredInput *entry) {
    if (!entry) return;
    free(entry->bytes);
    free(entry->extraBytes);
    memset(entry, 0, sizeof(*entry));
}

static void deferred_clear(CjguiWindowsRendererSession *s) {
    if (!s) return;
    for (uint32_t i = 0u; i < s->deferredCount; ++i) {
        uint32_t slot = (s->deferredHead + i) % CJGUI_WINDOWS_DEFERRED_CAPACITY;
        deferred_free_entry(&s->deferredInputs[slot]);
    }
    s->deferredHead = 0u;
    s->deferredCount = 0u;
    s->deferredBytes = 0u;
}

static void recovery_clear(CjguiWindowsRendererSession *s) {
    if (!s) return;
    for (uint32_t i = 0u; i < CJGUI_WINDOWS_RECOVERY_CAPACITY; ++i) {
        free(s->recoverySlots[i].bytes);
        free(s->recoverySlots[i].extraBytes);
        memset(&s->recoverySlots[i], 0, sizeof(s->recoverySlots[i]));
    }
    s->recoveryHead = 0u;
    s->recoveryCount = 0u;
}

static int stash_recovery(CjguiWindowsRendererSession *s, uint32_t reason,
    uint32_t outcome, uint64_t inputId, uint64_t bindingEpoch,
    uint64_t requestId, uint32_t kind, const char *bytes, uint32_t length,
    const char *extraBytes, uint32_t extraLength, int64_t modifiers,
    uint32_t repeatCount, uint64_t compositionId, uint32_t phase,
    uint32_t cursor16) {
    if (!s) return 0;
    if (s->recoveryCount >= CJGUI_WINDOWS_RECOVERY_CAPACITY) {
        s->recoveryDrops += 1u;
        return 0;
    }
    char *copy = NULL;
    if (length && bytes) {
        copy = (char *)malloc((size_t)length + 1u);
        if (!copy) {
            s->recoveryDrops += 1u;
            return 0;
        }
        memcpy(copy, bytes, length);
        copy[length] = '\0';
    }
    char *extraCopy = NULL;
    if (extraLength && extraBytes) {
        extraCopy = (char *)malloc((size_t)extraLength + 1u);
        if (!extraCopy) {
            free(copy);
            s->recoveryDrops += 1u;
            return 0;
        }
        memcpy(extraCopy, extraBytes, extraLength);
        extraCopy[extraLength] = '\0';
    }
    uint32_t slot = (s->recoveryHead + s->recoveryCount) %
        CJGUI_WINDOWS_RECOVERY_CAPACITY;
    s->recoverySlots[slot].bytes = copy;
    s->recoverySlots[slot].length = length;
    s->recoverySlots[slot].extraBytes = extraCopy;
    s->recoverySlots[slot].extraLength = extraLength;
    s->recoverySlots[slot].reason = reason;
    s->recoverySlots[slot].outcome = outcome;
    s->recoverySlots[slot].inputId = inputId;
    s->recoverySlots[slot].recordId = ++s->recoveryNextId;
    s->recoverySlots[slot].bindingEpoch = bindingEpoch;
    s->recoverySlots[slot].requestId = requestId;
    s->recoverySlots[slot].kind = kind;
    s->recoverySlots[slot].modifiers = modifiers;
    s->recoverySlots[slot].repeatCount = repeatCount;
    s->recoverySlots[slot].compositionId = compositionId;
    s->recoverySlots[slot].phase = phase;
    s->recoverySlots[slot].cursor16 = cursor16;
    s->recoveryCount += 1u;
    return 1;
}

/* 待决条目整记录转恢复：调用者在 stash 失败时不得弹出/释放原件。 */
static int stash_recovery_entry(CjguiWindowsRendererSession *s, uint32_t reason,
    uint32_t outcome, const CjguiWindowsDeferredInput *entry) {
    if (!entry) return 0;
    int accepted = stash_recovery(s, reason, outcome, entry->inputId,
        entry->bindingEpoch, entry->requestId, entry->kind,
        entry->bytes, entry->length, entry->extraBytes, entry->extraLength,
        entry->modifiers, entry->repeatCount, entry->compositionId,
        entry->phase, entry->cursor16);
    if (accepted) {
        uint32_t slot = (s->recoveryHead + s->recoveryCount - 1u) % CJGUI_WINDOWS_RECOVERY_CAPACITY;
        s->recoverySlots[slot].handledParts = entry->terminalQueued ? GCS_RESULTSTR : 0u;
    }
    return accepted;
}

static int defer_input(CjguiWindowsRendererSession *s, uint32_t kind,
    const char *bytes, uint32_t length, const char *extraBytes,
    uint32_t extraLength, int64_t modifiers, uint32_t repeatCount,
    uint64_t compositionId, uint32_t phase, uint32_t cursor16) {
    if (!s || !s->sourceInstallPending) return 0;
    uint64_t total = (uint64_t)length + (uint64_t)extraLength;
    uint64_t backlog = (uint64_t)s->deferredCount + (uint64_t)s->recoveryCount +
        (uint64_t)s->navHoldCount;
    if (s->deferredCount >= CJGUI_WINDOWS_DEFERRED_CAPACITY ||
        s->deferredBytes + total > CJGUI_WINDOWS_DEFERRED_BYTES ||
        length > CJGUI_WINDOWS_DEFERRED_IME_BYTES ||
        extraLength > CJGUI_WINDOWS_DEFERRED_IME_BYTES ||
        backlog + 1u > (uint64_t)CJGUI_WINDOWS_RECOVERY_CAPACITY +
            (uint64_t)CJGUI_WINDOWS_DEFERRED_CAPACITY +
            (uint64_t)CJGUI_WINDOWS_NAV_HOLD_CAPACITY) {
        s->deferredDrops += 1u;
        if (!stash_recovery(s, CJGUI_WINDOWS_RECOVERY_OVERFLOW,
                s->sourceInstallOutcome, s->deferredNextId,
                s->sourceInstallBindingEpoch, s->sourceInstallRequestId,
                kind, bytes, length, extraBytes, extraLength, modifiers,
                repeatCount, compositionId, phase, cursor16)) {
            s->eventQueueFull = 1u;
            return 0;
        }
        return 1;
    }
    uint32_t slot = (s->deferredHead + s->deferredCount) %
        CJGUI_WINDOWS_DEFERRED_CAPACITY;
    CjguiWindowsDeferredInput *entry = &s->deferredInputs[slot];
    memset(entry, 0, sizeof(*entry));
    if (length && bytes) {
        entry->bytes = (char *)malloc((size_t)length + 1u);
        if (!entry->bytes) {
            s->deferredDrops += 1u;
            s->eventQueueFull = 1u;
            return 0;
        }
        memcpy(entry->bytes, bytes, length);
        entry->bytes[length] = '\0';
    }
    if (extraLength && extraBytes) {
        entry->extraBytes = (char *)malloc((size_t)extraLength + 1u);
        if (!entry->extraBytes) {
            deferred_free_entry(entry);
            s->deferredDrops += 1u;
            s->eventQueueFull = 1u;
            return 0;
        }
        memcpy(entry->extraBytes, extraBytes, extraLength);
        entry->extraBytes[extraLength] = '\0';
    }
    entry->inputId = s->deferredNextId ? s->deferredNextId : 1u;
    s->deferredNextId = entry->inputId + 1u;
    if (s->deferredNextId == 0u) s->deferredNextId = 1u;
    entry->bindingEpoch = s->sourceInstallBindingEpoch;
    entry->requestId = s->sourceInstallRequestId;
    entry->kind = kind;
    entry->length = length;
    entry->extraLength = extraLength;
    entry->modifiers = modifiers;
    entry->repeatCount = repeatCount;
    entry->compositionId = compositionId;
    entry->phase = phase;
    entry->cursor16 = cursor16;
    s->deferredCount += 1u;
    s->deferredBytes += total;
    return 1;
}

static int nav_barrier_stash_to_recovery(CjguiWindowsRendererSession *s,
    uint32_t outcome) {
    if (!s || !s->navBarrierArmed) return 1;
    while (s->navHoldCount) {
        uint32_t slot = s->navHoldHead % CJGUI_WINDOWS_NAV_HOLD_CAPACITY;
        if (!stash_recovery(s, CJGUI_WINDOWS_RECOVERY_GATE_OUTCOME, outcome,
                s->navHold[slot].inputId, s->navHold[slot].bindingEpoch,
                s->navHold[slot].requestId,
                s->navHold[slot].isDelete ? 1u : 0u,
                s->navHold[slot].bytes, s->navHold[slot].length,
                NULL, 0u, s->navHold[slot].modifiers, 1u, 0u, 0u, 0u)) {
            s->eventQueueFull = 1u;
            return 0;
        }
        s->navHoldBytes -= s->navHold[slot].length;
        free(s->navHold[slot].bytes);
        memset(&s->navHold[slot], 0, sizeof(s->navHold[slot]));
        s->navHoldHead = (s->navHoldHead + 1u) % CJGUI_WINDOWS_NAV_HOLD_CAPACITY;
        s->navHoldCount -= 1u;
    }
    s->navBarrierArmed = 0u;
    return 1;
}

static void drain_deferred_inputs(CjguiWindowsRendererSession *s) {
    if (!s) return;
    uint64_t binding = s->sourceInstallConfirmedBinding;
    uint64_t request = s->sourceInstallConfirmedRequest;
    while (s->deferredCount > 0u) {
        CjguiWindowsDeferredInput *slot = &s->deferredInputs[s->deferredHead];
        int mismatched = (slot->bindingEpoch != binding || slot->requestId != request);
        int stashed = 0;
        int delivered = 0;
        if (mismatched) {
            stashed = stash_recovery_entry(s, CJGUI_WINDOWS_RECOVERY_GATE_OUTCOME,
                CJGUI_WINDOWS_INSTALL_OUTCOME_CONFLICT, slot);
        } else if (slot->kind == 0u) {
            delivered = queue_owned_range_replace(s,
                slot->bytes ? slot->bytes : "", slot->length, slot->modifiers,
                slot->repeatCount ? slot->repeatCount : 1u);
        } else if (slot->kind == 1u) {
            delivered = enqueue_windows_navigation(s,
                slot->bytes ? slot->bytes : "", slot->modifiers);
        } else {
            delivered = replay_deferred_composition(s, slot);
        }
        if (!mismatched && !delivered) {
            /* 队列压力不是来源冲突；原记录（含已交付分段进度）仍由本门
               持有，恢复容量后只继续尚未交付部分。 */
            s->eventQueueFull = 1u;
            break;
        }
        if (!stashed && !delivered) {
            s->eventQueueFull = 1u;
            break;
        }
        s->deferredBytes -= (uint64_t)slot->length + (uint64_t)slot->extraLength;
        deferred_free_entry(slot);
        s->deferredHead = (s->deferredHead + 1u) % CJGUI_WINDOWS_DEFERRED_CAPACITY;
        s->deferredCount -= 1u;
    }
}

static void settle_gate_locked(CjguiWindowsRendererSession *s, uint32_t outcome) {
    s->sourceInstallOutcome = outcome;
    s->sourceInstallPending = 0u;
    s->sourceInstallBindingEpoch = 0u;
    s->sourceInstallRequestId = 0u;
    s->sourceInstallProvisional = 0u;
    s->sourceInstallProvisionalNonce = 0u;
}

static CjguiInternalRendererStatus finish_source_install_impl(uint64_t token,
    uint64_t requestId, uint32_t outcome, uint64_t receiptNonce) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (outcome < CJGUI_WINDOWS_FINISH_CONFIRMED ||
        outcome > CJGUI_WINDOWS_FINISH_CLOSED || requestId == 0u)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (!s->sourceInstallPending ||
        s->sourceInstallRequestId != requestId) {
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    if (outcome == CJGUI_WINDOWS_FINISH_CONFIRMED) {
        if (!s->sourceInstallProvisional || s->sourceInstallProvisionalNonce == 0u ||
            receiptNonce != s->sourceInstallProvisionalNonce) {
            return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
        }
        s->sourceInstallConfirmedBinding = s->sourceInstallBindingEpoch;
        s->sourceInstallConfirmedRequest = s->sourceInstallRequestId;
        s->sourceInstallPending = 0u;
        s->sourceInstallOutcome = CJGUI_WINDOWS_INSTALL_OUTCOME_OWNER_CONFIRMED;
        {
            /* drain 可能送达新的导航并立起新屏障（epoch 推进）；旧确认只结清
               原请求，新屏障须等其导航裁决与新选区安装确认，不得在此放行。
               新屏障由随后的新安装入口释放并重放。 */
            uint64_t barrierBefore = s->navBarrierEpoch;
            drain_deferred_inputs(s);
            int navDelivered = s->navBarrierEpoch != barrierBefore || nav_barrier_release(s, 1);
            if (s->deferredCount || !navDelivered) {
                s->sourceInstallPending = 1u;
                return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
            }
        }
        settle_gate_locked(s, CJGUI_WINDOWS_INSTALL_OUTCOME_OWNER_CONFIRMED);
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    uint32_t nativeOutcome = CJGUI_WINDOWS_INSTALL_OUTCOME_OWNER_CANCELLED;
    if (outcome == CJGUI_WINDOWS_FINISH_SUPERSEDED)
        nativeOutcome = CJGUI_WINDOWS_INSTALL_OUTCOME_SUPERSEDED;
    else if (outcome == CJGUI_WINDOWS_FINISH_CONFLICT)
        nativeOutcome = CJGUI_WINDOWS_INSTALL_OUTCOME_CONFLICT;
    else if (outcome == CJGUI_WINDOWS_FINISH_CLOSED)
        nativeOutcome = CJGUI_WINDOWS_INSTALL_OUTCOME_CLOSED;
    while (s->deferredCount > 0u) {
        CjguiWindowsDeferredInput *entry =
            &s->deferredInputs[s->deferredHead];
        if (!stash_recovery_entry(s, CJGUI_WINDOWS_RECOVERY_GATE_OUTCOME,
                nativeOutcome, entry)) {
            s->eventQueueFull = 1u;
            return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
        }
        s->deferredBytes -= (uint64_t)entry->length + (uint64_t)entry->extraLength;
        deferred_free_entry(entry);
        s->deferredHead = (s->deferredHead + 1u) % CJGUI_WINDOWS_DEFERRED_CAPACITY;
        s->deferredCount -= 1u;
    }
    if (!nav_barrier_stash_to_recovery(s, nativeOutcome))
        return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
    settle_gate_locked(s, nativeOutcome);
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus diagnostic_resources_impl(uint64_t token,
    CjguiInternalRendererDiagnosticResources *outResources);
static CjguiInternalRendererStatus diagnostic_timing_impl(uint64_t token,
    CjguiInternalRendererDiagnosticTiming *outTiming);
static CjguiInternalRendererStatus diagnostic_workload_impl(uint64_t token,
    CjguiInternalRendererDiagnosticWorkload *outWorkload);
static CjguiInternalRendererStatus composable_display_progress_impl(
    uint64_t token, CjguiInternalRendererComposableDisplayProgress *outProgress);
static CjguiInternalRendererStatus composable_image_resource_state_impl(
    uint64_t token, const char *resourcePath, const char *resourceId,
    uint64_t resourceVersion, uint32_t *outState);

typedef struct CjguiWindowsTokenCtx {
    uint64_t token;
} CjguiWindowsTokenCtx;

typedef struct CjguiWindowsPresentCtx {
    uint64_t token, ticketId;
    CjguiInternalRendererFrameObservation obs;
    volatile LONG references, dispatchReferenceReleased;
} CjguiWindowsPresentCtx;

static void present_ctx_release(CjguiWindowsPresentCtx *ctx) {
    if (InterlockedDecrement(&ctx->references) == 0) free(ctx);
}
static void present_ctx_dispatch_release(void *raw) {
    CjguiWindowsPresentCtx *ctx = (CjguiWindowsPresentCtx *)raw;
    if (InterlockedCompareExchange(&ctx->dispatchReferenceReleased, 1, 0) == 0)
        present_ctx_release(ctx);
}
static CjguiInternalRendererStatus cjgui_windows_present_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    CjguiWindowsPresentCtx *c = (CjguiWindowsPresentCtx *)raw;
    EnterCriticalSection(&g_sessionLock);
    if (s->presentReceipt.ticketId != c->ticketId) {
        LeaveCriticalSection(&g_sessionLock);
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    s->presentReceipt.projectionVersion = s->candidateScene.version;
    LeaveCriticalSection(&g_sessionLock);
    CjguiInternalRendererStatus st = present_composable_scene_impl(c->token, &c->obs);
    EnterCriticalSection(&g_sessionLock);
    if (s->presentReceipt.ticketId == c->ticketId && !s->presentReceipt.settled) {
        CjguiInternalRendererPresentReceipt *r = &s->presentReceipt;
        r->decision = st == CJGUI_INTERNAL_RENDERER_OK ?
            CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED : CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_REJECTED;
        r->terminalStatus = st;
        r->settled = 1u;
        r->resyncRequired = st != CJGUI_INTERNAL_RENDERER_OK;
        if (st == CJGUI_INTERNAL_RENDERER_OK) {
            r->observation = c->obs;
            r->observation.ticketId = c->ticketId;
        }
        if (s->presentReceiptPublished) {
            if (st == CJGUI_INTERNAL_RENDERER_OK) ++s->presentTicketAcceptedCount;
            else ++s->presentTicketRejectedCount;
        }
    }
    LeaveCriticalSection(&g_sessionLock);
    return st;
}

CjguiInternalRendererStatus cjgui_internal_renderer_present_composable_scene(
    uint64_t token, CjguiInternalRendererFrameObservation *outObservation) {
    if (!outObservation) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    memset(outObservation, 0, sizeof(*outObservation));
    CjguiWindowsPresentCtx *ctx = (CjguiWindowsPresentCtx *)calloc(1u, sizeof(*ctx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token; ctx->references = 2;
    ensure_session_lock();
    EnterCriticalSection(&g_sessionLock);
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s || s->presentClosing) {
        LeaveCriticalSection(&g_sessionLock);
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    if (s->presentReceipt.ticketId) {
        publish_present_receipt_locked(s);
        outObservation->ticketId = s->presentReceipt.ticketId;
        LeaveCriticalSection(&g_sessionLock);
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
    }
    if (s->presentationTicketNext == UINT64_MAX) {
        LeaveCriticalSection(&g_sessionLock); free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    ctx->ticketId = ++s->presentationTicketNext;
    s->presentReceipt.ticketId = ctx->ticketId;
    s->presentReceipt.decision = CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_PENDING;
    uint64_t ticket = ctx->ticketId;
    LeaveCriticalSection(&g_sessionLock);
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "present",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_present_proc, ctx,
        present_ctx_dispatch_release, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    EnterCriticalSection(&g_sessionLock);
    s = find_session(token);
    if (s && s->presentReceipt.ticketId == ticket) {
        if (st == CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT || s->presentReceiptPublished) {
            publish_present_receipt_locked(s);
            outObservation->ticketId = ticket;
            st = CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
        } else {
            if (st == CJGUI_INTERNAL_RENDERER_OK) *outObservation = ctx->obs;
            memset(&s->presentReceipt, 0, sizeof(s->presentReceipt));
        }
    }
    LeaveCriticalSection(&g_sessionLock);
    // 38 transfers the dispatch reference to the existing orphan hold/reap.
    // The caller reference keeps ctx alive even when a queued timeout/cancel
    // already invoked its destructor; release each reference exactly once.
    if (cmdId == 0u || st != CJGUI_INTERNAL_RENDERER_PRESENT_PENDING)
        present_ctx_dispatch_release(ctx);
    present_ctx_release(ctx);
    return st;
}

typedef struct CjguiWindowsPresentClearCtx {
    uint64_t token;
    CjguiInternalRendererClearColor color;
    int hasColor;
    CjguiInternalRendererFrameObservation obs;
} CjguiWindowsPresentClearCtx;

static CjguiInternalRendererStatus cjgui_windows_present_clear_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsPresentClearCtx *c = (CjguiWindowsPresentClearCtx *)raw;
    return present_clear_impl(c->token, c->hasColor ? &c->color : NULL, &c->obs);
}

CjguiInternalRendererStatus cjgui_internal_renderer_present_clear(uint64_t token,
    const CjguiInternalRendererClearColor *color,
    CjguiInternalRendererFrameObservation *outObservation) {
    if (!outObservation) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsPresentClearCtx *ctx =
        (CjguiWindowsPresentClearCtx *)calloc(1u, sizeof(CjguiWindowsPresentClearCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    if (color) {
        ctx->color = *color;
        ctx->hasColor = 1;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "present_clear",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_present_clear_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) *outObservation = ctx->obs;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsU64Ctx {
    uint64_t token;
    uint64_t value;
} CjguiWindowsU64Ctx;

static CjguiInternalRendererStatus cjgui_windows_acknowledge_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsU64Ctx *c = (CjguiWindowsU64Ctx *)raw;
    return acknowledge_present_impl(c->token, c->value);
}

CjguiInternalRendererStatus cjgui_internal_renderer_acknowledge_present(
    uint64_t token, uint64_t ticketId) {
    return acknowledge_present_impl(token, ticketId);
}


static CjguiInternalRendererStatus cjgui_windows_focus_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsU64Ctx *c = (CjguiWindowsU64Ctx *)raw;
    return focus_composable_node_impl(c->token, c->value);
}

CjguiInternalRendererStatus cjgui_internal_renderer_focus_composable_node(
    uint64_t token, uint64_t nodeId) {
    CjguiWindowsU64Ctx *ctx =
        (CjguiWindowsU64Ctx *)calloc(1u, sizeof(CjguiWindowsU64Ctx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->value = nodeId;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "focus_node",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_focus_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_activate_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsTokenCtx *c = (CjguiWindowsTokenCtx *)raw;
    return activate_window_impl(c->token);
}

CjguiInternalRendererStatus cjgui_internal_renderer_activate_window(uint64_t token) {
    CjguiWindowsTokenCtx *ctx =
        (CjguiWindowsTokenCtx *)calloc(1u, sizeof(CjguiWindowsTokenCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "activate",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_activate_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsTitleCtx {
    uint64_t token;
    char *title;
} CjguiWindowsTitleCtx;

static void cjgui_windows_title_free(void *raw) {
    CjguiWindowsTitleCtx *c = (CjguiWindowsTitleCtx *)raw;
    if (!c) return;
    free(c->title);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_title_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsTitleCtx *c = (CjguiWindowsTitleCtx *)raw;
    return set_window_title_impl(c->token, c->title);
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_window_title(
    uint64_t token, const char *title) {
    CjguiWindowsTitleCtx *ctx =
        (CjguiWindowsTitleCtx *)calloc(1u, sizeof(CjguiWindowsTitleCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->title = cjgui_windows_dup_string(title);
    if (title && !ctx->title) {
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "set_title",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_title_proc, ctx,
        cjgui_windows_title_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_title_free(ctx);
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_request_close_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsTokenCtx *c = (CjguiWindowsTokenCtx *)raw;
    return request_close_impl(c->token);
}

CjguiInternalRendererStatus cjgui_internal_renderer_request_close(uint64_t token) {
    CjguiWindowsTokenCtx *ctx =
        (CjguiWindowsTokenCtx *)calloc(1u, sizeof(CjguiWindowsTokenCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "request_close",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_request_close_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_cancel_capture_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsTokenCtx *c = (CjguiWindowsTokenCtx *)raw;
    return cancel_composable_pointer_capture_impl(c->token);
}

CjguiInternalRendererStatus cjgui_internal_renderer_cancel_composable_pointer_capture(
    uint64_t token) {
    CjguiWindowsTokenCtx *ctx =
        (CjguiWindowsTokenCtx *)calloc(1u, sizeof(CjguiWindowsTokenCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "cancel_capture",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_cancel_capture_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_cancel_epoch_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsU64Ctx *c = (CjguiWindowsU64Ctx *)raw;
    return cancel_composable_pointer_capture_epoch_impl(c->token, c->value);
}

CjguiInternalRendererStatus cjgui_internal_renderer_cancel_composable_pointer_capture_epoch(
    uint64_t token, uint64_t gestureEpoch) {
    CjguiWindowsU64Ctx *ctx =
        (CjguiWindowsU64Ctx *)calloc(1u, sizeof(CjguiWindowsU64Ctx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->value = gestureEpoch;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "cancel_epoch",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_cancel_epoch_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsGestureKeyCtx {
    uint64_t token;
    uint64_t appInstance;
    uint64_t componentInstance;
    uint64_t surfaceGeneration;
    int64_t pointerId;
    uint64_t gestureEpoch;
} CjguiWindowsGestureKeyCtx;

static CjguiInternalRendererStatus cjgui_windows_cancel_key_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsGestureKeyCtx *c = (CjguiWindowsGestureKeyCtx *)raw;
    return cancel_composable_pointer_capture_gesture_key_impl(c->token,
        c->appInstance, c->componentInstance, c->surfaceGeneration,
        c->pointerId, c->gestureEpoch);
}

CjguiInternalRendererStatus cjgui_internal_renderer_cancel_composable_pointer_capture_gesture_key(
    uint64_t token, uint64_t appInstance, uint64_t componentInstance,
    uint64_t surfaceGeneration, int64_t pointerId, uint64_t gestureEpoch) {
    CjguiWindowsGestureKeyCtx *ctx =
        (CjguiWindowsGestureKeyCtx *)calloc(1u, sizeof(CjguiWindowsGestureKeyCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->appInstance = appInstance;
    ctx->componentInstance = componentInstance;
    ctx->surfaceGeneration = surfaceGeneration;
    ctx->pointerId = pointerId;
    ctx->gestureEpoch = gestureEpoch;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "cancel_key",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_cancel_key_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsViewportCtx {
    uint64_t token;
    CjguiInternalRendererViewport viewport;
} CjguiWindowsViewportCtx;

static CjguiInternalRendererStatus cjgui_windows_viewport_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsViewportCtx *c = (CjguiWindowsViewportCtx *)raw;
    return composable_viewport_impl(c->token, &c->viewport);
}

CjguiInternalRendererStatus cjgui_internal_renderer_composable_viewport(
    uint64_t token, CjguiInternalRendererViewport *outViewport) {
    if (!outViewport) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsViewportCtx *ctx =
        (CjguiWindowsViewportCtx *)calloc(1u, sizeof(CjguiWindowsViewportCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "viewport",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_viewport_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) *outViewport = ctx->viewport;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsGeometryCtx {
    uint64_t token;
    uint64_t projectionVersion;
    uint32_t nodeIndex;
    CjguiInternalRendererComposableGeometry geometry;
    int hasGeometry;
} CjguiWindowsGeometryCtx;

static CjguiInternalRendererStatus cjgui_windows_geometry_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsGeometryCtx *c = (CjguiWindowsGeometryCtx *)raw;
    return set_composable_scene_geometry_impl(c->token, c->projectionVersion,
        c->nodeIndex, c->hasGeometry ? &c->geometry : NULL);
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_scene_geometry(
    uint64_t token, uint64_t projectionVersion, uint32_t nodeIndex,
    const CjguiInternalRendererComposableGeometry *geometry) {
    CjguiWindowsGeometryCtx *ctx =
        (CjguiWindowsGeometryCtx *)calloc(1u, sizeof(CjguiWindowsGeometryCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->projectionVersion = projectionVersion;
    ctx->nodeIndex = nodeIndex;
    if (geometry) {
        ctx->geometry = *geometry;
        ctx->hasGeometry = 1;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "set_geometry",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_geometry_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsInstallGateCtx {
    uint64_t token;
    uint64_t bindingEpoch;
    uint64_t requestId;
    uint8_t pending;
} CjguiWindowsInstallGateCtx;

static CjguiInternalRendererStatus cjgui_windows_install_gate_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsInstallGateCtx *c = (CjguiWindowsInstallGateCtx *)raw;
    return set_source_install_gate_impl(c->token, c->bindingEpoch,
        c->requestId, c->pending);
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_source_install_gate(
    uint64_t token, uint64_t bindingEpoch, uint64_t requestId, uint8_t pending) {
    CjguiWindowsInstallGateCtx *ctx =
        (CjguiWindowsInstallGateCtx *)calloc(1u, sizeof(CjguiWindowsInstallGateCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->bindingEpoch = bindingEpoch;
    ctx->requestId = requestId;
    ctx->pending = pending;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "install_gate",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_install_gate_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsInstallCtx {
    uint64_t token;
    uint64_t nodeId;
    int64_t resourceId;
    uint64_t sceneVersion;
    uint64_t bindingEpoch;
    uint64_t requestId;
    uint64_t deadlineNs;
    char *expectedValue;
    uint32_t selectionStart;
    uint32_t selectionEnd;
    uint32_t outSelectionStart;
    uint32_t outSelectionEnd;
    uint8_t outDeferred;
} CjguiWindowsInstallCtx;

static void cjgui_windows_install_free(void *raw) {
    CjguiWindowsInstallCtx *c = (CjguiWindowsInstallCtx *)raw;
    if (!c) return;
    free(c->expectedValue);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_install_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsInstallCtx *c = (CjguiWindowsInstallCtx *)raw;
    return install_owned_source_selection_impl(c->token, c->nodeId,
        c->resourceId, c->sceneVersion, c->bindingEpoch, c->requestId,
        c->deadlineNs, c->expectedValue, c->selectionStart, c->selectionEnd,
        &c->outSelectionStart, &c->outSelectionEnd, &c->outDeferred);
}

CjguiInternalRendererStatus cjgui_internal_renderer_install_owned_source_selection(
    uint64_t token, uint64_t nodeId, int64_t resourceId, uint64_t sceneVersion,
    uint64_t bindingEpoch, uint64_t requestId, uint64_t deadlineNs,
    const char *expectedValue, uint32_t selectionStart, uint32_t selectionEnd,
    uint32_t *outSelectionStart, uint32_t *outSelectionEnd, uint8_t *outDeferred) {
    if (!outSelectionStart || !outSelectionEnd || !outDeferred)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outSelectionStart = 0u;
    *outSelectionEnd = 0u;
    *outDeferred = 0u;
    CjguiWindowsInstallCtx *ctx =
        (CjguiWindowsInstallCtx *)calloc(1u, sizeof(CjguiWindowsInstallCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeId = nodeId;
    ctx->resourceId = resourceId;
    ctx->sceneVersion = sceneVersion;
    ctx->bindingEpoch = bindingEpoch;
    ctx->requestId = requestId;
    ctx->deadlineNs = deadlineNs;
    ctx->expectedValue = cjgui_windows_dup_string(expectedValue);
    if (expectedValue && !ctx->expectedValue) {
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    ctx->selectionStart = selectionStart;
    ctx->selectionEnd = selectionEnd;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "install_owned",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_install_proc, ctx,
        cjgui_windows_install_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    // PRESENT_PENDING is a completed installation attempt whose outDeferred
    // fact keeps the same common request alive. It is not a dispatch timeout:
    // ctx is still caller-owned here, and no proxy/range was installed.
    if (st == CJGUI_INTERNAL_RENDERER_OK || st == CJGUI_INTERNAL_RENDERER_PRESENT_PENDING) {
        *outSelectionStart = ctx->outSelectionStart;
        *outSelectionEnd = ctx->outSelectionEnd;
        *outDeferred = ctx->outDeferred;
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_install_free(ctx);
    return st;
}

typedef struct CjguiWindowsRestoreCtx {
    uint64_t token;
    uint64_t nodeId;
    int64_t resourceId;
    uint32_t nodeKind;
    uint64_t sceneVersion;
    char *expectedValue;
    uint32_t selectionStart;
    uint32_t selectionEnd;
    uint32_t outSelectionStart;
    uint32_t outSelectionEnd;
} CjguiWindowsRestoreCtx;

static void cjgui_windows_restore_free(void *raw) {
    CjguiWindowsRestoreCtx *c = (CjguiWindowsRestoreCtx *)raw;
    if (!c) return;
    free(c->expectedValue);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_restore_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsRestoreCtx *c = (CjguiWindowsRestoreCtx *)raw;
    return restore_composable_selection_impl(c->token, c->nodeId,
        c->resourceId, c->nodeKind, c->sceneVersion, c->expectedValue,
        c->selectionStart, c->selectionEnd, &c->outSelectionStart,
        &c->outSelectionEnd);
}

CjguiInternalRendererStatus cjgui_internal_renderer_restore_composable_selection(
    uint64_t token, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
    uint64_t sceneVersion, const char *expectedValue, uint32_t selectionStart,
    uint32_t selectionEnd, uint32_t *outSelectionStart, uint32_t *outSelectionEnd) {
    if (!outSelectionStart || !outSelectionEnd)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsRestoreCtx *ctx =
        (CjguiWindowsRestoreCtx *)calloc(1u, sizeof(CjguiWindowsRestoreCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeId = nodeId;
    ctx->resourceId = resourceId;
    ctx->nodeKind = nodeKind;
    ctx->sceneVersion = sceneVersion;
    ctx->expectedValue = cjgui_windows_dup_string(expectedValue);
    if (expectedValue && !ctx->expectedValue) {
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    ctx->selectionStart = selectionStart;
    ctx->selectionEnd = selectionEnd;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "restore_sel",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_restore_proc, ctx,
        cjgui_windows_restore_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outSelectionStart = ctx->outSelectionStart;
        *outSelectionEnd = ctx->outSelectionEnd;
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_restore_free(ctx);
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_read_sel_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsRestoreCtx *c = (CjguiWindowsRestoreCtx *)raw;
    return read_composable_selection_impl(c->token, c->nodeId, c->resourceId,
        c->nodeKind, c->sceneVersion, c->expectedValue, &c->outSelectionStart,
        &c->outSelectionEnd);
}

CjguiInternalRendererStatus cjgui_internal_renderer_read_composable_selection(
    uint64_t token, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
    uint64_t sceneVersion, const char *expectedValue, uint32_t *outSelectionStart,
    uint32_t *outSelectionEnd) {
    if (!outSelectionStart || !outSelectionEnd)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsRestoreCtx *ctx =
        (CjguiWindowsRestoreCtx *)calloc(1u, sizeof(CjguiWindowsRestoreCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeId = nodeId;
    ctx->resourceId = resourceId;
    ctx->nodeKind = nodeKind;
    ctx->sceneVersion = sceneVersion;
    ctx->expectedValue = cjgui_windows_dup_string(expectedValue);
    if (expectedValue && !ctx->expectedValue) {
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "read_sel",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_read_sel_proc, ctx,
        cjgui_windows_restore_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outSelectionStart = ctx->outSelectionStart;
        *outSelectionEnd = ctx->outSelectionEnd;
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_restore_free(ctx);
    return st;
}

typedef struct CjguiWindowsOwnedSessionCtx {
    uint64_t token;
    uint64_t nodeId;
    int64_t resourceId;
    uint32_t nodeKind;
    uint64_t bindingEpoch;
    uint32_t enabled;
} CjguiWindowsOwnedSessionCtx;

static CjguiInternalRendererStatus cjgui_windows_owned_session_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsOwnedSessionCtx *c = (CjguiWindowsOwnedSessionCtx *)raw;
    return set_composable_owned_text_session_impl(c->token, c->nodeId,
        c->resourceId, c->nodeKind, c->bindingEpoch, c->enabled);
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_owned_text_session(
    uint64_t token, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
    uint64_t bindingEpoch, uint32_t enabled) {
    CjguiWindowsOwnedSessionCtx *ctx =
        (CjguiWindowsOwnedSessionCtx *)calloc(1u, sizeof(CjguiWindowsOwnedSessionCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeId = nodeId;
    ctx->resourceId = resourceId;
    ctx->nodeKind = nodeKind;
    ctx->bindingEpoch = bindingEpoch;
    ctx->enabled = enabled;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "owned_session",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_owned_session_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_recover_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsRestoreCtx *c = (CjguiWindowsRestoreCtx *)raw;
    return recover_active_text_proxy_impl(c->token, c->nodeId, c->resourceId,
        c->nodeKind, c->expectedValue, &c->outSelectionStart,
        &c->outSelectionEnd);
}

CjguiInternalRendererStatus cjgui_internal_renderer_recover_active_text_proxy(
    uint64_t token, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
    const char *acceptedValue, uint32_t *outSelectionStart,
    uint32_t *outSelectionEnd) {
    if (!outSelectionStart || !outSelectionEnd)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsRestoreCtx *ctx =
        (CjguiWindowsRestoreCtx *)calloc(1u, sizeof(CjguiWindowsRestoreCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeId = nodeId;
    ctx->resourceId = resourceId;
    ctx->nodeKind = nodeKind;
    ctx->expectedValue = cjgui_windows_dup_string(acceptedValue);
    if (acceptedValue && !ctx->expectedValue) {
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "recover_proxy",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_recover_proc, ctx,
        cjgui_windows_restore_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outSelectionStart = ctx->outSelectionStart;
        *outSelectionEnd = ctx->outSelectionEnd;
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_restore_free(ctx);
    return st;
}

typedef struct CjguiWindowsReanchorCtx {
    uint64_t token;
    uint64_t nodeId;
    int64_t resourceId;
    uint32_t nodeKind;
    uint64_t sceneVersion;
    char *baseText;
    uint32_t replacementStart16;
    uint32_t replacementLength16;
    uint32_t outMechanism;
    uint32_t outMarkedStart16;
    uint32_t outMarkedLength16;
    uint32_t outInnerStart16;
    uint32_t outInnerEnd16;
} CjguiWindowsReanchorCtx;

static void cjgui_windows_reanchor_free(void *raw) {
    CjguiWindowsReanchorCtx *c = (CjguiWindowsReanchorCtx *)raw;
    if (!c) return;
    free(c->baseText);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_reanchor_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsReanchorCtx *c = (CjguiWindowsReanchorCtx *)raw;
    return reanchor_composition_impl(c->token, c->nodeId, c->resourceId,
        c->nodeKind, c->sceneVersion, c->baseText, c->replacementStart16,
        c->replacementLength16, &c->outMechanism, &c->outMarkedStart16,
        &c->outMarkedLength16, &c->outInnerStart16, &c->outInnerEnd16);
}

CjguiInternalRendererStatus cjgui_internal_renderer_reanchor_composition(
    uint64_t token, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
    uint64_t sceneVersion, const char *newBaseText, uint32_t replacementStart16,
    uint32_t replacementLength16, uint32_t *outMechanism,
    uint32_t *outMarkedStart16, uint32_t *outMarkedLength16,
    uint32_t *outInnerStart16, uint32_t *outInnerEnd16) {
    if (!outMechanism || !outMarkedStart16 || !outMarkedLength16 ||
        !outInnerStart16 || !outInnerEnd16)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsReanchorCtx *ctx =
        (CjguiWindowsReanchorCtx *)calloc(1u, sizeof(CjguiWindowsReanchorCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeId = nodeId;
    ctx->resourceId = resourceId;
    ctx->nodeKind = nodeKind;
    ctx->sceneVersion = sceneVersion;
    ctx->baseText = cjgui_windows_dup_string(newBaseText);
    if (newBaseText && !ctx->baseText) {
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    ctx->replacementStart16 = replacementStart16;
    ctx->replacementLength16 = replacementLength16;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "reanchor",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_reanchor_proc, ctx,
        cjgui_windows_reanchor_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outMechanism = ctx->outMechanism;
        *outMarkedStart16 = ctx->outMarkedStart16;
        *outMarkedLength16 = ctx->outMarkedLength16;
        *outInnerStart16 = ctx->outInnerStart16;
        *outInnerEnd16 = ctx->outInnerEnd16;
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_reanchor_free(ctx);
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_arm_reanchor_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsReanchorCtx *c = (CjguiWindowsReanchorCtx *)raw;
    return arm_composition_reanchor_impl(c->token, c->nodeId, c->resourceId,
        c->nodeKind, c->baseText, c->replacementStart16,
        c->replacementLength16);
}

CjguiInternalRendererStatus cjgui_internal_renderer_arm_composition_reanchor(
    uint64_t token, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
    const char *baseText, uint32_t replacementStart16,
    uint32_t replacementLength16) {
    CjguiWindowsReanchorCtx *ctx =
        (CjguiWindowsReanchorCtx *)calloc(1u, sizeof(CjguiWindowsReanchorCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeId = nodeId;
    ctx->resourceId = resourceId;
    ctx->nodeKind = nodeKind;
    ctx->baseText = cjgui_windows_dup_string(baseText);
    if (baseText && !ctx->baseText) {
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    ctx->replacementStart16 = replacementStart16;
    ctx->replacementLength16 = replacementLength16;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "arm_reanchor",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_arm_reanchor_proc, ctx,
        cjgui_windows_reanchor_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_reanchor_free(ctx);
    return st;
}

typedef struct CjguiWindowsCancelCompCtx {
    uint64_t token;
    int32_t result;
    int32_t outHadMarked;
    int32_t outCancelReturned;
} CjguiWindowsCancelCompCtx;

static CjguiInternalRendererStatus cjgui_windows_cancel_comp_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsCancelCompCtx *c = (CjguiWindowsCancelCompCtx *)raw;
    c->result = cancel_composition_impl(c->token, &c->outHadMarked,
        &c->outCancelReturned);
    return (CjguiInternalRendererStatus)c->result;
}

int32_t cjgui_internal_renderer_cancel_composition(uint64_t token,
    int32_t *outHadMarked, int32_t *outCancelReturned) {
    if (!outHadMarked || !outCancelReturned)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsCancelCompCtx *ctx =
        (CjguiWindowsCancelCompCtx *)calloc(1u, sizeof(CjguiWindowsCancelCompCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "cancel_comp",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_cancel_comp_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    int32_t result = (int32_t)st;
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outHadMarked = ctx->outHadMarked;
        *outCancelReturned = ctx->outCancelReturned;
        result = ctx->result;
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return result;
}

typedef struct CjguiWindowsRangeArmCtx {
    uint64_t token;
    CjguiInternalInstalledRangeCandidate candidate;
    uint8_t *sourceText;
} CjguiWindowsRangeArmCtx;

static void cjgui_windows_range_arm_free(void *raw) {
    CjguiWindowsRangeArmCtx *c = (CjguiWindowsRangeArmCtx *)raw;
    if (!c) return;
    free(c->sourceText);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_range_arm_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsRangeArmCtx *c = (CjguiWindowsRangeArmCtx *)raw;
    c->candidate.sourceTextUtf8 = c->sourceText;
    return installed_range_arm_impl(c->token, &c->candidate);
}

CjguiInternalRendererStatus cjgui_internal_renderer_installed_range_arm(
    uint64_t token, const CjguiInternalInstalledRangeCandidate *candidate) {
    if (!candidate) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsRangeArmCtx *ctx =
        (CjguiWindowsRangeArmCtx *)calloc(1u, sizeof(CjguiWindowsRangeArmCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->candidate = *candidate;
    ctx->candidate.sourceTextUtf8 = NULL;
    ctx->sourceText = cjgui_windows_dup_bytes(candidate->sourceTextUtf8,
        candidate->sourceTextUtf8Length);
    if (candidate->sourceTextUtf8Length && !ctx->sourceText) {
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "range_arm",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_range_arm_proc, ctx,
        cjgui_windows_range_arm_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_range_arm_free(ctx);
    return st;
}

typedef struct CjguiWindowsRangeReceiptCtx {
    uint64_t token;
    uint64_t nonce;
    CjguiInternalInstalledRangeReceipt receipt;
} CjguiWindowsRangeReceiptCtx;

static CjguiInternalRendererStatus cjgui_windows_range_receipt_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsRangeReceiptCtx *c = (CjguiWindowsRangeReceiptCtx *)raw;
    return installed_range_receipt_impl(c->token, c->nonce, &c->receipt);
}

CjguiInternalRendererStatus cjgui_internal_renderer_installed_range_receipt(
    uint64_t token, uint64_t nonce, CjguiInternalInstalledRangeReceipt *receipt) {
    if (!receipt) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsRangeReceiptCtx *ctx =
        (CjguiWindowsRangeReceiptCtx *)calloc(1u, sizeof(CjguiWindowsRangeReceiptCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nonce = nonce;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "range_receipt",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_range_receipt_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) *receipt = ctx->receipt;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_range_active_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsRangeReceiptCtx *c = (CjguiWindowsRangeReceiptCtx *)raw;
    return installed_range_active_receipt_impl(c->token, c->nonce, &c->receipt);
}

CjguiInternalRendererStatus cjgui_internal_renderer_installed_range_active_receipt(
    uint64_t token, uint64_t nonce, CjguiInternalInstalledRangeReceipt *receipt) {
    if (!receipt) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsRangeReceiptCtx *ctx =
        (CjguiWindowsRangeReceiptCtx *)calloc(1u, sizeof(CjguiWindowsRangeReceiptCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nonce = nonce;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "range_active",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_range_active_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) *receipt = ctx->receipt;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsRangeActivateCtx {
    uint64_t token;
    uint64_t nonce;
    uint64_t proxyGeneration;
    uint64_t selectionRevision;
} CjguiWindowsRangeActivateCtx;

static CjguiInternalRendererStatus cjgui_windows_range_activate_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsRangeActivateCtx *c = (CjguiWindowsRangeActivateCtx *)raw;
    return installed_range_activate_impl(c->token, c->nonce,
        c->proxyGeneration, c->selectionRevision);
}

CjguiInternalRendererStatus cjgui_internal_renderer_installed_range_activate(
    uint64_t token, uint64_t nonce, uint64_t proxyGeneration,
    uint64_t selectionRevision) {
    CjguiWindowsRangeActivateCtx *ctx =
        (CjguiWindowsRangeActivateCtx *)calloc(1u, sizeof(CjguiWindowsRangeActivateCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nonce = nonce;
    ctx->proxyGeneration = proxyGeneration;
    ctx->selectionRevision = selectionRevision;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "range_activate",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_range_activate_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_range_cancel_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsU64Ctx *c = (CjguiWindowsU64Ctx *)raw;
    return installed_range_cancel_impl(c->token, c->value);
}

CjguiInternalRendererStatus cjgui_internal_renderer_installed_range_cancel(
    uint64_t token, uint64_t nonce) {
    CjguiWindowsU64Ctx *ctx =
        (CjguiWindowsU64Ctx *)calloc(1u, sizeof(CjguiWindowsU64Ctx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->value = nonce;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "range_cancel",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_range_cancel_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsClaimCtx {
    uint64_t token;
    uint64_t node;
    int64_t resource;
    uint64_t binding;
    uint64_t scene;
    CjguiInternalInstalledRangeIntent intent;
} CjguiWindowsClaimCtx;

static CjguiInternalRendererStatus cjgui_windows_claim_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsClaimCtx *c = (CjguiWindowsClaimCtx *)raw;
    return claim_last_pumped_range_impl(c->token, c->node, c->resource,
        c->binding, c->scene, &c->intent);
}

CjguiInternalRendererStatus cjgui_internal_renderer_claim_last_pumped_range(
    uint64_t token, uint64_t node, int64_t resource, uint64_t binding,
    uint64_t scene, CjguiInternalInstalledRangeIntent *intent) {
    if (!intent) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsClaimCtx *ctx =
        (CjguiWindowsClaimCtx *)calloc(1u, sizeof(CjguiWindowsClaimCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->node = node;
    ctx->resource = resource;
    ctx->binding = binding;
    ctx->scene = scene;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "claim_range",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_claim_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) *intent = ctx->intent;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsCopyBytesCtx {
    uint64_t token;
    uint64_t seq;
    uint8_t *preBody;
    uint32_t preCapacity;
    uint8_t *replacement;
    uint32_t replacementCapacity;
    uint8_t *postBody;
    uint32_t postCapacity;
} CjguiWindowsCopyBytesCtx;

static void cjgui_windows_copy_bytes_free(void *raw) {
    CjguiWindowsCopyBytesCtx *c = (CjguiWindowsCopyBytesCtx *)raw;
    if (!c) return;
    free(c->preBody);
    free(c->replacement);
    free(c->postBody);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_copy_bytes_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsCopyBytesCtx *c = (CjguiWindowsCopyBytesCtx *)raw;
    return copy_claimed_range_bytes_impl(c->token, c->seq, c->preBody,
        c->preCapacity, c->replacement, c->replacementCapacity, c->postBody,
        c->postCapacity);
}

CjguiInternalRendererStatus cjgui_internal_renderer_copy_claimed_range_bytes(
    uint64_t token, uint64_t seq,
    uint8_t *preBody, uint32_t preCapacity,
    uint8_t *replacement, uint32_t replacementCapacity,
    uint8_t *postBody, uint32_t postCapacity) {
    CjguiWindowsCopyBytesCtx *ctx =
        (CjguiWindowsCopyBytesCtx *)calloc(1u, sizeof(CjguiWindowsCopyBytesCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->seq = seq;
    ctx->preBody = (uint8_t *)calloc(preCapacity ? preCapacity : 1u, 1u);
    ctx->replacement = (uint8_t *)calloc(replacementCapacity ? replacementCapacity : 1u, 1u);
    ctx->postBody = (uint8_t *)calloc(postCapacity ? postCapacity : 1u, 1u);
    ctx->preCapacity = preCapacity;
    ctx->replacementCapacity = replacementCapacity;
    ctx->postCapacity = postCapacity;
    if (!ctx->preBody || !ctx->replacement || !ctx->postBody) {
        cjgui_windows_copy_bytes_free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "copy_bytes",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_copy_bytes_proc, ctx,
        cjgui_windows_copy_bytes_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        if (preBody) memcpy(preBody, ctx->preBody, preCapacity);
        if (replacement) memcpy(replacement, ctx->replacement, replacementCapacity);
        if (postBody) memcpy(postBody, ctx->postBody, postCapacity);
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_copy_bytes_free(ctx);
    return st;
}

typedef struct CjguiWindowsAckCtx {
    uint64_t token;
    CjguiInternalInstalledRangeIntent intent;
    uint8_t *preBody;
    uint8_t *replacement;
    uint8_t *postBody;
    uint32_t accepted;
    int64_t versionAfter;
} CjguiWindowsAckCtx;

static void cjgui_windows_ack_free(void *raw) {
    CjguiWindowsAckCtx *c = (CjguiWindowsAckCtx *)raw;
    if (!c) return;
    free(c->preBody);
    free(c->replacement);
    free(c->postBody);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_ack_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsAckCtx *c = (CjguiWindowsAckCtx *)raw;
    c->intent.preBodyUtf8 = c->preBody;
    c->intent.replacementUtf8 = c->replacement;
    c->intent.postBodyUtf8 = c->postBody;
    return ack_installed_range_impl(c->token, &c->intent, c->accepted,
        c->versionAfter);
}

CjguiInternalRendererStatus cjgui_internal_renderer_ack_installed_range(
    uint64_t token, const CjguiInternalInstalledRangeIntent *intent,
    uint32_t accepted, int64_t versionAfter) {
    if (!intent) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsAckCtx *ctx =
        (CjguiWindowsAckCtx *)calloc(1u, sizeof(CjguiWindowsAckCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->intent = *intent;
    ctx->intent.preBodyUtf8 = NULL;
    ctx->intent.replacementUtf8 = NULL;
    ctx->intent.postBodyUtf8 = NULL;
    ctx->preBody = cjgui_windows_dup_bytes(intent->preBodyUtf8,
        intent->preBodyUtf8Length);
    ctx->replacement = cjgui_windows_dup_bytes(intent->replacementUtf8,
        intent->replacementUtf8Length);
    ctx->postBody = cjgui_windows_dup_bytes(intent->postBodyUtf8,
        intent->postBodyUtf8Length);
    if ((intent->preBodyUtf8Length && !ctx->preBody) ||
        (intent->replacementUtf8Length && !ctx->replacement) ||
        (intent->postBodyUtf8Length && !ctx->postBody)) {
        cjgui_windows_ack_free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    ctx->accepted = accepted;
    ctx->versionAfter = versionAfter;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "ack_range",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_ack_proc, ctx,
        cjgui_windows_ack_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_ack_free(ctx);
    return st;
}

typedef struct CjguiWindowsReleaseRangeCtx {
    uint64_t token;
    uint64_t document;
    uint64_t binding;
} CjguiWindowsReleaseRangeCtx;

static CjguiInternalRendererStatus cjgui_windows_release_range_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsReleaseRangeCtx *c = (CjguiWindowsReleaseRangeCtx *)raw;
    return release_installed_range_impl(c->token, c->document, c->binding);
}

CjguiInternalRendererStatus cjgui_internal_renderer_release_installed_range(
    uint64_t token, uint64_t document, uint64_t binding) {
    CjguiWindowsReleaseRangeCtx *ctx =
        (CjguiWindowsReleaseRangeCtx *)calloc(1u, sizeof(CjguiWindowsReleaseRangeCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->document = document;
    ctx->binding = binding;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "release_range",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_release_range_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsCaretCtx {
    uint64_t token;
    int64_t nodeId;
    double x;
    double y;
    double width;
    double height;
} CjguiWindowsCaretCtx;

static CjguiInternalRendererStatus cjgui_windows_caret_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsCaretCtx *c = (CjguiWindowsCaretCtx *)raw;
    return (CjguiInternalRendererStatus)declare_input_caret_impl(c->token,
        c->nodeId, c->x, c->y, c->width, c->height);
}

int32_t cjgui_internal_renderer_declare_input_caret(uint64_t token, int64_t nodeId,
    double x, double y, double width, double height) {
    CjguiWindowsCaretCtx *ctx =
        (CjguiWindowsCaretCtx *)calloc(1u, sizeof(CjguiWindowsCaretCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeId = nodeId;
    ctx->x = x;
    ctx->y = y;
    ctx->width = width;
    ctx->height = height;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "declare_caret",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_caret_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return (int32_t)st;
}

typedef struct CjguiWindowsPumpedGeomCtx {
    uint64_t token;
    CjguiInternalRendererPointerEventGeometry geometry;
} CjguiWindowsPumpedGeomCtx;

static CjguiInternalRendererStatus cjgui_windows_pumped_geom_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsPumpedGeomCtx *c = (CjguiWindowsPumpedGeomCtx *)raw;
    return pumped_pointer_geometry_impl(c->token, &c->geometry);
}

CjguiInternalRendererStatus cjgui_internal_renderer_pumped_pointer_geometry(
    uint64_t token, CjguiInternalRendererPointerEventGeometry *outGeometry) {
    if (!outGeometry) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsPumpedGeomCtx *ctx =
        (CjguiWindowsPumpedGeomCtx *)calloc(1u, sizeof(CjguiWindowsPumpedGeomCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "pumped_geom",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_pumped_geom_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) *outGeometry = ctx->geometry;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsConsumedLifetimeCtx {
    uint64_t token;
    int32_t result;
    uint64_t outSessionGeneration;
    uint64_t outCoordinateEpoch;
} CjguiWindowsConsumedLifetimeCtx;

static CjguiInternalRendererStatus cjgui_windows_consumed_lifetime_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsConsumedLifetimeCtx *c = (CjguiWindowsConsumedLifetimeCtx *)raw;
    c->result = owner_consumed_pointer_coordinate_lifetime_impl(c->token,
        &c->outSessionGeneration, &c->outCoordinateEpoch);
    return CJGUI_INTERNAL_RENDERER_OK;
}

int32_t cjgui_internal_renderer_owner_consumed_pointer_coordinate_lifetime(
    uint64_t token, uint64_t *outSessionGeneration, uint64_t *outCoordinateEpoch) {
    if (!outSessionGeneration || !outCoordinateEpoch) return 0;
    CjguiWindowsConsumedLifetimeCtx *ctx =
        (CjguiWindowsConsumedLifetimeCtx *)calloc(1u, sizeof(CjguiWindowsConsumedLifetimeCtx));
    if (!ctx) return 0;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "consumed_life",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_consumed_lifetime_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    int32_t result = 0;
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outSessionGeneration = ctx->outSessionGeneration;
        *outCoordinateEpoch = ctx->outCoordinateEpoch;
        result = ctx->result;
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return result;
}

typedef struct CjguiWindowsFormTextCtx {
    uint64_t token;
    const char *leased;
} CjguiWindowsFormTextCtx;

static CjguiInternalRendererStatus cjgui_windows_form_text_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    CjguiWindowsFormTextCtx *c = (CjguiWindowsFormTextCtx *)raw;
    const char *live = form_event_text_impl(c->token);
    if (!live) live = "";
    free(s->formEventTextPrev);
    s->formEventTextPrev = s->formEventTextLease;
    s->formEventTextLease = cjgui_windows_dup_string(live);
    if (!s->formEventTextLease) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    s->formEventTextLeaseId += 1u;
    c->leased = s->formEventTextLease;
    return CJGUI_INTERNAL_RENDERER_OK;
}

const char *cjgui_internal_renderer_form_event_text(uint64_t token) {
    CjguiWindowsFormTextCtx *ctx =
        (CjguiWindowsFormTextCtx *)calloc(1u, sizeof(CjguiWindowsFormTextCtx));
    if (!ctx) return "";
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "form_text",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_form_text_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    const char *result = "";
    if (st == CJGUI_INTERNAL_RENDERER_OK && ctx->leased) result = ctx->leased;
    free(ctx);
    return result;
}

typedef struct CjguiWindowsNodeRectCtx {
    uint64_t token;
    uint64_t nodeId;
    int64_t x;
    int64_t y;
    int64_t width;
    int64_t height;
} CjguiWindowsNodeRectCtx;

static CjguiInternalRendererStatus cjgui_windows_node_rect_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsNodeRectCtx *c = (CjguiWindowsNodeRectCtx *)raw;
    return node_rect_impl(c->token, c->nodeId, &c->x, &c->y, &c->width,
        &c->height);
}

CjguiInternalRendererStatus cjgui_internal_renderer_node_rect(uint64_t token,
    uint64_t nodeId, int64_t *outX, int64_t *outY, int64_t *outWidth,
    int64_t *outHeight) {
    if (!outX || !outY || !outWidth || !outHeight)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsNodeRectCtx *ctx =
        (CjguiWindowsNodeRectCtx *)calloc(1u, sizeof(CjguiWindowsNodeRectCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeId = nodeId;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "node_rect",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_node_rect_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outX = ctx->x;
        *outY = ctx->y;
        *outWidth = ctx->width;
        *outHeight = ctx->height;
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsQueryPresentCtx {
    uint64_t token;
    uint64_t ticketId;
    CjguiInternalRendererPresentReceipt receipt;
} CjguiWindowsQueryPresentCtx;

static CjguiInternalRendererStatus cjgui_windows_query_present_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsQueryPresentCtx *c = (CjguiWindowsQueryPresentCtx *)raw;
    return query_present_impl(c->token, c->ticketId, &c->receipt);
}

CjguiInternalRendererStatus cjgui_internal_renderer_query_present(
    uint64_t token, uint64_t ticketId,
    CjguiInternalRendererPresentReceipt *outReceipt) {
    return query_present_impl(token, ticketId, outReceipt);
}


typedef struct CjguiWindowsHitTestCtx {
    uint64_t token;
    uint64_t nodeId;
    double x;
    double y;
    uint64_t expectedSceneVersion;
    uint32_t outByteOffset;
    uint32_t outAffinity;
} CjguiWindowsHitTestCtx;

static CjguiInternalRendererStatus cjgui_windows_hit_test_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsHitTestCtx *c = (CjguiWindowsHitTestCtx *)raw;
    return hit_test_composable_text_impl(c->token, c->nodeId, c->x, c->y,
        c->expectedSceneVersion, &c->outByteOffset, &c->outAffinity);
}

CjguiInternalRendererStatus cjgui_internal_renderer_hit_test_composable_text(
    uint64_t token, uint64_t nodeId, double x, double y,
    uint64_t expectedSceneVersion, uint32_t *outByteOffset,
    uint32_t *outAffinity) {
    if (!outByteOffset || !outAffinity)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsHitTestCtx *ctx =
        (CjguiWindowsHitTestCtx *)calloc(1u, sizeof(CjguiWindowsHitTestCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeId = nodeId;
    ctx->x = x;
    ctx->y = y;
    ctx->expectedSceneVersion = expectedSceneVersion;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "hit_test",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_hit_test_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outByteOffset = ctx->outByteOffset;
        *outAffinity = ctx->outAffinity;
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsTextPosCtx {
    uint64_t token;
    uint64_t nodeId;
    uint64_t expectedSceneVersion;
    uint32_t op;
    int64_t displayByte;
    uint32_t renderSide;
    uint64_t layoutLease;
    uint64_t stopId;
    uint32_t direction;
    double x;
    double y;
    uint64_t meta[8];
    double rect[4];
} CjguiWindowsTextPosCtx;

static CjguiInternalRendererStatus cjgui_windows_text_pos_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsTextPosCtx *c = (CjguiWindowsTextPosCtx *)raw;
    return text_position_v1_impl(c->token, c->nodeId, c->expectedSceneVersion,
        c->op, c->displayByte, c->renderSide, c->layoutLease, c->stopId,
        c->direction, c->x, c->y, c->meta, c->rect);
}

CjguiInternalRendererStatus cjgui_internal_renderer_text_position_v1(
    uint64_t token, uint64_t nodeId, uint64_t expectedSceneVersion, uint32_t op,
    int64_t displayByte, uint32_t renderSide, uint64_t layoutLease,
    uint64_t stopId, uint32_t direction, double x, double y, uint64_t *meta,
    double *rect) {
    if (!meta || !rect) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsTextPosCtx *ctx =
        (CjguiWindowsTextPosCtx *)calloc(1u, sizeof(CjguiWindowsTextPosCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeId = nodeId;
    ctx->expectedSceneVersion = expectedSceneVersion;
    ctx->op = op;
    ctx->displayByte = displayByte;
    ctx->renderSide = renderSide;
    ctx->layoutLease = layoutLease;
    ctx->stopId = stopId;
    ctx->direction = direction;
    ctx->x = x;
    ctx->y = y;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "text_pos",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_text_pos_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        memcpy(meta, ctx->meta, sizeof(ctx->meta));
        memcpy(rect, ctx->rect, sizeof(ctx->rect));
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsCoordLifeCtx {
    uint64_t token;
    uint64_t epoch;
    uint64_t outSessionGeneration;
} CjguiWindowsCoordLifeCtx;

static CjguiInternalRendererStatus cjgui_windows_coord_life_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsCoordLifeCtx *c = (CjguiWindowsCoordLifeCtx *)raw;
    c->epoch = coordinate_lifetime_impl(c->token, &c->outSessionGeneration);
    return CJGUI_INTERNAL_RENDERER_OK;
}

uint64_t cjgui_internal_renderer_coordinate_lifetime(uint64_t token,
    uint64_t *outSessionGeneration) {
    if (outSessionGeneration) *outSessionGeneration = 0u;
    CjguiWindowsCoordLifeCtx *ctx =
        (CjguiWindowsCoordLifeCtx *)calloc(1u, sizeof(CjguiWindowsCoordLifeCtx));
    if (!ctx) return 0u;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "coord_life",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_coord_life_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    uint64_t epoch = 0u;
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        epoch = ctx->epoch;
        if (outSessionGeneration)
            *outSessionGeneration = ctx->outSessionGeneration;
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return epoch;
}

typedef struct CjguiWindowsActivationCtx {
    uint64_t token;
    int32_t outKey;
    int32_t outMain;
    int32_t outAppActive;
} CjguiWindowsActivationCtx;

static CjguiInternalRendererStatus cjgui_windows_activation_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsActivationCtx *c = (CjguiWindowsActivationCtx *)raw;
    return window_activation_state_impl(c->token, &c->outKey, &c->outMain,
        &c->outAppActive);
}

CjguiInternalRendererStatus cjgui_internal_renderer_window_activation_state(
    uint64_t token, int32_t *outKey, int32_t *outMain, int32_t *outAppActive) {
    if (!outKey || !outMain || !outAppActive)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsActivationCtx *ctx =
        (CjguiWindowsActivationCtx *)calloc(1u, sizeof(CjguiWindowsActivationCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "activation",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_activation_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outKey = ctx->outKey;
        *outMain = ctx->outMain;
        *outAppActive = ctx->outAppActive;
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_window_frame_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsNodeRectCtx *c = (CjguiWindowsNodeRectCtx *)raw;
    return window_frame_impl(c->token, &c->x, &c->y, &c->width, &c->height);
}

CjguiInternalRendererStatus cjgui_internal_renderer_window_frame(uint64_t token,
    int64_t *outX, int64_t *outY, int64_t *outWidth, int64_t *outHeight) {
    if (!outX || !outY || !outWidth || !outHeight)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsNodeRectCtx *ctx =
        (CjguiWindowsNodeRectCtx *)calloc(1u, sizeof(CjguiWindowsNodeRectCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "window_frame",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_window_frame_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outX = ctx->x;
        *outY = ctx->y;
        *outWidth = ctx->width;
        *outHeight = ctx->height;
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsDiagResCtx {
    uint64_t token;
    CjguiInternalRendererDiagnosticResources resources;
} CjguiWindowsDiagResCtx;

static CjguiInternalRendererStatus cjgui_windows_diag_res_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsDiagResCtx *c = (CjguiWindowsDiagResCtx *)raw;
    return diagnostic_resources_impl(c->token, &c->resources);
}

CjguiInternalRendererStatus cjgui_internal_renderer_diagnostic_resources(
    uint64_t token, CjguiInternalRendererDiagnosticResources *outResources) {
    if (!outResources) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsDiagResCtx *ctx =
        (CjguiWindowsDiagResCtx *)calloc(1u, sizeof(CjguiWindowsDiagResCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "diag_res",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_diag_res_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) *outResources = ctx->resources;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsDiagTimingCtx {
    uint64_t token;
    CjguiInternalRendererDiagnosticTiming timing;
} CjguiWindowsDiagTimingCtx;

static CjguiInternalRendererStatus cjgui_windows_diag_timing_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsDiagTimingCtx *c = (CjguiWindowsDiagTimingCtx *)raw;
    return diagnostic_timing_impl(c->token, &c->timing);
}

CjguiInternalRendererStatus cjgui_internal_renderer_diagnostic_timing(
    uint64_t token, CjguiInternalRendererDiagnosticTiming *outTiming) {
    if (!outTiming) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsDiagTimingCtx *ctx =
        (CjguiWindowsDiagTimingCtx *)calloc(1u, sizeof(CjguiWindowsDiagTimingCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "diag_timing",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_diag_timing_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) *outTiming = ctx->timing;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsDiagWorkCtx {
    uint64_t token;
    CjguiInternalRendererDiagnosticWorkload workload;
} CjguiWindowsDiagWorkCtx;

static CjguiInternalRendererStatus cjgui_windows_diag_work_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsDiagWorkCtx *c = (CjguiWindowsDiagWorkCtx *)raw;
    return diagnostic_workload_impl(c->token, &c->workload);
}

CjguiInternalRendererStatus cjgui_internal_renderer_diagnostic_workload(
    uint64_t token, CjguiInternalRendererDiagnosticWorkload *outWorkload) {
    if (!outWorkload) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsDiagWorkCtx *ctx =
        (CjguiWindowsDiagWorkCtx *)calloc(1u, sizeof(CjguiWindowsDiagWorkCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "diag_work",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_diag_work_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) *outWorkload = ctx->workload;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsDisplayProgressCtx {
    uint64_t token;
    CjguiInternalRendererComposableDisplayProgress progress;
} CjguiWindowsDisplayProgressCtx;

static CjguiInternalRendererStatus cjgui_windows_display_progress_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsDisplayProgressCtx *c = (CjguiWindowsDisplayProgressCtx *)raw;
    return composable_display_progress_impl(c->token, &c->progress);
}

CjguiInternalRendererStatus cjgui_internal_renderer_composable_display_progress(
    uint64_t token, CjguiInternalRendererComposableDisplayProgress *outProgress) {
    if (!outProgress) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsDisplayProgressCtx *ctx =
        (CjguiWindowsDisplayProgressCtx *)calloc(1u, sizeof(CjguiWindowsDisplayProgressCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "disp_progress",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_display_progress_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) *outProgress = ctx->progress;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsImageStateCtx {
    uint64_t token;
    char *resourcePath;
    char *resourceId;
    uint64_t resourceVersion;
    uint32_t outState;
} CjguiWindowsImageStateCtx;

static void cjgui_windows_image_state_free(void *raw) {
    CjguiWindowsImageStateCtx *c = (CjguiWindowsImageStateCtx *)raw;
    if (!c) return;
    free(c->resourcePath);
    free(c->resourceId);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_image_state_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsImageStateCtx *c = (CjguiWindowsImageStateCtx *)raw;
    return composable_image_resource_state_impl(c->token, c->resourcePath,
        c->resourceId, c->resourceVersion, &c->outState);
}

CjguiInternalRendererStatus cjgui_internal_renderer_composable_image_resource_state(
    uint64_t token, const char *resourcePath, const char *resourceId,
    uint64_t resourceVersion, uint32_t *outState) {
    if (!outState) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsImageStateCtx *ctx =
        (CjguiWindowsImageStateCtx *)calloc(1u, sizeof(CjguiWindowsImageStateCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->resourcePath = cjgui_windows_dup_string(resourcePath);
    ctx->resourceId = cjgui_windows_dup_string(resourceId);
    if ((resourcePath && !ctx->resourcePath) ||
        (resourceId && !ctx->resourceId)) {
        cjgui_windows_image_state_free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    ctx->resourceVersion = resourceVersion;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "image_state",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_image_state_proc, ctx,
        cjgui_windows_image_state_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) *outState = ctx->outState;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_image_state_free(ctx);
    return st;
}

typedef struct CjguiWindowsPrepCtx {
    uint64_t token;
    uint64_t preparationId;
    uint64_t baseSceneVersion;
    uint64_t projectionVersion;
    uint32_t nodeCount;
    uint64_t deadlineNs;
    uint32_t outReady;
} CjguiWindowsPrepCtx;

static CjguiInternalRendererStatus cjgui_windows_begin_prep_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsPrepCtx *c = (CjguiWindowsPrepCtx *)raw;
    return begin_composable_preparation_impl(c->token, c->preparationId,
        c->baseSceneVersion, c->projectionVersion, c->nodeCount);
}

CjguiInternalRendererStatus cjgui_internal_renderer_begin_composable_preparation(
    uint64_t token, uint64_t preparationId, uint64_t baseSceneVersion,
    uint64_t projectionVersion, uint32_t nodeCount) {
    CjguiWindowsPrepCtx *ctx =
        (CjguiWindowsPrepCtx *)calloc(1u, sizeof(CjguiWindowsPrepCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->preparationId = preparationId;
    ctx->baseSceneVersion = baseSceneVersion;
    ctx->projectionVersion = projectionVersion;
    ctx->nodeCount = nodeCount;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "begin_prep",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_begin_prep_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsPrepareNodeCtx {
    uint64_t token;
    uint64_t preparationId;
    uint32_t index;
    CjguiInternalRendererComposableNode node;
    int hasNode;
    CjguiInternalRendererComposableGeometry geometry;
    int hasGeometry;
    char *label;
    char *value;
    char *semanticId;
    char *bindingKey;
    char *rowKey;
    char *parentRowKey;
    char *semanticLabel;
    char *encodedRuns;
} CjguiWindowsPrepareNodeCtx;

static void cjgui_windows_prepare_node_free(void *raw) {
    CjguiWindowsPrepareNodeCtx *c = (CjguiWindowsPrepareNodeCtx *)raw;
    if (!c) return;
    free(c->label);
    free(c->value);
    free(c->semanticId);
    free(c->bindingKey);
    free(c->rowKey);
    free(c->parentRowKey);
    free(c->semanticLabel);
    free(c->encodedRuns);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_prepare_node_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsPrepareNodeCtx *c = (CjguiWindowsPrepareNodeCtx *)raw;
    return prepare_composable_node_impl(c->token, c->preparationId, c->index,
        c->hasNode ? &c->node : NULL, c->hasGeometry ? &c->geometry : NULL,
        c->label, c->value, c->semanticId, c->bindingKey, c->rowKey,
        c->parentRowKey, c->semanticLabel, c->encodedRuns);
}

CjguiInternalRendererStatus cjgui_internal_renderer_prepare_composable_node(
    uint64_t token, uint64_t preparationId, uint32_t index,
    const CjguiInternalRendererComposableNode *node,
    const CjguiInternalRendererComposableGeometry *geometry,
    const char *label, const char *value, const char *semanticId,
    const char *bindingKey, const char *rowKey, const char *parentRowKey,
    const char *semanticLabel, const char *encodedRuns) {
    CjguiWindowsPrepareNodeCtx *ctx =
        (CjguiWindowsPrepareNodeCtx *)calloc(1u, sizeof(CjguiWindowsPrepareNodeCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->preparationId = preparationId;
    ctx->index = index;
    if (node) {
        ctx->node = *node;
        ctx->hasNode = 1;
    }
    if (geometry) {
        ctx->geometry = *geometry;
        ctx->hasGeometry = 1;
    }
    ctx->label = cjgui_windows_dup_string(label);
    ctx->value = cjgui_windows_dup_string(value);
    ctx->semanticId = cjgui_windows_dup_string(semanticId);
    ctx->bindingKey = cjgui_windows_dup_string(bindingKey);
    ctx->rowKey = cjgui_windows_dup_string(rowKey);
    ctx->parentRowKey = cjgui_windows_dup_string(parentRowKey);
    ctx->semanticLabel = cjgui_windows_dup_string(semanticLabel);
    ctx->encodedRuns = cjgui_windows_dup_string(encodedRuns);
    if ((label && !ctx->label) || (value && !ctx->value) ||
        (semanticId && !ctx->semanticId) || (bindingKey && !ctx->bindingKey) ||
        (rowKey && !ctx->rowKey) || (parentRowKey && !ctx->parentRowKey) ||
        (semanticLabel && !ctx->semanticLabel) ||
        (encodedRuns && !ctx->encodedRuns)) {
        cjgui_windows_prepare_node_free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "prepare_node",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_prepare_node_proc, ctx,
        cjgui_windows_prepare_node_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_prepare_node_free(ctx);
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_advance_prep_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsPrepCtx *c = (CjguiWindowsPrepCtx *)raw;
    return advance_composable_preparation_impl(c->token, c->preparationId,
        c->deadlineNs, &c->outReady);
}

CjguiInternalRendererStatus cjgui_internal_renderer_advance_composable_preparation(
    uint64_t token, uint64_t preparationId, uint64_t deadlineNs,
    uint32_t *outReady) {
    if (!outReady) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsPrepCtx *ctx =
        (CjguiWindowsPrepCtx *)calloc(1u, sizeof(CjguiWindowsPrepCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->preparationId = preparationId;
    ctx->deadlineNs = deadlineNs;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "advance_prep",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_advance_prep_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) *outReady = ctx->outReady;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_promote_prep_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsU64Ctx *c = (CjguiWindowsU64Ctx *)raw;
    return promote_composable_preparation_impl(c->token, c->value);
}

CjguiInternalRendererStatus cjgui_internal_renderer_promote_composable_preparation(
    uint64_t token, uint64_t preparationId) {
    CjguiWindowsU64Ctx *ctx =
        (CjguiWindowsU64Ctx *)calloc(1u, sizeof(CjguiWindowsU64Ctx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->value = preparationId;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "promote_prep",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_promote_prep_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_cancel_prep_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsU64Ctx *c = (CjguiWindowsU64Ctx *)raw;
    return cancel_composable_preparation_impl(c->token, c->value);
}

CjguiInternalRendererStatus cjgui_internal_renderer_cancel_composable_preparation(
    uint64_t token, uint64_t preparationId) {
    CjguiWindowsU64Ctx *ctx =
        (CjguiWindowsU64Ctx *)calloc(1u, sizeof(CjguiWindowsU64Ctx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->value = preparationId;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "cancel_prep",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_cancel_prep_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

/* ---- R7：共用准备协议在 Windows 的真实实现 ----
   批量 prepare / 具名 reuse / 有界退休三个入口与 macOS 同名同签名；都进 UI
   线程执行，且统一消费同一个绝对 deadline。 */

typedef struct CjguiWindowsPrepBatchCtx {
    uint64_t token;
    uint64_t preparationId;
    uint32_t firstIndex;
    uint32_t count;
    uint64_t deadlineNs;
    uint32_t outCopied;
    CjguiInternalRendererComposableNode nodes[CJGUI_PRIVATE_PREPARATION_BATCH_CAPACITY];
    CjguiInternalRendererComposableGeometry geometry[CJGUI_PRIVATE_PREPARATION_BATCH_CAPACITY];
    char *strings[CJGUI_PRIVATE_PREPARATION_BATCH_CAPACITY * 8u];
} CjguiWindowsPrepBatchCtx;

static void cjgui_windows_prep_batch_free(void *raw) {
    CjguiWindowsPrepBatchCtx *c = (CjguiWindowsPrepBatchCtx *)raw;
    if (!c) return;
    for (size_t i = 0u; i < sizeof(c->strings) / sizeof(c->strings[0]); ++i) free(c->strings[i]);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_prep_batch_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsPrepBatchCtx *c = (CjguiWindowsPrepBatchCtx *)raw;
    c->outCopied = 0u;
    for (uint32_t i = 0u; i < c->count; ++i) {
        /* 派发与已完成前缀已经消耗同一绝对预算：到点即返回真实成功前缀。 */
        if (c->deadlineNs != 0u && cjgui_internal_renderer_owner_clock_ns() >= c->deadlineNs) break;
        char **texts = &c->strings[(size_t)i * 8u];
        CjguiInternalRendererStatus status = prepare_composable_node_impl(c->token,
            c->preparationId, c->firstIndex + i, &c->nodes[i], &c->geometry[i],
            texts[0], texts[1], texts[2], texts[3], texts[4], texts[5], texts[6], texts[7]);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
        c->outCopied += 1u;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_prepare_composable_node_batch(
    uint64_t token, uint64_t preparationId, uint32_t firstIndex, uint32_t count,
    const CjguiInternalRendererComposableNode *nodes,
    const CjguiInternalRendererComposableGeometry *geometry,
    const char *const *strings, uint64_t deadlineNs, uint32_t *outCopied) {
    if (outCopied) *outCopied = 0u;
    if (!nodes || !geometry || !strings || count == 0u ||
        count > CJGUI_PRIVATE_PREPARATION_BATCH_CAPACITY)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsPrepBatchCtx *ctx =
        (CjguiWindowsPrepBatchCtx *)calloc(1u, sizeof(CjguiWindowsPrepBatchCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->preparationId = preparationId;
    ctx->firstIndex = firstIndex;
    ctx->count = count;
    ctx->deadlineNs = deadlineNs;
    /* IN 字符串按包装层约定深拷贝：命令超时/移交后调用者内存不再被引用。 */
    for (uint32_t i = 0u; i < count; ++i) {
        ctx->nodes[i] = nodes[i];
        ctx->geometry[i] = geometry[i];
        for (uint32_t k = 0u; k < 8u; ++k) {
            const char *value = strings[(size_t)i * 8u + k];
            if (!value) continue;
            ctx->strings[(size_t)i * 8u + k] = cjgui_windows_dup_string(value);
            if (!ctx->strings[(size_t)i * 8u + k]) {
                cjgui_windows_prep_batch_free(ctx);
                return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
            }
        }
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "prepare_node_batch",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_prep_batch_proc, ctx,
        cjgui_windows_prep_batch_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK && outCopied) *outCopied = ctx->outCopied;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_prep_batch_free(ctx);
    return st;
}

typedef struct CjguiWindowsPrepReuseCtx {
    uint64_t token;
    uint64_t preparationId;
    uint32_t firstIndex;
    uint32_t count;
    uint64_t deadlineNs;
    uint32_t stale;
} CjguiWindowsPrepReuseCtx;

static CjguiInternalRendererStatus cjgui_windows_prep_reuse_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsPrepReuseCtx *c = (CjguiWindowsPrepReuseCtx *)raw;
    c->stale = 0u;
    if (!s || !s->preparationActive || s->preparationId != c->preparationId ||
        s->preparationReady || c->count == 0u || c->firstIndex >= s->preparationNodeCount ||
        c->count > s->preparationNodeCount - c->firstIndex) {
        c->stale = 1u;
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    for (uint32_t i = 0u; i < c->count; ++i) {
        if (s->preparationState[c->firstIndex + i] != 0u) {
            c->stale = 1u;
            return CJGUI_INTERNAL_RENDERER_OK;
        }
    }
    /* 具名、有界的完整声明回退：本后端不做声明级 COW 复用（不伪报复用，
       outReused 恒为 0），调用者按既有路径对这有界节点做完整声明复制。 */
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_reuse_composable_node_batch(
    uint64_t token, uint64_t preparationId, uint32_t firstIndex, uint32_t count,
    const CjguiInternalRendererComposableNode *nodes,
    const CjguiInternalRendererComposableGeometry *geometry, uint64_t deadlineNs,
    uint32_t *outReused) {
    if (outReused) *outReused = 0u;
    if (!nodes || !geometry || count == 0u || count > CJGUI_PRIVATE_PREPARATION_BATCH_CAPACITY)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsPrepReuseCtx *ctx =
        (CjguiWindowsPrepReuseCtx *)calloc(1u, sizeof(CjguiWindowsPrepReuseCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->preparationId = preparationId;
    ctx->firstIndex = firstIndex;
    ctx->count = count;
    (void)geometry;
    (void)deadlineNs;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "reuse_node_batch",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_prep_reuse_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        if (ctx->stale) st = CJGUI_INTERNAL_RENDERER_SCENE_STALE;
        free(ctx);
    } else if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) {
        free(ctx);
    }
    return st;
}

typedef struct CjguiWindowsPrepDrainCtx {
    uint64_t token;
    uint64_t deadline;
    uint32_t mayBegin;
} CjguiWindowsPrepDrainCtx;

static CjguiInternalRendererStatus cjgui_windows_drain_retirement_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    CjguiWindowsPrepDrainCtx *c = (CjguiWindowsPrepDrainCtx *)raw;
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    c->mayBegin = windows_prep_drain(s, c->deadline) ? 1u : 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_drain_composable_retirement(
    uint64_t token, uint64_t ownerDeadline, uint8_t *outMayBegin) {
    if (!outMayBegin) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outMayBegin = 0u;
    CjguiWindowsPrepDrainCtx *ctx =
        (CjguiWindowsPrepDrainCtx *)calloc(1u, sizeof(CjguiWindowsPrepDrainCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->deadline = ownerDeadline;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "drain_retirement",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_drain_retirement_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outMayBegin = ctx->mayBegin ? 1u : 0u;
        free(ctx);
    } else if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) {
        free(ctx);
    }
    return st;
}

typedef struct CjguiWindowsConfigSceneCtx {
    uint64_t token;
    uint64_t projectionVersion;
    uint32_t nodeCount;
} CjguiWindowsConfigSceneCtx;

static CjguiInternalRendererStatus cjgui_windows_config_scene_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsConfigSceneCtx *c = (CjguiWindowsConfigSceneCtx *)raw;
    return configure_composable_scene_impl(c->token, c->projectionVersion,
        c->nodeCount);
}

CjguiInternalRendererStatus cjgui_internal_renderer_configure_composable_scene(
    uint64_t token, uint64_t projectionVersion, uint32_t nodeCount) {
    CjguiWindowsConfigSceneCtx *ctx =
        (CjguiWindowsConfigSceneCtx *)calloc(1u, sizeof(CjguiWindowsConfigSceneCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->projectionVersion = projectionVersion;
    ctx->nodeCount = nodeCount;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "config_scene",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_config_scene_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_discard_candidate_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsTokenCtx *c = (CjguiWindowsTokenCtx *)raw;
    return discard_composable_scene_candidate_impl(c->token);
}

CjguiInternalRendererStatus cjgui_internal_renderer_discard_composable_scene_candidate(
    uint64_t token) {
    CjguiWindowsTokenCtx *ctx =
        (CjguiWindowsTokenCtx *)calloc(1u, sizeof(CjguiWindowsTokenCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "discard_cand",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_discard_candidate_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsSetNodeCtx {
    uint64_t token;
    uint32_t nodeIndex;
    CjguiInternalRendererComposableNode node;
    int hasNode;
    char *label;
    char *value;
    char *imageResourcePath;
    char *imageResourceId;
    uint64_t imageResourceVersion;
    uint8_t *bytes;
    uint32_t length;
    int hasBytes;
} CjguiWindowsSetNodeCtx;

static void cjgui_windows_set_node_free(void *raw) {
    CjguiWindowsSetNodeCtx *c = (CjguiWindowsSetNodeCtx *)raw;
    if (!c) return;
    free(c->label);
    free(c->value);
    free(c->imageResourcePath);
    free(c->imageResourceId);
    free(c->bytes);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_set_node_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsSetNodeCtx *c = (CjguiWindowsSetNodeCtx *)raw;
    if (c->hasBytes) {
        return set_composable_scene_node_bytes_impl(c->token, c->nodeIndex,
            c->hasNode ? &c->node : NULL, c->label, c->value,
            c->imageResourcePath, c->imageResourceId, c->imageResourceVersion,
            c->bytes, c->length);
    }
    return set_composable_scene_node_impl(c->token, c->nodeIndex,
        c->hasNode ? &c->node : NULL, c->label, c->value, c->imageResourcePath,
        c->imageResourceId, c->imageResourceVersion);
}

static CjguiInternalRendererStatus cjgui_windows_set_node_entry(uint64_t token,
    uint32_t nodeIndex, const CjguiInternalRendererComposableNode *node,
    const char *label, const char *value, const char *imageResourcePath,
    const char *imageResourceId, uint64_t imageResourceVersion,
    const uint8_t *bytes, uint32_t length, int hasBytes, const char *apiName) {
    CjguiWindowsSetNodeCtx *ctx =
        (CjguiWindowsSetNodeCtx *)calloc(1u, sizeof(CjguiWindowsSetNodeCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeIndex = nodeIndex;
    if (node) {
        ctx->node = *node;
        ctx->hasNode = 1;
    }
    ctx->label = cjgui_windows_dup_string(label);
    ctx->value = cjgui_windows_dup_string(value);
    ctx->imageResourcePath = cjgui_windows_dup_string(imageResourcePath);
    ctx->imageResourceId = cjgui_windows_dup_string(imageResourceId);
    ctx->imageResourceVersion = imageResourceVersion;
    if (hasBytes) {
        ctx->bytes = cjgui_windows_dup_bytes(bytes, length);
        ctx->length = length;
        ctx->hasBytes = 1;
        if (length && !ctx->bytes) {
            cjgui_windows_set_node_free(ctx);
            return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        }
    }
    if ((label && !ctx->label) || (value && !ctx->value) ||
        (imageResourcePath && !ctx->imageResourcePath) ||
        (imageResourceId && !ctx->imageResourceId)) {
        cjgui_windows_set_node_free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, apiName,
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_set_node_proc, ctx,
        cjgui_windows_set_node_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_set_node_free(ctx);
    return st;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_scene_node(
    uint64_t token, uint32_t nodeIndex,
    const CjguiInternalRendererComposableNode *node, const char *label,
    const char *value, const char *imageResourcePath,
    const char *imageResourceId, uint64_t imageResourceVersion) {
    return cjgui_windows_set_node_entry(token, nodeIndex, node, label, value,
        imageResourcePath, imageResourceId, imageResourceVersion, NULL, 0u, 0,
        "set_node");
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_scene_node_bytes(
    uint64_t token, uint32_t nodeIndex,
    const CjguiInternalRendererComposableNode *node, const char *label,
    const char *value, const char *imageResourcePath,
    const char *imageResourceId, uint64_t imageResourceVersion,
    const uint8_t *bytes, uint32_t length) {
    return cjgui_windows_set_node_entry(token, nodeIndex, node, label, value,
        imageResourcePath, imageResourceId, imageResourceVersion, bytes, length,
        1, "set_node_bytes");
}

typedef struct CjguiWindowsSemanticCtx {
    uint64_t token;
    uint32_t nodeIndex;
    char *semanticId;
    char *bindingKey;
    char *rowKey;
    char *parentRowKey;
    char *semanticLabel;
    int isMetadata;
} CjguiWindowsSemanticCtx;

static void cjgui_windows_semantic_free(void *raw) {
    CjguiWindowsSemanticCtx *c = (CjguiWindowsSemanticCtx *)raw;
    if (!c) return;
    free(c->semanticId);
    free(c->bindingKey);
    free(c->rowKey);
    free(c->parentRowKey);
    free(c->semanticLabel);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_semantic_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsSemanticCtx *c = (CjguiWindowsSemanticCtx *)raw;
    if (c->isMetadata) {
        return set_composable_node_semantic_metadata_impl(c->token, c->nodeIndex,
            c->bindingKey, c->rowKey, c->parentRowKey, c->semanticLabel);
    }
    return set_composable_node_semantic_identity_impl(c->token, c->nodeIndex,
        c->semanticId);
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_node_semantic_identity(
    uint64_t token, uint32_t nodeIndex, const char *semanticId) {
    CjguiWindowsSemanticCtx *ctx =
        (CjguiWindowsSemanticCtx *)calloc(1u, sizeof(CjguiWindowsSemanticCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeIndex = nodeIndex;
    ctx->semanticId = cjgui_windows_dup_string(semanticId);
    if (semanticId && !ctx->semanticId) {
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "semantic_id",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_semantic_proc, ctx,
        cjgui_windows_semantic_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_semantic_free(ctx);
    return st;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_node_semantic_metadata(
    uint64_t token, uint32_t nodeIndex, const char *bindingKey,
    const char *rowKey, const char *parentRowKey, const char *semanticLabel) {
    CjguiWindowsSemanticCtx *ctx =
        (CjguiWindowsSemanticCtx *)calloc(1u, sizeof(CjguiWindowsSemanticCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeIndex = nodeIndex;
    ctx->bindingKey = cjgui_windows_dup_string(bindingKey);
    ctx->rowKey = cjgui_windows_dup_string(rowKey);
    ctx->parentRowKey = cjgui_windows_dup_string(parentRowKey);
    ctx->semanticLabel = cjgui_windows_dup_string(semanticLabel);
    ctx->isMetadata = 1;
    if ((bindingKey && !ctx->bindingKey) || (rowKey && !ctx->rowKey) ||
        (parentRowKey && !ctx->parentRowKey) ||
        (semanticLabel && !ctx->semanticLabel)) {
        cjgui_windows_semantic_free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "semantic_meta",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_semantic_proc, ctx,
        cjgui_windows_semantic_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_semantic_free(ctx);
    return st;
}

typedef struct CjguiWindowsTextRunsCtx {
    uint64_t token;
    uint64_t nodeId;
    char *encoded;
} CjguiWindowsTextRunsCtx;

static void cjgui_windows_text_runs_free(void *raw) {
    CjguiWindowsTextRunsCtx *c = (CjguiWindowsTextRunsCtx *)raw;
    if (!c) return;
    free(c->encoded);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_text_runs_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsTextRunsCtx *c = (CjguiWindowsTextRunsCtx *)raw;
    return set_composable_text_runs_impl(c->token, c->nodeId, c->encoded);
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_text_runs(
    uint64_t token, uint64_t nodeId, const char *encoded) {
    CjguiWindowsTextRunsCtx *ctx =
        (CjguiWindowsTextRunsCtx *)calloc(1u, sizeof(CjguiWindowsTextRunsCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeId = nodeId;
    ctx->encoded = cjgui_windows_dup_string(encoded);
    if (encoded && !ctx->encoded) {
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "text_runs",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_text_runs_proc, ctx,
        cjgui_windows_text_runs_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_text_runs_free(ctx);
    return st;
}

typedef struct CjguiWindowsStageBgCtx {
    uint64_t token;
    uint64_t projectionVersion;
    uint32_t mode;
    uint32_t colorScheme;
} CjguiWindowsStageBgCtx;

static CjguiInternalRendererStatus cjgui_windows_stage_bg_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsStageBgCtx *c = (CjguiWindowsStageBgCtx *)raw;
    return stage_window_background_impl(c->token, c->projectionVersion, c->mode,
        c->colorScheme);
}

CjguiInternalRendererStatus cjgui_internal_renderer_stage_window_background(
    uint64_t token, uint64_t projectionVersion, uint32_t mode,
    uint32_t colorScheme) {
    CjguiWindowsStageBgCtx *ctx =
        (CjguiWindowsStageBgCtx *)calloc(1u, sizeof(CjguiWindowsStageBgCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->projectionVersion = projectionVersion;
    ctx->mode = mode;
    ctx->colorScheme = colorScheme;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "stage_bg",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_stage_bg_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsBgSnapshotCtx {
    uint64_t token;
    CjguiInternalRendererWindowBackgroundSnapshot snapshot;
} CjguiWindowsBgSnapshotCtx;

static CjguiInternalRendererStatus cjgui_windows_bg_snapshot_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsBgSnapshotCtx *c = (CjguiWindowsBgSnapshotCtx *)raw;
    return window_background_snapshot_impl(c->token, &c->snapshot);
}

CjguiInternalRendererStatus cjgui_internal_renderer_window_background_snapshot(
    uint64_t token,
    CjguiInternalRendererWindowBackgroundSnapshot *outSnapshot) {
    if (!outSnapshot) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsBgSnapshotCtx *ctx =
        (CjguiWindowsBgSnapshotCtx *)calloc(1u, sizeof(CjguiWindowsBgSnapshotCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "bg_snapshot",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_bg_snapshot_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) *outSnapshot = ctx->snapshot;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

static CjguiInternalRendererStatus prepare_composable_image_resource_impl(
    uint64_t token, const char *resourcePath, const char *resourceId,
    uint64_t resourceVersion, uint32_t *outState);
static CjguiInternalRendererStatus finish_composable_png_transfer_impl(
    uint64_t token, const char *resourceIdentity, uint8_t accepted);
static CjguiInternalRendererStatus prepare_composable_png_transfer_impl(
    uint64_t token, const char *resourceIdentity, const uint8_t *bytes,
    uint32_t length, uint32_t *outWidth, uint32_t *outHeight,
    uint64_t *outDecodeMicros);
static CjguiInternalRendererStatus text_position_stats_v1_impl(uint64_t token,
    uint64_t *counts);
static CjguiInternalRendererStatus text_geometry_caret_impl(uint64_t token,
    int64_t nodeId, int64_t displayByte, double caretWidthPt,
    uint64_t expectedSceneVersion, uint32_t affinity, double *outX, double *outY,
    double *outWidth, double *outHeight);
static CjguiInternalRendererStatus text_visual_neighbor_impl(uint64_t token,
    uint64_t nodeId, int64_t displayByte, uint32_t left,
    uint64_t expectedSceneVersion, uint32_t caretAffinity,
    uint32_t *outNeighborByte, uint32_t *outAffinity);
static CjguiInternalRendererStatus diagnostic_node_geometry_impl(uint64_t token,
    uint32_t nodeIndex, CjguiInternalRendererDiagnosticNodeGeometry *outGeometry);
static CjguiInternalRendererStatus text_stop_resolve_impl(uint64_t token,
    uint64_t nodeId, int64_t displayByte, uint32_t branchIn,
    uint64_t expectedSceneVersion, uint32_t *outByte, uint32_t *outBranch,
    uint32_t *outLineFirstChar, uint32_t *outLineLength, double *outX);
static CjguiInternalRendererStatus text_stop_neighbor_impl(uint64_t token,
    uint64_t nodeId, int64_t displayByte, uint32_t branchIn, uint32_t left,
    uint64_t expectedSceneVersion, uint32_t *outByte, uint32_t *outBranch);
static int32_t set_composable_range_edit_delta_impl(uint64_t token,
    int32_t enabled);
static CjguiInternalRendererStatus set_composable_context_menu_guard_impl(
    uint64_t token, uint64_t sceneVersion, uint64_t layerScope,
    uint64_t requestId, uint64_t layerNodeId, int64_t resourceId,
    uint32_t nodeKind, int64_t x, int64_t y, int64_t width, int64_t height,
    uint32_t enabled);
static CjguiInternalRendererStatus configure_composable_data_transfer_impl(
    uint64_t token, uint64_t projectionVersion, uint32_t itemCount);
static CjguiInternalRendererStatus set_composable_data_transfer_item_impl(
    uint64_t token, uint32_t itemIndex,
    const CjguiInternalRendererComposableDataTransferItem *item,
    const char *format, const char *payload, const char *sourceKind,
    const char *sourceIdentity);
static CjguiInternalRendererStatus set_composable_data_transfer_item_bytes_impl(
    uint64_t token, uint32_t itemIndex, const uint8_t *bytes, uint32_t length);
static CjguiInternalRendererStatus copy_data_transfer_event_binary_impl(
    uint64_t token, uint64_t eventId, uint8_t *outBytes, uint32_t capacity);
static CjguiInternalRendererStatus configure_shared_operation_impl(
    uint64_t token, uint32_t visibleRecordCount);
static CjguiInternalRendererStatus set_shared_operation_title_impl(uint64_t token,
    uint32_t recordIndex, const char *title);
static CjguiInternalRendererStatus set_shared_operation_state_impl(uint64_t token,
    const CjguiInternalRendererSharedOperationState *state);
static CjguiInternalRendererStatus configure_shared_form_impl(uint64_t token,
    uint32_t fieldCount);
static CjguiInternalRendererStatus set_shared_collection_row_impl(uint64_t token,
    uint32_t rowIndex, const char *title, uint8_t isSelected,
    uint32_t viewportStart, uint32_t totalRecordCount);
static CjguiInternalRendererStatus set_shared_form_field_impl(uint64_t token,
    uint32_t fieldIndex, const char *label, const char *draftText,
    const char *validationError, uint32_t editorKind, uint8_t isFocused,
    uint32_t selectionStart, uint32_t selectionEnd);
static CjguiInternalRendererStatus set_shared_form_status_impl(uint64_t token,
    const char *statusText);
static CjguiInternalRendererStatus configure_composable_command_menu_impl(
    uint64_t token, uint64_t projectionVersion, uint32_t itemCount);
static CjguiInternalRendererStatus set_composable_command_menu_item_impl(
    uint64_t token, uint32_t itemIndex, const char *commandId, const char *title,
    const char *menuGroup, const char *shortcut, uint32_t menuSection,
    uint64_t focusScope, uint8_t enabled, uint8_t checked);
static CjguiInternalRendererStatus commit_composable_command_menu_impl(
    uint64_t token);
static CjguiInternalRendererStatus configure_shared_collection_form_impl(
    uint64_t token, uint32_t fieldCount, uint32_t visibleRecordCount);
static CjguiInternalRendererStatus set_shared_collection_filter_impl(
    uint64_t token, const char *filterText);
static CjguiInternalRendererStatus measure_composable_multiline_natural_height_impl(
    uint64_t token, const char *text, double fontSize, uint32_t fontWeight,
    uint32_t fontFamily, uint32_t contentWidth, uint32_t *outHeight);
static CjguiInternalRendererStatus measure_composable_text_impl(uint64_t token,
    const char *text, double fontSize, uint32_t fontWeight, uint32_t fontFamily,
    uint32_t maximumWidth, CjguiInternalRendererTextMeasurement *outMeasurement);
static CjguiInternalRendererStatus begin_composable_preparation_impl(
    uint64_t token, uint64_t preparationId, uint64_t baseSceneVersion,
    uint64_t projectionVersion, uint32_t nodeCount);
static CjguiInternalRendererStatus prepare_composable_node_impl(uint64_t token,
    uint64_t preparationId, uint32_t index,
    const CjguiInternalRendererComposableNode *node,
    const CjguiInternalRendererComposableGeometry *geometry,
    const char *label, const char *value, const char *semanticId,
    const char *bindingKey, const char *rowKey, const char *parentRowKey,
    const char *semanticLabel, const char *encodedRuns);
static CjguiInternalRendererStatus advance_composable_preparation_impl(
    uint64_t token, uint64_t preparationId, uint64_t deadlineNs,
    uint32_t *outReady);
static CjguiInternalRendererStatus promote_composable_preparation_impl(
    uint64_t token, uint64_t preparationId);
static CjguiInternalRendererStatus cancel_composable_preparation_impl(
    uint64_t token, uint64_t preparationId);
static CjguiInternalRendererStatus configure_composable_scene_impl(
    uint64_t token, uint64_t projectionVersion, uint32_t nodeCount);
static CjguiInternalRendererStatus discard_composable_scene_candidate_impl(
    uint64_t token);
static CjguiInternalRendererStatus set_composable_scene_node_impl(uint64_t token,
    uint32_t nodeIndex, const CjguiInternalRendererComposableNode *node,
    const char *label, const char *value, const char *imageResourcePath,
    const char *imageResourceId, uint64_t imageResourceVersion);
static CjguiInternalRendererStatus set_composable_scene_node_bytes_impl(
    uint64_t token, uint32_t nodeIndex,
    const CjguiInternalRendererComposableNode *node, const char *label,
    const char *value, const char *imageResourcePath,
    const char *imageResourceId, uint64_t imageResourceVersion,
    const uint8_t *bytes, uint32_t length);
static CjguiInternalRendererStatus set_composable_node_semantic_identity_impl(
    uint64_t token, uint32_t nodeIndex, const char *semanticId);
static CjguiInternalRendererStatus set_composable_node_semantic_metadata_impl(
    uint64_t token, uint32_t nodeIndex, const char *bindingKey,
    const char *rowKey, const char *parentRowKey, const char *semanticLabel);
static CjguiInternalRendererStatus set_composable_text_runs_impl(uint64_t token,
    uint64_t nodeId, const char *encoded);
static CjguiInternalRendererStatus stage_window_background_impl(uint64_t token,
    uint64_t projectionVersion, uint32_t mode, uint32_t colorScheme);
static CjguiInternalRendererStatus window_background_snapshot_impl(uint64_t token,
    CjguiInternalRendererWindowBackgroundSnapshot *outSnapshot);

typedef struct CjguiWindowsImageStateCtx2 {
    uint64_t token;
    char *resourcePath;
    char *resourceId;
    uint64_t resourceVersion;
    uint32_t outState;
} CjguiWindowsImageStateCtx2;

static void cjgui_windows_prepare_image_free(void *raw) {
    CjguiWindowsImageStateCtx2 *c = (CjguiWindowsImageStateCtx2 *)raw;
    if (!c) return;
    free(c->resourcePath);
    free(c->resourceId);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_prepare_image_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsImageStateCtx2 *c = (CjguiWindowsImageStateCtx2 *)raw;
    return prepare_composable_image_resource_impl(c->token, c->resourcePath,
        c->resourceId, c->resourceVersion, &c->outState);
}

CjguiInternalRendererStatus cjgui_internal_renderer_prepare_composable_image_resource(
    uint64_t token, const char *resourcePath, const char *resourceId,
    uint64_t resourceVersion, uint32_t *outState) {
    if (!outState) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsImageStateCtx2 *ctx =
        (CjguiWindowsImageStateCtx2 *)calloc(1u, sizeof(CjguiWindowsImageStateCtx2));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->resourcePath = cjgui_windows_dup_string(resourcePath);
    ctx->resourceId = cjgui_windows_dup_string(resourceId);
    if ((resourcePath && !ctx->resourcePath) ||
        (resourceId && !ctx->resourceId)) {
        cjgui_windows_prepare_image_free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    ctx->resourceVersion = resourceVersion;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "prepare_image",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_prepare_image_proc, ctx,
        cjgui_windows_prepare_image_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) *outState = ctx->outState;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_prepare_image_free(ctx);
    return st;
}

typedef struct CjguiWindowsPngCtx {
    uint64_t token;
    char *resourceIdentity;
    uint8_t *bytes;
    uint32_t length;
    uint8_t accepted;
    uint32_t outWidth;
    uint32_t outHeight;
    uint64_t outDecodeMicros;
    int isPrepare;
} CjguiWindowsPngCtx;

static void cjgui_windows_png_free(void *raw) {
    CjguiWindowsPngCtx *c = (CjguiWindowsPngCtx *)raw;
    if (!c) return;
    free(c->resourceIdentity);
    free(c->bytes);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_png_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsPngCtx *c = (CjguiWindowsPngCtx *)raw;
    if (c->isPrepare) {
        return prepare_composable_png_transfer_impl(c->token,
            c->resourceIdentity, c->bytes, c->length, &c->outWidth,
            &c->outHeight, &c->outDecodeMicros);
    }
    return finish_composable_png_transfer_impl(c->token, c->resourceIdentity,
        c->accepted);
}

CjguiInternalRendererStatus cjgui_internal_renderer_prepare_composable_png_transfer(
    uint64_t token, const char *resourceIdentity, const uint8_t *bytes,
    uint32_t length, uint32_t *outWidth, uint32_t *outHeight,
    uint64_t *outDecodeMicros) {
    if (!outWidth || !outHeight || !outDecodeMicros)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsPngCtx *ctx =
        (CjguiWindowsPngCtx *)calloc(1u, sizeof(CjguiWindowsPngCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->resourceIdentity = cjgui_windows_dup_string(resourceIdentity);
    ctx->bytes = cjgui_windows_dup_bytes(bytes, length);
    ctx->length = length;
    ctx->isPrepare = 1;
    if ((resourceIdentity && !ctx->resourceIdentity) ||
        (length && !ctx->bytes)) {
        cjgui_windows_png_free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "prepare_png",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_png_proc, ctx,
        cjgui_windows_png_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outWidth = ctx->outWidth;
        *outHeight = ctx->outHeight;
        *outDecodeMicros = ctx->outDecodeMicros;
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_png_free(ctx);
    return st;
}

CjguiInternalRendererStatus cjgui_internal_renderer_finish_composable_png_transfer(
    uint64_t token, const char *resourceIdentity, uint8_t accepted) {
    CjguiWindowsPngCtx *ctx =
        (CjguiWindowsPngCtx *)calloc(1u, sizeof(CjguiWindowsPngCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->resourceIdentity = cjgui_windows_dup_string(resourceIdentity);
    ctx->accepted = accepted;
    if (resourceIdentity && !ctx->resourceIdentity) {
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "finish_png",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_png_proc, ctx,
        cjgui_windows_png_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_png_free(ctx);
    return st;
}

typedef struct CjguiWindowsTextStatsCtx {
    uint64_t token;
    uint64_t counts[4];
} CjguiWindowsTextStatsCtx;

static CjguiInternalRendererStatus cjgui_windows_text_stats_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsTextStatsCtx *c = (CjguiWindowsTextStatsCtx *)raw;
    return text_position_stats_v1_impl(c->token, c->counts);
}

CjguiInternalRendererStatus cjgui_internal_renderer_text_position_stats_v1(
    uint64_t token, uint64_t *counts) {
    if (!counts) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsTextStatsCtx *ctx =
        (CjguiWindowsTextStatsCtx *)calloc(1u, sizeof(CjguiWindowsTextStatsCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "text_stats",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_text_stats_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) memcpy(counts, ctx->counts,
        sizeof(ctx->counts));
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsCaretGeomCtx {
    uint64_t token;
    int64_t nodeId;
    int64_t displayByte;
    double caretWidthPt;
    uint64_t expectedSceneVersion;
    uint32_t affinity;
    double outX;
    double outY;
    double outWidth;
    double outHeight;
} CjguiWindowsCaretGeomCtx;

static CjguiInternalRendererStatus cjgui_windows_caret_geom_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsCaretGeomCtx *c = (CjguiWindowsCaretGeomCtx *)raw;
    return text_geometry_caret_impl(c->token, c->nodeId, c->displayByte,
        c->caretWidthPt, c->expectedSceneVersion, c->affinity, &c->outX,
        &c->outY, &c->outWidth, &c->outHeight);
}

CjguiInternalRendererStatus cjgui_internal_renderer_text_geometry_caret(
    uint64_t token, int64_t nodeId, int64_t displayByte, double caretWidthPt,
    uint64_t expectedSceneVersion, uint32_t affinity, double *outX,
    double *outY, double *outWidth, double *outHeight) {
    if (!outX || !outY || !outWidth || !outHeight)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsCaretGeomCtx *ctx =
        (CjguiWindowsCaretGeomCtx *)calloc(1u, sizeof(CjguiWindowsCaretGeomCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeId = nodeId;
    ctx->displayByte = displayByte;
    ctx->caretWidthPt = caretWidthPt;
    ctx->expectedSceneVersion = expectedSceneVersion;
    ctx->affinity = affinity;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "caret_geom",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_caret_geom_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outX = ctx->outX;
        *outY = ctx->outY;
        *outWidth = ctx->outWidth;
        *outHeight = ctx->outHeight;
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsVisualNeighborCtx {
    uint64_t token;
    uint64_t nodeId;
    int64_t displayByte;
    uint32_t left;
    uint64_t expectedSceneVersion;
    uint32_t caretAffinity;
    uint32_t outNeighborByte;
    uint32_t outAffinity;
} CjguiWindowsVisualNeighborCtx;

static CjguiInternalRendererStatus cjgui_windows_visual_neighbor_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsVisualNeighborCtx *c = (CjguiWindowsVisualNeighborCtx *)raw;
    return text_visual_neighbor_impl(c->token, c->nodeId, c->displayByte,
        c->left, c->expectedSceneVersion, c->caretAffinity,
        &c->outNeighborByte, &c->outAffinity);
}

CjguiInternalRendererStatus cjgui_internal_renderer_text_visual_neighbor(
    uint64_t token, uint64_t nodeId, int64_t displayByte, uint32_t left,
    uint64_t expectedSceneVersion, uint32_t caretAffinity,
    uint32_t *outNeighborByte, uint32_t *outAffinity) {
    if (!outNeighborByte || !outAffinity)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsVisualNeighborCtx *ctx =
        (CjguiWindowsVisualNeighborCtx *)calloc(1u, sizeof(CjguiWindowsVisualNeighborCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeId = nodeId;
    ctx->displayByte = displayByte;
    ctx->left = left;
    ctx->expectedSceneVersion = expectedSceneVersion;
    ctx->caretAffinity = caretAffinity;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "vis_neighbor",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_visual_neighbor_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outNeighborByte = ctx->outNeighborByte;
        *outAffinity = ctx->outAffinity;
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsDiagNodeGeomCtx {
    uint64_t token;
    uint32_t nodeIndex;
    CjguiInternalRendererDiagnosticNodeGeometry geometry;
} CjguiWindowsDiagNodeGeomCtx;

static CjguiInternalRendererStatus cjgui_windows_diag_node_geom_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsDiagNodeGeomCtx *c = (CjguiWindowsDiagNodeGeomCtx *)raw;
    return diagnostic_node_geometry_impl(c->token, c->nodeIndex, &c->geometry);
}

CjguiInternalRendererStatus cjgui_internal_renderer_diagnostic_node_geometry(
    uint64_t token, uint32_t nodeIndex,
    CjguiInternalRendererDiagnosticNodeGeometry *outGeometry) {
    if (!outGeometry) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsDiagNodeGeomCtx *ctx =
        (CjguiWindowsDiagNodeGeomCtx *)calloc(1u, sizeof(CjguiWindowsDiagNodeGeomCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeIndex = nodeIndex;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "diag_node",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_diag_node_geom_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) *outGeometry = ctx->geometry;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsStopResolveCtx {
    uint64_t token;
    uint64_t nodeId;
    int64_t displayByte;
    uint32_t branchIn;
    uint64_t expectedSceneVersion;
    uint32_t left;
    uint32_t outByte;
    uint32_t outBranch;
    uint32_t outLineFirstChar;
    uint32_t outLineLength;
    double outX;
    int isNeighbor;
} CjguiWindowsStopResolveCtx;

static CjguiInternalRendererStatus cjgui_windows_stop_resolve_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsStopResolveCtx *c = (CjguiWindowsStopResolveCtx *)raw;
    if (c->isNeighbor) {
        return text_stop_neighbor_impl(c->token, c->nodeId, c->displayByte,
            c->branchIn, c->left, c->expectedSceneVersion, &c->outByte,
            &c->outBranch);
    }
    return text_stop_resolve_impl(c->token, c->nodeId, c->displayByte,
        c->branchIn, c->expectedSceneVersion, &c->outByte, &c->outBranch,
        &c->outLineFirstChar, &c->outLineLength, &c->outX);
}

CjguiInternalRendererStatus cjgui_internal_renderer_text_stop_resolve(
    uint64_t token, uint64_t nodeId, int64_t displayByte, uint32_t branchIn,
    uint64_t expectedSceneVersion, uint32_t *outByte, uint32_t *outBranch,
    uint32_t *outLineFirstChar, uint32_t *outLineLength, double *outX) {
    if (!outByte || !outBranch || !outLineFirstChar || !outLineLength || !outX)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsStopResolveCtx *ctx =
        (CjguiWindowsStopResolveCtx *)calloc(1u, sizeof(CjguiWindowsStopResolveCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeId = nodeId;
    ctx->displayByte = displayByte;
    ctx->branchIn = branchIn;
    ctx->expectedSceneVersion = expectedSceneVersion;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "stop_resolve",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_stop_resolve_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outByte = ctx->outByte;
        *outBranch = ctx->outBranch;
        *outLineFirstChar = ctx->outLineFirstChar;
        *outLineLength = ctx->outLineLength;
        *outX = ctx->outX;
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

CjguiInternalRendererStatus cjgui_internal_renderer_text_stop_neighbor(
    uint64_t token, uint64_t nodeId, int64_t displayByte, uint32_t branchIn,
    uint32_t left, uint64_t expectedSceneVersion, uint32_t *outByte,
    uint32_t *outBranch) {
    if (!outByte || !outBranch) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsStopResolveCtx *ctx =
        (CjguiWindowsStopResolveCtx *)calloc(1u, sizeof(CjguiWindowsStopResolveCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeId = nodeId;
    ctx->displayByte = displayByte;
    ctx->branchIn = branchIn;
    ctx->left = left;
    ctx->expectedSceneVersion = expectedSceneVersion;
    ctx->isNeighbor = 1;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "stop_neighbor",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_stop_resolve_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outByte = ctx->outByte;
        *outBranch = ctx->outBranch;
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsDeltaCtx {
    uint64_t token;
    int32_t enabled;
    int32_t result;
} CjguiWindowsDeltaCtx;

static CjguiInternalRendererStatus cjgui_windows_delta_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsDeltaCtx *c = (CjguiWindowsDeltaCtx *)raw;
    c->result = set_composable_range_edit_delta_impl(c->token, c->enabled);
    return (CjguiInternalRendererStatus)c->result;
}

int32_t cjgui_internal_renderer_set_composable_range_edit_delta(uint64_t token,
    int32_t enabled) {
    CjguiWindowsDeltaCtx *ctx =
        (CjguiWindowsDeltaCtx *)calloc(1u, sizeof(CjguiWindowsDeltaCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->enabled = enabled;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "range_delta",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_delta_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    int32_t result = (int32_t)st;
    if (st == CJGUI_INTERNAL_RENDERER_OK) result = ctx->result;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return result;
}

typedef struct CjguiWindowsMenuGuardCtx {
    uint64_t token;
    uint64_t sceneVersion;
    uint64_t layerScope;
    uint64_t requestId;
    uint64_t layerNodeId;
    int64_t resourceId;
    uint32_t nodeKind;
    int64_t x;
    int64_t y;
    int64_t width;
    int64_t height;
    uint32_t enabled;
} CjguiWindowsMenuGuardCtx;

static CjguiInternalRendererStatus cjgui_windows_menu_guard_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsMenuGuardCtx *c = (CjguiWindowsMenuGuardCtx *)raw;
    return set_composable_context_menu_guard_impl(c->token, c->sceneVersion,
        c->layerScope, c->requestId, c->layerNodeId, c->resourceId,
        c->nodeKind, c->x, c->y, c->width, c->height, c->enabled);
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_context_menu_guard(
    uint64_t token, uint64_t sceneVersion, uint64_t layerScope,
    uint64_t requestId, uint64_t layerNodeId, int64_t resourceId,
    uint32_t nodeKind, int64_t x, int64_t y, int64_t width, int64_t height,
    uint32_t enabled) {
    CjguiWindowsMenuGuardCtx *ctx =
        (CjguiWindowsMenuGuardCtx *)calloc(1u, sizeof(CjguiWindowsMenuGuardCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->sceneVersion = sceneVersion;
    ctx->layerScope = layerScope;
    ctx->requestId = requestId;
    ctx->layerNodeId = layerNodeId;
    ctx->resourceId = resourceId;
    ctx->nodeKind = nodeKind;
    ctx->x = x;
    ctx->y = y;
    ctx->width = width;
    ctx->height = height;
    ctx->enabled = enabled;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "menu_guard",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_menu_guard_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsTransferItemCtx {
    uint64_t token;
    uint32_t itemIndex;
    CjguiInternalRendererComposableDataTransferItem item;
    int hasItem;
    char *format;
    char *payload;
    char *sourceKind;
    char *sourceIdentity;
    uint8_t *bytes;
    uint32_t length;
    int hasBytes;
} CjguiWindowsTransferItemCtx;

static void cjgui_windows_transfer_item_free(void *raw) {
    CjguiWindowsTransferItemCtx *c = (CjguiWindowsTransferItemCtx *)raw;
    if (!c) return;
    free(c->format);
    free(c->payload);
    free(c->sourceKind);
    free(c->sourceIdentity);
    free(c->bytes);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_transfer_item_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsTransferItemCtx *c = (CjguiWindowsTransferItemCtx *)raw;
    if (c->hasBytes) {
        return set_composable_data_transfer_item_bytes_impl(c->token,
            c->itemIndex, c->bytes, c->length);
    }
    return set_composable_data_transfer_item_impl(c->token, c->itemIndex,
        c->hasItem ? &c->item : NULL, c->format, c->payload, c->sourceKind,
        c->sourceIdentity);
}

static CjguiInternalRendererStatus cjgui_windows_config_xfer_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsConfigSceneCtx *c = (CjguiWindowsConfigSceneCtx *)raw;
    return configure_composable_data_transfer_impl(c->token,
        c->projectionVersion, c->nodeCount);
}

CjguiInternalRendererStatus cjgui_internal_renderer_configure_composable_data_transfer(
    uint64_t token, uint64_t projectionVersion, uint32_t itemCount) {
    CjguiWindowsConfigSceneCtx *ctx =
        (CjguiWindowsConfigSceneCtx *)calloc(1u, sizeof(CjguiWindowsConfigSceneCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->projectionVersion = projectionVersion;
    ctx->nodeCount = itemCount;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "config_xfer",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_config_xfer_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_data_transfer_item(
    uint64_t token, uint32_t itemIndex,
    const CjguiInternalRendererComposableDataTransferItem *item,
    const char *format, const char *payload, const char *sourceKind,
    const char *sourceIdentity) {
    CjguiWindowsTransferItemCtx *ctx =
        (CjguiWindowsTransferItemCtx *)calloc(1u, sizeof(CjguiWindowsTransferItemCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->itemIndex = itemIndex;
    if (item) {
        ctx->item = *item;
        ctx->hasItem = 1;
    }
    ctx->format = cjgui_windows_dup_string(format);
    ctx->payload = cjgui_windows_dup_string(payload);
    ctx->sourceKind = cjgui_windows_dup_string(sourceKind);
    ctx->sourceIdentity = cjgui_windows_dup_string(sourceIdentity);
    if ((format && !ctx->format) || (payload && !ctx->payload) ||
        (sourceKind && !ctx->sourceKind) ||
        (sourceIdentity && !ctx->sourceIdentity)) {
        cjgui_windows_transfer_item_free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "xfer_item",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_transfer_item_proc, ctx,
        cjgui_windows_transfer_item_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_transfer_item_free(ctx);
    return st;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_data_transfer_item_bytes(
    uint64_t token, uint32_t itemIndex, const uint8_t *bytes, uint32_t length) {
    CjguiWindowsTransferItemCtx *ctx =
        (CjguiWindowsTransferItemCtx *)calloc(1u, sizeof(CjguiWindowsTransferItemCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->itemIndex = itemIndex;
    ctx->bytes = cjgui_windows_dup_bytes(bytes, length);
    ctx->length = length;
    ctx->hasBytes = 1;
    if (length && !ctx->bytes) {
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "xfer_bytes",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_transfer_item_proc, ctx,
        cjgui_windows_transfer_item_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_transfer_item_free(ctx);
    return st;
}

typedef struct CjguiWindowsXferCopyCtx {
    uint64_t token;
    uint64_t eventId;
    uint32_t capacity;
} CjguiWindowsXferCopyCtx;

static CjguiInternalRendererStatus cjgui_windows_xfer_copy_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsXferCopyCtx *c = (CjguiWindowsXferCopyCtx *)raw;
    return copy_data_transfer_event_binary_impl(c->token, c->eventId, NULL,
        c->capacity);
}

CjguiInternalRendererStatus cjgui_internal_renderer_copy_data_transfer_event_binary(
    uint64_t token, uint64_t eventId, uint8_t *outBytes, uint32_t capacity) {
    (void)outBytes;
    CjguiWindowsXferCopyCtx *ctx =
        (CjguiWindowsXferCopyCtx *)calloc(1u, sizeof(CjguiWindowsXferCopyCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->eventId = eventId;
    ctx->capacity = capacity;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "xfer_copy",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_xfer_copy_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_config_shared_op_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsConfigSceneCtx *c = (CjguiWindowsConfigSceneCtx *)raw;
    return configure_shared_operation_impl(c->token, c->nodeCount);
}

CjguiInternalRendererStatus cjgui_internal_renderer_configure_shared_operation(
    uint64_t token, uint32_t visibleRecordCount) {
    CjguiWindowsConfigSceneCtx *ctx =
        (CjguiWindowsConfigSceneCtx *)calloc(1u, sizeof(CjguiWindowsConfigSceneCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeCount = visibleRecordCount;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "config_shared",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_config_shared_op_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsSharedTitleCtx {
    uint64_t token;
    uint32_t recordIndex;
    char *title;
} CjguiWindowsSharedTitleCtx;

static void cjgui_windows_shared_title_free(void *raw) {
    CjguiWindowsSharedTitleCtx *c = (CjguiWindowsSharedTitleCtx *)raw;
    if (!c) return;
    free(c->title);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_shared_title_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsSharedTitleCtx *c = (CjguiWindowsSharedTitleCtx *)raw;
    return set_shared_operation_title_impl(c->token, c->recordIndex, c->title);
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_shared_operation_title(
    uint64_t token, uint32_t recordIndex, const char *title) {
    CjguiWindowsSharedTitleCtx *ctx =
        (CjguiWindowsSharedTitleCtx *)calloc(1u, sizeof(CjguiWindowsSharedTitleCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->recordIndex = recordIndex;
    ctx->title = cjgui_windows_dup_string(title);
    if (title && !ctx->title) {
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "shared_title",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_shared_title_proc, ctx,
        cjgui_windows_shared_title_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_shared_title_free(ctx);
    return st;
}

typedef struct CjguiWindowsSharedStateCtx {
    uint64_t token;
    CjguiInternalRendererSharedOperationState state;
    int hasState;
} CjguiWindowsSharedStateCtx;

static CjguiInternalRendererStatus cjgui_windows_shared_state_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsSharedStateCtx *c = (CjguiWindowsSharedStateCtx *)raw;
    return set_shared_operation_state_impl(c->token,
        c->hasState ? &c->state : NULL);
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_shared_operation_state(
    uint64_t token, const CjguiInternalRendererSharedOperationState *state) {
    CjguiWindowsSharedStateCtx *ctx =
        (CjguiWindowsSharedStateCtx *)calloc(1u, sizeof(CjguiWindowsSharedStateCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    if (state) {
        ctx->state = *state;
        ctx->hasState = 1;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "shared_state",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_shared_state_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_config_form_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsConfigSceneCtx *c = (CjguiWindowsConfigSceneCtx *)raw;
    return configure_shared_form_impl(c->token, c->nodeCount);
}

CjguiInternalRendererStatus cjgui_internal_renderer_configure_shared_form(
    uint64_t token, uint32_t fieldCount) {
    CjguiWindowsConfigSceneCtx *ctx =
        (CjguiWindowsConfigSceneCtx *)calloc(1u, sizeof(CjguiWindowsConfigSceneCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeCount = fieldCount;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "config_form",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_config_form_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsCollectionRowCtx {
    uint64_t token;
    uint32_t rowIndex;
    char *title;
    uint8_t isSelected;
    uint32_t viewportStart;
    uint32_t totalRecordCount;
} CjguiWindowsCollectionRowCtx;

static void cjgui_windows_collection_row_free(void *raw) {
    CjguiWindowsCollectionRowCtx *c = (CjguiWindowsCollectionRowCtx *)raw;
    if (!c) return;
    free(c->title);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_collection_row_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsCollectionRowCtx *c = (CjguiWindowsCollectionRowCtx *)raw;
    return set_shared_collection_row_impl(c->token, c->rowIndex, c->title,
        c->isSelected, c->viewportStart, c->totalRecordCount);
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_shared_collection_row(
    uint64_t token, uint32_t rowIndex, const char *title, uint8_t isSelected,
    uint32_t viewportStart, uint32_t totalRecordCount) {
    CjguiWindowsCollectionRowCtx *ctx =
        (CjguiWindowsCollectionRowCtx *)calloc(1u, sizeof(CjguiWindowsCollectionRowCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->rowIndex = rowIndex;
    ctx->title = cjgui_windows_dup_string(title);
    ctx->isSelected = isSelected;
    ctx->viewportStart = viewportStart;
    ctx->totalRecordCount = totalRecordCount;
    if (title && !ctx->title) {
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "coll_row",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_collection_row_proc, ctx,
        cjgui_windows_collection_row_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_collection_row_free(ctx);
    return st;
}

typedef struct CjguiWindowsFormFieldCtx {
    uint64_t token;
    uint32_t fieldIndex;
    char *label;
    char *draftText;
    char *validationError;
    uint32_t editorKind;
    uint8_t isFocused;
    uint32_t selectionStart;
    uint32_t selectionEnd;
} CjguiWindowsFormFieldCtx;

static void cjgui_windows_form_field_free(void *raw) {
    CjguiWindowsFormFieldCtx *c = (CjguiWindowsFormFieldCtx *)raw;
    if (!c) return;
    free(c->label);
    free(c->draftText);
    free(c->validationError);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_form_field_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsFormFieldCtx *c = (CjguiWindowsFormFieldCtx *)raw;
    return set_shared_form_field_impl(c->token, c->fieldIndex, c->label,
        c->draftText, c->validationError, c->editorKind, c->isFocused,
        c->selectionStart, c->selectionEnd);
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_shared_form_field(
    uint64_t token, uint32_t fieldIndex, const char *label,
    const char *draftText, const char *validationError, uint32_t editorKind,
    uint8_t isFocused, uint32_t selectionStart, uint32_t selectionEnd) {
    CjguiWindowsFormFieldCtx *ctx =
        (CjguiWindowsFormFieldCtx *)calloc(1u, sizeof(CjguiWindowsFormFieldCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->fieldIndex = fieldIndex;
    ctx->label = cjgui_windows_dup_string(label);
    ctx->draftText = cjgui_windows_dup_string(draftText);
    ctx->validationError = cjgui_windows_dup_string(validationError);
    ctx->editorKind = editorKind;
    ctx->isFocused = isFocused;
    ctx->selectionStart = selectionStart;
    ctx->selectionEnd = selectionEnd;
    if ((label && !ctx->label) || (draftText && !ctx->draftText) ||
        (validationError && !ctx->validationError)) {
        cjgui_windows_form_field_free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "form_field",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_form_field_proc, ctx,
        cjgui_windows_form_field_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_form_field_free(ctx);
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_form_status_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsSharedTitleCtx *c = (CjguiWindowsSharedTitleCtx *)raw;
    return set_shared_form_status_impl(c->token, c->title);
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_shared_form_status(
    uint64_t token, const char *statusText) {
    CjguiWindowsSharedTitleCtx *ctx =
        (CjguiWindowsSharedTitleCtx *)calloc(1u, sizeof(CjguiWindowsSharedTitleCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->title = cjgui_windows_dup_string(statusText);
    if (statusText && !ctx->title) {
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "form_status",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_form_status_proc, ctx,
        cjgui_windows_shared_title_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_shared_title_free(ctx);
    return st;
}

typedef struct CjguiWindowsMenuCtx {
    uint64_t token;
    uint64_t projectionVersion;
    uint32_t itemCount;
    uint32_t itemIndex;
    char *commandId;
    char *title;
    char *menuGroup;
    char *shortcut;
    uint32_t menuSection;
    uint64_t focusScope;
    uint8_t enabled;
    uint8_t checked;
    int isItem;
} CjguiWindowsMenuCtx;

static void cjgui_windows_menu_free(void *raw) {
    CjguiWindowsMenuCtx *c = (CjguiWindowsMenuCtx *)raw;
    if (!c) return;
    free(c->commandId);
    free(c->title);
    free(c->menuGroup);
    free(c->shortcut);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_menu_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsMenuCtx *c = (CjguiWindowsMenuCtx *)raw;
    if (c->isItem) {
        return set_composable_command_menu_item_impl(c->token, c->itemIndex,
            c->commandId, c->title, c->menuGroup, c->shortcut, c->menuSection,
            c->focusScope, c->enabled, c->checked);
    }
    return configure_composable_command_menu_impl(c->token,
        c->projectionVersion, c->itemCount);
}

CjguiInternalRendererStatus cjgui_internal_renderer_configure_composable_command_menu(
    uint64_t token, uint64_t projectionVersion, uint32_t itemCount) {
    CjguiWindowsMenuCtx *ctx =
        (CjguiWindowsMenuCtx *)calloc(1u, sizeof(CjguiWindowsMenuCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->projectionVersion = projectionVersion;
    ctx->itemCount = itemCount;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "config_menu",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_menu_proc, ctx,
        cjgui_windows_menu_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_menu_free(ctx);
    return st;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_command_menu_item(
    uint64_t token, uint32_t itemIndex, const char *commandId,
    const char *title, const char *menuGroup, const char *shortcut,
    uint32_t menuSection, uint64_t focusScope, uint8_t enabled,
    uint8_t checked) {
    CjguiWindowsMenuCtx *ctx =
        (CjguiWindowsMenuCtx *)calloc(1u, sizeof(CjguiWindowsMenuCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->itemIndex = itemIndex;
    ctx->commandId = cjgui_windows_dup_string(commandId);
    ctx->title = cjgui_windows_dup_string(title);
    ctx->menuGroup = cjgui_windows_dup_string(menuGroup);
    ctx->shortcut = cjgui_windows_dup_string(shortcut);
    ctx->menuSection = menuSection;
    ctx->focusScope = focusScope;
    ctx->enabled = enabled;
    ctx->checked = checked;
    ctx->isItem = 1;
    if ((commandId && !ctx->commandId) || (title && !ctx->title) ||
        (menuGroup && !ctx->menuGroup) || (shortcut && !ctx->shortcut)) {
        cjgui_windows_menu_free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "menu_item",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_menu_proc, ctx,
        cjgui_windows_menu_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_menu_free(ctx);
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_commit_menu_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsTokenCtx *c = (CjguiWindowsTokenCtx *)raw;
    return commit_composable_command_menu_impl(c->token);
}

CjguiInternalRendererStatus cjgui_internal_renderer_commit_composable_command_menu(
    uint64_t token) {
    CjguiWindowsTokenCtx *ctx =
        (CjguiWindowsTokenCtx *)calloc(1u, sizeof(CjguiWindowsTokenCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "commit_menu",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_commit_menu_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_config_coll_form_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsConfigSceneCtx *c = (CjguiWindowsConfigSceneCtx *)raw;
    return configure_shared_collection_form_impl(c->token, c->nodeCount,
        (uint32_t)c->projectionVersion);
}

CjguiInternalRendererStatus cjgui_internal_renderer_configure_shared_collection_form(
    uint64_t token, uint32_t fieldCount, uint32_t visibleRecordCount) {
    CjguiWindowsConfigSceneCtx *ctx =
        (CjguiWindowsConfigSceneCtx *)calloc(1u, sizeof(CjguiWindowsConfigSceneCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->nodeCount = fieldCount;
    ctx->projectionVersion = visibleRecordCount;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "config_coll",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_config_coll_form_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

static CjguiInternalRendererStatus cjgui_windows_coll_filter_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsSharedTitleCtx *c = (CjguiWindowsSharedTitleCtx *)raw;
    return set_shared_collection_filter_impl(c->token, c->title);
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_shared_collection_filter(
    uint64_t token, const char *filterText) {
    CjguiWindowsSharedTitleCtx *ctx =
        (CjguiWindowsSharedTitleCtx *)calloc(1u, sizeof(CjguiWindowsSharedTitleCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->title = cjgui_windows_dup_string(filterText);
    if (filterText && !ctx->title) {
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "coll_filter",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_coll_filter_proc, ctx,
        cjgui_windows_shared_title_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_shared_title_free(ctx);
    return st;
}

typedef struct CjguiWindowsMeasureCtx {
    uint64_t token;
    char *text;
    double fontSize;
    uint32_t fontWeight;
    uint32_t fontFamily;
    uint32_t width;
    uint32_t outHeight;
    CjguiInternalRendererTextMeasurement measurement;
    int isMultiline;
} CjguiWindowsMeasureCtx;

static void cjgui_windows_measure_free(void *raw) {
    CjguiWindowsMeasureCtx *c = (CjguiWindowsMeasureCtx *)raw;
    if (!c) return;
    free(c->text);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_measure_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsMeasureCtx *c = (CjguiWindowsMeasureCtx *)raw;
    if (c->isMultiline) {
        return measure_composable_multiline_natural_height_impl(c->token,
            c->text, c->fontSize, c->fontWeight, c->fontFamily, c->width,
            &c->outHeight);
    }
    return measure_composable_text_impl(c->token, c->text, c->fontSize,
        c->fontWeight, c->fontFamily, c->width, &c->measurement);
}

CjguiInternalRendererStatus cjgui_internal_renderer_measure_composable_multiline_natural_height(
    uint64_t token, const char *text, double fontSize, uint32_t fontWeight,
    uint32_t fontFamily, uint32_t contentWidth, uint32_t *outHeight) {
    if (!outHeight) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsMeasureCtx *ctx =
        (CjguiWindowsMeasureCtx *)calloc(1u, sizeof(CjguiWindowsMeasureCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->text = cjgui_windows_dup_string(text);
    ctx->fontSize = fontSize;
    ctx->fontWeight = fontWeight;
    ctx->fontFamily = fontFamily;
    ctx->width = contentWidth;
    ctx->isMultiline = 1;
    if (text && !ctx->text) {
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "measure_multi",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_measure_proc, ctx,
        cjgui_windows_measure_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) *outHeight = ctx->outHeight;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_measure_free(ctx);
    return st;
}

CjguiInternalRendererStatus cjgui_internal_renderer_measure_composable_text(
    uint64_t token, const char *text, double fontSize, uint32_t fontWeight,
    uint32_t fontFamily, uint32_t maximumWidth,
    CjguiInternalRendererTextMeasurement *outMeasurement) {
    if (!outMeasurement) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsMeasureCtx *ctx =
        (CjguiWindowsMeasureCtx *)calloc(1u, sizeof(CjguiWindowsMeasureCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->text = cjgui_windows_dup_string(text);
    ctx->fontSize = fontSize;
    ctx->fontWeight = fontWeight;
    ctx->fontFamily = fontFamily;
    ctx->width = maximumWidth;
    if (text && !ctx->text) {
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "measure_text",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_measure_proc, ctx,
        cjgui_windows_measure_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) *outMeasurement = ctx->measurement;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_measure_free(ctx);
    return st;
}

static CjguiInternalRendererStatus present_ticket_stats_impl(uint64_t token,
    CjguiInternalRendererPresentTicketStats *outStats);
static uint8_t source_install_pending_scalar_impl(uint64_t token);
static uint64_t source_install_gated_inputs_impl(uint64_t token);
static int32_t probe_image_texture_impl(uint64_t token, uint64_t nodeId,
    int32_t *outFound, int32_t *outHasTexture, int32_t *outCacheKeyLength,
    int32_t *outFailed);
static CjguiInternalRendererStatus set_diagnostic_timing_impl(uint64_t token,
    uint32_t enabled);
static CjguiInternalRendererStatus set_diagnostic_overlay_impl(uint64_t token,
    uint32_t flags, uint64_t selectedNodeId, uint8_t hasSelection);
static int32_t text_line_rect_count_impl(uint64_t token, uint64_t nodeId,
    int64_t startByte, int64_t endByte, int32_t maxRects,
    uint64_t expectedSceneVersion);
static int32_t window_number_impl(uint64_t token, int64_t *outNumber);
static const char *data_transfer_event_format_impl(uint64_t token);
static uint32_t data_transfer_event_binary_size_impl(uint64_t token,
    uint64_t eventId);

typedef struct CjguiWindowsTicketStatsCtx {
    uint64_t token;
    CjguiInternalRendererPresentTicketStats stats;
} CjguiWindowsTicketStatsCtx;

static CjguiInternalRendererStatus cjgui_windows_ticket_stats_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsTicketStatsCtx *c = (CjguiWindowsTicketStatsCtx *)raw;
    return present_ticket_stats_impl(c->token, &c->stats);
}

CjguiInternalRendererStatus cjgui_internal_renderer_present_ticket_stats(
    uint64_t token, CjguiInternalRendererPresentTicketStats *outStats) {
    return present_ticket_stats_impl(token, outStats);
}


typedef struct CjguiWindowsGateScalarCtx {
    uint64_t token;
    uint64_t value;
} CjguiWindowsGateScalarCtx;

static CjguiInternalRendererStatus cjgui_windows_gate_inputs_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsGateScalarCtx *c = (CjguiWindowsGateScalarCtx *)raw;
    c->value = source_install_gated_inputs_impl(c->token);
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus cjgui_windows_gate_pending_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsGateScalarCtx *c = (CjguiWindowsGateScalarCtx *)raw;
    c->value = source_install_pending_scalar_impl(c->token);
    return CJGUI_INTERNAL_RENDERER_OK;
}

uint8_t cjgui_internal_renderer_source_install_pending_scalar(uint64_t token) {
    CjguiWindowsGateScalarCtx *ctx =
        (CjguiWindowsGateScalarCtx *)calloc(1u, sizeof(CjguiWindowsGateScalarCtx));
    if (!ctx) return 0u;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "gate_pending",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_gate_pending_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    uint8_t value = 0u;
    if (st == CJGUI_INTERNAL_RENDERER_OK) value = (uint8_t)ctx->value;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return value;
}

uint64_t cjgui_internal_renderer_source_install_gated_inputs(uint64_t token) {
    CjguiWindowsGateScalarCtx *ctx =
        (CjguiWindowsGateScalarCtx *)calloc(1u, sizeof(CjguiWindowsGateScalarCtx));
    if (!ctx) return 0u;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "gate_inputs",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_gate_inputs_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    uint64_t value = 0u;
    if (st == CJGUI_INTERNAL_RENDERER_OK) value = ctx->value;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return value;
}

typedef struct CjguiWindowsImageProbeCtx {
    uint64_t token;
    uint64_t nodeId;
    int32_t result;
    int32_t outFound;
    int32_t outHasTexture;
    int32_t outCacheKeyLength;
    int32_t outFailed;
} CjguiWindowsImageProbeCtx;

static CjguiInternalRendererStatus cjgui_windows_image_probe_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsImageProbeCtx *c = (CjguiWindowsImageProbeCtx *)raw;
    c->result = probe_image_texture_impl(c->token, c->nodeId, &c->outFound,
        &c->outHasTexture, &c->outCacheKeyLength, &c->outFailed);
    return CJGUI_INTERNAL_RENDERER_OK;
}

int32_t cjgui_internal_renderer_probe_image_texture(uint64_t token,
    uint64_t nodeId, int32_t *outFound, int32_t *outHasTexture,
    int32_t *outCacheKeyLength, int32_t *outFailed) {
    if (!outFound || !outHasTexture || !outCacheKeyLength || !outFailed) return 0;
    CjguiWindowsImageProbeCtx *ctx =
        (CjguiWindowsImageProbeCtx *)calloc(1u, sizeof(CjguiWindowsImageProbeCtx));
    if (!ctx) return 0;
    ctx->token = token;
    ctx->nodeId = nodeId;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "image_probe",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_image_probe_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    int32_t result = 0;
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outFound = ctx->outFound;
        *outHasTexture = ctx->outHasTexture;
        *outCacheKeyLength = ctx->outCacheKeyLength;
        *outFailed = ctx->outFailed;
        result = ctx->result;
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return result;
}

static CjguiInternalRendererStatus cjgui_windows_set_diag_timing_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsU64Ctx *c = (CjguiWindowsU64Ctx *)raw;
    return set_diagnostic_timing_impl(c->token, (uint32_t)c->value);
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_diagnostic_timing(
    uint64_t token, uint32_t enabled) {
    CjguiWindowsU64Ctx *ctx =
        (CjguiWindowsU64Ctx *)calloc(1u, sizeof(CjguiWindowsU64Ctx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->value = enabled;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "diag_timing",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_set_diag_timing_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsDiagOverlayCtx {
    uint64_t token;
    uint32_t flags;
    uint64_t selectedNodeId;
    uint8_t hasSelection;
} CjguiWindowsDiagOverlayCtx;

static CjguiInternalRendererStatus cjgui_windows_diag_overlay_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsDiagOverlayCtx *c = (CjguiWindowsDiagOverlayCtx *)raw;
    return set_diagnostic_overlay_impl(c->token, c->flags, c->selectedNodeId,
        c->hasSelection);
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_diagnostic_overlay(
    uint64_t token, uint32_t flags, uint64_t selectedNodeId,
    uint8_t hasSelection) {
    CjguiWindowsDiagOverlayCtx *ctx =
        (CjguiWindowsDiagOverlayCtx *)calloc(1u, sizeof(CjguiWindowsDiagOverlayCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->flags = flags;
    ctx->selectedNodeId = selectedNodeId;
    ctx->hasSelection = hasSelection;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "diag_overlay",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_diag_overlay_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsLineRectCtx {
    uint64_t token;
    uint64_t nodeId;
    int64_t startByte;
    int64_t endByte;
    int32_t maxRects;
    uint64_t expectedSceneVersion;
    int32_t result;
} CjguiWindowsLineRectCtx;

static CjguiInternalRendererStatus cjgui_windows_line_rect_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsLineRectCtx *c = (CjguiWindowsLineRectCtx *)raw;
    c->result = text_line_rect_count_impl(c->token, c->nodeId, c->startByte,
        c->endByte, c->maxRects, c->expectedSceneVersion);
    return CJGUI_INTERNAL_RENDERER_OK;
}

int32_t cjgui_internal_renderer_text_line_rect_count(uint64_t token,
    uint64_t nodeId, int64_t startByte, int64_t endByte, int32_t maxRects,
    uint64_t expectedSceneVersion) {
    CjguiWindowsLineRectCtx *ctx =
        (CjguiWindowsLineRectCtx *)calloc(1u, sizeof(CjguiWindowsLineRectCtx));
    if (!ctx) return 0;
    ctx->token = token;
    ctx->nodeId = nodeId;
    ctx->startByte = startByte;
    ctx->endByte = endByte;
    ctx->maxRects = maxRects;
    ctx->expectedSceneVersion = expectedSceneVersion;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "line_rects",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_line_rect_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    int32_t result = 0;
    if (st == CJGUI_INTERNAL_RENDERER_OK) result = ctx->result;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return result;
}

typedef struct CjguiWindowsNumberCtx {
    uint64_t token;
    int32_t result;
    int64_t outNumber;
} CjguiWindowsNumberCtx;

static CjguiInternalRendererStatus cjgui_windows_number_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsNumberCtx *c = (CjguiWindowsNumberCtx *)raw;
    c->result = window_number_impl(c->token, &c->outNumber);
    return CJGUI_INTERNAL_RENDERER_OK;
}

int32_t cjgui_internal_renderer_window_number(uint64_t token,
    int64_t *outNumber) {
    if (!outNumber) return 0;
    CjguiWindowsNumberCtx *ctx =
        (CjguiWindowsNumberCtx *)calloc(1u, sizeof(CjguiWindowsNumberCtx));
    if (!ctx) return 0;
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "window_number",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_number_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    int32_t result = 0;
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outNumber = ctx->outNumber;
        result = ctx->result;
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return result;
}

typedef struct CjguiWindowsXferStubCtx {
    uint64_t token;
    uint64_t eventId;
    const char *format;
    uint32_t size;
} CjguiWindowsXferStubCtx;

static CjguiInternalRendererStatus cjgui_windows_xfer_format_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsXferStubCtx *c = (CjguiWindowsXferStubCtx *)raw;
    c->format = data_transfer_event_format_impl(c->token);
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus cjgui_windows_xfer_size_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsXferStubCtx *c = (CjguiWindowsXferStubCtx *)raw;
    c->size = data_transfer_event_binary_size_impl(c->token, c->eventId);
    return CJGUI_INTERNAL_RENDERER_OK;
}

const char *cjgui_internal_renderer_data_transfer_event_format(uint64_t token) {
    CjguiWindowsXferStubCtx *ctx =
        (CjguiWindowsXferStubCtx *)calloc(1u, sizeof(CjguiWindowsXferStubCtx));
    if (!ctx) return "";
    ctx->token = token;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "xfer_format",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_xfer_format_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    const char *result = "";
    if (st == CJGUI_INTERNAL_RENDERER_OK && ctx->format) result = ctx->format;
    free(ctx);
    return result;
}

uint32_t cjgui_internal_renderer_data_transfer_event_binary_size(uint64_t token,
    uint64_t eventId) {
    CjguiWindowsXferStubCtx *ctx =
        (CjguiWindowsXferStubCtx *)calloc(1u, sizeof(CjguiWindowsXferStubCtx));
    if (!ctx) return 0u;
    ctx->token = token;
    ctx->eventId = eventId;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "xfer_size",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_xfer_size_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    uint32_t size = 0u;
    if (st == CJGUI_INTERNAL_RENDERER_OK) size = ctx->size;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return size;
}

typedef struct CjguiWindowsFinishCtx {
    uint64_t token;
    uint64_t requestId;
    uint32_t outcome;
    uint64_t receiptNonce;
} CjguiWindowsFinishCtx;

static CjguiInternalRendererStatus cjgui_windows_finish_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsFinishCtx *c = (CjguiWindowsFinishCtx *)raw;
    return finish_source_install_impl(c->token, c->requestId, c->outcome,
        c->receiptNonce);
}

CjguiInternalRendererStatus cjgui_internal_renderer_finish_source_install(
    uint64_t token, uint64_t requestId, uint32_t outcome,
    uint64_t receiptNonce) {
    CjguiWindowsFinishCtx *ctx =
        (CjguiWindowsFinishCtx *)calloc(1u, sizeof(CjguiWindowsFinishCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->requestId = requestId;
    ctx->outcome = outcome;
    ctx->receiptNonce = receiptNonce;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "finish_install",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_finish_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

typedef struct CjguiWindowsRecoveryCtx {
    uint64_t token;
    uint32_t outReason;
    uint32_t outOutcome;
    uint64_t outInputId;
    uint8_t *outBytes;
    uint32_t capacity;
    uint32_t outLength;
    uint32_t outKind;
    int64_t outModifiers;
    uint32_t outRepeat;
    uint64_t outCompositionId;
    uint32_t outPhase;
    uint32_t outCursor16;
    uint8_t *outExtraBytes;
    uint32_t extraCapacity;
    uint32_t outExtraLength;
    uint32_t hasFullOut;
} CjguiWindowsRecoveryCtx;

static void cjgui_windows_recovery_free(void *raw) {
    CjguiWindowsRecoveryCtx *c = (CjguiWindowsRecoveryCtx *)raw;
    if (!c) return;
    free(c->outBytes);
    free(c->outExtraBytes);
    free(c);
}

static CjguiInternalRendererStatus cjgui_windows_recovery_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsRecoveryCtx *c = (CjguiWindowsRecoveryCtx *)raw;
    CjguiWindowsRendererSession *live = find_session(c->token);
    if (!live) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    c->outReason = CJGUI_WINDOWS_RECOVERY_NONE;
    c->outOutcome = CJGUI_WINDOWS_INSTALL_OUTCOME_NONE;
    c->outInputId = 0u;
    c->outLength = 0u;
    c->outKind = 0u;
    c->outModifiers = 0;
    c->outRepeat = 0u;
    c->outCompositionId = 0u;
    c->outPhase = 0u;
    c->outCursor16 = 0u;
    c->outExtraLength = 0u;
    if (!live->recoveryCount) return CJGUI_INTERNAL_RENDERER_OK;
    uint32_t slot = live->recoveryHead % CJGUI_WINDOWS_RECOVERY_CAPACITY;
    uint32_t length = live->recoverySlots[slot].length;
    uint32_t extraLength = live->recoverySlots[slot].extraLength;
    int hasMain = (live->recoverySlots[slot].bytes && length) ? 1 : 0;
    int hasExtra = (live->recoverySlots[slot].extraBytes && extraLength) ? 1 : 0;
    if (!hasMain && !hasExtra) {
        c->outReason = live->recoverySlots[slot].reason;
        c->outOutcome = live->recoverySlots[slot].outcome;
        c->outInputId = live->recoverySlots[slot].inputId;
        goto pop_record;
    }
    if (!c->outBytes || !c->capacity) {
        c->outReason = live->recoverySlots[slot].reason;
        c->outOutcome = live->recoverySlots[slot].outcome;
        c->outInputId = live->recoverySlots[slot].inputId;
        c->outLength = length;
        c->outExtraLength = extraLength;
        c->outKind = live->recoverySlots[slot].kind;
        c->outModifiers = live->recoverySlots[slot].modifiers;
        c->outRepeat = live->recoverySlots[slot].repeatCount;
        c->outCompositionId = live->recoverySlots[slot].compositionId;
        c->outPhase = live->recoverySlots[slot].phase;
        c->outCursor16 = live->recoverySlots[slot].cursor16;
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    if (hasExtra && !c->hasFullOut) {
        c->outReason = live->recoverySlots[slot].reason;
        c->outOutcome = live->recoverySlots[slot].outcome;
        c->outInputId = live->recoverySlots[slot].inputId;
        c->outLength = length;
        c->outExtraLength = extraLength;
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    {
        uint32_t take = length < c->capacity ? length : c->capacity;
        if (hasMain) memcpy(c->outBytes, live->recoverySlots[slot].bytes, take);
        c->outLength = take;
        if (take < length) {
            memmove(live->recoverySlots[slot].bytes,
                live->recoverySlots[slot].bytes + take, length - take);
            live->recoverySlots[slot].length = length - take;
            live->recoverySlots[slot].bytes[length - take] = '\0';
            c->outReason = live->recoverySlots[slot].reason;
            c->outOutcome = live->recoverySlots[slot].outcome;
            c->outInputId = live->recoverySlots[slot].inputId;
            c->outKind = live->recoverySlots[slot].kind;
            c->outModifiers = live->recoverySlots[slot].modifiers;
            c->outRepeat = live->recoverySlots[slot].repeatCount;
            c->outCompositionId = live->recoverySlots[slot].compositionId;
            c->outPhase = live->recoverySlots[slot].phase;
            c->outCursor16 = live->recoverySlots[slot].cursor16;
            c->outExtraLength = extraLength;
            return CJGUI_INTERNAL_RENDERER_OK;
        }
    }
    if (hasExtra) {
        uint32_t extraTake = extraLength < c->extraCapacity ? extraLength : c->extraCapacity;
        if (c->outExtraBytes && extraTake) {
            memcpy(c->outExtraBytes, live->recoverySlots[slot].extraBytes, extraTake);
        }
        c->outExtraLength = extraTake;
        if (extraTake < extraLength) {
            memmove(live->recoverySlots[slot].extraBytes,
                live->recoverySlots[slot].extraBytes + extraTake, extraLength - extraTake);
            live->recoverySlots[slot].extraLength = extraLength - extraTake;
            live->recoverySlots[slot].extraBytes[extraLength - extraTake] = '\0';
            free(live->recoverySlots[slot].bytes);
            live->recoverySlots[slot].bytes = NULL;
            live->recoverySlots[slot].length = 0u;
            c->outReason = live->recoverySlots[slot].reason;
            c->outOutcome = live->recoverySlots[slot].outcome;
            c->outInputId = live->recoverySlots[slot].inputId;
            c->outKind = live->recoverySlots[slot].kind;
            c->outModifiers = live->recoverySlots[slot].modifiers;
            c->outRepeat = live->recoverySlots[slot].repeatCount;
            c->outCompositionId = live->recoverySlots[slot].compositionId;
            c->outPhase = live->recoverySlots[slot].phase;
            c->outCursor16 = live->recoverySlots[slot].cursor16;
            c->outLength = length;
            return CJGUI_INTERNAL_RENDERER_OK;
        }
    }
    c->outReason = live->recoverySlots[slot].reason;
    c->outOutcome = live->recoverySlots[slot].outcome;
    c->outInputId = live->recoverySlots[slot].inputId;
    c->outKind = live->recoverySlots[slot].kind;
    c->outModifiers = live->recoverySlots[slot].modifiers;
    c->outRepeat = live->recoverySlots[slot].repeatCount;
    c->outCompositionId = live->recoverySlots[slot].compositionId;
    c->outPhase = live->recoverySlots[slot].phase;
    c->outCursor16 = live->recoverySlots[slot].cursor16;
pop_record:
    free(live->recoverySlots[slot].bytes);
    free(live->recoverySlots[slot].extraBytes);
    memset(&live->recoverySlots[slot], 0, sizeof(live->recoverySlots[slot]));
    live->recoveryHead = (live->recoveryHead + 1u) %
        CJGUI_WINDOWS_RECOVERY_CAPACITY;
    live->recoveryCount -= 1u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_install_recovery(
    uint64_t token, uint32_t *outReason, uint32_t *outOutcome,
    uint64_t *outInputId, uint8_t *outBytes, uint32_t capacity,
    uint32_t *outLength, uint32_t *outKind, int64_t *outModifiers,
    uint32_t *outRepeat, uint64_t *outCompositionId, uint32_t *outPhase,
    uint32_t *outCursor16, uint8_t *outExtraBytes, uint32_t extraCapacity,
    uint32_t *outExtraLength) {
    if (!outReason || !outOutcome || !outInputId || !outLength)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsRecoveryCtx *ctx =
        (CjguiWindowsRecoveryCtx *)calloc(1u, sizeof(CjguiWindowsRecoveryCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->outBytes = (uint8_t *)calloc(capacity ? capacity : 1u, 1u);
    ctx->extraCapacity = extraCapacity;
    ctx->hasFullOut = (outKind && outModifiers && outRepeat && outCompositionId &&
        outPhase && outCursor16 && outExtraLength) ? 1u : 0u;
    if (ctx->hasFullOut) {
        ctx->outExtraBytes = (uint8_t *)calloc(extraCapacity ? extraCapacity : 1u, 1u);
        if (!ctx->outExtraBytes) {
            free(ctx->outBytes);
            free(ctx);
            return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        }
    }
    ctx->capacity = capacity;
    if (!ctx->outBytes) {
        free(ctx);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "install_rcv",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_recovery_proc, ctx,
        cjgui_windows_recovery_free, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outReason = ctx->outReason;
        *outOutcome = ctx->outOutcome;
        *outInputId = ctx->outInputId;
        *outLength = ctx->outLength;
        if (outKind) *outKind = ctx->outKind;
        if (outModifiers) *outModifiers = ctx->outModifiers;
        if (outRepeat) *outRepeat = ctx->outRepeat;
        if (outCompositionId) *outCompositionId = ctx->outCompositionId;
        if (outPhase) *outPhase = ctx->outPhase;
        if (outCursor16) *outCursor16 = ctx->outCursor16;
        if (outExtraLength) *outExtraLength = ctx->outExtraLength;
        if (outBytes && capacity && ctx->outLength)
            memcpy(outBytes, ctx->outBytes,
                ctx->outLength < capacity ? ctx->outLength : capacity);
        if (outExtraBytes && extraCapacity && ctx->outExtraLength)
            memcpy(outExtraBytes, ctx->outExtraBytes,
                ctx->outExtraLength < extraCapacity ? ctx->outExtraLength : extraCapacity);
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        cjgui_windows_recovery_free(ctx);
    return st;
}

/* v1 metadata: record, reason, outcome, input, binding, request, kind,
   modifiers, repeat, composition, phase, cursor16, main length, extra length,
   completed IME flags, session generation. ACK is idempotent after completion. */
typedef struct CjguiWindowsRecoveryV1Ctx {
    uint64_t meta[16];
    uint64_t ackId;
    uint8_t *bytes, *extra;
    uint32_t capacity, extraCapacity;
} CjguiWindowsRecoveryV1Ctx;
static void recovery_v1_free(void *raw) {
    CjguiWindowsRecoveryV1Ctx *c = raw;
    free(c->bytes); free(c->extra); free(c);
}
static CjguiInternalRendererStatus recovery_v1_proc(CjguiWindowsRendererSession *s, void *raw) {
    CjguiWindowsRecoveryV1Ctx *c = raw;
    if (!s->recoveryCount) return CJGUI_INTERNAL_RENDERER_OK;
    uint32_t i = s->recoveryHead;
    if (c->ackId) {
        if (c->ackId < s->recoverySlots[i].recordId) return CJGUI_INTERNAL_RENDERER_OK;
        if (c->ackId != s->recoverySlots[i].recordId) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
        free(s->recoverySlots[i].bytes); free(s->recoverySlots[i].extraBytes);
        memset(&s->recoverySlots[i], 0, sizeof(s->recoverySlots[i]));
        s->recoveryHead = (i + 1u) % CJGUI_WINDOWS_RECOVERY_CAPACITY;
        s->recoveryCount -= 1u;
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    if (s->recoverySlots[i].length > c->capacity ||
        s->recoverySlots[i].extraLength > c->extraCapacity)
        return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    c->meta[0] = s->recoverySlots[i].recordId;
    c->meta[1] = s->recoverySlots[i].reason; c->meta[2] = s->recoverySlots[i].outcome;
    c->meta[3] = s->recoverySlots[i].inputId; c->meta[4] = s->recoverySlots[i].bindingEpoch;
    c->meta[5] = s->recoverySlots[i].requestId; c->meta[6] = s->recoverySlots[i].kind;
    c->meta[7] = (uint64_t)s->recoverySlots[i].modifiers;
    c->meta[8] = s->recoverySlots[i].repeatCount; c->meta[9] = s->recoverySlots[i].compositionId;
    c->meta[10] = s->recoverySlots[i].phase; c->meta[11] = s->recoverySlots[i].cursor16;
    c->meta[12] = s->recoverySlots[i].length; c->meta[13] = s->recoverySlots[i].extraLength;
    c->meta[14] = s->recoverySlots[i].handledParts; c->meta[15] = s->sessionGeneration;
    if (c->meta[12]) memcpy(c->bytes, s->recoverySlots[i].bytes, (size_t)c->meta[12]);
    if (c->meta[13]) memcpy(c->extra, s->recoverySlots[i].extraBytes, (size_t)c->meta[13]);
    return CJGUI_INTERNAL_RENDERER_OK;
}
CjguiInternalRendererStatus cjgui_internal_renderer_peek_install_recovery_v1(
    uint64_t token, uint64_t *meta, uint8_t *bytes, uint32_t capacity,
    uint8_t *extra, uint32_t extraCapacity) {
    if (!meta || !bytes || !extra || capacity > 262144u || extraCapacity > 65536u)
        return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    CjguiWindowsRecoveryV1Ctx *c = calloc(1u, sizeof(*c));
    if (!c) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    c->bytes = calloc(capacity ? capacity : 1u, 1u);
    c->extra = calloc(extraCapacity ? extraCapacity : 1u, 1u);
    c->capacity = capacity; c->extraCapacity = extraCapacity;
    if (!c->bytes || !c->extra) { recovery_v1_free(c); return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR; }
    uint64_t command = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "recovery_peek_v1",
        CJGUI_WINDOWS_CMD_GENERIC, recovery_v1_proc, c, recovery_v1_free,
        CJGUI_WINDOWS_CMD_TIMEOUT_MS, &command);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        memcpy(meta, c->meta, sizeof(c->meta));
        if (c->meta[12]) memcpy(bytes, c->bytes, (size_t)c->meta[12]);
        if (c->meta[13]) memcpy(extra, c->extra, (size_t)c->meta[13]);
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT && st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        recovery_v1_free(c);
    return st;
}
CjguiInternalRendererStatus cjgui_internal_renderer_ack_install_recovery_v1(uint64_t token, uint64_t recordId) {
    if (!recordId) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    CjguiWindowsRecoveryV1Ctx *c = calloc(1u, sizeof(*c));
    if (!c) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    c->ackId = recordId;
    uint64_t command = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "recovery_ack_v1",
        CJGUI_WINDOWS_CMD_GENERIC, recovery_v1_proc, c, recovery_v1_free,
        CJGUI_WINDOWS_CMD_TIMEOUT_MS, &command);
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT && st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT)
        recovery_v1_free(c);
    return st;
}

typedef struct CjguiWindowsReceiptCtx {
    uint64_t token;
    uint64_t requestId;
    uint64_t outNonce;
} CjguiWindowsReceiptCtx;

static CjguiInternalRendererStatus cjgui_windows_receipt_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsReceiptCtx *c = (CjguiWindowsReceiptCtx *)raw;
    CjguiWindowsRendererSession *live = find_session(c->token);
    if (!live) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    c->outNonce = 0u;
    if (live->sourceInstallPending &&
        live->sourceInstallRequestId == c->requestId &&
        live->sourceInstallProvisional) {
        c->outNonce = live->sourceInstallProvisionalNonce;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

typedef struct CjguiWindowsGateStateCtx {
    uint64_t token;
    uint64_t requestId;
    uint8_t outPending;
    uint8_t outProvisional;
} CjguiWindowsGateStateCtx;

static CjguiInternalRendererStatus cjgui_windows_gate_state_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsGateStateCtx *c = (CjguiWindowsGateStateCtx *)raw;
    CjguiWindowsRendererSession *live = find_session(c->token);
    if (!live) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    c->outPending = (live->sourceInstallPending &&
        live->sourceInstallRequestId == c->requestId) ? 1u : 0u;
    c->outProvisional = (c->outPending && live->sourceInstallProvisional) ? 1u : 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_source_install_gate_state(
    uint64_t token, uint64_t requestId, uint8_t *outPending,
    uint8_t *outProvisional) {
    if (!outPending || !outProvisional)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsGateStateCtx *ctx =
        (CjguiWindowsGateStateCtx *)calloc(1u, sizeof(CjguiWindowsGateStateCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->requestId = requestId;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "install_gate",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_gate_state_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) {
        *outPending = ctx->outPending;
        *outProvisional = ctx->outProvisional;
    }
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

CjguiInternalRendererStatus cjgui_internal_renderer_source_install_receipt(
    uint64_t token, uint64_t requestId, uint64_t *outNonce) {    if (!outNonce) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsReceiptCtx *ctx =
        (CjguiWindowsReceiptCtx *)calloc(1u, sizeof(CjguiWindowsReceiptCtx));
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx->token = token;
    ctx->requestId = requestId;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "install_rcpt",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_receipt_proc, ctx,
        cjgui_windows_free_ctx, CJGUI_WINDOWS_CMD_TIMEOUT_MS, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_OK) *outNonce = ctx->outNonce;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT &&
        st != CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) free(ctx);
    return st;
}

uint64_t cjgui_internal_renderer_create(const CjguiInternalRendererConfig *config,
    CjguiInternalRendererStatus *outStatus) {
    if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (!config) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN;
    CjguiWindowsRendererSession *s = NULL;
    ensure_session_lock();
    EnterCriticalSection(&g_sessionLock);
    for (uint32_t i = 0; i < CJGUI_WINDOWS_SESSION_CAPACITY; ++i) {
        if (!g_sessions[i].occupied) { s = &g_sessions[i]; break; }
    }
    if (s) {
        memset(s, 0, sizeof(*s));
        s->occupied = 1;
        const char *trace=getenv("CJGUI_WINDOWS_TRACE_TIMING");
        s->traceEnabled=trace && !strcmp(trace,"1");
    }
    LeaveCriticalSection(&g_sessionLock);
    if (!s) {
        if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_SESSION_TABLE_FULL;
        return CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN;
    }
    InitializeCriticalSection(&s->rawLock);
    InitializeCriticalSection(&s->cmdLock);
    s->rawWakeEvent = CreateEventW(NULL, FALSE, FALSE, NULL);
    s->pumpStopEvent = CreateEventW(NULL, TRUE, FALSE, NULL);
    s->pumpReadyEvent = CreateEventW(NULL, TRUE, FALSE, NULL);
    s->cmdWakeEvent = CreateEventW(NULL, FALSE, FALSE, NULL);
    s->cmdHead = 0u;
    s->cmdTail = 0u;
    s->retiring = 0;
    if (!s->rawWakeEvent || !s->pumpStopEvent || !s->pumpReadyEvent || !s->cmdWakeEvent) {
        if (s->rawWakeEvent) CloseHandle(s->rawWakeEvent);
        if (s->pumpStopEvent) CloseHandle(s->pumpStopEvent);
        if (s->pumpReadyEvent) CloseHandle(s->pumpReadyEvent);
        if (s->cmdWakeEvent) CloseHandle(s->cmdWakeEvent);
        DeleteCriticalSection(&s->cmdLock);
        DeleteCriticalSection(&s->rawLock);
        memset(s, 0, sizeof(*s));
        if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        return CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN;
    }
    s->token = (uint64_t)InterlockedIncrement64(&g_nextSessionToken);
    if (s->token == 0) s->token = (uint64_t)InterlockedIncrement64(&g_nextSessionToken);
    s->sessionGeneration = next_positive_counter(&g_nextSessionGeneration);
    s->coordinateEpoch = next_positive_counter(&g_nextCoordinateEpoch);
    s->focusedNodeId = UINT64_MAX;
    s->focusedResourceId = -1;
    s->ownedTextSessionResourceId = -1;
    s->clearRed = config->clearColorRed;
    s->clearGreen = config->clearColorGreen;
    s->clearBlue = config->clearColorBlue;
    s->clearAlpha = config->clearColorAlpha;
    s->caretNodeId = -1;
    s->pendingCreateWidth = config->windowWidth ? config->windowWidth : 960;
    s->pendingCreateHeight = config->windowHeight ? config->windowHeight : 640;
    s->pumpThreadStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    s->pumpThread = CreateThread(NULL, 0, pump_thread_main, s, 0, &s->pumpThreadId);
    if (!s->pumpThread) {
        CloseHandle(s->rawWakeEvent);
        CloseHandle(s->pumpStopEvent);
        CloseHandle(s->pumpReadyEvent);
        CloseHandle(s->cmdWakeEvent);
        DeleteCriticalSection(&s->cmdLock);
        DeleteCriticalSection(&s->rawLock);
        memset(s, 0, sizeof(*s));
        if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_WINDOW_CREATE_FAILED;
        return CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN;
    }
    s->pumpThreadRunning = 1;
    DWORD ready = WaitForSingleObject(s->pumpReadyEvent, 30000u);
    if (ready != WAIT_OBJECT_0 || s->pumpThreadStatus != CJGUI_INTERNAL_RENDERER_OK) {
        DWORD code = (ready == WAIT_OBJECT_0) ? (DWORD)s->pumpThreadStatus
            : (DWORD)CJGUI_INTERNAL_RENDERER_WINDOW_CREATE_FAILED;
        SetEvent(s->pumpStopEvent);
        WaitForSingleObject(s->pumpThread, 5000u);
        CloseHandle(s->pumpThread);
        CloseHandle(s->rawWakeEvent);
        CloseHandle(s->pumpStopEvent);
        CloseHandle(s->pumpReadyEvent);
        CloseHandle(s->cmdWakeEvent);
        release_graphics(s);
        DeleteCriticalSection(&s->cmdLock);
        DeleteCriticalSection(&s->rawLock);
        memset(s, 0, sizeof(*s));
        if (outStatus) *outStatus = (CjguiInternalRendererStatus)code;
        return CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN;
    }
    s->ownerThreadId = GetCurrentThreadId();
    if (s->pumpThreadId != 0u && s->pumpThreadId != s->ownerThreadId) {
        if (AttachThreadInput(s->pumpThreadId, s->ownerThreadId, TRUE))
            s->inputAttached = 1;
    }
    if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_OK;
    return s->token;
}

static CjguiInternalRendererStatus window_activation_state_impl(uint64_t token,
    int32_t *outKey, int32_t *outMain, int32_t *outAppActive) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s || !s->hwnd) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    HWND foreground = GetForegroundWindow();
    HWND active = GetActiveWindow();
    if (outKey) *outKey = foreground == s->hwnd;
    if (outMain) *outMain = active == s->hwnd;
    if (outAppActive) {
        DWORD foregroundProcess = 0;
        if (foreground) GetWindowThreadProcessId(foreground, &foregroundProcess);
        *outAppActive = foregroundProcess == GetCurrentProcessId();
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus activate_window_impl(uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s || !s->hwnd) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (IsIconic(s->hwnd)) ShowWindow(s->hwnd, SW_RESTORE);
    BringWindowToTop(s->hwnd);
    return SetForegroundWindow(s->hwnd) ? CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

static CjguiInternalRendererStatus window_frame_impl(uint64_t token, int64_t *outX,
    int64_t *outY, int64_t *outWidth, int64_t *outHeight) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s || !s->hwnd) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    RECT rect;
    if (!GetWindowRect(s->hwnd, &rect)) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (outX) *outX = rect.left;
    if (outY) *outY = rect.top;
    if (outWidth) *outWidth = rect.right - rect.left;
    if (outHeight) *outHeight = rect.bottom - rect.top;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static int32_t window_number_impl(uint64_t token, int64_t *outNumber) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s || !s->hwnd) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (outNumber) *outNumber = (int64_t)(intptr_t)s->hwnd;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus set_window_title_impl(uint64_t token, const char *title) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s || !s->hwnd) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!title) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    int byteCount = (int)strnlen(title, 16385);
    if (byteCount > 16384) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    int chars = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, title, byteCount, NULL, 0);
    if (chars <= 0 || chars > 4096) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    wchar_t *wide = (wchar_t *)calloc((size_t)chars + 1, sizeof(wchar_t));
    if (!wide) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    int converted = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, title, byteCount, wide, chars);
    BOOL ok = converted == chars && SetWindowTextW(s->hwnd, wide);
    free(wide);
    return ok ? CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

static int32_t set_composable_range_edit_delta_impl(uint64_t token, int32_t enabled) {
    return find_session(token) ? (enabled == 0 || enabled == 1
        ? CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR)
        : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
}

static int32_t cancel_composition_impl(uint64_t token,
    int32_t *outHadMarked, int32_t *outCancelReturned) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s || !s->hwnd) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (outHadMarked) *outHadMarked = s->compositionActive ? 1 : 0;
    BOOL cancelled = FALSE;
    HIMC context = ImmGetContext(s->hwnd);
    if (context) {
        cancelled = ImmNotifyIME(context, NI_COMPOSITIONSTR, CPS_CANCEL, 0);
        ImmReleaseContext(s->hwnd, context);
    }
    if (cancelled) s->compositionActive = 0;
    if (outCancelReturned) *outCancelReturned = cancelled ? 1 : 0;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static int32_t declare_input_caret_impl(uint64_t token, int64_t nodeId,
    double x, double y, double width, double height) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s || !s->hwnd) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    s->caretNodeId = nodeId;
    s->caretX = x; s->caretY = y; s->caretWidth = width; s->caretHeight = height;
    if (nodeId < 0) return CJGUI_INTERNAL_RENDERER_OK;
    HIMC context = ImmGetContext(s->hwnd);
    if (context) {
        double scale = (double)(s->dpi ? s->dpi : 96) / 96.0;
        COMPOSITIONFORM composition;
        memset(&composition, 0, sizeof(composition));
        composition.dwStyle = CFS_POINT;
        composition.ptCurrentPos.x = (LONG)(x * scale);
        composition.ptCurrentPos.y = (LONG)(y * scale + height * scale);
        (void)ImmSetCompositionWindow(context, &composition);
        CANDIDATEFORM candidate;
        memset(&candidate, 0, sizeof(candidate));
        candidate.dwIndex = 0;
        candidate.dwStyle = CFS_CANDIDATEPOS;
        candidate.ptCurrentPos = composition.ptCurrentPos;
        (void)ImmSetCandidateWindow(context, &candidate);
        ImmReleaseContext(s->hwnd, context);
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

static uint8_t source_install_pending_scalar_impl(uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    return s ? (s->sourceInstallPending ? 1 : 0) : 0;
}

static uint64_t source_install_gated_inputs_impl(uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    return s ? s->sourceInstallGatedInputs : 0u;
}

static int32_t probe_image_texture_impl(uint64_t token, uint64_t nodeId,
    int32_t *outFound, int32_t *outHasTexture, int32_t *outCacheKeyLength, int32_t *outFailed) {
    (void)nodeId;
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (outFound) *outFound = 0;
    if (outHasTexture) *outHasTexture = 0;
    if (outCacheKeyLength) *outCacheKeyLength = 0;
    if (outFailed) *outFailed = 0;
    return CJGUI_INTERNAL_RENDERER_OK;
}

uint64_t cjgui_internal_renderer_owner_clock_ns(void) {
    LARGE_INTEGER frequency, counter;
    if (!QueryPerformanceFrequency(&frequency) || !QueryPerformanceCounter(&counter) || frequency.QuadPart <= 0)
        return 0;
    uint64_t f = (uint64_t)frequency.QuadPart, c = (uint64_t)counter.QuadPart;
    return (c / f) * 1000000000ull + ((c % f) * 1000000000ull) / f;
}

uint64_t cjgui_internal_renderer_owner_trace_ns(void) {
    return windows_owner_trace_enabled() ? cjgui_internal_renderer_owner_clock_ns() : 0u;
}

uint64_t cjgui_internal_renderer_owner_trace_managed_record(uint32_t kind,uint64_t session,
    uint64_t turn,uint64_t request,uint64_t dispatch,uint64_t generation,
    uint32_t phase,uint64_t span,uint64_t managedId,uint8_t withWatch) {
    (void)managedId;(void)withWatch;
    if (!windows_owner_trace_enabled()) return 0u;
    CjguiWindowsOwnerTraceRow row={cjgui_internal_renderer_owner_clock_ns(),session,turn,request,
        dispatch,generation,span,kind,phase,GetCurrentThreadId()};
    AcquireSRWLockExclusive(&g_windowsOwnerTraceLock);
    uint64_t index=g_windowsOwnerTraceCount++;
    if (kind==1u || kind==3u || kind==19u) row.span=index+1u;
    g_windowsOwnerTrace[index%CJGUI_WINDOWS_OWNER_TRACE_CAPACITY]=row;
    ReleaseSRWLockExclusive(&g_windowsOwnerTraceLock);
    return row.span;
}

static void windows_owner_trace_dump(FILE *out) {
    CjguiWindowsOwnerTraceRow *snapshot=malloc(sizeof(g_windowsOwnerTrace));
    if (!snapshot) {fprintf(out,"OWNER_TRACE snapshot_allocation_failed\n");return;}
    AcquireSRWLockShared(&g_windowsOwnerTraceLock);
    uint64_t total=g_windowsOwnerTraceCount;
    memcpy(snapshot,g_windowsOwnerTrace,sizeof(g_windowsOwnerTrace));
    ReleaseSRWLockShared(&g_windowsOwnerTraceLock);
    uint64_t first=total>CJGUI_WINDOWS_OWNER_TRACE_CAPACITY?total-CJGUI_WINDOWS_OWNER_TRACE_CAPACITY:0u;
    fprintf(out,"OWNER_TRACE enabled=%d total=%llu retained=%llu dropped=%llu\n",
        g_windowsOwnerTraceEnabled,(unsigned long long)total,(unsigned long long)(total-first),(unsigned long long)first);
    for(uint64_t i=first;i<total;++i) {
        CjguiWindowsOwnerTraceRow *r=&snapshot[i%CJGUI_WINDOWS_OWNER_TRACE_CAPACITY];
        fprintf(out,"OWNER_TRACE_ROW index=%llu t_ns=%llu kind=%u phase=%u session=%llu turn=%llu request=%llu dispatch=%llu generation=%llu span=%llu tid=%lu\n",
            (unsigned long long)i,(unsigned long long)r->clockNs,r->kind,r->phase,
            (unsigned long long)r->session,(unsigned long long)r->turn,(unsigned long long)r->request,
            (unsigned long long)r->dispatch,(unsigned long long)r->generation,(unsigned long long)r->span,(unsigned long)r->tid);
    }
    free(snapshot);
}

uint64_t cjgui_internal_renderer_owner_thread_cpu_ns(void) {
    FILETIME creation, exitTime, kernel, user;
    if (!GetThreadTimes(GetCurrentThread(), &creation, &exitTime, &kernel, &user)) return 0;
    ULARGE_INTEGER k, u;
    k.LowPart = kernel.dwLowDateTime; k.HighPart = kernel.dwHighDateTime;
    u.LowPart = user.dwLowDateTime; u.HighPart = user.dwHighDateTime;
    return (k.QuadPart + u.QuadPart) * 100ull;
}

static CjguiInternalRendererStatus diagnostic_workload_impl(uint64_t token,
    CjguiInternalRendererDiagnosticWorkload *outWorkload) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s || !outWorkload) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    memset(outWorkload, 0, sizeof(*outWorkload));
    outWorkload->sceneVersion = s->sceneVersion;
    outWorkload->frameIndex = s->frameIndex;
    outWorkload->textLayoutPreparationCount = s->textLayoutPreparationCount;
    outWorkload->imageDecodeStartCount = s->imageDecodeStartCount;
    outWorkload->textRasterCount = s->textRasterCount;
    outWorkload->textRasterBytes = s->textRasterBytes;
    outWorkload->textRasterMicros = s->textRasterMicros;
    outWorkload->textUploadCount = s->textUploadCount;
    outWorkload->textUploadBytes = s->textUploadBytes;
    outWorkload->textUploadMicros = s->textUploadMicros;
    outWorkload->textTextureLiveBytes = s->textTextureBytesInUse;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus set_diagnostic_timing_impl(uint64_t token, uint32_t enabled) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    s->diagnosticTimingEnabled = enabled ? 1u : 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus set_diagnostic_overlay_impl(uint64_t token, uint32_t flags,
    uint64_t selectedNodeId, uint8_t hasSelection) {
    (void)selectedNodeId; (void)hasSelection;
    if (!find_session(token)) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    return flags == 0 ? CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

static CjguiInternalRendererStatus windows_text_line_rects(
    CjguiWindowsRendererSession *s, uint64_t nodeId, int64_t startByte, int64_t endByte,
    int32_t maxRects, uint64_t expectedSceneVersion, double *outRects, uint32_t *outCount) {
    if (!outCount) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outCount = 0u;
    if (startByte < 0 || endByte < startByte || maxRects <= 0 || maxRects > 16384)
        return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    CjguiWindowsSceneNode *node = NULL;
    CjguiInternalRendererStatus status = windows_accepted_text_node(
        s, nodeId, expectedSceneVersion, &node);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    const char *text = windows_text_layout_value(node);
    uint64_t byteLength = 0u; uint32_t totalUnits = 0u;
    status = windows_text_layout_units(text, &byteLength, &totalUnits);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    uint32_t startUnits = 0u, endUnits = 0u;
    status = windows_validate_text_grapheme_boundary(text, byteLength,
        (uint64_t)startByte, &startUnits);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = windows_validate_text_grapheme_boundary(text, byteLength,
        (uint64_t)endByte, &endUnits);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    if (endUnits < startUnits || endUnits > totalUnits)
        return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    if (startUnits == endUnits) return CJGUI_INTERNAL_RENDERER_OK;

    UINT32 required = 0u;
    HRESULT hr = IDWriteTextLayout_HitTestTextRange(node->textLayout,
        startUnits, endUnits - startUnits, 0.0f, 0.0f, NULL, 0u, &required);
    if (required > 16384u || (FAILED(hr) && hr != E_NOT_SUFFICIENT_BUFFER)) {
        s->lastGraphicsFailure = hr;
        return required > 16384u ? CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED
            : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    if (!required) return CJGUI_INTERNAL_RENDERER_OK;
    uint64_t scratchBytes = (uint64_t)required * sizeof(DWRITE_HIT_TEST_METRICS);
    if (!text_budget_reserve_scratch(s, scratchBytes))
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    DWRITE_HIT_TEST_METRICS *metrics = (DWRITE_HIT_TEST_METRICS *)calloc(required, sizeof(*metrics));
    if (!metrics) {
        text_budget_release_scratch(s, scratchBytes);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    UINT32 actual = 0u;
    hr = IDWriteTextLayout_HitTestTextRange(node->textLayout, startUnits,
        endUnits - startUnits, 0.0f, 0.0f, metrics, required, &actual);
    if (FAILED(hr) || actual > required) {
        free(metrics);
        text_budget_release_scratch(s, scratchBytes);
        s->lastGraphicsFailure = hr;
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    double originX = (double)node->node.x + node->geometry.translateX + node->textLogicalOffsetX;
    double originY = (double)node->node.y + node->geometry.translateY - node->multilineScrollY;
    uint32_t emitted = 0u;
    for (UINT32 i = 0u; i < actual && emitted < (uint32_t)maxRects; ++i) {
        if (!(metrics[i].width > 0.0f) || !(metrics[i].height > 0.0f)) continue;
        if (outRects) {
            outRects[emitted * 4u + 0u] = originX + metrics[i].left;
            outRects[emitted * 4u + 1u] = originY + metrics[i].top;
            outRects[emitted * 4u + 2u] = metrics[i].width;
            outRects[emitted * 4u + 3u] = metrics[i].height;
        }
        ++emitted;
    }
    free(metrics);
    text_budget_release_scratch(s, scratchBytes);
    *outCount = emitted;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus hit_test_composable_text_impl(uint64_t token, uint64_t nodeId,
    double x, double y, uint64_t expectedSceneVersion, uint32_t *outByteOffset,
    uint32_t *outAffinity) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outByteOffset || !outAffinity) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint64_t meta[8] = {0}; double rect[4] = {0};
    CjguiInternalRendererStatus status = cjgui_internal_renderer_text_position_v1(token,
        nodeId, expectedSceneVersion, 1u, 0, 2u, 0u, 0u, 0u, x, y, meta, rect);
    if (status == CJGUI_INTERNAL_RENDERER_OK) {
        *outByteOffset = (uint32_t)meta[2];
        *outAffinity = (uint32_t)meta[3];
    }
    return status;
}

static CjguiInternalRendererStatus text_stop_resolve_impl(uint64_t token, uint64_t nodeId,
    int64_t displayByte, uint32_t branchIn, uint64_t expectedSceneVersion,
    uint32_t *outByte, uint32_t *outBranch, uint32_t *outLineFirstChar,
    uint32_t *outLineLength, double *outX) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outByte || !outBranch || !outLineFirstChar || !outLineLength || !outX || branchIn > 2u)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint64_t meta[8] = {0}; double rect[4] = {0};
    CjguiInternalRendererStatus status = cjgui_internal_renderer_text_position_v1(token,
        nodeId, expectedSceneVersion, 0u, displayByte, branchIn, 0u, 0u,
        0u, 0.0, 0.0, meta, rect);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiWindowsSceneNode *node = NULL;
    status = windows_accepted_text_node(s, nodeId, expectedSceneVersion, &node);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    const char *text = windows_text_layout_value(node);
    uint64_t bytes = 0u; uint32_t totalUnits = 0u, units = 0u;
    status = windows_text_layout_units(text, &bytes, &totalUnits);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = windows_validate_text_grapheme_boundary(text, bytes, (uint64_t)displayByte, &units);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    DWRITE_HIT_TEST_METRICS hit; memset(&hit, 0, sizeof(hit)); FLOAT hx = 0.0f, hy = 0.0f;
    status = windows_text_position_units(s, node, units, totalUnits, bytes,
        (uint32_t)meta[3], &hit, &hx, &hy);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    DWRITE_LINE_METRICS *lines = NULL; UINT32 lineCount = 0u; uint64_t scratch = 0u;
    status = windows_get_line_metrics(s, node->textLayout, &lines, &lineCount, &scratch);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    UINT32 lineStart = 0u, lineLength = 0u;
    (void)windows_line_for_top(lines, lineCount, hit.top, &lineStart, &lineLength);
    windows_release_line_metrics(s, &lines, scratch);
    *outByte = (uint32_t)meta[2]; *outBranch = (uint32_t)meta[3];
    *outLineFirstChar = lineStart; *outLineLength = lineLength; *outX = rect[0];
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus text_stop_neighbor_impl(uint64_t token, uint64_t nodeId,
    int64_t displayByte, uint32_t branchIn, uint32_t left, uint64_t expectedSceneVersion,
    uint32_t *outByte, uint32_t *outBranch) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outByte || !outBranch || branchIn > 2u || left > 1u)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint64_t meta[8] = {0}; double rect[4] = {0};
    CjguiInternalRendererStatus status = cjgui_internal_renderer_text_position_v1(token,
        nodeId, expectedSceneVersion, 2u, displayByte, branchIn, 0u, 0u,
        left ? 0u : 1u, 0.0, 0.0, meta, rect);
    if (status == CJGUI_INTERNAL_RENDERER_OK) {
        *outByte = (uint32_t)meta[2]; *outBranch = (uint32_t)meta[3];
    }
    return status;
}

static int32_t text_line_rect_count_impl(uint64_t token, uint64_t nodeId,
    int64_t startByte, int64_t endByte, int32_t maxRects, uint64_t expectedSceneVersion) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return -(int32_t)owner;
    uint32_t count = 0u;
    CjguiInternalRendererStatus status = windows_text_line_rects(s, nodeId, startByte,
        endByte, maxRects, expectedSceneVersion, NULL, &count);
    return status == CJGUI_INTERNAL_RENDERER_OK ? (int32_t)count : -(int32_t)status;
}

double cjgui_internal_renderer_text_line_rect_value(uint64_t token, uint64_t nodeId,
    int64_t startByte, int64_t endByte, int32_t maxRects, int32_t index,
    int32_t component, uint64_t expectedSceneVersion) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (require_session(s) != CJGUI_INTERNAL_RENDERER_OK || index < 0 ||
        component < 0 || component > 3 || maxRects <= 0 || index >= maxRects) return 0.0;
    double *rects = (double *)calloc((size_t)maxRects * 4u, sizeof(double));
    if (!rects) return 0.0;
    uint32_t count = 0u;
    CjguiInternalRendererStatus status = windows_text_line_rects(s, nodeId, startByte,
        endByte, maxRects, expectedSceneVersion, rects, &count);
    double result = status == CJGUI_INTERNAL_RENDERER_OK && (uint32_t)index < count
        ? rects[(size_t)index * 4u + (uint32_t)component] : 0.0;
    free(rects);
    return result;
}

static CjguiInternalRendererStatus diagnostic_node_geometry_impl(uint64_t token, uint32_t nodeIndex,
    CjguiInternalRendererDiagnosticNodeGeometry *outGeometry) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outGeometry) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    memset(outGeometry, 0, sizeof(*outGeometry));
    outGeometry->sceneVersion = s->sceneVersion;
    outGeometry->frameIndex = s->frameIndex;
    if (!s->acceptedScene.configured || nodeIndex >= s->acceptedScene.count ||
        !s->acceptedScene.nodes[nodeIndex].hasNode)
        return CJGUI_INTERNAL_RENDERER_SCENE_NOT_STAGED;
    CjguiInternalRendererComposableNode *node = &s->acceptedScene.nodes[nodeIndex].node;
    CjguiInternalRendererComposableGeometry *geometry = &s->acceptedScene.nodes[nodeIndex].geometry;
    outGeometry->outputX = (double)node->x + geometry->translateX;
    outGeometry->outputY = (double)node->y + geometry->translateY;
    outGeometry->outputWidth = (double)node->width;
    outGeometry->outputHeight = (double)node->height;
    outGeometry->flags = 1u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus finish_destroy_admission(uint64_t token, CjguiInternalRendererStatus st) {
    EnterCriticalSection(&g_sessionLock);
    CjguiWindowsRendererSession *s = find_session(token);
    if (s) s->presentClosing = 0u;
    LeaveCriticalSection(&g_sessionLock);
    return st;
}

CjguiInternalRendererStatus cjgui_internal_renderer_destroy(uint64_t token) {
    CjguiWindowsRendererSession *route = find_session(token);
    if (!route) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    DWORD caller = GetCurrentThreadId();
    if (route->pumpThreadId != 0u && caller == route->pumpThreadId) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    ensure_session_lock();
    EnterCriticalSection(&g_sessionLock);
    route = find_session(token);
    if (!route || route->presentClosing) {
        LeaveCriticalSection(&g_sessionLock);
        return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    if (route->presentReceipt.ticketId) {
        ++route->presentTicketDestroyRefusedCount;
        LeaveCriticalSection(&g_sessionLock);
        return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
    }
    route->presentClosing = 1u;
    LeaveCriticalSection(&g_sessionLock);
    if (!route->pumpThreadRunning || route->pumpThreadId == 0u) {
        if (route->retiring) return finish_destroy_admission(token, CJGUI_INTERNAL_RENDERER_INVALID_SESSION);
        /* A stopped/unavailable pump changes dispatch, not transfer ownership.
           Use the same preflight and GPU release as the live-pump branch. */
        CjguiInternalRendererStatus closeStatus = cjgui_windows_destroy_proc(route, NULL);
        if (closeStatus != CJGUI_INTERNAL_RENDERER_OK) return finish_destroy_admission(token, closeStatus);
        destroy_caller_phase_b(route);
        return finish_destroy_admission(token, CJGUI_INTERNAL_RENDERER_OK);
    }
    HANDLE pumpThread = route->pumpThread;
    HANDLE pumpStop = route->pumpStopEvent;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "destroy",
        CJGUI_WINDOWS_CMD_DESTROY, cjgui_windows_destroy_proc, NULL, NULL,
        120000u, &cmdId);
    if (st != CJGUI_INTERNAL_RENDERER_OK) return finish_destroy_admission(token, st);
    SetEvent(pumpStop);
    if (WaitForSingleObject(pumpThread, 30000u) != WAIT_OBJECT_0) {
        return finish_destroy_admission(token, CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR);
    }
    CloseHandle(pumpThread);
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) return finish_destroy_admission(token, CJGUI_INTERNAL_RENDERER_INVALID_SESSION);
    destroy_caller_phase_b(s);
    return finish_destroy_admission(token, CJGUI_INTERNAL_RENDERER_OK);
}

static CjguiInternalRendererStatus request_close_impl(uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s || !s->hwnd) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    return PostMessageW(s->hwnd, WM_CLOSE, 0, 0)
        ? CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

uint32_t cjgui_internal_renderer_occupied_session_count(void) {
    uint32_t count = 0;
    ensure_session_lock();
    EnterCriticalSection(&g_sessionLock);
    for (uint32_t i = 0; i < CJGUI_WINDOWS_SESSION_CAPACITY; ++i) count += g_sessions[i].occupied ? 1u : 0u;
    LeaveCriticalSection(&g_sessionLock);
    return count;
}

static uint64_t coordinate_lifetime_impl(uint64_t token,
    uint64_t *outSessionGeneration) {
    if (outSessionGeneration) *outSessionGeneration = 0u;
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s || !s->hwnd || !s->sessionGeneration || !s->coordinateEpoch) return 0u;
    if (outSessionGeneration) *outSessionGeneration = s->sessionGeneration;
    return s->coordinateEpoch;
}

void cjgui_internal_renderer_request_application_stop(void) {
    /* 停止语义投到各会话的 dispatcher 命令，不再对任意调用线程 PostQuitMessage。 */
    uint64_t tokens[CJGUI_WINDOWS_SESSION_CAPACITY];
    uint32_t count = 0u;
    ensure_session_lock();
    EnterCriticalSection(&g_sessionLock);
    for (uint32_t i = 0; i < CJGUI_WINDOWS_SESSION_CAPACITY; ++i) {
        if (g_sessions[i].occupied && g_sessions[i].pumpThreadId != 0u &&
            !g_sessions[i].retiring) {
            tokens[count++] = g_sessions[i].token;
        }
    }
    LeaveCriticalSection(&g_sessionLock);
    for (uint32_t i = 0u; i < count; ++i) cjgui_windows_enqueue_stop(tokens[i]);
}

int64_t cjgui_macos_control_accent_srgb8(void) {
    COLORREF color = GetSysColor(COLOR_HIGHLIGHT);
    uint32_t rgb = ((uint32_t)GetRValue(color) << 16) |
        ((uint32_t)GetGValue(color) << 8) | (uint32_t)GetBValue(color);
    return (int64_t)(0x01000000u | rgb);
}

static const char *data_transfer_event_format_impl(uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    return require_session(s) == CJGUI_INTERNAL_RENDERER_OK ? "" : "";
}

static uint32_t data_transfer_event_binary_size_impl(uint64_t token,
    uint64_t eventId) {
    (void)eventId;
    CjguiWindowsRendererSession *s = find_session(token);
    return require_session(s) == CJGUI_INTERNAL_RENDERER_OK ? 0u : 0u;
}

static CjguiInternalRendererStatus copy_data_transfer_event_binary_impl(
    uint64_t token, uint64_t eventId, uint8_t *outBytes, uint32_t capacity) {
    (void)eventId; (void)outBytes; (void)capacity;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    return owner == CJGUI_INTERNAL_RENDERER_OK
        ? CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED : owner;
}

static CjguiInternalRendererStatus prepare_composable_png_transfer_impl(
    uint64_t token, const char *resourceIdentity, const uint8_t *bytes, uint32_t length,
    uint32_t *outWidth, uint32_t *outHeight, uint64_t *outDecodeMicros) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!resourceIdentity || !bytes || !outWidth || !outHeight || !outDecodeMicros)
        return CJGUI_INTERNAL_RENDERER_PNG_INVALID;
    *outWidth = 0u; *outHeight = 0u; *outDecodeMicros = 0u;
    size_t identityBytes = strnlen(resourceIdentity, 1025u);
    if (identityBytes == 0u || identityBytes > 1024u || length == 0u || length > 512u * 1024u)
        return length > 512u * 1024u ? CJGUI_INTERNAL_RENDERER_PNG_PAYLOAD_TOO_LARGE
            : CJGUI_INTERNAL_RENDERER_PNG_INVALID;
    if (s->pendingPngTransferCount != 0u) return CJGUI_INTERNAL_RENDERER_PNG_QUEUE_BUDGET_EXCEEDED;
    uint8_t *decoded = (uint8_t *)malloc(1024u * 1024u);
    if (!decoded) return CJGUI_INTERNAL_RENDERER_PNG_RESOURCE_BUDGET_EXCEEDED;
    uint64_t decodedBytes = 0u;
    LARGE_INTEGER start, finish, frequency;
    QueryPerformanceCounter(&start); QueryPerformanceFrequency(&frequency);
    int32_t decode = cjgui_windows_wic_decode_png_rgba8(bytes, length, 512u * 1024u,
        2048u, 2048u, 1024u * 1024u, decoded, 1024u * 1024u,
        outWidth, outHeight, &decodedBytes);
    QueryPerformanceCounter(&finish);
    if (frequency.QuadPart > 0 && finish.QuadPart >= start.QuadPart) {
        *outDecodeMicros = (uint64_t)((finish.QuadPart - start.QuadPart) * 1000000u /
            (uint64_t)frequency.QuadPart);
    }
    free(decoded);
    if (decode != CJGUI_WINDOWS_WIC_OK) {
        if (decode == CJGUI_WINDOWS_WIC_INVALID_PNG) return CJGUI_INTERNAL_RENDERER_PNG_INVALID;
        if (decode == CJGUI_WINDOWS_WIC_DIMENSION_EXCEEDED) return CJGUI_INTERNAL_RENDERER_PNG_DIMENSION_EXCEEDED;
        if (decode == CJGUI_WINDOWS_WIC_BUDGET_EXCEEDED) return CJGUI_INTERNAL_RENDERER_PNG_RESOURCE_BUDGET_EXCEEDED;
        return CJGUI_INTERNAL_RENDERER_PNG_DECODE_FAILED;
    }
    s->pendingPngTransferIdentity = copy_valid_utf8(resourceIdentity, 1024u,
        NULL, &owner);
    if (!s->pendingPngTransferIdentity) return owner == CJGUI_INTERNAL_RENDERER_OK
        ? CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR : owner;
    s->pendingPngTransferCount = 1u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus finish_composable_png_transfer_impl(
    uint64_t token, const char *resourceIdentity, uint8_t accepted) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (accepted > 1u || !resourceIdentity || !s->pendingPngTransferCount ||
        !s->pendingPngTransferIdentity || strcmp(resourceIdentity, s->pendingPngTransferIdentity) != 0)
        return CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED;
    free(s->pendingPngTransferIdentity);
    s->pendingPngTransferIdentity = NULL;
    s->pendingPngTransferCount = 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static int windows_utf16_length(const char *utf8, uint32_t *outLength) {
    if (!utf8 || !outLength) return 0;
    size_t bytes = strnlen(utf8, CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY + 1u);
    if (bytes > CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY || bytes > INT_MAX) return 0;
    if (!bytes) { *outLength = 0u; return 1; }
    int units = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8,
        (int)bytes, NULL, 0);
    if (units <= 0) return 0;
    *outLength = (uint32_t)units;
    return 1;
}

static int windows_utf8_offset_for_utf16(const char *utf8, uint32_t target,
    uint64_t *outByteOffset) {
    if (!utf8 || !outByteOffset) return 0;
    const uint8_t *bytes = (const uint8_t *)utf8;
    uint64_t length = strnlen(utf8, CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY + 1u);
    if (length > CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY) return 0;
    uint64_t byte = 0u; uint32_t units = 0u;
    while (byte < length) {
        uint8_t first = bytes[byte];
        uint64_t scalarBytes = first < 0x80u ? 1u :
            (first & 0xe0u) == 0xc0u ? 2u : (first & 0xf0u) == 0xe0u ? 3u : 4u;
        uint32_t scalarUnits = scalarBytes == 4u ? 2u : 1u;
        if (units == target) { *outByteOffset = byte; return 1; }
        if (target > units && target < units + scalarUnits) return 0;
        units += scalarUnits;
        byte += scalarBytes;
    }
    if (units == target) { *outByteOffset = length; return 1; }
    return 0;
}

static int windows_utf8_grapheme_boundary(const char *utf8, uint64_t length,
    uint64_t offset) {
    if (offset > length) return 0;
    if (length == 0u) return offset == 0u;
    uint64_t probe = offset;
    if (probe == length) {
        --probe;
        while (probe > 0u && (((const uint8_t *)utf8)[probe] & 0xc0u) == 0x80u) --probe;
    }
    uint64_t start = 0u, end = 0u;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_grapheme_cluster_range(
        utf8, length, probe, &start, &end);
    return status == CJGUI_INTERNAL_RENDERER_OK &&
        ((offset == length && end == length) || (offset < length && start == offset));
}

static CjguiInternalRendererStatus windows_validate_active_text(
    CjguiWindowsRendererSession *s, uint64_t nodeId, int64_t resourceId,
    uint32_t nodeKind, uint64_t sceneVersion, const char *expectedValue,
    CjguiWindowsSceneNode **outNode) {
    if (!s || !expectedValue) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (sceneVersion != s->sceneVersion) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, nodeId);
    if (!node || node->node.resourceId != resourceId || node->node.nodeKind != nodeKind ||
        strcmp(node->value ? node->value : "", expectedValue) != 0)
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    if (s->focusedNodeId != nodeId || s->focusedResourceId != resourceId ||
        s->focusedNodeKind != nodeKind || !s->proxyValueUtf8 ||
        strcmp((const char *)s->proxyValueUtf8, expectedValue) != 0)
        return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    if (outNode) *outNode = node;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static char *duplicate_utf8_bytes(const char *text, size_t length) {
    char *copy = (char *)malloc(length + 1u);
    if (!copy) return NULL;
    if (length) memcpy(copy, text, length);
    copy[length] = '\0';
    return copy;
}

static void clear_pending_owned_input(CjguiWindowsRendererSession *s) {
    if (!s) return;
    free(s->pendingOwnedInputBase);
    free(s->pendingOwnedInputValue);
    s->pendingOwnedInputBase = NULL;
    s->pendingOwnedInputValue = NULL;
    s->pendingOwnedInputSceneVersion = 0u;
    s->pendingOwnedInputBindingEpoch = 0u;
    s->pendingOwnedInputNodeId = 0u;
    s->pendingOwnedInputResourceId = -1;
    s->pendingOwnedInputNodeKind = 0u;
    s->pendingOwnedInputEventCount = 0u;
}

static int replace_utf8_range16(const char *base, uint32_t start16, uint32_t end16,
    const char *insert, uint32_t insertLength, char **outValue, uint32_t *outLength) {
    if (!base || (!insert && insertLength) || !outValue || !outLength || end16 < start16)
        return 0;
    *outValue = NULL;
    *outLength = 0u;
    uint64_t startByte = 0u, endByte = 0u;
    if (!windows_utf8_offset_for_utf16(base, start16, &startByte) ||
        !windows_utf8_offset_for_utf16(base, end16, &endByte)) return 0;
    uint64_t baseLength = strlen(base);
    if (endByte > baseLength) return 0;
    uint64_t nextLength = startByte + insertLength + baseLength - endByte;
    if (nextLength > CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY || nextLength > UINT32_MAX)
        return 0;
    char *next = (char *)malloc((size_t)nextLength + 1u);
    if (!next) return 0;
    memcpy(next, base, (size_t)startByte);
    if (insertLength) memcpy(next + startByte, insert, insertLength);
    memcpy(next + startByte + insertLength, base + endByte, (size_t)(baseLength - endByte));
    next[nextLength] = '\0';
    *outValue = next;
    *outLength = (uint32_t)nextLength;
    return 1;
}

// 安装待决期间约束普通输入/导航/组合开始：不按旧选区产生事务，
// 调用方按未消费处理（交还消息系统，不静默吞键），计数供探针核对。
// 门只约束与其同代 owner 会话的票据，避免旧票阻塞新会话。
static int source_install_gate_holds_input(CjguiWindowsRendererSession *s) {
    if (!s || !s->sourceInstallPending) return 0;
    if (s->navReplayActive) return 0;
    if (!s->ownedTextSessionEnabled || !s->ownedTextSessionBindingEpoch ||
        s->sourceInstallBindingEpoch != s->ownedTextSessionBindingEpoch) return 0;
    if (s->sourceInstallGatedInputs != UINT64_MAX) ++s->sourceInstallGatedInputs;
    return 1;
}

// 只校验 accepted 目标（场景代次/节点身份/正文），不要求焦点与代理，
// 供原子安装在 SetFocus 之前使用；焦点与代理在安装后复核。
static CjguiWindowsSceneNode *windows_find_accepted_text(CjguiWindowsRendererSession *s,
    uint64_t nodeId, int64_t resourceId, uint32_t nodeKind, uint64_t sceneVersion,
    const char *expectedValue) {
    if (!s || !expectedValue || s->sceneVersion != sceneVersion) return NULL;
    CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, nodeId);
    if (!node || node->node.resourceId != resourceId || node->node.nodeKind != nodeKind ||
        strcmp(node->value ? node->value : "", expectedValue) != 0) return NULL;
    return node;
}

static void qorr_debug_log(const char *tag, CjguiWindowsRendererSession *s,
    const char *detail, int status) {
    /* 终版不写盘：诊断已收敛，保留空函数避免触碰 10 处调用点。 */
    (void)tag;
    (void)s;
    (void)detail;
    (void)status;
}

static void range_claims_clear(CjguiWindowsRendererSession *s) {
    for (uint32_t i = s->rangeClaimHead; i != s->rangeClaimTail; ++i) {
        CjguiWindowsRangeClaimEntry *entry = &s->rangeClaims[i % CJGUI_WINDOWS_RANGE_CLAIM_CAPACITY];
        free(entry->preBody);
        free(entry->replacement);
        free(entry->postBody);
        memset(entry, 0, sizeof(*entry));
    }
    s->rangeClaimHead = 0u;
    s->rangeClaimTail = 0u;
}

static void range_disarm(CjguiWindowsRendererSession *s) {
    range_claims_clear(s);
    free(s->rangeBasisText);
    free(s->rangeChainBody);
    s->rangeBasisText = NULL;
    s->rangeChainBody = NULL;
    s->rangeBasisTextLength = 0u;
    s->rangeChainBodyLength = 0u;
    s->rangeArmed = 0;
    s->rangeClosed = 0;
    s->rangeNonce = 0u;
    s->rangeNextSeq = 0u;
    s->rangePrevSeq = 0u;
    s->rangeAcceptedSeq = 0u;
    s->rangeAcceptedVersion = 0;
    s->rangeAcceptedSourceEnd = 0u;
}

static CjguiInternalRendererStatus installed_range_arm_impl(
    uint64_t token, const CjguiInternalInstalledRangeCandidate *candidate) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!candidate || candidate->nonce == 0u || candidate->bindingEpoch == 0u ||
        !candidate->sourceTextUtf8) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    if (candidate->sourceTextUtf8Length > CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY)
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    range_disarm(s);
    char *basisCopy = duplicate_utf8_bytes((const char *)candidate->sourceTextUtf8,
        (size_t)candidate->sourceTextUtf8Length);
    char *bodyCopy = duplicate_utf8_bytes((const char *)candidate->sourceTextUtf8,
        (size_t)candidate->sourceTextUtf8Length);
    if (!basisCopy || !bodyCopy) {
        free(basisCopy);
        free(bodyCopy);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    s->rangeArmed = 1;
    s->rangeClosed = 0;
    s->rangeNonce = candidate->nonce;
    s->rangeGeneration = candidate->rendererSessionGeneration
        ? candidate->rendererSessionGeneration : s->sessionGeneration;
    s->rangeWindowToken = candidate->windowInstanceToken;
    s->rangeBindingEpoch = candidate->bindingEpoch;
    s->rangeContextEpoch = candidate->contextEpoch;
    s->rangeMirrorRevision = candidate->mirrorRevision;
    s->rangeOwnerVersion = candidate->ownerVersion;
    s->rangeSceneVersion = candidate->installedSceneVersion;
    s->rangeNodeId = candidate->nodeId;
    s->rangeResourceId = candidate->resourceId;
    s->rangeSourceStart = candidate->sourceStartByte;
    s->rangeSourceEnd = candidate->sourceEndByte;
    s->rangeBasisText = basisCopy;
    s->rangeBasisTextLength = candidate->sourceTextUtf8Length;
    s->rangeChainBody = bodyCopy;
    s->rangeChainBodyLength = candidate->sourceTextUtf8Length;
    s->rangeProxyGeneration = s->rangeProxyGeneration + 1u;
    if (s->rangeProxyGeneration == 0u) s->rangeProxyGeneration = 1u;
    s->rangeSelectionRevision = s->rangeSelectionRevision + 1u;
    s->rangeSelectionStart16 = s->selectionStart16;
    s->rangeSelectionEnd16 = s->selectionEnd16;
    s->rangeAcceptedSeq = 0u;
    s->rangeAcceptedVersion = candidate->ownerVersion;
    s->rangeAcceptedSourceEnd = candidate->sourceEndByte;
    s->rangeNextSeq = 0u;
    s->rangePrevSeq = 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus installed_range_receipt_impl(
    uint64_t token, uint64_t nonce, CjguiInternalInstalledRangeReceipt *receipt) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!receipt) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (!s->rangeArmed || s->rangeNonce != nonce) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    memset(receipt, 0, sizeof(*receipt));
    receipt->nonce = s->rangeNonce;
    receipt->rendererSessionGeneration = s->rangeGeneration;
    receipt->windowInstanceToken = s->rangeWindowToken;
    receipt->bindingEpoch = s->rangeBindingEpoch;
    receipt->contextEpoch = s->rangeContextEpoch;
    receipt->mirrorRevision = s->rangeMirrorRevision;
    receipt->ownerVersion = s->rangeOwnerVersion;
    receipt->installedSceneVersion = s->rangeSceneVersion;
    receipt->nodeId = s->rangeNodeId;
    receipt->resourceId = s->rangeResourceId;
    receipt->sourceStartByte = s->rangeSourceStart;
    receipt->sourceEndByte = s->rangeSourceEnd;
    receipt->proxyGeneration = s->rangeProxyGeneration;
    receipt->selectionRevision = s->rangeSelectionRevision;
    receipt->actualSelectionStart16 = s->selectionStart16;
    receipt->actualSelectionEnd16 = s->selectionEnd16;
    receipt->acceptedSequence = s->rangeAcceptedSeq;
    receipt->acceptedVersion = s->rangeAcceptedVersion;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus installed_range_active_receipt_impl(
    uint64_t token, uint64_t nonce, CjguiInternalInstalledRangeReceipt *receipt) {
    return cjgui_internal_renderer_installed_range_receipt(token, nonce, receipt);
}

static CjguiInternalRendererStatus installed_range_activate_impl(
    uint64_t token, uint64_t nonce, uint64_t proxyGeneration, uint64_t selectionRevision) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!s->rangeArmed || s->rangeNonce != nonce) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    if (proxyGeneration != 0u && proxyGeneration != s->rangeProxyGeneration)
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    (void)selectionRevision;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus installed_range_cancel_impl(
    uint64_t token, uint64_t nonce) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!s->rangeArmed || s->rangeNonce != nonce) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    range_disarm(s);
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus claim_last_pumped_range_impl(
    uint64_t token, uint64_t node, int64_t resource, uint64_t binding, uint64_t scene,
    CjguiInternalInstalledRangeIntent *intent) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!intent) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (s->rangeClaimHead == s->rangeClaimTail) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    CjguiWindowsRangeClaimEntry *entry =
        &s->rangeClaims[s->rangeClaimHead % CJGUI_WINDOWS_RANGE_CLAIM_CAPACITY];
    if (entry->claimed || node != s->rangeNodeId || resource != s->rangeResourceId ||
        binding != s->rangeBindingEpoch || scene != entry->sceneVersion) {
        /* 队首不是刚泵出的本链事件：不拥有，交回普通路由（不消费）。 */
        return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    }
    memset(intent, 0, sizeof(*intent));
    intent->nonce = s->rangeNonce;
    intent->rendererSessionGeneration = s->rangeGeneration;
    intent->windowInstanceToken = s->rangeWindowToken;
    intent->bindingEpoch = s->rangeBindingEpoch;
    intent->contextEpoch = s->rangeContextEpoch;
    intent->mirrorRevision = s->rangeMirrorRevision;
    intent->ownerVersion = s->rangeOwnerVersion;
    intent->installedSceneVersion = s->rangeSceneVersion;
    intent->nodeId = s->rangeNodeId;
    intent->resourceId = s->rangeResourceId;
    /* Source scope belongs to the ACK observed at capture. Speculative
       preBody may already contain later queued edits; a newer ACK cannot
       retroactively replace this input's provenance. */
    intent->sourceStartByte = entry->observedSourceStartByte;
    intent->sourceEndByte = entry->observedSourceEndByte;
    intent->proxyGeneration = s->rangeProxyGeneration;
    intent->selectionRevision = s->rangeSelectionRevision;
    intent->seq = entry->seq;
    intent->previousSeq = entry->prevSeq;
    intent->observedAckSeq = entry->observedAckSeq;
    intent->observedAckVersion = entry->observedAckVersion;
    intent->wholeChoiceNonce = 0u;
    intent->wholeChoicePreviousSeq = 0u;
    intent->flags = entry->flags;
    intent->rangeStart16 = entry->rangeStart16;
    intent->rangeLength16 = entry->rangeLength16;
    intent->selectionStart16 = entry->selectionStart16;
    intent->selectionEnd16 = entry->selectionEnd16;
    intent->preBodyUtf8 = (const uint8_t *)entry->preBody;
    intent->preBodyUtf8Length = entry->preBodyLength;
    intent->replacementUtf8 = (const uint8_t *)entry->replacement;
    intent->replacementUtf8Length = entry->replacementLength;
    intent->postBodyUtf8 = (const uint8_t *)entry->postBody;
    intent->postBodyUtf8Length = entry->postBodyLength;
    entry->claimed = 1;
    windows_trace(s,"range_claim",entry->seq,entry->preBodyLength,entry->postBodyLength,
        s->rangeNonce,s->rangeProxyGeneration,s->rangeOwnerVersion);
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus copy_claimed_range_bytes_impl(
    uint64_t token, uint64_t seq,
    uint8_t *preBody, uint32_t preCapacity,
    uint8_t *replacement, uint32_t replacementCapacity,
    uint8_t *postBody, uint32_t postCapacity) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (s->rangeClaimHead == s->rangeClaimTail) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    CjguiWindowsRangeClaimEntry *entry =
        &s->rangeClaims[s->rangeClaimHead % CJGUI_WINDOWS_RANGE_CLAIM_CAPACITY];
    if (seq != entry->seq) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    if (preCapacity < entry->preBodyLength ||
        replacementCapacity < entry->replacementLength ||
        postCapacity < entry->postBodyLength) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    if (entry->preBodyLength) memcpy(preBody, entry->preBody, entry->preBodyLength);
    if (entry->replacementLength) memcpy(replacement, entry->replacement, entry->replacementLength);
    if (entry->postBodyLength) memcpy(postBody, entry->postBody, entry->postBodyLength);
    windows_trace(s,"range_copy",entry->seq,entry->preBodyLength,entry->postBodyLength,
        entry->replacementLength,s->rangeNonce,entry->flags);
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus ack_installed_range_impl(
    uint64_t token, const CjguiInternalInstalledRangeIntent *intent,
    uint32_t accepted, int64_t versionAfter) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!intent) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (s->rangeClaimHead == s->rangeClaimTail) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    CjguiWindowsRangeClaimEntry *entry =
        &s->rangeClaims[s->rangeClaimHead % CJGUI_WINDOWS_RANGE_CLAIM_CAPACITY];
    if (intent->seq != entry->seq || intent->nonce != s->rangeNonce)
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    windows_trace(s,"range_ack",entry->seq,accepted,(uint64_t)versionAfter,
        intent->nonce,intent->proxyGeneration,entry->observedAckSeq);
    if (accepted) {
        s->rangeAcceptedSeq = entry->seq;
        s->rangeAcceptedVersion = versionAfter;
        s->rangeAcceptedSourceEnd = s->rangeSourceStart + (uint64_t)entry->postBodyLength;
    } else {
        /* 拒绝的后缀：链按共享契约关闭，后续捕获带 closed 标记。 */
        s->rangeClosed = 1;
    }
    free(entry->preBody);
    free(entry->replacement);
    free(entry->postBody);
    memset(entry, 0, sizeof(*entry));
    s->rangeClaimHead += 1u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus release_installed_range_impl(
    uint64_t token, uint64_t document, uint64_t binding) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!s->rangeArmed) return CJGUI_INTERNAL_RENDERER_OK;
    if (document != 0u && document != s->rangeWindowToken) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    if (binding != 0u && binding != s->rangeBindingEpoch) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    range_disarm(s);
    return CJGUI_INTERNAL_RENDERER_OK;
}

static int queue_owned_range_replace(CjguiWindowsRendererSession *s,
    const char *insert, uint32_t insertLength, int64_t frozenModifiers,
    uint32_t repeatCount) {
    if (!s || !s->ownedTextSessionEnabled || !s->ownedTextSessionBindingEpoch ||
        !s->hwnd || GetFocus() != s->hwnd || !s->acceptedScene.configured) {
        if (s) qorr_debug_log("drop_early", s, insert, 0);
        return 0;
    }
    if (source_install_gate_holds_input(s)) {
        qorr_debug_log("drop_gate", s, insert, 0);
        return defer_input(s, 0u, insert ? insert : "", insertLength, NULL, 0u,
            frozenModifiers, repeatCount ? repeatCount : 1u, 0u, 0u, 0u);
    }
    if (s->navBarrierArmed && !s->navReplayActive) {
        return nav_barrier_hold_char(s, insert, insertLength, frozenModifiers);
    }
    if (s->compositionState != WINDOWS_COMPOSITION_IDLE || s->compositionActive) { qorr_debug_log("drop_comp", s, insert, 0); return 1; }
    uint64_t bindingEpoch = s->ownedTextSessionBindingEpoch;
    CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, s->ownedTextSessionNodeId);
    if (!node || node->node.resourceId != s->ownedTextSessionResourceId ||
        node->node.nodeKind != s->ownedTextSessionNodeKind ||
        (node->node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT &&
         node->node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT &&
         node->node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) ||
        s->focusedNodeId != s->ownedTextSessionNodeId ||
        s->focusedResourceId != s->ownedTextSessionResourceId ||
        s->focusedNodeKind != s->ownedTextSessionNodeKind) {
        qorr_debug_log("drop_node", s, insert, 0);
        return 0;
    }

    const char *base = NULL;
    int chainMode = 0;
    if (s->rangeArmed && s->rangeChainBody &&
        s->rangeNodeId == s->ownedTextSessionNodeId &&
        s->rangeResourceId == s->ownedTextSessionResourceId &&
        s->rangeBindingEpoch == bindingEpoch) {
        chainMode = 1;
        base = s->rangeChainBody;
    } else if (s->pendingOwnedInputEventCount) {
        if (s->pendingOwnedInputBindingEpoch != bindingEpoch ||
            s->pendingOwnedInputNodeId != s->ownedTextSessionNodeId ||
            s->pendingOwnedInputResourceId != s->ownedTextSessionResourceId ||
            s->pendingOwnedInputNodeKind != s->ownedTextSessionNodeKind ||
            s->pendingOwnedInputSceneVersion != s->sceneVersion ||
            !s->pendingOwnedInputBase || !s->pendingOwnedInputValue ||
            strcmp(node->value ? node->value : "", s->pendingOwnedInputBase) != 0) {
            qorr_debug_log("drop_pending", s, insert, 0);
            return 0;
        }
        base = s->pendingOwnedInputValue;
    } else {
        CjguiInternalRendererStatus vstatus = windows_validate_active_text(s, s->ownedTextSessionNodeId,
            s->ownedTextSessionResourceId, s->ownedTextSessionNodeKind,
            s->sceneVersion, node->value ? node->value : "", NULL);
        if (vstatus != CJGUI_INTERNAL_RENDERER_OK) {
            qorr_debug_log("drop_validate", s, insert, (int)vstatus);
            return 0;
        }
        base = node->value ? node->value : "";
    }

    uint32_t baseLength16 = 0u, insertLength16 = 0u;
    if (!windows_utf16_length(base, &baseLength16) ||
        !windows_utf16_length(insert ? insert : "", &insertLength16) ||
        s->selectionEnd16 < s->selectionStart16 || s->selectionEnd16 > baseLength16)
        return 0;
    uint64_t startByte = 0u, endByte = 0u;
    uint64_t baseBytes = strlen(base);
    if (!windows_utf8_offset_for_utf16(base, s->selectionStart16, &startByte) ||
        !windows_utf8_offset_for_utf16(base, s->selectionEnd16, &endByte) ||
        !windows_utf8_grapheme_boundary(base, baseBytes, startByte) ||
        !windows_utf8_grapheme_boundary(base, baseBytes, endByte)) return 0;

    char *nextValue = NULL;
    uint32_t nextLength = 0u;
    if (!replace_utf8_range16(base, s->selectionStart16, s->selectionEnd16,
        insert, insertLength, &nextValue, &nextLength)) return 0;
    uint32_t nextLength16 = 0u;
    if (!windows_utf16_length(nextValue, &nextLength16) ||
        s->selectionStart16 + insertLength16 > nextLength16) {
        free(nextValue);
        return 0;
    }

    if (chainMode) {
        /* installed-range 旁带生产：每笔输入一条 claim 记录（环形），事件携带
           真实捕获 scene（不再有 present 后重盖）。 */
        if (s->rangeClaimTail - s->rangeClaimHead >= CJGUI_WINDOWS_RANGE_CLAIM_CAPACITY) {
            /* 队列满载：保全已准入项，明确消费并拒绝这一笔（不写 owner）。 */
            free(nextValue);
            s->eventQueueFull = 1u;
            qorr_debug_log("chain_full", s, insert, 0);
            return 1;
        }
        uint64_t seq = s->rangeNextSeq + 1u;
        if (seq == 0u) { free(nextValue); return 0; }
        CjguiWindowsRangeClaimEntry *entry =
            &s->rangeClaims[s->rangeClaimTail % CJGUI_WINDOWS_RANGE_CLAIM_CAPACITY];
        memset(entry, 0, sizeof(*entry));
        char *preCopy = duplicate_utf8_bytes(base, strlen(base));
        char *replCopy = duplicate_utf8_bytes(insert ? insert : "", insertLength);
        char *postCopy = duplicate_utf8_bytes(nextValue, strlen(nextValue));
        if (!preCopy || !replCopy || !postCopy) {
            free(preCopy);
            free(replCopy);
            free(postCopy);
            free(nextValue);
            s->eventQueueFull = 1u;
            return 1;
        }
        entry->seq = seq;
        entry->prevSeq = s->rangePrevSeq;
        entry->observedAckSeq = s->rangeAcceptedSeq;
        entry->observedAckVersion = s->rangeAcceptedVersion;
        entry->observedSourceStartByte = s->rangeSourceStart;
        entry->observedSourceEndByte = s->rangeAcceptedSourceEnd;
        entry->flags = s->rangeClosed ? 1u : 0u;
        entry->rangeStart16 = s->selectionStart16;
        entry->rangeLength16 = s->selectionEnd16 - s->selectionStart16;
        entry->selectionStart16 = s->selectionStart16 + insertLength16;
        entry->selectionEnd16 = s->selectionStart16 + insertLength16;
        entry->sceneVersion = s->sceneVersion;
        entry->preBody = preCopy;
        entry->preBodyLength = (uint32_t)strlen(preCopy);
        entry->replacement = replCopy;
        entry->replacementLength = insertLength;
        entry->postBody = postCopy;
        entry->postBodyLength = (uint32_t)strlen(postCopy);
        entry->claimed = 0;
        s->rangeClaimTail += 1u;
        CjguiInternalRendererEvent chainEvent;
        memset(&chainEvent, 0, sizeof(chainEvent));
        chainEvent.kind = CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED;
        chainEvent.nodeId = s->ownedTextSessionNodeId;
        chainEvent.projectionVersion = s->sceneVersion;
        chainEvent.resourceId = s->ownedTextSessionResourceId;
        chainEvent.nodeKind = s->ownedTextSessionNodeKind;
        chainEvent.selectionStart = s->selectionStart16;
        chainEvent.selectionEnd = s->selectionEnd16;
        chainEvent.replacementStart16 = s->selectionStart16;
        chainEvent.replacementLength16 = (int64_t)s->selectionEnd16 - (int64_t)s->selectionStart16;
        chainEvent.bindingEpoch = bindingEpoch;
        if (!push_event_payload(s, &chainEvent, insert, insertLength)) {
            s->rangeClaimTail -= 1u;
            free(entry->preBody);
            free(entry->replacement);
            free(entry->postBody);
            memset(entry, 0, sizeof(*entry));
            free(nextValue);
            return 1;
        }
        s->rangeNextSeq = seq;
        s->rangePrevSeq = seq;
        free(s->rangeChainBody);
        s->rangeChainBody = nextValue;
        s->rangeChainBodyLength = (uint32_t)strlen(nextValue);
        s->rangeSelectionRevision += 1u;
        s->selectionStart16 = s->selectionEnd16 = s->selectionStart16 + insertLength16;
        qorr_debug_log("push_chain", s, insert, (int)seq);
        return 1;
    }

    char *nextBase = NULL;
    if (!s->pendingOwnedInputEventCount) {
        nextBase = duplicate_utf8_bytes(base, strlen(base));
        if (!nextBase) {
            free(nextValue);
            s->eventQueueFull = 1u;
            return 1;
        }
    }

    CjguiInternalRendererEvent event;
    memset(&event, 0, sizeof(event));
    event.kind = CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED;
    event.nodeId = s->ownedTextSessionNodeId;
    event.projectionVersion = s->pendingOwnedInputEventCount
        ? s->pendingOwnedInputSceneVersion : s->sceneVersion;
    event.resourceId = s->ownedTextSessionResourceId;
    event.nodeKind = s->ownedTextSessionNodeKind;
    event.selectionStart = s->selectionStart16;
    event.selectionEnd = s->selectionEnd16;
    event.replacementStart16 = s->selectionStart16;
    event.replacementLength16 = (int64_t)s->selectionEnd16 - (int64_t)s->selectionStart16;
    event.bindingEpoch = bindingEpoch;
    if (!push_event_payload(s, &event, insert, insertLength)) {
        free(nextValue);
        free(nextBase);
        return 1; // Refuse further local input; the existing queue-full event is explicit.
    }

    if (!s->pendingOwnedInputEventCount) {
        s->pendingOwnedInputBase = nextBase;
        s->pendingOwnedInputSceneVersion = s->sceneVersion;
        s->pendingOwnedInputBindingEpoch = bindingEpoch;
        s->pendingOwnedInputNodeId = s->ownedTextSessionNodeId;
        s->pendingOwnedInputResourceId = s->ownedTextSessionResourceId;
        s->pendingOwnedInputNodeKind = s->ownedTextSessionNodeKind;
    }
    free(s->pendingOwnedInputValue);
    s->pendingOwnedInputValue = nextValue;
    ++s->pendingOwnedInputEventCount;
    qorr_debug_log("push", s, insert, (int)s->pendingOwnedInputEventCount);
    s->selectionStart16 = s->selectionEnd16 = s->selectionStart16 + insertLength16;
    return 1;
}

static int handle_windows_text_character(CjguiWindowsRendererSession *s,
    const WCHAR *text, uint32_t units, int64_t frozenModifiers,
    uint32_t repeatCount) {
    if (!s || !text || units == 0u || units > 2u || !s->ownedTextSessionEnabled) {
        return 0;
    }
    WCHAR combined[2];
    uint32_t count = units;
    if (units == 1u && text[0] >= 0xd800u && text[0] <= 0xdbffu) {
        if (s->pendingHighSurrogate &&
            s->pendingHighSurrogateBindingEpoch == s->ownedTextSessionBindingEpoch) {
            WCHAR replacement = 0xfffdu;
            s->pendingHighSurrogate = 0u;
            s->pendingHighSurrogateBindingEpoch = 0u;
            if (!handle_windows_text_character(s, &replacement, 1u, frozenModifiers,
                repeatCount))
                return 0;
        }
        s->pendingHighSurrogate = text[0];
        s->pendingHighSurrogateBindingEpoch = s->ownedTextSessionBindingEpoch;
        return 1;
    }
    if (units == 1u && text[0] >= 0xdc00u && text[0] <= 0xdfffu) {
        if (s->pendingHighSurrogate &&
            s->pendingHighSurrogateBindingEpoch == s->ownedTextSessionBindingEpoch) {
            combined[0] = s->pendingHighSurrogate;
            combined[1] = text[0];
            count = 2u;
        } else {
            combined[0] = 0xfffdu;
            count = 1u;
        }
        s->pendingHighSurrogate = 0u;
        s->pendingHighSurrogateBindingEpoch = 0u;
        text = combined;
    } else if (units == 1u && s->pendingHighSurrogate) {
        WCHAR replacement = 0xfffdu;
        s->pendingHighSurrogate = 0u;
        s->pendingHighSurrogateBindingEpoch = 0u;
        if (!handle_windows_text_character(s, &replacement, 1u, frozenModifiers,
            repeatCount))
            return 0;
    }
    if (count == 1u && text[0] < 0x20u && text[0] != L'\r' && text[0] != L'\t')
        return 1;
    if (count == 1u && text[0] == L'\t') return 1;
    WCHAR normalized[2] = {text[0], count > 1u ? text[1] : 0u};
    if (count == 1u && normalized[0] == L'\r') normalized[0] = L'\n';
    int bytes = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, normalized,
        (int)count, NULL, 0, NULL, NULL);
    if (bytes <= 0 || bytes > 8) return 1;
    char utf8[9];
    if (WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, normalized,
        (int)count, utf8, bytes, NULL, NULL) != bytes) return 1;
    /* 终止符：下游 windows_utf16_length / 调试输出按 NUL 结尾读取。 */
    utf8[bytes] = '\0';
    (void)handle_windows_text_character;
    return queue_owned_range_replace(s, utf8, (uint32_t)bytes, frozenModifiers,
        repeatCount);
}

static int64_t windows_keyboard_modifiers(void) {
    /* 在 UI WndProc 冻结本消息的队列状态。连续 SendInput 可在处理 Home/Left
       前就释放 Ctrl/Shift；Async 此时只见最后物理状态，会篡改旧消息的意图。
       GetKeyState 随本线程取出键盘消息推进，消费 raw 时不再读取键盘。 */
    int64_t flags = 0;
    if (GetKeyState(VK_SHIFT) < 0) flags |= 0x020000;
    if (GetKeyState(VK_CONTROL) < 0) flags |= 0x040000;
    if (GetKeyState(VK_MENU) < 0) flags |= 0x080000;
    if (GetKeyState(VK_LWIN) < 0 || GetKeyState(VK_RWIN) < 0) flags |= 0x100000;
    return flags;
}

static int enqueue_windows_navigation(CjguiWindowsRendererSession *s, const char *intent,
    int64_t frozenModifiers) {
    if (!s || !intent || !s->ownedTextSessionEnabled || !s->ownedTextSessionBindingEpoch ||
        GetFocus() != s->hwnd) return 0;
    if (source_install_gate_holds_input(s)) {
        return defer_input(s, 1u, intent, (uint32_t)strlen(intent), NULL, 0u,
            frozenModifiers, 1u, 0u, 0u, 0u);
    }
    if (s->navBarrierArmed && !s->navReplayActive && nav_intent_is_delete(intent)) {
        return nav_barrier_hold_delete(s, intent, frozenModifiers);
    }
    CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, s->ownedTextSessionNodeId);
    if (!node || node->node.resourceId != s->ownedTextSessionResourceId ||
        node->node.nodeKind != s->ownedTextSessionNodeKind) return 0;
    CjguiInternalRendererEvent event;
    memset(&event, 0, sizeof(event));
    /* Primary Windows chords use the existing normalized command wire.
       The Cangjie declaration still resolves target, availability and scope;
       native never performs undo/save or stores an application command table. */
    event.kind = strncmp(intent, "shortcut:", 9u) == 0 ? 34u : 35u;
    event.nodeId = s->ownedTextSessionNodeId;
    event.projectionVersion = s->sceneVersion;
    event.resourceId = s->ownedTextSessionResourceId;
    event.nodeKind = s->ownedTextSessionNodeKind;
    event.bindingEpoch = s->ownedTextSessionBindingEpoch;
    event.modifierFlags = frozenModifiers;
    if (!push_event_payload(s, &event, intent, (uint32_t)strlen(intent))) return 0;
    if (nav_intent_is_movement(intent)) {
        s->navBarrierArmed = 1u;
        s->navBarrierEpoch += 1u;
    }
    return 1;
}

static int handle_windows_key_down(CjguiWindowsRendererSession *s, WPARAM key,
    int64_t frozenModifiers) {
    if (!s || !s->ownedTextSessionEnabled || GetFocus() != s->hwnd) return 0;
    if (s->compositionState != WINDOWS_COMPOSITION_IDLE || s->compositionActive) {
        if (key == VK_ESCAPE) {
            end_windows_ime_composition(s);
            return 1;
        }
        return 0;
    }
    if ((frozenModifiers & 0x040000) != 0 &&
        (frozenModifiers & (0x080000 | 0x100000)) == 0 && key >= 'A' && key <= 'Z') {
        /* Ctrl is the Windows primary modifier. AltGr and Windows-key chords
           are distinct input, and cannot accidentally invoke this route. */
        char shortcut[40];
        snprintf(shortcut, sizeof(shortcut), "shortcut:%scommand+%c",
            (frozenModifiers & 0x020000) != 0 ? "shift+" : "", (char)(key - 'A' + 'a'));
        return enqueue_windows_navigation(s, shortcut, frozenModifiers);
    }
    const char *intent = NULL;
    switch (key) {
        case VK_BACK: intent = "deleteBackward"; break;
        case VK_DELETE: intent = "deleteForward"; break;
        case VK_LEFT: intent = "left"; break;
        case VK_RIGHT: intent = "right"; break;
        case VK_UP: intent = "up"; break;
        case VK_DOWN: intent = "down"; break;
        case VK_HOME: intent = "home"; break;
        case VK_END: intent = "end"; break;
        case VK_ESCAPE: intent = "escape"; break;
        default: break;
    }
    if (!intent) return 0;
    return enqueue_windows_navigation(s, intent, frozenModifiers);
}

static int nav_intent_is_movement(const char *intent) {
    if (!intent) return 0;
    return strcmp(intent, "left") == 0 || strcmp(intent, "right") == 0 ||
        strcmp(intent, "up") == 0 || strcmp(intent, "down") == 0 ||
        strcmp(intent, "home") == 0 || strcmp(intent, "end") == 0;
}

static int nav_intent_is_delete(const char *intent) {
    if (!intent) return 0;
    return strcmp(intent, "deleteBackward") == 0 || strcmp(intent, "deleteForward") == 0;
}

static int nav_barrier_hold_char(CjguiWindowsRendererSession *s,
    const char *insert, uint32_t insertLength, int64_t frozenModifiers) {
    if (!s || !insert) return 0;
    if (s->navHoldCount >= CJGUI_WINDOWS_NAV_HOLD_CAPACITY ||
        s->navHoldBytes + insertLength > CJGUI_WINDOWS_NAV_HOLD_BYTES) {
        s->deferredDrops += 1u;
        if (!stash_recovery(s, CJGUI_WINDOWS_RECOVERY_OVERFLOW,
                CJGUI_WINDOWS_INSTALL_OUTCOME_NONE, s->deferredNextId,
                s->ownedTextSessionBindingEpoch, 0u, 0u, insert, insertLength,
                NULL, 0u, frozenModifiers, 1u, 0u, 0u, 0u)) {
            s->eventQueueFull = 1u;
            return 0;
        }
        return 1;
    }
    char *copy = duplicate_utf8_bytes(insert, insertLength);
    if (!copy) {
        s->deferredDrops += 1u;
        s->eventQueueFull = 1u;
        return 0;
    }
    uint32_t slot = (s->navHoldHead + s->navHoldCount) % CJGUI_WINDOWS_NAV_HOLD_CAPACITY;
    s->navHold[slot].isDelete = 0u;
    s->navHold[slot].bytes = copy;
    s->navHold[slot].length = insertLength;
    s->navHold[slot].modifiers = frozenModifiers;
    s->navHold[slot].inputId = s->deferredNextId ? s->deferredNextId : 1u;
    s->deferredNextId = s->navHold[slot].inputId + 1u;
    if (!s->deferredNextId) s->deferredNextId = 1u;
    s->navHold[slot].bindingEpoch = s->ownedTextSessionBindingEpoch;
    s->navHold[slot].requestId = s->sourceInstallRequestId;
    s->navHoldCount += 1u;
    s->navHoldBytes += insertLength;
    return 1;
}

static int nav_barrier_hold_delete(CjguiWindowsRendererSession *s,
    const char *intent, int64_t frozenModifiers) {
    if (!s || !intent) return 0;
    uint32_t intentLength = (uint32_t)strlen(intent);
    if (s->navHoldCount >= CJGUI_WINDOWS_NAV_HOLD_CAPACITY ||
        s->navHoldBytes + intentLength > CJGUI_WINDOWS_NAV_HOLD_BYTES) {
        s->deferredDrops += 1u;
        if (!stash_recovery(s, CJGUI_WINDOWS_RECOVERY_OVERFLOW,
                CJGUI_WINDOWS_INSTALL_OUTCOME_NONE, s->deferredNextId,
                s->ownedTextSessionBindingEpoch, 0u, 1u, intent, intentLength,
                NULL, 0u, frozenModifiers, 1u, 0u, 0u, 0u)) {
            s->eventQueueFull = 1u;
            return 0;
        }
        return 1;
    }
    char *copy = duplicate_utf8_bytes(intent, intentLength);
    if (!copy) {
        s->deferredDrops += 1u;
        s->eventQueueFull = 1u;
        return 0;
    }
    uint32_t slot = (s->navHoldHead + s->navHoldCount) % CJGUI_WINDOWS_NAV_HOLD_CAPACITY;
    s->navHold[slot].isDelete = 1u;
    s->navHold[slot].bytes = copy;
    s->navHold[slot].length = intentLength;
    s->navHold[slot].modifiers = frozenModifiers;
    s->navHold[slot].inputId = s->deferredNextId ? s->deferredNextId : 1u;
    s->deferredNextId = s->navHold[slot].inputId + 1u;
    if (!s->deferredNextId) s->deferredNextId = 1u;
    s->navHold[slot].bindingEpoch = s->ownedTextSessionBindingEpoch;
    s->navHold[slot].requestId = s->sourceInstallRequestId;
    s->navHoldCount += 1u;
    s->navHoldBytes += intentLength;
    return 1;
}

static int nav_barrier_release(CjguiWindowsRendererSession *s, int replay) {
    if (!s || !s->navBarrierArmed) return 1;
    uint64_t barrier = s->navBarrierEpoch;
    while (s->navHoldCount) {
        uint32_t slot = s->navHoldHead % CJGUI_WINDOWS_NAV_HOLD_CAPACITY;
        if (replay) {
            s->navReplayActive = 1u;
            int delivered = s->navHold[slot].isDelete
                ? enqueue_windows_navigation(s, s->navHold[slot].bytes,
                    s->navHold[slot].modifiers)
                : queue_owned_range_replace(s, s->navHold[slot].bytes,
                    s->navHold[slot].length, s->navHold[slot].modifiers, 1u);
            s->navReplayActive = 0u;
            if (!delivered) { s->eventQueueFull = 1u; return 0; }
        }
        s->navHoldBytes -= s->navHold[slot].length;
        free(s->navHold[slot].bytes);
        memset(&s->navHold[slot], 0, sizeof(s->navHold[slot]));
        s->navHoldHead = (s->navHoldHead + 1u) % CJGUI_WINDOWS_NAV_HOLD_CAPACITY;
        s->navHoldCount -= 1u;
        if (replay && s->navBarrierEpoch != barrier) return 1;
    }
    s->navBarrierArmed = 0u;
    return 1;
}

static int read_imm_utf8(HIMC context, DWORD index, char **outText,
    uint32_t *outBytes, uint32_t *outUnits) {
    if (!context || !outText || !outBytes || !outUnits) return 0;
    *outText = NULL;
    *outBytes = 0u;
    *outUnits = 0u;
    LONG wideBytes = ImmGetCompositionStringW(context, index, NULL, 0u);
    if (wideBytes < 0 || (wideBytes % (LONG)sizeof(WCHAR)) != 0 ||
        (uint64_t)wideBytes > CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY * sizeof(WCHAR))
        return 0;
    uint32_t units = (uint32_t)(wideBytes / (LONG)sizeof(WCHAR));
    WCHAR *wide = units ? (WCHAR *)malloc((size_t)wideBytes) : NULL;
    if (units && !wide) return 0;
    if (units && ImmGetCompositionStringW(context, index, wide, (DWORD)wideBytes) != wideBytes) {
        free(wide);
        return 0;
    }
    int bytes = units ? WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS,
        wide, (int)units, NULL, 0, NULL, NULL) : 0;
    if (bytes < 0 || (uint32_t)bytes > CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY) {
        free(wide);
        return 0;
    }
    char *utf8 = (char *)malloc((size_t)bytes + 1u);
    if (!utf8) {
        free(wide);
        return 0;
    }
    if (bytes && WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS,
        wide, (int)units, utf8, bytes, NULL, NULL) != bytes) {
        free(wide);
        free(utf8);
        return 0;
    }
    utf8[bytes] = '\0';
    free(wide);
    *outText = utf8;
    *outBytes = (uint32_t)bytes;
    *outUnits = units;
    return 1;
}

static int begin_windows_composition(CjguiWindowsRendererSession *s) {
    if (!s || !s->ownedTextSessionEnabled || !s->ownedTextSessionBindingEpoch ||
        s->compositionState != WINDOWS_COMPOSITION_IDLE || s->compositionGate != WINDOWS_COMPOSITION_GATE_OPEN)
        return 0;
    if (source_install_gate_holds_input(s)) return 0;
    if (s->eventCount >= CJGUI_WINDOWS_EVENT_CAPACITY - 1u ||
        s->eventTextBytes > CJGUI_WINDOWS_EVENT_TEXT_BUDGET - CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY) {
        s->eventQueueFull = 1u;
        return 0;
    }
    CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, s->ownedTextSessionNodeId);
    if (!node || node->node.resourceId != s->ownedTextSessionResourceId ||
        node->node.nodeKind != s->ownedTextSessionNodeKind ||
        windows_validate_active_text(s, s->ownedTextSessionNodeId,
            s->ownedTextSessionResourceId, s->ownedTextSessionNodeKind,
            s->sceneVersion, node->value ? node->value : "", NULL) != CJGUI_INTERNAL_RENDERER_OK)
        return 0;
    size_t length = strlen(node->value ? node->value : "");
    char *base = duplicate_utf8_bytes(node->value ? node->value : "", length);
    uint64_t compositionId = next_positive_counter(&g_nextCompositionId);
    if (!base || !compositionId) {
        free(base);
        return 0;
    }
    if (s->selectionEnd16 < s->selectionStart16) {
        free(base);
        return 0;
    }
    s->compositionBaseUtf8 = base;
    s->compositionExpectedOwnerUtf8 = NULL;
    s->activeCompositionId = compositionId;
    s->compositionBindingEpoch = s->ownedTextSessionBindingEpoch;
    s->compositionSceneVersion = s->sceneVersion;
    s->compositionNodeId = s->ownedTextSessionNodeId;
    s->compositionResourceId = s->ownedTextSessionResourceId;
    s->compositionNodeKind = s->ownedTextSessionNodeKind;
    s->compositionReplacementStart16 = s->selectionStart16;
    s->compositionReplacementLength16 = s->selectionEnd16 - s->selectionStart16;
    s->compositionState = WINDOWS_COMPOSITION_MARKED;
    s->compositionGate = WINDOWS_COMPOSITION_GATE_OPEN;
    s->compositionTerminalReserved = 1u;
    s->compositionTerminalPhase = 0u;
    s->compositionActive = 1u;
    s->pendingHighSurrogate = 0u;
    s->pendingHighSurrogateBindingEpoch = 0u;
    return 1;
}

static int queue_windows_composition_update(CjguiWindowsRendererSession *s,
    const char *text, uint32_t textBytes, uint32_t cursor16) {
    if (!s || !text || s->compositionGate != WINDOWS_COMPOSITION_GATE_OPEN) return 0;
    if (s->compositionState == WINDOWS_COMPOSITION_IDLE && !begin_windows_composition(s)) return 0;
    if (s->compositionState != WINDOWS_COMPOSITION_MARKED) return 0;
    uint32_t markedLength16 = 0u;
    if (!windows_utf16_length(text, &markedLength16)) return 0;
    if (cursor16 > markedLength16) cursor16 = markedLength16;
    CjguiInternalRendererEvent event;
    memset(&event, 0, sizeof(event));
    event.kind = CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_COMPOSITION;
    event.nodeId = s->compositionNodeId;
    event.projectionVersion = s->compositionSceneVersion;
    event.resourceId = s->compositionResourceId;
    event.nodeKind = s->compositionNodeKind;
    event.compositionPhase = CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_UPDATE;
    event.compositionId = s->activeCompositionId;
    event.bindingEpoch = s->compositionBindingEpoch;
    event.replacementStart16 = s->compositionReplacementStart16;
    event.replacementLength16 = s->compositionReplacementLength16;
    event.markedStart16 = s->compositionReplacementStart16;
    event.markedLength16 = markedLength16;
    event.selectionStart = cursor16;
    event.selectionEnd = cursor16;
    if (!push_event_payload_internal(s, &event, text, textBytes, 0)) {
        s->compositionGate = WINDOWS_COMPOSITION_GATE_RECOVERING;
        return 0;
    }
    return 1;
}

static int queue_windows_composition_terminal(CjguiWindowsRendererSession *s,
    uint32_t phase, const char *text, uint32_t textBytes) {
    if (!s || s->compositionState != WINDOWS_COMPOSITION_MARKED ||
        (phase != CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_COMMIT &&
         phase != CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_CANCEL)) return 0;
    CjguiInternalRendererEvent event;
    memset(&event, 0, sizeof(event));
    event.kind = CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_COMPOSITION;
    event.nodeId = s->compositionNodeId;
    event.projectionVersion = s->compositionSceneVersion;
    event.resourceId = s->compositionResourceId;
    event.nodeKind = s->compositionNodeKind;
    event.compositionPhase = phase;
    event.compositionId = s->activeCompositionId;
    event.bindingEpoch = s->compositionBindingEpoch;
    event.replacementStart16 = s->compositionReplacementStart16;
    event.replacementLength16 = s->compositionReplacementLength16;
    event.markedStart16 = -1;
    event.markedLength16 = 0;
    if (phase == CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_COMMIT && text) {
        uint32_t expectedLength = 0u;
        if (!replace_utf8_range16(s->compositionBaseUtf8,
            s->compositionReplacementStart16,
            s->compositionReplacementStart16 + s->compositionReplacementLength16,
            text, textBytes, &s->compositionExpectedOwnerUtf8, &expectedLength))
            return 0;
    } else if (phase == CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_CANCEL) {
        s->compositionExpectedOwnerUtf8 = duplicate_utf8_bytes(s->compositionBaseUtf8,
            strlen(s->compositionBaseUtf8));
        if (!s->compositionExpectedOwnerUtf8) return 0;
    }
    if (!push_event_payload_internal(s, &event, text, textBytes, 1)) {
        free(s->compositionExpectedOwnerUtf8);
        s->compositionExpectedOwnerUtf8 = NULL;
        s->compositionGate = WINDOWS_COMPOSITION_GATE_RECOVERING;
        s->eventQueueFull = 1u;
        return 0;
    }
    s->compositionTerminalPhase = phase;
    s->compositionState = WINDOWS_COMPOSITION_TERMINAL_QUEUED;
    s->compositionGate = WINDOWS_COMPOSITION_GATE_RETIRING;
    return 1;
}

static void clear_pending_ime_successor(CjguiWindowsRendererSession *s) {
    free(s->pendingImeSuccessorUtf8);
    s->pendingImeSuccessorUtf8 = NULL;
    s->pendingImeSuccessorBytes = 0u;
    s->pendingImeSuccessorCursor16 = 0u;
    s->pendingImeSuccessorPresent = 0u;
    s->pendingImeSuccessorReady = 0u;
    s->pendingImeSuccessorInputId = 0u;
    s->pendingImeSuccessorBindingEpoch = 0u;
    s->pendingImeSuccessorRequestId = 0u;
    s->pendingImeSuccessorCompositionId = 0u;
    s->pendingImeSuccessorNodeId = 0u;
    s->pendingImeSuccessorResourceId = -1;
    s->pendingImeSuccessorNodeKind = 0u;
    s->pendingImeSuccessorDeliveryCompositionId = 0u;
}

static int recover_pending_ime_successor(CjguiWindowsRendererSession *s,
    uint32_t outcome) {
    if (!s->pendingImeSuccessorPresent) return 1;
    /* Only the not-yet-delivered marked update transfers here. Its preceding
       commit is already queued; never package that commit for replay again.
       kind 2 / UPDATE is the existing captured composition-update record. */
    if (!stash_recovery(s, CJGUI_WINDOWS_RECOVERY_GATE_OUTCOME, outcome,
        s->pendingImeSuccessorInputId, s->pendingImeSuccessorBindingEpoch,
        s->pendingImeSuccessorRequestId, 2u, s->pendingImeSuccessorUtf8,
        s->pendingImeSuccessorBytes, NULL, 0u, 0, 1u,
        s->pendingImeSuccessorCompositionId,
        CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_UPDATE,
        s->pendingImeSuccessorCursor16)) return 0;
    clear_pending_ime_successor(s);
    return 1;
}

static int remember_ime_successor(CjguiWindowsRendererSession *s,
    const char *text, uint32_t textBytes, uint32_t cursor16,
    uint64_t inputId, uint64_t bindingEpoch, uint64_t requestId,
    uint64_t compositionId) {
    if (!s || !text) return 0;
    char *copy = duplicate_utf8_bytes(text, textBytes);
    if (!copy) { s->eventQueueFull = 1u; return 0; }
    free(s->pendingImeSuccessorUtf8);
    s->pendingImeSuccessorUtf8 = copy;
    s->pendingImeSuccessorBytes = textBytes;
    s->pendingImeSuccessorCursor16 = cursor16;
    s->pendingImeSuccessorPresent = 1u;
    s->pendingImeSuccessorInputId = inputId ? inputId : s->deferredNextId++;
    s->pendingImeSuccessorBindingEpoch = bindingEpoch;
    s->pendingImeSuccessorRequestId = requestId;
    s->pendingImeSuccessorCompositionId = compositionId;
    s->pendingImeSuccessorNodeId = s->compositionNodeId;
    s->pendingImeSuccessorResourceId = s->compositionResourceId;
    s->pendingImeSuccessorNodeKind = s->compositionNodeKind;
    s->pendingImeSuccessorDeliveryCompositionId = 0u;
    return 1;
}

static int handle_windows_ime_composition(CjguiWindowsRendererSession *s,
    LPARAM flags, int64_t imeSlot) {
    if (!s || !s->ownedTextSessionEnabled) return 0;
    if (imeSlot < 0 || imeSlot >= (int64_t)CJGUI_WINDOWS_IME_FROZEN_CAPACITY)
        { s->eventQueueFull = 1u; return 0; }
    CjguiWindowsImeFrozen *frozen = &s->imeFrozen[(uint32_t)imeSlot];
    if (!frozen->used || frozen->bindingEpoch != s->ownedTextSessionBindingEpoch)
        { s->eventQueueFull = 1u; return 0; }
    frozen->readyForRetry = 1u;
    int hasResult = (frozen->flags & GCS_RESULTSTR) && !(frozen->handledFlags & GCS_RESULTSTR);
    int hasMarked = (frozen->flags & GCS_COMPSTR) && !(frozen->handledFlags & GCS_COMPSTR);
    if (!source_install_gate_holds_input(s) &&
        s->compositionGate != WINDOWS_COMPOSITION_GATE_OPEN) {
        if (frozen->retryablePressure && s->compositionState == WINDOWS_COMPOSITION_MARKED &&
            frozen->compositionId == s->activeCompositionId &&
            frozen->bindingEpoch == s->compositionBindingEpoch) {
            s->compositionGate = WINDOWS_COMPOSITION_GATE_OPEN;
        } else if (!(s->compositionState == WINDOWS_COMPOSITION_TERMINAL_QUEUED && !hasResult)) {
            return 0;
        }
    }
    int handled = handle_ime_core(s, flags, hasResult, frozen->resultText,
        frozen->resultBytes, 0u, hasMarked, frozen->markedText,
        frozen->markedBytes, frozen->cursor16, frozen);
    if (!handled) {
        frozen->retryablePressure = 1u;
        s->eventQueueFull = 1u;
        return 0;
    }
    ime_frozen_free_slot(s, imeSlot);
    return 1;
}

static void retry_kept_ime_frozen(CjguiWindowsRendererSession *s) {
    if (!s || !s->imeFrozenCount) return;
    for (uint32_t i = 0u; i < CJGUI_WINDOWS_IME_FROZEN_CAPACITY; ++i) {
        CjguiWindowsImeFrozen *frozen = &s->imeFrozen[i];
        if (!frozen->used || !frozen->readyForRetry) continue;
        if (frozen->bindingEpoch != s->ownedTextSessionBindingEpoch) {
            s->imeFreezeMisses += 1u;
            /* 旧来源走恢复接收方，转移失败仍保原件，不给新绑定重放。 */
            if (!stash_recovery(s, CJGUI_WINDOWS_RECOVERY_GATE_OUTCOME,
                CJGUI_WINDOWS_INSTALL_OUTCOME_CONFLICT, s->deferredNextId,
                frozen->bindingEpoch, 0u, 3u,
                frozen->resultText, frozen->resultBytes,
                frozen->markedText, frozen->markedBytes, 0, 1u,
                frozen->compositionId, 0u, frozen->cursor16)) break;
            s->deferredNextId += 1u;
            uint32_t slot = (s->recoveryHead + s->recoveryCount - 1u) % CJGUI_WINDOWS_RECOVERY_CAPACITY;
            s->recoverySlots[slot].handledParts = (uint32_t)frozen->handledFlags;
            ime_frozen_free_slot(s, (int64_t)i);
            continue;
        }
        if (!handle_windows_ime_composition(s, (LPARAM)frozen->flags, (int64_t)i)) break;
    }
}

static int handle_ime_core(CjguiWindowsRendererSession *s, LPARAM flags,
    int hasResult, char *resultText, uint32_t resultBytes, uint32_t resultUnits,
    int hasMarked, char *markedText, uint32_t markedBytes, uint32_t cursor16,
    CjguiWindowsImeFrozen *progress) {
    (void)flags;
    if (source_install_gate_holds_input(s)) {
        uint32_t kind = hasResult ? 3u : 2u;
        const char *bytes = hasResult ? resultText : markedText;
        uint32_t length = hasResult ? resultBytes : markedBytes;
        const char *extra = (hasResult && hasMarked) ? markedText : NULL;
        uint32_t extraLength = (hasResult && hasMarked) ? markedBytes : 0u;
        if (!defer_input(s, kind, bytes ? bytes : "", length, extra,
            extraLength, 0, 1u, s->activeCompositionId,
            hasResult ? CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_COMMIT
                      : CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_UPDATE,
            cursor16)) return 0;
        if (hasResult) progress->handledFlags |= GCS_RESULTSTR;
        if (hasMarked) progress->handledFlags |= GCS_COMPSTR;
        return 1;
    }
    if (hasResult) {
        if (s->compositionState == WINDOWS_COMPOSITION_IDLE) {
            if (!begin_windows_composition(s)) return 0;
            progress->needsResultUpdate = 1u;
            progress->compositionId = s->activeCompositionId;
        }
        if (progress->needsResultUpdate) {
            if (!queue_windows_composition_update(s, resultText, resultBytes, resultUnits)) return 0;
            progress->needsResultUpdate = 0u;
        }
        if (s->compositionState != WINDOWS_COMPOSITION_MARKED ||
            !queue_windows_composition_terminal(s,
                CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_COMMIT, resultText, resultBytes))
            return 0;
        progress->handledFlags |= GCS_RESULTSTR;
    }
    if (hasMarked) {
        int accepted = s->compositionState == WINDOWS_COMPOSITION_TERMINAL_QUEUED
            ? remember_ime_successor(s, markedText, markedBytes, cursor16,
                0u, progress->bindingEpoch, s->sourceInstallRequestId,
                progress->compositionId)
            : queue_windows_composition_update(s, markedText, markedBytes, cursor16);
        if (!accepted) return 0;
        progress->handledFlags |= GCS_COMPSTR;
    }
    return 1;
}

static void end_windows_ime_composition(CjguiWindowsRendererSession *s) {
    if (!s || s->compositionState != WINDOWS_COMPOSITION_MARKED) return;
    s->compositionGate = WINDOWS_COMPOSITION_GATE_RETIRING;
    if (!queue_windows_composition_terminal(s,
        CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_CANCEL, "", 0u)) {
        s->compositionGate = WINDOWS_COMPOSITION_GATE_RECOVERING;
        s->eventQueueFull = 1u;
    }
}

static void finish_windows_composition_after_presentation(CjguiWindowsRendererSession *s) {
    if (!s || s->compositionState != WINDOWS_COMPOSITION_TERMINAL_QUEUED ||
        !s->compositionExpectedOwnerUtf8) return;
    CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, s->compositionNodeId);
    if (!node || node->node.resourceId != s->compositionResourceId ||
        node->node.nodeKind != s->compositionNodeKind ||
        strcmp(node->value ? node->value : "", s->compositionExpectedOwnerUtf8) != 0) {
        s->compositionGate = WINDOWS_COMPOSITION_GATE_RECOVERING;
        (void)recover_pending_ime_successor(s, CJGUI_WINDOWS_INSTALL_OUTCOME_CONFLICT);
        return;
    }
    s->pendingImeSuccessorReady = s->compositionTerminalPhase ==
        CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_COMMIT && s->pendingImeSuccessorPresent;
    s->compositionActive = 0u;
    s->compositionState = WINDOWS_COMPOSITION_IDLE;
    s->compositionGate = WINDOWS_COMPOSITION_GATE_OPEN;
    s->activeCompositionId = 0u;
    s->compositionBindingEpoch = 0u;
    s->compositionSceneVersion = 0u;
    s->compositionNodeId = 0u;
    s->compositionResourceId = -1;
    s->compositionNodeKind = 0u;
    s->compositionReplacementStart16 = 0u;
    s->compositionReplacementLength16 = 0u;
    s->compositionTerminalPhase = 0u;
    free(s->compositionBaseUtf8);
    s->compositionBaseUtf8 = NULL;
    free(s->compositionExpectedOwnerUtf8);
    s->compositionExpectedOwnerUtf8 = NULL;
}

static void synchronize_owned_proxy_after_presentation(CjguiWindowsRendererSession *s) {
    if (!s || !s->ownedTextSessionEnabled || !s->hwnd ||
        s->compositionState == WINDOWS_COMPOSITION_MARKED) return;
    CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, s->ownedTextSessionNodeId);
    if (!node || node->node.resourceId != s->ownedTextSessionResourceId ||
        node->node.nodeKind != s->ownedTextSessionNodeKind ||
        s->focusedNodeId != s->ownedTextSessionNodeId ||
        s->focusedResourceId != s->ownedTextSessionResourceId ||
        s->focusedNodeKind != s->ownedTextSessionNodeKind) return;
    const char *accepted = node->value ? node->value : "";
    CjguiInternalRendererStatus copyStatus = CJGUI_INTERNAL_RENDERER_OK;
    uint8_t *copy = (uint8_t *)copy_valid_utf8(accepted,
        CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY, NULL, &copyStatus);
    if (!copy) return;
    uint32_t acceptedLength16 = 0u;
    if (!windows_utf16_length(accepted, &acceptedLength16)) {
        free(copy);
        return;
    }
    if (s->pendingOwnedInputEventCount) {
        /* The local shadow is admitted only if the exact resulting owner bytes
         * were presented. A refusal or external write retires every dependent
         * coordinate before another character can enter the owner session. */
        if (node->node.resourceId != s->pendingOwnedInputResourceId ||
            node->node.nodeKind != s->pendingOwnedInputNodeKind ||
            strcmp(accepted, s->pendingOwnedInputValue ? s->pendingOwnedInputValue : "") != 0)
            s->selectionStart16 = s->selectionEnd16 = acceptedLength16;
        clear_pending_owned_input(s);
    }
    if (!s->proxyValueUtf8 || strcmp((const char *)s->proxyValueUtf8, accepted) != 0) {
        free(s->proxyValueUtf8);
        s->proxyValueUtf8 = copy;
        copy = NULL;
    }
    free(copy);
    if (s->selectionEnd16 > acceptedLength16)
        s->selectionStart16 = s->selectionEnd16 = acceptedLength16;
}

static void start_pending_ime_successor(CjguiWindowsRendererSession *s) {
    if (!s || !s->pendingImeSuccessorReady || !s->pendingImeSuccessorPresent) return;
    /* The copied marked update belongs to the captured producer. A later
       valid focus/binding must not lend it authority over another owner. */
    if (!s->ownedTextSessionEnabled ||
        s->ownedTextSessionBindingEpoch != s->pendingImeSuccessorBindingEpoch ||
        s->ownedTextSessionNodeId != s->pendingImeSuccessorNodeId ||
        s->ownedTextSessionResourceId != s->pendingImeSuccessorResourceId ||
        s->ownedTextSessionNodeKind != s->pendingImeSuccessorNodeKind) {
        (void)recover_pending_ime_successor(s, CJGUI_WINDOWS_INSTALL_OUTCOME_CONFLICT);
        return;
    }
    if (source_install_gate_holds_input(s)) return;
    if (GetFocus() != s->hwnd) return;
    CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, s->ownedTextSessionNodeId);
    if (!node || node->node.resourceId != s->ownedTextSessionResourceId ||
        node->node.nodeKind != s->ownedTextSessionNodeKind ||
        windows_validate_active_text(s, s->ownedTextSessionNodeId,
            s->ownedTextSessionResourceId, s->ownedTextSessionNodeKind,
            s->sceneVersion, node->value ? node->value : "", NULL) != CJGUI_INTERNAL_RENDERER_OK)
        return;
    if (s->compositionState == WINDOWS_COMPOSITION_IDLE) {
        if (!begin_windows_composition(s)) return;
        s->pendingImeSuccessorDeliveryCompositionId = s->activeCompositionId;
    } else if (s->compositionState != WINDOWS_COMPOSITION_MARKED ||
        s->pendingImeSuccessorDeliveryCompositionId == 0u ||
        s->pendingImeSuccessorDeliveryCompositionId != s->activeCompositionId ||
        s->compositionBindingEpoch != s->pendingImeSuccessorBindingEpoch ||
        s->compositionNodeId != s->pendingImeSuccessorNodeId ||
        s->compositionResourceId != s->pendingImeSuccessorResourceId ||
        s->compositionNodeKind != s->pendingImeSuccessorNodeKind) {
        return;
    }
    /* Only this retained delivery may reopen its pressure gate. Do not queue
       a cancel or begin another composition to retry the failed update. */
    if (s->compositionGate == WINDOWS_COMPOSITION_GATE_RECOVERING)
        s->compositionGate = WINDOWS_COMPOSITION_GATE_OPEN;
    if (!queue_windows_composition_update(s, s->pendingImeSuccessorUtf8,
        s->pendingImeSuccessorBytes, s->pendingImeSuccessorCursor16)) {
        return;
    }
    clear_pending_ime_successor(s);
}

static CjguiInternalRendererStatus focus_composable_node_impl(
    uint64_t token, uint64_t nodeId) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, nodeId);
    if (!node) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    if (node->node.isReadOnly || !node->node.isInteractive ||
        (node->node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT &&
         node->node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT &&
         node->node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT &&
         node->node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT))
        return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
    CjguiInternalRendererStatus copyStatus = CJGUI_INTERNAL_RENDERER_OK;
    uint8_t *next = (uint8_t *)copy_valid_utf8(node->value ? node->value : "",
        CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY, NULL, &copyStatus);
    if (!next) return copyStatus;
    uint32_t length16 = 0u;
    if (!windows_utf16_length((const char *)next, &length16)) { free(next); return CJGUI_INTERNAL_RENDERER_INVALID_UTF8; }
    free(s->proxyValueUtf8);
    s->proxyValueUtf8 = next;
    s->focusedNodeId = nodeId;
    s->focusedResourceId = node->node.resourceId;
    s->focusedNodeKind = node->node.nodeKind;
    s->selectionStart16 = s->selectionEnd16 = length16;
    SetFocus(s->hwnd);
    return GetFocus() == s->hwnd ? CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

static CjguiInternalRendererStatus restore_composable_selection_impl(
    uint64_t token, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
    uint64_t sceneVersion, const char *expectedValue, uint32_t selectionStart,
    uint32_t selectionEnd, uint32_t *outSelectionStart, uint32_t *outSelectionEnd) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outSelectionStart || !outSelectionEnd || !expectedValue || selectionEnd < selectionStart)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outSelectionStart = 0u; *outSelectionEnd = 0u;
    CjguiInternalRendererStatus status = windows_validate_active_text(s, nodeId,
        resourceId, nodeKind, sceneVersion, expectedValue, NULL);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    uint32_t length16 = 0u;
    if (!windows_utf16_length(expectedValue, &length16)) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    if (selectionEnd > length16) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    uint64_t startByte = 0u, endByte = 0u;
    if (!windows_utf8_offset_for_utf16(expectedValue, selectionStart, &startByte) ||
        !windows_utf8_offset_for_utf16(expectedValue, selectionEnd, &endByte))
        return CJGUI_INTERNAL_RENDERER_GRAPHEME_BOUNDARY_INVALID;
    uint64_t length = strlen(expectedValue);
    if (!windows_utf8_grapheme_boundary(expectedValue, length, startByte) ||
        !windows_utf8_grapheme_boundary(expectedValue, length, endByte))
        return CJGUI_INTERNAL_RENDERER_GRAPHEME_BOUNDARY_INVALID;
    s->selectionStart16 = selectionStart; s->selectionEnd16 = selectionEnd;
    *outSelectionStart = selectionStart; *outSelectionEnd = selectionEnd;
    nav_barrier_release(s, 1);
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus install_owned_source_selection_impl(
    uint64_t token, uint64_t nodeId, int64_t resourceId, uint64_t sceneVersion,
    uint64_t bindingEpoch, uint64_t requestId, uint64_t deadlineNs,
    const char *expectedValue, uint32_t selectionStart, uint32_t selectionEnd,
    uint32_t *outSelectionStart, uint32_t *outSelectionEnd, uint8_t *outDeferred) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!expectedValue || !outSelectionStart || !outSelectionEnd || !outDeferred ||
        selectionEnd < selectionStart || !bindingEpoch || !requestId || !deadlineNs)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outSelectionStart = 0u;
    *outSelectionEnd = 0u;
    *outDeferred = 0u;
    windows_trace(s,"install_check",requestId,sceneVersion,nodeId,bindingEpoch,
        s->sourceInstallPending,s->sceneVersion);
    windows_trace(s,"install_gate",s->sourceInstallRequestId,s->sourceInstallBindingEpoch,
        s->ownedTextSessionBindingEpoch,s->ownedTextSessionNodeId,s->ownedTextSessionEnabled,
        (uint64_t)s->ownedTextSessionResourceId);

    // A budget that expired while the owner was preparing its accepted turn
    // does not consume the request or touch focus/selection. The same ticket
    // can be retried by the next owner turn.
    uint64_t now = cjgui_internal_renderer_owner_clock_ns();
    if (now >= deadlineNs) {
        *outDeferred = 1u;
        return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
    }

    if (!s->sourceInstallPending || s->sourceInstallBindingEpoch != bindingEpoch ||
        s->sourceInstallRequestId != requestId || !s->ownedTextSessionEnabled ||
        s->ownedTextSessionBindingEpoch != bindingEpoch ||
        s->ownedTextSessionNodeId != nodeId || s->ownedTextSessionResourceId != resourceId ||
        s->ownedTextSessionNodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT)
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;

    CjguiWindowsSceneNode *node = windows_find_accepted_text(s, nodeId, resourceId,
        CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, sceneVersion, expectedValue);
    if (s->traceEnabled) {
        CjguiWindowsSceneNode *actual=scene_node_by_id(&s->acceptedScene,nodeId);
        windows_trace(s,"install_node",actual?(uint64_t)actual->node.resourceId:UINT64_MAX,
            actual?actual->node.nodeKind:UINT32_MAX,actual && actual->value?strlen(actual->value):0u,
            strlen(expectedValue),actual && actual->value?strcmp(actual->value,expectedValue)==0:0u,
            (uint64_t)resourceId);
    }
    if (!node) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    if (strlen(expectedValue) > 65536u) return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;

    uint32_t length16 = 0u;
    if (!windows_utf16_length(expectedValue, &length16)) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    if (selectionEnd > length16) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    uint64_t startByte = 0u, endByte = 0u;
    if (!windows_utf8_offset_for_utf16(expectedValue, selectionStart, &startByte) ||
        !windows_utf8_offset_for_utf16(expectedValue, selectionEnd, &endByte))
        return CJGUI_INTERNAL_RENDERER_GRAPHEME_BOUNDARY_INVALID;
    uint64_t textBytes = strlen(expectedValue);
    if (!windows_utf8_grapheme_boundary(expectedValue, textBytes, startByte) ||
        !windows_utf8_grapheme_boundary(expectedValue, textBytes, endByte))
        return CJGUI_INTERNAL_RENDERER_GRAPHEME_BOUNDARY_INVALID;

    // A minimized or hidden HWND has no usable keyboard focus. The accepted
    // source and ticket are still valid; preserve them for a later owner turn
    // instead of consuming the stale-source attempt budget.
    if (IsIconic(s->hwnd) || !IsWindowVisible(s->hwnd)) {
        *outDeferred = 1u;
        return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
    }

    // Focus and proxy are part of this atomic installation. Keep the old range
    // and proxy until SetFocus has succeeded and the exact owner-projected
    // node is still live; install the ticket's proxy together with focus and
    // the non-empty range, restoring everything on any mismatch.
    uint32_t oldStart = s->selectionStart16;
    uint32_t oldEnd = s->selectionEnd16;
    uint8_t *nextProxy = NULL;
    {
        CjguiInternalRendererStatus copyStatus = CJGUI_INTERNAL_RENDERER_OK;
        nextProxy = (uint8_t *)copy_valid_utf8(expectedValue,
            CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY, NULL, &copyStatus);
        if (!nextProxy) return copyStatus;
    }
    SetFocus(s->hwnd);
    if (find_session(token) != s || s->sceneVersion != sceneVersion ||
        s->ownedTextSessionBindingEpoch != bindingEpoch ||
        !s->sourceInstallPending || s->sourceInstallRequestId != requestId ||
        strcmp(node->value ? node->value : "", expectedValue) != 0) {
        free(nextProxy);
        s->selectionStart16 = oldStart;
        s->selectionEnd16 = oldEnd;
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }

    if (GetFocus() != s->hwnd) {
        free(nextProxy);
        s->selectionStart16 = oldStart;
        s->selectionEnd16 = oldEnd;
        *outDeferred = 1u;
        return CJGUI_INTERNAL_RENDERER_PRESENT_PENDING;
    }

    free(s->proxyValueUtf8);
    s->proxyValueUtf8 = nextProxy;
    s->focusedNodeId = nodeId;
    s->focusedResourceId = resourceId;
    s->focusedNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    s->selectionStart16 = selectionStart;
    s->selectionEnd16 = selectionEnd;
    *outSelectionStart = selectionStart;
    *outSelectionEnd = selectionEnd;
    // 同票成功安装进入 provisional：门继续约束后续输入直到 owner 显式结算，
    // 新票由 owner 另行下发。outcome 区分 native 安装成功与 owner 最终结论。
    // 票据 nonce 随成功安装签发，owner 须凭票据结算，防取消与成功混同。
    s->sourceInstallProvisional = 1u;
    s->sourceInstallOutcome = CJGUI_WINDOWS_INSTALL_OUTCOME_INSTALLED;
    s->sourceInstallProvisionalNonce = s->sourceInstallNextNonce + 1u;
    if (s->sourceInstallProvisionalNonce == 0u)
        s->sourceInstallProvisionalNonce = 1u;
    s->sourceInstallNextNonce = s->sourceInstallProvisionalNonce;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus read_composable_selection_impl(
    uint64_t token, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
    uint64_t sceneVersion, const char *expectedValue,
    uint32_t *outSelectionStart, uint32_t *outSelectionEnd) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outSelectionStart || !outSelectionEnd) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outSelectionStart = 0u; *outSelectionEnd = 0u;
    CjguiInternalRendererStatus status = windows_validate_active_text(s, nodeId,
        resourceId, nodeKind, sceneVersion, expectedValue, NULL);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    *outSelectionStart = s->selectionStart16; *outSelectionEnd = s->selectionEnd16;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus recover_active_text_proxy_impl(
    uint64_t token, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
    const char *acceptedValue, uint32_t *outSelectionStart, uint32_t *outSelectionEnd) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!acceptedValue || !outSelectionStart || !outSelectionEnd)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outSelectionStart = 0u; *outSelectionEnd = 0u;
    if (s->compositionActive) return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
    // 非活跃目标拒绝且不变：恢复只针对当前焦点文本，不碰他人代理与选区。
    if (s->focusedNodeId != nodeId || s->focusedResourceId != resourceId ||
        s->focusedNodeKind != nodeKind)
        return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, nodeId);
    if (!node || node->node.resourceId != resourceId || node->node.nodeKind != nodeKind ||
        strcmp(node->value ? node->value : "", acceptedValue) != 0)
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    CjguiInternalRendererStatus copyStatus = CJGUI_INTERNAL_RENDERER_OK;
    uint8_t *next = (uint8_t *)copy_valid_utf8(acceptedValue,
        CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY, NULL, &copyStatus);
    if (!next) return copyStatus;
    uint32_t length16 = 0u;
    if (!windows_utf16_length((const char *)next, &length16)) { free(next); return CJGUI_INTERNAL_RENDERER_INVALID_UTF8; }
    free(s->proxyValueUtf8); s->proxyValueUtf8 = next;
    s->selectionStart16 = s->selectionEnd16 = length16;
    *outSelectionStart = length16; *outSelectionEnd = length16;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus reanchor_composition_impl(
    uint64_t token, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
    uint64_t sceneVersion, const char *newBaseText, uint32_t replacementStart16,
    uint32_t replacementLength16, uint32_t *outMechanism, uint32_t *outMarkedStart16,
    uint32_t *outMarkedLength16, uint32_t *outInnerStart16, uint32_t *outInnerEnd16) {
    (void)token; (void)nodeId; (void)resourceId; (void)nodeKind; (void)sceneVersion;
    (void)newBaseText; (void)replacementStart16; (void)replacementLength16;
    if (!outMechanism || !outMarkedStart16 || !outMarkedLength16 || !outInnerStart16 || !outInnerEnd16)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outMechanism = 0u; *outMarkedStart16 = 0u; *outMarkedLength16 = 0u;
    *outInnerStart16 = 0u; *outInnerEnd16 = 0u;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

static CjguiInternalRendererStatus arm_composition_reanchor_impl(
    uint64_t token, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
    const char *baseText, uint32_t replacementStart16, uint32_t replacementLength16) {
    (void)token; (void)nodeId; (void)resourceId; (void)nodeKind;
    (void)baseText; (void)replacementStart16; (void)replacementLength16;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

static CjguiInternalRendererStatus set_composable_owned_text_session_impl(
    uint64_t token, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
    uint64_t bindingEpoch, uint32_t enabled) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (enabled > 1u) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (enabled) {
        if (nodeId == 0u) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        if (bindingEpoch == s->ownedTextSessionBindingEpoch && s->ownedTextSessionEnabled &&
            s->ownedTextSessionNodeId == nodeId &&
            s->ownedTextSessionResourceId == resourceId &&
            s->ownedTextSessionNodeKind == nodeKind)
            return CJGUI_INTERNAL_RENDERER_OK;
        // 与 macOS 同语义：声明只接受并存储，不要求目标已聚焦（焦点在真实输入
        // 路径上另行校验）；旧实现的先决焦点要求会挡住启动期声明。
        if (bindingEpoch < s->ownedTextSessionBindingEpoch)
            return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
        if (s->compositionState == WINDOWS_COMPOSITION_MARKED)
            end_windows_ime_composition(s);
        clear_pending_owned_input(s);
        s->pendingHighSurrogate = 0u;
        s->pendingHighSurrogateBindingEpoch = 0u;
        s->ownedTextSessionEnabled = 1u; s->ownedTextSessionNodeId = nodeId;
        s->ownedTextSessionResourceId = resourceId; s->ownedTextSessionNodeKind = nodeKind;
        s->ownedTextSessionBindingEpoch = bindingEpoch;
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    // 撤回：同代次或更新的声明生效；旧代次撤回不触碰当前绑定。
    if (bindingEpoch < s->ownedTextSessionBindingEpoch)
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    if (s->compositionState == WINDOWS_COMPOSITION_MARKED)
        end_windows_ime_composition(s);
    clear_pending_owned_input(s);
    s->pendingHighSurrogate = 0u;
    s->pendingHighSurrogateBindingEpoch = 0u;
    s->ownedTextSessionEnabled = 0u; s->ownedTextSessionNodeId = 0u;
    s->ownedTextSessionResourceId = -1; s->ownedTextSessionNodeKind = 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus configure_shared_operation_impl(
    uint64_t token, uint32_t visibleRecordCount) {
    (void)visibleRecordCount;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    return owner == CJGUI_INTERNAL_RENDERER_OK ? CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED : owner;
}

static CjguiInternalRendererStatus set_shared_operation_title_impl(
    uint64_t token, uint32_t recordIndex, const char *title) {
    (void)recordIndex; (void)title;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    return owner == CJGUI_INTERNAL_RENDERER_OK ? CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED : owner;
}

static CjguiInternalRendererStatus set_shared_operation_state_impl(
    uint64_t token, const CjguiInternalRendererSharedOperationState *state) {
    (void)state;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    return owner == CJGUI_INTERNAL_RENDERER_OK ? CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED : owner;
}

static CjguiInternalRendererStatus configure_shared_form_impl(
    uint64_t token, uint32_t fieldCount) {
    (void)fieldCount;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    return owner == CJGUI_INTERNAL_RENDERER_OK ? CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED : owner;
}

static CjguiInternalRendererStatus set_shared_collection_row_impl(
    uint64_t token, uint32_t rowIndex, const char *title, uint8_t isSelected,
    uint32_t viewportStart, uint32_t totalRecordCount) {
    (void)rowIndex; (void)title; (void)isSelected; (void)viewportStart; (void)totalRecordCount;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    return owner == CJGUI_INTERNAL_RENDERER_OK ? CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED : owner;
}

static CjguiInternalRendererStatus set_shared_form_field_impl(
    uint64_t token, uint32_t fieldIndex, const char *label, const char *draftText,
    const char *validationError, uint32_t editorKind, uint8_t isFocused,
    uint32_t selectionStart, uint32_t selectionEnd) {
    (void)fieldIndex; (void)label; (void)draftText; (void)validationError;
    (void)editorKind; (void)isFocused; (void)selectionStart; (void)selectionEnd;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    return owner == CJGUI_INTERNAL_RENDERER_OK ? CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED : owner;
}

static CjguiInternalRendererStatus set_shared_form_status_impl(
    uint64_t token, const char *statusText) {
    (void)statusText;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    return owner == CJGUI_INTERNAL_RENDERER_OK ? CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED : owner;
}

static CjguiInternalRendererStatus present_clear_impl(uint64_t token,
    const CjguiInternalRendererClearColor *color,
    CjguiInternalRendererFrameObservation *outObservation) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s || !color || !outObservation) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    memset(outObservation, 0, sizeof(*outObservation));
    int32_t status = present_clear_color(s, color->red, color->green, color->blue, color->alpha);
    if (status == CJGUI_INTERNAL_RENDERER_OK) {
        outObservation->frameIndex = s->frameIndex;
        outObservation->drawableWidthPixels = s->width;
        outObservation->drawableHeightPixels = s->height;
        outObservation->contentsScale = (double)(s->dpi ? s->dpi : 96) / 96.0;
    }
    return status;
}

/* Windows private text-measure tickets. A candidate owns the consumer;
   the system callback owns execution. No HWND, session or GPU object crosses
   into the worker. A slot and its reservation retire only after both leave. */
#define CJGUI_WINDOWS_ASYNC_MEASURE_SLOTS 4u
#define CJGUI_WINDOWS_ASYNC_MEASURE_MAX_BYTES 131072u
#define CJGUI_WINDOWS_ASYNC_MEASURE_RESERVED_BYTES 262144u

typedef struct CjguiWindowsAsyncMeasureJob {
    uint64_t handle;
    char *text;
    size_t bytes;
    double fontSize;
    uint32_t fontWeight, fontFamily, width, slot;
    uint8_t textMetrics, consumerLive, completed;
    int32_t status, failure;
    CjguiInternalRendererTextMeasurement metrics;
} CjguiWindowsAsyncMeasureJob;
static SRWLOCK g_windowsAsyncMeasureLock=SRWLOCK_INIT;
static CjguiWindowsAsyncMeasureJob *g_windowsAsyncMeasureJobs[CJGUI_WINDOWS_ASYNC_MEASURE_SLOTS];
static uint64_t g_windowsAsyncMeasureNextHandle=1u;
static size_t g_windowsAsyncMeasureReservedBytes=0u;
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
static HANDLE g_windowsAsyncMeasureTestGate=NULL;
static volatile LONG g_windowsAsyncMeasureTestAtGate=0;
static DWORD g_windowsAsyncMeasureTestWorkerTid=0;
#endif

static CjguiWindowsAsyncMeasureJob *windows_async_measure_find(uint64_t handle) {
    if (!handle) return NULL;
    for (uint32_t i=0;i<CJGUI_WINDOWS_ASYNC_MEASURE_SLOTS;i++) {
        CjguiWindowsAsyncMeasureJob *j=g_windowsAsyncMeasureJobs[i];
        if (j && j->handle==handle) return j;
    }
    return NULL;
}
static void windows_async_measure_retire_locked(CjguiWindowsAsyncMeasureJob *j) {
    g_windowsAsyncMeasureJobs[j->slot]=NULL;
    g_windowsAsyncMeasureReservedBytes-=j->bytes;
    free(j->text);free(j);
}
static void CALLBACK windows_async_measure_worker(PTP_CALLBACK_INSTANCE instance,void *raw) {
    (void)instance;
    CjguiWindowsAsyncMeasureJob *j=(CjguiWindowsAsyncMeasureJob *)raw;
#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
    g_windowsAsyncMeasureTestWorkerTid=GetCurrentThreadId();
    if (g_windowsAsyncMeasureTestGate) {
        InterlockedIncrement(&g_windowsAsyncMeasureTestAtGate);
        WaitForSingleObject(g_windowsAsyncMeasureTestGate,INFINITE);
        InterlockedDecrement(&g_windowsAsyncMeasureTestAtGate);
    }
#endif
    AcquireSRWLockExclusive(&g_windowsAsyncMeasureLock);
    uint8_t live=j->consumerLive;
    ReleaseSRWLockExclusive(&g_windowsAsyncMeasureLock);
    int32_t failure=CJGUI_INTERNAL_RENDERER_OK;
    CjguiInternalRendererTextMeasurement result={0};
    if (live) {
        HRESULT com=CoInitializeEx(NULL,COINIT_MULTITHREADED);
        IDWriteFactory *factory=NULL;IDWriteTextLayout *layout=NULL;
        DWRITE_TEXT_METRICS metrics={0};HRESULT hr=S_OK;
        if (FAILED(com)) failure=CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        if (failure==CJGUI_INTERNAL_RENDERER_OK) {
            hr=DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED,&IID_IDWriteFactory,(IUnknown **)&factory);
            if (FAILED(hr)||!factory) failure=CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        }
        if (failure==CJGUI_INTERNAL_RENDERER_OK) failure=create_measured_text_layout_for_factory(
            factory,&hr,j->text,j->fontSize,j->fontWeight,j->fontFamily,
            j->width?(FLOAT)j->width:100000.0f,100000.0f,&layout,&metrics,NULL);
        if (failure==CJGUI_INTERNAL_RENDERER_OK) {
            double width=ceil((double)metrics.widthIncludingTrailingWhitespace),height=ceil((double)metrics.height);
            if (!isfinite(width)||!isfinite(height)||width<0||height<0||width>UINT32_MAX||height>UINT32_MAX||(!j->textMetrics&&height>1000000.0)||metrics.lineCount>65536u)
                failure=CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
            else {
                result.width=(uint32_t)width;result.height=(uint32_t)height;
                if (j->textMetrics) {
                    UINT32 count=metrics.lineCount,actual=0;
                    DWRITE_LINE_METRICS *lines=count?(DWRITE_LINE_METRICS *)calloc(count,sizeof(*lines)):NULL;
                    HRESULT lineHr=count&&!lines?E_OUTOFMEMORY:IDWriteTextLayout_GetLineMetrics(layout,lines,count,&actual);
                    if (FAILED(lineHr)) failure=CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
                    else if (actual) {result.lineHeight=(uint32_t)ceil(lines[0].height);result.baseline=(uint32_t)ceil(lines[0].baseline);}
                    free(lines);
                }
            }
        }
        if (layout) IDWriteTextLayout_Release(layout);
        if (factory) IDWriteFactory_Release(factory);
        if (SUCCEEDED(com)) CoUninitialize();
    }
    AcquireSRWLockExclusive(&g_windowsAsyncMeasureLock);
    j->metrics=result;j->failure=failure;j->completed=1;
    j->status=!j->consumerLive?5:failure==CJGUI_INTERNAL_RENDERER_OK?3:4;
    if (!j->consumerLive) windows_async_measure_retire_locked(j);
    ReleaseSRWLockExclusive(&g_windowsAsyncMeasureLock);
    /* No access to the ticket after the completed/retired publication. */
}
static int32_t windows_async_measure_begin(const char *text,uint64_t byteLength,
    double fontSize,uint32_t fontWeight,uint32_t fontFamily,uint32_t width,
    uint8_t textMetrics,uint64_t *outHandle) {
    if (outHandle) *outHandle=0;
    if (!outHandle||!text||byteLength>CJGUI_WINDOWS_ASYNC_MEASURE_MAX_BYTES||
        !isfinite(fontSize)||fontSize<=0||fontSize>512||fontFamily>3||
        !(fontWeight==0||fontWeight==1||(fontWeight>=100&&fontWeight<=900&&fontWeight%100==0))||
        (!textMetrics&&!width)||strnlen(text,(size_t)byteLength+1u)!=byteLength) return 7;
    if (byteLength && MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,text,(int)byteLength,NULL,0)<=0) return 7;
    AcquireSRWLockExclusive(&g_windowsAsyncMeasureLock);
    uint32_t slot=0;while(slot<CJGUI_WINDOWS_ASYNC_MEASURE_SLOTS&&g_windowsAsyncMeasureJobs[slot]) slot++;
    if (slot==CJGUI_WINDOWS_ASYNC_MEASURE_SLOTS||byteLength>CJGUI_WINDOWS_ASYNC_MEASURE_RESERVED_BYTES-g_windowsAsyncMeasureReservedBytes) {
        ReleaseSRWLockExclusive(&g_windowsAsyncMeasureLock);return 1;
    }
    if (!g_windowsAsyncMeasureNextHandle) {ReleaseSRWLockExclusive(&g_windowsAsyncMeasureLock);return 4;}
    CjguiWindowsAsyncMeasureJob *j=(CjguiWindowsAsyncMeasureJob *)calloc(1,sizeof(*j));
    if (!j) {ReleaseSRWLockExclusive(&g_windowsAsyncMeasureLock);return 4;}
    j->text=(char *)malloc((size_t)byteLength+1u);
    if (!j->text) {free(j);ReleaseSRWLockExclusive(&g_windowsAsyncMeasureLock);return 4;}
    memcpy(j->text,text,(size_t)byteLength);j->text[byteLength]=0;
    j->bytes=(size_t)byteLength;j->handle=g_windowsAsyncMeasureNextHandle++;j->slot=slot;
    j->fontSize=fontSize;j->fontWeight=fontWeight;j->fontFamily=fontFamily;j->width=width;
    j->textMetrics=textMetrics;j->consumerLive=1;j->status=2;
    g_windowsAsyncMeasureJobs[slot]=j;g_windowsAsyncMeasureReservedBytes+=j->bytes;
    uint64_t handle=j->handle;
    /* Keep admission locked until submission returns; an early callback cannot
       retire this ticket before begin publishes the copied scalar handle. */
    if (!TrySubmitThreadpoolCallback(windows_async_measure_worker,j,NULL)) {
        windows_async_measure_retire_locked(j);ReleaseSRWLockExclusive(&g_windowsAsyncMeasureLock);return 4;
    }
    *outHandle=handle;ReleaseSRWLockExclusive(&g_windowsAsyncMeasureLock);return 0;
}
int32_t cjgui_async_composable_multiline_begin(const char *text,uint64_t byteLength,
    double fontSize,uint32_t fontWeight,uint32_t fontFamily,uint32_t contentWidth,uint64_t *outHandle) {
    return windows_async_measure_begin(text,byteLength,fontSize,fontWeight,fontFamily,contentWidth,0,outHandle);
}
int32_t cjgui_async_composable_text_metrics_begin(const char *text,uint64_t byteLength,
    double fontSize,uint32_t fontWeight,uint32_t fontFamily,uint32_t maximumWidth,uint64_t *outHandle) {
    return windows_async_measure_begin(text,byteLength,fontSize,fontWeight,fontFamily,maximumWidth,1,outHandle);
}
int32_t CjguiAsyncMultilineMeasurePoll(uint64_t handle,uint32_t *outHeight,int32_t *outFailure) {
    if (!outHeight||!outFailure) return 7;
    *outHeight=0;*outFailure=0;
    AcquireSRWLockShared(&g_windowsAsyncMeasureLock);
    CjguiWindowsAsyncMeasureJob *j=windows_async_measure_find(handle);
    int32_t status=!j||!j->consumerLive?6:j->textMetrics?7:j->status;
    if (status==3) *outHeight=j->metrics.height;
    if (status==4) *outFailure=j->failure;
    ReleaseSRWLockShared(&g_windowsAsyncMeasureLock);return status;
}
int32_t CjguiAsyncTextMetricsPoll(uint64_t handle,CjguiInternalRendererTextMeasurement *outMetrics,int32_t *outFailure) {
    if (!outMetrics||!outFailure) return 7;
    memset(outMetrics,0,sizeof(*outMetrics));*outFailure=0;
    AcquireSRWLockShared(&g_windowsAsyncMeasureLock);
    CjguiWindowsAsyncMeasureJob *j=windows_async_measure_find(handle);
    int32_t status=!j||!j->consumerLive?6:!j->textMetrics?7:j->status;
    if (status==3) *outMetrics=j->metrics;
    if (status==4) *outFailure=j->failure;
    ReleaseSRWLockShared(&g_windowsAsyncMeasureLock);return status;
}
int32_t CjguiAsyncMultilineMeasureRelease(uint64_t handle,int32_t disposition) {
    if (disposition!=0&&disposition!=1) return 7;
    AcquireSRWLockExclusive(&g_windowsAsyncMeasureLock);
    CjguiWindowsAsyncMeasureJob *j=windows_async_measure_find(handle);
    if (!j||!j->consumerLive) {ReleaseSRWLockExclusive(&g_windowsAsyncMeasureLock);return 6;}
    if (disposition==0&&(!j->completed||j->status!=3)) {
        ReleaseSRWLockExclusive(&g_windowsAsyncMeasureLock);return 7;
    }
    j->consumerLive=0;
    if (j->completed) windows_async_measure_retire_locked(j);
    ReleaseSRWLockExclusive(&g_windowsAsyncMeasureLock);return 0;
}

// ---- 正常产品链 Windows 平台服务补全（2026-10-06，20 个链接缺口） ----
// 三态纪律：进入产品链必经场景发布的“声明/准备”类 API 在 Windows 被接受并做
// 与 macOS 相同口径的有界校验（否则候选场景会被整体拒绝）；未在写作链中实现
// 的平台特性（OS 菜单栏投影、系统剪贴板/拖放、原生 context-menu 守卫、共享集合
// 表单）保留具名缺口；指针取消与几何诊断直接使用本文件已有的真实会话状态。

static CjguiInternalRendererStatus cancel_composable_pointer_capture_impl(
    uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (s->mouseCaptureActive || s->mousePressActive) windows_cancel_mouse_gesture(s);
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus cancel_composable_pointer_capture_epoch_impl(
    uint64_t token, uint64_t gestureEpoch) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (gestureEpoch == 0u) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (s->mouseGestureEpoch != gestureEpoch) return CJGUI_INTERNAL_RENDERER_OK;
    if (s->mouseCaptureActive || s->mousePressActive) windows_cancel_mouse_gesture(s);
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus configure_composable_command_menu_impl(
    uint64_t token, uint64_t projectionVersion, uint32_t itemCount) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (projectionVersion == 0u || itemCount > 128u)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    s->commandMenuProjectionVersion = projectionVersion;
    s->commandMenuPendingCount = itemCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus set_composable_command_menu_item_impl(
    uint64_t token, uint32_t itemIndex, const char *commandId, const char *title,
    const char *menuGroup, const char *shortcut, uint32_t menuSection, uint64_t focusScope,
    uint8_t enabled, uint8_t checked) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!commandId || !title || !menuGroup || !shortcut) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (itemIndex >= s->commandMenuPendingCount) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (strlen(commandId) == 0u || strlen(commandId) > 256u || strlen(title) > 1024u ||
        strlen(menuGroup) > 256u || strlen(shortcut) > 64u || enabled > 1u || checked > 1u)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    // 声明语义与 macOS 相同（校验后接受）；Windows 暂不投影到系统菜单栏，
    // 快捷键/命令调用沿用仓颉侧声明，此处不保存第二份业务真相。
    (void)menuSection;
    (void)focusScope;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus commit_composable_command_menu_impl(
    uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    s->commandMenuAcceptedCount = s->commandMenuPendingCount;
    s->commandMenuPendingCount = 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus configure_composable_data_transfer_impl(
    uint64_t token, uint64_t projectionVersion, uint32_t itemCount) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (projectionVersion == 0u || itemCount > 256u)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    s->dataTransferProjectionVersion = projectionVersion;
    s->dataTransferPendingCount = itemCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus set_composable_data_transfer_item_impl(
    uint64_t token, uint32_t itemIndex, const CjguiInternalRendererComposableDataTransferItem *item,
    const char *format, const char *payload, const char *sourceKind, const char *sourceIdentity) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!item || !format || !payload || !sourceKind || !sourceIdentity)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (itemIndex >= s->dataTransferPendingCount) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (strlen(format) == 0u || strlen(format) > 64u || strlen(payload) > 524288u ||
        strlen(sourceKind) > 64u || strlen(sourceIdentity) > 256u)
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    // 与 macOS 相同口径校验后接受；Windows 尚未接入系统剪贴板/拖放事件。
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus set_composable_data_transfer_item_bytes_impl(
    uint64_t token, uint32_t itemIndex, const uint8_t *bytes, uint32_t length) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!bytes || length == 0u || length > 524288u) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (itemIndex >= s->dataTransferPendingCount) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    return CJGUI_INTERNAL_RENDERER_OK;
}

uint64_t cjgui_internal_renderer_data_transfer_event_delivery_ordinal(uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) return 0u;
    return 0u; // 未接入系统剪贴板/拖放：无待决数据转移事件。
}

int64_t cjgui_internal_renderer_data_transfer_event_source_id(uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) return -1;
    return -1;
}

const char *cjgui_internal_renderer_data_transfer_event_source_kind(uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) return "";
    return "";
}

const char *cjgui_internal_renderer_data_transfer_event_source_identity(uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) return "";
    return "";
}

uint8_t cjgui_internal_renderer_has_unkeyed_application_exit_request(void) {
    // Windows 的退出来自显式窗口关闭，不存在 macOS “无键窗口标准 Quit”语义。
    return 0u;
}

static uint32_t gApplicationExitLifecycleOwners = 0u;

void cjgui_internal_renderer_retain_application_exit_lifecycle_owner(void) {
    if (gApplicationExitLifecycleOwners != UINT32_MAX) ++gApplicationExitLifecycleOwners;
}

void cjgui_internal_renderer_release_application_exit_lifecycle_owner(void) {
    if (gApplicationExitLifecycleOwners > 0u) --gApplicationExitLifecycleOwners;
}

void cjgui_internal_renderer_complete_application_exit_request(void) {
    // 无待决无键退出请求可清；保留符号与 macOS 相同语义。
}

static CjguiInternalRendererStatus composable_display_progress_impl(
    uint64_t token, CjguiInternalRendererComposableDisplayProgress *outProgress) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outProgress) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    memset(outProgress, 0, sizeof(*outProgress));
    outProgress->submittedFrameIndex = s->frameIndex;
    outProgress->submittedSceneVersion = s->sceneVersion;
    outProgress->currentPointWidth = (double)s->width * 96.0 / (double)(s->dpi ? s->dpi : 96u);
    outProgress->currentPointHeight = (double)s->height * 96.0 / (double)(s->dpi ? s->dpi : 96u);
    outProgress->currentBackingScale = (double)(s->dpi ? s->dpi : 96u) / 96.0;
    outProgress->currentDrawableWidthPixels = s->width;
    outProgress->currentDrawableHeightPixels = s->height;
    outProgress->currentGeometryRevision = s->resizeVersion;
    outProgress->submittedPointWidth = outProgress->currentPointWidth;
    outProgress->submittedPointHeight = outProgress->currentPointHeight;
    outProgress->submittedBackingScale = outProgress->currentBackingScale;
    outProgress->submittedDrawableWidthPixels = s->width;
    outProgress->submittedDrawableHeightPixels = s->height;
    outProgress->submittedGeometryRevision = s->resizeVersion;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus set_composable_context_menu_guard_impl(
    uint64_t token, uint64_t sceneVersion, uint64_t layerScope, uint64_t requestId,
    uint64_t layerNodeId, int64_t resourceId, uint32_t nodeKind, int64_t x, int64_t y,
    int64_t width, int64_t height, uint32_t enabled) {
    (void)sceneVersion; (void)layerScope; (void)requestId; (void)layerNodeId; (void)resourceId;
    (void)nodeKind; (void)x; (void)y; (void)width; (void)height; (void)enabled;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    // 具名缺口：Windows 尚未实现原生 context-menu 外部点击守卫；仓颉侧
    // 按设计在失败时结束该次右键请求（native_guard_install_failed），不误报已安装。
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

static CjguiInternalRendererStatus configure_shared_collection_form_impl(
    uint64_t token, uint32_t fieldCount, uint32_t visibleRecordCount) {
    (void)fieldCount; (void)visibleRecordCount;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

static CjguiInternalRendererStatus set_shared_collection_filter_impl(
    uint64_t token, const char *filterText) {
    (void)filterText;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_test_hold_next_composable_present(
    uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    // 内部测试缝：Windows 正常侧车不编译测试门，明确拒绝而非伪装已挂起。
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

// ---- 链接缺口收尾（第 2 轮：3 个漏网符号） ----

static CjguiInternalRendererStatus cancel_composable_pointer_capture_gesture_key_impl(
    uint64_t token, uint64_t appInstance, uint64_t componentInstance,
    uint64_t surfaceGeneration, int64_t pointerId, uint64_t gestureEpoch) {
    (void)appInstance; (void)componentInstance; (void)surfaceGeneration;
    (void)pointerId; (void)gestureEpoch;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    // OHOS 全键变体：与 macOS 相同口径，本后端不适用该键控取消。
    return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

int64_t cjgui_internal_renderer_data_transfer_event_expected_owner_version(uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) return -1;
    return -1; // 未接入系统剪贴板/拖放：无待决数据转移的期望版本。
}

CjguiInternalRendererStatus cjgui_internal_renderer_test_resolve_pending_composable_present(
    uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    // 内部测试缝：正常侧车不含测试门，明确拒绝而非伪装已解决挂起。
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

/* 诊断观测：最近一次 pump 调用实际执行的 OS 线程 id。
   供 A/B 线程反例判定“同一 session 是否恒由同一 UI 线程执行”。
   完整 dispatcher 落地后，此值应恒等于泵线程 id；当前实现随调用线程变化。 */
uint32_t cjgui_internal_renderer_debug_last_pump_tid(uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) return 0u;
    return (uint32_t)s->lastPumpTid;
}

/* 诊断观测：私有准备图与有界退休的真实计数/字节。只读标量，不改变任何状态，
   供反例判定“取消后是否真实回收、容量不足是否具名保旧”。 */
#define CJGUI_WINDOWS_PREP_DEBUG_ACTIVE 0u
#define CJGUI_WINDOWS_PREP_DEBUG_READY 1u
#define CJGUI_WINDOWS_PREP_DEBUG_NODES 2u
#define CJGUI_WINDOWS_PREP_DEBUG_PREPARED 3u
#define CJGUI_WINDOWS_PREP_DEBUG_STAGED 4u
#define CJGUI_WINDOWS_PREP_DEBUG_LIVE_BYTES 5u
#define CJGUI_WINDOWS_PREP_DEBUG_RETIRING 6u
#define CJGUI_WINDOWS_PREP_DEBUG_RETIRED_NODES 7u
#define CJGUI_WINDOWS_PREP_DEBUG_RETIRED_BYTES 8u
#define CJGUI_WINDOWS_PREP_DEBUG_UNITS 9u
#define CJGUI_WINDOWS_PREP_DEBUG_DEADLINE_HITS 10u
#define CJGUI_WINDOWS_PREP_DEBUG_STALE 11u
#define CJGUI_WINDOWS_PREP_DEBUG_BUDGET_REFUSALS 12u
#define CJGUI_WINDOWS_PREP_DEBUG_CANCELS 13u
#define CJGUI_WINDOWS_PREP_DEBUG_COPIED 14u
#define CJGUI_WINDOWS_PREP_DEBUG_RETIRED_GRAPHS 15u
/* 票身份记账（16 起，只增不改旧编号）：取消把 active 字段归零，之后每一行都只能
   按这张票回答“资源到底什么时候真正释放了”。16..24 是最近一次退休/回收的票事实
   （就地释放分支没有槽位也写这份事实），25 是当前队首退休槽的票，队列为空读 0。 */
#define CJGUI_WINDOWS_PREP_DEBUG_LAST_TICKET 16u
#define CJGUI_WINDOWS_PREP_DEBUG_LAST_CANCEL_NS 17u
#define CJGUI_WINDOWS_PREP_DEBUG_LAST_RETIRED_NS 18u
#define CJGUI_WINDOWS_PREP_DEBUG_LAST_RECLAIM_NS 19u
#define CJGUI_WINDOWS_PREP_DEBUG_LAST_RELEASED_NODES 20u
#define CJGUI_WINDOWS_PREP_DEBUG_LAST_RELEASED_BYTES 21u
#define CJGUI_WINDOWS_PREP_DEBUG_LAST_GRAPH_NODES 22u
#define CJGUI_WINDOWS_PREP_DEBUG_LAST_GRAPH_BYTES 23u
#define CJGUI_WINDOWS_PREP_DEBUG_RETIRE_ACCOUNTING_ERRORS 24u
#define CJGUI_WINDOWS_PREP_DEBUG_RETIRING_HEAD_TICKET 25u
uint64_t cjgui_internal_renderer_debug_preparation_scalar(uint64_t token, uint32_t field) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) return 0u;
    switch (field) {
    case CJGUI_WINDOWS_PREP_DEBUG_ACTIVE: return s->preparationActive ? 1u : 0u;
    case CJGUI_WINDOWS_PREP_DEBUG_READY: return s->preparationReady ? 1u : 0u;
    case CJGUI_WINDOWS_PREP_DEBUG_NODES: return (uint64_t)s->preparationNodeCount;
    case CJGUI_WINDOWS_PREP_DEBUG_PREPARED: return (uint64_t)s->preparationPreparedCount;
    case CJGUI_WINDOWS_PREP_DEBUG_STAGED: return (uint64_t)s->preparationStagedCount;
    case CJGUI_WINDOWS_PREP_DEBUG_LIVE_BYTES: return s->preparationLiveBytes;
    case CJGUI_WINDOWS_PREP_DEBUG_RETIRING: return (uint64_t)s->preparationRetiringCount;
    case CJGUI_WINDOWS_PREP_DEBUG_RETIRED_NODES: return s->preparationRetiredNodeCount;
    case CJGUI_WINDOWS_PREP_DEBUG_RETIRED_BYTES: return s->preparationRetiredBytes;
    case CJGUI_WINDOWS_PREP_DEBUG_UNITS: return s->preparationUnitCount;
    case CJGUI_WINDOWS_PREP_DEBUG_DEADLINE_HITS: return s->preparationDeadlineHits;
    case CJGUI_WINDOWS_PREP_DEBUG_STALE: return s->preparationStaleCount;
    case CJGUI_WINDOWS_PREP_DEBUG_BUDGET_REFUSALS: return s->preparationBudgetRefusals;
    case CJGUI_WINDOWS_PREP_DEBUG_CANCELS: return s->preparationCancelCount;
    case CJGUI_WINDOWS_PREP_DEBUG_COPIED: return s->preparationCopiedCount;
    case CJGUI_WINDOWS_PREP_DEBUG_RETIRED_GRAPHS: return s->preparationRetiredGraphCount;
    /* 票身份与真实回收时刻：取消从这里开始 active 票号就是 0，反例不能拿归零后的
       active 字段回答“这张票回收完了没有”，只能读最近一次退休/回收的票与队首槽。 */
    case CJGUI_WINDOWS_PREP_DEBUG_LAST_TICKET: return s->preparationLastTicket;
    case CJGUI_WINDOWS_PREP_DEBUG_LAST_CANCEL_NS: return s->preparationLastCancelNs;
    case CJGUI_WINDOWS_PREP_DEBUG_LAST_RETIRED_NS: return s->preparationLastRetiredNs;
    case CJGUI_WINDOWS_PREP_DEBUG_LAST_RECLAIM_NS: return s->preparationLastReclaimNs;
    case CJGUI_WINDOWS_PREP_DEBUG_LAST_RELEASED_NODES: return s->preparationLastReleasedNodes;
    case CJGUI_WINDOWS_PREP_DEBUG_LAST_RELEASED_BYTES: return s->preparationLastReleasedBytes;
    case CJGUI_WINDOWS_PREP_DEBUG_LAST_GRAPH_NODES: return s->preparationLastGraphNodes;
    case CJGUI_WINDOWS_PREP_DEBUG_LAST_GRAPH_BYTES: return s->preparationLastGraphBytes;
    case CJGUI_WINDOWS_PREP_DEBUG_RETIRE_ACCOUNTING_ERRORS:
        return s->preparationRetireAccountingErrors;
    case CJGUI_WINDOWS_PREP_DEBUG_RETIRING_HEAD_TICKET:
        return s->preparationRetiringCount > 0u ? s->preparationRetiring[0].preparationId : 0u;
    default: return 0u;
    }
}

#ifdef CJGUI_WINDOWS_SCENE_CONTRACT_TEST
static DWORD g_testDestroyExecTid = 0u;

DWORD cjgui_windows_test_destroy_exec_tid(void) {
    return g_testDestroyExecTid;
}

typedef struct CjguiWindowsTestSleepCtx {
    uint64_t token;
    uint32_t sleepMs;
} CjguiWindowsTestSleepCtx;

static CjguiInternalRendererStatus cjgui_windows_test_sleep_proc(
    CjguiWindowsRendererSession *s, void *raw) {
    (void)s;
    CjguiWindowsTestSleepCtx *c = (CjguiWindowsTestSleepCtx *)raw;
    Sleep(c->sleepMs);
    return CJGUI_INTERNAL_RENDERER_OK;
}

uint64_t cjgui_windows_test_sleep_command(uint64_t token, uint32_t sleepMs) {
    CjguiWindowsTestSleepCtx *ctx =
        (CjguiWindowsTestSleepCtx *)calloc(1u, sizeof(CjguiWindowsTestSleepCtx));
    if (!ctx) return 0u;
    ctx->token = token;
    ctx->sleepMs = sleepMs;
    uint64_t cmdId = 0u;
    CjguiInternalRendererStatus st = windows_dispatch_sync(token, "test_sleep",
        CJGUI_WINDOWS_CMD_GENERIC, cjgui_windows_test_sleep_proc, ctx,
        cjgui_windows_free_ctx, 5000u, &cmdId);
    if (st == CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT) return cmdId;
    if (st != CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT) free(ctx);
    return 0u;
}
#endif

uint32_t cjgui_internal_renderer_debug_source_install_state(uint64_t token,
    uint32_t *outProvisional, uint32_t *outOutcome) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) return 0u;
    if (outProvisional) *outProvisional = s->sourceInstallProvisional;
    if (outOutcome) *outOutcome = s->sourceInstallOutcome;
    return s->sourceInstallPending;
}
