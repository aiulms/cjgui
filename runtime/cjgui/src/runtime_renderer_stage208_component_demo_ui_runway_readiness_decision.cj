// 中文维护注释：本文件是 stage208 component demo UI runway readiness decision owner。
// Owner: 汇合 stage205 RenderCommand admission、stage206 preview packet 与
// stage207 semantic diff/explain，输出最小 UI framework runway readiness。
// Truth: readiness decision 只批准下一段 layout/style first-slice 输入。
// Stop-line: 不扩 public API，不启用 layout engine，不写 renderer/runtime state。
package cjgui

struct CjguiInternalRendererStage208ComponentDemoUiRunwayReadinessDecisionFacts {
    let didConsumeStage207SemanticPreviewDiffExplain: Bool
    let didJoinRenderCommandAdmissionWithPreviewPacket: Bool
    let didJoinSemanticDiffExplainWithRollbackBoundary: Bool
    let didMaterializeUiRunwayReadinessDecision: Bool
    let didConfirmMinimalUiFrameworkRunwayAdvanced: Bool
    let didPrepareStage209LayoutStyleFirstSliceInput: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepLayoutEngineBlocked: Bool
    let didKeepInputEventPipelineBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepVisibilityNotPublished: Bool

    init(
        didConsumeStage207SemanticPreviewDiffExplain: Bool,
        didJoinRenderCommandAdmissionWithPreviewPacket: Bool,
        didJoinSemanticDiffExplainWithRollbackBoundary: Bool,
        didMaterializeUiRunwayReadinessDecision: Bool,
        didConfirmMinimalUiFrameworkRunwayAdvanced: Bool,
        didPrepareStage209LayoutStyleFirstSliceInput: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepLayoutEngineBlocked: Bool,
        didKeepInputEventPipelineBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepVisibilityNotPublished: Bool
    ) {
        this.didConsumeStage207SemanticPreviewDiffExplain =
            didConsumeStage207SemanticPreviewDiffExplain
        this.didJoinRenderCommandAdmissionWithPreviewPacket =
            didJoinRenderCommandAdmissionWithPreviewPacket
        this.didJoinSemanticDiffExplainWithRollbackBoundary =
            didJoinSemanticDiffExplainWithRollbackBoundary
        this.didMaterializeUiRunwayReadinessDecision =
            didMaterializeUiRunwayReadinessDecision
        this.didConfirmMinimalUiFrameworkRunwayAdvanced =
            didConfirmMinimalUiFrameworkRunwayAdvanced
        this.didPrepareStage209LayoutStyleFirstSliceInput =
            didPrepareStage209LayoutStyleFirstSliceInput
        this.didKeepPublicComponentApiBlocked =
            didKeepPublicComponentApiBlocked
        this.didKeepLayoutEngineBlocked = didKeepLayoutEngineBlocked
        this.didKeepInputEventPipelineBlocked =
            didKeepInputEventPipelineBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didKeepVisibilityNotPublished = didKeepVisibilityNotPublished
    }
}

struct CjguiInternalRendererStage208ComponentDemoUiRunwayReadinessDecisionReadiness {
    let semanticPreviewDiffExplain:
        CjguiInternalRendererStage207SemanticPreviewDiffExplainReadiness
    let componentDemoUiRunwayReadinessDecisionFacts:
        CjguiInternalRendererStage208ComponentDemoUiRunwayReadinessDecisionFacts
    let didPrepareStage208ComponentDemoUiRunwayReadinessDecisionReadiness:
        Bool
    let didConfirmComponentDemoUiRunwayReadinessDecisionReady: Bool
    let didConfirmRenderCommandAdmissionPreviewJoined: Bool
    let didConfirmComponentDemoPreviewPacketJoined: Bool
    let didConfirmSemanticDiffExplainRollbackBoundaryJoined: Bool
    let didConfirmUiRunwayReadinessDecisionMaterialized: Bool
    let didConfirmStage209LayoutStyleFirstSliceInputPrepared: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmLayoutEngineEnabled: Bool
    let didConfirmInputEventPipelineEnabled: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmVisibilityPublished: Bool

