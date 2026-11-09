package cjgui

import std.unittest.*
import std.unittest.testmacro.*

// Uses the existing bounded owner fixture and real session commit functions.
// Native installation is independently observed as a display-proxy range.
class SourceCoordinatesTestOwner <: CjguiRangeTextSource & CjguiRangeTextEditSink &
    CjguiRangeTextSelectionOwner {
    let body: FakeTextOwner
    let origin: Int64
    var revision: Int64 = 1
    var anchor: Int64 = 0
    var focus: Int64 = 0
    var selectionWrites: Int64 = 0
    var installs: Int64 = 0
    var proxyStart: Int64 = -1
    var proxyEnd: Int64 = -1
    init(text: String, origin!: Int64 = 0) { this.body = FakeTextOwner(text); this.origin = origin }
    public func rangeTextVersion(): Int64 { body.ver }
    public func rangeTextByteLength(): Int64 { Int64(body.data.size) }
    public func readRangeText(start: Int64, limit: Int64): CjguiRangeTextSlice {
        body.readRangeText(if (start < origin) { origin } else { start }, limit)
    }
    public func confirmRangeTextVersion(version: Int64, action: () -> Bool): Bool {
        body.confirmRangeTextVersion(version, action)
    }
    public func rebaseRangeTextSelection(version: Int64, a: Int64, b: Int64): ?(Int64, Int64, Int64) {
        body.rebaseRangeTextSelection(version, a, b)
    }
    public func applyRangeTextEdit(version: Int64, a: Int64, b: Int64, text: String): CjguiRangeTextEditOutcome {
        body.applyRangeTextEdit(version, a, b, text)
    }
    public func sourceSelectionSnapshot(): CjguiSourceSelectionSnapshot {
        CjguiSourceSelectionSnapshot(body.ver, revision, anchor, focus,
            documentId: "source-coordinate-fixture", sessionEpoch: 1, viewGeneration: 1)
    }
    public func setSourceSelection(version: Int64, a: Int64, f: Int64): Bool {
        if (version != body.ver || cjguiUtf8OffsetToUtf16(body.text(), a).isNone() ||
            cjguiUtf8OffsetToUtf16(body.text(), f).isNone()) { return false }
        anchor = a; focus = f; revision += 1; selectionWrites += 1
        return true
    }
    public func reserveSourceSelection(version: Int64, expected: Int64, a: Int64,
        f: Int64, decision: CjguiSelectionDecision): Int64 { return -1 }
    public func settleSourceSelection(expected: Int64): Unit {}
}

// RED used the exact old Windows fallback entry. The same oracle now exercises
// the internal same-ticket conversion; the old routing is retained in evidence.
private func sourceCoordinatesCommit(session: CjguiTextSession, ticket: CjguiTextSelectionTicket,
    anchorByte: Int64, focusByte: Int64, install: () -> Bool): Bool {
    return session.commitSourceSelectionInMirrorTicket(ticket, anchorByte, focusByte, install)
}

func sourceCoordinatesSession(owner: SourceCoordinatesTestOwner, limit!: Int64 = 65536): CjguiTextSession {
    let session = CjguiTextSession(CjguiRangeTextWindow(4, "coordinates", owner, owner, materializeLimit: limit))
    session.bind()
    return session
}

@Test
func sourceCoordinatesOriginal134BytesKeepReverseDirectionAndSeparateProxy(): Unit {
    let text = "\u{FEFF}# 写作验收\n\n首段正文WINCHAIN-01中😀，包含中文与 *强调*。\n\n- 条目一\n- 条目二\n\n```cj\ncode()\n```\n\n尾段。\n"
    @Assert(text.size, 134)
    let owner = SourceCoordinatesTestOwner(text)
    let session = sourceCoordinatesSession(owner)
    let accepted = sourceCoordinatesCommit(session, session.freezeSelectionTicket(), 49, 41, { =>
        owner.proxyStart = 14; owner.proxyEnd = 18; return true
    })
    @Assert(accepted, true)
    @Assert(session.plainSelectionAnchorValue(), 27)
    @Assert(session.plainSelectionFocusValue(), 23)
    @Assert(session.selection16()[0], 23); @Assert(session.selection16()[1], 27)
    @Assert(owner.anchor, 49); @Assert(owner.focus, 41)
    @Assert(owner.proxyStart, 14); @Assert(owner.proxyEnd, 18)
    @Assert(owner.body.text(), text); @Assert(owner.body.ver, 1)
    @Assert(owner.body.writeCalls, 0); @Assert(owner.selectionWrites, 1)
}

