// Focused contracts for the shared layout primitives. These use only public
// CJGUI builders and the canonical layout engine; no product coordinates are
// hand-computed in an application.
package cjgui_rule_set_window_app

import cjgui.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private func layoutPrimitiveScene(root: CjguiComposableUiNode, width: Int64, height: Int64,
    version: Int64): CjguiComposableUiScene {
    return CjguiComposableUiLayoutEngine.layoutWithMetrics(root, CjguiComposableUiRect(0, 0, width, height), version,
        CjguiComposableUiFallbackTextMeasurer()).scene
}

@Test
func wrapMeasuresRowsAndReflowsFromActualWidth(): Unit {
    let root = cjguiComposableVertical(1000, "wrap-root", CjguiComposableUiStyle(growX: 1, growY: 1))
    let wrap = cjguiComposableWrap(1001, "wrap", CjguiComposableUiStyle(gap: 10), rowGap: 12)
    wrap.add(cjguiComposableText(1002, "wrap-a", "A", CjguiComposableUiStyle(fixedWidth: 80, fixedHeight: 20)))
    wrap.add(cjguiComposableText(1003, "wrap-b", "B", CjguiComposableUiStyle(fixedWidth: 80, fixedHeight: 30)))
    wrap.add(cjguiComposableButton(1004, "wrap-c", "C", "WRAP_C", -1,
        CjguiComposableUiStyle(fixedWidth: 80, fixedHeight: 25)))
    root.add(wrap)

    let narrow = layoutPrimitiveScene(root, 200, 200, 1)
    @Assert(narrow.layoutError(), "")
    let narrowWrap = narrow.nodeForId(1001)
    @Assert(narrowWrap.bounds.width, 200)
    @Assert(narrowWrap.bounds.height, 67)
    @Assert(narrow.nodeForId(1002).bounds.x, 0)
    @Assert(narrow.nodeForId(1003).bounds.x, 90)
    @Assert(narrow.nodeForId(1004).bounds.y, 42)
    @Assert(narrow.nodeForId(1004).bounds.x, 0)

    let wide = layoutPrimitiveScene(root, 300, 200, 2)
    @Assert(wide.layoutError(), "")
    @Assert(wide.nodeForId(1001).bounds.height, 30)
    @Assert(wide.nodeForId(1004).bounds.x, 180)
    @Assert(wide.nodeForId(1004).bounds.y, 0)

    // An item wider than the available row is clamped once, not measured in a
    // retry loop: the row stays one line at the container width.
    let oversizedRoot = cjguiComposableVertical(1010, "wrap-oversized-root",
        CjguiComposableUiStyle(growX: 1))
    let oversized = cjguiComposableWrap(1011, "wrap-oversized",
        CjguiComposableUiStyle(fixedWidth: 200), rowGap: 0)
    oversized.add(cjguiComposableText(1012, "wrap-oversized-item", "wide",
        CjguiComposableUiStyle(fixedWidth: 400, fixedHeight: 20)))
    oversizedRoot.add(oversized)
    let oversizedScene = layoutPrimitiveScene(oversizedRoot, 200, 100, 3)
    @Assert(oversizedScene.layoutError(), "")
    @Assert(oversizedScene.nodeForId(1011).bounds.height, 20)
    @Assert(oversizedScene.nodeForId(1012).bounds.width, 200)

    let mixedRoot = cjguiComposableVertical(1020, "wrap-mixed-root", CjguiComposableUiStyle(growX: 1))
    let mixed = cjguiComposableWrap(1021, "wrap-mixed", CjguiComposableUiStyle(fixedWidth: 200, gap: 10))
    mixed.add(cjguiComposableText(1022, "wrap-mixed-a", "A", CjguiComposableUiStyle(fixedWidth: 60,
        fixedHeight: 20)))
    mixed.add(cjguiComposableButton(1023, "wrap-mixed-b", "B", "WRAP_MIXED_B", -1,
        CjguiComposableUiStyle(fixedWidth: 120, fixedHeight: 20)))
    mixed.add(cjguiComposableText(1024, "wrap-mixed-c", "C", CjguiComposableUiStyle(fixedWidth: 40,
        fixedHeight: 20)))
    mixedRoot.add(mixed)
    let mixedScene = layoutPrimitiveScene(mixedRoot, 200, 100, 4)
    @Assert(mixedScene.layoutError(), "")
    @Assert(mixedScene.nodeForId(1023).bounds.x, 70)
    @Assert(mixedScene.nodeForId(1024).bounds.x, 0)
    @Assert(mixedScene.nodeForId(1024).bounds.y, 30)
    @Assert(mixedScene.nodeForId(1021).bounds.height, 50)
}

