// 中文维护注释：本文件是 visible-window runtime native probe 的
// drawable / render-pass color attachment readiness owner。
// Owner: runtime renderer internal drawable to render-pass color attachment
// readiness。
// Truth: 只消费 stage106 command queue / command buffer first-slice envelope
// 与既有 render-pass color attachment recovery readiness，把第一帧链路中
// drawable acquisition、drawable texture lifetime、descriptor color attachment
// 的前置顺序建模为 current-shell bounded contract。它不获取 drawable，
// 不配置 color attachment，不创建 encoder，不提交或 present，不写 renderer
// state，不把 current-shell evidence 升级为 production truth。
// Stop-line: 不新增 production accessor call site，不调用 application
// singleton accessor，不创建或激活 NSApplication，不扩 native bridge / public
// API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
// Same-shape Boundary Brake: 本 owner 必须表达 drawable / render-pass color
// attachment prerequisite contract；不得退化成 approval、external packet、
// report wrapper 或 no-runtime-execution 包装。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentFacts {
    let didConsumeCommandQueueCommandBufferFirstSliceEnvelope: Bool
    let didConsumeRenderPassDescriptorColorAttachmentRecovery: Bool
    let didRequireFirstSliceAdmissionBeforeDrawableAcquisition: Bool
    let didRequireDrawableTextureLifetimeBeforeColorAttachment: Bool
    let didRequireRenderPassDescriptorBeforeColorAttachment: Bool
    let didRequireDescriptorDrawableLayerDeviceCleanupCoownership: Bool
    let didKeepDrawableAcquisitionBlockedUntilAdmittedFirstSlice: Bool
    let didKeepColorAttachmentConfigurationBlocked: Bool
    let didKeepEncoderCreationBlocked: Bool
    let didKeepDrawCommitPresentGpuRenderBlocked: Bool
    let didKeepDrawableColorAttachmentCurrentShellBounded: Bool
    let didRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didConfirmNoProductionTruthUpgrade: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didAvoidApprovalExternalPacketOrReportWrapper: Bool

    init(
        didConsumeCommandQueueCommandBufferFirstSliceEnvelope: Bool,
        didConsumeRenderPassDescriptorColorAttachmentRecovery: Bool,
        didRequireFirstSliceAdmissionBeforeDrawableAcquisition: Bool,
        didRequireDrawableTextureLifetimeBeforeColorAttachment: Bool,
        didRequireRenderPassDescriptorBeforeColorAttachment: Bool,
        didRequireDescriptorDrawableLayerDeviceCleanupCoownership: Bool,
        didKeepDrawableAcquisitionBlockedUntilAdmittedFirstSlice: Bool,
        didKeepColorAttachmentConfigurationBlocked: Bool,
        didKeepEncoderCreationBlocked: Bool,
        didKeepDrawCommitPresentGpuRenderBlocked: Bool,
        didKeepDrawableColorAttachmentCurrentShellBounded: Bool,
        didRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didConfirmNoProductionTruthUpgrade: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didAvoidApprovalExternalPacketOrReportWrapper: Bool
    ) {
        this.didConsumeCommandQueueCommandBufferFirstSliceEnvelope =
            didConsumeCommandQueueCommandBufferFirstSliceEnvelope
        this.didConsumeRenderPassDescriptorColorAttachmentRecovery =
            didConsumeRenderPassDescriptorColorAttachmentRecovery
        this.didRequireFirstSliceAdmissionBeforeDrawableAcquisition =
            didRequireFirstSliceAdmissionBeforeDrawableAcquisition
        this.didRequireDrawableTextureLifetimeBeforeColorAttachment =
            didRequireDrawableTextureLifetimeBeforeColorAttachment
        this.didRequireRenderPassDescriptorBeforeColorAttachment =
            didRequireRenderPassDescriptorBeforeColorAttachment
        this.didRequireDescriptorDrawableLayerDeviceCleanupCoownership =
            didRequireDescriptorDrawableLayerDeviceCleanupCoownership
        this.didKeepDrawableAcquisitionBlockedUntilAdmittedFirstSlice =
            didKeepDrawableAcquisitionBlockedUntilAdmittedFirstSlice
        this.didKeepColorAttachmentConfigurationBlocked =
            didKeepColorAttachmentConfigurationBlocked
        this.didKeepEncoderCreationBlocked = didKeepEncoderCreationBlocked
        this.didKeepDrawCommitPresentGpuRenderBlocked =
            didKeepDrawCommitPresentGpuRenderBlocked
        this.didKeepDrawableColorAttachmentCurrentShellBounded =
            didKeepDrawableColorAttachmentCurrentShellBounded
        this.didRequireProductionWriteAdmissionBeforeRendererStateWrite =
            didRequireProductionWriteAdmissionBeforeRendererStateWrite
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didConfirmNoProductionTruthUpgrade =
            didConfirmNoProductionTruthUpgrade
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didConfirmNoNativeBridgeExpansion =
            didConfirmNoNativeBridgeExpansion
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentReadiness {
    let commandQueueCommandBufferFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceReadiness
    let colorAttachmentRecoveryReadiness:
        CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness
    let drawableRenderPassColorAttachmentFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentFacts
    let didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentReadiness:
        Bool
    let shouldConsumeCommandQueueCommandBufferFirstSliceEnvelope: Bool
    let shouldConsumeRenderPassDescriptorColorAttachmentRecovery: Bool
    let shouldRequireFirstSliceAdmissionBeforeDrawableAcquisition: Bool
    let shouldRequireDrawableTextureLifetimeBeforeColorAttachment: Bool
    let shouldRequireRenderPassDescriptorBeforeColorAttachment: Bool
    let shouldRequireDescriptorDrawableLayerDeviceCleanupCoownership: Bool
    let shouldKeepDrawableAcquisitionBlockedUntilAdmittedFirstSlice: Bool
    let shouldKeepColorAttachmentConfigurationBlocked: Bool
    let shouldKeepEncoderCreationBlocked: Bool
    let shouldKeepDrawCommitPresentGpuRenderBlocked: Bool
    let shouldKeepDrawableColorAttachmentCurrentShellBounded: Bool
    let shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool
    let shouldKeepRendererStateWriteBlocked: Bool
    let didConfirmFirstSliceInput: Bool
    let didConfirmColorAttachmentRecoveryInput: Bool
    let didConfirmDrawableColorAttachmentPrerequisiteOrdering: Bool
    let didConfirmDrawableColorAttachmentStopLine: Bool
    let didConfirmNoProductionTruthUpgrade: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didAvoidApprovalExternalPacketOrReportWrapper: Bool

    init(
        commandQueueCommandBufferFirstSliceReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceReadiness,
        colorAttachmentRecoveryReadiness:
            CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness,
        drawableRenderPassColorAttachmentFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentFacts,
        didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentReadiness:
            Bool,
        shouldConsumeCommandQueueCommandBufferFirstSliceEnvelope: Bool,
        shouldConsumeRenderPassDescriptorColorAttachmentRecovery: Bool,
        shouldRequireFirstSliceAdmissionBeforeDrawableAcquisition: Bool,
        shouldRequireDrawableTextureLifetimeBeforeColorAttachment: Bool,
        shouldRequireRenderPassDescriptorBeforeColorAttachment: Bool,
        shouldRequireDescriptorDrawableLayerDeviceCleanupCoownership: Bool,
        shouldKeepDrawableAcquisitionBlockedUntilAdmittedFirstSlice: Bool,
        shouldKeepColorAttachmentConfigurationBlocked: Bool,
        shouldKeepEncoderCreationBlocked: Bool,
        shouldKeepDrawCommitPresentGpuRenderBlocked: Bool,
        shouldKeepDrawableColorAttachmentCurrentShellBounded: Bool,
        shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool,
        shouldKeepRendererStateWriteBlocked: Bool,
        didConfirmFirstSliceInput: Bool,
        didConfirmColorAttachmentRecoveryInput: Bool,
        didConfirmDrawableColorAttachmentPrerequisiteOrdering: Bool,
        didConfirmDrawableColorAttachmentStopLine: Bool,
        didConfirmNoProductionTruthUpgrade: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didAvoidApprovalExternalPacketOrReportWrapper: Bool
    ) {
        this.commandQueueCommandBufferFirstSliceReadiness =
            commandQueueCommandBufferFirstSliceReadiness
        this.colorAttachmentRecoveryReadiness =
            colorAttachmentRecoveryReadiness
        this.drawableRenderPassColorAttachmentFacts =
            drawableRenderPassColorAttachmentFacts
        this.didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentReadiness =
            didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentReadiness
        this.shouldConsumeCommandQueueCommandBufferFirstSliceEnvelope =
            shouldConsumeCommandQueueCommandBufferFirstSliceEnvelope
        this.shouldConsumeRenderPassDescriptorColorAttachmentRecovery =
            shouldConsumeRenderPassDescriptorColorAttachmentRecovery
        this.shouldRequireFirstSliceAdmissionBeforeDrawableAcquisition =
            shouldRequireFirstSliceAdmissionBeforeDrawableAcquisition
        this.shouldRequireDrawableTextureLifetimeBeforeColorAttachment =
            shouldRequireDrawableTextureLifetimeBeforeColorAttachment
        this.shouldRequireRenderPassDescriptorBeforeColorAttachment =
            shouldRequireRenderPassDescriptorBeforeColorAttachment
        this.shouldRequireDescriptorDrawableLayerDeviceCleanupCoownership =
            shouldRequireDescriptorDrawableLayerDeviceCleanupCoownership
        this.shouldKeepDrawableAcquisitionBlockedUntilAdmittedFirstSlice =
            shouldKeepDrawableAcquisitionBlockedUntilAdmittedFirstSlice
        this.shouldKeepColorAttachmentConfigurationBlocked =
            shouldKeepColorAttachmentConfigurationBlocked
        this.shouldKeepEncoderCreationBlocked =
            shouldKeepEncoderCreationBlocked
        this.shouldKeepDrawCommitPresentGpuRenderBlocked =
            shouldKeepDrawCommitPresentGpuRenderBlocked
        this.shouldKeepDrawableColorAttachmentCurrentShellBounded =
            shouldKeepDrawableColorAttachmentCurrentShellBounded
        this.shouldRequireProductionWriteAdmissionBeforeRendererStateWrite =
            shouldRequireProductionWriteAdmissionBeforeRendererStateWrite
        this.shouldKeepRendererStateWriteBlocked =
            shouldKeepRendererStateWriteBlocked
        this.didConfirmFirstSliceInput = didConfirmFirstSliceInput
        this.didConfirmColorAttachmentRecoveryInput =
            didConfirmColorAttachmentRecoveryInput
        this.didConfirmDrawableColorAttachmentPrerequisiteOrdering =
            didConfirmDrawableColorAttachmentPrerequisiteOrdering
        this.didConfirmDrawableColorAttachmentStopLine =
            didConfirmDrawableColorAttachmentStopLine
        this.didConfirmNoProductionTruthUpgrade =
            didConfirmNoProductionTruthUpgrade
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didConfirmNoNativeBridgeExpansion =
            didConfirmNoNativeBridgeExpansion
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

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentFacts(
    commandQueueCommandBufferFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceReadiness,
    colorAttachmentRecoveryReadiness:
        CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentFacts(
        commandQueueCommandBufferFirstSliceReadiness
            .didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceReadiness,
        colorAttachmentRecoveryReadiness
            .didPrepareRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness,
        true,
        colorAttachmentRecoveryReadiness
            .didConfirmDrawableTextureLifetimeSupportRequired,
        true,
        colorAttachmentRecoveryReadiness
            .didConfirmDescriptorDrawableLayerDeviceCleanupStillUnproven,
        true,
        colorAttachmentRecoveryReadiness
            .didConfirmColorAttachmentFirstSliceStillBlocked,
        commandQueueCommandBufferFirstSliceReadiness
            .shouldKeepEncoderCreationBlocked &&
            colorAttachmentRecoveryReadiness.didConfirmEncoderCreationStillBlocked,
        colorAttachmentRecoveryReadiness
            .didConfirmNoEncoderDrawCommitPresentGpuOrRender,
        commandQueueCommandBufferFirstSliceReadiness
            .shouldKeepCurrentShellFirstSliceBounded,
        commandQueueCommandBufferFirstSliceReadiness
            .shouldRequireProductionWriteAdmissionBeforeRendererStateWrite,
        commandQueueCommandBufferFirstSliceReadiness
            .shouldKeepRendererStateWriteBlocked &&
            colorAttachmentRecoveryReadiness.didConfirmNoRendererStateWrite,
        commandQueueCommandBufferFirstSliceReadiness
            .didConfirmNoProductionTruthUpgrade,
        commandQueueCommandBufferFirstSliceReadiness
            .didConfirmNoBackendReadyTruth &&
            colorAttachmentRecoveryReadiness.didConfirmNoBackendReadyTruth,
        commandQueueCommandBufferFirstSliceReadiness
            .didConfirmNoNativeBridgeExpansion,
        commandQueueCommandBufferFirstSliceReadiness.didConfirmNoPublicApi &&
            colorAttachmentRecoveryReadiness.didConfirmNoPublicSurface,
        commandQueueCommandBufferFirstSliceReadiness
            .didConfirmNoProductionPublicCAbi,
        commandQueueCommandBufferFirstSliceReadiness
            .didConfirmNoRuntimeStateWrite,
        commandQueueCommandBufferFirstSliceReadiness.didConfirmNoCjpmTomlChange,
        commandQueueCommandBufferFirstSliceReadiness
            .didConfirmNoRendererStateWrite &&
            colorAttachmentRecoveryReadiness.didConfirmNoRendererStateWrite,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentReadiness(
    commandQueueCommandBufferFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceReadiness,
    colorAttachmentRecoveryReadiness:
        CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness,
    drawableRenderPassColorAttachmentFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentReadiness {
    let firstSliceInputReady =
        drawableRenderPassColorAttachmentFacts
            .didConsumeCommandQueueCommandBufferFirstSliceEnvelope &&
        commandQueueCommandBufferFirstSliceReadiness.didConfirmFirstSliceOrdering &&
        commandQueueCommandBufferFirstSliceReadiness.didConfirmFirstSliceStopLine
    let colorAttachmentRecoveryInputReady =
        drawableRenderPassColorAttachmentFacts
            .didConsumeRenderPassDescriptorColorAttachmentRecovery &&
        colorAttachmentRecoveryReadiness.didConfirmColorAttachmentFirstSliceStillBlocked &&
        colorAttachmentRecoveryReadiness.didConfirmEncoderCreationStillBlocked
    let prerequisiteOrderingReady =
        drawableRenderPassColorAttachmentFacts
            .didRequireFirstSliceAdmissionBeforeDrawableAcquisition &&
        drawableRenderPassColorAttachmentFacts
            .didRequireDrawableTextureLifetimeBeforeColorAttachment &&
        drawableRenderPassColorAttachmentFacts
            .didRequireRenderPassDescriptorBeforeColorAttachment &&
        drawableRenderPassColorAttachmentFacts
            .didRequireDescriptorDrawableLayerDeviceCleanupCoownership &&
        drawableRenderPassColorAttachmentFacts
            .didKeepDrawableAcquisitionBlockedUntilAdmittedFirstSlice
    let stopLineReady =
        drawableRenderPassColorAttachmentFacts
            .didKeepColorAttachmentConfigurationBlocked &&
        drawableRenderPassColorAttachmentFacts.didKeepEncoderCreationBlocked &&
        drawableRenderPassColorAttachmentFacts
            .didKeepDrawCommitPresentGpuRenderBlocked &&
        drawableRenderPassColorAttachmentFacts
            .didKeepDrawableColorAttachmentCurrentShellBounded &&
        drawableRenderPassColorAttachmentFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite &&
        drawableRenderPassColorAttachmentFacts.didKeepRendererStateWriteBlocked &&
        drawableRenderPassColorAttachmentFacts.didConfirmNoProductionTruthUpgrade &&
        drawableRenderPassColorAttachmentFacts.didConfirmNoBackendReadyTruth &&
        drawableRenderPassColorAttachmentFacts.didConfirmNoNativeBridgeExpansion &&
        drawableRenderPassColorAttachmentFacts.didConfirmNoPublicApi &&
        drawableRenderPassColorAttachmentFacts
            .didConfirmNoProductionPublicCAbi &&
        drawableRenderPassColorAttachmentFacts.didConfirmNoRuntimeStateWrite &&
        drawableRenderPassColorAttachmentFacts.didConfirmNoCjpmTomlChange &&
        drawableRenderPassColorAttachmentFacts.didConfirmNoRendererStateWrite &&
        drawableRenderPassColorAttachmentFacts
            .didAvoidApprovalExternalPacketOrReportWrapper
    let readinessReady =
        firstSliceInputReady &&
        colorAttachmentRecoveryInputReady &&
        prerequisiteOrderingReady &&
        stopLineReady

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentReadiness(
        commandQueueCommandBufferFirstSliceReadiness,
        colorAttachmentRecoveryReadiness,
        drawableRenderPassColorAttachmentFacts,
        readinessReady,
        drawableRenderPassColorAttachmentFacts
            .didConsumeCommandQueueCommandBufferFirstSliceEnvelope,
        drawableRenderPassColorAttachmentFacts
            .didConsumeRenderPassDescriptorColorAttachmentRecovery,
        drawableRenderPassColorAttachmentFacts
            .didRequireFirstSliceAdmissionBeforeDrawableAcquisition,
        drawableRenderPassColorAttachmentFacts
            .didRequireDrawableTextureLifetimeBeforeColorAttachment,
        drawableRenderPassColorAttachmentFacts
            .didRequireRenderPassDescriptorBeforeColorAttachment,
        drawableRenderPassColorAttachmentFacts
            .didRequireDescriptorDrawableLayerDeviceCleanupCoownership,
        drawableRenderPassColorAttachmentFacts
            .didKeepDrawableAcquisitionBlockedUntilAdmittedFirstSlice,
        drawableRenderPassColorAttachmentFacts
            .didKeepColorAttachmentConfigurationBlocked,
        drawableRenderPassColorAttachmentFacts.didKeepEncoderCreationBlocked,
        drawableRenderPassColorAttachmentFacts
            .didKeepDrawCommitPresentGpuRenderBlocked,
        drawableRenderPassColorAttachmentFacts
            .didKeepDrawableColorAttachmentCurrentShellBounded,
        drawableRenderPassColorAttachmentFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite,
        drawableRenderPassColorAttachmentFacts.didKeepRendererStateWriteBlocked,
        firstSliceInputReady,
        colorAttachmentRecoveryInputReady,
        prerequisiteOrderingReady,
        stopLineReady,
        drawableRenderPassColorAttachmentFacts.didConfirmNoProductionTruthUpgrade,
        drawableRenderPassColorAttachmentFacts.didConfirmNoBackendReadyTruth,
        drawableRenderPassColorAttachmentFacts.didConfirmNoNativeBridgeExpansion,
        drawableRenderPassColorAttachmentFacts.didConfirmNoPublicApi,
        drawableRenderPassColorAttachmentFacts.didConfirmNoProductionPublicCAbi,
        drawableRenderPassColorAttachmentFacts.didConfirmNoRuntimeStateWrite,
        drawableRenderPassColorAttachmentFacts.didConfirmNoCjpmTomlChange,
        drawableRenderPassColorAttachmentFacts.didConfirmNoRendererStateWrite,
        drawableRenderPassColorAttachmentFacts
            .didAvoidApprovalExternalPacketOrReportWrapper
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentReadiness {
    let commandQueueCommandBufferFirstSliceReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceDraft()
    let colorAttachmentRecoveryReadiness =
        cjguiInternalExecuteDefaultRendererRenderPassDescriptorColorAttachmentRecoveryDraft()
    let drawableRenderPassColorAttachmentFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentFacts(
            commandQueueCommandBufferFirstSliceReadiness,
            colorAttachmentRecoveryReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentReadiness(
        commandQueueCommandBufferFirstSliceReadiness,
        colorAttachmentRecoveryReadiness,
        drawableRenderPassColorAttachmentFacts
    )
}
