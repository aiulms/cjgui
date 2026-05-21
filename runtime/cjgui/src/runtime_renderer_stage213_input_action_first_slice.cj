// 中文维护注释：本文件是 stage213 input/action first-slice owner。
// Owner: 消费 stage212 UI framework runway readiness decision，生成 Button-like
// action intent、enabled predicate 与 semantic-node 绑定事实。
// Truth: action intent 是 owner-local preview 输入，不是事件派发或 runtime action。
// Stop-line: 不执行 input pipeline，不 dispatch action，不写 renderer/runtime state。
package cjgui

struct CjguiInternalRendererStage213InputActionIntentFacts {
    let actionOrdinal: Int64
    let targetSemanticNodeOrdinal: Int64
    let didMaterializeButtonLikeActionIntentFacts: Bool
    let didBindActionIntentToButtonLikeSemanticNode: Bool
    let didBindEnabledPredicateToActionIntent: Bool
    let didKeepActionIntentOwnerLocal: Bool
    let didKeepActionDispatchDeterministic: Bool
    let didKeepInputEventPipelineExecutionBlocked: Bool

    init(
        actionOrdinal: Int64,
        targetSemanticNodeOrdinal: Int64,
        didMaterializeButtonLikeActionIntentFacts: Bool,
        didBindActionIntentToButtonLikeSemanticNode: Bool,
        didBindEnabledPredicateToActionIntent: Bool,
        didKeepActionIntentOwnerLocal: Bool,
        didKeepActionDispatchDeterministic: Bool,
        didKeepInputEventPipelineExecutionBlocked: Bool
    ) {
        this.actionOrdinal = actionOrdinal
        this.targetSemanticNodeOrdinal = targetSemanticNodeOrdinal
        this.didMaterializeButtonLikeActionIntentFacts =
            didMaterializeButtonLikeActionIntentFacts
        this.didBindActionIntentToButtonLikeSemanticNode =
            didBindActionIntentToButtonLikeSemanticNode
        this.didBindEnabledPredicateToActionIntent =
            didBindEnabledPredicateToActionIntent
        this.didKeepActionIntentOwnerLocal = didKeepActionIntentOwnerLocal
        this.didKeepActionDispatchDeterministic =
            didKeepActionDispatchDeterministic
        this.didKeepInputEventPipelineExecutionBlocked =
            didKeepInputEventPipelineExecutionBlocked
    }
}

struct CjguiInternalRendererStage213InputActionFirstSliceFacts {
    let inputActionIntentFacts:
        CjguiInternalRendererStage213InputActionIntentFacts
    let didConsumeStage212UiFrameworkRunwayReadinessDecision: Bool
    let didConsumeStyledComponentPreviewPacket: Bool
    let didBindActionIntentToSemanticNode: Bool
    let didBindActionIntentToStyledComponentPreviewPacket: Bool
    let didPreserveStyleRollbackBoundary: Bool
    let didPrepareStage214ActionPreviewPacketInput: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepLayoutEngineBlocked: Bool
    let didKeepInputEventPipelineExecutionBlocked: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepVisibilityNotPublished: Bool

    init(
        inputActionIntentFacts:
            CjguiInternalRendererStage213InputActionIntentFacts,
        didConsumeStage212UiFrameworkRunwayReadinessDecision: Bool,
        didConsumeStyledComponentPreviewPacket: Bool,
        didBindActionIntentToSemanticNode: Bool,
        didBindActionIntentToStyledComponentPreviewPacket: Bool,
        didPreserveStyleRollbackBoundary: Bool,
        didPrepareStage214ActionPreviewPacketInput: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepLayoutEngineBlocked: Bool,
        didKeepInputEventPipelineExecutionBlocked: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepVisibilityNotPublished: Bool
    ) {
        this.inputActionIntentFacts = inputActionIntentFacts
        this.didConsumeStage212UiFrameworkRunwayReadinessDecision =
            didConsumeStage212UiFrameworkRunwayReadinessDecision
        this.didConsumeStyledComponentPreviewPacket =
            didConsumeStyledComponentPreviewPacket
        this.didBindActionIntentToSemanticNode =
            didBindActionIntentToSemanticNode
        this.didBindActionIntentToStyledComponentPreviewPacket =
            didBindActionIntentToStyledComponentPreviewPacket
        this.didPreserveStyleRollbackBoundary =
            didPreserveStyleRollbackBoundary
        this.didPrepareStage214ActionPreviewPacketInput =
            didPrepareStage214ActionPreviewPacketInput
        this.didKeepPublicComponentApiBlocked =
            didKeepPublicComponentApiBlocked
        this.didKeepLayoutEngineBlocked = didKeepLayoutEngineBlocked
        this.didKeepInputEventPipelineExecutionBlocked =
            didKeepInputEventPipelineExecutionBlocked
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didKeepVisibilityNotPublished = didKeepVisibilityNotPublished
    }
}

