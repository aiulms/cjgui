// 中文维护注释：本文件是 stage758 minimal public preview API declaration owner。
// Owner: 消费 stage757 descriptor，开放一个 experimental Cangjie public preview readiness projection。
// Truth: 只新增 `cjguiExperimentalComponentPreviewApiReady(): Bool`，不承诺 stable compatibility。
// Stop-line: 不扩 public C ABI、不暴露 internal owner type、不执行 state commit、不写 renderer_state/runtime_state。
// Same-shape Boundary Brake: 本 slice 用单一 public preview readiness API 替代后续同构 public-preflight owner。
package cjgui

struct CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationPlan {
    let didConsumeStage757MinimalPublicPreviewApiDescriptor: Bool
    let didConsumeMinimalPublicPreviewComponentDescriptor: Bool
    let didMaterializeExperimentalComponentPreviewReadinessApi: Bool
    let didExposeOnlyCjguiExperimentalComponentPreviewApiReady: Bool
    let didBindPublicPreviewApiToDescriptor: Bool
    let didKeepPublicPreviewApiStableCompatibilityUnpromised: Bool
    let didKeepPublicCAbiUnexpanded: Bool
    let didPrepareStage759MinimalPublicPreviewApiDemoConsumption: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool

    init(
        didConsumeStage757MinimalPublicPreviewApiDescriptor: Bool,
        didConsumeMinimalPublicPreviewComponentDescriptor: Bool,
        didMaterializeExperimentalComponentPreviewReadinessApi: Bool,
        didExposeOnlyCjguiExperimentalComponentPreviewApiReady: Bool,
        didBindPublicPreviewApiToDescriptor: Bool,
        didKeepPublicPreviewApiStableCompatibilityUnpromised: Bool,
        didKeepPublicCAbiUnexpanded: Bool,
        didPrepareStage759MinimalPublicPreviewApiDemoConsumption: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool
    ) {
        this.didConsumeStage757MinimalPublicPreviewApiDescriptor = didConsumeStage757MinimalPublicPreviewApiDescriptor
        this.didConsumeMinimalPublicPreviewComponentDescriptor = didConsumeMinimalPublicPreviewComponentDescriptor
        this.didMaterializeExperimentalComponentPreviewReadinessApi = didMaterializeExperimentalComponentPreviewReadinessApi
        this.didExposeOnlyCjguiExperimentalComponentPreviewApiReady = didExposeOnlyCjguiExperimentalComponentPreviewApiReady
        this.didBindPublicPreviewApiToDescriptor = didBindPublicPreviewApiToDescriptor
        this.didKeepPublicPreviewApiStableCompatibilityUnpromised = didKeepPublicPreviewApiStableCompatibilityUnpromised
        this.didKeepPublicCAbiUnexpanded = didKeepPublicCAbiUnexpanded
        this.didPrepareStage759MinimalPublicPreviewApiDemoConsumption = didPrepareStage759MinimalPublicPreviewApiDemoConsumption
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
    }
}

struct CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationFacts {
    let previewApiDeclarationPlan: CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationPlan
    let didAddPublicComponentApi: Bool
    let didKeepStablePublicApiNotAdded: Bool
    let didKeepPublicCAbiNotAdded: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didKeepAcceptanceCommitNotCommitted: Bool
    let didKeepInputEventPipelineExecutionBlocked: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepNativeBridgeExpansionBlocked: Bool

    init(
        previewApiDeclarationPlan: CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationPlan,
        didAddPublicComponentApi: Bool,
        didKeepStablePublicApiNotAdded: Bool,
        didKeepPublicCAbiNotAdded: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didKeepAcceptanceCommitNotCommitted: Bool,
        didKeepInputEventPipelineExecutionBlocked: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepNativeBridgeExpansionBlocked: Bool
    ) {
        this.previewApiDeclarationPlan = previewApiDeclarationPlan
        this.didAddPublicComponentApi = didAddPublicComponentApi
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

struct CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationReadiness {
    let previewDescriptor: CjguiInternalRendererStage757MinimalPublicPreviewApiDescriptorReadiness
    let previewApiDeclarationPlan: CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationPlan
    let previewApiDeclarationFacts: CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationFacts
    let didConfirmStage758MinimalPublicPreviewApiDeclarationReady: Bool
    let didConfirmStage757MinimalPublicPreviewApiDescriptorConsumed: Bool
    let didConfirmExperimentalComponentPreviewReadinessApiMaterialized: Bool
    let didConfirmOnlyCjguiExperimentalComponentPreviewApiReadyExposed: Bool
    let didConfirmPublicPreviewApiBoundToDescriptor: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmStablePublicApiAdded: Bool
    let didConfirmPublicCAbiAdded: Bool
    let didConfirmPublicPreviewApiStableCompatibilityUnpromised: Bool
    let didConfirmStage759MinimalPublicPreviewApiDemoConsumptionPrepared: Bool
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
        previewDescriptor: CjguiInternalRendererStage757MinimalPublicPreviewApiDescriptorReadiness,
        previewApiDeclarationPlan: CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationPlan,
        previewApiDeclarationFacts: CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationFacts,
        didConfirmStage758MinimalPublicPreviewApiDeclarationReady: Bool,
        didConfirmStage757MinimalPublicPreviewApiDescriptorConsumed: Bool,
        didConfirmExperimentalComponentPreviewReadinessApiMaterialized: Bool,
        didConfirmOnlyCjguiExperimentalComponentPreviewApiReadyExposed: Bool,
        didConfirmPublicPreviewApiBoundToDescriptor: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmStablePublicApiAdded: Bool,
        didConfirmPublicCAbiAdded: Bool,
        didConfirmPublicPreviewApiStableCompatibilityUnpromised: Bool,
        didConfirmStage759MinimalPublicPreviewApiDemoConsumptionPrepared: Bool,
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
        this.previewDescriptor = previewDescriptor
        this.previewApiDeclarationPlan = previewApiDeclarationPlan
        this.previewApiDeclarationFacts = previewApiDeclarationFacts
        this.didConfirmStage758MinimalPublicPreviewApiDeclarationReady = didConfirmStage758MinimalPublicPreviewApiDeclarationReady
        this.didConfirmStage757MinimalPublicPreviewApiDescriptorConsumed = didConfirmStage757MinimalPublicPreviewApiDescriptorConsumed
        this.didConfirmExperimentalComponentPreviewReadinessApiMaterialized = didConfirmExperimentalComponentPreviewReadinessApiMaterialized
        this.didConfirmOnlyCjguiExperimentalComponentPreviewApiReadyExposed = didConfirmOnlyCjguiExperimentalComponentPreviewApiReadyExposed
        this.didConfirmPublicPreviewApiBoundToDescriptor = didConfirmPublicPreviewApiBoundToDescriptor
        this.didConfirmPublicComponentApiAdded = didConfirmPublicComponentApiAdded
        this.didConfirmStablePublicApiAdded = didConfirmStablePublicApiAdded
        this.didConfirmPublicCAbiAdded = didConfirmPublicCAbiAdded
        this.didConfirmPublicPreviewApiStableCompatibilityUnpromised = didConfirmPublicPreviewApiStableCompatibilityUnpromised
        this.didConfirmStage759MinimalPublicPreviewApiDemoConsumptionPrepared = didConfirmStage759MinimalPublicPreviewApiDemoConsumptionPrepared
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

func cjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationMaterialized(): Bool {
    return true
}

func cjguiInternalBuildRendererStage758MinimalPublicPreviewApiDeclarationPlan(
    previewDescriptor: CjguiInternalRendererStage757MinimalPublicPreviewApiDescriptorReadiness): CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationPlan {
    let descriptorReady = previewDescriptor.didConfirmStage757MinimalPublicPreviewApiDescriptorReady && previewDescriptor
        .didConfirmStage758MinimalPublicPreviewApiDeclarationPrepared
    let publicApiReady = descriptorReady && previewDescriptor
        .didConfirmMinimalPublicPreviewComponentDescriptorMaterialized && previewDescriptor
        .didConfirmPreviewCompatibilityLedgerMaterialized && previewDescriptor
        .didConfirmPreviewRollbackDeprecationNoteMaterialized && previewDescriptor.didConfirmPreviewApiExperimental &&
        cjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationMaterialized()
    return CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationPlan(
        descriptorReady,
        previewDescriptor.didConfirmMinimalPublicPreviewComponentDescriptorMaterialized,
        publicApiReady,
        publicApiReady,
        previewDescriptor.didConfirmPreviewDescriptorBoundToAcceptanceCommitRuntimeContract,
        previewDescriptor.didConfirmStablePublicApiAdded == false,
        previewDescriptor.didConfirmPublicCAbiAdded == false,
        publicApiReady,
        previewDescriptor.didConfirmRendererSubmissionBlocked,
        previewDescriptor.didConfirmRendererStateWriteBlocked,
        previewDescriptor.didConfirmRuntimeStateWriteBlocked
    )
}

func cjguiInternalBuildRendererStage758MinimalPublicPreviewApiDeclarationFacts(
    previewDescriptor: CjguiInternalRendererStage757MinimalPublicPreviewApiDescriptorReadiness,
    previewApiDeclarationPlan: CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationPlan
): CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationFacts {
    return CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationFacts(
        previewApiDeclarationPlan,
        previewApiDeclarationPlan.didMaterializeExperimentalComponentPreviewReadinessApi,
        previewApiDeclarationPlan.didKeepPublicPreviewApiStableCompatibilityUnpromised,
        previewApiDeclarationPlan.didKeepPublicCAbiUnexpanded,
        previewDescriptor.didConfirmOwnerAcceptanceGranted == false,
        previewDescriptor.didConfirmAcceptanceCommitCommitted == false,
        previewDescriptor.didConfirmInputEventPipelineExecution == false,
        previewDescriptor.didConfirmActionDispatch == false,
        previewDescriptor.didConfirmStateUpdateCommitted == false,
        previewDescriptor.didConfirmNativeBridgeExpansionBlocked
    )
}

func cjguiInternalBuildRendererStage758MinimalPublicPreviewApiDeclarationReadiness(
    previewDescriptor: CjguiInternalRendererStage757MinimalPublicPreviewApiDescriptorReadiness,
    previewApiDeclarationPlan: CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationPlan,
    previewApiDeclarationFacts: CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationFacts
): CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationReadiness {
    let declarationReady = previewApiDeclarationPlan.didConsumeStage757MinimalPublicPreviewApiDescriptor && previewApiDeclarationPlan
        .didConsumeMinimalPublicPreviewComponentDescriptor && previewApiDeclarationPlan
        .didMaterializeExperimentalComponentPreviewReadinessApi && previewApiDeclarationPlan
        .didExposeOnlyCjguiExperimentalComponentPreviewApiReady && previewApiDeclarationPlan
        .didBindPublicPreviewApiToDescriptor && previewApiDeclarationPlan
        .didKeepPublicPreviewApiStableCompatibilityUnpromised && previewApiDeclarationPlan.didKeepPublicCAbiUnexpanded &&
        previewApiDeclarationPlan.didPrepareStage759MinimalPublicPreviewApiDemoConsumption
    let stopLineReady = previewApiDeclarationFacts.didAddPublicComponentApi && previewApiDeclarationFacts
        .didKeepStablePublicApiNotAdded && previewApiDeclarationFacts.didKeepPublicCAbiNotAdded && previewApiDeclarationFacts
        .didKeepOwnerAcceptanceNotGranted && previewApiDeclarationFacts.didKeepAcceptanceCommitNotCommitted && previewApiDeclarationFacts
        .didKeepInputEventPipelineExecutionBlocked && previewApiDeclarationFacts.didKeepActionDispatchBlocked && previewApiDeclarationFacts
        .didKeepStateUpdateCommittedBlocked && previewApiDeclarationPlan.didKeepRendererSubmissionBlocked && previewApiDeclarationPlan
        .didKeepRendererStateWriteBlocked && previewApiDeclarationPlan.didKeepRuntimeStateWriteBlocked && previewApiDeclarationFacts
        .didKeepNativeBridgeExpansionBlocked
    return CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationReadiness(
        previewDescriptor,
        previewApiDeclarationPlan,
        previewApiDeclarationFacts,
        declarationReady && stopLineReady,
        previewApiDeclarationPlan.didConsumeStage757MinimalPublicPreviewApiDescriptor,
        previewApiDeclarationPlan.didMaterializeExperimentalComponentPreviewReadinessApi,
        previewApiDeclarationPlan.didExposeOnlyCjguiExperimentalComponentPreviewApiReady,
        previewApiDeclarationPlan.didBindPublicPreviewApiToDescriptor,
        true,
        false,
        false,
        previewApiDeclarationPlan.didKeepPublicPreviewApiStableCompatibilityUnpromised,
        previewApiDeclarationPlan.didPrepareStage759MinimalPublicPreviewApiDemoConsumption,
        false,
        false,
        false,
        false,
        false,
        previewApiDeclarationPlan.didKeepRendererSubmissionBlocked,
        previewApiDeclarationPlan.didKeepRendererStateWriteBlocked,
        previewApiDeclarationPlan.didKeepRuntimeStateWriteBlocked,
        previewApiDeclarationFacts.didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage758MinimalPublicPreviewApiDeclarationDraft(): CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationReadiness {
    let previewDescriptor = cjguiInternalExecuteDefaultRendererStage757MinimalPublicPreviewApiDescriptorDraft()
    let previewApiDeclarationPlan = cjguiInternalBuildRendererStage758MinimalPublicPreviewApiDeclarationPlan(
        previewDescriptor)
    let previewApiDeclarationFacts = cjguiInternalBuildRendererStage758MinimalPublicPreviewApiDeclarationFacts(
        previewDescriptor,
        previewApiDeclarationPlan
    )
    return cjguiInternalBuildRendererStage758MinimalPublicPreviewApiDeclarationReadiness(
        previewDescriptor,
        previewApiDeclarationPlan,
        previewApiDeclarationFacts
    )
}

// 这是 CJGUI component preview API 的第一个 experimental Cangjie public surface。
// 只返回 readiness projection，不暴露 internal owner type，不提交 state，不承诺 stable compatibility。
public func cjguiExperimentalComponentPreviewApiReady(): Bool {
    let readiness = cjguiInternalExecuteDefaultRendererStage758MinimalPublicPreviewApiDeclarationDraft()
    return readiness.didConfirmStage758MinimalPublicPreviewApiDeclarationReady && readiness
        .didConfirmExperimentalComponentPreviewReadinessApiMaterialized && readiness
        .didConfirmOnlyCjguiExperimentalComponentPreviewApiReadyExposed && readiness
        .didConfirmPublicPreviewApiBoundToDescriptor && readiness.didConfirmPublicComponentApiAdded &&
        readiness.didConfirmStablePublicApiAdded == false && readiness.didConfirmPublicCAbiAdded == false && readiness
        .didConfirmPublicPreviewApiStableCompatibilityUnpromised && readiness.didConfirmOwnerAcceptanceGranted == false &&
        readiness.didConfirmAcceptanceCommitCommitted == false && readiness.didConfirmRendererStateWriteBlocked && readiness
        .didConfirmRuntimeStateWriteBlocked && readiness.didConfirmNativeBridgeExpansionBlocked
}
