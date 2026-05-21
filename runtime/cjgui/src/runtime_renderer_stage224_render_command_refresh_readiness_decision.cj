// 中文维护注释：本文件是 stage224 render-command refresh readiness decision owner。
// Owner: 汇合 state update preview、refreshed RenderCommand packet 与 diff/explain，
// 为下一段 renderer submission preview 准备内部输入。
// Truth: readiness decision 只推进 UI framework runway，不代表 renderer 可提交。
// Stop-line: 不提交 renderer，不提交状态，不扩 public/native surface。
package cjgui

struct CjguiInternalRendererStage224RenderCommandRefreshReadinessDecisionFacts {
    let didConsumeStage223RenderCommandRefreshSemanticDiffExplain: Bool
    let didJoinStateUpdatePreviewWithRefreshedRenderCommandPacket: Bool
    let didJoinRenderCommandRefreshDiffExplainWithRollbackBoundary: Bool
    let didMaterializeRenderCommandRefreshReadinessDecision: Bool
    let didConfirmMinimalUiFrameworkRunwayAdvanced: Bool
    let didPrepareStage225RendererSubmissionPreviewInput: Bool
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
    let didKeepNativeBridgeExpansionBlocked: Bool
    let didKeepVisibilityNotPublished: Bool

    init(
        didConsumeStage223RenderCommandRefreshSemanticDiffExplain: Bool,
        didJoinStateUpdatePreviewWithRefreshedRenderCommandPacket: Bool,
        didJoinRenderCommandRefreshDiffExplainWithRollbackBoundary: Bool,
        didMaterializeRenderCommandRefreshReadinessDecision: Bool,
        didConfirmMinimalUiFrameworkRunwayAdvanced: Bool,
        didPrepareStage225RendererSubmissionPreviewInput: Bool,
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
        didKeepNativeBridgeExpansionBlocked: Bool,
        didKeepVisibilityNotPublished: Bool
    ) {
        this.didConsumeStage223RenderCommandRefreshSemanticDiffExplain =
            didConsumeStage223RenderCommandRefreshSemanticDiffExplain
        this.didJoinStateUpdatePreviewWithRefreshedRenderCommandPacket =
            didJoinStateUpdatePreviewWithRefreshedRenderCommandPacket
        this.didJoinRenderCommandRefreshDiffExplainWithRollbackBoundary =
            didJoinRenderCommandRefreshDiffExplainWithRollbackBoundary
        this.didMaterializeRenderCommandRefreshReadinessDecision =
            didMaterializeRenderCommandRefreshReadinessDecision
        this.didConfirmMinimalUiFrameworkRunwayAdvanced =
            didConfirmMinimalUiFrameworkRunwayAdvanced
        this.didPrepareStage225RendererSubmissionPreviewInput =
            didPrepareStage225RendererSubmissionPreviewInput
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
        this.didKeepNativeBridgeExpansionBlocked =
            didKeepNativeBridgeExpansionBlocked
        this.didKeepVisibilityNotPublished = didKeepVisibilityNotPublished
    }
}

struct CjguiInternalRendererStage224RenderCommandRefreshReadinessDecisionReadiness {
    let renderCommandRefreshSemanticDiffExplain:
        CjguiInternalRendererStage223RenderCommandRefreshSemanticDiffExplainReadiness
    let renderCommandRefreshReadinessDecisionFacts:
        CjguiInternalRendererStage224RenderCommandRefreshReadinessDecisionFacts
    let didPrepareStage224RenderCommandRefreshReadinessDecisionReadiness:
        Bool
    let didConfirmRenderCommandRefreshReadinessDecisionReady: Bool
    let didConfirmStateUpdatePreviewJoinedWithRefreshedRenderCommandPacket:
        Bool
    let didConfirmRenderCommandRefreshDiffExplainRollbackBoundaryJoined:
        Bool
    let didConfirmRenderCommandRefreshReadinessDecisionMaterialized: Bool
    let didConfirmStage225RendererSubmissionPreviewInputPrepared: Bool
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
    let didConfirmNativeBridgeExpansionBlocked: Bool
    let didConfirmVisibilityPublished: Bool

