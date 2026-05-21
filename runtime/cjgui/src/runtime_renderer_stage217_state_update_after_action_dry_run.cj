// 中文维护注释：本文件是 stage217 state-update-after-action dry-run owner。
// Owner: 消费 stage216 interaction readiness，把 Button-like action preview
// 连接到 owner-local state update 候选和 rollback preview。
// Truth: dry-run 只证明状态更新输入可被构造，不代表 action 已执行或状态已提交。
// Stop-line: 不执行 input pipeline，不 dispatch action，不写 renderer/runtime state。
package cjgui

struct CjguiInternalRendererStage217StateUpdateAfterActionDryRunFacts {
    let actionOrdinal: Int64
    let targetSemanticNodeOrdinal: Int64
    let beforeStateRevision: Int64
    let previewStateRevision: Int64
    let didConsumeStage216InteractionRunwayReadinessDecision: Bool
    let didConsumeActionPreviewPacket: Bool
    let didBindActionIntentToOwnerLocalStateUpdateCandidate: Bool
    let didMaterializeStateUpdateAfterActionDryRun: Bool
    let didMaterializeStateUpdateRollbackPreview: Bool
    let didMaterializeVisibilityNotPublishedBoundary: Bool
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didPrepareStage218StateUpdatePreviewPacketInput: Bool
    let didKeepInputEventPipelineExecutionBlocked: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepStateUpdateNonCommitting: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepLayoutEngineBlocked: Bool
    let didKeepVisibilityNotPublished: Bool

    init(
        actionOrdinal: Int64,
        targetSemanticNodeOrdinal: Int64,
        beforeStateRevision: Int64,
        previewStateRevision: Int64,
        didConsumeStage216InteractionRunwayReadinessDecision: Bool,
        didConsumeActionPreviewPacket: Bool,
        didBindActionIntentToOwnerLocalStateUpdateCandidate: Bool,
        didMaterializeStateUpdateAfterActionDryRun: Bool,
        didMaterializeStateUpdateRollbackPreview: Bool,
        didMaterializeVisibilityNotPublishedBoundary: Bool,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didPrepareStage218StateUpdatePreviewPacketInput: Bool,
        didKeepInputEventPipelineExecutionBlocked: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepStateUpdateNonCommitting: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepLayoutEngineBlocked: Bool,
        didKeepVisibilityNotPublished: Bool
    ) {
        this.actionOrdinal = actionOrdinal
        this.targetSemanticNodeOrdinal = targetSemanticNodeOrdinal
        this.beforeStateRevision = beforeStateRevision
        this.previewStateRevision = previewStateRevision
        this.didConsumeStage216InteractionRunwayReadinessDecision =
            didConsumeStage216InteractionRunwayReadinessDecision
        this.didConsumeActionPreviewPacket = didConsumeActionPreviewPacket
        this.didBindActionIntentToOwnerLocalStateUpdateCandidate =
            didBindActionIntentToOwnerLocalStateUpdateCandidate
        this.didMaterializeStateUpdateAfterActionDryRun =
            didMaterializeStateUpdateAfterActionDryRun
        this.didMaterializeStateUpdateRollbackPreview =
            didMaterializeStateUpdateRollbackPreview
        this.didMaterializeVisibilityNotPublishedBoundary =
            didMaterializeVisibilityNotPublishedBoundary
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didKeepOwnerAcceptanceNotGranted =
            didKeepOwnerAcceptanceNotGranted
        this.didPrepareStage218StateUpdatePreviewPacketInput =
            didPrepareStage218StateUpdatePreviewPacketInput
        this.didKeepInputEventPipelineExecutionBlocked =
            didKeepInputEventPipelineExecutionBlocked
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepStateUpdateNonCommitting =
            didKeepStateUpdateNonCommitting
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didKeepPublicComponentApiBlocked =
            didKeepPublicComponentApiBlocked
        this.didKeepLayoutEngineBlocked = didKeepLayoutEngineBlocked
        this.didKeepVisibilityNotPublished = didKeepVisibilityNotPublished
    }
}

struct CjguiInternalRendererStage217StateUpdateAfterActionDryRunReadiness {
    let interactionRunwayReadinessDecision:
        CjguiInternalRendererStage216InteractionRunwayReadinessDecisionReadiness
    let stateUpdateAfterActionDryRunFacts:
        CjguiInternalRendererStage217StateUpdateAfterActionDryRunFacts
    let didPrepareStage217StateUpdateAfterActionDryRunReadiness: Bool
    let didConfirmStateUpdateAfterActionDryRunReady: Bool
    let didConfirmActionIntentBoundToOwnerLocalStateUpdateCandidate: Bool
    let didConfirmStateUpdateAfterActionDryRunMaterialized: Bool
    let didConfirmStateUpdateRollbackPreviewMaterialized: Bool
    let didConfirmVisibilityNotPublishedBoundaryMaterialized: Bool
    let didConfirmStage218StateUpdatePreviewPacketInputPrepared: Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmInputEventPipelineExecuted: Bool
    let didConfirmActionDispatchExecuted: Bool
    let didConfirmStateUpdateCommitted: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmLayoutEngineEnabled: Bool
    let didConfirmVisibilityPublished: Bool

