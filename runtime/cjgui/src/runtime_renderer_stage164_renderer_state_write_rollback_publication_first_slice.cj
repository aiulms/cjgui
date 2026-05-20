// 中文维护注释：本文件是 stage164 renderer-state write rollback publication
// first-slice runtime owner。
// Owner: 消费 stage163 executor dry-run result envelope，物化 rollback
// publication result，并准备 visibility publication result 输入。
// Stop-line: rollback publication 只在内部 envelope 中存在，不发布 public state。
package cjgui

struct CjguiInternalRendererStage164RendererStateWriteRollbackPublicationFirstSliceFacts {
    let didConsumeStage163RendererStateWriteExecutorDryRun: Bool
    let didRequireStage163RendererStateWriteExecutorDryRunPacket: Bool
    let didMaterializeRendererStateWriteRollbackPublicationResult: Bool
    let didBindRollbackPublicationToExecutorDryRun: Bool
    let didBindRollbackPublicationBoundary: Bool
    let didPrepareVisibilityPublicationResultInput: Bool
    let didKeepRollbackPublicationNonMutating: Bool
    let didKeepRollbackPublicationPredicatesUnsatisfied: Bool
    let didKeepRendererStateWriteExecutionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool

    init(
        didConsumeStage163RendererStateWriteExecutorDryRun: Bool,
        didRequireStage163RendererStateWriteExecutorDryRunPacket: Bool,
        didMaterializeRendererStateWriteRollbackPublicationResult: Bool,
        didBindRollbackPublicationToExecutorDryRun: Bool,
        didBindRollbackPublicationBoundary: Bool,
        didPrepareVisibilityPublicationResultInput: Bool,
        didKeepRollbackPublicationNonMutating: Bool,
        didKeepRollbackPublicationPredicatesUnsatisfied: Bool,
        didKeepRendererStateWriteExecutionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool
    ) {
        this.didConsumeStage163RendererStateWriteExecutorDryRun =
            didConsumeStage163RendererStateWriteExecutorDryRun
        this.didRequireStage163RendererStateWriteExecutorDryRunPacket =
            didRequireStage163RendererStateWriteExecutorDryRunPacket
        this.didMaterializeRendererStateWriteRollbackPublicationResult =
            didMaterializeRendererStateWriteRollbackPublicationResult
        this.didBindRollbackPublicationToExecutorDryRun =
            didBindRollbackPublicationToExecutorDryRun
        this.didBindRollbackPublicationBoundary =
            didBindRollbackPublicationBoundary
        this.didPrepareVisibilityPublicationResultInput =
            didPrepareVisibilityPublicationResultInput
        this.didKeepRollbackPublicationNonMutating =
            didKeepRollbackPublicationNonMutating
        this.didKeepRollbackPublicationPredicatesUnsatisfied =
            didKeepRollbackPublicationPredicatesUnsatisfied
        this.didKeepRendererStateWriteExecutionBlocked =
            didKeepRendererStateWriteExecutionBlocked
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

struct CjguiInternalRendererStage164RendererStateWriteRollbackPublicationFirstSliceReadiness {
    let rendererStateWriteExecutorDryRun:
        CjguiInternalRendererStage163RendererStateWriteExecutorDryRunFirstSliceReadiness
    let rendererStateWriteRollbackPublicationFacts:
        CjguiInternalRendererStage164RendererStateWriteRollbackPublicationFirstSliceFacts
    let didPrepareRendererStage164RendererStateWriteRollbackPublicationFirstSliceReadiness:
        Bool
    let shouldConsumeStage163RendererStateWriteExecutorDryRun: Bool
    let shouldMaterializeRendererStateWriteRollbackPublicationResult: Bool
    let shouldPrepareVisibilityPublicationResultInput: Bool
    let didConfirmStage163RendererStateWriteExecutorDryRunInput: Bool
    let didConfirmRendererStateWriteRollbackPublicationReady: Bool
    let didConfirmRendererStateWriteRollbackPublicationSourceReady: Bool
    let didConfirmRendererStateWriteRollbackPublicationRuntimeAdmitted: Bool
    let didConfirmRendererStateWriteRollbackPublicationResultMaterialized:
        Bool
    let didConfirmRendererStateWriteRollbackPublicationBoundaryBound: Bool
    let didConfirmRendererStateWriteVisibilityPublicationResultInputPrepared:
        Bool
    let didConfirmRendererStateWriteRollbackPublicationNonMutating: Bool
    let didConfirmRendererStateWriteRollbackPublicationPredicatesSatisfied:
        Bool
    let didConfirmRendererStateWriteExecutionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool

    init(
        rendererStateWriteExecutorDryRun:
            CjguiInternalRendererStage163RendererStateWriteExecutorDryRunFirstSliceReadiness,
        rendererStateWriteRollbackPublicationFacts:
            CjguiInternalRendererStage164RendererStateWriteRollbackPublicationFirstSliceFacts,
        didPrepareRendererStage164RendererStateWriteRollbackPublicationFirstSliceReadiness:
            Bool,
        shouldConsumeStage163RendererStateWriteExecutorDryRun: Bool,
        shouldMaterializeRendererStateWriteRollbackPublicationResult: Bool,
        shouldPrepareVisibilityPublicationResultInput: Bool,
        didConfirmStage163RendererStateWriteExecutorDryRunInput: Bool,
        didConfirmRendererStateWriteRollbackPublicationReady: Bool,
        didConfirmRendererStateWriteRollbackPublicationSourceReady: Bool,
        didConfirmRendererStateWriteRollbackPublicationRuntimeAdmitted: Bool,
        didConfirmRendererStateWriteRollbackPublicationResultMaterialized:
            Bool,
        didConfirmRendererStateWriteRollbackPublicationBoundaryBound: Bool,
        didConfirmRendererStateWriteVisibilityPublicationResultInputPrepared:
            Bool,
        didConfirmRendererStateWriteRollbackPublicationNonMutating: Bool,
        didConfirmRendererStateWriteRollbackPublicationPredicatesSatisfied:
            Bool,
        didConfirmRendererStateWriteExecutionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool
    ) {
        this.rendererStateWriteExecutorDryRun =
            rendererStateWriteExecutorDryRun
        this.rendererStateWriteRollbackPublicationFacts =
            rendererStateWriteRollbackPublicationFacts
        this.didPrepareRendererStage164RendererStateWriteRollbackPublicationFirstSliceReadiness =
            didPrepareRendererStage164RendererStateWriteRollbackPublicationFirstSliceReadiness
        this.shouldConsumeStage163RendererStateWriteExecutorDryRun =
            shouldConsumeStage163RendererStateWriteExecutorDryRun
        this.shouldMaterializeRendererStateWriteRollbackPublicationResult =
            shouldMaterializeRendererStateWriteRollbackPublicationResult
        this.shouldPrepareVisibilityPublicationResultInput =
            shouldPrepareVisibilityPublicationResultInput
        this.didConfirmStage163RendererStateWriteExecutorDryRunInput =
            didConfirmStage163RendererStateWriteExecutorDryRunInput
        this.didConfirmRendererStateWriteRollbackPublicationReady =
            didConfirmRendererStateWriteRollbackPublicationReady
        this.didConfirmRendererStateWriteRollbackPublicationSourceReady =
            didConfirmRendererStateWriteRollbackPublicationSourceReady
        this.didConfirmRendererStateWriteRollbackPublicationRuntimeAdmitted =
            didConfirmRendererStateWriteRollbackPublicationRuntimeAdmitted
        this.didConfirmRendererStateWriteRollbackPublicationResultMaterialized =
            didConfirmRendererStateWriteRollbackPublicationResultMaterialized
        this.didConfirmRendererStateWriteRollbackPublicationBoundaryBound =
            didConfirmRendererStateWriteRollbackPublicationBoundaryBound
        this.didConfirmRendererStateWriteVisibilityPublicationResultInputPrepared =
            didConfirmRendererStateWriteVisibilityPublicationResultInputPrepared
        this.didConfirmRendererStateWriteRollbackPublicationNonMutating =
            didConfirmRendererStateWriteRollbackPublicationNonMutating
        this.didConfirmRendererStateWriteRollbackPublicationPredicatesSatisfied =
            didConfirmRendererStateWriteRollbackPublicationPredicatesSatisfied
        this.didConfirmRendererStateWriteExecutionBlocked =
            didConfirmRendererStateWriteExecutionBlocked
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked =
            didConfirmRuntimeStateWriteBlocked
        this.didConfirmNoNativeBridgeExpansion = didConfirmNoNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi = didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
    }
}

func cjguiInternalBuildRendererStage164RendererStateWriteRollbackPublicationFirstSliceFacts(
    rendererStateWriteExecutorDryRun:
        CjguiInternalRendererStage163RendererStateWriteExecutorDryRunFirstSliceReadiness
): CjguiInternalRendererStage164RendererStateWriteRollbackPublicationFirstSliceFacts {
    return CjguiInternalRendererStage164RendererStateWriteRollbackPublicationFirstSliceFacts(
        rendererStateWriteExecutorDryRun
            .didConfirmRendererStateWriteExecutorDryRunReady,
        true,
        rendererStateWriteExecutorDryRun
            .didConfirmRendererStateWriteRollbackPublicationResultInputPrepared,
        true,
        true,
        true,
        true,
        true,
        rendererStateWriteExecutorDryRun
            .didConfirmRendererStateWriteExecutionBlocked,
        rendererStateWriteExecutorDryRun.didConfirmRendererStateWriteBlocked,
        rendererStateWriteExecutorDryRun.didConfirmRuntimeStateWriteBlocked,
        rendererStateWriteExecutorDryRun.didConfirmNoNativeBridgeExpansion,
        rendererStateWriteExecutorDryRun.didConfirmNoPublicApi,
        rendererStateWriteExecutorDryRun.didConfirmNoProductionPublicCAbi,
        rendererStateWriteExecutorDryRun.didConfirmNoRuntimeStateWrite,
        rendererStateWriteExecutorDryRun.didConfirmNoCjpmTomlChange,
        rendererStateWriteExecutorDryRun.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalBuildRendererStage164RendererStateWriteRollbackPublicationFirstSliceReadiness(
    rendererStateWriteExecutorDryRun:
        CjguiInternalRendererStage163RendererStateWriteExecutorDryRunFirstSliceReadiness,
    rendererStateWriteRollbackPublicationFacts:
        CjguiInternalRendererStage164RendererStateWriteRollbackPublicationFirstSliceFacts
): CjguiInternalRendererStage164RendererStateWriteRollbackPublicationFirstSliceReadiness {
    let stage163InputReady =
        rendererStateWriteRollbackPublicationFacts
            .didConsumeStage163RendererStateWriteExecutorDryRun &&
        rendererStateWriteExecutorDryRun
            .didConfirmRendererStateWriteExecutorDryRunReady &&
        rendererStateWriteExecutorDryRun
            .didConfirmRendererStateWriteRollbackPublicationResultInputPrepared
    let rollbackPublicationReady =
        stage163InputReady &&
        rendererStateWriteRollbackPublicationFacts
            .didMaterializeRendererStateWriteRollbackPublicationResult &&
        rendererStateWriteRollbackPublicationFacts
            .didBindRollbackPublicationToExecutorDryRun &&
        rendererStateWriteRollbackPublicationFacts
            .didBindRollbackPublicationBoundary &&
        rendererStateWriteRollbackPublicationFacts
            .didPrepareVisibilityPublicationResultInput
    let stopLineReady =
        rendererStateWriteRollbackPublicationFacts
            .didKeepRollbackPublicationNonMutating &&
        rendererStateWriteRollbackPublicationFacts
            .didKeepRollbackPublicationPredicatesUnsatisfied &&
        rendererStateWriteRollbackPublicationFacts
            .didKeepRendererStateWriteExecutionBlocked &&
        rendererStateWriteRollbackPublicationFacts
            .didKeepRendererStateWriteBlocked &&
        rendererStateWriteRollbackPublicationFacts
            .didKeepRuntimeStateWriteBlocked &&
        rendererStateWriteRollbackPublicationFacts
            .didConfirmNoNativeBridgeExpansion &&
        rendererStateWriteRollbackPublicationFacts.didConfirmNoPublicApi &&
        rendererStateWriteRollbackPublicationFacts
            .didConfirmNoProductionPublicCAbi &&
        rendererStateWriteRollbackPublicationFacts
            .didConfirmNoRuntimeStateWrite &&
        rendererStateWriteRollbackPublicationFacts.didConfirmNoCjpmTomlChange &&
        rendererStateWriteRollbackPublicationFacts
            .didConfirmNoRendererStateWrite

    return CjguiInternalRendererStage164RendererStateWriteRollbackPublicationFirstSliceReadiness(
        rendererStateWriteExecutorDryRun,
        rendererStateWriteRollbackPublicationFacts,
        rollbackPublicationReady && stopLineReady,
        rendererStateWriteRollbackPublicationFacts
            .didConsumeStage163RendererStateWriteExecutorDryRun,
        rendererStateWriteRollbackPublicationFacts
            .didMaterializeRendererStateWriteRollbackPublicationResult,
        rendererStateWriteRollbackPublicationFacts
            .didPrepareVisibilityPublicationResultInput,
        stage163InputReady,
        rollbackPublicationReady,
        rollbackPublicationReady,
        false,
        rendererStateWriteRollbackPublicationFacts
            .didMaterializeRendererStateWriteRollbackPublicationResult,
        rendererStateWriteRollbackPublicationFacts
            .didBindRollbackPublicationBoundary,
        rendererStateWriteRollbackPublicationFacts
            .didPrepareVisibilityPublicationResultInput,
        rendererStateWriteRollbackPublicationFacts
            .didKeepRollbackPublicationNonMutating,
        false,
        rendererStateWriteRollbackPublicationFacts
            .didKeepRendererStateWriteExecutionBlocked,
        rendererStateWriteRollbackPublicationFacts
            .didKeepRendererStateWriteBlocked,
        rendererStateWriteRollbackPublicationFacts
            .didKeepRuntimeStateWriteBlocked,
        rendererStateWriteRollbackPublicationFacts
            .didConfirmNoNativeBridgeExpansion,
        rendererStateWriteRollbackPublicationFacts.didConfirmNoPublicApi,
        rendererStateWriteRollbackPublicationFacts
            .didConfirmNoProductionPublicCAbi,
        rendererStateWriteRollbackPublicationFacts.didConfirmNoRuntimeStateWrite,
        rendererStateWriteRollbackPublicationFacts.didConfirmNoCjpmTomlChange,
        rendererStateWriteRollbackPublicationFacts
            .didConfirmNoRendererStateWrite
    )
}

func cjguiInternalExecuteDefaultRendererStage164RendererStateWriteRollbackPublicationFirstSliceDraft():
    CjguiInternalRendererStage164RendererStateWriteRollbackPublicationFirstSliceReadiness {
    let rendererStateWriteExecutorDryRun =
        cjguiInternalExecuteDefaultRendererStage163RendererStateWriteExecutorDryRunFirstSliceDraft()
    let rendererStateWriteRollbackPublicationFacts =
        cjguiInternalBuildRendererStage164RendererStateWriteRollbackPublicationFirstSliceFacts(
            rendererStateWriteExecutorDryRun
        )
    return cjguiInternalBuildRendererStage164RendererStateWriteRollbackPublicationFirstSliceReadiness(
        rendererStateWriteExecutorDryRun,
        rendererStateWriteRollbackPublicationFacts
    )
}
