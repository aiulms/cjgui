// 中文维护注释：本文件是 stage206 component demo preview packet owner。
// Owner: 消费 stage205 RenderCommand admission 与 RenderBatchingPacket，生成
// owner-local preview packet，给 semantic diff/explain 使用。
// Truth: preview packet 是可回滚预览输入，不是 visibility publication。
// Stop-line: 不提交 renderer，不发布 visibility，不写 renderer/runtime state。
package cjgui

struct CjguiInternalRendererStage206ComponentDemoPreviewPacketFacts {
    let didConsumeStage205ComponentDemoRenderCommandAdmission: Bool
    let didConsumeRenderBatchingPacket: Bool
    let didMaterializeComponentDemoPreviewPacket: Bool
    let didBindPreviewToRenderBatchingFacts: Bool
    let didBindPreviewToOwnerLocalRollbackBoundary: Bool
    let didKeepPreviewVisibilityNotPublished: Bool
    let didPrepareStage207SemanticPreviewDiffInput: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepNativeBridgeExpansionBlocked: Bool

    init(
        didConsumeStage205ComponentDemoRenderCommandAdmission: Bool,
        didConsumeRenderBatchingPacket: Bool,
        didMaterializeComponentDemoPreviewPacket: Bool,
        didBindPreviewToRenderBatchingFacts: Bool,
        didBindPreviewToOwnerLocalRollbackBoundary: Bool,
        didKeepPreviewVisibilityNotPublished: Bool,
        didPrepareStage207SemanticPreviewDiffInput: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepNativeBridgeExpansionBlocked: Bool
    ) {
        this.didConsumeStage205ComponentDemoRenderCommandAdmission =
            didConsumeStage205ComponentDemoRenderCommandAdmission
        this.didConsumeRenderBatchingPacket = didConsumeRenderBatchingPacket
        this.didMaterializeComponentDemoPreviewPacket =
            didMaterializeComponentDemoPreviewPacket
        this.didBindPreviewToRenderBatchingFacts =
            didBindPreviewToRenderBatchingFacts
        this.didBindPreviewToOwnerLocalRollbackBoundary =
            didBindPreviewToOwnerLocalRollbackBoundary
        this.didKeepPreviewVisibilityNotPublished =
            didKeepPreviewVisibilityNotPublished
        this.didPrepareStage207SemanticPreviewDiffInput =
            didPrepareStage207SemanticPreviewDiffInput
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

struct CjguiInternalRendererStage206ComponentDemoPreviewPacketReadiness {
    let componentDemoRenderCommandAdmission:
        CjguiInternalRendererStage205ComponentDemoRenderCommandAdmissionReadiness
    let renderBatchingPacket: CjguiInternalRenderBatchingPacket
    let componentDemoPreviewPacketFacts:
        CjguiInternalRendererStage206ComponentDemoPreviewPacketFacts
    let didPrepareStage206ComponentDemoPreviewPacketReadiness: Bool
    let didConfirmComponentDemoPreviewPacketReady: Bool
    let didConfirmComponentDemoPreviewPacketMaterialized: Bool
    let didConfirmPreviewBoundToOwnerLocalRollbackBoundary: Bool
    let didConfirmStage207SemanticPreviewDiffInputPrepared: Bool
    let didConfirmPreviewVisibilityPublished: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmNativeBridgeExpansionBlocked: Bool

    init(
        componentDemoRenderCommandAdmission:
            CjguiInternalRendererStage205ComponentDemoRenderCommandAdmissionReadiness,
        renderBatchingPacket: CjguiInternalRenderBatchingPacket,
        componentDemoPreviewPacketFacts:
            CjguiInternalRendererStage206ComponentDemoPreviewPacketFacts,
        didPrepareStage206ComponentDemoPreviewPacketReadiness: Bool,
        didConfirmComponentDemoPreviewPacketReady: Bool,
        didConfirmComponentDemoPreviewPacketMaterialized: Bool,
        didConfirmPreviewBoundToOwnerLocalRollbackBoundary: Bool,
        didConfirmStage207SemanticPreviewDiffInputPrepared: Bool,
        didConfirmPreviewVisibilityPublished: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmNativeBridgeExpansionBlocked: Bool
    ) {
        this.componentDemoRenderCommandAdmission =
            componentDemoRenderCommandAdmission
        this.renderBatchingPacket = renderBatchingPacket
        this.componentDemoPreviewPacketFacts = componentDemoPreviewPacketFacts
        this.didPrepareStage206ComponentDemoPreviewPacketReadiness =
            didPrepareStage206ComponentDemoPreviewPacketReadiness
        this.didConfirmComponentDemoPreviewPacketReady =
            didConfirmComponentDemoPreviewPacketReady
        this.didConfirmComponentDemoPreviewPacketMaterialized =
            didConfirmComponentDemoPreviewPacketMaterialized
        this.didConfirmPreviewBoundToOwnerLocalRollbackBoundary =
            didConfirmPreviewBoundToOwnerLocalRollbackBoundary
        this.didConfirmStage207SemanticPreviewDiffInputPrepared =
            didConfirmStage207SemanticPreviewDiffInputPrepared
        this.didConfirmPreviewVisibilityPublished =
            didConfirmPreviewVisibilityPublished
        this.didConfirmRendererSubmissionBlocked =
            didConfirmRendererSubmissionBlocked
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked =
            didConfirmRuntimeStateWriteBlocked
        this.didConfirmPublicComponentApiAdded = didConfirmPublicComponentApiAdded
        this.didConfirmNativeBridgeExpansionBlocked =
            didConfirmNativeBridgeExpansionBlocked
    }
}

func cjguiInternalBuildRendererStage206ComponentDemoPreviewPacketFacts(
    componentDemoRenderCommandAdmission:
        CjguiInternalRendererStage205ComponentDemoRenderCommandAdmissionReadiness,
    renderBatchingPacket: CjguiInternalRenderBatchingPacket
): CjguiInternalRendererStage206ComponentDemoPreviewPacketFacts {
    return CjguiInternalRendererStage206ComponentDemoPreviewPacketFacts(
        componentDemoRenderCommandAdmission
            .didConfirmComponentDemoRenderCommandAdmissionReady,
        renderBatchingPacket.isRenderBatchingPacketReady,
        true,
        renderBatchingPacket.didKeepBatchingPacketRendererAgnostic &&
            renderBatchingPacket.didPreserveRenderBatchingPlan &&
            renderBatchingPacket.didAvoidCommandMerge,
        componentDemoRenderCommandAdmission
            .componentDemoStateUpdateDryRun
            .didConfirmOwnerLocalRollbackPreviewMaterialized,
        componentDemoRenderCommandAdmission
            .componentDemoStateUpdateDryRun
            .didConfirmVisibilityPublished == false,
        true,
        componentDemoRenderCommandAdmission.didConfirmRendererSubmissionBlocked &&
            renderBatchingPacket.didAvoidRenderSideEffect,
        componentDemoRenderCommandAdmission.didConfirmRendererStateWriteBlocked,
        componentDemoRenderCommandAdmission.didConfirmRuntimeStateWriteBlocked,
        componentDemoRenderCommandAdmission.didConfirmPublicComponentApiAdded == false,
        componentDemoRenderCommandAdmission.didConfirmNativeBridgeExpansionBlocked
    )
}

func cjguiInternalBuildRendererStage206ComponentDemoPreviewPacketReadiness(
    componentDemoRenderCommandAdmission:
        CjguiInternalRendererStage205ComponentDemoRenderCommandAdmissionReadiness,
    renderBatchingPacket: CjguiInternalRenderBatchingPacket,
    componentDemoPreviewPacketFacts:
        CjguiInternalRendererStage206ComponentDemoPreviewPacketFacts
): CjguiInternalRendererStage206ComponentDemoPreviewPacketReadiness {
    let previewReady =
        componentDemoPreviewPacketFacts
            .didConsumeStage205ComponentDemoRenderCommandAdmission &&
        componentDemoPreviewPacketFacts.didConsumeRenderBatchingPacket &&
        componentDemoPreviewPacketFacts
            .didMaterializeComponentDemoPreviewPacket &&
        componentDemoPreviewPacketFacts.didBindPreviewToRenderBatchingFacts &&
        componentDemoPreviewPacketFacts
            .didBindPreviewToOwnerLocalRollbackBoundary &&
        componentDemoPreviewPacketFacts.didKeepPreviewVisibilityNotPublished &&
        componentDemoPreviewPacketFacts.didPrepareStage207SemanticPreviewDiffInput
    let stopLineReady =
        componentDemoPreviewPacketFacts.didKeepRendererSubmissionBlocked &&
        componentDemoPreviewPacketFacts.didKeepRendererStateWriteBlocked &&
        componentDemoPreviewPacketFacts.didKeepRuntimeStateWriteBlocked &&
        componentDemoPreviewPacketFacts.didKeepPublicComponentApiBlocked &&
        componentDemoPreviewPacketFacts.didKeepNativeBridgeExpansionBlocked

    return CjguiInternalRendererStage206ComponentDemoPreviewPacketReadiness(
        componentDemoRenderCommandAdmission,
        renderBatchingPacket,
        componentDemoPreviewPacketFacts,
        previewReady && stopLineReady,
        previewReady && stopLineReady,
        componentDemoPreviewPacketFacts.didMaterializeComponentDemoPreviewPacket,
        componentDemoPreviewPacketFacts
            .didBindPreviewToOwnerLocalRollbackBoundary,
        componentDemoPreviewPacketFacts
            .didPrepareStage207SemanticPreviewDiffInput,
        false,
        componentDemoPreviewPacketFacts.didKeepRendererSubmissionBlocked,
        componentDemoPreviewPacketFacts.didKeepRendererStateWriteBlocked,
        componentDemoPreviewPacketFacts.didKeepRuntimeStateWriteBlocked,
        false,
        componentDemoPreviewPacketFacts.didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage206ComponentDemoPreviewPacketDraft():
    CjguiInternalRendererStage206ComponentDemoPreviewPacketReadiness {
    let admission =
        cjguiInternalExecuteDefaultRendererStage205ComponentDemoRenderCommandAdmissionDraft()
    let batchingPacket = cjguiInternalExecuteDefaultRenderBatchingHintDraft()
    let facts = cjguiInternalBuildRendererStage206ComponentDemoPreviewPacketFacts(
        admission,
        batchingPacket
    )
    return cjguiInternalBuildRendererStage206ComponentDemoPreviewPacketReadiness(
        admission,
        batchingPacket,
        facts
    )
}
