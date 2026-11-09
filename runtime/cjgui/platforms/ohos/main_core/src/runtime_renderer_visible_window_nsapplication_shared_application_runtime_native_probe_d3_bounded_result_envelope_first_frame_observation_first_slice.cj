// 中文维护注释：本文件是 visible-window runtime native probe 的
// first-frame observation first-slice readiness owner。
// Owner: runtime renderer internal first-frame observation first slice。
// Truth: 消费 stage115 present/no-present branch readiness；只有正向
// present scheduling envelope 才能进入 bounded isolated first-frame observation。
// Stop-line: 本 owner 只允许 probe-local window capture / frame-hash summary
// envelope，不持久化 frame hash，不输出 hash 值，不做 baseline compare，
// 不写 renderer state，不把 isolated observation 升级为 production render truth，
// 也不扩 production native bridge C ABI。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceFacts {
    let didConsumePresentNoPresentBranchFirstSliceReadiness: Bool
    let didRequirePositivePresentScheduledEnvelopeBeforeFirstFrameObservation:
        Bool
    let didRequireBoundedIsolatedFirstFrameObservationProbe: Bool
    let didRequireUserVisibleWindowCaptureObservation: Bool
    let didRequireFrameHashSummary: Bool
    let didRequireNoFrameHashPersistence: Bool
    let didRequireNoFrameHashValueLogging: Bool
    let didRequireNoBaselineComparison: Bool
    let didAllowFirstFrameObservedEnvelope: Bool
    let didKeepProductionPresentBlocked: Bool
    let didKeepProductionRenderTruthBlocked: Bool
    let didRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didConfirmNoProductionTruthUpgrade: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didConfirmNoProductionNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didAvoidApprovalExternalPacketRecoveryOrReportWrapper: Bool

    init(
        didConsumePresentNoPresentBranchFirstSliceReadiness: Bool,
        didRequirePositivePresentScheduledEnvelopeBeforeFirstFrameObservation:
            Bool,
        didRequireBoundedIsolatedFirstFrameObservationProbe: Bool,
        didRequireUserVisibleWindowCaptureObservation: Bool,
        didRequireFrameHashSummary: Bool,
        didRequireNoFrameHashPersistence: Bool,
        didRequireNoFrameHashValueLogging: Bool,
        didRequireNoBaselineComparison: Bool,
        didAllowFirstFrameObservedEnvelope: Bool,
        didKeepProductionPresentBlocked: Bool,
        didKeepProductionRenderTruthBlocked: Bool,
        didRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didConfirmNoProductionTruthUpgrade: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didConfirmNoProductionNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didAvoidApprovalExternalPacketRecoveryOrReportWrapper: Bool
    ) {
        this.didConsumePresentNoPresentBranchFirstSliceReadiness =
            didConsumePresentNoPresentBranchFirstSliceReadiness
        this.didRequirePositivePresentScheduledEnvelopeBeforeFirstFrameObservation =
            didRequirePositivePresentScheduledEnvelopeBeforeFirstFrameObservation
        this.didRequireBoundedIsolatedFirstFrameObservationProbe =
            didRequireBoundedIsolatedFirstFrameObservationProbe
        this.didRequireUserVisibleWindowCaptureObservation =
            didRequireUserVisibleWindowCaptureObservation
        this.didRequireFrameHashSummary = didRequireFrameHashSummary
        this.didRequireNoFrameHashPersistence =
            didRequireNoFrameHashPersistence
        this.didRequireNoFrameHashValueLogging =
            didRequireNoFrameHashValueLogging
        this.didRequireNoBaselineComparison = didRequireNoBaselineComparison
        this.didAllowFirstFrameObservedEnvelope =
            didAllowFirstFrameObservedEnvelope
        this.didKeepProductionPresentBlocked = didKeepProductionPresentBlocked
        this.didKeepProductionRenderTruthBlocked =
            didKeepProductionRenderTruthBlocked
        this.didRequireProductionWriteAdmissionBeforeRendererStateWrite =
            didRequireProductionWriteAdmissionBeforeRendererStateWrite
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didConfirmNoProductionTruthUpgrade =
            didConfirmNoProductionTruthUpgrade
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didConfirmNoProductionNativeBridgeExpansion =
            didConfirmNoProductionNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didAvoidApprovalExternalPacketRecoveryOrReportWrapper =
            didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceReadiness {
    let presentNoPresentBranchFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceReadiness
    let firstFrameObservationFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceFacts
    let didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceReadiness:
        Bool
    let shouldConsumePresentNoPresentBranchFirstSliceReadiness: Bool
    let shouldRequirePositivePresentScheduledEnvelopeBeforeFirstFrameObservation:
        Bool
    let shouldRequireBoundedIsolatedFirstFrameObservationProbe: Bool
    let shouldRequireUserVisibleWindowCaptureObservation: Bool
    let shouldRequireFrameHashSummary: Bool
    let shouldRequireNoFrameHashPersistence: Bool
    let shouldRequireNoFrameHashValueLogging: Bool
    let shouldRequireNoBaselineComparison: Bool
    let shouldAllowFirstFrameObservedEnvelope: Bool
    let shouldKeepProductionPresentBlocked: Bool
    let shouldKeepProductionRenderTruthBlocked: Bool
    let shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool
    let shouldKeepRendererStateWriteBlocked: Bool
    let didConfirmPresentNoPresentBranchFirstSliceInput: Bool
    let didConfirmFirstFrameObservationContract: Bool
    let didConfirmFirstFrameObservationStopLine: Bool
    let didConfirmNoProductionTruthUpgrade: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didConfirmNoProductionNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didAvoidApprovalExternalPacketRecoveryOrReportWrapper: Bool

    init(
        presentNoPresentBranchFirstSliceReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceReadiness,
        firstFrameObservationFirstSliceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceFacts,
        didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceReadiness:
            Bool,
        shouldConsumePresentNoPresentBranchFirstSliceReadiness: Bool,
        shouldRequirePositivePresentScheduledEnvelopeBeforeFirstFrameObservation:
            Bool,
        shouldRequireBoundedIsolatedFirstFrameObservationProbe: Bool,
        shouldRequireUserVisibleWindowCaptureObservation: Bool,
        shouldRequireFrameHashSummary: Bool,
        shouldRequireNoFrameHashPersistence: Bool,
        shouldRequireNoFrameHashValueLogging: Bool,
        shouldRequireNoBaselineComparison: Bool,
        shouldAllowFirstFrameObservedEnvelope: Bool,
        shouldKeepProductionPresentBlocked: Bool,
        shouldKeepProductionRenderTruthBlocked: Bool,
        shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool,
        shouldKeepRendererStateWriteBlocked: Bool,
        didConfirmPresentNoPresentBranchFirstSliceInput: Bool,
        didConfirmFirstFrameObservationContract: Bool,
        didConfirmFirstFrameObservationStopLine: Bool,
        didConfirmNoProductionTruthUpgrade: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didConfirmNoProductionNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didAvoidApprovalExternalPacketRecoveryOrReportWrapper: Bool
    ) {
        this.presentNoPresentBranchFirstSliceReadiness =
            presentNoPresentBranchFirstSliceReadiness
        this.firstFrameObservationFirstSliceFacts =
            firstFrameObservationFirstSliceFacts
        this.didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceReadiness =
            didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceReadiness
        this.shouldConsumePresentNoPresentBranchFirstSliceReadiness =
            shouldConsumePresentNoPresentBranchFirstSliceReadiness
        this.shouldRequirePositivePresentScheduledEnvelopeBeforeFirstFrameObservation =
            shouldRequirePositivePresentScheduledEnvelopeBeforeFirstFrameObservation
        this.shouldRequireBoundedIsolatedFirstFrameObservationProbe =
            shouldRequireBoundedIsolatedFirstFrameObservationProbe
        this.shouldRequireUserVisibleWindowCaptureObservation =
            shouldRequireUserVisibleWindowCaptureObservation
        this.shouldRequireFrameHashSummary = shouldRequireFrameHashSummary
        this.shouldRequireNoFrameHashPersistence =
            shouldRequireNoFrameHashPersistence
        this.shouldRequireNoFrameHashValueLogging =
            shouldRequireNoFrameHashValueLogging
        this.shouldRequireNoBaselineComparison =
            shouldRequireNoBaselineComparison
        this.shouldAllowFirstFrameObservedEnvelope =
            shouldAllowFirstFrameObservedEnvelope
        this.shouldKeepProductionPresentBlocked =
            shouldKeepProductionPresentBlocked
        this.shouldKeepProductionRenderTruthBlocked =
            shouldKeepProductionRenderTruthBlocked
        this.shouldRequireProductionWriteAdmissionBeforeRendererStateWrite =
            shouldRequireProductionWriteAdmissionBeforeRendererStateWrite
        this.shouldKeepRendererStateWriteBlocked =
            shouldKeepRendererStateWriteBlocked
        this.didConfirmPresentNoPresentBranchFirstSliceInput =
            didConfirmPresentNoPresentBranchFirstSliceInput
        this.didConfirmFirstFrameObservationContract =
            didConfirmFirstFrameObservationContract
        this.didConfirmFirstFrameObservationStopLine =
            didConfirmFirstFrameObservationStopLine
        this.didConfirmNoProductionTruthUpgrade =
            didConfirmNoProductionTruthUpgrade
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didConfirmNoProductionNativeBridgeExpansion =
            didConfirmNoProductionNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didAvoidApprovalExternalPacketRecoveryOrReportWrapper =
            didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceFacts(
    presentNoPresentBranchFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceFacts(
        presentNoPresentBranchFirstSliceReadiness
            .didPrepareRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceReadiness,
        presentNoPresentBranchFirstSliceReadiness
            .shouldAllowBoundedDrawablePresentScheduledEnvelope,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        presentNoPresentBranchFirstSliceReadiness.shouldKeepProductionPresentBlocked,
        presentNoPresentBranchFirstSliceReadiness
            .shouldKeepProductionRenderTruthBlocked,
        presentNoPresentBranchFirstSliceReadiness
            .shouldRequireProductionWriteAdmissionBeforeRendererStateWrite,
        presentNoPresentBranchFirstSliceReadiness
            .shouldKeepRendererStateWriteBlocked,
        presentNoPresentBranchFirstSliceReadiness
            .didConfirmNoProductionTruthUpgrade,
        presentNoPresentBranchFirstSliceReadiness.didConfirmNoBackendReadyTruth,
        presentNoPresentBranchFirstSliceReadiness
            .didConfirmNoProductionNativeBridgeExpansion,
        presentNoPresentBranchFirstSliceReadiness.didConfirmNoPublicApi,
        presentNoPresentBranchFirstSliceReadiness
            .didConfirmNoProductionPublicCAbi,
        presentNoPresentBranchFirstSliceReadiness.didConfirmNoRuntimeStateWrite,
        presentNoPresentBranchFirstSliceReadiness.didConfirmNoCjpmTomlChange,
        presentNoPresentBranchFirstSliceReadiness.didConfirmNoRendererStateWrite,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceReadiness(
    presentNoPresentBranchFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceReadiness,
    firstFrameObservationFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceReadiness {
    let presentInputReady =
        firstFrameObservationFirstSliceFacts
            .didConsumePresentNoPresentBranchFirstSliceReadiness &&
        presentNoPresentBranchFirstSliceReadiness.didConfirmPresentBranchOrdering &&
        presentNoPresentBranchFirstSliceReadiness.didConfirmPresentBranchStopLine
    let observationContractReady =
        firstFrameObservationFirstSliceFacts
            .didRequirePositivePresentScheduledEnvelopeBeforeFirstFrameObservation &&
        firstFrameObservationFirstSliceFacts
            .didRequireBoundedIsolatedFirstFrameObservationProbe &&
        firstFrameObservationFirstSliceFacts
            .didRequireUserVisibleWindowCaptureObservation &&
        firstFrameObservationFirstSliceFacts.didRequireFrameHashSummary &&
        firstFrameObservationFirstSliceFacts.didRequireNoFrameHashPersistence &&
        firstFrameObservationFirstSliceFacts.didRequireNoFrameHashValueLogging &&
        firstFrameObservationFirstSliceFacts.didRequireNoBaselineComparison &&
        firstFrameObservationFirstSliceFacts.didAllowFirstFrameObservedEnvelope
    let stopLineReady =
        firstFrameObservationFirstSliceFacts.didKeepProductionPresentBlocked &&
        firstFrameObservationFirstSliceFacts
            .didKeepProductionRenderTruthBlocked &&
        firstFrameObservationFirstSliceFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite &&
        firstFrameObservationFirstSliceFacts.didKeepRendererStateWriteBlocked &&
        firstFrameObservationFirstSliceFacts.didConfirmNoProductionTruthUpgrade &&
        firstFrameObservationFirstSliceFacts.didConfirmNoBackendReadyTruth &&
        firstFrameObservationFirstSliceFacts
            .didConfirmNoProductionNativeBridgeExpansion &&
        firstFrameObservationFirstSliceFacts.didConfirmNoPublicApi &&
        firstFrameObservationFirstSliceFacts.didConfirmNoProductionPublicCAbi &&
        firstFrameObservationFirstSliceFacts.didConfirmNoRuntimeStateWrite &&
        firstFrameObservationFirstSliceFacts.didConfirmNoCjpmTomlChange &&
        firstFrameObservationFirstSliceFacts.didConfirmNoRendererStateWrite &&
        firstFrameObservationFirstSliceFacts
            .didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    let readinessReady =
        presentInputReady && observationContractReady && stopLineReady

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceReadiness(
        presentNoPresentBranchFirstSliceReadiness,
        firstFrameObservationFirstSliceFacts,
        readinessReady,
        firstFrameObservationFirstSliceFacts
            .didConsumePresentNoPresentBranchFirstSliceReadiness,
        firstFrameObservationFirstSliceFacts
            .didRequirePositivePresentScheduledEnvelopeBeforeFirstFrameObservation,
        firstFrameObservationFirstSliceFacts
            .didRequireBoundedIsolatedFirstFrameObservationProbe,
        firstFrameObservationFirstSliceFacts
            .didRequireUserVisibleWindowCaptureObservation,
        firstFrameObservationFirstSliceFacts.didRequireFrameHashSummary,
        firstFrameObservationFirstSliceFacts.didRequireNoFrameHashPersistence,
        firstFrameObservationFirstSliceFacts.didRequireNoFrameHashValueLogging,
        firstFrameObservationFirstSliceFacts.didRequireNoBaselineComparison,
        firstFrameObservationFirstSliceFacts.didAllowFirstFrameObservedEnvelope,
        firstFrameObservationFirstSliceFacts.didKeepProductionPresentBlocked,
        firstFrameObservationFirstSliceFacts
            .didKeepProductionRenderTruthBlocked,
        firstFrameObservationFirstSliceFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite,
        firstFrameObservationFirstSliceFacts.didKeepRendererStateWriteBlocked,
        presentInputReady,
        observationContractReady,
        stopLineReady,
        firstFrameObservationFirstSliceFacts
            .didConfirmNoProductionTruthUpgrade,
        firstFrameObservationFirstSliceFacts.didConfirmNoBackendReadyTruth,
        firstFrameObservationFirstSliceFacts
            .didConfirmNoProductionNativeBridgeExpansion,
        firstFrameObservationFirstSliceFacts.didConfirmNoPublicApi,
        firstFrameObservationFirstSliceFacts.didConfirmNoProductionPublicCAbi,
        firstFrameObservationFirstSliceFacts.didConfirmNoRuntimeStateWrite,
        firstFrameObservationFirstSliceFacts.didConfirmNoCjpmTomlChange,
        firstFrameObservationFirstSliceFacts.didConfirmNoRendererStateWrite,
        firstFrameObservationFirstSliceFacts
            .didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceReadiness {
    let presentNoPresentBranchFirstSliceReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceDraft()
    let firstFrameObservationFirstSliceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceFacts(
            presentNoPresentBranchFirstSliceReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceReadiness(
        presentNoPresentBranchFirstSliceReadiness,
        firstFrameObservationFirstSliceFacts
    )
}
