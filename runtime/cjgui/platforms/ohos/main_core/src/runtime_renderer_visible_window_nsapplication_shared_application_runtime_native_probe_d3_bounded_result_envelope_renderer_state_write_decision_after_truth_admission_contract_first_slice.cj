// 中文维护注释：本文件是 stage144 renderer-state write decision after
// stage143 truth-admission contract first-slice runtime owner。
// Owner: runtime renderer internal renderer-state write decision envelope after
// first-frame truth-admission preflight.
// Truth: 只消费 stage143 truth-admission result envelope；本阶段只生成
// non-mutating write decision，不执行 renderer state / runtime_state.cj 写入。
// Stop-line: 缺少 production render truth、backend-ready truth 或 production
// write admission 时，renderer_state_write 必须保持 false；不扩 public API /
// public C ABI / native bridge。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceFacts {
    let didConsumeTruthAdmissionAfterFirstFrameObservationContract: Bool
    let didRequireStage143TruthAdmissionPacket: Bool
    let didRequireTruthAdmissionPreflightBeforeWriteDecision: Bool
    let didRequireProductionRenderTruthBeforeRendererStateWrite: Bool
    let didRequireBackendReadyTruthBeforeRendererStateWrite: Bool
    let didRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool
    let didRequireStateMutationRequestEnvelopeBeforeWrite: Bool
    let didKeepWriteDecisionNonMutating: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool

    init(
        didConsumeTruthAdmissionAfterFirstFrameObservationContract: Bool,
        didRequireStage143TruthAdmissionPacket: Bool,
        didRequireTruthAdmissionPreflightBeforeWriteDecision: Bool,
        didRequireProductionRenderTruthBeforeRendererStateWrite: Bool,
        didRequireBackendReadyTruthBeforeRendererStateWrite: Bool,
        didRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool,
        didRequireStateMutationRequestEnvelopeBeforeWrite: Bool,
        didKeepWriteDecisionNonMutating: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool
    ) {
        this.didConsumeTruthAdmissionAfterFirstFrameObservationContract =
            didConsumeTruthAdmissionAfterFirstFrameObservationContract
        this.didRequireStage143TruthAdmissionPacket =
            didRequireStage143TruthAdmissionPacket
        this.didRequireTruthAdmissionPreflightBeforeWriteDecision =
            didRequireTruthAdmissionPreflightBeforeWriteDecision
        this.didRequireProductionRenderTruthBeforeRendererStateWrite =
            didRequireProductionRenderTruthBeforeRendererStateWrite
        this.didRequireBackendReadyTruthBeforeRendererStateWrite =
            didRequireBackendReadyTruthBeforeRendererStateWrite
        this.didRequireProductionWriteAdmissionBeforeRendererStateWrite =
            didRequireProductionWriteAdmissionBeforeRendererStateWrite
        this.didRequireStateMutationRequestEnvelopeBeforeWrite =
            didRequireStateMutationRequestEnvelopeBeforeWrite
        this.didKeepWriteDecisionNonMutating = didKeepWriteDecisionNonMutating
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceReadiness {
    let truthAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceReadiness
    let writeDecisionFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceFacts
    let didPrepareRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceReadiness:
        Bool
    let shouldConsumeTruthAdmissionAfterFirstFrameObservationContract: Bool
    let shouldRequireStage143TruthAdmissionPacket: Bool
    let shouldRequireTruthAdmissionPreflightBeforeWriteDecision: Bool
    let shouldRequireProductionRenderTruthBeforeRendererStateWrite: Bool
    let shouldRequireBackendReadyTruthBeforeRendererStateWrite: Bool
    let shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool
    let shouldRequireStateMutationRequestEnvelopeBeforeWrite: Bool
    let shouldKeepWriteDecisionNonMutating: Bool
    let didConfirmStage143TruthAdmissionInput: Bool
    let didConfirmRendererStateWriteDecisionContract: Bool
    let didConfirmRendererStateWriteDecisionStopLine: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool

    init(
        truthAdmission:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceReadiness,
        writeDecisionFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceFacts,
        didPrepareRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceReadiness:
            Bool,
        shouldConsumeTruthAdmissionAfterFirstFrameObservationContract: Bool,
        shouldRequireStage143TruthAdmissionPacket: Bool,
        shouldRequireTruthAdmissionPreflightBeforeWriteDecision: Bool,
        shouldRequireProductionRenderTruthBeforeRendererStateWrite: Bool,
        shouldRequireBackendReadyTruthBeforeRendererStateWrite: Bool,
        shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool,
        shouldRequireStateMutationRequestEnvelopeBeforeWrite: Bool,
        shouldKeepWriteDecisionNonMutating: Bool,
        didConfirmStage143TruthAdmissionInput: Bool,
        didConfirmRendererStateWriteDecisionContract: Bool,
        didConfirmRendererStateWriteDecisionStopLine: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool
    ) {
        this.truthAdmission = truthAdmission
        this.writeDecisionFacts = writeDecisionFacts
        this.didPrepareRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceReadiness =
            didPrepareRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceReadiness
        this.shouldConsumeTruthAdmissionAfterFirstFrameObservationContract =
            shouldConsumeTruthAdmissionAfterFirstFrameObservationContract
        this.shouldRequireStage143TruthAdmissionPacket =
            shouldRequireStage143TruthAdmissionPacket
        this.shouldRequireTruthAdmissionPreflightBeforeWriteDecision =
            shouldRequireTruthAdmissionPreflightBeforeWriteDecision
        this.shouldRequireProductionRenderTruthBeforeRendererStateWrite =
            shouldRequireProductionRenderTruthBeforeRendererStateWrite
        this.shouldRequireBackendReadyTruthBeforeRendererStateWrite =
            shouldRequireBackendReadyTruthBeforeRendererStateWrite
        this.shouldRequireProductionWriteAdmissionBeforeRendererStateWrite =
            shouldRequireProductionWriteAdmissionBeforeRendererStateWrite
        this.shouldRequireStateMutationRequestEnvelopeBeforeWrite =
            shouldRequireStateMutationRequestEnvelopeBeforeWrite
        this.shouldKeepWriteDecisionNonMutating = shouldKeepWriteDecisionNonMutating
        this.didConfirmStage143TruthAdmissionInput =
            didConfirmStage143TruthAdmissionInput
        this.didConfirmRendererStateWriteDecisionContract =
            didConfirmRendererStateWriteDecisionContract
        this.didConfirmRendererStateWriteDecisionStopLine =
            didConfirmRendererStateWriteDecisionStopLine
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked = didConfirmRuntimeStateWriteBlocked
        this.didConfirmNoNativeBridgeExpansion = didConfirmNoNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi = didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceFacts(
    truthAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceFacts(
        truthAdmission
            .didPrepareTruthAdmissionAfterFirstFrameObservationContractFirstSliceReadiness,
        true,
        truthAdmission.shouldKeepTruthAdmissionPreflightOnly,
        true,
        truthAdmission.shouldRequireBackendReadyPredicateBeforeProductionTruth,
        true,
        true,
        true,
        truthAdmission.didConfirmRendererStateWriteBlocked,
        truthAdmission.didConfirmRuntimeStateWriteBlocked,
        truthAdmission.didConfirmNoNativeBridgeExpansion,
        truthAdmission.didConfirmNoPublicApi,
        truthAdmission.didConfirmNoProductionPublicCAbi,
        truthAdmission.didConfirmNoRuntimeStateWrite,
        truthAdmission.didConfirmNoCjpmTomlChange,
        truthAdmission.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceReadiness(
    truthAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceReadiness,
    writeDecisionFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceReadiness {
    let inputReady =
        writeDecisionFacts
            .didConsumeTruthAdmissionAfterFirstFrameObservationContract &&
        truthAdmission.didConfirmTruthAdmissionPredicateContract &&
        truthAdmission.didConfirmTruthAdmissionStopLine
    let decisionReady =
        writeDecisionFacts.didRequireStage143TruthAdmissionPacket &&
        writeDecisionFacts.didRequireTruthAdmissionPreflightBeforeWriteDecision &&
        writeDecisionFacts
            .didRequireProductionRenderTruthBeforeRendererStateWrite &&
        writeDecisionFacts.didRequireBackendReadyTruthBeforeRendererStateWrite &&
        writeDecisionFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite &&
        writeDecisionFacts.didRequireStateMutationRequestEnvelopeBeforeWrite &&
        writeDecisionFacts.didKeepWriteDecisionNonMutating
    let stopLineReady =
        writeDecisionFacts.didKeepRendererStateWriteBlocked &&
        writeDecisionFacts.didKeepRuntimeStateWriteBlocked &&
        writeDecisionFacts.didConfirmNoNativeBridgeExpansion &&
        writeDecisionFacts.didConfirmNoPublicApi &&
        writeDecisionFacts.didConfirmNoProductionPublicCAbi &&
        writeDecisionFacts.didConfirmNoRuntimeStateWrite &&
        writeDecisionFacts.didConfirmNoCjpmTomlChange &&
        writeDecisionFacts.didConfirmNoRendererStateWrite

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceReadiness(
        truthAdmission,
        writeDecisionFacts,
        inputReady && decisionReady && stopLineReady,
        writeDecisionFacts.didConsumeTruthAdmissionAfterFirstFrameObservationContract,
        writeDecisionFacts.didRequireStage143TruthAdmissionPacket,
        writeDecisionFacts.didRequireTruthAdmissionPreflightBeforeWriteDecision,
        writeDecisionFacts
            .didRequireProductionRenderTruthBeforeRendererStateWrite,
        writeDecisionFacts.didRequireBackendReadyTruthBeforeRendererStateWrite,
        writeDecisionFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite,
        writeDecisionFacts.didRequireStateMutationRequestEnvelopeBeforeWrite,
        writeDecisionFacts.didKeepWriteDecisionNonMutating,
        inputReady,
        decisionReady,
        stopLineReady,
        writeDecisionFacts.didKeepRendererStateWriteBlocked,
        writeDecisionFacts.didKeepRuntimeStateWriteBlocked,
        writeDecisionFacts.didConfirmNoNativeBridgeExpansion,
        writeDecisionFacts.didConfirmNoPublicApi,
        writeDecisionFacts.didConfirmNoProductionPublicCAbi,
        writeDecisionFacts.didConfirmNoRuntimeStateWrite,
        writeDecisionFacts.didConfirmNoCjpmTomlChange,
        writeDecisionFacts.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceReadiness {
    let truthAdmission =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceDraft()
    let writeDecisionFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceFacts(
            truthAdmission
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceReadiness(
        truthAdmission,
        writeDecisionFacts
    )
}
