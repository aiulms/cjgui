// 中文维护注释：本文件是 vertex buffer / draw input no-submit planning owner。
// Truth: 只消费 CjguiInternalRendererNoPipelineStateRuntimeCallReadiness，
// 固定 MTLBuffer token lifecycle、vertex layout 与 no-encoder/no-draw 合同。
// Stop-line: 不创建或绑定 render command encoder，不调用 setVertexBuffer，
// 不 draw，不创建 index buffer，不 commit，不 present，不提交 GPU work，
// 不执行 render，不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: vertex buffer planning facts 不得包装成 draw
// permission、render permission、GPU submission、backend-ready、state write、
// receipt、record 或 publication。
package cjgui

struct CjguiInternalRendererVertexBufferNoSubmitPlanningFacts {
    let pipelineStateRuntimeReadiness:
        CjguiInternalRendererNoPipelineStateRuntimeCallReadiness
    let didConfirmVertexLayoutRequirement: Bool
    let didConfirmBufferCreationCanStayNoSubmit: Bool
    let didConfirmEncoderBindingStillBlocked: Bool
    let didConfirmSetVertexBufferStillBlocked: Bool
    let didConfirmDrawStillBlocked: Bool
    let didConfirmCommitPresentGpuRenderStillBlocked: Bool
    let didConfirmNoPointerHandleClassIdReturnPolicy: Bool

    init(
        pipelineStateRuntimeReadiness:
            CjguiInternalRendererNoPipelineStateRuntimeCallReadiness,
        didConfirmVertexLayoutRequirement: Bool,
        didConfirmBufferCreationCanStayNoSubmit: Bool,
        didConfirmEncoderBindingStillBlocked: Bool,
        didConfirmSetVertexBufferStillBlocked: Bool,
        didConfirmDrawStillBlocked: Bool,
        didConfirmCommitPresentGpuRenderStillBlocked: Bool,
        didConfirmNoPointerHandleClassIdReturnPolicy: Bool
    ) {
        this.pipelineStateRuntimeReadiness = pipelineStateRuntimeReadiness
        this.didConfirmVertexLayoutRequirement =
            didConfirmVertexLayoutRequirement
        this.didConfirmBufferCreationCanStayNoSubmit =
            didConfirmBufferCreationCanStayNoSubmit
        this.didConfirmEncoderBindingStillBlocked =
            didConfirmEncoderBindingStillBlocked
        this.didConfirmSetVertexBufferStillBlocked =
            didConfirmSetVertexBufferStillBlocked
        this.didConfirmDrawStillBlocked = didConfirmDrawStillBlocked
        this.didConfirmCommitPresentGpuRenderStillBlocked =
            didConfirmCommitPresentGpuRenderStillBlocked
        this.didConfirmNoPointerHandleClassIdReturnPolicy =
            didConfirmNoPointerHandleClassIdReturnPolicy
    }
}

