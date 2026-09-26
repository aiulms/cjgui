// Generated-UI candidate ticket protocol tests (package A1, transport layer).
//
// The holder owns the ticket; this file pins the ONE compact command an external
// client uses to read it, and the submit reply that hands the token back:
//   * `GET_GENERATED_UI_CANDIDATE <token>` answers the attempt's own state;
//   * a provider without an attempt table answers UNKNOWN, never a state that
//     belongs to another attempt;
//   * a malformed token is an invalid request, not a silent default;
//   * the submit reply carries ENDPOINT_EPOCH + CANDIDATE_TOKEN + RECEIPT.
package cjgui_shared_operation_core

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private class CandidateTicketProvider <: CjguiSharedOperationGeneratedUiProvider {
    public func capabilitiesPayload(): String {
        return ""
    }

    public func fieldsPayload(): String {
        return ""
    }

    public func acceptedStructurePayload(): String {
        return "GENERATED_UI_STRUCTURE 1\nNODE 0 root vertical\nEND"
    }

    public func acceptedStructureVersion(): Int64 {
        return 3
    }

    public func submitStructure(candidatePayload: String, expectedVersion: Int64):
        CjguiSharedOperationGeneratedUiSubmit {
        return CjguiSharedOperationGeneratedUiSubmit(true, "", "", expectedVersion, expectedVersion,
            candidateVersion: expectedVersion + 1, candidateToken: 11,
            receipt: "generated-ui-candidate-11")
    }

    public func candidateTicketPayload(token: Int64): String {
        if (token != 11) {
            return ""
        }
        return "CANDIDATE_TOKEN 11\nRECEIPT generated-ui-candidate-11\nBASE_VERSION 3\n" +
            "CANDIDATE_VERSION 4\nTERMINAL_STATE ACCEPTED\nSCENE_STATE scene_accepted\nREASON none\n" +
            "PATH none\nACCEPTED_VERSION 4\nCURRENT_ACCEPTED_TOKEN 11\nPENDING_TOKEN 0"
    }
}

/// A provider that only implements the original interface: it never overrides
/// `candidateTicketPayload`, so the transport must report UNKNOWN.
private class DefaultTicketProvider <: CjguiSharedOperationGeneratedUiProvider {
    public func capabilitiesPayload(): String { return "" }
    public func fieldsPayload(): String { return "" }
    public func acceptedStructurePayload(): String { return "" }
    public func acceptedStructureVersion(): Int64 { return 0 }
    public func submitStructure(candidatePayload: String, expectedVersion: Int64):
        CjguiSharedOperationGeneratedUiSubmit {
        return CjguiSharedOperationGeneratedUiSubmit(false, "not_implemented", "",
            expectedVersion, expectedVersion)
    }
}

private func candidateTicketAuthorization(): CjguiSharedOperationExternalAuthorization {
    return CjguiSharedOperationExternalAuthorization(
        "候选票据验收调用者",
        "candidate-ticket-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_GENERATED_UI", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("SUBMIT_GENERATED_UI", ArrayList<Int64>(), true)
        ])
    )
}

private func candidateTicketConnection(provider: ?CjguiSharedOperationGeneratedUiProvider):
    CjguiSharedOperationExternalConnection {
    let connection = CjguiSharedOperationExternalConnection(
        CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>()),
        candidateTicketAuthorization())
    if (let Some(active) <- provider) {
        let _ = connection.enableGeneratedUiProvider(active)
    }
    return connection
}

@Test
func candidateTicketReadCarriesOnlyItsOwnAttempt(): Unit {
    let connection = candidateTicketConnection(Some(CandidateTicketProvider()))

    let known = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH candidate-ticket-capability\n" +
        "GET_GENERATED_UI_CANDIDATE 11")
    @Assert(known.contains("KIND GENERATED_UI_CANDIDATE"), true)
    @Assert(known.contains("CANDIDATE_TOKEN 11"), true)
    @Assert(known.contains("ENDPOINT_EPOCH "), true)
    @Assert(known.contains("RECEIPT generated-ui-candidate-11"), true)
    @Assert(known.contains("TERMINAL_STATE ACCEPTED"), true)
    @Assert(known.contains("ACCEPTED_VERSION 4"), true)
    @Assert(known.contains("CURRENT_ACCEPTED_TOKEN 11"), true)
    @Assert(known.endsWith("END"), true)

    // The provider has no record for this token: the transport must not invent
    // a state for it, and must not answer with the token 11 state.
    let unknown = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH candidate-ticket-capability\n" +
        "GET_GENERATED_UI_CANDIDATE 12")
    @Assert(unknown.contains("TERMINAL_STATE UNKNOWN"), true)
    @Assert(unknown.contains("CANDIDATE_TOKEN 12"), true)
    @Assert(unknown.contains("TERMINAL_STATE ACCEPTED"), false)
    @Assert(unknown.endsWith("END"), true)

    // A malformed token is rejected as a request fault, not defaulted to 0.
    let malformed = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH candidate-ticket-capability\n" +
        "GET_GENERATED_UI_CANDIDATE notANumber")
    @Assert(malformed.contains("ERROR invalid_request"), true)
    let missing = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH candidate-ticket-capability\n" +
        "GET_GENERATED_UI_CANDIDATE")
    @Assert(missing.contains("ERROR invalid_request"), true)
}

@Test
func candidateSubmitReplyHandsBackTheAttemptToken(): Unit {
    let connection = candidateTicketConnection(Some(CandidateTicketProvider()))
    let reply = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH candidate-ticket-capability\n" +
        "SUBMIT_GENERATED_UI 3\nGENERATED_UI_STRUCTURE 1\nNODE 0 root vertical\nEND")
    @Assert(reply.contains("APPLIED true"), true)
    @Assert(reply.contains("CANDIDATE_TOKEN 11"), true)
    @Assert(reply.contains("RECEIPT generated-ui-candidate-11"), true)
    @Assert(reply.contains("ENDPOINT_EPOCH "), true)
    @Assert(reply.contains("CANDIDATE_VERSION 4"), true)
    @Assert(reply.endsWith("END"), true)
}

@Test
func candidateTicketWithoutProviderTableReportsUnknown(): Unit {
    // A provider that predates the attempt table (the interface default answers
    // an empty payload): the command still answers a bounded, honest UNKNOWN
    // envelope instead of a state that belongs to another attempt.
    let defaulted = candidateTicketConnection(Some(DefaultTicketProvider()))
    let reply = defaulted.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH candidate-ticket-capability\n" +
        "GET_GENERATED_UI_CANDIDATE 11")
    @Assert(reply.contains("KIND GENERATED_UI_CANDIDATE"), true)
    @Assert(reply.contains("CANDIDATE_TOKEN 11"), true)
    @Assert(reply.contains("TERMINAL_STATE UNKNOWN"), true)
    @Assert(reply.endsWith("END"), true)

    // No provider is enabled at all: the capability answer is unavailable
    // rather than an invented ticket state.
    let absent = candidateTicketConnection(None)
    let absentReply = absent.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH candidate-ticket-capability\n" +
        "GET_GENERATED_UI_CANDIDATE 11")
    @Assert(absentReply.contains("ERROR "), true)
    @Assert(absentReply.contains("TERMINAL_STATE"), false)
}
