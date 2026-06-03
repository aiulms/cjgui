// 中文维护注释：本文件是 stage737 component state store public API internal shape owner。
// Owner: 消费 stage736 commit runtime manager，整理未来 component API 的 internal-only shape。
// Truth: 只证明 commit runtime proof 可形成内部 descriptor / props / state / event port 形状。
// Stop-line: 不新增 stable public API、不提交 state、不 dispatch action、不写 renderer_state/runtime_state。
// Same-shape Boundary Brake: 本 slice 把 public API 前置 shape 收束为共享内部契约输入。
package cjgui

struct CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapePlan {
    let didConsumeStage736ComponentStateStoreCommitRuntimeManager: Bool
    let didConsumeCommitRuntimeManagerContracts: Bool
    let didMaterializeInternalComponentApiShapeDescriptor: Bool
    let didMaterializeComponentPropsShapeLedger: Bool
    let didMaterializeComponentStateSlotShapeLedger: Bool
    let didMaterializeComponentEventPortShapeLedger: Bool
    let didMaterializeComponentCommitCapabilityShape: Bool
    let didMaterializeTodoComponentApiInternalShapeSurface: Bool
    let didMaterializeSettingsComponentApiInternalShapeSurface: Bool
    let didMaterializeAiGeneratedSettingsComponentApiInternalShapeSurface: Bool
    let didMaterializeChatComposerComponentApiInternalShapeSurface: Bool
    let didBindInternalShapeToStage736CommitRuntimeManager: Bool
    let didKeepInternalShapePrePublic: Bool
    let didPrepareStage738ComponentApiCompatibilityPreflight: Bool
    let didKeepHostMutationBlocked: Bool
    let didKeepStablePublicApiBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool

    init(
        didConsumeStage736ComponentStateStoreCommitRuntimeManager: Bool,
        didConsumeCommitRuntimeManagerContracts: Bool,
        didMaterializeInternalComponentApiShapeDescriptor: Bool,
        didMaterializeComponentPropsShapeLedger: Bool,
        didMaterializeComponentStateSlotShapeLedger: Bool,
        didMaterializeComponentEventPortShapeLedger: Bool,
        didMaterializeComponentCommitCapabilityShape: Bool,
        didMaterializeTodoComponentApiInternalShapeSurface: Bool,
        didMaterializeSettingsComponentApiInternalShapeSurface: Bool,
        didMaterializeAiGeneratedSettingsComponentApiInternalShapeSurface: Bool,
        didMaterializeChatComposerComponentApiInternalShapeSurface: Bool,
        didBindInternalShapeToStage736CommitRuntimeManager: Bool,
        didKeepInternalShapePrePublic: Bool,
        didPrepareStage738ComponentApiCompatibilityPreflight: Bool,
        didKeepHostMutationBlocked: Bool,
        didKeepStablePublicApiBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool
    ) {
        this.didConsumeStage736ComponentStateStoreCommitRuntimeManager = didConsumeStage736ComponentStateStoreCommitRuntimeManager
        this.didConsumeCommitRuntimeManagerContracts = didConsumeCommitRuntimeManagerContracts
        this.didMaterializeInternalComponentApiShapeDescriptor = didMaterializeInternalComponentApiShapeDescriptor
        this.didMaterializeComponentPropsShapeLedger = didMaterializeComponentPropsShapeLedger
        this.didMaterializeComponentStateSlotShapeLedger = didMaterializeComponentStateSlotShapeLedger
        this.didMaterializeComponentEventPortShapeLedger = didMaterializeComponentEventPortShapeLedger
        this.didMaterializeComponentCommitCapabilityShape = didMaterializeComponentCommitCapabilityShape
        this.didMaterializeTodoComponentApiInternalShapeSurface = didMaterializeTodoComponentApiInternalShapeSurface
        this.didMaterializeSettingsComponentApiInternalShapeSurface = didMaterializeSettingsComponentApiInternalShapeSurface
        this.didMaterializeAiGeneratedSettingsComponentApiInternalShapeSurface = didMaterializeAiGeneratedSettingsComponentApiInternalShapeSurface
        this.didMaterializeChatComposerComponentApiInternalShapeSurface = didMaterializeChatComposerComponentApiInternalShapeSurface
        this.didBindInternalShapeToStage736CommitRuntimeManager = didBindInternalShapeToStage736CommitRuntimeManager
        this.didKeepInternalShapePrePublic = didKeepInternalShapePrePublic
        this.didPrepareStage738ComponentApiCompatibilityPreflight = didPrepareStage738ComponentApiCompatibilityPreflight
        this.didKeepHostMutationBlocked = didKeepHostMutationBlocked
        this.didKeepStablePublicApiBlocked = didKeepStablePublicApiBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
    }
}

