package cjgui

foreign {
    func cjgui_internal_renderer_test_enqueue_composable_wheel(
        session: UInt64, nodeId: UInt64, deltaY: Float64, phase: UInt32, momentum: UInt32
    ): Int32
    func cjgui_internal_renderer_test_enqueue_composable_wheel_override(
        session: UInt64, nodeId: UInt64, projectionVersion: UInt64, resourceId: Int64,
        nodeKind: UInt32, payload: CString
    ): Int32
}

private let QUEUED_WHEEL_ROOT_ID: Int64 = 9300
private let QUEUED_WHEEL_NODE_ID: Int64 = 9301

/// A deliberately ordinary HORIZONTAL container: it is wheel eligible by
/// declaration, but it owns no scroll viewport, click target or focus scope.
/// Viewport owner A→B→A is therefore inapplicable to this consumer.
private class QueuedWheelBindingController <: CjguiComposableUiController &
    CjguiComposableUiWheelDeltaConsumer {
    private var revisionValue: Int64 = 1
    private var resourceValue: Int64 = 41
    private var actionValue: String = "SCROLL_A"
    private var incarnationValue: Int64 = 1
    private var presentValue: Bool = true
    private var enabledValue: Bool = true
    private var wheelValue: Bool = true
    private var paintValue: Int64 = 0
    private var inputScopeValue: String = ""
    private var inputControlValue: Bool = false
    private var pointerInteractiveValue: Bool = false
    private var interactionPaintValue: Bool = false
    private var viewportValue: ?CjguiComposableUiScrollViewport = None
    private var consumesDeltaValue: Bool = true
    private var lastWheelSerialValue: Int64 = 0
    private var lastFrameworkScrollValue: Bool = false
    private var lastRequestedBeforeValue: Int64 = 0
    private var lastRequestedAfterValue: Int64 = 0
    private var lastAcceptedBeforeValue: Int64 = 0
    private var lastAcceptedAfterValue: Int64 = 0
    private var accumulatedYValue: Float64 = 0.0
    private var packetCountValue: Int64 = 0
    private var lifecyclePacketCountValue: Int64 = 0
    private var rejectedCountValue: Int64 = 0
    private var appliedResourceValue: Int64 = -1
    private var appliedActionValue: String = ""
    private var appliedIncarnationValue: Int64 = -1
    private var phaseTraceValue: String = ""
    private var dispatchTraceValue: String = ""

    public func uiSceneVersion(): Int64 { return revisionValue }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(QUEUED_WHEEL_ROOT_ID, "queued-wheel-root",
            CjguiComposableUiStyle(fixedWidth: 320, fixedHeight: 220))
        if (presentValue) {
            let background = if (paintValue == 0) {
                CjguiComposableUiColor(0.12, 0.16, 0.22, 1.0)
            } else {
                CjguiComposableUiColor(0.18, 0.24, 0.12, 1.0)
            }
            let style = CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 140,
                background: background, wheelScrollable: wheelValue,
                pointerInteractive: pointerInteractiveValue)
            if (let Some(viewport) <- viewportValue) {
                let target = cjguiComposableScrollArea(QUEUED_WHEEL_NODE_ID, "queued-wheel-owner",
                    viewport, style, enabled: enabledValue)
                target.add(cjguiComposableVertical(9302, "queued-wheel-content",
                    CjguiComposableUiStyle(fixedHeight: 360)))
                root.add(target)
            } else {
                let interaction = if (interactionPaintValue) {
                    CjguiComposableUiInteractionStyle(hover: CjguiComposableUiPaintStyle(
                        background: Some(CjguiComposableUiColor(0.75, 0.25, 0.1, 1.0))))
                } else {
                    CjguiComposableUiInteractionStyle()
                }
                let kind = if (inputControlValue) { CJGUI_COMPOSABLE_UI_BUTTON } else {
                    CJGUI_COMPOSABLE_UI_HORIZONTAL
                }
                let target = CjguiComposableUiNode(QUEUED_WHEEL_NODE_ID, "queued-wheel-owner",
                    kind, "wheel owner", "", actionValue, resourceValue, style,
                    enabled: enabledValue, inputScopeId: inputScopeValue,
                    semanticKey: "queued-wheel-owner", semanticIncarnation: incarnationValue,
                    interactionStyle: interaction)
                root.add(target)
            }
        }
        return root
    }

    public func consumesWheelDelta(node: CjguiComposableUiLayoutNode): Bool {
        return consumesDeltaValue && node.nodeId == QUEUED_WHEEL_NODE_ID
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_SCROLL &&
            event.node.nodeId == QUEUED_WHEEL_NODE_ID) {
            if (let Some(delta) <- event.wheelDelta) {
                lastWheelSerialValue = event.wheelEventSerial
                lastFrameworkScrollValue = event.frameworkScrollApplied
                lastRequestedBeforeValue = event.scrollRequestedBefore
                lastRequestedAfterValue = event.scrollRequestedAfter
                lastAcceptedBeforeValue = event.scrollAcceptedBefore
                lastAcceptedAfterValue = event.scrollAcceptedAfter
                accumulatedYValue += delta.deltaY
                packetCountValue += 1
                // Count each delivered phase packet, including the zero-delta
                // Ended packet, as a lifecycle observation by the owner.
                lifecyclePacketCountValue += 1
                appliedResourceValue = event.node.resourceId
                appliedActionValue = event.node.actionName
                appliedIncarnationValue = event.node.semanticIncarnation
                phaseTraceValue += "${delta.phase}:${delta.momentumPhase}:${delta.deltaY};"
                dispatchTraceValue += "accept;"
                revisionValue += 1
                return CjguiComposableUiDispatchResult(true)
            }
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        if (eventKind == CJGUI_COMPOSABLE_UI_EVENT_SCROLL && nodeId == QUEUED_WHEEL_NODE_ID) {
            rejectedCountValue += 1
            dispatchTraceValue += "reject;"
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func accumulatedY(): Float64 { return accumulatedYValue }
    public func packetCount(): Int64 { return packetCountValue }
    public func lifecyclePacketCount(): Int64 { return lifecyclePacketCountValue }
    public func rejectedCount(): Int64 { return rejectedCountValue }
    public func appliedResource(): Int64 { return appliedResourceValue }
    public func appliedAction(): String { return appliedActionValue }
    public func appliedIncarnation(): Int64 { return appliedIncarnationValue }
    public func phaseTrace(): String { return phaseTraceValue }
    public func dispatchTrace(): String { return dispatchTraceValue }
    public func lastWheelSerial(): Int64 { return lastWheelSerialValue }
    public func lastFrameworkScroll(): Bool { return lastFrameworkScrollValue }
    public func lastRequestedBefore(): Int64 { return lastRequestedBeforeValue }
    public func lastRequestedAfter(): Int64 { return lastRequestedAfterValue }
    public func lastAcceptedBefore(): Int64 { return lastAcceptedBeforeValue }
    public func lastAcceptedAfter(): Int64 { return lastAcceptedAfterValue }

    public func changePaint(): Unit { paintValue = 1 - paintValue; revisionValue += 1 }
    public func rebind(resource: Int64, action: String): Unit {
        resourceValue = resource
        actionValue = action
        revisionValue += 1
    }
    public func setIncarnation(value: Int64): Unit { incarnationValue = value; revisionValue += 1 }
    public func setPresent(value: Bool): Unit { presentValue = value; revisionValue += 1 }
    public func setEnabled(value: Bool): Unit { enabledValue = value; revisionValue += 1 }
    public func setWheelEligible(value: Bool): Unit { wheelValue = value; revisionValue += 1 }
    public func setInputScope(value: String): Unit { inputScopeValue = value; revisionValue += 1 }
    public func setInputControl(value: Bool): Unit { inputControlValue = value; revisionValue += 1 }
    public func setPointerInteractive(value: Bool): Unit { pointerInteractiveValue = value; revisionValue += 1 }
    public func setInteractionPaint(value: Bool): Unit { interactionPaintValue = value; revisionValue += 1 }
    public func bindViewport(value: ?CjguiComposableUiScrollViewport): Unit {
        viewportValue = value
        revisionValue += 1
    }
    public func setConsumesDelta(value: Bool): Unit { consumesDeltaValue = value }
}

@Test
func composableQueuedWheelReportsOneFrameworkViewportStepToOrdinaryConsumer(): Unit {
    let controller = QueuedWheelBindingController()
    let viewport = CjguiComposableUiScrollViewport()
    controller.bindViewport(Some(viewport))
    controller.setConsumesDelta(false)
    let window = queuedWheelWindow(controller)
    try {
        @Assert(window.start(), true)
        let oldAccepted = viewport.acceptedOffset()
        @Assert(queuedWheelEnqueue(window.testSessionToken(), -1.0, 1u32), 0)
        @Assert(window.pump(0u32).isOpen, true)
        @Assert(controller.packetCount(), 1)
        @Assert(controller.lastWheelSerial() > 0, true)
        @Assert(controller.lastFrameworkScroll(), true)
        @Assert(controller.lastRequestedAfter() != controller.lastRequestedBefore(), true)
        @Assert(controller.lastAcceptedBefore(), oldAccepted)
        @Assert(controller.lastAcceptedAfter(), oldAccepted)
    } finally { window.close() }
}

private func queuedWheelEnqueue(session: UInt64, deltaY: Float64, phase: UInt32): Int32 {
    return unsafe {
        cjgui_internal_renderer_test_enqueue_composable_wheel(
            session, UInt64(QUEUED_WHEEL_NODE_ID), deltaY, phase, 0u32)
    }
}

private func queuedWheelEnqueueMomentum(session: UInt64, deltaY: Float64, phase: UInt32,
    momentum: UInt32): Int32 {
    return unsafe {
        cjgui_internal_renderer_test_enqueue_composable_wheel(
            session, UInt64(QUEUED_WHEEL_NODE_ID), deltaY, phase, momentum)
    }
}

/// This deliberately corrupts the last queued envelope after the native test
/// seam performs a real FIFO enqueue. It is evidence about admission checks,
/// never evidence that AppKit emitted the packet.
private func queuedWheelEnqueueForged(session: UInt64, projectionVersion: UInt64,
    resourceId: Int64, nodeKind: UInt32, payload: String): Int32 {
    unsafe {
        let cPayload = LibC.mallocCString(payload)
        let result = cjgui_internal_renderer_test_enqueue_composable_wheel_override(
            session, UInt64(QUEUED_WHEEL_NODE_ID), projectionVersion, resourceId, nodeKind, cPayload)
        LibC.free(cPayload)
        return result
    }
}

private func queuedWheelWindow(controller: QueuedWheelBindingController): CjguiComposableUiWindow {
    return CjguiComposableUiWindow(controller)
}

private func queuedWheelAcceptedResource(window: CjguiComposableUiWindow): Int64 {
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == QUEUED_WHEEL_NODE_ID) { return node.resourceId }
    }
    return -1
}

