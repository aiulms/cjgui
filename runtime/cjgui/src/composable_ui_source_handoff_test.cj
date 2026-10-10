// E/macOS source handoff regression. The native insert helper invokes the
// actual NSTextView/TextKit delegate; coordinate-based pointer phases exercise
// the production overlay mouseDown/mouseUp route and its original FIFO.
package cjgui

import std.unittest.*
import std.unittest.testmacro.*
import std.time.*

foreign {
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
    let sourceViewport = CjguiComposableUiScrollViewport()
    var includeUndoAction = false
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
        let root = cjguiComposableVertical(8001, "source-handoff-root",
            CjguiComposableUiStyle(fixedWidth: 360, fixedHeight: 300,
                background: if (revision % 2 == 0) { CjguiComposableUiColor(0.96, 0.96, 0.96, 1.0) }
                    else { CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0) }))
        root.add(cjguiComposableMultilineTextInput(8002, "source-body", "Source", owner.text(), 8802,
            CjguiComposableUiStyle(fixedWidth: 340, fixedHeight: 150), fieldId: "source-body"))
        let preview = cjguiComposableText(8003, "source-preview", owner.text(),
            CjguiComposableUiStyle(fixedWidth: 340, fixedHeight: 70, pointerInteractive: true),
            resourceId: 8803, fieldId: "source-preview")
        if (scrollFixture) {
            let scroll = cjguiComposableScrollArea(8005, "source-preview-scroll", sourceViewport,
                CjguiComposableUiStyle(fixedWidth: 340, fixedHeight: 120))
            let content = cjguiComposableVertical(8006, "source-preview-content",
                CjguiComposableUiStyle(gap: 0, clipsContent: true))
            content.add(preview)
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
        @Assert(window.selectionRestoreState(sourceRestore + 1), "superseded")
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
        @Assert(window.selectionRestoreState(sourceRestore + 1), "superseded")
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

        for (_ in 0..8) {
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
        @Assert(window.selectionRestoreState(id), "need_prepare_installation")
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
            "down", false, -1.0, 0u64), true)
        @Assert(window.retainVisualInputIntent(2u64, 1u64, generation, source,
            "down", true, -1.0, 0u64), true)
        @Assert(window.visualInputIntentHeadIsCurrent(), true)
        @Assert(window.settleVisualInputIntent(2u64, CjguiVisualInputIntentOutcome.AtBoundary), false)
        let first = window.pendingVisualInputIntent().getOrThrow()
        @Assert(first.sequence, 1u64)
        @Assert(first.previousSequence, 0u64)
        @Assert(first.sourceTicket.nodeId, 8002)
        @Assert(window.bindVisualInputTransfer(1u64, 9001u64), true)
        @Assert(window.bindVisualInputTransfer(1u64, 9002u64), false)
        @Assert(window.pendingVisualInputIntent().getOrThrow().transferId, 9001u64)
        @Assert(window.settleVisualInputIntent(1u64, CjguiVisualInputIntentOutcome.Committed,
            acceptedSource: Some(source), acceptedPreferredX: 37.0), true)
        let rebased = window.pendingVisualInputIntent().getOrThrow()
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
