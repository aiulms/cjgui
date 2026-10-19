// E/macOS source handoff regression. The native insert helper invokes the
// actual NSTextView/TextKit delegate; coordinate-based pointer phases exercise
// the production overlay mouseDown/mouseUp route and its original FIFO.
package cjgui

import std.unittest.*
import std.unittest.testmacro.*
import std.time.*
import std.collection.*

foreign {
    func cjgui_internal_renderer_test_fault_actual_activation_pair(session: UInt64, fault: UInt32): Int32
    func cjgui_internal_renderer_test_caret_confirmation_pending_once(session: UInt64, command: UInt32): Int32
    func cjgui_internal_renderer_test_selection_finalizing_pending_once(session: UInt64, command: UInt32): Int32
    func cjgui_internal_renderer_test_insert_actual_composable_proxy(session: UInt64, text: CString): Int32
    func cjgui_internal_renderer_test_readonly_proxy_mutations(session: UInt64): Int32
    func cjgui_internal_renderer_test_queue_composable_selection(
        session: UInt64, nodeIndex: UInt32, selectionStart: UInt32, selectionEnd: UInt32): Int32
    func cjgui_internal_renderer_test_set_composable_selection(
        session: UInt64, nodeIndex: UInt32, selectionStart: UInt32, selectionEnd: UInt32): Int32
    func cjgui_internal_renderer_test_confirm_source_handoff_selection(
        session: UInt64, selectionStart: UInt32, selectionEnd: UInt32): Int32
    func cjgui_internal_renderer_test_insert_composable_text(
        session: UInt64, nodeIndex: UInt32, text: CString): Int32
    func cjgui_internal_renderer_test_close_text_preparation_worker_gate(): Unit
    func cjgui_internal_renderer_test_wait_for_text_preparation_worker_gate(timeoutMs: UInt32): Int32
    func cjgui_internal_renderer_test_open_text_preparation_worker_gate(): Unit
    func cjgui_internal_renderer_test_wait_for_text_preparation_finished(timeoutMs: UInt32): Int32
    func cjgui_internal_renderer_test_monotonic_micros(outMicros: CPointer<UInt64>): Int32
    func cjgui_internal_renderer_test_arm_pending_selection_pointer_update(
        session: UInt64, pointX: Float32, pointY: Float32): Int32
    func cjgui_internal_renderer_test_pending_selection_pointer_update_consumed(session: UInt64): Int32
    func cjgui_internal_renderer_test_arm_selection_geometry_rejection(session: UInt64): Int32
    func cjgui_internal_renderer_test_selection_geometry_rejection_consumed(session: UInt64): Int32
}

private class SourceHandoffController <: CjguiComposableUiController &
    CjguiComposableUiCompositionRangeProvider & CjguiComposableUiInstalledSelectionInputProvider &
    CjguiComposableUiSelectionCompletionProvider & CjguiComposableUiPointerCaptureVersionProvider {
    let owner: FakeTextOwner
    var completionCount: Int64 = 0
    var holdFirstPresentForLifecycle = false
    var lifecyclePresentHeld = false
    var completion: ?CjguiInstalledSelectionCompletion = None
    var firstCompletion: ?CjguiInstalledSelectionCompletion = None
    var requireCompletion = false
    var insertOnCompletion = ""
    var completionInsertStatus: Int32 = -1
    public func selectionInstallationCompleted(value: CjguiInstalledSelectionCompletion): Unit {
        completionCount += 1
        completion = Some(value)
        if (firstCompletion.isNone()) { firstCompletion = Some(value) }
        if (insertOnCompletion.size > 0) {
            let text = insertOnCompletion
            insertOnCompletion = ""
            if (let Some(host) <- window) { completionInsertStatus = sourceHandoffInsert(host, 1u32, text) }
        }
    }
    var retainOriginalArrow = false
    var originalArrowSequence: UInt64 = 0u64
    var revision: Int64 = 1
    var window: ?CjguiComposableUiWindow = None
    var session: ?CjguiTextSession = None
    var previewAnchor16: Int64 = -1
    var previewSelectionCommits: Int64 = 0
    var selectionChoiceId: Int64 = 0
    var selectionDocumentId: String = "source-handoff"
    var deferredSelectionPublishes: Int64 = 0
    var deferredSelectionTransferId: UInt64 = 0u64
    var selectionChoiceAnchorByte: Int64 = -1
    var selectionChoiceFocusByte: Int64 = -1
    var useSelectionSubmissionForPointer = false
    var useSourceSelectionSubmissionForPointer = false
    var scrollFixture = false
    var omitPreviewForResident = false
    var residentAnchorPreview = false
    var previewHeight: Int64 = 70
    var previewContentClips: Bool = true
    let sourceViewport = CjguiComposableUiScrollViewport()
    var exerciseDeclaredActivation = false
    var declaredActivationCount: Int64 = 0
    var declaredSourceAdmissions: Int64 = 0
    var declaredSelectionAdmissions: Int64 = 0
    var declaredSelectionPublishes: Int64 = 0
    var includeUndoAction = false
    var includeOwnerTextInput = true
    var previewReadOnly = false
    var previewEnabled = true
    var previewPointerInteractive = true
    var useBoundMirrorBody = false
    var previewDragActive = false
    var previewDragAnchor16: Int64 = -1
    var pointerBeginAdmissions: Int64 = 0
    var pointerUpdateAdmissions: Int64 = 0
    var pointerEndAdmissions: Int64 = 0
    var pointerBeginPublishes: Int64 = 0
    var pointerEndPublishes: Int64 = 0
    var lastPointerSelectionTransferId: UInt64 = 0u64
    init(owner: FakeTextOwner) { this.owner = owner }
    func attach(window: CjguiComposableUiWindow, session: CjguiTextSession): Unit {
        this.window = Some(window)
        this.session = Some(session)
    }
    public func pointerCaptureVersion(node: CjguiComposableUiLayoutNode): Int64 {
        // Keep the source mapping stable across scene/origin handoff; a body
        // version change still retires the captured source coordinates.
        return if (scrollFixture) { owner.ver } else { this.uiSceneVersion() }
    }
    func recordDeferredSelectionPublish(window: CjguiComposableUiWindow,
        nodeId: Int64, resourceId: Int64): Unit {
        deferredSelectionPublishes += 1
        deferredSelectionTransferId = window.acceptedSelectionTransferId(nodeId, resourceId)
    }
    public func uiSceneVersion(): Int64 { return revision + owner.ver }
    public func buildUi(): CjguiComposableUiNode {
        if (holdFirstPresentForLifecycle) {
            if (let Some(host) <- window) {
                holdFirstPresentForLifecycle = false
                lifecyclePresentHeld = host.testHoldNextComposablePresent()
            }
        }
        let root = cjguiComposableVertical(8001, "source-handoff-root",
            CjguiComposableUiStyle(fixedWidth: 360, fixedHeight: 300,
                background: if (revision % 2 == 0) { CjguiComposableUiColor(0.96, 0.96, 0.96, 1.0) }
                    else { CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0) }))
        let presentedBody = if (useBoundMirrorBody && session.isSome()) {
            session.getOrThrow().mirrorSnapshot().text
        } else { owner.text() }
        if (includeOwnerTextInput) {
            root.add(cjguiComposableMultilineTextInput(8002, "source-body", "Source", presentedBody, 8802,
                CjguiComposableUiStyle(fixedWidth: 340, fixedHeight: 150), fieldId: "source-body"))
        }
        let preview = CjguiComposableUiNode(8003, "source-preview", CJGUI_COMPOSABLE_UI_TEXT,
            "", presentedBody, "", 8803,
            CjguiComposableUiStyle(fixedWidth: 340, fixedHeight: previewHeight, pointerInteractive: previewPointerInteractive),
            fieldId: "source-preview", readOnly: previewReadOnly, enabled: previewEnabled)
        if (scrollFixture) {
            let scroll = cjguiComposableScrollArea(8005, "source-preview-scroll", sourceViewport,
                CjguiComposableUiStyle(fixedWidth: 340, fixedHeight: 120))
            let content = cjguiComposableVertical(8006, "source-preview-content",
                CjguiComposableUiStyle(gap: 0, clipsContent: previewContentClips))
            if (!omitPreviewForResident) { content.add(preview) }
            if (residentAnchorPreview) {
                content.add(cjguiComposableText(8008, "resident-anchor-preview", presentedBody,
                    CjguiComposableUiStyle(fixedWidth: 340, fixedHeight: 70)))
            }
            content.add(cjguiComposableVertical(8007, "source-preview-tail",
                CjguiComposableUiStyle(fixedHeight: 240)))
            scroll.add(content)
            root.add(scroll)
        } else {
            root.add(preview)
        }
        if (includeUndoAction) {
            root.add(cjguiComposableButton(8004, "undo-action", "Undo", "UNDO", 8804,
                CjguiComposableUiStyle(fixedWidth: 100, fixedHeight: 32)))
        }
        return root
    }
    public func prepareCompositionSourceRange(node: CjguiComposableUiLayoutNode,
        start16: Int64, end16: Int64, sceneVersion: Int64): CjguiMappedCompositionRange {
        let host = match (window) { case Some(v) => v; case None => return CjguiMappedCompositionRange(None) }
        let bound = match (session) { case Some(v) => v; case None => return CjguiMappedCompositionRange(None) }
        let mirror = bound.mirrorSnapshot()
        if (!mirror.prepared || mirror.contentVersion != owner.ver ||
            mirror.contextEpoch != bound.contextEpochValue() || node.nodeId != 8003 ||
            node.resourceId != 8803 || node.nodeKind != CJGUI_COMPOSABLE_UI_TEXT ||
            node.value != mirror.text || sceneVersion != host.windowProjection().acceptedSceneVersion) {
            return CjguiMappedCompositionRange(None, reason: "source_handoff_fixture_stale")
        }
        let start = match (cjguiUtf16OffsetToUtf8(mirror.text, start16)) {
            case Some(v) => v; case None => return CjguiMappedCompositionRange(None)
        }
        let end = match (cjguiUtf16OffsetToUtf8(mirror.text, end16)) {
            case Some(v) => v; case None => return CjguiMappedCompositionRange(None)
        }
        return CjguiMappedCompositionRange(bound.prepareSourceRange(owner.ver,
            mirror.startByte + start, mirror.startByte + end))
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.nodeId == 8004) {
            declaredActivationCount += 1
            let host = window.getOrThrow()
            let sourceAdmitted = host.testAdmittedTextCommandSerial() != 0u64
            if (sourceAdmitted) { declaredSourceAdmissions += 1 }
            // A trusted controller can explicitly navigate via its public
            // selection API without a declared command. That separate ability
            // is not evidence of this queued action's editing source.
            if (!exerciseDeclaredActivation || !sourceAdmitted) { return CjguiComposableUiDispatchResult(true) }
            let ticket = match (host.freezeAcceptedSelection(8003)) {
                case Some(value) => value; case None => return CjguiComposableUiDispatchResult(false)
            }
            let result = host.submitAcceptedSelection(ticket, 1, 4, 1, 4,
                { => declaredSelectionPublishes += 1 })
            let admitted = match (result) {
                case CjguiSelectionSubmission.Committed => true
                case CjguiSelectionSubmission.Retained(_) => true
                case CjguiSelectionSubmission.NotAdmitted(_) => false
            }
            if (admitted) { declaredSelectionAdmissions += 1 }
            return CjguiComposableUiDispatchResult(admitted)
        }
        if (retainOriginalArrow && event.eventKind == 35 && (event.text == "left" || event.text == "right")) {
            let host = window.getOrThrow()
            let ticket = host.freezeAcceptedSelection(event.node.nodeId).getOrThrow()
            let retained = host.retainVisualInputIntent(event.inputSequence, event.inputPreviousSequence,
                event.inputSessionGeneration, ticket, event.text, false, -1.0, 0u64)
            if (retained) { originalArrowSequence = event.inputSequence }
            return CjguiComposableUiDispatchResult(retained)
        }

        if (event.node.nodeId == 8003 && event.node.nodeKind == CJGUI_COMPOSABLE_UI_TEXT &&
            (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN ||
             event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE ||
             event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_END)) {
            let host = match (window) { case Some(v) => v;
                case None => return CjguiComposableUiDispatchResult(false) }
            let begin = event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN
            let update = event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE
            let end = event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_END
            if (begin) { host.invalidatePlainPositionBranch() }
            let (status, byte, _) = host.hitTestComposableTextDetailed(8003,
                Float64(event.pointerX), Float64(event.pointerY))
            if (status != 0) { return CjguiComposableUiDispatchResult(false) }
            let focus16 = match (cjguiUtf8OffsetToUtf16(event.node.value, byte)) {
                case Some(v) => v; case None => return CjguiComposableUiDispatchResult(false)
            }
            if (!begin && !previewDragActive) { return CjguiComposableUiDispatchResult(false) }
            let anchor16 = if (begin) { focus16 } else { previewDragAnchor16 }
            if (anchor16 < 0) { return CjguiComposableUiDispatchResult(false) }
            let ticket = match (host.freezeAcceptedSelection(8003)) {
                case Some(v) => v; case None => return CjguiComposableUiDispatchResult(false)
            }
            let low = if (anchor16 < focus16) { anchor16 } else { focus16 }
            let high = if (anchor16 > focus16) { anchor16 } else { focus16 }
            let publishChoice = { =>
                previewAnchor16 = anchor16
                previewSelectionCommits += 1
                if (begin) { pointerBeginPublishes += 1 }
                if (end) { pointerEndPublishes += 1 }
                lastPointerSelectionTransferId = host.acceptedSelectionTransferId(8003, 8803)
            }
            let admitted = if (!useSelectionSubmissionForPointer) {
                host.commitAcceptedSelection(ticket, anchor16, focus16, low, high, publishChoice)
            } else if (useSourceSelectionSubmissionForPointer) {
                let sourceAnchor = match (cjguiUtf16OffsetToUtf8(event.node.value, anchor16)) {
                    case Some(value) => value; case None => return CjguiComposableUiDispatchResult(false)
                }
                let sourceFocus = match (cjguiUtf16OffsetToUtf8(event.node.value, focus16)) {
                    case Some(value) => value; case None => return CjguiComposableUiDispatchResult(false)
                }
                match (host.submitAcceptedSourceSelection(ticket, sourceAnchor, sourceFocus, low, high, publishChoice)) {
                    case CjguiSelectionSubmission.Committed => true
                    case CjguiSelectionSubmission.Retained(_) => true
                    case CjguiSelectionSubmission.NotAdmitted(_) => false
                }
            } else {
                match (host.submitAcceptedSelection(ticket, anchor16, focus16, low, high, publishChoice)) {
                    case CjguiSelectionSubmission.Committed => true
                    case CjguiSelectionSubmission.Retained(_) => true
                    case CjguiSelectionSubmission.NotAdmitted(_) => false
                }
            }
            if (admitted) {
                if (begin) { previewDragAnchor16 = focus16; previewDragActive = true; pointerBeginAdmissions += 1 }
                if (update) { pointerUpdateAdmissions += 1 }
                if (end) { pointerEndAdmissions += 1; previewDragActive = false }
            }
            return CjguiComposableUiDispatchResult(admitted)
        }
        return CjguiComposableUiDispatchResult(true)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func authorizeInstalledSelectionInput(proof: CjguiInstalledSelectionInputProof):
        ?CjguiOwnerSelectionChoice {
        let bound = match (session) { case Some(value) => value; case None => return None }
        if (requireCompletion) {
            let installed = match (completion) { case Some(value) => value; case None => return None }
            if (proof.transferId != installed.transferId || proof.targetNodeId != installed.targetNodeId ||
                proof.targetProxyGeneration != installed.targetProxyGeneration) { return None }
            let selected = bound.sourceSelectionSnapshot().getOrThrow()
            selectionChoiceAnchorByte = selected.anchorByte
            selectionChoiceFocusByte = selected.focusByte
        } else if (proof.sourceBody != owner.text() || proof.targetBody != owner.text() ||
            proof.sourceNodeId != 8002 || proof.targetNodeId != 8002 ||
            selectionChoiceAnchorByte < 0 || selectionChoiceFocusByte < 0) { return None }
        selectionChoiceId += 1
        let ticket = bound.freezeSelectionTicket()
        return Some(CjguiOwnerSelectionChoice(selectionDocumentId, 1, owner.ver,
            proof.targetProjectionVersion, ticket.contextEpoch, ticket.selectionRevision,
            selectionChoiceId, selectionChoiceAnchorByte, selectionChoiceFocusByte))
    }
    public func installedSelectionChoiceIsCurrent(choice: CjguiOwnerSelectionChoice): Bool {
        let bound = match (session) { case Some(value) => value; case None => return false }
        let ticket = bound.freezeSelectionTicket()
        return choice.documentId == selectionDocumentId && choice.sessionEpoch == 1 &&
            choice.contentVersion == owner.ver && choice.contextEpoch == ticket.contextEpoch &&
            choice.selectionRevision == ticket.selectionRevision &&
            choice.anchorByte == selectionChoiceAnchorByte && choice.focusByte == selectionChoiceFocusByte
    }
}

private class SourceHandoffBoolBox {
    var value = false
}

private func sourceHandoffInsert(window: CjguiComposableUiWindow, nodeIndex: UInt32,
    text: String): Int32 {
    let nativeText = unsafe { LibC.mallocCString(text) }
    var status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (resource = nativeText.asResource()) {
        status = unsafe { cjgui_internal_renderer_test_insert_composable_text(
            window.testSessionToken(), nodeIndex, resource.value) }
    }
    return status
}

private func sourceHandoffAcceptedPoint(window: CjguiComposableUiWindow,
    nodeId: Int64, resourceId: Int64): (Bool, Float32, Float32) {
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == nodeId && node.resourceId == resourceId &&
            node.bounds.width > 0 && node.bounds.height > 0) {
            return (true, Float32(node.bounds.x + node.bounds.width / 2),
                Float32(node.bounds.y + node.bounds.height / 2))
        }
    }
    return (false, 0.0f32, 0.0f32)
}

private func sourceHandoffTextPoint(window: CjguiComposableUiWindow,
    nodeId: Int64, resourceId: Int64, fraction: Float64): (Bool, Float32, Float32) {
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == nodeId && node.resourceId == resourceId &&
            node.bounds.width > 40 && node.bounds.height > 0) {
            let x = Float64(node.bounds.x) + Float64(node.bounds.width) * fraction
            let y = Float64(node.bounds.y) + Float64(node.bounds.height) / 2.0
            return (true, Float32(x), Float32(y))
        }
    }
    return (false, 0.0f32, 0.0f32)
}

private func sourceHandoffSendMouse(window: CjguiComposableUiWindow, phase: UInt32,
    pointX: Float32, pointY: Float32): Int32 {
    return unsafe { cjgui_internal_renderer_test_send_composable_mouse(
        window.testSessionToken(), phase, pointX, pointY) }
}

private func sourceHandoffSelection(window: CjguiComposableUiWindow, nodeIndex: UInt32,
    selectionStart: UInt32, selectionEnd: UInt32): Int32 {
    return unsafe { cjgui_internal_renderer_test_queue_composable_selection(
        window.testSessionToken(), nodeIndex, selectionStart, selectionEnd) }
}

private func sourceHandoffSetSelection(window: CjguiComposableUiWindow, nodeIndex: UInt32,
    selectionStart: UInt32, selectionEnd: UInt32): Int32 {
    return unsafe { cjgui_internal_renderer_test_set_composable_selection(
        window.testSessionToken(), nodeIndex, selectionStart, selectionEnd) }
}

private func sourceHandoffLateConfirm(window: CjguiComposableUiWindow,
    selectionStart: UInt32, selectionEnd: UInt32): Int32 {
    return unsafe { cjgui_internal_renderer_test_confirm_source_handoff_selection(
        window.testSessionToken(), selectionStart, selectionEnd) }
}

private func sourceHandoffPump(window: CjguiComposableUiWindow): Unit {
    let _ = window.pump(0u32)
}

private func sourceHandoffMonotonicMicros(): UInt64 {
    var micros = 0u64
    let status = unsafe { cjgui_internal_renderer_test_monotonic_micros(inout micros) }
    return if (status == CJGUI_INTERNAL_RENDERER_OK) { micros } else { 0u64 }
}

private func sourceHandoffNativeSelection(window: CjguiComposableUiWindow): (Int32, UInt32, UInt32) {
    var start: UInt32 = 0
    var end: UInt32 = 0
    let status = unsafe { cjgui_internal_renderer_test_composable_selection(
        window.testSessionToken(), inout start, inout end) }
    return (status, start, end)
}

private func sourceHandoffNativeGesture(window: CjguiComposableUiWindow): UInt64 {
    return unsafe { cjgui_internal_renderer_test_active_pointer_epoch(window.testSessionToken()) }
}

private func sourceHandoffWindow(controller: SourceHandoffController): CjguiComposableUiWindow {
    return CjguiComposableUiWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration(
            "CJGUI source handoff", 980u32, 620u32, rangeTextEditDeltaDelivery: true))
}

