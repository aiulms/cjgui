package cjgui

private class OwnerBudgetTestClock { var value: Int64 = 1000000 }
private class OwnerSchedulingWaitState { var calls: Int64 = 0; var deadline: UInt64 = 0u64 }

@Test
func testSharedOwnerBudgetDoesNotResetForSecondWindowOrCallback(): Unit {
    let clock = OwnerBudgetTestClock()
    let budget = CjguiOwnerTurnBudget()
    budget.testUseClock({ => clock.value })
    @Assert(budget.begin(), true)
    clock.value += 9000000
    @Assert(budget.admits(8000), false)
    @Assert(budget.begin(), false)
    @Assert(budget.remainingMicroseconds(), 7000)
    // A second participant reads the same object/allowance.
    let sibling = budget
    @Assert(sibling.admits(8000), false)
    @Assert(sibling.remainingMicroseconds(), 7000)
    budget.end()
    @Assert(budget.begin(), true)
    @Assert(sibling.admits(12000), true)
}

@Test
func testOwnerBudgetCreditsOnlyActualPumpWaitAndKeepsQueueTime(): Unit {
    let clock = OwnerBudgetTestClock()
    let budget = CjguiOwnerTurnBudget()
    budget.testUseClock({ => clock.value })
    let _ = budget.begin()
    clock.value += 13000000 // Main-queue wait is work, not idle.
    @Assert(budget.remainingMicroseconds(), 3000)
    clock.value += 10000000 // A measured pump wait is the only credited interval.
    budget.creditPumpIdle(10000000)
    @Assert(budget.remainingMicroseconds(), 3000)
    clock.value += 3001000
    @Assert(budget.remainingMicroseconds(), 0)
    @Assert(budget.admits(1), false)
}

@Test
func testDeferredRefreshGetsNextTurnBeforeBusySibling(): Unit {
    let clock = OwnerBudgetTestClock()
    let budget = CjguiOwnerTurnBudget()
    budget.testUseClock({ => clock.value })
    let _ = budget.begin()
    @Assert(budget.admitsRefresh(1u64, 12000), true)
    clock.value += 5000000
    @Assert(budget.admitsRefresh(2u64, 12000), false)
    budget.end()
    let _ = budget.begin()
    @Assert(budget.admitsRefresh(1u64, 12000), false)
    // A deferred projection does not suppress ordinary accepted FIFO work.
    @Assert(budget.admits(4000), true)
    @Assert(budget.admitsRefresh(2u64, 12000), true)
    clock.value += 6000000
    @Assert(budget.remainingMicroseconds(), 10000)
    budget.end()
    let _ = budget.begin()
    @Assert(budget.admitsRefresh(1u64, 12000), true)
    budget.end()
}

@Test
func testClosedRefreshWaiterCannotStrandSibling(): Unit {
    let clock = OwnerBudgetTestClock()
    let budget = CjguiOwnerTurnBudget()
    budget.testUseClock({ => clock.value })
    let _ = budget.begin()
    clock.value += 9000000
    @Assert(budget.admitsRefresh(2u64, 12000), false)
    budget.end()
    let _ = budget.begin()
    @Assert(budget.admitsRefresh(1u64, 12000), false)
    budget.end() // Window 2 closed without re-entering the budget.
    let _ = budget.begin()
    @Assert(budget.admitsRefresh(1u64, 12000), true)
    budget.end()
}

@Test
func testSchedulingDeadlineDoesNotBorrowCreditedResourceIdle(): Unit {
    let clock = OwnerBudgetTestClock()
    let budget = CjguiOwnerTurnBudget()
    budget.testUseClock({ => clock.value })
    let _ = budget.begin()
    let deadline = budget.schedulingDeadlineNs()
    clock.value += 13000000
    @Assert(budget.remainingSchedulingMicroseconds(), 3000)
    clock.value += 10000000
    budget.creditPumpIdle(10000000)
    @Assert(budget.remainingMicroseconds(), 3000)
    @Assert(budget.remainingSchedulingMicroseconds(), 0)
    @Assert(budget.schedulingDeadlineNs(), deadline)
}

@Test
func testSiblingHostsShareOneSchedulingWaitAndOriginalDeadline(): Unit {
    let clock = OwnerBudgetTestClock()
    let budget = CjguiOwnerTurnBudget()
    budget.testUseClock({ => clock.value })
    let state = OwnerSchedulingWaitState()
    budget.testUseSchedulingWait({ _, deadline =>
        state.calls += 1
        state.deadline = deadline
        clock.value += 4000000
        return 4000000
    })
    let _ = budget.begin()
    let originalDeadline = budget.schedulingDeadlineNs()
    clock.value += 12000000
    let sibling = budget
    @Assert(sibling.finishScheduling(), 4000)
    @Assert(budget.finishScheduling(), 0)
    @Assert(state.calls, 1)
    @Assert(state.deadline, originalDeadline)
    @Assert(budget.remainingSchedulingMicroseconds(), 0)
    @Assert(budget.remainingMicroseconds(), 4000)
}

@Test
func testReadyContinuationDoesNotIdleBehindAWorkerWait(): Unit {
    let clock = OwnerBudgetTestClock()
    let budget = CjguiOwnerTurnBudget()
    budget.testUseClock({ => clock.value })
    let state = OwnerSchedulingWaitState()
    budget.testUseSchedulingWait({ _, _ => state.calls += 1; return 0 })
    let _ = budget.begin()
    budget.needsReadyContinuation()
    @Assert(budget.finishScheduling(), 0)
    @Assert(state.calls, 0)
    budget.end()
    let _ = budget.begin()
    let _ = budget.finishScheduling()
    @Assert(state.calls, 1)
}

@Test
func testSiblingAnimationsKeepEarliestSchedulingWake(): Unit {
    let clock = OwnerBudgetTestClock()
    let budget = CjguiOwnerTurnBudget()
    budget.testUseClock({ => clock.value })
    let state = OwnerSchedulingWaitState()
    budget.testUseSchedulingWait({ _, deadline => state.calls += 1; state.deadline = deadline; return 0 })
    let _ = budget.begin()
    clock.value += 1000000
    let earliest = UInt64(clock.value + 8000000)
    budget.limitSchedulingWait(8000)
    clock.value += 3000000
    budget.limitSchedulingWait(8000)
    clock.value += 1000000
    let _ = budget.finishScheduling()
    @Assert(state.calls, 1)
    @Assert(state.deadline, earliest)
    @Assert(state.deadline < budget.schedulingDeadlineNs(), true)
}
