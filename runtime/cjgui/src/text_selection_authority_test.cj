package cjgui

import std.unittest.*
import std.unittest.testmacro.*

// This fixture tests the framework/owner seam, not AppKit installation. Native
// installation and rollback use their own production-entry counterexamples.
class SelectionAuthorityTestDecision <: CjguiSelectionDecision {
    var value: Int64 = 1
    public override func state(): Int64 { return value }
    public override func admitWriter(): Bool {
        if (value == 1) { value = 4; return true }
        return value == 3 || value == 4
    }
}

class SelectionAuthorityTestOwner <: CjguiRangeTextSource & CjguiRangeTextEditSink & CjguiRangeTextSelectionOwner {
    let body = FakeTextOwner("alpha bravo\n\ncharlie delta\n")
    var revision: Int64 = 1
    var nextRevision: Int64 = 2
    var anchor: Int64 = 0
    var focus: Int64 = 0
    var pendingRevision: Int64 = -1
    var pendingAnchor: Int64 = 0
    var pendingFocus: Int64 = 0
    var port: ?CjguiSelectionDecision = None
    var guardActive = false
    var successorAfterFold = false

    public func rangeTextVersion(): Int64 { body.rangeTextVersion() }
    public func rangeTextByteLength(): Int64 { body.rangeTextByteLength() }
    public func readRangeText(start: Int64, limit: Int64): CjguiRangeTextSlice { body.readRangeText(start, limit) }
    public func rebaseRangeTextSelection(version: Int64, start: Int64, end: Int64): ?(Int64, Int64, Int64) {
        body.rebaseRangeTextSelection(version, start, end)
    }
    public func confirmRangeTextVersion(version: Int64, action: () -> Bool): Bool {
        if (version != body.ver) { return false }
        guardActive = true
        try { return action() } finally { guardActive = false }
    }
    public func applyRangeTextEdit(version: Int64, start: Int64, end: Int64, text: String): CjguiRangeTextEditOutcome {
        body.applyRangeTextEdit(version, start, end, text)
    }
    public func sourceSelectionSnapshot(): CjguiSourceSelectionSnapshot {
        if (let Some(p) <- port) {
            if (p.state() == 3) {
                return CjguiSourceSelectionSnapshot(body.ver, pendingRevision, pendingAnchor, pendingFocus,
                    documentId: "test-authority", sessionEpoch: 1, viewGeneration: 1)
            }
        }
        return CjguiSourceSelectionSnapshot(body.ver, revision, anchor, focus,
            documentId: "test-authority", sessionEpoch: 1, viewGeneration: 1)
    }
    public func setSourceSelection(version: Int64, a: Int64, f: Int64): Bool {
        let total = Int64(body.data.size)
        if (version != body.ver || a < 0 || f < 0 || a > total || f > total) { return false }
        if (let Some(p) <- port) { if (!p.admitWriter()) { return false } }
        anchor = a; focus = f; revision = nextRevision; nextRevision += 1
        return true
    }
    public func reserveSourceSelection(version: Int64, expectedRevision: Int64, a: Int64,
        f: Int64, decision: CjguiSelectionDecision): Int64 {
        let total = Int64(body.data.size)
        if (version != body.ver || expectedRevision != revision || port.isSome() ||
            a < 0 || f < 0 || a > total || f > total) { return -1 }
        pendingRevision = nextRevision
        nextRevision += 1
        pendingAnchor = a; pendingFocus = f; port = Some(decision)
        return pendingRevision
    }
    public func settleSourceSelection(expectedRevision: Int64): Unit {
        if (let Some(p) <- port) {
            if (p.state() == 3 && expectedRevision == pendingRevision) {
                anchor = pendingAnchor; focus = pendingFocus; revision = pendingRevision
                pendingRevision = -1; port = None
                if (successorAfterFold) { let _ = setSourceSelection(body.ver, 2, 2) }
            } else if (p.state() == 4) { port = None; pendingRevision = -1 }
        }
    }
}

