package cjgui

// Metadata for one actual callback, not an input queue or a document history.
// Original input, owner before/after and declaration conversion never change.
// Only the predecessor reference retires after a real latest installation.
class CjguiOwnerCommandReceipt {
    let handoffIdentity: UInt64
    let input: InternalRendererInputProvenance
    let before: CjguiSourceSelectionSnapshot
    let after: CjguiSourceSelectionSnapshot
    let context: Int64
    let binding: UInt64
    let declaredBusinessRevision: Int64
    let businessRevisionAfter: Int64
    let applied: Bool
    let depth: Int64
    var predecessor: ?CjguiOwnerCommandReceipt

    init(identity: UInt64, input: InternalRendererInputProvenance,
        before: CjguiSourceSelectionSnapshot, after: CjguiSourceSelectionSnapshot,
        context: Int64, binding: UInt64, declaredBusinessRevision: Int64,
        businessRevisionAfter: Int64, applied: Bool, predecessor: ?CjguiOwnerCommandReceipt) {
        this.handoffIdentity = identity
        this.input = input
        this.before = before
        this.after = after
        this.context = context
        this.binding = binding
        this.declaredBusinessRevision = declaredBusinessRevision
        this.businessRevisionAfter = businessRevisionAfter
        this.applied = applied
        this.predecessor = predecessor
        this.depth = if (let Some(previous) <- predecessor) { previous.depth + 1 } else { 1 }
    }

    func isValid(): Bool {
        if (handoffIdentity == 0u64 || !input.isValidFor(34u32) || context <= 0 || binding == 0u64 ||
            before.documentId.size == 0 || before.documentId != after.documentId ||
            before.sessionEpoch != after.sessionEpoch || after.sessionEpoch <= 0 ||
            after.revision < 0 || after.anchorByte < 0 || after.focusByte < 0 || depth > 64) { return false }
        if (applied) {
            if (before.version == Int64.Max || after.version != before.version + 1) { return false }
        } else if (after.version != before.version) { return false }
        if (let Some(previous) <- predecessor) {
            return previous.isTailFor(input.previousSequence, before, context, binding) &&
                previous.input.sessionGeneration == input.sessionGeneration
        }
        return true
    }

    func isTailFor(sequence: UInt64, selected: CjguiSourceSelectionSnapshot,
        currentContext: Int64, currentBinding: UInt64): Bool {
        return input.sequence == sequence && context == currentContext && binding == currentBinding &&
            after.documentId == selected.documentId && after.sessionEpoch == selected.sessionEpoch &&
            after.version == selected.version && after.revision == selected.revision &&
            after.anchorByte == selected.anchorByte &&
            after.focusByte == selected.focusByte
    }

    func convertsBusinessRevision(declared: Int64, actual: Int64,
        selected: CjguiSourceSelectionSnapshot, currentContext: Int64, currentBinding: UInt64): Bool {
        return declaredBusinessRevision == declared && businessRevisionAfter == actual &&
            this.isTailFor(input.sequence, selected, currentContext, currentBinding)
    }

    func retirePresentedPredecessors(): Unit { predecessor = None }
}

@When[os == "macOS"]
foreign {
    func cjgui_internal_renderer_accept_owner_command_receipt(session: UInt64, identity: UInt64,
        generation: UInt64, sequence: UInt64, previous: UInt64, before: Int64, after: Int64,
        revision: Int64, anchor: Int64, focus: Int64, applied: UInt32): Int32
    func cjgui_internal_renderer_retire_owner_command_presentation(session: UInt64, identity: UInt64): Int32
}

@When[os == "macOS"]
func internalRendererOwnerCommandReceiptSupported(): Bool { true }
@When[os != "macOS"]
func internalRendererOwnerCommandReceiptSupported(): Bool { false }

@When[os == "macOS"]
func internalRendererAcceptOwnerCommandReceipt(session: UInt64, receipt: CjguiOwnerCommandReceipt): Int32 {
    if (!receipt.isValid()) { return CJGUI_INTERNAL_RENDERER_SCENE_STALE }
    return unsafe { cjgui_internal_renderer_accept_owner_command_receipt(session, receipt.handoffIdentity,
        receipt.input.sessionGeneration, receipt.input.sequence, receipt.input.previousSequence,
        receipt.before.version, receipt.after.version, receipt.after.revision,
        receipt.after.anchorByte, receipt.after.focusByte, if (receipt.applied) { 1u32 } else { 0u32 }) }
}
@When[os != "macOS"]
func internalRendererAcceptOwnerCommandReceipt(session: UInt64, receipt: CjguiOwnerCommandReceipt): Int32 {
    CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}

@When[os == "macOS"]
func internalRendererRetireOwnerCommandPresentation(session: UInt64, identity: UInt64): Int32 {
    unsafe { cjgui_internal_renderer_retire_owner_command_presentation(session, identity) }
}
@When[os != "macOS"]
func internalRendererRetireOwnerCommandPresentation(session: UInt64, identity: UInt64): Int32 {
    CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}
