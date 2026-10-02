// runtime/cjgui/native/cjgui_internal_renderer.h
//
// INTERNAL / UNSTABLE C ABI.
//
// This header declares the runtime-owned internal renderer sidecar ABI.
// It is NOT a public, stable, or installable header. Symbols are prefixed
// with `cjgui_internal_renderer_` to keep them visibly internal. No
// compatibility is promised across versions.
//
// The Cangjie runtime owns the session lifecycle and the bounded event pump.
// The C side never calls [NSApplication run]; it only performs single/bounded
// AppKit event acquisition on demand. The Cangjie side always retains control
// and loops pumpEvent.
//
// Principles enforced here and in the .m:
//  - AppKit work runs only on the main thread. A native macOS application
//    launcher can opt in to synchronous dispatch from its Cangjie worker;
//    without that opt-in, off-main calls fail closed with NOT_MAIN_THREAD.
//  - No Objective-C / Metal pointer is ever returned to Cangjie. Only a
//    uint64_t session token and POD result/event structs cross the boundary.
//  - The C side never stores addresses of Cangjie-provided inout parameters.
//  - Session capacity is intentionally tiny (e.g. 2).
//  - pumpEvent is bounded: it never waits longer than the caller's timeout
//    (<= 16 ms).

#ifndef CJGUI_INTERNAL_RENDERER_H
#define CJGUI_INTERNAL_RENDERER_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Internal status enum. Values are stable within R1 but the enum as a whole
// is internal/unstable.
typedef enum CjguiInternalRendererStatus {
    CJGUI_INTERNAL_RENDERER_OK = 0,
    CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD = 1,
    CJGUI_INTERNAL_RENDERER_APP_INIT_FAILED = 2,
    CJGUI_INTERNAL_RENDERER_WINDOW_CREATE_FAILED = 3,
    CJGUI_INTERNAL_RENDERER_METAL_DEVICE_UNAVAILABLE = 4,
    CJGUI_INTERNAL_RENDERER_METAL_COMMAND_QUEUE_UNAVAILABLE = 5,
    CJGUI_INTERNAL_RENDERER_METAL_LAYER_UNAVAILABLE = 6,
    CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE = 7,
    CJGUI_INTERNAL_RENDERER_METAL_COMMAND_BUFFER_UNAVAILABLE = 8,
    CJGUI_INTERNAL_RENDERER_METAL_ENCODER_UNAVAILABLE = 9,
    CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED = 10,
    CJGUI_INTERNAL_RENDERER_INVALID_SESSION = 11,
    CJGUI_INTERNAL_RENDERER_SESSION_TABLE_FULL = 12,
    CJGUI_INTERNAL_RENDERER_READBACK_FAILED = 13,
    // The caller supplied bytes that are not a complete UTF-8 string. This
    // remains an internal status; the Cangjie wrapper maps it to a value-only
    // experimental API reason and never exposes the native enum.
    CJGUI_INTERNAL_RENDERER_INVALID_UTF8 = 14,
    // A platform transfer offer or payload did not match the currently
    // accepted Cangjie declaration or its explicit byte bound.
    CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED = 15,
    // The candidate's visible text tiles exceeded a bounded allocation or
    // the 24 MiB accepted-scene text budget. The old scene stays accepted.
    CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED = 16,
    // Hit testing needs the node to be present in the currently accepted scene;
    // a miss is reported distinctly so a caller can tell "not staged yet" from a
    // programming error instead of silently receiving offset 0.
    CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND = 17,
    CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY = 18,
    // No accepted scene nodes are staged at all, as opposed to the requested id
    // being absent from a staged scene.
    CJGUI_INTERNAL_RENDERER_SCENE_NOT_STAGED = 19,
    // A native ticket owns the staged candidate until its terminal decision.
    CJGUI_INTERNAL_RENDERER_PRESENT_PENDING = 20,
    // A staged effect group failed bounded target admission. The previous
    // accepted scene and every texture generation it uses remain untouched.
    CJGUI_INTERNAL_RENDERER_EFFECT_RESOURCE_BUDGET_EXCEEDED = 22,
    CJGUI_INTERNAL_RENDERER_EFFECT_DECLARATION_REJECTED = 23,
    CJGUI_INTERNAL_RENDERER_PNG_INVALID = 25,
    CJGUI_INTERNAL_RENDERER_PNG_DIMENSION_EXCEEDED = 26,
    CJGUI_INTERNAL_RENDERER_PNG_DECODE_FAILED = 27,
    CJGUI_INTERNAL_RENDERER_PNG_RESOURCE_BUDGET_EXCEEDED = 28,
    CJGUI_INTERNAL_RENDERER_PNG_PAYLOAD_TOO_LARGE = 29,
    CJGUI_INTERNAL_RENDERER_PNG_QUEUE_BUDGET_EXCEEDED = 30,
    CJGUI_INTERNAL_RENDERER_PNG_UNSUPPORTED = 31,
    // A1 票据协议：会话仍有未确认（未 ACK）的提交票据，销毁被拒绝。
    // 依据 Astra pending-transaction/answer.md 第 4 点：destroy 直接清 g_pending
    // 只能阻止槽位误认领，不能证明原事务结算完成；旧实例身份也不得在资源仍
    // 存活时被复用。
    CJGUI_INTERNAL_RENDERER_PENDING_SETTLEMENT_UNRESOLVED = 21,
    // The requested byte offset does not name a grapheme cluster boundary
    // candidate (it splits a UTF-8 scalar, or sits past the buffer end), so no
    // cluster range can be proven for it. Distinct from INVALID_UTF8: the
    // buffer itself decoded fine.
    CJGUI_INTERNAL_RENDERER_GRAPHEME_BOUNDARY_INVALID = 24,
    // The platform text service cannot answer grapheme-cluster queries on this backend, so NO
    // cluster can be named. A named refusal, never a scalar fallback: the caller keeps the
    // original text and reports this state (OHOS text-service bridging is not wired yet).
    CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED = 32,
    // The caller's expected accepted-scene version no longer matches the
    // staged scene: the query's position identity is stale, the caller must
    // re-resolve against the current scene instead of using mixed facts.
    CJGUI_INTERNAL_RENDERER_SCENE_STALE = 33,
    // A display-range query named a byte that is not a strict UTF-8 boundary
    // (mid-scalar) or lies past the staged text: the caller keeps the text and
    // the original selection, never a clamped stand-in (M1 contract).
    CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID = 34,
    // The visual-navigation query could not enumerate the caret line's
    // insertion points within the bounded budget: no neighbor is named, the
    // caller keeps caret and selection (M2 contract; never a half-line scan).
    CJGUI_INTERNAL_RENDERER_VISUAL_NAV_UNSUPPORTED = 35,
    CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR = 99
} CjguiInternalRendererStatus;

// Lifecycle / event kinds returned by pumpEvent.
typedef enum CjguiInternalRendererEventKind {
    CJGUI_INTERNAL_RENDERER_EVENT_NONE = 0,
    CJGUI_INTERNAL_RENDERER_EVENT_CLOSE_REQUESTED = 1,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_SELECT_RECORD = 2,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_TOGGLE_RECORD = 3,
    // These change only the renderer viewport. Cangjie consumes them to
    // select a different bounded projection; they never mutate list truth.
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_VIEWPORT_PREVIOUS = 4,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_VIEWPORT_NEXT = 5,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_FOCUS = 6,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_TEXT_CHANGED = 7,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_BOOLEAN_CHANGED = 8,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_APPLY = 9,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_CANCEL = 10,
    // A bounded native input queue refused a new interaction after preserving
    // every interaction already accepted. Cangjie surfaces a retry message;
    // it must never reinterpret this as a successful domain edit.
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_INPUT_QUEUE_FULL = 11,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_SELECT = 12,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_PREVIOUS_PAGE = 13,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_NEXT_PAGE = 14,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_CREATE = 15,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_DELETE = 16,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_UNDO = 17,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_REDO = 18,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_SAVE = 19,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_COPY = 20,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_NEW = 21,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_OPEN = 22,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_SAVE_AS = 23,
    // A native window close is not permission to discard application state.
    // The collection domain receives this request and explicitly chooses to
    // keep the window open or call request_close after save/discard.
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_CLOSE = 24,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_DISCARD = 25,
    // The native view only owns this transient query text. Cangjie applies it
    // to its projection; it never becomes collection or rule-set state.
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_FILTER_CHANGED = 26,
    // Generic composable-scene intents. Their recordIndex is the current
    // scene-node array index; projectionVersion prevents Cangjie from mapping
    // a queued intent onto a replacement node after a rebuild.
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE = 27,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_CHANGED = 28,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_BOOLEAN_CHANGED = 29,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SCROLL = 30,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FOCUS = 31,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_RESIZED = 32,
    // Selection is platform-owned query state. It never invokes a domain
    // action, but lets the live window projection answer a later read.
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED = 33,
    // Native emits only a normalized command name. Cangjie resolves it
    // through an application-provided binding to an ordinary control action.
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_WINDOW_COMMAND = 34,
    // A focused button inside a composable scroll area can delegate list
    // navigation to its Cangjie-owned range state. Text controls keep their
    // normal AppKit editing commands and never enter this route.
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE = 35,
    // Escape is a generic layer-dismiss request against the currently
    // rendered node identity. Cangjie decides whether that layer can close.
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_DISMISS_LAYER = 36,
    // Continuous pointer phases remain separate so a bounded FIFO may merge
    // only same-target updates and can never lose a terminal end/cancel.
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_BEGIN = 37,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE = 38,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_END = 39,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_CANCEL = 40,
    // An AppKit NSMenuItem never owns an application callback.  Its action
    // only carries the stable command id into the same bounded Cangjie FIFO
    // as the keyboard route, where the accepted scene revalidates it.
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_MENU_COMMAND = 41,
    // Standard AppKit Quit is only a process-level intent.  It is delivered
    // to the current Cangjie application turn, whose existing exit-decision
    // provider may reject it without closing any projection.
    CJGUI_INTERNAL_RENDERER_EVENT_APPLICATION_EXIT_REQUESTED = 42,
    // These are framework-owned visual interaction phases. They carry the
    // same copied scene identity as every other composable event; Cangjie
    // resolves paint from it, while native retains only short-lived mouse
    // routing needed to decide whether release may activate.
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_HOVER_ENTER = 43,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_HOVER_LEAVE = 44,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_PRESS_BEGIN = 45,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_PRESS_END = 46,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_PRESS_CANCEL = 47,
    // Native copies a bounded declared value and stable scene identity only.
    // Cangjie revalidates the target and invokes the established owner.
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_DATA_TRANSFER_COPY = 48,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_DATA_TRANSFER_PASTE = 49,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_DATA_TRANSFER_DROP = 50,
    // A file read is asynchronous: BEGIN reserves one receipt identity;
    // REJECTED settles it without invoking the image owner.
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FILE_TRANSFER_BEGIN = 53,
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FILE_TRANSFER_REJECTED = 54,
    // A human edit delivered as an edit DELTA instead of the whole value.
    // `selectionStart`/`selectionEnd` are the replaced UTF-16 range in the
    // version the value was projected from, and the form text is the inserted
    // replacement string. Consumers that need the resulting value keep the
    // existing TEXT_CHANGED event; a range-text consumer uses this one and never
    // has to diff the full text.
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED = 51,
    // A secondary pointer press is a context-menu request against the exact
    // accepted scene target. It never changes focus, selection or activation.
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_CONTEXT_MENU_REQUEST = 56,
    // One platform composition phase (IME marked text) routed to the single
    // window-owned Cangjie text session bound to this node. `formText` carries
    // the preedit on update (phase 1) or the final text on commit (phase 2);
    // cancel (phase 3) carries no text. Emitted ONLY while the window's
    // `set_composable_owned_text_session` declaration names this node with a
    // matching binding epoch; every other node keeps the ordinary text events
    // above and never receives this kind.
    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_COMPOSITION = 52
} CjguiInternalRendererEventKind;

typedef enum CjguiInternalRendererTextCompositionPhase {
    CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_UPDATE = 1,
    CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_COMMIT = 2,
    CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_CANCEL = 3
} CjguiInternalRendererTextCompositionPhase;

typedef enum CjguiInternalRendererDataTransferRole {
    CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_SOURCE = 1,
    CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_TARGET = 2
} CjguiInternalRendererDataTransferRole;

typedef enum CjguiInternalRendererComposableNodeKind {
    CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL = 1,
    CJGUI_INTERNAL_RENDERER_COMPOSABLE_HORIZONTAL = 2,
    CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT = 3,
    CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON = 4,
    CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT = 5,
    CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT = 6,
    CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT = 7,
    CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA = 8,
    CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE = 9,
    CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT = 10,
    CJGUI_INTERNAL_RENDERER_COMPOSABLE_LAYER_BACKDROP = 12,
    CJGUI_INTERNAL_RENDERER_COMPOSABLE_SPLIT_DIVIDER = 13,
    CJGUI_INTERNAL_RENDERER_COMPOSABLE_SLIDER = 14,
    // Bounded, Cangjie-described geometry. The payload is copied into the
    // existing generic scene-node value; this enum carries no GPU object or
    // public native rendering API.
    CJGUI_INTERNAL_RENDERER_COMPOSABLE_VECTOR_GRAPHIC = 15,
    CJGUI_INTERNAL_RENDERER_COMPOSABLE_TABS = 16,
    // One tab TITLE inside a tab container's title row. It is an ordinary
    // focusable/actionable composable node: activation and AX press enqueue the
    // SAME generic ACTIVATE interaction a button uses, and Cangjie resolves it
    // against the accepted tab state. No tab-specific native routing exists.
    CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE = 17
} CjguiInternalRendererComposableNodeKind;

// Config POD. Window geometry + clear color baseline. Layout matches the
// Cangjie @C struct.
typedef struct CjguiInternalRendererConfig {
    uint32_t windowWidth;
    uint32_t windowHeight;
    double clearColorRed;
    double clearColorGreen;
    double clearColorBlue;
    double clearColorAlpha;
} CjguiInternalRendererConfig;