/// Mirrors the production owner's monotonic reservation sequence: abort folds
/// back to the visible A revision, but does not reuse the consumed B revision.
/// This keeps the counterexample isolated from the compact fixture above.
class SelectionAuthorityJumpOwner <: CjguiRangeTextSource & CjguiRangeTextEditSink &
    CjguiRangeTextSelectionOwner {
    let body = FakeTextOwner("alpha bravo\n\ncharlie delta\n")
    var visibleRevision: Int64 = 1
    var nextRevision: Int64 = 2
    var anchor: Int64 = 0
    var focus: Int64 = 0
    var pendingRevision: Int64 = -1
    var lastReservedRevision: Int64 = -1
    var pendingAnchor: Int64 = 0
    var pendingFocus: Int64 = 0
    var port: ?CjguiSelectionDecision = None
    var lastSettledRevision: Int64 = -1
    var foldCount: Int64 = 0
    var portRetired = false
    var installCalls: Int64 = 0
    var installReceiptRevision: Int64 = -1

    public func rangeTextVersion(): Int64 { body.rangeTextVersion() }
    public func rangeTextByteLength(): Int64 { body.rangeTextByteLength() }
    public func readRangeText(start: Int64, limit: Int64): CjguiRangeTextSlice {
        body.readRangeText(start, limit)
    }
    public func rebaseRangeTextSelection(version: Int64, start: Int64, end: Int64): ?(Int64, Int64, Int64) {
        body.rebaseRangeTextSelection(version, start, end)
    }
    public func confirmRangeTextVersion(version: Int64, action: () -> Bool): Bool {
        if (version != body.ver) { return false }
        return action()
    }
    public func applyRangeTextEdit(version: Int64, start: Int64, end: Int64,
        text: String): CjguiRangeTextEditOutcome {
        body.applyRangeTextEdit(version, start, end, text)
    }
    public func sourceSelectionSnapshot(): CjguiSourceSelectionSnapshot {
        if (let Some(decision) <- port) {
            if (decision.state() == 3 && !portRetired) {
                return CjguiSourceSelectionSnapshot(body.ver, pendingRevision,
                    pendingAnchor, pendingFocus, documentId: "jump-test", sessionEpoch: 1,
                    viewGeneration: 1)
            }
        }
        return CjguiSourceSelectionSnapshot(body.ver, visibleRevision, anchor, focus,
            documentId: "jump-test", sessionEpoch: 1, viewGeneration: 1)
    }
    public func setSourceSelection(version: Int64, anchorByte: Int64, focusByte: Int64): Bool {
        let total = Int64(body.data.size)
        if (version != body.ver || anchorByte < 0 || focusByte < 0 ||
            anchorByte > total || focusByte > total || port.isSome()) { return false }
        anchor = anchorByte
        focus = focusByte
        visibleRevision = nextRevision
        nextRevision += 1
        return true
    }
    public func reserveSourceSelection(version: Int64, expectedRevision: Int64,
        anchorByte: Int64, focusByte: Int64, decision: CjguiSelectionDecision): Int64 {
        let total = Int64(body.data.size)
        if (version != body.ver || expectedRevision != visibleRevision || port.isSome() ||
            anchorByte < 0 || focusByte < 0 || anchorByte > total || focusByte > total) {
            return -1
        }
        pendingRevision = nextRevision
        lastReservedRevision = pendingRevision
        nextRevision += 1
        pendingAnchor = anchorByte
        pendingFocus = focusByte
        port = Some(decision)
        return pendingRevision
    }
    public func settleSourceSelection(revision: Int64): Unit {
        lastSettledRevision = revision
        if (let Some(decision) <- port) {
            if (decision.state() == 3 && revision == pendingRevision) {
                anchor = pendingAnchor
                focus = pendingFocus
                visibleRevision = pendingRevision
                port = None
                pendingRevision = -1
                foldCount += 1
            } else if (decision.state() == 4) {
                port = None
                pendingRevision = -1
            }
        }
    }
    /// Simulate the framework retiring the native decision cell after commit.
    /// An unfurled owner memo then reads Closed and therefore resolves to A.
    func retireCommittedPort(): Unit {
        portRetired = true
    }
}

func selectionAuthorityTestSession(owner: SelectionAuthorityTestOwner,
    materializeLimit!: Int64 = 65536): CjguiTextSession {
    let window = CjguiRangeTextWindow(1001, "authority-test", owner, owner,
        materializeLimit: materializeLimit)
    let session = CjguiTextSession(window)
    session.bind()
    return session
}

