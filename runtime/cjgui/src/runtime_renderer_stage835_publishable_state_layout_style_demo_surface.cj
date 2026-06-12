// 中文维护注释：本文件是 stage835 publishable state layout/style demo surface owner。
// Owner: 消费 stage834 text/focus measurement plan，生成五类 demo 的 layout/style preview surface。
// Truth: 只证明 resolver preview 可投影到 demo-host result surface，不执行 host mutation。
// Stop-line: 不变更 host、不提交状态、不写 renderer_state/runtime_state、不扩 public API。
// Same-shape Boundary Brake: 本 slice 将五类 demo 的 layout/style preview 收敛为共享 surface 形状。
package cjgui

struct CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfacePlan {
    let didConsumeStage834PublishableStateTextFocusMeasurementPlan: Bool
    let didConsumeTextFocusMeasurementPlan: Bool
    let didMaterializeTodoLayoutStylePreviewSurface: Bool
    let didMaterializeSettingsLayoutStylePreviewSurface: Bool
    let didMaterializeAiGeneratedSettingsLayoutStylePreviewSurface: Bool
    let didMaterializeChatComposerLayoutStylePreviewSurface: Bool
    let didMaterializeFileBrowserLayoutStylePreviewSurface: Bool
    let didMaterializeLayoutStyleResultSurfaceReceipt: Bool
    let didBindDemoSurfaceToTextFocusMeasurementPlan: Bool
    let didPrepareStage836PublishableStateLayoutStyleRuntimeManager: Bool
    let didKeepHostMutationBlocked: Bool
    let didKeepLayoutEngineDisabled: Bool
    let didKeepStyleResolverProductionDisabled: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool

    init(
        didConsumeStage834PublishableStateTextFocusMeasurementPlan: Bool,
        didConsumeTextFocusMeasurementPlan: Bool,
        didMaterializeTodoLayoutStylePreviewSurface: Bool,
        didMaterializeSettingsLayoutStylePreviewSurface: Bool,
        didMaterializeAiGeneratedSettingsLayoutStylePreviewSurface: Bool,
        didMaterializeChatComposerLayoutStylePreviewSurface: Bool,
        didMaterializeFileBrowserLayoutStylePreviewSurface: Bool,
        didMaterializeLayoutStyleResultSurfaceReceipt: Bool,
        didBindDemoSurfaceToTextFocusMeasurementPlan: Bool,
        didPrepareStage836PublishableStateLayoutStyleRuntimeManager: Bool,
        didKeepHostMutationBlocked: Bool,
        didKeepLayoutEngineDisabled: Bool,
        didKeepStyleResolverProductionDisabled: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool
    ) {
        this.didConsumeStage834PublishableStateTextFocusMeasurementPlan = didConsumeStage834PublishableStateTextFocusMeasurementPlan
        this.didConsumeTextFocusMeasurementPlan = didConsumeTextFocusMeasurementPlan
        this.didMaterializeTodoLayoutStylePreviewSurface = didMaterializeTodoLayoutStylePreviewSurface
        this.didMaterializeSettingsLayoutStylePreviewSurface = didMaterializeSettingsLayoutStylePreviewSurface
        this.didMaterializeAiGeneratedSettingsLayoutStylePreviewSurface = didMaterializeAiGeneratedSettingsLayoutStylePreviewSurface
        this.didMaterializeChatComposerLayoutStylePreviewSurface = didMaterializeChatComposerLayoutStylePreviewSurface
        this.didMaterializeFileBrowserLayoutStylePreviewSurface = didMaterializeFileBrowserLayoutStylePreviewSurface
        this.didMaterializeLayoutStyleResultSurfaceReceipt = didMaterializeLayoutStyleResultSurfaceReceipt
        this.didBindDemoSurfaceToTextFocusMeasurementPlan = didBindDemoSurfaceToTextFocusMeasurementPlan
        this.didPrepareStage836PublishableStateLayoutStyleRuntimeManager = didPrepareStage836PublishableStateLayoutStyleRuntimeManager
        this.didKeepHostMutationBlocked = didKeepHostMutationBlocked
        this.didKeepLayoutEngineDisabled = didKeepLayoutEngineDisabled
        this.didKeepStyleResolverProductionDisabled = didKeepStyleResolverProductionDisabled
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
    }
}

