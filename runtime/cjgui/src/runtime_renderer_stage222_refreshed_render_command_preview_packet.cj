// 中文维护注释：本文件是 stage222 refreshed RenderCommand preview packet owner。
// Owner: 消费 stage221 refresh preview 与 RenderBatchingPacket，生成可解释 preview packet。
// Truth: preview packet 仍是 owner-local dry-run 输入，不发布 visibility。
// Stop-line: 不执行合批、不提交 renderer、不写 renderer/runtime state。
package cjgui

struct CjguiInternalRendererStage222RefreshedRenderCommandPreviewPacketFacts {
    let didConsumeStage221RenderCommandRefresh: Bool
    let didConsumeRenderBatchingPacket: Bool
    let didMaterializeRefreshedRenderCommandPreviewPacket: Bool
    let didBindPreviewPacketToStateUpdatePreview: Bool
    let didBindPreviewPacketToStateUpdateSemanticDiff: Bool
    let didBindPreviewPacketToRollbackBoundary: Bool
    let didPreserveBackendAgnosticRefreshPacket: Bool
    let didKeepPreviewVisibilityNotPublished: Bool
    let didPrepareStage223RenderCommandRefreshSemanticDiffInput: Bool
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepNativeBridgeExpansionBlocked: Bool

    init(
        didConsumeStage221RenderCommandRefresh: Bool,
        didConsumeRenderBatchingPacket: Bool,
        didMaterializeRefreshedRenderCommandPreviewPacket: Bool,
        didBindPreviewPacketToStateUpdatePreview: Bool,
        didBindPreviewPacketToStateUpdateSemanticDiff: Bool,
        didBindPreviewPacketToRollbackBoundary: Bool,
        didPreserveBackendAgnosticRefreshPacket: Bool,
        didKeepPreviewVisibilityNotPublished: Bool,
        didPrepareStage223RenderCommandRefreshSemanticDiffInput: Bool,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepNativeBridgeExpansionBlocked: Bool
    ) {
        this.didConsumeStage221RenderCommandRefresh =
            didConsumeStage221RenderCommandRefresh
        this.didConsumeRenderBatchingPacket = didConsumeRenderBatchingPacket
        this.didMaterializeRefreshedRenderCommandPreviewPacket =
            didMaterializeRefreshedRenderCommandPreviewPacket
        this.didBindPreviewPacketToStateUpdatePreview =
            didBindPreviewPacketToStateUpdatePreview
        this.didBindPreviewPacketToStateUpdateSemanticDiff =
            didBindPreviewPacketToStateUpdateSemanticDiff
        this.didBindPreviewPacketToRollbackBoundary =
            didBindPreviewPacketToRollbackBoundary
        this.didPreserveBackendAgnosticRefreshPacket =
            didPreserveBackendAgnosticRefreshPacket
        this.didKeepPreviewVisibilityNotPublished =
            didKeepPreviewVisibilityNotPublished
        this.didPrepareStage223RenderCommandRefreshSemanticDiffInput =
            didPrepareStage223RenderCommandRefreshSemanticDiffInput
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didKeepOwnerAcceptanceNotGranted =
            didKeepOwnerAcceptanceNotGranted
        this.didKeepStateUpdateCommittedBlocked =
            didKeepStateUpdateCommittedBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didKeepPublicComponentApiBlocked =
            didKeepPublicComponentApiBlocked
        this.didKeepNativeBridgeExpansionBlocked =
            didKeepNativeBridgeExpansionBlocked
    }
}

struct CjguiInternalRendererStage222RefreshedRenderCommandPreviewPacketReadiness {
    let renderCommandRefresh:
        CjguiInternalRendererStage221RenderCommandRefreshAfterStateUpdatePreviewReadiness
    let renderBatchingPacket: CjguiInternalRenderBatchingPacket
    let refreshedRenderCommandPreviewPacketFacts:
        CjguiInternalRendererStage222RefreshedRenderCommandPreviewPacketFacts
    let didPrepareStage222RefreshedRenderCommandPreviewPacketReadiness:
        Bool
    let didConfirmRefreshedRenderCommandPreviewPacketReady: Bool
    let didConfirmRefreshedRenderCommandPreviewPacketMaterialized: Bool
    let didConfirmPreviewPacketBoundToStateUpdatePreview: Bool
    let didConfirmPreviewPacketBoundToStateUpdateSemanticDiff: Bool
    let didConfirmPreviewPacketBoundToRollbackBoundary: Bool
    let didConfirmPreviewVisibilityPublished: Bool
    let didConfirmStage223RenderCommandRefreshSemanticDiffInputPrepared:
        Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmStateUpdateCommitted: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmNativeBridgeExpansionBlocked: Bool

    init(
        renderCommandRefresh:
            CjguiInternalRendererStage221RenderCommandRefreshAfterStateUpdatePreviewReadiness,
        renderBatchingPacket: CjguiInternalRenderBatchingPacket,
        refreshedRenderCommandPreviewPacketFacts:
            CjguiInternalRendererStage222RefreshedRenderCommandPreviewPacketFacts,
        didPrepareStage222RefreshedRenderCommandPreviewPacketReadiness:
            Bool,
        didConfirmRefreshedRenderCommandPreviewPacketReady: Bool,
        didConfirmRefreshedRenderCommandPreviewPacketMaterialized: Bool,
        didConfirmPreviewPacketBoundToStateUpdatePreview: Bool,
        didConfirmPreviewPacketBoundToStateUpdateSemanticDiff: Bool,
        didConfirmPreviewPacketBoundToRollbackBoundary: Bool,
        didConfirmPreviewVisibilityPublished: Bool,
        didConfirmStage223RenderCommandRefreshSemanticDiffInputPrepared:
            Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmStateUpdateCommitted: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmNativeBridgeExpansionBlocked: Bool
    ) {
        this.renderCommandRefresh = renderCommandRefresh
        this.renderBatchingPacket = renderBatchingPacket
        this.refreshedRenderCommandPreviewPacketFacts =
            refreshedRenderCommandPreviewPacketFacts
        this.didPrepareStage222RefreshedRenderCommandPreviewPacketReadiness =
            didPrepareStage222RefreshedRenderCommandPreviewPacketReadiness
        this.didConfirmRefreshedRenderCommandPreviewPacketReady =
            didConfirmRefreshedRenderCommandPreviewPacketReady
        this.didConfirmRefreshedRenderCommandPreviewPacketMaterialized =
            didConfirmRefreshedRenderCommandPreviewPacketMaterialized
        this.didConfirmPreviewPacketBoundToStateUpdatePreview =
            didConfirmPreviewPacketBoundToStateUpdatePreview
        this.didConfirmPreviewPacketBoundToStateUpdateSemanticDiff =
            didConfirmPreviewPacketBoundToStateUpdateSemanticDiff
        this.didConfirmPreviewPacketBoundToRollbackBoundary =
            didConfirmPreviewPacketBoundToRollbackBoundary
        this.didConfirmPreviewVisibilityPublished =
            didConfirmPreviewVisibilityPublished
        this.didConfirmStage223RenderCommandRefreshSemanticDiffInputPrepared =
            didConfirmStage223RenderCommandRefreshSemanticDiffInputPrepared
        this.didConfirmOwnerAcceptanceRequired =
            didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted =
            didConfirmOwnerAcceptanceGranted
        this.didConfirmStateUpdateCommitted = didConfirmStateUpdateCommitted
        this.didConfirmRendererSubmissionBlocked =
            didConfirmRendererSubmissionBlocked
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked =
            didConfirmRuntimeStateWriteBlocked
        this.didConfirmPublicComponentApiAdded =
            didConfirmPublicComponentApiAdded
        this.didConfirmNativeBridgeExpansionBlocked =
            didConfirmNativeBridgeExpansionBlocked
    }
}

func cjguiInternalBuildRendererStage222RefreshedRenderCommandPreviewPacketFacts(
    renderCommandRefresh:
        CjguiInternalRendererStage221RenderCommandRefreshAfterStateUpdatePreviewReadiness,
    renderBatchingPacket: CjguiInternalRenderBatchingPacket
): CjguiInternalRendererStage222RefreshedRenderCommandPreviewPacketFacts {
    let stateUpdateDiff =
        renderCommandRefresh.statefulInteractionReadinessDecision
            .stateUpdateSemanticDiffExplain

    return CjguiInternalRendererStage222RefreshedRenderCommandPreviewPacketFacts(
        renderCommandRefresh.didConfirmRenderCommandRefreshReady,
        renderBatchingPacket.isRenderBatchingPacketReady,
        true,
        renderCommandRefresh.didConfirmStateUpdatePreviewMappedToRenderCommandRefresh,
        stateUpdateDiff.didConfirmStateUpdateSemanticDiffMaterialized &&
            renderCommandRefresh
                .didConfirmRenderCommandRefreshPreviewMaterialized,
        stateUpdateDiff
            .didConfirmStateUpdateRollbackReadyBoundaryMaterialized,
        renderCommandRefresh.didConfirmCommandPacketBackendAgnostic &&
            renderBatchingPacket.didKeepBatchingPacketRendererAgnostic &&
            renderBatchingPacket.didAvoidRenderSideEffect,
        renderCommandRefresh.didConfirmVisibilityPublished == false,
        true,
        renderCommandRefresh.didConfirmOwnerAcceptanceRequired,
        renderCommandRefresh.didConfirmOwnerAcceptanceGranted == false,
        renderCommandRefresh.didConfirmStateUpdateCommitted == false,
        renderCommandRefresh.didConfirmRendererSubmissionBlocked &&
            renderBatchingPacket.didAvoidCommandMerge,
        renderCommandRefresh.didConfirmRendererStateWriteBlocked,
        renderCommandRefresh.didConfirmRuntimeStateWriteBlocked,
        renderCommandRefresh.didConfirmPublicComponentApiAdded == false,
        renderBatchingPacket.didAvoidRenderSideEffect
    )
}

