package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.time.*

// runtime_renderer_session.cj
//
// INTERNAL / UNSTABLE Cangjie wrapper for the runtime-owned internal renderer
// sidecar (runtime/cjgui/native/cjgui_internal_renderer.*).
//
// This file only carries real data and behavior:
//   - @C struct mappings (layout-identical to the C POD structs);
//   - foreign func declarations for the internal C ABI;
//   - session token handling;
//   - create/present/pump/close/destroy calls with centralized unsafe
//     encapsulation.
//
// It does NOT introduce public Cangjie API. All symbols use default internal
// visibility. It does NOT write runtime_state or renderer_state.
//
// CFFI rules honored:
//   - foreign calls happen inside unsafe {};
//   - inout pointers are only valid for the duration of the call and the C
//     side never stores them;
//   - no Objective-C / Metal pointer crosses the boundary, only UInt64
//     session tokens and POD structs.
//
// Note on result records: Cangjie forbids @C struct members in tuples, so
// multi-value returns use plain internal scalar records below. These hold the
// real frame/event scalars, not Bool/readiness/plan/receipt wrappers.

// ---- internal status codes (mirror CjguiInternalRendererStatus) ----

let CJGUI_INTERNAL_RENDERER_OK: Int32 = 0
let CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD: Int32 = 1
let CJGUI_INTERNAL_RENDERER_APP_INIT_FAILED: Int32 = 2
let CJGUI_INTERNAL_RENDERER_WINDOW_CREATE_FAILED: Int32 = 3
let CJGUI_INTERNAL_RENDERER_METAL_DEVICE_UNAVAILABLE: Int32 = 4
let CJGUI_INTERNAL_RENDERER_METAL_COMMAND_QUEUE_UNAVAILABLE: Int32 = 5
let CJGUI_INTERNAL_RENDERER_METAL_LAYER_UNAVAILABLE: Int32 = 6
let CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE: Int32 = 7
let CJGUI_INTERNAL_RENDERER_METAL_COMMAND_BUFFER_UNAVAILABLE: Int32 = 8
let CJGUI_INTERNAL_RENDERER_METAL_ENCODER_UNAVAILABLE: Int32 = 9
let CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED: Int32 = 10
let CJGUI_INTERNAL_RENDERER_INVALID_SESSION: Int32 = 11
let CJGUI_INTERNAL_RENDERER_SESSION_TABLE_FULL: Int32 = 12
let CJGUI_INTERNAL_RENDERER_READBACK_FAILED: Int32 = 13
// 提交未定（Sol 提交边界协议）：native 已取得平台提交许可但结果尚未落定。
// 核心不得把它当成拒绝回滚候选；保留候选与 staged 事实，等待 native 侧
// 结算槽给出一次性 commit/rollback（见 ohos_renderer.cpp 结算协议）。
let CJGUI_INTERNAL_RENDERER_PRESENT_PENDING: Int32 = 20
let CJGUI_INTERNAL_RENDERER_INVALID_UTF8: Int32 = 14
let CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED: Int32 = 15
let CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED: Int32 = 16
let CJGUI_INTERNAL_RENDERER_EFFECT_RESOURCE_BUDGET_EXCEEDED: Int32 = 22
let CJGUI_INTERNAL_RENDERER_EFFECT_DECLARATION_REJECTED: Int32 = 23
let CJGUI_INTERNAL_RENDERER_PNG_INVALID: Int32 = 25
let CJGUI_INTERNAL_RENDERER_PNG_DIMENSION_EXCEEDED: Int32 = 26
let CJGUI_INTERNAL_RENDERER_PNG_DECODE_FAILED: Int32 = 27
let CJGUI_INTERNAL_RENDERER_PNG_RESOURCE_BUDGET_EXCEEDED: Int32 = 28
let CJGUI_INTERNAL_RENDERER_PNG_PAYLOAD_TOO_LARGE: Int32 = 29
let CJGUI_INTERNAL_RENDERER_PNG_QUEUE_BUDGET_EXCEEDED: Int32 = 30
let CJGUI_INTERNAL_RENDERER_PNG_UNSUPPORTED: Int32 = 31
let CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED: Int32 = 32
// M1（2026-09-30）：位置查询的具名拒绝码——无此节点（17）、无已持留排版（18）、
// 场景尚未 staged（19）、调用方携带的 accepted 场景版本已前进（33）。
let CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND: Int32 = 17
let CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY: Int32 = 18
let CJGUI_INTERNAL_RENDERER_SCENE_NOT_STAGED: Int32 = 19
let CJGUI_INTERNAL_RENDERER_SCENE_STALE: Int32 = 33
let CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID: Int32 = 34
// M2：视觉导航的行插入点枚举超出有界预算——不具名邻位，调用方保持 caret。
let CJGUI_INTERNAL_RENDERER_VISUAL_NAV_UNSUPPORTED: Int32 = 35
let CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR: Int32 = 99
let CJGUI_SELECTION_TRANSFER_EMPTY: UInt32 = 0u32
let CJGUI_SELECTION_TRANSFER_PREPARING: UInt32 = 1u32
let CJGUI_SELECTION_TRANSFER_PENDING: UInt32 = 2u32
let CJGUI_SELECTION_TRANSFER_FINALIZING: UInt32 = 3u32
let CJGUI_SELECTION_TRANSFER_COMMITTED: UInt32 = 4u32
let CJGUI_SELECTION_TRANSFER_ABORTED: UInt32 = 5u32
let CJGUI_SELECTION_TRANSFER_RECOVERY_BLOCKED: UInt32 = 6u32
let CJGUI_SELECTION_INPUT_ALLOW: UInt32 = 0u32
let CJGUI_SELECTION_INPUT_RETAINED_CANCEL: UInt32 = 1u32
let CJGUI_SELECTION_INPUT_RECOVERY_BLOCKED: UInt32 = 2u32
let CJGUI_SELECTION_INPUT_STALE: UInt32 = 3u32
// Secondary pointer context request; the C enum value is mirrored here without
// changing the POD event ABI.
let CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_CONTEXT_MENU_REQUEST: UInt32 = 56u32

// Invalid session token sentinel.
let CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN: UInt64 = 0

// ---- @C struct mappings (layout-identical to the C POD structs) ----

// New package-private sideband records. Existing Node/Event PODs are unchanged.
@C
struct CjguiInternalInstalledRangeCandidate {
    var nonce: UInt64 = 0
    var rendererSessionGeneration: UInt64 = 0
    var windowInstanceToken: UInt64 = 0
    var bindingEpoch: UInt64 = 0
    var contextEpoch: UInt64 = 0
    var mirrorRevision: UInt64 = 0
    var ownerVersion: Int64 = -1
    var installedSceneVersion: UInt64 = 0
    var nodeId: UInt64 = 0
    var resourceId: Int64 = -1
    var sourceStartByte: UInt64 = 0
    var sourceEndByte: UInt64 = 0
    var sourceTextUtf8: CPointer<UInt8> = CPointer<UInt8>()
    var sourceTextUtf8Length: UInt32 = 0
}

@C
struct CjguiInternalSelectionTransferCandidate {
    var transferId: UInt64 = 0
    var sourceInstalledNonce: UInt64 = 0
    var sourceRendererSessionGeneration: UInt64 = 0
    var sourceWindowInstanceToken: UInt64 = 0
    var sourceBindingEpoch: UInt64 = 0
    var sourceContextEpoch: UInt64 = 0
    var sourceMirrorRevision: UInt64 = 0
    var sourceOwnerVersion: Int64 = -1
    var sourceAcceptedVersion: Int64 = -1
    var sourceAcceptedSequence: UInt64 = 0
    var sourceStartByte: UInt64 = 0
    var sourceEndByte: UInt64 = 0
    var sourceProxyGeneration: UInt64 = 0
    var sourceSelectionRevision: UInt64 = 0
    var sourceNodeId: UInt64 = 0
    var sourceProjectionVersion: UInt64 = 0
    var sourceResourceId: Int64 = -1
    var sourceNodeKind: UInt32 = 0
    var sourceSceneVersion: UInt64 = 0
    var sourceSelectionStart16: UInt32 = 0
    var sourceSelectionEnd16: UInt32 = 0
    var sourceBodyUtf8: CPointer<UInt8> = CPointer<UInt8>()
    var sourceBodyUtf8Length: UInt32 = 0
    var targetNodeId: UInt64 = 0
    var targetProjectionVersion: UInt64 = 0
    var targetResourceId: Int64 = -1
    var targetNodeKind: UInt32 = 0
    var targetSceneVersion: UInt64 = 0
    var targetAnchor16: UInt32 = 0
    var targetFocus16: UInt32 = 0
    var targetBodyUtf8: CPointer<UInt8> = CPointer<UInt8>()
    var targetBodyUtf8Length: UInt32 = 0
}

@C
struct CjguiInternalSelectionTransferReceipt {
    var transferId: UInt64 = 0
    var sceneVersion: UInt64 = 0
    var bindingEpoch: UInt64 = 0
    var nodeId: UInt64 = 0
    var projectionVersion: UInt64 = 0
    var resourceId: Int64 = -1
    var nodeKind: UInt32 = 0
    var selectionStart16: UInt32 = 0
    var selectionEnd16: UInt32 = 0
    var selectionRevision: UInt64 = 0
    var proxyGeneration: UInt64 = 0
    var firstResponder: UInt8 = 0
}

@C
struct CjguiInternalInstalledRangeReceipt {
    var nonce: UInt64 = 0
    var rendererSessionGeneration: UInt64 = 0
    var windowInstanceToken: UInt64 = 0
    var bindingEpoch: UInt64 = 0
    var contextEpoch: UInt64 = 0
    var mirrorRevision: UInt64 = 0
    var ownerVersion: Int64 = -1
    var installedSceneVersion: UInt64 = 0
    var nodeId: UInt64 = 0
    var resourceId: Int64 = -1
    var sourceStartByte: UInt64 = 0
    var sourceEndByte: UInt64 = 0
    var proxyGeneration: UInt64 = 0
    var selectionRevision: UInt64 = 0
    var actualSelectionStart16: UInt32 = 0
    var actualSelectionEnd16: UInt32 = 0
    var acceptedSequence: UInt64 = 0
    var acceptedVersion: Int64 = -1
}

@C
struct CjguiInternalInstalledRangeIntent {
    var nonce: UInt64 = 0
    var rendererSessionGeneration: UInt64 = 0
    var windowInstanceToken: UInt64 = 0
    var bindingEpoch: UInt64 = 0
    var contextEpoch: UInt64 = 0
    var mirrorRevision: UInt64 = 0
    var ownerVersion: Int64 = -1
    var installedSceneVersion: UInt64 = 0
    var nodeId: UInt64 = 0
    var resourceId: Int64 = -1
    var sourceStartByte: UInt64 = 0
    var sourceEndByte: UInt64 = 0
    var proxyGeneration: UInt64 = 0
    var selectionRevision: UInt64 = 0
    var seq: UInt64 = 0
    var previousSeq: UInt64 = 0
    var observedAckSeq: UInt64 = 0
    var observedAckVersion: Int64 = -1
    var wholeChoiceNonce: UInt64 = 0
    var wholeChoicePreviousSeq: UInt64 = 0
    var flags: UInt32 = 0
    var rangeStart16: UInt32 = 0
    var rangeLength16: UInt32 = 0
    var selectionStart16: UInt32 = 0
    var selectionEnd16: UInt32 = 0
    var preBodyUtf8: CPointer<UInt8> = CPointer<UInt8>()
    var preBodyUtf8Length: UInt32 = 0
    var replacementUtf8: CPointer<UInt8> = CPointer<UInt8>()
    var replacementUtf8Length: UInt32 = 0
    var postBodyUtf8: CPointer<UInt8> = CPointer<UInt8>()
    var postBodyUtf8Length: UInt32 = 0
}

class InternalRendererInstalledRangeClaim {
    let raw: CjguiInternalInstalledRangeIntent
    let input: CjguiInstalledRangeInput
    let replacement: String
    let postBody: String
    init(raw: CjguiInternalInstalledRangeIntent, input: CjguiInstalledRangeInput,
        replacement: String, postBody: String) {
        this.raw = raw; this.input = input; this.replacement = replacement; this.postBody = postBody
    }
}

@C
struct CjguiInternalRendererConfig {
    var windowWidth: UInt32 = 0
    var windowHeight: UInt32 = 0
    var clearColorRed: Float64 = 0.0
    var clearColorGreen: Float64 = 0.0
    var clearColorBlue: Float64 = 0.0
    var clearColorAlpha: Float64 = 0.0
    init(windowWidth!: UInt32, windowHeight!: UInt32, clearColorRed!: Float64, clearColorGreen!: Float64,
        clearColorBlue!: Float64, clearColorAlpha!: Float64) {
        this.windowWidth = windowWidth
        this.windowHeight = windowHeight
        this.clearColorRed = clearColorRed
        this.clearColorGreen = clearColorGreen
        this.clearColorBlue = clearColorBlue
        this.clearColorAlpha = clearColorAlpha
    }
}

@C
struct CjguiInternalRendererClearColor {
    var red: Float64 = 0.0
    var green: Float64 = 0.0
    var blue: Float64 = 0.0
    var alpha: Float64 = 0.0
    init(red!: Float64, green!: Float64, blue!: Float64, alpha!: Float64) {
        this.red = red
        this.green = green
        this.blue = blue
        this.alpha = alpha
    }
}

@C
struct CjguiInternalRendererFrameObservation {
    var frameIndex: UInt64 = 0
    var drawableWidthPixels: UInt32 = 0
    var drawableHeightPixels: UInt32 = 0
    var contentsScale: Float64 = 0.0
    var readbackAttempted: UInt8 = 0
    var readbackCompleted: UInt8 = 0
    var readbackColorMatched: UInt8 = 0
    // A1：本次提交的票据编号。非 0 表示该票据已登记在 native 结算槽，必须经
    // queryPresent 取终态、acknowledgePresent 确认。0 表示未登记票据。
    var ticketId: UInt64 = 0
}

// A1 票据裁决（镜像 CjguiInternalRendererPresentDecision）。
let CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_NONE: UInt32 = 0
let CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_PENDING: UInt32 = 1
let CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED: UInt32 = 2
let CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_REJECTED: UInt32 = 3

@C
struct CjguiInternalRendererPresentReceipt {
    var ticketId: UInt64 = 0
    var projectionVersion: UInt64 = 0
    var decision: UInt32 = 0
    var terminalStatus: Int32 = 0
    var observation: CjguiInternalRendererFrameObservation = CjguiInternalRendererFrameObservation()
    var resyncRequired: UInt8 = 0
    var settled: UInt8 = 0
}

@C
struct CjguiInternalRendererPresentTicketStats {
    var nextTicketId: Int64 = 0
    var unackedTicketId: Int64 = 0
    var acceptedCount: Int64 = 0
    var rejectedCount: Int64 = 0
    var queryCount: Int64 = 0
    var ackCount: Int64 = 0
    var duplicateSettlementCount: Int64 = 0
    var destroyRefusedCount: Int64 = 0
    var available: UInt8 = 0
}

@C
struct CjguiInternalRendererComposableDisplayProgress {
    var submittedFrameIndex: UInt64 = 0
    var observedMetalCompletionFrameIndex: UInt64 = 0
    var observedMetalFailureFrameIndex: UInt64 = 0
    var observedMetalGpuDurationMicros: Int64 = -1
    var overlayDrawnProjectionVersion: UInt64 = 0
    var effectSubmittedSceneVersion: UInt64 = 0
    var effectSubmittedFrameIndex: UInt64 = 0
    var effectRequestedRadiusPoints: UInt32 = 0
    var effectMode: UInt32 = 0
    var effectFallbackReason: UInt32 = 0
    var effectCompletion: UInt32 = 0
    var currentPointWidth: Float64 = 0.0
    var currentPointHeight: Float64 = 0.0
    var currentBackingScale: Float64 = 0.0
    var currentDrawableWidthPixels: UInt32 = 0
    var currentDrawableHeightPixels: UInt32 = 0
    var currentGeometryRevision: UInt64 = 0
    var submittedPointWidth: Float64 = 0.0
    var submittedPointHeight: Float64 = 0.0
    var submittedBackingScale: Float64 = 0.0
    var submittedDrawableWidthPixels: UInt32 = 0
    var submittedDrawableHeightPixels: UInt32 = 0
    var submittedGeometryRevision: UInt64 = 0
    var submittedSceneVersion: UInt64 = 0
}

@C
struct CjguiInternalRendererDiagnosticNodeGeometry {
    var sceneVersion: UInt64 = 0
    var frameIndex: UInt64 = 0
    var outputX: Float64 = 0.0
    var outputY: Float64 = 0.0
    var outputWidth: Float64 = 0.0
    var outputHeight: Float64 = 0.0
    var sampleX: Float64 = 0.0
    var sampleY: Float64 = 0.0
    var sampleWidth: Float64 = 0.0
    var sampleHeight: Float64 = 0.0
    var flags: UInt32 = 0
    var reserved: UInt32 = 0
}

@C
struct CjguiInternalRendererDiagnosticResources {
    var sceneVersion: UInt64 = 0
    var frameIndex: UInt64 = 0
    var liveEffectBytes: UInt64 = 0
    var cachedEffectBytes: UInt64 = 0
    var overlayDrawCount: UInt64 = 0
}

/// C mirror of the bounded workload scalars: saturating totals of real work
/// points (node writes, COW clones, node allocations, scene text-layout
/// preparations, image decode starts) plus the currently reusable bytes.
@C
struct CjguiInternalRendererDiagnosticWorkload {
    var sceneVersion: UInt64 = 0
    var frameIndex: UInt64 = 0
    var nodeWriteCount: UInt64 = 0
    var nodeCloneCount: UInt64 = 0
    var nodeAllocationCount: UInt64 = 0
    var textLayoutPreparationCount: UInt64 = 0
    var imageDecodeStartCount: UInt64 = 0
    var reusableResourceBytes: UInt64 = 0
    var textRasterCount: UInt64 = 0
    var textRasterBytes: UInt64 = 0
    var textRasterMicros: UInt64 = 0
    var textUploadCount: UInt64 = 0
    var textUploadBytes: UInt64 = 0
    var textUploadMicros: UInt64 = 0
    var textTextureLiveBytes: UInt64 = 0
    var textCandidatePeakBytes: UInt64 = 0
}

/// Fixed-size, per-window opt-in timing totals. All durations are nanoseconds
/// from mach_continuous_time; counters are session-owned and saturating.
@C
struct CjguiInternalRendererDiagnosticTiming {
    var sceneVersion: UInt64 = 0
    var frameIndex: UInt64 = 0
    var enabled: UInt32 = 0
    var clockAvailable: UInt32 = 0
    var positionPrepareCount: UInt64 = 0
    var positionQueryCount: UInt64 = 0
    var positionLineBuildCount: UInt64 = 0
    var positionCacheHitCount: UInt64 = 0
    var positionPrepareNanoseconds: UInt64 = 0
    var positionQueryNanoseconds: UInt64 = 0
    var positionLineBuildNanoseconds: UInt64 = 0
    var encodeNanoseconds: UInt64 = 0
    var submitNanoseconds: UInt64 = 0
    var rasterNanoseconds: UInt64 = 0
    var uploadNanoseconds: UInt64 = 0
    var readCount: UInt64 = 0
    var readNanoseconds: UInt64 = 0
}

/// C mirror of the native window-background observation. This describes
/// AppKit host adoption and the matching Metal submission, never a sampled
/// WindowServer pixel or an AppKit object.
@C
struct CjguiInternalRendererWindowBackgroundSnapshot {
    var acceptedSceneVersion: UInt64 = 0
    var frameIndex: UInt64 = 0
    var requestRevision: UInt64 = 0
    var environmentRevision: UInt64 = 0
    var observationRevision: UInt64 = 0
    var requestedMode: UInt32 = 0
    var backend: UInt32 = 0
    var actualMode: UInt32 = 0
    var fallbackReason: UInt32 = 0
    var completion: UInt32 = 0
    var reduceTransparency: UInt32 = 0
    var windowActive: UInt32 = 0
    var colorScheme: UInt32 = 0
}

@C
struct CjguiInternalRendererEvent {
    var kind: UInt32 = 0
    var recordIndex: UInt32 = 0
    var selectionStart: UInt32 = 0
    var selectionEnd: UInt32 = 0
    var nodeId: UInt64 = 0
    var projectionVersion: UInt64 = 0
    var resourceId: Int64 = -1
    var nodeKind: UInt32 = 0
    var pointerX: Int64 = 0
    var pointerY: Int64 = 0
    var modifierFlags: Int64 = 0
    // kind 52 组字相位记录（其余 kind 恒为 0/-1，与 C 头逐字段同序）。
    var compositionPhase: UInt32 = 0
    var replacementStart16: Int64 = -1
    var replacementLength16: Int64 = 0
    var markedStart16: Int64 = -1
    var markedLength16: Int64 = 0
    var compositionId: UInt64 = 0
    var bindingEpoch: UInt64 = 0
    var dataTransferEventId: UInt64 = 0
    var gestureAppInstance: UInt64 = 0
    var gestureComponentInstance: UInt64 = 0
    var gestureSurfaceGeneration: UInt64 = 0
    var gesturePointerId: Int64 = -1
    var gestureEpoch: UInt64 = 0
    var acceptedBindingEpoch: UInt64 = 0
}

@C
struct CjguiInternalRendererPointerEventGeometry {
    var present: UInt32 = 0
    var kind: UInt32 = 0
    var nodeId: UInt64 = 0
    var projectionVersion: UInt64 = 0
    var resourceId: Int64 = -1
    var nodeKind: UInt32 = 0
    var reserved: UInt32 = 0
    var x: Float64 = 0.0
    var y: Float64 = 0.0
    var translateX: Float64 = 0.0
    var translateY: Float64 = 0.0
}

@C
struct CjguiInternalRendererComposableDataTransferItem {
    var nodeId: UInt64 = 0
    var projectionVersion: UInt64 = 0
    var resourceId: Int64 = -1
    var nodeKind: UInt32 = 0
    var role: UInt32 = 0
    var maximumPayloadBytes: UInt32 = 0
    var sourceId: Int64 = -1
    var bindingEpoch: UInt64 = 0
    var expectedOwnerVersion: Int64 = -1
    var localPngFileAllowed: UInt32 = 0
    init(nodeId!: UInt64, projectionVersion!: UInt64, resourceId!: Int64, nodeKind!: UInt32, role!: UInt32,
        maximumPayloadBytes!: UInt32, sourceId!: Int64, bindingEpoch!: UInt64 = 0u64,
        expectedOwnerVersion!: Int64 = -1, localPngFileAllowed!: UInt32 = 0u32) {
        this.nodeId = nodeId
        this.projectionVersion = projectionVersion
        this.resourceId = resourceId
        this.nodeKind = nodeKind
        this.role = role
        this.maximumPayloadBytes = maximumPayloadBytes
        this.sourceId = sourceId
        this.bindingEpoch = bindingEpoch
        this.expectedOwnerVersion = expectedOwnerVersion
        this.localPngFileAllowed = localPngFileAllowed
    }
}

@C
struct CjguiInternalRendererComposableGeometry {
    var nodeId: UInt64 = 0
    var clipCount: UInt32 = 0
    var reserved: UInt32 = 0
    var translateX: Float64 = 0.0
    var translateY: Float64 = 0.0
    var clip0X: Float64 = 0.0
    var clip0Y: Float64 = 0.0
    var clip1X: Float64 = 0.0
    var clip1Y: Float64 = 0.0
    var clip2X: Float64 = 0.0
    var clip2Y: Float64 = 0.0
    var clip3X: Float64 = 0.0
    var clip3Y: Float64 = 0.0
}

