package cjgui

@Test
func typographyNamedOverridesAndPaintPreserveLayoutFacts(): Unit {
    let named = CjguiComposableUiNamedStyle("body", CjguiComposableUiStyle(
        fontSize: 16.0, letterSpacing: 1.25, lineHeight: 32.5))
    let inherited = named.boundStyle(fontSize: Some(18.0)).style
    @Assert(inherited.letterSpacing, 1.25)
    @Assert(inherited.lineHeight, 32.5)
    let cleared = named.localStyle(letterSpacing: Some(0.0), lineHeight: Some(0.0))
    @Assert(cleared.letterSpacing, 0.0)
    @Assert(cleared.lineHeight, 0.0)
    let paint = cjguiComposableUiPaintOverlay(inherited, CjguiComposableUiStyle(
        textColor: CjguiComposableUiColor(1.0, 0.0, 0.0, 1.0)))
    @Assert(paint.letterSpacing, 1.25)
    @Assert(paint.lineHeight, 32.5)
    @Assert(cjguiComposableUiParseTypographyScalar("-0.75", false), Some(-0.75))
    @Assert(cjguiComposableUiParseTypographyScalar("32.5", true), Some(32.5))
    for (token in ["NaN", "inf", "1000", "1e2", " 2", "1.2345"]) {
        @Assert(cjguiComposableUiParseTypographyScalar(token, true).isNone(), true)
    }
    @Assert(cjguiComposableUiParseTypographyScalar("-1", true).isNone(), true)
    @Assert(cjguiComposableUiParseTypographyScalar("", true), Some(0.0))
}

@Test
func typographyPendingMeasurementRejectsOldStyleIdentity(): Unit {
    let original = CjguiComposableUiStyle(fontSize: 16.0, letterSpacing: 1.25, lineHeight: 32.5)
    let text = CjguiAsyncTextMetricsJob("中文 é 👩🏽‍💻", original, 200, 0u64)
    let multi = CjguiAsyncMultilineHeightJob("中文\n👩🏽‍💻", original, 200, 0u64)
    @Assert(text.matches("中文 é 👩🏽‍💻", original, 200), true)
    @Assert(multi.matches("中文\n👩🏽‍💻", original, 200), true)
    for (changed in [CjguiComposableUiStyle(fontSize: 16.0, letterSpacing: 2.0, lineHeight: 32.5),
        CjguiComposableUiStyle(fontSize: 16.0, letterSpacing: 1.25, lineHeight: 28.0),
        CjguiComposableUiStyle(fontSize: 16.0)]) {
        @Assert(text.matches("中文 é 👩🏽‍💻", changed, 200), false)
        @Assert(multi.matches("中文\n👩🏽‍💻", changed, 200), false)
    }
}
