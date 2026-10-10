package cjgui

import std.unittest.*
import std.unittest.testmacro.*

class InstalledRangeRaceOwner <: CjguiRangeTextSource & CjguiRangeTextEditSink {
    let owner: FakeTextOwner
    var raceAfterAccept: Bool = false
    var insideVersionGuard: Bool = false
    init(text: String) { owner = FakeTextOwner(text) }
    public func rangeTextVersion(): Int64 { owner.rangeTextVersion() }
    public func rangeTextByteLength(): Int64 { owner.rangeTextByteLength() }
    public func readRangeText(start: Int64, limit: Int64): CjguiRangeTextSlice { owner.readRangeText(start, limit) }
    public func rebaseRangeTextSelection(version: Int64, start: Int64, end: Int64): ?(Int64, Int64, Int64) {
        owner.rebaseRangeTextSelection(version, start, end)
    }
    public func confirmRangeTextVersion(version: Int64, action: () -> Bool): Bool {
        if (owner.ver != version) { return false }
        insideVersionGuard = true
        try { return action() } finally { insideVersionGuard = false }
    }
    public func applyRangeTextEdit(version: Int64, start: Int64, end: Int64, text: String): CjguiRangeTextEditOutcome {
        let receipt = owner.applyRangeTextEdit(version, start, end, text)
        if (receipt.applied && raceAfterAccept) {
            raceAfterAccept = false
            owner.externalWrite(0, 0, "Agent:")
        }
        return receipt
    }
}

func installedInput(b: CjguiInstalledRangeBasis, body: String, seq: UInt64, previous: UInt64,
    start: Int64, end: Int64): CjguiInstalledRangeInput {
    return CjguiInstalledRangeInput(b, 17, seq, previous, 0, b.ownerVersion, body, start, end)
}

@Test
func testInstalledRangeContinuousPrefixUsesActualOwnerReceipts(): Unit {
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    let basis = session.freezeInstalledRangeBasis(1, 41, 3).getOrThrow()
    @Assert(session.activateInstalledRangeBasis(basis, 17))
    // A new semantic selection is pending; the public alignment gate stays shut.
    session.setSelection16(2, 2)
    let semantic = session.freezeSelectionTicket()
    let _ = session.handlePlainIntent(MoveLeft)
    @Assert(!session.replaceRange16(3, 3, "!").accepted)
    // Both native ranges were captured before pumping, so both observed ACK=0/v1.
    let x = session.submitInstalledRange16(installedInput(basis, "abc", 1, 0, 3, 3), "X")
    let y = session.submitInstalledRange16(installedInput(basis, "abcX", 2, 1, 4, 4), "Y")
    @Assert(x.accepted); @Assert(y.accepted)
    @Assert(x.versionAfter, 2); @Assert(y.versionAfter, 3)
    @Assert(owner.text(), "abcXY"); @Assert(owner.writeCalls, 2)
    @Assert(!session.selectionTicketMatches(semantic))
    @Assert(!session.replaceRange16(5, 5, "!").accepted)
    let replay = session.submitInstalledRange16(installedInput(basis, "abcX", 2, 1, 4, 4), "Y")
    @Assert(!replay.accepted); @Assert(owner.writeCalls, 2)
}

@Test
func testInstalledRangeExternalVersionRejectsBeforeSinkAndClosesSuffix(): Unit {
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    let basis = session.freezeInstalledRangeBasis(2, 41, 3).getOrThrow()
    @Assert(session.activateInstalledRangeBasis(basis, 17))
    let x = session.submitInstalledRange16(installedInput(basis, "abc", 1, 0, 3, 3), "X")
    @Assert(x.accepted)
    owner.externalWrite(0, 0, "Agent:")
    let y = session.submitInstalledRange16(installedInput(basis, "abcX", 2, 1, 4, 4), "Y")
    @Assert(!y.accepted); @Assert(y.reason, "version_conflict")
    let z = session.submitInstalledRange16(installedInput(basis, "abcXY", 3, 2, 5, 5), "Z")
    @Assert(!z.accepted); @Assert(owner.writeCalls, 1)
    @Assert(owner.text(), "Agent:abcX")
}

