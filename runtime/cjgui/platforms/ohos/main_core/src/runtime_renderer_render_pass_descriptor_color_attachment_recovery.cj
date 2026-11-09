// 维护注释：本文件是 MTLRenderPassDescriptor color attachment implementation recovery owner。
// Truth: 只消费 CjguiInternalRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness，
// 将 production drawable texture lifetime、descriptor / drawable / layer / device cleanup
// 共同所有权缺口脱水为 recovery facts。
// Stop-line: 不配置 colorAttachments[0]，不绑定 drawable texture，不创建 encoder，
// 不 draw，不 commit，不 present，不提交 GPU work，不执行 render，不写 runtime_state.cj。
// Same-shape Boundary Brake: recovery facts 不得包装成 attachment implementation、
// render-ready、GPU submission、backend-ready、state write、receipt、record 或 publication。
package cjgui

struct CjguiInternalRendererRenderPassDescriptorColorAttachmentRecoveryObservation {
    let didObserveColorAttachmentPlanningTail: Bool
    let didConfirmProductionDrawableTokenLifetimeAbsent: Bool
    let didConfirmProductionDrawableTextureOwnershipAbsent: Bool
    let didConfirmDescriptorDrawableLayerDeviceCleanupCoownershipAbsent: Bool
    let didKeepIsolatedDrawableEvidenceNonProduction: Bool
    let didKeepColorAttachmentImplementationBlocked: Bool
    let didKeepEncoderCreationBlocked: Bool
    let didKeepDrawCommitPresentGpuRenderBlocked: Bool
    let didKeepRecoveryFactsDehydrated: Bool

    init(
        didObserveColorAttachmentPlanningTail: Bool,
        didConfirmProductionDrawableTokenLifetimeAbsent: Bool,
        didConfirmProductionDrawableTextureOwnershipAbsent: Bool,
        didConfirmDescriptorDrawableLayerDeviceCleanupCoownershipAbsent: Bool,
        didKeepIsolatedDrawableEvidenceNonProduction: Bool,
        didKeepColorAttachmentImplementationBlocked: Bool,
        didKeepEncoderCreationBlocked: Bool,
        didKeepDrawCommitPresentGpuRenderBlocked: Bool,
        didKeepRecoveryFactsDehydrated: Bool
    ) {
        this.didObserveColorAttachmentPlanningTail =
            didObserveColorAttachmentPlanningTail
        this.didConfirmProductionDrawableTokenLifetimeAbsent =
            didConfirmProductionDrawableTokenLifetimeAbsent
        this.didConfirmProductionDrawableTextureOwnershipAbsent =
            didConfirmProductionDrawableTextureOwnershipAbsent
        this.didConfirmDescriptorDrawableLayerDeviceCleanupCoownershipAbsent =
            didConfirmDescriptorDrawableLayerDeviceCleanupCoownershipAbsent
        this.didKeepIsolatedDrawableEvidenceNonProduction =
            didKeepIsolatedDrawableEvidenceNonProduction
        this.didKeepColorAttachmentImplementationBlocked =
            didKeepColorAttachmentImplementationBlocked
        this.didKeepEncoderCreationBlocked = didKeepEncoderCreationBlocked
        this.didKeepDrawCommitPresentGpuRenderBlocked =
            didKeepDrawCommitPresentGpuRenderBlocked
        this.didKeepRecoveryFactsDehydrated = didKeepRecoveryFactsDehydrated
    }
}

