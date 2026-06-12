// 中文维护注释：本文件是 stage838 publishable state focus movement preview owner。
// Owner: 消费 stage837 focus manager input，生成非派发的焦点移动、selection/caret 与回滚预览。
// Truth: 只证明 owner-local focus movement 可解释、可回滚、可投影到 demo surface。
// Stop-line: 不派发 input、不移动真实焦点、不提交状态、不写 renderer_state/runtime_state。
// Same-shape Boundary Brake: 本 slice 将焦点移动预览统一为共享 decision shape。
package cjgui

struct CjguiInternalRendererStage838PublishableStateFocusMovementPreviewPlan {
    let didConsumeStage837PublishableStateFocusManager: Bool
    let didConsumeOwnerLocalFocusTraversalManagerInput: Bool
    let didMaterializeOwnerLocalFocusMovementPreview: Bool
    let didMaterializeSelectionCaretTransitionPreview: Bool
    let didMaterializeFocusRollbackSnapshot: Bool
    let didMaterializeFocusChangeExplainReceipt: Bool
    let didBindFocusMovementToStage837FocusManagerInput: Bool
    let didPrepareStage839PublishableStateFocusDemoSurface: Bool
    let didKeepFocusDispatchBlocked: Bool
    let didKeepFocusMutationBlocked: Bool
    let didKeepInputPipelineExecutionBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool

    init(
        didConsumeStage837PublishableStateFocusManager: Bool,
        didConsumeOwnerLocalFocusTraversalManagerInput: Bool,
        didMaterializeOwnerLocalFocusMovementPreview: Bool,
        didMaterializeSelectionCaretTransitionPreview: Bool,
        didMaterializeFocusRollbackSnapshot: Bool,
        didMaterializeFocusChangeExplainReceipt: Bool,
        didBindFocusMovementToStage837FocusManagerInput: Bool,
        didPrepareStage839PublishableStateFocusDemoSurface: Bool,
        didKeepFocusDispatchBlocked: Bool,
        didKeepFocusMutationBlocked: Bool,
        didKeepInputPipelineExecutionBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool
    ) {
        this.didConsumeStage837PublishableStateFocusManager = didConsumeStage837PublishableStateFocusManager
        this.didConsumeOwnerLocalFocusTraversalManagerInput = didConsumeOwnerLocalFocusTraversalManagerInput
        this.didMaterializeOwnerLocalFocusMovementPreview = didMaterializeOwnerLocalFocusMovementPreview
        this.didMaterializeSelectionCaretTransitionPreview = didMaterializeSelectionCaretTransitionPreview
        this.didMaterializeFocusRollbackSnapshot = didMaterializeFocusRollbackSnapshot
        this.didMaterializeFocusChangeExplainReceipt = didMaterializeFocusChangeExplainReceipt
        this.didBindFocusMovementToStage837FocusManagerInput = didBindFocusMovementToStage837FocusManagerInput
        this.didPrepareStage839PublishableStateFocusDemoSurface = didPrepareStage839PublishableStateFocusDemoSurface
        this.didKeepFocusDispatchBlocked = didKeepFocusDispatchBlocked
        this.didKeepFocusMutationBlocked = didKeepFocusMutationBlocked
        this.didKeepInputPipelineExecutionBlocked = didKeepInputPipelineExecutionBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
    }
}

