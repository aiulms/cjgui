package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.overflow.*
import std.time.*

// Test-only FFI. The sidecar links the production renderer with
// CJGUI_INTERNAL_TESTING; no application-facing Cangjie API exposes a native
// session or this synthetic dragging-info source.
foreign {
    func cjgui_internal_renderer_test_composable_data_transfer_drop(
        session: UInt64, targetNodeId: UInt64, externalPayload: CString
    ): Int32
    func cjgui_internal_renderer_test_composable_data_transfer_copy(
        session: UInt64, sourceNodeId: UInt64
    ): Int32
    func cjgui_internal_renderer_test_composable_data_transfer_hover_target(session: UInt64): Int32
    func cjgui_internal_renderer_test_pool_begin(): Int32
    func cjgui_internal_renderer_test_pool_end(): Int32
    func cjgui_internal_renderer_test_transfer_lifecycle_prepare(): Int64
    func cjgui_internal_renderer_test_transfer_lifecycle_verify(): Int32
    func cjgui_internal_renderer_test_transfer_lifecycle_release_leak(): Unit
    func cjgui_internal_renderer_test_composable_data_transfer_hover_cleared(session: UInt64): Int32
    func cjgui_internal_renderer_test_composable_data_transfer_cancel(session: UInt64): Int32
    func cjgui_internal_renderer_test_composable_data_transfer_stats(
        session: UInt64,
        outReadCount: CPointer<UInt64>, outReadBytes: CPointer<UInt64>, outReadPeakBytes: CPointer<UInt64>,
        outParseCount: CPointer<UInt64>, outParseBytes: CPointer<UInt64>, outParsePeakBytes: CPointer<UInt64>,
        outSourceWriteCount: CPointer<UInt64>, outSourceWriteBytes: CPointer<UInt64>,
        outSourceWritePeakBytes: CPointer<UInt64>, outSourceCurrentBytes: CPointer<UInt64>,
        outSourcePeakBytes: CPointer<UInt64>, outAcceptedCurrentBytes: CPointer<UInt64>,
        outAcceptedPeakBytes: CPointer<UInt64>, outCandidateCurrentBytes: CPointer<UInt64>,
        outCandidatePeakBytes: CPointer<UInt64>, outFifoCurrentEvents: CPointer<UInt32>,
        outFifoPeakEvents: CPointer<UInt32>, outFifoCurrentBytes: CPointer<UInt64>,
        outFifoPeakBytes: CPointer<UInt64>
    ): Int32
}

private let CONTROLLED_DOCUMENT_ID: Int64 = 7301
private let PRESSURE_DOCUMENT_ID: Int64 = 7302
private let STALE_DOCUMENT_ID: Int64 = 7303
private let MODAL_DOCUMENT_ID: Int64 = 7304
private let SOURCE_NODE_ID: Int64 = 13
private let FIRST_TARGET_NODE_ID: Int64 = 14
private let REBOUND_TARGET_NODE_ID: Int64 = 15
// The internal Cangjie wrapper intentionally exposes only statuses consumed
// by production code. This test-only sidecar status mirrors the native ABI.
private let TEST_DATA_TRANSFER_REJECTED: Int32 = 15

private class TransferStats {
    let readCount: UInt64
    let readBytes: UInt64
    let readPeakBytes: UInt64
    let parseCount: UInt64
    let parseBytes: UInt64
    let parsePeakBytes: UInt64
    let sourceWriteCount: UInt64
    let sourceWriteBytes: UInt64
    let sourceWritePeakBytes: UInt64
    let sourceBytesCurrent: UInt64
    let sourceBytesPeak: UInt64
    let acceptedBytesCurrent: UInt64
    let acceptedBytesPeak: UInt64
    let candidateBytesCurrent: UInt64
    let candidateBytesPeak: UInt64
    let fifoCurrentEvents: UInt32
    let fifoPeakEvents: UInt32
    let fifoCurrentBytes: UInt64
    let fifoPeakBytes: UInt64

    init(readCount: UInt64, readBytes: UInt64, readPeakBytes: UInt64, parseCount: UInt64, parseBytes: UInt64,
        parsePeakBytes: UInt64, sourceWriteCount: UInt64, sourceWriteBytes: UInt64, sourceWritePeakBytes: UInt64,
        sourceBytesCurrent: UInt64, sourceBytesPeak: UInt64, acceptedBytesCurrent: UInt64,
        acceptedBytesPeak: UInt64, candidateBytesCurrent: UInt64, candidateBytesPeak: UInt64,
        fifoCurrentEvents: UInt32, fifoPeakEvents: UInt32, fifoCurrentBytes: UInt64, fifoPeakBytes: UInt64) {
        this.readCount = readCount
        this.readBytes = readBytes
        this.readPeakBytes = readPeakBytes
        this.parseCount = parseCount
        this.parseBytes = parseBytes
        this.parsePeakBytes = parsePeakBytes
        this.sourceWriteCount = sourceWriteCount
        this.sourceWriteBytes = sourceWriteBytes
        this.sourceWritePeakBytes = sourceWritePeakBytes
        this.sourceBytesCurrent = sourceBytesCurrent
        this.sourceBytesPeak = sourceBytesPeak
        this.acceptedBytesCurrent = acceptedBytesCurrent
        this.acceptedBytesPeak = acceptedBytesPeak
        this.candidateBytesCurrent = candidateBytesCurrent
        this.candidateBytesPeak = candidateBytesPeak
        this.fifoCurrentEvents = fifoCurrentEvents
        this.fifoPeakEvents = fifoPeakEvents
        this.fifoCurrentBytes = fifoCurrentBytes
        this.fifoPeakBytes = fifoPeakBytes
    }
}