struct CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapeFacts {
    let internalShapePlan: CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapePlan
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didKeepProductionRenderTruthBlocked: Bool
    let didKeepBackendReadyTruthBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepStablePublicApiNotAdded: Bool
    let didKeepInputEventPipelineExecutionBlocked: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepVisibilityPublicationAdmittedBlocked: Bool
    let didKeepVisibilityPublishedBlocked: Bool
    let didKeepNativeBridgeExpansionBlocked: Bool

    init(
        internalShapePlan: CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapePlan,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didKeepProductionRenderTruthBlocked: Bool,
        didKeepBackendReadyTruthBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepStablePublicApiNotAdded: Bool,
        didKeepInputEventPipelineExecutionBlocked: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepVisibilityPublicationAdmittedBlocked: Bool,
        didKeepVisibilityPublishedBlocked: Bool,
        didKeepNativeBridgeExpansionBlocked: Bool
    ) {
        this.internalShapePlan = internalShapePlan
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didKeepOwnerAcceptanceNotGranted = didKeepOwnerAcceptanceNotGranted
        this.didKeepProductionRenderTruthBlocked = didKeepProductionRenderTruthBlocked
        this.didKeepBackendReadyTruthBlocked = didKeepBackendReadyTruthBlocked
        this.didKeepPublicComponentApiBlocked = didKeepPublicComponentApiBlocked
        this.didKeepStablePublicApiNotAdded = didKeepStablePublicApiNotAdded
        this.didKeepInputEventPipelineExecutionBlocked = didKeepInputEventPipelineExecutionBlocked
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepStateUpdateCommittedBlocked = didKeepStateUpdateCommittedBlocked
        this.didKeepVisibilityPublicationAdmittedBlocked = didKeepVisibilityPublicationAdmittedBlocked
        this.didKeepVisibilityPublishedBlocked = didKeepVisibilityPublishedBlocked
        this.didKeepNativeBridgeExpansionBlocked = didKeepNativeBridgeExpansionBlocked
    }
}

