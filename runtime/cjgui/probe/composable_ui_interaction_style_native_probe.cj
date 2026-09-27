package cjgui

foreign {
    func cjgui_internal_renderer_test_enqueue_composable_event(
        session: UInt64, nodeIndex: UInt32, eventKind: UInt32, text: CString
    ): Int32
    func cjgui_internal_renderer_test_send_composable_mouse(
        session: UInt64, phase: UInt32, pointX: Float32, pointY: Float32
    ): Int32
    func cjgui_internal_renderer_test_cancel_composable_platform_interaction(session: UInt64): Int32
    func cjgui_internal_renderer_test_set_composable_present_failures(session: UInt64, failureCount: UInt32): Int32
    func cjgui_internal_renderer_test_composable_scene_update_stats(
        session: UInt64, outCommittedNodeCount: CPointer<UInt32>, outNodeUpdateCount: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_request_composable_drawable_pixel(
        session: UInt64, pointX: UInt32, pointY: UInt32
    ): Int32
    func cjgui_internal_renderer_test_composable_drawable_pixel(
        session: UInt64, outBlue: CPointer<UInt8>, outGreen: CPointer<UInt8>,
        outRed: CPointer<UInt8>, outAlpha: CPointer<UInt8>
    ): Int32
    func cjgui_internal_renderer_test_composable_interaction_trace(
        session: UInt64, outPendingInteractionCount: CPointer<UInt32>, outLastEnqueuedKind: CPointer<UInt32>,
        outLastEnqueuedNodeId: CPointer<UInt64>, outLastEnqueuedProjectionVersion: CPointer<UInt64>,
        outLastPumpedKind: CPointer<UInt32>, outLastPumpedNodeId: CPointer<UInt64>,
        outLastPumpedProjectionVersion: CPointer<UInt64>
    ): Int32
}

private class InteractionStyleProbeController <: CjguiComposableUiController {
    private var stableActionCount: Int64
    private var reboundActionCountValue: Int64
    private var actionRevision: Int64

    init() {
        this.stableActionCount = 0
        this.reboundActionCountValue = 0
        this.actionRevision = 1
    }

    public func uiSceneVersion(): Int64 { return actionRevision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(8801, "interaction-probe-root",
            CjguiComposableUiStyle(fixedWidth: 160, fixedHeight: 80))
        root.add(cjguiComposableButton(8802, "interaction-probe-button", "Action",
            if (actionRevision == 1) { "ACT" } else { "REBOUND" }, 5,
            CjguiComposableUiStyle(fixedWidth: 160, fixedHeight: 80,
                background: CjguiComposableUiColor(0.10, 0.12, 0.16, 1.0)),
            interactionStyle: CjguiComposableUiInteractionStyle(
                hover: CjguiComposableUiPaintStyle(background: Some(CjguiComposableUiColor(0.76, 0.20, 0.16, 1.0))),
                pressed: CjguiComposableUiPaintStyle(background: Some(CjguiComposableUiColor(0.26, 0.70, 0.20, 1.0))),
                focused: CjguiComposableUiPaintStyle(border: Some(CjguiComposableUiColor(0.92, 0.88, 0.12, 1.0)),
                    borderWidth: Some(3)))))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.actionName == "ACT") {
            stableActionCount += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "REBOUND") {
            reboundActionCountValue += 1
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
    public func stableCount(): Int64 { return stableActionCount }
    public func reboundCount(): Int64 { return reboundActionCountValue }
    public func rebindActionDuringPress(): Unit { actionRevision = 2 }
}

/// Keeps one ordinary pressable action in a real layer host while its owner
/// changes around an in-flight mouse lifecycle.  The mutable values model the
/// result of an external owner write; the probe drives the normal native
/// down/up path, never a controller-only activation shortcut.
private class PressBoundaryProbeController <: CjguiComposableUiController {
    private var targetState: Int64
    private var modalVisible: Bool
    private var unrelatedRevision: Int64
    private var revision: Int64
    private var stableActionCountValue: Int64
    private var reboundActionCountValue: Int64

    init() {
        this.targetState = 0
        this.modalVisible = false
        this.unrelatedRevision = 0
        this.revision = 1
        this.stableActionCountValue = 0
        this.reboundActionCountValue = 0
    }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let host = cjguiComposableLayerHost(9900, "press-boundary-host", CjguiComposableUiStyle())
        let base = cjguiComposableVertical(9901, "press-boundary-base",
            CjguiComposableUiStyle(fixedWidth: 160, fixedHeight: 160))
        if (targetState == 3) {
            base.add(cjguiComposableText(9903, "press-boundary-placeholder", "target removed",
                CjguiComposableUiStyle(fixedWidth: 160, fixedHeight: 80)))
        } else {
            base.add(cjguiComposableButton(9902,
                if (targetState == 4) { "press-boundary-a-recreated" } else { "press-boundary-a" },
                "A", if (targetState == 5) { "REBOUND_ACTION" } else { "STABLE_ACTION" }, 51,
                CjguiComposableUiStyle(fixedWidth: 160, fixedHeight: 80,
                    background: CjguiComposableUiColor(0.10, 0.12, 0.16, 1.0)),
                enabled: targetState != 1,
                operationActionName: if (targetState == 2) { "WRITE_A_REBOUND" } else { "WRITE_A" },
                operationResourceId: if (targetState == 2) { 92 } else { 91 },
                interactionStyle: CjguiComposableUiInteractionStyle(
                    hover: CjguiComposableUiPaintStyle(background: Some(CjguiComposableUiColor(0.76, 0.20, 0.16, 1.0))),
                    pressed: CjguiComposableUiPaintStyle(background: Some(CjguiComposableUiColor(0.26, 0.70, 0.20, 1.0))))))
        }
        base.add(cjguiComposableButton(9904, "press-boundary-b", "B ${unrelatedRevision}", "UNRELATED", 52,
            CjguiComposableUiStyle(fixedWidth: 160, fixedHeight: 80,
                background: CjguiComposableUiColor(0.18, 0.18, 0.22, 1.0)),
            interactionStyle: CjguiComposableUiInteractionStyle(
                hover: CjguiComposableUiPaintStyle(background: Some(CjguiComposableUiColor(0.22, 0.44, 0.76, 1.0))))))
        host.add(base)
        if (modalVisible) {
            let dialog = cjguiComposableDialogLayer(9910, "press-boundary-dialog", "press-boundary-modal",
                "press-boundary-base", 9902,
                CjguiComposableUiStyle(fixedWidth: 120, fixedHeight: 64, padding: 8), initialFocusNodeId: 9911)
            dialog.add(cjguiComposableButton(9911, "press-boundary-dialog-close", "close", "CLOSE_MODAL", 53,
                CjguiComposableUiStyle(fixedHeight: 32)))
            host.add(dialog)
        }
        return host
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.actionName == "STABLE_ACTION") {
            stableActionCountValue += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "REBOUND_ACTION") {
            reboundActionCountValue += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "CLOSE_MODAL") {
            modalVisible = false
            revision += 1
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
    public func stableActionCount(): Int64 { return stableActionCountValue }
    public func reboundActionCount(): Int64 { return reboundActionCountValue }
    public func disableTarget(): Unit { targetState = 1; revision += 1 }
    public func removeTarget(): Unit { targetState = 3; revision += 1 }
    public func recreateTarget(): Unit { targetState = 4; revision += 1 }
    public func rebindOperation(): Unit { targetState = 2; revision += 1 }
    public func rebindAction(): Unit { targetState = 5; revision += 1 }
    public func restoreTarget(): Unit { targetState = 0; revision += 1 }
    public func changeUnrelatedB(): Unit { unrelatedRevision += 1; revision += 1 }
    public func openModal(): Unit { modalVisible = true; revision += 1 }
    public func closeModalExternally(): Unit { modalVisible = false; revision += 1 }
}

private class InteractionStyleProbePixel {
    let status: Int32
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8

    init(status: Int32, red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        this.status = status
        this.red = red
        this.green = green
        this.blue = blue
        this.alpha = alpha
    }
}

private func pixel(session: UInt64): InteractionStyleProbePixel {
    var blue: UInt8 = 0u8
    var green: UInt8 = 0u8
    var red: UInt8 = 0u8
    var alpha: UInt8 = 0u8
    let status = unsafe { cjgui_internal_renderer_test_composable_drawable_pixel(session, inout blue, inout green,
        inout red, inout alpha) }
    return InteractionStyleProbePixel(status, red, green, blue, alpha)
}

private func interactionTrace(session: UInt64): String {
    var pending: UInt32 = 0u32
    var enqueuedKind: UInt32 = 0u32
    var enqueuedNodeId: UInt64 = 0u64
    var enqueuedVersion: UInt64 = 0u64
    var pumpedKind: UInt32 = 0u32
    var pumpedNodeId: UInt64 = 0u64
    var pumpedVersion: UInt64 = 0u64
    let status = unsafe { cjgui_internal_renderer_test_composable_interaction_trace(
        session, inout pending, inout enqueuedKind, inout enqueuedNodeId, inout enqueuedVersion,
        inout pumpedKind, inout pumpedNodeId, inout pumpedVersion) }
    return "status=${status} pending=${pending} enqueued=${enqueuedKind}/${enqueuedNodeId}/${enqueuedVersion} pumped=${pumpedKind}/${pumpedNodeId}/${pumpedVersion}"
}

private class InteractionStyleNativeCounters {
    let status: Int32
    let updates: UInt64

    init(status: Int32, updates: UInt64) {
        this.status = status
        this.updates = updates
    }
}

private func nativeCounters(session: UInt64): InteractionStyleNativeCounters {
    var committed: UInt32 = 0u32
    var updates: UInt64 = 0u64
    let status = unsafe {
        cjgui_internal_renderer_test_composable_scene_update_stats(session, inout committed, inout updates)
    }
    return InteractionStyleNativeCounters(status, updates)
}

private func verifyPressBoundaryLifecycle(): Bool {
    let controller = PressBoundaryProbeController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        println("CJGUI_INTERACTION_STYLE_PRESS_BOUNDARY start=false")
        return false
    }
    // This probe judges the native input and replacement boundary at each
    // event. Make its immediate paint oracle explicit; animated color timing
    // is covered by the dedicated interaction transition tests.
    let _ = window.setReduceMotionEnabled(true)
    let session = window.testSessionToken()
    let emptyText = unsafe { LibC.mallocCString("") }
    // An identical enter is a true no-op: accepted hover paint remains live,
    // and the second duplicate must not rebuild, lay out, submit or restage a
    // node merely because native repeated the same routing intent.
    let clearHover = unsafe { cjgui_internal_renderer_test_enqueue_composable_event(session, 2u32, 44u32, emptyText) }
    let clearHoverTurn = window.pump(0u32)
    let enterA = unsafe { cjgui_internal_renderer_test_enqueue_composable_event(session, 2u32, 43u32, emptyText) }
    let enterATurn = window.pump(0u32)
    let repeatBefore = window.windowProjection()
    let repeatNativeBefore = nativeCounters(session)
    let repeatedEnterA = unsafe { cjgui_internal_renderer_test_enqueue_composable_event(session, 2u32, 43u32, emptyText) }
    let repeatedEnterTurn = window.pump(0u32)
    let repeatAfter = window.windowProjection()
    let repeatNativeAfter = nativeCounters(session)
    let repeatedStateNoWork = clearHover == 0 && clearHoverTurn.isOpen && enterA == 0 && enterATurn.isOpen &&
        repeatedEnterA == 0 && repeatedEnterTurn.isOpen && !repeatedEnterTurn.didApplyHumanAction &&
        repeatNativeBefore.status == 0 && repeatNativeAfter.status == 0 &&
        repeatAfter.buildPassCount == repeatBefore.buildPassCount &&
        repeatAfter.layoutPassCount == repeatBefore.layoutPassCount &&
        repeatAfter.nativeSubmissionCount == repeatBefore.nativeSubmissionCount &&
        repeatNativeAfter.updates == repeatNativeBefore.updates
    // Establish the ordinary one-click action before testing invalidation.
    let initialDown = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 20.0f32) }
    let initialDownTurn = window.pump(0u32)
    let initialUp = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 20.0f32) }
    let initialUpTurn = window.pump(0u32)
    let initialAction = initialDown == 0 && initialDownTurn.isOpen && initialUp == 0 &&
        initialUpTurn.didApplyHumanAction && controller.stableActionCount() == 1 && controller.reboundActionCount() == 0

    // An external rebinding of the same raw node and action to another owner
    // target must cancel the old release rather than writing that replacement.
    let operationDown = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 20.0f32) }
    let operationDownTurn = window.pump(0u32)
    controller.rebindOperation()
    let operationRefresh = window.refresh()
    let operationUp = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 20.0f32) }
    let operationUpTurn = window.pump(0u32)
    let operationRebindCancelled = operationDown == 0 && operationDownTurn.isOpen && operationRefresh && operationUp == 0 &&
        operationUpTurn.isOpen && controller.stableActionCount() == 1 && controller.reboundActionCount() == 0
    controller.restoreTarget()
    let operationRestore = window.refresh()

    let actionDown = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 20.0f32) }
    let actionDownTurn = window.pump(0u32)
    controller.rebindAction()
    let actionRefresh = window.refresh()
    let actionUp = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 20.0f32) }
    let actionUpTurn = window.pump(0u32)
    let actionRebindCancelled = actionDown == 0 && actionDownTurn.isOpen && actionRefresh && actionUp == 0 &&
        actionUpTurn.isOpen && controller.stableActionCount() == 1 && controller.reboundActionCount() == 0
    controller.restoreTarget()
    let actionRestore = window.refresh()

    // The rebind and terminal release can be separated by an unrelated
    // interaction-only paint.  That paint must not erase the provenance that
    // rejects A's old activation, nor may it cancel a still-valid A press.
    let interleavedDown = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 20.0f32) }
    let interleavedDownTurn = window.pump(0u32)
    controller.rebindAction()
    let interleavedRefresh = window.refresh()
    let interleavedBHover = unsafe { cjgui_internal_renderer_test_enqueue_composable_event(session, 3u32, 43u32, emptyText) }
    let interleavedBHoverTurn = window.pump(0u32)
    let interleavedUp = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 20.0f32) }
    let interleavedUpTurn = window.pump(0u32)
    let interleavedRebindCancelled = interleavedDown == 0 && interleavedDownTurn.isOpen && interleavedRefresh &&
        interleavedBHover == 0 && interleavedBHoverTurn.isOpen && interleavedUp == 0 && interleavedUpTurn.isOpen &&
        controller.stableActionCount() == 1 && controller.reboundActionCount() == 0
    controller.restoreTarget()
    let interleavedRestore = window.refresh()

    let disabledDown = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 20.0f32) }
    let disabledDownTurn = window.pump(0u32)
    controller.disableTarget()
    let disabledRefresh = window.refresh()
    let disabledUp = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 20.0f32) }
    let disabledUpTurn = window.pump(0u32)
    let disabledCancelled = disabledDown == 0 && disabledDownTurn.isOpen && disabledRefresh && disabledUp == 0 &&
        disabledUpTurn.isOpen && controller.stableActionCount() == 1 && controller.reboundActionCount() == 0
    controller.restoreTarget()
    let disabledRestore = window.refresh()

    let removedDown = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 20.0f32) }
    let removedDownTurn = window.pump(0u32)
    controller.removeTarget()
    let removalRefresh = window.refresh()
    controller.recreateTarget()
    let recreationRefresh = window.refresh()
    let removedUp = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 20.0f32) }
    let removedUpTurn = window.pump(0u32)
    let deleteRecreateCancelled = removedDown == 0 && removedDownTurn.isOpen && removalRefresh && recreationRefresh &&
        removedUp == 0 && removedUpTurn.isOpen && controller.stableActionCount() == 1 && controller.reboundActionCount() == 0
    controller.restoreTarget()
    let recreationRestore = window.refresh()

    // A change to B and a COW-only B hover leave the still-valid A press
    // alive. Neither is authority to cancel a different owner/action.
    let unrelatedDown = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 20.0f32) }
    let unrelatedDownTurn = window.pump(0u32)
    controller.changeUnrelatedB()
    let unrelatedRefresh = window.refresh()
    let unrelatedUp = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 20.0f32) }
    let unrelatedUpTurn = window.pump(0u32)
    let unrelatedPreservedA = unrelatedDown == 0 && unrelatedDownTurn.isOpen && unrelatedRefresh && unrelatedUp == 0 &&
        unrelatedUpTurn.didApplyHumanAction && controller.stableActionCount() == 2 && controller.reboundActionCount() == 0

    let paintDown = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 20.0f32) }
    let paintDownTurn = window.pump(0u32)
    let paintBHover = unsafe { cjgui_internal_renderer_test_enqueue_composable_event(session, 3u32, 43u32, emptyText) }
    let paintBHoverTurn = window.pump(0u32)
    let paintUp = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 20.0f32) }
    let paintUpTurn = window.pump(0u32)
    let purePaintPreservedA = paintDown == 0 && paintDownTurn.isOpen && paintBHover == 0 && paintBHoverTurn.isOpen &&
        paintUp == 0 && paintUpTurn.didApplyHumanAction && controller.stableActionCount() == 3 && controller.reboundActionCount() == 0

    let modalDown = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 20.0f32) }
    let modalDownTurn = window.pump(0u32)
    controller.openModal()
    let modalRefresh = window.refresh()
    let modalUp = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 20.0f32) }
    let modalUpTurn = window.pump(0u32)
    let modalCancelled = modalDown == 0 && modalDownTurn.isOpen && modalRefresh && modalUp == 0 && modalUpTurn.isOpen &&
        controller.stableActionCount() == 3 && controller.reboundActionCount() == 0
    controller.closeModalExternally()
    let modalRestore = window.refresh()

    let blurDown = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 20.0f32) }
    let blurDownTurn = window.pump(0u32)
    let blurCancel = unsafe { cjgui_internal_renderer_test_cancel_composable_platform_interaction(session) }
    let blurCancelTurn = window.pump(0u32)
    let blurUp = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 20.0f32) }
    let blurUpTurn = window.pump(0u32)
    let platformBlurCancelled = blurDown == 0 && blurDownTurn.isOpen && blurCancel == 0 && blurCancelTurn.isOpen &&
        blurUp == 0 && blurUpTurn.isOpen && controller.stableActionCount() == 3 && controller.reboundActionCount() == 0

    // A failed interaction-only candidate never advances the accepted scene
    // or replaces its action routing; a later normal refresh retries from the
    // retained scene and the original physical release still reaches STABLE.
    let failureBefore = window.displayedSceneVersion()
    let forceFailure = unsafe { cjgui_internal_renderer_test_set_composable_present_failures(session, 1u32) }
    let failureDown = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 20.0f32) }
    let failureTurn = window.pump(0u32)
    let failedCandidateRetained = forceFailure == 0 && failureDown == 0 && failureTurn.isOpen &&
        window.displayedSceneVersion() == failureBefore && window.nativeStatus() != 0
    let healthyRetry = window.refresh()
    let failureUp = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 20.0f32) }
    let failureUpTurn = window.pump(0u32)
    let failedCandidateRecovered = healthyRetry && failureUp == 0 && failureUpTurn.didApplyHumanAction &&
        controller.stableActionCount() == 4 && controller.reboundActionCount() == 0

    let valid = repeatedStateNoWork && initialAction && operationRebindCancelled && operationRestore &&
        actionRebindCancelled && actionRestore && interleavedRebindCancelled && interleavedRestore && disabledCancelled && disabledRestore && deleteRecreateCancelled &&
        recreationRestore && unrelatedPreservedA && purePaintPreservedA && modalCancelled && modalRestore &&
        platformBlurCancelled && failedCandidateRetained && failedCandidateRecovered
    println("CJGUI_INTERACTION_STYLE_PRESS_BOUNDARY repeated_no_work=${repeatedStateNoWork} operation_rebind_cancelled=${operationRebindCancelled} action_rebind_cancelled=${actionRebindCancelled} interleaved_rebind_cancelled=${interleavedRebindCancelled} disabled_cancelled=${disabledCancelled} delete_recreate_cancelled=${deleteRecreateCancelled} unrelated_preserved_a=${unrelatedPreservedA} pure_paint_preserved_a=${purePaintPreservedA} modal_cancelled=${modalCancelled} platform_blur_cancelled=${platformBlurCancelled} failed_candidate_retained=${failedCandidateRetained} failed_candidate_recovered=${failedCandidateRecovered} valid=${valid}")
    unsafe { LibC.free(emptyText) }
    window.close()
    return valid
}