struct CjguiInternalRendererNoVertexBufferNoSubmitPlanningReadiness {
    let pipelineStateRuntimeReadiness:
        CjguiInternalRendererNoPipelineStateRuntimeCallReadiness
    let planningFacts:
        CjguiInternalRendererVertexBufferNoSubmitPlanningFacts
    let didPrepareRendererNoVertexBufferNoSubmitPlanningReadiness: Bool
    let shouldDeferRendererNoVertexBufferNoSubmitPlanningReadiness: Bool
    let didConfirmVertexDataContract: Bool
    let didConfirmBufferLifecycleCanStayNoSubmit: Bool
    let didConfirmNoEncoderBinding: Bool
    let didConfirmNoSetVertexBuffer: Bool
    let didConfirmNoDrawCommitPresentGpuOrRender: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepVertexBufferPlanningReadinessDehydrated: Bool
    let didAvoidDrawPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        pipelineStateRuntimeReadiness:
            CjguiInternalRendererNoPipelineStateRuntimeCallReadiness,
        planningFacts:
            CjguiInternalRendererVertexBufferNoSubmitPlanningFacts,
        didPrepareRendererNoVertexBufferNoSubmitPlanningReadiness: Bool,
        shouldDeferRendererNoVertexBufferNoSubmitPlanningReadiness: Bool,
        didConfirmVertexDataContract: Bool,
        didConfirmBufferLifecycleCanStayNoSubmit: Bool,
        didConfirmNoEncoderBinding: Bool,
        didConfirmNoSetVertexBuffer: Bool,
        didConfirmNoDrawCommitPresentGpuOrRender: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepVertexBufferPlanningReadinessDehydrated: Bool,
        didAvoidDrawPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.pipelineStateRuntimeReadiness = pipelineStateRuntimeReadiness
        this.planningFacts = planningFacts
        this.didPrepareRendererNoVertexBufferNoSubmitPlanningReadiness =
            didPrepareRendererNoVertexBufferNoSubmitPlanningReadiness
        this.shouldDeferRendererNoVertexBufferNoSubmitPlanningReadiness =
            shouldDeferRendererNoVertexBufferNoSubmitPlanningReadiness
        this.didConfirmVertexDataContract = didConfirmVertexDataContract
        this.didConfirmBufferLifecycleCanStayNoSubmit =
            didConfirmBufferLifecycleCanStayNoSubmit
        this.didConfirmNoEncoderBinding = didConfirmNoEncoderBinding
        this.didConfirmNoSetVertexBuffer = didConfirmNoSetVertexBuffer
        this.didConfirmNoDrawCommitPresentGpuOrRender =
            didConfirmNoDrawCommitPresentGpuOrRender
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepVertexBufferPlanningReadinessDehydrated =
            didKeepVertexBufferPlanningReadinessDehydrated
        this.didAvoidDrawPermissionWrapper = didAvoidDrawPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
    }
}

func cjguiInternalBuildRendererVertexBufferNoSubmitPlanningReadiness(
    pipelineStateRuntimeReadiness:
        CjguiInternalRendererNoPipelineStateRuntimeCallReadiness
): CjguiInternalRendererNoVertexBufferNoSubmitPlanningReadiness {
    let upstreamReady =
        pipelineStateRuntimeReadiness
            .didPrepareRendererNoPipelineStateRuntimeCallReadiness &&
        pipelineStateRuntimeReadiness.didConfirmRuntimeInternalCallExecuted &&
        pipelineStateRuntimeReadiness.didConfirmCreateClassifyDestroyCleanup &&
        pipelineStateRuntimeReadiness.didConfirmNoPublicSurface &&
        pipelineStateRuntimeReadiness.didConfirmNoRendererStateWrite &&
        pipelineStateRuntimeReadiness.didConfirmNoBackendReadyTruth
    let planningFacts =
        CjguiInternalRendererVertexBufferNoSubmitPlanningFacts(
            pipelineStateRuntimeReadiness,
            upstreamReady,
            true,
            true,
            true,
            true,
            true,
            true
        )
    let readinessReady =
        upstreamReady &&
        planningFacts.didConfirmVertexLayoutRequirement &&
        planningFacts.didConfirmBufferCreationCanStayNoSubmit &&
        planningFacts.didConfirmEncoderBindingStillBlocked &&
        planningFacts.didConfirmSetVertexBufferStillBlocked &&
        planningFacts.didConfirmDrawStillBlocked &&
        planningFacts.didConfirmCommitPresentGpuRenderStillBlocked &&
        planningFacts.didConfirmNoPointerHandleClassIdReturnPolicy

    return CjguiInternalRendererNoVertexBufferNoSubmitPlanningReadiness(
        pipelineStateRuntimeReadiness,
        planningFacts,
        readinessReady,
        !readinessReady,
        planningFacts.didConfirmVertexLayoutRequirement,
        planningFacts.didConfirmBufferCreationCanStayNoSubmit,
        planningFacts.didConfirmEncoderBindingStillBlocked,
        planningFacts.didConfirmSetVertexBufferStillBlocked,
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

func cjguiInternalExecuteDefaultRendererVertexBufferNoSubmitPlanningDraft():
    CjguiInternalRendererNoVertexBufferNoSubmitPlanningReadiness {
    let pipelineStateRuntimeReadiness =
        cjguiInternalExecuteDefaultRendererPipelineStateRuntimeCallDraft()
    return cjguiInternalBuildRendererVertexBufferNoSubmitPlanningReadiness(
        pipelineStateRuntimeReadiness
    )
}