// Clear color POD used by presentClear.
typedef struct CjguiInternalRendererClearColor {
    double red;
    double green;
    double blue;
    double alpha;
} CjguiInternalRendererClearColor;

// Frame observation POD returned by presentClear. Only POD scalars.
typedef struct CjguiInternalRendererFrameObservation {
    uint64_t frameIndex;            // 1-based frame index for this session
    uint32_t drawableWidthPixels;   // drawable pixel width
    uint32_t drawableHeightPixels;  // drawable pixel height
    double contentsScale;           // backing scale factor
    uint8_t readbackAttempted;      // 1 if readback was attempted this frame
    uint8_t readbackCompleted;      // command buffer completed (when attempted)
    uint8_t readbackColorMatched;   // sampled clear color matched (when attempted)
    // A1 票据协议：本次提交的票据编号。非 0 表示这张票据已登记在 native 的
    // 结算槽里，调用方必须经 query_present 取得终态并 acknowledge_present 确认。
    // 0 表示本次调用没有登记任何票据（同步成功即已接受/已拒绝，或未进入提交）。
    // 不能用 frameIndex 代替：frameIndex 只在接受后才推进，且不是每次提交唯一。
    uint64_t ticketId;
} CjguiInternalRendererFrameObservation;

// A0 ABI canary：布局漂移必须在编译期暴露（8+4+4+8+1+1+1+pad7+8 = 40 字节）。
// 仓颉 @C 镜像与全部调用方依赖此布局；改动本结构必须同步三处镜像并重跑 canary。
_Static_assert(sizeof(CjguiInternalRendererFrameObservation) == 40,
               "CjguiInternalRendererFrameObservation layout drifted");

// 一张提交票据的结算裁决（A1）。native 是唯一裁决点，核心只读它。
typedef enum CjguiInternalRendererPresentDecision {
    // 该会话没有这张票据（已确认过、从未登记、或身份不符）。核心本地仍持有
    // 该 ticket 时这是协议缺口，不得当成拒绝或重新开始的许可。
    CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_NONE = 0,
    // 仍未落定（native 已取得提交许可但结果未回）。候选与 accepted 都保留。
    CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_PENDING = 1,
    // 已接受：native accepted 与命中已切到该候选，帧号已推进一次。
    CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED = 2,
    // 已拒绝：候选丢弃、旧 accepted 保留，画面可能与候选分离。
    CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_REJECTED = 3
} CjguiInternalRendererPresentDecision;

// query_present 的回执 POD。终态一旦写入保持不变，重复查询返回相同结果。
typedef struct CjguiInternalRendererPresentReceipt {
    uint64_t ticketId;
    uint64_t projectionVersion;
    uint32_t decision;                      // CjguiInternalRendererPresentDecision
    int32_t terminalStatus;                 // 原生终态 status（Pending 时为 0）
    CjguiInternalRendererFrameObservation observation;  // Accepted 时的帧观察
    // 画面可能与刚提交的候选分离（Rejected），核心需要安排一次重新同步。
    uint8_t resyncRequired;
    // 终态已定（decision != PENDING）。ACK 之前该票据一直可查。
    uint8_t settled;
} CjguiInternalRendererPresentReceipt;

// Read-only progress observed from the live composable session. These scalar
// facts intentionally stop before a claim that a person has seen the window:
// Metal completion is recorded from an asynchronously completed command
// buffer, GPU duration is -1 when Metal did not make timing available, and
// overlay progress is known only after its AppKit drawRect ran.
// One committed backdrop submission. Mode describes encoded work; completion
// describes only that exact GPU submission, never physical window display.
typedef enum CjguiInternalRendererBackdropMode {
    CJGUI_INTERNAL_BACKDROP_UNAVAILABLE = 0,
    CJGUI_INTERNAL_BACKDROP_NONE = 1,
    CJGUI_INTERNAL_BACKDROP_BLURRED = 2,
    CJGUI_INTERNAL_BACKDROP_UNBLURRED = 3,
} CjguiInternalRendererBackdropMode;

typedef enum CjguiInternalRendererBackdropReason {
    CJGUI_INTERNAL_BACKDROP_REASON_NONE = 0,
    CJGUI_INTERNAL_BACKDROP_REASON_NOT_REQUESTED = 1,
    CJGUI_INTERNAL_BACKDROP_REASON_EMPTY_ROI = 2,
    CJGUI_INTERNAL_BACKDROP_REASON_NON_OPAQUE_CLEAR = 3,
    CJGUI_INTERNAL_BACKDROP_REASON_KERNEL_LIMIT = 4,
    CJGUI_INTERNAL_BACKDROP_REASON_RESOURCE_BUDGET = 5,
    CJGUI_INTERNAL_BACKDROP_REASON_ALLOCATION_FAILED = 6,
    CJGUI_INTERNAL_BACKDROP_REASON_PIPELINE_UNAVAILABLE = 7,
    CJGUI_INTERNAL_BACKDROP_REASON_ENCODE_FAILED = 8,
} CjguiInternalRendererBackdropReason;

typedef enum CjguiInternalRendererBackdropCompletion {
    CJGUI_INTERNAL_BACKDROP_COMPLETION_UNAVAILABLE = 0,
    CJGUI_INTERNAL_BACKDROP_COMPLETION_PENDING = 1,
    CJGUI_INTERNAL_BACKDROP_COMPLETION_SUCCEEDED = 2,
    CJGUI_INTERNAL_BACKDROP_COMPLETION_FAILED = 3,
} CjguiInternalRendererBackdropCompletion;

typedef struct CjguiInternalRendererComposableDisplayProgress {
    uint64_t submittedFrameIndex;
    uint64_t observedMetalCompletionFrameIndex;
    uint64_t observedMetalFailureFrameIndex;
    int64_t observedMetalGpuDurationMicros;
    uint64_t overlayDrawnProjectionVersion;
    uint64_t effectSubmittedSceneVersion;
    uint64_t effectSubmittedFrameIndex;
    uint32_t effectRequestedRadiusPoints;
    uint32_t effectMode;
    uint32_t effectFallbackReason;
    uint32_t effectCompletion;
    // One main-thread sample of current platform geometry. Point coordinates
    // retain subpoint precision; drawable dimensions are actual layer pixels.
    double currentPointWidth;
    double currentPointHeight;
    double currentBackingScale;
    uint32_t currentDrawableWidthPixels;
    uint32_t currentDrawableHeightPixels;
    uint64_t currentGeometryRevision;
    // These describe the latest successfully committed command, and may lag
    // current geometry after resize or a failed redraw.
    double submittedPointWidth;
    double submittedPointHeight;
    double submittedBackingScale;
    uint32_t submittedDrawableWidthPixels;
    uint32_t submittedDrawableHeightPixels;
    uint64_t submittedGeometryRevision;
    uint64_t submittedSceneVersion;
} CjguiInternalRendererComposableDisplayProgress;

// Experimental read-only developer geometry. Every range is from the last
// accepted native scene and last submitted drawable, in window points. Flags:
// 1 output, 2 actual backdrop sample, 4 sample target redrawn in this frame.
typedef struct CjguiInternalRendererDiagnosticNodeGeometry {
    uint64_t sceneVersion;
    uint64_t frameIndex;
    double outputX, outputY, outputWidth, outputHeight;
    double sampleX, sampleY, sampleWidth, sampleHeight;
    uint32_t flags;
    uint32_t reserved;
} CjguiInternalRendererDiagnosticNodeGeometry;

typedef struct CjguiInternalRendererDiagnosticResources {
    uint64_t sceneVersion;
    uint64_t frameIndex;
    uint64_t liveEffectBytes;
    uint64_t cachedEffectBytes;
    uint64_t overlayDrawCount;
} CjguiInternalRendererDiagnosticResources;

// Bounded workload scalars behind the diagnostics snapshot. The counters are
// saturating uint64 totals of real work points in this session (node writes,
// COW clones, node allocations, scene text-layout preparations, image decode
// starts); reusableResourceBytes is a current sum, not a total. They are
// counted in normal builds; no text, image or per-node record crosses here.
typedef struct CjguiInternalRendererDiagnosticWorkload {
    uint64_t sceneVersion;
    uint64_t frameIndex;
    uint64_t nodeWriteCount;
    uint64_t nodeCloneCount;
    uint64_t nodeAllocationCount;
    uint64_t textLayoutPreparationCount;
    uint64_t imageDecodeStartCount;
    uint64_t reusableResourceBytes;
    uint64_t textRasterCount;
    uint64_t textRasterBytes;
    uint64_t textRasterMicros;
    uint64_t textUploadCount;
    uint64_t textUploadBytes;
    uint64_t textUploadMicros;
    uint64_t textTextureLiveBytes;
    uint64_t textCandidatePeakBytes;
} CjguiInternalRendererDiagnosticWorkload;

// Fixed-size opt-in per-session timing totals. Durations are nanoseconds from
// mach_continuous_time; counts retain one window's position work only.
typedef struct CjguiInternalRendererDiagnosticTiming {
    uint64_t sceneVersion;
    uint64_t frameIndex;
    uint32_t enabled;
    uint32_t clockAvailable;
    uint64_t positionPrepareCount;
    uint64_t positionQueryCount;
    uint64_t positionLineBuildCount;
    uint64_t positionCacheHitCount;
    uint64_t positionPrepareNanoseconds;
    uint64_t positionQueryNanoseconds;
    uint64_t positionLineBuildNanoseconds;
    uint64_t encodeNanoseconds;
    uint64_t submitNanoseconds;
    uint64_t rasterNanoseconds;
    uint64_t uploadNanoseconds;
    uint64_t readCount;
    uint64_t readNanoseconds;
} CjguiInternalRendererDiagnosticTiming;

// P4 system window background projection. This is an internal POD mirror;
// AppKit host installation is not a claim that physical pixels were observed.
typedef struct CjguiInternalRendererWindowBackgroundSnapshot {
    uint64_t acceptedSceneVersion;
    uint64_t frameIndex;
    uint64_t requestRevision;
    uint64_t environmentRevision;
    uint64_t observationRevision;
    uint32_t requestedMode;       // 0=opaque, 1=system_content_area
    uint32_t backend;             // 0=unavailable, 1=appkit_behind_window
    uint32_t actualMode;          // 0=opaque, 1=system_host_installed, 2=opaque_fallback
    uint32_t fallbackReason;      // 0=not_requested,1=none,2=reduce_transparency,3=unsupported,4=material_prepare_failed,5=host_apply_failed,6=render_failed
    uint32_t completion;          // 0=pending, 1=succeeded, 2=failed
    uint32_t reduceTransparency;  // 0/1
    uint32_t windowActive;        // 0/1
    uint32_t colorScheme;         // 1=light, 2=dark
} CjguiInternalRendererWindowBackgroundSnapshot;

typedef enum CjguiInternalRendererWindowBackgroundMode {
    CJGUI_INTERNAL_WINDOW_BACKGROUND_OPAQUE = 0,
    CJGUI_INTERNAL_WINDOW_BACKGROUND_SYSTEM_CONTENT_AREA = 1,
} CjguiInternalRendererWindowBackgroundMode;

typedef enum CjguiInternalRendererWindowColorScheme {
    CJGUI_INTERNAL_WINDOW_COLOR_SCHEME_LIGHT = 1,
    CJGUI_INTERNAL_WINDOW_COLOR_SCHEME_DARK = 2,
} CjguiInternalRendererWindowColorScheme;

// Event POD returned by pumpEvent.
typedef struct CjguiInternalRendererEvent {
    uint32_t kind;   // CjguiInternalRendererEventKind
    uint32_t recordIndex;
    uint32_t selectionStart;
    uint32_t selectionEnd;
    // The rendered node identity is authoritative for composable intents.
    // recordIndex is retained only as local diagnostic/projection metadata.
    uint64_t nodeId;
    uint64_t projectionVersion;
    // A node ID alone is not a durable target: a dynamic scene may rebind
    // that slot to another resource or component type between queue and pump.
    int64_t resourceId;
    uint32_t nodeKind;
    // Logical points in the same top-left coordinate system as the Cangjie
    // layout and native hit test.  They are meaningful only for pointer
    // phases; selection fields retain their existing text-only meaning.
    int64_t pointerX;
    int64_t pointerY;
    // Keyboard modifier flags of the pointer event that produced this intent
    // (AppKit NSEventModifierFlag* bits). Non-pointer intents leave it 0.
    int64_t modifierFlags;
    // TEXT_COMPOSITION (kind 52) record. Zero for every other kind, so a
    // consumer that does not know this kind still reads a valid event.
    // `compositionPhase` is CjguiInternalRendererTextCompositionPhase;
    // `compositionId` is monotonic per native session and identifies one
    // composition across its update/terminal phases; `bindingEpoch` is the
    // window's binding generation at capture time, so an event queued before a
    // rebind is refused instead of editing the new session.
    uint32_t compositionPhase;
    // `replacementStart16`/`replacementLength16` describe the platform's
    // intended replacement in UTF-16 units of the node's CURRENT proxy text
    // (-1 location = the protocol's NSNotFound, i.e. "not specified").
    // `markedStart16`/`markedLength16` are the actual marked range read after
    // the platform mutation; a terminal phase may report -1/0 (no marked text).
    // The inner selection of an update reuses selectionStart/selectionEnd.
    int64_t replacementStart16;
    int64_t replacementLength16;
    int64_t markedStart16;
    int64_t markedLength16;
    uint64_t compositionId;
    uint64_t bindingEpoch;
    // Transfer events only: a one-shot FIFO identity for the binary byte
    // getter. It prevents a later pump from supplying another event's data.
    uint64_t dataTransferEventId;
    // Pointer identity and core-issued accepted binding are independent of
    // kind-52 composition bindingEpoch. Zero is never a pointer wildcard.
    uint64_t gestureAppInstance;
    uint64_t gestureComponentInstance;
    uint64_t gestureSurfaceGeneration;
    int64_t gesturePointerId;
    uint64_t gestureEpoch;
    uint64_t acceptedBindingEpoch;
} CjguiInternalRendererEvent;

