package cjgui

// Narrow Mac measurement adapter. Other backends keep their existing entries
// until their native layout consumes the already-shared typography fields.
foreign {
    @When[os == "macOS" || os == "Linux"]
    func cjgui_internal_renderer_measure_composable_styled_text(session: UInt64, text: CString,
        fontSize: Float64, weight: UInt32, family: UInt32, width: UInt32, spacing: Float64,
        height: Float64, maximumLines: UInt32, overflow: UInt32, runs: CString,
        output: CPointer<CjguiInternalRendererTextMeasurement>): Int32
    @When[os == "macOS"]
    func cjgui_async_composable_styled_text_begin(text: CString, byteLength: UInt64,
        fontSize: Float64, weight: UInt32, family: UInt32, width: UInt32, spacing: Float64,
        height: Float64, maximumLines: UInt32, overflow: UInt32, runs: CString, output: CPointer<UInt64>): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_measure_composable_text_typography(session: UInt64, text: CString,
        fontSize: Float64, fontWeight: UInt32, fontFamily: UInt32, width: UInt32,
        letterSpacing: Float64, lineHeight: Float64, output: CPointer<CjguiInternalRendererTextMeasurement>): Int32
    @When[os == "macOS"]
    func cjgui_internal_renderer_measure_composable_multiline_natural_height_typography(session: UInt64,
        text: CString, fontSize: Float64, fontWeight: UInt32, fontFamily: UInt32, width: UInt32,
        letterSpacing: Float64, lineHeight: Float64, output: CPointer<UInt32>): Int32
    @When[os == "macOS"]
    func cjgui_async_composable_text_metrics_typography_begin(text: CString, byteLength: UInt64,
        fontSize: Float64, fontWeight: UInt32, family: UInt32, width: UInt32,
        spacing: Float64, height: Float64, output: CPointer<UInt64>): Int32
    @When[os == "macOS"]
    func cjgui_async_composable_multiline_typography_begin(text: CString, byteLength: UInt64,
        fontSize: Float64, fontWeight: UInt32, family: UInt32, width: UInt32,
        spacing: Float64, height: Float64, output: CPointer<UInt64>): Int32
}

@When[os == "macOS" || os == "Linux"]
public func cjguiStyledTextSupportVersion(): Int64 { return 1 }
@When[os != "macOS" && os != "Linux"]
public func cjguiStyledTextSupportVersion(): Int64 { return 0 }

@When[os == "macOS"]
func cjguiMeasureStyledTypography(session: UInt64, text: CString, runs: CString,
    style: CjguiComposableUiStyle, width: UInt32): (Int32, UInt32, UInt32, UInt32, UInt32) {
    var output = CjguiInternalRendererTextMeasurement()
    let status = unsafe { cjgui_internal_renderer_measure_composable_styled_text(session, text,
        style.fontSize, UInt32(if (style.fontWeight > 1000) { 1000 } else { style.fontWeight }), composableFontFamilyCode(style.fontFamily), width,
        style.letterSpacing, style.lineHeight, UInt32(style.textMaxLines),
        if (style.textOverflow == "ellipsis") { 1u32 } else { 0u32 }, runs, inout output) }
    return (status, output.width, output.height, output.lineHeight, output.baseline)
}
// Linux consumes the same 14-field declaration through the platform's
// FreeType/HarfBuzz/Fontconfig layout. The measurement is produced by the same
// native function the paint path calls, so max-lines/ellipsis and baselines are
// not a second approximation.
@When[os == "Linux"]
func cjguiMeasureStyledTypography(session: UInt64, text: CString, runs: CString,
    style: CjguiComposableUiStyle, width: UInt32): (Int32, UInt32, UInt32, UInt32, UInt32) {
    var output = CjguiInternalRendererTextMeasurement()
    let status = unsafe { cjgui_internal_renderer_measure_composable_styled_text(session, text,
        style.fontSize, UInt32(if (style.fontWeight > 1000) { 1000 } else { style.fontWeight }), composableFontFamilyCode(style.fontFamily), width,
        style.letterSpacing, style.lineHeight, UInt32(style.textMaxLines),
        if (style.textOverflow == "ellipsis") { 1u32 } else { 0u32 }, runs, inout output) }
    return (status, output.width, output.height, output.lineHeight, output.baseline)
}
@When[os != "macOS" && os != "Linux"]
func cjguiMeasureStyledTypography(session: UInt64, text: CString, runs: CString,
    style: CjguiComposableUiStyle, width: UInt32): (Int32, UInt32, UInt32, UInt32, UInt32) {
    return (CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED, 0u32, 0u32, 0u32, 0u32)
}

