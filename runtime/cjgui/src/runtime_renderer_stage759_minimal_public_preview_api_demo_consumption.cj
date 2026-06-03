// 中文维护注释：本文件是 stage759 minimal public preview API demo consumption owner。
// Owner: 消费 stage758 public preview declaration，让 Todo / settings demo surface 共同消费该 shape。
// Truth: 只证明两个 demo 能引用 experimental readiness projection，不执行真实 UI/state mutation。
// Stop-line: 不授予 owner acceptance、不提交 state、不写 renderer_state/runtime_state、不扩 public C ABI。
// Same-shape Boundary Brake: 本 slice 防止后续每个 demo 复制 public preview API consumption proof。
package cjgui

struct CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionPlan {
    let didConsumeStage758MinimalPublicPreviewApiDeclaration: Bool
    let didConsumeCjguiExperimentalComponentPreviewApiReady: Bool
    let didMaterializeTodoPublicPreviewApiDemoSurface: Bool
    let didMaterializeSettingsPublicPreviewApiDemoSurface: Bool
    let didBindDemoConsumptionToPublicPreviewApiDeclaration: Bool
    let didKeepDemoConsumptionPreviewOnly: Bool
    let didPrepareStage760MinimalPublicPreviewApiPublicScanContract: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool

    init(
        didConsumeStage758MinimalPublicPreviewApiDeclaration: Bool,
        didConsumeCjguiExperimentalComponentPreviewApiReady: Bool,
        didMaterializeTodoPublicPreviewApiDemoSurface: Bool,
        didMaterializeSettingsPublicPreviewApiDemoSurface: Bool,
        didBindDemoConsumptionToPublicPreviewApiDeclaration: Bool,
        didKeepDemoConsumptionPreviewOnly: Bool,
        didPrepareStage760MinimalPublicPreviewApiPublicScanContract: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool
    ) {
        this.didConsumeStage758MinimalPublicPreviewApiDeclaration = didConsumeStage758MinimalPublicPreviewApiDeclaration
        this.didConsumeCjguiExperimentalComponentPreviewApiReady = didConsumeCjguiExperimentalComponentPreviewApiReady
        this.didMaterializeTodoPublicPreviewApiDemoSurface = didMaterializeTodoPublicPreviewApiDemoSurface
        this.didMaterializeSettingsPublicPreviewApiDemoSurface = didMaterializeSettingsPublicPreviewApiDemoSurface
        this.didBindDemoConsumptionToPublicPreviewApiDeclaration = didBindDemoConsumptionToPublicPreviewApiDeclaration
        this.didKeepDemoConsumptionPreviewOnly = didKeepDemoConsumptionPreviewOnly
        this.didPrepareStage760MinimalPublicPreviewApiPublicScanContract = didPrepareStage760MinimalPublicPreviewApiPublicScanContract
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
    }
}

struct CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionFacts {
    let demoConsumptionPlan: CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionPlan
    let didKeepPublicComponentApiAdded: Bool
    let didKeepStablePublicApiNotAdded: Bool
    let didKeepPublicCAbiNotAdded: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didKeepAcceptanceCommitNotCommitted: Bool
    let didKeepInputEventPipelineExecutionBlocked: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepNativeBridgeExpansionBlocked: Bool

    init(
        demoConsumptionPlan: CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionPlan,
        didKeepPublicComponentApiAdded: Bool,
        didKeepStablePublicApiNotAdded: Bool,
        didKeepPublicCAbiNotAdded: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didKeepAcceptanceCommitNotCommitted: Bool,
        didKeepInputEventPipelineExecutionBlocked: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepNativeBridgeExpansionBlocked: Bool
    ) {
        this.demoConsumptionPlan = demoConsumptionPlan
        this.didKeepPublicComponentApiAdded = didKeepPublicComponentApiAdded
        this.didKeepStablePublicApiNotAdded = didKeepStablePublicApiNotAdded
        this.didKeepPublicCAbiNotAdded = didKeepPublicCAbiNotAdded
        this.didKeepOwnerAcceptanceNotGranted = didKeepOwnerAcceptanceNotGranted
        this.didKeepAcceptanceCommitNotCommitted = didKeepAcceptanceCommitNotCommitted
        this.didKeepInputEventPipelineExecutionBlocked = didKeepInputEventPipelineExecutionBlocked
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepStateUpdateCommittedBlocked = didKeepStateUpdateCommittedBlocked
        this.didKeepNativeBridgeExpansionBlocked = didKeepNativeBridgeExpansionBlocked
    }
}