private func transferStats(session: UInt64): ?TransferStats {
    var readCount: UInt64 = 0
    var readBytes: UInt64 = 0
    var readPeakBytes: UInt64 = 0
    var parseCount: UInt64 = 0
    var parseBytes: UInt64 = 0
    var parsePeakBytes: UInt64 = 0
    var sourceWriteCount: UInt64 = 0
    var sourceWriteBytes: UInt64 = 0
    var sourceWritePeakBytes: UInt64 = 0
    var sourceBytesCurrent: UInt64 = 0
    var sourceBytesPeak: UInt64 = 0
    var acceptedBytesCurrent: UInt64 = 0
    var acceptedBytesPeak: UInt64 = 0
    var candidateBytesCurrent: UInt64 = 0
    var candidateBytesPeak: UInt64 = 0
    var fifoCurrentEvents: UInt32 = 0
    var fifoPeakEvents: UInt32 = 0
    var fifoCurrentBytes: UInt64 = 0
    var fifoPeakBytes: UInt64 = 0
    let status = unsafe {
        cjgui_internal_renderer_test_composable_data_transfer_stats(
            session, inout readCount, inout readBytes, inout readPeakBytes, inout parseCount, inout parseBytes,
            inout parsePeakBytes, inout sourceWriteCount, inout sourceWriteBytes, inout sourceWritePeakBytes,
            inout sourceBytesCurrent, inout sourceBytesPeak, inout acceptedBytesCurrent, inout acceptedBytesPeak,
            inout candidateBytesCurrent, inout candidateBytesPeak, inout fifoCurrentEvents, inout fifoPeakEvents,
            inout fifoCurrentBytes, inout fifoPeakBytes)
    }
    if (status != CJGUI_INTERNAL_RENDERER_OK) { return None }
    return Some(TransferStats(readCount, readBytes, readPeakBytes, parseCount, parseBytes, parsePeakBytes,
        sourceWriteCount, sourceWriteBytes, sourceWritePeakBytes, sourceBytesCurrent, sourceBytesPeak,
        acceptedBytesCurrent, acceptedBytesPeak, candidateBytesCurrent, candidateBytesPeak,
        fifoCurrentEvents, fifoPeakEvents, fifoCurrentBytes, fifoPeakBytes))
}

private func testDrop(session: UInt64, targetNodeId: Int64, payload: String): Int32 {
    let nativePayload = unsafe { LibC.mallocCString(payload) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (payloadResource = nativePayload.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_composable_data_transfer_drop(
                session, UInt64(targetNodeId), payloadResource.value)
        }
    }
    return status
}

private func testCopy(session: UInt64, sourceNodeId: Int64): Int32 {
    return unsafe {
        cjgui_internal_renderer_test_composable_data_transfer_copy(session, UInt64(sourceNodeId))
    }
}

private func payloadOfLength(length: Int64, marker: String): String {
    let builder = StringBuilder()
    builder.append(marker)
    var index = marker.size
    while (index < length) {
        builder.append("x")
        index += 1
    }
    return builder.toString()
}

/// A minimal normal window consumer. It intentionally mirrors the actual
/// document controller's transfer boundary: the window resolves the native
/// target and format, while the existing workspace/range owner decides the
/// mutation. It owns no parallel clipboard, drag, or document state.
private class ControlledDocumentTransferController <: CjguiComposableUiController & CjguiComposableUiDataTransferProvider {
    private let workspace: CjguiTextDocumentWorkspace
    private var revision: Int64
    private var targetNodeId: Int64
    private var targetEnabled: Bool
    private var sourcePayload: String
    private var acceptedTransfers: Int64
    private var acceptedCopies: Int64
    private var rejectedTransfers: Int64
    private var trace: ArrayList<String>
    private let documentId: Int64
    private var modalOpen = false

    init(workspace: CjguiTextDocumentWorkspace, documentId!: Int64 = CONTROLLED_DOCUMENT_ID) {
        this.workspace = workspace
        this.documentId = documentId
        this.revision = 1
        this.targetNodeId = FIRST_TARGET_NODE_ID
        this.targetEnabled = true
        this.sourcePayload = ""
        this.acceptedTransfers = 0
        this.acceptedCopies = 0
        this.rejectedTransfers = 0
        this.trace = ArrayList<String>()
    }

    public func uiSceneVersion(): Int64 {
        return workspace.contextSnapshot().version.saturatingAdd(revision)
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "controlled-transfer-root",
            CjguiComposableUiStyle(padding: 12, gap: 8))
        root.add(cjguiComposableText(2, "controlled-transfer-title", "受控文档传输",
            CjguiComposableUiStyle(fontSize: 15.0)))
        root.add(cjguiComposableButton(SOURCE_NODE_ID, "controlled-transfer-source",
            "复制当前文本", "TRANSFER_COPY", documentId,
            CjguiComposableUiStyle(fixedHeight: 32), enabled: sourcePayload.size > 0))
        root.add(cjguiComposableButton(targetNodeId, "controlled-transfer-target-${targetNodeId}",
            "接收文本", "TRANSFER_DROP", documentId,
            CjguiComposableUiStyle(fixedHeight: 32), enabled: targetEnabled))
        if (modalOpen) {
            // A modal layer shadows the transfer target: while it is open the
            // controller stops declaring the target, so the destination
            // boundary has no live binding for it.
            let dialog = cjguiComposableDialogLayerWithReference(60, "controlled-modal-layer",
                "controlled-modal-layer", "controlled-transfer-root",
                CjguiComposableUiNodeReference.manual(targetNodeId),
                CjguiComposableUiStyle(fixedWidth: 260, fixedHeight: 120,
                    background: CjguiComposableUiColor(0.10, 0.14, 0.22, 1.0),
                    padding: 12, gap: 8))
            dialog.add(cjguiComposableText(61, "controlled-modal-title", "模态层遮蔽中",
                CjguiComposableUiStyle(fontSize: 14.0)))
            dialog.add(cjguiComposableButton(62, "controlled-modal-close", "关闭模态",
                "CLOSE_MODAL", documentId,
                CjguiComposableUiStyle(fixedHeight: 30)))
            root.add(dialog)
        }
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.actionName == "CLOSE_MODAL") {
            modalOpen = false
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        rejectedTransfers += 1
        revision += 1
        trace.add("reject kind=${eventKind} node=${nodeId} target=${targetNodeId} enabled=${targetEnabled}")
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func dataTransferDeclarations(): ArrayList<CjguiComposableUiDataTransferDeclaration> {
        let declarations = ArrayList<CjguiComposableUiDataTransferDeclaration>()
        if (sourcePayload.size > 0) {
            if (let Some(offer) <- CjguiSharedOperationTransferOffer.create(
                "COPY", "controlled_source_window", "controlled-source-session", documentId,
                CjguiSharedOperationTransferFormat.utf8Text(maximumBytes: 512 * 1024), sourcePayload)) {
                declarations.add(CjguiComposableUiDataTransferDeclaration.source("controlled-transfer-source", offer))
            }
        }
        if (targetEnabled && !modalOpen) {
            declarations.add(CjguiComposableUiDataTransferDeclaration.target(
                "controlled-transfer-target-${targetNodeId}", CjguiSharedOperationTransferFormat.utf8Text()))
        }
        return declarations
    }

    public func setModal(open: Bool): Unit {
        modalOpen = open
        revision += 1
    }

    public func applyDataTransfer(event: CjguiComposableUiDataTransferEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_COPY && event.node.nodeId == SOURCE_NODE_ID &&
            event.offer.payload == sourcePayload) {
            acceptedCopies += 1
            revision += 1
            trace.add("copy ok node=${event.node.nodeId} bytes=${event.offer.payload.size}")
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind != CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_DROP || !targetEnabled ||
            event.node.nodeId != targetNodeId || event.node.resourceId != documentId ||
            event.format.kind != "UTF8_TEXT") {
            rejectedTransfers += 1
            revision += 1
            trace.add("drop reject:mismatch kind=${event.eventKind} node=${event.node.nodeId} " +
                "resource=${event.node.resourceId} format=${event.format.kind} bytes=${event.offer.payload.size} " +
                "target=${targetNodeId} enabled=${targetEnabled}")
            return CjguiComposableUiDispatchResult(false)
        }
        let selection = workspace.selection()
        if (!selection.isAvailable || selection.documentId != documentId) {
            rejectedTransfers += 1
            revision += 1
            trace.add("drop reject:selection bytes=${event.offer.payload.size} " +
                "available=${selection.isAvailable} doc=${selection.documentId} reason=${selection.reason}")
            return CjguiComposableUiDispatchResult(false)
        }
        let result = workspace.acceptTextTransferFromHuman(documentId,
            CjguiTextDocumentRange(selection.start, selection.end), event.offer)
        if (result.applied) {
            acceptedTransfers += 1
            revision += 1
            trace.add("drop applied bytes=${event.offer.payload.size} range=${selection.start}..${selection.end} " +
                "version=${result.versionAfter}")
            return CjguiComposableUiDispatchResult(true)
        }
        rejectedTransfers += 1
        revision += 1
        trace.add("drop reject:owner bytes=${event.offer.payload.size} range=${selection.start}..${selection.end} " +
            "reason=${result.reason}")
        return CjguiComposableUiDispatchResult(false)
    }

    public func traceLines(): ArrayList<String> { return trace }

    public func rebindTarget(): Unit {
        targetNodeId = REBOUND_TARGET_NODE_ID
        revision += 1
    }

    public func disableTarget(): Unit {
        targetEnabled = false
        revision += 1
    }

    public func acceptedCount(): Int64 { return acceptedTransfers }
    public func acceptedCopyCount(): Int64 { return acceptedCopies }
    public func rejectedCount(): Int64 { return rejectedTransfers }
    public func setSourcePayload(payload: String): Unit {
        sourcePayload = payload
        revision += 1
    }
}