@C
struct CjguiInternalRendererComposableNode {
    var nodeId: UInt64 = 0
    var projectionVersion: UInt64 = 0
    var resourceId: Int64 = -1
    var x: Int64 = 0
    var y: Int64 = 0
    var width: Int64 = 0
    var height: Int64 = 0
    var clipX: Int64 = 0
    var clipY: Int64 = 0
    var clipWidth: Int64 = 0
    var clipHeight: Int64 = 0
    var nodeKind: UInt32 = 0
    var isInteractive: UInt32 = 0
    var isReadOnly: UInt32 = 0
    var tabInsertsText: UInt32 = 0
    var preservesActiveLocalText: UInt32 = 0
    var borderWidth: UInt32 = 0
    var cornerRadius: Float64 = 0.0
    var clipCornerRadius: Float64 = 0.0
    var clipConstraintCount: UInt32 = 0
    var clip0X: Int64 = 0
    var clip0Y: Int64 = 0
    var clip0Width: Int64 = 0
    var clip0Height: Int64 = 0
    var clip0CornerRadius: Float64 = 0.0
    var clip1X: Int64 = 0
    var clip1Y: Int64 = 0
    var clip1Width: Int64 = 0
    var clip1Height: Int64 = 0
    var clip1CornerRadius: Float64 = 0.0
    var clip2X: Int64 = 0
    var clip2Y: Int64 = 0
    var clip2Width: Int64 = 0
    var clip2Height: Int64 = 0
    var clip2CornerRadius: Float64 = 0.0
    var clip3X: Int64 = 0
    var clip3Y: Int64 = 0
    var clip3Width: Int64 = 0
    var clip3Height: Int64 = 0
    var clip3CornerRadius: Float64 = 0.0
    var fontSize: Float64 = 13.0
    var fontWeight: UInt32 = 0
    var fontFamily: UInt32 = 0
    var imageContentMode: UInt32 = 1
    var fillRed: Float64 = 0.0
    var fillGreen: Float64 = 0.0
    var fillBlue: Float64 = 0.0
    var fillAlpha: Float64 = 0.0
    var borderRed: Float64 = 0.0
    var borderGreen: Float64 = 0.0
    var borderBlue: Float64 = 0.0
    var borderAlpha: Float64 = 0.0
    var textRed: Float64 = 0.0
    var textGreen: Float64 = 0.0
    var textBlue: Float64 = 0.0
    var textAlpha: Float64 = 0.0
    var inputScope: UInt64 = 0
    var tabGroupId: UInt64 = 0
    var tabSelected: UInt32 = 0
    var semanticRole: UInt32 = 0
    var semanticState: UInt32 = 0
    var semanticLevel: Int64 = 0
    var semanticIncarnation: Int64 = 0
    var shadowPresent: UInt32 = 0
    var shadowOffsetX: Float64 = 0.0
    var shadowOffsetY: Float64 = 0.0
    var shadowBlurRadius: Float64 = 0.0
    var shadowSpread: Float64 = 0.0
    var shadowRed: Float64 = 0.0
    var shadowGreen: Float64 = 0.0
    var shadowBlue: Float64 = 0.0
    var shadowAlpha: Float64 = 0.0
    var gradientPresent: UInt32 = 0
    var gradientStopCount: UInt32 = 0
    var gradientStartX: Float64 = 0.0
    var gradientStartY: Float64 = 0.0
    var gradientEndX: Float64 = 0.0
    var gradientEndY: Float64 = 0.0
    var gradientStop0Position: Float64 = 0.0
    var gradientStop0Red: Float64 = 0.0
    var gradientStop0Green: Float64 = 0.0
    var gradientStop0Blue: Float64 = 0.0
    var gradientStop0Alpha: Float64 = 0.0
    var gradientStop1Position: Float64 = 0.0
    var gradientStop1Red: Float64 = 0.0
    var gradientStop1Green: Float64 = 0.0
    var gradientStop1Blue: Float64 = 0.0
    var gradientStop1Alpha: Float64 = 0.0
    var gradientStop2Position: Float64 = 0.0
    var gradientStop2Red: Float64 = 0.0
    var gradientStop2Green: Float64 = 0.0
    var gradientStop2Blue: Float64 = 0.0
    var gradientStop2Alpha: Float64 = 0.0
    var gradientStop3Position: Float64 = 0.0
    var gradientStop3Red: Float64 = 0.0
    var gradientStop3Green: Float64 = 0.0
    var gradientStop3Blue: Float64 = 0.0
    var gradientStop3Alpha: Float64 = 0.0
    var effectGroupPresent: UInt32 = 0
    var effectGroupSubtreeCount: UInt32 = 0
    var effectGroupOpacity: Float64 = 1.0
    var effectGroupBlendMode: UInt32 = 0
    var effectMaskPresent: UInt32 = 0
    var effectMaskStopCount: UInt32 = 0
    var effectMaskStartX: Float64 = 0.0
    var effectMaskStartY: Float64 = 0.0
    var effectMaskEndX: Float64 = 0.0
    var effectMaskEndY: Float64 = 0.0
    var effectMaskStop0Position: Float64 = 0.0
    var effectMaskStop0Alpha: Float64 = 0.0
    var effectMaskStop1Position: Float64 = 0.0
    var effectMaskStop1Alpha: Float64 = 0.0
    var effectMaskStop2Position: Float64 = 0.0
    var effectMaskStop2Alpha: Float64 = 0.0
    var effectMaskStop3Position: Float64 = 0.0
    var effectMaskStop3Alpha: Float64 = 0.0
    var effectBackdropBlurRadiusPoints: UInt32 = 0
    var effectBackdropBlurFallback: UInt32 = 0
    var wheelScrollable: UInt32 = 0
    var acceptedBindingEpoch: UInt64 = 0
    init(nodeId!: UInt64, projectionVersion!: UInt64, resourceId!: Int64, x!: Int64, y!: Int64, width!: Int64,
        height!: Int64, clipX!: Int64, clipY!: Int64, clipWidth!: Int64, clipHeight!: Int64, nodeKind!: UInt32,
        isInteractive!: UInt32, isReadOnly!: UInt32, tabInsertsText!: UInt32, preservesActiveLocalText!: UInt32 = 0u32,
        borderWidth!: UInt32, cornerRadius!: Float64 = 0.0, clipCornerRadius!: Float64 = 0.0,
        clipConstraintCount!: UInt32 = 0u32, clip0X!: Int64 = 0, clip0Y!: Int64 = 0, clip0Width!: Int64 = 0,
        clip0Height!: Int64 = 0, clip0CornerRadius!: Float64 = 0.0, clip1X!: Int64 = 0, clip1Y!: Int64 = 0,
        clip1Width!: Int64 = 0, clip1Height!: Int64 = 0, clip1CornerRadius!: Float64 = 0.0, clip2X!: Int64 = 0,
        clip2Y!: Int64 = 0, clip2Width!: Int64 = 0, clip2Height!: Int64 = 0, clip2CornerRadius!: Float64 = 0.0,
        clip3X!: Int64 = 0, clip3Y!: Int64 = 0, clip3Width!: Int64 = 0, clip3Height!: Int64 = 0,
        clip3CornerRadius!: Float64 = 0.0, fontSize!: Float64, fontWeight!: UInt32, fontFamily!: UInt32,
        imageContentMode!: UInt32, fillRed!: Float64, fillGreen!: Float64, fillBlue!: Float64, fillAlpha!: Float64,
        borderRed!: Float64, borderGreen!: Float64, borderBlue!: Float64, borderAlpha!: Float64, textRed!: Float64,
        textGreen!: Float64, textBlue!: Float64, textAlpha!: Float64, inputScope!: UInt64 = 0, tabGroupId!: UInt64 = 0,
        tabSelected!: UInt32 = 0, semanticRole!: UInt32 = 0u32, semanticState!: UInt32 = 0u32,
        semanticLevel!: Int64 = 0, semanticIncarnation!: Int64 = 0,
        shadowPresent!: UInt32 = 0u32, shadowOffsetX!: Float64 = 0.0,
        shadowOffsetY!: Float64 = 0.0, shadowBlurRadius!: Float64 = 0.0, shadowSpread!: Float64 = 0.0,
        shadowRed!: Float64 = 0.0, shadowGreen!: Float64 = 0.0, shadowBlue!: Float64 = 0.0, shadowAlpha!: Float64 = 0.0,
        gradientPresent!: UInt32 = 0u32, gradientStopCount!: UInt32 = 0u32, gradientStartX!: Float64 = 0.0,
        gradientStartY!: Float64 = 0.0, gradientEndX!: Float64 = 0.0, gradientEndY!: Float64 = 0.0,
        gradientStop0Position!: Float64 = 0.0, gradientStop0Red!: Float64 = 0.0, gradientStop0Green!: Float64 = 0.0,
        gradientStop0Blue!: Float64 = 0.0, gradientStop0Alpha!: Float64 = 0.0, gradientStop1Position!: Float64 = 0.0,
        gradientStop1Red!: Float64 = 0.0, gradientStop1Green!: Float64 = 0.0, gradientStop1Blue!: Float64 = 0.0,
        gradientStop1Alpha!: Float64 = 0.0, gradientStop2Position!: Float64 = 0.0, gradientStop2Red!: Float64 = 0.0,
        gradientStop2Green!: Float64 = 0.0, gradientStop2Blue!: Float64 = 0.0, gradientStop2Alpha!: Float64 = 0.0,
        gradientStop3Position!: Float64 = 0.0, gradientStop3Red!: Float64 = 0.0, gradientStop3Green!: Float64 = 0.0,
        gradientStop3Blue!: Float64 = 0.0, gradientStop3Alpha!: Float64 = 0.0,
        effectGroupPresent!: UInt32 = 0u32, effectGroupSubtreeCount!: UInt32 = 0u32,
        effectGroupOpacity!: Float64 = 1.0, effectGroupBlendMode!: UInt32 = 0u32,
        effectMaskPresent!: UInt32 = 0u32, effectMaskStopCount!: UInt32 = 0u32,
        effectMaskStartX!: Float64 = 0.0, effectMaskStartY!: Float64 = 0.0,
        effectMaskEndX!: Float64 = 0.0, effectMaskEndY!: Float64 = 0.0,
        effectMaskStop0Position!: Float64 = 0.0, effectMaskStop0Alpha!: Float64 = 0.0,
        effectMaskStop1Position!: Float64 = 0.0, effectMaskStop1Alpha!: Float64 = 0.0,
        effectMaskStop2Position!: Float64 = 0.0, effectMaskStop2Alpha!: Float64 = 0.0,
        effectMaskStop3Position!: Float64 = 0.0, effectMaskStop3Alpha!: Float64 = 0.0,
        effectBackdropBlurRadiusPoints!: UInt32 = 0u32, effectBackdropBlurFallback!: UInt32 = 0u32) {
        this.nodeId = nodeId
        this.projectionVersion = projectionVersion
        this.resourceId = resourceId
        this.x = x
        this.y = y
        this.width = width
        this.height = height
        this.clipX = clipX
        this.clipY = clipY
        this.clipWidth = clipWidth
        this.clipHeight = clipHeight
        this.nodeKind = nodeKind
        this.isInteractive = isInteractive
        this.isReadOnly = isReadOnly
        this.tabInsertsText = tabInsertsText
        this.preservesActiveLocalText = preservesActiveLocalText
        this.borderWidth = borderWidth
        this.cornerRadius = cornerRadius
        this.clipCornerRadius = clipCornerRadius
        this.clipConstraintCount = clipConstraintCount
        this.clip0X = clip0X
        this.clip0Y = clip0Y
        this.clip0Width = clip0Width
        this.clip0Height = clip0Height
        this.clip0CornerRadius = clip0CornerRadius
        this.clip1X = clip1X
        this.clip1Y = clip1Y
        this.clip1Width = clip1Width
        this.clip1Height = clip1Height
        this.clip1CornerRadius = clip1CornerRadius
        this.clip2X = clip2X
        this.clip2Y = clip2Y
        this.clip2Width = clip2Width
        this.clip2Height = clip2Height
        this.clip2CornerRadius = clip2CornerRadius
        this.clip3X = clip3X
        this.clip3Y = clip3Y
        this.clip3Width = clip3Width
        this.clip3Height = clip3Height
        this.clip3CornerRadius = clip3CornerRadius
        this.fontSize = fontSize
        this.fontWeight = fontWeight
        this.fontFamily = fontFamily
        this.imageContentMode = imageContentMode
        this.fillRed = fillRed
        this.fillGreen = fillGreen
        this.fillBlue = fillBlue
        this.fillAlpha = fillAlpha
        this.borderRed = borderRed
        this.borderGreen = borderGreen
        this.borderBlue = borderBlue
        this.borderAlpha = borderAlpha
        this.textRed = textRed
        this.textGreen = textGreen
        this.textBlue = textBlue
        this.textAlpha = textAlpha
        this.inputScope = inputScope
        this.tabGroupId = tabGroupId
        this.tabSelected = tabSelected
        this.semanticRole = semanticRole
        this.semanticState = semanticState
        this.semanticLevel = semanticLevel
        this.semanticIncarnation = semanticIncarnation
        this.shadowPresent = shadowPresent
        this.shadowOffsetX = shadowOffsetX
        this.shadowOffsetY = shadowOffsetY
        this.shadowBlurRadius = shadowBlurRadius
        this.shadowSpread = shadowSpread
        this.shadowRed = shadowRed
        this.shadowGreen = shadowGreen
        this.shadowBlue = shadowBlue
        this.shadowAlpha = shadowAlpha
        this.gradientPresent = gradientPresent
        this.gradientStopCount = gradientStopCount
        this.gradientStartX = gradientStartX
        this.gradientStartY = gradientStartY
        this.gradientEndX = gradientEndX
        this.gradientEndY = gradientEndY
        this.gradientStop0Position = gradientStop0Position
        this.gradientStop0Red = gradientStop0Red
        this.gradientStop0Green = gradientStop0Green
        this.gradientStop0Blue = gradientStop0Blue
        this.gradientStop0Alpha = gradientStop0Alpha
        this.gradientStop1Position = gradientStop1Position
        this.gradientStop1Red = gradientStop1Red
        this.gradientStop1Green = gradientStop1Green
        this.gradientStop1Blue = gradientStop1Blue
        this.gradientStop1Alpha = gradientStop1Alpha
        this.gradientStop2Position = gradientStop2Position
        this.gradientStop2Red = gradientStop2Red
        this.gradientStop2Green = gradientStop2Green
        this.gradientStop2Blue = gradientStop2Blue
        this.gradientStop2Alpha = gradientStop2Alpha
        this.gradientStop3Position = gradientStop3Position
        this.gradientStop3Red = gradientStop3Red
        this.gradientStop3Green = gradientStop3Green
        this.gradientStop3Blue = gradientStop3Blue
        this.gradientStop3Alpha = gradientStop3Alpha
        this.effectGroupPresent = effectGroupPresent
        this.effectGroupSubtreeCount = effectGroupSubtreeCount
        this.effectGroupOpacity = effectGroupOpacity
        this.effectGroupBlendMode = effectGroupBlendMode
        this.effectMaskPresent = effectMaskPresent
        this.effectMaskStopCount = effectMaskStopCount
        this.effectMaskStartX = effectMaskStartX
        this.effectMaskStartY = effectMaskStartY
        this.effectMaskEndX = effectMaskEndX
        this.effectMaskEndY = effectMaskEndY
        this.effectMaskStop0Position = effectMaskStop0Position
        this.effectMaskStop0Alpha = effectMaskStop0Alpha
        this.effectMaskStop1Position = effectMaskStop1Position
        this.effectMaskStop1Alpha = effectMaskStop1Alpha
        this.effectMaskStop2Position = effectMaskStop2Position
        this.effectMaskStop2Alpha = effectMaskStop2Alpha
        this.effectMaskStop3Position = effectMaskStop3Position
        this.effectMaskStop3Alpha = effectMaskStop3Alpha
        this.effectBackdropBlurRadiusPoints = effectBackdropBlurRadiusPoints
        this.effectBackdropBlurFallback = effectBackdropBlurFallback
    }
}

@C
struct CjguiInternalRendererViewport {
    var width: UInt32 = 0
    var height: UInt32 = 0
    var resizeVersion: UInt64 = 0
    var resourceCompletionVersion: UInt64 = 0
}

@C
struct CjguiInternalRendererTextMeasurement {
    var width: UInt32 = 0
    var height: UInt32 = 0
    var lineHeight: UInt32 = 0
    var baseline: UInt32 = 0
}

@C
struct CjguiInternalRendererSharedOperationState {
    var selectedRecordId: Int64 = -1
    var markedRecordMask: UInt64 = 0
    var version: UInt64 = 0
    var selectedRecordIndex: UInt32 = 0
    var recordCount: UInt32 = 0
    var viewportStart: UInt32 = 0
    var totalRecordCount: UInt32 = 0
    init(
        selectedRecordId!: Int64,
        markedRecordMask!: UInt64,
        version!: UInt64,
        selectedRecordIndex!: UInt32,
        recordCount!: UInt32,
        viewportStart!: UInt32,
        totalRecordCount!: UInt32
    ) {
        this.selectedRecordId = selectedRecordId
        this.markedRecordMask = markedRecordMask
        this.version = version
        this.selectedRecordIndex = selectedRecordIndex
        this.recordCount = recordCount
        this.viewportStart = viewportStart
        this.totalRecordCount = totalRecordCount
    }
}

// ---- plain internal scalar result records ----
//
// Plain (non-@C) records carrying the real status + frame/event scalars. They
// exist only because @C structs cannot be tuple members in Cangjie. They hold
// real data, not Bool/readiness/facts.

struct InternalRendererCreateResult {
    let token: UInt64
    let status: Int32
    init(token: UInt64, status: Int32) {
        this.token = token
        this.status = status
    }
}

struct InternalRendererFrameResult {
    let status: Int32
    let frameIndex: UInt64
    let drawableWidthPixels: UInt32
    let drawableHeightPixels: UInt32
    let contentsScale: Float64
    let readbackAttempted: UInt8
    let readbackCompleted: UInt8
    let readbackColorMatched: UInt8
    /// A1：本次提交的票据编号（0 = 未登记票据）。非 0 时调用方必须经
    /// queryPresent 取终态并 acknowledgePresent 确认，才能提交下一个候选。
    let ticketId: UInt64
    init(status: Int32, frameIndex: UInt64, drawableWidthPixels: UInt32, drawableHeightPixels: UInt32,
        contentsScale: Float64, readbackAttempted: UInt8, readbackCompleted: UInt8, readbackColorMatched: UInt8,
        ticketId!: UInt64 = 0) {
        this.status = status
        this.frameIndex = frameIndex
        this.drawableWidthPixels = drawableWidthPixels
        this.drawableHeightPixels = drawableHeightPixels
        this.contentsScale = contentsScale
        this.readbackAttempted = readbackAttempted
        this.readbackCompleted = readbackCompleted
        this.readbackColorMatched = readbackColorMatched
        this.ticketId = ticketId
    }
}

/// A1：queryPresent 的仓颉侧回执（不把 C POD 布局带进核心）。
struct InternalRendererPresentReceipt {
    let status: Int32
    let ticketId: UInt64
    let projectionVersion: UInt64
    let decision: UInt32
    let terminalStatus: Int32
    let frameIndex: UInt64
    let contentsScale: Float64
    let resyncRequired: Bool
    let settled: Bool
    init(status: Int32, ticketId: UInt64, projectionVersion: UInt64, decision: UInt32, terminalStatus: Int32,
        frameIndex: UInt64, contentsScale: Float64, resyncRequired: Bool, settled: Bool) {
        this.status = status
        this.ticketId = ticketId
        this.projectionVersion = projectionVersion
        this.decision = decision
        this.terminalStatus = terminalStatus
        this.frameIndex = frameIndex
        this.contentsScale = contentsScale
        this.resyncRequired = resyncRequired
        this.settled = settled
    }
}

/// A1：present 票据取证计数（见 ABI 头字段说明）。available=false 表示该平台
/// 没有实现计数入口，此时所有值都不得被当作事实使用。
struct InternalRendererTicketStats {
    let nextTicketId: Int64
    let unackedTicketId: Int64
    let acceptedCount: Int64
    let rejectedCount: Int64
    let queryCount: Int64
    let ackCount: Int64
    let duplicateSettlementCount: Int64
    let destroyRefusedCount: Int64
    let available: Bool
    init(nextTicketId: Int64, unackedTicketId: Int64, acceptedCount: Int64, rejectedCount: Int64, queryCount: Int64,
        ackCount: Int64, duplicateSettlementCount: Int64, destroyRefusedCount: Int64, available: Bool) {
        this.nextTicketId = nextTicketId
        this.unackedTicketId = unackedTicketId
        this.acceptedCount = acceptedCount
        this.rejectedCount = rejectedCount
        this.queryCount = queryCount
        this.ackCount = ackCount
        this.duplicateSettlementCount = duplicateSettlementCount
        this.destroyRefusedCount = destroyRefusedCount
        this.available = available
    }
}

@C
struct InternalRendererActivationPrefix {
    var sessionGeneration: UInt64 = 0u64
    var nonce: UInt64 = 0u64
    var sceneVersion: UInt64 = 0u64
    var nodeId: UInt64 = 0u64
    var resourceId: Int64 = 0
    var bindingEpoch: UInt64 = 0u64
    var nodeKind: UInt32 = 0u32
    var ordinal: UInt32 = 0u32
    var secondKind: UInt32 = 0u32
    var memberCount: UInt32 = 0u32
    var memberKind: UInt32 = 0u32
}

struct InternalRendererPumpResult {
    let activationPrefix: InternalRendererActivationPrefix
    let installedRangeOwned: Bool
    let installedRangeClaim: ?InternalRendererInstalledRangeClaim
    let status: Int32
    let eventKind: UInt32
    let recordIndex: UInt32
    let selectionStart: UInt32
    let selectionEnd: UInt32
    let nodeId: UInt64
    let projectionVersion: UInt64
    let resourceId: Int64
    let nodeKind: UInt32
    let pointerX: Int64
    let pointerY: Int64
    let pointerVisualX: Float64
    let pointerVisualY: Float64
    let pointerTranslateX: Float64
    let pointerTranslateY: Float64
    let pointerGeometryAccepted: Bool
    let modifierFlags: Int64
    let compositionPhase: UInt32
    let replacementStart16: Int64
    let replacementLength16: Int64
    let markedStart16: Int64
    let markedLength16: Int64
    let compositionId: UInt64
    let bindingEpoch: UInt64
    let dataTransferEventId: UInt64
    let gestureAppInstance: UInt64
    let gestureComponentInstance: UInt64
    let gestureSurfaceGeneration: UInt64
    let gesturePointerId: Int64
    let gestureEpoch: UInt64
    let acceptedBindingEpoch: UInt64
    let inputSessionGeneration: UInt64
    let inputSequence: UInt64
    let inputPreviousSequence: UInt64
    init(status: Int32, eventKind: UInt32, recordIndex: UInt32, selectionStart: UInt32, selectionEnd: UInt32,
        nodeId: UInt64, projectionVersion: UInt64, resourceId: Int64, nodeKind: UInt32, pointerX: Int64,
        pointerY: Int64, pointerVisualX: Float64, pointerVisualY: Float64, pointerTranslateX: Float64,
        pointerTranslateY: Float64, pointerGeometryAccepted: Bool, modifierFlags: Int64,
        compositionPhase: UInt32, replacementStart16: Int64,
        replacementLength16: Int64, markedStart16: Int64, markedLength16: Int64, compositionId: UInt64,
        bindingEpoch: UInt64, dataTransferEventId: UInt64,
        gestureAppInstance: UInt64, gestureComponentInstance: UInt64,
        gestureSurfaceGeneration: UInt64, gesturePointerId: Int64,
        gestureEpoch: UInt64, acceptedBindingEpoch: UInt64,
        installedRangeOwned!: Bool = false,
        installedRangeClaim!: ?InternalRendererInstalledRangeClaim = None,
        activationPrefix!: InternalRendererActivationPrefix = InternalRendererActivationPrefix(),
        inputSessionGeneration!: UInt64 = 0u64, inputSequence!: UInt64 = 0u64,
        inputPreviousSequence!: UInt64 = 0u64) {
        this.activationPrefix = activationPrefix
        this.installedRangeOwned = installedRangeOwned
        this.installedRangeClaim = installedRangeClaim
        this.status = status
        this.eventKind = eventKind
        this.recordIndex = recordIndex
        this.selectionStart = selectionStart
        this.selectionEnd = selectionEnd
        this.nodeId = nodeId
        this.projectionVersion = projectionVersion
        this.resourceId = resourceId
        this.nodeKind = nodeKind
        this.pointerX = pointerX
        this.pointerY = pointerY
        this.pointerVisualX = pointerVisualX
        this.pointerVisualY = pointerVisualY
        this.pointerTranslateX = pointerTranslateX
        this.pointerTranslateY = pointerTranslateY
        this.pointerGeometryAccepted = pointerGeometryAccepted
        this.modifierFlags = modifierFlags
        this.compositionPhase = compositionPhase
        this.replacementStart16 = replacementStart16
        this.replacementLength16 = replacementLength16
        this.markedStart16 = markedStart16
        this.markedLength16 = markedLength16
        this.compositionId = compositionId
        this.bindingEpoch = bindingEpoch
        this.dataTransferEventId = dataTransferEventId
        this.gestureAppInstance = gestureAppInstance
        this.gestureComponentInstance = gestureComponentInstance
        this.gestureSurfaceGeneration = gestureSurfaceGeneration
        this.gesturePointerId = gesturePointerId
        this.gestureEpoch = gestureEpoch
        this.acceptedBindingEpoch = acceptedBindingEpoch
        this.inputSessionGeneration = inputSessionGeneration
        this.inputSequence = inputSequence
        this.inputPreviousSequence = inputPreviousSequence
    }
}

