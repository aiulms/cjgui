// 中文维护注释：本文件是 stage227 renderer submission semantic diff / explain owner。
// Owner: 消费 stage226 preview packet，生成 submission diff、explain 和 rollback boundary。
// Truth: diff/explain 是 owner acceptance 输入，不代表 owner 已接受。
// Stop-line: 不提交 renderer，不发布 visibility，不写 renderer/runtime state。
package cjgui

struct CjguiInternalRendererStage227RendererSubmissionSemanticDiffExplainFacts {
    let didConsumeStage226RendererSubmissionPreviewPacket: Bool
    let didMaterializeRendererSubmissionSemanticDiff: Bool
    let didMaterializeRendererSubmissionExplainPacket: Bool
    let didBindDiffToRendererSubmissionPreviewPacket: Bool
    let didBindExplainToRenderCommandRefreshSemanticDiff: Bool
    let didMaterializeRendererSubmissionRollbackReadyBoundary: Bool
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didPrepareStage228RendererSubmissionReadinessDecisionInput: Bool
    let didKeepVisibilityNotPublished: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool

    init(
        didConsumeStage226RendererSubmissionPreviewPacket: Bool,
        didMaterializeRendererSubmissionSemanticDiff: Bool,
        didMaterializeRendererSubmissionExplainPacket: Bool,
        didBindDiffToRendererSubmissionPreviewPacket: Bool,
        didBindExplainToRenderCommandRefreshSemanticDiff: Bool,
        didMaterializeRendererSubmissionRollbackReadyBoundary: Bool,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didPrepareStage228RendererSubmissionReadinessDecisionInput: Bool,
        didKeepVisibilityNotPublished: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool
    ) {
        this.didConsumeStage226RendererSubmissionPreviewPacket =
            didConsumeStage226RendererSubmissionPreviewPacket
        this.didMaterializeRendererSubmissionSemanticDiff =
            didMaterializeRendererSubmissionSemanticDiff
        this.didMaterializeRendererSubmissionExplainPacket =
            didMaterializeRendererSubmissionExplainPacket
        this.didBindDiffToRendererSubmissionPreviewPacket =
            didBindDiffToRendererSubmissionPreviewPacket
        this.didBindExplainToRenderCommandRefreshSemanticDiff =
            didBindExplainToRenderCommandRefreshSemanticDiff
        this.didMaterializeRendererSubmissionRollbackReadyBoundary =
            didMaterializeRendererSubmissionRollbackReadyBoundary
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didKeepOwnerAcceptanceNotGranted =
            didKeepOwnerAcceptanceNotGranted
        this.didPrepareStage228RendererSubmissionReadinessDecisionInput =
            didPrepareStage228RendererSubmissionReadinessDecisionInput
        this.didKeepVisibilityNotPublished = didKeepVisibilityNotPublished
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didKeepPublicComponentApiBlocked =
            didKeepPublicComponentApiBlocked
    }
}

struct CjguiInternalRendererStage227RendererSubmissionSemanticDiffExplainReadiness {
    let rendererSubmissionPreviewPacket:
        CjguiInternalRendererStage226RendererSubmissionPreviewPacketReadiness
    let rendererSubmissionSemanticDiffExplainFacts:
        CjguiInternalRendererStage227RendererSubmissionSemanticDiffExplainFacts
    let didPrepareStage227RendererSubmissionSemanticDiffExplainReadiness:
        Bool
    let didConfirmRendererSubmissionSemanticDiffExplainReady: Bool
    let didConfirmRendererSubmissionSemanticDiffMaterialized: Bool
    let didConfirmRendererSubmissionExplainPacketMaterialized: Bool
    let didConfirmRendererSubmissionRollbackReadyBoundaryMaterialized: Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmStage228RendererSubmissionReadinessDecisionInputPrepared:
        Bool
    let didConfirmVisibilityPublished: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmPublicComponentApiAdded: Bool

