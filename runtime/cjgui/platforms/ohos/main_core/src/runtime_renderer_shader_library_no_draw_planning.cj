// 中文维护注释：本文件是 shader library no-draw planning owner。
// Truth: 只消费 CjguiInternalRendererNoPipelineDescriptorRuntimeCallReadiness，
// 固定 shader source / library / function 的 no-draw 前置合同。
// Stop-line: 不创建 MTLRenderPipelineState，不创建或绑定 encoder，不 draw，
// 不创建 vertex buffer，不 commit，不 present，不提交 GPU work，不执行 render，
// 不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: shader planning facts 不得包装成 pipeline-ready、
// render permission、GPU submission、backend-ready、state write、receipt、record
// 或 publication。
package cjgui

foreign func cjgui_native_bridge_shader_source_contract_available(): Int32
foreign func cjgui_native_bridge_shader_library_table_capacity(): UInt32
foreign func cjgui_native_bridge_shader_library_table_enabled(): UInt32
foreign func cjgui_native_bridge_shader_library_table_occupied_count(): UInt32
foreign func cjgui_native_bridge_shader_library_create(
    deviceToken: UInt64,
    outLibraryToken: CPointer<UInt64>
): Int32
foreign func cjgui_native_bridge_shader_library_destroy(
    libraryToken: UInt64
): Int32
foreign func cjgui_native_bridge_shader_library_token_classify(
    libraryToken: UInt64
): Int32
foreign func cjgui_native_bridge_shader_library_double_destroy_classify(
    libraryToken: UInt64
): Int32
foreign func cjgui_native_bridge_shader_library_create_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_shader_library_destroy_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_shader_function_table_capacity(): UInt32
foreign func cjgui_native_bridge_shader_function_table_enabled(): UInt32
foreign func cjgui_native_bridge_shader_function_table_occupied_count(): UInt32
foreign func cjgui_native_bridge_shader_function_lookup_vertex(
    libraryToken: UInt64,
    outFunctionToken: CPointer<UInt64>
): Int32
foreign func cjgui_native_bridge_shader_function_lookup_fragment(
    libraryToken: UInt64,
    outFunctionToken: CPointer<UInt64>
): Int32
foreign func cjgui_native_bridge_shader_function_destroy(
    functionToken: UInt64
): Int32
foreign func cjgui_native_bridge_shader_function_token_classify(
    functionToken: UInt64
): Int32
foreign func cjgui_native_bridge_shader_function_double_destroy_classify(
    functionToken: UInt64
): Int32
foreign func cjgui_native_bridge_shader_function_lookup_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_shader_function_destroy_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_shader_function_missing_classify(): Int32
foreign func cjgui_native_bridge_shader_pipeline_state_creation_still_blocked():
    Int32
foreign func cjgui_native_bridge_shader_encoder_binding_still_blocked(): Int32
foreign func cjgui_native_bridge_shader_draw_still_blocked(): Int32

struct CjguiInternalRendererShaderLibraryNoDrawPlanningFacts {
    let sourceContractValue: Int32
    let libraryCapacityValue: UInt32
    let functionCapacityValue: UInt32
    let pipelineStateStillBlockedValue: Int32
    let encoderBindingStillBlockedValue: Int32
    let drawStillBlockedValue: Int32
    let didConfirmShaderSourceRequirement: Bool
    let didConfirmLibraryCreationRequirement: Bool
    let didConfirmVertexFunctionRequirement: Bool
    let didConfirmFragmentFunctionRequirement: Bool
    let didConfirmPipelineStateStillBlocked: Bool
    let didConfirmEncoderBindingBlocked: Bool
    let didConfirmDrawBlocked: Bool
    let didConfirmNoGpuSubmitOrRender: Bool

    init(
        sourceContractValue: Int32,
        libraryCapacityValue: UInt32,
        functionCapacityValue: UInt32,
        pipelineStateStillBlockedValue: Int32,
        encoderBindingStillBlockedValue: Int32,
        drawStillBlockedValue: Int32,
        didConfirmShaderSourceRequirement: Bool,
        didConfirmLibraryCreationRequirement: Bool,
        didConfirmVertexFunctionRequirement: Bool,
        didConfirmFragmentFunctionRequirement: Bool,
        didConfirmPipelineStateStillBlocked: Bool,
        didConfirmEncoderBindingBlocked: Bool,
        didConfirmDrawBlocked: Bool,
        didConfirmNoGpuSubmitOrRender: Bool
    ) {
        this.sourceContractValue = sourceContractValue
        this.libraryCapacityValue = libraryCapacityValue
        this.functionCapacityValue = functionCapacityValue
        this.pipelineStateStillBlockedValue = pipelineStateStillBlockedValue
        this.encoderBindingStillBlockedValue = encoderBindingStillBlockedValue
        this.drawStillBlockedValue = drawStillBlockedValue
        this.didConfirmShaderSourceRequirement =
            didConfirmShaderSourceRequirement
        this.didConfirmLibraryCreationRequirement =
            didConfirmLibraryCreationRequirement
        this.didConfirmVertexFunctionRequirement =
            didConfirmVertexFunctionRequirement
        this.didConfirmFragmentFunctionRequirement =
            didConfirmFragmentFunctionRequirement
        this.didConfirmPipelineStateStillBlocked =
            didConfirmPipelineStateStillBlocked
        this.didConfirmEncoderBindingBlocked = didConfirmEncoderBindingBlocked
        this.didConfirmDrawBlocked = didConfirmDrawBlocked
        this.didConfirmNoGpuSubmitOrRender = didConfirmNoGpuSubmitOrRender
    }
}

