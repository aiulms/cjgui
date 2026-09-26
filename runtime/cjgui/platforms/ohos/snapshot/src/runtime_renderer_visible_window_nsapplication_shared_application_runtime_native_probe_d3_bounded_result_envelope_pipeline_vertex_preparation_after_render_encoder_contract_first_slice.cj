// 中文维护注释：本文件是 stage137 pipeline / vertex preparation after
// stage136 render encoder contract first-slice runtime owner。
// Owner: runtime renderer internal pipeline / vertex preparation contract after
// stage136 command buffer / render encoder envelope。
// Truth: 只消费 stage136 render encoder contract envelope；只有当前 packet
// 证明 positive render encoder / endEncoding 后，才允许 isolated probe 创建
// shader library / functions、pipeline descriptor / pipeline state 与静态三角形
// vertex buffer。
// Stop-line: 本 owner 不执行 native AppKit/Metal，不绑定 pipeline / vertex，
// 不 draw / commit / present，不提交 GPU work，不写 renderer state /
// runtime_state.cj，不扩 public API / public C ABI / native bridge。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceFacts {
    let didConsumeCommandBufferRenderEncoderContractAfterDrawableReadiness: Bool
    let didRequireStage136RenderEncoderContractPacket: Bool
    let didRequirePositiveRenderEncoderBeforePipelineVertexPreparation: Bool
    let didRequireBoundedPipelineVertexPreparationProbe: Bool
    let didRequireProbeLocalShaderLibrary: Bool
    let didRequireProbeLocalShaderFunctions: Bool
    let didRequireProbeLocalPipelineDescriptor: Bool
    let didRequireProbeLocalPipelineState: Bool
    let didRequireProbeLocalStaticTriangleVertexBuffer: Bool
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
        didConsumeCommandBufferRenderEncoderContractAfterDrawableReadiness: Bool,
        didRequireStage136RenderEncoderContractPacket: Bool,
        didRequirePositiveRenderEncoderBeforePipelineVertexPreparation: Bool,
        didRequireBoundedPipelineVertexPreparationProbe: Bool,
        didRequireProbeLocalShaderLibrary: Bool,
        didRequireProbeLocalShaderFunctions: Bool,
        didRequireProbeLocalPipelineDescriptor: Bool,
        didRequireProbeLocalPipelineState: Bool,
        didRequireProbeLocalStaticTriangleVertexBuffer: Bool,
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
        this.didConsumeCommandBufferRenderEncoderContractAfterDrawableReadiness =
            didConsumeCommandBufferRenderEncoderContractAfterDrawableReadiness
        this.didRequireStage136RenderEncoderContractPacket =
            didRequireStage136RenderEncoderContractPacket
        this.didRequirePositiveRenderEncoderBeforePipelineVertexPreparation =
            didRequirePositiveRenderEncoderBeforePipelineVertexPreparation
        this.didRequireBoundedPipelineVertexPreparationProbe =
            didRequireBoundedPipelineVertexPreparationProbe
        this.didRequireProbeLocalShaderLibrary = didRequireProbeLocalShaderLibrary
        this.didRequireProbeLocalShaderFunctions =
            didRequireProbeLocalShaderFunctions
        this.didRequireProbeLocalPipelineDescriptor =
            didRequireProbeLocalPipelineDescriptor
        this.didRequireProbeLocalPipelineState =
            didRequireProbeLocalPipelineState
        this.didRequireProbeLocalStaticTriangleVertexBuffer =
            didRequireProbeLocalStaticTriangleVertexBuffer
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceReadiness {
    let commandBufferRenderEncoderContract:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceReadiness
    let pipelineVertexPreparationFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceFacts
    let didPreparePipelineVertexPreparationAfterRenderEncoderContractFirstSliceReadiness:
        Bool
    let shouldConsumeCommandBufferRenderEncoderContractAfterDrawableReadiness:
        Bool
    let shouldRequireStage136RenderEncoderContractPacket: Bool
    let shouldRequirePositiveRenderEncoderBeforePipelineVertexPreparation: Bool
    let shouldRequireBoundedPipelineVertexPreparationProbe: Bool
    let shouldRequireProbeLocalShaderLibrary: Bool
    let shouldRequireProbeLocalShaderFunctions: Bool
    let shouldRequireProbeLocalPipelineDescriptor: Bool
    let shouldRequireProbeLocalPipelineState: Bool
    let shouldRequireProbeLocalStaticTriangleVertexBuffer: Bool
    let shouldKeepPipelineStateBindingBlocked: Bool
    let shouldKeepVertexBufferBindingBlocked: Bool
    let shouldKeepDrawCommitPresentGpuWorkBlocked: Bool
    let didConfirmStage136RenderEncoderContractInput: Bool
    let didConfirmPipelineVertexPreparationOrdering: Bool
    let didConfirmPipelineVertexPreparationStopLine: Bool
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
        commandBufferRenderEncoderContract:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceReadiness,
        pipelineVertexPreparationFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceFacts,
        didPreparePipelineVertexPreparationAfterRenderEncoderContractFirstSliceReadiness:
            Bool,
        shouldConsumeCommandBufferRenderEncoderContractAfterDrawableReadiness:
            Bool,
        shouldRequireStage136RenderEncoderContractPacket: Bool,
        shouldRequirePositiveRenderEncoderBeforePipelineVertexPreparation: Bool,
        shouldRequireBoundedPipelineVertexPreparationProbe: Bool,
        shouldRequireProbeLocalShaderLibrary: Bool,
        shouldRequireProbeLocalShaderFunctions: Bool,
        shouldRequireProbeLocalPipelineDescriptor: Bool,
        shouldRequireProbeLocalPipelineState: Bool,
        shouldRequireProbeLocalStaticTriangleVertexBuffer: Bool,
        shouldKeepPipelineStateBindingBlocked: Bool,
        shouldKeepVertexBufferBindingBlocked: Bool,
        shouldKeepDrawCommitPresentGpuWorkBlocked: Bool,
        didConfirmStage136RenderEncoderContractInput: Bool,
        didConfirmPipelineVertexPreparationOrdering: Bool,
        didConfirmPipelineVertexPreparationStopLine: Bool,
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
        this.commandBufferRenderEncoderContract =
            commandBufferRenderEncoderContract
        this.pipelineVertexPreparationFacts = pipelineVertexPreparationFacts
        this.didPreparePipelineVertexPreparationAfterRenderEncoderContractFirstSliceReadiness =
            didPreparePipelineVertexPreparationAfterRenderEncoderContractFirstSliceReadiness
        this.shouldConsumeCommandBufferRenderEncoderContractAfterDrawableReadiness =
            shouldConsumeCommandBufferRenderEncoderContractAfterDrawableReadiness
        this.shouldRequireStage136RenderEncoderContractPacket =
            shouldRequireStage136RenderEncoderContractPacket
        this.shouldRequirePositiveRenderEncoderBeforePipelineVertexPreparation =
            shouldRequirePositiveRenderEncoderBeforePipelineVertexPreparation
        this.shouldRequireBoundedPipelineVertexPreparationProbe =
            shouldRequireBoundedPipelineVertexPreparationProbe
        this.shouldRequireProbeLocalShaderLibrary =
            shouldRequireProbeLocalShaderLibrary
        this.shouldRequireProbeLocalShaderFunctions =
            shouldRequireProbeLocalShaderFunctions
        this.shouldRequireProbeLocalPipelineDescriptor =
            shouldRequireProbeLocalPipelineDescriptor
        this.shouldRequireProbeLocalPipelineState =
            shouldRequireProbeLocalPipelineState
        this.shouldRequireProbeLocalStaticTriangleVertexBuffer =
            shouldRequireProbeLocalStaticTriangleVertexBuffer
        this.shouldKeepPipelineStateBindingBlocked =
            shouldKeepPipelineStateBindingBlocked
        this.shouldKeepVertexBufferBindingBlocked =
            shouldKeepVertexBufferBindingBlocked
        this.shouldKeepDrawCommitPresentGpuWorkBlocked =
            shouldKeepDrawCommitPresentGpuWorkBlocked
        this.didConfirmStage136RenderEncoderContractInput =
            didConfirmStage136RenderEncoderContractInput
        this.didConfirmPipelineVertexPreparationOrdering =
            didConfirmPipelineVertexPreparationOrdering
        this.didConfirmPipelineVertexPreparationStopLine =
            didConfirmPipelineVertexPreparationStopLine
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
        this.didConfirmNoNativeBridgeExpansion = didConfirmNoNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi = didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceFacts(
    commandBufferRenderEncoderContract:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceFacts(
        commandBufferRenderEncoderContract
            .didPrepareCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceReadiness,
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
        commandBufferRenderEncoderContract
            .shouldKeepDrawCommitPresentGpuWorkBlocked,
        commandBufferRenderEncoderContract
            .didConfirmFirstFrameObservationBlocked,
        commandBufferRenderEncoderContract
            .didConfirmProductionTruthPromotionBlocked,
        commandBufferRenderEncoderContract
            .didConfirmRendererStateWriteAdmissionBlocked,
        commandBufferRenderEncoderContract.didConfirmRendererStateWriteBlocked,
        commandBufferRenderEncoderContract.didConfirmRuntimeStateWriteBlocked,
        commandBufferRenderEncoderContract.didConfirmNoNativeBridgeExpansion,
        commandBufferRenderEncoderContract.didConfirmNoPublicApi,
        commandBufferRenderEncoderContract.didConfirmNoProductionPublicCAbi,
        commandBufferRenderEncoderContract.didConfirmNoRuntimeStateWrite,
        commandBufferRenderEncoderContract.didConfirmNoCjpmTomlChange,
        commandBufferRenderEncoderContract.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceReadiness(
    commandBufferRenderEncoderContract:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceReadiness,
    pipelineVertexPreparationFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceReadiness {
    let inputReady =
        pipelineVertexPreparationFacts
            .didConsumeCommandBufferRenderEncoderContractAfterDrawableReadiness &&
        commandBufferRenderEncoderContract
            .didConfirmCommandBufferRenderEncoderContractGate &&
        commandBufferRenderEncoderContract.didConfirmRenderEncoderStopLine
    let orderingReady =
        pipelineVertexPreparationFacts
            .didRequireStage136RenderEncoderContractPacket &&
        pipelineVertexPreparationFacts
            .didRequirePositiveRenderEncoderBeforePipelineVertexPreparation &&
        pipelineVertexPreparationFacts
            .didRequireBoundedPipelineVertexPreparationProbe &&
        pipelineVertexPreparationFacts.didRequireProbeLocalShaderLibrary &&
        pipelineVertexPreparationFacts.didRequireProbeLocalShaderFunctions &&
        pipelineVertexPreparationFacts.didRequireProbeLocalPipelineDescriptor &&
        pipelineVertexPreparationFacts.didRequireProbeLocalPipelineState &&
        pipelineVertexPreparationFacts
            .didRequireProbeLocalStaticTriangleVertexBuffer
    let stopLineReady =
        pipelineVertexPreparationFacts.didKeepPipelineStateBindingBlocked &&
        pipelineVertexPreparationFacts.didKeepVertexBufferBindingBlocked &&
        pipelineVertexPreparationFacts
            .didKeepDrawCommitPresentGpuWorkBlocked &&
        pipelineVertexPreparationFacts.didKeepFirstFrameObservationBlocked &&
        pipelineVertexPreparationFacts.didKeepProductionTruthPromotionBlocked &&
        pipelineVertexPreparationFacts
            .didKeepRendererStateWriteAdmissionBlocked &&
        pipelineVertexPreparationFacts.didKeepRendererStateWriteBlocked &&
        pipelineVertexPreparationFacts.didKeepRuntimeStateWriteBlocked &&
        pipelineVertexPreparationFacts.didConfirmNoNativeBridgeExpansion &&
        pipelineVertexPreparationFacts.didConfirmNoPublicApi &&
        pipelineVertexPreparationFacts.didConfirmNoProductionPublicCAbi &&
        pipelineVertexPreparationFacts.didConfirmNoRuntimeStateWrite &&
        pipelineVertexPreparationFacts.didConfirmNoCjpmTomlChange &&
        pipelineVertexPreparationFacts.didConfirmNoRendererStateWrite

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceReadiness(
        commandBufferRenderEncoderContract,
        pipelineVertexPreparationFacts,
        inputReady && orderingReady && stopLineReady,
        pipelineVertexPreparationFacts
            .didConsumeCommandBufferRenderEncoderContractAfterDrawableReadiness,
        pipelineVertexPreparationFacts
            .didRequireStage136RenderEncoderContractPacket,
        pipelineVertexPreparationFacts
            .didRequirePositiveRenderEncoderBeforePipelineVertexPreparation,
        pipelineVertexPreparationFacts
            .didRequireBoundedPipelineVertexPreparationProbe,
        pipelineVertexPreparationFacts.didRequireProbeLocalShaderLibrary,
        pipelineVertexPreparationFacts.didRequireProbeLocalShaderFunctions,
        pipelineVertexPreparationFacts.didRequireProbeLocalPipelineDescriptor,
        pipelineVertexPreparationFacts.didRequireProbeLocalPipelineState,
        pipelineVertexPreparationFacts
            .didRequireProbeLocalStaticTriangleVertexBuffer,
        pipelineVertexPreparationFacts.didKeepPipelineStateBindingBlocked,
        pipelineVertexPreparationFacts.didKeepVertexBufferBindingBlocked,
        pipelineVertexPreparationFacts.didKeepDrawCommitPresentGpuWorkBlocked,
        inputReady,
        orderingReady,
        stopLineReady,
        pipelineVertexPreparationFacts.didKeepFirstFrameObservationBlocked,
        pipelineVertexPreparationFacts.didKeepProductionTruthPromotionBlocked,
        pipelineVertexPreparationFacts
            .didKeepRendererStateWriteAdmissionBlocked,
        pipelineVertexPreparationFacts.didKeepRendererStateWriteBlocked,
        pipelineVertexPreparationFacts.didKeepRuntimeStateWriteBlocked,
        pipelineVertexPreparationFacts.didConfirmNoNativeBridgeExpansion,
        pipelineVertexPreparationFacts.didConfirmNoPublicApi,
        pipelineVertexPreparationFacts.didConfirmNoProductionPublicCAbi,
        pipelineVertexPreparationFacts.didConfirmNoRuntimeStateWrite,
        pipelineVertexPreparationFacts.didConfirmNoCjpmTomlChange,
        pipelineVertexPreparationFacts.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceReadiness {
    let commandBufferRenderEncoderContract =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceDraft()
    let pipelineVertexPreparationFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceFacts(
            commandBufferRenderEncoderContract
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceReadiness(
        commandBufferRenderEncoderContract,
        pipelineVertexPreparationFacts
    )
}
