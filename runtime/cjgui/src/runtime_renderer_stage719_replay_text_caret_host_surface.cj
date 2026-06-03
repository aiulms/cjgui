// 中文维护注释：本文件是 stage719 replay text/caret host surface owner。
// Owner: 消费 stage718 style/focus resolver，生成 text/caret/composition host inspection surface。
// Truth: 只证明 resolved preview 可形成可检查的 text/caret host surface，不做真实文本排版。
// Stop-line: 不启用 text shaping、不提交 state、不执行 host/renderer、不写 renderer_state/runtime_state。
// Same-shape Boundary Brake: 本 slice 把 text/caret host inspection 抽成共享 surface。
package cjgui

struct CjguiInternalRendererStage719ReplayTextCaretHostSurfacePlan {
    let didConsumeStage718ReplayStyleFocusResolver: Bool
    let didConsumeReplayStyleFocusResolutionReceipts: Bool
    let didMaterializeSharedReplayTextCaretModel: Bool
    let didMaterializeReplayTextSelectionLedger: Bool
    let didMaterializeReplayCaretPositionLedger: Bool
    let didMaterializeReplayCompositionPlaceholderLedger: Bool
    let didMaterializeReplayDemoHostInspectionSurface: Bool
    let didMaterializeTodoReplayTextCaretHostSurface: Bool
    let didMaterializeSettingsReplayTextCaretHostSurface: Bool
    let didMaterializeAiGeneratedSettingsReplayTextCaretHostSurface: Bool
    let didMaterializeChatComposerReplayTextCaretHostSurface: Bool
    let didBindTextCaretHostSurfaceToStage718Resolver: Bool
    let didKeepTextCaretHostSurfaceCheckable: Bool
    let didPrepareStage720ReplayVisualRuntimeManager: Bool
    let didKeepHostMutationBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool

    init(
        didConsumeStage718ReplayStyleFocusResolver: Bool,
        didConsumeReplayStyleFocusResolutionReceipts: Bool,
        didMaterializeSharedReplayTextCaretModel: Bool,
        didMaterializeReplayTextSelectionLedger: Bool,
        didMaterializeReplayCaretPositionLedger: Bool,
        didMaterializeReplayCompositionPlaceholderLedger: Bool,
        didMaterializeReplayDemoHostInspectionSurface: Bool,
        didMaterializeTodoReplayTextCaretHostSurface: Bool,
        didMaterializeSettingsReplayTextCaretHostSurface: Bool,
        didMaterializeAiGeneratedSettingsReplayTextCaretHostSurface: Bool,
        didMaterializeChatComposerReplayTextCaretHostSurface: Bool,
        didBindTextCaretHostSurfaceToStage718Resolver: Bool,
        didKeepTextCaretHostSurfaceCheckable: Bool,
        didPrepareStage720ReplayVisualRuntimeManager: Bool,
        didKeepHostMutationBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool
    ) {
        this.didConsumeStage718ReplayStyleFocusResolver = didConsumeStage718ReplayStyleFocusResolver
        this.didConsumeReplayStyleFocusResolutionReceipts = didConsumeReplayStyleFocusResolutionReceipts
        this.didMaterializeSharedReplayTextCaretModel = didMaterializeSharedReplayTextCaretModel
        this.didMaterializeReplayTextSelectionLedger = didMaterializeReplayTextSelectionLedger
        this.didMaterializeReplayCaretPositionLedger = didMaterializeReplayCaretPositionLedger
        this.didMaterializeReplayCompositionPlaceholderLedger = didMaterializeReplayCompositionPlaceholderLedger
        this.didMaterializeReplayDemoHostInspectionSurface = didMaterializeReplayDemoHostInspectionSurface
        this.didMaterializeTodoReplayTextCaretHostSurface = didMaterializeTodoReplayTextCaretHostSurface
        this.didMaterializeSettingsReplayTextCaretHostSurface = didMaterializeSettingsReplayTextCaretHostSurface
        this.didMaterializeAiGeneratedSettingsReplayTextCaretHostSurface = didMaterializeAiGeneratedSettingsReplayTextCaretHostSurface
        this.didMaterializeChatComposerReplayTextCaretHostSurface = didMaterializeChatComposerReplayTextCaretHostSurface
        this.didBindTextCaretHostSurfaceToStage718Resolver = didBindTextCaretHostSurfaceToStage718Resolver
        this.didKeepTextCaretHostSurfaceCheckable = didKeepTextCaretHostSurfaceCheckable
        this.didPrepareStage720ReplayVisualRuntimeManager = didPrepareStage720ReplayVisualRuntimeManager
        this.didKeepHostMutationBlocked = didKeepHostMutationBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
    }
}

