// 中文维护注释：本文件是 stage239 backend adapter rollback/visibility boundary owner。
// Owner: 消费 stage238 no-submit predicate，生成 rollback-ready result envelope
// 与 visibility-not-published boundary 的 owner-local value。
// Truth: boundary 不发布 visibility，不代表 renderer/backend 可提交。
// Stop-line: 不提交 renderer，不写 renderer/runtime state，不扩 native bridge。
package cjgui

struct CjguiInternalRendererStage239BackendAdapterRollbackVisibilityBoundaryFacts {
    let didConsumeStage238BackendAdapterNoSubmitPredicate: Bool
    let didMaterializeBackendAdapterRollbackVisibilityBoundary: Bool
    let didBindRollbackBoundaryToNoSubmitPredicate: Bool
    let didConfirmRollbackReadyResultEnvelope: Bool
    let didConfirmVisibilityNotPublishedBoundary: Bool
    let didPreserveBackendAdapterRollbackBoundaryValueOnly: Bool
    let didPrepareStage240BackendAdapterReadinessDecisionInput: Bool
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didKeepBackendReadyTruthBlocked: Bool
    let didKeepBackendImplementationBlocked: Bool
    let didKeepPlatformCommandBufferBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepNativeBridgeExpansionBlocked: Bool
    let didKeepVisibilityNotPublished: Bool

    init(
        didConsumeStage238BackendAdapterNoSubmitPredicate: Bool,
        didMaterializeBackendAdapterRollbackVisibilityBoundary: Bool,
        didBindRollbackBoundaryToNoSubmitPredicate: Bool,
        didConfirmRollbackReadyResultEnvelope: Bool,
        didConfirmVisibilityNotPublishedBoundary: Bool,
        didPreserveBackendAdapterRollbackBoundaryValueOnly: Bool,
        didPrepareStage240BackendAdapterReadinessDecisionInput: Bool,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didKeepBackendReadyTruthBlocked: Bool,
        didKeepBackendImplementationBlocked: Bool,
        didKeepPlatformCommandBufferBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepNativeBridgeExpansionBlocked: Bool,
        didKeepVisibilityNotPublished: Bool
    ) {
        this.didConsumeStage238BackendAdapterNoSubmitPredicate =
            didConsumeStage238BackendAdapterNoSubmitPredicate
        this.didMaterializeBackendAdapterRollbackVisibilityBoundary =
            didMaterializeBackendAdapterRollbackVisibilityBoundary
        this.didBindRollbackBoundaryToNoSubmitPredicate =
            didBindRollbackBoundaryToNoSubmitPredicate
        this.didConfirmRollbackReadyResultEnvelope =
            didConfirmRollbackReadyResultEnvelope
        this.didConfirmVisibilityNotPublishedBoundary =
            didConfirmVisibilityNotPublishedBoundary
        this.didPreserveBackendAdapterRollbackBoundaryValueOnly =
            didPreserveBackendAdapterRollbackBoundaryValueOnly
        this.didPrepareStage240BackendAdapterReadinessDecisionInput =
            didPrepareStage240BackendAdapterReadinessDecisionInput
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didKeepOwnerAcceptanceNotGranted =
            didKeepOwnerAcceptanceNotGranted
        this.didKeepBackendReadyTruthBlocked =
            didKeepBackendReadyTruthBlocked
        this.didKeepBackendImplementationBlocked =
            didKeepBackendImplementationBlocked
        this.didKeepPlatformCommandBufferBlocked =
            didKeepPlatformCommandBufferBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didKeepNativeBridgeExpansionBlocked =
            didKeepNativeBridgeExpansionBlocked
        this.didKeepVisibilityNotPublished = didKeepVisibilityNotPublished
    }
}

struct CjguiInternalRendererStage239BackendAdapterRollbackVisibilityBoundaryReadiness {
    let backendAdapterNoSubmitPredicate:
        CjguiInternalRendererStage238BackendAdapterNoSubmitPredicateReadiness
    let backendAdapterRollbackVisibilityBoundaryFacts:
        CjguiInternalRendererStage239BackendAdapterRollbackVisibilityBoundaryFacts
    let didPrepareStage239BackendAdapterRollbackVisibilityBoundaryReadiness:
        Bool
    let didConfirmBackendAdapterRollbackVisibilityBoundaryReady: Bool
    let didConfirmBackendAdapterRollbackVisibilityBoundaryMaterialized: Bool
    let didConfirmRollbackBoundaryBoundToNoSubmitPredicate: Bool
    let didConfirmRollbackReadyResultEnvelope: Bool
    let didConfirmVisibilityNotPublishedBoundary: Bool
    let didConfirmStage240BackendAdapterReadinessDecisionInputPrepared: Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmBackendReadyTruth: Bool
    let didConfirmBackendImplementationBlocked: Bool
    let didConfirmPlatformCommandBufferBlocked: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmNativeBridgeExpansionBlocked: Bool
    let didConfirmVisibilityPublished: Bool

