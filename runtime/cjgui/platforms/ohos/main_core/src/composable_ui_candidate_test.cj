// Candidate ownership tests (package A1): a submission attempt is identified by
// its OWN token, allocated by the structure holder before the candidate is
// looked at, and settled by the asynchronous scene commit that no client can
// observe by version number alone.
//
// What is pinned here:
//   * two attempts that share a base version get different tokens/receipts, and
//     replacing the first one settles it as SUPERSEDED (never as accepted);
//   * only the commit hook settles an attempt as ACCEPTED, and it never rewrites
//     an already-accepted attempt when a later candidate is accepted;
//   * an attempt that dies before the holder sees a structure (decode/CAS) and
//     an attempt whose scene is rejected keep their own REJECTED reason;
//   * a token outside the bounded table answers UNKNOWN instead of borrowing
//     another attempt's state.
package cjgui

import std.collection.*
import cjgui_shared_operation_core.*

private class TailLegacyRollbackParticipant <: CjguiComposableUiSceneRefreshParticipant {
    public var rollbacks: Int64 = 0
    public func beginSceneRefresh(): Bool { return true }
    public func prepareSceneRefresh(): Bool { return true }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }
    public func commitSceneRefresh(): Unit {}
    public func rollbackSceneRefresh(): Unit { rollbacks += 1 }
}

@Test
func tailRollbackReasonKeepsLegacyParticipantCompatible(): Unit {
    let legacy = TailLegacyRollbackParticipant()
    let participant: CjguiComposableUiSceneRefreshParticipant = legacy
    participant.rollbackSceneRefresh("accepted_input")
    @Assert(legacy.rollbacks, 1)
}

@Test
func tailRollbackReasonSettlesOnlyPendingTicketAndPreservesSpecificRefusal(): Unit {
    let holder = CjguiGeneratedUiStructureHolder(generatedTextCatalog())
    let provider = GeneratedTestProvider()
    let children = ArrayList<CjguiGeneratedUiNodeSpec>([
        CjguiGeneratedUiNodeSpec("fieldA", "textInput", fieldId: "label")])
    let spec = CjguiGeneratedUiNodeSpec("panelA", "vertical", children: children)
    let accepted = holder.submit(spec, provider)
    @Assert(generatedCommit(holder, provider), true)
    let version = holder.structureVersion()
    let identity = holder.nodeIdForKey("fieldA")
    let pending = holder.submit(spec, provider)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    holder.rollbackCandidateRefresh("accepted_input")
    let ticket = holder.candidateTicketPayload(pending.candidateToken)
    @Assert(ticket.contains("TERMINAL_STATE REJECTED"), true)
    @Assert(ticket.contains("REASON accepted_input"), true)
    @Assert(ticket.contains("SCENE_STATE scene_rejected:accepted_input"), true)
    @Assert(holder.structureVersion(), version)
    @Assert(holder.nodeIdForKey("fieldA"), identity)
    @Assert(holder.currentAcceptedCandidateToken(), accepted.candidateToken)
    @Assert(holder.pendingCandidateToken(), 0)
    holder.rollbackCandidateRefresh("late_window_close")
    @Assert(holder.candidateTicketPayload(pending.candidateToken), ticket)
    @Assert(holder.candidateTicketPayload(accepted.candidateToken).contains("TERMINAL_STATE ACCEPTED"), true)
    let specific = holder.submit(spec, provider)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    holder.rejectCandidateAttempt(specific.candidateToken, "binding_revoked", "fieldA")
    let named = holder.candidateTicketPayload(specific.candidateToken)
    holder.rollbackCandidateRefresh("later_generic_failure")
    // The ticket also exposes the CURRENT pending pointer. Rollback clears
    // that pointer; the attempt's own terminal fields must remain identical.
    @Assert(holder.candidateTicketPayload(specific.candidateToken),
        named.replace("PENDING_TOKEN ${specific.candidateToken}", "PENDING_TOKEN 0"))
    @Assert(holder.pendingCandidateToken(), 0)
    @Assert(holder.lastSceneOutcome(), "candidate_rejected")
    let invalid = holder.submit(CjguiGeneratedUiNodeSpec("", "vertical"), provider)
    let before = holder.candidateTicketPayload(invalid.candidateToken)
    holder.rollbackCandidateRefresh("later_generic_failure")
    @Assert(holder.candidateTicketPayload(invalid.candidateToken), before)
}

