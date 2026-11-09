package cjgui

import std.collection.*

private func layoutCopyStyledText(): CjguiComposableUiLayoutNode {
    let runs = [CjguiComposableUiTextStyleRun(0, 5, 32.0, 600, "system", 0.149, 0.149, 0.149, 1.0),
        CjguiComposableUiTextStyleRun.selectionBackground(1, 5,
            CjguiComposableUiColor(0.804, 0.867, 0.949, 0.55))]
    let declaration = cjguiComposableText(1039, "copy-styled-source", "ABCDE",
        CjguiComposableUiStyle(fixedWidth: 680, fixedHeight: 118, pointerInteractive: true),
        fieldId: "source-span", textStyleRuns: runs)
    let clips = ArrayList<CjguiComposableUiClipConstraint>()
    clips.add(CjguiComposableUiClipConstraint(CjguiComposableUiRect(200, 45, 884, 699)))
    return CjguiComposableUiLayoutNode(declaration, CjguiComposableUiRect(302, 586, 680, 118),
        CjguiComposableUiRect(302, 586, 680, 118), clipConstraints: clips)
}

@Test
func layoutCopyOriginGeometryRetainsActualStyledSource(): Unit {
    let before = layoutCopyStyledText()
    let next = before.withResolvedGeometry(CjguiComposableUiRect(302, 78, 680, 118), before.clipConstraints())
    // A rebased focus must carry the same actual typography and selection
    // declaration as its receipt predecessor. The continuation guard stays exact.
    @Assert(next.textStyleRuns.size, 2)
    @Assert(next.textStyleRuns[0].encoded(), before.textStyleRuns[0].encoded())
    @Assert(next.textStyleRuns[1].isSelectionBackground(), true)
    @Assert(next.textStyleRuns[1].encoded(), before.textStyleRuns[1].encoded())
    @Assert(next.bounds.y, 78)
    @Assert(next.fieldId, before.fieldId)
    @Assert(next.identityKey, before.identityKey)
    @Assert(next.value, before.value)
}

@Test
func layoutCopyResolvedPaintRetainsActualStyledSource(): Unit {
    let before = layoutCopyStyledText()
    let next = before.withResolvedPaintStyle(CjguiComposableUiStyle(fontSize: 21.0))
    @Assert(next.textStyleRuns.size, 2)
    @Assert(next.textStyleRuns[0].encoded(), before.textStyleRuns[0].encoded())
    @Assert(next.textStyleRuns[1].encoded(), before.textStyleRuns[1].encoded())
    @Assert(next.style.fontSize, 21.0)
    @Assert(next.bounds.y, before.bounds.y)
    @Assert(next.clip.y, before.clip.y)
    @Assert(next.fieldId, before.fieldId)
    @Assert(next.identityKey, before.identityKey)
    @Assert(next.value, before.value)
}

@Test
func layoutCopyPlatformSelectionRetainsColourPolicyAndScalarBounds(): Unit {
    let run = CjguiComposableUiTextStyleRun.platformSelectionBackground(1, 8)
    let declaration = cjguiComposableText(1039, "copy-platform-selection", "A中🙂B",
        CjguiComposableUiStyle(fixedWidth: 680, fixedHeight: 118), textStyleRuns: [run])
    let before = CjguiComposableUiLayoutNode(declaration, CjguiComposableUiRect(302, 586, 680, 118),
        CjguiComposableUiRect(200, 45, 884, 699))
    let next = before.withResolvedGeometry(CjguiComposableUiRect(302, 78, 680, 118), before.clipConstraints())
    @Assert(next.textStyleRuns[0].encoded(), run.encoded())
    @Assert(next.textStyleRuns[0].usesPlatformSelectionBackground(), true)
    @Assert(cjguiSelectionBackgroundRunsRejection(next.value, next.textStyleRuns).isNone(), true)
    @Assert(cjguiSelectionBackgroundRunsRejection(next.value,
        [CjguiComposableUiTextStyleRun.platformSelectionBackground(2, 8)]).isSome(), true)
    let nodes = ArrayList<CjguiComposableUiLayoutNode>()
    nodes.add(next)
    let scene = CjguiComposableUiScene(1, CjguiComposableUiRect(0, 0, 1100, 780), nodes)
    @Assert(scene.hasPlatformSelectionBackground, true)
}
