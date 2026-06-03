// 中文维护注释：本文件是 stage721 component visual state store preflight owner。
// Owner: 消费 stage720 visual runtime manager，生成 owner-local visual state store preflight。
// Truth: 只证明 visual runtime 可形成 state slot / rollback base 的 internal dry-run 形态。
// Stop-line: 不提交 state，不执行 input/action，不发布 visibility，不写 renderer_state/runtime_state。
// Same-shape Boundary Brake: 本 slice 把 visual runtime 到 state store preflight 抽成共享入口。
package cjgui

struct CjguiInternalRendererStage721ComponentVisualStateStorePreflightPlan {
    let didConsumeStage720ReplayVisualRuntimeManager: Bool
    let didConsumeReplayVisualRuntimeManagerReceipts: Bool
    let didMaterializeSharedComponentVisualStateStorePreflight: Bool
    let didMaterializeVisualStateSlotLedger: Bool
    let didMaterializeVisualStateRollbackBaseSnapshot: Bool
    let didMaterializeVisualStyleStateSlot: Bool
    let didMaterializeTextCaretStateSlot: Bool
    let didMaterializeFocusRouteStateSlot: Bool
    let didMaterializeTodoComponentVisualStateStorePreflight: Bool
    let didMaterializeSettingsComponentVisualStateStorePreflight: Bool
    let didMaterializeAiGeneratedSettingsComponentVisualStateStorePreflight: Bool
    let didMaterializeChatComposerComponentVisualStateStorePreflight: Bool
    let didBindStateStorePreflightToStage720VisualRuntimeManager: Bool
    let didKeepVisualStateStorePreflightOwnerLocal: Bool
    let didPrepareStage722ComponentVisualStateStoreDeltaRollback: Bool
    let didKeepHostMutationBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool

    init(
        didConsumeStage720ReplayVisualRuntimeManager: Bool,
        didConsumeReplayVisualRuntimeManagerReceipts: Bool,
        didMaterializeSharedComponentVisualStateStorePreflight: Bool,
        didMaterializeVisualStateSlotLedger: Bool,
        didMaterializeVisualStateRollbackBaseSnapshot: Bool,
        didMaterializeVisualStyleStateSlot: Bool,
        didMaterializeTextCaretStateSlot: Bool,
        didMaterializeFocusRouteStateSlot: Bool,
        didMaterializeTodoComponentVisualStateStorePreflight: Bool,
        didMaterializeSettingsComponentVisualStateStorePreflight: Bool,
        didMaterializeAiGeneratedSettingsComponentVisualStateStorePreflight: Bool,
        didMaterializeChatComposerComponentVisualStateStorePreflight: Bool,
        didBindStateStorePreflightToStage720VisualRuntimeManager: Bool,
        didKeepVisualStateStorePreflightOwnerLocal: Bool,
        didPrepareStage722ComponentVisualStateStoreDeltaRollback: Bool,
        didKeepHostMutationBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool
    ) {
        this.didConsumeStage720ReplayVisualRuntimeManager = didConsumeStage720ReplayVisualRuntimeManager
        this.didConsumeReplayVisualRuntimeManagerReceipts = didConsumeReplayVisualRuntimeManagerReceipts
        this.didMaterializeSharedComponentVisualStateStorePreflight = didMaterializeSharedComponentVisualStateStorePreflight
        this.didMaterializeVisualStateSlotLedger = didMaterializeVisualStateSlotLedger
        this.didMaterializeVisualStateRollbackBaseSnapshot = didMaterializeVisualStateRollbackBaseSnapshot
        this.didMaterializeVisualStyleStateSlot = didMaterializeVisualStyleStateSlot
        this.didMaterializeTextCaretStateSlot = didMaterializeTextCaretStateSlot
        this.didMaterializeFocusRouteStateSlot = didMaterializeFocusRouteStateSlot
        this.didMaterializeTodoComponentVisualStateStorePreflight = didMaterializeTodoComponentVisualStateStorePreflight
        this.didMaterializeSettingsComponentVisualStateStorePreflight = didMaterializeSettingsComponentVisualStateStorePreflight
        this.didMaterializeAiGeneratedSettingsComponentVisualStateStorePreflight = didMaterializeAiGeneratedSettingsComponentVisualStateStorePreflight
        this.didMaterializeChatComposerComponentVisualStateStorePreflight = didMaterializeChatComposerComponentVisualStateStorePreflight
        this.didBindStateStorePreflightToStage720VisualRuntimeManager = didBindStateStorePreflightToStage720VisualRuntimeManager
        this.didKeepVisualStateStorePreflightOwnerLocal = didKeepVisualStateStorePreflightOwnerLocal
        this.didPrepareStage722ComponentVisualStateStoreDeltaRollback = didPrepareStage722ComponentVisualStateStoreDeltaRollback
        this.didKeepHostMutationBlocked = didKeepHostMutationBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
    }
}