private class TailRollbackRegionBinding <: CjguiGeneratedUiRegionBinding {
    public func ownerRevision(): Int64 { return 1 }
    public func fieldResourceId(fieldId: String): Int64 { return -1 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return -1 }
    public func draftText(fieldId: String): String { return "" }
    public func appliedText(fieldId: String): String { return "" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(false, "")
    }
    public func actionAvailable(actionName: String): Bool { return false }
    public func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
}

private class TailRollbackWindowController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    private static func catalog(): CjguiGeneratedUiCapabilityCatalog {
        let result = generatedTextCatalog()
        let properties = ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("text", "STRING", required: true, maxLength: 40)])
        let _ = result.registerComponent(CjguiGeneratedUiComponentSpec("label", properties, false))
        return result
    }
    public let region = CjguiGeneratedUiWindowRegion(catalog(), TailRollbackRegionBinding(), "tail-rollback")
    public func uiSceneVersion(): Int64 { return region.revision() }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(81001, "tail-rollback-root", CjguiComposableUiStyle())
        root.add(region.buildNode())
        return root
    }
    public func beginSceneRefresh(): Bool { return region.beginSceneRefresh() }
    public func prepareSceneRefresh(): Bool { return region.prepareSceneRefresh() }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> { return ArrayList<CjguiComposableUiCommand>() }
    public func commitSceneRefresh(): Unit { region.commitSceneRefresh() }
    public func rollbackSceneRefresh(): Unit { region.rollbackSceneRefresh() }
    public func rollbackSceneRefresh(reason: String): Unit { region.rollbackSceneRefresh(reason) }
    public func disposeSceneRefreshResources(): Unit { region.disposeSceneRefreshResources() }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult { return region.handleEvent(event) }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

@Test
func tailRollbackProductionWindowCancellationReachesPublicTicket(): Unit {
    let controller = TailRollbackWindowController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    controller.region.attachWindow(window)
    let accepted = window.acceptedSceneDump()
    let budget = CjguiOwnerTurnBudget()
    window.useOwnerTurnBudget(budget)
    let reply = controller.region.submitStructure("""
GENERATED_UI_STRUCTURE 1
NODE 0 tailPanel vertical
NODE 1 tailLabel label
PROPERTY 1 tailLabel text pending
END
""", 0)
    @Assert(reply.candidateAccepted, true)
    @Assert(budget.begin(), true)
    let _ = window.refreshIfNeeded()
    @Assert(budget.hasPreparedWork(), true)
    @Assert(controller.region.candidateTicketPayload(reply.candidateToken).contains("TERMINAL_STATE PENDING"), true)
    // A real source refresh cancels the retained carrier. It does not change
    // admission or retry the declaration: its original public ticket settles.
    window.requestRefresh()
    let ticket = controller.region.candidateTicketPayload(reply.candidateToken)
    @Assert(ticket.contains("TERMINAL_STATE REJECTED"), true)
    @Assert(ticket.contains("REASON request_changed"), true)
    @Assert(controller.region.acceptedStructureVersion(), 0)
    @Assert(window.acceptedSceneDump(), accepted)
    @Assert(budget.hasPreparedWork(), false)
    budget.end()
    window.close()
    @Assert(controller.region.candidateTicketPayload(reply.candidateToken), ticket)
}

