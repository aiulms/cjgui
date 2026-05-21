// 中文维护注释：本文件是 stage216 interaction runway readiness decision owner。
// Owner: 汇合 action intent、action preview packet 与 action rollback boundary，
// 输出下一段 state-update-after-action dry-run 输入。
// Truth: readiness decision 只推进 interaction runway，不代表 action runtime ready。
// Stop-line: 不 dispatch action，不执行 state update，不写 renderer/runtime state。
package cjgui

struct CjguiInternalRendererStage216InteractionRunwayReadinessDecisionFacts {
    let didConsumeStage215ActionSemanticDiffExplain: Bool
    let didJoinActionIntentWithActionPreviewPacket: Bool
    let didJoinActionPreviewWithActionRollbackBoundary: Bool
    let didMaterializeInteractionRunwayReadinessDecision: Bool
    let didConfirmMinimalUiFrameworkRunwayAdvanced: Bool
    let didPrepareStage217StateUpdateAfterActionDryRunInput: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepLayoutEngineBlocked: Bool
    let didKeepInputEventPipelineExecutionBlocked: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepVisibilityNotPublished: Bool

    init(
        didConsumeStage215ActionSemanticDiffExplain: Bool,
        didJoinActionIntentWithActionPreviewPacket: Bool,
        didJoinActionPreviewWithActionRollbackBoundary: Bool,
        didMaterializeInteractionRunwayReadinessDecision: Bool,
        didConfirmMinimalUiFrameworkRunwayAdvanced: Bool,
        didPrepareStage217StateUpdateAfterActionDryRunInput: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepLayoutEngineBlocked: Bool,
        didKeepInputEventPipelineExecutionBlocked: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepVisibilityNotPublished: Bool
    ) {
        this.didConsumeStage215ActionSemanticDiffExplain =
            didConsumeStage215ActionSemanticDiffExplain
        this.didJoinActionIntentWithActionPreviewPacket =
            didJoinActionIntentWithActionPreviewPacket
        this.didJoinActionPreviewWithActionRollbackBoundary =
            didJoinActionPreviewWithActionRollbackBoundary
        this.didMaterializeInteractionRunwayReadinessDecision =
            didMaterializeInteractionRunwayReadinessDecision
        this.didConfirmMinimalUiFrameworkRunwayAdvanced =
            didConfirmMinimalUiFrameworkRunwayAdvanced
        this.didPrepareStage217StateUpdateAfterActionDryRunInput =
            didPrepareStage217StateUpdateAfterActionDryRunInput
        this.didKeepPublicComponentApiBlocked =
            didKeepPublicComponentApiBlocked
        this.didKeepLayoutEngineBlocked = didKeepLayoutEngineBlocked
        this.didKeepInputEventPipelineExecutionBlocked =
            didKeepInputEventPipelineExecutionBlocked
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didKeepVisibilityNotPublished = didKeepVisibilityNotPublished
    }
}

struct CjguiInternalRendererStage216InteractionRunwayReadinessDecisionReadiness {
    let actionSemanticDiffExplain:
        CjguiInternalRendererStage215ActionSemanticDiffExplainReadiness
    let interactionRunwayReadinessDecisionFacts:
        CjguiInternalRendererStage216InteractionRunwayReadinessDecisionFacts
    let didPrepareStage216InteractionRunwayReadinessDecisionReadiness:
        Bool
    let didConfirmInteractionRunwayReadinessDecisionReady: Bool
    let didConfirmActionIntentJoinedWithActionPreviewPacket: Bool
    let didConfirmActionPreviewRollbackBoundaryJoined: Bool
    let didConfirmInteractionRunwayReadinessDecisionMaterialized: Bool
    let didConfirmStage217StateUpdateAfterActionDryRunInputPrepared: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmInputEventPipelineExecuted: Bool
    let didConfirmActionDispatchExecuted: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmLayoutEngineEnabled: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmVisibilityPublished: Bool

