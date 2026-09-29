package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*
import std.fs.*
import std.overflow.*
import std.sync.*
import std.time.*

private let DOCUMENT_A: Int64 = 7301
private let DOCUMENT_B: Int64 = 7302
private let SCALE_SAMPLE_COUNT: Int64 = 30
private let MAX_EXTERNAL_WAIT_ROUNDS: Int64 = 80
// Focused latency mode. One public request is in flight at a time and every
// sample gets a distinct, legal, non-initial DOCUMENT_B preview value.
private let LATENCY_SAMPLE_COUNT: Int64 = 20
private let LATENCY_FIRST_VALUE: Int64 = 129
// The external driver performs exactly one pre-measurement GET_CONTEXT (to
// learn the owner context version) before sample 1. The ready-queue observer
// counts every queued request, so sample i's INVOKE is the
// (LATENCY_PRE_MEASUREMENT_READY_COUNT + i)-th queued request. Validity below
// re-checks the exact total so a stray read cannot hide as a valid sample.
private let LATENCY_PRE_MEASUREMENT_READY_COUNT: Int64 = 1
private let LATENCY_ARMED_WAIT_MS: Int64 = 30000
private let LATENCY_SAMPLE_WAIT_MS: Int64 = 10000
private let LATENCY_SCENE_WAIT_MS: Int64 = 10000
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
    /// Test-only: reports whether the CALLING thread is the macOS main thread and
    /// whether main-thread dispatch is enabled in the native renderer. It exists
    /// so a probe can localize a NOT_MAIN_THREAD rejection instead of guessing.
    func cjgui_internal_renderer_test_is_main_thread(
        outIsMainThread: CPointer<Int32>, outDispatchEnabled: CPointer<Int32>
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
    func cjgui_internal_renderer_test_arm_submit_gate(session: UInt64, holdMicros: UInt32): Int32
    func cjgui_internal_renderer_test_midwork_composable_event_timing(session: UInt64,
        outAStartMicros: CPointer<UInt64>, outAEndMicros: CPointer<UInt64>,
        outProducerReadyMicros: CPointer<UInt64>, outProducerPostMicros: CPointer<UInt64>,
        outNativeEnqueueMicros: CPointer<UInt64>, outEnqueueStatus: CPointer<Int32>): Int32
    func cjgui_internal_renderer_test_monotonic_micros(outMicros: CPointer<UInt64>): Int32
}

/// A is a real pressable action. Its action name is derived from A's owner
/// version so an external A write is a genuine rebind, while an external B
/// write is unrelated to A's accepted scene.
private class SchedulingAController <: CjguiComposableUiController {
    private let workspace: CjguiTextDocumentWorkspace
    private let scale: Int64
    private var actionCountValue: Int64
    private var genericCountValue: Int64
    private var localRevision: Int64

    init(workspace: CjguiTextDocumentWorkspace, scale: Int64) {
        this.workspace = workspace
        this.scale = scale
        this.actionCountValue = 0
        this.genericCountValue = 0
        this.localRevision = 0
    }

    public func uiSceneVersion(): Int64 {
        return workspace.previewLimitVersionForDocument(DOCUMENT_A) + localRevision
    }

