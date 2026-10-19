package cjgui

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private func completionFixture(transfer: UInt64, revision: Int64, version!: Int64 = 3,
    firstResponder!: UInt8 = 1u8, targetContext!: Int64 = 2, targetMirror!: Int64 = 3,
    targetKind!: Int64 = CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT,
    semanticSelectionRevision!: Int64 = -1): (CjguiInstalledSelectionCompletion, CjguiSourceSelectionSnapshot,
    CjguiTextSelectionTicket) {
    let selected = CjguiSourceSelectionSnapshot(version, revision, 2, 1,
        documentId: "completion-owner", sessionEpoch: 9, viewGeneration: 4)
    let semantic = CjguiTextSelectionTicket(targetContext, targetMirror, version, version,
        if (semanticSelectionRevision >= 0) { semanticSelectionRevision } else { revision })
    var candidate = CjguiInternalSelectionTransferCandidate()
    candidate.transferId = transfer
    candidate.sourceRendererSessionGeneration = 11u64
    candidate.sourceWindowInstanceToken = 12u64
    candidate.sourceContextEpoch = 2u64
    candidate.sourceMirrorRevision = 3u64
    candidate.sourceOwnerVersion = version
    candidate.sourceStartByte = 0u64; candidate.sourceEndByte = 3u64
    candidate.sourceNodeId = 107u64
    candidate.targetNodeId = 107u64; candidate.targetResourceId = 1
    candidate.targetNodeKind = UInt32(targetKind)
    candidate.targetSceneVersion = 6u64; candidate.targetProjectionVersion = 6u64
    candidate.targetAnchor16 = 2u32; candidate.targetFocus16 = 1u32
    var receipt = CjguiInternalSelectionTransferReceipt()
    receipt.transferId = transfer
    receipt.nodeId = candidate.targetNodeId; receipt.resourceId = candidate.targetResourceId
    receipt.nodeKind = candidate.targetNodeKind
    receipt.sceneVersion = candidate.targetSceneVersion; receipt.projectionVersion = candidate.targetProjectionVersion
    receipt.bindingEpoch = 7u64; receipt.proxyGeneration = transfer + 10u64
    receipt.selectionRevision = 8u64; receipt.selectionStart16 = 1u32; receipt.selectionEnd16 = 2u32
    receipt.firstResponder = firstResponder
    return (CjguiInstalledSelectionCompletion(1, 20u64, selected, semantic, candidate, receipt, "ABC", "ABC",
        sourceSemantic: Some(CjguiTextSelectionTicket(2, 3, version, version, revision))),
        selected, semantic)
}

@Test
func selectionCompletionSeparatesOriginalSourceFromAcceptedSemanticWithoutResigning(): Unit {
    let (completion, selected, accepted) = completionFixture(1u64, 5, targetContext: 8, targetMirror: 9)
    @Assert(completion.sourceContextEpoch, 2)
    @Assert(completion.sourceMirrorRevision, 3)
    @Assert(completion.semantic.contextEpoch, 8)
    @Assert(completion.semantic.mirrorRevision, 9)
    @Assert(completion.matches(selected, accepted, 7u64, 20u64), true)
    @Assert(completion.matches(selected, CjguiTextSelectionTicket(2, 3, 3, 3, 5), 7u64, 20u64), false)
    let (_, newer, newerSemantic) = completionFixture(2u64, 6, targetContext: 8, targetMirror: 9)
    @Assert(completion.matches(newer, newerSemantic, 7u64, 20u64), false)
}

@Test
func selectionCompletionRetainsActualReceiptExactlyOnceAfterPendingIsGone(): Unit {
    let (completion, selected, semantic) = completionFixture(1u64, 5)
    let publication = CjguiSelectionCompletionPublication()
    @Assert(publication.record(completion, selected, semantic, 7u64, 20u64), true)
    @Assert(publication.record(completion, selected, semantic, 7u64, 20u64), false)
    let held = publication.current(selected, semantic, 7u64, 20u64).getOrThrow()
    @Assert(held.sourceSelection.anchorByte, 2)
    @Assert(held.sourceSelection.focusByte, 1)
    @Assert(held.targetSelectionStart16, 1)
    @Assert(held.targetSelectionEnd16, 2)
    @Assert(held.targetProxyGeneration, 11u64)
}

