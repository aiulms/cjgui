// 中文维护注释：本文件是 MTLRenderPipelineDescriptor no-draw configuration owner。
// Truth: 只消费 CjguiInternalRendererNoPipelineDescriptorCreateDestroyReadiness，
// 局部执行 descriptor create / configure / classify / destroy，并把 pixel format、
// sample count 与 still-blocked facts 脱水为 internal facts。
// Stop-line: 不创建 pipeline state，不创建 shader library / function，不绑定 encoder，
// 不调用 setRenderPipelineState，不 draw，不创建 vertex buffer，不 commit，不 present，
// 不提交 GPU work，不执行 render，不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: pipeline descriptor configuration facts 不得包装成
// render permission、GPU submission、backend-ready、state write、receipt、record
// 或 publication。
package cjgui

struct CjguiInternalRendererPipelineDescriptorConfigurationObservation {
    let descriptorCreateStatusValue: Int32
    let descriptorConfigureStatusValue: Int32
    let descriptorDestroyStatusValue: Int32
    let descriptorTokenValue: UInt64
    let descriptorConfiguredClassValue: Int32
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
    let descriptorOccupiedAfterDestroyValue: UInt32
    let didObserveNoDrawConfiguration: Bool
    let didObservePixelFormatConfigured: Bool
    let didObserveSampleCountConfigured: Bool
    let didObserveShaderLibraryAndFunctionStillBlocked: Bool
    let didObservePipelineStateAndEncoderStillBlocked: Bool
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
        descriptorConfiguredClassValue: Int32,
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
        descriptorOccupiedAfterDestroyValue: UInt32,
        didObserveNoDrawConfiguration: Bool,
        didObservePixelFormatConfigured: Bool,
        didObserveSampleCountConfigured: Bool,
        didObserveShaderLibraryAndFunctionStillBlocked: Bool,
        didObservePipelineStateAndEncoderStillBlocked: Bool,
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
        this.descriptorConfiguredClassValue = descriptorConfiguredClassValue
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
        this.descriptorOccupiedAfterDestroyValue =
            descriptorOccupiedAfterDestroyValue
        this.didObserveNoDrawConfiguration = didObserveNoDrawConfiguration
        this.didObservePixelFormatConfigured =
            didObservePixelFormatConfigured
        this.didObserveSampleCountConfigured = didObserveSampleCountConfigured
        this.didObserveShaderLibraryAndFunctionStillBlocked =
            didObserveShaderLibraryAndFunctionStillBlocked
        this.didObservePipelineStateAndEncoderStillBlocked =
            didObservePipelineStateAndEncoderStillBlocked
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

struct CjguiInternalRendererNoPipelineDescriptorConfigurationReadiness {
    let pipelineDescriptorCreateDestroyReadiness:
        CjguiInternalRendererNoPipelineDescriptorCreateDestroyReadiness
    let configurationObservation:
        CjguiInternalRendererPipelineDescriptorConfigurationObservation
    let didPrepareRendererNoPipelineDescriptorConfigurationReadiness: Bool
    let shouldDeferRendererNoPipelineDescriptorConfigurationReadiness: Bool
    let shouldReportRendererPipelineDescriptorConfigurationBlocked: Bool
    let didPreserveRendererPipelineDescriptorCreateDestroyReadiness: Bool
    let didConfirmNoDrawConfiguration: Bool
    let didConfirmColorPixelFormatConfigured: Bool
    let didConfirmSampleCountConfigured: Bool
    let didConfirmShaderLibraryAndFunctionStillBlocked: Bool
    let didConfirmBlendingStillBlocked: Bool
    let didConfirmPipelineStateCreationStillBlocked: Bool
    let didConfirmEncoderBindingStillBlocked: Bool
    let didConfirmDoubleDestroyFailClosed: Bool
    let didConfirmCleanupCountsReturnToZero: Bool
    let didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepPipelineDescriptorConfigurationReadinessDehydrated: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        pipelineDescriptorCreateDestroyReadiness:
            CjguiInternalRendererNoPipelineDescriptorCreateDestroyReadiness,
        configurationObservation:
            CjguiInternalRendererPipelineDescriptorConfigurationObservation,
        didPrepareRendererNoPipelineDescriptorConfigurationReadiness: Bool,
        shouldDeferRendererNoPipelineDescriptorConfigurationReadiness: Bool,
        shouldReportRendererPipelineDescriptorConfigurationBlocked: Bool,
        didPreserveRendererPipelineDescriptorCreateDestroyReadiness: Bool,
        didConfirmNoDrawConfiguration: Bool,
        didConfirmColorPixelFormatConfigured: Bool,
        didConfirmSampleCountConfigured: Bool,
        didConfirmShaderLibraryAndFunctionStillBlocked: Bool,
        didConfirmBlendingStillBlocked: Bool,
        didConfirmPipelineStateCreationStillBlocked: Bool,
        didConfirmEncoderBindingStillBlocked: Bool,
        didConfirmDoubleDestroyFailClosed: Bool,
        didConfirmCleanupCountsReturnToZero: Bool,
        didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepPipelineDescriptorConfigurationReadinessDehydrated: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.pipelineDescriptorCreateDestroyReadiness =
            pipelineDescriptorCreateDestroyReadiness
        this.configurationObservation = configurationObservation
        this.didPrepareRendererNoPipelineDescriptorConfigurationReadiness =
            didPrepareRendererNoPipelineDescriptorConfigurationReadiness
        this.shouldDeferRendererNoPipelineDescriptorConfigurationReadiness =
            shouldDeferRendererNoPipelineDescriptorConfigurationReadiness
        this.shouldReportRendererPipelineDescriptorConfigurationBlocked =
            shouldReportRendererPipelineDescriptorConfigurationBlocked
        this.didPreserveRendererPipelineDescriptorCreateDestroyReadiness =
            didPreserveRendererPipelineDescriptorCreateDestroyReadiness
        this.didConfirmNoDrawConfiguration = didConfirmNoDrawConfiguration
        this.didConfirmColorPixelFormatConfigured =
            didConfirmColorPixelFormatConfigured
        this.didConfirmSampleCountConfigured = didConfirmSampleCountConfigured
        this.didConfirmShaderLibraryAndFunctionStillBlocked =
            didConfirmShaderLibraryAndFunctionStillBlocked
        this.didConfirmBlendingStillBlocked = didConfirmBlendingStillBlocked
        this.didConfirmPipelineStateCreationStillBlocked =
            didConfirmPipelineStateCreationStillBlocked
        this.didConfirmEncoderBindingStillBlocked =
            didConfirmEncoderBindingStillBlocked
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
        this.didKeepPipelineDescriptorConfigurationReadinessDehydrated =
            didKeepPipelineDescriptorConfigurationReadinessDehydrated
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererPipelineDescriptorConfigurationValues():
    CjguiInternalRendererPipelineDescriptorConfigurationObservation {
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
    let descriptorConfiguredClass = unsafe {
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

    return CjguiInternalRendererPipelineDescriptorConfigurationObservation(
        descriptorCreateStatus,
        descriptorConfigureStatus,
        descriptorDestroyStatus,
        descriptorToken,
        descriptorConfiguredClass,
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
        descriptorOccupiedAfterDestroy,
        descriptorCreateStatus == Int32(0) &&
            descriptorConfigureStatus == Int32(0) &&
            descriptorConfiguredClass == Int32(220),
        colorPixelFormatClass == Int32(222),
        sampleCountClass == Int32(223),
        shaderLibraryStillBlocked == Int32(-230) &&
            vertexFunctionStillBlocked == Int32(-231) &&
            fragmentFunctionStillBlocked == Int32(-232),
        pipelineStateCreationStillBlocked == Int32(-229) &&
            encoderBindingStillBlocked == Int32(-234),
        descriptorDoubleDestroyStatus == Int32(-226) &&
            descriptorDoubleDestroyClass == Int32(-226),
        descriptorOccupiedBefore == descriptorOccupiedAfterDestroy &&
            descriptorOccupiedAfterCreate == descriptorOccupiedBefore +
                UInt32(1),
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererPipelineDescriptorConfigurationReadiness(
    pipelineDescriptorCreateDestroyReadiness:
        CjguiInternalRendererNoPipelineDescriptorCreateDestroyReadiness,
    configurationObservation:
        CjguiInternalRendererPipelineDescriptorConfigurationObservation
): CjguiInternalRendererNoPipelineDescriptorConfigurationReadiness {
    let upstreamReady =
        pipelineDescriptorCreateDestroyReadiness
            .didPrepareRendererNoPipelineDescriptorCreateDestroyReadiness &&
        pipelineDescriptorCreateDestroyReadiness
            .didConfirmTokenBackedPipelineDescriptorCreateDestroy &&
        pipelineDescriptorCreateDestroyReadiness
            .didConfirmShaderLibraryAndFunctionsStillBlocked &&
        pipelineDescriptorCreateDestroyReadiness
            .didConfirmPipelineStateCreationStillBlocked &&
        pipelineDescriptorCreateDestroyReadiness
            .didConfirmEncoderBindingStillBlocked &&
        pipelineDescriptorCreateDestroyReadiness
            .didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender &&
        pipelineDescriptorCreateDestroyReadiness.didConfirmNoPublicSurface &&
        pipelineDescriptorCreateDestroyReadiness.didConfirmNoRendererStateWrite &&
        pipelineDescriptorCreateDestroyReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        configurationObservation.didObserveNoDrawConfiguration &&
        configurationObservation.didObservePixelFormatConfigured &&
        configurationObservation.didObserveSampleCountConfigured &&
        configurationObservation
            .didObserveShaderLibraryAndFunctionStillBlocked &&
        configurationObservation.didObservePipelineStateAndEncoderStillBlocked &&
        configurationObservation.didObserveDoubleDestroyFailClosed &&
        configurationObservation.didObserveCleanupCounts &&
        configurationObservation.didKeepTokenFunctionLocal &&
        configurationObservation
            .didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender &&
        configurationObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady

    return CjguiInternalRendererNoPipelineDescriptorConfigurationReadiness(
        pipelineDescriptorCreateDestroyReadiness,
        configurationObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        configurationObservation.didObserveNoDrawConfiguration,
        configurationObservation.didObservePixelFormatConfigured,
        configurationObservation.didObserveSampleCountConfigured,
        configurationObservation
            .didObserveShaderLibraryAndFunctionStillBlocked,
        configurationObservation.blendingStillBlockedValue == Int32(-233),
        configurationObservation.pipelineStateCreationStillBlockedValue ==
            Int32(-229),
        configurationObservation.encoderBindingStillBlockedValue == Int32(-234),
        configurationObservation.didObserveDoubleDestroyFailClosed,
        configurationObservation.didObserveCleanupCounts,
        configurationObservation
            .didConfirmNoPipelineStateShaderEncoderDrawCommitPresentGpuOrRender,
        configurationObservation.didConfirmNoPointerHandleClassIdReturn,
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

func cjguiInternalExecuteDefaultRendererPipelineDescriptorConfigurationDraft():
    CjguiInternalRendererNoPipelineDescriptorConfigurationReadiness {
    let pipelineDescriptorCreateDestroyReadiness =
        cjguiInternalExecuteDefaultRendererPipelineDescriptorCreateDestroyDraft()
    let configurationObservation =
        cjguiInternalObserveRendererPipelineDescriptorConfigurationValues()
    return cjguiInternalBuildRendererPipelineDescriptorConfigurationReadiness(
        pipelineDescriptorCreateDestroyReadiness,
        configurationObservation
    )
}
