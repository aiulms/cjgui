// 中文维护注释：本文件是 stage134 bounded visible-order smoke first-slice
// runtime owner。
// Owner: runtime renderer internal AppKit visible-order smoke readiness。
// Truth: 消费 stage133 renderer-state write token gate recheck 后，只允许把
// fresh bounded AppKit visible-order smoke 作为 isolated result envelope 输入；
// 它证明 NSApplication / NSWindow / NSView / visible-order / auto-close cleanup
// 链路可以单独观测，不要求 Metal device，也不提升 first-frame 或 production truth。
// Stop-line: 不调用 native AppKit/Metal，不获取 drawable，不创建 encoder/draw/commit/
// present，不写 renderer state / runtime_state.cj，不扩 public API / public C ABI /
// native bridge。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceFacts {
    let didConsumeRendererStateWriteTokenGateRecheck: Bool
    let didRequireFreshBoundedVisibleOrderSmokeProbe: Bool
    let didMaterializeNsApplicationWindowViewVisibleOrder: Bool
    let didRequireAutoCloseCleanupBeforeDrawableRoute: Bool
    let didKeepVisibleOrderFactsIsolated: Bool
    let didKeepMetalDeviceRequirementOutOfVisibleOrderSmoke: Bool
    let didConfirmNoMetalDrawableEncoderDrawCommitPresent: Bool
    let didKeepFirstFrameObservationBlocked: Bool
    let didKeepProductionTruthPromotionBlocked: Bool
    let didKeepRendererStateWriteAdmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didPrepareDrawableReadinessReprobeRoute: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool

    init(
        didConsumeRendererStateWriteTokenGateRecheck: Bool,
        didRequireFreshBoundedVisibleOrderSmokeProbe: Bool,
        didMaterializeNsApplicationWindowViewVisibleOrder: Bool,
        didRequireAutoCloseCleanupBeforeDrawableRoute: Bool,
        didKeepVisibleOrderFactsIsolated: Bool,
        didKeepMetalDeviceRequirementOutOfVisibleOrderSmoke: Bool,
        didConfirmNoMetalDrawableEncoderDrawCommitPresent: Bool,
        didKeepFirstFrameObservationBlocked: Bool,
        didKeepProductionTruthPromotionBlocked: Bool,
        didKeepRendererStateWriteAdmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didPrepareDrawableReadinessReprobeRoute: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool
    ) {
        this.didConsumeRendererStateWriteTokenGateRecheck =
            didConsumeRendererStateWriteTokenGateRecheck
        this.didRequireFreshBoundedVisibleOrderSmokeProbe =
            didRequireFreshBoundedVisibleOrderSmokeProbe
        this.didMaterializeNsApplicationWindowViewVisibleOrder =
            didMaterializeNsApplicationWindowViewVisibleOrder
        this.didRequireAutoCloseCleanupBeforeDrawableRoute =
            didRequireAutoCloseCleanupBeforeDrawableRoute
        this.didKeepVisibleOrderFactsIsolated =
            didKeepVisibleOrderFactsIsolated
        this.didKeepMetalDeviceRequirementOutOfVisibleOrderSmoke =
            didKeepMetalDeviceRequirementOutOfVisibleOrderSmoke
        this.didConfirmNoMetalDrawableEncoderDrawCommitPresent =
            didConfirmNoMetalDrawableEncoderDrawCommitPresent
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
        this.didPrepareDrawableReadinessReprobeRoute =
            didPrepareDrawableReadinessReprobeRoute
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceReadiness {
    let visibleOrderSmokeFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceFacts
    let didPrepareVisibleOrderSmokeFirstSliceReadiness: Bool
    let shouldPublishVisibleOrderSmokeResultEnvelope: Bool
    let shouldKeepVisibleOrderFactsIsolated: Bool
    let shouldKeepFirstFrameObservationBlocked: Bool
    let shouldKeepProductionTruthPromotionBlocked: Bool
    let shouldKeepRendererStateWriteAdmissionBlocked: Bool
    let shouldContinueDrawableReadinessReprobeRoute: Bool
    let didConfirmRendererStateWriteTokenGateRecheckConsumed: Bool
    let didConfirmFreshBoundedVisibleOrderSmokeProbeRequired: Bool
    let didConfirmNsApplicationWindowViewVisibleOrderMaterialized: Bool
    let didConfirmAutoCloseCleanupBeforeDrawableRoute: Bool
    let didConfirmMetalDeviceNotRequiredForVisibleOrderSmoke: Bool
    let didConfirmNoMetalDrawableEncoderDrawCommitPresent: Bool
    let didConfirmFirstFrameObservationBlocked: Bool
    let didConfirmProductionTruthPromotionBlocked: Bool
    let didConfirmRendererStateWriteAdmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmDrawableReadinessReprobeRoutePrepared: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool

    init(
        visibleOrderSmokeFirstSliceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceFacts,
        didPrepareVisibleOrderSmokeFirstSliceReadiness: Bool,
        shouldPublishVisibleOrderSmokeResultEnvelope: Bool,
        shouldKeepVisibleOrderFactsIsolated: Bool,
        shouldKeepFirstFrameObservationBlocked: Bool,
        shouldKeepProductionTruthPromotionBlocked: Bool,
        shouldKeepRendererStateWriteAdmissionBlocked: Bool,
        shouldContinueDrawableReadinessReprobeRoute: Bool,
        didConfirmRendererStateWriteTokenGateRecheckConsumed: Bool,
        didConfirmFreshBoundedVisibleOrderSmokeProbeRequired: Bool,
        didConfirmNsApplicationWindowViewVisibleOrderMaterialized: Bool,
        didConfirmAutoCloseCleanupBeforeDrawableRoute: Bool,
        didConfirmMetalDeviceNotRequiredForVisibleOrderSmoke: Bool,
        didConfirmNoMetalDrawableEncoderDrawCommitPresent: Bool,
        didConfirmFirstFrameObservationBlocked: Bool,
        didConfirmProductionTruthPromotionBlocked: Bool,
        didConfirmRendererStateWriteAdmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmDrawableReadinessReprobeRoutePrepared: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool
    ) {
        this.visibleOrderSmokeFirstSliceFacts =
            visibleOrderSmokeFirstSliceFacts
        this.didPrepareVisibleOrderSmokeFirstSliceReadiness =
            didPrepareVisibleOrderSmokeFirstSliceReadiness
        this.shouldPublishVisibleOrderSmokeResultEnvelope =
            shouldPublishVisibleOrderSmokeResultEnvelope
        this.shouldKeepVisibleOrderFactsIsolated =
            shouldKeepVisibleOrderFactsIsolated
        this.shouldKeepFirstFrameObservationBlocked =
            shouldKeepFirstFrameObservationBlocked
        this.shouldKeepProductionTruthPromotionBlocked =
            shouldKeepProductionTruthPromotionBlocked
        this.shouldKeepRendererStateWriteAdmissionBlocked =
            shouldKeepRendererStateWriteAdmissionBlocked
        this.shouldContinueDrawableReadinessReprobeRoute =
            shouldContinueDrawableReadinessReprobeRoute
        this.didConfirmRendererStateWriteTokenGateRecheckConsumed =
            didConfirmRendererStateWriteTokenGateRecheckConsumed
        this.didConfirmFreshBoundedVisibleOrderSmokeProbeRequired =
            didConfirmFreshBoundedVisibleOrderSmokeProbeRequired
        this.didConfirmNsApplicationWindowViewVisibleOrderMaterialized =
            didConfirmNsApplicationWindowViewVisibleOrderMaterialized
        this.didConfirmAutoCloseCleanupBeforeDrawableRoute =
            didConfirmAutoCloseCleanupBeforeDrawableRoute
        this.didConfirmMetalDeviceNotRequiredForVisibleOrderSmoke =
            didConfirmMetalDeviceNotRequiredForVisibleOrderSmoke
        this.didConfirmNoMetalDrawableEncoderDrawCommitPresent =
            didConfirmNoMetalDrawableEncoderDrawCommitPresent
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
        this.didConfirmDrawableReadinessReprobeRoutePrepared =
            didConfirmDrawableReadinessReprobeRoutePrepared
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

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceFacts(
    rendererStateWriteTokenGateRecheckFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialRendererStateWriteTokenGateRecheckFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceFacts(
        rendererStateWriteTokenGateRecheckFirstSliceReadiness
            .didPrepareRendererStateWriteTokenGateRecheckFirstSliceReadiness,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        rendererStateWriteTokenGateRecheckFirstSliceReadiness
            .didConfirmRendererStateWriteAdmissionBlocked,
        rendererStateWriteTokenGateRecheckFirstSliceReadiness
            .didConfirmRendererStateWriteBlocked,
        rendererStateWriteTokenGateRecheckFirstSliceReadiness
            .didConfirmRuntimeStateWriteBlocked,
        true,
        rendererStateWriteTokenGateRecheckFirstSliceReadiness
            .didConfirmNoNativeBridgeExpansion,
        rendererStateWriteTokenGateRecheckFirstSliceReadiness.didConfirmNoPublicApi,
        rendererStateWriteTokenGateRecheckFirstSliceReadiness
            .didConfirmNoProductionPublicCAbi,
        rendererStateWriteTokenGateRecheckFirstSliceReadiness
            .didConfirmNoRuntimeStateWrite,
        rendererStateWriteTokenGateRecheckFirstSliceReadiness.didConfirmNoCjpmTomlChange,
        rendererStateWriteTokenGateRecheckFirstSliceReadiness
            .didConfirmNoRendererStateWrite
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceReadiness(
    visibleOrderSmokeFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceReadiness {
    let visibleOrderSmokeReady =
        visibleOrderSmokeFirstSliceFacts
            .didConsumeRendererStateWriteTokenGateRecheck &&
        visibleOrderSmokeFirstSliceFacts
            .didRequireFreshBoundedVisibleOrderSmokeProbe &&
        visibleOrderSmokeFirstSliceFacts
            .didMaterializeNsApplicationWindowViewVisibleOrder &&
        visibleOrderSmokeFirstSliceFacts
            .didRequireAutoCloseCleanupBeforeDrawableRoute &&
        visibleOrderSmokeFirstSliceFacts
            .didKeepVisibleOrderFactsIsolated &&
        visibleOrderSmokeFirstSliceFacts
            .didPrepareDrawableReadinessReprobeRoute

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceReadiness(
        visibleOrderSmokeFirstSliceFacts,
        visibleOrderSmokeReady,
        visibleOrderSmokeReady,
        visibleOrderSmokeFirstSliceFacts.didKeepVisibleOrderFactsIsolated,
        visibleOrderSmokeFirstSliceFacts.didKeepFirstFrameObservationBlocked,
        visibleOrderSmokeFirstSliceFacts.didKeepProductionTruthPromotionBlocked,
        visibleOrderSmokeFirstSliceFacts
            .didKeepRendererStateWriteAdmissionBlocked,
        visibleOrderSmokeFirstSliceFacts.didPrepareDrawableReadinessReprobeRoute,
        visibleOrderSmokeFirstSliceFacts
            .didConsumeRendererStateWriteTokenGateRecheck,
        visibleOrderSmokeFirstSliceFacts
            .didRequireFreshBoundedVisibleOrderSmokeProbe,
        visibleOrderSmokeFirstSliceFacts
            .didMaterializeNsApplicationWindowViewVisibleOrder,
        visibleOrderSmokeFirstSliceFacts
            .didRequireAutoCloseCleanupBeforeDrawableRoute,
        visibleOrderSmokeFirstSliceFacts
            .didKeepMetalDeviceRequirementOutOfVisibleOrderSmoke,
        visibleOrderSmokeFirstSliceFacts
            .didConfirmNoMetalDrawableEncoderDrawCommitPresent,
        visibleOrderSmokeFirstSliceFacts.didKeepFirstFrameObservationBlocked,
        visibleOrderSmokeFirstSliceFacts.didKeepProductionTruthPromotionBlocked,
        visibleOrderSmokeFirstSliceFacts
            .didKeepRendererStateWriteAdmissionBlocked,
        visibleOrderSmokeFirstSliceFacts.didKeepRendererStateWriteBlocked,
        visibleOrderSmokeFirstSliceFacts.didKeepRuntimeStateWriteBlocked,
        visibleOrderSmokeFirstSliceFacts.didPrepareDrawableReadinessReprobeRoute,
        visibleOrderSmokeFirstSliceFacts.didConfirmNoNativeBridgeExpansion,
        visibleOrderSmokeFirstSliceFacts.didConfirmNoPublicApi,
        visibleOrderSmokeFirstSliceFacts.didConfirmNoProductionPublicCAbi,
        visibleOrderSmokeFirstSliceFacts.didConfirmNoRuntimeStateWrite,
        visibleOrderSmokeFirstSliceFacts.didConfirmNoCjpmTomlChange,
        visibleOrderSmokeFirstSliceFacts.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceReadiness {
    let rendererStateWriteTokenGateRecheckFirstSliceReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialRendererStateWriteTokenGateRecheckFirstSliceDraft()
    let visibleOrderSmokeFirstSliceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceFacts(
            rendererStateWriteTokenGateRecheckFirstSliceReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceReadiness(
        visibleOrderSmokeFirstSliceFacts
    )
}
