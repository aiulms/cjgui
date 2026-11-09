// 维护注释：本文件是 drawable environment / window visibility planning owner。
// Truth: 只消费 CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness，
// 固定 nextDrawable 前置的 visible window、main-thread run loop、display backing
// 与 no-present cleanup 需求；不调用 nextDrawable。
// Stop-line: 不创建 NSWindow，不获取 drawable，不 present，不创建 command queue /
// command buffer / encoder，不提交 GPU work，不写 runtime_state.cj。
// Same-shape Boundary Brake: environment facts 不得包装成 drawable-ready、
// backend-ready、render-ready、GPU submission、state write、receipt、record 或 publication。
package cjgui

struct CjguiInternalRendererDrawableEnvironmentVisibilityObservation {
    let didRequireVisibleWindowEvidence: Bool
    let didRequireMainThreadRunLoopEvidence: Bool
    let didRequireDisplayBackedLayerEvidence: Bool
    let didRequireLayerDeviceBindingEvidence: Bool
    let didRequireBoundedNoPresentProbe: Bool
    let didConfirmProductionRuntimeWindowStillAbsent: Bool
    let didConfirmDefaultNoNextDrawableCall: Bool
    let didConfirmNoCommandQueueBufferOrRender: Bool
    let didClassifyVisibleWindowProbeAsIsolatedOnly: Bool
    let didKeepEnvironmentFactsDehydrated: Bool

    init(
        didRequireVisibleWindowEvidence: Bool,
        didRequireMainThreadRunLoopEvidence: Bool,
        didRequireDisplayBackedLayerEvidence: Bool,
        didRequireLayerDeviceBindingEvidence: Bool,
        didRequireBoundedNoPresentProbe: Bool,
        didConfirmProductionRuntimeWindowStillAbsent: Bool,
        didConfirmDefaultNoNextDrawableCall: Bool,
        didConfirmNoCommandQueueBufferOrRender: Bool,
        didClassifyVisibleWindowProbeAsIsolatedOnly: Bool,
        didKeepEnvironmentFactsDehydrated: Bool
    ) {
        this.didRequireVisibleWindowEvidence = didRequireVisibleWindowEvidence
        this.didRequireMainThreadRunLoopEvidence =
            didRequireMainThreadRunLoopEvidence
        this.didRequireDisplayBackedLayerEvidence =
            didRequireDisplayBackedLayerEvidence
        this.didRequireLayerDeviceBindingEvidence =
            didRequireLayerDeviceBindingEvidence
        this.didRequireBoundedNoPresentProbe = didRequireBoundedNoPresentProbe
        this.didConfirmProductionRuntimeWindowStillAbsent =
            didConfirmProductionRuntimeWindowStillAbsent
        this.didConfirmDefaultNoNextDrawableCall =
            didConfirmDefaultNoNextDrawableCall
        this.didConfirmNoCommandQueueBufferOrRender =
            didConfirmNoCommandQueueBufferOrRender
        this.didClassifyVisibleWindowProbeAsIsolatedOnly =
            didClassifyVisibleWindowProbeAsIsolatedOnly
        this.didKeepEnvironmentFactsDehydrated =
            didKeepEnvironmentFactsDehydrated
    }
}