private func runPendingSelectionBeginRace(useSourceBytes: Bool): Unit {
    let owner = SelectionAuthorityTestOwner()
    owner.body.data = Array<Byte>(128, repeat: 97u8)
    let body = owner.body.text()
    let controller = SourceHandoffController(owner.body)
    controller.useSelectionSubmissionForPointer = true
    controller.useSourceSelectionSubmissionForPointer = useSourceBytes
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "pending-pointer-begin", owner, owner,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.focusAcceptedNodeById(8002), true)
        @Assert(sourceHandoffSetSelection(window, 1u32, 0u32, 0u32), CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        let sourceRestore = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, body, 0, 0)
        @Assert(sourceRestore > 0, true)
        let restoreDeadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(sourceRestore) == "pending" &&
            sourceHandoffMonotonicMicros() < restoreDeadline) {
            sourceHandoffPump(window)
        }
        @Assert(sourceHandoffMonotonicMicros() < restoreDeadline, true)
        @Assert(window.selectionRestoreState(sourceRestore), "installed")

        let startPoint = sourceHandoffTextPoint(window, 8003, 8803, 0.12)
        let endPoint = sourceHandoffTextPoint(window, 8003, 8803, 0.82)
        @Assert(startPoint[0] && endPoint[0], true)
        let (startStatus, expectedAnchor, _) = window.hitTestComposableTextDetailed(
            8003, Float64(startPoint[1]), Float64(startPoint[2]))
        let (endStatus, expectedFocus, _) = window.hitTestComposableTextDetailed(
            8003, Float64(endPoint[1]), Float64(endPoint[2]))
        @Assert(startStatus, 0)
        @Assert(endStatus, 0)
        @Assert(expectedFocus > expectedAnchor, true)
        let before = owner.sourceSelectionSnapshot()
        @Assert(unsafe { cjgui_internal_renderer_test_arm_pending_selection_pointer_update(
            window.testSessionToken(), endPoint[1], endPoint[2]) }, CJGUI_INTERNAL_RENDERER_OK)
        @Assert(sourceHandoffSendMouse(window, 1u32, startPoint[1], startPoint[2]),
            CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        @Assert(unsafe { cjgui_internal_renderer_test_pending_selection_pointer_update_consumed(
            window.testSessionToken()) }, 1)

        // The one-shot hook has already injected an ordinary mouseDragged
        // UPDATE while B was Pending. These follow-up native events share the
        // same captured gesture and must be accepted after BEGIN is Retained.
        @Assert(sourceHandoffSendMouse(window, 2u32, endPoint[1], endPoint[2]),
            CJGUI_INTERNAL_RENDERER_OK)
        @Assert(sourceHandoffSendMouse(window, 3u32, endPoint[1], endPoint[2]),
            CJGUI_INTERNAL_RENDERER_OK)
        for (_ in 0..8) { sourceHandoffPump(window) }
        let after = owner.sourceSelectionSnapshot()
        @Assert(controller.pointerBeginAdmissions, 1)
        @Assert(controller.pointerUpdateAdmissions >= 1, true)
        @Assert(controller.pointerEndAdmissions, 1)
        @Assert(controller.previewDragActive, false)
        @Assert(controller.pointerBeginPublishes, 0)
        @Assert(controller.pointerEndPublishes, 1)
        @Assert(controller.lastPointerSelectionTransferId > 0u64, true)
        @Assert(after.anchorByte, expectedAnchor)
        @Assert(after.focusByte, expectedFocus)
        @Assert(after.revision > before.revision, true)
        @Assert(session.installedRangeExpectedVersion(), owner.rangeTextVersion())
        let native = sourceHandoffNativeSelection(window)
        @Assert(native[0], CJGUI_INTERNAL_RENDERER_OK)
        @Assert(Int64(native[1]), expectedAnchor)
        @Assert(Int64(native[2]), expectedFocus)
        @Assert(owner.body.text(), body)
        @Assert(owner.body.writeCalls, 0)
    } finally { window.close() }
}

@Test
func pendingSelectionBeginRetainsRealCapturedUpdateAndCompletesThroughEnd(): Unit {
    runPendingSelectionBeginRace(false)
}

@Test
func committedSelectionPublishesNativeSceneEvenWhenOwnerDeclarationIsUnchanged(): Unit {
    let owner = SelectionAuthorityTestOwner()
    owner.body.data = "abcde\nFGHIJ\n".toArray()
    let body = owner.body.text()
    let controller = SourceHandoffController(owner.body)
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "selection-equal-declaration", owner, owner,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.focusAcceptedNodeById(8002), true)
        @Assert(sourceHandoffSetSelection(window, 1u32, 0u32, 0u32), CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        let restore = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, body, 0, 0)
        let deadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(restore) == "pending" &&
            sourceHandoffMonotonicMicros() < deadline) { sourceHandoffPump(window) }
        @Assert(window.selectionRestoreState(restore), "installed")

        let ticket = window.freezeAcceptedSelection(8003).getOrThrow()
        let priorScene = window.inputSceneVersion()
        let priorSubmissions = window.windowProjection().nativeSubmissionCount
        @Assert(window.commitAcceptedSelection(ticket, 9, 2, 2, 9, { =>
            controller.previewSelectionCommits += 1
        }), true)
        @Assert(window.acceptedSelectionTransferId(8003, 8803) > 0u64, true)
        @Assert(owner.sourceSelectionSnapshot().anchorByte, 9)
        @Assert(owner.sourceSelectionSnapshot().focusByte, 2)
        // Identical owner declarations must acquire a post-decision native
        // scene witness. Otherwise the transfer keeps suppressing every
        // non-focus fragment as an old selection indefinitely.
        @Assert(window.refresh(), true)
        @Assert(window.inputSceneVersion() > priorScene, true)
        @Assert(window.windowProjection().nativeSubmissionCount, priorSubmissions + 1)
        let publishedScene = window.inputSceneVersion()
        @Assert(window.refresh(), true)
        @Assert(window.inputSceneVersion(), publishedScene)
        @Assert(window.windowProjection().nativeSubmissionCount, priorSubmissions + 1)
        @Assert(controller.previewSelectionCommits, 1)
        @Assert(owner.body.text(), body)
        @Assert(owner.body.writeCalls, 0)
    } finally { window.close() }
}

@Test
func pendingSourceSelectionBeginRetainsRealCapturedUpdateAndCompletesThroughEnd(): Unit {
    runPendingSelectionBeginRace(true)
}

@Test
func pendingSelectionUnsupportedInstallAndChangedTicketAreNotRetained(): Unit {
    let owner = SelectionAuthorityTestOwner()
    owner.body.data = Array<Byte>(128, repeat: 97u8)
    let body = owner.body.text()
    let controller = SourceHandoffController(owner.body)
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "selection-submit-fail-closed", owner, owner,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.focusAcceptedNodeById(8002), true)
        @Assert(sourceHandoffSetSelection(window, 1u32, 0u32, 0u32), CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        let sourceRestore = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, body, 0, 0)
        @Assert(sourceRestore > 0, true)
        let restoreDeadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(sourceRestore) == "pending" &&
            sourceHandoffMonotonicMicros() < restoreDeadline) {
            sourceHandoffPump(window)
        }
        @Assert(sourceHandoffMonotonicMicros() < restoreDeadline, true)
        @Assert(window.selectionRestoreState(sourceRestore), "installed")

        let before = owner.sourceSelectionSnapshot()
        let ticket = window.freezeAcceptedSelection(8003).getOrThrow()
        @Assert(unsafe { cjgui_internal_renderer_test_arm_selection_geometry_rejection(
            window.testSessionToken()) }, CJGUI_INTERNAL_RENDERER_OK)
        let unsupported = window.submitAcceptedSelection(ticket, 2, 9, 2, 9, { =>
            controller.previewSelectionCommits += 1
        })
        match (unsupported) {
            case CjguiSelectionSubmission.NotAdmitted(_) => ()
            case _ => @Assert(false, true)
        }
        @Assert(unsafe { cjgui_internal_renderer_test_selection_geometry_rejection_consumed(
            window.testSessionToken()) }, 1)
        @Assert(window.selectionRestoreState(sourceRestore + 1), "native_refused_32")
        @Assert(controller.previewSelectionCommits, 0)
        @Assert(owner.sourceSelectionSnapshot().revision, before.revision)
        @Assert(owner.body.text(), body)
        @Assert(owner.body.writeCalls, 0)

        // A same-value owner selection still changes the frozen identity. It
        // must fail admission before the restore slot or callback is touched.
        @Assert(owner.setSourceSelection(owner.rangeTextVersion(), before.anchorByte, before.focusByte), true)
        let stale = window.submitAcceptedSelection(ticket, 2, 9, 2, 9, { =>
            controller.previewSelectionCommits += 1
        })
        match (stale) {
            case CjguiSelectionSubmission.NotAdmitted(_) => ()
            case _ => @Assert(false, true)
        }
        @Assert(window.selectionRestoreState(sourceRestore + 1), "native_refused_32")
        @Assert(controller.previewSelectionCommits, 0)
        @Assert(owner.body.text(), body)
        @Assert(owner.body.writeCalls, 0)
    } finally { window.close() }
}

@Test
func pendingSelectionStatus33RestoreAttemptsAreBoundedPerScene(): Unit {
    let owner = SelectionAuthorityTestOwner()
    owner.body.data = Array<Byte>(128, repeat: 97u8)
    let body = owner.body.text()
    let controller = SourceHandoffController(owner.body)
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "selection-submit-bounded-retry", owner, owner,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.focusAcceptedNodeById(8002), true)
        @Assert(sourceHandoffSetSelection(window, 1u32, 0u32, 0u32), CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        let sourceRestore = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, body, 0, 0)
        @Assert(sourceRestore > 0, true)
        let restoreDeadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(sourceRestore) == "pending" &&
            sourceHandoffMonotonicMicros() < restoreDeadline) {
            sourceHandoffPump(window)
        }
        @Assert(sourceHandoffMonotonicMicros() < restoreDeadline, true)
        @Assert(window.selectionRestoreState(sourceRestore), "installed")

        let startPoint = sourceHandoffTextPoint(window, 8003, 8803, 0.12)
        let endPoint = sourceHandoffTextPoint(window, 8003, 8803, 0.82)
        let (startStatus, anchor16, _) = window.hitTestComposableTextDetailed(
            8003, Float64(startPoint[1]), Float64(startPoint[2]))
        let (endStatus, focus16, _) = window.hitTestComposableTextDetailed(
            8003, Float64(endPoint[1]), Float64(endPoint[2]))
        @Assert(startStatus, 0)
        @Assert(endStatus, 0)
        @Assert(focus16 > anchor16, true)
        @Assert(sourceHandoffSendMouse(window, 1u32, startPoint[1], startPoint[2]),
            CJGUI_INTERNAL_RENDERER_OK)
        let ticket = window.freezeAcceptedSelection(8003).getOrThrow()
        @Assert(unsafe { cjgui_internal_renderer_test_arm_pending_selection_pointer_update(
            window.testSessionToken(), endPoint[1], endPoint[2]) }, CJGUI_INTERNAL_RENDERER_OK)
        let first = window.submitAcceptedSelection(ticket, anchor16, focus16, anchor16, focus16, { =>
            controller.previewSelectionCommits += 1
        })
        let id = match (first) {
            case CjguiSelectionSubmission.Retained(value) => value
            case _ => -1
        }
        @Assert(id > 0, true)
        @Assert(unsafe { cjgui_internal_renderer_test_pending_selection_pointer_update_consumed(
            window.testSessionToken()) }, 1)
        @Assert(controller.previewSelectionCommits, 0)
        let before = owner.sourceSelectionSnapshot()

        // The short submit now consumes the first of the same eight attempts.
        for (_ in 0..7) {
            @Assert(unsafe { cjgui_internal_renderer_test_arm_pending_selection_pointer_update(
                window.testSessionToken(), endPoint[1], endPoint[2]) }, CJGUI_INTERNAL_RENDERER_OK)
            window.pumpPendingSelectionRestore()
            @Assert(unsafe { cjgui_internal_renderer_test_pending_selection_pointer_update_consumed(
                window.testSessionToken()) }, 1)
        }
        @Assert(window.selectionRestoreState(id), "need_prepare_installation")
        @Assert(owner.sourceSelectionSnapshot().revision, before.revision)
        @Assert(owner.sourceSelectionSnapshot().anchorByte, before.anchorByte)
        @Assert(owner.sourceSelectionSnapshot().focusByte, before.focusByte)
        @Assert(controller.previewSelectionCommits, 0)
        @Assert(owner.body.text(), body)
        @Assert(owner.body.writeCalls, 0)

        // At the per-scene limit an armed event remains unconsumed: pumping
        // cannot become a busy retry loop. A new accepted scene resets the cap.
        @Assert(unsafe { cjgui_internal_renderer_test_arm_pending_selection_pointer_update(
            window.testSessionToken(), endPoint[1], endPoint[2]) }, CJGUI_INTERNAL_RENDERER_OK)
        window.pumpPendingSelectionRestore()
        @Assert(unsafe { cjgui_internal_renderer_test_pending_selection_pointer_update_consumed(
            window.testSessionToken()) }, 0)
        @Assert(window.selectionRestoreState(id), "attempt_limit_exhausted")
    } finally { window.close() }
}

@Test
func longSelectionSubmissionRetainsWithoutPublishingAndSameValueOwnerChoiceDefeatsIt(): Unit {
    let owner = SelectionAuthorityTestOwner()
    owner.body.data = Array<Byte>(4096, repeat: 97u8)
    let body = owner.body.text()
    let controller = SourceHandoffController(owner.body)
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "long-selection-retained", owner, owner,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let before = session.freezeSelectionTicket()
        let ticket = window.freezeAcceptedSelection(8003).getOrThrow()
        let result = window.submitAcceptedSelection(ticket, 1, 20, 1, 20, { => controller.previewSelectionCommits += 1 })
        let id = match (result) {
            case CjguiSelectionSubmission.Retained(value) => value
            case _ => -1
        }
        @Assert(id > 0, true)
        @Assert(window.selectionRestoreState(id), "pending")
        @Assert(controller.previewSelectionCommits, 0)
        @Assert(session.freezeSelectionTicket().selectionRevision, before.selectionRevision)
        @Assert(owner.setSourceSelection(owner.rangeTextVersion(), 0, 0), true)
        window.pumpPendingSelectionRestore()
        @Assert(window.selectionRestoreState(id), "identity_superseded")
        @Assert(controller.previewSelectionCommits, 0)
        @Assert(owner.body.text(), body)
        @Assert(owner.rangeTextVersion(), before.contentVersion)
        @Assert(owner.body.writeCalls, 0)
    } finally { window.close() }
}

@Test
func longSelectionSubmissionSameValueNewRequestSupersedesOnlyPendingIdentity(): Unit {
    let owner = SelectionAuthorityTestOwner()
    owner.body.data = Array<Byte>(4096, repeat: 98u8)
    let body = owner.body.text()
    let controller = SourceHandoffController(owner.body)
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "long-selection-supersession", owner, owner,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let ticket = window.freezeAcceptedSelection(8003).getOrThrow()
        let first = window.requestAcceptedSelectionRestore(ticket, 20, 1, 1, 20, { => controller.previewSelectionCommits += 10 })
        let second = window.requestAcceptedSelectionRestore(ticket, 20, 1, 1, 20, { => controller.previewSelectionCommits += 1 })
        @Assert(first > 0 && second > first, true)
        @Assert(window.selectionRestoreState(first), "superseded")
        @Assert(window.selectionRestoreState(second), "pending")
        @Assert(controller.previewSelectionCommits, 0)
        @Assert(owner.body.text(), body)
        @Assert(owner.rangeTextVersion(), 1)
        @Assert(owner.body.writeCalls, 0)
    } finally { window.close() }
}

@Test
func longSelectionSubmissionCommitsSourceAuthorityOnlyAfterPreparedBReceipt(): Unit {
    let owner = SelectionAuthorityTestOwner()
    owner.body.data = Array<Byte>(4096, repeat: 99u8)
    @Assert(owner.setSourceSelection(owner.rangeTextVersion(), 5, 10), true)
    let body = owner.body.text()
    let controller = SourceHandoffController(owner.body)
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "long-selection-installed-b", owner, owner,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.focusAcceptedNodeById(8002), true)
        @Assert(sourceHandoffSetSelection(window, 1u32, 5u32, 10u32), CJGUI_INTERNAL_RENDERER_OK)
        @Assert(sourceHandoffSelection(window, 1u32, 5u32, 10u32), CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        @Assert(session.selection16()[0], 5)
        @Assert(session.selection16()[1], 10)
        let sourceRestore = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, body, 5, 10)
        @Assert(sourceRestore > 0, true)
        let restoreDeadline = sourceHandoffMonotonicMicros() + 5000000u64
        @Assert(restoreDeadline > 5000000u64, true)
        while (window.selectionRestoreState(sourceRestore) == "pending" &&
            sourceHandoffMonotonicMicros() < restoreDeadline) {
            sourceHandoffPump(window)
            let _ = unsafe { cjgui_internal_renderer_test_wait_for_text_preparation_finished(1u32) }
        }
        @Assert(sourceHandoffMonotonicMicros() < restoreDeadline, true)
        @Assert(window.selectionRestoreState(sourceRestore), "installed")
        @Assert(session.installedRangeExpectedVersion(), owner.rangeTextVersion())
        @Assert(sourceHandoffNativeSelection(window)[1], 5u32)
        @Assert(sourceHandoffNativeSelection(window)[2], 10u32)
        let before = session.freezeSelectionTicket()
        let ticket = window.freezeAcceptedSelection(8003).getOrThrow()
        let submission = window.submitAcceptedSelection(ticket, 20, 35, 20, 35, { =>
            controller.recordDeferredSelectionPublish(window, 8003, 8803)
        })
        let id = match (submission) {
            case CjguiSelectionSubmission.Retained(value) => value
            case _ => -1
        }
        @Assert(id > 0, true)
        @Assert(window.selectionRestoreState(id), "pending")
        @Assert(controller.deferredSelectionPublishes, 0)
        @Assert(owner.sourceSelectionSnapshot().anchorByte, 5)
        @Assert(owner.sourceSelectionSnapshot().focusByte, 10)
        @Assert(owner.sourceSelectionSnapshot().revision, before.selectionRevision)
        @Assert(owner.body.text(), body)
        @Assert(owner.body.writeCalls, 0)

        let selectionDeadline = sourceHandoffMonotonicMicros() + 5000000u64
        @Assert(selectionDeadline > 5000000u64, true)
        while (window.selectionRestoreState(id) == "pending" &&
            sourceHandoffMonotonicMicros() < selectionDeadline) {
            sourceHandoffPump(window)
            let _ = unsafe { cjgui_internal_renderer_test_wait_for_text_preparation_finished(1u32) }
        }
        @Assert(sourceHandoffMonotonicMicros() < selectionDeadline, true)
        @Assert(window.selectionRestoreState(id), "installed")
        @Assert(controller.deferredSelectionPublishes, 1)
        @Assert(controller.deferredSelectionTransferId > 0u64, true)
        let current = owner.sourceSelectionSnapshot()
        @Assert(current.anchorByte, 20)
        @Assert(current.focusByte, 35)
        @Assert(current.revision, before.selectionRevision + 1)
        @Assert(session.installedRangeExpectedVersion(), owner.rangeTextVersion())
        let native = sourceHandoffNativeSelection(window)
        @Assert(native[0], CJGUI_INTERNAL_RENDERER_OK)
        @Assert(native[1], 20u32)
        @Assert(native[2], 35u32)
        @Assert(owner.body.text(), body)
        @Assert(owner.body.writeCalls, 0)
        sourceHandoffPump(window)
        sourceHandoffPump(window)
        @Assert(controller.deferredSelectionPublishes, 1)
        @Assert(owner.sourceSelectionSnapshot().revision, before.selectionRevision + 1)
    } finally { window.close() }
}

