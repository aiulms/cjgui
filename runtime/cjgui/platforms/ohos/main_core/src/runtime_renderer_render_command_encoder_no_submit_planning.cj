// 维护注释：本文件是 MTLRenderCommandEncoder no-submit planning owner。
// Truth: 只消费 CjguiInternalRendererNoCommandBufferRuntimeCallReadiness，
// 将 descriptor attachment、production drawable texture lifetime 与 encoder
// creation 缺口脱水为 internal planning facts。
// Stop-line: 不创建 encoder，不调用 renderCommandEncoderWithDescriptor，
// 不 draw，不创建 pipeline / vertex buffer，不 commit，不 present，不提交 GPU work，
// 不执行 render，不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: no-submit planning facts 不得包装成 render permission、
// GPU submission、backend-ready、state write、receipt、record 或 publication。
package cjgui

struct CjguiInternalRendererRenderCommandEncoderNoSubmitPlanningObservation {
    let didObserveCommandBufferRuntimeCallTail: Bool
    let didConfirmRenderPassDescriptorAttachmentMissing: Bool
    let didConfirmProductionDrawableTextureLifetimeMissing: Bool
    let didConfirmEncoderCreationStillBlocked: Bool
    let didConfirmDrawPipelineAndVertexBufferStillBlocked: Bool
    let didConfirmCommitPresentGpuSubmitAndRenderStillBlocked: Bool
    let didKeepDrawableLifetimeRecoverySeparate: Bool
    let didKeepNoSubmitPlanningFactsDehydrated: Bool

    init(
        didObserveCommandBufferRuntimeCallTail: Bool,
        didConfirmRenderPassDescriptorAttachmentMissing: Bool,
        didConfirmProductionDrawableTextureLifetimeMissing: Bool,
        didConfirmEncoderCreationStillBlocked: Bool,
        didConfirmDrawPipelineAndVertexBufferStillBlocked: Bool,
        didConfirmCommitPresentGpuSubmitAndRenderStillBlocked: Bool,
        didKeepDrawableLifetimeRecoverySeparate: Bool,
        didKeepNoSubmitPlanningFactsDehydrated: Bool
    ) {
        this.didObserveCommandBufferRuntimeCallTail =
            didObserveCommandBufferRuntimeCallTail
        this.didConfirmRenderPassDescriptorAttachmentMissing =
            didConfirmRenderPassDescriptorAttachmentMissing
        this.didConfirmProductionDrawableTextureLifetimeMissing =
            didConfirmProductionDrawableTextureLifetimeMissing
        this.didConfirmEncoderCreationStillBlocked =
            didConfirmEncoderCreationStillBlocked
        this.didConfirmDrawPipelineAndVertexBufferStillBlocked =
            didConfirmDrawPipelineAndVertexBufferStillBlocked
        this.didConfirmCommitPresentGpuSubmitAndRenderStillBlocked =
            didConfirmCommitPresentGpuSubmitAndRenderStillBlocked
        this.didKeepDrawableLifetimeRecoverySeparate =
            didKeepDrawableLifetimeRecoverySeparate
        this.didKeepNoSubmitPlanningFactsDehydrated =
            didKeepNoSubmitPlanningFactsDehydrated
    }
}

