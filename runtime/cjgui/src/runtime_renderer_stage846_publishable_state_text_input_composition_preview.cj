// 中文维护注释：本文件是 stage846 publishable state text input composition preview owner。
// Owner: 消费 stage845 text input adapter，生成文本插入、选择替换、光标移动与 composition 预览。
// Truth: 只证明 normalized text input intent 可转换为可回滚、可解释的文本预览。
// Stop-line: 不修改文本状态、不执行 input pipeline、不提交 state-store、不写 renderer_state/runtime_state。
// Same-shape Boundary Brake: 本 slice 将 keyboard / selection / composition 预览统一为共享 preview shape。
package cjgui

struct CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewPlan {
    let didConsumeStage845PublishableStateTextInputAdapter: Bool
    let didConsumeNormalizedTextInputIntents: Bool
    let didMaterializeTextInsertionPreview: Bool
    let didMaterializeSelectionReplacementPreview: Bool
    let didMaterializeCaretMovementPreview: Bool
    let didMaterializeCompositionCommitCancelPreview: Bool
    let didMaterializeTextInputRollbackSnapshot: Bool
    let didMaterializeTextInputExplainReceipt: Bool
    let didBindCompositionPreviewToStage842EditPreview: Bool
    let didPrepareStage847PublishableStateTextInputDemoSurface: Bool
    let didKeepTextMutationBlocked: Bool
    let didKeepInputPipelineExecutionBlocked: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool

    init(
        didConsumeStage845PublishableStateTextInputAdapter: Bool,
        didConsumeNormalizedTextInputIntents: Bool,
        didMaterializeTextInsertionPreview: Bool,
        didMaterializeSelectionReplacementPreview: Bool,
        didMaterializeCaretMovementPreview: Bool,
        didMaterializeCompositionCommitCancelPreview: Bool,
        didMaterializeTextInputRollbackSnapshot: Bool,
        didMaterializeTextInputExplainReceipt: Bool,
        didBindCompositionPreviewToStage842EditPreview: Bool,
        didPrepareStage847PublishableStateTextInputDemoSurface: Bool,
        didKeepTextMutationBlocked: Bool,
        didKeepInputPipelineExecutionBlocked: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool
    ) {
        this.didConsumeStage845PublishableStateTextInputAdapter = didConsumeStage845PublishableStateTextInputAdapter
        this.didConsumeNormalizedTextInputIntents = didConsumeNormalizedTextInputIntents
        this.didMaterializeTextInsertionPreview = didMaterializeTextInsertionPreview
        this.didMaterializeSelectionReplacementPreview = didMaterializeSelectionReplacementPreview
        this.didMaterializeCaretMovementPreview = didMaterializeCaretMovementPreview
        this.didMaterializeCompositionCommitCancelPreview = didMaterializeCompositionCommitCancelPreview
        this.didMaterializeTextInputRollbackSnapshot = didMaterializeTextInputRollbackSnapshot
        this.didMaterializeTextInputExplainReceipt = didMaterializeTextInputExplainReceipt
        this.didBindCompositionPreviewToStage842EditPreview = didBindCompositionPreviewToStage842EditPreview
        this.didPrepareStage847PublishableStateTextInputDemoSurface = didPrepareStage847PublishableStateTextInputDemoSurface
        this.didKeepTextMutationBlocked = didKeepTextMutationBlocked
        this.didKeepInputPipelineExecutionBlocked = didKeepInputPipelineExecutionBlocked
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepStateUpdateCommittedBlocked = didKeepStateUpdateCommittedBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
    }
}

struct CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewFacts {
    let compositionPreviewPlan: CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewPlan
    let didKeepPublicComponentApiAdded: Bool
    let didKeepNoNewPublicSurfaceAdded: Bool
    let didKeepStablePublicApiNotAdded: Bool
    let didKeepPublicCAbiNotAdded: Bool
    let didKeepStateStoreCommitNotPublished: Bool
    let didKeepVisibilityPublicationAdmittedBlocked: Bool
    let didKeepVisibilityPublishedBlocked: Bool
    let didKeepNativeBridgeExpansionBlocked: Bool

