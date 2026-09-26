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
