// 维护注释：本文件是 token-backed MTLDevice create/destroy first-slice owner。
// Truth: 只消费 CjguiInternalRendererNoMetalDeviceAvailabilityReadiness，
// 调用 default device create / classify / destroy C ABI，并把 token 生命周期脱水为 facts。
// Stop-line: 不绑定 CAMetalLayer，不创建 command queue / drawable / command buffer，
// 不返回 token 到 public surface，不写 runtime_state.cj。
// Same-shape Boundary Brake: MTLDevice token facts 不得包装成 backend-ready、
// render-ready、GPU submission、state write、receipt、record 或 publication。
package cjgui

foreign func cjgui_native_bridge_metal_device_table_capacity(): UInt32
foreign func cjgui_native_bridge_metal_device_table_enabled(): UInt32
foreign func cjgui_native_bridge_metal_device_table_occupied_count(): UInt32
foreign func cjgui_native_bridge_metal_default_device_create(
    outToken: CPointer<UInt64>
): Int32
foreign func cjgui_native_bridge_metal_device_destroy(token: UInt64): Int32
foreign func cjgui_native_bridge_metal_device_token_classify(
    token: UInt64
): Int32
foreign func cjgui_native_bridge_metal_device_double_destroy_classify(
    token: UInt64
): Int32
foreign func cjgui_native_bridge_metal_device_create_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_metal_device_destroy_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_metal_device_command_queue_still_blocked():
    Int32

