// 中文维护注释：本文件是 stage209 layout/style first-slice owner。
// Owner: 消费 stage208 UI runway readiness decision，生成 Rect/Text/Button-like
// demo 的最小 internal layout/style value facts。
// Truth: value facts 是 owner-local preview 输入，不是 layout engine 或 public API。
// Stop-line: 不启用 layout/input pipeline，不提交 renderer，不写 renderer/runtime state。
package cjgui

struct CjguiInternalRendererStage209LayoutStyleValueFacts {
    let rectOriginX: Int64
    let rectOriginY: Int64
    let rectWidth: Int64
    let rectHeight: Int64
    let textBaselineY: Int64
    let buttonInsetX: Int64
    let buttonInsetY: Int64
    let styleTokenVersion: Int64
    let didMaterializeInternalRectLayoutValueFacts: Bool
    let didMaterializeInternalTextTypographyValueFacts: Bool
    let didMaterializeInternalButtonStyleValueFacts: Bool
    let didMaterializeInternalStyleTokenValueFacts: Bool
    let didKeepValuesOwnerLocal: Bool
    let didKeepStyleResolutionDeterministic: Bool

    init(
        rectOriginX: Int64,
        rectOriginY: Int64,
        rectWidth: Int64,
        rectHeight: Int64,
        textBaselineY: Int64,
        buttonInsetX: Int64,
        buttonInsetY: Int64,
        styleTokenVersion: Int64,
        didMaterializeInternalRectLayoutValueFacts: Bool,
        didMaterializeInternalTextTypographyValueFacts: Bool,
        didMaterializeInternalButtonStyleValueFacts: Bool,
        didMaterializeInternalStyleTokenValueFacts: Bool,
        didKeepValuesOwnerLocal: Bool,
        didKeepStyleResolutionDeterministic: Bool
    ) {
        this.rectOriginX = rectOriginX
        this.rectOriginY = rectOriginY
        this.rectWidth = rectWidth
        this.rectHeight = rectHeight
        this.textBaselineY = textBaselineY
        this.buttonInsetX = buttonInsetX
        this.buttonInsetY = buttonInsetY
        this.styleTokenVersion = styleTokenVersion
        this.didMaterializeInternalRectLayoutValueFacts =
            didMaterializeInternalRectLayoutValueFacts
        this.didMaterializeInternalTextTypographyValueFacts =
            didMaterializeInternalTextTypographyValueFacts
        this.didMaterializeInternalButtonStyleValueFacts =
            didMaterializeInternalButtonStyleValueFacts
        this.didMaterializeInternalStyleTokenValueFacts =
            didMaterializeInternalStyleTokenValueFacts
        this.didKeepValuesOwnerLocal = didKeepValuesOwnerLocal
        this.didKeepStyleResolutionDeterministic =
            didKeepStyleResolutionDeterministic
    }
}

struct CjguiInternalRendererStage209LayoutStyleFirstSliceFacts {
    let layoutStyleValueFacts: CjguiInternalRendererStage209LayoutStyleValueFacts
    let didConsumeStage208ComponentDemoUiRunwayReadinessDecision: Bool
    let didConsumeComponentDemoPreviewPacket: Bool
    let didBindLayoutStyleFactsToComponentDemoPreviewPacket: Bool
    let didPreserveSemanticDiffExplainBoundary: Bool
    let didPrepareStage210StyledComponentPreviewPacketInput: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepLayoutEngineBlocked: Bool
    let didKeepInputEventPipelineBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepVisibilityNotPublished: Bool

