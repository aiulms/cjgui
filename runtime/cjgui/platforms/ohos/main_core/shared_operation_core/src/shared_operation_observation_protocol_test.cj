// Generated-UI observation protocol tests (package B3/B4, transport layer).
//
// The provider owns the snapshot; the transport only wraps it and attaches the
// endpoint epoch:
//   * `GET_GENERATED_UI_SNAPSHOT` returns ONE envelope tagged with the endpoint;
//   * `GET_GENERATED_UI_CHANGES <stream_epoch> <cursor>` carries the bounded
//     change body and nothing else;
//   * a provider without the observation seam is unavailable, which is a
//     DIFFERENT fact from "no changes";
//   * a malformed changes header is a request fault.
package cjgui_shared_operation_core

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private class ObservingProvider <: CjguiSharedOperationGeneratedUiProvider {
    public func capabilitiesPayload(): String { return "" }
    public func fieldsPayload(): String { return "" }
    public func acceptedStructurePayload(): String { return "" }
    public func acceptedStructureVersion(): Int64 { return 4 }
    public func submitStructure(candidatePayload: String, expectedVersion: Int64):
        CjguiSharedOperationGeneratedUiSubmit {
        return CjguiSharedOperationGeneratedUiSubmit(false, "not_implemented", "",
            expectedVersion, expectedVersion)
    }

    public func snapshotPayload(): String {
        return "STREAM_EPOCH 1\nCURSOR 7\nOWNER_FIELD_REVISION 12\nACCEPTED_STRUCTURE_VERSION 4\n" +
            "OWNER_PENDING_SCENE 0\nSNAPSHOT_STRUCTURE NODE 0 root vertical\nEND"
    }

    public func changesPayload(streamEpoch: Int64, cursor: Int64): String {
        if (streamEpoch != 1) {
            return "STREAM_EPOCH 1\nSINCE ${cursor}\nCURRENT 9\nRESYNC_REQUIRED 1\nEND"
        }
        return "STREAM_EPOCH 1\nSINCE ${cursor}\nCURRENT 9\nRESYNC_REQUIRED 0\n" +
            "CHANGE 8 FIELDS detail\nCHANGE 9 SCENE detail\nEND"
    }

    public func sectionPayload(section: String, expectedCursor: Int64): String {
        let header = "SECTION ${section}\nSTREAM_EPOCH 1\nSTREAM_IDENTITY session-1\nCURSOR 9\n"
        if (expectedCursor != 9) {
            return "${header}SNAPSHOT_REVISION_CHANGED 1"
        }
        if (section == "FIELDS") {
            return "${header}SNAPSHOT_REVISION_CHANGED 0\nSNAPSHOT_FIELD FIELD label 81001 DRAFT_HEX 41"
        }
        if (section == "INSTANCES") {
            return "${header}SNAPSHOT_REVISION_CHANGED 0\nSNAPSHOT_INSTANCE INSTANCE edit id=812001"
        }
        return "${header}SNAPSHOT_REVISION_CHANGED 1"
    }
}

private class SilentObservationProvider <: CjguiSharedOperationGeneratedUiProvider {
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

private func observationAuthorization(): CjguiSharedOperationExternalAuthorization {
    return CjguiSharedOperationExternalAuthorization(
        "观测验收调用者",
        "observation-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_GENERATED_UI", ArrayList<Int64>(), true)
        ])
    )
}

private func observationConnection(provider: ?CjguiSharedOperationGeneratedUiProvider):
    CjguiSharedOperationExternalConnection {
    let connection = CjguiSharedOperationExternalConnection(
        CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>()),
        observationAuthorization())
    if (let Some(active) <- provider) {
        let _ = connection.enableGeneratedUiProvider(active)
    }
    return connection
}

