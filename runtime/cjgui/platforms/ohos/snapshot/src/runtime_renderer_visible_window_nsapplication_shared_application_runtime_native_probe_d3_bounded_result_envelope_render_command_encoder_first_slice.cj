// 中文维护注释：本文件是 visible-window runtime native probe 的
// render command encoder creation first-slice readiness owner。
// Owner: runtime renderer internal render command encoder first slice。
// Truth: 消费 stage109 color attachment configuration first-slice readiness 与
// 既有 render command encoder no-submit planning readiness，把下一步收敛为
// bounded isolated probe-local command queue / command buffer / render command
// encoder creation + endEncoding 合约。
// Stop-line: production bridge 仍不暴露 encoder creation callable；本 owner
// 不创建 pipeline state / vertex buffer，不 draw，不 commit / present，不提交
// GPU work，不写 renderer state，不把 isolated evidence 升级为 production truth。
// Same-shape Boundary Brake: 本 owner 必须表达 render command encoder
// first-slice contract；不得退化成 approval、external packet、recovery、
// report wrapper 或 generic guard。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceFacts {
    let didConsumeColorAttachmentConfigurationFirstSliceReadiness: Bool
    let didConsumeRenderCommandEncoderNoSubmitPlanningReadiness: Bool
    let didRequirePositiveColorAttachmentEnvelopeBeforeEncoder: Bool
    let didRequireBoundedIsolatedRenderCommandEncoderProbe: Bool
    let didRequireProbeLocalCommandQueue: Bool
    let didRequireProbeLocalCommandBuffer: Bool
    let didRequireProbeLocalRenderPassDescriptorInput: Bool
    let didRequireProbeLocalRenderCommandEncoder: Bool
    let didRequireEndEncodingBeforeCleanup: Bool
    let didRequireDescriptorDrawableLayerDeviceCleanupCoownership: Bool
    let didKeepProductionEncoderBridgeBlocked: Bool
    let didKeepPipelineVertexDrawCommitPresentGpuRenderBlocked: Bool
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
        didConsumeColorAttachmentConfigurationFirstSliceReadiness: Bool,
        didConsumeRenderCommandEncoderNoSubmitPlanningReadiness: Bool,
        didRequirePositiveColorAttachmentEnvelopeBeforeEncoder: Bool,
        didRequireBoundedIsolatedRenderCommandEncoderProbe: Bool,
        didRequireProbeLocalCommandQueue: Bool,
        didRequireProbeLocalCommandBuffer: Bool,
        didRequireProbeLocalRenderPassDescriptorInput: Bool,
        didRequireProbeLocalRenderCommandEncoder: Bool,
        didRequireEndEncodingBeforeCleanup: Bool,
        didRequireDescriptorDrawableLayerDeviceCleanupCoownership: Bool,
        didKeepProductionEncoderBridgeBlocked: Bool,
        didKeepPipelineVertexDrawCommitPresentGpuRenderBlocked: Bool,
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
        this.didConsumeColorAttachmentConfigurationFirstSliceReadiness =
            didConsumeColorAttachmentConfigurationFirstSliceReadiness
        this.didConsumeRenderCommandEncoderNoSubmitPlanningReadiness =
            didConsumeRenderCommandEncoderNoSubmitPlanningReadiness
        this.didRequirePositiveColorAttachmentEnvelopeBeforeEncoder =
            didRequirePositiveColorAttachmentEnvelopeBeforeEncoder
        this.didRequireBoundedIsolatedRenderCommandEncoderProbe =
            didRequireBoundedIsolatedRenderCommandEncoderProbe
        this.didRequireProbeLocalCommandQueue = didRequireProbeLocalCommandQueue
        this.didRequireProbeLocalCommandBuffer = didRequireProbeLocalCommandBuffer
        this.didRequireProbeLocalRenderPassDescriptorInput =
            didRequireProbeLocalRenderPassDescriptorInput
        this.didRequireProbeLocalRenderCommandEncoder =
            didRequireProbeLocalRenderCommandEncoder
        this.didRequireEndEncodingBeforeCleanup =
            didRequireEndEncodingBeforeCleanup
        this.didRequireDescriptorDrawableLayerDeviceCleanupCoownership =
            didRequireDescriptorDrawableLayerDeviceCleanupCoownership
        this.didKeepProductionEncoderBridgeBlocked =
            didKeepProductionEncoderBridgeBlocked
        this.didKeepPipelineVertexDrawCommitPresentGpuRenderBlocked =
            didKeepPipelineVertexDrawCommitPresentGpuRenderBlocked
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceReadiness {
    let colorAttachmentConfigurationFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceReadiness
    let encoderNoSubmitPlanningReadiness:
        CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness
    let encoderFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceFacts
    let didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceReadiness:
        Bool
    let shouldConsumeColorAttachmentConfigurationFirstSliceReadiness: Bool
    let shouldConsumeRenderCommandEncoderNoSubmitPlanningReadiness: Bool
    let shouldRequirePositiveColorAttachmentEnvelopeBeforeEncoder: Bool
    let shouldRequireBoundedIsolatedRenderCommandEncoderProbe: Bool
    let shouldRequireProbeLocalCommandQueue: Bool
    let shouldRequireProbeLocalCommandBuffer: Bool
    let shouldRequireProbeLocalRenderPassDescriptorInput: Bool
    let shouldRequireProbeLocalRenderCommandEncoder: Bool
    let shouldRequireEndEncodingBeforeCleanup: Bool
    let shouldKeepProductionEncoderBridgeBlocked: Bool
    let shouldKeepPipelineVertexDrawCommitPresentGpuRenderBlocked: Bool
    let shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool
    let shouldKeepRendererStateWriteBlocked: Bool
    let didConfirmColorAttachmentConfigurationInput: Bool
    let didConfirmNoSubmitPlanningInput: Bool
    let didConfirmRenderCommandEncoderFirstSliceOrdering: Bool
    let didConfirmRenderCommandEncoderFirstSliceStopLine: Bool
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
        colorAttachmentConfigurationFirstSliceReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceReadiness,
        encoderNoSubmitPlanningReadiness:
            CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness,
        encoderFirstSliceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceFacts,
        didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceReadiness:
            Bool,
        shouldConsumeColorAttachmentConfigurationFirstSliceReadiness: Bool,
        shouldConsumeRenderCommandEncoderNoSubmitPlanningReadiness: Bool,
        shouldRequirePositiveColorAttachmentEnvelopeBeforeEncoder: Bool,
        shouldRequireBoundedIsolatedRenderCommandEncoderProbe: Bool,
        shouldRequireProbeLocalCommandQueue: Bool,
        shouldRequireProbeLocalCommandBuffer: Bool,
        shouldRequireProbeLocalRenderPassDescriptorInput: Bool,
        shouldRequireProbeLocalRenderCommandEncoder: Bool,
        shouldRequireEndEncodingBeforeCleanup: Bool,
        shouldKeepProductionEncoderBridgeBlocked: Bool,
        shouldKeepPipelineVertexDrawCommitPresentGpuRenderBlocked: Bool,
        shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool,
        shouldKeepRendererStateWriteBlocked: Bool,
        didConfirmColorAttachmentConfigurationInput: Bool,
        didConfirmNoSubmitPlanningInput: Bool,
        didConfirmRenderCommandEncoderFirstSliceOrdering: Bool,
        didConfirmRenderCommandEncoderFirstSliceStopLine: Bool,
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
        this.colorAttachmentConfigurationFirstSliceReadiness =
            colorAttachmentConfigurationFirstSliceReadiness
        this.encoderNoSubmitPlanningReadiness =
            encoderNoSubmitPlanningReadiness
        this.encoderFirstSliceFacts =
            encoderFirstSliceFacts
        this.didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceReadiness =
            didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceReadiness
        this.shouldConsumeColorAttachmentConfigurationFirstSliceReadiness =
            shouldConsumeColorAttachmentConfigurationFirstSliceReadiness
        this.shouldConsumeRenderCommandEncoderNoSubmitPlanningReadiness =
            shouldConsumeRenderCommandEncoderNoSubmitPlanningReadiness
        this.shouldRequirePositiveColorAttachmentEnvelopeBeforeEncoder =
            shouldRequirePositiveColorAttachmentEnvelopeBeforeEncoder
        this.shouldRequireBoundedIsolatedRenderCommandEncoderProbe =
            shouldRequireBoundedIsolatedRenderCommandEncoderProbe
        this.shouldRequireProbeLocalCommandQueue =
            shouldRequireProbeLocalCommandQueue
        this.shouldRequireProbeLocalCommandBuffer =
            shouldRequireProbeLocalCommandBuffer
        this.shouldRequireProbeLocalRenderPassDescriptorInput =
            shouldRequireProbeLocalRenderPassDescriptorInput
        this.shouldRequireProbeLocalRenderCommandEncoder =
            shouldRequireProbeLocalRenderCommandEncoder
        this.shouldRequireEndEncodingBeforeCleanup =
            shouldRequireEndEncodingBeforeCleanup
        this.shouldKeepProductionEncoderBridgeBlocked =
            shouldKeepProductionEncoderBridgeBlocked
        this.shouldKeepPipelineVertexDrawCommitPresentGpuRenderBlocked =
            shouldKeepPipelineVertexDrawCommitPresentGpuRenderBlocked
        this.shouldRequireProductionWriteAdmissionBeforeRendererStateWrite =
            shouldRequireProductionWriteAdmissionBeforeRendererStateWrite
        this.shouldKeepRendererStateWriteBlocked =
            shouldKeepRendererStateWriteBlocked
        this.didConfirmColorAttachmentConfigurationInput =
            didConfirmColorAttachmentConfigurationInput
        this.didConfirmNoSubmitPlanningInput = didConfirmNoSubmitPlanningInput
        this.didConfirmRenderCommandEncoderFirstSliceOrdering =
            didConfirmRenderCommandEncoderFirstSliceOrdering
        this.didConfirmRenderCommandEncoderFirstSliceStopLine =
            didConfirmRenderCommandEncoderFirstSliceStopLine
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

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceFacts(
    colorAttachmentConfigurationFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceReadiness,
    encoderNoSubmitPlanningReadiness:
        CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceFacts(
        colorAttachmentConfigurationFirstSliceReadiness
            .didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceReadiness,
        encoderNoSubmitPlanningReadiness
            .didPrepareRendererNoRenderCommandEncoderNoSubmitPlanningReadiness,
        colorAttachmentConfigurationFirstSliceReadiness
            .shouldRequirePositiveDrawableTextureEnvelopeBeforeConfiguration,
        true,
        true,
        true,
        colorAttachmentConfigurationFirstSliceReadiness
            .shouldRequireProbeLocalRenderPassDescriptor,
        true,
        true,
        colorAttachmentConfigurationFirstSliceReadiness
            .shouldRequireDescriptorDrawableLayerDeviceCleanupCoownership,
        encoderNoSubmitPlanningReadiness
            .didConfirmEncoderCreationStillBlocked,
        colorAttachmentConfigurationFirstSliceReadiness
            .shouldKeepDrawCommitPresentGpuRenderBlocked &&
            encoderNoSubmitPlanningReadiness
                .didConfirmNoDrawCommitPresentGpuOrRender,
        colorAttachmentConfigurationFirstSliceReadiness
            .shouldRequireProductionWriteAdmissionBeforeRendererStateWrite,
        colorAttachmentConfigurationFirstSliceReadiness
            .shouldKeepRendererStateWriteBlocked,
        colorAttachmentConfigurationFirstSliceReadiness
            .didConfirmNoProductionTruthUpgrade,
        colorAttachmentConfigurationFirstSliceReadiness.didConfirmNoBackendReadyTruth &&
            encoderNoSubmitPlanningReadiness
                .didConfirmNoBackendReadyTruth,
        colorAttachmentConfigurationFirstSliceReadiness
            .didConfirmNoProductionNativeBridgeExpansion,
        colorAttachmentConfigurationFirstSliceReadiness.didConfirmNoPublicApi &&
            encoderNoSubmitPlanningReadiness.didConfirmNoPublicSurface,
        colorAttachmentConfigurationFirstSliceReadiness
            .didConfirmNoProductionPublicCAbi,
        colorAttachmentConfigurationFirstSliceReadiness.didConfirmNoRuntimeStateWrite,
        colorAttachmentConfigurationFirstSliceReadiness.didConfirmNoCjpmTomlChange,
        colorAttachmentConfigurationFirstSliceReadiness.didConfirmNoRendererStateWrite &&
            encoderNoSubmitPlanningReadiness
                .didConfirmNoRendererStateWrite,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceReadiness(
    colorAttachmentConfigurationFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceReadiness,
    encoderNoSubmitPlanningReadiness:
        CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness,
    encoderFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceReadiness {
    let colorAttachmentInputReady =
        encoderFirstSliceFacts
            .didConsumeColorAttachmentConfigurationFirstSliceReadiness &&
        colorAttachmentConfigurationFirstSliceReadiness
            .didConfirmColorAttachmentConfigurationOrdering &&
        colorAttachmentConfigurationFirstSliceReadiness
            .didConfirmColorAttachmentConfigurationStopLine
    let noSubmitPlanningInputReady =
        encoderFirstSliceFacts
            .didConsumeRenderCommandEncoderNoSubmitPlanningReadiness &&
        encoderNoSubmitPlanningReadiness
            .didConfirmEncoderCreationStillBlocked &&
        encoderNoSubmitPlanningReadiness
            .didConfirmDrawStillBlocked &&
        encoderNoSubmitPlanningReadiness
            .didConfirmNoDrawCommitPresentGpuOrRender
    let orderingReady =
        encoderFirstSliceFacts
            .didRequirePositiveColorAttachmentEnvelopeBeforeEncoder &&
        encoderFirstSliceFacts
            .didRequireBoundedIsolatedRenderCommandEncoderProbe &&
        encoderFirstSliceFacts.didRequireProbeLocalCommandQueue &&
        encoderFirstSliceFacts.didRequireProbeLocalCommandBuffer &&
        encoderFirstSliceFacts
            .didRequireProbeLocalRenderPassDescriptorInput &&
        encoderFirstSliceFacts
            .didRequireProbeLocalRenderCommandEncoder &&
        encoderFirstSliceFacts.didRequireEndEncodingBeforeCleanup &&
        encoderFirstSliceFacts
            .didRequireDescriptorDrawableLayerDeviceCleanupCoownership
    let stopLineReady =
        encoderFirstSliceFacts
            .didKeepProductionEncoderBridgeBlocked &&
        encoderFirstSliceFacts
            .didKeepPipelineVertexDrawCommitPresentGpuRenderBlocked &&
        encoderFirstSliceFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite &&
        encoderFirstSliceFacts.didKeepRendererStateWriteBlocked &&
        encoderFirstSliceFacts.didConfirmNoProductionTruthUpgrade &&
        encoderFirstSliceFacts.didConfirmNoBackendReadyTruth &&
        encoderFirstSliceFacts
            .didConfirmNoProductionNativeBridgeExpansion &&
        encoderFirstSliceFacts.didConfirmNoPublicApi &&
        encoderFirstSliceFacts.didConfirmNoProductionPublicCAbi &&
        encoderFirstSliceFacts.didConfirmNoRuntimeStateWrite &&
        encoderFirstSliceFacts.didConfirmNoCjpmTomlChange &&
        encoderFirstSliceFacts.didConfirmNoRendererStateWrite &&
        encoderFirstSliceFacts
            .didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    let readinessReady =
        colorAttachmentInputReady &&
        noSubmitPlanningInputReady &&
        orderingReady &&
        stopLineReady

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceReadiness(
        colorAttachmentConfigurationFirstSliceReadiness,
        encoderNoSubmitPlanningReadiness,
        encoderFirstSliceFacts,
        readinessReady,
        encoderFirstSliceFacts
            .didConsumeColorAttachmentConfigurationFirstSliceReadiness,
        encoderFirstSliceFacts
            .didConsumeRenderCommandEncoderNoSubmitPlanningReadiness,
        encoderFirstSliceFacts
            .didRequirePositiveColorAttachmentEnvelopeBeforeEncoder,
        encoderFirstSliceFacts
            .didRequireBoundedIsolatedRenderCommandEncoderProbe,
        encoderFirstSliceFacts.didRequireProbeLocalCommandQueue,
        encoderFirstSliceFacts.didRequireProbeLocalCommandBuffer,
        encoderFirstSliceFacts
            .didRequireProbeLocalRenderPassDescriptorInput,
        encoderFirstSliceFacts
            .didRequireProbeLocalRenderCommandEncoder,
        encoderFirstSliceFacts.didRequireEndEncodingBeforeCleanup,
        encoderFirstSliceFacts.didKeepProductionEncoderBridgeBlocked,
        encoderFirstSliceFacts
            .didKeepPipelineVertexDrawCommitPresentGpuRenderBlocked,
        encoderFirstSliceFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite,
        encoderFirstSliceFacts.didKeepRendererStateWriteBlocked,
        colorAttachmentInputReady,
        noSubmitPlanningInputReady,
        orderingReady,
        stopLineReady,
        encoderFirstSliceFacts.didConfirmNoProductionTruthUpgrade,
        encoderFirstSliceFacts.didConfirmNoBackendReadyTruth,
        encoderFirstSliceFacts
            .didConfirmNoProductionNativeBridgeExpansion,
        encoderFirstSliceFacts.didConfirmNoPublicApi,
        encoderFirstSliceFacts.didConfirmNoProductionPublicCAbi,
        encoderFirstSliceFacts.didConfirmNoRuntimeStateWrite,
        encoderFirstSliceFacts.didConfirmNoCjpmTomlChange,
        encoderFirstSliceFacts.didConfirmNoRendererStateWrite,
        encoderFirstSliceFacts
            .didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceReadiness {
    let colorAttachmentConfigurationFirstSliceReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceDraft()
    let encoderNoSubmitPlanningReadiness =
        cjguiInternalExecuteDefaultRendererRenderCommandEncoderNoSubmitPlanningDraft()
    let encoderFirstSliceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceFacts(
            colorAttachmentConfigurationFirstSliceReadiness,
            encoderNoSubmitPlanningReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceReadiness(
        colorAttachmentConfigurationFirstSliceReadiness,
        encoderNoSubmitPlanningReadiness,
        encoderFirstSliceFacts
    )
}
