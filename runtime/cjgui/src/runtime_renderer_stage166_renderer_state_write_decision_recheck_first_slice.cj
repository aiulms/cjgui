// 中文维护注释：本文件是 stage166 renderer-state write decision recheck
// first-slice runtime owner。
// Owner: 消费 stage165 visibility publication result，重检 write decision 并
// 输出 state-write first-slice contract 输入。
// Stop-line: decision recheck 仍 denied；不修改 runtime_state.cj 或 renderer state。
package cjgui

struct CjguiInternalRendererStage166RendererStateWriteDecisionRecheckFirstSliceFacts {
    let didConsumeStage165RendererStateWriteVisibilityPublication: Bool
    let didRequireStage165RendererStateWriteVisibilityPublicationPacket: Bool
    let didMaterializeRendererStateWriteDecisionRecheckLedger: Bool
    let didBindDecisionRecheckToVisibilityPublication: Bool
    let didBindRendererStateWriteDecisionPositivePredicates: Bool
    let didPrepareRendererStateWriteFirstSliceContractInput: Bool
    let didKeepRendererStateWriteDecisionDenied: Bool
    let didKeepRendererStateWriteDecisionPredicatesUnsatisfied: Bool
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
        didConsumeStage165RendererStateWriteVisibilityPublication: Bool,
        didRequireStage165RendererStateWriteVisibilityPublicationPacket: Bool,
        didMaterializeRendererStateWriteDecisionRecheckLedger: Bool,
        didBindDecisionRecheckToVisibilityPublication: Bool,
        didBindRendererStateWriteDecisionPositivePredicates: Bool,
        didPrepareRendererStateWriteFirstSliceContractInput: Bool,
        didKeepRendererStateWriteDecisionDenied: Bool,
        didKeepRendererStateWriteDecisionPredicatesUnsatisfied: Bool,
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
        this.didConsumeStage165RendererStateWriteVisibilityPublication =
            didConsumeStage165RendererStateWriteVisibilityPublication
        this.didRequireStage165RendererStateWriteVisibilityPublicationPacket =
            didRequireStage165RendererStateWriteVisibilityPublicationPacket
        this.didMaterializeRendererStateWriteDecisionRecheckLedger =
            didMaterializeRendererStateWriteDecisionRecheckLedger
        this.didBindDecisionRecheckToVisibilityPublication =
            didBindDecisionRecheckToVisibilityPublication
        this.didBindRendererStateWriteDecisionPositivePredicates =
            didBindRendererStateWriteDecisionPositivePredicates
        this.didPrepareRendererStateWriteFirstSliceContractInput =
            didPrepareRendererStateWriteFirstSliceContractInput
        this.didKeepRendererStateWriteDecisionDenied =
            didKeepRendererStateWriteDecisionDenied
        this.didKeepRendererStateWriteDecisionPredicatesUnsatisfied =
            didKeepRendererStateWriteDecisionPredicatesUnsatisfied
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

struct CjguiInternalRendererStage166RendererStateWriteDecisionRecheckFirstSliceReadiness {
    let rendererStateWriteVisibilityPublication:
        CjguiInternalRendererStage165RendererStateWriteVisibilityPublicationFirstSliceReadiness
    let rendererStateWriteDecisionRecheckFacts:
        CjguiInternalRendererStage166RendererStateWriteDecisionRecheckFirstSliceFacts
    let didPrepareRendererStage166RendererStateWriteDecisionRecheckFirstSliceReadiness:
        Bool
    let shouldConsumeStage165RendererStateWriteVisibilityPublication: Bool
    let shouldMaterializeRendererStateWriteDecisionRecheckLedger: Bool
    let shouldPrepareRendererStateWriteFirstSliceContractInput: Bool
    let didConfirmStage165RendererStateWriteVisibilityPublicationInput: Bool
    let didConfirmRendererStateWriteDecisionRecheckReady: Bool
    let didConfirmRendererStateWriteDecisionRecheckSourceReady: Bool
    let didConfirmRendererStateWriteDecisionRecheckRuntimeAdmitted: Bool
    let didConfirmRendererStateWriteDecisionRecheckLedgerMaterialized: Bool
    let didConfirmRendererStateWriteDecisionPositivePredicatesBound: Bool
    let didConfirmRendererStateWriteFirstSliceContractInputPrepared: Bool
    let didConfirmRendererStateWriteDecisionDenied: Bool
    let didConfirmRendererStateWriteDecisionPredicatesSatisfied: Bool
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
        rendererStateWriteVisibilityPublication:
            CjguiInternalRendererStage165RendererStateWriteVisibilityPublicationFirstSliceReadiness,
        rendererStateWriteDecisionRecheckFacts:
            CjguiInternalRendererStage166RendererStateWriteDecisionRecheckFirstSliceFacts,
        didPrepareRendererStage166RendererStateWriteDecisionRecheckFirstSliceReadiness:
            Bool,
        shouldConsumeStage165RendererStateWriteVisibilityPublication: Bool,
        shouldMaterializeRendererStateWriteDecisionRecheckLedger: Bool,
        shouldPrepareRendererStateWriteFirstSliceContractInput: Bool,
        didConfirmStage165RendererStateWriteVisibilityPublicationInput: Bool,
        didConfirmRendererStateWriteDecisionRecheckReady: Bool,
        didConfirmRendererStateWriteDecisionRecheckSourceReady: Bool,
        didConfirmRendererStateWriteDecisionRecheckRuntimeAdmitted: Bool,
        didConfirmRendererStateWriteDecisionRecheckLedgerMaterialized: Bool,
        didConfirmRendererStateWriteDecisionPositivePredicatesBound: Bool,
        didConfirmRendererStateWriteFirstSliceContractInputPrepared: Bool,
        didConfirmRendererStateWriteDecisionDenied: Bool,
        didConfirmRendererStateWriteDecisionPredicatesSatisfied: Bool,
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
        this.rendererStateWriteVisibilityPublication =
            rendererStateWriteVisibilityPublication
        this.rendererStateWriteDecisionRecheckFacts =
            rendererStateWriteDecisionRecheckFacts
        this.didPrepareRendererStage166RendererStateWriteDecisionRecheckFirstSliceReadiness =
            didPrepareRendererStage166RendererStateWriteDecisionRecheckFirstSliceReadiness
        this.shouldConsumeStage165RendererStateWriteVisibilityPublication =
            shouldConsumeStage165RendererStateWriteVisibilityPublication
        this.shouldMaterializeRendererStateWriteDecisionRecheckLedger =
            shouldMaterializeRendererStateWriteDecisionRecheckLedger
        this.shouldPrepareRendererStateWriteFirstSliceContractInput =
            shouldPrepareRendererStateWriteFirstSliceContractInput
        this.didConfirmStage165RendererStateWriteVisibilityPublicationInput =
            didConfirmStage165RendererStateWriteVisibilityPublicationInput
        this.didConfirmRendererStateWriteDecisionRecheckReady =
            didConfirmRendererStateWriteDecisionRecheckReady
        this.didConfirmRendererStateWriteDecisionRecheckSourceReady =
            didConfirmRendererStateWriteDecisionRecheckSourceReady
        this.didConfirmRendererStateWriteDecisionRecheckRuntimeAdmitted =
            didConfirmRendererStateWriteDecisionRecheckRuntimeAdmitted
        this.didConfirmRendererStateWriteDecisionRecheckLedgerMaterialized =
            didConfirmRendererStateWriteDecisionRecheckLedgerMaterialized
        this.didConfirmRendererStateWriteDecisionPositivePredicatesBound =
            didConfirmRendererStateWriteDecisionPositivePredicatesBound
        this.didConfirmRendererStateWriteFirstSliceContractInputPrepared =
            didConfirmRendererStateWriteFirstSliceContractInputPrepared
        this.didConfirmRendererStateWriteDecisionDenied =
            didConfirmRendererStateWriteDecisionDenied
        this.didConfirmRendererStateWriteDecisionPredicatesSatisfied =
            didConfirmRendererStateWriteDecisionPredicatesSatisfied
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

func cjguiInternalBuildRendererStage166RendererStateWriteDecisionRecheckFirstSliceFacts(
    rendererStateWriteVisibilityPublication:
        CjguiInternalRendererStage165RendererStateWriteVisibilityPublicationFirstSliceReadiness
): CjguiInternalRendererStage166RendererStateWriteDecisionRecheckFirstSliceFacts {
    return CjguiInternalRendererStage166RendererStateWriteDecisionRecheckFirstSliceFacts(
        rendererStateWriteVisibilityPublication
            .didConfirmRendererStateWriteVisibilityPublicationReady,
        true,
        rendererStateWriteVisibilityPublication
            .didConfirmRendererStateWriteDecisionRecheckInputPrepared,
        true,
        true,
        true,
        true,
        true,
        rendererStateWriteVisibilityPublication
            .didConfirmRendererStateWriteExecutionBlocked,
        rendererStateWriteVisibilityPublication.didConfirmRendererStateWriteBlocked,
        rendererStateWriteVisibilityPublication.didConfirmRuntimeStateWriteBlocked,
        rendererStateWriteVisibilityPublication.didConfirmNoNativeBridgeExpansion,
        rendererStateWriteVisibilityPublication.didConfirmNoPublicApi,
        rendererStateWriteVisibilityPublication.didConfirmNoProductionPublicCAbi,
        rendererStateWriteVisibilityPublication.didConfirmNoRuntimeStateWrite,
        rendererStateWriteVisibilityPublication.didConfirmNoCjpmTomlChange,
        rendererStateWriteVisibilityPublication.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalBuildRendererStage166RendererStateWriteDecisionRecheckFirstSliceReadiness(
    rendererStateWriteVisibilityPublication:
        CjguiInternalRendererStage165RendererStateWriteVisibilityPublicationFirstSliceReadiness,
    rendererStateWriteDecisionRecheckFacts:
        CjguiInternalRendererStage166RendererStateWriteDecisionRecheckFirstSliceFacts
): CjguiInternalRendererStage166RendererStateWriteDecisionRecheckFirstSliceReadiness {
    let stage165InputReady =
        rendererStateWriteDecisionRecheckFacts
            .didConsumeStage165RendererStateWriteVisibilityPublication &&
        rendererStateWriteVisibilityPublication
            .didConfirmRendererStateWriteVisibilityPublicationReady &&
        rendererStateWriteVisibilityPublication
            .didConfirmRendererStateWriteDecisionRecheckInputPrepared
    let decisionRecheckReady =
        stage165InputReady &&
        rendererStateWriteDecisionRecheckFacts
            .didMaterializeRendererStateWriteDecisionRecheckLedger &&
        rendererStateWriteDecisionRecheckFacts
            .didBindDecisionRecheckToVisibilityPublication &&
        rendererStateWriteDecisionRecheckFacts
            .didBindRendererStateWriteDecisionPositivePredicates &&
        rendererStateWriteDecisionRecheckFacts
            .didPrepareRendererStateWriteFirstSliceContractInput
    let stopLineReady =
        rendererStateWriteDecisionRecheckFacts
            .didKeepRendererStateWriteDecisionDenied &&
        rendererStateWriteDecisionRecheckFacts
            .didKeepRendererStateWriteDecisionPredicatesUnsatisfied &&
        rendererStateWriteDecisionRecheckFacts
            .didKeepRendererStateWriteExecutionBlocked &&
        rendererStateWriteDecisionRecheckFacts
            .didKeepRendererStateWriteBlocked &&
        rendererStateWriteDecisionRecheckFacts
            .didKeepRuntimeStateWriteBlocked &&
        rendererStateWriteDecisionRecheckFacts.didConfirmNoNativeBridgeExpansion &&
        rendererStateWriteDecisionRecheckFacts.didConfirmNoPublicApi &&
        rendererStateWriteDecisionRecheckFacts
            .didConfirmNoProductionPublicCAbi &&
        rendererStateWriteDecisionRecheckFacts.didConfirmNoRuntimeStateWrite &&
        rendererStateWriteDecisionRecheckFacts.didConfirmNoCjpmTomlChange &&
        rendererStateWriteDecisionRecheckFacts.didConfirmNoRendererStateWrite

    return CjguiInternalRendererStage166RendererStateWriteDecisionRecheckFirstSliceReadiness(
        rendererStateWriteVisibilityPublication,
        rendererStateWriteDecisionRecheckFacts,
        decisionRecheckReady && stopLineReady,
        rendererStateWriteDecisionRecheckFacts
            .didConsumeStage165RendererStateWriteVisibilityPublication,
        rendererStateWriteDecisionRecheckFacts
            .didMaterializeRendererStateWriteDecisionRecheckLedger,
        rendererStateWriteDecisionRecheckFacts
            .didPrepareRendererStateWriteFirstSliceContractInput,
        stage165InputReady,
        decisionRecheckReady,
        decisionRecheckReady,
        false,
        rendererStateWriteDecisionRecheckFacts
            .didMaterializeRendererStateWriteDecisionRecheckLedger,
        rendererStateWriteDecisionRecheckFacts
            .didBindRendererStateWriteDecisionPositivePredicates,
        rendererStateWriteDecisionRecheckFacts
            .didPrepareRendererStateWriteFirstSliceContractInput,
        rendererStateWriteDecisionRecheckFacts
            .didKeepRendererStateWriteDecisionDenied,
        false,
        rendererStateWriteDecisionRecheckFacts
            .didKeepRendererStateWriteExecutionBlocked,
        rendererStateWriteDecisionRecheckFacts.didKeepRendererStateWriteBlocked,
        rendererStateWriteDecisionRecheckFacts.didKeepRuntimeStateWriteBlocked,
        rendererStateWriteDecisionRecheckFacts.didConfirmNoNativeBridgeExpansion,
        rendererStateWriteDecisionRecheckFacts.didConfirmNoPublicApi,
        rendererStateWriteDecisionRecheckFacts.didConfirmNoProductionPublicCAbi,
        rendererStateWriteDecisionRecheckFacts.didConfirmNoRuntimeStateWrite,
        rendererStateWriteDecisionRecheckFacts.didConfirmNoCjpmTomlChange,
        rendererStateWriteDecisionRecheckFacts.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalExecuteDefaultRendererStage166RendererStateWriteDecisionRecheckFirstSliceDraft():
    CjguiInternalRendererStage166RendererStateWriteDecisionRecheckFirstSliceReadiness {
    let rendererStateWriteVisibilityPublication =
        cjguiInternalExecuteDefaultRendererStage165RendererStateWriteVisibilityPublicationFirstSliceDraft()
    let rendererStateWriteDecisionRecheckFacts =
        cjguiInternalBuildRendererStage166RendererStateWriteDecisionRecheckFirstSliceFacts(
            rendererStateWriteVisibilityPublication
        )
    return cjguiInternalBuildRendererStage166RendererStateWriteDecisionRecheckFirstSliceReadiness(
        rendererStateWriteVisibilityPublication,
        rendererStateWriteDecisionRecheckFacts
    )
}