@Test
func selectionAuthorityCommitIsVisibleBeforeFoldAndCannotBecomeRejectionAfterSuccessor(): Unit {
    let owner = SelectionAuthorityTestOwner()
    let session = selectionAuthorityTestSession(owner)
    let ticket = session.freezeSelectionTicket()
    let decision = SelectionAuthorityTestDecision()
    owner.successorAfterFold = true
    let accepted = session.commitReservedSelectionTicket(ticket, 17, 5, decision, { _ =>
        @Assert(owner.guardActive, false)
        decision.value = 2
        @Assert(session.plainSelectionAnchorValue(), 0)
        decision.value = 3
        @Assert(session.plainSelectionAnchorValue(), 17)
        @Assert(session.plainSelectionFocusValue(), 5)
        @Assert(session.selectionRevisionValue(), ticket.selectionRevision + 1)
    })
    @Assert(accepted, true)
    @Assert(session.plainSelectionAnchorValue(), 2)
    @Assert(session.plainSelectionFocusValue(), 2)
    @Assert(owner.body.writeCalls, 0)
}

@Test
func selectionAuthorityAbortedInstallKeepsAAndSameValueNewChoiceInvalidatesTicket(): Unit {
    let owner = SelectionAuthorityTestOwner()
    let session = selectionAuthorityTestSession(owner)
    let ticket = session.freezeSelectionTicket()
    let decision = SelectionAuthorityTestDecision()
    @Assert(session.commitReservedSelectionTicket(ticket, 5, 17, decision, { _ => decision.value = 4 }), false)
    @Assert(session.plainSelectionAnchorValue(), 0)
    @Assert(session.selectionTicketMatches(ticket), true)
    session.setSelection16(0, 0)
    @Assert(session.selectionTicketMatches(ticket), false)
    @Assert(owner.body.writeCalls, 0)
}

@Test
func sourceWholeSelectionCommitsNewOwnerRevisionAndRevokesSameValueChoice(): Unit {
    let owner = SelectionAuthorityTestOwner()
    owner.body.data = "0123456789abcdefghijklmnopqrstuvwxyz".toArray()
    let session = selectionAuthorityTestSession(owner, materializeLimit: 8)
    let ticket = session.freezeSelectionTicket()
    let total = Int64(owner.body.data.size)
    let firstDecision = SelectionAuthorityTestDecision()
    let first = session.commitReservedSourceSelectionTicket(ticket, 0, total, firstDecision, { _ =>
        firstDecision.value = 3
    })
    @Assert(first, true)
    let accepted = owner.sourceSelectionSnapshot()
    @Assert(accepted.version, 1)
    @Assert(accepted.anchorByte, 0)
    @Assert(accepted.focusByte, total)
    @Assert(accepted.revision, ticket.selectionRevision + 1)
    @Assert(owner.body.writeCalls, 0)
    @Assert(owner.body.maxReadBytes <= 8, true)

    let whole = session.wholeDocumentChoiceForCurrentSelection(1).getOrThrow()
    @Assert(whole.byteLength, total)
    @Assert(whole.isCurrent(), true)
    let sameValueTicket = session.freezeSelectionTicket()
    let sameValueDecision = SelectionAuthorityTestDecision()
    let sameValue = session.commitReservedSourceSelectionTicket(sameValueTicket, 0, total,
        sameValueDecision, { _ => sameValueDecision.value = 3 })
    @Assert(sameValue, true)
    @Assert(owner.sourceSelectionSnapshot().revision, accepted.revision + 1)
    @Assert(whole.isCurrent(), false)
    @Assert(owner.body.writeCalls, 0)
}

@Test
func globalSourceReservationOutsideEightByteMirrorCommitsOrRestoresA(): Unit {
    let owner = SelectionAuthorityTestOwner()
    owner.body.data = "0123456789abcdefghijklmnopqrstuvwxyz".toArray()
    let session = selectionAuthorityTestSession(owner, materializeLimit: 8)
    let ticket = session.freezeSelectionTicket()
    let total = Int64(owner.body.data.size)
    let before = owner.sourceSelectionSnapshot()

    let cancelledDecision = SelectionAuthorityTestDecision()
    let cancelled = session.commitReservedSourceSelectionTicket(ticket, 0, total,
        cancelledDecision, { _ => cancelledDecision.value = 4 })
    @Assert(cancelled, false)
    let afterCancel = owner.sourceSelectionSnapshot()
    @Assert(afterCancel.revision, before.revision)
    @Assert(afterCancel.anchorByte, before.anchorByte)
    @Assert(afterCancel.focusByte, before.focusByte)
    @Assert(session.selectionTicketMatches(ticket), true)
    @Assert(owner.body.writeCalls, 0)

    let committedDecision = SelectionAuthorityTestDecision()
    let committed = session.commitReservedSourceSelectionTicket(ticket, 0, total,
        committedDecision, { _ => committedDecision.value = 3 })
    @Assert(committed, true)
    let selected = owner.sourceSelectionSnapshot()
    @Assert(selected.anchorByte, 0)
    @Assert(selected.focusByte, total)
    @Assert(selected.revision, before.revision + 2)
    @Assert(owner.body.maxReadBytes <= 8, true)
    @Assert(owner.body.writeCalls, 0)
}

