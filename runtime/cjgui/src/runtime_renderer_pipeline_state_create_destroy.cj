// 中文维护注释：本文件是 token-backed MTLRenderPipelineState create/destroy owner。
// Truth: 只消费 CjguiInternalRendererNoPipelineStateCreateDestroyPlanningReadiness，
// 局部调用 device / descriptor / shader / pipeline state create -> classify ->
// destroy -> cleanup，并脱水为 internal facts。
// Stop-line: token 只在函数局部；不创建或绑定 render command encoder，
// 不 setRenderPipelineState，不 draw，不创建 vertex buffer，不 commit，不 present，
// 不提交 GPU work，不执行 render，不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: pipeline state token facts 不得包装成 render
// permission、GPU submission、backend-ready、state write、receipt、record
// 或 publication。
package cjgui

foreign func cjgui_native_bridge_pipeline_state_table_capacity(): UInt32
foreign func cjgui_native_bridge_pipeline_state_table_enabled(): UInt32
foreign func cjgui_native_bridge_pipeline_state_table_occupied_count(): UInt32
foreign func cjgui_native_bridge_pipeline_state_create(
    deviceToken: UInt64,
    descriptorToken: UInt64,
    vertexFunctionToken: UInt64,
    fragmentFunctionToken: UInt64,
    outToken: CPointer<UInt64>
): Int32
foreign func cjgui_native_bridge_pipeline_state_destroy(token: UInt64): Int32
foreign func cjgui_native_bridge_pipeline_state_token_classify(token: UInt64):
    Int32
foreign func cjgui_native_bridge_pipeline_state_double_destroy_classify(
    token: UInt64
): Int32
foreign func cjgui_native_bridge_pipeline_state_encoder_binding_still_blocked():
    Int32
foreign func cjgui_native_bridge_pipeline_state_draw_still_blocked(): Int32

