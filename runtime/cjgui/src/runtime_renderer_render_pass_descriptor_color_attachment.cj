// 维护注释：本文件是 MTLRenderPassDescriptor color attachment planning owner。
// Truth: 只消费 CjguiInternalRendererNoRenderPassDescriptorCreateDestroyReadiness，
// 将 color attachment 所需的 production drawable texture lifecycle 缺口脱水为 facts。
// Stop-line: 不配置 colorAttachments[0]，不创建 encoder，不 draw，不 commit，
// 不 present，不提交 GPU work，不执行 render，不写 runtime_state.cj。
// Same-shape Boundary Brake: attachment planning facts 不得包装成 render-ready、
// GPU submission、backend-ready、state write、receipt、record 或 publication。
package cjgui

struct CjguiInternalRendererRenderPassDescriptorColorAttachmentPlanningObservation {
    let didObserveDescriptorCreateDestroyTail: Bool
    let didRequireProductionDrawableTextureLifecycle: Bool
    let didRejectIsolatedDrawableAsProductionTruth: Bool
    let didRequireDescriptorDrawableCleanupProof: Bool
    let didKeepColorAttachmentConfigurationBlocked: Bool
    let didKeepEncoderCreationBlocked: Bool
    let didKeepDrawCommitPresentGpuRenderBlocked: Bool
    let didKeepAttachmentPlanningFactsDehydrated: Bool

    init(
        didObserveDescriptorCreateDestroyTail: Bool,
        didRequireProductionDrawableTextureLifecycle: Bool,
        didRejectIsolatedDrawableAsProductionTruth: Bool,
        didRequireDescriptorDrawableCleanupProof: Bool,
        didKeepColorAttachmentConfigurationBlocked: Bool,
        didKeepEncoderCreationBlocked: Bool,
        didKeepDrawCommitPresentGpuRenderBlocked: Bool,
        didKeepAttachmentPlanningFactsDehydrated: Bool
    ) {
        this.didObserveDescriptorCreateDestroyTail =
            didObserveDescriptorCreateDestroyTail
        this.didRequireProductionDrawableTextureLifecycle =
            didRequireProductionDrawableTextureLifecycle
        this.didRejectIsolatedDrawableAsProductionTruth =
            didRejectIsolatedDrawableAsProductionTruth
        this.didRequireDescriptorDrawableCleanupProof =
            didRequireDescriptorDrawableCleanupProof
        this.didKeepColorAttachmentConfigurationBlocked =
            didKeepColorAttachmentConfigurationBlocked
        this.didKeepEncoderCreationBlocked = didKeepEncoderCreationBlocked
        this.didKeepDrawCommitPresentGpuRenderBlocked =
            didKeepDrawCommitPresentGpuRenderBlocked
        this.didKeepAttachmentPlanningFactsDehydrated =
            didKeepAttachmentPlanningFactsDehydrated
    }
}

