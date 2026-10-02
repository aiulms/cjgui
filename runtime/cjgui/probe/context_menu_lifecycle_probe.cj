package cjgui

import std.collection.*

// FIFO lifecycle probe only. The native test seam captures the accepted
// overlay node's visual center and enqueues kind 56 with the same accepted
// identity/geometry primitive as rightMouseDown. This exercises framework
// request/command lifecycle; it is not evidence of CGEvent delivery.
foreign {
    func cjgui_internal_renderer_test_enqueue_composable_event(
        session: UInt64, nodeIndex: UInt32, eventKind: UInt32, text: CString
    ): Int32
}

private class ContextMenuProbeOwner <: CjguiRangeTextSource & CjguiRangeTextEditSink {
    private var bytes: Array<Byte>
    private var version: Int64 = 1
    var sinkCalls: Int64 = 0
    var ownerWrites: Int64 = 0

    init(text: String) {
        this.bytes = text.toArray()
    }

    public func text(): String {
        return String.fromUtf8(this.bytes)
    }

    public func rangeTextVersion(): Int64 {
        return this.version
    }

    public func confirmRangeTextVersion(expectedVersion: Int64, action: () -> Bool): Bool {
        return this.version == expectedVersion && action()
    }

    public func rebaseRangeTextSelection(fromVersion: Int64, startByte: Int64,
        endByte: Int64): ?(Int64, Int64, Int64) {
        if (fromVersion == this.version && startByte >= 0 && endByte >= startByte &&
            endByte <= Int64(this.bytes.size)) {
            return Some((fromVersion, startByte, endByte))
        }
        return None
    }

    public func rangeTextByteLength(): Int64 {
        return Int64(this.bytes.size)
    }

    public func readRangeText(startByte: Int64, maxBytes: Int64): CjguiRangeTextSlice {
        if (startByte < 0 || maxBytes < 0 || startByte > Int64(this.bytes.size)) {
            return CjguiRangeTextSlice(startByte, startByte, "", this.version,
                Int64(this.bytes.size), false, "invalid_probe_range")
        }
        let endByte = if (startByte + maxBytes > Int64(this.bytes.size)) {
            Int64(this.bytes.size)
        } else {
            startByte + maxBytes
        }
        return CjguiRangeTextSlice(startByte, startByte,
            String.fromUtf8(this.bytes.slice(startByte, endByte - startByte)), this.version,
            Int64(this.bytes.size), endByte == Int64(this.bytes.size),
            if (endByte == Int64(this.bytes.size)) { "" } else { "probe_window_truncated" })
    }

    public func applyRangeTextEdit(baseVersion: Int64, startByte: Int64, endByte: Int64,
        inserted: String): CjguiRangeTextEditOutcome {
        this.sinkCalls += 1
        if (baseVersion != this.version) {
            return CjguiRangeTextEditOutcome.conflict(this.version, "stale_probe_base")
        }
        if (startByte < 0 || endByte < startByte || endByte > Int64(this.bytes.size)) {
            return CjguiRangeTextEditOutcome.rejected(this.version, "invalid_probe_range")
        }
        let updated = ArrayList<Byte>()
        var index: Int64 = 0
        while (index < startByte) {
            updated.add(this.bytes[index])
            index += 1
        }
        updated.add(all: inserted.toArray())
        index = endByte
        while (index < Int64(this.bytes.size)) {
            updated.add(this.bytes[index])
            index += 1
        }
        this.bytes = updated.toArray()
        let before = this.version
        this.version += 1
        this.ownerWrites += 1
        return CjguiRangeTextEditOutcome.accepted(before, this.version)
    }
}

