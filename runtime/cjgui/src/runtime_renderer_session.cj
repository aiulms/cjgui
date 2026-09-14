package cjgui

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
let CJGUI_INTERNAL_RENDERER_INVALID_UTF8: Int32 = 14
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
        textGreen!: Float64, textBlue!: Float64, textAlpha!: Float64, inputScope!: UInt64 = 0) {
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
    init(status: Int32, frameIndex: UInt64, drawableWidthPixels: UInt32, drawableHeightPixels: UInt32,
        contentsScale: Float64, readbackAttempted: UInt8, readbackCompleted: UInt8, readbackColorMatched: UInt8) {
        this.status = status
        this.frameIndex = frameIndex
        this.drawableWidthPixels = drawableWidthPixels
        this.drawableHeightPixels = drawableHeightPixels
        this.contentsScale = contentsScale
        this.readbackAttempted = readbackAttempted
        this.readbackCompleted = readbackCompleted
        this.readbackColorMatched = readbackColorMatched
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
    init(status: Int32, eventKind: UInt32, recordIndex: UInt32, selectionStart: UInt32, selectionEnd: UInt32,
        nodeId: UInt64, projectionVersion: UInt64, resourceId: Int64, nodeKind: UInt32, pointerX: Int64,
        pointerY: Int64) {
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

    func cjgui_internal_renderer_create(
        config: CPointer<CjguiInternalRendererConfig>,
        outStatus: CPointer<Int32>
    ): UInt64

    func cjgui_internal_renderer_set_window_title(session: UInt64, title: CString): Int32

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

    func cjgui_internal_renderer_present_composable_scene(
        session: UInt64,
        outObservation: CPointer<CjguiInternalRendererFrameObservation>
    ): Int32

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

    func cjgui_internal_renderer_focus_composable_node(session: UInt64, nodeId: UInt64): Int32

    func cjgui_internal_renderer_cancel_composable_pointer_capture(session: UInt64): Int32

    func cjgui_internal_renderer_measure_composable_text(
        session: UInt64,
        text: CString,
        fontSize: Float64,
        fontWeight: UInt32,
        fontFamily: UInt32,
        maximumWidth: UInt32,
        outMeasurement: CPointer<CjguiInternalRendererTextMeasurement>
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
        event.nodeId, event.projectionVersion, event.resourceId, event.nodeKind, event.pointerX, event.pointerY)
}

func internalRendererConfigureComposableScene(session: UInt64, projectionVersion: UInt64, nodeCount: UInt32): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_configure_composable_scene(session, projectionVersion, nodeCount) }
    return status
}

func internalRendererSetComposableSceneNode(
    session: UInt64,
    nodeIndex: UInt32,
    node: CjguiInternalRendererComposableNode,
    label: String,
    value: String,
    imageResourcePath: String,
    imageResourceId: String,
    imageResourceVersion: Int64
): Int32 {
    var mutableNode = node
    let cLabel = unsafe { LibC.mallocCString(label) }
    let cValue = unsafe { LibC.mallocCString(value) }
    let cImageResourcePath = unsafe { LibC.mallocCString(imageResourcePath) }
    let cImageResourceId = unsafe { LibC.mallocCString(imageResourceId) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (labelResource = cLabel.asResource()) {
        try (valueResource = cValue.asResource()) {
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
        observation.readbackCompleted, observation.readbackColorMatched)
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

func internalRendererFocusComposableNode(session: UInt64, nodeId: Int64): Int32 {
    if (nodeId < 0) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe { status = cjgui_internal_renderer_focus_composable_node(session, UInt64(nodeId)) }
    return status
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
    let measurement: CjguiComposableUiTextMeasurement
    init(value: String, fontSize: Float64, fontWeight: Int64, fontFamily: String, maximumWidth: Int64,
        measurement: CjguiComposableUiTextMeasurement) {
        this.value = value
        this.fontSize = fontSize
        this.fontWeight = fontWeight
        this.fontFamily = fontFamily
        this.maximumWidth = maximumWidth
        this.measurement = measurement
    }
    func matches(value: String, style: CjguiComposableUiStyle, maximumWidth: Int64): Bool {
        return this.value == value && this.fontSize == style.fontSize && this.fontWeight == style.fontWeight &&
            this.fontFamily == style.fontFamily && this.maximumWidth == maximumWidth
    }
}

/// Production font measurer. It accepts only the opaque renderer session and
/// returns copied scalar metrics; NSFont/NSString/Metal objects remain owned
/// by the native sidecar. The fallback is used only to complete the current
/// local calculation safely: callers inspect `measurementStatus` and refuse
/// to publish the scene if any real AppKit query failed.
class CjguiInternalRendererTextMeasurer <: CjguiComposableUiTextMeasurer & CjguiComposableUiLayoutMeasurementEnvironment {
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
        return "cjgui-native-text-session-${session}"
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
            if (cached.matches(value, style, maximumWidth)) {
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
                    if (style.fontWeight > 0) {
                        1u32
                    } else {
                        0u32
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
                result
            )
        )
        return result
    }
}

/// Internal ABI enum only. Style construction already normalizes to this
/// closed set, and the native side applies the same system fallback.
func composableFontFamilyCode(fontFamily: String): UInt32 {
    return if (fontFamily == "monospaced") {
        1u32
    } else {
        0u32
    }
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

func internalRendererFormEventText(session: UInt64): String {
    let borrowed = unsafe { cjgui_internal_renderer_form_event_text(session) }
    return borrowed.toString()
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
