// Definite-height multiline layout must avoid text intrinsic work only where
// the existing vertical allocation makes that work irrelevant. The paired
// multi-flexible-child and wrapped-fixed-width cases pin the boundaries where
// intrinsic measurement still determines observable geometry.
package cjgui

import std.collection.*

private class DefiniteMultilineTestMeasurer <: CjguiComposableUiTextMeasurer {
    public var callCount: Int64 = 0
    public let maximumWidths = ArrayList<Int64>()

    public func measure(value: String, style: CjguiComposableUiStyle,
        maximumWidth: Int64): CjguiComposableUiTextMeasurement {
        let _ = style
        callCount += 1
        maximumWidths.add(maximumWidth)
        let measuredHeight = if (value == "prior-200") {
            188
        } else if (value == "editor-100") {
            88
        } else if (value == "editor-500") {
            488
        } else if (value == "wrap-fixed-540" && maximumWidth == 526) {
            176
        } else if (value == "wrap-fixed-540") {
            64
        } else {
            let width = if (maximumWidth > 0) { maximumWidth } else { 1 }
            let units = Int64(value.size) * 8
            let lines = if (units > width) { (units + width - 1) / width } else { 1 }
            lines * 18
        }
        return CjguiComposableUiTextMeasurement(maximumWidth, measuredHeight, 18, 14)
    }
}

private class RoleAwareMultilineTestMeasurer <: CjguiComposableUiTextMeasurer &
    CjguiComposableUiMultilineNaturalHeightMeasurer {
    public var fullCalls: Int64 = 0
    public var multilineCalls: Int64 = 0
    public func measure(value: String, style: CjguiComposableUiStyle,
        maximumWidth: Int64): CjguiComposableUiTextMeasurement {
        let _ = value
        let _ = style
        fullCalls += 1
        return CjguiComposableUiTextMeasurement(maximumWidth, 20, 18, 14)
    }
    public func multilineNaturalContentHeight(value: String, style: CjguiComposableUiStyle,
        contentWidth: Int64): ?Int64 {
        let _ = value
        let _ = style
        multilineCalls += 1
        return if (contentWidth == 526) { Some(100) } else { Some(40) }
    }
}

private func definiteMultilineLayout(root: CjguiComposableUiNode, width: Int64, height: Int64,
    measurer: DefiniteMultilineTestMeasurer): CjguiComposableUiLayoutResult {
    return CjguiComposableUiLayoutEngine.layoutWithMetrics(root,
        CjguiComposableUiRect(0, 0, width, height), 1, measurer, reuseMeasurements: false)
}

private func definiteMultilineLongValue(): String {
    let builder = StringBuilder()
    var index: Int64 = 0
    while (index < 10249) {
        builder.append("0123456789")
        index += 1
    }
    return builder.toString()
}

@Test
func oversizedUnbrokenMultilineIsRejectedBeforeIntrinsicOrDefiniteLayout(): Unit {
    let value = StringBuilder()
    var index: Int64 = 0
    while (index < 13108) {
        value.append("0123456789")
        index += 1
    }
    let root = cjguiComposableVertical(100, "root", CjguiComposableUiStyle())
    root.add(cjguiComposableMultilineTextInput(101, "oversized", "Oversized", value.toString(), 101,
        CjguiComposableUiStyle(fixedWidth: 540, growY: 1)))
    let measurer = DefiniteMultilineTestMeasurer()
    let result = definiteMultilineLayout(root, 900, 600, measurer)
    @Assert(result.scene.isValid(), false)
    @Assert(result.scene.layoutError(), "text_layout_budget_exceeded")
    @Assert(measurer.callCount, 0)
}

@Test
func definiteUniqueGrowYMultilineSkipsFullValueMeasurement(): Unit {
    let root = cjguiComposableVertical(1, "root", CjguiComposableUiStyle())
    root.add(cjguiComposableMultilineTextInput(2, "document", "Document",
        definiteMultilineLongValue(), 2,
        CjguiComposableUiStyle(fixedWidth: 540, growY: 1)))
    let measurer = DefiniteMultilineTestMeasurer()
    let result = definiteMultilineLayout(root, 900, 600, measurer)
    let editor = result.scene.nodeForId(2)

    @Assert(result.scene.isValid(), true)
    @Assert(result.metrics.measurerCallCount, 0)
    @Assert(measurer.callCount, 0)
    @Assert(editor.bounds.width, 540)
    @Assert(editor.bounds.height, 600)
}

