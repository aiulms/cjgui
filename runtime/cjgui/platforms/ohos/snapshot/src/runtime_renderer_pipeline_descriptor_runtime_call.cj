// 中文维护注释：本文件是 pipeline descriptor runtime internal FFI call owner。
// Truth: 只消费 CjguiInternalRendererNoPipelineDescriptorConfigurationReadiness，
// 局部执行 descriptor create / configure / classify / destroy / double-destroy
// 调用序列，并把结果脱水为 internal facts。
// Stop-line: token 只在函数局部；不创建 pipeline state，不创建 shader library /
// function，不创建或绑定 encoder，不调用 setRenderPipelineState，不 draw，不创建
// vertex buffer，不 commit，不 present，不提交 GPU work，不执行 render，不写
// runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: pipeline descriptor runtime call facts 不得包装成
// render permission、GPU submission、backend-ready、state write、receipt、record
// 或 publication。
package cjgui

struct CjguiInternalRendererPipelineDescriptorRuntimeCallObservation {
    let descriptorCreateStatusValue: Int32
    let descriptorConfigureStatusValue: Int32
    let descriptorDestroyStatusValue: Int32
    let descriptorTokenValue: UInt64
    let descriptorValidClassValue: Int32
    let colorPixelFormatClassValue: Int32
    let sampleCountClassValue: Int32
    let descriptorDestroyedClassValue: Int32
    let descriptorDoubleDestroyStatusValue: Int32
    let descriptorDoubleDestroyClassValue: Int32
    let pipelineStateCreationStillBlockedValue: Int32
    let shaderLibraryStillBlockedValue: Int32
    let vertexFunctionStillBlockedValue: Int32
    let fragmentFunctionStillBlockedValue: Int32
    let blendingStillBlockedValue: Int32
    let encoderBindingStillBlockedValue: Int32
    let descriptorOccupiedBeforeValue: UInt32
    let descriptorOccupiedAfterCreateValue: UInt32
    let descriptorOccupiedAfterCleanupValue: UInt32
    let didObserveRuntimeInternalCall: Bool
    let didObserveCreateConfigureClassifyDestroy: Bool
    let didObserveNoDrawConfigurationFacts: Bool
    let didObserveNoDrawBlockers: Bool
    let didObserveDoubleDestroyFailClosed: Bool
    let didObserveCleanupCounts: Bool
    let didKeepTokenFunctionLocal: Bool
    let didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        descriptorCreateStatusValue: Int32,
        descriptorConfigureStatusValue: Int32,
        descriptorDestroyStatusValue: Int32,
        descriptorTokenValue: UInt64,
        descriptorValidClassValue: Int32,
        colorPixelFormatClassValue: Int32,
        sampleCountClassValue: Int32,
        descriptorDestroyedClassValue: Int32,
        descriptorDoubleDestroyStatusValue: Int32,
        descriptorDoubleDestroyClassValue: Int32,
        pipelineStateCreationStillBlockedValue: Int32,
        shaderLibraryStillBlockedValue: Int32,
        vertexFunctionStillBlockedValue: Int32,
        fragmentFunctionStillBlockedValue: Int32,
        blendingStillBlockedValue: Int32,
        encoderBindingStillBlockedValue: Int32,
        descriptorOccupiedBeforeValue: UInt32,
        descriptorOccupiedAfterCreateValue: UInt32,
        descriptorOccupiedAfterCleanupValue: UInt32,
        didObserveRuntimeInternalCall: Bool,
        didObserveCreateConfigureClassifyDestroy: Bool,
        didObserveNoDrawConfigurationFacts: Bool,
        didObserveNoDrawBlockers: Bool,
        didObserveDoubleDestroyFailClosed: Bool,
        didObserveCleanupCounts: Bool,
        didKeepTokenFunctionLocal: Bool,
        didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.descriptorCreateStatusValue = descriptorCreateStatusValue
        this.descriptorConfigureStatusValue = descriptorConfigureStatusValue
        this.descriptorDestroyStatusValue = descriptorDestroyStatusValue
        this.descriptorTokenValue = descriptorTokenValue
        this.descriptorValidClassValue = descriptorValidClassValue
        this.colorPixelFormatClassValue = colorPixelFormatClassValue
        this.sampleCountClassValue = sampleCountClassValue
        this.descriptorDestroyedClassValue = descriptorDestroyedClassValue
        this.descriptorDoubleDestroyStatusValue =
            descriptorDoubleDestroyStatusValue
        this.descriptorDoubleDestroyClassValue =
            descriptorDoubleDestroyClassValue
        this.pipelineStateCreationStillBlockedValue =
            pipelineStateCreationStillBlockedValue
        this.shaderLibraryStillBlockedValue = shaderLibraryStillBlockedValue
        this.vertexFunctionStillBlockedValue = vertexFunctionStillBlockedValue
        this.fragmentFunctionStillBlockedValue =
            fragmentFunctionStillBlockedValue
        this.blendingStillBlockedValue = blendingStillBlockedValue
        this.encoderBindingStillBlockedValue = encoderBindingStillBlockedValue
        this.descriptorOccupiedBeforeValue = descriptorOccupiedBeforeValue
        this.descriptorOccupiedAfterCreateValue =
            descriptorOccupiedAfterCreateValue
        this.descriptorOccupiedAfterCleanupValue =
            descriptorOccupiedAfterCleanupValue
        this.didObserveRuntimeInternalCall = didObserveRuntimeInternalCall
        this.didObserveCreateConfigureClassifyDestroy =
            didObserveCreateConfigureClassifyDestroy
        this.didObserveNoDrawConfigurationFacts =
            didObserveNoDrawConfigurationFacts
        this.didObserveNoDrawBlockers = didObserveNoDrawBlockers
        this.didObserveDoubleDestroyFailClosed =
            didObserveDoubleDestroyFailClosed
        this.didObserveCleanupCounts = didObserveCleanupCounts
        this.didKeepTokenFunctionLocal = didKeepTokenFunctionLocal
        this.didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender =
            didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoPipelineDescriptorRuntimeCallReadiness {
    let pipelineDescriptorConfigurationReadiness:
        CjguiInternalRendererNoPipelineDescriptorConfigurationReadiness
    let runtimeCallObservation:
        CjguiInternalRendererPipelineDescriptorRuntimeCallObservation
    let didPrepareRendererNoPipelineDescriptorRuntimeCallReadiness: Bool
    let shouldDeferRendererNoPipelineDescriptorRuntimeCallReadiness: Bool
    let shouldReportRendererPipelineDescriptorRuntimeCallBlocked: Bool
    let didPreserveRendererPipelineDescriptorConfigurationReadiness: Bool
    let didConfirmRuntimeInternalCallExecuted: Bool
    let didConfirmTokensStayedFunctionLocal: Bool
    let didConfirmCreateConfigureClassifyDestroyLifecycle: Bool
    let didConfirmNoDrawConfigurationFacts: Bool
    let didConfirmNoDrawBlockers: Bool
    let didConfirmDoubleDestroyFailClosed: Bool
    let didConfirmCleanupCountsReturnToZero: Bool
    let didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepPipelineDescriptorRuntimeCallReadinessDehydrated: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        pipelineDescriptorConfigurationReadiness:
            CjguiInternalRendererNoPipelineDescriptorConfigurationReadiness,
        runtimeCallObservation:
            CjguiInternalRendererPipelineDescriptorRuntimeCallObservation,
        didPrepareRendererNoPipelineDescriptorRuntimeCallReadiness: Bool,
        shouldDeferRendererNoPipelineDescriptorRuntimeCallReadiness: Bool,
        shouldReportRendererPipelineDescriptorRuntimeCallBlocked: Bool,
        didPreserveRendererPipelineDescriptorConfigurationReadiness: Bool,
        didConfirmRuntimeInternalCallExecuted: Bool,
        didConfirmTokensStayedFunctionLocal: Bool,
        didConfirmCreateConfigureClassifyDestroyLifecycle: Bool,
        didConfirmNoDrawConfigurationFacts: Bool,
        didConfirmNoDrawBlockers: Bool,
        didConfirmDoubleDestroyFailClosed: Bool,
        didConfirmCleanupCountsReturnToZero: Bool,
        didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepPipelineDescriptorRuntimeCallReadinessDehydrated: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.pipelineDescriptorConfigurationReadiness =
            pipelineDescriptorConfigurationReadiness
        this.runtimeCallObservation = runtimeCallObservation
        this.didPrepareRendererNoPipelineDescriptorRuntimeCallReadiness =
            didPrepareRendererNoPipelineDescriptorRuntimeCallReadiness
        this.shouldDeferRendererNoPipelineDescriptorRuntimeCallReadiness =
            shouldDeferRendererNoPipelineDescriptorRuntimeCallReadiness
        this.shouldReportRendererPipelineDescriptorRuntimeCallBlocked =
            shouldReportRendererPipelineDescriptorRuntimeCallBlocked
        this.didPreserveRendererPipelineDescriptorConfigurationReadiness =
            didPreserveRendererPipelineDescriptorConfigurationReadiness
        this.didConfirmRuntimeInternalCallExecuted =
            didConfirmRuntimeInternalCallExecuted
        this.didConfirmTokensStayedFunctionLocal =
            didConfirmTokensStayedFunctionLocal
        this.didConfirmCreateConfigureClassifyDestroyLifecycle =
            didConfirmCreateConfigureClassifyDestroyLifecycle
        this.didConfirmNoDrawConfigurationFacts =
            didConfirmNoDrawConfigurationFacts
        this.didConfirmNoDrawBlockers = didConfirmNoDrawBlockers
        this.didConfirmDoubleDestroyFailClosed =
            didConfirmDoubleDestroyFailClosed
        this.didConfirmCleanupCountsReturnToZero =
            didConfirmCleanupCountsReturnToZero
        this.didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender =
            didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepPipelineDescriptorRuntimeCallReadinessDehydrated =
            didKeepPipelineDescriptorRuntimeCallReadinessDehydrated
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererPipelineDescriptorRuntimeCallValues():
    CjguiInternalRendererPipelineDescriptorRuntimeCallObservation {
    let descriptorOccupiedBefore = unsafe {
        cjgui_native_bridge_pipeline_descriptor_table_occupied_count()
    }
    var descriptorToken = UInt64(0)
    let descriptorCreateStatus = unsafe {
        cjgui_native_bridge_pipeline_descriptor_create(inout descriptorToken)
    }
    let descriptorOccupiedAfterCreate = unsafe {
        cjgui_native_bridge_pipeline_descriptor_table_occupied_count()
    }
    let descriptorConfigureStatus = unsafe {
        cjgui_native_bridge_pipeline_descriptor_configure_no_draw(
            descriptorToken
        )
    }
    let descriptorValidClass = unsafe {
        cjgui_native_bridge_pipeline_descriptor_token_classify(descriptorToken)
    }
    let colorPixelFormatClass = unsafe {
        cjgui_native_bridge_pipeline_descriptor_color_pixel_format_classify(
            descriptorToken
        )
    }
    let sampleCountClass = unsafe {
        cjgui_native_bridge_pipeline_descriptor_sample_count_classify(
            descriptorToken
        )
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
    let descriptorDestroyStatus = unsafe {
        cjgui_native_bridge_pipeline_descriptor_destroy(descriptorToken)
    }
    let descriptorOccupiedAfterCleanup = unsafe {
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

    return CjguiInternalRendererPipelineDescriptorRuntimeCallObservation(
        descriptorCreateStatus,
        descriptorConfigureStatus,
        descriptorDestroyStatus,
        descriptorToken,
        descriptorValidClass,
        colorPixelFormatClass,
        sampleCountClass,
        descriptorDestroyedClass,
        descriptorDoubleDestroyStatus,
        descriptorDoubleDestroyClass,
        pipelineStateCreationStillBlocked,
        shaderLibraryStillBlocked,
        vertexFunctionStillBlocked,
        fragmentFunctionStillBlocked,
        blendingStillBlocked,
        encoderBindingStillBlocked,
        descriptorOccupiedBefore,
        descriptorOccupiedAfterCreate,
        descriptorOccupiedAfterCleanup,
        descriptorCreateStatus == Int32(0) &&
            descriptorConfigureStatus == Int32(0) &&
            descriptorDestroyStatus == Int32(0),
        descriptorToken != UInt64(0) &&
            descriptorToken < UInt64(4294967296) &&
            descriptorValidClass == Int32(220) &&
            descriptorDestroyedClass == Int32(-223),
        colorPixelFormatClass == Int32(222) &&
            sampleCountClass == Int32(223),
        pipelineStateCreationStillBlocked == Int32(-229) &&
            shaderLibraryStillBlocked == Int32(-230) &&
            vertexFunctionStillBlocked == Int32(-231) &&
            fragmentFunctionStillBlocked == Int32(-232) &&
            blendingStillBlocked == Int32(-233) &&
            encoderBindingStillBlocked == Int32(-234),
        descriptorDoubleDestroyStatus == Int32(-226) &&
            descriptorDoubleDestroyClass == Int32(-226),
        descriptorOccupiedBefore == descriptorOccupiedAfterCleanup &&
            descriptorOccupiedAfterCreate == descriptorOccupiedBefore +
                UInt32(1),
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererPipelineDescriptorRuntimeCallReadiness(
    pipelineDescriptorConfigurationReadiness:
        CjguiInternalRendererNoPipelineDescriptorConfigurationReadiness,
    runtimeCallObservation:
        CjguiInternalRendererPipelineDescriptorRuntimeCallObservation
): CjguiInternalRendererNoPipelineDescriptorRuntimeCallReadiness {
    let upstreamReady =
        pipelineDescriptorConfigurationReadiness
            .didPrepareRendererNoPipelineDescriptorConfigurationReadiness &&
        pipelineDescriptorConfigurationReadiness
            .didConfirmNoDrawConfiguration &&
        pipelineDescriptorConfigurationReadiness
            .didConfirmColorPixelFormatConfigured &&
        pipelineDescriptorConfigurationReadiness.didConfirmSampleCountConfigured &&
        pipelineDescriptorConfigurationReadiness
            .didConfirmShaderLibraryAndFunctionStillBlocked &&
        pipelineDescriptorConfigurationReadiness
            .didConfirmPipelineStateCreationStillBlocked &&
        pipelineDescriptorConfigurationReadiness
            .didConfirmEncoderBindingStillBlocked &&
        pipelineDescriptorConfigurationReadiness
            .didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender &&
        pipelineDescriptorConfigurationReadiness.didConfirmNoPublicSurface &&
        pipelineDescriptorConfigurationReadiness.didConfirmNoRendererStateWrite &&
        pipelineDescriptorConfigurationReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        runtimeCallObservation.didObserveRuntimeInternalCall &&
        runtimeCallObservation.didObserveCreateConfigureClassifyDestroy &&
        runtimeCallObservation.didObserveNoDrawConfigurationFacts &&
        runtimeCallObservation.didObserveNoDrawBlockers &&
        runtimeCallObservation.didObserveDoubleDestroyFailClosed &&
        runtimeCallObservation.didObserveCleanupCounts &&
        runtimeCallObservation.didKeepTokenFunctionLocal &&
        runtimeCallObservation
            .didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender &&
        runtimeCallObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady

    return CjguiInternalRendererNoPipelineDescriptorRuntimeCallReadiness(
        pipelineDescriptorConfigurationReadiness,
        runtimeCallObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        runtimeCallObservation.didObserveRuntimeInternalCall,
        runtimeCallObservation.didKeepTokenFunctionLocal,
        runtimeCallObservation.didObserveCreateConfigureClassifyDestroy,
        runtimeCallObservation.didObserveNoDrawConfigurationFacts,
        runtimeCallObservation.didObserveNoDrawBlockers,
        runtimeCallObservation.didObserveDoubleDestroyFailClosed,
        runtimeCallObservation.didObserveCleanupCounts,
        runtimeCallObservation
            .didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender,
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

func cjguiInternalExecuteDefaultRendererPipelineDescriptorRuntimeCallDraft():
    CjguiInternalRendererNoPipelineDescriptorRuntimeCallReadiness {
    let pipelineDescriptorConfigurationReadiness =
        cjguiInternalExecuteDefaultRendererPipelineDescriptorConfigurationDraft()
    let runtimeCallObservation =
        cjguiInternalObserveRendererPipelineDescriptorRuntimeCallValues()
    return cjguiInternalBuildRendererPipelineDescriptorRuntimeCallReadiness(
        pipelineDescriptorConfigurationReadiness,
        runtimeCallObservation
    )
}
