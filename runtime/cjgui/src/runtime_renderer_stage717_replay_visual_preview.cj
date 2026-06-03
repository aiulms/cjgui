// 中文维护注释：本文件是 stage717 replay visual preview owner。
// Owner: 消费 stage716 action-state-render executor，生成 layout/style/text/focus preview。
// Truth: 只证明 replay render result 可进入可检查 visual preview，不启用真实 layout/style/text/focus 引擎。
// Stop-line: 不执行 input pipeline、不 dispatch、不提交 state、不发布 visibility、不写 renderer_state/runtime_state。
// Same-shape Boundary Brake: 本 slice 将四个 demo 的 replay visual preview 压缩为共享 ledger。
package cjgui

struct CjguiInternalRendererStage717ReplayVisualPreviewPlan {
    let didConsumeStage716ComponentRuntimeInputEventReplayActionStateRenderExecutor: Bool
    let didConsumeReplayActionStateRenderRuntimeSurfaces: Bool
    let didMaterializeSharedReplayLayoutStyleTextFocusPreview: Bool
    let didMaterializeReplayLayoutConstraintLedger: Bool
    let didMaterializeReplayStyleTokenLedger: Bool
    let didMaterializeReplayTextRunLedger: Bool
    let didMaterializeReplayFocusTargetLedger: Bool
    let didMaterializeTodoReplayVisualPreviewSurface: Bool
    let didMaterializeSettingsReplayVisualPreviewSurface: Bool
    let didMaterializeAiGeneratedSettingsReplayVisualPreviewSurface: Bool
    let didMaterializeChatComposerReplayVisualPreviewSurface: Bool
    let didBindReplayVisualPreviewToStage716Executor: Bool
    let didKeepReplayVisualPreviewCheckable: Bool
    let didPrepareStage718ReplayStyleFocusResolver: Bool
    let didKeepHostMutationBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool

    init(
        didConsumeStage716ComponentRuntimeInputEventReplayActionStateRenderExecutor: Bool,
        didConsumeReplayActionStateRenderRuntimeSurfaces: Bool,
        didMaterializeSharedReplayLayoutStyleTextFocusPreview: Bool,
        didMaterializeReplayLayoutConstraintLedger: Bool,
        didMaterializeReplayStyleTokenLedger: Bool,
        didMaterializeReplayTextRunLedger: Bool,
        didMaterializeReplayFocusTargetLedger: Bool,
        didMaterializeTodoReplayVisualPreviewSurface: Bool,
        didMaterializeSettingsReplayVisualPreviewSurface: Bool,
        didMaterializeAiGeneratedSettingsReplayVisualPreviewSurface: Bool,
        didMaterializeChatComposerReplayVisualPreviewSurface: Bool,
        didBindReplayVisualPreviewToStage716Executor: Bool,
        didKeepReplayVisualPreviewCheckable: Bool,
        didPrepareStage718ReplayStyleFocusResolver: Bool,
        didKeepHostMutationBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool
    ) {
        this.didConsumeStage716ComponentRuntimeInputEventReplayActionStateRenderExecutor = didConsumeStage716ComponentRuntimeInputEventReplayActionStateRenderExecutor
        this.didConsumeReplayActionStateRenderRuntimeSurfaces = didConsumeReplayActionStateRenderRuntimeSurfaces
        this.didMaterializeSharedReplayLayoutStyleTextFocusPreview = didMaterializeSharedReplayLayoutStyleTextFocusPreview
        this.didMaterializeReplayLayoutConstraintLedger = didMaterializeReplayLayoutConstraintLedger
        this.didMaterializeReplayStyleTokenLedger = didMaterializeReplayStyleTokenLedger
        this.didMaterializeReplayTextRunLedger = didMaterializeReplayTextRunLedger
        this.didMaterializeReplayFocusTargetLedger = didMaterializeReplayFocusTargetLedger
        this.didMaterializeTodoReplayVisualPreviewSurface = didMaterializeTodoReplayVisualPreviewSurface
        this.didMaterializeSettingsReplayVisualPreviewSurface = didMaterializeSettingsReplayVisualPreviewSurface
        this.didMaterializeAiGeneratedSettingsReplayVisualPreviewSurface = didMaterializeAiGeneratedSettingsReplayVisualPreviewSurface
        this.didMaterializeChatComposerReplayVisualPreviewSurface = didMaterializeChatComposerReplayVisualPreviewSurface
        this.didBindReplayVisualPreviewToStage716Executor = didBindReplayVisualPreviewToStage716Executor
        this.didKeepReplayVisualPreviewCheckable = didKeepReplayVisualPreviewCheckable
        this.didPrepareStage718ReplayStyleFocusResolver = didPrepareStage718ReplayStyleFocusResolver
        this.didKeepHostMutationBlocked = didKeepHostMutationBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
    }
}