// Layout: kind + recordIndex + selection pair (4x uint32), nodeId +
// projectionVersion + resourceId (3x 64), nodeKind (uint32 + 4 pad),
// pointer pair + modifiers (3x 64), then the kind-52 record as
// The existing 136-byte prefix plus six independent gesture/binding fields.
_Static_assert(sizeof(CjguiInternalRendererEvent) == 184,
               "CjguiInternalRendererEvent layout drifted");
_Static_assert(offsetof(CjguiInternalRendererEvent, gestureAppInstance) == 136 &&
               offsetof(CjguiInternalRendererEvent, acceptedBindingEpoch) == 176,
               "CjguiInternalRendererEvent gesture offsets drifted");

// Read immediately after pump_event. The exact point and the accepted node
// translation were captured together when this event entered the FIFO. This
// sidecar leaves the established event POD (including HarmonyOS mirrors) intact.
typedef struct CjguiInternalRendererPointerEventGeometry {
    uint32_t present;
    uint32_t kind;
    uint64_t nodeId;
    uint64_t projectionVersion;
    int64_t resourceId;
    uint32_t nodeKind;
    uint32_t reserved;
    double x;
    double y;
    double translateX;
    double translateY;
} CjguiInternalRendererPointerEventGeometry;

// One native coordination declaration for one format on an already-staged
// composable node. Format and UTF-8 payload are copied during the setter;
// Cangjie objects, business callbacks and pasteboard objects never enter this
// ABI. A source supplies payload; a target supplies an empty payload.
typedef struct CjguiInternalRendererComposableDataTransferItem {
    uint64_t nodeId;
    uint64_t projectionVersion;
    int64_t resourceId;
    uint32_t nodeKind;
    uint32_t role; // CjguiInternalRendererDataTransferRole
    uint32_t maximumPayloadBytes;
    int64_t sourceId;
    uint64_t bindingEpoch;
    int64_t expectedOwnerVersion;
    uint32_t localPngFileAllowed;
} CjguiInternalRendererComposableDataTransferItem;

// Generic scene node. Geometry uses top-left point coordinates supplied by
// the Cangjie layout engine. The C side copies labels/values immediately and
// never stores a Cangjie pointer. This remains an internal ABI.
typedef struct CjguiInternalRendererComposableNode {
    uint64_t nodeId;
    uint64_t projectionVersion;
    int64_t resourceId;
    int64_t x;
    int64_t y;
    int64_t width;
    int64_t height;
    int64_t clipX;
    int64_t clipY;
    int64_t clipWidth;
    int64_t clipHeight;
    uint32_t nodeKind;
    uint32_t isInteractive;
    // Text fields retain their visible value but never become a native edit
    // target when this is set. Disabled controls use isInteractive = 0.
    uint32_t isReadOnly;
    // Only multi-line inputs may opt in to literal Tab insertion. All other
    // controls retain window focus navigation behavior.
    uint32_t tabInsertsText;
    // The Cangjie owner has just accepted an edit originating from the active
    // native input proxy. The next projection may retain that proxy's text
    // rather than serializing the same complete value back through the ABI.
    // This is a one-shot transport hint, never a request to ignore an
    // external replacement.
    uint32_t preservesActiveLocalText;
    uint32_t borderWidth;
    // Logical corner geometry supplied by the Cangjie layout projection.
    // `clipCornerRadius` belongs to the inherited `clip*` rectangle.
    double cornerRadius;
    double clipCornerRadius;
    // The resolved layout carries the original geometry of every clipping
    // ancestor.  `clip*` above remains the conservative bounding rectangle
    // for old internal callers and scissor setup; these fixed slots are the
    // authoritative rounded-clip chain.  A zero count means one legacy slot.
    uint32_t clipConstraintCount;
    int64_t clip0X, clip0Y, clip0Width, clip0Height;
    double clip0CornerRadius;
    int64_t clip1X, clip1Y, clip1Width, clip1Height;
    double clip1CornerRadius;
    int64_t clip2X, clip2Y, clip2Width, clip2Height;
    double clip2CornerRadius;
    int64_t clip3X, clip3Y, clip3Width, clip3Height;
    double clip3CornerRadius;
    double fontSize;
    uint32_t fontWeight;
    // 0=system (including invalid/fallback requests), 1=monospaced system.
    uint32_t fontFamily;
    uint32_t imageContentMode;
    double fillRed;
    double fillGreen;
    double fillBlue;
    double fillAlpha;
    double borderRed;
    double borderGreen;
    double borderBlue;
    double borderAlpha;
    double textRed;
    double textGreen;
    double textBlue;
    double textAlpha;
    // Cangjie computes a bounded identity for the currently active layer
    // scope. It is only a focus-navigation partition, never authorization or
    // a native menu/dialog type.
    uint64_t inputScope;
    // The accepted tabs view-state identity and its selected title. Native Tab
    // traversal uses this projection to expose exactly one stop per group;
    // Cangjie remains the sole selection/focus owner.
    uint64_t tabGroupId;
    uint32_t tabSelected;
    // Platform-neutral accepted semantics. Selected and expanded are separate
    // from focus and paint; bit 0=selected, bit 1=expandable, bit 2=expanded,
    // bit 3=disabled. A semantic row may be an inert layout node containing
    // a separate actionable child, so disabled cannot be inferred from kind.
    uint32_t semanticRole;
    uint32_t semanticState;
    int64_t semanticLevel;
    int64_t semanticIncarnation;
    // ---- P1 shape effects (Cangjie @C mirror must match exactly) ----
    // These fields describe a single outer shadow and/or a single linear
    // gradient for this node. They never widen hit testing and never become a
    // native retained object: the renderer only copies scalars per frame.
    uint32_t shadowPresent;     // 1 = 绘制外阴影；0 = 无
    double shadowOffsetX;       // 逻辑点，+x 右
    double shadowOffsetY;       // 逻辑点，+y 下
    double shadowBlurRadius;    // 逻辑点，>=0，<=256；sigma = blur/2
    double shadowSpread;        // 逻辑点，>=0，<=128
    double shadowRed;
    double shadowGreen;
    double shadowBlue;
    double shadowAlpha;
    uint32_t gradientPresent;   // 1 = 线性渐变填充；0 = 纯色 fill*
    uint32_t gradientStopCount; // 2..4，按 position 升序
    double gradientStartX;      // 归一化 [0,1]，相对节点自身 box
    double gradientStartY;
    double gradientEndX;
    double gradientEndY;
    double gradientStop0Position;
    double gradientStop0Red;
    double gradientStop0Green;
    double gradientStop0Blue;
    double gradientStop0Alpha;
    double gradientStop1Position;
    double gradientStop1Red;
    double gradientStop1Green;
    double gradientStop1Blue;
    double gradientStop1Alpha;
    double gradientStop2Position;
    double gradientStop2Red;
    double gradientStop2Green;
    double gradientStop2Blue;
    double gradientStop2Alpha;
    double gradientStop3Position;
    double gradientStop3Red;
    double gradientStop3Green;
    double gradientStop3Blue;
    double gradientStop3Alpha;
    // ---- P4 isolated effect group (Cangjie @C mirror must match exactly) ----
    // The group begins at this node (including its own background/shadow) and
    // covers the relative preorder span [index, index + subtreeCount). A zero
    // present flag leaves the existing direct painter path unchanged.
    uint32_t effectGroupPresent;
    uint32_t effectGroupSubtreeCount;
    double effectGroupOpacity;
    uint32_t effectGroupBlendMode; // 0=normal, 1=multiply
    uint32_t effectMaskPresent;
    uint32_t effectMaskStopCount;
    double effectMaskStartX, effectMaskStartY, effectMaskEndX, effectMaskEndY;
    double effectMaskStop0Position, effectMaskStop0Alpha;
    double effectMaskStop1Position, effectMaskStop1Alpha;
    double effectMaskStop2Position, effectMaskStop2Alpha;
    double effectMaskStop3Position, effectMaskStop3Alpha;
    // ---- P4 in-app backdrop sample (Cangjie @C mirror must match exactly) ----
    uint32_t effectBackdropBlurRadiusPoints; // 0 disables; admitted range 1..16
    uint32_t effectBackdropBlurFallback; // 0=unblurred on resource/encode failure
    // ---- Wheel routing declaration ----
    // 1 = this node receives wheel gestures like a scroll area even though it
    // is not one (container-level wheel opt-in). The Cangjie side fills it
    // from style.wheelScrollable; hit routing matches it alongside
    // COMPOSABLE_SCROLL_AREA.
    uint32_t wheelScrollable;
    uint64_t acceptedBindingEpoch;
} CjguiInternalRendererComposableNode;
_Static_assert(offsetof(CjguiInternalRendererComposableNode, acceptedBindingEpoch) + 8 ==
               sizeof(CjguiInternalRendererComposableNode),
               "CjguiInternalRendererComposableNode binding tail drifted");

typedef struct CjguiInternalRendererViewport {
    uint32_t width;
    uint32_t height;
    uint64_t resizeVersion;
    // Monotonic only after an asynchronous image request reaches ready or
    // failed on the main thread. It is a refresh invalidation, not a frame
    // completion or visual-presentation claim.
    uint64_t resourceCompletionVersion;
} CjguiInternalRendererViewport;

// AppKit-shaped text metrics returned as scalars. This is an internal layout
// query only: Cangjie never receives NSFont/NSString pointers, and the native
// side does not retain the supplied text pointer after the call returns.
typedef struct CjguiInternalRendererTextMeasurement {
    uint32_t width;
    uint32_t height;
    uint32_t lineHeight;
    uint32_t baseline;
} CjguiInternalRendererTextMeasurement;

// Shared-operation window projection. This POD is a renderer input only: the
// Cangjie CjguiSharedOperationList remains the truth owner and pushes a fresh
// projection after every accepted or rejected action.
typedef struct CjguiInternalRendererSharedOperationState {
    int64_t selectedRecordId;
    uint64_t markedRecordMask;
    uint64_t version;
    uint32_t selectedRecordIndex;
    uint32_t recordCount;       // rows currently projected into the viewport
    uint32_t viewportStart;     // stable-list index of projected row zero
    uint32_t totalRecordCount;  // application record count; never truncated
} CjguiInternalRendererSharedOperationState;

// Returns the UTF-8 byte length of a prefix ending only at AppKit's composed
// character boundaries. The input is a caller-owned, scalar-safe scan window;
// native code copies it into NSString only for this call and returns no native
// object. When inputComplete is zero, a composed range touching the window's
// end is discarded because the caller may have clipped a longer source.
CjguiInternalRendererStatus
cjgui_internal_renderer_composed_prefix_utf8_length(
    const char *utf8, uint64_t inputBytes, uint64_t maxOutputBytes,
    uint64_t maxClusters, uint8_t inputComplete, uint64_t *outPrefixBytes);

// Invalid session token sentinel. Keep it distinct from the status enum's
// INVALID_SESSION=11; a macro with that enum name silently turned failed
// native calls into OK=0 after preprocessing.
#define CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN ((uint64_t)0)

// Enables the internal synchronous dispatch path from Cangjie scheduler
// workers to an already-running AppKit process main thread. Only the native
// macOS launcher may call this while on that main thread; it is not exposed to
// Cangjie and does not weaken AppKit's main-thread ownership.
void cjgui_internal_renderer_enable_main_thread_dispatch(void);

#ifdef CJGUI_INTERNAL_TESTING
// Isolated lifecycle probe: temporarily refuse worker calls, then restore the
// original AppKit dispatch route on the same live application instance.
CjguiInternalRendererStatus cjgui_internal_renderer_test_set_main_thread_dispatch_enabled(int enabled);
#endif

// Requests normal AppKit-loop termination after framework-owned application
// cleanup. It transfers no application state and retains no Cangjie object.
void cjgui_internal_renderer_request_application_stop(void);

// Clears the coalesced standard-Quit intent after its Cangjie application
// owner has made a decision. This carries no Cangjie object or decision value;
// the owner itself owns the resulting close or rejection.
void cjgui_internal_renderer_complete_application_exit_request(void);

// Application-owned multi-window hosts retain one scalar lifecycle reference
// while they have a live process-loop owner. It lets a standard Quit with no
// key window remain an application decision, without selecting an arbitrary
// renderer session. Legacy single-window hosts retain no reference and keep
// AppKit's explicit normal no-owner behavior.
void cjgui_internal_renderer_retain_application_exit_lifecycle_owner(void);
void cjgui_internal_renderer_release_application_exit_lifecycle_owner(void);

// Returns non-zero only for a pending standard Quit that had no key CJGUI
// window and has at least one application-lifecycle owner. The Cangjie
// application layer must establish that it is the unique active owner before
// consuming it, then acknowledge through complete_application_exit_request.
uint8_t cjgui_internal_renderer_has_unkeyed_application_exit_request(void);

// create(config) -> session token.
// Returns CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN on failure; status is
// written to *outStatus (which may be NULL only when a caller is fine
// ignoring it, but the bounded probe always passes a non-NULL pointer).
uint64_t cjgui_internal_renderer_create(const CjguiInternalRendererConfig *config,
                                        CjguiInternalRendererStatus *outStatus);

// Copies an application-provided title into an already-created native window.
// The string is consumed during the call; no Cangjie pointer is retained.
CjguiInternalRendererStatus
cjgui_internal_renderer_set_window_title(uint64_t session, const char *title);

// Opt in to explicit text edit deltas for composable text nodes. When
// enabled, each human edit is additionally delivered as
// CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED, whose
// selection fields are the replaced UTF-16 range and whose form text is the
// inserted replacement string. Disabled by default.
int32_t
cjgui_internal_renderer_set_composable_range_edit_delta(uint64_t session, int32_t enabled);