    init(
        renderCommandRefreshSemanticDiffExplain:
            CjguiInternalRendererStage223RenderCommandRefreshSemanticDiffExplainReadiness,
        renderCommandRefreshReadinessDecisionFacts:
            CjguiInternalRendererStage224RenderCommandRefreshReadinessDecisionFacts,
        didPrepareStage224RenderCommandRefreshReadinessDecisionReadiness:
            Bool,
        didConfirmRenderCommandRefreshReadinessDecisionReady: Bool,
        didConfirmStateUpdatePreviewJoinedWithRefreshedRenderCommandPacket:
            Bool,
        didConfirmRenderCommandRefreshDiffExplainRollbackBoundaryJoined:
            Bool,
        didConfirmRenderCommandRefreshReadinessDecisionMaterialized: Bool,
        didConfirmStage225RendererSubmissionPreviewInputPrepared: Bool,
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
        didConfirmNativeBridgeExpansionBlocked: Bool,
        didConfirmVisibilityPublished: Bool
    ) {
        this.renderCommandRefreshSemanticDiffExplain =
            renderCommandRefreshSemanticDiffExplain
        this.renderCommandRefreshReadinessDecisionFacts =
            renderCommandRefreshReadinessDecisionFacts
        this.didPrepareStage224RenderCommandRefreshReadinessDecisionReadiness =
            didPrepareStage224RenderCommandRefreshReadinessDecisionReadiness
        this.didConfirmRenderCommandRefreshReadinessDecisionReady =
            didConfirmRenderCommandRefreshReadinessDecisionReady
        this.didConfirmStateUpdatePreviewJoinedWithRefreshedRenderCommandPacket =
            didConfirmStateUpdatePreviewJoinedWithRefreshedRenderCommandPacket
        this.didConfirmRenderCommandRefreshDiffExplainRollbackBoundaryJoined =
            didConfirmRenderCommandRefreshDiffExplainRollbackBoundaryJoined
        this.didConfirmRenderCommandRefreshReadinessDecisionMaterialized =
            didConfirmRenderCommandRefreshReadinessDecisionMaterialized
        this.didConfirmStage225RendererSubmissionPreviewInputPrepared =
            didConfirmStage225RendererSubmissionPreviewInputPrepared
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
        this.didConfirmNativeBridgeExpansionBlocked =
            didConfirmNativeBridgeExpansionBlocked
        this.didConfirmVisibilityPublished = didConfirmVisibilityPublished
    }
}

func cjguiInternalBuildRendererStage224RenderCommandRefreshReadinessDecisionFacts(
    renderCommandRefreshSemanticDiffExplain:
        CjguiInternalRendererStage223RenderCommandRefreshSemanticDiffExplainReadiness
): CjguiInternalRendererStage224RenderCommandRefreshReadinessDecisionFacts {
    let refreshedPacket =
        renderCommandRefreshSemanticDiffExplain.refreshedRenderCommandPreviewPacket
    let refresh = refreshedPacket.renderCommandRefresh
    let statefulInteraction = refresh.statefulInteractionReadinessDecision

    return CjguiInternalRendererStage224RenderCommandRefreshReadinessDecisionFacts(
        renderCommandRefreshSemanticDiffExplain
            .didConfirmRenderCommandRefreshSemanticDiffExplainReady,
        refresh.didConfirmStateUpdatePreviewMappedToRenderCommandRefresh &&
            refreshedPacket
                .didConfirmRefreshedRenderCommandPreviewPacketMaterialized,
        renderCommandRefreshSemanticDiffExplain
            .didConfirmRenderCommandRefreshSemanticDiffMaterialized &&
            renderCommandRefreshSemanticDiffExplain
                .didConfirmRenderCommandRefreshExplainPacketMaterialized &&
            renderCommandRefreshSemanticDiffExplain
                .didConfirmRenderCommandRefreshRollbackReadyBoundaryMaterialized,
        true,
        true,
        true,
        renderCommandRefreshSemanticDiffExplain
            .didConfirmOwnerAcceptanceRequired,
        renderCommandRefreshSemanticDiffExplain
            .didConfirmOwnerAcceptanceGranted == false,
        statefulInteraction.didConfirmInputEventPipelineExecuted == false,
        statefulInteraction.didConfirmActionDispatchExecuted == false,
        renderCommandRefreshSemanticDiffExplain
            .didConfirmStateUpdateCommitted == false,
        statefulInteraction.didConfirmPublicComponentApiAdded == false,
        statefulInteraction.didConfirmLayoutEngineEnabled == false,
        renderCommandRefreshSemanticDiffExplain
            .didConfirmRendererSubmissionBlocked,
        renderCommandRefreshSemanticDiffExplain
            .didConfirmRendererStateWriteBlocked,
        renderCommandRefreshSemanticDiffExplain
            .didConfirmRuntimeStateWriteBlocked,
        refreshedPacket.didConfirmNativeBridgeExpansionBlocked,
        renderCommandRefreshSemanticDiffExplain
            .didConfirmVisibilityPublished == false
    )
}

