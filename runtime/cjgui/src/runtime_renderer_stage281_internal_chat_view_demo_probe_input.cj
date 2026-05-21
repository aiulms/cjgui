// 中文维护注释：本文件是 stage281 internal chat view demo probe input owner。
// Owner: 消费 stage280 chat view readiness decision，形成 chat probe 的 owner-local 输入包。
// Truth: probe input 只描述 message append / composer clear / pending delivery 的 dry-run 输入。
// Stop-line: 不提交 state、不提交 renderer、不写 renderer/runtime state、不发布 visibility。
// Same-shape Boundary Brake: 下一步必须产出 result envelope，不再复制 chat readiness 包装。
package cjgui

struct CjguiInternalRendererStage281InternalChatViewDemoProbeInputFacts {
    let didConsumeStage280InternalChatViewDemoReadinessDecision: Bool
    let didMaterializeInternalChatViewDemoProbeInput: Bool
    let didBindChatProbeInputToMessageAppendIntent: Bool
    let didBindChatProbeInputToComposerClearIntent: Bool
    let didBindChatProbeInputToPendingDeliveryIntent: Bool
    let didBindChatProbeInputToOwnerLocalStateDelta: Bool
    let didBindChatProbeInputToRenderCommandPreview: Bool
    let didBindChatProbeInputToRollbackReadyBoundary: Bool
    let didBindChatProbeInputToVisibilityNotPublishedBoundary: Bool
    let didKeepChatProbeInputOwnerLocalInMemoryOnly: Bool
    let didKeepChatProbeInputNonExecuting: Bool
    let didPrepareStage282ChatViewDemoProbeResultEnvelopeInput: Bool
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didKeepBackendReadyTruthBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepVisibilityNotPublished: Bool

    init(
        didConsumeStage280InternalChatViewDemoReadinessDecision: Bool,
        didMaterializeInternalChatViewDemoProbeInput: Bool,
        didBindChatProbeInputToMessageAppendIntent: Bool,
        didBindChatProbeInputToComposerClearIntent: Bool,
        didBindChatProbeInputToPendingDeliveryIntent: Bool,
        didBindChatProbeInputToOwnerLocalStateDelta: Bool,
        didBindChatProbeInputToRenderCommandPreview: Bool,
        didBindChatProbeInputToRollbackReadyBoundary: Bool,
        didBindChatProbeInputToVisibilityNotPublishedBoundary: Bool,
        didKeepChatProbeInputOwnerLocalInMemoryOnly: Bool,
        didKeepChatProbeInputNonExecuting: Bool,
        didPrepareStage282ChatViewDemoProbeResultEnvelopeInput: Bool,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didKeepBackendReadyTruthBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepVisibilityNotPublished: Bool
    ) {
        this.didConsumeStage280InternalChatViewDemoReadinessDecision =
            didConsumeStage280InternalChatViewDemoReadinessDecision
        this.didMaterializeInternalChatViewDemoProbeInput =
            didMaterializeInternalChatViewDemoProbeInput
        this.didBindChatProbeInputToMessageAppendIntent =
            didBindChatProbeInputToMessageAppendIntent
        this.didBindChatProbeInputToComposerClearIntent =
            didBindChatProbeInputToComposerClearIntent
        this.didBindChatProbeInputToPendingDeliveryIntent =
            didBindChatProbeInputToPendingDeliveryIntent
        this.didBindChatProbeInputToOwnerLocalStateDelta =
            didBindChatProbeInputToOwnerLocalStateDelta
        this.didBindChatProbeInputToRenderCommandPreview =
            didBindChatProbeInputToRenderCommandPreview
        this.didBindChatProbeInputToRollbackReadyBoundary =
            didBindChatProbeInputToRollbackReadyBoundary
        this.didBindChatProbeInputToVisibilityNotPublishedBoundary =
            didBindChatProbeInputToVisibilityNotPublishedBoundary
        this.didKeepChatProbeInputOwnerLocalInMemoryOnly =
            didKeepChatProbeInputOwnerLocalInMemoryOnly
        this.didKeepChatProbeInputNonExecuting =
            didKeepChatProbeInputNonExecuting
        this.didPrepareStage282ChatViewDemoProbeResultEnvelopeInput =
            didPrepareStage282ChatViewDemoProbeResultEnvelopeInput
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didKeepOwnerAcceptanceNotGranted =
            didKeepOwnerAcceptanceNotGranted
        this.didKeepBackendReadyTruthBlocked =
            didKeepBackendReadyTruthBlocked
        this.didKeepPublicComponentApiBlocked =
            didKeepPublicComponentApiBlocked
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepStateUpdateCommittedBlocked =
            didKeepStateUpdateCommittedBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didKeepVisibilityNotPublished = didKeepVisibilityNotPublished
    }
}