struct CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionReadiness {
    let previewApiDeclaration: CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationReadiness
    let demoConsumptionPlan: CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionPlan
    let demoConsumptionFacts: CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionFacts
    let didConfirmStage759MinimalPublicPreviewApiDemoConsumptionReady: Bool
    let didConfirmStage758MinimalPublicPreviewApiDeclarationConsumed: Bool
    let didConfirmCjguiExperimentalComponentPreviewApiReadyConsumed: Bool
    let didConfirmTodoPublicPreviewApiDemoSurfaceMaterialized: Bool
    let didConfirmSettingsPublicPreviewApiDemoSurfaceMaterialized: Bool
    let didConfirmDemoConsumptionBoundToPublicPreviewApiDeclaration: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmStablePublicApiAdded: Bool
    let didConfirmPublicCAbiAdded: Bool
    let didConfirmStage760MinimalPublicPreviewApiPublicScanContractPrepared: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmAcceptanceCommitCommitted: Bool
    let didConfirmInputEventPipelineExecution: Bool
    let didConfirmActionDispatch: Bool
    let didConfirmStateUpdateCommitted: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmNativeBridgeExpansionBlocked: Bool

    init(
        previewApiDeclaration: CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationReadiness,
        demoConsumptionPlan: CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionPlan,
        demoConsumptionFacts: CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionFacts,
        didConfirmStage759MinimalPublicPreviewApiDemoConsumptionReady: Bool,
        didConfirmStage758MinimalPublicPreviewApiDeclarationConsumed: Bool,
        didConfirmCjguiExperimentalComponentPreviewApiReadyConsumed: Bool,
        didConfirmTodoPublicPreviewApiDemoSurfaceMaterialized: Bool,
        didConfirmSettingsPublicPreviewApiDemoSurfaceMaterialized: Bool,
        didConfirmDemoConsumptionBoundToPublicPreviewApiDeclaration: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmStablePublicApiAdded: Bool,
        didConfirmPublicCAbiAdded: Bool,
        didConfirmStage760MinimalPublicPreviewApiPublicScanContractPrepared: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmAcceptanceCommitCommitted: Bool,
        didConfirmInputEventPipelineExecution: Bool,
        didConfirmActionDispatch: Bool,
        didConfirmStateUpdateCommitted: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmNativeBridgeExpansionBlocked: Bool
    ) {
        this.previewApiDeclaration = previewApiDeclaration
        this.demoConsumptionPlan = demoConsumptionPlan
        this.demoConsumptionFacts = demoConsumptionFacts
        this.didConfirmStage759MinimalPublicPreviewApiDemoConsumptionReady = didConfirmStage759MinimalPublicPreviewApiDemoConsumptionReady
        this.didConfirmStage758MinimalPublicPreviewApiDeclarationConsumed = didConfirmStage758MinimalPublicPreviewApiDeclarationConsumed
        this.didConfirmCjguiExperimentalComponentPreviewApiReadyConsumed = didConfirmCjguiExperimentalComponentPreviewApiReadyConsumed
        this.didConfirmTodoPublicPreviewApiDemoSurfaceMaterialized = didConfirmTodoPublicPreviewApiDemoSurfaceMaterialized
        this.didConfirmSettingsPublicPreviewApiDemoSurfaceMaterialized = didConfirmSettingsPublicPreviewApiDemoSurfaceMaterialized
        this.didConfirmDemoConsumptionBoundToPublicPreviewApiDeclaration = didConfirmDemoConsumptionBoundToPublicPreviewApiDeclaration
        this.didConfirmPublicComponentApiAdded = didConfirmPublicComponentApiAdded
        this.didConfirmStablePublicApiAdded = didConfirmStablePublicApiAdded
        this.didConfirmPublicCAbiAdded = didConfirmPublicCAbiAdded
        this.didConfirmStage760MinimalPublicPreviewApiPublicScanContractPrepared = didConfirmStage760MinimalPublicPreviewApiPublicScanContractPrepared
        this.didConfirmOwnerAcceptanceGranted = didConfirmOwnerAcceptanceGranted
        this.didConfirmAcceptanceCommitCommitted = didConfirmAcceptanceCommitCommitted
        this.didConfirmInputEventPipelineExecution = didConfirmInputEventPipelineExecution
        this.didConfirmActionDispatch = didConfirmActionDispatch
        this.didConfirmStateUpdateCommitted = didConfirmStateUpdateCommitted
        this.didConfirmRendererSubmissionBlocked = didConfirmRendererSubmissionBlocked
        this.didConfirmRendererStateWriteBlocked = didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked = didConfirmRuntimeStateWriteBlocked
        this.didConfirmNativeBridgeExpansionBlocked = didConfirmNativeBridgeExpansionBlocked
    }
}

func cjguiInternalBuildRendererStage759MinimalPublicPreviewApiDemoConsumptionPlan(
    previewApiDeclaration: CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationReadiness): CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionPlan {
    let declarationReady = previewApiDeclaration.didConfirmStage758MinimalPublicPreviewApiDeclarationReady && previewApiDeclaration
        .didConfirmStage759MinimalPublicPreviewApiDemoConsumptionPrepared
    let publicApiReady = cjguiExperimentalComponentPreviewApiReady()
    let demoReady = declarationReady && publicApiReady && previewApiDeclaration
        .didConfirmPublicPreviewApiStableCompatibilityUnpromised
    return CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionPlan(
        declarationReady,
        publicApiReady,
        demoReady,
        demoReady,
        previewApiDeclaration.didConfirmPublicPreviewApiBoundToDescriptor,
        demoReady,
        demoReady,
        previewApiDeclaration.didConfirmRendererSubmissionBlocked,
        previewApiDeclaration.didConfirmRendererStateWriteBlocked,
        previewApiDeclaration.didConfirmRuntimeStateWriteBlocked
    )
}

