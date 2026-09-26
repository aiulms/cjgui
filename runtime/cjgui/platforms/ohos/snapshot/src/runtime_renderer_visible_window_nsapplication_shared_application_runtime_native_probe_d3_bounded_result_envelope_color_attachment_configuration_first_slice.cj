// 中文维护注释：本文件是 visible-window runtime native probe 的
// render-pass color attachment configuration first-slice readiness owner。
// Owner: runtime renderer internal color attachment configuration first slice。
// Truth: 消费 stage108 drawable texture lifetime first-slice readiness 与
// 既有 color attachment recovery readiness，把下一步收敛为 bounded isolated
// probe-local render pass descriptor colorAttachments[0].texture 绑定合约。
// 它不创建 encoder，不 draw / commit / present，不提交 GPU work，不写
// renderer state，不把 isolated evidence 升级为 production truth，也不扩
// production native bridge C ABI。
// Stop-line: production bridge 仍不暴露 color attachment 配置 callable；
// 本 owner 只描述 bounded isolated probe 的输入、输出和清理边界。
// Same-shape Boundary Brake: 本 owner 必须表达 color attachment configuration
// first-slice contract；不得退化成 approval、external packet、report wrapper
// 或 generic recovery 包装。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceFacts {
    let didConsumeDrawableTextureLifetimeFirstSliceReadiness: Bool
    let didConsumeColorAttachmentRecoveryReadiness: Bool
    let didRequirePositiveDrawableTextureEnvelopeBeforeConfiguration: Bool
    let didRequireBoundedIsolatedColorAttachmentConfigurationProbe: Bool
    let didRequireProbeLocalRenderPassDescriptor: Bool
    let didRequireProbeLocalDrawableTextureBinding: Bool
    let didRequireAttachmentLoadStoreClearFacts: Bool
    let didRequireDescriptorDrawableLayerDeviceCleanupCoownership: Bool
    let didKeepEncoderCreationBlockedAfterColorAttachment: Bool
    let didKeepDrawCommitPresentGpuRenderBlocked: Bool
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
    let didAvoidApprovalExternalPacketOrReportWrapper: Bool

    init(
        didConsumeDrawableTextureLifetimeFirstSliceReadiness: Bool,
        didConsumeColorAttachmentRecoveryReadiness: Bool,
        didRequirePositiveDrawableTextureEnvelopeBeforeConfiguration: Bool,
        didRequireBoundedIsolatedColorAttachmentConfigurationProbe: Bool,
        didRequireProbeLocalRenderPassDescriptor: Bool,
        didRequireProbeLocalDrawableTextureBinding: Bool,
        didRequireAttachmentLoadStoreClearFacts: Bool,
        didRequireDescriptorDrawableLayerDeviceCleanupCoownership: Bool,
        didKeepEncoderCreationBlockedAfterColorAttachment: Bool,
        didKeepDrawCommitPresentGpuRenderBlocked: Bool,
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
        didAvoidApprovalExternalPacketOrReportWrapper: Bool
    ) {
        this.didConsumeDrawableTextureLifetimeFirstSliceReadiness =
            didConsumeDrawableTextureLifetimeFirstSliceReadiness
        this.didConsumeColorAttachmentRecoveryReadiness =
            didConsumeColorAttachmentRecoveryReadiness
        this.didRequirePositiveDrawableTextureEnvelopeBeforeConfiguration =
            didRequirePositiveDrawableTextureEnvelopeBeforeConfiguration
        this.didRequireBoundedIsolatedColorAttachmentConfigurationProbe =
            didRequireBoundedIsolatedColorAttachmentConfigurationProbe
        this.didRequireProbeLocalRenderPassDescriptor =
            didRequireProbeLocalRenderPassDescriptor
        this.didRequireProbeLocalDrawableTextureBinding =
            didRequireProbeLocalDrawableTextureBinding
        this.didRequireAttachmentLoadStoreClearFacts =
            didRequireAttachmentLoadStoreClearFacts
        this.didRequireDescriptorDrawableLayerDeviceCleanupCoownership =
            didRequireDescriptorDrawableLayerDeviceCleanupCoownership
        this.didKeepEncoderCreationBlockedAfterColorAttachment =
            didKeepEncoderCreationBlockedAfterColorAttachment
        this.didKeepDrawCommitPresentGpuRenderBlocked =
            didKeepDrawCommitPresentGpuRenderBlocked
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
        this.didAvoidApprovalExternalPacketOrReportWrapper =
            didAvoidApprovalExternalPacketOrReportWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceReadiness {
    let drawableTextureLifetimeFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceReadiness
    let colorAttachmentRecoveryReadiness:
        CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness
    let colorAttachmentConfigurationFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceFacts
    let didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceReadiness:
        Bool
    let shouldConsumeDrawableTextureLifetimeFirstSliceReadiness: Bool
    let shouldConsumeColorAttachmentRecoveryReadiness: Bool
    let shouldRequirePositiveDrawableTextureEnvelopeBeforeConfiguration: Bool
    let shouldRequireBoundedIsolatedColorAttachmentConfigurationProbe: Bool
    let shouldRequireProbeLocalRenderPassDescriptor: Bool
    let shouldRequireProbeLocalDrawableTextureBinding: Bool
    let shouldRequireAttachmentLoadStoreClearFacts: Bool
    let shouldRequireDescriptorDrawableLayerDeviceCleanupCoownership: Bool
    let shouldKeepEncoderCreationBlockedAfterColorAttachment: Bool
    let shouldKeepDrawCommitPresentGpuRenderBlocked: Bool
    let shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool
    let shouldKeepRendererStateWriteBlocked: Bool
    let didConfirmDrawableTextureLifetimeInput: Bool
    let didConfirmColorAttachmentRecoveryInput: Bool
    let didConfirmColorAttachmentConfigurationOrdering: Bool
    let didConfirmColorAttachmentConfigurationStopLine: Bool
    let didConfirmNoProductionTruthUpgrade: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didConfirmNoProductionNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didAvoidApprovalExternalPacketOrReportWrapper: Bool

    init(
        drawableTextureLifetimeFirstSliceReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceReadiness,
        colorAttachmentRecoveryReadiness:
            CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness,
        colorAttachmentConfigurationFirstSliceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceFacts,
        didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceReadiness:
            Bool,
        shouldConsumeDrawableTextureLifetimeFirstSliceReadiness: Bool,
        shouldConsumeColorAttachmentRecoveryReadiness: Bool,
        shouldRequirePositiveDrawableTextureEnvelopeBeforeConfiguration: Bool,
        shouldRequireBoundedIsolatedColorAttachmentConfigurationProbe: Bool,
        shouldRequireProbeLocalRenderPassDescriptor: Bool,
        shouldRequireProbeLocalDrawableTextureBinding: Bool,
        shouldRequireAttachmentLoadStoreClearFacts: Bool,
        shouldRequireDescriptorDrawableLayerDeviceCleanupCoownership: Bool,
        shouldKeepEncoderCreationBlockedAfterColorAttachment: Bool,
        shouldKeepDrawCommitPresentGpuRenderBlocked: Bool,
        shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool,
        shouldKeepRendererStateWriteBlocked: Bool,
        didConfirmDrawableTextureLifetimeInput: Bool,
        didConfirmColorAttachmentRecoveryInput: Bool,
        didConfirmColorAttachmentConfigurationOrdering: Bool,
        didConfirmColorAttachmentConfigurationStopLine: Bool,
        didConfirmNoProductionTruthUpgrade: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didConfirmNoProductionNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didAvoidApprovalExternalPacketOrReportWrapper: Bool
    ) {
        this.drawableTextureLifetimeFirstSliceReadiness =
            drawableTextureLifetimeFirstSliceReadiness
        this.colorAttachmentRecoveryReadiness = colorAttachmentRecoveryReadiness
        this.colorAttachmentConfigurationFirstSliceFacts =
            colorAttachmentConfigurationFirstSliceFacts
        this.didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceReadiness =
            didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceReadiness
        this.shouldConsumeDrawableTextureLifetimeFirstSliceReadiness =
            shouldConsumeDrawableTextureLifetimeFirstSliceReadiness
        this.shouldConsumeColorAttachmentRecoveryReadiness =
            shouldConsumeColorAttachmentRecoveryReadiness
        this.shouldRequirePositiveDrawableTextureEnvelopeBeforeConfiguration =
            shouldRequirePositiveDrawableTextureEnvelopeBeforeConfiguration
        this.shouldRequireBoundedIsolatedColorAttachmentConfigurationProbe =
            shouldRequireBoundedIsolatedColorAttachmentConfigurationProbe
        this.shouldRequireProbeLocalRenderPassDescriptor =
            shouldRequireProbeLocalRenderPassDescriptor
        this.shouldRequireProbeLocalDrawableTextureBinding =
            shouldRequireProbeLocalDrawableTextureBinding
        this.shouldRequireAttachmentLoadStoreClearFacts =
            shouldRequireAttachmentLoadStoreClearFacts
        this.shouldRequireDescriptorDrawableLayerDeviceCleanupCoownership =
            shouldRequireDescriptorDrawableLayerDeviceCleanupCoownership
        this.shouldKeepEncoderCreationBlockedAfterColorAttachment =
            shouldKeepEncoderCreationBlockedAfterColorAttachment
        this.shouldKeepDrawCommitPresentGpuRenderBlocked =
            shouldKeepDrawCommitPresentGpuRenderBlocked
        this.shouldRequireProductionWriteAdmissionBeforeRendererStateWrite =
            shouldRequireProductionWriteAdmissionBeforeRendererStateWrite
        this.shouldKeepRendererStateWriteBlocked =
            shouldKeepRendererStateWriteBlocked
        this.didConfirmDrawableTextureLifetimeInput =
            didConfirmDrawableTextureLifetimeInput
        this.didConfirmColorAttachmentRecoveryInput =
            didConfirmColorAttachmentRecoveryInput
        this.didConfirmColorAttachmentConfigurationOrdering =
            didConfirmColorAttachmentConfigurationOrdering
        this.didConfirmColorAttachmentConfigurationStopLine =
            didConfirmColorAttachmentConfigurationStopLine
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
        this.didAvoidApprovalExternalPacketOrReportWrapper =
            didAvoidApprovalExternalPacketOrReportWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceFacts(
    drawableTextureLifetimeFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceReadiness,
    colorAttachmentRecoveryReadiness:
        CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceFacts(
        drawableTextureLifetimeFirstSliceReadiness
            .didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceReadiness,
        colorAttachmentRecoveryReadiness
            .didPrepareRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness,
        drawableTextureLifetimeFirstSliceReadiness
            .shouldRequireDrawableTextureObservationBeforeColorAttachment,
        true,
        true,
        true,
        true,
        drawableTextureLifetimeFirstSliceReadiness
            .shouldRequireDescriptorDrawableLayerDeviceCleanupCoownership &&
            colorAttachmentRecoveryReadiness
                .didConfirmDescriptorDrawableLayerDeviceCleanupStillUnproven,
        true,
        drawableTextureLifetimeFirstSliceReadiness
            .shouldKeepEncoderDrawCommitPresentGpuRenderBlocked &&
            colorAttachmentRecoveryReadiness
                .didConfirmNoEncoderDrawCommitPresentGpuOrRender,
        drawableTextureLifetimeFirstSliceReadiness
            .shouldRequireProductionWriteAdmissionBeforeRendererStateWrite,
        drawableTextureLifetimeFirstSliceReadiness.shouldKeepRendererStateWriteBlocked,
        drawableTextureLifetimeFirstSliceReadiness
            .didConfirmNoProductionTruthUpgrade,
        drawableTextureLifetimeFirstSliceReadiness.didConfirmNoBackendReadyTruth &&
            colorAttachmentRecoveryReadiness.didConfirmNoBackendReadyTruth,
        true,
        drawableTextureLifetimeFirstSliceReadiness.didConfirmNoPublicApi &&
            colorAttachmentRecoveryReadiness.didConfirmNoPublicSurface,
        true,
        drawableTextureLifetimeFirstSliceReadiness.didConfirmNoRuntimeStateWrite,
        drawableTextureLifetimeFirstSliceReadiness.didConfirmNoCjpmTomlChange,
        drawableTextureLifetimeFirstSliceReadiness.didConfirmNoRendererStateWrite &&
            colorAttachmentRecoveryReadiness.didConfirmNoRendererStateWrite,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceReadiness(
    drawableTextureLifetimeFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceReadiness,
    colorAttachmentRecoveryReadiness:
        CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness,
    colorAttachmentConfigurationFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceReadiness {
    let drawableTextureInputReady =
        colorAttachmentConfigurationFirstSliceFacts
            .didConsumeDrawableTextureLifetimeFirstSliceReadiness &&
        drawableTextureLifetimeFirstSliceReadiness
            .didConfirmDrawableTextureLifetimeFirstSliceOrdering &&
        drawableTextureLifetimeFirstSliceReadiness
            .didConfirmDrawableTextureLifetimeFirstSliceStopLine
    let recoveryInputReady =
        colorAttachmentConfigurationFirstSliceFacts
            .didConsumeColorAttachmentRecoveryReadiness &&
        colorAttachmentRecoveryReadiness
            .didConfirmDrawableTextureLifetimeSupportRequired &&
        colorAttachmentRecoveryReadiness.didConfirmColorAttachmentFirstSliceStillBlocked &&
        colorAttachmentRecoveryReadiness.didConfirmEncoderCreationStillBlocked
    let orderingReady =
        colorAttachmentConfigurationFirstSliceFacts
            .didRequirePositiveDrawableTextureEnvelopeBeforeConfiguration &&
        colorAttachmentConfigurationFirstSliceFacts
            .didRequireBoundedIsolatedColorAttachmentConfigurationProbe &&
        colorAttachmentConfigurationFirstSliceFacts
            .didRequireProbeLocalRenderPassDescriptor &&
        colorAttachmentConfigurationFirstSliceFacts
            .didRequireProbeLocalDrawableTextureBinding &&
        colorAttachmentConfigurationFirstSliceFacts
            .didRequireAttachmentLoadStoreClearFacts &&
        colorAttachmentConfigurationFirstSliceFacts
            .didRequireDescriptorDrawableLayerDeviceCleanupCoownership
    let stopLineReady =
        colorAttachmentConfigurationFirstSliceFacts
            .didKeepEncoderCreationBlockedAfterColorAttachment &&
        colorAttachmentConfigurationFirstSliceFacts
            .didKeepDrawCommitPresentGpuRenderBlocked &&
        colorAttachmentConfigurationFirstSliceFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite &&
        colorAttachmentConfigurationFirstSliceFacts.didKeepRendererStateWriteBlocked &&
        colorAttachmentConfigurationFirstSliceFacts
            .didConfirmNoProductionTruthUpgrade &&
        colorAttachmentConfigurationFirstSliceFacts.didConfirmNoBackendReadyTruth &&
        colorAttachmentConfigurationFirstSliceFacts
            .didConfirmNoProductionNativeBridgeExpansion &&
        colorAttachmentConfigurationFirstSliceFacts.didConfirmNoPublicApi &&
        colorAttachmentConfigurationFirstSliceFacts
            .didConfirmNoProductionPublicCAbi &&
        colorAttachmentConfigurationFirstSliceFacts.didConfirmNoRuntimeStateWrite &&
        colorAttachmentConfigurationFirstSliceFacts.didConfirmNoCjpmTomlChange &&
        colorAttachmentConfigurationFirstSliceFacts.didConfirmNoRendererStateWrite &&
        colorAttachmentConfigurationFirstSliceFacts
            .didAvoidApprovalExternalPacketOrReportWrapper
    let readinessReady =
        drawableTextureInputReady &&
        recoveryInputReady &&
        orderingReady &&
        stopLineReady

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceReadiness(
        drawableTextureLifetimeFirstSliceReadiness,
        colorAttachmentRecoveryReadiness,
        colorAttachmentConfigurationFirstSliceFacts,
        readinessReady,
        colorAttachmentConfigurationFirstSliceFacts
            .didConsumeDrawableTextureLifetimeFirstSliceReadiness,
        colorAttachmentConfigurationFirstSliceFacts
            .didConsumeColorAttachmentRecoveryReadiness,
        colorAttachmentConfigurationFirstSliceFacts
            .didRequirePositiveDrawableTextureEnvelopeBeforeConfiguration,
        colorAttachmentConfigurationFirstSliceFacts
            .didRequireBoundedIsolatedColorAttachmentConfigurationProbe,
        colorAttachmentConfigurationFirstSliceFacts
            .didRequireProbeLocalRenderPassDescriptor,
        colorAttachmentConfigurationFirstSliceFacts
            .didRequireProbeLocalDrawableTextureBinding,
        colorAttachmentConfigurationFirstSliceFacts
            .didRequireAttachmentLoadStoreClearFacts,
        colorAttachmentConfigurationFirstSliceFacts
            .didRequireDescriptorDrawableLayerDeviceCleanupCoownership,
        colorAttachmentConfigurationFirstSliceFacts
            .didKeepEncoderCreationBlockedAfterColorAttachment,
        colorAttachmentConfigurationFirstSliceFacts
            .didKeepDrawCommitPresentGpuRenderBlocked,
        colorAttachmentConfigurationFirstSliceFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite,
        colorAttachmentConfigurationFirstSliceFacts.didKeepRendererStateWriteBlocked,
        drawableTextureInputReady,
        recoveryInputReady,
        orderingReady,
        stopLineReady,
        colorAttachmentConfigurationFirstSliceFacts
            .didConfirmNoProductionTruthUpgrade,
        colorAttachmentConfigurationFirstSliceFacts.didConfirmNoBackendReadyTruth,
        colorAttachmentConfigurationFirstSliceFacts
            .didConfirmNoProductionNativeBridgeExpansion,
        colorAttachmentConfigurationFirstSliceFacts.didConfirmNoPublicApi,
        colorAttachmentConfigurationFirstSliceFacts
            .didConfirmNoProductionPublicCAbi,
        colorAttachmentConfigurationFirstSliceFacts.didConfirmNoRuntimeStateWrite,
        colorAttachmentConfigurationFirstSliceFacts.didConfirmNoCjpmTomlChange,
        colorAttachmentConfigurationFirstSliceFacts.didConfirmNoRendererStateWrite,
        colorAttachmentConfigurationFirstSliceFacts
            .didAvoidApprovalExternalPacketOrReportWrapper
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceReadiness {
    let drawableTextureLifetimeFirstSliceReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceDraft()
    let colorAttachmentRecoveryReadiness =
        cjguiInternalExecuteDefaultRendererRenderPassDescriptorColorAttachmentRecoveryDraft()
    let colorAttachmentConfigurationFirstSliceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceFacts(
            drawableTextureLifetimeFirstSliceReadiness,
            colorAttachmentRecoveryReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeColorAttachmentConfigurationFirstSliceReadiness(
        drawableTextureLifetimeFirstSliceReadiness,
        colorAttachmentRecoveryReadiness,
        colorAttachmentConfigurationFirstSliceFacts
    )
}
