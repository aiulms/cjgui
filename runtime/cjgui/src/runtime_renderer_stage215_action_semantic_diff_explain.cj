// 中文维护注释：本文件是 stage215 action semantic diff / explain owner。
// Owner: 消费 stage214 action preview packet，生成 action diff、explain packet
// 与 rollback-ready boundary。
// Truth: diff/explain 是 owner acceptance 输入，不代表 action 已被接受。
// Stop-line: 不 dispatch action，不更新状态，不写 renderer/runtime state。
package cjgui

struct CjguiInternalRendererStage215ActionSemanticDiffExplainFacts {
    let didConsumeStage214ActionPreviewPacket: Bool
    let didMaterializeActionSemanticDiff: Bool
    let didMaterializeActionExplainPacket: Bool
    let didBindDiffToActionPreviewPacket: Bool
    let didBindExplainToActionIntentFacts: Bool
    let didMaterializeActionRollbackReadyBoundary: Bool
    let didKeepOwnerAcceptanceRequired: Bool
    let didPrepareStage216InteractionRunwayReadinessDecisionInput: Bool
    let didKeepInputEventPipelineExecutionBlocked: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepVisibilityNotPublished: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepLayoutEngineBlocked: Bool

    init(
        didConsumeStage214ActionPreviewPacket: Bool,
        didMaterializeActionSemanticDiff: Bool,
        didMaterializeActionExplainPacket: Bool,
        didBindDiffToActionPreviewPacket: Bool,
        didBindExplainToActionIntentFacts: Bool,
        didMaterializeActionRollbackReadyBoundary: Bool,
        didKeepOwnerAcceptanceRequired: Bool,
        didPrepareStage216InteractionRunwayReadinessDecisionInput: Bool,
        didKeepInputEventPipelineExecutionBlocked: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepVisibilityNotPublished: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepLayoutEngineBlocked: Bool
    ) {
        this.didConsumeStage214ActionPreviewPacket =
            didConsumeStage214ActionPreviewPacket
        this.didMaterializeActionSemanticDiff =
            didMaterializeActionSemanticDiff
        this.didMaterializeActionExplainPacket =
            didMaterializeActionExplainPacket
        this.didBindDiffToActionPreviewPacket =
            didBindDiffToActionPreviewPacket
        this.didBindExplainToActionIntentFacts =
            didBindExplainToActionIntentFacts
        this.didMaterializeActionRollbackReadyBoundary =
            didMaterializeActionRollbackReadyBoundary
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didPrepareStage216InteractionRunwayReadinessDecisionInput =
            didPrepareStage216InteractionRunwayReadinessDecisionInput
        this.didKeepInputEventPipelineExecutionBlocked =
            didKeepInputEventPipelineExecutionBlocked
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepVisibilityNotPublished = didKeepVisibilityNotPublished
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didKeepPublicComponentApiBlocked =
            didKeepPublicComponentApiBlocked
        this.didKeepLayoutEngineBlocked = didKeepLayoutEngineBlocked
    }
}

struct CjguiInternalRendererStage215ActionSemanticDiffExplainReadiness {
    let actionPreviewPacket:
        CjguiInternalRendererStage214ActionPreviewPacketReadiness
    let actionSemanticDiffExplainFacts:
        CjguiInternalRendererStage215ActionSemanticDiffExplainFacts
    let didPrepareStage215ActionSemanticDiffExplainReadiness: Bool
    let didConfirmActionSemanticDiffExplainReady: Bool
    let didConfirmActionSemanticDiffMaterialized: Bool
    let didConfirmActionExplainPacketMaterialized: Bool
    let didConfirmActionRollbackReadyBoundaryMaterialized: Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmActionDispatchBlocked: Bool
    let didConfirmStage216InteractionRunwayReadinessDecisionInputPrepared:
        Bool
    let didConfirmInputEventPipelineExecuted: Bool
    let didConfirmVisibilityPublished: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmLayoutEngineEnabled: Bool

