package cjgui

import std.env.*

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
    func firstMismatch(selected: CjguiSourceSelectionSnapshot, current: CjguiTextSelectionTicket,
        binding: UInt64, windowSession: UInt64): String {
        let frozen = this.sourceSelection
        if (!(actualInstall)) { return "actual_install" }
        if (!(this.windowSession == windowSession)) { return "window" }
        if (!(targetBindingEpoch == binding)) { return "binding" }
        if (!(frozen.documentId.size > 0)) { return "document_valid" }
        if (!(frozen.sessionEpoch > 0)) { return "epoch_valid" }
        if (!(frozen.documentId == selected.documentId)) { return "document" }
        if (!(frozen.sessionEpoch == selected.sessionEpoch)) { return "epoch" }
        if (!(frozen.viewGeneration == selected.viewGeneration)) { return "view_generation" }
        if (!(frozen.version == selected.version)) { return "owner_version" }
        if (!(frozen.revision == selected.revision)) { return "owner_revision" }
        if (!(frozen.anchorByte == selected.anchorByte)) { return "source_anchor" }
        if (!(frozen.focusByte == selected.focusByte)) { return "source_focus" }
        if (!(sourceOwnerVersion == frozen.version)) { return "source_owner_version" }
        if (!(frozen.revision == semantic.selectionRevision)) { return "frozen_selection_revision" }
        if (!(sourceContextEpoch == sourceSemantic.contextEpoch)) { return "source_context" }
        if (!(sourceMirrorRevision == sourceSemantic.mirrorRevision)) { return "source_mirror" }
        if (!(frozen.version == semantic.contentVersion)) { return "frozen_content_version" }
        if (!(semantic.contextEpoch == current.contextEpoch)) { return "context" }
        if (!(semantic.mirrorRevision == current.mirrorRevision)) { return "mirror" }
        if (!(semantic.contentVersion == current.contentVersion)) { return "content_version" }
        if (!(semantic.sourceVersion == current.sourceVersion)) { return "source_version" }
        if (!(semantic.selectionRevision == current.selectionRevision)) { return "selection_revision" }
        return "none"
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
    private var failureObservations: Int64 = 0
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
            if (failureObservations < 16 && getVariable("CJGUI_TRACE_IME_PUMP") == Some("1")) {
                failureObservations += 1
                getStdOut().writeln("CJGUI_COMPLETION_EXPIRED mono_ns=${unsafe { cjgui_internal_renderer_owner_clock_ns() }} " +
                    "session=${windowSession} transfer=${completion.transferId} proxy=${completion.targetProxyGeneration} " +
                    "reason=${completion.firstMismatch(selected, semantic, binding, windowSession)} " +
                    "old_binding=${completion.targetBindingEpoch} binding=${binding} " +
                    "old_epoch=${completion.sourceSelection.sessionEpoch} epoch=${selected.sessionEpoch} " +
                    "old_view=${completion.sourceSelection.viewGeneration} view=${selected.viewGeneration} " +
                    "old_version=${completion.sourceSelection.version} version=${selected.version} " +
                    "old_revision=${completion.sourceSelection.revision} revision=${selected.revision} " +
                    "old_anchor=${completion.sourceSelection.anchorByte} anchor=${selected.anchorByte} " +
                    "old_focus=${completion.sourceSelection.focusByte} focus=${selected.focusByte} " +
                    "old_context=${completion.semantic.contextEpoch} context=${semantic.contextEpoch} " +
                    "old_mirror=${completion.semantic.mirrorRevision} mirror=${semantic.mirrorRevision} " +
                    "old_content=${completion.semantic.contentVersion} content=${semantic.contentVersion} " +
                    "old_source=${completion.semantic.sourceVersion} source=${semantic.sourceVersion} " +
                    "old_selection=${completion.semantic.selectionRevision} selection=${semantic.selectionRevision}")
                getStdOut().flush()
            }
        }
        held = None
        return None
    }

    func clear(): Unit {
        if (let Some(completion) <- held) {
            if (failureObservations < 16 && getVariable("CJGUI_TRACE_IME_PUMP") == Some("1")) {
                failureObservations += 1
                getStdOut().writeln("CJGUI_COMPLETION_CLEARED mono_ns=${unsafe { cjgui_internal_renderer_owner_clock_ns() }} " +
                    "session=${completion.windowSession} transfer=${completion.transferId} proxy=${completion.targetProxyGeneration}")
                getStdOut().flush()
            }
        }
        held = None
        deliveredWindow = 0u64; deliveredTransfer = 0u64; deliveredProxy = 0u64
    }
}
