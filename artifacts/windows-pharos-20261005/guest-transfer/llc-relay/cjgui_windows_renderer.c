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
#define CJGUI_WINDOWS_TEXT_FLIGHT_LEASE_CAPACITY (CJGUI_WINDOWS_SCENE_NODE_CAPACITY * 2u)
#define CJGUI_WINDOWS_TEXT_FLIGHT_HASH_CAPACITY 4096u
#define CJGUI_WINDOWS_TEXT_RUN_CAPACITY 1024u
#define CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY (1024u * 1024u)
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
} CjguiWindowsTextTextureLease;

typedef struct CjguiWindowsTextFlight {
    ID3D11Query *query;
    CjguiWindowsTextTextureLease *leases[CJGUI_WINDOWS_TEXT_FLIGHT_LEASE_CAPACITY];
    uint32_t leaseCount;
    uint8_t pending;
    uint8_t recording;
} CjguiWindowsTextFlight;

typedef struct CjguiWindowsSceneNode {
    CjguiInternalRendererComposableNode node;
    CjguiInternalRendererComposableGeometry geometry;
    char *label;
    char *value;
    char *imageResourcePath;
    char *imageResourceId;
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
    uint64_t textDpi;
    uint64_t layoutLease;
    uint64_t textMaskNonzeroPixels;
    uint64_t ownedBytes;
    uint8_t hasNode;
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
} CjguiWindowsRawRecord;

/* UI dispatcher 命令环：C ABI 入口把会话逻辑封送到 UI 线程执行。
   命令在入队后至多执行一次；调用者在 doneEvent 上等待完成。
   started 由 UI 线程置位；cancelled 仅在未开始前由入队侧置位。 */
#define CJGUI_WINDOWS_CMD_RING_CAPACITY 64u

typedef enum CjguiWindowsCommandKind {
    CJGUI_WINDOWS_CMD_PUMP = 1,
    CJGUI_WINDOWS_CMD_DESTROY = 2
} CjguiWindowsCommandKind;

typedef struct CjguiWindowsCommand {
    uint32_t kind;
    uint64_t token;
    uint64_t generation;
    uint32_t timeoutMs;
    int hasIdleOut;
    CjguiInternalRendererEvent outEvent;
    uint64_t outIdleNs;
    CjguiInternalRendererStatus status;
    HANDLE doneEvent;
    int started;
    int done;
    int cancelled;
} CjguiWindowsCommand;

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
    HANDLE rawWakeEvent;
    CRITICAL_SECTION cmdLock;
    CjguiWindowsCommand *cmdRing[CJGUI_WINDOWS_CMD_RING_CAPACITY];
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
    uint32_t diagnosticTimingEnabled;
    uint32_t compositionActive;
    uint32_t closeRequested;
    uint32_t minimized;
    uint32_t sourceInstallPending;
    uint64_t sourceInstallBindingEpoch;
    uint64_t sourceInstallRequestId;
    uint64_t sourceInstallGatedInputs;
    uint32_t sourceInstallProvisional;
    uint32_t sourceInstallOutcome;
#define CJGUI_WINDOWS_INSTALL_OUTCOME_NONE 0u
#define CJGUI_WINDOWS_INSTALL_OUTCOME_INSTALLED 1u
#define CJGUI_WINDOWS_INSTALL_OUTCOME_OWNER_CONFIRMED 2u
#define CJGUI_WINDOWS_INSTALL_OUTCOME_OWNER_CANCELLED 3u
#define CJGUI_WINDOWS_INSTALL_OUTCOME_SUPERSEDED 4u
#define CJGUI_WINDOWS_INSTALL_OUTCOME_CONFLICT 5u
#define CJGUI_WINDOWS_INSTALL_OUTCOME_CLOSED 6u
    uint32_t navBarrierArmed;
    uint32_t navReplayActive;
#define CJGUI_WINDOWS_NAV_HOLD_CAPACITY 16u
#define CJGUI_WINDOWS_NAV_HOLD_BYTES 65536u
    struct {
        uint32_t isDelete;
        char *bytes;
        uint32_t length;
        int64_t modifiers;
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
    uint64_t lastPumpedSessionGeneration;
    uint64_t focusedNodeId;
    int64_t focusedResourceId;
    uint32_t focusedNodeKind;
    uint32_t selectionStart16;
    uint32_t selectionEnd16;
    uint8_t *proxyValueUtf8;
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
    uint32_t compositionGate;
    uint32_t compositionTerminalPhase;
    char *compositionBaseUtf8;
    char *compositionExpectedOwnerUtf8;
    char *pendingImeSuccessorUtf8;
    uint32_t pendingImeSuccessorCursor16;
    uint32_t pendingImeSuccessorPresent;
    uint32_t pendingImeSuccessorReady;
    char *pendingPngTransferIdentity;
    uint32_t pendingPngTransferCount;
    uint64_t presentationTicketNext;
    uint64_t presentationAcceptedCount;
    uint64_t presentationRejectedCount;
    uint64_t presentationQueryCount;
    uint64_t presentationAckCount;
    uint64_t preparationId;
    uint64_t preparationProjectionVersion;
    uint64_t backgroundProjectionVersion;
    uint32_t backgroundMode;
    uint32_t backgroundColorScheme;
    CjguiWindowsScene candidateScene;
    CjguiWindowsScene acceptedScene;
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
    uint64_t mouseCoordinateEpoch;
    uint64_t mouseLayoutLease;
    uint64_t mouseNextGestureEpoch;
    double mouseLastX;
    double mouseLastY;
    CjguiInternalRendererComposableNode mouseFrozenNode;
    CjguiInternalRendererComposableGeometry mouseFrozenGeometry;
    char *mouseFrozenValue;
    char *formEventText;
    HRESULT lastGraphicsFailure;
    uint32_t occupied;
};

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
static CjguiInternalRendererStatus marshal_pump_command(uint64_t token, uint32_t timeoutMs,
    CjguiInternalRendererEvent *outEvent, uint64_t *outIdleWaitNs, int hasIdleOut);
static CjguiInternalRendererStatus marshal_destroy_command(uint64_t token);

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
        CjguiWindowsTextTextureLease *leases[2] = {
            scene->nodes[i].textLease, scene->nodes[i].labelTextLease};
        for (uint32_t which = 0; which < 2u; ++which) {
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
    const WCHAR *text, uint32_t units);
static int handle_windows_key_down(CjguiWindowsRendererSession *s, WPARAM key,
    int64_t frozenModifiers);
static int64_t windows_keyboard_modifiers(void);
static int handle_windows_ime_composition(CjguiWindowsRendererSession *s, LPARAM flags);
static void end_windows_ime_composition(CjguiWindowsRendererSession *s);
static void clear_pending_owned_input(CjguiWindowsRendererSession *s);
static void range_disarm(CjguiWindowsRendererSession *s);
static void nav_barrier_release(CjguiWindowsRendererSession *s, int replay);
static int nav_intent_is_movement(const char *intent);
static int nav_intent_is_delete(const char *intent);
static int nav_barrier_hold_char(CjguiWindowsRendererSession *s,
    const char *insert, uint32_t insertLength);
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

static int windows_mouse_geometry_still_matches(const CjguiWindowsRendererSession *s,
    const CjguiWindowsSceneNode *entry) {
    if (!s || !entry || !entry->hasNode || !entry->hasGeometry || !s->mouseFrozenValue ||
        entry->node.nodeId != s->mouseNodeId || entry->node.resourceId != s->mouseResourceId ||
        entry->node.nodeKind != s->mouseNodeKind ||
        entry->node.isInteractive != s->mouseFrozenNode.isInteractive ||
        entry->node.isReadOnly != s->mouseFrozenNode.isReadOnly ||
        entry->node.acceptedBindingEpoch != s->mouseFrozenNode.acceptedBindingEpoch ||
        entry->node.x != s->mouseFrozenNode.x || entry->node.y != s->mouseFrozenNode.y ||
        entry->node.width != s->mouseFrozenNode.width || entry->node.height != s->mouseFrozenNode.height ||
        entry->node.cornerRadius != s->mouseFrozenNode.cornerRadius ||
        entry->node.clipX != s->mouseFrozenNode.clipX || entry->node.clipY != s->mouseFrozenNode.clipY ||
        entry->node.clipWidth != s->mouseFrozenNode.clipWidth || entry->node.clipHeight != s->mouseFrozenNode.clipHeight ||
        entry->node.clipCornerRadius != s->mouseFrozenNode.clipCornerRadius ||
        entry->node.clipConstraintCount != s->mouseFrozenNode.clipConstraintCount ||
        entry->node.clip0X != s->mouseFrozenNode.clip0X || entry->node.clip0Y != s->mouseFrozenNode.clip0Y ||
        entry->node.clip0Width != s->mouseFrozenNode.clip0Width ||
        entry->node.clip0Height != s->mouseFrozenNode.clip0Height ||
        entry->node.clip0CornerRadius != s->mouseFrozenNode.clip0CornerRadius ||
        entry->node.clip1X != s->mouseFrozenNode.clip1X || entry->node.clip1Y != s->mouseFrozenNode.clip1Y ||
        entry->node.clip1Width != s->mouseFrozenNode.clip1Width ||
        entry->node.clip1Height != s->mouseFrozenNode.clip1Height ||
        entry->node.clip1CornerRadius != s->mouseFrozenNode.clip1CornerRadius ||
        entry->node.clip2X != s->mouseFrozenNode.clip2X || entry->node.clip2Y != s->mouseFrozenNode.clip2Y ||
        entry->node.clip2Width != s->mouseFrozenNode.clip2Width ||
        entry->node.clip2Height != s->mouseFrozenNode.clip2Height ||
        entry->node.clip2CornerRadius != s->mouseFrozenNode.clip2CornerRadius ||
        entry->node.clip3X != s->mouseFrozenNode.clip3X || entry->node.clip3Y != s->mouseFrozenNode.clip3Y ||
        entry->node.clip3Width != s->mouseFrozenNode.clip3Width ||
        entry->node.clip3Height != s->mouseFrozenNode.clip3Height ||
        entry->node.clip3CornerRadius != s->mouseFrozenNode.clip3CornerRadius ||
        entry->layoutLease != s->mouseLayoutLease || strcmp(entry->value ? entry->value : "", s->mouseFrozenValue) != 0 ||
        entry->geometry.translateX != s->mouseFrozenGeometry.translateX ||
        entry->geometry.translateY != s->mouseFrozenGeometry.translateY ||
        entry->geometry.clip0X != s->mouseFrozenGeometry.clip0X ||
        entry->geometry.clip0Y != s->mouseFrozenGeometry.clip0Y ||
        entry->geometry.clip1X != s->mouseFrozenGeometry.clip1X ||
        entry->geometry.clip1Y != s->mouseFrozenGeometry.clip1Y ||
        entry->geometry.clip2X != s->mouseFrozenGeometry.clip2X ||
        entry->geometry.clip2Y != s->mouseFrozenGeometry.clip2Y ||
        entry->geometry.clip3X != s->mouseFrozenGeometry.clip3X ||
        entry->geometry.clip3Y != s->mouseFrozenGeometry.clip3Y ||
        entry->geometry.clipCount != s->mouseFrozenGeometry.clipCount)
        return 0;
    return 1;
}

