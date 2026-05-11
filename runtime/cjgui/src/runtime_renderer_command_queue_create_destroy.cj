// 维护注释：本文件是 token-backed MTLCommandQueue create/destroy first-slice owner。
// Truth: 只消费 CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness，
// 调用 command queue create / classify / destroy C ABI，并把 token 生命周期脱水为 facts。
// Stop-line: 不创建 command buffer / encoder，不 commit，不 present，不提交 GPU work，
// 不执行 render，不返回 token 到 public surface，不写 runtime_state.cj。
// Same-shape Boundary Brake: command queue token facts 不得包装成 backend-ready、
// GPU submission、render-ready、state write、receipt、record 或 publication。
package cjgui

foreign func cjgui_native_bridge_command_queue_table_capacity(): UInt32
foreign func cjgui_native_bridge_command_queue_table_enabled(): UInt32
foreign func cjgui_native_bridge_command_queue_table_occupied_count(): UInt32
foreign func cjgui_native_bridge_command_queue_create(
    deviceToken: UInt64,
    outQueueToken: CPointer<UInt64>
): Int32
foreign func cjgui_native_bridge_command_queue_destroy(
    queueToken: UInt64
): Int32
foreign func cjgui_native_bridge_command_queue_token_classify(
    queueToken: UInt64
): Int32
foreign func cjgui_native_bridge_command_queue_double_destroy_classify(
    queueToken: UInt64
): Int32
foreign func cjgui_native_bridge_command_queue_create_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_command_queue_destroy_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_command_buffer_creation_still_blocked():
    Int32