    init(
        compositionPreviewPlan: CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewPlan,
        didKeepPublicComponentApiAdded: Bool,
        didKeepNoNewPublicSurfaceAdded: Bool,
        didKeepStablePublicApiNotAdded: Bool,
        didKeepPublicCAbiNotAdded: Bool,
        didKeepStateStoreCommitNotPublished: Bool,
        didKeepVisibilityPublicationAdmittedBlocked: Bool,
        didKeepVisibilityPublishedBlocked: Bool,
        didKeepNativeBridgeExpansionBlocked: Bool
    ) {
        this.compositionPreviewPlan = compositionPreviewPlan
        this.didKeepPublicComponentApiAdded = didKeepPublicComponentApiAdded
        this.didKeepNoNewPublicSurfaceAdded = didKeepNoNewPublicSurfaceAdded
        this.didKeepStablePublicApiNotAdded = didKeepStablePublicApiNotAdded
        this.didKeepPublicCAbiNotAdded = didKeepPublicCAbiNotAdded
        this.didKeepStateStoreCommitNotPublished = didKeepStateStoreCommitNotPublished
        this.didKeepVisibilityPublicationAdmittedBlocked = didKeepVisibilityPublicationAdmittedBlocked
        this.didKeepVisibilityPublishedBlocked = didKeepVisibilityPublishedBlocked
        this.didKeepNativeBridgeExpansionBlocked = didKeepNativeBridgeExpansionBlocked
    }
}

