package cjgui

import std.collection.*

// Controlled AppKit probe. Selection and insertion reach the real hidden
// NSTextView through native test seams; the page restore uses only production
// window and native code. Desktop CGEvent delivery is verified separately.
foreign {
    func cjgui_internal_renderer_test_set_composable_selection(
        session: UInt64, nodeIndex: UInt32, selectionStart: UInt32, selectionEnd: UInt32
    ): Int32
    func cjgui_internal_renderer_test_insert_composable_text(
        session: UInt64, nodeIndex: UInt32, text: CString
    ): Int32
}

private class TabsNativeSelectionController <: CjguiComposableUiController {
    let state = CjguiComposableUiTabsState("basic")
    let scope = CjguiComposableUiIdentityScope("tabs-native-selection")
    var draft = "甲😀乙"
    var other = "其他字段"
    private var revision: Int64 = 1

    func bump(): Unit { revision += 1 }
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let basic = cjguiComposableVertical(7501, "selection-basic", CjguiComposableUiStyle(gap: 4))
        basic.add(CjguiComposableUiNode(7502, "selection-editor", CJGUI_COMPOSABLE_UI_TEXT_INPUT,
            "正文", draft, "", 7502, CjguiComposableUiStyle(fixedHeight: 24),
            identity: scope.local("editor")))
        basic.add(CjguiComposableUiNode(7503, "selection-other", CJGUI_COMPOSABLE_UI_TEXT_INPUT,
            "其他", other, "", 7503, CjguiComposableUiStyle(fixedHeight: 24),
            identity: scope.local("other")))
        let pages = ArrayList<CjguiComposableUiTabPage>()
        pages.add(CjguiComposableUiTabPage("basic", "基本", basic))
        pages.add(CjguiComposableUiTabPage("advanced", "高级",
            cjguiComposableText(7504, "selection-advanced", "高级页", CjguiComposableUiStyle(fixedHeight: 20))))
        return cjguiComposableTabs(scope, "selection-tabs", pages, state,
            CjguiComposableUiStyle(growX: 1, growY: 1), titleHeight: 24)
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.semanticId == "selection-editor") {
            draft = event.text
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func editorIndex(window: CjguiComposableUiWindow): UInt32 {
    var index: UInt32 = 0
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == "selection-editor") { return index }
        index += 1
    }
    return 4294967295u32
}

main(): Int64 {
    let controller = TabsNativeSelectionController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start() || !window.focusScopedNode(controller.scope, "editor")) {
        println("CJGUI_TABS_NATIVE_SELECTION setup=false")
        window.close()
        return 1
    }
    let firstIndex = editorIndex(window)
    let selected = unsafe {
        cjgui_internal_renderer_test_set_composable_selection(window.testSessionToken(), firstIndex, 1u32, 3u32)
    }
    let selectionTurn = window.pump(0u32)
    let bookmark = window.testPageFocusBookmarkTrace()
    if (selected != CJGUI_INTERNAL_RENDERER_OK || !bookmark.contains("sel=1-3")) {
        println("CJGUI_TABS_NATIVE_SELECTION selection_status=${selected} event=${selectionTurn.didApplyHumanAction} " +
            "bookmark=${bookmark} passed=false")
        window.close()
        return 1
    }
    let _ = controller.state.select("advanced")
    controller.bump()
    let away = window.refresh()
    let _ = controller.state.select("basic")
    controller.bump()
    let back = window.refresh()
    let restored = window.testPageFocusBookmarkTrace()
    let currentIndex = editorIndex(window)
    let cReplacement = unsafe { LibC.mallocCString("X") }
    var inserted: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (replacement = cReplacement.asResource()) {
        inserted = unsafe {
            cjgui_internal_renderer_test_insert_composable_text(window.testSessionToken(),
                currentIndex, replacement.value)
        }
    }
    let editTurn = window.pump(0u32)
    let restoredSelection = restored.contains("sel=1-3")
    let passed = away && back && restoredSelection &&
        inserted == CJGUI_INTERNAL_RENDERER_OK && editTurn.didApplyHumanAction &&
        controller.draft == "甲X乙" && controller.other == "其他字段"
    println("CJGUI_TABS_NATIVE_SELECTION selected=${selected} away=${away} back=${back} " +
        "restored=${restoredSelection} inserted=${inserted} owner=${controller.draft} " +
        "other=${controller.other} edit_applied=${editTurn.didApplyHumanAction} passed=${passed}")
    window.close()
    return if (passed) { 0 } else { 1 }
}
