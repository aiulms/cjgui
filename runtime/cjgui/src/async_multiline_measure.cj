package cjgui

// macOS private layout preparation. A candidate owns one handle; only a
// scalar geometry returns from the private worker. No native object or
// thread handle is exposed through the public CJGUI surface.
let CJGUI_ASYNC_MEASURE_STARTED: Int32 = 0
let CJGUI_ASYNC_MEASURE_DEFERRED_CAPACITY: Int32 = 1
let CJGUI_ASYNC_MEASURE_PENDING: Int32 = 2
let CJGUI_ASYNC_MEASURE_READY: Int32 = 3
let CJGUI_ASYNC_MEASURE_FAILED: Int32 = 4
let CJGUI_ASYNC_MEASURE_CANCELLED: Int32 = 5
let CJGUI_ASYNC_MEASURE_STALE_HANDLE: Int32 = 6
let CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT: Int32 = 7
let CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED: Int32 = 0
let CJGUI_ASYNC_MEASURE_RELEASE_ABANDONED: Int32 = 1
let CJGUI_ASYNC_MEASURE_MAX_JOB_BYTES: Int64 = 131072

foreign {
    func cjgui_async_composable_multiline_begin(
        text: CString,
        byteLength: UInt64,
        fontSize: Float64,
        fontWeight: UInt32,
        fontFamily: UInt32,
        contentWidth: UInt32,
        outHandle: CPointer<UInt64>
    ): Int32

    func CjguiAsyncMultilineMeasurePoll(
        handle: UInt64,
        outHeight: CPointer<UInt32>,
        outFailure: CPointer<Int32>
    ): Int32

    func CjguiAsyncMultilineMeasureRelease(handle: UInt64, disposition: Int32): Int32

    func cjgui_async_composable_text_metrics_begin(
        text: CString,
        byteLength: UInt64,
        fontSize: Float64,
        fontWeight: UInt32,
        fontFamily: UInt32,
        maximumWidth: UInt32,
        outHandle: CPointer<UInt64>
    ): Int32

    func CjguiAsyncTextMetricsPoll(handle: UInt64, outMetrics: CPointer<CjguiInternalRendererTextMeasurement>,
        outFailure: CPointer<Int32>): Int32
}

class CjguiAsyncTextMetricsJob {
    let value: String
    let style: CjguiComposableUiStyle
    let fontSize: Float64
    let fontWeight: Int64
    let fontFamily: String
    let maximumWidth: Int64
    let handle: UInt64
    private var released: Bool = false

    init(value: String, style: CjguiComposableUiStyle, maximumWidth: Int64, handle: UInt64) {
        this.value = value
        this.style = style
        this.fontSize = style.fontSize
        this.fontWeight = style.fontWeight
        this.fontFamily = style.fontFamily
        this.maximumWidth = maximumWidth
        this.handle = handle
    }
    func matches(value: String, style: CjguiComposableUiStyle, maximumWidth: Int64): Bool {
        return this.value == value && this.fontSize == style.fontSize && this.fontWeight == style.fontWeight &&
            this.fontFamily == style.fontFamily && this.maximumWidth == maximumWidth
    }
    func poll(): (Int32, CjguiComposableUiTextMeasurement, Int32) {
        var native = CjguiInternalRendererTextMeasurement()
        var failure: Int32 = 0
        let status = if (released) {
            CJGUI_ASYNC_MEASURE_STALE_HANDLE
        } else {
            unsafe { CjguiAsyncTextMetricsPoll(handle, inout native, inout failure) }
        }
        return (status, CjguiComposableUiTextMeasurement(Int64(native.width), Int64(native.height),
                Int64(native.lineHeight), Int64(native.baseline)), failure)
    }
    func release(consumed: Bool): Unit {
        if (released) {
            return
        }
        released = true
        let disposition = if (consumed) {
            CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED
        } else {
            CJGUI_ASYNC_MEASURE_RELEASE_ABANDONED
        }
        let _ = unsafe { CjguiAsyncMultilineMeasureRelease(handle, disposition) }
    }
}

