package cjgui

/// Experimental owner selection seam. Endpoints are directed UTF-8 document
/// offsets, never coordinates in an input proxy. Revisions also change for a
/// same-valued new choice. Implementations arbitrate ALL owner writers.
public class CjguiSourceSelectionSnapshot {
    public let documentId: String
    public let sessionEpoch: Int64
    public let viewGeneration: Int64
    public let version: Int64
    public let revision: Int64
    public let anchorByte: Int64
    public let focusByte: Int64
    public init(version: Int64, revision: Int64, anchorByte: Int64, focusByte: Int64,
        documentId!: String = "", sessionEpoch!: Int64 = 0, viewGeneration!: Int64 = 0) {
        this.documentId = documentId; this.sessionEpoch = sessionEpoch; this.viewGeneration = viewGeneration
        this.version = version; this.revision = revision
        this.anchorByte = anchorByte; this.focusByte = focusByte
    }
    /// Experimental: collapse a nonempty directed source choice at its own
    /// endpoint. Empty/invalid choices return None; callers still freeze and
    /// arbitrate this snapshot's identity at the ordinary selection decision.
    public func nonemptyCollapseEndpoint(forward: Bool): ?Int64 {
        return cjguiNonemptySelectionCollapseEndpoint(anchorByte, focusByte, forward)
    }
}

// Shared endpoint semantics, also used by the plain mirror adapter. This
// chooses an existing boundary only; it grants no selection/write authority.
func cjguiNonemptySelectionCollapseEndpoint(anchor: Int64, focus: Int64, forward: Bool): ?Int64 {
    if (anchor < 0 || focus < 0 || anchor == focus) { return None }
    return Some(if (forward) { max(anchor, focus) } else { min(anchor, focus) })
}

/// Scalar-only calls: no AppKit dispatch, owner callback, allocation of a native
/// object, or waiting for UI work is permitted while the owner holds its lock.
/// 0 idle, 1 pending, 2 finalizing, 3 committed, 4 aborted/restored A,
/// 5 recovery blocked, 6 closed. Only 3 makes the reserved B authoritative.
public abstract class CjguiSelectionDecision {
    public func state(): Int64
    public func admitWriter(): Bool
}

public interface CjguiRangeTextSelectionOwner {
    func sourceSelectionSnapshot(): CjguiSourceSelectionSnapshot
    func setSourceSelection(version: Int64, anchorByte: Int64, focusByte: Int64): Bool
    /// Returns the actual reserved B revision, or -1 before admission. Aborted
    /// reservations may consume revisions; callers must never infer revision+1.
    func reserveSourceSelection(version: Int64, revision: Int64, anchorByte: Int64,
        focusByte: Int64, decision: CjguiSelectionDecision): Int64
    func settleSourceSelection(revision: Int64): Unit
}

class CjguiNativeSelectionDecision <: CjguiSelectionDecision {
    let session: UInt64
    let transfer: UInt64
    init(session: UInt64, transfer: UInt64) { this.session = session; this.transfer = transfer }
    public override func state(): Int64 {
        let value = internalRendererSelectionTransferState(session, transfer)
        if (value[0] != CJGUI_INTERNAL_RENDERER_OK) { return 6 }
        return match (value[1]) {
            case 1u32 => 1
            case 2u32 => 1
            case 3u32 => 2
            case 4u32 => 3
            case 5u32 => 4
            case 6u32 => 5
            case _ => 0
        }
    }
    public override func admitWriter(): Bool {
        let admitted = internalRendererAdmitSelectionTransferInput(session, transfer)
        return admitted[0] == CJGUI_INTERNAL_RENDERER_OK && admitted[1] == 0u32
    }
}

/// Experimental opt-in writer for a current owner source choice. The sink must
/// arbitrate the entire frozen identity at its real transaction/journal boundary.
/// No selected interior is materialised by the framework.
public interface CjguiRangeTextSelectionEditSink {
    func applySourceSelectionEdit(choice: CjguiSourceSelectionSnapshot, inserted: String): CjguiRangeTextEditOutcome
}

// One private original reservation. Its owner and decision never migrate to a
// later session; terminal folding happens while the native cell is still live.
class CjguiSourceSelectionReservation {
    let owner: CjguiRangeTextSelectionOwner
    let semantic: CjguiTextSelectionTicket
    let anchorByte: Int64
    let focusByte: Int64
    let revision: Int64
    let decision: CjguiSelectionDecision
    private var terminal: Int64 = 1
    init(owner: CjguiRangeTextSelectionOwner, semantic: CjguiTextSelectionTicket,
        anchor: Int64, focus: Int64, revision: Int64, decision: CjguiSelectionDecision) {
        this.owner = owner; this.semantic = semantic
        this.anchorByte = anchor; this.focusByte = focus
        this.revision = revision; this.decision = decision
    }
    func matches(ticket: CjguiTextSelectionTicket, anchor: Int64, focus: Int64): Bool {
        return semantic.contextEpoch == ticket.contextEpoch && semantic.mirrorRevision == ticket.mirrorRevision &&
            semantic.contentVersion == ticket.contentVersion && semantic.sourceVersion == ticket.sourceVersion &&
            semantic.selectionRevision == ticket.selectionRevision && anchorByte == anchor && focusByte == focus
    }
    func settle(): Bool {
        if (terminal == 3 || terminal == 4 || terminal == 6) { return terminal == 3 }
        let state = decision.state()
        if (state != 3 && state != 4 && state != 6) { return false }
        owner.settleSourceSelection(revision)
        terminal = state
        return terminal == 3
    }
}
