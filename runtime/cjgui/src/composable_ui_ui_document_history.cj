// Optional immutable UI-semantic mementos. Region/owner remain the live truth;
// this ledger contains no widget, native object, business value or ticket pump.
package cjgui

import std.collection.*

/// Experimental, per-document-session policy. Serialized snapshot bytes and
/// complete transactions are bounded independently. Disabled unless supplied.
public class CjguiUiDocumentHistoryPolicy {
    public let maximumTransactions: Int64
    public let maximumSerializedBytes: Int64

    public init(maximumTransactions!: Int64 = 32, maximumSerializedBytes!: Int64 = 2097152) {
        if (maximumTransactions <= 0 || maximumSerializedBytes <= 0) {
            throw IllegalArgumentException("ui_document_history_invalid_limit")
        }
        this.maximumTransactions = maximumTransactions
        this.maximumSerializedBytes = maximumSerializedBytes
    }
}

/// Facts, not a second mutable UI. Missing/off history does not sample a region.
public class CjguiUiDocumentHistoryState {
    public let supported: Bool
    public let enabled: Bool
    public let surfaceIdentity: Int64
    public let acceptedVersion: Int64
    public let acceptedDigest: String
    public let headVersion: Int64
    public let epoch: Int64
    public let undoDepth: Int64
    public let redoDepth: Int64
    public let retainedSerializedBytes: Int64
    public let maximumTransactions: Int64
    public let maximumSerializedBytes: Int64
    public let pendingAction: String
    public let pendingToken: Int64
    public let undoReason: String
    public let redoReason: String
    public let boundaryReason: String
    public let canUndo: Bool
    public let canRedo: Bool

    public init(enabled: Bool, surfaceIdentity!: Int64 = 0, acceptedVersion!: Int64 = -1,
        acceptedDigest!: String = "", headVersion!: Int64 = -1, epoch!: Int64 = 0,
        undoDepth!: Int64 = 0, redoDepth!: Int64 = 0, retainedSerializedBytes!: Int64 = 0,
        maximumTransactions!: Int64 = 0, maximumSerializedBytes!: Int64 = 0,
        pendingAction!: String = "", pendingToken!: Int64 = 0,
        undoReason!: String = "ui_document_history_disabled",
        redoReason!: String = "ui_document_history_disabled", boundaryReason!: String = "",
        supported!: Bool = true) {
        this.supported = supported
        this.enabled = enabled
        this.surfaceIdentity = surfaceIdentity
        this.acceptedVersion = acceptedVersion
        this.acceptedDigest = acceptedDigest
        this.headVersion = headVersion
        this.epoch = epoch
        this.undoDepth = undoDepth
        this.redoDepth = redoDepth
        this.retainedSerializedBytes = retainedSerializedBytes
        this.maximumTransactions = maximumTransactions
        this.maximumSerializedBytes = maximumSerializedBytes
        this.pendingAction = pendingAction
        this.pendingToken = pendingToken
        this.undoReason = undoReason
        this.redoReason = redoReason
        this.boundaryReason = boundaryReason
        this.canUndo = enabled && undoReason.size == 0
        this.canRedo = enabled && redoReason.size == 0
    }
}

// All access is under the owning document session's lock. Full accepted text
// already contains composition definitions/instances, properties, bindings and
// resource references. It never includes owner draft/applied values.
class CjguiUiDocumentHistory {
    let policy: CjguiUiDocumentHistoryPolicy
    let snapshots = ArrayList<CjguiGeneratedUiAcceptedDocument>()
    var position: Int64 = -1
    var retainedBytes: Int64 = 0
    var headVersion: Int64 = -1
    var headDigest: String = ""
    // Opaque process-local generations never repeat when another session is
    // attached to the same region at the same UI version/digest.
    var epoch: Int64 = cjguiNextUiDocumentSurfaceIdentity()
    var boundaryReason: String = ""
    var closed: Bool = false

    init(policy: CjguiUiDocumentHistoryPolicy) { this.policy = policy }

    func clear(reason: String): Unit {
        snapshots.clear()
        position = -1
        retainedBytes = 0
        headVersion = -1
        headDigest = ""
        boundaryReason = reason
        epoch = cjguiNextUiDocumentSurfaceIdentity()
    }

    func reset(accepted: CjguiGeneratedUiAcceptedDocument, reason: String): Unit {
        clear(reason)
        headVersion = accepted.version
        headDigest = accepted.digest
        // An uninitialized v0 region is not an undoable document. Its first
        // accepted UI establishes the initial session boundary.
        if (accepted.version == 0) {
            boundaryReason = "ui_document_history_initial_baseline"
            return
        }
        if (accepted.text.size > policy.maximumSerializedBytes) {
            boundaryReason = "ui_document_history_entry_too_large"
            return
        }
        snapshots.add(accepted)
        retainedBytes = accepted.text.size
        position = 0
    }

