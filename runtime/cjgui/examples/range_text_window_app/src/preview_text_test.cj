package cjgui_range_text_window_app

import cjgui.*
import std.unittest.*
import std.unittest.testmacro.*

private func plainConsumerFindNode(root: CjguiComposableUiNode, id: Int64): ?CjguiComposableUiNode {
    if (root.nodeId == id) { return Some(root) }
    for (child in root.children()) {
        if (let Some(found) <- plainConsumerFindNode(child, id)) { return Some(found) }
    }
    return None
}

@When[os == "macOS"]
@Test
func testNormalPlainConsumerPublicSelectionProjectsOwnerChoice(): Unit {
    let controller = RangeTextWindowController("abcde\nFGHIJ\n", twoPaneFixture: true)
    let window = CjguiComposableUiWindow(controller)
    let session = controller.attach(window)
    let initialScene = controller.uiSceneVersion()
    session.setSelection16(9, 2)
    let chosen = session.sourceSelectionSnapshot().getOrThrow()
    @Assert(chosen.anchorByte, 9)
    @Assert(chosen.focusByte, 2)
    @Assert(controller.uiSceneVersion() > initialScene)
    let root = controller.buildUi()
    let first = plainConsumerFindNode(root, 9).getOrThrow()
    let second = plainConsumerFindNode(root, 11).getOrThrow()
    @Assert(first.textStyleRuns.size, 1)
    @Assert(first.textStyleRuns[0].start, 2)
    @Assert(first.textStyleRuns[0].end, 5)
    @Assert(second.textStyleRuns.size, 1)
    @Assert(second.textStyleRuns[0].start, 0)
    @Assert(second.textStyleRuns[0].end, 3)
    @Assert(controller.ownerText(), "abcde\nFGHIJ\n")
    @Assert(session.sourceSelectionSnapshot().getOrThrow().version, 1)
    session.setSelection16(3, 3)
    let cleared = controller.buildUi()
    @Assert(plainConsumerFindNode(cleared, 9).getOrThrow().textStyleRuns.size, 0)
    @Assert(plainConsumerFindNode(cleared, 11).getOrThrow().textStyleRuns.size, 0)
    controller.close()
}

@When[os == "macOS"]
@Test
func testNormalPlainConsumerUndoButtonRestoresOwnerAndContinuation(): Unit {
    let controller = RangeTextWindowController("abcde\nFGHIJ\n", twoPaneFixture: true)
    let window = CjguiComposableUiWindow(controller)
    let session = controller.attach(window)
    session.setSelection16(9, 2)
    @Assert(session.prepareSourceRange(1, 2, 9).getOrThrow().replace("Z").accepted)
    @Assert(controller.ownerText(), "abZIJ\n")
    // Reproduce the live consumer's accepted v2 source mirror before invoking
    // Undo. The owner and session must agree at this boundary.
    let _ = session.refreshMirror()
    let beforeUndo = session.mirrorSnapshot()
    @Assert(beforeUndo.contentVersion, 2)
    @Assert(beforeUndo.text, "abZIJ\n")
    let undo = plainConsumerFindNode(controller.buildUi(), 14).getOrThrow()
    let undoNode = CjguiComposableUiLayoutNode(undo, CjguiComposableUiRect(0, 0, 140, 30),
        CjguiComposableUiRect(0, 0, 140, 30))
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(undoNode, 27, "", 0, 0,
        controller.uiSceneVersion())).didApply)
    @Assert(controller.ownerText(), "abcde\nFGHIJ\n")
    let afterUndo = session.mirrorSnapshot()
    @Assert(afterUndo.contentVersion, 3)
    @Assert(afterUndo.text, "abcde\nFGHIJ\n")
    let restored = session.sourceSelectionSnapshot().getOrThrow()
    @Assert(restored.version, 3)
    @Assert(restored.anchorByte, 9)
    @Assert(restored.focusByte, 2)
    let restoredRoot = controller.buildUi()
    @Assert(plainConsumerFindNode(restoredRoot, 9).getOrThrow().textStyleRuns.size, 1)
    @Assert(plainConsumerFindNode(restoredRoot, 11).getOrThrow().textStyleRuns.size, 1)
    // Native no-click continuation is checked in the normal GUI run. This
    // declaration/owner test consumes the restored range without a new choice.
    @Assert(session.prepareSourceRange(restored.version, restored.focusByte,
        restored.anchorByte).getOrThrow().replace("Q").accepted)
    @Assert(controller.ownerText(), "abQIJ\n")
    @Assert(session.sourceSelectionSnapshot().getOrThrow().version, 4)
    controller.close()
}