@Test
func definiteMultilinePreservesFixedSiblingsAndHeightConstraints(): Unit {
    let root = cjguiComposableVertical(10, "root", CjguiComposableUiStyle(gap: 10))
    root.add(cjguiComposableText(11, "top", "top", CjguiComposableUiStyle(fixedWidth: 80, fixedHeight: 50)))
    root.add(cjguiComposableMultilineTextInput(12, "document", "Document", "wrapped body", 12,
        CjguiComposableUiStyle(fixedWidth: 540, growY: 1, minHeight: 120, maxHeight: 260, idealHeight: 180)))
    root.add(cjguiComposableText(13, "bottom", "bottom", CjguiComposableUiStyle(fixedWidth: 80, fixedHeight: 30)))
    let measurer = DefiniteMultilineTestMeasurer()
    let exactIdeal = definiteMultilineLayout(root, 900, 280, measurer)
    @Assert(exactIdeal.metrics.measurerCallCount, 0)
    @Assert(exactIdeal.scene.nodeForId(11).bounds.y, 0)
    @Assert(exactIdeal.scene.nodeForId(11).bounds.height, 50)
    @Assert(exactIdeal.scene.nodeForId(12).bounds.y, 60)
    @Assert(exactIdeal.scene.nodeForId(12).bounds.height, 180)
    @Assert(exactIdeal.scene.nodeForId(13).bounds.y, 250)
    @Assert(exactIdeal.scene.nodeForId(13).bounds.height, 30)

    let maxCapped = definiteMultilineLayout(root, 900, 600, measurer)
    @Assert(maxCapped.metrics.measurerCallCount, 0)
    @Assert(maxCapped.scene.nodeForId(12).bounds.height, 260)
    @Assert(maxCapped.scene.nodeForId(13).bounds.y, 330)

    let minConstrained = definiteMultilineLayout(root, 900, 80, measurer)
    @Assert(minConstrained.metrics.measurerCallCount, 0)
    @Assert(minConstrained.scene.nodeForId(12).bounds.height, 120)
    @Assert(minConstrained.scene.nodeForId(13).bounds.y, 190)
}

@Test
func definiteMultilinePruningWorksAtZeroSpaceAndNestedBounds(): Unit {
    let zeroRoot = cjguiComposableVertical(20, "zero-root", CjguiComposableUiStyle())
    zeroRoot.add(cjguiComposableMultilineTextInput(21, "zero-document", "Document",
        definiteMultilineLongValue(), 21, CjguiComposableUiStyle(fixedWidth: 540, growY: 1)))
    let zeroMeasurer = DefiniteMultilineTestMeasurer()
    let zero = definiteMultilineLayout(zeroRoot, 900, 0, zeroMeasurer)
    @Assert(zero.metrics.measurerCallCount, 0)
    @Assert(zero.scene.nodeForId(21).bounds.width, 540)
    @Assert(zero.scene.nodeForId(21).bounds.height, 0)

    let outer = cjguiComposableVertical(30, "outer", CjguiComposableUiStyle())
    let panel = cjguiComposableVertical(31, "panel", CjguiComposableUiStyle(fixedWidth: 900, fixedHeight: 500))
    panel.add(cjguiComposableMultilineTextInput(32, "nested-document", "Document",
        definiteMultilineLongValue(), 32, CjguiComposableUiStyle(fixedWidth: 540, growY: 1)))
    outer.add(panel)
    let nestedMeasurer = DefiniteMultilineTestMeasurer()
    let nested = definiteMultilineLayout(outer, 900, 700, nestedMeasurer)
    @Assert(nested.scene.isValid(), true)
    @Assert(nested.metrics.measurerCallCount, 0)
    @Assert(nested.scene.nodeForId(31).bounds.height, 500)
    @Assert(nested.scene.nodeForId(32).bounds.width, 540)
    @Assert(nested.scene.nodeForId(32).bounds.height, 500)
}