struct CjguiInternalRendererStage719ReplayTextCaretHostSurfaceFacts {
    let textCaretHostSurfacePlan: CjguiInternalRendererStage719ReplayTextCaretHostSurfacePlan
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
        textCaretHostSurfacePlan: CjguiInternalRendererStage719ReplayTextCaretHostSurfacePlan,
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
        this.textCaretHostSurfacePlan = textCaretHostSurfacePlan
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

struct CjguiInternalRendererStage719ReplayTextCaretHostSurfaceReadiness {
    let styleFocusResolver: CjguiInternalRendererStage718ReplayStyleFocusResolverReadiness
    let textCaretHostSurfacePlan: CjguiInternalRendererStage719ReplayTextCaretHostSurfacePlan
    let textCaretHostSurfaceFacts: CjguiInternalRendererStage719ReplayTextCaretHostSurfaceFacts
    let didConfirmStage719ReplayTextCaretHostSurfaceReady: Bool
    let didConfirmStage718ReplayStyleFocusResolverConsumed: Bool
    let didConfirmStage717ReplayVisualPreviewConsumedTransitively: Bool
    let didConfirmStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorConsumedTransitively: Bool
    let didConfirmReplayStyleFocusResolutionReceiptsConsumed: Bool
    let didConfirmSharedReplayTextCaretModelMaterialized: Bool
    let didConfirmReplayTextSelectionLedgerMaterialized: Bool
    let didConfirmReplayCaretPositionLedgerMaterialized: Bool
    let didConfirmReplayCompositionPlaceholderLedgerMaterialized: Bool
    let didConfirmReplayDemoHostInspectionSurfaceMaterialized: Bool
    let didConfirmTodoReplayTextCaretHostSurfaceMaterialized: Bool
    let didConfirmSettingsReplayTextCaretHostSurfaceMaterialized: Bool
    let didConfirmAiGeneratedSettingsReplayTextCaretHostSurfaceMaterialized: Bool
    let didConfirmChatComposerReplayTextCaretHostSurfaceMaterialized: Bool
    let didConfirmTextCaretHostSurfaceBoundToStage718Resolver: Bool
    let didConfirmTextCaretHostSurfaceCheckable: Bool
    let didConfirmStage720ReplayVisualRuntimeManagerPrepared: Bool
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
        styleFocusResolver: CjguiInternalRendererStage718ReplayStyleFocusResolverReadiness,
        textCaretHostSurfacePlan: CjguiInternalRendererStage719ReplayTextCaretHostSurfacePlan,
        textCaretHostSurfaceFacts: CjguiInternalRendererStage719ReplayTextCaretHostSurfaceFacts,
        didConfirmStage719ReplayTextCaretHostSurfaceReady: Bool,
        didConfirmStage718ReplayStyleFocusResolverConsumed: Bool,
        didConfirmStage717ReplayVisualPreviewConsumedTransitively: Bool,
        didConfirmStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorConsumedTransitively: Bool,
        didConfirmReplayStyleFocusResolutionReceiptsConsumed: Bool,
        didConfirmSharedReplayTextCaretModelMaterialized: Bool,
        didConfirmReplayTextSelectionLedgerMaterialized: Bool,
        didConfirmReplayCaretPositionLedgerMaterialized: Bool,
        didConfirmReplayCompositionPlaceholderLedgerMaterialized: Bool,
        didConfirmReplayDemoHostInspectionSurfaceMaterialized: Bool,
        didConfirmTodoReplayTextCaretHostSurfaceMaterialized: Bool,
        didConfirmSettingsReplayTextCaretHostSurfaceMaterialized: Bool,
        didConfirmAiGeneratedSettingsReplayTextCaretHostSurfaceMaterialized: Bool,
        didConfirmChatComposerReplayTextCaretHostSurfaceMaterialized: Bool,
        didConfirmTextCaretHostSurfaceBoundToStage718Resolver: Bool,
        didConfirmTextCaretHostSurfaceCheckable: Bool,
        didConfirmStage720ReplayVisualRuntimeManagerPrepared: Bool,
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
        this.styleFocusResolver = styleFocusResolver
        this.textCaretHostSurfacePlan = textCaretHostSurfacePlan
        this.textCaretHostSurfaceFacts = textCaretHostSurfaceFacts
        this.didConfirmStage719ReplayTextCaretHostSurfaceReady = didConfirmStage719ReplayTextCaretHostSurfaceReady
        this.didConfirmStage718ReplayStyleFocusResolverConsumed = didConfirmStage718ReplayStyleFocusResolverConsumed
        this.didConfirmStage717ReplayVisualPreviewConsumedTransitively = didConfirmStage717ReplayVisualPreviewConsumedTransitively
        this.didConfirmStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorConsumedTransitively = didConfirmStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorConsumedTransitively
        this.didConfirmReplayStyleFocusResolutionReceiptsConsumed = didConfirmReplayStyleFocusResolutionReceiptsConsumed
        this.didConfirmSharedReplayTextCaretModelMaterialized = didConfirmSharedReplayTextCaretModelMaterialized
        this.didConfirmReplayTextSelectionLedgerMaterialized = didConfirmReplayTextSelectionLedgerMaterialized
        this.didConfirmReplayCaretPositionLedgerMaterialized = didConfirmReplayCaretPositionLedgerMaterialized
        this.didConfirmReplayCompositionPlaceholderLedgerMaterialized = didConfirmReplayCompositionPlaceholderLedgerMaterialized
        this.didConfirmReplayDemoHostInspectionSurfaceMaterialized = didConfirmReplayDemoHostInspectionSurfaceMaterialized
        this.didConfirmTodoReplayTextCaretHostSurfaceMaterialized = didConfirmTodoReplayTextCaretHostSurfaceMaterialized
        this.didConfirmSettingsReplayTextCaretHostSurfaceMaterialized = didConfirmSettingsReplayTextCaretHostSurfaceMaterialized
        this.didConfirmAiGeneratedSettingsReplayTextCaretHostSurfaceMaterialized = didConfirmAiGeneratedSettingsReplayTextCaretHostSurfaceMaterialized
        this.didConfirmChatComposerReplayTextCaretHostSurfaceMaterialized = didConfirmChatComposerReplayTextCaretHostSurfaceMaterialized
        this.didConfirmTextCaretHostSurfaceBoundToStage718Resolver = didConfirmTextCaretHostSurfaceBoundToStage718Resolver
        this.didConfirmTextCaretHostSurfaceCheckable = didConfirmTextCaretHostSurfaceCheckable
        this.didConfirmStage720ReplayVisualRuntimeManagerPrepared = didConfirmStage720ReplayVisualRuntimeManagerPrepared
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

func cjguiInternalRendererStage719ReplayTextCaretHostSurfaceMaterialized(): Bool {
    return true
}

func cjguiInternalBuildRendererStage719ReplayTextCaretHostSurfacePlan(
    styleFocusResolver: CjguiInternalRendererStage718ReplayStyleFocusResolverReadiness): CjguiInternalRendererStage719ReplayTextCaretHostSurfacePlan {
    let stage718Ready = styleFocusResolver.didConfirmStage718ReplayStyleFocusResolverReady && styleFocusResolver
        .didConfirmStage719ReplayTextCaretHostSurfacePrepared
    let resolutionReceiptsReady = styleFocusResolver.didConfirmSharedReplayStyleResolverDryRunMaterialized && styleFocusResolver
        .didConfirmSharedReplayFocusManagerDryRunMaterialized && styleFocusResolver
        .didConfirmResolvedVisualStyleLedgerMaterialized && styleFocusResolver
        .didConfirmFocusMovementLedgerMaterialized && styleFocusResolver
        .didConfirmValidationFocusHandoffLedgerMaterialized && styleFocusResolver
        .didConfirmChatComposerReplayStyleFocusResolutionMaterialized
    let hostSurfaceReady = stage718Ready && resolutionReceiptsReady &&
        cjguiInternalRendererStage719ReplayTextCaretHostSurfaceMaterialized()
    return CjguiInternalRendererStage719ReplayTextCaretHostSurfacePlan(
        stage718Ready,
        resolutionReceiptsReady,
        hostSurfaceReady,
        hostSurfaceReady,
        hostSurfaceReady,
        hostSurfaceReady,
        hostSurfaceReady,
        hostSurfaceReady,
        hostSurfaceReady,
        hostSurfaceReady,
        hostSurfaceReady,
        styleFocusResolver.didConfirmStyleFocusResolverBoundToStage717Preview,
        true,
        hostSurfaceReady,
        styleFocusResolver.didConfirmHostMutation == false,
        styleFocusResolver.didConfirmRendererSubmissionBlocked,
        styleFocusResolver.didConfirmRendererStateWriteBlocked,
        styleFocusResolver.didConfirmRuntimeStateWriteBlocked
    )
}

func cjguiInternalBuildRendererStage719ReplayTextCaretHostSurfaceFacts(
    styleFocusResolver: CjguiInternalRendererStage718ReplayStyleFocusResolverReadiness,
    textCaretHostSurfacePlan: CjguiInternalRendererStage719ReplayTextCaretHostSurfacePlan
): CjguiInternalRendererStage719ReplayTextCaretHostSurfaceFacts {
    return CjguiInternalRendererStage719ReplayTextCaretHostSurfaceFacts(
        textCaretHostSurfacePlan,
        styleFocusResolver.didConfirmOwnerAcceptanceRequired,
        styleFocusResolver.didConfirmOwnerAcceptanceGranted == false,
        styleFocusResolver.didConfirmProductionRenderTruth == false,
        styleFocusResolver.didConfirmBackendReadyTruth == false,
        styleFocusResolver.didConfirmPublicComponentApiAdded == false,
        styleFocusResolver.didConfirmInputEventPipelineExecution == false,
        styleFocusResolver.didConfirmActionDispatch == false,
        styleFocusResolver.didConfirmStateUpdateCommitted == false,
        styleFocusResolver.didConfirmVisibilityPublicationAdmitted == false,
        styleFocusResolver.didConfirmVisibilityPublished == false,
        styleFocusResolver.didConfirmNativeBridgeExpansionBlocked
    )
}

func cjguiInternalBuildRendererStage719ReplayTextCaretHostSurfaceReadiness(
    styleFocusResolver: CjguiInternalRendererStage718ReplayStyleFocusResolverReadiness,
    textCaretHostSurfacePlan: CjguiInternalRendererStage719ReplayTextCaretHostSurfacePlan,
    textCaretHostSurfaceFacts: CjguiInternalRendererStage719ReplayTextCaretHostSurfaceFacts
): CjguiInternalRendererStage719ReplayTextCaretHostSurfaceReadiness {
    let hostSurfaceReady = textCaretHostSurfacePlan.didConsumeStage718ReplayStyleFocusResolver && textCaretHostSurfacePlan
        .didConsumeReplayStyleFocusResolutionReceipts && textCaretHostSurfacePlan
        .didMaterializeSharedReplayTextCaretModel && textCaretHostSurfacePlan.didMaterializeReplayTextSelectionLedger && textCaretHostSurfacePlan
        .didMaterializeReplayCaretPositionLedger && textCaretHostSurfacePlan
        .didMaterializeReplayCompositionPlaceholderLedger && textCaretHostSurfacePlan
        .didMaterializeReplayDemoHostInspectionSurface && textCaretHostSurfacePlan
        .didMaterializeChatComposerReplayTextCaretHostSurface && textCaretHostSurfacePlan
        .didBindTextCaretHostSurfaceToStage718Resolver && textCaretHostSurfacePlan.didKeepTextCaretHostSurfaceCheckable &&
        textCaretHostSurfacePlan.didPrepareStage720ReplayVisualRuntimeManager
    let stopLineReady = textCaretHostSurfacePlan.didKeepHostMutationBlocked && textCaretHostSurfaceFacts
        .didKeepOwnerAcceptanceRequired && textCaretHostSurfaceFacts.didKeepOwnerAcceptanceNotGranted && textCaretHostSurfaceFacts
        .didKeepProductionRenderTruthBlocked && textCaretHostSurfaceFacts.didKeepBackendReadyTruthBlocked && textCaretHostSurfaceFacts
        .didKeepPublicComponentApiBlocked && textCaretHostSurfaceFacts.didKeepInputEventPipelineExecutionBlocked && textCaretHostSurfaceFacts
        .didKeepActionDispatchBlocked && textCaretHostSurfaceFacts.didKeepStateUpdateCommittedBlocked && textCaretHostSurfaceFacts
        .didKeepVisibilityPublicationAdmittedBlocked && textCaretHostSurfaceFacts.didKeepVisibilityPublishedBlocked && textCaretHostSurfacePlan
        .didKeepRendererSubmissionBlocked && textCaretHostSurfacePlan.didKeepRendererStateWriteBlocked && textCaretHostSurfacePlan
        .didKeepRuntimeStateWriteBlocked && textCaretHostSurfaceFacts.didKeepNativeBridgeExpansionBlocked
    return CjguiInternalRendererStage719ReplayTextCaretHostSurfaceReadiness(
        styleFocusResolver,
        textCaretHostSurfacePlan,
        textCaretHostSurfaceFacts,
        hostSurfaceReady && stopLineReady,
        textCaretHostSurfacePlan.didConsumeStage718ReplayStyleFocusResolver,
        styleFocusResolver.didConfirmStage717ReplayVisualPreviewConsumed,
        styleFocusResolver
            .didConfirmStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorConsumedTransitively,
        textCaretHostSurfacePlan.didConsumeReplayStyleFocusResolutionReceipts,
        textCaretHostSurfacePlan.didMaterializeSharedReplayTextCaretModel,
        textCaretHostSurfacePlan.didMaterializeReplayTextSelectionLedger,
        textCaretHostSurfacePlan.didMaterializeReplayCaretPositionLedger,
        textCaretHostSurfacePlan.didMaterializeReplayCompositionPlaceholderLedger,
        textCaretHostSurfacePlan.didMaterializeReplayDemoHostInspectionSurface,
        textCaretHostSurfacePlan.didMaterializeTodoReplayTextCaretHostSurface,
        textCaretHostSurfacePlan.didMaterializeSettingsReplayTextCaretHostSurface,
        textCaretHostSurfacePlan.didMaterializeAiGeneratedSettingsReplayTextCaretHostSurface,
        textCaretHostSurfacePlan.didMaterializeChatComposerReplayTextCaretHostSurface,
        textCaretHostSurfacePlan.didBindTextCaretHostSurfaceToStage718Resolver,
        textCaretHostSurfacePlan.didKeepTextCaretHostSurfaceCheckable,
        textCaretHostSurfacePlan.didPrepareStage720ReplayVisualRuntimeManager,
        false,
        textCaretHostSurfaceFacts.didKeepOwnerAcceptanceRequired,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        textCaretHostSurfacePlan.didKeepRendererSubmissionBlocked,
        textCaretHostSurfacePlan.didKeepRendererStateWriteBlocked,
        textCaretHostSurfacePlan.didKeepRuntimeStateWriteBlocked,
        textCaretHostSurfaceFacts.didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage719ReplayTextCaretHostSurfaceDraft(): CjguiInternalRendererStage719ReplayTextCaretHostSurfaceReadiness {
    let styleFocusResolver = cjguiInternalExecuteDefaultRendererStage718ReplayStyleFocusResolverDraft()
    let textCaretHostSurfacePlan = cjguiInternalBuildRendererStage719ReplayTextCaretHostSurfacePlan(styleFocusResolver)
    let textCaretHostSurfaceFacts = cjguiInternalBuildRendererStage719ReplayTextCaretHostSurfaceFacts(
        styleFocusResolver,
        textCaretHostSurfacePlan
    )
    return cjguiInternalBuildRendererStage719ReplayTextCaretHostSurfaceReadiness(
        styleFocusResolver,
        textCaretHostSurfacePlan,
        textCaretHostSurfaceFacts
    )
}
