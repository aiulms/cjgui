// 中文维护注释：本文件是 stage152 mutation request bridge after stage151
// write token gate first-slice runtime owner。
// Owner: runtime renderer internal bridge from the new write-token gate route
// to the existing renderer-state mutation request result envelope assets.
// Truth: 本阶段只绑定 mutation request source/result contract；stage151 token 未
// admitted 时不执行 mutation request，不进入 guarded executor。
// Stop-line: mutation request runtime admission、guarded executor、
// renderer_state_write 与 runtime_state_write 必须保持 false。
// Same-shape Boundary Brake: 本阶段桥接既有 mutation request shape/rejection
// evidence，下一步必须接 guarded executor bridge 或 Metal-capable rerun。
package cjgui

struct CjguiInternalRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceFacts {
    let didConsumeStage151WriteTokenGateReadiness: Bool
    let didConsumeLegacyMutationRequestResultEnvelopeReadiness: Bool
    let didRequireStage151WriteTokenGatePacket: Bool
    let didRequireLegacyMutationRequestResultEnvelope: Bool
    let didBindMutationRequestShapeToStage151WriteTokenGate: Bool
    let didBindMutationRequestRejectionToDeniedWriteToken: Bool
    let didBindRollbackEligibilityToBlockedStage151: Bool
    let didPrepareGuardedExecutorBridgeInput: Bool
    let didKeepMutationRequestBridgeSourceOnly: Bool
    let didKeepMutationRequestRuntimeAdmissionBlocked: Bool
    let didKeepGuardedStateWriteExecutorBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool

