// 中文维护注释：本文件是 stage247 backend adapter visibility boundary recheck owner。
// Owner: 对 executor result packet 做 visibility-not-published 与 rollback-ready 复核。
// Truth: recheck 只给 stage248 readiness decision 输入，不发布可见结果。
// Stop-line: 不提交 backend，不写 renderer/runtime state，不发布 visibility。
package cjgui

struct CjguiInternalRendererStage247BackendAdapterVisibilityBoundaryRecheckFacts {
    let didConsumeStage246BackendAdapterExecutorResultPacket: Bool
    let didMaterializeBackendAdapterVisibilityBoundaryRecheck: Bool
    let didRecheckBackendAdapterVisibilityNotPublishedBoundary: Bool
    let didRecheckExecutorResultRollbackReady: Bool
    let didRejectVisibilityPublicationAdmission: Bool
    let didPrepareStage248BackendAdapterExecutorReadinessDecisionInput: Bool
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didKeepBackendReadyTruthBlocked: Bool
    let didKeepPlatformCommandBufferBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepVisibilityNotPublished: Bool

    init(
        didConsumeStage246BackendAdapterExecutorResultPacket: Bool,
        didMaterializeBackendAdapterVisibilityBoundaryRecheck: Bool,
        didRecheckBackendAdapterVisibilityNotPublishedBoundary: Bool,
        didRecheckExecutorResultRollbackReady: Bool,
        didRejectVisibilityPublicationAdmission: Bool,
        didPrepareStage248BackendAdapterExecutorReadinessDecisionInput: Bool,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didKeepBackendReadyTruthBlocked: Bool,
        didKeepPlatformCommandBufferBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepVisibilityNotPublished: Bool
    ) {
        this.didConsumeStage246BackendAdapterExecutorResultPacket =
            didConsumeStage246BackendAdapterExecutorResultPacket
        this.didMaterializeBackendAdapterVisibilityBoundaryRecheck =
            didMaterializeBackendAdapterVisibilityBoundaryRecheck
        this.didRecheckBackendAdapterVisibilityNotPublishedBoundary =
            didRecheckBackendAdapterVisibilityNotPublishedBoundary
        this.didRecheckExecutorResultRollbackReady =
            didRecheckExecutorResultRollbackReady
        this.didRejectVisibilityPublicationAdmission =
            didRejectVisibilityPublicationAdmission
        this.didPrepareStage248BackendAdapterExecutorReadinessDecisionInput =
            didPrepareStage248BackendAdapterExecutorReadinessDecisionInput
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

struct CjguiInternalRendererStage247BackendAdapterVisibilityBoundaryRecheckReadiness {
    let backendAdapterExecutorResultPacket:
        CjguiInternalRendererStage246BackendAdapterExecutorResultPacketReadiness
    let backendAdapterVisibilityBoundaryRecheckFacts:
        CjguiInternalRendererStage247BackendAdapterVisibilityBoundaryRecheckFacts
    let didPrepareStage247BackendAdapterVisibilityBoundaryRecheckReadiness:
        Bool
    let didConfirmBackendAdapterVisibilityBoundaryRecheckReady: Bool
    let didConfirmBackendAdapterVisibilityBoundaryRecheckMaterialized: Bool
    let didConfirmBackendAdapterVisibilityNotPublishedBoundaryRechecked: Bool
    let didConfirmBackendAdapterExecutorResultRollbackReadyRechecked: Bool
    let didConfirmVisibilityPublicationAdmitted: Bool
    let didConfirmStage248BackendAdapterExecutorReadinessDecisionInputPrepared:
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
        backendAdapterExecutorResultPacket:
            CjguiInternalRendererStage246BackendAdapterExecutorResultPacketReadiness,
        backendAdapterVisibilityBoundaryRecheckFacts:
            CjguiInternalRendererStage247BackendAdapterVisibilityBoundaryRecheckFacts,
        didPrepareStage247BackendAdapterVisibilityBoundaryRecheckReadiness:
            Bool,
        didConfirmBackendAdapterVisibilityBoundaryRecheckReady: Bool,
        didConfirmBackendAdapterVisibilityBoundaryRecheckMaterialized: Bool,
        didConfirmBackendAdapterVisibilityNotPublishedBoundaryRechecked: Bool,
        didConfirmBackendAdapterExecutorResultRollbackReadyRechecked: Bool,
        didConfirmVisibilityPublicationAdmitted: Bool,
        didConfirmStage248BackendAdapterExecutorReadinessDecisionInputPrepared:
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
        this.backendAdapterExecutorResultPacket =
            backendAdapterExecutorResultPacket
        this.backendAdapterVisibilityBoundaryRecheckFacts =
            backendAdapterVisibilityBoundaryRecheckFacts
        this.didPrepareStage247BackendAdapterVisibilityBoundaryRecheckReadiness =
            didPrepareStage247BackendAdapterVisibilityBoundaryRecheckReadiness
        this.didConfirmBackendAdapterVisibilityBoundaryRecheckReady =
            didConfirmBackendAdapterVisibilityBoundaryRecheckReady
        this.didConfirmBackendAdapterVisibilityBoundaryRecheckMaterialized =
            didConfirmBackendAdapterVisibilityBoundaryRecheckMaterialized
        this.didConfirmBackendAdapterVisibilityNotPublishedBoundaryRechecked =
            didConfirmBackendAdapterVisibilityNotPublishedBoundaryRechecked
        this.didConfirmBackendAdapterExecutorResultRollbackReadyRechecked =
            didConfirmBackendAdapterExecutorResultRollbackReadyRechecked
        this.didConfirmVisibilityPublicationAdmitted =
            didConfirmVisibilityPublicationAdmitted
        this.didConfirmStage248BackendAdapterExecutorReadinessDecisionInputPrepared =
            didConfirmStage248BackendAdapterExecutorReadinessDecisionInputPrepared
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

func cjguiInternalBuildRendererStage247BackendAdapterVisibilityBoundaryRecheckFacts(
    backendAdapterExecutorResultPacket:
        CjguiInternalRendererStage246BackendAdapterExecutorResultPacketReadiness
): CjguiInternalRendererStage247BackendAdapterVisibilityBoundaryRecheckFacts {
    return CjguiInternalRendererStage247BackendAdapterVisibilityBoundaryRecheckFacts(
        backendAdapterExecutorResultPacket
            .didConfirmBackendAdapterExecutorResultPacketReady,
        true,
        backendAdapterExecutorResultPacket
            .didConfirmVisibilityPublished == false,
        backendAdapterExecutorResultPacket
            .didConfirmExecutorResultBoundToRollbackReadyEnvelope,
        backendAdapterExecutorResultPacket
            .didConfirmVisibilityPublished == false &&
            backendAdapterExecutorResultPacket
                .didConfirmBackendReadyTruth == false,
        true,
        backendAdapterExecutorResultPacket.didConfirmOwnerAcceptanceRequired,
        backendAdapterExecutorResultPacket
            .didConfirmOwnerAcceptanceGranted == false,
        backendAdapterExecutorResultPacket.didConfirmBackendReadyTruth == false,
        backendAdapterExecutorResultPacket
            .didConfirmPlatformCommandBufferBlocked,
        backendAdapterExecutorResultPacket.didConfirmRendererSubmissionBlocked,
        backendAdapterExecutorResultPacket.didConfirmRendererStateWriteBlocked,
        backendAdapterExecutorResultPacket.didConfirmRuntimeStateWriteBlocked,
        backendAdapterExecutorResultPacket.didConfirmVisibilityPublished == false
    )
}

func cjguiInternalBuildRendererStage247BackendAdapterVisibilityBoundaryRecheckReadiness(
    backendAdapterExecutorResultPacket:
        CjguiInternalRendererStage246BackendAdapterExecutorResultPacketReadiness,
    backendAdapterVisibilityBoundaryRecheckFacts:
        CjguiInternalRendererStage247BackendAdapterVisibilityBoundaryRecheckFacts
): CjguiInternalRendererStage247BackendAdapterVisibilityBoundaryRecheckReadiness {
    let recheckReady =
        backendAdapterVisibilityBoundaryRecheckFacts
            .didConsumeStage246BackendAdapterExecutorResultPacket &&
        backendAdapterVisibilityBoundaryRecheckFacts
            .didMaterializeBackendAdapterVisibilityBoundaryRecheck &&
        backendAdapterVisibilityBoundaryRecheckFacts
            .didRecheckBackendAdapterVisibilityNotPublishedBoundary &&
        backendAdapterVisibilityBoundaryRecheckFacts
            .didRecheckExecutorResultRollbackReady &&
        backendAdapterVisibilityBoundaryRecheckFacts
            .didRejectVisibilityPublicationAdmission &&
        backendAdapterVisibilityBoundaryRecheckFacts
            .didPrepareStage248BackendAdapterExecutorReadinessDecisionInput
    let stopLineReady =
        backendAdapterVisibilityBoundaryRecheckFacts
            .didKeepOwnerAcceptanceRequired &&
        backendAdapterVisibilityBoundaryRecheckFacts
            .didKeepOwnerAcceptanceNotGranted &&
        backendAdapterVisibilityBoundaryRecheckFacts
            .didKeepBackendReadyTruthBlocked &&
        backendAdapterVisibilityBoundaryRecheckFacts
            .didKeepPlatformCommandBufferBlocked &&
        backendAdapterVisibilityBoundaryRecheckFacts
            .didKeepRendererSubmissionBlocked &&
        backendAdapterVisibilityBoundaryRecheckFacts
            .didKeepRendererStateWriteBlocked &&
        backendAdapterVisibilityBoundaryRecheckFacts
            .didKeepRuntimeStateWriteBlocked &&
        backendAdapterVisibilityBoundaryRecheckFacts.didKeepVisibilityNotPublished

    return CjguiInternalRendererStage247BackendAdapterVisibilityBoundaryRecheckReadiness(
        backendAdapterExecutorResultPacket,
        backendAdapterVisibilityBoundaryRecheckFacts,
        recheckReady && stopLineReady,
        recheckReady && stopLineReady,
        backendAdapterVisibilityBoundaryRecheckFacts
            .didMaterializeBackendAdapterVisibilityBoundaryRecheck,
        backendAdapterVisibilityBoundaryRecheckFacts
            .didRecheckBackendAdapterVisibilityNotPublishedBoundary,
        backendAdapterVisibilityBoundaryRecheckFacts
            .didRecheckExecutorResultRollbackReady,
        false,
        backendAdapterVisibilityBoundaryRecheckFacts
            .didPrepareStage248BackendAdapterExecutorReadinessDecisionInput,
        backendAdapterVisibilityBoundaryRecheckFacts
            .didKeepOwnerAcceptanceRequired,
        false,
        false,
        backendAdapterVisibilityBoundaryRecheckFacts
            .didKeepPlatformCommandBufferBlocked,
        backendAdapterVisibilityBoundaryRecheckFacts
            .didKeepRendererSubmissionBlocked,
        backendAdapterVisibilityBoundaryRecheckFacts
            .didKeepRendererStateWriteBlocked,
        backendAdapterVisibilityBoundaryRecheckFacts
            .didKeepRuntimeStateWriteBlocked,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage247BackendAdapterVisibilityBoundaryRecheckDraft():
    CjguiInternalRendererStage247BackendAdapterVisibilityBoundaryRecheckReadiness {
    let resultPacket =
        cjguiInternalExecuteDefaultRendererStage246BackendAdapterExecutorResultPacketDraft()
    let facts =
        cjguiInternalBuildRendererStage247BackendAdapterVisibilityBoundaryRecheckFacts(
            resultPacket
        )
    return cjguiInternalBuildRendererStage247BackendAdapterVisibilityBoundaryRecheckReadiness(
        resultPacket,
        facts
    )
}
