// 中文维护注释：本文件是 stage226 renderer submission preview packet owner。
// Owner: 消费 stage225 non-submitting submission preview 与 RenderBatchingPacket，
// 生成 owner-local preview packet，给 submission diff/explain 使用。
// Truth: preview packet 是可回滚 dry-run 输入，不发布 visibility。
// Stop-line: 不提交 renderer，不写 renderer/runtime state，不扩 public/native surface。
package cjgui

struct CjguiInternalRendererStage226RendererSubmissionPreviewPacketFacts {
    let didConsumeStage225RendererSubmissionPreview: Bool
    let didConsumeRenderBatchingPacket: Bool
    let didMaterializeRendererSubmissionPreviewPacket: Bool
    let didBindPreviewPacketToNonSubmittingCandidate: Bool
    let didBindPreviewPacketToRenderCommandRefreshReadiness: Bool
    let didBindPreviewPacketToRollbackBoundary: Bool
    let didPreserveBackendAgnosticSubmissionPacket: Bool
    let didKeepPreviewVisibilityNotPublished: Bool
    let didPrepareStage227RendererSubmissionSemanticDiffInput: Bool
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepNativeBridgeExpansionBlocked: Bool

    init(
        didConsumeStage225RendererSubmissionPreview: Bool,
        didConsumeRenderBatchingPacket: Bool,
        didMaterializeRendererSubmissionPreviewPacket: Bool,
        didBindPreviewPacketToNonSubmittingCandidate: Bool,
        didBindPreviewPacketToRenderCommandRefreshReadiness: Bool,
        didBindPreviewPacketToRollbackBoundary: Bool,
        didPreserveBackendAgnosticSubmissionPacket: Bool,
        didKeepPreviewVisibilityNotPublished: Bool,
        didPrepareStage227RendererSubmissionSemanticDiffInput: Bool,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepNativeBridgeExpansionBlocked: Bool
    ) {
        this.didConsumeStage225RendererSubmissionPreview =
            didConsumeStage225RendererSubmissionPreview
        this.didConsumeRenderBatchingPacket = didConsumeRenderBatchingPacket
        this.didMaterializeRendererSubmissionPreviewPacket =
            didMaterializeRendererSubmissionPreviewPacket
        this.didBindPreviewPacketToNonSubmittingCandidate =
            didBindPreviewPacketToNonSubmittingCandidate
        this.didBindPreviewPacketToRenderCommandRefreshReadiness =
            didBindPreviewPacketToRenderCommandRefreshReadiness
        this.didBindPreviewPacketToRollbackBoundary =
            didBindPreviewPacketToRollbackBoundary
        this.didPreserveBackendAgnosticSubmissionPacket =
            didPreserveBackendAgnosticSubmissionPacket
        this.didKeepPreviewVisibilityNotPublished =
            didKeepPreviewVisibilityNotPublished
        this.didPrepareStage227RendererSubmissionSemanticDiffInput =
            didPrepareStage227RendererSubmissionSemanticDiffInput
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didKeepOwnerAcceptanceNotGranted =
            didKeepOwnerAcceptanceNotGranted
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

struct CjguiInternalRendererStage226RendererSubmissionPreviewPacketReadiness {
    let rendererSubmissionPreview:
        CjguiInternalRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshReadiness
    let renderBatchingPacket: CjguiInternalRenderBatchingPacket
    let rendererSubmissionPreviewPacketFacts:
        CjguiInternalRendererStage226RendererSubmissionPreviewPacketFacts
    let didPrepareStage226RendererSubmissionPreviewPacketReadiness: Bool
    let didConfirmRendererSubmissionPreviewPacketReady: Bool
    let didConfirmRendererSubmissionPreviewPacketMaterialized: Bool
    let didConfirmPreviewPacketBoundToNonSubmittingCandidate: Bool
    let didConfirmPreviewPacketBoundToRenderCommandRefreshReadiness: Bool
    let didConfirmPreviewPacketBoundToRollbackBoundary: Bool
    let didConfirmStage227RendererSubmissionSemanticDiffInputPrepared: Bool
    let didConfirmPreviewVisibilityPublished: Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmNativeBridgeExpansionBlocked: Bool

    init(
        rendererSubmissionPreview:
            CjguiInternalRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshReadiness,
        renderBatchingPacket: CjguiInternalRenderBatchingPacket,
        rendererSubmissionPreviewPacketFacts:
            CjguiInternalRendererStage226RendererSubmissionPreviewPacketFacts,
        didPrepareStage226RendererSubmissionPreviewPacketReadiness: Bool,
        didConfirmRendererSubmissionPreviewPacketReady: Bool,
        didConfirmRendererSubmissionPreviewPacketMaterialized: Bool,
        didConfirmPreviewPacketBoundToNonSubmittingCandidate: Bool,
        didConfirmPreviewPacketBoundToRenderCommandRefreshReadiness: Bool,
        didConfirmPreviewPacketBoundToRollbackBoundary: Bool,
        didConfirmStage227RendererSubmissionSemanticDiffInputPrepared: Bool,
        didConfirmPreviewVisibilityPublished: Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmNativeBridgeExpansionBlocked: Bool
    ) {
        this.rendererSubmissionPreview = rendererSubmissionPreview
        this.renderBatchingPacket = renderBatchingPacket
        this.rendererSubmissionPreviewPacketFacts =
            rendererSubmissionPreviewPacketFacts
        this.didPrepareStage226RendererSubmissionPreviewPacketReadiness =
            didPrepareStage226RendererSubmissionPreviewPacketReadiness
        this.didConfirmRendererSubmissionPreviewPacketReady =
            didConfirmRendererSubmissionPreviewPacketReady
        this.didConfirmRendererSubmissionPreviewPacketMaterialized =
            didConfirmRendererSubmissionPreviewPacketMaterialized
        this.didConfirmPreviewPacketBoundToNonSubmittingCandidate =
            didConfirmPreviewPacketBoundToNonSubmittingCandidate
        this.didConfirmPreviewPacketBoundToRenderCommandRefreshReadiness =
            didConfirmPreviewPacketBoundToRenderCommandRefreshReadiness
        this.didConfirmPreviewPacketBoundToRollbackBoundary =
            didConfirmPreviewPacketBoundToRollbackBoundary
        this.didConfirmStage227RendererSubmissionSemanticDiffInputPrepared =
            didConfirmStage227RendererSubmissionSemanticDiffInputPrepared
        this.didConfirmPreviewVisibilityPublished =
            didConfirmPreviewVisibilityPublished
        this.didConfirmOwnerAcceptanceRequired =
            didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted =
            didConfirmOwnerAcceptanceGranted
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

func cjguiInternalBuildRendererStage226RendererSubmissionPreviewPacketFacts(
    rendererSubmissionPreview:
        CjguiInternalRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshReadiness,
    renderBatchingPacket: CjguiInternalRenderBatchingPacket
): CjguiInternalRendererStage226RendererSubmissionPreviewPacketFacts {
    let refreshDecision = rendererSubmissionPreview.renderCommandRefreshReadinessDecision

    return CjguiInternalRendererStage226RendererSubmissionPreviewPacketFacts(
        rendererSubmissionPreview.didConfirmRendererSubmissionPreviewReady,
        renderBatchingPacket.isRenderBatchingPacketReady,
        true,
        rendererSubmissionPreview.didConfirmSubmissionCandidateNonSubmitting,
        refreshDecision.didConfirmRenderCommandRefreshReadinessDecisionReady,
        refreshDecision.didConfirmRenderCommandRefreshDiffExplainRollbackBoundaryJoined,
        rendererSubmissionPreview.didConfirmSubmissionPreviewRendererAgnostic &&
            renderBatchingPacket.didKeepBatchingPacketRendererAgnostic &&
            renderBatchingPacket.didAvoidRenderSideEffect,
        rendererSubmissionPreview.didConfirmVisibilityPublished == false,
        true,
        rendererSubmissionPreview.didConfirmOwnerAcceptanceRequired,
        rendererSubmissionPreview.didConfirmOwnerAcceptanceGranted == false,
        rendererSubmissionPreview.didConfirmRendererSubmissionBlocked &&
            renderBatchingPacket.didAvoidCommandMerge,
        rendererSubmissionPreview.didConfirmRendererStateWriteBlocked,
        rendererSubmissionPreview.didConfirmRuntimeStateWriteBlocked,
        false,
        rendererSubmissionPreview.didConfirmNativeBridgeExpansionBlocked
    )
}

func cjguiInternalBuildRendererStage226RendererSubmissionPreviewPacketReadiness(
    rendererSubmissionPreview:
        CjguiInternalRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshReadiness,
    renderBatchingPacket: CjguiInternalRenderBatchingPacket,
    rendererSubmissionPreviewPacketFacts:
        CjguiInternalRendererStage226RendererSubmissionPreviewPacketFacts
): CjguiInternalRendererStage226RendererSubmissionPreviewPacketReadiness {
    let packetReady =
        rendererSubmissionPreviewPacketFacts
            .didConsumeStage225RendererSubmissionPreview &&
        rendererSubmissionPreviewPacketFacts.didConsumeRenderBatchingPacket &&
        rendererSubmissionPreviewPacketFacts
            .didMaterializeRendererSubmissionPreviewPacket &&
        rendererSubmissionPreviewPacketFacts
            .didBindPreviewPacketToNonSubmittingCandidate &&
        rendererSubmissionPreviewPacketFacts
            .didBindPreviewPacketToRenderCommandRefreshReadiness &&
        rendererSubmissionPreviewPacketFacts
            .didBindPreviewPacketToRollbackBoundary &&
        rendererSubmissionPreviewPacketFacts
            .didPreserveBackendAgnosticSubmissionPacket &&
        rendererSubmissionPreviewPacketFacts.didKeepPreviewVisibilityNotPublished &&
        rendererSubmissionPreviewPacketFacts
            .didPrepareStage227RendererSubmissionSemanticDiffInput
    let stopLineReady =
        rendererSubmissionPreviewPacketFacts.didKeepOwnerAcceptanceRequired &&
        rendererSubmissionPreviewPacketFacts.didKeepOwnerAcceptanceNotGranted &&
        rendererSubmissionPreviewPacketFacts.didKeepRendererSubmissionBlocked &&
        rendererSubmissionPreviewPacketFacts.didKeepRendererStateWriteBlocked &&
        rendererSubmissionPreviewPacketFacts.didKeepRuntimeStateWriteBlocked &&
        rendererSubmissionPreviewPacketFacts.didKeepPublicComponentApiBlocked &&
        rendererSubmissionPreviewPacketFacts.didKeepNativeBridgeExpansionBlocked

    return CjguiInternalRendererStage226RendererSubmissionPreviewPacketReadiness(
        rendererSubmissionPreview,
        renderBatchingPacket,
        rendererSubmissionPreviewPacketFacts,
        packetReady && stopLineReady,
        packetReady && stopLineReady,
        rendererSubmissionPreviewPacketFacts
            .didMaterializeRendererSubmissionPreviewPacket,
        rendererSubmissionPreviewPacketFacts
            .didBindPreviewPacketToNonSubmittingCandidate,
        rendererSubmissionPreviewPacketFacts
            .didBindPreviewPacketToRenderCommandRefreshReadiness,
        rendererSubmissionPreviewPacketFacts
            .didBindPreviewPacketToRollbackBoundary,
        rendererSubmissionPreviewPacketFacts
            .didPrepareStage227RendererSubmissionSemanticDiffInput,
        false,
        rendererSubmissionPreviewPacketFacts.didKeepOwnerAcceptanceRequired,
        false,
        rendererSubmissionPreviewPacketFacts.didKeepRendererSubmissionBlocked,
        rendererSubmissionPreviewPacketFacts.didKeepRendererStateWriteBlocked,
        rendererSubmissionPreviewPacketFacts.didKeepRuntimeStateWriteBlocked,
        false,
        rendererSubmissionPreviewPacketFacts.didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage226RendererSubmissionPreviewPacketDraft():
    CjguiInternalRendererStage226RendererSubmissionPreviewPacketReadiness {
    let submissionPreview =
        cjguiInternalExecuteDefaultRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshDraft()
    let batchingPacket = cjguiInternalExecuteDefaultRenderBatchingHintDraft()
    let facts =
        cjguiInternalBuildRendererStage226RendererSubmissionPreviewPacketFacts(
            submissionPreview,
            batchingPacket
        )
    return cjguiInternalBuildRendererStage226RendererSubmissionPreviewPacketReadiness(
        submissionPreview,
        batchingPacket,
        facts
    )
}
