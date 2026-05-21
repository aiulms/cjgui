// 中文维护注释：本文件是 stage219 state update semantic diff / explain owner。
// Owner: 消费 state update preview packet，生成 state diff、explain packet 与
// rollback-ready boundary，作为 owner acceptance 的输入。
// Truth: diff/explain 不代表 owner 已接受，也不提交 state update。
// Stop-line: 不 dispatch action，不写 renderer/runtime state，不发布 visibility。
package cjgui

struct CjguiInternalRendererStage219StateUpdateSemanticDiffExplainFacts {
    let didConsumeStage218StateUpdatePreviewPacket: Bool
    let didMaterializeStateUpdateSemanticDiff: Bool
    let didMaterializeStateUpdateExplainPacket: Bool
    let didBindDiffToStateUpdatePreviewPacket: Bool
    let didBindExplainToActionIntentFacts: Bool
    let didMaterializeStateUpdateRollbackReadyBoundary: Bool
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didPrepareStage220StatefulInteractionReadinessDecisionInput: Bool
    let didKeepInputEventPipelineExecutionBlocked: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepVisibilityNotPublished: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepLayoutEngineBlocked: Bool

    init(
        didConsumeStage218StateUpdatePreviewPacket: Bool,
        didMaterializeStateUpdateSemanticDiff: Bool,
        didMaterializeStateUpdateExplainPacket: Bool,
        didBindDiffToStateUpdatePreviewPacket: Bool,
        didBindExplainToActionIntentFacts: Bool,
        didMaterializeStateUpdateRollbackReadyBoundary: Bool,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didPrepareStage220StatefulInteractionReadinessDecisionInput: Bool,
        didKeepInputEventPipelineExecutionBlocked: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepVisibilityNotPublished: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepLayoutEngineBlocked: Bool
    ) {
        this.didConsumeStage218StateUpdatePreviewPacket =
            didConsumeStage218StateUpdatePreviewPacket
        this.didMaterializeStateUpdateSemanticDiff =
            didMaterializeStateUpdateSemanticDiff
        this.didMaterializeStateUpdateExplainPacket =
            didMaterializeStateUpdateExplainPacket
        this.didBindDiffToStateUpdatePreviewPacket =
            didBindDiffToStateUpdatePreviewPacket
        this.didBindExplainToActionIntentFacts =
            didBindExplainToActionIntentFacts
        this.didMaterializeStateUpdateRollbackReadyBoundary =
            didMaterializeStateUpdateRollbackReadyBoundary
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didKeepOwnerAcceptanceNotGranted =
            didKeepOwnerAcceptanceNotGranted
        this.didPrepareStage220StatefulInteractionReadinessDecisionInput =
            didPrepareStage220StatefulInteractionReadinessDecisionInput
        this.didKeepInputEventPipelineExecutionBlocked =
            didKeepInputEventPipelineExecutionBlocked
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepStateUpdateCommittedBlocked =
            didKeepStateUpdateCommittedBlocked
        this.didKeepVisibilityNotPublished = didKeepVisibilityNotPublished
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didKeepPublicComponentApiBlocked =
            didKeepPublicComponentApiBlocked
        this.didKeepLayoutEngineBlocked = didKeepLayoutEngineBlocked
    }
}

struct CjguiInternalRendererStage219StateUpdateSemanticDiffExplainReadiness {
    let stateUpdatePreviewPacket:
        CjguiInternalRendererStage218StateUpdatePreviewPacketReadiness
    let stateUpdateSemanticDiffExplainFacts:
        CjguiInternalRendererStage219StateUpdateSemanticDiffExplainFacts
    let didPrepareStage219StateUpdateSemanticDiffExplainReadiness: Bool
    let didConfirmStateUpdateSemanticDiffExplainReady: Bool
    let didConfirmStateUpdateSemanticDiffMaterialized: Bool
    let didConfirmStateUpdateExplainPacketMaterialized: Bool
    let didConfirmStateUpdateRollbackReadyBoundaryMaterialized: Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmStage220StatefulInteractionReadinessDecisionInputPrepared:
        Bool
    let didConfirmInputEventPipelineExecuted: Bool
    let didConfirmActionDispatchExecuted: Bool
    let didConfirmStateUpdateCommitted: Bool
    let didConfirmVisibilityPublished: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmLayoutEngineEnabled: Bool

