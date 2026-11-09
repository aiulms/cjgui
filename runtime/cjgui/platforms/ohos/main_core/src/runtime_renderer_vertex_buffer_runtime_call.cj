// 中文维护注释：本文件是 vertex buffer runtime internal FFI call owner。
// Truth: 只消费 CjguiInternalRendererNoVertexBufferDataUploadReadiness，
// 局部执行 vertex buffer create/upload/classify/destroy runtime call path，
// 并把结果脱水为 facts。
// Stop-line: token 只在函数局部；不创建或绑定 render command encoder，
// 不调用 setVertexBuffer，不 draw，不创建 index buffer，不 commit，不 present，
// 不提交 GPU work，不执行 render，不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: vertex buffer runtime facts 不得包装成 draw
// permission、render permission、GPU submission、backend-ready、state write、
// receipt、record 或 publication。
package cjgui

struct CjguiInternalRendererVertexBufferRuntimeCallObservation {
    let dataUploadObservation:
        CjguiInternalRendererVertexBufferDataUploadObservation
    let didObserveRuntimeInternalCall: Bool
    let didObserveCreateUploadClassifyDestroyCleanup: Bool
    let didConfirmTokensStayedFunctionLocal: Bool
    let didConfirmEncoderSetVertexBufferDrawCommitPresentGpuOrRenderBlocked:
        Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        dataUploadObservation:
            CjguiInternalRendererVertexBufferDataUploadObservation,
        didObserveRuntimeInternalCall: Bool,
        didObserveCreateUploadClassifyDestroyCleanup: Bool,
        didConfirmTokensStayedFunctionLocal: Bool,
        didConfirmEncoderSetVertexBufferDrawCommitPresentGpuOrRenderBlocked:
            Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.dataUploadObservation = dataUploadObservation
        this.didObserveRuntimeInternalCall = didObserveRuntimeInternalCall
        this.didObserveCreateUploadClassifyDestroyCleanup =
            didObserveCreateUploadClassifyDestroyCleanup
        this.didConfirmTokensStayedFunctionLocal =
            didConfirmTokensStayedFunctionLocal
        this.didConfirmEncoderSetVertexBufferDrawCommitPresentGpuOrRenderBlocked =
            didConfirmEncoderSetVertexBufferDrawCommitPresentGpuOrRenderBlocked
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoVertexBufferRuntimeCallReadiness {
    let dataUploadReadiness:
        CjguiInternalRendererNoVertexBufferDataUploadReadiness
    let runtimeCallObservation:
        CjguiInternalRendererVertexBufferRuntimeCallObservation
    let didPrepareRendererNoVertexBufferRuntimeCallReadiness: Bool
    let shouldDeferRendererNoVertexBufferRuntimeCallReadiness: Bool
    let didConfirmRuntimeInternalCallExecuted: Bool
    let didConfirmCreateUploadClassifyDestroyCleanup: Bool
    let didConfirmTokensStayedFunctionLocal: Bool
    let didConfirmNoEncoderBinding: Bool
    let didConfirmNoSetVertexBuffer: Bool
    let didConfirmNoDrawCommitPresentGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepVertexBufferRuntimeCallReadinessDehydrated: Bool
    let didAvoidDrawPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        dataUploadReadiness:
            CjguiInternalRendererNoVertexBufferDataUploadReadiness,
        runtimeCallObservation:
            CjguiInternalRendererVertexBufferRuntimeCallObservation,
        didPrepareRendererNoVertexBufferRuntimeCallReadiness: Bool,
        shouldDeferRendererNoVertexBufferRuntimeCallReadiness: Bool,
        didConfirmRuntimeInternalCallExecuted: Bool,
        didConfirmCreateUploadClassifyDestroyCleanup: Bool,
        didConfirmTokensStayedFunctionLocal: Bool,
        didConfirmNoEncoderBinding: Bool,
        didConfirmNoSetVertexBuffer: Bool,
        didConfirmNoDrawCommitPresentGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepVertexBufferRuntimeCallReadinessDehydrated: Bool,
        didAvoidDrawPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.dataUploadReadiness = dataUploadReadiness
        this.runtimeCallObservation = runtimeCallObservation
        this.didPrepareRendererNoVertexBufferRuntimeCallReadiness =
            didPrepareRendererNoVertexBufferRuntimeCallReadiness
        this.shouldDeferRendererNoVertexBufferRuntimeCallReadiness =
            shouldDeferRendererNoVertexBufferRuntimeCallReadiness
        this.didConfirmRuntimeInternalCallExecuted =
            didConfirmRuntimeInternalCallExecuted
        this.didConfirmCreateUploadClassifyDestroyCleanup =
            didConfirmCreateUploadClassifyDestroyCleanup
        this.didConfirmTokensStayedFunctionLocal =
            didConfirmTokensStayedFunctionLocal
        this.didConfirmNoEncoderBinding = didConfirmNoEncoderBinding
        this.didConfirmNoSetVertexBuffer = didConfirmNoSetVertexBuffer
        this.didConfirmNoDrawCommitPresentGpuOrRender =
            didConfirmNoDrawCommitPresentGpuOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepVertexBufferRuntimeCallReadinessDehydrated =
            didKeepVertexBufferRuntimeCallReadinessDehydrated
        this.didAvoidDrawPermissionWrapper = didAvoidDrawPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererVertexBufferRuntimeCallValues():
    CjguiInternalRendererVertexBufferRuntimeCallObservation {
    let dataUploadObservation =
        cjguiInternalObserveRendererVertexBufferDataUploadValues()
    return CjguiInternalRendererVertexBufferRuntimeCallObservation(
        dataUploadObservation,
        dataUploadObservation.didObserveStaticTriangleUpload,
        dataUploadObservation.didObserveStaticTriangleUpload &&
            dataUploadObservation.didObserveCleanupCounts,
        dataUploadObservation.didKeepTokensFunctionLocal,
        dataUploadObservation
            .didConfirmEncoderSetVertexBufferDrawCommitPresentGpuOrRenderBlocked,
        dataUploadObservation.didConfirmNoPointerHandleClassIdReturn
    )
}

func cjguiInternalBuildRendererVertexBufferRuntimeCallReadiness(
    dataUploadReadiness:
        CjguiInternalRendererNoVertexBufferDataUploadReadiness,
    runtimeCallObservation:
        CjguiInternalRendererVertexBufferRuntimeCallObservation
): CjguiInternalRendererNoVertexBufferRuntimeCallReadiness {
    let upstreamReady =
        dataUploadReadiness
            .didPrepareRendererNoVertexBufferDataUploadReadiness &&
        dataUploadReadiness.didConfirmStaticTriangleDataUpload &&
        dataUploadReadiness.didConfirmPositionColorLayoutFacts &&
        dataUploadReadiness.didConfirmNoEncoderBinding &&
        dataUploadReadiness.didConfirmNoSetVertexBuffer &&
        dataUploadReadiness.didConfirmNoDrawCommitPresentGpuOrRender &&
        dataUploadReadiness.didConfirmNoPublicSurface &&
        dataUploadReadiness.didConfirmNoRendererStateWrite &&
        dataUploadReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        runtimeCallObservation.didObserveRuntimeInternalCall &&
        runtimeCallObservation
            .didObserveCreateUploadClassifyDestroyCleanup &&
        runtimeCallObservation.didConfirmTokensStayedFunctionLocal &&
        runtimeCallObservation
            .didConfirmEncoderSetVertexBufferDrawCommitPresentGpuOrRenderBlocked &&
        runtimeCallObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady

    return CjguiInternalRendererNoVertexBufferRuntimeCallReadiness(
        dataUploadReadiness,
        runtimeCallObservation,
        readinessReady,
        !readinessReady,
        runtimeCallObservation.didObserveRuntimeInternalCall,
        runtimeCallObservation.didObserveCreateUploadClassifyDestroyCleanup,
        runtimeCallObservation.didConfirmTokensStayedFunctionLocal,
        true,
        true,
        runtimeCallObservation
            .didConfirmEncoderSetVertexBufferDrawCommitPresentGpuOrRenderBlocked,
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

func cjguiInternalExecuteDefaultRendererVertexBufferRuntimeCallDraft():
    CjguiInternalRendererNoVertexBufferRuntimeCallReadiness {
    let dataUploadReadiness =
        cjguiInternalExecuteDefaultRendererVertexBufferDataUploadDraft()
    let runtimeCallObservation =
        cjguiInternalObserveRendererVertexBufferRuntimeCallValues()
    return cjguiInternalBuildRendererVertexBufferRuntimeCallReadiness(
        dataUploadReadiness,
        runtimeCallObservation
    )
}