private func publicRangeReadback(workspace: CjguiTextDocumentWorkspace, rangeStart: Int64, expectedContent: String,
    expectedVersion: Int64): Bool {
    let authorization = CjguiSharedOperationExternalAuthorization(
        "controlled-drop-readback", "controlled-drop-readback-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("READ_RANGE", ArrayList<Int64>([CONTROLLED_DOCUMENT_ID]), false)
        ])
    )
    let connection = CjguiSharedOperationExternalConnection(workspace, authorization)
    if (!connection.enableRangeReads(workspace)) { return false }
    let response = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH controlled-drop-readback-capability\nREAD_RANGE " +
        "${CONTROLLED_DOCUMENT_ID} ${rangeStart} ${rangeStart + expectedContent.size} ${expectedVersion}"
    )
    return response.contains("KIND RANGE\nAVAILABLE true\nCONFLICT false") &&
        response.contains("VERSION ${expectedVersion}") &&
        response.contains("CONTENT_UTF8_HEX ${expectedContent.size} " +
            CjguiSharedOperationFrame.encodeUtf8Hex(expectedContent))
}

private func contentIs(workspace: CjguiTextDocumentWorkspace, expected: String, version: Int64,
    documentId!: Int64 = CONTROLLED_DOCUMENT_ID): Bool {
    if (let Some(snapshot) <- workspace.documentSnapshot(documentId)) {
        return snapshot.content == expected && snapshot.version == version
    }
    return false
}

private func emitPayloadStats(label: String, payloadBytes: Int64, elapsedNs: Int64,
    before: CjguiSharedOperationWindowProjection, after: CjguiSharedOperationWindowProjection,
    timing: CjguiComposableUiRefreshTiming, stats: TransferStats): Unit {
    println("CJGUI_TRANSFER_PAYLOAD label=${label} payload_bytes=${payloadBytes} elapsed_ns=${elapsedNs} " +
        "build_delta=${after.buildPassCount - before.buildPassCount} layout_delta=${after.layoutPassCount - before.layoutPassCount} " +
        "submit_delta=${after.nativeSubmissionCount - before.nativeSubmissionCount} build_ns=${timing.buildNanoseconds} " +
        "layout_ns=${timing.layoutNanoseconds} stage_submit_ns=${timing.nativeStageAndSubmitNanoseconds} " +
        "read_count=${stats.readCount} read_bytes=${stats.readBytes} read_peak_bytes=${stats.readPeakBytes} " +
        "parse_count=${stats.parseCount} parse_bytes=${stats.parseBytes} parse_peak_bytes=${stats.parsePeakBytes} " +
        "source_write_count=${stats.sourceWriteCount} source_write_bytes=${stats.sourceWriteBytes} " +
        "source_write_peak_bytes=${stats.sourceWritePeakBytes} source_current_bytes=${stats.sourceBytesCurrent} " +
        "source_peak_bytes=${stats.sourceBytesPeak} accepted_current_bytes=${stats.acceptedBytesCurrent} " +
        "accepted_peak_bytes=${stats.acceptedBytesPeak} candidate_current_bytes=${stats.candidateBytesCurrent} " +
        "candidate_peak_bytes=${stats.candidateBytesPeak} fifo_current_events=${stats.fifoCurrentEvents} " +
        "fifo_peak_events=${stats.fifoPeakEvents} fifo_current_bytes=${stats.fifoCurrentBytes} " +
        "fifo_peak_bytes=${stats.fifoPeakBytes}")
}