@Test
func longSelectionSubmissionSameValueAuthorityCancelsRunningWorkerAndKeepsAUsable(): Unit {
    let owner = SelectionAuthorityTestOwner()
    owner.body.data = Array<Byte>(4096, repeat: 100u8)
    @Assert(owner.setSourceSelection(owner.rangeTextVersion(), 5, 10), true)
    let body = owner.body.text()
    let controller = SourceHandoffController(owner.body)
    controller.selectionDocumentId = "test-authority"
    let window = sourceHandoffWindow(controller)
    var gateClosed = false
    try {
        let session = window.bindRangeTextSession(8002, "long-selection-worker-cancel", owner, owner,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.focusAcceptedNodeById(8002), true)
        @Assert(sourceHandoffSetSelection(window, 1u32, 5u32, 10u32), CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        @Assert(sourceHandoffNativeSelection(window)[0], CJGUI_INTERNAL_RENDERER_OK)
        let sourceRestore = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, body, 5, 10)
        @Assert(sourceRestore > 0, true)
        let restoreDeadline = sourceHandoffMonotonicMicros() + 5000000u64
        @Assert(restoreDeadline > 5000000u64, true)
        while (window.selectionRestoreState(sourceRestore) == "pending" &&
            sourceHandoffMonotonicMicros() < restoreDeadline) {
            sourceHandoffPump(window)
            let _ = unsafe { cjgui_internal_renderer_test_wait_for_text_preparation_finished(1u32) }
        }
        @Assert(sourceHandoffMonotonicMicros() < restoreDeadline, true)
        @Assert(window.selectionRestoreState(sourceRestore), "installed")
        @Assert(session.installedRangeExpectedVersion(), owner.rangeTextVersion())
        @Assert(sourceHandoffNativeSelection(window)[1], 5u32)
        @Assert(sourceHandoffNativeSelection(window)[2], 10u32)
        let notificationsBefore = controller.completionCount
        let before = session.freezeSelectionTicket()
        let ticket = window.freezeAcceptedSelection(8003).getOrThrow()
        let submission = window.submitAcceptedSelection(ticket, 20, 35, 20, 35, { =>
            controller.recordDeferredSelectionPublish(window, 8003, 8803)
        })
        let id = match (submission) {
            case CjguiSelectionSubmission.Retained(value) => value
            case _ => -1
        }
        @Assert(id > 0, true)
        unsafe { cjgui_internal_renderer_test_close_text_preparation_worker_gate() }
        gateClosed = true
        sourceHandoffPump(window)
        @Assert(unsafe { cjgui_internal_renderer_test_wait_for_text_preparation_worker_gate(5000u32) }, 1)
        @Assert(window.selectionRestoreState(id), "pending")
        @Assert(controller.deferredSelectionPublishes, 0)
        @Assert(controller.completionCount, notificationsBefore)
        @Assert(owner.sourceSelectionSnapshot().anchorByte, 5)
        @Assert(owner.sourceSelectionSnapshot().focusByte, 10)
        @Assert(owner.sourceSelectionSnapshot().revision, before.selectionRevision)
        @Assert(sourceHandoffNativeSelection(window)[1], 5u32)
        @Assert(sourceHandoffNativeSelection(window)[2], 10u32)

        // Same endpoints with a new owner revision invalidate the frozen
        // request while the native worker is demonstrably held at its gate.
        @Assert(owner.setSourceSelection(owner.rangeTextVersion(), 5, 10), true)
        window.pumpPendingSelectionRestore()
        @Assert(window.selectionRestoreState(id), "identity_superseded")
        @Assert(controller.deferredSelectionPublishes, 0)
        @Assert(controller.completionCount, notificationsBefore)
        @Assert(owner.sourceSelectionSnapshot().anchorByte, 5)
        @Assert(owner.sourceSelectionSnapshot().focusByte, 10)
        @Assert(owner.sourceSelectionSnapshot().revision, before.selectionRevision + 1)
        @Assert(owner.body.text(), body)
        @Assert(owner.body.writeCalls, 0)

        unsafe { cjgui_internal_renderer_test_open_text_preparation_worker_gate() }
        gateClosed = false
        @Assert(unsafe { cjgui_internal_renderer_test_wait_for_text_preparation_finished(5000u32) }, 1)
        @Assert(window.installedSelectionCompletion().isNone(), true)
        @Assert(controller.completionCount, notificationsBefore)
        @Assert(owner.body.writeCalls, 0)
        controller.selectionChoiceAnchorByte = 5
        controller.selectionChoiceFocusByte = 10
        @Assert(sourceHandoffInsert(window, 1u32, "Z"), CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        let expected = Array<Byte>(4092, repeat: 100u8)
        expected[5] = 90u8
        @Assert(owner.body.text(), String.fromUtf8(expected))
        @Assert(owner.body.writeCalls, 1)
        @Assert(owner.rangeTextVersion(), before.contentVersion + 1)
        @Assert(controller.deferredSelectionPublishes, 0)
    } finally {
        if (gateClosed) {
            unsafe { cjgui_internal_renderer_test_open_text_preparation_worker_gate() }
            let _ = unsafe { cjgui_internal_renderer_test_wait_for_text_preparation_finished(5000u32) }
        }
        window.close()
    }
}

@Test
func sourceHandoffVerticalInputRetainsExactAfterChainAndBoundsSuffix(): Unit {
    sourceHandoffArrowInputRetainsExactAfterChainAndBoundsSuffix("down", "down")
}

@Test
func sourceHandoffHorizontalInputRetainsExactAfterChainAndBoundsSuffix(): Unit {
    sourceHandoffArrowInputRetainsExactAfterChainAndBoundsSuffix("left", "right")
}

private func sourceHandoffArrowInputRetainsExactAfterChainAndBoundsSuffix(firstDirection: String,
    secondDirection: String): Unit {
    let owner = FakeTextOwner("ABCDE🙂\n")
    let controller = SourceHandoffController(owner)
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "vertical-input-fifo", owner, owner,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let source = window.freezeAcceptedSelection(8002).getOrThrow()
        let (generation, _) = internalRendererCoordinateLifetime(window.testSessionToken())
        @Assert(generation != 0u64, true)
        @Assert(window.retainVisualInputIntent(1u64, 0u64, generation, source,
            firstDirection, false, -1.0, 0u64), true)
        @Assert(window.retainVisualInputIntent(2u64, 1u64, generation, source,
            secondDirection, true, -1.0, 0u64), true)
        @Assert(window.visualInputIntentHeadIsCurrent(), true)
        @Assert(window.settleVisualInputIntent(2u64, CjguiVisualInputIntentOutcome.AtBoundary), false)
        let first = window.pendingVisualInputIntent().getOrThrow()
        @Assert(first.direction, firstDirection)
        @Assert(first.sequence, 1u64)
        @Assert(first.previousSequence, 0u64)
        @Assert(first.sourceTicket.nodeId, 8002)
        @Assert(window.bindVisualInputTransfer(1u64, 9001u64), true)
        @Assert(window.bindVisualInputTransfer(1u64, 9002u64), false)
        @Assert(window.pendingVisualInputIntent().getOrThrow().transferId, 9001u64)
        @Assert(window.settleVisualInputIntent(1u64, CjguiVisualInputIntentOutcome.Committed,
            acceptedSource: Some(source), acceptedPreferredX: 37.0), true)
        let rebased = window.pendingVisualInputIntent().getOrThrow()
        @Assert(rebased.direction, secondDirection)
        @Assert(rebased.sequence, 2u64)
        @Assert(rebased.previousSequence, 1u64)
        @Assert(rebased.preferredX, 37.0)
        @Assert(window.settleVisualInputIntent(2u64, CjguiVisualInputIntentOutcome.AtBoundary), true)
        @Assert(window.pendingVisualInputIntent().isNone(), true)

        var sequence: UInt64 = 3u64
        var previous: UInt64 = 2u64
        var admitted: Int64 = 0
        while (sequence < 67u64) {
            if (window.retainVisualInputIntent(sequence, previous, generation, source,
                "up", false, -1.0, 0u64)) { admitted += 1 }
            previous = sequence
            sequence += 1u64
        }
        @Assert(admitted, 64)
        @Assert(window.retainVisualInputIntent(67u64, 66u64, generation, source,
            "up", false, -1.0, 0u64), false)
        @Assert(window.visualInputIntentHeadIsCurrent(), true)
        // A new accepted owner selection invalidates the captured source and
        // closes every queued successor before another movement can run.
        session.setSelection16(1, 1)
        @Assert(window.visualInputIntentHeadIsCurrent(), false)
        @Assert(window.pendingVisualInputIntent().isNone(), true)
        @Assert(window.settleVisualInputIntent(3u64, CjguiVisualInputIntentOutcome.Aborted), false)
        @Assert(window.pendingVisualInputIntent().isNone(), true)
        @Assert(window.retainVisualInputIntent(68u64, 67u64, generation + 1u64, source,
            "down", false, -1.0, 0u64), false)
        @Assert(owner.writeCalls, 0)
    } finally {
        window.close()
    }
}

// Controlled native pending-present tickets exercise the real owner ACK gate.
// Normal macOS present is synchronous; these are closure contract tests.
@Test
func sourceHandoffCloseHeldTicketKeepsOriginalRestoreAndRefusesNewRequests(): Unit {
    let owner = FakeTextOwner("ABCDE🙂\n")
    let controller = SourceHandoffController(owner)
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "close-restore", owner, owner,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        session.setSelection16(2, 2)
        let ticket = window.freezeAcceptedSelection(8002).getOrThrow()
        let request = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.text(), 2, 2)
        @Assert(request > 0, true)
        @Assert(window.testHoldNextComposablePresent(), true)
        controller.revision += 1
        @Assert(window.refreshIfNeeded(), false)
        @Assert(window.nativeStatus(), CJGUI_INTERNAL_RENDERER_PRESENT_PENDING)
        window.close()
        @Assert(window.isOpen(), true)
        @Assert(window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.text(), 3, 3), -1)
        @Assert(window.requestAcceptedSelectionRestore(ticket, 2, 2, 2, 2,
            { => controller.previewSelectionCommits += 1 }), -1)
        @Assert(window.selectionRestoreState(request), "pending")
        @Assert(window.testSelectionRestoreAttemptCount(), 0)
        @Assert(controller.previewSelectionCommits, 0)
        @Assert(owner.ver, 1)
        @Assert(owner.text(), "ABCDE🙂\n")
    } finally {
        let _ = window.testResolvePendingComposablePresent()
        window.close()
    }
}

@Test
func testPreparedSelectionMirrorMoveCannotSignOwnedRestoration(): Unit {
    let owner = FakeTextOwner("abcdefghABCDEFGHijklmnopIJKLMNOP")
    let controller = SourceHandoffController(owner)
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "mirror-selection-proof", owner, owner,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, materializeLimit: 8)
    controller.attach(window, session)
    session.setSelection16(2, 2)
    @Assert(session.prepareSourceRange(1, 24, 24).isSome(), true)
    @Assert(window.requestOwnedSelectionRestore(), false)
    @Assert(owner.writeCalls, 0)
    let kept = session.sourceRangeForSelectionTicket(session.freezeSelectionTicket()).getOrThrow()
    @Assert(kept[1], 2)
    window.close()
}

@Test
func testOwnerReplacementAfterChoiceIsProjectedBeforeRestoreAdmission(): Unit {
    let owner = SelectionAuthorityTestOwner()
    let controller = SourceHandoffController(owner.body)
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "owner-after-restore", owner, owner,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    session.setSelection16(2, 4)
    let total = owner.body.rangeTextByteLength()
    let _ = owner.body.applyRangeTextEdit(1, 0, total, "NEW BODY")
    @Assert(owner.body.ver, 2)
    @Assert(owner.setSourceSelection(2, 3, 3), true)
    @Assert(session.refreshMirror(), true)
    @Assert(session.selectionCoordinatesMatchMirror(), false)
    @Assert(window.requestOwnedSelectionRestore(), true)
    let (start, end) = session.selection16()
    @Assert(start, 3)
    @Assert(end, 3)
    @Assert(owner.body.writeCalls, 1)
    window.close()
}

@Test
func testOwnerChoiceOutsideMovedMirrorCannotSignOwnedRestoration(): Unit {
    let owner = SelectionAuthorityTestOwner()
    owner.body.data = "abcdefghABCDEFGHijklmnopIJKLMNOP".toArray()
    let controller = SourceHandoffController(owner.body)
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "owner-mirror-proof", owner, owner,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, materializeLimit: 8)
    session.setSelection16(2, 2)
    @Assert(session.prepareSourceRange(1, 24, 24).isSome(), true)
    @Assert(window.requestOwnedSelectionRestore(), false)
    @Assert(owner.sourceSelectionSnapshot().anchorByte, 2)
    @Assert(owner.sourceSelectionSnapshot().focusByte, 2)
    @Assert(owner.body.writeCalls, 0)
    window.close()
}

@Test
func sourceHandoffCloseHeldTicketDoesNotAdvanceOriginalInstallationAttempt(): Unit {
    let owner = FakeTextOwner("ABCDE🙂\n")
    let controller = SourceHandoffController(owner)
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "close-attempt", owner, owner,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        session.setSelection16(2, 2)
        let request = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.text(), 2, 2)
        @Assert(window.testHoldNextComposablePresent(), true)
        controller.revision += 1
        @Assert(window.refreshIfNeeded(), false)
        window.close()
        let attempts = window.testSelectionRestoreAttemptCount()
        window.pumpPendingSelectionRestore()
        @Assert(window.testSelectionRestoreAttemptCount(), attempts)
        @Assert(window.selectionRestoreState(request), "pending")
        @Assert(window.isOpen(), true)
    } finally {
        let _ = window.testResolvePendingComposablePresent()
        window.close()
    }
}

@Test
func sourceHandoffCloseResolvedTicketKeepsPaintAndAnimationBehindCloseGate(): Unit {
    let owner = FakeTextOwner("ABCDE🙂\n")
    let controller = SourceHandoffController(owner)
    let window = sourceHandoffWindow(controller)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.animateNodeOpacity("semantic:source-body", 0.5,
            spec: CjguiComposableUiAnimationSpec.tween(durationMs: 1000), atTime: MonoTime.now()), true)
        let alpha = window.animatedNodeOpacity("semantic:source-body").getOrThrow()
        let accepted = window.windowProjection().acceptedSceneVersion
        @Assert(window.testHoldNextComposablePresent(), true)
        controller.revision += 1
        @Assert(window.refreshIfNeeded(), false)
        window.close()
        @Assert(window.isOpen(), true)
        @Assert(window.testResolvePendingComposablePresent(), true)
        @Assert(window.testRefreshInteractionPaint(), false)
        @Assert(window.windowProjection().acceptedSceneVersion, accepted)
        @Assert(window.needsAnimationTick(), false)
        let _ = window.testAdvanceAnimationsAtMs(1000000000000000.0)
        @Assert(window.animatedNodeOpacity("semantic:source-body").getOrThrow(), alpha)
        window.close()
        @Assert(window.isOpen(), false)
    } finally {
        let _ = window.testResolvePendingComposablePresent()
        window.close()
    }
}

@Test
func sourceHandoffPresentationSelectionThenRealTextKitRUsesNewReceipt(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "first line\nsecond source row\n".toArray()
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    controller.selectionDocumentId = "test-authority"
    controller.requireCompletion = true
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "source-handoff", authority, authority,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.focusAcceptedNodeById(8002), true)
        @Assert(sourceHandoffInsert(window, 1u32, "X"), CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        @Assert(owner.text(), "first line\nsecond source row\nX")
        @Assert(sourceHandoffInsert(window, 1u32, "Y"), CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        @Assert(owner.text(), "first line\nsecond source row\nXY")

        @Assert(window.refresh(), true)
        // Hit the preview through the production coordinate-based mouse path.
        // Down queues focus plus pointer BEGIN; up queues pointer END. Drain
        // both original FIFO portions; the controller commits during dispatch.
        let previewPoint = sourceHandoffAcceptedPoint(window, 8003, 8803)
        @Assert(previewPoint[0], true)
        @Assert(sourceHandoffSendMouse(window, 1u32, previewPoint[1], previewPoint[2]),
            CJGUI_INTERNAL_RENDERER_OK)
        let previewDownTurn = window.pump(0u32)
        @Assert(previewDownTurn.isOpen, true)
        @Assert(sourceHandoffSendMouse(window, 3u32, previewPoint[1], previewPoint[2]),
            CJGUI_INTERNAL_RENDERER_OK)
        let previewUpTurn = window.pump(0u32)
        @Assert(previewUpTurn.isOpen, true)
        // The same normal-consumer semantic transaction runs during pointer
        // dispatch, before pump-tail recovery can install a different surface.
        @Assert(controller.previewSelectionCommits > 0, true)
        // Click the source at its accepted geometry. TextKit captures both the
        // focus and click selection before Cangjie drains their FIFO entries.
        let sourcePoint = sourceHandoffAcceptedPoint(window, 8002, 8802)
        @Assert(sourcePoint[0], true)
        @Assert(sourceHandoffSendMouse(window, 1u32, sourcePoint[1], sourcePoint[2]),
            CJGUI_INTERNAL_RENDERER_OK)
        let clickedSelection = sourceHandoffNativeSelection(window)
        @Assert(clickedSelection[0], CJGUI_INTERNAL_RENDERER_OK)
        @Assert(sourceHandoffSendMouse(window, 3u32, sourcePoint[1], sourcePoint[2]),
            CJGUI_INTERNAL_RENDERER_OK)
        // A same-body selection revision supersedes the captured click range
        // before its queued kind-33 event is consumed. Its receipt confirmation
        // is stale; the later accepted selection below confirms the new range.
        session.setSelection16(1, 1)
        @Assert(sourceHandoffSetSelection(window, 1u32, 1u32, 1u32), CJGUI_INTERNAL_RENDERER_OK)
        @Assert(sourceHandoffLateConfirm(window, clickedSelection[1], clickedSelection[2]),
            CJGUI_INTERNAL_RENDERER_SCENE_STALE)
        // The actual click kind-33 now fails exact readback; this accepted
        // nonterminal selection refreshes only the receipt's selection pair.
        @Assert(sourceHandoffSelection(window, 1u32, 2u32, 2u32), CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        // The owner/native pointer choice may retain a source reinstall after
        // the real click FIFO. Do not inject TextKit input until that exact
        // source body and directed selection have an installed receipt.
        let sourceReceipt = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.text(), 2, 2)
        @Assert(sourceReceipt > 0, true)
        let sourceReceiptDeadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(sourceReceipt) == "pending" &&
            sourceHandoffMonotonicMicros() < sourceReceiptDeadline) {
            sourceHandoffPump(window)
        }
        @Assert(sourceHandoffMonotonicMicros() < sourceReceiptDeadline, true)
        @Assert(window.selectionRestoreState(sourceReceipt), "installed")
        @Assert(session.installedRangeExpectedVersion(), owner.ver)
        @Assert(controller.completionCount > 0, true)
        @Assert(controller.completion.getOrThrow().requestId, sourceReceipt)
        @Assert(controller.completion.getOrThrow().sourceOwnerVersion, owner.ver)
        let writesBeforeR = owner.writeCalls
        @Assert(sourceHandoffInsert(window, 1u32, "R"), CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        @Assert(owner.text(), "fiRrst line\nsecond source row\nXY")
        @Assert(owner.writeCalls, writesBeforeR + 1)
        @Assert(session.installedRangeExpectedVersion(), owner.ver)
    } finally { window.close() }
}

@Test
func sourceHandoffTextKitInsertUsesOwnerGlobalAuthorizedChoiceOnce(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "ABCDE🙂\n".toArray()
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    controller.selectionDocumentId = "test-authority"
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "source-transfer-typed", authority, authority,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.focusAcceptedNodeById(8002), true)
        @Assert(sourceHandoffSelection(window, 1u32, 1u32, 3u32), CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        @Assert(sourceHandoffNativeSelection(window)[0], CJGUI_INTERNAL_RENDERER_OK)
        session.setSelection16(1, 3)
        controller.selectionChoiceAnchorByte = 1
        controller.selectionChoiceFocusByte = 3
        let ticket = window.freezeAcceptedSelection(8002).getOrThrow()
        let transfer = window.prepareSelectionTransferFromInstalledSource(ticket, 1, 3)
        @Assert(transfer.isSome(), true)
        @Assert(window.commitAcceptedSelection(ticket, 1, 3, 1, 3, { => },
            selectionTransferId: transfer.getOrThrow()), true)
        @Assert(sourceHandoffInsert(window, 1u32, "Z"), CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        @Assert(owner.text(), "AZDE🙂\n")
        @Assert(controller.selectionChoiceId, 1)
        @Assert(session.contentVersion(), owner.ver)
    } finally { window.close() }
}

@Test
func sourceHandoffRejectsBasisAfterExternalSameValueOwnerVersion(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "alpha\nbeta\n".toArray()
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    controller.selectionDocumentId = "test-authority"
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "source-handoff-stale", authority, authority,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.focusAcceptedNodeById(8002), true)
        controller.requireCompletion = true
        let initialReceipt = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.text(), 0, 0)
        @Assert(initialReceipt > 0, true)
        let initialReceiptDeadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(initialReceipt) == "pending" &&
            sourceHandoffMonotonicMicros() < initialReceiptDeadline) {
            sourceHandoffPump(window)
        }
        @Assert(sourceHandoffMonotonicMicros() < initialReceiptDeadline, true)
        @Assert(window.selectionRestoreState(initialReceipt), "installed")
        @Assert(controller.completionCount > 0, true)
        @Assert(controller.completion.getOrThrow().requestId, initialReceipt)
        @Assert(window.refresh(), true)
        // Focus the presentation through its accepted geometry and production
        // pointer capture, then consume focus/BEGIN and END through the FIFO.
        let previewPoint = sourceHandoffAcceptedPoint(window, 8003, 8803)
        @Assert(previewPoint[0], true)
        @Assert(sourceHandoffSendMouse(window, 1u32, previewPoint[1], previewPoint[2]),
            CJGUI_INTERNAL_RENDERER_OK)
        let previewDownTurn = window.pump(0u32)
        @Assert(previewDownTurn.isOpen, true)
        @Assert(sourceHandoffSendMouse(window, 3u32, previewPoint[1], previewPoint[2]),
            CJGUI_INTERNAL_RENDERER_OK)
        let previewUpTurn = window.pump(0u32)
        @Assert(previewUpTurn.isOpen, true)
        // The same normal-consumer semantic transaction runs during pointer
        // dispatch, before pump-tail recovery can install a different surface.
        @Assert(controller.previewSelectionCommits > 0, true)
        // An external same-value owner version change invalidates the exact
        // pre-armed source basis. Reading the new version cannot let the old
        // candidate claim authority over those pixels.
        owner.bumpVersionOnly()
        @Assert(session.refreshMirror(), true)
        session.setSelection16(0, 0)
        let sourcePoint = sourceHandoffAcceptedPoint(window, 8002, 8802)
        @Assert(sourcePoint[0], true)
        @Assert(sourceHandoffSendMouse(window, 1u32, sourcePoint[1], sourcePoint[2]),
            CJGUI_INTERNAL_RENDERER_OK)
        @Assert(sourceHandoffSendMouse(window, 3u32, sourcePoint[1], sourcePoint[2]),
            CJGUI_INTERNAL_RENDERER_OK)
        @Assert(sourceHandoffSelection(window, 1u32, 2u32, 2u32), CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        let staleWrites = owner.writeCalls
        @Assert(sourceHandoffInsert(window, 1u32, "Q"), CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        @Assert(owner.text(), "alpha\nbeta\n")
        @Assert(owner.writeCalls, staleWrites)
        @Assert(window.refresh(), true)

        // Re-publish against the current owner version, then a fresh actual
        // source installation receipt permits the TextKit callback once.
        let refreshedPreviewPoint = sourceHandoffAcceptedPoint(window, 8003, 8803)
        @Assert(refreshedPreviewPoint[0], true)
        @Assert(sourceHandoffSendMouse(window, 1u32, refreshedPreviewPoint[1], refreshedPreviewPoint[2]),
            CJGUI_INTERNAL_RENDERER_OK)
        let refreshedPreviewDownTurn = window.pump(0u32)
        @Assert(refreshedPreviewDownTurn.isOpen, true)
        @Assert(sourceHandoffSendMouse(window, 3u32, refreshedPreviewPoint[1], refreshedPreviewPoint[2]),
            CJGUI_INTERNAL_RENDERER_OK)
        let refreshedPreviewUpTurn = window.pump(0u32)
        @Assert(refreshedPreviewUpTurn.isOpen, true)
        @Assert(controller.previewSelectionCommits > 2, true)
        let refreshedSourcePoint = sourceHandoffAcceptedPoint(window, 8002, 8802)
        @Assert(refreshedSourcePoint[0], true)
        @Assert(sourceHandoffSendMouse(window, 1u32, refreshedSourcePoint[1], refreshedSourcePoint[2]),
            CJGUI_INTERNAL_RENDERER_OK)
        @Assert(sourceHandoffSendMouse(window, 3u32, refreshedSourcePoint[1], refreshedSourcePoint[2]),
            CJGUI_INTERNAL_RENDERER_OK)
        @Assert(sourceHandoffSelection(window, 1u32, 2u32, 2u32), CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        // Reinstall the refreshed owner version after the newly accepted
        // choice; the earlier stale-basis attempt cannot lend it a receipt.
        let sourceReceipt = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.text(), 2, 2)
        @Assert(sourceReceipt > 0, true)
        let sourceReceiptDeadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(sourceReceipt) == "pending" &&
            sourceHandoffMonotonicMicros() < sourceReceiptDeadline) {
            sourceHandoffPump(window)
        }
        @Assert(sourceHandoffMonotonicMicros() < sourceReceiptDeadline, true)
        @Assert(window.selectionRestoreState(sourceReceipt), "installed")
        @Assert(session.installedRangeExpectedVersion(), owner.ver)
        @Assert(controller.completionCount > 1, true)
        @Assert(controller.completion.getOrThrow().requestId, sourceReceipt)
        @Assert(controller.completion.getOrThrow().sourceOwnerVersion, owner.ver)
        let writesBeforeR = owner.writeCalls
        @Assert(sourceHandoffInsert(window, 1u32, "R"), CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        @Assert(owner.text(), "alRpha\nbeta\n")
        @Assert(owner.writeCalls, writesBeforeR + 1)
        @Assert(session.installedRangeExpectedVersion(), owner.ver)
    } finally { window.close() }
}