@Test
func ownerHandoffMatchesOriginalChoiceAndActualAdoptionFromSameCommit(): Unit {
    let (completed, _, adopted) = completionFixture(1u64, 6)
    let original = CjguiTextSelectionTicket(2, 3, 3, 3, 5)
    let handoff = CjguiOwnerSelectionHandoff(1u64,
        CjguiSourceSelectionSnapshot(2, 4, 1, 1, documentId: "completion-owner", sessionEpoch: 9), 2)
    handoff.target = Some(CjguiSourceSelectionSnapshot(3, 5, 2, 1,
        documentId: "completion-owner", sessionEpoch: 9, viewGeneration: 4))
    @Assert(handoff.matchesCompletion(completed, original), true)
    @Assert(handoff.matchesRequestedChoice(original, 2, 1), true)
    @Assert(handoff.matchesRequestedChoice(original, 1, 2), false)
    @Assert(handoff.matchesRequestedChoice(adopted, 2, 1), false)
    @Assert(handoff.matchesCompletion(completed, adopted), false)
    @Assert(handoff.matchesCompletion(completed, CjguiTextSelectionTicket(2, 3, 4, 4, 5)), false)
    let (late, _, _) = completionFixture(2u64, 7, version: 4)
    @Assert(handoff.matchesCompletion(late, original), false)
}

@Test
func selectionCompletionLateOldReceiptCannotReplaceSameValueNewSelection(): Unit {
    let (old, oldSelected, oldSemantic) = completionFixture(1u64, 5)
    let (fresh, selected, semantic) = completionFixture(2u64, 6)
    let publication = CjguiSelectionCompletionPublication()
    @Assert(publication.record(old, oldSelected, oldSemantic, 7u64, 20u64), true)
    @Assert(publication.current(selected, semantic, 7u64, 20u64).isNone(), true)
    @Assert(publication.record(fresh, selected, semantic, 7u64, 20u64), true)
    @Assert(publication.record(old, selected, semantic, 7u64, 20u64), false)
    @Assert(publication.current(selected, semantic, 7u64, 20u64).getOrThrow().transferId, 2u64)
}

@Test
func selectionCompletionOwnerVersionBindingAndCloseExpireObservation(): Unit {
    let (completion, selected, semantic) = completionFixture(1u64, 5)
    let (_, newer, newerSemantic) = completionFixture(2u64, 6, version: 4)
    let versionSlot = CjguiSelectionCompletionPublication()
    @Assert(versionSlot.record(completion, selected, semantic, 7u64, 20u64), true)
    @Assert(versionSlot.current(newer, newerSemantic, 7u64, 20u64).isNone(), true)
    @Assert(versionSlot.record(completion, newer, newerSemantic, 7u64, 20u64), false)
    let bindingSlot = CjguiSelectionCompletionPublication()
    @Assert(bindingSlot.record(completion, selected, semantic, 7u64, 20u64), true)
    @Assert(bindingSlot.current(selected, semantic, 8u64, 20u64).isNone(), true)
    let closeSlot = CjguiSelectionCompletionPublication()
    @Assert(closeSlot.record(completion, selected, semantic, 7u64, 20u64), true)
    closeSlot.clear()
    @Assert(closeSlot.current(selected, semantic, 7u64, 20u64).isNone(), true)
}

@Test
func selectionCompletionUninstalledCandidateCannotPublish(): Unit {
    let (completion, selected, semantic) = completionFixture(1u64, 5, firstResponder: 0u8)
    let publication = CjguiSelectionCompletionPublication()
    @Assert(publication.record(completion, selected, semantic, 7u64, 20u64), false)
    @Assert(publication.current(selected, semantic, 7u64, 20u64).isNone(), true)
}

@Test
func ownerHandoffPrivateActualASurvivesPublicCurrentExpirationForSealedB(): Unit {
    let (a, before, original) = completionFixture(6u64, 3)
    let publication = CjguiSelectionCompletionPublication()
    @Assert(publication.record(a, before, original, 7u64, 20u64), true)
    let handoff = CjguiOwnerSelectionHandoff(1u64, before, 2, sourceCompletion: Some(a))
    let after = CjguiSourceSelectionSnapshot(4, 5, 2, 2,
        documentId: "completion-owner", sessionEpoch: 9, viewGeneration: 4)
    let requested = CjguiTextSelectionTicket(2, 4, 4, 4, 5)
    handoff.target = Some(after)
    @Assert(publication.current(after, requested, 7u64, 20u64).isNone(), true)
    let kept = handoff.sourceForCandidate(after, requested, 20u64).getOrThrow()
    @Assert(kept.transferId, 6u64)
    @Assert(kept.sourceSelection.version, 3)
    @Assert(kept.semantic.contentVersion, 3)
    @Assert(handoff.target.getOrThrow().version, 4)
    @Assert(handoff.sourceForCandidate(after, CjguiTextSelectionTicket(2, 4, 3, 3, 5), 20u64).isNone(), true)
    @Assert(handoff.sourceForCandidate(after, CjguiTextSelectionTicket(2, 4, 4, 4, 6), 20u64).isNone(), true)
    @Assert(handoff.sourceForCandidate(after, requested, 21u64).isNone(), true)
}

