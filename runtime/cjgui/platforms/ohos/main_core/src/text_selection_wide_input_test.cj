package cjgui

import std.unittest.*
import std.unittest.testmacro.*

// The real transaction seam receives the frozen owner choice, independent of
// the focus mirror. Inject a same-value successor at that seam to prove that
// the descriptor callback alone cannot authorize a stale wide replacement.
class WideSelectionInputTestOwner <: CjguiRangeTextSource & CjguiRangeTextEditSink &
    CjguiRangeTextSelectionOwner & CjguiRangeTextSelectionEditSink {
    let owner = SelectionAuthorityTestOwner()
    var successorOnWrite = false
    var atomicCalls: Int64 = 0
    init() {
        owner.body.data = ("HEAD:" + String.fromUtf8(Array<Byte>(4096, repeat: 97u8)) + ":TAIL").toArray()
    }
    public func rangeTextVersion(): Int64 { owner.rangeTextVersion() }
    public func rangeTextByteLength(): Int64 { owner.rangeTextByteLength() }
    public func readRangeText(start: Int64, limit: Int64): CjguiRangeTextSlice {
        owner.readRangeText(start, limit)
    }
    public func confirmRangeTextVersion(version: Int64, action: () -> Bool): Bool {
        owner.confirmRangeTextVersion(version, action)
    }
    public func rebaseRangeTextSelection(version: Int64, start: Int64, end: Int64): ?(Int64, Int64, Int64) {
        owner.rebaseRangeTextSelection(version, start, end)
    }
    public func applyRangeTextEdit(version: Int64, start: Int64, end: Int64,
        text: String): CjguiRangeTextEditOutcome { owner.applyRangeTextEdit(version, start, end, text) }
    public func sourceSelectionSnapshot(): CjguiSourceSelectionSnapshot { owner.sourceSelectionSnapshot() }
    public func setSourceSelection(version: Int64, anchor: Int64, focus: Int64): Bool {
        owner.setSourceSelection(version, anchor, focus)
    }
    public func reserveSourceSelection(version: Int64, revision: Int64, anchor: Int64,
        focus: Int64, decision: CjguiSelectionDecision): Int64 {
        owner.reserveSourceSelection(version, revision, anchor, focus, decision)
    }
    public func settleSourceSelection(revision: Int64): Unit { owner.settleSourceSelection(revision) }
    public func applySourceSelectionEdit(choice: CjguiSourceSelectionSnapshot,
        text: String): CjguiRangeTextEditOutcome {
        atomicCalls += 1
        if (successorOnWrite) {
            successorOnWrite = false
            let _ = owner.setSourceSelection(choice.version, choice.anchorByte, choice.focusByte)
        }
        let current = owner.sourceSelectionSnapshot()
        if (choice.documentId != current.documentId || choice.sessionEpoch != current.sessionEpoch ||
            choice.viewGeneration != current.viewGeneration || choice.version != current.version ||
            choice.revision != current.revision || choice.anchorByte != current.anchorByte ||
            choice.focusByte != current.focusByte) {
            return CjguiRangeTextEditOutcome.rejected(current.version, "source_selection_stale")
        }
        let lo = if (choice.anchorByte < choice.focusByte) { choice.anchorByte } else { choice.focusByte }
        let hi = if (choice.anchorByte > choice.focusByte) { choice.anchorByte } else { choice.focusByte }
        if (!cjguiIsUtf8Boundary(owner.body.data, lo) || !cjguiIsUtf8Boundary(owner.body.data, hi)) {
            return CjguiRangeTextEditOutcome.rejected(current.version, CJGUI_RANGE_TEXT_REASON_NOT_BOUNDARY)
        }
        return owner.applyRangeTextEdit(choice.version, lo, hi, text)
    }
}

func wideSelectionInputTestSession(owner: WideSelectionInputTestOwner): CjguiTextSession {
    let session = CjguiTextSession(CjguiRangeTextWindow(1001, "wide-choice", owner, owner,
        materializeLimit: 32))
    session.bind()
    @Assert(session.prepareSourceRange(1, 4101, 4101).isSome(), true)
    @Assert(owner.setSourceSelection(1, 5, 4101), true)
    return session
}

