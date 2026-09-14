package cjgui

import std.time.*

/// Probe-only native seam.  The production path receives the same normalized
/// point events from AppKit; this symbol is compiled only with
/// CJGUI_INTERNAL_TESTING and never becomes a public Cangjie API.
foreign {
    func cjgui_internal_renderer_test_send_composable_pointer(
        session: UInt64, phase: UInt32, pointX: Float32, pointY: Float32
    ): Int32
    func cjgui_internal_renderer_test_composable_interaction_stats(
        session: UInt64, outPendingInteractionCount: CPointer<UInt32>, outMaxPendingInteractionCount: CPointer<UInt32>,
        outAccessibilityNotificationCount: CPointer<UInt64>
    ): Int32
    /// Direct responder seam retained only as a control for the AppKit route
    /// test below. Production callers never use this symbol.
    func cjgui_internal_renderer_test_send_composable_key(
        session: UInt64, keyCode: UInt16, modifiers: UInt64, outFocusedNodeId: CPointer<UInt64>
    ): Int32
    /// Posts through the session's real NSApplication/NSWindow responder
    /// route. routeFlags distinguish application/key-window/first-responder
    /// readiness from receipt by the composable overlay.
    func cjgui_internal_renderer_test_dispatch_composable_key_through_application(
        session: UInt64, keyCode: UInt16, modifiers: UInt64,
        outFocusedNodeId: CPointer<UInt64>, outRouteFlags: CPointer<UInt32>
    ): Int32
}

private class PointerCaptureProbeController <: CjguiComposableUiController & CjguiComposableUiPointerCaptureVersionProvider {
    private var revision: Int64
    private var pointerRevision: Int64
    private var began: Bool
    private var updateCount: Int64
    private var ended: Bool
    private var cancelled: Bool
    private var externalWriteCount: Int64
    private var targetVisible: Bool
    private var modalVisible: Bool
    private var lastX: Int64
    private var lastY: Int64
    private var keyboardAdjustmentCount: Int64

    init() {
        this.revision = 1
        this.pointerRevision = 1
        this.began = false
        this.updateCount = 0
        this.ended = false
        this.cancelled = false
        this.externalWriteCount = 0
        this.targetVisible = true
        this.modalVisible = false
        this.lastX = -1
        this.lastY = -1
        this.keyboardAdjustmentCount = 0
    }

    public func uiSceneVersion(): Int64 { return revision }

