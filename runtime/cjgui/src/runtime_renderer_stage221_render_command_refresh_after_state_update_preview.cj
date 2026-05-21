// 中文维护注释：本文件是 stage221 render-command refresh owner。
// Owner: 消费 stage220 stateful interaction readiness 与内部 RenderCommandPacket，
// 把 state update preview 映射到 Button-like demo 的 refreshed command preview。
// Truth: refresh preview 只是后端无关 value facts，不是 renderer submission。
// Stop-line: 不提交 state update，不发布 visibility，不写 renderer/runtime state。
package cjgui

struct CjguiInternalRendererStage221RenderCommandRefreshAfterStateUpdatePreviewFacts {
    let didConsumeStage220StatefulInteractionReadinessDecision: Bool
    let didConsumeInternalRenderCommandPacket: Bool
    let didMapStateUpdatePreviewToRenderCommandRefresh: Bool
    let didBindRefreshToButtonLikeSemanticNode: Bool
    let didMaterializeRenderCommandRefreshPreview: Bool
    let didCarryOwnerLocalBeforeAfterStateRevisions: Bool
    let didPreserveRendererAgnosticCommandShape: Bool
    let didAvoidRenderSideEffect: Bool
    let didPrepareStage222RefreshedRenderCommandPreviewPacketInput: Bool
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepInputEventPipelineExecutionBlocked: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepLayoutEngineBlocked: Bool
    let didKeepVisibilityNotPublished: Bool