struct CjguiInternalRendererStage721ComponentVisualStateStorePreflightFacts {
    let stateStorePreflightPlan: CjguiInternalRendererStage721ComponentVisualStateStorePreflightPlan
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didKeepProductionRenderTruthBlocked: Bool
    let didKeepBackendReadyTruthBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepInputEventPipelineExecutionBlocked: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepVisibilityPublicationAdmittedBlocked: Bool
    let didKeepVisibilityPublishedBlocked: Bool
    let didKeepNativeBridgeExpansionBlocked: Bool

    init(
        stateStorePreflightPlan: CjguiInternalRendererStage721ComponentVisualStateStorePreflightPlan,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didKeepProductionRenderTruthBlocked: Bool,
        didKeepBackendReadyTruthBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepInputEventPipelineExecutionBlocked: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepVisibilityPublicationAdmittedBlocked: Bool,
        didKeepVisibilityPublishedBlocked: Bool,
        didKeepNativeBridgeExpansionBlocked: Bool
    ) {
        this.stateStorePreflightPlan = stateStorePreflightPlan
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didKeepOwnerAcceptanceNotGranted = didKeepOwnerAcceptanceNotGranted
        this.didKeepProductionRenderTruthBlocked = didKeepProductionRenderTruthBlocked
        this.didKeepBackendReadyTruthBlocked = didKeepBackendReadyTruthBlocked
        this.didKeepPublicComponentApiBlocked = didKeepPublicComponentApiBlocked
        this.didKeepInputEventPipelineExecutionBlocked = didKeepInputEventPipelineExecutionBlocked
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepStateUpdateCommittedBlocked = didKeepStateUpdateCommittedBlocked
        this.didKeepVisibilityPublicationAdmittedBlocked = didKeepVisibilityPublicationAdmittedBlocked
        this.didKeepVisibilityPublishedBlocked = didKeepVisibilityPublishedBlocked
        this.didKeepNativeBridgeExpansionBlocked = didKeepNativeBridgeExpansionBlocked
    }
}

struct CjguiInternalRendererStage721ComponentVisualStateStorePreflightReadiness {
    let visualRuntimeManager: CjguiInternalRendererStage720ReplayVisualRuntimeManagerReadiness
    let stateStorePreflightPlan: CjguiInternalRendererStage721ComponentVisualStateStorePreflightPlan
    let stateStorePreflightFacts: CjguiInternalRendererStage721ComponentVisualStateStorePreflightFacts
    let didConfirmStage721ComponentVisualStateStorePreflightReady: Bool
    let didConfirmStage720ReplayVisualRuntimeManagerConsumed: Bool
    let didConfirmStage719ReplayTextCaretHostSurfaceConsumedTransitively: Bool
    let didConfirmReplayVisualRuntimeManagerReceiptsConsumed: Bool
    let didConfirmSharedComponentVisualStateStorePreflightMaterialized: Bool
    let didConfirmVisualStateSlotLedgerMaterialized: Bool
    let didConfirmVisualStateRollbackBaseSnapshotMaterialized: Bool
    let didConfirmVisualStyleStateSlotMaterialized: Bool
    let didConfirmTextCaretStateSlotMaterialized: Bool
    let didConfirmFocusRouteStateSlotMaterialized: Bool
    let didConfirmTodoComponentVisualStateStorePreflightMaterialized: Bool
    let didConfirmSettingsComponentVisualStateStorePreflightMaterialized: Bool
    let didConfirmAiGeneratedSettingsComponentVisualStateStorePreflightMaterialized: Bool
    let didConfirmChatComposerComponentVisualStateStorePreflightMaterialized: Bool
    let didConfirmStateStorePreflightBoundToStage720VisualRuntimeManager: Bool
    let didConfirmVisualStateStorePreflightOwnerLocal: Bool
    let didConfirmStage722ComponentVisualStateStoreDeltaRollbackPrepared: Bool
    let didConfirmHostMutation: Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmProductionRenderTruth: Bool
    let didConfirmBackendReadyTruth: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmInputEventPipelineExecution: Bool
    let didConfirmActionDispatch: Bool
    let didConfirmStateUpdateCommitted: Bool
    let didConfirmVisibilityPublicationAdmitted: Bool
    let didConfirmVisibilityPublished: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmNativeBridgeExpansionBlocked: Bool

    init(
        visualRuntimeManager: CjguiInternalRendererStage720ReplayVisualRuntimeManagerReadiness,
        stateStorePreflightPlan: CjguiInternalRendererStage721ComponentVisualStateStorePreflightPlan,
        stateStorePreflightFacts: CjguiInternalRendererStage721ComponentVisualStateStorePreflightFacts,
        didConfirmStage721ComponentVisualStateStorePreflightReady: Bool,
        didConfirmStage720ReplayVisualRuntimeManagerConsumed: Bool,
        didConfirmStage719ReplayTextCaretHostSurfaceConsumedTransitively: Bool,
        didConfirmReplayVisualRuntimeManagerReceiptsConsumed: Bool,
        didConfirmSharedComponentVisualStateStorePreflightMaterialized: Bool,
        didConfirmVisualStateSlotLedgerMaterialized: Bool,
        didConfirmVisualStateRollbackBaseSnapshotMaterialized: Bool,
        didConfirmVisualStyleStateSlotMaterialized: Bool,
        didConfirmTextCaretStateSlotMaterialized: Bool,
        didConfirmFocusRouteStateSlotMaterialized: Bool,
        didConfirmTodoComponentVisualStateStorePreflightMaterialized: Bool,
        didConfirmSettingsComponentVisualStateStorePreflightMaterialized: Bool,
        didConfirmAiGeneratedSettingsComponentVisualStateStorePreflightMaterialized: Bool,
        didConfirmChatComposerComponentVisualStateStorePreflightMaterialized: Bool,
        didConfirmStateStorePreflightBoundToStage720VisualRuntimeManager: Bool,
        didConfirmVisualStateStorePreflightOwnerLocal: Bool,
        didConfirmStage722ComponentVisualStateStoreDeltaRollbackPrepared: Bool,
        didConfirmHostMutation: Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmProductionRenderTruth: Bool,
        didConfirmBackendReadyTruth: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmInputEventPipelineExecution: Bool,
        didConfirmActionDispatch: Bool,
        didConfirmStateUpdateCommitted: Bool,
        didConfirmVisibilityPublicationAdmitted: Bool,
        didConfirmVisibilityPublished: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmNativeBridgeExpansionBlocked: Bool
    ) {
        this.visualRuntimeManager = visualRuntimeManager
        this.stateStorePreflightPlan = stateStorePreflightPlan
        this.stateStorePreflightFacts = stateStorePreflightFacts
        this.didConfirmStage721ComponentVisualStateStorePreflightReady = didConfirmStage721ComponentVisualStateStorePreflightReady
        this.didConfirmStage720ReplayVisualRuntimeManagerConsumed = didConfirmStage720ReplayVisualRuntimeManagerConsumed
        this.didConfirmStage719ReplayTextCaretHostSurfaceConsumedTransitively = didConfirmStage719ReplayTextCaretHostSurfaceConsumedTransitively
        this.didConfirmReplayVisualRuntimeManagerReceiptsConsumed = didConfirmReplayVisualRuntimeManagerReceiptsConsumed
        this.didConfirmSharedComponentVisualStateStorePreflightMaterialized = didConfirmSharedComponentVisualStateStorePreflightMaterialized
        this.didConfirmVisualStateSlotLedgerMaterialized = didConfirmVisualStateSlotLedgerMaterialized
        this.didConfirmVisualStateRollbackBaseSnapshotMaterialized = didConfirmVisualStateRollbackBaseSnapshotMaterialized
        this.didConfirmVisualStyleStateSlotMaterialized = didConfirmVisualStyleStateSlotMaterialized
        this.didConfirmTextCaretStateSlotMaterialized = didConfirmTextCaretStateSlotMaterialized
        this.didConfirmFocusRouteStateSlotMaterialized = didConfirmFocusRouteStateSlotMaterialized
        this.didConfirmTodoComponentVisualStateStorePreflightMaterialized = didConfirmTodoComponentVisualStateStorePreflightMaterialized
        this.didConfirmSettingsComponentVisualStateStorePreflightMaterialized = didConfirmSettingsComponentVisualStateStorePreflightMaterialized
        this.didConfirmAiGeneratedSettingsComponentVisualStateStorePreflightMaterialized = didConfirmAiGeneratedSettingsComponentVisualStateStorePreflightMaterialized
        this.didConfirmChatComposerComponentVisualStateStorePreflightMaterialized = didConfirmChatComposerComponentVisualStateStorePreflightMaterialized
        this.didConfirmStateStorePreflightBoundToStage720VisualRuntimeManager = didConfirmStateStorePreflightBoundToStage720VisualRuntimeManager
        this.didConfirmVisualStateStorePreflightOwnerLocal = didConfirmVisualStateStorePreflightOwnerLocal
        this.didConfirmStage722ComponentVisualStateStoreDeltaRollbackPrepared = didConfirmStage722ComponentVisualStateStoreDeltaRollbackPrepared
        this.didConfirmHostMutation = didConfirmHostMutation
        this.didConfirmOwnerAcceptanceRequired = didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted = didConfirmOwnerAcceptanceGranted
        this.didConfirmProductionRenderTruth = didConfirmProductionRenderTruth
        this.didConfirmBackendReadyTruth = didConfirmBackendReadyTruth
        this.didConfirmPublicComponentApiAdded = didConfirmPublicComponentApiAdded
        this.didConfirmInputEventPipelineExecution = didConfirmInputEventPipelineExecution
        this.didConfirmActionDispatch = didConfirmActionDispatch
        this.didConfirmStateUpdateCommitted = didConfirmStateUpdateCommitted
        this.didConfirmVisibilityPublicationAdmitted = didConfirmVisibilityPublicationAdmitted
        this.didConfirmVisibilityPublished = didConfirmVisibilityPublished
        this.didConfirmRendererSubmissionBlocked = didConfirmRendererSubmissionBlocked
        this.didConfirmRendererStateWriteBlocked = didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked = didConfirmRuntimeStateWriteBlocked
        this.didConfirmNativeBridgeExpansionBlocked = didConfirmNativeBridgeExpansionBlocked
    }
}