    init(
        backendAdapterNoSubmitPredicate:
            CjguiInternalRendererStage238BackendAdapterNoSubmitPredicateReadiness,
        backendAdapterRollbackVisibilityBoundaryFacts:
            CjguiInternalRendererStage239BackendAdapterRollbackVisibilityBoundaryFacts,
        didPrepareStage239BackendAdapterRollbackVisibilityBoundaryReadiness:
            Bool,
        didConfirmBackendAdapterRollbackVisibilityBoundaryReady: Bool,
        didConfirmBackendAdapterRollbackVisibilityBoundaryMaterialized: Bool,
        didConfirmRollbackBoundaryBoundToNoSubmitPredicate: Bool,
        didConfirmRollbackReadyResultEnvelope: Bool,
        didConfirmVisibilityNotPublishedBoundary: Bool,
        didConfirmStage240BackendAdapterReadinessDecisionInputPrepared: Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmBackendReadyTruth: Bool,
        didConfirmBackendImplementationBlocked: Bool,
        didConfirmPlatformCommandBufferBlocked: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmNativeBridgeExpansionBlocked: Bool,
        didConfirmVisibilityPublished: Bool
    ) {
        this.backendAdapterNoSubmitPredicate =
            backendAdapterNoSubmitPredicate
        this.backendAdapterRollbackVisibilityBoundaryFacts =
            backendAdapterRollbackVisibilityBoundaryFacts
        this.didPrepareStage239BackendAdapterRollbackVisibilityBoundaryReadiness =
            didPrepareStage239BackendAdapterRollbackVisibilityBoundaryReadiness
        this.didConfirmBackendAdapterRollbackVisibilityBoundaryReady =
            didConfirmBackendAdapterRollbackVisibilityBoundaryReady
        this.didConfirmBackendAdapterRollbackVisibilityBoundaryMaterialized =
            didConfirmBackendAdapterRollbackVisibilityBoundaryMaterialized
        this.didConfirmRollbackBoundaryBoundToNoSubmitPredicate =
            didConfirmRollbackBoundaryBoundToNoSubmitPredicate
        this.didConfirmRollbackReadyResultEnvelope =
            didConfirmRollbackReadyResultEnvelope
        this.didConfirmVisibilityNotPublishedBoundary =
            didConfirmVisibilityNotPublishedBoundary
        this.didConfirmStage240BackendAdapterReadinessDecisionInputPrepared =
            didConfirmStage240BackendAdapterReadinessDecisionInputPrepared
        this.didConfirmOwnerAcceptanceRequired =
            didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted =
            didConfirmOwnerAcceptanceGranted
        this.didConfirmBackendReadyTruth = didConfirmBackendReadyTruth
        this.didConfirmBackendImplementationBlocked =
            didConfirmBackendImplementationBlocked
        this.didConfirmPlatformCommandBufferBlocked =
            didConfirmPlatformCommandBufferBlocked
        this.didConfirmRendererSubmissionBlocked =
            didConfirmRendererSubmissionBlocked
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked =
            didConfirmRuntimeStateWriteBlocked
        this.didConfirmNativeBridgeExpansionBlocked =
            didConfirmNativeBridgeExpansionBlocked
        this.didConfirmVisibilityPublished = didConfirmVisibilityPublished
    }
}

func cjguiInternalBuildRendererStage239BackendAdapterRollbackVisibilityBoundaryFacts(
    backendAdapterNoSubmitPredicate:
        CjguiInternalRendererStage238BackendAdapterNoSubmitPredicateReadiness
): CjguiInternalRendererStage239BackendAdapterRollbackVisibilityBoundaryFacts {
    let predicateReady =
        backendAdapterNoSubmitPredicate
            .didConfirmBackendAdapterNoSubmitPredicateReady &&
        backendAdapterNoSubmitPredicate
            .didConfirmNoSubmitPredicateBoundToAdapterPreview

    return CjguiInternalRendererStage239BackendAdapterRollbackVisibilityBoundaryFacts(
        backendAdapterNoSubmitPredicate
            .didConfirmBackendAdapterNoSubmitPredicateReady,
        true,
        predicateReady,
        backendAdapterNoSubmitPredicate
            .didConfirmAdapterPredicateRejectsRendererSubmission,
        backendAdapterNoSubmitPredicate.didConfirmVisibilityPublished == false,
        true,
        true,
        backendAdapterNoSubmitPredicate.didConfirmOwnerAcceptanceRequired,
        backendAdapterNoSubmitPredicate
            .didConfirmOwnerAcceptanceGranted == false,
        backendAdapterNoSubmitPredicate.didConfirmBackendReadyTruth == false,
        backendAdapterNoSubmitPredicate.didConfirmBackendImplementationBlocked,
        backendAdapterNoSubmitPredicate.didConfirmPlatformCommandBufferBlocked,
        backendAdapterNoSubmitPredicate.didConfirmRendererSubmissionBlocked,
        backendAdapterNoSubmitPredicate.didConfirmRendererStateWriteBlocked,
        backendAdapterNoSubmitPredicate.didConfirmRuntimeStateWriteBlocked,
        backendAdapterNoSubmitPredicate.didConfirmNativeBridgeExpansionBlocked,
        backendAdapterNoSubmitPredicate.didConfirmVisibilityPublished == false
    )
}

