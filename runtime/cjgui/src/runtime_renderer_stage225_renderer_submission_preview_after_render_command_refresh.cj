// 中文维护注释：本文件是 stage225 renderer submission preview owner。
// Owner: 消费 stage224 render-command refresh readiness 与内部 RenderCommandPacket，
// 生成 Button-like demo 的 non-submitting renderer submission preview。
// Truth: submission preview 是 owner-local value facts，不代表 renderer 已提交。
// Stop-line: 不提交 renderer，不提交状态，不写 renderer/runtime state，不扩 native surface。
package cjgui

struct CjguiInternalRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshFacts {
    let didConsumeStage224RenderCommandRefreshReadinessDecision: Bool
    let didConsumeInternalRenderCommandPacket: Bool
    let didMaterializeRendererSubmissionPreview: Bool
    let didClassifySubmissionAsNonSubmitting: Bool
    let didBindSubmissionPreviewToButtonLikeSemanticNode: Bool
    let didBindSubmissionPreviewToRefreshedRenderCommandPacket: Bool
    let didPreserveRendererAgnosticSubmissionCandidate: Bool
    let didAvoidRenderSideEffect: Bool
    let didPrepareStage226RendererSubmissionPreviewPacketInput: Bool
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepInputEventPipelineExecutionBlocked: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepNativeBridgeExpansionBlocked: Bool
    let didKeepVisibilityNotPublished: Bool

    init(
        didConsumeStage224RenderCommandRefreshReadinessDecision: Bool,
        didConsumeInternalRenderCommandPacket: Bool,
        didMaterializeRendererSubmissionPreview: Bool,
        didClassifySubmissionAsNonSubmitting: Bool,
        didBindSubmissionPreviewToButtonLikeSemanticNode: Bool,
        didBindSubmissionPreviewToRefreshedRenderCommandPacket: Bool,
        didPreserveRendererAgnosticSubmissionCandidate: Bool,
        didAvoidRenderSideEffect: Bool,
        didPrepareStage226RendererSubmissionPreviewPacketInput: Bool,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepInputEventPipelineExecutionBlocked: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepNativeBridgeExpansionBlocked: Bool,
        didKeepVisibilityNotPublished: Bool
    ) {
        this.didConsumeStage224RenderCommandRefreshReadinessDecision =
            didConsumeStage224RenderCommandRefreshReadinessDecision
        this.didConsumeInternalRenderCommandPacket =
            didConsumeInternalRenderCommandPacket
        this.didMaterializeRendererSubmissionPreview =
            didMaterializeRendererSubmissionPreview
        this.didClassifySubmissionAsNonSubmitting =
            didClassifySubmissionAsNonSubmitting
        this.didBindSubmissionPreviewToButtonLikeSemanticNode =
            didBindSubmissionPreviewToButtonLikeSemanticNode
        this.didBindSubmissionPreviewToRefreshedRenderCommandPacket =
            didBindSubmissionPreviewToRefreshedRenderCommandPacket
        this.didPreserveRendererAgnosticSubmissionCandidate =
            didPreserveRendererAgnosticSubmissionCandidate
        this.didAvoidRenderSideEffect = didAvoidRenderSideEffect
        this.didPrepareStage226RendererSubmissionPreviewPacketInput =
            didPrepareStage226RendererSubmissionPreviewPacketInput
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didKeepOwnerAcceptanceNotGranted =
            didKeepOwnerAcceptanceNotGranted
        this.didKeepStateUpdateCommittedBlocked =
            didKeepStateUpdateCommittedBlocked
        this.didKeepInputEventPipelineExecutionBlocked =
            didKeepInputEventPipelineExecutionBlocked
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didKeepNativeBridgeExpansionBlocked =
            didKeepNativeBridgeExpansionBlocked
        this.didKeepVisibilityNotPublished = didKeepVisibilityNotPublished
    }
}

struct CjguiInternalRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshReadiness {
    let renderCommandRefreshReadinessDecision:
        CjguiInternalRendererStage224RenderCommandRefreshReadinessDecisionReadiness
    let renderCommandPacket: CjguiInternalRenderCommandPacket
    let rendererSubmissionPreviewAfterRenderCommandRefreshFacts:
        CjguiInternalRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshFacts
    let didPrepareStage225RendererSubmissionPreviewAfterRenderCommandRefreshReadiness:
        Bool
    let didConfirmRendererSubmissionPreviewReady: Bool
    let didConfirmRendererSubmissionPreviewMaterialized: Bool
    let didConfirmSubmissionCandidateNonSubmitting: Bool
    let didConfirmSubmissionPreviewBoundToButtonLikeSemanticNode: Bool
    let didConfirmSubmissionPreviewBoundToRefreshedRenderCommandPacket: Bool
    let didConfirmSubmissionPreviewRendererAgnostic: Bool
    let didConfirmSubmissionPreviewAvoidedRenderSideEffect: Bool
    let didConfirmStage226RendererSubmissionPreviewPacketInputPrepared: Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmStateUpdateCommitted: Bool
    let didConfirmInputEventPipelineExecuted: Bool
    let didConfirmActionDispatchExecuted: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmNativeBridgeExpansionBlocked: Bool
    let didConfirmVisibilityPublished: Bool