    init(
        didConsumeStage151WriteTokenGateReadiness: Bool,
        didConsumeLegacyMutationRequestResultEnvelopeReadiness: Bool,
        didRequireStage151WriteTokenGatePacket: Bool,
        didRequireLegacyMutationRequestResultEnvelope: Bool,
        didBindMutationRequestShapeToStage151WriteTokenGate: Bool,
        didBindMutationRequestRejectionToDeniedWriteToken: Bool,
        didBindRollbackEligibilityToBlockedStage151: Bool,
        didPrepareGuardedExecutorBridgeInput: Bool,
        didKeepMutationRequestBridgeSourceOnly: Bool,
        didKeepMutationRequestRuntimeAdmissionBlocked: Bool,
        didKeepGuardedStateWriteExecutorBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool
    ) {
        this.didConsumeStage151WriteTokenGateReadiness =
            didConsumeStage151WriteTokenGateReadiness
        this.didConsumeLegacyMutationRequestResultEnvelopeReadiness =
            didConsumeLegacyMutationRequestResultEnvelopeReadiness
        this.didRequireStage151WriteTokenGatePacket =
            didRequireStage151WriteTokenGatePacket
        this.didRequireLegacyMutationRequestResultEnvelope =
            didRequireLegacyMutationRequestResultEnvelope
        this.didBindMutationRequestShapeToStage151WriteTokenGate =
            didBindMutationRequestShapeToStage151WriteTokenGate
        this.didBindMutationRequestRejectionToDeniedWriteToken =
            didBindMutationRequestRejectionToDeniedWriteToken
        this.didBindRollbackEligibilityToBlockedStage151 =
            didBindRollbackEligibilityToBlockedStage151
        this.didPrepareGuardedExecutorBridgeInput =
            didPrepareGuardedExecutorBridgeInput
        this.didKeepMutationRequestBridgeSourceOnly =
            didKeepMutationRequestBridgeSourceOnly
        this.didKeepMutationRequestRuntimeAdmissionBlocked =
            didKeepMutationRequestRuntimeAdmissionBlocked
        this.didKeepGuardedStateWriteExecutorBlocked =
            didKeepGuardedStateWriteExecutorBlocked
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

struct CjguiInternalRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceReadiness {
    let writeTokenGate:
        CjguiInternalRendererStage151RendererStateWriteTokenGateAfterProductionTruthRecheckFirstSliceReadiness
    let mutationRequestResult:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateMutationRequestResultEnvelopeFirstSliceReadiness
    let mutationRequestBridgeFacts:
        CjguiInternalRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceFacts
    let didPrepareRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceReadiness:
        Bool
    let shouldConsumeStage151WriteTokenGateReadiness: Bool
    let shouldConsumeLegacyMutationRequestResultEnvelopeReadiness: Bool
    let shouldBindMutationRequestShapeToStage151WriteTokenGate: Bool
    let shouldKeepMutationRequestBridgeSourceOnly: Bool
    let didConfirmStage151WriteTokenGateInput: Bool
    let didConfirmLegacyMutationRequestResultEnvelopeInput: Bool
    let didConfirmMutationRequestBridgeReady: Bool
    let didConfirmMutationRequestBridgeSourceReady: Bool
    let didConfirmMutationRequestBridgeRuntimeAdmitted: Bool
    let didConfirmGuardedStateWriteExecutorBridgeInputPrepared: Bool
    let didConfirmGuardedStateWriteExecutorBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool

    init(
        writeTokenGate:
            CjguiInternalRendererStage151RendererStateWriteTokenGateAfterProductionTruthRecheckFirstSliceReadiness,
        mutationRequestResult:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateMutationRequestResultEnvelopeFirstSliceReadiness,
        mutationRequestBridgeFacts:
            CjguiInternalRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceFacts,
        didPrepareRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceReadiness:
            Bool,
        shouldConsumeStage151WriteTokenGateReadiness: Bool,
        shouldConsumeLegacyMutationRequestResultEnvelopeReadiness: Bool,
        shouldBindMutationRequestShapeToStage151WriteTokenGate: Bool,
        shouldKeepMutationRequestBridgeSourceOnly: Bool,
        didConfirmStage151WriteTokenGateInput: Bool,
        didConfirmLegacyMutationRequestResultEnvelopeInput: Bool,
        didConfirmMutationRequestBridgeReady: Bool,
        didConfirmMutationRequestBridgeSourceReady: Bool,
        didConfirmMutationRequestBridgeRuntimeAdmitted: Bool,
        didConfirmGuardedStateWriteExecutorBridgeInputPrepared: Bool,
        didConfirmGuardedStateWriteExecutorBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool
    ) {
        this.writeTokenGate = writeTokenGate
        this.mutationRequestResult = mutationRequestResult
        this.mutationRequestBridgeFacts = mutationRequestBridgeFacts
        this.didPrepareRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceReadiness =
            didPrepareRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceReadiness
        this.shouldConsumeStage151WriteTokenGateReadiness =
            shouldConsumeStage151WriteTokenGateReadiness
        this.shouldConsumeLegacyMutationRequestResultEnvelopeReadiness =
            shouldConsumeLegacyMutationRequestResultEnvelopeReadiness
        this.shouldBindMutationRequestShapeToStage151WriteTokenGate =
            shouldBindMutationRequestShapeToStage151WriteTokenGate
        this.shouldKeepMutationRequestBridgeSourceOnly =
            shouldKeepMutationRequestBridgeSourceOnly
        this.didConfirmStage151WriteTokenGateInput =
            didConfirmStage151WriteTokenGateInput
        this.didConfirmLegacyMutationRequestResultEnvelopeInput =
            didConfirmLegacyMutationRequestResultEnvelopeInput
        this.didConfirmMutationRequestBridgeReady =
            didConfirmMutationRequestBridgeReady
        this.didConfirmMutationRequestBridgeSourceReady =
            didConfirmMutationRequestBridgeSourceReady
        this.didConfirmMutationRequestBridgeRuntimeAdmitted =
            didConfirmMutationRequestBridgeRuntimeAdmitted
        this.didConfirmGuardedStateWriteExecutorBridgeInputPrepared =
            didConfirmGuardedStateWriteExecutorBridgeInputPrepared
        this.didConfirmGuardedStateWriteExecutorBlocked =
            didConfirmGuardedStateWriteExecutorBlocked
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

func cjguiInternalBuildRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceFacts(
    writeTokenGate:
        CjguiInternalRendererStage151RendererStateWriteTokenGateAfterProductionTruthRecheckFirstSliceReadiness,
    mutationRequestResult:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateMutationRequestResultEnvelopeFirstSliceReadiness
): CjguiInternalRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceFacts {
    return CjguiInternalRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceFacts(
        writeTokenGate
            .didPrepareRendererStage151RendererStateWriteTokenGateAfterProductionTruthRecheckFirstSliceReadiness,
        mutationRequestResult
            .didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateMutationRequestResultEnvelopeFirstSliceReadiness,
        true,
        true,
        mutationRequestResult.didConfirmMutationRequestShapePersistedAsDryRunFact,
        mutationRequestResult.didConfirmMutationRequestRejectionPersistedAsDryRunFact,
        mutationRequestResult.didConfirmRollbackEligibilityBlocked,
        mutationRequestResult.didConfirmGuardedStateWriteExecutorInputPrepared,
        true,
        true,
        true,
        writeTokenGate.didConfirmRendererStateWriteBlocked &&
            mutationRequestResult
                .didConfirmRendererStateWriteBlockedAfterMutationRequestResult,
        writeTokenGate.didConfirmRuntimeStateWriteBlocked &&
            mutationRequestResult
                .didConfirmRuntimeStateWriteBlockedAfterMutationRequestResult,
        writeTokenGate.didConfirmNoNativeBridgeExpansion &&
            mutationRequestResult.didConfirmNoNativeBridgeExpansion,
        writeTokenGate.didConfirmNoPublicApi &&
            mutationRequestResult.didConfirmNoPublicApi,
        writeTokenGate.didConfirmNoProductionPublicCAbi &&
            mutationRequestResult.didConfirmNoProductionPublicCAbi,
        writeTokenGate.didConfirmNoRuntimeStateWrite &&
            mutationRequestResult.didConfirmNoRuntimeStateWrite,
        writeTokenGate.didConfirmNoCjpmTomlChange &&
            mutationRequestResult.didConfirmNoCjpmTomlChange,
        writeTokenGate.didConfirmNoRendererStateWrite &&
            mutationRequestResult.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalBuildRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceReadiness(
    writeTokenGate:
        CjguiInternalRendererStage151RendererStateWriteTokenGateAfterProductionTruthRecheckFirstSliceReadiness,
    mutationRequestResult:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateMutationRequestResultEnvelopeFirstSliceReadiness,
    mutationRequestBridgeFacts:
        CjguiInternalRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceFacts
): CjguiInternalRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceReadiness {
    let stage151InputReady =
        mutationRequestBridgeFacts.didConsumeStage151WriteTokenGateReadiness &&
        writeTokenGate.didConfirmRendererStateWriteTokenGateReady
    let legacyInputReady =
        mutationRequestBridgeFacts
            .didConsumeLegacyMutationRequestResultEnvelopeReadiness &&
        mutationRequestResult.didConfirmMutationRequestResultEnvelopeMaterialized
    let bridgeReady =
        stage151InputReady &&
        legacyInputReady &&
        mutationRequestBridgeFacts.didBindMutationRequestShapeToStage151WriteTokenGate &&
        mutationRequestBridgeFacts.didBindMutationRequestRejectionToDeniedWriteToken &&
        mutationRequestBridgeFacts.didBindRollbackEligibilityToBlockedStage151 &&
        mutationRequestBridgeFacts.didPrepareGuardedExecutorBridgeInput &&
        mutationRequestBridgeFacts.didKeepMutationRequestBridgeSourceOnly
    let stopLineReady =
        mutationRequestBridgeFacts.didKeepMutationRequestRuntimeAdmissionBlocked &&
        mutationRequestBridgeFacts.didKeepGuardedStateWriteExecutorBlocked &&
        mutationRequestBridgeFacts.didKeepRendererStateWriteBlocked &&
        mutationRequestBridgeFacts.didKeepRuntimeStateWriteBlocked &&
        mutationRequestBridgeFacts.didConfirmNoNativeBridgeExpansion &&
        mutationRequestBridgeFacts.didConfirmNoPublicApi &&
        mutationRequestBridgeFacts.didConfirmNoProductionPublicCAbi &&
        mutationRequestBridgeFacts.didConfirmNoRuntimeStateWrite &&
        mutationRequestBridgeFacts.didConfirmNoCjpmTomlChange &&
        mutationRequestBridgeFacts.didConfirmNoRendererStateWrite

    return CjguiInternalRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceReadiness(
        writeTokenGate,
        mutationRequestResult,
        mutationRequestBridgeFacts,
        bridgeReady && stopLineReady,
        mutationRequestBridgeFacts.didConsumeStage151WriteTokenGateReadiness,
        mutationRequestBridgeFacts
            .didConsumeLegacyMutationRequestResultEnvelopeReadiness,
        mutationRequestBridgeFacts.didBindMutationRequestShapeToStage151WriteTokenGate,
        mutationRequestBridgeFacts.didKeepMutationRequestBridgeSourceOnly,
        stage151InputReady,
        legacyInputReady,
        bridgeReady,
        bridgeReady,
        false,
        mutationRequestBridgeFacts.didPrepareGuardedExecutorBridgeInput,
        mutationRequestBridgeFacts.didKeepGuardedStateWriteExecutorBlocked,
        mutationRequestBridgeFacts.didKeepRendererStateWriteBlocked,
        mutationRequestBridgeFacts.didKeepRuntimeStateWriteBlocked,
        mutationRequestBridgeFacts.didConfirmNoNativeBridgeExpansion,
        mutationRequestBridgeFacts.didConfirmNoPublicApi,
        mutationRequestBridgeFacts.didConfirmNoProductionPublicCAbi,
        mutationRequestBridgeFacts.didConfirmNoRuntimeStateWrite,
        mutationRequestBridgeFacts.didConfirmNoCjpmTomlChange,
        mutationRequestBridgeFacts.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalExecuteDefaultRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceDraft():
    CjguiInternalRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceReadiness {
    let writeTokenGate =
        cjguiInternalExecuteDefaultRendererStage151RendererStateWriteTokenGateAfterProductionTruthRecheckFirstSliceDraft()
    let mutationRequestResult =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateMutationRequestResultEnvelopeFirstSliceDraft()
    let mutationRequestBridgeFacts =
        cjguiInternalBuildRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceFacts(
            writeTokenGate,
            mutationRequestResult
        )
    return cjguiInternalBuildRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceReadiness(
        writeTokenGate,
        mutationRequestResult,
        mutationRequestBridgeFacts
    )
}
