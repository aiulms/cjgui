// 维护注释：本文件是 token-backed MTLRenderPassDescriptor create/destroy first-slice owner。
// Truth: 只消费 CjguiInternalRendererNoCommandBufferRuntimeCallReadiness，
// 调用 descriptor create / classify / destroy C ABI，并把 token 生命周期脱水为 facts。
// Stop-line: 不配置 color attachment，不创建 encoder，不 draw，不 commit，不 present，
// 不提交 GPU work，不执行 render，不返回 token 到 public surface，不写 runtime_state.cj。
// Same-shape Boundary Brake: descriptor token facts 不得包装成 render-ready、
// GPU submission、backend-ready、state write、receipt、record 或 publication。
package cjgui

foreign func cjgui_native_bridge_render_pass_descriptor_table_capacity(): UInt32
foreign func cjgui_native_bridge_render_pass_descriptor_table_enabled(): UInt32
foreign func cjgui_native_bridge_render_pass_descriptor_table_occupied_count():
    UInt32
foreign func cjgui_native_bridge_render_pass_descriptor_create(
    outDescriptorToken: CPointer<UInt64>
): Int32
foreign func cjgui_native_bridge_render_pass_descriptor_destroy(
    descriptorToken: UInt64
): Int32
foreign func cjgui_native_bridge_render_pass_descriptor_token_classify(
    descriptorToken: UInt64
): Int32
foreign func cjgui_native_bridge_render_pass_descriptor_double_destroy_classify(
    descriptorToken: UInt64
): Int32
foreign func cjgui_native_bridge_render_pass_descriptor_create_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_render_pass_descriptor_destroy_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_render_pass_descriptor_color_attachment_still_blocked():
    Int32
foreign func cjgui_native_bridge_render_pass_descriptor_encoder_creation_still_blocked():
    Int32
foreign func cjgui_native_bridge_render_pass_descriptor_drawable_texture_still_blocked():
    Int32

