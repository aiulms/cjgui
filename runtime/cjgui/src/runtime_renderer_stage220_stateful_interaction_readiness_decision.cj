// 中文维护注释：本文件是 stage220 stateful interaction readiness decision owner。
// Owner: 汇合 action preview、state update preview、state diff/explain 与
// rollback-ready boundary，输出下一段 render command refresh 输入。
// Truth: readiness decision 只推进 stateful UI runway，不代表状态已提交。
// Stop-line: 不发布 visibility，不提交 renderer，不写 renderer/runtime state。
package cjgui

struct CjguiInternalRendererStage220StatefulInteractionReadinessDecisionFacts {
    let didConsumeStage219StateUpdateSemanticDiffExplain: Bool
    let didJoinActionPreviewWithStateUpdatePreviewPacket: Bool
    let didJoinStateUpdatePreviewWithRollbackReadyBoundary: Bool
    let didMaterializeStatefulInteractionReadinessDecision: Bool
    let didConfirmMinimalUiFrameworkRunwayAdvanced: Bool
    let didPrepareStage221RenderCommandRefreshAfterStateUpdatePreviewInput:
        Bool
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didKeepInputEventPipelineExecutionBlocked: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepLayoutEngineBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepVisibilityNotPublished: Bool

    init(
        didConsumeStage219StateUpdateSemanticDiffExplain: Bool,
        didJoinActionPreviewWithStateUpdatePreviewPacket: Bool,
        didJoinStateUpdatePreviewWithRollbackReadyBoundary: Bool,
        didMaterializeStatefulInteractionReadinessDecision: Bool,
        didConfirmMinimalUiFrameworkRunwayAdvanced: Bool,
        didPrepareStage221RenderCommandRefreshAfterStateUpdatePreviewInput:
            Bool,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didKeepInputEventPipelineExecutionBlocked: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepLayoutEngineBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepVisibilityNotPublished: Bool
    ) {
        this.didConsumeStage219StateUpdateSemanticDiffExplain =
            didConsumeStage219StateUpdateSemanticDiffExplain
        this.didJoinActionPreviewWithStateUpdatePreviewPacket =
            didJoinActionPreviewWithStateUpdatePreviewPacket
        this.didJoinStateUpdatePreviewWithRollbackReadyBoundary =
            didJoinStateUpdatePreviewWithRollbackReadyBoundary
        this.didMaterializeStatefulInteractionReadinessDecision =
            didMaterializeStatefulInteractionReadinessDecision
        this.didConfirmMinimalUiFrameworkRunwayAdvanced =
            didConfirmMinimalUiFrameworkRunwayAdvanced
        this.didPrepareStage221RenderCommandRefreshAfterStateUpdatePreviewInput =
            didPrepareStage221RenderCommandRefreshAfterStateUpdatePreviewInput
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didKeepOwnerAcceptanceNotGranted =
            didKeepOwnerAcceptanceNotGranted
        this.didKeepInputEventPipelineExecutionBlocked =
            didKeepInputEventPipelineExecutionBlocked
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepStateUpdateCommittedBlocked =
            didKeepStateUpdateCommittedBlocked
        this.didKeepPublicComponentApiBlocked =
            didKeepPublicComponentApiBlocked
        this.didKeepLayoutEngineBlocked = didKeepLayoutEngineBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didKeepVisibilityNotPublished = didKeepVisibilityNotPublished
    }
}

struct CjguiInternalRendererStage220StatefulInteractionReadinessDecisionReadiness {
    let stateUpdateSemanticDiffExplain:
        CjguiInternalRendererStage219StateUpdateSemanticDiffExplainReadiness
    let statefulInteractionReadinessDecisionFacts:
        CjguiInternalRendererStage220StatefulInteractionReadinessDecisionFacts
    let didPrepareStage220StatefulInteractionReadinessDecisionReadiness:
        Bool
    let didConfirmStatefulInteractionReadinessDecisionReady: Bool
    let didConfirmActionPreviewJoinedWithStateUpdatePreviewPacket: Bool
    let didConfirmStateUpdatePreviewJoinedWithRollbackReadyBoundary: Bool
    let didConfirmStatefulInteractionReadinessDecisionMaterialized: Bool
    let didConfirmStage221RenderCommandRefreshAfterStateUpdatePreviewInputPrepared:
        Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmInputEventPipelineExecuted: Bool
    let didConfirmActionDispatchExecuted: Bool
    let didConfirmStateUpdateCommitted: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmLayoutEngineEnabled: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmVisibilityPublished: Bool