private class ContextMenuLifecycleController <: CjguiComposableUiController &
    CjguiComposableUiContextMenuRequestHandler {
    private let owner: ContextMenuProbeOwner
    private var host: Option<CjguiComposableUiWindow> = None
    private var session: Option<CjguiTextSession> = None
    private var request: Option<CjguiComposableUiContextMenuRequest> = None
    private var visible: Bool = false
    private var revision: Int64 = 1
    var commandDispatches: Int64 = 0
    var endedRequests: Int64 = 0

    init() {
        this.owner = ContextMenuProbeOwner("alpha beta gamma")
    }

    public func attach(window: CjguiComposableUiWindow): CjguiTextSession {
        this.host = Some(window)
        let bound = window.bindRangeTextSession(2, "context-probe-body", this.owner, this.owner, 42,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, materializeLimit: 4096)
        this.session = Some(bound)
        return bound
    }

    public func uiSceneVersion(): Int64 {
        return this.revision
    }

    public func buildUi(): CjguiComposableUiNode {
        let content = cjguiComposableVertical(1, "context-probe-content", CjguiComposableUiStyle(gap: 4))
        let mirror = match (host) {
            case Some(window) => window.textSessionMirrorText()
            case None => ""
        }
        content.add(cjguiComposableMultilineTextInput(2, "context-probe-body", "", mirror, 42,
            CjguiComposableUiStyle(fixedHeight: 180)))
        let hostNode = cjguiComposableLayerHost(90, "context-probe-layer-host",
            CjguiComposableUiStyle(growX: 1, growY: 1))
        hostNode.add(content)
        if (visible) {
            if (let Some(active) <- request) {
                let menu = cjguiComposableContextMenuLayer(500, "context-probe-menu", active.layerId,
                    "context-probe-body", active.nodeId, active.hostLocalX, active.hostLocalY,
                    CjguiComposableUiStyle(fixedWidth: 160, fixedHeight: 42, padding: 4))
                menu.add(cjguiComposableButton(501, "context-probe-command", "Apply", "PROBE_COMMAND", 42,
                    CjguiComposableUiStyle(fixedHeight: 32, growX: 1)))
                hostNode.add(menu)
            }
        }
        return hostNode
    }

    public func requestContextMenu(request: CjguiComposableUiContextMenuRequest): Bool {
        if (request.nodeId != 2 || request.resourceId != 42 ||
            request.nodeKind != CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT) {
            return false
        }
        let window = match (host) { case Some(value) => value; case None => return false }
        let declaration = CjguiComposableUiCommand("probe.apply",
            CjguiComposableUiNodeReference.manual(request.nodeId), "Apply", "Probe", 0,
            true, false)
        if (!window.declareContextMenuCommand(request.requestId, declaration)) {
            return false
        }
        this.request = Some(request)
        visible = true
        revision += 1
        return true
    }

    public func contextMenuRequestEnded(requestId: Int64, reason: String): Unit {
        endedRequests += 1
        if (let Some(current) <- request) {
            if (current.requestId == requestId) {
                request = None
                visible = false
                revision += 1
            }
        }
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind != 27 || event.text != "probe.apply" || event.node.nodeId != 2 ||
            event.node.resourceId != 42 || event.node.nodeKind != CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT) {
            return CjguiComposableUiDispatchResult(false)
        }
        commandDispatches += 1
        let outcome = owner.applyRangeTextEdit(owner.rangeTextVersion(), 0, 0, "!")
        if (outcome.applied) { revision += 1 }
        return CjguiComposableUiDispatchResult(outcome.applied)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func currentRequestId(): Int64 {
        return match (request) { case Some(value) => value.requestId; case None => -1 }
    }

    public func selectionSession(): CjguiTextSession {
        return match (session) { case Some(value) => value; case None => throw Exception("probe session missing") }
    }

    public func ownerWrites(): Int64 { return owner.ownerWrites }
    public func sinkCalls(): Int64 { return owner.sinkCalls }
}

private func enqueueContextMenuRequest(window: CjguiComposableUiWindow): Bool {
    let nodes = window.acceptedSceneNodes()
    var nodeIndex: Int64 = -1
    var index: Int64 = 0
    while (index < Int64(nodes.size)) {
        if (nodes[index].nodeId == 2 && nodes[index].resourceId == 42 &&
            nodes[index].nodeKind == CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT) {
            nodeIndex = index
            break
        }
        index += 1
    }
    if (nodeIndex < 0) { return false }
    let empty = unsafe { LibC.mallocCString("") }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = empty.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_enqueue_composable_event(window.testSessionToken(),
                UInt32(nodeIndex), 56u32, textResource.value)
        }
    }
    if (status != CJGUI_INTERNAL_RENDERER_OK) { return false }
    let pumped = window.pump(0u32)
    return pumped.isOpen
}

private func newContextMenuHarness(): (ContextMenuLifecycleController, CjguiComposableUiWindow) {
    let controller = ContextMenuLifecycleController()
    let window = CjguiComposableUiWindow(controller)
    let _ = controller.attach(window)
    return (controller, window)
}

