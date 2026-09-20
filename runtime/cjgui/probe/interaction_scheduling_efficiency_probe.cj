package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*
import std.fs.*
import std.overflow.*
import std.time.*

private let DOCUMENT_A: Int64 = 7301
private let DOCUMENT_B: Int64 = 7302
private let SCALE_SAMPLE_COUNT: Int64 = 30
private let MAX_EXTERNAL_WAIT_ROUNDS: Int64 = 80
// The application turn's nominal event-wait budget is 16 ms, but owner work
// already admitted before that wait can legitimately consume it. This probe
// gives the fixed 64-event backlog plus real UDS admission a 64 ms wall-clock
// service bound; it is a test acceptance limit, never scheduler pacing.
private let MAX_OVERLAP_OWNER_SERVICE_MS: Int64 = 64

foreign {
    func cjgui_internal_renderer_test_send_composable_mouse(
        session: UInt64, phase: UInt32, pointX: Float32, pointY: Float32
    ): Int32
    func cjgui_internal_renderer_test_enqueue_composable_event(
        session: UInt64, nodeIndex: UInt32, eventKind: UInt32, text: CString
    ): Int32
    func cjgui_internal_renderer_test_composable_interaction_stats(
        session: UInt64, outPendingInteractionCount: CPointer<UInt32>,
        outMaxPendingInteractionCount: CPointer<UInt32>, outAccessibilityNotificationCount: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_scene_update_stats(
        session: UInt64, outCommittedNodeCount: CPointer<UInt32>, outNodeUpdateCount: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_interaction_trace(
        session: UInt64, outPendingInteractionCount: CPointer<UInt32>, outLastEnqueuedKind: CPointer<UInt32>,
        outLastEnqueuedNodeId: CPointer<UInt64>, outLastEnqueuedProjectionVersion: CPointer<UInt64>,
        outLastPumpedKind: CPointer<UInt32>, outLastPumpedNodeId: CPointer<UInt64>,
        outLastPumpedProjectionVersion: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_set_composable_present_failures(
        session: UInt64, failureCount: UInt32
    ): Int32
}

/// A is a real pressable action. Its action name is derived from A's owner
/// version so an external A write is a genuine rebind, while an external B
/// write is unrelated to A's accepted scene.
private class SchedulingAController <: CjguiComposableUiController {
    private let workspace: CjguiTextDocumentWorkspace
    private let scale: Int64
    private var actionCountValue: Int64
    private var genericCountValue: Int64

    init(workspace: CjguiTextDocumentWorkspace, scale: Int64) {
        this.workspace = workspace
        this.scale = scale
        this.actionCountValue = 0
        this.genericCountValue = 0
    }

    public func uiSceneVersion(): Int64 {
        return workspace.previewLimitVersionForDocument(DOCUMENT_A)
    }

    private func actionName(): String {
        return "A_ACTION_${workspace.previewLimitForDocument(DOCUMENT_A)}"
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "scheduling-a-root",
            CjguiComposableUiStyle(fixedWidth: 280, fixedHeight: 1200, gap: 0,
                background: CjguiComposableUiColor(0.08, 0.10, 0.15, 1.0)))
        root.add(cjguiComposableButton(2, "scheduling-a-action", "A", actionName(), DOCUMENT_A,
            CjguiComposableUiStyle(fixedWidth: 280, fixedHeight: 28,
                background: CjguiComposableUiColor(0.12, 0.20, 0.34, 1.0),
                textColor: CjguiComposableUiColor(0.92, 0.96, 1.0, 1.0)),
            operationActionName: "SET_PREVIEW_LIMIT", operationResourceId: DOCUMENT_A,
            interactionStyle: CjguiComposableUiInteractionStyle(
                hover: CjguiComposableUiPaintStyle(background: Some(CjguiComposableUiColor(0.28, 0.50, 0.88, 1.0))),
                pressed: CjguiComposableUiPaintStyle(background: Some(CjguiComposableUiColor(0.10, 0.72, 0.42, 1.0))),
                focused: CjguiComposableUiPaintStyle(border: Some(CjguiComposableUiColor(0.94, 0.84, 0.20, 1.0)),
                    borderWidth: Some(2)))))
        // B is an unrelated paint target in the same accepted scene. The
        // interleaving sample hovers it while A remains physically pressed.
        root.add(cjguiComposableButton(3, "scheduling-a-unrelated-b", "B", "B_PAINT",
            DOCUMENT_B, CjguiComposableUiStyle(fixedWidth: 280, fixedHeight: 28,
                background: CjguiComposableUiColor(0.16, 0.17, 0.22, 1.0)),
            interactionStyle: CjguiComposableUiInteractionStyle(
                hover: CjguiComposableUiPaintStyle(background: Some(CjguiComposableUiColor(0.26, 0.40, 0.70, 1.0))))))
        var index: Int64 = 0
        while (index < scale) {
            root.add(cjguiComposableText(10000 + index, "scheduling-a-scale-${index}",
                "A scale ${scale} sample ${index}", CjguiComposableUiStyle(fixedHeight: 12)))
            index += 1
        }
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.semanticId == "scheduling-a-action") {
            // The old action must not reach the owner after an external A
            // rebind. The window's identity check should reject it first; this
            // guard is the consumer-side fail-closed boundary.
            if (event.node.actionName != actionName()) {
                return CjguiComposableUiDispatchResult(false)
            }
            actionCountValue += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.semanticId == "scheduling-a-unrelated-b") {
            genericCountValue += 1
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

    public func actionCount(): Int64 { return actionCountValue }
    public func genericCount(): Int64 { return genericCountValue }
    public func ownerValue(): Int64 { return workspace.previewLimitForDocument(DOCUMENT_A) }
    public func ownerVersion(): Int64 { return workspace.previewLimitVersionForDocument(DOCUMENT_A) }
}

/// B receives one ordinary generic action per sample and a real public owner
/// write. Its scene is intentionally independent from A's owner version.
private class SchedulingBController <: CjguiComposableUiController {
    private let workspace: CjguiTextDocumentWorkspace
    private var ordinaryCountValue: Int64

    init(workspace: CjguiTextDocumentWorkspace) {
        this.workspace = workspace
        this.ordinaryCountValue = 0
    }

    public func uiSceneVersion(): Int64 {
        return workspace.previewLimitVersionForDocument(DOCUMENT_B)
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "scheduling-b-root",
            CjguiComposableUiStyle(fixedWidth: 260, fixedHeight: 120,
                background: CjguiComposableUiColor(0.94, 0.95, 0.97, 1.0)))
        root.add(cjguiComposableButton(2, "scheduling-b-input", "B ordinary input", "B_ORDINARY",
            DOCUMENT_B, CjguiComposableUiStyle(fixedWidth: 260, fixedHeight: 28,
                background: CjguiComposableUiColor(0.86, 0.88, 0.94, 1.0))))
        root.add(cjguiComposableText(3, "scheduling-b-owner-value",
            "B owner=${workspace.previewLimitForDocument(DOCUMENT_B)}",
            CjguiComposableUiStyle(fixedHeight: 22), resourceId: DOCUMENT_B, displayValueRole: "view"))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.semanticId == "scheduling-b-input") {
            ordinaryCountValue += 1
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

    public func ordinaryCount(): Int64 { return ordinaryCountValue }
    public func ownerVersion(): Int64 { return workspace.previewLimitVersionForDocument(DOCUMENT_B) }
}

private class SchedulingOptions {
    let ackDirectory: String
    let overlapOnly: Bool
    init(ackDirectory: String, overlapOnly!: Bool = false) {
        this.ackDirectory = ackDirectory
        this.overlapOnly = overlapOnly
    }
}

private func optionsFromArgs(args: Array<String>): ?SchedulingOptions {
    if (args.size == 2 && args[0] == "--ack-dir") {
        return Some(SchedulingOptions(args[1]))
    }
    if (args.size == 3 && args[0] == "--ack-dir" && args[2] == "--overlap-only") {
        return Some(SchedulingOptions(args[1], overlapOnly: true))
    }
    return None
}

private func authorization(): CjguiSharedOperationExternalAuthorization {
    let targets = ArrayList<Int64>([DOCUMENT_A, DOCUMENT_B])
    return CjguiSharedOperationExternalAuthorization("interaction-scheduling-agent",
        "interaction-scheduling-20260915", ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("SET_PREVIEW_LIMIT", targets, false)
        ]))
}

private class NativeStats {
    let status: Int32
    let committedNodes: UInt32
    let nodeUpdates: UInt64
    let pending: UInt32
    let highWater: UInt32

    init(status: Int32, committedNodes: UInt32, nodeUpdates: UInt64, pending: UInt32, highWater: UInt32) {
        this.status = status
        this.committedNodes = committedNodes
        this.nodeUpdates = nodeUpdates
        this.pending = pending
        this.highWater = highWater
    }
}

private func nativeStats(session: UInt64): NativeStats {
    var committedNodes: UInt32 = 0u32
    var nodeUpdates: UInt64 = 0u64
    let sceneStatus = unsafe {
        cjgui_internal_renderer_test_composable_scene_update_stats(session, inout committedNodes, inout nodeUpdates)
    }
    var pending: UInt32 = 0u32
    var highWater: UInt32 = 0u32
    var notifications: UInt64 = 0u64
    let interactionStatus = unsafe {
        cjgui_internal_renderer_test_composable_interaction_stats(session, inout pending, inout highWater,
            inout notifications)
    }
    return NativeStats(if (sceneStatus == CJGUI_INTERNAL_RENDERER_OK && interactionStatus == CJGUI_INTERNAL_RENDERER_OK) {
        CJGUI_INTERNAL_RENDERER_OK
    } else {
        CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    }, committedNodes, nodeUpdates, pending, highWater)
}

/// Test-only snapshot of native FIFO provenance.  It explains an unexpected
/// terminal delta without adding an event path or changing press routing.
private class NativeInteractionTrace {
    let status: Int32
    let pending: UInt32
    let lastEnqueuedKind: UInt32
    let lastEnqueuedNodeId: UInt64
    let lastPumpedKind: UInt32
    let lastPumpedNodeId: UInt64

    init(status: Int32, pending: UInt32, lastEnqueuedKind: UInt32, lastEnqueuedNodeId: UInt64,
        lastPumpedKind: UInt32, lastPumpedNodeId: UInt64) {
        this.status = status
        this.pending = pending
        this.lastEnqueuedKind = lastEnqueuedKind
        this.lastEnqueuedNodeId = lastEnqueuedNodeId
        this.lastPumpedKind = lastPumpedKind
        this.lastPumpedNodeId = lastPumpedNodeId
    }
}

private func nativeInteractionTrace(session: UInt64): NativeInteractionTrace {
    var pending: UInt32 = 0u32
    var lastEnqueuedKind: UInt32 = 0u32
    var lastEnqueuedNodeId: UInt64 = 0u64
    var lastEnqueuedProjectionVersion: UInt64 = 0u64
    var lastPumpedKind: UInt32 = 0u32
    var lastPumpedNodeId: UInt64 = 0u64
    var lastPumpedProjectionVersion: UInt64 = 0u64
    let status = unsafe {
        cjgui_internal_renderer_test_composable_interaction_trace(session, inout pending, inout lastEnqueuedKind,
            inout lastEnqueuedNodeId, inout lastEnqueuedProjectionVersion, inout lastPumpedKind,
            inout lastPumpedNodeId, inout lastPumpedProjectionVersion)
    }
    return NativeInteractionTrace(status, pending, lastEnqueuedKind, lastEnqueuedNodeId, lastPumpedKind,
        lastPumpedNodeId)
}

private class AckWaitResult {
    let seen: Bool
    let rounds: Int64
    let externalActions: Int64
    let elapsedNs: UInt64

    init(seen: Bool, rounds: Int64, externalActions: Int64, elapsedNs: UInt64) {
        this.seen = seen
        this.rounds = rounds
        this.externalActions = externalActions
        this.elapsedNs = elapsedNs
    }
}

/// One-shot overlap observation.  The native composable FIFO and the
/// Cangjie per-turn drain are both bounded at 64 events, so this probe does
/// not pretend that one pump is preemptible.  It records the exact atomic
/// interval instead: A has a full pending FIFO before the owner turn that
/// serves the real UDS burst, while B's ordinary event is observed in that
/// same application turn.
private class OverlapWaitResult {
    let seen: Bool
    let rounds: Int64
    let externalActions: Int64
    let firstExternalRound: Int64
    let firstExternalElapsedBeforeWaitMs: Int64
    let pendingBeforeExternal: UInt32
    let maxPending: UInt32
    let maxHighWater: UInt32
    let bOrdinaryDelta: Int64
    let bOwnerVersionDeltaAtFirstExternal: Int64
    let bOrdinaryEnqueued: Bool
    let queueOverflowObserved: Bool

    init(seen: Bool, rounds: Int64, externalActions: Int64, firstExternalRound: Int64,
        firstExternalElapsedBeforeWaitMs: Int64, pendingBeforeExternal: UInt32, maxPending: UInt32,
        maxHighWater: UInt32, bOrdinaryDelta: Int64, bOwnerVersionDeltaAtFirstExternal: Int64,
        bOrdinaryEnqueued: Bool, queueOverflowObserved: Bool) {
        this.seen = seen
        this.rounds = rounds
        this.externalActions = externalActions
        this.firstExternalRound = firstExternalRound
        this.firstExternalElapsedBeforeWaitMs = firstExternalElapsedBeforeWaitMs
        this.pendingBeforeExternal = pendingBeforeExternal
        this.maxPending = maxPending
        this.maxHighWater = maxHighWater
        this.bOrdinaryDelta = bOrdinaryDelta
        this.bOwnerVersionDeltaAtFirstExternal = bOwnerVersionDeltaAtFirstExternal
        this.bOrdinaryEnqueued = bOrdinaryEnqueued
        this.queueOverflowObserved = queueOverflowObserved
    }
}

/// Probe-only idle trace.  It records the first scheduler turn that retires a
/// session before the external client has performed any action, so lifecycle
/// diagnosis does not infer a cause from the later missing UDS descriptor.
private func waitForAck(application: CjguiMacosApplication, windowA: CjguiComposableUiWindow,
    windowB: CjguiComposableUiWindow, ackPath: String): AckWaitResult {
    let started = MonoTime.now()
    var rounds: Int64 = 0
    var externalActions: Int64 = 0
    while (!exists(ackPath) && rounds < MAX_EXTERNAL_WAIT_ROUNDS) {
        let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
        externalActions += turn.externalActionCount
        rounds += 1
        if (!turn.isOpen || !application.isOpen() || !windowA.isOpen() || !windowB.isOpen()) {
            println("CJGUI_INTERACTION_SCHEDULING_IDLE_TURN_FAILURE round=${rounds} application_open=${application.isOpen()} a_open=${windowA.isOpen()} b_open=${windowB.isOpen()} turn_open=${turn.isOpen} turn_windows=${turn.windowCount} turn_external_actions=${turn.externalActionCount} a_native_status=${windowA.nativeStatus()} b_native_status=${windowB.nativeStatus()} a_scene=${windowA.displayedSceneVersion()} b_scene=${windowB.displayedSceneVersion()}")
            getStdOut().flush()
        }
        if (!turn.isOpen) { break }
    }
    return AckWaitResult(exists(ackPath), rounds, externalActions,
        UInt64((MonoTime.now() - started).toNanoseconds()))
}

/// Waits for one real external burst while A already owns a bounded FIFO.
/// There is deliberately no producer loop here: the 64 A events are queued
/// once before READY and are drained by the one normal owner turn.  If the
/// external requests arrive later, the observation fails instead of
/// replenishing the queue after every turn and manufacturing overlap.
private func waitForOverlapAck(application: CjguiMacosApplication, windowA: CjguiComposableUiWindow,
    windowB: CjguiComposableUiWindow, controllerB: SchedulingBController, sessionA: UInt64,
    sessionB: UInt64, startPath: String, ackPath: String, emptyText: CString): OverlapWaitResult {
    var rounds: Int64 = 0
    var externalActions: Int64 = 0
    var firstExternalRound: Int64 = -1
    var firstExternalElapsedBeforeWaitMs: Int64 = -1
    var pendingBeforeExternal: UInt32 = 0u32
    var maxPending: UInt32 = 0u32
    var maxHighWater: UInt32 = 0u32
    let bOrdinaryStart = controllerB.ordinaryCount()
    let bOwnerVersionStart = controllerB.ownerVersion()
    var bOrdinaryDelta: Int64 = 0
    var bOwnerVersionDeltaAtFirstExternal: Int64 = 0
    var bOrdinaryEnqueued = false
    var queueOverflowObserved = false
    let coordinationStarted = MonoTime.now()
    while (!exists(startPath) && (MonoTime.now() - coordinationStarted).toMilliseconds() < 2000) {
        // This is a probe-only barrier.  It waits for the client process to
        // report that its UDS frames were sent; it never calls the
        // application owner or changes production scheduling.
        sleep(Duration.millisecond)
    }
    if (!exists(startPath)) {
        return OverlapWaitResult(false, 0, 0, -1, -1, 0u32, 0u32, 0u32, 0, 0, false, false)
    }
    while (!exists(ackPath) && rounds < MAX_EXTERNAL_WAIT_ROUNDS) {
        let before = nativeStats(sessionA)
        maxPending = if (before.pending > maxPending) { before.pending } else { maxPending }
        maxHighWater = if (before.highWater > maxHighWater) { before.highWater } else { maxHighWater }
        let bStatus = unsafe {
            cjgui_internal_renderer_test_enqueue_composable_event(sessionB, 1u32, 27u32, emptyText)
        }
        bOrdinaryEnqueued = bOrdinaryEnqueued || bStatus == CJGUI_INTERNAL_RENDERER_OK
        // A's 64-event queue is already full from the caller.  This explicit
        // 65th enqueue proves the native refusal boundary without changing
        // the production scheduler or dropping an accepted event.
        let overflowStatus = unsafe {
            cjgui_internal_renderer_test_enqueue_composable_event(sessionA, 1u32, 43u32, emptyText)
        }
        if (overflowStatus != CJGUI_INTERNAL_RENDERER_OK) {
            queueOverflowObserved = true
        }
        let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
        let elapsedBeforeWait = turn.elapsedBeforeEventWaitMs
        let after = nativeStats(sessionA)
        maxPending = if (after.pending > maxPending) { after.pending } else { maxPending }
        maxHighWater = if (after.highWater > maxHighWater) { after.highWater } else { maxHighWater }
        bOrdinaryDelta = controllerB.ordinaryCount() - bOrdinaryStart
        if (turn.externalActionCount > 0 && firstExternalRound < 0) {
            firstExternalRound = rounds + 1
            firstExternalElapsedBeforeWaitMs = elapsedBeforeWait
            pendingBeforeExternal = before.pending
            externalActions = turn.externalActionCount
            bOwnerVersionDeltaAtFirstExternal = controllerB.ownerVersion() - bOwnerVersionStart
        }
        if (!turn.isOpen || !application.isOpen() || !windowA.isOpen() || !windowB.isOpen()) {
            println("CJGUI_INTERACTION_SCHEDULING_OVERLAP_TURN_FAILURE round=${rounds + 1} application_open=${application.isOpen()} a_open=${windowA.isOpen()} b_open=${windowB.isOpen()} turn_open=${turn.isOpen} pending_before=${before.pending} pending_after=${after.pending} external_actions=${turn.externalActionCount}")
            getStdOut().flush()
            break
        }
        rounds += 1
    }
    return OverlapWaitResult(exists(ackPath), rounds, externalActions, firstExternalRound,
        firstExternalElapsedBeforeWaitMs, pendingBeforeExternal, maxPending, maxHighWater,
        bOrdinaryDelta, bOwnerVersionDeltaAtFirstExternal, bOrdinaryEnqueued, queueOverflowObserved)
}

private func runOverlap(application: CjguiMacosApplication, windowA: CjguiComposableUiWindow,
    windowB: CjguiComposableUiWindow, controllerA: SchedulingAController, controllerB: SchedulingBController,
    sessionA: UInt64, sessionB: UInt64, ackDirectory: String, emptyText: CString): Bool {
    let ackPath = "${ackDirectory}/overlap-ack-1"
    let beforeActionCount = controllerA.actionCount()
    let downStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_mouse(sessionA, 1u32, 40.0f32, 14.0f32)
    }
    let downTurn = application.pumpOneTurn(turnBudgetMs: 16u32)
    let pressedAction = windowA.testPressedInteractionActionName()

    // Fill A's native FIFO once.  The Cangjie event budget and the native
    // capacity are both 64, so this is a measured atomic drain boundary, not
    // a synthetic producer that requeues work after every pump.
    var queuedA: Int64 = 0
    while (queuedA < 64) {
        let kind = if (queuedA % 2 == 0) { 43u32 } else { 44u32 }
        let status = unsafe {
            cjgui_internal_renderer_test_enqueue_composable_event(sessionA, 1u32, kind, emptyText)
        }
        if (status == CJGUI_INTERNAL_RENDERER_OK) {
            queuedA += 1
        } else {
            break
        }
    }
    let beforeReady = nativeStats(sessionA)
    println("CJGUI_INTERACTION_SCHEDULING_OVERLAP_READY sample=1 target=${DOCUMENT_B} expected_version=${controllerB.ownerVersion()} value=160 queued_a=${queuedA} pending_a=${beforeReady.pending}")
    getStdOut().flush()
    let wait = waitForOverlapAck(application, windowA, windowB, controllerB, sessionA, sessionB,
        "${ackDirectory}/overlap-start-1", ackPath, emptyText)
    let pressSnapshotBeforeUp = windowA.testPressedInteractionActionName()
    let beforeUp = nativeStats(sessionA)
    let upStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_mouse(sessionA, 3u32, 40.0f32, 14.0f32)
    }
    let upTurn = application.pumpOneTurn(turnBudgetMs: 16u32)
    let upTrace = nativeInteractionTrace(sessionA)
    let terminalIdentityChanged = windowA.testLastTerminalPressIdentityChanged()
    let terminalActivationSuppressed = windowA.testLastPressActivationSuppressed()
    let actionDelta = controllerA.actionCount() - beforeActionCount
    let terminalPlatformCancel = upTrace.lastPumpedKind == 47u32 && actionDelta == 0
    let terminalRebindSuppressed = terminalIdentityChanged && terminalActivationSuppressed && actionDelta == 0
    // The overlap write belongs to B, not the pressed A action. A must either
    // activate normally or report the platform's explicit cancel; an unrelated
    // owner update cannot be passed off as a rebind suppression.
    let terminalNormalActivation = actionDelta == 1
    let terminalCorrect = terminalNormalActivation || terminalPlatformCancel
    let finalStats = nativeStats(sessionA)
    let boundedQueue = queuedA == 64 && beforeReady.pending == 64u32 &&
        wait.pendingBeforeExternal == 64u32 && wait.maxPending <= 64u32 &&
        wait.maxHighWater <= 64u32 && wait.queueOverflowObserved
    let bOwnerObserved = wait.bOrdinaryEnqueued && wait.bOrdinaryDelta == 1 &&
        wait.bOwnerVersionDeltaAtFirstExternal == 1
    let sameAtomicTurn = wait.seen && wait.externalActions > 0 && wait.firstExternalRound > 0 &&
        wait.firstExternalElapsedBeforeWaitMs <= MAX_OVERLAP_OWNER_SERVICE_MS
    let valid = downStatus == CJGUI_INTERNAL_RENDERER_OK && downTurn.isOpen && pressedAction.size > 0 &&
        wait.seen && sameAtomicTurn && boundedQueue && bOwnerObserved && upStatus == CJGUI_INTERNAL_RENDERER_OK &&
        upTurn.isOpen && pressSnapshotBeforeUp.size > 0 && terminalCorrect && finalStats.status == CJGUI_INTERNAL_RENDERER_OK &&
        beforeUp.status == CJGUI_INTERNAL_RENDERER_OK
    println("CJGUI_INTERACTION_SCHEDULING_OVERLAP_RESULT valid=${valid} ready_pending=${beforeReady.pending} queued_a=${queuedA} ack_seen=${wait.seen} rounds=${wait.rounds} first_external_round=${wait.firstExternalRound} external_actions=${wait.externalActions} first_external_elapsed_before_wait_ms=${wait.firstExternalElapsedBeforeWaitMs} owner_service_bound_ms=${MAX_OVERLAP_OWNER_SERVICE_MS} pending_before_external=${wait.pendingBeforeExternal} max_pending=${wait.maxPending} max_high_water=${wait.maxHighWater} queue_overflow_observed=${wait.queueOverflowObserved} b_ordinary_enqueued=${wait.bOrdinaryEnqueued} b_ordinary_delta=${wait.bOrdinaryDelta} b_owner_version_delta_at_first_external=${wait.bOwnerVersionDeltaAtFirstExternal} press_snapshot_before_up=${pressSnapshotBeforeUp} terminal_identity_changed=${terminalIdentityChanged} terminal_activation_suppressed=${terminalActivationSuppressed} terminal_normal_activation=${terminalNormalActivation} terminal_platform_cancel=${terminalPlatformCancel} terminal_rebind_suppressed=${terminalRebindSuppressed} action_delta=${actionDelta} up_status=${upStatus} up_turn_open=${upTurn.isOpen}")
    getStdOut().flush()
    return valid
}