@Test
func sourceHandoffNonBudgetRestoreSettlesSameRequestWithActualReceipt(): Unit {
    let owner = FakeTextOwner("ABCDE🙂\n")
    let controller = SourceHandoffController(owner)
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "source-handoff-restore", owner, owner,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.focusAcceptedNodeById(8002), true)
        session.setSelection16(2, 2)
        let request = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.text(), 2, 2)
        @Assert(request > 0, true)
        let original = sourceHandoffNativeSelection(window)
        @Assert(original[0], CJGUI_INTERNAL_RENDERER_OK)
        var before = readPacedSourceProxyPreparation(window, request, owner.text(), 2u32, 2u32,
            nodeId: 8002u64, resourceId: 8802u32)
        @Assert(before.status, CJGUI_INTERNAL_RENDERER_OK)
        @Assert(before.state, PACED_SOURCE_PROXY_ABSENT)
        // Drive the actual native units, rather than confusing deferred units
        // with the existing eight installation attempts. Every pending unit
        // must advance the same actual preparation; no sleep or retry is used.
        var turn: Int64 = 0
        while (turn < 24 && window.selectionRestoreState(request) == "pending") {
            sourceHandoffPump(window)
            if (window.selectionRestoreState(request) == "pending") {
                let after = readPacedSourceProxyPreparation(window, request, owner.text(), 2u32, 2u32,
                    nodeId: 8002u64, resourceId: 8802u32)
                assertPacedSourceProxyPreparationIdentity(after, request, 2u32, 2u32)
                @Assert(after.state != before.state || after.phase != before.phase ||
                    after.characterCursor != before.characterCursor || after.tileCursor != before.tileCursor, true)
                let whilePreparing = sourceHandoffNativeSelection(window)
                @Assert(whilePreparing[1], original[1])
                @Assert(whilePreparing[2], original[2])
                before = after
            }
            turn += 1
        }
        @Assert(turn < 24, true)
        @Assert(window.selectionRestoreState(request), "installed")
        // This is a selection installation, not a rejected-edit proxy
        // calibration; the existing rollback/ACK counter stays unchanged.
        @Assert(window.textSessionRestoreCount(), 0)
        @Assert(session.needsNativeSelectionRestore(), false)
        @Assert(session.installedRangeExpectedVersion(), owner.ver)
        let actual = sourceHandoffNativeSelection(window)
        @Assert(actual[0], CJGUI_INTERNAL_RENDERER_OK)
        @Assert(actual[1], 2u32)
        @Assert(actual[2], 2u32)
        @Assert(owner.text(), "ABCDE🙂\n")
        @Assert(owner.ver, 1)
        // The actual TextKit callback must consume this installed source once.
        // Extra pump turns cannot replay the input or settle another version.
        @Assert(sourceHandoffInsert(window, 1u32, "Z"), CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        sourceHandoffPump(window)
        sourceHandoffPump(window)
        @Assert(owner.text(), "ABZCDE🙂\n")
        @Assert(owner.ver, 2)
        @Assert(session.installedRangeExpectedVersion(), 2)
        @Assert(window.selectionRestoreState(request), "installed")
    } finally { window.close() }
}

private func sourceHandoffDirectionScenario(mode: Int64): Unit {
    let authority = SelectionAuthorityTestOwner()
    var body = ""
    for (_ in 0..8) { body += "alpha bravo charlie delta echo fox\n" }
    authority.body.data = body.toArray()
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    controller.scrollFixture = true
    // Keep the existing small text target; overflowing hit routing is a separate original counter.
    controller.previewHeight = 70
    // This direction control has only the accepted scroll clip. The original
    // moving nested-clip counter remains independently RED.
    controller.previewContentClips = false
    controller.selectionDocumentId = "test-authority"
    controller.requireCompletion = true
    controller.useSelectionSubmissionForPointer = true
    controller.useSourceSelectionSubmissionForPointer = true
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "source-direction-interleaving", authority, authority,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    controller.attach(window, session)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let (left, top, width, height) = window.nodeRect(8005).getOrThrow()
        for (node in window.acceptedSceneNodes()) {
            if (node.nodeId == 8003 || node.nodeId == 8005) {
                println("SOURCE_DIRECTION_SETUP node=${node.nodeId} kind=${node.nodeKind} " +
                    "resource=${node.resourceId} x=${node.bounds.x} y=${node.bounds.y} " +
                    "width=${node.bounds.width} height=${node.bounds.height}")
            }
        }
        let x = Float64(left + 24)
        let inside = Float64(top + 30)
        let below = Float64(top + height + 20)
        let above = Float64(top - 20)
        @Assert(unsafe { cjgui_internal_renderer_test_begin_composable_pointer(window.testSessionToken(),
            8003u64, x, inside) }, CJGUI_INTERNAL_RENDERER_OK)
        var beginTurns = 0
        while (controller.completionCount == 0 && beginTurns < 12) {
            sourceHandoffPump(window)
            beginTurns += 1
        }
        @Assert(controller.pointerBeginAdmissions, 1)
        @Assert(controller.completionCount > 0, true)
        let gesture = sourceHandoffNativeGesture(window)
        let before = controller.sourceViewport.acceptedOffset()
        if (mode != 2) {
            @Assert(unsafe { cjgui_internal_renderer_test_captured_pointer_phase(window.testSessionToken(),
                2u32, x, below) }, CJGUI_INTERNAL_RENDERER_OK)
            let _ = window.pumpEventsWithoutRefresh(0u32)
        }
        let forward = controller.sourceViewport.offset()
        @Assert(if (mode == 2) { forward == before } else { forward > before }, true)
        @Assert(controller.sourceViewport.acceptedOffset(), before)
        let forwardGeneration = controller.sourceViewport.requestGeneration()
        if (mode == 3) {
            @Assert(window.refresh(), true)
            @Assert(controller.sourceViewport.acceptedOffset(), forward)
            // Finish the actual accepted-scene capture continuation before a
            // new original UPDATE. This emits no extra pointer or text input.
            sourceHandoffPump(window)
            @Assert(sourceHandoffNativeGesture(window), gesture)
        }
        let phase: UInt32 = if (mode == 4) { 3u32 } else if (mode == 5) { 4u32 } else { 2u32 }
        let nextPoint = if (mode == 1 || mode >= 4) { below } else { above }
        @Assert(unsafe { cjgui_internal_renderer_test_captured_pointer_phase(window.testSessionToken(),
            phase, x, nextPoint) }, CJGUI_INTERNAL_RENDERER_OK)
        let _ = window.pumpEventsWithoutRefresh(0u32)
        let choice = authority.sourceSelectionSnapshot()
        println("SOURCE_DIRECTION_COUNTER mode=${mode} phase=reverse_before_present gesture=${gesture} " +
            "generation=${forwardGeneration} forward=${forward} accepted=${controller.sourceViewport.acceptedOffset()} " +
            "choice=${choice.anchorByte}:${choice.focusByte} updates=${controller.pointerUpdateAdmissions}")
        @Assert(sourceHandoffNativeGesture(window), if (mode >= 4) { 0u64 } else { gesture })
        @Assert(owner.writeCalls, 0)
        @Assert(window.testHoldNextComposablePresent(), true)
        @Assert(window.refresh(), false)
        @Assert(controller.sourceViewport.acceptedOffset(), if (mode == 3) { forward } else { before })
        @Assert(window.testResolvePendingComposablePresent(), true)
        let _ = window.refreshIfNeeded()
        println("SOURCE_DIRECTION_COUNTER mode=${mode} phase=after_original_candidate accepted=${controller.sourceViewport.acceptedOffset()} " +
            "forward=${forward} before=${before} source=${choice.anchorByte}:${choice.focusByte}")
        // A request whose unpresented direction was overtaken by a real
        // reverse UPDATE must not publish that old positive displacement.
        if (mode == 0 || mode == 2) {
            @Assert(controller.sourceViewport.acceptedOffset() <= before, true)
        } else if (mode == 1) {
            @Assert(controller.sourceViewport.acceptedOffset(), forward)
        } else if (mode == 3) {
            // An already presented displacement remains real. The next
            // original point is hit against that accepted viewport.
            @Assert(controller.sourceViewport.acceptedOffset() <= forward, true)
        } else {
            @Assert(window.pointerCaptureActiveForTest(), false)
            @Assert(owner.writeCalls, 0)
        }
    } finally { window.close() }
}

@Test
func sourceHandoffReverseBeforeForwardViewportPresentation(): Unit { sourceHandoffDirectionScenario(0) }
@Test
func sourceHandoffDirectionSameSideKeepsOriginalRequest(): Unit { sourceHandoffDirectionScenario(1) }
@Test
func sourceHandoffDirectionReverseWithoutPendingRequest(): Unit { sourceHandoffDirectionScenario(2) }
@Test
func sourceHandoffDirectionReverseAfterActualPresentation(): Unit { sourceHandoffDirectionScenario(3) }
@Test
func sourceHandoffDirectionOriginalUpStopsCapture(): Unit { sourceHandoffDirectionScenario(4) }
@Test
func sourceHandoffDirectionOriginalCancelStopsCapture(): Unit { sourceHandoffDirectionScenario(5) }

@Test
func sourceHandoffRepeatMappedRestoreAfterPassiveOriginKeepsRealBeginGesture(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "first line\nsecond source row\n".toArray()
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    controller.scrollFixture = true
    controller.selectionDocumentId = "test-authority"
    controller.requireCompletion = true
    controller.useSelectionSubmissionForPointer = true
    controller.useSourceSelectionSubmissionForPointer = true
    let bindingA = CjguiComposableUiScrollOriginBinding("source-document", owner.ver,
        "source-map-v1", "origin-A")
    @Assert(controller.sourceViewport.stageCoordinateOrigin(bindingA), "scroll_origin_initial")
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "source-repeat-origin", authority, authority,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(controller.sourceViewport.acceptedCoordinateOrigin().getOrThrow().layoutOrigin, "origin-A")

        // This is the native TEST helper for the production pointer-begin
        // producer, not a queued synthetic kind-33 selection event.
        let beginPoint = sourceHandoffAcceptedPoint(window, 8003, 8803)
        @Assert(beginPoint[0], true)
        @Assert(unsafe { cjgui_internal_renderer_test_begin_composable_pointer(window.testSessionToken(),
            8003u64, Float64(beginPoint[1]), Float64(beginPoint[2])) }, CJGUI_INTERNAL_RENDERER_OK)
        let gesture = sourceHandoffNativeGesture(window)
        @Assert(gesture > 0u64, true)
        var beginTurns = 0
        while (controller.completionCount == 0 && beginTurns < 12) {
            sourceHandoffPump(window)
            beginTurns += 1
        }
        @Assert(controller.pointerBeginAdmissions, 1)
        @Assert(controller.pointerBeginPublishes, 1)
        @Assert(controller.completionCount > 0, true)
        @Assert(window.pointerCaptureActiveForTest(), true)
        @Assert(sourceHandoffNativeGesture(window), gesture)
        let beginReceipt = controller.completion.getOrThrow()
        @Assert(window.installedSelectionCompletion().getOrThrow().transferId, beginReceipt.transferId)
        @Assert(beginReceipt.targetNodeId, 8003)
        @Assert(beginReceipt.sourceOwnerVersion, owner.ver)
        @Assert(beginReceipt.sourceSelection.documentId, controller.selectionDocumentId)
        let directedChoice = beginReceipt.sourceSelection

        // Freeze the passive ticket from the actual accepted ScrollArea/text
        // geometry, then accept one coordinate-origin change with that ticket.
        let originTicket = window.freezeScrollOriginAnchor(controller.sourceViewport, 8003,
            directedChoice.focusByte, "source-selection", bindingA).getOrThrow()
        let bindingB = CjguiComposableUiScrollOriginBinding("source-document", owner.ver,
            "source-map-v1", "origin-B")
        @Assert(controller.sourceViewport.stageCoordinateOrigin(bindingB, anchor: Some(originTicket),
            targetNodeId: 8003, targetLocalByte: directedChoice.focusByte), "scroll_origin_anchor_staged")
        controller.revision += 1
        @Assert(window.refresh(), true)
        // The accepted scene first receives the continuation offer, then the
        // next owner turn completes it into the new native capture segment.
        sourceHandoffPump(window)
        sourceHandoffPump(window)
        var handoffTurns = 0
        while (controller.sourceViewport.acceptedCoordinateOrigin().getOrThrow().layoutOrigin != "origin-B" &&
            handoffTurns < 12) {
            sourceHandoffPump(window)
            handoffTurns += 1
        }
        @Assert(controller.sourceViewport.acceptedCoordinateOrigin().getOrThrow().layoutOrigin, "origin-B")
        @Assert(controller.sourceViewport.pendingOriginAnchor().isNone(), true)
        @Assert(window.pointerCaptureActiveForTest(), true)
        @Assert(sourceHandoffNativeGesture(window), gesture)
        @Assert(controller.pointerBeginAdmissions, 1)
        @Assert(controller.pointerUpdateAdmissions, 0)
        @Assert(controller.pointerEndAdmissions, 0)
        let afterHandoff = sourceHandoffAcceptedPoint(window, 8003, 8803)
        @Assert(afterHandoff[0], true)
        let acceptedOffset = controller.sourceViewport.acceptedOffset()
        let acceptedOriginOffset = controller.sourceViewport.acceptedOriginOffset()
        let completionBeforeRepeat = controller.completionCount
        println("SOURCE_REPEAT_RESTORE stage=handoff receipt=${beginReceipt.transferId} owner=${beginReceipt.sourceOwnerVersion} " +
            "gesture=${gesture} origin=${bindingA.layoutOrigin}->${bindingB.layoutOrigin} " +
            "begin=${controller.pointerBeginAdmissions} update=${controller.pointerUpdateAdmissions} end=${controller.pointerEndAdmissions}")

        // No pointer event is sent between the accepted passive handoff and
        // this second installation of the exact same directed owner choice.
        // This reaches freezeMacTextRestoreDispatch after continuation
        // completion has retired macTextPointerContinuation.
        let mappedTicket = window.freezeAcceptedSelection(8003).getOrThrow()
        let repeatRestore = window.requestAcceptedSelectionRestore(mappedTicket,
            directedChoice.anchorByte, directedChoice.focusByte,
            beginReceipt.targetSelectionStart16, beginReceipt.targetSelectionEnd16,
            { => }, sourceCoordinatesAreBytes: true)
        @Assert(repeatRestore > 0, true)
        var restoreTurns = 0
        while (window.selectionRestoreState(repeatRestore) == "pending" && restoreTurns < 12) {
            sourceHandoffPump(window)
            restoreTurns += 1
        }
        @Assert(window.selectionRestoreState(repeatRestore), "installed")
        @Assert(controller.completionCount, completionBeforeRepeat + 1)
        let repeatReceipt = controller.completion.getOrThrow()
        // Completion alone does not exercise the accepted-frame capture gate.
        // Publish the consumer's current choice before checking continuation,
        // as the normal product does, without another physical pointer event.
        controller.revision += 1
        @Assert(window.refresh(), true)
        sourceHandoffPump(window)
        @Assert(repeatReceipt.requestId, repeatRestore)
        @Assert(repeatReceipt.transferId != beginReceipt.transferId, true)
        @Assert(repeatReceipt.sourceSelection.anchorByte, directedChoice.anchorByte)
        @Assert(repeatReceipt.sourceSelection.focusByte, directedChoice.focusByte)
        // A real installation reserves its own selection revision even when
        // the directed byte endpoints are unchanged.
        @Assert(repeatReceipt.sourceSelection.revision > directedChoice.revision, true)
        @Assert(repeatReceipt.sourceOwnerVersion, beginReceipt.sourceOwnerVersion)
        @Assert(window.pointerCaptureActiveForTest(), true)
        @Assert(sourceHandoffNativeGesture(window), gesture)
        @Assert(controller.pointerBeginAdmissions, 1)
        @Assert(controller.pointerUpdateAdmissions, 0)
        @Assert(controller.pointerEndAdmissions, 0)
        @Assert(controller.sourceViewport.acceptedOffset(), acceptedOffset)
        @Assert(controller.sourceViewport.acceptedOriginOffset(), acceptedOriginOffset)
        let afterRepeat = sourceHandoffAcceptedPoint(window, 8003, 8803)
        @Assert(afterRepeat[0], afterHandoff[0])
        @Assert(afterRepeat[1], afterHandoff[1])
        @Assert(afterRepeat[2], afterHandoff[2])
        println("SOURCE_REPEAT_RESTORE stage=repeat request=${repeatRestore} receipt=${repeatReceipt.transferId} " +
            "owner=${repeatReceipt.sourceOwnerVersion} gesture=${sourceHandoffNativeGesture(window)} " +
            "origin=${controller.sourceViewport.acceptedOriginOffset()} offset=${controller.sourceViewport.acceptedOffset()}")
        @Assert(owner.text(), "first line\nsecond source row\n")
        @Assert(owner.writeCalls, 0)
    } finally { window.close() }
}

@Test
func selectionTransferDecisionCellIsMonotonicAndCancellationWinsCommit(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "A\nB\n".toArray()
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    controller.requireCompletion = true
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "selection-decision-cell", authority, authority,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.focusAcceptedNodeById(8002), true)
        let sourceReceipt = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.text(), 0, 0)
        @Assert(sourceReceipt > 0, true)
        let receiptDeadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(sourceReceipt) == "pending" &&
            sourceHandoffMonotonicMicros() < receiptDeadline) {
            sourceHandoffPump(window)
        }
        @Assert(sourceHandoffMonotonicMicros() < receiptDeadline, true)
        @Assert(window.selectionRestoreState(sourceReceipt), "installed")
        @Assert(controller.completionCount > 0, true)
        @Assert(controller.completion.getOrThrow().requestId, sourceReceipt)
        let nativeA = sourceHandoffNativeSelection(window)
        @Assert(nativeA[0], CJGUI_INTERNAL_RENDERER_OK)
        @Assert(nativeA[1], 0u32)
        @Assert(nativeA[2], 0u32)

        // Create the cell through the real installed-source path so its A
        // capsule comes from native state and its source receipt, not a test
        // seam that fabricates a completed capture.
        let ticket = window.freezeAcceptedSelection(8003).getOrThrow()
        let capturedTransfer = window.prepareSelectionTransferFromInstalledSource(ticket, 1, 3)
        @Assert(capturedTransfer.isSome(), true)
        let sessionToken = window.testSessionToken()
        let firstId = capturedTransfer.getOrThrow()
        @Assert(firstId > 0u64, true)
        let pending = internalRendererSelectionTransferState(sessionToken, firstId)
        @Assert(pending[0], CJGUI_INTERNAL_RENDERER_OK)
        @Assert(pending[1], CJGUI_SELECTION_TRANSFER_PENDING)
        @Assert(pending[2], 0u8)
        @Assert(pending[3], 2u32)
        @Assert(internalRendererBeginSelectionTransferFinalizing(sessionToken, firstId),
            CJGUI_INTERNAL_RENDERER_OK)

        // A real input producer asks the same decision cell for admission.
        // During Finalizing it must be retained and set cancellation before
        // the native transaction can publish B.
        let retained = internalRendererAdmitSelectionTransferInput(sessionToken, firstId)
        @Assert(retained[0], CJGUI_INTERNAL_RENDERER_OK)
        @Assert(retained[1], CJGUI_SELECTION_INPUT_RETAINED_CANCEL)
        let finalizing = internalRendererSelectionTransferState(sessionToken, firstId)
        @Assert(finalizing[0], CJGUI_INTERNAL_RENDERER_OK)
        @Assert(finalizing[1], CJGUI_SELECTION_TRANSFER_FINALIZING)
        @Assert(finalizing[2], 1u8)
        @Assert(finalizing[3], 2u32)
        @Assert(internalRendererCommitSelectionTransfer(sessionToken, firstId) != CJGUI_INTERNAL_RENDERER_OK, true)
        // Abort cannot finish until the actual A proxy/selection readback has
        // established proof in the decision cell.
        @Assert(internalRendererFinishSelectionTransferAbort(sessionToken, firstId),
            CJGUI_INTERNAL_RENDERER_SCENE_STALE)
        @Assert(internalRendererRestoreSelectionTransferA(sessionToken, firstId), CJGUI_INTERNAL_RENDERER_OK)
        let restoredA = sourceHandoffNativeSelection(window)
        @Assert(restoredA[0], CJGUI_INTERNAL_RENDERER_OK)
        @Assert(restoredA[1], nativeA[1])
        @Assert(restoredA[2], nativeA[2])
        @Assert(owner.text(), "A\nB\n")
        @Assert(owner.writeCalls, 0)
        @Assert(internalRendererFinishSelectionTransferAbort(sessionToken, firstId), CJGUI_INTERNAL_RENDERER_OK)
        let aborted = internalRendererSelectionTransferState(sessionToken, firstId)
        @Assert(aborted[0], CJGUI_INTERNAL_RENDERER_OK)
        @Assert(aborted[1], CJGUI_SELECTION_TRANSFER_ABORTED)
        @Assert(aborted[2], 1u8)
        @Assert(aborted[3], 2u32)
        @Assert(internalRendererReleaseSelectionTransfer(sessionToken, firstId), CJGUI_INTERNAL_RENDERER_OK)
        @Assert(internalRendererReleaseSelectionTransfer(sessionToken, firstId), CJGUI_INTERNAL_RENDERER_OK)

        let (secondStatus, secondId) = internalRendererCreateSelectionTransfer(sessionToken)
        @Assert(secondStatus, CJGUI_INTERNAL_RENDERER_OK)
        @Assert(secondId > firstId, true)
        @Assert(internalRendererPublishSelectionTransferPending(sessionToken, secondId), CJGUI_INTERNAL_RENDERER_OK)
        @Assert(internalRendererBeginSelectionTransferFinalizing(sessionToken, secondId), CJGUI_INTERNAL_RENDERER_OK)
        @Assert(internalRendererCommitSelectionTransfer(sessionToken, secondId), CJGUI_INTERNAL_RENDERER_OK)
        let committed = internalRendererSelectionTransferState(sessionToken, secondId)
        @Assert(committed[0], CJGUI_INTERNAL_RENDERER_OK)
        @Assert(committed[1], CJGUI_SELECTION_TRANSFER_COMMITTED)
        @Assert(committed[2], 0u8)
        @Assert(committed[3], 2u32)
        @Assert(internalRendererFinishSelectionTransferAbort(sessionToken, secondId) != CJGUI_INTERNAL_RENDERER_OK, true)
        @Assert(internalRendererReleaseSelectionTransfer(sessionToken, secondId), CJGUI_INTERNAL_RENDERER_OK)
        @Assert(internalRendererReleaseSelectionTransfer(sessionToken, secondId), CJGUI_INTERNAL_RENDERER_OK)
        @Assert(internalRendererSelectionTransferState(sessionToken, firstId)[0] != CJGUI_INTERNAL_RENDERER_OK, true)
    } finally { window.close() }
}

