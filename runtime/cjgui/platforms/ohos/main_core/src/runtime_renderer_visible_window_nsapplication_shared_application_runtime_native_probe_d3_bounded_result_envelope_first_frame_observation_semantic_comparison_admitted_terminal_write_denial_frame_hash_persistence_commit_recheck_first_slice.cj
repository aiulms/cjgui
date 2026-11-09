// 中文维护注释：本文件是 backing-store token result envelope 后的
// frame-hash persistence commit readiness recheck first-slice owner。
// Owner: runtime renderer internal frame-hash persistence commit recheck。
// Truth: frame-hash persistence commit 必须重新绑定 backing-store token result；
// token denial 时继续阻断 persistence / production truth / renderer-state write。
// Stop-line: 不持久化 hash value，不写 renderer state / runtime_state.cj，
// 不扩 public API / public C ABI / native bridge。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceCommitReadinessRecheckFirstSliceFacts {
    let didConsumeBackingStoreTokenResultEnvelope: Bool
    let didRecheckFrameHashPersistenceCommitAgainstTokenResult: Bool
    let didConfirmTokenDenialBlocksFrameHashPersistenceCommit: Bool
    let didConfirmPositiveProbeStillRequiredForPersistenceCommit: Bool
    let didConfirmNonzeroFrameHashStillRequiredForPersistenceCommit: Bool
    let didKeepFrameHashPersistenceCommitAdmissionBlocked: Bool
    let didKeepFrameHashValueRedacted: Bool
    let didKeepFrameHashUnpersisted: Bool
    let didKeepResultEnvelopePromotionBlocked: Bool
    let didKeepProductionRenderTruthBlocked: Bool
    let didKeepBackendReadyTruthBlocked: Bool
    let didKeepRendererStateWriteAdmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didPreparePositiveProbeMaterializationOrProductionTruthTokenGateNextRoute: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool

    init(
        didConsumeBackingStoreTokenResultEnvelope: Bool,
        didRecheckFrameHashPersistenceCommitAgainstTokenResult: Bool,
        didConfirmTokenDenialBlocksFrameHashPersistenceCommit: Bool,
        didConfirmPositiveProbeStillRequiredForPersistenceCommit: Bool,
        didConfirmNonzeroFrameHashStillRequiredForPersistenceCommit: Bool,
        didKeepFrameHashPersistenceCommitAdmissionBlocked: Bool,
        didKeepFrameHashValueRedacted: Bool,
        didKeepFrameHashUnpersisted: Bool,
        didKeepResultEnvelopePromotionBlocked: Bool,
        didKeepProductionRenderTruthBlocked: Bool,
        didKeepBackendReadyTruthBlocked: Bool,
        didKeepRendererStateWriteAdmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didPreparePositiveProbeMaterializationOrProductionTruthTokenGateNextRoute: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool
    ) {
        this.didConsumeBackingStoreTokenResultEnvelope =
            didConsumeBackingStoreTokenResultEnvelope
        this.didRecheckFrameHashPersistenceCommitAgainstTokenResult =
            didRecheckFrameHashPersistenceCommitAgainstTokenResult
        this.didConfirmTokenDenialBlocksFrameHashPersistenceCommit =
            didConfirmTokenDenialBlocksFrameHashPersistenceCommit
        this.didConfirmPositiveProbeStillRequiredForPersistenceCommit =
            didConfirmPositiveProbeStillRequiredForPersistenceCommit
        this.didConfirmNonzeroFrameHashStillRequiredForPersistenceCommit =
            didConfirmNonzeroFrameHashStillRequiredForPersistenceCommit
        this.didKeepFrameHashPersistenceCommitAdmissionBlocked =
            didKeepFrameHashPersistenceCommitAdmissionBlocked
        this.didKeepFrameHashValueRedacted = didKeepFrameHashValueRedacted
        this.didKeepFrameHashUnpersisted = didKeepFrameHashUnpersisted
        this.didKeepResultEnvelopePromotionBlocked =
            didKeepResultEnvelopePromotionBlocked
        this.didKeepProductionRenderTruthBlocked =
            didKeepProductionRenderTruthBlocked
        this.didKeepBackendReadyTruthBlocked = didKeepBackendReadyTruthBlocked
        this.didKeepRendererStateWriteAdmissionBlocked =
            didKeepRendererStateWriteAdmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didPreparePositiveProbeMaterializationOrProductionTruthTokenGateNextRoute =
            didPreparePositiveProbeMaterializationOrProductionTruthTokenGateNextRoute
        this.didConfirmNoNativeBridgeExpansion =
            didConfirmNoNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceCommitReadinessRecheckFirstSliceReadiness {
    let frameHashPersistenceCommitReadinessRecheckFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceCommitReadinessRecheckFirstSliceFacts
    let didPrepareFrameHashPersistenceCommitReadinessRecheckFirstSliceReadiness: Bool
    let shouldPublishFrameHashPersistenceCommitReadinessRecheck: Bool
    let shouldKeepFrameHashPersistenceCommitBlocked: Bool
    let shouldKeepProductionTruthPromotionBlocked: Bool
    let shouldKeepRendererStateWriteAdmissionBlocked: Bool
    let shouldContinuePositiveProbeMaterializationOrProductionTruthTokenGateRoute: Bool
    let didConfirmBackingStoreTokenResultEnvelopeConsumed: Bool
    let didConfirmFrameHashPersistenceCommitRecheckedAgainstTokenResult: Bool
    let didConfirmTokenDenialBlocksFrameHashPersistenceCommit: Bool
    let didConfirmPositiveProbeStillRequiredForPersistenceCommit: Bool
    let didConfirmNonzeroFrameHashStillRequiredForPersistenceCommit: Bool
    let didConfirmFrameHashPersistenceCommitAdmissionBlocked: Bool
    let didConfirmFrameHashValueRedacted: Bool
    let didConfirmFrameHashUnpersisted: Bool
    let didConfirmResultEnvelopePromotionBlocked: Bool
    let didConfirmProductionRenderTruthBlocked: Bool
    let didConfirmBackendReadyTruthBlocked: Bool
    let didConfirmRendererStateWriteAdmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmPositiveProbeMaterializationOrProductionTruthTokenGateNextRoutePrepared: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool

    init(
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceCommitReadinessRecheckFirstSliceFacts,
        didPrepareFrameHashPersistenceCommitReadinessRecheckFirstSliceReadiness: Bool,
        shouldPublishFrameHashPersistenceCommitReadinessRecheck: Bool,
        shouldKeepFrameHashPersistenceCommitBlocked: Bool,
        shouldKeepProductionTruthPromotionBlocked: Bool,
        shouldKeepRendererStateWriteAdmissionBlocked: Bool,
        shouldContinuePositiveProbeMaterializationOrProductionTruthTokenGateRoute: Bool,
        didConfirmBackingStoreTokenResultEnvelopeConsumed: Bool,
        didConfirmFrameHashPersistenceCommitRecheckedAgainstTokenResult: Bool,
        didConfirmTokenDenialBlocksFrameHashPersistenceCommit: Bool,
        didConfirmPositiveProbeStillRequiredForPersistenceCommit: Bool,
        didConfirmNonzeroFrameHashStillRequiredForPersistenceCommit: Bool,
        didConfirmFrameHashPersistenceCommitAdmissionBlocked: Bool,
        didConfirmFrameHashValueRedacted: Bool,
        didConfirmFrameHashUnpersisted: Bool,
        didConfirmResultEnvelopePromotionBlocked: Bool,
        didConfirmProductionRenderTruthBlocked: Bool,
        didConfirmBackendReadyTruthBlocked: Bool,
        didConfirmRendererStateWriteAdmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmPositiveProbeMaterializationOrProductionTruthTokenGateNextRoutePrepared: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool
    ) {
        this.frameHashPersistenceCommitReadinessRecheckFirstSliceFacts =
            frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
        this.didPrepareFrameHashPersistenceCommitReadinessRecheckFirstSliceReadiness =
            didPrepareFrameHashPersistenceCommitReadinessRecheckFirstSliceReadiness
        this.shouldPublishFrameHashPersistenceCommitReadinessRecheck =
            shouldPublishFrameHashPersistenceCommitReadinessRecheck
        this.shouldKeepFrameHashPersistenceCommitBlocked =
            shouldKeepFrameHashPersistenceCommitBlocked
        this.shouldKeepProductionTruthPromotionBlocked =
            shouldKeepProductionTruthPromotionBlocked
        this.shouldKeepRendererStateWriteAdmissionBlocked =
            shouldKeepRendererStateWriteAdmissionBlocked
        this.shouldContinuePositiveProbeMaterializationOrProductionTruthTokenGateRoute =
            shouldContinuePositiveProbeMaterializationOrProductionTruthTokenGateRoute
        this.didConfirmBackingStoreTokenResultEnvelopeConsumed =
            didConfirmBackingStoreTokenResultEnvelopeConsumed
        this.didConfirmFrameHashPersistenceCommitRecheckedAgainstTokenResult =
            didConfirmFrameHashPersistenceCommitRecheckedAgainstTokenResult
        this.didConfirmTokenDenialBlocksFrameHashPersistenceCommit =
            didConfirmTokenDenialBlocksFrameHashPersistenceCommit
        this.didConfirmPositiveProbeStillRequiredForPersistenceCommit =
            didConfirmPositiveProbeStillRequiredForPersistenceCommit
        this.didConfirmNonzeroFrameHashStillRequiredForPersistenceCommit =
            didConfirmNonzeroFrameHashStillRequiredForPersistenceCommit
        this.didConfirmFrameHashPersistenceCommitAdmissionBlocked =
            didConfirmFrameHashPersistenceCommitAdmissionBlocked
        this.didConfirmFrameHashValueRedacted =
            didConfirmFrameHashValueRedacted
        this.didConfirmFrameHashUnpersisted = didConfirmFrameHashUnpersisted
        this.didConfirmResultEnvelopePromotionBlocked =
            didConfirmResultEnvelopePromotionBlocked
        this.didConfirmProductionRenderTruthBlocked =
            didConfirmProductionRenderTruthBlocked
        this.didConfirmBackendReadyTruthBlocked =
            didConfirmBackendReadyTruthBlocked
        this.didConfirmRendererStateWriteAdmissionBlocked =
            didConfirmRendererStateWriteAdmissionBlocked
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked =
            didConfirmRuntimeStateWriteBlocked
        this.didConfirmPositiveProbeMaterializationOrProductionTruthTokenGateNextRoutePrepared =
            didConfirmPositiveProbeMaterializationOrProductionTruthTokenGateNextRoutePrepared
        this.didConfirmNoNativeBridgeExpansion =
            didConfirmNoNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceCommitReadinessRecheckFirstSliceFacts(
    backingStoreTokenResultEnvelopeFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialBackingStoreTokenResultEnvelopeFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceCommitReadinessRecheckFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceCommitReadinessRecheckFirstSliceFacts(
        backingStoreTokenResultEnvelopeFirstSliceReadiness
            .didPrepareBackingStoreTokenResultEnvelopeFirstSliceReadiness,
        true,
        backingStoreTokenResultEnvelopeFirstSliceReadiness
            .shouldKeepBackingStoreTokenIssueDenied,
        backingStoreTokenResultEnvelopeFirstSliceReadiness
            .didConfirmMissingPositiveProbeBlocksTokenIssue,
        backingStoreTokenResultEnvelopeFirstSliceReadiness
            .didConfirmMissingNonzeroFrameHashBlocksTokenIssue,
        true,
        backingStoreTokenResultEnvelopeFirstSliceReadiness
            .didConfirmFrameHashValueRedacted,
        backingStoreTokenResultEnvelopeFirstSliceReadiness
            .didConfirmFrameHashUnpersisted,
        backingStoreTokenResultEnvelopeFirstSliceReadiness
            .didConfirmResultEnvelopePromotionBlocked,
        true,
        true,
        backingStoreTokenResultEnvelopeFirstSliceReadiness
            .didConfirmRendererStateWriteAdmissionBlocked,
        backingStoreTokenResultEnvelopeFirstSliceReadiness
            .didConfirmRendererStateWriteBlocked,
        backingStoreTokenResultEnvelopeFirstSliceReadiness
            .didConfirmRuntimeStateWriteBlocked,
        true,
        backingStoreTokenResultEnvelopeFirstSliceReadiness
            .didConfirmNoNativeBridgeExpansion,
        backingStoreTokenResultEnvelopeFirstSliceReadiness.didConfirmNoPublicApi,
        backingStoreTokenResultEnvelopeFirstSliceReadiness
            .didConfirmNoProductionPublicCAbi,
        backingStoreTokenResultEnvelopeFirstSliceReadiness.didConfirmNoRuntimeStateWrite,
        backingStoreTokenResultEnvelopeFirstSliceReadiness.didConfirmNoCjpmTomlChange,
        backingStoreTokenResultEnvelopeFirstSliceReadiness.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceCommitReadinessRecheckFirstSliceReadiness(
    frameHashPersistenceCommitReadinessRecheckFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceCommitReadinessRecheckFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceCommitReadinessRecheckFirstSliceReadiness {
    let persistenceCommitRecheckReady =
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didConsumeBackingStoreTokenResultEnvelope &&
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didRecheckFrameHashPersistenceCommitAgainstTokenResult &&
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didConfirmTokenDenialBlocksFrameHashPersistenceCommit &&
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didKeepFrameHashPersistenceCommitAdmissionBlocked &&
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didPreparePositiveProbeMaterializationOrProductionTruthTokenGateNextRoute

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceCommitReadinessRecheckFirstSliceReadiness(
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts,
        persistenceCommitRecheckReady,
        persistenceCommitRecheckReady,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didKeepFrameHashPersistenceCommitAdmissionBlocked,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didKeepResultEnvelopePromotionBlocked,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didKeepRendererStateWriteAdmissionBlocked,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didPreparePositiveProbeMaterializationOrProductionTruthTokenGateNextRoute,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didConsumeBackingStoreTokenResultEnvelope,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didRecheckFrameHashPersistenceCommitAgainstTokenResult,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didConfirmTokenDenialBlocksFrameHashPersistenceCommit,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didConfirmPositiveProbeStillRequiredForPersistenceCommit,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didConfirmNonzeroFrameHashStillRequiredForPersistenceCommit,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didKeepFrameHashPersistenceCommitAdmissionBlocked,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didKeepFrameHashValueRedacted,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didKeepFrameHashUnpersisted,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didKeepResultEnvelopePromotionBlocked,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didKeepProductionRenderTruthBlocked,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didKeepBackendReadyTruthBlocked,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didKeepRendererStateWriteAdmissionBlocked,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didKeepRendererStateWriteBlocked,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didKeepRuntimeStateWriteBlocked,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didPreparePositiveProbeMaterializationOrProductionTruthTokenGateNextRoute,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didConfirmNoNativeBridgeExpansion,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts.didConfirmNoPublicApi,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didConfirmNoProductionPublicCAbi,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didConfirmNoRuntimeStateWrite,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts.didConfirmNoCjpmTomlChange,
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
            .didConfirmNoRendererStateWrite
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceCommitReadinessRecheckFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceCommitReadinessRecheckFirstSliceReadiness {
    let backingStoreTokenResultEnvelopeFirstSliceReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialBackingStoreTokenResultEnvelopeFirstSliceDraft()
    let frameHashPersistenceCommitReadinessRecheckFirstSliceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceCommitReadinessRecheckFirstSliceFacts(
            backingStoreTokenResultEnvelopeFirstSliceReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceCommitReadinessRecheckFirstSliceReadiness(
        frameHashPersistenceCommitReadinessRecheckFirstSliceFacts
    )
}