struct CjguiInternalRendererStage281InternalChatViewDemoProbeInputReadiness {
    let internalChatViewDemoReadinessDecision:
        CjguiInternalRendererStage280InternalChatViewDemoReadinessDecisionReadiness
    let internalChatViewDemoProbeInputFacts:
        CjguiInternalRendererStage281InternalChatViewDemoProbeInputFacts
    let didPrepareStage281InternalChatViewDemoProbeInputReadiness: Bool
    let didConfirmInternalChatViewDemoProbeInputReady: Bool
    let didConfirmChatViewDemoProbeInputMaterialized: Bool
    let didConfirmChatProbeInputBoundToMessageAppendIntent: Bool
    let didConfirmChatProbeInputBoundToComposerClearIntent: Bool
    let didConfirmChatProbeInputBoundToPendingDeliveryIntent: Bool
    let didConfirmChatProbeInputBoundToOwnerLocalStateDelta: Bool
    let didConfirmChatProbeInputBoundToRenderCommandPreview: Bool
    let didConfirmChatProbeInputBoundToRollbackReadyBoundary: Bool
    let didConfirmChatProbeInputBoundToVisibilityNotPublishedBoundary: Bool
    let didConfirmChatProbeInputOwnerLocalInMemoryOnly: Bool
    let didConfirmChatProbeInputNonExecuting: Bool
    let didConfirmStage282ChatViewDemoProbeResultEnvelopeInputPrepared: Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmBackendReadyTruth: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmActionDispatch: Bool
    let didConfirmStateUpdateCommitted: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmVisibilityPublished: Bool

