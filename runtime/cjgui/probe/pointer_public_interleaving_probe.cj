package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*
import std.fs.*
import std.overflow.*

private let DOCUMENT_A: Int64 = 7101
private let DOCUMENT_B: Int64 = 7102

/// This probe uses the production Cangjie owner for both public operations
/// and human pointer changes.  The native pointer/key seams merely stand in
/// for AppKit delivery; neither stores document or preview-limit state.
foreign {
    func cjgui_internal_renderer_test_send_composable_pointer(
        session: UInt64, phase: UInt32, pointX: Float32, pointY: Float32
    ): Int32
    func cjgui_internal_renderer_test_composable_interaction_stats(
        session: UInt64, outPendingInteractionCount: CPointer<UInt32>, outMaxPendingInteractionCount: CPointer<UInt32>,
        outAccessibilityNotificationCount: CPointer<UInt64>
    ): Int32
}

private class PointerPublicInterleaveController <: CjguiComposableUiController &
    CjguiComposableUiPointerCaptureVersionProvider {
    private let workspace: CjguiTextDocumentWorkspace
    private let documentId: Int64
    private let semanticPrefix: String
    private var localRevision: Int64
    private var beganCount: Int64
    private var updateCount: Int64
    private var endCount: Int64
    private var cancelCount: Int64

    init(workspace: CjguiTextDocumentWorkspace, documentId: Int64, semanticPrefix: String) {
        this.workspace = workspace
        this.documentId = documentId
        this.semanticPrefix = semanticPrefix
        this.localRevision = 1
        this.beganCount = 0
        this.updateCount = 0
        this.endCount = 0
        this.cancelCount = 0
    }

    public func uiSceneVersion(): Int64 {
        return workspace.previewLimitVersionForDocument(documentId).saturatingAdd(localRevision)
    }

    public func pointerCaptureVersion(node: CjguiComposableUiLayoutNode): Int64 {
        if (node.nodeKind == CJGUI_COMPOSABLE_UI_SLIDER && node.resourceId == documentId) {
            return workspace.previewLimitVersionForDocument(documentId)
        }
        return uiSceneVersion()
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(documentId, "${semanticPrefix}-root", CjguiComposableUiStyle())
        root.add(cjguiComposableSlider(documentId + 10, "${semanticPrefix}-slider",
            workspace.previewLimitForDocument(documentId), 128, 512, 32,
            CjguiComposableUiStyle(growX: 1, fixedHeight: 28), operationActionName: "SET_PREVIEW_LIMIT",
            operationResourceId: documentId))
        root.add(cjguiComposableText(documentId + 11, "${semanticPrefix}-readback",
            "${semanticPrefix}=${workspace.previewLimitForDocument(documentId)}",
            CjguiComposableUiStyle(), resourceId: documentId, displayValueRole: "view"))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.node.nodeKind != CJGUI_COMPOSABLE_UI_SLIDER || event.node.resourceId != documentId) {
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.eventKind == 35) {
            let direction = if (event.text == "left" || event.text == "down") {
                -1
            } else if (event.text == "right" || event.text == "up") {
                1
            } else {
                0
            }
            if (direction == 0) {
                return CjguiComposableUiDispatchResult(false)
            }
            let value = CjguiComposableUiSliderGeometry.adjustValue(
                workspace.previewLimitForDocument(documentId), direction, event.node.pointerControlMinimum,
                event.node.pointerControlMaximum, event.node.pointerControlStep)
            let result = workspace.setPreviewLimitFromHuman(documentId, value)
            if (result.applied) { localRevision += 1 }
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN ||
            event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE ||
            event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_END) {
            let value = CjguiComposableUiSliderGeometry.valueForPointer(event.pointerX, event.node.bounds.x,
                event.node.bounds.width, event.node.pointerControlMinimum, event.node.pointerControlMaximum,
                event.node.pointerControlStep)
            let result = workspace.setPreviewLimitFromHuman(documentId, value)
            if (result.applied) { localRevision += 1 }
            if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN) {
                beganCount += 1
            } else if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE) {
                updateCount += 1
            } else {
                endCount += 1
            }
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_CANCEL) {
            cancelCount += 1
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
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

    public func begins(): Int64 { return beganCount }
    public func updates(): Int64 { return updateCount }
    public func ends(): Int64 { return endCount }
    public func cancels(): Int64 { return cancelCount }
}

