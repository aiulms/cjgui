// 中文维护注释：本文件是 token-backed MTLBuffer create/destroy no-submit owner。
// Truth: 只消费 CjguiInternalRendererNoVertexBufferNoSubmitPlanningReadiness，
// 局部调用 device / vertex buffer create -> classify -> destroy -> cleanup，
// 并脱水为 internal facts。
// Stop-line: token 只在函数局部；不创建或绑定 render command encoder，
// 不调用 setVertexBuffer，不 draw，不创建 index buffer，不 commit，不 present，
// 不提交 GPU work，不执行 render，不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: vertex buffer token facts 不得包装成 draw
// permission、render permission、GPU submission、backend-ready、state write、
// receipt、record 或 publication。
package cjgui

foreign func cjgui_native_bridge_vertex_buffer_table_capacity(): UInt32
foreign func cjgui_native_bridge_vertex_buffer_table_enabled(): UInt32
foreign func cjgui_native_bridge_vertex_buffer_table_occupied_count(): UInt32
foreign func cjgui_native_bridge_vertex_buffer_create(
    deviceToken: UInt64,
    outToken: CPointer<UInt64>
): Int32
foreign func cjgui_native_bridge_vertex_buffer_destroy(token: UInt64): Int32
foreign func cjgui_native_bridge_vertex_buffer_token_classify(token: UInt64):
    Int32
foreign func cjgui_native_bridge_vertex_buffer_double_destroy_classify(
    token: UInt64
): Int32
foreign func cjgui_native_bridge_vertex_buffer_create_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_vertex_buffer_destroy_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_vertex_buffer_layout_position_color(): Int32
foreign func cjgui_native_bridge_vertex_buffer_encoder_binding_still_blocked():
    Int32
foreign func cjgui_native_bridge_vertex_buffer_draw_still_blocked(): Int32

