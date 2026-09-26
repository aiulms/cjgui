// 维护注释：本文件是 drawable no-present acquisition value owner。
// Truth: 只消费 CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness，
// 固定 isolated visible-window probe 中 nextDrawable 可 no-present acquire 的脱水事实。
// Stop-line: 不 present，不创建 command queue / command buffer / encoder，
// 不提交 GPU work，不执行 render，不写 runtime_state.cj，不接 production render path。
// Same-shape Boundary Brake: no-present drawable facts 不得包装成 backend-ready、
// render-ready、GPU submission、state write、receipt、record 或 publication。
package cjgui

struct CjguiInternalRendererDrawableNoPresentAcquisitionObservation {
    let didExecuteIsolatedNextDrawableCall: Bool
    let didObserveBoundedNextDrawableReturn: Bool
    let didObserveDrawableAcquired: Bool
    let didKeepDrawableLocalAndUnstored: Bool
    let didConfirmNoPresent: Bool
    let didConfirmNoCommandQueueBufferEncoder: Bool
    let didConfirmNoGpuSubmissionOrRender: Bool
    let didConfirmCleanupAfterAcquisition: Bool
    let didClassifyEvidenceAsIsolatedProbeOnly: Bool
    let didKeepNoPresentAcquisitionFactsDehydrated: Bool

    init(
        didExecuteIsolatedNextDrawableCall: Bool,
        didObserveBoundedNextDrawableReturn: Bool,
        didObserveDrawableAcquired: Bool,
        didKeepDrawableLocalAndUnstored: Bool,
        didConfirmNoPresent: Bool,
        didConfirmNoCommandQueueBufferEncoder: Bool,
        didConfirmNoGpuSubmissionOrRender: Bool,
        didConfirmCleanupAfterAcquisition: Bool,
        didClassifyEvidenceAsIsolatedProbeOnly: Bool,
        didKeepNoPresentAcquisitionFactsDehydrated: Bool
    ) {
        this.didExecuteIsolatedNextDrawableCall =
            didExecuteIsolatedNextDrawableCall
        this.didObserveBoundedNextDrawableReturn =
            didObserveBoundedNextDrawableReturn
        this.didObserveDrawableAcquired = didObserveDrawableAcquired
        this.didKeepDrawableLocalAndUnstored =
            didKeepDrawableLocalAndUnstored
        this.didConfirmNoPresent = didConfirmNoPresent
        this.didConfirmNoCommandQueueBufferEncoder =
            didConfirmNoCommandQueueBufferEncoder
        this.didConfirmNoGpuSubmissionOrRender =
            didConfirmNoGpuSubmissionOrRender
        this.didConfirmCleanupAfterAcquisition =
            didConfirmCleanupAfterAcquisition
        this.didClassifyEvidenceAsIsolatedProbeOnly =
            didClassifyEvidenceAsIsolatedProbeOnly
        this.didKeepNoPresentAcquisitionFactsDehydrated =
            didKeepNoPresentAcquisitionFactsDehydrated
    }
}

