// 维护注释：本文件是 token-backed MTLCommandBuffer create/destroy first-slice owner。
// Truth: 只消费 CjguiInternalRendererNoCommandQueueRuntimeCallReadiness，
// 调用 command buffer create / classify / destroy C ABI，并把 token 生命周期脱水为 facts。
// Stop-line: 不 commit，不 present，不创建 encoder / render pass，不提交 GPU work，
// 不执行 render，不返回 token 到 public surface，不写 runtime_state.cj。
// Same-shape Boundary Brake: command buffer token facts 不得包装成 backend-ready、
// GPU submission、render-ready、state write、receipt、record 或 publication。
package cjgui

foreign func cjgui_native_bridge_command_buffer_table_capacity(): UInt32
foreign func cjgui_native_bridge_command_buffer_table_enabled(): UInt32
foreign func cjgui_native_bridge_command_buffer_table_occupied_count(): UInt32
foreign func cjgui_native_bridge_command_buffer_create(
    queueToken: UInt64,
    outBufferToken: CPointer<UInt64>
): Int32
foreign func cjgui_native_bridge_command_buffer_destroy(
    bufferToken: UInt64
): Int32
foreign func cjgui_native_bridge_command_buffer_token_classify(
    bufferToken: UInt64
): Int32
foreign func cjgui_native_bridge_command_buffer_double_destroy_classify(
    bufferToken: UInt64
): Int32
foreign func cjgui_native_bridge_command_buffer_create_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_command_buffer_destroy_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_command_buffer_commit_still_blocked(): Int32
foreign func cjgui_native_bridge_command_buffer_encoder_creation_still_blocked():
    Int32