    init(
        stateUpdateSemanticDiffExplain:
            CjguiInternalRendererStage219StateUpdateSemanticDiffExplainReadiness,
        statefulInteractionReadinessDecisionFacts:
            CjguiInternalRendererStage220StatefulInteractionReadinessDecisionFacts,
        didPrepareStage220StatefulInteractionReadinessDecisionReadiness:
            Bool,
        didConfirmStatefulInteractionReadinessDecisionReady: Bool,
        didConfirmActionPreviewJoinedWithStateUpdatePreviewPacket: Bool,
        didConfirmStateUpdatePreviewJoinedWithRollbackReadyBoundary: Bool,
        didConfirmStatefulInteractionReadinessDecisionMaterialized: Bool,
        didConfirmStage221RenderCommandRefreshAfterStateUpdatePreviewInputPrepared:
            Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmInputEventPipelineExecuted: Bool,
        didConfirmActionDispatchExecuted: Bool,
        didConfirmStateUpdateCommitted: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmLayoutEngineEnabled: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmVisibilityPublished: Bool
    ) {
        this.stateUpdateSemanticDiffExplain =
            stateUpdateSemanticDiffExplain
        this.statefulInteractionReadinessDecisionFacts =
            statefulInteractionReadinessDecisionFacts
        this.didPrepareStage220StatefulInteractionReadinessDecisionReadiness =
            didPrepareStage220StatefulInteractionReadinessDecisionReadiness
        this.didConfirmStatefulInteractionReadinessDecisionReady =
            didConfirmStatefulInteractionReadinessDecisionReady
        this.didConfirmActionPreviewJoinedWithStateUpdatePreviewPacket =
            didConfirmActionPreviewJoinedWithStateUpdatePreviewPacket
        this.didConfirmStateUpdatePreviewJoinedWithRollbackReadyBoundary =
            didConfirmStateUpdatePreviewJoinedWithRollbackReadyBoundary
        this.didConfirmStatefulInteractionReadinessDecisionMaterialized =
            didConfirmStatefulInteractionReadinessDecisionMaterialized
        this.didConfirmStage221RenderCommandRefreshAfterStateUpdatePreviewInputPrepared =
            didConfirmStage221RenderCommandRefreshAfterStateUpdatePreviewInputPrepared
        this.didConfirmOwnerAcceptanceRequired =
            didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted =
            didConfirmOwnerAcceptanceGranted
        this.didConfirmInputEventPipelineExecuted =
            didConfirmInputEventPipelineExecuted
        this.didConfirmActionDispatchExecuted =
            didConfirmActionDispatchExecuted
        this.didConfirmStateUpdateCommitted = didConfirmStateUpdateCommitted
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

func cjguiInternalBuildRendererStage220StatefulInteractionReadinessDecisionFacts(
    stateUpdateSemanticDiffExplain:
        CjguiInternalRendererStage219StateUpdateSemanticDiffExplainReadiness
): CjguiInternalRendererStage220StatefulInteractionReadinessDecisionFacts {
    let statePreview =
        stateUpdateSemanticDiffExplain.stateUpdatePreviewPacket
    let actionPreview = statePreview.stateUpdateAfterActionDryRun
        .interactionRunwayReadinessDecision.actionSemanticDiffExplain
        .actionPreviewPacket

    return CjguiInternalRendererStage220StatefulInteractionReadinessDecisionFacts(
        stateUpdateSemanticDiffExplain
            .didConfirmStateUpdateSemanticDiffExplainReady,
        actionPreview.didConfirmActionPreviewPacketReady &&
            statePreview.didConfirmStateUpdatePreviewPacketReady,
        statePreview.didConfirmStateUpdatePreviewBoundToRollbackPreview &&
            stateUpdateSemanticDiffExplain
                .didConfirmStateUpdateRollbackReadyBoundaryMaterialized,
        true,
        true,
        true,
        stateUpdateSemanticDiffExplain.didConfirmOwnerAcceptanceRequired,
        stateUpdateSemanticDiffExplain.didConfirmOwnerAcceptanceGranted == false,
        stateUpdateSemanticDiffExplain.didConfirmInputEventPipelineExecuted == false,
        stateUpdateSemanticDiffExplain.didConfirmActionDispatchExecuted == false,
        stateUpdateSemanticDiffExplain.didConfirmStateUpdateCommitted == false,
        stateUpdateSemanticDiffExplain.didConfirmPublicComponentApiAdded == false,
        stateUpdateSemanticDiffExplain.didConfirmLayoutEngineEnabled == false,
        stateUpdateSemanticDiffExplain.didConfirmRendererSubmissionBlocked,
        stateUpdateSemanticDiffExplain.didConfirmRendererStateWriteBlocked,
        stateUpdateSemanticDiffExplain.didConfirmRuntimeStateWriteBlocked,
        stateUpdateSemanticDiffExplain.didConfirmVisibilityPublished == false
    )
}

func cjguiInternalBuildRendererStage220StatefulInteractionReadinessDecisionReadiness(
    stateUpdateSemanticDiffExplain:
        CjguiInternalRendererStage219StateUpdateSemanticDiffExplainReadiness,
    statefulInteractionReadinessDecisionFacts:
        CjguiInternalRendererStage220StatefulInteractionReadinessDecisionFacts
): CjguiInternalRendererStage220StatefulInteractionReadinessDecisionReadiness {
    let decisionReady =
        statefulInteractionReadinessDecisionFacts
            .didConsumeStage219StateUpdateSemanticDiffExplain &&
        statefulInteractionReadinessDecisionFacts
            .didJoinActionPreviewWithStateUpdatePreviewPacket &&
        statefulInteractionReadinessDecisionFacts
            .didJoinStateUpdatePreviewWithRollbackReadyBoundary &&
        statefulInteractionReadinessDecisionFacts
            .didMaterializeStatefulInteractionReadinessDecision &&
        statefulInteractionReadinessDecisionFacts
            .didConfirmMinimalUiFrameworkRunwayAdvanced &&
        statefulInteractionReadinessDecisionFacts
            .didPrepareStage221RenderCommandRefreshAfterStateUpdatePreviewInput
    let stopLineReady =
        statefulInteractionReadinessDecisionFacts
            .didKeepOwnerAcceptanceRequired &&
        statefulInteractionReadinessDecisionFacts
            .didKeepOwnerAcceptanceNotGranted &&
        statefulInteractionReadinessDecisionFacts
            .didKeepInputEventPipelineExecutionBlocked &&
        statefulInteractionReadinessDecisionFacts
            .didKeepActionDispatchBlocked &&
        statefulInteractionReadinessDecisionFacts
            .didKeepStateUpdateCommittedBlocked &&
        statefulInteractionReadinessDecisionFacts
            .didKeepPublicComponentApiBlocked &&
        statefulInteractionReadinessDecisionFacts.didKeepLayoutEngineBlocked &&
        statefulInteractionReadinessDecisionFacts
            .didKeepRendererSubmissionBlocked &&
        statefulInteractionReadinessDecisionFacts
            .didKeepRendererStateWriteBlocked &&
        statefulInteractionReadinessDecisionFacts
            .didKeepRuntimeStateWriteBlocked &&
        statefulInteractionReadinessDecisionFacts
            .didKeepVisibilityNotPublished

    return CjguiInternalRendererStage220StatefulInteractionReadinessDecisionReadiness(
        stateUpdateSemanticDiffExplain,
        statefulInteractionReadinessDecisionFacts,
        decisionReady && stopLineReady,
        decisionReady && stopLineReady,
        statefulInteractionReadinessDecisionFacts
            .didJoinActionPreviewWithStateUpdatePreviewPacket,
        statefulInteractionReadinessDecisionFacts
            .didJoinStateUpdatePreviewWithRollbackReadyBoundary,
        statefulInteractionReadinessDecisionFacts
            .didMaterializeStatefulInteractionReadinessDecision,
        statefulInteractionReadinessDecisionFacts
            .didPrepareStage221RenderCommandRefreshAfterStateUpdatePreviewInput,
        statefulInteractionReadinessDecisionFacts
            .didKeepOwnerAcceptanceRequired,
        false,
        false,
        false,
        false,
        false,
        false,
        statefulInteractionReadinessDecisionFacts
            .didKeepRendererSubmissionBlocked,
        statefulInteractionReadinessDecisionFacts
            .didKeepRendererStateWriteBlocked,
        statefulInteractionReadinessDecisionFacts
            .didKeepRuntimeStateWriteBlocked,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage220StatefulInteractionReadinessDecisionDraft():
    CjguiInternalRendererStage220StatefulInteractionReadinessDecisionReadiness {
    let diffExplain =
        cjguiInternalExecuteDefaultRendererStage219StateUpdateSemanticDiffExplainDraft()
    let facts =
        cjguiInternalBuildRendererStage220StatefulInteractionReadinessDecisionFacts(
            diffExplain
        )
    return cjguiInternalBuildRendererStage220StatefulInteractionReadinessDecisionReadiness(
        diffExplain,
        facts
    )
}
