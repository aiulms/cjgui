// 中文维护注释：本文件是 stage663 interaction feedback input state/render receipt owner。
// Owner: 消费 stage662 normalized feedback input intents，生成 state/render/focus/result surface receipt。
// Truth: 只证明 feedback input intent 可进入 owner-local dry-run receipt，不提交 state。
// Stop-line: 不执行真实 input pipeline、不 dispatch、不发布 visibility、不写 renderer_state/runtime_state。
// Same-shape Boundary Brake: 本轮把四个 demo 的 feedback input state/render receipt 合并为 shared receipt。
package cjgui

struct CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptPlan {
    let didConsumeStage662InteractionFeedbackInputIntentNormalizer: Bool
    let didConsumeFeedbackInputIntents: Bool
    let didMaterializeFeedbackInputStateDeltaDryRunReceipt: Bool
    let didMaterializeFeedbackInputRenderCommandRefreshReceipt: Bool
    let didMaterializeFeedbackInputFocusTransitionPreview: Bool
    let didMaterializeFeedbackInputResultSurfaceRefreshReceipt: Bool
    let didMaterializeFeedbackInputSemanticDiffExplainReceipt: Bool
    let didMaterializeTodoFeedbackInputStateRenderReceipt: Bool
    let didMaterializeSettingsFeedbackInputStateRenderReceipt: Bool
    let didMaterializeAiGeneratedSettingsFeedbackInputStateRenderReceipt: Bool
    let didMaterializeChatComposerFeedbackInputStateRenderReceipt: Bool
    let didBindStateRenderReceiptToStage662Intents: Bool
    let didKeepFeedbackInputStateRenderReceiptCheckable: Bool
    let didKeepStateUpdateDryRunOnly: Bool
    let didPrepareStage664InteractionFeedbackInputRuntimeContract: Bool
    let didKeepHostMutationBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool

    init(
        didConsumeStage662InteractionFeedbackInputIntentNormalizer: Bool,
        didConsumeFeedbackInputIntents: Bool,
        didMaterializeFeedbackInputStateDeltaDryRunReceipt: Bool,
        didMaterializeFeedbackInputRenderCommandRefreshReceipt: Bool,
        didMaterializeFeedbackInputFocusTransitionPreview: Bool,
        didMaterializeFeedbackInputResultSurfaceRefreshReceipt: Bool,
        didMaterializeFeedbackInputSemanticDiffExplainReceipt: Bool,
        didMaterializeTodoFeedbackInputStateRenderReceipt: Bool,
        didMaterializeSettingsFeedbackInputStateRenderReceipt: Bool,
        didMaterializeAiGeneratedSettingsFeedbackInputStateRenderReceipt: Bool,
        didMaterializeChatComposerFeedbackInputStateRenderReceipt: Bool,
        didBindStateRenderReceiptToStage662Intents: Bool,
        didKeepFeedbackInputStateRenderReceiptCheckable: Bool,
        didKeepStateUpdateDryRunOnly: Bool,
        didPrepareStage664InteractionFeedbackInputRuntimeContract: Bool,
        didKeepHostMutationBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool
    ) {
        this.didConsumeStage662InteractionFeedbackInputIntentNormalizer = didConsumeStage662InteractionFeedbackInputIntentNormalizer
        this.didConsumeFeedbackInputIntents = didConsumeFeedbackInputIntents
        this.didMaterializeFeedbackInputStateDeltaDryRunReceipt = didMaterializeFeedbackInputStateDeltaDryRunReceipt
        this.didMaterializeFeedbackInputRenderCommandRefreshReceipt = didMaterializeFeedbackInputRenderCommandRefreshReceipt
        this.didMaterializeFeedbackInputFocusTransitionPreview = didMaterializeFeedbackInputFocusTransitionPreview
        this.didMaterializeFeedbackInputResultSurfaceRefreshReceipt = didMaterializeFeedbackInputResultSurfaceRefreshReceipt
        this.didMaterializeFeedbackInputSemanticDiffExplainReceipt = didMaterializeFeedbackInputSemanticDiffExplainReceipt
        this.didMaterializeTodoFeedbackInputStateRenderReceipt = didMaterializeTodoFeedbackInputStateRenderReceipt
        this.didMaterializeSettingsFeedbackInputStateRenderReceipt = didMaterializeSettingsFeedbackInputStateRenderReceipt
        this.didMaterializeAiGeneratedSettingsFeedbackInputStateRenderReceipt = didMaterializeAiGeneratedSettingsFeedbackInputStateRenderReceipt
        this.didMaterializeChatComposerFeedbackInputStateRenderReceipt = didMaterializeChatComposerFeedbackInputStateRenderReceipt
        this.didBindStateRenderReceiptToStage662Intents = didBindStateRenderReceiptToStage662Intents
        this.didKeepFeedbackInputStateRenderReceiptCheckable = didKeepFeedbackInputStateRenderReceiptCheckable
        this.didKeepStateUpdateDryRunOnly = didKeepStateUpdateDryRunOnly
        this.didPrepareStage664InteractionFeedbackInputRuntimeContract = didPrepareStage664InteractionFeedbackInputRuntimeContract
        this.didKeepHostMutationBlocked = didKeepHostMutationBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
    }
}

