// 中文维护注释：本文件是 stage437 transaction visibility RenderCommand transaction admission owner。
// Owner: 消费 stage436 transaction dry-run，生成 Todo/settings/AI-generated settings 的 visibility admission candidate。
// Truth: 只证明 transaction preview 可进入 owner-local admission，不发布 visibility、不提交 state。
// Stop-line: 不授予 acceptance、不写 renderer/runtime state、不实现 backend、不扩 public API / native bridge。
// Same-shape Boundary Brake: 本轮消费 transaction dry-run 进入 admission，不重复 transaction 包装。
package cjgui

struct CjguiInternalRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionPlan {
    let didConsumeStage436TransactionVisibilityRenderCommandGateTransactionDryRun: Bool
    let didConsumeTransactionVisibilityRenderCommandTransactionDryRun: Bool
    let didConsumeAcceptedGateToPendingTransactionVisibilityRenderCommandTransaction: Bool
    let didConsumeBlockedGateToRollbackTransactionVisibilityRenderCommandTransaction: Bool
    let didMaterializeTransactionVisibilityRenderCommandTransactionAdmission: Bool
    let didMaterializeTodoTransactionVisibilityRenderCommandTransactionAdmission: Bool
    let didMaterializeSettingsTransactionVisibilityRenderCommandTransactionAdmission: Bool
    let didMaterializeAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionAdmission: Bool
    let didPrepareAcceptedTransactionVisibilityRenderCommandTransactionAdmissionCandidate: Bool
    let didPrepareBlockedTransactionVisibilityRenderCommandTransactionDenialCandidate: Bool
    let didBindTransactionVisibilityAdmissionToStage436TransactionDryRun: Bool
    let didBindTransactionVisibilityAdmissionToStage435Gate: Bool
    let didKeepTransactionVisibilityRenderCommandTransactionAdmissionOwnerLocal: Bool
    let didKeepTransactionVisibilityRenderCommandTransactionAdmissionPreviewOnly: Bool
    let didPrepareStage438TransactionVisibilityCommandPlan: Bool
    let didKeepInputEventPipelineBlocked: Bool
    let didKeepInputEventPipelineExecutionBlocked: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepVisibilityPublishedBlocked: Bool
    let didKeepBackendImplementationBlocked: Bool
    let didKeepPlatformCommandBufferBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool

    init(
        didConsumeStage436TransactionVisibilityRenderCommandGateTransactionDryRun: Bool,
        didConsumeTransactionVisibilityRenderCommandTransactionDryRun: Bool,
        didConsumeAcceptedGateToPendingTransactionVisibilityRenderCommandTransaction: Bool,
        didConsumeBlockedGateToRollbackTransactionVisibilityRenderCommandTransaction: Bool,
        didMaterializeTransactionVisibilityRenderCommandTransactionAdmission: Bool,
        didMaterializeTodoTransactionVisibilityRenderCommandTransactionAdmission: Bool,
        didMaterializeSettingsTransactionVisibilityRenderCommandTransactionAdmission: Bool,
        didMaterializeAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionAdmission: Bool,
        didPrepareAcceptedTransactionVisibilityRenderCommandTransactionAdmissionCandidate: Bool,
        didPrepareBlockedTransactionVisibilityRenderCommandTransactionDenialCandidate: Bool,
        didBindTransactionVisibilityAdmissionToStage436TransactionDryRun: Bool,
        didBindTransactionVisibilityAdmissionToStage435Gate: Bool,
        didKeepTransactionVisibilityRenderCommandTransactionAdmissionOwnerLocal: Bool,
        didKeepTransactionVisibilityRenderCommandTransactionAdmissionPreviewOnly: Bool,
        didPrepareStage438TransactionVisibilityCommandPlan: Bool,
        didKeepInputEventPipelineBlocked: Bool,
        didKeepInputEventPipelineExecutionBlocked: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepVisibilityPublishedBlocked: Bool,
        didKeepBackendImplementationBlocked: Bool,
        didKeepPlatformCommandBufferBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool
    ) {
        this.didConsumeStage436TransactionVisibilityRenderCommandGateTransactionDryRun = didConsumeStage436TransactionVisibilityRenderCommandGateTransactionDryRun
        this.didConsumeTransactionVisibilityRenderCommandTransactionDryRun = didConsumeTransactionVisibilityRenderCommandTransactionDryRun
        this.didConsumeAcceptedGateToPendingTransactionVisibilityRenderCommandTransaction = didConsumeAcceptedGateToPendingTransactionVisibilityRenderCommandTransaction
        this.didConsumeBlockedGateToRollbackTransactionVisibilityRenderCommandTransaction = didConsumeBlockedGateToRollbackTransactionVisibilityRenderCommandTransaction
        this.didMaterializeTransactionVisibilityRenderCommandTransactionAdmission = didMaterializeTransactionVisibilityRenderCommandTransactionAdmission
        this.didMaterializeTodoTransactionVisibilityRenderCommandTransactionAdmission = didMaterializeTodoTransactionVisibilityRenderCommandTransactionAdmission
        this.didMaterializeSettingsTransactionVisibilityRenderCommandTransactionAdmission = didMaterializeSettingsTransactionVisibilityRenderCommandTransactionAdmission
        this.didMaterializeAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionAdmission = didMaterializeAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionAdmission
        this.didPrepareAcceptedTransactionVisibilityRenderCommandTransactionAdmissionCandidate = didPrepareAcceptedTransactionVisibilityRenderCommandTransactionAdmissionCandidate
        this.didPrepareBlockedTransactionVisibilityRenderCommandTransactionDenialCandidate = didPrepareBlockedTransactionVisibilityRenderCommandTransactionDenialCandidate
        this.didBindTransactionVisibilityAdmissionToStage436TransactionDryRun = didBindTransactionVisibilityAdmissionToStage436TransactionDryRun
        this.didBindTransactionVisibilityAdmissionToStage435Gate = didBindTransactionVisibilityAdmissionToStage435Gate
        this.didKeepTransactionVisibilityRenderCommandTransactionAdmissionOwnerLocal = didKeepTransactionVisibilityRenderCommandTransactionAdmissionOwnerLocal
        this.didKeepTransactionVisibilityRenderCommandTransactionAdmissionPreviewOnly = didKeepTransactionVisibilityRenderCommandTransactionAdmissionPreviewOnly
        this.didPrepareStage438TransactionVisibilityCommandPlan = didPrepareStage438TransactionVisibilityCommandPlan
        this.didKeepInputEventPipelineBlocked = didKeepInputEventPipelineBlocked
        this.didKeepInputEventPipelineExecutionBlocked = didKeepInputEventPipelineExecutionBlocked
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepStateUpdateCommittedBlocked = didKeepStateUpdateCommittedBlocked
        this.didKeepVisibilityPublishedBlocked = didKeepVisibilityPublishedBlocked
        this.didKeepBackendImplementationBlocked = didKeepBackendImplementationBlocked
        this.didKeepPlatformCommandBufferBlocked = didKeepPlatformCommandBufferBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
    }
}