struct CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfaceFacts {
    let demoSurfacePlan: CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfacePlan
    let didKeepPublicComponentApiAdded: Bool
    let didKeepNoNewPublicSurfaceAdded: Bool
    let didKeepStablePublicApiNotAdded: Bool
    let didKeepPublicCAbiNotAdded: Bool
    let didKeepStateStoreCommitNotPublished: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepNativeBridgeExpansionBlocked: Bool

    init(
        demoSurfacePlan: CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfacePlan,
        didKeepPublicComponentApiAdded: Bool,
        didKeepNoNewPublicSurfaceAdded: Bool,
        didKeepStablePublicApiNotAdded: Bool,
        didKeepPublicCAbiNotAdded: Bool,
        didKeepStateStoreCommitNotPublished: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepNativeBridgeExpansionBlocked: Bool
    ) {
        this.demoSurfacePlan = demoSurfacePlan
        this.didKeepPublicComponentApiAdded = didKeepPublicComponentApiAdded
        this.didKeepNoNewPublicSurfaceAdded = didKeepNoNewPublicSurfaceAdded
        this.didKeepStablePublicApiNotAdded = didKeepStablePublicApiNotAdded
        this.didKeepPublicCAbiNotAdded = didKeepPublicCAbiNotAdded
        this.didKeepStateStoreCommitNotPublished = didKeepStateStoreCommitNotPublished
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepStateUpdateCommittedBlocked = didKeepStateUpdateCommittedBlocked
        this.didKeepNativeBridgeExpansionBlocked = didKeepNativeBridgeExpansionBlocked
    }
}

struct CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfaceReadiness {
    let textFocusMeasurement: CjguiInternalRendererStage834PublishableStateTextFocusMeasurementReadiness
    let demoSurfacePlan: CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfacePlan
    let demoSurfaceFacts: CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfaceFacts
    let didConfirmStage835PublishableStateLayoutStyleDemoSurfaceReady: Bool
    let didConfirmStage834PublishableStateTextFocusMeasurementPlanConsumed: Bool
    let didConfirmStage833PublishableStateLayoutStyleResolverConsumedTransitively: Bool
    let didConfirmTextFocusMeasurementPlanConsumed: Bool
    let didConfirmTodoLayoutStylePreviewSurfaceMaterialized: Bool
    let didConfirmSettingsLayoutStylePreviewSurfaceMaterialized: Bool
    let didConfirmAiGeneratedSettingsLayoutStylePreviewSurfaceMaterialized: Bool
    let didConfirmChatComposerLayoutStylePreviewSurfaceMaterialized: Bool
    let didConfirmFileBrowserLayoutStylePreviewSurfaceMaterialized: Bool
    let didConfirmLayoutStyleResultSurfaceReceiptMaterialized: Bool
    let didConfirmDemoSurfaceBoundToTextFocusMeasurementPlan: Bool
    let didConfirmStage836PublishableStateLayoutStyleRuntimeManagerPrepared: Bool
    let didConfirmHostMutation: Bool
    let didConfirmLayoutEngineEnabled: Bool
    let didConfirmStyleResolverProductionEnabled: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmNewPublicSurfaceAdded: Bool
    let didConfirmStablePublicApiAdded: Bool
    let didConfirmPublicCAbiAdded: Bool
    let didConfirmStateStoreCommitPublished: Bool
    let didConfirmActionDispatch: Bool
    let didConfirmStateUpdateCommitted: Bool
    let didConfirmRendererSubmission: Bool
    let didConfirmRendererStateWrite: Bool
    let didConfirmRuntimeStateWrite: Bool
    let didConfirmNativeBridgeExpansionBlocked: Bool

