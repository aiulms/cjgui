// 中文维护注释：本文件是 stage246 backend adapter executor result packet owner。
// Owner: 将 stage245 dry-run executor 结果封装为 rollback-ready result packet。
// Truth: packet 是 owner-local value，只供后续 recheck/readiness 使用。
// Stop-line: 不提交 renderer，不写 renderer/runtime state，不发布 visibility。
package cjgui

struct CjguiInternalRendererStage246BackendAdapterExecutorResultPacketFacts {
    let didConsumeStage245BackendAdapterDryRunExecutor: Bool
    let didMaterializeBackendAdapterExecutorResultPacket: Bool
    let didBindExecutorResultToRollbackReadyEnvelope: Bool
    let didKeepExecutorResultOwnerLocalInMemoryOnly: Bool
    let didRejectExecutorResultRendererSubmission: Bool
    let didRejectExecutorResultRendererStateWrite: Bool
    let didPrepareStage247BackendAdapterVisibilityBoundaryRecheckInput: Bool
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didKeepBackendReadyTruthBlocked: Bool
    let didKeepPlatformCommandBufferBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepVisibilityNotPublished: Bool

    init(
        didConsumeStage245BackendAdapterDryRunExecutor: Bool,
        didMaterializeBackendAdapterExecutorResultPacket: Bool,
        didBindExecutorResultToRollbackReadyEnvelope: Bool,
        didKeepExecutorResultOwnerLocalInMemoryOnly: Bool,
        didRejectExecutorResultRendererSubmission: Bool,
        didRejectExecutorResultRendererStateWrite: Bool,
        didPrepareStage247BackendAdapterVisibilityBoundaryRecheckInput: Bool,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didKeepBackendReadyTruthBlocked: Bool,
        didKeepPlatformCommandBufferBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepVisibilityNotPublished: Bool
    ) {
        this.didConsumeStage245BackendAdapterDryRunExecutor =
            didConsumeStage245BackendAdapterDryRunExecutor
        this.didMaterializeBackendAdapterExecutorResultPacket =
            didMaterializeBackendAdapterExecutorResultPacket
        this.didBindExecutorResultToRollbackReadyEnvelope =
            didBindExecutorResultToRollbackReadyEnvelope
        this.didKeepExecutorResultOwnerLocalInMemoryOnly =
            didKeepExecutorResultOwnerLocalInMemoryOnly
        this.didRejectExecutorResultRendererSubmission =
            didRejectExecutorResultRendererSubmission
        this.didRejectExecutorResultRendererStateWrite =
            didRejectExecutorResultRendererStateWrite
        this.didPrepareStage247BackendAdapterVisibilityBoundaryRecheckInput =
            didPrepareStage247BackendAdapterVisibilityBoundaryRecheckInput
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

struct CjguiInternalRendererStage246BackendAdapterExecutorResultPacketReadiness {
    let backendAdapterDryRunExecutor:
        CjguiInternalRendererStage245BackendAdapterDryRunExecutorReadiness
    let backendAdapterExecutorResultPacketFacts:
        CjguiInternalRendererStage246BackendAdapterExecutorResultPacketFacts
    let didPrepareStage246BackendAdapterExecutorResultPacketReadiness: Bool
    let didConfirmBackendAdapterExecutorResultPacketReady: Bool
    let didConfirmBackendAdapterExecutorResultPacketMaterialized: Bool
    let didConfirmExecutorResultBoundToRollbackReadyEnvelope: Bool
    let didConfirmExecutorResultOwnerLocalInMemoryOnly: Bool
    let didConfirmExecutorResultRendererSubmissionRejected: Bool
    let didConfirmExecutorResultRendererStateWriteRejected: Bool
    let didConfirmStage247BackendAdapterVisibilityBoundaryRecheckInputPrepared:
        Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmBackendReadyTruth: Bool
    let didConfirmPlatformCommandBufferBlocked: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmVisibilityPublished: Bool

    init(
        backendAdapterDryRunExecutor:
            CjguiInternalRendererStage245BackendAdapterDryRunExecutorReadiness,
        backendAdapterExecutorResultPacketFacts:
            CjguiInternalRendererStage246BackendAdapterExecutorResultPacketFacts,
        didPrepareStage246BackendAdapterExecutorResultPacketReadiness: Bool,
        didConfirmBackendAdapterExecutorResultPacketReady: Bool,
        didConfirmBackendAdapterExecutorResultPacketMaterialized: Bool,
        didConfirmExecutorResultBoundToRollbackReadyEnvelope: Bool,
        didConfirmExecutorResultOwnerLocalInMemoryOnly: Bool,
        didConfirmExecutorResultRendererSubmissionRejected: Bool,
        didConfirmExecutorResultRendererStateWriteRejected: Bool,
        didConfirmStage247BackendAdapterVisibilityBoundaryRecheckInputPrepared:
            Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmBackendReadyTruth: Bool,
        didConfirmPlatformCommandBufferBlocked: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmVisibilityPublished: Bool
    ) {
        this.backendAdapterDryRunExecutor = backendAdapterDryRunExecutor
        this.backendAdapterExecutorResultPacketFacts =
            backendAdapterExecutorResultPacketFacts
        this.didPrepareStage246BackendAdapterExecutorResultPacketReadiness =
            didPrepareStage246BackendAdapterExecutorResultPacketReadiness
        this.didConfirmBackendAdapterExecutorResultPacketReady =
            didConfirmBackendAdapterExecutorResultPacketReady
        this.didConfirmBackendAdapterExecutorResultPacketMaterialized =
            didConfirmBackendAdapterExecutorResultPacketMaterialized
        this.didConfirmExecutorResultBoundToRollbackReadyEnvelope =
            didConfirmExecutorResultBoundToRollbackReadyEnvelope
        this.didConfirmExecutorResultOwnerLocalInMemoryOnly =
            didConfirmExecutorResultOwnerLocalInMemoryOnly
        this.didConfirmExecutorResultRendererSubmissionRejected =
            didConfirmExecutorResultRendererSubmissionRejected
        this.didConfirmExecutorResultRendererStateWriteRejected =
            didConfirmExecutorResultRendererStateWriteRejected
        this.didConfirmStage247BackendAdapterVisibilityBoundaryRecheckInputPrepared =
            didConfirmStage247BackendAdapterVisibilityBoundaryRecheckInputPrepared
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

func cjguiInternalBuildRendererStage246BackendAdapterExecutorResultPacketFacts(
    backendAdapterDryRunExecutor:
        CjguiInternalRendererStage245BackendAdapterDryRunExecutorReadiness
): CjguiInternalRendererStage246BackendAdapterExecutorResultPacketFacts {
    return CjguiInternalRendererStage246BackendAdapterExecutorResultPacketFacts(
        backendAdapterDryRunExecutor.didConfirmBackendAdapterDryRunExecutorReady,
        true,
        backendAdapterDryRunExecutor
            .didConfirmBackendAdapterExecutorRollbackSnapshotCaptured,
        backendAdapterDryRunExecutor
            .didConfirmOwnerLocalInMemoryAdapterDryRunExecuted &&
            backendAdapterDryRunExecutor
                .didConfirmBackendAdapterExecutorNoSubmit,
        backendAdapterDryRunExecutor.didConfirmRendererSubmissionBlocked,
        backendAdapterDryRunExecutor.didConfirmRendererStateWriteBlocked,
        true,
        backendAdapterDryRunExecutor.didConfirmOwnerAcceptanceRequired,
        backendAdapterDryRunExecutor
            .didConfirmOwnerAcceptanceGranted == false,
        backendAdapterDryRunExecutor.didConfirmBackendReadyTruth == false,
        backendAdapterDryRunExecutor.didConfirmPlatformCommandBufferBlocked,
        backendAdapterDryRunExecutor.didConfirmRendererSubmissionBlocked,
        backendAdapterDryRunExecutor.didConfirmRendererStateWriteBlocked,
        backendAdapterDryRunExecutor.didConfirmRuntimeStateWriteBlocked,
        backendAdapterDryRunExecutor.didConfirmVisibilityPublished == false
    )
}

func cjguiInternalBuildRendererStage246BackendAdapterExecutorResultPacketReadiness(
    backendAdapterDryRunExecutor:
        CjguiInternalRendererStage245BackendAdapterDryRunExecutorReadiness,
    backendAdapterExecutorResultPacketFacts:
        CjguiInternalRendererStage246BackendAdapterExecutorResultPacketFacts
): CjguiInternalRendererStage246BackendAdapterExecutorResultPacketReadiness {
    let packetReady =
        backendAdapterExecutorResultPacketFacts
            .didConsumeStage245BackendAdapterDryRunExecutor &&
        backendAdapterExecutorResultPacketFacts
            .didMaterializeBackendAdapterExecutorResultPacket &&
        backendAdapterExecutorResultPacketFacts
            .didBindExecutorResultToRollbackReadyEnvelope &&
        backendAdapterExecutorResultPacketFacts
            .didKeepExecutorResultOwnerLocalInMemoryOnly &&
        backendAdapterExecutorResultPacketFacts
            .didRejectExecutorResultRendererSubmission &&
        backendAdapterExecutorResultPacketFacts
            .didRejectExecutorResultRendererStateWrite &&
        backendAdapterExecutorResultPacketFacts
            .didPrepareStage247BackendAdapterVisibilityBoundaryRecheckInput
    let stopLineReady =
        backendAdapterExecutorResultPacketFacts.didKeepOwnerAcceptanceRequired &&
        backendAdapterExecutorResultPacketFacts.didKeepOwnerAcceptanceNotGranted &&
        backendAdapterExecutorResultPacketFacts.didKeepBackendReadyTruthBlocked &&
        backendAdapterExecutorResultPacketFacts
            .didKeepPlatformCommandBufferBlocked &&
        backendAdapterExecutorResultPacketFacts.didKeepRendererSubmissionBlocked &&
        backendAdapterExecutorResultPacketFacts
            .didKeepRendererStateWriteBlocked &&
        backendAdapterExecutorResultPacketFacts.didKeepRuntimeStateWriteBlocked &&
        backendAdapterExecutorResultPacketFacts.didKeepVisibilityNotPublished

    return CjguiInternalRendererStage246BackendAdapterExecutorResultPacketReadiness(
        backendAdapterDryRunExecutor,
        backendAdapterExecutorResultPacketFacts,
        packetReady && stopLineReady,
        packetReady && stopLineReady,
        backendAdapterExecutorResultPacketFacts
            .didMaterializeBackendAdapterExecutorResultPacket,
        backendAdapterExecutorResultPacketFacts
            .didBindExecutorResultToRollbackReadyEnvelope,
        backendAdapterExecutorResultPacketFacts
            .didKeepExecutorResultOwnerLocalInMemoryOnly,
        backendAdapterExecutorResultPacketFacts
            .didRejectExecutorResultRendererSubmission,
        backendAdapterExecutorResultPacketFacts
            .didRejectExecutorResultRendererStateWrite,
        backendAdapterExecutorResultPacketFacts
            .didPrepareStage247BackendAdapterVisibilityBoundaryRecheckInput,
        backendAdapterExecutorResultPacketFacts.didKeepOwnerAcceptanceRequired,
        false,
        false,
        backendAdapterExecutorResultPacketFacts
            .didKeepPlatformCommandBufferBlocked,
        backendAdapterExecutorResultPacketFacts.didKeepRendererSubmissionBlocked,
        backendAdapterExecutorResultPacketFacts
            .didKeepRendererStateWriteBlocked,
        backendAdapterExecutorResultPacketFacts.didKeepRuntimeStateWriteBlocked,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage246BackendAdapterExecutorResultPacketDraft():
    CjguiInternalRendererStage246BackendAdapterExecutorResultPacketReadiness {
    let executor =
        cjguiInternalExecuteDefaultRendererStage245BackendAdapterDryRunExecutorDraft()
    let facts =
        cjguiInternalBuildRendererStage246BackendAdapterExecutorResultPacketFacts(
            executor
        )
    return cjguiInternalBuildRendererStage246BackendAdapterExecutorResultPacketReadiness(
        executor,
        facts
    )
}