    public func pointerCaptureVersion(node: CjguiComposableUiLayoutNode): Int64 {
        if (node.nodeId == 9101 && node.resourceId == 9101) {
            return pointerRevision
        }
        return revision
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableLayerHost(9100, "pointer-capture-root", CjguiComposableUiStyle())
        let base = cjguiComposableVertical(9102, "pointer-capture-base", CjguiComposableUiStyle())
        // Kind 13 is the public split-divider pointer target introduced by
        // this stage.  It has a fixed visual hit box; point 480,240 used by
        // the test is deliberately outside it.
        if (targetVisible) {
            base.add(CjguiComposableUiNode(
                9101, "pointer-capture-divider", 13, "", "", "POINTER_CAPTURE", 9101,
                CjguiComposableUiStyle(fixedWidth: 220, fixedHeight: 24)
            ))
        }
        // Keep the controller's accepted pointer value in the actual
        // projection. This makes the load probe verify its ordinary
        // dispatch-to-rebuild path rather than treating an invisible local
        // counter as a rendered state change.
        base.add(cjguiComposableText(9105, "pointer-capture-readback",
            "pointer=${lastX},${lastY}", CjguiComposableUiStyle()))
        root.add(base)
        if (modalVisible) {
            let dialog = cjguiComposableDialogLayer(9103, "pointer-capture-dialog", "pointer-capture-modal",
                "pointer-capture-root", 9100, CjguiComposableUiStyle(fixedWidth: 160, fixedHeight: 64))
            dialog.add(cjguiComposableText(9104, "pointer-capture-dialog-text", "pointer capture cancelled",
                CjguiComposableUiStyle()))
            root.add(dialog)
        }
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.node.nodeId != 9101) {
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.eventKind == 35 && (event.text == "left" || event.text == "right" || event.text == "up" ||
            event.text == "down")) {
            keyboardAdjustmentCount += 1
            revision += 1
            pointerRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 37) {
            began = true
            lastX = event.pointerX
            lastY = event.pointerY
            revision += 1
            pointerRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 38) {
            updateCount += 1
            lastX = event.pointerX
            lastY = event.pointerY
            revision += 1
            pointerRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 39) {
            ended = true
            lastX = event.pointerX
            lastY = event.pointerY
            revision += 1
            pointerRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 40) {
            cancelled = true
            lastX = event.pointerX
            lastY = event.pointerY
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

    public func didBegin(): Bool { return began }
    public func updateEvents(): Int64 { return updateCount }
    public func didEnd(): Bool { return ended }
    public func didCancel(): Bool { return cancelled }
    /// Models a separately accepted public operation routed through this
    /// controller: it owns the same scene revision but is not a pointer phase.
    public func applyExternalSameOwnerWrite(): Unit {
        externalWriteCount += 1
        revision += 1
        pointerRevision += 1
    }
    /// A second owner projection changed, but it did not change the captured
    /// divider's value or authorization. Its whole-scene revision advances;
    /// the divider-specific revision intentionally remains stable.
    public func applyExternalUnrelatedOwnerWrite(): Unit {
        externalWriteCount += 1
        revision += 1
    }
    public func externalWrites(): Int64 { return externalWriteCount }
    public func removeCapturedTarget(): Unit {
        targetVisible = false
        revision += 1
    }
    public func openModal(): Unit {
        modalVisible = true
        revision += 1
    }
    public func pointerX(): Int64 { return lastX }
    public func pointerY(): Int64 { return lastY }
    public func keyboardAdjustments(): Int64 { return keyboardAdjustmentCount }
}

/// Clicking/dragging a pointer control must make that same control the native
/// focus target. Compare the old direct responder seam with NSApplication's
/// own dispatch so a no-op desktop automation key is never misattributed to
/// the composable owner without checking the responder chain.
private func verifyPointerControlFocusEnablesKeyboardAdjustment(): Bool {
    let controller = PointerCaptureProbeController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        return false
    }
    let session = window.testSessionToken()
    let began = unsafe {
        cjgui_internal_renderer_test_send_composable_pointer(session, 1u32, 10.0f32, 10.0f32)
    }
    let beginTurn = window.pump(0u32)
    var directFocusedNodeId: UInt64 = 0u64
    let directKeyStatus = unsafe {
        // macOS virtual-keycode 124 is Right Arrow.
        cjgui_internal_renderer_test_send_composable_key(session, 124u16, 0u64, inout directFocusedNodeId)
    }
    let directKeyTurn = window.pump(0u32)
    let directOwnerAdjustments = controller.keyboardAdjustments()
    var applicationFocusedNodeId: UInt64 = 0u64
    var applicationRouteFlags: UInt32 = 0u32
    let applicationKeyStatus = unsafe {
        cjgui_internal_renderer_test_dispatch_composable_key_through_application(
            session, 124u16, 0u64, inout applicationFocusedNodeId, inout applicationRouteFlags
        )
    }
    let applicationKeyTurn = window.pump(0u32)
    let applicationOwnerAdjustments = controller.keyboardAdjustments()
    let passed = began == CJGUI_INTERNAL_RENDERER_OK && beginTurn.didApplyHumanAction &&
        directKeyStatus == CJGUI_INTERNAL_RENDERER_OK && directFocusedNodeId == 9101u64 && directKeyTurn.didApplyHumanAction &&
        applicationKeyStatus == CJGUI_INTERNAL_RENDERER_OK && applicationFocusedNodeId == 9101u64 &&
        applicationRouteFlags == 31u32 && applicationKeyTurn.didApplyHumanAction &&
        directOwnerAdjustments == 1 && applicationOwnerAdjustments == 2
    println("CJGUI_POINTER_CAPTURE_KEY_ROUTE direct_status=${directKeyStatus} direct_node=${directFocusedNodeId} direct_owner_adjustments=${directOwnerAdjustments} application_status=${applicationKeyStatus} application_node=${applicationFocusedNodeId} application_route_flags=${applicationRouteFlags} application_owner_adjustments=${applicationOwnerAdjustments} passed=${passed}")
    window.close()
    return passed
}

