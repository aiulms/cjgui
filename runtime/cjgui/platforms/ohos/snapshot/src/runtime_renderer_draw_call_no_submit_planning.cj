// 中文维护注释：本文件是 draw call no-submit planning owner。
// Truth: 只消费 CjguiInternalRendererNoVertexBufferRuntimeCallReadiness，
// 固定 pipeline state / vertex buffer 已具备、encoder 仍缺失的 draw input 合同。
// Stop-line: 不创建 render command encoder，不调用 setVertexBuffer 或
// setRenderPipelineState，不 draw，不创建 index buffer，不 commit，不 present，
// 不提交 GPU work，不执行 render，不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: draw call planning facts 不得包装成 draw
// permission、render permission、GPU submission、backend-ready、state write、
// receipt、record 或 publication。
package cjgui

struct CjguiInternalRendererDrawCallNoSubmitPlanningFacts {
    let vertexBufferRuntimeReadiness:
        CjguiInternalRendererNoVertexBufferRuntimeCallReadiness
    let didConfirmPipelineStateFactsAvailable: Bool
    let didConfirmVertexBufferFactsAvailable: Bool
    let didConfirmRenderCommandEncoderMissing: Bool
    let didConfirmPipelineBindingBlocked: Bool
    let didConfirmVertexBindingBlocked: Bool
    let didConfirmDrawBlocked: Bool
    let didConfirmCommitPresentGpuRenderBlocked: Bool
    let didConfirmNoPointerHandleClassIdReturnPolicy: Bool

    init(
        vertexBufferRuntimeReadiness:
            CjguiInternalRendererNoVertexBufferRuntimeCallReadiness,
        didConfirmPipelineStateFactsAvailable: Bool,
        didConfirmVertexBufferFactsAvailable: Bool,
        didConfirmRenderCommandEncoderMissing: Bool,
        didConfirmPipelineBindingBlocked: Bool,
        didConfirmVertexBindingBlocked: Bool,
        didConfirmDrawBlocked: Bool,
        didConfirmCommitPresentGpuRenderBlocked: Bool,
        didConfirmNoPointerHandleClassIdReturnPolicy: Bool
    ) {
        this.vertexBufferRuntimeReadiness = vertexBufferRuntimeReadiness
        this.didConfirmPipelineStateFactsAvailable =
            didConfirmPipelineStateFactsAvailable
        this.didConfirmVertexBufferFactsAvailable =
            didConfirmVertexBufferFactsAvailable
        this.didConfirmRenderCommandEncoderMissing =
            didConfirmRenderCommandEncoderMissing
        this.didConfirmPipelineBindingBlocked = didConfirmPipelineBindingBlocked
        this.didConfirmVertexBindingBlocked = didConfirmVertexBindingBlocked
        this.didConfirmDrawBlocked = didConfirmDrawBlocked
        this.didConfirmCommitPresentGpuRenderBlocked =
            didConfirmCommitPresentGpuRenderBlocked
        this.didConfirmNoPointerHandleClassIdReturnPolicy =
            didConfirmNoPointerHandleClassIdReturnPolicy
    }
}

