// 中文维护注释：本文件是 token-backed MTLRenderPipelineDescriptor create/destroy first-slice owner。
// Truth: 只消费 CjguiInternalRendererNoPipelineDescriptorPlanningReadiness，
// 调用 pipeline descriptor create / classify / destroy C ABI，并把 token 生命周期
// 脱水为 internal facts。
// Stop-line: 不创建 pipeline state，不创建 shader library / function，不配置 shader，
// 不创建或绑定 encoder，不调用 setRenderPipelineState，不 draw，不创建 vertex buffer，
// 不 commit，不 present，不提交 GPU work，不执行 render，不返回 token 到 public surface，
// 不写 runtime_state.cj。
// Same-shape Boundary Brake: pipeline descriptor token facts 不得包装成 render-ready、
// GPU submission、backend-ready、state write、receipt、record 或 publication。
package cjgui

foreign func cjgui_native_bridge_pipeline_descriptor_table_capacity(): UInt32
foreign func cjgui_native_bridge_pipeline_descriptor_table_enabled(): UInt32
foreign func cjgui_native_bridge_pipeline_descriptor_table_occupied_count():
    UInt32
foreign func cjgui_native_bridge_pipeline_descriptor_create(
    outDescriptorToken: CPointer<UInt64>
): Int32
foreign func cjgui_native_bridge_pipeline_descriptor_destroy(
    descriptorToken: UInt64
): Int32
foreign func cjgui_native_bridge_pipeline_descriptor_token_classify(
    descriptorToken: UInt64
): Int32
foreign func cjgui_native_bridge_pipeline_descriptor_double_destroy_classify(
    descriptorToken: UInt64
): Int32
foreign func cjgui_native_bridge_pipeline_descriptor_create_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_pipeline_descriptor_destroy_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_pipeline_descriptor_configure_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_pipeline_descriptor_configure_no_draw(
    descriptorToken: UInt64
): Int32
foreign func cjgui_native_bridge_pipeline_descriptor_color_pixel_format_classify(
    descriptorToken: UInt64
): Int32
foreign func cjgui_native_bridge_pipeline_descriptor_sample_count_classify(
    descriptorToken: UInt64
): Int32
foreign func cjgui_native_bridge_pipeline_descriptor_shader_library_still_blocked():
    Int32
foreign func cjgui_native_bridge_pipeline_descriptor_vertex_function_still_blocked():
    Int32
foreign func cjgui_native_bridge_pipeline_descriptor_fragment_function_still_blocked():
    Int32
foreign func cjgui_native_bridge_pipeline_descriptor_blending_still_blocked():
    Int32
foreign func cjgui_native_bridge_pipeline_descriptor_encoder_binding_still_blocked():
    Int32
foreign func cjgui_native_bridge_pipeline_state_creation_still_blocked():
    Int32

