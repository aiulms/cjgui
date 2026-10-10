/// Platform-neutral experimental source choice seams shared with the main framework.
/// H range sessions consume owner choices and the guarded writer for bounded paging.
/// Native E selection decision-port transfer is still not imported into OHOS.
package cjgui

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
}

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

/// Experimental opt-in writer for a current owner source choice. The sink must
/// arbitrate the entire frozen identity at its real transaction/journal boundary.
/// No selected interior is materialised by the framework.
public interface CjguiRangeTextSelectionEditSink {
    func applySourceSelectionEdit(choice: CjguiSourceSelectionSnapshot, inserted: String): CjguiRangeTextEditOutcome
}