private func runPayloadCostChain(): Bool {
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(CONTROLLED_DOCUMENT_ID, "成本目标", "目标|")
    ]))
    let controllerA = ControlledDocumentTransferController(workspace)
    let controllerB = ControlledDocumentTransferController(workspace)
    let windowA = CjguiComposableUiWindow(controllerA)
    let windowB = CjguiComposableUiWindow(controllerB)
    if (!workspace.setSelectionFromHuman(CONTROLLED_DOCUMENT_ID, CjguiTextDocumentRange(7, 7)).isAvailable ||
        !windowA.start() || !windowB.start()) {
        windowA.close(); windowB.close()
        return false
    }

    let firstPayload = payloadOfLength(128, "payload-128-")
    controllerA.setSourcePayload(firstPayload)
    controllerB.setSourcePayload(firstPayload)
    if (!windowA.refresh() || !windowB.refresh()) {
        windowA.close(); windowB.close()
        return false
    }

    // Repeated target hover must coalesce to one enter/one leave and must not
    // reach the business owner. The helper enters the production destination
    // callback; it does not fabricate a 48/49/50 event.
    // A2 hover deltas: stable repeated hover must not read or parse the
    // payload again and must not rebuild layout; one interaction paint pass
    // is the allowed feedback.
    let hoverBeforeStats = transferStats(windowA.testSessionToken())
    let hoverBeforeProjection = windowA.windowProjection()
    var hoverOk = true
    var hoverIndex: Int64 = 0
    while (hoverIndex < 128) {
        if (unsafe { cjgui_internal_renderer_test_composable_data_transfer_hover_target(windowA.testSessionToken()) } !=
            CJGUI_INTERNAL_RENDERER_OK) {
            hoverOk = false
        }
        hoverIndex += 1
    }
    let hoverPump = windowA.pump(0u32)
    let cancelStatus = unsafe { cjgui_internal_renderer_test_composable_data_transfer_cancel(windowA.testSessionToken()) }
    let cancelPump = windowA.pump(0u32)
    let hoverCleared = unsafe {
        cjgui_internal_renderer_test_composable_data_transfer_hover_cleared(windowA.testSessionToken())
    }
    let hoverAfterStats = transferStats(windowA.testSessionToken())
    let hoverAfterProjection = windowA.windowProjection()
    var hoverDeltaOk = false
    if (let Some(before) <- hoverBeforeStats) {
        if (let Some(after) <- hoverAfterStats) {
            hoverDeltaOk = before.readCount == after.readCount && before.parseCount == after.parseCount &&
                hoverBeforeProjection.buildPassCount == hoverAfterProjection.buildPassCount &&
                hoverBeforeProjection.layoutPassCount == hoverAfterProjection.layoutPassCount
        }
    }
    let hoverPure = hoverOk && hoverDeltaOk && hoverPump.isOpen && cancelStatus == CJGUI_INTERNAL_RENDERER_OK &&
        !cancelPump.didApplyHumanAction && hoverCleared == CJGUI_INTERNAL_RENDERER_OK &&
        controllerA.acceptedCount() == 0 && controllerA.acceptedCopyCount() == 0

    let payloads = ArrayList<String>([
        firstPayload,
        payloadOfLength(4096, "payload-4096-"),
        payloadOfLength(512 * 1024, "payload-524288-")
    ])
    let labels = ArrayList<String>(["small", "medium", "near_limit"])
    let expectedVersions = ArrayList<Int64>([1, 2, 3])
    var expectedContent = "目标|"
    var payloadIndex: Int64 = 0
    var payloadsPassed = true
    var otherWindowProgressed = true
    while (payloadIndex < payloads.size) {
        let payload = payloads[payloadIndex]
        // The owner document is bounded at 512 KiB total, so the near-limit
        // round replaces the whole document: the accepted result sits exactly
        // at the production boundary instead of inventing a larger budget.
        let nearLimitRound = payloadIndex == 2
        let selectionRange = if (nearLimitRound) {
            CjguiTextDocumentRange(0, expectedContent.size)
        } else {
            let selectionEnd = expectedContent.size
            CjguiTextDocumentRange(selectionEnd, selectionEnd)
        }
        if (!workspace.setSelectionFromHuman(CONTROLLED_DOCUMENT_ID, selectionRange).isAvailable) {
            payloadsPassed = false
            break
        }
        controllerA.setSourcePayload(payload)
        controllerB.setSourcePayload(payload)
        if (!windowA.refresh() || !windowB.refresh()) {
            payloadsPassed = false
            break
        }
        let targetWindow = if (payloadIndex == 1) { windowB } else { windowA }
        let targetController = if (payloadIndex == 1) { controllerB } else { controllerA }
        let priorCopyCount = targetController.acceptedCopyCount()
        let priorDropCount = targetController.acceptedCount()
        let before = targetWindow.windowProjection()
        let started = MonoTime.now()
        let copyStatus = testCopy(targetWindow.testSessionToken(), SOURCE_NODE_ID)
        let copyPump = targetWindow.pump(0u32)
        let dropStatus = testDrop(targetWindow.testSessionToken(), FIRST_TARGET_NODE_ID, payload)
        let dropPump = targetWindow.pump(0u32)
        let elapsedNs = (MonoTime.now() - started).toNanoseconds()
        let after = targetWindow.windowProjection()
        let timing = targetWindow.testRefreshTiming()
        let stats = transferStats(targetWindow.testSessionToken())
        let nextContent = if (nearLimitRound) { payload } else { expectedContent + payload }
        // The public range protocol is deliberately bounded. Read the exact
        // newly accepted suffix, rather than trying to echo a 512 KiB owner
        // document through one response frame.
        let publicSuffix = if (payload.size > 4096) { payloadOfLength(4096, "") } else { payload }
        let ownerReadback = publicRangeReadback(workspace, nextContent.size - publicSuffix.size, publicSuffix,
            expectedVersions[payloadIndex])
        let contentOk = contentIs(workspace, nextContent, expectedVersions[payloadIndex])
        let applied = copyStatus == CJGUI_INTERNAL_RENDERER_OK && copyPump.didApplyHumanAction &&
            dropStatus == CJGUI_INTERNAL_RENDERER_OK && dropPump.didApplyHumanAction &&
            targetController.acceptedCopyCount() == priorCopyCount + 1 &&
            targetController.acceptedCount() == priorDropCount + 1 &&
            contentOk && ownerReadback
        println("CJGUI_TRANSFER_ROUND label=${labels[payloadIndex]} copy_status=${copyStatus} " +
            "copy_applied=${copyPump.didApplyHumanAction} drop_status=${dropStatus} " +
            "drop_applied=${dropPump.didApplyHumanAction} copy_delta=${targetController.acceptedCopyCount() - priorCopyCount} " +
            "drop_delta=${targetController.acceptedCount() - priorDropCount} content_ok=${contentOk} " +
            "readback_ok=${ownerReadback} window=${if (payloadIndex == 1) { "B" } else { "A" }}")
        if (let Some(snapshot) <- stats) {
            emitPayloadStats(labels[payloadIndex], payload.size, elapsedNs, before, after, timing, snapshot)
        } else {
            payloadsPassed = false
        }
        payloadsPassed = payloadsPassed && applied
        // Expected state only advances for an actually accepted transfer;
        // a fail-closed rejection must not poison later expectations.
        if (applied) { expectedContent = nextContent }
        // A's operation must not starve B, and B's operation must not leave A
        // on a stale scene: both continue through their normal pump/refresh.
        let otherWindow = if (payloadIndex == 1) { windowA } else { windowB }
        let priorOtherScene = otherWindow.windowProjection().sceneVersion
        let otherRefresh = otherWindow.refreshIfNeeded()
        let otherPump = otherWindow.pump(0u32)
        let afterOtherScene = otherWindow.windowProjection().sceneVersion
        otherWindowProgressed = otherWindowProgressed && otherRefresh && otherPump.isOpen &&
            afterOtherScene >= priorOtherScene
        payloadIndex += 1
    }

    // Oversize input must fail at the production destination boundary and
    // must not reach the Cangjie owner or leave retained FIFO bytes.
    let overflowPayload = payloadOfLength(512 * 1024 + 1, "overflow-")
    let overflowBefore = expectedContent
    let overflowStatus = testDrop(windowA.testSessionToken(), FIRST_TARGET_NODE_ID, overflowPayload)
    let overflowPump = windowA.pump(0u32)
    let overflowStats = transferStats(windowA.testSessionToken())
    let overflowContentOk = contentIs(workspace, overflowBefore, 3)
    let overflowFifoEmpty = if (let Some(value) <- overflowStats) {
        value.fifoCurrentEvents == 0u32 && value.fifoCurrentBytes == 0
    } else {
        false
    }
    let overflowConverged = overflowStatus == TEST_DATA_TRANSFER_REJECTED && !overflowPump.didApplyHumanAction &&
        overflowContentOk && overflowFifoEmpty
    println("CJGUI_TRANSFER_OVERFLOW status=${overflowStatus} applied=${overflowPump.didApplyHumanAction} " +
        "content_ok=${overflowContentOk} fifo_empty=${overflowFifoEmpty}")

    // Queue two accepted drops before one normal window pump to prove FIFO
    // drain rather than direct owner invocation. The drain budget consumes
    // the whole queued FIFO in one pump, so both events must land in that
    // single turn. The document already sits at the 512 KiB boundary, so the
    // queued drops replace the 7-byte tail in place instead of appending.
    let queueStart = expectedContent.size - 7
    let _ = workspace.setSelectionFromHuman(CONTROLLED_DOCUMENT_ID,
        CjguiTextDocumentRange(queueStart, expectedContent.size))
    controllerA.setSourcePayload("queue")
    let _ = windowA.refresh()
    let queueSelectionBefore = workspace.selection().isAvailable
    let priorQueueAccepted = controllerA.acceptedCount()
    let priorQueueRejected = controllerA.rejectedCount()
    let queuedFirst = testDrop(windowA.testSessionToken(), FIRST_TARGET_NODE_ID, "queue-a")
    let queuedSecond = testDrop(windowA.testSessionToken(), FIRST_TARGET_NODE_ID, "queue-b")
    let queuedFirstPump = windowA.pump(0u32)
    let acceptedAfterFirstPump = controllerA.acceptedCount()
    let rejectedAfterFirstPump = controllerA.rejectedCount()
    // One bounded pump drains both queued drops; the public range protocol
    // then reads back the final replaced tail at the bumped version.
    let queueReadback = publicRangeReadback(workspace, queueStart, "queue-b", 5)
    let queuedSecondPump = windowA.pump(0u32)
    let queueStats = transferStats(windowA.testSessionToken())
    let queueFifoEmpty = if (let Some(value) <- queueStats) { value.fifoCurrentEvents == 0u32 } else { false }
    let fifoDrained = queuedFirst == CJGUI_INTERNAL_RENDERER_OK && queuedSecond == CJGUI_INTERNAL_RENDERER_OK &&
        queuedFirstPump.didApplyHumanAction && queuedSecondPump.isOpen &&
        acceptedAfterFirstPump == priorQueueAccepted + 2 && rejectedAfterFirstPump == priorQueueRejected &&
        queueFifoEmpty && queueReadback
    println("CJGUI_TRANSFER_QUEUE first=${queuedFirst} second=${queuedSecond} " +
        "pump1_applied=${queuedFirstPump.didApplyHumanAction} pump2_open=${queuedSecondPump.isOpen} " +
        "selection_before=${queueSelectionBefore} accepted_after_pump1=${acceptedAfterFirstPump} " +
        "rejected_after_pump1=${rejectedAfterFirstPump} queue_readback=${queueReadback} " +
        "accepted_final=${controllerA.acceptedCount()} rejected_final=${controllerA.rejectedCount()} " +
        "fifo_empty=${queueFifoEmpty} queue_start=${queueStart}")
    var traceIndex: Int64 = 0
    let traceLines = controllerA.traceLines()
    while (traceIndex < traceLines.size) {
        println("CJGUI_TRANSFER_OWNER_A[${traceIndex}] ${traceLines[traceIndex]}")
        traceIndex += 1
    }
    traceIndex = 0
    let traceLinesB = controllerB.traceLines()
    while (traceIndex < traceLinesB.size) {
        println("CJGUI_TRANSFER_OWNER_B[${traceIndex}] ${traceLinesB[traceIndex]}")
        traceIndex += 1
    }

    let beforeCloseStats = transferStats(windowA.testSessionToken())
    let occupiedBeforeClose = internalRendererOccupiedSessionCount()
    windowA.close()
    let occupiedAfterFirstClose = internalRendererOccupiedSessionCount()
    let siblingStillOpen = windowB.isOpen() && windowB.pump(0u32).isOpen
    windowB.close()
    let occupiedAfterAllClose = internalRendererOccupiedSessionCount()
    // Retention before close must hold only the live declarations: the FIFO
    // is empty, the source side holds just the latest payload (earlier 128B,
    // 4KiB and 512KiB payloads were released, not accumulated) and the
    // staged candidate set equals the accepted set. Session destruction is
    // proven by the occupied-session counts below; the stats ABI ends with
    // the session, so post-close byte counters are not observable.
    let retentionConverged = if (let Some(value) <- beforeCloseStats) {
        value.fifoCurrentEvents == 0u32 && value.fifoCurrentBytes == 0 &&
        value.sourceBytesCurrent == UInt64("queue".size) &&
        value.candidateBytesCurrent == value.acceptedBytesCurrent
    } else {
        false
    }
    if (let Some(value) <- beforeCloseStats) {
        println("CJGUI_TRANSFER_RETENTION fifo_events=${value.fifoCurrentEvents} fifo_bytes=${value.fifoCurrentBytes} " +
            "source_current=${value.sourceBytesCurrent} accepted_current=${value.acceptedBytesCurrent} " +
            "candidate_current=${value.candidateBytesCurrent}")
    }
    let closedConverged = retentionConverged && !windowA.isOpen() && !windowB.isOpen() && siblingStillOpen &&
        occupiedBeforeClose == 2u32 && occupiedAfterFirstClose == 1u32 && occupiedAfterAllClose == 0u32

    // A4-3: two drops queued while the target is valid, then the accepted
    // generation is invalidated (target disabled + refresh) BEFORE any pump
    // consumes them. The queued events must be fail-closed rejected against
    // the new scene: no owner mutation, queue drained, rejection explained.
    // A4-1: modal shadowing. While the modal layer is open the controller
    // does not declare the target, so a drop aimed at the shadowed node is
    // refused at the destination boundary; closing the layer re-arms the
    // same target and the drop then applies.
    let modalWorkspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(MODAL_DOCUMENT_ID, "模态遮蔽", "M|")
    ]))
    let controllerM = ControlledDocumentTransferController(modalWorkspace, documentId: MODAL_DOCUMENT_ID)
    let windowM = CjguiComposableUiWindow(controllerM)
    var modalOk = false
    if (modalWorkspace.setSelectionFromHuman(MODAL_DOCUMENT_ID, CjguiTextDocumentRange(2, 2)).isAvailable &&
        windowM.start()) {
        controllerM.setModal(true)
        let shadowed = windowM.refresh()
        let shadowedDrop = testDrop(windowM.testSessionToken(), FIRST_TARGET_NODE_ID, "M1")
        let shadowedPump = windowM.pump(0u32)
        let shadowedContent = if (let Some(snapshot) <- modalWorkspace.documentSnapshot(MODAL_DOCUMENT_ID)) {
            snapshot.content
        } else {
            "?"
        }
        let shadowedRejected = shadowed && shadowedDrop == TEST_DATA_TRANSFER_REJECTED &&
            !shadowedPump.didApplyHumanAction && controllerM.acceptedCount() == 0 &&
            shadowedContent == "M|"
        controllerM.setModal(false)
        let unshadowed = windowM.refresh()
        let rearmedDrop = testDrop(windowM.testSessionToken(), FIRST_TARGET_NODE_ID, "M1")
        let rearmedPump = windowM.pump(0u32)
        let rearmedContent = if (let Some(snapshot) <- modalWorkspace.documentSnapshot(MODAL_DOCUMENT_ID)) {
            snapshot.content
        } else {
            "?"
        }
        let rearmedApplied = unshadowed && shadowedDrop == TEST_DATA_TRANSFER_REJECTED &&
            rearmedDrop == CJGUI_INTERNAL_RENDERER_OK && rearmedPump.didApplyHumanAction &&
            controllerM.acceptedCount() == 1 && rearmedContent == "M|M1"
        modalOk = shadowedRejected && rearmedApplied
        println("CJGUI_TRANSFER_A4_MODAL shadowed_reject=${shadowedRejected} rearmed_apply=${rearmedApplied} " +
            "shadowed_content=${shadowedContent} rearmed_content=${rearmedContent} passed=${modalOk}")
        windowM.close()
    }

    let staleWorkspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(STALE_DOCUMENT_ID, "过期队列", "S|")
    ]))
    let controllerD = ControlledDocumentTransferController(staleWorkspace, documentId: STALE_DOCUMENT_ID)
    let windowD = CjguiComposableUiWindow(controllerD)
    var staleQueueOk = false
    if (staleWorkspace.setSelectionFromHuman(STALE_DOCUMENT_ID, CjguiTextDocumentRange(2, 2)).isAvailable &&
        windowD.start()) {
        let queuedOne = testDrop(windowD.testSessionToken(), FIRST_TARGET_NODE_ID, "q1")
        let queuedTwo = testDrop(windowD.testSessionToken(), FIRST_TARGET_NODE_ID, "q2")
        controllerD.disableTarget()
        let invalidated = windowD.refresh()
        let stalePump = windowD.pump(0u32)
        let staleContent = if (let Some(snapshot) <- staleWorkspace.documentSnapshot(STALE_DOCUMENT_ID)) {
            snapshot.content
        } else {
            "?"
        }
        let staleFifo = transferStats(windowD.testSessionToken())
        let staleFifoEmpty = if (let Some(value) <- staleFifo) { value.fifoCurrentEvents == 0u32 } else { false }
        staleQueueOk = queuedOne == CJGUI_INTERNAL_RENDERER_OK && queuedTwo == CJGUI_INTERNAL_RENDERER_OK &&
            invalidated && !stalePump.didApplyHumanAction && controllerD.acceptedCount() == 0 &&
            staleFifoEmpty && staleContent == "S|"
        println("CJGUI_TRANSFER_A4_STALE_QUEUE q1=${queuedOne} q2=${queuedTwo} invalidated=${invalidated} " +
            "pump_applied=${stalePump.didApplyHumanAction} accepted=${controllerD.acceptedCount()} " +
            "rejected=${controllerD.rejectedCount()} fifo_empty=${staleFifoEmpty} content=${staleContent} " +
            "passed=${staleQueueOk}")
        windowD.close()
    }

    // Bounded-FIFO pressure: 65 small drops race the 64-slot native FIFO.
    // An accepted drop enters as a hover-enter + drop pair, so the queue
    // fills after a bounded number of drops; everything past the capacity is
    // refused at the production destination boundary without entering the
    // queue, the queue-full notice is delivered only after the drain, and
    // the owner applies exactly the accepted edits - no silent loss and no
    // partial text.  The split point itself is an internal event-count
    // detail, so the assertions check the invariants.
    let queueFullWorkspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(PRESSURE_DOCUMENT_ID, "队列压力", "Q")
    ]))
    let controllerC = ControlledDocumentTransferController(queueFullWorkspace, documentId: PRESSURE_DOCUMENT_ID)
    let windowC = CjguiComposableUiWindow(controllerC)
    var pressureOk = false
    if (queueFullWorkspace.setSelectionFromHuman(PRESSURE_DOCUMENT_ID, CjguiTextDocumentRange(1, 1)).isAvailable &&
        windowC.start()) {
        var okCount: Int64 = 0
        var refusedCount: Int64 = 0
        var unexpectedStatus = false
        var dropIndex: Int64 = 0
        while (dropIndex < 65) {
            let status = testDrop(windowC.testSessionToken(), FIRST_TARGET_NODE_ID, "x")
            if (status == CJGUI_INTERNAL_RENDERER_OK) {
                okCount += 1
            } else if (status == TEST_DATA_TRANSFER_REJECTED) {
                refusedCount += 1
            } else {
                unexpectedStatus = true
            }
            dropIndex += 1
        }
        let pressurePump = windowC.pump(0u32)
        let noticePump = windowC.pump(0u32)
        let pressureStats = transferStats(windowC.testSessionToken())
        // Drops 2..N replace the previous in-place payload, and an identical
        // replace is a workspace no-op (applied without a version bump), so
        // the document must be exactly "Qx" while the owner counted every
        // accepted drop.
        let pressureConverged = (if (let Some(value) <- pressureStats) {
            value.fifoCurrentEvents == 0u32 && value.fifoCurrentBytes == 0
        } else {
            false
        }) && contentIs(queueFullWorkspace, "Qx", 1, documentId: PRESSURE_DOCUMENT_ID)
        pressureOk = !unexpectedStatus && okCount > 0 && okCount + refusedCount == 65 &&
            pressurePump.didApplyHumanAction && controllerC.acceptedCount() == okCount &&
            noticePump.isOpen && !noticePump.didApplyHumanAction &&
            controllerC.rejectedCount() == 1 && pressureConverged
        let pressureContent = if (let Some(snapshot) <- queueFullWorkspace.documentSnapshot(PRESSURE_DOCUMENT_ID)) {
            snapshot.content
        } else {
            ""
        }
        if (let Some(value) <- pressureStats) {
            println("CJGUI_TRANSFER_QUEUE_PRESSURE ok=${okCount} refused=${refusedCount} " +
                "applied=${controllerC.acceptedCount()} rejected=${controllerC.rejectedCount()} " +
                "pump1_applied=${pressurePump.didApplyHumanAction} notice_pump_open=${noticePump.isOpen} " +
                "fifo_events=${value.fifoCurrentEvents} fifo_bytes=${value.fifoCurrentBytes} " +
                "content=${pressureContent} content_version=${(if (let Some(snapshot) <- queueFullWorkspace.documentSnapshot(PRESSURE_DOCUMENT_ID)) { snapshot.version } else { -1 })} " +
                "converged=${pressureConverged}")
        } else {
            println("CJGUI_TRANSFER_QUEUE_PRESSURE ok=${okCount} refused=${refusedCount} stats_missing converged=${pressureConverged}")
        }
        windowC.close()
    }
    let passed = hoverPure && payloadsPassed && otherWindowProgressed && overflowConverged && fifoDrained &&
        closedConverged && pressureOk && modalOk && staleQueueOk
    println("CJGUI_TRANSFER_COST_CHAIN hover_pure=${hoverPure} payloads=${payloadsPassed} " +
        "other_window=${otherWindowProgressed} overflow=${overflowConverged} fifo_drained=${fifoDrained} " +
        "close_converged=${closedConverged} queue_pressure=${pressureOk} " +
        "overflow_status=${overflowStatus} overflow_applied=${overflowPump.didApplyHumanAction} " +
        "queued_first=${queuedFirst} queued_second=${queuedSecond} queued_first_applied=${queuedFirstPump.didApplyHumanAction} " +
        "queued_second_applied=${queuedSecondPump.didApplyHumanAction} accepted_a=${controllerA.acceptedCount()} " +
        "passed=${passed}")
    return passed
}

