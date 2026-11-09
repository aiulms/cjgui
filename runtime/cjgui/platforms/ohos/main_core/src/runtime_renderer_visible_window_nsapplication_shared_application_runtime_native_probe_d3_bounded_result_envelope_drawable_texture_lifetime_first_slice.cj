// 中文维护注释：本文件是 visible-window runtime native probe 的
// drawable texture lifetime first-slice readiness owner。
// Owner: runtime renderer internal drawable texture lifetime first slice。
// Truth: 消费 stage107 drawable / render-pass color attachment readiness 与
// 既有 drawable texture lifetime planning readiness，把下一步收敛为
// bounded isolated probe-local drawable token / texture observation contract。
// 它不配置 color attachment，不创建 encoder，不 draw / commit / present，
// 不提交 GPU work，不写 renderer state，不把 isolated evidence 升级为
// production truth，也不扩 production native bridge C ABI。
// Stop-line: production bridge 仍不调用 nextDrawable；本 owner 只描述
// bounded isolated probe 的输入、输出和清理边界。
// Same-shape Boundary Brake: 本 owner 必须表达 drawable texture lifetime
// first-slice contract；不得退化成 approval、external packet、report wrapper
// 或 generic recovery 包装。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceFacts {
    let didConsumeDrawableRenderPassColorAttachmentReadiness: Bool
    let didConsumeDrawableTextureLifetimePlanningReadiness: Bool
    let didRequireFirstSliceAdmissionBeforeDrawableAcquisition: Bool
    let didRequireBoundedIsolatedDrawableAcquisitionProbe: Bool
    let didRequireProbeLocalDrawableTokenLifetime: Bool
    let didRequireDrawableTextureObservationBeforeColorAttachment: Bool
    let didRequireDescriptorDrawableLayerDeviceCleanupCoownership: Bool
    let didKeepColorAttachmentConfigurationBlocked: Bool
    let didKeepEncoderDrawCommitPresentGpuRenderBlocked: Bool
    let didKeepDrawableTextureFirstSliceCurrentShellBounded: Bool
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
        didConsumeDrawableRenderPassColorAttachmentReadiness: Bool,
        didConsumeDrawableTextureLifetimePlanningReadiness: Bool,
        didRequireFirstSliceAdmissionBeforeDrawableAcquisition: Bool,
        didRequireBoundedIsolatedDrawableAcquisitionProbe: Bool,
        didRequireProbeLocalDrawableTokenLifetime: Bool,
        didRequireDrawableTextureObservationBeforeColorAttachment: Bool,
        didRequireDescriptorDrawableLayerDeviceCleanupCoownership: Bool,
        didKeepColorAttachmentConfigurationBlocked: Bool,
        didKeepEncoderDrawCommitPresentGpuRenderBlocked: Bool,
        didKeepDrawableTextureFirstSliceCurrentShellBounded: Bool,
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
        this.didConsumeDrawableRenderPassColorAttachmentReadiness =
            didConsumeDrawableRenderPassColorAttachmentReadiness
        this.didConsumeDrawableTextureLifetimePlanningReadiness =
            didConsumeDrawableTextureLifetimePlanningReadiness
        this.didRequireFirstSliceAdmissionBeforeDrawableAcquisition =
            didRequireFirstSliceAdmissionBeforeDrawableAcquisition
        this.didRequireBoundedIsolatedDrawableAcquisitionProbe =
            didRequireBoundedIsolatedDrawableAcquisitionProbe
        this.didRequireProbeLocalDrawableTokenLifetime =
            didRequireProbeLocalDrawableTokenLifetime
        this.didRequireDrawableTextureObservationBeforeColorAttachment =
            didRequireDrawableTextureObservationBeforeColorAttachment
        this.didRequireDescriptorDrawableLayerDeviceCleanupCoownership =
            didRequireDescriptorDrawableLayerDeviceCleanupCoownership
        this.didKeepColorAttachmentConfigurationBlocked =
            didKeepColorAttachmentConfigurationBlocked
        this.didKeepEncoderDrawCommitPresentGpuRenderBlocked =
            didKeepEncoderDrawCommitPresentGpuRenderBlocked
        this.didKeepDrawableTextureFirstSliceCurrentShellBounded =
            didKeepDrawableTextureFirstSliceCurrentShellBounded
        this.didRequireProductionWriteAdmissionBeforeRendererStateWrite =
            didRequireProductionWriteAdmissionBeforeRendererStateWrite
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceReadiness {
    let drawableRenderPassColorAttachmentReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentReadiness
    let drawableTextureLifetimePlanningReadiness:
        CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness
    let drawableTextureLifetimeFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceFacts
    let didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceReadiness:
        Bool
    let shouldConsumeDrawableRenderPassColorAttachmentReadiness: Bool
    let shouldConsumeDrawableTextureLifetimePlanningReadiness: Bool
    let shouldRequireFirstSliceAdmissionBeforeDrawableAcquisition: Bool
    let shouldRequireBoundedIsolatedDrawableAcquisitionProbe: Bool
    let shouldRequireProbeLocalDrawableTokenLifetime: Bool
    let shouldRequireDrawableTextureObservationBeforeColorAttachment: Bool
    let shouldRequireDescriptorDrawableLayerDeviceCleanupCoownership: Bool
    let shouldKeepColorAttachmentConfigurationBlocked: Bool
    let shouldKeepEncoderDrawCommitPresentGpuRenderBlocked: Bool
    let shouldKeepDrawableTextureFirstSliceCurrentShellBounded: Bool
    let shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool
    let shouldKeepRendererStateWriteBlocked: Bool
    let didConfirmDrawableRenderPassColorAttachmentInput: Bool
    let didConfirmDrawableTextureLifetimePlanningInput: Bool
    let didConfirmDrawableTextureLifetimeFirstSliceOrdering: Bool
    let didConfirmDrawableTextureLifetimeFirstSliceStopLine: Bool
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
        drawableRenderPassColorAttachmentReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentReadiness,
        drawableTextureLifetimePlanningReadiness:
            CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness,
        drawableTextureLifetimeFirstSliceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceFacts,
        didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceReadiness:
            Bool,
        shouldConsumeDrawableRenderPassColorAttachmentReadiness: Bool,
        shouldConsumeDrawableTextureLifetimePlanningReadiness: Bool,
        shouldRequireFirstSliceAdmissionBeforeDrawableAcquisition: Bool,
        shouldRequireBoundedIsolatedDrawableAcquisitionProbe: Bool,
        shouldRequireProbeLocalDrawableTokenLifetime: Bool,
        shouldRequireDrawableTextureObservationBeforeColorAttachment: Bool,
        shouldRequireDescriptorDrawableLayerDeviceCleanupCoownership: Bool,
        shouldKeepColorAttachmentConfigurationBlocked: Bool,
        shouldKeepEncoderDrawCommitPresentGpuRenderBlocked: Bool,
        shouldKeepDrawableTextureFirstSliceCurrentShellBounded: Bool,
        shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool,
        shouldKeepRendererStateWriteBlocked: Bool,
        didConfirmDrawableRenderPassColorAttachmentInput: Bool,
        didConfirmDrawableTextureLifetimePlanningInput: Bool,
        didConfirmDrawableTextureLifetimeFirstSliceOrdering: Bool,
        didConfirmDrawableTextureLifetimeFirstSliceStopLine: Bool,
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
        this.drawableRenderPassColorAttachmentReadiness =
            drawableRenderPassColorAttachmentReadiness
        this.drawableTextureLifetimePlanningReadiness =
            drawableTextureLifetimePlanningReadiness
        this.drawableTextureLifetimeFirstSliceFacts =
            drawableTextureLifetimeFirstSliceFacts
        this.didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceReadiness =
            didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceReadiness
        this.shouldConsumeDrawableRenderPassColorAttachmentReadiness =
            shouldConsumeDrawableRenderPassColorAttachmentReadiness
        this.shouldConsumeDrawableTextureLifetimePlanningReadiness =
            shouldConsumeDrawableTextureLifetimePlanningReadiness
        this.shouldRequireFirstSliceAdmissionBeforeDrawableAcquisition =
            shouldRequireFirstSliceAdmissionBeforeDrawableAcquisition
        this.shouldRequireBoundedIsolatedDrawableAcquisitionProbe =
            shouldRequireBoundedIsolatedDrawableAcquisitionProbe
        this.shouldRequireProbeLocalDrawableTokenLifetime =
            shouldRequireProbeLocalDrawableTokenLifetime
        this.shouldRequireDrawableTextureObservationBeforeColorAttachment =
            shouldRequireDrawableTextureObservationBeforeColorAttachment
        this.shouldRequireDescriptorDrawableLayerDeviceCleanupCoownership =
            shouldRequireDescriptorDrawableLayerDeviceCleanupCoownership
        this.shouldKeepColorAttachmentConfigurationBlocked =
            shouldKeepColorAttachmentConfigurationBlocked
        this.shouldKeepEncoderDrawCommitPresentGpuRenderBlocked =
            shouldKeepEncoderDrawCommitPresentGpuRenderBlocked
        this.shouldKeepDrawableTextureFirstSliceCurrentShellBounded =
            shouldKeepDrawableTextureFirstSliceCurrentShellBounded
        this.shouldRequireProductionWriteAdmissionBeforeRendererStateWrite =
            shouldRequireProductionWriteAdmissionBeforeRendererStateWrite
        this.shouldKeepRendererStateWriteBlocked =
            shouldKeepRendererStateWriteBlocked
        this.didConfirmDrawableRenderPassColorAttachmentInput =
            didConfirmDrawableRenderPassColorAttachmentInput
        this.didConfirmDrawableTextureLifetimePlanningInput =
            didConfirmDrawableTextureLifetimePlanningInput
        this.didConfirmDrawableTextureLifetimeFirstSliceOrdering =
            didConfirmDrawableTextureLifetimeFirstSliceOrdering
        this.didConfirmDrawableTextureLifetimeFirstSliceStopLine =
            didConfirmDrawableTextureLifetimeFirstSliceStopLine
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

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceFacts(
    drawableRenderPassColorAttachmentReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentReadiness,
    drawableTextureLifetimePlanningReadiness:
        CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceFacts(
        drawableRenderPassColorAttachmentReadiness
            .didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentReadiness,
        drawableTextureLifetimePlanningReadiness
            .didPrepareRendererNoDrawableTextureLifetimePlanningReadiness,
        drawableRenderPassColorAttachmentReadiness
            .shouldRequireFirstSliceAdmissionBeforeDrawableAcquisition,
        true,
        drawableTextureLifetimePlanningReadiness
            .didConfirmTokenLocalAcquireClassifyReleaseRequired,
        true,
        drawableRenderPassColorAttachmentReadiness
            .shouldRequireDescriptorDrawableLayerDeviceCleanupCoownership &&
            drawableTextureLifetimePlanningReadiness
                .didConfirmDescriptorDrawableLayerDeviceCleanupStillUnproven,
        true,
        true,
        drawableRenderPassColorAttachmentReadiness
            .shouldKeepDrawableColorAttachmentCurrentShellBounded,
        drawableRenderPassColorAttachmentReadiness
            .shouldRequireProductionWriteAdmissionBeforeRendererStateWrite,
        drawableRenderPassColorAttachmentReadiness
            .shouldKeepRendererStateWriteBlocked,
        drawableRenderPassColorAttachmentReadiness
            .didConfirmNoProductionTruthUpgrade,
        drawableRenderPassColorAttachmentReadiness
            .didConfirmNoBackendReadyTruth &&
            drawableTextureLifetimePlanningReadiness.didConfirmNoBackendReadyTruth,
        true,
        drawableRenderPassColorAttachmentReadiness.didConfirmNoPublicApi &&
            drawableTextureLifetimePlanningReadiness.didConfirmNoPublicSurface,
        true,
        drawableRenderPassColorAttachmentReadiness
            .didConfirmNoRuntimeStateWrite,
        drawableRenderPassColorAttachmentReadiness.didConfirmNoCjpmTomlChange,
        drawableRenderPassColorAttachmentReadiness
            .didConfirmNoRendererStateWrite &&
            drawableTextureLifetimePlanningReadiness.didConfirmNoRendererStateWrite,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceReadiness(
    drawableRenderPassColorAttachmentReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentReadiness,
    drawableTextureLifetimePlanningReadiness:
        CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness,
    drawableTextureLifetimeFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceReadiness {
    let drawableColorAttachmentInputReady =
        drawableTextureLifetimeFirstSliceFacts
            .didConsumeDrawableRenderPassColorAttachmentReadiness &&
        drawableRenderPassColorAttachmentReadiness
            .didConfirmDrawableColorAttachmentPrerequisiteOrdering &&
        drawableRenderPassColorAttachmentReadiness
            .didConfirmDrawableColorAttachmentStopLine
    let lifetimePlanningInputReady =
        drawableTextureLifetimeFirstSliceFacts
            .didConsumeDrawableTextureLifetimePlanningReadiness &&
        drawableTextureLifetimePlanningReadiness
            .didConfirmProductionDrawableTokenLifetimeStillMissing &&
        drawableTextureLifetimePlanningReadiness
            .didConfirmProductionDrawableTextureOwnershipStillMissing &&
        drawableTextureLifetimePlanningReadiness
            .didConfirmTokenLocalAcquireClassifyReleaseRequired
    let orderingReady =
        drawableTextureLifetimeFirstSliceFacts
            .didRequireFirstSliceAdmissionBeforeDrawableAcquisition &&
        drawableTextureLifetimeFirstSliceFacts
            .didRequireBoundedIsolatedDrawableAcquisitionProbe &&
        drawableTextureLifetimeFirstSliceFacts
            .didRequireProbeLocalDrawableTokenLifetime &&
        drawableTextureLifetimeFirstSliceFacts
            .didRequireDrawableTextureObservationBeforeColorAttachment &&
        drawableTextureLifetimeFirstSliceFacts
            .didRequireDescriptorDrawableLayerDeviceCleanupCoownership
    let stopLineReady =
        drawableTextureLifetimeFirstSliceFacts
            .didKeepColorAttachmentConfigurationBlocked &&
        drawableTextureLifetimeFirstSliceFacts
            .didKeepEncoderDrawCommitPresentGpuRenderBlocked &&
        drawableTextureLifetimeFirstSliceFacts
            .didKeepDrawableTextureFirstSliceCurrentShellBounded &&
        drawableTextureLifetimeFirstSliceFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite &&
        drawableTextureLifetimeFirstSliceFacts.didKeepRendererStateWriteBlocked &&
        drawableTextureLifetimeFirstSliceFacts
            .didConfirmNoProductionTruthUpgrade &&
        drawableTextureLifetimeFirstSliceFacts.didConfirmNoBackendReadyTruth &&
        drawableTextureLifetimeFirstSliceFacts
            .didConfirmNoProductionNativeBridgeExpansion &&
        drawableTextureLifetimeFirstSliceFacts.didConfirmNoPublicApi &&
        drawableTextureLifetimeFirstSliceFacts
            .didConfirmNoProductionPublicCAbi &&
        drawableTextureLifetimeFirstSliceFacts.didConfirmNoRuntimeStateWrite &&
        drawableTextureLifetimeFirstSliceFacts.didConfirmNoCjpmTomlChange &&
        drawableTextureLifetimeFirstSliceFacts.didConfirmNoRendererStateWrite &&
        drawableTextureLifetimeFirstSliceFacts
            .didAvoidApprovalExternalPacketOrReportWrapper
    let readinessReady =
        drawableColorAttachmentInputReady &&
        lifetimePlanningInputReady &&
        orderingReady &&
        stopLineReady

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceReadiness(
        drawableRenderPassColorAttachmentReadiness,
        drawableTextureLifetimePlanningReadiness,
        drawableTextureLifetimeFirstSliceFacts,
        readinessReady,
        drawableTextureLifetimeFirstSliceFacts
            .didConsumeDrawableRenderPassColorAttachmentReadiness,
        drawableTextureLifetimeFirstSliceFacts
            .didConsumeDrawableTextureLifetimePlanningReadiness,
        drawableTextureLifetimeFirstSliceFacts
            .didRequireFirstSliceAdmissionBeforeDrawableAcquisition,
        drawableTextureLifetimeFirstSliceFacts
            .didRequireBoundedIsolatedDrawableAcquisitionProbe,
        drawableTextureLifetimeFirstSliceFacts
            .didRequireProbeLocalDrawableTokenLifetime,
        drawableTextureLifetimeFirstSliceFacts
            .didRequireDrawableTextureObservationBeforeColorAttachment,
        drawableTextureLifetimeFirstSliceFacts
            .didRequireDescriptorDrawableLayerDeviceCleanupCoownership,
        drawableTextureLifetimeFirstSliceFacts
            .didKeepColorAttachmentConfigurationBlocked,
        drawableTextureLifetimeFirstSliceFacts
            .didKeepEncoderDrawCommitPresentGpuRenderBlocked,
        drawableTextureLifetimeFirstSliceFacts
            .didKeepDrawableTextureFirstSliceCurrentShellBounded,
        drawableTextureLifetimeFirstSliceFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite,
        drawableTextureLifetimeFirstSliceFacts.didKeepRendererStateWriteBlocked,
        drawableColorAttachmentInputReady,
        lifetimePlanningInputReady,
        orderingReady,
        stopLineReady,
        drawableTextureLifetimeFirstSliceFacts
            .didConfirmNoProductionTruthUpgrade,
        drawableTextureLifetimeFirstSliceFacts.didConfirmNoBackendReadyTruth,
        drawableTextureLifetimeFirstSliceFacts
            .didConfirmNoProductionNativeBridgeExpansion,
        drawableTextureLifetimeFirstSliceFacts.didConfirmNoPublicApi,
        drawableTextureLifetimeFirstSliceFacts.didConfirmNoProductionPublicCAbi,
        drawableTextureLifetimeFirstSliceFacts.didConfirmNoRuntimeStateWrite,
        drawableTextureLifetimeFirstSliceFacts.didConfirmNoCjpmTomlChange,
        drawableTextureLifetimeFirstSliceFacts.didConfirmNoRendererStateWrite,
        drawableTextureLifetimeFirstSliceFacts
            .didAvoidApprovalExternalPacketOrReportWrapper
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceReadiness {
    let drawableRenderPassColorAttachmentReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentDraft()
    let drawableTextureLifetimePlanningReadiness =
        cjguiInternalExecuteDefaultRendererDrawableTextureLifetimePlanningDraft()
    let drawableTextureLifetimeFirstSliceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceFacts(
            drawableRenderPassColorAttachmentReadiness,
            drawableTextureLifetimePlanningReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceReadiness(
        drawableRenderPassColorAttachmentReadiness,
        drawableTextureLifetimePlanningReadiness,
        drawableTextureLifetimeFirstSliceFacts
    )
}
