// 中文维护注释：本文件是 stage726 component visual state store action reducer preflight owner。
// Owner: 消费 stage725 input/action bridge，生成 owner-local mutation preflight / rollback plan。
// Truth: 只证明 action intent 可被 state store reducer 分类为 dry-run mutation 候选。
// Stop-line: 不 dispatch、不提交 state、不发布 visibility、不写 renderer_state/runtime_state。
// Same-shape Boundary Brake: 本 slice 用 shared reducer/preflight 压缩 per-demo mutation owner。
package cjgui

struct CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightPlan {
    let didConsumeStage725ComponentVisualStateStoreInputActionBridge: Bool
    let didConsumeVisualStateStoreActionIntents: Bool
    let didMaterializeSharedVisualStateStoreActionReducer: Bool
    let didMaterializeVisualStateStoreMutationPreflight: Bool
    let didMaterializeVisualStateStoreConflictClassifier: Bool
    let didMaterializeVisualStateStoreRollbackPlan: Bool
    let didMaterializeTodoVisualStateStoreMutationPreflight: Bool
    let didMaterializeSettingsVisualStateStoreMutationPreflight: Bool
    let didMaterializeAiGeneratedSettingsVisualStateStoreMutationPreflight: Bool
    let didMaterializeChatComposerVisualStateStoreMutationPreflight: Bool
    let didBindMutationPreflightToStage725InputActionBridge: Bool
    let didBindMutationPreflightToStage724VisualStateStoreManager: Bool
    let didKeepVisualStateStoreMutationOwnerLocal: Bool
    let didKeepVisualStateStoreMutationDryRunOnly: Bool
    let didPrepareStage727ComponentVisualStateStoreRenderResultHostSurface: Bool
    let didKeepHostMutationBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool

    init(
        didConsumeStage725ComponentVisualStateStoreInputActionBridge: Bool,
        didConsumeVisualStateStoreActionIntents: Bool,
        didMaterializeSharedVisualStateStoreActionReducer: Bool,
        didMaterializeVisualStateStoreMutationPreflight: Bool,
        didMaterializeVisualStateStoreConflictClassifier: Bool,
        didMaterializeVisualStateStoreRollbackPlan: Bool,
        didMaterializeTodoVisualStateStoreMutationPreflight: Bool,
        didMaterializeSettingsVisualStateStoreMutationPreflight: Bool,
        didMaterializeAiGeneratedSettingsVisualStateStoreMutationPreflight: Bool,
        didMaterializeChatComposerVisualStateStoreMutationPreflight: Bool,
        didBindMutationPreflightToStage725InputActionBridge: Bool,
        didBindMutationPreflightToStage724VisualStateStoreManager: Bool,
        didKeepVisualStateStoreMutationOwnerLocal: Bool,
        didKeepVisualStateStoreMutationDryRunOnly: Bool,
        didPrepareStage727ComponentVisualStateStoreRenderResultHostSurface: Bool,
        didKeepHostMutationBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool
    ) {
        this.didConsumeStage725ComponentVisualStateStoreInputActionBridge = didConsumeStage725ComponentVisualStateStoreInputActionBridge
        this.didConsumeVisualStateStoreActionIntents = didConsumeVisualStateStoreActionIntents
        this.didMaterializeSharedVisualStateStoreActionReducer = didMaterializeSharedVisualStateStoreActionReducer
        this.didMaterializeVisualStateStoreMutationPreflight = didMaterializeVisualStateStoreMutationPreflight
        this.didMaterializeVisualStateStoreConflictClassifier = didMaterializeVisualStateStoreConflictClassifier
        this.didMaterializeVisualStateStoreRollbackPlan = didMaterializeVisualStateStoreRollbackPlan
        this.didMaterializeTodoVisualStateStoreMutationPreflight = didMaterializeTodoVisualStateStoreMutationPreflight
        this.didMaterializeSettingsVisualStateStoreMutationPreflight = didMaterializeSettingsVisualStateStoreMutationPreflight
        this.didMaterializeAiGeneratedSettingsVisualStateStoreMutationPreflight = didMaterializeAiGeneratedSettingsVisualStateStoreMutationPreflight
        this.didMaterializeChatComposerVisualStateStoreMutationPreflight = didMaterializeChatComposerVisualStateStoreMutationPreflight
        this.didBindMutationPreflightToStage725InputActionBridge = didBindMutationPreflightToStage725InputActionBridge
        this.didBindMutationPreflightToStage724VisualStateStoreManager = didBindMutationPreflightToStage724VisualStateStoreManager
        this.didKeepVisualStateStoreMutationOwnerLocal = didKeepVisualStateStoreMutationOwnerLocal
        this.didKeepVisualStateStoreMutationDryRunOnly = didKeepVisualStateStoreMutationDryRunOnly
        this.didPrepareStage727ComponentVisualStateStoreRenderResultHostSurface = didPrepareStage727ComponentVisualStateStoreRenderResultHostSurface
        this.didKeepHostMutationBlocked = didKeepHostMutationBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
    }
}

