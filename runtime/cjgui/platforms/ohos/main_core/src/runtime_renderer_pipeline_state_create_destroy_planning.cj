// 中文维护注释：本文件是 MTLRenderPipelineState create/destroy no-draw planning owner。
// Truth: 只消费 CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness，
// 固定 pipeline state lifecycle 前置条件与 no-encoder/no-draw 合同。
// Stop-line: 不创建或绑定 render command encoder，不 setRenderPipelineState，
// 不 draw，不创建 vertex buffer，不 commit，不 present，不提交 GPU work，
// 不执行 render，不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: pipeline state planning facts 不得包装成
// render permission、GPU submission、backend-ready、state write、receipt、record
// 或 publication。
package cjgui

struct CjguiInternalRendererPipelineStateCreateDestroyPlanningFacts {
    let shaderRuntimeReadiness:
        CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness
    let didConfirmDeviceDescriptorShaderFunctionPrerequisites: Bool
    let didConfirmPipelineStateCreateDestroyCanStayNoDraw: Bool
    let didConfirmEncoderBindingStillBlocked: Bool
    let didConfirmDrawStillBlocked: Bool
    let didConfirmCommitPresentGpuRenderStillBlocked: Bool
    let didConfirmNoPointerHandleClassIdReturnPolicy: Bool

    init(
        shaderRuntimeReadiness:
            CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness,
        didConfirmDeviceDescriptorShaderFunctionPrerequisites: Bool,
        didConfirmPipelineStateCreateDestroyCanStayNoDraw: Bool,
        didConfirmEncoderBindingStillBlocked: Bool,
        didConfirmDrawStillBlocked: Bool,
        didConfirmCommitPresentGpuRenderStillBlocked: Bool,
        didConfirmNoPointerHandleClassIdReturnPolicy: Bool
    ) {
        this.shaderRuntimeReadiness = shaderRuntimeReadiness
        this.didConfirmDeviceDescriptorShaderFunctionPrerequisites =
            didConfirmDeviceDescriptorShaderFunctionPrerequisites
        this.didConfirmPipelineStateCreateDestroyCanStayNoDraw =
            didConfirmPipelineStateCreateDestroyCanStayNoDraw
        this.didConfirmEncoderBindingStillBlocked =
            didConfirmEncoderBindingStillBlocked
        this.didConfirmDrawStillBlocked = didConfirmDrawStillBlocked
        this.didConfirmCommitPresentGpuRenderStillBlocked =
            didConfirmCommitPresentGpuRenderStillBlocked
        this.didConfirmNoPointerHandleClassIdReturnPolicy =
            didConfirmNoPointerHandleClassIdReturnPolicy
    }
}

struct CjguiInternalRendererNoPipelineStateCreateDestroyPlanningReadiness {
    let shaderRuntimeReadiness:
        CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness
    let planningFacts:
        CjguiInternalRendererPipelineStateCreateDestroyPlanningFacts
    let didPrepareRendererNoPipelineStateCreateDestroyPlanningReadiness: Bool
    let shouldDeferRendererNoPipelineStateCreateDestroyPlanningReadiness: Bool
    let didConfirmNoDrawPrerequisites: Bool
    let didConfirmNoEncoderBinding: Bool
    let didConfirmNoDrawCommitPresentGpuOrRender: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepPipelineStatePlanningReadinessDehydrated: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        shaderRuntimeReadiness:
            CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness,
        planningFacts:
            CjguiInternalRendererPipelineStateCreateDestroyPlanningFacts,
        didPrepareRendererNoPipelineStateCreateDestroyPlanningReadiness: Bool,
        shouldDeferRendererNoPipelineStateCreateDestroyPlanningReadiness: Bool,
        didConfirmNoDrawPrerequisites: Bool,
        didConfirmNoEncoderBinding: Bool,
        didConfirmNoDrawCommitPresentGpuOrRender: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepPipelineStatePlanningReadinessDehydrated: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.shaderRuntimeReadiness = shaderRuntimeReadiness
        this.planningFacts = planningFacts
        this.didPrepareRendererNoPipelineStateCreateDestroyPlanningReadiness =
            didPrepareRendererNoPipelineStateCreateDestroyPlanningReadiness
        this.shouldDeferRendererNoPipelineStateCreateDestroyPlanningReadiness =
            shouldDeferRendererNoPipelineStateCreateDestroyPlanningReadiness
        this.didConfirmNoDrawPrerequisites = didConfirmNoDrawPrerequisites
        this.didConfirmNoEncoderBinding = didConfirmNoEncoderBinding
        this.didConfirmNoDrawCommitPresentGpuOrRender =
            didConfirmNoDrawCommitPresentGpuOrRender
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepPipelineStatePlanningReadinessDehydrated =
            didKeepPipelineStatePlanningReadinessDehydrated
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
    }
}

func cjguiInternalBuildRendererPipelineStateCreateDestroyPlanningReadiness(
    shaderRuntimeReadiness:
        CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness
): CjguiInternalRendererNoPipelineStateCreateDestroyPlanningReadiness {
    let upstreamReady =
        shaderRuntimeReadiness.didPrepareRendererNoShaderLibraryRuntimeCallReadiness &&
        shaderRuntimeReadiness.didConfirmRuntimeInternalCallExecuted &&
        shaderRuntimeReadiness.didConfirmCreateLookupClassifyDestroyCleanup &&
        shaderRuntimeReadiness.didConfirmNoPublicSurface &&
        shaderRuntimeReadiness.didConfirmNoRendererStateWrite &&
        shaderRuntimeReadiness.didConfirmNoBackendReadyTruth
    let planningFacts =
        CjguiInternalRendererPipelineStateCreateDestroyPlanningFacts(
            shaderRuntimeReadiness,
            upstreamReady,
            true,
            true,
            true,
            true,
            true
        )
    let readinessReady =
        upstreamReady &&
        planningFacts.didConfirmDeviceDescriptorShaderFunctionPrerequisites &&
        planningFacts.didConfirmPipelineStateCreateDestroyCanStayNoDraw &&
        planningFacts.didConfirmEncoderBindingStillBlocked &&
        planningFacts.didConfirmDrawStillBlocked &&
        planningFacts.didConfirmCommitPresentGpuRenderStillBlocked &&
        planningFacts.didConfirmNoPointerHandleClassIdReturnPolicy

    return CjguiInternalRendererNoPipelineStateCreateDestroyPlanningReadiness(
        shaderRuntimeReadiness,
        planningFacts,
        readinessReady,
        !readinessReady,
        planningFacts.didConfirmDeviceDescriptorShaderFunctionPrerequisites,
        planningFacts.didConfirmEncoderBindingStillBlocked,
        planningFacts.didConfirmDrawStillBlocked &&
            planningFacts.didConfirmCommitPresentGpuRenderStillBlocked,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererPipelineStateCreateDestroyPlanningDraft():
    CjguiInternalRendererNoPipelineStateCreateDestroyPlanningReadiness {
    let shaderRuntimeReadiness =
        cjguiInternalExecuteDefaultRendererShaderLibraryRuntimeCallDraft()
    return cjguiInternalBuildRendererPipelineStateCreateDestroyPlanningReadiness(
        shaderRuntimeReadiness
    )
}
