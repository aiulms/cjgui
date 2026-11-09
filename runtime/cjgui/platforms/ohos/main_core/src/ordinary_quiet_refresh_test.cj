package cjgui

import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

private class OrdinaryQuietController <: CjguiComposableUiController {
    var revision: Int64 = 1
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        return cjguiComposableText(99201, "ordinary-quiet-label", "revision ${revision}",
            CjguiComposableUiStyle(fixedWidth: 220, fixedHeight: 40))
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(false) }
    public func rejectUiEvent(kind: Int64, node: Int64): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(false) }
    public func requestWindowClose(): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(true, shouldClose: true) }
}

@When[os == "macOS"]
@Test
func ordinaryQuietPeersRetireObsoleteRefreshAdmissionAndActuallyWait(): Unit {
    cjguiMacosOwnerTest({ =>
        let app = CjguiMacosApplication()
        let first = OrdinaryQuietController()
        let second = OrdinaryQuietController()
        let a = app.openWindow(first, configuration: CjguiMacosApplicationWindowConfiguration("quiet A", 400u32, 300u32))
        let b = app.openWindow(second, configuration: CjguiMacosApplicationWindowConfiguration("quiet B", 400u32, 300u32))
        @Assert(a.didOpen && b.didOpen, true)
        let wa = app.window(a.identifier.getOrThrow()).getOrThrow()
        let wb = app.window(b.identifier.getOrThrow()).getOrThrow()
        let budget = CjguiOwnerTurnBudget()
        wa.useOwnerTurnBudget(budget); wb.useOwnerTurnBudget(budget)
        try {
            let deadline = MonoTime.now() + Duration.second * 3
            while (MonoTime.now() < deadline) {
                let _ = app.pumpUntilWork(timeoutMs: 16u32)
                if (wa.acceptedNodeText("ordinary-quiet-label") == Some("revision 1") &&
                    wb.acceptedNodeText("ordinary-quiet-label") == Some("revision 1") &&
                    budget.observedIdleNanoseconds() > 0) { break }
            }
            @Assert(wa.acceptedNodeText("ordinary-quiet-label"), Some("revision 1"))
            @Assert(wb.acceptedNodeText("ordinary-quiet-label"), Some("revision 1"))
            @Assert(budget.observedIdleNanoseconds() > 0, true)
            // A real prior budget denial leaves the second owner queued. Its
            // next accepted scene is already unchanged; no candidate is ready.
            @Assert(budget.begin(), true)
            @Assert(budget.admitsRefresh(wb.testSessionToken(), Int64.Max), false)
            budget.end()
            @Assert(budget.begin(), true)
            // Pin the adverse visit order: the non-priority quiet peer is
            // checked first, exactly as captured in the production hot region.
            let firstUnchanged = wa.refreshIfNeeded()
            let secondUnchanged = wb.refreshIfNeeded()
            println("ORDINARY_QUIET first=${firstUnchanged} second=${secondUnchanged} ready=${budget.hasReadyContinuation()}")
            @Assert(firstUnchanged && secondUnchanged, true)
            @Assert(budget.hasReadyContinuation(), false)
            @Assert(wa.ownerIdleWaitAllowance(16u32, frameworkOwnsTurn: true), 16u32)
            budget.end()
            let waitDeadline = MonoTime.now() + Duration.second * 3
            while (MonoTime.now() < waitDeadline) {
                let _ = app.pumpUntilWork(timeoutMs: 16u32)
                if (budget.observedIdleNanoseconds() > 0) { break }
            }
            @Assert(budget.observedIdleNanoseconds() > 0, true)
            // Retiring obsolete demand must not suppress a real sibling edit.
            first.revision += 1; wa.requestRefresh()
            let changedDeadline = MonoTime.now() + Duration.second * 3
            while (MonoTime.now() < changedDeadline && wa.acceptedNodeText("ordinary-quiet-label") != Some("revision 2")) {
                let _ = app.pumpUntilWork(timeoutMs: 16u32)
            }
            @Assert(wa.acceptedNodeText("ordinary-quiet-label"), Some("revision 2"))
            @Assert(wb.acceptedNodeText("ordinary-quiet-label"), Some("revision 1"))
        } finally { budget.end(); app.close() }
    })
}
