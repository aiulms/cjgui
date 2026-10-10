package cjgui

/// Experimental proposal for one scene candidate. Source provenance and the
/// proposed target remain separate; this value is neither an installation nor
/// input authorization. Providers freeze it before constructing decorations.
public class CjguiComposableUiCandidateSelectionProjection {
    public let sourceCompletion: ?CjguiInstalledSelectionCompletion
    public let selection: CjguiSourceSelectionSnapshot
    public let semantic: CjguiTextSelectionTicket
    public let mappingIdentity: String
    public let targetNodeId: Int64
    public let targetResourceId: Int64
    public let targetNodeKind: Int64
    public let targetBody: String
    public let localAnchor16: Int64
    public let localFocus16: Int64
    public let localCaretByte: Int64
    public let affinity: UInt32

    public init(source: ?CjguiInstalledSelectionCompletion, selection: CjguiSourceSelectionSnapshot,
        semantic: CjguiTextSelectionTicket, mappingIdentity: String,
        targetNodeId: Int64, targetResourceId: Int64, targetNodeKind: Int64, body: String,
        localAnchor16: Int64, localFocus16: Int64, localCaretByte: Int64,
        affinity!: UInt32 = 2u32) {
        this.sourceCompletion = source; this.selection = selection; this.semantic = semantic
        this.mappingIdentity = mappingIdentity; this.targetNodeId = targetNodeId
        this.targetResourceId = targetResourceId; this.targetNodeKind = targetNodeKind
        this.targetBody = body; this.localAnchor16 = localAnchor16; this.localFocus16 = localFocus16
        this.localCaretByte = localCaretByte; this.affinity = affinity
    }
}

/// None explicitly means no candidate caret or input migration. Initial,
/// unfocused scenes need no invented receipt. Unprovided legacy consumers keep
/// their existing behavior and get a frozen copy of the accepted caret.
public interface CjguiComposableUiCandidateSelectionProvider {
    func candidateSelectionProjection(): ?CjguiComposableUiCandidateSelectionProjection
}

class CjguiCandidateSelectionDeclaration {
    let projection: ?CjguiComposableUiCandidateSelectionProjection
    init(projection: ?CjguiComposableUiCandidateSelectionProjection) { this.projection = projection }
}

// Installed receipts deliberately do not participate in proposal equality:
// accepting the same proposal produces a successor receipt, not new geometry.
// Mapping and input responsibility still change even when node pixels match.
func cjguiSameCandidateSelection(previous: ?CjguiCandidateSelectionDeclaration,
    candidate: ?CjguiCandidateSelectionDeclaration): Bool {
    if (previous.isNone() || candidate.isNone()) { return previous.isNone() && candidate.isNone() }
    let old = previous.getOrThrow().projection
    let next = candidate.getOrThrow().projection
    if (old.isNone() || next.isNone()) { return old.isNone() && next.isNone() }
    let a = old.getOrThrow(); let b = next.getOrThrow()
    return cjguiSameSourceChoice(a.selection, b.selection) &&
        a.semantic.contextEpoch == b.semantic.contextEpoch && a.semantic.mirrorRevision == b.semantic.mirrorRevision &&
        a.semantic.contentVersion == b.semantic.contentVersion && a.semantic.sourceVersion == b.semantic.sourceVersion &&
        a.semantic.selectionRevision == b.semantic.selectionRevision && a.mappingIdentity == b.mappingIdentity &&
        a.targetNodeId == b.targetNodeId && a.targetResourceId == b.targetResourceId &&
        a.targetNodeKind == b.targetNodeKind && a.targetBody == b.targetBody &&
        a.localAnchor16 == b.localAnchor16 && a.localFocus16 == b.localFocus16 &&
        a.localCaretByte == b.localCaretByte && a.affinity == b.affinity
}
