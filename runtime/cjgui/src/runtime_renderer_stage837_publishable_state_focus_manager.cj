// 中文维护注释：本文件是 stage837 publishable state focus manager owner。
// Owner: 消费 stage836 layout/style runtime manager，建立 owner-local focus traversal manager 输入。
// Truth: 只证明 publishable state slot 可形成焦点候选、顺序与 caret anchor ledger。
// Stop-line: 不移动真实焦点、不执行 input pipeline、不提交状态、不写 renderer_state/runtime_state。
// Same-shape Boundary Brake: 本 slice 用共享 focus manager input 替代后续 per-demo focus 模板。
package cjgui

struct CjguiInternalRendererStage837PublishableStateFocusManagerPlan {
    let didConsumeStage836PublishableStateLayoutStyleRuntimeManager: Bool
    let didConsumeLayoutStyleRuntimeManager: Bool
    let didMaterializeOwnerLocalFocusTraversalManagerInput: Bool
    let didMaterializeFocusScopeCandidateLedger: Bool
    let didMaterializeFocusableSlotOrderLedger: Bool
    let didMaterializeCaretAnchorCandidateLedger: Bool
    let didBindFocusManagerToStage834MeasurementPlan: Bool
    let didBindFocusManagerToStage836RuntimeManager: Bool
    let didPrepareStage838PublishableStateFocusMovementPreview: Bool
    let didKeepFocusManagerProductionDisabled: Bool
    let didKeepFocusMutationBlocked: Bool
    let didKeepInputPipelineExecutionBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool

    init(
        didConsumeStage836PublishableStateLayoutStyleRuntimeManager: Bool,
        didConsumeLayoutStyleRuntimeManager: Bool,
        didMaterializeOwnerLocalFocusTraversalManagerInput: Bool,
        didMaterializeFocusScopeCandidateLedger: Bool,
        didMaterializeFocusableSlotOrderLedger: Bool,
        didMaterializeCaretAnchorCandidateLedger: Bool,
        didBindFocusManagerToStage834MeasurementPlan: Bool,
        didBindFocusManagerToStage836RuntimeManager: Bool,
        didPrepareStage838PublishableStateFocusMovementPreview: Bool,
        didKeepFocusManagerProductionDisabled: Bool,
        didKeepFocusMutationBlocked: Bool,
        didKeepInputPipelineExecutionBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool
    ) {
        this.didConsumeStage836PublishableStateLayoutStyleRuntimeManager = didConsumeStage836PublishableStateLayoutStyleRuntimeManager
        this.didConsumeLayoutStyleRuntimeManager = didConsumeLayoutStyleRuntimeManager
        this.didMaterializeOwnerLocalFocusTraversalManagerInput = didMaterializeOwnerLocalFocusTraversalManagerInput
        this.didMaterializeFocusScopeCandidateLedger = didMaterializeFocusScopeCandidateLedger
        this.didMaterializeFocusableSlotOrderLedger = didMaterializeFocusableSlotOrderLedger
        this.didMaterializeCaretAnchorCandidateLedger = didMaterializeCaretAnchorCandidateLedger
        this.didBindFocusManagerToStage834MeasurementPlan = didBindFocusManagerToStage834MeasurementPlan
        this.didBindFocusManagerToStage836RuntimeManager = didBindFocusManagerToStage836RuntimeManager
        this.didPrepareStage838PublishableStateFocusMovementPreview = didPrepareStage838PublishableStateFocusMovementPreview
        this.didKeepFocusManagerProductionDisabled = didKeepFocusManagerProductionDisabled
        this.didKeepFocusMutationBlocked = didKeepFocusMutationBlocked
        this.didKeepInputPipelineExecutionBlocked = didKeepInputPipelineExecutionBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
    }
}

struct CjguiInternalRendererStage837PublishableStateFocusManagerFacts {
    let focusManagerPlan: CjguiInternalRendererStage837PublishableStateFocusManagerPlan
    let didKeepPublicComponentApiAdded: Bool
    let didKeepNoNewPublicSurfaceAdded: Bool
    let didKeepStablePublicApiNotAdded: Bool
    let didKeepPublicCAbiNotAdded: Bool
    let didKeepStateStoreCommitNotPublished: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepVisibilityPublicationAdmittedBlocked: Bool
    let didKeepVisibilityPublishedBlocked: Bool
    let didKeepNativeBridgeExpansionBlocked: Bool

