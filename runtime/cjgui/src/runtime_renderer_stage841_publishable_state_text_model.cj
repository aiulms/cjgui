// 中文维护注释：本文件是 stage841 publishable state text model owner。
// Owner: 消费 stage840 focus runtime manager，建立 owner-local text value / selection / caret / composition model。
// Truth: 只证明 focus/runtime contract 可形成可检查文本模型，不执行文本排版或真实编辑。
// Stop-line: 不启用 text shaping、不派发 input、不提交状态、不写 renderer_state/runtime_state、不扩 public API。
// Same-shape Boundary Brake: 本 slice 用共享 text model 输入替代后续 per-demo text 模板。
package cjgui

struct CjguiInternalRendererStage841PublishableStateTextModelPlan {
    let didConsumeStage840PublishableStateFocusRuntimeManager: Bool
    let didConsumeSharedPublishableFocusRuntimeManager: Bool
    let didMaterializeOwnerLocalTextValueModel: Bool
    let didMaterializeTextRunLedger: Bool
    let didMaterializeSelectionRangeModel: Bool
    let didMaterializeCaretPositionModel: Bool
    let didMaterializeCompositionPlaceholderModel: Bool
    let didBindTextModelToStage834MeasurementPlan: Bool
    let didBindTextModelToStage840FocusRuntimeManager: Bool
    let didPrepareStage842PublishableStateTextEditPreview: Bool
    let didKeepTextShapingDisabled: Bool
    let didKeepTextMutationBlocked: Bool
    let didKeepInputPipelineExecutionBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool

    init(
        didConsumeStage840PublishableStateFocusRuntimeManager: Bool,
        didConsumeSharedPublishableFocusRuntimeManager: Bool,
        didMaterializeOwnerLocalTextValueModel: Bool,
        didMaterializeTextRunLedger: Bool,
        didMaterializeSelectionRangeModel: Bool,
        didMaterializeCaretPositionModel: Bool,
        didMaterializeCompositionPlaceholderModel: Bool,
        didBindTextModelToStage834MeasurementPlan: Bool,
        didBindTextModelToStage840FocusRuntimeManager: Bool,
        didPrepareStage842PublishableStateTextEditPreview: Bool,
        didKeepTextShapingDisabled: Bool,
        didKeepTextMutationBlocked: Bool,
        didKeepInputPipelineExecutionBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool
    ) {
        this.didConsumeStage840PublishableStateFocusRuntimeManager = didConsumeStage840PublishableStateFocusRuntimeManager
        this.didConsumeSharedPublishableFocusRuntimeManager = didConsumeSharedPublishableFocusRuntimeManager
        this.didMaterializeOwnerLocalTextValueModel = didMaterializeOwnerLocalTextValueModel
        this.didMaterializeTextRunLedger = didMaterializeTextRunLedger
        this.didMaterializeSelectionRangeModel = didMaterializeSelectionRangeModel
        this.didMaterializeCaretPositionModel = didMaterializeCaretPositionModel
        this.didMaterializeCompositionPlaceholderModel = didMaterializeCompositionPlaceholderModel
        this.didBindTextModelToStage834MeasurementPlan = didBindTextModelToStage834MeasurementPlan
        this.didBindTextModelToStage840FocusRuntimeManager = didBindTextModelToStage840FocusRuntimeManager
        this.didPrepareStage842PublishableStateTextEditPreview = didPrepareStage842PublishableStateTextEditPreview
        this.didKeepTextShapingDisabled = didKeepTextShapingDisabled
        this.didKeepTextMutationBlocked = didKeepTextMutationBlocked
        this.didKeepInputPipelineExecutionBlocked = didKeepInputPipelineExecutionBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
    }
}