struct CjguiInternalRendererStage717ReplayVisualPreviewFacts {
    let visualPreviewPlan: CjguiInternalRendererStage717ReplayVisualPreviewPlan
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
        visualPreviewPlan: CjguiInternalRendererStage717ReplayVisualPreviewPlan,
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
        this.visualPreviewPlan = visualPreviewPlan
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

struct CjguiInternalRendererStage717ReplayVisualPreviewReadiness {
    let actionStateRenderExecutor: CjguiInternalRendererStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorReadiness
    let visualPreviewPlan: CjguiInternalRendererStage717ReplayVisualPreviewPlan
    let visualPreviewFacts: CjguiInternalRendererStage717ReplayVisualPreviewFacts
    let didConfirmStage717ReplayVisualPreviewReady: Bool
    let didConfirmStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorConsumed: Bool
    let didConfirmReplayActionStateRenderRuntimeSurfacesConsumed: Bool
    let didConfirmSharedReplayLayoutStyleTextFocusPreviewMaterialized: Bool
    let didConfirmReplayLayoutConstraintLedgerMaterialized: Bool
    let didConfirmReplayStyleTokenLedgerMaterialized: Bool
    let didConfirmReplayTextRunLedgerMaterialized: Bool
    let didConfirmReplayFocusTargetLedgerMaterialized: Bool
    let didConfirmTodoReplayVisualPreviewSurfaceMaterialized: Bool
    let didConfirmSettingsReplayVisualPreviewSurfaceMaterialized: Bool
    let didConfirmAiGeneratedSettingsReplayVisualPreviewSurfaceMaterialized: Bool
    let didConfirmChatComposerReplayVisualPreviewSurfaceMaterialized: Bool
    let didConfirmReplayVisualPreviewBoundToStage716Executor: Bool
    let didConfirmReplayVisualPreviewCheckable: Bool
    let didConfirmStage718ReplayStyleFocusResolverPrepared: Bool
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
        actionStateRenderExecutor: CjguiInternalRendererStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorReadiness,
        visualPreviewPlan: CjguiInternalRendererStage717ReplayVisualPreviewPlan,
        visualPreviewFacts: CjguiInternalRendererStage717ReplayVisualPreviewFacts,
        didConfirmStage717ReplayVisualPreviewReady: Bool,
        didConfirmStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorConsumed: Bool,
        didConfirmReplayActionStateRenderRuntimeSurfacesConsumed: Bool,
        didConfirmSharedReplayLayoutStyleTextFocusPreviewMaterialized: Bool,
        didConfirmReplayLayoutConstraintLedgerMaterialized: Bool,
        didConfirmReplayStyleTokenLedgerMaterialized: Bool,
        didConfirmReplayTextRunLedgerMaterialized: Bool,
        didConfirmReplayFocusTargetLedgerMaterialized: Bool,
        didConfirmTodoReplayVisualPreviewSurfaceMaterialized: Bool,
        didConfirmSettingsReplayVisualPreviewSurfaceMaterialized: Bool,
        didConfirmAiGeneratedSettingsReplayVisualPreviewSurfaceMaterialized: Bool,
        didConfirmChatComposerReplayVisualPreviewSurfaceMaterialized: Bool,
        didConfirmReplayVisualPreviewBoundToStage716Executor: Bool,
        didConfirmReplayVisualPreviewCheckable: Bool,
        didConfirmStage718ReplayStyleFocusResolverPrepared: Bool,
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
        this.actionStateRenderExecutor = actionStateRenderExecutor
        this.visualPreviewPlan = visualPreviewPlan
        this.visualPreviewFacts = visualPreviewFacts
        this.didConfirmStage717ReplayVisualPreviewReady = didConfirmStage717ReplayVisualPreviewReady
        this.didConfirmStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorConsumed = didConfirmStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorConsumed
        this.didConfirmReplayActionStateRenderRuntimeSurfacesConsumed = didConfirmReplayActionStateRenderRuntimeSurfacesConsumed
        this.didConfirmSharedReplayLayoutStyleTextFocusPreviewMaterialized = didConfirmSharedReplayLayoutStyleTextFocusPreviewMaterialized
        this.didConfirmReplayLayoutConstraintLedgerMaterialized = didConfirmReplayLayoutConstraintLedgerMaterialized
        this.didConfirmReplayStyleTokenLedgerMaterialized = didConfirmReplayStyleTokenLedgerMaterialized
        this.didConfirmReplayTextRunLedgerMaterialized = didConfirmReplayTextRunLedgerMaterialized
        this.didConfirmReplayFocusTargetLedgerMaterialized = didConfirmReplayFocusTargetLedgerMaterialized
        this.didConfirmTodoReplayVisualPreviewSurfaceMaterialized = didConfirmTodoReplayVisualPreviewSurfaceMaterialized
        this.didConfirmSettingsReplayVisualPreviewSurfaceMaterialized = didConfirmSettingsReplayVisualPreviewSurfaceMaterialized
        this.didConfirmAiGeneratedSettingsReplayVisualPreviewSurfaceMaterialized = didConfirmAiGeneratedSettingsReplayVisualPreviewSurfaceMaterialized
        this.didConfirmChatComposerReplayVisualPreviewSurfaceMaterialized = didConfirmChatComposerReplayVisualPreviewSurfaceMaterialized
        this.didConfirmReplayVisualPreviewBoundToStage716Executor = didConfirmReplayVisualPreviewBoundToStage716Executor
        this.didConfirmReplayVisualPreviewCheckable = didConfirmReplayVisualPreviewCheckable
        this.didConfirmStage718ReplayStyleFocusResolverPrepared = didConfirmStage718ReplayStyleFocusResolverPrepared
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

func cjguiInternalRendererStage717ReplayVisualPreviewMaterialized(): Bool {
    return true
}

func cjguiInternalBuildRendererStage717ReplayVisualPreviewPlan(
    actionStateRenderExecutor: CjguiInternalRendererStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorReadiness): CjguiInternalRendererStage717ReplayVisualPreviewPlan {
    let stage716Ready = actionStateRenderExecutor
        .didConfirmStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorReady && actionStateRenderExecutor
        .didConfirmStage717ComponentRuntimeInputEventReplayActionStateRenderLayoutStylePreviewPrepared
    let runtimeSurfacesReady = actionStateRenderExecutor
        .didConfirmSharedComponentRuntimeInputEventReplayActionStateRenderRuntimeContractMaterialized && actionStateRenderExecutor
        .didConfirmTodoComponentRuntimeInputEventReplayActionStateRenderRuntimeSurfaceMaterialized && actionStateRenderExecutor
        .didConfirmSettingsComponentRuntimeInputEventReplayActionStateRenderRuntimeSurfaceMaterialized && actionStateRenderExecutor
        .didConfirmAiGeneratedSettingsComponentRuntimeInputEventReplayActionStateRenderRuntimeSurfaceMaterialized && actionStateRenderExecutor
        .didConfirmChatComposerComponentRuntimeInputEventReplayActionStateRenderRuntimeSurfaceMaterialized
    let previewReady = stage716Ready && runtimeSurfacesReady &&
        cjguiInternalRendererStage717ReplayVisualPreviewMaterialized()
    return CjguiInternalRendererStage717ReplayVisualPreviewPlan(
        stage716Ready,
        runtimeSurfacesReady,
        previewReady,
        previewReady,
        previewReady,
        previewReady,
        previewReady,
        previewReady,
        previewReady,
        previewReady,
        previewReady,
        actionStateRenderExecutor.didConfirmSharedComponentRuntimeInputEventReplayActionStateRenderExecutorMaterialized,
        true,
        previewReady,
        actionStateRenderExecutor.didConfirmHostMutation == false,
        actionStateRenderExecutor.didConfirmRendererSubmissionBlocked,
        actionStateRenderExecutor.didConfirmRendererStateWriteBlocked,
        actionStateRenderExecutor.didConfirmRuntimeStateWriteBlocked
    )
}

func cjguiInternalBuildRendererStage717ReplayVisualPreviewFacts(
    actionStateRenderExecutor: CjguiInternalRendererStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorReadiness,
    visualPreviewPlan: CjguiInternalRendererStage717ReplayVisualPreviewPlan
): CjguiInternalRendererStage717ReplayVisualPreviewFacts {
    return CjguiInternalRendererStage717ReplayVisualPreviewFacts(
        visualPreviewPlan,
        actionStateRenderExecutor.didConfirmOwnerAcceptanceRequired,
        actionStateRenderExecutor.didConfirmOwnerAcceptanceGranted == false,
        actionStateRenderExecutor.didConfirmProductionRenderTruth == false,
        actionStateRenderExecutor.didConfirmBackendReadyTruth == false,
        actionStateRenderExecutor.didConfirmPublicComponentApiAdded == false,
        actionStateRenderExecutor.didConfirmInputEventPipelineExecution == false,
        actionStateRenderExecutor.didConfirmActionDispatch == false,
        actionStateRenderExecutor.didConfirmStateUpdateCommitted == false,
        actionStateRenderExecutor.didConfirmVisibilityPublicationAdmitted == false,
        actionStateRenderExecutor.didConfirmVisibilityPublished == false,
        actionStateRenderExecutor.didConfirmNativeBridgeExpansionBlocked
    )
}

func cjguiInternalBuildRendererStage717ReplayVisualPreviewReadiness(
    actionStateRenderExecutor: CjguiInternalRendererStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorReadiness,
    visualPreviewPlan: CjguiInternalRendererStage717ReplayVisualPreviewPlan,
    visualPreviewFacts: CjguiInternalRendererStage717ReplayVisualPreviewFacts
): CjguiInternalRendererStage717ReplayVisualPreviewReadiness {
    let previewReady = visualPreviewPlan.didConsumeStage716ComponentRuntimeInputEventReplayActionStateRenderExecutor && visualPreviewPlan
        .didConsumeReplayActionStateRenderRuntimeSurfaces && visualPreviewPlan
        .didMaterializeSharedReplayLayoutStyleTextFocusPreview && visualPreviewPlan
        .didMaterializeReplayLayoutConstraintLedger && visualPreviewPlan.didMaterializeReplayStyleTokenLedger && visualPreviewPlan
        .didMaterializeReplayTextRunLedger && visualPreviewPlan.didMaterializeReplayFocusTargetLedger && visualPreviewPlan
        .didMaterializeChatComposerReplayVisualPreviewSurface && visualPreviewPlan
        .didBindReplayVisualPreviewToStage716Executor && visualPreviewPlan.didKeepReplayVisualPreviewCheckable && visualPreviewPlan
        .didPrepareStage718ReplayStyleFocusResolver
    let stopLineReady = visualPreviewPlan.didKeepHostMutationBlocked && visualPreviewFacts
        .didKeepOwnerAcceptanceRequired && visualPreviewFacts.didKeepOwnerAcceptanceNotGranted && visualPreviewFacts
        .didKeepProductionRenderTruthBlocked && visualPreviewFacts.didKeepBackendReadyTruthBlocked && visualPreviewFacts
        .didKeepPublicComponentApiBlocked && visualPreviewFacts.didKeepInputEventPipelineExecutionBlocked && visualPreviewFacts
        .didKeepActionDispatchBlocked && visualPreviewFacts.didKeepStateUpdateCommittedBlocked && visualPreviewFacts
        .didKeepVisibilityPublicationAdmittedBlocked && visualPreviewFacts.didKeepVisibilityPublishedBlocked && visualPreviewPlan
        .didKeepRendererSubmissionBlocked && visualPreviewPlan.didKeepRendererStateWriteBlocked && visualPreviewPlan
        .didKeepRuntimeStateWriteBlocked && visualPreviewFacts.didKeepNativeBridgeExpansionBlocked
    return CjguiInternalRendererStage717ReplayVisualPreviewReadiness(
        actionStateRenderExecutor,
        visualPreviewPlan,
        visualPreviewFacts,
        previewReady && stopLineReady,
        visualPreviewPlan.didConsumeStage716ComponentRuntimeInputEventReplayActionStateRenderExecutor,
        visualPreviewPlan.didConsumeReplayActionStateRenderRuntimeSurfaces,
        visualPreviewPlan.didMaterializeSharedReplayLayoutStyleTextFocusPreview,
        visualPreviewPlan.didMaterializeReplayLayoutConstraintLedger,
        visualPreviewPlan.didMaterializeReplayStyleTokenLedger,
        visualPreviewPlan.didMaterializeReplayTextRunLedger,
        visualPreviewPlan.didMaterializeReplayFocusTargetLedger,
        visualPreviewPlan.didMaterializeTodoReplayVisualPreviewSurface,
        visualPreviewPlan.didMaterializeSettingsReplayVisualPreviewSurface,
        visualPreviewPlan.didMaterializeAiGeneratedSettingsReplayVisualPreviewSurface,
        visualPreviewPlan.didMaterializeChatComposerReplayVisualPreviewSurface,
        visualPreviewPlan.didBindReplayVisualPreviewToStage716Executor,
        visualPreviewPlan.didKeepReplayVisualPreviewCheckable,
        visualPreviewPlan.didPrepareStage718ReplayStyleFocusResolver,
        false,
        visualPreviewFacts.didKeepOwnerAcceptanceRequired,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        visualPreviewPlan.didKeepRendererSubmissionBlocked,
        visualPreviewPlan.didKeepRendererStateWriteBlocked,
        visualPreviewPlan.didKeepRuntimeStateWriteBlocked,
        visualPreviewFacts.didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage717ReplayVisualPreviewDraft(): CjguiInternalRendererStage717ReplayVisualPreviewReadiness {
    let actionStateRenderExecutor = cjguiInternalExecuteDefaultRendererStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorDraft()
    let visualPreviewPlan = cjguiInternalBuildRendererStage717ReplayVisualPreviewPlan(actionStateRenderExecutor)
    let visualPreviewFacts = cjguiInternalBuildRendererStage717ReplayVisualPreviewFacts(
        actionStateRenderExecutor,
        visualPreviewPlan
    )
    return cjguiInternalBuildRendererStage717ReplayVisualPreviewReadiness(
        actionStateRenderExecutor,
        visualPreviewPlan,
        visualPreviewFacts
    )
}