@Test
func sourceHandoffOwnedRestoreOwnerSnapshotDoesNotWriteBody(): Unit {
    // Native-window installation is exercised by the isolated application
    // launcher fixture. Keep this unit test on the owner-only boundary because
    // cjpm test runs on a managed worker, not AppKit's process main thread.
    let owner = SelectionAuthorityTestOwner()
    owner.body.data = "abcdefghij\n".toArray()
    let original = owner.body.text()
    let before = owner.sourceSelectionSnapshot()
    @Assert(before.anchorByte, 0)
    @Assert(before.focusByte, 0)
    @Assert(before.revision, owner.revision)

    owner.body.bumpVersionOnly()
    @Assert(owner.setSourceSelection(owner.body.ver, 2, 9), true)
    let restored = owner.sourceSelectionSnapshot()
    @Assert(restored.version, owner.body.ver)
    @Assert(restored.anchorByte, 2)
    @Assert(restored.focusByte, 9)
    @Assert(restored.revision > before.revision, true)
    @Assert(owner.body.text(), original)
    @Assert(owner.body.writeCalls, 0)
}

@Test
func sourceHandoffCompletionSurvivesClearedPendingBeforeImmediateInput(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "ABCDE\n".toArray()
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    controller.selectionDocumentId = "test-authority"
    controller.requireCompletion = true
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "completion-input", authority, authority,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.focusAcceptedNodeById(8002), true)
        session.setSelection16(2, 2)
        let request = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.text(), 2, 2)
        @Assert(request > 0, true)
        var turns: Int64 = 0
        while (window.selectionRestoreState(request) == "pending" && turns < 24) {
            sourceHandoffPump(window)
            turns += 1
        }
        @Assert(window.selectionRestoreState(request), "installed")
        @Assert(window.pendingSelectionRestoreId(), -1)
        @Assert(controller.completionCount, 1)
        @Assert(controller.completion.getOrThrow().requestId, request)
        for (text in ["H", "i", "中", "😀"]) {
            @Assert(sourceHandoffInsert(window, 1u32, text), CJGUI_INTERNAL_RENDERER_OK)
            sourceHandoffPump(window)
        }
        sourceHandoffPump(window)
        @Assert(owner.text(), "ABHi中😀CDE\n")
        @Assert(owner.ver, 5)
        @Assert(session.contentVersion(), 5)
        @Assert(controller.selectionChoiceId, 4)
    } finally { window.close() }
}

@Test
func sourceHandoffCompletionAndCapturedInputSettleInSamePumpBatch(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "ABCDE\n".toArray()
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    controller.selectionDocumentId = "test-authority"
    controller.requireCompletion = true
    controller.insertOnCompletion = "H"
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "completion-same-batch", authority, authority,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.focusAcceptedNodeById(8002), true)
        session.setSelection16(2, 2)
        let request = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.text(), 2, 2)
        var turns: Int64 = 0
        while (owner.ver == 1 && turns < 24) { sourceHandoffPump(window); turns += 1 }
        @Assert(controller.completionInsertStatus, CJGUI_INTERNAL_RENDERER_OK)
        // The accepted H starts AUTO id2 in this same pump, superseding the
        // terminal query's one slot. The immutable id1 fact is still id1.
        @Assert(controller.firstCompletion.getOrThrow().requestId, request)
        @Assert(controller.firstCompletion.getOrThrow().sourceOwnerVersion, 1)
        @Assert(controller.completionCount, 2)
        @Assert(controller.completion.getOrThrow().sourceOwnerVersion, 2)
        @Assert(owner.text(), "ABHCDE\n")
        @Assert(owner.writeCalls, 1)
        @Assert(controller.selectionChoiceId, 1)
        sourceHandoffPump(window)
        sourceHandoffPump(window)
        @Assert(owner.writeCalls, 1)
        @Assert(owner.ver, 2)
    } finally { window.close() }
}

@Test
func sourceHandoffCompletionCrossTurnPreparationPublishesBeforeFirstInput(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = Array<Byte>(4096, repeat: 65u8)
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    controller.selectionDocumentId = "test-authority"
    controller.requireCompletion = true
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "completion-prepared", authority, authority,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.focusAcceptedNodeById(8002), true)
        session.setSelection16(5, 10)
        let request = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.text(), 5, 10)
        @Assert(request > 0, true)
        @Assert(controller.completionCount, 0)
        let deadline = sourceHandoffMonotonicMicros() + 5000000u64
        var turns: Int64 = 0
        while (window.selectionRestoreState(request) == "pending" && sourceHandoffMonotonicMicros() < deadline) {
            sourceHandoffPump(window)
            let _ = unsafe { cjgui_internal_renderer_test_wait_for_text_preparation_finished(1u32) }
            turns += 1
        }
        @Assert(turns > 1, true)
        @Assert(window.selectionRestoreState(request), "installed")
        @Assert(controller.completionCount, 1)
        @Assert(window.installedSelectionCompletion().getOrThrow().sourceSelection.anchorByte, 5)
        @Assert(window.installedSelectionCompletion().getOrThrow().sourceSelection.focusByte, 10)
        @Assert(sourceHandoffInsert(window, 1u32, "Z"), CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        @Assert(owner.text(), "AAAAAZ" + String.fromUtf8(Array<Byte>(4086, repeat: 65u8)))
        @Assert(owner.writeCalls, 1)
        @Assert(owner.ver, 2)
        @Assert(window.installedSelectionCompletion().isNone(), true)
        sourceHandoffPump(window)
        @Assert(owner.writeCalls, 1)
    } finally { window.close() }
}

@Test
func initialTextFocusRetainsPreSceneIntentUntilActualInstallReceipt(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "ABCDE🙂\n".toArray()
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "initial-focus-before-scene", authority, authority,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    controller.attach(window, session)
    try {
        window.testSetInitialTextFocusWindowState(true, true, true, true, false)
        @Assert(window.requestInitialOwnedTextFocusRestore(), true)
        @Assert(window.testInitialTextFocusIntentPending(), true)
        @Assert(window.pendingSelectionRestoreId(), -1)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let deadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (controller.completionCount == 0 && sourceHandoffMonotonicMicros() < deadline) {
            sourceHandoffPump(window)
        }
        @Assert(sourceHandoffMonotonicMicros() < deadline, true)
        @Assert(controller.completionCount, 1)
        @Assert(controller.completion.getOrThrow().requestId > 0, true)
        @Assert(controller.completion.getOrThrow().targetNodeId, 8002)
        @Assert(controller.completion.getOrThrow().sourceSelection.version, owner.ver)
        @Assert(window.installedSelectionCompletion().isSome(), true)
        @Assert(window.testInitialTextFocusIntentPending(), false)
        @Assert(owner.writeCalls, 0)
    } finally { window.close() }
}

@Test
func ownerWriteAdmissionRetainsOriginalFirstInstallationBeforeHistoryPublication(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "ABCDE🙂\n".toArray()
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    controller.includeOwnerTextInput = false
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "history-first-install", authority, authority,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    controller.attach(window, session)
    try {
        window.testSetInitialTextFocusWindowState(true, true, true, true, false)
        @Assert(window.requestInitialOwnedTextFocusRestore(), true)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        sourceHandoffPump(window)
        @Assert(window.testInitialTextFocusIntentPending(), true)
        @Assert(window.installedSelectionCompletion().isNone(), true)
        let original = window.admitTextOwnerWrite(None)
        @Assert(original.isReady, false)
        @Assert(original.isWaiting, true)
        @Assert(original.predecessor, 0u64)
        @Assert(window.performTextOwnerSelectionChange({=>
            controller.deferredSelectionPublishes += 1
            return (true, 1, 22)
        }), false)
        @Assert(controller.deferredSelectionPublishes, 0)
        @Assert(window.testInitialTextFocusIntentPending(), true)
        controller.includeOwnerTextInput = true
        controller.revision += 1
        @Assert(window.refresh(), true)
        let deadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (controller.completionCount == 0 && sourceHandoffMonotonicMicros() < deadline) {
            sourceHandoffPump(window)
        }
        @Assert(controller.completionCount, 1)
        @Assert(window.installedSelectionCompletion().getOrThrow().sourceSelection.version, 1)
        @Assert(window.admitTextOwnerWrite(Some(original)).isReady, true)
        @Assert(owner.writeCalls, 0)
        @Assert(controller.deferredSelectionPublishes, 0)
    } finally { window.close() }
}

@Test
func ownerWriteAdmissionVersionJumpUsesActualAAndSameBodyB(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "same saved bytes🙂\n".toArray()
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "history-version-jump", authority, authority,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    controller.attach(window, session)
    try {
        window.testSetInitialTextFocusWindowState(true, true, true, true, false)
        @Assert(window.requestInitialOwnedTextFocusRestore(), true)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let initialDeadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (controller.completionCount == 0 && sourceHandoffMonotonicMicros() < initialDeadline) {
            sourceHandoffPump(window)
        }
        @Assert(controller.completionCount, 1)
        let original = window.installedSelectionCompletion().getOrThrow()
        @Assert(original.sourceSelection.version, 1)
        @Assert(window.admitTextOwnerWrite(None).isReady, true)
        // Component owner callback advances history identity without editing its saved bytes.
        // Actual file recovery is verified separately through the production service/open path.
        @Assert(window.performTextOwnerSelectionChange({=>
            controller.deferredSelectionPublishes += 1
            let before = owner.ver
            owner.ver = 22
            return (true, before, owner.ver)
        }), true)
        let pending = window.admitTextOwnerWrite(None)
        @Assert(pending.isWaiting, true)
        @Assert(pending.predecessor > 0u64, true)
        let deadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (controller.completionCount < 2 && sourceHandoffMonotonicMicros() < deadline) {
            sourceHandoffPump(window)
        }
        @Assert(controller.completionCount, 2)
        let successor = window.installedSelectionCompletion().getOrThrow()
        @Assert(successor.sourceSelection.version, 22)
        @Assert(successor.transferId != original.transferId, true)
        @Assert(window.admitTextOwnerWrite(Some(pending)).isReady, true)
        @Assert(controller.deferredSelectionPublishes, 1)
        @Assert(owner.writeCalls, 0)
        @Assert(owner.text(), "same saved bytes🙂\n")
        sourceHandoffPump(window)
        @Assert(controller.deferredSelectionPublishes, 1)
    } finally { window.close() }
}

@Test
func ownerWriteAdmissionExpiredActualInstallationCannotBecomeBootstrap(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "old installed choice🙂\n".toArray()
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "history-expired-A", authority, authority,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    controller.attach(window, session)
    try {
        window.testSetInitialTextFocusWindowState(true, true, true, true, false)
        @Assert(window.requestInitialOwnedTextFocusRestore(), true)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let deadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (controller.completionCount == 0 && sourceHandoffMonotonicMicros() < deadline) {
            sourceHandoffPump(window)
        }
        @Assert(controller.completionCount, 1)
        @Assert(window.installedSelectionCompletion().isSome(), true)
        // The old failure advanced the owner outside this window's common boundary.
        owner.ver = 22
        @Assert(window.installedSelectionCompletion().isNone(), true)
        @Assert(window.admitTextOwnerWrite(None).isTerminal, true)
        @Assert(window.performTextOwnerSelectionChange({=>
            controller.deferredSelectionPublishes += 1
            return (true, 22, 23)
        }), false)
        @Assert(controller.deferredSelectionPublishes, 0)
        @Assert(owner.ver, 22)
        @Assert(owner.writeCalls, 0)
    } finally { window.close() }
}

@Test
func initialTextFocusWaitsWhileWindowIsInactiveThenUsesSameIntent(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "ABCDE🙂\n".toArray()
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "initial-focus-inactive", authority, authority,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    controller.attach(window, session)
    try {
        window.testSetInitialTextFocusWindowState(false, false, false, true, false)
        @Assert(window.requestInitialOwnedTextFocusRestore(), true)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        var turn: Int64 = 0
        while (turn < 12) {
            sourceHandoffPump(window)
            turn += 1
        }
        @Assert(window.testInitialTextFocusIntentPending(), true)
        @Assert(window.pendingSelectionRestoreId(), -1)
        @Assert(window.testSelectionRestoreAttemptCount(), 0)
        @Assert(controller.completionCount, 0)
        @Assert(window.installedSelectionCompletion().isNone(), true)
        window.testSetInitialTextFocusWindowState(true, true, true, true, false)
        let deadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (controller.completionCount == 0 && sourceHandoffMonotonicMicros() < deadline) {
            sourceHandoffPump(window)
        }
        @Assert(sourceHandoffMonotonicMicros() < deadline, true)
        @Assert(controller.completionCount, 1)
        @Assert(controller.completion.getOrThrow().sourceSelection.version, owner.ver)
        @Assert(window.testInitialTextFocusIntentPending(), false)
    } finally { window.close() }
}

@Test
func initialTextFocusKeepsOneIntentAcrossMissingAcceptedTarget(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "ABCDE🙂\n".toArray()
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    controller.includeOwnerTextInput = false
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "initial-focus-target-late", authority, authority,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    controller.attach(window, session)
    try {
        window.testSetInitialTextFocusWindowState(true, true, true, true, false)
        @Assert(window.requestInitialOwnedTextFocusRestore(), true)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        var turn: Int64 = 0
        while (turn < 12) {
            sourceHandoffPump(window)
            turn += 1
        }
        @Assert(window.testInitialTextFocusIntentPending(), true)
        @Assert(window.pendingSelectionRestoreId(), -1)
        @Assert(window.testSelectionRestoreAttemptCount(), 0)
        @Assert(controller.completionCount, 0)
        controller.includeOwnerTextInput = true
        controller.revision += 1
        @Assert(window.refresh(), true)
        let deadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (controller.completionCount == 0 && sourceHandoffMonotonicMicros() < deadline) {
            sourceHandoffPump(window)
        }
        @Assert(sourceHandoffMonotonicMicros() < deadline, true)
        @Assert(controller.completionCount, 1)
        @Assert(controller.completion.getOrThrow().targetNodeId, 8002)
        @Assert(window.testInitialTextFocusIntentPending(), false)
    } finally { window.close() }
}

@Test
func initialTextFocusYieldsToNewAcceptedUserFocus(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "ABCDE🙂\n".toArray()
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    controller.includeUndoAction = true
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "initial-focus-user-wins", authority, authority,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    controller.attach(window, session)
    try {
        window.testSetInitialTextFocusWindowState(false, false, false, true, false)
        @Assert(window.requestInitialOwnedTextFocusRestore(), true)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.focusAcceptedNodeById(8004), true)
        window.testSetInitialTextFocusWindowState(true, true, true, true, false)
        sourceHandoffPump(window)
        @Assert(window.testInitialTextFocusIntentPending(), false)
        @Assert(window.pendingSelectionRestoreId(), -1)
        @Assert(window.windowProjection().focusedControlId, "undo-action")
        @Assert(controller.completionCount, 0)
        @Assert(window.installedSelectionCompletion().isNone(), true)
    } finally { window.close() }
}

@Test
func initialTextFocusExpiresWithOwnerIdentityAndClose(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "ABCDE🙂\n".toArray()
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "initial-focus-expired", authority, authority,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    controller.attach(window, session)
    @Assert(window.requestInitialOwnedTextFocusRestore(), true)
    owner.data = "replacement".toArray()
    owner.ver += 1
    window.testSetInitialTextFocusWindowState(true, true, true, true, false)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    sourceHandoffPump(window)
    @Assert(window.testInitialTextFocusIntentPending(), false)
    @Assert(controller.completionCount, 0)
    @Assert(window.installedSelectionCompletion().isNone(), true)
    window.close()

    let closedAuthority = SelectionAuthorityTestOwner()
    closedAuthority.body.data = "close-before-first-scene".toArray()
    let closedOwner = closedAuthority.body
    let closedController = SourceHandoffController(closedOwner)
    let closedWindow = sourceHandoffWindow(closedController)
    let closedSession = closedWindow.bindRangeTextSession(8002, "initial-focus-close", closedAuthority,
        closedAuthority, 8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    closedController.attach(closedWindow, closedSession)
    @Assert(closedWindow.requestInitialOwnedTextFocusRestore(), true)
    closedWindow.close()
    @Assert(closedWindow.testInitialTextFocusIntentPending(), false)
    @Assert(closedController.completionCount, 0)
}

@Test
func foregroundOnlyAcceptedVisualOpeningRestoreWaitsForActiveWindow(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "ABCDE🙂\n".toArray()
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "visual-opening-focus-active", authority, authority,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    controller.attach(window, session)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let ticket = window.freezeAcceptedSelection(8003).getOrThrow()
        window.testSetInitialTextFocusWindowState(false, false, false, true, false)
        let published = SourceHandoffBoolBox()
        let id = window.requestAcceptedSelectionRestore(ticket, 0, 0, 0, 0,
            { => published.value = true }, sourceCoordinatesAreBytes: true, foregroundOnly: true)
        @Assert(id > 0, true)
        var turn: Int64 = 0
        while (turn < 12) {
            window.pumpPendingSelectionRestore()
            turn += 1
        }
        @Assert(window.selectionRestoreState(id), "pending")
        @Assert(window.testSelectionRestoreAttemptCount(), 0)
        @Assert(published.value, false)
        @Assert(window.installedSelectionCompletion().isNone(), true)
        window.testSetInitialTextFocusWindowState(true, true, true, true, false)
        let deadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(id) == "pending" && sourceHandoffMonotonicMicros() < deadline) {
            sourceHandoffPump(window)
        }
        @Assert(sourceHandoffMonotonicMicros() < deadline, true)
        @Assert(window.selectionRestoreState(id), "installed")
        @Assert(published.value, true)
        @Assert(window.installedSelectionCompletion().isSome(), true)
        @Assert(owner.writeCalls, 0)
    } finally { window.close() }
}

@Test
func foregroundOnlyAcceptedVisualOpeningRestoreYieldsToNewFocus(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "ABCDE🙂\n".toArray()
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    controller.includeUndoAction = true
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "visual-opening-focus-user-wins", authority, authority,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    controller.attach(window, session)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let ticket = window.freezeAcceptedSelection(8003).getOrThrow()
        window.testSetInitialTextFocusWindowState(false, false, false, true, false)
        let published = SourceHandoffBoolBox()
        let id = window.requestAcceptedSelectionRestore(ticket, 0, 0, 0, 0,
            { => published.value = true }, sourceCoordinatesAreBytes: true, foregroundOnly: true)
        @Assert(id > 0, true)
        @Assert(window.focusAcceptedNodeById(8004), true)
        window.testSetInitialTextFocusWindowState(true, true, true, true, false)
        window.pumpPendingSelectionRestore()
        @Assert(window.selectionRestoreState(id), "human_selection_superseded")
        @Assert(published.value, false)
        @Assert(window.windowProjection().focusedControlId, "undo-action")
        @Assert(window.installedSelectionCompletion().isNone(), true)
    } finally { window.close() }
}

@Test
func liveWindowSessionIdentityExistsBeforeAcceptedFrameAndRetiresOnClose(): Unit {
    let owner = FakeTextOwner("live-generation-before-frame🙂\n")
    let controller = SourceHandoffController(owner)
    controller.holdFirstPresentForLifecycle = true
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "live-session-before-first-frame", owner, owner,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    controller.attach(window, session)
    @Assert(window.liveWindowSessionIdentity().isNone(), true)
    try {
        @Assert(window.start(), true)
        @Assert(controller.lifecyclePresentHeld, true)
        @Assert(window.isOpen(), true)
        @Assert(window.windowProgress().sessionIdentity, "")
        @Assert(window.windowProjection().isActive, false)
        @Assert(window.windowProjection().sessionIdentity, "unavailable")
        let first = window.liveWindowSessionIdentity().getOrThrow()
        @Assert(first != "", true)
        let status = window.nativeStatus()
        @Assert(window.liveWindowSessionIdentity().getOrThrow(), first)
        @Assert(window.nativeStatus(), status)
        @Assert(window.windowProjection().acceptedSceneVersion, 0)
        @Assert(owner.writeCalls, 0)
        @Assert(window.testResolvePendingComposablePresent(), true)
        window.close()
        @Assert(window.isOpen(), false)
        @Assert(window.liveWindowSessionIdentity().isNone(), true)
        @Assert(window.start(), true)
        let second = window.liveWindowSessionIdentity().getOrThrow()
        @Assert(second != first, true)
        @Assert(owner.writeCalls, 0)
    } finally {
        let _ = window.testResolvePendingComposablePresent()
        window.close()
    }
    @Assert(window.liveWindowSessionIdentity().isNone(), true)
}

@Test
func ownerWriteAdmissionSameOwnerMirrorExpiryHasOriginalActualReceipt(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = Array<UInt8>(4096, repeat: 97)
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    controller.useBoundMirrorBody = true
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "passive-mirror-diagnostic", authority, authority,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, materializeLimit: 512)
    controller.attach(window, session)
    try {
        window.testSetInitialTextFocusWindowState(true, true, true, true, false)
        @Assert(window.requestInitialOwnedTextFocusRestore(), true)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let deadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (controller.completionCount == 0 && sourceHandoffMonotonicMicros() < deadline) {
            sourceHandoffPump(window)
        }
        @Assert(controller.completionCount, 1)
        let actualA = window.installedSelectionCompletion().getOrThrow()
        let original = session.sourceSelectionSnapshot().getOrThrow()
        let originalSemantic = session.freezeSelectionTicket()
        @Assert(window.admitTextOwnerWrite(None).isReady, true)
        // A paint-only scene refresh must not retire the actual receipt.
        controller.revision += 1
        @Assert(window.refresh(), true)
        sourceHandoffPump(window)
        @Assert(window.installedSelectionCompletion().getOrThrow().transferId, actualA.transferId)
        @Assert(session.freezeSelectionTicket().mirrorRevision, originalSemantic.mirrorRevision)
        // Real bounded materialization changes the mirror, without editing owner/selection.
        @Assert(session.revealByte(2048), true)
        let moved = session.mirrorSnapshot()
        @Assert(moved.startByte > 0, true)
        @Assert(moved.text, actualA.targetBody)
        let now = session.sourceSelectionSnapshot().getOrThrow()
        @Assert(now.version, original.version)
        @Assert(now.revision, original.revision)
        @Assert(now.anchorByte, original.anchorByte)
        @Assert(now.focusByte, original.focusByte)
        @Assert(actualA.firstMismatch(now, session.freezeSelectionTicket(), actualA.targetBindingEpoch,
            actualA.windowSession), "mirror")
        @Assert(window.installedSelectionCompletion().isNone(), true)
        let refused = window.admitTextOwnerWrite(None)
        @Assert(refused.isTerminal, true)
        @Assert(refused.reason, "owner_installed_source_unavailable")
        @Assert(owner.ver, 1)
        @Assert(owner.writeCalls, 0)
    } finally { window.close() }
}