struct CjguiInternalRendererStage841PublishableStateTextModelFacts {
    let textModelPlan: CjguiInternalRendererStage841PublishableStateTextModelPlan
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
        textModelPlan: CjguiInternalRendererStage841PublishableStateTextModelPlan,
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
        this.textModelPlan = textModelPlan
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

struct CjguiInternalRendererStage841PublishableStateTextModelReadiness {
    let focusRuntimeManager: CjguiInternalRendererStage840PublishableStateFocusRuntimeManagerReadiness
    let textModelPlan: CjguiInternalRendererStage841PublishableStateTextModelPlan
    let textModelFacts: CjguiInternalRendererStage841PublishableStateTextModelFacts
    let didConfirmStage841PublishableStateTextModelReady: Bool
    let didConfirmStage840PublishableStateFocusRuntimeManagerConsumed: Bool
    let didConfirmStage839PublishableStateFocusDemoSurfaceConsumedTransitively: Bool
    let didConfirmStage834PublishableStateTextFocusMeasurementPlanConsumedTransitively: Bool
    let didConfirmSharedPublishableFocusRuntimeManagerConsumed: Bool
    let didConfirmOwnerLocalTextValueModelMaterialized: Bool
    let didConfirmTextRunLedgerMaterialized: Bool
    let didConfirmSelectionRangeModelMaterialized: Bool
    let didConfirmCaretPositionModelMaterialized: Bool
    let didConfirmCompositionPlaceholderModelMaterialized: Bool
    let didConfirmTextModelBoundToStage834MeasurementPlan: Bool
    let didConfirmTextModelBoundToStage840FocusRuntimeManager: Bool
    let didConfirmStage842PublishableStateTextEditPreviewPrepared: Bool
    let didConfirmTextShapingEnabled: Bool
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
        focusRuntimeManager: CjguiInternalRendererStage840PublishableStateFocusRuntimeManagerReadiness,
        textModelPlan: CjguiInternalRendererStage841PublishableStateTextModelPlan,
        textModelFacts: CjguiInternalRendererStage841PublishableStateTextModelFacts,
        didConfirmStage841PublishableStateTextModelReady: Bool,
        didConfirmStage840PublishableStateFocusRuntimeManagerConsumed: Bool,
        didConfirmStage839PublishableStateFocusDemoSurfaceConsumedTransitively: Bool,
        didConfirmStage834PublishableStateTextFocusMeasurementPlanConsumedTransitively: Bool,
        didConfirmSharedPublishableFocusRuntimeManagerConsumed: Bool,
        didConfirmOwnerLocalTextValueModelMaterialized: Bool,
        didConfirmTextRunLedgerMaterialized: Bool,
        didConfirmSelectionRangeModelMaterialized: Bool,
        didConfirmCaretPositionModelMaterialized: Bool,
        didConfirmCompositionPlaceholderModelMaterialized: Bool,
        didConfirmTextModelBoundToStage834MeasurementPlan: Bool,
        didConfirmTextModelBoundToStage840FocusRuntimeManager: Bool,
        didConfirmStage842PublishableStateTextEditPreviewPrepared: Bool,
        didConfirmTextShapingEnabled: Bool,
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
        this.focusRuntimeManager = focusRuntimeManager
        this.textModelPlan = textModelPlan
        this.textModelFacts = textModelFacts
        this.didConfirmStage841PublishableStateTextModelReady = didConfirmStage841PublishableStateTextModelReady
        this.didConfirmStage840PublishableStateFocusRuntimeManagerConsumed = didConfirmStage840PublishableStateFocusRuntimeManagerConsumed
        this.didConfirmStage839PublishableStateFocusDemoSurfaceConsumedTransitively = didConfirmStage839PublishableStateFocusDemoSurfaceConsumedTransitively
        this.didConfirmStage834PublishableStateTextFocusMeasurementPlanConsumedTransitively = didConfirmStage834PublishableStateTextFocusMeasurementPlanConsumedTransitively
        this.didConfirmSharedPublishableFocusRuntimeManagerConsumed = didConfirmSharedPublishableFocusRuntimeManagerConsumed
        this.didConfirmOwnerLocalTextValueModelMaterialized = didConfirmOwnerLocalTextValueModelMaterialized
        this.didConfirmTextRunLedgerMaterialized = didConfirmTextRunLedgerMaterialized
        this.didConfirmSelectionRangeModelMaterialized = didConfirmSelectionRangeModelMaterialized
        this.didConfirmCaretPositionModelMaterialized = didConfirmCaretPositionModelMaterialized
        this.didConfirmCompositionPlaceholderModelMaterialized = didConfirmCompositionPlaceholderModelMaterialized
        this.didConfirmTextModelBoundToStage834MeasurementPlan = didConfirmTextModelBoundToStage834MeasurementPlan
        this.didConfirmTextModelBoundToStage840FocusRuntimeManager = didConfirmTextModelBoundToStage840FocusRuntimeManager
        this.didConfirmStage842PublishableStateTextEditPreviewPrepared = didConfirmStage842PublishableStateTextEditPreviewPrepared
        this.didConfirmTextShapingEnabled = didConfirmTextShapingEnabled
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

func cjguiInternalRendererStage841PublishableStateTextModelMaterialized(): Bool {
    return true
}

func cjguiInternalBuildRendererStage841PublishableStateTextModelPlan(
    focusRuntimeManager: CjguiInternalRendererStage840PublishableStateFocusRuntimeManagerReadiness): CjguiInternalRendererStage841PublishableStateTextModelPlan {
    let stage840Ready = focusRuntimeManager.didConfirmStage840PublishableStateFocusRuntimeManagerReady && focusRuntimeManager
        .didConfirmStage841PublishableStateTextModelAfterStage840Prepared
    let focusRuntimeReady = focusRuntimeManager.didConfirmSharedPublishableFocusRuntimeManagerMaterialized && focusRuntimeManager
        .didConfirmPublishableFocusRuntimeContractMaterialized && focusRuntimeManager
        .didConfirmFileBrowserFocusRuntimeSurfaceMaterialized
    let measurementReady = focusRuntimeManager
        .didConfirmStage836PublishableStateLayoutStyleRuntimeManagerConsumedTransitively && focusRuntimeManager
        .focusDemoSurface
        .focusMovementPreview
        .focusManager
        .layoutStyleRuntimeManager
        .layoutStyleDemoSurface
        .textFocusMeasurement
        .didConfirmTextRunMeasurementInputMaterialized && focusRuntimeManager
        .focusDemoSurface
        .focusMovementPreview
        .focusManager
        .layoutStyleRuntimeManager
        .layoutStyleDemoSurface
        .textFocusMeasurement
        .didConfirmSelectionRangeMeasurementInputMaterialized && focusRuntimeManager
        .focusDemoSurface
        .focusMovementPreview
        .focusManager
        .layoutStyleRuntimeManager
        .layoutStyleDemoSurface
        .textFocusMeasurement
        .didConfirmCaretGeometryPlaceholderMaterialized
    let textModelReady = stage840Ready && focusRuntimeReady && measurementReady &&
        cjguiInternalRendererStage841PublishableStateTextModelMaterialized()
    return CjguiInternalRendererStage841PublishableStateTextModelPlan(
        stage840Ready,
        focusRuntimeReady,
        textModelReady,
        textModelReady,
        textModelReady,
        textModelReady,
        textModelReady,
        measurementReady,
        focusRuntimeManager.didConfirmFocusRuntimeManagerBoundToStage837FocusManagerInput,
        textModelReady,
        focusRuntimeManager
            .focusDemoSurface
            .focusMovementPreview
            .focusManager
            .layoutStyleRuntimeManager
            .didConfirmTextShapingEnabled == false,
        true,
        focusRuntimeManager.didConfirmInputPipelineExecution == false,
        focusRuntimeManager.didConfirmRendererSubmission == false,
        focusRuntimeManager.didConfirmRendererStateWrite == false,
        focusRuntimeManager.didConfirmRuntimeStateWrite == false
    )
}

func cjguiInternalBuildRendererStage841PublishableStateTextModelFacts(
    focusRuntimeManager: CjguiInternalRendererStage840PublishableStateFocusRuntimeManagerReadiness,
    textModelPlan: CjguiInternalRendererStage841PublishableStateTextModelPlan
): CjguiInternalRendererStage841PublishableStateTextModelFacts {
    return CjguiInternalRendererStage841PublishableStateTextModelFacts(
        textModelPlan,
        focusRuntimeManager.didConfirmPublicComponentApiAdded,
        focusRuntimeManager.didConfirmNewPublicSurfaceAdded == false,
        focusRuntimeManager.didConfirmStablePublicApiAdded == false,
        focusRuntimeManager.didConfirmPublicCAbiAdded == false,
        focusRuntimeManager.didConfirmStateStoreCommitPublished == false,
        focusRuntimeManager.didConfirmActionDispatch == false,
        focusRuntimeManager.didConfirmStateUpdateCommitted == false,
        focusRuntimeManager.didConfirmVisibilityPublicationAdmitted == false,
        focusRuntimeManager.didConfirmVisibilityPublished == false,
        focusRuntimeManager.didConfirmNativeBridgeExpansionBlocked
    )
}

func cjguiInternalBuildRendererStage841PublishableStateTextModelReadiness(
    focusRuntimeManager: CjguiInternalRendererStage840PublishableStateFocusRuntimeManagerReadiness,
    textModelPlan: CjguiInternalRendererStage841PublishableStateTextModelPlan,
    textModelFacts: CjguiInternalRendererStage841PublishableStateTextModelFacts
): CjguiInternalRendererStage841PublishableStateTextModelReadiness {
    let textModelReady = textModelPlan.didConsumeStage840PublishableStateFocusRuntimeManager && textModelPlan
        .didConsumeSharedPublishableFocusRuntimeManager && textModelPlan.didMaterializeOwnerLocalTextValueModel && textModelPlan
        .didMaterializeTextRunLedger && textModelPlan.didMaterializeSelectionRangeModel && textModelPlan
        .didMaterializeCaretPositionModel && textModelPlan.didMaterializeCompositionPlaceholderModel && textModelPlan
        .didBindTextModelToStage834MeasurementPlan && textModelPlan.didBindTextModelToStage840FocusRuntimeManager && textModelPlan
        .didPrepareStage842PublishableStateTextEditPreview
    let stopLineReady = textModelPlan.didKeepTextShapingDisabled && textModelPlan.didKeepTextMutationBlocked && textModelPlan
        .didKeepInputPipelineExecutionBlocked && textModelFacts.didKeepPublicComponentApiAdded && textModelFacts
        .didKeepNoNewPublicSurfaceAdded && textModelFacts.didKeepStablePublicApiNotAdded && textModelFacts
        .didKeepPublicCAbiNotAdded && textModelFacts.didKeepStateStoreCommitNotPublished && textModelFacts
        .didKeepActionDispatchBlocked && textModelFacts.didKeepStateUpdateCommittedBlocked && textModelFacts
        .didKeepVisibilityPublicationAdmittedBlocked && textModelFacts.didKeepVisibilityPublishedBlocked && textModelPlan
        .didKeepRendererSubmissionBlocked && textModelPlan.didKeepRendererStateWriteBlocked && textModelPlan
        .didKeepRuntimeStateWriteBlocked && textModelFacts.didKeepNativeBridgeExpansionBlocked
    return CjguiInternalRendererStage841PublishableStateTextModelReadiness(
        focusRuntimeManager,
        textModelPlan,
        textModelFacts,
        textModelReady && stopLineReady,
        textModelPlan.didConsumeStage840PublishableStateFocusRuntimeManager,
        focusRuntimeManager.didConfirmStage839PublishableStateFocusDemoSurfaceConsumed,
        focusRuntimeManager
            .focusDemoSurface
            .focusMovementPreview
            .focusManager
            .didConfirmStage834PublishableStateTextFocusMeasurementPlanConsumedTransitively,
        textModelPlan.didConsumeSharedPublishableFocusRuntimeManager,
        textModelPlan.didMaterializeOwnerLocalTextValueModel,
        textModelPlan.didMaterializeTextRunLedger,
        textModelPlan.didMaterializeSelectionRangeModel,
        textModelPlan.didMaterializeCaretPositionModel,
        textModelPlan.didMaterializeCompositionPlaceholderModel,
        textModelPlan.didBindTextModelToStage834MeasurementPlan,
        textModelPlan.didBindTextModelToStage840FocusRuntimeManager,
        textModelPlan.didPrepareStage842PublishableStateTextEditPreview,
        false,
        false,
        false,
        textModelFacts.didKeepPublicComponentApiAdded,
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
        textModelFacts.didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage841PublishableStateTextModelDraft(): CjguiInternalRendererStage841PublishableStateTextModelReadiness {
    let focusRuntimeManager = cjguiInternalExecuteDefaultRendererStage840PublishableStateFocusRuntimeManagerDraft()
    let textModelPlan = cjguiInternalBuildRendererStage841PublishableStateTextModelPlan(focusRuntimeManager)
    let textModelFacts = cjguiInternalBuildRendererStage841PublishableStateTextModelFacts(
        focusRuntimeManager,
        textModelPlan
    )
    return cjguiInternalBuildRendererStage841PublishableStateTextModelReadiness(
        focusRuntimeManager,
        textModelPlan,
        textModelFacts
    )
}