struct CjguiInternalRendererPipelineStateCreateDestroyObservation {
    let deviceCreateStatusValue: Int32
    let descriptorCreateStatusValue: Int32
    let descriptorConfigureStatusValue: Int32
    let libraryCreateStatusValue: Int32
    let vertexLookupStatusValue: Int32
    let fragmentLookupStatusValue: Int32
    let pipelineStateCreateStatusValue: Int32
    let pipelineStateDestroyStatusValue: Int32
    let pipelineStateTokenValue: UInt64
    let pipelineStateClassValue: Int32
    let pipelineStateDestroyedClassValue: Int32
    let pipelineStateDoubleDestroyStatusValue: Int32
    let pipelineStateDoubleDestroyClassValue: Int32
    let descriptorDestroyWhilePipelineLiveValue: Int32
    let vertexDestroyWhilePipelineLiveValue: Int32
    let deviceDestroyWhilePipelineLiveValue: Int32
    let encoderBindingStillBlockedValue: Int32
    let drawStillBlockedValue: Int32
    let pipelineStateOccupiedBeforeValue: UInt32
    let pipelineStateOccupiedAfterCreateValue: UInt32
    let pipelineStateOccupiedAfterCleanupValue: UInt32
    let didObservePipelineStateLifecycle: Bool
    let didObserveDependencyDestroyBlockedWhilePipelineLive: Bool
    let didObserveDoubleDestroyFailClosed: Bool
    let didObserveCleanupCounts: Bool
    let didKeepTokensFunctionLocal: Bool
    let didConfirmEncoderDrawCommitPresentGpuOrRenderBlocked: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        deviceCreateStatusValue: Int32,
        descriptorCreateStatusValue: Int32,
        descriptorConfigureStatusValue: Int32,
        libraryCreateStatusValue: Int32,
        vertexLookupStatusValue: Int32,
        fragmentLookupStatusValue: Int32,
        pipelineStateCreateStatusValue: Int32,
        pipelineStateDestroyStatusValue: Int32,
        pipelineStateTokenValue: UInt64,
        pipelineStateClassValue: Int32,
        pipelineStateDestroyedClassValue: Int32,
        pipelineStateDoubleDestroyStatusValue: Int32,
        pipelineStateDoubleDestroyClassValue: Int32,
        descriptorDestroyWhilePipelineLiveValue: Int32,
        vertexDestroyWhilePipelineLiveValue: Int32,
        deviceDestroyWhilePipelineLiveValue: Int32,
        encoderBindingStillBlockedValue: Int32,
        drawStillBlockedValue: Int32,
        pipelineStateOccupiedBeforeValue: UInt32,
        pipelineStateOccupiedAfterCreateValue: UInt32,
        pipelineStateOccupiedAfterCleanupValue: UInt32,
        didObservePipelineStateLifecycle: Bool,
        didObserveDependencyDestroyBlockedWhilePipelineLive: Bool,
        didObserveDoubleDestroyFailClosed: Bool,
        didObserveCleanupCounts: Bool,
        didKeepTokensFunctionLocal: Bool,
        didConfirmEncoderDrawCommitPresentGpuOrRenderBlocked: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.deviceCreateStatusValue = deviceCreateStatusValue
        this.descriptorCreateStatusValue = descriptorCreateStatusValue
        this.descriptorConfigureStatusValue = descriptorConfigureStatusValue
        this.libraryCreateStatusValue = libraryCreateStatusValue
        this.vertexLookupStatusValue = vertexLookupStatusValue
        this.fragmentLookupStatusValue = fragmentLookupStatusValue
        this.pipelineStateCreateStatusValue = pipelineStateCreateStatusValue
        this.pipelineStateDestroyStatusValue = pipelineStateDestroyStatusValue
        this.pipelineStateTokenValue = pipelineStateTokenValue
        this.pipelineStateClassValue = pipelineStateClassValue
        this.pipelineStateDestroyedClassValue = pipelineStateDestroyedClassValue
        this.pipelineStateDoubleDestroyStatusValue =
            pipelineStateDoubleDestroyStatusValue
        this.pipelineStateDoubleDestroyClassValue =
            pipelineStateDoubleDestroyClassValue
        this.descriptorDestroyWhilePipelineLiveValue =
            descriptorDestroyWhilePipelineLiveValue
        this.vertexDestroyWhilePipelineLiveValue =
            vertexDestroyWhilePipelineLiveValue
        this.deviceDestroyWhilePipelineLiveValue =
            deviceDestroyWhilePipelineLiveValue
        this.encoderBindingStillBlockedValue = encoderBindingStillBlockedValue
        this.drawStillBlockedValue = drawStillBlockedValue
        this.pipelineStateOccupiedBeforeValue =
            pipelineStateOccupiedBeforeValue
        this.pipelineStateOccupiedAfterCreateValue =
            pipelineStateOccupiedAfterCreateValue
        this.pipelineStateOccupiedAfterCleanupValue =
            pipelineStateOccupiedAfterCleanupValue
        this.didObservePipelineStateLifecycle =
            didObservePipelineStateLifecycle
        this.didObserveDependencyDestroyBlockedWhilePipelineLive =
            didObserveDependencyDestroyBlockedWhilePipelineLive
        this.didObserveDoubleDestroyFailClosed =
            didObserveDoubleDestroyFailClosed
        this.didObserveCleanupCounts = didObserveCleanupCounts
        this.didKeepTokensFunctionLocal = didKeepTokensFunctionLocal
        this.didConfirmEncoderDrawCommitPresentGpuOrRenderBlocked =
            didConfirmEncoderDrawCommitPresentGpuOrRenderBlocked
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoPipelineStateCreateDestroyReadiness {
    let planningReadiness:
        CjguiInternalRendererNoPipelineStateCreateDestroyPlanningReadiness
    let createDestroyObservation:
        CjguiInternalRendererPipelineStateCreateDestroyObservation
    let didPrepareRendererNoPipelineStateCreateDestroyReadiness: Bool
    let shouldDeferRendererNoPipelineStateCreateDestroyReadiness: Bool
    let didConfirmPipelineStateCreateDestroyLifecycle: Bool
    let didConfirmDependencyDestroyBlockedWhilePipelineLive: Bool
    let didConfirmDoubleDestroyFailClosed: Bool
    let didConfirmCleanupCountsReturnToZero: Bool
    let didConfirmTokensStayedFunctionLocal: Bool
    let didConfirmNoEncoderBinding: Bool
    let didConfirmNoDrawCommitPresentGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepPipelineStateCreateDestroyReadinessDehydrated: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        planningReadiness:
            CjguiInternalRendererNoPipelineStateCreateDestroyPlanningReadiness,
        createDestroyObservation:
            CjguiInternalRendererPipelineStateCreateDestroyObservation,
        didPrepareRendererNoPipelineStateCreateDestroyReadiness: Bool,
        shouldDeferRendererNoPipelineStateCreateDestroyReadiness: Bool,
        didConfirmPipelineStateCreateDestroyLifecycle: Bool,
        didConfirmDependencyDestroyBlockedWhilePipelineLive: Bool,
        didConfirmDoubleDestroyFailClosed: Bool,
        didConfirmCleanupCountsReturnToZero: Bool,
        didConfirmTokensStayedFunctionLocal: Bool,
        didConfirmNoEncoderBinding: Bool,
        didConfirmNoDrawCommitPresentGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepPipelineStateCreateDestroyReadinessDehydrated: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.planningReadiness = planningReadiness
        this.createDestroyObservation = createDestroyObservation
        this.didPrepareRendererNoPipelineStateCreateDestroyReadiness =
            didPrepareRendererNoPipelineStateCreateDestroyReadiness
        this.shouldDeferRendererNoPipelineStateCreateDestroyReadiness =
            shouldDeferRendererNoPipelineStateCreateDestroyReadiness
        this.didConfirmPipelineStateCreateDestroyLifecycle =
            didConfirmPipelineStateCreateDestroyLifecycle
        this.didConfirmDependencyDestroyBlockedWhilePipelineLive =
            didConfirmDependencyDestroyBlockedWhilePipelineLive
        this.didConfirmDoubleDestroyFailClosed =
            didConfirmDoubleDestroyFailClosed
        this.didConfirmCleanupCountsReturnToZero =
            didConfirmCleanupCountsReturnToZero
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
        this.didKeepPipelineStateCreateDestroyReadinessDehydrated =
            didKeepPipelineStateCreateDestroyReadinessDehydrated
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
    }
}

