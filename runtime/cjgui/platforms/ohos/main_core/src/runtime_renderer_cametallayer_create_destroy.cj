// 维护注释：本文件是 CAMetalLayer token-backed create/destroy first-slice owner。
// Truth: 只消费 CjguiInternalRendererNoCAMetalLayerObjectTableReadiness，
// 调用 create / classify / destroy C ABI，并把返回值脱水为 internal facts。
// Stop-line: 不 attach 到 NSView，不设置 layer / wantsLayer，不设置 Metal device，
// 不获取 drawable，不返回 pointer / handle / Class / id，不写 runtime_state.cj。
// Same-shape Boundary Brake: 不得把 layer token lifecycle 包成 backend-ready、
// render-ready、Metal device、drawable、GPU submission、state write 或 publication。
package cjgui

foreign func cjgui_native_bridge_cametallayer_create(
    outToken: CPointer<UInt64>
): Int32
foreign func cjgui_native_bridge_cametallayer_destroy(token: UInt64): Int32
foreign func cjgui_native_bridge_cametallayer_token_classify(
    token: UInt64
): Int32
foreign func cjgui_native_bridge_cametallayer_table_occupied_count(): UInt32
foreign func cjgui_native_bridge_cametallayer_double_destroy_classify(
    token: UInt64
): Int32
foreign func cjgui_native_bridge_cametallayer_destroy_requires_main_thread():
    Int32

