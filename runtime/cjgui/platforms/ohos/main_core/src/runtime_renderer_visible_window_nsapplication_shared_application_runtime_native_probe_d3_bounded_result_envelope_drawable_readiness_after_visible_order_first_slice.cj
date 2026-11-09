// 中文维护注释：本文件是 stage135 drawable readiness after visible-order
// first-slice runtime owner。
// Owner: runtime renderer internal drawable readiness after visible-order smoke。
// Truth: 消费 stage134 visible-order smoke readiness，只把下一段 Metal device
// binding / drawable readiness 建模为 isolated result-envelope gate；当前宿主无
// Metal device 时必须阻止 drawable acquisition，并准备 command pipeline contract。
// Stop-line: 不调用 native AppKit/Metal，不获取 drawable，不创建 command queue /
// buffer / encoder，不 draw / commit / present，不写 renderer state /
// runtime_state.cj，不扩 public API / public C ABI / native bridge。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceFacts {
    let didConsumeVisibleOrderSmokeReadiness: Bool
    let didRequireVisibleOrderSmokeBeforeDrawableReadiness: Bool
    let didRequireMetalDeviceBindingReprobeBeforeDrawable: Bool
    let didClassifyDrawableBlockedWhenMetalDeviceUnavailable: Bool
    let didKeepDrawableFactsIsolated: Bool
    let didKeepDrawableRequestBlockedUntilMetalDeviceReady: Bool
    let didKeepCommandQueueBlockedUntilDrawableReadiness: Bool
    let didPrepareCommandPipelineContractRoute: Bool
    let didKeepFirstFrameObservationBlocked: Bool
    let didKeepProductionTruthPromotionBlocked: Bool
    let didKeepRendererStateWriteAdmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool

    init(
        didConsumeVisibleOrderSmokeReadiness: Bool,
        didRequireVisibleOrderSmokeBeforeDrawableReadiness: Bool,
        didRequireMetalDeviceBindingReprobeBeforeDrawable: Bool,
        didClassifyDrawableBlockedWhenMetalDeviceUnavailable: Bool,
        didKeepDrawableFactsIsolated: Bool,
        didKeepDrawableRequestBlockedUntilMetalDeviceReady: Bool,
        didKeepCommandQueueBlockedUntilDrawableReadiness: Bool,
        didPrepareCommandPipelineContractRoute: Bool,
        didKeepFirstFrameObservationBlocked: Bool,
        didKeepProductionTruthPromotionBlocked: Bool,
        didKeepRendererStateWriteAdmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool
    ) {
        this.didConsumeVisibleOrderSmokeReadiness =
            didConsumeVisibleOrderSmokeReadiness
        this.didRequireVisibleOrderSmokeBeforeDrawableReadiness =
            didRequireVisibleOrderSmokeBeforeDrawableReadiness
        this.didRequireMetalDeviceBindingReprobeBeforeDrawable =
            didRequireMetalDeviceBindingReprobeBeforeDrawable
        this.didClassifyDrawableBlockedWhenMetalDeviceUnavailable =
            didClassifyDrawableBlockedWhenMetalDeviceUnavailable
        this.didKeepDrawableFactsIsolated = didKeepDrawableFactsIsolated
        this.didKeepDrawableRequestBlockedUntilMetalDeviceReady =
            didKeepDrawableRequestBlockedUntilMetalDeviceReady
        this.didKeepCommandQueueBlockedUntilDrawableReadiness =
            didKeepCommandQueueBlockedUntilDrawableReadiness
        this.didPrepareCommandPipelineContractRoute =
            didPrepareCommandPipelineContractRoute
        this.didKeepFirstFrameObservationBlocked =
            didKeepFirstFrameObservationBlocked
        this.didKeepProductionTruthPromotionBlocked =
            didKeepProductionTruthPromotionBlocked
        this.didKeepRendererStateWriteAdmissionBlocked =
            didKeepRendererStateWriteAdmissionBlocked
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked =
            didKeepRuntimeStateWriteBlocked
        this.didConfirmNoNativeBridgeExpansion =
            didConfirmNoNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceReadiness {
    let visibleOrderSmokeReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceReadiness
    let drawableReadinessFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceFacts
    let didPrepareDrawableReadinessAfterVisibleOrderFirstSliceReadiness: Bool
    let shouldConsumeVisibleOrderSmokeReadiness: Bool
    let shouldRequireVisibleOrderSmokeBeforeDrawableReadiness: Bool
    let shouldRequireMetalDeviceBindingReprobeBeforeDrawable: Bool
    let shouldClassifyDrawableBlockedWhenMetalDeviceUnavailable: Bool
    let shouldKeepDrawableFactsIsolated: Bool
    let shouldKeepDrawableRequestBlockedUntilMetalDeviceReady: Bool
    let shouldKeepCommandQueueBlockedUntilDrawableReadiness: Bool
    let shouldContinueCommandPipelineContractRoute: Bool
    let didConfirmVisibleOrderSmokeInput: Bool
    let didConfirmDrawableReadinessGate: Bool
    let didConfirmDrawableStopLine: Bool
    let didConfirmFirstFrameObservationBlocked: Bool
    let didConfirmProductionTruthPromotionBlocked: Bool
    let didConfirmRendererStateWriteAdmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool

    init(
        visibleOrderSmokeReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceReadiness,
        drawableReadinessFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceFacts,
        didPrepareDrawableReadinessAfterVisibleOrderFirstSliceReadiness: Bool,
        shouldConsumeVisibleOrderSmokeReadiness: Bool,
        shouldRequireVisibleOrderSmokeBeforeDrawableReadiness: Bool,
        shouldRequireMetalDeviceBindingReprobeBeforeDrawable: Bool,
        shouldClassifyDrawableBlockedWhenMetalDeviceUnavailable: Bool,
        shouldKeepDrawableFactsIsolated: Bool,
        shouldKeepDrawableRequestBlockedUntilMetalDeviceReady: Bool,
        shouldKeepCommandQueueBlockedUntilDrawableReadiness: Bool,
        shouldContinueCommandPipelineContractRoute: Bool,
        didConfirmVisibleOrderSmokeInput: Bool,
        didConfirmDrawableReadinessGate: Bool,
        didConfirmDrawableStopLine: Bool,
        didConfirmFirstFrameObservationBlocked: Bool,
        didConfirmProductionTruthPromotionBlocked: Bool,
        didConfirmRendererStateWriteAdmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool
    ) {
        this.visibleOrderSmokeReadiness = visibleOrderSmokeReadiness
        this.drawableReadinessFacts = drawableReadinessFacts
        this.didPrepareDrawableReadinessAfterVisibleOrderFirstSliceReadiness =
            didPrepareDrawableReadinessAfterVisibleOrderFirstSliceReadiness
        this.shouldConsumeVisibleOrderSmokeReadiness =
            shouldConsumeVisibleOrderSmokeReadiness
        this.shouldRequireVisibleOrderSmokeBeforeDrawableReadiness =
            shouldRequireVisibleOrderSmokeBeforeDrawableReadiness
        this.shouldRequireMetalDeviceBindingReprobeBeforeDrawable =
            shouldRequireMetalDeviceBindingReprobeBeforeDrawable
        this.shouldClassifyDrawableBlockedWhenMetalDeviceUnavailable =
            shouldClassifyDrawableBlockedWhenMetalDeviceUnavailable
        this.shouldKeepDrawableFactsIsolated = shouldKeepDrawableFactsIsolated
        this.shouldKeepDrawableRequestBlockedUntilMetalDeviceReady =
            shouldKeepDrawableRequestBlockedUntilMetalDeviceReady
        this.shouldKeepCommandQueueBlockedUntilDrawableReadiness =
            shouldKeepCommandQueueBlockedUntilDrawableReadiness
        this.shouldContinueCommandPipelineContractRoute =
            shouldContinueCommandPipelineContractRoute
        this.didConfirmVisibleOrderSmokeInput = didConfirmVisibleOrderSmokeInput
        this.didConfirmDrawableReadinessGate =
            didConfirmDrawableReadinessGate
        this.didConfirmDrawableStopLine = didConfirmDrawableStopLine
        this.didConfirmFirstFrameObservationBlocked =
            didConfirmFirstFrameObservationBlocked
        this.didConfirmProductionTruthPromotionBlocked =
            didConfirmProductionTruthPromotionBlocked
        this.didConfirmRendererStateWriteAdmissionBlocked =
            didConfirmRendererStateWriteAdmissionBlocked
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked =
            didConfirmRuntimeStateWriteBlocked
        this.didConfirmNoNativeBridgeExpansion =
            didConfirmNoNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceFacts(
    visibleOrderSmokeReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceFacts(
        visibleOrderSmokeReadiness.didPrepareVisibleOrderSmokeFirstSliceReadiness,
        visibleOrderSmokeReadiness
            .didConfirmNsApplicationWindowViewVisibleOrderMaterialized,
        true,
        true,
        visibleOrderSmokeReadiness.shouldKeepVisibleOrderFactsIsolated,
        true,
        true,
        true,
        visibleOrderSmokeReadiness.shouldKeepFirstFrameObservationBlocked,
        visibleOrderSmokeReadiness.shouldKeepProductionTruthPromotionBlocked,
        visibleOrderSmokeReadiness
            .shouldKeepRendererStateWriteAdmissionBlocked,
        visibleOrderSmokeReadiness.didConfirmRendererStateWriteBlocked,
        visibleOrderSmokeReadiness.didConfirmRuntimeStateWriteBlocked,
        visibleOrderSmokeReadiness.didConfirmNoNativeBridgeExpansion,
        visibleOrderSmokeReadiness.didConfirmNoPublicApi,
        visibleOrderSmokeReadiness.didConfirmNoProductionPublicCAbi,
        visibleOrderSmokeReadiness.didConfirmNoRuntimeStateWrite,
        visibleOrderSmokeReadiness.didConfirmNoCjpmTomlChange,
        visibleOrderSmokeReadiness.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceReadiness(
    visibleOrderSmokeReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceReadiness,
    drawableReadinessFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceReadiness {
    let drawableGateReady =
        drawableReadinessFacts.didConsumeVisibleOrderSmokeReadiness &&
        drawableReadinessFacts
            .didRequireVisibleOrderSmokeBeforeDrawableReadiness &&
        drawableReadinessFacts
            .didRequireMetalDeviceBindingReprobeBeforeDrawable &&
        drawableReadinessFacts
            .didClassifyDrawableBlockedWhenMetalDeviceUnavailable &&
        drawableReadinessFacts
            .didKeepDrawableRequestBlockedUntilMetalDeviceReady &&
        drawableReadinessFacts.didPrepareCommandPipelineContractRoute
    let drawableStopLineReady =
        drawableReadinessFacts.didKeepDrawableFactsIsolated &&
        drawableReadinessFacts.didKeepCommandQueueBlockedUntilDrawableReadiness &&
        drawableReadinessFacts.didKeepFirstFrameObservationBlocked &&
        drawableReadinessFacts.didKeepProductionTruthPromotionBlocked &&
        drawableReadinessFacts.didKeepRendererStateWriteAdmissionBlocked &&
        drawableReadinessFacts.didKeepRendererStateWriteBlocked &&
        drawableReadinessFacts.didKeepRuntimeStateWriteBlocked &&
        drawableReadinessFacts.didConfirmNoNativeBridgeExpansion &&
        drawableReadinessFacts.didConfirmNoPublicApi &&
        drawableReadinessFacts.didConfirmNoProductionPublicCAbi &&
        drawableReadinessFacts.didConfirmNoRuntimeStateWrite &&
        drawableReadinessFacts.didConfirmNoCjpmTomlChange &&
        drawableReadinessFacts.didConfirmNoRendererStateWrite

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceReadiness(
        visibleOrderSmokeReadiness,
        drawableReadinessFacts,
        drawableGateReady && drawableStopLineReady,
        drawableReadinessFacts.didConsumeVisibleOrderSmokeReadiness,
        drawableReadinessFacts
            .didRequireVisibleOrderSmokeBeforeDrawableReadiness,
        drawableReadinessFacts
            .didRequireMetalDeviceBindingReprobeBeforeDrawable,
        drawableReadinessFacts
            .didClassifyDrawableBlockedWhenMetalDeviceUnavailable,
        drawableReadinessFacts.didKeepDrawableFactsIsolated,
        drawableReadinessFacts
            .didKeepDrawableRequestBlockedUntilMetalDeviceReady,
        drawableReadinessFacts.didKeepCommandQueueBlockedUntilDrawableReadiness,
        drawableReadinessFacts.didPrepareCommandPipelineContractRoute,
        drawableReadinessFacts.didConsumeVisibleOrderSmokeReadiness,
        drawableGateReady,
        drawableStopLineReady,
        drawableReadinessFacts.didKeepFirstFrameObservationBlocked,
        drawableReadinessFacts.didKeepProductionTruthPromotionBlocked,
        drawableReadinessFacts.didKeepRendererStateWriteAdmissionBlocked,
        drawableReadinessFacts.didKeepRendererStateWriteBlocked,
        drawableReadinessFacts.didKeepRuntimeStateWriteBlocked,
        drawableReadinessFacts.didConfirmNoNativeBridgeExpansion,
        drawableReadinessFacts.didConfirmNoPublicApi,
        drawableReadinessFacts.didConfirmNoProductionPublicCAbi,
        drawableReadinessFacts.didConfirmNoRuntimeStateWrite,
        drawableReadinessFacts.didConfirmNoCjpmTomlChange,
        drawableReadinessFacts.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceReadiness {
    let visibleOrderSmokeReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceDraft()
    let drawableReadinessFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceFacts(
            visibleOrderSmokeReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceReadiness(
        visibleOrderSmokeReadiness,
        drawableReadinessFacts
    )
}
