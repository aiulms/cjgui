package cjgui

@Test
func scrollAreaRejectsMultipleContentChildren(): Unit {
    let root = cjguiComposableVertical(85001, "root", CjguiComposableUiStyle())
    let scroll = cjguiComposableScrollArea(85002, "scroll", 0, CjguiComposableUiStyle(fixedHeight: 100))
    scroll.add(cjguiComposableText(85003, "first", "first", CjguiComposableUiStyle()))
    scroll.add(cjguiComposableText(85004, "second", "second", CjguiComposableUiStyle()))
    root.add(scroll)
    let scene = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 300, 200), 1)
    @Assert(scene.isValid(), false)
    @Assert(scene.layoutError(), "scroll_area_requires_at_most_one_child")
}

@Test
func scrollAreaAcceptsEmptyAndSingleContent(): Unit {
    let empty = cjguiComposableScrollArea(85101, "empty", 0, CjguiComposableUiStyle())
    let emptyScene = CjguiComposableUiLayoutEngine.layout(empty, CjguiComposableUiRect(0, 0, 300, 200), 1)
    @Assert(emptyScene.isValid(), true)
    let scroll = cjguiComposableScrollArea(85201, "scroll", 0, CjguiComposableUiStyle())
    let content = cjguiComposableVertical(85202, "content", CjguiComposableUiStyle())
    content.add(cjguiComposableText(85203, "first", "first", CjguiComposableUiStyle()))
    content.add(cjguiComposableText(85204, "second", "second", CjguiComposableUiStyle()))
    scroll.add(content)
    let scene = CjguiComposableUiLayoutEngine.layout(scroll, CjguiComposableUiRect(0, 0, 300, 200), 1)
    @Assert(scene.isValid(), true)
    @Assert(scene.nodeForId(85203).nodeId, 85203)
    @Assert(scene.nodeForId(85204).nodeId, 85204)
}