@Test
func readOnlyPresentationKeepsActualSelectionReceiptAcrossPermissionChange(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "ABCDE🙂\n".toArray()
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    controller.previewReadOnly = true
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "readonly-presentation-lifetime", authority, authority,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    controller.attach(window, session)
    try {
        @Assert(controller.buildUi().children()[1].isReadOnly, true)
        window.testSetInitialTextFocusWindowState(true, true, true, true, false)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let firstTicket = window.freezeAcceptedSelection(8003).getOrThrow()
        @Assert(window.requestAcceptedSelectionRestore(firstTicket, 0, 0, 0, 0, { => },
            sourceCoordinatesAreBytes: true, foregroundOnly: true) > 0, true)
        let deadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (controller.completionCount == 0 && sourceHandoffMonotonicMicros() < deadline) {
            sourceHandoffPump(window)
        }
        @Assert(controller.completionCount, 1)
        let a = window.installedSelectionCompletion().getOrThrow()
        @Assert(a.targetNodeId, 8003)
        @Assert(unsafe { cjgui_internal_renderer_test_readonly_proxy_mutations(window.testSessionToken()) }, 0)
        @Assert(window.admitTextOwnerWrite(None).isReady, true)
        controller.revision += 1
        @Assert(window.refresh(), true)
        sourceHandoffPump(window)
        @Assert(window.installedSelectionCompletion().getOrThrow().transferId, a.transferId)
        controller.previewReadOnly = false
        controller.revision += 1
        @Assert(window.refresh(), true)
        sourceHandoffPump(window)
        @Assert(window.installedSelectionCompletion().getOrThrow().transferId, a.transferId)
        controller.previewReadOnly = true
        controller.revision += 1
        @Assert(window.refresh(), true)
        sourceHandoffPump(window)
        @Assert(window.installedSelectionCompletion().getOrThrow().transferId, a.transferId)
        @Assert(unsafe { cjgui_internal_renderer_test_readonly_proxy_mutations(window.testSessionToken()) }, 0)
        controller.previewReadOnly = false
        controller.revision += 1
        @Assert(window.refresh(), true)
        sourceHandoffPump(window)
        @Assert(window.installedSelectionCompletion().getOrThrow().transferId, a.transferId)
        @Assert(owner.ver, 1)
        @Assert(owner.writeCalls, 0)
    } finally { window.close() }
}


@Test
func readOnlyPresentationActualDisableStillRetiresSelectionReceipt(): Unit {
    for (disable in [true, false]) {
        let authority = SelectionAuthorityTestOwner()
        authority.body.data = "ABCDE🙂\n".toArray()
        let controller = SourceHandoffController(authority.body)
        controller.previewReadOnly = true
        let window = sourceHandoffWindow(controller)
        let session = window.bindRangeTextSession(8002, "readonly-real-disable", authority, authority,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        try {
            window.testSetInitialTextFocusWindowState(true, true, true, true, false)
                @Assert(window.start(), true)
            @Assert(window.refresh(), true)
            let firstTicket = window.freezeAcceptedSelection(8003).getOrThrow()
            @Assert(window.requestAcceptedSelectionRestore(firstTicket, 0, 0, 0, 0, { => },
                sourceCoordinatesAreBytes: true, foregroundOnly: true) > 0, true)
            let deadline = sourceHandoffMonotonicMicros() + 5000000u64
            while (controller.completionCount == 0 && sourceHandoffMonotonicMicros() < deadline) {
                sourceHandoffPump(window)
            }
            @Assert(window.installedSelectionCompletion().isSome(), true)
            if (disable) { controller.previewEnabled = false }
            else { controller.previewPointerInteractive = false }
            controller.revision += 1
            @Assert(window.refresh(), true)
            sourceHandoffPump(window)
            @Assert(window.installedSelectionCompletion().isNone(), true)
            @Assert(authority.body.ver, 1)
            @Assert(authority.body.writeCalls, 0)
        } finally { window.close() }
        @Assert(window.installedSelectionCompletion().isNone(), true)
    }
}


@Test
func readOnlyPresentationFreshMutationsDoNotEnterFinalizingFifo(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "ABCDE🙂\n".toArray()
    let controller = SourceHandoffController(authority.body)
    controller.previewReadOnly = true
    controller.requireCompletion = true
    controller.selectionDocumentId = "test-authority"
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "readonly-no-replay", authority, authority,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    controller.attach(window, session)
    try {
        window.testSetInitialTextFocusWindowState(true, true, true, true, false)
        @Assert(window.start(), true)
        let ticket = window.freezeAcceptedSelection(8003).getOrThrow()
        let id = window.requestAcceptedSelectionRestore(ticket, 0, 0, 0, 0, { => },
            sourceCoordinatesAreBytes: true, foregroundOnly: true)
        let deadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(id) == "pending" && sourceHandoffMonotonicMicros() < deadline) {
            sourceHandoffPump(window)
        }
        @Assert(window.selectionRestoreState(id), "installed")
        let actualA = window.installedSelectionCompletion().getOrThrow()
        let original = window.freezeAcceptedSelection(8003).getOrThrow()
        let transfer = window.prepareSelectionTransferFromInstalledSource(original, 1, 3).getOrThrow()
        let token = window.testSessionToken()
        @Assert(internalRendererBeginSelectionTransferFinalizing(token, transfer), 0)
        @Assert(unsafe { cjgui_internal_renderer_test_readonly_proxy_mutations(token) }, 0)
        let state = internalRendererSelectionTransferState(token, transfer)
        @Assert(state[1], CJGUI_SELECTION_TRANSFER_FINALIZING)
        @Assert(state[2], 0u8)
        @Assert(internalRendererRestoreSelectionTransferA(token, transfer), 0)
        @Assert(internalRendererFinishSelectionTransferAbort(token, transfer), 0)
        @Assert(internalRendererReleaseSelectionTransfer(token, transfer), 0)
        controller.previewReadOnly = false
        controller.revision += 1
        @Assert(window.refresh(), true)
        sourceHandoffPump(window)
        @Assert(window.installedSelectionCompletion().getOrThrow().transferId, actualA.transferId)
        @Assert(authority.body.ver, 1)
        @Assert(authority.body.writeCalls, 0)
        @Assert(authority.body.text(), "ABCDE🙂\n")
        // One new native input producer uses the same real A after permission returns.
        // The earlier forbidden producers remain absent; do not re-send them.
        let freshInput = unsafe { LibC.mallocCString("a") }
        try (resource = freshInput.asResource()) {
            @Assert(unsafe { cjgui_internal_renderer_test_insert_actual_composable_proxy(
                token, resource.value) }, 0)
        }
        let inputDeadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (authority.body.writeCalls == 0 && sourceHandoffMonotonicMicros() < inputDeadline) {
            sourceHandoffPump(window)
        }
        @Assert(authority.body.writeCalls, 1)
        @Assert(authority.body.ver, 2)
        @Assert(authority.body.text(), "aABCDE🙂\n")
    } finally { window.close() }
}

@Test
func readOnlyPresentationActualPointerSelectionRemainsInteractive(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789\n".toArray()
    let controller = SourceHandoffController(authority.body)
    controller.previewReadOnly = true
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "readonly-pointer-selection", authority, authority,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    controller.attach(window, session)
    try {
        window.testSetInitialTextFocusWindowState(true, true, true, true, false)
        @Assert(window.start(), true)
        let ticket = window.freezeAcceptedSelection(8003).getOrThrow()
        let id = window.requestAcceptedSelectionRestore(ticket, 0, 0, 0, 0, { => },
            sourceCoordinatesAreBytes: true, foregroundOnly: true)
        let deadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(id) == "pending" && sourceHandoffMonotonicMicros() < deadline) {
            sourceHandoffPump(window)
        }
        @Assert(window.selectionRestoreState(id), "installed")
        let (ready, x, y) = sourceHandoffTextPoint(window, 8003, 8803, 0.1)
        @Assert(ready, true)
        @Assert(sourceHandoffSendMouse(window, 1u32, x, y), 0)
        sourceHandoffPump(window)
        @Assert(controller.pointerBeginAdmissions, 1)
        let (_, finishX, finishY) = sourceHandoffTextPoint(window, 8003, 8803, 0.3)
        @Assert(sourceHandoffSendMouse(window, 2u32, finishX, finishY), 0)
        sourceHandoffPump(window)
        @Assert(controller.pointerUpdateAdmissions, 1)
        @Assert(sourceHandoffSendMouse(window, 3u32, finishX, finishY), 0)
        sourceHandoffPump(window)
        @Assert(controller.pointerEndAdmissions, 1)
        @Assert(controller.previewSelectionCommits, 3)
        let selected = session.sourceSelectionSnapshot().getOrThrow()
        @Assert(selected.anchorByte != selected.focusByte, true)
        @Assert(authority.body.ver, 1)
        @Assert(authority.body.writeCalls, 0)
    } finally { window.close() }
}

// Admission must not create its own 4ms install budget after the common round
// has no allowance. Pending keeps A and the original selection ticket.
private class ShortSelectionAdmissionTestClock { var value: Int64 = 1000000 }

@Test
func shortSelectionSubmissionRetainsBeforeOwnerReservationAtBudgetBoundary(): Unit {
    let owner = SelectionAuthorityTestOwner()
    owner.body.data = "ABCDE\n".toArray()
    let controller = SourceHandoffController(owner.body)
    let window = sourceHandoffWindow(controller)
    let budget = CjguiOwnerTurnBudget()
    try {
        let session = window.bindRangeTextSession(8002, "short-original-budget", owner, owner,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.focusAcceptedNodeById(8002), true)
        let restore = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.body.text(), 0, 0)
        let until = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(restore) == "pending" && sourceHandoffMonotonicMicros() < until) {
            sourceHandoffPump(window)
        }
        @Assert(window.selectionRestoreState(restore), "installed")
        let before = owner.sourceSelectionSnapshot()
        let ticket = window.freezeAcceptedSelection(8003).getOrThrow()
        window.useOwnerTurnBudget(budget)
        let clock = ShortSelectionAdmissionTestClock()
        budget.testUseClock({ => clock.value })
        @Assert(budget.begin(), true)
        clock.value += 16000000
        let submission = window.submitAcceptedSourceSelection(ticket, 0, 6, 0, 6,
            { => controller.previewSelectionCommits += 1 })
        let id = match (submission) {
            case CjguiSelectionSubmission.Retained(value) => value
            case _ => -1
        }
        @Assert(id > 0, true)
        @Assert(controller.previewSelectionCommits, 0)
        @Assert(owner.sourceSelectionSnapshot().revision, before.revision)
        @Assert(owner.sourceSelectionSnapshot().anchorByte, before.anchorByte)
        @Assert(owner.sourceSelectionSnapshot().focusByte, before.focusByte)
        @Assert(owner.body.writeCalls, 0)
        budget.end()
        let next = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(id) != "installed" && sourceHandoffMonotonicMicros() < next) {
            window.pumpPendingSelectionRestore()
        }
        @Assert(window.selectionRestoreState(id), "installed")
        @Assert(controller.previewSelectionCommits, 1)
        @Assert(owner.sourceSelectionSnapshot().anchorByte, 0)
        @Assert(owner.sourceSelectionSnapshot().focusByte, 6)
        @Assert(owner.body.writeCalls, 0)
    } finally { budget.end(); window.close() }
}

@Test
func selectionPendingDecisionRetainsOneOriginalOwnerReservation(): Unit {
    let owner = SelectionAuthorityTestOwner()
    owner.body.data = "ABCDE\n".toArray()
    let controller = SourceHandoffController(owner.body)
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "pending-original-reservation", owner, owner,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.focusAcceptedNodeById(8002), true)
        let initial = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.body.text(), 0, 0)
        let until = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(initial) == "pending" && sourceHandoffMonotonicMicros() < until) {
            sourceHandoffPump(window)
        }
        @Assert(window.selectionRestoreState(initial), "installed")
        let before = owner.sourceSelectionSnapshot()
        let nextRevision = owner.nextRevision
        let ticket = window.freezeAcceptedSelection(8003).getOrThrow()
        @Assert(unsafe { cjgui_internal_renderer_test_selection_finalizing_pending_once(
            window.testSessionToken(), 1u32) }, 0)
        let submission = window.submitAcceptedSourceSelection(ticket, 0, 6, 0, 6,
            { => controller.previewSelectionCommits += 1 })
        let id = match (submission) {
            case CjguiSelectionSubmission.Retained(value) => value
            case _ => -1
        }
        @Assert(id > 0, true)
        @Assert(unsafe { cjgui_internal_renderer_test_selection_finalizing_pending_once(
            window.testSessionToken(), 2u32) }, 1)
        @Assert(owner.nextRevision, nextRevision + 1)
        @Assert(owner.port.getOrThrow().state(), 1)
        @Assert(owner.sourceSelectionSnapshot().revision, before.revision)
        @Assert(owner.sourceSelectionSnapshot().anchorByte, before.anchorByte)
        @Assert(owner.sourceSelectionSnapshot().focusByte, before.focusByte)
        @Assert(controller.previewSelectionCommits, 0)
        @Assert(owner.body.writeCalls, 0)
        window.pumpPendingSelectionRestore()
        @Assert(window.selectionRestoreState(id), "installed")
        @Assert(owner.nextRevision, nextRevision + 1)
        @Assert(owner.sourceSelectionSnapshot().revision, nextRevision)
        @Assert(owner.sourceSelectionSnapshot().anchorByte, 0)
        @Assert(owner.sourceSelectionSnapshot().focusByte, 6)
        @Assert(controller.previewSelectionCommits, 1)
        window.pumpPendingSelectionRestore()
        @Assert(controller.previewSelectionCommits, 1)
        @Assert(owner.nextRevision, nextRevision + 1)
        @Assert(owner.body.writeCalls, 0)
    } finally { window.close() }
}

@Test
func selectionPendingDecisionSameValueNewChoiceRejectsOriginalReservation(): Unit {
    let owner = SelectionAuthorityTestOwner()
    owner.body.data = "ABCDE\n".toArray()
    let controller = SourceHandoffController(owner.body)
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "pending-original-reservation", owner, owner,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.focusAcceptedNodeById(8002), true)
        let initial = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.body.text(), 0, 0)
        let until = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(initial) == "pending" && sourceHandoffMonotonicMicros() < until) {
            sourceHandoffPump(window)
        }
        @Assert(window.selectionRestoreState(initial), "installed")
        let before = owner.sourceSelectionSnapshot()
        let nextRevision = owner.nextRevision
        let ticket = window.freezeAcceptedSelection(8003).getOrThrow()
        @Assert(unsafe { cjgui_internal_renderer_test_selection_finalizing_pending_once(
            window.testSessionToken(), 1u32) }, 0)
        let submission = window.submitAcceptedSourceSelection(ticket, 0, 6, 0, 6,
            { => controller.previewSelectionCommits += 1 })
        let id = match (submission) {
            case CjguiSelectionSubmission.Retained(value) => value
            case _ => -1
        }
        @Assert(id > 0, true)
        @Assert(unsafe { cjgui_internal_renderer_test_selection_finalizing_pending_once(
            window.testSessionToken(), 2u32) }, 1)
        @Assert(owner.nextRevision, nextRevision + 1)
        @Assert(owner.port.getOrThrow().state(), 1)
        @Assert(owner.sourceSelectionSnapshot().revision, before.revision)
        @Assert(owner.sourceSelectionSnapshot().anchorByte, before.anchorByte)
        @Assert(owner.sourceSelectionSnapshot().focusByte, before.focusByte)
        @Assert(controller.previewSelectionCommits, 0)
        @Assert(owner.body.writeCalls, 0)
        @Assert(owner.setSourceSelection(owner.rangeTextVersion(), before.anchorByte, before.focusByte), true)
        window.pumpPendingSelectionRestore()
        @Assert(window.selectionRestoreState(id), "identity_superseded")
        @Assert(owner.port.isNone(), true)
        @Assert(owner.nextRevision, nextRevision + 2)
        @Assert(owner.sourceSelectionSnapshot().revision, nextRevision + 1)
        @Assert(owner.sourceSelectionSnapshot().anchorByte, before.anchorByte)
        @Assert(owner.sourceSelectionSnapshot().focusByte, before.focusByte)
        @Assert(controller.previewSelectionCommits, 0)
        @Assert(owner.body.writeCalls, 0)
    } finally { window.close() }
}

@Test
func selectionPendingDecisionCloseFoldsOriginalReservationBeforeCellRelease(): Unit {
    let owner = SelectionAuthorityTestOwner()
    owner.body.data = "ABCDE\n".toArray()
    let controller = SourceHandoffController(owner.body)
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "pending-original-reservation", owner, owner,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.focusAcceptedNodeById(8002), true)
        let initial = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.body.text(), 0, 0)
        let until = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(initial) == "pending" && sourceHandoffMonotonicMicros() < until) {
            sourceHandoffPump(window)
        }
        @Assert(window.selectionRestoreState(initial), "installed")
        let before = owner.sourceSelectionSnapshot()
        let nextRevision = owner.nextRevision
        let ticket = window.freezeAcceptedSelection(8003).getOrThrow()
        @Assert(unsafe { cjgui_internal_renderer_test_selection_finalizing_pending_once(
            window.testSessionToken(), 1u32) }, 0)
        let submission = window.submitAcceptedSourceSelection(ticket, 0, 6, 0, 6,
            { => controller.previewSelectionCommits += 1 })
        let id = match (submission) {
            case CjguiSelectionSubmission.Retained(value) => value
            case _ => -1
        }
        @Assert(id > 0, true)
        @Assert(unsafe { cjgui_internal_renderer_test_selection_finalizing_pending_once(
            window.testSessionToken(), 2u32) }, 1)
        @Assert(owner.nextRevision, nextRevision + 1)
        @Assert(owner.port.getOrThrow().state(), 1)
        @Assert(owner.sourceSelectionSnapshot().revision, before.revision)
        @Assert(owner.sourceSelectionSnapshot().anchorByte, before.anchorByte)
        @Assert(owner.sourceSelectionSnapshot().focusByte, before.focusByte)
        @Assert(controller.previewSelectionCommits, 0)
        @Assert(owner.body.writeCalls, 0)
        window.close()
        @Assert(window.isOpen(), false)
        @Assert(window.selectionRestoreState(id), "window_closed")
        @Assert(owner.port.isNone(), true)
        @Assert(owner.nextRevision, nextRevision + 1)
        @Assert(owner.sourceSelectionSnapshot().revision, before.revision)
        @Assert(owner.sourceSelectionSnapshot().anchorByte, before.anchorByte)
        @Assert(owner.sourceSelectionSnapshot().focusByte, before.focusByte)
        @Assert(controller.previewSelectionCommits, 0)
        @Assert(owner.body.writeCalls, 0)
    } finally { window.close() }
}

// A real presentation key leaves its dispatch, then another accepted UI pass
// happens before the original source move. The following original text must
// remain ordered behind this same key until its actual installed B confirms.
@Test
func sourceHandoffDeferredSourceArrowDrainsOriginalHeldTextExactlyOnce(): Unit {
    sourceHandoffDeferredSourceArrow(false)
}

@Test
func sourceHandoffDeferredSourceArrowAckPendingRetainsHeadAndOnlyConfirmsOnce(): Unit {
    sourceHandoffDeferredSourceArrow(true)
}

@Test
func sourceHandoffDeferredSourceArrowRightUsesLargerEndpoint(): Unit {
    sourceHandoffDeferredSourceArrow(false, forward: true)
}
@Test
func sourceHandoffDeferredSourceArrowReversedLeftUsesSmallerEndpoint(): Unit {
    sourceHandoffDeferredSourceArrow(false, reverse: true)
}
@Test
func sourceHandoffDeferredSourceArrowReversedRightUsesLargerEndpoint(): Unit {
    sourceHandoffDeferredSourceArrow(false, forward: true, reverse: true)
}
@Test
func sourceHandoffDeferredSourceArrowRejectsOldOwnerBeforeCommit(): Unit {
    sourceHandoffDeferredSourceArrow(false, rejectOwner: true)
}
@Test
func sourceHandoffDeferredSourceArrowClosesWithOutstandingAcceptedTargetPresent(): Unit {
    sourceHandoffDeferredSourceArrow(false, closeBeforeTarget: true)
}

@Test
func sourceHandoffDeferredSourceArrowRejectedAckRecoversWithoutResubmittingB(): Unit {
    sourceHandoffDeferredSourceArrow(true, rejectAck: true)
}