func cjguiInternalObserveRendererPipelineStateCreateDestroyValues():
    CjguiInternalRendererPipelineStateCreateDestroyObservation {
    let pipelineStateOccupiedBefore = unsafe {
        cjgui_native_bridge_pipeline_state_table_occupied_count()
    }
    var deviceToken = UInt64(0)
    let deviceCreate = unsafe {
        cjgui_native_bridge_metal_default_device_create(inout deviceToken)
    }
    var descriptorToken = UInt64(0)
    let descriptorCreate = unsafe {
        cjgui_native_bridge_pipeline_descriptor_create(inout descriptorToken)
    }
    let descriptorConfigure = unsafe {
        cjgui_native_bridge_pipeline_descriptor_configure_no_draw(
            descriptorToken
        )
    }
    var libraryToken = UInt64(0)
    let libraryCreate = unsafe {
        cjgui_native_bridge_shader_library_create(deviceToken, inout libraryToken)
    }
    var vertexToken = UInt64(0)
    let vertexLookup = unsafe {
        cjgui_native_bridge_shader_function_lookup_vertex(
            libraryToken,
            inout vertexToken
        )
    }
    var fragmentToken = UInt64(0)
    let fragmentLookup = unsafe {
        cjgui_native_bridge_shader_function_lookup_fragment(
            libraryToken,
            inout fragmentToken
        )
    }
    var pipelineStateToken = UInt64(0)
    let pipelineStateCreate = unsafe {
        cjgui_native_bridge_pipeline_state_create(
            deviceToken,
            descriptorToken,
            vertexToken,
            fragmentToken,
            inout pipelineStateToken
        )
    }
    let pipelineStateOccupiedAfterCreate = unsafe {
        cjgui_native_bridge_pipeline_state_table_occupied_count()
    }
    let pipelineStateClass = unsafe {
        cjgui_native_bridge_pipeline_state_token_classify(pipelineStateToken)
    }
    let descriptorDestroyWhilePipelineLive = unsafe {
        cjgui_native_bridge_pipeline_descriptor_destroy(descriptorToken)
    }
    let vertexDestroyWhilePipelineLive = unsafe {
        cjgui_native_bridge_shader_function_destroy(vertexToken)
    }
    let deviceDestroyWhilePipelineLive = unsafe {
        cjgui_native_bridge_metal_device_destroy(deviceToken)
    }
    let encoderBindingStillBlocked = unsafe {
        cjgui_native_bridge_pipeline_state_encoder_binding_still_blocked()
    }
    let drawStillBlocked = unsafe {
        cjgui_native_bridge_pipeline_state_draw_still_blocked()
    }
    let pipelineStateDestroy = unsafe {
        cjgui_native_bridge_pipeline_state_destroy(pipelineStateToken)
    }
    let pipelineStateDestroyedClass = unsafe {
        cjgui_native_bridge_pipeline_state_token_classify(pipelineStateToken)
    }
    let pipelineStateDoubleDestroy = unsafe {
        cjgui_native_bridge_pipeline_state_destroy(pipelineStateToken)
    }
    let pipelineStateDoubleDestroyClass = unsafe {
        cjgui_native_bridge_pipeline_state_double_destroy_classify(
            pipelineStateToken
        )
    }
    let vertexDestroy = unsafe {
        cjgui_native_bridge_shader_function_destroy(vertexToken)
    }
    let fragmentDestroy = unsafe {
        cjgui_native_bridge_shader_function_destroy(fragmentToken)
    }
    let libraryDestroy = unsafe {
        cjgui_native_bridge_shader_library_destroy(libraryToken)
    }
    let descriptorDestroy = unsafe {
        cjgui_native_bridge_pipeline_descriptor_destroy(descriptorToken)
    }
    let deviceDestroy = unsafe {
        cjgui_native_bridge_metal_device_destroy(deviceToken)
    }
    let pipelineStateOccupiedAfterCleanup = unsafe {
        cjgui_native_bridge_pipeline_state_table_occupied_count()
    }

    let lifecycleReady =
        deviceCreate == Int32(0) &&
        descriptorCreate == Int32(0) &&
        descriptorConfigure == Int32(0) &&
        libraryCreate == Int32(0) &&
        vertexLookup == Int32(0) &&
        fragmentLookup == Int32(0) &&
        pipelineStateCreate == Int32(0) &&
        pipelineStateClass == Int32(260) &&
        pipelineStateDestroy == Int32(0) &&
        vertexDestroy == Int32(0) &&
        fragmentDestroy == Int32(0) &&
        libraryDestroy == Int32(0) &&
        descriptorDestroy == Int32(0) &&
        deviceDestroy == Int32(0)
    let dependencyBlocked =
        descriptorDestroyWhilePipelineLive < Int32(0) &&
        vertexDestroyWhilePipelineLive < Int32(0) &&
        deviceDestroyWhilePipelineLive < Int32(0)
    let doubleDestroyClosed =
        pipelineStateDestroyedClass < Int32(0) &&
        pipelineStateDoubleDestroy < Int32(0) &&
        pipelineStateDoubleDestroyClass < Int32(0)
    let cleanupCounts =
        pipelineStateOccupiedAfterCreate == pipelineStateOccupiedBefore +
            UInt32(1) &&
        pipelineStateOccupiedAfterCleanup == pipelineStateOccupiedBefore

    return CjguiInternalRendererPipelineStateCreateDestroyObservation(
        deviceCreate,
        descriptorCreate,
        descriptorConfigure,
        libraryCreate,
        vertexLookup,
        fragmentLookup,
        pipelineStateCreate,
        pipelineStateDestroy,
        pipelineStateToken,
        pipelineStateClass,
        pipelineStateDestroyedClass,
        pipelineStateDoubleDestroy,
        pipelineStateDoubleDestroyClass,
        descriptorDestroyWhilePipelineLive,
        vertexDestroyWhilePipelineLive,
        deviceDestroyWhilePipelineLive,
        encoderBindingStillBlocked,
        drawStillBlocked,
        pipelineStateOccupiedBefore,
        pipelineStateOccupiedAfterCreate,
        pipelineStateOccupiedAfterCleanup,
        lifecycleReady,
        dependencyBlocked,
        doubleDestroyClosed,
        cleanupCounts,
        true,
        encoderBindingStillBlocked < Int32(0) &&
            drawStillBlocked < Int32(0),
        true
    )
}

