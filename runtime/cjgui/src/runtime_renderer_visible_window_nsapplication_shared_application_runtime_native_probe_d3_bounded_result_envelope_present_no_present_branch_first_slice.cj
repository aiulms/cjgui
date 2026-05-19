// 中文维护注释：本文件是 visible-window runtime native probe 的
// present/no-present branch first-slice readiness owner。
// Owner: runtime renderer internal present/no-present branch first slice。
// Truth: 消费 stage114 command-buffer commit no-present readiness，把下一步收敛为
// bounded isolated probe-local present scheduling envelope；只有正向 commit envelope
// 才能进入 present 分支，缺失时必须停在 no-present 分支。
// Stop-line: 本 owner 只允许 isolated probe-local present scheduling contract，
// 不写 renderer state，不把 isolated present evidence 升级为 production render
// truth，也不扩 production native bridge C ABI。
// Same-shape Boundary Brake: 本 owner 必须表达 present/no-present branch contract；
// 不得退化成 approval、external packet、recovery、report wrapper 或 generic guard。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceFacts {
    let didConsumeCommandBufferCommitNoPresentFirstSliceReadiness: Bool
    let didRequirePositiveCommandBufferCommitNoPresentEnvelopeBeforePresentBranch:
        Bool
    let didRequireBoundedIsolatedPresentNoPresentBranchProbe: Bool
    let didRequireProbeLocalDrawablePresentScheduling: Bool
    let didRequirePresentAfterEncodingBeforeCommit: Bool
    let didRequireProbeLocalCommandBufferCommitAfterPresentScheduling: Bool
    let didRequireBoundedPresentCompletionWait: Bool
    let didRequireCommandBufferStatusCompletedClassification: Bool
    let didAllowBoundedDrawablePresentScheduledEnvelope: Bool
    let didRequireNoPresentBranchWhenCommitEnvelopeMissing: Bool
    let didKeepProductionPresentBlocked: Bool
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
        didConsumeCommandBufferCommitNoPresentFirstSliceReadiness: Bool,
        didRequirePositiveCommandBufferCommitNoPresentEnvelopeBeforePresentBranch:
            Bool,
        didRequireBoundedIsolatedPresentNoPresentBranchProbe: Bool,
        didRequireProbeLocalDrawablePresentScheduling: Bool,
        didRequirePresentAfterEncodingBeforeCommit: Bool,
        didRequireProbeLocalCommandBufferCommitAfterPresentScheduling: Bool,
        didRequireBoundedPresentCompletionWait: Bool,
        didRequireCommandBufferStatusCompletedClassification: Bool,
        didAllowBoundedDrawablePresentScheduledEnvelope: Bool,
        didRequireNoPresentBranchWhenCommitEnvelopeMissing: Bool,
        didKeepProductionPresentBlocked: Bool,
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
        this.didConsumeCommandBufferCommitNoPresentFirstSliceReadiness =
            didConsumeCommandBufferCommitNoPresentFirstSliceReadiness
        this.didRequirePositiveCommandBufferCommitNoPresentEnvelopeBeforePresentBranch =
            didRequirePositiveCommandBufferCommitNoPresentEnvelopeBeforePresentBranch
        this.didRequireBoundedIsolatedPresentNoPresentBranchProbe =
            didRequireBoundedIsolatedPresentNoPresentBranchProbe
        this.didRequireProbeLocalDrawablePresentScheduling =
            didRequireProbeLocalDrawablePresentScheduling
        this.didRequirePresentAfterEncodingBeforeCommit =
            didRequirePresentAfterEncodingBeforeCommit
        this.didRequireProbeLocalCommandBufferCommitAfterPresentScheduling =
            didRequireProbeLocalCommandBufferCommitAfterPresentScheduling
        this.didRequireBoundedPresentCompletionWait =
            didRequireBoundedPresentCompletionWait
        this.didRequireCommandBufferStatusCompletedClassification =
            didRequireCommandBufferStatusCompletedClassification
        this.didAllowBoundedDrawablePresentScheduledEnvelope =
            didAllowBoundedDrawablePresentScheduledEnvelope
        this.didRequireNoPresentBranchWhenCommitEnvelopeMissing =
            didRequireNoPresentBranchWhenCommitEnvelopeMissing
        this.didKeepProductionPresentBlocked = didKeepProductionPresentBlocked
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceReadiness {
    let commandBufferCommitNoPresentFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceReadiness
    let presentNoPresentBranchFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceFacts
    let didPrepareRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceReadiness:
        Bool
    let shouldConsumeCommandBufferCommitNoPresentFirstSliceReadiness: Bool
    let shouldRequirePositiveCommandBufferCommitNoPresentEnvelopeBeforePresentBranch:
        Bool
    let shouldRequireBoundedIsolatedPresentNoPresentBranchProbe: Bool
    let shouldRequireProbeLocalDrawablePresentScheduling: Bool
    let shouldRequirePresentAfterEncodingBeforeCommit: Bool
    let shouldRequireProbeLocalCommandBufferCommitAfterPresentScheduling: Bool
    let shouldRequireBoundedPresentCompletionWait: Bool
    let shouldRequireCommandBufferStatusCompletedClassification: Bool
    let shouldAllowBoundedDrawablePresentScheduledEnvelope: Bool
    let shouldRequireNoPresentBranchWhenCommitEnvelopeMissing: Bool
    let shouldKeepProductionPresentBlocked: Bool
    let shouldKeepProductionRenderTruthBlocked: Bool
    let shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool
    let shouldKeepRendererStateWriteBlocked: Bool
    let didConfirmCommandBufferCommitNoPresentFirstSliceInput: Bool
    let didConfirmPresentBranchOrdering: Bool
    let didConfirmPresentBranchStopLine: Bool
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
        commandBufferCommitNoPresentFirstSliceReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceReadiness,
        presentNoPresentBranchFirstSliceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceFacts,
        didPrepareRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceReadiness:
            Bool,
        shouldConsumeCommandBufferCommitNoPresentFirstSliceReadiness: Bool,
        shouldRequirePositiveCommandBufferCommitNoPresentEnvelopeBeforePresentBranch:
            Bool,
        shouldRequireBoundedIsolatedPresentNoPresentBranchProbe: Bool,
        shouldRequireProbeLocalDrawablePresentScheduling: Bool,
        shouldRequirePresentAfterEncodingBeforeCommit: Bool,
        shouldRequireProbeLocalCommandBufferCommitAfterPresentScheduling: Bool,
        shouldRequireBoundedPresentCompletionWait: Bool,
        shouldRequireCommandBufferStatusCompletedClassification: Bool,
        shouldAllowBoundedDrawablePresentScheduledEnvelope: Bool,
        shouldRequireNoPresentBranchWhenCommitEnvelopeMissing: Bool,
        shouldKeepProductionPresentBlocked: Bool,
        shouldKeepProductionRenderTruthBlocked: Bool,
        shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool,
        shouldKeepRendererStateWriteBlocked: Bool,
        didConfirmCommandBufferCommitNoPresentFirstSliceInput: Bool,
        didConfirmPresentBranchOrdering: Bool,
        didConfirmPresentBranchStopLine: Bool,
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
        this.commandBufferCommitNoPresentFirstSliceReadiness =
            commandBufferCommitNoPresentFirstSliceReadiness
        this.presentNoPresentBranchFirstSliceFacts =
            presentNoPresentBranchFirstSliceFacts
        this.didPrepareRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceReadiness =
            didPrepareRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceReadiness
        this.shouldConsumeCommandBufferCommitNoPresentFirstSliceReadiness =
            shouldConsumeCommandBufferCommitNoPresentFirstSliceReadiness
        this.shouldRequirePositiveCommandBufferCommitNoPresentEnvelopeBeforePresentBranch =
            shouldRequirePositiveCommandBufferCommitNoPresentEnvelopeBeforePresentBranch
        this.shouldRequireBoundedIsolatedPresentNoPresentBranchProbe =
            shouldRequireBoundedIsolatedPresentNoPresentBranchProbe
        this.shouldRequireProbeLocalDrawablePresentScheduling =
            shouldRequireProbeLocalDrawablePresentScheduling
        this.shouldRequirePresentAfterEncodingBeforeCommit =
            shouldRequirePresentAfterEncodingBeforeCommit
        this.shouldRequireProbeLocalCommandBufferCommitAfterPresentScheduling =
            shouldRequireProbeLocalCommandBufferCommitAfterPresentScheduling
        this.shouldRequireBoundedPresentCompletionWait =
            shouldRequireBoundedPresentCompletionWait
        this.shouldRequireCommandBufferStatusCompletedClassification =
            shouldRequireCommandBufferStatusCompletedClassification
        this.shouldAllowBoundedDrawablePresentScheduledEnvelope =
            shouldAllowBoundedDrawablePresentScheduledEnvelope
        this.shouldRequireNoPresentBranchWhenCommitEnvelopeMissing =
            shouldRequireNoPresentBranchWhenCommitEnvelopeMissing
        this.shouldKeepProductionPresentBlocked =
            shouldKeepProductionPresentBlocked
        this.shouldKeepProductionRenderTruthBlocked =
            shouldKeepProductionRenderTruthBlocked
        this.shouldRequireProductionWriteAdmissionBeforeRendererStateWrite =
            shouldRequireProductionWriteAdmissionBeforeRendererStateWrite
        this.shouldKeepRendererStateWriteBlocked =
            shouldKeepRendererStateWriteBlocked
        this.didConfirmCommandBufferCommitNoPresentFirstSliceInput =
            didConfirmCommandBufferCommitNoPresentFirstSliceInput
        this.didConfirmPresentBranchOrdering = didConfirmPresentBranchOrdering
        this.didConfirmPresentBranchStopLine = didConfirmPresentBranchStopLine
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

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceFacts(
    commandBufferCommitNoPresentFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceFacts(
        commandBufferCommitNoPresentFirstSliceReadiness
            .didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceReadiness,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        commandBufferCommitNoPresentFirstSliceReadiness.shouldKeepPresentBlocked,
        commandBufferCommitNoPresentFirstSliceReadiness
            .shouldKeepProductionRenderTruthBlocked,
        commandBufferCommitNoPresentFirstSliceReadiness
            .shouldRequireProductionWriteAdmissionBeforeRendererStateWrite,
        commandBufferCommitNoPresentFirstSliceReadiness
            .shouldKeepRendererStateWriteBlocked,
        commandBufferCommitNoPresentFirstSliceReadiness
            .didConfirmNoProductionTruthUpgrade,
        commandBufferCommitNoPresentFirstSliceReadiness
            .didConfirmNoBackendReadyTruth,
        commandBufferCommitNoPresentFirstSliceReadiness
            .didConfirmNoProductionNativeBridgeExpansion,
        commandBufferCommitNoPresentFirstSliceReadiness
            .didConfirmNoPublicApi,
        commandBufferCommitNoPresentFirstSliceReadiness
            .didConfirmNoProductionPublicCAbi,
        commandBufferCommitNoPresentFirstSliceReadiness
            .didConfirmNoRuntimeStateWrite,
        commandBufferCommitNoPresentFirstSliceReadiness.didConfirmNoCjpmTomlChange,
        commandBufferCommitNoPresentFirstSliceReadiness
            .didConfirmNoRendererStateWrite,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceReadiness(
    commandBufferCommitNoPresentFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceReadiness,
    presentNoPresentBranchFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceReadiness {
    let commandBufferCommitInputReady =
        presentNoPresentBranchFirstSliceFacts
            .didConsumeCommandBufferCommitNoPresentFirstSliceReadiness &&
        commandBufferCommitNoPresentFirstSliceReadiness
            .didConfirmCommandBufferCommitOrdering &&
        commandBufferCommitNoPresentFirstSliceReadiness
            .didConfirmCommandBufferCommitStopLine
    let presentBranchOrderingReady =
        presentNoPresentBranchFirstSliceFacts
            .didRequirePositiveCommandBufferCommitNoPresentEnvelopeBeforePresentBranch &&
        presentNoPresentBranchFirstSliceFacts
            .didRequireBoundedIsolatedPresentNoPresentBranchProbe &&
        presentNoPresentBranchFirstSliceFacts
            .didRequireProbeLocalDrawablePresentScheduling &&
        presentNoPresentBranchFirstSliceFacts
            .didRequirePresentAfterEncodingBeforeCommit &&
        presentNoPresentBranchFirstSliceFacts
            .didRequireProbeLocalCommandBufferCommitAfterPresentScheduling &&
        presentNoPresentBranchFirstSliceFacts
            .didRequireBoundedPresentCompletionWait &&
        presentNoPresentBranchFirstSliceFacts
            .didRequireCommandBufferStatusCompletedClassification &&
        presentNoPresentBranchFirstSliceFacts
            .didAllowBoundedDrawablePresentScheduledEnvelope &&
        presentNoPresentBranchFirstSliceFacts
            .didRequireNoPresentBranchWhenCommitEnvelopeMissing
    let stopLineReady =
        presentNoPresentBranchFirstSliceFacts.didKeepProductionPresentBlocked &&
        presentNoPresentBranchFirstSliceFacts
            .didKeepProductionRenderTruthBlocked &&
        presentNoPresentBranchFirstSliceFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite &&
        presentNoPresentBranchFirstSliceFacts
            .didKeepRendererStateWriteBlocked &&
        presentNoPresentBranchFirstSliceFacts
            .didConfirmNoProductionTruthUpgrade &&
        presentNoPresentBranchFirstSliceFacts.didConfirmNoBackendReadyTruth &&
        presentNoPresentBranchFirstSliceFacts
            .didConfirmNoProductionNativeBridgeExpansion &&
        presentNoPresentBranchFirstSliceFacts.didConfirmNoPublicApi &&
        presentNoPresentBranchFirstSliceFacts
            .didConfirmNoProductionPublicCAbi &&
        presentNoPresentBranchFirstSliceFacts.didConfirmNoRuntimeStateWrite &&
        presentNoPresentBranchFirstSliceFacts.didConfirmNoCjpmTomlChange &&
        presentNoPresentBranchFirstSliceFacts.didConfirmNoRendererStateWrite &&
        presentNoPresentBranchFirstSliceFacts
            .didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    let readinessReady =
        commandBufferCommitInputReady && presentBranchOrderingReady &&
        stopLineReady

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceReadiness(
        commandBufferCommitNoPresentFirstSliceReadiness,
        presentNoPresentBranchFirstSliceFacts,
        readinessReady,
        presentNoPresentBranchFirstSliceFacts
            .didConsumeCommandBufferCommitNoPresentFirstSliceReadiness,
        presentNoPresentBranchFirstSliceFacts
            .didRequirePositiveCommandBufferCommitNoPresentEnvelopeBeforePresentBranch,
        presentNoPresentBranchFirstSliceFacts
            .didRequireBoundedIsolatedPresentNoPresentBranchProbe,
        presentNoPresentBranchFirstSliceFacts
            .didRequireProbeLocalDrawablePresentScheduling,
        presentNoPresentBranchFirstSliceFacts
            .didRequirePresentAfterEncodingBeforeCommit,
        presentNoPresentBranchFirstSliceFacts
            .didRequireProbeLocalCommandBufferCommitAfterPresentScheduling,
        presentNoPresentBranchFirstSliceFacts
            .didRequireBoundedPresentCompletionWait,
        presentNoPresentBranchFirstSliceFacts
            .didRequireCommandBufferStatusCompletedClassification,
        presentNoPresentBranchFirstSliceFacts
            .didAllowBoundedDrawablePresentScheduledEnvelope,
        presentNoPresentBranchFirstSliceFacts
            .didRequireNoPresentBranchWhenCommitEnvelopeMissing,
        presentNoPresentBranchFirstSliceFacts.didKeepProductionPresentBlocked,
        presentNoPresentBranchFirstSliceFacts
            .didKeepProductionRenderTruthBlocked,
        presentNoPresentBranchFirstSliceFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite,
        presentNoPresentBranchFirstSliceFacts
            .didKeepRendererStateWriteBlocked,
        commandBufferCommitInputReady,
        presentBranchOrderingReady,
        stopLineReady,
        presentNoPresentBranchFirstSliceFacts
            .didConfirmNoProductionTruthUpgrade,
        presentNoPresentBranchFirstSliceFacts.didConfirmNoBackendReadyTruth,
        presentNoPresentBranchFirstSliceFacts
            .didConfirmNoProductionNativeBridgeExpansion,
        presentNoPresentBranchFirstSliceFacts.didConfirmNoPublicApi,
        presentNoPresentBranchFirstSliceFacts
            .didConfirmNoProductionPublicCAbi,
        presentNoPresentBranchFirstSliceFacts.didConfirmNoRuntimeStateWrite,
        presentNoPresentBranchFirstSliceFacts.didConfirmNoCjpmTomlChange,
        presentNoPresentBranchFirstSliceFacts.didConfirmNoRendererStateWrite,
        presentNoPresentBranchFirstSliceFacts
            .didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceReadiness {
    let commandBufferCommitNoPresentFirstSliceReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceDraft()
    let presentNoPresentBranchFirstSliceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceFacts(
            commandBufferCommitNoPresentFirstSliceReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceReadiness(
        commandBufferCommitNoPresentFirstSliceReadiness,
        presentNoPresentBranchFirstSliceFacts
    )
}