    init(
        focusManagerPlan: CjguiInternalRendererStage837PublishableStateFocusManagerPlan,
        didKeepPublicComponentApiAdded: Bool,
        didKeepNoNewPublicSurfaceAdded: Bool,
        didKeepStablePublicApiNotAdded: Bool,
        didKeepPublicCAbiNotAdded: Bool,
        didKeepStateStoreCommitNotPublished: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepVisibilityPublicationAdmittedBlocked: Bool,
        didKeepVisibilityPublishedBlocked: Bool,
        didKeepNativeBridgeExpansionBlocked: Bool
    ) {
        this.focusManagerPlan = focusManagerPlan
        this.didKeepPublicComponentApiAdded = didKeepPublicComponentApiAdded
        this.didKeepNoNewPublicSurfaceAdded = didKeepNoNewPublicSurfaceAdded
        this.didKeepStablePublicApiNotAdded = didKeepStablePublicApiNotAdded
        this.didKeepPublicCAbiNotAdded = didKeepPublicCAbiNotAdded
        this.didKeepStateStoreCommitNotPublished = didKeepStateStoreCommitNotPublished
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepStateUpdateCommittedBlocked = didKeepStateUpdateCommittedBlocked
        this.didKeepVisibilityPublicationAdmittedBlocked = didKeepVisibilityPublicationAdmittedBlocked
        this.didKeepVisibilityPublishedBlocked = didKeepVisibilityPublishedBlocked
        this.didKeepNativeBridgeExpansionBlocked = didKeepNativeBridgeExpansionBlocked
    }
}

struct CjguiInternalRendererStage837PublishableStateFocusManagerReadiness {
    let layoutStyleRuntimeManager: CjguiInternalRendererStage836PublishableStateLayoutStyleRuntimeManagerReadiness
    let focusManagerPlan: CjguiInternalRendererStage837PublishableStateFocusManagerPlan
    let focusManagerFacts: CjguiInternalRendererStage837PublishableStateFocusManagerFacts
    let didConfirmStage837PublishableStateFocusManagerReady: Bool
    let didConfirmStage836PublishableStateLayoutStyleRuntimeManagerConsumed: Bool
    let didConfirmStage835PublishableStateLayoutStyleDemoSurfaceConsumedTransitively: Bool
    let didConfirmStage834PublishableStateTextFocusMeasurementPlanConsumedTransitively: Bool
    let didConfirmLayoutStyleRuntimeManagerConsumed: Bool
    let didConfirmOwnerLocalFocusTraversalManagerInputMaterialized: Bool
    let didConfirmFocusScopeCandidateLedgerMaterialized: Bool
    let didConfirmFocusableSlotOrderLedgerMaterialized: Bool
    let didConfirmCaretAnchorCandidateLedgerMaterialized: Bool
    let didConfirmFocusManagerBoundToStage834MeasurementPlan: Bool
    let didConfirmFocusManagerBoundToStage836RuntimeManager: Bool
    let didConfirmStage838PublishableStateFocusMovementPreviewPrepared: Bool
    let didConfirmFocusManagerEnabled: Bool
    let didConfirmFocusMutation: Bool
    let didConfirmInputPipelineExecution: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmNewPublicSurfaceAdded: Bool
    let didConfirmStablePublicApiAdded: Bool
    let didConfirmPublicCAbiAdded: Bool
    let didConfirmStateStoreCommitPublished: Bool
    let didConfirmActionDispatch: Bool
    let didConfirmStateUpdateCommitted: Bool
    let didConfirmVisibilityPublicationAdmitted: Bool
    let didConfirmVisibilityPublished: Bool
    let didConfirmRendererSubmission: Bool
    let didConfirmRendererStateWrite: Bool
    let didConfirmRuntimeStateWrite: Bool
    let didConfirmNativeBridgeExpansionBlocked: Bool

