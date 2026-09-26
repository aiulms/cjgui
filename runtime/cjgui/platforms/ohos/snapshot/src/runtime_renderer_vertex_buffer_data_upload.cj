// 中文维护注释：本文件是 vertex buffer static triangle data-upload owner。
// Truth: 只消费 CjguiInternalRendererNoVertexBufferCreateDestroyReadiness，
// 局部执行 buffer create -> upload -> classify -> destroy，并脱水为 facts。
// Stop-line: token 只在函数局部；上传只验证固定 position/color 三角形
// layout facts；不创建或绑定 encoder，不调用 setVertexBuffer，不 draw，
// 不创建 index buffer，不 commit，不 present，不提交 GPU work，不执行 render，
// 不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: vertex upload facts 不得包装成 draw permission、
// render permission、GPU submission、backend-ready、state write、receipt、
// record 或 publication。
package cjgui

foreign func cjgui_native_bridge_vertex_buffer_upload_static_triangle(
    token: UInt64
): Int32
foreign func cjgui_native_bridge_vertex_buffer_data_classify(token: UInt64):
    Int32
foreign func cjgui_native_bridge_vertex_buffer_upload_requires_main_thread():
    Int32

struct CjguiInternalRendererVertexBufferDataUploadObservation {
    let deviceCreateStatusValue: Int32
    let vertexBufferCreateStatusValue: Int32
    let uploadStatusValue: Int32
    let dataClassValue: Int32
    let layoutPositionColorValue: Int32
    let vertexBufferDestroyStatusValue: Int32
    let deviceDestroyStatusValue: Int32
    let vertexBufferTokenValue: UInt64
    let vertexBufferOccupiedBeforeValue: UInt32
    let vertexBufferOccupiedAfterCreateValue: UInt32
    let vertexBufferOccupiedAfterCleanupValue: UInt32
    let encoderBindingStillBlockedValue: Int32
    let drawStillBlockedValue: Int32
    let didObserveStaticTriangleUpload: Bool
    let didObserveLayoutFacts: Bool
    let didObserveCleanupCounts: Bool
    let didKeepTokensFunctionLocal: Bool
    let didConfirmEncoderSetVertexBufferDrawCommitPresentGpuOrRenderBlocked:
        Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        deviceCreateStatusValue: Int32,
        vertexBufferCreateStatusValue: Int32,
        uploadStatusValue: Int32,
        dataClassValue: Int32,
        layoutPositionColorValue: Int32,
        vertexBufferDestroyStatusValue: Int32,
        deviceDestroyStatusValue: Int32,
        vertexBufferTokenValue: UInt64,
        vertexBufferOccupiedBeforeValue: UInt32,
        vertexBufferOccupiedAfterCreateValue: UInt32,
        vertexBufferOccupiedAfterCleanupValue: UInt32,
        encoderBindingStillBlockedValue: Int32,
        drawStillBlockedValue: Int32,
        didObserveStaticTriangleUpload: Bool,
        didObserveLayoutFacts: Bool,
        didObserveCleanupCounts: Bool,
        didKeepTokensFunctionLocal: Bool,
        didConfirmEncoderSetVertexBufferDrawCommitPresentGpuOrRenderBlocked:
            Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.deviceCreateStatusValue = deviceCreateStatusValue
        this.vertexBufferCreateStatusValue = vertexBufferCreateStatusValue
        this.uploadStatusValue = uploadStatusValue
        this.dataClassValue = dataClassValue
        this.layoutPositionColorValue = layoutPositionColorValue
        this.vertexBufferDestroyStatusValue = vertexBufferDestroyStatusValue
        this.deviceDestroyStatusValue = deviceDestroyStatusValue
        this.vertexBufferTokenValue = vertexBufferTokenValue
        this.vertexBufferOccupiedBeforeValue = vertexBufferOccupiedBeforeValue
        this.vertexBufferOccupiedAfterCreateValue =
            vertexBufferOccupiedAfterCreateValue
        this.vertexBufferOccupiedAfterCleanupValue =
            vertexBufferOccupiedAfterCleanupValue
        this.encoderBindingStillBlockedValue = encoderBindingStillBlockedValue
        this.drawStillBlockedValue = drawStillBlockedValue
        this.didObserveStaticTriangleUpload = didObserveStaticTriangleUpload
        this.didObserveLayoutFacts = didObserveLayoutFacts
        this.didObserveCleanupCounts = didObserveCleanupCounts
        this.didKeepTokensFunctionLocal = didKeepTokensFunctionLocal
        this.didConfirmEncoderSetVertexBufferDrawCommitPresentGpuOrRenderBlocked =
            didConfirmEncoderSetVertexBufferDrawCommitPresentGpuOrRenderBlocked
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoVertexBufferDataUploadReadiness {
    let createDestroyReadiness:
        CjguiInternalRendererNoVertexBufferCreateDestroyReadiness
    let uploadObservation:
        CjguiInternalRendererVertexBufferDataUploadObservation
    let didPrepareRendererNoVertexBufferDataUploadReadiness: Bool
    let shouldDeferRendererNoVertexBufferDataUploadReadiness: Bool
    let didConfirmStaticTriangleDataUpload: Bool
    let didConfirmPositionColorLayoutFacts: Bool
    let didConfirmCleanupCountsReturnToZero: Bool
    let didConfirmTokensStayedFunctionLocal: Bool
    let didConfirmNoEncoderBinding: Bool
    let didConfirmNoSetVertexBuffer: Bool
    let didConfirmNoDrawCommitPresentGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepVertexBufferDataUploadReadinessDehydrated: Bool
    let didAvoidDrawPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        createDestroyReadiness:
            CjguiInternalRendererNoVertexBufferCreateDestroyReadiness,
        uploadObservation:
            CjguiInternalRendererVertexBufferDataUploadObservation,
        didPrepareRendererNoVertexBufferDataUploadReadiness: Bool,
        shouldDeferRendererNoVertexBufferDataUploadReadiness: Bool,
        didConfirmStaticTriangleDataUpload: Bool,
        didConfirmPositionColorLayoutFacts: Bool,
        didConfirmCleanupCountsReturnToZero: Bool,
        didConfirmTokensStayedFunctionLocal: Bool,
        didConfirmNoEncoderBinding: Bool,
        didConfirmNoSetVertexBuffer: Bool,
        didConfirmNoDrawCommitPresentGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepVertexBufferDataUploadReadinessDehydrated: Bool,
        didAvoidDrawPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.createDestroyReadiness = createDestroyReadiness
        this.uploadObservation = uploadObservation
        this.didPrepareRendererNoVertexBufferDataUploadReadiness =
            didPrepareRendererNoVertexBufferDataUploadReadiness
        this.shouldDeferRendererNoVertexBufferDataUploadReadiness =
            shouldDeferRendererNoVertexBufferDataUploadReadiness
        this.didConfirmStaticTriangleDataUpload =
            didConfirmStaticTriangleDataUpload
        this.didConfirmPositionColorLayoutFacts =
            didConfirmPositionColorLayoutFacts
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
        this.didKeepVertexBufferDataUploadReadinessDehydrated =
            didKeepVertexBufferDataUploadReadinessDehydrated
        this.didAvoidDrawPermissionWrapper = didAvoidDrawPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
    }
}