    init(
        stateUpdatePreviewPacket:
            CjguiInternalRendererStage218StateUpdatePreviewPacketReadiness,
        stateUpdateSemanticDiffExplainFacts:
            CjguiInternalRendererStage219StateUpdateSemanticDiffExplainFacts,
        didPrepareStage219StateUpdateSemanticDiffExplainReadiness: Bool,
        didConfirmStateUpdateSemanticDiffExplainReady: Bool,
        didConfirmStateUpdateSemanticDiffMaterialized: Bool,
        didConfirmStateUpdateExplainPacketMaterialized: Bool,
        didConfirmStateUpdateRollbackReadyBoundaryMaterialized: Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmStage220StatefulInteractionReadinessDecisionInputPrepared:
            Bool,
        didConfirmInputEventPipelineExecuted: Bool,
        didConfirmActionDispatchExecuted: Bool,
        didConfirmStateUpdateCommitted: Bool,
        didConfirmVisibilityPublished: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmLayoutEngineEnabled: Bool
    ) {
        this.stateUpdatePreviewPacket = stateUpdatePreviewPacket
        this.stateUpdateSemanticDiffExplainFacts =
            stateUpdateSemanticDiffExplainFacts
        this.didPrepareStage219StateUpdateSemanticDiffExplainReadiness =
            didPrepareStage219StateUpdateSemanticDiffExplainReadiness
        this.didConfirmStateUpdateSemanticDiffExplainReady =
            didConfirmStateUpdateSemanticDiffExplainReady
        this.didConfirmStateUpdateSemanticDiffMaterialized =
            didConfirmStateUpdateSemanticDiffMaterialized
        this.didConfirmStateUpdateExplainPacketMaterialized =
            didConfirmStateUpdateExplainPacketMaterialized
        this.didConfirmStateUpdateRollbackReadyBoundaryMaterialized =
            didConfirmStateUpdateRollbackReadyBoundaryMaterialized
        this.didConfirmOwnerAcceptanceRequired =
            didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted =
            didConfirmOwnerAcceptanceGranted
        this.didConfirmStage220StatefulInteractionReadinessDecisionInputPrepared =
            didConfirmStage220StatefulInteractionReadinessDecisionInputPrepared
        this.didConfirmInputEventPipelineExecuted =
            didConfirmInputEventPipelineExecuted
        this.didConfirmActionDispatchExecuted =
            didConfirmActionDispatchExecuted
        this.didConfirmStateUpdateCommitted = didConfirmStateUpdateCommitted
        this.didConfirmVisibilityPublished = didConfirmVisibilityPublished
        this.didConfirmRendererSubmissionBlocked =
            didConfirmRendererSubmissionBlocked
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked =
            didConfirmRuntimeStateWriteBlocked
        this.didConfirmPublicComponentApiAdded =
            didConfirmPublicComponentApiAdded
        this.didConfirmLayoutEngineEnabled = didConfirmLayoutEngineEnabled
    }
}

func cjguiInternalBuildRendererStage219StateUpdateSemanticDiffExplainFacts(
    stateUpdatePreviewPacket:
        CjguiInternalRendererStage218StateUpdatePreviewPacketReadiness
): CjguiInternalRendererStage219StateUpdateSemanticDiffExplainFacts {
    let dryRun = stateUpdatePreviewPacket.stateUpdateAfterActionDryRun
    let actionIntent = dryRun.interactionRunwayReadinessDecision
        .actionSemanticDiffExplain.actionPreviewPacket.inputActionFirstSlice
        .inputActionFirstSliceFacts.inputActionIntentFacts

    return CjguiInternalRendererStage219StateUpdateSemanticDiffExplainFacts(
        stateUpdatePreviewPacket.didConfirmStateUpdatePreviewPacketReady,
        true,
        true,
        stateUpdatePreviewPacket
            .didConfirmStateUpdatePreviewPacketMaterialized,
        actionIntent.didMaterializeButtonLikeActionIntentFacts,
        stateUpdatePreviewPacket
            .didConfirmStateUpdatePreviewBoundToRollbackPreview,
        stateUpdatePreviewPacket.didConfirmOwnerAcceptanceRequired,
        stateUpdatePreviewPacket.didConfirmOwnerAcceptanceGranted == false,
        true,
        stateUpdatePreviewPacket.didConfirmInputEventPipelineExecuted == false,
        stateUpdatePreviewPacket.didConfirmActionDispatchExecuted == false,
        stateUpdatePreviewPacket.didConfirmStateUpdateCommitted == false,
        stateUpdatePreviewPacket.didConfirmVisibilityPublished == false,
        stateUpdatePreviewPacket.didConfirmRendererSubmissionBlocked,
        stateUpdatePreviewPacket.didConfirmRendererStateWriteBlocked,
        stateUpdatePreviewPacket.didConfirmRuntimeStateWriteBlocked,
        stateUpdatePreviewPacket.didConfirmPublicComponentApiAdded == false,
        stateUpdatePreviewPacket.didConfirmLayoutEngineEnabled == false
    )
}