struct InternalRendererViewportResult {
    let status: Int32
    let width: UInt32
    let height: UInt32
    let resizeVersion: UInt64
    let resourceCompletionVersion: UInt64
    init(status: Int32, width: UInt32, height: UInt32, resizeVersion: UInt64, resourceCompletionVersion: UInt64) {
        this.status = status
        this.width = width
        this.height = height
        this.resizeVersion = resizeVersion
        this.resourceCompletionVersion = resourceCompletionVersion
    }
}

struct InternalRendererImageResourceResult {
    let status: Int32
    let stateCode: UInt32
    init(status: Int32, stateCode: UInt32) {
        this.status = status
        this.stateCode = stateCode
    }
}

struct InternalRendererComposableDisplayProgressResult {
    let status: Int32
    let submittedFrameIndex: UInt64
    let observedMetalCompletionFrameIndex: UInt64
    let observedMetalFailureFrameIndex: UInt64
    let observedMetalGpuDurationMicros: Int64
    let overlayDrawnProjectionVersion: UInt64
    let effectSubmittedSceneVersion: UInt64
    let effectSubmittedFrameIndex: UInt64
    let effectRequestedRadiusPoints: UInt32
    let effectMode: UInt32
    let effectFallbackReason: UInt32
    let effectCompletion: UInt32
    let geometry: CjguiInternalRendererComposableDisplayProgress
    init(status: Int32, submittedFrameIndex: UInt64, observedMetalCompletionFrameIndex: UInt64,
        observedMetalFailureFrameIndex: UInt64, observedMetalGpuDurationMicros: Int64,
        overlayDrawnProjectionVersion: UInt64, effectSubmittedSceneVersion: UInt64,
        effectSubmittedFrameIndex: UInt64, effectRequestedRadiusPoints: UInt32,
        effectMode: UInt32, effectFallbackReason: UInt32, effectCompletion: UInt32,
        geometry: CjguiInternalRendererComposableDisplayProgress) {
        this.status = status
        this.submittedFrameIndex = submittedFrameIndex
        this.observedMetalCompletionFrameIndex = observedMetalCompletionFrameIndex
        this.observedMetalFailureFrameIndex = observedMetalFailureFrameIndex
        this.observedMetalGpuDurationMicros = observedMetalGpuDurationMicros
        this.overlayDrawnProjectionVersion = overlayDrawnProjectionVersion
        this.effectSubmittedSceneVersion = effectSubmittedSceneVersion
        this.effectSubmittedFrameIndex = effectSubmittedFrameIndex
        this.effectRequestedRadiusPoints = effectRequestedRadiusPoints
        this.effectMode = effectMode
        this.effectFallbackReason = effectFallbackReason
        this.effectCompletion = effectCompletion
        this.geometry = geometry
    }
}

struct InternalRendererWindowBackgroundResult {
    let status: Int32
    let snapshot: CjguiInternalRendererWindowBackgroundSnapshot
    init(status: Int32, snapshot: CjguiInternalRendererWindowBackgroundSnapshot) {
        this.status = status
        this.snapshot = snapshot
    }
}

struct InternalRendererSelectionTransferVerifyBResult {
    let status: Int32
    let receipt: CjguiInternalSelectionTransferReceipt
    init(status: Int32, receipt: CjguiInternalSelectionTransferReceipt) {
        this.status = status
        this.receipt = receipt
    }
}

struct InternalRendererActivationPrefixResult {
    let status: Int32
    let prefix: InternalRendererActivationPrefix
    init(status: Int32, prefix: InternalRendererActivationPrefix) {
        this.status = status
        this.prefix = prefix
    }
}

// ---- foreign func declarations (internal/unstable C ABI) ----

foreign {
    func cjgui_internal_renderer_request_application_stop(): Unit

    func cjgui_internal_renderer_complete_application_exit_request(): Unit

    func cjgui_internal_renderer_retain_application_exit_lifecycle_owner(): Unit

    func cjgui_internal_renderer_release_application_exit_lifecycle_owner(): Unit

    func cjgui_internal_renderer_has_unkeyed_application_exit_request(): UInt8

    func cjgui_internal_renderer_create(
        config: CPointer<CjguiInternalRendererConfig>,
        outStatus: CPointer<Int32>
    ): UInt64

    func cjgui_internal_renderer_coordinate_lifetime(session: UInt64,
        outSessionGeneration: CPointer<UInt64>): UInt64

    func cjgui_internal_renderer_owner_consumed_pointer_coordinate_lifetime(session: UInt64,
        outSessionGeneration: CPointer<UInt64>, outCoordinateEpoch: CPointer<UInt64>): Int32

    @When[os == "macOS"]
    func cjgui_internal_renderer_owner_consumed_pointer_fifo(session: UInt64,
        generation: CPointer<UInt64>, binding: CPointer<UInt64>, first: CPointer<UInt64>,
        last: CPointer<UInt64>, previous: CPointer<UInt64>, phase: CPointer<UInt32>): Int32

    @When[os == "macOS"]
    func cjgui_internal_renderer_selection_background_version(): UInt32

    func cjgui_internal_renderer_set_window_title(session: UInt64, title: CString): Int32

    func cjgui_internal_renderer_stage_window_background(
        session: UInt64, projectionVersion: UInt64, mode: UInt32, colorScheme: UInt32
    ): Int32

    func cjgui_internal_renderer_window_background_snapshot(
        session: UInt64, outSnapshot: CPointer<CjguiInternalRendererWindowBackgroundSnapshot>
    ): Int32

    func cjgui_internal_renderer_set_composable_range_edit_delta(session: UInt64, enabled: Int32): Int32

    func cjgui_internal_renderer_set_composable_owned_text_session(
        session: UInt64,
        nodeId: UInt64,
        resourceId: Int64,
        nodeKind: UInt32,
        bindingEpoch: UInt64,
        enabled: Int32
    ): Int32

    func cjgui_internal_renderer_set_composable_context_menu_guard(
        session: UInt64,
        sceneVersion: UInt64,
        layerScope: UInt64,
        requestId: UInt64,
        layerNodeId: UInt64,
        resourceId: Int64,
        nodeKind: UInt32,
        x: Int64,
        y: Int64,
        width: Int64,
        height: Int64,
        enabled: UInt32
    ): Int32

    func cjgui_internal_renderer_recover_active_text_proxy(
        session: UInt64,
        nodeId: UInt64,
        resourceId: Int64,
        nodeKind: UInt32,
        acceptedValue: CString,
        outSelectionStart: CPointer<UInt32>,
        outSelectionEnd: CPointer<UInt32>
    ): Int32

    func cjgui_internal_renderer_present_clear(
        session: UInt64,
        color: CPointer<CjguiInternalRendererClearColor>,
        outObservation: CPointer<CjguiInternalRendererFrameObservation>
    ): Int32

    func cjgui_internal_renderer_begin_composable_preparation(session: UInt64, preparationId: UInt64,
        baseSceneVersion: UInt64, projectionVersion: UInt64, nodeCount: UInt32): Int32
    func cjgui_internal_renderer_prepare_composable_node(session: UInt64, preparationId: UInt64, nodeIndex: UInt32,
        node: CPointer<CjguiInternalRendererComposableNode>, geometry: CPointer<CjguiInternalRendererComposableGeometry>,
        label: CString, value: CString, semanticId: CString, bindingKey: CString, rowKey: CString,
        parentRowKey: CString, semanticLabel: CString, encodedRuns: CString): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_prepare_composable_node_batch(session: UInt64, preparationId: UInt64,
        firstIndex: UInt32, count: UInt32, nodes: CPointer<CjguiInternalRendererComposableNode>,
        geometry: CPointer<CjguiInternalRendererComposableGeometry>, strings: CPointer<CString>,
        deadlineNs: UInt64, outCopied: CPointer<UInt32>): Int32
    func cjgui_internal_renderer_advance_composable_preparation(session: UInt64, preparationId: UInt64,
        deadlineNs: UInt64, outReady: CPointer<UInt32>): Int32
    func cjgui_internal_renderer_promote_composable_preparation(session: UInt64, preparationId: UInt64): Int32
    func cjgui_internal_renderer_cancel_composable_preparation(session: UInt64, preparationId: UInt64): Int32

    func cjgui_internal_renderer_configure_composable_scene(
        session: UInt64,
        projectionVersion: UInt64,
        nodeCount: UInt32
    ): Int32

    func cjgui_internal_renderer_set_composable_scene_geometry(
        session: UInt64, projectionVersion: UInt64, nodeIndex: UInt32,
        geometry: CPointer<CjguiInternalRendererComposableGeometry>
    ): Int32

    func cjgui_internal_renderer_discard_composable_scene_candidate(session: UInt64): Int32

    func cjgui_internal_renderer_set_composable_scene_node(
        session: UInt64,
        nodeIndex: UInt32,
        node: CPointer<CjguiInternalRendererComposableNode>,
        label: CString,
        value: CString,
        imageResourcePath: CString,
        imageResourceId: CString,
        imageResourceVersion: UInt64
    ): Int32

    func cjgui_internal_renderer_set_composable_scene_node_bytes(
        session: UInt64, nodeIndex: UInt32, node: CPointer<CjguiInternalRendererComposableNode>,
        label: CString, value: CString, imageResourcePath: CString, imageResourceId: CString,
        imageResourceVersion: UInt64, bytes: CPointer<UInt8>, length: UInt32
    ): Int32

    func cjgui_internal_renderer_prepare_composable_png_transfer(
        session: UInt64, resourceIdentity: CString, bytes: CPointer<UInt8>, length: UInt32,
        outWidth: CPointer<UInt32>, outHeight: CPointer<UInt32>, outDecodeMicros: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_finish_composable_png_transfer(
        session: UInt64, resourceIdentity: CString, accepted: UInt8
    ): Int32

    func cjgui_internal_renderer_set_composable_node_semantic_identity(
        session: UInt64,
        nodeIndex: UInt32,
        semanticId: CString
    ): Int32

    func cjgui_internal_renderer_set_composable_node_semantic_metadata(
        session: UInt64,
        nodeIndex: UInt32,
        bindingKey: CString,
        rowKey: CString,
        parentRowKey: CString,
        semanticLabel: CString
    ): Int32

    func cjgui_internal_renderer_configure_composable_data_transfer(
        session: UInt64,
        projectionVersion: UInt64,
        itemCount: UInt32
    ): Int32

    func cjgui_internal_renderer_set_composable_data_transfer_item(
        session: UInt64,
        itemIndex: UInt32,
        item: CPointer<CjguiInternalRendererComposableDataTransferItem>,
        format: CString,
        payload: CString,
        sourceKind: CString,
        sourceIdentity: CString
    ): Int32

    func cjgui_internal_renderer_set_composable_data_transfer_item_bytes(
        session: UInt64, itemIndex: UInt32, bytes: CPointer<UInt8>, length: UInt32
    ): Int32

    func cjgui_internal_renderer_present_composable_scene(
        session: UInt64,
        outObservation: CPointer<CjguiInternalRendererFrameObservation>
    ): Int32

    func cjgui_internal_renderer_cancel_composition(
        session: UInt64,
        outHadMarked: CPointer<Int32>,
        outCancelReturned: CPointer<Int32>
    ): Int32

    func cjgui_internal_renderer_window_number(
        session: UInt64,
        outNumber: CPointer<Int64>
    ): Int32

    func cjgui_internal_renderer_probe_image_texture(
        session: UInt64,
        nodeId: UInt64,
        outFound: CPointer<Int32>,
        outHasTexture: CPointer<Int32>,
        outCacheKeyLength: CPointer<Int32>,
        outFailed: CPointer<Int32>
    ): Int32

    func cjgui_internal_renderer_declare_input_caret(
        session: UInt64,
        nodeId: Int64,
        x: Float64,
        y: Float64,
        width: Float64,
        height: Float64
    ): Int32
    // A1 票据协议：查询原提交（只读终态，不 configure/build/Flush）与确认回执。
    func cjgui_internal_renderer_query_present(
        session: UInt64,
        ticketId: UInt64,
        outReceipt: CPointer<CjguiInternalRendererPresentReceipt>
    ): Int32

    func cjgui_internal_renderer_acknowledge_present(session: UInt64, ticketId: UInt64): Int32

    func cjgui_internal_renderer_test_hold_next_composable_present(session: UInt64): Int32
    func cjgui_internal_renderer_test_resolve_pending_composable_present(session: UInt64): Int32

    func cjgui_internal_renderer_present_ticket_stats(
        session: UInt64,
        out: CPointer<CjguiInternalRendererPresentTicketStats>
    ): Int32

    func cjgui_internal_renderer_configure_composable_command_menu(
        session: UInt64,
        projectionVersion: UInt64,
        itemCount: UInt32
    ): Int32

    func cjgui_internal_renderer_set_composable_command_menu_item(
        session: UInt64,
        itemIndex: UInt32,
        commandId: CString,
        title: CString,
        menuGroup: CString,
        shortcut: CString,
        menuSection: UInt32,
        focusScope: UInt64,
        enabled: UInt8,
        checked: UInt8
    ): Int32

    func cjgui_internal_renderer_commit_composable_command_menu(session: UInt64): Int32

    func cjgui_internal_renderer_prepare_composable_image_resource(
        session: UInt64,
        resourcePath: CString,
        resourceId: CString,
        resourceVersion: UInt64,
        outState: CPointer<UInt32>
    ): Int32

    func cjgui_internal_renderer_composable_image_resource_state(
        session: UInt64,
        resourcePath: CString,
        resourceId: CString,
        resourceVersion: UInt64,
        outState: CPointer<UInt32>
    ): Int32

    func cjgui_internal_renderer_composable_viewport(
        session: UInt64,
        outViewport: CPointer<CjguiInternalRendererViewport>
    ): Int32

    func cjgui_internal_renderer_composable_display_progress(
        session: UInt64,
        outProgress: CPointer<CjguiInternalRendererComposableDisplayProgress>
    ): Int32

    func cjgui_internal_renderer_diagnostic_node_geometry(
        session: UInt64, nodeIndex: UInt32,
        outGeometry: CPointer<CjguiInternalRendererDiagnosticNodeGeometry>
    ): Int32

    func cjgui_internal_renderer_diagnostic_resources(
        session: UInt64, outResources: CPointer<CjguiInternalRendererDiagnosticResources>
    ): Int32

    func cjgui_internal_renderer_diagnostic_workload(
        session: UInt64, outWorkload: CPointer<CjguiInternalRendererDiagnosticWorkload>
    ): Int32

    @When[os == "macOS"]
    func cjgui_internal_renderer_diagnostic_scalar_snapshot(session: UInt64,
        expectedGeneration: UInt64, expectedSceneVersion: UInt64,
        outProgress: CPointer<CjguiInternalRendererComposableDisplayProgress>,
        outWorkload: CPointer<CjguiInternalRendererDiagnosticWorkload>,
        outTiming: CPointer<CjguiInternalRendererDiagnosticTiming>): Int32

    func cjgui_internal_renderer_set_diagnostic_timing(session: UInt64, enabled: UInt32): Int32

    // Internal, opt-in phase clock. Zero means diagnostics are disabled.
    func cjgui_internal_renderer_owner_trace_ns(): UInt64
    func cjgui_internal_renderer_owner_clock_ns(): UInt64
    func cjgui_internal_renderer_owner_thread_cpu_ns(): UInt64
    @When[os == "macOS"]
    func cjgui_internal_renderer_owner_trace_record(kind: UInt32, session: UInt64,
        turn: UInt64, request: UInt64, dispatch: UInt64, generation: UInt64,
        phase: UInt32, span: UInt64): UInt64
    func cjgui_internal_renderer_owner_trace_managed_record(kind: UInt32, session: UInt64,
        turn: UInt64, request: UInt64, dispatch: UInt64, generation: UInt64,
        phase: UInt32, span: UInt64, managedId: UInt64, withWatch: UInt8): UInt64
    @When[os == "macOS"]
    func cjgui_internal_renderer_owner_trace_boundary(session: UInt64, turn: UInt64,
        stage: UInt32, relatedKind: UInt32, relatedPhase: UInt32, value: UInt64,
        managedId: UInt64): Unit
    @When[os == "macOS"]
    func cjgui_internal_renderer_owner_trace_dispatch_begin(session: UInt64, turn: UInt64,
        request: UInt64, generation: UInt64, phase: UInt32, span: UInt64): UInt64
    @When[os == "macOS"]
    func cjgui_internal_renderer_owner_trace_set_turn(turn: UInt64): Unit
    @When[os == "macOS"]
    func cjgui_internal_renderer_owner_trace_dispatch_event(kind: UInt32, session: UInt64,
        turn: UInt64, request: UInt64, dispatch: UInt64, generation: UInt64,
        phase: UInt32, span: UInt64): Unit
    @When[os == "macOS"]
    func cjgui_internal_renderer_owner_trace_export(): Unit
    @When[os == "macOS"]
    func cjgui_internal_renderer_finalize_owner_trace(): UInt8
    @When[os == "macOS"]
    func cjgui_internal_renderer_acquire_application_cleanup(): UInt64
    @When[os == "macOS"]
    func cjgui_internal_renderer_complete_application_cleanup(ticket: UInt64): UInt8
    @When[os == "macOS"]
    func cjgui_internal_renderer_owner_trace_legacy_span(session: UInt64, turn: UInt64,
        request: UInt64, generation: UInt64, phase: UInt32, startedNs: UInt64): Unit
    func cjgui_internal_renderer_source_install_pending_scalar(session: UInt64): UInt8
    @When[os == "macOS" || os == "Windows"]
    func cjgui_internal_renderer_installed_range_arm(session: UInt64,
        candidate: CPointer<CjguiInternalInstalledRangeCandidate>): Int32
    @When[os == "macOS" || os == "Windows"]
    func cjgui_internal_renderer_installed_range_receipt(session: UInt64, nonce: UInt64,
        receipt: CPointer<CjguiInternalInstalledRangeReceipt>): Int32
    @When[os == "macOS" || os == "Windows"]
    func cjgui_internal_renderer_installed_range_active_receipt(session: UInt64, nonce: UInt64,
        receipt: CPointer<CjguiInternalInstalledRangeReceipt>): Int32
    @When[os == "macOS" || os == "Windows"]
    func cjgui_internal_renderer_installed_range_activate(session: UInt64, nonce: UInt64,
        proxyGeneration: UInt64, selectionRevision: UInt64): Int32
    @When[os == "macOS" || os == "Windows"]
    func cjgui_internal_renderer_installed_range_cancel(session: UInt64, nonce: UInt64): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_selection_transfer_create(session: UInt64, outTransferId: CPointer<UInt64>): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_selection_transfer_publish_pending(session: UInt64, transferId: UInt64): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_selection_transfer_begin_finalizing(session: UInt64, transferId: UInt64): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_selection_transfer_request_cancel(session: UInt64, transferId: UInt64): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_selection_transfer_commit(session: UInt64, transferId: UInt64): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_selection_transfer_finish_abort(session: UInt64, transferId: UInt64): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_selection_transfer_recovery_blocked(session: UInt64, transferId: UInt64): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_selection_transfer_state(session: UInt64, transferId: UInt64,
        outState: CPointer<UInt32>, outCancelled: CPointer<UInt8>, outReferences: CPointer<UInt32>): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_selection_transfer_admit_input(session: UInt64, transferId: UInt64,
        outAdmission: CPointer<UInt32>): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_selection_transfer_retain(session: UInt64, transferId: UInt64): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_selection_transfer_release(session: UInt64, transferId: UInt64): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_selection_transfer_capture_a(session: UInt64,
        candidate: CPointer<CjguiInternalSelectionTransferCandidate>): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_selection_transfer_capture_current(session: UInt64,
        candidate: CPointer<CjguiInternalSelectionTransferCandidate>, bytes: CPointer<UInt8>, capacity: UInt32): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_selection_transfer_prepare_b(session: UInt64, transferId: UInt64,
        deadlineNs: UInt64, outReady: CPointer<UInt8>): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_selection_transfer_install_b(session: UInt64, transferId: UInt64,
        outReceipt: CPointer<CjguiInternalSelectionTransferReceipt>): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_selection_transfer_verify_b(session: UInt64, transferId: UInt64,
        outReceipt: CPointer<CjguiInternalSelectionTransferReceipt>): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_selection_transfer_restore_a(session: UInt64, transferId: UInt64): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_selection_transfer_replay_input(session: UInt64, transferId: UInt64): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_selection_transfer_discard_capsule(session: UInt64, transferId: UInt64): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_source_handoff_arm(session: UInt64,
        candidate: CPointer<CjguiInternalInstalledRangeCandidate>, expectedBindingEpoch: UInt64,
        expectedNodeId: UInt64, expectedResourceId: Int64, expectedNodeKind: UInt32): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_source_handoff_confirm_selection(session: UInt64, nonce: UInt64,
        selectionStart16: UInt32, selectionEnd16: UInt32): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_source_handoff_activate(session: UInt64, nonce: UInt64,
        proxyGeneration: UInt64, selectionRevision: UInt64): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_source_handoff_finish(session: UInt64, nonce: UInt64): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_source_handoff_cancel(session: UInt64, nonce: UInt64): Int32
    @When[os == "macOS" || os == "Windows"]
    func cjgui_internal_renderer_claim_last_pumped_range(session: UInt64, node: UInt64,
        resource: Int64, binding: UInt64, scene: UInt64,
        intent: CPointer<CjguiInternalInstalledRangeIntent>): Int32
    @When[os == "macOS" || os == "Windows"]
    func cjgui_internal_renderer_copy_claimed_range_bytes(session: UInt64, seq: UInt64,
        preBody: CPointer<UInt8>, preCapacity: UInt32,
        replacement: CPointer<UInt8>, replacementCapacity: UInt32,
        postBody: CPointer<UInt8>, postCapacity: UInt32): Int32
    @When[os == "macOS" || os == "Windows"]
    func cjgui_internal_renderer_ack_installed_range(session: UInt64,
        intent: CPointer<CjguiInternalInstalledRangeIntent>, accepted: UInt32, versionAfter: Int64): Int32
    @When[os == "macOS" || os == "Windows"]
    func cjgui_internal_renderer_release_installed_range(session: UInt64,
        document: UInt64, binding: UInt64): Int32
    func cjgui_internal_renderer_set_source_install_gate(session: UInt64, bindingEpoch: UInt64,
        requestId: UInt64, pending: UInt8): Int32

    func cjgui_internal_renderer_diagnostic_timing(
        session: UInt64, outTiming: CPointer<CjguiInternalRendererDiagnosticTiming>
    ): Int32

    func cjgui_internal_renderer_set_diagnostic_overlay(
        session: UInt64, flags: UInt32, selectedNodeId: UInt64, hasSelection: UInt8
    ): Int32

    func cjgui_internal_renderer_focus_composable_node(session: UInt64, nodeId: UInt64): Int32

    func cjgui_internal_renderer_restore_composable_selection(
        session: UInt64,
        nodeId: UInt64,
        resourceId: Int64,
        nodeKind: UInt32,
        sceneVersion: UInt64,
        expectedValue: CString,
        selectionStart: UInt32,
        selectionEnd: UInt32,
        outSelectionStart: CPointer<UInt32>,
        outSelectionEnd: CPointer<UInt32>
    ): Int32

    func cjgui_internal_renderer_install_owned_source_selection(
        session: UInt64, nodeId: UInt64, resourceId: Int64, sceneVersion: UInt64,
        bindingEpoch: UInt64, requestId: UInt64, deadlineNs: UInt64, value: CString,
        start: UInt32, end: UInt32, outStart: CPointer<UInt32>, outEnd: CPointer<UInt32>,
        outDeferred: CPointer<UInt8>): Int32

    func cjgui_internal_renderer_read_composable_selection(
        session: UInt64,
        nodeId: UInt64,
        resourceId: Int64,
        nodeKind: UInt32,
        sceneVersion: UInt64,
        expectedValue: CString,
        outSelectionStart: CPointer<UInt32>,
        outSelectionEnd: CPointer<UInt32>
    ): Int32

    func cjgui_internal_renderer_reanchor_composition(
        session: UInt64,
        nodeId: UInt64,
        resourceId: Int64,
        nodeKind: UInt32,
        sceneVersion: UInt64,
        newBaseText: CString,
        replacementStart16: UInt32,
        replacementLength16: UInt32,
        outMechanism: CPointer<UInt32>,
        outMarkedStart16: CPointer<UInt32>,
        outMarkedLength16: CPointer<UInt32>,
        outInnerStart16: CPointer<UInt32>,
        outInnerEnd16: CPointer<UInt32>
    ): Int32

    func cjgui_internal_renderer_arm_composition_reanchor(
        session: UInt64,
        nodeId: UInt64,
        resourceId: Int64,
        nodeKind: UInt32,
        baseText: CString,
        replacementStart16: UInt32,
        replacementLength16: UInt32
    ): Int32

    func cjgui_internal_renderer_cancel_composable_pointer_capture(session: UInt64): Int32
    func cjgui_internal_renderer_cancel_composable_pointer_capture_epoch(session: UInt64,
        gestureEpoch: UInt64): Int32
    func cjgui_internal_renderer_cancel_composable_pointer_capture_gesture_key(session: UInt64,
        appInstance: UInt64, componentInstance: UInt64, surfaceGeneration: UInt64,
        pointerId: Int64, gestureEpoch: UInt64): Int32

    func cjgui_internal_renderer_node_rect(
        session: UInt64,
        nodeId: UInt64,
        outX: CPointer<Int64>,
        outY: CPointer<Int64>,
        outWidth: CPointer<Int64>,
        outHeight: CPointer<Int64>
    ): Int32

    func cjgui_internal_renderer_window_activation_state(
        session: UInt64,
        outKey: CPointer<Int32>,
        outMain: CPointer<Int32>,
        outAppActive: CPointer<Int32>
    ): Int32

    func cjgui_internal_renderer_activate_window(session: UInt64): Int32

    func cjgui_internal_renderer_window_frame(
        session: UInt64,
        outX: CPointer<Int64>,
        outY: CPointer<Int64>,
        outWidth: CPointer<Int64>,
        outHeight: CPointer<Int64>
    ): Int32

    func cjgui_internal_renderer_hit_test_composable_text(
        session: UInt64,
        nodeId: UInt64,
        x: Float64,
        y: Float64,
        expectedSceneVersion: UInt64,
        outByteOffset: CPointer<UInt32>,
        outAffinity: CPointer<UInt32>
    ): Int32

    func cjgui_internal_renderer_set_composable_text_runs(
        session: UInt64,
        nodeId: UInt64,
        encoded: CString
    ): Int32

    func cjgui_internal_renderer_measure_composable_text(
        session: UInt64,
        text: CString,
        fontSize: Float64,
        fontWeight: UInt32,
        fontFamily: UInt32,
        maximumWidth: UInt32,
        outMeasurement: CPointer<CjguiInternalRendererTextMeasurement>
    ): Int32

    func cjgui_internal_renderer_measure_composable_multiline_natural_height(
        session: UInt64,
        text: CString,
        fontSize: Float64,
        fontWeight: UInt32,
        fontFamily: UInt32,
        contentWidth: UInt32,
        outHeight: CPointer<UInt32>
    ): Int32

    func cjgui_internal_renderer_composed_prefix_utf8_length(
        utf8: CString,
        inputBytes: UInt64,
        maxOutputBytes: UInt64,
        maxClusters: UInt64,
        inputComplete: UInt8,
        outPrefixBytes: CPointer<UInt64>
    ): Int32

    func cjgui_internal_renderer_pump_event(
        session: UInt64,
        timeoutMs: UInt32,
        outEvent: CPointer<CjguiInternalRendererEvent>
    ): Int32

    func cjgui_internal_renderer_pump_event_measured(session: UInt64, timeoutMs: UInt32,
        outEvent: CPointer<CjguiInternalRendererEvent>, outIdleWaitNs: CPointer<UInt64>): Int32

    func cjgui_internal_renderer_pumped_pointer_geometry(
        session: UInt64,
        outGeometry: CPointer<CjguiInternalRendererPointerEventGeometry>
    ): Int32

    func cjgui_internal_renderer_configure_shared_operation(
        session: UInt64,
        visibleRecordCount: UInt32
    ): Int32

    func cjgui_internal_renderer_set_shared_operation_title(
        session: UInt64,
        recordIndex: UInt32,
        title: CString
    ): Int32

    func cjgui_internal_renderer_set_shared_operation_state(
        session: UInt64,
        state: CPointer<CjguiInternalRendererSharedOperationState>
    ): Int32

    func cjgui_internal_renderer_configure_shared_form(session: UInt64, fieldCount: UInt32): Int32

    func cjgui_internal_renderer_configure_shared_collection_form(
        session: UInt64,
        fieldCount: UInt32,
        visibleRecordCount: UInt32
    ): Int32

    func cjgui_internal_renderer_set_shared_collection_row(
        session: UInt64,
        rowIndex: UInt32,
        title: CString,
        isSelected: UInt8,
        viewportStart: UInt32,
        totalRecordCount: UInt32
    ): Int32

    func cjgui_internal_renderer_set_shared_collection_filter(
        session: UInt64,
        filterText: CString
    ): Int32

    func cjgui_internal_renderer_set_shared_form_field(
        session: UInt64,
        fieldIndex: UInt32,
        label: CString,
        draftText: CString,
        validationError: CString,
        editorKind: UInt32,
        isFocused: UInt8,
        selectionStart: UInt32,
        selectionEnd: UInt32
    ): Int32

    func cjgui_internal_renderer_set_shared_form_status(session: UInt64, statusText: CString): Int32

    func cjgui_internal_renderer_form_event_text(session: UInt64): CString

    func cjgui_internal_renderer_data_transfer_event_format(session: UInt64): CString

    func cjgui_internal_renderer_data_transfer_event_source_kind(session: UInt64): CString

    func cjgui_internal_renderer_data_transfer_event_source_identity(session: UInt64): CString

    func cjgui_internal_renderer_data_transfer_event_source_id(session: UInt64): Int64
    func cjgui_internal_renderer_data_transfer_event_expected_owner_version(session: UInt64): Int64
    func cjgui_internal_renderer_data_transfer_event_delivery_ordinal(session: UInt64): UInt64
    func cjgui_internal_renderer_data_transfer_event_binary_size(session: UInt64, eventId: UInt64): UInt32
    func cjgui_internal_renderer_copy_data_transfer_event_binary(
        session: UInt64, eventId: UInt64, outBytes: CPointer<UInt8>, capacity: UInt32
    ): Int32

    func cjgui_internal_renderer_request_close(session: UInt64): Int32

    func cjgui_internal_renderer_destroy(session: UInt64): Int32

    func cjgui_internal_renderer_occupied_session_count(): UInt32
}

// ---- centralized unsafe call wrappers ----
//
// Each wrapper copies the POD argument into a local var (required for inout),
// performs the single foreign call inside an unsafe block, and returns a plain
// result record. No Objective-C / Metal pointer ever escapes.

func internalRendererRequestApplicationStop(): Unit {
    unsafe { cjgui_internal_renderer_request_application_stop() }
}

func internalRendererCompleteApplicationExitRequest(): Unit {
    unsafe { cjgui_internal_renderer_complete_application_exit_request() }
}

func internalRendererRetainApplicationExitLifecycleOwner(): Unit {
    unsafe { cjgui_internal_renderer_retain_application_exit_lifecycle_owner() }
}

func internalRendererReleaseApplicationExitLifecycleOwner(): Unit {
    unsafe { cjgui_internal_renderer_release_application_exit_lifecycle_owner() }
}

func internalRendererHasUnkeyedApplicationExitRequest(): Bool {
    return unsafe { cjgui_internal_renderer_has_unkeyed_application_exit_request() } != 0u8
}

func internalRendererCreate(config: CjguiInternalRendererConfig): InternalRendererCreateResult {
    var cfg = config
    var status: Int32 = 0
    var token: UInt64 = CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN
    unsafe {
        token = cjgui_internal_renderer_create(inout cfg, inout status)
    }
    return InternalRendererCreateResult(token, status)
}

func internalRendererSetWindowTitle(session: UInt64, title: String): Int32 {
    let cTitle = unsafe { LibC.mallocCString(title) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (titleResource = cTitle.asResource()) {
        unsafe { status = cjgui_internal_renderer_set_window_title(session, titleResource.value) }
    }
    return status
}

func internalRendererStageWindowBackground(session: UInt64, projectionVersion: UInt64, mode: UInt32,
    colorScheme: UInt32): Int32 {
    return unsafe { cjgui_internal_renderer_stage_window_background(session, projectionVersion, mode, colorScheme) }
}

// Pure atomic private lifetime read; never waits on AppKit or owns a native object.
func internalRendererCoordinateLifetime(session: UInt64): (UInt64, UInt64) {
    var generation: UInt64 = 0u64
    let coordinate = unsafe { cjgui_internal_renderer_coordinate_lifetime(session, inout generation) }
    return (generation, coordinate)
}

func internalRendererConsumedPointerCoordinateLifetime(session: UInt64): (UInt64, UInt64) {
    var generation: UInt64 = 0u64
    var coordinate: UInt64 = 0u64
    let ok = unsafe { cjgui_internal_renderer_owner_consumed_pointer_coordinate_lifetime(
        session, inout generation, inout coordinate) }
    return if (ok == 1) { (generation, coordinate) } else { (0u64, 0u64) }
}

@When[os == "macOS"]
func internalRendererConsumedPointerFifo(session: UInt64): CjguiMacSliderPointerFifo {
    var generation: UInt64 = 0u64
    var binding: UInt64 = 0u64
    var first: UInt64 = 0u64
    var last: UInt64 = 0u64
    var previous: UInt64 = 0u64
    var phase: UInt32 = 0u32
    let ok = unsafe { cjgui_internal_renderer_owner_consumed_pointer_fifo(session,
        inout generation, inout binding, inout first, inout last, inout previous, inout phase) }
    return if (ok == 1) { CjguiMacSliderPointerFifo(generation, binding, first, last, previous, phase) }
        else { CjguiMacSliderPointerFifo(0u64, 0u64, 0u64, 0u64, 0u64, 0u32) }
}

@When[os != "macOS"]
func internalRendererConsumedPointerFifo(session: UInt64): CjguiMacSliderPointerFifo {
    return CjguiMacSliderPointerFifo(0u64, 0u64, 0u64, 0u64, 0u64, 0u32)
}

@When[os == "macOS"]
func internalRendererSelectionBackgroundVersion(): UInt32 {
    return unsafe { cjgui_internal_renderer_selection_background_version() }
}

@When[os != "macOS"]
func internalRendererSelectionBackgroundVersion(): UInt32 { return 0u32 }

func internalRendererWindowBackgroundSnapshot(session: UInt64): InternalRendererWindowBackgroundResult {
    var snapshot = CjguiInternalRendererWindowBackgroundSnapshot()
    let status = unsafe { cjgui_internal_renderer_window_background_snapshot(session, inout snapshot) }
    return InternalRendererWindowBackgroundResult(status, snapshot)
}

func internalRendererPresentClear(session: UInt64, color: CjguiInternalRendererClearColor): InternalRendererFrameResult {
    var col = color
    var observation = CjguiInternalRendererFrameObservation()
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        status = cjgui_internal_renderer_present_clear(session, inout col, inout observation)
    }
    return InternalRendererFrameResult(
        status,
        observation.frameIndex,
        observation.drawableWidthPixels,
        observation.drawableHeightPixels,
        observation.contentsScale,
        observation.readbackAttempted,
        observation.readbackCompleted,
        observation.readbackColorMatched
    )
}

@C
struct CjguiInternalRendererFrameObservationCanary {
    var observation: CjguiInternalRendererFrameObservation = CjguiInternalRendererFrameObservation()
    var canaryTail1: UInt64 = 0xA5A5A5A55A5A5A5A
    var canaryTail2: UInt64 = 0x5A5A5A5AA5A5A5A5
}

// Keep the canary's direct CFunc call in the declaration's compilation unit.
// A cjpm unittest body is linked from `cjgui$test`; its direct reference to a
// private foreign declaration can acquire a package-prefixed linker symbol.
// This still passes the nested observation field to the exact native writer.
func internalRendererPresentClearCanaryInvalidSession(): Bool {
    var wrapper = CjguiInternalRendererFrameObservationCanary()
    let status = unsafe { cjgui_internal_renderer_present_clear(
        987654321, CPointer<CjguiInternalRendererClearColor>(), inout wrapper.observation) }
    return status == CJGUI_INTERNAL_RENDERER_INVALID_SESSION && wrapper.observation.frameIndex == 0 &&
        wrapper.observation.ticketId == 0 && wrapper.canaryTail1 == 0xA5A5A5A55A5A5A5A &&
        wrapper.canaryTail2 == 0x5A5A5A5AA5A5A5A5
}

@C
struct CjguiInternalRendererEventCanary {
    var event: CjguiInternalRendererEvent = CjguiInternalRendererEvent()
    var canaryTail1: UInt64 = 0xA5A5A5A55A5A5A5A
    var canaryTail2: UInt64 = 0x5A5A5A5AA5A5A5A5
}

// pump_event 的 native 端先按自己的 sizeof(Event) 清零整块再写字段:仓颉镜像
// 偏小会被完整清零越界写坏哨兵,偏大则读不到 native 写入的字段尾部。无效会话
// 仍走这条清零路径,因此这个形状能同时锁尺寸与写入边界。
func internalRendererPumpEventCanaryInvalidSession(): Bool {
    var wrapper = CjguiInternalRendererEventCanary()
    let status = unsafe { cjgui_internal_renderer_pump_event(987654321, 0, inout wrapper.event) }
    return status == CJGUI_INTERNAL_RENDERER_INVALID_SESSION && wrapper.event.kind == 0 &&
        wrapper.event.compositionPhase == 0 && wrapper.event.bindingEpoch == 0 &&
        wrapper.event.gestureEpoch == 0 && wrapper.event.acceptedBindingEpoch == 0 &&
        wrapper.canaryTail1 == 0xA5A5A5A55A5A5A5A && wrapper.canaryTail2 == 0x5A5A5A5AA5A5A5A5
}

func internalRendererPumpEvent(session: UInt64, timeoutMs: UInt32,
    budget!: ?CjguiOwnerTurnBudget = None): InternalRendererPumpResult {
    var event = CjguiInternalRendererEvent()
    var geometry = CjguiInternalRendererPointerEventGeometry()
    var activationPrefix = InternalRendererActivationPrefix()
    var inputProvenance = InternalRendererInputProvenance(0u64, 0u64, 0u64, 0u32)
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        if (let Some(ownerBudget) <- budget) {
            var idleWaitNs: UInt64 = 0
            cjguiOwnerTraceBoundary(session, 0u64, 300u32, 0u32, timeoutMs, 0u64, UInt64.Max)
            status = cjgui_internal_renderer_pump_event_measured(session, timeoutMs, inout event, inout idleWaitNs)
            cjguiOwnerTraceBoundary(session, 0u64, 301u32, event.kind, timeoutMs, idleWaitNs, UInt64.Max)
            ownerBudget.creditPumpIdle(Int64(idleWaitNs))
            cjguiOwnerTraceBoundary(session, 0u64, 302u32, event.kind, timeoutMs, idleWaitNs, UInt64.Max)
        } else {
            status = cjgui_internal_renderer_pump_event(session, timeoutMs, inout event)
        }
        // NONE has no captured pointer. Its geometry query used to synchronously
        // revisit AppKit after the measured idle wait. For real events, native
        // returns the geometry copied with this consumed event's private ticket.
        if (status == CJGUI_INTERNAL_RENDERER_OK && event.kind != 0u32) {
            let prefix = internalRendererConsumedActivationPrefix(session)
            activationPrefix = prefix.prefix
            if (prefix.status != CJGUI_INTERNAL_RENDERER_OK) { status = prefix.status }
            let geometryStatus = cjgui_internal_renderer_pumped_pointer_geometry(session, inout geometry)
            if (geometryStatus != CJGUI_INTERNAL_RENDERER_OK) { geometry.present = 0 }
            inputProvenance = internalRendererConsumedInputProvenance(session)
            if (!inputProvenance.isValidFor(event.kind)) {
                inputProvenance = InternalRendererInputProvenance(0u64, 0u64, 0u64, 0u32)
            }
        }
    }
    // Fixed native-ring boundaries use the native clock and actual OS TID.
    // They intentionally do not look up a managed thread or install a watch.
    cjguiOwnerTraceBoundary(session, 0u64, 303u32, event.kind, timeoutMs, inputProvenance.sequence, UInt64.Max)
    let exact = geometry.present == 1u32 && geometry.kind == event.kind && geometry.nodeId == event.nodeId &&
        geometry.projectionVersion == event.projectionVersion && geometry.resourceId == event.resourceId &&
        geometry.nodeKind == event.nodeKind
    let range: (Bool, ?InternalRendererInstalledRangeClaim) = if (status == CJGUI_INTERNAL_RENDERER_OK && event.kind == 51u32) {
        internalRendererClaimInstalledRange(session, event.nodeId, event.resourceId,
            event.bindingEpoch, event.projectionVersion)
    } else { (false, None) }
    let result = InternalRendererPumpResult(status, event.kind, event.recordIndex, event.selectionStart, event.selectionEnd,
        event.nodeId, event.projectionVersion, event.resourceId, event.nodeKind, event.pointerX, event.pointerY,
        if (exact) { geometry.x } else { Float64(event.pointerX) },
        if (exact) { geometry.y } else { Float64(event.pointerY) },
        if (exact) { geometry.translateX } else { 0.0 },
        if (exact) { geometry.translateY } else { 0.0 }, exact,
        event.modifierFlags, event.compositionPhase, event.replacementStart16, event.replacementLength16,
        event.markedStart16, event.markedLength16, event.compositionId, event.bindingEpoch,
        event.dataTransferEventId, event.gestureAppInstance, event.gestureComponentInstance,
        event.gestureSurfaceGeneration, event.gesturePointerId, event.gestureEpoch,
        event.acceptedBindingEpoch, installedRangeOwned: range[0], installedRangeClaim: range[1],
        activationPrefix: activationPrefix,
        inputSessionGeneration: inputProvenance.sessionGeneration,
        inputSequence: inputProvenance.sequence,
        inputPreviousSequence: inputProvenance.previousSequence)
    cjguiOwnerTraceBoundary(session, 0u64, 304u32, event.kind, timeoutMs, inputProvenance.sequence, UInt64.Max)
    return result
}