private func sourceHandoffDeferredSourceArrow(holdAck: Bool, forward!: Bool = false,
    reverse!: Bool = false, rejectOwner!: Bool = false, closeBeforeTarget!: Bool = false,
    rejectAck!: Bool = false): Unit {
    let sawPendingHead = SourceHandoffBoolBox()
    let owner = SelectionAuthorityTestOwner()
    let original = owner.body.text()
    let controller = SourceHandoffController(owner.body)
    controller.requireCompletion = true
    controller.selectionDocumentId = "test-authority"
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "deferred-source-arrow", owner, owner,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let initial = window.freezeAcceptedSelection(8003).getOrThrow()
        let initialAnchor = if (reverse) { Int64(original.size) } else { 0 }
        let initialFocus = if (reverse) { 0 } else { Int64(original.size) }
        let restore = window.requestAcceptedSelectionRestore(initial, initialAnchor, initialFocus,
            0, cjguiUtf16Length(original), {=>}, sourceCoordinatesAreBytes: true)
        let deadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(restore) == "pending" && sourceHandoffMonotonicMicros() < deadline) {
            sourceHandoffPump(window)
        }
        @Assert(window.selectionRestoreState(restore), "installed")
        @Assert(owner.sourceSelectionSnapshot().anchorByte, initialAnchor)
        @Assert(owner.sourceSelectionSnapshot().focusByte, initialFocus)
        controller.retainOriginalArrow = true
        var focused = 0u64
        @Assert(unsafe { cjgui_internal_renderer_test_send_composable_key(window.testSessionToken(),
            if (forward) { 124u16 } else { 123u16 }, 0u64, inout focused) }, CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        @Assert(controller.originalArrowSequence > 0u64, true)
        @Assert(window.pendingVisualInputIntent().isSome(), true)
        if (closeBeforeTarget) {
            @Assert(window.testHoldNextComposablePresent(), true)
            controller.revision += 1
            @Assert(window.refreshIfNeeded(), false)
            window.close()
            @Assert(window.isOpen(), true)
            let _ = window.testResolvePendingComposablePresent()
            window.close()
            @Assert(window.isOpen(), false)
            @Assert(owner.body.text(), original)
            @Assert(owner.body.writeCalls, 0)
            return
        }
        controller.revision += 1
        @Assert(window.refreshIfNeeded(), true)
        if (rejectOwner) {
            let stale = window.freezeAcceptedSelection(8003).getOrThrow()
            let _ = owner.body.applyRangeTextEdit(owner.body.ver, 0, 0, "AGENT")
            @Assert(owner.setSourceSelection(owner.body.ver, 1, 1), true)
            @Assert(session.refreshMirror(), true)
            @Assert(window.requestAcceptedSelectionRestore(stale, 0, 0, 0, 0, {=>},
                sourceCoordinatesAreBytes: true, retainedInputSequence: controller.originalArrowSequence), -1)
            @Assert(owner.body.text(), "AGENT" + original)
            @Assert(owner.body.writeCalls, 1)
            let _ = window.settleVisualInputIntent(controller.originalArrowSequence, CjguiVisualInputIntentOutcome.Aborted)
            return
        }
        // Freeze the actual immutable origin before the original held scalar.
        // Recovery names that origin, not the bindRangeTextSession label.
        let originalInputBasis = controller.completion.getOrThrow()
        let originalMirror = session.mirrorSnapshot()
        @Assert(originalInputBasis.targetBody, original)
        @Assert(originalMirror.text, original)
        @Assert(originalMirror.contentVersion, 1)
        let payload = if (forward) { "R" } else { "L" }
        let text = unsafe { LibC.mallocCString(payload) }
        try (resource = text.asResource()) {
            @Assert(unsafe { cjgui_internal_renderer_test_insert_actual_composable_proxy(
                window.testSessionToken(), resource.value) }, CJGUI_INTERNAL_RENDERER_OK)
        }
        @Assert(owner.body.writeCalls, 0)
        let target = window.freezeAcceptedSelection(8003).getOrThrow()
        let endpoint = if (forward) { Int64(original.size) } else { 0 }
        let proxy = if (forward) { cjguiUtf16Length(original) } else { 0 }
        let submission = window.submitAcceptedSourceSelection(target, endpoint, endpoint, proxy, proxy, {=>
            controller.previewSelectionCommits += 1
            let accepted = window.freezeAcceptedSelection(8003)
            if (holdAck) {
                @Assert(unsafe { cjgui_internal_renderer_test_caret_confirmation_pending_once(
                    window.testSessionToken(), if (rejectAck) { 3u32 } else { 1u32 }) }, CJGUI_INTERNAL_RENDERER_OK)
            }
            let settled = window.settleVisualInputIntent(controller.originalArrowSequence,
                CjguiVisualInputIntentOutcome.Committed, acceptedSource: accepted)
            if (holdAck) { sawPendingHead.value = !settled && window.pendingVisualInputIntent().isSome() }
            if (rejectAck) {
                @Assert(window.visualInputIntentConfirmationPending(controller.originalArrowSequence), false)
                let _ = window.settleVisualInputIntent(controller.originalArrowSequence,
                    CjguiVisualInputIntentOutcome.Aborted)
            }
        }, retainedInputSequence: controller.originalArrowSequence)
        @Assert(match (submission) { case NotAdmitted(_) => false; case _ => true }, true)
        if (rejectAck) {
            for (_ in 0..8) { sourceHandoffPump(window) }
            @Assert(unsafe { cjgui_internal_renderer_test_caret_confirmation_pending_once(
                window.testSessionToken(), 2u32) }, 1)
            @Assert(controller.previewSelectionCommits, 1)
            @Assert(owner.body.text(), original)
            @Assert(owner.body.writeCalls, 0)
            @Assert(owner.sourceSelectionSnapshot().anchorByte, 0)
            @Assert(owner.sourceSelectionSnapshot().focusByte, 0)
            let drafts = session.recoveryDraftsValue()
            @Assert(drafts.size, 1)
            @Assert(drafts[0].content, payload)
            @Assert(drafts[0].sourceVersion, 1)
            let expectedIdentity = "cjgui-input:${originalInputBasis.rendererSessionGeneration}:window:${originalInputBasis.windowInstanceToken}:binding:${originalInputBasis.targetBindingEpoch}:context:${originalInputBasis.sourceContextEpoch}:node:${originalInputBasis.targetNodeId}"
            @Assert(drafts[0].bindingIdentity, expectedIdentity)
            // Completion.source* describes A; the original scalar was captured
            // after that B. Its full unchanged source mirror is frozen above.
            @Assert(drafts[0].sourceStartByte, originalMirror.startByte)
            @Assert(drafts[0].sourceEndByte, originalMirror.startByte + Int64(original.size))
            let installed = sourceHandoffNativeSelection(window)
            @Assert(installed[0], CJGUI_INTERNAL_RENDERER_OK)
            @Assert(installed[1], 0u32)
            @Assert(installed[2], 0u32)
            // The test consumer owns this immutable complete draft before ACK.
            println("CJGUI_TEST_REFUSED_ACK_RECOVERY id=${drafts[0].draftId} text=${drafts[0].content} version=${drafts[0].sourceVersion} binding=${drafts[0].bindingIdentity} owner_reapplied=false")
            @Assert(window.acknowledgeTextSessionRecoveryDraftOwnership(drafts[0].draftId), true)
            @Assert(window.pendingVisualInputIntent().isNone(), true)
            window.close()
            @Assert(window.isOpen(), false)
            return
        }
        let finish = sourceHandoffMonotonicMicros() + 5000000u64
        while (owner.body.writeCalls == 0 && sourceHandoffMonotonicMicros() < finish) { sourceHandoffPump(window) }
        if (holdAck) {
            @Assert(unsafe { cjgui_internal_renderer_test_caret_confirmation_pending_once(
                window.testSessionToken(), 2u32) }, 1)
            @Assert(sawPendingHead.value, true)
        }
        @Assert(controller.previewSelectionCommits, 1)
        @Assert(owner.body.text(), if (forward) { original + payload } else { payload + original })
        @Assert(owner.body.writeCalls, 1)
        @Assert(window.pendingVisualInputIntent().isNone(), true)
    } finally { window.close() }
}

// The candidate really commits a different local text/node while one original
// source-global Left and its following scalar remain pending. No branch or
// installed receipt is supplied by the test: both are produced by Present.
private class SourceCarryController <: CjguiComposableUiController &
    CjguiComposableUiCompositionRangeProvider & CjguiComposableUiInstalledSelectionInputProvider & CjguiComposableUiSelectionCompletionProvider &
    CjguiComposableUiCandidateSelectionProvider {
    let base: SourceHandoffController
    var carry = false
    let first = "alpha bravo\n\n"
    let second = "charlie delta\n"
    init(base: SourceHandoffController) { this.base = base }
    public func uiSceneVersion(): Int64 { return base.uiSceneVersion() }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(8001, "carry-root",
            CjguiComposableUiStyle(fixedWidth: 360, fixedHeight: 300))
        root.add(cjguiComposableMultilineTextInput(8002, "source-body", "Source", base.owner.text(), 8802,
            CjguiComposableUiStyle(fixedWidth: 340, fixedHeight: 100), fieldId: "source-body"))
        root.add(CjguiComposableUiNode(8003, "source-preview", CJGUI_COMPOSABLE_UI_TEXT,
            "", first, "", 8803, CjguiComposableUiStyle(fixedWidth: 340, fixedHeight: 65, pointerInteractive: true), fieldId: "source-preview"))
        root.add(CjguiComposableUiNode(8009, "carry-preview", CJGUI_COMPOSABLE_UI_TEXT,
            "", second, "", 8809, CjguiComposableUiStyle(fixedWidth: 340, fixedHeight: 65, pointerInteractive: true), fieldId: "carry-preview"))
        return root
    }
    public func prepareCompositionSourceRange(node: CjguiComposableUiLayoutNode,
        start16: Int64, end16: Int64, sceneVersion: Int64): CjguiMappedCompositionRange {
        let offset: Int64 = if (node.nodeId == 8003 && node.value == first) { 0 }
            else if (node.nodeId == 8009 && node.value == second) { Int64(first.size) } else { return CjguiMappedCompositionRange(None) }
        if (sceneVersion != base.window.getOrThrow().windowProjection().acceptedSceneVersion) {
            return CjguiMappedCompositionRange(None)
        }
        let lo = match (cjguiUtf16OffsetToUtf8(node.value, start16)) { case Some(v) => v; case None => return CjguiMappedCompositionRange(None) }
        let hi = match (cjguiUtf16OffsetToUtf8(node.value, end16)) { case Some(v) => v; case None => return CjguiMappedCompositionRange(None) }
        return CjguiMappedCompositionRange(base.session.getOrThrow().prepareSourceRange(base.owner.ver,
            offset + lo, offset + hi))
    }
    public func candidateSelectionProjection(): ?CjguiComposableUiCandidateSelectionProjection {
        if (!carry) { return None }
        let session = base.session.getOrThrow()
        let selected = session.sourceSelectionSnapshot().getOrThrow()
        return Some(CjguiComposableUiCandidateSelectionProjection(base.completion, selected,
            session.freezeSelectionTicket(), "source-handoff:owner1:bytes13-27", 8009, 8809,
            CJGUI_COMPOSABLE_UI_TEXT, second, 0, cjguiUtf16Length(second), Int64(second.size)))
    }
    public func selectionInstallationCompleted(value: CjguiInstalledSelectionCompletion): Unit {
        base.selectionInstallationCompleted(value)
    }
    public func authorizeInstalledSelectionInput(proof: CjguiInstalledSelectionInputProof): ?CjguiOwnerSelectionChoice {
        return base.authorizeInstalledSelectionInput(proof)
    }
    public func installedSelectionChoiceIsCurrent(choice: CjguiOwnerSelectionChoice): Bool {
        return base.installedSelectionChoiceIsCurrent(choice)
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return base.applyUiEvent(event)
    }
    public func rejectUiEvent(kind: Int64, node: Int64): CjguiComposableUiDispatchResult {
        return base.rejectUiEvent(kind, node)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult { return base.requestWindowClose() }
}

@Test
func sourceHandoffDeferredSourceArrowCandidateCarryKeepsOriginalUntilFinalB(): Unit { sourceHandoffCandidateCarry("normal") }
@Test
func sourceHandoffDeferredSourceArrowCandidateCarryAckPendingOnlyConfirms(): Unit { sourceHandoffCandidateCarry("ack_pending") }
@Test
func sourceHandoffDeferredSourceArrowCandidateCarrySameBytesNewRevisionRejects(): Unit { sourceHandoffCandidateCarry("choice_revision") }
@Test
func sourceHandoffDeferredSourceArrowCandidateCarryExternalVersionRejects(): Unit { sourceHandoffCandidateCarry("external_version") }
@Test
func sourceHandoffDeferredSourceArrowCandidateCarryPresentFailurePreservesA(): Unit { sourceHandoffCandidateCarry("present_failure") }
@Test
func sourceHandoffDeferredSourceArrowCandidateCarryBindRejectionTerminatesAndRecovers(): Unit { sourceHandoffCandidateCarry("bind_rejection") }
@Test
func sourceHandoffDeferredSourceArrowCandidateCarryCloseWithOriginalFollowingText(): Unit { sourceHandoffCandidateCarry("close") }

@Test
func sourceHandoffDeferredSourceArrowCandidateCarryCancellationWithOriginalFollowingText(): Unit { sourceHandoffCandidateCarry("cancel_pending") }

@Test
func sourceHandoffDeferredSourceArrowCandidateCarryRebindSameBytesCannotInheritOriginal(): Unit { sourceHandoffCandidateCarry("rebind") }

private func sourceHandoffCandidateCarry(mode: String): Unit {
    let owner = SelectionAuthorityTestOwner()
    let original = owner.body.text()
    let base = SourceHandoffController(owner.body)
    base.requireCompletion = true
    base.selectionDocumentId = "test-authority"
    let controller = SourceCarryController(base)
    let window = CjguiComposableUiWindow(controller, configuration: CjguiMacosApplicationWindowConfiguration(
        "CJGUI source carry", 980u32, 620u32, rangeTextEditDeltaDelivery: true))
    try {
        let session = window.bindRangeTextSession(8002, "source-carry", owner, owner,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        base.attach(window, session)
        @Assert(original, controller.first + controller.second)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let restore = window.requestAcceptedSelectionRestore(window.freezeAcceptedSelection(8003).getOrThrow(),
            0, Int64(original.size), 0, cjguiUtf16Length(controller.first), {=>}, sourceCoordinatesAreBytes: true)
        let deadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(restore) == "pending" && sourceHandoffMonotonicMicros() < deadline) {
            sourceHandoffPump(window)
        }
        @Assert(window.selectionRestoreState(restore), "installed")
        let a = base.completion.getOrThrow()
        @Assert(a.targetBody, controller.first)
        base.retainOriginalArrow = true
        var focused = 0u64
        @Assert(unsafe { cjgui_internal_renderer_test_send_composable_key(window.testSessionToken(),
            123u16, 0u64, inout focused) }, CJGUI_INTERNAL_RENDERER_OK)
        sourceHandoffPump(window)
        let head = window.pendingVisualInputIntent().getOrThrow()
        @Assert(head.sequence, base.originalArrowSequence)
        if (mode == "cancel_pending") { @Assert(window.testHoldNextComposablePresent(), true) }
        if (mode == "present_failure") {
            @Assert(unsafe { cjgui_internal_renderer_test_set_composable_present_failures(
                window.testSessionToken(), 1u32) }, CJGUI_INTERNAL_RENDERER_OK)
        }
        controller.carry = true
        base.revision += 1
        let _ = window.refreshIfNeeded()
        let carryDeadline = sourceHandoffMonotonicMicros() + 5000000u64
        if (mode == "cancel_pending") {
            while (window.windowProgress().pendingRefreshReason != "refresh_present_pending" &&
                sourceHandoffMonotonicMicros() < carryDeadline) { sourceHandoffPump(window) }
            @Assert(window.windowProgress().pendingRefreshReason, "refresh_present_pending")
            @Assert(base.completion.getOrThrow().transferId, a.transferId)
            let pendingText = unsafe { LibC.mallocCString("L") }
            try (resource = pendingText.asResource()) {
                @Assert(unsafe { cjgui_internal_renderer_test_insert_actual_composable_proxy(
                    window.testSessionToken(), resource.value) }, CJGUI_INTERNAL_RENDERER_OK)
            }
            @Assert(owner.body.writeCalls, 0)
            window.close()
            @Assert(window.isOpen(), true)
            let drafts = session.recoveryDraftsValue()
            @Assert(drafts.size, 1)
            @Assert(drafts[0].content, "L")
            let expectedOrigin = "cjgui-input:${a.rendererSessionGeneration}:window:${a.windowInstanceToken}:binding:${a.targetBindingEpoch}:context:${a.sourceContextEpoch}:node:${a.targetNodeId}"
            @Assert(drafts[0].bindingIdentity, expectedOrigin)
            @Assert(window.acknowledgeTextSessionRecoveryDraftOwnership(drafts[0].draftId), true)
            // The original input has been cancelled, so this old proposal must
            // reject. A pending receipt is not permission to install its B.
            @Assert(window.testResolvePendingComposablePresent(), false)
            @Assert(base.completion.getOrThrow().transferId, a.transferId)
            let nativeA = sourceHandoffNativeSelection(window)
            @Assert(nativeA[0], CJGUI_INTERNAL_RENDERER_OK)
            @Assert(nativeA[1], 0u32)
            @Assert(nativeA[2], UInt32(cjguiUtf16Length(controller.first)))
            @Assert(owner.body.text(), original)
            @Assert(owner.body.writeCalls, 0)
            window.close()
            @Assert(window.isOpen(), false)
            return
        }
        while (base.completion.getOrThrow().targetNodeId != 8009 &&
            sourceHandoffMonotonicMicros() < carryDeadline &&
            !(mode == "present_failure" && window.windowProgress().lastNativeFailure != "none")) {
            @Assert(owner.body.writeCalls, 0)
            sourceHandoffPump(window)
        }
        println("CJGUI_TEST_CARRY_PROGRESS failure=${window.windowProgress().lastNativeFailure}")
        let carry = base.completion.getOrThrow()
        if (mode == "present_failure") {
            @Assert(window.windowProgress().lastNativeFailure != "none", true)
            @Assert(carry.transferId, a.transferId)
            @Assert(carry.targetNodeId, a.targetNodeId)
            @Assert(carry.targetBody, controller.first)
        } else {
            @Assert(carry.transferId != a.transferId, true)
            @Assert(carry.targetNodeId, 8009)
            @Assert(carry.targetBody, controller.second)
        }
        @Assert(cjguiSameSourceChoice(carry.sourceSelection, a.sourceSelection), true)
        let originalPayloadBinding = "cjgui-input:${carry.rendererSessionGeneration}:window:${carry.windowInstanceToken}:binding:${carry.targetBindingEpoch}:context:${carry.sourceContextEpoch}:node:${carry.targetNodeId}"

        @Assert(window.pendingVisualInputIntent().getOrThrow().sequence, head.sequence)
        @Assert(owner.body.text(), original)
        @Assert(owner.body.writeCalls, 0)
        let text = unsafe { LibC.mallocCString("L") }
        try (resource = text.asResource()) {
            @Assert(unsafe { cjgui_internal_renderer_test_insert_actual_composable_proxy(
                window.testSessionToken(), resource.value) }, CJGUI_INTERNAL_RENDERER_OK)
        }
        @Assert(owner.body.writeCalls, 0)
        if (mode == "rebind") {
            let stale = window.freezeAcceptedSelection(8002).getOrThrow()
            let sameBytesDifferentOwner = SelectionAuthorityTestOwner()
            @Assert(sameBytesDifferentOwner.setSourceSelection(1, 0, Int64(original.size)), true)
            @Assert(cjguiSameSourceChoice(sameBytesDifferentOwner.sourceSelectionSnapshot(), carry.sourceSelection), true)
            controller.carry = false
            let rebound = window.bindRangeTextSession(8002, "source-carry-rebound", sameBytesDifferentOwner,
                sameBytesDifferentOwner, 8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
            base.attach(window, rebound)
            @Assert(session.isBound(), false)
            @Assert(rebound.isBound(), true)
            let oldDrafts = window.retiredTextSessionRecoveryDrafts()
            @Assert(oldDrafts.size, 1)
            @Assert(oldDrafts[0].content, "L")
            @Assert(oldDrafts[0].bindingIdentity, originalPayloadBinding)
            @Assert(window.requestAcceptedSelectionRestore(stale, 0, 0, 0, 0, {=>},
                sourceCoordinatesAreBytes: true, retainedInputSequence: head.sequence), -1)
            let _ = window.settleVisualInputIntent(head.sequence, CjguiVisualInputIntentOutcome.Aborted)
            @Assert(window.acknowledgeTextSessionRecoveryDraftOwnership(oldDrafts[0].draftId), true)
            for (_ in 0..8) { sourceHandoffPump(window) }
            @Assert(owner.body.text(), original)
            @Assert(owner.body.writeCalls, 0)
            @Assert(sameBytesDifferentOwner.body.text(), original)
            @Assert(sameBytesDifferentOwner.body.writeCalls, 0)
            window.close()
            @Assert(window.isOpen(), false)
            return
        }
        if (mode == "choice_revision" || mode == "external_version") {
            let stale = window.freezeAcceptedSelection(8002).getOrThrow()
            if (mode == "external_version") {
                let _ = owner.body.applyRangeTextEdit(owner.body.ver, 0, 0, "AGENT")
            }
            @Assert(owner.setSourceSelection(owner.body.ver, 0, Int64(owner.body.data.size)), true)
            let _ = session.refreshMirror()
            @Assert(owner.sourceSelectionSnapshot().revision != a.sourceSelection.revision, true)
            let ticket = if (mode == "choice_revision") { window.freezeAcceptedSelection(8002).getOrThrow() } else { stale }
            @Assert(window.requestAcceptedSelectionRestore(ticket, 0, 0, 0, 0, {=>},
                sourceCoordinatesAreBytes: true, retainedInputSequence: head.sequence), -1)
            let _ = window.settleVisualInputIntent(head.sequence, CjguiVisualInputIntentOutcome.Aborted)
            for (_ in 0..8) { sourceHandoffPump(window) }
            let drafts = session.recoveryDraftsValue()
            @Assert(drafts.size, 1)
            @Assert(drafts[0].content, "L")
            @Assert(drafts[0].bindingIdentity, originalPayloadBinding)

            @Assert(drafts[0].sourceVersion, 1)
            @Assert(owner.body.text(), if (mode == "external_version") { "AGENT" + original } else { original })
            @Assert(owner.body.writeCalls, if (mode == "external_version") { 1 } else { 0 })
            @Assert(window.acknowledgeTextSessionRecoveryDraftOwnership(drafts[0].draftId), true)
            window.close()
            @Assert(window.isOpen(), false)
            return
        }
        if (mode == "close") {
            window.close()
            let drafts = session.recoveryDraftsValue()
            @Assert(drafts.size, 1)
            @Assert(drafts[0].content, "L")
            @Assert(drafts[0].bindingIdentity, originalPayloadBinding)

            @Assert(owner.body.text(), original)
            @Assert(owner.body.writeCalls, 0)
            @Assert(window.acknowledgeTextSessionRecoveryDraftOwnership(drafts[0].draftId), true)
            window.close()
            @Assert(window.isOpen(), false)
            return
        }
        if (mode == "bind_rejection") {
            @Assert(unsafe { cjgui_internal_renderer_test_caret_confirmation_pending_once(
                window.testSessionToken(), 4u32) }, CJGUI_INTERNAL_RENDERER_OK)
        }
        // Merely carrying A is not the requested Left outcome. Its full native
        // original remains pending until the real collapsed target B commits.
        controller.carry = false
        let request = window.submitAcceptedSourceSelection(window.freezeAcceptedSelection(8002).getOrThrow(),
            0, 0, 0, 0, {=>
                base.previewSelectionCommits += 1
                if (mode == "ack_pending") {
                    @Assert(unsafe { cjgui_internal_renderer_test_caret_confirmation_pending_once(
                        window.testSessionToken(), 1u32) }, CJGUI_INTERNAL_RENDERER_OK)
                }
                let settled = window.settleVisualInputIntent(head.sequence, CjguiVisualInputIntentOutcome.Committed,
                    acceptedSource: window.freezeAcceptedSelection(8002))
                @Assert(settled, mode != "ack_pending")
                if (mode == "ack_pending") { @Assert(window.visualInputIntentConfirmationPending(head.sequence), true) }
            }, retainedInputSequence: head.sequence)
        if (mode == "bind_rejection") {
            @Assert(match (request) {
                case NotAdmitted(reason) => reason == "source_preparation_rejected:selection_transfer_caret_bind:33"
                case _ => false
            }, true)
        } else { @Assert(match (request) { case NotAdmitted(_) => false; case _ => true }, true) }
        if (mode == "bind_rejection") {
            for (_ in 0..8) { sourceHandoffPump(window) }
            @Assert(unsafe { cjgui_internal_renderer_test_caret_confirmation_pending_once(
                window.testSessionToken(), 2u32) }, 1)
            @Assert(base.previewSelectionCommits, 0)
            @Assert(window.pendingSelectionRestoreId(), -1)
            @Assert(window.pendingVisualInputIntent().isNone(), true)
            @Assert(owner.body.text(), original)
            @Assert(owner.body.writeCalls, 0)
            let drafts = session.recoveryDraftsValue()
            @Assert(drafts.size, 1)
            @Assert(drafts[0].content, "L")
            @Assert(drafts[0].bindingIdentity, originalPayloadBinding)

            @Assert(window.acknowledgeTextSessionRecoveryDraftOwnership(drafts[0].draftId), true)
            window.close()
            @Assert(window.isOpen(), false)
            return
        }
        let finish = sourceHandoffMonotonicMicros() + 5000000u64
        while (owner.body.writeCalls == 0 && sourceHandoffMonotonicMicros() < finish) { sourceHandoffPump(window) }
        @Assert(base.previewSelectionCommits, 1)
        if (mode == "ack_pending") {
            @Assert(unsafe { cjgui_internal_renderer_test_caret_confirmation_pending_once(
                window.testSessionToken(), 2u32) }, 1)
        }
        @Assert(owner.body.text(), "L" + original)
        @Assert(owner.body.writeCalls, 1)
        @Assert(window.pendingVisualInputIntent().isNone(), true)
        window.close()
        @Assert(window.isOpen(), false)
    } finally { window.close() }
}

// Same original capture and unchanged directed range: UPDATE must publish its
// callback once without another owner choice or native proxy installation.
@Test
func sourceHandoffSameGestureUnchangedUpdateReusesActualInstall(): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789\n".toArray()
    let controller = SourceHandoffController(authority.body)
    controller.selectionDocumentId = "test-authority"
    controller.requireCompletion = true
    controller.useSelectionSubmissionForPointer = true
    controller.useSourceSelectionSubmissionForPointer = true
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "same-gesture-unchanged-selection", authority, authority,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    controller.attach(window, session)
    try {
        window.testSetInitialTextFocusWindowState(true, true, true, true, false)
        @Assert(window.start(), true)
        let ticket = window.freezeAcceptedSelection(8003).getOrThrow()
        let id = window.requestAcceptedSelectionRestore(ticket, 0, 0, 0, 0, { => },
            sourceCoordinatesAreBytes: true, foregroundOnly: true)
        let deadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(id) == "pending" && sourceHandoffMonotonicMicros() < deadline) {
            sourceHandoffPump(window)
        }
        @Assert(window.selectionRestoreState(id), "installed")
        let (ready, x, y) = sourceHandoffTextPoint(window, 8003, 8803, 0.1)
        @Assert(ready, true)
        @Assert(sourceHandoffSendMouse(window, 1u32, x, y), 0)
        sourceHandoffPump(window)
        let (_, finishX, finishY) = sourceHandoffTextPoint(window, 8003, 8803, 0.3)
        @Assert(sourceHandoffSendMouse(window, 2u32, finishX, finishY), 0)
        sourceHandoffPump(window)
        let before = session.sourceSelectionSnapshot().getOrThrow()
        let installed = window.installedSelectionCompletion().getOrThrow()
        let callbacks = controller.previewSelectionCommits
        let completions = controller.completionCount
        let updates = controller.pointerUpdateAdmissions
        let gesture = sourceHandoffNativeGesture(window)
        @Assert(before.anchorByte != before.focusByte, true)
        @Assert(sourceHandoffSendMouse(window, 2u32, finishX + 0.05f32, finishY), 0)
        sourceHandoffPump(window)
        let after = session.sourceSelectionSnapshot().getOrThrow()
        @Assert(after.anchorByte, before.anchorByte)
        @Assert(after.focusByte, before.focusByte)
        @Assert(controller.pointerUpdateAdmissions, updates + 1)
        @Assert(controller.previewSelectionCommits, callbacks + 1)
        @Assert(sourceHandoffNativeGesture(window), gesture)
        @Assert(after.revision, before.revision)
        @Assert(window.installedSelectionCompletion().getOrThrow().transferId, installed.transferId)
        @Assert(controller.completionCount, completions)
        let resident = internalRendererActiveInstalledRangeReceipt(window.testSessionToken(),
            installed.transferId).getOrThrow()
        @Assert(resident.proxyGeneration, installed.targetProxyGeneration)
        @Assert(resident.installedSceneVersion, UInt64(installed.targetSceneVersion))
        @Assert(window.freezeAcceptedSelection(8003).getOrThrow().sceneVersion > installed.targetSceneVersion, true)
        // An explicit passive projection must also keep the historical install.
        @Assert(window.refresh(), true)
        @Assert(sourceHandoffSendMouse(window, 2u32, finishX + 0.07f32, finishY), 0)
        sourceHandoffPump(window)
        @Assert(session.sourceSelectionSnapshot().getOrThrow().revision, before.revision)
        @Assert(controller.previewSelectionCommits, callbacks + 2)
        @Assert(controller.pointerUpdateAdmissions, updates + 2)
        @Assert(controller.completionCount, completions)
        @Assert(window.installedSelectionCompletion().getOrThrow().transferId, installed.transferId)
        // A real changed range still reserves and installs a fresh choice.
        let nextX = x - 30.0f32
        let nextY = y - 25.0f32
        @Assert(sourceHandoffSendMouse(window, 2u32, nextX, nextY), 0)
        sourceHandoffPump(window)
        let changed = session.sourceSelectionSnapshot().getOrThrow()
        @Assert(changed.focusByte != after.focusByte, true)
        @Assert(changed.revision > after.revision, true)
        @Assert(window.installedSelectionCompletion().getOrThrow().transferId != installed.transferId, true)
        @Assert(sourceHandoffSendMouse(window, 3u32, nextX, nextY), 0)
        sourceHandoffPump(window)
        // An explicit mapped selection outside a pointer UPDATE remains a new
        // owner choice even if its directed coordinates are identical.
        let explicitBefore = session.sourceSelectionSnapshot().getOrThrow()
        let actual = window.installedSelectionCompletion().getOrThrow()
        let current = window.freezeAcceptedSelection(8003).getOrThrow()
        let submission = window.submitAcceptedSourceSelection(current, explicitBefore.anchorByte,
            explicitBefore.focusByte, actual.targetSelectionStart16, actual.targetSelectionEnd16, {=>})
        let explicitDeadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.pendingSelectionRestoreId() >= 0 && sourceHandoffMonotonicMicros() < explicitDeadline) {
            sourceHandoffPump(window)
        }
        let explicitAfter = session.sourceSelectionSnapshot().getOrThrow()
        @Assert(explicitAfter.anchorByte, explicitBefore.anchorByte)
        @Assert(explicitAfter.focusByte, explicitBefore.focusByte)
        @Assert(explicitAfter.revision > explicitBefore.revision, true)
        @Assert(authority.body.writeCalls, 0)
    } finally { window.close() }
}

