// 中文维护注释：本文件是 stage211 layout/style semantic diff / explain owner。
// Owner: 消费 stage210 styled preview packet，生成 layout/style diff、explain
// packet 与 style rollback-ready boundary。
// Truth: diff/explain 是 owner acceptance 输入，不发布 visibility。
// Stop-line: 不接受预览，不启用 layout engine，不写 renderer/runtime state。
package cjgui

struct CjguiInternalRendererStage211LayoutStyleSemanticDiffExplainFacts {
    let didConsumeStage210StyledComponentPreviewPacket: Bool
    let didMaterializeLayoutStyleSemanticDiff: Bool
    let didMaterializeLayoutStyleExplainPacket: Bool
    let didBindDiffToStyledComponentPreviewPacket: Bool
    let didBindExplainToLayoutStyleValueFacts: Bool
    let didMaterializeStyleRollbackReadyBoundary: Bool
    let didKeepOwnerAcceptanceRequired: Bool
    let didPrepareStage212UiFrameworkRunwayReadinessDecisionInput: Bool
    let didKeepVisibilityNotPublished: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepLayoutEngineBlocked: Bool

    init(
        didConsumeStage210StyledComponentPreviewPacket: Bool,
        didMaterializeLayoutStyleSemanticDiff: Bool,
        didMaterializeLayoutStyleExplainPacket: Bool,
        didBindDiffToStyledComponentPreviewPacket: Bool,
        didBindExplainToLayoutStyleValueFacts: Bool,
        didMaterializeStyleRollbackReadyBoundary: Bool,
        didKeepOwnerAcceptanceRequired: Bool,
        didPrepareStage212UiFrameworkRunwayReadinessDecisionInput: Bool,
        didKeepVisibilityNotPublished: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepLayoutEngineBlocked: Bool
    ) {
        this.didConsumeStage210StyledComponentPreviewPacket =
            didConsumeStage210StyledComponentPreviewPacket
        this.didMaterializeLayoutStyleSemanticDiff =
            didMaterializeLayoutStyleSemanticDiff
        this.didMaterializeLayoutStyleExplainPacket =
            didMaterializeLayoutStyleExplainPacket
        this.didBindDiffToStyledComponentPreviewPacket =
            didBindDiffToStyledComponentPreviewPacket
        this.didBindExplainToLayoutStyleValueFacts =
            didBindExplainToLayoutStyleValueFacts
        this.didMaterializeStyleRollbackReadyBoundary =
            didMaterializeStyleRollbackReadyBoundary
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didPrepareStage212UiFrameworkRunwayReadinessDecisionInput =
            didPrepareStage212UiFrameworkRunwayReadinessDecisionInput
        this.didKeepVisibilityNotPublished = didKeepVisibilityNotPublished
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didKeepPublicComponentApiBlocked =
            didKeepPublicComponentApiBlocked
        this.didKeepLayoutEngineBlocked = didKeepLayoutEngineBlocked
    }
}

struct CjguiInternalRendererStage211LayoutStyleSemanticDiffExplainReadiness {
    let styledComponentPreviewPacket:
        CjguiInternalRendererStage210StyledComponentPreviewPacketReadiness
    let layoutStyleSemanticDiffExplainFacts:
        CjguiInternalRendererStage211LayoutStyleSemanticDiffExplainFacts
    let didPrepareStage211LayoutStyleSemanticDiffExplainReadiness: Bool
    let didConfirmLayoutStyleSemanticDiffExplainReady: Bool
    let didConfirmLayoutStyleSemanticDiffMaterialized: Bool
    let didConfirmLayoutStyleExplainPacketMaterialized: Bool
    let didConfirmStyleRollbackReadyBoundaryMaterialized: Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmStage212UiFrameworkRunwayReadinessDecisionInputPrepared:
        Bool
    let didConfirmVisibilityPublished: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmLayoutEngineEnabled: Bool

    init(
        styledComponentPreviewPacket:
            CjguiInternalRendererStage210StyledComponentPreviewPacketReadiness,
        layoutStyleSemanticDiffExplainFacts:
            CjguiInternalRendererStage211LayoutStyleSemanticDiffExplainFacts,
        didPrepareStage211LayoutStyleSemanticDiffExplainReadiness: Bool,
        didConfirmLayoutStyleSemanticDiffExplainReady: Bool,
        didConfirmLayoutStyleSemanticDiffMaterialized: Bool,
        didConfirmLayoutStyleExplainPacketMaterialized: Bool,
        didConfirmStyleRollbackReadyBoundaryMaterialized: Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmStage212UiFrameworkRunwayReadinessDecisionInputPrepared:
            Bool,
        didConfirmVisibilityPublished: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmLayoutEngineEnabled: Bool
    ) {
        this.styledComponentPreviewPacket = styledComponentPreviewPacket
        this.layoutStyleSemanticDiffExplainFacts =
            layoutStyleSemanticDiffExplainFacts
        this.didPrepareStage211LayoutStyleSemanticDiffExplainReadiness =
            didPrepareStage211LayoutStyleSemanticDiffExplainReadiness
        this.didConfirmLayoutStyleSemanticDiffExplainReady =
            didConfirmLayoutStyleSemanticDiffExplainReady
        this.didConfirmLayoutStyleSemanticDiffMaterialized =
            didConfirmLayoutStyleSemanticDiffMaterialized
        this.didConfirmLayoutStyleExplainPacketMaterialized =
            didConfirmLayoutStyleExplainPacketMaterialized
        this.didConfirmStyleRollbackReadyBoundaryMaterialized =
            didConfirmStyleRollbackReadyBoundaryMaterialized
        this.didConfirmOwnerAcceptanceRequired =
            didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted = didConfirmOwnerAcceptanceGranted
        this.didConfirmStage212UiFrameworkRunwayReadinessDecisionInputPrepared =
            didConfirmStage212UiFrameworkRunwayReadinessDecisionInputPrepared
        this.didConfirmVisibilityPublished = didConfirmVisibilityPublished
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked =
            didConfirmRuntimeStateWriteBlocked
        this.didConfirmPublicComponentApiAdded =
            didConfirmPublicComponentApiAdded
        this.didConfirmLayoutEngineEnabled = didConfirmLayoutEngineEnabled
    }
}