    init(
        interactionRunwayReadinessDecision:
            CjguiInternalRendererStage216InteractionRunwayReadinessDecisionReadiness,
        stateUpdateAfterActionDryRunFacts:
            CjguiInternalRendererStage217StateUpdateAfterActionDryRunFacts,
        didPrepareStage217StateUpdateAfterActionDryRunReadiness: Bool,
        didConfirmStateUpdateAfterActionDryRunReady: Bool,
        didConfirmActionIntentBoundToOwnerLocalStateUpdateCandidate: Bool,
        didConfirmStateUpdateAfterActionDryRunMaterialized: Bool,
        didConfirmStateUpdateRollbackPreviewMaterialized: Bool,
        didConfirmVisibilityNotPublishedBoundaryMaterialized: Bool,
        didConfirmStage218StateUpdatePreviewPacketInputPrepared: Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmInputEventPipelineExecuted: Bool,
        didConfirmActionDispatchExecuted: Bool,
        didConfirmStateUpdateCommitted: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmLayoutEngineEnabled: Bool,
        didConfirmVisibilityPublished: Bool
    ) {
        this.interactionRunwayReadinessDecision =
            interactionRunwayReadinessDecision
        this.stateUpdateAfterActionDryRunFacts =
            stateUpdateAfterActionDryRunFacts
        this.didPrepareStage217StateUpdateAfterActionDryRunReadiness =
            didPrepareStage217StateUpdateAfterActionDryRunReadiness
        this.didConfirmStateUpdateAfterActionDryRunReady =
            didConfirmStateUpdateAfterActionDryRunReady
        this.didConfirmActionIntentBoundToOwnerLocalStateUpdateCandidate =
            didConfirmActionIntentBoundToOwnerLocalStateUpdateCandidate
        this.didConfirmStateUpdateAfterActionDryRunMaterialized =
            didConfirmStateUpdateAfterActionDryRunMaterialized
        this.didConfirmStateUpdateRollbackPreviewMaterialized =
            didConfirmStateUpdateRollbackPreviewMaterialized
        this.didConfirmVisibilityNotPublishedBoundaryMaterialized =
            didConfirmVisibilityNotPublishedBoundaryMaterialized
        this.didConfirmStage218StateUpdatePreviewPacketInputPrepared =
            didConfirmStage218StateUpdatePreviewPacketInputPrepared
        this.didConfirmOwnerAcceptanceRequired =
            didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted =
            didConfirmOwnerAcceptanceGranted
        this.didConfirmInputEventPipelineExecuted =
            didConfirmInputEventPipelineExecuted
        this.didConfirmActionDispatchExecuted =
            didConfirmActionDispatchExecuted
        this.didConfirmStateUpdateCommitted = didConfirmStateUpdateCommitted
        this.didConfirmRendererSubmissionBlocked =
            didConfirmRendererSubmissionBlocked
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked =
            didConfirmRuntimeStateWriteBlocked
        this.didConfirmPublicComponentApiAdded =
            didConfirmPublicComponentApiAdded
        this.didConfirmLayoutEngineEnabled = didConfirmLayoutEngineEnabled
        this.didConfirmVisibilityPublished = didConfirmVisibilityPublished
    }
}

func cjguiInternalBuildRendererStage217StateUpdateAfterActionDryRunFacts(
    interactionRunwayReadinessDecision:
        CjguiInternalRendererStage216InteractionRunwayReadinessDecisionReadiness
): CjguiInternalRendererStage217StateUpdateAfterActionDryRunFacts {
    let actionDiffExplain =
        interactionRunwayReadinessDecision.actionSemanticDiffExplain
    let actionPreview = actionDiffExplain.actionPreviewPacket
    let actionIntent = actionPreview.inputActionFirstSlice
        .inputActionFirstSliceFacts.inputActionIntentFacts

    return CjguiInternalRendererStage217StateUpdateAfterActionDryRunFacts(
        actionIntent.actionOrdinal,
        actionIntent.targetSemanticNodeOrdinal,
        1,
        2,
        interactionRunwayReadinessDecision
            .didConfirmStage217StateUpdateAfterActionDryRunInputPrepared,
        actionPreview.didConfirmActionPreviewPacketReady,
        interactionRunwayReadinessDecision
            .didConfirmActionIntentJoinedWithActionPreviewPacket &&
            actionIntent.didBindActionIntentToButtonLikeSemanticNode &&
            actionIntent.didBindEnabledPredicateToActionIntent,
        true,
        interactionRunwayReadinessDecision
            .didConfirmActionPreviewRollbackBoundaryJoined,
        interactionRunwayReadinessDecision.didConfirmVisibilityPublished == false,
        actionDiffExplain.didConfirmOwnerAcceptanceRequired,
        interactionRunwayReadinessDecision.didConfirmOwnerAcceptanceGranted == false,
        true,
        interactionRunwayReadinessDecision.didConfirmInputEventPipelineExecuted == false,
        interactionRunwayReadinessDecision.didConfirmActionDispatchExecuted == false,
        true,
        interactionRunwayReadinessDecision.didConfirmRendererSubmissionBlocked,
        interactionRunwayReadinessDecision.didConfirmRendererStateWriteBlocked,
        interactionRunwayReadinessDecision.didConfirmRuntimeStateWriteBlocked,
        interactionRunwayReadinessDecision.didConfirmPublicComponentApiAdded == false,
        interactionRunwayReadinessDecision.didConfirmLayoutEngineEnabled == false,
        interactionRunwayReadinessDecision.didConfirmVisibilityPublished == false
    )
}