    init(
        semanticPreviewDiffExplain:
            CjguiInternalRendererStage207SemanticPreviewDiffExplainReadiness,
        componentDemoUiRunwayReadinessDecisionFacts:
            CjguiInternalRendererStage208ComponentDemoUiRunwayReadinessDecisionFacts,
        didPrepareStage208ComponentDemoUiRunwayReadinessDecisionReadiness:
            Bool,
        didConfirmComponentDemoUiRunwayReadinessDecisionReady: Bool,
        didConfirmRenderCommandAdmissionPreviewJoined: Bool,
        didConfirmComponentDemoPreviewPacketJoined: Bool,
        didConfirmSemanticDiffExplainRollbackBoundaryJoined: Bool,
        didConfirmUiRunwayReadinessDecisionMaterialized: Bool,
        didConfirmStage209LayoutStyleFirstSliceInputPrepared: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmLayoutEngineEnabled: Bool,
        didConfirmInputEventPipelineEnabled: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmVisibilityPublished: Bool
    ) {
        this.semanticPreviewDiffExplain = semanticPreviewDiffExplain
        this.componentDemoUiRunwayReadinessDecisionFacts =
            componentDemoUiRunwayReadinessDecisionFacts
        this.didPrepareStage208ComponentDemoUiRunwayReadinessDecisionReadiness =
            didPrepareStage208ComponentDemoUiRunwayReadinessDecisionReadiness
        this.didConfirmComponentDemoUiRunwayReadinessDecisionReady =
            didConfirmComponentDemoUiRunwayReadinessDecisionReady
        this.didConfirmRenderCommandAdmissionPreviewJoined =
            didConfirmRenderCommandAdmissionPreviewJoined
        this.didConfirmComponentDemoPreviewPacketJoined =
            didConfirmComponentDemoPreviewPacketJoined
        this.didConfirmSemanticDiffExplainRollbackBoundaryJoined =
            didConfirmSemanticDiffExplainRollbackBoundaryJoined
        this.didConfirmUiRunwayReadinessDecisionMaterialized =
            didConfirmUiRunwayReadinessDecisionMaterialized
        this.didConfirmStage209LayoutStyleFirstSliceInputPrepared =
            didConfirmStage209LayoutStyleFirstSliceInputPrepared
        this.didConfirmPublicComponentApiAdded = didConfirmPublicComponentApiAdded
        this.didConfirmLayoutEngineEnabled = didConfirmLayoutEngineEnabled
        this.didConfirmInputEventPipelineEnabled =
            didConfirmInputEventPipelineEnabled
        this.didConfirmRendererSubmissionBlocked =
            didConfirmRendererSubmissionBlocked
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked =
            didConfirmRuntimeStateWriteBlocked
        this.didConfirmVisibilityPublished = didConfirmVisibilityPublished
    }
}

func cjguiInternalBuildRendererStage208ComponentDemoUiRunwayReadinessDecisionFacts(
    semanticPreviewDiffExplain:
        CjguiInternalRendererStage207SemanticPreviewDiffExplainReadiness
): CjguiInternalRendererStage208ComponentDemoUiRunwayReadinessDecisionFacts {
    let previewPacket = semanticPreviewDiffExplain.componentDemoPreviewPacket
    let admission = previewPacket.componentDemoRenderCommandAdmission

    return CjguiInternalRendererStage208ComponentDemoUiRunwayReadinessDecisionFacts(
        semanticPreviewDiffExplain
            .didConfirmSemanticPreviewDiffExplainReady,
        admission.didConfirmRenderCommandAdmissionPreviewMaterialized &&
            previewPacket.didConfirmComponentDemoPreviewPacketMaterialized,
        semanticPreviewDiffExplain.didConfirmSemanticPreviewDiffMaterialized &&
            semanticPreviewDiffExplain.didConfirmSemanticExplainPacketMaterialized &&
            semanticPreviewDiffExplain
                .didConfirmRollbackReadyPreviewBoundaryMaterialized,
        true,
        true,
        true,
        semanticPreviewDiffExplain.didConfirmPublicComponentApiAdded == false,
        true,
        true,
        previewPacket.didConfirmRendererSubmissionBlocked,
        semanticPreviewDiffExplain.didConfirmRendererStateWriteBlocked,
        semanticPreviewDiffExplain.didConfirmRuntimeStateWriteBlocked,
        semanticPreviewDiffExplain.didConfirmVisibilityPublished == false
    )
}