    init(
        layoutStyleRuntimeManager: CjguiInternalRendererStage836PublishableStateLayoutStyleRuntimeManagerReadiness,
        focusManagerPlan: CjguiInternalRendererStage837PublishableStateFocusManagerPlan,
        focusManagerFacts: CjguiInternalRendererStage837PublishableStateFocusManagerFacts,
        didConfirmStage837PublishableStateFocusManagerReady: Bool,
        didConfirmStage836PublishableStateLayoutStyleRuntimeManagerConsumed: Bool,
        didConfirmStage835PublishableStateLayoutStyleDemoSurfaceConsumedTransitively: Bool,
        didConfirmStage834PublishableStateTextFocusMeasurementPlanConsumedTransitively: Bool,
        didConfirmLayoutStyleRuntimeManagerConsumed: Bool,
        didConfirmOwnerLocalFocusTraversalManagerInputMaterialized: Bool,
        didConfirmFocusScopeCandidateLedgerMaterialized: Bool,
        didConfirmFocusableSlotOrderLedgerMaterialized: Bool,
        didConfirmCaretAnchorCandidateLedgerMaterialized: Bool,
        didConfirmFocusManagerBoundToStage834MeasurementPlan: Bool,
        didConfirmFocusManagerBoundToStage836RuntimeManager: Bool,
        didConfirmStage838PublishableStateFocusMovementPreviewPrepared: Bool,
        didConfirmFocusManagerEnabled: Bool,
        didConfirmFocusMutation: Bool,
        didConfirmInputPipelineExecution: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmNewPublicSurfaceAdded: Bool,
        didConfirmStablePublicApiAdded: Bool,
        didConfirmPublicCAbiAdded: Bool,
        didConfirmStateStoreCommitPublished: Bool,
        didConfirmActionDispatch: Bool,
        didConfirmStateUpdateCommitted: Bool,
        didConfirmVisibilityPublicationAdmitted: Bool,
        didConfirmVisibilityPublished: Bool,
        didConfirmRendererSubmission: Bool,
        didConfirmRendererStateWrite: Bool,
        didConfirmRuntimeStateWrite: Bool,
        didConfirmNativeBridgeExpansionBlocked: Bool
    ) {
        this.layoutStyleRuntimeManager = layoutStyleRuntimeManager
        this.focusManagerPlan = focusManagerPlan
        this.focusManagerFacts = focusManagerFacts
        this.didConfirmStage837PublishableStateFocusManagerReady = didConfirmStage837PublishableStateFocusManagerReady
        this.didConfirmStage836PublishableStateLayoutStyleRuntimeManagerConsumed = didConfirmStage836PublishableStateLayoutStyleRuntimeManagerConsumed
        this.didConfirmStage835PublishableStateLayoutStyleDemoSurfaceConsumedTransitively = didConfirmStage835PublishableStateLayoutStyleDemoSurfaceConsumedTransitively
        this.didConfirmStage834PublishableStateTextFocusMeasurementPlanConsumedTransitively = didConfirmStage834PublishableStateTextFocusMeasurementPlanConsumedTransitively
        this.didConfirmLayoutStyleRuntimeManagerConsumed = didConfirmLayoutStyleRuntimeManagerConsumed
        this.didConfirmOwnerLocalFocusTraversalManagerInputMaterialized = didConfirmOwnerLocalFocusTraversalManagerInputMaterialized
        this.didConfirmFocusScopeCandidateLedgerMaterialized = didConfirmFocusScopeCandidateLedgerMaterialized
        this.didConfirmFocusableSlotOrderLedgerMaterialized = didConfirmFocusableSlotOrderLedgerMaterialized
        this.didConfirmCaretAnchorCandidateLedgerMaterialized = didConfirmCaretAnchorCandidateLedgerMaterialized
        this.didConfirmFocusManagerBoundToStage834MeasurementPlan = didConfirmFocusManagerBoundToStage834MeasurementPlan
        this.didConfirmFocusManagerBoundToStage836RuntimeManager = didConfirmFocusManagerBoundToStage836RuntimeManager
        this.didConfirmStage838PublishableStateFocusMovementPreviewPrepared = didConfirmStage838PublishableStateFocusMovementPreviewPrepared
        this.didConfirmFocusManagerEnabled = didConfirmFocusManagerEnabled
        this.didConfirmFocusMutation = didConfirmFocusMutation
        this.didConfirmInputPipelineExecution = didConfirmInputPipelineExecution
        this.didConfirmPublicComponentApiAdded = didConfirmPublicComponentApiAdded
        this.didConfirmNewPublicSurfaceAdded = didConfirmNewPublicSurfaceAdded
        this.didConfirmStablePublicApiAdded = didConfirmStablePublicApiAdded
        this.didConfirmPublicCAbiAdded = didConfirmPublicCAbiAdded
        this.didConfirmStateStoreCommitPublished = didConfirmStateStoreCommitPublished
        this.didConfirmActionDispatch = didConfirmActionDispatch
        this.didConfirmStateUpdateCommitted = didConfirmStateUpdateCommitted
        this.didConfirmVisibilityPublicationAdmitted = didConfirmVisibilityPublicationAdmitted
        this.didConfirmVisibilityPublished = didConfirmVisibilityPublished
        this.didConfirmRendererSubmission = didConfirmRendererSubmission
        this.didConfirmRendererStateWrite = didConfirmRendererStateWrite
        this.didConfirmRuntimeStateWrite = didConfirmRuntimeStateWrite
        this.didConfirmNativeBridgeExpansionBlocked = didConfirmNativeBridgeExpansionBlocked
    }
}