@Test
func ownerHandoffCandidateRequiresActualABeforeSealedResultAndExactDirection(): Unit {
    let (a, before, _) = completionFixture(6u64, 3)
    let after = CjguiSourceSelectionSnapshot(4, 5, 2, 1,
        documentId: "completion-owner", sessionEpoch: 9, viewGeneration: 4)
    let requested = CjguiTextSelectionTicket(2, 4, 4, 4, 5)
    let unsealed = CjguiOwnerSelectionHandoff(1u64, before, 2, sourceCompletion: Some(a))
    @Assert(unsealed.sourceForCandidate(after, requested, 20u64).isNone(), true)
    let absent = CjguiOwnerSelectionHandoff(1u64, before, 2)
    absent.target = Some(after)
    @Assert(absent.sourceForCandidate(after, requested, 20u64).isNone(), true)
    unsealed.target = Some(after)
    let reversed = CjguiSourceSelectionSnapshot(4, 5, 1, 2,
        documentId: "completion-owner", sessionEpoch: 9, viewGeneration: 4)
    @Assert(unsealed.sourceForCandidate(reversed, requested, 20u64).isNone(), true)
    let wrongBefore = CjguiOwnerSelectionHandoff(1u64,
        CjguiSourceSelectionSnapshot(2, 3, 2, 1, documentId: "completion-owner", sessionEpoch: 9),
        2, sourceCompletion: Some(a))
    wrongBefore.target = Some(after)
    @Assert(wrongBefore.sourceForCandidate(after, requested, 20u64).isNone(), true)
}

@Test
func previewSelectionDecorationCarriesBoundedCrossFragmentRangesAndExplicitClear(): Unit {
    let (completion, _, _) = completionFixture(9u64, 5, targetKind: CJGUI_COMPOSABLE_UI_TEXT)
    let fragments = ArrayList<CjguiComposableUiSelectionDecorationFragment>()
    fragments.add(CjguiComposableUiSelectionDecorationFragment(1001, "first paragraph", 12, 17))
    fragments.add(CjguiComposableUiSelectionDecorationFragment(1002, "second paragraph", 0, 4))
    // Empty rows are part of the batch: they clear a fragment that the previous
    // accepted selection painted, without manufacturing a body or source range.
    fragments.add(CjguiComposableUiSelectionDecorationFragment(1003, "third paragraph", 0, 0))
    let batch = CjguiComposableUiSelectionDecoration(completion.transferId,
        completion.sourceOwnerVersion, completion.sourceSelection.revision, 77, 6,
        CjguiComposableUiColor(0.2, 0.4, 0.8, 0.55), fragments)
    @Assert(batch.encodedNodeRanges().getOrThrow(), "1001:12:17;1002:0:4;1003:0:0")
    @Assert(batch.matches(completion, 6), true)
    @Assert(batch.matches(completion, 7), false)
    // An ordinary accepted scene can advance while preserving the same owner
    // completion; the application must re-project through that scene's current
    // accepted SourceMap before staging its new version.
    let rebound = CjguiComposableUiSelectionDecoration(completion.transferId,
        completion.sourceOwnerVersion, completion.sourceSelection.revision, 78, 7,
        CjguiComposableUiColor(0.2, 0.4, 0.8, 0.55), fragments)
    @Assert(rebound.matches(completion, 7), true)
}

@Test
func previewSelectionDecorationRejectsStaleOwnerAndUnboundedRanges(): Unit {
    let (completion, _, _) = completionFixture(9u64, 5, targetKind: CJGUI_COMPOSABLE_UI_TEXT)
    let one = ArrayList<CjguiComposableUiSelectionDecorationFragment>()
    one.add(CjguiComposableUiSelectionDecorationFragment(1001, "paragraph", 1, 3))
    let stale = CjguiComposableUiSelectionDecoration(10u64,
        completion.sourceOwnerVersion, completion.sourceSelection.revision, 77, 6,
        CjguiComposableUiColor(0.2, 0.4, 0.8, 0.55), one)
    @Assert(stale.matches(completion, 6), false)
    let invalidRows = ArrayList<CjguiComposableUiSelectionDecorationFragment>()
    invalidRows.add(CjguiComposableUiSelectionDecorationFragment(1001, "paragraph", 4, 3))
    let invalid = CjguiComposableUiSelectionDecoration(completion.transferId,
        completion.sourceOwnerVersion, completion.sourceSelection.revision, 77, 6,
        CjguiComposableUiColor(0.2, 0.4, 0.8, 0.55), invalidRows)
    @Assert(invalid.encodedNodeRanges().isNone(), true)
}

