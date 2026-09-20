package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*
import std.overflow.*
import std.time.*

// This probe drives an ordinary NSTextView delegate through the same native
// FIFO that a normal composable application drains.  The only test boundary is
// the request to type into that AppKit control; controller mutation still goes
// through the Cangjie workspace owner and an application turn.
foreign {
    func cjgui_internal_renderer_test_edit_composable_text(
        session: UInt64, nodeIndex: UInt32, text: CString
    ): Int32
    // The helper resizes a real NSWindow and posts the ordinary geometry
    // notification.  The Cangjie window must observe its own resize revision.
    func cjgui_internal_renderer_test_resize_composable_window(
        session: UInt64, outResizeVersion: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_set_composable_image_launch_gate(session: UInt64, held: UInt8): Int32
    func cjgui_internal_renderer_test_composable_image_pipeline_stats(
        session: UInt64, outPathResolveMicros: CPointer<UInt64>, outCacheHitCount: CPointer<UInt64>,
        outAsyncLaunchCount: CPointer<UInt64>, outAsyncTotalMicros: CPointer<UInt64>,
        outPeakInFlight: CPointer<UInt32>, outPeakPending: CPointer<UInt32>,
        outCacheBytes: CPointer<UInt64>, outResourceCompletionVersion: CPointer<UInt64>
    ): Int32
}

private let COMPLEX_MIXED_PRIMARY_DOCUMENT_ID: Int64 = 8601
private let COMPLEX_MIXED_SECONDARY_DOCUMENT_ID: Int64 = 8602
private let COMPLEX_MIXED_EXPECTED_BATCHES: Int64 = 30
private let COMPLEX_MIXED_IMAGE_REQUEST_COUNT: Int64 = 16

private func complexMixedInitialContent(): String {
    var content = ""
    var index: Int64 = 0
    while (index < 64) {
        content = "${content}screen-off-row-${index}: stable payload ${index}\n"
        index += 1
    }
    return content
}

// A dynamic list and its anchor are projection-local.  Their text owner is
// still the workspace document, so a public REPLACE_RANGES batch can update A
// while B takes ordinary local text input.  The rows deliberately remain
// taller than the viewport: the latter half are screen-off visual objects,
// not a separate synthetic state store.
private class ComplexMixedPrimaryController <: CjguiComposableUiController {
    private let workspace: CjguiTextDocumentWorkspace
    private let documentId: Int64
    private var rowIds: ArrayList<Int64>
    private var anchorRowId: Int64
    private var localRevision: Int64
    private var usesMonospacedFont: Bool
    private var changedStructure: Bool
    private var insertedProbeRow: Bool

    init(workspace: CjguiTextDocumentWorkspace, documentId: Int64) {
        this.workspace = workspace
        this.documentId = documentId
        this.rowIds = ArrayList<Int64>()
        var index: Int64 = 0
        while (index < 64) {
            this.rowIds.add(index)
            index += 1
        }
        this.anchorRowId = 0
        this.localRevision = 1
        this.usesMonospacedFont = false
        this.changedStructure = false
        this.insertedProbeRow = false
    }

    public func uiSceneVersion(): Int64 {
        if (let Some(snapshot) <- workspace.documentSnapshot(documentId)) {
            return snapshot.version.saturatingAdd(localRevision)
        }
        return localRevision
    }

    public func buildUi(): CjguiComposableUiNode {
        let fontFamily = if (usesMonospacedFont) {
            "monospaced"
        } else {
            ""
        }
        let snapshot = if (let Some(value) <- workspace.documentSnapshot(documentId)) {
            value
        } else {
            CjguiTextDocumentSnapshot(documentId, "复杂混合负载已关闭", "", 0)
        }
        let host = cjguiComposableLayerHost(1, "complex-mixed-primary-host",
            CjguiComposableUiStyle(padding: 8, background: CjguiComposableUiColor(0.04, 0.06, 0.10, 1.0)))
        let base = cjguiComposableVertical(2, "complex-mixed-primary-base",
            CjguiComposableUiStyle(padding: 8, gap: 4, fontFamily: fontFamily))
        base.add(cjguiComposableMultilineTextInput(3, "complex-mixed-primary-editor", snapshot.title, snapshot.content,
            documentId, CjguiComposableUiStyle(fixedHeight: 140, fontFamily: fontFamily), fieldId: "primaryContent",
            operationActionName: "REPLACE_RANGE", operationResourceId: documentId, displayValueRole: "document"))
        for (rowId in rowIds) {
            let row = cjguiComposableVertical(1000 + rowId, "complex-mixed-primary-row-${rowId}",
                CjguiComposableUiStyle(fixedHeight: 24, padding: 2, fontFamily: fontFamily),
                inputScopeId: "complex-mixed-scope-${rowId}")
            row.add(cjguiComposableText(2000 + rowId, "complex-mixed-primary-row-value-${rowId}",
                "屏外对象 ${rowId}，文档 v${snapshot.version}",
                CjguiComposableUiStyle(fontSize: 11.0, fontFamily: fontFamily), resourceId: documentId,
                displayValueRole: "document"))
            base.add(row)
        }
        host.add(base)
        let anchor = cjguiComposableAnchoredLayer(9000, "complex-mixed-primary-anchor", "complex-mixed-anchor", "menu",
            "complex-mixed-primary-row-${anchorRowId}", 1000 + anchorRowId,
            CjguiComposableUiStyle(fixedWidth: 210, fixedHeight: 32, padding: 4, fontFamily: fontFamily,
                background: CjguiComposableUiColor(0.10, 0.20, 0.36, 1.0)))
        anchor.add(cjguiComposableText(9001, "complex-mixed-primary-anchor-copy",
            "锚点对象 ${anchorRowId}；结构变更=${changedStructure}",
            CjguiComposableUiStyle(fontSize: 11.0, fontFamily: fontFamily)))
        host.add(anchor)
        return host
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == 3 && event.node.resourceId == documentId) {
            return CjguiComposableUiDispatchResult(workspace.replaceProjectionTextFromHuman(documentId, event.text).applied)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    // This is a normal declaration change: delete the previous first scope,
    // reverse surviving rows, then anchor the layer at the new first stable
    // item.  It exercises candidate identity/reference resolution rather than
    // retaining an index-derived native focus scope.
    func deleteFirstAndReorderForProbe(): Bool {
        if (rowIds.size < 3) {
            return false
        }
        rowIds.remove(at: 0)
        let reordered = ArrayList<Int64>()
        var index = rowIds.size
        while (index > 0) {
            index -= 1
            reordered.add(rowIds[index])
        }
        rowIds = reordered
        anchorRowId = rowIds[0]
        changedStructure = true
        localRevision = localRevision.saturatingAdd(1)
        return true
    }

    func toggleFontForProbe(): Unit {
        usesMonospacedFont = !usesMonospacedFont
        localRevision = localRevision.saturatingAdd(1)
    }

    // Insert a new declaration after the deletion/reorder, leaving the anchor
    // on its surviving semantic row.  This covers both directions of dynamic
    // structure change in the real window path.
    func insertProbeRowForProbe(): Bool {
        if (!changedStructure || insertedProbeRow) {
            return false
        }
        rowIds.add(64)
        insertedProbeRow = true
        localRevision = localRevision.saturatingAdd(1)
        return true
    }

    func currentAnchorRowId(): Int64 { return anchorRowId }
    func structureChanged(): Bool { return changedStructure }
    func probeRowInserted(): Bool { return insertedProbeRow }
    func monospacedFontEnabled(): Bool { return usesMonospacedFont }
}

private class ComplexMixedSecondaryController <: CjguiComposableUiController {
    private let workspace: CjguiTextDocumentWorkspace
    private let documentId: Int64

    init(workspace: CjguiTextDocumentWorkspace, documentId: Int64) {
        this.workspace = workspace
        this.documentId = documentId
    }

    public func uiSceneVersion(): Int64 {
        if (let Some(snapshot) <- workspace.documentSnapshot(documentId)) {
            return snapshot.version
        }
        return 0
    }

    public func buildUi(): CjguiComposableUiNode {
        let snapshot = if (let Some(value) <- workspace.documentSnapshot(documentId)) {
            value
        } else {
            CjguiTextDocumentSnapshot(documentId, "B 已关闭", "", 0)
        }
        let root = cjguiComposableVertical(1, "complex-mixed-secondary-root", CjguiComposableUiStyle(padding: 12, gap: 8))
        root.add(cjguiComposableTextInput(2, "complex-mixed-secondary-input", snapshot.title, snapshot.content,
            documentId, CjguiComposableUiStyle(fixedHeight: 32), fieldId: "secondaryContent",
            operationActionName: "REPLACE_RANGE", operationResourceId: documentId, displayValueRole: "document"))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == 2 && event.node.resourceId == documentId) {
            return CjguiComposableUiDispatchResult(workspace.replaceProjectionTextFromHuman(documentId, event.text).applied)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func complexMixedAuthorization(): CjguiSharedOperationExternalAuthorization {
    let documents = ArrayList<Int64>([COMPLEX_MIXED_PRIMARY_DOCUMENT_ID, COMPLEX_MIXED_SECONDARY_DOCUMENT_ID])
    return CjguiSharedOperationExternalAuthorization(
        "cjgui-complex-mixed-probe", "cjgui-complex-mixed-probe-20260914",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("GET_WINDOW_PROGRESS", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("GET_WINDOW_INTERACTION", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("GET_WINDOW_TARGETS", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("GET_WINDOW_CONTEXT", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("READ_RANGE", documents, false),
            CjguiSharedOperationExternalActionScope("REPLACE_RANGES",
                ArrayList<Int64>([COMPLEX_MIXED_PRIMARY_DOCUMENT_ID]), false)
        ])
    )
}

private func documentVersion(workspace: CjguiTextDocumentWorkspace, documentId: Int64): Int64 {
    if (let Some(snapshot) <- workspace.documentSnapshot(documentId)) {
        return snapshot.version
    }
    return -1
}

private func editSecondaryThroughAppKit(window: CjguiComposableUiWindow, value: String): Bool {
    let nativeText = unsafe { LibC.mallocCString(value) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (text = nativeText.asResource()) {
        status = unsafe {
            // The root is scene index 0 and B's editable input is index 1.
            cjgui_internal_renderer_test_edit_composable_text(window.testSessionToken(), 1u32, text.value)
        }
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

private func resizePrimaryThroughAppKit(window: CjguiComposableUiWindow): Bool {
    var resizeVersion: UInt64 = 0u64
    let status = unsafe {
        cjgui_internal_renderer_test_resize_composable_window(window.testSessionToken(), inout resizeVersion)
    }
    return status == CJGUI_INTERNAL_RENDERER_OK && resizeVersion > 0u64
}

private func buildPassCount(application: CjguiMacosApplication, identifier: CjguiMacosApplicationWindowIdentifier): Int64 {
    if (let Some(window) <- application.window(identifier)) {
        return window.windowProjection().buildPassCount
    }
    return -1
}

private func submissionCount(application: CjguiMacosApplication, identifier: CjguiMacosApplicationWindowIdentifier): Int64 {
    if (let Some(window) <- application.window(identifier)) {
        return window.windowProjection().nativeSubmissionCount
    }
    return -1
}

private class ComplexMixedImagePipelineStats {
    let status: Int32
    let launches: UInt64
    let peakInFlight: UInt32
    let peakPending: UInt32

    init(status: Int32, launches: UInt64, peakInFlight: UInt32, peakPending: UInt32) {
        this.status = status
        this.launches = launches
        this.peakInFlight = peakInFlight
        this.peakPending = peakPending
    }
}

private func imagePipelineStats(window: CjguiComposableUiWindow): ComplexMixedImagePipelineStats {
    var resolveMicros: UInt64 = 0u64
    var cacheHits: UInt64 = 0u64
    var launches: UInt64 = 0u64
    var asyncMicros: UInt64 = 0u64
    var peakInFlight: UInt32 = 0u32
    var peakPending: UInt32 = 0u32
    var cacheBytes: UInt64 = 0u64
    var completions: UInt64 = 0u64
    let status = unsafe { cjgui_internal_renderer_test_composable_image_pipeline_stats(
        window.testSessionToken(), inout resolveMicros, inout cacheHits, inout launches, inout asyncMicros,
        inout peakInFlight, inout peakPending, inout cacheBytes, inout completions) }
    return ComplexMixedImagePipelineStats(status, launches, peakInFlight, peakPending)
}

private func runComplexMixedApplicationProbe(): Bool {
    let imagePath = if (let Some(value) <- getVariable("CJGUI_COMPLEX_MIXED_IMAGE_PATH")) { value } else { "" }
    if (imagePath.size == 0) {
        getStdErr().writeln("CJGUI_COMPLEX_MIXED_IMAGE_PATH is required")
        return false
    }
    let primary = CjguiTextDocument(COMPLEX_MIXED_PRIMARY_DOCUMENT_ID, "A 屏外批量文档", complexMixedInitialContent())
    let secondary = CjguiTextDocument(COMPLEX_MIXED_SECONDARY_DOCUMENT_ID, "B 原生输入文档", "B initial")
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([primary, secondary]))
    let application = CjguiMacosApplication(maximumWindowCount: 2)
    let primaryController = ComplexMixedPrimaryController(workspace, COMPLEX_MIXED_PRIMARY_DOCUMENT_ID)
    let secondaryController = ComplexMixedSecondaryController(workspace, COMPLEX_MIXED_SECONDARY_DOCUMENT_ID)
    let configuration = CjguiMacosApplicationWindowConfiguration("CJGUI complex mixed", 560u32, 260u32)
    let openedPrimary = application.openWindow(primaryController, configuration: configuration)
    let openedSecondary = application.openWindow(secondaryController, configuration: configuration)
    if (!openedPrimary.didOpen || !openedSecondary.didOpen) {
        application.close()
        return false
    }
    if (let Some(primaryIdentifier) <- openedPrimary.identifier) {
        if (let Some(secondaryIdentifier) <- openedSecondary.identifier) {
            let connection = CjguiSharedOperationExternalConnection(workspace, complexMixedAuthorization(), workspace)
            if (!connection.enableTargetedContextReads(workspace) || !connection.enableRangeReads(workspace) ||
                !connection.enableWindowProjectionTargetReads(application) ||
                !connection.enableWindowProgressTargetReads(application) || !application.attachExternalConnection(connection)) {
                application.close()
                return false
            }
            if (let Some(primaryWindow) <- application.window(primaryIdentifier)) {
                let token = primaryWindow.testSessionToken()
                if (unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(token, 1u8) } !=
                    CJGUI_INTERNAL_RENDERER_OK) {
                    application.close()
                    return false
                }
                var requestOrdinal: Int64 = 0
                var queuedAll = true
                while (requestOrdinal < COMPLEX_MIXED_IMAGE_REQUEST_COUNT) {
                    let request = primaryWindow.prepareImageResource(imagePath,
                        "complex-mixed-image-pressure-${requestOrdinal}", requestOrdinal + 1)
                    queuedAll = queuedAll && request.state == "loading"
                    requestOrdinal += 1
                }
                let queuedStats = imagePipelineStats(primaryWindow)
                if (!queuedAll || queuedStats.status != CJGUI_INTERNAL_RENDERER_OK ||
                    queuedStats.peakPending != UInt32(COMPLEX_MIXED_IMAGE_REQUEST_COUNT) || queuedStats.launches != 0u64) {
                    application.close()
                    return false
                }
                println("CJGUI_COMPLEX_MIXED_IMAGE_QUEUED requests=${COMPLEX_MIXED_IMAGE_REQUEST_COUNT} pending_peak=${queuedStats.peakPending} launches=${queuedStats.launches}")
                getStdOut().flush()
            } else {
                application.close()
                return false
            }
            if (let Some(info) <- connection.connectionInfo()) {
                println("CJGUI_COMPLEX_MIXED_READY DESCRIPTOR_PATH ${info.descriptorPath}")
                println("CJGUI_COMPLEX_MIXED_READY PRIMARY_TARGET ${primaryIdentifier.value}")
                println("CJGUI_COMPLEX_MIXED_READY SECONDARY_TARGET ${secondaryIdentifier.value}")
                getStdOut().flush()
            } else {
                application.close()
                return false
            }
            let started = MonoTime.now()
            var lastPrimaryVersion = documentVersion(workspace, COMPLEX_MIXED_PRIMARY_DOCUMENT_ID)
            var emittedSecondaryVersion: Int64 = 0
            var nativeInputRequests: Int64 = 0
            var resizeObserved = false
            var finalReady = false
            var idleBuildPrimary: Int64 = -1
            var idleSubmitPrimary: Int64 = -1
            var idleBuildSecondary: Int64 = -1
            var idleSubmitSecondary: Int64 = -1
            var imageGateReleased = false
            var finalReadyStarted = MonoTime.now()
            var passed = lastPrimaryVersion == 0 && documentVersion(workspace, COMPLEX_MIXED_SECONDARY_DOCUMENT_ID) == 0
            while (passed && application.isOpen() && (MonoTime.now() - started).toMilliseconds() < 30000) {
                let turn = application.pumpOneTurn(turnBudgetMs: 4u32)
                if (!turn.isOpen) {
                    passed = false
                    break
                }
                let primaryVersion = documentVersion(workspace, COMPLEX_MIXED_PRIMARY_DOCUMENT_ID)
                if (primaryVersion < lastPrimaryVersion || primaryVersion > COMPLEX_MIXED_EXPECTED_BATCHES) {
                    passed = false
                    break
                }
                if (primaryVersion > lastPrimaryVersion) {
                    // The external runner waits for every public response, so
                    // one accepted batch must advance exactly one document
                    // version. A coalesced GET must not appear here.
                    if (primaryVersion != lastPrimaryVersion + 1) {
                        passed = false
                        break
                    }
                    lastPrimaryVersion = primaryVersion
                    // This follows the first descriptor-authorized write and
                    // happens immediately before B's real AppKit input in the
                    // same application turn.  It turns the earlier held queue
                    // into actual MetalKit work without pretending a held gate
                    // was already an in-flight decoder.
                    if (!imageGateReleased && primaryVersion == 1) {
                        if (let Some(primaryWindow) <- application.window(primaryIdentifier)) {
                            let token = primaryWindow.testSessionToken()
                            let released = unsafe {
                                cjgui_internal_renderer_test_set_composable_image_launch_gate(token, 0u8) }
                            let nudge = primaryWindow.prepareImageResource(imagePath, "complex-mixed-image-pressure-0", 1)
                            if (released != CJGUI_INTERNAL_RENDERER_OK || nudge.state != "loading") {
                                passed = false
                                break
                            }
                            imageGateReleased = true
                        } else {
                            passed = false
                            break
                        }
                    }
                    if (primaryVersion == 10 && !primaryController.deleteFirstAndReorderForProbe()) {
                        passed = false
                        break
                    }
                    if (primaryVersion == 15 && !primaryController.insertProbeRowForProbe()) {
                        passed = false
                        break
                    }
                    if (primaryVersion == 20) {
                        primaryController.toggleFontForProbe()
                        if (let Some(primaryWindow) <- application.window(primaryIdentifier)) {
                            resizeObserved = resizePrimaryThroughAppKit(primaryWindow)
                        }
                        if (!resizeObserved) {
                            passed = false
                            break
                        }
                    }
                    if (let Some(secondaryWindow) <- application.window(secondaryIdentifier)) {
                        if (!editSecondaryThroughAppKit(secondaryWindow, "B native input after A batch ${primaryVersion}")) {
                            passed = false
                            break
                        }
                        nativeInputRequests += 1
                    } else {
                        passed = false
                        break
                    }
                }
                let secondaryVersion = documentVersion(workspace, COMPLEX_MIXED_SECONDARY_DOCUMENT_ID)
                if (secondaryVersion > emittedSecondaryVersion) {
                    if (secondaryVersion != emittedSecondaryVersion + 1 || secondaryVersion > lastPrimaryVersion) {
                        passed = false
                        break
                    }
                    emittedSecondaryVersion = secondaryVersion
                    println(
                        "CJGUI_COMPLEX_MIXED_SAMPLE sample=${secondaryVersion} primary_version=${lastPrimaryVersion} secondary_version=${secondaryVersion} native_input_requests=${nativeInputRequests} served_actions=${turn.externalActionCount} anchor_row=${primaryController.currentAnchorRowId()} structure_changed=${primaryController.structureChanged()} inserted_row=${primaryController.probeRowInserted()} monospaced=${primaryController.monospacedFontEnabled()} resize_observed=${resizeObserved}")
                }
                if (!finalReady && emittedSecondaryVersion == COMPLEX_MIXED_EXPECTED_BATCHES && lastPrimaryVersion ==
                    COMPLEX_MIXED_EXPECTED_BATCHES && nativeInputRequests == COMPLEX_MIXED_EXPECTED_BATCHES &&
                    primaryController.structureChanged() && primaryController.probeRowInserted() &&
                    primaryController.monospacedFontEnabled() && resizeObserved) {
                    idleBuildPrimary = buildPassCount(application, primaryIdentifier)
                    idleSubmitPrimary = submissionCount(application, primaryIdentifier)
                    idleBuildSecondary = buildPassCount(application, secondaryIdentifier)
                    idleSubmitSecondary = submissionCount(application, secondaryIdentifier)
                    if (idleBuildPrimary < 1 || idleSubmitPrimary < 1 || idleBuildSecondary < 1 || idleSubmitSecondary < 1) {
                        passed = false
                        break
                    }
                    finalReady = true
                    finalReadyStarted = MonoTime.now()
                    println("CJGUI_COMPLEX_MIXED_READY_FOR_FINAL_READS primary_version=${lastPrimaryVersion} secondary_version=${emittedSecondaryVersion} primary_target=${primaryIdentifier.value} secondary_target=${secondaryIdentifier.value}")
                    getStdOut().flush()
                }
                // Continue serving read-only public calls after all writes,
                // then prove they neither retain queued mutations nor rebuild
                // either completed projection.
                if (finalReady && (MonoTime.now() - finalReadyStarted).toMilliseconds() >= 2000) {
                    let stable = buildPassCount(application, primaryIdentifier) == idleBuildPrimary &&
                        submissionCount(application, primaryIdentifier) == idleSubmitPrimary &&
                        buildPassCount(application, secondaryIdentifier) == idleBuildSecondary &&
                        submissionCount(application, secondaryIdentifier) == idleSubmitSecondary
                    let diagnostics = connection.transportDiagnostics()
                    let activeClients = if (let Some(value) <- diagnostics) { value.activeClientCount } else { -1 }
                    let readyRequests = if (let Some(value) <- diagnostics) { value.readyRequestHighWater } else { -1 }
                    let imageStats = if (let Some(primaryWindow) <- application.window(primaryIdentifier)) {
                        imagePipelineStats(primaryWindow)
                    } else {
                        ComplexMixedImagePipelineStats(-100, 0u64, 0u32, 0u32)
                    }
                    println(
                        "CJGUI_COMPLEX_MIXED_RESULT passed=${stable} primary_version=${lastPrimaryVersion} secondary_version=${emittedSecondaryVersion} native_input_requests=${nativeInputRequests} dynamic_structure=${primaryController.structureChanged()} dynamic_insertion=${primaryController.probeRowInserted()} anchor_row=${primaryController.currentAnchorRowId()} font_invalidated=${primaryController.monospacedFontEnabled()} native_resize=${resizeObserved} idle_build_delta=${buildPassCount(application, primaryIdentifier) - idleBuildPrimary},${buildPassCount(application, secondaryIdentifier) - idleBuildSecondary} idle_submit_delta=${submissionCount(application, primaryIdentifier) - idleSubmitPrimary},${submissionCount(application, secondaryIdentifier) - idleSubmitSecondary} active_clients=${activeClients} ready_high_water=${readyRequests} image_gate_released=${imageGateReleased} image_launches=${imageStats.launches} image_peak_inflight=${imageStats.peakInFlight} image_peak_pending=${imageStats.peakPending}")
                    passed = stable && activeClients == 0 && readyRequests >= 1 && imageGateReleased &&
                        imageStats.status == CJGUI_INTERNAL_RENDERER_OK && imageStats.launches == UInt64(COMPLEX_MIXED_IMAGE_REQUEST_COUNT) &&
                        imageStats.peakInFlight <= 4u32 && imageStats.peakPending == UInt32(COMPLEX_MIXED_IMAGE_REQUEST_COUNT)
                    break
                }
            }
            application.close()
            let reclaimed = internalRendererOccupiedSessionCount() == 0u32
            println("CJGUI_COMPLEX_MIXED_RECLAIMED sessions_zero=${reclaimed}")
            return passed && finalReady && reclaimed
        }
    }
    application.close()
    return false
}

main(args: Array<String>): Int64 {
    if (args.size == 1 && args[0] == "--complex-mixed") {
        return if (runComplexMixedApplicationProbe()) { 0 } else { 1 }
    }
    getStdErr().writeln("usage: complex_scene_application_mixed_probe --complex-mixed")
    return 2
}