struct CjguiInternalRendererPipelineDescriptorCreateDestroyObservation {
    let descriptorCreateStatusValue: Int32
    let descriptorDestroyStatusValue: Int32
    let descriptorTokenValue: UInt64
    let descriptorValidClassValue: Int32
    let descriptorDestroyedClassValue: Int32
    let descriptorDoubleDestroyStatusValue: Int32
    let descriptorDoubleDestroyClassValue: Int32
    let invalidDescriptorDestroyStatusValue: Int32
    let descriptorCreateRequiresMainThreadValue: Int32
    let descriptorDestroyRequiresMainThreadValue: Int32
    let descriptorConfigureRequiresMainThreadValue: Int32
    let pipelineStateCreationStillBlockedValue: Int32
    let shaderLibraryStillBlockedValue: Int32
    let vertexFunctionStillBlockedValue: Int32
    let fragmentFunctionStillBlockedValue: Int32
    let blendingStillBlockedValue: Int32
    let encoderBindingStillBlockedValue: Int32
    let descriptorTableCapacityValue: UInt32
    let descriptorTableEnabledValue: UInt32
    let descriptorOccupiedBeforeValue: UInt32
    let descriptorOccupiedAfterCreateValue: UInt32
    let descriptorOccupiedAfterDestroyValue: UInt32
    let didObserveDescriptorCreateToken: Bool
    let didObserveOpaqueDescriptorToken: Bool
    let didObserveDescriptorValidClassification: Bool
    let didObserveDescriptorOccupiedLifecycle: Bool
    let didObserveDescriptorDestroy: Bool
    let didObserveDescriptorDestroyedStale: Bool
    let didObserveDescriptorDoubleDestroyFailClosed: Bool
    let didObserveInvalidDescriptorDestroyFailClosed: Bool
    let didObserveMainThreadDescriptorGate: Bool
    let didObserveNoDrawBlockers: Bool
    let didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        descriptorCreateStatusValue: Int32,
        descriptorDestroyStatusValue: Int32,
        descriptorTokenValue: UInt64,
        descriptorValidClassValue: Int32,
        descriptorDestroyedClassValue: Int32,
        descriptorDoubleDestroyStatusValue: Int32,
        descriptorDoubleDestroyClassValue: Int32,
        invalidDescriptorDestroyStatusValue: Int32,
        descriptorCreateRequiresMainThreadValue: Int32,
        descriptorDestroyRequiresMainThreadValue: Int32,
        descriptorConfigureRequiresMainThreadValue: Int32,
        pipelineStateCreationStillBlockedValue: Int32,
        shaderLibraryStillBlockedValue: Int32,
        vertexFunctionStillBlockedValue: Int32,
        fragmentFunctionStillBlockedValue: Int32,
        blendingStillBlockedValue: Int32,
        encoderBindingStillBlockedValue: Int32,
        descriptorTableCapacityValue: UInt32,
        descriptorTableEnabledValue: UInt32,
        descriptorOccupiedBeforeValue: UInt32,
        descriptorOccupiedAfterCreateValue: UInt32,
        descriptorOccupiedAfterDestroyValue: UInt32,
        didObserveDescriptorCreateToken: Bool,
        didObserveOpaqueDescriptorToken: Bool,
        didObserveDescriptorValidClassification: Bool,
        didObserveDescriptorOccupiedLifecycle: Bool,
        didObserveDescriptorDestroy: Bool,
        didObserveDescriptorDestroyedStale: Bool,
        didObserveDescriptorDoubleDestroyFailClosed: Bool,
        didObserveInvalidDescriptorDestroyFailClosed: Bool,
        didObserveMainThreadDescriptorGate: Bool,
        didObserveNoDrawBlockers: Bool,
        didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.descriptorCreateStatusValue = descriptorCreateStatusValue
        this.descriptorDestroyStatusValue = descriptorDestroyStatusValue
        this.descriptorTokenValue = descriptorTokenValue
        this.descriptorValidClassValue = descriptorValidClassValue
        this.descriptorDestroyedClassValue = descriptorDestroyedClassValue
        this.descriptorDoubleDestroyStatusValue =
            descriptorDoubleDestroyStatusValue
        this.descriptorDoubleDestroyClassValue =
            descriptorDoubleDestroyClassValue
        this.invalidDescriptorDestroyStatusValue =
            invalidDescriptorDestroyStatusValue
        this.descriptorCreateRequiresMainThreadValue =
            descriptorCreateRequiresMainThreadValue
        this.descriptorDestroyRequiresMainThreadValue =
            descriptorDestroyRequiresMainThreadValue
        this.descriptorConfigureRequiresMainThreadValue =
            descriptorConfigureRequiresMainThreadValue
        this.pipelineStateCreationStillBlockedValue =
            pipelineStateCreationStillBlockedValue
        this.shaderLibraryStillBlockedValue = shaderLibraryStillBlockedValue
        this.vertexFunctionStillBlockedValue = vertexFunctionStillBlockedValue
        this.fragmentFunctionStillBlockedValue =
            fragmentFunctionStillBlockedValue
        this.blendingStillBlockedValue = blendingStillBlockedValue
        this.encoderBindingStillBlockedValue = encoderBindingStillBlockedValue
        this.descriptorTableCapacityValue = descriptorTableCapacityValue
        this.descriptorTableEnabledValue = descriptorTableEnabledValue
        this.descriptorOccupiedBeforeValue = descriptorOccupiedBeforeValue
        this.descriptorOccupiedAfterCreateValue =
            descriptorOccupiedAfterCreateValue
        this.descriptorOccupiedAfterDestroyValue =
            descriptorOccupiedAfterDestroyValue
        this.didObserveDescriptorCreateToken = didObserveDescriptorCreateToken
        this.didObserveOpaqueDescriptorToken = didObserveOpaqueDescriptorToken
        this.didObserveDescriptorValidClassification =
            didObserveDescriptorValidClassification
        this.didObserveDescriptorOccupiedLifecycle =
            didObserveDescriptorOccupiedLifecycle
        this.didObserveDescriptorDestroy = didObserveDescriptorDestroy
        this.didObserveDescriptorDestroyedStale =
            didObserveDescriptorDestroyedStale
        this.didObserveDescriptorDoubleDestroyFailClosed =
            didObserveDescriptorDoubleDestroyFailClosed
        this.didObserveInvalidDescriptorDestroyFailClosed =
            didObserveInvalidDescriptorDestroyFailClosed
        this.didObserveMainThreadDescriptorGate =
            didObserveMainThreadDescriptorGate
        this.didObserveNoDrawBlockers = didObserveNoDrawBlockers
        this.didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender =
            didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoPipelineDescriptorCreateDestroyReadiness {
    let pipelineDescriptorPlanningReadiness:
        CjguiInternalRendererNoPipelineDescriptorPlanningReadiness
    let createDestroyObservation:
        CjguiInternalRendererPipelineDescriptorCreateDestroyObservation
    let didPrepareRendererNoPipelineDescriptorCreateDestroyReadiness: Bool
    let shouldDeferRendererNoPipelineDescriptorCreateDestroyReadiness: Bool
    let shouldReportRendererPipelineDescriptorCreateDestroyBlocked: Bool
    let didPreserveRendererPipelineDescriptorPlanningReadiness: Bool
    let didConfirmTokenBackedPipelineDescriptorCreateDestroy: Bool
    let didConfirmMainThreadDescriptorGate: Bool
    let didConfirmDescriptorDoubleDestroyFailClosed: Bool
    let didConfirmCleanupCountsReturnToZero: Bool
    let didConfirmShaderLibraryAndFunctionsStillBlocked: Bool
    let didConfirmPipelineStateCreationStillBlocked: Bool
    let didConfirmBlendingStillBlocked: Bool
    let didConfirmEncoderBindingStillBlocked: Bool
    let didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepPipelineDescriptorCreateDestroyReadinessDehydrated: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        pipelineDescriptorPlanningReadiness:
            CjguiInternalRendererNoPipelineDescriptorPlanningReadiness,
        createDestroyObservation:
            CjguiInternalRendererPipelineDescriptorCreateDestroyObservation,
        didPrepareRendererNoPipelineDescriptorCreateDestroyReadiness: Bool,
        shouldDeferRendererNoPipelineDescriptorCreateDestroyReadiness: Bool,
        shouldReportRendererPipelineDescriptorCreateDestroyBlocked: Bool,
        didPreserveRendererPipelineDescriptorPlanningReadiness: Bool,
        didConfirmTokenBackedPipelineDescriptorCreateDestroy: Bool,
        didConfirmMainThreadDescriptorGate: Bool,
        didConfirmDescriptorDoubleDestroyFailClosed: Bool,
        didConfirmCleanupCountsReturnToZero: Bool,
        didConfirmShaderLibraryAndFunctionsStillBlocked: Bool,
        didConfirmPipelineStateCreationStillBlocked: Bool,
        didConfirmBlendingStillBlocked: Bool,
        didConfirmEncoderBindingStillBlocked: Bool,
        didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepPipelineDescriptorCreateDestroyReadinessDehydrated: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.pipelineDescriptorPlanningReadiness =
            pipelineDescriptorPlanningReadiness
        this.createDestroyObservation = createDestroyObservation
        this.didPrepareRendererNoPipelineDescriptorCreateDestroyReadiness =
            didPrepareRendererNoPipelineDescriptorCreateDestroyReadiness
        this.shouldDeferRendererNoPipelineDescriptorCreateDestroyReadiness =
            shouldDeferRendererNoPipelineDescriptorCreateDestroyReadiness
        this.shouldReportRendererPipelineDescriptorCreateDestroyBlocked =
            shouldReportRendererPipelineDescriptorCreateDestroyBlocked
        this.didPreserveRendererPipelineDescriptorPlanningReadiness =
            didPreserveRendererPipelineDescriptorPlanningReadiness
        this.didConfirmTokenBackedPipelineDescriptorCreateDestroy =
            didConfirmTokenBackedPipelineDescriptorCreateDestroy
        this.didConfirmMainThreadDescriptorGate =
            didConfirmMainThreadDescriptorGate
        this.didConfirmDescriptorDoubleDestroyFailClosed =
            didConfirmDescriptorDoubleDestroyFailClosed
        this.didConfirmCleanupCountsReturnToZero =
            didConfirmCleanupCountsReturnToZero
        this.didConfirmShaderLibraryAndFunctionsStillBlocked =
            didConfirmShaderLibraryAndFunctionsStillBlocked
        this.didConfirmPipelineStateCreationStillBlocked =
            didConfirmPipelineStateCreationStillBlocked
        this.didConfirmBlendingStillBlocked = didConfirmBlendingStillBlocked
        this.didConfirmEncoderBindingStillBlocked =
            didConfirmEncoderBindingStillBlocked
        this.didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender =
            didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepPipelineDescriptorCreateDestroyReadinessDehydrated =
            didKeepPipelineDescriptorCreateDestroyReadinessDehydrated
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererPipelineDescriptorCreateDestroyValues():
    CjguiInternalRendererPipelineDescriptorCreateDestroyObservation {
    let descriptorOccupiedBefore = unsafe {
        cjgui_native_bridge_pipeline_descriptor_table_occupied_count()
    }
    let descriptorCapacity = unsafe {
        cjgui_native_bridge_pipeline_descriptor_table_capacity()
    }
    let descriptorEnabled = unsafe {
        cjgui_native_bridge_pipeline_descriptor_table_enabled()
    }
    var descriptorToken = UInt64(0)
    let descriptorCreateStatus = unsafe {
        cjgui_native_bridge_pipeline_descriptor_create(inout descriptorToken)
    }
    let descriptorOccupiedAfterCreate = unsafe {
        cjgui_native_bridge_pipeline_descriptor_table_occupied_count()
    }
    let descriptorValidClass = unsafe {
        cjgui_native_bridge_pipeline_descriptor_token_classify(descriptorToken)
    }
    let descriptorCreateRequiresMainThread = unsafe {
        cjgui_native_bridge_pipeline_descriptor_create_requires_main_thread()
    }
    let descriptorDestroyRequiresMainThread = unsafe {
        cjgui_native_bridge_pipeline_descriptor_destroy_requires_main_thread()
    }
    let descriptorConfigureRequiresMainThread = unsafe {
        cjgui_native_bridge_pipeline_descriptor_configure_requires_main_thread()
    }
    let pipelineStateCreationStillBlocked = unsafe {
        cjgui_native_bridge_pipeline_state_creation_still_blocked()
    }
    let shaderLibraryStillBlocked = unsafe {
        cjgui_native_bridge_pipeline_descriptor_shader_library_still_blocked()
    }
    let vertexFunctionStillBlocked = unsafe {
        cjgui_native_bridge_pipeline_descriptor_vertex_function_still_blocked()
    }
    let fragmentFunctionStillBlocked = unsafe {
        cjgui_native_bridge_pipeline_descriptor_fragment_function_still_blocked()
    }
    let blendingStillBlocked = unsafe {
        cjgui_native_bridge_pipeline_descriptor_blending_still_blocked()
    }
    let encoderBindingStillBlocked = unsafe {
        cjgui_native_bridge_pipeline_descriptor_encoder_binding_still_blocked()
    }
    let invalidDescriptorDestroyStatus = unsafe {
        cjgui_native_bridge_pipeline_descriptor_destroy(UInt64(0))
    }
    let descriptorDestroyStatus = unsafe {
        cjgui_native_bridge_pipeline_descriptor_destroy(descriptorToken)
    }
    let descriptorOccupiedAfterDestroy = unsafe {
        cjgui_native_bridge_pipeline_descriptor_table_occupied_count()
    }
    let descriptorDestroyedClass = unsafe {
        cjgui_native_bridge_pipeline_descriptor_token_classify(descriptorToken)
    }
    let descriptorDoubleDestroyStatus = unsafe {
        cjgui_native_bridge_pipeline_descriptor_destroy(descriptorToken)
    }
    let descriptorDoubleDestroyClass = unsafe {
        cjgui_native_bridge_pipeline_descriptor_double_destroy_classify(
            descriptorToken
        )
    }

    return CjguiInternalRendererPipelineDescriptorCreateDestroyObservation(
        descriptorCreateStatus,
        descriptorDestroyStatus,
        descriptorToken,
        descriptorValidClass,
        descriptorDestroyedClass,
        descriptorDoubleDestroyStatus,
        descriptorDoubleDestroyClass,
        invalidDescriptorDestroyStatus,
        descriptorCreateRequiresMainThread,
        descriptorDestroyRequiresMainThread,
        descriptorConfigureRequiresMainThread,
        pipelineStateCreationStillBlocked,
        shaderLibraryStillBlocked,
        vertexFunctionStillBlocked,
        fragmentFunctionStillBlocked,
        blendingStillBlocked,
        encoderBindingStillBlocked,
        descriptorCapacity,
        descriptorEnabled,
        descriptorOccupiedBefore,
        descriptorOccupiedAfterCreate,
        descriptorOccupiedAfterDestroy,
        descriptorCreateStatus == Int32(0) &&
            descriptorToken != UInt64(0),
        descriptorToken != UInt64(0) && descriptorToken < UInt64(4294967296),
        descriptorValidClass == Int32(220),
        descriptorOccupiedAfterCreate == descriptorOccupiedBefore + UInt32(1) &&
            descriptorOccupiedAfterDestroy == descriptorOccupiedBefore,
        descriptorDestroyStatus == Int32(0),
        descriptorDestroyedClass == Int32(-223),
        descriptorDoubleDestroyStatus == Int32(-226) &&
            descriptorDoubleDestroyClass == Int32(-226),
        invalidDescriptorDestroyStatus == Int32(-222),
        descriptorCreateRequiresMainThread == Int32(-220) &&
            descriptorDestroyRequiresMainThread == Int32(-221) &&
            descriptorConfigureRequiresMainThread == Int32(-238),
        pipelineStateCreationStillBlocked == Int32(-229) &&
            shaderLibraryStillBlocked == Int32(-230) &&
            vertexFunctionStillBlocked == Int32(-231) &&
            fragmentFunctionStillBlocked == Int32(-232) &&
            blendingStillBlocked == Int32(-233) &&
            encoderBindingStillBlocked == Int32(-234),
        true,
        true
    )
}

func cjguiInternalBuildRendererPipelineDescriptorCreateDestroyReadiness(
    pipelineDescriptorPlanningReadiness:
        CjguiInternalRendererNoPipelineDescriptorPlanningReadiness,
    createDestroyObservation:
        CjguiInternalRendererPipelineDescriptorCreateDestroyObservation
): CjguiInternalRendererNoPipelineDescriptorCreateDestroyReadiness {
    let upstreamReady =
        pipelineDescriptorPlanningReadiness
            .didPrepareRendererNoPipelineDescriptorPlanningReadiness &&
        pipelineDescriptorPlanningReadiness
            .didConfirmPipelineDescriptorRequirement &&
        pipelineDescriptorPlanningReadiness
            .didConfirmShaderLibraryAndFunctionStillBlocked &&
        pipelineDescriptorPlanningReadiness
            .didConfirmPipelineStateCreationStillBlocked &&
        pipelineDescriptorPlanningReadiness.didConfirmEncoderBindingStillBlocked &&
        pipelineDescriptorPlanningReadiness
            .didConfirmNoDrawVertexBufferCommitPresentGpuOrRender &&
        pipelineDescriptorPlanningReadiness.didConfirmNoPublicSurface &&
        pipelineDescriptorPlanningReadiness.didConfirmNoRendererStateWrite &&
        pipelineDescriptorPlanningReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        createDestroyObservation.didObserveDescriptorCreateToken &&
        createDestroyObservation.didObserveOpaqueDescriptorToken &&
        createDestroyObservation.didObserveDescriptorValidClassification &&
        createDestroyObservation.didObserveDescriptorOccupiedLifecycle &&
        createDestroyObservation.didObserveDescriptorDestroy &&
        createDestroyObservation.didObserveDescriptorDestroyedStale &&
        createDestroyObservation
            .didObserveDescriptorDoubleDestroyFailClosed &&
        createDestroyObservation
            .didObserveInvalidDescriptorDestroyFailClosed &&
        createDestroyObservation.didObserveMainThreadDescriptorGate &&
        createDestroyObservation.didObserveNoDrawBlockers &&
        createDestroyObservation
            .didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender &&
        createDestroyObservation.didConfirmNoPointerHandleClassIdReturn
    let cleanupReady =
        createDestroyObservation.descriptorOccupiedAfterDestroyValue ==
            createDestroyObservation.descriptorOccupiedBeforeValue
    let readinessReady = upstreamReady && observationReady && cleanupReady

    return CjguiInternalRendererNoPipelineDescriptorCreateDestroyReadiness(
        pipelineDescriptorPlanningReadiness,
        createDestroyObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        createDestroyObservation.didObserveDescriptorCreateToken,
        createDestroyObservation.didObserveMainThreadDescriptorGate,
        createDestroyObservation.didObserveDescriptorDoubleDestroyFailClosed,
        cleanupReady,
        createDestroyObservation.shaderLibraryStillBlockedValue ==
            Int32(-230) &&
            createDestroyObservation.vertexFunctionStillBlockedValue ==
                Int32(-231) &&
            createDestroyObservation.fragmentFunctionStillBlockedValue ==
                Int32(-232),
        createDestroyObservation.pipelineStateCreationStillBlockedValue ==
            Int32(-229),
        createDestroyObservation.blendingStillBlockedValue == Int32(-233),
        createDestroyObservation.encoderBindingStillBlockedValue == Int32(-234),
        createDestroyObservation
            .didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender,
        createDestroyObservation.didConfirmNoPointerHandleClassIdReturn,
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

func cjguiInternalExecuteDefaultRendererPipelineDescriptorCreateDestroyDraft():
    CjguiInternalRendererNoPipelineDescriptorCreateDestroyReadiness {
    let pipelineDescriptorPlanningReadiness =
        cjguiInternalExecuteDefaultRendererPipelineDescriptorPlanningDraft()
    let createDestroyObservation =
        cjguiInternalObserveRendererPipelineDescriptorCreateDestroyValues()
    return cjguiInternalBuildRendererPipelineDescriptorCreateDestroyReadiness(
        pipelineDescriptorPlanningReadiness,
        createDestroyObservation
    )
}