struct CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness {
    let recoveryReadiness:
        CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness
    let visibilityObservation:
        CjguiInternalRendererDrawableEnvironmentVisibilityObservation
    let didPrepareRendererNoDrawableEnvironmentVisibilityReadiness: Bool
    let shouldDeferRendererNoDrawableEnvironmentVisibilityReadiness: Bool
    let shouldReportRendererDrawableEnvironmentVisibilityBlocked: Bool
    let didPreserveRendererDrawableAcquisitionRecoveryReadiness: Bool
    let didConfirmWindowVisibilityRequirement: Bool
    let didConfirmMainThreadRunLoopRequirement: Bool
    let didConfirmDisplayBackingRequirement: Bool
    let didConfirmLayerDeviceBindingRequirement: Bool
    let didConfirmNoPresentAcquisitionCleanupRequirement: Bool
    let didConfirmProductionRuntimeNoWindowCreation: Bool
    let didConfirmNoNextDrawableCall: Bool
    let didConfirmNoPresentCommandQueueBufferOrRender: Bool
    let didConfirmNoGpuSubmission: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepDrawableEnvironmentVisibilityReadinessDehydrated: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        recoveryReadiness:
            CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness,
        visibilityObservation:
            CjguiInternalRendererDrawableEnvironmentVisibilityObservation,
        didPrepareRendererNoDrawableEnvironmentVisibilityReadiness: Bool,
        shouldDeferRendererNoDrawableEnvironmentVisibilityReadiness: Bool,
        shouldReportRendererDrawableEnvironmentVisibilityBlocked: Bool,
        didPreserveRendererDrawableAcquisitionRecoveryReadiness: Bool,
        didConfirmWindowVisibilityRequirement: Bool,
        didConfirmMainThreadRunLoopRequirement: Bool,
        didConfirmDisplayBackingRequirement: Bool,
        didConfirmLayerDeviceBindingRequirement: Bool,
        didConfirmNoPresentAcquisitionCleanupRequirement: Bool,
        didConfirmProductionRuntimeNoWindowCreation: Bool,
        didConfirmNoNextDrawableCall: Bool,
        didConfirmNoPresentCommandQueueBufferOrRender: Bool,
        didConfirmNoGpuSubmission: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepDrawableEnvironmentVisibilityReadinessDehydrated: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.recoveryReadiness = recoveryReadiness
        this.visibilityObservation = visibilityObservation
        this.didPrepareRendererNoDrawableEnvironmentVisibilityReadiness =
            didPrepareRendererNoDrawableEnvironmentVisibilityReadiness
        this.shouldDeferRendererNoDrawableEnvironmentVisibilityReadiness =
            shouldDeferRendererNoDrawableEnvironmentVisibilityReadiness
        this.shouldReportRendererDrawableEnvironmentVisibilityBlocked =
            shouldReportRendererDrawableEnvironmentVisibilityBlocked
        this.didPreserveRendererDrawableAcquisitionRecoveryReadiness =
            didPreserveRendererDrawableAcquisitionRecoveryReadiness
        this.didConfirmWindowVisibilityRequirement =
            didConfirmWindowVisibilityRequirement
        this.didConfirmMainThreadRunLoopRequirement =
            didConfirmMainThreadRunLoopRequirement
        this.didConfirmDisplayBackingRequirement =
            didConfirmDisplayBackingRequirement
        this.didConfirmLayerDeviceBindingRequirement =
            didConfirmLayerDeviceBindingRequirement
        this.didConfirmNoPresentAcquisitionCleanupRequirement =
            didConfirmNoPresentAcquisitionCleanupRequirement
        this.didConfirmProductionRuntimeNoWindowCreation =
            didConfirmProductionRuntimeNoWindowCreation
        this.didConfirmNoNextDrawableCall = didConfirmNoNextDrawableCall
        this.didConfirmNoPresentCommandQueueBufferOrRender =
            didConfirmNoPresentCommandQueueBufferOrRender
        this.didConfirmNoGpuSubmission = didConfirmNoGpuSubmission
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepDrawableEnvironmentVisibilityReadinessDehydrated =
            didKeepDrawableEnvironmentVisibilityReadinessDehydrated
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildDefaultRendererDrawableEnvironmentVisibilityObservation():
    CjguiInternalRendererDrawableEnvironmentVisibilityObservation {
    return CjguiInternalRendererDrawableEnvironmentVisibilityObservation(
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

func cjguiInternalBuildRendererDrawableEnvironmentVisibilityReadiness(
    recoveryReadiness:
        CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness,
    visibilityObservation:
        CjguiInternalRendererDrawableEnvironmentVisibilityObservation
): CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness {
    let recoveryReady =
        recoveryReadiness
            .didPrepareRendererNoDrawableAcquisitionRecoveryReadiness &&
        recoveryReadiness.didConfirmDrawableAvailabilityStillBlocked &&
        recoveryReadiness.didConfirmDisplayBackedLayerEvidenceMissing &&
        recoveryReadiness.didConfirmVisibleWindowEvidenceMissing &&
        recoveryReadiness.didConfirmRunLoopNonBlockingEvidenceMissing &&
        recoveryReadiness.didConfirmNoNextDrawableCall &&
        recoveryReadiness.didConfirmNoPresentCommandQueueBufferOrRender &&
        recoveryReadiness.didConfirmNoGpuSubmission &&
        recoveryReadiness.didConfirmNoRendererStateWrite &&
        recoveryReadiness.didConfirmNoBackendReadyTruth
    let visibilityReady =
        recoveryReady &&
        visibilityObservation.didRequireVisibleWindowEvidence &&
        visibilityObservation.didRequireMainThreadRunLoopEvidence &&
        visibilityObservation.didRequireDisplayBackedLayerEvidence &&
        visibilityObservation.didRequireLayerDeviceBindingEvidence &&
        visibilityObservation.didRequireBoundedNoPresentProbe &&
        visibilityObservation.didConfirmProductionRuntimeWindowStillAbsent &&
        visibilityObservation.didConfirmDefaultNoNextDrawableCall &&
        visibilityObservation.didConfirmNoCommandQueueBufferOrRender &&
        visibilityObservation.didClassifyVisibleWindowProbeAsIsolatedOnly &&
        visibilityObservation.didKeepEnvironmentFactsDehydrated

    if (visibilityReady) {
        return CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness(
            recoveryReadiness,
            visibilityObservation,
            true,
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
            true,
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness(
        recoveryReadiness,
        visibilityObservation,
        false,
        true,
        false,
        recoveryReady,
        visibilityObservation.didRequireVisibleWindowEvidence,
        visibilityObservation.didRequireMainThreadRunLoopEvidence,
        visibilityObservation.didRequireDisplayBackedLayerEvidence,
        visibilityObservation.didRequireLayerDeviceBindingEvidence,
        visibilityObservation.didRequireBoundedNoPresentProbe,
        visibilityObservation.didConfirmProductionRuntimeWindowStillAbsent,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        visibilityObservation.didKeepEnvironmentFactsDehydrated,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererDrawableEnvironmentVisibilityDraft():
    CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness {
    let recoveryReadiness =
        cjguiInternalExecuteDefaultRendererDrawableAcquisitionRecoveryDraft()
    let visibilityObservation =
        cjguiInternalBuildDefaultRendererDrawableEnvironmentVisibilityObservation()
    return cjguiInternalBuildRendererDrawableEnvironmentVisibilityReadiness(
        recoveryReadiness,
        visibilityObservation
    )
}