struct CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewReadiness {
    let textInputAdapter: CjguiInternalRendererStage845PublishableStateTextInputAdapterReadiness
    let compositionPreviewPlan: CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewPlan
    let compositionPreviewFacts: CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewFacts
    let didConfirmStage846PublishableStateTextInputCompositionPreviewReady: Bool
    let didConfirmStage845PublishableStateTextInputAdapterConsumed: Bool
    let didConfirmStage844PublishableStateTextRuntimeManagerConsumedTransitively: Bool
    let didConfirmStage842PublishableStateTextEditPreviewConsumedTransitively: Bool
    let didConfirmNormalizedTextInputIntentsConsumed: Bool
    let didConfirmTextInsertionPreviewMaterialized: Bool
    let didConfirmSelectionReplacementPreviewMaterialized: Bool
    let didConfirmCaretMovementPreviewMaterialized: Bool
    let didConfirmCompositionCommitCancelPreviewMaterialized: Bool
    let didConfirmTextInputRollbackSnapshotMaterialized: Bool
    let didConfirmTextInputExplainReceiptMaterialized: Bool
    let didConfirmCompositionPreviewBoundToStage842EditPreview: Bool
    let didConfirmStage847PublishableStateTextInputDemoSurfacePrepared: Bool
    let didConfirmTextMutation: Bool
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
        textInputAdapter: CjguiInternalRendererStage845PublishableStateTextInputAdapterReadiness,
        compositionPreviewPlan: CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewPlan,
        compositionPreviewFacts: CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewFacts,
        didConfirmStage846PublishableStateTextInputCompositionPreviewReady: Bool,
        didConfirmStage845PublishableStateTextInputAdapterConsumed: Bool,
        didConfirmStage844PublishableStateTextRuntimeManagerConsumedTransitively: Bool,
        didConfirmStage842PublishableStateTextEditPreviewConsumedTransitively: Bool,
        didConfirmNormalizedTextInputIntentsConsumed: Bool,
        didConfirmTextInsertionPreviewMaterialized: Bool,
        didConfirmSelectionReplacementPreviewMaterialized: Bool,
        didConfirmCaretMovementPreviewMaterialized: Bool,
        didConfirmCompositionCommitCancelPreviewMaterialized: Bool,
        didConfirmTextInputRollbackSnapshotMaterialized: Bool,
        didConfirmTextInputExplainReceiptMaterialized: Bool,
        didConfirmCompositionPreviewBoundToStage842EditPreview: Bool,
        didConfirmStage847PublishableStateTextInputDemoSurfacePrepared: Bool,
        didConfirmTextMutation: Bool,
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
        this.textInputAdapter = textInputAdapter
        this.compositionPreviewPlan = compositionPreviewPlan
        this.compositionPreviewFacts = compositionPreviewFacts
        this.didConfirmStage846PublishableStateTextInputCompositionPreviewReady = didConfirmStage846PublishableStateTextInputCompositionPreviewReady
        this.didConfirmStage845PublishableStateTextInputAdapterConsumed = didConfirmStage845PublishableStateTextInputAdapterConsumed
        this.didConfirmStage844PublishableStateTextRuntimeManagerConsumedTransitively = didConfirmStage844PublishableStateTextRuntimeManagerConsumedTransitively
        this.didConfirmStage842PublishableStateTextEditPreviewConsumedTransitively = didConfirmStage842PublishableStateTextEditPreviewConsumedTransitively
        this.didConfirmNormalizedTextInputIntentsConsumed = didConfirmNormalizedTextInputIntentsConsumed
        this.didConfirmTextInsertionPreviewMaterialized = didConfirmTextInsertionPreviewMaterialized
        this.didConfirmSelectionReplacementPreviewMaterialized = didConfirmSelectionReplacementPreviewMaterialized
        this.didConfirmCaretMovementPreviewMaterialized = didConfirmCaretMovementPreviewMaterialized
        this.didConfirmCompositionCommitCancelPreviewMaterialized = didConfirmCompositionCommitCancelPreviewMaterialized
        this.didConfirmTextInputRollbackSnapshotMaterialized = didConfirmTextInputRollbackSnapshotMaterialized
        this.didConfirmTextInputExplainReceiptMaterialized = didConfirmTextInputExplainReceiptMaterialized
        this.didConfirmCompositionPreviewBoundToStage842EditPreview = didConfirmCompositionPreviewBoundToStage842EditPreview
        this.didConfirmStage847PublishableStateTextInputDemoSurfacePrepared = didConfirmStage847PublishableStateTextInputDemoSurfacePrepared
        this.didConfirmTextMutation = didConfirmTextMutation
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

func cjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewMaterialized(): Bool {
    return true
}

func cjguiInternalBuildRendererStage846PublishableStateTextInputCompositionPreviewPlan(
    textInputAdapter: CjguiInternalRendererStage845PublishableStateTextInputAdapterReadiness): CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewPlan {
    let stage845Ready = textInputAdapter.didConfirmStage845PublishableStateTextInputAdapterReady && textInputAdapter
        .didConfirmStage846PublishableStateTextInputCompositionPreviewPrepared
    let normalizedReady = textInputAdapter.didConfirmNormalizedKeyboardTextIntentAdapterMaterialized && textInputAdapter
        .didConfirmCaretMovementIntentAdapterMaterialized && textInputAdapter
        .didConfirmSelectionReplacementIntentAdapterMaterialized && textInputAdapter
        .didConfirmCompositionPreeditIntentAdapterMaterialized
    let previewReady = stage845Ready && normalizedReady &&
        cjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewMaterialized()
    return CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewPlan(
        stage845Ready,
        normalizedReady,
        previewReady,
        previewReady,
        previewReady,
        previewReady,
        previewReady,
        previewReady,
        textInputAdapter.didConfirmTextInputAdapterBoundToStage844TextRuntimeManager && textInputAdapter
            .textRuntimeManager
            .didConfirmTextRuntimeManagerBoundToStage842EditPreview,
        previewReady,
        textInputAdapter.didConfirmTextMutation == false,
        textInputAdapter.didConfirmInputPipelineExecution == false,
        textInputAdapter.didConfirmActionDispatch == false,
        textInputAdapter.didConfirmStateUpdateCommitted == false,
        textInputAdapter.didConfirmRendererSubmission == false,
        textInputAdapter.didConfirmRendererStateWrite == false,
        textInputAdapter.didConfirmRuntimeStateWrite == false
    )
}

func cjguiInternalBuildRendererStage846PublishableStateTextInputCompositionPreviewFacts(
    textInputAdapter: CjguiInternalRendererStage845PublishableStateTextInputAdapterReadiness,
    compositionPreviewPlan: CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewPlan
): CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewFacts {
    return CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewFacts(
        compositionPreviewPlan,
        textInputAdapter.didConfirmPublicComponentApiAdded,
        textInputAdapter.didConfirmNewPublicSurfaceAdded == false,
        textInputAdapter.didConfirmStablePublicApiAdded == false,
        textInputAdapter.didConfirmPublicCAbiAdded == false,
        textInputAdapter.didConfirmStateStoreCommitPublished == false,
        textInputAdapter.didConfirmVisibilityPublicationAdmitted == false,
        textInputAdapter.didConfirmVisibilityPublished == false,
        textInputAdapter.didConfirmNativeBridgeExpansionBlocked
    )
}

func cjguiInternalBuildRendererStage846PublishableStateTextInputCompositionPreviewReadiness(
    textInputAdapter: CjguiInternalRendererStage845PublishableStateTextInputAdapterReadiness,
    compositionPreviewPlan: CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewPlan,
    compositionPreviewFacts: CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewFacts
): CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewReadiness {
    let previewReady = compositionPreviewPlan.didConsumeStage845PublishableStateTextInputAdapter && compositionPreviewPlan
        .didConsumeNormalizedTextInputIntents && compositionPreviewPlan.didMaterializeTextInsertionPreview && compositionPreviewPlan
        .didMaterializeSelectionReplacementPreview && compositionPreviewPlan.didMaterializeCaretMovementPreview && compositionPreviewPlan
        .didMaterializeCompositionCommitCancelPreview && compositionPreviewPlan.didMaterializeTextInputRollbackSnapshot &&
        compositionPreviewPlan.didMaterializeTextInputExplainReceipt && compositionPreviewPlan
        .didBindCompositionPreviewToStage842EditPreview && compositionPreviewPlan
        .didPrepareStage847PublishableStateTextInputDemoSurface
    let stopLineReady = compositionPreviewPlan.didKeepTextMutationBlocked && compositionPreviewPlan
        .didKeepInputPipelineExecutionBlocked && compositionPreviewPlan.didKeepActionDispatchBlocked && compositionPreviewPlan
        .didKeepStateUpdateCommittedBlocked && compositionPreviewFacts.didKeepPublicComponentApiAdded && compositionPreviewFacts
        .didKeepNoNewPublicSurfaceAdded && compositionPreviewFacts.didKeepStablePublicApiNotAdded && compositionPreviewFacts
        .didKeepPublicCAbiNotAdded && compositionPreviewFacts.didKeepStateStoreCommitNotPublished && compositionPreviewFacts
        .didKeepVisibilityPublicationAdmittedBlocked && compositionPreviewFacts.didKeepVisibilityPublishedBlocked && compositionPreviewPlan
        .didKeepRendererSubmissionBlocked && compositionPreviewPlan.didKeepRendererStateWriteBlocked && compositionPreviewPlan
        .didKeepRuntimeStateWriteBlocked && compositionPreviewFacts.didKeepNativeBridgeExpansionBlocked
    return CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewReadiness(
        textInputAdapter,
        compositionPreviewPlan,
        compositionPreviewFacts,
        previewReady && stopLineReady,
        compositionPreviewPlan.didConsumeStage845PublishableStateTextInputAdapter,
        textInputAdapter.didConfirmStage844PublishableStateTextRuntimeManagerConsumed,
        textInputAdapter.didConfirmStage842PublishableStateTextEditPreviewConsumedTransitively,
        compositionPreviewPlan.didConsumeNormalizedTextInputIntents,
        compositionPreviewPlan.didMaterializeTextInsertionPreview,
        compositionPreviewPlan.didMaterializeSelectionReplacementPreview,
        compositionPreviewPlan.didMaterializeCaretMovementPreview,
        compositionPreviewPlan.didMaterializeCompositionCommitCancelPreview,
        compositionPreviewPlan.didMaterializeTextInputRollbackSnapshot,
        compositionPreviewPlan.didMaterializeTextInputExplainReceipt,
        compositionPreviewPlan.didBindCompositionPreviewToStage842EditPreview,
        compositionPreviewPlan.didPrepareStage847PublishableStateTextInputDemoSurface,
        false,
        false,
        compositionPreviewFacts.didKeepPublicComponentApiAdded,
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
        compositionPreviewFacts.didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage846PublishableStateTextInputCompositionPreviewDraft(): CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewReadiness {
    let textInputAdapter = cjguiInternalExecuteDefaultRendererStage845PublishableStateTextInputAdapterDraft()
    let compositionPreviewPlan = cjguiInternalBuildRendererStage846PublishableStateTextInputCompositionPreviewPlan(
        textInputAdapter)
    let compositionPreviewFacts = cjguiInternalBuildRendererStage846PublishableStateTextInputCompositionPreviewFacts(
        textInputAdapter,
        compositionPreviewPlan
    )
    return cjguiInternalBuildRendererStage846PublishableStateTextInputCompositionPreviewReadiness(
        textInputAdapter,
        compositionPreviewPlan,
        compositionPreviewFacts
    )
}
