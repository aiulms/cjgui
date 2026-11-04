package cjgui

import std.collection.*
import std.time.*

private class RevealWindowSource <: CjguiComposableUiVirtualListSource {
    public func itemCount(): Int64 { return 100 }
    public func itemAt(index: Int64): CjguiComposableUiVirtualListItem {
        return CjguiComposableUiVirtualListItem("item-${index}", index, "item ${index}")
    }
    public func indexForKey(key: String): Int64 {
        for (index in 0..100) { if (key == "item-${index}") { return index } }
        return -1
    }
    public func buildRow(item: CjguiComposableUiVirtualListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        return cjguiComposableText(30000 + item.resourceId, "reveal-row-${item.resourceId}", item.title,
            CjguiComposableUiStyle(fixedHeight: 20))
    }
}

private class RevealWindowController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant &
    CjguiComposableUiBusinessOwnerRevisionProvider {
    let viewport = CjguiComposableUiScrollViewport()
    let state = CjguiComposableUiVirtualListState()
    let source = RevealWindowSource()
    let variableSource = LateHeightRevealSource(80)
    var useVariable: Bool = false
    var commits: Int64 = 0
    var rollbacks: Int64 = 0
    var directRoot: Bool = false
    public func uiSceneVersion(): Int64 { return 1 }
    public func uiBusinessOwnerRevision(): Int64 { return 1 }
    public func beginSceneRefresh(): Bool { return true }
    public func prepareSceneRefresh(): Bool { return true }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> { return ArrayList() }
    public func commitSceneRefresh(): Unit { commits += 1 }
    public func rollbackSceneRefresh(): Unit { rollbacks += 1 }
    public func buildUi(): CjguiComposableUiNode {
        let style = CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 100)
        let list = if (useVariable) {
            cjguiComposableVariableHeightList(100, "reveal-list", 101, viewport, variableSource, state,
                20, 0, 0, style)
        } else {
            cjguiComposableVirtualList(100, "reveal-list", 101, viewport, source, state, 20, 0, 0, style)
        }
        if (directRoot) { return list }
        let root = cjguiComposableVertical(99, "reveal-root", CjguiComposableUiStyle())
        root.add(list)
        return root
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
func collectionRejectedRevealPreservesPreparedCandidate(): Unit {
    cjguiMacosOwnerTest({ => collectionRejectedRevealPreservesPreparedCandidateBody() })
}

private func collectionAdvanceOwnerTurn(window: CjguiComposableUiWindow, budget: CjguiOwnerTurnBudget): Unit {
    @Assert(budget.begin(), true)
    try {
        let _ = window.refreshIfNeeded()
        let _ = window.pump(0u32)
        let _ = budget.finishScheduling()
    } finally { budget.end() }
}

private func collectionAwaitFirstAccepted(window: CjguiComposableUiWindow, budget: CjguiOwnerTurnBudget): Unit {
    let deadline = MonoTime.now() + 5 * Duration.second
    var turns: Int64 = 0
    while (window.isOpen() && window.windowProgress().acceptedSceneVersion < 1 &&
        turns < 240 && MonoTime.now() < deadline) {
        collectionAdvanceOwnerTurn(window, budget)
        turns += 1
    }
    @Assert(window.windowProgress().acceptedSceneVersion >= 1, true)
}

private func collectionRejectedRevealPreservesPreparedCandidateBody(): Unit {
    let controller = RevealWindowController()
    let window = CjguiComposableUiWindow(controller)
    let budget = CjguiOwnerTurnBudget()
    try {
        window.useOwnerTurnBudget(budget)
        @Assert(window.start(), true)
        collectionAwaitFirstAccepted(window, budget)
        budget.testUseClock({ =>
            let now = Int64(unsafe { cjgui_internal_renderer_owner_clock_ns() })
            now + if (window.testPreparedCandidateReady()) { 10000000 } else { 0 }
        })
        @Assert(controller.viewport.acceptedOffset(), 0)
        @Assert(controller.uiBusinessOwnerRevision(), 1)
        @Assert(controller.viewport.requestOffset(20), true)
        @Assert(controller.viewport.acceptedOffset(), 0)
        window.requestRefresh()
        var turns: Int64 = 0
        let deadline = MonoTime.now() + 5 * Duration.second
        while (!window.testPreparedCandidateReady() && turns < 240 && MonoTime.now() < deadline) {
            collectionAdvanceOwnerTurn(window, budget)
            turns += 1
        }
        @Assert(window.testPreparedCandidateReady(), true)
        let before = window.testSelectionRefreshIdentity()
        @Assert(before[1] > 0, true)
        let beforeRollbacks = controller.rollbacks
        let beforeOffset = controller.viewport.offset()
        let foreignViewport = CjguiComposableUiScrollViewport()
        foreignViewport.stageExtents(2000, 100, 0)
        foreignViewport.commitStagedExtents()
        @Assert(window.revealVirtualListItem("reveal-list", "item-10", foreignViewport), false)
        @Assert(window.testSelectionRefreshIdentity()[1], before[1])
        @Assert(window.testPreparedCandidateReady(), true)
        @Assert(controller.rollbacks, beforeRollbacks)
        @Assert(window.revealVirtualListItem("reveal-list", "missing", controller.viewport), false)
        let after = window.testSelectionRefreshIdentity()
        @Assert(after[1], before[1])
        @Assert(window.testPreparedCandidateReady(), true)
        @Assert(controller.rollbacks, beforeRollbacks)
        @Assert(controller.viewport.offset(), beforeOffset)
        @Assert(controller.viewport.acceptedOffset(), 0)
        @Assert(controller.state.selectedKey(), "")
        @Assert(controller.state.focusedKey(), "")
        @Assert(window.revealVirtualListItem("reveal-list", "item-10", controller.viewport), true)
        @Assert(controller.viewport.offset(), 200)
        @Assert(controller.viewport.acceptedOffset(), 0)
        @Assert(controller.state.selectedKey(), "")
        @Assert(controller.state.focusedKey(), "")
        @Assert(controller.uiBusinessOwnerRevision(), 1)
        window.close()
        @Assert(window.revealVirtualListItem("reveal-list", "item-10", controller.viewport), false)
    } finally {
        budget.end()
        window.close()
    }
}

@When[os == "macOS"]
@Test
func collectionFixedRootFreezesWindowAllocatedExtent(): Unit {
    cjguiMacosOwnerTest({ => collectionFixedRootFreezesWindowAllocatedExtentBody() })
}

private func collectionFixedRootFreezesWindowAllocatedExtentBody(): Unit {
    let controller = RevealWindowController()
    controller.directRoot = true
    let window = CjguiComposableUiWindow(controller)
    let budget = CjguiOwnerTurnBudget()
    try {
        window.useOwnerTurnBudget(budget)
        @Assert(window.start(), true)
        collectionAwaitFirstAccepted(window, budget)
        @Assert(window.acceptedNodeBounds("reveal-list").isSome(), true)
        @Assert(window.acceptedNodeBounds("reveal-row-6").isSome(), true)
        @Assert(controller.state.materializedEnd() > 6, true)
        @Assert(controller.state.materializedEnd() < 100, true)
    } finally { budget.end(); window.close() }
}

@When[os == "macOS"]
@Test
func collectionWindowVariableRevealCommitsLateHeightAnchor(): Unit {
    cjguiMacosOwnerTest({ =>
        let controller = RevealWindowController()
        controller.useVariable = true
        let window = CjguiComposableUiWindow(controller)
        let budget = CjguiOwnerTurnBudget()
        try {
            window.useOwnerTurnBudget(budget)
            @Assert(window.start(), true)
            collectionAwaitFirstAccepted(window, budget)
            let beforeScene = window.windowProgress().acceptedSceneVersion
            @Assert(controller.viewport.acceptedOffset(), 0)
            @Assert(window.revealVirtualListItem("reveal-list", "item-19", controller.viewport), true)
            @Assert(controller.viewport.acceptedOffset(), 0)
            let deadline = MonoTime.now() + 5 * Duration.second
            var turns: Int64 = 0
            while (window.isOpen() && window.windowProgress().acceptedSceneVersion <= beforeScene &&
                turns < 240 && MonoTime.now() < deadline) {
                collectionAdvanceOwnerTurn(window, budget)
                turns += 1
            }
            @Assert(window.windowProgress().acceptedSceneVersion > beforeScene, true)
            let list = window.acceptedNodeBounds("reveal-list").getOrThrow()
            let target = window.acceptedNodeBounds("late-row-19").getOrThrow()
            @Assert(target.height, 80)
            @Assert(target.y >= list.y, true)
            @Assert(target.y + target.height <= list.y + list.height, true)
            @Assert(controller.viewport.acceptedOffset(), 360)
            @Assert(controller.state.selectedKey(), "")
            @Assert(controller.state.focusedKey(), "")
            @Assert(controller.uiBusinessOwnerRevision(), 1)
        } finally { budget.end(); window.close() }
    })
}