struct CjguiInternalRendererCAMetalLayerCreateDestroyObservation {
    let createStatusValue: Int32
    let createdTokenValue: UInt64
    let validTokenClassValue: Int32
    let destroyStatusValue: Int32
    let destroyedTokenClassValue: Int32
    let doubleDestroyStatusValue: Int32
    let doubleDestroyClassValue: Int32
    let invalidDestroyStatusValue: Int32
    let destroyRequiresMainThreadValue: Int32
    let occupiedBeforeValue: UInt32
    let occupiedAfterCreateValue: UInt32
    let occupiedAfterDestroyValue: UInt32
    let didObserveMainThreadCreate: Bool
    let didObserveOpaqueToken: Bool
    let didObserveValidTokenClassification: Bool
    let didObserveOccupiedCountLifecycle: Bool
    let didObserveCreateClassifyDestroyLifecycle: Bool
    let didObserveDestroy: Bool
    let didObserveDestroyedTokenStale: Bool
    let didObserveDoubleDestroyFailClosed: Bool
    let didObserveInvalidTokenFailClosed: Bool
    let didObserveDestroyRequiresMainThread: Bool
    let didConfirmNoAttachment: Bool
    let didConfirmNoDeviceDrawableOrRender: Bool
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
        destroyRequiresMainThreadValue: Int32,
        occupiedBeforeValue: UInt32,
        occupiedAfterCreateValue: UInt32,
        occupiedAfterDestroyValue: UInt32,
        didObserveMainThreadCreate: Bool,
        didObserveOpaqueToken: Bool,
        didObserveValidTokenClassification: Bool,
        didObserveOccupiedCountLifecycle: Bool,
        didObserveCreateClassifyDestroyLifecycle: Bool,
        didObserveDestroy: Bool,
        didObserveDestroyedTokenStale: Bool,
        didObserveDoubleDestroyFailClosed: Bool,
        didObserveInvalidTokenFailClosed: Bool,
        didObserveDestroyRequiresMainThread: Bool,
        didConfirmNoAttachment: Bool,
        didConfirmNoDeviceDrawableOrRender: Bool,
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
        this.destroyRequiresMainThreadValue = destroyRequiresMainThreadValue
        this.occupiedBeforeValue = occupiedBeforeValue
        this.occupiedAfterCreateValue = occupiedAfterCreateValue
        this.occupiedAfterDestroyValue = occupiedAfterDestroyValue
        this.didObserveMainThreadCreate = didObserveMainThreadCreate
        this.didObserveOpaqueToken = didObserveOpaqueToken
        this.didObserveValidTokenClassification =
            didObserveValidTokenClassification
        this.didObserveOccupiedCountLifecycle =
            didObserveOccupiedCountLifecycle
        this.didObserveCreateClassifyDestroyLifecycle =
            didObserveCreateClassifyDestroyLifecycle
        this.didObserveDestroy = didObserveDestroy
        this.didObserveDestroyedTokenStale = didObserveDestroyedTokenStale
        this.didObserveDoubleDestroyFailClosed =
            didObserveDoubleDestroyFailClosed
        this.didObserveInvalidTokenFailClosed =
            didObserveInvalidTokenFailClosed
        this.didObserveDestroyRequiresMainThread =
            didObserveDestroyRequiresMainThread
        this.didConfirmNoAttachment = didConfirmNoAttachment
        this.didConfirmNoDeviceDrawableOrRender =
            didConfirmNoDeviceDrawableOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoCAMetalLayerCreateDestroyReadiness {
    let didPrepareRendererNoCAMetalLayerCreateDestroyReadiness: Bool
    let shouldDeferRendererNoCAMetalLayerCreateDestroyReadiness: Bool
    let shouldReportRendererNoCAMetalLayerCreateDestroyBlocked: Bool
    let didPreserveRendererCAMetalLayerObjectTableReadiness: Bool
    let didConfirmFixedCapacityCAMetalLayerTable: Bool
    let didConfirmMainThreadCreateDestroyGate: Bool
    let didConfirmOpaqueTokenIdentity: Bool
    let didConfirmTokenNotPointer: Bool
    let didConfirmCreateClassifyDestroyLifecycle: Bool
    let didConfirmDestroyedTokenStale: Bool
    let didConfirmDoubleDestroyFailClosed: Bool
    let didConfirmInvalidTokenFailClosed: Bool
    let didConfirmNoAttachment: Bool
    let didConfirmNoDeviceDrawableOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepCAMetalLayerCreateDestroyReadinessDehydrated: Bool
    let didAvoidAttachWrapper: Bool
    let didAvoidMetalReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        didPrepareRendererNoCAMetalLayerCreateDestroyReadiness: Bool,
        shouldDeferRendererNoCAMetalLayerCreateDestroyReadiness: Bool,
        shouldReportRendererNoCAMetalLayerCreateDestroyBlocked: Bool,
        didPreserveRendererCAMetalLayerObjectTableReadiness: Bool,
        didConfirmFixedCapacityCAMetalLayerTable: Bool,
        didConfirmMainThreadCreateDestroyGate: Bool,
        didConfirmOpaqueTokenIdentity: Bool,
        didConfirmTokenNotPointer: Bool,
        didConfirmCreateClassifyDestroyLifecycle: Bool,
        didConfirmDestroyedTokenStale: Bool,
        didConfirmDoubleDestroyFailClosed: Bool,
        didConfirmInvalidTokenFailClosed: Bool,
        didConfirmNoAttachment: Bool,
        didConfirmNoDeviceDrawableOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepCAMetalLayerCreateDestroyReadinessDehydrated: Bool,
        didAvoidAttachWrapper: Bool,
        didAvoidMetalReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.didPrepareRendererNoCAMetalLayerCreateDestroyReadiness =
            didPrepareRendererNoCAMetalLayerCreateDestroyReadiness
        this.shouldDeferRendererNoCAMetalLayerCreateDestroyReadiness =
            shouldDeferRendererNoCAMetalLayerCreateDestroyReadiness
        this.shouldReportRendererNoCAMetalLayerCreateDestroyBlocked =
            shouldReportRendererNoCAMetalLayerCreateDestroyBlocked
        this.didPreserveRendererCAMetalLayerObjectTableReadiness =
            didPreserveRendererCAMetalLayerObjectTableReadiness
        this.didConfirmFixedCapacityCAMetalLayerTable =
            didConfirmFixedCapacityCAMetalLayerTable
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
        this.didConfirmNoAttachment = didConfirmNoAttachment
        this.didConfirmNoDeviceDrawableOrRender =
            didConfirmNoDeviceDrawableOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth =
            didConfirmNoBackendReadyTruth
        this.didKeepCAMetalLayerCreateDestroyReadinessDehydrated =
            didKeepCAMetalLayerCreateDestroyReadinessDehydrated
        this.didAvoidAttachWrapper = didAvoidAttachWrapper
        this.didAvoidMetalReadyWrapper = didAvoidMetalReadyWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
    }
}