func cjguiInternalRendererStage837PublishableStateFocusManagerMaterialized(): Bool {
    return true
}

func cjguiInternalBuildRendererStage837PublishableStateFocusManagerPlan(
    layoutStyleRuntimeManager: CjguiInternalRendererStage836PublishableStateLayoutStyleRuntimeManagerReadiness): CjguiInternalRendererStage837PublishableStateFocusManagerPlan {
    let stage836Ready = layoutStyleRuntimeManager.didConfirmStage836PublishableStateLayoutStyleRuntimeManagerReady && layoutStyleRuntimeManager
        .didConfirmStage837PublishableStateFocusManagerAfterStage836Prepared
    let runtimeReady = layoutStyleRuntimeManager.didConfirmSharedPublishableLayoutStyleRuntimeManagerMaterialized && layoutStyleRuntimeManager
        .didConfirmFileBrowserLayoutStyleRuntimeSurfaceMaterialized && layoutStyleRuntimeManager
        .didConfirmFuturePerDemoLayoutStyleTemplateNeedReduced
    let measurementReady = layoutStyleRuntimeManager.didConfirmRuntimeManagerBoundToStage834MeasurementPlan && layoutStyleRuntimeManager
        .layoutStyleDemoSurface
        .textFocusMeasurement
        .didConfirmFocusTraversalMeasurementLedgerMaterialized && layoutStyleRuntimeManager
        .layoutStyleDemoSurface
        .textFocusMeasurement
        .didConfirmCaretGeometryPlaceholderMaterialized
    let focusReady = stage836Ready && runtimeReady && measurementReady &&
        cjguiInternalRendererStage837PublishableStateFocusManagerMaterialized()
    return CjguiInternalRendererStage837PublishableStateFocusManagerPlan(
        stage836Ready,
        runtimeReady,
        focusReady,
        focusReady,
        focusReady,
        focusReady,
        measurementReady,
        layoutStyleRuntimeManager.didConfirmSharedPublishableLayoutStyleRuntimeManagerMaterialized,
        focusReady,
        true,
        true,
        true,
        layoutStyleRuntimeManager.didConfirmRendererSubmission == false,
        layoutStyleRuntimeManager.didConfirmRendererStateWrite == false,
        layoutStyleRuntimeManager.didConfirmRuntimeStateWrite == false
    )
}

func cjguiInternalBuildRendererStage837PublishableStateFocusManagerFacts(
    layoutStyleRuntimeManager: CjguiInternalRendererStage836PublishableStateLayoutStyleRuntimeManagerReadiness,
    focusManagerPlan: CjguiInternalRendererStage837PublishableStateFocusManagerPlan
): CjguiInternalRendererStage837PublishableStateFocusManagerFacts {
    return CjguiInternalRendererStage837PublishableStateFocusManagerFacts(
        focusManagerPlan,
        layoutStyleRuntimeManager.didConfirmPublicComponentApiAdded,
        layoutStyleRuntimeManager.didConfirmNewPublicSurfaceAdded == false,
        layoutStyleRuntimeManager.didConfirmStablePublicApiAdded == false,
        layoutStyleRuntimeManager.didConfirmPublicCAbiAdded == false,
        layoutStyleRuntimeManager.didConfirmStateStoreCommitPublished == false,
        layoutStyleRuntimeManager.didConfirmActionDispatch == false,
        layoutStyleRuntimeManager.didConfirmStateUpdateCommitted == false,
        layoutStyleRuntimeManager.didConfirmVisibilityPublicationAdmitted == false,
        layoutStyleRuntimeManager.didConfirmVisibilityPublished == false,
        layoutStyleRuntimeManager.didConfirmNativeBridgeExpansionBlocked
    )
}