@When[os == "macOS"]
@Test
func testNormalPlainConsumerForwardUndoRefreshesCurrentMirror(): Unit {
    let controller = RangeTextWindowController("abcde\nFGHIJ\n", twoPaneFixture: true)
    let window = CjguiComposableUiWindow(controller)
    let session = controller.attach(window)
    session.setSelection16(2, 9)
    let selected = session.sourceSelectionSnapshot().getOrThrow()
    @Assert(selected.anchorByte, 2)
    @Assert(selected.focusByte, 9)
    @Assert(session.prepareSourceRange(1, 2, 9).getOrThrow().replace("Z").accepted)
    @Assert(controller.ownerText(), "abZIJ\n")
    let _ = session.refreshMirror()
    let beforeUndo = session.mirrorSnapshot()
    @Assert(beforeUndo.contentVersion, 2)
    @Assert(beforeUndo.text, "abZIJ\n")
    let undo = plainConsumerFindNode(controller.buildUi(), 14).getOrThrow()
    let undoNode = CjguiComposableUiLayoutNode(undo, CjguiComposableUiRect(0, 0, 140, 30),
        CjguiComposableUiRect(0, 0, 140, 30))
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(undoNode, 27, "", 0, 0,
        controller.uiSceneVersion())).didApply)
    @Assert(controller.ownerText(), "abcde\nFGHIJ\n")
    let afterUndo = session.mirrorSnapshot()
    @Assert(afterUndo.contentVersion, 3)
    @Assert(afterUndo.text, "abcde\nFGHIJ\n")
    controller.close()
}

class TestRangeTextDecision <: CjguiSelectionDecision {
    var value: Int64
    init(value: Int64) { this.value = value }
    public override func state(): Int64 { return this.value }
    public override func admitWriter(): Bool {
        if (this.value == 1) { this.value = 4; return true }
        return false
    }
}

@Test
func testPlainPreviewIsBoundedAtAUtf8Boundary(): Unit {
    let preview = RangeTextPreviewBinding(2, 7, 100, "12345678901234567890123😀Z")
    @Assert(preview.text, "12345678901234567890123")
    @Assert(preview.sourceEnd(), 123)
    let node = rangeTextPreviewNode(Some(preview), CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0))
    @Assert(node.nodeKind, CJGUI_COMPOSABLE_UI_TEXT)
    @Assert(node.style.pointerInteractive)
    @Assert(node.resourceId, 102)
    @Assert(node.semanticId, "range-text-preview")
}

@Test
func testPlainPreviewMapsActualOwnerUtf8WithoutSplittingEmoji(): Unit {
    let preview = RangeTextPreviewBinding(2, 7, 100, "a😀b")
    let range = preview.sourceRangeUtf16(1, 3).getOrThrow()
    @Assert(range[0], 101)
    @Assert(range[1], 105)
    @Assert(preview.sourceRangeUtf16(1, 2).isNone())
    @Assert(preview.sourceRangeUtf16(3, 1).isNone())
}

@When[os == "macOS"]
@Test
func testPlainPreviewUsesExplicitSelectionBackgroundWithoutChangingSource(): Unit {
    let preview = RangeTextPreviewBinding(2, 7, 100, "a😀b")
    let ink = CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0)
    let selected = rangeTextPreviewNode(Some(preview), ink, selectionStart: 1, selectionEnd: 5)
    @Assert(selected.nodeKind, CJGUI_COMPOSABLE_UI_TEXT)
    @Assert(selected.value, preview.text)
    @Assert(selected.textStyleRuns.size, 1)
    @Assert(selected.textStyleRuns[0].encoded().endsWith(":1"))
    @Assert(selected.textStyleRuns[0].start, 1)
    @Assert(selected.textStyleRuns[0].end, 5)
    let cleared = rangeTextPreviewNode(Some(preview), ink)
    @Assert(cleared.textStyleRuns.size, 0)
    @Assert(cleared.value, selected.value)
}

@Test
func testPlainPreviewCaptureIgnoresDecorationButNotSourceOrOwner(): Unit {
    let revision = RangeTextPreviewCaptureRevision()
    let original = RangeTextPreviewBinding(2, 7, 100, "same plain text")
    let first = revision.observe(Some(original), 2, 7, 100)
    @Assert(revision.observe(Some(RangeTextPreviewBinding(2, 7, 100, "same plain text")), 2, 7, 100), first)
    let remapped = revision.observe(Some(RangeTextPreviewBinding(2, 7, 200, "same plain text")), 2, 7, 200)
    @Assert(remapped > first)
    let external = revision.observe(Some(original), 2, 8, 100)
    @Assert(external > remapped)
    let rebound = revision.observe(Some(original), 3, 7, 100)
    @Assert(rebound > external)
    @Assert(revision.observe(Some(original), 2, 7, 100) > rebound)
}

