package cjgui

import std.collection.*

foreign {
    func cjgui_internal_renderer_test_composable_measurement_count(
        session: UInt64, outMeasurementCount: CPointer<UInt32>): Int32
}

private class LayoutPreparationClock {
    var base: Int64 = 0
    var spent: Bool = false
}

private class LayoutPreparationController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    let clock: LayoutPreparationClock
    var revision: Int64 = 1
    var spendBuildAllowance: Bool = false
    var builds: Int64 = 0
    var commits: Int64 = 0
    var rollbacks: Int64 = 0
    var viewport: ?CjguiComposableUiScrollViewport = None

    init(clock: LayoutPreparationClock) { this.clock = clock }
    public func uiSceneVersion(): Int64 { return revision }
    public func beginSceneRefresh(): Bool { return true }
    public func buildUi(): CjguiComposableUiNode {
        builds += 1
        let root = cjguiComposableVertical(9790, "layout-prepare-root", CjguiComposableUiStyle())
        for (index in 0..24) {
            root.add(cjguiComposableText(9791 + index, "layout-prepare-row-${index}",
                "revision ${revision}: actual AppKit row ${index} 🙂 仓颉",
                CjguiComposableUiStyle(fontSize: 14.0)))
        }
        // A controlled clock closes admission after build. It establishes the
        // boundary contract; it is not a natural performance measurement.
        if (spendBuildAllowance) { clock.spent = true }
        if (let Some(binding) <- viewport) {
            let scroller = cjguiComposableScrollArea(9788, "layout-prepare-scroll", binding,
                CjguiComposableUiStyle(fixedWidth: 320, fixedHeight: 160))
            scroller.add(root)
            return scroller
        }
        return root
    }
    public func prepareSceneRefresh(): Bool { return true }
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
func layoutPreparationReservesUnownedViewportUntilCancel(): Unit {
    let clock = LayoutPreparationClock()
    let firstController = LayoutPreparationController(clock)
    let first = CjguiComposableUiWindow(firstController)
    let budget = CjguiOwnerTurnBudget()
    let viewport = CjguiComposableUiScrollViewport()
    let secondController = LayoutPreparationController(LayoutPreparationClock())
    secondController.viewport = Some(viewport)
    let second = CjguiComposableUiWindow(secondController)
    let afterCancel = CjguiComposableUiWindow(secondController)
    try {
        @Assert(first.start(), true)
        first.useOwnerTurnBudget(budget)
        firstController.viewport = Some(viewport)
        firstController.revision = 2
        firstController.spendBuildAllowance = true
        clock.base = Int64(unsafe { cjgui_internal_renderer_owner_clock_ns() })
        budget.testUseClock({ => clock.base + if (clock.spent) { 15000000 } else { 0 } })
        first.requestRefresh()
        @Assert(budget.begin(), true)
        @Assert(first.refreshIfNeeded(), false)
        budget.end()
        @Assert(viewport.ownerWindowToken(), 0)
        // A different window cannot solve or claim the object while the
        // original candidate owns its prospective facts and preparation.
        @Assert(second.start(), false)
        @Assert(viewport.ownerWindowToken(), 0)
        @Assert(firstController.rollbacks, 0)
        first.requestRefresh()
        @Assert(firstController.rollbacks, 1)
        @Assert(afterCancel.start(), true)
        @Assert(viewport.ownerWindowToken() > 0, true)
    } finally { budget.end(); first.close(); second.close(); afterCancel.close() }
}

private func layoutPreparationNativeMeasurementCount(window: CjguiComposableUiWindow): UInt32 {
    var count: UInt32 = 0u32
    @Assert(unsafe { cjgui_internal_renderer_test_composable_measurement_count(
        window.testSessionToken(), inout count) }, CJGUI_INTERNAL_RENDERER_OK)
    return count
}

@Test
func layoutPreparationCandidateOwnsItsRunArray(): Unit {
    let red = CjguiComposableUiTextStyleRun(0, 1, 14.0, 0, "system", 1.0, 0.0, 0.0, 1.0)
    let blue = CjguiComposableUiTextStyleRun(0, 1, 14.0, 0, "system", 0.0, 0.0, 1.0, 1.0)
    let runs = [red]
    let declaration = cjguiComposableText(9789, "layout-frozen-runs", "x", CjguiComposableUiStyle(),
        textStyleRuns: runs)
    let frozen = declaration.cloneForWindowCandidate()
    runs[0] = blue
    @Assert(declaration.textStyleRuns[0].blue, 1.0)
    @Assert(frozen.textStyleRuns[0].red, 1.0)
    @Assert(frozen.textStyleRuns[0].blue, 0.0)
}

@Test
func layoutPreparationDoesNotStartColdMeasurementAfterBuildClosesAllowance(): Unit {
    let clock = LayoutPreparationClock()
    let controller = LayoutPreparationController(clock)
    let window = CjguiComposableUiWindow(controller)
    let budget = CjguiOwnerTurnBudget()
    try {
        @Assert(window.start(), true)
        @Assert(controller.builds, 1)
        @Assert(controller.commits, 1)
        let old = window.acceptedNodeValue("layout-prepare-row-0") ?? ""
        let nativeBefore = layoutPreparationNativeMeasurementCount(window)
        window.useOwnerTurnBudget(budget)
        clock.base = Int64(unsafe { cjgui_internal_renderer_owner_clock_ns() })
        budget.testUseClock({ => clock.base + if (clock.spent) { 15000000 } else { 0 } })
        controller.revision = 2
        controller.spendBuildAllowance = true
        window.requestRefresh()
        @Assert(budget.begin(), true)
        @Assert(window.refreshIfNeeded(), false)
        budget.end()
        @Assert(layoutPreparationNativeMeasurementCount(window), nativeBefore)
        @Assert(window.acceptedNodeValue("layout-prepare-row-0") ?? "", old)
        @Assert(controller.builds, 2)
        @Assert(controller.commits, 1)
        @Assert(controller.rollbacks, 0)
        @Assert(budget.hasPreparedWork(), true)

        // Resume with the real clock and the same already-built candidate.
        // A completed preparation must publish once, without replaying build.
        controller.spendBuildAllowance = false
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
        @Assert(window.acceptedNodeValue("layout-prepare-row-0") ?? "",
            "revision 2: actual AppKit row 0 🙂 仓颉")
        @Assert(controller.builds, 2)
        @Assert(controller.commits, 2)
        @Assert(controller.rollbacks, 0)
    } finally { budget.end(); window.close() }
}
