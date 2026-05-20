// 中文维护注释：本文件是 stage140 command-buffer commit no-present after
// stage139 draw-call contract first-slice runtime owner。
// Owner: runtime renderer internal command-buffer commit no-present contract after
// probe-local draw 已经在 stage139 envelope 中正向成立。
// Truth: 只消费 stage139 draw-call envelope；只有 packet 证明 draw 已经调用后，
// 才允许 isolated probe-local command buffer commit 与 bounded completion 分类。
// Stop-line: 本 owner 不执行 native AppKit/Metal，不 present，不观测 first frame，
// 不写 renderer state / runtime_state.cj，不扩 public API / public C ABI / native bridge。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceFacts {
    let didConsumeDrawCallAfterPipelineVertexBindingContract: Bool
    let didRequireStage139DrawCallPacket: Bool
    let didRequirePositiveDrawCallBeforeCommit: Bool
    let didRequireBoundedCommandBufferCommitNoPresentProbe: Bool
    let didRequireProbeLocalDrawBeforeCommit: Bool
    let didRequireEndEncodingBeforeCommit: Bool
    let didRequireProbeLocalCommandBufferCommit: Bool
    let didRequireBoundedCompletionWait: Bool
    let didRequireGpuSubmissionCompletionEnvelope: Bool
    let didKeepPresentBlocked: Bool
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
        didConsumeDrawCallAfterPipelineVertexBindingContract: Bool,
        didRequireStage139DrawCallPacket: Bool,
        didRequirePositiveDrawCallBeforeCommit: Bool,
        didRequireBoundedCommandBufferCommitNoPresentProbe: Bool,
        didRequireProbeLocalDrawBeforeCommit: Bool,
        didRequireEndEncodingBeforeCommit: Bool,
        didRequireProbeLocalCommandBufferCommit: Bool,
        didRequireBoundedCompletionWait: Bool,
        didRequireGpuSubmissionCompletionEnvelope: Bool,
        didKeepPresentBlocked: Bool,
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
        this.didConsumeDrawCallAfterPipelineVertexBindingContract =
            didConsumeDrawCallAfterPipelineVertexBindingContract
        this.didRequireStage139DrawCallPacket = didRequireStage139DrawCallPacket
        this.didRequirePositiveDrawCallBeforeCommit =
            didRequirePositiveDrawCallBeforeCommit
        this.didRequireBoundedCommandBufferCommitNoPresentProbe =
            didRequireBoundedCommandBufferCommitNoPresentProbe
        this.didRequireProbeLocalDrawBeforeCommit =
            didRequireProbeLocalDrawBeforeCommit
        this.didRequireEndEncodingBeforeCommit = didRequireEndEncodingBeforeCommit
        this.didRequireProbeLocalCommandBufferCommit =
            didRequireProbeLocalCommandBufferCommit
        this.didRequireBoundedCompletionWait = didRequireBoundedCompletionWait
        this.didRequireGpuSubmissionCompletionEnvelope =
            didRequireGpuSubmissionCompletionEnvelope
        this.didKeepPresentBlocked = didKeepPresentBlocked
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceReadiness {
    let drawCall:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceReadiness
    let commitFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceFacts
    let didPrepareCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceReadiness:
        Bool
    let shouldConsumeDrawCallAfterPipelineVertexBindingContract: Bool
    let shouldRequireStage139DrawCallPacket: Bool
    let shouldRequirePositiveDrawCallBeforeCommit: Bool
    let shouldRequireBoundedCommandBufferCommitNoPresentProbe: Bool
    let shouldRequireProbeLocalDrawBeforeCommit: Bool
    let shouldRequireEndEncodingBeforeCommit: Bool
    let shouldRequireProbeLocalCommandBufferCommit: Bool
    let shouldRequireBoundedCompletionWait: Bool
    let shouldRequireGpuSubmissionCompletionEnvelope: Bool
    let shouldKeepPresentBlocked: Bool
    let didConfirmStage139DrawCallInput: Bool
    let didConfirmCommandBufferCommitOrdering: Bool
    let didConfirmCommandBufferCommitStopLine: Bool
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
        drawCall:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceReadiness,
        commitFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceFacts,
        didPrepareCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceReadiness:
            Bool,
        shouldConsumeDrawCallAfterPipelineVertexBindingContract: Bool,
        shouldRequireStage139DrawCallPacket: Bool,
        shouldRequirePositiveDrawCallBeforeCommit: Bool,
        shouldRequireBoundedCommandBufferCommitNoPresentProbe: Bool,
        shouldRequireProbeLocalDrawBeforeCommit: Bool,
        shouldRequireEndEncodingBeforeCommit: Bool,
        shouldRequireProbeLocalCommandBufferCommit: Bool,
        shouldRequireBoundedCompletionWait: Bool,
        shouldRequireGpuSubmissionCompletionEnvelope: Bool,
        shouldKeepPresentBlocked: Bool,
        didConfirmStage139DrawCallInput: Bool,
        didConfirmCommandBufferCommitOrdering: Bool,
        didConfirmCommandBufferCommitStopLine: Bool,
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
        this.drawCall = drawCall
        this.commitFacts = commitFacts
        this.didPrepareCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceReadiness =
            didPrepareCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceReadiness
        this.shouldConsumeDrawCallAfterPipelineVertexBindingContract =
            shouldConsumeDrawCallAfterPipelineVertexBindingContract
        this.shouldRequireStage139DrawCallPacket = shouldRequireStage139DrawCallPacket
        this.shouldRequirePositiveDrawCallBeforeCommit =
            shouldRequirePositiveDrawCallBeforeCommit
        this.shouldRequireBoundedCommandBufferCommitNoPresentProbe =
            shouldRequireBoundedCommandBufferCommitNoPresentProbe
        this.shouldRequireProbeLocalDrawBeforeCommit =
            shouldRequireProbeLocalDrawBeforeCommit
        this.shouldRequireEndEncodingBeforeCommit = shouldRequireEndEncodingBeforeCommit
        this.shouldRequireProbeLocalCommandBufferCommit =
            shouldRequireProbeLocalCommandBufferCommit
        this.shouldRequireBoundedCompletionWait = shouldRequireBoundedCompletionWait
        this.shouldRequireGpuSubmissionCompletionEnvelope =
            shouldRequireGpuSubmissionCompletionEnvelope
        this.shouldKeepPresentBlocked = shouldKeepPresentBlocked
        this.didConfirmStage139DrawCallInput = didConfirmStage139DrawCallInput
        this.didConfirmCommandBufferCommitOrdering =
            didConfirmCommandBufferCommitOrdering
        this.didConfirmCommandBufferCommitStopLine =
            didConfirmCommandBufferCommitStopLine
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

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceFacts(
    drawCall:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceFacts(
        drawCall.didPrepareDrawCallAfterPipelineVertexBindingContractFirstSliceReadiness,
        true,
        true,
        true,
        drawCall.shouldRequireProbeLocalDrawPrimitivesCall,
        drawCall.shouldRequireEndEncodingAfterDrawBeforeCleanup,
        true,
        true,
        true,
        true,
        drawCall.didConfirmFirstFrameObservationBlocked,
        drawCall.didConfirmProductionTruthPromotionBlocked,
        drawCall.didConfirmRendererStateWriteAdmissionBlocked,
        drawCall.didConfirmRendererStateWriteBlocked,
        drawCall.didConfirmRuntimeStateWriteBlocked,
        drawCall.didConfirmNoNativeBridgeExpansion,
        drawCall.didConfirmNoPublicApi,
        drawCall.didConfirmNoProductionPublicCAbi,
        drawCall.didConfirmNoRuntimeStateWrite,
        drawCall.didConfirmNoCjpmTomlChange,
        drawCall.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceReadiness(
    drawCall:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceReadiness,
    commitFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceReadiness {
    let inputReady =
        commitFacts.didConsumeDrawCallAfterPipelineVertexBindingContract &&
        drawCall.didConfirmDrawCallOrdering &&
        drawCall.didConfirmDrawCallStopLine
    let orderingReady =
        commitFacts.didRequireStage139DrawCallPacket &&
        commitFacts.didRequirePositiveDrawCallBeforeCommit &&
        commitFacts.didRequireBoundedCommandBufferCommitNoPresentProbe &&
        commitFacts.didRequireProbeLocalDrawBeforeCommit &&
        commitFacts.didRequireEndEncodingBeforeCommit &&
        commitFacts.didRequireProbeLocalCommandBufferCommit &&
        commitFacts.didRequireBoundedCompletionWait &&
        commitFacts.didRequireGpuSubmissionCompletionEnvelope
    let stopLineReady =
        commitFacts.didKeepPresentBlocked &&
        commitFacts.didKeepFirstFrameObservationBlocked &&
        commitFacts.didKeepProductionTruthPromotionBlocked &&
        commitFacts.didKeepRendererStateWriteAdmissionBlocked &&
        commitFacts.didKeepRendererStateWriteBlocked &&
        commitFacts.didKeepRuntimeStateWriteBlocked &&
        commitFacts.didConfirmNoNativeBridgeExpansion &&
        commitFacts.didConfirmNoPublicApi &&
        commitFacts.didConfirmNoProductionPublicCAbi &&
        commitFacts.didConfirmNoRuntimeStateWrite &&
        commitFacts.didConfirmNoCjpmTomlChange &&
        commitFacts.didConfirmNoRendererStateWrite

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceReadiness(
        drawCall,
        commitFacts,
        inputReady && orderingReady && stopLineReady,
        commitFacts.didConsumeDrawCallAfterPipelineVertexBindingContract,
        commitFacts.didRequireStage139DrawCallPacket,
        commitFacts.didRequirePositiveDrawCallBeforeCommit,
        commitFacts.didRequireBoundedCommandBufferCommitNoPresentProbe,
        commitFacts.didRequireProbeLocalDrawBeforeCommit,
        commitFacts.didRequireEndEncodingBeforeCommit,
        commitFacts.didRequireProbeLocalCommandBufferCommit,
        commitFacts.didRequireBoundedCompletionWait,
        commitFacts.didRequireGpuSubmissionCompletionEnvelope,
        commitFacts.didKeepPresentBlocked,
        inputReady,
        orderingReady,
        stopLineReady,
        commitFacts.didKeepFirstFrameObservationBlocked,
        commitFacts.didKeepProductionTruthPromotionBlocked,
        commitFacts.didKeepRendererStateWriteAdmissionBlocked,
        commitFacts.didKeepRendererStateWriteBlocked,
        commitFacts.didKeepRuntimeStateWriteBlocked,
        commitFacts.didConfirmNoNativeBridgeExpansion,
        commitFacts.didConfirmNoPublicApi,
        commitFacts.didConfirmNoProductionPublicCAbi,
        commitFacts.didConfirmNoRuntimeStateWrite,
        commitFacts.didConfirmNoCjpmTomlChange,
        commitFacts.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceReadiness {
    let drawCall =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceDraft()
    let commitFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceFacts(
            drawCall
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceReadiness(
        drawCall,
        commitFacts
    )
}