@Test
func testInstalledRangeOutOfOrderAndRebindingCannotWrite(): Unit {
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    let basis = session.freezeInstalledRangeBasis(3, 41, 3).getOrThrow()
    @Assert(session.activateInstalledRangeBasis(basis, 17))
    let y = session.submitInstalledRange16(installedInput(basis, "abcX", 2, 1, 4, 4), "Y")
    @Assert(!y.accepted); @Assert(owner.writeCalls, 0)
    session.invalidate()
    session.bind()
    let x = session.submitInstalledRange16(installedInput(basis, "abc", 1, 0, 3, 3), "X")
    @Assert(!x.accepted); @Assert(x.reason, "installed_range_stale_binding")
    @Assert(owner.text(), "abc")
    @Assert(!session.activateInstalledRangeBasis(basis, 17))
}

@Test
func testInstalledRangeMapsOldScopeAfterCurrentMirrorMoves(): Unit {
    let owner = FakeTextOwner("abcDEFGHabcIJKLMabcNOPQRabcSTUVW")
    let session = makeSession(owner, materializeLimit: 8)
    let basis = session.freezeInstalledRangeBasis(4, 41, 3).getOrThrow()
    @Assert(session.activateInstalledRangeBasis(basis, 17))
    let oldBody = basis.text
    let _ = session.revealByte(24)
    @Assert(session.mirrorSnapshot().startByte > basis.sourceStart)
    let edit = session.submitInstalledRange16(installedInput(basis, oldBody, 1, 0, 0, 3), "OLD")
    @Assert(edit.accepted)
    @Assert(owner.text(), "OLDDEFGHabcIJKLMabcNOPQRabcSTUVW")
    @Assert(owner.writeCalls, 1)
    @Assert(owner.maxReadBytes <= 8)
}

@Test
func testInstalledRangeRejectsActualPostMismatchBeforeOwner(): Unit {
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    let basis = session.freezeInstalledRangeBasis(5, 41, 3).getOrThrow()
    @Assert(session.activateInstalledRangeBasis(basis, 17))
    let edit = session.submitInstalledRange16(installedInput(basis, "abc", 1, 0, 3, 3), "X",
        actualPostBody: Some("abcOther"))
    @Assert(!edit.accepted); @Assert(edit.reason, "installed_range_post_body_mismatch")
    @Assert(owner.text(), "abc"); @Assert(owner.writeCalls, 0)
}

@Test
func testSelectionInstallRunsOutsideOwnerVersionGuardAndRechecks(): Unit {
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    let ticket = session.freezeSelectionTicket()
    let ok = session.commitSelectionTicket(ticket, 1, 1, { =>
        owner.bumpVersionOnly()
        return true
    })
    @Assert(!ok)
    @Assert(session.selection16()[0], 0)
    @Assert(session.selection16()[1], 0)
    @Assert(owner.writeCalls, 0)
}

@Test
func testInstalledRangeKeepsAcceptedReceiptWhenRefreshReadsLaterOwner(): Unit {
    let owner = InstalledRangeRaceOwner("abc")
    let session = CjguiTextSession(CjguiRangeTextWindow(1001, "plain-text", owner, owner))
    session.bind()
    let basis = session.freezeInstalledRangeBasis(6, 41, 3).getOrThrow()
    @Assert(session.activateInstalledRangeBasis(basis, 17))
    owner.raceAfterAccept = true
    let x = session.submitInstalledRange16(installedInput(basis, "abc", 1, 0, 3, 3), "X")
    @Assert(x.accepted); @Assert(x.versionAfter, 2)
    @Assert(owner.owner.ver, 3)
    let y = session.submitInstalledRange16(installedInput(basis, "abcX", 2, 1, 4, 4), "Y")
    @Assert(!y.accepted); @Assert(owner.owner.writeCalls, 1)
    @Assert(owner.owner.text(), "Agent:abcX")
}

@Test
func testSelectionInstallNeverRunsInsideOwnerGuard(): Unit {
    let owner = InstalledRangeRaceOwner("abc")
    let session = CjguiTextSession(CjguiRangeTextWindow(1001, "plain-text", owner, owner))
    session.bind()
    let ticket = session.freezeSelectionTicket()
    let installed = session.commitSelectionTicket(ticket, 1, 1, { =>
        @Assert(!owner.insideVersionGuard)
        return true
    })
    @Assert(installed)
    @Assert(session.selection16()[0], 1)
    @Assert(session.selection16()[1], 1)
}