@Test
func composableQueuedWheelPaintAdvanceKeepsQueuedGesture(): Unit {
    let controller = QueuedWheelBindingController()
    let window = queuedWheelWindow(controller)
    try {
        @Assert(window.start(), true)
        window.testSetSceneWriteTrace(true)
        let session = window.testSessionToken()
        let versionBefore = window.displayedSceneVersion()
        let revisionBefore = controller.uiSceneVersion()
        let begin = queuedWheelEnqueue(session, -1.0, 1u32)
        let changed = queuedWheelEnqueue(session, -1.0, 4u32)
        let ended = queuedWheelEnqueue(session, 0.0, 8u32)

        controller.changePaint()
        let refreshAccepted = window.refreshIfNeeded()
        let versionAfter = window.displayedSceneVersion()
        let projectionAfter = window.acceptedSceneDump()
        let turn = window.pump(0u32)
        println("CJGUI_QUEUED_WHEEL_PAINT version=${versionBefore}->${versionAfter} enqueue=${begin},${changed},${ended} " +
            "refresh=${refreshAccepted} packets=${controller.packetCount()} lifecycle=${controller.lifecyclePacketCount()} " +
            "deltaY=${controller.accumulatedY()} rejected=${controller.rejectedCount()} revision=${revisionBefore}->${controller.uiSceneVersion()} " +
            "open=${turn.isOpen}")

        @Assert(begin, 0)
        @Assert(changed, 0)
        @Assert(ended, 0)
        @Assert(refreshAccepted, true)
        @Assert(versionAfter, versionBefore + 1)
        @Assert(projectionAfter.contains("queued-wheel-owner"), true)
        @Assert(turn.isOpen, true)
        @Assert(controller.accumulatedY(), -2.0)
        @Assert(controller.packetCount(), 3)
        @Assert(controller.lifecyclePacketCount(), 3)
        @Assert(controller.rejectedCount(), 0)
        @Assert(controller.uiSceneVersion(), revisionBefore + 4)
    } finally { window.close() }
}