private func verifyAcceptedAndUndeclaredCommands(): Bool {
    let (controller, window) = newContextMenuHarness()
    if (!window.start()) { window.close(); return false }
    controller.selectionSession().setSelection16(1, 4)
    if (!enqueueContextMenuRequest(window)) { window.close(); return false }
    let requestId = controller.currentRequestId()
    if (requestId < 0 || controller.ownerWrites() != 0 || controller.sinkCalls() != 0 ||
        controller.commandDispatches != 0) {
        window.close()
        return false
    }
    let wrongRequestAccepted = window.invokeContextMenuCommand(requestId - 1, "probe.apply")
    let wrongRequestStayedZero = !wrongRequestAccepted && controller.ownerWrites() == 0 &&
        controller.sinkCalls() == 0 && controller.commandDispatches == 0
    let undeclaredAccepted = window.invokeContextMenuCommand(requestId, "not-declared")
    let undeclaredStayedZero = !undeclaredAccepted && controller.ownerWrites() == 0 &&
        controller.sinkCalls() == 0 && controller.commandDispatches == 0
    let accepted = window.invokeContextMenuCommand(requestId, "probe.apply")
    let exactlyOnce = accepted && controller.commandDispatches == 1 && controller.ownerWrites() == 1 &&
        controller.sinkCalls() == 1 && controller.ownerWrites() == 1
    let replayRejected = !window.invokeContextMenuCommand(requestId, "probe.apply") &&
        controller.commandDispatches == 1 && controller.ownerWrites() == 1 && controller.sinkCalls() == 1
    window.close()
    println("CJGUI_CONTEXT_MENU_FIFO accepted=${exactlyOnce} wrong_request_zero_write=${wrongRequestStayedZero} undeclared_zero_write=${undeclaredStayedZero} replay_rejected=${replayRejected}")
    return wrongRequestStayedZero && undeclaredStayedZero && exactlyOnce && replayRejected
}

private func verifySameSelectionAbaRejects(): Bool {
    let (controller, window) = newContextMenuHarness()
    if (!window.start()) { window.close(); return false }
    controller.selectionSession().setSelection16(1, 4)
    if (!enqueueContextMenuRequest(window)) { window.close(); return false }
    let oldRequest = controller.currentRequestId()
    // Same coordinates and value, but setSelection16 advances its independent
    // selectionRevision. The frozen request must no longer authorize a command.
    controller.selectionSession().setSelection16(1, 4)
    let accepted = window.invokeContextMenuCommand(oldRequest, "probe.apply")
    let refusedWithoutOwnerWrite = !accepted && controller.commandDispatches == 0 &&
        controller.ownerWrites() == 0 && controller.sinkCalls() == 0
    window.close()
    println("CJGUI_CONTEXT_MENU_FIFO selection_aba_refused=${refusedWithoutOwnerWrite}")
    return refusedWithoutOwnerWrite
}

private func verifySupersededRequestCannotReachCurrentTarget(): Bool {
    let (controller, window) = newContextMenuHarness()
    if (!window.start()) { window.close(); return false }
    controller.selectionSession().setSelection16(1, 4)
    if (!enqueueContextMenuRequest(window)) { window.close(); return false }
    let oldRequest = controller.currentRequestId()
    if (!enqueueContextMenuRequest(window)) { window.close(); return false }
    let currentRequest = controller.currentRequestId()
    let oldRefused = oldRequest >= 0 && currentRequest > oldRequest &&
        !window.invokeContextMenuCommand(oldRequest, "probe.apply") && controller.commandDispatches == 0 &&
        controller.ownerWrites() == 0 && controller.sinkCalls() == 0
    let currentAccepted = window.invokeContextMenuCommand(currentRequest, "probe.apply") &&
        controller.commandDispatches == 1 && controller.ownerWrites() == 1 && controller.sinkCalls() == 1
    window.close()
    println("CJGUI_CONTEXT_MENU_FIFO superseded_refused=${oldRefused} current_request_accepted=${currentAccepted}")
    return oldRefused && currentAccepted
}

private func verifySameNodeRebindRejectsOldRequest(): Bool {
    let (controller, window) = newContextMenuHarness()
    if (!window.start()) { window.close(); return false }
    controller.selectionSession().setSelection16(1, 4)
    if (!enqueueContextMenuRequest(window)) { window.close(); return false }
    let oldRequest = controller.currentRequestId()
    let replacement = ContextMenuProbeOwner("alpha beta gamma")
    let _ = window.bindRangeTextSession(2, "context-probe-body", replacement, replacement, 42,
        CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, materializeLimit: 4096)
    let accepted = window.invokeContextMenuCommand(oldRequest, "probe.apply")
    let refusedWithoutOldOwnerWrite = !accepted && controller.commandDispatches == 0 &&
        controller.ownerWrites() == 0 && controller.sinkCalls() == 0 && replacement.ownerWrites == 0 &&
        replacement.sinkCalls == 0
    window.close()
    println("CJGUI_CONTEXT_MENU_FIFO same_node_rebind_refused=${refusedWithoutOldOwnerWrite}")
    return refusedWithoutOldOwnerWrite
}

main(args: Array<String>): Int64 {
    let accepted = verifyAcceptedAndUndeclaredCommands()
    let aba = verifySameSelectionAbaRejects()
    let superseded = verifySupersededRequestCannotReachCurrentTarget()
    let rebound = verifySameNodeRebindRejectsOldRequest()
    let allPassed = accepted && aba && superseded && rebound
    println("CJGUI_CONTEXT_MENU_FIFO_RESULT pass=${allPassed} injection=kind56_fifo cg_event=false")
    if (allPassed) { return 0 }
    return 1
}