    init(
        rendererSubmissionPreviewPacket:
            CjguiInternalRendererStage226RendererSubmissionPreviewPacketReadiness,
        rendererSubmissionSemanticDiffExplainFacts:
            CjguiInternalRendererStage227RendererSubmissionSemanticDiffExplainFacts,
        didPrepareStage227RendererSubmissionSemanticDiffExplainReadiness:
            Bool,
        didConfirmRendererSubmissionSemanticDiffExplainReady: Bool,
        didConfirmRendererSubmissionSemanticDiffMaterialized: Bool,
        didConfirmRendererSubmissionExplainPacketMaterialized: Bool,
        didConfirmRendererSubmissionRollbackReadyBoundaryMaterialized: Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmStage228RendererSubmissionReadinessDecisionInputPrepared:
            Bool,
        didConfirmVisibilityPublished: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmPublicComponentApiAdded: Bool
    ) {
        this.rendererSubmissionPreviewPacket =
            rendererSubmissionPreviewPacket
        this.rendererSubmissionSemanticDiffExplainFacts =
            rendererSubmissionSemanticDiffExplainFacts
        this.didPrepareStage227RendererSubmissionSemanticDiffExplainReadiness =
            didPrepareStage227RendererSubmissionSemanticDiffExplainReadiness
        this.didConfirmRendererSubmissionSemanticDiffExplainReady =
            didConfirmRendererSubmissionSemanticDiffExplainReady
        this.didConfirmRendererSubmissionSemanticDiffMaterialized =
            didConfirmRendererSubmissionSemanticDiffMaterialized
        this.didConfirmRendererSubmissionExplainPacketMaterialized =
            didConfirmRendererSubmissionExplainPacketMaterialized
        this.didConfirmRendererSubmissionRollbackReadyBoundaryMaterialized =
            didConfirmRendererSubmissionRollbackReadyBoundaryMaterialized
        this.didConfirmOwnerAcceptanceRequired =
            didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted =
            didConfirmOwnerAcceptanceGranted
        this.didConfirmStage228RendererSubmissionReadinessDecisionInputPrepared =
            didConfirmStage228RendererSubmissionReadinessDecisionInputPrepared
        this.didConfirmVisibilityPublished = didConfirmVisibilityPublished
        this.didConfirmRendererSubmissionBlocked =
            didConfirmRendererSubmissionBlocked
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked =
            didConfirmRuntimeStateWriteBlocked
        this.didConfirmPublicComponentApiAdded =
            didConfirmPublicComponentApiAdded
    }
}

func cjguiInternalBuildRendererStage227RendererSubmissionSemanticDiffExplainFacts(
    rendererSubmissionPreviewPacket:
        CjguiInternalRendererStage226RendererSubmissionPreviewPacketReadiness
): CjguiInternalRendererStage227RendererSubmissionSemanticDiffExplainFacts {
    let refreshDecision = rendererSubmissionPreviewPacket
        .rendererSubmissionPreview.renderCommandRefreshReadinessDecision
    let refreshDiffExplain =
        refreshDecision.renderCommandRefreshSemanticDiffExplain

    return CjguiInternalRendererStage227RendererSubmissionSemanticDiffExplainFacts(
        rendererSubmissionPreviewPacket
            .didConfirmRendererSubmissionPreviewPacketReady,
        true,
        true,
        rendererSubmissionPreviewPacket
            .didConfirmRendererSubmissionPreviewPacketMaterialized,
        refreshDiffExplain
            .didConfirmRenderCommandRefreshSemanticDiffMaterialized &&
            refreshDiffExplain
                .didConfirmRenderCommandRefreshExplainPacketMaterialized,
        rendererSubmissionPreviewPacket
            .didConfirmPreviewPacketBoundToRollbackBoundary,
        rendererSubmissionPreviewPacket.didConfirmOwnerAcceptanceRequired,
        rendererSubmissionPreviewPacket.didConfirmOwnerAcceptanceGranted == false,
        true,
        rendererSubmissionPreviewPacket.didConfirmPreviewVisibilityPublished == false,
        rendererSubmissionPreviewPacket.didConfirmRendererSubmissionBlocked,
        rendererSubmissionPreviewPacket.didConfirmRendererStateWriteBlocked,
        rendererSubmissionPreviewPacket.didConfirmRuntimeStateWriteBlocked,
        rendererSubmissionPreviewPacket.didConfirmPublicComponentApiAdded == false
    )
}

