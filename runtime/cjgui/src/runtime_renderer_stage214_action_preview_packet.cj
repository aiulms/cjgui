// 中文维护注释：本文件是 stage214 action preview packet owner。
// Owner: 消费 stage213 input/action first-slice，把 action intent 绑定到
// styled component preview packet 与 owner-local rollback boundary。
// Truth: action preview packet 是可解释预览，不是 action dispatch。
// Stop-line: 不执行 input pipeline，不发布 visibility，不写 renderer/runtime state。
package cjgui

struct CjguiInternalRendererStage214ActionPreviewPacketFacts {
    let didConsumeStage213InputActionFirstSlice: Bool
    let didJoinActionIntentWithStyledComponentPreviewPacket: Bool
    let didMaterializeActionPreviewPacket: Bool
    let didBindActionPreviewToOwnerLocalRollbackBoundary: Bool
    let didBindActionPreviewToSemanticNode: Bool
    let didPreserveActionPreviewNonDispatching: Bool
    let didPrepareStage215ActionSemanticDiffInput: Bool
    let didKeepInputEventPipelineExecutionBlocked: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepLayoutEngineBlocked: Bool
    let didKeepVisibilityNotPublished: Bool

    init(
        didConsumeStage213InputActionFirstSlice: Bool,
        didJoinActionIntentWithStyledComponentPreviewPacket: Bool,
        didMaterializeActionPreviewPacket: Bool,
        didBindActionPreviewToOwnerLocalRollbackBoundary: Bool,
        didBindActionPreviewToSemanticNode: Bool,
        didPreserveActionPreviewNonDispatching: Bool,
        didPrepareStage215ActionSemanticDiffInput: Bool,
        didKeepInputEventPipelineExecutionBlocked: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepLayoutEngineBlocked: Bool,
        didKeepVisibilityNotPublished: Bool
    ) {
        this.didConsumeStage213InputActionFirstSlice =
            didConsumeStage213InputActionFirstSlice
        this.didJoinActionIntentWithStyledComponentPreviewPacket =
            didJoinActionIntentWithStyledComponentPreviewPacket
        this.didMaterializeActionPreviewPacket =
            didMaterializeActionPreviewPacket
        this.didBindActionPreviewToOwnerLocalRollbackBoundary =
            didBindActionPreviewToOwnerLocalRollbackBoundary
        this.didBindActionPreviewToSemanticNode =
            didBindActionPreviewToSemanticNode
        this.didPreserveActionPreviewNonDispatching =
            didPreserveActionPreviewNonDispatching
        this.didPrepareStage215ActionSemanticDiffInput =
            didPrepareStage215ActionSemanticDiffInput
        this.didKeepInputEventPipelineExecutionBlocked =
            didKeepInputEventPipelineExecutionBlocked
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didKeepPublicComponentApiBlocked =
            didKeepPublicComponentApiBlocked
        this.didKeepLayoutEngineBlocked = didKeepLayoutEngineBlocked
        this.didKeepVisibilityNotPublished = didKeepVisibilityNotPublished
    }
}

struct CjguiInternalRendererStage214ActionPreviewPacketReadiness {
    let inputActionFirstSlice:
        CjguiInternalRendererStage213InputActionFirstSliceReadiness
    let actionPreviewPacketFacts:
        CjguiInternalRendererStage214ActionPreviewPacketFacts
    let didPrepareStage214ActionPreviewPacketReadiness: Bool
    let didConfirmActionPreviewPacketReady: Bool
    let didConfirmActionIntentJoinedWithStyledComponentPreviewPacket: Bool
    let didConfirmActionPreviewPacketMaterialized: Bool
    let didConfirmActionPreviewBoundToOwnerLocalRollbackBoundary: Bool
    let didConfirmActionPreviewBoundToSemanticNode: Bool
    let didConfirmActionPreviewNonDispatching: Bool
    let didConfirmStage215ActionSemanticDiffInputPrepared: Bool
    let didConfirmInputEventPipelineExecuted: Bool
    let didConfirmActionDispatchExecuted: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmLayoutEngineEnabled: Bool
    let didConfirmVisibilityPublished: Bool