main(): Int64 {
    let controller = InteractionStyleProbeController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) { return 2 }
    let _ = window.setReduceMotionEnabled(true)
    let session = window.testSessionToken()
    let emptyText = unsafe { LibC.mallocCString("") }
    let initial = window.windowProjection()
    let initialVersion = window.displayedSceneVersion()
    let captureHover = unsafe { cjgui_internal_renderer_test_request_composable_drawable_pixel(session, 20u32, 20u32) }
    let hoverEvent = unsafe { cjgui_internal_renderer_test_enqueue_composable_event(session, 1u32, 43u32, emptyText) }
    let hoverTurn = window.pump(0u32)
    let hoverPixel = pixel(session)
    let afterHover = window.windowProjection()
    let afterHoverVersion = window.displayedSceneVersion()
    let hoverTrace = interactionTrace(session)
    let capturePress = unsafe { cjgui_internal_renderer_test_request_composable_drawable_pixel(session, 20u32, 20u32) }
    let pressEvent = unsafe { cjgui_internal_renderer_test_enqueue_composable_event(session, 1u32, 45u32, emptyText) }
    let pressTurn = window.pump(0u32)
    let pressPixel = pixel(session)
    let afterPress = window.windowProjection()
    let afterPressVersion = window.displayedSceneVersion()
    let pressTrace = interactionTrace(session)
    let cancelEvent = unsafe { cjgui_internal_renderer_test_enqueue_composable_event(session, 1u32, 47u32, emptyText) }
    let cancelTurn = window.pump(0u32)
    let afterCancel = window.windowProjection()
    let afterCancelVersion = window.displayedSceneVersion()
    let cancelTrace = interactionTrace(session)
    let physicalDown = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 20.0f32) }
    let physicalDownTurn = window.pump(0u32)
    let physicalMoveOut = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 2u32, 300.0f32, 20.0f32) }
    let physicalMoveOutTurn = window.pump(0u32)
    let physicalReleaseOutside = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 300.0f32, 20.0f32) }
    let physicalReleaseOutsideTurn = window.pump(0u32)
    let noActionAfterCancelledPress = controller.stableCount() == 0 && controller.reboundCount() == 0
    let physicalActivateDown = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 20.0f32) }
    let physicalActivateDownTurn = window.pump(0u32)
    let physicalActivateUp = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 20.0f32) }
    let physicalActivateTurn = window.pump(0u32)
    let actionOnce = controller.stableCount() == 1 && controller.reboundCount() == 0
    // A released physical press belongs to the declaration seen at mouse-down.
    // Rebinding the same raw node/resource/kind before mouse-up must cancel it,
    // never retarget the newly declared action.
    let actionRebindDown = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 20.0f32) }
    let actionRebindDownTurn = window.pump(0u32)
    controller.rebindActionDuringPress()
    let actionRebindRefresh = window.refresh()
    let actionRebindUp = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 20.0f32) }
    let actionRebindUpTurn = window.pump(0u32)
    let actionRebindCancelled = controller.stableCount() == 1 && controller.reboundCount() == 0
    let stableBuild = initial.buildPassCount == afterHover.buildPassCount && afterHover.buildPassCount == afterPress.buildPassCount &&
        afterPress.buildPassCount == afterCancel.buildPassCount
    let stableLayout = initial.layoutPassCount == afterHover.layoutPassCount && afterHover.layoutPassCount == afterPress.layoutPassCount &&
        afterPress.layoutPassCount == afterCancel.layoutPassCount
    let changedSubmission = initial.nativeSubmissionCount < afterHover.nativeSubmissionCount &&
        afterHover.nativeSubmissionCount < afterPress.nativeSubmissionCount && afterPress.nativeSubmissionCount < afterCancel.nativeSubmissionCount
    let hoverPaint = hoverPixel.status == 0 && hoverPixel.red > 120u8 && hoverPixel.green < 100u8
    let pressPaint = pressPixel.status == 0 && pressPixel.green > 120u8 && pressPixel.red < 100u8
    let styleValid = captureHover == 0 && hoverEvent == 0 && hoverTurn.isOpen && capturePress == 0 && pressEvent == 0 &&
        pressTurn.isOpen && cancelEvent == 0 && cancelTurn.isOpen && stableBuild && stableLayout && changedSubmission &&
        hoverPaint && pressPaint && physicalDown == 0 && physicalDownTurn.isOpen && physicalMoveOut == 0 &&
        physicalMoveOutTurn.isOpen && physicalReleaseOutside == 0 && physicalReleaseOutsideTurn.isOpen &&
        noActionAfterCancelledPress && physicalActivateDown == 0 && physicalActivateDownTurn.isOpen &&
        physicalActivateUp == 0 && physicalActivateTurn.didApplyHumanAction && actionOnce && actionRebindDown == 0 &&
        actionRebindDownTurn.isOpen && actionRebindRefresh && actionRebindUp == 0 && actionRebindUpTurn.isOpen &&
        actionRebindCancelled
    let pressBoundaryValid = verifyPressBoundaryLifecycle()
    let valid = styleValid && pressBoundaryValid
    println("CJGUI_INTERACTION_STYLE_NATIVE_PROBE hover_paint=${hoverPaint} press_paint=${pressPaint} build_stable=${stableBuild} layout_stable=${stableLayout} local_submit=${changedSubmission} physical_cancel_no_action=${noActionAfterCancelledPress} physical_release_once=${actionOnce} action_rebind_cancelled=${actionRebindCancelled} press_boundary=${pressBoundaryValid} valid=${valid} versions=${initialVersion}/${afterHoverVersion}/${afterPressVersion}/${afterCancelVersion} submissions=${initial.nativeSubmissionCount}/${afterHover.nativeSubmissionCount}/${afterPress.nativeSubmissionCount}/${afterCancel.nativeSubmissionCount} hover_rgba=${hoverPixel.status}:${hoverPixel.red},${hoverPixel.green},${hoverPixel.blue},${hoverPixel.alpha} press_rgba=${pressPixel.status}:${pressPixel.red},${pressPixel.green},${pressPixel.blue},${pressPixel.alpha} trace_hover=${hoverTrace} trace_press=${pressTrace} trace_cancel=${cancelTrace}")
    unsafe { LibC.free(emptyText) }
    window.close()
    return if (valid) { 0 } else { 3 }
}