    // Every observed adjacent accepted version is one transaction. If an
    // application bypassed the normal completion seam and more than one
    // acceptance escaped observation, explicitly establish a new boundary;
    // never invent intermediate transactions or undo across the gap.
    func observe(accepted: CjguiGeneratedUiAcceptedDocument): Unit {
        if (closed) { return }
        if (headVersion < 0) { reset(accepted, boundaryReason); return }
        if (accepted.version == headVersion && accepted.digest == headDigest) { return }
        if (accepted.version != headVersion + 1) {
            reset(accepted, "ui_document_history_unobserved_change")
            return
        }
        let sameSemantic = accepted.digest == headDigest || (position >= 0 &&
            !uiDocDiffHasChanges(cjguiUiDocumentDiffLines(snapshots[position].text, accepted.text)))
        if (sameSemantic) {
            headVersion = accepted.version
            headDigest = accepted.digest
            if (position >= 0) {
                retainedBytes += accepted.text.size - snapshots[position].text.size
                snapshots[position] = accepted
                if (retainedBytes > policy.maximumSerializedBytes) {
                    reset(accepted, "ui_document_history_evicted")
                }
            }
            return // a semantic no-op is not a history transaction
        }
        if (position < 0) { reset(accepted, boundaryReason); return }
        if (accepted.text.size > policy.maximumSerializedBytes) {
            reset(accepted, "ui_document_history_entry_too_large")
            return
        }
        while (snapshots.size > position + 1) {
            let last = snapshots.size - 1
            retainedBytes -= snapshots[last].text.size
            let _ = snapshots.remove(at: last)
        }
        snapshots.add(accepted)
        retainedBytes += accepted.text.size
        position = snapshots.size - 1
        headVersion = accepted.version
        headDigest = accepted.digest
        boundaryReason = ""
        epoch = cjguiNextUiDocumentSurfaceIdentity()
        // Evict a COMPLETE oldest transaction by dropping its first snapshot;
        // the remaining first snapshot is the explicit new undo boundary.
        while (snapshots.size - 1 > policy.maximumTransactions ||
            retainedBytes > policy.maximumSerializedBytes) {
            retainedBytes -= snapshots[0].text.size
            let _ = snapshots.remove(at: 0)
            position -= 1
            boundaryReason = "ui_document_history_evicted"
        }
    }

    func target(action: String): Int64 {
        if (closed) { return -1 }
        if (action == "UI_DOC_UNDO" && position > 0) { return position - 1 }
        if (action == "UI_DOC_REDO" && position >= 0 && position + 1 < snapshots.size) { return position + 1 }
        return -1
    }

    func settle(target: Int64, expectedEpoch: Int64, accepted: CjguiGeneratedUiAcceptedDocument): Bool {
        if (closed || expectedEpoch != epoch || target < 0 || target >= snapshots.size ||
            snapshots[target].digest != accepted.digest || accepted.version != headVersion + 1) {
            return false
        }
        position = target
        headVersion = accepted.version
        headDigest = accepted.digest
        epoch = cjguiNextUiDocumentSurfaceIdentity()
        return true
    }

    func state(surface: Int64, accepted: CjguiGeneratedUiAcceptedDocument, mode: String,
        pendingAction: String, pendingToken: Int64): CjguiUiDocumentHistoryState {
        let undoDepth = if (position > 0) { position } else { 0 }
        let redoDepth = if (position >= 0) { snapshots.size - position - 1 } else { 0 }
        let unavailable = if (closed) { "ui_document_history_closed" }
            else if (mode == "submitted") { "ui_document_operation_pending" }
            else if (mode == "preview") { "ui_document_preview_pending" } else { "" }
        let undo = if (unavailable.size > 0) { unavailable }
            else if (undoDepth > 0) { "" }
            else if (position < 0 && boundaryReason.size > 0) { boundaryReason }
            else { "ui_document_nothing_to_undo" }
        let redo = if (unavailable.size > 0) { unavailable }
            else if (redoDepth > 0) { "" } else { "ui_document_nothing_to_redo" }
        return CjguiUiDocumentHistoryState(!closed, surfaceIdentity: surface,
            acceptedVersion: accepted.version, acceptedDigest: accepted.digest,
            headVersion: headVersion, epoch: epoch, undoDepth: undoDepth, redoDepth: redoDepth,
            retainedSerializedBytes: retainedBytes, maximumTransactions: policy.maximumTransactions,
            maximumSerializedBytes: policy.maximumSerializedBytes, pendingAction: pendingAction,
            pendingToken: if (mode == "submitted") { pendingToken } else { 0 },
            undoReason: undo, redoReason: redo, boundaryReason: boundaryReason)
    }
}