@Test
func testPlainOwnerSelectionUsesPendingDecisionAndSameValueRevision(): Unit {
    let owner = PlainRangeTextStore("abcdefgh")
    let identity = owner.sourceSelectionSnapshot()
    @Assert(identity.documentId, "cjgui-range-text-window-app:memory")
    @Assert(identity.sessionEpoch > 0)
    @Assert(owner.setSourceSelection(1, 1, 3))
    let before = owner.sourceSelectionSnapshot()
    @Assert(before.documentId, identity.documentId)
    @Assert(before.sessionEpoch, identity.sessionEpoch)
    @Assert(before.viewGeneration, identity.viewGeneration)
    let decision = TestRangeTextDecision(1)
    @Assert(owner.reserveSourceSelection(before.version, before.revision, 5, 7, decision) >= 0)
    let outcome = owner.applyRangeTextEdit(1, 0, 0, "X")
    @Assert(outcome.applied)
    @Assert(decision.state(), 4)
    let selected = owner.sourceSelectionSnapshot()
    @Assert(selected.anchorByte, 1)
    @Assert(selected.focusByte, 1)
    @Assert(owner.setSourceSelection(owner.rangeTextVersion(), selected.anchorByte, selected.focusByte))
    @Assert(owner.sourceSelectionSnapshot().revision > selected.revision)
}

@Test
func testPlainOwnerCommittedChoiceIsReadableBeforeFoldAndLateAbortCannotRestoreA(): Unit {
    let owner = PlainRangeTextStore("abcdefgh")
    @Assert(owner.setSourceSelection(1, 1, 3))
    let before = owner.sourceSelectionSnapshot()
    let decision = TestRangeTextDecision(1)
    @Assert(owner.reserveSourceSelection(before.version, before.revision, 5, 7, decision) >= 0)
    decision.value = 3
    let committed = owner.sourceSelectionSnapshot()
    @Assert(committed.anchorByte, 5)
    @Assert(committed.focusByte, 7)
    owner.settleSourceSelection(before.revision + 1)
    decision.value = 4
    let folded = owner.sourceSelectionSnapshot()
    @Assert(folded.anchorByte, 5)
    @Assert(folded.focusByte, 7)
}

@Test
func testPlainOwnerFinalizingWriterHasTypedCompletionAndIsNotRunBeforeTerminal(): Unit {
    let owner = PlainRangeTextStore("abcdefgh")
    let before = owner.sourceSelectionSnapshot()
    let decision = TestRangeTextDecision(1)
    @Assert(owner.reserveSourceSelection(before.version, before.revision, 5, 7, decision) >= 0)
    decision.value = 2
    let intent = PlainRangeTextWriterIntent<Int64>("typed-finalizer", "counter", 16, { => 73 })
    let admission = owner.submitOwnerWriter(intent)
    @Assert(admission.kind, RANGE_TEXT_WRITER_RETAINED)
    let ticket = admission.ticket.getOrThrow()
    @Assert(ticket.status(), 0)
    decision.value = 3
    owner.settleSourceSelection(before.revision + 1)
    @Assert(ticket.status(), RANGE_TEXT_WRITER_SETTLED)
    @Assert(ticket.result().getOrThrow(), 73)
}

@Test
func testPlainOwnerUndoRestoresDirectedSelectionWithoutAnotherClick(): Unit {
    let owner = PlainRangeTextStore("abcdef", enableUndoHistory: true)
    @Assert(owner.setSourceSelection(1, 4, 2))
    let accepted = owner.applyRangeTextEdit(1, 2, 4, "Z")
    @Assert(accepted.applied)
    @Assert(owner.text(), "abZef")
    @Assert(owner.sourceSelectionSnapshot().anchorByte, 3)
    @Assert(owner.undoOwnerEdit())
    @Assert(owner.text(), "abcdef")
    @Assert(owner.sourceSelectionSnapshot().anchorByte, 4)
    @Assert(owner.sourceSelectionSnapshot().focusByte, 2)
}

