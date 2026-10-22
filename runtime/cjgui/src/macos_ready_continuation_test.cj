package cjgui

import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

foreign {
    func cjgui_internal_renderer_test_drawable_gate_close(): Unit
    func cjgui_internal_renderer_test_drawable_gate_open(): Unit
    func cjgui_internal_renderer_test_drawable_gate_entries(): UInt64
    func cjgui_internal_renderer_test_drawable_gate_open_on_owner_wait(): Unit
    func cjgui_internal_renderer_test_drawable_gate_owner_wait_opens(): UInt64
}

private class ReadyContinuationController <: CjguiComposableUiController {
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        return cjguiComposableButton(98201, "ready-button", "ready 中文", "ACT", 1,
            CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 50,
                background: CjguiComposableUiColor(0.1, 0.1, 0.1, 1.0)),
            interactionStyle: CjguiComposableUiInteractionStyle(hover: CjguiComposableUiPaintStyle(
                background: Some(CjguiComposableUiColor(0.8, 0.1, 0.1, 1.0)))))
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
func macosReadyPaintIsConsumedAtExistingWaitTailBeforeReturningToCaller(): Unit {
    let app = CjguiMacosApplication()
    try {
        let opened = app.openWindow(ReadyContinuationController(), configuration:
            CjguiMacosApplicationWindowConfiguration("ready continuation fixture", 400u32, 300u32))
        @Assert(opened.didOpen, true)
        let window = app.window(opened.identifier.getOrThrow()).getOrThrow()
        var turns = 0
        while ((window.windowProjection().submittedFrameIndex <= 0 ||
                window.ownerIdleWaitAllowance(UInt32.Max) != UInt32.Max) && turns < 240) {
            let _ = app.pumpOneTurn()
            turns += 1
        }
        @Assert(window.windowProjection().submittedFrameIndex > 0, true)
        let _ = window.setReduceMotionEnabled(true)
        @Assert(window.testApplyInteractionIntent(43u32, 98201), true)
        unsafe { cjgui_internal_renderer_test_drawable_gate_close() }
        @Assert(window.testRefreshInteractionPaint(), false)
        let entered = MonoTime.now()
        while (unsafe { cjgui_internal_renderer_test_drawable_gate_entries() } == 0u64 &&
            (MonoTime.now() - entered).toNanoseconds() < 200000000) {}
        @Assert(unsafe { cjgui_internal_renderer_test_drawable_gate_entries() }, 1u64)
        let before = window.windowProjection().submittedFrameIndex
        unsafe { cjgui_internal_renderer_test_drawable_gate_open_on_owner_wait() }
        // Exactly ONE ordinary turn. The completion wakes its existing wait;
        // no next caller turn, extra pump, event or timeout rescues the result.
        let _ = app.pumpUntilWork(timeoutMs: 200u32)
        let after = window.windowProjection().submittedFrameIndex
        let opens = unsafe { cjgui_internal_renderer_test_drawable_gate_owner_wait_opens() }
        println("READY_CONTINUATION before=${before} after=${after} wait_opens=${opens} caller_turns=1")
        @Assert(opens, 1u64)
        @Assert(after > before, true)
    } finally {
        unsafe { cjgui_internal_renderer_test_drawable_gate_open() }
        app.close()
    }
}