// Declare (or withdraw) the single composable text node whose platform
// composition phases belong to the window-owned text session. While the
// declaration names an ACTIVE node, its IME marked-text lifecycle is delivered
// as CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_COMPOSITION (kind 52)
// and the corresponding ordinary text events are suppressed for that intent.
// Every other node and every non-composition edit keeps the ordinary events.
// `bindingEpoch` is echoed back on each phase so a queued event from before a
// rebind can be refused by the window; `enabled = 0` withdraws the declaration.
CjguiInternalRendererStatus
cjgui_internal_renderer_set_composable_owned_text_session(uint64_t session, uint64_t nodeId,
                                                          int64_t resourceId, uint32_t nodeKind,
                                                          uint64_t bindingEpoch, uint32_t enabled);

// Install or withdraw one accepted Cangjie context-menu outside-click guard.
// The guard is session-scoped and identifies the layer through its accepted
// focus scope and root target; it does not extend the scene/event POD layout.
CjguiInternalRendererStatus
cjgui_internal_renderer_set_composable_context_menu_guard(uint64_t session, uint64_t sceneVersion,
    uint64_t layerScope, uint64_t requestId, uint64_t layerNodeId, int64_t resourceId,
    uint32_t nodeKind, int64_t x, int64_t y, int64_t width, int64_t height, uint32_t enabled);

// Roll back the hidden text proxy after the application refused a human range
// edit. Only restores text the owner already accepted; fails (and changes
// nothing) when the target is not the active node, the accepted value no longer
// matches the committed node, or a composition is in flight. Returns the
// installed UTF-16 selection through the out parameters.
CjguiInternalRendererStatus
cjgui_internal_renderer_recover_active_text_proxy(uint64_t session, uint64_t nodeId,
                                                  int64_t resourceId, uint32_t nodeKind,
                                                  const char *acceptedValue,
                                                  uint32_t *outSelectionStart, uint32_t *outSelectionEnd);

// presentClear(session, color) -> frame observation.
// Writes the frame observation into *outObservation and the status into
// *outStatus. Performs a real Metal clear, present and commit, and (on the
// first frame of a session) a readback probe.
CjguiInternalRendererStatus
cjgui_internal_renderer_present_clear(uint64_t session,
                                      const CjguiInternalRendererClearColor *color,
                                      CjguiInternalRendererFrameObservation *outObservation);

// Installs an entirely generic Cangjie-built scene. Existing legacy overlays
// are not consulted by this path. Initial frames and image-content changes
// run a focused non-clear diagnostic; text-only refreshes do not force a
// synchronous GPU readback.
CjguiInternalRendererStatus
cjgui_internal_renderer_configure_composable_scene(uint64_t session,
                                                    uint64_t projectionVersion,
                                                    uint32_t nodeCount);
// Versioned, value-only post-layout geometry sidecar. The existing integer
// composable node POD and its HarmonyOS snapshot ABI remain unchanged.
typedef struct {
    uint64_t nodeId;
    uint32_t clipCount;
    uint32_t reserved;
    double translateX;
    double translateY;
    double clip0X, clip0Y;
    double clip1X, clip1Y;
    double clip2X, clip2Y;
    double clip3X, clip3Y;
} CjguiInternalRendererComposableGeometry;
CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_scene_geometry(
    uint64_t session, uint64_t projectionVersion, uint32_t nodeIndex,
    const CjguiInternalRendererComposableGeometry *geometry);
// Release a rejected/uncommitted candidate's staged image holds. The accepted
// scene, GPU submissions and another window's domain references stay intact.
CjguiInternalRendererStatus cjgui_internal_renderer_discard_composable_scene_candidate(uint64_t session);

CjguiInternalRendererStatus
cjgui_internal_renderer_set_composable_scene_node(
    uint64_t session, uint32_t nodeIndex,
    const CjguiInternalRendererComposableNode *node,
    const char *label, const char *value, const char *imageResourcePath,
    const char *imageResourceId, uint64_t imageResourceVersion);
CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_scene_node_bytes(
    uint64_t session, uint32_t nodeIndex, const CjguiInternalRendererComposableNode *node,
    const char *label, const char *value, const char *imageResourcePath,
    const char *imageResourceId, uint64_t imageResourceVersion,
    const uint8_t *bytes, uint32_t length);
CjguiInternalRendererStatus cjgui_internal_renderer_prepare_composable_png_transfer(
    uint64_t session, const char *resourceIdentity, const uint8_t *bytes, uint32_t length,
    uint32_t *outWidth, uint32_t *outHeight, uint64_t *outDecodeMicros);
CjguiInternalRendererStatus cjgui_internal_renderer_finish_composable_png_transfer(
    uint64_t session, const char *resourceIdentity, uint8_t accepted);

// Records the accepted public semantic identity of one staged composable node.
// Kept separate from the node setter so existing native callers and probes keep
// their signature; the runtime calls it right after a successful node set.
CjguiInternalRendererStatus
cjgui_internal_renderer_set_composable_node_semantic_identity(uint64_t session,
                                                              uint32_t nodeIndex,
                                                              const char *semanticId);

// Value-only sidecar staged with the same scene node. The binding key changes
// when a local address targets a different owner/field/action; the row keys
// describe logical outline ancestry without materializing hidden rows.
CjguiInternalRendererStatus
cjgui_internal_renderer_set_composable_node_semantic_metadata(uint64_t session,
    uint32_t nodeIndex, const char *bindingKey, const char *rowKey, const char *parentRowKey,
    const char *semanticLabel);

// Replaces the complete native coordination declaration set (including an
// empty set) for this staged composable scene. Promotion is atomic with the
// scene presented by `present_composable_scene`.
CjguiInternalRendererStatus
cjgui_internal_renderer_configure_composable_data_transfer(uint64_t session,
                                                            uint64_t projectionVersion,
                                                            uint32_t itemCount);
CjguiInternalRendererStatus
cjgui_internal_renderer_set_composable_data_transfer_item(
    uint64_t session, uint32_t itemIndex,
    const CjguiInternalRendererComposableDataTransferItem *item,
    const char *format, const char *payload,
    const char *sourceKind, const char *sourceIdentity);
CjguiInternalRendererStatus
cjgui_internal_renderer_set_composable_data_transfer_item_bytes(
    uint64_t session, uint32_t itemIndex, const uint8_t *bytes, uint32_t length);

CjguiInternalRendererStatus
cjgui_internal_renderer_present_composable_scene(
    uint64_t session, CjguiInternalRendererFrameObservation *outObservation);

CjguiInternalRendererStatus
cjgui_internal_renderer_stage_window_background(uint64_t session,
                                                uint64_t projectionVersion,
                                                uint32_t mode,
                                                uint32_t colorScheme);
CjguiInternalRendererStatus
cjgui_internal_renderer_window_background_snapshot(
    uint64_t session, CjguiInternalRendererWindowBackgroundSnapshot *outSnapshot);

// A1 票据协议：把“提交新候选”和“查询原提交”拆成两个入口。
// `present_composable_scene` 仍然负责投递新候选（并在投递时登记票据），但它
// 不再承担“顺便结算上一张票据并可能提交新候选”的双重职责：只要该会话还有
// 未确认票据，它直接返回 PENDING 且不做任何结算、不投递新候选。
//
// query_present：只读终态。不得 configure、build、创建新 job 或再次 Flush。
// 终态一旦写入保持不变，重复查询返回相同结果。
CjguiInternalRendererStatus
cjgui_internal_renderer_query_present(
    uint64_t session, uint64_t ticketId, CjguiInternalRendererPresentReceipt *outReceipt);

// acknowledge_present：幂等。只回收回执并开放下一次提交，不再推进帧号，
// 不改变已接受的场景。ACK 之后同一 ticketId 的查询返回 decision=NONE。
CjguiInternalRendererStatus
cjgui_internal_renderer_acknowledge_present(uint64_t session, uint64_t ticketId);

// Internal test seam. It is inert in normal sidecars and cannot produce a
// pending ticket unless CJGUI_INTERNAL_TESTING is explicitly compiled in.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_hold_next_composable_present(uint64_t session);
CjguiInternalRendererStatus
cjgui_internal_renderer_test_resolve_pending_composable_present(uint64_t session);

// 票据取证计数（测试/验证用，只读）。available=0 表示该平台没有实现计数，
// 此时其余字段都不得被当作事实使用。
typedef struct CjguiInternalRendererPresentTicketStats {
    int64_t nextTicketId;                // session 下一个将分配的 ticketId
    int64_t unackedTicketId;             // 当前未 ACK 的 ticketId（0 = 无）
    int64_t acceptedCount;               // 已接受结算次数（唯一的 commit 次数）
    int64_t rejectedCount;               // 已拒绝结算次数（唯一的 rollback 次数）
    int64_t queryCount;                  // query_present 调用次数
    int64_t ackCount;                    // acknowledge_present 调用次数
    int64_t duplicateSettlementCount;    // 重复结算尝试（本应恒为 0；>0 即缺陷证据）
    int64_t destroyRefusedCount;         // 被 destroy 拒绝的次数（未结算）
    uint8_t available;                   // 1 = 本平台实现了计数
} CjguiInternalRendererPresentTicketStats;

CjguiInternalRendererStatus
cjgui_internal_renderer_present_ticket_stats(uint64_t session,
                                             CjguiInternalRendererPresentTicketStats *out);

// Stage one bounded, scalar command-menu projection alongside a composable
// scene candidate. Strings are copied during each setter; no Cangjie pointer
// or AppKit object crosses this internal ABI. The scene commit promotes it
// atomically with the input scene, while the explicit commit supports a
// command-state-only refresh against an already accepted scene version.
CjguiInternalRendererStatus
cjgui_internal_renderer_configure_composable_command_menu(
    uint64_t session, uint64_t projectionVersion, uint32_t itemCount);

CjguiInternalRendererStatus
cjgui_internal_renderer_set_composable_command_menu_item(
    uint64_t session, uint32_t itemIndex, const char *commandId,
    const char *title, const char *menuGroup, const char *shortcut,
    uint32_t menuSection, uint64_t focusScope, uint8_t enabled, uint8_t checked);

CjguiInternalRendererStatus
cjgui_internal_renderer_commit_composable_command_menu(uint64_t session);

// Starts or observes a bounded asynchronous image preparation owned by this
// renderer session. `outState` is one of 0=unrequested, 1=loading, 2=ready,
// 3=failed. Paths are copied during the call; native objects never cross this
// internal ABI. outState is unrequested(0), loading(1), ready(2), failed(3),
// or bounded-admission busy(4). Completion causes the viewport
// resourceCompletionVersion to advance, so normal Cangjie scheduling decides
// when to submit the next scene.
CjguiInternalRendererStatus
cjgui_internal_renderer_prepare_composable_image_resource(
    uint64_t session, const char *resourcePath, const char *resourceId,
    uint64_t resourceVersion, uint32_t *outState);

CjguiInternalRendererStatus
cjgui_internal_renderer_composable_image_resource_state(
    uint64_t session, const char *resourcePath, const char *resourceId,
    uint64_t resourceVersion, uint32_t *outState);

CjguiInternalRendererStatus
cjgui_internal_renderer_composable_viewport(uint64_t session,
                                             CjguiInternalRendererViewport *outViewport);

// Pure observation: this does not redraw, re-stage, or create an input event.
CjguiInternalRendererStatus
cjgui_internal_renderer_composable_display_progress(
    uint64_t session, CjguiInternalRendererComposableDisplayProgress *outProgress);

// Bounded, non-mutating reads; neither entry requests a scene refresh or GPU
// wait. The overlay is an AppKit view above the business drawing layers.
CjguiInternalRendererStatus
cjgui_internal_renderer_diagnostic_node_geometry(
    uint64_t session, uint32_t nodeIndex, CjguiInternalRendererDiagnosticNodeGeometry *outGeometry);
CjguiInternalRendererStatus
cjgui_internal_renderer_diagnostic_resources(
    uint64_t session, CjguiInternalRendererDiagnosticResources *outResources);
CjguiInternalRendererStatus
cjgui_internal_renderer_diagnostic_workload(
    uint64_t session, CjguiInternalRendererDiagnosticWorkload *outWorkload);
CjguiInternalRendererStatus
cjgui_internal_renderer_set_diagnostic_timing(uint64_t session, uint32_t enabled);
CjguiInternalRendererStatus
cjgui_internal_renderer_diagnostic_timing(
    uint64_t session, CjguiInternalRendererDiagnosticTiming *outTiming);
CjguiInternalRendererStatus
cjgui_internal_renderer_set_diagnostic_overlay(
    uint64_t session, uint32_t flags, uint64_t selectedNodeId, uint8_t hasSelection);

// The accepted rect (x, y, width, height) of one scene node.
CjguiInternalRendererStatus
cjgui_internal_renderer_node_rect(uint64_t session, uint64_t nodeId,
                                  int64_t *outX, int64_t *outY, int64_t *outWidth, int64_t *outHeight);

// Key/main/app-active state of the window, and an explicit activation entry point.
CjguiInternalRendererStatus
cjgui_internal_renderer_window_activation_state(uint64_t session, int32_t *outKey,
                                                int32_t *outMain, int32_t *outAppActive);
CjguiInternalRendererStatus
cjgui_internal_renderer_activate_window(uint64_t session);

// The window's on-screen frame in top-left origin coordinates, for a caller that
// must place a synthetic pointer or an overlay without guessing the position.
CjguiInternalRendererStatus
cjgui_internal_renderer_window_frame(uint64_t session, int64_t *outX, int64_t *outY,
                                     int64_t *outWidth, int64_t *outHeight);