@When[os == "macOS"]
func cjguiBeginAsyncStyledTypography(text: CString, byteLength: UInt64, runs: CString,
    style: CjguiComposableUiStyle, width: UInt32): (Int32, UInt64) {
    var output = 0u64
    let status = unsafe { cjgui_async_composable_styled_text_begin(text, byteLength,
        style.fontSize, UInt32(if (style.fontWeight > 1000) { 1000 } else { style.fontWeight }), composableFontFamilyCode(style.fontFamily), width,
        style.letterSpacing, style.lineHeight, UInt32(style.textMaxLines),
        if (style.textOverflow == "ellipsis") { 1u32 } else { 0u32 }, runs, inout output) }
    return (status, output)
}
@When[os != "macOS"]
func cjguiBeginAsyncStyledTypography(text: CString, byteLength: UInt64, runs: CString,
    style: CjguiComposableUiStyle, width: UInt32): (Int32, UInt64) {
    return (CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT, 0u64)
}

@When[os == "macOS"]
func cjguiMeasureTextTypography(session: UInt64, text: CString, fontSize: Float64, fontWeight: UInt32, family: UInt32, width: UInt32, spacing: Float64, height: Float64): (Int32, UInt32, UInt32, UInt32, UInt32) {
    var output: CjguiInternalRendererTextMeasurement = CjguiInternalRendererTextMeasurement()
    let status = unsafe { cjgui_internal_renderer_measure_composable_text_typography(session, text, fontSize, fontWeight, family, width, spacing, height, inout output) }
    return (status, output.width, output.height, output.lineHeight, output.baseline)
}

@When[os != "macOS"]
func cjguiMeasureTextTypography(session: UInt64, text: CString, fontSize: Float64, fontWeight: UInt32, family: UInt32, width: UInt32, spacing: Float64, height: Float64): (Int32, UInt32, UInt32, UInt32, UInt32) {
    var output: CjguiInternalRendererTextMeasurement = CjguiInternalRendererTextMeasurement()
    let status = unsafe { cjgui_internal_renderer_measure_composable_text(session, text, fontSize, fontWeight, family, width, inout output) }
    return (status, output.width, output.height, output.lineHeight, output.baseline)
}

@When[os == "macOS"]
func cjguiMeasureMultilineTypography(session: UInt64, text: CString, fontSize: Float64, fontWeight: UInt32, family: UInt32, width: UInt32, spacing: Float64, height: Float64): (Int32, UInt32) {
    var output: UInt32 = 0u32
    let status = unsafe { cjgui_internal_renderer_measure_composable_multiline_natural_height_typography(session, text, fontSize, fontWeight, family, width, spacing, height, inout output) }
    return (status, output)
}

@When[os != "macOS"]
func cjguiMeasureMultilineTypography(session: UInt64, text: CString, fontSize: Float64, fontWeight: UInt32, family: UInt32, width: UInt32, spacing: Float64, height: Float64): (Int32, UInt32) {
    var output: UInt32 = 0u32
    let status = unsafe { cjgui_internal_renderer_measure_composable_multiline_natural_height(session, text, fontSize, fontWeight, family, width, inout output) }
    return (status, output)
}

@When[os == "macOS"]
func cjguiBeginAsyncTextTypography(text: CString, byteLength: UInt64, fontSize: Float64, fontWeight: UInt32, family: UInt32, width: UInt32, spacing: Float64, height: Float64): (Int32, UInt64) {
    var output: UInt64 = 0u64
    let status = unsafe { cjgui_async_composable_text_metrics_typography_begin(text, byteLength, fontSize, fontWeight, family, width, spacing, height, inout output) }
    return (status, output)
}

@When[os != "macOS"]
func cjguiBeginAsyncTextTypography(text: CString, byteLength: UInt64, fontSize: Float64, fontWeight: UInt32, family: UInt32, width: UInt32, spacing: Float64, height: Float64): (Int32, UInt64) {
    var output: UInt64 = 0u64
    let status = unsafe { cjgui_async_composable_text_metrics_begin(text, byteLength, fontSize, fontWeight, family, width, inout output) }
    return (status, output)
}

@When[os == "macOS"]
func cjguiBeginAsyncMultilineTypography(text: CString, byteLength: UInt64, fontSize: Float64, fontWeight: UInt32, family: UInt32, width: UInt32, spacing: Float64, height: Float64): (Int32, UInt64) {
    var output: UInt64 = 0u64
    let status = unsafe { cjgui_async_composable_multiline_typography_begin(text, byteLength, fontSize, fontWeight, family, width, spacing, height, inout output) }
    return (status, output)
}

@When[os != "macOS"]
func cjguiBeginAsyncMultilineTypography(text: CString, byteLength: UInt64, fontSize: Float64, fontWeight: UInt32, family: UInt32, width: UInt32, spacing: Float64, height: Float64): (Int32, UInt64) {
    var output: UInt64 = 0u64
    let status = unsafe { cjgui_async_composable_multiline_begin(text, byteLength, fontSize, fontWeight, family, width, inout output) }
    return (status, output)
}