func cjguiInternalBuildRendererStage227RendererSubmissionSemanticDiffExplainReadiness(
    rendererSubmissionPreviewPacket:
        CjguiInternalRendererStage226RendererSubmissionPreviewPacketReadiness,
    rendererSubmissionSemanticDiffExplainFacts:
        CjguiInternalRendererStage227RendererSubmissionSemanticDiffExplainFacts
): CjguiInternalRendererStage227RendererSubmissionSemanticDiffExplainReadiness {
    let diffExplainReady =
        rendererSubmissionSemanticDiffExplainFacts
            .didConsumeStage226RendererSubmissionPreviewPacket &&
        rendererSubmissionSemanticDiffExplainFacts
            .didMaterializeRendererSubmissionSemanticDiff &&
        rendererSubmissionSemanticDiffExplainFacts
            .didMaterializeRendererSubmissionExplainPacket &&
        rendererSubmissionSemanticDiffExplainFacts
            .didBindDiffToRendererSubmissionPreviewPacket &&
        rendererSubmissionSemanticDiffExplainFacts
            .didBindExplainToRenderCommandRefreshSemanticDiff &&
        rendererSubmissionSemanticDiffExplainFacts
            .didMaterializeRendererSubmissionRollbackReadyBoundary &&
        rendererSubmissionSemanticDiffExplainFacts.didKeepOwnerAcceptanceRequired &&
        rendererSubmissionSemanticDiffExplainFacts
            .didPrepareStage228RendererSubmissionReadinessDecisionInput
    let stopLineReady =
        rendererSubmissionSemanticDiffExplainFacts
            .didKeepOwnerAcceptanceNotGranted &&
        rendererSubmissionSemanticDiffExplainFacts.didKeepVisibilityNotPublished &&
        rendererSubmissionSemanticDiffExplainFacts.didKeepRendererSubmissionBlocked &&
        rendererSubmissionSemanticDiffExplainFacts.didKeepRendererStateWriteBlocked &&
        rendererSubmissionSemanticDiffExplainFacts.didKeepRuntimeStateWriteBlocked &&
        rendererSubmissionSemanticDiffExplainFacts.didKeepPublicComponentApiBlocked

    return CjguiInternalRendererStage227RendererSubmissionSemanticDiffExplainReadiness(
        rendererSubmissionPreviewPacket,
        rendererSubmissionSemanticDiffExplainFacts,
        diffExplainReady && stopLineReady,
        diffExplainReady && stopLineReady,
        rendererSubmissionSemanticDiffExplainFacts
            .didMaterializeRendererSubmissionSemanticDiff,
        rendererSubmissionSemanticDiffExplainFacts
            .didMaterializeRendererSubmissionExplainPacket,
        rendererSubmissionSemanticDiffExplainFacts
            .didMaterializeRendererSubmissionRollbackReadyBoundary,
        rendererSubmissionSemanticDiffExplainFacts.didKeepOwnerAcceptanceRequired,
        false,
        rendererSubmissionSemanticDiffExplainFacts
            .didPrepareStage228RendererSubmissionReadinessDecisionInput,
        false,
        rendererSubmissionSemanticDiffExplainFacts.didKeepRendererSubmissionBlocked,
        rendererSubmissionSemanticDiffExplainFacts.didKeepRendererStateWriteBlocked,
        rendererSubmissionSemanticDiffExplainFacts.didKeepRuntimeStateWriteBlocked,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage227RendererSubmissionSemanticDiffExplainDraft():
    CjguiInternalRendererStage227RendererSubmissionSemanticDiffExplainReadiness {
    let previewPacket =
        cjguiInternalExecuteDefaultRendererStage226RendererSubmissionPreviewPacketDraft()
    let facts =
        cjguiInternalBuildRendererStage227RendererSubmissionSemanticDiffExplainFacts(
            previewPacket
        )
    return cjguiInternalBuildRendererStage227RendererSubmissionSemanticDiffExplainReadiness(
        previewPacket,
        facts
    )
}