    init(
        internalChatViewDemoReadinessDecision:
            CjguiInternalRendererStage280InternalChatViewDemoReadinessDecisionReadiness,
        internalChatViewDemoProbeInputFacts:
            CjguiInternalRendererStage281InternalChatViewDemoProbeInputFacts,
        didPrepareStage281InternalChatViewDemoProbeInputReadiness: Bool,
        didConfirmInternalChatViewDemoProbeInputReady: Bool,
        didConfirmChatViewDemoProbeInputMaterialized: Bool,
        didConfirmChatProbeInputBoundToMessageAppendIntent: Bool,
        didConfirmChatProbeInputBoundToComposerClearIntent: Bool,
        didConfirmChatProbeInputBoundToPendingDeliveryIntent: Bool,
        didConfirmChatProbeInputBoundToOwnerLocalStateDelta: Bool,
        didConfirmChatProbeInputBoundToRenderCommandPreview: Bool,
        didConfirmChatProbeInputBoundToRollbackReadyBoundary: Bool,
        didConfirmChatProbeInputBoundToVisibilityNotPublishedBoundary: Bool,
        didConfirmChatProbeInputOwnerLocalInMemoryOnly: Bool,
        didConfirmChatProbeInputNonExecuting: Bool,
        didConfirmStage282ChatViewDemoProbeResultEnvelopeInputPrepared: Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmBackendReadyTruth: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmActionDispatch: Bool,
        didConfirmStateUpdateCommitted: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmVisibilityPublished: Bool
    ) {
        this.internalChatViewDemoReadinessDecision =
            internalChatViewDemoReadinessDecision
        this.internalChatViewDemoProbeInputFacts =
            internalChatViewDemoProbeInputFacts
        this.didPrepareStage281InternalChatViewDemoProbeInputReadiness =
            didPrepareStage281InternalChatViewDemoProbeInputReadiness
        this.didConfirmInternalChatViewDemoProbeInputReady =
            didConfirmInternalChatViewDemoProbeInputReady
        this.didConfirmChatViewDemoProbeInputMaterialized =
            didConfirmChatViewDemoProbeInputMaterialized
        this.didConfirmChatProbeInputBoundToMessageAppendIntent =
            didConfirmChatProbeInputBoundToMessageAppendIntent
        this.didConfirmChatProbeInputBoundToComposerClearIntent =
            didConfirmChatProbeInputBoundToComposerClearIntent
        this.didConfirmChatProbeInputBoundToPendingDeliveryIntent =
            didConfirmChatProbeInputBoundToPendingDeliveryIntent
        this.didConfirmChatProbeInputBoundToOwnerLocalStateDelta =
            didConfirmChatProbeInputBoundToOwnerLocalStateDelta
        this.didConfirmChatProbeInputBoundToRenderCommandPreview =
            didConfirmChatProbeInputBoundToRenderCommandPreview
        this.didConfirmChatProbeInputBoundToRollbackReadyBoundary =
            didConfirmChatProbeInputBoundToRollbackReadyBoundary
        this.didConfirmChatProbeInputBoundToVisibilityNotPublishedBoundary =
            didConfirmChatProbeInputBoundToVisibilityNotPublishedBoundary
        this.didConfirmChatProbeInputOwnerLocalInMemoryOnly =
            didConfirmChatProbeInputOwnerLocalInMemoryOnly
        this.didConfirmChatProbeInputNonExecuting =
            didConfirmChatProbeInputNonExecuting
        this.didConfirmStage282ChatViewDemoProbeResultEnvelopeInputPrepared =
            didConfirmStage282ChatViewDemoProbeResultEnvelopeInputPrepared
        this.didConfirmOwnerAcceptanceRequired =
            didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted =
            didConfirmOwnerAcceptanceGranted
        this.didConfirmBackendReadyTruth = didConfirmBackendReadyTruth
        this.didConfirmPublicComponentApiAdded =
            didConfirmPublicComponentApiAdded
        this.didConfirmActionDispatch = didConfirmActionDispatch
        this.didConfirmStateUpdateCommitted = didConfirmStateUpdateCommitted
        this.didConfirmRendererSubmissionBlocked =
            didConfirmRendererSubmissionBlocked
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked =
            didConfirmRuntimeStateWriteBlocked
        this.didConfirmVisibilityPublished = didConfirmVisibilityPublished
    }
}

