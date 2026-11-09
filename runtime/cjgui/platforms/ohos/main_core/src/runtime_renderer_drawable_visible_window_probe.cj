// 维护注释：本文件是 isolated visible-window drawable probe value owner。
// Truth: 只消费 CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness，
// 固定 isolated NSWindow / NSView / CAMetalLayer / MTLDevice 环境 probe facts。
// Stop-line: 不调用 nextDrawable，不获取 drawable，不 present，不创建 command queue /
// command buffer / encoder，不提交 GPU work，不写 runtime_state.cj。
// Same-shape Boundary Brake: visible-window probe facts 不得包装成 drawable-ready、
// backend-ready、render-ready、GPU submission、state write、receipt、record 或 publication。
package cjgui

struct CjguiInternalRendererDrawableVisibleWindowProbeObservation {
    let didExecuteIsolatedVisibleWindowProbe: Bool
    let didObserveIsolatedWindowVisibility: Bool
    let didObserveDisplayBackedLayer: Bool
    let didObserveLayerDeviceBinding: Bool
    let didObserveBoundedRunLoop: Bool
    let didConfirmProbeCleanup: Bool
    let didConfirmDefaultNoNextDrawableCall: Bool
    let didConfirmNoCommandQueueBufferOrRender: Bool
    let didClassifyProbeAsIsolatedOnly: Bool
    let didKeepProbeFactsDehydrated: Bool

    init(
        didExecuteIsolatedVisibleWindowProbe: Bool,
        didObserveIsolatedWindowVisibility: Bool,
        didObserveDisplayBackedLayer: Bool,
        didObserveLayerDeviceBinding: Bool,
        didObserveBoundedRunLoop: Bool,
        didConfirmProbeCleanup: Bool,
        didConfirmDefaultNoNextDrawableCall: Bool,
        didConfirmNoCommandQueueBufferOrRender: Bool,
        didClassifyProbeAsIsolatedOnly: Bool,
        didKeepProbeFactsDehydrated: Bool
    ) {
        this.didExecuteIsolatedVisibleWindowProbe =
            didExecuteIsolatedVisibleWindowProbe
        this.didObserveIsolatedWindowVisibility =
            didObserveIsolatedWindowVisibility
        this.didObserveDisplayBackedLayer = didObserveDisplayBackedLayer
        this.didObserveLayerDeviceBinding = didObserveLayerDeviceBinding
        this.didObserveBoundedRunLoop = didObserveBoundedRunLoop
        this.didConfirmProbeCleanup = didConfirmProbeCleanup
        this.didConfirmDefaultNoNextDrawableCall =
            didConfirmDefaultNoNextDrawableCall
        this.didConfirmNoCommandQueueBufferOrRender =
            didConfirmNoCommandQueueBufferOrRender
        this.didClassifyProbeAsIsolatedOnly = didClassifyProbeAsIsolatedOnly
        this.didKeepProbeFactsDehydrated = didKeepProbeFactsDehydrated
    }
}

