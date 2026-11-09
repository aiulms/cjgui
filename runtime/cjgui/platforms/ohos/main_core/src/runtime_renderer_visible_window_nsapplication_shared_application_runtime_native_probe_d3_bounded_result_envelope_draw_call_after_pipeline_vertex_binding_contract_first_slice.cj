// 中文维护注释：本文件是 stage139 draw-call after stage138 pipeline / vertex
// binding contract first-slice runtime owner。
// Owner: runtime renderer internal no-submit draw-call contract after pipeline
// state 与 static triangle vertex buffer 已绑定。
// Truth: 只消费 stage138 binding envelope；只有 packet 证明 pipeline state 与
// vertex buffer 已绑定后，才允许 isolated probe-local drawPrimitives 调用。
// Stop-line: 本 owner 不执行 native AppKit/Metal，不 commit / present，不提交
// GPU work，不观测 first frame，不写 renderer state / runtime_state.cj，不扩
// public API / public C ABI / native bridge。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceFacts {
    let didConsumePipelineVertexBindingAfterPreparationContract: Bool
    let didRequireStage138PipelineVertexBindingPacket: Bool
    let didRequirePositivePipelineVertexBindingBeforeDraw: Bool
    let didRequireBoundedDrawCallProbe: Bool
    let didRequireProbeLocalRenderCommandEncoder: Bool
    let didRequireProbeLocalPipelineStateBound: Bool
    let didRequireProbeLocalStaticTriangleVertexBufferBound: Bool
    let didRequireProbeLocalDrawPrimitivesCall: Bool
    let didRequireEndEncodingAfterDrawBeforeCleanup: Bool
    let didKeepCommitPresentGpuWorkBlocked: Bool
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
        didConsumePipelineVertexBindingAfterPreparationContract: Bool,
        didRequireStage138PipelineVertexBindingPacket: Bool,
        didRequirePositivePipelineVertexBindingBeforeDraw: Bool,
        didRequireBoundedDrawCallProbe: Bool,
        didRequireProbeLocalRenderCommandEncoder: Bool,
        didRequireProbeLocalPipelineStateBound: Bool,
        didRequireProbeLocalStaticTriangleVertexBufferBound: Bool,
        didRequireProbeLocalDrawPrimitivesCall: Bool,
        didRequireEndEncodingAfterDrawBeforeCleanup: Bool,
        didKeepCommitPresentGpuWorkBlocked: Bool,
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
        this.didConsumePipelineVertexBindingAfterPreparationContract =
            didConsumePipelineVertexBindingAfterPreparationContract
        this.didRequireStage138PipelineVertexBindingPacket =
            didRequireStage138PipelineVertexBindingPacket
        this.didRequirePositivePipelineVertexBindingBeforeDraw =
            didRequirePositivePipelineVertexBindingBeforeDraw
        this.didRequireBoundedDrawCallProbe = didRequireBoundedDrawCallProbe
        this.didRequireProbeLocalRenderCommandEncoder =
            didRequireProbeLocalRenderCommandEncoder
        this.didRequireProbeLocalPipelineStateBound =
            didRequireProbeLocalPipelineStateBound
        this.didRequireProbeLocalStaticTriangleVertexBufferBound =
            didRequireProbeLocalStaticTriangleVertexBufferBound
        this.didRequireProbeLocalDrawPrimitivesCall =
            didRequireProbeLocalDrawPrimitivesCall
        this.didRequireEndEncodingAfterDrawBeforeCleanup =
            didRequireEndEncodingAfterDrawBeforeCleanup
        this.didKeepCommitPresentGpuWorkBlocked =
            didKeepCommitPresentGpuWorkBlocked
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceReadiness {
    let pipelineVertexBinding:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceReadiness
    let drawCallFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceFacts
    let didPrepareDrawCallAfterPipelineVertexBindingContractFirstSliceReadiness:
        Bool
    let shouldConsumePipelineVertexBindingAfterPreparationContract: Bool
    let shouldRequireStage138PipelineVertexBindingPacket: Bool
    let shouldRequirePositivePipelineVertexBindingBeforeDraw: Bool
    let shouldRequireBoundedDrawCallProbe: Bool
    let shouldRequireProbeLocalRenderCommandEncoder: Bool
    let shouldRequireProbeLocalPipelineStateBound: Bool
    let shouldRequireProbeLocalStaticTriangleVertexBufferBound: Bool
    let shouldRequireProbeLocalDrawPrimitivesCall: Bool
    let shouldRequireEndEncodingAfterDrawBeforeCleanup: Bool
    let shouldKeepCommitPresentGpuWorkBlocked: Bool
    let didConfirmStage138PipelineVertexBindingInput: Bool
    let didConfirmDrawCallOrdering: Bool
    let didConfirmDrawCallStopLine: Bool
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
        pipelineVertexBinding:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceReadiness,
        drawCallFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceFacts,
        didPrepareDrawCallAfterPipelineVertexBindingContractFirstSliceReadiness:
            Bool,
        shouldConsumePipelineVertexBindingAfterPreparationContract: Bool,
        shouldRequireStage138PipelineVertexBindingPacket: Bool,
        shouldRequirePositivePipelineVertexBindingBeforeDraw: Bool,
        shouldRequireBoundedDrawCallProbe: Bool,
        shouldRequireProbeLocalRenderCommandEncoder: Bool,
        shouldRequireProbeLocalPipelineStateBound: Bool,
        shouldRequireProbeLocalStaticTriangleVertexBufferBound: Bool,
        shouldRequireProbeLocalDrawPrimitivesCall: Bool,
        shouldRequireEndEncodingAfterDrawBeforeCleanup: Bool,
        shouldKeepCommitPresentGpuWorkBlocked: Bool,
        didConfirmStage138PipelineVertexBindingInput: Bool,
        didConfirmDrawCallOrdering: Bool,
        didConfirmDrawCallStopLine: Bool,
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
        this.pipelineVertexBinding = pipelineVertexBinding
        this.drawCallFacts = drawCallFacts
        this.didPrepareDrawCallAfterPipelineVertexBindingContractFirstSliceReadiness =
            didPrepareDrawCallAfterPipelineVertexBindingContractFirstSliceReadiness
        this.shouldConsumePipelineVertexBindingAfterPreparationContract =
            shouldConsumePipelineVertexBindingAfterPreparationContract
        this.shouldRequireStage138PipelineVertexBindingPacket =
            shouldRequireStage138PipelineVertexBindingPacket
        this.shouldRequirePositivePipelineVertexBindingBeforeDraw =
            shouldRequirePositivePipelineVertexBindingBeforeDraw
        this.shouldRequireBoundedDrawCallProbe = shouldRequireBoundedDrawCallProbe
        this.shouldRequireProbeLocalRenderCommandEncoder =
            shouldRequireProbeLocalRenderCommandEncoder
        this.shouldRequireProbeLocalPipelineStateBound =
            shouldRequireProbeLocalPipelineStateBound
        this.shouldRequireProbeLocalStaticTriangleVertexBufferBound =
            shouldRequireProbeLocalStaticTriangleVertexBufferBound
        this.shouldRequireProbeLocalDrawPrimitivesCall =
            shouldRequireProbeLocalDrawPrimitivesCall
        this.shouldRequireEndEncodingAfterDrawBeforeCleanup =
            shouldRequireEndEncodingAfterDrawBeforeCleanup
        this.shouldKeepCommitPresentGpuWorkBlocked =
            shouldKeepCommitPresentGpuWorkBlocked
        this.didConfirmStage138PipelineVertexBindingInput =
            didConfirmStage138PipelineVertexBindingInput
        this.didConfirmDrawCallOrdering = didConfirmDrawCallOrdering
        this.didConfirmDrawCallStopLine = didConfirmDrawCallStopLine
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

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceFacts(
    pipelineVertexBinding:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceFacts(
        pipelineVertexBinding
            .didPreparePipelineVertexBindingAfterPreparationContractFirstSliceReadiness,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        pipelineVertexBinding.shouldKeepDrawCommitPresentGpuWorkBlocked,
        pipelineVertexBinding.didConfirmFirstFrameObservationBlocked,
        pipelineVertexBinding.didConfirmProductionTruthPromotionBlocked,
        pipelineVertexBinding.didConfirmRendererStateWriteAdmissionBlocked,
        pipelineVertexBinding.didConfirmRendererStateWriteBlocked,
        pipelineVertexBinding.didConfirmRuntimeStateWriteBlocked,
        pipelineVertexBinding.didConfirmNoNativeBridgeExpansion,
        pipelineVertexBinding.didConfirmNoPublicApi,
        pipelineVertexBinding.didConfirmNoProductionPublicCAbi,
        pipelineVertexBinding.didConfirmNoRuntimeStateWrite,
        pipelineVertexBinding.didConfirmNoCjpmTomlChange,
        pipelineVertexBinding.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceReadiness(
    pipelineVertexBinding:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceReadiness,
    drawCallFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceReadiness {
    let inputReady =
        drawCallFacts.didConsumePipelineVertexBindingAfterPreparationContract &&
        pipelineVertexBinding.didConfirmPipelineVertexBindingOrdering &&
        pipelineVertexBinding.didConfirmPipelineVertexBindingStopLine
    let orderingReady =
        drawCallFacts.didRequireStage138PipelineVertexBindingPacket &&
        drawCallFacts.didRequirePositivePipelineVertexBindingBeforeDraw &&
        drawCallFacts.didRequireBoundedDrawCallProbe &&
        drawCallFacts.didRequireProbeLocalRenderCommandEncoder &&
        drawCallFacts.didRequireProbeLocalPipelineStateBound &&
        drawCallFacts.didRequireProbeLocalStaticTriangleVertexBufferBound &&
        drawCallFacts.didRequireProbeLocalDrawPrimitivesCall &&
        drawCallFacts.didRequireEndEncodingAfterDrawBeforeCleanup
    let stopLineReady =
        drawCallFacts.didKeepCommitPresentGpuWorkBlocked &&
        drawCallFacts.didKeepFirstFrameObservationBlocked &&
        drawCallFacts.didKeepProductionTruthPromotionBlocked &&
        drawCallFacts.didKeepRendererStateWriteAdmissionBlocked &&
        drawCallFacts.didKeepRendererStateWriteBlocked &&
        drawCallFacts.didKeepRuntimeStateWriteBlocked &&
        drawCallFacts.didConfirmNoNativeBridgeExpansion &&
        drawCallFacts.didConfirmNoPublicApi &&
        drawCallFacts.didConfirmNoProductionPublicCAbi &&
        drawCallFacts.didConfirmNoRuntimeStateWrite &&
        drawCallFacts.didConfirmNoCjpmTomlChange &&
        drawCallFacts.didConfirmNoRendererStateWrite

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceReadiness(
        pipelineVertexBinding,
        drawCallFacts,
        inputReady && orderingReady && stopLineReady,
        drawCallFacts.didConsumePipelineVertexBindingAfterPreparationContract,
        drawCallFacts.didRequireStage138PipelineVertexBindingPacket,
        drawCallFacts.didRequirePositivePipelineVertexBindingBeforeDraw,
        drawCallFacts.didRequireBoundedDrawCallProbe,
        drawCallFacts.didRequireProbeLocalRenderCommandEncoder,
        drawCallFacts.didRequireProbeLocalPipelineStateBound,
        drawCallFacts.didRequireProbeLocalStaticTriangleVertexBufferBound,
        drawCallFacts.didRequireProbeLocalDrawPrimitivesCall,
        drawCallFacts.didRequireEndEncodingAfterDrawBeforeCleanup,
        drawCallFacts.didKeepCommitPresentGpuWorkBlocked,
        inputReady,
        orderingReady,
        stopLineReady,
        drawCallFacts.didKeepFirstFrameObservationBlocked,
        drawCallFacts.didKeepProductionTruthPromotionBlocked,
        drawCallFacts.didKeepRendererStateWriteAdmissionBlocked,
        drawCallFacts.didKeepRendererStateWriteBlocked,
        drawCallFacts.didKeepRuntimeStateWriteBlocked,
        drawCallFacts.didConfirmNoNativeBridgeExpansion,
        drawCallFacts.didConfirmNoPublicApi,
        drawCallFacts.didConfirmNoProductionPublicCAbi,
        drawCallFacts.didConfirmNoRuntimeStateWrite,
        drawCallFacts.didConfirmNoCjpmTomlChange,
        drawCallFacts.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceReadiness {
    let pipelineVertexBinding =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceDraft()
    let drawCallFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceFacts(
            pipelineVertexBinding
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceReadiness(
        pipelineVertexBinding,
        drawCallFacts
    )
}
