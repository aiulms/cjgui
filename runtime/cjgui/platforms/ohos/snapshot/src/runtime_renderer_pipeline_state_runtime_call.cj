// 中文维护注释：本文件是 pipeline state runtime internal FFI call owner。
// Truth: 只消费 CjguiInternalRendererNoPipelineStateCreateDestroyReadiness，
// 局部执行 pipeline state create/classify/destroy runtime call path，并把结果脱水为 facts。
// Stop-line: token 只在函数局部；不创建或绑定 render command encoder，
// 不 setRenderPipelineState，不 draw，不创建 vertex buffer，不 commit，不 present，
// 不提交 GPU work，不执行 render，不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: pipeline state runtime facts 不得包装成 render
// permission、GPU submission、backend-ready、state write、receipt、record
// 或 publication。
package cjgui

struct CjguiInternalRendererPipelineStateRuntimeCallObservation {
    let createDestroyObservation:
        CjguiInternalRendererPipelineStateCreateDestroyObservation
    let didObserveRuntimeInternalCall: Bool
    let didObserveCreateClassifyDestroyCleanup: Bool
    let didConfirmTokensStayedFunctionLocal: Bool
    let didConfirmEncoderDrawCommitPresentGpuOrRenderBlocked: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        createDestroyObservation:
            CjguiInternalRendererPipelineStateCreateDestroyObservation,
        didObserveRuntimeInternalCall: Bool,
        didObserveCreateClassifyDestroyCleanup: Bool,
        didConfirmTokensStayedFunctionLocal: Bool,
        didConfirmEncoderDrawCommitPresentGpuOrRenderBlocked: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.createDestroyObservation = createDestroyObservation
        this.didObserveRuntimeInternalCall = didObserveRuntimeInternalCall
        this.didObserveCreateClassifyDestroyCleanup =
            didObserveCreateClassifyDestroyCleanup
        this.didConfirmTokensStayedFunctionLocal =
            didConfirmTokensStayedFunctionLocal
        this.didConfirmEncoderDrawCommitPresentGpuOrRenderBlocked =
            didConfirmEncoderDrawCommitPresentGpuOrRenderBlocked
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoPipelineStateRuntimeCallReadiness {
    let pipelineStateCreateDestroyReadiness:
        CjguiInternalRendererNoPipelineStateCreateDestroyReadiness
    let runtimeCallObservation:
        CjguiInternalRendererPipelineStateRuntimeCallObservation
    let didPrepareRendererNoPipelineStateRuntimeCallReadiness: Bool
    let shouldDeferRendererNoPipelineStateRuntimeCallReadiness: Bool
    let didConfirmRuntimeInternalCallExecuted: Bool
    let didConfirmCreateClassifyDestroyCleanup: Bool
    let didConfirmDependencyDestroyBlockedWhilePipelineLive: Bool
    let didConfirmTokensStayedFunctionLocal: Bool
    let didConfirmNoEncoderBinding: Bool
    let didConfirmNoDrawCommitPresentGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepPipelineStateRuntimeCallReadinessDehydrated: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        pipelineStateCreateDestroyReadiness:
            CjguiInternalRendererNoPipelineStateCreateDestroyReadiness,
        runtimeCallObservation:
            CjguiInternalRendererPipelineStateRuntimeCallObservation,
        didPrepareRendererNoPipelineStateRuntimeCallReadiness: Bool,
        shouldDeferRendererNoPipelineStateRuntimeCallReadiness: Bool,
        didConfirmRuntimeInternalCallExecuted: Bool,
        didConfirmCreateClassifyDestroyCleanup: Bool,
        didConfirmDependencyDestroyBlockedWhilePipelineLive: Bool,
        didConfirmTokensStayedFunctionLocal: Bool,
        didConfirmNoEncoderBinding: Bool,
        didConfirmNoDrawCommitPresentGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepPipelineStateRuntimeCallReadinessDehydrated: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.pipelineStateCreateDestroyReadiness =
            pipelineStateCreateDestroyReadiness
        this.runtimeCallObservation = runtimeCallObservation
        this.didPrepareRendererNoPipelineStateRuntimeCallReadiness =
            didPrepareRendererNoPipelineStateRuntimeCallReadiness
        this.shouldDeferRendererNoPipelineStateRuntimeCallReadiness =
            shouldDeferRendererNoPipelineStateRuntimeCallReadiness
        this.didConfirmRuntimeInternalCallExecuted =
            didConfirmRuntimeInternalCallExecuted
        this.didConfirmCreateClassifyDestroyCleanup =
            didConfirmCreateClassifyDestroyCleanup
        this.didConfirmDependencyDestroyBlockedWhilePipelineLive =
            didConfirmDependencyDestroyBlockedWhilePipelineLive
        this.didConfirmTokensStayedFunctionLocal =
            didConfirmTokensStayedFunctionLocal
        this.didConfirmNoEncoderBinding = didConfirmNoEncoderBinding
        this.didConfirmNoDrawCommitPresentGpuOrRender =
            didConfirmNoDrawCommitPresentGpuOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepPipelineStateRuntimeCallReadinessDehydrated =
            didKeepPipelineStateRuntimeCallReadinessDehydrated
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererPipelineStateRuntimeCallValues():
    CjguiInternalRendererPipelineStateRuntimeCallObservation {
    let createDestroyObservation =
        cjguiInternalObserveRendererPipelineStateCreateDestroyValues()
    return CjguiInternalRendererPipelineStateRuntimeCallObservation(
        createDestroyObservation,
        createDestroyObservation.didObservePipelineStateLifecycle,
        createDestroyObservation.didObservePipelineStateLifecycle &&
            createDestroyObservation.didObserveCleanupCounts,
        createDestroyObservation.didKeepTokensFunctionLocal,
        createDestroyObservation
            .didConfirmEncoderDrawCommitPresentGpuOrRenderBlocked,
        createDestroyObservation.didConfirmNoPointerHandleClassIdReturn
    )
}

func cjguiInternalBuildRendererPipelineStateRuntimeCallReadiness(
    pipelineStateCreateDestroyReadiness:
        CjguiInternalRendererNoPipelineStateCreateDestroyReadiness,
    runtimeCallObservation:
        CjguiInternalRendererPipelineStateRuntimeCallObservation
): CjguiInternalRendererNoPipelineStateRuntimeCallReadiness {
    let upstreamReady =
        pipelineStateCreateDestroyReadiness
            .didPrepareRendererNoPipelineStateCreateDestroyReadiness &&
        pipelineStateCreateDestroyReadiness
            .didConfirmPipelineStateCreateDestroyLifecycle &&
        pipelineStateCreateDestroyReadiness
            .didConfirmDependencyDestroyBlockedWhilePipelineLive &&
        pipelineStateCreateDestroyReadiness.didConfirmNoPublicSurface &&
        pipelineStateCreateDestroyReadiness.didConfirmNoRendererStateWrite &&
        pipelineStateCreateDestroyReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        runtimeCallObservation.didObserveRuntimeInternalCall &&
        runtimeCallObservation.didObserveCreateClassifyDestroyCleanup &&
        runtimeCallObservation.didConfirmTokensStayedFunctionLocal &&
        runtimeCallObservation
            .didConfirmEncoderDrawCommitPresentGpuOrRenderBlocked &&
        runtimeCallObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady

    return CjguiInternalRendererNoPipelineStateRuntimeCallReadiness(
        pipelineStateCreateDestroyReadiness,
        runtimeCallObservation,
        readinessReady,
        !readinessReady,
        runtimeCallObservation.didObserveRuntimeInternalCall,
        runtimeCallObservation.didObserveCreateClassifyDestroyCleanup,
        pipelineStateCreateDestroyReadiness
            .didConfirmDependencyDestroyBlockedWhilePipelineLive,
        runtimeCallObservation.didConfirmTokensStayedFunctionLocal,
        true,
        runtimeCallObservation
            .didConfirmEncoderDrawCommitPresentGpuOrRenderBlocked,
        runtimeCallObservation.didConfirmNoPointerHandleClassIdReturn,
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

func cjguiInternalExecuteDefaultRendererPipelineStateRuntimeCallDraft():
    CjguiInternalRendererNoPipelineStateRuntimeCallReadiness {
    let pipelineStateCreateDestroyReadiness =
        cjguiInternalExecuteDefaultRendererPipelineStateCreateDestroyDraft()
    let runtimeCallObservation =
        cjguiInternalObserveRendererPipelineStateRuntimeCallValues()
    return cjguiInternalBuildRendererPipelineStateRuntimeCallReadiness(
        pipelineStateCreateDestroyReadiness,
        runtimeCallObservation
    )
}