@Test
func composableQueuedWheelResourceActionRebindRejectsOldTicket(): Unit {
    let controller = QueuedWheelBindingController()
    let window = queuedWheelWindow(controller)
    try {
        @Assert(window.start(), true)
        let session = window.testSessionToken()
        let old = queuedWheelEnqueue(session, -1.0, 1u32)
        controller.rebind(82, "SCROLL_B")
        let rebound = window.refreshIfNeeded()
        let staleTurn = window.pump(0u32)
        let rejectedOld = controller.packetCount() == 0 && controller.rejectedCount() == 1 &&
            controller.accumulatedY() == 0.0
        let fresh = queuedWheelEnqueue(session, 0.25, 4u32)
        let freshTurn = window.pump(0u32)
        println("CJGUI_QUEUED_WHEEL_REBIND enqueue=${old}/${fresh} accepted=${rebound} " +
            "old=${staleTurn.isOpen}/${controller.rejectedCount()} fresh=${freshTurn.isOpen}/" +
            "${controller.accumulatedY()}/${controller.appliedResource()}/${controller.appliedAction()}")
        @Assert(old, 0)
        @Assert(rebound, true)
        @Assert(rejectedOld, true)
        @Assert(fresh, 0)
        @Assert(freshTurn.isOpen, true)
        @Assert(controller.packetCount(), 1)
        @Assert(controller.accumulatedY(), 0.25)
        @Assert(controller.appliedResource(), 82)
        @Assert(controller.appliedAction(), "SCROLL_B")
        @Assert(controller.rejectedCount(), 1)
    } finally { window.close() }
}

@Test
func composableQueuedWheelSemanticIncarnationRejectsOldTicket(): Unit {
    let controller = QueuedWheelBindingController()
    let window = queuedWheelWindow(controller)
    try {
        @Assert(window.start(), true)
        let session = window.testSessionToken()
        let old = queuedWheelEnqueue(session, -1.0, 1u32)
        controller.setIncarnation(2)
        let rebound = window.refreshIfNeeded()
        let staleTurn = window.pump(0u32)
        let fresh = queuedWheelEnqueue(session, 0.5, 4u32)
        let freshTurn = window.pump(0u32)
        println("CJGUI_QUEUED_WHEEL_INCARNATION enqueue=${old}/${fresh} accepted=${rebound} " +
            "old=${staleTurn.isOpen}/${controller.rejectedCount()} fresh=${freshTurn.isOpen}/" +
            "${controller.accumulatedY()}/${controller.appliedIncarnation()}")
        @Assert(old, 0)
        @Assert(rebound, true)
        @Assert(controller.packetCount(), 1)
        @Assert(controller.accumulatedY(), 0.5)
        @Assert(controller.appliedIncarnation(), 2)
        @Assert(controller.rejectedCount(), 1)
    } finally { window.close() }
}

@Test
func composableQueuedWheelRemoveReaddSameIdRejectsOldTicket(): Unit {
    let controller = QueuedWheelBindingController()
    let window = queuedWheelWindow(controller)
    try {
        @Assert(window.start(), true)
        let session = window.testSessionToken()
        let old = queuedWheelEnqueue(session, -1.0, 1u32)
        controller.setPresent(false)
        let removed = window.refreshIfNeeded()
        controller.setPresent(true)
        let readded = window.refreshIfNeeded()
        let staleTurn = window.pump(0u32)
        let oldRejected = controller.packetCount() == 0 && controller.rejectedCount() == 1 &&
            controller.accumulatedY() == 0.0
        let fresh = queuedWheelEnqueue(session, 0.5, 4u32)
        let freshTurn = window.pump(0u32)
        println("CJGUI_QUEUED_WHEEL_READD enqueue=${old}/${fresh} removed=${removed} readded=${readded} " +
            "old=${staleTurn.isOpen}/${controller.rejectedCount()} fresh=${freshTurn.isOpen}/${controller.accumulatedY()}")
        @Assert(old, 0)
        @Assert(removed, true)
        @Assert(readded, true)
        @Assert(oldRejected, true)
        @Assert(fresh, 0)
        @Assert(freshTurn.isOpen, true)
        @Assert(controller.packetCount(), 1)
        @Assert(controller.accumulatedY(), 0.5)
        @Assert(controller.rejectedCount(), 1)
    } finally { window.close() }
}

@Test
func composableQueuedWheelDisableEnableRejectsOldTicket(): Unit {
    let controller = QueuedWheelBindingController()
    let window = queuedWheelWindow(controller)
    try {
        @Assert(window.start(), true)
        let session = window.testSessionToken()
        let old = queuedWheelEnqueue(session, -1.0, 1u32)
        controller.setEnabled(false)
        let disabled = window.refreshIfNeeded()
        controller.setEnabled(true)
        let enabled = window.refreshIfNeeded()
        let staleTurn = window.pump(0u32)
        let oldRejected = controller.packetCount() == 0 && controller.rejectedCount() == 1 &&
            controller.accumulatedY() == 0.0
        let fresh = queuedWheelEnqueue(session, 0.5, 4u32)
        let freshTurn = window.pump(0u32)
        println("CJGUI_QUEUED_WHEEL_ENABLE enqueue=${old}/${fresh} disabled=${disabled} enabled=${enabled} " +
            "old=${staleTurn.isOpen}/${controller.rejectedCount()} fresh=${freshTurn.isOpen}/${controller.accumulatedY()}")
        @Assert(old, 0)
        @Assert(disabled, true)
        @Assert(enabled, true)
        @Assert(oldRejected, true)
        @Assert(fresh, 0)
        @Assert(freshTurn.isOpen, true)
        @Assert(controller.packetCount(), 1)
        @Assert(controller.accumulatedY(), 0.5)
        @Assert(controller.rejectedCount(), 1)
    } finally { window.close() }
}

