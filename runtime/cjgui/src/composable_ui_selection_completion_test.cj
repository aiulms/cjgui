package cjgui

import std.unittest.*
import std.unittest.testmacro.*

private func completionFixture(transfer: UInt64, revision: Int64, version!: Int64 = 3,
    firstResponder!: UInt8 = 1u8, targetContext!: Int64 = 2, targetMirror!: Int64 = 3): (CjguiInstalledSelectionCompletion, CjguiSourceSelectionSnapshot,
    CjguiTextSelectionTicket) {
    let selected = CjguiSourceSelectionSnapshot(version, revision, 2, 1,
        documentId: "completion-owner", sessionEpoch: 9, viewGeneration: 4)
    let semantic = CjguiTextSelectionTicket(targetContext, targetMirror, version, version, revision)
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
    candidate.targetNodeKind = UInt32(CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
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
