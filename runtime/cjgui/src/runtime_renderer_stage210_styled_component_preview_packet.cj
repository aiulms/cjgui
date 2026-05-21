// 中文维护注释：本文件是 stage210 styled component preview packet owner。
// Owner: 消费 stage209 layout/style first-slice，把 style facts 绑定到
// stage206 component demo preview packet。
// Truth: styled preview packet 仍是 owner-local 可回滚预览，不是 renderer submit。
// Stop-line: 不发布 visibility，不扩 public component API，不写 renderer/runtime state。
package cjgui

struct CjguiInternalRendererStage210StyledComponentPreviewPacketFacts {
    let didConsumeStage209LayoutStyleFirstSlice: Bool
    let didJoinLayoutStyleFactsWithComponentDemoPreviewPacket: Bool
    let didMaterializeStyledComponentPreviewPacket: Bool
    let didBindRectLayoutToRenderCommandAdmissionPreview: Bool
    let didBindTextTypographyToSemanticExplainPacket: Bool
    let didBindButtonStyleToOwnerLocalRollbackBoundary: Bool
    let didPreserveRenderCommandPacketBackendAgnostic: Bool
    let didPrepareStage211LayoutStyleSemanticDiffInput: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepLayoutEngineBlocked: Bool
    let didKeepVisibilityNotPublished: Bool