struct CjguiInternalRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionFacts {
    let didConsumeStage436TransactionVisibilityRenderCommandGateTransactionDryRun: Bool
    let didConfirmStage435TransactionVisibilityRenderCommandRefreshOwnerAcceptanceGateConsumedTransitively: Bool
    let didConfirmStage434TransactionVisibilityRenderCommandRefreshDemoSurfaceDryRunConsumedTransitively: Bool
    let didConfirmStage433TransactionVisibilityStateUpdateRenderCommandRefreshConsumedTransitively: Bool
    let didConfirmStage432TransactionVisibilityActionIntentStateUpdateDryRunConsumedTransitively: Bool
    let didConfirmStage431TransactionVisibilityPreviewInputEventActionAdapterConsumedTransitively: Bool
    let didConfirmStage430TransactionVisibilityPreviewDiffRenderCommandRefreshConsumedTransitively: Bool
    let didConfirmStage429DemoSurfaceTransactionVisibilityPreviewRefreshConsumedTransitively: Bool
    let didConfirmStage428RenderCommandTransactionVisibilityCommandPlanConsumedTransitively: Bool
    let didConfirmRouteConvergenceNotNeeded: Bool
    let didConfirmStage381ConvergenceExitAlreadyMaterialized: Bool
    let didConsumeTransactionVisibilityRenderCommandTransactionDryRun: Bool
    let didConsumeTodoTransactionVisibilityRenderCommandTransactionDryRun: Bool
    let didConsumeSettingsTransactionVisibilityRenderCommandTransactionDryRun: Bool
    let didConsumeAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionDryRun: Bool
    let didConsumeAcceptedGateToPendingTransactionVisibilityRenderCommandTransaction: Bool
    let didConsumeBlockedGateToRollbackTransactionVisibilityRenderCommandTransaction: Bool
    let didMaterializeTransactionVisibilityRenderCommandTransactionAdmission: Bool
    let didMaterializeTodoTransactionVisibilityRenderCommandTransactionAdmission: Bool
    let didMaterializeSettingsTransactionVisibilityRenderCommandTransactionAdmission: Bool
    let didMaterializeAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionAdmission: Bool
    let didPrepareAcceptedTransactionVisibilityRenderCommandTransactionAdmissionCandidate: Bool
    let didPrepareBlockedTransactionVisibilityRenderCommandTransactionDenialCandidate: Bool
    let didBindTransactionVisibilityAdmissionToStage436TransactionDryRun: Bool
    let didBindTransactionVisibilityAdmissionToStage435Gate: Bool
    let didKeepTransactionVisibilityRenderCommandTransactionAdmissionOwnerLocal: Bool
    let didKeepTransactionVisibilityRenderCommandTransactionAdmissionPreviewOnly: Bool
    let didPrepareStage438TransactionVisibilityCommandPlan: Bool
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didKeepProductionRenderTruthBlocked: Bool
    let didKeepBackendReadyTruthBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepLayoutEngineBlocked: Bool
    let didKeepInputEventPipelineBlocked: Bool
    let didKeepInputEventPipelineExecutionBlocked: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepVisibilityPublicationBlocked: Bool
    let didKeepVisibilityPublishedBlocked: Bool
    let didKeepBackendImplementationBlocked: Bool
    let didKeepPlatformCommandBufferBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepNativeBridgeExpansionBlocked: Bool

    init(
        didConsumeStage436TransactionVisibilityRenderCommandGateTransactionDryRun: Bool,
        didConfirmStage435TransactionVisibilityRenderCommandRefreshOwnerAcceptanceGateConsumedTransitively: Bool,
        didConfirmStage434TransactionVisibilityRenderCommandRefreshDemoSurfaceDryRunConsumedTransitively: Bool,
        didConfirmStage433TransactionVisibilityStateUpdateRenderCommandRefreshConsumedTransitively: Bool,
        didConfirmStage432TransactionVisibilityActionIntentStateUpdateDryRunConsumedTransitively: Bool,
        didConfirmStage431TransactionVisibilityPreviewInputEventActionAdapterConsumedTransitively: Bool,
        didConfirmStage430TransactionVisibilityPreviewDiffRenderCommandRefreshConsumedTransitively: Bool,
        didConfirmStage429DemoSurfaceTransactionVisibilityPreviewRefreshConsumedTransitively: Bool,
        didConfirmStage428RenderCommandTransactionVisibilityCommandPlanConsumedTransitively: Bool,
        didConfirmRouteConvergenceNotNeeded: Bool,
        didConfirmStage381ConvergenceExitAlreadyMaterialized: Bool,
        didConsumeTransactionVisibilityRenderCommandTransactionDryRun: Bool,
        didConsumeTodoTransactionVisibilityRenderCommandTransactionDryRun: Bool,
        didConsumeSettingsTransactionVisibilityRenderCommandTransactionDryRun: Bool,
        didConsumeAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionDryRun: Bool,
        didConsumeAcceptedGateToPendingTransactionVisibilityRenderCommandTransaction: Bool,
        didConsumeBlockedGateToRollbackTransactionVisibilityRenderCommandTransaction: Bool,
        didMaterializeTransactionVisibilityRenderCommandTransactionAdmission: Bool,
        didMaterializeTodoTransactionVisibilityRenderCommandTransactionAdmission: Bool,
        didMaterializeSettingsTransactionVisibilityRenderCommandTransactionAdmission: Bool,
        didMaterializeAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionAdmission: Bool,
        didPrepareAcceptedTransactionVisibilityRenderCommandTransactionAdmissionCandidate: Bool,
        didPrepareBlockedTransactionVisibilityRenderCommandTransactionDenialCandidate: Bool,
        didBindTransactionVisibilityAdmissionToStage436TransactionDryRun: Bool,
        didBindTransactionVisibilityAdmissionToStage435Gate: Bool,
        didKeepTransactionVisibilityRenderCommandTransactionAdmissionOwnerLocal: Bool,
        didKeepTransactionVisibilityRenderCommandTransactionAdmissionPreviewOnly: Bool,
        didPrepareStage438TransactionVisibilityCommandPlan: Bool,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didKeepProductionRenderTruthBlocked: Bool,
        didKeepBackendReadyTruthBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepLayoutEngineBlocked: Bool,
        didKeepInputEventPipelineBlocked: Bool,
        didKeepInputEventPipelineExecutionBlocked: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepVisibilityPublicationBlocked: Bool,
        didKeepVisibilityPublishedBlocked: Bool,
        didKeepBackendImplementationBlocked: Bool,
        didKeepPlatformCommandBufferBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepNativeBridgeExpansionBlocked: Bool
    ) {
        this.didConsumeStage436TransactionVisibilityRenderCommandGateTransactionDryRun = didConsumeStage436TransactionVisibilityRenderCommandGateTransactionDryRun
        this.didConfirmStage435TransactionVisibilityRenderCommandRefreshOwnerAcceptanceGateConsumedTransitively = didConfirmStage435TransactionVisibilityRenderCommandRefreshOwnerAcceptanceGateConsumedTransitively
        this.didConfirmStage434TransactionVisibilityRenderCommandRefreshDemoSurfaceDryRunConsumedTransitively = didConfirmStage434TransactionVisibilityRenderCommandRefreshDemoSurfaceDryRunConsumedTransitively
        this.didConfirmStage433TransactionVisibilityStateUpdateRenderCommandRefreshConsumedTransitively = didConfirmStage433TransactionVisibilityStateUpdateRenderCommandRefreshConsumedTransitively
        this.didConfirmStage432TransactionVisibilityActionIntentStateUpdateDryRunConsumedTransitively = didConfirmStage432TransactionVisibilityActionIntentStateUpdateDryRunConsumedTransitively
        this.didConfirmStage431TransactionVisibilityPreviewInputEventActionAdapterConsumedTransitively = didConfirmStage431TransactionVisibilityPreviewInputEventActionAdapterConsumedTransitively
        this.didConfirmStage430TransactionVisibilityPreviewDiffRenderCommandRefreshConsumedTransitively = didConfirmStage430TransactionVisibilityPreviewDiffRenderCommandRefreshConsumedTransitively
        this.didConfirmStage429DemoSurfaceTransactionVisibilityPreviewRefreshConsumedTransitively = didConfirmStage429DemoSurfaceTransactionVisibilityPreviewRefreshConsumedTransitively
        this.didConfirmStage428RenderCommandTransactionVisibilityCommandPlanConsumedTransitively = didConfirmStage428RenderCommandTransactionVisibilityCommandPlanConsumedTransitively
        this.didConfirmRouteConvergenceNotNeeded = didConfirmRouteConvergenceNotNeeded
        this.didConfirmStage381ConvergenceExitAlreadyMaterialized = didConfirmStage381ConvergenceExitAlreadyMaterialized
        this.didConsumeTransactionVisibilityRenderCommandTransactionDryRun = didConsumeTransactionVisibilityRenderCommandTransactionDryRun
        this.didConsumeTodoTransactionVisibilityRenderCommandTransactionDryRun = didConsumeTodoTransactionVisibilityRenderCommandTransactionDryRun
        this.didConsumeSettingsTransactionVisibilityRenderCommandTransactionDryRun = didConsumeSettingsTransactionVisibilityRenderCommandTransactionDryRun
        this.didConsumeAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionDryRun = didConsumeAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionDryRun
        this.didConsumeAcceptedGateToPendingTransactionVisibilityRenderCommandTransaction = didConsumeAcceptedGateToPendingTransactionVisibilityRenderCommandTransaction
        this.didConsumeBlockedGateToRollbackTransactionVisibilityRenderCommandTransaction = didConsumeBlockedGateToRollbackTransactionVisibilityRenderCommandTransaction
        this.didMaterializeTransactionVisibilityRenderCommandTransactionAdmission = didMaterializeTransactionVisibilityRenderCommandTransactionAdmission
        this.didMaterializeTodoTransactionVisibilityRenderCommandTransactionAdmission = didMaterializeTodoTransactionVisibilityRenderCommandTransactionAdmission
        this.didMaterializeSettingsTransactionVisibilityRenderCommandTransactionAdmission = didMaterializeSettingsTransactionVisibilityRenderCommandTransactionAdmission
        this.didMaterializeAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionAdmission = didMaterializeAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionAdmission
        this.didPrepareAcceptedTransactionVisibilityRenderCommandTransactionAdmissionCandidate = didPrepareAcceptedTransactionVisibilityRenderCommandTransactionAdmissionCandidate
        this.didPrepareBlockedTransactionVisibilityRenderCommandTransactionDenialCandidate = didPrepareBlockedTransactionVisibilityRenderCommandTransactionDenialCandidate
        this.didBindTransactionVisibilityAdmissionToStage436TransactionDryRun = didBindTransactionVisibilityAdmissionToStage436TransactionDryRun
        this.didBindTransactionVisibilityAdmissionToStage435Gate = didBindTransactionVisibilityAdmissionToStage435Gate
        this.didKeepTransactionVisibilityRenderCommandTransactionAdmissionOwnerLocal = didKeepTransactionVisibilityRenderCommandTransactionAdmissionOwnerLocal
        this.didKeepTransactionVisibilityRenderCommandTransactionAdmissionPreviewOnly = didKeepTransactionVisibilityRenderCommandTransactionAdmissionPreviewOnly
        this.didPrepareStage438TransactionVisibilityCommandPlan = didPrepareStage438TransactionVisibilityCommandPlan
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didKeepOwnerAcceptanceNotGranted = didKeepOwnerAcceptanceNotGranted
        this.didKeepProductionRenderTruthBlocked = didKeepProductionRenderTruthBlocked
        this.didKeepBackendReadyTruthBlocked = didKeepBackendReadyTruthBlocked
        this.didKeepPublicComponentApiBlocked = didKeepPublicComponentApiBlocked
        this.didKeepLayoutEngineBlocked = didKeepLayoutEngineBlocked
        this.didKeepInputEventPipelineBlocked = didKeepInputEventPipelineBlocked
        this.didKeepInputEventPipelineExecutionBlocked = didKeepInputEventPipelineExecutionBlocked
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepStateUpdateCommittedBlocked = didKeepStateUpdateCommittedBlocked
        this.didKeepVisibilityPublicationBlocked = didKeepVisibilityPublicationBlocked
        this.didKeepVisibilityPublishedBlocked = didKeepVisibilityPublishedBlocked
        this.didKeepBackendImplementationBlocked = didKeepBackendImplementationBlocked
        this.didKeepPlatformCommandBufferBlocked = didKeepPlatformCommandBufferBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didKeepNativeBridgeExpansionBlocked = didKeepNativeBridgeExpansionBlocked
    }
}

