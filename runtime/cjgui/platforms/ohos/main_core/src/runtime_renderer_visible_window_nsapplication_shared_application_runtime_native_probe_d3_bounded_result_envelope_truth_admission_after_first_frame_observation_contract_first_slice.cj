// 中文维护注释：本文件是 stage143 truth admission after stage142
// first-frame observation contract first-slice runtime owner。
// Owner: runtime renderer internal truth-admission contract after probe-local
// first-frame observation envelope.
// Truth: 只消费 stage142 first-frame result envelope；即使 isolated first-frame
// observation 正向成立，也只能进入 truth-admission preflight，不升级 production
// render truth，不写 renderer state / runtime_state.cj。
// Stop-line: 本 owner 不执行 native runtime，不持久化 frame hash，不做真实
// production truth promotion，不扩 public API / public C ABI / native bridge。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceFacts {
    let didConsumeFirstFrameObservationAfterPresentSchedulingContract: Bool
    let didRequireStage142FirstFramePacket: Bool
    let didRequirePositiveFirstFrameBeforeTruthAdmission: Bool
    let didRequireFrameHashComputed: Bool
    let didRequireFrameHashNonzero: Bool
    let didRequireFrameHashValueRedacted: Bool
    let didRequireNoFrameHashPersistence: Bool
    let didRequireBaselineOrSemanticVerificationBeforeProductionTruth: Bool
    let didRequireBackendReadyPredicateBeforeProductionTruth: Bool
    let didKeepTruthAdmissionPreflightOnly: Bool
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
        didConsumeFirstFrameObservationAfterPresentSchedulingContract: Bool,
        didRequireStage142FirstFramePacket: Bool,
        didRequirePositiveFirstFrameBeforeTruthAdmission: Bool,
        didRequireFrameHashComputed: Bool,
        didRequireFrameHashNonzero: Bool,
        didRequireFrameHashValueRedacted: Bool,
        didRequireNoFrameHashPersistence: Bool,
        didRequireBaselineOrSemanticVerificationBeforeProductionTruth: Bool,
        didRequireBackendReadyPredicateBeforeProductionTruth: Bool,
        didKeepTruthAdmissionPreflightOnly: Bool,
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
        this.didConsumeFirstFrameObservationAfterPresentSchedulingContract =
            didConsumeFirstFrameObservationAfterPresentSchedulingContract
        this.didRequireStage142FirstFramePacket =
            didRequireStage142FirstFramePacket
        this.didRequirePositiveFirstFrameBeforeTruthAdmission =
            didRequirePositiveFirstFrameBeforeTruthAdmission
        this.didRequireFrameHashComputed = didRequireFrameHashComputed
        this.didRequireFrameHashNonzero = didRequireFrameHashNonzero
        this.didRequireFrameHashValueRedacted = didRequireFrameHashValueRedacted
        this.didRequireNoFrameHashPersistence = didRequireNoFrameHashPersistence
        this.didRequireBaselineOrSemanticVerificationBeforeProductionTruth =
            didRequireBaselineOrSemanticVerificationBeforeProductionTruth
        this.didRequireBackendReadyPredicateBeforeProductionTruth =
            didRequireBackendReadyPredicateBeforeProductionTruth
        this.didKeepTruthAdmissionPreflightOnly =
            didKeepTruthAdmissionPreflightOnly
        this.didKeepProductionTruthPromotionBlocked =
            didKeepProductionTruthPromotionBlocked
        this.didKeepRendererStateWriteAdmissionBlocked =
            didKeepRendererStateWriteAdmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didConfirmNoNativeBridgeExpansion = didConfirmNoNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi = didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceReadiness {
    let firstFrame:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationAfterPresentSchedulingContractFirstSliceReadiness
    let truthAdmissionFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceFacts
    let didPrepareTruthAdmissionAfterFirstFrameObservationContractFirstSliceReadiness:
        Bool
    let shouldConsumeFirstFrameObservationAfterPresentSchedulingContract: Bool
    let shouldRequireStage142FirstFramePacket: Bool
    let shouldRequirePositiveFirstFrameBeforeTruthAdmission: Bool
    let shouldRequireFrameHashComputed: Bool
    let shouldRequireFrameHashNonzero: Bool
    let shouldRequireFrameHashValueRedacted: Bool
    let shouldRequireNoFrameHashPersistence: Bool
    let shouldRequireBaselineOrSemanticVerificationBeforeProductionTruth: Bool
    let shouldRequireBackendReadyPredicateBeforeProductionTruth: Bool
    let shouldKeepTruthAdmissionPreflightOnly: Bool
    let didConfirmStage142FirstFrameInput: Bool
    let didConfirmTruthAdmissionPredicateContract: Bool
    let didConfirmTruthAdmissionStopLine: Bool
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
        firstFrame:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationAfterPresentSchedulingContractFirstSliceReadiness,
        truthAdmissionFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceFacts,
        didPrepareTruthAdmissionAfterFirstFrameObservationContractFirstSliceReadiness:
            Bool,
        shouldConsumeFirstFrameObservationAfterPresentSchedulingContract: Bool,
        shouldRequireStage142FirstFramePacket: Bool,
        shouldRequirePositiveFirstFrameBeforeTruthAdmission: Bool,
        shouldRequireFrameHashComputed: Bool,
        shouldRequireFrameHashNonzero: Bool,
        shouldRequireFrameHashValueRedacted: Bool,
        shouldRequireNoFrameHashPersistence: Bool,
        shouldRequireBaselineOrSemanticVerificationBeforeProductionTruth: Bool,
        shouldRequireBackendReadyPredicateBeforeProductionTruth: Bool,
        shouldKeepTruthAdmissionPreflightOnly: Bool,
        didConfirmStage142FirstFrameInput: Bool,
        didConfirmTruthAdmissionPredicateContract: Bool,
        didConfirmTruthAdmissionStopLine: Bool,
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
        this.firstFrame = firstFrame
        this.truthAdmissionFacts = truthAdmissionFacts
        this.didPrepareTruthAdmissionAfterFirstFrameObservationContractFirstSliceReadiness =
            didPrepareTruthAdmissionAfterFirstFrameObservationContractFirstSliceReadiness
        this.shouldConsumeFirstFrameObservationAfterPresentSchedulingContract =
            shouldConsumeFirstFrameObservationAfterPresentSchedulingContract
        this.shouldRequireStage142FirstFramePacket =
            shouldRequireStage142FirstFramePacket
        this.shouldRequirePositiveFirstFrameBeforeTruthAdmission =
            shouldRequirePositiveFirstFrameBeforeTruthAdmission
        this.shouldRequireFrameHashComputed = shouldRequireFrameHashComputed
        this.shouldRequireFrameHashNonzero = shouldRequireFrameHashNonzero
        this.shouldRequireFrameHashValueRedacted =
            shouldRequireFrameHashValueRedacted
        this.shouldRequireNoFrameHashPersistence =
            shouldRequireNoFrameHashPersistence
        this.shouldRequireBaselineOrSemanticVerificationBeforeProductionTruth =
            shouldRequireBaselineOrSemanticVerificationBeforeProductionTruth
        this.shouldRequireBackendReadyPredicateBeforeProductionTruth =
            shouldRequireBackendReadyPredicateBeforeProductionTruth
        this.shouldKeepTruthAdmissionPreflightOnly =
            shouldKeepTruthAdmissionPreflightOnly
        this.didConfirmStage142FirstFrameInput = didConfirmStage142FirstFrameInput
        this.didConfirmTruthAdmissionPredicateContract =
            didConfirmTruthAdmissionPredicateContract
        this.didConfirmTruthAdmissionStopLine = didConfirmTruthAdmissionStopLine
        this.didConfirmProductionTruthPromotionBlocked =
            didConfirmProductionTruthPromotionBlocked
        this.didConfirmRendererStateWriteAdmissionBlocked =
            didConfirmRendererStateWriteAdmissionBlocked
        this.didConfirmRendererStateWriteBlocked = didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked = didConfirmRuntimeStateWriteBlocked
        this.didConfirmNoNativeBridgeExpansion = didConfirmNoNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi = didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceFacts(
    firstFrame:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationAfterPresentSchedulingContractFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceFacts(
        firstFrame
            .didPrepareFirstFrameObservationAfterPresentSchedulingContractFirstSliceReadiness,
        true,
        firstFrame.shouldAllowFirstFrameObservedEnvelope,
        firstFrame.shouldRequireFrameHashSummary,
        firstFrame.shouldRequireFrameHashSummary,
        firstFrame.shouldRequireNoFrameHashValueLogging,
        firstFrame.shouldRequireNoFrameHashPersistence,
        true,
        true,
        true,
        firstFrame.didConfirmProductionTruthPromotionBlocked,
        firstFrame.didConfirmRendererStateWriteAdmissionBlocked,
        firstFrame.didConfirmRendererStateWriteBlocked,
        firstFrame.didConfirmRuntimeStateWriteBlocked,
        firstFrame.didConfirmNoNativeBridgeExpansion,
        firstFrame.didConfirmNoPublicApi,
        firstFrame.didConfirmNoProductionPublicCAbi,
        firstFrame.didConfirmNoRuntimeStateWrite,
        firstFrame.didConfirmNoCjpmTomlChange,
        firstFrame.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceReadiness(
    firstFrame:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationAfterPresentSchedulingContractFirstSliceReadiness,
    truthAdmissionFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceReadiness {
    let inputReady =
        truthAdmissionFacts
            .didConsumeFirstFrameObservationAfterPresentSchedulingContract &&
        firstFrame.didConfirmFirstFrameObservationContract &&
        firstFrame.didConfirmFirstFrameObservationStopLine
    let predicateReady =
        truthAdmissionFacts.didRequireStage142FirstFramePacket &&
        truthAdmissionFacts.didRequirePositiveFirstFrameBeforeTruthAdmission &&
        truthAdmissionFacts.didRequireFrameHashComputed &&
        truthAdmissionFacts.didRequireFrameHashNonzero &&
        truthAdmissionFacts.didRequireFrameHashValueRedacted &&
        truthAdmissionFacts.didRequireNoFrameHashPersistence &&
        truthAdmissionFacts
            .didRequireBaselineOrSemanticVerificationBeforeProductionTruth &&
        truthAdmissionFacts.didRequireBackendReadyPredicateBeforeProductionTruth &&
        truthAdmissionFacts.didKeepTruthAdmissionPreflightOnly
    let stopLineReady =
        truthAdmissionFacts.didKeepProductionTruthPromotionBlocked &&
        truthAdmissionFacts.didKeepRendererStateWriteAdmissionBlocked &&
        truthAdmissionFacts.didKeepRendererStateWriteBlocked &&
        truthAdmissionFacts.didKeepRuntimeStateWriteBlocked &&
        truthAdmissionFacts.didConfirmNoNativeBridgeExpansion &&
        truthAdmissionFacts.didConfirmNoPublicApi &&
        truthAdmissionFacts.didConfirmNoProductionPublicCAbi &&
        truthAdmissionFacts.didConfirmNoRuntimeStateWrite &&
        truthAdmissionFacts.didConfirmNoCjpmTomlChange &&
        truthAdmissionFacts.didConfirmNoRendererStateWrite

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceReadiness(
        firstFrame,
        truthAdmissionFacts,
        inputReady && predicateReady && stopLineReady,
        truthAdmissionFacts.didConsumeFirstFrameObservationAfterPresentSchedulingContract,
        truthAdmissionFacts.didRequireStage142FirstFramePacket,
        truthAdmissionFacts.didRequirePositiveFirstFrameBeforeTruthAdmission,
        truthAdmissionFacts.didRequireFrameHashComputed,
        truthAdmissionFacts.didRequireFrameHashNonzero,
        truthAdmissionFacts.didRequireFrameHashValueRedacted,
        truthAdmissionFacts.didRequireNoFrameHashPersistence,
        truthAdmissionFacts
            .didRequireBaselineOrSemanticVerificationBeforeProductionTruth,
        truthAdmissionFacts.didRequireBackendReadyPredicateBeforeProductionTruth,
        truthAdmissionFacts.didKeepTruthAdmissionPreflightOnly,
        inputReady,
        predicateReady,
        stopLineReady,
        truthAdmissionFacts.didKeepProductionTruthPromotionBlocked,
        truthAdmissionFacts.didKeepRendererStateWriteAdmissionBlocked,
        truthAdmissionFacts.didKeepRendererStateWriteBlocked,
        truthAdmissionFacts.didKeepRuntimeStateWriteBlocked,
        truthAdmissionFacts.didConfirmNoNativeBridgeExpansion,
        truthAdmissionFacts.didConfirmNoPublicApi,
        truthAdmissionFacts.didConfirmNoProductionPublicCAbi,
        truthAdmissionFacts.didConfirmNoRuntimeStateWrite,
        truthAdmissionFacts.didConfirmNoCjpmTomlChange,
        truthAdmissionFacts.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceReadiness {
    let firstFrame =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationAfterPresentSchedulingContractFirstSliceDraft()
    let truthAdmissionFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceFacts(
            firstFrame
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceReadiness(
        firstFrame,
        truthAdmissionFacts
    )
}
