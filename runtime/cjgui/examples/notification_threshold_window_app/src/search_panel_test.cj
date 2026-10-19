package cjgui_notification_threshold_window_app

import cjgui.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*
import std.env.*

private class ModalRestoreTestController <: CjguiComposableUiController {
    let panel = CjguiSearchableSelectionPanel("restore-result-test")
    public func uiSceneVersion(): Int64 { return panel.revision() }
    public func buildUi(): CjguiComposableUiNode {
        let base = cjguiComposableVertical(1, "restore-base", CjguiComposableUiStyle())
        base.add(cjguiComposableTextInput(13, "restore-field", "通道", "邮件😀中文", 0,
            CjguiComposableUiStyle(fixedHeight: 38)))
        return panel.attachTo(base, CjguiComposableUiTheme.paperLight())
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(false) }
    public func rejectUiEvent(kind: Int64, node: Int64): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(false) }
    public func requestWindowClose(): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(true, shouldClose: true) }
}

@Test
func searchablePanelDoesNotReleaseConfirmationWhenNativeReturnSelectionFails(): Unit {
    let controller = ModalRestoreTestController()
    let host = cjguiCreatePlatformApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Modal Restore Check", 640u32, 520u32))
    let window = host.window()
    @Assert(host.start(), true)
    try {
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        @Assert(window.focusAcceptedNodeById(13), true)
        let _ = host.pumpOneTurn()
        controller.panel.open("测试", ArrayList<CjguiSearchableSelectionItem>([
            CjguiSearchableSelectionItem("sms", "短信")]), CjguiComposableUiNodeReference.manual(13))
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        @Assert(controller.panel.requestConfirm(), true)
        setVariable("CJGUI_SELECTION_RESTORE_REFUSE_ONCE", "1")
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        @Assert(controller.panel.takeConfirmed(window).isNone(), true)
        @Assert(controller.panel.takeConfirmationFailure().startsWith("native_refused_"), true)
        @Assert(controller.panel.takeConfirmationFailure(), "")
        setVariable("CJGUI_SELECTION_RESTORE_REFUSE_ONCE", "0")
        controller.panel.open("重开", ArrayList<CjguiSearchableSelectionItem>([
            CjguiSearchableSelectionItem("sms", "短信")]), CjguiComposableUiNodeReference.manual(13))
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        @Assert(controller.panel.requestConfirm(), true)
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        @Assert(controller.panel.takeConfirmed(window).getOrThrow().key, "sms")
        @Assert(controller.panel.takeConfirmed(window).isNone(), true)
    } finally {
        setVariable("CJGUI_SELECTION_RESTORE_REFUSE_ONCE", "0")
        host.close()
    }
}

@Test
func searchablePanelNavigationKeysRequireAnExplicitInputScope(): Unit {
    for (key in ["up", "down", "enter", "escape"]) {
        let shortcut = CjguiComposableUiShortcut(key, usesCommand: false)
        @Assert(CjguiComposableUiCommand("picker-${key}", 9, shortcut, focusScopeId: "picker").isValid(), true)
        @Assert(CjguiComposableUiCommand("global-${key}", 9, shortcut).isValid(), false)
    }
    @Assert(CjguiComposableUiShortcut("a", usesCommand: false).isValid(), false)
}

@Test
func searchablePanelKeepsBusinessIdentityThroughFilteringAndRejectsDisabledOrEmpty(): Unit {
    let panel = CjguiSearchableSelectionPanel("public-consumer-test")
    panel.open("文件", ArrayList<CjguiSearchableSelectionItem>([
        CjguiSearchableSelectionItem("path-A", "Same.md", detail: "A/Same.md"),
        CjguiSearchableSelectionItem("path-B", "Same.md", detail: "B/Same.md", isEnabled: false, disabledReason: "文件不可读")
    ]), CjguiComposableUiNodeReference.manual(13))
    panel.setQuery("b/same")
    @Assert(panel.resultCount(), 1)
    @Assert(panel.highlightedKey(), "path-B")
    @Assert(panel.itemAt(0).resourceId, 1)
    @Assert(panel.requestConfirm(), false)
    @Assert(panel.isOpen(), true)
    panel.setQuery("no-match")
    @Assert(panel.resultCount(), 0)
    @Assert(panel.requestConfirm(), false)
    panel.setQuery("a/same")
    @Assert(panel.highlightedKey(), "path-A")
    @Assert(panel.requestConfirm(), true)
    @Assert(panel.isOpen(), false)
}

@Test
func searchablePanelUsesAnApplicationMatcherAndCancelsWithoutConfirmation(): Unit {
    let panel = CjguiSearchableSelectionPanel("custom-filter-test")
    panel.open("通道", ArrayList<CjguiSearchableSelectionItem>([
        CjguiSearchableSelectionItem("email", "邮件"), CjguiSearchableSelectionItem("sms", "短信")
    ]), CjguiComposableUiNodeReference.manual(13), matches: { item, query => query == "" || item.key == query })
    panel.setQuery("sms")
    @Assert(panel.highlightedKey(), "sms")
    panel.cancel()
    @Assert(panel.requestConfirm(), false)
    @Assert(panel.isOpen(), false)
}