@Test
func sourceCoordinatesAsciiAndForwardRemainExact(): Unit {
    let owner = SourceCoordinatesTestOwner("abcde")
    let session = sourceCoordinatesSession(owner)
    @Assert(sourceCoordinatesCommit(session, session.freezeSelectionTicket(), 1, 4, { => true }), true)
    @Assert(session.selection16()[0], 1); @Assert(session.selection16()[1], 4)
    @Assert(owner.anchor, 1); @Assert(owner.focus, 4)
}

@Test
func sourceCoordinatesNonzeroMirrorOriginUsesLocalUtf16(): Unit {
    var prefix = ""
    for (_ in 0..100) { prefix += "x" }
    let owner = SourceCoordinatesTestOwner(prefix + "éA中😀Z", origin: 100)
    let session = sourceCoordinatesSession(owner, limit: 12)
    @Assert(session.mirrorSnapshot().startByte, 100)
    @Assert(session.mirrorText(), "éA中😀Z")
    @Assert(sourceCoordinatesCommit(session, session.freezeSelectionTicket(), 110, 103, { => true }), true)
    @Assert(session.plainSelectionAnchorValue(), 5); @Assert(session.plainSelectionFocusValue(), 2)
    @Assert(owner.anchor, 110); @Assert(owner.focus, 103)
}

@Test
func sourceCoordinatesBadBoundaryAndOutsideMirrorNeverInstall(): Unit {
    let owner = SourceCoordinatesTestOwner("éA中😀Z")
    let session = sourceCoordinatesSession(owner)
    for (pair in [(1, 3), (3, 7), (-1, 3), (0, 12)]) {
        @Assert(sourceCoordinatesCommit(session, session.freezeSelectionTicket(), pair[0], pair[1], { =>
            owner.installs += 1; return true
        }), false)
    }
    @Assert(owner.installs, 0); @Assert(owner.selectionWrites, 0)
    @Assert(owner.body.ver, 1)
}

@Test
func sourceCoordinatesOldOwnerAndMirrorTicketsNeverInstall(): Unit {
    let owner = SourceCoordinatesTestOwner("éA中😀Z")
    let session = sourceCoordinatesSession(owner)
    let oldOwner = session.freezeSelectionTicket()
    owner.body.bumpVersionOnly()
    @Assert(sourceCoordinatesCommit(session, oldOwner, 3, 10, { => owner.installs += 1; return true }), false)
    let _ = session.refreshMirror()
    let oldContext = session.freezeSelectionTicket()
    session.bind()
    @Assert(sourceCoordinatesCommit(session, oldContext, 3, 10, { => owner.installs += 1; return true }), false)
    @Assert(owner.installs, 0); @Assert(owner.selectionWrites, 0)
}

@Test
func sourceCoordinatesFailedInstallAndInstallVersionChangeDoNotCommit(): Unit {
    let owner = SourceCoordinatesTestOwner("éA中😀Z")
    let session = sourceCoordinatesSession(owner)
    let ticket = session.freezeSelectionTicket()
    @Assert(sourceCoordinatesCommit(session, ticket, 10, 3, { => false }), false)
    @Assert(owner.selectionWrites, 0); @Assert(session.selectionTicketMatches(ticket), true)
    @Assert(sourceCoordinatesCommit(session, ticket, 10, 3, { => owner.body.bumpVersionOnly(); return true }), false)
    @Assert(owner.selectionWrites, 0); @Assert(owner.body.ver, 2)
}