@Test
func aspectRatioHonorsParentExtentsAndRejectsInvalidRatio(): Unit {
    let root = cjguiComposableVertical(1100, "aspect-root", CjguiComposableUiStyle(growX: 1))
    let frame = cjguiComposableAspectRatio(1101, "aspect", 16, 9,
        CjguiComposableUiStyle(fixedWidth: 160))
    frame.add(cjguiComposableText(1102, "aspect-content", "16:9", CjguiComposableUiStyle()))
    root.add(frame)
    let scene = layoutPrimitiveScene(root, 200, 300, 1)
    @Assert(scene.layoutError(), "")
    @Assert(scene.nodeForId(1101).bounds.width, 160)
    @Assert(scene.nodeForId(1101).bounds.height, 90)
    @Assert(scene.nodeForId(1102).bounds.width, 160)
    @Assert(scene.nodeForId(1102).bounds.height, 90)

    let constrainedRoot = cjguiComposableVertical(1110, "aspect-constrained-root",
        CjguiComposableUiStyle(growX: 1))
    let constrained = cjguiComposableAspectRatio(1111, "aspect-constrained", 16, 9,
        CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 60))
    constrained.add(cjguiComposableText(1112, "aspect-constrained-content", "constrained",
        CjguiComposableUiStyle()))
    constrainedRoot.add(constrained)
    let constrainedScene = layoutPrimitiveScene(constrainedRoot, 300, 300, 2)
    @Assert(constrainedScene.layoutError(), "")
    @Assert(constrainedScene.nodeForId(1111).bounds.width, 200)
    @Assert(constrainedScene.nodeForId(1111).bounds.height, 60)
    @Assert(constrainedScene.nodeForId(1112).bounds.width, 106)
    @Assert(constrainedScene.nodeForId(1112).bounds.height, 60)

    // No usable parent extent: the ratio content is 0x0 rather than being
    // reported as a successful arbitrary size.
    let unconstrained = cjguiComposableAspectRatio(1115, "aspect-unconstrained", 16, 9,
        CjguiComposableUiStyle())
    unconstrained.add(cjguiComposableText(1116, "aspect-unconstrained-content", "none",
        CjguiComposableUiStyle()))
    let unconstrainedScene = layoutPrimitiveScene(unconstrained, 0, 0, 3)
    @Assert(unconstrainedScene.layoutError(), "")
    @Assert(unconstrainedScene.nodeForId(1115).bounds.width, 0)
    @Assert(unconstrainedScene.nodeForId(1115).bounds.height, 0)
    @Assert(unconstrainedScene.nodeForId(1116).bounds.width, 0)
    @Assert(unconstrainedScene.nodeForId(1116).bounds.height, 0)

    let invalidRoot = cjguiComposableVertical(1120, "aspect-invalid-root",
        CjguiComposableUiStyle(growX: 1))
    let invalid = cjguiComposableAspectRatio(1121, "aspect-invalid", 0, 9,
        CjguiComposableUiStyle(fixedWidth: 120))
    invalid.add(cjguiComposableText(1122, "aspect-invalid-content", "invalid", CjguiComposableUiStyle()))
    invalidRoot.add(invalid)
    let invalidScene = layoutPrimitiveScene(invalidRoot, 200, 200, 3)
    @Assert(invalidScene.isValid(), false)
    @Assert(invalidScene.layoutError(), "invalid_aspect_ratio")
}

