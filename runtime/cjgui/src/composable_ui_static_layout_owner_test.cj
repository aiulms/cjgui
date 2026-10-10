package cjgui

import std.collection.*

private class StaticOwnerClock { var base: Int64 = 0; var spent: Bool = false }

private class StaticOwnerLayoutController <: CjguiComposableUiController &
    CjguiComposableUiSceneRefreshParticipant & CjguiComposableUiBusinessOwnerRevisionProvider {
    let owner: FakeTextOwner
    let clock: StaticOwnerClock
    var revision: Int64 = 1
    var builds: Int64 = 0
    var commits: Int64 = 0
    var rollbacks: Int64 = 0
    var spend: Bool = false
    init(owner: FakeTextOwner, clock: StaticOwnerClock) { this.owner = owner; this.clock = clock }
    public func uiSceneVersion(): Int64 { return revision }
    public func uiBusinessOwnerRevision(): Int64 { return owner.ver }
    public func beginSceneRefresh(): Bool { return true }
    public func prepareSceneRefresh(): Bool { return true }
    public func buildUi(): CjguiComposableUiNode {
        builds += 1
        let root = cjguiComposableVertical(9770, "static-owner-root", CjguiComposableUiStyle())
        root.add(cjguiComposableMultilineTextInput(9771, "static-owner-body", "", owner.text(), 9771,
            CjguiComposableUiStyle(fixedWidth: 320, fixedHeight: 90)))
        for (index in 0..16) {
            root.add(cjguiComposableText(9772 + index, "static-owner-companion-${index}",
                "cold companion ${revision}/${index}", CjguiComposableUiStyle(fontSize: 14.0)))
        }
        if (spend) { clock.spent = true }
        return root
    }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> { return ArrayList() }
    public func commitSceneRefresh(): Unit { commits += 1 }
    public func rollbackSceneRefresh(): Unit { rollbacks += 1 }
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

@Test
func staticLayoutSameValueSelectionAndExternalOwnerRetireOriginalCandidateOnce(): Unit {
    let owner = FakeTextOwner("ABCDE🙂\n")
    let clock = StaticOwnerClock()
    let controller = StaticOwnerLayoutController(owner, clock)
    let window = CjguiComposableUiWindow(controller)
    let budget = CjguiOwnerTurnBudget()
    try {
        let session = window.bindRangeTextSession(9771, "static-owner-body", owner, owner,
            9771, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        @Assert(window.start(), true)
        @Assert(window.focusAcceptedNodeById(9771), true)
        let _ = window.pump(0u32)
        @Assert(session.awaitingCalibration(), false)
        window.useOwnerTurnBudget(budget)
        controller.revision = 2
        controller.spend = true
        budget.testUseClock({ => clock.base + if (clock.spent) { 15000000 } else { 0 } })
        window.requestRefresh()
        clock.base = Int64(unsafe { cjgui_internal_renderer_owner_clock_ns() })
        @Assert(budget.begin(), true)
        @Assert(window.refreshIfNeeded(), false)
        budget.end()
        @Assert(controller.builds, 2)
        @Assert(controller.rollbacks, 0)

        // A -> B -> A has equal coordinates, bytes, focus and owner version;
        // only the real semantic selection revision proves it is a new intent.
        session.setSelection16(1, 1)
        session.setSelection16(0, 0)
        clock.spent = false
        clock.base = Int64(unsafe { cjgui_internal_renderer_owner_clock_ns() })
        @Assert(budget.begin(), true)
        @Assert(window.refreshIfNeeded(), false)
        budget.end()
        @Assert(controller.builds, 3)
        @Assert(controller.rollbacks, 1)
        @Assert(owner.ver, 1)
        @Assert(owner.text(), "ABCDE🙂\n")

        // The business owner changes without substituting a UI revision.
        owner.externalWrite(2, 2, "Q")
        @Assert(session.refreshMirror(), true)
        clock.spent = false
        clock.base = Int64(unsafe { cjgui_internal_renderer_owner_clock_ns() })
        @Assert(budget.begin(), true)
        @Assert(window.refreshIfNeeded(), false)
        budget.end()
        @Assert(controller.builds, 4)
        @Assert(controller.rollbacks, 2)
        @Assert(window.acceptedNodeValue("static-owner-body") ?? "", "ABCDE🙂\n")
        @Assert(owner.ver, 2)
        @Assert(owner.text(), "ABQCDE🙂\n")
        window.requestRefresh()
        @Assert(controller.rollbacks, 3)
        controller.spend = false
        budget.testUseClock({ => Int64(unsafe { cjgui_internal_renderer_owner_clock_ns() }) })
        var settled = false
        var turns: Int64 = 0
        while (turns < 48 && !settled) {
            @Assert(budget.begin(), true)
            settled = window.refreshIfNeeded()
            let _ = window.pump(0u32)
            budget.end()
            turns += 1
        }
        @Assert(settled, true)
        @Assert(window.acceptedNodeValue("static-owner-body") ?? "", "ABQCDE🙂\n")
        @Assert(controller.builds, 5)
        @Assert(controller.commits, 2)
        @Assert(controller.rollbacks, 3)
        @Assert(owner.ver, 2)
        @Assert(owner.text(), "ABQCDE🙂\n")
    } finally { budget.end(); window.close() }
}