func cjguiInternalObserveRendererCAMetalLayerCreateDestroyValues():
    CjguiInternalRendererCAMetalLayerCreateDestroyObservation {
    let occupiedBefore = unsafe {
        cjgui_native_bridge_cametallayer_table_occupied_count()
    }
    var createdToken = UInt64(0)
    let createStatus = unsafe {
        cjgui_native_bridge_cametallayer_create(inout createdToken)
    }
    let occupiedAfterCreate = unsafe {
        cjgui_native_bridge_cametallayer_table_occupied_count()
    }
    let validTokenClass = unsafe {
        cjgui_native_bridge_cametallayer_token_classify(createdToken)
    }
    let invalidDestroyStatus = unsafe {
        cjgui_native_bridge_cametallayer_destroy(UInt64(0))
    }
    let destroyRequiresMainThread = unsafe {
        cjgui_native_bridge_cametallayer_destroy_requires_main_thread()
    }
    let destroyStatus = unsafe {
        cjgui_native_bridge_cametallayer_destroy(createdToken)
    }
    let occupiedAfterDestroy = unsafe {
        cjgui_native_bridge_cametallayer_table_occupied_count()
    }
    let destroyedTokenClass = unsafe {
        cjgui_native_bridge_cametallayer_token_classify(createdToken)
    }
    let doubleDestroyStatus = unsafe {
        cjgui_native_bridge_cametallayer_destroy(createdToken)
    }
    let doubleDestroyClass = unsafe {
        cjgui_native_bridge_cametallayer_double_destroy_classify(createdToken)
    }

    return CjguiInternalRendererCAMetalLayerCreateDestroyObservation(
        createStatus,
        createdToken,
        validTokenClass,
        destroyStatus,
        destroyedTokenClass,
        doubleDestroyStatus,
        doubleDestroyClass,
        invalidDestroyStatus,
        destroyRequiresMainThread,
        occupiedBefore,
        occupiedAfterCreate,
        occupiedAfterDestroy,
        createStatus == Int32(0) && createdToken != UInt64(0),
        createdToken != UInt64(0),
        validTokenClass == Int32(80),
        occupiedBefore == UInt32(0) &&
            occupiedAfterCreate == UInt32(1) &&
            occupiedAfterDestroy == UInt32(0),
        createStatus == Int32(0) &&
            createdToken != UInt64(0) &&
            validTokenClass == Int32(80) &&
            destroyStatus == Int32(0),
        destroyStatus == Int32(0),
        destroyedTokenClass == Int32(-83),
        doubleDestroyStatus == Int32(-86) &&
            doubleDestroyClass == Int32(-86),
        invalidDestroyStatus == Int32(-82),
        destroyRequiresMainThread == Int32(-81),
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererCAMetalLayerCreateDestroyReadiness(
    objectTableReadiness:
        CjguiInternalRendererNoCAMetalLayerObjectTableReadiness,
    createDestroyObservation:
        CjguiInternalRendererCAMetalLayerCreateDestroyObservation
): CjguiInternalRendererNoCAMetalLayerCreateDestroyReadiness {
    let upstreamReady =
        objectTableReadiness
            .didPrepareRendererNoCAMetalLayerObjectTableReadiness &&
        objectTableReadiness.didConfirmFixedCapacityCAMetalLayerTableShell &&
        objectTableReadiness.didConfirmTableEnabled &&
        objectTableReadiness.didConfirmNoAttachment &&
        objectTableReadiness.didConfirmNoMetalDeviceOrDrawable &&
        objectTableReadiness.didConfirmNoPointerHandleClassIdReturn &&
        objectTableReadiness.didConfirmNoRendererStateWrite &&
        objectTableReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        createDestroyObservation.didObserveMainThreadCreate &&
        createDestroyObservation.didObserveOpaqueToken &&
        createDestroyObservation.didObserveValidTokenClassification &&
        createDestroyObservation.didObserveOccupiedCountLifecycle &&
        createDestroyObservation.didObserveDestroy &&
        createDestroyObservation.didObserveDestroyedTokenStale &&
        createDestroyObservation.didObserveDoubleDestroyFailClosed &&
        createDestroyObservation.didObserveInvalidTokenFailClosed &&
        createDestroyObservation.didObserveDestroyRequiresMainThread &&
        createDestroyObservation.didConfirmNoAttachment &&
        createDestroyObservation.didConfirmNoDeviceDrawableOrRender &&
        createDestroyObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady
    return CjguiInternalRendererNoCAMetalLayerCreateDestroyReadiness(
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        objectTableReadiness.didConfirmFixedCapacityCAMetalLayerTableShell,
        createDestroyObservation.didObserveDestroyRequiresMainThread,
        createDestroyObservation.didObserveOpaqueToken,
        createDestroyObservation.createdTokenValue < UInt64(4294967296),
        createDestroyObservation.didObserveCreateClassifyDestroyLifecycle,
        createDestroyObservation.didObserveDestroyedTokenStale,
        createDestroyObservation.didObserveDoubleDestroyFailClosed,
        createDestroyObservation.didObserveInvalidTokenFailClosed,
        createDestroyObservation.didConfirmNoAttachment,
        createDestroyObservation.didConfirmNoDeviceDrawableOrRender,
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

func cjguiInternalExecuteDefaultRendererCAMetalLayerCreateDestroyDraft():
    CjguiInternalRendererNoCAMetalLayerCreateDestroyReadiness {
    let objectTableReadiness =
        cjguiInternalExecuteDefaultRendererCAMetalLayerObjectTableDraft()
    let createDestroyObservation =
        cjguiInternalObserveRendererCAMetalLayerCreateDestroyValues()
    return cjguiInternalBuildRendererCAMetalLayerCreateDestroyReadiness(
        objectTableReadiness,
        createDestroyObservation
    )
}