    init(
        inputActionFirstSlice:
            CjguiInternalRendererStage213InputActionFirstSliceReadiness,
        actionPreviewPacketFacts:
            CjguiInternalRendererStage214ActionPreviewPacketFacts,
        didPrepareStage214ActionPreviewPacketReadiness: Bool,
        didConfirmActionPreviewPacketReady: Bool,
        didConfirmActionIntentJoinedWithStyledComponentPreviewPacket: Bool,
        didConfirmActionPreviewPacketMaterialized: Bool,
        didConfirmActionPreviewBoundToOwnerLocalRollbackBoundary: Bool,
        didConfirmActionPreviewBoundToSemanticNode: Bool,
        didConfirmActionPreviewNonDispatching: Bool,
        didConfirmStage215ActionSemanticDiffInputPrepared: Bool,
        didConfirmInputEventPipelineExecuted: Bool,
        didConfirmActionDispatchExecuted: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmLayoutEngineEnabled: Bool,
        didConfirmVisibilityPublished: Bool
    ) {
        this.inputActionFirstSlice = inputActionFirstSlice
        this.actionPreviewPacketFacts = actionPreviewPacketFacts
        this.didPrepareStage214ActionPreviewPacketReadiness =
            didPrepareStage214ActionPreviewPacketReadiness
        this.didConfirmActionPreviewPacketReady =
            didConfirmActionPreviewPacketReady
        this.didConfirmActionIntentJoinedWithStyledComponentPreviewPacket =
            didConfirmActionIntentJoinedWithStyledComponentPreviewPacket
        this.didConfirmActionPreviewPacketMaterialized =
            didConfirmActionPreviewPacketMaterialized
        this.didConfirmActionPreviewBoundToOwnerLocalRollbackBoundary =
            didConfirmActionPreviewBoundToOwnerLocalRollbackBoundary
        this.didConfirmActionPreviewBoundToSemanticNode =
            didConfirmActionPreviewBoundToSemanticNode
        this.didConfirmActionPreviewNonDispatching =
            didConfirmActionPreviewNonDispatching
        this.didConfirmStage215ActionSemanticDiffInputPrepared =
            didConfirmStage215ActionSemanticDiffInputPrepared
        this.didConfirmInputEventPipelineExecuted =
            didConfirmInputEventPipelineExecuted
        this.didConfirmActionDispatchExecuted =
            didConfirmActionDispatchExecuted
        this.didConfirmRendererSubmissionBlocked =
            didConfirmRendererSubmissionBlocked
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked =
            didConfirmRuntimeStateWriteBlocked
        this.didConfirmPublicComponentApiAdded =
            didConfirmPublicComponentApiAdded
        this.didConfirmLayoutEngineEnabled = didConfirmLayoutEngineEnabled
        this.didConfirmVisibilityPublished = didConfirmVisibilityPublished
    }
}

func cjguiInternalBuildRendererStage214ActionPreviewPacketFacts(
    inputActionFirstSlice:
        CjguiInternalRendererStage213InputActionFirstSliceReadiness
): CjguiInternalRendererStage214ActionPreviewPacketFacts {
    let uiDecision =
        inputActionFirstSlice.uiFrameworkRunwayReadinessDecision
    let layoutStyleSemanticDiffExplain =
        uiDecision.layoutStyleSemanticDiffExplain
    let styledPreview =
        layoutStyleSemanticDiffExplain.styledComponentPreviewPacket

    return CjguiInternalRendererStage214ActionPreviewPacketFacts(
        inputActionFirstSlice.didConfirmInputActionFirstSliceReady,
        inputActionFirstSlice
            .didConfirmActionIntentBoundToStyledComponentPreviewPacket &&
            styledPreview.didConfirmStyledComponentPreviewPacketReady,
        true,
        inputActionFirstSlice.didConfirmStyleRollbackBoundaryPreserved &&
            layoutStyleSemanticDiffExplain
                .didConfirmStyleRollbackReadyBoundaryMaterialized,
        inputActionFirstSlice.didConfirmActionIntentBoundToSemanticNode,
        inputActionFirstSlice.didConfirmActionDispatchBlocked,
        true,
        inputActionFirstSlice.didConfirmInputEventPipelineExecuted == false,
        inputActionFirstSlice.didConfirmActionDispatchBlocked,
        inputActionFirstSlice.didConfirmRendererSubmissionBlocked,
        inputActionFirstSlice.didConfirmRendererStateWriteBlocked,
        inputActionFirstSlice.didConfirmRuntimeStateWriteBlocked,
        inputActionFirstSlice.didConfirmPublicComponentApiAdded == false,
        inputActionFirstSlice.didConfirmLayoutEngineEnabled == false,
        inputActionFirstSlice.didConfirmVisibilityPublished == false
    )
}