func cjguiInternalRendererStage721ComponentVisualStateStorePreflightMaterialized(): Bool {
    return true
}

func cjguiInternalBuildRendererStage721ComponentVisualStateStorePreflightPlan(
    visualRuntimeManager: CjguiInternalRendererStage720ReplayVisualRuntimeManagerReadiness): CjguiInternalRendererStage721ComponentVisualStateStorePreflightPlan {
    let stage720Ready = visualRuntimeManager.didConfirmStage720ReplayVisualRuntimeManagerReady && visualRuntimeManager
        .didConfirmStage721ComponentRuntimeVisualStateStorePreflightPrepared
    let visualRuntimeReceiptsReady = visualRuntimeManager.didConfirmSharedReplayVisualRuntimeManagerMaterialized && visualRuntimeManager
        .didConfirmSharedReplayVisualRuntimeContractMaterialized && visualRuntimeManager
        .didConfirmReplayVisualExecutionReceiptContractMaterialized && visualRuntimeManager
        .didConfirmChatComposerReplayVisualRuntimeSurfaceMaterialized
    let preflightReady = stage720Ready && visualRuntimeReceiptsReady &&
        cjguiInternalRendererStage721ComponentVisualStateStorePreflightMaterialized()
    return CjguiInternalRendererStage721ComponentVisualStateStorePreflightPlan(
        stage720Ready,
        visualRuntimeReceiptsReady,
        preflightReady,
        preflightReady,
        preflightReady,
        preflightReady,
        preflightReady,
        preflightReady,
        preflightReady,
        preflightReady,
        preflightReady,
        preflightReady,
        preflightReady,
        preflightReady,
        preflightReady,
        visualRuntimeManager.didConfirmHostMutation == false,
        visualRuntimeManager.didConfirmRendererSubmissionBlocked,
        visualRuntimeManager.didConfirmRendererStateWriteBlocked,
        visualRuntimeManager.didConfirmRuntimeStateWriteBlocked
    )
}