func beginCjguiAsyncTextMetrics(value: String, style: CjguiComposableUiStyle, maximumWidth: Int64): (Int32, ?CjguiAsyncTextMetricsJob) {
    if (value.size > CJGUI_ASYNC_MEASURE_MAX_JOB_BYTES || style.fontSize <= 0.0) {
        return (CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT, None)
    }
    let width = if (maximumWidth <= 0) {
        0u32
    } else if (maximumWidth > Int64(UInt32.Max)) {
        UInt32.Max
    } else {
        UInt32(maximumWidth)
    }
    let weight = if (style.fontWeight <= 0) {
        0u32
    } else if (style.fontWeight > 1000) {
        1000u32
    } else {
        UInt32(style.fontWeight)
    }
    let cText = unsafe { LibC.mallocCString(value) }
    var handle: UInt64 = 0u64
    var status = CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT
    try (textResource = cText.asResource()) {
        unsafe {
            status = cjgui_async_composable_text_metrics_begin(textResource.value, UInt64(value.size), style.fontSize,
                weight, composableFontFamilyCode(style.fontFamily), width, inout handle)
        }
    }
    if (status != CJGUI_ASYNC_MEASURE_STARTED || handle == 0u64) {
        return (status, None)
    }
    return (status, Some(CjguiAsyncTextMetricsJob(value, style, maximumWidth, handle)))
}

class CjguiAsyncMultilineHeightJob {
    let value: String
    let style: CjguiComposableUiStyle
    let fontSize: Float64
    let fontWeight: Int64
    let fontFamily: String
    let contentWidth: Int64
    let handle: UInt64
    private var released: Bool = false

    init(value: String, style: CjguiComposableUiStyle, contentWidth: Int64, handle: UInt64) {
        this.value = value
        this.style = style
        this.fontSize = style.fontSize
        this.fontWeight = style.fontWeight
        this.fontFamily = style.fontFamily
        this.contentWidth = contentWidth
        this.handle = handle
    }

    func matches(value: String, style: CjguiComposableUiStyle, contentWidth: Int64): Bool {
        return this.value == value && this.fontSize == style.fontSize && this.fontWeight == style.fontWeight &&
            this.fontFamily == style.fontFamily && this.contentWidth == contentWidth
    }

    func poll(): (Int32, Int64, Int32) {
        if (released) {
            return (CJGUI_ASYNC_MEASURE_STALE_HANDLE, 0, 0)
        }
        var height: UInt32 = 0u32
        var failure: Int32 = 0
        let status = unsafe { CjguiAsyncMultilineMeasurePoll(handle, inout height, inout failure) }
        return (status, Int64(height), failure)
    }

    func release(consumed: Bool): Unit {
        if (released) {
            return
        }
        released = true
        let disposition = if (consumed) {
            CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED
        } else {
            CJGUI_ASYNC_MEASURE_RELEASE_ABANDONED
        }
        let _ = unsafe { CjguiAsyncMultilineMeasureRelease(handle, disposition) }
    }
}

func beginCjguiAsyncMultilineHeight(value: String, style: CjguiComposableUiStyle, contentWidth: Int64): (Int32, ?CjguiAsyncMultilineHeightJob) {
    if (value.size > CJGUI_ASYNC_MEASURE_MAX_JOB_BYTES || contentWidth <= 0 || contentWidth > Int64(UInt32.Max) ||
        style.fontSize <= 0.0) {
        return (CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT, None)
    }
    let cText = unsafe { LibC.mallocCString(value) }
    var handle: UInt64 = 0u64
    var status = CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT
    try (textResource = cText.asResource()) {
        unsafe {
            status = cjgui_async_composable_multiline_begin(textResource.value, UInt64(value.size), style.fontSize,
                UInt32(style.fontWeight), composableFontFamilyCode(style.fontFamily), UInt32(contentWidth), inout handle)
        }
    }
    if (status != CJGUI_ASYNC_MEASURE_STARTED || handle == 0u64) {
        return (status, None)
    }
    return (status, Some(CjguiAsyncMultilineHeightJob(value, style, contentWidth, handle)))
}
