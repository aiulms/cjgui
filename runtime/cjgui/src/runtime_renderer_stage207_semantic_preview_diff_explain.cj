// 中文维护注释：本文件是 stage207 semantic preview diff / explain owner。
// Owner: 消费 stage206 preview packet，生成 owner-local semantic diff、explain
// packet 与 rollback-ready preview boundary。
// Truth: diff/explain 是审计输入，不是 owner acceptance 或 visibility publication。
// Stop-line: 不接受变更，不发布 visibility，不写 renderer/runtime state。
package cjgui

struct CjguiInternalRendererStage207SemanticPreviewDiffExplainFacts {
    let didConsumeStage206ComponentDemoPreviewPacket: Bool
    let didMaterializeSemanticPreviewDiff: Bool
    let didMaterializeSemanticExplainPacket: Bool
    let didBindDiffToComponentDemoPreviewPacket: Bool
    let didBindExplainToRenderCommandAdmissionPreview: Bool
    let didMaterializeRollbackReadyPreviewBoundary: Bool
    let didKeepOwnerAcceptanceRequired: Bool
    let didPrepareStage208UiRunwayReadinessDecisionInput: Bool
    let didKeepVisibilityNotPublished: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool

    init(
        didConsumeStage206ComponentDemoPreviewPacket: Bool,
        didMaterializeSemanticPreviewDiff: Bool,
        didMaterializeSemanticExplainPacket: Bool,
        didBindDiffToComponentDemoPreviewPacket: Bool,
        didBindExplainToRenderCommandAdmissionPreview: Bool,
        didMaterializeRollbackReadyPreviewBoundary: Bool,
        didKeepOwnerAcceptanceRequired: Bool,
        didPrepareStage208UiRunwayReadinessDecisionInput: Bool,
        didKeepVisibilityNotPublished: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool
    ) {
        this.didConsumeStage206ComponentDemoPreviewPacket =
            didConsumeStage206ComponentDemoPreviewPacket
        this.didMaterializeSemanticPreviewDiff =
            didMaterializeSemanticPreviewDiff
        this.didMaterializeSemanticExplainPacket =
            didMaterializeSemanticExplainPacket
        this.didBindDiffToComponentDemoPreviewPacket =
            didBindDiffToComponentDemoPreviewPacket
        this.didBindExplainToRenderCommandAdmissionPreview =
            didBindExplainToRenderCommandAdmissionPreview
        this.didMaterializeRollbackReadyPreviewBoundary =
            didMaterializeRollbackReadyPreviewBoundary
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didPrepareStage208UiRunwayReadinessDecisionInput =
            didPrepareStage208UiRunwayReadinessDecisionInput
        this.didKeepVisibilityNotPublished = didKeepVisibilityNotPublished
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didKeepPublicComponentApiBlocked =
            didKeepPublicComponentApiBlocked
    }
}

struct CjguiInternalRendererStage207SemanticPreviewDiffExplainReadiness {
    let componentDemoPreviewPacket:
        CjguiInternalRendererStage206ComponentDemoPreviewPacketReadiness
    let semanticPreviewDiffExplainFacts:
        CjguiInternalRendererStage207SemanticPreviewDiffExplainFacts
    let didPrepareStage207SemanticPreviewDiffExplainReadiness: Bool
    let didConfirmSemanticPreviewDiffExplainReady: Bool
    let didConfirmSemanticPreviewDiffMaterialized: Bool
    let didConfirmSemanticExplainPacketMaterialized: Bool
    let didConfirmRollbackReadyPreviewBoundaryMaterialized: Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmStage208UiRunwayReadinessDecisionInputPrepared: Bool
    let didConfirmVisibilityPublished: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmPublicComponentApiAdded: Bool

    init(
        componentDemoPreviewPacket:
            CjguiInternalRendererStage206ComponentDemoPreviewPacketReadiness,
        semanticPreviewDiffExplainFacts:
            CjguiInternalRendererStage207SemanticPreviewDiffExplainFacts,
        didPrepareStage207SemanticPreviewDiffExplainReadiness: Bool,
        didConfirmSemanticPreviewDiffExplainReady: Bool,
        didConfirmSemanticPreviewDiffMaterialized: Bool,
        didConfirmSemanticExplainPacketMaterialized: Bool,
        didConfirmRollbackReadyPreviewBoundaryMaterialized: Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmStage208UiRunwayReadinessDecisionInputPrepared: Bool,
        didConfirmVisibilityPublished: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmPublicComponentApiAdded: Bool
    ) {
        this.componentDemoPreviewPacket = componentDemoPreviewPacket
        this.semanticPreviewDiffExplainFacts = semanticPreviewDiffExplainFacts
        this.didPrepareStage207SemanticPreviewDiffExplainReadiness =
            didPrepareStage207SemanticPreviewDiffExplainReadiness
        this.didConfirmSemanticPreviewDiffExplainReady =
            didConfirmSemanticPreviewDiffExplainReady
        this.didConfirmSemanticPreviewDiffMaterialized =
            didConfirmSemanticPreviewDiffMaterialized
        this.didConfirmSemanticExplainPacketMaterialized =
            didConfirmSemanticExplainPacketMaterialized
        this.didConfirmRollbackReadyPreviewBoundaryMaterialized =
            didConfirmRollbackReadyPreviewBoundaryMaterialized
        this.didConfirmOwnerAcceptanceRequired =
            didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted = didConfirmOwnerAcceptanceGranted
        this.didConfirmStage208UiRunwayReadinessDecisionInputPrepared =
            didConfirmStage208UiRunwayReadinessDecisionInputPrepared
        this.didConfirmVisibilityPublished = didConfirmVisibilityPublished
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked =
            didConfirmRuntimeStateWriteBlocked
        this.didConfirmPublicComponentApiAdded = didConfirmPublicComponentApiAdded
    }
}

