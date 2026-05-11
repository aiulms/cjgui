// 维护注释：本文件是 drawable availability / still-blocked internal owner。
// Truth: 只消费 CjguiInternalRendererNoDrawableAcquisitionPlanningReadiness，
// 调用既有 fail-closed C ABI，观察 drawable acquisition 与 command queue 仍 blocked。
// Stop-line: 不调用 nextDrawable，不 present，不创建 command queue / command buffer /
// encoder，不提交 GPU work，不写 runtime_state.cj。
// Same-shape Boundary Brake: availability facts 不得包装成 drawable-ready、
// backend-ready、render-ready、GPU submission、state write、receipt、record 或 publication。
package cjgui

struct CjguiInternalRendererDrawableAvailabilityObservation {
    let drawableStillBlockedValue: Int32
    let commandQueueStillBlockedValue: Int32
    let didObserveDrawableAcquisitionStillBlocked: Bool
    let didObservePresentStillForbidden: Bool
    let didObserveCommandQueueBufferStillBlocked: Bool
    let didObserveNoNextDrawableCall: Bool
    let didObserveNoGpuSubmissionOrRender: Bool
    let didKeepAvailabilityFactsDehydrated: Bool

    init(
        drawableStillBlockedValue: Int32,
        commandQueueStillBlockedValue: Int32,
        didObserveDrawableAcquisitionStillBlocked: Bool,
        didObservePresentStillForbidden: Bool,
        didObserveCommandQueueBufferStillBlocked: Bool,
        didObserveNoNextDrawableCall: Bool,
        didObserveNoGpuSubmissionOrRender: Bool,
        didKeepAvailabilityFactsDehydrated: Bool
    ) {
        this.drawableStillBlockedValue = drawableStillBlockedValue
        this.commandQueueStillBlockedValue = commandQueueStillBlockedValue
        this.didObserveDrawableAcquisitionStillBlocked =
            didObserveDrawableAcquisitionStillBlocked
        this.didObservePresentStillForbidden = didObservePresentStillForbidden
        this.didObserveCommandQueueBufferStillBlocked =
            didObserveCommandQueueBufferStillBlocked
        this.didObserveNoNextDrawableCall = didObserveNoNextDrawableCall
        this.didObserveNoGpuSubmissionOrRender =
            didObserveNoGpuSubmissionOrRender
        this.didKeepAvailabilityFactsDehydrated =
            didKeepAvailabilityFactsDehydrated
    }
}