@Test
func wideSelectionInputKeepsGlobalChoiceAndOriginalFifoExactlyOnce(): Unit {
    let owner = WideSelectionInputTestOwner()
    let session = wideSelectionInputTestSession(owner)
    let selected = owner.sourceSelectionSnapshot()
    let first = session.submitAuthorizedSelectionRange(81u64, 1u64, 1u64, 0u64,
        selected.version, selected.revision, selected.anchorByte, selected.focusByte, "中", { => true })
    @Assert(first.accepted, true)
    @Assert(owner.owner.body.text(), "HEAD:中:TAIL")
    @Assert(owner.atomicCalls, 1)
    @Assert(owner.owner.body.writeCalls, 1)
    @Assert(owner.owner.body.maxReadBytes <= 36, true)
    let duplicate = session.submitAuthorizedSelectionRange(81u64, 1u64, 1u64, 0u64,
        selected.version, selected.revision, selected.anchorByte, selected.focusByte, "中", { => true })
    @Assert(duplicate.ticket, first.ticket)
    @Assert(owner.atomicCalls, 1)
    let conflict = session.submitAuthorizedSelectionRange(81u64, 1u64, 1u64, 0u64,
        selected.version, selected.revision, selected.anchorByte, selected.focusByte, "X", { => true })
    @Assert(conflict.reason, "selection_input_id_conflict")
    @Assert(session.acknowledge(first.ticket, first.contextEpoch), true)
    @Assert(session.acknowledgeAuthorizedSelectionInput(81u64, 1u64), true)
    @Assert(session.acknowledgeAuthorizedSelectionInput(81u64, 1u64), true)
    @Assert(owner.owner.body.writeCalls, 1)
    let nextChoice = owner.sourceSelectionSnapshot()
    let next = session.submitAuthorizedSelectionRange(81u64, 2u64, 2u64, 1u64,
        nextChoice.version, nextChoice.revision, nextChoice.anchorByte, nextChoice.focusByte, "续", { => true })
    @Assert(next.accepted, true)
    @Assert(owner.owner.body.text(), "HEAD:中续:TAIL")
    @Assert(owner.owner.body.writeCalls, 2)
    let late = session.submitAuthorizedSelectionRange(81u64, 1u64, 1u64, 0u64,
        selected.version, selected.revision, selected.anchorByte, selected.focusByte, "中", { => true })
    @Assert(late.accepted, false)
    @Assert(owner.owner.body.writeCalls, 2)
}

@Test
func wideSelectionInputAtomicWriterRejectsSameValueSuccessor(): Unit {
    let owner = WideSelectionInputTestOwner()
    let session = wideSelectionInputTestSession(owner)
    let selected = owner.sourceSelectionSnapshot()
    owner.successorOnWrite = true
    let rejected = session.submitAuthorizedSelectionRange(82u64, 1u64, 1u64, 0u64,
        selected.version, selected.revision, selected.anchorByte, selected.focusByte, "X", { => true })
    @Assert(rejected.accepted, false)
    @Assert(rejected.reason, "source_selection_stale")
    @Assert(owner.atomicCalls, 1)
    @Assert(owner.owner.body.writeCalls, 0)
    @Assert(owner.owner.body.data.size, 4106)
}

@Test
func wideSelectionInputCannotWidenAnOrdinaryLocalSink(): Unit {
    let owner = SelectionAuthorityTestOwner()
    owner.body.data = String.fromUtf8(Array<Byte>(4096, repeat: 97u8)).toArray()
    let session = selectionAuthorityTestSession(owner, materializeLimit: 32)
    @Assert(owner.setSourceSelection(1, 3, 4000), true)
    let selected = owner.sourceSelectionSnapshot()
    let refused = session.submitAuthorizedSelectionRange(83u64, 1u64, 1u64, 0u64,
        selected.version, selected.revision, selected.anchorByte, selected.focusByte, "X", { => true })
    @Assert(refused.accepted, false)
    @Assert(refused.reason, "source_selection_edit_unavailable")
    @Assert(owner.body.writeCalls, 0)
}
