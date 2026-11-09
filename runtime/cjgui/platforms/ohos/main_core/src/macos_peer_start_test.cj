package cjgui

import std.unittest.*
import std.unittest.testmacro.*

private class PeerStartController <: CjguiComposableUiController {
    var builds: Int64 = 0
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        builds += 1
        return cjguiComposableText(98100, "peer-start-value", "ordinary peer 中文👩🏽‍💻",
            CjguiComposableUiStyle(growX: 1, growY: 1, fontSize: 14.0))
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

@When[os == "macOS"]
@Test
func macosApplicationDefersPeerColdProjectionToNormalTurn(): Unit {
    let app = CjguiMacosApplication()
    try {
        let first = PeerStartController()
        let opened = app.openWindow(first,
            configuration: CjguiMacosApplicationWindowConfiguration("first peer-start fixture", 400u32, 300u32))
        @Assert(opened.didOpen, true)
        let primaryWindow = app.window(opened.identifier.getOrThrow()).getOrThrow()
        var turns = 0
        while (primaryWindow.windowProjection().submittedFrameIndex <= 0 && turns < 240) {
            let _ = app.pumpOneTurn()
            turns += 1
        }
        @Assert(primaryWindow.windowProjection().submittedFrameIndex > 0, true)
        let before = first.builds
        let peer = PeerStartController()
        let second = app.openWindow(peer,
            configuration: CjguiMacosApplicationWindowConfiguration("second peer-start fixture", 400u32, 300u32))
        @Assert(second.didOpen, true)
        @Assert(peer.builds, 0)
        @Assert(first.builds, before)
        let window = app.window(second.identifier.getOrThrow()).getOrThrow()
        @Assert(window.windowProjection().submittedFrameIndex <= 0, true)
        turns = 0
        while (window.windowProjection().submittedFrameIndex <= 0 && turns < 240) {
            let _ = app.pumpOneTurn()
            turns += 1
        }
        @Assert(window.windowProjection().submittedFrameIndex > 0, true)
        @Assert(peer.builds, 1)
        @Assert(app.requestClose(second.identifier.getOrThrow()), true)
        @Assert(primaryWindow.isOpen(), true)
        @Assert(app.requestClose(opened.identifier.getOrThrow()), true)
        println("PEER_START deferred_builds=0 accepted_builds=${peer.builds} survivor_open=true normal_closed=true")
    } finally { app.close() }
}
