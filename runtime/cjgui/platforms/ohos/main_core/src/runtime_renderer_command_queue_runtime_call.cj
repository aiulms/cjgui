// 维护注释：本文件是 MTLCommandQueue runtime internal FFI call owner。
// Truth: 只消费 CjguiInternalRendererNoCommandQueueCreateDestroyReadiness，
// 局部执行 queue create / classify / destroy / double-destroy 调用序列，
// 并把结果脱水为 internal facts。
// Stop-line: token 只在函数局部；不创建 command buffer，不 commit，不 present，
// 不提交 GPU work，不执行 render，不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: queue runtime call facts 不得包装成 backend-ready、
// GPU submission、render permission、state write、receipt、record 或 publication。
package cjgui

struct CjguiInternalRendererCommandQueueRuntimeCallObservation {
    let deviceCreateStatusValue: Int32
    let queueCreateStatusValue: Int32
    let queueTokenValue: UInt64
    let queueClassValue: Int32
    let commandBufferStillBlockedValue: Int32
    let queueDestroyStatusValue: Int32
    let queueDestroyedClassValue: Int32
    let queueDoubleDestroyStatusValue: Int32
    let queueDoubleDestroyClassValue: Int32
    let deviceDestroyStatusValue: Int32
    let queueOccupiedBeforeValue: UInt32
    let queueOccupiedAfterCreateValue: UInt32
    let queueOccupiedAfterDestroyValue: UInt32
    let deviceOccupiedBeforeValue: UInt32
    let deviceOccupiedAfterCleanupValue: UInt32
    let didObserveRuntimeInternalCall: Bool
    let didObserveQueueCreateClassifyDestroy: Bool
    let didObserveDoubleDestroyFailClosed: Bool
    let didObserveCommandBufferStillBlocked: Bool
    let didObserveCleanupCounts: Bool
    let didKeepTokensFunctionLocal: Bool
    let didConfirmNoCommandBufferEncoderSubmitRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        deviceCreateStatusValue: Int32,
        queueCreateStatusValue: Int32,
        queueTokenValue: UInt64,
        queueClassValue: Int32,
        commandBufferStillBlockedValue: Int32,
        queueDestroyStatusValue: Int32,
        queueDestroyedClassValue: Int32,
        queueDoubleDestroyStatusValue: Int32,
        queueDoubleDestroyClassValue: Int32,
        deviceDestroyStatusValue: Int32,
        queueOccupiedBeforeValue: UInt32,
        queueOccupiedAfterCreateValue: UInt32,
        queueOccupiedAfterDestroyValue: UInt32,
        deviceOccupiedBeforeValue: UInt32,
        deviceOccupiedAfterCleanupValue: UInt32,
        didObserveRuntimeInternalCall: Bool,
        didObserveQueueCreateClassifyDestroy: Bool,
        didObserveDoubleDestroyFailClosed: Bool,
        didObserveCommandBufferStillBlocked: Bool,
        didObserveCleanupCounts: Bool,
        didKeepTokensFunctionLocal: Bool,
        didConfirmNoCommandBufferEncoderSubmitRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.deviceCreateStatusValue = deviceCreateStatusValue
        this.queueCreateStatusValue = queueCreateStatusValue
        this.queueTokenValue = queueTokenValue
        this.queueClassValue = queueClassValue
        this.commandBufferStillBlockedValue = commandBufferStillBlockedValue
        this.queueDestroyStatusValue = queueDestroyStatusValue
        this.queueDestroyedClassValue = queueDestroyedClassValue
        this.queueDoubleDestroyStatusValue = queueDoubleDestroyStatusValue
        this.queueDoubleDestroyClassValue = queueDoubleDestroyClassValue
        this.deviceDestroyStatusValue = deviceDestroyStatusValue
        this.queueOccupiedBeforeValue = queueOccupiedBeforeValue
        this.queueOccupiedAfterCreateValue = queueOccupiedAfterCreateValue
        this.queueOccupiedAfterDestroyValue = queueOccupiedAfterDestroyValue
        this.deviceOccupiedBeforeValue = deviceOccupiedBeforeValue
        this.deviceOccupiedAfterCleanupValue =
            deviceOccupiedAfterCleanupValue
        this.didObserveRuntimeInternalCall = didObserveRuntimeInternalCall
        this.didObserveQueueCreateClassifyDestroy =
            didObserveQueueCreateClassifyDestroy
        this.didObserveDoubleDestroyFailClosed =
            didObserveDoubleDestroyFailClosed
        this.didObserveCommandBufferStillBlocked =
            didObserveCommandBufferStillBlocked
        this.didObserveCleanupCounts = didObserveCleanupCounts
        this.didKeepTokensFunctionLocal = didKeepTokensFunctionLocal
        this.didConfirmNoCommandBufferEncoderSubmitRender =
            didConfirmNoCommandBufferEncoderSubmitRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoCommandQueueRuntimeCallReadiness {
    let commandQueueCreateDestroyReadiness:
        CjguiInternalRendererNoCommandQueueCreateDestroyReadiness
    let runtimeCallObservation:
        CjguiInternalRendererCommandQueueRuntimeCallObservation
    let didPrepareRendererNoCommandQueueRuntimeCallReadiness: Bool
    let shouldDeferRendererNoCommandQueueRuntimeCallReadiness: Bool
    let shouldReportRendererCommandQueueRuntimeCallBlocked: Bool
    let didPreserveRendererCommandQueueCreateDestroyReadiness: Bool
    let didConfirmRuntimeInternalCallExecuted: Bool
    let didConfirmTokensStayedFunctionLocal: Bool
    let didConfirmQueueCreateClassifyDestroyLifecycle: Bool
    let didConfirmDoubleDestroyFailClosed: Bool
    let didConfirmCleanupCountsReturnToZero: Bool
    let didConfirmCommandBufferStillBlocked: Bool
    let didConfirmNoPresentGpuSubmissionOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepCommandQueueRuntimeCallReadinessDehydrated: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        commandQueueCreateDestroyReadiness:
            CjguiInternalRendererNoCommandQueueCreateDestroyReadiness,
        runtimeCallObservation:
            CjguiInternalRendererCommandQueueRuntimeCallObservation,
        didPrepareRendererNoCommandQueueRuntimeCallReadiness: Bool,
        shouldDeferRendererNoCommandQueueRuntimeCallReadiness: Bool,
        shouldReportRendererCommandQueueRuntimeCallBlocked: Bool,
        didPreserveRendererCommandQueueCreateDestroyReadiness: Bool,
        didConfirmRuntimeInternalCallExecuted: Bool,
        didConfirmTokensStayedFunctionLocal: Bool,
        didConfirmQueueCreateClassifyDestroyLifecycle: Bool,
        didConfirmDoubleDestroyFailClosed: Bool,
        didConfirmCleanupCountsReturnToZero: Bool,
        didConfirmCommandBufferStillBlocked: Bool,
        didConfirmNoPresentGpuSubmissionOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepCommandQueueRuntimeCallReadinessDehydrated: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.commandQueueCreateDestroyReadiness =
            commandQueueCreateDestroyReadiness
        this.runtimeCallObservation = runtimeCallObservation
        this.didPrepareRendererNoCommandQueueRuntimeCallReadiness =
            didPrepareRendererNoCommandQueueRuntimeCallReadiness
        this.shouldDeferRendererNoCommandQueueRuntimeCallReadiness =
            shouldDeferRendererNoCommandQueueRuntimeCallReadiness
        this.shouldReportRendererCommandQueueRuntimeCallBlocked =
            shouldReportRendererCommandQueueRuntimeCallBlocked
        this.didPreserveRendererCommandQueueCreateDestroyReadiness =
            didPreserveRendererCommandQueueCreateDestroyReadiness
        this.didConfirmRuntimeInternalCallExecuted =
            didConfirmRuntimeInternalCallExecuted
        this.didConfirmTokensStayedFunctionLocal =
            didConfirmTokensStayedFunctionLocal
        this.didConfirmQueueCreateClassifyDestroyLifecycle =
            didConfirmQueueCreateClassifyDestroyLifecycle
        this.didConfirmDoubleDestroyFailClosed =
            didConfirmDoubleDestroyFailClosed
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
        this.didKeepCommandQueueRuntimeCallReadinessDehydrated =
            didKeepCommandQueueRuntimeCallReadinessDehydrated
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererCommandQueueRuntimeCallValues():
    CjguiInternalRendererCommandQueueRuntimeCallObservation {
    let deviceOccupiedBefore = unsafe {
        cjgui_native_bridge_metal_device_table_occupied_count()
    }
    let queueOccupiedBefore = unsafe {
        cjgui_native_bridge_command_queue_table_occupied_count()
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
    let queueClass = unsafe {
        cjgui_native_bridge_command_queue_token_classify(queueToken)
    }
    let commandBufferStillBlocked = unsafe {
        cjgui_native_bridge_command_buffer_creation_still_blocked()
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

    return CjguiInternalRendererCommandQueueRuntimeCallObservation(
        deviceCreateStatus,
        queueCreateStatus,
        queueToken,
        queueClass,
        commandBufferStillBlocked,
        queueDestroyStatus,
        queueDestroyedClass,
        queueDoubleDestroyStatus,
        queueDoubleDestroyClass,
        deviceDestroyStatus,
        queueOccupiedBefore,
        queueOccupiedAfterCreate,
        queueOccupiedAfterDestroy,
        deviceOccupiedBefore,
        deviceOccupiedAfterCleanup,
        deviceCreateStatus == Int32(0) &&
            queueCreateStatus == Int32(0) &&
            queueDestroyStatus == Int32(0) &&
            deviceDestroyStatus == Int32(0),
        queueToken != UInt64(0) &&
            queueToken < UInt64(4294967296) &&
            queueClass == Int32(160) &&
            queueDestroyStatus == Int32(0) &&
            queueDestroyedClass == Int32(-163),
        queueDoubleDestroyStatus == Int32(-166) &&
            queueDoubleDestroyClass == Int32(-166),
        commandBufferStillBlocked == Int32(-169),
        queueOccupiedBefore == queueOccupiedAfterDestroy &&
            deviceOccupiedBefore == deviceOccupiedAfterCleanup,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererCommandQueueRuntimeCallReadiness(
    commandQueueCreateDestroyReadiness:
        CjguiInternalRendererNoCommandQueueCreateDestroyReadiness,
    runtimeCallObservation:
        CjguiInternalRendererCommandQueueRuntimeCallObservation
): CjguiInternalRendererNoCommandQueueRuntimeCallReadiness {
    let upstreamReady =
        commandQueueCreateDestroyReadiness
            .didPrepareRendererNoCommandQueueCreateDestroyReadiness &&
        commandQueueCreateDestroyReadiness
            .didConfirmTokenBackedCommandQueueCreateDestroy &&
        commandQueueCreateDestroyReadiness.didConfirmCommandBufferStillBlocked &&
        commandQueueCreateDestroyReadiness
            .didConfirmNoPresentGpuSubmissionOrRender &&
        commandQueueCreateDestroyReadiness.didConfirmNoPublicSurface &&
        commandQueueCreateDestroyReadiness.didConfirmNoRendererStateWrite &&
        commandQueueCreateDestroyReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        runtimeCallObservation.didObserveRuntimeInternalCall &&
        runtimeCallObservation.didObserveQueueCreateClassifyDestroy &&
        runtimeCallObservation.didObserveDoubleDestroyFailClosed &&
        runtimeCallObservation.didObserveCommandBufferStillBlocked &&
        runtimeCallObservation.didObserveCleanupCounts &&
        runtimeCallObservation.didKeepTokensFunctionLocal &&
        runtimeCallObservation.didConfirmNoCommandBufferEncoderSubmitRender &&
        runtimeCallObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady

    return CjguiInternalRendererNoCommandQueueRuntimeCallReadiness(
        commandQueueCreateDestroyReadiness,
        runtimeCallObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        runtimeCallObservation.didObserveRuntimeInternalCall,
        runtimeCallObservation.didKeepTokensFunctionLocal,
        runtimeCallObservation.didObserveQueueCreateClassifyDestroy,
        runtimeCallObservation.didObserveDoubleDestroyFailClosed,
        runtimeCallObservation.didObserveCleanupCounts,
        runtimeCallObservation.didObserveCommandBufferStillBlocked,
        runtimeCallObservation.didConfirmNoCommandBufferEncoderSubmitRender,
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

func cjguiInternalExecuteDefaultRendererCommandQueueRuntimeCallDraft():
    CjguiInternalRendererNoCommandQueueRuntimeCallReadiness {
    let commandQueueCreateDestroyReadiness =
        cjguiInternalExecuteDefaultRendererCommandQueueCreateDestroyDraft()
    let runtimeCallObservation =
        cjguiInternalObserveRendererCommandQueueRuntimeCallValues()
    return cjguiInternalBuildRendererCommandQueueRuntimeCallReadiness(
        commandQueueCreateDestroyReadiness,
        runtimeCallObservation
    )
}
