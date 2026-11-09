package cjgui_shared_operation_core

import std.collection.*
import std.random.*

// A frozen copy of the document bytes plus the two object headers the lease
// keeps alive. The bound is what the lease RESERVES for its whole holding
// period, so it is declared before the copy is made.
private const CJGUI_TEXT_SNAPSHOT_RESIDENT_OVERHEAD_BYTES: Int64 = 64

/// Plain-text reference provider for the fixed-snapshot lease (E1). This is the
/// application side a second consumer needs: the framework owns tokens, TTL and
/// limits, this owns "what is a document, and what is an immutable snapshot of
/// it".
///
/// Instance identity is the document OBJECT, not its resource id: the prefix is
/// generated once per provider instance, so two workspaces (or a later process)
/// reusing document id 8101 never present the same instance id.
///
/// Owner-thread only, like every other participant in a lease: the transport
/// handlers and the disposal path both run there, so this holds no lock of its
/// own. `liveHandleCount` is read by the application AFTER the endpoint closed.
public class CjguiTextDocumentSnapshotProvider <: CjguiSharedOperationSnapshotProvider {
    private let workspace: CjguiTextDocumentWorkspace
    private let instancePrefix: String
    // Diagnostics: handles handed out and not yet released. The owner prints
    // this after the endpoint closes to show every lease was converged.
    private var liveHandles: Int64 = 0

    public init(workspace: CjguiTextDocumentWorkspace) {
        this.workspace = workspace
        this.instancePrefix = "td${sharedTextSnapshotHex16()}${sharedTextSnapshotHex16()}"
    }

    public func resourceInstanceId(resourceId: Int64): String {
        return "${this.instancePrefix}_${resourceId}"
    }

    /// Handles handed out minus handles released; 0 after the endpoint closed.
    public func liveHandleCount(): Int64 {
        return this.liveHandles
    }

    func releaseHandle(): Unit {
        if (this.liveHandles > 0) {
            this.liveHandles -= 1
        }
    }

    public func snapshotResourceState(resourceId: Int64): CjguiSharedOperationSnapshotResourceState {
        let liveness = this.workspace.documentLiveness(resourceId)
        if (liveness == "open") {
            return CjguiSharedOperationSnapshotResourceState.open(this.resourceInstanceId(resourceId))
        }
        if (liveness == "document_closed") {
            return CjguiSharedOperationSnapshotResourceState.closed(this.resourceInstanceId(resourceId))
        }
        return CjguiSharedOperationSnapshotResourceState.unknown()
    }

    public func acquireSnapshotFromExternal(resourceId: Int64, expectedInstanceId: String,
        expectedVersion: Int64, retentionBudget: CjguiSharedOperationSnapshotRetentionBudget
    ): CjguiSharedOperationSnapshotAcquireResult {
        let state = this.snapshotResourceState(resourceId)
        if (!state.isKnown) {
            return CjguiSharedOperationSnapshotAcquireResult.refused("snapshot_unknown_resource")
        }
        if (!state.isOpen) {
            return CjguiSharedOperationSnapshotAcquireResult.refused("snapshot_resource_closed")
        }
        if (expectedInstanceId != "" && expectedInstanceId != state.instanceId) {
            return CjguiSharedOperationSnapshotAcquireResult.refused("snapshot_instance_mismatch")
        }
        let snapshot = match (this.workspace.documentSnapshot(resourceId)) {
            case Some(value) => value
            case None => return CjguiSharedOperationSnapshotAcquireResult.refused("snapshot_resource_closed")
        }
        if (expectedVersion >= 0 && snapshot.version != expectedVersion) {
            return CjguiSharedOperationSnapshotAcquireResult.refused("version_conflict")
        }
        // Check the reservation BEFORE copying: a refused acquire must not
        // allocate what it cannot keep.
        let residentBound = Int64(snapshot.content.size) + CJGUI_TEXT_SNAPSHOT_RESIDENT_OVERHEAD_BYTES
        if (residentBound > retentionBudget.residentBytes || retentionBudget.openResources < 1) {
            return CjguiSharedOperationSnapshotAcquireResult.refused("snapshot_budget_exceeded")
        }
        let handle = CjguiTextDocumentSnapshotHandle(this, snapshot, state.instanceId)
        this.liveHandles += 1
        return CjguiSharedOperationSnapshotAcquireResult.acquired(handle,
            CjguiSharedOperationSnapshotRetentionCost(residentBound, 0, 1))
    }
}

/// One frozen plain-text snapshot. The bytes are copied ONCE at acquire and
/// never follow the document; every read answers exactly those bytes and the
/// version they were taken at. Release is idempotent.
private class CjguiTextDocumentSnapshotHandle <: CjguiSharedOperationSnapshotHandle {
    private let provider: CjguiTextDocumentSnapshotProvider
    private let infoValue: CjguiSharedOperationSnapshotInfo
    private let bytes: Array<UInt8>
    private var released: Bool = false

    init(provider: CjguiTextDocumentSnapshotProvider, snapshot: CjguiTextDocumentSnapshot,
        instanceId: String) {
        this.provider = provider
        this.bytes = snapshot.content.toArray()
        this.infoValue = CjguiSharedOperationSnapshotInfo(snapshot.documentId, instanceId,
            snapshot.version, Int64(this.bytes.size))
    }

    public func snapshotInfo(): CjguiSharedOperationSnapshotInfo {
        return this.infoValue
    }

    public func readRange(start: Int64, end: Int64): CjguiSharedOperationRangeRead {
        if (this.released) {
            return CjguiSharedOperationRangeRead(false, false, this.infoValue.resourceId,
                this.infoValue.version, start, end, "", "snapshot_released")
        }
        // The same boundary rule the live READ_RANGE enforces, so a client that
        // aligns reads against the live document is aligned here too.
        if (!isTextRangeBoundary(this.bytes, CjguiTextDocumentRange(start, end))) {
            return CjguiSharedOperationRangeRead(false, false, this.infoValue.resourceId,
                this.infoValue.version, start, end, "", "invalid_text_boundary")
        }
        return CjguiSharedOperationRangeRead(true, false, this.infoValue.resourceId,
            this.infoValue.version, start, end,
            String.fromUtf8(this.bytes.slice(start, end - start)), "available")
    }

    public func release(): Unit {
        if (this.released) {
            return
        }
        this.released = true
        this.provider.releaseHandle()
    }
}

private func sharedTextSnapshotHex16(): String {
    let digits = "0123456789abcdef"
    let builder = StringBuilder()
    var value = Random().nextUInt64()
    var shift = 60
    while (shift >= 0) {
        let nibble = Int64((value >> UInt64(shift)) & 0xF)
        builder.append(digits[nibble..(nibble + 1)])
        shift -= 4
    }
    return builder.toString()
}