    init(
        textFocusMeasurement: CjguiInternalRendererStage834PublishableStateTextFocusMeasurementReadiness,
        demoSurfacePlan: CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfacePlan,
        demoSurfaceFacts: CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfaceFacts,
        didConfirmStage835PublishableStateLayoutStyleDemoSurfaceReady: Bool,
        didConfirmStage834PublishableStateTextFocusMeasurementPlanConsumed: Bool,
        didConfirmStage833PublishableStateLayoutStyleResolverConsumedTransitively: Bool,
        didConfirmTextFocusMeasurementPlanConsumed: Bool,
        didConfirmTodoLayoutStylePreviewSurfaceMaterialized: Bool,
        didConfirmSettingsLayoutStylePreviewSurfaceMaterialized: Bool,
        didConfirmAiGeneratedSettingsLayoutStylePreviewSurfaceMaterialized: Bool,
        didConfirmChatComposerLayoutStylePreviewSurfaceMaterialized: Bool,
        didConfirmFileBrowserLayoutStylePreviewSurfaceMaterialized: Bool,
        didConfirmLayoutStyleResultSurfaceReceiptMaterialized: Bool,
        didConfirmDemoSurfaceBoundToTextFocusMeasurementPlan: Bool,
        didConfirmStage836PublishableStateLayoutStyleRuntimeManagerPrepared: Bool,
        didConfirmHostMutation: Bool,
        didConfirmLayoutEngineEnabled: Bool,
        didConfirmStyleResolverProductionEnabled: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmNewPublicSurfaceAdded: Bool,
        didConfirmStablePublicApiAdded: Bool,
        didConfirmPublicCAbiAdded: Bool,
        didConfirmStateStoreCommitPublished: Bool,
        didConfirmActionDispatch: Bool,
        didConfirmStateUpdateCommitted: Bool,
        didConfirmRendererSubmission: Bool,
        didConfirmRendererStateWrite: Bool,
        didConfirmRuntimeStateWrite: Bool,
        didConfirmNativeBridgeExpansionBlocked: Bool
    ) {
        this.textFocusMeasurement = textFocusMeasurement
        this.demoSurfacePlan = demoSurfacePlan
        this.demoSurfaceFacts = demoSurfaceFacts
        this.didConfirmStage835PublishableStateLayoutStyleDemoSurfaceReady = didConfirmStage835PublishableStateLayoutStyleDemoSurfaceReady
        this.didConfirmStage834PublishableStateTextFocusMeasurementPlanConsumed = didConfirmStage834PublishableStateTextFocusMeasurementPlanConsumed
        this.didConfirmStage833PublishableStateLayoutStyleResolverConsumedTransitively = didConfirmStage833PublishableStateLayoutStyleResolverConsumedTransitively
        this.didConfirmTextFocusMeasurementPlanConsumed = didConfirmTextFocusMeasurementPlanConsumed
        this.didConfirmTodoLayoutStylePreviewSurfaceMaterialized = didConfirmTodoLayoutStylePreviewSurfaceMaterialized
        this.didConfirmSettingsLayoutStylePreviewSurfaceMaterialized = didConfirmSettingsLayoutStylePreviewSurfaceMaterialized
        this.didConfirmAiGeneratedSettingsLayoutStylePreviewSurfaceMaterialized = didConfirmAiGeneratedSettingsLayoutStylePreviewSurfaceMaterialized
        this.didConfirmChatComposerLayoutStylePreviewSurfaceMaterialized = didConfirmChatComposerLayoutStylePreviewSurfaceMaterialized
        this.didConfirmFileBrowserLayoutStylePreviewSurfaceMaterialized = didConfirmFileBrowserLayoutStylePreviewSurfaceMaterialized
        this.didConfirmLayoutStyleResultSurfaceReceiptMaterialized = didConfirmLayoutStyleResultSurfaceReceiptMaterialized
        this.didConfirmDemoSurfaceBoundToTextFocusMeasurementPlan = didConfirmDemoSurfaceBoundToTextFocusMeasurementPlan
        this.didConfirmStage836PublishableStateLayoutStyleRuntimeManagerPrepared = didConfirmStage836PublishableStateLayoutStyleRuntimeManagerPrepared
        this.didConfirmHostMutation = didConfirmHostMutation
        this.didConfirmLayoutEngineEnabled = didConfirmLayoutEngineEnabled
        this.didConfirmStyleResolverProductionEnabled = didConfirmStyleResolverProductionEnabled
        this.didConfirmPublicComponentApiAdded = didConfirmPublicComponentApiAdded
        this.didConfirmNewPublicSurfaceAdded = didConfirmNewPublicSurfaceAdded
        this.didConfirmStablePublicApiAdded = didConfirmStablePublicApiAdded
        this.didConfirmPublicCAbiAdded = didConfirmPublicCAbiAdded
        this.didConfirmStateStoreCommitPublished = didConfirmStateStoreCommitPublished
        this.didConfirmActionDispatch = didConfirmActionDispatch
        this.didConfirmStateUpdateCommitted = didConfirmStateUpdateCommitted
        this.didConfirmRendererSubmission = didConfirmRendererSubmission
        this.didConfirmRendererStateWrite = didConfirmRendererStateWrite
        this.didConfirmRuntimeStateWrite = didConfirmRuntimeStateWrite
        this.didConfirmNativeBridgeExpansionBlocked = didConfirmNativeBridgeExpansionBlocked
    }
}

func cjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfaceMaterialized(): Bool {
    return true
}

func cjguiInternalBuildRendererStage835PublishableStateLayoutStyleDemoSurfacePlan(
    textFocusMeasurement: CjguiInternalRendererStage834PublishableStateTextFocusMeasurementReadiness): CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfacePlan {
    let stage834Ready = textFocusMeasurement.didConfirmStage834PublishableStateTextFocusMeasurementPlanReady && textFocusMeasurement
        .didConfirmStage835PublishableStateLayoutStyleDemoSurfacePrepared
    let measurementReady = textFocusMeasurement.didConfirmTextRunMeasurementInputMaterialized && textFocusMeasurement
        .didConfirmCaretGeometryPlaceholderMaterialized && textFocusMeasurement
        .didConfirmFocusTraversalMeasurementLedgerMaterialized
    let surfaceReady = stage834Ready && measurementReady &&
        cjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfaceMaterialized()
    return CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfacePlan(
        stage834Ready,
        measurementReady,
        surfaceReady,
        surfaceReady,
        surfaceReady,
        surfaceReady,
        surfaceReady,
        surfaceReady,
        textFocusMeasurement.didConfirmMeasurementPlanBoundToLayoutStyleResolver,
        surfaceReady,
        true,
        textFocusMeasurement.didConfirmTextShapingEnabled == false,
        textFocusMeasurement.didConfirmFocusManagerEnabled == false,
        textFocusMeasurement.didConfirmRendererSubmission == false,
        textFocusMeasurement.didConfirmRendererStateWrite == false,
        textFocusMeasurement.didConfirmRuntimeStateWrite == false
    )
}

func cjguiInternalBuildRendererStage835PublishableStateLayoutStyleDemoSurfaceFacts(
    textFocusMeasurement: CjguiInternalRendererStage834PublishableStateTextFocusMeasurementReadiness,
    demoSurfacePlan: CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfacePlan
): CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfaceFacts {
    return CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfaceFacts(
        demoSurfacePlan,
        textFocusMeasurement.didConfirmPublicComponentApiAdded,
        textFocusMeasurement.didConfirmNewPublicSurfaceAdded == false,
        textFocusMeasurement.didConfirmStablePublicApiAdded == false,
        textFocusMeasurement.didConfirmPublicCAbiAdded == false,
        textFocusMeasurement.didConfirmStateStoreCommitPublished == false,
        textFocusMeasurement.didConfirmActionDispatch == false,
        textFocusMeasurement.didConfirmStateUpdateCommitted == false,
        textFocusMeasurement.didConfirmNativeBridgeExpansionBlocked
    )
}