func cjguiInternalBuildRendererStage219StateUpdateSemanticDiffExplainReadiness(
    stateUpdatePreviewPacket:
        CjguiInternalRendererStage218StateUpdatePreviewPacketReadiness,
    stateUpdateSemanticDiffExplainFacts:
        CjguiInternalRendererStage219StateUpdateSemanticDiffExplainFacts
): CjguiInternalRendererStage219StateUpdateSemanticDiffExplainReadiness {
    let diffExplainReady =
        stateUpdateSemanticDiffExplainFacts
            .didConsumeStage218StateUpdatePreviewPacket &&
        stateUpdateSemanticDiffExplainFacts
            .didMaterializeStateUpdateSemanticDiff &&
        stateUpdateSemanticDiffExplainFacts
            .didMaterializeStateUpdateExplainPacket &&
        stateUpdateSemanticDiffExplainFacts
            .didBindDiffToStateUpdatePreviewPacket &&
        stateUpdateSemanticDiffExplainFacts
            .didBindExplainToActionIntentFacts &&
        stateUpdateSemanticDiffExplainFacts
            .didMaterializeStateUpdateRollbackReadyBoundary &&
        stateUpdateSemanticDiffExplainFacts.didKeepOwnerAcceptanceRequired &&
        stateUpdateSemanticDiffExplainFacts
            .didPrepareStage220StatefulInteractionReadinessDecisionInput
    let stopLineReady =
        stateUpdateSemanticDiffExplainFacts.didKeepOwnerAcceptanceNotGranted &&
        stateUpdateSemanticDiffExplainFacts
            .didKeepInputEventPipelineExecutionBlocked &&
        stateUpdateSemanticDiffExplainFacts.didKeepActionDispatchBlocked &&
        stateUpdateSemanticDiffExplainFacts
            .didKeepStateUpdateCommittedBlocked &&
        stateUpdateSemanticDiffExplainFacts.didKeepVisibilityNotPublished &&
        stateUpdateSemanticDiffExplainFacts.didKeepRendererSubmissionBlocked &&
        stateUpdateSemanticDiffExplainFacts.didKeepRendererStateWriteBlocked &&
        stateUpdateSemanticDiffExplainFacts.didKeepRuntimeStateWriteBlocked &&
        stateUpdateSemanticDiffExplainFacts.didKeepPublicComponentApiBlocked &&
        stateUpdateSemanticDiffExplainFacts.didKeepLayoutEngineBlocked

    return CjguiInternalRendererStage219StateUpdateSemanticDiffExplainReadiness(
        stateUpdatePreviewPacket,
        stateUpdateSemanticDiffExplainFacts,
        diffExplainReady && stopLineReady,
        diffExplainReady && stopLineReady,
        stateUpdateSemanticDiffExplainFacts
            .didMaterializeStateUpdateSemanticDiff,
        stateUpdateSemanticDiffExplainFacts
            .didMaterializeStateUpdateExplainPacket,
        stateUpdateSemanticDiffExplainFacts
            .didMaterializeStateUpdateRollbackReadyBoundary,
        stateUpdateSemanticDiffExplainFacts.didKeepOwnerAcceptanceRequired,
        false,
        stateUpdateSemanticDiffExplainFacts
            .didPrepareStage220StatefulInteractionReadinessDecisionInput,
        false,
        false,
        false,
        false,
        stateUpdateSemanticDiffExplainFacts.didKeepRendererSubmissionBlocked,
        stateUpdateSemanticDiffExplainFacts.didKeepRendererStateWriteBlocked,
        stateUpdateSemanticDiffExplainFacts.didKeepRuntimeStateWriteBlocked,
        false,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage219StateUpdateSemanticDiffExplainDraft():
    CjguiInternalRendererStage219StateUpdateSemanticDiffExplainReadiness {
    let previewPacket =
        cjguiInternalExecuteDefaultRendererStage218StateUpdatePreviewPacketDraft()
    let facts =
        cjguiInternalBuildRendererStage219StateUpdateSemanticDiffExplainFacts(
            previewPacket
        )
    return cjguiInternalBuildRendererStage219StateUpdateSemanticDiffExplainReadiness(
        previewPacket,
        facts
    )
}
