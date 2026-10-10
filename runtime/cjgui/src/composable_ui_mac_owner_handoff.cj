package cjgui

@When[os == "macOS"]
foreign {
    func cjgui_internal_renderer_owner_handoff_begin(session: UInt64, document: CString,
        epoch: Int64, window: UInt64, context: UInt64, binding: UInt64, before: Int64,
        nonce: UInt64, sequence: UInt64, identity: CPointer<UInt64>): Int32
    func cjgui_internal_renderer_owner_handoff_seal(session: UInt64, identity: UInt64,
        after: Int64, revision: Int64, anchor: Int64, focus: Int64, receipt: Int64): Int32
    func cjgui_internal_renderer_owner_handoff_bind(session: UInt64, identity: UInt64, transfer: UInt64): Int32
    func cjgui_internal_renderer_owner_handoff_complete(session: UInt64, identity: UInt64,
        transfer: UInt64, version: Int64, revision: Int64, anchor: Int64, focus: Int64): Int32
    func cjgui_internal_renderer_owner_handoff_abort(session: UInt64, identity: UInt64): Int32
    func cjgui_internal_renderer_owner_handoff_state(session: UInt64, identity: UInt64): Int32
    func cjgui_internal_renderer_parked_text_input_focus(session: UInt64, window: UInt64,
        context: UInt64, node: UInt64, resource: Int64, kind: UInt32): Int32
}

@When[os == "macOS"]
func internalRendererOwnerHandoffSupported(): Bool { return true }
@When[os != "macOS"]
func internalRendererOwnerHandoffSupported(): Bool { return false }

@When[os == "macOS"]
func internalRendererHasParkedTextFocus(session: UInt64, window: Int64, context: Int64,
    node: Int64, resource: Int64, kind: Int64): Bool {
    return unsafe { cjgui_internal_renderer_parked_text_input_focus(session, UInt64(window),
        UInt64(context), UInt64(node), resource, UInt32(kind)) } == CJGUI_INTERNAL_RENDERER_OK
}
@When[os != "macOS"]
func internalRendererHasParkedTextFocus(session: UInt64, window: Int64, context: Int64,
    node: Int64, resource: Int64, kind: Int64): Bool { return false }

@When[os == "macOS"]
func internalRendererBeginOwnerHandoff(session: UInt64, window: Int64, context: Int64, binding: UInt64,
    selected: CjguiSourceSelectionSnapshot, nonce: UInt64, sequence: UInt64): (Int32, UInt64) {
    let document = unsafe { LibC.mallocCString(selected.documentId) }
    var identity = 0u64
    try {
        let status = unsafe { cjgui_internal_renderer_owner_handoff_begin(session, document,
            selected.sessionEpoch, UInt64(window), UInt64(context), binding, selected.version,
            nonce, sequence, inout identity) }
        return (status, identity)
    } finally { unsafe { LibC.free(document) } }
}
@When[os != "macOS"]
func internalRendererBeginOwnerHandoff(session: UInt64, window: Int64, context: Int64, binding: UInt64,
    selected: CjguiSourceSelectionSnapshot, nonce: UInt64, sequence: UInt64): (Int32, UInt64) {
    return (CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED, 0u64)
}
@When[os == "macOS"]
func internalRendererSealOwnerHandoff(session: UInt64, identity: UInt64,
    selected: CjguiSourceSelectionSnapshot, receipt: Int64): Int32 {
    return unsafe { cjgui_internal_renderer_owner_handoff_seal(session, identity, selected.version,
        selected.revision, selected.anchorByte, selected.focusByte, receipt) }
}
@When[os != "macOS"]
func internalRendererSealOwnerHandoff(session: UInt64, identity: UInt64,
    selected: CjguiSourceSelectionSnapshot, receipt: Int64): Int32 {
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}
@When[os == "macOS"]
func internalRendererBindOwnerHandoff(session: UInt64, identity: UInt64, transfer: UInt64): Int32 {
    return unsafe { cjgui_internal_renderer_owner_handoff_bind(session, identity, transfer) }
}
@When[os != "macOS"]
func internalRendererBindOwnerHandoff(session: UInt64, identity: UInt64, transfer: UInt64): Int32 {
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}
@When[os == "macOS"]
func internalRendererCompleteOwnerHandoff(session: UInt64, identity: UInt64,
    completed: CjguiInstalledSelectionCompletion, revision: Int64): Int32 {
    return unsafe { cjgui_internal_renderer_owner_handoff_complete(session, identity, completed.transferId,
        completed.sourceSelection.version, revision, completed.sourceSelection.anchorByte,
        completed.sourceSelection.focusByte) }
}
@When[os != "macOS"]
func internalRendererCompleteOwnerHandoff(session: UInt64, identity: UInt64,
    completed: CjguiInstalledSelectionCompletion, revision: Int64): Int32 {
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}
@When[os == "macOS"]
func internalRendererAbortOwnerHandoff(session: UInt64, identity: UInt64): Int32 {
    return unsafe { cjgui_internal_renderer_owner_handoff_abort(session, identity) }
}

@When[os == "macOS"]
func internalRendererOwnerHandoffState(session: UInt64, identity: UInt64): Int32 {
    return unsafe { cjgui_internal_renderer_owner_handoff_state(session, identity) }
}
@When[os != "macOS"]
func internalRendererOwnerHandoffState(session: UInt64, identity: UInt64): Int32 {
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}
@When[os != "macOS"]
func internalRendererAbortOwnerHandoff(session: UInt64, identity: UInt64): Int32 {
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}

// Only the final sealed target is immutable. Original pre-cutoff range writes
// may drain in their existing source FIFO before that target can be sealed.
class CjguiOwnerSelectionHandoff {
    let identity: UInt64
    let before: CjguiSourceSelectionSnapshot
    let context: Int64
    var target: ?CjguiSourceSelectionSnapshot = None
    var latestReceiptSelection: ?CjguiSourceSelectionSnapshot = None
    var requestId: Int64 = -1
    init(identity: UInt64, before: CjguiSourceSelectionSnapshot, context: Int64) {
        this.identity = identity
        this.before = before
        this.context = context
    }

    func matchesRequestedChoice(requested: CjguiTextSelectionTicket, anchor: Int64, focus: Int64): Bool {
        let selected = match (target) { case Some(value) => value; case None => return false }
        return requested.contentVersion == selected.version && requested.sourceVersion == selected.version &&
            requested.contextEpoch == context && requested.selectionRevision == selected.revision &&
            anchor == selected.anchorByte && focus == selected.focusByte
    }

    func matchesCompletion(completed: CjguiInstalledSelectionCompletion,
        requested: CjguiTextSelectionTicket): Bool {
        let selected = match (target) { case Some(value) => value; case None => return false }
        let actual = completed.sourceSelection
        return actual.documentId == selected.documentId && actual.sessionEpoch == selected.sessionEpoch &&
            actual.viewGeneration == selected.viewGeneration &&
            actual.version == selected.version && actual.anchorByte == selected.anchorByte &&
            actual.focusByte == selected.focusByte && completed.semantic.contextEpoch == context &&
            this.matchesRequestedChoice(requested, actual.anchorByte, actual.focusByte)
    }
}
