// 中文维护注释：本文件是 stage223 render-command refresh semantic diff / explain owner。
// Owner: 消费 refreshed preview packet，生成 command refresh diff、explain 和 rollback boundary。
// Truth: diff/explain 只是 owner acceptance 输入，不代表 owner 已接受。
// Stop-line: 不提交状态，不提交 renderer，不写 renderer/runtime state。
package cjgui

struct CjguiInternalRendererStage223RenderCommandRefreshSemanticDiffExplainFacts {
    let didConsumeStage222RefreshedRenderCommandPreviewPacket: Bool
    let didMaterializeRenderCommandRefreshSemanticDiff: Bool
    let didMaterializeRenderCommandRefreshExplainPacket: Bool
    let didBindDiffToRefreshedPreviewPacket: Bool
    let didBindExplainToStateUpdateSemanticDiff: Bool
    let didMaterializeRenderCommandRefreshRollbackReadyBoundary: Bool
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didPrepareStage224RenderCommandRefreshReadinessDecisionInput: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepVisibilityNotPublished: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool

    init(
        didConsumeStage222RefreshedRenderCommandPreviewPacket: Bool,
        didMaterializeRenderCommandRefreshSemanticDiff: Bool,
        didMaterializeRenderCommandRefreshExplainPacket: Bool,
        didBindDiffToRefreshedPreviewPacket: Bool,
        didBindExplainToStateUpdateSemanticDiff: Bool,
        didMaterializeRenderCommandRefreshRollbackReadyBoundary: Bool,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didPrepareStage224RenderCommandRefreshReadinessDecisionInput: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepVisibilityNotPublished: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool
    ) {
        this.didConsumeStage222RefreshedRenderCommandPreviewPacket =
            didConsumeStage222RefreshedRenderCommandPreviewPacket
        this.didMaterializeRenderCommandRefreshSemanticDiff =
            didMaterializeRenderCommandRefreshSemanticDiff
        this.didMaterializeRenderCommandRefreshExplainPacket =
            didMaterializeRenderCommandRefreshExplainPacket
        this.didBindDiffToRefreshedPreviewPacket =
            didBindDiffToRefreshedPreviewPacket
        this.didBindExplainToStateUpdateSemanticDiff =
            didBindExplainToStateUpdateSemanticDiff
        this.didMaterializeRenderCommandRefreshRollbackReadyBoundary =
            didMaterializeRenderCommandRefreshRollbackReadyBoundary
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didKeepOwnerAcceptanceNotGranted =
            didKeepOwnerAcceptanceNotGranted
        this.didPrepareStage224RenderCommandRefreshReadinessDecisionInput =
            didPrepareStage224RenderCommandRefreshReadinessDecisionInput
        this.didKeepStateUpdateCommittedBlocked =
            didKeepStateUpdateCommittedBlocked
        this.didKeepVisibilityNotPublished = didKeepVisibilityNotPublished
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didKeepPublicComponentApiBlocked =
            didKeepPublicComponentApiBlocked
    }
}

struct CjguiInternalRendererStage223RenderCommandRefreshSemanticDiffExplainReadiness {
    let refreshedRenderCommandPreviewPacket:
        CjguiInternalRendererStage222RefreshedRenderCommandPreviewPacketReadiness
    let renderCommandRefreshSemanticDiffExplainFacts:
        CjguiInternalRendererStage223RenderCommandRefreshSemanticDiffExplainFacts
    let didPrepareStage223RenderCommandRefreshSemanticDiffExplainReadiness:
        Bool
    let didConfirmRenderCommandRefreshSemanticDiffExplainReady: Bool
    let didConfirmRenderCommandRefreshSemanticDiffMaterialized: Bool
    let didConfirmRenderCommandRefreshExplainPacketMaterialized: Bool
    let didConfirmRenderCommandRefreshRollbackReadyBoundaryMaterialized:
        Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmStage224RenderCommandRefreshReadinessDecisionInputPrepared:
        Bool
    let didConfirmStateUpdateCommitted: Bool
    let didConfirmVisibilityPublished: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmPublicComponentApiAdded: Bool

