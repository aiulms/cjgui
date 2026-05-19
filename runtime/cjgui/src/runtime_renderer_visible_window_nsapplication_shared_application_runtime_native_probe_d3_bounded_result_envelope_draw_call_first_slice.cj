// 中文维护注释：本文件是 visible-window runtime native probe 的 draw-call
// first-slice readiness owner。
// Owner: runtime renderer internal draw call first slice。
// Truth: 消费 stage112 pipeline / vertex binding first-slice readiness，把下一步
// 收敛为 bounded isolated probe-local draw encoding 合约：在 pipeline state 与
// static triangle vertex buffer 已绑定后调用 draw primitives，然后在 submit 前停住。
// Stop-line: 本 owner 不 commit / present，不提交 GPU work，不执行 render，不写
// renderer state，不把 isolated evidence 升级为 production truth，也不扩
// production native bridge C ABI。
// Same-shape Boundary Brake: 本 owner 必须表达 draw-call first-slice contract；
// 不得退化成 approval、external packet、recovery、report wrapper 或 generic guard。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceFacts {
    let didConsumePipelineVertexBindingFirstSliceReadiness: Bool
    let didRequirePositivePipelineVertexBindingEnvelopeBeforeDraw: Bool
    let didRequireBoundedIsolatedDrawCallProbe: Bool
    let didRequireProbeLocalRenderCommandEncoder: Bool
    let didRequireProbeLocalPipelineStateBound: Bool
    let didRequireProbeLocalStaticTriangleVertexBufferBound: Bool
    let didRequireProbeLocalDrawPrimitivesCall: Bool
    let didRequireEndEncodingAfterDrawBeforeCleanup: Bool
    let didKeepCommitPresentGpuRenderBlocked: Bool
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
        didConsumePipelineVertexBindingFirstSliceReadiness: Bool,
        didRequirePositivePipelineVertexBindingEnvelopeBeforeDraw: Bool,
        didRequireBoundedIsolatedDrawCallProbe: Bool,
        didRequireProbeLocalRenderCommandEncoder: Bool,
        didRequireProbeLocalPipelineStateBound: Bool,
        didRequireProbeLocalStaticTriangleVertexBufferBound: Bool,
        didRequireProbeLocalDrawPrimitivesCall: Bool,
        didRequireEndEncodingAfterDrawBeforeCleanup: Bool,
        didKeepCommitPresentGpuRenderBlocked: Bool,
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
        this.didConsumePipelineVertexBindingFirstSliceReadiness =
            didConsumePipelineVertexBindingFirstSliceReadiness
        this.didRequirePositivePipelineVertexBindingEnvelopeBeforeDraw =
            didRequirePositivePipelineVertexBindingEnvelopeBeforeDraw
        this.didRequireBoundedIsolatedDrawCallProbe =
            didRequireBoundedIsolatedDrawCallProbe
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
        this.didKeepCommitPresentGpuRenderBlocked =
            didKeepCommitPresentGpuRenderBlocked
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceReadiness {
    let pipelineVertexBindingFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingFirstSliceReadiness
    let drawCallFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceFacts
    let didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceReadiness:
        Bool
    let shouldConsumePipelineVertexBindingFirstSliceReadiness: Bool
    let shouldRequirePositivePipelineVertexBindingEnvelopeBeforeDraw: Bool
    let shouldRequireBoundedIsolatedDrawCallProbe: Bool
    let shouldRequireProbeLocalRenderCommandEncoder: Bool
    let shouldRequireProbeLocalPipelineStateBound: Bool
    let shouldRequireProbeLocalStaticTriangleVertexBufferBound: Bool
    let shouldRequireProbeLocalDrawPrimitivesCall: Bool
    let shouldRequireEndEncodingAfterDrawBeforeCleanup: Bool
    let shouldKeepCommitPresentGpuRenderBlocked: Bool
    let shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool
    let shouldKeepRendererStateWriteBlocked: Bool
    let didConfirmPipelineVertexBindingFirstSliceInput: Bool
    let didConfirmDrawCallOrdering: Bool
    let didConfirmDrawCallStopLine: Bool
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
        pipelineVertexBindingFirstSliceReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingFirstSliceReadiness,
        drawCallFirstSliceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceFacts,
        didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceReadiness:
            Bool,
        shouldConsumePipelineVertexBindingFirstSliceReadiness: Bool,
        shouldRequirePositivePipelineVertexBindingEnvelopeBeforeDraw: Bool,
        shouldRequireBoundedIsolatedDrawCallProbe: Bool,
        shouldRequireProbeLocalRenderCommandEncoder: Bool,
        shouldRequireProbeLocalPipelineStateBound: Bool,
        shouldRequireProbeLocalStaticTriangleVertexBufferBound: Bool,
        shouldRequireProbeLocalDrawPrimitivesCall: Bool,
        shouldRequireEndEncodingAfterDrawBeforeCleanup: Bool,
        shouldKeepCommitPresentGpuRenderBlocked: Bool,
        shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool,
        shouldKeepRendererStateWriteBlocked: Bool,
        didConfirmPipelineVertexBindingFirstSliceInput: Bool,
        didConfirmDrawCallOrdering: Bool,
        didConfirmDrawCallStopLine: Bool,
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
        this.pipelineVertexBindingFirstSliceReadiness =
            pipelineVertexBindingFirstSliceReadiness
        this.drawCallFirstSliceFacts = drawCallFirstSliceFacts
        this.didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceReadiness =
            didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceReadiness
        this.shouldConsumePipelineVertexBindingFirstSliceReadiness =
            shouldConsumePipelineVertexBindingFirstSliceReadiness
        this.shouldRequirePositivePipelineVertexBindingEnvelopeBeforeDraw =
            shouldRequirePositivePipelineVertexBindingEnvelopeBeforeDraw
        this.shouldRequireBoundedIsolatedDrawCallProbe =
            shouldRequireBoundedIsolatedDrawCallProbe
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
        this.shouldKeepCommitPresentGpuRenderBlocked =
            shouldKeepCommitPresentGpuRenderBlocked
        this.shouldRequireProductionWriteAdmissionBeforeRendererStateWrite =
            shouldRequireProductionWriteAdmissionBeforeRendererStateWrite
        this.shouldKeepRendererStateWriteBlocked =
            shouldKeepRendererStateWriteBlocked
        this.didConfirmPipelineVertexBindingFirstSliceInput =
            didConfirmPipelineVertexBindingFirstSliceInput
        this.didConfirmDrawCallOrdering = didConfirmDrawCallOrdering
        this.didConfirmDrawCallStopLine = didConfirmDrawCallStopLine
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

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceFacts(
    pipelineVertexBindingFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceFacts(
        pipelineVertexBindingFirstSliceReadiness
            .didPrepareRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingFirstSliceReadiness,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        pipelineVertexBindingFirstSliceReadiness
            .shouldKeepDrawCommitPresentGpuRenderBlocked,
        pipelineVertexBindingFirstSliceReadiness
            .shouldRequireProductionWriteAdmissionBeforeRendererStateWrite,
        pipelineVertexBindingFirstSliceReadiness
            .shouldKeepRendererStateWriteBlocked,
        pipelineVertexBindingFirstSliceReadiness.didConfirmNoProductionTruthUpgrade,
        pipelineVertexBindingFirstSliceReadiness.didConfirmNoBackendReadyTruth,
        pipelineVertexBindingFirstSliceReadiness
            .didConfirmNoProductionNativeBridgeExpansion,
        pipelineVertexBindingFirstSliceReadiness.didConfirmNoPublicApi,
        pipelineVertexBindingFirstSliceReadiness.didConfirmNoProductionPublicCAbi,
        pipelineVertexBindingFirstSliceReadiness.didConfirmNoRuntimeStateWrite,
        pipelineVertexBindingFirstSliceReadiness.didConfirmNoCjpmTomlChange,
        pipelineVertexBindingFirstSliceReadiness.didConfirmNoRendererStateWrite,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceReadiness(
    pipelineVertexBindingFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingFirstSliceReadiness,
    drawCallFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceReadiness {
    let bindingInputReady =
        drawCallFirstSliceFacts
            .didConsumePipelineVertexBindingFirstSliceReadiness &&
        pipelineVertexBindingFirstSliceReadiness
            .didConfirmPipelineVertexBindingOrdering &&
        pipelineVertexBindingFirstSliceReadiness
            .didConfirmPipelineVertexBindingStopLine
    let orderingReady =
        drawCallFirstSliceFacts
            .didRequirePositivePipelineVertexBindingEnvelopeBeforeDraw &&
        drawCallFirstSliceFacts.didRequireBoundedIsolatedDrawCallProbe &&
        drawCallFirstSliceFacts.didRequireProbeLocalRenderCommandEncoder &&
        drawCallFirstSliceFacts.didRequireProbeLocalPipelineStateBound &&
        drawCallFirstSliceFacts
            .didRequireProbeLocalStaticTriangleVertexBufferBound &&
        drawCallFirstSliceFacts.didRequireProbeLocalDrawPrimitivesCall &&
        drawCallFirstSliceFacts.didRequireEndEncodingAfterDrawBeforeCleanup
    let stopLineReady =
        drawCallFirstSliceFacts.didKeepCommitPresentGpuRenderBlocked &&
        drawCallFirstSliceFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite &&
        drawCallFirstSliceFacts.didKeepRendererStateWriteBlocked &&
        drawCallFirstSliceFacts.didConfirmNoProductionTruthUpgrade &&
        drawCallFirstSliceFacts.didConfirmNoBackendReadyTruth &&
        drawCallFirstSliceFacts.didConfirmNoProductionNativeBridgeExpansion &&
        drawCallFirstSliceFacts.didConfirmNoPublicApi &&
        drawCallFirstSliceFacts.didConfirmNoProductionPublicCAbi &&
        drawCallFirstSliceFacts.didConfirmNoRuntimeStateWrite &&
        drawCallFirstSliceFacts.didConfirmNoCjpmTomlChange &&
        drawCallFirstSliceFacts.didConfirmNoRendererStateWrite &&
        drawCallFirstSliceFacts
            .didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    let readinessReady = bindingInputReady && orderingReady && stopLineReady

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceReadiness(
        pipelineVertexBindingFirstSliceReadiness,
        drawCallFirstSliceFacts,
        readinessReady,
        drawCallFirstSliceFacts
            .didConsumePipelineVertexBindingFirstSliceReadiness,
        drawCallFirstSliceFacts
            .didRequirePositivePipelineVertexBindingEnvelopeBeforeDraw,
        drawCallFirstSliceFacts.didRequireBoundedIsolatedDrawCallProbe,
        drawCallFirstSliceFacts.didRequireProbeLocalRenderCommandEncoder,
        drawCallFirstSliceFacts.didRequireProbeLocalPipelineStateBound,
        drawCallFirstSliceFacts
            .didRequireProbeLocalStaticTriangleVertexBufferBound,
        drawCallFirstSliceFacts.didRequireProbeLocalDrawPrimitivesCall,
        drawCallFirstSliceFacts.didRequireEndEncodingAfterDrawBeforeCleanup,
        drawCallFirstSliceFacts.didKeepCommitPresentGpuRenderBlocked,
        drawCallFirstSliceFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite,
        drawCallFirstSliceFacts.didKeepRendererStateWriteBlocked,
        bindingInputReady,
        orderingReady,
        stopLineReady,
        drawCallFirstSliceFacts.didConfirmNoProductionTruthUpgrade,
        drawCallFirstSliceFacts.didConfirmNoBackendReadyTruth,
        drawCallFirstSliceFacts.didConfirmNoProductionNativeBridgeExpansion,
        drawCallFirstSliceFacts.didConfirmNoPublicApi,
        drawCallFirstSliceFacts.didConfirmNoProductionPublicCAbi,
        drawCallFirstSliceFacts.didConfirmNoRuntimeStateWrite,
        drawCallFirstSliceFacts.didConfirmNoCjpmTomlChange,
        drawCallFirstSliceFacts.didConfirmNoRendererStateWrite,
        drawCallFirstSliceFacts
            .didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceReadiness {
    let pipelineVertexBindingFirstSliceReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingFirstSliceDraft()
    let drawCallFirstSliceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceFacts(
            pipelineVertexBindingFirstSliceReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceReadiness(
        pipelineVertexBindingFirstSliceReadiness,
        drawCallFirstSliceFacts
    )
}