private func verifyPointerCaptureKeepsTargetOutsideOriginalBounds(): Bool {
    let controller = PointerCaptureProbeController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        return false
    }
    let session = window.testSessionToken()
    let began = unsafe {
        cjgui_internal_renderer_test_send_composable_pointer(session, 1u32, 10.0f32, 10.0f32)
    }
    let beginTurn = window.pump(0u32)
    // This point lies outside the 220×24 divider.  It must remain routed to
    // the captured divider rather than hit-testing whatever is underneath.
    let moved = unsafe {
        cjgui_internal_renderer_test_send_composable_pointer(session, 2u32, 480.0f32, 240.0f32)
    }
    let moveTurn = window.pump(0u32)
    let ended = unsafe {
        cjgui_internal_renderer_test_send_composable_pointer(session, 3u32, 480.0f32, 240.0f32)
    }
    let endTurn = window.pump(0u32)
    let passed = began == CJGUI_INTERNAL_RENDERER_OK && moved == CJGUI_INTERNAL_RENDERER_OK &&
        ended == CJGUI_INTERNAL_RENDERER_OK && beginTurn.didApplyHumanAction && moveTurn.didApplyHumanAction &&
        endTurn.didApplyHumanAction && controller.didBegin() && controller.updateEvents() == 1 && controller.didEnd() &&
        controller.pointerX() == 480 && controller.pointerY() == 240
    window.close()
    return passed
}

private func verifyExternalOwnerWriteCancelsStalePointerContinuation(): Bool {
    let controller = PointerCaptureProbeController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        return false
    }
    let session = window.testSessionToken()
    let began = unsafe {
        cjgui_internal_renderer_test_send_composable_pointer(session, 1u32, 10.0f32, 10.0f32)
    }
    let beginTurn = window.pump(0u32)
    controller.applyExternalSameOwnerWrite()
    let refreshed = window.refresh()
    // The accepted external owner write revokes both halves of the capture:
    // no subsequent platform move may enter the FIFO, and the owner saw its
    // cancel while reconciling the new projection.
    let moved = unsafe {
        cjgui_internal_renderer_test_send_composable_pointer(session, 2u32, 140.0f32, 10.0f32)
    }
    let passed = began == CJGUI_INTERNAL_RENDERER_OK && beginTurn.didApplyHumanAction && refreshed &&
        moved != CJGUI_INTERNAL_RENDERER_OK && controller.didBegin() &&
        controller.didCancel() && !controller.didEnd() && controller.updateEvents() == 0 &&
        controller.externalWrites() == 1 && controller.pointerX() == 10 && controller.pointerY() == 10
    window.close()
    return passed
}

private func verifyExternalUnrelatedOwnerWritePreservesPointerCapture(): Bool {
    let controller = PointerCaptureProbeController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        return false
    }
    let session = window.testSessionToken()
    let began = unsafe {
        cjgui_internal_renderer_test_send_composable_pointer(session, 1u32, 10.0f32, 10.0f32)
    }
    let beginTurn = window.pump(0u32)
    controller.applyExternalUnrelatedOwnerWrite()
    let refreshed = window.refresh()
    // The unrelated owner update rebuilt the scene, but did not supersede the
    // divider's target-scoped truth. Native capture must remain live across
    // that refresh and deliver its subsequent terminal lifecycle normally.
    let moved = unsafe {
        cjgui_internal_renderer_test_send_composable_pointer(session, 2u32, 140.0f32, 10.0f32)
    }
    let moveTurn = window.pump(0u32)
    let ended = unsafe {
        cjgui_internal_renderer_test_send_composable_pointer(session, 3u32, 140.0f32, 10.0f32)
    }
    let endTurn = window.pump(0u32)
    let passed = began == CJGUI_INTERNAL_RENDERER_OK && beginTurn.didApplyHumanAction && refreshed &&
        moved == CJGUI_INTERNAL_RENDERER_OK && moveTurn.didApplyHumanAction &&
        ended == CJGUI_INTERNAL_RENDERER_OK && endTurn.didApplyHumanAction &&
        controller.didBegin() && !controller.didCancel() && controller.updateEvents() == 1 &&
        controller.didEnd() && controller.externalWrites() == 1 && controller.pointerX() == 140 && controller.pointerY() == 10
    window.close()
    return passed
}