@Test
func composableQueuedWheelEligibilityToggleRejectsOldTicket(): Unit {
    let controller = QueuedWheelBindingController()
    let window = queuedWheelWindow(controller)
    try {
        @Assert(window.start(), true)
        let session = window.testSessionToken()
        let old = queuedWheelEnqueue(session, -1.0, 1u32)
        controller.setWheelEligible(false)
        let ineligible = window.refreshIfNeeded()
        controller.setWheelEligible(true)
        let eligible = window.refreshIfNeeded()
        let staleTurn = window.pump(0u32)
        let oldRejected = controller.packetCount() == 0 && controller.rejectedCount() == 1 &&
            controller.accumulatedY() == 0.0
        let fresh = queuedWheelEnqueue(session, 0.5, 4u32)
        let freshTurn = window.pump(0u32)
        println("CJGUI_QUEUED_WHEEL_ELIGIBILITY enqueue=${old}/${fresh} ineligible=${ineligible} eligible=${eligible} " +
            "old=${staleTurn.isOpen}/${controller.rejectedCount()} fresh=${freshTurn.isOpen}/${controller.accumulatedY()}")
        @Assert(old, 0)
        @Assert(ineligible, true)
        @Assert(eligible, true)
        @Assert(oldRejected, true)
        @Assert(fresh, 0)
        @Assert(freshTurn.isOpen, true)
        @Assert(controller.packetCount(), 1)
        @Assert(controller.accumulatedY(), 0.5)
        @Assert(controller.rejectedCount(), 1)
    } finally { window.close() }
}

@Test
func composableQueuedWheelViewportOwnerAbaRejectsOldTicket(): Unit {
    let controller = QueuedWheelBindingController()
    let viewportA = CjguiComposableUiScrollViewport()
    let viewportB = CjguiComposableUiScrollViewport()
    controller.bindViewport(Some(viewportA))
    let window = queuedWheelWindow(controller)
    try {
        @Assert(viewportA.viewStateIdentity() != viewportB.viewStateIdentity(), true)
        @Assert(window.start(), true)
        let session = window.testSessionToken()
        let acceptedBefore = window.displayedSceneVersion()
        let old = queuedWheelEnqueue(session, -1.0, 1u32)

        controller.bindViewport(Some(viewportB))
        let acceptedB = window.refreshIfNeeded()
        let versionB = window.displayedSceneVersion()
        let ownerMovedToB = viewportA.ownerWindowToken() == 0 && viewportB.ownerWindowToken() > 0
        controller.bindViewport(Some(viewportA))
        let acceptedAAgain = window.refreshIfNeeded()
        let versionAAgain = window.displayedSceneVersion()
        let ownerReturnedToA = viewportA.ownerWindowToken() > 0 && viewportB.ownerWindowToken() == 0
        let staleTurn = window.pump(0u32)
        let oldRejected = controller.packetCount() == 0 && controller.rejectedCount() == 1 &&
            controller.accumulatedY() == 0.0
        let fresh = queuedWheelEnqueue(session, 0.5, 4u32)
        let freshTurn = window.pump(0u32)
        println("CJGUI_QUEUED_WHEEL_VIEWPORT_ABA version=${acceptedBefore}->${versionB}->${versionAAgain} " +
            "accepted=${acceptedB}/${acceptedAAgain} owners=${ownerMovedToB}/${ownerReturnedToA} " +
            "old=${old}/${staleTurn.isOpen}/${controller.rejectedCount()} fresh=${fresh}/${freshTurn.isOpen}/" +
            "${controller.accumulatedY()}")
        @Assert(old, 0)
        @Assert(acceptedB, true)
        @Assert(acceptedAAgain, true)
        @Assert(versionB > acceptedBefore, true)
        @Assert(versionAAgain > versionB, true)
        @Assert(ownerMovedToB, true)
        @Assert(ownerReturnedToA, true)
        @Assert(oldRejected, true)
        @Assert(fresh, 0)
        @Assert(freshTurn.isOpen, true)
        @Assert(controller.packetCount(), 1)
        @Assert(controller.accumulatedY(), 0.5)
        @Assert(controller.rejectedCount(), 1)
    } finally { window.close() }
}

@Test
func composableQueuedWheelInputScopeAbaRejectsOldTicket(): Unit {
    let controller = QueuedWheelBindingController()
    controller.setInputScope("wheel-scope-a")
    let window = queuedWheelWindow(controller)
    try {
        @Assert(window.start(), true)
        let session = window.testSessionToken()
        let acceptedBefore = window.displayedSceneVersion()
        let old = queuedWheelEnqueue(session, -1.0, 1u32)
        controller.setInputScope("wheel-scope-b")
        let acceptedB = window.refreshIfNeeded()
        let versionB = window.displayedSceneVersion()
        controller.setInputScope("wheel-scope-a")
        let acceptedAAgain = window.refreshIfNeeded()
        let versionAAgain = window.displayedSceneVersion()
        let staleTurn = window.pump(0u32)
        let oldRejected = controller.packetCount() == 0 && controller.rejectedCount() == 1 &&
            controller.accumulatedY() == 0.0
        let fresh = queuedWheelEnqueue(session, 0.5, 4u32)
        let freshTurn = window.pump(0u32)
        println("CJGUI_QUEUED_WHEEL_SCOPE_ABA version=${acceptedBefore}->${versionB}->${versionAAgain} " +
            "accepted=${acceptedB}/${acceptedAAgain} old=${old}/${staleTurn.isOpen}/" +
            "${controller.rejectedCount()} fresh=${fresh}/${freshTurn.isOpen}/${controller.accumulatedY()}")
        @Assert(old, 0)
        @Assert(acceptedB, true)
        @Assert(acceptedAAgain, true)
        @Assert(versionB > acceptedBefore, true)
        @Assert(versionAAgain > versionB, true)
        @Assert(oldRejected, true)
        @Assert(fresh, 0)
        @Assert(freshTurn.isOpen, true)
        @Assert(controller.packetCount(), 1)
        @Assert(controller.accumulatedY(), 0.5)
        @Assert(controller.rejectedCount(), 1)
    } finally { window.close() }
}