@When[os == "macOS"]
foreign {
    func cjgui_internal_renderer_consumed_activation_prefix(
        session: UInt64, outPrefix: CPointer<InternalRendererActivationPrefix>): Int32
    func cjgui_internal_renderer_owner_consumed_input_provenance(session: UInt64,
        outSessionGeneration: CPointer<UInt64>, outSequence: CPointer<UInt64>,
        outPreviousSequence: CPointer<UInt64>, outEventKind: CPointer<UInt32>): Int32
    func cjgui_internal_renderer_finish_caret_input(session: UInt64, generation: UInt64,
        sequence: UInt64, previous: UInt64, outcome: UInt32, nonce: UInt64,
        proxyGeneration: UInt64, selectionRevision: UInt64, ownerVersion: Int64,
        contextEpoch: UInt64, windowToken: UInt64): Int32
    func cjgui_internal_renderer_bind_caret_selection_transfer(session: UInt64, transferId: UInt64,
        generation: UInt64, sequence: UInt64, previousSequence: UInt64): Int32
}

@When[os == "macOS"]
func internalRendererBindCaretSelectionTransfer(session: UInt64, transferId: UInt64,
    input: InternalRendererInputProvenance): Int32 {
    unsafe { cjgui_internal_renderer_bind_caret_selection_transfer(session, transferId,
        input.sessionGeneration, input.sequence, input.previousSequence) }
}
@When[os != "macOS"]
func internalRendererBindCaretSelectionTransfer(session: UInt64, transferId: UInt64,
    input: InternalRendererInputProvenance): Int32 {
    CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}

@When[os == "macOS"]
func internalRendererFinishCaretInput(session: UInt64, input: InternalRendererInputProvenance,
    outcome: UInt32, receipt: ?CjguiInternalInstalledRangeReceipt): Int32 {
    let r = match (receipt) {
        case Some(value) => value
        case None => CjguiInternalInstalledRangeReceipt()
    }
    return unsafe { cjgui_internal_renderer_finish_caret_input(session, input.sessionGeneration,
        input.sequence, input.previousSequence, outcome, r.nonce, r.proxyGeneration,
        r.selectionRevision, r.acceptedVersion, r.contextEpoch, r.windowInstanceToken) }
}
@When[os != "macOS"]
func internalRendererFinishCaretInput(session: UInt64, input: InternalRendererInputProvenance,
    outcome: UInt32, receipt: ?CjguiInternalInstalledRangeReceipt): Int32 {
    CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}

// Immutable, bounded copy of one refused physical input. This private bridge
// carries its actual installation source, never a replacement Node/Event POD.
class InternalRendererCaretRecovery {
    let session: UInt64
    let metadata: Array<UInt64>
    let content: String
    let reason: String
    init(session: UInt64, metadata: Array<UInt64>, content: String, reason: String) {
        this.session = session
        this.metadata = metadata
        this.content = content
        this.reason = reason
    }
}

@When[os == "macOS"]
foreign {
    func cjgui_internal_renderer_peek_caret_recovery(session: UInt64, metadata: CPointer<UInt64>, count: UInt32): Int32

    func cjgui_internal_renderer_copy_caret_recovery(session: UInt64, generation: UInt64, recoveryId: UInt64,
        payload: CPointer<UInt8>, payloadLength: UInt32, reason: CPointer<UInt8>, reasonLength: UInt32): Int32

    func cjgui_internal_renderer_finish_caret_recovery(session: UInt64, generation: UInt64, recoveryId: UInt64,
        disposition: UInt32): Int32

    func cjgui_internal_renderer_cancel_caret_prefix(session: UInt64, windowToken: UInt64, bindingEpoch: UInt64): Int32
}

@When[os == "macOS"]
func internalRendererPeekCaretRecovery(session: UInt64): (Int32, ?InternalRendererCaretRecovery) {
    let metadata = Array<UInt64>(21, repeat: 0u64)
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        let out = acquireArrayRawData(metadata)
        status = cjgui_internal_renderer_peek_caret_recovery(session, out.pointer, 21u32)
        releaseArrayRawData(out)
    }
    if (status != CJGUI_INTERNAL_RENDERER_OK || metadata[0] == 0u64) {
        return (status, None)
    }
    if (metadata[0] >= 281474976710656u64 || metadata[1] == 0u64 || metadata[12] > 262144u64 || metadata[18] > 256u64 ||
        metadata[4] > UInt64(Int64.Max) || metadata[5] > UInt64(Int64.Max) || metadata[6] > metadata[7] || metadata[7] >
        UInt64(Int64.Max)) {
        return (CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID, None)
    }
    let payload = Array<UInt8>(Int64(metadata[12]), repeat: 0u8)
    let reason = Array<UInt8>(Int64(metadata[18]), repeat: 0u8)
    unsafe {
        let p = acquireArrayRawData(payload);
        let r = acquireArrayRawData(reason)
        status = cjgui_internal_renderer_copy_caret_recovery(session, metadata[1], metadata[0], p.pointer,
            UInt32(payload.size), r.pointer, UInt32(reason.size))
        releaseArrayRawData(r);
        releaseArrayRawData(p)
    }
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        return (status, None)
    }
    return (status, Some(
            InternalRendererCaretRecovery(session, metadata, String.fromUtf8(payload), String.fromUtf8(reason))))
}