func cjguiInternalBuildRendererStage721ComponentVisualStateStorePreflightFacts(
    visualRuntimeManager: CjguiInternalRendererStage720ReplayVisualRuntimeManagerReadiness,
    stateStorePreflightPlan: CjguiInternalRendererStage721ComponentVisualStateStorePreflightPlan
): CjguiInternalRendererStage721ComponentVisualStateStorePreflightFacts {
    return CjguiInternalRendererStage721ComponentVisualStateStorePreflightFacts(
        stateStorePreflightPlan,
        visualRuntimeManager.didConfirmOwnerAcceptanceRequired,
        visualRuntimeManager.didConfirmOwnerAcceptanceGranted == false,
        visualRuntimeManager.didConfirmProductionRenderTruth == false,
        visualRuntimeManager.didConfirmBackendReadyTruth == false,
        visualRuntimeManager.didConfirmPublicComponentApiAdded == false,
        visualRuntimeManager.didConfirmInputEventPipelineExecution == false,
        visualRuntimeManager.didConfirmActionDispatch == false,
        visualRuntimeManager.didConfirmStateUpdateCommitted == false,
        visualRuntimeManager.didConfirmVisibilityPublicationAdmitted == false,
        visualRuntimeManager.didConfirmVisibilityPublished == false,
        visualRuntimeManager.didConfirmNativeBridgeExpansionBlocked
    )
}

