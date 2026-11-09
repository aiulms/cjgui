// 中文维护注释：本文件是 draw call still-blocked native fact owner。
// Truth: 只消费 CjguiInternalRendererNoDrawCallNoSubmitPlanningReadiness，
// 调用 still-blocked C ABI 并脱水为 encoder / pipeline / vertex / draw blocker facts。
// Stop-line: 不创建 render command encoder，不调用 setVertexBuffer 或
// setRenderPipelineState，不 draw，不创建 index buffer，不 commit，不 present，
// 不提交 GPU work，不执行 render，不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: still-blocked facts 不得包装成 draw permission、
// render permission、GPU submission、backend-ready、state write、receipt、record
// 或 publication。
package cjgui

foreign func cjgui_native_bridge_draw_call_encoder_required(): Int32
foreign func cjgui_native_bridge_draw_call_pipeline_binding_required(): Int32
foreign func cjgui_native_bridge_draw_call_vertex_binding_required(): Int32
foreign func cjgui_native_bridge_draw_call_still_blocked(): Int32

struct CjguiInternalRendererDrawCallStillBlockedObservation {
    let encoderRequiredValue: Int32
    let pipelineBindingRequiredValue: Int32
    let vertexBindingRequiredValue: Int32
    let drawStillBlockedValue: Int32
    let didObserveEncoderRequired: Bool
    let didObservePipelineBindingRequired: Bool
    let didObserveVertexBindingRequired: Bool
    let didObserveDrawStillBlocked: Bool
    let didConfirmNoEncoderBindingDrawCommitPresentGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        encoderRequiredValue: Int32,
        pipelineBindingRequiredValue: Int32,
        vertexBindingRequiredValue: Int32,
        drawStillBlockedValue: Int32,
        didObserveEncoderRequired: Bool,
        didObservePipelineBindingRequired: Bool,
        didObserveVertexBindingRequired: Bool,
        didObserveDrawStillBlocked: Bool,
        didConfirmNoEncoderBindingDrawCommitPresentGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.encoderRequiredValue = encoderRequiredValue
        this.pipelineBindingRequiredValue = pipelineBindingRequiredValue
        this.vertexBindingRequiredValue = vertexBindingRequiredValue
        this.drawStillBlockedValue = drawStillBlockedValue
        this.didObserveEncoderRequired = didObserveEncoderRequired
        this.didObservePipelineBindingRequired =
            didObservePipelineBindingRequired
        this.didObserveVertexBindingRequired = didObserveVertexBindingRequired
        this.didObserveDrawStillBlocked = didObserveDrawStillBlocked
        this.didConfirmNoEncoderBindingDrawCommitPresentGpuOrRender =
            didConfirmNoEncoderBindingDrawCommitPresentGpuOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoDrawCallStillBlockedReadiness {
    let planningReadiness:
        CjguiInternalRendererNoDrawCallNoSubmitPlanningReadiness
    let stillBlockedObservation:
        CjguiInternalRendererDrawCallStillBlockedObservation
    let didPrepareRendererNoDrawCallStillBlockedReadiness: Bool
    let shouldDeferRendererNoDrawCallStillBlockedReadiness: Bool
    let didConfirmEncoderRequired: Bool
    let didConfirmPipelineBindingRequired: Bool
    let didConfirmVertexBindingRequired: Bool
    let didConfirmDrawStillBlocked: Bool
    let didConfirmNoEncoderCreation: Bool
    let didConfirmNoSetRenderPipelineState: Bool
    let didConfirmNoSetVertexBuffer: Bool
    let didConfirmNoDrawCommitPresentGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepDrawCallStillBlockedReadinessDehydrated: Bool
    let didAvoidDrawPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        planningReadiness:
            CjguiInternalRendererNoDrawCallNoSubmitPlanningReadiness,
        stillBlockedObservation:
            CjguiInternalRendererDrawCallStillBlockedObservation,
        didPrepareRendererNoDrawCallStillBlockedReadiness: Bool,
        shouldDeferRendererNoDrawCallStillBlockedReadiness: Bool,
        didConfirmEncoderRequired: Bool,
        didConfirmPipelineBindingRequired: Bool,
        didConfirmVertexBindingRequired: Bool,
        didConfirmDrawStillBlocked: Bool,
        didConfirmNoEncoderCreation: Bool,
        didConfirmNoSetRenderPipelineState: Bool,
        didConfirmNoSetVertexBuffer: Bool,
        didConfirmNoDrawCommitPresentGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepDrawCallStillBlockedReadinessDehydrated: Bool,
        didAvoidDrawPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.planningReadiness = planningReadiness
        this.stillBlockedObservation = stillBlockedObservation
        this.didPrepareRendererNoDrawCallStillBlockedReadiness =
            didPrepareRendererNoDrawCallStillBlockedReadiness
        this.shouldDeferRendererNoDrawCallStillBlockedReadiness =
            shouldDeferRendererNoDrawCallStillBlockedReadiness
        this.didConfirmEncoderRequired = didConfirmEncoderRequired
        this.didConfirmPipelineBindingRequired =
            didConfirmPipelineBindingRequired
        this.didConfirmVertexBindingRequired = didConfirmVertexBindingRequired
        this.didConfirmDrawStillBlocked = didConfirmDrawStillBlocked
        this.didConfirmNoEncoderCreation = didConfirmNoEncoderCreation
        this.didConfirmNoSetRenderPipelineState =
            didConfirmNoSetRenderPipelineState
        this.didConfirmNoSetVertexBuffer = didConfirmNoSetVertexBuffer
        this.didConfirmNoDrawCommitPresentGpuOrRender =
            didConfirmNoDrawCommitPresentGpuOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepDrawCallStillBlockedReadinessDehydrated =
            didKeepDrawCallStillBlockedReadinessDehydrated
        this.didAvoidDrawPermissionWrapper = didAvoidDrawPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
    }
}