@Test
func composableQueuedWheelRejectedNativeCandidateKeepsOldTicket(): Unit {
    let controller = QueuedWheelBindingController()
    let window = queuedWheelWindow(controller)
    try {
        @Assert(window.start(), true)
        let session = window.testSessionToken()
        let acceptedVersion = window.displayedSceneVersion()
        let acceptedDump = window.acceptedSceneDump()
        let old = queuedWheelEnqueue(session, -1.0, 1u32)
        controller.changePaint()
        let armed = unsafe { cjgui_internal_renderer_test_set_composable_present_failures(session, 1u32) }
        let candidateAccepted = window.refreshIfNeeded()
        let retainedVersion = window.displayedSceneVersion()
        let retainedDump = window.acceptedSceneDump()
        let staleTicketPump = window.pump(0u32)
        let preserved = retainedVersion == acceptedVersion && retainedDump == acceptedDump &&
            controller.packetCount() == 1 && controller.rejectedCount() == 0 &&
            controller.accumulatedY() == -1.0
        let fresh = queuedWheelEnqueue(session, 0.25, 4u32)
        let freshPump = window.pump(0u32)
        println("CJGUI_QUEUED_WHEEL_NATIVE_REJECT enqueue=${old}/${fresh} arm=${armed} accepted=${candidateAccepted} " +
            "version=${acceptedVersion}->${retainedVersion}->${window.displayedSceneVersion()} " +
            "oldPump=${staleTicketPump.isOpen} freshPump=${freshPump.isOpen} packets=${controller.packetCount()} " +
            "deltaY=${controller.accumulatedY()} rejected=${controller.rejectedCount()}")
        @Assert(old, 0)
        @Assert(armed, CJGUI_INTERNAL_RENDERER_OK)
        @Assert(candidateAccepted, false)
        @Assert(retainedVersion, acceptedVersion)
        @Assert(retainedDump, acceptedDump)
        @Assert(staleTicketPump.isOpen, true)
        @Assert(preserved, true)
        @Assert(fresh, 0)
        @Assert(freshPump.isOpen, true)
        @Assert(controller.packetCount(), 2)
        @Assert(controller.accumulatedY(), -0.75)
        @Assert(controller.rejectedCount(), 0)
    } finally { window.close() }
}

@Test
func composableQueuedWheelLifecycleOrderSurvivesPaintAdvance(): Unit {
    let controller = QueuedWheelBindingController()
    let window = queuedWheelWindow(controller)
    try {
        @Assert(window.start(), true)
        window.testSetSceneWriteTrace(true)
        let session = window.testSessionToken()
        let acceptedP = window.acceptedWheelSceneVersionForTest()
        let birth = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)
        let begin = queuedWheelEnqueue(session, -1.0, 1u32)

        // First BEGIN belongs to P. A paint-only accepted generation must not
        // retire this gesture ticket before the following ordered packets.
        controller.changePaint()
        let paintAccepted = window.refresh()
        let afterPaintP = window.acceptedWheelSceneVersionForTest()
        let afterPaintBirth = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)
        let changed = queuedWheelEnqueue(session, -1.0, 4u32)
        let phaseZero = queuedWheelEnqueueMomentum(session, 0.25, 0u32, 0u32)
        let ended = queuedWheelEnqueue(session, 0.0, 8u32)
        let momentum = queuedWheelEnqueueMomentum(session, 0.5, 0u32, 4u32)
        let cancelled = queuedWheelEnqueue(session, 0.0, 16u32)
        let turn = window.pump(0u32)
        println("CJGUI_QUEUED_WHEEL_PHASES P=${acceptedP}->${afterPaintP} birth=${birth}->${afterPaintBirth} " +
            "enqueue=${begin},${changed},${phaseZero},${ended},${momentum},${cancelled} accepted=${paintAccepted} " +
            "trace=${controller.phaseTrace()} sum=${controller.accumulatedY()} reject=${controller.rejectedCount()}")

        @Assert(begin, 0)
        @Assert(changed, 0)
        @Assert(phaseZero, 0)
        @Assert(ended, 0)
        @Assert(momentum, 0)
        @Assert(cancelled, 0)
        @Assert(paintAccepted, true)
        @Assert(afterPaintP > acceptedP, true)
        @Assert(afterPaintBirth, birth)
        @Assert(turn.isOpen, true)
        let expectedTrace = "1:0:${Float64(-1.0)};4:0:${Float64(-1.0)};0:0:${Float64(0.25)};" +
            "8:0:${Float64(0.0)};0:4:${Float64(0.5)};16:0:${Float64(0.0)};"
        @Assert(controller.phaseTrace(), expectedTrace)
        @Assert(controller.accumulatedY(), -1.25)
        @Assert(controller.packetCount(), 6)
        @Assert(controller.lifecyclePacketCount(), 6)
        @Assert(controller.rejectedCount(), 0)
    } finally { window.close() }
}