@When[os != "macOS"]
func internalRendererPeekCaretRecovery(session: UInt64): (Int32, ?InternalRendererCaretRecovery) {
    return (CJGUI_INTERNAL_RENDERER_OK, None)
}

@When[os == "macOS"]
func internalRendererFinishCaretRecovery(recovery: InternalRendererCaretRecovery, disposition: UInt32): Int32 {
    return unsafe { cjgui_internal_renderer_finish_caret_recovery(recovery.session, recovery.metadata[1],
        recovery.metadata[0], disposition) }
}

@When[os != "macOS"]
func internalRendererFinishCaretRecovery(recovery: InternalRendererCaretRecovery, disposition: UInt32): Int32 {
    CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}

@When[os == "macOS"]
func internalRendererCancelCaretPrefix(session: UInt64, windowToken: UInt64, bindingEpoch: UInt64): Int32 {
    return unsafe { cjgui_internal_renderer_cancel_caret_prefix(session, windowToken, bindingEpoch) }
}

@When[os != "macOS"]
func internalRendererCancelCaretPrefix(session: UInt64, windowToken: UInt64, bindingEpoch: UInt64): Int32 {
    CJGUI_INTERNAL_RENDERER_OK
}

@When[os == "macOS"]
func internalRendererConsumedActivationPrefix(session: UInt64): InternalRendererActivationPrefixResult {
    var value = InternalRendererActivationPrefix()
    let status = unsafe { cjgui_internal_renderer_consumed_activation_prefix(session, inout value) }
    return InternalRendererActivationPrefixResult(status,
        if (status == CJGUI_INTERNAL_RENDERER_OK) { value } else { InternalRendererActivationPrefix() })
}

@When[os != "macOS"]
func internalRendererConsumedActivationPrefix(session: UInt64): InternalRendererActivationPrefixResult {
    return InternalRendererActivationPrefixResult(CJGUI_INTERNAL_RENDERER_OK, InternalRendererActivationPrefix())
}

struct InternalRendererInputProvenance {
    let sessionGeneration: UInt64
    let sequence: UInt64
    let previousSequence: UInt64
    let eventKind: UInt32
    init(sessionGeneration: UInt64, sequence: UInt64, previousSequence: UInt64, eventKind: UInt32) {
        this.sessionGeneration = sessionGeneration
        this.sequence = sequence
        this.previousSequence = previousSequence
        this.eventKind = eventKind
    }
    func isValidFor(expectedKind: UInt32): Bool {
        return sessionGeneration != 0u64 && sequence != 0u64 &&
            previousSequence != UInt64.Max && previousSequence + 1 == sequence && eventKind == expectedKind
    }
}

@When[os == "macOS"]
func internalRendererConsumedInputProvenance(session: UInt64): InternalRendererInputProvenance {
    var generation: UInt64 = 0u64
    var sequence: UInt64 = 0u64
    var previous: UInt64 = 0u64
    var kind: UInt32 = 0u32
    let status = unsafe { cjgui_internal_renderer_owner_consumed_input_provenance(session,
        inout generation, inout sequence, inout previous, inout kind) }
    if (status == 0) {
        return InternalRendererInputProvenance(0u64, 0u64, 0u64, 0u32)
    }
    return InternalRendererInputProvenance(generation, sequence, previous, kind)
}
@When[os != "macOS"]
func internalRendererConsumedInputProvenance(session: UInt64): InternalRendererInputProvenance {
    return InternalRendererInputProvenance(0u64, 0u64, 0u64, 0u32)
}

@When[os == "macOS"]
func internalRendererInstalledRangeSupported(): Bool { true }
@When[os != "macOS"]
func internalRendererInstalledRangeSupported(): Bool { false }

// 普通来源范围（installed-range 链）能力：macOS 与 Windows 各自实现生产者侧。
// 跨选择 transfer / source-handoff 仍由上面的 macOS-only 能力门控制。
@When[os == "macOS" || os == "Windows"]
func internalRendererSourceRangeSupported(): Bool { true }
@When[os != "macOS" && os != "Windows"]
func internalRendererSourceRangeSupported(): Bool { false }

// 跨选择 transfer 能力：当前仅 macOS 有完整原生实现。Windows 的普通选择提交
// 直接走 restore 路径（原生已实现），不进入 transfer 分支。
@When[os == "macOS"]
func internalRendererSelectionTransferSupported(): Bool { true }
@When[os != "macOS"]
func internalRendererSelectionTransferSupported(): Bool { false }

// Private, macOS-only common decision cell used by owner selection transfers.
// The numeric status is kept internal so tests can drive exact transition
// boundaries without creating a public state API.
@When[os == "macOS"]
func internalRendererCreateSelectionTransfer(session: UInt64): (Int32, UInt64) {
    var transferId: UInt64 = 0u64
    let status = unsafe { cjgui_internal_renderer_selection_transfer_create(session, inout transferId) }
    return (status, transferId)
}
@When[os != "macOS"]
func internalRendererCreateSelectionTransfer(session: UInt64): (Int32, UInt64) {
    return (CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED, 0u64)
}

@When[os == "macOS"]
func internalRendererPublishSelectionTransferPending(session: UInt64, transferId: UInt64): Int32 {
    unsafe { cjgui_internal_renderer_selection_transfer_publish_pending(session, transferId) }
}
@When[os != "macOS"]
func internalRendererPublishSelectionTransferPending(session: UInt64, transferId: UInt64): Int32 {
    CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}

@When[os == "macOS"]
func internalRendererBeginSelectionTransferFinalizing(session: UInt64, transferId: UInt64): Int32 {
    unsafe { cjgui_internal_renderer_selection_transfer_begin_finalizing(session, transferId) }
}
@When[os != "macOS"]
func internalRendererBeginSelectionTransferFinalizing(session: UInt64, transferId: UInt64): Int32 {
    CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}

@When[os == "macOS"]
func internalRendererRequestSelectionTransferCancel(session: UInt64, transferId: UInt64): Int32 {
    unsafe { cjgui_internal_renderer_selection_transfer_request_cancel(session, transferId) }
}
@When[os != "macOS"]
func internalRendererRequestSelectionTransferCancel(session: UInt64, transferId: UInt64): Int32 {
    CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}

@When[os == "macOS"]
func internalRendererCommitSelectionTransfer(session: UInt64, transferId: UInt64): Int32 {
    unsafe { cjgui_internal_renderer_selection_transfer_commit(session, transferId) }
}
@When[os != "macOS"]
func internalRendererCommitSelectionTransfer(session: UInt64, transferId: UInt64): Int32 {
    CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}

@When[os == "macOS"]
func internalRendererFinishSelectionTransferAbort(session: UInt64, transferId: UInt64): Int32 {
    unsafe { cjgui_internal_renderer_selection_transfer_finish_abort(session, transferId) }
}
@When[os != "macOS"]
func internalRendererFinishSelectionTransferAbort(session: UInt64, transferId: UInt64): Int32 {
    CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}

@When[os == "macOS"]
func internalRendererBlockSelectionTransferRecovery(session: UInt64, transferId: UInt64): Int32 {
    unsafe { cjgui_internal_renderer_selection_transfer_recovery_blocked(session, transferId) }
}
@When[os != "macOS"]
func internalRendererBlockSelectionTransferRecovery(session: UInt64, transferId: UInt64): Int32 {
    CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}

@When[os == "macOS"]
func internalRendererSelectionTransferState(session: UInt64, transferId: UInt64): (Int32, UInt32, UInt8, UInt32) {
    var state: UInt32 = 0u32
    var cancelled: UInt8 = 0u8
    var references: UInt32 = 0u32
    let status = unsafe { cjgui_internal_renderer_selection_transfer_state(session, transferId,
        inout state, inout cancelled, inout references) }
    return (status, state, cancelled, references)
}
@When[os != "macOS"]
func internalRendererSelectionTransferState(session: UInt64, transferId: UInt64): (Int32, UInt32, UInt8, UInt32) {
    return (CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED, 0u32, 0u8, 0u32)
}

@When[os == "macOS"]
func internalRendererAdmitSelectionTransferInput(session: UInt64, transferId: UInt64): (Int32, UInt32) {
    var admission: UInt32 = 3u32
    let status = unsafe { cjgui_internal_renderer_selection_transfer_admit_input(session, transferId, inout admission) }
    return (status, admission)
}
@When[os != "macOS"]
func internalRendererAdmitSelectionTransferInput(session: UInt64, transferId: UInt64): (Int32, UInt32) {
    return (CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED, 3u32)
}

@When[os == "macOS"]
func internalRendererRetainSelectionTransfer(session: UInt64, transferId: UInt64): Int32 {
    unsafe { cjgui_internal_renderer_selection_transfer_retain(session, transferId) }
}
@When[os != "macOS"]
func internalRendererRetainSelectionTransfer(session: UInt64, transferId: UInt64): Int32 {
    CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}

@When[os == "macOS"]
func internalRendererReleaseSelectionTransfer(session: UInt64, transferId: UInt64): Int32 {
    unsafe { cjgui_internal_renderer_selection_transfer_release(session, transferId) }
}
@When[os != "macOS"]
func internalRendererReleaseSelectionTransfer(session: UInt64, transferId: UInt64): Int32 {
    CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}

@When[os == "macOS"]
func internalRendererCaptureSelectionTransferCandidate(session: UInt64,
    candidate: CjguiInternalSelectionTransferCandidate, sourceBody: String, targetBody: String): Int32 {
    var frozen = candidate
    let sourceBytes = sourceBody.toArray()
    let targetBytes = targetBody.toArray()
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        let sourceData = acquireArrayRawData(sourceBytes)
        let targetData = acquireArrayRawData(targetBytes)
        frozen.sourceBodyUtf8 = sourceData.pointer
        frozen.sourceBodyUtf8Length = UInt32(sourceBytes.size)
        frozen.targetBodyUtf8 = targetData.pointer
        frozen.targetBodyUtf8Length = UInt32(targetBytes.size)
        status = cjgui_internal_renderer_selection_transfer_capture_a(session, inout frozen)
        releaseArrayRawData(targetData)
        releaseArrayRawData(sourceData)
    }
    return status
}
@When[os != "macOS"]
func internalRendererCaptureSelectionTransferCandidate(session: UInt64,
    candidate: CjguiInternalSelectionTransferCandidate, sourceBody: String, targetBody: String): Int32 {
    CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}

@When[os == "macOS"]
func internalRendererCaptureSelectionTransferA(session: UInt64, transferId: UInt64,
    sourceNodeId: UInt64, sourceProjectionVersion: UInt64, sourceResourceId: Int64,
    sourceNodeKind: UInt32, sourceSceneVersion: UInt64, sourceSelectionStart16: UInt32,
    sourceSelectionEnd16: UInt32, sourceBody: String,
    nodeId: UInt64, projectionVersion: UInt64, resourceId: Int64, nodeKind: UInt32,
    sceneVersion: UInt64, anchor16: UInt32, focus16: UInt32, body: String): Int32 {
    var candidate = CjguiInternalSelectionTransferCandidate()
    candidate.transferId = transferId; candidate.targetNodeId = nodeId
    candidate.sourceNodeId = sourceNodeId
    candidate.sourceProjectionVersion = sourceProjectionVersion
    candidate.sourceResourceId = sourceResourceId
    candidate.sourceNodeKind = sourceNodeKind
    candidate.sourceSceneVersion = sourceSceneVersion
    candidate.sourceSelectionStart16 = sourceSelectionStart16
    candidate.sourceSelectionEnd16 = sourceSelectionEnd16
    candidate.targetProjectionVersion = projectionVersion; candidate.targetResourceId = resourceId
    candidate.targetNodeKind = nodeKind; candidate.targetSceneVersion = sceneVersion
    candidate.targetAnchor16 = anchor16; candidate.targetFocus16 = focus16
    let sourceBytes = sourceBody.toArray()
    let bytes = body.toArray()
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        let sourceData = acquireArrayRawData(sourceBytes)
        let data = acquireArrayRawData(bytes)
        candidate.sourceBodyUtf8 = sourceData.pointer
        candidate.sourceBodyUtf8Length = UInt32(sourceBytes.size)
        candidate.targetBodyUtf8 = data.pointer
        candidate.targetBodyUtf8Length = UInt32(bytes.size)
        status = cjgui_internal_renderer_selection_transfer_capture_a(session, inout candidate)
        releaseArrayRawData(data)
        releaseArrayRawData(sourceData)
    }
    return status
}
@When[os != "macOS"]
func internalRendererCaptureSelectionTransferA(session: UInt64, transferId: UInt64,
    sourceNodeId: UInt64, sourceProjectionVersion: UInt64, sourceResourceId: Int64,
    sourceNodeKind: UInt32, sourceSceneVersion: UInt64, sourceSelectionStart16: UInt32,
    sourceSelectionEnd16: UInt32, sourceBody: String,
    nodeId: UInt64, projectionVersion: UInt64, resourceId: Int64, nodeKind: UInt32,
    sceneVersion: UInt64, anchor16: UInt32, focus16: UInt32, body: String): Int32 {
    CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}

class InternalRendererCaptureSelectionResult {
    let status: Int32
    let candidate: CjguiInternalSelectionTransferCandidate
    let sourceBody: String
    init(status: Int32, candidate: CjguiInternalSelectionTransferCandidate, sourceBody: String) {
        this.status = status; this.candidate = candidate; this.sourceBody = sourceBody
    }
}

@When[os == "macOS"]
func internalRendererCaptureCurrentSelectionTransfer(session: UInt64,
    candidate: CjguiInternalSelectionTransferCandidate, targetBody: String):
    InternalRendererCaptureSelectionResult {
    var frozen = candidate
    let source = Array<UInt8>(65536, repeat: 0u8)
    let target = targetBody.toArray()
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        let output = acquireArrayRawData(source)
        let input = acquireArrayRawData(target)
        frozen.targetBodyUtf8 = input.pointer; frozen.targetBodyUtf8Length = UInt32(target.size)
        status = cjgui_internal_renderer_selection_transfer_capture_current(session, inout frozen,
            output.pointer, 65536u32)
        releaseArrayRawData(input); releaseArrayRawData(output)
    }
    let body = if (status == CJGUI_INTERNAL_RENDERER_OK && frozen.sourceBodyUtf8Length <= 65536u32) {
        String.fromUtf8(source.slice(0, Int64(frozen.sourceBodyUtf8Length)))
    } else { "" }
    return InternalRendererCaptureSelectionResult(status, frozen, body)
}
@When[os != "macOS"]
func internalRendererCaptureCurrentSelectionTransfer(session: UInt64,
    candidate: CjguiInternalSelectionTransferCandidate, targetBody: String):
    InternalRendererCaptureSelectionResult {
    return InternalRendererCaptureSelectionResult(CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED, candidate, "")
}

@When[os == "macOS"]
func internalRendererPrepareSelectionTransferB(session: UInt64, transferId: UInt64,
    deadlineNs: UInt64): (Int32, Bool) {
    var ready = 0u8
    let status = unsafe { cjgui_internal_renderer_selection_transfer_prepare_b(
        session, transferId, deadlineNs, inout ready) }
    return (status, ready != 0u8)
}
@When[os != "macOS"]
func internalRendererPrepareSelectionTransferB(session: UInt64, transferId: UInt64,
    deadlineNs: UInt64): (Int32, Bool) {
    return (CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED, false)
}

@When[os == "macOS"]
func internalRendererInstallSelectionTransferB(session: UInt64, transferId: UInt64):
    InternalRendererSelectionTransferVerifyBResult {
    var receipt = CjguiInternalSelectionTransferReceipt()
    let status = unsafe { cjgui_internal_renderer_selection_transfer_install_b(session, transferId, inout receipt) }
    return InternalRendererSelectionTransferVerifyBResult(status, receipt)
}
@When[os != "macOS"]
func internalRendererInstallSelectionTransferB(session: UInt64, transferId: UInt64):
    InternalRendererSelectionTransferVerifyBResult {
    return InternalRendererSelectionTransferVerifyBResult(
        CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED, CjguiInternalSelectionTransferReceipt())
}

@When[os == "macOS"]
func internalRendererVerifySelectionTransferB(session: UInt64, transferId: UInt64):
    InternalRendererSelectionTransferVerifyBResult {
    var receipt = CjguiInternalSelectionTransferReceipt()
    let status = unsafe { cjgui_internal_renderer_selection_transfer_verify_b(session, transferId, inout receipt) }
    return InternalRendererSelectionTransferVerifyBResult(status, receipt)
}
@When[os != "macOS"]
func internalRendererVerifySelectionTransferB(session: UInt64, transferId: UInt64):
    InternalRendererSelectionTransferVerifyBResult {
    return InternalRendererSelectionTransferVerifyBResult(
        CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED, CjguiInternalSelectionTransferReceipt())
}

@When[os == "macOS"]
func internalRendererRestoreSelectionTransferA(session: UInt64, transferId: UInt64): Int32 {
    unsafe { cjgui_internal_renderer_selection_transfer_restore_a(session, transferId) }
}
@When[os != "macOS"]
func internalRendererRestoreSelectionTransferA(session: UInt64, transferId: UInt64): Int32 {
    CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}

@When[os == "macOS"]
func internalRendererReplaySelectionTransferInput(session: UInt64, transferId: UInt64): Int32 {
    unsafe { cjgui_internal_renderer_selection_transfer_replay_input(session, transferId) }
}
@When[os != "macOS"]
func internalRendererReplaySelectionTransferInput(session: UInt64, transferId: UInt64): Int32 {
    CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}

@When[os == "macOS"]
func internalRendererDiscardSelectionTransferCapsule(session: UInt64, transferId: UInt64): Int32 {
    unsafe { cjgui_internal_renderer_selection_transfer_discard_capsule(session, transferId) }
}
@When[os != "macOS"]
func internalRendererDiscardSelectionTransferCapsule(session: UInt64, transferId: UInt64): Int32 {
    CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}

@When[os == "macOS" || os == "Windows"]
func internalRendererArmInstalledRange(session: UInt64, basis: CjguiInstalledRangeBasis,
    scene: UInt64, node: UInt64, resource: Int64): Int32 {
    var candidate = CjguiInternalInstalledRangeCandidate()
    candidate.nonce = basis.nonce; candidate.windowInstanceToken = basis.document
    candidate.bindingEpoch = basis.binding; candidate.contextEpoch = UInt64(basis.context)
    candidate.mirrorRevision = UInt64(basis.mirror); candidate.ownerVersion = basis.ownerVersion
    candidate.installedSceneVersion = scene; candidate.nodeId = node; candidate.resourceId = resource
    candidate.sourceStartByte = UInt64(basis.sourceStart); candidate.sourceEndByte = UInt64(basis.sourceEnd)
    let bytes = basis.text.toArray()
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        let data = acquireArrayRawData(bytes)
        candidate.sourceTextUtf8 = data.pointer; candidate.sourceTextUtf8Length = UInt32(bytes.size)
        status = cjgui_internal_renderer_installed_range_arm(session, inout candidate)
        releaseArrayRawData(data)
    }
    return status
}
@When[os != "macOS" && os != "Windows"]
func internalRendererArmInstalledRange(session: UInt64, basis: CjguiInstalledRangeBasis,
    scene: UInt64, node: UInt64, resource: Int64): Int32 { CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED }

@When[os == "macOS" || os == "Windows"]
func internalRendererInstalledRangeReceipt(session: UInt64, nonce: UInt64): ?CjguiInternalInstalledRangeReceipt {
    var receipt = CjguiInternalInstalledRangeReceipt()
    let status = unsafe { cjgui_internal_renderer_installed_range_receipt(session, nonce, inout receipt) }
    return if (status == CJGUI_INTERNAL_RENDERER_OK) { Some(receipt) } else { None }
}
@When[os != "macOS" && os != "Windows"]
func internalRendererInstalledRangeReceipt(session: UInt64, nonce: UInt64): ?CjguiInternalInstalledRangeReceipt { None }

@When[os == "macOS" || os == "Windows"]
func internalRendererActiveInstalledRangeReceipt(session: UInt64, nonce: UInt64):
    ?CjguiInternalInstalledRangeReceipt {
    var receipt = CjguiInternalInstalledRangeReceipt()
    let status = unsafe { cjgui_internal_renderer_installed_range_active_receipt(session, nonce, inout receipt) }
    return if (status == CJGUI_INTERNAL_RENDERER_OK) { Some(receipt) } else { None }
}
@When[os != "macOS" && os != "Windows"]
func internalRendererActiveInstalledRangeReceipt(session: UInt64, nonce: UInt64):
    ?CjguiInternalInstalledRangeReceipt { None }

@When[os == "macOS" || os == "Windows"]
func internalRendererActivateInstalledRange(session: UInt64, nonce: UInt64,
    proxy: UInt64, selectionRevision: UInt64): Int32 {
    unsafe { cjgui_internal_renderer_installed_range_activate(session, nonce, proxy, selectionRevision) }
}
@When[os != "macOS" && os != "Windows"]
func internalRendererActivateInstalledRange(session: UInt64, nonce: UInt64,
    proxy: UInt64, selectionRevision: UInt64): Int32 { CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED }

@When[os == "macOS" || os == "Windows"]
func internalRendererCancelInstalledRange(session: UInt64, nonce: UInt64): Unit {
    let _ = unsafe { cjgui_internal_renderer_installed_range_cancel(session, nonce) }
}
@When[os != "macOS" && os != "Windows"]
func internalRendererCancelInstalledRange(session: UInt64, nonce: UInt64): Unit {}

@When[os == "macOS"]
func internalRendererArmSourceHandoff(session: UInt64, basis: CjguiInstalledRangeBasis,
    scene: UInt64, node: UInt64, resource: Int64,
    expectedBinding: UInt64, expectedNode: UInt64, expectedResource: Int64,
    expectedKind: UInt32): Int32 {
    var candidate = CjguiInternalInstalledRangeCandidate()
    candidate.nonce = basis.nonce; candidate.windowInstanceToken = basis.document
    candidate.bindingEpoch = basis.binding; candidate.contextEpoch = UInt64(basis.context)
    candidate.mirrorRevision = UInt64(basis.mirror); candidate.ownerVersion = basis.ownerVersion
    candidate.installedSceneVersion = scene; candidate.nodeId = node; candidate.resourceId = resource
    candidate.sourceStartByte = UInt64(basis.sourceStart); candidate.sourceEndByte = UInt64(basis.sourceEnd)
    let bytes = basis.text.toArray()
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        let data = acquireArrayRawData(bytes)
        candidate.sourceTextUtf8 = data.pointer; candidate.sourceTextUtf8Length = UInt32(bytes.size)
        status = cjgui_internal_renderer_source_handoff_arm(session, inout candidate,
            expectedBinding, expectedNode, expectedResource, expectedKind)
        releaseArrayRawData(data)
    }
    return status
}
@When[os != "macOS"]
func internalRendererArmSourceHandoff(session: UInt64, basis: CjguiInstalledRangeBasis,
    scene: UInt64, node: UInt64, resource: Int64,
    expectedBinding: UInt64, expectedNode: UInt64, expectedResource: Int64,
    expectedKind: UInt32): Int32 { CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED }

@When[os == "macOS"]
func internalRendererConfirmSourceHandoffSelection(session: UInt64, nonce: UInt64,
    selectionStart16: UInt32, selectionEnd16: UInt32): Int32 {
    unsafe { cjgui_internal_renderer_source_handoff_confirm_selection(session, nonce,
        selectionStart16, selectionEnd16) }
}
@When[os != "macOS"]
func internalRendererConfirmSourceHandoffSelection(session: UInt64, nonce: UInt64,
    selectionStart16: UInt32, selectionEnd16: UInt32): Int32 { CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED }

@When[os == "macOS"]
func internalRendererActivateSourceHandoff(session: UInt64, nonce: UInt64,
    proxy: UInt64, selectionRevision: UInt64): Int32 {
    unsafe { cjgui_internal_renderer_source_handoff_activate(session, nonce, proxy, selectionRevision) }
}
@When[os != "macOS"]
func internalRendererActivateSourceHandoff(session: UInt64, nonce: UInt64,
    proxy: UInt64, selectionRevision: UInt64): Int32 { CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED }

@When[os == "macOS"]
func internalRendererFinishSourceHandoff(session: UInt64, nonce: UInt64): Int32 {
    unsafe { cjgui_internal_renderer_source_handoff_finish(session, nonce) }
}
@When[os != "macOS"]
func internalRendererFinishSourceHandoff(session: UInt64, nonce: UInt64): Int32 { CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED }

@When[os == "macOS"]
func internalRendererCancelSourceHandoff(session: UInt64, nonce: UInt64): Int32 {
    unsafe { cjgui_internal_renderer_source_handoff_cancel(session, nonce) }
}
@When[os != "macOS"]
func internalRendererCancelSourceHandoff(session: UInt64, nonce: UInt64): Int32 { CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED }

@When[os == "macOS" || os == "Windows"]
func internalRendererReleaseInstalledRange(session: UInt64, document: UInt64, binding: UInt64): Unit {
    let _ = unsafe { cjgui_internal_renderer_release_installed_range(session, document, binding) }
}
@When[os != "macOS" && os != "Windows"]
func internalRendererReleaseInstalledRange(session: UInt64, document: UInt64, binding: UInt64): Unit {}

@When[os == "macOS" || os == "Windows"]
func internalRendererAckInstalledRange(session: UInt64, claim: InternalRendererInstalledRangeClaim,
    accepted: Bool, version: Int64): Int32 {
    var raw = claim.raw
    unsafe { cjgui_internal_renderer_ack_installed_range(session, inout raw,
        if (accepted) { 1u32 } else { 0u32 }, version) }
}
@When[os != "macOS" && os != "Windows"]
func internalRendererAckInstalledRange(session: UInt64, claim: InternalRendererInstalledRangeClaim,
    accepted: Bool, version: Int64): Int32 { CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED }

@When[os == "macOS" || os == "Windows"]
func internalRendererClaimInstalledRange(session: UInt64, node: UInt64, resource: Int64,
    binding: UInt64, scene: UInt64): (Bool, ?InternalRendererInstalledRangeClaim) {
    var raw = CjguiInternalInstalledRangeIntent()
    let status = unsafe { cjgui_internal_renderer_claim_last_pumped_range(session, node, resource,
        binding, scene, inout raw) }
    if (status == CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND) { return (false, None) }
    // Non-OK owned claims have already been retired by the native claim gate.
    if (status != CJGUI_INTERNAL_RENDERER_OK) { return (true, None) }
    let payloadBytes = Int64(raw.preBodyUtf8Length) + Int64(raw.replacementUtf8Length) +
        Int64(raw.postBodyUtf8Length)
    if (payloadBytes > CJGUI_INSTALLED_RANGE_PAYLOAD_BUDGET / CJGUI_INSTALLED_RANGE_PAYLOAD_COPIES) {
        // The materialized source window may grow after an edit. Enforce the
        // already-reserved payload/copy budget instead of rejecting a one-byte
        // insertion into a full 64 KiB window. Settle any invalid reservation.
        let _ = unsafe { cjgui_internal_renderer_ack_installed_range(session, inout raw, 0u32, -1) }
        return (true, None)
    }
    let pre = Array<UInt8>(Int64(raw.preBodyUtf8Length), repeat: 0)
    let replacement = Array<UInt8>(Int64(raw.replacementUtf8Length), repeat: 0)
    let post = Array<UInt8>(Int64(raw.postBodyUtf8Length), repeat: 0)
    var copied: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        let preData = acquireArrayRawData(pre)
        let replacementData = acquireArrayRawData(replacement)
        let postData = acquireArrayRawData(post)
        copied = cjgui_internal_renderer_copy_claimed_range_bytes(session, raw.seq,
            preData.pointer, raw.preBodyUtf8Length, replacementData.pointer, raw.replacementUtf8Length,
            postData.pointer, raw.postBodyUtf8Length)
        releaseArrayRawData(postData); releaseArrayRawData(replacementData); releaseArrayRawData(preData)
    }
    if (copied != CJGUI_INTERNAL_RENDERER_OK) {
        let _ = unsafe { cjgui_internal_renderer_ack_installed_range(session, inout raw, 0u32, -1) }
        return (true, None)
    }
    let basis = CjguiInstalledRangeBasis(raw.nonce, raw.windowInstanceToken, raw.bindingEpoch,
        Int64(raw.contextEpoch), Int64(raw.mirrorRevision), raw.ownerVersion,
        Int64(raw.sourceStartByte), Int64(raw.sourceEndByte), "")
    let input = CjguiInstalledRangeInput(basis, raw.proxyGeneration, raw.seq, raw.previousSeq,
        raw.observedAckSeq, raw.observedAckVersion, String.fromUtf8(pre),
        Int64(raw.rangeStart16), Int64(raw.rangeStart16) + Int64(raw.rangeLength16),
        wholeChoiceNonce: raw.wholeChoiceNonce, wholeChoicePrevious: raw.wholeChoicePreviousSeq)
    return (true, Some(InternalRendererInstalledRangeClaim(raw, input, String.fromUtf8(replacement), String.fromUtf8(post))))
}
@When[os != "macOS" && os != "Windows"]
func internalRendererClaimInstalledRange(session: UInt64, node: UInt64, resource: Int64,
    binding: UInt64, scene: UInt64): (Bool, ?InternalRendererInstalledRangeClaim) { (false, None) }

func internalRendererConfigureComposableScene(session: UInt64, projectionVersion: UInt64, nodeCount: UInt32): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_configure_composable_scene(session, projectionVersion, nodeCount) }
    return status
}

@When[os == "macOS"]
foreign {
    func cjgui_internal_renderer_prepare_frame_resources(session: UInt64, request: UInt64,
        deadlineNs: UInt64, outReady: CPointer<UInt32>): Int32
}
@When[os == "macOS"]
func internalRendererPrepareFrameResources(session: UInt64, request: UInt64,
    deadlineNs: UInt64): (Int32, Bool) {
    var ready = 0u32
    let status = unsafe { cjgui_internal_renderer_prepare_frame_resources(session, request, deadlineNs, inout ready) }
    return (status, ready == 1u32)
}
@When[os != "macOS"]
func internalRendererPrepareFrameResources(session: UInt64, request: UInt64,
    deadlineNs: UInt64): (Int32, Bool) { (CJGUI_INTERNAL_RENDERER_OK, true) }

// Package-private owned scratch bridge; no native object escapes this module.
func internalRendererBeginComposablePreparation(session: UInt64, preparationId: UInt64,
    baseSceneVersion: UInt64, projectionVersion: UInt64, nodeCount: UInt32): Int32 {
    return unsafe { cjgui_internal_renderer_begin_composable_preparation(session, preparationId,
        baseSceneVersion, projectionVersion, nodeCount) }
}
func internalRendererAdvanceComposablePreparation(session: UInt64, preparationId: UInt64,
    deadlineNs: UInt64): (Int32, Bool) {
    var ready: UInt32 = 0u32
    let status = unsafe { cjgui_internal_renderer_advance_composable_preparation(
        session, preparationId, deadlineNs, inout ready) }
    return (status, ready == 1u32)
}
func internalRendererPromoteComposablePreparation(session: UInt64, preparationId: UInt64): Int32 {
    return unsafe { cjgui_internal_renderer_promote_composable_preparation(session, preparationId) }
}
func internalRendererCancelComposablePreparation(session: UInt64, preparationId: UInt64): Int32 {
    return unsafe { cjgui_internal_renderer_cancel_composable_preparation(session, preparationId) }
}
func internalRendererPrepareComposableNode(session: UInt64, preparationId: UInt64, nodeIndex: UInt32,
    node: CjguiInternalRendererComposableNode, geometry: CjguiInternalRendererComposableGeometry,
    label: String, value: String, semanticId: String, semanticBindingKey: String, semanticRowKey: String,
    semanticParentRowKey: String, semanticLabel: String, encodedRuns: String): Int32 {
    var mutableNode = node
    var mutableGeometry = geometry
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    let preparedCString0 = unsafe { LibC.mallocCString(label) }
    let preparedCString1 = unsafe { LibC.mallocCString(value) }
    let preparedCString2 = unsafe { LibC.mallocCString(semanticId) }
    let preparedCString3 = unsafe { LibC.mallocCString(semanticBindingKey) }
    let preparedCString4 = unsafe { LibC.mallocCString(semanticRowKey) }
    let preparedCString5 = unsafe { LibC.mallocCString(semanticParentRowKey) }
    let preparedCString6 = unsafe { LibC.mallocCString(semanticLabel) }
    let preparedCString7 = unsafe { LibC.mallocCString(encodedRuns) }
    try (preparedStringResource0 = preparedCString0.asResource()) {
        try (preparedStringResource1 = preparedCString1.asResource()) {
            try (preparedStringResource2 = preparedCString2.asResource()) {
                try (preparedStringResource3 = preparedCString3.asResource()) {
                    try (preparedStringResource4 = preparedCString4.asResource()) {
                        try (preparedStringResource5 = preparedCString5.asResource()) {
                            try (preparedStringResource6 = preparedCString6.asResource()) {
                                try (preparedStringResource7 = preparedCString7.asResource()) {
                                    unsafe { status = cjgui_internal_renderer_prepare_composable_node(session, preparationId, nodeIndex,
                                        inout mutableNode, inout mutableGeometry, preparedStringResource0.value, preparedStringResource1.value, preparedStringResource2.value, preparedStringResource3.value,
                                        preparedStringResource4.value, preparedStringResource5.value, preparedStringResource6.value, preparedStringResource7.value) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return status
}

@When[os == "macOS"]
func internalRendererPrepareComposableNodeBatch(session: UInt64, preparationId: UInt64, firstIndex: UInt32,
    nodes: Array<CjguiInternalRendererComposableNode>, geometry: Array<CjguiInternalRendererComposableGeometry>,
    strings: Array<String>, deadlineNs: UInt64): (Int32, UInt32) {
    if (nodes.size <= 0 || nodes.size > 8 || geometry.size != nodes.size || strings.size != nodes.size * 8) {
        return (CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR, 0u32)
    }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    var copied: UInt32 = 0
    let nativeNodes = unsafe { LibC.malloc<CjguiInternalRendererComposableNode>(count: nodes.size) }
    try (nodeMemory = nativeNodes.asResource()) {
    let nativeGeometry = unsafe { LibC.malloc<CjguiInternalRendererComposableGeometry>(count: nodes.size) }
    try (geometryMemory = nativeGeometry.asResource()) {
    let nativeStrings = unsafe { LibC.malloc<CString>(count: strings.size) }
    try (stringMemory = nativeStrings.asResource()) {
    var filledStrings: Int64 = 0
    try {
        for (i in 0..nodes.size) {
            unsafe { nativeNodes.write(i, nodes[i]); nativeGeometry.write(i, geometry[i]) }
        }
        for (text in strings) {
            let value = unsafe { LibC.mallocCString(text) }
            unsafe { nativeStrings.write(filledStrings, value) }
            filledStrings += 1
        }
        status = unsafe { cjgui_internal_renderer_prepare_composable_node_batch(session, preparationId,
            firstIndex, UInt32(nodes.size), nativeNodes, nativeGeometry, nativeStrings, deadlineNs, inout copied) }
    } finally {
        for (i in 0..filledStrings) { unsafe { LibC.free(nativeStrings.read(i)) } }
    }
    }
    }
    }
    return (status, copied)
}

@When[os != "macOS"]
func internalRendererPrepareComposableNodeBatch(session: UInt64, preparationId: UInt64, firstIndex: UInt32,
    nodes: Array<CjguiInternalRendererComposableNode>, geometry: Array<CjguiInternalRendererComposableGeometry>,
    strings: Array<String>, deadlineNs: UInt64): (Int32, UInt32) {
    // No OHOS bridge or snapshot change. Its existing scalar call remains the
    // implementation if this main-tree helper is compiled on another platform.
    if (nodes.size <= 0 || nodes.size > 8 || geometry.size != nodes.size || strings.size != nodes.size * 8) {
        return (CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR, 0u32)
    }
    var copied: UInt32 = 0
    for (i in 0..nodes.size) {
        let s = i * 8
        let status = internalRendererPrepareComposableNode(session, preparationId, firstIndex + UInt32(i),
            nodes[i], geometry[i], strings[s], strings[s + 1], strings[s + 2], strings[s + 3], strings[s + 4],
            strings[s + 5], strings[s + 6], strings[s + 7])
        if (status != CJGUI_INTERNAL_RENDERER_OK) { return (status, copied) }
        copied += 1u32
    }
    return (CJGUI_INTERNAL_RENDERER_OK, copied)
}

func internalRendererSetComposableSceneGeometry(session: UInt64, projectionVersion: UInt64,
    nodeIndex: UInt32, geometry: CjguiInternalRendererComposableGeometry): Int32 {
    var mutableGeometry = geometry
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        status = cjgui_internal_renderer_set_composable_scene_geometry(session, projectionVersion,
            nodeIndex, inout mutableGeometry)
    }
    return status
}

func internalRendererDiscardComposableSceneCandidate(session: UInt64): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_discard_composable_scene_candidate(session) }
    return status
}

func internalRendererConfigureComposableCommandMenu(session: UInt64, projectionVersion: UInt64, itemCount: UInt32): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_configure_composable_command_menu(session, projectionVersion, itemCount) }
    return status
}

func internalRendererSetComposableCommandMenuItem(
    session: UInt64,
    itemIndex: UInt32,
    commandId: String,
    title: String,
    menuGroup: String,
    shortcut: String,
    menuSection: UInt32,
    focusScope: UInt64,
    enabled: Bool,
    checked: Bool
): Int32 {
    let cCommandId = unsafe { LibC.mallocCString(commandId) }
    let cTitle = unsafe { LibC.mallocCString(title) }
    let cMenuGroup = unsafe { LibC.mallocCString(menuGroup) }
    let cShortcut = unsafe { LibC.mallocCString(shortcut) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (commandIdResource = cCommandId.asResource()) {
        try (titleResource = cTitle.asResource()) {
            try (menuGroupResource = cMenuGroup.asResource()) {
                try (shortcutResource = cShortcut.asResource()) {
                    unsafe {
                        status = cjgui_internal_renderer_set_composable_command_menu_item(
                            session,
                            itemIndex,
                            commandIdResource.value,
                            titleResource.value,
                            menuGroupResource.value,
                            shortcutResource.value,
                            menuSection,
                            focusScope,
                            if (enabled) {
                                1u8
                            } else {
                                0u8
                            },
                            if (checked) {
                                1u8
                            } else {
                                0u8
                            }
                        )
                    }
                }
            }
        }
    }
    return status
}

func internalRendererCommitComposableCommandMenu(session: UInt64): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_commit_composable_command_menu(session) }
    return status
}

func internalRendererSetComposableSceneNode(
    session: UInt64,
    nodeIndex: UInt32,
    node: CjguiInternalRendererComposableNode,
    label: String,
    value: String,
    semanticId: String,
    imageResourcePath: String,
    imageResourceId: String,
    imageResourceVersion: Int64,
    imageTransferOffer!: ?CjguiSharedOperationTransferOffer = None
): Int32 {
    var mutableNode = node
    let cLabel = unsafe { LibC.mallocCString(label) }
    let cValue = unsafe { LibC.mallocCString(value) }
    let cSemanticId = unsafe { LibC.mallocCString(semanticId) }
    let cImageResourcePath = unsafe { LibC.mallocCString(imageResourcePath) }
    let cImageResourceId = unsafe { LibC.mallocCString(imageResourceId) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (labelResource = cLabel.asResource()) {
        try (valueResource = cValue.asResource()) {
            try (semanticIdResource = cSemanticId.asResource()) {
                try (imageResource = cImageResourcePath.asResource()) {
                    try (imageResourceIdResource = cImageResourceId.asResource()) {
                        let boundedVersion = if (imageResourceVersion < 0) {
                            0u64
                        } else {
                            UInt64(imageResourceVersion)
                        }
                        if (let Some(offer) <- imageTransferOffer) {
                            let bytes = offer.binaryBytes()
                            if (bytes.size <= 0 || bytes.size > 512 * 1024) {
                                status = CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED
                            } else {
                                unsafe {
                                    let handle = acquireArrayRawData(bytes)
                                    status = cjgui_internal_renderer_set_composable_scene_node_bytes(
                                        session, nodeIndex, inout mutableNode, labelResource.value,
                                        valueResource.value, imageResource.value, imageResourceIdResource.value,
                                        boundedVersion, handle.pointer, UInt32(bytes.size))
                                    releaseArrayRawData(handle)
                                }
                            }
                        } else {
                            unsafe {
                                status = cjgui_internal_renderer_set_composable_scene_node(
                                    session, nodeIndex, inout mutableNode, labelResource.value,
                                    valueResource.value, imageResource.value, imageResourceIdResource.value,
                                    boundedVersion)
                            }
                        }
                        unsafe {
                            // The accepted semantic identity is staged only with the
                            // node it addresses; a later AX read then has the exact
                            // instance address instead of a caption guess.
                            if (status == CJGUI_INTERNAL_RENDERER_OK) {
                                status = cjgui_internal_renderer_set_composable_node_semantic_identity(
                                    session,
                                    nodeIndex,
                                    semanticIdResource.value
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    return status
}

struct InternalRendererPreparedPng {
    let status: Int32
    let width: UInt32
    let height: UInt32
    let decodeMicros: UInt64
    init(status: Int32, width: UInt32, height: UInt32, decodeMicros: UInt64) {
        this.status = status
        this.width = width
        this.height = height
        this.decodeMicros = decodeMicros
    }
}

func internalRendererPreparePngTransfer(session: UInt64,
    offer: CjguiSharedOperationTransferOffer): InternalRendererPreparedPng {
    let bytes = offer.binaryBytes()
    if (bytes.size <= 0 || bytes.size > 512 * 1024) {
        return InternalRendererPreparedPng(CJGUI_INTERNAL_RENDERER_PNG_INVALID, 0u32, 0u32, 0u64)
    }
    let identity = cjguiComposableTransferImageResourceIdentity(offer)
    let cIdentity = unsafe { LibC.mallocCString(identity) }
    var width: UInt32 = 0u32
    var height: UInt32 = 0u32
    var micros: UInt64 = 0u64
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (identityResource = cIdentity.asResource()) {
        unsafe {
            let handle = acquireArrayRawData(bytes)
            status = cjgui_internal_renderer_prepare_composable_png_transfer(
                session, identityResource.value, handle.pointer, UInt32(bytes.size),
                inout width, inout height, inout micros)
            releaseArrayRawData(handle)
        }
    }
    return InternalRendererPreparedPng(status, width, height, micros)
}

func internalRendererFinishPngTransfer(session: UInt64,
    offer: CjguiSharedOperationTransferOffer, accepted: Bool): Int32 {
    let identity = cjguiComposableTransferImageResourceIdentity(offer)
    let cIdentity = unsafe { LibC.mallocCString(identity) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (identityResource = cIdentity.asResource()) {
        status = unsafe { cjgui_internal_renderer_finish_composable_png_transfer(
            session, identityResource.value, if (accepted) { 1u8 } else { 0u8 }) }
    }
    return status
}

func internalRendererSetComposableSemanticMetadata(session: UInt64, nodeIndex: UInt32,
    bindingKey: String, rowKey: String, parentRowKey: String, semanticLabel: String): Int32 {
    let cBinding = unsafe { LibC.mallocCString(bindingKey) }
    let cRow = unsafe { LibC.mallocCString(rowKey) }
    let cParent = unsafe { LibC.mallocCString(parentRowKey) }
    let cLabel = unsafe { LibC.mallocCString(semanticLabel) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (bindingResource = cBinding.asResource()) {
        try (rowResource = cRow.asResource()) {
            try (parentResource = cParent.asResource()) {
                try (labelResource = cLabel.asResource()) {
                    unsafe {
                        status = cjgui_internal_renderer_set_composable_node_semantic_metadata(session, nodeIndex,
                            bindingResource.value, rowResource.value, parentResource.value, labelResource.value)
                    }
                }
            }
        }
    }
    return status
}

func internalRendererConfigureComposableDataTransfer(
    session: UInt64,
    projectionVersion: UInt64,
    itemCount: UInt32
): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        status = cjgui_internal_renderer_configure_composable_data_transfer(session, projectionVersion, itemCount)
    }
    return status
}

func internalRendererSetComposableDataTransferItem(
    session: UInt64,
    itemIndex: UInt32,
    item: CjguiInternalRendererComposableDataTransferItem,
    format: String,
    payload: String,
    sourceKind: String,
    sourceIdentity: String
): Int32 {
    var mutableItem = item
    let cFormat = unsafe { LibC.mallocCString(format) }
    let cPayload = unsafe { LibC.mallocCString(payload) }
    let cSourceKind = unsafe { LibC.mallocCString(sourceKind) }
    let cSourceIdentity = unsafe { LibC.mallocCString(sourceIdentity) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (formatResource = cFormat.asResource()) {
        try (payloadResource = cPayload.asResource()) {
            try (sourceKindResource = cSourceKind.asResource()) {
                try (sourceIdentityResource = cSourceIdentity.asResource()) {
                    unsafe {
                        status = cjgui_internal_renderer_set_composable_data_transfer_item(session, itemIndex,
                            inout mutableItem, formatResource.value, payloadResource.value, sourceKindResource.value,
                            sourceIdentityResource.value)
                    }
                }
            }
        }
    }
    return status
}

func internalRendererSetComposableDataTransferItemBytes(session: UInt64, itemIndex: UInt32,
    bytes: Array<Byte>): Int32 {
    if (bytes.size <= 0 || bytes.size > 512 * 1024) { return CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        let handle = acquireArrayRawData(bytes)
        status = cjgui_internal_renderer_set_composable_data_transfer_item_bytes(
            session, itemIndex, handle.pointer, UInt32(bytes.size))
        releaseArrayRawData(handle)
    }
    return status
}

func internalRendererPresentComposableScene(session: UInt64): InternalRendererFrameResult {
    var observation = CjguiInternalRendererFrameObservation()
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_present_composable_scene(session, inout observation) }
    return InternalRendererFrameResult(status, observation.frameIndex, observation.drawableWidthPixels,
        observation.drawableHeightPixels, observation.contentsScale, observation.readbackAttempted,
        observation.readbackCompleted, observation.readbackColorMatched, ticketId: observation.ticketId)
}

/// A1：查询一张已登记票据的终态。只读，不 configure/build/提交。
func internalRendererQueryPresent(session: UInt64, ticketId: UInt64): InternalRendererPresentReceipt {
    var receipt = CjguiInternalRendererPresentReceipt()
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_query_present(session, ticketId, inout receipt) }
    return InternalRendererPresentReceipt(status, receipt.ticketId, receipt.projectionVersion, receipt.decision,
        receipt.terminalStatus, receipt.observation.frameIndex, receipt.observation.contentsScale,
        receipt.resyncRequired != 0u8, receipt.settled != 0u8)
}

/// A1：确认回执（幂等）。只回收回执并开放下一次提交，不推进帧号。
func internalRendererAcknowledgePresent(session: UInt64, ticketId: UInt64): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_acknowledge_present(session, ticketId) }
    return status
}

// Package-only deterministic pending seam. The normal macOS sidecar returns
// INTERNAL_ERROR; only an explicitly compiled testing sidecar can defer a
// staged native commit and issue a real ticket.
func internalRendererTestHoldNextComposablePresent(session: UInt64): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_test_hold_next_composable_present(session) }
    return status
}

func internalRendererTestResolvePendingComposablePresent(session: UInt64): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_test_resolve_pending_composable_present(session) }
    return status
}

/// A1：票据取证计数（测试/验证用）。查询失败时 available=false，不伪造事实。
func internalRendererPresentTicketStats(session: UInt64): InternalRendererTicketStats {
    var stats = CjguiInternalRendererPresentTicketStats()
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_present_ticket_stats(session, inout stats) }
    if (status != CJGUI_INTERNAL_RENDERER_OK || stats.available == 0u8) {
        return InternalRendererTicketStats(0, 0, 0, 0, 0, 0, 0, 0, false)
    }
    return InternalRendererTicketStats(stats.nextTicketId, stats.unackedTicketId, stats.acceptedCount,
        stats.rejectedCount, stats.queryCount, stats.ackCount, stats.duplicateSettlementCount, stats.destroyRefusedCount,
        true)
}

private func internalRendererComposableImageResource(
    session: UInt64,
    resourcePath: String,
    resourceId: String,
    resourceVersion: Int64,
    prepares: Bool
): InternalRendererImageResourceResult {
    let cPath = unsafe { LibC.mallocCString(resourcePath) }
    let cId = unsafe { LibC.mallocCString(resourceId) }
    var state: UInt32 = 0u32
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    let boundedVersion = if (resourceVersion < 0) {
        0u64
    } else {
        UInt64(resourceVersion)
    }
    try (pathResource = cPath.asResource()) {
        try (idResource = cId.asResource()) {
            unsafe {
                status = if (prepares) {
                    cjgui_internal_renderer_prepare_composable_image_resource(session, pathResource.value,
                        idResource.value, boundedVersion, inout state)
                } else {
                    cjgui_internal_renderer_composable_image_resource_state(session, pathResource.value,
                        idResource.value, boundedVersion, inout state)
                }
            }
        }
    }
    return InternalRendererImageResourceResult(status, state)
}

func internalRendererPrepareComposableImageResource(
    session: UInt64,
    resourcePath: String,
    resourceId: String,
    resourceVersion: Int64
): InternalRendererImageResourceResult {
    return internalRendererComposableImageResource(session, resourcePath, resourceId, resourceVersion, true)
}

func internalRendererComposableImageResourceState(
    session: UInt64,
    resourcePath: String,
    resourceId: String,
    resourceVersion: Int64
): InternalRendererImageResourceResult {
    return internalRendererComposableImageResource(session, resourcePath, resourceId, resourceVersion, false)
}

func internalRendererComposableViewport(session: UInt64): InternalRendererViewportResult {
    var viewport = CjguiInternalRendererViewport()
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_composable_viewport(session, inout viewport) }
    return InternalRendererViewportResult(status, viewport.width, viewport.height, viewport.resizeVersion,
        viewport.resourceCompletionVersion)
}

// Ordinary copied result, not an ABI/POD or a retained native object.
struct InternalRendererDiagnosticScalarSnapshotResult {
    let status: Int32
    let progress: CjguiInternalRendererComposableDisplayProgress
    let workload: CjguiInternalRendererDiagnosticWorkload
    let timing: CjguiInternalRendererDiagnosticTiming
    init(status: Int32, progress: CjguiInternalRendererComposableDisplayProgress,
        workload: CjguiInternalRendererDiagnosticWorkload, timing: CjguiInternalRendererDiagnosticTiming) {
        this.status = status
        this.progress = progress
        this.workload = workload
        this.timing = timing
    }
}

@When[os == "macOS"]
func internalRendererDiagnosticScalarSnapshot(session: UInt64, sceneVersion: UInt64):
    InternalRendererDiagnosticScalarSnapshotResult {
    let (generation, _) = internalRendererCoordinateLifetime(session)
    var progress = CjguiInternalRendererComposableDisplayProgress()
    var workload = CjguiInternalRendererDiagnosticWorkload()
    var timing = CjguiInternalRendererDiagnosticTiming()
    let status = unsafe { cjgui_internal_renderer_diagnostic_scalar_snapshot(session,
        generation, sceneVersion, inout progress, inout workload, inout timing) }
    return InternalRendererDiagnosticScalarSnapshotResult(status, progress, workload, timing)
}

@When[os != "macOS"]
func internalRendererDiagnosticScalarSnapshot(session: UInt64, sceneVersion: UInt64):
    InternalRendererDiagnosticScalarSnapshotResult {
    return InternalRendererDiagnosticScalarSnapshotResult(CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR,
        CjguiInternalRendererComposableDisplayProgress(), CjguiInternalRendererDiagnosticWorkload(),
        CjguiInternalRendererDiagnosticTiming())
}

/// Reads already-observed renderer facts only. It must never schedule a frame
/// or touch the native input FIFO, so an external GET can safely call it.
func internalRendererComposableDisplayProgress(session: UInt64): InternalRendererComposableDisplayProgressResult {
    var progress = CjguiInternalRendererComposableDisplayProgress()
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_composable_display_progress(session, inout progress) }
    cjguiOwnerTraceBoundary(session, 0u64, 142u32, 0u32, 75u32, 0u64, UInt64.Max)
    return InternalRendererComposableDisplayProgressResult(
        status,
        progress.submittedFrameIndex,
        progress.observedMetalCompletionFrameIndex,
        progress.observedMetalFailureFrameIndex,
        progress.observedMetalGpuDurationMicros,
        progress.overlayDrawnProjectionVersion,
        progress.effectSubmittedSceneVersion,
        progress.effectSubmittedFrameIndex,
        progress.effectRequestedRadiusPoints,
        progress.effectMode,
        progress.effectFallbackReason,
        progress.effectCompletion,
        progress
    )
}

/// Observe the last complete main-thread publication for this exact accepted
/// scene. This is not an input/restore ACK or a fresh native-state barrier.
/// A missing/stale publication remains unavailable; do not queue a main hop
/// merely to turn an observation into a value.
@When[os == "macOS"]
func internalRendererPublishedComposableDisplayProgress(session: UInt64, sceneVersion: UInt64):
    InternalRendererComposableDisplayProgressResult {
    let copied = internalRendererDiagnosticScalarSnapshot(session, sceneVersion)
    let progress = copied.progress
    return InternalRendererComposableDisplayProgressResult(
        copied.status,
        progress.submittedFrameIndex,
        progress.observedMetalCompletionFrameIndex,
        progress.observedMetalFailureFrameIndex,
        progress.observedMetalGpuDurationMicros,
        progress.overlayDrawnProjectionVersion,
        progress.effectSubmittedSceneVersion,
        progress.effectSubmittedFrameIndex,
        progress.effectRequestedRadiusPoints,
        progress.effectMode,
        progress.effectFallbackReason,
        progress.effectCompletion,
        progress
    )
}

@When[os != "macOS"]
func internalRendererPublishedComposableDisplayProgress(session: UInt64, sceneVersion: UInt64):
    InternalRendererComposableDisplayProgressResult {
    return internalRendererComposableDisplayProgress(session)
}

func internalRendererFocusComposableNode(session: UInt64, nodeId: Int64): Int32 {
    if (nodeId < 0) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_focus_composable_node(session, UInt64(nodeId)) }
    return status
}

// The positions and the returned range are UTF-16 code units. The native side
// validates the accepted scene, exact owner value and active input responder.
func internalRendererRestoreComposableSelection(session: UInt64, nodeId: Int64, resourceId: Int64, nodeKind: Int64,
    sceneVersion: Int64, value: String, start: Int64, end: Int64): (Int32, Int64, Int64) {
    if (nodeId < 0 || nodeKind < 0 || sceneVersion < 0 || start < 0 || end < start || end > 4294967295) {
        return (CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR, 0, 0)
    }
    let cValue = unsafe { LibC.mallocCString(value) }
    var appliedStart: UInt32 = 0
    var appliedEnd: UInt32 = 0
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (valueResource = cValue.asResource()) {
        unsafe {
            status = cjgui_internal_renderer_restore_composable_selection(session, UInt64(nodeId), resourceId,
                UInt32(nodeKind), UInt64(sceneVersion), valueResource.value, UInt32(start), UInt32(end),
                inout appliedStart, inout appliedEnd)
        }
    }
    return (status, Int64(appliedStart), Int64(appliedEnd))
}

func internalRendererInstallOwnedSourceSelection(session: UInt64, nodeId: Int64, resourceId: Int64,
    sceneVersion: Int64, bindingEpoch: UInt64, requestId: Int64, deadlineNs: UInt64,
    value: String, start: Int64, end: Int64): (Int32, Int64, Int64, Bool) {
    if (nodeId < 0 || sceneVersion < 0 || requestId <= 0 || start < 0 || end < start ||
        end > 4294967295 || value.size > 65536) {
        return (CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR, 0, 0, false)
    }
    let cValue = unsafe { LibC.mallocCString(value) }
    var appliedStart: UInt32 = 0
    var appliedEnd: UInt32 = 0
    var deferred: UInt8 = 0
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (valueResource = cValue.asResource()) {
        unsafe {
            status = cjgui_internal_renderer_install_owned_source_selection(session, UInt64(nodeId), resourceId,
                UInt64(sceneVersion), bindingEpoch, UInt64(requestId), deadlineNs, valueResource.value,
                UInt32(start), UInt32(end), inout appliedStart, inout appliedEnd, inout deferred)
        }
    }
    return (status, Int64(appliedStart), Int64(appliedEnd), deferred != 0u8)
}

func internalRendererReadComposableSelection(session: UInt64, nodeId: Int64, resourceId: Int64, nodeKind: Int64,
    sceneVersion: Int64, value: String): (Int32, Int64, Int64) {
    if (nodeId < 0 || nodeKind < 0 || sceneVersion < 0) {
        return (CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR, 0, 0)
    }
    let cValue = unsafe { LibC.mallocCString(value) }
    var currentStart: UInt32 = 0
    var currentEnd: UInt32 = 0
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (valueResource = cValue.asResource()) {
        unsafe {
            status = cjgui_internal_renderer_read_composable_selection(session, UInt64(nodeId), resourceId,
                UInt32(nodeKind), UInt64(sceneVersion), valueResource.value,
                inout currentStart, inout currentEnd)
        }
    }
    return (status, Int64(currentStart), Int64(currentEnd))
}

// Reanchor keeps the live platform composition while the owner projection
// advances. `newBaseText` is the new proxy base the owner projection maps to;
// the active preedit is re-installed at `[replacementStart16, +replacementLength16)`
// of that base. `replacementStart16 == -1` asks native to infer that range from
// the proxy (accepted only while the old head and tail survive verbatim). The
// returned tuple is (status, mechanism, markedStart16, markedLength16,
// innerStart16, innerEnd16); mechanism 1 means the platform marked run survived
// the storage update, 2 means it had to be re-installed. Any non-zero status
// changed nothing and the caller must cancel instead.
func internalRendererReanchorComposition(session: UInt64, nodeId: Int64, resourceId: Int64, nodeKind: Int64,
    sceneVersion: Int64, newBaseText: String, replacementStart16: Int64,
    replacementLength16: Int64): (Int32, Int64, Int64, Int64, Int64, Int64) {
    if (nodeId < 0 || nodeKind < 0 || sceneVersion < 0 || replacementStart16 < -1 ||
        replacementLength16 < 0 || (replacementStart16 > 0 && replacementStart16 + replacementLength16 > 4294967295)) {
        return (CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR, 0, 0, 0, 0, 0)
    }
    let cValue = unsafe { LibC.mallocCString(newBaseText) }
    var mechanism: UInt32 = 0
    var markedStart: UInt32 = 0
    var markedLength: UInt32 = 0
    var innerStart: UInt32 = 0
    var innerEnd: UInt32 = 0
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    let nativeStart = if (replacementStart16 < 0) { UInt32(4294967295) } else { UInt32(replacementStart16) }
    try (valueResource = cValue.asResource()) {
        unsafe {
            status = cjgui_internal_renderer_reanchor_composition(session, UInt64(nodeId), resourceId,
                UInt32(nodeKind), UInt64(sceneVersion), valueResource.value, nativeStart,
                UInt32(replacementLength16), inout mechanism, inout markedStart, inout markedLength,
                inout innerStart, inout innerEnd)
        }
    }
    return (status, Int64(mechanism), Int64(markedStart), Int64(markedLength), Int64(innerStart), Int64(innerEnd))
}

// Arm one reanchor request for the next accepted scene of this exact node.
// Native consults it only when the owner value change would otherwise cancel a
// live marked composition, and the install still has to succeed and read back
// at that accept. This call changes no proxy or owner state.
func internalRendererArmCompositionReanchor(session: UInt64, nodeId: Int64, resourceId: Int64, nodeKind: Int64,
    baseText: String, replacementStart16: Int64, replacementLength16: Int64): Int32 {
    if (nodeId < 0 || nodeKind < 0 || replacementStart16 < -2 || replacementLength16 < 0) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    }
    let cValue = unsafe { LibC.mallocCString(baseText) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    let nativeStart = if (replacementStart16 == -1) {
        UInt32(4294967295)
    } else if (replacementStart16 == -2) {
        UInt32(4294967294)
    } else {
        UInt32(replacementStart16)
    }
    try (valueResource = cValue.asResource()) {
        unsafe {
            status = cjgui_internal_renderer_arm_composition_reanchor(session, UInt64(nodeId), resourceId,
                UInt32(nodeKind), valueResource.value, nativeStart, UInt32(replacementLength16))
        }
    }
    return status
}

/// Roll back the hidden text proxy after the application refused a human range
/// edit: restore the value the owner already accepted, under projection
/// suppression, and report the installed grapheme-safe selection. It never
/// creates document truth and fails without changing anything when the target
/// is no longer the active node or the accepted value is stale.
func internalRendererRecoverActiveTextProxy(session: UInt64, nodeId: Int64, resourceId: Int64, nodeKind: Int64,
    acceptedValue: String): (Int32, Int64, Int64) {
    if (nodeId < 0 || nodeKind < 0) {
        return (CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR, 0, 0)
    }
    let cValue = unsafe { LibC.mallocCString(acceptedValue) }
    var appliedStart: UInt32 = 0
    var appliedEnd: UInt32 = 0
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (valueResource = cValue.asResource()) {
        unsafe {
            status = cjgui_internal_renderer_recover_active_text_proxy(session, UInt64(nodeId), resourceId,
                UInt32(nodeKind), valueResource.value, inout appliedStart, inout appliedEnd)
        }
    }
    return (status, Int64(appliedStart), Int64(appliedEnd))
}

func internalRendererCancelComposablePointerCapture(session: UInt64): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_cancel_composable_pointer_capture(session) }
    return status
}