func cjguiInternalBuildRendererStage721ComponentVisualStateStorePreflightReadiness(
    visualRuntimeManager: CjguiInternalRendererStage720ReplayVisualRuntimeManagerReadiness,
    stateStorePreflightPlan: CjguiInternalRendererStage721ComponentVisualStateStorePreflightPlan,
    stateStorePreflightFacts: CjguiInternalRendererStage721ComponentVisualStateStorePreflightFacts
): CjguiInternalRendererStage721ComponentVisualStateStorePreflightReadiness {
    let preflightReady = stateStorePreflightPlan.didConsumeStage720ReplayVisualRuntimeManager && stateStorePreflightPlan
        .didConsumeReplayVisualRuntimeManagerReceipts && stateStorePreflightPlan
        .didMaterializeSharedComponentVisualStateStorePreflight && stateStorePreflightPlan
        .didMaterializeVisualStateSlotLedger && stateStorePreflightPlan.didMaterializeVisualStateRollbackBaseSnapshot && stateStorePreflightPlan
        .didMaterializeChatComposerComponentVisualStateStorePreflight && stateStorePreflightPlan
        .didBindStateStorePreflightToStage720VisualRuntimeManager && stateStorePreflightPlan
        .didKeepVisualStateStorePreflightOwnerLocal && stateStorePreflightPlan
        .didPrepareStage722ComponentVisualStateStoreDeltaRollback
    let stopLineReady = stateStorePreflightPlan.didKeepHostMutationBlocked && stateStorePreflightFacts
        .didKeepOwnerAcceptanceRequired && stateStorePreflightFacts.didKeepOwnerAcceptanceNotGranted && stateStorePreflightFacts
        .didKeepProductionRenderTruthBlocked && stateStorePreflightFacts.didKeepBackendReadyTruthBlocked && stateStorePreflightFacts
        .didKeepPublicComponentApiBlocked && stateStorePreflightFacts.didKeepInputEventPipelineExecutionBlocked && stateStorePreflightFacts
        .didKeepActionDispatchBlocked && stateStorePreflightFacts.didKeepStateUpdateCommittedBlocked && stateStorePreflightFacts
        .didKeepVisibilityPublicationAdmittedBlocked && stateStorePreflightFacts.didKeepVisibilityPublishedBlocked && stateStorePreflightPlan
        .didKeepRendererSubmissionBlocked && stateStorePreflightPlan.didKeepRendererStateWriteBlocked && stateStorePreflightPlan
        .didKeepRuntimeStateWriteBlocked && stateStorePreflightFacts.didKeepNativeBridgeExpansionBlocked
    return CjguiInternalRendererStage721ComponentVisualStateStorePreflightReadiness(
        visualRuntimeManager,
        stateStorePreflightPlan,
        stateStorePreflightFacts,
        preflightReady && stopLineReady,
        stateStorePreflightPlan.didConsumeStage720ReplayVisualRuntimeManager,
        visualRuntimeManager.didConfirmStage719ReplayTextCaretHostSurfaceConsumed,
        stateStorePreflightPlan.didConsumeReplayVisualRuntimeManagerReceipts,
        stateStorePreflightPlan.didMaterializeSharedComponentVisualStateStorePreflight,
        stateStorePreflightPlan.didMaterializeVisualStateSlotLedger,
        stateStorePreflightPlan.didMaterializeVisualStateRollbackBaseSnapshot,
        stateStorePreflightPlan.didMaterializeVisualStyleStateSlot,
        stateStorePreflightPlan.didMaterializeTextCaretStateSlot,
        stateStorePreflightPlan.didMaterializeFocusRouteStateSlot,
        stateStorePreflightPlan.didMaterializeTodoComponentVisualStateStorePreflight,
        stateStorePreflightPlan.didMaterializeSettingsComponentVisualStateStorePreflight,
        stateStorePreflightPlan.didMaterializeAiGeneratedSettingsComponentVisualStateStorePreflight,
        stateStorePreflightPlan.didMaterializeChatComposerComponentVisualStateStorePreflight,
        stateStorePreflightPlan.didBindStateStorePreflightToStage720VisualRuntimeManager,
        stateStorePreflightPlan.didKeepVisualStateStorePreflightOwnerLocal,
        stateStorePreflightPlan.didPrepareStage722ComponentVisualStateStoreDeltaRollback,
        false,
        stateStorePreflightFacts.didKeepOwnerAcceptanceRequired,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        stateStorePreflightPlan.didKeepRendererSubmissionBlocked,
        stateStorePreflightPlan.didKeepRendererStateWriteBlocked,
        stateStorePreflightPlan.didKeepRuntimeStateWriteBlocked,
        stateStorePreflightFacts.didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage721ComponentVisualStateStorePreflightDraft(): CjguiInternalRendererStage721ComponentVisualStateStorePreflightReadiness {
    let visualRuntimeManager = cjguiInternalExecuteDefaultRendererStage720ReplayVisualRuntimeManagerDraft()
    let stateStorePreflightPlan = cjguiInternalBuildRendererStage721ComponentVisualStateStorePreflightPlan(
        visualRuntimeManager)
    let stateStorePreflightFacts = cjguiInternalBuildRendererStage721ComponentVisualStateStorePreflightFacts(
        visualRuntimeManager,
        stateStorePreflightPlan
    )
    return cjguiInternalBuildRendererStage721ComponentVisualStateStorePreflightReadiness(
        visualRuntimeManager,
        stateStorePreflightPlan,
        stateStorePreflightFacts
    )
}