@Test
func generatedCandidateTokenOwnsItsOwnAttempt(): Unit {
    let catalog = generatedTextCatalog()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    let leaves = ArrayList<CjguiGeneratedUiNodeSpec>()
    leaves.add(CjguiGeneratedUiNodeSpec("fieldA", "textInput", fieldId: "label"))
    let firstSpec = CjguiGeneratedUiNodeSpec("panelA", "vertical", children: leaves)

    // The application allocates the attempt token BEFORE it decodes a payload;
    // the holder records it and the submit adopts it.
    let firstToken = holder.allocateCandidateAttempt()
    let first = holder.submit(firstSpec, provider, attemptToken: firstToken)
    @Assert(first.candidateAccepted, true)
    @Assert(first.candidateToken, firstToken)
    @Assert(first.receipt, CjguiGeneratedUiStructureHolder.receiptForToken(firstToken))
    @Assert(holder.pendingCandidateToken(), firstToken)
    if (let Some(record) <- holder.candidateRecord(firstToken)) {
        @Assert(record.terminalState(), "PENDING")
        @Assert(record.baseVersion, 0)
        @Assert(record.candidateVersion, 1)
    } else {
        @Assert(false, true)
    }

    // A second submitter with the SAME base version: the holder is still at
    // version 0, so the candidate is received and the first attempt is merely
    // replaced. It must never be reported as accepted or as a business failure.
    let secondToken = holder.allocateCandidateAttempt()
    @Assert(secondToken > firstToken, true)
    let secondLeaves = ArrayList<CjguiGeneratedUiNodeSpec>()
    secondLeaves.add(CjguiGeneratedUiNodeSpec("fieldB", "textInput", fieldId: "label"))
    let secondSpec = CjguiGeneratedUiNodeSpec("panelB", "vertical", children: secondLeaves)
    let second = holder.submit(secondSpec, provider, attemptToken: secondToken)
    @Assert(second.candidateAccepted, true)
    @Assert(second.receipt != first.receipt, true)
    if (let Some(record) <- holder.candidateRecord(firstToken)) {
        @Assert(record.terminalState(), "SUPERSEDED")
        @Assert(record.sceneState(), "superseded_by_newer_candidate")
    } else {
        @Assert(false, true)
    }
    @Assert(holder.pendingCandidateToken(), secondToken)
    // Nothing was published by either attempt yet.
    @Assert(holder.structureVersion(), 0)
    @Assert(holder.currentAcceptedCandidateToken(), 0)

    // ONLY the scene commit settles the pending attempt as ACCEPTED.
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.structureVersion(), 1)
    @Assert(holder.currentAcceptedCandidateToken(), secondToken)
    @Assert(holder.pendingCandidateToken(), 0)
    if (let Some(record) <- holder.candidateRecord(secondToken)) {
        @Assert(record.terminalState(), "ACCEPTED")
        @Assert(record.sceneState(), "scene_accepted")
        @Assert(record.acceptedVersion(), 1)
    } else {
        @Assert(false, true)
    }

    // Accepted-then-replaced: a later accepted structure does not rewrite the
    // earlier attempt. The reader compares its token with the current accepted
    // token instead, which is exactly what the typed client reports as
    // `accepted_then_replaced`.
    let thirdLeaves = ArrayList<CjguiGeneratedUiNodeSpec>()
    thirdLeaves.add(CjguiGeneratedUiNodeSpec("fieldC", "textInput", fieldId: "label"))
    let third = holder.submit(CjguiGeneratedUiNodeSpec("panelC", "vertical", children: thirdLeaves), provider)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.structureVersion(), 2)
    @Assert(holder.currentAcceptedCandidateToken(), third.candidateToken)
    if (let Some(record) <- holder.candidateRecord(secondToken)) {
        @Assert(record.terminalState(), "ACCEPTED")
        @Assert(record.acceptedVersion(), 1)
    } else {
        @Assert(false, true)
    }
    @Assert(holder.currentAcceptedCandidateToken() != secondToken, true)

    // The compact ticket read carries the same state, and an evicted/unknown
    // token is reported as UNKNOWN rather than as some other attempt's answer.
    let ticket = holder.candidateTicketPayload(secondToken)
    @Assert(ticket.contains("TERMINAL_STATE ACCEPTED"), true)
    @Assert(ticket.contains("ACCEPTED_VERSION 1"), true)
    @Assert(ticket.contains("CURRENT_ACCEPTED_TOKEN ${third.candidateToken}"), true)
    let unknown = holder.candidateTicketPayload(999999)
    @Assert(unknown.contains("TERMINAL_STATE UNKNOWN"), true)
    @Assert(holder.candidateRecord(999999).isNone(), true)
}