@Test
func testTwoPaneFixtureKeepsDirectedSourceBytesAcrossUtf8NewlineSplit(): Unit {
    let panes = rangeTextTwoPaneBindings(4, 9, 100, "A😀B\nC中文D").getOrThrow()
    let first = panes[0]
    let second = panes[1]
    @Assert(first.sourceStart, 100)
    @Assert(first.text, "A😀B")
    @Assert(second.sourceStart, 107)
    @Assert(second.text, "C中文D")
    let forwardFirst = rangeTextPaneSelection(first, 102, 111)
    let forwardSecond = rangeTextPaneSelection(second, 102, 111)
    @Assert(forwardFirst[0], 2)
    @Assert(forwardFirst[1], 6)
    @Assert(forwardSecond[0], 0)
    @Assert(forwardSecond[1], 4)
    let reverseFirst = rangeTextPaneSelection(first, 111, 102)
    let reverseSecond = rangeTextPaneSelection(second, 111, 102)
    @Assert(reverseFirst[0], forwardFirst[0])
    @Assert(reverseFirst[1], forwardFirst[1])
    @Assert(reverseSecond[0], forwardSecond[0])
    @Assert(reverseSecond[1], forwardSecond[1])
    let sourceSpan = second.sourceRangeUtf16(1, 3).getOrThrow()
    @Assert(sourceSpan[0], 108)
    @Assert(sourceSpan[1], 114)
}

@Test
func testPreviewBindingsMatchExactFirstAndSecondSlicesOfSameMirror(): Unit {
    let mirror = "abcde\nFGHIJ\n"
    let panes = rangeTextTwoPaneBindings(4, 9, 200, mirror).getOrThrow()
    let first = panes[0]
    let second = panes[1]
    @Assert(first.matchesMirror(4, 9, 200, mirror), true)
    @Assert(second.matchesMirror(4, 9, 200, mirror), true)
    @Assert(RangeTextPreviewBinding(4, 9, 200, "abcdf").matchesMirror(4, 9, 200, mirror), false)
    @Assert(second.matchesMirror(4, 10, 200, mirror), false)
    @Assert(RangeTextPreviewBinding(4, 9, 212, "X").matchesMirror(4, 9, 200, mirror), false)
}

@Test
func testSecondPaneProxySelectionIsTheSourceSelectionIntersection(): Unit {
    let panes = rangeTextTwoPaneBindings(4, 9, 200, "abcde\nFGHIJ\n").getOrThrow()
    let first = rangeTextPaneSelection(panes[0], 202, 209)
    let second = rangeTextPaneSelection(panes[1], 202, 209)
    @Assert(first[0], 2)
    @Assert(first[1], 5)
    @Assert(second[0], 0)
    @Assert(second[1], 3)
    @Assert(cjguiUtf8OffsetToUtf16(panes[1].text, second[0]).getOrThrow(), 0)
    @Assert(cjguiUtf8OffsetToUtf16(panes[1].text, second[1]).getOrThrow(), 3)
    let reverse = rangeTextPaneSelection(panes[1], 209, 202)
    @Assert(reverse[0], second[0])
    @Assert(reverse[1], second[1])
    let caret = rangeTextPaneSelection(panes[1], 209, 209)
    @Assert(caret[0], 3)
    @Assert(caret[1], 3)
}

@Test
func testTwoPaneCapturedDragResolvesEndpointAgainstAcceptedPaneGeometry(): Unit {
    let firstRect = Some((18, 74, 72, 34))
    let secondRect = Some((93, 74, 132, 34))
    // The native drag stays captured by pane 9, but this endpoint is over pane
    // 11. Resolve the accepted fragment from its current scene geometry.
    @Assert(rangeTextPreviewTargetNodeAtPoint(firstRect, secondRect, 41, 91), 9)
    @Assert(rangeTextPreviewTargetNodeAtPoint(firstRect, secondRect, 124, 91), 11)
    @Assert(rangeTextPreviewTargetNodeAtPoint(firstRect, secondRect, 250, 91), -1)
    let panes = rangeTextTwoPaneBindings(4, 9, 0, "abcde\nFGHIJ\n").getOrThrow()
    let second = panes[1]
    @Assert(second.sourceStart, 6)
    @Assert(second.text, "FGHIJ\n")
    @Assert(rangeTextPreviewSourceByteAtHit(second, 3).getOrThrow(), 9)
    @Assert(rangeTextPreviewSourceByteAtHit(second, 6).getOrThrow(), 12)
    @Assert(rangeTextPreviewSourceByteAtHit(second, 7).isNone())
    @Assert(panes[0].text + "\n" + second.text, "abcde\nFGHIJ\n")
}