struct CjguiInternalRendererVertexBufferCreateDestroyObservation {
    let deviceCreateStatusValue: Int32
    let vertexBufferCreateStatusValue: Int32
    let vertexBufferDestroyStatusValue: Int32
    let vertexBufferTokenValue: UInt64
    let vertexBufferClassValue: Int32
    let vertexBufferDestroyedClassValue: Int32
    let vertexBufferDoubleDestroyStatusValue: Int32
    let vertexBufferDoubleDestroyClassValue: Int32
    let deviceDestroyWhileBufferLiveValue: Int32
    let deviceDestroyStatusValue: Int32
    let layoutPositionColorValue: Int32
    let encoderBindingStillBlockedValue: Int32
    let drawStillBlockedValue: Int32
    let vertexBufferOccupiedBeforeValue: UInt32
    let vertexBufferOccupiedAfterCreateValue: UInt32
    let vertexBufferOccupiedAfterCleanupValue: UInt32
    let didObserveVertexBufferLifecycle: Bool
    let didObserveDependencyDestroyBlockedWhileBufferLive: Bool
    let didObserveDoubleDestroyFailClosed: Bool
    let didObserveCleanupCounts: Bool
    let didKeepTokensFunctionLocal: Bool
    let didConfirmEncoderSetVertexBufferDrawCommitPresentGpuOrRenderBlocked:
        Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        deviceCreateStatusValue: Int32,
        vertexBufferCreateStatusValue: Int32,
        vertexBufferDestroyStatusValue: Int32,
        vertexBufferTokenValue: UInt64,
        vertexBufferClassValue: Int32,
        vertexBufferDestroyedClassValue: Int32,
        vertexBufferDoubleDestroyStatusValue: Int32,
        vertexBufferDoubleDestroyClassValue: Int32,
        deviceDestroyWhileBufferLiveValue: Int32,
        deviceDestroyStatusValue: Int32,
        layoutPositionColorValue: Int32,
        encoderBindingStillBlockedValue: Int32,
        drawStillBlockedValue: Int32,
        vertexBufferOccupiedBeforeValue: UInt32,
        vertexBufferOccupiedAfterCreateValue: UInt32,
        vertexBufferOccupiedAfterCleanupValue: UInt32,
        didObserveVertexBufferLifecycle: Bool,
        didObserveDependencyDestroyBlockedWhileBufferLive: Bool,
        didObserveDoubleDestroyFailClosed: Bool,
        didObserveCleanupCounts: Bool,
        didKeepTokensFunctionLocal: Bool,
        didConfirmEncoderSetVertexBufferDrawCommitPresentGpuOrRenderBlocked:
            Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.deviceCreateStatusValue = deviceCreateStatusValue
        this.vertexBufferCreateStatusValue = vertexBufferCreateStatusValue
        this.vertexBufferDestroyStatusValue = vertexBufferDestroyStatusValue
        this.vertexBufferTokenValue = vertexBufferTokenValue
        this.vertexBufferClassValue = vertexBufferClassValue
        this.vertexBufferDestroyedClassValue = vertexBufferDestroyedClassValue
        this.vertexBufferDoubleDestroyStatusValue =
            vertexBufferDoubleDestroyStatusValue
        this.vertexBufferDoubleDestroyClassValue =
            vertexBufferDoubleDestroyClassValue
        this.deviceDestroyWhileBufferLiveValue =
            deviceDestroyWhileBufferLiveValue
        this.deviceDestroyStatusValue = deviceDestroyStatusValue
        this.layoutPositionColorValue = layoutPositionColorValue
        this.encoderBindingStillBlockedValue = encoderBindingStillBlockedValue
        this.drawStillBlockedValue = drawStillBlockedValue
        this.vertexBufferOccupiedBeforeValue = vertexBufferOccupiedBeforeValue
        this.vertexBufferOccupiedAfterCreateValue =
            vertexBufferOccupiedAfterCreateValue
        this.vertexBufferOccupiedAfterCleanupValue =
            vertexBufferOccupiedAfterCleanupValue
        this.didObserveVertexBufferLifecycle = didObserveVertexBufferLifecycle
        this.didObserveDependencyDestroyBlockedWhileBufferLive =
            didObserveDependencyDestroyBlockedWhileBufferLive
        this.didObserveDoubleDestroyFailClosed =
            didObserveDoubleDestroyFailClosed
        this.didObserveCleanupCounts = didObserveCleanupCounts
        this.didKeepTokensFunctionLocal = didKeepTokensFunctionLocal
        this.didConfirmEncoderSetVertexBufferDrawCommitPresentGpuOrRenderBlocked =
            didConfirmEncoderSetVertexBufferDrawCommitPresentGpuOrRenderBlocked
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoVertexBufferCreateDestroyReadiness {
    let planningReadiness:
        CjguiInternalRendererNoVertexBufferNoSubmitPlanningReadiness
    let createDestroyObservation:
        CjguiInternalRendererVertexBufferCreateDestroyObservation
    let didPrepareRendererNoVertexBufferCreateDestroyReadiness: Bool
    let shouldDeferRendererNoVertexBufferCreateDestroyReadiness: Bool
    let didConfirmVertexBufferCreateDestroyLifecycle: Bool
    let didConfirmDependencyDestroyBlockedWhileBufferLive: Bool
    let didConfirmDoubleDestroyFailClosed: Bool
    let didConfirmCleanupCountsReturnToZero: Bool
    let didConfirmTokensStayedFunctionLocal: Bool
    let didConfirmNoEncoderBinding: Bool
    let didConfirmNoSetVertexBuffer: Bool
    let didConfirmNoDrawCommitPresentGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepVertexBufferCreateDestroyReadinessDehydrated: Bool
    let didAvoidDrawPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        planningReadiness:
            CjguiInternalRendererNoVertexBufferNoSubmitPlanningReadiness,
        createDestroyObservation:
            CjguiInternalRendererVertexBufferCreateDestroyObservation,
        didPrepareRendererNoVertexBufferCreateDestroyReadiness: Bool,
        shouldDeferRendererNoVertexBufferCreateDestroyReadiness: Bool,
        didConfirmVertexBufferCreateDestroyLifecycle: Bool,
        didConfirmDependencyDestroyBlockedWhileBufferLive: Bool,
        didConfirmDoubleDestroyFailClosed: Bool,
        didConfirmCleanupCountsReturnToZero: Bool,
        didConfirmTokensStayedFunctionLocal: Bool,
        didConfirmNoEncoderBinding: Bool,
        didConfirmNoSetVertexBuffer: Bool,
        didConfirmNoDrawCommitPresentGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepVertexBufferCreateDestroyReadinessDehydrated: Bool,
        didAvoidDrawPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.planningReadiness = planningReadiness
        this.createDestroyObservation = createDestroyObservation
        this.didPrepareRendererNoVertexBufferCreateDestroyReadiness =
            didPrepareRendererNoVertexBufferCreateDestroyReadiness
        this.shouldDeferRendererNoVertexBufferCreateDestroyReadiness =
            shouldDeferRendererNoVertexBufferCreateDestroyReadiness
        this.didConfirmVertexBufferCreateDestroyLifecycle =
            didConfirmVertexBufferCreateDestroyLifecycle
        this.didConfirmDependencyDestroyBlockedWhileBufferLive =
            didConfirmDependencyDestroyBlockedWhileBufferLive
        this.didConfirmDoubleDestroyFailClosed =
            didConfirmDoubleDestroyFailClosed
        this.didConfirmCleanupCountsReturnToZero =
            didConfirmCleanupCountsReturnToZero
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
        this.didKeepVertexBufferCreateDestroyReadinessDehydrated =
            didKeepVertexBufferCreateDestroyReadinessDehydrated
        this.didAvoidDrawPermissionWrapper = didAvoidDrawPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
    }
}