private func verifyTargetDeletionCancelsPlatformAndOwnerCapture(): Bool {
    let controller = PointerCaptureProbeController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        return false
    }
    let session = window.testSessionToken()
    let began = unsafe {
        cjgui_internal_renderer_test_send_composable_pointer(session, 1u32, 10.0f32, 10.0f32)
    }
    let beginTurn = window.pump(0u32)
    controller.removeCapturedTarget()
    let refreshed = window.refresh()
    // A replacement projection removed the captured target. Native routing
    // must be gone too, so a later move cannot even enqueue a stale phase.
    let moved = unsafe {
        cjgui_internal_renderer_test_send_composable_pointer(session, 2u32, 140.0f32, 10.0f32)
    }
    let passed = began == CJGUI_INTERNAL_RENDERER_OK && beginTurn.didApplyHumanAction && refreshed &&
        controller.didCancel() && !controller.didEnd() && controller.updateEvents() == 0 &&
        moved != CJGUI_INTERNAL_RENDERER_OK
    window.close()
    return passed
}

private func verifyModalTransitionCancelsCapturedPointer(): Bool {
    let controller = PointerCaptureProbeController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        return false
    }
    let session = window.testSessionToken()
    let began = unsafe {
        cjgui_internal_renderer_test_send_composable_pointer(session, 1u32, 10.0f32, 10.0f32)
    }
    let beginTurn = window.pump(0u32)
    controller.openModal()
    let refreshed = window.refresh()
    // The modal input scope supersedes the underlying control, so native
    // capture is revoked alongside the owner capability.
    let moved = unsafe {
        cjgui_internal_renderer_test_send_composable_pointer(session, 2u32, 140.0f32, 10.0f32)
    }
    let passed = began == CJGUI_INTERNAL_RENDERER_OK && beginTurn.didApplyHumanAction && refreshed &&
        controller.didCancel() && !controller.didEnd() && controller.updateEvents() == 0 &&
        moved != CJGUI_INTERNAL_RENDERER_OK
    window.close()
    return passed
}