struct CjguiInternalRendererStage213InputActionFirstSliceReadiness {
    let uiFrameworkRunwayReadinessDecision:
        CjguiInternalRendererStage212UiFrameworkRunwayReadinessDecisionReadiness
    let inputActionFirstSliceFacts:
        CjguiInternalRendererStage213InputActionFirstSliceFacts
    let didPrepareStage213InputActionFirstSliceReadiness: Bool
    let didConfirmInputActionFirstSliceReady: Bool
    let didConfirmButtonLikeActionIntentFactsMaterialized: Bool
    let didConfirmActionIntentBoundToSemanticNode: Bool
    let didConfirmActionEnabledPredicateBound: Bool
    let didConfirmActionIntentBoundToStyledComponentPreviewPacket: Bool
    let didConfirmStyleRollbackBoundaryPreserved: Bool
    let didConfirmStage214ActionPreviewPacketInputPrepared: Bool
    let didConfirmInputEventPipelineExecuted: Bool
    let didConfirmActionDispatchBlocked: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmLayoutEngineEnabled: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmVisibilityPublished: Bool

    init(
        uiFrameworkRunwayReadinessDecision:
            CjguiInternalRendererStage212UiFrameworkRunwayReadinessDecisionReadiness,
        inputActionFirstSliceFacts:
            CjguiInternalRendererStage213InputActionFirstSliceFacts,
        didPrepareStage213InputActionFirstSliceReadiness: Bool,
        didConfirmInputActionFirstSliceReady: Bool,
        didConfirmButtonLikeActionIntentFactsMaterialized: Bool,
        didConfirmActionIntentBoundToSemanticNode: Bool,
        didConfirmActionEnabledPredicateBound: Bool,
        didConfirmActionIntentBoundToStyledComponentPreviewPacket: Bool,
        didConfirmStyleRollbackBoundaryPreserved: Bool,
        didConfirmStage214ActionPreviewPacketInputPrepared: Bool,
        didConfirmInputEventPipelineExecuted: Bool,
        didConfirmActionDispatchBlocked: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmLayoutEngineEnabled: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmVisibilityPublished: Bool
    ) {
        this.uiFrameworkRunwayReadinessDecision =
            uiFrameworkRunwayReadinessDecision
        this.inputActionFirstSliceFacts = inputActionFirstSliceFacts
        this.didPrepareStage213InputActionFirstSliceReadiness =
            didPrepareStage213InputActionFirstSliceReadiness
        this.didConfirmInputActionFirstSliceReady =
            didConfirmInputActionFirstSliceReady
        this.didConfirmButtonLikeActionIntentFactsMaterialized =
            didConfirmButtonLikeActionIntentFactsMaterialized
        this.didConfirmActionIntentBoundToSemanticNode =
            didConfirmActionIntentBoundToSemanticNode
        this.didConfirmActionEnabledPredicateBound =
            didConfirmActionEnabledPredicateBound
        this.didConfirmActionIntentBoundToStyledComponentPreviewPacket =
            didConfirmActionIntentBoundToStyledComponentPreviewPacket
        this.didConfirmStyleRollbackBoundaryPreserved =
            didConfirmStyleRollbackBoundaryPreserved
        this.didConfirmStage214ActionPreviewPacketInputPrepared =
            didConfirmStage214ActionPreviewPacketInputPrepared
        this.didConfirmInputEventPipelineExecuted =
            didConfirmInputEventPipelineExecuted
        this.didConfirmActionDispatchBlocked = didConfirmActionDispatchBlocked
        this.didConfirmPublicComponentApiAdded =
            didConfirmPublicComponentApiAdded
        this.didConfirmLayoutEngineEnabled = didConfirmLayoutEngineEnabled
        this.didConfirmRendererSubmissionBlocked =
            didConfirmRendererSubmissionBlocked
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked =
            didConfirmRuntimeStateWriteBlocked
        this.didConfirmVisibilityPublished = didConfirmVisibilityPublished
    }
}

