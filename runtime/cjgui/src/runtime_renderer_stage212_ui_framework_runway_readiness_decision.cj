// 中文维护注释：本文件是 stage212 UI framework runway readiness decision owner。
// Owner: 汇合 stage209 layout/style facts、stage210 styled preview packet 与
// stage211 diff/explain，输出下一段 input/action first-slice 输入。
// Truth: readiness decision 只推进最小 UI framework runway，不等于可用 public UI。
// Stop-line: 不启用 layout/input engine，不发布 visibility，不写 renderer/runtime state。
package cjgui

struct CjguiInternalRendererStage212UiFrameworkRunwayReadinessDecisionFacts {
    let didConsumeStage211LayoutStyleSemanticDiffExplain: Bool
    let didJoinLayoutStyleFactsWithStyledPreviewPacket: Bool
    let didJoinStyledPreviewWithStyleRollbackBoundary: Bool
    let didMaterializeUiFrameworkRunwayReadinessDecision: Bool
    let didConfirmMinimalUiFrameworkRunwayAdvanced: Bool
    let didPrepareStage213InputActionFirstSliceInput: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepLayoutEngineBlocked: Bool
    let didKeepInputEventPipelineBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepVisibilityNotPublished: Bool

    init(
        didConsumeStage211LayoutStyleSemanticDiffExplain: Bool,
        didJoinLayoutStyleFactsWithStyledPreviewPacket: Bool,
        didJoinStyledPreviewWithStyleRollbackBoundary: Bool,
        didMaterializeUiFrameworkRunwayReadinessDecision: Bool,
        didConfirmMinimalUiFrameworkRunwayAdvanced: Bool,
        didPrepareStage213InputActionFirstSliceInput: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepLayoutEngineBlocked: Bool,
        didKeepInputEventPipelineBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepVisibilityNotPublished: Bool
    ) {
        this.didConsumeStage211LayoutStyleSemanticDiffExplain =
            didConsumeStage211LayoutStyleSemanticDiffExplain
        this.didJoinLayoutStyleFactsWithStyledPreviewPacket =
            didJoinLayoutStyleFactsWithStyledPreviewPacket
        this.didJoinStyledPreviewWithStyleRollbackBoundary =
            didJoinStyledPreviewWithStyleRollbackBoundary
        this.didMaterializeUiFrameworkRunwayReadinessDecision =
            didMaterializeUiFrameworkRunwayReadinessDecision
        this.didConfirmMinimalUiFrameworkRunwayAdvanced =
            didConfirmMinimalUiFrameworkRunwayAdvanced
        this.didPrepareStage213InputActionFirstSliceInput =
            didPrepareStage213InputActionFirstSliceInput
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

struct CjguiInternalRendererStage212UiFrameworkRunwayReadinessDecisionReadiness {
    let layoutStyleSemanticDiffExplain:
        CjguiInternalRendererStage211LayoutStyleSemanticDiffExplainReadiness
    let uiFrameworkRunwayReadinessDecisionFacts:
        CjguiInternalRendererStage212UiFrameworkRunwayReadinessDecisionFacts
    let didPrepareStage212UiFrameworkRunwayReadinessDecisionReadiness:
        Bool
    let didConfirmUiFrameworkRunwayReadinessDecisionReady: Bool
    let didConfirmLayoutStyleFactsJoinedWithStyledPreviewPacket: Bool
    let didConfirmStyledPreviewRollbackBoundaryJoined: Bool
    let didConfirmUiFrameworkRunwayReadinessDecisionMaterialized: Bool
    let didConfirmStage213InputActionFirstSliceInputPrepared: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmLayoutEngineEnabled: Bool
    let didConfirmInputEventPipelineEnabled: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmVisibilityPublished: Bool

    init(
        layoutStyleSemanticDiffExplain:
            CjguiInternalRendererStage211LayoutStyleSemanticDiffExplainReadiness,
        uiFrameworkRunwayReadinessDecisionFacts:
            CjguiInternalRendererStage212UiFrameworkRunwayReadinessDecisionFacts,
        didPrepareStage212UiFrameworkRunwayReadinessDecisionReadiness:
            Bool,
        didConfirmUiFrameworkRunwayReadinessDecisionReady: Bool,
        didConfirmLayoutStyleFactsJoinedWithStyledPreviewPacket: Bool,
        didConfirmStyledPreviewRollbackBoundaryJoined: Bool,
        didConfirmUiFrameworkRunwayReadinessDecisionMaterialized: Bool,
        didConfirmStage213InputActionFirstSliceInputPrepared: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmLayoutEngineEnabled: Bool,
        didConfirmInputEventPipelineEnabled: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmVisibilityPublished: Bool
    ) {
        this.layoutStyleSemanticDiffExplain = layoutStyleSemanticDiffExplain
        this.uiFrameworkRunwayReadinessDecisionFacts =
            uiFrameworkRunwayReadinessDecisionFacts
        this.didPrepareStage212UiFrameworkRunwayReadinessDecisionReadiness =
            didPrepareStage212UiFrameworkRunwayReadinessDecisionReadiness
        this.didConfirmUiFrameworkRunwayReadinessDecisionReady =
            didConfirmUiFrameworkRunwayReadinessDecisionReady
        this.didConfirmLayoutStyleFactsJoinedWithStyledPreviewPacket =
            didConfirmLayoutStyleFactsJoinedWithStyledPreviewPacket
        this.didConfirmStyledPreviewRollbackBoundaryJoined =
            didConfirmStyledPreviewRollbackBoundaryJoined
        this.didConfirmUiFrameworkRunwayReadinessDecisionMaterialized =
            didConfirmUiFrameworkRunwayReadinessDecisionMaterialized
        this.didConfirmStage213InputActionFirstSliceInputPrepared =
            didConfirmStage213InputActionFirstSliceInputPrepared
        this.didConfirmPublicComponentApiAdded =
            didConfirmPublicComponentApiAdded
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

func cjguiInternalBuildRendererStage212UiFrameworkRunwayReadinessDecisionFacts(
    layoutStyleSemanticDiffExplain:
        CjguiInternalRendererStage211LayoutStyleSemanticDiffExplainReadiness
): CjguiInternalRendererStage212UiFrameworkRunwayReadinessDecisionFacts {
    let styledPreview =
        layoutStyleSemanticDiffExplain.styledComponentPreviewPacket

    return CjguiInternalRendererStage212UiFrameworkRunwayReadinessDecisionFacts(
        layoutStyleSemanticDiffExplain
            .didConfirmLayoutStyleSemanticDiffExplainReady,
        styledPreview.didConfirmLayoutStyleFactsJoinedWithPreviewPacket,
        styledPreview.didConfirmStyledComponentPreviewPacketMaterialized &&
            layoutStyleSemanticDiffExplain
                .didConfirmStyleRollbackReadyBoundaryMaterialized,
        true,
        true,
        true,
        layoutStyleSemanticDiffExplain.didConfirmPublicComponentApiAdded == false,
        layoutStyleSemanticDiffExplain.didConfirmLayoutEngineEnabled == false,
        styledPreview.layoutStyleFirstSlice
            .didConfirmInputEventPipelineEnabled == false,
        styledPreview.didConfirmRendererSubmissionBlocked,
        layoutStyleSemanticDiffExplain.didConfirmRendererStateWriteBlocked,
        layoutStyleSemanticDiffExplain.didConfirmRuntimeStateWriteBlocked,
        layoutStyleSemanticDiffExplain.didConfirmVisibilityPublished == false
    )
}

func cjguiInternalBuildRendererStage212UiFrameworkRunwayReadinessDecisionReadiness(
    layoutStyleSemanticDiffExplain:
        CjguiInternalRendererStage211LayoutStyleSemanticDiffExplainReadiness,
    uiFrameworkRunwayReadinessDecisionFacts:
        CjguiInternalRendererStage212UiFrameworkRunwayReadinessDecisionFacts
): CjguiInternalRendererStage212UiFrameworkRunwayReadinessDecisionReadiness {
    let decisionReady =
        uiFrameworkRunwayReadinessDecisionFacts
            .didConsumeStage211LayoutStyleSemanticDiffExplain &&
        uiFrameworkRunwayReadinessDecisionFacts
            .didJoinLayoutStyleFactsWithStyledPreviewPacket &&
        uiFrameworkRunwayReadinessDecisionFacts
            .didJoinStyledPreviewWithStyleRollbackBoundary &&
        uiFrameworkRunwayReadinessDecisionFacts
            .didMaterializeUiFrameworkRunwayReadinessDecision &&
        uiFrameworkRunwayReadinessDecisionFacts
            .didConfirmMinimalUiFrameworkRunwayAdvanced &&
        uiFrameworkRunwayReadinessDecisionFacts
            .didPrepareStage213InputActionFirstSliceInput
    let stopLineReady =
        uiFrameworkRunwayReadinessDecisionFacts
            .didKeepPublicComponentApiBlocked &&
        uiFrameworkRunwayReadinessDecisionFacts.didKeepLayoutEngineBlocked &&
        uiFrameworkRunwayReadinessDecisionFacts
            .didKeepInputEventPipelineBlocked &&
        uiFrameworkRunwayReadinessDecisionFacts
            .didKeepRendererSubmissionBlocked &&
        uiFrameworkRunwayReadinessDecisionFacts
            .didKeepRendererStateWriteBlocked &&
        uiFrameworkRunwayReadinessDecisionFacts
            .didKeepRuntimeStateWriteBlocked &&
        uiFrameworkRunwayReadinessDecisionFacts
            .didKeepVisibilityNotPublished

    return CjguiInternalRendererStage212UiFrameworkRunwayReadinessDecisionReadiness(
        layoutStyleSemanticDiffExplain,
        uiFrameworkRunwayReadinessDecisionFacts,
        decisionReady && stopLineReady,
        decisionReady && stopLineReady,
        uiFrameworkRunwayReadinessDecisionFacts
            .didJoinLayoutStyleFactsWithStyledPreviewPacket,
        uiFrameworkRunwayReadinessDecisionFacts
            .didJoinStyledPreviewWithStyleRollbackBoundary,
        uiFrameworkRunwayReadinessDecisionFacts
            .didMaterializeUiFrameworkRunwayReadinessDecision,
        uiFrameworkRunwayReadinessDecisionFacts
            .didPrepareStage213InputActionFirstSliceInput,
        false,
        false,
        false,
        uiFrameworkRunwayReadinessDecisionFacts
            .didKeepRendererSubmissionBlocked,
        uiFrameworkRunwayReadinessDecisionFacts
            .didKeepRendererStateWriteBlocked,
        uiFrameworkRunwayReadinessDecisionFacts
            .didKeepRuntimeStateWriteBlocked,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage212UiFrameworkRunwayReadinessDecisionDraft():
    CjguiInternalRendererStage212UiFrameworkRunwayReadinessDecisionReadiness {
    let diffExplain =
        cjguiInternalExecuteDefaultRendererStage211LayoutStyleSemanticDiffExplainDraft()
    let facts =
        cjguiInternalBuildRendererStage212UiFrameworkRunwayReadinessDecisionFacts(
            diffExplain
        )
    return cjguiInternalBuildRendererStage212UiFrameworkRunwayReadinessDecisionReadiness(
        diffExplain,
        facts
    )
}