func internalRendererCancelComposablePointerCaptureEpoch(session: UInt64, gestureEpoch: UInt64): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_cancel_composable_pointer_capture_epoch(session, gestureEpoch) }
    return status
}

func internalRendererCancelComposablePointerCaptureGestureKey(session: UInt64,
    appInstance: UInt64, componentInstance: UInt64, surfaceGeneration: UInt64,
    pointerId: Int64, gestureEpoch: UInt64): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_cancel_composable_pointer_capture_gesture_key(
        session, appInstance, componentInstance, surfaceGeneration, pointerId, gestureEpoch) }
    return status
}

/// One bounded entry of the session-local production measurement cache. The
/// cache owns only Cangjie scalar data; native font and string objects remain
/// on the sidecar and are never retained across the ABI.
private class CjguiInternalRendererTextMeasurementCacheEntry {
    let value: String
    let fontSize: Float64
    let fontWeight: Int64
    let fontFamily: String
    let maximumWidth: Int64
    let queryKind: Int64
    let measurement: CjguiComposableUiTextMeasurement
    init(value: String, fontSize: Float64, fontWeight: Int64, fontFamily: String, maximumWidth: Int64, queryKind: Int64,
        measurement: CjguiComposableUiTextMeasurement) {
        this.value = value
        this.fontSize = fontSize
        this.fontWeight = fontWeight
        this.fontFamily = fontFamily
        this.maximumWidth = maximumWidth
        this.queryKind = queryKind
        this.measurement = measurement
    }
    func matches(value: String, style: CjguiComposableUiStyle, maximumWidth: Int64, queryKind: Int64): Bool {
        return this.queryKind == queryKind && this.value == value && this.fontSize == style.fontSize &&
            this.fontWeight == style.fontWeight && this.fontFamily == style.fontFamily && this.maximumWidth ==
            maximumWidth
    }
}

/// Production font measurer. It accepts only the opaque renderer session and
/// returns copied scalar metrics; NSFont/NSString/Metal objects remain owned
/// by the native sidecar. The fallback is used only to complete the current
/// local calculation safely: callers inspect `measurementStatus` and refuse
/// to publish the scene if any real AppKit query failed.
class CjguiInternalRendererTextMeasurer <: CjguiComposableUiTextMeasurer & CjguiComposableUiMultilineNaturalHeightMeasurer & CjguiComposableUiLayoutMeasurementEnvironment {
    private let session: UInt64
    private let fallback: CjguiComposableUiFallbackTextMeasurer
    private var cache: ArrayList<CjguiInternalRendererTextMeasurementCacheEntry>
    private var lastMeasurementStatus: Int32
    private var measurementPassNativeElapsedMsValue: Int64
    private var measurementPassNativeCallCountValue: Int64
    private var measurementPassCacheHitCountValue: Int64 = 0
    private var measurementPassCacheEvictionCountValue: Int64 = 0
    private var measurementEnvironmentResizeVersion: UInt64 = UInt64.Max
    init(session: UInt64) {
        this.session = session
        this.fallback = CjguiComposableUiFallbackTextMeasurer()
        this.cache = ArrayList<CjguiInternalRendererTextMeasurementCacheEntry>()
        this.lastMeasurementStatus = CJGUI_INTERNAL_RENDERER_OK
        this.measurementPassNativeElapsedMsValue = 0
        this.measurementPassNativeCallCountValue = 0
    }
    /// Session identity binds cross-pass geometry to the native font service.
    /// `CjguiComposableUiWindow` drops its per-session cache before any
    /// viewport/backing-scale generation can reuse same-point measurements.
    public func layoutMeasurementEnvironmentKey(): String {
        return "cjgui-native-text-session-${session}-resize-${measurementEnvironmentResizeVersion}-multiline-natural-height-v1"
    }
    // Only the window passes the actual native viewport generation. Point
    // bounds can stay equal while a backing/font environment changes.
    func useMeasurementEnvironment(resizeVersion: UInt64): Unit {
        if (measurementEnvironmentResizeVersion != resizeVersion) {
            cache.clear()
            measurementEnvironmentResizeVersion = resizeVersion
        }
    }
    /// A refresh may make many measurement calls. The cached successful
    /// entries are retained, while failure health applies only to this pass.
    public func beginMeasurementPass(): Unit {
        lastMeasurementStatus = CJGUI_INTERNAL_RENDERER_OK
        measurementPassNativeElapsedMsValue = 0
        measurementPassNativeCallCountValue = 0
        measurementPassCacheHitCountValue = 0
        measurementPassCacheEvictionCountValue = 0
    }
    public func measurementStatus(): Int32 {
        return lastMeasurementStatus
    }
    public func measurementPassNativeElapsedMs(): Int64 {
        return measurementPassNativeElapsedMsValue
    }
    public func measurementPassNativeCallCount(): Int64 {
        return measurementPassNativeCallCountValue
    }
    func measurementPassCacheHitCount(): Int64 { return measurementPassCacheHitCountValue }
    func measurementPassCacheEvictionCount(): Int64 { return measurementPassCacheEvictionCountValue }
    func measurementCacheEntryCount(): Int64 { return cache.size }

    func cachedMeasurement(value: String, style: CjguiComposableUiStyle,
        width: Int64, kind: Int64): ?CjguiComposableUiTextMeasurement {
        var index: Int64 = 0
        while (index < cache.size) {
            let entry = cache[index]
            if (entry.matches(value, style, width, kind)) {
                // A hit is actual reuse of a successful query from this
                // session/font environment. Retain its recent position so a
                // single changing status label cannot evict the whole pass.
                if (index != cache.size - 1) {
                    cache.remove(at: index)
                    cache.add(entry)
                }
                measurementPassCacheHitCountValue += 1
                return Some(entry.measurement)
            }
            index += 1
        }
        return None
    }

    private func retainMeasurement(entry: CjguiInternalRendererTextMeasurementCacheEntry): Unit {
        // Keep the same 128-entry bound; retire only the least recently used
        // successful scalar result. Window environment changes still replace
        // this entire session measurer through the existing invalidation path.
        if (cache.size >= 128) {
            cache.remove(at: 0)
            measurementPassCacheEvictionCountValue += 1
        }
        cache.add(entry)
    }
    func retainPreparedMeasurement(value: String, style: CjguiComposableUiStyle, width: Int64, kind: Int64,
        measured: CjguiComposableUiTextMeasurement, expectedEnvironment: String): Bool {
        if (layoutMeasurementEnvironmentKey() != expectedEnvironment) {
            return false
        }
        // Preparation is pure geometry. Keeping a successful result in the
        // same bounded cache lets a later selection-only scene reuse it.
        if (cachedMeasurement(value, style, width, kind).isNone()) {
            retainMeasurement(
                CjguiInternalRendererTextMeasurementCacheEntry(value, style.fontSize, style.fontWeight, style.fontFamily,
                    width, kind, measured))
        }
        return true
    }
    public func measure(value: String, style: CjguiComposableUiStyle, maximumWidth: Int64): CjguiComposableUiTextMeasurement {
        if (let Some(cached) <- cachedMeasurement(value, style, maximumWidth, 0)) { return cached }
        let cText = unsafe { LibC.mallocCString(value) }
        var native = CjguiInternalRendererTextMeasurement()
        var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        let boundedWidth = if (maximumWidth <= 0) {
            0u32
        } else if (maximumWidth > 4294967295) {
            4294967295u32
        } else {
            UInt32(maximumWidth)
        }
        let nativeStarted = MonoTime.now()
        try (textResource = cText.asResource()) {
            unsafe {
                status = cjgui_internal_renderer_measure_composable_text(
                    session,
                    textResource.value,
                    style.fontSize,
                    if (style.fontWeight <= 0) {
                        0u32
                    } else if (style.fontWeight > 1000) {
                        1000u32
                    } else {
                        UInt32(style.fontWeight)
                    },
                    composableFontFamilyCode(style.fontFamily),
                    boundedWidth,
                    inout native
                )
            }
        }
        measurementPassNativeCallCountValue += 1
        measurementPassNativeElapsedMsValue += (MonoTime.now() - nativeStarted).toMilliseconds()
        if (status != CJGUI_INTERNAL_RENDERER_OK || native.lineHeight == 0u32) {
            if (lastMeasurementStatus == CJGUI_INTERNAL_RENDERER_OK) {
                lastMeasurementStatus = if (status == CJGUI_INTERNAL_RENDERER_OK) {
                    CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
                } else {
                    status
                }
            }
            return fallback.measure(value, style, maximumWidth)
        }
        let result = CjguiComposableUiTextMeasurement(
            Int64(native.width),
            Int64(native.height),
            Int64(native.lineHeight),
            Int64(native.baseline)
        )
        retainMeasurement(
            CjguiInternalRendererTextMeasurementCacheEntry(
                value,
                style.fontSize,
                style.fontWeight,
                style.fontFamily,
                maximumWidth,
                0,
                result
            )
        )
        return result
    }
    public func multilineNaturalContentHeight(value: String, style: CjguiComposableUiStyle, contentWidth: Int64): ?Int64 {
        if (let Some(cached) <- cachedMeasurement(value, style, contentWidth, 1)) { return Some(cached.height) }
        let cText = unsafe { LibC.mallocCString(value) }
        var nativeHeight: UInt32 = 0
        var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        let boundedWidth = if (contentWidth <= 0) {
            1u32
        } else if (contentWidth > 4294967295) {
            4294967295u32
        } else {
            UInt32(contentWidth)
        }
        let nativeStarted = MonoTime.now()
        try (textResource = cText.asResource()) {
            unsafe {
                status = cjgui_internal_renderer_measure_composable_multiline_natural_height(session, textResource.value,
                    style.fontSize, if (style.fontWeight <= 0) {
                        0u32
                    } else if (style.fontWeight > 1000) {
                        1000u32
                    } else {
                        UInt32(style.fontWeight)
                    }, composableFontFamilyCode(style.fontFamily), boundedWidth, inout nativeHeight)
            }
        }
        measurementPassNativeCallCountValue += 1
        measurementPassNativeElapsedMsValue += (MonoTime.now() - nativeStarted).toMilliseconds()
        if (status != CJGUI_INTERNAL_RENDERER_OK || nativeHeight == 0u32) {
            if (lastMeasurementStatus == CJGUI_INTERNAL_RENDERER_OK) {
                lastMeasurementStatus = if (status == CJGUI_INTERNAL_RENDERER_OK) {
                    CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
                } else {
                    status
                }
            }
            return None
        }
        let result = CjguiComposableUiTextMeasurement(0, Int64(nativeHeight), 1, 0)
        retainMeasurement(
            CjguiInternalRendererTextMeasurementCacheEntry(value, style.fontSize, style.fontWeight, style.fontFamily,
                contentWidth, 1, result))
        return Some(Int64(nativeHeight))
    }
}