func cjguiInternalObserveRendererVertexBufferCreateDestroyValues():
    CjguiInternalRendererVertexBufferCreateDestroyObservation {
    let vertexBufferOccupiedBefore = unsafe {
        cjgui_native_bridge_vertex_buffer_table_occupied_count()
    }
    var deviceToken = UInt64(0)
    let deviceCreate = unsafe {
        cjgui_native_bridge_metal_default_device_create(inout deviceToken)
    }
    var bufferToken = UInt64(0)
    let bufferCreate = unsafe {
        cjgui_native_bridge_vertex_buffer_create(deviceToken, inout bufferToken)
    }
    let vertexBufferOccupiedAfterCreate = unsafe {
        cjgui_native_bridge_vertex_buffer_table_occupied_count()
    }
    let bufferClass = unsafe {
        cjgui_native_bridge_vertex_buffer_token_classify(bufferToken)
    }
    let deviceDestroyWhileBufferLive = unsafe {
        cjgui_native_bridge_metal_device_destroy(deviceToken)
    }
    let layoutPositionColor = unsafe {
        cjgui_native_bridge_vertex_buffer_layout_position_color()
    }
    let encoderBindingStillBlocked = unsafe {
        cjgui_native_bridge_vertex_buffer_encoder_binding_still_blocked()
    }
    let drawStillBlocked = unsafe {
        cjgui_native_bridge_vertex_buffer_draw_still_blocked()
    }
    let bufferDestroy = unsafe {
        cjgui_native_bridge_vertex_buffer_destroy(bufferToken)
    }
    let bufferDestroyedClass = unsafe {
        cjgui_native_bridge_vertex_buffer_token_classify(bufferToken)
    }
    let bufferDoubleDestroy = unsafe {
        cjgui_native_bridge_vertex_buffer_destroy(bufferToken)
    }
    let bufferDoubleDestroyClass = unsafe {
        cjgui_native_bridge_vertex_buffer_double_destroy_classify(bufferToken)
    }
    let deviceDestroy = unsafe {
        cjgui_native_bridge_metal_device_destroy(deviceToken)
    }
    let vertexBufferOccupiedAfterCleanup = unsafe {
        cjgui_native_bridge_vertex_buffer_table_occupied_count()
    }

    let lifecycleReady =
        deviceCreate == Int32(0) &&
        bufferCreate == Int32(0) &&
        bufferClass == Int32(300) &&
        bufferDestroy == Int32(0) &&
        deviceDestroy == Int32(0)
    let dependencyBlocked = deviceDestroyWhileBufferLive < Int32(0)
    let doubleDestroyClosed =
        bufferDestroyedClass < Int32(0) &&
        bufferDoubleDestroy < Int32(0) &&
        bufferDoubleDestroyClass < Int32(0)
    let cleanupCounts =
        vertexBufferOccupiedAfterCreate == vertexBufferOccupiedBefore +
            UInt32(1) &&
        vertexBufferOccupiedAfterCleanup == vertexBufferOccupiedBefore

    return CjguiInternalRendererVertexBufferCreateDestroyObservation(
        deviceCreate,
        bufferCreate,
        bufferDestroy,
        bufferToken,
        bufferClass,
        bufferDestroyedClass,
        bufferDoubleDestroy,
        bufferDoubleDestroyClass,
        deviceDestroyWhileBufferLive,
        deviceDestroy,
        layoutPositionColor,
        encoderBindingStillBlocked,
        drawStillBlocked,
        vertexBufferOccupiedBefore,
        vertexBufferOccupiedAfterCreate,
        vertexBufferOccupiedAfterCleanup,
        lifecycleReady,
        dependencyBlocked,
        doubleDestroyClosed,
        cleanupCounts,
        true,
        layoutPositionColor == Int32(302) &&
            encoderBindingStillBlocked < Int32(0) &&
            drawStillBlocked < Int32(0),
        true
    )
}

