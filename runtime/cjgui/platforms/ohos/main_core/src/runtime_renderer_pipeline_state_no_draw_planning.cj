// 维护注释：本文件是 pipeline state no-draw planning owner。
// Truth: 只消费 CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness，
// 将 shader/library/function、pipeline descriptor 与 pipeline state 前置条件脱水为
// internal planning facts。
// Stop-line: 不创建 pipeline state / descriptor / shader library / shader function，
// 不创建或绑定 encoder，不调用 setRenderPipelineState，不 draw，不创建 vertex buffer，
// 不 commit，不 present，不提交 GPU work，不执行 render，不写 runtime_state.cj，
// 不发布 public API。
// Same-shape Boundary Brake: no-draw pipeline facts 不得包装成 render permission、
// GPU submission、backend-ready、state write、receipt、record 或 publication。
package cjgui

struct CjguiInternalRendererPipelineStateNoDrawPlanningObservation {
    let didObserveRenderCommandEncoderNoSubmitPlanningTail: Bool
    let didConfirmShaderLibraryRequirement: Bool
    let didConfirmVertexFunctionRequirement: Bool
    let didConfirmFragmentFunctionRequirement: Bool
    let didConfirmPipelineDescriptorRequirement: Bool
    let didConfirmPipelineStateCreationDeferred: Bool
    let didConfirmEncoderBindingBlocked: Bool
    let didConfirmDrawStillBlocked: Bool
    let didConfirmCommitPresentGpuSubmitAndRenderStillBlocked: Bool
    let didKeepPipelineStateNoDrawPlanningFactsDehydrated: Bool

    init(
        didObserveRenderCommandEncoderNoSubmitPlanningTail: Bool,
        didConfirmShaderLibraryRequirement: Bool,
        didConfirmVertexFunctionRequirement: Bool,
        didConfirmFragmentFunctionRequirement: Bool,
        didConfirmPipelineDescriptorRequirement: Bool,
        didConfirmPipelineStateCreationDeferred: Bool,
        didConfirmEncoderBindingBlocked: Bool,
        didConfirmDrawStillBlocked: Bool,
        didConfirmCommitPresentGpuSubmitAndRenderStillBlocked: Bool,
        didKeepPipelineStateNoDrawPlanningFactsDehydrated: Bool
    ) {
        this.didObserveRenderCommandEncoderNoSubmitPlanningTail =
            didObserveRenderCommandEncoderNoSubmitPlanningTail
        this.didConfirmShaderLibraryRequirement =
            didConfirmShaderLibraryRequirement
        this.didConfirmVertexFunctionRequirement =
            didConfirmVertexFunctionRequirement
        this.didConfirmFragmentFunctionRequirement =
            didConfirmFragmentFunctionRequirement
        this.didConfirmPipelineDescriptorRequirement =
            didConfirmPipelineDescriptorRequirement
        this.didConfirmPipelineStateCreationDeferred =
            didConfirmPipelineStateCreationDeferred
        this.didConfirmEncoderBindingBlocked = didConfirmEncoderBindingBlocked
        this.didConfirmDrawStillBlocked = didConfirmDrawStillBlocked
        this.didConfirmCommitPresentGpuSubmitAndRenderStillBlocked =
            didConfirmCommitPresentGpuSubmitAndRenderStillBlocked
        this.didKeepPipelineStateNoDrawPlanningFactsDehydrated =
            didKeepPipelineStateNoDrawPlanningFactsDehydrated
    }
}