struct CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness {
    let colorAttachmentPlanningReadiness:
        CjguiInternalRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness
    let recoveryObservation:
        CjguiInternalRendererRenderPassDescriptorColorAttachmentRecoveryObservation
    let didPrepareRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness:
        Bool
    let shouldDeferRendererRenderPassDescriptorColorAttachmentImplementation:
        Bool
    let shouldReportRendererRenderPassDescriptorColorAttachmentRecoveryBlocked:
        Bool
    let didPreserveRendererColorAttachmentPlanningReadiness: Bool
    let didConfirmProductionDrawableTokenLifetimeMissing: Bool
    let didConfirmProductionDrawableTextureOwnershipMissing: Bool
    let didConfirmDescriptorDrawableLayerDeviceCleanupStillUnproven: Bool
    let didConfirmIsolatedDrawableEvidenceCannotConfigureProductionDescriptor:
        Bool
    let didConfirmColorAttachmentFirstSliceStillBlocked: Bool
    let didConfirmDrawableTextureLifetimeSupportRequired: Bool
    let didConfirmEncoderCreationStillBlocked: Bool
    let didConfirmNoEncoderDrawCommitPresentGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepColorAttachmentRecoveryReadinessDehydrated: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        colorAttachmentPlanningReadiness:
            CjguiInternalRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness,
        recoveryObservation:
            CjguiInternalRendererRenderPassDescriptorColorAttachmentRecoveryObservation,
        didPrepareRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness:
            Bool,
        shouldDeferRendererRenderPassDescriptorColorAttachmentImplementation:
            Bool,
        shouldReportRendererRenderPassDescriptorColorAttachmentRecoveryBlocked:
            Bool,
        didPreserveRendererColorAttachmentPlanningReadiness: Bool,
        didConfirmProductionDrawableTokenLifetimeMissing: Bool,
        didConfirmProductionDrawableTextureOwnershipMissing: Bool,
        didConfirmDescriptorDrawableLayerDeviceCleanupStillUnproven: Bool,
        didConfirmIsolatedDrawableEvidenceCannotConfigureProductionDescriptor:
            Bool,
        didConfirmColorAttachmentFirstSliceStillBlocked: Bool,
        didConfirmDrawableTextureLifetimeSupportRequired: Bool,
        didConfirmEncoderCreationStillBlocked: Bool,
        didConfirmNoEncoderDrawCommitPresentGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepColorAttachmentRecoveryReadinessDehydrated: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.colorAttachmentPlanningReadiness =
            colorAttachmentPlanningReadiness
        this.recoveryObservation = recoveryObservation
        this.didPrepareRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness =
            didPrepareRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness
        this.shouldDeferRendererRenderPassDescriptorColorAttachmentImplementation =
            shouldDeferRendererRenderPassDescriptorColorAttachmentImplementation
        this.shouldReportRendererRenderPassDescriptorColorAttachmentRecoveryBlocked =
            shouldReportRendererRenderPassDescriptorColorAttachmentRecoveryBlocked
        this.didPreserveRendererColorAttachmentPlanningReadiness =
            didPreserveRendererColorAttachmentPlanningReadiness
        this.didConfirmProductionDrawableTokenLifetimeMissing =
            didConfirmProductionDrawableTokenLifetimeMissing
        this.didConfirmProductionDrawableTextureOwnershipMissing =
            didConfirmProductionDrawableTextureOwnershipMissing
        this.didConfirmDescriptorDrawableLayerDeviceCleanupStillUnproven =
            didConfirmDescriptorDrawableLayerDeviceCleanupStillUnproven
        this.didConfirmIsolatedDrawableEvidenceCannotConfigureProductionDescriptor =
            didConfirmIsolatedDrawableEvidenceCannotConfigureProductionDescriptor
        this.didConfirmColorAttachmentFirstSliceStillBlocked =
            didConfirmColorAttachmentFirstSliceStillBlocked
        this.didConfirmDrawableTextureLifetimeSupportRequired =
            didConfirmDrawableTextureLifetimeSupportRequired
        this.didConfirmEncoderCreationStillBlocked =
            didConfirmEncoderCreationStillBlocked
        this.didConfirmNoEncoderDrawCommitPresentGpuOrRender =
            didConfirmNoEncoderDrawCommitPresentGpuOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepColorAttachmentRecoveryReadinessDehydrated =
            didKeepColorAttachmentRecoveryReadinessDehydrated
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildDefaultRendererRenderPassDescriptorColorAttachmentRecoveryObservation():
    CjguiInternalRendererRenderPassDescriptorColorAttachmentRecoveryObservation {
    return CjguiInternalRendererRenderPassDescriptorColorAttachmentRecoveryObservation(
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

func cjguiInternalBuildRendererRenderPassDescriptorColorAttachmentRecoveryReadiness(
    colorAttachmentPlanningReadiness:
        CjguiInternalRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness,
    recoveryObservation:
        CjguiInternalRendererRenderPassDescriptorColorAttachmentRecoveryObservation
): CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness {
    let planningTailReady =
        colorAttachmentPlanningReadiness
            .didPrepareRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness &&
        colorAttachmentPlanningReadiness
            .didConfirmProductionDrawableTextureLifecycleMissing &&
        colorAttachmentPlanningReadiness
            .didConfirmIsolatedDrawableCannotConfigureProductionDescriptor &&
        colorAttachmentPlanningReadiness
            .didConfirmDescriptorDrawableCleanupStillUnproven &&
        colorAttachmentPlanningReadiness
            .didConfirmColorAttachmentConfigurationStillBlocked &&
        colorAttachmentPlanningReadiness.didConfirmEncoderCreationStillBlocked &&
        colorAttachmentPlanningReadiness
            .didConfirmNoEncoderDrawCommitPresentGpuOrRender &&
        colorAttachmentPlanningReadiness.didConfirmNoPointerHandleClassIdReturn &&
        colorAttachmentPlanningReadiness.didConfirmNoPublicSurface &&
        colorAttachmentPlanningReadiness.didConfirmNoRendererStateWrite &&
        colorAttachmentPlanningReadiness.didConfirmNoBackendReadyTruth
    let recoveryReady =
        planningTailReady &&
        recoveryObservation.didObserveColorAttachmentPlanningTail &&
        recoveryObservation.didConfirmProductionDrawableTokenLifetimeAbsent &&
        recoveryObservation.didConfirmProductionDrawableTextureOwnershipAbsent &&
        recoveryObservation
            .didConfirmDescriptorDrawableLayerDeviceCleanupCoownershipAbsent &&
        recoveryObservation.didKeepIsolatedDrawableEvidenceNonProduction &&
        recoveryObservation.didKeepColorAttachmentImplementationBlocked &&
        recoveryObservation.didKeepEncoderCreationBlocked &&
        recoveryObservation.didKeepDrawCommitPresentGpuRenderBlocked &&
        recoveryObservation.didKeepRecoveryFactsDehydrated

    return CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness(
        colorAttachmentPlanningReadiness,
        recoveryObservation,
        recoveryReady,
        true,
        true,
        planningTailReady,
        recoveryObservation.didConfirmProductionDrawableTokenLifetimeAbsent,
        recoveryObservation.didConfirmProductionDrawableTextureOwnershipAbsent,
        recoveryObservation
            .didConfirmDescriptorDrawableLayerDeviceCleanupCoownershipAbsent,
        recoveryObservation.didKeepIsolatedDrawableEvidenceNonProduction,
        recoveryObservation.didKeepColorAttachmentImplementationBlocked,
        true,
        recoveryObservation.didKeepEncoderCreationBlocked,
        recoveryObservation.didKeepDrawCommitPresentGpuRenderBlocked,
        true,
        true,
        true,
        true,
        recoveryObservation.didKeepRecoveryFactsDehydrated,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererRenderPassDescriptorColorAttachmentRecoveryDraft():
    CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness {
    let colorAttachmentPlanningReadiness =
        cjguiInternalExecuteDefaultRendererRenderPassDescriptorColorAttachmentPlanningDraft()
    let recoveryObservation =
        cjguiInternalBuildDefaultRendererRenderPassDescriptorColorAttachmentRecoveryObservation()
    return cjguiInternalBuildRendererRenderPassDescriptorColorAttachmentRecoveryReadiness(
        colorAttachmentPlanningReadiness,
        recoveryObservation
    )
}