@Test
func composableQueuedWheelFullAndInteractionPaintKeepBirth(): Unit {
    let controller = QueuedWheelBindingController()
    controller.setInputControl(true)
    controller.setInteractionPaint(true)
    let window = queuedWheelWindow(controller)
    try {
        @Assert(window.start(), true)
        window.testSetSceneWriteTrace(true)
        let session = window.testSessionToken()
        let initialP = window.acceptedWheelSceneVersionForTest()
        let birth = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)
        let oldTicket = queuedWheelEnqueue(session, -1.0, 1u32)

        controller.changePaint()
        let fullAccepted = window.refresh()
        let fullP = window.acceptedWheelSceneVersionForTest()
        let fullBirth = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)
        let samePixelFullRefresh = window.refresh()
        let samePixelFullP = window.acceptedWheelSceneVersionForTest()
        let samePixelFullBirth = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)

        // The hover target changes at t=0 while the presented pixels remain
        // the same. This exercises the same-pixels path without inventing a
        // native present; advancing the animation then exercises the accepted
        // interaction-paint present.
        @Assert(window.testRefreshInteractionPaint(), true)
        @Assert(window.testApplyInteractionIntent(43u32, QUEUED_WHEEL_NODE_ID), true)
        let samePixelRefresh = window.testRefreshInteractionPaint()
        let samePixelP = window.acceptedWheelSceneVersionForTest()
        let samePixelBirth = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)
        let advanced = window.testAdvanceAnimationsAtMs(90.0)
        let interactionAccepted = window.testRefreshInteractionPaint()
        let interactionP = window.acceptedWheelSceneVersionForTest()
        let interactionBirth = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)
        let turn = window.pump(0u32)
        println("CJGUI_QUEUED_WHEEL_PAINT_BIRTH P=${initialP}->${fullP}->${samePixelFullP}->${samePixelP}->${interactionP} " +
            "birth=${birth}->${fullBirth}->${samePixelFullBirth}->${samePixelBirth}->${interactionBirth} " +
            "accepted=${fullAccepted}/${samePixelFullRefresh}/${samePixelRefresh}/${advanced}/${interactionAccepted} " +
            "old=${oldTicket}/${turn.isOpen} packets=${controller.packetCount()} reject=${controller.rejectedCount()}")

        @Assert(oldTicket, 0)
        @Assert(fullAccepted, true)
        @Assert(fullP > initialP, true)
        @Assert(fullBirth, birth)
        @Assert(samePixelFullRefresh, true)
        @Assert(samePixelFullP, fullP)
        @Assert(samePixelFullBirth, birth)
        @Assert(samePixelRefresh, true)
        @Assert(samePixelP, fullP)
        @Assert(samePixelBirth, birth)
        @Assert(advanced, true)
        @Assert(interactionAccepted, true)
        @Assert(interactionP > samePixelP, true)
        @Assert(interactionBirth, birth)
        @Assert(turn.isOpen, true)
        @Assert(controller.packetCount(), 1)
        @Assert(controller.accumulatedY(), -1.0)
        @Assert(controller.rejectedCount(), 0)
    } finally { window.close() }
}

@Test
func composableQueuedWheelStaleThenFreshShareFifo(): Unit {
    let controller = QueuedWheelBindingController()
    let window = queuedWheelWindow(controller)
    try {
        @Assert(window.start(), true)
        window.testSetSceneWriteTrace(true)
        let session = window.testSessionToken()
        let old = queuedWheelEnqueue(session, -1.0, 1u32)
        controller.rebind(82, "SCROLL_B")
        let rebindAccepted = window.refresh()
        let fresh = queuedWheelEnqueue(session, 0.25, 4u32)
        let turn = window.pump(0u32)
        println("CJGUI_QUEUED_WHEEL_FIFO old=${old} fresh=${fresh} refresh=${rebindAccepted} " +
            "order=${controller.dispatchTrace()} packets=${controller.packetCount()} " +
            "deltaY=${controller.accumulatedY()} reject=${controller.rejectedCount()}")
        @Assert(old, 0)
        @Assert(rebindAccepted, true)
        @Assert(fresh, 0)
        @Assert(turn.isOpen, true)
        @Assert(controller.dispatchTrace(), "reject;accept;")
        @Assert(controller.packetCount(), 1)
        @Assert(controller.accumulatedY(), 0.25)
        @Assert(controller.appliedResource(), 82)
        @Assert(controller.rejectedCount(), 1)
    } finally { window.close() }
}

@Test
func composableQueuedWheelPointerInteractiveCannotBypassWithdrawal(): Unit {
    let controller = QueuedWheelBindingController()
    controller.setInputControl(true)
    controller.setPointerInteractive(true)
    let window = queuedWheelWindow(controller)
    try {
        @Assert(window.start(), true)
        window.testSetSceneWriteTrace(true)
        let session = window.testSessionToken()
        let oldEligible = queuedWheelEnqueue(session, -1.0, 1u32)
        controller.setWheelEligible(false)
        let withdrew = window.refresh()
        let disabledCandidate = queuedWheelEnqueue(session, -0.5, 4u32)
        controller.setWheelEligible(true)
        let restored = window.refresh()
        let fresh = queuedWheelEnqueue(session, 0.25, 4u32)
        let turn = window.pump(0u32)
        println("CJGUI_QUEUED_WHEEL_WITHDRAW old=${oldEligible}/${disabledCandidate}/${fresh} " +
            "withdraw=${withdrew} restored=${restored} order=${controller.dispatchTrace()} " +
            "packets=${controller.packetCount()} deltaY=${controller.accumulatedY()} reject=${controller.rejectedCount()}")
        @Assert(oldEligible, 0)
        @Assert(disabledCandidate, 0)
        @Assert(withdrew, true)
        @Assert(restored, true)
        @Assert(fresh, 0)
        @Assert(turn.isOpen, true)
        @Assert(controller.dispatchTrace(), "reject;reject;accept;")
        @Assert(controller.packetCount(), 1)
        @Assert(controller.accumulatedY(), 0.25)
        @Assert(controller.rejectedCount(), 2)
        @Assert(controller.appliedAction(), "SCROLL_A")
    } finally { window.close() }
}

