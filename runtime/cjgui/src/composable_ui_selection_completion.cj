package cjgui

/// Experimental immutable publication of one actual A-to-B installation.
/// Native receipt and owner adoption are captured together, before the next
/// dequeue. This is an observation, not a new selection or write capability.
/// No native pointer or mutable platform object escapes this value.
public class CjguiInstalledSelectionCompletion {
    public let requestId: Int64
    public let windowSession: UInt64
    public let transferId: UInt64
    public let rendererSessionGeneration: UInt64
    public let windowInstanceToken: UInt64
    public let sourceSelection: CjguiSourceSelectionSnapshot
    public let semantic: CjguiTextSelectionTicket
    public let sourceOwnerVersion: Int64
    public let sourceContextEpoch: Int64
    public let sourceMirrorRevision: Int64
    public let sourceStartByte: Int64
    public let sourceEndByte: Int64
    public let sourceNodeId: Int64
    public let sourceBody: String
    public let targetNodeId: Int64
    public let targetResourceId: Int64
    public let targetSceneVersion: Int64
    public let targetProjectionVersion: Int64
    public let targetBindingEpoch: UInt64
    public let targetNodeKind: Int64
    public let targetProxyGeneration: UInt64
    public let targetSelectionRevision: UInt64
    public let targetSelectionStart16: Int64
    public let targetSelectionEnd16: Int64
    public let targetBody: String
    private let actualInstall: Bool
    private let sourceSemantic: CjguiTextSelectionTicket

    init(requestId: Int64, windowSession: UInt64, selected: CjguiSourceSelectionSnapshot,
        semantic: CjguiTextSelectionTicket, candidate: CjguiInternalSelectionTransferCandidate,
        receipt: CjguiInternalSelectionTransferReceipt, sourceBody: String, targetBody: String,
        sourceSemantic!: ?CjguiTextSelectionTicket = None) {
        this.requestId = requestId; this.windowSession = windowSession
        this.transferId = candidate.transferId
        this.rendererSessionGeneration = candidate.sourceRendererSessionGeneration
        this.windowInstanceToken = candidate.sourceWindowInstanceToken
        this.sourceSelection = selected; this.semantic = semantic
        this.sourceSemantic = sourceSemantic ?? semantic
        this.sourceOwnerVersion = candidate.sourceOwnerVersion
        this.sourceContextEpoch = Int64(candidate.sourceContextEpoch)
        this.sourceMirrorRevision = Int64(candidate.sourceMirrorRevision)
        this.sourceStartByte = Int64(candidate.sourceStartByte)
        this.sourceEndByte = Int64(candidate.sourceEndByte)
        this.sourceNodeId = Int64(candidate.sourceNodeId); this.sourceBody = sourceBody
        this.targetNodeId = Int64(receipt.nodeId); this.targetResourceId = receipt.resourceId
        this.targetSceneVersion = Int64(receipt.sceneVersion)
        this.targetProjectionVersion = Int64(receipt.projectionVersion)
        this.targetBindingEpoch = receipt.bindingEpoch; this.targetNodeKind = Int64(receipt.nodeKind)
        this.targetProxyGeneration = receipt.proxyGeneration
        this.targetSelectionRevision = receipt.selectionRevision
        this.targetSelectionStart16 = Int64(receipt.selectionStart16)
        this.targetSelectionEnd16 = Int64(receipt.selectionEnd16); this.targetBody = targetBody
        this.actualInstall = candidate.transferId != 0u64 && receipt.transferId == candidate.transferId &&
            candidate.sourceRendererSessionGeneration != 0u64 && candidate.sourceWindowInstanceToken != 0u64 &&
            receipt.firstResponder == 1u8 && receipt.proxyGeneration != 0u64 &&
            receipt.bindingEpoch != 0u64 && receipt.selectionRevision != 0u64 &&
            receipt.selectionStart16 == (if (candidate.targetAnchor16 <= candidate.targetFocus16) {
                candidate.targetAnchor16 } else { candidate.targetFocus16 }) &&
            receipt.selectionEnd16 == (if (candidate.targetAnchor16 >= candidate.targetFocus16) {
                candidate.targetAnchor16 } else { candidate.targetFocus16 }) &&
            receipt.nodeId == candidate.targetNodeId && receipt.resourceId == candidate.targetResourceId &&
            receipt.nodeKind == candidate.targetNodeKind && receipt.sceneVersion == candidate.targetSceneVersion &&
            receipt.projectionVersion == candidate.targetProjectionVersion
    }

    func matches(selected: CjguiSourceSelectionSnapshot, current: CjguiTextSelectionTicket,
        binding: UInt64, windowSession: UInt64): Bool {
        let frozen = this.sourceSelection
        return actualInstall && this.windowSession == windowSession && targetBindingEpoch == binding &&
            frozen.documentId.size > 0 && frozen.sessionEpoch > 0 &&
            frozen.documentId == selected.documentId && frozen.sessionEpoch == selected.sessionEpoch &&
            frozen.viewGeneration == selected.viewGeneration && frozen.version == selected.version &&
            frozen.revision == selected.revision && frozen.anchorByte == selected.anchorByte &&
            frozen.focusByte == selected.focusByte && sourceOwnerVersion == frozen.version &&
            frozen.revision == semantic.selectionRevision && sourceContextEpoch == sourceSemantic.contextEpoch &&
            sourceMirrorRevision == sourceSemantic.mirrorRevision && frozen.version == semantic.contentVersion &&
            semantic.contextEpoch == current.contextEpoch && semantic.mirrorRevision == current.mirrorRevision &&
            semantic.contentVersion == current.contentVersion && semantic.sourceVersion == current.sourceVersion &&
            semantic.selectionRevision == current.selectionRevision
    }
}

/// Optional synchronous owner notification. It runs after the existing
/// product publication and outside the selection owner's reservation lock.
/// Explicit restoration, AUTO and ordinary selection use the same receipt.
public interface CjguiComposableUiSelectionCompletionProvider {
    func selectionInstallationCompleted(completion: CjguiInstalledSelectionCompletion): Unit
}

/// One bounded observation slot. Pending is not the lifetime of completion.
/// Rechecking current identity expires old observations without replaying any
/// input; a repeated terminal can never notify the same installation twice.
class CjguiSelectionCompletionPublication {
    private var held: ?CjguiInstalledSelectionCompletion = None
    private var deliveredWindow: UInt64 = 0u64
    private var deliveredTransfer: UInt64 = 0u64
    private var deliveredProxy: UInt64 = 0u64

    func record(completion: CjguiInstalledSelectionCompletion, selected: CjguiSourceSelectionSnapshot,
        semantic: CjguiTextSelectionTicket, binding: UInt64, windowSession: UInt64): Bool {
        if (!completion.matches(selected, semantic, binding, windowSession)) { return false }
        if (deliveredWindow == windowSession && deliveredTransfer == completion.transferId &&
            deliveredProxy == completion.targetProxyGeneration) { return false }
        held = Some(completion)
        deliveredWindow = windowSession; deliveredTransfer = completion.transferId
        deliveredProxy = completion.targetProxyGeneration
        return true
    }

    func current(selected: CjguiSourceSelectionSnapshot, semantic: CjguiTextSelectionTicket,
        binding: UInt64, windowSession: UInt64): ?CjguiInstalledSelectionCompletion {
        if (let Some(completion) <- held) {
            if (completion.matches(selected, semantic, binding, windowSession)) { return Some(completion) }
        }
        held = None
        return None
    }

    func clear(): Unit {
        held = None
        deliveredWindow = 0u64; deliveredTransfer = 0u64; deliveredProxy = 0u64
    }
}