func cjguiInternalBuildRendererStage835PublishableStateLayoutStyleDemoSurfaceReadiness(
    textFocusMeasurement: CjguiInternalRendererStage834PublishableStateTextFocusMeasurementReadiness,
    demoSurfacePlan: CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfacePlan,
    demoSurfaceFacts: CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfaceFacts
): CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfaceReadiness {
    let surfaceReady = demoSurfacePlan.didConsumeStage834PublishableStateTextFocusMeasurementPlan && demoSurfacePlan
        .didConsumeTextFocusMeasurementPlan && demoSurfacePlan.didMaterializeTodoLayoutStylePreviewSurface && demoSurfacePlan
        .didMaterializeSettingsLayoutStylePreviewSurface && demoSurfacePlan
        .didMaterializeAiGeneratedSettingsLayoutStylePreviewSurface && demoSurfacePlan
        .didMaterializeChatComposerLayoutStylePreviewSurface && demoSurfacePlan
        .didMaterializeFileBrowserLayoutStylePreviewSurface && demoSurfacePlan
        .didMaterializeLayoutStyleResultSurfaceReceipt && demoSurfacePlan.didBindDemoSurfaceToTextFocusMeasurementPlan &&
        demoSurfacePlan.didPrepareStage836PublishableStateLayoutStyleRuntimeManager
    let stopLineReady = demoSurfacePlan.didKeepHostMutationBlocked && demoSurfacePlan.didKeepLayoutEngineDisabled && demoSurfacePlan
        .didKeepStyleResolverProductionDisabled && demoSurfaceFacts.didKeepPublicComponentApiAdded && demoSurfaceFacts
        .didKeepNoNewPublicSurfaceAdded && demoSurfaceFacts.didKeepStablePublicApiNotAdded && demoSurfaceFacts
        .didKeepPublicCAbiNotAdded && demoSurfaceFacts.didKeepStateStoreCommitNotPublished && demoSurfaceFacts
        .didKeepActionDispatchBlocked && demoSurfaceFacts.didKeepStateUpdateCommittedBlocked && demoSurfacePlan
        .didKeepRendererSubmissionBlocked && demoSurfacePlan.didKeepRendererStateWriteBlocked && demoSurfacePlan
        .didKeepRuntimeStateWriteBlocked && demoSurfaceFacts.didKeepNativeBridgeExpansionBlocked
    return CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfaceReadiness(
        textFocusMeasurement,
        demoSurfacePlan,
        demoSurfaceFacts,
        surfaceReady && stopLineReady,
        demoSurfacePlan.didConsumeStage834PublishableStateTextFocusMeasurementPlan,
        textFocusMeasurement.didConfirmStage833PublishableStateLayoutStyleResolverConsumed,
        demoSurfacePlan.didConsumeTextFocusMeasurementPlan,
        demoSurfacePlan.didMaterializeTodoLayoutStylePreviewSurface,
        demoSurfacePlan.didMaterializeSettingsLayoutStylePreviewSurface,
        demoSurfacePlan.didMaterializeAiGeneratedSettingsLayoutStylePreviewSurface,
        demoSurfacePlan.didMaterializeChatComposerLayoutStylePreviewSurface,
        demoSurfacePlan.didMaterializeFileBrowserLayoutStylePreviewSurface,
        demoSurfacePlan.didMaterializeLayoutStyleResultSurfaceReceipt,
        demoSurfacePlan.didBindDemoSurfaceToTextFocusMeasurementPlan,
        demoSurfacePlan.didPrepareStage836PublishableStateLayoutStyleRuntimeManager,
        false,
        false,
        false,
        demoSurfaceFacts.didKeepPublicComponentApiAdded,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        demoSurfaceFacts.didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage835PublishableStateLayoutStyleDemoSurfaceDraft(): CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfaceReadiness {
    let textFocusMeasurement = cjguiInternalExecuteDefaultRendererStage834PublishableStateTextFocusMeasurementDraft()
    let demoSurfacePlan = cjguiInternalBuildRendererStage835PublishableStateLayoutStyleDemoSurfacePlan(
        textFocusMeasurement)
    let demoSurfaceFacts = cjguiInternalBuildRendererStage835PublishableStateLayoutStyleDemoSurfaceFacts(
        textFocusMeasurement,
        demoSurfacePlan
    )
    return cjguiInternalBuildRendererStage835PublishableStateLayoutStyleDemoSurfaceReadiness(
        textFocusMeasurement,
        demoSurfacePlan,
        demoSurfaceFacts
    )
}