struct CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness {
    let environmentVisibilityReadiness:
        CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness
    let probeObservation:
        CjguiInternalRendererDrawableVisibleWindowProbeObservation
    let didPrepareRendererNoDrawableVisibleWindowProbeReadiness: Bool
    let shouldDeferRendererNoDrawableVisibleWindowProbeReadiness: Bool
    let shouldReportRendererDrawableNoPresentAcquisitionBlocked: Bool
    let didPreserveRendererDrawableEnvironmentVisibilityReadiness: Bool
    let didConfirmIsolatedVisibleWindowProbeExecuted: Bool
    let didConfirmIsolatedWindowVisibility: Bool
    let didConfirmDisplayBackedLayer: Bool
    let didConfirmLayerDeviceBinding: Bool
    let didConfirmBoundedRunLoop: Bool
    let didConfirmProbeCleanup: Bool
    let didConfirmProductionRuntimeNoWindowSemanticsChange: Bool
    let didConfirmNoNextDrawableCall: Bool
    let didConfirmNoPresentCommandQueueBufferOrRender: Bool
    let didConfirmNoGpuSubmission: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepDrawableVisibleWindowProbeReadinessDehydrated: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        environmentVisibilityReadiness:
            CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness,
        probeObservation:
            CjguiInternalRendererDrawableVisibleWindowProbeObservation,
        didPrepareRendererNoDrawableVisibleWindowProbeReadiness: Bool,
        shouldDeferRendererNoDrawableVisibleWindowProbeReadiness: Bool,
        shouldReportRendererDrawableNoPresentAcquisitionBlocked: Bool,
        didPreserveRendererDrawableEnvironmentVisibilityReadiness: Bool,
        didConfirmIsolatedVisibleWindowProbeExecuted: Bool,
        didConfirmIsolatedWindowVisibility: Bool,
        didConfirmDisplayBackedLayer: Bool,
        didConfirmLayerDeviceBinding: Bool,
        didConfirmBoundedRunLoop: Bool,
        didConfirmProbeCleanup: Bool,
        didConfirmProductionRuntimeNoWindowSemanticsChange: Bool,
        didConfirmNoNextDrawableCall: Bool,
        didConfirmNoPresentCommandQueueBufferOrRender: Bool,
        didConfirmNoGpuSubmission: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepDrawableVisibleWindowProbeReadinessDehydrated: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.environmentVisibilityReadiness =
            environmentVisibilityReadiness
        this.probeObservation = probeObservation
        this.didPrepareRendererNoDrawableVisibleWindowProbeReadiness =
            didPrepareRendererNoDrawableVisibleWindowProbeReadiness
        this.shouldDeferRendererNoDrawableVisibleWindowProbeReadiness =
            shouldDeferRendererNoDrawableVisibleWindowProbeReadiness
        this.shouldReportRendererDrawableNoPresentAcquisitionBlocked =
            shouldReportRendererDrawableNoPresentAcquisitionBlocked
        this.didPreserveRendererDrawableEnvironmentVisibilityReadiness =
            didPreserveRendererDrawableEnvironmentVisibilityReadiness
        this.didConfirmIsolatedVisibleWindowProbeExecuted =
            didConfirmIsolatedVisibleWindowProbeExecuted
        this.didConfirmIsolatedWindowVisibility =
            didConfirmIsolatedWindowVisibility
        this.didConfirmDisplayBackedLayer = didConfirmDisplayBackedLayer
        this.didConfirmLayerDeviceBinding = didConfirmLayerDeviceBinding
        this.didConfirmBoundedRunLoop = didConfirmBoundedRunLoop
        this.didConfirmProbeCleanup = didConfirmProbeCleanup
        this.didConfirmProductionRuntimeNoWindowSemanticsChange =
            didConfirmProductionRuntimeNoWindowSemanticsChange
        this.didConfirmNoNextDrawableCall = didConfirmNoNextDrawableCall
        this.didConfirmNoPresentCommandQueueBufferOrRender =
            didConfirmNoPresentCommandQueueBufferOrRender
        this.didConfirmNoGpuSubmission = didConfirmNoGpuSubmission
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepDrawableVisibleWindowProbeReadinessDehydrated =
            didKeepDrawableVisibleWindowProbeReadinessDehydrated
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildDefaultRendererDrawableVisibleWindowProbeObservation():
    CjguiInternalRendererDrawableVisibleWindowProbeObservation {
    return CjguiInternalRendererDrawableVisibleWindowProbeObservation(
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

func cjguiInternalBuildRendererDrawableVisibleWindowProbeReadiness(
    environmentVisibilityReadiness:
        CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness,
    probeObservation:
        CjguiInternalRendererDrawableVisibleWindowProbeObservation
): CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness {
    let environmentReady =
        environmentVisibilityReadiness
            .didPrepareRendererNoDrawableEnvironmentVisibilityReadiness &&
        environmentVisibilityReadiness.didConfirmWindowVisibilityRequirement &&
        environmentVisibilityReadiness.didConfirmMainThreadRunLoopRequirement &&
        environmentVisibilityReadiness.didConfirmDisplayBackingRequirement &&
        environmentVisibilityReadiness.didConfirmLayerDeviceBindingRequirement &&
        environmentVisibilityReadiness
            .didConfirmNoPresentAcquisitionCleanupRequirement &&
        environmentVisibilityReadiness.didConfirmProductionRuntimeNoWindowCreation &&
        environmentVisibilityReadiness.didConfirmNoNextDrawableCall &&
        environmentVisibilityReadiness
            .didConfirmNoPresentCommandQueueBufferOrRender &&
        environmentVisibilityReadiness.didConfirmNoGpuSubmission &&
        environmentVisibilityReadiness.didConfirmNoRendererStateWrite &&
        environmentVisibilityReadiness.didConfirmNoBackendReadyTruth
    let probeReady =
        environmentReady &&
        probeObservation.didExecuteIsolatedVisibleWindowProbe &&
        probeObservation.didObserveIsolatedWindowVisibility &&
        probeObservation.didObserveDisplayBackedLayer &&
        probeObservation.didObserveLayerDeviceBinding &&
        probeObservation.didObserveBoundedRunLoop &&
        probeObservation.didConfirmProbeCleanup &&
        probeObservation.didConfirmDefaultNoNextDrawableCall &&
        probeObservation.didConfirmNoCommandQueueBufferOrRender &&
        probeObservation.didClassifyProbeAsIsolatedOnly &&
        probeObservation.didKeepProbeFactsDehydrated

    if (probeReady) {
        return CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness(
            environmentVisibilityReadiness,
            probeObservation,
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
            true,
            true
        )
    }

    return CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness(
        environmentVisibilityReadiness,
        probeObservation,
        false,
        true,
        false,
        environmentReady,
        probeObservation.didExecuteIsolatedVisibleWindowProbe,
        probeObservation.didObserveIsolatedWindowVisibility,
        probeObservation.didObserveDisplayBackedLayer,
        probeObservation.didObserveLayerDeviceBinding,
        probeObservation.didObserveBoundedRunLoop,
        probeObservation.didConfirmProbeCleanup,
        environmentVisibilityReadiness.didConfirmProductionRuntimeNoWindowCreation,
        probeObservation.didConfirmDefaultNoNextDrawableCall,
        probeObservation.didConfirmNoCommandQueueBufferOrRender,
        true,
        true,
        true,
        true,
        true,
        probeObservation.didKeepProbeFactsDehydrated,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererDrawableVisibleWindowProbeDraft():
    CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness {
    let environmentVisibilityReadiness =
        cjguiInternalExecuteDefaultRendererDrawableEnvironmentVisibilityDraft()
    let probeObservation =
        cjguiInternalBuildDefaultRendererDrawableVisibleWindowProbeObservation()
    return cjguiInternalBuildRendererDrawableVisibleWindowProbeReadiness(
        environmentVisibilityReadiness,
        probeObservation
    )
}