func cjguiInternalBuildRendererStage281InternalChatViewDemoProbeInputFacts(
    internalChatViewDemoReadinessDecision:
        CjguiInternalRendererStage280InternalChatViewDemoReadinessDecisionReadiness
): CjguiInternalRendererStage281InternalChatViewDemoProbeInputFacts {
    let renderPreview =
        internalChatViewDemoReadinessDecision
            .internalChatViewDemoRenderCommandPreview
    let stateDryRun = renderPreview.internalChatViewDemoStateUpdateDryRun
    let intentPacket = stateDryRun.internalChatViewDemoIntentPacket

    return CjguiInternalRendererStage281InternalChatViewDemoProbeInputFacts(
        internalChatViewDemoReadinessDecision
            .didConfirmInternalChatViewDemoReadinessDecisionReady,
        true,
        intentPacket.didConfirmChatMessageListIntentSemanticNodeMaterialized &&
            intentPacket.didConfirmChatSendIntentSemanticNodeMaterialized,
        intentPacket.didConfirmChatComposerIntentSemanticNodeMaterialized &&
            intentPacket.didConfirmChatSendIntentSemanticNodeMaterialized,
        stateDryRun.didConfirmChatPendingDeliveryStateDeltaDryRunMaterialized &&
            intentPacket.didConfirmChatSendIntentSemanticNodeMaterialized,
        stateDryRun.didConfirmChatMessageAppendStateDeltaDryRunMaterialized &&
            stateDryRun.didConfirmChatComposerClearStateDeltaDryRunMaterialized &&
            stateDryRun.didConfirmChatPendingDeliveryStateDeltaDryRunMaterialized,
        renderPreview.didConfirmInternalChatViewDemoRenderCommandPreviewReady &&
            renderPreview
                .didConfirmChatRenderPreviewBoundToRenderCommandRefreshRequirement,
        internalChatViewDemoReadinessDecision
            .didConfirmChatViewJoinedWithRollbackReadyBoundary,
        internalChatViewDemoReadinessDecision
            .didConfirmChatViewJoinedWithVisibilityNotPublishedBoundary,
        internalChatViewDemoReadinessDecision
            .didConfirmStateUpdateCommitted == false &&
            internalChatViewDemoReadinessDecision
                .didConfirmVisibilityPublished == false,
        internalChatViewDemoReadinessDecision.didConfirmActionDispatch == false &&
            internalChatViewDemoReadinessDecision
                .didConfirmRendererSubmissionBlocked,
        true,
        internalChatViewDemoReadinessDecision.didConfirmOwnerAcceptanceRequired,
        internalChatViewDemoReadinessDecision
            .didConfirmOwnerAcceptanceGranted == false,
        internalChatViewDemoReadinessDecision.didConfirmBackendReadyTruth ==
            false,
        internalChatViewDemoReadinessDecision
            .didConfirmPublicComponentApiAdded == false,
        internalChatViewDemoReadinessDecision.didConfirmActionDispatch == false,
        internalChatViewDemoReadinessDecision
            .didConfirmStateUpdateCommitted == false,
        internalChatViewDemoReadinessDecision.didConfirmRendererSubmissionBlocked,
        internalChatViewDemoReadinessDecision.didConfirmRendererStateWriteBlocked,
        internalChatViewDemoReadinessDecision.didConfirmRuntimeStateWriteBlocked,
        internalChatViewDemoReadinessDecision.didConfirmVisibilityPublished ==
            false
    )
}