struct CjguiInternalRendererCommandBufferCreateDestroyObservation {
    let deviceCreateStatusValue: Int32
    let queueCreateStatusValue: Int32
    let bufferCreateStatusValue: Int32
    let queueDestroyBlockedStatusValue: Int32
    let bufferDestroyStatusValue: Int32
    let queueDestroyStatusValue: Int32
    let deviceDestroyStatusValue: Int32
    let bufferTokenValue: UInt64
    let bufferValidClassValue: Int32
    let bufferDestroyedClassValue: Int32
    let bufferDoubleDestroyStatusValue: Int32
    let bufferDoubleDestroyClassValue: Int32
    let invalidBufferDestroyStatusValue: Int32
    let bufferCreateRequiresMainThreadValue: Int32
    let bufferDestroyRequiresMainThreadValue: Int32
    let commitStillBlockedValue: Int32
    let encoderCreationStillBlockedValue: Int32
    let bufferTableCapacityValue: UInt32
    let bufferTableEnabledValue: UInt32
    let bufferOccupiedBeforeValue: UInt32
    let bufferOccupiedAfterCreateValue: UInt32
    let bufferOccupiedAfterDestroyValue: UInt32
    let queueOccupiedBeforeValue: UInt32
    let queueOccupiedAfterCleanupValue: UInt32
    let deviceOccupiedBeforeValue: UInt32
    let deviceOccupiedAfterCleanupValue: UInt32
    let didObserveCommandBufferCreateToken: Bool
    let didObserveOpaqueCommandBufferToken: Bool
    let didObserveCommandBufferValidClassification: Bool
    let didObserveCommandBufferOccupiedLifecycle: Bool
    let didObserveQueueDestroyBlockedUntilBufferDestroy: Bool
    let didObserveCommandBufferDestroy: Bool
    let didObserveCommandBufferDestroyedStale: Bool
    let didObserveCommandBufferDoubleDestroyFailClosed: Bool
    let didObserveInvalidCommandBufferDestroyFailClosed: Bool
    let didObserveMainThreadCommandBufferGate: Bool
    let didObserveCommitAndEncoderStillBlocked: Bool
    let didConfirmNoPresentGpuSubmissionOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        deviceCreateStatusValue: Int32,
        queueCreateStatusValue: Int32,
        bufferCreateStatusValue: Int32,
        queueDestroyBlockedStatusValue: Int32,
        bufferDestroyStatusValue: Int32,
        queueDestroyStatusValue: Int32,
        deviceDestroyStatusValue: Int32,
        bufferTokenValue: UInt64,
        bufferValidClassValue: Int32,
        bufferDestroyedClassValue: Int32,
        bufferDoubleDestroyStatusValue: Int32,
        bufferDoubleDestroyClassValue: Int32,
        invalidBufferDestroyStatusValue: Int32,
        bufferCreateRequiresMainThreadValue: Int32,
        bufferDestroyRequiresMainThreadValue: Int32,
        commitStillBlockedValue: Int32,
        encoderCreationStillBlockedValue: Int32,
        bufferTableCapacityValue: UInt32,
        bufferTableEnabledValue: UInt32,
        bufferOccupiedBeforeValue: UInt32,
        bufferOccupiedAfterCreateValue: UInt32,
        bufferOccupiedAfterDestroyValue: UInt32,
        queueOccupiedBeforeValue: UInt32,
        queueOccupiedAfterCleanupValue: UInt32,
        deviceOccupiedBeforeValue: UInt32,
        deviceOccupiedAfterCleanupValue: UInt32,
        didObserveCommandBufferCreateToken: Bool,
        didObserveOpaqueCommandBufferToken: Bool,
        didObserveCommandBufferValidClassification: Bool,
        didObserveCommandBufferOccupiedLifecycle: Bool,
        didObserveQueueDestroyBlockedUntilBufferDestroy: Bool,
        didObserveCommandBufferDestroy: Bool,
        didObserveCommandBufferDestroyedStale: Bool,
        didObserveCommandBufferDoubleDestroyFailClosed: Bool,
        didObserveInvalidCommandBufferDestroyFailClosed: Bool,
        didObserveMainThreadCommandBufferGate: Bool,
        didObserveCommitAndEncoderStillBlocked: Bool,
        didConfirmNoPresentGpuSubmissionOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.deviceCreateStatusValue = deviceCreateStatusValue
        this.queueCreateStatusValue = queueCreateStatusValue
        this.bufferCreateStatusValue = bufferCreateStatusValue
        this.queueDestroyBlockedStatusValue = queueDestroyBlockedStatusValue
        this.bufferDestroyStatusValue = bufferDestroyStatusValue
        this.queueDestroyStatusValue = queueDestroyStatusValue
        this.deviceDestroyStatusValue = deviceDestroyStatusValue
        this.bufferTokenValue = bufferTokenValue
        this.bufferValidClassValue = bufferValidClassValue
        this.bufferDestroyedClassValue = bufferDestroyedClassValue
        this.bufferDoubleDestroyStatusValue = bufferDoubleDestroyStatusValue
        this.bufferDoubleDestroyClassValue = bufferDoubleDestroyClassValue
        this.invalidBufferDestroyStatusValue = invalidBufferDestroyStatusValue
        this.bufferCreateRequiresMainThreadValue =
            bufferCreateRequiresMainThreadValue
        this.bufferDestroyRequiresMainThreadValue =
            bufferDestroyRequiresMainThreadValue
        this.commitStillBlockedValue = commitStillBlockedValue
        this.encoderCreationStillBlockedValue =
            encoderCreationStillBlockedValue
        this.bufferTableCapacityValue = bufferTableCapacityValue
        this.bufferTableEnabledValue = bufferTableEnabledValue
        this.bufferOccupiedBeforeValue = bufferOccupiedBeforeValue
        this.bufferOccupiedAfterCreateValue = bufferOccupiedAfterCreateValue
        this.bufferOccupiedAfterDestroyValue = bufferOccupiedAfterDestroyValue
        this.queueOccupiedBeforeValue = queueOccupiedBeforeValue
        this.queueOccupiedAfterCleanupValue = queueOccupiedAfterCleanupValue
        this.deviceOccupiedBeforeValue = deviceOccupiedBeforeValue
        this.deviceOccupiedAfterCleanupValue = deviceOccupiedAfterCleanupValue
        this.didObserveCommandBufferCreateToken =
            didObserveCommandBufferCreateToken
        this.didObserveOpaqueCommandBufferToken =
            didObserveOpaqueCommandBufferToken
        this.didObserveCommandBufferValidClassification =
            didObserveCommandBufferValidClassification
        this.didObserveCommandBufferOccupiedLifecycle =
            didObserveCommandBufferOccupiedLifecycle
        this.didObserveQueueDestroyBlockedUntilBufferDestroy =
            didObserveQueueDestroyBlockedUntilBufferDestroy
        this.didObserveCommandBufferDestroy = didObserveCommandBufferDestroy
        this.didObserveCommandBufferDestroyedStale =
            didObserveCommandBufferDestroyedStale
        this.didObserveCommandBufferDoubleDestroyFailClosed =
            didObserveCommandBufferDoubleDestroyFailClosed
        this.didObserveInvalidCommandBufferDestroyFailClosed =
            didObserveInvalidCommandBufferDestroyFailClosed
        this.didObserveMainThreadCommandBufferGate =
            didObserveMainThreadCommandBufferGate
        this.didObserveCommitAndEncoderStillBlocked =
            didObserveCommitAndEncoderStillBlocked
        this.didConfirmNoPresentGpuSubmissionOrRender =
            didConfirmNoPresentGpuSubmissionOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoCommandBufferCreateDestroyReadiness {
    let commandQueueRuntimeCallReadiness:
        CjguiInternalRendererNoCommandQueueRuntimeCallReadiness
    let createDestroyObservation:
        CjguiInternalRendererCommandBufferCreateDestroyObservation
    let didPrepareRendererNoCommandBufferCreateDestroyReadiness: Bool
    let shouldDeferRendererNoCommandBufferCreateDestroyReadiness: Bool
    let shouldReportRendererCommandBufferCreateDestroyBlocked: Bool
    let didPreserveRendererCommandQueueRuntimeCallReadiness: Bool
    let didConfirmTokenBackedCommandBufferCreateDestroy: Bool
    let didConfirmMainThreadCommandBufferGate: Bool
    let didConfirmQueueDestroyRequiresBufferDestroyFirst: Bool
    let didConfirmCommandBufferDoubleDestroyFailClosed: Bool
    let didConfirmCleanupCountsReturnToZero: Bool
    let didConfirmCommitStillBlocked: Bool
    let didConfirmEncoderCreationStillBlocked: Bool
    let didConfirmNoPresentGpuSubmissionOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepCommandBufferCreateDestroyReadinessDehydrated: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        commandQueueRuntimeCallReadiness:
            CjguiInternalRendererNoCommandQueueRuntimeCallReadiness,
        createDestroyObservation:
            CjguiInternalRendererCommandBufferCreateDestroyObservation,
        didPrepareRendererNoCommandBufferCreateDestroyReadiness: Bool,
        shouldDeferRendererNoCommandBufferCreateDestroyReadiness: Bool,
        shouldReportRendererCommandBufferCreateDestroyBlocked: Bool,
        didPreserveRendererCommandQueueRuntimeCallReadiness: Bool,
        didConfirmTokenBackedCommandBufferCreateDestroy: Bool,
        didConfirmMainThreadCommandBufferGate: Bool,
        didConfirmQueueDestroyRequiresBufferDestroyFirst: Bool,
        didConfirmCommandBufferDoubleDestroyFailClosed: Bool,
        didConfirmCleanupCountsReturnToZero: Bool,
        didConfirmCommitStillBlocked: Bool,
        didConfirmEncoderCreationStillBlocked: Bool,
        didConfirmNoPresentGpuSubmissionOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepCommandBufferCreateDestroyReadinessDehydrated: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.commandQueueRuntimeCallReadiness =
            commandQueueRuntimeCallReadiness
        this.createDestroyObservation = createDestroyObservation
        this.didPrepareRendererNoCommandBufferCreateDestroyReadiness =
            didPrepareRendererNoCommandBufferCreateDestroyReadiness
        this.shouldDeferRendererNoCommandBufferCreateDestroyReadiness =
            shouldDeferRendererNoCommandBufferCreateDestroyReadiness
        this.shouldReportRendererCommandBufferCreateDestroyBlocked =
            shouldReportRendererCommandBufferCreateDestroyBlocked
        this.didPreserveRendererCommandQueueRuntimeCallReadiness =
            didPreserveRendererCommandQueueRuntimeCallReadiness
        this.didConfirmTokenBackedCommandBufferCreateDestroy =
            didConfirmTokenBackedCommandBufferCreateDestroy
        this.didConfirmMainThreadCommandBufferGate =
            didConfirmMainThreadCommandBufferGate
        this.didConfirmQueueDestroyRequiresBufferDestroyFirst =
            didConfirmQueueDestroyRequiresBufferDestroyFirst
        this.didConfirmCommandBufferDoubleDestroyFailClosed =
            didConfirmCommandBufferDoubleDestroyFailClosed
        this.didConfirmCleanupCountsReturnToZero =
            didConfirmCleanupCountsReturnToZero
        this.didConfirmCommitStillBlocked = didConfirmCommitStillBlocked
        this.didConfirmEncoderCreationStillBlocked =
            didConfirmEncoderCreationStillBlocked
        this.didConfirmNoPresentGpuSubmissionOrRender =
            didConfirmNoPresentGpuSubmissionOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepCommandBufferCreateDestroyReadinessDehydrated =
            didKeepCommandBufferCreateDestroyReadinessDehydrated
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererCommandBufferCreateDestroyValues():
    CjguiInternalRendererCommandBufferCreateDestroyObservation {
    let deviceOccupiedBefore = unsafe {
        cjgui_native_bridge_metal_device_table_occupied_count()
    }
    let queueOccupiedBefore = unsafe {
        cjgui_native_bridge_command_queue_table_occupied_count()
    }
    let bufferOccupiedBefore = unsafe {
        cjgui_native_bridge_command_buffer_table_occupied_count()
    }
    let bufferCapacity = unsafe {
        cjgui_native_bridge_command_buffer_table_capacity()
    }
    let bufferEnabled = unsafe {
        cjgui_native_bridge_command_buffer_table_enabled()
    }
    var deviceToken = UInt64(0)
    var queueToken = UInt64(0)
    var bufferToken = UInt64(0)
    let deviceCreateStatus = unsafe {
        cjgui_native_bridge_metal_default_device_create(inout deviceToken)
    }
    let queueCreateStatus = unsafe {
        cjgui_native_bridge_command_queue_create(
            deviceToken,
            inout queueToken
        )
    }
    let bufferCreateStatus = unsafe {
        cjgui_native_bridge_command_buffer_create(
            queueToken,
            inout bufferToken
        )
    }
    let bufferOccupiedAfterCreate = unsafe {
        cjgui_native_bridge_command_buffer_table_occupied_count()
    }
    let bufferValidClass = unsafe {
        cjgui_native_bridge_command_buffer_token_classify(bufferToken)
    }
    let queueDestroyBlockedStatus = unsafe {
        cjgui_native_bridge_command_queue_destroy(queueToken)
    }
    let bufferCreateRequiresMainThread = unsafe {
        cjgui_native_bridge_command_buffer_create_requires_main_thread()
    }
    let bufferDestroyRequiresMainThread = unsafe {
        cjgui_native_bridge_command_buffer_destroy_requires_main_thread()
    }
    let commitStillBlocked = unsafe {
        cjgui_native_bridge_command_buffer_commit_still_blocked()
    }
    let encoderCreationStillBlocked = unsafe {
        cjgui_native_bridge_command_buffer_encoder_creation_still_blocked()
    }
    let invalidBufferDestroyStatus = unsafe {
        cjgui_native_bridge_command_buffer_destroy(UInt64(0))
    }
    let bufferDestroyStatus = unsafe {
        cjgui_native_bridge_command_buffer_destroy(bufferToken)
    }
    let bufferOccupiedAfterDestroy = unsafe {
        cjgui_native_bridge_command_buffer_table_occupied_count()
    }
    let bufferDestroyedClass = unsafe {
        cjgui_native_bridge_command_buffer_token_classify(bufferToken)
    }
    let bufferDoubleDestroyStatus = unsafe {
        cjgui_native_bridge_command_buffer_destroy(bufferToken)
    }
    let bufferDoubleDestroyClass = unsafe {
        cjgui_native_bridge_command_buffer_double_destroy_classify(bufferToken)
    }
    let queueDestroyStatus = unsafe {
        cjgui_native_bridge_command_queue_destroy(queueToken)
    }
    let deviceDestroyStatus = unsafe {
        cjgui_native_bridge_metal_device_destroy(deviceToken)
    }
    let queueOccupiedAfterCleanup = unsafe {
        cjgui_native_bridge_command_queue_table_occupied_count()
    }
    let deviceOccupiedAfterCleanup = unsafe {
        cjgui_native_bridge_metal_device_table_occupied_count()
    }

    return CjguiInternalRendererCommandBufferCreateDestroyObservation(
        deviceCreateStatus,
        queueCreateStatus,
        bufferCreateStatus,
        queueDestroyBlockedStatus,
        bufferDestroyStatus,
        queueDestroyStatus,
        deviceDestroyStatus,
        bufferToken,
        bufferValidClass,
        bufferDestroyedClass,
        bufferDoubleDestroyStatus,
        bufferDoubleDestroyClass,
        invalidBufferDestroyStatus,
        bufferCreateRequiresMainThread,
        bufferDestroyRequiresMainThread,
        commitStillBlocked,
        encoderCreationStillBlocked,
        bufferCapacity,
        bufferEnabled,
        bufferOccupiedBefore,
        bufferOccupiedAfterCreate,
        bufferOccupiedAfterDestroy,
        queueOccupiedBefore,
        queueOccupiedAfterCleanup,
        deviceOccupiedBefore,
        deviceOccupiedAfterCleanup,
        deviceCreateStatus == Int32(0) &&
            queueCreateStatus == Int32(0) &&
            bufferCreateStatus == Int32(0) &&
            bufferToken != UInt64(0),
        bufferToken != UInt64(0) && bufferToken < UInt64(4294967296),
        bufferValidClass == Int32(180),
        bufferOccupiedAfterCreate == bufferOccupiedBefore + UInt32(1) &&
            bufferOccupiedAfterDestroy == bufferOccupiedBefore,
        queueDestroyBlockedStatus == Int32(-173),
        bufferDestroyStatus == Int32(0),
        bufferDestroyedClass == Int32(-183),
        bufferDoubleDestroyStatus == Int32(-186) &&
            bufferDoubleDestroyClass == Int32(-186),
        invalidBufferDestroyStatus == Int32(-182),
        bufferCreateRequiresMainThread == Int32(-180) &&
            bufferDestroyRequiresMainThread == Int32(-181),
        commitStillBlocked == Int32(-189) &&
            encoderCreationStillBlocked == Int32(-190),
        true,
        true
    )
}

func cjguiInternalBuildRendererCommandBufferCreateDestroyReadiness(
    commandQueueRuntimeCallReadiness:
        CjguiInternalRendererNoCommandQueueRuntimeCallReadiness,
    createDestroyObservation:
        CjguiInternalRendererCommandBufferCreateDestroyObservation
): CjguiInternalRendererNoCommandBufferCreateDestroyReadiness {
    let upstreamReady =
        commandQueueRuntimeCallReadiness
            .didPrepareRendererNoCommandQueueRuntimeCallReadiness &&
        commandQueueRuntimeCallReadiness
            .didConfirmQueueCreateClassifyDestroyLifecycle &&
        commandQueueRuntimeCallReadiness
            .didConfirmNoPresentGpuSubmissionOrRender &&
        commandQueueRuntimeCallReadiness.didConfirmNoPublicSurface &&
        commandQueueRuntimeCallReadiness.didConfirmNoRendererStateWrite &&
        commandQueueRuntimeCallReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        createDestroyObservation.didObserveCommandBufferCreateToken &&
        createDestroyObservation.didObserveOpaqueCommandBufferToken &&
        createDestroyObservation.didObserveCommandBufferValidClassification &&
        createDestroyObservation.didObserveCommandBufferOccupiedLifecycle &&
        createDestroyObservation
            .didObserveQueueDestroyBlockedUntilBufferDestroy &&
        createDestroyObservation.didObserveCommandBufferDestroy &&
        createDestroyObservation.didObserveCommandBufferDestroyedStale &&
        createDestroyObservation
            .didObserveCommandBufferDoubleDestroyFailClosed &&
        createDestroyObservation
            .didObserveInvalidCommandBufferDestroyFailClosed &&
        createDestroyObservation.didObserveMainThreadCommandBufferGate &&
        createDestroyObservation.didObserveCommitAndEncoderStillBlocked &&
        createDestroyObservation.didConfirmNoPresentGpuSubmissionOrRender &&
        createDestroyObservation.didConfirmNoPointerHandleClassIdReturn
    let cleanupReady =
        createDestroyObservation.bufferOccupiedAfterDestroyValue ==
            createDestroyObservation.bufferOccupiedBeforeValue &&
        createDestroyObservation.queueOccupiedAfterCleanupValue ==
            createDestroyObservation.queueOccupiedBeforeValue &&
        createDestroyObservation.deviceOccupiedAfterCleanupValue ==
            createDestroyObservation.deviceOccupiedBeforeValue
    let readinessReady = upstreamReady && observationReady && cleanupReady

    return CjguiInternalRendererNoCommandBufferCreateDestroyReadiness(
        commandQueueRuntimeCallReadiness,
        createDestroyObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        createDestroyObservation.didObserveCommandBufferCreateToken,
        createDestroyObservation.didObserveMainThreadCommandBufferGate,
        createDestroyObservation
            .didObserveQueueDestroyBlockedUntilBufferDestroy,
        createDestroyObservation
            .didObserveCommandBufferDoubleDestroyFailClosed,
        cleanupReady,
        createDestroyObservation.commitStillBlockedValue == Int32(-189),
        createDestroyObservation.encoderCreationStillBlockedValue ==
            Int32(-190),
        createDestroyObservation.didConfirmNoPresentGpuSubmissionOrRender,
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

func cjguiInternalExecuteDefaultRendererCommandBufferCreateDestroyDraft():
    CjguiInternalRendererNoCommandBufferCreateDestroyReadiness {
    let commandQueueRuntimeCallReadiness =
        cjguiInternalExecuteDefaultRendererCommandQueueRuntimeCallDraft()
    let createDestroyObservation =
        cjguiInternalObserveRendererCommandBufferCreateDestroyValues()
    return cjguiInternalBuildRendererCommandBufferCreateDestroyReadiness(
        commandQueueRuntimeCallReadiness,
        createDestroyObservation
    )
}
