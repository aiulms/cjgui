// 中文维护注释：本文件是 stage248 backend adapter executor readiness decision owner。
// Owner: 汇合 executor、result packet 与 visibility boundary recheck。
// Truth: readiness 只准备 stage249 backend result preview 输入，不代表 backend ready truth。
// Stop-line: 不提交 renderer，不写 renderer/runtime state，不扩 public API。
package cjgui

struct CjguiInternalRendererStage248BackendAdapterExecutorReadinessDecisionFacts {
    let didConsumeStage247BackendAdapterVisibilityBoundaryRecheck: Bool
    let didJoinExecutorWithResultPacketAndVisibilityBoundary: Bool
    let didMaterializeBackendAdapterExecutorReadinessDecision: Bool
    let didPrepareStage249ComponentDemoBackendResultPreviewInput: Bool
    let didKeepOwnerLocalInMemoryDryRunOnly: Bool
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didKeepBackendReadyTruthBlocked: Bool
    let didKeepPlatformCommandBufferBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepVisibilityNotPublished: Bool

    init(
        didConsumeStage247BackendAdapterVisibilityBoundaryRecheck: Bool,
        didJoinExecutorWithResultPacketAndVisibilityBoundary: Bool,
        didMaterializeBackendAdapterExecutorReadinessDecision: Bool,
        didPrepareStage249ComponentDemoBackendResultPreviewInput: Bool,
        didKeepOwnerLocalInMemoryDryRunOnly: Bool,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didKeepBackendReadyTruthBlocked: Bool,
        didKeepPlatformCommandBufferBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepVisibilityNotPublished: Bool
    ) {
        this.didConsumeStage247BackendAdapterVisibilityBoundaryRecheck =
            didConsumeStage247BackendAdapterVisibilityBoundaryRecheck
        this.didJoinExecutorWithResultPacketAndVisibilityBoundary =
            didJoinExecutorWithResultPacketAndVisibilityBoundary
        this.didMaterializeBackendAdapterExecutorReadinessDecision =
            didMaterializeBackendAdapterExecutorReadinessDecision
        this.didPrepareStage249ComponentDemoBackendResultPreviewInput =
            didPrepareStage249ComponentDemoBackendResultPreviewInput
        this.didKeepOwnerLocalInMemoryDryRunOnly =
            didKeepOwnerLocalInMemoryDryRunOnly
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didKeepOwnerAcceptanceNotGranted =
            didKeepOwnerAcceptanceNotGranted
        this.didKeepBackendReadyTruthBlocked =
            didKeepBackendReadyTruthBlocked
        this.didKeepPlatformCommandBufferBlocked =
            didKeepPlatformCommandBufferBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didKeepVisibilityNotPublished = didKeepVisibilityNotPublished
    }
}

struct CjguiInternalRendererStage248BackendAdapterExecutorReadinessDecisionReadiness {
    let backendAdapterVisibilityBoundaryRecheck:
        CjguiInternalRendererStage247BackendAdapterVisibilityBoundaryRecheckReadiness
    let backendAdapterExecutorReadinessDecisionFacts:
        CjguiInternalRendererStage248BackendAdapterExecutorReadinessDecisionFacts
    let didPrepareStage248BackendAdapterExecutorReadinessDecisionReadiness:
        Bool
    let didConfirmBackendAdapterExecutorReadinessDecisionReady: Bool
    let didConfirmExecutorJoinedWithResultPacketAndVisibilityBoundary: Bool
    let didConfirmBackendAdapterExecutorReadinessDecisionMaterialized: Bool
    let didConfirmStage249ComponentDemoBackendResultPreviewInputPrepared: Bool
    let didConfirmOwnerLocalInMemoryDryRunOnly: Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmBackendReadyTruth: Bool
    let didConfirmPlatformCommandBufferBlocked: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmVisibilityPublished: Bool