    init(
        actionPreviewPacket:
            CjguiInternalRendererStage214ActionPreviewPacketReadiness,
        actionSemanticDiffExplainFacts:
            CjguiInternalRendererStage215ActionSemanticDiffExplainFacts,
        didPrepareStage215ActionSemanticDiffExplainReadiness: Bool,
        didConfirmActionSemanticDiffExplainReady: Bool,
        didConfirmActionSemanticDiffMaterialized: Bool,
        didConfirmActionExplainPacketMaterialized: Bool,
        didConfirmActionRollbackReadyBoundaryMaterialized: Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmActionDispatchBlocked: Bool,
        didConfirmStage216InteractionRunwayReadinessDecisionInputPrepared:
            Bool,
        didConfirmInputEventPipelineExecuted: Bool,
        didConfirmVisibilityPublished: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmLayoutEngineEnabled: Bool
    ) {
        this.actionPreviewPacket = actionPreviewPacket
        this.actionSemanticDiffExplainFacts =
            actionSemanticDiffExplainFacts
        this.didPrepareStage215ActionSemanticDiffExplainReadiness =
            didPrepareStage215ActionSemanticDiffExplainReadiness
        this.didConfirmActionSemanticDiffExplainReady =
            didConfirmActionSemanticDiffExplainReady
        this.didConfirmActionSemanticDiffMaterialized =
            didConfirmActionSemanticDiffMaterialized
        this.didConfirmActionExplainPacketMaterialized =
            didConfirmActionExplainPacketMaterialized
        this.didConfirmActionRollbackReadyBoundaryMaterialized =
            didConfirmActionRollbackReadyBoundaryMaterialized
        this.didConfirmOwnerAcceptanceRequired =
            didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted = didConfirmOwnerAcceptanceGranted
        this.didConfirmActionDispatchBlocked =
            didConfirmActionDispatchBlocked
        this.didConfirmStage216InteractionRunwayReadinessDecisionInputPrepared =
            didConfirmStage216InteractionRunwayReadinessDecisionInputPrepared
        this.didConfirmInputEventPipelineExecuted =
            didConfirmInputEventPipelineExecuted
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

func cjguiInternalBuildRendererStage215ActionSemanticDiffExplainFacts(
    actionPreviewPacket:
        CjguiInternalRendererStage214ActionPreviewPacketReadiness
): CjguiInternalRendererStage215ActionSemanticDiffExplainFacts {
    return CjguiInternalRendererStage215ActionSemanticDiffExplainFacts(
        actionPreviewPacket.didConfirmActionPreviewPacketReady,
        true,
        true,
        actionPreviewPacket.didConfirmActionPreviewPacketMaterialized,
        actionPreviewPacket.didConfirmActionPreviewBoundToSemanticNode,
        actionPreviewPacket
            .didConfirmActionPreviewBoundToOwnerLocalRollbackBoundary,
        true,
        true,
        actionPreviewPacket.didConfirmInputEventPipelineExecuted == false,
        actionPreviewPacket.didConfirmActionDispatchExecuted == false,
        actionPreviewPacket.didConfirmVisibilityPublished == false,
        actionPreviewPacket.didConfirmRendererSubmissionBlocked,
        actionPreviewPacket.didConfirmRendererStateWriteBlocked,
        actionPreviewPacket.didConfirmRuntimeStateWriteBlocked,
        actionPreviewPacket.didConfirmPublicComponentApiAdded == false,
        actionPreviewPacket.didConfirmLayoutEngineEnabled == false
    )
}

func cjguiInternalBuildRendererStage215ActionSemanticDiffExplainReadiness(
    actionPreviewPacket:
        CjguiInternalRendererStage214ActionPreviewPacketReadiness,
    actionSemanticDiffExplainFacts:
        CjguiInternalRendererStage215ActionSemanticDiffExplainFacts
): CjguiInternalRendererStage215ActionSemanticDiffExplainReadiness {
    let diffExplainReady =
        actionSemanticDiffExplainFacts.didConsumeStage214ActionPreviewPacket &&
        actionSemanticDiffExplainFacts.didMaterializeActionSemanticDiff &&
        actionSemanticDiffExplainFacts.didMaterializeActionExplainPacket &&
        actionSemanticDiffExplainFacts.didBindDiffToActionPreviewPacket &&
        actionSemanticDiffExplainFacts.didBindExplainToActionIntentFacts &&
        actionSemanticDiffExplainFacts
            .didMaterializeActionRollbackReadyBoundary &&
        actionSemanticDiffExplainFacts.didKeepOwnerAcceptanceRequired &&
        actionSemanticDiffExplainFacts
            .didPrepareStage216InteractionRunwayReadinessDecisionInput
    let stopLineReady =
        actionSemanticDiffExplainFacts
            .didKeepInputEventPipelineExecutionBlocked &&
        actionSemanticDiffExplainFacts.didKeepActionDispatchBlocked &&
        actionSemanticDiffExplainFacts.didKeepVisibilityNotPublished &&
        actionSemanticDiffExplainFacts.didKeepRendererSubmissionBlocked &&
        actionSemanticDiffExplainFacts.didKeepRendererStateWriteBlocked &&
        actionSemanticDiffExplainFacts.didKeepRuntimeStateWriteBlocked &&
        actionSemanticDiffExplainFacts.didKeepPublicComponentApiBlocked &&
        actionSemanticDiffExplainFacts.didKeepLayoutEngineBlocked

    return CjguiInternalRendererStage215ActionSemanticDiffExplainReadiness(
        actionPreviewPacket,
        actionSemanticDiffExplainFacts,
        diffExplainReady && stopLineReady,
        diffExplainReady && stopLineReady,
        actionSemanticDiffExplainFacts.didMaterializeActionSemanticDiff,
        actionSemanticDiffExplainFacts.didMaterializeActionExplainPacket,
        actionSemanticDiffExplainFacts
            .didMaterializeActionRollbackReadyBoundary,
        actionSemanticDiffExplainFacts.didKeepOwnerAcceptanceRequired,
        false,
        actionSemanticDiffExplainFacts.didKeepActionDispatchBlocked,
        actionSemanticDiffExplainFacts
            .didPrepareStage216InteractionRunwayReadinessDecisionInput,
        false,
        false,
        actionSemanticDiffExplainFacts.didKeepRendererSubmissionBlocked,
        actionSemanticDiffExplainFacts.didKeepRendererStateWriteBlocked,
        actionSemanticDiffExplainFacts.didKeepRuntimeStateWriteBlocked,
        false,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage215ActionSemanticDiffExplainDraft():
    CjguiInternalRendererStage215ActionSemanticDiffExplainReadiness {
    let actionPreview =
        cjguiInternalExecuteDefaultRendererStage214ActionPreviewPacketDraft()
    let facts =
        cjguiInternalBuildRendererStage215ActionSemanticDiffExplainFacts(
            actionPreview
        )
    return cjguiInternalBuildRendererStage215ActionSemanticDiffExplainReadiness(
        actionPreview,
        facts
    )
}