private func externalValue(sample: Int64, scale: Int64): Int64 {
    let slot = (sample + scale / 8) % 12
    return 160 + slot * 32
}

private func runScale(application: CjguiMacosApplication, windowA: CjguiComposableUiWindow,
    windowB: CjguiComposableUiWindow, controllerA: SchedulingAController, controllerB: SchedulingBController,
    sessionA: UInt64, sessionB: UInt64, scale: Int64, ackDirectory: String, emptyText: CString): Bool {
    var valid = true
    var normalUnrelatedActivationCount: Int64 = 0
    var reboundSuppressionCount: Int64 = 0
    var sample: Int64 = 1
    while (sample <= SCALE_SAMPLE_COUNT) {
        let target = if (sample % 3 == 0) { DOCUMENT_A } else { DOCUMENT_B }
        let proposedValue = externalValue(sample, scale)
        // Every DOCUMENT_A sample must actually change the declaration that
        // the physical press captured. A same-value public write is still a
        // real operation, but it cannot prove old-action suppression.
        let value = if (target == DOCUMENT_A && proposedValue == controllerA.ownerValue()) {
            if (proposedValue >= 512) { 160 } else { proposedValue + 32 }
        } else {
            proposedValue
        }
        let ackPath = "${ackDirectory}/ack-${scale}-${sample}"
        let beforeA = windowA.windowProjection()
        let beforeB = windowB.windowProjection()
        let beforeAActionCount = controllerA.actionCount()
        let beforeBOrdinaryCount = controllerB.ordinaryCount()
        let beforeNative = nativeStats(sessionA)
        let sampleStarted = MonoTime.now()

        // Generic B input is a separate ordinary application event and is
        // pumped before A's physical press lifecycle.
        let genericEnqueueStarted = MonoTime.now()
        let genericStatus = unsafe {
            cjgui_internal_renderer_test_enqueue_composable_event(sessionB, 1u32, 27u32, emptyText)
        }
        let genericEnqueueNs = (MonoTime.now() - genericEnqueueStarted).toNanoseconds()
        let genericPumpStarted = MonoTime.now()
        let genericTurn = application.pumpOneTurn(turnBudgetMs: 16u32)
        let genericPumpNs = (MonoTime.now() - genericPumpStarted).toNanoseconds()

        let downStarted = MonoTime.now()
        let downStatus = unsafe {
            cjgui_internal_renderer_test_send_composable_mouse(sessionA, 1u32, 40.0f32, 14.0f32)
        }
        let enqueueNs = (MonoTime.now() - downStarted).toNanoseconds()
        let downPumpStarted = MonoTime.now()
        let downTurn = application.pumpOneTurn(turnBudgetMs: 16u32)
        let downPumpNs = (MonoTime.now() - downPumpStarted).toNanoseconds()
        let downTrace = nativeInteractionTrace(sessionA)

        // A pure interaction paint on unrelated B is deliberately inserted
        // between A down and the public owner write.
        let paintStatus = unsafe {
            cjgui_internal_renderer_test_enqueue_composable_event(sessionA, 2u32, 43u32, emptyText)
        }
        let paintPumpStarted = MonoTime.now()
        let paintTurn = application.pumpOneTurn(turnBudgetMs: 16u32)
        let paintPumpNs = (MonoTime.now() - paintPumpStarted).toNanoseconds()

        println("CJGUI_INTERACTION_SCHEDULING_READY scale=${scale} sample=${sample} target=${target} value=${value}")
        getStdOut().flush()
        let beforeWaitApplicationOpen = application.isOpen()
        let beforeWaitAOpen = windowA.isOpen()
        let beforeWaitBOpen = windowB.isOpen()
        let ack = waitForAck(application, windowA, windowB, ackPath)
        let pressSnapshotBeforeUp = windowA.testPressedInteractionActionName()
        let afterWaitApplicationOpen = application.isOpen()
        let afterWaitAOpen = windowA.isOpen()
        let afterWaitBOpen = windowB.isOpen()

        let upStarted = MonoTime.now()
        let upStatus = unsafe {
            cjgui_internal_renderer_test_send_composable_mouse(sessionA, 3u32, 40.0f32, 14.0f32)
        }
        let upEnqueueNs = (MonoTime.now() - upStarted).toNanoseconds()
        let upPumpStarted = MonoTime.now()
        let upTurn = application.pumpOneTurn(turnBudgetMs: 16u32)
        let upPumpNs = (MonoTime.now() - upPumpStarted).toNanoseconds()
        let upTrace = nativeInteractionTrace(sessionA)
        let terminalIdentityChanged = windowA.testLastTerminalPressIdentityChanged()
        let terminalActivationSuppressed = windowA.testLastPressActivationSuppressed()
        let afterA = windowA.windowProjection()
        let afterB = windowB.windowProjection()
        let afterNative = nativeStats(sessionA)
        let actionDelta = controllerA.actionCount() - beforeAActionCount
        let ordinaryDelta = controllerB.ordinaryCount() - beforeBOrdinaryCount
        let targetProgress = if (target == DOCUMENT_A) {
            afterA.sceneVersion > beforeA.sceneVersion
        } else {
            afterB.sceneVersion > beforeB.sceneVersion
        }
        // A real AppKit key-window loss cancels the native press (47) rather
        // than activating either the old or replacement action. Treat that
        // as a distinct correct terminal result, while requiring at least one
        // normal unrelated activation and one actual rebind suppression per
        // scale below.
        // `pump` drains the complete FIFO, so a later hover-leave may be the
        // final trace record after an already-routed activation. The owner
        // delta is the stable terminal fact; the trace remains diagnostic.
        let terminalNormalActivation = actionDelta == 1
        let terminalPlatformCancel = upTrace.lastPumpedKind == 47u32 && actionDelta == 0
        let terminalRebindSuppressed = terminalIdentityChanged && terminalActivationSuppressed && actionDelta == 0
        let terminalExact = if (target == DOCUMENT_A) {
            terminalRebindSuppressed || terminalPlatformCancel
        } else {
            terminalNormalActivation || terminalPlatformCancel
        }
        if (target == DOCUMENT_A && terminalRebindSuppressed) {
            reboundSuppressionCount += 1
        }
        if (target == DOCUMENT_B && terminalNormalActivation) {
            normalUnrelatedActivationCount += 1
        }
        let genericSplit = genericStatus == CJGUI_INTERNAL_RENDERER_OK && genericTurn.isOpen && ordinaryDelta == 1
        let sampleValid = genericSplit && downStatus == CJGUI_INTERNAL_RENDERER_OK && downTurn.isOpen &&
            paintStatus == CJGUI_INTERNAL_RENDERER_OK && paintTurn.isOpen && upStatus == CJGUI_INTERNAL_RENDERER_OK &&
            upTurn.isOpen && ack.seen && ack.rounds <= MAX_EXTERNAL_WAIT_ROUNDS && ack.externalActions > 0 &&
            targetProgress && terminalExact && afterA.isActive && afterB.isActive &&
            beforeNative.status == CJGUI_INTERNAL_RENDERER_OK && afterNative.status == CJGUI_INTERNAL_RENDERER_OK
        // This is the sum of ordinary Cangjie window turns around A's
        // interaction. Public wait time is reported separately below; no
        // native stage time is smuggled into this label.
        let refreshCompareNs = downPumpNs + paintPumpNs + upPumpNs
        let totalNs = (MonoTime.now() - sampleStarted).toNanoseconds()
        let waitNs = ack.elapsedNs
        println("CJGUI_INTERACTION_SCHEDULING_SAMPLE scale=${scale} sample=${sample} target=${target} valid=${sampleValid} hover_down_status=${downStatus} terminal_status=${upStatus} enqueue_ns=${enqueueNs} generic_enqueue_ns=${genericEnqueueNs} refresh_compare_ns=${refreshCompareNs} native_stage_submit_ms=${afterA.lastNativeStageAndSubmitElapsedMs} wait_ns=${waitNs} total_ns=${totalNs} generic_turn_open=${genericTurn.isOpen} down_turn_open=${downTurn.isOpen} paint_turn_open=${paintTurn.isOpen} before_wait_application_open=${beforeWaitApplicationOpen} before_wait_a_open=${beforeWaitAOpen} before_wait_b_open=${beforeWaitBOpen} after_wait_application_open=${afterWaitApplicationOpen} after_wait_a_open=${afterWaitAOpen} after_wait_b_open=${afterWaitBOpen} up_turn_open=${upTurn.isOpen} down_pump_ns=${downPumpNs} paint_pump_ns=${paintPumpNs} up_enqueue_ns=${upEnqueueNs} up_pump_ns=${upPumpNs} ack_rounds=${ack.rounds} external_actions=${ack.externalActions} action_delta=${actionDelta} ordinary_b_delta=${ordinaryDelta} native_submission_delta=${afterA.nativeSubmissionCount - beforeA.nativeSubmissionCount} native_node_update_delta=${afterNative.nodeUpdates - beforeNative.nodeUpdates} native_pending=${afterNative.pending} native_high_water=${afterNative.highWater} down_trace_status=${downTrace.status} down_last_enqueued_kind=${downTrace.lastEnqueuedKind} down_last_enqueued_node=${downTrace.lastEnqueuedNodeId} down_last_pumped_kind=${downTrace.lastPumpedKind} down_last_pumped_node=${downTrace.lastPumpedNodeId} up_trace_status=${upTrace.status} up_pending=${upTrace.pending} up_last_enqueued_kind=${upTrace.lastEnqueuedKind} up_last_enqueued_node=${upTrace.lastEnqueuedNodeId} up_last_pumped_kind=${upTrace.lastPumpedKind} up_last_pumped_node=${upTrace.lastPumpedNodeId} press_snapshot_before_up=${pressSnapshotBeforeUp} terminal_identity_changed=${terminalIdentityChanged} terminal_activation_suppressed=${terminalActivationSuppressed} terminal_normal_activation=${terminalNormalActivation} terminal_platform_cancel=${terminalPlatformCancel} terminal_rebind_suppressed=${terminalRebindSuppressed} target_progress=${targetProgress} terminal_exact=${terminalExact} generic_split=${genericSplit}")
        valid = valid && sampleValid
        sample += 1
    }
    let terminalCoverage = normalUnrelatedActivationCount > 0 && reboundSuppressionCount > 0
    valid = valid && terminalCoverage
    println("CJGUI_INTERACTION_SCHEDULING_TERMINAL_COVERAGE scale=${scale} unrelated_activation=${normalUnrelatedActivationCount > 0} rebind_suppression=${reboundSuppressionCount > 0}")
    println("CJGUI_INTERACTION_SCHEDULING_SCALE scale=${scale} samples=${SCALE_SAMPLE_COUNT} valid=${valid}")
    return valid
}

