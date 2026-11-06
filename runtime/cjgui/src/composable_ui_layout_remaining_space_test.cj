package cjgui

@Test
func remainingHeightDoesNotDependOnGrowingEditorText(): Unit {
    let root = cjguiComposableVertical(81001, "root", CjguiComposableUiStyle())
    root.add(cjguiComposableText(81002, "header", "Header", CjguiComposableUiStyle()))
    root.add(cjguiComposableMultilineTextInput(81003, "editor", "Editor",
        "A long editor value that wraps across many lines in a narrow window. " +
        "A long editor value that wraps across many lines in a narrow window. " +
        "A long editor value that wraps across many lines in a narrow window.", 81003,
        CjguiComposableUiStyle(growY: 1, alignX: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH)))
    root.add(cjguiComposableText(81004, "footer", "Footer", CjguiComposableUiStyle()))
    let scene = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 120, 200), 1)
    let header = scene.nodeForId(81002).bounds
    let editor = scene.nodeForId(81003).bounds
    let footer = scene.nodeForId(81004).bounds
    @Assert(scene.isValid(), true)
    @Assert(header.height > 0, true)
    @Assert(footer.height > 0, true)
    @Assert(editor.y, header.height)
    @Assert(editor.height, 200 - header.height - footer.height)
    @Assert(footer.y + footer.height, 200)
}

@Test
func naturalCrossAxisTextStaysWithinNarrowParent(): Unit {
    let root = cjguiComposableVertical(81101, "root", CjguiComposableUiStyle())
    root.add(cjguiComposableText(81102, "text", "This long text must wrap within the available width",
        CjguiComposableUiStyle(alignX: CJGUI_COMPOSABLE_UI_ALIGN_CENTER)))
    let scene = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 80, 300), 1)
    let text = scene.nodeForId(81102).bounds
    @Assert(scene.isValid(), true)
    @Assert(text.x, 0)
    @Assert(text.width, 80)
    @Assert(text.height > 25, true)
}

@Test
func crossAxisHonorsExplicitWidthsAndPosition(): Unit {
    let root = cjguiComposableVertical(81201, "root", CjguiComposableUiStyle())
    root.add(cjguiComposableText(81202, "fixed", "Long text", CjguiComposableUiStyle(fixedWidth: 120)))
    root.add(cjguiComposableText(81203, "minimum", "Long text", CjguiComposableUiStyle(minWidth: 100)))
    root.add(cjguiComposableText(81204, "maximum", "Long text", CjguiComposableUiStyle(maxWidth: 40,
        alignX: CJGUI_COMPOSABLE_UI_ALIGN_END)))
    root.add(cjguiComposableText(81205, "ideal", "Long text", CjguiComposableUiStyle(idealWidth: 60,
        alignX: CJGUI_COMPOSABLE_UI_ALIGN_CENTER)))
    let scene = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 80, 400), 1)
    @Assert(scene.nodeForId(81202).bounds.width, 120)
    @Assert(scene.nodeForId(81203).bounds.width, 100)
    @Assert(scene.nodeForId(81204).bounds.width, 40)
    @Assert(scene.nodeForId(81204).bounds.x, 40)
    @Assert(scene.nodeForId(81205).bounds.width, 60)
    @Assert(scene.nodeForId(81205).bounds.x, 10)
}

@Test
func remainingHeightHonorsBoundsAndMultipleGrowth(): Unit {
    let root = cjguiComposableVertical(81301, "root", CjguiComposableUiStyle())
    root.add(cjguiComposableText(81302, "header", "header", CjguiComposableUiStyle(fixedHeight: 20)))
    root.add(cjguiComposableVertical(81303, "body", CjguiComposableUiStyle(growY: 1, minHeight: 60,
        maxHeight: 80, idealHeight: 70)))
    let capped = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 100, 200), 1)
    let undersized = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 100, 50), 2)
    @Assert(capped.isValid(), true)
    @Assert(capped.nodeForId(81303).bounds.height, 80)
    @Assert(undersized.nodeForId(81303).bounds.height, 60)
    @Assert(undersized.nodeForId(81303).bounds.y, 20)

    let two = cjguiComposableVertical(81401, "two", CjguiComposableUiStyle())
    two.add(cjguiComposableVertical(81402, "first", CjguiComposableUiStyle(growY: 1)))
    two.add(cjguiComposableVertical(81403, "second", CjguiComposableUiStyle(growY: 1)))
    let shared = CjguiComposableUiLayoutEngine.layout(two, CjguiComposableUiRect(0, 0, 100, 200), 3)
    @Assert(shared.nodeForId(81402).bounds.height, 100)
    @Assert(shared.nodeForId(81403).bounds.height, 100)
}