struct CjguiInternalRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionReadiness {
    let transactionDryRun: CjguiInternalRendererStage436TransactionVisibilityRenderCommandGateTransactionDryRunReadiness
    let admissionPlan: CjguiInternalRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionPlan
    let admissionFacts: CjguiInternalRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionFacts
    let didPrepareStage437TransactionVisibilityRenderCommandTransactionAdmissionReadiness: Bool
    let didConfirmStage437TransactionVisibilityRenderCommandTransactionAdmissionReady: Bool
    let didConfirmStage436TransactionVisibilityRenderCommandGateTransactionDryRunConsumed: Bool
    let didConfirmTransactionVisibilityRenderCommandTransactionDryRunConsumed: Bool
    let didConfirmTodoTransactionVisibilityRenderCommandTransactionDryRunConsumed: Bool
    let didConfirmSettingsTransactionVisibilityRenderCommandTransactionDryRunConsumed: Bool
    let didConfirmAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionDryRunConsumed: Bool
    let didConfirmAcceptedGateToPendingTransactionVisibilityRenderCommandTransactionConsumed: Bool
    let didConfirmBlockedGateToRollbackTransactionVisibilityRenderCommandTransactionConsumed: Bool
    let didConfirmTransactionVisibilityRenderCommandTransactionAdmissionMaterialized: Bool
    let didConfirmTodoTransactionVisibilityRenderCommandTransactionAdmissionMaterialized: Bool
    let didConfirmSettingsTransactionVisibilityRenderCommandTransactionAdmissionMaterialized: Bool
    let didConfirmAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionAdmissionMaterialized: Bool
    let didConfirmAcceptedTransactionVisibilityRenderCommandTransactionAdmissionCandidatePrepared: Bool
    let didConfirmBlockedTransactionVisibilityRenderCommandTransactionDenialCandidatePrepared: Bool
    let didConfirmTransactionVisibilityAdmissionBoundToStage436TransactionDryRun: Bool
    let didConfirmTransactionVisibilityAdmissionBoundToStage435Gate: Bool
    let didConfirmTransactionVisibilityRenderCommandTransactionAdmissionOwnerLocal: Bool
    let didConfirmTransactionVisibilityRenderCommandTransactionAdmissionPreviewOnly: Bool
    let didConfirmStage438TransactionVisibilityCommandPlanPrepared: Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmProductionRenderTruth: Bool
    let didConfirmBackendReadyTruth: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmLayoutEngineEnabled: Bool
    let didConfirmInputEventPipelineEnabled: Bool
    let didConfirmInputEventPipelineExecution: Bool
    let didConfirmActionDispatch: Bool
    let didConfirmStateUpdateCommitted: Bool
    let didConfirmVisibilityPublicationAdmitted: Bool
    let didConfirmVisibilityPublished: Bool
    let didConfirmBackendImplementationBlocked: Bool
    let didConfirmPlatformCommandBufferBlocked: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmNativeBridgeExpansionBlocked: Bool

    init(
        transactionDryRun: CjguiInternalRendererStage436TransactionVisibilityRenderCommandGateTransactionDryRunReadiness,
        admissionPlan: CjguiInternalRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionPlan,
        admissionFacts: CjguiInternalRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionFacts,
        didPrepareStage437TransactionVisibilityRenderCommandTransactionAdmissionReadiness: Bool,
        didConfirmStage437TransactionVisibilityRenderCommandTransactionAdmissionReady: Bool,
        didConfirmStage436TransactionVisibilityRenderCommandGateTransactionDryRunConsumed: Bool,
        didConfirmTransactionVisibilityRenderCommandTransactionDryRunConsumed: Bool,
        didConfirmTodoTransactionVisibilityRenderCommandTransactionDryRunConsumed: Bool,
        didConfirmSettingsTransactionVisibilityRenderCommandTransactionDryRunConsumed: Bool,
        didConfirmAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionDryRunConsumed: Bool,
        didConfirmAcceptedGateToPendingTransactionVisibilityRenderCommandTransactionConsumed: Bool,
        didConfirmBlockedGateToRollbackTransactionVisibilityRenderCommandTransactionConsumed: Bool,
        didConfirmTransactionVisibilityRenderCommandTransactionAdmissionMaterialized: Bool,
        didConfirmTodoTransactionVisibilityRenderCommandTransactionAdmissionMaterialized: Bool,
        didConfirmSettingsTransactionVisibilityRenderCommandTransactionAdmissionMaterialized: Bool,
        didConfirmAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionAdmissionMaterialized: Bool,
        didConfirmAcceptedTransactionVisibilityRenderCommandTransactionAdmissionCandidatePrepared: Bool,
        didConfirmBlockedTransactionVisibilityRenderCommandTransactionDenialCandidatePrepared: Bool,
        didConfirmTransactionVisibilityAdmissionBoundToStage436TransactionDryRun: Bool,
        didConfirmTransactionVisibilityAdmissionBoundToStage435Gate: Bool,
        didConfirmTransactionVisibilityRenderCommandTransactionAdmissionOwnerLocal: Bool,
        didConfirmTransactionVisibilityRenderCommandTransactionAdmissionPreviewOnly: Bool,
        didConfirmStage438TransactionVisibilityCommandPlanPrepared: Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmProductionRenderTruth: Bool,
        didConfirmBackendReadyTruth: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmLayoutEngineEnabled: Bool,
        didConfirmInputEventPipelineEnabled: Bool,
        didConfirmInputEventPipelineExecution: Bool,
        didConfirmActionDispatch: Bool,
        didConfirmStateUpdateCommitted: Bool,
        didConfirmVisibilityPublicationAdmitted: Bool,
        didConfirmVisibilityPublished: Bool,
        didConfirmBackendImplementationBlocked: Bool,
        didConfirmPlatformCommandBufferBlocked: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmNativeBridgeExpansionBlocked: Bool
    ) {
        this.transactionDryRun = transactionDryRun
        this.admissionPlan = admissionPlan
        this.admissionFacts = admissionFacts
        this.didPrepareStage437TransactionVisibilityRenderCommandTransactionAdmissionReadiness = didPrepareStage437TransactionVisibilityRenderCommandTransactionAdmissionReadiness
        this.didConfirmStage437TransactionVisibilityRenderCommandTransactionAdmissionReady = didConfirmStage437TransactionVisibilityRenderCommandTransactionAdmissionReady
        this.didConfirmStage436TransactionVisibilityRenderCommandGateTransactionDryRunConsumed = didConfirmStage436TransactionVisibilityRenderCommandGateTransactionDryRunConsumed
        this.didConfirmTransactionVisibilityRenderCommandTransactionDryRunConsumed = didConfirmTransactionVisibilityRenderCommandTransactionDryRunConsumed
        this.didConfirmTodoTransactionVisibilityRenderCommandTransactionDryRunConsumed = didConfirmTodoTransactionVisibilityRenderCommandTransactionDryRunConsumed
        this.didConfirmSettingsTransactionVisibilityRenderCommandTransactionDryRunConsumed = didConfirmSettingsTransactionVisibilityRenderCommandTransactionDryRunConsumed
        this.didConfirmAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionDryRunConsumed = didConfirmAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionDryRunConsumed
        this.didConfirmAcceptedGateToPendingTransactionVisibilityRenderCommandTransactionConsumed = didConfirmAcceptedGateToPendingTransactionVisibilityRenderCommandTransactionConsumed
        this.didConfirmBlockedGateToRollbackTransactionVisibilityRenderCommandTransactionConsumed = didConfirmBlockedGateToRollbackTransactionVisibilityRenderCommandTransactionConsumed
        this.didConfirmTransactionVisibilityRenderCommandTransactionAdmissionMaterialized = didConfirmTransactionVisibilityRenderCommandTransactionAdmissionMaterialized
        this.didConfirmTodoTransactionVisibilityRenderCommandTransactionAdmissionMaterialized = didConfirmTodoTransactionVisibilityRenderCommandTransactionAdmissionMaterialized
        this.didConfirmSettingsTransactionVisibilityRenderCommandTransactionAdmissionMaterialized = didConfirmSettingsTransactionVisibilityRenderCommandTransactionAdmissionMaterialized
        this.didConfirmAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionAdmissionMaterialized = didConfirmAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionAdmissionMaterialized
        this.didConfirmAcceptedTransactionVisibilityRenderCommandTransactionAdmissionCandidatePrepared = didConfirmAcceptedTransactionVisibilityRenderCommandTransactionAdmissionCandidatePrepared
        this.didConfirmBlockedTransactionVisibilityRenderCommandTransactionDenialCandidatePrepared = didConfirmBlockedTransactionVisibilityRenderCommandTransactionDenialCandidatePrepared
        this.didConfirmTransactionVisibilityAdmissionBoundToStage436TransactionDryRun = didConfirmTransactionVisibilityAdmissionBoundToStage436TransactionDryRun
        this.didConfirmTransactionVisibilityAdmissionBoundToStage435Gate = didConfirmTransactionVisibilityAdmissionBoundToStage435Gate
        this.didConfirmTransactionVisibilityRenderCommandTransactionAdmissionOwnerLocal = didConfirmTransactionVisibilityRenderCommandTransactionAdmissionOwnerLocal
        this.didConfirmTransactionVisibilityRenderCommandTransactionAdmissionPreviewOnly = didConfirmTransactionVisibilityRenderCommandTransactionAdmissionPreviewOnly
        this.didConfirmStage438TransactionVisibilityCommandPlanPrepared = didConfirmStage438TransactionVisibilityCommandPlanPrepared
        this.didConfirmOwnerAcceptanceRequired = didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted = didConfirmOwnerAcceptanceGranted
        this.didConfirmProductionRenderTruth = didConfirmProductionRenderTruth
        this.didConfirmBackendReadyTruth = didConfirmBackendReadyTruth
        this.didConfirmPublicComponentApiAdded = didConfirmPublicComponentApiAdded
        this.didConfirmLayoutEngineEnabled = didConfirmLayoutEngineEnabled
        this.didConfirmInputEventPipelineEnabled = didConfirmInputEventPipelineEnabled
        this.didConfirmInputEventPipelineExecution = didConfirmInputEventPipelineExecution
        this.didConfirmActionDispatch = didConfirmActionDispatch
        this.didConfirmStateUpdateCommitted = didConfirmStateUpdateCommitted
        this.didConfirmVisibilityPublicationAdmitted = didConfirmVisibilityPublicationAdmitted
        this.didConfirmVisibilityPublished = didConfirmVisibilityPublished
        this.didConfirmBackendImplementationBlocked = didConfirmBackendImplementationBlocked
        this.didConfirmPlatformCommandBufferBlocked = didConfirmPlatformCommandBufferBlocked
        this.didConfirmRendererSubmissionBlocked = didConfirmRendererSubmissionBlocked
        this.didConfirmRendererStateWriteBlocked = didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked = didConfirmRuntimeStateWriteBlocked
        this.didConfirmNativeBridgeExpansionBlocked = didConfirmNativeBridgeExpansionBlocked
    }
}

func cjguiInternalBuildRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionPlan(
    transactionDryRun: CjguiInternalRendererStage436TransactionVisibilityRenderCommandGateTransactionDryRunReadiness): CjguiInternalRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionPlan {
    let stage436Ready = transactionDryRun
        .didConfirmStage436TransactionVisibilityRenderCommandGateTransactionDryRunReady && transactionDryRun
        .didConfirmStage437TransactionVisibilityRenderCommandTransactionAdmissionPrepared
    let transactionReady = stage436Ready && transactionDryRun
        .didConfirmTransactionVisibilityRenderCommandTransactionDryRunMaterialized && transactionDryRun
        .didConfirmAcceptedGateToPendingTransactionVisibilityRenderCommandTransactionMapped && transactionDryRun
        .didConfirmBlockedGateToRollbackTransactionVisibilityRenderCommandTransactionMapped
    let perDemoReady = transactionReady && transactionDryRun
        .didConfirmTodoTransactionVisibilityRenderCommandTransactionDryRunMaterialized && transactionDryRun
        .didConfirmSettingsTransactionVisibilityRenderCommandTransactionDryRunMaterialized && transactionDryRun
        .didConfirmAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionDryRunMaterialized
    let admissionReady = perDemoReady && transactionDryRun.didConfirmOwnerAcceptanceRequired &&
        transactionDryRun.didConfirmOwnerAcceptanceGranted == false &&
        transactionDryRun.didConfirmStateUpdateCommitted == false && transactionDryRun.didConfirmVisibilityPublished ==
        false
    let stage438Ready = admissionReady && transactionDryRun.didConfirmRendererStateWriteBlocked && transactionDryRun
        .didConfirmRuntimeStateWriteBlocked

    return CjguiInternalRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionPlan(
        stage436Ready,
        transactionReady,
        transactionReady,
        transactionReady,
        admissionReady,
        admissionReady,
        admissionReady,
        admissionReady,
        admissionReady,
        admissionReady,
        admissionReady,
        admissionReady && transactionDryRun.didConfirmTransactionDryRunBoundToStage435Gate,
        admissionReady,
        admissionReady,
        stage438Ready,
        transactionDryRun.didConfirmInputEventPipelineEnabled == false,
        transactionDryRun.didConfirmInputEventPipelineExecution == false,
        transactionDryRun.didConfirmActionDispatch == false,
        transactionDryRun.didConfirmStateUpdateCommitted == false,
        transactionDryRun.didConfirmVisibilityPublished == false,
        transactionDryRun.didConfirmBackendImplementationBlocked,
        transactionDryRun.didConfirmPlatformCommandBufferBlocked,
        transactionDryRun.didConfirmRendererSubmissionBlocked,
        transactionDryRun.didConfirmRendererStateWriteBlocked,
        transactionDryRun.didConfirmRuntimeStateWriteBlocked
    )
}

func cjguiInternalBuildRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionFacts(
    transactionDryRun: CjguiInternalRendererStage436TransactionVisibilityRenderCommandGateTransactionDryRunReadiness,
    admissionPlan: CjguiInternalRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionPlan
): CjguiInternalRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionFacts {
    return CjguiInternalRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionFacts(
        admissionPlan.didConsumeStage436TransactionVisibilityRenderCommandGateTransactionDryRun,
        transactionDryRun.didConfirmStage435TransactionVisibilityRenderCommandRefreshOwnerAcceptanceGateConsumed,
        transactionDryRun
            .transactionFacts
            .didConfirmStage434TransactionVisibilityRenderCommandRefreshDemoSurfaceDryRunConsumedTransitively,
        transactionDryRun
            .transactionFacts
            .didConfirmStage433TransactionVisibilityStateUpdateRenderCommandRefreshConsumedTransitively,
        transactionDryRun
            .transactionFacts
            .didConfirmStage432TransactionVisibilityActionIntentStateUpdateDryRunConsumedTransitively,
        transactionDryRun
            .transactionFacts
            .didConfirmStage431TransactionVisibilityPreviewInputEventActionAdapterConsumedTransitively,
        transactionDryRun
            .transactionFacts
            .didConfirmStage430TransactionVisibilityPreviewDiffRenderCommandRefreshConsumedTransitively,
        transactionDryRun
            .transactionFacts
            .didConfirmStage429DemoSurfaceTransactionVisibilityPreviewRefreshConsumedTransitively,
        transactionDryRun
            .transactionFacts
            .didConfirmStage428RenderCommandTransactionVisibilityCommandPlanConsumedTransitively,
        transactionDryRun.transactionFacts.didConfirmRouteConvergenceNotNeeded,
        transactionDryRun.transactionFacts.didConfirmStage381ConvergenceExitAlreadyMaterialized,
        admissionPlan.didConsumeTransactionVisibilityRenderCommandTransactionDryRun,
        admissionPlan.didConsumeTransactionVisibilityRenderCommandTransactionDryRun && transactionDryRun
            .didConfirmTodoTransactionVisibilityRenderCommandTransactionDryRunMaterialized,
        admissionPlan.didConsumeTransactionVisibilityRenderCommandTransactionDryRun && transactionDryRun
            .didConfirmSettingsTransactionVisibilityRenderCommandTransactionDryRunMaterialized,
        admissionPlan.didConsumeTransactionVisibilityRenderCommandTransactionDryRun && transactionDryRun
            .didConfirmAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionDryRunMaterialized,
        admissionPlan.didConsumeAcceptedGateToPendingTransactionVisibilityRenderCommandTransaction,
        admissionPlan.didConsumeBlockedGateToRollbackTransactionVisibilityRenderCommandTransaction,
        admissionPlan.didMaterializeTransactionVisibilityRenderCommandTransactionAdmission,
        admissionPlan.didMaterializeTodoTransactionVisibilityRenderCommandTransactionAdmission,
        admissionPlan.didMaterializeSettingsTransactionVisibilityRenderCommandTransactionAdmission,
        admissionPlan.didMaterializeAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionAdmission,
        admissionPlan.didPrepareAcceptedTransactionVisibilityRenderCommandTransactionAdmissionCandidate,
        admissionPlan.didPrepareBlockedTransactionVisibilityRenderCommandTransactionDenialCandidate,
        admissionPlan.didBindTransactionVisibilityAdmissionToStage436TransactionDryRun,
        admissionPlan.didBindTransactionVisibilityAdmissionToStage435Gate,
        admissionPlan.didKeepTransactionVisibilityRenderCommandTransactionAdmissionOwnerLocal,
        admissionPlan.didKeepTransactionVisibilityRenderCommandTransactionAdmissionPreviewOnly,
        admissionPlan.didPrepareStage438TransactionVisibilityCommandPlan,
        transactionDryRun.didConfirmOwnerAcceptanceRequired,
        transactionDryRun.didConfirmOwnerAcceptanceGranted == false,
        transactionDryRun.didConfirmProductionRenderTruth == false,
        transactionDryRun.didConfirmBackendReadyTruth == false,
        transactionDryRun.didConfirmPublicComponentApiAdded == false,
        transactionDryRun.didConfirmLayoutEngineEnabled == false,
        admissionPlan.didKeepInputEventPipelineBlocked,
        admissionPlan.didKeepInputEventPipelineExecutionBlocked,
        admissionPlan.didKeepActionDispatchBlocked,
        admissionPlan.didKeepStateUpdateCommittedBlocked,
        transactionDryRun.transactionFacts.didKeepVisibilityPublicationBlocked,
        admissionPlan.didKeepVisibilityPublishedBlocked,
        admissionPlan.didKeepBackendImplementationBlocked,
        admissionPlan.didKeepPlatformCommandBufferBlocked,
        admissionPlan.didKeepRendererSubmissionBlocked,
        admissionPlan.didKeepRendererStateWriteBlocked,
        admissionPlan.didKeepRuntimeStateWriteBlocked,
        transactionDryRun.didConfirmNativeBridgeExpansionBlocked
    )
}

func cjguiInternalBuildRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionReadiness(
    transactionDryRun: CjguiInternalRendererStage436TransactionVisibilityRenderCommandGateTransactionDryRunReadiness,
    admissionPlan: CjguiInternalRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionPlan,
    admissionFacts: CjguiInternalRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionFacts
): CjguiInternalRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionReadiness {
    let admissionReady = admissionFacts.didConsumeStage436TransactionVisibilityRenderCommandGateTransactionDryRun && admissionFacts
        .didConsumeTransactionVisibilityRenderCommandTransactionDryRun && admissionFacts
        .didConsumeAcceptedGateToPendingTransactionVisibilityRenderCommandTransaction && admissionFacts
        .didConsumeBlockedGateToRollbackTransactionVisibilityRenderCommandTransaction && admissionFacts
        .didMaterializeTransactionVisibilityRenderCommandTransactionAdmission && admissionFacts
        .didMaterializeTodoTransactionVisibilityRenderCommandTransactionAdmission && admissionFacts
        .didMaterializeSettingsTransactionVisibilityRenderCommandTransactionAdmission && admissionFacts
        .didMaterializeAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionAdmission && admissionFacts
        .didPrepareAcceptedTransactionVisibilityRenderCommandTransactionAdmissionCandidate && admissionFacts
        .didPrepareBlockedTransactionVisibilityRenderCommandTransactionDenialCandidate && admissionFacts
        .didBindTransactionVisibilityAdmissionToStage436TransactionDryRun && admissionFacts
        .didBindTransactionVisibilityAdmissionToStage435Gate && admissionFacts
        .didKeepTransactionVisibilityRenderCommandTransactionAdmissionOwnerLocal && admissionFacts
        .didKeepTransactionVisibilityRenderCommandTransactionAdmissionPreviewOnly && admissionFacts
        .didPrepareStage438TransactionVisibilityCommandPlan
    let stopLineReady = admissionFacts.didKeepOwnerAcceptanceRequired && admissionFacts
        .didKeepOwnerAcceptanceNotGranted && admissionFacts.didKeepProductionRenderTruthBlocked && admissionFacts
        .didKeepBackendReadyTruthBlocked && admissionFacts.didKeepPublicComponentApiBlocked && admissionFacts
        .didKeepLayoutEngineBlocked && admissionFacts.didKeepInputEventPipelineBlocked && admissionFacts
        .didKeepInputEventPipelineExecutionBlocked && admissionFacts.didKeepActionDispatchBlocked && admissionFacts
        .didKeepStateUpdateCommittedBlocked && admissionFacts.didKeepVisibilityPublicationBlocked && admissionFacts
        .didKeepVisibilityPublishedBlocked && admissionFacts.didKeepBackendImplementationBlocked && admissionFacts
        .didKeepPlatformCommandBufferBlocked && admissionFacts.didKeepRendererSubmissionBlocked && admissionFacts
        .didKeepRendererStateWriteBlocked && admissionFacts.didKeepRuntimeStateWriteBlocked && admissionFacts
        .didKeepNativeBridgeExpansionBlocked

    return CjguiInternalRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionReadiness(
        transactionDryRun,
        admissionPlan,
        admissionFacts,
        admissionReady && stopLineReady,
        admissionReady && stopLineReady,
        admissionFacts.didConsumeStage436TransactionVisibilityRenderCommandGateTransactionDryRun,
        admissionFacts.didConsumeTransactionVisibilityRenderCommandTransactionDryRun,
        admissionFacts.didConsumeTodoTransactionVisibilityRenderCommandTransactionDryRun,
        admissionFacts.didConsumeSettingsTransactionVisibilityRenderCommandTransactionDryRun,
        admissionFacts.didConsumeAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionDryRun,
        admissionFacts.didConsumeAcceptedGateToPendingTransactionVisibilityRenderCommandTransaction,
        admissionFacts.didConsumeBlockedGateToRollbackTransactionVisibilityRenderCommandTransaction,
        admissionFacts.didMaterializeTransactionVisibilityRenderCommandTransactionAdmission,
        admissionFacts.didMaterializeTodoTransactionVisibilityRenderCommandTransactionAdmission,
        admissionFacts.didMaterializeSettingsTransactionVisibilityRenderCommandTransactionAdmission,
        admissionFacts.didMaterializeAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionAdmission,
        admissionFacts.didPrepareAcceptedTransactionVisibilityRenderCommandTransactionAdmissionCandidate,
        admissionFacts.didPrepareBlockedTransactionVisibilityRenderCommandTransactionDenialCandidate,
        admissionFacts.didBindTransactionVisibilityAdmissionToStage436TransactionDryRun,
        admissionFacts.didBindTransactionVisibilityAdmissionToStage435Gate,
        admissionFacts.didKeepTransactionVisibilityRenderCommandTransactionAdmissionOwnerLocal,
        admissionFacts.didKeepTransactionVisibilityRenderCommandTransactionAdmissionPreviewOnly,
        admissionFacts.didPrepareStage438TransactionVisibilityCommandPlan,
        admissionFacts.didKeepOwnerAcceptanceRequired,
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
        admissionFacts.didKeepBackendImplementationBlocked,
        admissionFacts.didKeepPlatformCommandBufferBlocked,
        admissionFacts.didKeepRendererSubmissionBlocked,
        admissionFacts.didKeepRendererStateWriteBlocked,
        admissionFacts.didKeepRuntimeStateWriteBlocked,
        admissionFacts.didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionDraft(): CjguiInternalRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionReadiness {
    let transactionDryRun = cjguiInternalExecuteDefaultRendererStage436TransactionVisibilityRenderCommandGateTransactionDryRunDraft()
    let admissionPlan = cjguiInternalBuildRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionPlan(
        transactionDryRun)
    let admissionFacts = cjguiInternalBuildRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionFacts(
        transactionDryRun,
        admissionPlan
    )
    return cjguiInternalBuildRendererStage437TransactionVisibilityRenderCommandTransactionAdmissionReadiness(
        transactionDryRun,
        admissionPlan,
        admissionFacts
    )
}
