package cjgui

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private class OrdinaryHostBudgetController <: CjguiComposableUiController {
    var revision: Int64 = 1
    var window: ?CjguiComposableUiWindow = None
    var sawActiveBudget: Bool = false
    var observedBuilds: Int64 = 0
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        if (let Some(value) <- window) {
            observedBuilds += 1
            sawActiveBudget = sawActiveBudget || value.hasActiveOwnerSchedulingRound()
        }
        return cjguiComposableText(98401, "ordinary-owner-label", "ordinary ${revision}",
            CjguiComposableUiStyle(fixedWidth: 220, fixedHeight: 40))
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
func ordinaryHostOwnsDefaultRoundAndBorrowsActiveCallerRound(): Unit {
    cjguiMacosOwnerTest({ => ordinaryHostOwnsDefaultRoundAndBorrowsActiveCallerRoundBody() })
}

private func ordinaryHostOwnsDefaultRoundAndBorrowsActiveCallerRoundBody(): Unit {
    let app = CjguiMacosApplication()
    let first = OrdinaryHostBudgetController()
    let second = OrdinaryHostBudgetController()
    let a = app.openWindow(first, configuration:
        CjguiMacosApplicationWindowConfiguration("ordinary budget A", 400u32, 300u32))
    let b = app.openWindow(second, configuration:
        CjguiMacosApplicationWindowConfiguration("ordinary budget B", 400u32, 300u32))
    @Assert(a.didOpen && b.didOpen, true)
    let wa = app.window(a.identifier.getOrThrow()).getOrThrow()
    let wb = app.window(b.identifier.getOrThrow()).getOrThrow()
    try {
        for (_ in 0..240) {
            if (wa.windowProgress().acceptedSceneVersion > 0 && wb.windowProgress().acceptedSceneVersion > 0) { break }
            let _ = app.pumpOneTurn()
        }
        @Assert(wa.windowProgress().acceptedSceneVersion > 0 && wb.windowProgress().acceptedSceneVersion > 0, true)
        first.window = Some(wa); second.window = Some(wb)
        first.revision += 1; second.revision += 1
        wa.requestRefresh(); wb.requestRefresh()
        for (_ in 0..48) {
            let _ = app.pumpOneTurn()
            if (first.observedBuilds > 0 && second.observedBuilds > 0) { break }
        }
        println("ORDINARY_DEFAULT first_builds=${first.observedBuilds} second_builds=${second.observedBuilds} " +
            "first_active=${first.sawActiveBudget} second_active=${second.sawActiveBudget}")
        @Assert(first.observedBuilds > 0 && second.observedBuilds > 0, true)
        @Assert(first.sawActiveBudget && second.sawActiveBudget, true)
        @Assert(wa.hasActiveOwnerSchedulingRound() || wb.hasActiveOwnerSchedulingRound(), false)

        let caller = CjguiOwnerTurnBudget()
        wa.useOwnerTurnBudget(caller); wb.useOwnerTurnBudget(caller)
        @Assert(caller.begin(), true)
        let identity = caller.turnIdentity()
        first.revision += 1; second.revision += 1
        wa.requestRefresh(); wb.requestRefresh()
        let _ = app.pumpOneTurn()
        @Assert(caller.isActive(), true)
        @Assert(caller.turnIdentity(), identity)
        caller.end()
        @Assert(caller.isActive(), false)
    } finally { app.close() }
}

private class OrdinaryBudgetThrowObserver <: CjguiMacosApplicationPostRefreshObserver {
    public func postRefreshBeforePump(window: CjguiComposableUiWindow): Unit {
        throw IllegalStateException("ordinary_budget_callback_failure")
    }
}

@When[os == "macOS"]
@Test
func ordinaryBudgetExceptionsAndSupportedWindowReopen(): Unit {
    cjguiMacosOwnerTest({ => ordinaryBudgetExceptionsAndSupportedWindowReopenBody() })
}

private func ordinaryBudgetExceptionsAndSupportedWindowReopenBody(): Unit {
    let app = CjguiMacosApplication()
    let controller = OrdinaryHostBudgetController()
    let first = app.openWindow(controller, configuration:
        CjguiMacosApplicationWindowConfiguration("shared lifecycle main",400u32,300u32))
    let second = app.openWindow(OrdinaryHostBudgetController(), configuration:
        CjguiMacosApplicationWindowConfiguration("shared lifecycle peer",400u32,300u32))
    @Assert(first.didOpen && second.didOpen,true)
    let wa = app.window(first.identifier.getOrThrow()).getOrThrow()
    let wb = app.window(second.identifier.getOrThrow()).getOrThrow()
    try {
        for (_ in 0..120) {
            if (wa.windowProgress().acceptedSceneVersion>0 && wb.windowProgress().acceptedSceneVersion>0) { break }
            let _ = app.pumpOneTurn()
        }
        let shared = wa.attachedOwnerTurnBudget().getOrThrow()
        @Assert(refEq(shared,wb.attachedOwnerTurnBudget().getOrThrow()),true)
        app.setTestPostRefreshObserver(Some(OrdinaryBudgetThrowObserver()))
        var caught = false
        try { let _ = app.pumpOneTurn() }
        catch (e: Exception) { caught = e.message == "ordinary_budget_callback_failure" }
        @Assert(caught,true)
        @Assert(shared.isActive(),false)

        let caller = CjguiOwnerTurnBudget()
        wa.useOwnerTurnBudget(caller); wb.useOwnerTurnBudget(caller)
        @Assert(caller.begin(),true)
        let turn = caller.turnIdentity()
        caught = false
        try { let _ = app.pumpOneTurn() }
        catch (e: Exception) { caught = e.message == "ordinary_budget_callback_failure" }
        @Assert(caught,true)
        @Assert(caller.isActive() && caller.turnIdentity()==turn,true)
        caller.end()
        app.setTestPostRefreshObserver(None)

        let conflict = CjguiOwnerTurnBudget()
        wb.useOwnerTurnBudget(conflict)
        caught = false
        try { let _ = app.pumpOneTurn() }
        catch (e: Exception) { caught = e.message == "application_owner_budget_conflict" }
        @Assert(caught,true)
        @Assert(caller.isActive() || conflict.isActive(),false)
        wb.useOwnerTurnBudget(caller)

        // Close a WINDOW while the shared application owner remains alive.
        // Host.close/app.close instead terminate the application and are final.
        @Assert(app.requestClose(second.identifier.getOrThrow()),true)
        for (_ in 0..120) {
            if (app.window(second.identifier.getOrThrow()).isNone()) { break }
            let _ = app.pumpOneTurn()
        }
        @Assert(wa.isOpen(),true)
        @Assert(app.window(second.identifier.getOrThrow()).isNone(),true)
        let reopened = app.openWindow(OrdinaryHostBudgetController(), configuration:
            CjguiMacosApplicationWindowConfiguration("shared lifecycle peer reopened",400u32,300u32))
        @Assert(reopened.didOpen,true)
        @Assert(reopened.identifier.getOrThrow().value != second.identifier.getOrThrow().value,true)
        let peer = app.window(reopened.identifier.getOrThrow()).getOrThrow()
        controller.window=Some(wa);controller.revision+=1;wa.requestRefresh()
        for (_ in 0..160) {
            let _ = app.pumpOneTurn()
            if (controller.observedBuilds>0 && peer.windowProgress().acceptedSceneVersion>0) { break }
        }
        @Assert(controller.sawActiveBudget && peer.windowProgress().acceptedSceneVersion>0,true)
        println("ORDINARY_LIFECYCLE owned_exception=propagated caller_exception=borrowed conflict=refused peer_reopened=true main_continued=true")
    } finally { app.close() }
}

@When[os == "macOS"]
@Test
func ordinarySingleHostDefaultBudgetAndFinalClose(): Unit {
    cjguiMacosOwnerTest({ =>
        let controller = OrdinaryHostBudgetController()
        let host = CjguiMacosApplicationHost(controller, configuration:
            CjguiMacosApplicationWindowConfiguration("single host budget",400u32,300u32))
        try {
            @Assert(host.start(),true)
            let window = host.window()
            for (_ in 0..120) {
                if (window.windowProgress().acceptedSceneVersion>0) { break }
                let _ = host.pumpOneTurn()
            }
            controller.window=Some(window);controller.revision+=1;window.requestRefresh()
            for (_ in 0..120) { let _=host.pumpOneTurn();if (controller.observedBuilds>0) { break } }
            @Assert(controller.sawActiveBudget,true)
            @Assert(window.hasActiveOwnerSchedulingRound(),false)
            println("ORDINARY_SINGLE_HOST budget=default_active close=final_no_reopen")
        } finally { host.close() }
    })
}