// These results belong to one frozen static candidate, never to a public
// text owner or native input ticket. A yield is distinct from failed geometry.
class CjguiLayoutMeasurementNeedBudget <: Exception {
    init() { super("layout_measurement_need_budget") }
}

// A private TextKit graph is still measuring an immutable candidate input.
// Capacity has no accepted job and is retried only for a bounded number of
// owner turns; an active job can wait without rebuilding the candidate tree.
class CjguiLayoutMeasurementNeedWorker <: Exception {
    let capacity: Bool
    init(capacity: Bool) {
        super(if (capacity) { "layout_measurement_worker_capacity" } else {
            "layout_measurement_worker_pending"
        })
        this.capacity = capacity
    }
}

class CjguiLayoutPreparationFailure <: Exception {
    init(reason: String) { super(reason) }
}

class CjguiPreparedStaticTextMeasurer <: CjguiComposableUiTextMeasurer & CjguiComposableUiMultilineNaturalHeightMeasurer & CjguiComposableUiLayoutMeasurementEnvironment & CjguiComposableUiLayoutPacer {
    private let base: CjguiInternalRendererTextMeasurer
    private let budget: CjguiOwnerTurnBudget
    private let environment: String
    private let pins = ArrayList<CjguiInternalRendererTextMeasurementCacheEntry>()
    private var keyBytes: Int64 = 0
    private var failure: String = "none"
    private let maximumEntries: Int64
    private let maximumBytes: Int64
    private var pendingMultiline: ?CjguiAsyncMultilineHeightJob = None
    private var pendingTextMetrics: ?CjguiAsyncTextMetricsJob = None
    private var multilineWorkerStartCount: Int64 = 0
    init(base: CjguiInternalRendererTextMeasurer, budget: CjguiOwnerTurnBudget, maximumEntries!: Int64 = 512,
        maximumBytes!: Int64 = 1048576) {
        this.base = base
        this.budget = budget
        this.environment = base.layoutMeasurementEnvironmentKey()
        this.maximumEntries = maximumEntries
        this.maximumBytes = maximumBytes
    }
    public func layoutMeasurementEnvironmentKey(): String {
        return environment
    }
    public func checkpointLayoutSlice(): Unit {
        checkpoint(false)
    }
    func pinCount(): Int64 {
        return pins.size
    }
    func retainedKeyBytes(): Int64 {
        return keyBytes
    }
    func failureReason(): String {
        return failure
    }
    func workerStartCount(): Int64 {
        return multilineWorkerStartCount
    }
    func release(): Unit {
        if (let Some(job) <- pendingMultiline) {
            job.release(false)
        }
        if (let Some(job) <- pendingTextMetrics) {
            job.release(false)
        }
        pendingMultiline = None
        pendingTextMetrics = None
        pins.clear()
        keyBytes = 0
    }
    /// Poll before a new clone/layout pass. A pending worker must not force
    /// repeated owner-side tree traversal, and cancellation releases its job.
    func pollPendingMultiline(): Bool {
        if (let Some(textJob) <- pendingTextMetrics) {
            let (status, measured, _) = textJob.poll()
            if (status == CJGUI_ASYNC_MEASURE_PENDING) {
                return false
            }
            pendingTextMetrics = None
            textJob.release(status == CJGUI_ASYNC_MEASURE_READY)
            if (status != CJGUI_ASYNC_MEASURE_READY || measured.lineHeight <= 0) {
                fail("layout_native_text_worker_failed")
            }
            if (!base.retainPreparedMeasurement(textJob.value, textJob.style, textJob.maximumWidth, 0, measured,
                environment)) {
                fail("layout_measurement_environment_changed")
            }
            let _ = pin(textJob.value, textJob.style, textJob.maximumWidth, 0, measured)
        }
        let job = match (pendingMultiline) {
            case Some(value) => value
            case None => return true
        }
        let (status, height, _) = job.poll()
        if (status == CJGUI_ASYNC_MEASURE_PENDING) {
            return false
        }
        pendingMultiline = None
        job.release(status == CJGUI_ASYNC_MEASURE_READY)
        if (status != CJGUI_ASYNC_MEASURE_READY || height <= 0) {
            fail("layout_native_multiline_worker_failed")
        }
        let measured = CjguiComposableUiTextMeasurement(0, height, 1, 0)
        if (!base.retainPreparedMeasurement(job.value, job.style, job.contentWidth, 1, measured, environment)) {
            fail("layout_measurement_environment_changed")
        }
        let _ = pin(job.value, job.style, job.contentWidth, 1, measured)
        return true
    }
    private func checkpoint(cold: Bool): Unit {
        if (failure != "none") {
            throw CjguiLayoutPreparationFailure(failure)
        }
        if (base.layoutMeasurementEnvironmentKey() != environment) {
            fail("layout_measurement_environment_changed")
        }
        // The native call is indivisible. Reserve includes return/cleanup and
        // other owner work; it is admission, not a worst-case timing claim.
        if (!budget.admits(if (cold) {
            4000
        } else {
            1000
        })) {
            throw CjguiLayoutMeasurementNeedBudget()
        }
    }
    private func fail(reason: String): Nothing {
        failure = reason
        throw CjguiLayoutPreparationFailure(reason)
    }
    private func lookup(value: String, style: CjguiComposableUiStyle, width: Int64, kind: Int64): ?CjguiComposableUiTextMeasurement {
        checkpoint(false)
        for (entry in pins) {
            if (entry.matches(value, style, width, kind)) {
                return Some(entry.measurement)
            }
        }
        return None
    }
    private func pin(value: String, style: CjguiComposableUiStyle, width: Int64, kind: Int64,
        measured: CjguiComposableUiTextMeasurement): CjguiComposableUiTextMeasurement {
        let bytes = value.size + style.fontFamily.size + 64
        if (pins.size >= maximumEntries || bytes > maximumBytes - keyBytes) {
            fail("layout_measurement_pin_capacity")
        }
        // Both old LRU hits and newly successful native results are pinned.
        // No metric is evicted before the candidate completes or is cancelled.
        pins.add(
            CjguiInternalRendererTextMeasurementCacheEntry(value, style.fontSize, style.fontWeight, style.fontFamily,
                width, kind, measured))
        keyBytes += bytes
        return measured
    }
    public func measure(value: String, style: CjguiComposableUiStyle, maximumWidth: Int64): CjguiComposableUiTextMeasurement {
        if (let Some(found) <- lookup(value, style, maximumWidth, 0)) {
            return found
        }
        if (let Some(found) <- base.cachedMeasurement(value, style, maximumWidth, 0)) {
            return pin(value, style, maximumWidth, 0, found)
        }
        // A small UI label retains the existing bounded synchronous route.
        // A long TEXT cold miss is indivisible even when it contains newlines;
        // it must yield before entering NSString drawing on the AppKit thread.
        if (value.size > 1024) {
            if (let Some(job) <- pendingTextMetrics) {
                if (!job.matches(value, style, maximumWidth)) {
                    fail("layout_text_worker_identity_changed")
                }
                throw CjguiLayoutMeasurementNeedWorker(false)
            }
            if (pendingMultiline.isSome()) {
                fail("layout_worker_kind_changed")
            }
            checkpoint(true)
            let (status, started) = beginCjguiAsyncTextMetrics(value, style, maximumWidth)
            if (status == CJGUI_ASYNC_MEASURE_STARTED && started.isSome()) {
                pendingTextMetrics = started
                multilineWorkerStartCount += 1
                throw CjguiLayoutMeasurementNeedWorker(false)
            }
            if (status == CJGUI_ASYNC_MEASURE_DEFERRED_CAPACITY) {
                throw CjguiLayoutMeasurementNeedWorker(true)
            }
            fail("layout_native_text_worker_unavailable")
        }
        // This runs BEFORE CString allocation/conversion/FFI in the real base.
        checkpoint(true)
        let actual = base.measure(value, style, maximumWidth)
        if (base.measurementStatus() != CJGUI_INTERNAL_RENDERER_OK) {
            fail("layout_native_measurement_failed")
        }
        return pin(value, style, maximumWidth, 0, actual)
    }
    public func multilineNaturalContentHeight(value: String, style: CjguiComposableUiStyle, contentWidth: Int64): ?Int64 {
        if (let Some(found) <- lookup(value, style, contentWidth, 1)) {
            return Some(found.height)
        }
        if (let Some(found) <- base.cachedMeasurement(value, style, contentWidth, 1)) {
            return Some(pin(value, style, contentWidth, 1, found).height)
        }
        if (let Some(job) <- pendingMultiline) {
            if (!job.matches(value, style, contentWidth)) {
                fail("layout_multiline_worker_identity_changed")
            }
            throw CjguiLayoutMeasurementNeedWorker(false)
        }
        checkpoint(true)
        let (status, started) = beginCjguiAsyncMultilineHeight(value, style, contentWidth)
        if (status == CJGUI_ASYNC_MEASURE_STARTED && started.isSome()) {
            pendingMultiline = started
            multilineWorkerStartCount += 1
            throw CjguiLayoutMeasurementNeedWorker(false)
        }
        if (status == CJGUI_ASYNC_MEASURE_DEFERRED_CAPACITY) {
            throw CjguiLayoutMeasurementNeedWorker(true)
        }
        fail("layout_native_multiline_worker_unavailable")
    }
}

/// Internal ABI enum only. Style construction already normalizes to this
/// closed set, and the native side applies the same system fallback.
func composableFontFamilyCode(fontFamily: String): UInt32 {
    if (fontFamily == "monospaced") {
        return 1u32
    }
    if (fontFamily == "system-italic") {
        return 2u32
    }
    if (fontFamily == "monospaced-italic") {
        return 3u32
    }
    return 0u32
}

func internalRendererConfigureSharedOperation(
    session: UInt64,
    visibleRecordCount: UInt32
): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        status = cjgui_internal_renderer_configure_shared_operation(session, visibleRecordCount)
    }
    return status
}

func internalRendererSetSharedOperationTitle(
    session: UInt64,
    recordIndex: UInt32,
    title: String
): Int32 {
    let cTitle = unsafe { LibC.mallocCString(title) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (titleResource = cTitle.asResource()) {
        unsafe {
            status = cjgui_internal_renderer_set_shared_operation_title(
                session,
                recordIndex,
                titleResource.value
            )
        }
    }
    return status
}

func internalRendererSetSharedOperationState(
    session: UInt64,
    state: CjguiInternalRendererSharedOperationState
): Int32 {
    var mutableState = state
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        status = cjgui_internal_renderer_set_shared_operation_state(
            session,
            inout mutableState
        )
    }
    return status
}

func internalRendererConfigureSharedForm(session: UInt64, fieldCount: UInt32): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_configure_shared_form(session, fieldCount) }
    return status
}

func internalRendererConfigureSharedCollectionForm(
    session: UInt64,
    fieldCount: UInt32,
    visibleRecordCount: UInt32
): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        status = cjgui_internal_renderer_configure_shared_collection_form(
            session,
            fieldCount,
            visibleRecordCount
        )
    }
    return status
}

func internalRendererSetSharedCollectionRow(
    session: UInt64,
    rowIndex: UInt32,
    title: String,
    isSelected: Bool,
    viewportStart: UInt32,
    totalRecordCount: UInt32
): Int32 {
    let cTitle = unsafe { LibC.mallocCString(title) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (titleResource = cTitle.asResource()) {
        unsafe {
            status = cjgui_internal_renderer_set_shared_collection_row(
                session,
                rowIndex,
                titleResource.value,
                if (isSelected) {
                    1u8
                } else {
                    0u8
                },
                viewportStart,
                totalRecordCount
            )
        }
    }
    return status
}

func internalRendererSetSharedCollectionFilter(session: UInt64, filterText: String): Int32 {
    let cFilter = unsafe { LibC.mallocCString(filterText) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (filterResource = cFilter.asResource()) {
        unsafe { status = cjgui_internal_renderer_set_shared_collection_filter(session, filterResource.value) }
    }
    return status
}

func internalRendererSetSharedFormField(
    session: UInt64,
    fieldIndex: UInt32,
    label: String,
    draftText: String,
    validationError: String,
    editorKind: UInt32,
    isFocused: Bool,
    selectionStart: UInt32,
    selectionEnd: UInt32
): Int32 {
    let cLabel = unsafe { LibC.mallocCString(label) }
    let cDraft = unsafe { LibC.mallocCString(draftText) }
    let cError = unsafe { LibC.mallocCString(validationError) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (labelResource = cLabel.asResource()) {
        try (draftResource = cDraft.asResource()) {
            try (errorResource = cError.asResource()) {
                unsafe {
                    status = cjgui_internal_renderer_set_shared_form_field(
                        session,
                        fieldIndex,
                        labelResource.value,
                        draftResource.value,
                        errorResource.value,
                        editorKind,
                        if (isFocused) {
                            1u8
                        } else {
                            0u8
                        },
                        selectionStart,
                        selectionEnd
                    )
                }
            }
        }
    }
    return status
}

func internalRendererSetSharedFormStatus(session: UInt64, statusText: String): Int32 {
    let cStatus = unsafe { LibC.mallocCString(statusText) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (statusResource = cStatus.asResource()) {
        unsafe { status = cjgui_internal_renderer_set_shared_form_status(session, statusResource.value) }
    }
    return status
}

/// Ask the native renderer to deliver explicit edit deltas for composable text
/// nodes on this session. Returns the native status.
func internalRendererSetComposableRangeEditDelta(session: UInt64, enabled: Bool): Int32 {
    let flag: Int32 = if (enabled) {
        1
    } else {
        0
    }
    return unsafe { cjgui_internal_renderer_set_composable_range_edit_delta(session, flag) }
}

/// 声明(或撤回)窗口拥有的那个文本节点:它的平台组字相位以 kind 52 送达该
/// 会话,对应整值/范围事件被抑制。`bindingEpoch` 原样回传,供窗口拒绝换绑前
/// 入队的旧回调;`enabled` 为 false 时撤回声明。
func internalRendererSetComposableOwnedTextSession(session: UInt64, nodeId: UInt64, resourceId: Int64,
    nodeKind: UInt32, bindingEpoch: UInt64, enabled: Bool): Int32 {
    let flag: Int32 = if (enabled) {
        1
    } else {
        0
    }
    return unsafe {
        cjgui_internal_renderer_set_composable_owned_text_session(session, nodeId, resourceId, nodeKind,
            bindingEpoch, flag)
    }
}

func internalRendererSetComposableContextMenuGuard(session: UInt64, sceneVersion: UInt64, layerScope: UInt64,
    requestId: UInt64, layerNodeId: UInt64, resourceId: Int64, nodeKind: UInt32,
    x: Int64, y: Int64, width: Int64, height: Int64, enabled: Bool): Int32 {
    let flag: UInt32 = if (enabled) { 1u32 } else { 0u32 }
    return unsafe {
        cjgui_internal_renderer_set_composable_context_menu_guard(session, sceneVersion, layerScope,
            requestId, layerNodeId, resourceId, nodeKind, x, y, width, height, flag)
    }
}

func internalRendererFormEventText(session: UInt64): String {
    let borrowed = unsafe { cjgui_internal_renderer_form_event_text(session) }
    return borrowed.toString()
}

func internalRendererDataTransferEventFormat(session: UInt64): String {
    let borrowed = unsafe { cjgui_internal_renderer_data_transfer_event_format(session) }
    return borrowed.toString()
}

func internalRendererDataTransferEventSourceKind(session: UInt64): String {
    let borrowed = unsafe { cjgui_internal_renderer_data_transfer_event_source_kind(session) }
    return borrowed.toString()
}

func internalRendererDataTransferEventSourceIdentity(session: UInt64): String {
    let borrowed = unsafe { cjgui_internal_renderer_data_transfer_event_source_identity(session) }
    return borrowed.toString()
}

func internalRendererDataTransferEventSourceId(session: UInt64): Int64 {
    return unsafe { cjgui_internal_renderer_data_transfer_event_source_id(session) }
}

func internalRendererDataTransferEventExpectedOwnerVersion(session: UInt64): Int64 {
    return unsafe { cjgui_internal_renderer_data_transfer_event_expected_owner_version(session) }
}

func internalRendererDataTransferEventDeliveryOrdinal(session: UInt64): UInt64 {
    return unsafe { cjgui_internal_renderer_data_transfer_event_delivery_ordinal(session) }
}

func internalRendererDataTransferEventBinary(session: UInt64, eventId: UInt64): ?Array<Byte> {
    if (eventId == 0u64) { return None }
    let length = unsafe { cjgui_internal_renderer_data_transfer_event_binary_size(session, eventId) }
    if (length == 0u32 || length > 512u32 * 1024u32) { return None }
    let bytes = Array<Byte>(Int64(length), repeat: 0)
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        let handle = acquireArrayRawData(bytes)
        status = cjgui_internal_renderer_copy_data_transfer_event_binary(
            session, eventId, handle.pointer, length)
        releaseArrayRawData(handle)
    }
    return if (status == CJGUI_INTERNAL_RENDERER_OK) { Some(bytes) } else { None }
}

func internalRendererRequestClose(session: UInt64): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    cjguiOwnerTraceBoundary(session, 0u64, 167u32, 0u32, 166u32, 0u64, UInt64.Max)
    unsafe {
        status = cjgui_internal_renderer_request_close(session)
    }
    cjguiOwnerTraceBoundary(session, 0u64, 168u32, 0u32, 166u32,
        if (status >= 0) { UInt64(status) } else { UInt64.Max }, UInt64.Max)
    return status
}

// macOS destroy already closes the actual NSWindow synchronously before it
// releases the session. A separate pre-close adds an unnecessary main hop.
// Other backends keep their original pre-close protocol.
@When[os == "macOS"]
func internalRendererRequestCloseBeforeDestroy(session: UInt64): Unit {}

@When[os != "macOS"]
func internalRendererRequestCloseBeforeDestroy(session: UInt64): Unit {
    let _ = internalRendererRequestClose(session)
}

@When[os == "macOS"]
func internalRendererCloseStopsNewOwnerWork(closePending: Bool, retryPending: Bool): Bool {
    return closePending || retryPending
}

@When[os != "macOS"]
func internalRendererCloseStopsNewOwnerWork(closePending: Bool, retryPending: Bool): Bool { return false }

func internalRendererDestroy(session: UInt64): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    cjguiOwnerTraceBoundary(session, 0u64, 164u32, 0u32, 163u32, 0u64, UInt64.Max)
    unsafe {
        status = cjgui_internal_renderer_destroy(session)
    }
    cjguiOwnerTraceBoundary(session, 0u64, 165u32, 0u32, 163u32,
        if (status >= 0) { UInt64(status) } else { UInt64.Max }, UInt64.Max)
    return status
}

func internalRendererOccupiedSessionCount(): UInt32 {
    var count: UInt32 = 0
    unsafe {
        count = cjgui_internal_renderer_occupied_session_count()
    }
    return count
}

// ---- experimental bounded document preview API ----

/// Immutable, value-only result for the experimental macOS document preview.
/// `preview` never contains an NSString or native pointer. The API is
/// intentionally platform-scoped: AppKit's composed-character ranges are the
/// boundary guarantee, not a claim of cross-platform Unicode grapheme
/// segmentation.
public class CjguiExperimentalDocumentPreviewResult {
    public let preview: String
    public let isAvailable: Bool
    public let isTruncated: Bool
    public let reason: String
    public let stability: String
    public let platform: String

    public init(preview: String, isAvailable: Bool, isTruncated: Bool, reason: String) {
        this.preview = preview
        this.isAvailable = isAvailable
        this.isTruncated = isTruncated
        this.reason = reason
        this.stability = "experimental"
        this.platform = "macOS"
    }
}

private const CJGUI_EXPERIMENTAL_DOCUMENT_PREVIEW_SCAN_BYTES: Int64 = 2048
private const CJGUI_EXPERIMENTAL_DOCUMENT_PREVIEW_DEFAULT_MAX_BYTES: Int64 = 512
private const CJGUI_EXPERIMENTAL_DOCUMENT_PREVIEW_DEFAULT_MAX_CLUSTERS: Int64 = 160

private class CjguiExperimentalDocumentPreviewInput {
    let value: String
    let inputComplete: UInt8
    init(value: String, inputComplete: UInt8) {
        this.value = value
        this.inputComplete = inputComplete
    }
}

/// Make only a scalar-safe window in Cangjie. AppKit, not this loop, decides
/// composed-character boundaries. A long composed sequence is still bounded
/// by the 2 KiB byte window because each scalar is appended at most once.
private func cjguiExperimentalDocumentPreviewInput(value: String): CjguiExperimentalDocumentPreviewInput {
    let window = StringBuilder()
    var complete = 1u8
    for (rune in value.runes()) {
        let scalar = rune.toString()
        if (window.size + scalar.size > CJGUI_EXPERIMENTAL_DOCUMENT_PREVIEW_SCAN_BYTES) {
            complete = 0u8
            break
        }
        window.append(scalar)
    }
    return CjguiExperimentalDocumentPreviewInput(window.toString(), complete)
}

// `prefixBytes` is produced by AppKit at a composed-character boundary. This
// loop merely reconstructs those exact UTF-8 bytes as Cangjie text; it never
// invents an independent truncation boundary.
private func cjguiExperimentalDocumentPreviewPrefix(value: String, prefixBytes: Int64): String {
    if (prefixBytes <= 0) {
        return ""
    }
    let output = StringBuilder()
    var bytes: Int64 = 0
    for (rune in value.runes()) {
        let scalar = rune.toString()
        if (bytes + scalar.size > prefixBytes) {
            break
        }
        output.append(scalar)
        bytes += scalar.size
        if (bytes == prefixBytes) {
            break
        }
    }
    return output.toString()
}

/// Return a bounded summary using AppKit composed-character semantics on
/// macOS. `maxBytes` is 4..512 and `maxClusters` is 1..160. Invalid arguments
/// fail as a value result; malformed UTF-8 from the internal bridge maps to
/// `invalid_utf8`. No repair loop or native object escapes this API.
public func cjguiExperimentalDocumentPreview(
    value: String,
    maxBytes!: Int64 = CJGUI_EXPERIMENTAL_DOCUMENT_PREVIEW_DEFAULT_MAX_BYTES,
    maxClusters!: Int64 = CJGUI_EXPERIMENTAL_DOCUMENT_PREVIEW_DEFAULT_MAX_CLUSTERS
): CjguiExperimentalDocumentPreviewResult {
    if (maxBytes < 4 || maxBytes > 512 || maxClusters < 1 || maxClusters > 160) {
        return CjguiExperimentalDocumentPreviewResult("", false, false, "invalid_argument")
    }
    if (value.size == 0) {
        return CjguiExperimentalDocumentPreviewResult("", true, false, "ok")
    }
    let input = cjguiExperimentalDocumentPreviewInput(value)
    // Reserve U+2026 before native composed-character selection.  Trimming a
    // complete native range later by scalar bytes can split a ZWJ sequence.
    // A complete source may therefore use at most `maxBytes - 3`; `maxBytes`
    // remains the strict result bound, including the truncation marker.
    let nativePrefixBudget = maxBytes - 3
    var prefixBytes: UInt64 = 0u64
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    let cInput = unsafe { LibC.mallocCString(input.value) }
    try (inputResource = cInput.asResource()) {
        unsafe {
            status = cjgui_internal_renderer_composed_prefix_utf8_length(
                inputResource.value,
                UInt64(input.value.size),
                UInt64(nativePrefixBudget),
                UInt64(maxClusters),
                input.inputComplete,
                inout prefixBytes
            )
        }
    }
    if (status == CJGUI_INTERNAL_RENDERER_INVALID_UTF8) {
        return CjguiExperimentalDocumentPreviewResult("", false, false, "invalid_utf8")
    }
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        return CjguiExperimentalDocumentPreviewResult("", false, false, "native_unavailable")
    }
    let scanWasTruncated = input.inputComplete == 0u8
    let prefixWasBounded = prefixBytes < UInt64(input.value.size)
    let wasTruncated = scanWasTruncated || prefixWasBounded
    let prefix = cjguiExperimentalDocumentPreviewPrefix(input.value, Int64(prefixBytes))
    let preview = if (wasTruncated) {
        prefix + "…"
    } else {
        prefix
    }
    return CjguiExperimentalDocumentPreviewResult(preview, true, wasTruncated, "ok")
}
