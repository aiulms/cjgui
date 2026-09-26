// 中文维护注释：本文件是 pipeline descriptor no-draw planning owner。
// Truth: 只消费 CjguiInternalRendererNoPipelineStateNoDrawPlanningReadiness，
// 固定 MTLRenderPipelineDescriptor 的 no-draw planning / requirement facts。
// Stop-line: 不创建 pipeline descriptor / pipeline state / shader library /
// shader function，不创建或绑定 encoder，不调用 setRenderPipelineState，不 draw，
// 不创建 vertex buffer，不 commit，不 present，不提交 GPU work，不执行 render，
// 不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: pipeline descriptor planning facts 不得包装成
// render permission、GPU submission、backend-ready、state write、receipt、record
// 或 publication。
package cjgui

struct CjguiInternalRendererPipelineDescriptorPlanningObservation {
    let didObservePipelineStateNoDrawPlanningTail: Bool
    let didConfirmDescriptorRequirement: Bool
    let didConfirmPixelFormatRequirement: Bool
    let didConfirmSampleCountRequirement: Bool
    let didConfirmShaderLibraryStillBlocked: Bool
    let didConfirmVertexFunctionStillBlocked: Bool
    let didConfirmFragmentFunctionStillBlocked: Bool
    let didConfirmBlendingStillBlocked: Bool
    let didConfirmPipelineStateCreationStillBlocked: Bool
    let didConfirmEncoderBindingStillBlocked: Bool
    let didKeepPipelineDescriptorPlanningFactsDehydrated: Bool

    init(
        didObservePipelineStateNoDrawPlanningTail: Bool,
        didConfirmDescriptorRequirement: Bool,
        didConfirmPixelFormatRequirement: Bool,
        didConfirmSampleCountRequirement: Bool,
        didConfirmShaderLibraryStillBlocked: Bool,
        didConfirmVertexFunctionStillBlocked: Bool,
        didConfirmFragmentFunctionStillBlocked: Bool,
        didConfirmBlendingStillBlocked: Bool,
        didConfirmPipelineStateCreationStillBlocked: Bool,
        didConfirmEncoderBindingStillBlocked: Bool,
        didKeepPipelineDescriptorPlanningFactsDehydrated: Bool
    ) {
        this.didObservePipelineStateNoDrawPlanningTail =
            didObservePipelineStateNoDrawPlanningTail
        this.didConfirmDescriptorRequirement =
            didConfirmDescriptorRequirement
        this.didConfirmPixelFormatRequirement =
            didConfirmPixelFormatRequirement
        this.didConfirmSampleCountRequirement =
            didConfirmSampleCountRequirement
        this.didConfirmShaderLibraryStillBlocked =
            didConfirmShaderLibraryStillBlocked
        this.didConfirmVertexFunctionStillBlocked =
            didConfirmVertexFunctionStillBlocked
        this.didConfirmFragmentFunctionStillBlocked =
            didConfirmFragmentFunctionStillBlocked
        this.didConfirmBlendingStillBlocked = didConfirmBlendingStillBlocked
        this.didConfirmPipelineStateCreationStillBlocked =
            didConfirmPipelineStateCreationStillBlocked
        this.didConfirmEncoderBindingStillBlocked =
            didConfirmEncoderBindingStillBlocked
        this.didKeepPipelineDescriptorPlanningFactsDehydrated =
            didKeepPipelineDescriptorPlanningFactsDehydrated
    }
}