    init(
        refreshedRenderCommandPreviewPacket:
            CjguiInternalRendererStage222RefreshedRenderCommandPreviewPacketReadiness,
        renderCommandRefreshSemanticDiffExplainFacts:
            CjguiInternalRendererStage223RenderCommandRefreshSemanticDiffExplainFacts,
        didPrepareStage223RenderCommandRefreshSemanticDiffExplainReadiness:
            Bool,
        didConfirmRenderCommandRefreshSemanticDiffExplainReady: Bool,
        didConfirmRenderCommandRefreshSemanticDiffMaterialized: Bool,
        didConfirmRenderCommandRefreshExplainPacketMaterialized: Bool,
        didConfirmRenderCommandRefreshRollbackReadyBoundaryMaterialized:
            Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmStage224RenderCommandRefreshReadinessDecisionInputPrepared:
            Bool,
        didConfirmStateUpdateCommitted: Bool,
        didConfirmVisibilityPublished: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmPublicComponentApiAdded: Bool
    ) {
        this.refreshedRenderCommandPreviewPacket =
            refreshedRenderCommandPreviewPacket
        this.renderCommandRefreshSemanticDiffExplainFacts =
            renderCommandRefreshSemanticDiffExplainFacts
        this.didPrepareStage223RenderCommandRefreshSemanticDiffExplainReadiness =
            didPrepareStage223RenderCommandRefreshSemanticDiffExplainReadiness
        this.didConfirmRenderCommandRefreshSemanticDiffExplainReady =
            didConfirmRenderCommandRefreshSemanticDiffExplainReady
        this.didConfirmRenderCommandRefreshSemanticDiffMaterialized =
            didConfirmRenderCommandRefreshSemanticDiffMaterialized
        this.didConfirmRenderCommandRefreshExplainPacketMaterialized =
            didConfirmRenderCommandRefreshExplainPacketMaterialized
        this.didConfirmRenderCommandRefreshRollbackReadyBoundaryMaterialized =
            didConfirmRenderCommandRefreshRollbackReadyBoundaryMaterialized
        this.didConfirmOwnerAcceptanceRequired =
            didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted =
            didConfirmOwnerAcceptanceGranted
        this.didConfirmStage224RenderCommandRefreshReadinessDecisionInputPrepared =
            didConfirmStage224RenderCommandRefreshReadinessDecisionInputPrepared
        this.didConfirmStateUpdateCommitted = didConfirmStateUpdateCommitted
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

func cjguiInternalBuildRendererStage223RenderCommandRefreshSemanticDiffExplainFacts(
    refreshedRenderCommandPreviewPacket:
        CjguiInternalRendererStage222RefreshedRenderCommandPreviewPacketReadiness
): CjguiInternalRendererStage223RenderCommandRefreshSemanticDiffExplainFacts {
    let stateUpdateDiff = refreshedRenderCommandPreviewPacket
        .renderCommandRefresh.statefulInteractionReadinessDecision
        .stateUpdateSemanticDiffExplain

    return CjguiInternalRendererStage223RenderCommandRefreshSemanticDiffExplainFacts(
        refreshedRenderCommandPreviewPacket
            .didConfirmRefreshedRenderCommandPreviewPacketReady,
        true,
        true,
        refreshedRenderCommandPreviewPacket
            .didConfirmRefreshedRenderCommandPreviewPacketMaterialized,
        stateUpdateDiff.didConfirmStateUpdateSemanticDiffMaterialized &&
            stateUpdateDiff.didConfirmStateUpdateExplainPacketMaterialized,
        refreshedRenderCommandPreviewPacket
            .didConfirmPreviewPacketBoundToRollbackBoundary,
        refreshedRenderCommandPreviewPacket.didConfirmOwnerAcceptanceRequired,
        refreshedRenderCommandPreviewPacket.didConfirmOwnerAcceptanceGranted == false,
        true,
        refreshedRenderCommandPreviewPacket.didConfirmStateUpdateCommitted == false,
        refreshedRenderCommandPreviewPacket.didConfirmPreviewVisibilityPublished == false,
        refreshedRenderCommandPreviewPacket.didConfirmRendererSubmissionBlocked,
        refreshedRenderCommandPreviewPacket.didConfirmRendererStateWriteBlocked,
        refreshedRenderCommandPreviewPacket.didConfirmRuntimeStateWriteBlocked,
        refreshedRenderCommandPreviewPacket.didConfirmPublicComponentApiAdded == false
    )
}

func cjguiInternalBuildRendererStage223RenderCommandRefreshSemanticDiffExplainReadiness(
    refreshedRenderCommandPreviewPacket:
        CjguiInternalRendererStage222RefreshedRenderCommandPreviewPacketReadiness,
    renderCommandRefreshSemanticDiffExplainFacts:
        CjguiInternalRendererStage223RenderCommandRefreshSemanticDiffExplainFacts
): CjguiInternalRendererStage223RenderCommandRefreshSemanticDiffExplainReadiness {
    let diffExplainReady =
        renderCommandRefreshSemanticDiffExplainFacts
            .didConsumeStage222RefreshedRenderCommandPreviewPacket &&
        renderCommandRefreshSemanticDiffExplainFacts
            .didMaterializeRenderCommandRefreshSemanticDiff &&
        renderCommandRefreshSemanticDiffExplainFacts
            .didMaterializeRenderCommandRefreshExplainPacket &&
        renderCommandRefreshSemanticDiffExplainFacts
            .didBindDiffToRefreshedPreviewPacket &&
        renderCommandRefreshSemanticDiffExplainFacts
            .didBindExplainToStateUpdateSemanticDiff &&
        renderCommandRefreshSemanticDiffExplainFacts
            .didMaterializeRenderCommandRefreshRollbackReadyBoundary &&
        renderCommandRefreshSemanticDiffExplainFacts
            .didKeepOwnerAcceptanceRequired &&
        renderCommandRefreshSemanticDiffExplainFacts
            .didPrepareStage224RenderCommandRefreshReadinessDecisionInput
    let stopLineReady =
        renderCommandRefreshSemanticDiffExplainFacts
            .didKeepOwnerAcceptanceNotGranted &&
        renderCommandRefreshSemanticDiffExplainFacts
            .didKeepStateUpdateCommittedBlocked &&
        renderCommandRefreshSemanticDiffExplainFacts
            .didKeepVisibilityNotPublished &&
        renderCommandRefreshSemanticDiffExplainFacts
            .didKeepRendererSubmissionBlocked &&
        renderCommandRefreshSemanticDiffExplainFacts
            .didKeepRendererStateWriteBlocked &&
        renderCommandRefreshSemanticDiffExplainFacts
            .didKeepRuntimeStateWriteBlocked &&
        renderCommandRefreshSemanticDiffExplainFacts
            .didKeepPublicComponentApiBlocked

    return CjguiInternalRendererStage223RenderCommandRefreshSemanticDiffExplainReadiness(
        refreshedRenderCommandPreviewPacket,
        renderCommandRefreshSemanticDiffExplainFacts,
        diffExplainReady && stopLineReady,
        diffExplainReady && stopLineReady,
        renderCommandRefreshSemanticDiffExplainFacts
            .didMaterializeRenderCommandRefreshSemanticDiff,
        renderCommandRefreshSemanticDiffExplainFacts
            .didMaterializeRenderCommandRefreshExplainPacket,
        renderCommandRefreshSemanticDiffExplainFacts
            .didMaterializeRenderCommandRefreshRollbackReadyBoundary,
        renderCommandRefreshSemanticDiffExplainFacts
            .didKeepOwnerAcceptanceRequired,
        false,
        renderCommandRefreshSemanticDiffExplainFacts
            .didPrepareStage224RenderCommandRefreshReadinessDecisionInput,
        false,
        false,
        renderCommandRefreshSemanticDiffExplainFacts
            .didKeepRendererSubmissionBlocked,
        renderCommandRefreshSemanticDiffExplainFacts
            .didKeepRendererStateWriteBlocked,
        renderCommandRefreshSemanticDiffExplainFacts
            .didKeepRuntimeStateWriteBlocked,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage223RenderCommandRefreshSemanticDiffExplainDraft():
    CjguiInternalRendererStage223RenderCommandRefreshSemanticDiffExplainReadiness {
    let refreshedPreviewPacket =
        cjguiInternalExecuteDefaultRendererStage222RefreshedRenderCommandPreviewPacketDraft()
    let facts =
        cjguiInternalBuildRendererStage223RenderCommandRefreshSemanticDiffExplainFacts(
            refreshedPreviewPacket
        )
    return cjguiInternalBuildRendererStage223RenderCommandRefreshSemanticDiffExplainReadiness(
        refreshedPreviewPacket,
        facts
    )
}
