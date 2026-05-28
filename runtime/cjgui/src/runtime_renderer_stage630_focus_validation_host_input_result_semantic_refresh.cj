// 中文维护注释：本文件是 stage630 focus/validation host input result semantic refresh owner。
// Owner: 消费 stage629 result surfaces，生成共享 semantic diff / explain refresh receipts。
// Truth: 只证明 result surface 可被转成可检查的语义差异与说明，不发布可见 UI。
// Stop-line: 不启用真实 input pipeline、不 dispatch、不提交 state、不执行 renderer submission。
// Same-shape Boundary Brake: 本轮把四个 demo 的 result semantic refresh 收敛为 shared ledger。
package cjgui

struct CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshPlan {
    let didConsumeStage629FocusValidationHostInputResultSurface: Bool
    let didConsumeResultSurfaceRefreshes: Bool
    let didMaterializeSharedResultSurfaceSemanticDiffRefresh: Bool
    let didMaterializeValidationErrorSemanticExplainLedger: Bool
    let didMaterializeFocusMovementSemanticExplainLedger: Bool
    let didMaterializeInputFeedbackSemanticExplainLedger: Bool
    let didMaterializeTodoResultSemanticRefreshReceipt: Bool
    let didMaterializeSettingsResultSemanticRefreshReceipt: Bool
    let didMaterializeAiGeneratedSettingsResultSemanticRefreshReceipt: Bool
    let didMaterializeChatComposerResultSemanticRefreshReceipt: Bool
    let didBindSemanticRefreshToStage629ResultSurfaces: Bool
    let didPrepareStage631FocusValidationResultSurfaceHostInspection: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool

    init(
        didConsumeStage629FocusValidationHostInputResultSurface: Bool,
        didConsumeResultSurfaceRefreshes: Bool,
        didMaterializeSharedResultSurfaceSemanticDiffRefresh: Bool,
        didMaterializeValidationErrorSemanticExplainLedger: Bool,
        didMaterializeFocusMovementSemanticExplainLedger: Bool,
        didMaterializeInputFeedbackSemanticExplainLedger: Bool,
        didMaterializeTodoResultSemanticRefreshReceipt: Bool,
        didMaterializeSettingsResultSemanticRefreshReceipt: Bool,
        didMaterializeAiGeneratedSettingsResultSemanticRefreshReceipt: Bool,
        didMaterializeChatComposerResultSemanticRefreshReceipt: Bool,
        didBindSemanticRefreshToStage629ResultSurfaces: Bool,
        didPrepareStage631FocusValidationResultSurfaceHostInspection: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool
    ) {
        this.didConsumeStage629FocusValidationHostInputResultSurface = didConsumeStage629FocusValidationHostInputResultSurface
        this.didConsumeResultSurfaceRefreshes = didConsumeResultSurfaceRefreshes
        this.didMaterializeSharedResultSurfaceSemanticDiffRefresh = didMaterializeSharedResultSurfaceSemanticDiffRefresh
        this.didMaterializeValidationErrorSemanticExplainLedger = didMaterializeValidationErrorSemanticExplainLedger
        this.didMaterializeFocusMovementSemanticExplainLedger = didMaterializeFocusMovementSemanticExplainLedger
        this.didMaterializeInputFeedbackSemanticExplainLedger = didMaterializeInputFeedbackSemanticExplainLedger
        this.didMaterializeTodoResultSemanticRefreshReceipt = didMaterializeTodoResultSemanticRefreshReceipt
        this.didMaterializeSettingsResultSemanticRefreshReceipt = didMaterializeSettingsResultSemanticRefreshReceipt
        this.didMaterializeAiGeneratedSettingsResultSemanticRefreshReceipt = didMaterializeAiGeneratedSettingsResultSemanticRefreshReceipt
        this.didMaterializeChatComposerResultSemanticRefreshReceipt = didMaterializeChatComposerResultSemanticRefreshReceipt
        this.didBindSemanticRefreshToStage629ResultSurfaces = didBindSemanticRefreshToStage629ResultSurfaces
        this.didPrepareStage631FocusValidationResultSurfaceHostInspection = didPrepareStage631FocusValidationResultSurfaceHostInspection
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
    }
}