static CjguiWindowsSceneNode *windows_current_mouse_target(CjguiWindowsRendererSession *s,
    uint32_t *outIndex) {
    if (outIndex) *outIndex = UINT32_MAX;
    if (!s || !s->mouseNodeId || s->mouseCoordinateEpoch != s->coordinateEpoch) return NULL;
    uint32_t index = UINT32_MAX;
    CjguiWindowsSceneNode *entry = scene_node_by_id(&s->acceptedScene, s->mouseNodeId);
    if (!entry || !windows_mouse_geometry_still_matches(s, entry)) return NULL;
    if (s->mouseProjectionVersion != s->acceptedScene.version) {
        s->mouseProjectionVersion = s->acceptedScene.version;
    }
    for (uint32_t i = 0; i < s->acceptedScene.count; ++i)
        if (&s->acceptedScene.nodes[i] == entry) { index = i; break; }
    if (index == UINT32_MAX) return NULL;
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
    uint32_t index = UINT32_MAX;
    CjguiWindowsSceneNode *entry = windows_current_mouse_target(s, &index);
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
    if (!s || (!s->mouseCaptureActive && !s->mouseSelectionActive && !s->mousePressActive)) return;
    double scale = (double)(s->dpi ? s->dpi : 96u) / 96.0;
    double x = (double)GET_X_LPARAM(lParam) / scale;
    double y = (double)GET_Y_LPARAM(lParam) / scale;
    s->mouseLastX = x; s->mouseLastY = y;
    uint32_t index = UINT32_MAX;
    CjguiWindowsSceneNode *entry = windows_current_mouse_target(s, &index);
    if (!entry) { windows_cancel_mouse_gesture(s); return; }
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

/* UI 线程专用：把一条原始输入追加到 raw 环。只触碰环索引与唤醒事件；
   不读写真正的会话状态，不做 user32 同步调用。 */
static void raw_ring_push(CjguiWindowsRendererSession *s, uint32_t message,
    uint64_t wParam, int64_t lParam, int64_t modifiers) {
    if (!s) return;
    EnterCriticalSection(&s->rawLock);
    uint32_t next = (s->rawHead + 1u) % CJGUI_WINDOWS_RAW_RING_CAPACITY;
    if (next != s->rawTail) {
        s->rawRing[s->rawHead].message = message;
        s->rawRing[s->rawHead].wParam = wParam;
        s->rawRing[s->rawHead].lParam = lParam;
        s->rawRing[s->rawHead].modifiers = modifiers;
        s->rawHead = next;
        SetEvent(s->rawWakeEvent);
    } else {
        s->rawDropped += 1u;
    }
    LeaveCriticalSection(&s->rawLock);
}

/* 驱动线程专用：取一条原始输入；空返回 0。 */
static int raw_ring_pop(CjguiWindowsRendererSession *s, uint32_t *message,
    uint64_t *wParam, int64_t *lParam, int64_t *modifiers) {
    int got = 0;
    EnterCriticalSection(&s->rawLock);
    if (s->rawHead != s->rawTail) {
        if (message) *message = s->rawRing[s->rawTail].message;
        if (wParam) *wParam = s->rawRing[s->rawTail].wParam;
        if (lParam) *lParam = s->rawRing[s->rawTail].lParam;
        if (modifiers) *modifiers = s->rawRing[s->rawTail].modifiers;
        s->rawTail = (s->rawTail + 1u) % CJGUI_WINDOWS_RAW_RING_CAPACITY;
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
    switch (message) {
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
        case WM_IME_COMPOSITION:
            /* 只记录原始输入；修饰键在到达时刻冻结，随记录搬运，
               消费侧不再读取“当前”键盘状态。 */
            raw_ring_push(s, (uint32_t)message, (uint64_t)wParam, (int64_t)lParam,
                windows_keyboard_modifiers());
            if (message == WM_IME_STARTCOMPOSITION || message == WM_IME_ENDCOMPOSITION ||
                message == WM_KILLFOCUS) {
                return DefWindowProcW(hwnd, message, wParam, lParam);
            }
            return 0;
        case WM_SYSKEYDOWN:
        case WM_SYSKEYUP:
            /* 裸 ALT（上下文位=0，即无其他键同时按下）会让 DefWindowProc 进入
               系统菜单模式：其嵌套模态消息循环会卡住 owner 泵（实测：测试脚本
               向前台应用发送 ALT 解锁键后，应用回合停止推进、探针缝不再执行）。
               消费裸 ALT 的按下与抬起；带键组合（如 Alt+F4）仍走默认处理。 */
            if (wParam == VK_MENU && (lParam & (1 << 29)) == 0) return 0;
            break;
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
    uint64_t wParam, int64_t lParam, int64_t frozenModifiers) {
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
            if (width && height && resizeStatus == CJGUI_INTERNAL_RENDERER_OK) {
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
            (void)handle_windows_text_character(s, &unit, 1u);
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
            (void)handle_windows_text_character(s, units, count);
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
                (void)handle_windows_ime_composition(s, (LPARAM)lParam);
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
        DestroyWindow(s->hwnd);
        s->hwnd = NULL;
        release_graphics(s);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    hr = DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, &IID_IDWriteFactory,
        (IUnknown **)&s->writeFactory);
    if (FAILED(hr) || !s->writeFactory) {
        s->lastGraphicsFailure = hr;
        DestroyWindow(s->hwnd);
        s->hwnd = NULL;
        release_graphics(s);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    s->width = clientWidth;
    s->height = clientHeight;
    CjguiInternalRendererStatus status = create_render_target(s);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        DestroyWindow(s->hwnd);
        s->hwnd = NULL;
        release_graphics(s);
        return status;
    }
    status = create_scene_pipeline(s);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        DestroyWindow(s->hwnd);
        s->hwnd = NULL;
        release_graphics(s);
        return status;
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
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    s->frameIndex += 1;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus create_measured_text_layout(
    CjguiWindowsRendererSession *s, const char *utf8, double fontSize,
    uint32_t fontWeight, uint32_t fontFamily, float maxWidth, float maxHeight,
    IDWriteTextLayout **outLayout, DWRITE_TEXT_METRICS *outMetrics) {
    if (!(fontWeight == 0u || fontWeight == 1u ||
          (fontWeight >= 100u && fontWeight <= 900u && fontWeight % 100u == 0u)) ||
        fontFamily > 3u) return CJGUI_INTERNAL_RENDERER_STYLE_RUN_INVALID;
    if (!s || !s->writeFactory || !utf8 || !outLayout || !outMetrics ||
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
    DWRITE_FONT_STYLE style = fontFamily >= 2u ? DWRITE_FONT_STYLE_ITALIC : DWRITE_FONT_STYLE_NORMAL;
    uint32_t weightValue = fontWeight == 0u ? 400u : fontWeight == 1u ? 700u : fontWeight;
    IDWriteTextFormat *format = NULL;
    IDWriteTextLayout *layout = NULL;
    HRESULT hr = IDWriteFactory_CreateTextFormat(s->writeFactory, family, NULL,
        (DWRITE_FONT_WEIGHT)weightValue, style,
        DWRITE_FONT_STRETCH_NORMAL, (FLOAT)fontSize, L"en-us", &format);
    if (SUCCEEDED(hr)) hr = IDWriteTextFormat_SetWordWrapping(format, DWRITE_WORD_WRAPPING_WRAP);
    if (SUCCEEDED(hr)) hr = IDWriteFactory_CreateTextLayout(s->writeFactory, wide,
        (UINT32)wideCount, format, maxWidth, maxHeight, &layout);
    if (SUCCEEDED(hr)) hr = IDWriteTextLayout_GetMetrics(layout, outMetrics);
    free(wide);
    if (format) IDWriteTextFormat_Release(format);
    if (FAILED(hr) || !layout) {
        if (layout) IDWriteTextLayout_Release(layout);
        s->lastGraphicsFailure = hr;
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    s->textLayoutPreparationCount += 1u;
    *outLayout = layout;
    return CJGUI_INTERNAL_RENDERER_OK;
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
                text_renderer_fill_rectangle(renderer, metrics[rect].left, metrics[rect].top,
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
    double logicalWidth, double logicalHeight, int applyRuns,
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
        ? IDWriteTextLayout_Draw(layout, NULL, (IDWriteTextRenderer *)&renderer, 0.0f, 0.0f) : E_FAIL;
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
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint64_t maskNonzero = 0u;
    for (uint64_t i = 0; i < pixels; ++i)
        if (rgba[i * 4u + 3u] != 0u) ++maskNonzero;
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
    out->node = source->node;
    out->geometry = source->geometry;
    out->textTextureWidth = source->textTextureWidth;
    out->textTextureHeight = source->textTextureHeight;
    out->labelTextureWidth = source->labelTextureWidth;
    out->labelTextureHeight = source->labelTextureHeight;
    out->textLogicalOffsetX = source->textLogicalOffsetX;
    out->textLogicalWidth = source->textLogicalWidth;
    out->labelLogicalWidth = source->labelLogicalWidth;
    out->textDpi = source->textDpi;
    out->layoutLease = source->layoutLease;
    out->textMaskNonzeroPixels = source->textMaskNonzeroPixels;
    out->hasNode = source->hasNode;
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

static CjguiInternalRendererStatus prepare_scene_node_text(CjguiWindowsRendererSession *s,
    CjguiWindowsScene *scene, uint32_t nodeIndex, CjguiWindowsSceneNode *node) {
    if (!windows_text_node_kind(node->node.nodeKind)) return CJGUI_INTERNAL_RENDERER_OK;
    CjguiInternalRendererStatus flightStatus = reap_text_flights(s);
    if (flightStatus != CJGUI_INTERNAL_RENDERER_OK) return flightStatus;
    double nodeWidth = (double)node->node.width;
    double nodeHeight = (double)node->node.height;
    double fontSize = node->node.fontSize > 0.0 ? node->node.fontSize : 14.0;
    const int editable = node->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT ||
        node->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT ||
        node->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT ||
        node->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    const char *bodyText = node->value ? node->value : "";
    if (node->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON &&
        node->label && node->label[0]) bodyText = node->label;

    IDWriteTextLayout *newLabelLayout = NULL;
    IDWriteTextLayout *newBodyLayout = NULL;
    CjguiWindowsTextTextureLease *newLabelLease = NULL;
    CjguiWindowsTextTextureLease *newBodyLease = NULL;
    uint32_t newLabelWidth = 0u, newLabelHeight = 0u;
    uint32_t newBodyWidth = 0u, newBodyHeight = 0u;
    uint64_t newLabelInk = 0u, newBodyInk = 0u;
    double labelBoxWidth = 0.0, bodyOffsetX = 0.0, bodyBoxWidth = nodeWidth;
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_OK;
    DWRITE_TEXT_METRICS labelMetrics; memset(&labelMetrics, 0, sizeof(labelMetrics));
    DWRITE_TEXT_METRICS bodyMetrics; memset(&bodyMetrics, 0, sizeof(bodyMetrics));

    if (editable && node->label && node->label[0]) {
        float labelConstraint = (FLOAT)fmax(1.0, fmin(nodeWidth * 0.5, nodeWidth - 1.0));
        status = create_measured_text_layout(s, node->label, fontSize,
            node->node.fontWeight, node->node.fontFamily, labelConstraint,
            (FLOAT)nodeHeight, &newLabelLayout, &labelMetrics);
        if (status != CJGUI_INTERNAL_RENDERER_OK) goto failed;
        labelBoxWidth = fmin((double)labelConstraint,
            fmax(0.0, (double)labelMetrics.widthIncludingTrailingWhitespace));
        if (labelBoxWidth <= 0.0) labelBoxWidth = fmin((double)labelConstraint, fontSize * 0.5);
        bodyOffsetX = fmin(nodeWidth, labelBoxWidth + 8.0);
        bodyBoxWidth = fmax(1.0, nodeWidth - bodyOffsetX);
    }
    status = create_styled_text_layout(s, node, bodyText, (FLOAT)bodyBoxWidth,
        (FLOAT)nodeHeight, &newBodyLayout, &bodyMetrics);
    if (status != CJGUI_INTERNAL_RENDERER_OK) goto failed;

    uint64_t labelBytes = 0u, bodyBytes = 0u;
    if (newLabelLayout && node->label[0] &&
        !text_texture_bytes_for_box(s, labelBoxWidth, nodeHeight, &labelBytes)) {
        status = CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
        goto failed;
    }
    if (bodyText[0] && !text_texture_bytes_for_box(s, bodyBoxWidth, nodeHeight, &bodyBytes)) {
        status = CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
        goto failed;
    }
    uint64_t otherSceneBytes = scene_unique_text_texture_bytes(scene, nodeIndex);
    if (otherSceneBytes > CJGUI_WINDOWS_TEXT_SCENE_TEXTURE_CAPACITY ||
        labelBytes > CJGUI_WINDOWS_TEXT_SCENE_TEXTURE_CAPACITY - otherSceneBytes ||
        bodyBytes > CJGUI_WINDOWS_TEXT_SCENE_TEXTURE_CAPACITY - otherSceneBytes - labelBytes) {
        status = CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
        goto failed;
    }

    if (newLabelLayout && node->label[0]) {
        status = rasterize_text_layout(s, node, node->label, newLabelLayout, labelBoxWidth, nodeHeight, 0,
            &newLabelLease, &newLabelWidth, &newLabelHeight, &newLabelInk);
        if (status != CJGUI_INTERNAL_RENDERER_OK) goto failed;
    }
    if (bodyText[0]) {
        status = rasterize_text_layout(s, node, bodyText, newBodyLayout, bodyBoxWidth, nodeHeight, 1,
            &newBodyLease, &newBodyWidth, &newBodyHeight, &newBodyInk);
        if (status != CJGUI_INTERNAL_RENDERER_OK) goto failed;
    }

    if (node->textLayout) IDWriteTextLayout_Release(node->textLayout);
    if (node->labelTextLayout) IDWriteTextLayout_Release(node->labelTextLayout);
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
    node->textLayout = newBodyLayout;
    node->labelTextLayout = newLabelLayout;
    node->textLease = newBodyLease;
    node->labelTextLease = newLabelLease;
    node->textTexture = newBodyLease ? newBodyLease->texture : NULL;
    node->textView = newBodyLease ? newBodyLease->view : NULL;
    node->labelTextTexture = newLabelLease ? newLabelLease->texture : NULL;
    node->labelTextView = newLabelLease ? newLabelLease->view : NULL;
    node->textTextureWidth = newBodyWidth;
    node->textTextureHeight = newBodyHeight;
    node->labelTextureWidth = newLabelWidth;
    node->labelTextureHeight = newLabelHeight;
    node->textLogicalOffsetX = bodyOffsetX;
    node->textLogicalWidth = bodyBoxWidth;
    node->labelLogicalWidth = labelBoxWidth;
    node->textDpi = s->dpi;
    node->layoutLease = next_text_layout_lease(s);
    node->textMaskNonzeroPixels = newBodyInk + newLabelInk;
    return CJGUI_INTERNAL_RENDERER_OK;

failed:
    if (newLabelLayout) IDWriteTextLayout_Release(newLabelLayout);
    if (newBodyLayout) IDWriteTextLayout_Release(newBodyLayout);
    if (newLabelLease) release_text_texture_lease(&newLabelLease);
    if (newBodyLease) release_text_texture_lease(&newBodyLease);
    return status;
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
        next.ownedBytes += next.nodes[i].ownedBytes;
    }
    release_scene(&s->candidateScene);
    s->candidateScene = next;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_begin_composable_preparation(
    uint64_t token, uint64_t preparationId, uint64_t baseSceneVersion,
    uint64_t projectionVersion, uint32_t nodeCount) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!preparationId || !projectionVersion || !nodeCount ||
        nodeCount > CJGUI_WINDOWS_SCENE_NODE_CAPACITY ||
        (s->acceptedScene.configured && baseSceneVersion != s->acceptedScene.version))
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    s->preparationId = preparationId;
    s->preparationProjectionVersion = projectionVersion;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_prepare_composable_node(
    uint64_t token, uint64_t preparationId, uint32_t index,
    const CjguiInternalRendererComposableNode *node,
    const CjguiInternalRendererComposableGeometry *geometry,
    const char *label, const char *value, const char *semanticId,
    const char *bindingKey, const char *rowKey, const char *parentRowKey,
    const char *semanticLabel, const char *encodedRuns) {
    (void)index; (void)node; (void)geometry; (void)label; (void)value;
    (void)semanticId; (void)bindingKey; (void)rowKey; (void)parentRowKey;
    (void)semanticLabel; (void)encodedRuns;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    return s->preparationId == preparationId
        ? CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED : CJGUI_INTERNAL_RENDERER_SCENE_STALE;
}

CjguiInternalRendererStatus cjgui_internal_renderer_advance_composable_preparation(
    uint64_t token, uint64_t preparationId, uint64_t deadlineNs, uint32_t *outReady) {
    (void)deadlineNs;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outReady) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outReady = 0u;
    return s->preparationId == preparationId
        ? CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED : CJGUI_INTERNAL_RENDERER_SCENE_STALE;
}

CjguiInternalRendererStatus cjgui_internal_renderer_promote_composable_preparation(
    uint64_t token, uint64_t preparationId) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    return s->preparationId == preparationId
        ? CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED : CJGUI_INTERNAL_RENDERER_SCENE_STALE;
}

CjguiInternalRendererStatus cjgui_internal_renderer_cancel_composable_preparation(
    uint64_t token, uint64_t preparationId) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (s->preparationId != preparationId) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    s->preparationId = 0u;
    s->preparationProjectionVersion = 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_configure_composable_scene(
    uint64_t token, uint64_t projectionVersion, uint32_t nodeCount) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    return scene_configure(s, projectionVersion, nodeCount);
}

CjguiInternalRendererStatus cjgui_internal_renderer_discard_composable_scene_candidate(
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

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_scene_geometry(
    uint64_t token, uint64_t projectionVersion, uint32_t nodeIndex,
    const CjguiInternalRendererComposableGeometry *geometry) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    return set_scene_geometry(s, projectionVersion, nodeIndex, geometry);
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_scene_node(
    uint64_t token, uint32_t nodeIndex, const CjguiInternalRendererComposableNode *node,
    const char *label, const char *value, const char *imageResourcePath,
    const char *imageResourceId, uint64_t imageResourceVersion) {
    (void)imageResourceVersion;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!s->candidateScene.configured || nodeIndex >= s->candidateScene.count)
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    CjguiInternalRendererStatus status = validate_composable_node(node, s->candidateScene.version);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        return status;
    }
    if (node->nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE) {
        return CJGUI_INTERNAL_RENDERER_PNG_UNSUPPORTED;
    }
    CjguiWindowsSceneNode next;
    memset(&next, 0, sizeof(next));
    CjguiWindowsTextRunDeclaration *declaration = text_runs_by_id(s, node->nodeId);
    status = copy_node_strings(&next, node, label, value, imageResourcePath,
        imageResourceId, declaration ? declaration->encoded : "");
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        release_scene_node(&next);
        return status;
    }
    if (next.ownedBytes > CJGUI_WINDOWS_TEXT_BYTE_CAPACITY -
        (s->candidateScene.ownedBytes - s->candidateScene.nodes[nodeIndex].ownedBytes)) {
        release_scene_node(&next);
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    }
    status = prepare_scene_node_text(s, &s->candidateScene, nodeIndex, &next);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        release_scene_node(&next);
        return status;
    }
    uint64_t oldOwnedBytes = s->candidateScene.nodes[nodeIndex].ownedBytes;
    release_scene_node(&s->candidateScene.nodes[nodeIndex]);
    s->candidateScene.ownedBytes -= oldOwnedBytes;
    s->candidateScene.nodes[nodeIndex] = next;
    s->candidateScene.ownedBytes += next.ownedBytes;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_scene_node_bytes(
    uint64_t token, uint32_t nodeIndex, const CjguiInternalRendererComposableNode *node,
    const char *label, const char *value, const char *imageResourcePath,
    const char *imageResourceId, uint64_t imageResourceVersion,
    const uint8_t *bytes, uint32_t length) {
    (void)nodeIndex; (void)node; (void)label; (void)value; (void)imageResourcePath;
    (void)imageResourceId; (void)imageResourceVersion; (void)bytes; (void)length;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    return CJGUI_INTERNAL_RENDERER_PNG_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_node_semantic_identity(
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
    if (length > CJGUI_WINDOWS_TEXT_BYTE_CAPACITY -
        (s->candidateScene.ownedBytes - strlen(target->semanticId ? target->semanticId : ""))) {
        free(copy);
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    }
    s->candidateScene.ownedBytes -= strlen(target->semanticId ? target->semanticId : "");
    target->ownedBytes -= strlen(target->semanticId ? target->semanticId : "");
    free(target->semanticId);
    target->semanticId = copy;
    target->ownedBytes += length;
    s->candidateScene.ownedBytes += length;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_node_semantic_metadata(
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
    for (size_t i = 0; i < 4u; ++i) { free(*fields[i]); *fields[i] = copies[i]; }
    target->ownedBytes = target->ownedBytes - oldBytes + newBytes;
    s->candidateScene.ownedBytes = s->candidateScene.ownedBytes - oldBytes + newBytes;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_text_runs(
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
    status = parse_style_run_list(copy, candidate ? candidate->value : NULL,
        &validatedRuns, &validatedCount);
    free(validatedRuns);
    if (status != CJGUI_INTERNAL_RENDERER_OK) { free(copy); return status; }
    char *candidateCopy = NULL;
    CjguiWindowsSceneNode next;
    memset(&next, 0, sizeof(next));
    uint32_t candidateIndex = 0u;
    uint64_t old = 0u;
    if (candidate) {
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
    if (candidate) {
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
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_stage_window_background(
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

CjguiInternalRendererStatus cjgui_internal_renderer_window_background_snapshot(
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

CjguiInternalRendererStatus cjgui_internal_renderer_composable_viewport(
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

CjguiInternalRendererStatus cjgui_internal_renderer_present_ticket_stats(
    uint64_t token, CjguiInternalRendererPresentTicketStats *outStats) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outStats) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    memset(outStats, 0, sizeof(*outStats));
    outStats->nextTicketId = 1;
    outStats->queryCount = (int64_t)s->presentationQueryCount;
    outStats->ackCount = (int64_t)s->presentationAckCount;
    outStats->available = 1u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_acknowledge_present(
    uint64_t token, uint64_t ticketId) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (ticketId == 0u) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ++s->presentationAckCount;
    return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
}

CjguiInternalRendererStatus cjgui_internal_renderer_present_composable_scene(
    uint64_t token, CjguiInternalRendererFrameObservation *outObservation) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outObservation || !s->candidateScene.configured)
        return CJGUI_INTERNAL_RENDERER_SCENE_NOT_STAGED;
    memset(outObservation, 0, sizeof(*outObservation));
    for (uint32_t i = 0; i < s->candidateScene.count; ++i) {
        CjguiWindowsSceneNode *node = &s->candidateScene.nodes[i];
        if (!node->hasNode || !node->hasGeometry ||
            node->node.projectionVersion != s->candidateScene.version ||
            node->geometry.nodeId != node->node.nodeId ||
            node->geometry.clipCount != node->node.clipConstraintCount)
            return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
        if (windows_text_node_kind(node->node.nodeKind) &&
            (!node->textLayout || node->textDpi != s->dpi))
            return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    if (!s->sceneVertexShader || !s->sceneInputLayout || !s->renderTarget)
        return CJGUI_INTERNAL_RENDERER_METAL_LAYER_UNAVAILABLE;
    CjguiWindowsTextFlight *flight = NULL;
    CjguiInternalRendererStatus status = begin_text_flight(s, &s->candidateScene, &flight);
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
    for (uint32_t i = 0; i < s->candidateScene.count && status == CJGUI_INTERNAL_RENDERER_OK; ++i) {
        CjguiWindowsSceneNode *entry = &s->candidateScene.nodes[i];
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
        if (status == CJGUI_INTERNAL_RENDERER_OK && entry->labelTextView &&
            node->textAlpha > 0.0 && entry->labelTextureWidth && entry->labelTextureHeight) {
            FLOAT ink[4] = {1.0f, 1.0f, 1.0f, opacity};
            status = draw_scene_quad(s, x, y, (FLOAT)entry->labelLogicalWidth * scale,
                height, ink, entry->labelTextView);
        }
        if (status == CJGUI_INTERNAL_RENDERER_OK && entry->textView &&
            node->textAlpha > 0.0 && entry->textTextureWidth && entry->textTextureHeight) {
            FLOAT ink[4] = {1.0f, 1.0f, 1.0f, opacity};
            status = draw_scene_quad(s, x + (FLOAT)entry->textLogicalOffsetX * scale, y,
                (FLOAT)entry->textLogicalWidth * scale, height, ink, entry->textView);
        }
    }
    end_text_flight(s, flight);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    if (s->frameIndex == 0u) {
        uint64_t nonClearPixels = 0u, darkPixels = 0u;
        status = readback_scene_pixel_counts(s, &nonClearPixels, &darkPixels);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
        s->sceneReadbackNonClearPixelCount = nonClearPixels;
        s->sceneReadbackDarkPixelCount = darkPixels;
    }
    HRESULT hr = IDXGISwapChain_Present(s->swapChain, 1, 0);
    if (FAILED(hr)) {
        s->lastGraphicsFailure = hr;
        ++s->presentationRejectedCount;
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    release_scene(&s->acceptedScene);
    s->acceptedScene = s->candidateScene;
    memset(&s->candidateScene, 0, sizeof(s->candidateScene));
    s->sceneVersion = s->acceptedScene.version;
    ++s->frameIndex;
    ++s->presentationAcceptedCount;
    synchronize_owned_proxy_after_presentation(s);
    finish_windows_composition_after_presentation(s);
    outObservation->frameIndex = s->frameIndex;
    outObservation->drawableWidthPixels = s->width;
    outObservation->drawableHeightPixels = s->height;
    outObservation->contentsScale = scale;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_prepare_composable_image_resource(
    uint64_t token, const char *resourcePath, const char *resourceId,
    uint64_t resourceVersion, uint32_t *outState) {
    (void)resourcePath; (void)resourceId; (void)resourceVersion;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outState) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outState = 3u;
    return CJGUI_INTERNAL_RENDERER_PNG_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_composable_image_resource_state(
    uint64_t token, const char *resourcePath, const char *resourceId,
    uint64_t resourceVersion, uint32_t *outState) {
    (void)resourcePath; (void)resourceId; (void)resourceVersion;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outState) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outState = 3u;
    return CJGUI_INTERNAL_RENDERER_PNG_UNSUPPORTED;
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
        while (raw_ring_pop(s, &message, &wParam, &lParam, &frozenModifiers)) {
            dispatch_raw_message(s, message, wParam, lParam, frozenModifiers);
        }
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
            while (raw_ring_pop(s, &message, &wParam, &lParam, &deadlineFrozen)) {
                dispatch_raw_message(s, message, wParam, lParam, deadlineFrozen);
            }
            popped = pop_event(s, outEvent);
            if (popped == CJGUI_INTERNAL_RENDERER_OK) return popped;
            return CJGUI_INTERNAL_RENDERER_OK;
        }
        remaining = nextRemaining;
    }
}


CjguiInternalRendererStatus cjgui_internal_renderer_set_source_install_gate(
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
            s->sourceInstallOutcome = CJGUI_WINDOWS_INSTALL_OUTCOME_SUPERSEDED;
        } else {
            s->sourceInstallOutcome = CJGUI_WINDOWS_INSTALL_OUTCOME_NONE;
        }
        s->sourceInstallBindingEpoch = bindingEpoch;
        s->sourceInstallRequestId = requestId;
        s->sourceInstallPending = 1u;
        s->sourceInstallProvisional = 0u;
        nav_barrier_release(s, 1);
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    if (!s->sourceInstallPending) return CJGUI_INTERNAL_RENDERER_OK;
    if (s->sourceInstallBindingEpoch != bindingEpoch || s->sourceInstallRequestId != requestId)
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    s->sourceInstallOutcome = s->sourceInstallProvisional
        ? CJGUI_WINDOWS_INSTALL_OUTCOME_OWNER_CONFIRMED
        : CJGUI_WINDOWS_INSTALL_OUTCOME_OWNER_CANCELLED;
    s->sourceInstallPending = 0u;
    s->sourceInstallBindingEpoch = 0u;
    s->sourceInstallRequestId = 0u;
    s->sourceInstallProvisional = 0u;
    nav_barrier_release(s, 1);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_diagnostic_resources(
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

CjguiInternalRendererStatus cjgui_internal_renderer_diagnostic_timing(
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

CjguiInternalRendererStatus cjgui_internal_renderer_node_rect(uint64_t token,
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
        outRect[1] = (double)node->node.y + node->geometry.translateY + localY;
        outRect[2] = 1.0;
        outRect[3] = hit.height > 0.0f ? hit.height :
            (node->node.fontSize > 0.0 ? node->node.fontSize * 1.25 : 18.0);
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus windows_position_from_point(
    CjguiWindowsRendererSession *s, CjguiWindowsSceneNode *node, uint64_t byteLength,
    uint32_t totalUnits, double sceneX, double sceneY, uint64_t *outMeta, double *outRect) {
    if (!isfinite(sceneX) || !isfinite(sceneY)) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    FLOAT originX = (FLOAT)((double)node->node.x + node->geometry.translateX + node->textLogicalOffsetX);
    FLOAT originY = (FLOAT)((double)node->node.y + node->geometry.translateY);
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

CjguiInternalRendererStatus cjgui_internal_renderer_text_position_v1(
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

CjguiInternalRendererStatus cjgui_internal_renderer_text_position_stats_v1(
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

CjguiInternalRendererStatus cjgui_internal_renderer_text_geometry_caret(
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

CjguiInternalRendererStatus cjgui_internal_renderer_text_visual_neighbor(
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

CjguiInternalRendererStatus cjgui_internal_renderer_query_present(uint64_t token,
    uint64_t ticketId, CjguiInternalRendererPresentReceipt *outReceipt) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outReceipt || ticketId == 0u) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    memset(outReceipt, 0, sizeof(*outReceipt));
    outReceipt->ticketId = ticketId;
    outReceipt->decision = CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_NONE;
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

CjguiInternalRendererStatus cjgui_internal_renderer_measure_composable_multiline_natural_height(
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

CjguiInternalRendererStatus cjgui_internal_renderer_measure_composable_text(
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
    unsigned long long nodeId = 0ull;
    int matchedRect = sscanf(request, "NODE_RECT %llu", &nodeId);
    unsigned long long clickId = 0ull;
    int matchedClick = sscanf(request, "CLICK_NODE %llu", &clickId);
    if (matchedRect != 1 && matchedClick != 1) return;
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
        fprintf(out, "NODE_RECT_RESULT %llu screen=%ld,%ld click=%ld,%ld client_click=%lld,%lld size=%dx%d client=%ldx%ld dpi=%u node_rect=%lld,%lld,%lld,%lld frac=%.6f,%.6f winrect=%ld,%ld,%ld,%ld layout=%.1fx%.1f\n",
            nodeId, (long)center.x, (long)center.y, (long)clickPoint.x, (long)clickPoint.y,
            clientClickX, clientClickY, cw, ch,
            (long)(client.right - client.left), (long)(client.bottom - client.top),
            (unsigned)s->dpi,
            (long long)node->node.x, (long long)node->node.y,
            (long long)node->node.width, (long long)node->node.height,
            layoutWidth > 0.0 ? ((double)node->node.x + (double)node->node.width / 2.0) / layoutWidth : 0.0,
            layoutHeight > 0.0 ? ((double)node->node.y + (double)node->node.height / 2.0) / layoutHeight : 0.0,
            (long)windowRect.left, (long)windowRect.top, (long)windowRect.right, (long)windowRect.bottom,
            layoutWidth, layoutHeight);
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
    if (!outEvent) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    windows_ensure_pump_input_attached(s);
    windows_test_probe_tick(s);
    return marshal_pump_command(token, timeoutMs, outEvent, outIdleWaitNs, 1);
}

CjguiInternalRendererStatus cjgui_internal_renderer_pump_event(
    uint64_t token, uint32_t timeoutMs, CjguiInternalRendererEvent *outEvent) {
    if (!outEvent) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    windows_ensure_pump_input_attached(s);
    windows_test_probe_tick(s);
    return marshal_pump_command(token, timeoutMs, outEvent, NULL, 0);
}

CjguiInternalRendererStatus cjgui_internal_renderer_pumped_pointer_geometry(
    uint64_t token, CjguiInternalRendererPointerEventGeometry *outGeometry) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!outGeometry) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outGeometry = s->lastPointerGeometry;
    memset(&s->lastPointerGeometry, 0, sizeof(s->lastPointerGeometry));
    return CJGUI_INTERNAL_RENDERER_OK;
}

int32_t cjgui_internal_renderer_owner_consumed_pointer_coordinate_lifetime(
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

const char *cjgui_internal_renderer_form_event_text(uint64_t token) {
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

static void destroy_ui_phase_a(CjguiWindowsRendererSession *s) {
    s->retiring = 1;
    EnterCriticalSection(&s->cmdLock);
    for (uint32_t i = s->cmdTail; i != s->cmdHead;
         i = (i + 1u) % CJGUI_WINDOWS_CMD_RING_CAPACITY) {
        CjguiWindowsCommand *queued = s->cmdRing[i % CJGUI_WINDOWS_CMD_RING_CAPACITY];
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
    free(s->pendingImeSuccessorUtf8);
    s->pendingImeSuccessorUtf8 = NULL;
    s->pendingImeSuccessorPresent = 0u;
    s->pendingImeSuccessorReady = 0u;
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
    nav_barrier_release(s, 0);
    release_scene(&s->candidateScene);
    release_scene(&s->acceptedScene);
    for (uint32_t i = 0; i < s->textRunDeclarationCount; ++i)
        free(s->textRunDeclarations[i].encoded);
    release_graphics(s);
    free(s->proxyValueUtf8);
    free(s->pendingPngTransferIdentity);
    for (uint32_t i = 0; i < CJGUI_WINDOWS_EVENT_CAPACITY; ++i)
        free(s->eventTextPayloads[i]);
    free(s->formEventText);
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

static void execute_dispatcher_command(CjguiWindowsRendererSession *s,
    CjguiWindowsCommand *cmd) {
    if (GetCurrentThreadId() != s->pumpThreadId) {
        cmd->status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        cmd->done = 1;
        SetEvent(cmd->doneEvent);
        return;
    }
    if (cmd->cancelled) {
        cmd->status = CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        cmd->done = 1;
        SetEvent(cmd->doneEvent);
        return;
    }
    if (cmd->generation != s->sessionGeneration) {
        cmd->status = CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        cmd->done = 1;
        SetEvent(cmd->doneEvent);
        return;
    }
    cmd->started = 1;
    if (cmd->kind == CJGUI_WINDOWS_CMD_PUMP) {
        uint64_t idleNs = 0u;
        cmd->status = pump_windows_messages(s, cmd->timeoutMs, &cmd->outEvent,
            cmd->hasIdleOut ? &idleNs : NULL);
        if (cmd->hasIdleOut) cmd->outIdleNs = idleNs;
    } else if (cmd->kind == CJGUI_WINDOWS_CMD_DESTROY) {
        if (s->retiring) {
            cmd->status = CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        } else {
            destroy_ui_phase_a(s);
            cmd->status = CJGUI_INTERNAL_RENDERER_OK;
        }
    } else {
        cmd->status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    cmd->done = 1;
    SetEvent(cmd->doneEvent);
}

static void drain_dispatcher_commands(CjguiWindowsRendererSession *s, int skipPumpAndDestroy) {
    for (;;) {
        CjguiWindowsCommand *cmd = NULL;
        EnterCriticalSection(&s->cmdLock);
        if (s->cmdHead != s->cmdTail) {
            CjguiWindowsCommand *front = s->cmdRing[s->cmdTail % CJGUI_WINDOWS_CMD_RING_CAPACITY];
            if (skipPumpAndDestroy && front &&
                (front->kind == CJGUI_WINDOWS_CMD_PUMP || front->kind == CJGUI_WINDOWS_CMD_DESTROY)) {
                LeaveCriticalSection(&s->cmdLock);
                return;
            }
            cmd = front;
            s->cmdTail = (s->cmdTail + 1u) % CJGUI_WINDOWS_CMD_RING_CAPACITY;
        }
        LeaveCriticalSection(&s->cmdLock);
        if (!cmd) return;
        execute_dispatcher_command(s, cmd);
    }
}

static CjguiInternalRendererStatus marshal_pump_command(uint64_t token, uint32_t timeoutMs,
    CjguiInternalRendererEvent *outEvent, uint64_t *outIdleWaitNs, int hasIdleOut) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    uint64_t generation = s->sessionGeneration;
    DWORD uiTid = s->pumpThreadId;
    int running = s->pumpThreadRunning;
    HWND hwnd = s->hwnd;
    if (uiTid != 0u && GetCurrentThreadId() == uiTid) {
        return pump_windows_messages(s, timeoutMs, outEvent,
            hasIdleOut ? outIdleWaitNs : NULL);
    }
    if (!running || uiTid == 0u || !hwnd) {
        if (!s->hwnd) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        return pump_windows_messages(s, timeoutMs, outEvent,
            hasIdleOut ? outIdleWaitNs : NULL);
    }
    HANDLE doneEvent = CreateEventW(NULL, FALSE, FALSE, NULL);
    if (!doneEvent) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsCommand cmd;
    memset(&cmd, 0, sizeof(cmd));
    cmd.kind = CJGUI_WINDOWS_CMD_PUMP;
    cmd.token = token;
    cmd.generation = generation;
    cmd.timeoutMs = timeoutMs;
    cmd.hasIdleOut = hasIdleOut;
    cmd.doneEvent = doneEvent;
    EnterCriticalSection(&s->cmdLock);
    if (s->retiring || s->sessionGeneration != generation) {
        LeaveCriticalSection(&s->cmdLock);
        CloseHandle(doneEvent);
        return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    if (((s->cmdHead + 1u) % CJGUI_WINDOWS_CMD_RING_CAPACITY) == s->cmdTail) {
        LeaveCriticalSection(&s->cmdLock);
        CloseHandle(doneEvent);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    s->cmdRing[s->cmdHead % CJGUI_WINDOWS_CMD_RING_CAPACITY] = &cmd;
    s->cmdHead = (s->cmdHead + 1u) % CJGUI_WINDOWS_CMD_RING_CAPACITY;
    SetEvent(s->cmdWakeEvent);
    LeaveCriticalSection(&s->cmdLock);
    WaitForSingleObject(doneEvent, INFINITE);
    CjguiInternalRendererStatus status = cmd.status;
    if (!cmd.cancelled && status == CJGUI_INTERNAL_RENDERER_OK) {
        *outEvent = cmd.outEvent;
        if (hasIdleOut && outIdleWaitNs) *outIdleWaitNs = cmd.outIdleNs;
    } else if (cmd.cancelled) {
        status = CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    CloseHandle(doneEvent);
    return status;
}

static CjguiInternalRendererStatus marshal_destroy_command(uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    uint64_t generation = s->sessionGeneration;
    DWORD uiTid = s->pumpThreadId;
    int running = s->pumpThreadRunning;
    HANDLE pumpThread = s->pumpThread;
    if (uiTid != 0u && GetCurrentThreadId() == uiTid) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    CjguiInternalRendererStatus flightStatus = drain_text_flights(s, 5000u);
    if (flightStatus != CJGUI_INTERNAL_RENDERER_OK) return flightStatus;
    if (!running || uiTid == 0u) {
        if (s->sessionGeneration != generation || s->retiring) {
            return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        }
        destroy_ui_phase_a(s);
        destroy_caller_phase_b(s);
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    HANDLE doneEvent = CreateEventW(NULL, FALSE, FALSE, NULL);
    if (!doneEvent) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiWindowsCommand cmd;
    memset(&cmd, 0, sizeof(cmd));
    cmd.kind = CJGUI_WINDOWS_CMD_DESTROY;
    cmd.token = token;
    cmd.generation = generation;
    cmd.doneEvent = doneEvent;
    EnterCriticalSection(&s->cmdLock);
    if (s->retiring || s->sessionGeneration != generation) {
        LeaveCriticalSection(&s->cmdLock);
        CloseHandle(doneEvent);
        return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    if (((s->cmdHead + 1u) % CJGUI_WINDOWS_CMD_RING_CAPACITY) == s->cmdTail) {
        LeaveCriticalSection(&s->cmdLock);
        CloseHandle(doneEvent);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    s->cmdRing[s->cmdHead % CJGUI_WINDOWS_CMD_RING_CAPACITY] = &cmd;
    s->cmdHead = (s->cmdHead + 1u) % CJGUI_WINDOWS_CMD_RING_CAPACITY;
    SetEvent(s->cmdWakeEvent);
    LeaveCriticalSection(&s->cmdLock);
    WaitForSingleObject(doneEvent, INFINITE);
    CjguiInternalRendererStatus status = cmd.cancelled
        ? CJGUI_INTERNAL_RENDERER_INVALID_SESSION : cmd.status;
    CloseHandle(doneEvent);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    SetEvent(s->pumpStopEvent);
    WaitForSingleObject(pumpThread, INFINITE);
    CloseHandle(pumpThread);
    destroy_caller_phase_b(s);
    return CJGUI_INTERNAL_RENDERER_OK;
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

CjguiInternalRendererStatus cjgui_internal_renderer_window_activation_state(uint64_t token,
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

CjguiInternalRendererStatus cjgui_internal_renderer_activate_window(uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s || !s->hwnd) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (IsIconic(s->hwnd)) ShowWindow(s->hwnd, SW_RESTORE);
    BringWindowToTop(s->hwnd);
    return SetForegroundWindow(s->hwnd) ? CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

CjguiInternalRendererStatus cjgui_internal_renderer_window_frame(uint64_t token, int64_t *outX,
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

int32_t cjgui_internal_renderer_window_number(uint64_t token, int64_t *outNumber) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s || !s->hwnd) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (outNumber) *outNumber = (int64_t)(intptr_t)s->hwnd;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_window_title(uint64_t token, const char *title) {
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

int32_t cjgui_internal_renderer_set_composable_range_edit_delta(uint64_t token, int32_t enabled) {
    return find_session(token) ? (enabled == 0 || enabled == 1
        ? CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR)
        : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
}

int32_t cjgui_internal_renderer_cancel_composition(uint64_t token,
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

int32_t cjgui_internal_renderer_declare_input_caret(uint64_t token, int64_t nodeId,
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

uint8_t cjgui_internal_renderer_source_install_pending_scalar(uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    return s ? (s->sourceInstallPending ? 1 : 0) : 0;
}

uint64_t cjgui_internal_renderer_source_install_gated_inputs(uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    return s ? s->sourceInstallGatedInputs : 0u;
}

int32_t cjgui_internal_renderer_probe_image_texture(uint64_t token, uint64_t nodeId,
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
    return cjgui_internal_renderer_owner_clock_ns();
}

uint64_t cjgui_internal_renderer_owner_thread_cpu_ns(void) {
    FILETIME creation, exitTime, kernel, user;
    if (!GetThreadTimes(GetCurrentThread(), &creation, &exitTime, &kernel, &user)) return 0;
    ULARGE_INTEGER k, u;
    k.LowPart = kernel.dwLowDateTime; k.HighPart = kernel.dwHighDateTime;
    u.LowPart = user.dwLowDateTime; u.HighPart = user.dwHighDateTime;
    return (k.QuadPart + u.QuadPart) * 100ull;
}

CjguiInternalRendererStatus cjgui_internal_renderer_diagnostic_workload(uint64_t token,
    CjguiInternalRendererDiagnosticWorkload *outWorkload) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s || !outWorkload) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    memset(outWorkload, 0, sizeof(*outWorkload));
    outWorkload->sceneVersion = s->sceneVersion;
    outWorkload->frameIndex = s->frameIndex;
    outWorkload->textLayoutPreparationCount = s->textLayoutPreparationCount;
    outWorkload->imageDecodeStartCount = s->imageDecodeStartCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_diagnostic_timing(uint64_t token, uint32_t enabled) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    s->diagnosticTimingEnabled = enabled ? 1u : 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_diagnostic_overlay(uint64_t token, uint32_t flags,
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
    double originY = (double)node->node.y + node->geometry.translateY;
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

CjguiInternalRendererStatus cjgui_internal_renderer_hit_test_composable_text(uint64_t token, uint64_t nodeId,
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

CjguiInternalRendererStatus cjgui_internal_renderer_text_stop_resolve(uint64_t token, uint64_t nodeId,
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

CjguiInternalRendererStatus cjgui_internal_renderer_text_stop_neighbor(uint64_t token, uint64_t nodeId,
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

int32_t cjgui_internal_renderer_text_line_rect_count(uint64_t token, uint64_t nodeId,
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

CjguiInternalRendererStatus cjgui_internal_renderer_diagnostic_node_geometry(uint64_t token, uint32_t nodeIndex,
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

CjguiInternalRendererStatus cjgui_internal_renderer_destroy(uint64_t token) {
    return marshal_destroy_command(token);
}

CjguiInternalRendererStatus cjgui_internal_renderer_request_close(uint64_t token) {
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

uint64_t cjgui_internal_renderer_coordinate_lifetime(uint64_t token,
    uint64_t *outSessionGeneration) {
    if (outSessionGeneration) *outSessionGeneration = 0u;
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s || !s->hwnd || !s->sessionGeneration || !s->coordinateEpoch) return 0u;
    if (outSessionGeneration) *outSessionGeneration = s->sessionGeneration;
    return s->coordinateEpoch;
}

void cjgui_internal_renderer_request_application_stop(void) {
    /* PostQuitMessage 只作用于调用线程；停止语义必须到达拥有窗口队列的泵线程。 */
    int posted = 0;
    ensure_session_lock();
    EnterCriticalSection(&g_sessionLock);
    for (uint32_t i = 0; i < CJGUI_WINDOWS_SESSION_CAPACITY; ++i) {
        if (g_sessions[i].occupied && g_sessions[i].pumpThreadId != 0u) {
            if (PostThreadMessageW(g_sessions[i].pumpThreadId, WM_QUIT, 0, 0)) posted += 1;
        }
    }
    LeaveCriticalSection(&g_sessionLock);
    (void)posted;
}

int64_t cjgui_macos_control_accent_srgb8(void) {
    COLORREF color = GetSysColor(COLOR_HIGHLIGHT);
    uint32_t rgb = ((uint32_t)GetRValue(color) << 16) |
        ((uint32_t)GetGValue(color) << 8) | (uint32_t)GetBValue(color);
    return (int64_t)(0x01000000u | rgb);
}

const char *cjgui_internal_renderer_data_transfer_event_format(uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    return require_session(s) == CJGUI_INTERNAL_RENDERER_OK ? "" : "";
}

uint32_t cjgui_internal_renderer_data_transfer_event_binary_size(uint64_t token,
    uint64_t eventId) {
    (void)eventId;
    CjguiWindowsRendererSession *s = find_session(token);
    return require_session(s) == CJGUI_INTERNAL_RENDERER_OK ? 0u : 0u;
}

CjguiInternalRendererStatus cjgui_internal_renderer_copy_data_transfer_event_binary(
    uint64_t token, uint64_t eventId, uint8_t *outBytes, uint32_t capacity) {
    (void)eventId; (void)outBytes; (void)capacity;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    return owner == CJGUI_INTERNAL_RENDERER_OK
        ? CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED : owner;
}

CjguiInternalRendererStatus cjgui_internal_renderer_prepare_composable_png_transfer(
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

CjguiInternalRendererStatus cjgui_internal_renderer_finish_composable_png_transfer(
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
}

CjguiInternalRendererStatus cjgui_internal_renderer_installed_range_arm(
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
    s->rangeNextSeq = 0u;
    s->rangePrevSeq = 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_installed_range_receipt(
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

CjguiInternalRendererStatus cjgui_internal_renderer_installed_range_active_receipt(
    uint64_t token, uint64_t nonce, CjguiInternalInstalledRangeReceipt *receipt) {
    return cjgui_internal_renderer_installed_range_receipt(token, nonce, receipt);
}

CjguiInternalRendererStatus cjgui_internal_renderer_installed_range_activate(
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

CjguiInternalRendererStatus cjgui_internal_renderer_installed_range_cancel(
    uint64_t token, uint64_t nonce) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (!s->rangeArmed || s->rangeNonce != nonce) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    range_disarm(s);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_claim_last_pumped_range(
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
    intent->sourceStartByte = s->rangeSourceStart;
    /* 回执语义：input 的源跨度 = 起点 + preBody 字节长（链体随接受增长）。 */
    intent->sourceEndByte = s->rangeSourceStart + (uint64_t)entry->preBodyLength;
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
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_copy_claimed_range_bytes(
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
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_ack_installed_range(
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
    if (accepted) {
        s->rangeAcceptedSeq = entry->seq;
        s->rangeAcceptedVersion = versionAfter;
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

CjguiInternalRendererStatus cjgui_internal_renderer_release_installed_range(
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
    const char *insert, uint32_t insertLength) {
    if (!s || !s->ownedTextSessionEnabled || !s->ownedTextSessionBindingEpoch ||
        !s->hwnd || GetFocus() != s->hwnd || !s->acceptedScene.configured) {
        if (s) qorr_debug_log("drop_early", s, insert, 0);
        return 0;
    }
    if (source_install_gate_holds_input(s)) { qorr_debug_log("drop_gate", s, insert, 0); return 0; }
    if (s->navBarrierArmed && !s->navReplayActive) {
        return nav_barrier_hold_char(s, insert, insertLength);
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
    const WCHAR *text, uint32_t units) {
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
            if (!handle_windows_text_character(s, &replacement, 1u)) return 0;
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
        if (!handle_windows_text_character(s, &replacement, 1u)) return 0;
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
    return queue_owned_range_replace(s, utf8, (uint32_t)bytes);
}

static int64_t windows_keyboard_modifiers(void) {
    /* 必须用 Async 物理状态：GetKeyState 返回的是本线程消息队列已处理的
       键盘状态，SendInput 合成的 Shift 在相邻 LEFT 消息处理时常常还未同步，
       导致 Shift 修饰丢失（实测 modifiers=0）。Async 反映注入时的真实按键。 */
    int64_t flags = 0;
    if (GetAsyncKeyState(VK_SHIFT) < 0) flags |= 0x020000;
    if (GetAsyncKeyState(VK_CONTROL) < 0) flags |= 0x040000;
    if (GetAsyncKeyState(VK_MENU) < 0) flags |= 0x080000;
    if (GetAsyncKeyState(VK_LWIN) < 0 || GetAsyncKeyState(VK_RWIN) < 0) flags |= 0x100000;
    return flags;
}

static int enqueue_windows_navigation(CjguiWindowsRendererSession *s, const char *intent,
    int64_t frozenModifiers) {
    if (!s || !intent || !s->ownedTextSessionEnabled || !s->ownedTextSessionBindingEpoch ||
        GetFocus() != s->hwnd) return 0;
    if (source_install_gate_holds_input(s)) return 0;
    if (s->navBarrierArmed && !s->navReplayActive && nav_intent_is_delete(intent)) {
        return nav_barrier_hold_delete(s, intent, frozenModifiers);
    }
    CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, s->ownedTextSessionNodeId);
    if (!node || node->node.resourceId != s->ownedTextSessionResourceId ||
        node->node.nodeKind != s->ownedTextSessionNodeKind) return 0;
    CjguiInternalRendererEvent event;
    memset(&event, 0, sizeof(event));
    event.kind = 35u;
    event.nodeId = s->ownedTextSessionNodeId;
    event.projectionVersion = s->sceneVersion;
    event.resourceId = s->ownedTextSessionResourceId;
    event.nodeKind = s->ownedTextSessionNodeKind;
    event.bindingEpoch = s->ownedTextSessionBindingEpoch;
    event.modifierFlags = frozenModifiers;
    if (!push_event_payload(s, &event, intent, (uint32_t)strlen(intent))) return 0;
    if (nav_intent_is_movement(intent)) s->navBarrierArmed = 1u;
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
    const char *insert, uint32_t insertLength) {
    if (!s || !insert) return 0;
    if (s->navHoldCount >= CJGUI_WINDOWS_NAV_HOLD_CAPACITY ||
        s->navHoldBytes + insertLength > CJGUI_WINDOWS_NAV_HOLD_BYTES) {
        s->eventQueueFull = 1u;
        return 1;
    }
    char *copy = duplicate_utf8_bytes(insert, insertLength);
    if (!copy) {
        s->eventQueueFull = 1u;
        return 1;
    }
    uint32_t slot = (s->navHoldHead + s->navHoldCount) % CJGUI_WINDOWS_NAV_HOLD_CAPACITY;
    s->navHold[slot].isDelete = 0u;
    s->navHold[slot].bytes = copy;
    s->navHold[slot].length = insertLength;
    s->navHold[slot].modifiers = 0;
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
        s->eventQueueFull = 1u;
        return 1;
    }
    char *copy = duplicate_utf8_bytes(intent, intentLength);
    if (!copy) {
        s->eventQueueFull = 1u;
        return 1;
    }
    uint32_t slot = (s->navHoldHead + s->navHoldCount) % CJGUI_WINDOWS_NAV_HOLD_CAPACITY;
    s->navHold[slot].isDelete = 1u;
    s->navHold[slot].bytes = copy;
    s->navHold[slot].length = intentLength;
    s->navHold[slot].modifiers = frozenModifiers;
    s->navHoldCount += 1u;
    s->navHoldBytes += intentLength;
    return 1;
}

static void nav_barrier_release(CjguiWindowsRendererSession *s, int replay) {
    if (!s || !s->navBarrierArmed) return;
    struct {
        uint32_t isDelete;
        char *bytes;
        uint32_t length;
        int64_t modifiers;
    } held[CJGUI_WINDOWS_NAV_HOLD_CAPACITY];
    uint32_t heldCount = 0u;
    while (s->navHoldCount > 0u && heldCount < CJGUI_WINDOWS_NAV_HOLD_CAPACITY) {
        uint32_t slot = s->navHoldHead % CJGUI_WINDOWS_NAV_HOLD_CAPACITY;
        held[heldCount].isDelete = s->navHold[slot].isDelete;
        held[heldCount].bytes = s->navHold[slot].bytes;
        held[heldCount].length = s->navHold[slot].length;
        held[heldCount].modifiers = s->navHold[slot].modifiers;
        s->navHold[slot].bytes = NULL;
        s->navHold[slot].length = 0u;
        s->navHoldHead = (s->navHoldHead + 1u) % CJGUI_WINDOWS_NAV_HOLD_CAPACITY;
        s->navHoldCount -= 1u;
        heldCount += 1u;
    }
    s->navHoldBytes = 0u;
    s->navBarrierArmed = 0u;
    if (!replay) {
        for (uint32_t i = 0u; i < heldCount; ++i) free(held[i].bytes);
        return;
    }
    s->navReplayActive = 1u;
    for (uint32_t i = 0u; i < heldCount; ++i) {
        if (held[i].isDelete) {
            (void)enqueue_windows_navigation(s, held[i].bytes, held[i].modifiers);
        } else {
            (void)queue_owned_range_replace(s, held[i].bytes, held[i].length);
        }
        free(held[i].bytes);
    }
    s->navReplayActive = 0u;
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

static void remember_ime_successor(CjguiWindowsRendererSession *s,
    const char *text, uint32_t textBytes, uint32_t cursor16) {
    if (!s || !text) return;
    char *copy = duplicate_utf8_bytes(text, textBytes);
    if (!copy) {
        s->eventQueueFull = 1u;
        return;
    }
    free(s->pendingImeSuccessorUtf8);
    s->pendingImeSuccessorUtf8 = copy;
    s->pendingImeSuccessorCursor16 = cursor16;
    s->pendingImeSuccessorPresent = 1u;
}

static int handle_windows_ime_composition(CjguiWindowsRendererSession *s, LPARAM flags) {
    if (!s || !s->ownedTextSessionEnabled || s->compositionGate != WINDOWS_COMPOSITION_GATE_OPEN)
        return 0;
    HIMC context = ImmGetContext(s->hwnd);
    if (!context) return 0;
    char *resultText = NULL, *markedText = NULL;
    uint32_t resultBytes = 0u, resultUnits = 0u;
    uint32_t markedBytes = 0u, markedUnits = 0u;
    int hasResult = ((uint64_t)flags & (uint64_t)GCS_RESULTSTR) != 0u;
    int hasMarked = ((uint64_t)flags & (uint64_t)GCS_COMPSTR) != 0u;
    int resultOk = !hasResult || read_imm_utf8(context, GCS_RESULTSTR,
        &resultText, &resultBytes, &resultUnits);
    int markedOk = !hasMarked || read_imm_utf8(context, GCS_COMPSTR,
        &markedText, &markedBytes, &markedUnits);
    LONG cursorValue = hasMarked ? ImmGetCompositionStringW(context, GCS_CURSORPOS, NULL, 0u) : 0;
    ImmReleaseContext(s->hwnd, context);
    if (!resultOk || !markedOk) {
        free(resultText); free(markedText);
        s->eventQueueFull = 1u;
        return 1;
    }
    uint32_t cursor16 = cursorValue < 0 ? markedUnits : (uint32_t)cursorValue;
    int handled = 1;
    if (hasResult) {
        if (s->compositionState == WINDOWS_COMPOSITION_IDLE) {
            if (!begin_windows_composition(s) ||
                !queue_windows_composition_update(s, resultText, resultBytes, resultUnits)) {
                handled = 1;
                goto ime_done;
            }
        }
        if (s->compositionState == WINDOWS_COMPOSITION_MARKED &&
            !queue_windows_composition_terminal(s,
                CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_COMMIT, resultText, resultBytes)) {
            s->eventQueueFull = 1u;
            s->compositionGate = WINDOWS_COMPOSITION_GATE_RECOVERING;
        }
        if (hasMarked && s->compositionState == WINDOWS_COMPOSITION_TERMINAL_QUEUED)
            remember_ime_successor(s, markedText, markedBytes, cursor16);
    } else if (hasMarked) {
        if (s->compositionState == WINDOWS_COMPOSITION_TERMINAL_QUEUED) {
            remember_ime_successor(s, markedText, markedBytes, cursor16);
        } else if (s->compositionState == WINDOWS_COMPOSITION_IDLE ||
            s->compositionState == WINDOWS_COMPOSITION_MARKED) {
            (void)queue_windows_composition_update(s, markedText, markedBytes, cursor16);
        }
    }
ime_done:
    free(resultText);
    free(markedText);
    return handled;
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
        free(s->pendingImeSuccessorUtf8);
        s->pendingImeSuccessorUtf8 = NULL;
        s->pendingImeSuccessorPresent = 0u;
        s->pendingImeSuccessorReady = 0u;
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
    if (!s || !s->pendingImeSuccessorReady || !s->pendingImeSuccessorPresent ||
        s->compositionState != WINDOWS_COMPOSITION_IDLE || !s->ownedTextSessionEnabled ||
        s->ownedTextSessionBindingEpoch == 0u || GetFocus() != s->hwnd) return;
    CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, s->ownedTextSessionNodeId);
    if (!node || node->node.resourceId != s->ownedTextSessionResourceId ||
        node->node.nodeKind != s->ownedTextSessionNodeKind ||
        windows_validate_active_text(s, s->ownedTextSessionNodeId,
            s->ownedTextSessionResourceId, s->ownedTextSessionNodeKind,
            s->sceneVersion, node->value ? node->value : "", NULL) != CJGUI_INTERNAL_RENDERER_OK)
        return;
    if (!begin_windows_composition(s)) return;
    if (!queue_windows_composition_update(s, s->pendingImeSuccessorUtf8,
        (uint32_t)strlen(s->pendingImeSuccessorUtf8), s->pendingImeSuccessorCursor16)) {
        end_windows_ime_composition(s);
        return;
    }
    free(s->pendingImeSuccessorUtf8);
    s->pendingImeSuccessorUtf8 = NULL;
    s->pendingImeSuccessorCursor16 = 0u;
    s->pendingImeSuccessorPresent = 0u;
    s->pendingImeSuccessorReady = 0u;
}

CjguiInternalRendererStatus cjgui_internal_renderer_focus_composable_node(
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

CjguiInternalRendererStatus cjgui_internal_renderer_restore_composable_selection(
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

CjguiInternalRendererStatus cjgui_internal_renderer_install_owned_source_selection(
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
    if (GetFocus() != s->hwnd || find_session(token) != s ||
        s->sceneVersion != sceneVersion ||
        s->ownedTextSessionBindingEpoch != bindingEpoch ||
        !s->sourceInstallPending || s->sourceInstallRequestId != requestId ||
        strcmp(node->value ? node->value : "", expectedValue) != 0) {
        free(nextProxy);
        s->selectionStart16 = oldStart;
        s->selectionEnd16 = oldEnd;
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
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
    s->sourceInstallProvisional = 1u;
    s->sourceInstallOutcome = CJGUI_WINDOWS_INSTALL_OUTCOME_INSTALLED;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_read_composable_selection(
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

CjguiInternalRendererStatus cjgui_internal_renderer_recover_active_text_proxy(
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

CjguiInternalRendererStatus cjgui_internal_renderer_reanchor_composition(
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

CjguiInternalRendererStatus cjgui_internal_renderer_arm_composition_reanchor(
    uint64_t token, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
    const char *baseText, uint32_t replacementStart16, uint32_t replacementLength16) {
    (void)token; (void)nodeId; (void)resourceId; (void)nodeKind;
    (void)baseText; (void)replacementStart16; (void)replacementLength16;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_owned_text_session(
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

CjguiInternalRendererStatus cjgui_internal_renderer_configure_shared_operation(
    uint64_t token, uint32_t visibleRecordCount) {
    (void)visibleRecordCount;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    return owner == CJGUI_INTERNAL_RENDERER_OK ? CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED : owner;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_shared_operation_title(
    uint64_t token, uint32_t recordIndex, const char *title) {
    (void)recordIndex; (void)title;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    return owner == CJGUI_INTERNAL_RENDERER_OK ? CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED : owner;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_shared_operation_state(
    uint64_t token, const CjguiInternalRendererSharedOperationState *state) {
    (void)state;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    return owner == CJGUI_INTERNAL_RENDERER_OK ? CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED : owner;
}

CjguiInternalRendererStatus cjgui_internal_renderer_configure_shared_form(
    uint64_t token, uint32_t fieldCount) {
    (void)fieldCount;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    return owner == CJGUI_INTERNAL_RENDERER_OK ? CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED : owner;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_shared_collection_row(
    uint64_t token, uint32_t rowIndex, const char *title, uint8_t isSelected,
    uint32_t viewportStart, uint32_t totalRecordCount) {
    (void)rowIndex; (void)title; (void)isSelected; (void)viewportStart; (void)totalRecordCount;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    return owner == CJGUI_INTERNAL_RENDERER_OK ? CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED : owner;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_shared_form_field(
    uint64_t token, uint32_t fieldIndex, const char *label, const char *draftText,
    const char *validationError, uint32_t editorKind, uint8_t isFocused,
    uint32_t selectionStart, uint32_t selectionEnd) {
    (void)fieldIndex; (void)label; (void)draftText; (void)validationError;
    (void)editorKind; (void)isFocused; (void)selectionStart; (void)selectionEnd;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    return owner == CJGUI_INTERNAL_RENDERER_OK ? CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED : owner;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_shared_form_status(
    uint64_t token, const char *statusText) {
    (void)statusText;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    return owner == CJGUI_INTERNAL_RENDERER_OK ? CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED : owner;
}

CjguiInternalRendererStatus cjgui_internal_renderer_present_clear(uint64_t token,
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

// macOS 私有异步多行测高 worker 在 Windows 的诚实占位：返回不可用，
// 调用方按既有 fail() 大声失败（不清默成功）。该能力的所有权与同步回退
// 或 Windows 实现由 E 裁定（async_multiline_measure.cj 为 E 在途特性）；
// 本占位只为不断开 Windows 链接，不代表该路径已可用。
int32_t cjgui_async_composable_multiline_begin(const char *text, uint64_t byteLength,
    double fontSize, uint32_t fontWeight, uint32_t fontFamily, uint32_t contentWidth,
    uint64_t *outHandle) {
    (void)text; (void)byteLength; (void)fontSize; (void)fontWeight;
    (void)fontFamily; (void)contentWidth;
    if (outHandle) *outHandle = 0u;
    return 4;
}

int32_t CjguiAsyncMultilineMeasurePoll(uint64_t handle, uint32_t *outHeight,
    int32_t *outFailure) {
    (void)handle;
    if (outHeight) *outHeight = 0u;
    if (outFailure) *outFailure = 4;
    return 4;
}

int32_t CjguiAsyncMultilineMeasureRelease(uint64_t handle, int32_t disposition) {
    (void)handle; (void)disposition;
    return 0;
}

// ---- 正常产品链 Windows 平台服务补全（2026-10-06，20 个链接缺口） ----
// 三态纪律：进入产品链必经场景发布的“声明/准备”类 API 在 Windows 被接受并做
// 与 macOS 相同口径的有界校验（否则候选场景会被整体拒绝）；未在写作链中实现
// 的平台特性（OS 菜单栏投影、系统剪贴板/拖放、原生 context-menu 守卫、共享集合
// 表单）保留具名缺口；指针取消与几何诊断直接使用本文件已有的真实会话状态。

CjguiInternalRendererStatus cjgui_internal_renderer_cancel_composable_pointer_capture(
    uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (s->mouseCaptureActive || s->mousePressActive) windows_cancel_mouse_gesture(s);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_cancel_composable_pointer_capture_epoch(
    uint64_t token, uint64_t gestureEpoch) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    if (gestureEpoch == 0u) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (s->mouseGestureEpoch != gestureEpoch) return CJGUI_INTERNAL_RENDERER_OK;
    if (s->mouseCaptureActive || s->mousePressActive) windows_cancel_mouse_gesture(s);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_configure_composable_command_menu(
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

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_command_menu_item(
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

CjguiInternalRendererStatus cjgui_internal_renderer_commit_composable_command_menu(
    uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    s->commandMenuAcceptedCount = s->commandMenuPendingCount;
    s->commandMenuPendingCount = 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_configure_composable_data_transfer(
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

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_data_transfer_item(
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

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_data_transfer_item_bytes(
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

CjguiInternalRendererStatus cjgui_internal_renderer_composable_display_progress(
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

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_context_menu_guard(
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

CjguiInternalRendererStatus cjgui_internal_renderer_configure_shared_collection_form(
    uint64_t token, uint32_t fieldCount, uint32_t visibleRecordCount) {
    (void)fieldCount; (void)visibleRecordCount;
    CjguiWindowsRendererSession *s = find_session(token);
    CjguiInternalRendererStatus owner = require_session(s);
    if (owner != CJGUI_INTERNAL_RENDERER_OK) return owner;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_shared_collection_filter(
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

CjguiInternalRendererStatus cjgui_internal_renderer_cancel_composable_pointer_capture_gesture_key(
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

// E 在途 macOS 私有异步文字度量接口（text_metrics）的 Windows 契约：
// 与既有 multiline 占位同策略——具名失败（4=FAILED），调用方 fail-fast，
// 不做“成功空壳”。句柄保持 0 以让调用方立即走失败分支。
int32_t cjgui_async_composable_text_metrics_begin(const char *text, uint64_t byteLength,
    double fontSize, uint32_t fontWeight, uint32_t fontFamily, uint32_t maximumWidth,
    uint64_t *outHandle) {
    (void)text; (void)byteLength; (void)fontSize; (void)fontWeight;
    (void)fontFamily; (void)maximumWidth;
    if (outHandle) *outHandle = 0u;
    return 4;
}

int32_t CjguiAsyncTextMetricsPoll(uint64_t handle,
    CjguiInternalRendererTextMeasurement *outMetrics, int32_t *outFailure) {
    (void)handle;
    if (outMetrics) memset(outMetrics, 0, sizeof(*outMetrics));
    if (outFailure) *outFailure = 4;
    return 4;
}

/* 诊断观测：最近一次 pump 调用实际执行的 OS 线程 id。
   供 A/B 线程反例判定“同一 session 是否恒由同一 UI 线程执行”。
   完整 dispatcher 落地后，此值应恒等于泵线程 id；当前实现随调用线程变化。 */
uint32_t cjgui_internal_renderer_debug_last_pump_tid(uint64_t token) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) return 0u;
    return (uint32_t)s->lastPumpTid;
}

uint32_t cjgui_internal_renderer_debug_source_install_state(uint64_t token,
    uint32_t *outProvisional, uint32_t *outOutcome) {
    CjguiWindowsRendererSession *s = find_session(token);
    if (!s) return 0u;
    if (outProvisional) *outProvisional = s->sourceInstallProvisional;
    if (outOutcome) *outOutcome = s->sourceInstallOutcome;
    return s->sourceInstallPending;
}