struct CjguiInternalRendererNoDrawCallNoSubmitPlanningReadiness {
    let vertexBufferRuntimeReadiness:
        CjguiInternalRendererNoVertexBufferRuntimeCallReadiness
    let planningFacts: CjguiInternalRendererDrawCallNoSubmitPlanningFacts
    let didPrepareRendererNoDrawCallNoSubmitPlanningReadiness: Bool
    let shouldDeferRendererNoDrawCallNoSubmitPlanningReadiness: Bool
    let didConfirmPipelineStateAvailable: Bool
    let didConfirmVertexBufferAvailable: Bool
    let didConfirmEncoderMissing: Bool
    let didConfirmPipelineBindingBlocked: Bool
    let didConfirmVertexBindingBlocked: Bool
    let didConfirmDrawCommitPresentGpuOrRenderBlocked: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepDrawCallPlanningReadinessDehydrated: Bool
    let didAvoidDrawPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        vertexBufferRuntimeReadiness:
            CjguiInternalRendererNoVertexBufferRuntimeCallReadiness,
        planningFacts: CjguiInternalRendererDrawCallNoSubmitPlanningFacts,
        didPrepareRendererNoDrawCallNoSubmitPlanningReadiness: Bool,
        shouldDeferRendererNoDrawCallNoSubmitPlanningReadiness: Bool,
        didConfirmPipelineStateAvailable: Bool,
        didConfirmVertexBufferAvailable: Bool,
        didConfirmEncoderMissing: Bool,
        didConfirmPipelineBindingBlocked: Bool,
        didConfirmVertexBindingBlocked: Bool,
        didConfirmDrawCommitPresentGpuOrRenderBlocked: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepDrawCallPlanningReadinessDehydrated: Bool,
        didAvoidDrawPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.vertexBufferRuntimeReadiness = vertexBufferRuntimeReadiness
        this.planningFacts = planningFacts
        this.didPrepareRendererNoDrawCallNoSubmitPlanningReadiness =
            didPrepareRendererNoDrawCallNoSubmitPlanningReadiness
        this.shouldDeferRendererNoDrawCallNoSubmitPlanningReadiness =
            shouldDeferRendererNoDrawCallNoSubmitPlanningReadiness
        this.didConfirmPipelineStateAvailable =
            didConfirmPipelineStateAvailable
        this.didConfirmVertexBufferAvailable = didConfirmVertexBufferAvailable
        this.didConfirmEncoderMissing = didConfirmEncoderMissing
        this.didConfirmPipelineBindingBlocked =
            didConfirmPipelineBindingBlocked
        this.didConfirmVertexBindingBlocked = didConfirmVertexBindingBlocked
        this.didConfirmDrawCommitPresentGpuOrRenderBlocked =
            didConfirmDrawCommitPresentGpuOrRenderBlocked
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepDrawCallPlanningReadinessDehydrated =
            didKeepDrawCallPlanningReadinessDehydrated
        this.didAvoidDrawPermissionWrapper = didAvoidDrawPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
    }
}

func cjguiInternalBuildRendererDrawCallNoSubmitPlanningReadiness(
    vertexBufferRuntimeReadiness:
        CjguiInternalRendererNoVertexBufferRuntimeCallReadiness
): CjguiInternalRendererNoDrawCallNoSubmitPlanningReadiness {
    let upstreamReady =
        vertexBufferRuntimeReadiness
            .didPrepareRendererNoVertexBufferRuntimeCallReadiness &&
        vertexBufferRuntimeReadiness.didConfirmRuntimeInternalCallExecuted &&
        vertexBufferRuntimeReadiness
            .didConfirmCreateUploadClassifyDestroyCleanup &&
        vertexBufferRuntimeReadiness.didConfirmNoEncoderBinding &&
        vertexBufferRuntimeReadiness.didConfirmNoSetVertexBuffer &&
        vertexBufferRuntimeReadiness.didConfirmNoDrawCommitPresentGpuOrRender &&
        vertexBufferRuntimeReadiness.didConfirmNoPublicSurface &&
        vertexBufferRuntimeReadiness.didConfirmNoRendererStateWrite &&
        vertexBufferRuntimeReadiness.didConfirmNoBackendReadyTruth
    let planningFacts =
        CjguiInternalRendererDrawCallNoSubmitPlanningFacts(
            vertexBufferRuntimeReadiness,
            upstreamReady,
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
        planningFacts.didConfirmPipelineStateFactsAvailable &&
        planningFacts.didConfirmVertexBufferFactsAvailable &&
        planningFacts.didConfirmRenderCommandEncoderMissing &&
        planningFacts.didConfirmPipelineBindingBlocked &&
        planningFacts.didConfirmVertexBindingBlocked &&
        planningFacts.didConfirmDrawBlocked &&
        planningFacts.didConfirmCommitPresentGpuRenderBlocked &&
        planningFacts.didConfirmNoPointerHandleClassIdReturnPolicy

    return CjguiInternalRendererNoDrawCallNoSubmitPlanningReadiness(
        vertexBufferRuntimeReadiness,
        planningFacts,
        readinessReady,
        !readinessReady,
        planningFacts.didConfirmPipelineStateFactsAvailable,
        planningFacts.didConfirmVertexBufferFactsAvailable,
        planningFacts.didConfirmRenderCommandEncoderMissing,
        planningFacts.didConfirmPipelineBindingBlocked,
        planningFacts.didConfirmVertexBindingBlocked,
        planningFacts.didConfirmDrawBlocked &&
            planningFacts.didConfirmCommitPresentGpuRenderBlocked,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererDrawCallNoSubmitPlanningDraft():
    CjguiInternalRendererNoDrawCallNoSubmitPlanningReadiness {
    let vertexBufferRuntimeReadiness =
        cjguiInternalExecuteDefaultRendererVertexBufferRuntimeCallDraft()
    return cjguiInternalBuildRendererDrawCallNoSubmitPlanningReadiness(
        vertexBufferRuntimeReadiness
    )
}