struct CjguiInternalRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness {
    let descriptorCreateDestroyReadiness:
        CjguiInternalRendererNoRenderPassDescriptorCreateDestroyReadiness
    let attachmentPlanningObservation:
        CjguiInternalRendererRenderPassDescriptorColorAttachmentPlanningObservation
    let didPrepareRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness:
        Bool
    let shouldDeferRendererNoRenderPassDescriptorColorAttachmentImplementation:
        Bool
    let shouldReportRendererRenderPassDescriptorColorAttachmentBlocked: Bool
    let didPreserveRendererRenderPassDescriptorCreateDestroyReadiness: Bool
    let didConfirmDescriptorLifecycleReadyForPlanningOnly: Bool
    let didConfirmProductionDrawableTextureLifecycleMissing: Bool
    let didConfirmIsolatedDrawableCannotConfigureProductionDescriptor: Bool
    let didConfirmDescriptorDrawableCleanupStillUnproven: Bool
    let didConfirmColorAttachmentConfigurationStillBlocked: Bool
    let didConfirmEncoderCreationStillBlocked: Bool
    let didConfirmNoEncoderDrawCommitPresentGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepColorAttachmentPlanningReadinessDehydrated: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        descriptorCreateDestroyReadiness:
            CjguiInternalRendererNoRenderPassDescriptorCreateDestroyReadiness,
        attachmentPlanningObservation:
            CjguiInternalRendererRenderPassDescriptorColorAttachmentPlanningObservation,
        didPrepareRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness:
            Bool,
        shouldDeferRendererNoRenderPassDescriptorColorAttachmentImplementation:
            Bool,
        shouldReportRendererRenderPassDescriptorColorAttachmentBlocked: Bool,
        didPreserveRendererRenderPassDescriptorCreateDestroyReadiness: Bool,
        didConfirmDescriptorLifecycleReadyForPlanningOnly: Bool,
        didConfirmProductionDrawableTextureLifecycleMissing: Bool,
        didConfirmIsolatedDrawableCannotConfigureProductionDescriptor: Bool,
        didConfirmDescriptorDrawableCleanupStillUnproven: Bool,
        didConfirmColorAttachmentConfigurationStillBlocked: Bool,
        didConfirmEncoderCreationStillBlocked: Bool,
        didConfirmNoEncoderDrawCommitPresentGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepColorAttachmentPlanningReadinessDehydrated: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.descriptorCreateDestroyReadiness =
            descriptorCreateDestroyReadiness
        this.attachmentPlanningObservation = attachmentPlanningObservation
        this.didPrepareRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness =
            didPrepareRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness
        this.shouldDeferRendererNoRenderPassDescriptorColorAttachmentImplementation =
            shouldDeferRendererNoRenderPassDescriptorColorAttachmentImplementation
        this.shouldReportRendererRenderPassDescriptorColorAttachmentBlocked =
            shouldReportRendererRenderPassDescriptorColorAttachmentBlocked
        this.didPreserveRendererRenderPassDescriptorCreateDestroyReadiness =
            didPreserveRendererRenderPassDescriptorCreateDestroyReadiness
        this.didConfirmDescriptorLifecycleReadyForPlanningOnly =
            didConfirmDescriptorLifecycleReadyForPlanningOnly
        this.didConfirmProductionDrawableTextureLifecycleMissing =
            didConfirmProductionDrawableTextureLifecycleMissing
        this.didConfirmIsolatedDrawableCannotConfigureProductionDescriptor =
            didConfirmIsolatedDrawableCannotConfigureProductionDescriptor
        this.didConfirmDescriptorDrawableCleanupStillUnproven =
            didConfirmDescriptorDrawableCleanupStillUnproven
        this.didConfirmColorAttachmentConfigurationStillBlocked =
            didConfirmColorAttachmentConfigurationStillBlocked
        this.didConfirmEncoderCreationStillBlocked =
            didConfirmEncoderCreationStillBlocked
        this.didConfirmNoEncoderDrawCommitPresentGpuOrRender =
            didConfirmNoEncoderDrawCommitPresentGpuOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepColorAttachmentPlanningReadinessDehydrated =
            didKeepColorAttachmentPlanningReadinessDehydrated
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildDefaultRendererRenderPassDescriptorColorAttachmentPlanningObservation():
    CjguiInternalRendererRenderPassDescriptorColorAttachmentPlanningObservation {
    return CjguiInternalRendererRenderPassDescriptorColorAttachmentPlanningObservation(
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

func cjguiInternalBuildRendererRenderPassDescriptorColorAttachmentPlanningReadiness(
    descriptorCreateDestroyReadiness:
        CjguiInternalRendererNoRenderPassDescriptorCreateDestroyReadiness,
    attachmentPlanningObservation:
        CjguiInternalRendererRenderPassDescriptorColorAttachmentPlanningObservation
): CjguiInternalRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness {
    let descriptorTailReady =
        descriptorCreateDestroyReadiness
            .didPrepareRendererNoRenderPassDescriptorCreateDestroyReadiness &&
        descriptorCreateDestroyReadiness
            .didConfirmTokenBackedRenderPassDescriptorCreateDestroy &&
        descriptorCreateDestroyReadiness.didConfirmColorAttachmentStillBlocked &&
        descriptorCreateDestroyReadiness.didConfirmDrawableTextureStillBlocked &&
        descriptorCreateDestroyReadiness.didConfirmEncoderCreationStillBlocked &&
        descriptorCreateDestroyReadiness
            .didConfirmNoEncoderDrawCommitPresentGpuOrRender &&
        descriptorCreateDestroyReadiness.didConfirmNoPublicSurface &&
        descriptorCreateDestroyReadiness.didConfirmNoRendererStateWrite &&
        descriptorCreateDestroyReadiness.didConfirmNoBackendReadyTruth
    let planningReady =
        descriptorTailReady &&
        attachmentPlanningObservation.didObserveDescriptorCreateDestroyTail &&
        attachmentPlanningObservation
            .didRequireProductionDrawableTextureLifecycle &&
        attachmentPlanningObservation.didRejectIsolatedDrawableAsProductionTruth &&
        attachmentPlanningObservation.didRequireDescriptorDrawableCleanupProof &&
        attachmentPlanningObservation.didKeepColorAttachmentConfigurationBlocked &&
        attachmentPlanningObservation.didKeepEncoderCreationBlocked &&
        attachmentPlanningObservation
            .didKeepDrawCommitPresentGpuRenderBlocked &&
        attachmentPlanningObservation.didKeepAttachmentPlanningFactsDehydrated

    return CjguiInternalRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness(
        descriptorCreateDestroyReadiness,
        attachmentPlanningObservation,
        planningReady,
        true,
        true,
        descriptorTailReady,
        descriptorTailReady &&
            attachmentPlanningObservation.didObserveDescriptorCreateDestroyTail,
        attachmentPlanningObservation
            .didRequireProductionDrawableTextureLifecycle,
        attachmentPlanningObservation.didRejectIsolatedDrawableAsProductionTruth,
        attachmentPlanningObservation.didRequireDescriptorDrawableCleanupProof,
        attachmentPlanningObservation.didKeepColorAttachmentConfigurationBlocked,
        attachmentPlanningObservation.didKeepEncoderCreationBlocked,
        attachmentPlanningObservation.didKeepDrawCommitPresentGpuRenderBlocked,
        true,
        true,
        true,
        true,
        attachmentPlanningObservation.didKeepAttachmentPlanningFactsDehydrated,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererRenderPassDescriptorColorAttachmentPlanningDraft():
    CjguiInternalRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness {
    let descriptorCreateDestroyReadiness =
        cjguiInternalExecuteDefaultRendererRenderPassDescriptorCreateDestroyDraft()
    let attachmentPlanningObservation =
        cjguiInternalBuildDefaultRendererRenderPassDescriptorColorAttachmentPlanningObservation()
    return cjguiInternalBuildRendererRenderPassDescriptorColorAttachmentPlanningReadiness(
        descriptorCreateDestroyReadiness,
        attachmentPlanningObservation
    )
}