    init(
        renderCommandRefreshReadinessDecision:
            CjguiInternalRendererStage224RenderCommandRefreshReadinessDecisionReadiness,
        renderCommandPacket: CjguiInternalRenderCommandPacket,
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts:
            CjguiInternalRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshFacts,
        didPrepareStage225RendererSubmissionPreviewAfterRenderCommandRefreshReadiness:
            Bool,
        didConfirmRendererSubmissionPreviewReady: Bool,
        didConfirmRendererSubmissionPreviewMaterialized: Bool,
        didConfirmSubmissionCandidateNonSubmitting: Bool,
        didConfirmSubmissionPreviewBoundToButtonLikeSemanticNode: Bool,
        didConfirmSubmissionPreviewBoundToRefreshedRenderCommandPacket: Bool,
        didConfirmSubmissionPreviewRendererAgnostic: Bool,
        didConfirmSubmissionPreviewAvoidedRenderSideEffect: Bool,
        didConfirmStage226RendererSubmissionPreviewPacketInputPrepared: Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmStateUpdateCommitted: Bool,
        didConfirmInputEventPipelineExecuted: Bool,
        didConfirmActionDispatchExecuted: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmNativeBridgeExpansionBlocked: Bool,
        didConfirmVisibilityPublished: Bool
    ) {
        this.renderCommandRefreshReadinessDecision =
            renderCommandRefreshReadinessDecision
        this.renderCommandPacket = renderCommandPacket
        this.rendererSubmissionPreviewAfterRenderCommandRefreshFacts =
            rendererSubmissionPreviewAfterRenderCommandRefreshFacts
        this.didPrepareStage225RendererSubmissionPreviewAfterRenderCommandRefreshReadiness =
            didPrepareStage225RendererSubmissionPreviewAfterRenderCommandRefreshReadiness
        this.didConfirmRendererSubmissionPreviewReady =
            didConfirmRendererSubmissionPreviewReady
        this.didConfirmRendererSubmissionPreviewMaterialized =
            didConfirmRendererSubmissionPreviewMaterialized
        this.didConfirmSubmissionCandidateNonSubmitting =
            didConfirmSubmissionCandidateNonSubmitting
        this.didConfirmSubmissionPreviewBoundToButtonLikeSemanticNode =
            didConfirmSubmissionPreviewBoundToButtonLikeSemanticNode
        this.didConfirmSubmissionPreviewBoundToRefreshedRenderCommandPacket =
            didConfirmSubmissionPreviewBoundToRefreshedRenderCommandPacket
        this.didConfirmSubmissionPreviewRendererAgnostic =
            didConfirmSubmissionPreviewRendererAgnostic
        this.didConfirmSubmissionPreviewAvoidedRenderSideEffect =
            didConfirmSubmissionPreviewAvoidedRenderSideEffect
        this.didConfirmStage226RendererSubmissionPreviewPacketInputPrepared =
            didConfirmStage226RendererSubmissionPreviewPacketInputPrepared
        this.didConfirmOwnerAcceptanceRequired =
            didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted =
            didConfirmOwnerAcceptanceGranted
        this.didConfirmStateUpdateCommitted = didConfirmStateUpdateCommitted
        this.didConfirmInputEventPipelineExecuted =
            didConfirmInputEventPipelineExecuted
        this.didConfirmActionDispatchExecuted =
            didConfirmActionDispatchExecuted
        this.didConfirmRendererSubmissionBlocked =
            didConfirmRendererSubmissionBlocked
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked =
            didConfirmRuntimeStateWriteBlocked
        this.didConfirmNativeBridgeExpansionBlocked =
            didConfirmNativeBridgeExpansionBlocked
        this.didConfirmVisibilityPublished = didConfirmVisibilityPublished
    }
}

func cjguiInternalBuildRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshFacts(
    renderCommandRefreshReadinessDecision:
        CjguiInternalRendererStage224RenderCommandRefreshReadinessDecisionReadiness,
    renderCommandPacket: CjguiInternalRenderCommandPacket
): CjguiInternalRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshFacts {
    let diffExplain =
        renderCommandRefreshReadinessDecision.renderCommandRefreshSemanticDiffExplain
    let refreshedPacket = diffExplain.refreshedRenderCommandPreviewPacket
    let refresh = refreshedPacket.renderCommandRefresh

    return CjguiInternalRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshFacts(
        renderCommandRefreshReadinessDecision
            .didConfirmStage225RendererSubmissionPreviewInputPrepared,
        renderCommandPacket.isRenderCommandPacketReady,
        true,
        renderCommandRefreshReadinessDecision.didConfirmRendererSubmissionBlocked &&
            renderCommandPacket.commandList.didAvoidRendererSubmission,
        refresh.didConfirmRefreshBoundToButtonLikeSemanticNode,
        refreshedPacket
            .didConfirmRefreshedRenderCommandPreviewPacketMaterialized,
        renderCommandPacket.didKeepCommandPacketRendererAgnostic &&
            refreshedPacket.didConfirmNativeBridgeExpansionBlocked,
        renderCommandPacket.didAvoidRenderSideEffect &&
            renderCommandPacket.commandList.didAvoidRendererSubmission,
        true,
        renderCommandRefreshReadinessDecision.didConfirmOwnerAcceptanceRequired,
        renderCommandRefreshReadinessDecision.didConfirmOwnerAcceptanceGranted == false,
        renderCommandRefreshReadinessDecision.didConfirmStateUpdateCommitted == false,
        renderCommandRefreshReadinessDecision.didConfirmInputEventPipelineExecuted == false,
        renderCommandRefreshReadinessDecision.didConfirmActionDispatchExecuted == false,
        renderCommandRefreshReadinessDecision.didConfirmRendererSubmissionBlocked &&
            renderCommandPacket.commandList.didAvoidRendererSubmission,
        renderCommandRefreshReadinessDecision.didConfirmRendererStateWriteBlocked,
        renderCommandRefreshReadinessDecision.didConfirmRuntimeStateWriteBlocked,
        renderCommandRefreshReadinessDecision.didConfirmNativeBridgeExpansionBlocked,
        renderCommandRefreshReadinessDecision.didConfirmVisibilityPublished == false
    )
}

func cjguiInternalBuildRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshReadiness(
    renderCommandRefreshReadinessDecision:
        CjguiInternalRendererStage224RenderCommandRefreshReadinessDecisionReadiness,
    renderCommandPacket: CjguiInternalRenderCommandPacket,
    rendererSubmissionPreviewAfterRenderCommandRefreshFacts:
        CjguiInternalRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshFacts
): CjguiInternalRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshReadiness {
    let previewReady =
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didConsumeStage224RenderCommandRefreshReadinessDecision &&
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didConsumeInternalRenderCommandPacket &&
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didMaterializeRendererSubmissionPreview &&
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didClassifySubmissionAsNonSubmitting &&
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didBindSubmissionPreviewToButtonLikeSemanticNode &&
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didBindSubmissionPreviewToRefreshedRenderCommandPacket &&
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didPreserveRendererAgnosticSubmissionCandidate &&
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didAvoidRenderSideEffect &&
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didPrepareStage226RendererSubmissionPreviewPacketInput
    let stopLineReady =
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didKeepOwnerAcceptanceRequired &&
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didKeepOwnerAcceptanceNotGranted &&
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didKeepStateUpdateCommittedBlocked &&
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didKeepInputEventPipelineExecutionBlocked &&
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didKeepActionDispatchBlocked &&
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didKeepRendererSubmissionBlocked &&
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didKeepRendererStateWriteBlocked &&
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didKeepRuntimeStateWriteBlocked &&
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didKeepNativeBridgeExpansionBlocked &&
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didKeepVisibilityNotPublished

    return CjguiInternalRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshReadiness(
        renderCommandRefreshReadinessDecision,
        renderCommandPacket,
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts,
        previewReady && stopLineReady,
        previewReady && stopLineReady,
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didMaterializeRendererSubmissionPreview,
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didClassifySubmissionAsNonSubmitting,
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didBindSubmissionPreviewToButtonLikeSemanticNode,
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didBindSubmissionPreviewToRefreshedRenderCommandPacket,
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didPreserveRendererAgnosticSubmissionCandidate,
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didAvoidRenderSideEffect,
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didPrepareStage226RendererSubmissionPreviewPacketInput,
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didKeepOwnerAcceptanceRequired,
        false,
        false,
        false,
        false,
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didKeepRendererSubmissionBlocked,
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didKeepRendererStateWriteBlocked,
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didKeepRuntimeStateWriteBlocked,
        rendererSubmissionPreviewAfterRenderCommandRefreshFacts
            .didKeepNativeBridgeExpansionBlocked,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshDraft():
    CjguiInternalRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshReadiness {
    let renderCommandRefreshDecision =
        cjguiInternalExecuteDefaultRendererStage224RenderCommandRefreshReadinessDecisionDraft()
    let commandPacket = cjguiInternalExecuteDefaultRenderCommandShapeDraft()
    let facts =
        cjguiInternalBuildRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshFacts(
            renderCommandRefreshDecision,
            commandPacket
        )
    return cjguiInternalBuildRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshReadiness(
        renderCommandRefreshDecision,
        commandPacket,
        facts
    )
}