struct CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness {
    let visibleWindowProbeReadiness:
        CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness
    let acquisitionObservation:
        CjguiInternalRendererDrawableNoPresentAcquisitionObservation
    let didPrepareRendererNoDrawableNoPresentAcquisitionReadiness: Bool
    let shouldDeferRendererNoDrawableNoPresentAcquisitionReadiness: Bool
    let shouldReportRendererDrawableNoPresentAcquisitionBlocked: Bool
    let didPreserveRendererDrawableVisibleWindowProbeReadiness: Bool
    let didConfirmIsolatedVisibleWindowPrerequisite: Bool
    let didConfirmDisplayBackedLayerPrerequisite: Bool
    let didConfirmBoundedRunLoopPrerequisite: Bool
    let didConfirmIsolatedNextDrawableNoPresentAcquisition: Bool
    let didConfirmDrawableNotSavedOrReturned: Bool
    let didConfirmNoPresentCommandQueueBufferEncoderOrRender: Bool
    let didConfirmNoGpuSubmission: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoProductionRuntimeWindowSemanticsChange: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepDrawableNoPresentAcquisitionReadinessDehydrated: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        visibleWindowProbeReadiness:
            CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness,
        acquisitionObservation:
            CjguiInternalRendererDrawableNoPresentAcquisitionObservation,
        didPrepareRendererNoDrawableNoPresentAcquisitionReadiness: Bool,
        shouldDeferRendererNoDrawableNoPresentAcquisitionReadiness: Bool,
        shouldReportRendererDrawableNoPresentAcquisitionBlocked: Bool,
        didPreserveRendererDrawableVisibleWindowProbeReadiness: Bool,
        didConfirmIsolatedVisibleWindowPrerequisite: Bool,
        didConfirmDisplayBackedLayerPrerequisite: Bool,
        didConfirmBoundedRunLoopPrerequisite: Bool,
        didConfirmIsolatedNextDrawableNoPresentAcquisition: Bool,
        didConfirmDrawableNotSavedOrReturned: Bool,
        didConfirmNoPresentCommandQueueBufferEncoderOrRender: Bool,
        didConfirmNoGpuSubmission: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoProductionRuntimeWindowSemanticsChange: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepDrawableNoPresentAcquisitionReadinessDehydrated: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.visibleWindowProbeReadiness = visibleWindowProbeReadiness
        this.acquisitionObservation = acquisitionObservation
        this.didPrepareRendererNoDrawableNoPresentAcquisitionReadiness =
            didPrepareRendererNoDrawableNoPresentAcquisitionReadiness
        this.shouldDeferRendererNoDrawableNoPresentAcquisitionReadiness =
            shouldDeferRendererNoDrawableNoPresentAcquisitionReadiness
        this.shouldReportRendererDrawableNoPresentAcquisitionBlocked =
            shouldReportRendererDrawableNoPresentAcquisitionBlocked
        this.didPreserveRendererDrawableVisibleWindowProbeReadiness =
            didPreserveRendererDrawableVisibleWindowProbeReadiness
        this.didConfirmIsolatedVisibleWindowPrerequisite =
            didConfirmIsolatedVisibleWindowPrerequisite
        this.didConfirmDisplayBackedLayerPrerequisite =
            didConfirmDisplayBackedLayerPrerequisite
        this.didConfirmBoundedRunLoopPrerequisite =
            didConfirmBoundedRunLoopPrerequisite
        this.didConfirmIsolatedNextDrawableNoPresentAcquisition =
            didConfirmIsolatedNextDrawableNoPresentAcquisition
        this.didConfirmDrawableNotSavedOrReturned =
            didConfirmDrawableNotSavedOrReturned
        this.didConfirmNoPresentCommandQueueBufferEncoderOrRender =
            didConfirmNoPresentCommandQueueBufferEncoderOrRender
        this.didConfirmNoGpuSubmission = didConfirmNoGpuSubmission
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoProductionRuntimeWindowSemanticsChange =
            didConfirmNoProductionRuntimeWindowSemanticsChange
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepDrawableNoPresentAcquisitionReadinessDehydrated =
            didKeepDrawableNoPresentAcquisitionReadinessDehydrated
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildDefaultRendererDrawableNoPresentAcquisitionObservation():
    CjguiInternalRendererDrawableNoPresentAcquisitionObservation {
    return CjguiInternalRendererDrawableNoPresentAcquisitionObservation(
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

func cjguiInternalBuildRendererDrawableNoPresentAcquisitionReadiness(
    visibleWindowProbeReadiness:
        CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness,
    acquisitionObservation:
        CjguiInternalRendererDrawableNoPresentAcquisitionObservation
): CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness {
    let visibleWindowReady =
        visibleWindowProbeReadiness
            .didPrepareRendererNoDrawableVisibleWindowProbeReadiness &&
        visibleWindowProbeReadiness
            .didConfirmIsolatedVisibleWindowProbeExecuted &&
        visibleWindowProbeReadiness.didConfirmIsolatedWindowVisibility &&
        visibleWindowProbeReadiness.didConfirmDisplayBackedLayer &&
        visibleWindowProbeReadiness.didConfirmLayerDeviceBinding &&
        visibleWindowProbeReadiness.didConfirmBoundedRunLoop &&
        visibleWindowProbeReadiness.didConfirmProbeCleanup &&
        visibleWindowProbeReadiness
            .didConfirmProductionRuntimeNoWindowSemanticsChange &&
        visibleWindowProbeReadiness.didConfirmNoPresentCommandQueueBufferOrRender &&
        visibleWindowProbeReadiness.didConfirmNoGpuSubmission &&
        visibleWindowProbeReadiness.didConfirmNoPointerHandleClassIdReturn &&
        visibleWindowProbeReadiness.didConfirmNoPublicSurface &&
        visibleWindowProbeReadiness.didConfirmNoRendererStateWrite &&
        visibleWindowProbeReadiness.didConfirmNoBackendReadyTruth
    let acquisitionReady =
        visibleWindowReady &&
        acquisitionObservation.didExecuteIsolatedNextDrawableCall &&
        acquisitionObservation.didObserveBoundedNextDrawableReturn &&
        acquisitionObservation.didObserveDrawableAcquired &&
        acquisitionObservation.didKeepDrawableLocalAndUnstored &&
        acquisitionObservation.didConfirmNoPresent &&
        acquisitionObservation.didConfirmNoCommandQueueBufferEncoder &&
        acquisitionObservation.didConfirmNoGpuSubmissionOrRender &&
        acquisitionObservation.didConfirmCleanupAfterAcquisition &&
        acquisitionObservation.didClassifyEvidenceAsIsolatedProbeOnly &&
        acquisitionObservation.didKeepNoPresentAcquisitionFactsDehydrated

    if (acquisitionReady) {
        return CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness(
            visibleWindowProbeReadiness,
            acquisitionObservation,
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
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness(
        visibleWindowProbeReadiness,
        acquisitionObservation,
        false,
        true,
        true,
        visibleWindowReady,
        visibleWindowProbeReadiness.didConfirmIsolatedWindowVisibility,
        visibleWindowProbeReadiness.didConfirmDisplayBackedLayer,
        visibleWindowProbeReadiness.didConfirmBoundedRunLoop,
        acquisitionObservation.didExecuteIsolatedNextDrawableCall &&
        acquisitionObservation.didObserveBoundedNextDrawableReturn &&
        acquisitionObservation.didObserveDrawableAcquired,
        acquisitionObservation.didKeepDrawableLocalAndUnstored,
        acquisitionObservation.didConfirmNoPresent &&
        acquisitionObservation.didConfirmNoCommandQueueBufferEncoder &&
        acquisitionObservation.didConfirmNoGpuSubmissionOrRender,
        acquisitionObservation.didConfirmNoGpuSubmissionOrRender,
        true,
        visibleWindowProbeReadiness
            .didConfirmProductionRuntimeNoWindowSemanticsChange,
        true,
        true,
        true,
        acquisitionObservation.didKeepNoPresentAcquisitionFactsDehydrated,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererDrawableNoPresentAcquisitionDraft():
    CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness {
    let visibleWindowProbeReadiness =
        cjguiInternalExecuteDefaultRendererDrawableVisibleWindowProbeDraft()
    let acquisitionObservation =
        cjguiInternalBuildDefaultRendererDrawableNoPresentAcquisitionObservation()
    return cjguiInternalBuildRendererDrawableNoPresentAcquisitionReadiness(
        visibleWindowProbeReadiness,
        acquisitionObservation
    )
}