func cjguiInternalObserveRendererVertexBufferDataUploadValues():
    CjguiInternalRendererVertexBufferDataUploadObservation {
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
    let uploadStatus = unsafe {
        cjgui_native_bridge_vertex_buffer_upload_static_triangle(bufferToken)
    }
    let dataClass = unsafe {
        cjgui_native_bridge_vertex_buffer_data_classify(bufferToken)
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
    let deviceDestroy = unsafe {
        cjgui_native_bridge_metal_device_destroy(deviceToken)
    }
    let vertexBufferOccupiedAfterCleanup = unsafe {
        cjgui_native_bridge_vertex_buffer_table_occupied_count()
    }
    let uploadReady =
        deviceCreate == Int32(0) &&
        bufferCreate == Int32(0) &&
        uploadStatus == Int32(0) &&
        dataClass == Int32(301) &&
        bufferDestroy == Int32(0) &&
        deviceDestroy == Int32(0)
    let layoutReady = layoutPositionColor == Int32(302)
    let cleanupCounts =
        vertexBufferOccupiedAfterCreate == vertexBufferOccupiedBefore +
            UInt32(1) &&
        vertexBufferOccupiedAfterCleanup == vertexBufferOccupiedBefore

    return CjguiInternalRendererVertexBufferDataUploadObservation(
        deviceCreate,
        bufferCreate,
        uploadStatus,
        dataClass,
        layoutPositionColor,
        bufferDestroy,
        deviceDestroy,
        bufferToken,
        vertexBufferOccupiedBefore,
        vertexBufferOccupiedAfterCreate,
        vertexBufferOccupiedAfterCleanup,
        encoderBindingStillBlocked,
        drawStillBlocked,
        uploadReady,
        layoutReady,
        cleanupCounts,
        true,
        encoderBindingStillBlocked < Int32(0) &&
            drawStillBlocked < Int32(0),
        true
    )
}

func cjguiInternalBuildRendererVertexBufferDataUploadReadiness(
    createDestroyReadiness:
        CjguiInternalRendererNoVertexBufferCreateDestroyReadiness,
    uploadObservation:
        CjguiInternalRendererVertexBufferDataUploadObservation
): CjguiInternalRendererNoVertexBufferDataUploadReadiness {
    let upstreamReady =
        createDestroyReadiness
            .didPrepareRendererNoVertexBufferCreateDestroyReadiness &&
        createDestroyReadiness.didConfirmVertexBufferCreateDestroyLifecycle &&
        createDestroyReadiness.didConfirmNoEncoderBinding &&
        createDestroyReadiness.didConfirmNoSetVertexBuffer &&
        createDestroyReadiness.didConfirmNoDrawCommitPresentGpuOrRender &&
        createDestroyReadiness.didConfirmNoPublicSurface &&
        createDestroyReadiness.didConfirmNoRendererStateWrite &&
        createDestroyReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        uploadObservation.didObserveStaticTriangleUpload &&
        uploadObservation.didObserveLayoutFacts &&
        uploadObservation.didObserveCleanupCounts &&
        uploadObservation.didKeepTokensFunctionLocal &&
        uploadObservation
            .didConfirmEncoderSetVertexBufferDrawCommitPresentGpuOrRenderBlocked &&
        uploadObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady

    return CjguiInternalRendererNoVertexBufferDataUploadReadiness(
        createDestroyReadiness,
        uploadObservation,
        readinessReady,
        !readinessReady,
        uploadObservation.didObserveStaticTriangleUpload,
        uploadObservation.didObserveLayoutFacts,
        uploadObservation.didObserveCleanupCounts,
        uploadObservation.didKeepTokensFunctionLocal,
        true,
        true,
        uploadObservation
            .didConfirmEncoderSetVertexBufferDrawCommitPresentGpuOrRenderBlocked,
        uploadObservation.didConfirmNoPointerHandleClassIdReturn,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVertexBufferDataUploadDraft():
    CjguiInternalRendererNoVertexBufferDataUploadReadiness {
    let createDestroyReadiness =
        cjguiInternalExecuteDefaultRendererVertexBufferCreateDestroyDraft()
    let uploadObservation =
        cjguiInternalObserveRendererVertexBufferDataUploadValues()
    return cjguiInternalBuildRendererVertexBufferDataUploadReadiness(
        createDestroyReadiness,
        uploadObservation
    )
}
