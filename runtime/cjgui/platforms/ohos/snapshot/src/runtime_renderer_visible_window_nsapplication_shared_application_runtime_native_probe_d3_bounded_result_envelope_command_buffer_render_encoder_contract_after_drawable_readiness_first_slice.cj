// 中文维护注释：本文件是 stage136 command buffer / render encoder contract
// after drawable readiness first-slice runtime owner。
// Owner: runtime renderer internal command buffer and render encoder contract
// after stage135 drawable / command pipeline gate。
// Truth: 只消费 stage135 command pipeline readiness，允许 isolated probe
// packet 证明 command buffer create/destroy、probe-local color attachment、
// render encoder creation 与 endEncoding；不把该 probe 解释为 production
// render truth。
// Stop-line: 不调用 native AppKit/Metal，不绑定 pipeline / vertex buffer，
// 不 draw / commit / present，不写 renderer state / runtime_state.cj，
// 不扩 public API / public C ABI / native bridge。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceFacts {
    let didConsumeCommandPipelineContractAfterDrawableReadiness: Bool
    let didRequireStage135CommandPipelinePacket: Bool
    let didRequireCommandBufferCreateDestroyContract: Bool
    let didRequirePositiveCommandBufferBeforeRenderEncoder: Bool
    let didRequireProbeLocalDrawableTextureBeforeColorAttachment: Bool
    let didRequireProbeLocalRenderPassColorAttachment: Bool
    let didRequireProbeLocalRenderCommandEncoder: Bool
    let didRequireEndEncodingBeforeCleanup: Bool
    let didKeepPipelineStateBindingBlocked: Bool
    let didKeepVertexBufferBindingBlocked: Bool
    let didKeepDrawCommitPresentGpuWorkBlocked: Bool
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
        didConsumeCommandPipelineContractAfterDrawableReadiness: Bool,
        didRequireStage135CommandPipelinePacket: Bool,
        didRequireCommandBufferCreateDestroyContract: Bool,
        didRequirePositiveCommandBufferBeforeRenderEncoder: Bool,
        didRequireProbeLocalDrawableTextureBeforeColorAttachment: Bool,
        didRequireProbeLocalRenderPassColorAttachment: Bool,
        didRequireProbeLocalRenderCommandEncoder: Bool,
        didRequireEndEncodingBeforeCleanup: Bool,
        didKeepPipelineStateBindingBlocked: Bool,
        didKeepVertexBufferBindingBlocked: Bool,
        didKeepDrawCommitPresentGpuWorkBlocked: Bool,
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
        this.didConsumeCommandPipelineContractAfterDrawableReadiness =
            didConsumeCommandPipelineContractAfterDrawableReadiness
        this.didRequireStage135CommandPipelinePacket =
            didRequireStage135CommandPipelinePacket
        this.didRequireCommandBufferCreateDestroyContract =
            didRequireCommandBufferCreateDestroyContract
        this.didRequirePositiveCommandBufferBeforeRenderEncoder =
            didRequirePositiveCommandBufferBeforeRenderEncoder
        this.didRequireProbeLocalDrawableTextureBeforeColorAttachment =
            didRequireProbeLocalDrawableTextureBeforeColorAttachment
        this.didRequireProbeLocalRenderPassColorAttachment =
            didRequireProbeLocalRenderPassColorAttachment
        this.didRequireProbeLocalRenderCommandEncoder =
            didRequireProbeLocalRenderCommandEncoder
        this.didRequireEndEncodingBeforeCleanup =
            didRequireEndEncodingBeforeCleanup
        this.didKeepPipelineStateBindingBlocked =
            didKeepPipelineStateBindingBlocked
        this.didKeepVertexBufferBindingBlocked =
            didKeepVertexBufferBindingBlocked
        this.didKeepDrawCommitPresentGpuWorkBlocked =
            didKeepDrawCommitPresentGpuWorkBlocked
        this.didKeepFirstFrameObservationBlocked =
            didKeepFirstFrameObservationBlocked
        this.didKeepProductionTruthPromotionBlocked =
            didKeepProductionTruthPromotionBlocked
        this.didKeepRendererStateWriteAdmissionBlocked =
            didKeepRendererStateWriteAdmissionBlocked
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked =
            didKeepRuntimeStateWriteBlocked
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceReadiness {
    let commandPipelineContract:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceReadiness
    let commandBufferRenderEncoderContractFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceFacts
    let didPrepareCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceReadiness:
        Bool
    let shouldConsumeCommandPipelineContractAfterDrawableReadiness: Bool
    let shouldRequireStage135CommandPipelinePacket: Bool
    let shouldRequireCommandBufferCreateDestroyContract: Bool
    let shouldRequirePositiveCommandBufferBeforeRenderEncoder: Bool
    let shouldRequireProbeLocalDrawableTextureBeforeColorAttachment: Bool
    let shouldRequireProbeLocalRenderPassColorAttachment: Bool
    let shouldRequireProbeLocalRenderCommandEncoder: Bool
    let shouldRequireEndEncodingBeforeCleanup: Bool
    let shouldKeepPipelineStateBindingBlocked: Bool
    let shouldKeepVertexBufferBindingBlocked: Bool
    let shouldKeepDrawCommitPresentGpuWorkBlocked: Bool
    let didConfirmCommandBufferRenderEncoderContractGate: Bool
    let didConfirmRenderEncoderStopLine: Bool
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
        commandPipelineContract:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceReadiness,
        commandBufferRenderEncoderContractFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceFacts,
        didPrepareCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceReadiness:
            Bool,
        shouldConsumeCommandPipelineContractAfterDrawableReadiness: Bool,
        shouldRequireStage135CommandPipelinePacket: Bool,
        shouldRequireCommandBufferCreateDestroyContract: Bool,
        shouldRequirePositiveCommandBufferBeforeRenderEncoder: Bool,
        shouldRequireProbeLocalDrawableTextureBeforeColorAttachment: Bool,
        shouldRequireProbeLocalRenderPassColorAttachment: Bool,
        shouldRequireProbeLocalRenderCommandEncoder: Bool,
        shouldRequireEndEncodingBeforeCleanup: Bool,
        shouldKeepPipelineStateBindingBlocked: Bool,
        shouldKeepVertexBufferBindingBlocked: Bool,
        shouldKeepDrawCommitPresentGpuWorkBlocked: Bool,
        didConfirmCommandBufferRenderEncoderContractGate: Bool,
        didConfirmRenderEncoderStopLine: Bool,
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
        this.commandPipelineContract = commandPipelineContract
        this.commandBufferRenderEncoderContractFacts =
            commandBufferRenderEncoderContractFacts
        this.didPrepareCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceReadiness =
            didPrepareCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceReadiness
        this.shouldConsumeCommandPipelineContractAfterDrawableReadiness =
            shouldConsumeCommandPipelineContractAfterDrawableReadiness
        this.shouldRequireStage135CommandPipelinePacket =
            shouldRequireStage135CommandPipelinePacket
        this.shouldRequireCommandBufferCreateDestroyContract =
            shouldRequireCommandBufferCreateDestroyContract
        this.shouldRequirePositiveCommandBufferBeforeRenderEncoder =
            shouldRequirePositiveCommandBufferBeforeRenderEncoder
        this.shouldRequireProbeLocalDrawableTextureBeforeColorAttachment =
            shouldRequireProbeLocalDrawableTextureBeforeColorAttachment
        this.shouldRequireProbeLocalRenderPassColorAttachment =
            shouldRequireProbeLocalRenderPassColorAttachment
        this.shouldRequireProbeLocalRenderCommandEncoder =
            shouldRequireProbeLocalRenderCommandEncoder
        this.shouldRequireEndEncodingBeforeCleanup =
            shouldRequireEndEncodingBeforeCleanup
        this.shouldKeepPipelineStateBindingBlocked =
            shouldKeepPipelineStateBindingBlocked
        this.shouldKeepVertexBufferBindingBlocked =
            shouldKeepVertexBufferBindingBlocked
        this.shouldKeepDrawCommitPresentGpuWorkBlocked =
            shouldKeepDrawCommitPresentGpuWorkBlocked
        this.didConfirmCommandBufferRenderEncoderContractGate =
            didConfirmCommandBufferRenderEncoderContractGate
        this.didConfirmRenderEncoderStopLine = didConfirmRenderEncoderStopLine
        this.didConfirmFirstFrameObservationBlocked =
            didConfirmFirstFrameObservationBlocked
        this.didConfirmProductionTruthPromotionBlocked =
            didConfirmProductionTruthPromotionBlocked
        this.didConfirmRendererStateWriteAdmissionBlocked =
            didConfirmRendererStateWriteAdmissionBlocked
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked =
            didConfirmRuntimeStateWriteBlocked
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

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceFacts(
    commandPipelineContract:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceFacts(
        commandPipelineContract
            .didPrepareCommandPipelineContractAfterDrawableReadinessFirstSliceReadiness,
        true,
        commandPipelineContract.didConfirmCommandPipelineContractGate,
        true,
        true,
        true,
        true,
        true,
        commandPipelineContract.shouldKeepPipelineVertexBindingBlocked,
        commandPipelineContract.shouldKeepPipelineVertexBindingBlocked,
        commandPipelineContract.shouldKeepDrawCommitPresentGpuWorkBlocked,
        commandPipelineContract.didConfirmFirstFrameObservationBlocked,
        commandPipelineContract.didConfirmProductionTruthPromotionBlocked,
        commandPipelineContract.didConfirmRendererStateWriteAdmissionBlocked,
        commandPipelineContract.didConfirmRendererStateWriteBlocked,
        commandPipelineContract.didConfirmRuntimeStateWriteBlocked,
        commandPipelineContract.didConfirmNoNativeBridgeExpansion,
        commandPipelineContract.didConfirmNoPublicApi,
        commandPipelineContract.didConfirmNoProductionPublicCAbi,
        commandPipelineContract.didConfirmNoRuntimeStateWrite,
        commandPipelineContract.didConfirmNoCjpmTomlChange,
        commandPipelineContract.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceReadiness(
    commandPipelineContract:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceReadiness,
    commandBufferRenderEncoderContractFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceReadiness {
    let contractGateReady =
        commandBufferRenderEncoderContractFacts
            .didConsumeCommandPipelineContractAfterDrawableReadiness &&
        commandBufferRenderEncoderContractFacts
            .didRequireStage135CommandPipelinePacket &&
        commandBufferRenderEncoderContractFacts
            .didRequireCommandBufferCreateDestroyContract &&
        commandBufferRenderEncoderContractFacts
            .didRequirePositiveCommandBufferBeforeRenderEncoder &&
        commandBufferRenderEncoderContractFacts
            .didRequireProbeLocalDrawableTextureBeforeColorAttachment &&
        commandBufferRenderEncoderContractFacts
            .didRequireProbeLocalRenderPassColorAttachment &&
        commandBufferRenderEncoderContractFacts
            .didRequireProbeLocalRenderCommandEncoder &&
        commandBufferRenderEncoderContractFacts
            .didRequireEndEncodingBeforeCleanup
    let stopLineReady =
        commandBufferRenderEncoderContractFacts
            .didKeepPipelineStateBindingBlocked &&
        commandBufferRenderEncoderContractFacts
            .didKeepVertexBufferBindingBlocked &&
        commandBufferRenderEncoderContractFacts
            .didKeepDrawCommitPresentGpuWorkBlocked &&
        commandBufferRenderEncoderContractFacts
            .didKeepFirstFrameObservationBlocked &&
        commandBufferRenderEncoderContractFacts
            .didKeepProductionTruthPromotionBlocked &&
        commandBufferRenderEncoderContractFacts
            .didKeepRendererStateWriteAdmissionBlocked &&
        commandBufferRenderEncoderContractFacts
            .didKeepRendererStateWriteBlocked &&
        commandBufferRenderEncoderContractFacts
            .didKeepRuntimeStateWriteBlocked &&
        commandBufferRenderEncoderContractFacts
            .didConfirmNoNativeBridgeExpansion &&
        commandBufferRenderEncoderContractFacts.didConfirmNoPublicApi &&
        commandBufferRenderEncoderContractFacts
            .didConfirmNoProductionPublicCAbi &&
        commandBufferRenderEncoderContractFacts.didConfirmNoRuntimeStateWrite &&
        commandBufferRenderEncoderContractFacts.didConfirmNoCjpmTomlChange &&
        commandBufferRenderEncoderContractFacts.didConfirmNoRendererStateWrite

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceReadiness(
        commandPipelineContract,
        commandBufferRenderEncoderContractFacts,
        contractGateReady && stopLineReady,
        commandBufferRenderEncoderContractFacts
            .didConsumeCommandPipelineContractAfterDrawableReadiness,
        commandBufferRenderEncoderContractFacts
            .didRequireStage135CommandPipelinePacket,
        commandBufferRenderEncoderContractFacts
            .didRequireCommandBufferCreateDestroyContract,
        commandBufferRenderEncoderContractFacts
            .didRequirePositiveCommandBufferBeforeRenderEncoder,
        commandBufferRenderEncoderContractFacts
            .didRequireProbeLocalDrawableTextureBeforeColorAttachment,
        commandBufferRenderEncoderContractFacts
            .didRequireProbeLocalRenderPassColorAttachment,
        commandBufferRenderEncoderContractFacts
            .didRequireProbeLocalRenderCommandEncoder,
        commandBufferRenderEncoderContractFacts.didRequireEndEncodingBeforeCleanup,
        commandBufferRenderEncoderContractFacts.didKeepPipelineStateBindingBlocked,
        commandBufferRenderEncoderContractFacts.didKeepVertexBufferBindingBlocked,
        commandBufferRenderEncoderContractFacts
            .didKeepDrawCommitPresentGpuWorkBlocked,
        contractGateReady,
        stopLineReady,
        commandBufferRenderEncoderContractFacts
            .didKeepFirstFrameObservationBlocked,
        commandBufferRenderEncoderContractFacts
            .didKeepProductionTruthPromotionBlocked,
        commandBufferRenderEncoderContractFacts
            .didKeepRendererStateWriteAdmissionBlocked,
        commandBufferRenderEncoderContractFacts.didKeepRendererStateWriteBlocked,
        commandBufferRenderEncoderContractFacts.didKeepRuntimeStateWriteBlocked,
        commandBufferRenderEncoderContractFacts.didConfirmNoNativeBridgeExpansion,
        commandBufferRenderEncoderContractFacts.didConfirmNoPublicApi,
        commandBufferRenderEncoderContractFacts.didConfirmNoProductionPublicCAbi,
        commandBufferRenderEncoderContractFacts.didConfirmNoRuntimeStateWrite,
        commandBufferRenderEncoderContractFacts.didConfirmNoCjpmTomlChange,
        commandBufferRenderEncoderContractFacts.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceReadiness {
    let commandPipelineContract =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceDraft()
    let commandBufferRenderEncoderContractFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceFacts(
            commandPipelineContract
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceReadiness(
        commandPipelineContract,
        commandBufferRenderEncoderContractFacts
    )
}
