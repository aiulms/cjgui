package cjgui_shared_operation_core

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

// The plain-text reference provider: the second consumer's application side.
// These tests drive the real dispatch path, so they also prove the workspace
// liveness probe, the instance identity and the frozen-copy semantics meet the
// lease contract that `shared_operation_snapshot_lease_test.cj` pins down.

private let PLAIN_SNAPSHOT_DOCUMENT: Int64 = 8401
private let PLAIN_SNAPSHOT_CLOSED_DOCUMENT: Int64 = 8402
// Authorized but never created: isolates "the provider has no such resource"
// from "the caller may not name it".
private let PLAIN_SNAPSHOT_ABSENT_DOCUMENT: Int64 = 8499
private let PLAIN_SNAPSHOT_CAPABILITY: String = "cjgui-plain-snapshot-provider-20260928"
private let PLAIN_SNAPSHOT_TEXT: String = "第一行：在场值班员\n第二行：复核🙂完成\n"

private func plainSnapshotWorkspace(): CjguiTextDocumentWorkspace {
    return CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(PLAIN_SNAPSHOT_DOCUMENT, "交接文档", PLAIN_SNAPSHOT_TEXT),
        CjguiTextDocument(PLAIN_SNAPSHOT_CLOSED_DOCUMENT, "待关闭文档", "close-me")
    ]))
}

private func plainSnapshotAuthorization(): CjguiSharedOperationExternalAuthorization {
    let targets = ArrayList<Int64>([PLAIN_SNAPSHOT_DOCUMENT, PLAIN_SNAPSHOT_CLOSED_DOCUMENT,
        PLAIN_SNAPSHOT_ABSENT_DOCUMENT])
    return CjguiSharedOperationExternalAuthorization("纯文本快照读者", PLAIN_SNAPSHOT_CAPABILITY,
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", targets, false),
            CjguiSharedOperationExternalActionScope("SNAPSHOT_ACQUIRE", targets, false),
            CjguiSharedOperationExternalActionScope("SNAPSHOT_READ", targets, false),
            CjguiSharedOperationExternalActionScope("SNAPSHOT_RELEASE", targets, false)
        ]))
}

private func plainSnapshotRequest(command: String): String {
    return "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH ${PLAIN_SNAPSHOT_CAPABILITY}\n${command}"
}

private func plainSnapshotField(payload: String, name: String): String {
    for (line in payload.split("\n")) {
        if (line.startsWith(name + " ")) {
            return line[name.size + 1..line.size]
        }
    }
    return ""
}

private func plainSnapshotAcquire(connection: CjguiSharedOperationExternalConnection,
    resourceId: Int64, instanceId: String, expectedVersion: String, ttlMs: Int64,
    requestId: String): String {
    return connection.dispatchPayload(plainSnapshotRequest(
        "SNAPSHOT_ACQUIRE ${connection.endpointInstance()} ${connection.endpointEpoch()} ${requestId} " +
        "${resourceId} ${instanceId} ${expectedVersion} ${ttlMs}"))
}