struct CjguiInternalRendererMetalDeviceCreateDestroyObservation {
    let createStatusValue: Int32
    let createdTokenValue: UInt64
    let validTokenClassValue: Int32
    let destroyStatusValue: Int32
    let destroyedTokenClassValue: Int32
    let doubleDestroyStatusValue: Int32
    let doubleDestroyClassValue: Int32
    let invalidDestroyStatusValue: Int32
    let createRequiresMainThreadValue: Int32
    let destroyRequiresMainThreadValue: Int32
    let commandQueueStillBlockedValue: Int32
    let tableCapacityValue: UInt32
    let tableEnabledValue: UInt32
    let occupiedBeforeValue: UInt32
    let occupiedAfterCreateValue: UInt32
    let occupiedAfterDestroyValue: UInt32
    let didObserveCreateToken: Bool
    let didObserveOpaqueToken: Bool
    let didObserveValidTokenClassification: Bool
    let didObserveOccupiedCountLifecycle: Bool
    let didObserveDestroy: Bool
    let didObserveDestroyedTokenStale: Bool
    let didObserveDoubleDestroyFailClosed: Bool
    let didObserveInvalidTokenFailClosed: Bool
    let didObserveMainThreadCreateDestroyGate: Bool
    let didConfirmNoCommandQueueDrawableOrRender: Bool
    let didConfirmNoLayerBinding: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        createStatusValue: Int32,
        createdTokenValue: UInt64,
        validTokenClassValue: Int32,
        destroyStatusValue: Int32,
        destroyedTokenClassValue: Int32,
        doubleDestroyStatusValue: Int32,
        doubleDestroyClassValue: Int32,
        invalidDestroyStatusValue: Int32,
        createRequiresMainThreadValue: Int32,
        destroyRequiresMainThreadValue: Int32,
        commandQueueStillBlockedValue: Int32,
        tableCapacityValue: UInt32,
        tableEnabledValue: UInt32,
        occupiedBeforeValue: UInt32,
        occupiedAfterCreateValue: UInt32,
        occupiedAfterDestroyValue: UInt32,
        didObserveCreateToken: Bool,
        didObserveOpaqueToken: Bool,
        didObserveValidTokenClassification: Bool,
        didObserveOccupiedCountLifecycle: Bool,
        didObserveDestroy: Bool,
        didObserveDestroyedTokenStale: Bool,
        didObserveDoubleDestroyFailClosed: Bool,
        didObserveInvalidTokenFailClosed: Bool,
        didObserveMainThreadCreateDestroyGate: Bool,
        didConfirmNoCommandQueueDrawableOrRender: Bool,
        didConfirmNoLayerBinding: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.createStatusValue = createStatusValue
        this.createdTokenValue = createdTokenValue
        this.validTokenClassValue = validTokenClassValue
        this.destroyStatusValue = destroyStatusValue
        this.destroyedTokenClassValue = destroyedTokenClassValue
        this.doubleDestroyStatusValue = doubleDestroyStatusValue
        this.doubleDestroyClassValue = doubleDestroyClassValue
        this.invalidDestroyStatusValue = invalidDestroyStatusValue
        this.createRequiresMainThreadValue = createRequiresMainThreadValue
        this.destroyRequiresMainThreadValue = destroyRequiresMainThreadValue
        this.commandQueueStillBlockedValue = commandQueueStillBlockedValue
        this.tableCapacityValue = tableCapacityValue
        this.tableEnabledValue = tableEnabledValue
        this.occupiedBeforeValue = occupiedBeforeValue
        this.occupiedAfterCreateValue = occupiedAfterCreateValue
        this.occupiedAfterDestroyValue = occupiedAfterDestroyValue
        this.didObserveCreateToken = didObserveCreateToken
        this.didObserveOpaqueToken = didObserveOpaqueToken
        this.didObserveValidTokenClassification =
            didObserveValidTokenClassification
        this.didObserveOccupiedCountLifecycle =
            didObserveOccupiedCountLifecycle
        this.didObserveDestroy = didObserveDestroy
        this.didObserveDestroyedTokenStale = didObserveDestroyedTokenStale
        this.didObserveDoubleDestroyFailClosed =
            didObserveDoubleDestroyFailClosed
        this.didObserveInvalidTokenFailClosed =
            didObserveInvalidTokenFailClosed
        this.didObserveMainThreadCreateDestroyGate =
            didObserveMainThreadCreateDestroyGate
        this.didConfirmNoCommandQueueDrawableOrRender =
            didConfirmNoCommandQueueDrawableOrRender
        this.didConfirmNoLayerBinding = didConfirmNoLayerBinding
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoMetalDeviceCreateDestroyReadiness {
    let availabilityReadiness:
        CjguiInternalRendererNoMetalDeviceAvailabilityReadiness
    let createDestroyObservation:
        CjguiInternalRendererMetalDeviceCreateDestroyObservation
    let didPrepareRendererNoMetalDeviceCreateDestroyReadiness: Bool
    let shouldDeferRendererNoMetalDeviceCreateDestroyReadiness: Bool
    let shouldReportRendererNoMetalDeviceCreateDestroyBlocked: Bool
    let didPreserveRendererMetalDeviceAvailabilityReadiness: Bool
    let didConfirmFixedCapacityDeviceTable: Bool
    let didConfirmMainThreadCreateDestroyGate: Bool
    let didConfirmOpaqueTokenIdentity: Bool
    let didConfirmTokenNotPointer: Bool
    let didConfirmCreateClassifyDestroyLifecycle: Bool
    let didConfirmDestroyedTokenStale: Bool
    let didConfirmDoubleDestroyFailClosed: Bool
    let didConfirmInvalidTokenFailClosed: Bool
    let didConfirmNoLayerBinding: Bool
    let didConfirmNoCommandQueueDrawableOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepMetalDeviceCreateDestroyReadinessDehydrated: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        availabilityReadiness:
            CjguiInternalRendererNoMetalDeviceAvailabilityReadiness,
        createDestroyObservation:
            CjguiInternalRendererMetalDeviceCreateDestroyObservation,
        didPrepareRendererNoMetalDeviceCreateDestroyReadiness: Bool,
        shouldDeferRendererNoMetalDeviceCreateDestroyReadiness: Bool,
        shouldReportRendererNoMetalDeviceCreateDestroyBlocked: Bool,
        didPreserveRendererMetalDeviceAvailabilityReadiness: Bool,
        didConfirmFixedCapacityDeviceTable: Bool,
        didConfirmMainThreadCreateDestroyGate: Bool,
        didConfirmOpaqueTokenIdentity: Bool,
        didConfirmTokenNotPointer: Bool,
        didConfirmCreateClassifyDestroyLifecycle: Bool,
        didConfirmDestroyedTokenStale: Bool,
        didConfirmDoubleDestroyFailClosed: Bool,
        didConfirmInvalidTokenFailClosed: Bool,
        didConfirmNoLayerBinding: Bool,
        didConfirmNoCommandQueueDrawableOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepMetalDeviceCreateDestroyReadinessDehydrated: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.availabilityReadiness = availabilityReadiness
        this.createDestroyObservation = createDestroyObservation
        this.didPrepareRendererNoMetalDeviceCreateDestroyReadiness =
            didPrepareRendererNoMetalDeviceCreateDestroyReadiness
        this.shouldDeferRendererNoMetalDeviceCreateDestroyReadiness =
            shouldDeferRendererNoMetalDeviceCreateDestroyReadiness
        this.shouldReportRendererNoMetalDeviceCreateDestroyBlocked =
            shouldReportRendererNoMetalDeviceCreateDestroyBlocked
        this.didPreserveRendererMetalDeviceAvailabilityReadiness =
            didPreserveRendererMetalDeviceAvailabilityReadiness
        this.didConfirmFixedCapacityDeviceTable =
            didConfirmFixedCapacityDeviceTable
        this.didConfirmMainThreadCreateDestroyGate =
            didConfirmMainThreadCreateDestroyGate
        this.didConfirmOpaqueTokenIdentity = didConfirmOpaqueTokenIdentity
        this.didConfirmTokenNotPointer = didConfirmTokenNotPointer
        this.didConfirmCreateClassifyDestroyLifecycle =
            didConfirmCreateClassifyDestroyLifecycle
        this.didConfirmDestroyedTokenStale = didConfirmDestroyedTokenStale
        this.didConfirmDoubleDestroyFailClosed =
            didConfirmDoubleDestroyFailClosed
        this.didConfirmInvalidTokenFailClosed =
            didConfirmInvalidTokenFailClosed
        this.didConfirmNoLayerBinding = didConfirmNoLayerBinding
        this.didConfirmNoCommandQueueDrawableOrRender =
            didConfirmNoCommandQueueDrawableOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepMetalDeviceCreateDestroyReadinessDehydrated =
            didKeepMetalDeviceCreateDestroyReadinessDehydrated
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererMetalDeviceCreateDestroyValues():
    CjguiInternalRendererMetalDeviceCreateDestroyObservation {
    let occupiedBefore = unsafe {
        cjgui_native_bridge_metal_device_table_occupied_count()
    }
    let capacity = unsafe {
        cjgui_native_bridge_metal_device_table_capacity()
    }
    let enabled = unsafe {
        cjgui_native_bridge_metal_device_table_enabled()
    }
    var createdToken = UInt64(0)
    let createStatus = unsafe {
        cjgui_native_bridge_metal_default_device_create(inout createdToken)
    }
    let occupiedAfterCreate = unsafe {
        cjgui_native_bridge_metal_device_table_occupied_count()
    }
    let validTokenClass = unsafe {
        cjgui_native_bridge_metal_device_token_classify(createdToken)
    }
    let invalidDestroyStatus = unsafe {
        cjgui_native_bridge_metal_device_destroy(UInt64(0))
    }
    let createRequiresMainThread = unsafe {
        cjgui_native_bridge_metal_device_create_requires_main_thread()
    }
    let destroyRequiresMainThread = unsafe {
        cjgui_native_bridge_metal_device_destroy_requires_main_thread()
    }
    let commandQueueStillBlocked = unsafe {
        cjgui_native_bridge_metal_device_command_queue_still_blocked()
    }
    let destroyStatus = unsafe {
        cjgui_native_bridge_metal_device_destroy(createdToken)
    }
    let occupiedAfterDestroy = unsafe {
        cjgui_native_bridge_metal_device_table_occupied_count()
    }
    let destroyedTokenClass = unsafe {
        cjgui_native_bridge_metal_device_token_classify(createdToken)
    }
    let doubleDestroyStatus = unsafe {
        cjgui_native_bridge_metal_device_destroy(createdToken)
    }
    let doubleDestroyClass = unsafe {
        cjgui_native_bridge_metal_device_double_destroy_classify(createdToken)
    }

    return CjguiInternalRendererMetalDeviceCreateDestroyObservation(
        createStatus,
        createdToken,
        validTokenClass,
        destroyStatus,
        destroyedTokenClass,
        doubleDestroyStatus,
        doubleDestroyClass,
        invalidDestroyStatus,
        createRequiresMainThread,
        destroyRequiresMainThread,
        commandQueueStillBlocked,
        capacity,
        enabled,
        occupiedBefore,
        occupiedAfterCreate,
        occupiedAfterDestroy,
        createStatus == Int32(0) && createdToken != UInt64(0),
        createdToken != UInt64(0),
        validTokenClass == Int32(120),
        occupiedAfterCreate == occupiedBefore + UInt32(1) &&
            occupiedAfterDestroy == occupiedBefore,
        destroyStatus == Int32(0),
        destroyedTokenClass == Int32(-123),
        doubleDestroyStatus == Int32(-126) &&
            doubleDestroyClass == Int32(-126),
        invalidDestroyStatus == Int32(-122),
        createRequiresMainThread == Int32(-120) &&
            destroyRequiresMainThread == Int32(-121),
        commandQueueStillBlocked == Int32(-129),
        true,
        true
    )
}

func cjguiInternalBuildRendererMetalDeviceCreateDestroyReadiness(
    availabilityReadiness:
        CjguiInternalRendererNoMetalDeviceAvailabilityReadiness,
    createDestroyObservation:
        CjguiInternalRendererMetalDeviceCreateDestroyObservation
): CjguiInternalRendererNoMetalDeviceCreateDestroyReadiness {
    let upstreamReady =
        availabilityReadiness
            .didPrepareRendererNoMetalDeviceAvailabilityReadiness &&
        availabilityReadiness.didConfirmDefaultDeviceAvailabilityObserved &&
        availabilityReadiness.didConfirmNoCommandQueueDrawableOrRender &&
        availabilityReadiness.didConfirmNoPublicSurface &&
        availabilityReadiness.didConfirmNoRendererStateWrite &&
        availabilityReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        createDestroyObservation.didObserveCreateToken &&
        createDestroyObservation.didObserveOpaqueToken &&
        createDestroyObservation.didObserveValidTokenClassification &&
        createDestroyObservation.didObserveOccupiedCountLifecycle &&
        createDestroyObservation.didObserveDestroy &&
        createDestroyObservation.didObserveDestroyedTokenStale &&
        createDestroyObservation.didObserveDoubleDestroyFailClosed &&
        createDestroyObservation.didObserveInvalidTokenFailClosed &&
        createDestroyObservation.didObserveMainThreadCreateDestroyGate &&
        createDestroyObservation.didConfirmNoCommandQueueDrawableOrRender &&
        createDestroyObservation.didConfirmNoLayerBinding &&
        createDestroyObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady

    return CjguiInternalRendererNoMetalDeviceCreateDestroyReadiness(
        availabilityReadiness,
        createDestroyObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        createDestroyObservation.tableCapacityValue > UInt32(0) &&
            createDestroyObservation.tableEnabledValue == UInt32(1),
        createDestroyObservation.didObserveMainThreadCreateDestroyGate,
        createDestroyObservation.didObserveOpaqueToken,
        createDestroyObservation.didObserveOpaqueToken,
        createDestroyObservation.didObserveCreateToken &&
            createDestroyObservation.didObserveValidTokenClassification &&
            createDestroyObservation.didObserveDestroy,
        createDestroyObservation.didObserveDestroyedTokenStale,
        createDestroyObservation.didObserveDoubleDestroyFailClosed,
        createDestroyObservation.didObserveInvalidTokenFailClosed,
        createDestroyObservation.didConfirmNoLayerBinding,
        createDestroyObservation.didConfirmNoCommandQueueDrawableOrRender,
        createDestroyObservation.didConfirmNoPointerHandleClassIdReturn,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererMetalDeviceCreateDestroyDraft():
    CjguiInternalRendererNoMetalDeviceCreateDestroyReadiness {
    let availabilityReadiness =
        cjguiInternalExecuteDefaultRendererMetalDeviceAvailabilityDraft()
    let createDestroyObservation =
        cjguiInternalObserveRendererMetalDeviceCreateDestroyValues()
    return cjguiInternalBuildRendererMetalDeviceCreateDestroyReadiness(
        availabilityReadiness,
        createDestroyObservation
    )
}
