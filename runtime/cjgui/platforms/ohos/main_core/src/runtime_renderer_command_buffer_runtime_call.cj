// 维护注释：本文件是 MTLCommandBuffer runtime internal FFI call owner。
// Truth: 只消费 CjguiInternalRendererNoCommandBufferCreateDestroyReadiness，
// 局部执行 command buffer create / classify / destroy / double-destroy 调用序列，
// 并把结果脱水为 internal facts。
// Stop-line: token 只在函数局部；不 commit，不 present，不创建 encoder / render pass，
// 不提交 GPU work，不执行 render，不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: command buffer runtime call facts 不得包装成 backend-ready、
// GPU submission、render permission、state write、receipt、record 或 publication。
package cjgui

struct CjguiInternalRendererCommandBufferRuntimeCallObservation {
    let deviceCreateStatusValue: Int32
    let queueCreateStatusValue: Int32
    let bufferCreateStatusValue: Int32
    let bufferClassValue: Int32
    let commitStillBlockedValue: Int32
    let encoderCreationStillBlockedValue: Int32
    let bufferDestroyStatusValue: Int32
    let bufferDestroyedClassValue: Int32
    let bufferDoubleDestroyStatusValue: Int32
    let bufferDoubleDestroyClassValue: Int32
    let queueDestroyStatusValue: Int32
    let deviceDestroyStatusValue: Int32
    let bufferOccupiedBeforeValue: UInt32
    let bufferOccupiedAfterCreateValue: UInt32
    let bufferOccupiedAfterDestroyValue: UInt32
    let queueOccupiedBeforeValue: UInt32
    let queueOccupiedAfterCleanupValue: UInt32
    let deviceOccupiedBeforeValue: UInt32
    let deviceOccupiedAfterCleanupValue: UInt32
    let didObserveRuntimeInternalCall: Bool
    let didObserveCommandBufferCreateClassifyDestroy: Bool
    let didObserveDoubleDestroyFailClosed: Bool
    let didObserveCommitAndEncoderStillBlocked: Bool
    let didObserveCleanupCounts: Bool
    let didKeepTokensFunctionLocal: Bool
    let didConfirmNoPresentGpuSubmissionOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        deviceCreateStatusValue: Int32,
        queueCreateStatusValue: Int32,
        bufferCreateStatusValue: Int32,
        bufferClassValue: Int32,
        commitStillBlockedValue: Int32,
        encoderCreationStillBlockedValue: Int32,
        bufferDestroyStatusValue: Int32,
        bufferDestroyedClassValue: Int32,
        bufferDoubleDestroyStatusValue: Int32,
        bufferDoubleDestroyClassValue: Int32,
        queueDestroyStatusValue: Int32,
        deviceDestroyStatusValue: Int32,
        bufferOccupiedBeforeValue: UInt32,
        bufferOccupiedAfterCreateValue: UInt32,
        bufferOccupiedAfterDestroyValue: UInt32,
        queueOccupiedBeforeValue: UInt32,
        queueOccupiedAfterCleanupValue: UInt32,
        deviceOccupiedBeforeValue: UInt32,
        deviceOccupiedAfterCleanupValue: UInt32,
        didObserveRuntimeInternalCall: Bool,
        didObserveCommandBufferCreateClassifyDestroy: Bool,
        didObserveDoubleDestroyFailClosed: Bool,
        didObserveCommitAndEncoderStillBlocked: Bool,
        didObserveCleanupCounts: Bool,
        didKeepTokensFunctionLocal: Bool,
        didConfirmNoPresentGpuSubmissionOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.deviceCreateStatusValue = deviceCreateStatusValue
        this.queueCreateStatusValue = queueCreateStatusValue
        this.bufferCreateStatusValue = bufferCreateStatusValue
        this.bufferClassValue = bufferClassValue
        this.commitStillBlockedValue = commitStillBlockedValue
        this.encoderCreationStillBlockedValue =
            encoderCreationStillBlockedValue
        this.bufferDestroyStatusValue = bufferDestroyStatusValue
        this.bufferDestroyedClassValue = bufferDestroyedClassValue
        this.bufferDoubleDestroyStatusValue = bufferDoubleDestroyStatusValue
        this.bufferDoubleDestroyClassValue = bufferDoubleDestroyClassValue
        this.queueDestroyStatusValue = queueDestroyStatusValue
        this.deviceDestroyStatusValue = deviceDestroyStatusValue
        this.bufferOccupiedBeforeValue = bufferOccupiedBeforeValue
        this.bufferOccupiedAfterCreateValue = bufferOccupiedAfterCreateValue
        this.bufferOccupiedAfterDestroyValue = bufferOccupiedAfterDestroyValue
        this.queueOccupiedBeforeValue = queueOccupiedBeforeValue
        this.queueOccupiedAfterCleanupValue = queueOccupiedAfterCleanupValue
        this.deviceOccupiedBeforeValue = deviceOccupiedBeforeValue
        this.deviceOccupiedAfterCleanupValue = deviceOccupiedAfterCleanupValue
        this.didObserveRuntimeInternalCall = didObserveRuntimeInternalCall
        this.didObserveCommandBufferCreateClassifyDestroy =
            didObserveCommandBufferCreateClassifyDestroy
        this.didObserveDoubleDestroyFailClosed =
            didObserveDoubleDestroyFailClosed
        this.didObserveCommitAndEncoderStillBlocked =
            didObserveCommitAndEncoderStillBlocked
        this.didObserveCleanupCounts = didObserveCleanupCounts
        this.didKeepTokensFunctionLocal = didKeepTokensFunctionLocal
        this.didConfirmNoPresentGpuSubmissionOrRender =
            didConfirmNoPresentGpuSubmissionOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoCommandBufferRuntimeCallReadiness {
    let commandBufferCreateDestroyReadiness:
        CjguiInternalRendererNoCommandBufferCreateDestroyReadiness
    let runtimeCallObservation:
        CjguiInternalRendererCommandBufferRuntimeCallObservation
    let didPrepareRendererNoCommandBufferRuntimeCallReadiness: Bool
    let shouldDeferRendererNoCommandBufferRuntimeCallReadiness: Bool
    let shouldReportRendererCommandBufferRuntimeCallBlocked: Bool
    let didPreserveRendererCommandBufferCreateDestroyReadiness: Bool
    let didConfirmRuntimeInternalCallExecuted: Bool
    let didConfirmTokensStayedFunctionLocal: Bool
    let didConfirmCommandBufferCreateClassifyDestroyLifecycle: Bool
    let didConfirmDoubleDestroyFailClosed: Bool
    let didConfirmCleanupCountsReturnToZero: Bool
    let didConfirmCommitStillBlocked: Bool
    let didConfirmEncoderCreationStillBlocked: Bool
    let didConfirmNoPresentGpuSubmissionOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepCommandBufferRuntimeCallReadinessDehydrated: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        commandBufferCreateDestroyReadiness:
            CjguiInternalRendererNoCommandBufferCreateDestroyReadiness,
        runtimeCallObservation:
            CjguiInternalRendererCommandBufferRuntimeCallObservation,
        didPrepareRendererNoCommandBufferRuntimeCallReadiness: Bool,
        shouldDeferRendererNoCommandBufferRuntimeCallReadiness: Bool,
        shouldReportRendererCommandBufferRuntimeCallBlocked: Bool,
        didPreserveRendererCommandBufferCreateDestroyReadiness: Bool,
        didConfirmRuntimeInternalCallExecuted: Bool,
        didConfirmTokensStayedFunctionLocal: Bool,
        didConfirmCommandBufferCreateClassifyDestroyLifecycle: Bool,
        didConfirmDoubleDestroyFailClosed: Bool,
        didConfirmCleanupCountsReturnToZero: Bool,
        didConfirmCommitStillBlocked: Bool,
        didConfirmEncoderCreationStillBlocked: Bool,
        didConfirmNoPresentGpuSubmissionOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepCommandBufferRuntimeCallReadinessDehydrated: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.commandBufferCreateDestroyReadiness =
            commandBufferCreateDestroyReadiness
        this.runtimeCallObservation = runtimeCallObservation
        this.didPrepareRendererNoCommandBufferRuntimeCallReadiness =
            didPrepareRendererNoCommandBufferRuntimeCallReadiness
        this.shouldDeferRendererNoCommandBufferRuntimeCallReadiness =
            shouldDeferRendererNoCommandBufferRuntimeCallReadiness
        this.shouldReportRendererCommandBufferRuntimeCallBlocked =
            shouldReportRendererCommandBufferRuntimeCallBlocked
        this.didPreserveRendererCommandBufferCreateDestroyReadiness =
            didPreserveRendererCommandBufferCreateDestroyReadiness
        this.didConfirmRuntimeInternalCallExecuted =
            didConfirmRuntimeInternalCallExecuted
        this.didConfirmTokensStayedFunctionLocal =
            didConfirmTokensStayedFunctionLocal
        this.didConfirmCommandBufferCreateClassifyDestroyLifecycle =
            didConfirmCommandBufferCreateClassifyDestroyLifecycle
        this.didConfirmDoubleDestroyFailClosed =
            didConfirmDoubleDestroyFailClosed
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
        this.didKeepCommandBufferRuntimeCallReadinessDehydrated =
            didKeepCommandBufferRuntimeCallReadinessDehydrated
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererCommandBufferRuntimeCallValues():
    CjguiInternalRendererCommandBufferRuntimeCallObservation {
    let deviceOccupiedBefore = unsafe {
        cjgui_native_bridge_metal_device_table_occupied_count()
    }
    let queueOccupiedBefore = unsafe {
        cjgui_native_bridge_command_queue_table_occupied_count()
    }
    let bufferOccupiedBefore = unsafe {
        cjgui_native_bridge_command_buffer_table_occupied_count()
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
    let bufferClass = unsafe {
        cjgui_native_bridge_command_buffer_token_classify(bufferToken)
    }
    let commitStillBlocked = unsafe {
        cjgui_native_bridge_command_buffer_commit_still_blocked()
    }
    let encoderCreationStillBlocked = unsafe {
        cjgui_native_bridge_command_buffer_encoder_creation_still_blocked()
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

    return CjguiInternalRendererCommandBufferRuntimeCallObservation(
        deviceCreateStatus,
        queueCreateStatus,
        bufferCreateStatus,
        bufferClass,
        commitStillBlocked,
        encoderCreationStillBlocked,
        bufferDestroyStatus,
        bufferDestroyedClass,
        bufferDoubleDestroyStatus,
        bufferDoubleDestroyClass,
        queueDestroyStatus,
        deviceDestroyStatus,
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
            bufferDestroyStatus == Int32(0) &&
            queueDestroyStatus == Int32(0) &&
            deviceDestroyStatus == Int32(0),
        bufferToken != UInt64(0) &&
            bufferToken < UInt64(4294967296) &&
            bufferClass == Int32(180) &&
            bufferDestroyStatus == Int32(0) &&
            bufferDestroyedClass == Int32(-183),
        bufferDoubleDestroyStatus == Int32(-186) &&
            bufferDoubleDestroyClass == Int32(-186),
        commitStillBlocked == Int32(-189) &&
            encoderCreationStillBlocked == Int32(-190),
        bufferOccupiedBefore == bufferOccupiedAfterDestroy &&
            queueOccupiedBefore == queueOccupiedAfterCleanup &&
            deviceOccupiedBefore == deviceOccupiedAfterCleanup,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererCommandBufferRuntimeCallReadiness(
    commandBufferCreateDestroyReadiness:
        CjguiInternalRendererNoCommandBufferCreateDestroyReadiness,
    runtimeCallObservation:
        CjguiInternalRendererCommandBufferRuntimeCallObservation
): CjguiInternalRendererNoCommandBufferRuntimeCallReadiness {
    let upstreamReady =
        commandBufferCreateDestroyReadiness
            .didPrepareRendererNoCommandBufferCreateDestroyReadiness &&
        commandBufferCreateDestroyReadiness
            .didConfirmTokenBackedCommandBufferCreateDestroy &&
        commandBufferCreateDestroyReadiness.didConfirmCommitStillBlocked &&
        commandBufferCreateDestroyReadiness
            .didConfirmEncoderCreationStillBlocked &&
        commandBufferCreateDestroyReadiness
            .didConfirmNoPresentGpuSubmissionOrRender &&
        commandBufferCreateDestroyReadiness.didConfirmNoPublicSurface &&
        commandBufferCreateDestroyReadiness.didConfirmNoRendererStateWrite &&
        commandBufferCreateDestroyReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        runtimeCallObservation.didObserveRuntimeInternalCall &&
        runtimeCallObservation
            .didObserveCommandBufferCreateClassifyDestroy &&
        runtimeCallObservation.didObserveDoubleDestroyFailClosed &&
        runtimeCallObservation.didObserveCommitAndEncoderStillBlocked &&
        runtimeCallObservation.didObserveCleanupCounts &&
        runtimeCallObservation.didKeepTokensFunctionLocal &&
        runtimeCallObservation.didConfirmNoPresentGpuSubmissionOrRender &&
        runtimeCallObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady

    return CjguiInternalRendererNoCommandBufferRuntimeCallReadiness(
        commandBufferCreateDestroyReadiness,
        runtimeCallObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        runtimeCallObservation.didObserveRuntimeInternalCall,
        runtimeCallObservation.didKeepTokensFunctionLocal,
        runtimeCallObservation
            .didObserveCommandBufferCreateClassifyDestroy,
        runtimeCallObservation.didObserveDoubleDestroyFailClosed,
        runtimeCallObservation.didObserveCleanupCounts,
        runtimeCallObservation.commitStillBlockedValue == Int32(-189),
        runtimeCallObservation.encoderCreationStillBlockedValue ==
            Int32(-190),
        runtimeCallObservation.didConfirmNoPresentGpuSubmissionOrRender,
        runtimeCallObservation.didConfirmNoPointerHandleClassIdReturn,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererCommandBufferRuntimeCallDraft():
    CjguiInternalRendererNoCommandBufferRuntimeCallReadiness {
    let commandBufferCreateDestroyReadiness =
        cjguiInternalExecuteDefaultRendererCommandBufferCreateDestroyDraft()
    let runtimeCallObservation =
        cjguiInternalObserveRendererCommandBufferRuntimeCallValues()
    return cjguiInternalBuildRendererCommandBufferRuntimeCallReadiness(
        commandBufferCreateDestroyReadiness,
        runtimeCallObservation
    )
}