/// Controlled native-process workload evidence, kept deliberately separate
/// from normal-bundle public socket calls. Each sample creates two ordinary
/// AppKit/Metal windows: A receives one complete captured drag and B remains
/// idle. The timestamp covers enqueue plus Cangjie dispatch/projection for A;
/// it is neither a physical-presentation measurement nor human-input latency.
private func verifyPointerCaptureLoadCondition(condition: String, burst: Bool): Bool {
    let samples: Int64 = 30
    let inputUpdates: Int64 = if (burst) { 32 } else { 8 }
    var totalElapsedMs: Int64 = 0
    var minimumElapsedMs: Int64 = -1
    var maximumElapsedMs: Int64 = 0
    var totalProcessedUpdates: Int64 = 0
    var totalCoalescedUpdates: Int64 = 0
    var maximumQueueHighWater: UInt32 = 0u32
    var sample: Int64 = 0
    while (sample < samples) {
        let controller = PointerCaptureProbeController()
        let window = CjguiComposableUiWindow(controller)
        let unrelatedController = PointerCaptureProbeController()
        let unrelatedWindow = CjguiComposableUiWindow(unrelatedController)
        if (!window.start() || !unrelatedWindow.start()) {
            unrelatedWindow.close()
            window.close()
            return false
        }
        let primaryBefore = window.windowProjection()
        let unrelatedBefore = unrelatedWindow.windowProjection()
        let session = window.testSessionToken()
        let started = MonoTime.now()
        var accepted = unsafe {
            cjgui_internal_renderer_test_send_composable_pointer(session, 1u32, 10.0f32, 10.0f32)
        } == CJGUI_INTERNAL_RENDERER_OK
        // The native historical high-water counter is an older test seam.
        // Observe the live bounded FIFO before its first drain instead: this
        // is the value that can actually affect a following turn.
        var observedQueueHighWater: UInt32 = 0u32
        var observedPending: UInt32 = 0u32
        var ignoredHistoricalHighWater: UInt32 = 0u32
        var ignoredAccessibilityNotifications: UInt64 = 0u64
        let initialStats = unsafe {
            cjgui_internal_renderer_test_composable_interaction_stats(
                session, inout observedPending, inout ignoredHistoricalHighWater,
                inout ignoredAccessibilityNotifications)
        }
        accepted = accepted && initialStats == CJGUI_INTERNAL_RENDERER_OK
        if (observedPending > observedQueueHighWater) {
            observedQueueHighWater = observedPending
        }
        var didApply = false
        if (burst) {
            var update: Int64 = 0
            while (update < inputUpdates) {
                accepted = accepted && unsafe {
                    cjgui_internal_renderer_test_send_composable_pointer(session, 2u32, 140.0f32, 10.0f32)
                } == CJGUI_INTERNAL_RENDERER_OK
                update += 1
            }
            accepted = accepted && unsafe {
                cjgui_internal_renderer_test_send_composable_pointer(session, 3u32, 140.0f32, 10.0f32)
            } == CJGUI_INTERNAL_RENDERER_OK
            observedPending = 0u32
            let burstStats = unsafe {
                cjgui_internal_renderer_test_composable_interaction_stats(
                    session, inout observedPending, inout ignoredHistoricalHighWater,
                    inout ignoredAccessibilityNotifications)
            }
            accepted = accepted && burstStats == CJGUI_INTERNAL_RENDERER_OK
            if (observedPending > observedQueueHighWater) {
                observedQueueHighWater = observedPending
            }
            didApply = window.pump(0u32).didApplyHumanAction
        } else {
            didApply = window.pump(0u32).didApplyHumanAction
            var update: Int64 = 0
            while (update < inputUpdates) {
                let updateAccepted = unsafe {
                    cjgui_internal_renderer_test_send_composable_pointer(session, 2u32, 140.0f32, 10.0f32)
                }
                let updateTurn = window.pump(0u32)
                accepted = accepted && updateAccepted == CJGUI_INTERNAL_RENDERER_OK
                didApply = didApply && updateTurn.didApplyHumanAction
                update += 1
            }
            let endAccepted = unsafe {
                cjgui_internal_renderer_test_send_composable_pointer(session, 3u32, 140.0f32, 10.0f32)
            }
            let endTurn = window.pump(0u32)
            accepted = accepted && endAccepted == CJGUI_INTERNAL_RENDERER_OK
            didApply = didApply && endTurn.didApplyHumanAction
        }
        // Dispatch consumes the native FIFO in this turn; rebuild/present is
        // deliberately scheduled as the following ordinary turn.
        let refreshTurn = window.pump(0u32)
        accepted = accepted && refreshTurn.isOpen
        let elapsedMs = (MonoTime.now() - started).toMilliseconds()
        var pendingInteractions: UInt32 = 0u32
        var queueHighWater: UInt32 = 0u32
        var accessibilityNotifications: UInt64 = 0u64
        let statsStatus = unsafe {
            cjgui_internal_renderer_test_composable_interaction_stats(
                session, inout pendingInteractions, inout queueHighWater, inout accessibilityNotifications)
        }
        if (observedQueueHighWater > queueHighWater) {
            queueHighWater = observedQueueHighWater
        }
        let primaryAfter = window.windowProjection()
        let unrelatedAfter = unrelatedWindow.windowProjection()
        let processedUpdates = controller.updateEvents()
        let expectedProcessedUpdates = if (burst) { 1 } else { inputUpdates }
        let coalescedUpdates = inputUpdates - processedUpdates
        // Pointer activation now carries one ordinary focus intent before the
        // begin/update/end lifecycle: low-frequency turns retain focus+begin,
        // while a burst retains focus+begin+coalesced-update+end.
        let expectedQueueHighWater: UInt32 = if (burst) { 4u32 } else { 2u32 }
        let unrelatedUnchanged = unrelatedAfter.sceneVersion == unrelatedBefore.sceneVersion &&
            unrelatedAfter.buildPassCount == unrelatedBefore.buildPassCount &&
            unrelatedAfter.layoutPassCount == unrelatedBefore.layoutPassCount &&
            unrelatedAfter.nativeSubmissionCount == unrelatedBefore.nativeSubmissionCount
        let passed = accepted && didApply && statsStatus == CJGUI_INTERNAL_RENDERER_OK && pendingInteractions == 0u32 &&
            queueHighWater == expectedQueueHighWater && controller.didBegin() && controller.didEnd() &&
            !controller.didCancel() && processedUpdates == expectedProcessedUpdates &&
            coalescedUpdates == inputUpdates - expectedProcessedUpdates && controller.pointerX() == 140 &&
            controller.pointerY() == 10 && primaryAfter.sceneVersion > primaryBefore.sceneVersion &&
            primaryAfter.lastNativeFailure == "none" && unrelatedUnchanged
        if (!passed) {
            println("CJGUI_POINTER_CAPTURE_LOAD_FAILURE condition=${condition} sample=${sample + 1} accepted=${accepted} applied=${didApply} stats=${statsStatus} pending=${pendingInteractions} high_water=${queueHighWater} began=${controller.didBegin()} ended=${controller.didEnd()} cancelled=${controller.didCancel()} processed=${processedUpdates} expected=${expectedProcessedUpdates} coalesced=${coalescedUpdates} last_pointer=${controller.pointerX()},${controller.pointerY()} primary_scene=${primaryBefore.sceneVersion},${primaryAfter.sceneVersion} native_failure=${primaryAfter.lastNativeFailure} unrelated_unchanged=${unrelatedUnchanged}")
        }
        unrelatedWindow.close()
        window.close()
        if (!passed) {
            return false
        }
        println("CJGUI_POINTER_CAPTURE_SAMPLE condition=${condition} sample=${sample + 1} elapsed_ms=${elapsedMs} input_updates=${inputUpdates} processed_updates=${processedUpdates} coalesced_updates=${coalescedUpdates} queue_pending=${pendingInteractions} queue_high_water=${queueHighWater} owner_end=${controller.didEnd()} primary_scene_before=${primaryBefore.sceneVersion} primary_scene_after=${primaryAfter.sceneVersion} unrelated_scene_delta=${unrelatedAfter.sceneVersion - unrelatedBefore.sceneVersion} unrelated_submit_delta=${unrelatedAfter.nativeSubmissionCount - unrelatedBefore.nativeSubmissionCount}")
        totalElapsedMs += elapsedMs
        if (minimumElapsedMs < 0 || elapsedMs < minimumElapsedMs) { minimumElapsedMs = elapsedMs }
        if (elapsedMs > maximumElapsedMs) { maximumElapsedMs = elapsedMs }
        totalProcessedUpdates += processedUpdates
        totalCoalescedUpdates += coalescedUpdates
        if (queueHighWater > maximumQueueHighWater) { maximumQueueHighWater = queueHighWater }
        sample += 1
    }
    println("CJGUI_POINTER_CAPTURE_LOAD condition=${condition} samples=${samples} input_updates=${inputUpdates * samples} processed_updates=${totalProcessedUpdates} coalesced_updates=${totalCoalescedUpdates} queue_high_water_max=${maximumQueueHighWater} elapsed_ms_min=${minimumElapsedMs} elapsed_ms_avg=${totalElapsedMs / samples} elapsed_ms_max=${maximumElapsedMs} unrelated_window_work=unchanged")
    return true
}