// Read-only hit test for a composable text node: point in scene coordinates in,
// UTF-8 display byte offset plus caret affinity out.
CjguiInternalRendererStatus
cjgui_internal_renderer_hit_test_composable_text(uint64_t session, uint64_t nodeId,
                                                 double x, double y,
                                                 uint64_t expectedSceneVersion,
                                                 uint32_t *outByteOffset, uint32_t *outAffinity);

// ---- 版本化停靠点查询（Astra 正式裁决；旧 byte+affinity 查询为兼容投影） ----
// 把 (displayByte, branchIn[0=Upstream,1=Downstream,2=AUTO→primary 优先]) 解析为
// accepted 排版内的停靠点；输出停靠点字节/分支/所在行首字符与行长/显示 x。
// 软折行边界的 Upstream 分支按上一折出行解析；请求分支不可得具名拒绝。
CjguiInternalRendererStatus
cjgui_internal_renderer_text_position_v1(uint64_t session, uint64_t nodeId,
    uint64_t expectedSceneVersion, uint32_t op, int64_t displayByte, uint32_t renderSide,
    uint64_t layoutLease, uint64_t stopId, uint32_t direction,
    double x, double y, uint64_t *meta, double *rect);
// v1 operations: 0 resolve, 1 hit, 2 horizontal, 3 vertical; direction=0 left/up.
// meta[8]: lease, stop, byte, renderSide, platformBranch, lineGlyphStart,
// UTF-16 boundary, provedBoundary. rect[4]: scene x,y,width,height.
// These integers are identities, never native pointers. Layout ownership stays
// with the accepted node; a relayout invalidates its lease and stop table.
CjguiInternalRendererStatus
cjgui_internal_renderer_text_position_stats_v1(uint64_t session, uint64_t *counts);
// counts[4]: process-local prepares, queries, line builds, cache hits. Normal
// builds expose counts; durations are explicitly unavailable.
CjguiInternalRendererStatus
cjgui_internal_renderer_text_stop_resolve(uint64_t session, uint64_t nodeId,
                                           int64_t displayByte, uint32_t branchIn,
                                           uint64_t expectedSceneVersion,
                                           uint32_t *outByte, uint32_t *outBranch,
                                           uint32_t *outLineFirstChar,
                                           uint32_t *outLineLength, double *outX);

// 停靠点视觉邻位：从当前停靠点出发，同行按 primary+alternate 合并显示序取相邻
// 条目（alternate 独有条目是一次合法停靠），行端按硬/软换行规则跨行；已证实
// 排版边缘透传 (原字节, 原分支)。
CjguiInternalRendererStatus
cjgui_internal_renderer_text_stop_neighbor(uint64_t session, uint64_t nodeId,
                                            int64_t displayByte, uint32_t branchIn,
                                            uint32_t left, uint64_t expectedSceneVersion,
                                            uint32_t *outByte, uint32_t *outBranch);

// Install the style runs of one scene node. `encoded` is
// "start:end:fontSize:weight:family:r:g:b:a;..." in display byte offsets.
CjguiInternalRendererStatus
cjgui_internal_renderer_set_composable_text_runs(uint64_t session, uint64_t nodeId, const char *encoded);

CjguiInternalRendererStatus
cjgui_internal_renderer_measure_composable_text(uint64_t session,
                                                const char *text,
                                                double fontSize,
                                                uint32_t fontWeight,
                                                uint32_t fontFamily,
                                                uint32_t maximumWidth,
                                                CjguiInternalRendererTextMeasurement *outMeasurement);

// Preview: exact multiline input content height at its resolved content width.
// Uses the same TextKit line-breaking rules as the multiline scene/input path.
CjguiInternalRendererStatus
cjgui_internal_renderer_measure_composable_multiline_natural_height(
    uint64_t session, const char *text, double fontSize, uint32_t fontWeight,
    uint32_t fontFamily, uint32_t contentWidth, uint32_t *outHeight);

// Probe-only queue injection. It is compiled only when
// CJGUI_INTERNAL_TESTING is defined; normal consumers have no test ABI.
#ifdef CJGUI_INTERNAL_TESTING
// One actual Metal submission, sampled on the same mach continuous clock as
// the two-window producer. Callback times are host observations, not GPU clock
// timestamps or proof that the drawable reached a physical display.
typedef struct CjguiInternalRendererSubmissionTimeline {
    uint64_t sessionGeneration;
    uint64_t sceneVersion;
    uint64_t frameIndex;
    uint64_t stageBeginMicros;
    uint64_t encodeEndMicros;
    uint64_t presentCallMicros;
    uint64_t commitCallBeginMicros;
    // Retained name for probe compatibility: sampled after commit returns.
    uint64_t commitCallMicros;
    uint64_t scheduledMicros;
    uint64_t completedMicros;
    int32_t completionStatus;
} CjguiInternalRendererSubmissionTimeline;
CjguiInternalRendererStatus cjgui_internal_renderer_test_submission_timeline(
    uint64_t session, uint64_t frameIndex, CjguiInternalRendererSubmissionTimeline *outTimeline);
CjguiInternalRendererStatus cjgui_internal_renderer_test_composable_file_transfer(
    uint64_t session, uint64_t targetNodeId, const char *path, uint8_t asDrop);
CjguiInternalRendererStatus cjgui_internal_renderer_test_hold_next_file_read(uint64_t session);
CjguiInternalRendererStatus cjgui_internal_renderer_test_hold_next_file_after_first_read(uint64_t session);
CjguiInternalRendererStatus cjgui_internal_renderer_test_file_read_resources(
    uint32_t *outOpenDescriptors, uint32_t *outAcquiredScopes);
CjguiInternalRendererStatus cjgui_internal_renderer_test_wait_file_read_entered(uint64_t session);
CjguiInternalRendererStatus cjgui_internal_renderer_test_release_file_read(uint64_t session);

CjguiInternalRendererStatus
cjgui_internal_renderer_test_enqueue_composable_event(uint64_t session,
                                                       uint32_t nodeIndex,
                                                       uint32_t eventKind,
                                                       const char *text);

// Arms an independent TESTING producer on source A. The producer posts an
// ordinary event for B after A enters focused multiline preparation. Its
// timestamps include the interval blocked on A before main-thread FIFO
// admission, so a probe cannot move latency start to the next host turn.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_arm_midwork_composable_event(uint64_t sourceSession,
                                                           uint64_t targetSession,
                                                           uint32_t targetNodeIndex,
                                                           uint32_t eventKind,
                                                           const char *text,
                                                           uint32_t delayMicros);
// Test-only producer for non-text A work. It releases a previously armed
// identity-carrying B event on a background queue without holding A's stage.
CjguiInternalRendererStatus cjgui_internal_renderer_test_release_midwork_composable_event(
    uint64_t sourceSession);
// A bounded TESTING-only pause between presentDrawable and commit. The armed
// independent producer posts B during this exact CPU submit interval; the
// main-thread FIFO receives it after A returns. Never used for natural costs.
CjguiInternalRendererStatus cjgui_internal_renderer_test_arm_submit_gate(
    uint64_t sourceSession, uint32_t holdMicros);
CjguiInternalRendererStatus
cjgui_internal_renderer_test_midwork_composable_event_timing(uint64_t sourceSession,
                                                              uint64_t *outAStartMicros,
                                                              uint64_t *outAEndMicros,
                                                              uint64_t *outProducerReadyMicros,
                                                              uint64_t *outProducerPostMicros,
                                                              uint64_t *outNativeEnqueueMicros,
                                                              int32_t *outEnqueueStatus);
CjguiInternalRendererStatus
cjgui_internal_renderer_test_monotonic_micros(uint64_t *outMicros);

// Locates the actual NSMenuItem installed from an accepted command menu
// projection and performs its AppKit action. It is a test-only native seam,
// never a public Cangjie menu handle or direct FIFO injector.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_prepare_composable_command_menu(uint64_t session,
                                                              uint32_t *outReadinessFlags);

// Observes the normal application's current key window without selecting a
// session, changing activation, or mutating focus. Bits report main-thread,
// regular policy, running, active, visible, can-become-key, is-key and
// key-window-has-a-live-CJGUI-session respectively.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_observe_current_composable_command_menu(uint32_t *outReadinessFlags);

// Test-only focus-preparation request by the ordinary window title. It is
// separate from item selection and has no production analogue. The caller
// must subsequently let the normal application scheduler run and use the
// observation function above to prove that this window actually became key.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_prepare_composable_command_menu_window(const char *title,
                                                                     uint32_t *outReadinessFlags);

// Selects an already-installed menu item only when its session is the
// application's current key window. Frontmost/key preparation is deliberately
// a separate test step so this helper cannot conceal cross-window routing
// mistakes by changing focus for its session argument.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_invoke_composable_menu_item(uint64_t session,
                                                          const char *commandId);

// Selects the installed item for the current key window only. This keeps a
// normal consumer probe independent of the package-private session token.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_invoke_current_composable_menu_item(const char *commandId);

// Sends one command-key shortcut through NSApplication while the current
// key-window menu projection is live. This is test-only; it does not call the
// Cangjie command API or enqueue a FIFO record directly.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_dispatch_current_composable_command_shortcut(uint16_t keyCode,
                                                                            uint64_t modifiers,
                                                                            const char *characters);

// Sends one ordinary key event (for example an arrow or Home/End, with or
// without modifiers) through NSApplication into the production keyDown path of
// the key window. Test-only: the NSEvent is built here, while the routing,
// queue and FFI below it stay production code. It returns OK only when the
// event produced exactly one queued interaction, so a swallowed event is
// distinguishable from a delivered one.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_dispatch_current_composable_key(uint16_t keyCode, uint64_t modifiers,
                                                             const char *characters);

// Captures an actual NSMenuItem while one window is key, then later invokes
// that retained item's AppKit action without changing the current key window.
// It verifies stale native callbacks still resolve their target at execution.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_capture_current_composable_menu_item(const char *commandId);

CjguiInternalRendererStatus
cjgui_internal_renderer_test_invoke_captured_composable_menu_item(void);

// Reads only normal AppKit projection facts for the command-menu integration
// probe: the process-local rebuild count and presence of the standard app/text
// responder entries. It cannot select a command or change window focus.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_observe_composable_command_menu_projection(uint64_t *outRebuildCount,
                                                                          uint32_t *outStandardMenuFlags);

// Observes one item in the current AppKit menu without selecting it. Bits are
// enabled, checked and has-key-equivalent; this is test-only state evidence
// for an accepted external owner update.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_observe_current_composable_menu_item(const char *commandId,
                                                                    uint32_t *outStateFlags);

// Executes the installed standard Quit NSMenuItem through AppKit.  This is
// intentionally test-only: the normal application bridge must still decide
// process exit from its Cangjie-owned lifecycle turn.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_invoke_standard_quit_menu_item(void);

// Makes the process application hidden or visible through the ordinary AppKit
// path and reports whether a CJGUI key window remains.  It exists only to
// exercise an application-owned standard-Quit decision when no window is key;
// it never chooses a renderer session as an application owner.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_application_hidden(uint8_t hidden,
                                                     uint32_t *outNoKeyWindow);

// Reads whether the standard Edit responder items currently retain their
// Cmd-Z / Cmd-Shift-Z key equivalents (bits 0 and 1).  It does not select an
// item or mutate focus, and lets the normal-app probe distinguish owner
// command priority from a responder-chain fallback.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_observe_standard_edit_shortcuts(uint32_t *outShortcutFlags);

// Programmatic native event seam for the pointer-capture probe. It exercises
// the production overlay hit-test/capture route and does not enter the
// normal-consumer ABI.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_send_composable_pointer(uint64_t session,
                                                      uint32_t phase,
                                                      float pointX,
                                                      float pointY);

// Test-only one-shot press through the same overlay hit-test and ordinary
// activation route used by mouseDown. It is intentionally separate from the
// capture-only seam above so non-capturing interactive geometry can prove its
// exact hit shape without becoming a second pointer-control contract.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_activate_composable_point(uint64_t session,
                                                        float pointX,
                                                        float pointY);

// Drives one press lifecycle through the same production overlay branches as
// mouseDown/mouseDragged/mouseUp. Phase 1 is down, 2 is drag/move, 3 is up,
// and 4 is cancellation. It remains test-only so no platform event object is
// exposed through the Cangjie consumer ABI.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_send_composable_mouse(uint64_t session,
                                                    uint32_t phase,
                                                    float pointX,
                                                    float pointY);

// Invokes the same press/pointer cancellation path as a native key-window
// resignation. It is test-only: normal consumers never receive a platform
// object or an imperative focus-loss API.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_cancel_composable_platform_interaction(uint64_t session);

// Test-only scalar observability for the normal-window text-measurement
// cache. It is absent from the production sidecar ABI.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_measurement_count(uint64_t session,
                                                           uint32_t *outMeasurementCount);

CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_measurement_failures(uint64_t session,
                                                                  uint32_t failureCount);

// Probe-only candidate transaction seams.  They are omitted from normal
// sidecar builds, and only reject the next staged node write or presentation.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_scene_node_failures(uint64_t session,
                                                                 uint32_t failureCount);

CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_present_failures(uint64_t session,
                                                              uint32_t failureCount);


CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_window_background_environment(uint64_t session,
                                                                uint8_t reduceTransparency);
CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_window_background_failures(uint64_t session,
                                                             uint32_t prepareFailures,
                                                             uint32_t hostApplyFailures);

// Rejects the next derived text-texture admission before allocation.  This is
// a test-only substitute for an allocator/device failure and must leave the
// previous committed scene/input projection intact.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_text_preparation_failures(uint64_t session,
                                                                       uint32_t failureCount);

// Reads only the test seam's remaining injected failures.  It lets a probe
// distinguish a real rejected active-text admission plus retry from a path
// that silently skipped the failure boundary.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_text_preparation_failures_remaining(uint64_t session,
                                                                             uint32_t *outFailureCount);

// Holds only loader launch for the normal-window probe. It neither changes
// image state nor installs a fake completion, and is absent from normal ABI.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_image_launch_gate(uint64_t session,
                                                               uint8_t held);