func cjguiInternalBuildRendererStage224RenderCommandRefreshReadinessDecisionReadiness(
    renderCommandRefreshSemanticDiffExplain:
        CjguiInternalRendererStage223RenderCommandRefreshSemanticDiffExplainReadiness,
    renderCommandRefreshReadinessDecisionFacts:
        CjguiInternalRendererStage224RenderCommandRefreshReadinessDecisionFacts
): CjguiInternalRendererStage224RenderCommandRefreshReadinessDecisionReadiness {
    let decisionReady =
        renderCommandRefreshReadinessDecisionFacts
            .didConsumeStage223RenderCommandRefreshSemanticDiffExplain &&
        renderCommandRefreshReadinessDecisionFacts
            .didJoinStateUpdatePreviewWithRefreshedRenderCommandPacket &&
        renderCommandRefreshReadinessDecisionFacts
            .didJoinRenderCommandRefreshDiffExplainWithRollbackBoundary &&
        renderCommandRefreshReadinessDecisionFacts
            .didMaterializeRenderCommandRefreshReadinessDecision &&
        renderCommandRefreshReadinessDecisionFacts
            .didConfirmMinimalUiFrameworkRunwayAdvanced &&
        renderCommandRefreshReadinessDecisionFacts
            .didPrepareStage225RendererSubmissionPreviewInput
    let stopLineReady =
        renderCommandRefreshReadinessDecisionFacts
            .didKeepOwnerAcceptanceRequired &&
        renderCommandRefreshReadinessDecisionFacts
            .didKeepOwnerAcceptanceNotGranted &&
        renderCommandRefreshReadinessDecisionFacts
            .didKeepInputEventPipelineExecutionBlocked &&
        renderCommandRefreshReadinessDecisionFacts
            .didKeepActionDispatchBlocked &&
        renderCommandRefreshReadinessDecisionFacts
            .didKeepStateUpdateCommittedBlocked &&
        renderCommandRefreshReadinessDecisionFacts
            .didKeepPublicComponentApiBlocked &&
        renderCommandRefreshReadinessDecisionFacts
            .didKeepLayoutEngineBlocked &&
        renderCommandRefreshReadinessDecisionFacts
            .didKeepRendererSubmissionBlocked &&
        renderCommandRefreshReadinessDecisionFacts
            .didKeepRendererStateWriteBlocked &&
        renderCommandRefreshReadinessDecisionFacts
            .didKeepRuntimeStateWriteBlocked &&
        renderCommandRefreshReadinessDecisionFacts
            .didKeepNativeBridgeExpansionBlocked &&
        renderCommandRefreshReadinessDecisionFacts
            .didKeepVisibilityNotPublished

    return CjguiInternalRendererStage224RenderCommandRefreshReadinessDecisionReadiness(
        renderCommandRefreshSemanticDiffExplain,
        renderCommandRefreshReadinessDecisionFacts,
        decisionReady && stopLineReady,
        decisionReady && stopLineReady,
        renderCommandRefreshReadinessDecisionFacts
            .didJoinStateUpdatePreviewWithRefreshedRenderCommandPacket,
        renderCommandRefreshReadinessDecisionFacts
            .didJoinRenderCommandRefreshDiffExplainWithRollbackBoundary,
        renderCommandRefreshReadinessDecisionFacts
            .didMaterializeRenderCommandRefreshReadinessDecision,
        renderCommandRefreshReadinessDecisionFacts
            .didPrepareStage225RendererSubmissionPreviewInput,
        renderCommandRefreshReadinessDecisionFacts
            .didKeepOwnerAcceptanceRequired,
        false,
        false,
        false,
        false,
        false,
        false,
        renderCommandRefreshReadinessDecisionFacts
            .didKeepRendererSubmissionBlocked,
        renderCommandRefreshReadinessDecisionFacts
            .didKeepRendererStateWriteBlocked,
        renderCommandRefreshReadinessDecisionFacts
            .didKeepRuntimeStateWriteBlocked,
        renderCommandRefreshReadinessDecisionFacts
            .didKeepNativeBridgeExpansionBlocked,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage224RenderCommandRefreshReadinessDecisionDraft():
    CjguiInternalRendererStage224RenderCommandRefreshReadinessDecisionReadiness {
    let diffExplain =
        cjguiInternalExecuteDefaultRendererStage223RenderCommandRefreshSemanticDiffExplainDraft()
    let facts =
        cjguiInternalBuildRendererStage224RenderCommandRefreshReadinessDecisionFacts(
            diffExplain
        )
    return cjguiInternalBuildRendererStage224RenderCommandRefreshReadinessDecisionReadiness(
        diffExplain,
        facts
    )
}