struct CjguiInternalRendererNoShaderLibraryNoDrawPlanningReadiness {
    let pipelineDescriptorRuntimeCallReadiness:
        CjguiInternalRendererNoPipelineDescriptorRuntimeCallReadiness
    let planningFacts: CjguiInternalRendererShaderLibraryNoDrawPlanningFacts
    let didPrepareRendererNoShaderLibraryNoDrawPlanningReadiness: Bool
    let shouldDeferRendererNoShaderLibraryNoDrawPlanningReadiness: Bool
    let didConfirmShaderSourceLibraryFunctionRequirements: Bool
    let didConfirmPipelineStateEncoderDrawStillBlocked: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepShaderPlanningReadinessDehydrated: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        pipelineDescriptorRuntimeCallReadiness:
            CjguiInternalRendererNoPipelineDescriptorRuntimeCallReadiness,
        planningFacts: CjguiInternalRendererShaderLibraryNoDrawPlanningFacts,
        didPrepareRendererNoShaderLibraryNoDrawPlanningReadiness: Bool,
        shouldDeferRendererNoShaderLibraryNoDrawPlanningReadiness: Bool,
        didConfirmShaderSourceLibraryFunctionRequirements: Bool,
        didConfirmPipelineStateEncoderDrawStillBlocked: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepShaderPlanningReadinessDehydrated: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.pipelineDescriptorRuntimeCallReadiness =
            pipelineDescriptorRuntimeCallReadiness
        this.planningFacts = planningFacts
        this.didPrepareRendererNoShaderLibraryNoDrawPlanningReadiness =
            didPrepareRendererNoShaderLibraryNoDrawPlanningReadiness
        this.shouldDeferRendererNoShaderLibraryNoDrawPlanningReadiness =
            shouldDeferRendererNoShaderLibraryNoDrawPlanningReadiness
        this.didConfirmShaderSourceLibraryFunctionRequirements =
            didConfirmShaderSourceLibraryFunctionRequirements
        this.didConfirmPipelineStateEncoderDrawStillBlocked =
            didConfirmPipelineStateEncoderDrawStillBlocked
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepShaderPlanningReadinessDehydrated =
            didKeepShaderPlanningReadinessDehydrated
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererShaderLibraryNoDrawPlanningFacts():
    CjguiInternalRendererShaderLibraryNoDrawPlanningFacts {
    let sourceContract = unsafe {
        cjgui_native_bridge_shader_source_contract_available()
    }
    let libraryCapacity = unsafe {
        cjgui_native_bridge_shader_library_table_capacity()
    }
    let functionCapacity = unsafe {
        cjgui_native_bridge_shader_function_table_capacity()
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

    return CjguiInternalRendererShaderLibraryNoDrawPlanningFacts(
        sourceContract,
        libraryCapacity,
        functionCapacity,
        pipelineStateBlocked,
        encoderBlocked,
        drawBlocked,
        sourceContract == Int32(240),
        libraryCapacity > UInt32(0),
        functionCapacity > UInt32(0),
        functionCapacity >= UInt32(2),
        pipelineStateBlocked == Int32(-252),
        encoderBlocked == Int32(-253),
        drawBlocked == Int32(-254),
        true
    )
}

func cjguiInternalBuildRendererShaderLibraryNoDrawPlanningReadiness(
    pipelineDescriptorRuntimeCallReadiness:
        CjguiInternalRendererNoPipelineDescriptorRuntimeCallReadiness,
    planningFacts: CjguiInternalRendererShaderLibraryNoDrawPlanningFacts
): CjguiInternalRendererNoShaderLibraryNoDrawPlanningReadiness {
    let upstreamReady =
        pipelineDescriptorRuntimeCallReadiness
            .didPrepareRendererNoPipelineDescriptorRuntimeCallReadiness &&
        pipelineDescriptorRuntimeCallReadiness
            .didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender &&
        pipelineDescriptorRuntimeCallReadiness.didConfirmNoPublicSurface &&
        pipelineDescriptorRuntimeCallReadiness.didConfirmNoRendererStateWrite &&
        pipelineDescriptorRuntimeCallReadiness.didConfirmNoBackendReadyTruth
    let requirementsReady =
        planningFacts.didConfirmShaderSourceRequirement &&
        planningFacts.didConfirmLibraryCreationRequirement &&
        planningFacts.didConfirmVertexFunctionRequirement &&
        planningFacts.didConfirmFragmentFunctionRequirement
    let blockersReady =
        planningFacts.didConfirmPipelineStateStillBlocked &&
        planningFacts.didConfirmEncoderBindingBlocked &&
        planningFacts.didConfirmDrawBlocked &&
        planningFacts.didConfirmNoGpuSubmitOrRender
    let readinessReady = upstreamReady && requirementsReady && blockersReady

    return CjguiInternalRendererNoShaderLibraryNoDrawPlanningReadiness(
        pipelineDescriptorRuntimeCallReadiness,
        planningFacts,
        readinessReady,
        !readinessReady,
        requirementsReady,
        blockersReady,
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

func cjguiInternalExecuteDefaultRendererShaderLibraryNoDrawPlanningDraft():
    CjguiInternalRendererNoShaderLibraryNoDrawPlanningReadiness {
    let pipelineDescriptorRuntimeCallReadiness =
        cjguiInternalExecuteDefaultRendererPipelineDescriptorRuntimeCallDraft()
    let planningFacts =
        cjguiInternalObserveRendererShaderLibraryNoDrawPlanningFacts()
    return cjguiInternalBuildRendererShaderLibraryNoDrawPlanningReadiness(
        pipelineDescriptorRuntimeCallReadiness,
        planningFacts
    )
}
