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
    init(nodeId!: UInt64, projectionVersion!: UInt64, resourceId!: Int64, nodeKind!: UInt32, role!: UInt32,
        maximumPayloadBytes!: UInt32, sourceId!: Int64, bindingEpoch!: UInt64 = 0u64) {
        this.nodeId = nodeId
        this.projectionVersion = projectionVersion
        this.resourceId = resourceId
        this.nodeKind = nodeKind
        this.role = role
        this.maximumPayloadBytes = maximumPayloadBytes
        this.sourceId = sourceId
        this.bindingEpoch = bindingEpoch
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
    init(status: Int32, eventKind: UInt32, recordIndex: UInt32, selectionStart: UInt32, selectionEnd: UInt32,
        nodeId: UInt64, projectionVersion: UInt64, resourceId: Int64, nodeKind: UInt32, pointerX: Int64,
        pointerY: Int64, modifierFlags: Int64, compositionPhase: UInt32, replacementStart16: Int64,
        replacementLength16: Int64, markedStart16: Int64, markedLength16: Int64, compositionId: UInt64,
        bindingEpoch: UInt64, dataTransferEventId: UInt64) {
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
    init(status: Int32, submittedFrameIndex: UInt64, observedMetalCompletionFrameIndex: UInt64,
        observedMetalFailureFrameIndex: UInt64, observedMetalGpuDurationMicros: Int64,
        overlayDrawnProjectionVersion: UInt64, effectSubmittedSceneVersion: UInt64,
        effectSubmittedFrameIndex: UInt64, effectRequestedRadiusPoints: UInt32,
        effectMode: UInt32, effectFallbackReason: UInt32, effectCompletion: UInt32) {
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

    func cjgui_internal_renderer_cancel_composable_pointer_capture(session: UInt64): Int32

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
        wrapper.canaryTail1 == 0xA5A5A5A55A5A5A5A && wrapper.canaryTail2 == 0x5A5A5A5AA5A5A5A5
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
        event.dataTransferEventId)
}

func internalRendererConfigureComposableScene(session: UInt64, projectionVersion: UInt64, nodeCount: UInt32): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_configure_composable_scene(session, projectionVersion, nodeCount) }
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
        progress.overlayDrawnProjectionVersion,
        progress.effectSubmittedSceneVersion,
        progress.effectSubmittedFrameIndex,
        progress.effectRequestedRadiusPoints,
        progress.effectMode,
        progress.effectFallbackReason,
        progress.effectCompletion
    )
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
    public func multilineNaturalContentHeight(value: String, style: CjguiComposableUiStyle, contentWidth: Int64): ?Int64 {
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
                status = cjgui_internal_renderer_measure_composable_multiline_natural_height(session, textResource.value,
                    style.fontSize, if (style.fontWeight > 0) {
                        1u32
                    } else {
                        0u32
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
        if (cache.size >= 128) {
            cache = ArrayList<CjguiInternalRendererTextMeasurementCacheEntry>()
        }
        cache.add(
            CjguiInternalRendererTextMeasurementCacheEntry(value, style.fontSize, style.fontWeight, style.fontFamily,
                contentWidth, 1, result))
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