private func caretCompletionProjection(completion: CjguiInstalledSelectionCompletion,
    selected: CjguiSourceSelectionSnapshot, semantic: CjguiTextSelectionTicket,
    node!: Int64 = 107, resource!: Int64 = 1, kind!: Int64 = CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT,
    body!: String = "ABC", anchor!: Int64 = 2, focus!: Int64 = 1): CjguiComposableUiCandidateSelectionProjection {
    return CjguiComposableUiCandidateSelectionProjection(Some(completion), selected, semantic,
        "current-source-window", node, resource, kind, body, anchor, focus, focus)
}

@Test
func candidateCaretOriginUsesFreshCompletionInsteadOfPreviousTarget(): Unit {
    let (completion, selected, semantic) = completionFixture(71u64, 5)
    let current = caretCompletionProjection(completion, selected, semantic)
    let origin = cjguiCandidateCaretInstalledOrigin(current, 7u64, 20u64, false)
    @Assert(origin[0], 71)
    @Assert(origin[6], 107)
    @Assert(origin[13], 2)
    @Assert(origin[14], 1)
    @Assert(origin[15], 1)
    // There is no new B receipt to borrow while preparation is pending.
    @Assert(cjguiCandidateCaretInstalledOrigin(current, 7u64, 20u64, true)[15], 0)
    @Assert(cjguiCandidateCaretInstalledOrigin(current, 8u64, 20u64, false)[15], 0)
    @Assert(cjguiCandidateCaretInstalledOrigin(current, 7u64, 21u64, false)[15], 0)
}

@Test
func candidateCaretOriginRejectsDifferentTargetBodyRangeAndDirection(): Unit {
    let (completion, selected, semantic) = completionFixture(72u64, 5)
    let wrong = [caretCompletionProjection(completion, selected, semantic, node: 108),
        caretCompletionProjection(completion, selected, semantic, resource: 2),
        caretCompletionProjection(completion, selected, semantic, kind: CJGUI_COMPOSABLE_UI_TEXT),
        caretCompletionProjection(completion, selected, semantic, body: "ABD"),
        caretCompletionProjection(completion, selected, semantic, anchor: 3),
        caretCompletionProjection(completion, selected, semantic, anchor: 1, focus: 2)]
    for (value in wrong) { @Assert(cjguiCandidateCaretInstalledOrigin(value, 7u64, 20u64, false)[15], 0) }
}

@Test
func candidateCaretOriginRejectsWrongOwnerRevisionAndSourceSpan(): Unit {
    let (completion, selected, semantic) = completionFixture(73u64, 5)
    let wrong = [CjguiSourceSelectionSnapshot(4, 5, 2, 1,
            documentId: selected.documentId, sessionEpoch: 9, viewGeneration: 4),
        CjguiSourceSelectionSnapshot(3, 6, 2, 1,
            documentId: selected.documentId, sessionEpoch: 9, viewGeneration: 4),
        CjguiSourceSelectionSnapshot(3, 5, 3, 1,
            documentId: selected.documentId, sessionEpoch: 9, viewGeneration: 4),
        CjguiSourceSelectionSnapshot(3, 5, 1, 2,
            documentId: selected.documentId, sessionEpoch: 9, viewGeneration: 4)]
    for (source in wrong) {
        @Assert(cjguiCandidateCaretInstalledOrigin(caretCompletionProjection(completion, source, semantic),
            7u64, 20u64, false)[15], 0)
    }
}