@Test
func testPlainOwnerCapacityRefusalReturnsFullRetryableIntent(): Unit {
    let owner = PlainRangeTextStore("a")
    let before = owner.sourceSelectionSnapshot()
    let decision = TestRangeTextDecision(1)
    @Assert(owner.reserveSourceSelection(before.version, before.revision, 1, 1, decision) >= 0)
    decision.value = 2
    var i: Int64 = 0
    while (i < RANGE_TEXT_WRITER_MAX_ITEMS) {
        let value = i
        let admission = owner.submitOwnerWriter(PlainRangeTextWriterIntent<Int64>(
            "retained-${value}", "body-${value}", 8, { => value }))
        @Assert(admission.kind, RANGE_TEXT_WRITER_RETAINED)
        i += 1
    }
    let original = PlainRangeTextWriterIntent<Int64>("retry-this", "exact-payload", 8, { => 42 })
    let refusal = owner.submitOwnerWriter(original)
    @Assert(refusal.kind, RANGE_TEXT_WRITER_NOT_ADMITTED)
    @Assert(refusal.notAdmittedIntent.getOrThrow().operationId, original.operationId)
    decision.value = 3
    owner.settleSourceSelection(before.revision + 1)
    @Assert(owner.retainedWriterCount(), 0)
    let retried = owner.submitOwnerWriter(refusal.notAdmittedIntent.getOrThrow())
    @Assert(retried.kind, RANGE_TEXT_WRITER_SETTLED)
    @Assert(retried.value.getOrThrow(), 42)
}

private class PendingPlainRangeTextDecision <: CjguiSelectionDecision {
    var value: Int64 = 1
    public override func state(): Int64 { return this.value }
    public override func admitWriter(): Bool { return false }
}

@Test
func testPlainOwnerSelectionEditReplacesFrozenDirectedOwnerRange(): Unit {
    let owner = PlainRangeTextStore("0123456789")
    @Assert(owner.setSourceSelection(1, 8, 2))
    let choice = owner.sourceSelectionSnapshot()
    let outcome = owner.applySourceSelectionEdit(choice, "Z")
    @Assert(outcome.applied)
    @Assert(owner.text(), "01Z89")
    @Assert(owner.rangeTextVersion(), 2)
    @Assert(owner.lastAppliedRangeText(), "2:8")
    let after = owner.sourceSelectionSnapshot()
    @Assert(after.anchorByte, 3)
    @Assert(after.focusByte, 3)
}

@Test
func testPlainOwnerSelectionEditRefusesAChangedOwnerChoice(): Unit {
    let owner = PlainRangeTextStore("0123456789")
    @Assert(owner.setSourceSelection(1, 8, 2))
    let stale = owner.sourceSelectionSnapshot()
    @Assert(owner.setSourceSelection(1, 1, 4))
    let before = owner.text()
    let outcome = owner.applySourceSelectionEdit(stale, "Z")
    @Assert(!outcome.applied)
    @Assert(outcome.reason, "source_selection_stale")
    @Assert(owner.text(), before)
    @Assert(owner.rangeTextVersion(), 1)
    @Assert(owner.sourceSelectionSnapshot().anchorByte, 1)
    @Assert(owner.sourceSelectionSnapshot().focusByte, 4)
}

@Test
func testPlainOwnerSelectionEditRetainedWriterRechecksChoiceAtFifoExecution(): Unit {
    let owner = PlainRangeTextStore("0123456789")
    @Assert(owner.setSourceSelection(1, 8, 2))
    let stale = owner.sourceSelectionSnapshot()
    let decision = PendingPlainRangeTextDecision()
    let reserved = owner.reserveSourceSelection(stale.version, stale.revision, 1, 4, decision)
    @Assert(reserved > 0)
    var deferred: Option<PlainRangeTextWriterAdmission<CjguiRangeTextEditOutcome>> = None
    try {
        let _ = owner.applySourceSelectionEdit(stale, "Z")
    } catch (error: PlainRangeTextWriterRetainedException<CjguiRangeTextEditOutcome>) {
        deferred = Some(error.admission)
    }
    let admission = deferred.getOrThrow()
    @Assert(admission.kind, RANGE_TEXT_WRITER_RETAINED)
    let ticket = admission.ticket.getOrThrow()
    @Assert(ticket.status(), 0)
    decision.value = 3
    owner.settleSourceSelection(reserved)
    @Assert(ticket.status(), RANGE_TEXT_WRITER_SETTLED)
    let outcome = ticket.result().getOrThrow()
    @Assert(!outcome.applied)
    @Assert(outcome.reason, "source_selection_stale")
    @Assert(owner.text(), "0123456789")
    @Assert(owner.rangeTextVersion(), 1)
    @Assert(owner.sourceSelectionSnapshot().anchorByte, 1)
    @Assert(owner.sourceSelectionSnapshot().focusByte, 4)
}