private func run(options: SchedulingOptions): Int64 {
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(DOCUMENT_A, "scheduling-A", "A"),
        CjguiTextDocument(DOCUMENT_B, "scheduling-B", "B")
    ]))
    let application = CjguiMacosApplication(maximumWindowCount: 2)
    let configuration = CjguiMacosApplicationWindowConfiguration("CJGUI Interaction Scheduling", 480u32, 260u32)
    let controllerB = SchedulingBController(workspace)
    let openedB = application.openWindow(controllerB, configuration: configuration)
    if (!openedB.didOpen) { application.close(); return 1 }
    let identifierB = if (let Some(value) <- openedB.identifier) { value } else {
        application.close()
        return 1
    }
    let windowB = if (let Some(value) <- application.window(identifierB)) { value } else {
        application.close()
        return 1
    }
    let connection = CjguiSharedOperationExternalConnection(workspace, authorization(), workspace)
    if (!connection.enableTargetedContextReads(workspace) || !application.attachExternalConnection(connection)) {
        application.close()
        return 1
    }
    if (let None <- connection.connectionInfo()) {
        application.close()
        return 1
    }
    if (let Some(info) <- connection.connectionInfo()) {
        println("CJGUI_INTERACTION_SCHEDULING_READY_DESCRIPTOR ${info.descriptorPath}")
        getStdOut().flush()
    }
    let sessionB = windowB.testSessionToken()
    let emptyText = unsafe { LibC.mallocCString("") }
    if (options.overlapOnly) {
        // The focused overlap acceptance intentionally avoids replaying the
        // 90 historical sequential samples. It still opens the same
        // application-owned B and A windows, accepts a real UDS request, and
        // exercises the normal owner turn under a fixed A FIFO backlog.
        let controllerA = SchedulingAController(workspace, 960)
        let openedA = application.openWindow(controllerA, configuration: configuration)
        if (!openedA.didOpen) {
            unsafe { LibC.free(emptyText) }
            application.close()
            return 1
        }
        let identifierA = if (let Some(value) <- openedA.identifier) { value } else {
            unsafe { LibC.free(emptyText) }
            application.close()
            return 1
        }
        let windowA = if (let Some(value) <- application.window(identifierA)) { value } else {
            unsafe { LibC.free(emptyText) }
            application.close()
            return 1
        }
        let overlapValid = runOverlap(application, windowA, windowB, controllerA, controllerB,
            windowA.testSessionToken(), sessionB, options.ackDirectory, emptyText)
        let closedA = application.requestClose(identifierA)
        let bRemainsOpen = application.isOpen() && windowB.isOpen() && !windowA.isOpen()
        let valid = overlapValid && closedA && bRemainsOpen
        println("CJGUI_INTERACTION_SCHEDULING_OVERLAP_ONLY_SUMMARY overlap_valid=${overlapValid} closed_a=${closedA} b_remains_open=${bRemainsOpen} valid=${valid}")
        unsafe { LibC.free(emptyText) }
        application.close()
        return if (valid) { 0 } else { 1 }
    }
    var allScalesValid = true
    var closedASurvivesB = true
    var finalAClosed = false
    var finalBRemainsOpen = false
    let scales = ArrayList<Int64>([8, 128, 960])
    var scaleIndex: Int64 = 0
    var failedCandidateRetained = false
    var failedCandidateRecovered = false
    var overlapValid = false
    var idleNoSubmit = false
    while (scaleIndex < scales.size) {
        let scale = scales[scaleIndex]
        let scaleController = SchedulingAController(workspace, scale)
        let opened = application.openWindow(scaleController, configuration: configuration)
        if (!opened.didOpen) {
            unsafe { LibC.free(emptyText) }
            application.close()
            return 1
        }
        let scaleIdentifier = if (let Some(identifier) <- opened.identifier) {
            identifier
        } else {
            unsafe { LibC.free(emptyText) }
            application.close()
            return 1
        }
        let scaleWindow = if (let Some(openedWindow) <- application.window(scaleIdentifier)) {
            openedWindow
        } else {
                unsafe { LibC.free(emptyText) }
                application.close()
                return 1
        }
        let scaleSession = scaleWindow.testSessionToken()
        let scaleValid = runScale(application, scaleWindow, windowB, scaleController, controllerB,
            scaleSession, sessionB, scale, options.ackDirectory, emptyText)
        allScalesValid = allScalesValid && scaleValid
        if (scale == 960) {
            overlapValid = runOverlap(application, scaleWindow, windowB, scaleController, controllerB,
                scaleSession, sessionB, options.ackDirectory, emptyText)
            // Keep the final A window open for the failure-candidate and idle
            // checks; smaller scale windows are closed after their samples.
            let failureBefore = scaleWindow.displayedSceneVersion()
            let failureSubmissionBefore = scaleWindow.windowProjection().nativeSubmissionCount
            let forceFailure = unsafe {
                cjgui_internal_renderer_test_set_composable_present_failures(scaleSession, 1u32)
            }
            // Every regular sample finishes with Cangjie-owned hover on B:
            // native's direct mouse helper still retains A as its hover, so
            // mouse-up has no second hover event to overwrite that Cangjie
            // state. Clear B then enter A in the same normal FIFO drain to
            // make this controlled candidate observably different.
            let failureLeave = unsafe {
                cjgui_internal_renderer_test_enqueue_composable_event(scaleSession, 2u32, 44u32, emptyText)
            }
            let failureEnqueue = unsafe {
                cjgui_internal_renderer_test_enqueue_composable_event(scaleSession, 1u32, 43u32, emptyText)
            }
            let failureTurn = application.pumpOneTurn(turnBudgetMs: 16u32)
            let failureProjection = scaleWindow.windowProjection()
            failedCandidateRetained = forceFailure == CJGUI_INTERNAL_RENDERER_OK &&
                failureLeave == CJGUI_INTERNAL_RENDERER_OK && failureEnqueue == CJGUI_INTERNAL_RENDERER_OK && failureTurn.isOpen &&
                scaleWindow.displayedSceneVersion() == failureBefore &&
                failureProjection.pendingRefreshReason == "interaction_paint_internal_error" &&
                failureProjection.lastNativeFailure == "internal_error" &&
                failureProjection.nativeSubmissionCount == failureSubmissionBefore
            let healthyRetry = scaleWindow.refresh()
            let recoveredProjection = scaleWindow.windowProjection()
            failedCandidateRecovered = healthyRetry && scaleWindow.nativeStatus() == CJGUI_INTERNAL_RENDERER_OK &&
                recoveredProjection.pendingRefreshReason == "none" &&
                recoveredProjection.nativeSubmissionCount > failureSubmissionBefore
            println("CJGUI_INTERACTION_SCHEDULING_FAILURE_CANDIDATE force_status=${forceFailure} leave_status=${failureLeave} enqueue_status=${failureEnqueue} turn_open=${failureTurn.isOpen} scene_before=${failureBefore} scene_after=${scaleWindow.displayedSceneVersion()} failure_pending=${failureProjection.pendingRefreshReason} failure_reason=${failureProjection.lastNativeFailure} submissions_before=${failureSubmissionBefore} submissions_after_failure=${failureProjection.nativeSubmissionCount} retry_ok=${healthyRetry} retry_pending=${recoveredProjection.pendingRefreshReason} submissions_after_retry=${recoveredProjection.nativeSubmissionCount} retained=${failedCandidateRetained} recovered=${failedCandidateRecovered}")
            let idleABefore = scaleWindow.windowProjection()
            let idleBBefore = windowB.windowProjection()
            var idleValid = true
            var idleRound: Int64 = 0
            while (idleRound < 3) {
                let idleTurn = application.pumpOneTurn(turnBudgetMs: 0u32)
                idleValid = idleValid && idleTurn.isOpen && idleTurn.externalActionCount == 0
                idleRound += 1
            }
            let idleAAfter = scaleWindow.windowProjection()
            let idleBAfter = windowB.windowProjection()
            idleNoSubmit = idleValid &&
                idleAAfter.nativeSubmissionCount == idleABefore.nativeSubmissionCount &&
                idleBAfter.nativeSubmissionCount == idleBBefore.nativeSubmissionCount
            finalAClosed = application.requestClose(scaleIdentifier)
            finalBRemainsOpen = application.isOpen() && windowB.isOpen() && !scaleWindow.isOpen()
            closedASurvivesB = closedASurvivesB && finalAClosed && finalBRemainsOpen
            println("CJGUI_INTERACTION_SCHEDULING_A_CLOSE scale=960 closed_a=${finalAClosed} b_remains_open=${finalBRemainsOpen}")
        } else {
            // Close through the application lifecycle rather than directly
            // destroying a window session.  This must retire only A's
            // identifier, preserve B and keep the shared UDS endpoint alive
            // for the next scale's independently opened A.
            let closedA = application.requestClose(scaleIdentifier)
            let bRemainsOpen = application.isOpen() && windowB.isOpen() && !scaleWindow.isOpen()
            println("CJGUI_INTERACTION_SCHEDULING_A_CLOSE scale=${scale} closed_a=${closedA} b_remains_open=${bRemainsOpen}")
            closedASurvivesB = closedASurvivesB && closedA && bRemainsOpen
        }
        scaleIndex += 1
    }
    let valid = allScalesValid && closedASurvivesB && overlapValid && failedCandidateRetained && failedCandidateRecovered && idleNoSubmit
    println("CJGUI_INTERACTION_SCHEDULING_SUMMARY scales_valid=${allScalesValid} a_close_survives_b=${closedASurvivesB} overlap_valid=${overlapValid} failed_candidate_retained=${failedCandidateRetained} failed_candidate_recovered=${failedCandidateRecovered} idle_no_submit=${idleNoSubmit} valid=${valid}")
    unsafe { LibC.free(emptyText) }
    application.close()
    return if (valid) { 0 } else { 1 }
}

main(args: Array<String>): Int64 {
    if (let Some(options) <- optionsFromArgs(args)) {
        return run(options)
    }
    getStdErr().writeln("usage: interaction_scheduling_efficiency_probe --ack-dir PATH [--overlap-only]")
    return 2
}