@Test
func stackSharesGeometryAndKeepsPaintHitAndClipOrder(): Unit {
    let root = cjguiComposableStack(1200, "stack", CjguiComposableUiStyle(fixedWidth: 100, fixedHeight: 100,
        clipsContent: true))
    root.add(cjguiComposableButton(1201, "stack-base", "Base", "BASE", -1,
        CjguiComposableUiStyle(fixedWidth: 100, fixedHeight: 100)))
    root.add(cjguiComposableButton(1202, "stack-badge", "Badge", "BADGE", -1,
        CjguiComposableUiStyle(fixedWidth: 30, fixedHeight: 20, offsetX: 20,
            alignX: CJGUI_COMPOSABLE_UI_ALIGN_END, zIndex: 10)))
    let scene = layoutPrimitiveScene(root, 100, 100, 1)
    @Assert(scene.layoutError(), "")
    @Assert(scene.nodeForId(1201).bounds.width, 100)
    @Assert(scene.nodeForId(1201).bounds.height, 100)
    @Assert(scene.nodeForId(1202).bounds.x, 90)
    @Assert(scene.nodeForId(1202).bounds.y, 0)
    @Assert(scene.nodeForId(1202).containsResolvedClip(105, 10), false)
    @Assert(scene.hitTest(90, 10).nodeId, 1202)
    @Assert(scene.hitTest(20, 50).nodeId, 1201)
    @Assert(scene.hitTest(105, 10).nodeId, -1)
    var baseIndex: Int64 = -1
    var badgeIndex: Int64 = -1
    let nodes = scene.nodes()
    var index: Int64 = 0
    while (index < nodes.size) {
        if (nodes[index].nodeId == 1201) { baseIndex = index }
        if (nodes[index].nodeId == 1202) { badgeIndex = index }
        index += 1
    }
    @Assert(baseIndex >= 0, true)
    @Assert(badgeIndex > baseIndex, true)

    // Padding is part of the advertised stack vocabulary and really insets the
    // shared content rect.
    let padded = cjguiComposableStack(1210, "stack-padded", CjguiComposableUiStyle(fixedWidth: 100,
        fixedHeight: 100, padding: 10))
    padded.add(cjguiComposableButton(1211, "stack-padded-child", "P", "PADDED", -1,
        CjguiComposableUiStyle(fixedWidth: 20, fixedHeight: 20, alignX: CJGUI_COMPOSABLE_UI_ALIGN_START,
            alignY: CJGUI_COMPOSABLE_UI_ALIGN_START)))
    let paddedScene = layoutPrimitiveScene(padded, 100, 100, 2)
    @Assert(paddedScene.layoutError(), "")
    @Assert(paddedScene.nodeForId(1211).bounds.x, 10)
    @Assert(paddedScene.nodeForId(1211).bounds.y, 10)
    @Assert(paddedScene.nodeForId(1211).bounds.width, 20)
}

private func layoutSpecWrapRoot(rowGap: Int64): CjguiComposableUiNode {
    let root = cjguiComposableVertical(1400, "layout-spec-wrap-root", CjguiComposableUiStyle())
    let region = cjguiComposableWrap(1401, "layout-spec-wrap-region",
        CjguiComposableUiStyle(fixedWidth: 240, gap: 0), rowGap: rowGap,
        layoutReuseKey: "layout-spec-wrap-v1")
    region.add(cjguiComposableText(1402, "layout-spec-wrap-a", "A",
        CjguiComposableUiStyle(fixedWidth: 100, fixedHeight: 20)))
    region.add(cjguiComposableText(1403, "layout-spec-wrap-b", "B",
        CjguiComposableUiStyle(fixedWidth: 100, fixedHeight: 20)))
    region.add(cjguiComposableText(1404, "layout-spec-wrap-c", "C",
        CjguiComposableUiStyle(fixedWidth: 100, fixedHeight: 20)))
    root.add(region)
    return root
}

private func layoutSpecAspectRoot(aspectWidth: Int64, aspectHeight: Int64): CjguiComposableUiNode {
    let root = cjguiComposableVertical(1410, "layout-spec-aspect-root", CjguiComposableUiStyle())
    let region = cjguiComposableAspectRatio(1411, "layout-spec-aspect-region", aspectWidth, aspectHeight,
        CjguiComposableUiStyle(fixedWidth: 160), layoutReuseKey: "layout-spec-aspect-v1")
    region.add(cjguiComposableText(1412, "layout-spec-aspect-content", "ratio",
        CjguiComposableUiStyle()))
    root.add(region)
    return root
}