func cjguiInternalBuildRendererStage207SemanticPreviewDiffExplainFacts(
    componentDemoPreviewPacket:
        CjguiInternalRendererStage206ComponentDemoPreviewPacketReadiness
): CjguiInternalRendererStage207SemanticPreviewDiffExplainFacts {
    return CjguiInternalRendererStage207SemanticPreviewDiffExplainFacts(
        componentDemoPreviewPacket.didConfirmComponentDemoPreviewPacketReady,
        true,
        true,
        componentDemoPreviewPacket
            .didConfirmComponentDemoPreviewPacketMaterialized,
        componentDemoPreviewPacket
            .componentDemoRenderCommandAdmission
            .didConfirmRenderCommandAdmissionPreviewMaterialized,
        componentDemoPreviewPacket
            .didConfirmPreviewBoundToOwnerLocalRollbackBoundary,
        true,
        true,
        componentDemoPreviewPacket.didConfirmPreviewVisibilityPublished == false,
        componentDemoPreviewPacket.didConfirmRendererStateWriteBlocked,
        componentDemoPreviewPacket.didConfirmRuntimeStateWriteBlocked,
        componentDemoPreviewPacket.didConfirmPublicComponentApiAdded == false
    )
}

func cjguiInternalBuildRendererStage207SemanticPreviewDiffExplainReadiness(
    componentDemoPreviewPacket:
        CjguiInternalRendererStage206ComponentDemoPreviewPacketReadiness,
    semanticPreviewDiffExplainFacts:
        CjguiInternalRendererStage207SemanticPreviewDiffExplainFacts
): CjguiInternalRendererStage207SemanticPreviewDiffExplainReadiness {
    let diffExplainReady =
        semanticPreviewDiffExplainFacts
            .didConsumeStage206ComponentDemoPreviewPacket &&
        semanticPreviewDiffExplainFacts.didMaterializeSemanticPreviewDiff &&
        semanticPreviewDiffExplainFacts.didMaterializeSemanticExplainPacket &&
        semanticPreviewDiffExplainFacts
            .didBindDiffToComponentDemoPreviewPacket &&
        semanticPreviewDiffExplainFacts
            .didBindExplainToRenderCommandAdmissionPreview &&
        semanticPreviewDiffExplainFacts
            .didMaterializeRollbackReadyPreviewBoundary &&
        semanticPreviewDiffExplainFacts.didKeepOwnerAcceptanceRequired &&
        semanticPreviewDiffExplainFacts
            .didPrepareStage208UiRunwayReadinessDecisionInput
    let stopLineReady =
        semanticPreviewDiffExplainFacts.didKeepVisibilityNotPublished &&
        semanticPreviewDiffExplainFacts.didKeepRendererStateWriteBlocked &&
        semanticPreviewDiffExplainFacts.didKeepRuntimeStateWriteBlocked &&
        semanticPreviewDiffExplainFacts.didKeepPublicComponentApiBlocked

    return CjguiInternalRendererStage207SemanticPreviewDiffExplainReadiness(
        componentDemoPreviewPacket,
        semanticPreviewDiffExplainFacts,
        diffExplainReady && stopLineReady,
        diffExplainReady && stopLineReady,
        semanticPreviewDiffExplainFacts.didMaterializeSemanticPreviewDiff,
        semanticPreviewDiffExplainFacts.didMaterializeSemanticExplainPacket,
        semanticPreviewDiffExplainFacts
            .didMaterializeRollbackReadyPreviewBoundary,
        semanticPreviewDiffExplainFacts.didKeepOwnerAcceptanceRequired,
        false,
        semanticPreviewDiffExplainFacts
            .didPrepareStage208UiRunwayReadinessDecisionInput,
        false,
        semanticPreviewDiffExplainFacts.didKeepRendererStateWriteBlocked,
        semanticPreviewDiffExplainFacts.didKeepRuntimeStateWriteBlocked,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage207SemanticPreviewDiffExplainDraft():
    CjguiInternalRendererStage207SemanticPreviewDiffExplainReadiness {
    let previewPacket =
        cjguiInternalExecuteDefaultRendererStage206ComponentDemoPreviewPacketDraft()
    let facts = cjguiInternalBuildRendererStage207SemanticPreviewDiffExplainFacts(
        previewPacket
    )
    return cjguiInternalBuildRendererStage207SemanticPreviewDiffExplainReadiness(
        previewPacket,
        facts
    )
}