// Narrow timing/accounting split for the resource probe. `asyncTotalMicros`
// is the complete MetalKit URL-loader interval; Apple's API does not expose
// separate file/decode/texture-upload subintervals, so callers must not
// relabel it as any one of those costs.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_image_pipeline_stats(
    uint64_t session, uint64_t *outPathResolveMicros, uint64_t *outCacheHitCount,
    uint64_t *outAsyncLaunchCount, uint64_t *outAsyncTotalMicros,
    uint32_t *outPeakInFlight, uint32_t *outPeakPending,
    uint64_t *outCacheBytes, uint64_t *outResourceCompletionVersion);

// Test-only scalar inspection of the bounded application+MTLDevice image
// domain. Reusable-cache bytes/entries are intentionally separate from
// committed scene texture references; neither pointer nor native object crosses
// the ABI. `subscriberCount` includes only live token+generation subscribers.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_application_image_domain_stats(
    uint64_t session, uint32_t *outReusableCacheEntries, uint64_t *outReusableCacheBytes,
    uint32_t *outInFlight, uint32_t *outPending, uint64_t *outActualLoadCount,
    uint64_t *outActualDecodeCount, uint32_t *outCommittedTextureRefs,
    uint32_t *outSubscriberCount, uint32_t *outActiveSessionCount,
    uint32_t *outResourceRecordCount);

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_scene_version(uint64_t session,
                                                       uint64_t *outSceneVersion);

// Scalar proof of the admitted text tile. It deliberately exposes neither a
// Metal texture nor its pixels; tests use it to distinguish a visible-range
// allocation from the old full-node backing store.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_text_resource_stats(uint64_t session,
                                                             uint32_t nodeIndex,
                                                             uint64_t *outByteCount,
                                                             float *outX, float *outY,
                                                             float *outWidth, float *outHeight);

// Per-allocation accounting for the actual accepted text textures. The union
// rectangle above cannot by itself prove that a large body was split.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_text_tile_stats(uint64_t session,
                                                         uint32_t nodeIndex, uint32_t tileIndex,
                                                         uint32_t *outTileCount, uint64_t *outTileBytes,
                                                         float *outX, float *outY,
                                                         float *outWidth, float *outHeight);

// Probe-only read of the accepted Metal texture, after raster/upload. A
// positive alpha count shows that a planned tile contains actual glyph pixels.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_text_tile_alpha_pixels(uint64_t session,
                                                                uint32_t nodeIndex, uint32_t tileIndex,
                                                                uint64_t *outNonzeroAlphaPixels);

// Selection decorations are scene geometry, independent of body textures.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_text_selection_rect_stats(uint64_t session,
                                                                  uint32_t nodeIndex,
                                                                  uint32_t *outRectCount,
                                                                  float *outMinY, float *outMaxY);

// Programmatic viewport geometry for controlled large-window probes. The
// returned size is AppKit's actual content view, never the requested size.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_content_size(uint64_t session,
                                                         uint32_t width, uint32_t height,
                                                         uint32_t *outActualWidth,
                                                         uint32_t *outActualHeight);

// Test-only oversized logical viewport. The actual NSWindow remains bounded
// by the display; only its owned content view/drawable is enlarged for a
// controlled raster and submit check.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_viewport_size(uint64_t session,
                                                          uint32_t width, uint32_t height,
                                                          uint32_t *outViewWidth,
                                                          uint32_t *outViewHeight);

// Reports the bounded retry state for an active multiline derived texture.
// This is probe-only observability for transient allocation recovery.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_active_text_resource_state(uint64_t session,
                                                                    uint8_t *outFailed,
                                                                    uint32_t *outRetryCount);

// Test-only count of committed generic nodes and actual Cangjie-to-native
// node writes. It proves staged-node reuse without exposing an Objective-C or
// Metal object through the production ABI.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_scene_update_stats(uint64_t session,
                                                            uint32_t *outCommittedNodeCount,
                                                            uint64_t *outNodeUpdateCount);

// Test-only wheel-region query: which scene node owns a scroll gesture at a
// point in SCENE coordinates, and how it earned that ownership (scroll area, or
// a container that declared wheelScrollable). It answers the production
// `scrollNodeContainingPoint` rule without posting a platform event, so a probe
// can assert that a container's NEW bounds respond and its OLD bounds no
// longer do. No native object crosses the boundary: node id and two flags out.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_scroll_owner_at_point(uint64_t session, double x, double y,
                                                              uint64_t *outNodeId,
                                                              uint32_t *outIsScrollArea,
                                                              uint32_t *outWheelScrollable);

// Test-only native submission counters. The values are cumulative scalar
// observations for one process; callers take deltas around a declared sample
// and keep them separate from Cangjie build/layout and Metal completion.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_scene_submission_stats(
    uint64_t session,
    uint64_t *outCloneCount,
    uint64_t *outNodeAllocationCount,
    uint64_t *outConfigureMicros,
    uint64_t *outSetMicros,
    uint64_t *outCommitMicros);

// Cost observability for the normal composable interaction path. These are
// process-local counters compiled only into probes; they neither expose a
// native object nor add a production renderer ABI.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_interaction_stats(uint64_t session,
                                                           uint32_t *outPendingInteractionCount,
                                                           uint32_t *outMaxPendingInteractionCount,
                                                           uint64_t *outAccessibilityNotificationCount);
// Test-only causal trace for a failed layer/key regression. It exposes scalar
// FIFO provenance only; no native object, text content, or business callback
// crosses the framework boundary.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_interaction_trace(uint64_t session,
                                                           uint32_t *outPendingInteractionCount,
                                                           uint32_t *outLastEnqueuedKind,
                                                           uint64_t *outLastEnqueuedNodeId,
                                                           uint64_t *outLastEnqueuedProjectionVersion,
                                                           uint32_t *outLastPumpedKind,
                                                           uint64_t *outLastPumpedNodeId,
                                                           uint64_t *outLastPumpedProjectionVersion);
// Test-only process snapshot used to compare an active workload with a later
// idle turn. Values are diagnostics, not a release-performance claim.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_process_resource_stats(uint64_t session,
                                                     uint64_t *outResidentBytes,
                                                     uint64_t *outUserMicros,
                                                     uint64_t *outSystemMicros);

// Test-only equivalent of a platform-invalidated Metal view. A following
// presentation must fail before command-buffer submission; this lets the
// normal window regression prove it does not invent a GPU completion for a
// no-drawable/view-invalidated path.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_invalidate_composable_drawable(uint64_t session);

// Test-only exact drawable-pixel capture. The caller supplies a logical
// point in the current composable viewport before presenting; the native
// renderer copies that actual BGRA drawable pixel after its normal encoder
// finishes. It exposes neither an image nor a native handle.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_request_composable_drawable_pixel(uint64_t session,
                                                                uint32_t pointX,
                                                                uint32_t pointY);
CjguiInternalRendererStatus
cjgui_internal_renderer_test_request_composable_drawable_pixel_precise(uint64_t session,
                                                                       double pointX,
                                                                       double pointY);
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_drawable_pixel(uint64_t session,
                                                        uint8_t *outBlue, uint8_t *outGreen,
                                                        uint8_t *outRed, uint8_t *outAlpha);

// Cumulative per-session facts for the P4 offscreen targets. current/peak
// account for all live accepted, candidate and in-flight target generations;
// no retired target pool is kept. A pass is one target content encode and a
// composite draw is one fixed-function blend draw (multiply needs two).
typedef struct CjguiInternalRendererEffectStats {
    uint64_t targetAllocations;
    uint64_t targetReuses;
    uint64_t targetCurrentBytes;
    uint64_t targetPeakBytes;
    uint64_t contentRedraws;
    uint64_t offscreenPasses;
    uint64_t compositeDraws;
    uint64_t backdropPrefixPasses;
    uint64_t backdropHorizontalPasses;
    uint64_t backdropVerticalPasses;
    uint64_t backdropCacheHits;
    uint64_t backdropFallbacks;
} CjguiInternalRendererEffectStats;

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_effect_stats(uint64_t session,
                                                      CjguiInternalRendererEffectStats *outStats);

// Probe-only one-shot failure after a normal accepted redraw encoded at least
// one effect target, before the main drawable encoder or command-buffer commit.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_fail_next_composable_main_encoder_after_effects(uint64_t session);
CjguiInternalRendererStatus
cjgui_internal_renderer_test_fail_next_composable_backdrop_encode(uint64_t session);

// Creates a small opaque local PNG fixture only for native renderer probes.
// The test still exercises normal file URL decode, texture creation, draw and
// drawable readback; this avoids embedding user assets or a second decoder.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_write_solid_image_fixture(const char *path,
                                                        uint8_t red, uint8_t green,
                                                        uint8_t blue, uint8_t alpha);

CjguiInternalRendererStatus
cjgui_internal_renderer_test_write_solid_image_fixture_sized(const char *path,
                                                              uint32_t width, uint32_t height,
                                                              uint8_t red, uint8_t green,
                                                              uint8_t blue, uint8_t alpha);

// Encoder-work scalars for the latest composable Metal frame. Consecutive
// shape nodes may share one vertex upload/draw; image and text textures stay
// explicit painter-order boundaries. This is test-only and never exports a
// Metal object or production renderer capability.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_encoder_stats(uint64_t session,
                                                       uint32_t *outShapeNodeCount,
                                                       uint32_t *outShapeBatchCount,
                                                       uint32_t *outTextureDrawCount,
                                                       uint64_t *outShapeVertexBytes);

// Actual stride and largest single `setVertexBytes` submission from the
// latest composable frame. This is test-only scalar observability for the
// documented Metal 4 KiB input ceiling; total shapeVertexBytes may span
// multiple ordered submissions.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_encoder_batch_stats(uint64_t session,
                                                             uint32_t *outVertexStride,
                                                             uint64_t *outMaxShapeBatchVertexBytes);

// CPU wall interval inside CjguiEncodeComposableNodes for the latest
// submitted frame. It excludes Metal completion/presentation and is exposed
// only to compare equivalent test scenes.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_encoder_cpu_stats(uint64_t session,
                                                           uint64_t *outEncodeMicros);

// Latest composable frame's native call spans. `nextDrawable` is measured
// directly rather than inferred from a larger stage interval; command-buffer,
// present and commit calls are separate CPU spans. `readbackWait` is non-zero
// only when that frame synchronously waited for a diagnostic/readback. These
// test-only scalars do not report GPU completion or physical presentation.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_present_timing_stats(
    uint64_t session,
    uint64_t *outNextDrawableMicros,
    uint64_t *outCommandBufferMicros,
    uint64_t *outPresentMicros,
    uint64_t *outCommitMicros,
    uint64_t *outReadbackWaitMicros,
    uint8_t *outReadbackWaited);

// Latest-frame facts for compact vector-buffer submission. `outBufferUploads`
// and `outBufferUploadBytes` describe topology allocations made by that frame;
// `outBufferReuses` describes already accepted per-node buffers bound again for
// paint/layout/clip changes. Resident bytes remain owned by accepted native
// nodes and are retained through in-flight command-buffer completion.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_vector_submission_stats(uint64_t session,
                                                                 uint32_t *outDrawCount,
                                                                 uint32_t *outBufferUploads,
                                                                 uint32_t *outBufferReuses,
                                                                 uint64_t *outBufferUploadBytes,
                                                                 uint64_t *outResidentBytes);

// Test-only scalar ownership/preparation facts for vector render-path probes.
// `outMultisampleAttachmentBytes` is the declared private 4x color attachment
// byte cost for the latest submitted frame (0 on the ordinary drawable path),
// not total GPU process memory or completion timing.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_vector_render_stats(
    uint64_t session,
    uint8_t *outSampleCount,
    uint64_t *outMultisampleAttachmentBytes,
    uint64_t *outPipelineBuildCount,
    uint64_t *outGeometryPreparationCount,
    uint64_t *outGeometryPreparedBytes);

// Test-only selector for comparing two legal shape submission strategies on
// the same scene: one complete rectangle per setVertexBytes call versus
// capacity-bounded consecutive rectangles. This never crosses the shipped
// renderer ABI.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_shape_submission_mode(uint64_t session,
                                                                    uint8_t mode);

// Test-only state of the deferred active-text resource continuation. This
// distinguishes a scheduled retry from a completed derived texture without
// exposing the overlay, AppKit view, or Metal resource.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_active_text_resource_preparation_state(uint64_t session,
                                                                                 uint8_t *outScheduled,
                                                                                 uint8_t *outFailed,
                                                                                 uint32_t *outRetryCount);

// Cumulative actual text-work counters for one isolated native session.
// Raster is the offscreen AppKit bitmap + normalization interval; upload is
// the subsequent texture `replaceRegion` interval. They do not imply that a
// frame reached the GPU or display and are test-only scalar observability.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_text_work_stats(uint64_t session,
                                                         uint64_t *outRasterCount,
                                                         uint64_t *outRasterBytes,
                                                         uint64_t *outRasterMicros,
                                                         uint64_t *outUploadCount,
                                                         uint64_t *outUploadBytes,
                                                         uint64_t *outUploadMicros);

// Per-reason cumulative raster/upload counts for the continuous-editing
// baseline. Reason slots are fixed and ordered: unknown, static_candidate,
// active_content, selection_caret, visible_tile_scroll, retry,
// projection_geometry, external_projection_content. The last two scalars bind
// the most recently admitted work to an owner projection and UTF-8 content
// size without exporting document text.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_text_work_reason_stats(
    uint64_t session,
    uint64_t *outUnknownRaster, uint64_t *outStaticCandidateRaster,
    uint64_t *outActiveContentRaster, uint64_t *outSelectionCaretRaster,
    uint64_t *outVisibleTileScrollRaster, uint64_t *outRetryRaster,
    uint64_t *outProjectionGeometryRaster, uint64_t *outExternalProjectionContentRaster,
    uint64_t *outUnknownUpload, uint64_t *outStaticCandidateUpload,
    uint64_t *outActiveContentUpload, uint64_t *outSelectionCaretUpload,
    uint64_t *outVisibleTileScrollUpload, uint64_t *outRetryUpload,
    uint64_t *outProjectionGeometryUpload, uint64_t *outExternalProjectionContentUpload,
    uint64_t *outLastProjectionVersion, uint64_t *outLastContentUtf8Bytes);