    private func actionName(): String {
        return "A_ACTION_${workspace.previewLimitForDocument(DOCUMENT_A)}"
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "scheduling-a-root",
            CjguiComposableUiStyle(fixedWidth: 280, fixedHeight: 1200, gap: 0,
                background: CjguiComposableUiColor(0.08, 0.10, 0.15, 1.0)))
        root.add(cjguiComposableButton(2, "scheduling-a-action",
            if (localRevision == 0) { "A" } else { "A ${localRevision}" }, actionName(), DOCUMENT_A,
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
    public func advanceLocalForSubmitGate(): Unit { localRevision += 1 }
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

/// Test-only ready-queue observer.
///
/// The transport worker calls this the moment a complete public request enters
/// the owner ready queue. It retains only a bounded local order/time pair, so
/// the focused latency probe can attribute the exact ready time of one
/// measurement invoke. It never touches owner state, never copies a request
/// payload, and adds no protocol surface.
private class LatencyReadyObserver <: CjguiSharedOperationReadyRequestObserver {
    private let lock: Mutex
    private let queuedAt: ArrayList<MonoTime>
    private var recordedCount: Int64

    init() {
        this.lock = Mutex()
        this.queuedAt = ArrayList<MonoTime>()
        this.recordedCount = 0
    }

    public func readyRequestQueued(sequence: Int64, at: MonoTime): Unit {
        synchronized(lock) {
            queuedAt.add(at)
            if (sequence > recordedCount) {
                recordedCount = sequence
            }
        }
    }

    public func count(): Int64 {
        return synchronized(lock) { recordedCount }
    }

    public func timeFor(sequence: Int64): ?MonoTime {
        return synchronized(lock) {
            if (sequence < 1 || sequence > Int64(queuedAt.size)) {
                return None
            }
            return Some(queuedAt[sequence - 1])
        }
    }
}

/// Thin latency measurement wrapper over the real workspace.
///
/// It is not a second owner: all five domain methods delegate to the same
/// CjguiTextDocumentWorkspace the controllers, the change domain and the
/// targeted context reads already use. `executeFromExternal` only samples the
/// owner's own committed result (time, versionAfter, applied count, target and
/// integer value) after the real owner submission, so the probe can timestamp
/// the exact apply without bypassing the public transport or touching business
/// state.
private class LatencyTimingDomain <: CjguiSharedOperationDomain {
    private let workspace: CjguiTextDocumentWorkspace
    private var appliedCountValue: Int64
    private var lastApplyTimeValue: ?MonoTime
    private var lastApplyVersionAfterValue: Int64
    private var lastApplyValueValue: Int64
    private var lastApplyDocumentValue: Int64

    init(workspace: CjguiTextDocumentWorkspace) {
        this.workspace = workspace
        this.appliedCountValue = 0
        this.lastApplyTimeValue = None
        this.lastApplyVersionAfterValue = 0
        this.lastApplyValueValue = -1
        this.lastApplyDocumentValue = -1
    }

    public func resourceType(): String { return workspace.resourceType() }

    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        return workspace.contextSnapshot()
    }

    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        return workspace.actionDescriptors()
    }

    public func executeFromHuman(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return workspace.executeFromHuman(invocation)
    }

    public func executeFromExternal(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        let result = workspace.executeFromExternal(invocation)
        if (result.applied) {
            appliedCountValue += 1
            lastApplyTimeValue = Some(MonoTime.now())
            lastApplyVersionAfterValue = result.versionAfter
            if (invocation.targetResourceIds.size == 1) {
                lastApplyDocumentValue = invocation.targetResourceIds[0]
            } else {
                lastApplyDocumentValue = -1
            }
            var value: Int64 = -1
            for (argument in invocation.arguments) {
                if (argument.name == "value") {
                    value = argument.value.integerValue
                }
            }
            lastApplyValueValue = value
        }
        return result
    }

    public func appliedCount(): Int64 { return appliedCountValue }
    public func lastApplyTime(): ?MonoTime { return lastApplyTimeValue }
    public func lastApplyVersionAfter(): Int64 { return lastApplyVersionAfterValue }
    public func lastApplyValue(): Int64 { return lastApplyValueValue }
    public func lastApplyDocument(): Int64 { return lastApplyDocumentValue }
}

private class SchedulingOptions {
    let ackDirectory: String
    let overlapOnly: Bool
    let latencyOnly: Bool
    let latencyMotion: Bool
    let submitGateOnly: Bool
    init(ackDirectory: String, overlapOnly!: Bool = false, latencyOnly!: Bool = false,
        latencyMotion!: Bool = false, submitGateOnly!: Bool = false) {
        this.ackDirectory = ackDirectory
        this.overlapOnly = overlapOnly
        this.latencyOnly = latencyOnly
        this.latencyMotion = latencyMotion
        this.submitGateOnly = submitGateOnly
    }
}

private func optionsFromArgs(args: Array<String>): ?SchedulingOptions {
    if (args.size == 2 && args[0] == "--ack-dir") {
        return Some(SchedulingOptions(args[1]))
    }
    if (args.size == 3 && args[0] == "--ack-dir" && args[2] == "--overlap-only") {
        return Some(SchedulingOptions(args[1], overlapOnly: true))
    }
    if (args.size == 3 && args[0] == "--ack-dir" && args[2] == "--latency-only") {
        return Some(SchedulingOptions(args[1], latencyOnly: true))
    }
    if (args.size == 3 && args[0] == "--ack-dir" && args[2] == "--latency-motion") {
        return Some(SchedulingOptions(args[1], latencyMotion: true))
    }
    if (args.size == 3 && args[0] == "--ack-dir" && args[2] == "--submit-gate-only") {
        return Some(SchedulingOptions(args[1], submitGateOnly: true))
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
    /// B's ordinary input processed IN THE SAME TURN as the external action, and
    /// A's pending depth at that turn: the documented "one atomic owner turn
    /// serves both" condition, recorded per turn instead of as a total.
    let bOrdinaryDeltaAtFirstExternal: Int64
    let pendingBeforeExternalObserved: UInt32
    /// True when B's ordinary input was injected at the post-refresh/pre-pump
    /// boundary of the measured turn. That is the ONLY place an event can be
    /// both issued after the external-driven refresh and still processed by the
    /// same turn, so it is the measurement's precondition, not a convenience.
    let bPostRefreshInjected: Bool

    init(seen: Bool, rounds: Int64, externalActions: Int64, firstExternalRound: Int64,
        firstExternalElapsedBeforeWaitMs: Int64, pendingBeforeExternal: UInt32, maxPending: UInt32,
        maxHighWater: UInt32, bOrdinaryDelta: Int64, bOwnerVersionDeltaAtFirstExternal: Int64,
        bOrdinaryEnqueued: Bool, queueOverflowObserved: Bool, bOrdinaryDeltaAtFirstExternal: Int64,
        pendingBeforeExternalObserved: UInt32, bPostRefreshInjected: Bool) {
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
        this.bOrdinaryDeltaAtFirstExternal = bOrdinaryDeltaAtFirstExternal
        this.pendingBeforeExternalObserved = pendingBeforeExternalObserved
        this.bPostRefreshInjected = bPostRefreshInjected
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

/// Test-only post-refresh/pre-pump observer for the overlap acceptance. The
/// host calls it after a window's external-driven refresh and before that same
/// turn pumps the window, which is the ONLY boundary where B's ordinary input
/// can be both issued against the refreshed projection and served by the
/// measured turn. It injects at most once and only into B.
private class OverlapPostRefreshObserver <: CjguiMacosApplicationPostRefreshObserver {
    private let sessionB: UInt64
    private let emptyText: CString
    private var armedValue: Bool = false
    private var injectedValue: Bool = false

    init(sessionB: UInt64, emptyText: CString) {
        this.sessionB = sessionB
        this.emptyText = emptyText
    }

    public func arm(): Unit {
        armedValue = true
    }

    public func postRefreshBeforePump(window: CjguiComposableUiWindow): Unit {
        if (!armedValue || injectedValue) {
            return
        }
        if (window.testSessionToken() != sessionB) {
            return
        }
        let status = unsafe {
            cjgui_internal_renderer_test_enqueue_composable_event(sessionB, 1u32, 27u32, emptyText)
        }
        if (status == CJGUI_INTERNAL_RENDERER_OK) {
            injectedValue = true
        }
    }

    public func injected(): Bool {
        return injectedValue
    }
}

/// Waits for one real external burst while A already owns a bounded FIFO.
/// There is deliberately no producer loop here: the 64 A events are queued
/// once before READY and are drained by the one normal owner turn.  If the
/// external requests arrive later, the observation fails instead of
/// replenishing the queue after every turn and manufacturing overlap.
private func waitForOverlapAck(application: CjguiMacosApplication, windowA: CjguiComposableUiWindow,
    windowB: CjguiComposableUiWindow, controllerB: SchedulingBController, sessionA: UInt64,
    sessionB: UInt64, startPath: String, ackPath: String, emptyText: CString,
    postRefresh: OverlapPostRefreshObserver): OverlapWaitResult {
    var rounds: Int64 = 0
    var externalActions: Int64 = 0
    var firstExternalRound: Int64 = -1
    var firstExternalElapsedBeforeWaitMs: Int64 = -1
    var pendingBeforeExternal: UInt32 = 0u32
    var maxPending: UInt32 = 0u32
    var maxHighWater: UInt32 = 0u32
    let bOrdinaryStart = controllerB.ordinaryCount()
    let bOwnerVersionStart = controllerB.ownerVersion()
    // B's ordinary input is queued BEFORE the measured turn, not inside it: the
    // test enqueue becomes pumpable on the following host turn (it is dispatched
    // to the main queue), so queueing it inside the measured turn would only
    // prove the injection latency, not whether the owner turn serves both.
    let bSetupStatus = unsafe {
        cjgui_internal_renderer_test_enqueue_composable_event(sessionB, 1u32, 27u32, emptyText)
    }
    let bOrdinaryEnqueued = bSetupStatus == CJGUI_INTERNAL_RENDERER_OK
    var bOrdinaryDelta: Int64 = 0
    var bOrdinaryDeltaAtFirstExternal: Int64 = 0
    var pendingBeforeExternalObserved: UInt32 = 0u32
    var bOwnerVersionDeltaAtFirstExternal: Int64 = 0
    var queueOverflowObserved = false
    let coordinationStarted = MonoTime.now()
    while (!exists(startPath) && (MonoTime.now() - coordinationStarted).toMilliseconds() < 2000) {
        // This is a probe-only barrier.  It waits for the client process to
        // report that its UDS frames were sent; it never calls the
        // application owner or changes production scheduling.
        sleep(Duration.millisecond)
    }
    if (!exists(startPath)) {
        return OverlapWaitResult(false, 0, 0, -1, -1, 0u32, 0u32, 0u32, 0, 0, false, false, 0, 0u32,
            postRefresh.injected())
    }
    while (!exists(ackPath) && rounds < MAX_EXTERNAL_WAIT_ROUNDS) {
        let before = nativeStats(sessionA)
        maxPending = if (before.pending > maxPending) { before.pending } else { maxPending }
        maxHighWater = if (before.highWater > maxHighWater) { before.highWater } else { maxHighWater }
        let bOrdinaryBeforeTurn = controllerB.ordinaryCount()
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
            // B's ordinary input must be processed IN THIS TURN, not merely at
            // some point in the loop: that is the "same atomic turn" claim.
            bOrdinaryDeltaAtFirstExternal = controllerB.ordinaryCount() - bOrdinaryBeforeTurn
            pendingBeforeExternalObserved = before.pending
        }
        if (!turn.isOpen || !application.isOpen() || !windowA.isOpen() || !windowB.isOpen()) {
            // Report the FIRST state change, not only the final closed state: the
            // host records the first window retirement, the application close
            // reason and any consumed exit intent, and each window records why it
            // stopped being open (native event kind/status included).
            println("CJGUI_INTERACTION_SCHEDULING_OVERLAP_TURN_FAILURE round=${rounds + 1} application_open=${application.isOpen()} a_open=${windowA.isOpen()} b_open=${windowB.isOpen()} turn_open=${turn.isOpen} pending_before=${before.pending} pending_after=${after.pending} external_actions=${turn.externalActionCount} retirement='${application.testRetirementTrace()}' app_close='${application.testApplicationCloseTrace()}' exit_intent='${application.testExitIntentTrace()}' a_trace='${windowA.testCloseTrace()}' b_trace='${windowB.testCloseTrace()}' a_native=${windowA.nativeStatus()} b_native=${windowB.nativeStatus()} a_scene=${windowA.displayedSceneVersion()} b_scene=${windowB.displayedSceneVersion()}")
            getStdOut().flush()
            break
        }
        println("CJGUI_INTERACTION_SCHEDULING_OVERLAP_THREAD phase=round_${rounds + 1} ${mainThreadState()}")
        getStdOut().flush()
        println("CJGUI_INTERACTION_SCHEDULING_OVERLAP_ROUND round=${rounds + 1} setup_b_status=${bSetupStatus} overflow_status=${overflowStatus} b_ordinary_before=${bOrdinaryBeforeTurn} b_ordinary_after=${controllerB.ordinaryCount()} external=${turn.externalActionCount} turn_elapsed_ms=${turn.elapsedBeforeEventWaitMs} pending_before=${before.pending} pending_after=${after.pending} waited_window_present=${turn.waitedWindow.isSome()}")
        getStdOut().flush()
        rounds += 1
    }
    return OverlapWaitResult(exists(ackPath), rounds, externalActions, firstExternalRound,
        firstExternalElapsedBeforeWaitMs, pendingBeforeExternal, maxPending, maxHighWater,
        bOrdinaryDelta, bOwnerVersionDeltaAtFirstExternal, bOrdinaryEnqueued, queueOverflowObserved,
        bOrdinaryDeltaAtFirstExternal, pendingBeforeExternalObserved, postRefresh.injected())
}

private func mainThreadState(): String {
    var isMain: Int32 = -1
    var dispatchEnabled: Int32 = -1
    let status = unsafe {
        cjgui_internal_renderer_test_is_main_thread(inout isMain, inout dispatchEnabled)
    }
    return "status=${status} is_main=${isMain} dispatch_enabled=${dispatchEnabled}"
}

private class OverlapAdmissionResult {
    let admitted: Bool
    let ready: Int64
    let waitedMs: Int64

    init(admitted: Bool, ready: Int64, waitedMs: Int64) {
        this.admitted = admitted
        this.ready = ready
        this.waitedMs = waitedMs
    }
}

/// Wait, WITHOUT pumping any turn, until the transport's public ready-queue
/// counter shows the client's request has really been admitted. The client's
/// start marker only proves the frame is on the socket: the I/O worker still has
/// to accept and queue it. Pumping before that admission drains A's full FIFO, so
/// the documented "one atomic owner turn serves the real UDS request while A has
/// 64 pending events" condition becomes unobservable. This waits on the existing
/// public diagnostics; it changes no production scheduling and relaxes no bound.
private func waitForOverlapAdmission(connection: CjguiSharedOperationExternalConnection,
                                     startPath: String): OverlapAdmissionResult {
    let started = MonoTime.now()
    var ready: Int64 = 0
    var waited: Int64 = 0
    while (waited < 3000) {
        if (exists(startPath)) {
            if (let Some(diagnostics) <- connection.transportDiagnostics()) {
                ready = diagnostics.readyRequestCount
                if (ready >= 1) {
                    return OverlapAdmissionResult(true, ready, waited)
                }
            }
        }
        // Busy-wait diagnostic: no sleep on the probing thread while the
        // transport worker admits the request.
        waited = (MonoTime.now() - started).toMilliseconds()
    }
    return OverlapAdmissionResult(false, ready, waited)
}

private func runOverlap(application: CjguiMacosApplication, windowA: CjguiComposableUiWindow,
    windowB: CjguiComposableUiWindow, controllerA: SchedulingAController, controllerB: SchedulingBController,
    sessionA: UInt64, sessionB: UInt64, ackDirectory: String, emptyText: CString,
    connection: CjguiSharedOperationExternalConnection): Bool {
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
    println("CJGUI_INTERACTION_SCHEDULING_OVERLAP_THREAD phase=before_admission ${mainThreadState()}")
    getStdOut().flush()
    let admission = waitForOverlapAdmission(connection, "${ackDirectory}/overlap-start-1")
    println("CJGUI_INTERACTION_SCHEDULING_OVERLAP_ADMISSION admitted=${admission.admitted} ready=${admission.ready} waited_ms=${admission.waitedMs} thread='${mainThreadState()}'")
    getStdOut().flush()
    // B's ordinary input is injected at the host's post-refresh/pre-pump
    // boundary, so the SAME measured turn both applies the external write and
    // serves the ordinary input. The stale pre-refresh event enqueued above is
    // deliberately still present: an accepted post-refresh event plus the
    // strict projection-version rule prove the stale one was refused.
    let postRefresh = OverlapPostRefreshObserver(sessionB, emptyText)
    application.setTestPostRefreshObserver(Some(postRefresh))
    postRefresh.arm()
    let wait = waitForOverlapAck(application, windowA, windowB, controllerB, sessionA, sessionB,
        "${ackDirectory}/overlap-start-1", ackPath, emptyText, postRefresh)
    application.setTestPostRefreshObserver(None)
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
    // A's FIFO must be exactly at its bound when the external action is served,
    // and the 65th enqueue must have been refused. The counter of our own
    // successful enqueues is evidence, not the condition: one pre-existing
    // pending event can occupy a slot, which the pending/high-water readings and
    // the explicit refusal already prove.
    let boundedQueue = beforeReady.pending == 64u32 &&
        wait.pendingBeforeExternal == 64u32 && wait.pendingBeforeExternalObserved == 64u32 &&
        wait.maxPending <= 64u32 && wait.maxHighWater <= 64u32 && wait.queueOverflowObserved
    // B's ordinary input and the external action really were served in the SAME
    // owner turn, and the external action applied exactly one owner version.
    // B's ordinary input was injected AFTER the external-driven refresh and
    // processed by the SAME turn; the stale pre-refresh event was refused, which
    // is why exactly ONE of the two enqueued events was accepted.
    let bOwnerObserved = wait.bOrdinaryEnqueued && wait.bPostRefreshInjected &&
        wait.bOrdinaryDeltaAtFirstExternal >= 1 && wait.bOwnerVersionDeltaAtFirstExternal == 1 &&
        wait.bOrdinaryDelta == 1
    let sameAtomicTurn = wait.seen && wait.externalActions > 0 && wait.firstExternalRound > 0 &&
        wait.firstExternalElapsedBeforeWaitMs <= MAX_OVERLAP_OWNER_SERVICE_MS
    let valid = admission.admitted && downStatus == CJGUI_INTERNAL_RENDERER_OK && downTurn.isOpen &&
        pressedAction.size > 0 &&
        wait.seen && sameAtomicTurn && boundedQueue && bOwnerObserved && upStatus == CJGUI_INTERNAL_RENDERER_OK &&
        upTurn.isOpen && pressSnapshotBeforeUp.size > 0 && terminalCorrect && finalStats.status == CJGUI_INTERNAL_RENDERER_OK &&
        beforeUp.status == CJGUI_INTERNAL_RENDERER_OK
    println("CJGUI_INTERACTION_SCHEDULING_OVERLAP_RESULT valid=${valid} ready_pending=${beforeReady.pending} queued_a=${queuedA} ack_seen=${wait.seen} rounds=${wait.rounds} first_external_round=${wait.firstExternalRound} external_actions=${wait.externalActions} first_external_elapsed_before_wait_ms=${wait.firstExternalElapsedBeforeWaitMs} owner_service_bound_ms=${MAX_OVERLAP_OWNER_SERVICE_MS} pending_before_external=${wait.pendingBeforeExternal} max_pending=${wait.maxPending} max_high_water=${wait.maxHighWater} queue_overflow_observed=${wait.queueOverflowObserved} b_ordinary_enqueued=${wait.bOrdinaryEnqueued} b_post_refresh_injected=${wait.bPostRefreshInjected} b_ordinary_delta=${wait.bOrdinaryDelta} b_ordinary_delta_at_first_external=${wait.bOrdinaryDeltaAtFirstExternal} b_owner_version_delta_at_first_external=${wait.bOwnerVersionDeltaAtFirstExternal} press_snapshot_before_up=${pressSnapshotBeforeUp} terminal_identity_changed=${terminalIdentityChanged} terminal_activation_suppressed=${terminalActivationSuppressed} terminal_normal_activation=${terminalNormalActivation} terminal_platform_cancel=${terminalPlatformCancel} terminal_rebind_suppressed=${terminalRebindSuppressed} action_delta=${actionDelta} up_status=${upStatus} up_turn_open=${upTurn.isOpen}")
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

private func joinTokenList(items: ArrayList<String>): String {
    var text = ""
    var index = 0
    while (index < items.size) {
        if (index > 0) {
            text += "+"
        }
        text += items[index]
        index += 1
    }
    return text
}

/// Ascending copy of a bounded sample vector. The focused probe owns exactly
/// 20 records, so a local insertion sort keeps the nearest-rank definition
/// recomputable without adding a dependency or a second statistics path.
private func sortedSampleCopy(values: ArrayList<Int64>): Array<Int64> {
    let copy = values.toArray()
    var index = 1
    while (index < copy.size) {
        let key = copy[index]
        var scan = index - 1
        while (scan >= 0 && copy[scan] > key) {
            copy[scan + 1] = copy[scan]
            scan -= 1
        }
        copy[scan + 1] = key
        index += 1
    }
    return copy
}

/// Nearest-rank percentile. `rank = ceil(numerator * n / denominator)`, then
/// the 1-based rank selects the element. With n = 20 this makes p50 the 10th
/// record and p95 the 19th record.
private func percentileNearestRank(sortedValues: Array<Int64>, numerator: Int64, denominator: Int64): Int64 {
    if (sortedValues.size == 0) {
        return 0
    }
    let count = sortedValues.size
    var rank = (numerator * count + denominator - 1) / denominator
    if (rank < 1) {
        rank = 1
    }
    if (rank > count) {
        rank = count
    }
    return sortedValues[rank - 1]
}

private func writeMarkerFile(path: String, content: String): Unit {
    File.writeTo(Path(path), content.toArray())
}

private func acceptedOwnerText(windowB: CjguiComposableUiWindow): String {
    if (let Some(text) <- windowB.acceptedNodeText("scheduling-b-owner-value")) {
        return text
    }
    return ""
}

/// Focused latency mode. It reuses the same application host, workspace and UDS
/// lifecycle as the full probe, but opens A first and B second so every normal
/// turn still services A before B, and it runs exactly 20 public samples.
private func runLatencyMode(options: SchedulingOptions, workspace: CjguiTextDocumentWorkspace,
    application: CjguiMacosApplication, configuration: CjguiMacosApplicationWindowConfiguration,
    controllerB: SchedulingBController): Int64 {
    let controllerA = SchedulingAController(workspace, 8)
    let openedA = application.openWindow(controllerA, configuration: configuration)
    if (!openedA.didOpen) {
        application.close()
        return 1
    }
    let identifierA = if (let Some(value) <- openedA.identifier) {
        value
    } else {
        application.close()
        return 1
    }
    let windowA = if (let Some(value) <- application.window(identifierA)) {
        value
    } else {
        application.close()
        return 1
    }
    let openedB = application.openWindow(controllerB, configuration: configuration)
    if (!openedB.didOpen) {
        application.close()
        return 1
    }
    let identifierB = if (let Some(value) <- openedB.identifier) {
        value
    } else {
        application.close()
        return 1
    }
    let windowB = if (let Some(value) <- application.window(identifierB)) {
        value
    } else {
        application.close()
        return 1
    }
    let timingDomain = LatencyTimingDomain(workspace)
    let connection = CjguiSharedOperationExternalConnection(timingDomain, authorization(), workspace)
    if (!connection.enableTargetedContextReads(workspace) || !application.attachExternalConnection(connection)) {
        application.close()
        return 1
    }
    let observer = LatencyReadyObserver()
    if (!connection.enableTestReadyRequestObserver(observer)) {
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
    let sessionA = windowA.testSessionToken()
    if (options.submitGateOnly) {
        let valid = runPublicSubmitGate(options.ackDirectory, application, windowA, windowB,
            controllerA, timingDomain, observer, sessionA)
        application.close()
        return if (valid) { 0 } else { 1 }
    }
    let emptyText = unsafe { LibC.mallocCString("") }
    let valid = runLatencySamples(application, windowA, windowB, controllerA, timingDomain, connection,
        observer, sessionA, options.ackDirectory, emptyText, options.latencyMotion)
    unsafe { LibC.free(emptyText) }
    application.close()
    return if (valid) { 0 } else { 1 }
}

/// One real UDS INVOKE is admitted by the transport worker while A's Metal
/// commit path is held. The owner remains on the host thread; no test hook
/// invokes it or manufactures an accepted scene.
private func runPublicSubmitGate(ackDirectory: String, application: CjguiMacosApplication,
    windowA: CjguiComposableUiWindow, windowB: CjguiComposableUiWindow,
    controllerA: SchedulingAController, timing: LatencyTimingDomain,
    observer: LatencyReadyObserver, sessionA: UInt64): Bool {
    let armedStarted = MonoTime.now()
    while ((!exists("${ackDirectory}/latency-baseline-ready") || observer.count() < 1) &&
        (MonoTime.now() - armedStarted).toMilliseconds() < LATENCY_ARMED_WAIT_MS) {
        let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
    }
    if (!exists("${ackDirectory}/latency-baseline-ready") || observer.count() != 1) {
        println("CJGUI_PUBLIC_SUBMIT_GATE failed=baseline_ready count=${observer.count()} " +
            "elapsed_ms=${(MonoTime.now() - armedStarted).toMilliseconds()}")
        return false
    }
    let beforeApplied = timing.appliedCount()
    let beforeScene = windowB.windowProjection().acceptedSceneVersion
    controllerA.advanceLocalForSubmitGate()
    let arm = unsafe { cjgui_internal_renderer_test_arm_submit_gate(sessionA, 50000u32) }
    // Bound the cross-clock mapping instead of treating two sequential reads
    // as simultaneous. The queue observer's MonoTime value lies in the same
    // domain as monoBase; nativeBefore/After enclose that one sample.
    var nativeBefore: UInt64 = 0u64
    var nativeAfter: UInt64 = 0u64
    let clockBefore = unsafe { cjgui_internal_renderer_test_monotonic_micros(inout nativeBefore) }
    let monoBase = MonoTime.now()
    let clockAfter = unsafe { cjgui_internal_renderer_test_monotonic_micros(inout nativeAfter) }
    let refreshed = windowA.refresh()
    var gateStart: UInt64 = 0u64; var gateEnd: UInt64 = 0u64
    var producerReady: UInt64 = 0u64; var producerPost: UInt64 = 0u64
    var nativeEnqueue: UInt64 = 0u64; var enqueueStatus: Int32 = 0
    let timingStatus = unsafe { cjgui_internal_renderer_test_midwork_composable_event_timing(
        sessionA, inout gateStart, inout gateEnd, inout producerReady,
        inout producerPost, inout nativeEnqueue, inout enqueueStatus) }
    let readyWait = MonoTime.now()
    while (observer.count() < 2 && (MonoTime.now() - readyWait).toMilliseconds() < 2000) {
        sleep(Duration.millisecond)
    }
    var readyOffsetMicros: Int64 = -1
    if (let Some(queuedAt) <- observer.timeFor(2)) {
        readyOffsetMicros = (queuedAt - monoBase).toMicroseconds()
    }
    // Both native clock reads and Duration.toMicroseconds export integer
    // microseconds. Widen the bracket by their conversion granularity rather
    // than asserting that equal printed endpoints mean zero uncertainty.
    let readyEarliest = if (readyOffsetMicros >= 0 && clockBefore == CJGUI_INTERNAL_RENDERER_OK) {
        Int64(nativeBefore) + readyOffsetMicros - 2
    } else { -1 }
    let readyLatest = if (readyOffsetMicros >= 0 && clockAfter == CJGUI_INTERNAL_RENDERER_OK) {
        Int64(nativeAfter) + readyOffsetMicros + 2
    } else { -1 }
    // Both possible native timestamps for the observed ready boundary must
    // lie strictly inside the held commit interval. No guessed tolerance.
    let queuedInGate = readyEarliest >= Int64(gateStart) && readyLatest < Int64(gateEnd) &&
        readyLatest >= readyEarliest && gateEnd > gateStart
    var rounds: Int64 = 0
    while (rounds < 60 &&
        (timing.appliedCount() < beforeApplied + 1 ||
         acceptedOwnerText(windowB) != "B owner=129")) {
        let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
        rounds += 1
    }
    let ownerOnce = timing.appliedCount() == beforeApplied + 1 &&
        timing.lastApplyDocument() == DOCUMENT_B && timing.lastApplyValue() == 129
    let accepted = acceptedOwnerText(windowB) == "B owner=129" &&
        windowB.windowProjection().acceptedSceneVersion > beforeScene
    var idle: Int64 = 0
    while (idle < 3) { let _ = application.pumpOneTurn(turnBudgetMs: 0u32); idle += 1 }
    let stillOnce = timing.appliedCount() == beforeApplied + 1
    let valid = arm == CJGUI_INTERNAL_RENDERER_OK && clockBefore == CJGUI_INTERNAL_RENDERER_OK &&
        clockAfter == CJGUI_INTERNAL_RENDERER_OK &&
        timingStatus == CJGUI_INTERNAL_RENDERER_OK && refreshed && queuedInGate &&
        ownerOnce && accepted && stillOnce && observer.count() == 2
    println("CJGUI_PUBLIC_SUBMIT_GATE request=SET_PREVIEW_LIMIT target=${DOCUMENT_B} value=129 " +
        "ready_sequence=${observer.count()} gate_start_us=${gateStart} gate_end_us=${gateEnd} " +
        "native_before_us=${nativeBefore} native_after_us=${nativeAfter} " +
        "ready_mono_offset_us=${readyOffsetMicros} quantization_bound_us=2 " +
        "ready_native_interval_us=${readyEarliest}..${readyLatest} " +
        "ready_in_gate=${queuedInGate} owner_delta=${timing.appliedCount() - beforeApplied} " +
        "owner_version_after=${timing.lastApplyVersionAfter()} accepted_scene=${beforeScene}->" +
        "${windowB.windowProjection().acceptedSceneVersion} accepted_text=${acceptedOwnerText(windowB)} " +
        "pump_rounds=${rounds} exactly_once=${ownerOnce && stillOnce} valid=${valid}")
    getStdOut().flush()
    if (valid) { writeMarkerFile("${ackDirectory}/latency-accepted-1", "accepted\n") }
    return valid
}

private func runLatencySamples(application: CjguiMacosApplication, windowA: CjguiComposableUiWindow,
    windowB: CjguiComposableUiWindow, controllerA: SchedulingAController, timing: LatencyTimingDomain,
    connection: CjguiSharedOperationExternalConnection, observer: LatencyReadyObserver, sessionA: UInt64,
    ackDirectory: String, emptyText: CString, motionActivity: Bool): Bool {
    let _ = emptyText
    let origin = MonoTime.now()
    // The external driver publishes `latency-armed` before it starts measuring.
    // This wait pumps the host so the driver's single pre-measurement
    // GET_CONTEXT is served and cannot be mistaken for a sample request.
    let armedStarted = MonoTime.now()
    var turnOpen = true
    while (!exists("${ackDirectory}/latency-armed") &&
        (MonoTime.now() - armedStarted).toMilliseconds() < LATENCY_ARMED_WAIT_MS) {
        let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
        if (!turn.isOpen) {
            turnOpen = false
            break
        }
    }
    if (!exists("${ackDirectory}/latency-armed")) {
        println("FAIL_LATENCY_NOT_ARMED host_open=${turnOpen} waited_ms=${(MonoTime.now() - armedStarted).toMilliseconds()}")
        getStdOut().flush()
        return false
    }

    let motionKey = "semantic:scheduling-a-action"
    let motionSpec = CjguiComposableUiAnimationSpec.tween(durationMs: 1000)
    if (motionActivity) {
        let baselineWait = MonoTime.now()
        while (!exists("${ackDirectory}/latency-baseline-ready") &&
            (MonoTime.now() - baselineWait).toMilliseconds() < LATENCY_ARMED_WAIT_MS) {
            let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
            if (!turn.isOpen) { return false }
        }
        if (!exists("${ackDirectory}/latency-baseline-ready") ||
            !windowA.animateNodeTranslation(motionKey, 4.0, 0.0, spec: motionSpec,
                atTime: MonoTime.now())) { return false }
        writeMarkerFile("${ackDirectory}/latency-motion-ready", "active\n")
    }
    var samplesValid = true
    var aProgressEverySample = true
    var motionSamplesValid = true
    let readyToOwner = ArrayList<Int64>()
    let ownerToScene = ArrayList<Int64>()
    let readyToScene = ArrayList<Int64>()
    var index: Int64 = 1
    while (index <= LATENCY_SAMPLE_COUNT) {
        let value = LATENCY_FIRST_VALUE + (index - 1)
        let requestPath = "${ackDirectory}/latency-request-${index}"
        let acceptedPath = "${ackDirectory}/latency-accepted-${index}"
        let expectedSequence = LATENCY_PRE_MEASUREMENT_READY_COUNT + index
        let readyStarted = MonoTime.now()
        var readySeen = false
        var hostOpen = true
        while ((MonoTime.now() - readyStarted).toMilliseconds() < LATENCY_SAMPLE_WAIT_MS) {
            if (exists(requestPath) && observer.count() >= expectedSequence) {
                readySeen = true
                break
            }
            let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
            if (!turn.isOpen) {
                hostOpen = false
                break
            }
        }
        if (!readySeen) {
            println("FAIL_LATENCY_READY index=${index} value=${value} host_open=${hostOpen} ready_count=${observer.count()} expected_sequence=${expectedSequence} waited_ms=${(MonoTime.now() - readyStarted).toMilliseconds()}")
            getStdOut().flush()
            return false
        }
        var t0 = origin
        if (let Some(stamp) <- observer.timeFor(expectedSequence)) {
            t0 = stamp
        } else {
            println("FAIL_LATENCY_READY_STAMP index=${index} sequence=${expectedSequence}")
            getStdOut().flush()
            return false
        }
        let motionBefore = if (motionActivity) {
            if (let Some(status) <- windowA.animatedNodeTranslation(motionKey)) { status.active } else { false }
        } else { true }

        let beforeApplied = timing.appliedCount()
        let beforeProjectionA = windowA.windowProjection()
        let beforeAction = controllerA.actionCount()
        let beforeGeneric = controllerA.genericCount()
        var beforeBSubmission: Int64 = 0
        if (let Some(snapshot) <- windowB.testLastNativeSubmissionSnapshot()) {
            beforeBSubmission = snapshot.submissionCount
        }

        // One real controlled native input on A during every sample. It is the
        // same public down/up helper the sequential scale probe uses; it is not
        // a direct setter and never touches the shared owner.
        let downStatus = unsafe {
            cjgui_internal_renderer_test_send_composable_mouse(sessionA, 1u32, 40.0f32, 14.0f32)
        }
        let downTurn = application.pumpOneTurn(turnBudgetMs: 16u32)
        let upStatus = unsafe {
            cjgui_internal_renderer_test_send_composable_mouse(sessionA, 3u32, 40.0f32, 14.0f32)
        }

        let expectedText = "B owner=${value}"
        let sceneStarted = MonoTime.now()
        var applySeen = false
        var sceneSeen = false
        var sceneTime = origin
        var pumpRounds: Int64 = 0
        while ((MonoTime.now() - sceneStarted).toMilliseconds() < LATENCY_SCENE_WAIT_MS) {
            let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
            pumpRounds += 1
            if (!turn.isOpen) {
                break
            }
            if (timing.appliedCount() > beforeApplied) {
                applySeen = true
            }
            if (let Some(snapshot) <- windowB.testLastNativeSubmissionSnapshot()) {
                if (snapshot.submissionCount > beforeBSubmission && acceptedOwnerText(windowB) == expectedText) {
                    sceneSeen = true
                    sceneTime = snapshot.time
                }
            }
            if (applySeen && sceneSeen) {
                break
            }
        }

        var ownerTime = origin
        var ownerSeen = false
        if (let Some(stamp) <- timing.lastApplyTime()) {
            ownerTime = stamp
            ownerSeen = true
        }
        let applyMatched = timing.lastApplyDocument() == DOCUMENT_B && timing.lastApplyValue() == value &&
            timing.lastApplyVersionAfter() > 0
        var ordered = false
        if (ownerSeen && sceneSeen) {
            ordered = t0 <= ownerTime && ownerTime <= sceneTime
        }
        let afterProjectionA = windowA.windowProjection()
        let motionAfter = if (motionActivity) {
            if (let Some(status) <- windowA.animatedNodeTranslation(motionKey)) { status.active } else { false }
        } else { true }
        motionSamplesValid = motionSamplesValid && motionBefore && motionAfter
        let actionDelta = controllerA.actionCount() - beforeAction
        let genericDelta = controllerA.genericCount() - beforeGeneric
        let submissionDelta = afterProjectionA.nativeSubmissionCount - beforeProjectionA.nativeSubmissionCount
        let acceptedDelta = afterProjectionA.acceptedSceneVersion - beforeProjectionA.acceptedSceneVersion
        let tokens = ArrayList<String>()
        if (actionDelta > 0) { tokens.add("action") }
        if (genericDelta > 0) { tokens.add("generic") }
        if (submissionDelta > 0) { tokens.add("submit") }
        if (acceptedDelta > 0) { tokens.add("accepted") }
        var aProgress = "none"
        if (tokens.size > 0) {
            aProgress = joinTokenList(tokens)
        }
        let aProgressed = tokens.size > 0
        aProgressEverySample = aProgressEverySample && aProgressed

        var readyOwnerNs: Int64 = -1
        var ownerSceneNs: Int64 = -1
        var readySceneNs: Int64 = -1
        if (ownerSeen) {
            readyOwnerNs = (ownerTime - t0).toNanoseconds()
        }
        if (ownerSeen && sceneSeen) {
            ownerSceneNs = (sceneTime - ownerTime).toNanoseconds()
        }
        if (sceneSeen) {
            readySceneNs = (sceneTime - t0).toNanoseconds()
        }
        if (readyOwnerNs >= 0) { readyToOwner.add(readyOwnerNs) }
        if (ownerSceneNs >= 0) { ownerToScene.add(ownerSceneNs) }
        if (readySceneNs >= 0) { readyToScene.add(readySceneNs) }

        let sampleValid = applySeen && sceneSeen && ownerSeen && ordered && applyMatched && aProgressed &&
            motionBefore && motionAfter &&
            downStatus == CJGUI_INTERNAL_RENDERER_OK && upStatus == CJGUI_INTERNAL_RENDERER_OK &&
            downTurn.isOpen && hostOpen
        samplesValid = samplesValid && sampleValid
        println("CJGUI_INTERACTION_SCHEDULING_LATENCY_SAMPLE index=${index} value=${value} t0_ns=${(t0 - origin).toNanoseconds()} t1_ns=${(ownerTime - origin).toNanoseconds()} t2_ns=${(sceneTime - origin).toNanoseconds()} owner_to_scene_ns=${ownerSceneNs} ready_to_owner_ns=${readyOwnerNs} ready_to_scene_ns=${readySceneNs} a_progress=${aProgress} motion_before=${motionBefore} motion_after=${motionAfter} valid=${sampleValid} t0_abs_ns=${(t0 - origin).toNanoseconds()} t1_abs_ns=${(ownerTime - origin).toNanoseconds()} t2_abs_ns=${(sceneTime - origin).toNanoseconds()} ready_sequence=${expectedSequence} observer_count=${observer.count()} apply_version_after=${timing.lastApplyVersionAfter()} accepted_text=${acceptedOwnerText(windowB)} pump_rounds=${pumpRounds} down_status=${downStatus} up_status=${upStatus} down_turn_open=${downTurn.isOpen}")
        getStdOut().flush()
        if (motionActivity && index < LATENCY_SAMPLE_COUNT &&
            !windowA.animateNodeTranslation(motionKey, if (index % 2 == 0) { 4.0 } else { 0.0 },
                0.0, spec: motionSpec, atTime: MonoTime.now())) { return false }
        writeMarkerFile(acceptedPath, "index=${index} value=${value}\n")
        index += 1
    }
    if (motionActivity && !windowA.stopNodeTranslationAnimation(motionKey, atTime: MonoTime.now())) {
        return false
    }
    // The final pointer-up can still own its hover paint transition after the
    // position channel stops. Give that finite existing channel its normal
    // turns before taking the idle baseline; failure to settle stays visible.
    var motionSettleTurns: Int64 = 0
    var stableTurns: Int64 = 0
    var lastSubmission = windowA.windowProjection().nativeSubmissionCount
    while (motionActivity && motionSettleTurns < 100 && stableTurns < 3) {
        let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
        if (!turn.isOpen) { return false }
        let nowSubmission = windowA.windowProjection().nativeSubmissionCount
        if (!windowA.needsAnimationTick() && nowSubmission == lastSubmission) {
            stableTurns += 1
        } else {
            stableTurns = 0
        }
        lastSubmission = nowSubmission
        motionSettleTurns += 1
    }
    if (motionActivity && stableTurns < 3) { return false }

    // Idle check after the last sample: the same host, with all external work
    // drained, must stop building, laying out and submitting on its own.
    let idleABefore = windowA.windowProjection()
    let idleBBefore = windowB.windowProjection()
    let idleDiagnosticsBefore = connection.transportDiagnostics()
    var readyQueueBefore: Int64 = -1
    if (let Some(diagnostics) <- idleDiagnosticsBefore) {
        readyQueueBefore = diagnostics.readyRequestCount
    }
    var idleExternalActions: Int64 = 0
    var idleTurnsSeen: Int64 = 0
    var idleTurnsClean = true
    while (idleTurnsSeen < 3) {
        let idleTurn = application.pumpOneTurn(turnBudgetMs: 0u32)
        idleExternalActions += idleTurn.externalActionCount
        if (!idleTurn.isOpen || idleTurn.externalActionCount != 0) {
            idleTurnsClean = false
        }
        idleTurnsSeen += 1
    }
    let idleAAfter = windowA.windowProjection()
    let idleBAfter = windowB.windowProjection()
    let idleDiagnosticsAfter = connection.transportDiagnostics()
    var readyQueueAfter: Int64 = -1
    if (let Some(diagnostics) <- idleDiagnosticsAfter) {
        readyQueueAfter = diagnostics.readyRequestCount
    }
    let aBuildDelta = idleAAfter.buildPassCount - idleABefore.buildPassCount
    let aLayoutDelta = idleAAfter.layoutPassCount - idleABefore.layoutPassCount
    let aSubmissionDelta = idleAAfter.nativeSubmissionCount - idleABefore.nativeSubmissionCount
    let aAcceptedDelta = idleAAfter.acceptedSceneVersion - idleABefore.acceptedSceneVersion
    let bBuildDelta = idleBAfter.buildPassCount - idleBBefore.buildPassCount
    let bLayoutDelta = idleBAfter.layoutPassCount - idleBBefore.layoutPassCount
    let bSubmissionDelta = idleBAfter.nativeSubmissionCount - idleBBefore.nativeSubmissionCount
    let bAcceptedDelta = idleBAfter.acceptedSceneVersion - idleBBefore.acceptedSceneVersion
    let idleUnchanged = aBuildDelta == 0 && aLayoutDelta == 0 && aSubmissionDelta == 0 && aAcceptedDelta == 0 &&
        bBuildDelta == 0 && bLayoutDelta == 0 && bSubmissionDelta == 0 && bAcceptedDelta == 0
    let idleClean = idleTurnsClean && idleUnchanged && idleExternalActions == 0 && readyQueueAfter == 0

    let readyToOwnerSorted = sortedSampleCopy(readyToOwner)
    let ownerToSceneSorted = sortedSampleCopy(ownerToScene)
    let readyToSceneSorted = sortedSampleCopy(readyToScene)
    let p50ReadyOwner = percentileNearestRank(readyToOwnerSorted, 50, 100)
    let p95ReadyOwner = percentileNearestRank(readyToOwnerSorted, 95, 100)
    let p50ReadyScene = percentileNearestRank(readyToSceneSorted, 50, 100)
    let p95ReadyScene = percentileNearestRank(readyToSceneSorted, 95, 100)
    let maxReadyScene = percentileNearestRank(readyToSceneSorted, 100, 100)
    let maxReadyOwner = percentileNearestRank(readyToOwnerSorted, 100, 100)
    let maxOwnerScene = percentileNearestRank(ownerToSceneSorted, 100, 100)
    let recordCount = Int64(readyToScene.size)
    let observedRequests = observer.count()
    let expectedRequests = LATENCY_PRE_MEASUREMENT_READY_COUNT + LATENCY_SAMPLE_COUNT
    let recordsComplete = recordCount == LATENCY_SAMPLE_COUNT
    let requestAccountingExact = observedRequests == expectedRequests
    let valid = samplesValid && motionSamplesValid && aProgressEverySample && idleClean &&
        recordsComplete && requestAccountingExact
    println("CJGUI_INTERACTION_SCHEDULING_LATENCY_RESULT samples=${LATENCY_SAMPLE_COUNT} valid=${valid} motion_activity=${motionActivity} motion_samples_valid=${motionSamplesValid} motion_settle_turns=${motionSettleTurns} p50_ready_to_owner_ns=${p50ReadyOwner} p95_ready_to_owner_ns=${p95ReadyOwner} p50_ready_to_scene_ns=${p50ReadyScene} p95_ready_to_scene_ns=${p95ReadyScene} max_ready_to_scene_ns=${maxReadyScene} max_ready_to_owner_ns=${maxReadyOwner} max_owner_to_scene_ns=${maxOwnerScene} records=${recordCount} observer_requests=${observedRequests} expected_observer_requests=${expectedRequests} samples_valid=${samplesValid} a_progress_every_sample=${aProgressEverySample} idle_clean=${idleClean} idle_external_actions=${idleExternalActions} idle_turns=${idleTurnsSeen} idle_a_build_delta=${aBuildDelta} idle_a_layout_delta=${aLayoutDelta} idle_a_submission_delta=${aSubmissionDelta} idle_a_accepted_delta=${aAcceptedDelta} idle_b_build_delta=${bBuildDelta} idle_b_layout_delta=${bLayoutDelta} idle_b_submission_delta=${bSubmissionDelta} idle_b_accepted_delta=${bAcceptedDelta} ready_queue_before=${readyQueueBefore} ready_queue_after=${readyQueueAfter}")
    getStdOut().flush()
    if (!valid) {
        println("FAIL_LATENCY_SAMPLES records=${recordCount} samples_valid=${samplesValid} a_progress_every_sample=${aProgressEverySample} idle_clean=${idleClean} observer_requests=${observedRequests} expected_observer_requests=${expectedRequests}")
        getStdOut().flush()
    }
    return valid
}

private func run(options: SchedulingOptions): Int64 {
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(DOCUMENT_A, "scheduling-A", "A"),
        CjguiTextDocument(DOCUMENT_B, "scheduling-B", "B")
    ]))
    let application = CjguiMacosApplication(maximumWindowCount: 2)
    // The process host is part of the measurement: a probe that is not running
    // under the macOS application launcher has no enabled main-thread dispatch,
    // so every renderer operation from the runtime worker would be refused as
    // NOT_MAIN_THREAD. Report that state once, before any window opens, so a
    // harness bootstrap problem cannot be misread as a scheduling defect.
    println("CJGUI_INTERACTION_SCHEDULING_HOST ${mainThreadState()}")
    getStdOut().flush()
    let configuration = CjguiMacosApplicationWindowConfiguration("CJGUI Interaction Scheduling", 480u32, 260u32)
    let controllerB = SchedulingBController(workspace)
    if (options.latencyOnly || options.latencyMotion || options.submitGateOnly) {
        return runLatencyMode(options, workspace, application, configuration, controllerB)
    }
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
            windowA.testSessionToken(), sessionB, options.ackDirectory, emptyText, connection)
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
                scaleSession, sessionB, options.ackDirectory, emptyText, connection)
            // Keep the final A window open for the failure-candidate and idle
            // checks; smaller scale windows are closed after their samples.
            let failureBefore = scaleWindow.displayedSceneVersion()
            let failureSubmissionBefore = scaleWindow.windowProjection().nativeSubmissionCount
            let forceFailure = unsafe {
                cjgui_internal_renderer_test_set_composable_present_failures(scaleSession, 1u32)
            }
            // The controlled candidate must be an INTERACTION PAINT: the
            // hovered control here is the A action button (index 1), which is
            // the node that actually carries a hover paint style. Clearing that
            // slot requests exactly one paint; entering a control without an
            // interaction style would request nothing, and re-entering the same
            // slot would be a no-op. One change, one deferred submission.
            let failureLeave = unsafe {
                cjgui_internal_renderer_test_enqueue_composable_event(scaleSession, 1u32, 44u32, emptyText)
            }
            let failureEnqueue = failureLeave
            let failureTurn = application.pumpOneTurn(turnBudgetMs: 16u32)
            let _ = failureEnqueue
            // The interaction event itself only MARKS the projection; the
            // coalesced paint submission happens on the NEXT turn's refresh. The
            // injected native failure must therefore be observed on that
            // deferred turn, not on the turn that drained the FIFO.
            let failureSettleTurn = application.pumpOneTurn(turnBudgetMs: 16u32)
            let failureTrace = nativeInteractionTrace(scaleSession)
            let failureProjection = scaleWindow.windowProjection()
            failedCandidateRetained = forceFailure == CJGUI_INTERNAL_RENDERER_OK &&
                failureLeave == CJGUI_INTERNAL_RENDERER_OK && failureEnqueue == CJGUI_INTERNAL_RENDERER_OK &&
                failureTurn.isOpen && failureSettleTurn.isOpen &&
                scaleWindow.displayedSceneVersion() == failureBefore &&
                failureProjection.pendingRefreshReason == "interaction_paint_internal_error" &&
                failureProjection.lastNativeFailure == "internal_error" &&
                failureProjection.nativeSubmissionCount == failureSubmissionBefore
            let healthyRetry = scaleWindow.refresh()
            let recoveredProjection = scaleWindow.windowProjection()
            failedCandidateRecovered = healthyRetry && scaleWindow.nativeStatus() == CJGUI_INTERNAL_RENDERER_OK &&
                recoveredProjection.pendingRefreshReason == "none" &&
                recoveredProjection.nativeSubmissionCount > failureSubmissionBefore
            println("CJGUI_INTERACTION_SCHEDULING_FAILURE_CANDIDATE force_status=${forceFailure} leave_status=${failureLeave} enqueue_status=${failureEnqueue} turn_open=${failureTurn.isOpen} scene_before=${failureBefore} scene_after=${scaleWindow.displayedSceneVersion()} settle_turn_open=${failureSettleTurn.isOpen} failure_pending=${failureProjection.pendingRefreshReason} failure_reason=${failureProjection.lastNativeFailure} submissions_before=${failureSubmissionBefore} submissions_after_failure=${failureProjection.nativeSubmissionCount} retry_ok=${healthyRetry} retry_pending=${recoveredProjection.pendingRefreshReason} submissions_after_retry=${recoveredProjection.nativeSubmissionCount} retained=${failedCandidateRetained} recovered=${failedCandidateRecovered} enqueued_kind=${failureTrace.lastEnqueuedKind} pumped_kind=${failureTrace.lastPumpedKind} enqueued_node=${failureTrace.lastEnqueuedNodeId} pumped_node=${failureTrace.lastPumpedNodeId} pending_trace=${failureTrace.pending}")
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
    getStdErr().writeln("usage: interaction_scheduling_efficiency_probe --ack-dir PATH [--overlap-only|--latency-only]")
    return 2
}