    init(
        layoutStyleValueFacts:
            CjguiInternalRendererStage209LayoutStyleValueFacts,
        didConsumeStage208ComponentDemoUiRunwayReadinessDecision: Bool,
        didConsumeComponentDemoPreviewPacket: Bool,
        didBindLayoutStyleFactsToComponentDemoPreviewPacket: Bool,
        didPreserveSemanticDiffExplainBoundary: Bool,
        didPrepareStage210StyledComponentPreviewPacketInput: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepLayoutEngineBlocked: Bool,
        didKeepInputEventPipelineBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepVisibilityNotPublished: Bool
    ) {
        this.layoutStyleValueFacts = layoutStyleValueFacts
        this.didConsumeStage208ComponentDemoUiRunwayReadinessDecision =
            didConsumeStage208ComponentDemoUiRunwayReadinessDecision
        this.didConsumeComponentDemoPreviewPacket =
            didConsumeComponentDemoPreviewPacket
        this.didBindLayoutStyleFactsToComponentDemoPreviewPacket =
            didBindLayoutStyleFactsToComponentDemoPreviewPacket
        this.didPreserveSemanticDiffExplainBoundary =
            didPreserveSemanticDiffExplainBoundary
        this.didPrepareStage210StyledComponentPreviewPacketInput =
            didPrepareStage210StyledComponentPreviewPacketInput
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

struct CjguiInternalRendererStage209LayoutStyleFirstSliceReadiness {
    let componentDemoUiRunwayReadinessDecision:
        CjguiInternalRendererStage208ComponentDemoUiRunwayReadinessDecisionReadiness
    let layoutStyleFirstSliceFacts:
        CjguiInternalRendererStage209LayoutStyleFirstSliceFacts
    let didPrepareStage209LayoutStyleFirstSliceReadiness: Bool
    let didConfirmLayoutStyleFirstSliceReady: Bool
    let didConfirmRectLayoutValueFactsMaterialized: Bool
    let didConfirmTextTypographyValueFactsMaterialized: Bool
    let didConfirmButtonStyleValueFactsMaterialized: Bool
    let didConfirmStyleTokenValueFactsMaterialized: Bool
    let didConfirmLayoutStyleFactsBoundToComponentDemoPreviewPacket: Bool
    let didConfirmStage210StyledComponentPreviewPacketInputPrepared: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmLayoutEngineEnabled: Bool
    let didConfirmInputEventPipelineEnabled: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmVisibilityPublished: Bool

    init(
        componentDemoUiRunwayReadinessDecision:
            CjguiInternalRendererStage208ComponentDemoUiRunwayReadinessDecisionReadiness,
        layoutStyleFirstSliceFacts:
            CjguiInternalRendererStage209LayoutStyleFirstSliceFacts,
        didPrepareStage209LayoutStyleFirstSliceReadiness: Bool,
        didConfirmLayoutStyleFirstSliceReady: Bool,
        didConfirmRectLayoutValueFactsMaterialized: Bool,
        didConfirmTextTypographyValueFactsMaterialized: Bool,
        didConfirmButtonStyleValueFactsMaterialized: Bool,
        didConfirmStyleTokenValueFactsMaterialized: Bool,
        didConfirmLayoutStyleFactsBoundToComponentDemoPreviewPacket: Bool,
        didConfirmStage210StyledComponentPreviewPacketInputPrepared: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmLayoutEngineEnabled: Bool,
        didConfirmInputEventPipelineEnabled: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmVisibilityPublished: Bool
    ) {
        this.componentDemoUiRunwayReadinessDecision =
            componentDemoUiRunwayReadinessDecision
        this.layoutStyleFirstSliceFacts = layoutStyleFirstSliceFacts
        this.didPrepareStage209LayoutStyleFirstSliceReadiness =
            didPrepareStage209LayoutStyleFirstSliceReadiness
        this.didConfirmLayoutStyleFirstSliceReady =
            didConfirmLayoutStyleFirstSliceReady
        this.didConfirmRectLayoutValueFactsMaterialized =
            didConfirmRectLayoutValueFactsMaterialized
        this.didConfirmTextTypographyValueFactsMaterialized =
            didConfirmTextTypographyValueFactsMaterialized
        this.didConfirmButtonStyleValueFactsMaterialized =
            didConfirmButtonStyleValueFactsMaterialized
        this.didConfirmStyleTokenValueFactsMaterialized =
            didConfirmStyleTokenValueFactsMaterialized
        this.didConfirmLayoutStyleFactsBoundToComponentDemoPreviewPacket =
            didConfirmLayoutStyleFactsBoundToComponentDemoPreviewPacket
        this.didConfirmStage210StyledComponentPreviewPacketInputPrepared =
            didConfirmStage210StyledComponentPreviewPacketInputPrepared
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

func cjguiInternalBuildRendererStage209LayoutStyleValueFacts():
    CjguiInternalRendererStage209LayoutStyleValueFacts {
    return CjguiInternalRendererStage209LayoutStyleValueFacts(
        0,
        0,
        320,
        72,
        24,
        16,
        8,
        1,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererStage209LayoutStyleFirstSliceFacts(
    componentDemoUiRunwayReadinessDecision:
        CjguiInternalRendererStage208ComponentDemoUiRunwayReadinessDecisionReadiness,
    layoutStyleValueFacts:
        CjguiInternalRendererStage209LayoutStyleValueFacts
): CjguiInternalRendererStage209LayoutStyleFirstSliceFacts {
    let semanticDiffExplain =
        componentDemoUiRunwayReadinessDecision.semanticPreviewDiffExplain
    let previewPacket = semanticDiffExplain.componentDemoPreviewPacket

    return CjguiInternalRendererStage209LayoutStyleFirstSliceFacts(
        layoutStyleValueFacts,
        componentDemoUiRunwayReadinessDecision
            .didConfirmStage209LayoutStyleFirstSliceInputPrepared,
        previewPacket.didConfirmComponentDemoPreviewPacketMaterialized,
        layoutStyleValueFacts.didMaterializeInternalRectLayoutValueFacts &&
            layoutStyleValueFacts
                .didMaterializeInternalTextTypographyValueFacts &&
            layoutStyleValueFacts.didMaterializeInternalButtonStyleValueFacts &&
            layoutStyleValueFacts.didMaterializeInternalStyleTokenValueFacts,
        semanticDiffExplain.didConfirmSemanticPreviewDiffExplainReady &&
            semanticDiffExplain.didConfirmRollbackReadyPreviewBoundaryMaterialized,
        true,
        componentDemoUiRunwayReadinessDecision
            .didConfirmPublicComponentApiAdded == false,
        componentDemoUiRunwayReadinessDecision
            .didConfirmLayoutEngineEnabled == false,
        componentDemoUiRunwayReadinessDecision
            .didConfirmInputEventPipelineEnabled == false,
        componentDemoUiRunwayReadinessDecision
            .didConfirmRendererSubmissionBlocked,
        componentDemoUiRunwayReadinessDecision
            .didConfirmRendererStateWriteBlocked,
        componentDemoUiRunwayReadinessDecision
            .didConfirmRuntimeStateWriteBlocked,
        componentDemoUiRunwayReadinessDecision
            .didConfirmVisibilityPublished == false
    )
}

func cjguiInternalBuildRendererStage209LayoutStyleFirstSliceReadiness(
    componentDemoUiRunwayReadinessDecision:
        CjguiInternalRendererStage208ComponentDemoUiRunwayReadinessDecisionReadiness,
    layoutStyleFirstSliceFacts:
        CjguiInternalRendererStage209LayoutStyleFirstSliceFacts
): CjguiInternalRendererStage209LayoutStyleFirstSliceReadiness {
    let valueFacts = layoutStyleFirstSliceFacts.layoutStyleValueFacts
    let firstSliceReady =
        layoutStyleFirstSliceFacts
            .didConsumeStage208ComponentDemoUiRunwayReadinessDecision &&
        layoutStyleFirstSliceFacts.didConsumeComponentDemoPreviewPacket &&
        layoutStyleFirstSliceFacts
            .didBindLayoutStyleFactsToComponentDemoPreviewPacket &&
        layoutStyleFirstSliceFacts.didPreserveSemanticDiffExplainBoundary &&
        layoutStyleFirstSliceFacts
            .didPrepareStage210StyledComponentPreviewPacketInput &&
        valueFacts.didMaterializeInternalRectLayoutValueFacts &&
        valueFacts.didMaterializeInternalTextTypographyValueFacts &&
        valueFacts.didMaterializeInternalButtonStyleValueFacts &&
        valueFacts.didMaterializeInternalStyleTokenValueFacts &&
        valueFacts.didKeepValuesOwnerLocal &&
        valueFacts.didKeepStyleResolutionDeterministic
    let stopLineReady =
        layoutStyleFirstSliceFacts.didKeepPublicComponentApiBlocked &&
        layoutStyleFirstSliceFacts.didKeepLayoutEngineBlocked &&
        layoutStyleFirstSliceFacts.didKeepInputEventPipelineBlocked &&
        layoutStyleFirstSliceFacts.didKeepRendererSubmissionBlocked &&
        layoutStyleFirstSliceFacts.didKeepRendererStateWriteBlocked &&
        layoutStyleFirstSliceFacts.didKeepRuntimeStateWriteBlocked &&
        layoutStyleFirstSliceFacts.didKeepVisibilityNotPublished

    return CjguiInternalRendererStage209LayoutStyleFirstSliceReadiness(
        componentDemoUiRunwayReadinessDecision,
        layoutStyleFirstSliceFacts,
        firstSliceReady && stopLineReady,
        firstSliceReady && stopLineReady,
        valueFacts.didMaterializeInternalRectLayoutValueFacts,
        valueFacts.didMaterializeInternalTextTypographyValueFacts,
        valueFacts.didMaterializeInternalButtonStyleValueFacts,
        valueFacts.didMaterializeInternalStyleTokenValueFacts,
        layoutStyleFirstSliceFacts
            .didBindLayoutStyleFactsToComponentDemoPreviewPacket,
        layoutStyleFirstSliceFacts
            .didPrepareStage210StyledComponentPreviewPacketInput,
        false,
        false,
        false,
        layoutStyleFirstSliceFacts.didKeepRendererSubmissionBlocked,
        layoutStyleFirstSliceFacts.didKeepRendererStateWriteBlocked,
        layoutStyleFirstSliceFacts.didKeepRuntimeStateWriteBlocked,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage209LayoutStyleFirstSliceDraft():
    CjguiInternalRendererStage209LayoutStyleFirstSliceReadiness {
    let decision =
        cjguiInternalExecuteDefaultRendererStage208ComponentDemoUiRunwayReadinessDecisionDraft()
    let valueFacts = cjguiInternalBuildRendererStage209LayoutStyleValueFacts()
    let facts = cjguiInternalBuildRendererStage209LayoutStyleFirstSliceFacts(
        decision,
        valueFacts
    )
    return cjguiInternalBuildRendererStage209LayoutStyleFirstSliceReadiness(
        decision,
        facts
    )
}