struct CjguiInternalRendererNoDrawableAvailabilityReadiness {
    let planningReadiness:
        CjguiInternalRendererNoDrawableAcquisitionPlanningReadiness
    let availabilityObservation:
        CjguiInternalRendererDrawableAvailabilityObservation
    let didPrepareRendererNoDrawableAvailabilityReadiness: Bool
    let shouldDeferRendererNoDrawableAvailabilityReadiness: Bool
    let shouldReportRendererDrawableAvailabilityBlocked: Bool
    let didPreserveRendererDrawableAcquisitionPlanningReadiness: Bool
    let didConfirmDrawableAcquisitionStillBlocked: Bool
    let didConfirmPresentStillForbidden: Bool
    let didConfirmCommandQueueBufferStillBlocked: Bool
    let didConfirmNoNextDrawableCall: Bool
    let didConfirmNoCommandBufferEncoderOrRender: Bool
    let didConfirmNoGpuSubmission: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepDrawableAvailabilityReadinessDehydrated: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        planningReadiness:
            CjguiInternalRendererNoDrawableAcquisitionPlanningReadiness,
        availabilityObservation:
            CjguiInternalRendererDrawableAvailabilityObservation,
        didPrepareRendererNoDrawableAvailabilityReadiness: Bool,
        shouldDeferRendererNoDrawableAvailabilityReadiness: Bool,
        shouldReportRendererDrawableAvailabilityBlocked: Bool,
        didPreserveRendererDrawableAcquisitionPlanningReadiness: Bool,
        didConfirmDrawableAcquisitionStillBlocked: Bool,
        didConfirmPresentStillForbidden: Bool,
        didConfirmCommandQueueBufferStillBlocked: Bool,
        didConfirmNoNextDrawableCall: Bool,
        didConfirmNoCommandBufferEncoderOrRender: Bool,
        didConfirmNoGpuSubmission: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepDrawableAvailabilityReadinessDehydrated: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.planningReadiness = planningReadiness
        this.availabilityObservation = availabilityObservation
        this.didPrepareRendererNoDrawableAvailabilityReadiness =
            didPrepareRendererNoDrawableAvailabilityReadiness
        this.shouldDeferRendererNoDrawableAvailabilityReadiness =
            shouldDeferRendererNoDrawableAvailabilityReadiness
        this.shouldReportRendererDrawableAvailabilityBlocked =
            shouldReportRendererDrawableAvailabilityBlocked
        this.didPreserveRendererDrawableAcquisitionPlanningReadiness =
            didPreserveRendererDrawableAcquisitionPlanningReadiness
        this.didConfirmDrawableAcquisitionStillBlocked =
            didConfirmDrawableAcquisitionStillBlocked
        this.didConfirmPresentStillForbidden = didConfirmPresentStillForbidden
        this.didConfirmCommandQueueBufferStillBlocked =
            didConfirmCommandQueueBufferStillBlocked
        this.didConfirmNoNextDrawableCall = didConfirmNoNextDrawableCall
        this.didConfirmNoCommandBufferEncoderOrRender =
            didConfirmNoCommandBufferEncoderOrRender
        this.didConfirmNoGpuSubmission = didConfirmNoGpuSubmission
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepDrawableAvailabilityReadinessDehydrated =
            didKeepDrawableAvailabilityReadinessDehydrated
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererDrawableAvailabilityValues():
    CjguiInternalRendererDrawableAvailabilityObservation {
    let drawableBlocked = unsafe {
        cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked()
    }
    let commandQueueBlocked = unsafe {
        cjgui_native_bridge_metal_device_command_queue_still_blocked()
    }
    return CjguiInternalRendererDrawableAvailabilityObservation(
        drawableBlocked,
        commandQueueBlocked,
        drawableBlocked < Int32(0),
        true,
        commandQueueBlocked < Int32(0),
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererDrawableAvailabilityReadiness(
    planningReadiness:
        CjguiInternalRendererNoDrawableAcquisitionPlanningReadiness,
    availabilityObservation:
        CjguiInternalRendererDrawableAvailabilityObservation
): CjguiInternalRendererNoDrawableAvailabilityReadiness {
    let planningReady =
        planningReadiness
            .didPrepareRendererNoDrawableAcquisitionPlanningReadiness &&
        planningReadiness.didConfirmTokenBackedLayerDevicePrerequisite &&
        planningReadiness.didConfirmMainThreadGatePrerequisite &&
        planningReadiness.didConfirmNextDrawableStillOutsideThisOwner &&
        planningReadiness.didConfirmNoPresentCommandBufferQueueOrRender &&
        planningReadiness.didConfirmNoRendererStateWrite &&
        planningReadiness.didConfirmNoBackendReadyTruth
    let availabilityReady =
        planningReady &&
        availabilityObservation.didObserveDrawableAcquisitionStillBlocked &&
        availabilityObservation.didObservePresentStillForbidden &&
        availabilityObservation.didObserveCommandQueueBufferStillBlocked &&
        availabilityObservation.didObserveNoNextDrawableCall &&
        availabilityObservation.didObserveNoGpuSubmissionOrRender &&
        availabilityObservation.didKeepAvailabilityFactsDehydrated

    if (availabilityReady) {
        return CjguiInternalRendererNoDrawableAvailabilityReadiness(
            planningReadiness,
            availabilityObservation,
            true,
            false,
            false,
            true,
            true,
            true,
            true,
            true,
            true,
            true,
            true,
            true,
            true,
            true,
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererNoDrawableAvailabilityReadiness(
        planningReadiness,
        availabilityObservation,
        false,
        true,
        false,
        planningReady,
        availabilityObservation.didObserveDrawableAcquisitionStillBlocked,
        availabilityObservation.didObservePresentStillForbidden,
        availabilityObservation.didObserveCommandQueueBufferStillBlocked,
        availabilityObservation.didObserveNoNextDrawableCall,
        availabilityObservation.didObserveCommandQueueBufferStillBlocked,
        availabilityObservation.didObserveNoGpuSubmissionOrRender,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererDrawableAvailabilityDraft():
    CjguiInternalRendererNoDrawableAvailabilityReadiness {
    let planningReadiness =
        cjguiInternalExecuteDefaultRendererDrawableAcquisitionPlanningDraft()
    let availabilityObservation =
        cjguiInternalObserveRendererDrawableAvailabilityValues()
    return cjguiInternalBuildRendererDrawableAvailabilityReadiness(
        planningReadiness,
        availabilityObservation
    )
}