@Test
func selectionReservationRevisionJumpSurvivesNativePortRetirement(): Unit {
    let owner = SelectionAuthorityJumpOwner()
    let window = CjguiRangeTextWindow(1001, "authority-jump-test", owner, owner)
    let session = CjguiTextSession(window)
    session.bind()
    let firstTicket = session.freezeSelectionTicket()
    let aborted = SelectionAuthorityTestDecision()
    @Assert(session.commitReservedSourceSelectionTicket(firstTicket, 2, 9, aborted, { _ =>
        aborted.value = 4
    }), false)
    @Assert(owner.sourceSelectionSnapshot().revision, firstTicket.selectionRevision)
    @Assert(owner.nextRevision, firstTicket.selectionRevision + 2)

    // The abort consumed a revision. The next reservation must publish its
    // actual revision rather than assuming ticket.selectionRevision + 1.
    let ticket = session.freezeSelectionTicket()
    let committedDecision = SelectionAuthorityTestDecision()
    let committed = session.commitReservedSourceSelectionTicket(ticket, 5, 13, committedDecision, { reservedRevision =>
        owner.installCalls += 1
        owner.installReceiptRevision = reservedRevision
        @Assert(reservedRevision, owner.lastReservedRevision)
        committedDecision.value = 3
    })
    @Assert(committed, true)
    @Assert(owner.installCalls, 1)
    @Assert(owner.installReceiptRevision, owner.lastReservedRevision)
    @Assert(owner.lastReservedRevision, ticket.selectionRevision + 2)
    @Assert(owner.lastSettledRevision, owner.lastReservedRevision)
    @Assert(owner.foldCount, 1)
    let accepted = owner.sourceSelectionSnapshot()
    @Assert(accepted.anchorByte, 5)
    @Assert(accepted.focusByte, 13)
    @Assert(accepted.revision, owner.lastReservedRevision)

    owner.retireCommittedPort()
    let afterRetirement = owner.sourceSelectionSnapshot()
    @Assert(afterRetirement.anchorByte, 5)
    @Assert(afterRetirement.focusByte, 13)
    @Assert(afterRetirement.revision, owner.lastReservedRevision)
    let sameChoiceTicket = session.freezeSelectionTicket()
    @Assert(owner.setSourceSelection(owner.body.ver, 5, 13), true)
    @Assert(owner.sourceSelectionSnapshot().revision, accepted.revision + 1)
    @Assert(session.selectionTicketMatches(sameChoiceTicket), false)
    @Assert(owner.body.writeCalls, 0)
}

@Test
func authorizedWholeOwnerReplacementUsesBoundedReadsOnceAndRejectsOldChoiceAfterNewSelection(): Unit {
    let owner = SelectionAuthorityTestOwner()
    owner.body.data = "0123456789abcdefghijklmnopqrstuvwxyz".toArray()
    let session = selectionAuthorityTestSession(owner, materializeLimit: 8)
    let ticket = session.freezeSelectionTicket()
    let total = Int64(owner.body.data.size)
    let decision = SelectionAuthorityTestDecision()
    @Assert(session.commitReservedSourceSelectionTicket(ticket, 0, total, decision, { _ =>
        decision.value = 3
    }), true)
    let whole = session.wholeDocumentChoiceForCurrentSelection(1).getOrThrow()
    let first = session.submitAuthorizedSelectionRange(101u64, 1u64, 1u64, 0u64,
        whole.contentVersion, whole.selectionRevision, 0, total, "X", { => whole.isCurrent() })
    @Assert(first.accepted, true)
    @Assert(owner.body.data.size, 1)
    @Assert(String.fromUtf8(owner.body.data), "X")
    @Assert(owner.body.writeCalls, 1)
    @Assert(owner.body.maxReadBytes <= 8, true)
    @Assert(whole.isCurrent(), false)

    session.setSelection16(0, 0)
    let stale = session.submitAuthorizedSelectionRange(101u64, 2u64, 2u64, 1u64,
        2, whole.selectionRevision, 0, total, "Y", { => whole.isCurrent() })
    @Assert(stale.accepted, false)
    @Assert(stale.reason, "selection_input_choice_stale")
    @Assert(String.fromUtf8(owner.body.data), "X")
    @Assert(owner.body.writeCalls, 1)
}