func cjguiInternalBuildRendererStage217StateUpdateAfterActionDryRunReadiness(
    interactionRunwayReadinessDecision:
        CjguiInternalRendererStage216InteractionRunwayReadinessDecisionReadiness,
    stateUpdateAfterActionDryRunFacts:
        CjguiInternalRendererStage217StateUpdateAfterActionDryRunFacts
): CjguiInternalRendererStage217StateUpdateAfterActionDryRunReadiness {
    let dryRunReady =
        stateUpdateAfterActionDryRunFacts
            .didConsumeStage216InteractionRunwayReadinessDecision &&
        stateUpdateAfterActionDryRunFacts.didConsumeActionPreviewPacket &&
        stateUpdateAfterActionDryRunFacts
            .didBindActionIntentToOwnerLocalStateUpdateCandidate &&
        stateUpdateAfterActionDryRunFacts
            .didMaterializeStateUpdateAfterActionDryRun &&
        stateUpdateAfterActionDryRunFacts
            .didMaterializeStateUpdateRollbackPreview &&
        stateUpdateAfterActionDryRunFacts
            .didMaterializeVisibilityNotPublishedBoundary &&
        stateUpdateAfterActionDryRunFacts
            .didPrepareStage218StateUpdatePreviewPacketInput
    let stopLineReady =
        stateUpdateAfterActionDryRunFacts.didKeepOwnerAcceptanceRequired &&
        stateUpdateAfterActionDryRunFacts.didKeepOwnerAcceptanceNotGranted &&
        stateUpdateAfterActionDryRunFacts
            .didKeepInputEventPipelineExecutionBlocked &&
        stateUpdateAfterActionDryRunFacts.didKeepActionDispatchBlocked &&
        stateUpdateAfterActionDryRunFacts.didKeepStateUpdateNonCommitting &&
        stateUpdateAfterActionDryRunFacts.didKeepRendererSubmissionBlocked &&
        stateUpdateAfterActionDryRunFacts.didKeepRendererStateWriteBlocked &&
        stateUpdateAfterActionDryRunFacts.didKeepRuntimeStateWriteBlocked &&
        stateUpdateAfterActionDryRunFacts.didKeepPublicComponentApiBlocked &&
        stateUpdateAfterActionDryRunFacts.didKeepLayoutEngineBlocked &&
        stateUpdateAfterActionDryRunFacts.didKeepVisibilityNotPublished

    return CjguiInternalRendererStage217StateUpdateAfterActionDryRunReadiness(
        interactionRunwayReadinessDecision,
        stateUpdateAfterActionDryRunFacts,
        dryRunReady && stopLineReady,
        dryRunReady && stopLineReady,
        stateUpdateAfterActionDryRunFacts
            .didBindActionIntentToOwnerLocalStateUpdateCandidate,
        stateUpdateAfterActionDryRunFacts
            .didMaterializeStateUpdateAfterActionDryRun,
        stateUpdateAfterActionDryRunFacts
            .didMaterializeStateUpdateRollbackPreview,
        stateUpdateAfterActionDryRunFacts
            .didMaterializeVisibilityNotPublishedBoundary,
        stateUpdateAfterActionDryRunFacts
            .didPrepareStage218StateUpdatePreviewPacketInput,
        stateUpdateAfterActionDryRunFacts.didKeepOwnerAcceptanceRequired,
        false,
        false,
        false,
        false,
        stateUpdateAfterActionDryRunFacts.didKeepRendererSubmissionBlocked,
        stateUpdateAfterActionDryRunFacts.didKeepRendererStateWriteBlocked,
        stateUpdateAfterActionDryRunFacts.didKeepRuntimeStateWriteBlocked,
        false,
        false,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage217StateUpdateAfterActionDryRunDraft():
    CjguiInternalRendererStage217StateUpdateAfterActionDryRunReadiness {
    let interactionDecision =
        cjguiInternalExecuteDefaultRendererStage216InteractionRunwayReadinessDecisionDraft()
    let facts =
        cjguiInternalBuildRendererStage217StateUpdateAfterActionDryRunFacts(
            interactionDecision
        )
    return cjguiInternalBuildRendererStage217StateUpdateAfterActionDryRunReadiness(
        interactionDecision,
        facts
    )
}
