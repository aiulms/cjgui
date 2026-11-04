package cjgui

import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

private class DirectRefreshOwner <: CjguiComposableUiController {
    var revision: Int64 = 1
    var text = "before"
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "direct-refresh-root", CjguiComposableUiStyle())
        root.add(cjguiComposableTextInput(2, "direct-refresh-value", "Value", text, 10,
            CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 32)))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(kind: Int64, node: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func directRefreshAcceptedValue(window: CjguiComposableUiWindow): String {
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == 2) { return node.value }
    }
    return "missing"
}

@When[os == "macOS"]
@Test
func directWindowRefreshOutsideApplicationTurnKeepsDrawableCandidate(): Unit {
    cjguiMacosOwnerTest({ =>
        let owner = DirectRefreshOwner()
        let app = CjguiMacosApplication()
        let opened = app.openWindow(owner, configuration:
            CjguiMacosApplicationWindowConfiguration("CJGUI direct refresh", 400u32, 300u32))
        @Assert(opened.didOpen, true)
        let id = opened.identifier.getOrThrow()
        let window = app.window(id).getOrThrow()
        try {
            let beforeDeadline = MonoTime.now() + 5 * Duration.second
            while ((directRefreshAcceptedValue(window) != "before" || window.hasDeferredEventWork()) &&
                MonoTime.now() < beforeDeadline) {
                let _ = app.pumpOneTurn()
            }
            @Assert(directRefreshAcceptedValue(window), "before")
            @Assert(window.hasDeferredEventWork(), false)
            let scene = window.displayedSceneVersion()
            owner.text = "after"; owner.revision += 1
            // The application installed its budget during the completed turn.
            // This is the public direct entry outside that now-inactive turn.
            let _ = window.refresh()
            @Assert(window.nativeStatus() != CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR, true)
            let deadline = MonoTime.now() + 5 * Duration.second
            while (directRefreshAcceptedValue(window) != "after" && MonoTime.now() < deadline) {
                let _ = app.pumpOneTurn()
            }
            @Assert(directRefreshAcceptedValue(window), "after")
            @Assert(window.displayedSceneVersion() > scene, true)
        } finally {
            let _ = app.requestClose(id)
        }
    })
}
