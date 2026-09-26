// 中文维护注释：本文件是 visible-window runtime native probe 的 command-buffer
// commit no-present first-slice readiness owner。
// Owner: runtime renderer internal command buffer commit no-present first slice。
// Truth: 消费 stage113 draw-call first-slice readiness，把下一步收敛为 bounded
// isolated probe-local command buffer commit / completion envelope：draw encoding
// 完成后 commit command buffer，等待 bounded completion，然后仍不 present。
// Stop-line: 本 owner 不 present，不写 renderer state，不把 isolated GPU
// submission evidence 升级为 production render truth，也不扩 production native
// bridge C ABI。
// Cleanup: command-buffer completion 之后必须把 probe-local attachment texture、
// layer device 与 visible-window resources 解除绑定，并把 bridge table count
// 清理结果作为 envelope fact 暴露；该事实仍然只属于 isolated probe。
// Same-shape Boundary Brake: 本 owner 必须表达 command-buffer commit no-present
// first-slice contract；不得退化成 approval、external packet、recovery、report
// wrapper 或 generic guard。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceFacts {
    let didConsumeDrawCallFirstSliceReadiness: Bool
    let didRequirePositiveDrawCallEnvelopeBeforeCommit: Bool
    let didRequireBoundedIsolatedCommandBufferCommitProbe: Bool
    let didRequireProbeLocalDrawBeforeCommit: Bool
    let didRequireEndEncodingBeforeCommit: Bool
    let didRequireProbeLocalCommandBufferCommit: Bool
    let didRequireBoundedCommandBufferCompletionWait: Bool
    let didRequireCommandBufferStatusCompletedClassification: Bool
    let didAllowBoundedGpuSubmissionCompletionEnvelope: Bool
    let didRequirePostCommitCleanupLifecycleObservation: Bool
    let didRequireLayerDeviceDetachBeforeCleanup: Bool
    let didRequireAttachmentTextureDetachBeforeCleanup: Bool
    let didRequireBridgeTableCountsCleanAfterCleanup: Bool
    let didExposeCleanupLifecycleResultEnvelope: Bool
    let didKeepPresentBlocked: Bool
    let didKeepProductionRenderTruthBlocked: Bool
    let didRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didConfirmNoProductionTruthUpgrade: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didConfirmNoProductionNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didAvoidApprovalExternalPacketRecoveryOrReportWrapper: Bool

    init(
        didConsumeDrawCallFirstSliceReadiness: Bool,
        didRequirePositiveDrawCallEnvelopeBeforeCommit: Bool,
        didRequireBoundedIsolatedCommandBufferCommitProbe: Bool,
        didRequireProbeLocalDrawBeforeCommit: Bool,
        didRequireEndEncodingBeforeCommit: Bool,
        didRequireProbeLocalCommandBufferCommit: Bool,
        didRequireBoundedCommandBufferCompletionWait: Bool,
        didRequireCommandBufferStatusCompletedClassification: Bool,
        didAllowBoundedGpuSubmissionCompletionEnvelope: Bool,
        didRequirePostCommitCleanupLifecycleObservation: Bool,
        didRequireLayerDeviceDetachBeforeCleanup: Bool,
        didRequireAttachmentTextureDetachBeforeCleanup: Bool,
        didRequireBridgeTableCountsCleanAfterCleanup: Bool,
        didExposeCleanupLifecycleResultEnvelope: Bool,
        didKeepPresentBlocked: Bool,
        didKeepProductionRenderTruthBlocked: Bool,
        didRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didConfirmNoProductionTruthUpgrade: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didConfirmNoProductionNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didAvoidApprovalExternalPacketRecoveryOrReportWrapper: Bool
    ) {
        this.didConsumeDrawCallFirstSliceReadiness =
            didConsumeDrawCallFirstSliceReadiness
        this.didRequirePositiveDrawCallEnvelopeBeforeCommit =
            didRequirePositiveDrawCallEnvelopeBeforeCommit
        this.didRequireBoundedIsolatedCommandBufferCommitProbe =
            didRequireBoundedIsolatedCommandBufferCommitProbe
        this.didRequireProbeLocalDrawBeforeCommit =
            didRequireProbeLocalDrawBeforeCommit
        this.didRequireEndEncodingBeforeCommit =
            didRequireEndEncodingBeforeCommit
        this.didRequireProbeLocalCommandBufferCommit =
            didRequireProbeLocalCommandBufferCommit
        this.didRequireBoundedCommandBufferCompletionWait =
            didRequireBoundedCommandBufferCompletionWait
        this.didRequireCommandBufferStatusCompletedClassification =
            didRequireCommandBufferStatusCompletedClassification
        this.didAllowBoundedGpuSubmissionCompletionEnvelope =
            didAllowBoundedGpuSubmissionCompletionEnvelope
        this.didRequirePostCommitCleanupLifecycleObservation =
            didRequirePostCommitCleanupLifecycleObservation
        this.didRequireLayerDeviceDetachBeforeCleanup =
            didRequireLayerDeviceDetachBeforeCleanup
        this.didRequireAttachmentTextureDetachBeforeCleanup =
            didRequireAttachmentTextureDetachBeforeCleanup
        this.didRequireBridgeTableCountsCleanAfterCleanup =
            didRequireBridgeTableCountsCleanAfterCleanup
        this.didExposeCleanupLifecycleResultEnvelope =
            didExposeCleanupLifecycleResultEnvelope
        this.didKeepPresentBlocked = didKeepPresentBlocked
        this.didKeepProductionRenderTruthBlocked =
            didKeepProductionRenderTruthBlocked
        this.didRequireProductionWriteAdmissionBeforeRendererStateWrite =
            didRequireProductionWriteAdmissionBeforeRendererStateWrite
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didConfirmNoProductionTruthUpgrade =
            didConfirmNoProductionTruthUpgrade
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didConfirmNoProductionNativeBridgeExpansion =
            didConfirmNoProductionNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didAvoidApprovalExternalPacketRecoveryOrReportWrapper =
            didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceReadiness {
    let drawCallFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceReadiness
    let commandBufferCommitNoPresentFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceFacts
    let didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceReadiness:
        Bool
    let shouldConsumeDrawCallFirstSliceReadiness: Bool
    let shouldRequirePositiveDrawCallEnvelopeBeforeCommit: Bool
    let shouldRequireBoundedIsolatedCommandBufferCommitProbe: Bool
    let shouldRequireProbeLocalDrawBeforeCommit: Bool
    let shouldRequireEndEncodingBeforeCommit: Bool
    let shouldRequireProbeLocalCommandBufferCommit: Bool
    let shouldRequireBoundedCommandBufferCompletionWait: Bool
    let shouldRequireCommandBufferStatusCompletedClassification: Bool
    let shouldAllowBoundedGpuSubmissionCompletionEnvelope: Bool
    let shouldRequirePostCommitCleanupLifecycleObservation: Bool
    let shouldRequireLayerDeviceDetachBeforeCleanup: Bool
    let shouldRequireAttachmentTextureDetachBeforeCleanup: Bool
    let shouldRequireBridgeTableCountsCleanAfterCleanup: Bool
    let shouldExposeCleanupLifecycleResultEnvelope: Bool
    let shouldKeepPresentBlocked: Bool
    let shouldKeepProductionRenderTruthBlocked: Bool
    let shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool
    let shouldKeepRendererStateWriteBlocked: Bool
    let didConfirmDrawCallFirstSliceInput: Bool
    let didConfirmCommandBufferCommitOrdering: Bool
    let didConfirmPostCommitCleanupLifecycleContract: Bool
    let didConfirmCommandBufferCommitStopLine: Bool
    let didConfirmNoProductionTruthUpgrade: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didConfirmNoProductionNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didAvoidApprovalExternalPacketRecoveryOrReportWrapper: Bool

    init(
        drawCallFirstSliceReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceReadiness,
        commandBufferCommitNoPresentFirstSliceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceFacts,
        didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceReadiness:
            Bool,
        shouldConsumeDrawCallFirstSliceReadiness: Bool,
        shouldRequirePositiveDrawCallEnvelopeBeforeCommit: Bool,
        shouldRequireBoundedIsolatedCommandBufferCommitProbe: Bool,
        shouldRequireProbeLocalDrawBeforeCommit: Bool,
        shouldRequireEndEncodingBeforeCommit: Bool,
        shouldRequireProbeLocalCommandBufferCommit: Bool,
        shouldRequireBoundedCommandBufferCompletionWait: Bool,
        shouldRequireCommandBufferStatusCompletedClassification: Bool,
        shouldAllowBoundedGpuSubmissionCompletionEnvelope: Bool,
        shouldRequirePostCommitCleanupLifecycleObservation: Bool,
        shouldRequireLayerDeviceDetachBeforeCleanup: Bool,
        shouldRequireAttachmentTextureDetachBeforeCleanup: Bool,
        shouldRequireBridgeTableCountsCleanAfterCleanup: Bool,
        shouldExposeCleanupLifecycleResultEnvelope: Bool,
        shouldKeepPresentBlocked: Bool,
        shouldKeepProductionRenderTruthBlocked: Bool,
        shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool,
        shouldKeepRendererStateWriteBlocked: Bool,
        didConfirmDrawCallFirstSliceInput: Bool,
        didConfirmCommandBufferCommitOrdering: Bool,
        didConfirmPostCommitCleanupLifecycleContract: Bool,
        didConfirmCommandBufferCommitStopLine: Bool,
        didConfirmNoProductionTruthUpgrade: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didConfirmNoProductionNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didAvoidApprovalExternalPacketRecoveryOrReportWrapper: Bool
    ) {
        this.drawCallFirstSliceReadiness = drawCallFirstSliceReadiness
        this.commandBufferCommitNoPresentFirstSliceFacts =
            commandBufferCommitNoPresentFirstSliceFacts
        this.didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceReadiness =
            didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceReadiness
        this.shouldConsumeDrawCallFirstSliceReadiness =
            shouldConsumeDrawCallFirstSliceReadiness
        this.shouldRequirePositiveDrawCallEnvelopeBeforeCommit =
            shouldRequirePositiveDrawCallEnvelopeBeforeCommit
        this.shouldRequireBoundedIsolatedCommandBufferCommitProbe =
            shouldRequireBoundedIsolatedCommandBufferCommitProbe
        this.shouldRequireProbeLocalDrawBeforeCommit =
            shouldRequireProbeLocalDrawBeforeCommit
        this.shouldRequireEndEncodingBeforeCommit =
            shouldRequireEndEncodingBeforeCommit
        this.shouldRequireProbeLocalCommandBufferCommit =
            shouldRequireProbeLocalCommandBufferCommit
        this.shouldRequireBoundedCommandBufferCompletionWait =
            shouldRequireBoundedCommandBufferCompletionWait
        this.shouldRequireCommandBufferStatusCompletedClassification =
            shouldRequireCommandBufferStatusCompletedClassification
        this.shouldAllowBoundedGpuSubmissionCompletionEnvelope =
            shouldAllowBoundedGpuSubmissionCompletionEnvelope
        this.shouldRequirePostCommitCleanupLifecycleObservation =
            shouldRequirePostCommitCleanupLifecycleObservation
        this.shouldRequireLayerDeviceDetachBeforeCleanup =
            shouldRequireLayerDeviceDetachBeforeCleanup
        this.shouldRequireAttachmentTextureDetachBeforeCleanup =
            shouldRequireAttachmentTextureDetachBeforeCleanup
        this.shouldRequireBridgeTableCountsCleanAfterCleanup =
            shouldRequireBridgeTableCountsCleanAfterCleanup
        this.shouldExposeCleanupLifecycleResultEnvelope =
            shouldExposeCleanupLifecycleResultEnvelope
        this.shouldKeepPresentBlocked = shouldKeepPresentBlocked
        this.shouldKeepProductionRenderTruthBlocked =
            shouldKeepProductionRenderTruthBlocked
        this.shouldRequireProductionWriteAdmissionBeforeRendererStateWrite =
            shouldRequireProductionWriteAdmissionBeforeRendererStateWrite
        this.shouldKeepRendererStateWriteBlocked =
            shouldKeepRendererStateWriteBlocked
        this.didConfirmDrawCallFirstSliceInput =
            didConfirmDrawCallFirstSliceInput
        this.didConfirmCommandBufferCommitOrdering =
            didConfirmCommandBufferCommitOrdering
        this.didConfirmPostCommitCleanupLifecycleContract =
            didConfirmPostCommitCleanupLifecycleContract
        this.didConfirmCommandBufferCommitStopLine =
            didConfirmCommandBufferCommitStopLine
        this.didConfirmNoProductionTruthUpgrade =
            didConfirmNoProductionTruthUpgrade
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didConfirmNoProductionNativeBridgeExpansion =
            didConfirmNoProductionNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didAvoidApprovalExternalPacketRecoveryOrReportWrapper =
            didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceFacts(
    drawCallFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceFacts(
        drawCallFirstSliceReadiness
            .didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceReadiness,
        true,
        true,
        drawCallFirstSliceReadiness.shouldRequireProbeLocalDrawPrimitivesCall,
        drawCallFirstSliceReadiness.shouldRequireEndEncodingAfterDrawBeforeCleanup,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        drawCallFirstSliceReadiness
            .shouldRequireProductionWriteAdmissionBeforeRendererStateWrite,
        drawCallFirstSliceReadiness.shouldKeepRendererStateWriteBlocked,
        drawCallFirstSliceReadiness.didConfirmNoProductionTruthUpgrade,
        drawCallFirstSliceReadiness.didConfirmNoBackendReadyTruth,
        drawCallFirstSliceReadiness.didConfirmNoProductionNativeBridgeExpansion,
        drawCallFirstSliceReadiness.didConfirmNoPublicApi,
        drawCallFirstSliceReadiness.didConfirmNoProductionPublicCAbi,
        drawCallFirstSliceReadiness.didConfirmNoRuntimeStateWrite,
        drawCallFirstSliceReadiness.didConfirmNoCjpmTomlChange,
        drawCallFirstSliceReadiness.didConfirmNoRendererStateWrite,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceReadiness(
    drawCallFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceReadiness,
    commandBufferCommitNoPresentFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceReadiness {
    let drawCallInputReady =
        commandBufferCommitNoPresentFirstSliceFacts
            .didConsumeDrawCallFirstSliceReadiness &&
        drawCallFirstSliceReadiness.didConfirmDrawCallOrdering &&
        drawCallFirstSliceReadiness.didConfirmDrawCallStopLine
    let commitOrderingReady =
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequirePositiveDrawCallEnvelopeBeforeCommit &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequireBoundedIsolatedCommandBufferCommitProbe &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequireProbeLocalDrawBeforeCommit &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequireEndEncodingBeforeCommit &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequireProbeLocalCommandBufferCommit &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequireBoundedCommandBufferCompletionWait &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequireCommandBufferStatusCompletedClassification &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didAllowBoundedGpuSubmissionCompletionEnvelope
    let cleanupLifecycleReady =
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequirePostCommitCleanupLifecycleObservation &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequireLayerDeviceDetachBeforeCleanup &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequireAttachmentTextureDetachBeforeCleanup &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequireBridgeTableCountsCleanAfterCleanup &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didExposeCleanupLifecycleResultEnvelope
    let stopLineReady =
        commandBufferCommitNoPresentFirstSliceFacts.didKeepPresentBlocked &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didKeepProductionRenderTruthBlocked &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didKeepRendererStateWriteBlocked &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didConfirmNoProductionTruthUpgrade &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didConfirmNoBackendReadyTruth &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didConfirmNoProductionNativeBridgeExpansion &&
        commandBufferCommitNoPresentFirstSliceFacts.didConfirmNoPublicApi &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didConfirmNoProductionPublicCAbi &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didConfirmNoRuntimeStateWrite &&
        commandBufferCommitNoPresentFirstSliceFacts.didConfirmNoCjpmTomlChange &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didConfirmNoRendererStateWrite &&
        commandBufferCommitNoPresentFirstSliceFacts
            .didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    let readinessReady =
        drawCallInputReady && commitOrderingReady && cleanupLifecycleReady &&
        stopLineReady

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceReadiness(
        drawCallFirstSliceReadiness,
        commandBufferCommitNoPresentFirstSliceFacts,
        readinessReady,
        commandBufferCommitNoPresentFirstSliceFacts
            .didConsumeDrawCallFirstSliceReadiness,
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequirePositiveDrawCallEnvelopeBeforeCommit,
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequireBoundedIsolatedCommandBufferCommitProbe,
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequireProbeLocalDrawBeforeCommit,
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequireEndEncodingBeforeCommit,
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequireProbeLocalCommandBufferCommit,
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequireBoundedCommandBufferCompletionWait,
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequireCommandBufferStatusCompletedClassification,
        commandBufferCommitNoPresentFirstSliceFacts
            .didAllowBoundedGpuSubmissionCompletionEnvelope,
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequirePostCommitCleanupLifecycleObservation,
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequireLayerDeviceDetachBeforeCleanup,
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequireAttachmentTextureDetachBeforeCleanup,
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequireBridgeTableCountsCleanAfterCleanup,
        commandBufferCommitNoPresentFirstSliceFacts
            .didExposeCleanupLifecycleResultEnvelope,
        commandBufferCommitNoPresentFirstSliceFacts.didKeepPresentBlocked,
        commandBufferCommitNoPresentFirstSliceFacts
            .didKeepProductionRenderTruthBlocked,
        commandBufferCommitNoPresentFirstSliceFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite,
        commandBufferCommitNoPresentFirstSliceFacts
            .didKeepRendererStateWriteBlocked,
        drawCallInputReady,
        commitOrderingReady,
        cleanupLifecycleReady,
        stopLineReady,
        commandBufferCommitNoPresentFirstSliceFacts
            .didConfirmNoProductionTruthUpgrade,
        commandBufferCommitNoPresentFirstSliceFacts.didConfirmNoBackendReadyTruth,
        commandBufferCommitNoPresentFirstSliceFacts
            .didConfirmNoProductionNativeBridgeExpansion,
        commandBufferCommitNoPresentFirstSliceFacts.didConfirmNoPublicApi,
        commandBufferCommitNoPresentFirstSliceFacts
            .didConfirmNoProductionPublicCAbi,
        commandBufferCommitNoPresentFirstSliceFacts.didConfirmNoRuntimeStateWrite,
        commandBufferCommitNoPresentFirstSliceFacts.didConfirmNoCjpmTomlChange,
        commandBufferCommitNoPresentFirstSliceFacts.didConfirmNoRendererStateWrite,
        commandBufferCommitNoPresentFirstSliceFacts
            .didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceReadiness {
    let drawCallFirstSliceReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceDraft()
    let commandBufferCommitNoPresentFirstSliceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceFacts(
            drawCallFirstSliceReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceReadiness(
        drawCallFirstSliceReadiness,
        commandBufferCommitNoPresentFirstSliceFacts
    )
}