func cjguiInternalBuildRendererStage281InternalChatViewDemoProbeInputReadiness(
    internalChatViewDemoReadinessDecision:
        CjguiInternalRendererStage280InternalChatViewDemoReadinessDecisionReadiness,
    internalChatViewDemoProbeInputFacts:
        CjguiInternalRendererStage281InternalChatViewDemoProbeInputFacts
): CjguiInternalRendererStage281InternalChatViewDemoProbeInputReadiness {
    let probeInputReady =
        internalChatViewDemoProbeInputFacts
            .didConsumeStage280InternalChatViewDemoReadinessDecision &&
        internalChatViewDemoProbeInputFacts
            .didMaterializeInternalChatViewDemoProbeInput &&
        internalChatViewDemoProbeInputFacts
            .didBindChatProbeInputToMessageAppendIntent &&
        internalChatViewDemoProbeInputFacts
            .didBindChatProbeInputToComposerClearIntent &&
        internalChatViewDemoProbeInputFacts
            .didBindChatProbeInputToPendingDeliveryIntent &&
        internalChatViewDemoProbeInputFacts
            .didBindChatProbeInputToOwnerLocalStateDelta &&
        internalChatViewDemoProbeInputFacts
            .didBindChatProbeInputToRenderCommandPreview &&
        internalChatViewDemoProbeInputFacts
            .didBindChatProbeInputToRollbackReadyBoundary &&
        internalChatViewDemoProbeInputFacts
            .didBindChatProbeInputToVisibilityNotPublishedBoundary &&
        internalChatViewDemoProbeInputFacts
            .didKeepChatProbeInputOwnerLocalInMemoryOnly &&
        internalChatViewDemoProbeInputFacts.didKeepChatProbeInputNonExecuting &&
        internalChatViewDemoProbeInputFacts
            .didPrepareStage282ChatViewDemoProbeResultEnvelopeInput
    let stopLineReady =
        internalChatViewDemoProbeInputFacts.didKeepOwnerAcceptanceRequired &&
        internalChatViewDemoProbeInputFacts.didKeepOwnerAcceptanceNotGranted &&
        internalChatViewDemoProbeInputFacts.didKeepBackendReadyTruthBlocked &&
        internalChatViewDemoProbeInputFacts.didKeepPublicComponentApiBlocked &&
        internalChatViewDemoProbeInputFacts.didKeepActionDispatchBlocked &&
        internalChatViewDemoProbeInputFacts.didKeepStateUpdateCommittedBlocked &&
        internalChatViewDemoProbeInputFacts.didKeepRendererSubmissionBlocked &&
        internalChatViewDemoProbeInputFacts.didKeepRendererStateWriteBlocked &&
        internalChatViewDemoProbeInputFacts.didKeepRuntimeStateWriteBlocked &&
        internalChatViewDemoProbeInputFacts.didKeepVisibilityNotPublished

    return CjguiInternalRendererStage281InternalChatViewDemoProbeInputReadiness(
        internalChatViewDemoReadinessDecision,
        internalChatViewDemoProbeInputFacts,
        probeInputReady && stopLineReady,
        probeInputReady && stopLineReady,
        internalChatViewDemoProbeInputFacts
            .didMaterializeInternalChatViewDemoProbeInput,
        internalChatViewDemoProbeInputFacts
            .didBindChatProbeInputToMessageAppendIntent,
        internalChatViewDemoProbeInputFacts
            .didBindChatProbeInputToComposerClearIntent,
        internalChatViewDemoProbeInputFacts
            .didBindChatProbeInputToPendingDeliveryIntent,
        internalChatViewDemoProbeInputFacts
            .didBindChatProbeInputToOwnerLocalStateDelta,
        internalChatViewDemoProbeInputFacts
            .didBindChatProbeInputToRenderCommandPreview,
        internalChatViewDemoProbeInputFacts
            .didBindChatProbeInputToRollbackReadyBoundary,
        internalChatViewDemoProbeInputFacts
            .didBindChatProbeInputToVisibilityNotPublishedBoundary,
        internalChatViewDemoProbeInputFacts
            .didKeepChatProbeInputOwnerLocalInMemoryOnly,
        internalChatViewDemoProbeInputFacts.didKeepChatProbeInputNonExecuting,
        internalChatViewDemoProbeInputFacts
            .didPrepareStage282ChatViewDemoProbeResultEnvelopeInput,
        internalChatViewDemoProbeInputFacts.didKeepOwnerAcceptanceRequired,
        false,
        false,
        false,
        false,
        false,
        internalChatViewDemoProbeInputFacts.didKeepRendererSubmissionBlocked,
        internalChatViewDemoProbeInputFacts.didKeepRendererStateWriteBlocked,
        internalChatViewDemoProbeInputFacts.didKeepRuntimeStateWriteBlocked,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage281InternalChatViewDemoProbeInputDraft():
    CjguiInternalRendererStage281InternalChatViewDemoProbeInputReadiness {
    let decision =
        cjguiInternalExecuteDefaultRendererStage280InternalChatViewDemoReadinessDecisionDraft()
    let facts =
        cjguiInternalBuildRendererStage281InternalChatViewDemoProbeInputFacts(
            decision
        )
    return cjguiInternalBuildRendererStage281InternalChatViewDemoProbeInputReadiness(
        decision,
        facts
    )
}
