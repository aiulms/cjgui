// 中文维护注释：本文件是 shader library/function runtime internal FFI call owner。
// Truth: 只消费 CjguiInternalRendererNoShaderFunctionLookupReadiness，局部执行
// library create -> function lookup/classify -> cleanup 的 runtime internal call path，
// 并把结果脱水为 facts。
// Stop-line: token 只在函数局部；不创建 MTLRenderPipelineState，不创建或绑定
// render command encoder，不 setRenderPipelineState，不 draw，不创建 vertex buffer，
// 不 commit，不 present，不提交 GPU work，不执行 render，不写 runtime_state.cj，
// 不发布 public API。
// Same-shape Boundary Brake: shader runtime call facts 不得包装成 pipeline-ready、
// render permission、GPU submission、backend-ready、state write、receipt、record
// 或 publication。
package cjgui

struct CjguiInternalRendererShaderLibraryRuntimeCallObservation {
    let functionLookupObservation:
        CjguiInternalRendererShaderFunctionLookupObservation
    let didObserveRuntimeInternalCall: Bool
    let didObserveCreateLookupClassifyDestroyCleanup: Bool
    let didConfirmTokensStayedFunctionLocal: Bool
    let didConfirmPipelineStateEncoderDrawCommitPresentGpuOrRenderBlocked: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        functionLookupObservation:
            CjguiInternalRendererShaderFunctionLookupObservation,
        didObserveRuntimeInternalCall: Bool,
        didObserveCreateLookupClassifyDestroyCleanup: Bool,
        didConfirmTokensStayedFunctionLocal: Bool,
        didConfirmPipelineStateEncoderDrawCommitPresentGpuOrRenderBlocked: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.functionLookupObservation = functionLookupObservation
        this.didObserveRuntimeInternalCall = didObserveRuntimeInternalCall
        this.didObserveCreateLookupClassifyDestroyCleanup =
            didObserveCreateLookupClassifyDestroyCleanup
        this.didConfirmTokensStayedFunctionLocal =
            didConfirmTokensStayedFunctionLocal
        this.didConfirmPipelineStateEncoderDrawCommitPresentGpuOrRenderBlocked =
            didConfirmPipelineStateEncoderDrawCommitPresentGpuOrRenderBlocked
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness {
    let shaderFunctionLookupReadiness:
        CjguiInternalRendererNoShaderFunctionLookupReadiness
    let runtimeCallObservation:
        CjguiInternalRendererShaderLibraryRuntimeCallObservation
    let didPrepareRendererNoShaderLibraryRuntimeCallReadiness: Bool
    let shouldDeferRendererNoShaderLibraryRuntimeCallReadiness: Bool
    let didConfirmRuntimeInternalCallExecuted: Bool
    let didConfirmCreateLookupClassifyDestroyCleanup: Bool
    let didConfirmTokensStayedFunctionLocal: Bool
    let didConfirmNoPipelineStateEncoderDrawCommitPresentGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepShaderLibraryRuntimeCallReadinessDehydrated: Bool
    let didAvoidPipelineReadyWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        shaderFunctionLookupReadiness:
            CjguiInternalRendererNoShaderFunctionLookupReadiness,
        runtimeCallObservation:
            CjguiInternalRendererShaderLibraryRuntimeCallObservation,
        didPrepareRendererNoShaderLibraryRuntimeCallReadiness: Bool,
        shouldDeferRendererNoShaderLibraryRuntimeCallReadiness: Bool,
        didConfirmRuntimeInternalCallExecuted: Bool,
        didConfirmCreateLookupClassifyDestroyCleanup: Bool,
        didConfirmTokensStayedFunctionLocal: Bool,
        didConfirmNoPipelineStateEncoderDrawCommitPresentGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepShaderLibraryRuntimeCallReadinessDehydrated: Bool,
        didAvoidPipelineReadyWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.shaderFunctionLookupReadiness = shaderFunctionLookupReadiness
        this.runtimeCallObservation = runtimeCallObservation
        this.didPrepareRendererNoShaderLibraryRuntimeCallReadiness =
            didPrepareRendererNoShaderLibraryRuntimeCallReadiness
        this.shouldDeferRendererNoShaderLibraryRuntimeCallReadiness =
            shouldDeferRendererNoShaderLibraryRuntimeCallReadiness
        this.didConfirmRuntimeInternalCallExecuted =
            didConfirmRuntimeInternalCallExecuted
        this.didConfirmCreateLookupClassifyDestroyCleanup =
            didConfirmCreateLookupClassifyDestroyCleanup
        this.didConfirmTokensStayedFunctionLocal =
            didConfirmTokensStayedFunctionLocal
        this.didConfirmNoPipelineStateEncoderDrawCommitPresentGpuOrRender =
            didConfirmNoPipelineStateEncoderDrawCommitPresentGpuOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepShaderLibraryRuntimeCallReadinessDehydrated =
            didKeepShaderLibraryRuntimeCallReadinessDehydrated
        this.didAvoidPipelineReadyWrapper = didAvoidPipelineReadyWrapper
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererShaderLibraryRuntimeCallValues():
    CjguiInternalRendererShaderLibraryRuntimeCallObservation {
    let functionLookupObservation =
        cjguiInternalObserveRendererShaderFunctionLookupValues()
    return CjguiInternalRendererShaderLibraryRuntimeCallObservation(
        functionLookupObservation,
        functionLookupObservation.didObserveFunctionLookupLifecycle,
        functionLookupObservation.didObserveFunctionLookupLifecycle &&
            functionLookupObservation.didObserveVertexAndFragmentFunctions &&
            functionLookupObservation.didObserveCleanupCounts,
        functionLookupObservation.didKeepTokensFunctionLocal,
        functionLookupObservation
            .didConfirmPipelineStateEncoderDrawStillBlocked,
        functionLookupObservation.didConfirmNoPointerHandleClassIdReturn
    )
}

func cjguiInternalBuildRendererShaderLibraryRuntimeCallReadiness(
    shaderFunctionLookupReadiness:
        CjguiInternalRendererNoShaderFunctionLookupReadiness,
    runtimeCallObservation:
        CjguiInternalRendererShaderLibraryRuntimeCallObservation
): CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness {
    let upstreamReady =
        shaderFunctionLookupReadiness
            .didPrepareRendererNoShaderFunctionLookupReadiness &&
        shaderFunctionLookupReadiness.didConfirmFunctionLookupLifecycle &&
        shaderFunctionLookupReadiness
            .didConfirmPipelineStateEncoderDrawStillBlocked &&
        shaderFunctionLookupReadiness.didConfirmNoPublicSurface &&
        shaderFunctionLookupReadiness.didConfirmNoRendererStateWrite &&
        shaderFunctionLookupReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        runtimeCallObservation.didObserveRuntimeInternalCall &&
        runtimeCallObservation.didObserveCreateLookupClassifyDestroyCleanup &&
        runtimeCallObservation.didConfirmTokensStayedFunctionLocal &&
        runtimeCallObservation
            .didConfirmPipelineStateEncoderDrawCommitPresentGpuOrRenderBlocked &&
        runtimeCallObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady

    return CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness(
        shaderFunctionLookupReadiness,
        runtimeCallObservation,
        readinessReady,
        !readinessReady,
        runtimeCallObservation.didObserveRuntimeInternalCall,
        runtimeCallObservation.didObserveCreateLookupClassifyDestroyCleanup,
        runtimeCallObservation.didConfirmTokensStayedFunctionLocal,
        runtimeCallObservation
            .didConfirmPipelineStateEncoderDrawCommitPresentGpuOrRenderBlocked,
        runtimeCallObservation.didConfirmNoPointerHandleClassIdReturn,
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

func cjguiInternalExecuteDefaultRendererShaderLibraryRuntimeCallDraft():
    CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness {
    let shaderFunctionLookupReadiness =
        cjguiInternalExecuteDefaultRendererShaderFunctionLookupDraft()
    let runtimeCallObservation =
        cjguiInternalObserveRendererShaderLibraryRuntimeCallValues()
    return cjguiInternalBuildRendererShaderLibraryRuntimeCallReadiness(
        shaderFunctionLookupReadiness,
        runtimeCallObservation
    )
}