/// Same accepted keyed region, only the layout declaration changes: the cache
/// must not replay the previous wrap height or aspect geometry.
@Test
func layoutSpecChangesInvalidateKeyedReplay(): Unit {
    let measurer = CjguiComposableUiFallbackTextMeasurer()
    let wrapViewport = CjguiComposableUiRect(0, 0, 240, 200)
    let wrapCache = CjguiComposableUiLayoutReuseCache()
    let wrapFirst = CjguiComposableUiLayoutEngine.layoutWithMetrics(layoutSpecWrapRoot(0), wrapViewport, 1,
        measurer, reuseCache: wrapCache)
    @Assert(wrapFirst.scene.isValid())
    @Assert(wrapFirst.scene.nodeForId(1401).bounds.height, 40)
    let wrapRepeated = CjguiComposableUiLayoutEngine.layoutWithMetrics(layoutSpecWrapRoot(0), wrapViewport, 2,
        measurer, reuseCache: wrapCache)
    @Assert(wrapRepeated.metrics.subtreeReuseReplayedNodeCount > 0)
    let wrapChanged = CjguiComposableUiLayoutEngine.layoutWithMetrics(layoutSpecWrapRoot(12), wrapViewport, 3,
        measurer, reuseCache: wrapCache)
    @Assert(wrapChanged.scene.nodeForId(1401).bounds.height, 52)
    @Assert(wrapChanged.metrics.subtreeReuseReplayedNodeCount, 0)

    let aspectViewport = CjguiComposableUiRect(0, 0, 200, 200)
    let aspectCache = CjguiComposableUiLayoutReuseCache()
    let aspectFirst = CjguiComposableUiLayoutEngine.layoutWithMetrics(layoutSpecAspectRoot(4, 3), aspectViewport,
        1, measurer, reuseCache: aspectCache)
    @Assert(aspectFirst.scene.nodeForId(1411).bounds.height, 120)
    let aspectRepeated = CjguiComposableUiLayoutEngine.layoutWithMetrics(layoutSpecAspectRoot(4, 3), aspectViewport,
        2, measurer, reuseCache: aspectCache)
    @Assert(aspectRepeated.metrics.subtreeReuseReplayedNodeCount > 0)
    let aspectChanged = CjguiComposableUiLayoutEngine.layoutWithMetrics(layoutSpecAspectRoot(16, 9), aspectViewport,
        3, measurer, reuseCache: aspectCache)
    @Assert(aspectChanged.scene.nodeForId(1411).bounds.height, 90)
    @Assert(aspectChanged.scene.nodeForId(1412).bounds.width, 160)
    @Assert(aspectChanged.scene.nodeForId(1412).bounds.height, 90)
    @Assert(aspectChanged.metrics.subtreeReuseReplayedNodeCount, 0)
}

/// Stack must measure each child after stretch/parent clamping resolved its
/// ACTUAL width. Measuring at the preferred width would under-report wrapped
/// text or a stacked ratio child before placement uses the wider rect.
@Test
func stackMeasuresChildrenAtAllocatedWidth(): Unit {
    let textRoot = cjguiComposableVertical(1420, "stack-width-text-root", CjguiComposableUiStyle())
    let textStack = cjguiComposableStack(1421, "stack-width-text",
        CjguiComposableUiStyle(fixedWidth: 80, clipsContent: true))
    textStack.add(cjguiComposableText(1422, "stack-width-text-content", "abcdefghijklmnopqrst",
        CjguiComposableUiStyle(fontSize: 13.0, alignX: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH,
            alignY: CJGUI_COMPOSABLE_UI_ALIGN_START)))
    textRoot.add(textStack)
    let textScene = layoutPrimitiveScene(textRoot, 200, 300, 1)
    @Assert(textScene.layoutError(), "")
    let wrappedText = textScene.nodeForId(1422)
    @Assert(wrappedText.bounds.width, 80)
    @Assert(wrappedText.bounds.height > 20, true)
    @Assert(wrappedText.bounds.height, textScene.nodeForId(1421).bounds.height)

    let aspectRoot = cjguiComposableVertical(1430, "stack-width-aspect-root", CjguiComposableUiStyle())
    let aspectStack = cjguiComposableStack(1431, "stack-width-aspect",
        CjguiComposableUiStyle(fixedWidth: 160, clipsContent: true))
    let frame = cjguiComposableAspectRatio(1432, "stack-width-aspect-frame", 16, 9,
        CjguiComposableUiStyle(alignX: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH))
    frame.add(cjguiComposableText(1433, "stack-width-aspect-content", "frame",
        CjguiComposableUiStyle(fixedWidth: 80, fixedHeight: 45)))
    aspectStack.add(frame)
    aspectRoot.add(aspectStack)
    let aspectScene = layoutPrimitiveScene(aspectRoot, 300, 300, 2)
    @Assert(aspectScene.layoutError(), "")
    let measuredFrame = aspectScene.nodeForId(1432)
    @Assert(measuredFrame.bounds.width, 160)
    @Assert(measuredFrame.bounds.height, 90)
    @Assert(measuredFrame.bounds.height, aspectScene.nodeForId(1431).bounds.height)
}