struct CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness {
    let commandBufferRuntimeCallReadiness:
        CjguiInternalRendererNoCommandBufferRuntimeCallReadiness
    let noSubmitPlanningObservation:
        CjguiInternalRendererRenderCommandEncoderNoSubmitPlanningObservation
    let didPrepareRendererNoRenderCommandEncoderNoSubmitPlanningReadiness: Bool
    let shouldDeferRendererRenderCommandEncoderCreation: Bool
    let shouldReportRendererRenderCommandEncoderNoSubmitPlanningBlocked: Bool
    let didPreserveRendererCommandBufferRuntimeCallReadiness: Bool
    let didConfirmDescriptorAttachmentMissing: Bool
    let didConfirmProductionDrawableTextureLifetimeMissing: Bool
    let didConfirmEncoderCreationStillBlocked: Bool
    let didConfirmNoEncoderCreation: Bool
    let didConfirmDrawStillBlocked: Bool
    let didConfirmPipelineStateAndVertexBufferStillBlocked: Bool
    let didConfirmCommitPresentGpuSubmissionStillBlocked: Bool
    let didConfirmNoDrawCommitPresentGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepRenderCommandEncoderNoSubmitPlanningReadinessDehydrated: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        commandBufferRuntimeCallReadiness:
            CjguiInternalRendererNoCommandBufferRuntimeCallReadiness,
        noSubmitPlanningObservation:
            CjguiInternalRendererRenderCommandEncoderNoSubmitPlanningObservation,
        didPrepareRendererNoRenderCommandEncoderNoSubmitPlanningReadiness:
            Bool,
        shouldDeferRendererRenderCommandEncoderCreation: Bool,
        shouldReportRendererRenderCommandEncoderNoSubmitPlanningBlocked: Bool,
        didPreserveRendererCommandBufferRuntimeCallReadiness: Bool,
        didConfirmDescriptorAttachmentMissing: Bool,
        didConfirmProductionDrawableTextureLifetimeMissing: Bool,
        didConfirmEncoderCreationStillBlocked: Bool,
        didConfirmNoEncoderCreation: Bool,
        didConfirmDrawStillBlocked: Bool,
        didConfirmPipelineStateAndVertexBufferStillBlocked: Bool,
        didConfirmCommitPresentGpuSubmissionStillBlocked: Bool,
        didConfirmNoDrawCommitPresentGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepRenderCommandEncoderNoSubmitPlanningReadinessDehydrated: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.commandBufferRuntimeCallReadiness =
            commandBufferRuntimeCallReadiness
        this.noSubmitPlanningObservation = noSubmitPlanningObservation
        this.didPrepareRendererNoRenderCommandEncoderNoSubmitPlanningReadiness =
            didPrepareRendererNoRenderCommandEncoderNoSubmitPlanningReadiness
        this.shouldDeferRendererRenderCommandEncoderCreation =
            shouldDeferRendererRenderCommandEncoderCreation
        this.shouldReportRendererRenderCommandEncoderNoSubmitPlanningBlocked =
            shouldReportRendererRenderCommandEncoderNoSubmitPlanningBlocked
        this.didPreserveRendererCommandBufferRuntimeCallReadiness =
            didPreserveRendererCommandBufferRuntimeCallReadiness
        this.didConfirmDescriptorAttachmentMissing =
            didConfirmDescriptorAttachmentMissing
        this.didConfirmProductionDrawableTextureLifetimeMissing =
            didConfirmProductionDrawableTextureLifetimeMissing
        this.didConfirmEncoderCreationStillBlocked =
            didConfirmEncoderCreationStillBlocked
        this.didConfirmNoEncoderCreation = didConfirmNoEncoderCreation
        this.didConfirmDrawStillBlocked = didConfirmDrawStillBlocked
        this.didConfirmPipelineStateAndVertexBufferStillBlocked =
            didConfirmPipelineStateAndVertexBufferStillBlocked
        this.didConfirmCommitPresentGpuSubmissionStillBlocked =
            didConfirmCommitPresentGpuSubmissionStillBlocked
        this.didConfirmNoDrawCommitPresentGpuOrRender =
            didConfirmNoDrawCommitPresentGpuOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepRenderCommandEncoderNoSubmitPlanningReadinessDehydrated =
            didKeepRenderCommandEncoderNoSubmitPlanningReadinessDehydrated
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildDefaultRendererRenderCommandEncoderNoSubmitPlanningObservation():
    CjguiInternalRendererRenderCommandEncoderNoSubmitPlanningObservation {
    return CjguiInternalRendererRenderCommandEncoderNoSubmitPlanningObservation(
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

func cjguiInternalBuildRendererRenderCommandEncoderNoSubmitPlanningReadiness(
    commandBufferRuntimeCallReadiness:
        CjguiInternalRendererNoCommandBufferRuntimeCallReadiness,
    noSubmitPlanningObservation:
        CjguiInternalRendererRenderCommandEncoderNoSubmitPlanningObservation
): CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness {
    let commandBufferTailReady =
        commandBufferRuntimeCallReadiness
            .didPrepareRendererNoCommandBufferRuntimeCallReadiness &&
        commandBufferRuntimeCallReadiness.didConfirmRuntimeInternalCallExecuted &&
        commandBufferRuntimeCallReadiness
            .didConfirmCommandBufferCreateClassifyDestroyLifecycle &&
        commandBufferRuntimeCallReadiness.didConfirmCommitStillBlocked &&
        commandBufferRuntimeCallReadiness
            .didConfirmEncoderCreationStillBlocked &&
        commandBufferRuntimeCallReadiness
            .didConfirmNoPresentGpuSubmissionOrRender &&
        commandBufferRuntimeCallReadiness.didConfirmNoPointerHandleClassIdReturn &&
        commandBufferRuntimeCallReadiness.didConfirmNoPublicSurface &&
        commandBufferRuntimeCallReadiness.didConfirmNoRendererStateWrite &&
        commandBufferRuntimeCallReadiness.didConfirmNoBackendReadyTruth
    let planningReady =
        commandBufferTailReady &&
        noSubmitPlanningObservation.didObserveCommandBufferRuntimeCallTail &&
        noSubmitPlanningObservation
            .didConfirmRenderPassDescriptorAttachmentMissing &&
        noSubmitPlanningObservation
            .didConfirmProductionDrawableTextureLifetimeMissing &&
        noSubmitPlanningObservation.didConfirmEncoderCreationStillBlocked &&
        noSubmitPlanningObservation
            .didConfirmDrawPipelineAndVertexBufferStillBlocked &&
        noSubmitPlanningObservation
            .didConfirmCommitPresentGpuSubmitAndRenderStillBlocked &&
        noSubmitPlanningObservation.didKeepDrawableLifetimeRecoverySeparate &&
        noSubmitPlanningObservation.didKeepNoSubmitPlanningFactsDehydrated

    return CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness(
        commandBufferRuntimeCallReadiness,
        noSubmitPlanningObservation,
        planningReady,
        true,
        !planningReady,
        commandBufferTailReady,
        noSubmitPlanningObservation
            .didConfirmRenderPassDescriptorAttachmentMissing,
        noSubmitPlanningObservation
            .didConfirmProductionDrawableTextureLifetimeMissing,
        commandBufferRuntimeCallReadiness
            .didConfirmEncoderCreationStillBlocked &&
            noSubmitPlanningObservation.didConfirmEncoderCreationStillBlocked,
        true,
        true,
        noSubmitPlanningObservation
            .didConfirmDrawPipelineAndVertexBufferStillBlocked,
        commandBufferRuntimeCallReadiness.didConfirmCommitStillBlocked &&
            noSubmitPlanningObservation
                .didConfirmCommitPresentGpuSubmitAndRenderStillBlocked,
        commandBufferRuntimeCallReadiness
            .didConfirmNoPresentGpuSubmissionOrRender &&
            noSubmitPlanningObservation
                .didConfirmCommitPresentGpuSubmitAndRenderStillBlocked,
        true,
        true,
        true,
        true,
        noSubmitPlanningObservation.didKeepNoSubmitPlanningFactsDehydrated,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererRenderCommandEncoderNoSubmitPlanningDraft():
    CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness {
    let commandBufferRuntimeCallReadiness =
        cjguiInternalExecuteDefaultRendererCommandBufferRuntimeCallDraft()
    let noSubmitPlanningObservation =
        cjguiInternalBuildDefaultRendererRenderCommandEncoderNoSubmitPlanningObservation()
    return cjguiInternalBuildRendererRenderCommandEncoderNoSubmitPlanningReadiness(
        commandBufferRuntimeCallReadiness,
        noSubmitPlanningObservation
    )
}