    init(
        actionSemanticDiffExplain:
            CjguiInternalRendererStage215ActionSemanticDiffExplainReadiness,
        interactionRunwayReadinessDecisionFacts:
            CjguiInternalRendererStage216InteractionRunwayReadinessDecisionFacts,
        didPrepareStage216InteractionRunwayReadinessDecisionReadiness:
            Bool,
        didConfirmInteractionRunwayReadinessDecisionReady: Bool,
        didConfirmActionIntentJoinedWithActionPreviewPacket: Bool,
        didConfirmActionPreviewRollbackBoundaryJoined: Bool,
        didConfirmInteractionRunwayReadinessDecisionMaterialized: Bool,
        didConfirmStage217StateUpdateAfterActionDryRunInputPrepared: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmInputEventPipelineExecuted: Bool,
        didConfirmActionDispatchExecuted: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmLayoutEngineEnabled: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmVisibilityPublished: Bool
    ) {
        this.actionSemanticDiffExplain = actionSemanticDiffExplain
        this.interactionRunwayReadinessDecisionFacts =
            interactionRunwayReadinessDecisionFacts
        this.didPrepareStage216InteractionRunwayReadinessDecisionReadiness =
            didPrepareStage216InteractionRunwayReadinessDecisionReadiness
        this.didConfirmInteractionRunwayReadinessDecisionReady =
            didConfirmInteractionRunwayReadinessDecisionReady
        this.didConfirmActionIntentJoinedWithActionPreviewPacket =
            didConfirmActionIntentJoinedWithActionPreviewPacket
        this.didConfirmActionPreviewRollbackBoundaryJoined =
            didConfirmActionPreviewRollbackBoundaryJoined
        this.didConfirmInteractionRunwayReadinessDecisionMaterialized =
            didConfirmInteractionRunwayReadinessDecisionMaterialized
        this.didConfirmStage217StateUpdateAfterActionDryRunInputPrepared =
            didConfirmStage217StateUpdateAfterActionDryRunInputPrepared
        this.didConfirmOwnerAcceptanceGranted =
            didConfirmOwnerAcceptanceGranted
        this.didConfirmInputEventPipelineExecuted =
            didConfirmInputEventPipelineExecuted
        this.didConfirmActionDispatchExecuted =
            didConfirmActionDispatchExecuted
        this.didConfirmPublicComponentApiAdded =
            didConfirmPublicComponentApiAdded
        this.didConfirmLayoutEngineEnabled = didConfirmLayoutEngineEnabled
        this.didConfirmRendererSubmissionBlocked =
            didConfirmRendererSubmissionBlocked
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked =
            didConfirmRuntimeStateWriteBlocked
        this.didConfirmVisibilityPublished = didConfirmVisibilityPublished
    }
}

func cjguiInternalBuildRendererStage216InteractionRunwayReadinessDecisionFacts(
    actionSemanticDiffExplain:
        CjguiInternalRendererStage215ActionSemanticDiffExplainReadiness
): CjguiInternalRendererStage216InteractionRunwayReadinessDecisionFacts {
    let actionPreview = actionSemanticDiffExplain.actionPreviewPacket

    return CjguiInternalRendererStage216InteractionRunwayReadinessDecisionFacts(
        actionSemanticDiffExplain.didConfirmActionSemanticDiffExplainReady,
        actionPreview
            .didConfirmActionIntentJoinedWithStyledComponentPreviewPacket &&
            actionSemanticDiffExplain.didConfirmActionSemanticDiffMaterialized,
        actionPreview.didConfirmActionPreviewPacketMaterialized &&
            actionSemanticDiffExplain
                .didConfirmActionRollbackReadyBoundaryMaterialized,
        true,
        true,
        true,
        actionSemanticDiffExplain.didConfirmPublicComponentApiAdded == false,
        actionSemanticDiffExplain.didConfirmLayoutEngineEnabled == false,
        actionSemanticDiffExplain.didConfirmInputEventPipelineExecuted == false,
        actionSemanticDiffExplain.didConfirmActionDispatchBlocked,
        actionSemanticDiffExplain.didConfirmRendererSubmissionBlocked,
        actionSemanticDiffExplain.didConfirmRendererStateWriteBlocked,
        actionSemanticDiffExplain.didConfirmRuntimeStateWriteBlocked,
        actionSemanticDiffExplain.didConfirmVisibilityPublished == false
    )
}