func cjguiInternalBuildRendererStage214ActionPreviewPacketReadiness(
    inputActionFirstSlice:
        CjguiInternalRendererStage213InputActionFirstSliceReadiness,
    actionPreviewPacketFacts:
        CjguiInternalRendererStage214ActionPreviewPacketFacts
): CjguiInternalRendererStage214ActionPreviewPacketReadiness {
    let previewReady =
        actionPreviewPacketFacts.didConsumeStage213InputActionFirstSlice &&
        actionPreviewPacketFacts
            .didJoinActionIntentWithStyledComponentPreviewPacket &&
        actionPreviewPacketFacts.didMaterializeActionPreviewPacket &&
        actionPreviewPacketFacts
            .didBindActionPreviewToOwnerLocalRollbackBoundary &&
        actionPreviewPacketFacts.didBindActionPreviewToSemanticNode &&
        actionPreviewPacketFacts.didPreserveActionPreviewNonDispatching &&
        actionPreviewPacketFacts.didPrepareStage215ActionSemanticDiffInput
    let stopLineReady =
        actionPreviewPacketFacts.didKeepInputEventPipelineExecutionBlocked &&
        actionPreviewPacketFacts.didKeepActionDispatchBlocked &&
        actionPreviewPacketFacts.didKeepRendererSubmissionBlocked &&
        actionPreviewPacketFacts.didKeepRendererStateWriteBlocked &&
        actionPreviewPacketFacts.didKeepRuntimeStateWriteBlocked &&
        actionPreviewPacketFacts.didKeepPublicComponentApiBlocked &&
        actionPreviewPacketFacts.didKeepLayoutEngineBlocked &&
        actionPreviewPacketFacts.didKeepVisibilityNotPublished

    return CjguiInternalRendererStage214ActionPreviewPacketReadiness(
        inputActionFirstSlice,
        actionPreviewPacketFacts,
        previewReady && stopLineReady,
        previewReady && stopLineReady,
        actionPreviewPacketFacts
            .didJoinActionIntentWithStyledComponentPreviewPacket,
        actionPreviewPacketFacts.didMaterializeActionPreviewPacket,
        actionPreviewPacketFacts
            .didBindActionPreviewToOwnerLocalRollbackBoundary,
        actionPreviewPacketFacts.didBindActionPreviewToSemanticNode,
        actionPreviewPacketFacts.didPreserveActionPreviewNonDispatching,
        actionPreviewPacketFacts.didPrepareStage215ActionSemanticDiffInput,
        false,
        false,
        actionPreviewPacketFacts.didKeepRendererSubmissionBlocked,
        actionPreviewPacketFacts.didKeepRendererStateWriteBlocked,
        actionPreviewPacketFacts.didKeepRuntimeStateWriteBlocked,
        false,
        false,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage214ActionPreviewPacketDraft():
    CjguiInternalRendererStage214ActionPreviewPacketReadiness {
    let inputAction =
        cjguiInternalExecuteDefaultRendererStage213InputActionFirstSliceDraft()
    let facts =
        cjguiInternalBuildRendererStage214ActionPreviewPacketFacts(
            inputAction
        )
    return cjguiInternalBuildRendererStage214ActionPreviewPacketReadiness(
        inputAction,
        facts
    )
}