func cjguiInternalBuildRendererStage222RefreshedRenderCommandPreviewPacketReadiness(
    renderCommandRefresh:
        CjguiInternalRendererStage221RenderCommandRefreshAfterStateUpdatePreviewReadiness,
    renderBatchingPacket: CjguiInternalRenderBatchingPacket,
    refreshedRenderCommandPreviewPacketFacts:
        CjguiInternalRendererStage222RefreshedRenderCommandPreviewPacketFacts
): CjguiInternalRendererStage222RefreshedRenderCommandPreviewPacketReadiness {
    let previewReady =
        refreshedRenderCommandPreviewPacketFacts
            .didConsumeStage221RenderCommandRefresh &&
        refreshedRenderCommandPreviewPacketFacts
            .didConsumeRenderBatchingPacket &&
        refreshedRenderCommandPreviewPacketFacts
            .didMaterializeRefreshedRenderCommandPreviewPacket &&
        refreshedRenderCommandPreviewPacketFacts
            .didBindPreviewPacketToStateUpdatePreview &&
        refreshedRenderCommandPreviewPacketFacts
            .didBindPreviewPacketToStateUpdateSemanticDiff &&
        refreshedRenderCommandPreviewPacketFacts
            .didBindPreviewPacketToRollbackBoundary &&
        refreshedRenderCommandPreviewPacketFacts
            .didPreserveBackendAgnosticRefreshPacket &&
        refreshedRenderCommandPreviewPacketFacts
            .didKeepPreviewVisibilityNotPublished &&
        refreshedRenderCommandPreviewPacketFacts
            .didPrepareStage223RenderCommandRefreshSemanticDiffInput
    let stopLineReady =
        refreshedRenderCommandPreviewPacketFacts
            .didKeepOwnerAcceptanceRequired &&
        refreshedRenderCommandPreviewPacketFacts
            .didKeepOwnerAcceptanceNotGranted &&
        refreshedRenderCommandPreviewPacketFacts
            .didKeepStateUpdateCommittedBlocked &&
        refreshedRenderCommandPreviewPacketFacts
            .didKeepRendererSubmissionBlocked &&
        refreshedRenderCommandPreviewPacketFacts
            .didKeepRendererStateWriteBlocked &&
        refreshedRenderCommandPreviewPacketFacts
            .didKeepRuntimeStateWriteBlocked &&
        refreshedRenderCommandPreviewPacketFacts
            .didKeepPublicComponentApiBlocked &&
        refreshedRenderCommandPreviewPacketFacts
            .didKeepNativeBridgeExpansionBlocked

    return CjguiInternalRendererStage222RefreshedRenderCommandPreviewPacketReadiness(
        renderCommandRefresh,
        renderBatchingPacket,
        refreshedRenderCommandPreviewPacketFacts,
        previewReady && stopLineReady,
        previewReady && stopLineReady,
        refreshedRenderCommandPreviewPacketFacts
            .didMaterializeRefreshedRenderCommandPreviewPacket,
        refreshedRenderCommandPreviewPacketFacts
            .didBindPreviewPacketToStateUpdatePreview,
        refreshedRenderCommandPreviewPacketFacts
            .didBindPreviewPacketToStateUpdateSemanticDiff,
        refreshedRenderCommandPreviewPacketFacts
            .didBindPreviewPacketToRollbackBoundary,
        false,
        refreshedRenderCommandPreviewPacketFacts
            .didPrepareStage223RenderCommandRefreshSemanticDiffInput,
        refreshedRenderCommandPreviewPacketFacts.didKeepOwnerAcceptanceRequired,
        false,
        false,
        refreshedRenderCommandPreviewPacketFacts
            .didKeepRendererSubmissionBlocked,
        refreshedRenderCommandPreviewPacketFacts
            .didKeepRendererStateWriteBlocked,
        refreshedRenderCommandPreviewPacketFacts
            .didKeepRuntimeStateWriteBlocked,
        false,
        refreshedRenderCommandPreviewPacketFacts
            .didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage222RefreshedRenderCommandPreviewPacketDraft():
    CjguiInternalRendererStage222RefreshedRenderCommandPreviewPacketReadiness {
    let refresh =
        cjguiInternalExecuteDefaultRendererStage221RenderCommandRefreshAfterStateUpdatePreviewDraft()
    let batchingPacket = cjguiInternalExecuteDefaultRenderBatchingHintDraft()
    let facts =
        cjguiInternalBuildRendererStage222RefreshedRenderCommandPreviewPacketFacts(
            refresh,
            batchingPacket
        )
    return cjguiInternalBuildRendererStage222RefreshedRenderCommandPreviewPacketReadiness(
        refresh,
        batchingPacket,
        facts
    )
}