    init(
        didConsumeStage209LayoutStyleFirstSlice: Bool,
        didJoinLayoutStyleFactsWithComponentDemoPreviewPacket: Bool,
        didMaterializeStyledComponentPreviewPacket: Bool,
        didBindRectLayoutToRenderCommandAdmissionPreview: Bool,
        didBindTextTypographyToSemanticExplainPacket: Bool,
        didBindButtonStyleToOwnerLocalRollbackBoundary: Bool,
        didPreserveRenderCommandPacketBackendAgnostic: Bool,
        didPrepareStage211LayoutStyleSemanticDiffInput: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepLayoutEngineBlocked: Bool,
        didKeepVisibilityNotPublished: Bool
    ) {
        this.didConsumeStage209LayoutStyleFirstSlice =
            didConsumeStage209LayoutStyleFirstSlice
        this.didJoinLayoutStyleFactsWithComponentDemoPreviewPacket =
            didJoinLayoutStyleFactsWithComponentDemoPreviewPacket
        this.didMaterializeStyledComponentPreviewPacket =
            didMaterializeStyledComponentPreviewPacket
        this.didBindRectLayoutToRenderCommandAdmissionPreview =
            didBindRectLayoutToRenderCommandAdmissionPreview
        this.didBindTextTypographyToSemanticExplainPacket =
            didBindTextTypographyToSemanticExplainPacket
        this.didBindButtonStyleToOwnerLocalRollbackBoundary =
            didBindButtonStyleToOwnerLocalRollbackBoundary
        this.didPreserveRenderCommandPacketBackendAgnostic =
            didPreserveRenderCommandPacketBackendAgnostic
        this.didPrepareStage211LayoutStyleSemanticDiffInput =
            didPrepareStage211LayoutStyleSemanticDiffInput
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

struct CjguiInternalRendererStage210StyledComponentPreviewPacketReadiness {
    let layoutStyleFirstSlice:
        CjguiInternalRendererStage209LayoutStyleFirstSliceReadiness
    let styledComponentPreviewPacketFacts:
        CjguiInternalRendererStage210StyledComponentPreviewPacketFacts
    let didPrepareStage210StyledComponentPreviewPacketReadiness: Bool
    let didConfirmStyledComponentPreviewPacketReady: Bool
    let didConfirmLayoutStyleFactsJoinedWithPreviewPacket: Bool
    let didConfirmStyledComponentPreviewPacketMaterialized: Bool
    let didConfirmRectLayoutBoundToRenderCommandAdmissionPreview: Bool
    let didConfirmTextTypographyBoundToSemanticExplainPacket: Bool
    let didConfirmButtonStyleBoundToOwnerLocalRollbackBoundary: Bool
    let didConfirmStage211LayoutStyleSemanticDiffInputPrepared: Bool
    let didConfirmVisibilityPublished: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmLayoutEngineEnabled: Bool

    init(
        layoutStyleFirstSlice:
            CjguiInternalRendererStage209LayoutStyleFirstSliceReadiness,
        styledComponentPreviewPacketFacts:
            CjguiInternalRendererStage210StyledComponentPreviewPacketFacts,
        didPrepareStage210StyledComponentPreviewPacketReadiness: Bool,
        didConfirmStyledComponentPreviewPacketReady: Bool,
        didConfirmLayoutStyleFactsJoinedWithPreviewPacket: Bool,
        didConfirmStyledComponentPreviewPacketMaterialized: Bool,
        didConfirmRectLayoutBoundToRenderCommandAdmissionPreview: Bool,
        didConfirmTextTypographyBoundToSemanticExplainPacket: Bool,
        didConfirmButtonStyleBoundToOwnerLocalRollbackBoundary: Bool,
        didConfirmStage211LayoutStyleSemanticDiffInputPrepared: Bool,
        didConfirmVisibilityPublished: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmLayoutEngineEnabled: Bool
    ) {
        this.layoutStyleFirstSlice = layoutStyleFirstSlice
        this.styledComponentPreviewPacketFacts =
            styledComponentPreviewPacketFacts
        this.didPrepareStage210StyledComponentPreviewPacketReadiness =
            didPrepareStage210StyledComponentPreviewPacketReadiness
        this.didConfirmStyledComponentPreviewPacketReady =
            didConfirmStyledComponentPreviewPacketReady
        this.didConfirmLayoutStyleFactsJoinedWithPreviewPacket =
            didConfirmLayoutStyleFactsJoinedWithPreviewPacket
        this.didConfirmStyledComponentPreviewPacketMaterialized =
            didConfirmStyledComponentPreviewPacketMaterialized
        this.didConfirmRectLayoutBoundToRenderCommandAdmissionPreview =
            didConfirmRectLayoutBoundToRenderCommandAdmissionPreview
        this.didConfirmTextTypographyBoundToSemanticExplainPacket =
            didConfirmTextTypographyBoundToSemanticExplainPacket
        this.didConfirmButtonStyleBoundToOwnerLocalRollbackBoundary =
            didConfirmButtonStyleBoundToOwnerLocalRollbackBoundary
        this.didConfirmStage211LayoutStyleSemanticDiffInputPrepared =
            didConfirmStage211LayoutStyleSemanticDiffInputPrepared
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

func cjguiInternalBuildRendererStage210StyledComponentPreviewPacketFacts(
    layoutStyleFirstSlice:
        CjguiInternalRendererStage209LayoutStyleFirstSliceReadiness
): CjguiInternalRendererStage210StyledComponentPreviewPacketFacts {
    let uiDecision =
        layoutStyleFirstSlice.componentDemoUiRunwayReadinessDecision
    let semanticDiffExplain = uiDecision.semanticPreviewDiffExplain
    let previewPacket = semanticDiffExplain.componentDemoPreviewPacket
    let admission = previewPacket.componentDemoRenderCommandAdmission

    return CjguiInternalRendererStage210StyledComponentPreviewPacketFacts(
        layoutStyleFirstSlice.didConfirmLayoutStyleFirstSliceReady,
        layoutStyleFirstSlice
            .didConfirmLayoutStyleFactsBoundToComponentDemoPreviewPacket &&
            previewPacket.didConfirmComponentDemoPreviewPacketMaterialized,
        true,
        layoutStyleFirstSlice.didConfirmRectLayoutValueFactsMaterialized &&
            admission.didConfirmRenderCommandAdmissionPreviewMaterialized,
        layoutStyleFirstSlice.didConfirmTextTypographyValueFactsMaterialized &&
            semanticDiffExplain.didConfirmSemanticExplainPacketMaterialized,
        layoutStyleFirstSlice.didConfirmButtonStyleValueFactsMaterialized &&
            previewPacket.didConfirmPreviewBoundToOwnerLocalRollbackBoundary,
        admission.renderCommandPacket.didKeepCommandPacketRendererAgnostic &&
            previewPacket.renderBatchingPacket
                .didKeepBatchingPacketRendererAgnostic,
        true,
        layoutStyleFirstSlice.didConfirmRendererSubmissionBlocked,
        layoutStyleFirstSlice.didConfirmRendererStateWriteBlocked,
        layoutStyleFirstSlice.didConfirmRuntimeStateWriteBlocked,
        layoutStyleFirstSlice.didConfirmPublicComponentApiAdded == false,
        layoutStyleFirstSlice.didConfirmLayoutEngineEnabled == false,
        layoutStyleFirstSlice.didConfirmVisibilityPublished == false
    )
}

func cjguiInternalBuildRendererStage210StyledComponentPreviewPacketReadiness(
    layoutStyleFirstSlice:
        CjguiInternalRendererStage209LayoutStyleFirstSliceReadiness,
    styledComponentPreviewPacketFacts:
        CjguiInternalRendererStage210StyledComponentPreviewPacketFacts
): CjguiInternalRendererStage210StyledComponentPreviewPacketReadiness {
    let previewReady =
        styledComponentPreviewPacketFacts
            .didConsumeStage209LayoutStyleFirstSlice &&
        styledComponentPreviewPacketFacts
            .didJoinLayoutStyleFactsWithComponentDemoPreviewPacket &&
        styledComponentPreviewPacketFacts
            .didMaterializeStyledComponentPreviewPacket &&
        styledComponentPreviewPacketFacts
            .didBindRectLayoutToRenderCommandAdmissionPreview &&
        styledComponentPreviewPacketFacts
            .didBindTextTypographyToSemanticExplainPacket &&
        styledComponentPreviewPacketFacts
            .didBindButtonStyleToOwnerLocalRollbackBoundary &&
        styledComponentPreviewPacketFacts
            .didPreserveRenderCommandPacketBackendAgnostic &&
        styledComponentPreviewPacketFacts
            .didPrepareStage211LayoutStyleSemanticDiffInput
    let stopLineReady =
        styledComponentPreviewPacketFacts.didKeepRendererSubmissionBlocked &&
        styledComponentPreviewPacketFacts.didKeepRendererStateWriteBlocked &&
        styledComponentPreviewPacketFacts.didKeepRuntimeStateWriteBlocked &&
        styledComponentPreviewPacketFacts.didKeepPublicComponentApiBlocked &&
        styledComponentPreviewPacketFacts.didKeepLayoutEngineBlocked &&
        styledComponentPreviewPacketFacts.didKeepVisibilityNotPublished

    return CjguiInternalRendererStage210StyledComponentPreviewPacketReadiness(
        layoutStyleFirstSlice,
        styledComponentPreviewPacketFacts,
        previewReady && stopLineReady,
        previewReady && stopLineReady,
        styledComponentPreviewPacketFacts
            .didJoinLayoutStyleFactsWithComponentDemoPreviewPacket,
        styledComponentPreviewPacketFacts
            .didMaterializeStyledComponentPreviewPacket,
        styledComponentPreviewPacketFacts
            .didBindRectLayoutToRenderCommandAdmissionPreview,
        styledComponentPreviewPacketFacts
            .didBindTextTypographyToSemanticExplainPacket,
        styledComponentPreviewPacketFacts
            .didBindButtonStyleToOwnerLocalRollbackBoundary,
        styledComponentPreviewPacketFacts
            .didPrepareStage211LayoutStyleSemanticDiffInput,
        false,
        styledComponentPreviewPacketFacts.didKeepRendererSubmissionBlocked,
        styledComponentPreviewPacketFacts.didKeepRendererStateWriteBlocked,
        styledComponentPreviewPacketFacts.didKeepRuntimeStateWriteBlocked,
        false,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage210StyledComponentPreviewPacketDraft():
    CjguiInternalRendererStage210StyledComponentPreviewPacketReadiness {
    let firstSlice =
        cjguiInternalExecuteDefaultRendererStage209LayoutStyleFirstSliceDraft()
    let facts =
        cjguiInternalBuildRendererStage210StyledComponentPreviewPacketFacts(
            firstSlice
        )
    return cjguiInternalBuildRendererStage210StyledComponentPreviewPacketReadiness(
        firstSlice,
        facts
    )
}