main(): Int64 {
    if (!verifyPointerControlFocusEnablesKeyboardAdjustment()) {
        println("pointer capture probe: failed pointer_control_focus_enables_keyboard_adjustment")
        return 1
    }
    if (!verifyPointerCaptureKeepsTargetOutsideOriginalBounds()) {
        println("pointer capture probe: failed capture_moves_outside_original_bounds")
        return 1
    }
    if (!verifyExternalOwnerWriteCancelsStalePointerContinuation()) {
        println("pointer capture probe: failed external_owner_write_cancels_stale_continuation")
        return 1
    }
    if (!verifyExternalUnrelatedOwnerWritePreservesPointerCapture()) {
        println("pointer capture probe: failed external_unrelated_owner_write_preserves_capture")
        return 1
    }
    if (!verifyTargetDeletionCancelsPlatformAndOwnerCapture()) {
        println("pointer capture probe: failed target_deletion_cancels_platform_and_owner_capture")
        return 1
    }
    if (!verifyModalTransitionCancelsCapturedPointer()) {
        println("pointer capture probe: failed modal_transition_cancels_captured_pointer")
        return 1
    }
    if (!verifyPointerCaptureLoadCondition("low_frequency", false)) {
        println("pointer capture probe: failed low_frequency_continuous_load")
        return 1
    }
    if (!verifyPointerCaptureLoadCondition("burst", true)) {
        println("pointer capture probe: failed burst_continuous_load")
        return 1
    }
    println("pointer capture probe: pointer_control_focus_and_application_key_dispatch=passed capture_moves_outside_original_bounds=passed external_owner_write_cancels_stale_continuation=passed external_unrelated_owner_write_preserves_capture=passed target_deletion_cancels_platform_and_owner_capture=passed modal_transition_cancels_captured_pointer=passed")
    return 0
}
