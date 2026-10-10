package cjgui

import std.unittest.*
import std.unittest.testmacro.*

@Test
func ownerAppliedReceiptSurvivesAckAndRefusalWithoutInventingAnotherWrite(): Unit {
    let owner = FakeTextOwner("abc\nfooter")
    let session = makeSession(owner)
    @Assert(session.internalLatestAppliedEdit().isNone(), true)
    let first = session.prepareSourceRange(1, 1, 2).getOrThrow().replace("")
    @Assert(first.accepted, true)
    @Assert(session.acknowledge(first.ticket, first.contextEpoch), true)
    let retained = session.internalLatestAppliedEdit().getOrThrow()
    @Assert(retained.ticket, first.ticket)
    @Assert(retained.versionAfter, 2)
    @Assert(retained.seq, 1)
    owner.rejectAll = true
    let refused = session.prepareSourceRange(2, 0, 1).getOrThrow().replace("")
    @Assert(refused.accepted, false)
    @Assert(session.internalLatestAppliedEdit().getOrThrow().ticket, first.ticket)
    @Assert(owner.text(), "ac\nfooter")
    @Assert(session.currentEditSeq(), 1)
    owner.rejectAll = false
    let second = session.selectWholeDocument(2).getOrThrow().replace("new")
    @Assert(second.accepted, true)
    @Assert(session.internalLatestAppliedEdit().getOrThrow().ticket, second.ticket)
    @Assert(retained.versionAfter, 2)
    @Assert(retained.seq, 1)
    @Assert(session.currentEditSeq(), 2)
}

@Test
func ownerAppliedReceiptExpiresAtBindingAndExternalWritesDoNotManufactureIt(): Unit {
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    let applied = session.prepareSourceRange(1, 1, 2).getOrThrow().replace("")
    let retained = session.internalLatestAppliedEdit().getOrThrow()
    owner.externalWrite(0, 0, "!")
    let _ = session.contentVersion()
    @Assert(session.internalLatestAppliedEdit().getOrThrow().ticket, applied.ticket)
    @Assert(retained.versionAfter, 2)
    session.invalidate()
    @Assert(session.internalLatestAppliedEdit().isNone(), true)
    session.bind()
    @Assert(session.internalLatestAppliedEdit().isNone(), true)
    @Assert(session.currentEditSeq(), 0)
}