@Test
func spacerUsesExistingVerticalGrowth(): Unit {
    let column = cjguiComposableVertical(1350, "spacer-column", CjguiComposableUiStyle(fixedWidth: 40,
        fixedHeight: 300, gap: 10))
    column.add(cjguiComposableText(1351, "spacer-top", "Top", CjguiComposableUiStyle(fixedHeight: 50)))
    column.add(cjguiComposableSpacer(1352, "spacer-vertical", axis: CjguiComposableUiSplitAxis.VERTICAL))
    column.add(cjguiComposableText(1353, "spacer-bottom", "Bottom", CjguiComposableUiStyle(fixedHeight: 50)))
    let scene = layoutPrimitiveScene(column, 40, 300, 1)
    @Assert(scene.layoutError(), "")
    @Assert(scene.nodeForId(1351).bounds.y, 0)
    @Assert(scene.nodeForId(1352).bounds.y, 60)
    @Assert(scene.nodeForId(1352).bounds.height, 180)
    @Assert(scene.nodeForId(1353).bounds.y, 250)
}

@Test
func spacerUsesExistingHorizontalGrowth(): Unit {
    let row = cjguiComposableHorizontal(1300, "spacer-row", CjguiComposableUiStyle(fixedWidth: 300, fixedHeight: 40,
        gap: 10))
    row.add(cjguiComposableText(1301, "spacer-left", "Left", CjguiComposableUiStyle(fixedWidth: 50)))
    row.add(cjguiComposableSpacer(1302, "spacer"))
    row.add(cjguiComposableText(1303, "spacer-right", "Right", CjguiComposableUiStyle(fixedWidth: 50)))
    let scene = layoutPrimitiveScene(row, 300, 40, 1)
    @Assert(scene.layoutError(), "")
    @Assert(scene.nodeForId(1301).bounds.x, 0)
    @Assert(scene.nodeForId(1302).bounds.x, 60)
    @Assert(scene.nodeForId(1302).bounds.width, 180)
    @Assert(scene.nodeForId(1303).bounds.x, 250)
}

private func generatedPropertyDefault(properties: ArrayList<CjguiGeneratedUiPropertySpec>, name: String): String {
    for (property in properties) {
        if (property.name == name) {
            return property.defaultValue
        }
    }
    return "<absent>"
}

private func generatedPropertyMinimum(properties: ArrayList<CjguiGeneratedUiPropertySpec>, name: String): Int64 {
    for (property in properties) {
        if (property.name == name) {
            return property.minimum
        }
    }
    return -1
}

private func generatedPropertyMaximum(properties: ArrayList<CjguiGeneratedUiPropertySpec>, name: String): Int64 {
    for (property in properties) {
        if (property.name == name) {
            return property.maximum
        }
    }
    return -1
}

/// The public property vocabulary is the same contract the layout consumes:
/// stack publishes no gap, aspect ratio publishes the 16:9 defaults the
/// generated builder applies, and spacer publishes the ordinary growth default.
@Test
func generatedLayoutVocabularyMatchesLayout(): Unit {
    let stackProperties = CjguiGeneratedUiPresentation.stackStyleProperties()
    @Assert(generatedPropertyDefault(stackProperties, "gap"), "<absent>")
    @Assert(generatedPropertyDefault(stackProperties, "padding"), "0")
    let wrapProperties = CjguiGeneratedUiPresentation.wrapContentProperties()
    @Assert(generatedPropertyDefault(wrapProperties, "rowGap"), "0")
    @Assert(generatedPropertyMinimum(wrapProperties, "rowGap"), 0)
    @Assert(generatedPropertyMaximum(wrapProperties, "rowGap"), 4096)
    let aspectProperties = CjguiGeneratedUiPresentation.aspectRatioContentProperties()
    @Assert(generatedPropertyDefault(aspectProperties, "aspectWidth"), "16")
    @Assert(generatedPropertyDefault(aspectProperties, "aspectHeight"), "9")
    @Assert(generatedPropertyMinimum(aspectProperties, "aspectWidth"), 1)
    @Assert(generatedPropertyMaximum(aspectProperties, "aspectWidth"), 1000000)
    @Assert(generatedPropertyMinimum(aspectProperties, "aspectHeight"), 1)
    @Assert(generatedPropertyMaximum(aspectProperties, "aspectHeight"), 1000000)
    let spacerProperties = CjguiGeneratedUiPresentation.spacerContentProperties()
    @Assert(generatedPropertyDefault(spacerProperties, "axis"), "horizontal")
    @Assert(generatedPropertyDefault(spacerProperties, "weight"), "1")
    @Assert(generatedPropertyDefault(spacerProperties, "minimum"), "0")
    @Assert(generatedPropertyMinimum(spacerProperties, "weight"), 1)
    @Assert(generatedPropertyMaximum(spacerProperties, "weight"), 100)
    @Assert(generatedPropertyMinimum(spacerProperties, "minimum"), 0)
    @Assert(generatedPropertyMaximum(spacerProperties, "minimum"), 4096)
}