@Test
func composableQueuedWheelPendingAcceptedFreezesUntilPumpAndKeepsBirth(): Unit {
    let controller = QueuedWheelBindingController()
    let window = queuedWheelWindow(controller)
    try {
        @Assert(window.start(), true)
        window.testSetSceneWriteTrace(true)
        let session = window.testSessionToken()
        let acceptedP = window.acceptedWheelSceneVersionForTest()
        let birth = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)
        let old = queuedWheelEnqueue(session, -1.0, 1u32)
        let held = window.testHoldNextComposablePresent()
        controller.changePaint()
        let pending = !window.refreshIfNeeded()
        let pendingStatus = window.nativeStatus()
        let pWhilePending = window.acceptedWheelSceneVersionForTest()
        let birthWhilePending = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)
        let frozenTurn = window.pumpEventsWithoutRefresh(0u32)
        let pAfterFrozenTurn = window.acceptedWheelSceneVersionForTest()
        let birthAfterFrozenTurn = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)
        let packetsWhilePending = controller.packetCount()
        let resolved = window.testResolvePendingComposablePresent()
        let pAfterNativeResolve = window.acceptedWheelSceneVersionForTest()
        let birthAfterNativeResolve = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)
        let fresh = queuedWheelEnqueue(session, 0.25, 4u32)
        let turn = window.pumpEventsWithoutRefresh(0u32)
        let pAfterPump = window.acceptedWheelSceneVersionForTest()
        let birthAfterPump = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)
        let duplicateSettlement = window.testResolvePendingComposablePresent()
        let noPendingSettlement = window.settlePendingPresent()
        let pAfterObservation = window.acceptedWheelSceneVersionForTest()
        let birthAfterObservation = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)
        println("CJGUI_QUEUED_WHEEL_PENDING_ACCEPT old=${old} held=${held} pending=${pending}/${pendingStatus} " +
            "freeze=${frozenTurn.isOpen}/${packetsWhilePending} fresh=${fresh} resolved=${resolved} " +
            "P=${acceptedP}/${pWhilePending}/${pAfterFrozenTurn}/${pAfterNativeResolve}->${pAfterPump}->${pAfterObservation} " +
            "birth=${birth}/${birthWhilePending}/${birthAfterFrozenTurn}/${birthAfterNativeResolve}->${birthAfterPump}->${birthAfterObservation} " +
            "pump=${turn.isOpen} duplicate=${duplicateSettlement}/${noPendingSettlement} packets=${controller.packetCount()} " +
            "reject=${controller.rejectedCount()}")
        @Assert(old, 0)
        @Assert(held, true)
        @Assert(pending, true)
        @Assert(pendingStatus, CJGUI_INTERNAL_RENDERER_PRESENT_PENDING)
        @Assert(pWhilePending, acceptedP)
        @Assert(birthWhilePending, birth)
        @Assert(frozenTurn.isOpen, true)
        @Assert(packetsWhilePending, 0)
        @Assert(pAfterFrozenTurn, acceptedP)
        @Assert(birthAfterFrozenTurn, birth)
        @Assert(resolved, true)
        @Assert(pAfterNativeResolve, acceptedP)
        @Assert(birthAfterNativeResolve, birth)
        @Assert(fresh, 0)
        @Assert(turn.isOpen, true)
        @Assert(pAfterPump > acceptedP, true)
        @Assert(birthAfterPump, birth)
        @Assert(duplicateSettlement, false)
        @Assert(noPendingSettlement, false)
        @Assert(pAfterObservation, pAfterPump)
        @Assert(birthAfterObservation, birth)
        @Assert(controller.packetCount(), 2)
        @Assert(controller.accumulatedY(), -0.75)
        @Assert(controller.rejectedCount(), 0)
    } finally { window.close() }
}

@Test
func composableQueuedWheelPendingRejectedRetainsOldBirthAndTicket(): Unit {
    let controller = QueuedWheelBindingController()
    let window = queuedWheelWindow(controller)
    try {
        @Assert(window.start(), true)
        window.testSetSceneWriteTrace(true)
        let session = window.testSessionToken()
        let acceptedP = window.acceptedWheelSceneVersionForTest()
        let birth = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)
        let old = queuedWheelEnqueue(session, -1.0, 1u32)
        let held = window.testHoldNextComposablePresent()
        controller.changePaint()
        let pending = !window.refreshIfNeeded()
        let armFailure = unsafe {
            cjgui_internal_renderer_test_set_composable_present_failures(session, 1u32)
        }
        let resolved = window.testResolvePendingComposablePresent()
        let settled = window.settlePendingPresent()
        let noPendingSettlement = window.settlePendingPresent()
        let retainedP = window.acceptedWheelSceneVersionForTest()
        let retainedBirth = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)
        let turn = window.pumpEventsWithoutRefresh(0u32)
        println("CJGUI_QUEUED_WHEEL_PENDING_REJECT old=${old} held=${held} pending=${pending} " +
            "arm=${armFailure} resolve=${resolved} settled=${settled}/${noPendingSettlement} P=${acceptedP}->${retainedP} " +
            "birth=${birth}->${retainedBirth} pump=${turn.isOpen} packets=${controller.packetCount()} " +
            "reject=${controller.rejectedCount()}")
        @Assert(old, 0)
        @Assert(held, true)
        @Assert(pending, true)
        @Assert(armFailure, CJGUI_INTERNAL_RENDERER_OK)
        @Assert(resolved, false)
        @Assert(settled, true)
        @Assert(noPendingSettlement, false)
        @Assert(retainedP, acceptedP)
        @Assert(retainedBirth, birth)
        @Assert(turn.isOpen, true)
        @Assert(controller.packetCount(), 1)
        @Assert(controller.accumulatedY(), -1.0)
        @Assert(controller.rejectedCount(), 0)
    } finally { window.close() }
}

