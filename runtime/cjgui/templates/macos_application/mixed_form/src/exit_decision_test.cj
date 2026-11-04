// A4 controlled counterexample: the mixed application exit provider consults
// every live window's existing close decision; one refusal means ZERO closes.
package cjgui_mixed_form_starter

class FakeExitWindow <: MixedExitWindowDecision {
    public var open: Bool = true
    public var allow: Bool
    public var decisions: Int64 = 0
    public var closes: Int64 = 0
    public var clears: Int64 = 0
    init(allow: Bool) { this.allow = allow }
    public func isOpen(): Bool { return open }
    public func requestCloseDecision(): Bool {
        decisions += 1
        if (!allow) { return false }
        // A decision is only a decision: it may NOT close the window.
        return true
    }
    public func clearCloseDecision(): Unit { clears += 1 }
}

class FakeExitCancellationCounter {
    var count: Int64 = 0
    func cancel(): Unit { count += 1 }
}

@Test
func mixedExitProviderStopsAtFirstRefusalWithoutClosingAnything(): Unit {
    let first = FakeExitWindow(true)
    let second = FakeExitWindow(false)
    let provider = MixedApplicationExitDecision()
    provider.attachForTest(first)
    provider.attachForTest(second)
    @Assert(provider.requestApplicationExit(), false)
    @Assert(first.decisions, 1)
    @Assert(second.decisions, 1)
    @Assert(first.closes + second.closes, 0)
    @Assert(first.clears + second.clears, 0)
    // Cancel is the consumer's action; no close intent survives the refusal.
    @Assert(first.open && second.open, true)
    // A later explicit save/make-clean retried through the SAME entry allows.
    second.allow = true
    @Assert(provider.requestApplicationExit(), true)
    @Assert(first.decisions, 2)
    @Assert(second.decisions, 2)
    @Assert(first.closes + second.closes, 0)
    @Assert(first.clears + second.clears, 0)
    provider.applicationExitDidCommit()
    @Assert(first.clears, 1)
    @Assert(second.clears, 1)
}

@Test
func mixedExitProviderCancelRevokesEveryParticipant(): Unit {
    let first = FakeExitWindow(true)
    let second = FakeExitWindow(false)
    let provider = MixedApplicationExitDecision()
    provider.attachForTest(first)
    provider.attachForTest(second)
    @Assert(provider.requestApplicationExit(), false)
    @Assert(first.clears + second.clears, 0)
    provider.cancelIntent()
    @Assert(first.clears, 1)
    @Assert(second.clears, 1)
    provider.cancelIntent()
    @Assert(first.clears, 1)
    @Assert(first.closes + second.closes, 0)
}

@Test
func mixedExitProviderRetiresClosedControllersAndCountsOnlyLive(): Unit {
    let first = FakeExitWindow(true)
    let retired = FakeExitWindow(false)
    retired.open = false
    let provider = MixedApplicationExitDecision()
    provider.attachForTest(first)
    provider.attachForTest(retired)
    @Assert(provider.requestApplicationExit(), true)
    @Assert(first.decisions, 1)
    // Closed participants are pruned before a decision; they are never
    // consulted and do not inflate the allowed live count.
    @Assert(retired.decisions, 0)
    first.open = false
    let reopened = FakeExitWindow(true)
    provider.attachForTest(reopened)
    @Assert(provider.requestApplicationExit(), true)
    @Assert(reopened.decisions, 1)
    @Assert(first.decisions, 1)
}

@Test
func mixedExitApprovalRemainsUntilCommitOrExplicitCancel(): Unit {
    let window = FakeExitWindow(true)
    let provider = MixedApplicationExitDecision()
    let pendingCancelled = FakeExitCancellationCounter()
    provider.bindPendingCancellation({ => pendingCancelled.cancel() })
    provider.attachForTest(window)
    @Assert(provider.requestApplicationExit(), true)
    @Assert(window.clears, 0)
    @Assert(provider.requestApplicationExit(), true)
    @Assert(window.clears, 0)
    window.allow = false
    @Assert(provider.requestApplicationExit(), false)
    @Assert(window.clears, 0)
    provider.cancelIntent()
    @Assert(window.clears, 1)
    @Assert(pendingCancelled.count, 1)
}
