// 维护注释：本文件是 production drawable texture lifetime planning owner。
// Truth: 只消费 CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness，
// 将 production drawable token / texture lifetime 的前置缺口脱水为 planning facts。
// Stop-line: 不调用 nextDrawable，不保存 drawable，不 present，不创建 command buffer /
// encoder，不 commit，不提交 GPU work，不执行 render，不写 runtime_state.cj。
// Same-shape Boundary Brake: lifetime planning facts 不得包装成 drawable-ready、
// color attachment permission、GPU submission、backend-ready、state write、receipt、
// record 或 publication。
package cjgui

struct CjguiInternalRendererDrawableTextureLifetimePlanningObservation {
    let didObserveColorAttachmentRecoveryTail: Bool
    let didRequireProductionVisibleWindowSemantics: Bool
    let didRequireDisplayBackedLayerOwnership: Bool
    let didRequireTokenLocalDrawableLifetime: Bool
    let didRequireDrawableReleaseClassification: Bool
    let didRequireDescriptorDrawableLayerDeviceCleanupCoownership: Bool
    let didKeepNextDrawableBlockedInProduction: Bool
    let didKeepPresentCommandBufferEncoderGpuRenderBlocked: Bool
    let didKeepLifetimePlanningFactsDehydrated: Bool

    init(
        didObserveColorAttachmentRecoveryTail: Bool,
        didRequireProductionVisibleWindowSemantics: Bool,
        didRequireDisplayBackedLayerOwnership: Bool,
        didRequireTokenLocalDrawableLifetime: Bool,
        didRequireDrawableReleaseClassification: Bool,
        didRequireDescriptorDrawableLayerDeviceCleanupCoownership: Bool,
        didKeepNextDrawableBlockedInProduction: Bool,
        didKeepPresentCommandBufferEncoderGpuRenderBlocked: Bool,
        didKeepLifetimePlanningFactsDehydrated: Bool
    ) {
        this.didObserveColorAttachmentRecoveryTail =
            didObserveColorAttachmentRecoveryTail
        this.didRequireProductionVisibleWindowSemantics =
            didRequireProductionVisibleWindowSemantics
        this.didRequireDisplayBackedLayerOwnership =
            didRequireDisplayBackedLayerOwnership
        this.didRequireTokenLocalDrawableLifetime =
            didRequireTokenLocalDrawableLifetime
        this.didRequireDrawableReleaseClassification =
            didRequireDrawableReleaseClassification
        this.didRequireDescriptorDrawableLayerDeviceCleanupCoownership =
            didRequireDescriptorDrawableLayerDeviceCleanupCoownership
        this.didKeepNextDrawableBlockedInProduction =
            didKeepNextDrawableBlockedInProduction
        this.didKeepPresentCommandBufferEncoderGpuRenderBlocked =
            didKeepPresentCommandBufferEncoderGpuRenderBlocked
        this.didKeepLifetimePlanningFactsDehydrated =
            didKeepLifetimePlanningFactsDehydrated
    }
}

