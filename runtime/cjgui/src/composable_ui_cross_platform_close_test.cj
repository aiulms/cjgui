package cjgui

import std.unittest.*
import std.unittest.testmacro.*

@When[os != "macOS"]
private class CrossPlatformCloseOwner <: CjguiComposableUiController & CjguiComposableUiWindowCloseLifecycle {
    var commits: Int64 = 0
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        return cjguiComposableVertical(1, "cross-platform-close", CjguiComposableUiStyle())
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
    public func windowCloseDidCommit(): Unit { commits += 1 }
}

// Run on a supported non-Mac renderer host; no Mac testing stub can stand in
// for the native destroy and its real settlement decisions.
@When[os != "macOS"]
@Test
func nonMacWindowCloseUsesNativeDestroyAndRetires(): Unit {
    let owner = CrossPlatformCloseOwner()
    let window = CjguiComposableUiWindow(owner)
    @Assert(internalRendererAtomicExitCommitSupported(), false)
    @Assert(window.start(), true)
    window.close()
    @Assert(window.isOpen(), false)
    @Assert(owner.commits, 1)
}