struct CjguiInternalRendererRenderPassDescriptorCreateDestroyObservation {
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
    let colorAttachmentStillBlockedValue: Int32
    let encoderCreationStillBlockedValue: Int32
    let drawableTextureStillBlockedValue: Int32
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
    let didObserveAttachmentEncoderDrawableStillBlocked: Bool
    let didConfirmNoEncoderDrawCommitPresentGpuOrRender: Bool
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
        colorAttachmentStillBlockedValue: Int32,
        encoderCreationStillBlockedValue: Int32,
        drawableTextureStillBlockedValue: Int32,
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
        didObserveAttachmentEncoderDrawableStillBlocked: Bool,
        didConfirmNoEncoderDrawCommitPresentGpuOrRender: Bool,
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
        this.colorAttachmentStillBlockedValue = colorAttachmentStillBlockedValue
        this.encoderCreationStillBlockedValue = encoderCreationStillBlockedValue
        this.drawableTextureStillBlockedValue = drawableTextureStillBlockedValue
        this.descriptorTableCapacityValue = descriptorTableCapacityValue
        this.descriptorTableEnabledValue = descriptorTableEnabledValue
        this.descriptorOccupiedBeforeValue = descriptorOccupiedBeforeValue
        this.descriptorOccupiedAfterCreateValue =
            descriptorOccupiedAfterCreateValue
        this.descriptorOccupiedAfterDestroyValue =
            descriptorOccupiedAfterDestroyValue
        this.didObserveDescriptorCreateToken =
            didObserveDescriptorCreateToken
        this.didObserveOpaqueDescriptorToken =
            didObserveOpaqueDescriptorToken
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
        this.didObserveAttachmentEncoderDrawableStillBlocked =
            didObserveAttachmentEncoderDrawableStillBlocked
        this.didConfirmNoEncoderDrawCommitPresentGpuOrRender =
            didConfirmNoEncoderDrawCommitPresentGpuOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoRenderPassDescriptorCreateDestroyReadiness {
    let commandBufferRuntimeCallReadiness:
        CjguiInternalRendererNoCommandBufferRuntimeCallReadiness
    let createDestroyObservation:
        CjguiInternalRendererRenderPassDescriptorCreateDestroyObservation
    let didPrepareRendererNoRenderPassDescriptorCreateDestroyReadiness: Bool
    let shouldDeferRendererNoRenderPassDescriptorCreateDestroyReadiness: Bool
    let shouldReportRendererRenderPassDescriptorCreateDestroyBlocked: Bool
    let didPreserveRendererCommandBufferRuntimeCallReadiness: Bool
    let didConfirmTokenBackedRenderPassDescriptorCreateDestroy: Bool
    let didConfirmMainThreadDescriptorGate: Bool
    let didConfirmDescriptorDoubleDestroyFailClosed: Bool
    let didConfirmCleanupCountsReturnToZero: Bool
    let didConfirmColorAttachmentStillBlocked: Bool
    let didConfirmDrawableTextureStillBlocked: Bool
    let didConfirmEncoderCreationStillBlocked: Bool
    let didConfirmNoEncoderDrawCommitPresentGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepRenderPassDescriptorCreateDestroyReadinessDehydrated: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        commandBufferRuntimeCallReadiness:
            CjguiInternalRendererNoCommandBufferRuntimeCallReadiness,
        createDestroyObservation:
            CjguiInternalRendererRenderPassDescriptorCreateDestroyObservation,
        didPrepareRendererNoRenderPassDescriptorCreateDestroyReadiness: Bool,
        shouldDeferRendererNoRenderPassDescriptorCreateDestroyReadiness: Bool,
        shouldReportRendererRenderPassDescriptorCreateDestroyBlocked: Bool,
        didPreserveRendererCommandBufferRuntimeCallReadiness: Bool,
        didConfirmTokenBackedRenderPassDescriptorCreateDestroy: Bool,
        didConfirmMainThreadDescriptorGate: Bool,
        didConfirmDescriptorDoubleDestroyFailClosed: Bool,
        didConfirmCleanupCountsReturnToZero: Bool,
        didConfirmColorAttachmentStillBlocked: Bool,
        didConfirmDrawableTextureStillBlocked: Bool,
        didConfirmEncoderCreationStillBlocked: Bool,
        didConfirmNoEncoderDrawCommitPresentGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepRenderPassDescriptorCreateDestroyReadinessDehydrated: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.commandBufferRuntimeCallReadiness =
            commandBufferRuntimeCallReadiness
        this.createDestroyObservation = createDestroyObservation
        this.didPrepareRendererNoRenderPassDescriptorCreateDestroyReadiness =
            didPrepareRendererNoRenderPassDescriptorCreateDestroyReadiness
        this.shouldDeferRendererNoRenderPassDescriptorCreateDestroyReadiness =
            shouldDeferRendererNoRenderPassDescriptorCreateDestroyReadiness
        this.shouldReportRendererRenderPassDescriptorCreateDestroyBlocked =
            shouldReportRendererRenderPassDescriptorCreateDestroyBlocked
        this.didPreserveRendererCommandBufferRuntimeCallReadiness =
            didPreserveRendererCommandBufferRuntimeCallReadiness
        this.didConfirmTokenBackedRenderPassDescriptorCreateDestroy =
            didConfirmTokenBackedRenderPassDescriptorCreateDestroy
        this.didConfirmMainThreadDescriptorGate =
            didConfirmMainThreadDescriptorGate
        this.didConfirmDescriptorDoubleDestroyFailClosed =
            didConfirmDescriptorDoubleDestroyFailClosed
        this.didConfirmCleanupCountsReturnToZero =
            didConfirmCleanupCountsReturnToZero
        this.didConfirmColorAttachmentStillBlocked =
            didConfirmColorAttachmentStillBlocked
        this.didConfirmDrawableTextureStillBlocked =
            didConfirmDrawableTextureStillBlocked
        this.didConfirmEncoderCreationStillBlocked =
            didConfirmEncoderCreationStillBlocked
        this.didConfirmNoEncoderDrawCommitPresentGpuOrRender =
            didConfirmNoEncoderDrawCommitPresentGpuOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepRenderPassDescriptorCreateDestroyReadinessDehydrated =
            didKeepRenderPassDescriptorCreateDestroyReadinessDehydrated
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererRenderPassDescriptorCreateDestroyValues():
    CjguiInternalRendererRenderPassDescriptorCreateDestroyObservation {
    let descriptorOccupiedBefore = unsafe {
        cjgui_native_bridge_render_pass_descriptor_table_occupied_count()
    }
    let descriptorCapacity = unsafe {
        cjgui_native_bridge_render_pass_descriptor_table_capacity()
    }
    let descriptorEnabled = unsafe {
        cjgui_native_bridge_render_pass_descriptor_table_enabled()
    }
    var descriptorToken = UInt64(0)
    let descriptorCreateStatus = unsafe {
        cjgui_native_bridge_render_pass_descriptor_create(inout descriptorToken)
    }
    let descriptorOccupiedAfterCreate = unsafe {
        cjgui_native_bridge_render_pass_descriptor_table_occupied_count()
    }
    let descriptorValidClass = unsafe {
        cjgui_native_bridge_render_pass_descriptor_token_classify(
            descriptorToken
        )
    }
    let descriptorCreateRequiresMainThread = unsafe {
        cjgui_native_bridge_render_pass_descriptor_create_requires_main_thread()
    }
    let descriptorDestroyRequiresMainThread = unsafe {
        cjgui_native_bridge_render_pass_descriptor_destroy_requires_main_thread()
    }
    let colorAttachmentStillBlocked = unsafe {
        cjgui_native_bridge_render_pass_descriptor_color_attachment_still_blocked()
    }
    let encoderCreationStillBlocked = unsafe {
        cjgui_native_bridge_render_pass_descriptor_encoder_creation_still_blocked()
    }
    let drawableTextureStillBlocked = unsafe {
        cjgui_native_bridge_render_pass_descriptor_drawable_texture_still_blocked()
    }
    let invalidDescriptorDestroyStatus = unsafe {
        cjgui_native_bridge_render_pass_descriptor_destroy(UInt64(0))
    }
    let descriptorDestroyStatus = unsafe {
        cjgui_native_bridge_render_pass_descriptor_destroy(descriptorToken)
    }
    let descriptorOccupiedAfterDestroy = unsafe {
        cjgui_native_bridge_render_pass_descriptor_table_occupied_count()
    }
    let descriptorDestroyedClass = unsafe {
        cjgui_native_bridge_render_pass_descriptor_token_classify(
            descriptorToken
        )
    }
    let descriptorDoubleDestroyStatus = unsafe {
        cjgui_native_bridge_render_pass_descriptor_destroy(descriptorToken)
    }
    let descriptorDoubleDestroyClass = unsafe {
        cjgui_native_bridge_render_pass_descriptor_double_destroy_classify(
            descriptorToken
        )
    }

    return CjguiInternalRendererRenderPassDescriptorCreateDestroyObservation(
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
        colorAttachmentStillBlocked,
        encoderCreationStillBlocked,
        drawableTextureStillBlocked,
        descriptorCapacity,
        descriptorEnabled,
        descriptorOccupiedBefore,
        descriptorOccupiedAfterCreate,
        descriptorOccupiedAfterDestroy,
        descriptorCreateStatus == Int32(0) &&
            descriptorToken != UInt64(0),
        descriptorToken != UInt64(0) && descriptorToken < UInt64(4294967296),
        descriptorValidClass == Int32(200),
        descriptorOccupiedAfterCreate == descriptorOccupiedBefore + UInt32(1) &&
            descriptorOccupiedAfterDestroy == descriptorOccupiedBefore,
        descriptorDestroyStatus == Int32(0),
        descriptorDestroyedClass == Int32(-203),
        descriptorDoubleDestroyStatus == Int32(-206) &&
            descriptorDoubleDestroyClass == Int32(-206),
        invalidDescriptorDestroyStatus == Int32(-202),
        descriptorCreateRequiresMainThread == Int32(-200) &&
            descriptorDestroyRequiresMainThread == Int32(-201),
        colorAttachmentStillBlocked == Int32(-209) &&
            encoderCreationStillBlocked == Int32(-210) &&
            drawableTextureStillBlocked == Int32(-211),
        true,
        true
    )
}

func cjguiInternalBuildRendererRenderPassDescriptorCreateDestroyReadiness(
    commandBufferRuntimeCallReadiness:
        CjguiInternalRendererNoCommandBufferRuntimeCallReadiness,
    createDestroyObservation:
        CjguiInternalRendererRenderPassDescriptorCreateDestroyObservation
): CjguiInternalRendererNoRenderPassDescriptorCreateDestroyReadiness {
    let upstreamReady =
        commandBufferRuntimeCallReadiness
            .didPrepareRendererNoCommandBufferRuntimeCallReadiness &&
        commandBufferRuntimeCallReadiness
            .didConfirmCommandBufferCreateClassifyDestroyLifecycle &&
        commandBufferRuntimeCallReadiness.didConfirmCommitStillBlocked &&
        commandBufferRuntimeCallReadiness
            .didConfirmEncoderCreationStillBlocked &&
        commandBufferRuntimeCallReadiness
            .didConfirmNoPresentGpuSubmissionOrRender &&
        commandBufferRuntimeCallReadiness.didConfirmNoPublicSurface &&
        commandBufferRuntimeCallReadiness.didConfirmNoRendererStateWrite &&
        commandBufferRuntimeCallReadiness.didConfirmNoBackendReadyTruth
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
        createDestroyObservation
            .didObserveAttachmentEncoderDrawableStillBlocked &&
        createDestroyObservation
            .didConfirmNoEncoderDrawCommitPresentGpuOrRender &&
        createDestroyObservation.didConfirmNoPointerHandleClassIdReturn
    let cleanupReady =
        createDestroyObservation.descriptorOccupiedAfterDestroyValue ==
            createDestroyObservation.descriptorOccupiedBeforeValue
    let readinessReady = upstreamReady && observationReady && cleanupReady

    return CjguiInternalRendererNoRenderPassDescriptorCreateDestroyReadiness(
        commandBufferRuntimeCallReadiness,
        createDestroyObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        createDestroyObservation.didObserveDescriptorCreateToken,
        createDestroyObservation.didObserveMainThreadDescriptorGate,
        createDestroyObservation.didObserveDescriptorDoubleDestroyFailClosed,
        cleanupReady,
        createDestroyObservation.colorAttachmentStillBlockedValue ==
            Int32(-209),
        createDestroyObservation.drawableTextureStillBlockedValue ==
            Int32(-211),
        createDestroyObservation.encoderCreationStillBlockedValue ==
            Int32(-210),
        createDestroyObservation.didConfirmNoEncoderDrawCommitPresentGpuOrRender,
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

func cjguiInternalExecuteDefaultRendererRenderPassDescriptorCreateDestroyDraft():
    CjguiInternalRendererNoRenderPassDescriptorCreateDestroyReadiness {
    let commandBufferRuntimeCallReadiness =
        cjguiInternalExecuteDefaultRendererCommandBufferRuntimeCallDraft()
    let createDestroyObservation =
        cjguiInternalObserveRendererRenderPassDescriptorCreateDestroyValues()
    return cjguiInternalBuildRendererRenderPassDescriptorCreateDestroyReadiness(
        commandBufferRuntimeCallReadiness,
        createDestroyObservation
    )
}