// Classifies staged-reachable text textures against committed-reachable ones
// (TESTING only). `candidate_only` counts staged textures absent from the
// committed set; `shared` counts staged textures the committed scene also
// holds; `candidate_only_node_bytes` sums the derived byte counts of
// staged-only nodes that show no accepted texture object. A rejected
// candidate must leave candidate_only == 0 while committed sets stay intact.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_text_candidate_stats(
    uint64_t session,
    uint64_t *outCommittedUniqueTextureCount, uint64_t *outStagedUniqueTextureCount,
    uint64_t *outCandidateOnlyTextureCount, uint64_t *outSharedTextureCount,
    uint64_t *outCandidateOnlyNodeBytes);

// Cumulative setNodesFromProjection phase wall times (TESTING only): the
// accessibility rebuild, the focused-input reconciliation, and the active
// refresh. Callers take deltas around a declared sample.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_projection_timing_stats(
    uint64_t session, uint64_t *outAccessibilityMicros, uint64_t *outInputMicros,
    uint64_t *outRefreshMicros);

// CPU staging (the shared BGRA raster bitmap) current and peak bytes. Current
// must return to zero outside an active raster; peak is reported separately
// from Metal texture bytes and is not a whole-process figure.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_text_cpu_scratch_stats(
    uint64_t session, uint64_t *outCurrentBytes, uint64_t *outPeakBytes);

// Sub-interval attribution inside text rasters. These cover distinct steps
// (draw-with-layout, premultiplication normalize, texture creation) and MUST
// NOT be summed with the outer per-reason raster wall time into a total.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_text_interval_stats(
    uint64_t session, uint64_t *outStaticDrawWithLayoutMicros, uint64_t *outNormalizeMicros,
    uint64_t *outTextureCreateMicros);

// Test-only observability for the active multiline AppKit input adapter. The
// values prove it remains nearly transparent while the composable overlay,
// not NSTextView/NSScrollView, owns the visible document viewport.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_multiline_proxy_opacity(uint64_t session,
                                                                 float *outScrollAlpha,
                                                                 float *outTextAlpha);

// Drives the production multiline viewport scroll path and exposes the
// resulting local offset plus the number of glyphs in its visible fragment.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_scroll_composable_multiline(uint64_t session,
                                                          float deltaY,
                                                          float *outScrollOffset,
                                                          uint32_t *outVisibleGlyphCount);

// TESTING-only view of the active, accepted multiline viewport. A negative
// maximum means its exact content extent has not been established yet.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_multiline_viewport(uint64_t session, const char *marker,
                                                            float *outScrollOffset, float *outMaximumOffset,
                                                            uint32_t *outVisibleCharacterStart,
                                                            uint32_t *outVisibleCharacterLength,
                                                            uint64_t *outProjectionVersion,
                                                            int *outMarkerFullyVisible);

// Drives the overlay's normal down/drag/up event methods with AppKit mouse
// events expressed in composable-view coordinates. It is test-only so the
// public framework never exposes native event or text-view objects.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_drag_composable_text_selection(uint64_t session,
                                                             uint32_t nodeIndex,
                                                             float startX, float startY,
                                                             float endX, float endY,
                                                             uint32_t *outSelectionStart,
                                                             uint32_t *outSelectionEnd);

// Assigns a UTF-16 range through the actual TextKit adapter. The production
// bridge clamps it to composed-character boundaries before any selection
// event is published.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_selection(uint64_t session,
                                                       uint32_t nodeIndex,
                                                       uint32_t selectionStart,
                                                       uint32_t selectionEnd);

// Reads the focused TextKit adapter's UTF-16 selection after a projection.
// Test-only scalar evidence for edit-range remapping; no native object escapes.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_selection(uint64_t session,
                                                  uint32_t *outSelectionStart,
                                                  uint32_t *outSelectionEnd);

// Compares the focused TextKit adapter value with an expected UTF-8 string.
// Test-only scalar predicate; it never exposes an NSTextView or its content
// through the public framework surface.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_text_matches(uint64_t session,
                                                      const char *expected);

// Verifies, as scalar test evidence, that the active multiline adapter still
// holds the CTFont fallback selected for each composed character.  It does
// not expose an NSTextView, storage, font, or rendered pixels to Cangjie.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_multiline_fallback_runs(uint64_t session,
                                                                 uint32_t *outExpectedFallbackRuns,
                                                                 uint32_t *outMismatchedRuns);

// Inserts through the currently selected range of the real focused TextKit
// adapter. Unlike the replacement helper, this preserves the user's local
// caret/selection and is used by long-document position regressions only.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_insert_composable_text(uint64_t session,
                                                     uint32_t nodeIndex,
                                                     const char *text);

// Mirrors a user deleteBackward through the same hidden NSTextView adapter.
// Test-only and used to keep long-text insert/delete measurements symmetric.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_delete_composable_text(uint64_t session,
                                                     uint32_t nodeIndex);

// Direct responder control used only to compare against the real
// NSApplication dispatch seam below. It never appears in the framework API.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_send_composable_key(uint64_t session,
                                                  uint16_t keyCode,
                                                  uint64_t modifiers,
                                                  uint64_t *outFocusedNodeId);

// Dispatches a synthetic key through NSApplication to its NSWindow responder
// chain. routeFlags are test-only scalar facts: application, target-is-key,
// app-key-window-is-target, overlay-is-first-responder, overlay-received.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_dispatch_composable_key_through_application(
    uint64_t session, uint16_t keyCode, uint64_t modifiers, uint64_t *outFocusedNodeId,
    uint32_t *outRouteFlags);

// Retains one AX element across controlled scene replacement so the window
// probe can prove that a removed/rebound element cannot act on a new object.
// Test-only; it does not expose an accessibility object to Cangjie.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_capture_composable_accessibility_action(uint64_t session,
                                                                       uint32_t nodeIndex);
CjguiInternalRendererStatus
cjgui_internal_renderer_test_invoke_captured_composable_accessibility_action(uint64_t session);

// Same retention as above, but the element is addressed by its stable nodeId
// instead of a positional index. The desktop chain's Accessibility press is
// resolved by the element's identity, and a probe that guessed an index would
// silently press a different control. Test-only; no accessibility object is
// exposed to Cangjie.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_capture_composable_accessibility_action_for_node(uint64_t session,
                                                                             uint64_t nodeId);

// Resolves a point through the production composable z-order and invokes the
// same mouse target router as an AppKit mouse-down.  It exists only to prove
// that a modal backdrop blocks the base scene; it exposes no native view.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_click_composable_point(uint64_t session,
                                                     float pointX,
                                                     float pointY);

// Causes an actual AppKit content-size transition for a composable test
// window and returns the renderer's resulting resize revision. This exists
// solely to exercise the production resize invalidation path.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_resize_composable_window(uint64_t session,
                                                       uint64_t *outResizeVersion);

// Test-only controlled backing-scale transition. The helper changes no point
// bounds and drives the normal NSWindow backing-properties notification; it
// returns scalar drawable facts only and is absent from production sidecars.
#ifdef CJGUI_INTERNAL_TESTING
// For an isolated test process with exactly one live window. Returns zero if
// there are none or several, so a consumer probe cannot select another owner.
uint64_t cjgui_internal_renderer_test_sole_live_session_token(void);
CjguiInternalRendererStatus
cjgui_internal_renderer_test_toggle_composable_backing_scale(
    uint64_t session, uint64_t *outResizeVersion,
    double *outBeforeScale, double *outAfterScale,
    uint32_t *outDrawableWidth, uint32_t *outDrawableHeight);

// Probe the native painter dependency after accepted text preparation without
// changing scene bytes, texture, or caret geometry. This is test-only because
// production derives the flag from its text/caret preparation path.
CjguiInternalRendererStatus cjgui_internal_renderer_test_set_composable_caret_color_source(
    uint64_t session, uint64_t nodeId, double x, double y, double width, double height,
    uint32_t declared);
// action: 0 installs a manual monotonic clock and resets visible; 1 advances
// it to nowMicros; 2 returns to the platform clock; 3 stops the blink. The
// accepted caret rectangle is never removed by a phase change.
CjguiInternalRendererStatus cjgui_internal_renderer_test_caret_blink_clock(
    uint64_t session, uint32_t action, uint64_t nowMicros,
    int32_t *outVisible, int32_t *outHasCaretRect, uint64_t *outDeadlineMicros);
#endif

// Drives Cmd-C/X/V through the actual composable NSTextView first responder.
// The test saves and restores every general-pasteboard item; it never returns
// clipboard contents to Cangjie or to a test log.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_standard_editing_commands(uint64_t session);

// Verifies that an IME candidate rect comes from the self-drawn composable
// text viewport rather than the off-canvas NSTextView adapter.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_candidate_rect(uint64_t session,
                                                        uint32_t location,
                                                        uint32_t length,
                                                        float *outX,
                                                        float *outY,
                                                        float *outWidth,
                                                        float *outHeight);

// Forces two normal display passes after a multiline editor is inactive.
// GPU-derived text owns those inactive pixels, so the only TextKit graph must
// remain the active input adapter: no inactive layout cache may be built.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_multiline_layout_ownership(uint64_t session,
                                                                     uint32_t *outInactiveCacheEntries,
                                                                     uint32_t *outInactiveCacheHighWater,
                                                                     uint64_t *outBuildsAfterFirstPass,
                                                                     uint64_t *outBuildsAfterSecondPass);

// Splits the synchronous cost of one real AppKit text insertion so the probe
// can distinguish TextKit mutation from the renderer's delegates and
// accessibility projection. Test-only observability; no native object or
// callback crosses the framework boundary.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_input_timing(uint64_t session,
                                                      uint64_t *outMutationMicros,
                                                      uint64_t *outTextDelegateMicros,
                                                      uint64_t *outSelectionDelegateMicros,
                                                      uint64_t *outEventEnqueueMicros,
                                                      uint64_t *outAccessibilityMicros);

// Test-only scalar trace for a real input-proxy insertion. The mode switch
// controls an existing adapter setting only in testing; it neither changes
// the normal default nor exposes an AppKit object through the framework.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_bounded_input_layout(uint64_t session, uint8_t enabled);

// Test-only one-shot selection A/B: 0 reuses the accepted body resource; 1
// forces the existing full body rasterize/upload path for the next selection.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_selection_body_preparation_mode(uint64_t session, uint8_t mode);

#ifdef CJGUI_INTERNAL_TESTING
// Selects the complete replacement algorithm for exactly one projection;
// content, style and viewport remain unchanged for a paired A/B probe.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_force_full_projection_replacement_once(uint64_t session);
#endif

CjguiInternalRendererStatus
cjgui_internal_renderer_test_reset_composable_input_callback_trace(uint64_t session);

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_input_callback_trace(
    uint64_t session,
    uint64_t *outSuperInsertMicros, uint64_t *outModeChangeCount,
    uint64_t *outModeChangeMicros, uint64_t *outTextCallbackCount,
    uint64_t *outTextCallbackMicros, uint64_t *outSelectionCallbackCount,
    uint64_t *outPendingEditSelectionCount, uint64_t *outSelectionCallbackMicros,
    uint64_t *outSelectionRevealMicros, uint64_t *outSelectionQueueMicros,
    uint64_t *outSelectionAccessibilityMicros, uint64_t *outRefreshMicros,
    uint64_t *outPreparationMicros, uint64_t *outWholeAttributeWriteCount,
    uint64_t *outWholeAttributeCharacters, uint64_t *outFallbackApplyCount,
    uint64_t *outFallbackCharacters, uint64_t *outFallbackMicros);

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_text_substage_stats(uint64_t session,
    uint64_t *outDecorationsMicros, uint64_t *outKeyConstructionMicros,
    uint64_t *outPreparationMicros, uint64_t *outFallbackMicros,
    uint64_t *outFallbackApplyCount, uint64_t *outFallbackCharacters);

// Counts the overlay's explicit, range-scoped TextKit layout requests and
// deliberate whole-container requests. It lets the normal-window probe prove
// that a draw/selection/scroll sequence did not silently fall back to a full
// document layout. Test-only scalar observability.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_active_layout_work_counts(uint64_t session,
                                                                   uint64_t *outRangeLayoutCount,
                                                                   uint64_t *outFullLayoutCount);

// Resets/reads scalar timing and SDK-visible invalidation state for active
// TextKit range requests. Test-only observability; this does not expose a
// native object or add a public framework contract.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_reset_composable_active_layout_trace(uint64_t session);

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_active_layout_trace(
    uint64_t session,
    uint64_t *outCharacterEnsureCount, uint64_t *outCharacterEnsureMicros,
    uint64_t *outBoundingEnsureCount, uint64_t *outBoundingEnsureMicros,
    uint64_t *outGlyphIndexCount, uint64_t *outGlyphIndexMicros,
    uint64_t *outLineFragmentCount, uint64_t *outLineFragmentMicros,
    uint64_t *outGlyphLocationCount, uint64_t *outGlyphLocationMicros,
    uint64_t *outPositionProxyMicros, uint64_t *outPositionNoopWrites,
    uint64_t *outPositionChangedWrites, uint64_t *outFirstUnlaidBefore,
    uint64_t *outFirstUnlaidAfter, uint64_t *outInvalidatedLocation,
    uint64_t *outInvalidatedLength, uint64_t *outRevealMicros,
    uint64_t *outCandidateMicros, uint64_t *outPositionFirstUnlaidBefore,
    uint64_t *outPositionFirstUnlaidAfter, uint64_t *outPositionChangedMask);

