package cjgui

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private class AcceptedCommandPaintController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    var revision: Int64 = 0
    var enabled: Bool = true
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func buildUi(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.paperLight()
        let root = cjguiComposableVertical(1, "accepted-menu-root", theme.page)
        root.add(
            cjguiComposableButton(2, "accepted-menu-action", "Apply", "APPLY", 0, theme.primaryAction, enabled: enabled,
                interactionStyle: theme.primaryActionInteraction))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE && enabled)
    }
    public func rejectUiEvent(kind: Int64, node: Int64): CjguiComposableUiDispatchResult {
        let _ = kind;
        let _ = node
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func beginSceneRefresh(): Bool {
        return true
    }
    public func prepareSceneRefresh(): Bool {
        return true
    }
    public func commitSceneRefresh(): Unit {}
    public func rollbackSceneRefresh(): Unit {}
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>(
            [CjguiComposableUiCommand("accepted.apply", 2, CjguiComposableUiShortcut("s"))])
    }
}

@When[os == "macOS"]
@Test
func interactionPaintUsesAcceptedCommandIdentityAfterCandidateRetires(): Unit {
    let controller = AcceptedCommandPaintController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    try {
        let _ = window.refresh()
        for (_ in 0..64) {
            let _ = window.pump(1u32)
        }
        @Assert(window.windowProgress().acceptedSceneVersion > 0, true)
        @Assert(window.testApplyInteractionIntent(43u32, 2), true)
        @Assert(window.testRefreshInteractionPaint(), true)
        controller.enabled = false
        controller.revision += 1
        let _ = window.refresh()
        for (_ in 0..64) {
            let _ = window.pump(1u32)
        }
        @Assert(window.testRefreshInteractionPaint(), true)
        @Assert(window.invokeCommand("accepted.apply"), false)
    } finally {
        window.close()
    }
}
