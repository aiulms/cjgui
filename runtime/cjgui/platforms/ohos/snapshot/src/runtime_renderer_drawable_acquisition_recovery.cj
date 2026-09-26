// 维护注释：本文件是 drawable acquisition first implementation recovery owner。
// Truth: 只消费 CjguiInternalRendererNoDrawableAvailabilityReadiness，
// 将 nextDrawable 所需的可见窗口、display-backed layer、run loop 与 command queue
// 前置缺口脱水成 internal recovery facts。
// Stop-line: 不调用 nextDrawable，不获取 drawable，不 present，不创建 command queue /
// command buffer / encoder，不提交 GPU work，不写 runtime_state.cj。
// Same-shape Boundary Brake: recovery facts 不得包装成 drawable-ready、
// backend-ready、render-ready、GPU submission、state write、receipt、record 或 publication。
package cjgui

struct CjguiInternalRendererDrawableAcquisitionRecoveryObservation {
    let didObserveDrawableAvailabilityStillBlocked: Bool
    let didRequireDisplayBackedLayerEvidence: Bool
    let didRequireVisibleWindowEvidence: Bool
    let didRequireRunLoopNonBlockingEvidence: Bool
    let didRequireNoPresentAcquisitionPath: Bool
    let didRequireCommandQueueBufferBeforeRender: Bool
    let didClassifyNextDrawableAsRecoveryOnly: Bool
    let didKeepRecoveryFactsDehydrated: Bool

    init(
        didObserveDrawableAvailabilityStillBlocked: Bool,
        didRequireDisplayBackedLayerEvidence: Bool,
        didRequireVisibleWindowEvidence: Bool,
        didRequireRunLoopNonBlockingEvidence: Bool,
        didRequireNoPresentAcquisitionPath: Bool,
        didRequireCommandQueueBufferBeforeRender: Bool,
        didClassifyNextDrawableAsRecoveryOnly: Bool,
        didKeepRecoveryFactsDehydrated: Bool
    ) {
        this.didObserveDrawableAvailabilityStillBlocked =
            didObserveDrawableAvailabilityStillBlocked
        this.didRequireDisplayBackedLayerEvidence =
            didRequireDisplayBackedLayerEvidence
        this.didRequireVisibleWindowEvidence = didRequireVisibleWindowEvidence
        this.didRequireRunLoopNonBlockingEvidence =
            didRequireRunLoopNonBlockingEvidence
        this.didRequireNoPresentAcquisitionPath =
            didRequireNoPresentAcquisitionPath
        this.didRequireCommandQueueBufferBeforeRender =
            didRequireCommandQueueBufferBeforeRender
        this.didClassifyNextDrawableAsRecoveryOnly =
            didClassifyNextDrawableAsRecoveryOnly
        this.didKeepRecoveryFactsDehydrated = didKeepRecoveryFactsDehydrated
    }
}