    init(
        backendAdapterVisibilityBoundaryRecheck:
            CjguiInternalRendererStage247BackendAdapterVisibilityBoundaryRecheckReadiness,
        backendAdapterExecutorReadinessDecisionFacts:
            CjguiInternalRendererStage248BackendAdapterExecutorReadinessDecisionFacts,
        didPrepareStage248BackendAdapterExecutorReadinessDecisionReadiness:
            Bool,
        didConfirmBackendAdapterExecutorReadinessDecisionReady: Bool,
        didConfirmExecutorJoinedWithResultPacketAndVisibilityBoundary: Bool,
        didConfirmBackendAdapterExecutorReadinessDecisionMaterialized: Bool,
        didConfirmStage249ComponentDemoBackendResultPreviewInputPrepared: Bool,
        didConfirmOwnerLocalInMemoryDryRunOnly: Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmBackendReadyTruth: Bool,
        didConfirmPlatformCommandBufferBlocked: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmVisibilityPublished: Bool
    ) {
        this.backendAdapterVisibilityBoundaryRecheck =
            backendAdapterVisibilityBoundaryRecheck
        this.backendAdapterExecutorReadinessDecisionFacts =
            backendAdapterExecutorReadinessDecisionFacts
        this.didPrepareStage248BackendAdapterExecutorReadinessDecisionReadiness =
            didPrepareStage248BackendAdapterExecutorReadinessDecisionReadiness
        this.didConfirmBackendAdapterExecutorReadinessDecisionReady =
            didConfirmBackendAdapterExecutorReadinessDecisionReady
        this.didConfirmExecutorJoinedWithResultPacketAndVisibilityBoundary =
            didConfirmExecutorJoinedWithResultPacketAndVisibilityBoundary
        this.didConfirmBackendAdapterExecutorReadinessDecisionMaterialized =
            didConfirmBackendAdapterExecutorReadinessDecisionMaterialized
        this.didConfirmStage249ComponentDemoBackendResultPreviewInputPrepared =
            didConfirmStage249ComponentDemoBackendResultPreviewInputPrepared
        this.didConfirmOwnerLocalInMemoryDryRunOnly =
            didConfirmOwnerLocalInMemoryDryRunOnly
        this.didConfirmOwnerAcceptanceRequired =
            didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted =
            didConfirmOwnerAcceptanceGranted
        this.didConfirmBackendReadyTruth = didConfirmBackendReadyTruth
        this.didConfirmPlatformCommandBufferBlocked =
            didConfirmPlatformCommandBufferBlocked
        this.didConfirmRendererSubmissionBlocked =
            didConfirmRendererSubmissionBlocked
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked =
            didConfirmRuntimeStateWriteBlocked
        this.didConfirmVisibilityPublished = didConfirmVisibilityPublished
    }
}

func cjguiInternalBuildRendererStage248BackendAdapterExecutorReadinessDecisionFacts(
    backendAdapterVisibilityBoundaryRecheck:
        CjguiInternalRendererStage247BackendAdapterVisibilityBoundaryRecheckReadiness
): CjguiInternalRendererStage248BackendAdapterExecutorReadinessDecisionFacts {
    let resultPacket = backendAdapterVisibilityBoundaryRecheck
        .backendAdapterExecutorResultPacket
    let executor = resultPacket.backendAdapterDryRunExecutor

    return CjguiInternalRendererStage248BackendAdapterExecutorReadinessDecisionFacts(
        backendAdapterVisibilityBoundaryRecheck
            .didConfirmBackendAdapterVisibilityBoundaryRecheckReady,
        executor.didConfirmBackendAdapterDryRunExecutorReady &&
            resultPacket.didConfirmBackendAdapterExecutorResultPacketReady &&
            backendAdapterVisibilityBoundaryRecheck
                .didConfirmBackendAdapterVisibilityNotPublishedBoundaryRechecked,
        true,
        true,
        executor.didConfirmOwnerLocalInMemoryAdapterDryRunExecuted &&
            resultPacket.didConfirmExecutorResultOwnerLocalInMemoryOnly,
        backendAdapterVisibilityBoundaryRecheck.didConfirmOwnerAcceptanceRequired,
        backendAdapterVisibilityBoundaryRecheck
            .didConfirmOwnerAcceptanceGranted == false,
        backendAdapterVisibilityBoundaryRecheck
            .didConfirmBackendReadyTruth == false,
        backendAdapterVisibilityBoundaryRecheck
            .didConfirmPlatformCommandBufferBlocked,
        backendAdapterVisibilityBoundaryRecheck
            .didConfirmRendererSubmissionBlocked,
        backendAdapterVisibilityBoundaryRecheck
            .didConfirmRendererStateWriteBlocked,
        backendAdapterVisibilityBoundaryRecheck
            .didConfirmRuntimeStateWriteBlocked,
        backendAdapterVisibilityBoundaryRecheck
            .didConfirmVisibilityPublished == false
    )
}