@Test
func composableQueuedWheelPendingAcceptedFreezesOwnerAndPublishesSavedBinding(): Unit {
    let controller = QueuedWheelBindingController()
    let window = queuedWheelWindow(controller)
    try {
        @Assert(window.start(), true)
        window.testSetSceneWriteTrace(true)
        let session = window.testSessionToken()
        let acceptedA = window.acceptedWheelSceneVersionForTest()
        let birthA = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)
        let oldA = queuedWheelEnqueue(session, -1.0, 1u32)

        let held = window.testHoldNextComposablePresent()
        controller.rebind(82, "SCROLL_B")
        let pendingB = !window.refreshIfNeeded()
        let statusPendingB = window.nativeStatus()
        let (versionWhileBPending, birthWhileBPending, resourceWhileBPending) =
            (window.acceptedWheelSceneVersionForTest(),
                window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID),
                queuedWheelAcceptedResource(window))

        // The live owner moves on to C while the renderer still owns the
        // frozen B ticket. A pump must leave both FIFO events and accepted A
        // untouched until B receives its explicit native decision.
        controller.rebind(93, "SCROLL_C")
        let frozenTurn = window.pumpEventsWithoutRefresh(0u32)
        let packetsWhilePending = controller.packetCount()
        let versionAfterFrozenTurn = window.acceptedWheelSceneVersionForTest()
        let birthAfterFrozenTurn = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)
        let resolveAcceptedB = window.testResolvePendingComposablePresent()
        let versionAfterNativeB = window.acceptedWheelSceneVersionForTest()
        let birthAfterNativeB = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)
        let freshB = queuedWheelEnqueue(session, 0.25, 4u32)
        let turn = window.pumpEventsWithoutRefresh(0u32)
        let acceptedB = window.acceptedWheelSceneVersionForTest()
        let birthB = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)
        let acceptedResourceB = queuedWheelAcceptedResource(window)
        let duplicateSettlement = window.testResolvePendingComposablePresent()
        let noPendingSettlement = window.settlePendingPresent()
        let versionAfterDuplicate = window.acceptedWheelSceneVersionForTest()
        let birthAfterDuplicate = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)

        // C is the current live controller value but cannot replace the saved
        // pending B transaction during its settlement. Only the next ordinary
        // refresh may accept C and mint the next binding birth.
        let acceptedC = window.refresh()
        let versionC = window.acceptedWheelSceneVersionForTest()
        let birthC = window.acceptedWheelBindingBirthForTest(QUEUED_WHEEL_NODE_ID)
        let acceptedResourceC = queuedWheelAcceptedResource(window)
        println("CJGUI_QUEUED_WHEEL_PENDING_OWNER A=${acceptedA}/${birthA} pending=${held}/${pendingB}/${statusPendingB} " +
            "frozen=${frozenTurn.isOpen}/${packetsWhilePending}/${versionAfterFrozenTurn}/${birthAfterFrozenTurn} " +
            "resolve=${resolveAcceptedB} native=${versionAfterNativeB}/${birthAfterNativeB} FIFO=${oldA}/${freshB}/" +
            "${turn.isOpen}/${controller.dispatchTrace()}/${controller.appliedResource()}/${controller.accumulatedY()} " +
            "B=${acceptedB}/${birthB}/${acceptedResourceB} duplicate=${duplicateSettlement}/${noPendingSettlement}/" +
            "${versionAfterDuplicate}/${birthAfterDuplicate} C=${acceptedC}/${versionC}/${birthC}/${acceptedResourceC}")

        @Assert(oldA, 0)
        @Assert(held, true)
        @Assert(pendingB, true)
        @Assert(statusPendingB, CJGUI_INTERNAL_RENDERER_PRESENT_PENDING)
        @Assert(versionWhileBPending, acceptedA)
        @Assert(birthWhileBPending, birthA)
        @Assert(resourceWhileBPending, 41)
        @Assert(frozenTurn.isOpen, true)
        @Assert(packetsWhilePending, 0)
        @Assert(versionAfterFrozenTurn, acceptedA)
        @Assert(birthAfterFrozenTurn, birthA)
        @Assert(resolveAcceptedB, true)
        @Assert(versionAfterNativeB, acceptedA)
        @Assert(birthAfterNativeB, birthA)
        @Assert(freshB, 0)
        @Assert(turn.isOpen, true)
        @Assert(controller.dispatchTrace(), "reject;accept;")
        @Assert(controller.appliedResource(), 82)
        @Assert(controller.accumulatedY(), 0.25)
        @Assert(controller.rejectedCount(), 1)
        @Assert(acceptedB > acceptedA, true)
        @Assert(birthB, acceptedB)
        @Assert(acceptedResourceB, 82)
        @Assert(duplicateSettlement, false)
        @Assert(noPendingSettlement, false)
        @Assert(versionAfterDuplicate, acceptedB)
        @Assert(birthAfterDuplicate, birthB)
        @Assert(acceptedC, true)
        @Assert(versionC > acceptedB, true)
        @Assert(birthC, versionC)
        @Assert(acceptedResourceC, 93)
    } finally { window.close() }
}

@Test
func composableQueuedWheelRejectsForgedVersionsIdentityAndPayload(): Unit {
    let controller = QueuedWheelBindingController()
    let window = queuedWheelWindow(controller)
    try {
        @Assert(window.start(), true)
        window.testSetSceneWriteTrace(true)
        let session = window.testSessionToken()
        let p = UInt64(window.acceptedWheelSceneVersionForTest())
        // The accepted resource is the declaration's 41; appliedResource is
        // intentionally unset until delivery, so keep this private fixture
        // scalar explicit and visible in the diagnostic.
        let nodeKind = UInt32(CJGUI_COMPOSABLE_UI_HORIZONTAL)
        let zero = queuedWheelEnqueueForged(session, 0u64, 41, nodeKind,
            "cjgui-wheel-v1|0|-1|1|4|0")
        let future = queuedWheelEnqueueForged(session, p + 1u64, 41, nodeKind,
            "cjgui-wheel-v1|0|-1|1|4|0")
        let resourceMismatch = queuedWheelEnqueueForged(session, p, 999, nodeKind,
            "cjgui-wheel-v1|0|-1|1|4|0")
        let kindMismatch = queuedWheelEnqueueForged(session, p, 41,
            UInt32(CJGUI_COMPOSABLE_UI_BUTTON), "cjgui-wheel-v1|0|-1|1|4|0")
        let malformed = queuedWheelEnqueueForged(session, p, 41, nodeKind,
            "cjgui-wheel-v1|0|nan|1|4|0")
        let turn = window.pump(0u32)
        println("CJGUI_QUEUED_WHEEL_FORGED P=${p} resource=41 kind=${nodeKind} " +
            "enqueue=${zero},${future},${resourceMismatch},${kindMismatch},${malformed} " +
            "pump=${turn.isOpen} packets=${controller.packetCount()} rejected=${controller.rejectedCount()} " +
            "deltaY=${controller.accumulatedY()}")
        @Assert(zero, 0)
        @Assert(future, 0)
        @Assert(resourceMismatch, 0)
        @Assert(kindMismatch, 0)
        @Assert(malformed, 0)
        @Assert(turn.isOpen, true)
        @Assert(controller.packetCount(), 0)
        @Assert(controller.accumulatedY(), 0.0)
        @Assert(controller.rejectedCount(), 5)
    } finally { window.close() }
}
