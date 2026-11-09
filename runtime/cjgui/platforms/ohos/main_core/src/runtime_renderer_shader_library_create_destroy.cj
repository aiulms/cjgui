// 中文维护注释：本文件是 token-backed MTLLibrary create/destroy owner。
// Truth: 只消费 CjguiInternalRendererNoShaderSourceContractReadiness，局部调用
// device create -> library create/classify/destroy -> device destroy，并脱水为 facts。
// Stop-line: token 只在函数局部；不创建 MTLRenderPipelineState，不 lookup function
// 之外的对象，不创建 encoder，不 draw，不 commit，不 present，不提交 GPU work，
// 不执行 render，不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: shader library token facts 不得包装成 pipeline-ready、
// render permission、GPU submission、backend-ready、state write、receipt、record
// 或 publication。
package cjgui

struct CjguiInternalRendererShaderLibraryCreateDestroyObservation {
    let deviceCreateStatusValue: Int32
    let libraryCreateStatusValue: Int32
    let libraryDestroyStatusValue: Int32
    let deviceDestroyStatusValue: Int32
    let deviceTokenValue: UInt64
    let libraryTokenValue: UInt64
    let libraryValidClassValue: Int32
    let libraryDestroyedClassValue: Int32
    let libraryDoubleDestroyStatusValue: Int32
    let libraryDoubleDestroyClassValue: Int32
    let invalidDeviceCreateStatusValue: Int32
    let invalidLibraryDestroyStatusValue: Int32
    let createRequiresMainThreadValue: Int32
    let destroyRequiresMainThreadValue: Int32
    let pipelineStateStillBlockedValue: Int32
    let encoderBindingStillBlockedValue: Int32
    let drawStillBlockedValue: Int32
    let libraryOccupiedBeforeValue: UInt32
    let libraryOccupiedAfterCreateValue: UInt32
    let libraryOccupiedAfterCleanupValue: UInt32
    let didObserveLibraryCreateDestroyLifecycle: Bool
    let didObserveOpaqueLibraryToken: Bool
    let didObserveDoubleDestroyFailClosed: Bool
    let didObserveInvalidTokenFailClosed: Bool
    let didObserveCleanupCounts: Bool
    let didConfirmPipelineStateEncoderDrawStillBlocked: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        deviceCreateStatusValue: Int32,
        libraryCreateStatusValue: Int32,
        libraryDestroyStatusValue: Int32,
        deviceDestroyStatusValue: Int32,
        deviceTokenValue: UInt64,
        libraryTokenValue: UInt64,
        libraryValidClassValue: Int32,
        libraryDestroyedClassValue: Int32,
        libraryDoubleDestroyStatusValue: Int32,
        libraryDoubleDestroyClassValue: Int32,
        invalidDeviceCreateStatusValue: Int32,
        invalidLibraryDestroyStatusValue: Int32,
        createRequiresMainThreadValue: Int32,
        destroyRequiresMainThreadValue: Int32,
        pipelineStateStillBlockedValue: Int32,
        encoderBindingStillBlockedValue: Int32,
        drawStillBlockedValue: Int32,
        libraryOccupiedBeforeValue: UInt32,
        libraryOccupiedAfterCreateValue: UInt32,
        libraryOccupiedAfterCleanupValue: UInt32,
        didObserveLibraryCreateDestroyLifecycle: Bool,
        didObserveOpaqueLibraryToken: Bool,
        didObserveDoubleDestroyFailClosed: Bool,
        didObserveInvalidTokenFailClosed: Bool,
        didObserveCleanupCounts: Bool,
        didConfirmPipelineStateEncoderDrawStillBlocked: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.deviceCreateStatusValue = deviceCreateStatusValue
        this.libraryCreateStatusValue = libraryCreateStatusValue
        this.libraryDestroyStatusValue = libraryDestroyStatusValue
        this.deviceDestroyStatusValue = deviceDestroyStatusValue
        this.deviceTokenValue = deviceTokenValue
        this.libraryTokenValue = libraryTokenValue
        this.libraryValidClassValue = libraryValidClassValue
        this.libraryDestroyedClassValue = libraryDestroyedClassValue
        this.libraryDoubleDestroyStatusValue = libraryDoubleDestroyStatusValue
        this.libraryDoubleDestroyClassValue = libraryDoubleDestroyClassValue
        this.invalidDeviceCreateStatusValue = invalidDeviceCreateStatusValue
        this.invalidLibraryDestroyStatusValue =
            invalidLibraryDestroyStatusValue
        this.createRequiresMainThreadValue = createRequiresMainThreadValue
        this.destroyRequiresMainThreadValue = destroyRequiresMainThreadValue
        this.pipelineStateStillBlockedValue = pipelineStateStillBlockedValue
        this.encoderBindingStillBlockedValue = encoderBindingStillBlockedValue
        this.drawStillBlockedValue = drawStillBlockedValue
        this.libraryOccupiedBeforeValue = libraryOccupiedBeforeValue
        this.libraryOccupiedAfterCreateValue = libraryOccupiedAfterCreateValue
        this.libraryOccupiedAfterCleanupValue =
            libraryOccupiedAfterCleanupValue
        this.didObserveLibraryCreateDestroyLifecycle =
            didObserveLibraryCreateDestroyLifecycle
        this.didObserveOpaqueLibraryToken = didObserveOpaqueLibraryToken
        this.didObserveDoubleDestroyFailClosed =
            didObserveDoubleDestroyFailClosed
        this.didObserveInvalidTokenFailClosed =
            didObserveInvalidTokenFailClosed
        this.didObserveCleanupCounts = didObserveCleanupCounts
        this.didConfirmPipelineStateEncoderDrawStillBlocked =
            didConfirmPipelineStateEncoderDrawStillBlocked
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoShaderLibraryCreateDestroyReadiness {
    let shaderSourceContractReadiness:
        CjguiInternalRendererNoShaderSourceContractReadiness
    let createDestroyObservation:
        CjguiInternalRendererShaderLibraryCreateDestroyObservation
    let didPrepareRendererNoShaderLibraryCreateDestroyReadiness: Bool
    let shouldDeferRendererNoShaderLibraryCreateDestroyReadiness: Bool
    let didConfirmLibraryCreateDestroyLifecycle: Bool
    let didConfirmOpaqueTokenIdentity: Bool
    let didConfirmTokenNotPointer: Bool
    let didConfirmDoubleDestroyFailClosed: Bool
    let didConfirmInvalidTokenFailClosed: Bool
    let didConfirmCleanupCountsReturnToZero: Bool
    let didConfirmPipelineStateEncoderDrawStillBlocked: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepShaderLibraryCreateDestroyReadinessDehydrated: Bool
    let didAvoidPipelineReadyWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool

    init(
        shaderSourceContractReadiness:
            CjguiInternalRendererNoShaderSourceContractReadiness,
        createDestroyObservation:
            CjguiInternalRendererShaderLibraryCreateDestroyObservation,
        didPrepareRendererNoShaderLibraryCreateDestroyReadiness: Bool,
        shouldDeferRendererNoShaderLibraryCreateDestroyReadiness: Bool,
        didConfirmLibraryCreateDestroyLifecycle: Bool,
        didConfirmOpaqueTokenIdentity: Bool,
        didConfirmTokenNotPointer: Bool,
        didConfirmDoubleDestroyFailClosed: Bool,
        didConfirmInvalidTokenFailClosed: Bool,
        didConfirmCleanupCountsReturnToZero: Bool,
        didConfirmPipelineStateEncoderDrawStillBlocked: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepShaderLibraryCreateDestroyReadinessDehydrated: Bool,
        didAvoidPipelineReadyWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool
    ) {
        this.shaderSourceContractReadiness = shaderSourceContractReadiness
        this.createDestroyObservation = createDestroyObservation
        this.didPrepareRendererNoShaderLibraryCreateDestroyReadiness =
            didPrepareRendererNoShaderLibraryCreateDestroyReadiness
        this.shouldDeferRendererNoShaderLibraryCreateDestroyReadiness =
            shouldDeferRendererNoShaderLibraryCreateDestroyReadiness
        this.didConfirmLibraryCreateDestroyLifecycle =
            didConfirmLibraryCreateDestroyLifecycle
        this.didConfirmOpaqueTokenIdentity = didConfirmOpaqueTokenIdentity
        this.didConfirmTokenNotPointer = didConfirmTokenNotPointer
        this.didConfirmDoubleDestroyFailClosed =
            didConfirmDoubleDestroyFailClosed
        this.didConfirmInvalidTokenFailClosed = didConfirmInvalidTokenFailClosed
        this.didConfirmCleanupCountsReturnToZero =
            didConfirmCleanupCountsReturnToZero
        this.didConfirmPipelineStateEncoderDrawStillBlocked =
            didConfirmPipelineStateEncoderDrawStillBlocked
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepShaderLibraryCreateDestroyReadinessDehydrated =
            didKeepShaderLibraryCreateDestroyReadinessDehydrated
        this.didAvoidPipelineReadyWrapper = didAvoidPipelineReadyWrapper
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
    }
}

func cjguiInternalObserveRendererShaderLibraryCreateDestroyValues():
    CjguiInternalRendererShaderLibraryCreateDestroyObservation {
    let libraryOccupiedBefore = unsafe {
        cjgui_native_bridge_shader_library_table_occupied_count()
    }
    var invalidLibraryToken = UInt64(0)
    let invalidDeviceCreate = unsafe {
        cjgui_native_bridge_shader_library_create(
            UInt64(0),
            inout invalidLibraryToken
        )
    }
    var deviceToken = UInt64(0)
    let deviceCreate = unsafe {
        cjgui_native_bridge_metal_default_device_create(inout deviceToken)
    }
    var libraryToken = UInt64(0)
    let libraryCreate = unsafe {
        cjgui_native_bridge_shader_library_create(deviceToken, inout libraryToken)
    }
    let libraryOccupiedAfterCreate = unsafe {
        cjgui_native_bridge_shader_library_table_occupied_count()
    }
    let libraryValidClass = unsafe {
        cjgui_native_bridge_shader_library_token_classify(libraryToken)
    }
    let pipelineStateBlocked = unsafe {
        cjgui_native_bridge_shader_pipeline_state_creation_still_blocked()
    }
    let encoderBlocked = unsafe {
        cjgui_native_bridge_shader_encoder_binding_still_blocked()
    }
    let drawBlocked = unsafe {
        cjgui_native_bridge_shader_draw_still_blocked()
    }
    let libraryDestroy = unsafe {
        cjgui_native_bridge_shader_library_destroy(libraryToken)
    }
    let libraryOccupiedAfterCleanup = unsafe {
        cjgui_native_bridge_shader_library_table_occupied_count()
    }
    let libraryDestroyedClass = unsafe {
        cjgui_native_bridge_shader_library_token_classify(libraryToken)
    }
    let libraryDoubleDestroy = unsafe {
        cjgui_native_bridge_shader_library_destroy(libraryToken)
    }
    let libraryDoubleDestroyClass = unsafe {
        cjgui_native_bridge_shader_library_double_destroy_classify(libraryToken)
    }
    let invalidLibraryDestroy = unsafe {
        cjgui_native_bridge_shader_library_destroy(UInt64(0))
    }
    let createRequiresMainThread = unsafe {
        cjgui_native_bridge_shader_library_create_requires_main_thread()
    }
    let destroyRequiresMainThread = unsafe {
        cjgui_native_bridge_shader_library_destroy_requires_main_thread()
    }
    let deviceDestroy = unsafe {
        cjgui_native_bridge_metal_device_destroy(deviceToken)
    }

    return CjguiInternalRendererShaderLibraryCreateDestroyObservation(
        deviceCreate,
        libraryCreate,
        libraryDestroy,
        deviceDestroy,
        deviceToken,
        libraryToken,
        libraryValidClass,
        libraryDestroyedClass,
        libraryDoubleDestroy,
        libraryDoubleDestroyClass,
        invalidDeviceCreate,
        invalidLibraryDestroy,
        createRequiresMainThread,
        destroyRequiresMainThread,
        pipelineStateBlocked,
        encoderBlocked,
        drawBlocked,
        libraryOccupiedBefore,
        libraryOccupiedAfterCreate,
        libraryOccupiedAfterCleanup,
        deviceCreate == Int32(0) &&
            libraryCreate == Int32(0) &&
            libraryDestroy == Int32(0) &&
            deviceDestroy == Int32(0),
        libraryToken != UInt64(0) &&
            libraryToken < UInt64(4294967296) &&
            libraryValidClass == Int32(241) &&
            libraryDestroyedClass == Int32(-243),
        libraryDoubleDestroy == Int32(-246) &&
            libraryDoubleDestroyClass == Int32(-246),
        invalidDeviceCreate < Int32(0) && invalidLibraryDestroy < Int32(0),
        libraryOccupiedBefore == libraryOccupiedAfterCleanup &&
            libraryOccupiedAfterCreate == libraryOccupiedBefore + UInt32(1),
        pipelineStateBlocked == Int32(-252) &&
            encoderBlocked == Int32(-253) &&
            drawBlocked == Int32(-254),
        true
    )
}

func cjguiInternalBuildRendererShaderLibraryCreateDestroyReadiness(
    shaderSourceContractReadiness:
        CjguiInternalRendererNoShaderSourceContractReadiness,
    createDestroyObservation:
        CjguiInternalRendererShaderLibraryCreateDestroyObservation
): CjguiInternalRendererNoShaderLibraryCreateDestroyReadiness {
    let upstreamReady =
        shaderSourceContractReadiness
            .didPrepareRendererNoShaderSourceContractReadiness &&
        shaderSourceContractReadiness
            .didConfirmPipelineStateEncoderDrawStillBlocked &&
        shaderSourceContractReadiness.didConfirmNoRendererStateWrite &&
        shaderSourceContractReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        createDestroyObservation.didObserveLibraryCreateDestroyLifecycle &&
        createDestroyObservation.didObserveOpaqueLibraryToken &&
        createDestroyObservation.didObserveDoubleDestroyFailClosed &&
        createDestroyObservation.didObserveInvalidTokenFailClosed &&
        createDestroyObservation.didObserveCleanupCounts &&
        createDestroyObservation.didConfirmPipelineStateEncoderDrawStillBlocked &&
        createDestroyObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady

    return CjguiInternalRendererNoShaderLibraryCreateDestroyReadiness(
        shaderSourceContractReadiness,
        createDestroyObservation,
        readinessReady,
        !readinessReady,
        createDestroyObservation.didObserveLibraryCreateDestroyLifecycle,
        createDestroyObservation.didObserveOpaqueLibraryToken,
        createDestroyObservation.didObserveOpaqueLibraryToken,
        createDestroyObservation.didObserveDoubleDestroyFailClosed,
        createDestroyObservation.didObserveInvalidTokenFailClosed,
        createDestroyObservation.didObserveCleanupCounts,
        createDestroyObservation.didConfirmPipelineStateEncoderDrawStillBlocked,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererShaderLibraryCreateDestroyDraft():
    CjguiInternalRendererNoShaderLibraryCreateDestroyReadiness {
    let shaderSourceContractReadiness =
        cjguiInternalExecuteDefaultRendererShaderSourceContractDraft()
    let createDestroyObservation =
        cjguiInternalObserveRendererShaderLibraryCreateDestroyValues()
    return cjguiInternalBuildRendererShaderLibraryCreateDestroyReadiness(
        shaderSourceContractReadiness,
        createDestroyObservation
    )
}