struct CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshFacts {
    let semanticRefreshPlan: CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshPlan
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didKeepProductionRenderTruthBlocked: Bool
    let didKeepBackendReadyTruthBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepLayoutEngineBlocked: Bool
    let didKeepStyleResolverBlocked: Bool
    let didKeepFocusManagerBlocked: Bool
    let didKeepInputEventPipelineBlocked: Bool
    let didKeepInputEventPipelineExecutionBlocked: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepVisibilityPublicationAdmittedBlocked: Bool
    let didKeepVisibilityPublishedBlocked: Bool
    let didKeepNativeBridgeExpansionBlocked: Bool

    init(
        semanticRefreshPlan: CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshPlan,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didKeepProductionRenderTruthBlocked: Bool,
        didKeepBackendReadyTruthBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepLayoutEngineBlocked: Bool,
        didKeepStyleResolverBlocked: Bool,
        didKeepFocusManagerBlocked: Bool,
        didKeepInputEventPipelineBlocked: Bool,
        didKeepInputEventPipelineExecutionBlocked: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepVisibilityPublicationAdmittedBlocked: Bool,
        didKeepVisibilityPublishedBlocked: Bool,
        didKeepNativeBridgeExpansionBlocked: Bool
    ) {
        this.semanticRefreshPlan = semanticRefreshPlan
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didKeepOwnerAcceptanceNotGranted = didKeepOwnerAcceptanceNotGranted
        this.didKeepProductionRenderTruthBlocked = didKeepProductionRenderTruthBlocked
        this.didKeepBackendReadyTruthBlocked = didKeepBackendReadyTruthBlocked
        this.didKeepPublicComponentApiBlocked = didKeepPublicComponentApiBlocked
        this.didKeepLayoutEngineBlocked = didKeepLayoutEngineBlocked
        this.didKeepStyleResolverBlocked = didKeepStyleResolverBlocked
        this.didKeepFocusManagerBlocked = didKeepFocusManagerBlocked
        this.didKeepInputEventPipelineBlocked = didKeepInputEventPipelineBlocked
        this.didKeepInputEventPipelineExecutionBlocked = didKeepInputEventPipelineExecutionBlocked
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepStateUpdateCommittedBlocked = didKeepStateUpdateCommittedBlocked
        this.didKeepVisibilityPublicationAdmittedBlocked = didKeepVisibilityPublicationAdmittedBlocked
        this.didKeepVisibilityPublishedBlocked = didKeepVisibilityPublishedBlocked
        this.didKeepNativeBridgeExpansionBlocked = didKeepNativeBridgeExpansionBlocked
    }
}