@Test
func definiteMultilineMeasuresTrueAutoHeightAtResolvedChildWidth(): Unit {
    let root = cjguiComposableVertical(40, "root", CjguiComposableUiStyle())
    root.add(cjguiComposableMultilineTextInput(41, "wrapped-document", "Document", "wrap-fixed-540", 41,
        CjguiComposableUiStyle(fixedWidth: 540)))
    let measurer = DefiniteMultilineTestMeasurer()
    let result = definiteMultilineLayout(root, 900, 600, measurer)

    @Assert(result.scene.isValid(), true)
    @Assert(result.metrics.measurerCallCount, 1)
    @Assert(measurer.callCount, 1)
    @Assert(measurer.maximumWidths[0], 526)
    @Assert(result.scene.nodeForId(41).bounds.width, 540)
    @Assert(result.scene.nodeForId(41).bounds.height, 188)
}

@Test
func nestedAutoHeightUsesResolvedFixedChildWidth(): Unit {
    let root = cjguiComposableVertical(42, "root", CjguiComposableUiStyle())
    let panel = cjguiComposableVertical(43, "panel", CjguiComposableUiStyle(fixedWidth: 600, padding: 20))
    panel.add(cjguiComposableMultilineTextInput(44, "wrapped-document", "Document", "wrap-fixed-540", 44,
        CjguiComposableUiStyle(fixedWidth: 540)))
    root.add(panel)
    let measurer = DefiniteMultilineTestMeasurer()
    let result = definiteMultilineLayout(root, 900, 600, measurer)

    @Assert(result.scene.isValid(), true)
    @Assert(measurer.callCount, 2)
    @Assert(measurer.maximumWidths[0], 526)
    @Assert(measurer.maximumWidths[1], 526)
    @Assert(result.scene.nodeForId(43).bounds.width, 600)
    @Assert(result.scene.nodeForId(43).bounds.height, 228)
    @Assert(result.scene.nodeForId(44).bounds.height, 188)
}

@Test
func multilineNaturalHeightKeepsRoleQuerySeparateFromFullTextMetrics(): Unit {
    let root = cjguiComposableVertical(45, "root", CjguiComposableUiStyle())
    let style = CjguiComposableUiStyle(fixedWidth: 540)
    root.add(cjguiComposableText(46, "same-value", "same-value", style))
    root.add(cjguiComposableMultilineTextInput(47, "same-value", "Document", "same-value", 47, style))
    root.add(cjguiComposableMultilineTextInput(48, "same-value", "Document", "same-value", 48, style))
    let measurer = RoleAwareMultilineTestMeasurer()
    let result = CjguiComposableUiLayoutEngine.layoutWithMetrics(root,
        CjguiComposableUiRect(0, 0, 900, 600), 1, measurer)

    @Assert(result.scene.isValid(), true)
    @Assert(result.scene.nodeForId(46).bounds.height, 24)
    @Assert(result.scene.nodeForId(47).bounds.height, 112)
    @Assert(result.scene.nodeForId(48).bounds.height, 112)
    @Assert(measurer.fullCalls, 1)
    @Assert(measurer.multilineCalls, 1)
}

private func nonFixedSiblingEditorHeight(editorValue: String): Int64 {
    let root = cjguiComposableVertical(50, "root", CjguiComposableUiStyle())
    root.add(cjguiComposableMultilineTextInput(51, "prior", "Prior", "prior-200", 51,
        CjguiComposableUiStyle(fixedWidth: 540)))
    root.add(cjguiComposableMultilineTextInput(52, "editor", "Editor", editorValue, 52,
        CjguiComposableUiStyle(fixedWidth: 540, growY: 1)))
    let measurer = DefiniteMultilineTestMeasurer()
    let result = definiteMultilineLayout(root, 900, 300, measurer)
    @Assert(result.scene.isValid(), true)
    @Assert(result.metrics.measurerCallCount, 2)
    return result.scene.nodeForId(52).bounds.height
}

@Test
func laterGrowingEditorStillDependsOnEarlierFlexibleSiblingIntrinsicHeight(): Unit {
    // Both siblings are non-fixed. The first has no growth; changing its
    // intrinsic height changes how the existing shrink/grow sequence allocates
    // the editor. The definite-bounds shortcut must not generalize across it.
    @Assert(nonFixedSiblingEditorHeight("editor-100"), 100)
    @Assert(nonFixedSiblingEditorHeight("editor-500"), 300)
}