struct CjguiInternalRendererNoPipelineDescriptorPlanningReadiness {
    let pipelineStateNoDrawPlanningReadiness:
        CjguiInternalRendererNoPipelineStateNoDrawPlanningReadiness
    let planningObservation:
        CjguiInternalRendererPipelineDescriptorPlanningObservation
    let didPrepareRendererNoPipelineDescriptorPlanningReadiness: Bool
    let shouldDeferRendererPipelineDescriptorPlanning: Bool
    let shouldReportRendererPipelineDescriptorPlanningBlocked: Bool
    let didPreserveRendererPipelineStateNoDrawPlanningReadiness: Bool
    let didConfirmPipelineDescriptorRequirement: Bool
    let didConfirmNoDrawConfigurationPlan: Bool
    let didConfirmShaderLibraryAndFunctionStillBlocked: Bool
    let didConfirmPipelineStateCreationStillBlocked: Bool
    let didConfirmEncoderBindingStillBlocked: Bool
    let didConfirmNoDrawVertexBufferCommitPresentGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepPipelineDescriptorPlanningReadinessDehydrated: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        pipelineStateNoDrawPlanningReadiness:
            CjguiInternalRendererNoPipelineStateNoDrawPlanningReadiness,
        planningObservation:
            CjguiInternalRendererPipelineDescriptorPlanningObservation,
        didPrepareRendererNoPipelineDescriptorPlanningReadiness: Bool,
        shouldDeferRendererPipelineDescriptorPlanning: Bool,
        shouldReportRendererPipelineDescriptorPlanningBlocked: Bool,
        didPreserveRendererPipelineStateNoDrawPlanningReadiness: Bool,
        didConfirmPipelineDescriptorRequirement: Bool,
        didConfirmNoDrawConfigurationPlan: Bool,
        didConfirmShaderLibraryAndFunctionStillBlocked: Bool,
        didConfirmPipelineStateCreationStillBlocked: Bool,
        didConfirmEncoderBindingStillBlocked: Bool,
        didConfirmNoDrawVertexBufferCommitPresentGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepPipelineDescriptorPlanningReadinessDehydrated: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.pipelineStateNoDrawPlanningReadiness =
            pipelineStateNoDrawPlanningReadiness
        this.planningObservation = planningObservation
        this.didPrepareRendererNoPipelineDescriptorPlanningReadiness =
            didPrepareRendererNoPipelineDescriptorPlanningReadiness
        this.shouldDeferRendererPipelineDescriptorPlanning =
            shouldDeferRendererPipelineDescriptorPlanning
        this.shouldReportRendererPipelineDescriptorPlanningBlocked =
            shouldReportRendererPipelineDescriptorPlanningBlocked
        this.didPreserveRendererPipelineStateNoDrawPlanningReadiness =
            didPreserveRendererPipelineStateNoDrawPlanningReadiness
        this.didConfirmPipelineDescriptorRequirement =
            didConfirmPipelineDescriptorRequirement
        this.didConfirmNoDrawConfigurationPlan =
            didConfirmNoDrawConfigurationPlan
        this.didConfirmShaderLibraryAndFunctionStillBlocked =
            didConfirmShaderLibraryAndFunctionStillBlocked
        this.didConfirmPipelineStateCreationStillBlocked =
            didConfirmPipelineStateCreationStillBlocked
        this.didConfirmEncoderBindingStillBlocked =
            didConfirmEncoderBindingStillBlocked
        this.didConfirmNoDrawVertexBufferCommitPresentGpuOrRender =
            didConfirmNoDrawVertexBufferCommitPresentGpuOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepPipelineDescriptorPlanningReadinessDehydrated =
            didKeepPipelineDescriptorPlanningReadinessDehydrated
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildDefaultRendererPipelineDescriptorPlanningObservation():
    CjguiInternalRendererPipelineDescriptorPlanningObservation {
    return CjguiInternalRendererPipelineDescriptorPlanningObservation(
        true,
        true,
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

func cjguiInternalBuildRendererPipelineDescriptorPlanningReadiness(
    pipelineStateNoDrawPlanningReadiness:
        CjguiInternalRendererNoPipelineStateNoDrawPlanningReadiness,
    planningObservation:
        CjguiInternalRendererPipelineDescriptorPlanningObservation
): CjguiInternalRendererNoPipelineDescriptorPlanningReadiness {
    let upstreamReady =
        pipelineStateNoDrawPlanningReadiness
            .didPrepareRendererNoPipelineStateNoDrawPlanningReadiness &&
        pipelineStateNoDrawPlanningReadiness
            .didConfirmShaderLibraryAndFunctionPlanning &&
        pipelineStateNoDrawPlanningReadiness.didConfirmPipelineDescriptorPlanning &&
        pipelineStateNoDrawPlanningReadiness.didConfirmNoPipelineStateCreation &&
        pipelineStateNoDrawPlanningReadiness
            .didConfirmNoEncoderCreationOrBinding &&
        pipelineStateNoDrawPlanningReadiness
            .didConfirmNoSetRenderPipelineState &&
        pipelineStateNoDrawPlanningReadiness
            .didConfirmNoDrawVertexBufferCommitPresentGpuOrRender &&
        pipelineStateNoDrawPlanningReadiness.didConfirmNoPublicSurface &&
        pipelineStateNoDrawPlanningReadiness.didConfirmNoRendererStateWrite &&
        pipelineStateNoDrawPlanningReadiness.didConfirmNoBackendReadyTruth
    let descriptorPlanReady =
        planningObservation.didObservePipelineStateNoDrawPlanningTail &&
        planningObservation.didConfirmDescriptorRequirement &&
        planningObservation.didConfirmPixelFormatRequirement &&
        planningObservation.didConfirmSampleCountRequirement &&
        planningObservation.didConfirmShaderLibraryStillBlocked &&
        planningObservation.didConfirmVertexFunctionStillBlocked &&
        planningObservation.didConfirmFragmentFunctionStillBlocked &&
        planningObservation.didConfirmBlendingStillBlocked &&
        planningObservation.didConfirmPipelineStateCreationStillBlocked &&
        planningObservation.didConfirmEncoderBindingStillBlocked &&
        planningObservation.didKeepPipelineDescriptorPlanningFactsDehydrated
    let readinessReady = upstreamReady && descriptorPlanReady

    return CjguiInternalRendererNoPipelineDescriptorPlanningReadiness(
        pipelineStateNoDrawPlanningReadiness,
        planningObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        planningObservation.didConfirmDescriptorRequirement,
        planningObservation.didConfirmPixelFormatRequirement &&
            planningObservation.didConfirmSampleCountRequirement,
        planningObservation.didConfirmShaderLibraryStillBlocked &&
            planningObservation.didConfirmVertexFunctionStillBlocked &&
            planningObservation.didConfirmFragmentFunctionStillBlocked,
        planningObservation.didConfirmPipelineStateCreationStillBlocked,
        planningObservation.didConfirmEncoderBindingStillBlocked,
        true,
        true,
        true,
        true,
        true,
        planningObservation.didKeepPipelineDescriptorPlanningFactsDehydrated,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererPipelineDescriptorPlanningDraft():
    CjguiInternalRendererNoPipelineDescriptorPlanningReadiness {
    let pipelineStateNoDrawPlanningReadiness =
        cjguiInternalExecuteDefaultRendererPipelineStateNoDrawPlanningDraft()
    let planningObservation =
        cjguiInternalBuildDefaultRendererPipelineDescriptorPlanningObservation()
    return cjguiInternalBuildRendererPipelineDescriptorPlanningReadiness(
        pipelineStateNoDrawPlanningReadiness,
        planningObservation
    )
}
