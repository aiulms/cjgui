package cjgui

import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

private class OrdinaryRefreshContinuationController <: CjguiComposableUiController {
    var revision: Int64 = 1
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        return cjguiComposableText(98991, "ready-owner-label", "revision ${revision}",
            CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 40))
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

@When[os == "macOS"]
@Test
func ordinaryPacketBudgetYieldSchedulesReadyOwnerWork(): Unit {
    cjguiMacosOwnerTest({ =>
        let controller = OrdinaryRefreshContinuationController()
        let window = CjguiComposableUiWindow(controller)
        let budget = CjguiOwnerTurnBudget()
        try {
            @Assert(window.start(), true)
            window.useOwnerTurnBudget(budget)
            controller.revision += 1
            // Charge a real, frozen packet's first run-enumeration boundary.
            // Nothing marks native Ready or invents a completion notification.
            budget.testUseClock({ =>
                let actual = Int64(unsafe { cjgui_internal_renderer_owner_clock_ns() })
                return actual + if (window.testPreparedRunSourceCount() > 0) { 98500000 } else { 0 }
            })
            for (_ in 0..48) {
                @Assert(budget.begin(budgetMicroseconds: 100000), true)
                let _ = window.refreshIfNeeded()
                if (window.testPreparedRunSourceCount() > 0) { break }
                budget.end()
            }
            @Assert(window.testPreparedRunSourceCount() > 0, true)
            @Assert(budget.hasReadyContinuation(), true)
            @Assert(window.ownerIdleWaitAllowance(UInt32.Max, frameworkOwnsTurn: true), 0u32)
            budget.end()
            budget.testUseClock({ => Int64(unsafe { cjgui_internal_renderer_owner_clock_ns() }) })
            let deadline = MonoTime.now() + Duration.second * 3
            while (MonoTime.now() < deadline) {
                @Assert(budget.begin(budgetMicroseconds: 100000), true)
                let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternalInRound(
                    window, 100u32, 16u32, true)
                budget.end()
                if (window.acceptedNodeText("ready-owner-label") == Some("revision 2")) { break }
            }
            @Assert(window.acceptedNodeText("ready-owner-label"), Some("revision 2"))
        } finally { budget.end(); window.close() }
    })
}