func cjguiInternalBuildRendererStage837PublishableStateFocusManagerReadiness(
    layoutStyleRuntimeManager: CjguiInternalRendererStage836PublishableStateLayoutStyleRuntimeManagerReadiness,
    focusManagerPlan: CjguiInternalRendererStage837PublishableStateFocusManagerPlan,
    focusManagerFacts: CjguiInternalRendererStage837PublishableStateFocusManagerFacts
): CjguiInternalRendererStage837PublishableStateFocusManagerReadiness {
    let focusReady = focusManagerPlan.didConsumeStage836PublishableStateLayoutStyleRuntimeManager && focusManagerPlan
        .didConsumeLayoutStyleRuntimeManager && focusManagerPlan.didMaterializeOwnerLocalFocusTraversalManagerInput && focusManagerPlan
        .didMaterializeFocusScopeCandidateLedger && focusManagerPlan.didMaterializeFocusableSlotOrderLedger && focusManagerPlan
        .didMaterializeCaretAnchorCandidateLedger && focusManagerPlan.didBindFocusManagerToStage834MeasurementPlan && focusManagerPlan
        .didBindFocusManagerToStage836RuntimeManager && focusManagerPlan
        .didPrepareStage838PublishableStateFocusMovementPreview
    let stopLineReady = focusManagerPlan.didKeepFocusManagerProductionDisabled && focusManagerPlan
        .didKeepFocusMutationBlocked && focusManagerPlan.didKeepInputPipelineExecutionBlocked && focusManagerFacts
        .didKeepPublicComponentApiAdded && focusManagerFacts.didKeepNoNewPublicSurfaceAdded && focusManagerFacts
        .didKeepStablePublicApiNotAdded && focusManagerFacts.didKeepPublicCAbiNotAdded && focusManagerFacts
        .didKeepStateStoreCommitNotPublished && focusManagerFacts.didKeepActionDispatchBlocked && focusManagerFacts
        .didKeepStateUpdateCommittedBlocked && focusManagerFacts.didKeepVisibilityPublicationAdmittedBlocked && focusManagerFacts
        .didKeepVisibilityPublishedBlocked && focusManagerPlan.didKeepRendererSubmissionBlocked && focusManagerPlan
        .didKeepRendererStateWriteBlocked && focusManagerPlan.didKeepRuntimeStateWriteBlocked && focusManagerFacts
        .didKeepNativeBridgeExpansionBlocked
    return CjguiInternalRendererStage837PublishableStateFocusManagerReadiness(
        layoutStyleRuntimeManager,
        focusManagerPlan,
        focusManagerFacts,
        focusReady && stopLineReady,
        focusManagerPlan.didConsumeStage836PublishableStateLayoutStyleRuntimeManager,
        layoutStyleRuntimeManager.didConfirmStage835PublishableStateLayoutStyleDemoSurfaceConsumed,
        layoutStyleRuntimeManager.didConfirmStage834PublishableStateTextFocusMeasurementPlanConsumedTransitively,
        focusManagerPlan.didConsumeLayoutStyleRuntimeManager,
        focusManagerPlan.didMaterializeOwnerLocalFocusTraversalManagerInput,
        focusManagerPlan.didMaterializeFocusScopeCandidateLedger,
        focusManagerPlan.didMaterializeFocusableSlotOrderLedger,
        focusManagerPlan.didMaterializeCaretAnchorCandidateLedger,
        focusManagerPlan.didBindFocusManagerToStage834MeasurementPlan,
        focusManagerPlan.didBindFocusManagerToStage836RuntimeManager,
        focusManagerPlan.didPrepareStage838PublishableStateFocusMovementPreview,
        false,
        false,
        false,
        focusManagerFacts.didKeepPublicComponentApiAdded,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        focusManagerFacts.didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage837PublishableStateFocusManagerDraft(): CjguiInternalRendererStage837PublishableStateFocusManagerReadiness {
    let layoutStyleRuntimeManager = cjguiInternalExecuteDefaultRendererStage836PublishableStateLayoutStyleRuntimeManagerDraft()
    let focusManagerPlan = cjguiInternalBuildRendererStage837PublishableStateFocusManagerPlan(layoutStyleRuntimeManager)
    let focusManagerFacts = cjguiInternalBuildRendererStage837PublishableStateFocusManagerFacts(
        layoutStyleRuntimeManager,
        focusManagerPlan
    )
    return cjguiInternalBuildRendererStage837PublishableStateFocusManagerReadiness(
        layoutStyleRuntimeManager,
        focusManagerPlan,
        focusManagerFacts
    )
}
