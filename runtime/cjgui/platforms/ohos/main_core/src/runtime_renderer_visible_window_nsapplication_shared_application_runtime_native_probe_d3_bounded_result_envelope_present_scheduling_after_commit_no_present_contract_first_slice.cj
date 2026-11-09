// 中文维护注释：本文件是 stage141 present scheduling after stage140
// commit no-present contract first-slice runtime owner。
// Owner: runtime renderer internal present scheduling contract after isolated
// command-buffer commit/no-present envelope。
// Truth: 只消费 stage140 commit envelope；只有 packet 证明 commit 与 bounded
// submission 已经正向成立后，才允许 isolated probe-local present scheduling。
// Stop-line: 本 owner 不执行 native AppKit/Metal，不观测 first frame，不升级
// production render truth，不写 renderer state / runtime_state.cj，不扩 public API /
// public C ABI / native bridge。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentSchedulingAfterCommitNoPresentContractFirstSliceFacts {
    let didConsumeCommandBufferCommitNoPresentAfterDrawCallContract: Bool
    let didRequireStage140CommitNoPresentPacket: Bool
    let didRequirePositiveCommitBeforePresentScheduling: Bool
    let didRequireBoundedPresentSchedulingProbe: Bool
    let didRequireProbeLocalDrawablePresentScheduling: Bool
    let didRequirePresentAfterEncodingBeforeCommit: Bool
    let didRequireProbeLocalCommitAfterPresentScheduling: Bool
    let didRequireBoundedCompletionWait: Bool
    let didRequireDrawablePresentScheduledEnvelope: Bool
    let didRequireNoPresentBranchWhenCommitMissing: Bool
    let didKeepFirstFrameObservationBlocked: Bool
    let didKeepProductionTruthPromotionBlocked: Bool
    let didKeepRendererStateWriteAdmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool

    init(
        didConsumeCommandBufferCommitNoPresentAfterDrawCallContract: Bool,
        didRequireStage140CommitNoPresentPacket: Bool,
        didRequirePositiveCommitBeforePresentScheduling: Bool,
        didRequireBoundedPresentSchedulingProbe: Bool,
        didRequireProbeLocalDrawablePresentScheduling: Bool,
        didRequirePresentAfterEncodingBeforeCommit: Bool,
        didRequireProbeLocalCommitAfterPresentScheduling: Bool,
        didRequireBoundedCompletionWait: Bool,
        didRequireDrawablePresentScheduledEnvelope: Bool,
        didRequireNoPresentBranchWhenCommitMissing: Bool,
        didKeepFirstFrameObservationBlocked: Bool,
        didKeepProductionTruthPromotionBlocked: Bool,
        didKeepRendererStateWriteAdmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool
    ) {
        this.didConsumeCommandBufferCommitNoPresentAfterDrawCallContract =
            didConsumeCommandBufferCommitNoPresentAfterDrawCallContract
        this.didRequireStage140CommitNoPresentPacket =
            didRequireStage140CommitNoPresentPacket
        this.didRequirePositiveCommitBeforePresentScheduling =
            didRequirePositiveCommitBeforePresentScheduling
        this.didRequireBoundedPresentSchedulingProbe =
            didRequireBoundedPresentSchedulingProbe
        this.didRequireProbeLocalDrawablePresentScheduling =
            didRequireProbeLocalDrawablePresentScheduling
        this.didRequirePresentAfterEncodingBeforeCommit =
            didRequirePresentAfterEncodingBeforeCommit
        this.didRequireProbeLocalCommitAfterPresentScheduling =
            didRequireProbeLocalCommitAfterPresentScheduling
        this.didRequireBoundedCompletionWait = didRequireBoundedCompletionWait
        this.didRequireDrawablePresentScheduledEnvelope =
            didRequireDrawablePresentScheduledEnvelope
        this.didRequireNoPresentBranchWhenCommitMissing =
            didRequireNoPresentBranchWhenCommitMissing
        this.didKeepFirstFrameObservationBlocked =
            didKeepFirstFrameObservationBlocked
        this.didKeepProductionTruthPromotionBlocked =
            didKeepProductionTruthPromotionBlocked
        this.didKeepRendererStateWriteAdmissionBlocked =
            didKeepRendererStateWriteAdmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didConfirmNoNativeBridgeExpansion = didConfirmNoNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi = didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentSchedulingAfterCommitNoPresentContractFirstSliceReadiness {
    let commitNoPresent:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceReadiness
    let presentSchedulingFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentSchedulingAfterCommitNoPresentContractFirstSliceFacts
    let didPreparePresentSchedulingAfterCommitNoPresentContractFirstSliceReadiness:
        Bool
    let shouldConsumeCommandBufferCommitNoPresentAfterDrawCallContract: Bool
    let shouldRequireStage140CommitNoPresentPacket: Bool
    let shouldRequirePositiveCommitBeforePresentScheduling: Bool
    let shouldRequireBoundedPresentSchedulingProbe: Bool
    let shouldRequireProbeLocalDrawablePresentScheduling: Bool
    let shouldRequirePresentAfterEncodingBeforeCommit: Bool
    let shouldRequireProbeLocalCommitAfterPresentScheduling: Bool
    let shouldRequireBoundedCompletionWait: Bool
    let shouldRequireDrawablePresentScheduledEnvelope: Bool
    let shouldRequireNoPresentBranchWhenCommitMissing: Bool
    let didConfirmStage140CommitNoPresentInput: Bool
    let didConfirmPresentSchedulingOrdering: Bool
    let didConfirmPresentSchedulingStopLine: Bool
    let didConfirmFirstFrameObservationBlocked: Bool
    let didConfirmProductionTruthPromotionBlocked: Bool
    let didConfirmRendererStateWriteAdmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool

    init(
        commitNoPresent:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceReadiness,
        presentSchedulingFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentSchedulingAfterCommitNoPresentContractFirstSliceFacts,
        didPreparePresentSchedulingAfterCommitNoPresentContractFirstSliceReadiness:
            Bool,
        shouldConsumeCommandBufferCommitNoPresentAfterDrawCallContract: Bool,
        shouldRequireStage140CommitNoPresentPacket: Bool,
        shouldRequirePositiveCommitBeforePresentScheduling: Bool,
        shouldRequireBoundedPresentSchedulingProbe: Bool,
        shouldRequireProbeLocalDrawablePresentScheduling: Bool,
        shouldRequirePresentAfterEncodingBeforeCommit: Bool,
        shouldRequireProbeLocalCommitAfterPresentScheduling: Bool,
        shouldRequireBoundedCompletionWait: Bool,
        shouldRequireDrawablePresentScheduledEnvelope: Bool,
        shouldRequireNoPresentBranchWhenCommitMissing: Bool,
        didConfirmStage140CommitNoPresentInput: Bool,
        didConfirmPresentSchedulingOrdering: Bool,
        didConfirmPresentSchedulingStopLine: Bool,
        didConfirmFirstFrameObservationBlocked: Bool,
        didConfirmProductionTruthPromotionBlocked: Bool,
        didConfirmRendererStateWriteAdmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool
    ) {
        this.commitNoPresent = commitNoPresent
        this.presentSchedulingFacts = presentSchedulingFacts
        this.didPreparePresentSchedulingAfterCommitNoPresentContractFirstSliceReadiness =
            didPreparePresentSchedulingAfterCommitNoPresentContractFirstSliceReadiness
        this.shouldConsumeCommandBufferCommitNoPresentAfterDrawCallContract =
            shouldConsumeCommandBufferCommitNoPresentAfterDrawCallContract
        this.shouldRequireStage140CommitNoPresentPacket =
            shouldRequireStage140CommitNoPresentPacket
        this.shouldRequirePositiveCommitBeforePresentScheduling =
            shouldRequirePositiveCommitBeforePresentScheduling
        this.shouldRequireBoundedPresentSchedulingProbe =
            shouldRequireBoundedPresentSchedulingProbe
        this.shouldRequireProbeLocalDrawablePresentScheduling =
            shouldRequireProbeLocalDrawablePresentScheduling
        this.shouldRequirePresentAfterEncodingBeforeCommit =
            shouldRequirePresentAfterEncodingBeforeCommit
        this.shouldRequireProbeLocalCommitAfterPresentScheduling =
            shouldRequireProbeLocalCommitAfterPresentScheduling
        this.shouldRequireBoundedCompletionWait = shouldRequireBoundedCompletionWait
        this.shouldRequireDrawablePresentScheduledEnvelope =
            shouldRequireDrawablePresentScheduledEnvelope
        this.shouldRequireNoPresentBranchWhenCommitMissing =
            shouldRequireNoPresentBranchWhenCommitMissing
        this.didConfirmStage140CommitNoPresentInput =
            didConfirmStage140CommitNoPresentInput
        this.didConfirmPresentSchedulingOrdering =
            didConfirmPresentSchedulingOrdering
        this.didConfirmPresentSchedulingStopLine = didConfirmPresentSchedulingStopLine
        this.didConfirmFirstFrameObservationBlocked =
            didConfirmFirstFrameObservationBlocked
        this.didConfirmProductionTruthPromotionBlocked =
            didConfirmProductionTruthPromotionBlocked
        this.didConfirmRendererStateWriteAdmissionBlocked =
            didConfirmRendererStateWriteAdmissionBlocked
        this.didConfirmRendererStateWriteBlocked = didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked = didConfirmRuntimeStateWriteBlocked
        this.didConfirmNoNativeBridgeExpansion = didConfirmNoNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi = didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentSchedulingAfterCommitNoPresentContractFirstSliceFacts(
    commitNoPresent:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentSchedulingAfterCommitNoPresentContractFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentSchedulingAfterCommitNoPresentContractFirstSliceFacts(
        commitNoPresent.didPrepareCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceReadiness,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        commitNoPresent.didConfirmFirstFrameObservationBlocked,
        commitNoPresent.didConfirmProductionTruthPromotionBlocked,
        commitNoPresent.didConfirmRendererStateWriteAdmissionBlocked,
        commitNoPresent.didConfirmRendererStateWriteBlocked,
        commitNoPresent.didConfirmRuntimeStateWriteBlocked,
        commitNoPresent.didConfirmNoNativeBridgeExpansion,
        commitNoPresent.didConfirmNoPublicApi,
        commitNoPresent.didConfirmNoProductionPublicCAbi,
        commitNoPresent.didConfirmNoRuntimeStateWrite,
        commitNoPresent.didConfirmNoCjpmTomlChange,
        commitNoPresent.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentSchedulingAfterCommitNoPresentContractFirstSliceReadiness(
    commitNoPresent:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceReadiness,
    presentSchedulingFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentSchedulingAfterCommitNoPresentContractFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentSchedulingAfterCommitNoPresentContractFirstSliceReadiness {
    let inputReady =
        presentSchedulingFacts
            .didConsumeCommandBufferCommitNoPresentAfterDrawCallContract &&
        commitNoPresent.didConfirmCommandBufferCommitOrdering &&
        commitNoPresent.didConfirmCommandBufferCommitStopLine
    let orderingReady =
        presentSchedulingFacts.didRequireStage140CommitNoPresentPacket &&
        presentSchedulingFacts.didRequirePositiveCommitBeforePresentScheduling &&
        presentSchedulingFacts.didRequireBoundedPresentSchedulingProbe &&
        presentSchedulingFacts.didRequireProbeLocalDrawablePresentScheduling &&
        presentSchedulingFacts.didRequirePresentAfterEncodingBeforeCommit &&
        presentSchedulingFacts.didRequireProbeLocalCommitAfterPresentScheduling &&
        presentSchedulingFacts.didRequireBoundedCompletionWait &&
        presentSchedulingFacts.didRequireDrawablePresentScheduledEnvelope &&
        presentSchedulingFacts.didRequireNoPresentBranchWhenCommitMissing
    let stopLineReady =
        presentSchedulingFacts.didKeepFirstFrameObservationBlocked &&
        presentSchedulingFacts.didKeepProductionTruthPromotionBlocked &&
        presentSchedulingFacts.didKeepRendererStateWriteAdmissionBlocked &&
        presentSchedulingFacts.didKeepRendererStateWriteBlocked &&
        presentSchedulingFacts.didKeepRuntimeStateWriteBlocked &&
        presentSchedulingFacts.didConfirmNoNativeBridgeExpansion &&
        presentSchedulingFacts.didConfirmNoPublicApi &&
        presentSchedulingFacts.didConfirmNoProductionPublicCAbi &&
        presentSchedulingFacts.didConfirmNoRuntimeStateWrite &&
        presentSchedulingFacts.didConfirmNoCjpmTomlChange &&
        presentSchedulingFacts.didConfirmNoRendererStateWrite

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentSchedulingAfterCommitNoPresentContractFirstSliceReadiness(
        commitNoPresent,
        presentSchedulingFacts,
        inputReady && orderingReady && stopLineReady,
        presentSchedulingFacts
            .didConsumeCommandBufferCommitNoPresentAfterDrawCallContract,
        presentSchedulingFacts.didRequireStage140CommitNoPresentPacket,
        presentSchedulingFacts.didRequirePositiveCommitBeforePresentScheduling,
        presentSchedulingFacts.didRequireBoundedPresentSchedulingProbe,
        presentSchedulingFacts.didRequireProbeLocalDrawablePresentScheduling,
        presentSchedulingFacts.didRequirePresentAfterEncodingBeforeCommit,
        presentSchedulingFacts.didRequireProbeLocalCommitAfterPresentScheduling,
        presentSchedulingFacts.didRequireBoundedCompletionWait,
        presentSchedulingFacts.didRequireDrawablePresentScheduledEnvelope,
        presentSchedulingFacts.didRequireNoPresentBranchWhenCommitMissing,
        inputReady,
        orderingReady,
        stopLineReady,
        presentSchedulingFacts.didKeepFirstFrameObservationBlocked,
        presentSchedulingFacts.didKeepProductionTruthPromotionBlocked,
        presentSchedulingFacts.didKeepRendererStateWriteAdmissionBlocked,
        presentSchedulingFacts.didKeepRendererStateWriteBlocked,
        presentSchedulingFacts.didKeepRuntimeStateWriteBlocked,
        presentSchedulingFacts.didConfirmNoNativeBridgeExpansion,
        presentSchedulingFacts.didConfirmNoPublicApi,
        presentSchedulingFacts.didConfirmNoProductionPublicCAbi,
        presentSchedulingFacts.didConfirmNoRuntimeStateWrite,
        presentSchedulingFacts.didConfirmNoCjpmTomlChange,
        presentSchedulingFacts.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentSchedulingAfterCommitNoPresentContractFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentSchedulingAfterCommitNoPresentContractFirstSliceReadiness {
    let commitNoPresent =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceDraft()
    let presentSchedulingFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentSchedulingAfterCommitNoPresentContractFirstSliceFacts(
            commitNoPresent
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentSchedulingAfterCommitNoPresentContractFirstSliceReadiness(
        commitNoPresent,
        presentSchedulingFacts
    )
}