    init(
        didConsumeStage220StatefulInteractionReadinessDecision: Bool,
        didConsumeInternalRenderCommandPacket: Bool,
        didMapStateUpdatePreviewToRenderCommandRefresh: Bool,
        didBindRefreshToButtonLikeSemanticNode: Bool,
        didMaterializeRenderCommandRefreshPreview: Bool,
        didCarryOwnerLocalBeforeAfterStateRevisions: Bool,
        didPreserveRendererAgnosticCommandShape: Bool,
        didAvoidRenderSideEffect: Bool,
        didPrepareStage222RefreshedRenderCommandPreviewPacketInput: Bool,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepInputEventPipelineExecutionBlocked: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepLayoutEngineBlocked: Bool,
        didKeepVisibilityNotPublished: Bool
    ) {
        this.didConsumeStage220StatefulInteractionReadinessDecision =
            didConsumeStage220StatefulInteractionReadinessDecision
        this.didConsumeInternalRenderCommandPacket =
            didConsumeInternalRenderCommandPacket
        this.didMapStateUpdatePreviewToRenderCommandRefresh =
            didMapStateUpdatePreviewToRenderCommandRefresh
        this.didBindRefreshToButtonLikeSemanticNode =
            didBindRefreshToButtonLikeSemanticNode
        this.didMaterializeRenderCommandRefreshPreview =
            didMaterializeRenderCommandRefreshPreview
        this.didCarryOwnerLocalBeforeAfterStateRevisions =
            didCarryOwnerLocalBeforeAfterStateRevisions
        this.didPreserveRendererAgnosticCommandShape =
            didPreserveRendererAgnosticCommandShape
        this.didAvoidRenderSideEffect = didAvoidRenderSideEffect
        this.didPrepareStage222RefreshedRenderCommandPreviewPacketInput =
            didPrepareStage222RefreshedRenderCommandPreviewPacketInput
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didKeepOwnerAcceptanceNotGranted =
            didKeepOwnerAcceptanceNotGranted
        this.didKeepStateUpdateCommittedBlocked =
            didKeepStateUpdateCommittedBlocked
        this.didKeepInputEventPipelineExecutionBlocked =
            didKeepInputEventPipelineExecutionBlocked
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
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

struct CjguiInternalRendererStage221RenderCommandRefreshAfterStateUpdatePreviewReadiness {
    let statefulInteractionReadinessDecision:
        CjguiInternalRendererStage220StatefulInteractionReadinessDecisionReadiness
    let renderCommandPacket: CjguiInternalRenderCommandPacket
    let renderCommandRefreshAfterStateUpdatePreviewFacts:
        CjguiInternalRendererStage221RenderCommandRefreshAfterStateUpdatePreviewFacts
    let didPrepareStage221RenderCommandRefreshAfterStateUpdatePreviewReadiness:
        Bool
    let didConfirmRenderCommandRefreshReady: Bool
    let didConfirmStateUpdatePreviewMappedToRenderCommandRefresh: Bool
    let didConfirmRenderCommandRefreshPreviewMaterialized: Bool
    let didConfirmRefreshBoundToButtonLikeSemanticNode: Bool
    let didConfirmOwnerLocalBeforeAfterStateRevisionsCarried: Bool
    let didConfirmCommandPacketBackendAgnostic: Bool
    let didConfirmStage222RefreshedRenderCommandPreviewPacketInputPrepared:
        Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmStateUpdateCommitted: Bool
    let didConfirmInputEventPipelineExecuted: Bool
    let didConfirmActionDispatchExecuted: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmLayoutEngineEnabled: Bool
    let didConfirmVisibilityPublished: Bool

    init(
        statefulInteractionReadinessDecision:
            CjguiInternalRendererStage220StatefulInteractionReadinessDecisionReadiness,
        renderCommandPacket: CjguiInternalRenderCommandPacket,
        renderCommandRefreshAfterStateUpdatePreviewFacts:
            CjguiInternalRendererStage221RenderCommandRefreshAfterStateUpdatePreviewFacts,
        didPrepareStage221RenderCommandRefreshAfterStateUpdatePreviewReadiness:
            Bool,
        didConfirmRenderCommandRefreshReady: Bool,
        didConfirmStateUpdatePreviewMappedToRenderCommandRefresh: Bool,
        didConfirmRenderCommandRefreshPreviewMaterialized: Bool,
        didConfirmRefreshBoundToButtonLikeSemanticNode: Bool,
        didConfirmOwnerLocalBeforeAfterStateRevisionsCarried: Bool,
        didConfirmCommandPacketBackendAgnostic: Bool,
        didConfirmStage222RefreshedRenderCommandPreviewPacketInputPrepared:
            Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmStateUpdateCommitted: Bool,
        didConfirmInputEventPipelineExecuted: Bool,
        didConfirmActionDispatchExecuted: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmLayoutEngineEnabled: Bool,
        didConfirmVisibilityPublished: Bool
    ) {
        this.statefulInteractionReadinessDecision =
            statefulInteractionReadinessDecision
        this.renderCommandPacket = renderCommandPacket
        this.renderCommandRefreshAfterStateUpdatePreviewFacts =
            renderCommandRefreshAfterStateUpdatePreviewFacts
        this.didPrepareStage221RenderCommandRefreshAfterStateUpdatePreviewReadiness =
            didPrepareStage221RenderCommandRefreshAfterStateUpdatePreviewReadiness
        this.didConfirmRenderCommandRefreshReady =
            didConfirmRenderCommandRefreshReady
        this.didConfirmStateUpdatePreviewMappedToRenderCommandRefresh =
            didConfirmStateUpdatePreviewMappedToRenderCommandRefresh
        this.didConfirmRenderCommandRefreshPreviewMaterialized =
            didConfirmRenderCommandRefreshPreviewMaterialized
        this.didConfirmRefreshBoundToButtonLikeSemanticNode =
            didConfirmRefreshBoundToButtonLikeSemanticNode
        this.didConfirmOwnerLocalBeforeAfterStateRevisionsCarried =
            didConfirmOwnerLocalBeforeAfterStateRevisionsCarried
        this.didConfirmCommandPacketBackendAgnostic =
            didConfirmCommandPacketBackendAgnostic
        this.didConfirmStage222RefreshedRenderCommandPreviewPacketInputPrepared =
            didConfirmStage222RefreshedRenderCommandPreviewPacketInputPrepared
        this.didConfirmOwnerAcceptanceRequired =
            didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted =
            didConfirmOwnerAcceptanceGranted
        this.didConfirmStateUpdateCommitted = didConfirmStateUpdateCommitted
        this.didConfirmInputEventPipelineExecuted =
            didConfirmInputEventPipelineExecuted
        this.didConfirmActionDispatchExecuted =
            didConfirmActionDispatchExecuted
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

func cjguiInternalBuildRendererStage221RenderCommandRefreshAfterStateUpdatePreviewFacts(
    statefulInteractionReadinessDecision:
        CjguiInternalRendererStage220StatefulInteractionReadinessDecisionReadiness,
    renderCommandPacket: CjguiInternalRenderCommandPacket
): CjguiInternalRendererStage221RenderCommandRefreshAfterStateUpdatePreviewFacts {
    let stateUpdateDiff =
        statefulInteractionReadinessDecision.stateUpdateSemanticDiffExplain
    let statePreview = stateUpdateDiff.stateUpdatePreviewPacket
    let dryRunFacts = statePreview.stateUpdateAfterActionDryRun
        .stateUpdateAfterActionDryRunFacts
    let actionPreview = statePreview.stateUpdateAfterActionDryRun
        .interactionRunwayReadinessDecision.actionSemanticDiffExplain
        .actionPreviewPacket

    return CjguiInternalRendererStage221RenderCommandRefreshAfterStateUpdatePreviewFacts(
        statefulInteractionReadinessDecision
            .didConfirmStage221RenderCommandRefreshAfterStateUpdatePreviewInputPrepared,
        renderCommandPacket.isRenderCommandPacketReady,
        statePreview.didConfirmStateUpdatePreviewPacketReady &&
            stateUpdateDiff.didConfirmStateUpdateSemanticDiffMaterialized &&
            dryRunFacts.previewStateRevision > dryRunFacts.beforeStateRevision,
        actionPreview.didConfirmActionPreviewBoundToSemanticNode,
        true,
        dryRunFacts.previewStateRevision > dryRunFacts.beforeStateRevision,
        renderCommandPacket.didKeepCommandPacketRendererAgnostic,
        renderCommandPacket.didAvoidRenderSideEffect,
        true,
        statefulInteractionReadinessDecision.didConfirmOwnerAcceptanceRequired,
        statefulInteractionReadinessDecision.didConfirmOwnerAcceptanceGranted == false,
        statefulInteractionReadinessDecision.didConfirmStateUpdateCommitted == false,
        statefulInteractionReadinessDecision.didConfirmInputEventPipelineExecuted == false,
        statefulInteractionReadinessDecision.didConfirmActionDispatchExecuted == false,
        statefulInteractionReadinessDecision.didConfirmRendererSubmissionBlocked &&
            renderCommandPacket.commandList.didAvoidRendererSubmission,
        statefulInteractionReadinessDecision.didConfirmRendererStateWriteBlocked,
        statefulInteractionReadinessDecision.didConfirmRuntimeStateWriteBlocked,
        statefulInteractionReadinessDecision.didConfirmPublicComponentApiAdded == false,
        statefulInteractionReadinessDecision.didConfirmLayoutEngineEnabled == false,
        statefulInteractionReadinessDecision.didConfirmVisibilityPublished == false
    )
}

func cjguiInternalBuildRendererStage221RenderCommandRefreshAfterStateUpdatePreviewReadiness(
    statefulInteractionReadinessDecision:
        CjguiInternalRendererStage220StatefulInteractionReadinessDecisionReadiness,
    renderCommandPacket: CjguiInternalRenderCommandPacket,
    renderCommandRefreshAfterStateUpdatePreviewFacts:
        CjguiInternalRendererStage221RenderCommandRefreshAfterStateUpdatePreviewFacts
): CjguiInternalRendererStage221RenderCommandRefreshAfterStateUpdatePreviewReadiness {
    let refreshReady =
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didConsumeStage220StatefulInteractionReadinessDecision &&
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didConsumeInternalRenderCommandPacket &&
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didMapStateUpdatePreviewToRenderCommandRefresh &&
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didBindRefreshToButtonLikeSemanticNode &&
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didMaterializeRenderCommandRefreshPreview &&
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didCarryOwnerLocalBeforeAfterStateRevisions &&
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didPreserveRendererAgnosticCommandShape &&
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didAvoidRenderSideEffect &&
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didPrepareStage222RefreshedRenderCommandPreviewPacketInput
    let stopLineReady =
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didKeepOwnerAcceptanceRequired &&
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didKeepOwnerAcceptanceNotGranted &&
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didKeepStateUpdateCommittedBlocked &&
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didKeepInputEventPipelineExecutionBlocked &&
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didKeepActionDispatchBlocked &&
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didKeepRendererSubmissionBlocked &&
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didKeepRendererStateWriteBlocked &&
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didKeepRuntimeStateWriteBlocked &&
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didKeepPublicComponentApiBlocked &&
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didKeepLayoutEngineBlocked &&
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didKeepVisibilityNotPublished

    return CjguiInternalRendererStage221RenderCommandRefreshAfterStateUpdatePreviewReadiness(
        statefulInteractionReadinessDecision,
        renderCommandPacket,
        renderCommandRefreshAfterStateUpdatePreviewFacts,
        refreshReady && stopLineReady,
        refreshReady && stopLineReady,
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didMapStateUpdatePreviewToRenderCommandRefresh,
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didMaterializeRenderCommandRefreshPreview,
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didBindRefreshToButtonLikeSemanticNode,
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didCarryOwnerLocalBeforeAfterStateRevisions,
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didPreserveRendererAgnosticCommandShape,
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didPrepareStage222RefreshedRenderCommandPreviewPacketInput,
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didKeepOwnerAcceptanceRequired,
        false,
        false,
        false,
        false,
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didKeepRendererSubmissionBlocked,
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didKeepRendererStateWriteBlocked,
        renderCommandRefreshAfterStateUpdatePreviewFacts
            .didKeepRuntimeStateWriteBlocked,
        false,
        false,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage221RenderCommandRefreshAfterStateUpdatePreviewDraft():
    CjguiInternalRendererStage221RenderCommandRefreshAfterStateUpdatePreviewReadiness {
    let statefulInteractionDecision =
        cjguiInternalExecuteDefaultRendererStage220StatefulInteractionReadinessDecisionDraft()
    let commandPacket = cjguiInternalExecuteDefaultRenderCommandShapeDraft()
    let facts =
        cjguiInternalBuildRendererStage221RenderCommandRefreshAfterStateUpdatePreviewFacts(
            statefulInteractionDecision,
            commandPacket
        )
    return cjguiInternalBuildRendererStage221RenderCommandRefreshAfterStateUpdatePreviewReadiness(
        statefulInteractionDecision,
        commandPacket,
        facts
    )
}
