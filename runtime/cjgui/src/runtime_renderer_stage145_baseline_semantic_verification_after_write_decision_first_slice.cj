// 中文维护注释：本文件是 stage145 baseline / semantic verification after
// stage144 renderer-state write decision first-slice runtime owner。
// Owner: runtime renderer internal baseline / semantic verification contract
// after truth-admission write decision envelope.
// Truth: 只消费 stage144 write decision readiness；本阶段只声明 baseline /
// semantic verification 的非变更输入与阻断条件，不比较真实 baseline，不升级
// production render truth，不写 renderer state / runtime_state.cj。
// Stop-line: 缺少正向 first-frame / nonzero frame hash / baseline fixture 或
// semantic comparator 时，production truth 与 renderer_state_write 必须保持 false。
// Same-shape Boundary Brake: 不再新增同构 no-write wrapper；下一步必须接入
// baseline fixture / semantic comparator 物化或 Metal-capable rerun evidence。
package cjgui

struct CjguiInternalRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceFacts {
    let didConsumeWriteDecisionAfterTruthAdmissionContract: Bool
    let didRequireStage144WriteDecisionPacket: Bool
    let didRequireTruthAdmissionPreflightBeforeBaselineSemantic: Bool
    let didRequirePositiveFirstFrameBeforeBaselineSemantic: Bool
    let didRequireFrameHashNonzeroBeforeBaselineSemantic: Bool
    let didRequireBaselineFixtureOrSemanticComparator: Bool
    let didKeepBaselineComparisonNonMutating: Bool
    let didKeepSemanticAcceptancePreProduction: Bool
    let didKeepProductionTruthPromotionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool

    init(
        didConsumeWriteDecisionAfterTruthAdmissionContract: Bool,
        didRequireStage144WriteDecisionPacket: Bool,
        didRequireTruthAdmissionPreflightBeforeBaselineSemantic: Bool,
        didRequirePositiveFirstFrameBeforeBaselineSemantic: Bool,
        didRequireFrameHashNonzeroBeforeBaselineSemantic: Bool,
        didRequireBaselineFixtureOrSemanticComparator: Bool,
        didKeepBaselineComparisonNonMutating: Bool,
        didKeepSemanticAcceptancePreProduction: Bool,
        didKeepProductionTruthPromotionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool
    ) {
        this.didConsumeWriteDecisionAfterTruthAdmissionContract =
            didConsumeWriteDecisionAfterTruthAdmissionContract
        this.didRequireStage144WriteDecisionPacket =
            didRequireStage144WriteDecisionPacket
        this.didRequireTruthAdmissionPreflightBeforeBaselineSemantic =
            didRequireTruthAdmissionPreflightBeforeBaselineSemantic
        this.didRequirePositiveFirstFrameBeforeBaselineSemantic =
            didRequirePositiveFirstFrameBeforeBaselineSemantic
        this.didRequireFrameHashNonzeroBeforeBaselineSemantic =
            didRequireFrameHashNonzeroBeforeBaselineSemantic
        this.didRequireBaselineFixtureOrSemanticComparator =
            didRequireBaselineFixtureOrSemanticComparator
        this.didKeepBaselineComparisonNonMutating =
            didKeepBaselineComparisonNonMutating
        this.didKeepSemanticAcceptancePreProduction =
            didKeepSemanticAcceptancePreProduction
        this.didKeepProductionTruthPromotionBlocked =
            didKeepProductionTruthPromotionBlocked
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

struct CjguiInternalRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceReadiness {
    let writeDecision:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceReadiness
    let baselineSemanticFacts:
        CjguiInternalRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceFacts
    let didPrepareRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceReadiness:
        Bool
    let shouldConsumeWriteDecisionAfterTruthAdmissionContract: Bool
    let shouldRequireStage144WriteDecisionPacket: Bool
    let shouldRequireTruthAdmissionPreflightBeforeBaselineSemantic: Bool
    let shouldRequirePositiveFirstFrameBeforeBaselineSemantic: Bool
    let shouldRequireFrameHashNonzeroBeforeBaselineSemantic: Bool
    let shouldRequireBaselineFixtureOrSemanticComparator: Bool
    let shouldKeepBaselineComparisonNonMutating: Bool
    let didConfirmStage144WriteDecisionInput: Bool
    let didConfirmBaselineSemanticVerificationContract: Bool
    let didConfirmBaselineSemanticVerificationStopLine: Bool
    let didConfirmProductionTruthPromotionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool

    init(
        writeDecision:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceReadiness,
        baselineSemanticFacts:
            CjguiInternalRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceFacts,
        didPrepareRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceReadiness:
            Bool,
        shouldConsumeWriteDecisionAfterTruthAdmissionContract: Bool,
        shouldRequireStage144WriteDecisionPacket: Bool,
        shouldRequireTruthAdmissionPreflightBeforeBaselineSemantic: Bool,
        shouldRequirePositiveFirstFrameBeforeBaselineSemantic: Bool,
        shouldRequireFrameHashNonzeroBeforeBaselineSemantic: Bool,
        shouldRequireBaselineFixtureOrSemanticComparator: Bool,
        shouldKeepBaselineComparisonNonMutating: Bool,
        didConfirmStage144WriteDecisionInput: Bool,
        didConfirmBaselineSemanticVerificationContract: Bool,
        didConfirmBaselineSemanticVerificationStopLine: Bool,
        didConfirmProductionTruthPromotionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool
    ) {
        this.writeDecision = writeDecision
        this.baselineSemanticFacts = baselineSemanticFacts
        this.didPrepareRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceReadiness =
            didPrepareRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceReadiness
        this.shouldConsumeWriteDecisionAfterTruthAdmissionContract =
            shouldConsumeWriteDecisionAfterTruthAdmissionContract
        this.shouldRequireStage144WriteDecisionPacket =
            shouldRequireStage144WriteDecisionPacket
        this.shouldRequireTruthAdmissionPreflightBeforeBaselineSemantic =
            shouldRequireTruthAdmissionPreflightBeforeBaselineSemantic
        this.shouldRequirePositiveFirstFrameBeforeBaselineSemantic =
            shouldRequirePositiveFirstFrameBeforeBaselineSemantic
        this.shouldRequireFrameHashNonzeroBeforeBaselineSemantic =
            shouldRequireFrameHashNonzeroBeforeBaselineSemantic
        this.shouldRequireBaselineFixtureOrSemanticComparator =
            shouldRequireBaselineFixtureOrSemanticComparator
        this.shouldKeepBaselineComparisonNonMutating =
            shouldKeepBaselineComparisonNonMutating
        this.didConfirmStage144WriteDecisionInput =
            didConfirmStage144WriteDecisionInput
        this.didConfirmBaselineSemanticVerificationContract =
            didConfirmBaselineSemanticVerificationContract
        this.didConfirmBaselineSemanticVerificationStopLine =
            didConfirmBaselineSemanticVerificationStopLine
        this.didConfirmProductionTruthPromotionBlocked =
            didConfirmProductionTruthPromotionBlocked
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

func cjguiInternalBuildRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceFacts(
    writeDecision:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceReadiness
): CjguiInternalRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceFacts {
    return CjguiInternalRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceFacts(
        writeDecision
            .didPrepareRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceReadiness,
        true,
        writeDecision.shouldRequireTruthAdmissionPreflightBeforeWriteDecision,
        true,
        true,
        true,
        true,
        true,
        true,
        writeDecision.didConfirmRendererStateWriteBlocked,
        writeDecision.didConfirmRuntimeStateWriteBlocked,
        writeDecision.didConfirmNoNativeBridgeExpansion,
        writeDecision.didConfirmNoPublicApi,
        writeDecision.didConfirmNoProductionPublicCAbi,
        writeDecision.didConfirmNoRuntimeStateWrite,
        writeDecision.didConfirmNoCjpmTomlChange,
        writeDecision.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalBuildRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceReadiness(
    writeDecision:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceReadiness,
    baselineSemanticFacts:
        CjguiInternalRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceFacts
): CjguiInternalRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceReadiness {
    let inputReady =
        baselineSemanticFacts.didConsumeWriteDecisionAfterTruthAdmissionContract &&
        writeDecision.didConfirmStage143TruthAdmissionInput &&
        writeDecision.didConfirmRendererStateWriteDecisionContract
    let contractReady =
        baselineSemanticFacts.didRequireStage144WriteDecisionPacket &&
        baselineSemanticFacts
            .didRequireTruthAdmissionPreflightBeforeBaselineSemantic &&
        baselineSemanticFacts.didRequirePositiveFirstFrameBeforeBaselineSemantic &&
        baselineSemanticFacts.didRequireFrameHashNonzeroBeforeBaselineSemantic &&
        baselineSemanticFacts.didRequireBaselineFixtureOrSemanticComparator &&
        baselineSemanticFacts.didKeepBaselineComparisonNonMutating &&
        baselineSemanticFacts.didKeepSemanticAcceptancePreProduction
    let stopLineReady =
        baselineSemanticFacts.didKeepProductionTruthPromotionBlocked &&
        baselineSemanticFacts.didKeepRendererStateWriteBlocked &&
        baselineSemanticFacts.didKeepRuntimeStateWriteBlocked &&
        baselineSemanticFacts.didConfirmNoNativeBridgeExpansion &&
        baselineSemanticFacts.didConfirmNoPublicApi &&
        baselineSemanticFacts.didConfirmNoProductionPublicCAbi &&
        baselineSemanticFacts.didConfirmNoRuntimeStateWrite &&
        baselineSemanticFacts.didConfirmNoCjpmTomlChange &&
        baselineSemanticFacts.didConfirmNoRendererStateWrite

    return CjguiInternalRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceReadiness(
        writeDecision,
        baselineSemanticFacts,
        inputReady && contractReady && stopLineReady,
        baselineSemanticFacts.didConsumeWriteDecisionAfterTruthAdmissionContract,
        baselineSemanticFacts.didRequireStage144WriteDecisionPacket,
        baselineSemanticFacts
            .didRequireTruthAdmissionPreflightBeforeBaselineSemantic,
        baselineSemanticFacts.didRequirePositiveFirstFrameBeforeBaselineSemantic,
        baselineSemanticFacts.didRequireFrameHashNonzeroBeforeBaselineSemantic,
        baselineSemanticFacts.didRequireBaselineFixtureOrSemanticComparator,
        baselineSemanticFacts.didKeepBaselineComparisonNonMutating,
        inputReady,
        contractReady,
        stopLineReady,
        baselineSemanticFacts.didKeepProductionTruthPromotionBlocked,
        baselineSemanticFacts.didKeepRendererStateWriteBlocked,
        baselineSemanticFacts.didKeepRuntimeStateWriteBlocked,
        baselineSemanticFacts.didConfirmNoNativeBridgeExpansion,
        baselineSemanticFacts.didConfirmNoPublicApi,
        baselineSemanticFacts.didConfirmNoProductionPublicCAbi,
        baselineSemanticFacts.didConfirmNoRuntimeStateWrite,
        baselineSemanticFacts.didConfirmNoCjpmTomlChange,
        baselineSemanticFacts.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalExecuteDefaultRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceDraft():
    CjguiInternalRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceReadiness {
    let writeDecision =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceDraft()
    let baselineSemanticFacts =
        cjguiInternalBuildRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceFacts(
            writeDecision
        )
    return cjguiInternalBuildRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceReadiness(
        writeDecision,
        baselineSemanticFacts
    )
}