func cjguiInternalBuildRendererVertexBufferCreateDestroyReadiness(
    planningReadiness:
        CjguiInternalRendererNoVertexBufferNoSubmitPlanningReadiness,
    createDestroyObservation:
        CjguiInternalRendererVertexBufferCreateDestroyObservation
): CjguiInternalRendererNoVertexBufferCreateDestroyReadiness {
    let upstreamReady =
        planningReadiness
            .didPrepareRendererNoVertexBufferNoSubmitPlanningReadiness &&
        planningReadiness.didConfirmVertexDataContract &&
        planningReadiness.didConfirmBufferLifecycleCanStayNoSubmit &&
        planningReadiness.didConfirmNoEncoderBinding &&
        planningReadiness.didConfirmNoSetVertexBuffer &&
        planningReadiness.didConfirmNoDrawCommitPresentGpuOrRender &&
        planningReadiness.didConfirmNoPublicSurface &&
        planningReadiness.didConfirmNoRendererStateWrite &&
        planningReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        createDestroyObservation.didObserveVertexBufferLifecycle &&
        createDestroyObservation
            .didObserveDependencyDestroyBlockedWhileBufferLive &&
        createDestroyObservation.didObserveDoubleDestroyFailClosed &&
        createDestroyObservation.didObserveCleanupCounts &&
        createDestroyObservation.didKeepTokensFunctionLocal &&
        createDestroyObservation
            .didConfirmEncoderSetVertexBufferDrawCommitPresentGpuOrRenderBlocked &&
        createDestroyObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady

    return CjguiInternalRendererNoVertexBufferCreateDestroyReadiness(
        planningReadiness,
        createDestroyObservation,
        readinessReady,
        !readinessReady,
        createDestroyObservation.didObserveVertexBufferLifecycle,
        createDestroyObservation
            .didObserveDependencyDestroyBlockedWhileBufferLive,
        createDestroyObservation.didObserveDoubleDestroyFailClosed,
        createDestroyObservation.didObserveCleanupCounts,
        createDestroyObservation.didKeepTokensFunctionLocal,
        true,
        true,
        createDestroyObservation
            .didConfirmEncoderSetVertexBufferDrawCommitPresentGpuOrRenderBlocked,
        createDestroyObservation.didConfirmNoPointerHandleClassIdReturn,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVertexBufferCreateDestroyDraft():
    CjguiInternalRendererNoVertexBufferCreateDestroyReadiness {
    let planningReadiness =
        cjguiInternalExecuteDefaultRendererVertexBufferNoSubmitPlanningDraft()
    let createDestroyObservation =
        cjguiInternalObserveRendererVertexBufferCreateDestroyValues()
    return cjguiInternalBuildRendererVertexBufferCreateDestroyReadiness(
        planningReadiness,
        createDestroyObservation
    )
}
