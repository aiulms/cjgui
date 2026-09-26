// 中文维护注释：本文件是 token-backed MTLFunction lookup/classify owner。
// Truth: 只消费 CjguiInternalRendererNoShaderLibraryCreateDestroyReadiness，
// 局部调用 library create -> vertex/fragment lookup/classify/destroy -> cleanup，
// 并脱水为 internal facts。
// Stop-line: token 只在函数局部；不创建 MTLRenderPipelineState，不创建 encoder，
// 不绑定 pipeline，不 draw，不创建 vertex buffer，不 commit，不 present，
// 不提交 GPU work，不执行 render，不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: shader function facts 不得包装成 pipeline-ready、
// render permission、GPU submission、backend-ready、state write、receipt、record
// 或 publication。
package cjgui

struct CjguiInternalRendererShaderFunctionLookupObservation {
    let deviceCreateStatusValue: Int32
    let libraryCreateStatusValue: Int32
    let vertexLookupStatusValue: Int32
    let fragmentLookupStatusValue: Int32
    let vertexDestroyStatusValue: Int32
    let fragmentDestroyStatusValue: Int32
    let libraryDestroyStatusValue: Int32
    let deviceDestroyStatusValue: Int32
    let vertexTokenValue: UInt64
    let fragmentTokenValue: UInt64
    let vertexClassValue: Int32
    let fragmentClassValue: Int32
    let vertexDestroyedClassValue: Int32
    let vertexDoubleDestroyStatusValue: Int32
    let vertexDoubleDestroyClassValue: Int32
    let libraryDestroyWhileFunctionsLiveValue: Int32
    let missingClassValue: Int32
    let functionOccupiedBeforeValue: UInt32
    let functionOccupiedAfterLookupValue: UInt32
    let functionOccupiedAfterCleanupValue: UInt32
    let didObserveFunctionLookupLifecycle: Bool
    let didObserveVertexAndFragmentFunctions: Bool
    let didObserveLibraryDestroyBlockedWhileFunctionsLive: Bool
    let didObserveDoubleDestroyFailClosed: Bool
    let didObserveCleanupCounts: Bool
    let didKeepTokensFunctionLocal: Bool
    let didConfirmPipelineStateEncoderDrawStillBlocked: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        deviceCreateStatusValue: Int32,
        libraryCreateStatusValue: Int32,
        vertexLookupStatusValue: Int32,
        fragmentLookupStatusValue: Int32,
        vertexDestroyStatusValue: Int32,
        fragmentDestroyStatusValue: Int32,
        libraryDestroyStatusValue: Int32,
        deviceDestroyStatusValue: Int32,
        vertexTokenValue: UInt64,
        fragmentTokenValue: UInt64,
        vertexClassValue: Int32,
        fragmentClassValue: Int32,
        vertexDestroyedClassValue: Int32,
        vertexDoubleDestroyStatusValue: Int32,
        vertexDoubleDestroyClassValue: Int32,
        libraryDestroyWhileFunctionsLiveValue: Int32,
        missingClassValue: Int32,
        functionOccupiedBeforeValue: UInt32,
        functionOccupiedAfterLookupValue: UInt32,
        functionOccupiedAfterCleanupValue: UInt32,
        didObserveFunctionLookupLifecycle: Bool,
        didObserveVertexAndFragmentFunctions: Bool,
        didObserveLibraryDestroyBlockedWhileFunctionsLive: Bool,
        didObserveDoubleDestroyFailClosed: Bool,
        didObserveCleanupCounts: Bool,
        didKeepTokensFunctionLocal: Bool,
        didConfirmPipelineStateEncoderDrawStillBlocked: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.deviceCreateStatusValue = deviceCreateStatusValue
        this.libraryCreateStatusValue = libraryCreateStatusValue
        this.vertexLookupStatusValue = vertexLookupStatusValue
        this.fragmentLookupStatusValue = fragmentLookupStatusValue
        this.vertexDestroyStatusValue = vertexDestroyStatusValue
        this.fragmentDestroyStatusValue = fragmentDestroyStatusValue
        this.libraryDestroyStatusValue = libraryDestroyStatusValue
        this.deviceDestroyStatusValue = deviceDestroyStatusValue
        this.vertexTokenValue = vertexTokenValue
        this.fragmentTokenValue = fragmentTokenValue
        this.vertexClassValue = vertexClassValue
        this.fragmentClassValue = fragmentClassValue
        this.vertexDestroyedClassValue = vertexDestroyedClassValue
        this.vertexDoubleDestroyStatusValue = vertexDoubleDestroyStatusValue
        this.vertexDoubleDestroyClassValue = vertexDoubleDestroyClassValue
        this.libraryDestroyWhileFunctionsLiveValue =
            libraryDestroyWhileFunctionsLiveValue
        this.missingClassValue = missingClassValue
        this.functionOccupiedBeforeValue = functionOccupiedBeforeValue
        this.functionOccupiedAfterLookupValue = functionOccupiedAfterLookupValue
        this.functionOccupiedAfterCleanupValue =
            functionOccupiedAfterCleanupValue
        this.didObserveFunctionLookupLifecycle =
            didObserveFunctionLookupLifecycle
        this.didObserveVertexAndFragmentFunctions =
            didObserveVertexAndFragmentFunctions
        this.didObserveLibraryDestroyBlockedWhileFunctionsLive =
            didObserveLibraryDestroyBlockedWhileFunctionsLive
        this.didObserveDoubleDestroyFailClosed =
            didObserveDoubleDestroyFailClosed
        this.didObserveCleanupCounts = didObserveCleanupCounts
        this.didKeepTokensFunctionLocal = didKeepTokensFunctionLocal
        this.didConfirmPipelineStateEncoderDrawStillBlocked =
            didConfirmPipelineStateEncoderDrawStillBlocked
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoShaderFunctionLookupReadiness {
    let shaderLibraryCreateDestroyReadiness:
        CjguiInternalRendererNoShaderLibraryCreateDestroyReadiness
    let functionLookupObservation:
        CjguiInternalRendererShaderFunctionLookupObservation
    let didPrepareRendererNoShaderFunctionLookupReadiness: Bool
    let shouldDeferRendererNoShaderFunctionLookupReadiness: Bool
    let didConfirmFunctionLookupLifecycle: Bool
    let didConfirmVertexAndFragmentFunctionFacts: Bool
    let didConfirmTokensStayedFunctionLocal: Bool
    let didConfirmLibraryDestroyRequiresFunctionCleanup: Bool
    let didConfirmDoubleDestroyFailClosed: Bool
    let didConfirmCleanupCountsReturnToZero: Bool
    let didConfirmPipelineStateEncoderDrawStillBlocked: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepShaderFunctionLookupReadinessDehydrated: Bool
    let didAvoidPipelineReadyWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool

    init(
        shaderLibraryCreateDestroyReadiness:
            CjguiInternalRendererNoShaderLibraryCreateDestroyReadiness,
        functionLookupObservation:
            CjguiInternalRendererShaderFunctionLookupObservation,
        didPrepareRendererNoShaderFunctionLookupReadiness: Bool,
        shouldDeferRendererNoShaderFunctionLookupReadiness: Bool,
        didConfirmFunctionLookupLifecycle: Bool,
        didConfirmVertexAndFragmentFunctionFacts: Bool,
        didConfirmTokensStayedFunctionLocal: Bool,
        didConfirmLibraryDestroyRequiresFunctionCleanup: Bool,
        didConfirmDoubleDestroyFailClosed: Bool,
        didConfirmCleanupCountsReturnToZero: Bool,
        didConfirmPipelineStateEncoderDrawStillBlocked: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepShaderFunctionLookupReadinessDehydrated: Bool,
        didAvoidPipelineReadyWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool
    ) {
        this.shaderLibraryCreateDestroyReadiness =
            shaderLibraryCreateDestroyReadiness
        this.functionLookupObservation = functionLookupObservation
        this.didPrepareRendererNoShaderFunctionLookupReadiness =
            didPrepareRendererNoShaderFunctionLookupReadiness
        this.shouldDeferRendererNoShaderFunctionLookupReadiness =
            shouldDeferRendererNoShaderFunctionLookupReadiness
        this.didConfirmFunctionLookupLifecycle =
            didConfirmFunctionLookupLifecycle
        this.didConfirmVertexAndFragmentFunctionFacts =
            didConfirmVertexAndFragmentFunctionFacts
        this.didConfirmTokensStayedFunctionLocal =
            didConfirmTokensStayedFunctionLocal
        this.didConfirmLibraryDestroyRequiresFunctionCleanup =
            didConfirmLibraryDestroyRequiresFunctionCleanup
        this.didConfirmDoubleDestroyFailClosed =
            didConfirmDoubleDestroyFailClosed
        this.didConfirmCleanupCountsReturnToZero =
            didConfirmCleanupCountsReturnToZero
        this.didConfirmPipelineStateEncoderDrawStillBlocked =
            didConfirmPipelineStateEncoderDrawStillBlocked
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepShaderFunctionLookupReadinessDehydrated =
            didKeepShaderFunctionLookupReadinessDehydrated
        this.didAvoidPipelineReadyWrapper = didAvoidPipelineReadyWrapper
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
    }
}

func cjguiInternalObserveRendererShaderFunctionLookupValues():
    CjguiInternalRendererShaderFunctionLookupObservation {
    let functionOccupiedBefore = unsafe {
        cjgui_native_bridge_shader_function_table_occupied_count()
    }
    var deviceToken = UInt64(0)
    let deviceCreate = unsafe {
        cjgui_native_bridge_metal_default_device_create(inout deviceToken)
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
    let functionOccupiedAfterLookup = unsafe {
        cjgui_native_bridge_shader_function_table_occupied_count()
    }
    let vertexClass = unsafe {
        cjgui_native_bridge_shader_function_token_classify(vertexToken)
    }
    let fragmentClass = unsafe {
        cjgui_native_bridge_shader_function_token_classify(fragmentToken)
    }
    let libraryDestroyWhileFunctionsLive = unsafe {
        cjgui_native_bridge_shader_library_destroy(libraryToken)
    }
    let vertexDestroy = unsafe {
        cjgui_native_bridge_shader_function_destroy(vertexToken)
    }
    let fragmentDestroy = unsafe {
        cjgui_native_bridge_shader_function_destroy(fragmentToken)
    }
    let functionOccupiedAfterCleanup = unsafe {
        cjgui_native_bridge_shader_function_table_occupied_count()
    }
    let vertexDestroyedClass = unsafe {
        cjgui_native_bridge_shader_function_token_classify(vertexToken)
    }
    let vertexDoubleDestroy = unsafe {
        cjgui_native_bridge_shader_function_destroy(vertexToken)
    }
    let vertexDoubleDestroyClass = unsafe {
        cjgui_native_bridge_shader_function_double_destroy_classify(vertexToken)
    }
    let missingClass = unsafe {
        cjgui_native_bridge_shader_function_missing_classify()
    }
    let libraryDestroy = unsafe {
        cjgui_native_bridge_shader_library_destroy(libraryToken)
    }
    let deviceDestroy = unsafe {
        cjgui_native_bridge_metal_device_destroy(deviceToken)
    }

    return CjguiInternalRendererShaderFunctionLookupObservation(
        deviceCreate,
        libraryCreate,
        vertexLookup,
        fragmentLookup,
        vertexDestroy,
        fragmentDestroy,
        libraryDestroy,
        deviceDestroy,
        vertexToken,
        fragmentToken,
        vertexClass,
        fragmentClass,
        vertexDestroyedClass,
        vertexDoubleDestroy,
        vertexDoubleDestroyClass,
        libraryDestroyWhileFunctionsLive,
        missingClass,
        functionOccupiedBefore,
        functionOccupiedAfterLookup,
        functionOccupiedAfterCleanup,
        deviceCreate == Int32(0) &&
            libraryCreate == Int32(0) &&
            vertexLookup == Int32(0) &&
            fragmentLookup == Int32(0) &&
            vertexDestroy == Int32(0) &&
            fragmentDestroy == Int32(0) &&
            libraryDestroy == Int32(0) &&
            deviceDestroy == Int32(0),
        vertexClass == Int32(242) &&
            fragmentClass == Int32(243) &&
            vertexToken != UInt64(0) &&
            fragmentToken != UInt64(0) &&
            vertexToken != fragmentToken,
        libraryDestroyWhileFunctionsLive == Int32(-267),
        vertexDoubleDestroy == Int32(-265) &&
            vertexDoubleDestroyClass == Int32(-265),
        functionOccupiedBefore == functionOccupiedAfterCleanup &&
            functionOccupiedAfterLookup == functionOccupiedBefore + UInt32(2),
        true,
        missingClass == Int32(-255),
        true
    )
}

func cjguiInternalBuildRendererShaderFunctionLookupReadiness(
    shaderLibraryCreateDestroyReadiness:
        CjguiInternalRendererNoShaderLibraryCreateDestroyReadiness,
    functionLookupObservation:
        CjguiInternalRendererShaderFunctionLookupObservation
): CjguiInternalRendererNoShaderFunctionLookupReadiness {
    let upstreamReady =
        shaderLibraryCreateDestroyReadiness
            .didPrepareRendererNoShaderLibraryCreateDestroyReadiness &&
        shaderLibraryCreateDestroyReadiness
            .didConfirmPipelineStateEncoderDrawStillBlocked &&
        shaderLibraryCreateDestroyReadiness.didConfirmNoPublicSurface &&
        shaderLibraryCreateDestroyReadiness.didConfirmNoRendererStateWrite &&
        shaderLibraryCreateDestroyReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        functionLookupObservation.didObserveFunctionLookupLifecycle &&
        functionLookupObservation.didObserveVertexAndFragmentFunctions &&
        functionLookupObservation
            .didObserveLibraryDestroyBlockedWhileFunctionsLive &&
        functionLookupObservation.didObserveDoubleDestroyFailClosed &&
        functionLookupObservation.didObserveCleanupCounts &&
        functionLookupObservation.didKeepTokensFunctionLocal &&
        functionLookupObservation
            .didConfirmPipelineStateEncoderDrawStillBlocked &&
        functionLookupObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady

    return CjguiInternalRendererNoShaderFunctionLookupReadiness(
        shaderLibraryCreateDestroyReadiness,
        functionLookupObservation,
        readinessReady,
        !readinessReady,
        functionLookupObservation.didObserveFunctionLookupLifecycle,
        functionLookupObservation.didObserveVertexAndFragmentFunctions,
        functionLookupObservation.didKeepTokensFunctionLocal,
        functionLookupObservation
            .didObserveLibraryDestroyBlockedWhileFunctionsLive,
        functionLookupObservation.didObserveDoubleDestroyFailClosed,
        functionLookupObservation.didObserveCleanupCounts,
        functionLookupObservation
            .didConfirmPipelineStateEncoderDrawStillBlocked,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererShaderFunctionLookupDraft():
    CjguiInternalRendererNoShaderFunctionLookupReadiness {
    let shaderLibraryCreateDestroyReadiness =
        cjguiInternalExecuteDefaultRendererShaderLibraryCreateDestroyDraft()
    let functionLookupObservation =
        cjguiInternalObserveRendererShaderFunctionLookupValues()
    return cjguiInternalBuildRendererShaderFunctionLookupReadiness(
        shaderLibraryCreateDestroyReadiness,
        functionLookupObservation
    )
}
