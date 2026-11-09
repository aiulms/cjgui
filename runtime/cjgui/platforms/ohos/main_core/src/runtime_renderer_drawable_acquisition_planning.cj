// 维护注释：本文件是 drawable acquisition runway 的 planning internal owner。
// Truth: 只消费 CjguiInternalRendererNoMetalDeviceLayerBindingReadiness，
// 表达 drawable acquisition 仍处于 no-acquire planning / recovery gate。
// Stop-line: 不调用 nextDrawable，不获取 drawable，不创建 command queue /
// command buffer / encoder，不提交 GPU work，不写 runtime_state.cj。
// Same-shape Boundary Brake: planning facts 不得包装成 drawable-ready、
// backend-ready、render-ready、GPU submission、state write、receipt、record 或 publication。
package cjgui

struct CjguiInternalRendererDrawableAcquisitionPlanningObservation {
    let didAcceptMetalDeviceLayerBindingEvidence: Bool
    let didRequireTokenBackedLayerDeviceBinding: Bool
    let didRequireMainThreadDrawableGate: Bool
    let didRequireNoPresentPath: Bool
    let didRequireCommandQueueBufferBeforeRender: Bool
    let didKeepNextDrawableOutsideThisOwner: Bool
    let didKeepPlanningFactsDehydrated: Bool

    init(
        didAcceptMetalDeviceLayerBindingEvidence: Bool,
        didRequireTokenBackedLayerDeviceBinding: Bool,
        didRequireMainThreadDrawableGate: Bool,
        didRequireNoPresentPath: Bool,
        didRequireCommandQueueBufferBeforeRender: Bool,
        didKeepNextDrawableOutsideThisOwner: Bool,
        didKeepPlanningFactsDehydrated: Bool
    ) {
        this.didAcceptMetalDeviceLayerBindingEvidence =
            didAcceptMetalDeviceLayerBindingEvidence
        this.didRequireTokenBackedLayerDeviceBinding =
            didRequireTokenBackedLayerDeviceBinding
        this.didRequireMainThreadDrawableGate =
            didRequireMainThreadDrawableGate
        this.didRequireNoPresentPath = didRequireNoPresentPath
        this.didRequireCommandQueueBufferBeforeRender =
            didRequireCommandQueueBufferBeforeRender
        this.didKeepNextDrawableOutsideThisOwner =
            didKeepNextDrawableOutsideThisOwner
        this.didKeepPlanningFactsDehydrated = didKeepPlanningFactsDehydrated
    }
}