func cjguiInternalBuildRendererStage211LayoutStyleSemanticDiffExplainFacts(
    styledComponentPreviewPacket:
        CjguiInternalRendererStage210StyledComponentPreviewPacketReadiness
): CjguiInternalRendererStage211LayoutStyleSemanticDiffExplainFacts {
    return CjguiInternalRendererStage211LayoutStyleSemanticDiffExplainFacts(
        styledComponentPreviewPacket
            .didConfirmStyledComponentPreviewPacketReady,
        true,
        true,
        styledComponentPreviewPacket
            .didConfirmStyledComponentPreviewPacketMaterialized,
        styledComponentPreviewPacket
            .didConfirmLayoutStyleFactsJoinedWithPreviewPacket,
        styledComponentPreviewPacket
            .didConfirmButtonStyleBoundToOwnerLocalRollbackBoundary,
        true,
        true,
        styledComponentPreviewPacket.didConfirmVisibilityPublished == false,
        styledComponentPreviewPacket.didConfirmRendererStateWriteBlocked,
        styledComponentPreviewPacket.didConfirmRuntimeStateWriteBlocked,
        styledComponentPreviewPacket.didConfirmPublicComponentApiAdded == false,
        styledComponentPreviewPacket.didConfirmLayoutEngineEnabled == false
    )
}

func cjguiInternalBuildRendererStage211LayoutStyleSemanticDiffExplainReadiness(
    styledComponentPreviewPacket:
        CjguiInternalRendererStage210StyledComponentPreviewPacketReadiness,
    layoutStyleSemanticDiffExplainFacts:
        CjguiInternalRendererStage211LayoutStyleSemanticDiffExplainFacts
): CjguiInternalRendererStage211LayoutStyleSemanticDiffExplainReadiness {
    let diffExplainReady =
        layoutStyleSemanticDiffExplainFacts
            .didConsumeStage210StyledComponentPreviewPacket &&
        layoutStyleSemanticDiffExplainFacts
            .didMaterializeLayoutStyleSemanticDiff &&
        layoutStyleSemanticDiffExplainFacts
            .didMaterializeLayoutStyleExplainPacket &&
        layoutStyleSemanticDiffExplainFacts
            .didBindDiffToStyledComponentPreviewPacket &&
        layoutStyleSemanticDiffExplainFacts
            .didBindExplainToLayoutStyleValueFacts &&
        layoutStyleSemanticDiffExplainFacts
            .didMaterializeStyleRollbackReadyBoundary &&
        layoutStyleSemanticDiffExplainFacts.didKeepOwnerAcceptanceRequired &&
        layoutStyleSemanticDiffExplainFacts
            .didPrepareStage212UiFrameworkRunwayReadinessDecisionInput
    let stopLineReady =
        layoutStyleSemanticDiffExplainFacts.didKeepVisibilityNotPublished &&
        layoutStyleSemanticDiffExplainFacts.didKeepRendererStateWriteBlocked &&
        layoutStyleSemanticDiffExplainFacts.didKeepRuntimeStateWriteBlocked &&
        layoutStyleSemanticDiffExplainFacts.didKeepPublicComponentApiBlocked &&
        layoutStyleSemanticDiffExplainFacts.didKeepLayoutEngineBlocked

    return CjguiInternalRendererStage211LayoutStyleSemanticDiffExplainReadiness(
        styledComponentPreviewPacket,
        layoutStyleSemanticDiffExplainFacts,
        diffExplainReady && stopLineReady,
        diffExplainReady && stopLineReady,
        layoutStyleSemanticDiffExplainFacts
            .didMaterializeLayoutStyleSemanticDiff,
        layoutStyleSemanticDiffExplainFacts
            .didMaterializeLayoutStyleExplainPacket,
        layoutStyleSemanticDiffExplainFacts
            .didMaterializeStyleRollbackReadyBoundary,
        layoutStyleSemanticDiffExplainFacts.didKeepOwnerAcceptanceRequired,
        false,
        layoutStyleSemanticDiffExplainFacts
            .didPrepareStage212UiFrameworkRunwayReadinessDecisionInput,
        false,
        layoutStyleSemanticDiffExplainFacts.didKeepRendererStateWriteBlocked,
        layoutStyleSemanticDiffExplainFacts.didKeepRuntimeStateWriteBlocked,
        false,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage211LayoutStyleSemanticDiffExplainDraft():
    CjguiInternalRendererStage211LayoutStyleSemanticDiffExplainReadiness {
    let styledPreview =
        cjguiInternalExecuteDefaultRendererStage210StyledComponentPreviewPacketDraft()
    let facts =
        cjguiInternalBuildRendererStage211LayoutStyleSemanticDiffExplainFacts(
            styledPreview
        )
    return cjguiInternalBuildRendererStage211LayoutStyleSemanticDiffExplainReadiness(
        styledPreview,
        facts
    )
}