func cjguiInternalBuildRendererStage208ComponentDemoUiRunwayReadinessDecisionReadiness(
    semanticPreviewDiffExplain:
        CjguiInternalRendererStage207SemanticPreviewDiffExplainReadiness,
    componentDemoUiRunwayReadinessDecisionFacts:
        CjguiInternalRendererStage208ComponentDemoUiRunwayReadinessDecisionFacts
): CjguiInternalRendererStage208ComponentDemoUiRunwayReadinessDecisionReadiness {
    let decisionReady =
        componentDemoUiRunwayReadinessDecisionFacts
            .didConsumeStage207SemanticPreviewDiffExplain &&
        componentDemoUiRunwayReadinessDecisionFacts
            .didJoinRenderCommandAdmissionWithPreviewPacket &&
        componentDemoUiRunwayReadinessDecisionFacts
            .didJoinSemanticDiffExplainWithRollbackBoundary &&
        componentDemoUiRunwayReadinessDecisionFacts
            .didMaterializeUiRunwayReadinessDecision &&
        componentDemoUiRunwayReadinessDecisionFacts
            .didConfirmMinimalUiFrameworkRunwayAdvanced &&
        componentDemoUiRunwayReadinessDecisionFacts
            .didPrepareStage209LayoutStyleFirstSliceInput
    let stopLineReady =
        componentDemoUiRunwayReadinessDecisionFacts
            .didKeepPublicComponentApiBlocked &&
        componentDemoUiRunwayReadinessDecisionFacts.didKeepLayoutEngineBlocked &&
        componentDemoUiRunwayReadinessDecisionFacts
            .didKeepInputEventPipelineBlocked &&
        componentDemoUiRunwayReadinessDecisionFacts
            .didKeepRendererSubmissionBlocked &&
        componentDemoUiRunwayReadinessDecisionFacts
            .didKeepRendererStateWriteBlocked &&
        componentDemoUiRunwayReadinessDecisionFacts
            .didKeepRuntimeStateWriteBlocked &&
        componentDemoUiRunwayReadinessDecisionFacts
            .didKeepVisibilityNotPublished

    return CjguiInternalRendererStage208ComponentDemoUiRunwayReadinessDecisionReadiness(
        semanticPreviewDiffExplain,
        componentDemoUiRunwayReadinessDecisionFacts,
        decisionReady && stopLineReady,
        decisionReady && stopLineReady,
        componentDemoUiRunwayReadinessDecisionFacts
            .didJoinRenderCommandAdmissionWithPreviewPacket,
        componentDemoUiRunwayReadinessDecisionFacts
            .didJoinRenderCommandAdmissionWithPreviewPacket,
        componentDemoUiRunwayReadinessDecisionFacts
            .didJoinSemanticDiffExplainWithRollbackBoundary,
        componentDemoUiRunwayReadinessDecisionFacts
            .didMaterializeUiRunwayReadinessDecision,
        componentDemoUiRunwayReadinessDecisionFacts
            .didPrepareStage209LayoutStyleFirstSliceInput,
        false,
        false,
        false,
        componentDemoUiRunwayReadinessDecisionFacts
            .didKeepRendererSubmissionBlocked,
        componentDemoUiRunwayReadinessDecisionFacts
            .didKeepRendererStateWriteBlocked,
        componentDemoUiRunwayReadinessDecisionFacts
            .didKeepRuntimeStateWriteBlocked,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage208ComponentDemoUiRunwayReadinessDecisionDraft():
    CjguiInternalRendererStage208ComponentDemoUiRunwayReadinessDecisionReadiness {
    let diffExplain =
        cjguiInternalExecuteDefaultRendererStage207SemanticPreviewDiffExplainDraft()
    let facts = cjguiInternalBuildRendererStage208ComponentDemoUiRunwayReadinessDecisionFacts(
        diffExplain
    )
    return cjguiInternalBuildRendererStage208ComponentDemoUiRunwayReadinessDecisionReadiness(
        diffExplain,
        facts
    )
}
