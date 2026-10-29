package cjgui

import std.unittest.*
import std.unittest.testmacro.*

private class IncrementalContinuationController <: CjguiComposableUiController {
    public var revision: Int64 = 1
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(98301, "incremental-root", CjguiComposableUiStyle())
        root.add(cjguiComposableText(98302, "incremental-label", "revision-${revision}", CjguiComposableUiStyle()))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(false) }
    public func rejectUiEvent(kind: Int64, node: Int64): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(false) }
    public func requestWindowClose(): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(true, shouldClose: true) }
}

@Test
func incrementalContinuationRetainedCandidateAdvertisesWorkWithoutHumanEvent(): Unit {
    let controller = IncrementalContinuationController()
    let app = CjguiMacosApplication()
    let opened = app.openWindow(controller, configuration:
        CjguiMacosApplicationWindowConfiguration("incremental continuation fixture", 400u32, 300u32))
    @Assert(opened.didOpen, true)
    let window = app.window(opened.identifier.getOrThrow()).getOrThrow()
    try {
        // This checks the existing retained-work control signal. Actual first
        // frame publication is checked in the normal consumers, not used as
        // a prerequisite of this unit contract.
        let budget = CjguiOwnerTurnBudget()
        window.useOwnerTurnBudget(budget)
        controller.revision += 1
        window.requestRefresh()
        @Assert(budget.begin(), true)
        let _ = window.refreshIfNeeded()
        // No human event was sent. This is the existing retained candidate,
        // which the application wait tail must be allowed to continue.
        println("INCREMENTAL_CONTINUATION pending=${budget.hasPreparedWork()} " +
            "deferred=${window.hasDeferredEventWork()} native=${window.nativeStatus()} " +
            "failure=${window.windowProjection().lastNativeFailure}")
        @Assert(budget.hasPreparedWork(), true)
        @Assert(window.hasDeferredEventWork(), true)
        budget.end()
    } finally { app.close() }
}