main(): Int64 {
    // A3: the real autorelease-pool scope opens BEFORE any transfer object of
    // this sequence is created and is popped on this same thread after the
    // whole create/replace/close chain (including the payload cost chain)
    // finished. The judge therefore runs after the pool that owns those
    // objects' autoreleased temporaries has exited, instead of wrapping only
    // the judge in a fresh empty pool, which proved nothing.
    let poolBegin = unsafe { cjgui_internal_renderer_test_pool_begin() }
    if (poolBegin != 0) {
        println("CJGUI_TRANSFER_LIFECYCLE pool_begin_error=${poolBegin}")
        return 1
    }
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(CONTROLLED_DOCUMENT_ID, "受控目标", "目标|")
    ]))
    let controller = ControlledDocumentTransferController(workspace)
    let window = CjguiComposableUiWindow(controller)
    if (!workspace.setSelectionFromHuman(CONTROLLED_DOCUMENT_ID, CjguiTextDocumentRange(7, 7)).isAvailable ||
        !window.start()) {
        window.close()
        return 1
    }

    let session = window.testSessionToken()
    let firstNativeStatus = testDrop(session, FIRST_TARGET_NODE_ID, "DROP")
    let firstPump = window.pump(0u32)
    let firstAccepted = firstNativeStatus == CJGUI_INTERNAL_RENDERER_OK && firstPump.didApplyHumanAction &&
        controller.acceptedCount() == 1 && controller.rejectedCount() == 0 &&
        contentIs(workspace, "目标|DROP", 1) && publicRangeReadback(workspace, 0, "目标|DROP", 1)

    // A4-2: hover first, then the target rebinds, then a drop arrives at the
    // OLD node. The hover must not resurrect the dropped binding: the drop is
    // refused at the native destination boundary, the owner is untouched and
    // the pending hover state is cleared with the staged scene.
    let hoverBeforeRebind = unsafe { cjgui_internal_renderer_test_composable_data_transfer_hover_target(session) };
    controller.rebindTarget();
    let reboundForA4 = window.refresh();
    let staleHoverDropStatus = testDrop(session, FIRST_TARGET_NODE_ID, "A4-2");
    let staleHoverDropPump = window.pump(0u32);
    let hoverRebindClosed = hoverBeforeRebind == CJGUI_INTERNAL_RENDERER_OK && reboundForA4 &&
        staleHoverDropStatus == TEST_DATA_TRANSFER_REJECTED && !staleHoverDropPump.didApplyHumanAction &&
        controller.acceptedCount() == 1 && contentIs(workspace, "目标|DROP", 1);
    println("CJGUI_TRANSFER_A4_HOVER_REBIND hover=${hoverBeforeRebind} drop=${staleHoverDropStatus} " +
        "applied=${staleHoverDropPump.didApplyHumanAction} accepted=${controller.acceptedCount()} " +
        "passed=${hoverRebindClosed}");
    // Restore the working binding for the rest of the chain.
    let _ = workspace.setSelectionFromHuman(CONTROLLED_DOCUMENT_ID, CjguiTextDocumentRange(11, 11));

    // `draggingExited` must only drain hover events. It is deliberately
    // exercised after a successful owner write so a hidden second mutation
    // cannot be mistaken for initial setup.
    let cancelNativeStatus = unsafe { cjgui_internal_renderer_test_composable_data_transfer_cancel(session) }
    let cancelPump = window.pump(0u32)
    let cancellationIsPure = cancelNativeStatus == CJGUI_INTERNAL_RENDERER_OK && !cancelPump.didApplyHumanAction &&
        controller.acceptedCount() == 1 && contentIs(workspace, "目标|DROP", 1)

    // A fresh accepted scene rebinds the target identity. The former node
    // must fail in native before the FIFO, while the new node still reaches
    // the same document/range owner through the normal window pump.
    controller.rebindTarget()
    let rebound = window.refresh()
    let oldTargetStatus = testDrop(session, FIRST_TARGET_NODE_ID, "STALE")
    let afterOldTarget = window.pump(0u32)
    let oldTargetRejected = rebound && oldTargetStatus == TEST_DATA_TRANSFER_REJECTED &&
        !afterOldTarget.didApplyHumanAction && controller.acceptedCount() == 1 && contentIs(workspace, "目标|DROP", 1)

    let _ = workspace.setSelectionFromHuman(CONTROLLED_DOCUMENT_ID, CjguiTextDocumentRange(11, 11))
    let reboundNativeStatus = testDrop(session, REBOUND_TARGET_NODE_ID, "NEXT")
    let reboundPump = window.pump(0u32)
    let reboundAccepted = reboundNativeStatus == CJGUI_INTERNAL_RENDERER_OK && reboundPump.didApplyHumanAction &&
        controller.acceptedCount() == 2 && contentIs(workspace, "目标|DROPNEXT", 2) &&
        publicRangeReadback(workspace, 0, "目标|DROPNEXT", 2)

    controller.disableTarget()
    let disabled = window.refresh()
    let disabledStatus = testDrop(session, REBOUND_TARGET_NODE_ID, "DISABLED")
    let disabledPump = window.pump(0u32)
    let disabledRejected = disabled && disabledStatus == TEST_DATA_TRANSFER_REJECTED &&
        !disabledPump.didApplyHumanAction && controller.acceptedCount() == 2 && contentIs(workspace, "目标|DROPNEXT", 2)

    window.close()
    let sessionAfterClose = window.testSessionToken()
    let closedPump = window.pump(0u32)
    let closeRejected = sessionAfterClose == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN &&
        !closedPump.isOpen &&
        contentIs(workspace, "目标|DROPNEXT", 2)

    let legacyPassed = firstAccepted && cancellationIsPure && oldTargetRejected && reboundAccepted && disabledRejected && closeRejected && hoverRebindClosed
    println("CJGUI_CONTROLLED_DROP_WINDOW_CHAIN first=${firstAccepted} cancel=${cancellationIsPure} " +
        "rebind_old=${oldTargetRejected} rebind_new=${reboundAccepted} disabled=${disabledRejected} " +
        "closed=${closeRejected} session=${session} session_after_close=${sessionAfterClose} accepted=${controller.acceptedCount()} " +
        "rejected=${controller.rejectedCount()} passed=${legacyPassed}")
    let costPassed = runPayloadCostChain()
    // Close the pool that owns the temporaries of this whole sequence on this
    // thread BEFORE the judge. Anything the ledger still reports as filled and
    // unreleased after this point was not released by the pool exit, by the
    // renderer retire paths or by window close - which is exactly what the
    // judge is supposed to observe.
    let poolEnd = unsafe { cjgui_internal_renderer_test_pool_end() }
    if (poolEnd != 0) {
        println("CJGUI_TRANSFER_LIFECYCLE pool_end_error=${poolEnd}")
        return 1
    }
    // A3: the negative-control target is parsed before judging so an invalid
    // configuration fails before any ledger observation is used.
    let leakTarget = unsafe { cjgui_internal_renderer_test_transfer_lifecycle_prepare() }
    if (leakTarget == -1) {
        println("CJGUI_TRANSFER_LIFECYCLE config_error=true")
        return 1
    }
    let firstVerify = unsafe { cjgui_internal_renderer_test_transfer_lifecycle_verify() }
    // Same judge in both modes: 0 = pass, 1 = filled not released, 2 = double
    // release, 3 = ledger overflow, 4 = leak target never hit.
    var lifecycleOk = false
    if (leakTarget == 0) {
        lifecycleOk = firstVerify == 0
    } else if (firstVerify == 1) {
        unsafe { cjgui_internal_renderer_test_transfer_lifecycle_release_leak() }
        let secondVerify = unsafe { cjgui_internal_renderer_test_transfer_lifecycle_verify() }
        lifecycleOk = secondVerify == 0
    }
    println("CJGUI_TRANSFER_LIFECYCLE leak_target=${leakTarget} first_verify=${firstVerify} " +
        "pool_begin=${poolBegin} pool_end=${poolEnd} judged_after_pool_exit=true ok=${lifecycleOk}")
    let passed = legacyPassed && costPassed && lifecycleOk
    println("CJGUI_CONTROLLED_DROP_WINDOW_INTEGRATION legacy=${legacyPassed} cost_chain=${costPassed} lifecycle=${lifecycleOk} passed=${passed}")
    return if (passed) { 0 } else { 1 }
}