func cjguiInternalObserveRendererDrawCallStillBlockedValues():
    CjguiInternalRendererDrawCallStillBlockedObservation {
    let encoderRequired = unsafe {
        cjgui_native_bridge_draw_call_encoder_required()
    }
    let pipelineBindingRequired = unsafe {
        cjgui_native_bridge_draw_call_pipeline_binding_required()
    }
    let vertexBindingRequired = unsafe {
        cjgui_native_bridge_draw_call_vertex_binding_required()
    }
    let drawStillBlocked = unsafe {
        cjgui_native_bridge_draw_call_still_blocked()
    }
    return CjguiInternalRendererDrawCallStillBlockedObservation(
        encoderRequired,
        pipelineBindingRequired,
        vertexBindingRequired,
        drawStillBlocked,
        encoderRequired < Int32(0),
        pipelineBindingRequired < Int32(0),
        vertexBindingRequired < Int32(0),
        drawStillBlocked < Int32(0),
        true,
        true
    )
}

func cjguiInternalBuildRendererDrawCallStillBlockedReadiness(
    planningReadiness:
        CjguiInternalRendererNoDrawCallNoSubmitPlanningReadiness,
    stillBlockedObservation:
        CjguiInternalRendererDrawCallStillBlockedObservation
): CjguiInternalRendererNoDrawCallStillBlockedReadiness {
    let upstreamReady =
        planningReadiness.didPrepareRendererNoDrawCallNoSubmitPlanningReadiness &&
        planningReadiness.didConfirmPipelineStateAvailable &&
        planningReadiness.didConfirmVertexBufferAvailable &&
        planningReadiness.didConfirmEncoderMissing &&
        planningReadiness.didConfirmPipelineBindingBlocked &&
        planningReadiness.didConfirmVertexBindingBlocked &&
        planningReadiness.didConfirmDrawCommitPresentGpuOrRenderBlocked &&
        planningReadiness.didConfirmNoPublicSurface &&
        planningReadiness.didConfirmNoRendererStateWrite &&
        planningReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        stillBlockedObservation.didObserveEncoderRequired &&
        stillBlockedObservation.didObservePipelineBindingRequired &&
        stillBlockedObservation.didObserveVertexBindingRequired &&
        stillBlockedObservation.didObserveDrawStillBlocked &&
        stillBlockedObservation
            .didConfirmNoEncoderBindingDrawCommitPresentGpuOrRender &&
        stillBlockedObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady

    return CjguiInternalRendererNoDrawCallStillBlockedReadiness(
        planningReadiness,
        stillBlockedObservation,
        readinessReady,
        !readinessReady,
        stillBlockedObservation.didObserveEncoderRequired,
        stillBlockedObservation.didObservePipelineBindingRequired,
        stillBlockedObservation.didObserveVertexBindingRequired,
        stillBlockedObservation.didObserveDrawStillBlocked,
        true,
        true,
        true,
        stillBlockedObservation
            .didConfirmNoEncoderBindingDrawCommitPresentGpuOrRender,
        stillBlockedObservation.didConfirmNoPointerHandleClassIdReturn,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererDrawCallStillBlockedDraft():
    CjguiInternalRendererNoDrawCallStillBlockedReadiness {
    let planningReadiness =
        cjguiInternalExecuteDefaultRendererDrawCallNoSubmitPlanningDraft()
    let stillBlockedObservation =
        cjguiInternalObserveRendererDrawCallStillBlockedValues()
    return cjguiInternalBuildRendererDrawCallStillBlockedReadiness(
        planningReadiness,
        stillBlockedObservation
    )
}