func cjguiInternalBuildRendererStage216InteractionRunwayReadinessDecisionReadiness(
    actionSemanticDiffExplain:
        CjguiInternalRendererStage215ActionSemanticDiffExplainReadiness,
    interactionRunwayReadinessDecisionFacts:
        CjguiInternalRendererStage216InteractionRunwayReadinessDecisionFacts
): CjguiInternalRendererStage216InteractionRunwayReadinessDecisionReadiness {
    let decisionReady =
        interactionRunwayReadinessDecisionFacts
            .didConsumeStage215ActionSemanticDiffExplain &&
        interactionRunwayReadinessDecisionFacts
            .didJoinActionIntentWithActionPreviewPacket &&
        interactionRunwayReadinessDecisionFacts
            .didJoinActionPreviewWithActionRollbackBoundary &&
        interactionRunwayReadinessDecisionFacts
            .didMaterializeInteractionRunwayReadinessDecision &&
        interactionRunwayReadinessDecisionFacts
            .didConfirmMinimalUiFrameworkRunwayAdvanced &&
        interactionRunwayReadinessDecisionFacts
            .didPrepareStage217StateUpdateAfterActionDryRunInput
    let stopLineReady =
        interactionRunwayReadinessDecisionFacts
            .didKeepPublicComponentApiBlocked &&
        interactionRunwayReadinessDecisionFacts.didKeepLayoutEngineBlocked &&
        interactionRunwayReadinessDecisionFacts
            .didKeepInputEventPipelineExecutionBlocked &&
        interactionRunwayReadinessDecisionFacts.didKeepActionDispatchBlocked &&
        interactionRunwayReadinessDecisionFacts
            .didKeepRendererSubmissionBlocked &&
        interactionRunwayReadinessDecisionFacts
            .didKeepRendererStateWriteBlocked &&
        interactionRunwayReadinessDecisionFacts
            .didKeepRuntimeStateWriteBlocked &&
        interactionRunwayReadinessDecisionFacts
            .didKeepVisibilityNotPublished

    return CjguiInternalRendererStage216InteractionRunwayReadinessDecisionReadiness(
        actionSemanticDiffExplain,
        interactionRunwayReadinessDecisionFacts,
        decisionReady && stopLineReady,
        decisionReady && stopLineReady,
        interactionRunwayReadinessDecisionFacts
            .didJoinActionIntentWithActionPreviewPacket,
        interactionRunwayReadinessDecisionFacts
            .didJoinActionPreviewWithActionRollbackBoundary,
        interactionRunwayReadinessDecisionFacts
            .didMaterializeInteractionRunwayReadinessDecision,
        interactionRunwayReadinessDecisionFacts
            .didPrepareStage217StateUpdateAfterActionDryRunInput,
        false,
        false,
        false,
        false,
        false,
        interactionRunwayReadinessDecisionFacts
            .didKeepRendererSubmissionBlocked,
        interactionRunwayReadinessDecisionFacts
            .didKeepRendererStateWriteBlocked,
        interactionRunwayReadinessDecisionFacts
            .didKeepRuntimeStateWriteBlocked,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage216InteractionRunwayReadinessDecisionDraft():
    CjguiInternalRendererStage216InteractionRunwayReadinessDecisionReadiness {
    let actionDiffExplain =
        cjguiInternalExecuteDefaultRendererStage215ActionSemanticDiffExplainDraft()
    let facts =
        cjguiInternalBuildRendererStage216InteractionRunwayReadinessDecisionFacts(
            actionDiffExplain
        )
    return cjguiInternalBuildRendererStage216InteractionRunwayReadinessDecisionReadiness(
        actionDiffExplain,
        facts
    )
}