struct CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapeReadiness {
    let commitRuntimeManager: CjguiInternalRendererStage736ComponentStateStoreCommitRuntimeManagerReadiness
    let internalShapePlan: CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapePlan
    let internalShapeFacts: CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapeFacts
    let didConfirmStage737ComponentStateStorePublicApiInternalShapeReady: Bool
    let didConfirmStage736ComponentStateStoreCommitRuntimeManagerConsumed: Bool
    let didConfirmStage735ComponentVisualStateStoreCommitHostInspectionUiConsumedTransitively: Bool
    let didConfirmCommitRuntimeManagerContractsConsumed: Bool
    let didConfirmInternalComponentApiShapeDescriptorMaterialized: Bool
    let didConfirmComponentPropsShapeLedgerMaterialized: Bool
    let didConfirmComponentStateSlotShapeLedgerMaterialized: Bool
    let didConfirmComponentEventPortShapeLedgerMaterialized: Bool
    let didConfirmComponentCommitCapabilityShapeMaterialized: Bool
    let didConfirmTodoComponentApiInternalShapeSurfaceMaterialized: Bool
    let didConfirmSettingsComponentApiInternalShapeSurfaceMaterialized: Bool
    let didConfirmAiGeneratedSettingsComponentApiInternalShapeSurfaceMaterialized: Bool
    let didConfirmChatComposerComponentApiInternalShapeSurfaceMaterialized: Bool
    let didConfirmInternalShapeBoundToStage736CommitRuntimeManager: Bool
    let didConfirmInternalShapePrePublic: Bool
    let didConfirmStage738ComponentApiCompatibilityPreflightPrepared: Bool
    let didConfirmHostMutation: Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmProductionRenderTruth: Bool
    let didConfirmBackendReadyTruth: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmStablePublicApiAdded: Bool
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
        commitRuntimeManager: CjguiInternalRendererStage736ComponentStateStoreCommitRuntimeManagerReadiness,
        internalShapePlan: CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapePlan,
        internalShapeFacts: CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapeFacts,
        didConfirmStage737ComponentStateStorePublicApiInternalShapeReady: Bool,
        didConfirmStage736ComponentStateStoreCommitRuntimeManagerConsumed: Bool,
        didConfirmStage735ComponentVisualStateStoreCommitHostInspectionUiConsumedTransitively: Bool,
        didConfirmCommitRuntimeManagerContractsConsumed: Bool,
        didConfirmInternalComponentApiShapeDescriptorMaterialized: Bool,
        didConfirmComponentPropsShapeLedgerMaterialized: Bool,
        didConfirmComponentStateSlotShapeLedgerMaterialized: Bool,
        didConfirmComponentEventPortShapeLedgerMaterialized: Bool,
        didConfirmComponentCommitCapabilityShapeMaterialized: Bool,
        didConfirmTodoComponentApiInternalShapeSurfaceMaterialized: Bool,
        didConfirmSettingsComponentApiInternalShapeSurfaceMaterialized: Bool,
        didConfirmAiGeneratedSettingsComponentApiInternalShapeSurfaceMaterialized: Bool,
        didConfirmChatComposerComponentApiInternalShapeSurfaceMaterialized: Bool,
        didConfirmInternalShapeBoundToStage736CommitRuntimeManager: Bool,
        didConfirmInternalShapePrePublic: Bool,
        didConfirmStage738ComponentApiCompatibilityPreflightPrepared: Bool,
        didConfirmHostMutation: Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmProductionRenderTruth: Bool,
        didConfirmBackendReadyTruth: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmStablePublicApiAdded: Bool,
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
        this.commitRuntimeManager = commitRuntimeManager
        this.internalShapePlan = internalShapePlan
        this.internalShapeFacts = internalShapeFacts
        this.didConfirmStage737ComponentStateStorePublicApiInternalShapeReady = didConfirmStage737ComponentStateStorePublicApiInternalShapeReady
        this.didConfirmStage736ComponentStateStoreCommitRuntimeManagerConsumed = didConfirmStage736ComponentStateStoreCommitRuntimeManagerConsumed
        this.didConfirmStage735ComponentVisualStateStoreCommitHostInspectionUiConsumedTransitively = didConfirmStage735ComponentVisualStateStoreCommitHostInspectionUiConsumedTransitively
        this.didConfirmCommitRuntimeManagerContractsConsumed = didConfirmCommitRuntimeManagerContractsConsumed
        this.didConfirmInternalComponentApiShapeDescriptorMaterialized = didConfirmInternalComponentApiShapeDescriptorMaterialized
        this.didConfirmComponentPropsShapeLedgerMaterialized = didConfirmComponentPropsShapeLedgerMaterialized
        this.didConfirmComponentStateSlotShapeLedgerMaterialized = didConfirmComponentStateSlotShapeLedgerMaterialized
        this.didConfirmComponentEventPortShapeLedgerMaterialized = didConfirmComponentEventPortShapeLedgerMaterialized
        this.didConfirmComponentCommitCapabilityShapeMaterialized = didConfirmComponentCommitCapabilityShapeMaterialized
        this.didConfirmTodoComponentApiInternalShapeSurfaceMaterialized = didConfirmTodoComponentApiInternalShapeSurfaceMaterialized
        this.didConfirmSettingsComponentApiInternalShapeSurfaceMaterialized = didConfirmSettingsComponentApiInternalShapeSurfaceMaterialized
        this.didConfirmAiGeneratedSettingsComponentApiInternalShapeSurfaceMaterialized = didConfirmAiGeneratedSettingsComponentApiInternalShapeSurfaceMaterialized
        this.didConfirmChatComposerComponentApiInternalShapeSurfaceMaterialized = didConfirmChatComposerComponentApiInternalShapeSurfaceMaterialized
        this.didConfirmInternalShapeBoundToStage736CommitRuntimeManager = didConfirmInternalShapeBoundToStage736CommitRuntimeManager
        this.didConfirmInternalShapePrePublic = didConfirmInternalShapePrePublic
        this.didConfirmStage738ComponentApiCompatibilityPreflightPrepared = didConfirmStage738ComponentApiCompatibilityPreflightPrepared
        this.didConfirmHostMutation = didConfirmHostMutation
        this.didConfirmOwnerAcceptanceRequired = didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted = didConfirmOwnerAcceptanceGranted
        this.didConfirmProductionRenderTruth = didConfirmProductionRenderTruth
        this.didConfirmBackendReadyTruth = didConfirmBackendReadyTruth
        this.didConfirmPublicComponentApiAdded = didConfirmPublicComponentApiAdded
        this.didConfirmStablePublicApiAdded = didConfirmStablePublicApiAdded
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

func cjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapeMaterialized(): Bool {
    return true
}

func cjguiInternalBuildRendererStage737ComponentStateStorePublicApiInternalShapePlan(
    commitRuntimeManager: CjguiInternalRendererStage736ComponentStateStoreCommitRuntimeManagerReadiness): CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapePlan {
    let stage736Ready = commitRuntimeManager.didConfirmStage736ComponentStateStoreCommitRuntimeManagerReady && commitRuntimeManager
        .didConfirmStage737ComponentStateStorePublicApiInternalShapePrepared
    let commitRuntimeContractsReady = commitRuntimeManager
        .didConfirmSharedComponentStateStoreCommitRuntimeManagerMaterialized && commitRuntimeManager
        .didConfirmComponentStateStoreCommitRuntimeContractMaterialized && commitRuntimeManager
        .didConfirmComponentStateStoreCommitExecutionReceiptContractMaterialized && commitRuntimeManager
        .didConfirmChatComposerComponentStateStoreCommitRuntimeSurfaceMaterialized
    let internalShapeReady = stage736Ready && commitRuntimeContractsReady &&
        cjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapeMaterialized()
    return CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapePlan(
        stage736Ready,
        commitRuntimeContractsReady,
        internalShapeReady,
        internalShapeReady,
        internalShapeReady,
        internalShapeReady,
        internalShapeReady,
        internalShapeReady,
        internalShapeReady,
        internalShapeReady,
        internalShapeReady,
        commitRuntimeManager.didConfirmCommitRuntimeManagerBoundToStage735HostInspectionUi,
        internalShapeReady,
        internalShapeReady,
        commitRuntimeManager.didConfirmHostMutation == false,
        commitRuntimeManager.didConfirmPublicComponentApiAdded == false,
        commitRuntimeManager.didConfirmRendererSubmissionBlocked,
        commitRuntimeManager.didConfirmRendererStateWriteBlocked,
        commitRuntimeManager.didConfirmRuntimeStateWriteBlocked
    )
}

func cjguiInternalBuildRendererStage737ComponentStateStorePublicApiInternalShapeFacts(
    commitRuntimeManager: CjguiInternalRendererStage736ComponentStateStoreCommitRuntimeManagerReadiness,
    internalShapePlan: CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapePlan
): CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapeFacts {
    return CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapeFacts(
        internalShapePlan,
        commitRuntimeManager.didConfirmOwnerAcceptanceRequired,
        commitRuntimeManager.didConfirmOwnerAcceptanceGranted == false,
        commitRuntimeManager.didConfirmProductionRenderTruth == false,
        commitRuntimeManager.didConfirmBackendReadyTruth == false,
        commitRuntimeManager.didConfirmPublicComponentApiAdded == false,
        internalShapePlan.didKeepStablePublicApiBlocked,
        commitRuntimeManager.didConfirmInputEventPipelineExecution == false,
        commitRuntimeManager.didConfirmActionDispatch == false,
        commitRuntimeManager.didConfirmStateUpdateCommitted == false,
        commitRuntimeManager.didConfirmVisibilityPublicationAdmitted == false,
        commitRuntimeManager.didConfirmVisibilityPublished == false,
        commitRuntimeManager.didConfirmNativeBridgeExpansionBlocked
    )
}

func cjguiInternalBuildRendererStage737ComponentStateStorePublicApiInternalShapeReadiness(
    commitRuntimeManager: CjguiInternalRendererStage736ComponentStateStoreCommitRuntimeManagerReadiness,
    internalShapePlan: CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapePlan,
    internalShapeFacts: CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapeFacts
): CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapeReadiness {
    let internalShapeReady = internalShapePlan.didConsumeStage736ComponentStateStoreCommitRuntimeManager && internalShapePlan
        .didConsumeCommitRuntimeManagerContracts && internalShapePlan.didMaterializeInternalComponentApiShapeDescriptor &&
        internalShapePlan.didMaterializeComponentPropsShapeLedger && internalShapePlan
        .didMaterializeComponentStateSlotShapeLedger && internalShapePlan.didMaterializeComponentEventPortShapeLedger && internalShapePlan
        .didMaterializeComponentCommitCapabilityShape && internalShapePlan
        .didMaterializeChatComposerComponentApiInternalShapeSurface && internalShapePlan
        .didBindInternalShapeToStage736CommitRuntimeManager && internalShapePlan.didKeepInternalShapePrePublic && internalShapePlan
        .didPrepareStage738ComponentApiCompatibilityPreflight
    let stopLineReady = internalShapePlan.didKeepHostMutationBlocked && internalShapeFacts
        .didKeepOwnerAcceptanceRequired && internalShapeFacts.didKeepOwnerAcceptanceNotGranted && internalShapeFacts
        .didKeepProductionRenderTruthBlocked && internalShapeFacts.didKeepBackendReadyTruthBlocked && internalShapeFacts
        .didKeepPublicComponentApiBlocked && internalShapeFacts.didKeepStablePublicApiNotAdded && internalShapeFacts
        .didKeepInputEventPipelineExecutionBlocked && internalShapeFacts.didKeepActionDispatchBlocked && internalShapeFacts
        .didKeepStateUpdateCommittedBlocked && internalShapeFacts.didKeepVisibilityPublicationAdmittedBlocked && internalShapeFacts
        .didKeepVisibilityPublishedBlocked && internalShapePlan.didKeepRendererSubmissionBlocked && internalShapePlan
        .didKeepRendererStateWriteBlocked && internalShapePlan.didKeepRuntimeStateWriteBlocked && internalShapeFacts
        .didKeepNativeBridgeExpansionBlocked
    return CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapeReadiness(
        commitRuntimeManager,
        internalShapePlan,
        internalShapeFacts,
        internalShapeReady && stopLineReady,
        internalShapePlan.didConsumeStage736ComponentStateStoreCommitRuntimeManager,
        commitRuntimeManager.didConfirmStage735ComponentVisualStateStoreCommitHostInspectionUiConsumed,
        internalShapePlan.didConsumeCommitRuntimeManagerContracts,
        internalShapePlan.didMaterializeInternalComponentApiShapeDescriptor,
        internalShapePlan.didMaterializeComponentPropsShapeLedger,
        internalShapePlan.didMaterializeComponentStateSlotShapeLedger,
        internalShapePlan.didMaterializeComponentEventPortShapeLedger,
        internalShapePlan.didMaterializeComponentCommitCapabilityShape,
        internalShapePlan.didMaterializeTodoComponentApiInternalShapeSurface,
        internalShapePlan.didMaterializeSettingsComponentApiInternalShapeSurface,
        internalShapePlan.didMaterializeAiGeneratedSettingsComponentApiInternalShapeSurface,
        internalShapePlan.didMaterializeChatComposerComponentApiInternalShapeSurface,
        internalShapePlan.didBindInternalShapeToStage736CommitRuntimeManager,
        internalShapePlan.didKeepInternalShapePrePublic,
        internalShapePlan.didPrepareStage738ComponentApiCompatibilityPreflight,
        false,
        internalShapeFacts.didKeepOwnerAcceptanceRequired,
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
        internalShapePlan.didKeepRendererSubmissionBlocked,
        internalShapePlan.didKeepRendererStateWriteBlocked,
        internalShapePlan.didKeepRuntimeStateWriteBlocked,
        internalShapeFacts.didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage737ComponentStateStorePublicApiInternalShapeDraft(): CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapeReadiness {
    let commitRuntimeManager = cjguiInternalExecuteDefaultRendererStage736ComponentStateStoreCommitRuntimeManagerDraft()
    let internalShapePlan = cjguiInternalBuildRendererStage737ComponentStateStorePublicApiInternalShapePlan(
        commitRuntimeManager)
    let internalShapeFacts = cjguiInternalBuildRendererStage737ComponentStateStorePublicApiInternalShapeFacts(
        commitRuntimeManager,
        internalShapePlan
    )
    return cjguiInternalBuildRendererStage737ComponentStateStorePublicApiInternalShapeReadiness(
        commitRuntimeManager,
        internalShapePlan,
        internalShapeFacts
    )
}