private class PointerPublicInterleaveOptions {
    let unrelatedAckPath: String
    let sameAckPath: String
    init(unrelatedAckPath: String, sameAckPath: String) {
        this.unrelatedAckPath = unrelatedAckPath
        this.sameAckPath = sameAckPath
    }
}

private func optionsFromArgs(args: Array<String>): ?PointerPublicInterleaveOptions {
    var unrelatedAckPath = ""
    var sameAckPath = ""
    var index: Int64 = 0
    while (index < args.size) {
        if (args[index] == "--unrelated-ack" && index + 1 < args.size && unrelatedAckPath.size == 0) {
            unrelatedAckPath = args[index + 1]
            index += 2
        } else if (args[index] == "--same-ack" && index + 1 < args.size && sameAckPath.size == 0) {
            sameAckPath = args[index + 1]
            index += 2
        } else {
            return None
        }
    }
    if (unrelatedAckPath.size == 0 || sameAckPath.size == 0) {
        return None
    }
    return Some(PointerPublicInterleaveOptions(unrelatedAckPath, sameAckPath))
}

private func authorization(): CjguiSharedOperationExternalAuthorization {
    let targets = ArrayList<Int64>([DOCUMENT_A, DOCUMENT_B])
    return CjguiSharedOperationExternalAuthorization("pointer-public-interleave-agent",
        "pointer-public-interleave-20260914", ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("SET_PREVIEW_LIMIT", targets, false)
        ]))
}

private func startCapture(application: CjguiMacosApplication, session: UInt64,
    controller: PointerPublicInterleaveController): Bool {
    let status = unsafe {
        // The slider occupies the top 28 points of its zero-padding root.
        cjgui_internal_renderer_test_send_composable_pointer(session, 1u32, 48.0f32, 14.0f32)
    }
    let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
    return status == CJGUI_INTERNAL_RENDERER_OK && turn.isOpen && controller.begins() >= 1
}

/// Enqueue one pointer update immediately before every shared application
/// turn until a real UDS request is serviced.  `overlap=true` means the same
/// `pumpOneTurn` admitted a public request after that pointer event was
/// already in the native FIFO; it is not a sequential-batch claim.
private func driveBurstUntilExternalServiced(application: CjguiMacosApplication, session: UInt64,
    ackPath: String, label: String): Bool {
    var rounds: Int64 = 0
    var overlap = false
    var lastExternalActions: Int64 = 0
    while (rounds < 160 && !overlap) {
        // Re-enqueue the current value while waiting. This is still a real
        // pointer burst in the native FIFO, but it deliberately avoids
        // racing the UDS caller's snapshot/CAS token with unrelated local
        // value changes before the scheduler can admit that caller.
        let x = 48.0f32
        let update = unsafe {
            cjgui_internal_renderer_test_send_composable_pointer(session, 2u32, x, 14.0f32)
        }
        if (update != CJGUI_INTERNAL_RENDERER_OK) {
            println("CJGUI_POINTER_PUBLIC_INTERLEAVE_PHASE ${label} pointer_enqueue_failed_round=${rounds}")
            return false
        }
        let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
        lastExternalActions = turn.externalActionCount
        if (turn.externalActionCount > 0) {
            overlap = true
        }
        rounds += 1
    }
    var acknowledgementTurns: Int64 = 0
    while (!exists(ackPath) && acknowledgementTurns < 80) {
        let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
        acknowledgementTurns += 1
    }
    println("CJGUI_POINTER_PUBLIC_INTERLEAVE_PHASE ${label} queued_pointer_rounds=${rounds} external_actions_same_turn=${lastExternalActions} overlap=${overlap} acknowledgement_seen=${exists(ackPath)}")
    return overlap && exists(ackPath)
}