func cjguiInternalBuildRendererStage213InputActionIntentFacts():
    CjguiInternalRendererStage213InputActionIntentFacts {
    return CjguiInternalRendererStage213InputActionIntentFacts(
        1,
        3,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererStage213InputActionFirstSliceFacts(
    uiFrameworkRunwayReadinessDecision:
        CjguiInternalRendererStage212UiFrameworkRunwayReadinessDecisionReadiness,
    inputActionIntentFacts:
        CjguiInternalRendererStage213InputActionIntentFacts
): CjguiInternalRendererStage213InputActionFirstSliceFacts {
    let layoutStyleSemanticDiffExplain =
        uiFrameworkRunwayReadinessDecision.layoutStyleSemanticDiffExplain
    let styledPreview =
        layoutStyleSemanticDiffExplain.styledComponentPreviewPacket

    return CjguiInternalRendererStage213InputActionFirstSliceFacts(
        inputActionIntentFacts,
        uiFrameworkRunwayReadinessDecision
            .didConfirmStage213InputActionFirstSliceInputPrepared,
        styledPreview.didConfirmStyledComponentPreviewPacketMaterialized,
        inputActionIntentFacts
            .didBindActionIntentToButtonLikeSemanticNode,
        styledPreview.didConfirmStyledComponentPreviewPacketMaterialized &&
            uiFrameworkRunwayReadinessDecision
                .didConfirmLayoutStyleFactsJoinedWithStyledPreviewPacket,
        layoutStyleSemanticDiffExplain
            .didConfirmStyleRollbackReadyBoundaryMaterialized,
        true,
        uiFrameworkRunwayReadinessDecision
            .didConfirmPublicComponentApiAdded == false,
        uiFrameworkRunwayReadinessDecision
            .didConfirmLayoutEngineEnabled == false,
        inputActionIntentFacts.didKeepInputEventPipelineExecutionBlocked,
        true,
        uiFrameworkRunwayReadinessDecision
            .didConfirmRendererSubmissionBlocked,
        uiFrameworkRunwayReadinessDecision
            .didConfirmRendererStateWriteBlocked,
        uiFrameworkRunwayReadinessDecision
            .didConfirmRuntimeStateWriteBlocked,
        uiFrameworkRunwayReadinessDecision
            .didConfirmVisibilityPublished == false
    )
}

func cjguiInternalBuildRendererStage213InputActionFirstSliceReadiness(
    uiFrameworkRunwayReadinessDecision:
        CjguiInternalRendererStage212UiFrameworkRunwayReadinessDecisionReadiness,
    inputActionFirstSliceFacts:
        CjguiInternalRendererStage213InputActionFirstSliceFacts
): CjguiInternalRendererStage213InputActionFirstSliceReadiness {
    let intentFacts = inputActionFirstSliceFacts.inputActionIntentFacts
    let firstSliceReady =
        inputActionFirstSliceFacts
            .didConsumeStage212UiFrameworkRunwayReadinessDecision &&
        inputActionFirstSliceFacts.didConsumeStyledComponentPreviewPacket &&
        inputActionFirstSliceFacts.didBindActionIntentToSemanticNode &&
        inputActionFirstSliceFacts
            .didBindActionIntentToStyledComponentPreviewPacket &&
        inputActionFirstSliceFacts.didPreserveStyleRollbackBoundary &&
        inputActionFirstSliceFacts.didPrepareStage214ActionPreviewPacketInput &&
        intentFacts.didMaterializeButtonLikeActionIntentFacts &&
        intentFacts.didBindEnabledPredicateToActionIntent
    let stopLineReady =
        inputActionFirstSliceFacts.didKeepPublicComponentApiBlocked &&
        inputActionFirstSliceFacts.didKeepLayoutEngineBlocked &&
        inputActionFirstSliceFacts.didKeepInputEventPipelineExecutionBlocked &&
        inputActionFirstSliceFacts.didKeepActionDispatchBlocked &&
        inputActionFirstSliceFacts.didKeepRendererSubmissionBlocked &&
        inputActionFirstSliceFacts.didKeepRendererStateWriteBlocked &&
        inputActionFirstSliceFacts.didKeepRuntimeStateWriteBlocked &&
        inputActionFirstSliceFacts.didKeepVisibilityNotPublished

    return CjguiInternalRendererStage213InputActionFirstSliceReadiness(
        uiFrameworkRunwayReadinessDecision,
        inputActionFirstSliceFacts,
        firstSliceReady && stopLineReady,
        firstSliceReady && stopLineReady,
        intentFacts.didMaterializeButtonLikeActionIntentFacts,
        inputActionFirstSliceFacts.didBindActionIntentToSemanticNode,
        intentFacts.didBindEnabledPredicateToActionIntent,
        inputActionFirstSliceFacts
            .didBindActionIntentToStyledComponentPreviewPacket,
        inputActionFirstSliceFacts.didPreserveStyleRollbackBoundary,
        inputActionFirstSliceFacts.didPrepareStage214ActionPreviewPacketInput,
        false,
        inputActionFirstSliceFacts.didKeepActionDispatchBlocked,
        false,
        false,
        inputActionFirstSliceFacts.didKeepRendererSubmissionBlocked,
        inputActionFirstSliceFacts.didKeepRendererStateWriteBlocked,
        inputActionFirstSliceFacts.didKeepRuntimeStateWriteBlocked,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage213InputActionFirstSliceDraft():
    CjguiInternalRendererStage213InputActionFirstSliceReadiness {
    let uiDecision =
        cjguiInternalExecuteDefaultRendererStage212UiFrameworkRunwayReadinessDecisionDraft()
    let intentFacts = cjguiInternalBuildRendererStage213InputActionIntentFacts()
    let firstSliceFacts =
        cjguiInternalBuildRendererStage213InputActionFirstSliceFacts(
            uiDecision,
            intentFacts
        )
    return cjguiInternalBuildRendererStage213InputActionFirstSliceReadiness(
        uiDecision,
        firstSliceFacts
    )
}