struct CjguiInternalRendererNoPipelineStateNoDrawPlanningReadiness {
    let renderCommandEncoderNoSubmitPlanningReadiness:
        CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness
    let noDrawPlanningObservation:
        CjguiInternalRendererPipelineStateNoDrawPlanningObservation
    let didPrepareRendererNoPipelineStateNoDrawPlanningReadiness: Bool
    let shouldDeferRendererPipelineStateNoDrawPlanning: Bool
    let shouldReportRendererPipelineStateNoDrawPlanningBlocked: Bool
    let didPreserveRendererRenderCommandEncoderNoSubmitPlanningReadiness: Bool
    let didConfirmShaderLibraryAndFunctionPlanning: Bool
    let didConfirmPipelineDescriptorPlanning: Bool
    let didConfirmPipelineStateCreateDestroyStillDeferred: Bool
    let didConfirmNoPipelineStateCreation: Bool
    let didConfirmNoEncoderCreationOrBinding: Bool
    let didConfirmNoSetRenderPipelineState: Bool
    let didConfirmNoDrawVertexBufferCommitPresentGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepPipelineStateNoDrawPlanningReadinessDehydrated: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        renderCommandEncoderNoSubmitPlanningReadiness:
            CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness,
        noDrawPlanningObservation:
            CjguiInternalRendererPipelineStateNoDrawPlanningObservation,
        didPrepareRendererNoPipelineStateNoDrawPlanningReadiness: Bool,
        shouldDeferRendererPipelineStateNoDrawPlanning: Bool,
        shouldReportRendererPipelineStateNoDrawPlanningBlocked: Bool,
        didPreserveRendererRenderCommandEncoderNoSubmitPlanningReadiness: Bool,
        didConfirmShaderLibraryAndFunctionPlanning: Bool,
        didConfirmPipelineDescriptorPlanning: Bool,
        didConfirmPipelineStateCreateDestroyStillDeferred: Bool,
        didConfirmNoPipelineStateCreation: Bool,
        didConfirmNoEncoderCreationOrBinding: Bool,
        didConfirmNoSetRenderPipelineState: Bool,
        didConfirmNoDrawVertexBufferCommitPresentGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepPipelineStateNoDrawPlanningReadinessDehydrated: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.renderCommandEncoderNoSubmitPlanningReadiness =
            renderCommandEncoderNoSubmitPlanningReadiness
        this.noDrawPlanningObservation = noDrawPlanningObservation
        this.didPrepareRendererNoPipelineStateNoDrawPlanningReadiness =
            didPrepareRendererNoPipelineStateNoDrawPlanningReadiness
        this.shouldDeferRendererPipelineStateNoDrawPlanning =
            shouldDeferRendererPipelineStateNoDrawPlanning
        this.shouldReportRendererPipelineStateNoDrawPlanningBlocked =
            shouldReportRendererPipelineStateNoDrawPlanningBlocked
        this.didPreserveRendererRenderCommandEncoderNoSubmitPlanningReadiness =
            didPreserveRendererRenderCommandEncoderNoSubmitPlanningReadiness
        this.didConfirmShaderLibraryAndFunctionPlanning =
            didConfirmShaderLibraryAndFunctionPlanning
        this.didConfirmPipelineDescriptorPlanning =
            didConfirmPipelineDescriptorPlanning
        this.didConfirmPipelineStateCreateDestroyStillDeferred =
            didConfirmPipelineStateCreateDestroyStillDeferred
        this.didConfirmNoPipelineStateCreation =
            didConfirmNoPipelineStateCreation
        this.didConfirmNoEncoderCreationOrBinding =
            didConfirmNoEncoderCreationOrBinding
        this.didConfirmNoSetRenderPipelineState =
            didConfirmNoSetRenderPipelineState
        this.didConfirmNoDrawVertexBufferCommitPresentGpuOrRender =
            didConfirmNoDrawVertexBufferCommitPresentGpuOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepPipelineStateNoDrawPlanningReadinessDehydrated =
            didKeepPipelineStateNoDrawPlanningReadinessDehydrated
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildDefaultRendererPipelineStateNoDrawPlanningObservation():
    CjguiInternalRendererPipelineStateNoDrawPlanningObservation {
    return CjguiInternalRendererPipelineStateNoDrawPlanningObservation(
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

func cjguiInternalBuildRendererPipelineStateNoDrawPlanningReadiness(
    renderCommandEncoderNoSubmitPlanningReadiness:
        CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness,
    noDrawPlanningObservation:
        CjguiInternalRendererPipelineStateNoDrawPlanningObservation
): CjguiInternalRendererNoPipelineStateNoDrawPlanningReadiness {
    let encoderNoSubmitPlanningReady =
        renderCommandEncoderNoSubmitPlanningReadiness
            .didPrepareRendererNoRenderCommandEncoderNoSubmitPlanningReadiness &&
        renderCommandEncoderNoSubmitPlanningReadiness
            .didConfirmEncoderCreationStillBlocked &&
        renderCommandEncoderNoSubmitPlanningReadiness
            .didConfirmNoEncoderCreation &&
        renderCommandEncoderNoSubmitPlanningReadiness.didConfirmDrawStillBlocked &&
        renderCommandEncoderNoSubmitPlanningReadiness
            .didConfirmPipelineStateAndVertexBufferStillBlocked &&
        renderCommandEncoderNoSubmitPlanningReadiness
            .didConfirmCommitPresentGpuSubmissionStillBlocked &&
        renderCommandEncoderNoSubmitPlanningReadiness
            .didConfirmNoDrawCommitPresentGpuOrRender &&
        renderCommandEncoderNoSubmitPlanningReadiness
            .didConfirmNoPointerHandleClassIdReturn &&
        renderCommandEncoderNoSubmitPlanningReadiness
            .didConfirmNoPublicSurface &&
        renderCommandEncoderNoSubmitPlanningReadiness
            .didConfirmNoRendererStateWrite &&
        renderCommandEncoderNoSubmitPlanningReadiness
            .didConfirmNoBackendReadyTruth
    let shaderPlanningReady =
        noDrawPlanningObservation.didConfirmShaderLibraryRequirement &&
        noDrawPlanningObservation.didConfirmVertexFunctionRequirement &&
        noDrawPlanningObservation.didConfirmFragmentFunctionRequirement
    let descriptorPlanningReady =
        noDrawPlanningObservation.didConfirmPipelineDescriptorRequirement
    let stopLineReady =
        noDrawPlanningObservation.didConfirmPipelineStateCreationDeferred &&
        noDrawPlanningObservation.didConfirmEncoderBindingBlocked &&
        noDrawPlanningObservation.didConfirmDrawStillBlocked &&
        noDrawPlanningObservation
            .didConfirmCommitPresentGpuSubmitAndRenderStillBlocked &&
        noDrawPlanningObservation
            .didKeepPipelineStateNoDrawPlanningFactsDehydrated
    let readinessReady =
        encoderNoSubmitPlanningReady &&
        noDrawPlanningObservation
            .didObserveRenderCommandEncoderNoSubmitPlanningTail &&
        shaderPlanningReady &&
        descriptorPlanningReady &&
        stopLineReady

    return CjguiInternalRendererNoPipelineStateNoDrawPlanningReadiness(
        renderCommandEncoderNoSubmitPlanningReadiness,
        noDrawPlanningObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        encoderNoSubmitPlanningReady,
        shaderPlanningReady,
        descriptorPlanningReady,
        noDrawPlanningObservation.didConfirmPipelineStateCreationDeferred,
        true,
        noDrawPlanningObservation.didConfirmEncoderBindingBlocked,
        true,
        noDrawPlanningObservation.didConfirmDrawStillBlocked &&
            noDrawPlanningObservation
                .didConfirmCommitPresentGpuSubmitAndRenderStillBlocked,
        true,
        true,
        true,
        true,
        noDrawPlanningObservation
            .didKeepPipelineStateNoDrawPlanningFactsDehydrated,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererPipelineStateNoDrawPlanningDraft():
    CjguiInternalRendererNoPipelineStateNoDrawPlanningReadiness {
    let renderCommandEncoderNoSubmitPlanningReadiness =
        cjguiInternalExecuteDefaultRendererRenderCommandEncoderNoSubmitPlanningDraft()
    let noDrawPlanningObservation =
        cjguiInternalBuildDefaultRendererPipelineStateNoDrawPlanningObservation()
    return cjguiInternalBuildRendererPipelineStateNoDrawPlanningReadiness(
        renderCommandEncoderNoSubmitPlanningReadiness,
        noDrawPlanningObservation
    )
}