@Test
func snapshotReadIsOneEnvelopeWithTheEndpointEpoch(): Unit {
    let connection = observationConnection(Some(ObservingProvider()))
    let reply = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH observation-capability\nGET_GENERATED_UI_SNAPSHOT")
    @Assert(reply.contains("KIND GENERATED_UI_SNAPSHOT"), true)
    @Assert(reply.contains("ENDPOINT_EPOCH "), true)
    @Assert(reply.contains("STREAM_EPOCH 1"), true)
    @Assert(reply.contains("CURSOR 7"), true)
    @Assert(reply.contains("OWNER_FIELD_REVISION 12"), true)
    @Assert(reply.contains("SNAPSHOT_STRUCTURE NODE 0 root vertical"), true)
    @Assert(reply.endsWith("END"), true)

    // A provider without the seam is unavailable, not "no changes".
    let silent = observationConnection(Some(SilentObservationProvider()))
    let unavailable = silent.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH observation-capability\nGET_GENERATED_UI_SNAPSHOT")
    @Assert(unavailable.contains("ERROR generated_ui_unavailable"), true)
}

@Test
func sectionReadIsRefusedWhenItsCursorMoved(): Unit {
    let connection = observationConnection(Some(ObservingProvider()))
    let fields = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH observation-capability\n" +
        "GET_GENERATED_UI_SECTION FIELDS 9")
    @Assert(fields.contains("KIND GENERATED_UI_SECTION"), true)
    @Assert(fields.contains("ENDPOINT_EPOCH "), true)
    @Assert(fields.contains("CURSOR 9"), true)
    @Assert(fields.contains("SNAPSHOT_REVISION_CHANGED 0"), true)
    @Assert(fields.contains("SNAPSHOT_FIELD FIELD label 81001"), true)
    @Assert(fields.contains("SNAPSHOT_INSTANCE"), false)

    // A moved cursor publishes the flag and NO section content.
    let moved = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH observation-capability\n" +
        "GET_GENERATED_UI_SECTION FIELDS 3")
    @Assert(moved.contains("SNAPSHOT_REVISION_CHANGED 1"), true)
    @Assert(moved.contains("SNAPSHOT_FIELD"), false)

    // An unknown section and a malformed cursor are request faults.
    let unknown = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH observation-capability\n" +
        "GET_GENERATED_UI_SECTION SECRETS 9")
    @Assert(unknown.contains("ERROR invalid_request"), true)
    let malformed = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH observation-capability\n" +
        "GET_GENERATED_UI_SECTION FIELDS notANumber")
    @Assert(malformed.contains("ERROR invalid_request"), true)

    // A provider without the seam is unavailable, not an empty section.
    let silent = observationConnection(Some(SilentObservationProvider()))
    let unavailable = silent.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH observation-capability\n" +
        "GET_GENERATED_UI_SECTION FIELDS 9")
    @Assert(unavailable.contains("ERROR generated_ui_unavailable"), true)
}

@Test
func changesReadCarriesOnlyTheBoundedChangeBody(): Unit {
    let connection = observationConnection(Some(ObservingProvider()))
    let reply = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH observation-capability\n" +
        "GET_GENERATED_UI_CHANGES 1 7")
    @Assert(reply.contains("KIND GENERATED_UI_CHANGES"), true)
    @Assert(reply.contains("SINCE 7"), true)
    @Assert(reply.contains("CURRENT 9"), true)
    @Assert(reply.contains("RESYNC_REQUIRED 0"), true)
    @Assert(reply.contains("CHANGE 8 FIELDS"), true)
    @Assert(reply.contains("NODE "), false)
    @Assert(reply.endsWith("END"), true)

    // A stale stream epoch asks for a resync rather than replaying the history.
    let resync = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH observation-capability\n" +
        "GET_GENERATED_UI_CHANGES 2 7")
    @Assert(resync.contains("RESYNC_REQUIRED 1"), true)

    // Malformed headers stay request faults.
    let malformed = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH observation-capability\n" +
        "GET_GENERATED_UI_CHANGES one two")
    @Assert(malformed.contains("ERROR invalid_request"), true)
    let missingCursor = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH observation-capability\n" +
        "GET_GENERATED_UI_CHANGES 1")
    @Assert(missingCursor.contains("ERROR invalid_request"), true)
}
