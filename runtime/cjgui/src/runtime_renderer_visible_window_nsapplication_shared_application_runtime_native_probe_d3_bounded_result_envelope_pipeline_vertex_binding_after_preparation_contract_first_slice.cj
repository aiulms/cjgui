// 中文维护注释：本文件是 stage138 pipeline / vertex binding after stage137
// preparation contract first-slice runtime owner。
// Owner: runtime renderer internal pipeline / vertex binding contract after
// stage137 pipeline state / static triangle vertex-buffer preparation。
// Truth: 只消费 stage137 preparation envelope；只有 packet 证明 pipeline state
// 与 vertex buffer 已由 isolated probe 创建后，才允许 isolated probe-local
// encoder binding。
// Stop-line: 本 owner 不执行 native AppKit/Metal，不 draw / commit / present，
// 不提交 GPU work，不写 renderer state / runtime_state.cj，不扩 public API /
// public C ABI / native bridge。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceFacts {
    let didConsumePipelineVertexPreparationAfterRenderEncoderContract: Bool
    let didRequireStage137PipelineVertexPreparationPacket: Bool
    let didRequirePositivePipelineVertexPreparationBeforeBinding: Bool
    let didRequireBoundedPipelineVertexBindingProbe: Bool
    let didRequireProbeLocalRenderCommandEncoder: Bool
    let didRequireProbeLocalPipelineStateCreated: Bool
    let didRequireProbeLocalStaticTriangleVertexBufferCreated: Bool
    let didRequireProbeLocalPipelineStateBinding: Bool
    let didRequireProbeLocalVertexBufferBinding: Bool
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
        didConsumePipelineVertexPreparationAfterRenderEncoderContract: Bool,
        didRequireStage137PipelineVertexPreparationPacket: Bool,
        didRequirePositivePipelineVertexPreparationBeforeBinding: Bool,
        didRequireBoundedPipelineVertexBindingProbe: Bool,
        didRequireProbeLocalRenderCommandEncoder: Bool,
        didRequireProbeLocalPipelineStateCreated: Bool,
        didRequireProbeLocalStaticTriangleVertexBufferCreated: Bool,
        didRequireProbeLocalPipelineStateBinding: Bool,
        didRequireProbeLocalVertexBufferBinding: Bool,
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
        this.didConsumePipelineVertexPreparationAfterRenderEncoderContract =
            didConsumePipelineVertexPreparationAfterRenderEncoderContract
        this.didRequireStage137PipelineVertexPreparationPacket =
            didRequireStage137PipelineVertexPreparationPacket
        this.didRequirePositivePipelineVertexPreparationBeforeBinding =
            didRequirePositivePipelineVertexPreparationBeforeBinding
        this.didRequireBoundedPipelineVertexBindingProbe =
            didRequireBoundedPipelineVertexBindingProbe
        this.didRequireProbeLocalRenderCommandEncoder =
            didRequireProbeLocalRenderCommandEncoder
        this.didRequireProbeLocalPipelineStateCreated =
            didRequireProbeLocalPipelineStateCreated
        this.didRequireProbeLocalStaticTriangleVertexBufferCreated =
            didRequireProbeLocalStaticTriangleVertexBufferCreated
        this.didRequireProbeLocalPipelineStateBinding =
            didRequireProbeLocalPipelineStateBinding
        this.didRequireProbeLocalVertexBufferBinding =
            didRequireProbeLocalVertexBufferBinding
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceReadiness {
    let pipelineVertexPreparation:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceReadiness
    let pipelineVertexBindingFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceFacts
    let didPreparePipelineVertexBindingAfterPreparationContractFirstSliceReadiness:
        Bool
    let shouldConsumePipelineVertexPreparationAfterRenderEncoderContract: Bool
    let shouldRequireStage137PipelineVertexPreparationPacket: Bool
    let shouldRequirePositivePipelineVertexPreparationBeforeBinding: Bool
    let shouldRequireBoundedPipelineVertexBindingProbe: Bool
    let shouldRequireProbeLocalRenderCommandEncoder: Bool
    let shouldRequireProbeLocalPipelineStateCreated: Bool
    let shouldRequireProbeLocalStaticTriangleVertexBufferCreated: Bool
    let shouldRequireProbeLocalPipelineStateBinding: Bool
    let shouldRequireProbeLocalVertexBufferBinding: Bool
    let shouldKeepDrawCommitPresentGpuWorkBlocked: Bool
    let didConfirmStage137PipelineVertexPreparationInput: Bool
    let didConfirmPipelineVertexBindingOrdering: Bool
    let didConfirmPipelineVertexBindingStopLine: Bool
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
        pipelineVertexPreparation:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceReadiness,
        pipelineVertexBindingFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceFacts,
        didPreparePipelineVertexBindingAfterPreparationContractFirstSliceReadiness:
            Bool,
        shouldConsumePipelineVertexPreparationAfterRenderEncoderContract: Bool,
        shouldRequireStage137PipelineVertexPreparationPacket: Bool,
        shouldRequirePositivePipelineVertexPreparationBeforeBinding: Bool,
        shouldRequireBoundedPipelineVertexBindingProbe: Bool,
        shouldRequireProbeLocalRenderCommandEncoder: Bool,
        shouldRequireProbeLocalPipelineStateCreated: Bool,
        shouldRequireProbeLocalStaticTriangleVertexBufferCreated: Bool,
        shouldRequireProbeLocalPipelineStateBinding: Bool,
        shouldRequireProbeLocalVertexBufferBinding: Bool,
        shouldKeepDrawCommitPresentGpuWorkBlocked: Bool,
        didConfirmStage137PipelineVertexPreparationInput: Bool,
        didConfirmPipelineVertexBindingOrdering: Bool,
        didConfirmPipelineVertexBindingStopLine: Bool,
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
        this.pipelineVertexPreparation = pipelineVertexPreparation
        this.pipelineVertexBindingFacts = pipelineVertexBindingFacts
        this.didPreparePipelineVertexBindingAfterPreparationContractFirstSliceReadiness =
            didPreparePipelineVertexBindingAfterPreparationContractFirstSliceReadiness
        this.shouldConsumePipelineVertexPreparationAfterRenderEncoderContract =
            shouldConsumePipelineVertexPreparationAfterRenderEncoderContract
        this.shouldRequireStage137PipelineVertexPreparationPacket =
            shouldRequireStage137PipelineVertexPreparationPacket
        this.shouldRequirePositivePipelineVertexPreparationBeforeBinding =
            shouldRequirePositivePipelineVertexPreparationBeforeBinding
        this.shouldRequireBoundedPipelineVertexBindingProbe =
            shouldRequireBoundedPipelineVertexBindingProbe
        this.shouldRequireProbeLocalRenderCommandEncoder =
            shouldRequireProbeLocalRenderCommandEncoder
        this.shouldRequireProbeLocalPipelineStateCreated =
            shouldRequireProbeLocalPipelineStateCreated
        this.shouldRequireProbeLocalStaticTriangleVertexBufferCreated =
            shouldRequireProbeLocalStaticTriangleVertexBufferCreated
        this.shouldRequireProbeLocalPipelineStateBinding =
            shouldRequireProbeLocalPipelineStateBinding
        this.shouldRequireProbeLocalVertexBufferBinding =
            shouldRequireProbeLocalVertexBufferBinding
        this.shouldKeepDrawCommitPresentGpuWorkBlocked =
            shouldKeepDrawCommitPresentGpuWorkBlocked
        this.didConfirmStage137PipelineVertexPreparationInput =
            didConfirmStage137PipelineVertexPreparationInput
        this.didConfirmPipelineVertexBindingOrdering =
            didConfirmPipelineVertexBindingOrdering
        this.didConfirmPipelineVertexBindingStopLine =
            didConfirmPipelineVertexBindingStopLine
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

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceFacts(
    pipelineVertexPreparation:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceFacts(
        pipelineVertexPreparation
            .didPreparePipelineVertexPreparationAfterRenderEncoderContractFirstSliceReadiness,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        pipelineVertexPreparation.shouldKeepDrawCommitPresentGpuWorkBlocked,
        pipelineVertexPreparation.didConfirmFirstFrameObservationBlocked,
        pipelineVertexPreparation.didConfirmProductionTruthPromotionBlocked,
        pipelineVertexPreparation
            .didConfirmRendererStateWriteAdmissionBlocked,
        pipelineVertexPreparation.didConfirmRendererStateWriteBlocked,
        pipelineVertexPreparation.didConfirmRuntimeStateWriteBlocked,
        pipelineVertexPreparation.didConfirmNoNativeBridgeExpansion,
        pipelineVertexPreparation.didConfirmNoPublicApi,
        pipelineVertexPreparation.didConfirmNoProductionPublicCAbi,
        pipelineVertexPreparation.didConfirmNoRuntimeStateWrite,
        pipelineVertexPreparation.didConfirmNoCjpmTomlChange,
        pipelineVertexPreparation.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceReadiness(
    pipelineVertexPreparation:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceReadiness,
    pipelineVertexBindingFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceReadiness {
    let inputReady =
        pipelineVertexBindingFacts
            .didConsumePipelineVertexPreparationAfterRenderEncoderContract &&
        pipelineVertexPreparation
            .didConfirmPipelineVertexPreparationOrdering &&
        pipelineVertexPreparation.didConfirmPipelineVertexPreparationStopLine
    let orderingReady =
        pipelineVertexBindingFacts
            .didRequireStage137PipelineVertexPreparationPacket &&
        pipelineVertexBindingFacts
            .didRequirePositivePipelineVertexPreparationBeforeBinding &&
        pipelineVertexBindingFacts.didRequireBoundedPipelineVertexBindingProbe &&
        pipelineVertexBindingFacts.didRequireProbeLocalRenderCommandEncoder &&
        pipelineVertexBindingFacts.didRequireProbeLocalPipelineStateCreated &&
        pipelineVertexBindingFacts
            .didRequireProbeLocalStaticTriangleVertexBufferCreated &&
        pipelineVertexBindingFacts.didRequireProbeLocalPipelineStateBinding &&
        pipelineVertexBindingFacts.didRequireProbeLocalVertexBufferBinding
    let stopLineReady =
        pipelineVertexBindingFacts.didKeepDrawCommitPresentGpuWorkBlocked &&
        pipelineVertexBindingFacts.didKeepFirstFrameObservationBlocked &&
        pipelineVertexBindingFacts.didKeepProductionTruthPromotionBlocked &&
        pipelineVertexBindingFacts
            .didKeepRendererStateWriteAdmissionBlocked &&
        pipelineVertexBindingFacts.didKeepRendererStateWriteBlocked &&
        pipelineVertexBindingFacts.didKeepRuntimeStateWriteBlocked &&
        pipelineVertexBindingFacts.didConfirmNoNativeBridgeExpansion &&
        pipelineVertexBindingFacts.didConfirmNoPublicApi &&
        pipelineVertexBindingFacts.didConfirmNoProductionPublicCAbi &&
        pipelineVertexBindingFacts.didConfirmNoRuntimeStateWrite &&
        pipelineVertexBindingFacts.didConfirmNoCjpmTomlChange &&
        pipelineVertexBindingFacts.didConfirmNoRendererStateWrite

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceReadiness(
        pipelineVertexPreparation,
        pipelineVertexBindingFacts,
        inputReady && orderingReady && stopLineReady,
        pipelineVertexBindingFacts
            .didConsumePipelineVertexPreparationAfterRenderEncoderContract,
        pipelineVertexBindingFacts
            .didRequireStage137PipelineVertexPreparationPacket,
        pipelineVertexBindingFacts
            .didRequirePositivePipelineVertexPreparationBeforeBinding,
        pipelineVertexBindingFacts.didRequireBoundedPipelineVertexBindingProbe,
        pipelineVertexBindingFacts.didRequireProbeLocalRenderCommandEncoder,
        pipelineVertexBindingFacts.didRequireProbeLocalPipelineStateCreated,
        pipelineVertexBindingFacts
            .didRequireProbeLocalStaticTriangleVertexBufferCreated,
        pipelineVertexBindingFacts.didRequireProbeLocalPipelineStateBinding,
        pipelineVertexBindingFacts.didRequireProbeLocalVertexBufferBinding,
        pipelineVertexBindingFacts.didKeepDrawCommitPresentGpuWorkBlocked,
        inputReady,
        orderingReady,
        stopLineReady,
        pipelineVertexBindingFacts.didKeepFirstFrameObservationBlocked,
        pipelineVertexBindingFacts.didKeepProductionTruthPromotionBlocked,
        pipelineVertexBindingFacts
            .didKeepRendererStateWriteAdmissionBlocked,
        pipelineVertexBindingFacts.didKeepRendererStateWriteBlocked,
        pipelineVertexBindingFacts.didKeepRuntimeStateWriteBlocked,
        pipelineVertexBindingFacts.didConfirmNoNativeBridgeExpansion,
        pipelineVertexBindingFacts.didConfirmNoPublicApi,
        pipelineVertexBindingFacts.didConfirmNoProductionPublicCAbi,
        pipelineVertexBindingFacts.didConfirmNoRuntimeStateWrite,
        pipelineVertexBindingFacts.didConfirmNoCjpmTomlChange,
        pipelineVertexBindingFacts.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceReadiness {
    let pipelineVertexPreparation =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceDraft()
    let pipelineVertexBindingFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceFacts(
            pipelineVertexPreparation
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceReadiness(
        pipelineVertexPreparation,
        pipelineVertexBindingFacts
    )
}
