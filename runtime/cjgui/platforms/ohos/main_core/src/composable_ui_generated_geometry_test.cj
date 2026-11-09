// Accepted generated geometry is a public change detector. Equal-sized siblings
// must not cancel each other's resize, as they did in the real OHOS 60% viewport.
package cjgui

import std.collection.*

private func geometryTestInstance(key: String, id: Int64, width: Int64): CjguiGeneratedUiAcceptedInstance {
    return CjguiGeneratedUiAcceptedInstance(key, "", "", id, "generated-${key}",
        "vertical", "", "", "", true, CjguiComposableUiRect(28, 1090, width, 72))
}

private func geometryTestRectInstance(key: String, id: Int64, width: Int64,
    height: Int64): CjguiGeneratedUiAcceptedInstance {
    return CjguiGeneratedUiAcceptedInstance(key, "", "", id, "generated-${key}",
        "vertical", "", "", "", true, CjguiComposableUiRect(28, 1090, width, height))
}

private func geometryTestInstances(boardWidth: Int64, editorWidth: Int64):
    ArrayList<CjguiGeneratedUiAcceptedInstance> {
    let instances = ArrayList<CjguiGeneratedUiAcceptedInstance>()
    instances.add(geometryTestInstance("board", 100, boardWidth))
    instances.add(geometryTestInstance("icon", 101, 160))
    instances.add(geometryTestInstance("editor", 102, editorWidth))
    return instances
}

@Test
func generatedGeometryRevisionDetectsEqualWidthSiblingResize(): Unit {
    let before = geometryTestInstances(1264, 1264)
    let after = geometryTestInstances(736, 736)
    let baseline = cjguiGeneratedUiGeometryRevision(before)
    @Assert(cjguiGeneratedUiGeometryRevision(before), baseline)
    @Assert(cjguiGeneratedUiGeometryRevision(after) != baseline, true)
}

@Test
func generatedGeometryRevisionKeepsNodeAssociationWhenWidthsSwap(): Unit {
    let before = geometryTestInstances(1264, 736)
    let after = geometryTestInstances(736, 1264)
    @Assert(cjguiGeneratedUiGeometryRevision(before) != cjguiGeneratedUiGeometryRevision(after), true)
}

@Test
func generatedGeometryRevisionRetainsFieldAndInstancePositions(): Unit {
    let wide = ArrayList<CjguiGeneratedUiAcceptedInstance>()
    wide.add(geometryTestRectInstance("board", 100, 2, 3))
    let tall = ArrayList<CjguiGeneratedUiAcceptedInstance>()
    tall.add(geometryTestRectInstance("board", 100, 3, 2))
    @Assert(cjguiGeneratedUiGeometryRevision(wide) != cjguiGeneratedUiGeometryRevision(tall), true)

    let forward = ArrayList<CjguiGeneratedUiAcceptedInstance>()
    forward.add(geometryTestInstance("board", 100, 160))
    forward.add(geometryTestInstance("editor", 102, 736))
    let reversed = ArrayList<CjguiGeneratedUiAcceptedInstance>()
    reversed.add(geometryTestInstance("editor", 102, 736))
    reversed.add(geometryTestInstance("board", 100, 160))
    @Assert(cjguiGeneratedUiGeometryRevision(forward) != cjguiGeneratedUiGeometryRevision(reversed), true)
}

@Test
func generatedGeometryRevisionEmptyIsBounded(): Unit {
    let empty = ArrayList<CjguiGeneratedUiAcceptedInstance>()
    let revision = cjguiGeneratedUiGeometryRevision(empty)
    @Assert(revision >= 0 && revision <= 0x3FFFFFFF, true)
}