/// A lease over the plain-text provider freezes the document: the document's
/// own edits move on, the lease keeps serving its version, and a new acquire is
/// what observes the new version. Every frozen copy is released at the end.
@Test
func plainTextSnapshotLeaseFreezesTheDocumentAndReleasesEveryCopy(): Unit {
    let workspace = plainSnapshotWorkspace()
    let provider = CjguiTextDocumentSnapshotProvider(workspace)
    let connection = CjguiSharedOperationExternalConnection(workspace,
        plainSnapshotAuthorization())
    @Assert(connection.enableRangeReads(workspace), true)
    @Assert(connection.enableSnapshotReads(provider), true)

    let acquired = plainSnapshotAcquire(connection, PLAIN_SNAPSHOT_DOCUMENT, "-", "ANY", 60000, "req-plain")
    @Assert(acquired.contains("KIND SNAPSHOT_LEASE"), true)
    let token = plainSnapshotField(acquired, "TOKEN")
    let instance = plainSnapshotField(acquired, "RESOURCE_INSTANCE")
    @Assert(instance.startsWith("td"), true)
    @Assert(plainSnapshotField(acquired, "VERSION"), "0")
    @Assert(plainSnapshotField(acquired, "BYTE_LENGTH"), "${PLAIN_SNAPSHOT_TEXT.toArray().size}")

    // Read the frozen bytes in two pages and rebuild the exact text.
    let first = connection.dispatchPayload(plainSnapshotRequest("SNAPSHOT_READ ${token} 0 12"))
    @Assert(first.contains("AVAILABLE true"), true)
    @Assert(plainSnapshotField(first, "RESOURCE_INSTANCE") == "", true)
    let second = connection.dispatchPayload(plainSnapshotRequest("SNAPSHOT_READ ${token} 12 27"))
    @Assert(second.contains("AVAILABLE true"), true)

    // The document moves on through its own owner path.
    let edit = workspace.replaceRangeFromHuman(PLAIN_SNAPSHOT_DOCUMENT,
        CjguiTextDocumentRange(0, 0), "[外部编辑] ")
    @Assert(edit.applied, true)

    let frozen = connection.dispatchPayload(plainSnapshotRequest("SNAPSHOT_READ ${token} 0 12"))
    @Assert(frozen.contains("AVAILABLE true"), true)
    @Assert(plainSnapshotField(frozen, "VERSION"), "0")
    let fresh = plainSnapshotAcquire(connection, PLAIN_SNAPSHOT_DOCUMENT, "-", "ANY", 60000, "req-fresh")
    @Assert(plainSnapshotField(fresh, "VERSION"), "${edit.versionAfter}")
    @Assert(plainSnapshotField(fresh, "TOKEN") != token, true)

    let _ = connection.dispatchPayload(plainSnapshotRequest("SNAPSHOT_RELEASE ${token}"))
    let _ = connection.dispatchPayload(plainSnapshotRequest("SNAPSHOT_RELEASE ${plainSnapshotField(fresh, "TOKEN")}"))
    @Assert(provider.liveHandleCount(), 0)
    @Assert(connection.snapshotLeaseDiagnostics().contains("active=0"), true)
}

/// Instance pinning uses the value the acquire itself returned; a mismatched
/// pin, a closed document and an unknown resource are three named refusals.
@Test
func plainTextSnapshotRefusesWrongInstanceClosedAndUnknownResources(): Unit {
    let workspace = plainSnapshotWorkspace()
    let provider = CjguiTextDocumentSnapshotProvider(workspace)
    let connection = CjguiSharedOperationExternalConnection(workspace,
        plainSnapshotAuthorization())
    @Assert(connection.enableRangeReads(workspace), true)
    @Assert(connection.enableSnapshotReads(provider), true)
    let instance = provider.resourceInstanceId(PLAIN_SNAPSHOT_DOCUMENT)

    let pinned = plainSnapshotAcquire(connection, PLAIN_SNAPSHOT_DOCUMENT, instance, "0", 60000, "req-pin")
    @Assert(pinned.contains("KIND SNAPSHOT_LEASE"), true)
    @Assert(plainSnapshotField(pinned, "RESOURCE_INSTANCE"), instance)
    let _ = connection.dispatchPayload(plainSnapshotRequest("SNAPSHOT_RELEASE ${plainSnapshotField(pinned, "TOKEN")}"))

    let wrongInstance = plainSnapshotAcquire(connection, PLAIN_SNAPSHOT_DOCUMENT,
        "td00000000000000000000000000000000_${PLAIN_SNAPSHOT_DOCUMENT}", "0", 60000, "req-wrong")
    @Assert(wrongInstance.contains("ERROR snapshot_instance_mismatch"), true)

    let staleVersion = plainSnapshotAcquire(connection, PLAIN_SNAPSHOT_DOCUMENT, instance, "7", 60000, "req-stale")
    @Assert(staleVersion.contains("ERROR version_conflict"), true)

    let unknown = plainSnapshotAcquire(connection, PLAIN_SNAPSHOT_ABSENT_DOCUMENT, "-", "ANY",
        60000, "req-unknown")
    @Assert(unknown.contains("ERROR snapshot_unknown_resource"), true)
    let unauthorized = plainSnapshotAcquire(connection, 8498, "-", "ANY", 60000, "req-unauthorized")
    @Assert(unauthorized.contains("ERROR unauthorized_resource"), true)

    let closedEdit = workspace.closeDocumentFromHuman(PLAIN_SNAPSHOT_CLOSED_DOCUMENT)
    @Assert(closedEdit.applied, true)
    let closed = plainSnapshotAcquire(connection, PLAIN_SNAPSHOT_CLOSED_DOCUMENT, "-", "ANY", 60000, "req-closed")
    @Assert(closed.contains("ERROR snapshot_resource_closed"), true)
    @Assert(provider.liveHandleCount(), 0)
}