struct CjguiInternalRendererNoDrawableAcquisitionPlanningReadiness {
    let metalDeviceLayerBindingReadiness:
        CjguiInternalRendererNoMetalDeviceLayerBindingReadiness
    let planningObservation:
        CjguiInternalRendererDrawableAcquisitionPlanningObservation
    let didPrepareRendererNoDrawableAcquisitionPlanningReadiness: Bool
    let shouldDeferRendererNoDrawableAcquisitionPlanningReadiness: Bool
    let shouldReportRendererDrawableAcquisitionPlanningBlocked: Bool
    let didPreserveRendererMetalDeviceLayerBindingReadiness: Bool
    let didConfirmTokenBackedLayerDevicePrerequisite: Bool
    let didConfirmMainThreadGatePrerequisite: Bool
    let didConfirmNextDrawableStillOutsideThisOwner: Bool
    let didConfirmNoPresentCommandBufferQueueOrRender: Bool
    let didConfirmNoGpuSubmission: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepDrawableAcquisitionPlanningReadinessDehydrated: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        metalDeviceLayerBindingReadiness:
            CjguiInternalRendererNoMetalDeviceLayerBindingReadiness,
        planningObservation:
            CjguiInternalRendererDrawableAcquisitionPlanningObservation,
        didPrepareRendererNoDrawableAcquisitionPlanningReadiness: Bool,
        shouldDeferRendererNoDrawableAcquisitionPlanningReadiness: Bool,
        shouldReportRendererDrawableAcquisitionPlanningBlocked: Bool,
        didPreserveRendererMetalDeviceLayerBindingReadiness: Bool,
        didConfirmTokenBackedLayerDevicePrerequisite: Bool,
        didConfirmMainThreadGatePrerequisite: Bool,
        didConfirmNextDrawableStillOutsideThisOwner: Bool,
        didConfirmNoPresentCommandBufferQueueOrRender: Bool,
        didConfirmNoGpuSubmission: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepDrawableAcquisitionPlanningReadinessDehydrated: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.metalDeviceLayerBindingReadiness =
            metalDeviceLayerBindingReadiness
        this.planningObservation = planningObservation
        this.didPrepareRendererNoDrawableAcquisitionPlanningReadiness =
            didPrepareRendererNoDrawableAcquisitionPlanningReadiness
        this.shouldDeferRendererNoDrawableAcquisitionPlanningReadiness =
            shouldDeferRendererNoDrawableAcquisitionPlanningReadiness
        this.shouldReportRendererDrawableAcquisitionPlanningBlocked =
            shouldReportRendererDrawableAcquisitionPlanningBlocked
        this.didPreserveRendererMetalDeviceLayerBindingReadiness =
            didPreserveRendererMetalDeviceLayerBindingReadiness
        this.didConfirmTokenBackedLayerDevicePrerequisite =
            didConfirmTokenBackedLayerDevicePrerequisite
        this.didConfirmMainThreadGatePrerequisite =
            didConfirmMainThreadGatePrerequisite
        this.didConfirmNextDrawableStillOutsideThisOwner =
            didConfirmNextDrawableStillOutsideThisOwner
        this.didConfirmNoPresentCommandBufferQueueOrRender =
            didConfirmNoPresentCommandBufferQueueOrRender
        this.didConfirmNoGpuSubmission = didConfirmNoGpuSubmission
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepDrawableAcquisitionPlanningReadinessDehydrated =
            didKeepDrawableAcquisitionPlanningReadinessDehydrated
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererDrawableAcquisitionPlanningValues():
    CjguiInternalRendererDrawableAcquisitionPlanningObservation {
    return CjguiInternalRendererDrawableAcquisitionPlanningObservation(
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererDrawableAcquisitionPlanningReadiness(
    metalDeviceLayerBindingReadiness:
        CjguiInternalRendererNoMetalDeviceLayerBindingReadiness,
    planningObservation:
        CjguiInternalRendererDrawableAcquisitionPlanningObservation
): CjguiInternalRendererNoDrawableAcquisitionPlanningReadiness {
    let upstreamReady =
        metalDeviceLayerBindingReadiness
            .didPrepareRendererNoMetalDeviceLayerBindingReadiness &&
        metalDeviceLayerBindingReadiness
            .didConfirmTokenBackedLayerAndDeviceBinding &&
        metalDeviceLayerBindingReadiness
            .didConfirmMainThreadLayerBindingGate &&
        metalDeviceLayerBindingReadiness
            .didConfirmNoCommandQueueBufferEncoderOrRender &&
        metalDeviceLayerBindingReadiness.didConfirmNoPointerHandleClassIdReturn &&
        metalDeviceLayerBindingReadiness.didConfirmNoPublicSurface &&
        metalDeviceLayerBindingReadiness.didConfirmNoRendererStateWrite &&
        metalDeviceLayerBindingReadiness.didConfirmNoBackendReadyTruth
    let planningReady =
        upstreamReady &&
        planningObservation.didAcceptMetalDeviceLayerBindingEvidence &&
        planningObservation.didRequireTokenBackedLayerDeviceBinding &&
        planningObservation.didRequireMainThreadDrawableGate &&
        planningObservation.didRequireNoPresentPath &&
        planningObservation.didRequireCommandQueueBufferBeforeRender &&
        planningObservation.didKeepNextDrawableOutsideThisOwner &&
        planningObservation.didKeepPlanningFactsDehydrated

    if (planningReady) {
        return CjguiInternalRendererNoDrawableAcquisitionPlanningReadiness(
            metalDeviceLayerBindingReadiness,
            planningObservation,
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
            true
        )
    }

    return CjguiInternalRendererNoDrawableAcquisitionPlanningReadiness(
        metalDeviceLayerBindingReadiness,
        planningObservation,
        false,
        true,
        false,
        upstreamReady,
        planningObservation.didRequireTokenBackedLayerDeviceBinding,
        planningObservation.didRequireMainThreadDrawableGate,
        planningObservation.didKeepNextDrawableOutsideThisOwner,
        planningObservation.didRequireNoPresentPath,
        planningObservation.didRequireCommandQueueBufferBeforeRender,
        planningObservation.didRequireCommandQueueBufferBeforeRender,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererDrawableAcquisitionPlanningDraft():
    CjguiInternalRendererNoDrawableAcquisitionPlanningReadiness {
    let metalDeviceLayerBindingReadiness =
        cjguiInternalExecuteDefaultRendererMetalDeviceLayerBindingDraft()
    let planningObservation =
        cjguiInternalObserveRendererDrawableAcquisitionPlanningValues()
    return cjguiInternalBuildRendererDrawableAcquisitionPlanningReadiness(
        metalDeviceLayerBindingReadiness,
        planningObservation
    )
}