struct CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness {
    let colorAttachmentRecoveryReadiness:
        CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness
    let lifetimePlanningObservation:
        CjguiInternalRendererDrawableTextureLifetimePlanningObservation
    let didPrepareRendererNoDrawableTextureLifetimePlanningReadiness: Bool
    let shouldDeferRendererDrawableTextureLifetimeImplementation: Bool
    let shouldReportRendererDrawableTextureLifetimePlanningBlocked: Bool
    let didPreserveRendererColorAttachmentRecoveryReadiness: Bool
    let didConfirmProductionDrawableTokenLifetimeStillMissing: Bool
    let didConfirmProductionDrawableTextureOwnershipStillMissing: Bool
    let didConfirmProductionVisibleWindowSemanticsRequired: Bool
    let didConfirmDisplayBackedLayerOwnershipRequired: Bool
    let didConfirmTokenLocalAcquireClassifyReleaseRequired: Bool
    let didConfirmDoubleReleaseAndStaleDrawableFailClosedRequired: Bool
    let didConfirmDescriptorDrawableLayerDeviceCleanupStillUnproven: Bool
    let didConfirmNoProductionNextDrawableCall: Bool
    let didConfirmNoPresentCommandBufferEncoderCommitGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepDrawableTextureLifetimePlanningReadinessDehydrated: Bool
    let didAvoidColorAttachmentPermissionWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        colorAttachmentRecoveryReadiness:
            CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness,
        lifetimePlanningObservation:
            CjguiInternalRendererDrawableTextureLifetimePlanningObservation,
        didPrepareRendererNoDrawableTextureLifetimePlanningReadiness: Bool,
        shouldDeferRendererDrawableTextureLifetimeImplementation: Bool,
        shouldReportRendererDrawableTextureLifetimePlanningBlocked: Bool,
        didPreserveRendererColorAttachmentRecoveryReadiness: Bool,
        didConfirmProductionDrawableTokenLifetimeStillMissing: Bool,
        didConfirmProductionDrawableTextureOwnershipStillMissing: Bool,
        didConfirmProductionVisibleWindowSemanticsRequired: Bool,
        didConfirmDisplayBackedLayerOwnershipRequired: Bool,
        didConfirmTokenLocalAcquireClassifyReleaseRequired: Bool,
        didConfirmDoubleReleaseAndStaleDrawableFailClosedRequired: Bool,
        didConfirmDescriptorDrawableLayerDeviceCleanupStillUnproven: Bool,
        didConfirmNoProductionNextDrawableCall: Bool,
        didConfirmNoPresentCommandBufferEncoderCommitGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepDrawableTextureLifetimePlanningReadinessDehydrated: Bool,
        didAvoidColorAttachmentPermissionWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.colorAttachmentRecoveryReadiness =
            colorAttachmentRecoveryReadiness
        this.lifetimePlanningObservation = lifetimePlanningObservation
        this.didPrepareRendererNoDrawableTextureLifetimePlanningReadiness =
            didPrepareRendererNoDrawableTextureLifetimePlanningReadiness
        this.shouldDeferRendererDrawableTextureLifetimeImplementation =
            shouldDeferRendererDrawableTextureLifetimeImplementation
        this.shouldReportRendererDrawableTextureLifetimePlanningBlocked =
            shouldReportRendererDrawableTextureLifetimePlanningBlocked
        this.didPreserveRendererColorAttachmentRecoveryReadiness =
            didPreserveRendererColorAttachmentRecoveryReadiness
        this.didConfirmProductionDrawableTokenLifetimeStillMissing =
            didConfirmProductionDrawableTokenLifetimeStillMissing
        this.didConfirmProductionDrawableTextureOwnershipStillMissing =
            didConfirmProductionDrawableTextureOwnershipStillMissing
        this.didConfirmProductionVisibleWindowSemanticsRequired =
            didConfirmProductionVisibleWindowSemanticsRequired
        this.didConfirmDisplayBackedLayerOwnershipRequired =
            didConfirmDisplayBackedLayerOwnershipRequired
        this.didConfirmTokenLocalAcquireClassifyReleaseRequired =
            didConfirmTokenLocalAcquireClassifyReleaseRequired
        this.didConfirmDoubleReleaseAndStaleDrawableFailClosedRequired =
            didConfirmDoubleReleaseAndStaleDrawableFailClosedRequired
        this.didConfirmDescriptorDrawableLayerDeviceCleanupStillUnproven =
            didConfirmDescriptorDrawableLayerDeviceCleanupStillUnproven
        this.didConfirmNoProductionNextDrawableCall =
            didConfirmNoProductionNextDrawableCall
        this.didConfirmNoPresentCommandBufferEncoderCommitGpuOrRender =
            didConfirmNoPresentCommandBufferEncoderCommitGpuOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepDrawableTextureLifetimePlanningReadinessDehydrated =
            didKeepDrawableTextureLifetimePlanningReadinessDehydrated
        this.didAvoidColorAttachmentPermissionWrapper =
            didAvoidColorAttachmentPermissionWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildDefaultRendererDrawableTextureLifetimePlanningObservation():
    CjguiInternalRendererDrawableTextureLifetimePlanningObservation {
    return CjguiInternalRendererDrawableTextureLifetimePlanningObservation(
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererDrawableTextureLifetimePlanningReadiness(
    colorAttachmentRecoveryReadiness:
        CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness,
    lifetimePlanningObservation:
        CjguiInternalRendererDrawableTextureLifetimePlanningObservation
): CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness {
    let recoveryTailReady =
        colorAttachmentRecoveryReadiness
            .didPrepareRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness &&
        colorAttachmentRecoveryReadiness
            .didConfirmProductionDrawableTokenLifetimeMissing &&
        colorAttachmentRecoveryReadiness
            .didConfirmProductionDrawableTextureOwnershipMissing &&
        colorAttachmentRecoveryReadiness
            .didConfirmDescriptorDrawableLayerDeviceCleanupStillUnproven &&
        colorAttachmentRecoveryReadiness
            .didConfirmIsolatedDrawableEvidenceCannotConfigureProductionDescriptor &&
        colorAttachmentRecoveryReadiness
            .didConfirmColorAttachmentFirstSliceStillBlocked &&
        colorAttachmentRecoveryReadiness
            .didConfirmNoEncoderDrawCommitPresentGpuOrRender &&
        colorAttachmentRecoveryReadiness.didConfirmNoPointerHandleClassIdReturn &&
        colorAttachmentRecoveryReadiness.didConfirmNoPublicSurface &&
        colorAttachmentRecoveryReadiness.didConfirmNoRendererStateWrite &&
        colorAttachmentRecoveryReadiness.didConfirmNoBackendReadyTruth
    let planningReady =
        recoveryTailReady &&
        lifetimePlanningObservation.didObserveColorAttachmentRecoveryTail &&
        lifetimePlanningObservation.didRequireProductionVisibleWindowSemantics &&
        lifetimePlanningObservation.didRequireDisplayBackedLayerOwnership &&
        lifetimePlanningObservation.didRequireTokenLocalDrawableLifetime &&
        lifetimePlanningObservation.didRequireDrawableReleaseClassification &&
        lifetimePlanningObservation
            .didRequireDescriptorDrawableLayerDeviceCleanupCoownership &&
        lifetimePlanningObservation.didKeepNextDrawableBlockedInProduction &&
        lifetimePlanningObservation
            .didKeepPresentCommandBufferEncoderGpuRenderBlocked &&
        lifetimePlanningObservation.didKeepLifetimePlanningFactsDehydrated

    return CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness(
        colorAttachmentRecoveryReadiness,
        lifetimePlanningObservation,
        planningReady,
        true,
        true,
        recoveryTailReady,
        colorAttachmentRecoveryReadiness
            .didConfirmProductionDrawableTokenLifetimeMissing,
        colorAttachmentRecoveryReadiness
            .didConfirmProductionDrawableTextureOwnershipMissing,
        lifetimePlanningObservation.didRequireProductionVisibleWindowSemantics,
        lifetimePlanningObservation.didRequireDisplayBackedLayerOwnership,
        lifetimePlanningObservation.didRequireTokenLocalDrawableLifetime,
        lifetimePlanningObservation.didRequireDrawableReleaseClassification,
        colorAttachmentRecoveryReadiness
            .didConfirmDescriptorDrawableLayerDeviceCleanupStillUnproven &&
            lifetimePlanningObservation
                .didRequireDescriptorDrawableLayerDeviceCleanupCoownership,
        lifetimePlanningObservation.didKeepNextDrawableBlockedInProduction,
        lifetimePlanningObservation
            .didKeepPresentCommandBufferEncoderGpuRenderBlocked,
        true,
        true,
        true,
        true,
        lifetimePlanningObservation.didKeepLifetimePlanningFactsDehydrated,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererDrawableTextureLifetimePlanningDraft():
    CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness {
    let colorAttachmentRecoveryReadiness =
        cjguiInternalExecuteDefaultRendererRenderPassDescriptorColorAttachmentRecoveryDraft()
    let lifetimePlanningObservation =
        cjguiInternalBuildDefaultRendererDrawableTextureLifetimePlanningObservation()
    return cjguiInternalBuildRendererDrawableTextureLifetimePlanningReadiness(
        colorAttachmentRecoveryReadiness,
        lifetimePlanningObservation
    )
}