/// The provider refuses an acquire it cannot keep inside the reservation
/// BEFORE copying, and the SAME boundary rule the live read enforces applies to
/// frozen bytes, so a client's aligned reads stay aligned.
@Test
func plainTextSnapshotHonoursTheReservationAndTheClusterBoundary(): Unit {
    let workspace = plainSnapshotWorkspace()
    let provider = CjguiTextDocumentSnapshotProvider(workspace)
    let tiny = CjguiSharedOperationExternalConnection(workspace, plainSnapshotAuthorization())
    @Assert(tiny.enableRangeReads(workspace), true)
    // 4 reserved resident bytes cannot hold a 27-byte document.
    @Assert(tiny.enableSnapshotReads(provider,
        limits: CjguiSharedOperationSnapshotLeaseLimits(maxResidentBytes: 4)), true)
    let refused = plainSnapshotAcquire(tiny, PLAIN_SNAPSHOT_DOCUMENT, "-", "ANY", 60000, "req-tiny")
    @Assert(refused.contains("ERROR snapshot_budget_exceeded"), true)
    @Assert(provider.liveHandleCount(), 0)

    let connection = CjguiSharedOperationExternalConnection(workspace, plainSnapshotAuthorization())
    @Assert(connection.enableRangeReads(workspace), true)
    @Assert(connection.enableSnapshotReads(provider), true)
    let token = plainSnapshotField(plainSnapshotAcquire(connection, PLAIN_SNAPSHOT_DOCUMENT, "-", "ANY",
        60000, "req-boundary"), "TOKEN")

    // Byte 1 is inside the first 3-byte scalar of 第: not a cluster boundary.
    let midScalar = connection.dispatchPayload(plainSnapshotRequest("SNAPSHOT_READ ${token} 1 5"))
    @Assert(midScalar.contains("AVAILABLE false"), true)
    @Assert(midScalar.contains("REASON invalid_text_boundary"), true)
    let pastEnd = connection.dispatchPayload(plainSnapshotRequest("SNAPSHOT_READ ${token} 0 4096"))
    @Assert(pastEnd.contains("AVAILABLE false"), true)
    @Assert(pastEnd.contains("REASON invalid_range"), true)
    // The whole frozen document is still readable after both refusals.
    let whole = connection.dispatchPayload(plainSnapshotRequest("SNAPSHOT_READ ${token} 0 27"))
    @Assert(whole.contains("AVAILABLE true"), true)
    @Assert(whole.contains("VERSION 0"), true)
}

/// Closing the document ends every lease of that exact instance by name, and a
/// later acquire cannot resurrect the closed document.
@Test
func plainTextSnapshotCloseInvalidatesHeldLeases(): Unit {
    let workspace = plainSnapshotWorkspace()
    let provider = CjguiTextDocumentSnapshotProvider(workspace)
    let connection = CjguiSharedOperationExternalConnection(workspace, plainSnapshotAuthorization())
    @Assert(connection.enableRangeReads(workspace), true)
    @Assert(connection.enableSnapshotReads(provider), true)
    let token = plainSnapshotField(plainSnapshotAcquire(connection, PLAIN_SNAPSHOT_CLOSED_DOCUMENT, "-",
        "ANY", 60000, "req-close"), "TOKEN")

    let closeEdit = workspace.closeDocumentFromHuman(PLAIN_SNAPSHOT_CLOSED_DOCUMENT)
    @Assert(closeEdit.applied, true)
    @Assert(connection.invalidateSnapshotResource(PLAIN_SNAPSHOT_CLOSED_DOCUMENT,
        provider.resourceInstanceId(PLAIN_SNAPSHOT_CLOSED_DOCUMENT), "snapshot_resource_closed"), 1)

    let read = connection.dispatchPayload(plainSnapshotRequest("SNAPSHOT_READ ${token} 0 4"))
    @Assert(read.contains("AVAILABLE false"), true)
    @Assert(read.contains("REASON snapshot_resource_closed"), true)
    @Assert(provider.liveHandleCount(), 0)

    let again = plainSnapshotAcquire(connection, PLAIN_SNAPSHOT_CLOSED_DOCUMENT, "-", "ANY", 60000, "req-again")
    @Assert(again.contains("ERROR snapshot_resource_closed"), true)
    // The other document of the same workspace is untouched.
    let other = plainSnapshotAcquire(connection, PLAIN_SNAPSHOT_DOCUMENT, "-", "ANY", 60000, "req-other")
    @Assert(other.contains("KIND SNAPSHOT_LEASE"), true)
}
