package cjgui

import std.collection.*
import std.time.*
import std.convert.*

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
let CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED: Int32 = 16
let CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY: Int32 = 18
let CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED: Int32 = 32
let CJGUI_INTERNAL_RENDERER_SCENE_STALE: Int32 = 33
// H 内部恢复票据的「等待人锚」回执：与 PRESENT_PENDING 同类，是**有终态的等待**
// 而不是拒绝。窗口不得把它计入失败重试预算，也不得据此声称选区已落位。
let CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_ANCHOR_PENDING: Int32 = 36
let CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR: Int32 = 99

// Invalid session token sentinel.
let CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN: UInt64 = 0

// ---- @C struct mappings (layout-identical to the C POD structs) ----

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
struct CjguiInternalRendererProxyRestoreTicket {
    var requestId: UInt64 = 0
    var contextId: Int64 = 0
    var contextGeneration: UInt64 = 0
    var acceptedBindingEpoch: UInt64 = 0
    var acceptedProjectionVersion: UInt64 = 0
    var deadlineMonoMs: Int64 = 0
    var canonicalStart: UInt32 = 0
    var canonicalEnd: UInt32 = 0
    var state: Int32 = 0
}

// 票据相位（镜像 CjguiInternalRendererProxyRestoreState）。
let CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_NONE: Int32 = 0
let CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_QUEUED: Int32 = 1
let CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_SENT: Int32 = 2
let CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_INSTALLED: Int32 = 3
let CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_ADOPTED: Int32 = 4
let CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_NOT_INSTALLED: Int32 = 5
let CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_UNCONFIRMED: Int32 = 6
let CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_END_OF_TEXT: Int64 = 4294967295

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
struct CjguiInternalRendererComposableDataTransferItem {
    var nodeId: UInt64 = 0
    var projectionVersion: UInt64 = 0
    var resourceId: Int64 = -1
    var nodeKind: UInt32 = 0
    var role: UInt32 = 0
    var maximumPayloadBytes: UInt32 = 0
    var sourceId: Int64 = -1
    init(nodeId!: UInt64, projectionVersion!: UInt64, resourceId!: Int64, nodeKind!: UInt32, role!: UInt32,
        maximumPayloadBytes!: UInt32, sourceId!: Int64) {
        this.nodeId = nodeId
        this.projectionVersion = projectionVersion
        this.resourceId = resourceId
        this.nodeKind = nodeKind
        this.role = role
        this.maximumPayloadBytes = maximumPayloadBytes
        this.sourceId = sourceId
    }
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
    init(nextTicketId: Int64, unackedTicketId: Int64, acceptedCount: Int64, rejectedCount: Int64,
        queryCount: Int64, ackCount: Int64, duplicateSettlementCount: Int64, destroyRefusedCount: Int64,
        available: Bool) {
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

struct InternalRendererPumpResult {
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
    init(status: Int32, eventKind: UInt32, recordIndex: UInt32, selectionStart: UInt32, selectionEnd: UInt32,
        nodeId: UInt64, projectionVersion: UInt64, resourceId: Int64, nodeKind: UInt32, pointerX: Int64,
        pointerY: Int64, modifierFlags: Int64, compositionPhase: UInt32, replacementStart16: Int64,
        replacementLength16: Int64, markedStart16: Int64, markedLength16: Int64, compositionId: UInt64,
        bindingEpoch: UInt64, dataTransferEventId: UInt64,
        gestureAppInstance: UInt64, gestureComponentInstance: UInt64,
        gestureSurfaceGeneration: UInt64, gesturePointerId: Int64,
        gestureEpoch: UInt64, acceptedBindingEpoch: UInt64) {
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
    init(status: Int32, submittedFrameIndex: UInt64, observedMetalCompletionFrameIndex: UInt64,
        observedMetalFailureFrameIndex: UInt64, observedMetalGpuDurationMicros: Int64,
        overlayDrawnProjectionVersion: UInt64) {
        this.status = status
        this.submittedFrameIndex = submittedFrameIndex
        this.observedMetalCompletionFrameIndex = observedMetalCompletionFrameIndex
        this.observedMetalFailureFrameIndex = observedMetalFailureFrameIndex
        this.observedMetalGpuDurationMicros = observedMetalGpuDurationMicros
        this.overlayDrawnProjectionVersion = overlayDrawnProjectionVersion
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

    func cjgui_internal_renderer_set_window_title(session: UInt64, title: CString): Int32

    func cjgui_internal_renderer_set_composable_range_edit_delta(session: UInt64, enabled: Int32): Int32

    func cjgui_internal_renderer_set_composable_owned_text_session(
        session: UInt64,
        nodeId: UInt64,
        resourceId: Int64,
        nodeKind: UInt32,
        bindingEpoch: UInt64,
        enabled: Int32,
        mirrorText: CString,
        mirrorVersion: Int64
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

    func cjgui_internal_renderer_recover_text_proxy_ticket(
        session: UInt64,
        nodeId: UInt64,
        resourceId: Int64,
        nodeKind: UInt32,
        sceneVersion: UInt64,
        acceptedValue: CString,
        selectionStart: UInt32,
        selectionEnd: UInt32,
        outTicket: CPointer<CjguiInternalRendererProxyRestoreTicket>
    ): Int32

    func cjgui_internal_renderer_query_proxy_restore_ticket(
        session: UInt64,
        requestId: UInt64,
        outTicket: CPointer<CjguiInternalRendererProxyRestoreTicket>
    ): Int32

    func cjgui_internal_renderer_consume_proxy_restore_ticket(
        session: UInt64,
        requestId: UInt64,
        adoptedStart: UInt32,
        adoptedEnd: UInt32,
        outConsumed: CPointer<Int32>
    ): Int32

    func cjgui_internal_renderer_present_clear(
        session: UInt64,
        color: CPointer<CjguiInternalRendererClearColor>,
        outObservation: CPointer<CjguiInternalRendererFrameObservation>
    ): Int32

    func cjgui_internal_renderer_configure_composable_scene(
        session: UInt64,
        projectionVersion: UInt64,
        nodeCount: UInt32
    ): Int32

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

    func cjgui_internal_renderer_set_composable_node_semantic_identity(
        session: UInt64,
        nodeIndex: UInt32,
        semanticId: CString
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

    func cjgui_ohos_focus_generation(session: UInt64): UInt64
    func cjgui_ohos_restore_focus_checked(session: UInt64, nodeId: UInt64,
        expectedBindingEpoch: UInt64, focusGeneration: UInt64): Int32

    func cjgui_internal_renderer_focus_composable_node(session: UInt64, nodeId: UInt64): Int32
    func cjgui_internal_renderer_focus_composable_node_checked(
        session: UInt64, nodeId: UInt64, expectedBindingEpoch: UInt64): Int32

    func cjgui_internal_renderer_restore_composable_selection(
        session: UInt64, nodeId: UInt64, resourceId: Int64, nodeKind: UInt32,
        sceneVersion: UInt64, expectedValue: CString, selectionStart: UInt32, selectionEnd: UInt32,
        outSelectionStart: CPointer<UInt32>, outSelectionEnd: CPointer<UInt32>
    ): Int32

    // H1-R.a：一次性取走"人在 native 表面上亲手放置的落点"。1=身份与值全部命中并已消费，
    // 0=无匹配（零改动），-1=参数/会话无效。平台回声取不走锚。
    func cjgui_internal_renderer_take_human_selection_anchor(
        session: UInt64, nodeId: UInt64, resourceId: Int64, nodeKind: UInt32,
        projectionVersion: UInt64, acceptedBindingEpoch: UInt64,
        selectionStart: UInt32, selectionEnd: UInt32, outAnchorSeq: CPointer<UInt64>
    ): Int32

    // 通用窗口诊断出口：Cangjie 侧 println 在 OHOS 不进 hilog，窗口内部判定在
    // 设备上不可见。这个出口只把字符串记进渲染器日志，不读写会话状态。
    func ohos_renderer_window_log(message: CString): Int32

    // H 连续写作包 A：键盘遮挡上沿（surface 内 px；-1=无键盘）与编辑 caret
    // 场景矩形（vp）。只读；写入在平台桥与渲染线程绘制点。
    func ohos_renderer_keyboard_overlay_top_vp(): Float64
    func ohos_renderer_effective_visible_band(session: UInt64, expectedScene: UInt64,
        outWidth: CPointer<Float64>, outHeight: CPointer<Float64>): Int32
    func ohos_renderer_accepted_active_caret_rect(session: UInt64, expectedScene: UInt64,
        outNodeId: CPointer<UInt64>, outBinding: CPointer<UInt64>, outLeftVp: CPointer<Float64>,
        outTopVp: CPointer<Float64>, outRightVp: CPointer<Float64>, outBottomVp: CPointer<Float64>): Int32

    // round9-A（H 私有只读接缝）：取**最近一次出队事件**在入队时冻结的来源身份
    // （editingContextId + editingContextGeneration）。公共事件 POD 没有这两个
    // 字段（POD 布局有静态断言，不可扩），所以窗口无法从事件本身知道它属于哪个
    // 挂载；这个出口把「该事件自己的」来源交回窗口，使采纳事实能带来源而不是
    // 打印时的当前值。返回 0=有来源，1=本次事件没有来源身份，-1=参数错。
    // 在会话锁下一次读出 (ctx, gen, seq) 三元组：避免多次独立读撕裂成
    // 「事件 N 的 ctx + 事件 N+1 的 gen」。seq 随每次成功出队推进。
    func ohos_renderer_last_event_provenance(session: UInt64,
        outCtx: CPointer<Int64>, outGen: CPointer<UInt64>, outSeq: CPointer<UInt64>
    ): Int32

    // round9-D：拉取式有界只读状态读回，返回 native 拼好的**中性事实串**。
    //
    // 形状与本仓库既有的 `cjgui_internal_renderer_form_event_text` 相同：native 持有
    // 缓冲、调用方只读一次（借用指针，下一次调用会覆盖）。不用几十个出参——票据环
    // 展开后是 109 个实参，既不可读也超出编译器接受范围。
    //
    // 事实**不经过 hilog**：设备日志是环形缓冲且按 tag 限流，「没看到某行」推不出
    // 「没发生」。串里**不含**产品语义分类（无 source/preview 字样）——面归产品判。
    // 返回 nullptr 表示会话不存在。
    func ohos_renderer_accepted_state(session: UInt64): CString
    func cjgui_ohos_declare_owned_text_source(session: UInt64, nodeId: UInt64, resourceId: Int64,
        nodeKind: UInt32, bindingEpoch: UInt64, enabled: Int32, mirrorText: CString,
        mirrorVersion: Int64, basis: CString): Int32
    func ohos_renderer_caret_paint_progress(session: UInt64): UInt64
    func ohos_renderer_input_ticket_fact(session: UInt64, part: UInt32): CString
    func ohos_renderer_publish_choice(session: UInt64, basis: CString, accepted: Int32): Int32
    func ohos_renderer_input_dirty_ticket(session: UInt64): UInt64
    func ohos_renderer_finish_refused_input(session: UInt64, ticket: UInt64, request: UInt64, basis: CString): Int32
    func ohos_renderer_publish_restore_choice(session: UInt64, request: UInt64, basis: CString): Int32
    func ohos_renderer_input_owner_completion(session: UInt64, ticket: UInt64, accepted: Int32): Int32
    func ohos_renderer_complete_owned_input(session: UInt64, ticket: UInt64, accepted: Int32,
        ownerVersion: Int64, postOrigin: Int64, basis: CString): Int32


    func cjgui_internal_renderer_cancel_composable_pointer_capture(session: UInt64): Int32    func cjgui_internal_renderer_cancel_composable_pointer_capture_gesture_key(session: UInt64,
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

    func cjgui_internal_renderer_accepted_scene_version(
        session: UInt64,
        outSceneVersion: CPointer<UInt64>
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

func internalRendererPumpEvent(session: UInt64, timeoutMs: UInt32): InternalRendererPumpResult {
    var event = CjguiInternalRendererEvent()
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        status = cjgui_internal_renderer_pump_event(session, timeoutMs, inout event)
    }
    return InternalRendererPumpResult(status, event.kind, event.recordIndex, event.selectionStart, event.selectionEnd,
        event.nodeId, event.projectionVersion, event.resourceId, event.nodeKind, event.pointerX, event.pointerY,
        event.modifierFlags, event.compositionPhase, event.replacementStart16, event.replacementLength16,
        event.markedStart16, event.markedLength16, event.compositionId, event.bindingEpoch,
        event.dataTransferEventId,
        event.gestureAppInstance, event.gestureComponentInstance,
        event.gestureSurfaceGeneration, event.gesturePointerId, event.gestureEpoch,
        event.acceptedBindingEpoch)
}

func internalRendererConfigureComposableScene(session: UInt64, projectionVersion: UInt64, nodeCount: UInt32): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_configure_composable_scene(session, projectionVersion, nodeCount) }
    return status
}

func internalRendererConfigureComposableCommandMenu(session: UInt64, projectionVersion: UInt64,
    itemCount: UInt32): Int32 {
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
                            if (enabled) { 1u8 } else { 0u8 },
                            if (checked) { 1u8 } else { 0u8 }
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
    imageResourceVersion: Int64
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
                        unsafe {
                            status = cjgui_internal_renderer_set_composable_scene_node(
                                session,
                                nodeIndex,
                                inout mutableNode,
                                labelResource.value,
                                valueResource.value,
                                imageResource.value,
                                imageResourceIdResource.value,
                                boundedVersion
                            )
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
                        status = cjgui_internal_renderer_set_composable_data_transfer_item(
                            session, itemIndex, inout mutableItem, formatResource.value, payloadResource.value,
                            sourceKindResource.value, sourceIdentityResource.value)
                    }
                }
            }
        }
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

/// A1：票据取证计数（测试/验证用）。查询失败时 available=false，不伪造事实。
func internalRendererPresentTicketStats(session: UInt64): InternalRendererTicketStats {
    var stats = CjguiInternalRendererPresentTicketStats()
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_present_ticket_stats(session, inout stats) }
    if (status != CJGUI_INTERNAL_RENDERER_OK || stats.available == 0u8) {
        return InternalRendererTicketStats(0, 0, 0, 0, 0, 0, 0, 0, false)
    }
    return InternalRendererTicketStats(stats.nextTicketId, stats.unackedTicketId, stats.acceptedCount,
        stats.rejectedCount, stats.queryCount, stats.ackCount, stats.duplicateSettlementCount,
        stats.destroyRefusedCount, true)
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

/// Reads already-observed renderer facts only. It must never schedule a frame
/// or touch the native input FIFO, so an external GET can safely call it.
func internalRendererComposableDisplayProgress(session: UInt64): InternalRendererComposableDisplayProgressResult {
    var progress = CjguiInternalRendererComposableDisplayProgress()
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_composable_display_progress(session, inout progress) }
    return InternalRendererComposableDisplayProgressResult(
        status,
        progress.submittedFrameIndex,
        progress.observedMetalCompletionFrameIndex,
        progress.observedMetalFailureFrameIndex,
        progress.observedMetalGpuDurationMicros,
        progress.overlayDrawnProjectionVersion
    )
}

func internalRendererFocusGeneration(session: UInt64): UInt64 {
    unsafe { return cjgui_ohos_focus_generation(session) }
}
func internalRendererRestoreFocus(session: UInt64, nodeId: Int64,
    expectedBindingEpoch: UInt64, focusGeneration: UInt64): Int32 {
    if (nodeId < 0 || focusGeneration == 0) { return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR }
    unsafe { return cjgui_ohos_restore_focus_checked(session, UInt64(nodeId), expectedBindingEpoch, focusGeneration) }
}

func internalRendererFocusComposableNode(session: UInt64, nodeId: Int64, expectedBindingEpoch: UInt64): Int32 {
    if (nodeId < 0) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        status = cjgui_internal_renderer_focus_composable_node_checked(session, UInt64(nodeId), expectedBindingEpoch)
    }
    return status
}

// The positions and the returned range are UTF-16 code units. The native side
// validates the accepted scene, exact owner value and active input responder.
func internalRendererRestoreComposableSelection(session: UInt64, nodeId: Int64, resourceId: Int64,
    nodeKind: Int64, sceneVersion: Int64, value: String, start: Int64, end: Int64): (Int32, Int64, Int64) {
    if (nodeId < 0 || nodeKind < 0 || sceneVersion < 0 || start < 0 || end < start ||
        end > 4294967295) {
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

/// 窗口诊断：把一行文本记进渲染器日志（hilog 可见）。失败静默——诊断绝不能
/// 改变任何生产判定，也绝不能因为日志不可用而让调用方走另一条分支。
/// （停摆追因期的编号文件痕迹已按计划撤除，只保留 hilog 通道。）
func internalRendererWindowLog(message: String): Unit {
    let cMessage = unsafe { LibC.mallocCString(message) }
    try (resource = cMessage.asResource()) {
        unsafe {
            let _ = ohos_renderer_window_log(resource.value)
        }
    }
}

/// H 连续写作包 A：读回键盘遮挡上沿（场景 vp；<0 = 无键盘）。
func internalRendererKeyboardOverlayTopVp(): Float64 {
    var value: Float64 = -1.0
    unsafe {
        value = ohos_renderer_keyboard_overlay_top_vp()
    }
    return value
}

/// H 连续写作包 A：读回当前编辑 caret 的场景矩形（vp）。(0=无有效编辑 caret)
func internalRendererEffectiveVisibleBand(session: UInt64, expectedScene: UInt64):
    (Int32, Float64, Float64) {
    var width: Float64 = 0.0
    var height: Float64 = 0.0
    var status: Int32 = 0
    unsafe { status = ohos_renderer_effective_visible_band(session, expectedScene, inout width, inout height) }
    return (status, width, height)
}

func internalRendererCaretPaintProgress(session: UInt64): UInt64 {
    return unsafe { ohos_renderer_caret_paint_progress(session) }
}

func internalRendererAcceptedActiveCaretRect(session: UInt64, expectedScene: UInt64):
    (Int32, UInt64, UInt64, Float64, Float64, Float64, Float64) {
    var nodeId: UInt64 = 0
    var binding: UInt64 = 0
    var leftVp: Float64 = 0.0
    var topVp: Float64 = 0.0
    var bottomVp: Float64 = 0.0
    var rightVp: Float64 = 0.0
    var status: Int32 = -1
    unsafe {
        status = ohos_renderer_accepted_active_caret_rect(session, expectedScene, inout nodeId,
            inout binding, inout leftVp, inout topVp, inout rightVp, inout bottomVp)
    }
    return (status, nodeId, binding, leftVp, topVp, rightVp, bottomVp)
}

/// round9-A：读回「最近一次出队事件」的冻结来源身份。
///
/// 返回 `(hasSource, ctx, generation, seq)`。`hasSource=false` 时**不得**推测来源
/// （例如按当前挂载反填）——那正是旧采纳事实与新挂载不可区分的成因。纯只读。
///
/// **必须在 `pump` 返回非 NONE 之后立刻调用**，并把结果随该事件一起传下去；
/// 不能等到处理事件的深处再读。窗口的 pump 是一个 drain 循环
/// （`pumpWithRefreshPolicy` 先排空 FIFO 再统一发布），循环内可能又出队了
/// 下一条事件——那时读到的是**下一条**的来源，打印出的 `source_ctx` 属于错误的
/// 事件而且没有任何报警。
func internalRendererLastEventProvenance(session: UInt64): (Bool, Int64, UInt64, UInt64) {
    var ctx: Int64 = 0
    var gen: UInt64 = 0u64
    var seq: UInt64 = 0u64
    // 本仓库的 FFI 出参惯例是 inout（见文件头「inout pointers are only valid for
    // the duration of the call」），不是裸 pointer(&x)。
    var rc: Int32 = -1
    unsafe {
        rc = ohos_renderer_last_event_provenance(session, inout ctx, inout gen, inout seq)
    }
    if (rc != 0) {
        return (false, 0, 0u64, seq)
    }
    return (true, ctx, gen, seq)
}

/// round9-D：本窗口此刻的 accepted / 票据阶段事实（一行中性事实串的原文）。
///
/// 全部是**中性事实**：当前 accepted 投影版本、节点数、semantic 摘要、帧号、最近一次
/// 提交的票号，在途票据（票号/结算/终态/来源/候选节点数），以及最近 K=8 张已结算
/// 票据的阶段。**不含**任何产品语义分类——「这一帧是 source 面还是 preview 面」
/// 由调用方按自己的词表判定（通用层硬编码产品前缀会让两层各写一套分类表而互相
/// 矛盾）。
///
/// 返回空串表示读回不可用（会话不存在或出口未生效）——调用方必须把它与「读到但
/// 不是目标」分开具名，**不得**当成「没提交」。
public func internalRendererReadAcceptedStateText(session: UInt64): String {
    if (session == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
        return ""
    }
    // 与 internalRendererFormEventText 同一写法：借用指针直接 toString（native
    // 持有缓冲，下一次调用覆盖）。
    let borrowed = unsafe { ohos_renderer_accepted_state(session) }
    let text = borrowed.toString()
    return if (text.isEmpty()) { "" } else { "ACCEPTED " + text }
}

/// 取走"人在 native 表面上亲手放置的落点"（H1-R.a），返回 (taken, anchorSeq)。
/// taken=1 表示 native 有一枚**未消费**的锚，其冻结的节点身份与本次选区事件的身份、
/// UTF-16 值全部相同；此刻它已被置为已消费，同一锚不会被二次采纳。0 = 无匹配（零改动）。
/// 这条通道把"人的导航"与"平台安装回声"分开：给代理赋值会把 caret 甩到正文末尾，
/// 那个瞬时回声的值与锚不同，因此取不走锚，也就不能解除会话的输入门禁。
func internalRendererTakeHumanSelectionAnchor(session: UInt64, nodeId: Int64, resourceId: Int64,
    nodeKind: Int64, projectionVersion: Int64, acceptedBindingEpoch: Int64,
    start16: Int64, end16: Int64): (Int32, Int64) {
    if (nodeId < 0 || nodeKind < 0 || projectionVersion < 0 || acceptedBindingEpoch <= 0 ||
        start16 < 0 || end16 < start16 || start16 > 4294967295 || end16 > 4294967295) {
        return (0, 0)
    }
    var anchorSeq: UInt64 = 0
    var taken: Int32 = 0
    unsafe {
        taken = cjgui_internal_renderer_take_human_selection_anchor(session, UInt64(nodeId), resourceId,
            UInt32(nodeKind), UInt64(projectionVersion), UInt64(acceptedBindingEpoch),
            UInt32(start16), UInt32(end16), inout anchorSeq)
    }
    return (taken, Int64(anchorSeq))
}

/// Roll back the hidden text proxy after the application refused a human range
/// edit: restore the value the owner already accepted, under projection
/// suppression, and report the installed grapheme-safe selection. It never
/// creates document truth and fails without changing anything when the target
/// is no longer the active node or the accepted value is stale.
func internalRendererRecoverActiveTextProxy(session: UInt64, nodeId: Int64, resourceId: Int64,
    nodeKind: Int64, acceptedValue: String): (Int32, Int64, Int64) {
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

/// H1-R：一次逻辑恢复的唯一签发入口。native 在同一临界区内验证 accepted 正文、
/// 场景版本与规范落点，只登记一张票据并返回它冻结的 native 身份 + 单调截止。
/// 调用方此后只信票据里的值：不得再读"当前"镜像/上下文补进这张请求（旧实现正是
/// 这样把新代次贴到旧请求上的）。`requestId == 0` 表示签发失败。
/// 票据的普通仓颉镜像（tuple 成员不得是 @C struct，沿用 present 回执的同款形状）。
struct InternalRendererProxyRestoreTicket {
    let status: Int32
    let requestId: UInt64
    let contextId: Int64
    let contextGeneration: UInt64
    let acceptedBindingEpoch: UInt64
    let acceptedProjectionVersion: UInt64
    let deadlineMonoMs: Int64
    let canonicalStart: Int64
    let canonicalEnd: Int64
    let state: Int32
    init(status: Int32, ticket: CjguiInternalRendererProxyRestoreTicket) {
        this.status = status
        this.requestId = ticket.requestId
        this.contextId = ticket.contextId
        this.contextGeneration = ticket.contextGeneration
        this.acceptedBindingEpoch = ticket.acceptedBindingEpoch
        this.acceptedProjectionVersion = ticket.acceptedProjectionVersion
        this.deadlineMonoMs = ticket.deadlineMonoMs
        this.canonicalStart = Int64(ticket.canonicalStart)
        this.canonicalEnd = Int64(ticket.canonicalEnd)
        this.state = ticket.state
    }
}

func internalRendererRecoverTextProxyTicket(session: UInt64, nodeId: Int64, resourceId: Int64,
    nodeKind: Int64, sceneVersion: Int64, acceptedValue: String, start: Int64,
    end: Int64): (Int32, InternalRendererProxyRestoreTicket) {
    var ticket = CjguiInternalRendererProxyRestoreTicket()
    // resourceId = -1 合法：presentation 锚点节点（可视编辑包，如预览正文容器）
    // 声明时不带资源号，native 侧按完整身份校验，这里不再提前拒绝。
    if (nodeId < 0 || nodeKind < 0 || sceneVersion < 0 || resourceId < -1 ||
        (start < 0 && start != CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_END_OF_TEXT) ||
        (end < 0 && end != CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_END_OF_TEXT) ||
        end > CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_END_OF_TEXT ||
        start > CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_END_OF_TEXT) {
        return (CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR, InternalRendererProxyRestoreTicket(
            CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR, ticket))
    }
    let cValue = unsafe { LibC.mallocCString(acceptedValue) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (valueResource = cValue.asResource()) {
        unsafe {
            status = cjgui_internal_renderer_recover_text_proxy_ticket(session, UInt64(nodeId), resourceId,
                UInt32(nodeKind), UInt64(sceneVersion), valueResource.value, UInt32(start), UInt32(end),
                inout ticket)
        }
    }
    return (status, InternalRendererProxyRestoreTicket(status, ticket))
}

/// 按请求号查询票据。窗口自己的截止检查用它：事件丢失时仍能按票据终结待办，
/// 而不是宣称"平台没装"或直接解锁。
func internalRendererQueryProxyRestoreTicket(session: UInt64,
    requestId: UInt64): (Int32, InternalRendererProxyRestoreTicket) {
    var ticket = CjguiInternalRendererProxyRestoreTicket()
    if (requestId == 0u64) {
        return (CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR, InternalRendererProxyRestoreTicket(
            CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR, ticket))
    }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        status = cjgui_internal_renderer_query_proxy_restore_ticket(session, requestId, inout ticket)
    }
    return (status, InternalRendererProxyRestoreTicket(status, ticket))
}

/// 窗口采纳成功后的唯一消费点（与 native 的截止/取消竞争同一张票据，只有一个胜者）。
/// 返回 false 表示这张票据已不属于当前恢复（被终结/被取代/落点不符），调用方必须
/// 保留恢复意图并按有界重试重新签发，不得计成功。
func internalRendererConsumeProxyRestoreTicket(session: UInt64, requestId: UInt64,
    adoptedStart: Int64, adoptedEnd: Int64): Bool {
    if (requestId == 0u64 || adoptedStart < 0 || adoptedEnd < adoptedStart ||
        adoptedEnd > CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_END_OF_TEXT) {
        return false
    }
    var consumed: Int32 = 0
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        status = cjgui_internal_renderer_consume_proxy_restore_ticket(session, requestId,
            UInt32(adoptedStart), UInt32(adoptedEnd), inout consumed)
    }
    return status == CJGUI_INTERNAL_RENDERER_OK && consumed == 1
}

func internalRendererCancelComposablePointerCapture(session: UInt64): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_cancel_composable_pointer_capture(session) }
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
        return this.queryKind == queryKind && this.value == value && this.fontSize == style.fontSize && this.fontWeight == style.fontWeight &&
            this.fontFamily == style.fontFamily && this.maximumWidth == maximumWidth
    }
}

/// Production font measurer. It accepts only the opaque renderer session and
/// returns copied scalar metrics; NSFont/NSString/Metal objects remain owned
/// by the native sidecar. The fallback is used only to complete the current
/// local calculation safely: callers inspect `measurementStatus` and refuse
/// to publish the scene if any real AppKit query failed.
class CjguiInternalRendererTextMeasurer <: CjguiComposableUiTextMeasurer &
    CjguiComposableUiMultilineNaturalHeightMeasurer & CjguiComposableUiLayoutMeasurementEnvironment {
    private let session: UInt64
    private let fallback: CjguiComposableUiFallbackTextMeasurer
    private var cache: ArrayList<CjguiInternalRendererTextMeasurementCacheEntry>
    private var lastMeasurementStatus: Int32
    private var measurementPassNativeElapsedMsValue: Int64
    private var measurementPassNativeCallCountValue: Int64
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
        return "cjgui-native-text-session-${session}-multiline-natural-height-v1"
    }
    /// A refresh may make many measurement calls. The cached successful
    /// entries are retained, while failure health applies only to this pass.
    public func beginMeasurementPass(): Unit {
        lastMeasurementStatus = CJGUI_INTERNAL_RENDERER_OK
        measurementPassNativeElapsedMsValue = 0
        measurementPassNativeCallCountValue = 0
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
    public func measure(value: String, style: CjguiComposableUiStyle, maximumWidth: Int64): CjguiComposableUiTextMeasurement {
        var cachedIndex: Int64 = 0
        while (cachedIndex < cache.size) {
            let cached = cache[cachedIndex]
            if (cached.matches(value, style, maximumWidth, 0)) {
                return cached.measurement
            }
            cachedIndex += 1
        }
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
        // Bound memory even for a long-lived dashboard with unbounded external
        // labels. Clearing only evicts reusable scalar entries; it never
        // changes the already committed native scene.
        if (cache.size >= 128) {
            cache = ArrayList<CjguiInternalRendererTextMeasurementCacheEntry>()
        }
        cache.add(
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
    public func multilineNaturalContentHeight(value: String, style: CjguiComposableUiStyle,
        contentWidth: Int64): ?Int64 {
        var cachedIndex: Int64 = 0
        while (cachedIndex < cache.size) {
            let cached = cache[cachedIndex]
            if (cached.matches(value, style, contentWidth, 1)) {
                return Some(cached.measurement.height)
            }
            cachedIndex += 1
        }
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
                status = cjgui_internal_renderer_measure_composable_multiline_natural_height(
                    session, textResource.value, style.fontSize,
                    if (style.fontWeight > 0) { 1u32 } else { 0u32 },
                    composableFontFamilyCode(style.fontFamily), boundedWidth, inout nativeHeight)
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
        if (cache.size >= 128) {
            cache = ArrayList<CjguiInternalRendererTextMeasurementCacheEntry>()
        }
        cache.add(CjguiInternalRendererTextMeasurementCacheEntry(
            value, style.fontSize, style.fontWeight, style.fontFamily, contentWidth, 1, result))
        return Some(Int64(nativeHeight))
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
/// 可视编辑包（2026-10-04）：锚点节点可以是 presentation 节点（accepted 值≠
/// 会话镜像），声明同时携带**镜像文本**作为锚点的编辑缓冲事实；原生在播种/
/// 恢复校验时优先消费它，节点只提供身份与几何。撤回时传空串。
func internalRendererSetComposableOwnedTextSession(session: UInt64, nodeId: UInt64, resourceId: Int64,
    nodeKind: UInt32, bindingEpoch: UInt64, enabled: Bool, mirrorText!: String = "",
    mirrorVersion!: Int64 = -1, sourceBasis!: String = ""): Int32 {
    let flag: Int32 = if (enabled) {
        1
    } else {
        0
    }
    let cMirror = unsafe { LibC.mallocCString(mirrorText) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (mirrorResource = cMirror.asResource()) {
        let cBasis = unsafe { LibC.mallocCString(sourceBasis) }
        try (basisResource = cBasis.asResource()) {
            unsafe {
                status = cjgui_ohos_declare_owned_text_source(session, nodeId,
                    resourceId, nodeKind, bindingEpoch, flag, mirrorResource.value, mirrorVersion, basisResource.value)
            }
        }
    }
    return status
}

// Read immediately for this pump result, before another event is dequeued.
class CjguiOhosInputTicketFact {
    let id: Int64; let predecessor: Int64; let key: String; let basis: String
    let before: String; let after: String; let field: String
    let choiceBasis: String; let observation: Int64
    let node: Int64; let resource: Int64; let nodeKind: Int64
    let ownerBinding: UInt64; let acceptedBinding: UInt64; let projection: UInt64
    let start16: Int64; let end16: Int64; let inserted: String; let malformed: Bool; let transferred: Bool
    init(id: Int64, predecessor: Int64, key: String, basis: String,
        before: String, after: String, field: String, choiceBasis!: String = "", observation!: Int64 = 0,
        node!: Int64 = -1, resource!: Int64 = -1, nodeKind!: Int64 = -1,
        ownerBinding!: UInt64 = 0u64, acceptedBinding!: UInt64 = 0u64, projection!: UInt64 = 0u64,
        start16!: Int64 = -1, end16!: Int64 = -1, inserted!: String = "", malformed!: Bool = false, transferred!: Bool = false) {
        this.id=id; this.predecessor=predecessor; this.key=key; this.basis=basis
        this.before=before; this.after=after; this.field=field; this.choiceBasis=choiceBasis; this.observation=observation
        this.node=node; this.resource=resource; this.nodeKind=nodeKind
        this.ownerBinding=ownerBinding; this.acceptedBinding=acceptedBinding; this.projection=projection
        this.start16=start16; this.end16=end16; this.inserted=inserted; this.malformed=malformed; this.transferred=transferred
    }
}
func internalRendererInputTicket(session: UInt64): ?CjguiOhosInputTicketFact {
    let raw = unsafe { ohos_renderer_input_ticket_fact(session, 0u32) }.toString()
    if (raw.isEmpty()) { return None }
    // Presence and validity differ: a malformed real origin never falls back
    // to a legacy callback lacking a source ticket.
    let invalid = CjguiOhosInputTicketFact(-1,0,"","","","","",malformed:true)
    let parts = raw.split("|")
    if (parts.size != 4) { return Some(invalid) }
    let id = match (Int64.tryParse(parts[0])) { case Some(v) => v; case None => return Some(invalid) }
    let predecessor = match (Int64.tryParse(parts[1])) { case Some(v) => v; case None => return Some(invalid) }
    if (id <= 0 || predecessor < 0 || parts[2].isEmpty()) { return Some(invalid) }
    let before = unsafe { ohos_renderer_input_ticket_fact(session, 1u32) }.toString()
    let after = unsafe { ohos_renderer_input_ticket_fact(session, 2u32) }.toString()
    let field = unsafe { ohos_renderer_input_ticket_fact(session, 3u32) }.toString()
    let choice = unsafe { ohos_renderer_input_ticket_fact(session, 4u32) }.toString()
    let observation = match (Int64.tryParse(unsafe { ohos_renderer_input_ticket_fact(session, 5u32) }.toString())) { case Some(v) => v; case None => 0 }
    let metadata = unsafe { ohos_renderer_input_ticket_fact(session, 6u32) }.toString().split(",")
    if (metadata.size != 8) { return Some(invalid) }
    var values = ArrayList<Int64>()
    for (part in metadata) {
        let v = match (Int64.tryParse(part)) { case Some(value) => value; case None => return Some(invalid) }
        values.add(v)
    }
    if (values[0] <= 0 || values[2] <= 0 || values[3] <= 0 || values[4] <= 0 || values[5] < 0 ||
        values[6] < 0 || values[7] < values[6]) { return Some(invalid) }
    let inserted = unsafe { ohos_renderer_input_ticket_fact(session, 7u32) }.toString()
    return Some(CjguiOhosInputTicketFact(id,predecessor,parts[2],parts[3],before,after,field,
        choiceBasis:choice,observation:observation,node:values[0],resource:values[1],nodeKind:values[2],
        projection:UInt64(values[3]),acceptedBinding:UInt64(values[4]),ownerBinding:UInt64(values[5]),
        start16:values[6],end16:values[7],inserted:inserted,
        transferred: unsafe { ohos_renderer_input_ticket_fact(session,8u32) }.toString() == "1"))
}

func internalRendererPublishObservedChoice(session: UInt64, basis: String, accepted: Bool): Bool {
    let c = unsafe { LibC.mallocCString(basis) }
    var published = false
    try (resource = c.asResource()) {
        published = unsafe { ohos_renderer_publish_choice(session, resource.value, if (accepted) { 1 } else { 0 }) } == 0
    }
    return published
}
func internalRendererInputDirtyTicket(session: UInt64): Int64 {
    return Int64(unsafe { ohos_renderer_input_dirty_ticket(session) })
}
func internalRendererPublishRestoredChoice(session: UInt64, request: UInt64, basis: String): Bool {
    let c=unsafe { LibC.mallocCString(basis) }
    var okay=false
    try (resource=c.asResource()) {
        okay = unsafe { ohos_renderer_publish_restore_choice(session,request,resource.value) } == 0
    }
    return okay
}
func internalRendererFinishRefusedInput(session: UInt64, ticket: Int64, request: UInt64, basis: String): Bool {
    let c=unsafe { LibC.mallocCString(basis) }
    var okay=false
    try (resource=c.asResource()) {
        okay = unsafe { ohos_renderer_finish_refused_input(session,UInt64(ticket),request,resource.value) } == 0
    }
    return okay
}
func internalRendererInputOwnerCompletion(session: UInt64, id: Int64, accepted: Bool,
    ownerVersion!: Int64 = -1, postOrigin!: Int64 = -1, basis!: String = ""): Bool {
    if (id <= 0) { return false }
    if (ownerVersion < 0) {
        return unsafe { ohos_renderer_input_owner_completion(session, UInt64(id), if (accepted) { 1 } else { 0 }) } == 0
    }
    let c=unsafe { LibC.mallocCString(basis) }
    var okay=false
    try (resource=c.asResource()) {
        okay = unsafe { ohos_renderer_complete_owned_input(session,UInt64(id),if(accepted){1}else{0},
            ownerVersion,postOrigin,resource.value) } == 0
    }
    return okay
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

func internalRendererRequestClose(session: UInt64): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        status = cjgui_internal_renderer_request_close(session)
    }
    return status
}

func internalRendererDestroy(session: UInt64): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        status = cjgui_internal_renderer_destroy(session)
    }
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
