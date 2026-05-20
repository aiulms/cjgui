// 中文维护注释：本文件是 stage135 command pipeline contract after drawable
// readiness first-slice runtime owner。
// Owner: runtime renderer internal command pipeline contract after drawable gate。
// Truth: 消费 stage135 drawable readiness gate，只允许把 command queue
// create-destroy 与 render-pass descriptor create-destroy 作为 isolated contract
// probe 输入；当前无 drawable 时不得创建 command buffer / encoder 或提交 GPU work。
// Stop-line: 不调用 native AppKit/Metal，不获取 drawable，不创建 command buffer /
// encoder，不 draw / commit / present，不写 renderer state / runtime_state.cj，
// 不扩 public API / public C ABI / native bridge。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceFacts {
    let didConsumeDrawableReadinessAfterVisibleOrder: Bool
    let didRequireDrawableGateBeforeCommandPipeline: Bool
    let didRequireCommandQueueCreateDestroyContract: Bool
    let didRequireRenderPassDescriptorCreateDestroyContract: Bool
    let didKeepCommandBufferCreationBlockedUntilDrawableReady: Bool
    let didKeepRenderEncoderCreationBlocked: Bool
    let didKeepPipelineVertexBindingBlocked: Bool
    let didKeepDrawCommitPresentGpuWorkBlocked: Bool
    let didKeepCommandPipelineFactsIsolated: Bool
    let didPrepareRenderEncoderContractRoute: Bool
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
        didConsumeDrawableReadinessAfterVisibleOrder: Bool,
        didRequireDrawableGateBeforeCommandPipeline: Bool,
        didRequireCommandQueueCreateDestroyContract: Bool,
        didRequireRenderPassDescriptorCreateDestroyContract: Bool,
        didKeepCommandBufferCreationBlockedUntilDrawableReady: Bool,
        didKeepRenderEncoderCreationBlocked: Bool,
        didKeepPipelineVertexBindingBlocked: Bool,
        didKeepDrawCommitPresentGpuWorkBlocked: Bool,
        didKeepCommandPipelineFactsIsolated: Bool,
        didPrepareRenderEncoderContractRoute: Bool,
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
        this.didConsumeDrawableReadinessAfterVisibleOrder =
            didConsumeDrawableReadinessAfterVisibleOrder
        this.didRequireDrawableGateBeforeCommandPipeline =
            didRequireDrawableGateBeforeCommandPipeline
        this.didRequireCommandQueueCreateDestroyContract =
            didRequireCommandQueueCreateDestroyContract
        this.didRequireRenderPassDescriptorCreateDestroyContract =
            didRequireRenderPassDescriptorCreateDestroyContract
        this.didKeepCommandBufferCreationBlockedUntilDrawableReady =
            didKeepCommandBufferCreationBlockedUntilDrawableReady
        this.didKeepRenderEncoderCreationBlocked =
            didKeepRenderEncoderCreationBlocked
        this.didKeepPipelineVertexBindingBlocked =
            didKeepPipelineVertexBindingBlocked
        this.didKeepDrawCommitPresentGpuWorkBlocked =
            didKeepDrawCommitPresentGpuWorkBlocked
        this.didKeepCommandPipelineFactsIsolated =
            didKeepCommandPipelineFactsIsolated
        this.didPrepareRenderEncoderContractRoute =
            didPrepareRenderEncoderContractRoute
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceReadiness {
    let drawableReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceReadiness
    let commandPipelineContractFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceFacts
    let didPrepareCommandPipelineContractAfterDrawableReadinessFirstSliceReadiness:
        Bool
    let shouldConsumeDrawableReadinessAfterVisibleOrder: Bool
    let shouldRequireDrawableGateBeforeCommandPipeline: Bool
    let shouldRequireCommandQueueCreateDestroyContract: Bool
    let shouldRequireRenderPassDescriptorCreateDestroyContract: Bool
    let shouldKeepCommandBufferCreationBlockedUntilDrawableReady: Bool
    let shouldKeepRenderEncoderCreationBlocked: Bool
    let shouldKeepPipelineVertexBindingBlocked: Bool
    let shouldKeepDrawCommitPresentGpuWorkBlocked: Bool
    let shouldKeepCommandPipelineFactsIsolated: Bool
    let shouldPrepareRenderEncoderContractRoute: Bool
    let didConfirmDrawableReadinessInput: Bool
    let didConfirmCommandPipelineContractGate: Bool
    let didConfirmCommandPipelineStopLine: Bool
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
        drawableReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceReadiness,
        commandPipelineContractFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceFacts,
        didPrepareCommandPipelineContractAfterDrawableReadinessFirstSliceReadiness:
            Bool,
        shouldConsumeDrawableReadinessAfterVisibleOrder: Bool,
        shouldRequireDrawableGateBeforeCommandPipeline: Bool,
        shouldRequireCommandQueueCreateDestroyContract: Bool,
        shouldRequireRenderPassDescriptorCreateDestroyContract: Bool,
        shouldKeepCommandBufferCreationBlockedUntilDrawableReady: Bool,
        shouldKeepRenderEncoderCreationBlocked: Bool,
        shouldKeepPipelineVertexBindingBlocked: Bool,
        shouldKeepDrawCommitPresentGpuWorkBlocked: Bool,
        shouldKeepCommandPipelineFactsIsolated: Bool,
        shouldPrepareRenderEncoderContractRoute: Bool,
        didConfirmDrawableReadinessInput: Bool,
        didConfirmCommandPipelineContractGate: Bool,
        didConfirmCommandPipelineStopLine: Bool,
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
        this.drawableReadiness = drawableReadiness
        this.commandPipelineContractFacts = commandPipelineContractFacts
        this.didPrepareCommandPipelineContractAfterDrawableReadinessFirstSliceReadiness =
            didPrepareCommandPipelineContractAfterDrawableReadinessFirstSliceReadiness
        this.shouldConsumeDrawableReadinessAfterVisibleOrder =
            shouldConsumeDrawableReadinessAfterVisibleOrder
        this.shouldRequireDrawableGateBeforeCommandPipeline =
            shouldRequireDrawableGateBeforeCommandPipeline
        this.shouldRequireCommandQueueCreateDestroyContract =
            shouldRequireCommandQueueCreateDestroyContract
        this.shouldRequireRenderPassDescriptorCreateDestroyContract =
            shouldRequireRenderPassDescriptorCreateDestroyContract
        this.shouldKeepCommandBufferCreationBlockedUntilDrawableReady =
            shouldKeepCommandBufferCreationBlockedUntilDrawableReady
        this.shouldKeepRenderEncoderCreationBlocked =
            shouldKeepRenderEncoderCreationBlocked
        this.shouldKeepPipelineVertexBindingBlocked =
            shouldKeepPipelineVertexBindingBlocked
        this.shouldKeepDrawCommitPresentGpuWorkBlocked =
            shouldKeepDrawCommitPresentGpuWorkBlocked
        this.shouldKeepCommandPipelineFactsIsolated =
            shouldKeepCommandPipelineFactsIsolated
        this.shouldPrepareRenderEncoderContractRoute =
            shouldPrepareRenderEncoderContractRoute
        this.didConfirmDrawableReadinessInput = didConfirmDrawableReadinessInput
        this.didConfirmCommandPipelineContractGate =
            didConfirmCommandPipelineContractGate
        this.didConfirmCommandPipelineStopLine =
            didConfirmCommandPipelineStopLine
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

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceFacts(
    drawableReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceFacts(
        drawableReadiness
            .didPrepareDrawableReadinessAfterVisibleOrderFirstSliceReadiness,
        drawableReadiness.shouldContinueCommandPipelineContractRoute,
        true,
        true,
        true,
        true,
        true,
        true,
        drawableReadiness.shouldKeepDrawableFactsIsolated,
        true,
        drawableReadiness.didConfirmFirstFrameObservationBlocked,
        drawableReadiness.didConfirmProductionTruthPromotionBlocked,
        drawableReadiness.didConfirmRendererStateWriteAdmissionBlocked,
        drawableReadiness.didConfirmRendererStateWriteBlocked,
        drawableReadiness.didConfirmRuntimeStateWriteBlocked,
        drawableReadiness.didConfirmNoNativeBridgeExpansion,
        drawableReadiness.didConfirmNoPublicApi,
        drawableReadiness.didConfirmNoProductionPublicCAbi,
        drawableReadiness.didConfirmNoRuntimeStateWrite,
        drawableReadiness.didConfirmNoCjpmTomlChange,
        drawableReadiness.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceReadiness(
    drawableReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceReadiness,
    commandPipelineContractFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceReadiness {
    let commandPipelineContractReady =
        commandPipelineContractFacts.didConsumeDrawableReadinessAfterVisibleOrder &&
        commandPipelineContractFacts.didRequireDrawableGateBeforeCommandPipeline &&
        commandPipelineContractFacts.didRequireCommandQueueCreateDestroyContract &&
        commandPipelineContractFacts
            .didRequireRenderPassDescriptorCreateDestroyContract &&
        commandPipelineContractFacts
            .didKeepCommandBufferCreationBlockedUntilDrawableReady &&
        commandPipelineContractFacts.didPrepareRenderEncoderContractRoute
    let commandPipelineStopLineReady =
        commandPipelineContractFacts.didKeepRenderEncoderCreationBlocked &&
        commandPipelineContractFacts.didKeepPipelineVertexBindingBlocked &&
        commandPipelineContractFacts.didKeepDrawCommitPresentGpuWorkBlocked &&
        commandPipelineContractFacts.didKeepCommandPipelineFactsIsolated &&
        commandPipelineContractFacts.didKeepFirstFrameObservationBlocked &&
        commandPipelineContractFacts.didKeepProductionTruthPromotionBlocked &&
        commandPipelineContractFacts.didKeepRendererStateWriteAdmissionBlocked &&
        commandPipelineContractFacts.didKeepRendererStateWriteBlocked &&
        commandPipelineContractFacts.didKeepRuntimeStateWriteBlocked &&
        commandPipelineContractFacts.didConfirmNoNativeBridgeExpansion &&
        commandPipelineContractFacts.didConfirmNoPublicApi &&
        commandPipelineContractFacts.didConfirmNoProductionPublicCAbi &&
        commandPipelineContractFacts.didConfirmNoRuntimeStateWrite &&
        commandPipelineContractFacts.didConfirmNoCjpmTomlChange &&
        commandPipelineContractFacts.didConfirmNoRendererStateWrite

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceReadiness(
        drawableReadiness,
        commandPipelineContractFacts,
        commandPipelineContractReady && commandPipelineStopLineReady,
        commandPipelineContractFacts
            .didConsumeDrawableReadinessAfterVisibleOrder,
        commandPipelineContractFacts.didRequireDrawableGateBeforeCommandPipeline,
        commandPipelineContractFacts.didRequireCommandQueueCreateDestroyContract,
        commandPipelineContractFacts
            .didRequireRenderPassDescriptorCreateDestroyContract,
        commandPipelineContractFacts
            .didKeepCommandBufferCreationBlockedUntilDrawableReady,
        commandPipelineContractFacts.didKeepRenderEncoderCreationBlocked,
        commandPipelineContractFacts.didKeepPipelineVertexBindingBlocked,
        commandPipelineContractFacts.didKeepDrawCommitPresentGpuWorkBlocked,
        commandPipelineContractFacts.didKeepCommandPipelineFactsIsolated,
        commandPipelineContractFacts.didPrepareRenderEncoderContractRoute,
        commandPipelineContractFacts
            .didConsumeDrawableReadinessAfterVisibleOrder,
        commandPipelineContractReady,
        commandPipelineStopLineReady,
        commandPipelineContractFacts.didKeepFirstFrameObservationBlocked,
        commandPipelineContractFacts.didKeepProductionTruthPromotionBlocked,
        commandPipelineContractFacts.didKeepRendererStateWriteAdmissionBlocked,
        commandPipelineContractFacts.didKeepRendererStateWriteBlocked,
        commandPipelineContractFacts.didKeepRuntimeStateWriteBlocked,
        commandPipelineContractFacts.didConfirmNoNativeBridgeExpansion,
        commandPipelineContractFacts.didConfirmNoPublicApi,
        commandPipelineContractFacts.didConfirmNoProductionPublicCAbi,
        commandPipelineContractFacts.didConfirmNoRuntimeStateWrite,
        commandPipelineContractFacts.didConfirmNoCjpmTomlChange,
        commandPipelineContractFacts.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceReadiness {
    let drawableReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceDraft()
    let commandPipelineContractFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceFacts(
            drawableReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceReadiness(
        drawableReadiness,
        commandPipelineContractFacts
    )
}