@Test
func acceptedSelectionDecorationRequiresSameAcceptedMapping(): Unit {
    let (completion, _, _) = completionFixture(81u64, 5, targetKind: CJGUI_COMPOSABLE_UI_TEXT)
    let ranges = ArrayList<CjguiComposableUiSelectionDecorationFragment>()
    ranges.add(CjguiComposableUiSelectionDecorationFragment(107, "ABC", 1, 2))
    let exact = CjguiComposableUiSelectionDecoration(completion.transferId, completion.sourceOwnerVersion,
        completion.sourceSelection.revision, 9, 6, CjguiComposableUiColor(0.4, 0.6, 0.9, 0.5), ranges,
        mappingIdentity: "accepted-map")
    @Assert(exact.matchesMapping(completion, 6, "accepted-map"), true)
    @Assert(exact.matchesMapping(completion, 6, "other-map"), false)
    @Assert(exact.matchesMapping(completion, 7, "accepted-map"), false)
    @Assert(exact.matchesMapping(completion, 6, ""), false)
}

@Test
func retainedSelectionPaintTracksCurrentOwnerAfterSourceEdit(): Unit {
    let (completion, original, _) = completionFixture(82u64, 5, targetKind: CJGUI_COMPOSABLE_UI_TEXT)
    let current = CjguiSourceSelectionSnapshot(4, 11, original.anchorByte, original.focusByte,
        documentId: original.documentId, sessionEpoch: original.sessionEpoch,
        viewGeneration: original.viewGeneration)
    let ranges = ArrayList<CjguiComposableUiSelectionDecorationFragment>()
    ranges.add(CjguiComposableUiSelectionDecorationFragment(107, "ABCD", 1, 2))
    let updated = CjguiComposableUiSelectionDecoration(completion.transferId, current.version,
        current.revision, 10, 7, CjguiComposableUiColor(0.4, 0.6, 0.9, 0.5), ranges)

    @Assert(updated.matchesCurrentOwner(completion, current, 7), true)
    @Assert(updated.matches(completion, 7), false)
    @Assert(updated.matchesCurrentOwner(completion,
        CjguiSourceSelectionSnapshot(4, 11, 2, 1, documentId: "other-owner",
            sessionEpoch: current.sessionEpoch, viewGeneration: current.viewGeneration), 7), false)
    @Assert(updated.matchesCurrentOwner(completion, current, 8), false)
}

@Test
func retainedSelectionPaintRejectsCompletionWithInconsistentOriginalRevision(): Unit {
    let (completion, original, _) = completionFixture(83u64, 5, targetKind: CJGUI_COMPOSABLE_UI_TEXT,
        semanticSelectionRevision: 6)
    let current = CjguiSourceSelectionSnapshot(4, 11, original.anchorByte, original.focusByte,
        documentId: original.documentId, sessionEpoch: original.sessionEpoch,
        viewGeneration: original.viewGeneration)
    let ranges = ArrayList<CjguiComposableUiSelectionDecorationFragment>()
    ranges.add(CjguiComposableUiSelectionDecorationFragment(107, "ABCD", 1, 2))
    let updated = CjguiComposableUiSelectionDecoration(completion.transferId, current.version,
        current.revision, 10, 7, CjguiComposableUiColor(0.4, 0.6, 0.9, 0.5), ranges)

    @Assert(updated.matchesCurrentOwner(completion, current, 7), false)
}

@Test
func acceptedPreviewSelectionCompletionRemainsAvailableForNextScene(): Unit {
    let (completion, original, _) = completionFixture(84u64, 5, targetKind: CJGUI_COMPOSABLE_UI_TEXT)
    let retained = selectionPaintPublicationForAcceptedPreview(completion, true)
    let retainedTransfer = match (retained) {
        case Some(value) => value.transferId
        case None => 0u64
    }
    @Assert(retainedTransfer, completion.transferId)
    @Assert(selectionPaintPublicationForAcceptedPreview(completion, false).isNone(), true)
    let (inputCompletion, _, _) = completionFixture(85u64, 5)
    @Assert(selectionPaintPublicationForAcceptedPreview(inputCompletion, true).isNone(), true)

    // The retained completion remains lineage only: the later owner snapshot
    // and accepted mapping supply the current version, revision, and ranges.
    let current = CjguiSourceSelectionSnapshot(4, 11, original.anchorByte, original.focusByte,
        documentId: original.documentId, sessionEpoch: original.sessionEpoch,
        viewGeneration: original.viewGeneration)
    let ranges = ArrayList<CjguiComposableUiSelectionDecorationFragment>()
    ranges.add(CjguiComposableUiSelectionDecorationFragment(107, "ABCD", 1, 2))
    let updated = CjguiComposableUiSelectionDecoration(retained.getOrThrow().transferId,
        current.version, current.revision, 10, 7,
        CjguiComposableUiColor(0.4, 0.6, 0.9, 0.5), ranges)
    @Assert(updated.matchesCurrentOwner(retained.getOrThrow(), current, 7), true)
}
