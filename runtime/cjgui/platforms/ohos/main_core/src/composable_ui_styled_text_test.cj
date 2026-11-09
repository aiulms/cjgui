package cjgui

private class StyledMetricsTransportProbe <: CjguiComposableUiTextMeasurer & CjguiComposableUiStyledTextMeasurer {
    var styledCalls: Int64 = 0
    let plain = CjguiComposableUiFallbackTextMeasurer()
    public func measure(value: String, style: CjguiComposableUiStyle, width: Int64): CjguiComposableUiTextMeasurement {
        return plain.measure(value, style, width)
    }
    public func measureStyled(value: String, style: CjguiComposableUiStyle,
        runs: Array<CjguiComposableUiTextStyleRun>, width: Int64): CjguiComposableUiTextMeasurement {
        styledCalls += 1
        // Marker metrics verify transport, not a second text shaping oracle.
        return CjguiComposableUiTextMeasurement(120, 83, 43, 35)
    }
}

private func styledProbeTree(): CjguiComposableUiNode {
    let root = cjguiComposableVertical(9000, "styled-root", CjguiComposableUiStyle(growX: 1))
    root.add(cjguiComposableText(9001, "styled-description", "BIG 中文 👩🏽‍💻",
        CjguiComposableUiStyle(fontSize: 14.0, growX: 1),
        textStyleRuns: [CjguiComposableUiTextStyleRun(0, 3, 36.0, 0, "monospace", 1.0, 0.0, 0.0, 1.0)]))
    root.add(cjguiComposableButton(9002, "following-normal-control", "继续", "NEXT", 1,
        CjguiComposableUiStyle(fixedHeight: 32)))
    return root
}

@Test
func styledTextAutoHeightUsesAttributedMetricsAndClearsFollowingControl(): Unit {
    let probe = StyledMetricsTransportProbe()
    let result = CjguiComposableUiLayoutEngine.layoutWithMetrics(styledProbeTree(),
        CjguiComposableUiRect(0, 0, 200, 400), 1, probe)
    @Assert(result.scene.isValid(), true)
    let text = result.scene.nodeForId(9001)
    let next = result.scene.nodeForId(9002)
    @Assert(text.bounds.height, 87)
    @Assert(next.bounds.y >= text.bounds.y + text.bounds.height, true)
    @Assert(probe.styledCalls > 0, true)
}

@Test
func styledTextCustomMeasurerUnsupportedIsExplicitAndPlainCompatibilityRemains(): Unit {
    let plain = CjguiComposableUiFallbackTextMeasurer()
    let refused = CjguiComposableUiLayoutEngine.layoutWithMetrics(styledProbeTree(),
        CjguiComposableUiRect(0, 0, 200, 400), 1, plain)
    @Assert(refused.scene.isValid(), false)
    @Assert(refused.scene.layoutError(), "styled_text_measurer_unsupported")
    let node = cjguiComposableText(1, "plain", "旧消费者", CjguiComposableUiStyle())
    let accepted = CjguiComposableUiLayoutEngine.layoutWithMetrics(node,
        CjguiComposableUiRect(0, 0, 200, 400), 1, plain)
    @Assert(accepted.scene.isValid(), true)
}

@Test
func styledTextGeometryIdentityIgnoresPaintButKeepsFontRangeAndLimit(): Unit {
    let style = CjguiComposableUiStyle(fontSize: 14.0)
    let a = [CjguiComposableUiTextStyleRun(0, 3, 36.0, 0, "system", 1.0, 0.0, 0.0, 1.0)]
    let b = [CjguiComposableUiTextStyleRun(0, 3, 36.0, 0, "system", 0.0, 1.0, 0.0, 1.0)]
    let c = [CjguiComposableUiTextStyleRun(0, 3, 42.0, 0, "system", 0.0, 1.0, 0.0, 1.0)]
    @Assert(cjguiTextRunsGeometryKey(style, a), cjguiTextRunsGeometryKey(style, b))
    @Assert(cjguiTextRunsGeometryKey(style, a) == cjguiTextRunsGeometryKey(style, c), false)
    @Assert(cjguiTextRunsGeometryKey(style, a) == cjguiTextRunsGeometryKey(
        CjguiComposableUiStyle(fontSize: 14.0, textMaxLines: 2), a), false)
    let bad = [CjguiComposableUiTextStyleRun(1, 3, 14.0, 0, "system", 0.0, 0.0, 0.0, 1.0)]
    @Assert(cjguiOrdinaryTextRunsRejection("中", bad).isSome(), true)
}