struct CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightFacts {
    let actionReducerPreflightPlan: CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightPlan
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
        actionReducerPreflightPlan: CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightPlan,
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
        this.actionReducerPreflightPlan = actionReducerPreflightPlan
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

struct CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightReadiness {
    let inputActionBridge: CjguiInternalRendererStage725ComponentVisualStateStoreInputActionBridgeReadiness
    let actionReducerPreflightPlan: CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightPlan
    let actionReducerPreflightFacts: CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightFacts
    let didConfirmStage726ComponentVisualStateStoreActionReducerPreflightReady: Bool
    let didConfirmStage725ComponentVisualStateStoreInputActionBridgeConsumed: Bool
    let didConfirmStage724ComponentVisualStateStoreManagerConsumedTransitively: Bool
    let didConfirmVisualStateStoreActionIntentsConsumed: Bool
    let didConfirmSharedVisualStateStoreActionReducerMaterialized: Bool
    let didConfirmVisualStateStoreMutationPreflightMaterialized: Bool
    let didConfirmVisualStateStoreConflictClassifierMaterialized: Bool
    let didConfirmVisualStateStoreRollbackPlanMaterialized: Bool
    let didConfirmTodoVisualStateStoreMutationPreflightMaterialized: Bool
    let didConfirmSettingsVisualStateStoreMutationPreflightMaterialized: Bool
    let didConfirmAiGeneratedSettingsVisualStateStoreMutationPreflightMaterialized: Bool
    let didConfirmChatComposerVisualStateStoreMutationPreflightMaterialized: Bool
    let didConfirmMutationPreflightBoundToStage725InputActionBridge: Bool
    let didConfirmMutationPreflightBoundToStage724VisualStateStoreManager: Bool
    let didConfirmVisualStateStoreMutationOwnerLocal: Bool
    let didConfirmVisualStateStoreMutationDryRunOnly: Bool
    let didConfirmStage727ComponentVisualStateStoreRenderResultHostSurfacePrepared: Bool
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
        inputActionBridge: CjguiInternalRendererStage725ComponentVisualStateStoreInputActionBridgeReadiness,
        actionReducerPreflightPlan: CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightPlan,
        actionReducerPreflightFacts: CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightFacts,
        didConfirmStage726ComponentVisualStateStoreActionReducerPreflightReady: Bool,
        didConfirmStage725ComponentVisualStateStoreInputActionBridgeConsumed: Bool,
        didConfirmStage724ComponentVisualStateStoreManagerConsumedTransitively: Bool,
        didConfirmVisualStateStoreActionIntentsConsumed: Bool,
        didConfirmSharedVisualStateStoreActionReducerMaterialized: Bool,
        didConfirmVisualStateStoreMutationPreflightMaterialized: Bool,
        didConfirmVisualStateStoreConflictClassifierMaterialized: Bool,
        didConfirmVisualStateStoreRollbackPlanMaterialized: Bool,
        didConfirmTodoVisualStateStoreMutationPreflightMaterialized: Bool,
        didConfirmSettingsVisualStateStoreMutationPreflightMaterialized: Bool,
        didConfirmAiGeneratedSettingsVisualStateStoreMutationPreflightMaterialized: Bool,
        didConfirmChatComposerVisualStateStoreMutationPreflightMaterialized: Bool,
        didConfirmMutationPreflightBoundToStage725InputActionBridge: Bool,
        didConfirmMutationPreflightBoundToStage724VisualStateStoreManager: Bool,
        didConfirmVisualStateStoreMutationOwnerLocal: Bool,
        didConfirmVisualStateStoreMutationDryRunOnly: Bool,
        didConfirmStage727ComponentVisualStateStoreRenderResultHostSurfacePrepared: Bool,
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
        this.inputActionBridge = inputActionBridge
        this.actionReducerPreflightPlan = actionReducerPreflightPlan
        this.actionReducerPreflightFacts = actionReducerPreflightFacts
        this.didConfirmStage726ComponentVisualStateStoreActionReducerPreflightReady = didConfirmStage726ComponentVisualStateStoreActionReducerPreflightReady
        this.didConfirmStage725ComponentVisualStateStoreInputActionBridgeConsumed = didConfirmStage725ComponentVisualStateStoreInputActionBridgeConsumed
        this.didConfirmStage724ComponentVisualStateStoreManagerConsumedTransitively = didConfirmStage724ComponentVisualStateStoreManagerConsumedTransitively
        this.didConfirmVisualStateStoreActionIntentsConsumed = didConfirmVisualStateStoreActionIntentsConsumed
        this.didConfirmSharedVisualStateStoreActionReducerMaterialized = didConfirmSharedVisualStateStoreActionReducerMaterialized
        this.didConfirmVisualStateStoreMutationPreflightMaterialized = didConfirmVisualStateStoreMutationPreflightMaterialized
        this.didConfirmVisualStateStoreConflictClassifierMaterialized = didConfirmVisualStateStoreConflictClassifierMaterialized
        this.didConfirmVisualStateStoreRollbackPlanMaterialized = didConfirmVisualStateStoreRollbackPlanMaterialized
        this.didConfirmTodoVisualStateStoreMutationPreflightMaterialized = didConfirmTodoVisualStateStoreMutationPreflightMaterialized
        this.didConfirmSettingsVisualStateStoreMutationPreflightMaterialized = didConfirmSettingsVisualStateStoreMutationPreflightMaterialized
        this.didConfirmAiGeneratedSettingsVisualStateStoreMutationPreflightMaterialized = didConfirmAiGeneratedSettingsVisualStateStoreMutationPreflightMaterialized
        this.didConfirmChatComposerVisualStateStoreMutationPreflightMaterialized = didConfirmChatComposerVisualStateStoreMutationPreflightMaterialized
        this.didConfirmMutationPreflightBoundToStage725InputActionBridge = didConfirmMutationPreflightBoundToStage725InputActionBridge
        this.didConfirmMutationPreflightBoundToStage724VisualStateStoreManager = didConfirmMutationPreflightBoundToStage724VisualStateStoreManager
        this.didConfirmVisualStateStoreMutationOwnerLocal = didConfirmVisualStateStoreMutationOwnerLocal
        this.didConfirmVisualStateStoreMutationDryRunOnly = didConfirmVisualStateStoreMutationDryRunOnly
        this.didConfirmStage727ComponentVisualStateStoreRenderResultHostSurfacePrepared = didConfirmStage727ComponentVisualStateStoreRenderResultHostSurfacePrepared
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

func cjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightMaterialized(): Bool {
    return true
}

func cjguiInternalBuildRendererStage726ComponentVisualStateStoreActionReducerPreflightPlan(
    inputActionBridge: CjguiInternalRendererStage725ComponentVisualStateStoreInputActionBridgeReadiness): CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightPlan {
    let stage725Ready = inputActionBridge.didConfirmStage725ComponentVisualStateStoreInputActionBridgeReady && inputActionBridge
        .didConfirmStage726ComponentVisualStateStoreActionReducerPreflightPrepared
    let actionIntentsReady = inputActionBridge.didConfirmSharedVisualStateStoreInputActionBridgeMaterialized && inputActionBridge
        .didConfirmVisualStateStoreTextEditActionIntentMaterialized && inputActionBridge
        .didConfirmVisualStateStoreSubmitActionIntentMaterialized && inputActionBridge
        .didConfirmVisualStateStoreValidationDismissActionIntentMaterialized && inputActionBridge
        .didConfirmVisualStateStoreFocusMoveActionIntentMaterialized && inputActionBridge
        .didConfirmChatComposerVisualStateStoreInputActionSurfaceMaterialized
    let reducerReady = stage725Ready && actionIntentsReady &&
        cjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightMaterialized()
    return CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightPlan(
        stage725Ready,
        actionIntentsReady,
        reducerReady,
        reducerReady,
        reducerReady,
        reducerReady,
        reducerReady,
        reducerReady,
        reducerReady,
        reducerReady,
        inputActionBridge.didConfirmSharedVisualStateStoreInputActionBridgeMaterialized,
        inputActionBridge.didConfirmStage724ComponentVisualStateStoreManagerConsumed,
        true,
        true,
        reducerReady,
        inputActionBridge.didConfirmHostMutation == false,
        inputActionBridge.didConfirmRendererSubmissionBlocked,
        inputActionBridge.didConfirmRendererStateWriteBlocked,
        inputActionBridge.didConfirmRuntimeStateWriteBlocked
    )
}

func cjguiInternalBuildRendererStage726ComponentVisualStateStoreActionReducerPreflightFacts(
    inputActionBridge: CjguiInternalRendererStage725ComponentVisualStateStoreInputActionBridgeReadiness,
    actionReducerPreflightPlan: CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightPlan
): CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightFacts {
    return CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightFacts(
        actionReducerPreflightPlan,
        inputActionBridge.didConfirmOwnerAcceptanceRequired,
        inputActionBridge.didConfirmOwnerAcceptanceGranted == false,
        inputActionBridge.didConfirmProductionRenderTruth == false,
        inputActionBridge.didConfirmBackendReadyTruth == false,
        inputActionBridge.didConfirmPublicComponentApiAdded == false,
        inputActionBridge.didConfirmInputEventPipelineExecution == false,
        inputActionBridge.didConfirmActionDispatch == false,
        inputActionBridge.didConfirmStateUpdateCommitted == false,
        inputActionBridge.didConfirmVisibilityPublicationAdmitted == false,
        inputActionBridge.didConfirmVisibilityPublished == false,
        inputActionBridge.didConfirmNativeBridgeExpansionBlocked
    )
}

func cjguiInternalBuildRendererStage726ComponentVisualStateStoreActionReducerPreflightReadiness(
    inputActionBridge: CjguiInternalRendererStage725ComponentVisualStateStoreInputActionBridgeReadiness,
    actionReducerPreflightPlan: CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightPlan,
    actionReducerPreflightFacts: CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightFacts
): CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightReadiness {
    let reducerReady = actionReducerPreflightPlan.didConsumeStage725ComponentVisualStateStoreInputActionBridge && actionReducerPreflightPlan
        .didConsumeVisualStateStoreActionIntents && actionReducerPreflightPlan
        .didMaterializeSharedVisualStateStoreActionReducer && actionReducerPreflightPlan
        .didMaterializeVisualStateStoreMutationPreflight && actionReducerPreflightPlan
        .didMaterializeVisualStateStoreConflictClassifier && actionReducerPreflightPlan
        .didMaterializeVisualStateStoreRollbackPlan && actionReducerPreflightPlan
        .didMaterializeChatComposerVisualStateStoreMutationPreflight && actionReducerPreflightPlan
        .didBindMutationPreflightToStage725InputActionBridge && actionReducerPreflightPlan
        .didBindMutationPreflightToStage724VisualStateStoreManager && actionReducerPreflightPlan
        .didKeepVisualStateStoreMutationOwnerLocal && actionReducerPreflightPlan
        .didKeepVisualStateStoreMutationDryRunOnly && actionReducerPreflightPlan
        .didPrepareStage727ComponentVisualStateStoreRenderResultHostSurface
    let stopLineReady = actionReducerPreflightPlan.didKeepHostMutationBlocked && actionReducerPreflightFacts
        .didKeepOwnerAcceptanceRequired && actionReducerPreflightFacts.didKeepOwnerAcceptanceNotGranted && actionReducerPreflightFacts
        .didKeepProductionRenderTruthBlocked && actionReducerPreflightFacts.didKeepBackendReadyTruthBlocked && actionReducerPreflightFacts
        .didKeepPublicComponentApiBlocked && actionReducerPreflightFacts.didKeepInputEventPipelineExecutionBlocked && actionReducerPreflightFacts
        .didKeepActionDispatchBlocked && actionReducerPreflightFacts.didKeepStateUpdateCommittedBlocked && actionReducerPreflightFacts
        .didKeepVisibilityPublicationAdmittedBlocked && actionReducerPreflightFacts.didKeepVisibilityPublishedBlocked && actionReducerPreflightPlan
        .didKeepRendererSubmissionBlocked && actionReducerPreflightPlan.didKeepRendererStateWriteBlocked && actionReducerPreflightPlan
        .didKeepRuntimeStateWriteBlocked && actionReducerPreflightFacts.didKeepNativeBridgeExpansionBlocked
    return CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightReadiness(
        inputActionBridge,
        actionReducerPreflightPlan,
        actionReducerPreflightFacts,
        reducerReady && stopLineReady,
        actionReducerPreflightPlan.didConsumeStage725ComponentVisualStateStoreInputActionBridge,
        inputActionBridge.didConfirmStage724ComponentVisualStateStoreManagerConsumed,
        actionReducerPreflightPlan.didConsumeVisualStateStoreActionIntents,
        actionReducerPreflightPlan.didMaterializeSharedVisualStateStoreActionReducer,
        actionReducerPreflightPlan.didMaterializeVisualStateStoreMutationPreflight,
        actionReducerPreflightPlan.didMaterializeVisualStateStoreConflictClassifier,
        actionReducerPreflightPlan.didMaterializeVisualStateStoreRollbackPlan,
        actionReducerPreflightPlan.didMaterializeTodoVisualStateStoreMutationPreflight,
        actionReducerPreflightPlan.didMaterializeSettingsVisualStateStoreMutationPreflight,
        actionReducerPreflightPlan.didMaterializeAiGeneratedSettingsVisualStateStoreMutationPreflight,
        actionReducerPreflightPlan.didMaterializeChatComposerVisualStateStoreMutationPreflight,
        actionReducerPreflightPlan.didBindMutationPreflightToStage725InputActionBridge,
        actionReducerPreflightPlan.didBindMutationPreflightToStage724VisualStateStoreManager,
        actionReducerPreflightPlan.didKeepVisualStateStoreMutationOwnerLocal,
        actionReducerPreflightPlan.didKeepVisualStateStoreMutationDryRunOnly,
        actionReducerPreflightPlan.didPrepareStage727ComponentVisualStateStoreRenderResultHostSurface,
        false,
        actionReducerPreflightFacts.didKeepOwnerAcceptanceRequired,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        actionReducerPreflightPlan.didKeepRendererSubmissionBlocked,
        actionReducerPreflightPlan.didKeepRendererStateWriteBlocked,
        actionReducerPreflightPlan.didKeepRuntimeStateWriteBlocked,
        actionReducerPreflightFacts.didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage726ComponentVisualStateStoreActionReducerPreflightDraft(): CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightReadiness {
    let inputActionBridge = cjguiInternalExecuteDefaultRendererStage725ComponentVisualStateStoreInputActionBridgeDraft()
    let actionReducerPreflightPlan = cjguiInternalBuildRendererStage726ComponentVisualStateStoreActionReducerPreflightPlan(
        inputActionBridge)
    let actionReducerPreflightFacts = cjguiInternalBuildRendererStage726ComponentVisualStateStoreActionReducerPreflightFacts(
        inputActionBridge,
        actionReducerPreflightPlan
    )
    return cjguiInternalBuildRendererStage726ComponentVisualStateStoreActionReducerPreflightReadiness(
        inputActionBridge,
        actionReducerPreflightPlan,
        actionReducerPreflightFacts
    )
}