@Test
func testFullMaterializedWindowCanAcceptTwoSmallInputs(): Unit {
    let body = String.fromUtf8(Array<UInt8>(65536, repeat: 0x61u8))
    let owner = FakeTextOwner(body)
    let session = makeSession(owner)
    let basis = session.freezeInstalledRangeBasis(7, 41, 3).getOrThrow()
    @Assert(session.activateInstalledRangeBasis(basis, 17))
    let x = session.submitInstalledRange16(installedInput(basis, body, 1, 0, 65536, 65536), "X")
    let y = session.submitInstalledRange16(installedInput(basis, body + "X", 2, 1, 65537, 65537), "Y")
    @Assert(x.accepted); @Assert(y.accepted)
    @Assert(owner.writeCalls, 2); @Assert(owner.ver, 3)
    @Assert(owner.text(), body + "XY")
    @Assert(owner.maxReadBytes <= 65536)
}

@Test
func testInstalledRangePayloadBudgetRejectsBeforeOwner(): Unit {
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    let basis = session.freezeInstalledRangeBasis(8, 41, 3).getOrThrow()
    @Assert(session.activateInstalledRangeBasis(basis, 17))
    let tooLarge = String.fromUtf8(Array<UInt8>(1024 * 1024, repeat: 0x61u8))
    let rejected = session.submitInstalledRange16(installedInput(basis, "abc", 1, 0, 3, 3), tooLarge)
    @Assert(!rejected.accepted); @Assert(rejected.reason, CJGUI_RANGE_TEXT_REASON_BUDGET)
    @Assert(owner.writeCalls, 0); @Assert(owner.ver, 1); @Assert(owner.text(), "abc")
}

@Test
func testSequentialInputScopeUsesActualAcceptedPrefix(): Unit {
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    let basis = session.freezeInstalledRangeBasis(9, 41, 3).getOrThrow()
    @Assert(session.activateInstalledRangeBasis(basis, 17))
    let x = session.submitInstalledRange16(installedInput(basis, "abc", 1, 0, 3, 3), "X")
    @Assert(x.accepted); @Assert(x.versionAfter, 2)
    // Native captured Y after the real X ACK. Its installed root version stays
    // v1 while the accepted source end and observed owner receipt advance.
    let afterX = CjguiInstalledRangeBasis(basis.nonce, basis.document, basis.binding,
        basis.context, basis.mirror, basis.ownerVersion, basis.sourceStart, basis.sourceEnd + 1, "")
    let yInput = CjguiInstalledRangeInput(afterX, 17, 2, 1, 1, 2, "abcX", 4, 4)
    let y = session.submitInstalledRange16(yInput, "Y")
    @Assert(y.accepted); @Assert(y.versionAfter, 3); @Assert(owner.text(), "abcXY")
    let forgedEnd = CjguiInstalledRangeBasis(basis.nonce, basis.document, basis.binding,
        basis.context, basis.mirror, basis.ownerVersion, basis.sourceStart, basis.sourceEnd + 99, "")
    let z = session.submitInstalledRange16(CjguiInstalledRangeInput(forgedEnd, 17, 3, 2, 2, 3,
        "abcXY", 5, 5), "Z")
    @Assert(!z.accepted); @Assert(owner.writeCalls, 2); @Assert(owner.text(), "abcXY")
}