private func interactionHighWater(session: UInt64): Int64 {
    var pending: UInt32 = 0u32
    var highWater: UInt32 = 0u32
    var notifications: UInt64 = 0u64
    let status = unsafe {
        cjgui_internal_renderer_test_composable_interaction_stats(session, inout pending, inout highWater,
            inout notifications)
    }
    return if (status == CJGUI_INTERNAL_RENDERER_OK) { Int64(highWater) } else { -1 }
}

private func run(options: PointerPublicInterleaveOptions): Int64 {
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(DOCUMENT_A, "pointer-A", "A"),
        CjguiTextDocument(DOCUMENT_B, "pointer-B", "B")
    ]))
    let controllerA = PointerPublicInterleaveController(workspace, DOCUMENT_A, "pointer-a")
    let controllerB = PointerPublicInterleaveController(workspace, DOCUMENT_B, "pointer-b")
    let application = CjguiMacosApplication(maximumWindowCount: 2)
    let configuration = CjguiMacosApplicationWindowConfiguration("CJGUI Pointer Public Interleave", 480u32, 180u32)
    let openedA = application.openWindow(controllerA, configuration: configuration)
    let openedB = application.openWindow(controllerB, configuration: configuration)
    let connection = CjguiSharedOperationExternalConnection(workspace, authorization(), workspace)
    if (!openedA.didOpen || !openedB.didOpen || !connection.enableTargetedContextReads(workspace) ||
        !application.attachExternalConnection(connection)) {
        application.close()
        return 1
    }
    if (!application.isOpen()) {
        application.close()
        return 1
    }
    if (let None <- connection.connectionInfo()) {
        application.close()
        return 1
    }
    if (let Some(info) <- connection.connectionInfo()) {
        println("CJGUI_POINTER_PUBLIC_INTERLEAVE_READY DESCRIPTOR_PATH ${info.descriptorPath}")
        getStdOut().flush()
    }
    if (let None <- openedA.identifier) {
        application.close()
        return 1
    }
    if (let None <- openedB.identifier) {
        application.close()
        return 1
    }
    let identifierA = if (let Some(value) <- openedA.identifier) { value } else {
        application.close()
        return 1
    }
    let identifierB = if (let Some(value) <- openedB.identifier) { value } else {
        application.close()
        return 1
    }
    let windowA = if (let Some(value) <- application.window(identifierA)) { value } else {
        application.close()
        return 1
    }
    let windowB = if (let Some(value) <- application.window(identifierB)) { value } else {
        application.close()
        return 1
    }
    let sessionA = windowA.testSessionToken()

    let bSceneBefore = windowB.windowProjection().sceneVersion
    if (!startCapture(application, sessionA, controllerA)) {
        application.close()
        return 1
    }
    let unrelatedVersionBefore = workspace.contextSnapshot().version
    println("CJGUI_POINTER_PUBLIC_INTERLEAVE_PHASE UNRELATED_READY version_before_external=${unrelatedVersionBefore}")
    getStdOut().flush()
    if (!driveBurstUntilExternalServiced(application, sessionA, options.unrelatedAckPath, "UNRELATED")) {
        application.close()
        return 1
    }
    let unrelatedEnd = unsafe {
        cjgui_internal_renderer_test_send_composable_pointer(sessionA, 3u32, 216.0f32, 14.0f32)
    }
    let unrelatedEndTurn = application.pumpOneTurn(turnBudgetMs: 16u32)
    let bSceneAfter = windowB.windowProjection().sceneVersion
    let unrelatedVersionAfter = workspace.contextSnapshot().version
    let unrelatedPassed = unrelatedEnd == CJGUI_INTERNAL_RENDERER_OK && unrelatedEndTurn.isOpen &&
        controllerA.ends() >= 1 && controllerA.cancels() == 0 && bSceneAfter > bSceneBefore &&
        workspace.previewLimitForDocument(DOCUMENT_B) == 256
    println("CJGUI_POINTER_PUBLIC_INTERLEAVE_RESULT UNRELATED order=pointer_begin>external_B>pointer_end version_before=${unrelatedVersionBefore} version_after=${unrelatedVersionAfter} queue_high_water=${interactionHighWater(sessionA)} owner_updates=${controllerA.updates()} owner_end=${controllerA.ends()} owner_cancel=${controllerA.cancels()} b_scene_before=${bSceneBefore} b_scene_after=${bSceneAfter} b_value=${workspace.previewLimitForDocument(DOCUMENT_B)} passed=${unrelatedPassed}")
    getStdOut().flush()
    if (!unrelatedPassed) {
        application.close()
        return 1
    }

    let priorCancels = controllerA.cancels()
    let priorEnds = controllerA.ends()
    if (!startCapture(application, sessionA, controllerA)) {
        application.close()
        return 1
    }
    let sameVersionBefore = workspace.contextSnapshot().version
    println("CJGUI_POINTER_PUBLIC_INTERLEAVE_PHASE SAME_READY version_before_external=${sameVersionBefore}")
    getStdOut().flush()
    if (!driveBurstUntilExternalServiced(application, sessionA, options.sameAckPath, "SAME")) {
        application.close()
        return 1
    }
    let valueAfterExternal = workspace.previewLimitForDocument(DOCUMENT_A)
    let oldMove = unsafe {
        cjgui_internal_renderer_test_send_composable_pointer(sessionA, 2u32, 448.0f32, 14.0f32)
    }
    let oldEnd = unsafe {
        cjgui_internal_renderer_test_send_composable_pointer(sessionA, 3u32, 448.0f32, 14.0f32)
    }
    let oldTurn = application.pumpOneTurn(turnBudgetMs: 16u32)
    let sameVersionAfter = workspace.contextSnapshot().version
    let samePassed = valueAfterExternal == 416 && workspace.previewLimitForDocument(DOCUMENT_A) == 416 &&
        controllerA.cancels() == priorCancels + 1 && controllerA.ends() == priorEnds &&
        oldMove != CJGUI_INTERNAL_RENDERER_OK && oldEnd != CJGUI_INTERNAL_RENDERER_OK && oldTurn.isOpen
    println("CJGUI_POINTER_PUBLIC_INTERLEAVE_RESULT SAME order=pointer_begin>external_A>old_move_old_end version_before=${sameVersionBefore} version_after=${sameVersionAfter} queue_high_water=${interactionHighWater(sessionA)} owner_end_before=${priorEnds} owner_end_after=${controllerA.ends()} owner_cancel_before=${priorCancels} owner_cancel_after=${controllerA.cancels()} external_value=${valueAfterExternal} old_move_status=${oldMove} old_end_status=${oldEnd} final_value=${workspace.previewLimitForDocument(DOCUMENT_A)} passed=${samePassed}")
    if (let Some(diagnostics) <- connection.transportDiagnostics()) {
        println("CJGUI_POINTER_PUBLIC_INTERLEAVE_TRANSPORT accepted_clients=${diagnostics.acceptedClientCount} accepted_high_water=${diagnostics.acceptedClientHighWater} ready_high_water=${diagnostics.readyRequestHighWater} ready_bytes_high_water=${diagnostics.readyRequestBytesHighWater}")
    }
    getStdOut().flush()
    application.close()
    return if (samePassed) { 0 } else { 1 }
}

main(args: Array<String>): Int64 {
    if (let Some(options) <- optionsFromArgs(args)) {
        return run(options)
    }
    getStdErr().writeln("usage: pointer_public_interleaving_probe --unrelated-ack PATH --same-ack PATH")
    return 2
}