// Historical standalone NSTextView insertion sample. It pre-lays the whole
// container before mutation, so it is reported separately and must not be
// subtracted from an active CJGUI edit with a different warm-layout state.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_nstextview_insert_baseline(const char *text,
                                                         uint32_t selectionLocation,
                                                         float contentWidth,
                                                         uint64_t *outMutationMicros);

// Standalone native TextKit control with CJGUI's content width, wrapping and
// post-insert caret geometry query, but without the CJGUI delegate/owner
// lifecycle. It is a target-shape cross-check, never an additive baseline.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_nstextview_insert_visible_layout_baseline(
    const char *text, uint32_t selectionLocation, float contentWidth,
    uint64_t *outMutationMicros, uint64_t *outSelectionLayoutMicros);

// Drives the ordinary NSTextInputClient marked-text lifecycle for a focused
// composable text input. Test-only: no native text object or composition
// state crosses the framework boundary.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_marked_text(uint64_t session,
                                                         uint32_t nodeIndex,
                                                         const char *text);

CjguiInternalRendererStatus
cjgui_internal_renderer_test_commit_composable_marked_text(uint64_t session,
                                                            const char *text);

// Drives one marked-text update with an EXPLICIT replacement range and inner
// selection, so the range seam can be exercised without a system input source.
// replacementStart < 0 means NSNotFound (protocol default: the platform
// resolves it against the current marked range or selection).
CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_marked_text_ex(uint64_t session,
                                                            uint32_t nodeIndex,
                                                            const char *text,
                                                            uint32_t innerStart,
                                                            uint32_t innerEnd,
                                                            int64_t replacementStart,
                                                            int64_t replacementLength);

// Drives `unmarkText` alone, which AppKit defines as accepting the preedit as
// ordinary text (a COMMIT, never a cancel).
CjguiInternalRendererStatus
cjgui_internal_renderer_test_unmark_composable_marked_text(uint64_t session);

// Drives the input source's cancellation shape: setMarkedText with an empty
// string removes the preedit without inserting anything.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_cancel_composable_marked_text(uint64_t session);

#endif

// pumpEvent(session, timeoutMs) -> event.
// timeoutMs is clamped to at most 16 ms. Performs a single/bounded AppKit
// event acquisition. Never calls [NSApplication run].
CjguiInternalRendererStatus
cjgui_internal_renderer_pump_event(uint64_t session,
                                   uint32_t timeoutMs,
                                   CjguiInternalRendererEvent *outEvent);
CjguiInternalRendererStatus
cjgui_internal_renderer_pumped_pointer_geometry(uint64_t session,
    CjguiInternalRendererPointerEventGeometry *outGeometry);

// Moves native first-responder state to an already committed composable node
// without enqueuing an interaction. The caller supplies only Cangjie node
// identity; this function has no business-action behavior.
CjguiInternalRendererStatus
cjgui_internal_renderer_focus_composable_node(uint64_t session, uint64_t nodeId);

// Restores a UTF-16 selection only on the already focused, committed text node
// and exact current owner value. Returns the composed-character-safe range
// actually installed in the input proxy; it never changes focus or text.
CjguiInternalRendererStatus
cjgui_internal_renderer_restore_composable_selection(uint64_t session, uint64_t nodeId,
                                                     int64_t resourceId, uint32_t nodeKind,
                                                     uint64_t sceneVersion, const char *expectedValue,
                                                     uint32_t selectionStart, uint32_t selectionEnd,
                                                     uint32_t *outSelectionStart, uint32_t *outSelectionEnd);

// REANCHOR: keep a live session-owned marked composition on this node while the
// surrounding projection moves to a new owner version. `newBaseText` is the new
// proxy text WITHOUT the preedit; the preedit replaces
// [replacementStart16, replacementStart16 + replacementLength16) of it. On
// success the marked run and its inner selection are preserved (or reinstalled,
// reported through `outMechanism`: 1=preserved, 2=reinstalled) and the actual
// proxy state is read back before this call reports OK. On any identity, state
// or readback mismatch it returns a failure WITHOUT modifying the proxy, so the
// caller can fall back to cancelling the composition. With
// `replacementStart16 == UINT32_MAX` the replacement range is inferred from the
// proxy: the text before the marked run must survive verbatim at the front of
// `newBaseText`, and the preedit is installed at that same offset.
CjguiInternalRendererStatus
cjgui_internal_renderer_reanchor_composition(uint64_t session, uint64_t nodeId,
                                             int64_t resourceId, uint32_t nodeKind,
                                             uint64_t sceneVersion, const char *newBaseText,
                                             uint32_t replacementStart16, uint32_t replacementLength16,
                                             uint32_t *outMechanism,
                                             uint32_t *outMarkedStart16, uint32_t *outMarkedLength16,
                                             uint32_t *outInnerStart16, uint32_t *outInnerEnd16);

// REANCHOR: arm one reanchor request for the NEXT accepted scene of this exact
// node, so the accept path preserves the live marked composition instead of
// cancelling it when the owner value advanced. `baseText == NULL` clears the
// pending request. Arming changes neither proxy nor owner state; it only records
// intent, and the install still has to succeed and read back at the accept.
CjguiInternalRendererStatus
cjgui_internal_renderer_arm_composition_reanchor(uint64_t session, uint64_t nodeId,
                                                 int64_t resourceId, uint32_t nodeKind,
                                                 const char *baseText,
                                                 uint32_t replacementStart16,
                                                 uint32_t replacementLength16);

// Read the active proxy's CURRENT UTF-16 selection under the same committed
// text identity. A queued selection notification is only current if it still
// equals this proxy state when Cangjie consumes it.
CjguiInternalRendererStatus
cjgui_internal_renderer_read_composable_selection(uint64_t session, uint64_t nodeId,
                                                  int64_t resourceId, uint32_t nodeKind,
                                                  uint64_t sceneVersion, const char *expectedValue,
                                                  uint32_t *outSelectionStart, uint32_t *outSelectionEnd);

// Internal session-bound cancellation for a Cangjie-owned pointer revocation
// such as an accepted external owner write or modal transition. The Cangjie
// window emits the corresponding owner-visible POINTER_CANCEL separately.
CjguiInternalRendererStatus
cjgui_internal_renderer_cancel_composable_pointer_capture(uint64_t session);

// Cancel only the native gesture that Cangjie actually revoked. A queued
// terminal for an older capture cannot clear a newer press on the same window.
CjguiInternalRendererStatus
cjgui_internal_renderer_cancel_composable_pointer_capture_epoch(uint64_t session,
                                                                 uint64_t gestureEpoch);
// OHOS full-key variant. macOS supplies a no-op implementation for the
// unrelated backend; it never treats a zero field as a wildcard.
CjguiInternalRendererStatus
cjgui_internal_renderer_cancel_composable_pointer_capture_gesture_key(
    uint64_t session, uint64_t appInstance, uint64_t componentInstance,
    uint64_t surfaceGeneration, int64_t pointerId, uint64_t gestureEpoch);

// configureSharedOperation(session, visibleRecordCount) installs a
// text-and-input overlay above the existing Metal surface. This is the
// currently projected viewport, not the application-list length. Title
// strings are copied by the C side; callers retain ownership of the passed C
// strings. The renderer intentionally draws at most eight rows, while the
// Cangjie truth owner may contain more records.
CjguiInternalRendererStatus
cjgui_internal_renderer_configure_shared_operation(uint64_t session,
                                                    uint32_t visibleRecordCount);

// setSharedOperationTitle copies one UTF-8 title into the overlay. Index must
// be smaller than the configured visible-record count.
CjguiInternalRendererStatus
cjgui_internal_renderer_set_shared_operation_title(uint64_t session,
                                                    uint32_t recordIndex,
                                                    const char *title);

// setSharedOperationState updates the visible selection, marks and version.
// It never mutates application data and stores no Cangjie pointer.
CjguiInternalRendererStatus
cjgui_internal_renderer_set_shared_operation_state(
    uint64_t session,
    const CjguiInternalRendererSharedOperationState *state);

// Shared-editing form projection. The visible form is self-drawn; an
// off-canvas AppKit text-input proxy supplies IME, selection, paste and
// deletion services only. It enqueues intents, while Cangjie owns every
// applied/draft/validation value and pushes a new projection after each pump.
CjguiInternalRendererStatus
cjgui_internal_renderer_configure_shared_form(uint64_t session, uint32_t fieldCount);

// Generic collection + detail composition. `visibleRecordCount` is only a
// renderer viewport (<= 8), never an application collection limit.
CjguiInternalRendererStatus
cjgui_internal_renderer_configure_shared_collection_form(
    uint64_t session, uint32_t fieldCount, uint32_t visibleRecordCount);

CjguiInternalRendererStatus
cjgui_internal_renderer_set_shared_collection_row(
    uint64_t session, uint32_t rowIndex, const char *title, uint8_t isSelected,
    uint32_t viewportStart, uint32_t totalRecordCount);

// Copies the Cangjie-owned filter projection into the self-drawn query field.
// The native view may emit an intent while the user types, but does not retain
// it as application state across the next Cangjie projection.
CjguiInternalRendererStatus
cjgui_internal_renderer_set_shared_collection_filter(uint64_t session,
                                                      const char *filterText);

CjguiInternalRendererStatus
cjgui_internal_renderer_set_shared_form_field(
    uint64_t session, uint32_t fieldIndex, const char *label, const char *draftText,
    const char *validationError, uint32_t editorKind, uint8_t isFocused,
    uint32_t selectionStart, uint32_t selectionEnd);

CjguiInternalRendererStatus
cjgui_internal_renderer_set_shared_form_status(uint64_t session, const char *status);

// Returns a borrowed UTF-8 string valid until the next form interaction or
// form update for this session. It is consumed immediately inside the
// internal Cangjie bridge and is never part of a public API.
const char *cjgui_internal_renderer_form_event_text(uint64_t session);

// Borrowed until the next event pump for this session. It contains the
// declared format for a copy/paste/drop event and is empty for other events.
const char *cjgui_internal_renderer_data_transfer_event_format(uint64_t session);
const char *cjgui_internal_renderer_data_transfer_event_source_kind(uint64_t session);
const char *cjgui_internal_renderer_data_transfer_event_source_identity(uint64_t session);
int64_t cjgui_internal_renderer_data_transfer_event_source_id(uint64_t session);
int64_t cjgui_internal_renderer_data_transfer_event_expected_owner_version(uint64_t session);
uint64_t cjgui_internal_renderer_data_transfer_event_delivery_ordinal(uint64_t session);
uint32_t cjgui_internal_renderer_data_transfer_event_binary_size(uint64_t session, uint64_t eventId);
CjguiInternalRendererStatus cjgui_internal_renderer_copy_data_transfer_event_binary(
    uint64_t session, uint64_t eventId, uint8_t *outBytes, uint32_t capacity);

#ifdef CJGUI_INTERNAL_TESTING
// Test-only normal-pasteboard exercises. They conditionally restore the
// saved pasteboard and still call the production bounded helpers.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_data_transfer_copy(uint64_t session, uint64_t sourceNodeId);
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_data_transfer_paste(uint64_t session, uint64_t targetNodeId,
                                                             const char *externalPayload);
// Drives the production destination callbacks with a test-owned dragging
// info/pasteboard. It proves target callback -> FIFO boundaries only, never
// cross-window AppKit dispatch.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_data_transfer_drop(uint64_t session, uint64_t targetNodeId,
                                                            const char *externalPayload);
// Drives the production mouse-down/mouse-dragged source path and reports
// hit/press/threshold/dragging-session bits (1/2/4/8). It does not fabricate
// a target drop or expose an AppKit object to framework consumers.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_trace_composable_data_transfer_drag(
    uint64_t session, float sourceX, float sourceY, float dragX, float dragY, uint32_t *outTrace);
// Enters the first declared target through the production hover helper. The
// paired cancel helper below then calls the production draggingExited method.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_data_transfer_hover_target(uint64_t session);
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_data_transfer_hover_cleared(uint64_t session);
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_data_transfer_cancel(uint64_t session);

// Test-only transfer-retention observability. All byte values are bounded
// UTF-8 copies already owned by the normal native scene/FIFO: these are not
// allocator totals or application-domain payload retention. `read`/`parse`
// are cumulative callback observations with a largest single payload; source,
// accepted and candidate report current/peak declaration copies; FIFO reports
// only copy/paste/drop events (not unrelated pointer input).
CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_data_transfer_stats(
    uint64_t session,
    uint64_t *outReadCount, uint64_t *outReadBytes, uint64_t *outReadPeakBytes,
    uint64_t *outParseCount, uint64_t *outParseBytes, uint64_t *outParsePeakBytes,
    uint64_t *outSourceWriteCount, uint64_t *outSourceWriteBytes, uint64_t *outSourceWritePeakBytes,
    uint64_t *outSourceCurrentBytes, uint64_t *outSourcePeakBytes,
    uint64_t *outAcceptedCurrentBytes, uint64_t *outAcceptedPeakBytes,
    uint64_t *outCandidateCurrentBytes, uint64_t *outCandidatePeakBytes,
    uint32_t *outFifoCurrentEvents, uint32_t *outFifoPeakEvents,
    uint64_t *outFifoCurrentBytes, uint64_t *outFifoPeakBytes);
#endif

// requestClose(session) -> status. Marks close requested and closes the
// window. Does not destroy the session.
CjguiInternalRendererStatus
cjgui_internal_renderer_request_close(uint64_t session);

// destroy(session) -> status. Tears down view/window resources and frees the
// session slot. Double destroy returns CJGUI_INTERNAL_RENDERER_INVALID_SESSION.
CjguiInternalRendererStatus
cjgui_internal_renderer_destroy(uint64_t session);

// occupiedSessionCount() -> number of currently occupied session slots.
uint32_t cjgui_internal_renderer_occupied_session_count(void);

#ifdef __cplusplus
}
#endif

#endif // CJGUI_INTERNAL_RENDERER_H