struct CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness {
    let drawableAvailabilityReadiness:
        CjguiInternalRendererNoDrawableAvailabilityReadiness
    let recoveryObservation:
        CjguiInternalRendererDrawableAcquisitionRecoveryObservation
    let didPrepareRendererNoDrawableAcquisitionRecoveryReadiness: Bool
    let shouldDeferRendererNoDrawableAcquisitionRecoveryReadiness: Bool
    let shouldReportRendererDrawableAcquisitionRecoveryBlocked: Bool
    let didPreserveRendererDrawableAvailabilityReadiness: Bool
    let didConfirmDrawableAvailabilityStillBlocked: Bool
    let didConfirmDisplayBackedLayerEvidenceMissing: Bool
    let didConfirmVisibleWindowEvidenceMissing: Bool
    let didConfirmRunLoopNonBlockingEvidenceMissing: Bool
    let didConfirmNoNextDrawableCall: Bool
    let didConfirmNoPresentCommandQueueBufferOrRender: Bool
    let didConfirmNoGpuSubmission: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepDrawableAcquisitionRecoveryReadinessDehydrated: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        drawableAvailabilityReadiness:
            CjguiInternalRendererNoDrawableAvailabilityReadiness,
        recoveryObservation:
            CjguiInternalRendererDrawableAcquisitionRecoveryObservation,
        didPrepareRendererNoDrawableAcquisitionRecoveryReadiness: Bool,
        shouldDeferRendererNoDrawableAcquisitionRecoveryReadiness: Bool,
        shouldReportRendererDrawableAcquisitionRecoveryBlocked: Bool,
        didPreserveRendererDrawableAvailabilityReadiness: Bool,
        didConfirmDrawableAvailabilityStillBlocked: Bool,
        didConfirmDisplayBackedLayerEvidenceMissing: Bool,
        didConfirmVisibleWindowEvidenceMissing: Bool,
        didConfirmRunLoopNonBlockingEvidenceMissing: Bool,
        didConfirmNoNextDrawableCall: Bool,
        didConfirmNoPresentCommandQueueBufferOrRender: Bool,
        didConfirmNoGpuSubmission: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepDrawableAcquisitionRecoveryReadinessDehydrated: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.drawableAvailabilityReadiness = drawableAvailabilityReadiness
        this.recoveryObservation = recoveryObservation
        this.didPrepareRendererNoDrawableAcquisitionRecoveryReadiness =
            didPrepareRendererNoDrawableAcquisitionRecoveryReadiness
        this.shouldDeferRendererNoDrawableAcquisitionRecoveryReadiness =
            shouldDeferRendererNoDrawableAcquisitionRecoveryReadiness
        this.shouldReportRendererDrawableAcquisitionRecoveryBlocked =
            shouldReportRendererDrawableAcquisitionRecoveryBlocked
        this.didPreserveRendererDrawableAvailabilityReadiness =
            didPreserveRendererDrawableAvailabilityReadiness
        this.didConfirmDrawableAvailabilityStillBlocked =
            didConfirmDrawableAvailabilityStillBlocked
        this.didConfirmDisplayBackedLayerEvidenceMissing =
            didConfirmDisplayBackedLayerEvidenceMissing
        this.didConfirmVisibleWindowEvidenceMissing =
            didConfirmVisibleWindowEvidenceMissing
        this.didConfirmRunLoopNonBlockingEvidenceMissing =
            didConfirmRunLoopNonBlockingEvidenceMissing
        this.didConfirmNoNextDrawableCall = didConfirmNoNextDrawableCall
        this.didConfirmNoPresentCommandQueueBufferOrRender =
            didConfirmNoPresentCommandQueueBufferOrRender
        this.didConfirmNoGpuSubmission = didConfirmNoGpuSubmission
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepDrawableAcquisitionRecoveryReadinessDehydrated =
            didKeepDrawableAcquisitionRecoveryReadinessDehydrated
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildDefaultRendererDrawableAcquisitionRecoveryObservation():
    CjguiInternalRendererDrawableAcquisitionRecoveryObservation {
    return CjguiInternalRendererDrawableAcquisitionRecoveryObservation(
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

func cjguiInternalBuildRendererDrawableAcquisitionRecoveryReadiness(
    drawableAvailabilityReadiness:
        CjguiInternalRendererNoDrawableAvailabilityReadiness,
    recoveryObservation:
        CjguiInternalRendererDrawableAcquisitionRecoveryObservation
): CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness {
    let availabilityReady =
        drawableAvailabilityReadiness
            .didPrepareRendererNoDrawableAvailabilityReadiness &&
        drawableAvailabilityReadiness.didConfirmDrawableAcquisitionStillBlocked &&
        drawableAvailabilityReadiness.didConfirmPresentStillForbidden &&
        drawableAvailabilityReadiness.didConfirmCommandQueueBufferStillBlocked &&
        drawableAvailabilityReadiness.didConfirmNoNextDrawableCall &&
        drawableAvailabilityReadiness.didConfirmNoRendererStateWrite &&
        drawableAvailabilityReadiness.didConfirmNoBackendReadyTruth
    let recoveryReady =
        availabilityReady &&
        recoveryObservation.didObserveDrawableAvailabilityStillBlocked &&
        recoveryObservation.didRequireDisplayBackedLayerEvidence &&
        recoveryObservation.didRequireVisibleWindowEvidence &&
        recoveryObservation.didRequireRunLoopNonBlockingEvidence &&
        recoveryObservation.didRequireNoPresentAcquisitionPath &&
        recoveryObservation.didRequireCommandQueueBufferBeforeRender &&
        recoveryObservation.didClassifyNextDrawableAsRecoveryOnly &&
        recoveryObservation.didKeepRecoveryFactsDehydrated

    if (recoveryReady) {
        return CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness(
            drawableAvailabilityReadiness,
            recoveryObservation,
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
            true
        )
    }

    return CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness(
        drawableAvailabilityReadiness,
        recoveryObservation,
        false,
        true,
        false,
        availabilityReady,
        recoveryObservation.didObserveDrawableAvailabilityStillBlocked,
        recoveryObservation.didRequireDisplayBackedLayerEvidence,
        recoveryObservation.didRequireVisibleWindowEvidence,
        recoveryObservation.didRequireRunLoopNonBlockingEvidence,
        true,
        drawableAvailabilityReadiness.didConfirmPresentStillForbidden &&
        drawableAvailabilityReadiness.didConfirmCommandQueueBufferStillBlocked,
        drawableAvailabilityReadiness.didConfirmNoGpuSubmission,
        true,
        true,
        true,
        true,
        recoveryObservation.didKeepRecoveryFactsDehydrated,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererDrawableAcquisitionRecoveryDraft():
    CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness {
    let availabilityReadiness =
        cjguiInternalExecuteDefaultRendererDrawableAvailabilityDraft()
    let recoveryObservation =
        cjguiInternalBuildDefaultRendererDrawableAcquisitionRecoveryObservation()
    return cjguiInternalBuildRendererDrawableAcquisitionRecoveryReadiness(
        availabilityReadiness,
        recoveryObservation
    )
}