@Test
func generatedCandidateRejectionStaysWithItsOwnAttempt(): Unit {
    let catalog = generatedTextCatalog()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    let leaves = ArrayList<CjguiGeneratedUiNodeSpec>()
    leaves.add(CjguiGeneratedUiNodeSpec("fieldA", "textInput", fieldId: "label"))
    let accepted = CjguiGeneratedUiNodeSpec("panelA", "vertical", children: leaves)
    @Assert(generatedCommit(holder, provider), true)
    let _ = holder.submit(accepted, provider)
    @Assert(generatedCommit(holder, provider), true)

    // (a) An attempt that never reaches the holder with a structure: the
    // application decoded a malformed payload (or hit the version conflict)
    // after allocating the token, and says so for THAT token.
    let malformedToken = holder.allocateCandidateAttempt()
    holder.rejectCandidateAttempt(malformedToken, "malformed_node", "1")
    if (let Some(record) <- holder.candidateRecord(malformedToken)) {
        @Assert(record.terminalState(), "REJECTED")
        @Assert(record.reason(), "malformed_node")
        @Assert(record.path(), "1")
    } else {
        @Assert(false, true)
    }
    @Assert(holder.candidateTicketPayload(malformedToken).contains("REASON malformed_node"), true)

    // (b) A candidate the holder itself rejects at validation time.
    let invalidToken = holder.allocateCandidateAttempt()
    let invalid = holder.submit(CjguiGeneratedUiNodeSpec("", "vertical"), provider,
        attemptToken: invalidToken)
    @Assert(invalid.candidateAccepted, false)
    @Assert(invalid.candidateToken, invalidToken)
    if (let Some(record) <- holder.candidateRecord(invalidToken)) {
        @Assert(record.terminalState(), "REJECTED")
        @Assert(record.reason().size > 0, true)
    } else {
        @Assert(false, true)
    }

    // (c) A candidate that is valid but whose scene is rejected: its own token
    // is REJECTED, the accepted structure/version/token stay untouched.
    let acceptedVersion = holder.structureVersion()
    let acceptedToken = holder.currentAcceptedCandidateToken()
    let sceneRejectedToken = holder.allocateCandidateAttempt()
    let sceneRejected = holder.submit(accepted, provider, attemptToken: sceneRejectedToken)
    @Assert(sceneRejected.candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    holder.rollbackCandidateRefresh()
    if (let Some(record) <- holder.candidateRecord(sceneRejectedToken)) {
        @Assert(record.terminalState(), "REJECTED")
        @Assert(record.sceneState(), "scene_rejected:layout_or_native")
    } else {
        @Assert(false, true)
    }
    @Assert(holder.structureVersion(), acceptedVersion)
    @Assert(holder.currentAcceptedCandidateToken(), acceptedToken)
    @Assert(holder.pendingCandidateToken(), 0)
    @Assert(holder.hasPendingCandidate(), false)
}

// A finished scene may not settle a later admitted declaration.
@Test
func ordinaryRegionCompletedRollbackDoesNotRejectLaterSubmission(): Unit {
    let region = TailRollbackWindowController().region
    let scene = "GENERATED_UI_STRUCTURE 1\nNODE 0 panel vertical\nEND"
    let first = region.submitStructure(scene, 0)
    @Assert(region.beginSceneRefresh(), true)
    let _ = region.buildNode()
    @Assert(region.prepareSceneRefresh(), true)
    region.commitSceneRefresh()
    @Assert(region.candidateTicketPayload(first.candidateToken).contains("TERMINAL_STATE ACCEPTED"), true)
    @Assert(region.beginSceneRefresh(), true)
    let _ = region.buildNode()
    let busy = region.submitStructure(scene, 1)
    @Assert(busy.candidateAccepted, false)
    @Assert(busy.reason, "scene_transaction_busy")
    region.rollbackSceneRefresh("request_changed")
    let next = region.submitStructure(scene, 1)
    @Assert(next.candidateAccepted, true)
    // A second rollback from the completed carrier cannot own this request.
    region.rollbackSceneRefresh("late_previous_scene")
    @Assert(region.candidateTicketPayload(next.candidateToken).contains("TERMINAL_STATE PENDING"), true)
    @Assert(region.acceptedStructureVersion(), 1)
    @Assert(region.beginSceneRefresh(), true)
    let _ = region.buildNode()
    @Assert(region.prepareSceneRefresh(), true)
    region.commitSceneRefresh()
    @Assert(region.candidateTicketPayload(next.candidateToken).contains("TERMINAL_STATE ACCEPTED"), true)
    @Assert(region.acceptedStructureVersion(), 2)
}

@Test
func ordinaryRegionCompletedCommitCannotSettleLaterSubmission(): Unit {
    let region = TailRollbackWindowController().region
    let scene = "GENERATED_UI_STRUCTURE 1\nNODE 0 panel vertical\nEND"
    let older = region.submitStructure(scene, 0)
    @Assert(region.beginSceneRefresh(), true)
    let _ = region.buildNode()
    region.rollbackSceneRefresh("original_cancellation")
    @Assert(region.candidateTicketPayload(older.candidateToken).contains("REASON original_cancellation"), true)
    let next = region.submitStructure(scene, 0)
    @Assert(next.candidateAccepted, true)
    region.commitSceneRefresh()
    @Assert(region.candidateTicketPayload(next.candidateToken).contains("TERMINAL_STATE PENDING"), true)
    @Assert(region.beginSceneRefresh(), true)
    let _ = region.buildNode()
    @Assert(region.prepareSceneRefresh(), true)
    region.rollbackSceneRefresh("real_current_cancellation")
    @Assert(region.candidateTicketPayload(next.candidateToken).contains("REASON real_current_cancellation"), true)
}

@Test
func ordinaryHolderStyleCarrierRollbackCannotRejectNewTicket(): Unit {
    let holder = CjguiGeneratedUiStructureHolder(generatedTextCatalog())
    let provider = GeneratedTestProvider()
    let spec = CjguiGeneratedUiNodeSpec("panel", "vertical")
    let first = holder.submit(spec, provider)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    let next = holder.submit(spec, provider)
    @Assert(next.candidateAccepted, true)
    holder.rollbackCandidateRefresh("request_changed")
    @Assert(holder.candidateTicketPayload(next.candidateToken).contains("TERMINAL_STATE PENDING"), true)
    @Assert(holder.structureVersion(), 1)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.candidateTicketPayload(next.candidateToken).contains("TERMINAL_STATE ACCEPTED"), true)
    @Assert(holder.candidateTicketPayload(first.candidateToken).contains("TERMINAL_STATE ACCEPTED"), true)
}

@Test
func ordinaryHolderSupersededCarrierCannotSettleReplacement(): Unit {
    let holder = CjguiGeneratedUiStructureHolder(generatedTextCatalog())
    let provider = GeneratedTestProvider()
    let spec = CjguiGeneratedUiNodeSpec("panel", "vertical")
    let older = holder.submit(spec, provider)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    let next = holder.submit(spec, provider)
    @Assert(holder.prepareCandidateRefresh(), false)
    holder.rollbackCandidateRefresh("old_carrier")
    @Assert(holder.candidateTicketPayload(older.candidateToken).contains("TERMINAL_STATE SUPERSEDED"), true)
    @Assert(holder.candidateTicketPayload(next.candidateToken).contains("TERMINAL_STATE PENDING"), true)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.candidateTicketPayload(next.candidateToken).contains("TERMINAL_STATE ACCEPTED"), true)
}