struct CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshReadiness {
    let resultSurface: CjguiInternalRendererStage629FocusValidationHostInputResultSurfaceReadiness
    let semanticRefreshPlan: CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshPlan
    let semanticRefreshFacts: CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshFacts
    let didConfirmStage630FocusValidationHostInputResultSemanticRefreshReady: Bool
    let didConfirmStage629FocusValidationHostInputResultSurfaceConsumed: Bool
    let didConfirmStage628SharedFocusValidationHostInputRuntimeContractConsumedTransitively: Bool
    let didConfirmResultSurfaceRefreshesConsumed: Bool
    let didConfirmSharedResultSurfaceSemanticDiffRefreshMaterialized: Bool
    let didConfirmValidationErrorSemanticExplainLedgerMaterialized: Bool
    let didConfirmFocusMovementSemanticExplainLedgerMaterialized: Bool
    let didConfirmInputFeedbackSemanticExplainLedgerMaterialized: Bool
    let didConfirmTodoResultSemanticRefreshReceiptMaterialized: Bool
    let didConfirmSettingsResultSemanticRefreshReceiptMaterialized: Bool
    let didConfirmAiGeneratedSettingsResultSemanticRefreshReceiptMaterialized: Bool
    let didConfirmChatComposerResultSemanticRefreshReceiptMaterialized: Bool
    let didConfirmSemanticRefreshBoundToStage629ResultSurfaces: Bool
    let didConfirmStage631FocusValidationResultSurfaceHostInspectionPrepared: Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmProductionRenderTruth: Bool
    let didConfirmBackendReadyTruth: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmLayoutEngineEnabled: Bool
    let didConfirmStyleResolverEnabled: Bool
    let didConfirmFocusManagerEnabled: Bool
    let didConfirmInputEventPipelineEnabled: Bool
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
        resultSurface: CjguiInternalRendererStage629FocusValidationHostInputResultSurfaceReadiness,
        semanticRefreshPlan: CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshPlan,
        semanticRefreshFacts: CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshFacts,
        didConfirmStage630FocusValidationHostInputResultSemanticRefreshReady: Bool,
        didConfirmStage629FocusValidationHostInputResultSurfaceConsumed: Bool,
        didConfirmStage628SharedFocusValidationHostInputRuntimeContractConsumedTransitively: Bool,
        didConfirmResultSurfaceRefreshesConsumed: Bool,
        didConfirmSharedResultSurfaceSemanticDiffRefreshMaterialized: Bool,
        didConfirmValidationErrorSemanticExplainLedgerMaterialized: Bool,
        didConfirmFocusMovementSemanticExplainLedgerMaterialized: Bool,
        didConfirmInputFeedbackSemanticExplainLedgerMaterialized: Bool,
        didConfirmTodoResultSemanticRefreshReceiptMaterialized: Bool,
        didConfirmSettingsResultSemanticRefreshReceiptMaterialized: Bool,
        didConfirmAiGeneratedSettingsResultSemanticRefreshReceiptMaterialized: Bool,
        didConfirmChatComposerResultSemanticRefreshReceiptMaterialized: Bool,
        didConfirmSemanticRefreshBoundToStage629ResultSurfaces: Bool,
        didConfirmStage631FocusValidationResultSurfaceHostInspectionPrepared: Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmProductionRenderTruth: Bool,
        didConfirmBackendReadyTruth: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmLayoutEngineEnabled: Bool,
        didConfirmStyleResolverEnabled: Bool,
        didConfirmFocusManagerEnabled: Bool,
        didConfirmInputEventPipelineEnabled: Bool,
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
        this.resultSurface = resultSurface
        this.semanticRefreshPlan = semanticRefreshPlan
        this.semanticRefreshFacts = semanticRefreshFacts
        this.didConfirmStage630FocusValidationHostInputResultSemanticRefreshReady = didConfirmStage630FocusValidationHostInputResultSemanticRefreshReady
        this.didConfirmStage629FocusValidationHostInputResultSurfaceConsumed = didConfirmStage629FocusValidationHostInputResultSurfaceConsumed
        this.didConfirmStage628SharedFocusValidationHostInputRuntimeContractConsumedTransitively = didConfirmStage628SharedFocusValidationHostInputRuntimeContractConsumedTransitively
        this.didConfirmResultSurfaceRefreshesConsumed = didConfirmResultSurfaceRefreshesConsumed
        this.didConfirmSharedResultSurfaceSemanticDiffRefreshMaterialized = didConfirmSharedResultSurfaceSemanticDiffRefreshMaterialized
        this.didConfirmValidationErrorSemanticExplainLedgerMaterialized = didConfirmValidationErrorSemanticExplainLedgerMaterialized
        this.didConfirmFocusMovementSemanticExplainLedgerMaterialized = didConfirmFocusMovementSemanticExplainLedgerMaterialized
        this.didConfirmInputFeedbackSemanticExplainLedgerMaterialized = didConfirmInputFeedbackSemanticExplainLedgerMaterialized
        this.didConfirmTodoResultSemanticRefreshReceiptMaterialized = didConfirmTodoResultSemanticRefreshReceiptMaterialized
        this.didConfirmSettingsResultSemanticRefreshReceiptMaterialized = didConfirmSettingsResultSemanticRefreshReceiptMaterialized
        this.didConfirmAiGeneratedSettingsResultSemanticRefreshReceiptMaterialized = didConfirmAiGeneratedSettingsResultSemanticRefreshReceiptMaterialized
        this.didConfirmChatComposerResultSemanticRefreshReceiptMaterialized = didConfirmChatComposerResultSemanticRefreshReceiptMaterialized
        this.didConfirmSemanticRefreshBoundToStage629ResultSurfaces = didConfirmSemanticRefreshBoundToStage629ResultSurfaces
        this.didConfirmStage631FocusValidationResultSurfaceHostInspectionPrepared = didConfirmStage631FocusValidationResultSurfaceHostInspectionPrepared
        this.didConfirmOwnerAcceptanceRequired = didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted = didConfirmOwnerAcceptanceGranted
        this.didConfirmProductionRenderTruth = didConfirmProductionRenderTruth
        this.didConfirmBackendReadyTruth = didConfirmBackendReadyTruth
        this.didConfirmPublicComponentApiAdded = didConfirmPublicComponentApiAdded
        this.didConfirmLayoutEngineEnabled = didConfirmLayoutEngineEnabled
        this.didConfirmStyleResolverEnabled = didConfirmStyleResolverEnabled
        this.didConfirmFocusManagerEnabled = didConfirmFocusManagerEnabled
        this.didConfirmInputEventPipelineEnabled = didConfirmInputEventPipelineEnabled
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

func cjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshMaterialized(): Bool {
    return true
}

func cjguiInternalBuildRendererStage630FocusValidationHostInputResultSemanticRefreshPlan(
    resultSurface: CjguiInternalRendererStage629FocusValidationHostInputResultSurfaceReadiness): CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshPlan {
    let stage629Ready = resultSurface.didConfirmStage629FocusValidationHostInputResultSurfaceReady && resultSurface
        .didConfirmStage630FocusValidationHostInputResultSemanticRefreshPrepared
    let surfacesReady = resultSurface.didConfirmValidationErrorResultSurfaceMaterialized && resultSurface
        .didConfirmFocusMovementResultSurfacePreviewMaterialized && resultSurface
        .didConfirmInputFeedbackResultSurfaceDisplayMaterialized && resultSurface
        .didConfirmSemanticDiffResultSurfaceRefreshMaterialized && resultSurface
        .didConfirmChatComposerFocusValidationResultSurfaceMaterialized
    let semanticRefreshReady = stage629Ready && surfacesReady &&
        cjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshMaterialized()
    return CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshPlan(
        stage629Ready,
        surfacesReady,
        semanticRefreshReady,
        semanticRefreshReady,
        semanticRefreshReady,
        semanticRefreshReady,
        semanticRefreshReady,
        semanticRefreshReady,
        semanticRefreshReady,
        semanticRefreshReady,
        semanticRefreshReady && resultSurface.didConfirmResultSurfaceBoundToStage628RuntimeContract,
        semanticRefreshReady,
        resultSurface.didConfirmRendererSubmissionBlocked,
        resultSurface.didConfirmRendererStateWriteBlocked,
        resultSurface.didConfirmRuntimeStateWriteBlocked
    )
}

func cjguiInternalBuildRendererStage630FocusValidationHostInputResultSemanticRefreshFacts(
    resultSurface: CjguiInternalRendererStage629FocusValidationHostInputResultSurfaceReadiness,
    semanticRefreshPlan: CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshPlan
): CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshFacts {
    return CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshFacts(
        semanticRefreshPlan,
        resultSurface.didConfirmOwnerAcceptanceRequired,
        resultSurface.didConfirmOwnerAcceptanceGranted == false,
        resultSurface.didConfirmProductionRenderTruth == false,
        resultSurface.didConfirmBackendReadyTruth == false,
        resultSurface.didConfirmPublicComponentApiAdded == false,
        resultSurface.didConfirmLayoutEngineEnabled == false,
        resultSurface.didConfirmStyleResolverEnabled == false,
        resultSurface.didConfirmFocusManagerEnabled == false,
        resultSurface.didConfirmInputEventPipelineEnabled == false,
        resultSurface.didConfirmInputEventPipelineExecution == false,
        resultSurface.didConfirmActionDispatch == false,
        resultSurface.didConfirmStateUpdateCommitted == false,
        resultSurface.didConfirmVisibilityPublicationAdmitted == false,
        resultSurface.didConfirmVisibilityPublished == false,
        resultSurface.didConfirmNativeBridgeExpansionBlocked
    )
}

func cjguiInternalBuildRendererStage630FocusValidationHostInputResultSemanticRefreshReadiness(
    resultSurface: CjguiInternalRendererStage629FocusValidationHostInputResultSurfaceReadiness,
    semanticRefreshPlan: CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshPlan,
    semanticRefreshFacts: CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshFacts
): CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshReadiness {
    let semanticRefreshReady = semanticRefreshPlan.didConsumeStage629FocusValidationHostInputResultSurface && semanticRefreshPlan
        .didConsumeResultSurfaceRefreshes && semanticRefreshPlan.didMaterializeSharedResultSurfaceSemanticDiffRefresh && semanticRefreshPlan
        .didMaterializeValidationErrorSemanticExplainLedger && semanticRefreshPlan
        .didMaterializeFocusMovementSemanticExplainLedger && semanticRefreshPlan
        .didMaterializeInputFeedbackSemanticExplainLedger && semanticRefreshPlan
        .didMaterializeChatComposerResultSemanticRefreshReceipt && semanticRefreshPlan
        .didBindSemanticRefreshToStage629ResultSurfaces && semanticRefreshPlan
        .didPrepareStage631FocusValidationResultSurfaceHostInspection
    let stopLineReady = semanticRefreshFacts.didKeepOwnerAcceptanceRequired && semanticRefreshFacts
        .didKeepOwnerAcceptanceNotGranted && semanticRefreshFacts.didKeepProductionRenderTruthBlocked && semanticRefreshFacts
        .didKeepBackendReadyTruthBlocked && semanticRefreshFacts.didKeepPublicComponentApiBlocked && semanticRefreshFacts
        .didKeepLayoutEngineBlocked && semanticRefreshFacts.didKeepStyleResolverBlocked && semanticRefreshFacts
        .didKeepFocusManagerBlocked && semanticRefreshFacts.didKeepInputEventPipelineBlocked && semanticRefreshFacts
        .didKeepInputEventPipelineExecutionBlocked && semanticRefreshFacts.didKeepActionDispatchBlocked && semanticRefreshFacts
        .didKeepStateUpdateCommittedBlocked && semanticRefreshFacts.didKeepVisibilityPublicationAdmittedBlocked && semanticRefreshFacts
        .didKeepVisibilityPublishedBlocked && semanticRefreshPlan.didKeepRendererSubmissionBlocked && semanticRefreshPlan
        .didKeepRendererStateWriteBlocked && semanticRefreshPlan.didKeepRuntimeStateWriteBlocked && semanticRefreshFacts
        .didKeepNativeBridgeExpansionBlocked
    return CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshReadiness(
        resultSurface,
        semanticRefreshPlan,
        semanticRefreshFacts,
        semanticRefreshReady && stopLineReady,
        semanticRefreshPlan.didConsumeStage629FocusValidationHostInputResultSurface,
        resultSurface.didConfirmStage628SharedFocusValidationHostInputRuntimeContractConsumed,
        semanticRefreshPlan.didConsumeResultSurfaceRefreshes,
        semanticRefreshPlan.didMaterializeSharedResultSurfaceSemanticDiffRefresh,
        semanticRefreshPlan.didMaterializeValidationErrorSemanticExplainLedger,
        semanticRefreshPlan.didMaterializeFocusMovementSemanticExplainLedger,
        semanticRefreshPlan.didMaterializeInputFeedbackSemanticExplainLedger,
        semanticRefreshPlan.didMaterializeTodoResultSemanticRefreshReceipt,
        semanticRefreshPlan.didMaterializeSettingsResultSemanticRefreshReceipt,
        semanticRefreshPlan.didMaterializeAiGeneratedSettingsResultSemanticRefreshReceipt,
        semanticRefreshPlan.didMaterializeChatComposerResultSemanticRefreshReceipt,
        semanticRefreshPlan.didBindSemanticRefreshToStage629ResultSurfaces,
        semanticRefreshPlan.didPrepareStage631FocusValidationResultSurfaceHostInspection,
        semanticRefreshFacts.didKeepOwnerAcceptanceRequired,
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
        false,
        false,
        semanticRefreshPlan.didKeepRendererSubmissionBlocked,
        semanticRefreshPlan.didKeepRendererStateWriteBlocked,
        semanticRefreshPlan.didKeepRuntimeStateWriteBlocked,
        semanticRefreshFacts.didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage630FocusValidationHostInputResultSemanticRefreshDraft(): CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshReadiness {
    let resultSurface = cjguiInternalExecuteDefaultRendererStage629FocusValidationHostInputResultSurfaceDraft()
    let semanticRefreshPlan = cjguiInternalBuildRendererStage630FocusValidationHostInputResultSemanticRefreshPlan(
        resultSurface)
    let semanticRefreshFacts = cjguiInternalBuildRendererStage630FocusValidationHostInputResultSemanticRefreshFacts(
        resultSurface,
        semanticRefreshPlan
    )
    return cjguiInternalBuildRendererStage630FocusValidationHostInputResultSemanticRefreshReadiness(
        resultSurface,
        semanticRefreshPlan,
        semanticRefreshFacts
    )
}