// Native production tests cover the actual input proxy/receipt. This common
// test distinguishes real passive-origin authority from an ordinary deletion.
@When[os == "macOS"]
func sourceHandoffResidentProjectionFixture(qualified: Bool): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "ABCDE\nFGHIJ\n".toArray()
    let original = authority.body.text()
    let controller = SourceHandoffController(authority.body)
    controller.scrollFixture = true
    controller.residentAnchorPreview = true
    controller.selectionDocumentId = "test-authority"
    controller.requireCompletion = true
    let bindingA = CjguiComposableUiScrollOriginBinding("resident-test-owner", authority.body.ver,
        "resident-map-A", "resident-origin-A")
    @Assert(controller.sourceViewport.stageCoordinateOrigin(bindingA), "scroll_origin_initial")
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "resident-source-common", authority, authority,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    controller.attach(window, session)
    try {
        window.testSetInitialTextFocusWindowState(true, true, true, true, false)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let choice = window.freezeAcceptedSelection(8003).getOrThrow()
        let restore = window.requestAcceptedSelectionRestore(choice, 2, 2, 2, 2, { => },
            sourceCoordinatesAreBytes: true, foregroundOnly: true)
        let deadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(restore) == "pending" && sourceHandoffMonotonicMicros() < deadline) {
            sourceHandoffPump(window)
        }
        @Assert(window.selectionRestoreState(restore), "installed")
        let completed = window.installedSelectionCompletion().getOrThrow()
        let before = session.sourceSelectionSnapshot().getOrThrow()
        if (qualified) {
            let anchor = window.freezeScrollOriginAnchor(controller.sourceViewport, 8008, 0,
                "0", bindingA).getOrThrow()
            let bindingB = CjguiComposableUiScrollOriginBinding("resident-test-owner", authority.body.ver,
                "resident-map-A", "resident-origin-B")
            @Assert(controller.sourceViewport.stageCoordinateOrigin(bindingB, anchor: Some(anchor),
                targetNodeId: 8008, targetLocalByte: 0), "scroll_origin_anchor_staged")
        }
        let budget = CjguiOwnerTurnBudget()
        window.useOwnerTurnBudget(budget)
        controller.omitPreviewForResident = true
        controller.revision += 1
        window.requestRefresh()
        let sceneDeadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.inputSceneNodeValue(8003, 8803).isSome() &&
            sourceHandoffMonotonicMicros() < sceneDeadline) {
            @Assert(budget.begin(), true)
            let _ = window.refreshIfNeeded()
            sourceHandoffPump(window)
            budget.end()
        }
        @Assert(window.inputSceneNodeValue(8003, 8803).isNone(), true)
        @Assert(authority.body.text(), original)
        @Assert(authority.body.writeCalls, 0)
        let parked = internalRendererHasParkedTextFocus(window.testSessionToken(),
            Int64(completed.windowInstanceToken), completed.semantic.contextEpoch,
            completed.targetNodeId, completed.targetResourceId, completed.targetNodeKind)
        @Assert(parked, qualified)
        if (qualified) {
            @Assert(controller.sourceViewport.acceptedCoordinateOrigin().getOrThrow().layoutOrigin,
                "resident-origin-B")
            @Assert(window.installedSelectionCompletion().getOrThrow().transferId, completed.transferId)
            @Assert(session.sourceSelectionSnapshot().getOrThrow().revision, before.revision)
            let nativeText = unsafe { LibC.mallocCString("中") }
            try (resource = nativeText.asResource()) {
                @Assert(unsafe { cjgui_internal_renderer_test_insert_actual_composable_proxy(
                    window.testSessionToken(), resource.value) }, CJGUI_INTERNAL_RENDERER_OK)
            }
            let inputDeadline = sourceHandoffMonotonicMicros() + 5000000u64
            while (authority.body.writeCalls == 0 && sourceHandoffMonotonicMicros() < inputDeadline) {
                @Assert(budget.begin(), true)
                sourceHandoffPump(window)
                let _ = window.refreshIfNeeded()
                budget.end()
            }
            @Assert(authority.body.text(), "AB中CDE\nFGHIJ\n")
            @Assert(authority.body.writeCalls, 1)
            @Assert(authority.body.ver, 2)
        }
    } finally { window.close() }
}

@When[os == "macOS"]
@Test
func sourceHandoffResidentPassiveOriginKeepsInstalledFirstInputWithoutFakeOwnerOperation(): Unit {
    sourceHandoffResidentProjectionFixture(true)
}

@When[os == "macOS"]
@Test
func sourceHandoffResidentMissingPaintWithoutOriginTicketRetiresSource(): Unit {
    sourceHandoffResidentProjectionFixture(false)
}

// Actual production AX action -> original FIFO -> the real window command
// admission -> owner selection -> native B. Faults alter only those already
// queued members; they are not another event producer.
private func runActualAXCommandDispatch(fault: UInt32, declared!: Bool = true,
    revoke!: Bool = false, physical!: Bool = false, restoreAfterDeclaration!: Bool = false): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "abcdef\n".toArray()
    let owner = authority.body
    let controller = SourceHandoffController(owner)
    controller.selectionDocumentId = "test-authority"
    controller.requireCompletion = true
    controller.includeUndoAction = true
    controller.exerciseDeclaredActivation = declared
    let window = sourceHandoffWindow(controller)
    try {
        let session = window.bindRangeTextSession(8002, "ax-command", authority, authority,
            8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        controller.attach(window, session)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.focusAcceptedNodeById(8002), true)
        session.setSelection16(1, 4)
        let initial = window.requestTextSelectionRestore(8002, 8802,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.text(), 1, 4)
        @Assert(initial > 0, true)
        let deadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (controller.completionCount == 0 && sourceHandoffMonotonicMicros() < deadline) {
            sourceHandoffPump(window)
        }
        @Assert(controller.completionCount > 0, true)
        if (declared) {
            let commands = ArrayList<CjguiComposableUiCommand>()
            commands.add(CjguiComposableUiCommand("actual-ax-selection", CjguiComposableUiNodeReference.manual(8004),
                "Select", "", 0, true, false))
            @Assert(window.replaceCommands(commands), true)
        }
        if (restoreAfterDeclaration) {
            // Declarations precede this genuine, same-owner native B install.
            // Replacing commands after it would mask the missing publication.
            let before = controller.completionCount
            session.setSelection16(4, 1)
            let restore = window.requestTextSelectionRestore(8002, 8802,
                CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.text(), 1, 4)
            @Assert(restore > initial, true)
            let restoredDeadline = sourceHandoffMonotonicMicros() + 5000000u64
            while (controller.completionCount == before && sourceHandoffMonotonicMicros() < restoredDeadline) {
                sourceHandoffPump(window)
            }
            @Assert(controller.completionCount, before + 1)
            let installed = window.installedSelectionCompletion().getOrThrow()
            @Assert(installed.sourceSelection.anchorByte, 4)
            @Assert(installed.sourceSelection.focusByte, 1)
        }
        if (physical) {
            let point = sourceHandoffAcceptedPoint(window, 8004, 8804)
            @Assert(point[0], true)
            @Assert(sourceHandoffSendMouse(window, 1u32, point[1], point[2]), CJGUI_INTERNAL_RENDERER_OK)
            @Assert(sourceHandoffSendMouse(window, 3u32, point[1], point[2]), CJGUI_INTERNAL_RENDERER_OK)
        } else {
            @Assert(unsafe { cjgui_internal_renderer_test_capture_composable_accessibility_action_for_node(
                window.testSessionToken(), 8004u64) }, CJGUI_INTERNAL_RENDERER_OK)
            @Assert(unsafe { cjgui_internal_renderer_test_invoke_captured_composable_accessibility_action(
                window.testSessionToken()) }, CJGUI_INTERNAL_RENDERER_OK)
            if (fault > 0u32) {
                @Assert(unsafe { cjgui_internal_renderer_test_fault_actual_activation_pair(
                    window.testSessionToken(), fault) }, CJGUI_INTERNAL_RENDERER_OK)
            }
        }
        if (revoke) { @Assert(window.revokeCommand("actual-ax-selection"), true) }
        // Drain a finite FIFO and the retained real selection completion. No
        // retry action, fabricated focus or replacement input is submitted.
        let finish = sourceHandoffMonotonicMicros() + 3000000u64
        while (sourceHandoffMonotonicMicros() < finish &&
            (controller.declaredActivationCount == 0 ||
                (controller.declaredSelectionAdmissions > 0 && controller.declaredSelectionPublishes == 0))) {
            sourceHandoffPump(window)
        }
        for (_ in 0..4) { sourceHandoffPump(window) }
        let accepted = fault == 0u32 || fault == 3u32
        if (accepted) { @Assert(controller.declaredActivationCount, 1) }
        else { @Assert(controller.declaredActivationCount, 0) }
        if (accepted && declared && !revoke) {
            @Assert(controller.declaredSourceAdmissions, 1)
            @Assert(controller.declaredSelectionAdmissions, 1)
            @Assert(controller.declaredSelectionPublishes, 1)
            @Assert(window.installedSelectionCompletion().getOrThrow().targetNodeId, 8003)
        } else {
            @Assert(controller.declaredSourceAdmissions, 0)
            @Assert(controller.declaredSelectionAdmissions, 0)
            @Assert(controller.declaredSelectionPublishes, 0)
        }
        @Assert(owner.text(), "abcdef\n")
        @Assert(owner.ver, 1)
    } finally { window.close() }
}

@Test
func axCommandActualCommonDispatchAndPhysicalPressEachCommitOnce(): Unit {
    runActualAXCommandDispatch(0u32)
    runActualAXCommandDispatch(0u32, physical: true)
}
@Test
func axCommandActualCommonDispatchRejectsMissingFocusAndOutOfOrderTerminal(): Unit {
    runActualAXCommandDispatch(1u32)
    runActualAXCommandDispatch(2u32)
}
@Test
func axCommandActualCommonDispatchRejectsDuplicateAndWrongBindingGenerationTarget(): Unit {
    runActualAXCommandDispatch(3u32)
    runActualAXCommandDispatch(4u32)
    runActualAXCommandDispatch(5u32)
    runActualAXCommandDispatch(6u32)
    runActualAXCommandDispatch(7u32)
}
@Test
func axCommandActualCommonDispatchWithdrawnDeclarationAndOrdinaryAXButton(): Unit {
    runActualAXCommandDispatch(0u32, revoke: true)
    runActualAXCommandDispatch(0u32, declared: false)
}

@Test
func axCommandAfterInstalledRestoreRepublishesDeclarationForActualSource(): Unit {
    runActualAXCommandDispatch(0u32, restoreAfterDeclaration: true)
    runActualAXCommandDispatch(0u32, physical: true, restoreAfterDeclaration: true)
}
@Test
func axCommandAfterInstalledRestoreStillRejectsWithdrawnAndWrongBinding(): Unit {
    runActualAXCommandDispatch(0u32, revoke: true, restoreAfterDeclaration: true)
    runActualAXCommandDispatch(4u32, restoreAfterDeclaration: true)
}

// A real system micro-drag may deliver DOWN/MOVE/UP before the owner pumps
// even its first member. No intermediate pump or delayed/resubmitted key may
// be required to keep the original directed choice.
private func queuedSourceDragScenario(reverse: Bool): Unit {
    let authority = SelectionAuthorityTestOwner()
    authority.body.data = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789\n".toArray()
    let controller = SourceHandoffController(authority.body)
    controller.selectionDocumentId = "test-authority"
    controller.requireCompletion = true
    controller.useSelectionSubmissionForPointer = true
    controller.useSourceSelectionSubmissionForPointer = true
    let window = sourceHandoffWindow(controller)
    let session = window.bindRangeTextSession(8002, "queued-source-drag", authority, authority,
        8802, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    controller.attach(window, session)
    try {
        window.testSetInitialTextFocusWindowState(true, true, true, true, false)
        @Assert(window.start(), true)
        let ticket = window.freezeAcceptedSelection(8003).getOrThrow()
        let id = window.requestAcceptedSelectionRestore(ticket, 0, 0, 0, 0, { => },
            sourceCoordinatesAreBytes: true, foregroundOnly: true)
        let deadline = sourceHandoffMonotonicMicros() + 5000000u64
        while (window.selectionRestoreState(id) == "pending" && sourceHandoffMonotonicMicros() < deadline) {
            sourceHandoffPump(window)
        }
        @Assert(window.selectionRestoreState(id), "installed")
        let anchor: Int64 = if (reverse) { 4 } else { 2 }
        let focus: Int64 = if (reverse) { 2 } else { 4 }
        let start = window.acceptedTextPosition(8003, anchor)
        let finish = window.acceptedTextPosition(8003, focus)
        @Assert(start.status, CJGUI_INTERNAL_RENDERER_OK)
        @Assert(finish.status, CJGUI_INTERNAL_RENDERER_OK)
        @Assert(sourceHandoffSendMouse(window, 1u32, Float32(start.x + 0.05),
            Float32(start.y + start.height / 2.0)), CJGUI_INTERNAL_RENDERER_OK)
        @Assert(sourceHandoffSendMouse(window, 2u32, Float32(finish.x + 0.05),
            Float32(finish.y + finish.height / 2.0)), CJGUI_INTERNAL_RENDERER_OK)
        @Assert(sourceHandoffSendMouse(window, 3u32, Float32(finish.x + 0.05),
            Float32(finish.y + finish.height / 2.0)), CJGUI_INTERNAL_RENDERER_OK)
        for (_ in 0..64) { sourceHandoffPump(window) }
        let selected = session.sourceSelectionSnapshot().getOrThrow()
        @Assert(controller.pointerBeginAdmissions, 1)
        @Assert(controller.pointerUpdateAdmissions >= 1, true)
        @Assert(controller.pointerEndAdmissions, 1)
        @Assert(selected.anchorByte, anchor)
        @Assert(selected.focusByte, focus)
        @Assert(authority.body.text(), "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789\n")
        @Assert(authority.body.ver, 1)
    } finally { window.close() }
}

@Test
func sourceHandoffQueuedDownMoveUpKeepsFullDirectedChoice(): Unit {
    queuedSourceDragScenario(false)
    queuedSourceDragScenario(true)
}