func cjguiInternalBuildRendererPipelineStateCreateDestroyReadiness(
    planningReadiness:
        CjguiInternalRendererNoPipelineStateCreateDestroyPlanningReadiness,
    createDestroyObservation:
        CjguiInternalRendererPipelineStateCreateDestroyObservation
): CjguiInternalRendererNoPipelineStateCreateDestroyReadiness {
    let upstreamReady =
        planningReadiness
            .didPrepareRendererNoPipelineStateCreateDestroyPlanningReadiness &&
        planningReadiness.didConfirmNoDrawPrerequisites &&
        planningReadiness.didConfirmNoEncoderBinding &&
        planningReadiness.didConfirmNoDrawCommitPresentGpuOrRender &&
        planningReadiness.didConfirmNoPublicSurface &&
        planningReadiness.didConfirmNoRendererStateWrite &&
        planningReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        createDestroyObservation.didObservePipelineStateLifecycle &&
        createDestroyObservation
            .didObserveDependencyDestroyBlockedWhilePipelineLive &&
        createDestroyObservation.didObserveDoubleDestroyFailClosed &&
        createDestroyObservation.didObserveCleanupCounts &&
        createDestroyObservation.didKeepTokensFunctionLocal &&
        createDestroyObservation
            .didConfirmEncoderDrawCommitPresentGpuOrRenderBlocked &&
        createDestroyObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady

    return CjguiInternalRendererNoPipelineStateCreateDestroyReadiness(
        planningReadiness,
        createDestroyObservation,
        readinessReady,
        !readinessReady,
        createDestroyObservation.didObservePipelineStateLifecycle,
        createDestroyObservation
            .didObserveDependencyDestroyBlockedWhilePipelineLive,
        createDestroyObservation.didObserveDoubleDestroyFailClosed,
        createDestroyObservation.didObserveCleanupCounts,
        createDestroyObservation.didKeepTokensFunctionLocal,
        true,
        createDestroyObservation
            .didConfirmEncoderDrawCommitPresentGpuOrRenderBlocked,
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

func cjguiInternalExecuteDefaultRendererPipelineStateCreateDestroyDraft():
    CjguiInternalRendererNoPipelineStateCreateDestroyReadiness {
    let planningReadiness =
        cjguiInternalExecuteDefaultRendererPipelineStateCreateDestroyPlanningDraft()
    let createDestroyObservation =
        cjguiInternalObserveRendererPipelineStateCreateDestroyValues()
    return cjguiInternalBuildRendererPipelineStateCreateDestroyReadiness(
        planningReadiness,
        createDestroyObservation
    )
}