struct CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptFacts {
    let stateRenderReceiptPlan: CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptPlan
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
        stateRenderReceiptPlan: CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptPlan,
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
        this.stateRenderReceiptPlan = stateRenderReceiptPlan
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

struct CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptReadiness {
    let intentNormalizer: CjguiInternalRendererStage662InteractionFeedbackInputIntentNormalizerReadiness
    let stateRenderReceiptPlan: CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptPlan
    let stateRenderReceiptFacts: CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptFacts
    let didConfirmStage663InteractionFeedbackInputStateRenderReceiptReady: Bool
    let didConfirmStage662InteractionFeedbackInputIntentNormalizerConsumed: Bool
    let didConfirmStage661InteractionFeedbackInputBridgeConsumedTransitively: Bool
    let didConfirmFeedbackInputIntentsConsumed: Bool
    let didConfirmFeedbackInputStateDeltaDryRunReceiptMaterialized: Bool
    let didConfirmFeedbackInputRenderCommandRefreshReceiptMaterialized: Bool
    let didConfirmFeedbackInputFocusTransitionPreviewMaterialized: Bool
    let didConfirmFeedbackInputResultSurfaceRefreshReceiptMaterialized: Bool
    let didConfirmFeedbackInputSemanticDiffExplainReceiptMaterialized: Bool
    let didConfirmTodoFeedbackInputStateRenderReceiptMaterialized: Bool
    let didConfirmSettingsFeedbackInputStateRenderReceiptMaterialized: Bool
    let didConfirmAiGeneratedSettingsFeedbackInputStateRenderReceiptMaterialized: Bool
    let didConfirmChatComposerFeedbackInputStateRenderReceiptMaterialized: Bool
    let didConfirmFeedbackInputStateRenderReceiptCheckable: Bool
    let didConfirmStateUpdateDryRunOnly: Bool
    let didConfirmStage664InteractionFeedbackInputRuntimeContractPrepared: Bool
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
        intentNormalizer: CjguiInternalRendererStage662InteractionFeedbackInputIntentNormalizerReadiness,
        stateRenderReceiptPlan: CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptPlan,
        stateRenderReceiptFacts: CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptFacts,
        didConfirmStage663InteractionFeedbackInputStateRenderReceiptReady: Bool,
        didConfirmStage662InteractionFeedbackInputIntentNormalizerConsumed: Bool,
        didConfirmStage661InteractionFeedbackInputBridgeConsumedTransitively: Bool,
        didConfirmFeedbackInputIntentsConsumed: Bool,
        didConfirmFeedbackInputStateDeltaDryRunReceiptMaterialized: Bool,
        didConfirmFeedbackInputRenderCommandRefreshReceiptMaterialized: Bool,
        didConfirmFeedbackInputFocusTransitionPreviewMaterialized: Bool,
        didConfirmFeedbackInputResultSurfaceRefreshReceiptMaterialized: Bool,
        didConfirmFeedbackInputSemanticDiffExplainReceiptMaterialized: Bool,
        didConfirmTodoFeedbackInputStateRenderReceiptMaterialized: Bool,
        didConfirmSettingsFeedbackInputStateRenderReceiptMaterialized: Bool,
        didConfirmAiGeneratedSettingsFeedbackInputStateRenderReceiptMaterialized: Bool,
        didConfirmChatComposerFeedbackInputStateRenderReceiptMaterialized: Bool,
        didConfirmFeedbackInputStateRenderReceiptCheckable: Bool,
        didConfirmStateUpdateDryRunOnly: Bool,
        didConfirmStage664InteractionFeedbackInputRuntimeContractPrepared: Bool,
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
        this.intentNormalizer = intentNormalizer
        this.stateRenderReceiptPlan = stateRenderReceiptPlan
        this.stateRenderReceiptFacts = stateRenderReceiptFacts
        this.didConfirmStage663InteractionFeedbackInputStateRenderReceiptReady = didConfirmStage663InteractionFeedbackInputStateRenderReceiptReady
        this.didConfirmStage662InteractionFeedbackInputIntentNormalizerConsumed = didConfirmStage662InteractionFeedbackInputIntentNormalizerConsumed
        this.didConfirmStage661InteractionFeedbackInputBridgeConsumedTransitively = didConfirmStage661InteractionFeedbackInputBridgeConsumedTransitively
        this.didConfirmFeedbackInputIntentsConsumed = didConfirmFeedbackInputIntentsConsumed
        this.didConfirmFeedbackInputStateDeltaDryRunReceiptMaterialized = didConfirmFeedbackInputStateDeltaDryRunReceiptMaterialized
        this.didConfirmFeedbackInputRenderCommandRefreshReceiptMaterialized = didConfirmFeedbackInputRenderCommandRefreshReceiptMaterialized
        this.didConfirmFeedbackInputFocusTransitionPreviewMaterialized = didConfirmFeedbackInputFocusTransitionPreviewMaterialized
        this.didConfirmFeedbackInputResultSurfaceRefreshReceiptMaterialized = didConfirmFeedbackInputResultSurfaceRefreshReceiptMaterialized
        this.didConfirmFeedbackInputSemanticDiffExplainReceiptMaterialized = didConfirmFeedbackInputSemanticDiffExplainReceiptMaterialized
        this.didConfirmTodoFeedbackInputStateRenderReceiptMaterialized = didConfirmTodoFeedbackInputStateRenderReceiptMaterialized
        this.didConfirmSettingsFeedbackInputStateRenderReceiptMaterialized = didConfirmSettingsFeedbackInputStateRenderReceiptMaterialized
        this.didConfirmAiGeneratedSettingsFeedbackInputStateRenderReceiptMaterialized = didConfirmAiGeneratedSettingsFeedbackInputStateRenderReceiptMaterialized
        this.didConfirmChatComposerFeedbackInputStateRenderReceiptMaterialized = didConfirmChatComposerFeedbackInputStateRenderReceiptMaterialized
        this.didConfirmFeedbackInputStateRenderReceiptCheckable = didConfirmFeedbackInputStateRenderReceiptCheckable
        this.didConfirmStateUpdateDryRunOnly = didConfirmStateUpdateDryRunOnly
        this.didConfirmStage664InteractionFeedbackInputRuntimeContractPrepared = didConfirmStage664InteractionFeedbackInputRuntimeContractPrepared
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

func cjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptMaterialized(): Bool {
    return true
}

func cjguiInternalBuildRendererStage663InteractionFeedbackInputStateRenderReceiptPlan(
    intentNormalizer: CjguiInternalRendererStage662InteractionFeedbackInputIntentNormalizerReadiness): CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptPlan {
    let stage662Ready = intentNormalizer.didConfirmStage662InteractionFeedbackInputIntentNormalizerReady && intentNormalizer
        .didConfirmStage663InteractionFeedbackInputStateRenderReceiptPrepared
    let intentReady = intentNormalizer.didConfirmSharedFeedbackInputIntentNormalizerMaterialized && intentNormalizer
        .didConfirmValidationDismissInputIntentMaterialized && intentNormalizer
        .didConfirmFocusMovementInputIntentMaterialized && intentNormalizer
        .didConfirmInputFeedbackClearInputIntentMaterialized && intentNormalizer
        .didConfirmSemanticDiffAcknowledgeInputIntentMaterialized && intentNormalizer
        .didConfirmChatComposerFeedbackInputIntentMaterialized
    let receiptReady = stage662Ready && intentReady &&
        cjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptMaterialized()
    return CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptPlan(
        stage662Ready,
        intentReady,
        receiptReady,
        receiptReady,
        receiptReady,
        receiptReady,
        receiptReady,
        receiptReady,
        receiptReady,
        receiptReady,
        receiptReady,
        receiptReady,
        receiptReady,
        receiptReady,
        receiptReady,
        intentNormalizer.didConfirmHostMutation == false,
        intentNormalizer.didConfirmRendererSubmissionBlocked,
        intentNormalizer.didConfirmRendererStateWriteBlocked,
        intentNormalizer.didConfirmRuntimeStateWriteBlocked
    )
}

func cjguiInternalBuildRendererStage663InteractionFeedbackInputStateRenderReceiptFacts(
    intentNormalizer: CjguiInternalRendererStage662InteractionFeedbackInputIntentNormalizerReadiness,
    stateRenderReceiptPlan: CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptPlan
): CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptFacts {
    return CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptFacts(
        stateRenderReceiptPlan,
        intentNormalizer.didConfirmOwnerAcceptanceRequired,
        intentNormalizer.didConfirmOwnerAcceptanceGranted == false,
        intentNormalizer.didConfirmProductionRenderTruth == false,
        intentNormalizer.didConfirmBackendReadyTruth == false,
        intentNormalizer.didConfirmPublicComponentApiAdded == false,
        intentNormalizer.didConfirmInputEventPipelineExecution == false,
        intentNormalizer.didConfirmActionDispatch == false,
        intentNormalizer.didConfirmStateUpdateCommitted == false,
        intentNormalizer.didConfirmVisibilityPublicationAdmitted == false,
        intentNormalizer.didConfirmVisibilityPublished == false,
        intentNormalizer.didConfirmNativeBridgeExpansionBlocked
    )
}

func cjguiInternalBuildRendererStage663InteractionFeedbackInputStateRenderReceiptReadiness(
    intentNormalizer: CjguiInternalRendererStage662InteractionFeedbackInputIntentNormalizerReadiness,
    stateRenderReceiptPlan: CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptPlan,
    stateRenderReceiptFacts: CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptFacts
): CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptReadiness {
    let receiptReady = stateRenderReceiptPlan.didConsumeStage662InteractionFeedbackInputIntentNormalizer && stateRenderReceiptPlan
        .didConsumeFeedbackInputIntents && stateRenderReceiptPlan.didMaterializeFeedbackInputStateDeltaDryRunReceipt && stateRenderReceiptPlan
        .didMaterializeFeedbackInputRenderCommandRefreshReceipt && stateRenderReceiptPlan
        .didMaterializeFeedbackInputFocusTransitionPreview && stateRenderReceiptPlan
        .didMaterializeFeedbackInputResultSurfaceRefreshReceipt && stateRenderReceiptPlan
        .didMaterializeFeedbackInputSemanticDiffExplainReceipt && stateRenderReceiptPlan
        .didMaterializeChatComposerFeedbackInputStateRenderReceipt && stateRenderReceiptPlan
        .didKeepFeedbackInputStateRenderReceiptCheckable && stateRenderReceiptPlan.didKeepStateUpdateDryRunOnly && stateRenderReceiptPlan
        .didPrepareStage664InteractionFeedbackInputRuntimeContract
    let stopLineReady = stateRenderReceiptPlan.didKeepHostMutationBlocked && stateRenderReceiptFacts
        .didKeepOwnerAcceptanceRequired && stateRenderReceiptFacts.didKeepOwnerAcceptanceNotGranted && stateRenderReceiptFacts
        .didKeepProductionRenderTruthBlocked && stateRenderReceiptFacts.didKeepBackendReadyTruthBlocked && stateRenderReceiptFacts
        .didKeepPublicComponentApiBlocked && stateRenderReceiptFacts.didKeepInputEventPipelineExecutionBlocked && stateRenderReceiptFacts
        .didKeepActionDispatchBlocked && stateRenderReceiptFacts.didKeepStateUpdateCommittedBlocked && stateRenderReceiptFacts
        .didKeepVisibilityPublicationAdmittedBlocked && stateRenderReceiptFacts.didKeepVisibilityPublishedBlocked && stateRenderReceiptPlan
        .didKeepRendererSubmissionBlocked && stateRenderReceiptPlan.didKeepRendererStateWriteBlocked && stateRenderReceiptPlan
        .didKeepRuntimeStateWriteBlocked && stateRenderReceiptFacts.didKeepNativeBridgeExpansionBlocked
    return CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptReadiness(
        intentNormalizer,
        stateRenderReceiptPlan,
        stateRenderReceiptFacts,
        receiptReady && stopLineReady,
        stateRenderReceiptPlan.didConsumeStage662InteractionFeedbackInputIntentNormalizer,
        intentNormalizer.didConfirmStage661InteractionFeedbackInputBridgeConsumed,
        stateRenderReceiptPlan.didConsumeFeedbackInputIntents,
        stateRenderReceiptPlan.didMaterializeFeedbackInputStateDeltaDryRunReceipt,
        stateRenderReceiptPlan.didMaterializeFeedbackInputRenderCommandRefreshReceipt,
        stateRenderReceiptPlan.didMaterializeFeedbackInputFocusTransitionPreview,
        stateRenderReceiptPlan.didMaterializeFeedbackInputResultSurfaceRefreshReceipt,
        stateRenderReceiptPlan.didMaterializeFeedbackInputSemanticDiffExplainReceipt,
        stateRenderReceiptPlan.didMaterializeTodoFeedbackInputStateRenderReceipt,
        stateRenderReceiptPlan.didMaterializeSettingsFeedbackInputStateRenderReceipt,
        stateRenderReceiptPlan.didMaterializeAiGeneratedSettingsFeedbackInputStateRenderReceipt,
        stateRenderReceiptPlan.didMaterializeChatComposerFeedbackInputStateRenderReceipt,
        stateRenderReceiptPlan.didKeepFeedbackInputStateRenderReceiptCheckable,
        stateRenderReceiptPlan.didKeepStateUpdateDryRunOnly,
        stateRenderReceiptPlan.didPrepareStage664InteractionFeedbackInputRuntimeContract,
        false,
        stateRenderReceiptFacts.didKeepOwnerAcceptanceRequired,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        stateRenderReceiptPlan.didKeepRendererSubmissionBlocked,
        stateRenderReceiptPlan.didKeepRendererStateWriteBlocked,
        stateRenderReceiptPlan.didKeepRuntimeStateWriteBlocked,
        stateRenderReceiptFacts.didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage663InteractionFeedbackInputStateRenderReceiptDraft(): CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptReadiness {
    let intentNormalizer = cjguiInternalExecuteDefaultRendererStage662InteractionFeedbackInputIntentNormalizerDraft()
    let stateRenderReceiptPlan = cjguiInternalBuildRendererStage663InteractionFeedbackInputStateRenderReceiptPlan(
        intentNormalizer)
    let stateRenderReceiptFacts = cjguiInternalBuildRendererStage663InteractionFeedbackInputStateRenderReceiptFacts(
        intentNormalizer,
        stateRenderReceiptPlan
    )
    return cjguiInternalBuildRendererStage663InteractionFeedbackInputStateRenderReceiptReadiness(
        intentNormalizer,
        stateRenderReceiptPlan,
        stateRenderReceiptFacts
    )
}
