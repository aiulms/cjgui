// 中文维护注释：本文件是 stage218 state update preview packet owner。
// Owner: 消费 stage217 dry-run，生成 state before/after preview packet，
// 并把它绑定回 action preview 与 rollback preview。
// Truth: preview packet 是可解释输入，不代表状态提交或 visibility 发布。
// Stop-line: 不提交 state update，不写 renderer/runtime state。
package cjgui

struct CjguiInternalRendererStage218StateUpdatePreviewPacketFacts {
    let didConsumeStage217StateUpdateAfterActionDryRun: Bool
    let didMaterializeStateUpdatePreviewPacket: Bool
    let didBindPreviewPacketToActionPreview: Bool
    let didBindPreviewPacketToRollbackPreview: Bool
    let didCarryOwnerLocalBeforeAfterStateRevisions: Bool
    let didPreserveStateUpdateNonCommitting: Bool
    let didPrepareStage219StateUpdateSemanticDiffInput: Bool
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didKeepInputEventPipelineExecutionBlocked: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepVisibilityNotPublished: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepLayoutEngineBlocked: Bool

    init(
        didConsumeStage217StateUpdateAfterActionDryRun: Bool,
        didMaterializeStateUpdatePreviewPacket: Bool,
        didBindPreviewPacketToActionPreview: Bool,
        didBindPreviewPacketToRollbackPreview: Bool,
        didCarryOwnerLocalBeforeAfterStateRevisions: Bool,
        didPreserveStateUpdateNonCommitting: Bool,
        didPrepareStage219StateUpdateSemanticDiffInput: Bool,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didKeepInputEventPipelineExecutionBlocked: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepVisibilityNotPublished: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepLayoutEngineBlocked: Bool
    ) {
        this.didConsumeStage217StateUpdateAfterActionDryRun =
            didConsumeStage217StateUpdateAfterActionDryRun
        this.didMaterializeStateUpdatePreviewPacket =
            didMaterializeStateUpdatePreviewPacket
        this.didBindPreviewPacketToActionPreview =
            didBindPreviewPacketToActionPreview
        this.didBindPreviewPacketToRollbackPreview =
            didBindPreviewPacketToRollbackPreview
        this.didCarryOwnerLocalBeforeAfterStateRevisions =
            didCarryOwnerLocalBeforeAfterStateRevisions
        this.didPreserveStateUpdateNonCommitting =
            didPreserveStateUpdateNonCommitting
        this.didPrepareStage219StateUpdateSemanticDiffInput =
            didPrepareStage219StateUpdateSemanticDiffInput
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didKeepOwnerAcceptanceNotGranted =
            didKeepOwnerAcceptanceNotGranted
        this.didKeepInputEventPipelineExecutionBlocked =
            didKeepInputEventPipelineExecutionBlocked
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepStateUpdateCommittedBlocked =
            didKeepStateUpdateCommittedBlocked
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

struct CjguiInternalRendererStage218StateUpdatePreviewPacketReadiness {
    let stateUpdateAfterActionDryRun:
        CjguiInternalRendererStage217StateUpdateAfterActionDryRunReadiness
    let stateUpdatePreviewPacketFacts:
        CjguiInternalRendererStage218StateUpdatePreviewPacketFacts
    let didPrepareStage218StateUpdatePreviewPacketReadiness: Bool
    let didConfirmStateUpdatePreviewPacketReady: Bool
    let didConfirmStateUpdatePreviewPacketMaterialized: Bool
    let didConfirmStateUpdatePreviewBoundToActionPreview: Bool
    let didConfirmStateUpdatePreviewBoundToRollbackPreview: Bool
    let didConfirmStateUpdatePreviewNonCommitting: Bool
    let didConfirmStage219StateUpdateSemanticDiffInputPrepared: Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmInputEventPipelineExecuted: Bool
    let didConfirmActionDispatchExecuted: Bool
    let didConfirmStateUpdateCommitted: Bool
    let didConfirmVisibilityPublished: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmLayoutEngineEnabled: Bool

    init(
        stateUpdateAfterActionDryRun:
            CjguiInternalRendererStage217StateUpdateAfterActionDryRunReadiness,
        stateUpdatePreviewPacketFacts:
            CjguiInternalRendererStage218StateUpdatePreviewPacketFacts,
        didPrepareStage218StateUpdatePreviewPacketReadiness: Bool,
        didConfirmStateUpdatePreviewPacketReady: Bool,
        didConfirmStateUpdatePreviewPacketMaterialized: Bool,
        didConfirmStateUpdatePreviewBoundToActionPreview: Bool,
        didConfirmStateUpdatePreviewBoundToRollbackPreview: Bool,
        didConfirmStateUpdatePreviewNonCommitting: Bool,
        didConfirmStage219StateUpdateSemanticDiffInputPrepared: Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmInputEventPipelineExecuted: Bool,
        didConfirmActionDispatchExecuted: Bool,
        didConfirmStateUpdateCommitted: Bool,
        didConfirmVisibilityPublished: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmLayoutEngineEnabled: Bool
    ) {
        this.stateUpdateAfterActionDryRun = stateUpdateAfterActionDryRun
        this.stateUpdatePreviewPacketFacts =
            stateUpdatePreviewPacketFacts
        this.didPrepareStage218StateUpdatePreviewPacketReadiness =
            didPrepareStage218StateUpdatePreviewPacketReadiness
        this.didConfirmStateUpdatePreviewPacketReady =
            didConfirmStateUpdatePreviewPacketReady
        this.didConfirmStateUpdatePreviewPacketMaterialized =
            didConfirmStateUpdatePreviewPacketMaterialized
        this.didConfirmStateUpdatePreviewBoundToActionPreview =
            didConfirmStateUpdatePreviewBoundToActionPreview
        this.didConfirmStateUpdatePreviewBoundToRollbackPreview =
            didConfirmStateUpdatePreviewBoundToRollbackPreview
        this.didConfirmStateUpdatePreviewNonCommitting =
            didConfirmStateUpdatePreviewNonCommitting
        this.didConfirmStage219StateUpdateSemanticDiffInputPrepared =
            didConfirmStage219StateUpdateSemanticDiffInputPrepared
        this.didConfirmOwnerAcceptanceRequired =
            didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted =
            didConfirmOwnerAcceptanceGranted
        this.didConfirmInputEventPipelineExecuted =
            didConfirmInputEventPipelineExecuted
        this.didConfirmActionDispatchExecuted =
            didConfirmActionDispatchExecuted
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
        this.didConfirmLayoutEngineEnabled = didConfirmLayoutEngineEnabled
    }
}

func cjguiInternalBuildRendererStage218StateUpdatePreviewPacketFacts(
    stateUpdateAfterActionDryRun:
        CjguiInternalRendererStage217StateUpdateAfterActionDryRunReadiness
): CjguiInternalRendererStage218StateUpdatePreviewPacketFacts {
    let actionPreview = stateUpdateAfterActionDryRun
        .interactionRunwayReadinessDecision.actionSemanticDiffExplain
        .actionPreviewPacket
    let dryRunFacts =
        stateUpdateAfterActionDryRun.stateUpdateAfterActionDryRunFacts

    return CjguiInternalRendererStage218StateUpdatePreviewPacketFacts(
        stateUpdateAfterActionDryRun
            .didConfirmStateUpdateAfterActionDryRunReady,
        true,
        actionPreview.didConfirmActionPreviewPacketReady &&
            dryRunFacts.didBindActionIntentToOwnerLocalStateUpdateCandidate,
        stateUpdateAfterActionDryRun
            .didConfirmStateUpdateRollbackPreviewMaterialized,
        dryRunFacts.previewStateRevision > dryRunFacts.beforeStateRevision,
        stateUpdateAfterActionDryRun.didConfirmStateUpdateCommitted == false,
        true,
        stateUpdateAfterActionDryRun.didConfirmOwnerAcceptanceRequired,
        stateUpdateAfterActionDryRun.didConfirmOwnerAcceptanceGranted == false,
        stateUpdateAfterActionDryRun.didConfirmInputEventPipelineExecuted == false,
        stateUpdateAfterActionDryRun.didConfirmActionDispatchExecuted == false,
        stateUpdateAfterActionDryRun.didConfirmStateUpdateCommitted == false,
        stateUpdateAfterActionDryRun.didConfirmVisibilityPublished == false,
        stateUpdateAfterActionDryRun.didConfirmRendererSubmissionBlocked,
        stateUpdateAfterActionDryRun.didConfirmRendererStateWriteBlocked,
        stateUpdateAfterActionDryRun.didConfirmRuntimeStateWriteBlocked,
        stateUpdateAfterActionDryRun.didConfirmPublicComponentApiAdded == false,
        stateUpdateAfterActionDryRun.didConfirmLayoutEngineEnabled == false
    )
}

func cjguiInternalBuildRendererStage218StateUpdatePreviewPacketReadiness(
    stateUpdateAfterActionDryRun:
        CjguiInternalRendererStage217StateUpdateAfterActionDryRunReadiness,
    stateUpdatePreviewPacketFacts:
        CjguiInternalRendererStage218StateUpdatePreviewPacketFacts
): CjguiInternalRendererStage218StateUpdatePreviewPacketReadiness {
    let previewReady =
        stateUpdatePreviewPacketFacts
            .didConsumeStage217StateUpdateAfterActionDryRun &&
        stateUpdatePreviewPacketFacts.didMaterializeStateUpdatePreviewPacket &&
        stateUpdatePreviewPacketFacts.didBindPreviewPacketToActionPreview &&
        stateUpdatePreviewPacketFacts.didBindPreviewPacketToRollbackPreview &&
        stateUpdatePreviewPacketFacts
            .didCarryOwnerLocalBeforeAfterStateRevisions &&
        stateUpdatePreviewPacketFacts.didPreserveStateUpdateNonCommitting &&
        stateUpdatePreviewPacketFacts
            .didPrepareStage219StateUpdateSemanticDiffInput
    let stopLineReady =
        stateUpdatePreviewPacketFacts.didKeepOwnerAcceptanceRequired &&
        stateUpdatePreviewPacketFacts.didKeepOwnerAcceptanceNotGranted &&
        stateUpdatePreviewPacketFacts
            .didKeepInputEventPipelineExecutionBlocked &&
        stateUpdatePreviewPacketFacts.didKeepActionDispatchBlocked &&
        stateUpdatePreviewPacketFacts.didKeepStateUpdateCommittedBlocked &&
        stateUpdatePreviewPacketFacts.didKeepVisibilityNotPublished &&
        stateUpdatePreviewPacketFacts.didKeepRendererSubmissionBlocked &&
        stateUpdatePreviewPacketFacts.didKeepRendererStateWriteBlocked &&
        stateUpdatePreviewPacketFacts.didKeepRuntimeStateWriteBlocked &&
        stateUpdatePreviewPacketFacts.didKeepPublicComponentApiBlocked &&
        stateUpdatePreviewPacketFacts.didKeepLayoutEngineBlocked

    return CjguiInternalRendererStage218StateUpdatePreviewPacketReadiness(
        stateUpdateAfterActionDryRun,
        stateUpdatePreviewPacketFacts,
        previewReady && stopLineReady,
        previewReady && stopLineReady,
        stateUpdatePreviewPacketFacts.didMaterializeStateUpdatePreviewPacket,
        stateUpdatePreviewPacketFacts.didBindPreviewPacketToActionPreview,
        stateUpdatePreviewPacketFacts.didBindPreviewPacketToRollbackPreview,
        stateUpdatePreviewPacketFacts.didPreserveStateUpdateNonCommitting,
        stateUpdatePreviewPacketFacts
            .didPrepareStage219StateUpdateSemanticDiffInput,
        stateUpdatePreviewPacketFacts.didKeepOwnerAcceptanceRequired,
        false,
        false,
        false,
        false,
        false,
        stateUpdatePreviewPacketFacts.didKeepRendererSubmissionBlocked,
        stateUpdatePreviewPacketFacts.didKeepRendererStateWriteBlocked,
        stateUpdatePreviewPacketFacts.didKeepRuntimeStateWriteBlocked,
        false,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage218StateUpdatePreviewPacketDraft():
    CjguiInternalRendererStage218StateUpdatePreviewPacketReadiness {
    let dryRun =
        cjguiInternalExecuteDefaultRendererStage217StateUpdateAfterActionDryRunDraft()
    let facts =
        cjguiInternalBuildRendererStage218StateUpdatePreviewPacketFacts(
            dryRun
        )
    return cjguiInternalBuildRendererStage218StateUpdatePreviewPacketReadiness(
        dryRun,
        facts
    )
}