struct CjguiInternalRendererCommandQueueCreateDestroyObservation {
    let deviceCreateStatusValue: Int32
    let queueCreateStatusValue: Int32
    let queueTokenValue: UInt64
    let queueValidClassValue: Int32
    let deviceDestroyBlockedStatusValue: Int32
    let queueDestroyStatusValue: Int32
    let queueDestroyedClassValue: Int32
    let queueDoubleDestroyStatusValue: Int32
    let queueDoubleDestroyClassValue: Int32
    let invalidDestroyStatusValue: Int32
    let deviceDestroyStatusValue: Int32
    let queueCreateRequiresMainThreadValue: Int32
    let queueDestroyRequiresMainThreadValue: Int32
    let commandBufferStillBlockedValue: Int32
    let queueTableCapacityValue: UInt32
    let queueTableEnabledValue: UInt32
    let deviceOccupiedBeforeValue: UInt32
    let deviceOccupiedAfterCleanupValue: UInt32
    let queueOccupiedBeforeValue: UInt32
    let queueOccupiedAfterCreateValue: UInt32
    let queueOccupiedAfterDestroyValue: UInt32
    let didObserveQueueCreateToken: Bool
    let didObserveOpaqueQueueToken: Bool
    let didObserveQueueValidClassification: Bool
    let didObserveQueueOccupiedLifecycle: Bool
    let didObserveDeviceDestroyBlockedUntilQueueDestroy: Bool
    let didObserveQueueDestroy: Bool
    let didObserveQueueDestroyedStale: Bool
    let didObserveQueueDoubleDestroyFailClosed: Bool
    let didObserveInvalidQueueDestroyFailClosed: Bool
    let didObserveMainThreadQueueGate: Bool
    let didObserveCommandBufferStillBlocked: Bool
    let didConfirmNoCommandBufferEncoderSubmitRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        deviceCreateStatusValue: Int32,
        queueCreateStatusValue: Int32,
        queueTokenValue: UInt64,
        queueValidClassValue: Int32,
        deviceDestroyBlockedStatusValue: Int32,
        queueDestroyStatusValue: Int32,
        queueDestroyedClassValue: Int32,
        queueDoubleDestroyStatusValue: Int32,
        queueDoubleDestroyClassValue: Int32,
        invalidDestroyStatusValue: Int32,
        deviceDestroyStatusValue: Int32,
        queueCreateRequiresMainThreadValue: Int32,
        queueDestroyRequiresMainThreadValue: Int32,
        commandBufferStillBlockedValue: Int32,
        queueTableCapacityValue: UInt32,
        queueTableEnabledValue: UInt32,
        deviceOccupiedBeforeValue: UInt32,
        deviceOccupiedAfterCleanupValue: UInt32,
        queueOccupiedBeforeValue: UInt32,
        queueOccupiedAfterCreateValue: UInt32,
        queueOccupiedAfterDestroyValue: UInt32,
        didObserveQueueCreateToken: Bool,
        didObserveOpaqueQueueToken: Bool,
        didObserveQueueValidClassification: Bool,
        didObserveQueueOccupiedLifecycle: Bool,
        didObserveDeviceDestroyBlockedUntilQueueDestroy: Bool,
        didObserveQueueDestroy: Bool,
        didObserveQueueDestroyedStale: Bool,
        didObserveQueueDoubleDestroyFailClosed: Bool,
        didObserveInvalidQueueDestroyFailClosed: Bool,
        didObserveMainThreadQueueGate: Bool,
        didObserveCommandBufferStillBlocked: Bool,
        didConfirmNoCommandBufferEncoderSubmitRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.deviceCreateStatusValue = deviceCreateStatusValue
        this.queueCreateStatusValue = queueCreateStatusValue
        this.queueTokenValue = queueTokenValue
        this.queueValidClassValue = queueValidClassValue
        this.deviceDestroyBlockedStatusValue =
            deviceDestroyBlockedStatusValue
        this.queueDestroyStatusValue = queueDestroyStatusValue
        this.queueDestroyedClassValue = queueDestroyedClassValue
        this.queueDoubleDestroyStatusValue = queueDoubleDestroyStatusValue
        this.queueDoubleDestroyClassValue = queueDoubleDestroyClassValue
        this.invalidDestroyStatusValue = invalidDestroyStatusValue
        this.deviceDestroyStatusValue = deviceDestroyStatusValue
        this.queueCreateRequiresMainThreadValue =
            queueCreateRequiresMainThreadValue
        this.queueDestroyRequiresMainThreadValue =
            queueDestroyRequiresMainThreadValue
        this.commandBufferStillBlockedValue = commandBufferStillBlockedValue
        this.queueTableCapacityValue = queueTableCapacityValue
        this.queueTableEnabledValue = queueTableEnabledValue
        this.deviceOccupiedBeforeValue = deviceOccupiedBeforeValue
        this.deviceOccupiedAfterCleanupValue =
            deviceOccupiedAfterCleanupValue
        this.queueOccupiedBeforeValue = queueOccupiedBeforeValue
        this.queueOccupiedAfterCreateValue = queueOccupiedAfterCreateValue
        this.queueOccupiedAfterDestroyValue = queueOccupiedAfterDestroyValue
        this.didObserveQueueCreateToken = didObserveQueueCreateToken
        this.didObserveOpaqueQueueToken = didObserveOpaqueQueueToken
        this.didObserveQueueValidClassification =
            didObserveQueueValidClassification
        this.didObserveQueueOccupiedLifecycle =
            didObserveQueueOccupiedLifecycle
        this.didObserveDeviceDestroyBlockedUntilQueueDestroy =
            didObserveDeviceDestroyBlockedUntilQueueDestroy
        this.didObserveQueueDestroy = didObserveQueueDestroy
        this.didObserveQueueDestroyedStale = didObserveQueueDestroyedStale
        this.didObserveQueueDoubleDestroyFailClosed =
            didObserveQueueDoubleDestroyFailClosed
        this.didObserveInvalidQueueDestroyFailClosed =
            didObserveInvalidQueueDestroyFailClosed
        this.didObserveMainThreadQueueGate = didObserveMainThreadQueueGate
        this.didObserveCommandBufferStillBlocked =
            didObserveCommandBufferStillBlocked
        this.didConfirmNoCommandBufferEncoderSubmitRender =
            didConfirmNoCommandBufferEncoderSubmitRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoCommandQueueCreateDestroyReadiness {
    let drawableNoPresentReadiness:
        CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness
    let createDestroyObservation:
        CjguiInternalRendererCommandQueueCreateDestroyObservation
    let didPrepareRendererNoCommandQueueCreateDestroyReadiness: Bool
    let shouldDeferRendererNoCommandQueueCreateDestroyReadiness: Bool
    let shouldReportRendererCommandQueueCreateDestroyBlocked: Bool
    let didPreserveRendererDrawableNoPresentAcquisitionReadiness: Bool
    let didConfirmTokenBackedCommandQueueCreateDestroy: Bool
    let didConfirmMainThreadQueueGate: Bool
    let didConfirmDeviceDestroyRequiresQueueDestroyFirst: Bool
    let didConfirmQueueDoubleDestroyFailClosed: Bool
    let didConfirmCleanupCountsReturnToZero: Bool
    let didConfirmCommandBufferStillBlocked: Bool
    let didConfirmNoPresentGpuSubmissionOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepCommandQueueCreateDestroyReadinessDehydrated: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        drawableNoPresentReadiness:
            CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness,
        createDestroyObservation:
            CjguiInternalRendererCommandQueueCreateDestroyObservation,
        didPrepareRendererNoCommandQueueCreateDestroyReadiness: Bool,
        shouldDeferRendererNoCommandQueueCreateDestroyReadiness: Bool,
        shouldReportRendererCommandQueueCreateDestroyBlocked: Bool,
        didPreserveRendererDrawableNoPresentAcquisitionReadiness: Bool,
        didConfirmTokenBackedCommandQueueCreateDestroy: Bool,
        didConfirmMainThreadQueueGate: Bool,
        didConfirmDeviceDestroyRequiresQueueDestroyFirst: Bool,
        didConfirmQueueDoubleDestroyFailClosed: Bool,
        didConfirmCleanupCountsReturnToZero: Bool,
        didConfirmCommandBufferStillBlocked: Bool,
        didConfirmNoPresentGpuSubmissionOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepCommandQueueCreateDestroyReadinessDehydrated: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.drawableNoPresentReadiness = drawableNoPresentReadiness
        this.createDestroyObservation = createDestroyObservation
        this.didPrepareRendererNoCommandQueueCreateDestroyReadiness =
            didPrepareRendererNoCommandQueueCreateDestroyReadiness
        this.shouldDeferRendererNoCommandQueueCreateDestroyReadiness =
            shouldDeferRendererNoCommandQueueCreateDestroyReadiness
        this.shouldReportRendererCommandQueueCreateDestroyBlocked =
            shouldReportRendererCommandQueueCreateDestroyBlocked
        this.didPreserveRendererDrawableNoPresentAcquisitionReadiness =
            didPreserveRendererDrawableNoPresentAcquisitionReadiness
        this.didConfirmTokenBackedCommandQueueCreateDestroy =
            didConfirmTokenBackedCommandQueueCreateDestroy
        this.didConfirmMainThreadQueueGate = didConfirmMainThreadQueueGate
        this.didConfirmDeviceDestroyRequiresQueueDestroyFirst =
            didConfirmDeviceDestroyRequiresQueueDestroyFirst
        this.didConfirmQueueDoubleDestroyFailClosed =
            didConfirmQueueDoubleDestroyFailClosed
        this.didConfirmCleanupCountsReturnToZero =
            didConfirmCleanupCountsReturnToZero
        this.didConfirmCommandBufferStillBlocked =
            didConfirmCommandBufferStillBlocked
        this.didConfirmNoPresentGpuSubmissionOrRender =
            didConfirmNoPresentGpuSubmissionOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepCommandQueueCreateDestroyReadinessDehydrated =
            didKeepCommandQueueCreateDestroyReadinessDehydrated
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererCommandQueueCreateDestroyValues():
    CjguiInternalRendererCommandQueueCreateDestroyObservation {
    let deviceOccupiedBefore = unsafe {
        cjgui_native_bridge_metal_device_table_occupied_count()
    }
    let queueOccupiedBefore = unsafe {
        cjgui_native_bridge_command_queue_table_occupied_count()
    }
    let queueCapacity = unsafe {
        cjgui_native_bridge_command_queue_table_capacity()
    }
    let queueEnabled = unsafe {
        cjgui_native_bridge_command_queue_table_enabled()
    }
    var deviceToken = UInt64(0)
    var queueToken = UInt64(0)
    let deviceCreateStatus = unsafe {
        cjgui_native_bridge_metal_default_device_create(inout deviceToken)
    }
    let queueCreateStatus = unsafe {
        cjgui_native_bridge_command_queue_create(
            deviceToken,
            inout queueToken
        )
    }
    let queueOccupiedAfterCreate = unsafe {
        cjgui_native_bridge_command_queue_table_occupied_count()
    }
    let queueValidClass = unsafe {
        cjgui_native_bridge_command_queue_token_classify(queueToken)
    }
    let deviceDestroyBlockedStatus = unsafe {
        cjgui_native_bridge_metal_device_destroy(deviceToken)
    }
    let queueCreateRequiresMainThread = unsafe {
        cjgui_native_bridge_command_queue_create_requires_main_thread()
    }
    let queueDestroyRequiresMainThread = unsafe {
        cjgui_native_bridge_command_queue_destroy_requires_main_thread()
    }
    let commandBufferStillBlocked = unsafe {
        cjgui_native_bridge_command_buffer_creation_still_blocked()
    }
    let invalidDestroyStatus = unsafe {
        cjgui_native_bridge_command_queue_destroy(UInt64(0))
    }
    let queueDestroyStatus = unsafe {
        cjgui_native_bridge_command_queue_destroy(queueToken)
    }
    let queueOccupiedAfterDestroy = unsafe {
        cjgui_native_bridge_command_queue_table_occupied_count()
    }
    let queueDestroyedClass = unsafe {
        cjgui_native_bridge_command_queue_token_classify(queueToken)
    }
    let queueDoubleDestroyStatus = unsafe {
        cjgui_native_bridge_command_queue_destroy(queueToken)
    }
    let queueDoubleDestroyClass = unsafe {
        cjgui_native_bridge_command_queue_double_destroy_classify(queueToken)
    }
    let deviceDestroyStatus = unsafe {
        cjgui_native_bridge_metal_device_destroy(deviceToken)
    }
    let deviceOccupiedAfterCleanup = unsafe {
        cjgui_native_bridge_metal_device_table_occupied_count()
    }

    return CjguiInternalRendererCommandQueueCreateDestroyObservation(
        deviceCreateStatus,
        queueCreateStatus,
        queueToken,
        queueValidClass,
        deviceDestroyBlockedStatus,
        queueDestroyStatus,
        queueDestroyedClass,
        queueDoubleDestroyStatus,
        queueDoubleDestroyClass,
        invalidDestroyStatus,
        deviceDestroyStatus,
        queueCreateRequiresMainThread,
        queueDestroyRequiresMainThread,
        commandBufferStillBlocked,
        queueCapacity,
        queueEnabled,
        deviceOccupiedBefore,
        deviceOccupiedAfterCleanup,
        queueOccupiedBefore,
        queueOccupiedAfterCreate,
        queueOccupiedAfterDestroy,
        deviceCreateStatus == Int32(0) &&
            queueCreateStatus == Int32(0) &&
            queueToken != UInt64(0),
        queueToken != UInt64(0) && queueToken < UInt64(4294967296),
        queueValidClass == Int32(160),
        queueOccupiedAfterCreate == queueOccupiedBefore + UInt32(1) &&
            queueOccupiedAfterDestroy == queueOccupiedBefore,
        deviceDestroyBlockedStatus == Int32(-130),
        queueDestroyStatus == Int32(0),
        queueDestroyedClass == Int32(-163),
        queueDoubleDestroyStatus == Int32(-166) &&
            queueDoubleDestroyClass == Int32(-166),
        invalidDestroyStatus == Int32(-162),
        queueCreateRequiresMainThread == Int32(-160) &&
            queueDestroyRequiresMainThread == Int32(-161),
        commandBufferStillBlocked == Int32(-169),
        true,
        true
    )
}

func cjguiInternalBuildRendererCommandQueueCreateDestroyReadiness(
    drawableNoPresentReadiness:
        CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness,
    createDestroyObservation:
        CjguiInternalRendererCommandQueueCreateDestroyObservation
): CjguiInternalRendererNoCommandQueueCreateDestroyReadiness {
    let upstreamReady =
        drawableNoPresentReadiness
            .didPrepareRendererNoDrawableNoPresentAcquisitionReadiness &&
        drawableNoPresentReadiness
            .didConfirmIsolatedNextDrawableNoPresentAcquisition &&
        drawableNoPresentReadiness
            .didConfirmNoPresentCommandQueueBufferEncoderOrRender &&
        drawableNoPresentReadiness.didConfirmNoGpuSubmission &&
        drawableNoPresentReadiness.didConfirmNoPublicSurface &&
        drawableNoPresentReadiness.didConfirmNoRendererStateWrite &&
        drawableNoPresentReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        createDestroyObservation.didObserveQueueCreateToken &&
        createDestroyObservation.didObserveOpaqueQueueToken &&
        createDestroyObservation.didObserveQueueValidClassification &&
        createDestroyObservation.didObserveQueueOccupiedLifecycle &&
        createDestroyObservation
            .didObserveDeviceDestroyBlockedUntilQueueDestroy &&
        createDestroyObservation.didObserveQueueDestroy &&
        createDestroyObservation.didObserveQueueDestroyedStale &&
        createDestroyObservation.didObserveQueueDoubleDestroyFailClosed &&
        createDestroyObservation.didObserveInvalidQueueDestroyFailClosed &&
        createDestroyObservation.didObserveMainThreadQueueGate &&
        createDestroyObservation.didObserveCommandBufferStillBlocked &&
        createDestroyObservation.didConfirmNoCommandBufferEncoderSubmitRender &&
        createDestroyObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady

    return CjguiInternalRendererNoCommandQueueCreateDestroyReadiness(
        drawableNoPresentReadiness,
        createDestroyObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        createDestroyObservation.didObserveQueueCreateToken &&
            createDestroyObservation.didObserveQueueDestroy,
        createDestroyObservation.didObserveMainThreadQueueGate,
        createDestroyObservation
            .didObserveDeviceDestroyBlockedUntilQueueDestroy,
        createDestroyObservation.didObserveQueueDoubleDestroyFailClosed,
        createDestroyObservation.queueOccupiedBeforeValue ==
            createDestroyObservation.queueOccupiedAfterDestroyValue &&
            createDestroyObservation.deviceOccupiedBeforeValue ==
            createDestroyObservation.deviceOccupiedAfterCleanupValue,
        createDestroyObservation.didObserveCommandBufferStillBlocked,
        createDestroyObservation.didConfirmNoCommandBufferEncoderSubmitRender,
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

func cjguiInternalExecuteDefaultRendererCommandQueueCreateDestroyDraft():
    CjguiInternalRendererNoCommandQueueCreateDestroyReadiness {
    let drawableNoPresentReadiness =
        cjguiInternalExecuteDefaultRendererDrawableNoPresentAcquisitionDraft()
    let createDestroyObservation =
        cjguiInternalObserveRendererCommandQueueCreateDestroyValues()
    return cjguiInternalBuildRendererCommandQueueCreateDestroyReadiness(
        drawableNoPresentReadiness,
        createDestroyObservation
    )
}