func cjguiInternalBuildRendererStage248BackendAdapterExecutorReadinessDecisionReadiness(
    backendAdapterVisibilityBoundaryRecheck:
        CjguiInternalRendererStage247BackendAdapterVisibilityBoundaryRecheckReadiness,
    backendAdapterExecutorReadinessDecisionFacts:
        CjguiInternalRendererStage248BackendAdapterExecutorReadinessDecisionFacts
): CjguiInternalRendererStage248BackendAdapterExecutorReadinessDecisionReadiness {
    let decisionReady =
        backendAdapterExecutorReadinessDecisionFacts
            .didConsumeStage247BackendAdapterVisibilityBoundaryRecheck &&
        backendAdapterExecutorReadinessDecisionFacts
            .didJoinExecutorWithResultPacketAndVisibilityBoundary &&
        backendAdapterExecutorReadinessDecisionFacts
            .didMaterializeBackendAdapterExecutorReadinessDecision &&
        backendAdapterExecutorReadinessDecisionFacts
            .didPrepareStage249ComponentDemoBackendResultPreviewInput &&
        backendAdapterExecutorReadinessDecisionFacts
            .didKeepOwnerLocalInMemoryDryRunOnly
    let stopLineReady =
        backendAdapterExecutorReadinessDecisionFacts
            .didKeepOwnerAcceptanceRequired &&
        backendAdapterExecutorReadinessDecisionFacts
            .didKeepOwnerAcceptanceNotGranted &&
        backendAdapterExecutorReadinessDecisionFacts
            .didKeepBackendReadyTruthBlocked &&
        backendAdapterExecutorReadinessDecisionFacts
            .didKeepPlatformCommandBufferBlocked &&
        backendAdapterExecutorReadinessDecisionFacts
            .didKeepRendererSubmissionBlocked &&
        backendAdapterExecutorReadinessDecisionFacts
            .didKeepRendererStateWriteBlocked &&
        backendAdapterExecutorReadinessDecisionFacts
            .didKeepRuntimeStateWriteBlocked &&
        backendAdapterExecutorReadinessDecisionFacts.didKeepVisibilityNotPublished

    return CjguiInternalRendererStage248BackendAdapterExecutorReadinessDecisionReadiness(
        backendAdapterVisibilityBoundaryRecheck,
        backendAdapterExecutorReadinessDecisionFacts,
        decisionReady && stopLineReady,
        decisionReady && stopLineReady,
        backendAdapterExecutorReadinessDecisionFacts
            .didJoinExecutorWithResultPacketAndVisibilityBoundary,
        backendAdapterExecutorReadinessDecisionFacts
            .didMaterializeBackendAdapterExecutorReadinessDecision,
        backendAdapterExecutorReadinessDecisionFacts
            .didPrepareStage249ComponentDemoBackendResultPreviewInput,
        backendAdapterExecutorReadinessDecisionFacts
            .didKeepOwnerLocalInMemoryDryRunOnly,
        backendAdapterExecutorReadinessDecisionFacts
            .didKeepOwnerAcceptanceRequired,
        false,
        false,
        backendAdapterExecutorReadinessDecisionFacts
            .didKeepPlatformCommandBufferBlocked,
        backendAdapterExecutorReadinessDecisionFacts
            .didKeepRendererSubmissionBlocked,
        backendAdapterExecutorReadinessDecisionFacts
            .didKeepRendererStateWriteBlocked,
        backendAdapterExecutorReadinessDecisionFacts
            .didKeepRuntimeStateWriteBlocked,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage248BackendAdapterExecutorReadinessDecisionDraft():
    CjguiInternalRendererStage248BackendAdapterExecutorReadinessDecisionReadiness {
    let boundaryRecheck =
        cjguiInternalExecuteDefaultRendererStage247BackendAdapterVisibilityBoundaryRecheckDraft()
    let facts =
        cjguiInternalBuildRendererStage248BackendAdapterExecutorReadinessDecisionFacts(
            boundaryRecheck
        )
    return cjguiInternalBuildRendererStage248BackendAdapterExecutorReadinessDecisionReadiness(
        boundaryRecheck,
        facts
    )
}