@Test
func testWholeInstalledChoiceUsesRemoteBasisThenRealSuccessor(): Unit {
    let owner = FakeTextOwner("0123456789abcdefghij")
    let window = CjguiRangeTextWindow(1001, "whole-source", owner, owner, materializeLimit: 8)
    let session = CjguiTextSession(window)
    session.bind()
    let _ = session.revealByte(12)
    session.setSelection16(0, 0)
    let basis = session.freezeInstalledRangeBasis(88, 41, 3).getOrThrow()
    @Assert(basis.sourceStart > 0, true)
    @Assert(session.activateInstalledRangeBasis(basis, 17), true)
    let first = CjguiInstalledRangeInput(basis, 17, 1, 0, 0, 1, basis.text,
        0, cjguiUtf16Length(basis.text), wholeChoiceNonce: 301, wholeChoicePrevious: 0)
    let x = session.submitInstalledRange16(first, "x", actualPostBody: Some("x"))
    @Assert(x.accepted, true)
    @Assert(owner.text(), "x")
    let _ = session.acknowledge(x.ticket, x.contextEpoch)
    let y = session.submitInstalledRange16(installedInput(basis, "x", 2, 1, 1, 1), "y",
        actualPostBody: Some("xy"))
    @Assert(y.accepted, true)
    @Assert(owner.text(), "xy")
    @Assert(owner.ver, 3)
    @Assert(owner.writeCalls, 2)
    let replay = session.submitInstalledRange16(first, "x", actualPostBody: Some("x"))
    @Assert(replay.accepted, false)
    @Assert(owner.text(), "xy")
    @Assert(owner.writeCalls, 2)
}

@Test
func testWholeInstalledSuccessorAfterRealAckDoesNotUseRemoteRoot(): Unit {
    let owner = FakeTextOwner("0123456789abcdefghij")
    let session = makeSession(owner, materializeLimit: 8)
    let _ = session.revealByte(12)
    session.setSelection16(0, 0)
    let b = session.freezeInstalledRangeBasis(89, 41, 3).getOrThrow()
    @Assert(session.activateInstalledRangeBasis(b, 17), true)
    let x = session.submitInstalledRange16(CjguiInstalledRangeInput(b, 17, 1, 0, 0, 1,
        b.text, 0, cjguiUtf16Length(b.text), wholeChoiceNonce: 302), "x", actualPostBody: Some("x"))
    @Assert(x.accepted, true)
    let _ = session.acknowledge(x.ticket, x.contextEpoch)
    let successor = CjguiInstalledRangeBasis(b.nonce, b.document, b.binding, b.context,
        b.mirror, b.ownerVersion, 0, 1, "")
    let y = session.submitInstalledRange16(CjguiInstalledRangeInput(successor, 17, 2, 1, 1, 2,
        "x", 1, 1), "y", actualPostBody: Some("xy"))
    @Assert(y.accepted, true)
    @Assert(owner.text(), "xy")
    let forged = CjguiInstalledRangeBasis(b.nonce, b.document, b.binding, b.context,
        b.mirror, b.ownerVersion, b.sourceStart, b.sourceStart + 2, "")
    let z = session.submitInstalledRange16(CjguiInstalledRangeInput(forged, 17, 3, 2, 2, 3,
        "xy", 2, 2), "z", actualPostBody: Some("xyz"))
    @Assert(z.accepted, false)
    @Assert(owner.text(), "xy")
    @Assert(owner.writeCalls, 2)
}

@Test
func testWholeInstalledWrongPrefixAndExternalWriterCloseDependentSuffix(): Unit {
    let owner = FakeTextOwner("0123456789abcdefghij")
    let session = makeSession(owner, materializeLimit: 8)
    let b = session.freezeInstalledRangeBasis(90, 41, 3).getOrThrow()
    @Assert(session.activateInstalledRangeBasis(b, 17), true)
    let wrong = session.submitInstalledRange16(CjguiInstalledRangeInput(b, 17, 1, 0, 0, 1,
        b.text, 0, cjguiUtf16Length(b.text), wholeChoiceNonce: 303, wholeChoicePrevious: 8), "x")
    @Assert(wrong.accepted, false)
    @Assert(owner.writeCalls, 0)
    let late = session.submitInstalledRange16(installedInput(b, "x", 2, 1, 1, 1), "y")
    @Assert(late.accepted, false)
    @Assert(owner.writeCalls, 0)
    session.bind()
    let next = session.freezeInstalledRangeBasis(91, 41, 4).getOrThrow()
    @Assert(session.activateInstalledRangeBasis(next, 17), true)
    owner.externalWrite(0, 0, "Agent:")
    let conflict = session.submitInstalledRange16(CjguiInstalledRangeInput(next, 17, 1, 0, 0, 1,
        next.text, 0, cjguiUtf16Length(next.text), wholeChoiceNonce: 304), "x")
    @Assert(conflict.accepted, false)
    @Assert(owner.text(), "Agent:0123456789abcdefghij")
    @Assert(owner.writeCalls, 0)
}