func cjguiInternalBuildRendererStage239BackendAdapterRollbackVisibilityBoundaryReadiness(
    backendAdapterNoSubmitPredicate:
        CjguiInternalRendererStage238BackendAdapterNoSubmitPredicateReadiness,
    backendAdapterRollbackVisibilityBoundaryFacts:
        CjguiInternalRendererStage239BackendAdapterRollbackVisibilityBoundaryFacts
): CjguiInternalRendererStage239BackendAdapterRollbackVisibilityBoundaryReadiness {
    let boundaryReady =
        backendAdapterRollbackVisibilityBoundaryFacts
            .didConsumeStage238BackendAdapterNoSubmitPredicate &&
        backendAdapterRollbackVisibilityBoundaryFacts
            .didMaterializeBackendAdapterRollbackVisibilityBoundary &&
        backendAdapterRollbackVisibilityBoundaryFacts
            .didBindRollbackBoundaryToNoSubmitPredicate &&
        backendAdapterRollbackVisibilityBoundaryFacts
            .didConfirmRollbackReadyResultEnvelope &&
        backendAdapterRollbackVisibilityBoundaryFacts
            .didConfirmVisibilityNotPublishedBoundary &&
        backendAdapterRollbackVisibilityBoundaryFacts
            .didPreserveBackendAdapterRollbackBoundaryValueOnly &&
        backendAdapterRollbackVisibilityBoundaryFacts
            .didPrepareStage240BackendAdapterReadinessDecisionInput
    let stopLineReady =
        backendAdapterRollbackVisibilityBoundaryFacts
            .didKeepOwnerAcceptanceRequired &&
        backendAdapterRollbackVisibilityBoundaryFacts
            .didKeepOwnerAcceptanceNotGranted &&
        backendAdapterRollbackVisibilityBoundaryFacts
            .didKeepBackendReadyTruthBlocked &&
        backendAdapterRollbackVisibilityBoundaryFacts
            .didKeepBackendImplementationBlocked &&
        backendAdapterRollbackVisibilityBoundaryFacts
            .didKeepPlatformCommandBufferBlocked &&
        backendAdapterRollbackVisibilityBoundaryFacts
            .didKeepRendererSubmissionBlocked &&
        backendAdapterRollbackVisibilityBoundaryFacts
            .didKeepRendererStateWriteBlocked &&
        backendAdapterRollbackVisibilityBoundaryFacts
            .didKeepRuntimeStateWriteBlocked &&
        backendAdapterRollbackVisibilityBoundaryFacts
            .didKeepNativeBridgeExpansionBlocked &&
        backendAdapterRollbackVisibilityBoundaryFacts
            .didKeepVisibilityNotPublished

    return CjguiInternalRendererStage239BackendAdapterRollbackVisibilityBoundaryReadiness(
        backendAdapterNoSubmitPredicate,
        backendAdapterRollbackVisibilityBoundaryFacts,
        boundaryReady && stopLineReady,
        boundaryReady && stopLineReady,
        backendAdapterRollbackVisibilityBoundaryFacts
            .didMaterializeBackendAdapterRollbackVisibilityBoundary,
        backendAdapterRollbackVisibilityBoundaryFacts
            .didBindRollbackBoundaryToNoSubmitPredicate,
        backendAdapterRollbackVisibilityBoundaryFacts
            .didConfirmRollbackReadyResultEnvelope,
        backendAdapterRollbackVisibilityBoundaryFacts
            .didConfirmVisibilityNotPublishedBoundary,
        backendAdapterRollbackVisibilityBoundaryFacts
            .didPrepareStage240BackendAdapterReadinessDecisionInput,
        backendAdapterRollbackVisibilityBoundaryFacts
            .didKeepOwnerAcceptanceRequired,
        false,
        false,
        backendAdapterRollbackVisibilityBoundaryFacts
            .didKeepBackendImplementationBlocked,
        backendAdapterRollbackVisibilityBoundaryFacts
            .didKeepPlatformCommandBufferBlocked,
        backendAdapterRollbackVisibilityBoundaryFacts
            .didKeepRendererSubmissionBlocked,
        backendAdapterRollbackVisibilityBoundaryFacts
            .didKeepRendererStateWriteBlocked,
        backendAdapterRollbackVisibilityBoundaryFacts
            .didKeepRuntimeStateWriteBlocked,
        backendAdapterRollbackVisibilityBoundaryFacts
            .didKeepNativeBridgeExpansionBlocked,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage239BackendAdapterRollbackVisibilityBoundaryDraft():
    CjguiInternalRendererStage239BackendAdapterRollbackVisibilityBoundaryReadiness {
    let noSubmitPredicate =
        cjguiInternalExecuteDefaultRendererStage238BackendAdapterNoSubmitPredicateDraft()
    let facts =
        cjguiInternalBuildRendererStage239BackendAdapterRollbackVisibilityBoundaryFacts(
            noSubmitPredicate
        )
    return cjguiInternalBuildRendererStage239BackendAdapterRollbackVisibilityBoundaryReadiness(
        noSubmitPredicate,
        facts
    )
}