func cjguiInternalBuildRendererStage759MinimalPublicPreviewApiDemoConsumptionFacts(
    previewApiDeclaration: CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationReadiness,
    demoConsumptionPlan: CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionPlan
): CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionFacts {
    return CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionFacts(
        demoConsumptionPlan,
        previewApiDeclaration.didConfirmPublicComponentApiAdded,
        previewApiDeclaration.didConfirmStablePublicApiAdded == false,
        previewApiDeclaration.didConfirmPublicCAbiAdded == false,
        previewApiDeclaration.didConfirmOwnerAcceptanceGranted == false,
        previewApiDeclaration.didConfirmAcceptanceCommitCommitted == false,
        previewApiDeclaration.didConfirmInputEventPipelineExecution == false,
        previewApiDeclaration.didConfirmActionDispatch == false,
        previewApiDeclaration.didConfirmStateUpdateCommitted == false,
        previewApiDeclaration.didConfirmNativeBridgeExpansionBlocked
    )
}

func cjguiInternalBuildRendererStage759MinimalPublicPreviewApiDemoConsumptionReadiness(
    previewApiDeclaration: CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationReadiness,
    demoConsumptionPlan: CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionPlan,
    demoConsumptionFacts: CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionFacts
): CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionReadiness {
    let demoConsumptionReady = demoConsumptionPlan.didConsumeStage758MinimalPublicPreviewApiDeclaration && demoConsumptionPlan
        .didConsumeCjguiExperimentalComponentPreviewApiReady && demoConsumptionPlan
        .didMaterializeTodoPublicPreviewApiDemoSurface && demoConsumptionPlan
        .didMaterializeSettingsPublicPreviewApiDemoSurface && demoConsumptionPlan
        .didBindDemoConsumptionToPublicPreviewApiDeclaration && demoConsumptionPlan.didKeepDemoConsumptionPreviewOnly && demoConsumptionPlan
        .didPrepareStage760MinimalPublicPreviewApiPublicScanContract
    let stopLineReady = demoConsumptionFacts.didKeepPublicComponentApiAdded && demoConsumptionFacts
        .didKeepStablePublicApiNotAdded && demoConsumptionFacts.didKeepPublicCAbiNotAdded && demoConsumptionFacts
        .didKeepOwnerAcceptanceNotGranted && demoConsumptionFacts.didKeepAcceptanceCommitNotCommitted && demoConsumptionFacts
        .didKeepInputEventPipelineExecutionBlocked && demoConsumptionFacts.didKeepActionDispatchBlocked && demoConsumptionFacts
        .didKeepStateUpdateCommittedBlocked && demoConsumptionPlan.didKeepRendererSubmissionBlocked && demoConsumptionPlan
        .didKeepRendererStateWriteBlocked && demoConsumptionPlan.didKeepRuntimeStateWriteBlocked && demoConsumptionFacts
        .didKeepNativeBridgeExpansionBlocked
    return CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionReadiness(
        previewApiDeclaration,
        demoConsumptionPlan,
        demoConsumptionFacts,
        demoConsumptionReady && stopLineReady,
        demoConsumptionPlan.didConsumeStage758MinimalPublicPreviewApiDeclaration,
        demoConsumptionPlan.didConsumeCjguiExperimentalComponentPreviewApiReady,
        demoConsumptionPlan.didMaterializeTodoPublicPreviewApiDemoSurface,
        demoConsumptionPlan.didMaterializeSettingsPublicPreviewApiDemoSurface,
        demoConsumptionPlan.didBindDemoConsumptionToPublicPreviewApiDeclaration,
        demoConsumptionFacts.didKeepPublicComponentApiAdded,
        false,
        false,
        demoConsumptionPlan.didPrepareStage760MinimalPublicPreviewApiPublicScanContract,
        false,
        false,
        false,
        false,
        false,
        demoConsumptionPlan.didKeepRendererSubmissionBlocked,
        demoConsumptionPlan.didKeepRendererStateWriteBlocked,
        demoConsumptionPlan.didKeepRuntimeStateWriteBlocked,
        demoConsumptionFacts.didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage759MinimalPublicPreviewApiDemoConsumptionDraft(): CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionReadiness {
    let previewApiDeclaration = cjguiInternalExecuteDefaultRendererStage758MinimalPublicPreviewApiDeclarationDraft()
    let demoConsumptionPlan = cjguiInternalBuildRendererStage759MinimalPublicPreviewApiDemoConsumptionPlan(
        previewApiDeclaration)
    let demoConsumptionFacts = cjguiInternalBuildRendererStage759MinimalPublicPreviewApiDemoConsumptionFacts(
        previewApiDeclaration,
        demoConsumptionPlan
    )
    return cjguiInternalBuildRendererStage759MinimalPublicPreviewApiDemoConsumptionReadiness(
        previewApiDeclaration,
        demoConsumptionPlan,
        demoConsumptionFacts
    )
}