struct CjguiInternalRendererStage838PublishableStateFocusMovementPreviewFacts {
    let movementPreviewPlan: CjguiInternalRendererStage838PublishableStateFocusMovementPreviewPlan
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
        movementPreviewPlan: CjguiInternalRendererStage838PublishableStateFocusMovementPreviewPlan,
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
        this.movementPreviewPlan = movementPreviewPlan
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

struct CjguiInternalRendererStage838PublishableStateFocusMovementPreviewReadiness {
    let focusManager: CjguiInternalRendererStage837PublishableStateFocusManagerReadiness
    let movementPreviewPlan: CjguiInternalRendererStage838PublishableStateFocusMovementPreviewPlan
    let movementPreviewFacts: CjguiInternalRendererStage838PublishableStateFocusMovementPreviewFacts
    let didConfirmStage838PublishableStateFocusMovementPreviewReady: Bool
    let didConfirmStage837PublishableStateFocusManagerConsumed: Bool
    let didConfirmStage836PublishableStateLayoutStyleRuntimeManagerConsumedTransitively: Bool
    let didConfirmOwnerLocalFocusTraversalManagerInputConsumed: Bool
    let didConfirmOwnerLocalFocusMovementPreviewMaterialized: Bool
    let didConfirmSelectionCaretTransitionPreviewMaterialized: Bool
    let didConfirmFocusRollbackSnapshotMaterialized: Bool
    let didConfirmFocusChangeExplainReceiptMaterialized: Bool
    let didConfirmFocusMovementBoundToStage837FocusManagerInput: Bool
    let didConfirmStage839PublishableStateFocusDemoSurfacePrepared: Bool
    let didConfirmFocusDispatch: Bool
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
        focusManager: CjguiInternalRendererStage837PublishableStateFocusManagerReadiness,
        movementPreviewPlan: CjguiInternalRendererStage838PublishableStateFocusMovementPreviewPlan,
        movementPreviewFacts: CjguiInternalRendererStage838PublishableStateFocusMovementPreviewFacts,
        didConfirmStage838PublishableStateFocusMovementPreviewReady: Bool,
        didConfirmStage837PublishableStateFocusManagerConsumed: Bool,
        didConfirmStage836PublishableStateLayoutStyleRuntimeManagerConsumedTransitively: Bool,
        didConfirmOwnerLocalFocusTraversalManagerInputConsumed: Bool,
        didConfirmOwnerLocalFocusMovementPreviewMaterialized: Bool,
        didConfirmSelectionCaretTransitionPreviewMaterialized: Bool,
        didConfirmFocusRollbackSnapshotMaterialized: Bool,
        didConfirmFocusChangeExplainReceiptMaterialized: Bool,
        didConfirmFocusMovementBoundToStage837FocusManagerInput: Bool,
        didConfirmStage839PublishableStateFocusDemoSurfacePrepared: Bool,
        didConfirmFocusDispatch: Bool,
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
        this.focusManager = focusManager
        this.movementPreviewPlan = movementPreviewPlan
        this.movementPreviewFacts = movementPreviewFacts
        this.didConfirmStage838PublishableStateFocusMovementPreviewReady = didConfirmStage838PublishableStateFocusMovementPreviewReady
        this.didConfirmStage837PublishableStateFocusManagerConsumed = didConfirmStage837PublishableStateFocusManagerConsumed
        this.didConfirmStage836PublishableStateLayoutStyleRuntimeManagerConsumedTransitively = didConfirmStage836PublishableStateLayoutStyleRuntimeManagerConsumedTransitively
        this.didConfirmOwnerLocalFocusTraversalManagerInputConsumed = didConfirmOwnerLocalFocusTraversalManagerInputConsumed
        this.didConfirmOwnerLocalFocusMovementPreviewMaterialized = didConfirmOwnerLocalFocusMovementPreviewMaterialized
        this.didConfirmSelectionCaretTransitionPreviewMaterialized = didConfirmSelectionCaretTransitionPreviewMaterialized
        this.didConfirmFocusRollbackSnapshotMaterialized = didConfirmFocusRollbackSnapshotMaterialized
        this.didConfirmFocusChangeExplainReceiptMaterialized = didConfirmFocusChangeExplainReceiptMaterialized
        this.didConfirmFocusMovementBoundToStage837FocusManagerInput = didConfirmFocusMovementBoundToStage837FocusManagerInput
        this.didConfirmStage839PublishableStateFocusDemoSurfacePrepared = didConfirmStage839PublishableStateFocusDemoSurfacePrepared
        this.didConfirmFocusDispatch = didConfirmFocusDispatch
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

func cjguiInternalRendererStage838PublishableStateFocusMovementPreviewMaterialized(): Bool {
    return true
}

func cjguiInternalBuildRendererStage838PublishableStateFocusMovementPreviewPlan(
    focusManager: CjguiInternalRendererStage837PublishableStateFocusManagerReadiness): CjguiInternalRendererStage838PublishableStateFocusMovementPreviewPlan {
    let stage837Ready = focusManager.didConfirmStage837PublishableStateFocusManagerReady && focusManager
        .didConfirmStage838PublishableStateFocusMovementPreviewPrepared
    let focusInputReady = focusManager.didConfirmOwnerLocalFocusTraversalManagerInputMaterialized && focusManager
        .didConfirmFocusableSlotOrderLedgerMaterialized && focusManager.didConfirmCaretAnchorCandidateLedgerMaterialized
    let movementReady = stage837Ready && focusInputReady &&
        cjguiInternalRendererStage838PublishableStateFocusMovementPreviewMaterialized()
    return CjguiInternalRendererStage838PublishableStateFocusMovementPreviewPlan(
        stage837Ready,
        focusInputReady,
        movementReady,
        movementReady,
        movementReady,
        movementReady,
        focusManager.didConfirmOwnerLocalFocusTraversalManagerInputMaterialized,
        movementReady,
        true,
        focusManager.didConfirmFocusMutation == false,
        focusManager.didConfirmInputPipelineExecution == false,
        focusManager.didConfirmRendererSubmission == false,
        focusManager.didConfirmRendererStateWrite == false,
        focusManager.didConfirmRuntimeStateWrite == false
    )
}

func cjguiInternalBuildRendererStage838PublishableStateFocusMovementPreviewFacts(
    focusManager: CjguiInternalRendererStage837PublishableStateFocusManagerReadiness,
    movementPreviewPlan: CjguiInternalRendererStage838PublishableStateFocusMovementPreviewPlan
): CjguiInternalRendererStage838PublishableStateFocusMovementPreviewFacts {
    return CjguiInternalRendererStage838PublishableStateFocusMovementPreviewFacts(
        movementPreviewPlan,
        focusManager.didConfirmPublicComponentApiAdded,
        focusManager.didConfirmNewPublicSurfaceAdded == false,
        focusManager.didConfirmStablePublicApiAdded == false,
        focusManager.didConfirmPublicCAbiAdded == false,
        focusManager.didConfirmStateStoreCommitPublished == false,
        focusManager.didConfirmActionDispatch == false,
        focusManager.didConfirmStateUpdateCommitted == false,
        focusManager.didConfirmVisibilityPublicationAdmitted == false,
        focusManager.didConfirmVisibilityPublished == false,
        focusManager.didConfirmNativeBridgeExpansionBlocked
    )
}

func cjguiInternalBuildRendererStage838PublishableStateFocusMovementPreviewReadiness(
    focusManager: CjguiInternalRendererStage837PublishableStateFocusManagerReadiness,
    movementPreviewPlan: CjguiInternalRendererStage838PublishableStateFocusMovementPreviewPlan,
    movementPreviewFacts: CjguiInternalRendererStage838PublishableStateFocusMovementPreviewFacts
): CjguiInternalRendererStage838PublishableStateFocusMovementPreviewReadiness {
    let movementReady = movementPreviewPlan.didConsumeStage837PublishableStateFocusManager && movementPreviewPlan
        .didConsumeOwnerLocalFocusTraversalManagerInput && movementPreviewPlan
        .didMaterializeOwnerLocalFocusMovementPreview && movementPreviewPlan
        .didMaterializeSelectionCaretTransitionPreview && movementPreviewPlan.didMaterializeFocusRollbackSnapshot && movementPreviewPlan
        .didMaterializeFocusChangeExplainReceipt && movementPreviewPlan.didBindFocusMovementToStage837FocusManagerInput &&
        movementPreviewPlan.didPrepareStage839PublishableStateFocusDemoSurface
    let stopLineReady = movementPreviewPlan.didKeepFocusDispatchBlocked && movementPreviewPlan
        .didKeepFocusMutationBlocked && movementPreviewPlan.didKeepInputPipelineExecutionBlocked && movementPreviewFacts
        .didKeepPublicComponentApiAdded && movementPreviewFacts.didKeepNoNewPublicSurfaceAdded && movementPreviewFacts
        .didKeepStablePublicApiNotAdded && movementPreviewFacts.didKeepPublicCAbiNotAdded && movementPreviewFacts
        .didKeepStateStoreCommitNotPublished && movementPreviewFacts.didKeepActionDispatchBlocked && movementPreviewFacts
        .didKeepStateUpdateCommittedBlocked && movementPreviewFacts.didKeepVisibilityPublicationAdmittedBlocked && movementPreviewFacts
        .didKeepVisibilityPublishedBlocked && movementPreviewPlan.didKeepRendererSubmissionBlocked && movementPreviewPlan
        .didKeepRendererStateWriteBlocked && movementPreviewPlan.didKeepRuntimeStateWriteBlocked && movementPreviewFacts
        .didKeepNativeBridgeExpansionBlocked
    return CjguiInternalRendererStage838PublishableStateFocusMovementPreviewReadiness(
        focusManager,
        movementPreviewPlan,
        movementPreviewFacts,
        movementReady && stopLineReady,
        movementPreviewPlan.didConsumeStage837PublishableStateFocusManager,
        focusManager.didConfirmStage836PublishableStateLayoutStyleRuntimeManagerConsumed,
        movementPreviewPlan.didConsumeOwnerLocalFocusTraversalManagerInput,
        movementPreviewPlan.didMaterializeOwnerLocalFocusMovementPreview,
        movementPreviewPlan.didMaterializeSelectionCaretTransitionPreview,
        movementPreviewPlan.didMaterializeFocusRollbackSnapshot,
        movementPreviewPlan.didMaterializeFocusChangeExplainReceipt,
        movementPreviewPlan.didBindFocusMovementToStage837FocusManagerInput,
        movementPreviewPlan.didPrepareStage839PublishableStateFocusDemoSurface,
        false,
        false,
        false,
        movementPreviewFacts.didKeepPublicComponentApiAdded,
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
        movementPreviewFacts.didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage838PublishableStateFocusMovementPreviewDraft(): CjguiInternalRendererStage838PublishableStateFocusMovementPreviewReadiness {
    let focusManager = cjguiInternalExecuteDefaultRendererStage837PublishableStateFocusManagerDraft()
    let movementPreviewPlan = cjguiInternalBuildRendererStage838PublishableStateFocusMovementPreviewPlan(focusManager)
    let movementPreviewFacts = cjguiInternalBuildRendererStage838PublishableStateFocusMovementPreviewFacts(
        focusManager,
        movementPreviewPlan
    )
    return cjguiInternalBuildRendererStage838PublishableStateFocusMovementPreviewReadiness(
        focusManager,
        movementPreviewPlan,
        movementPreviewFacts
    )
}
