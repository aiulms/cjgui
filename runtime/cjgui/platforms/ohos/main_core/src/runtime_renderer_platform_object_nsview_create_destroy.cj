// Owner: platform object NSView create/destroy first-slice internal owner。
// Truth: 只消费 CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness，
// 调用 token-backed NSView create / classify / destroy C ABI，并把返回值脱水为
// internal facts。
// Stop-line: 不返回 Class / id / pointer / handle，不创建 NSWindow / layer /
// Metal，不写 runtime_state.cj，不新增 public API。
// Same-shape Boundary Brake: 不得把本 owner 包成 backend-ready、render-ready、
// Metal layer、renderer state write、receipt、record 或 publication wrapper。
package cjgui

foreign func cjgui_native_bridge_nsview_create(outToken: CPointer<UInt64>):
    Int32
foreign func cjgui_native_bridge_nsview_destroy(token: UInt64): Int32
foreign func cjgui_native_bridge_nsview_token_classify(token: UInt64): Int32
foreign func cjgui_native_bridge_nsview_table_occupied_count(): UInt32
foreign func cjgui_native_bridge_nsview_double_destroy_classify(
    token: UInt64
): Int32
foreign func cjgui_native_bridge_nsview_destroy_requires_main_thread():
    Int32

struct CjguiInternalRendererPlatformObjectNsViewCreateDestroyObservation {
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
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoNsWindowNsApplicationLayerMetal: Bool

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
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoNsWindowNsApplicationLayerMetal: Bool
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
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoNsWindowNsApplicationLayerMetal =
            didConfirmNoNsWindowNsApplicationLayerMetal
    }
}

struct CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness {
    let nsViewObjectTableReadiness:
        CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness
    let createDestroyObservation:
        CjguiInternalRendererPlatformObjectNsViewCreateDestroyObservation
    let didPrepareRendererNoPlatformObjectNsViewCreateDestroyReadiness:
        Bool
    let shouldDeferRendererNoPlatformObjectNsViewCreateDestroyReadiness:
        Bool
    let shouldReportRendererNoPlatformObjectNsViewCreateDestroyBlocked:
        Bool
    let didPreserveRendererPlatformObjectNsViewObjectTableReadiness: Bool
    let didConfirmFixedCapacityNsViewTable: Bool
    let didConfirmMainThreadCreateDestroyGate: Bool
    let didConfirmOpaqueTokenIdentity: Bool
    let didConfirmTokenNotPointer: Bool
    let didConfirmCreateClassifyDestroyLifecycle: Bool
    let didConfirmDestroyedTokenStale: Bool
    let didConfirmDoubleDestroyFailClosed: Bool
    let didConfirmInvalidTokenFailClosed: Bool
    let didConfirmNoNsWindowNsApplicationLayerMetal: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNsViewCreateDestroyReadinessDehydrated: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        nsViewObjectTableReadiness:
            CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness,
        createDestroyObservation:
            CjguiInternalRendererPlatformObjectNsViewCreateDestroyObservation,
        didPrepareRendererNoPlatformObjectNsViewCreateDestroyReadiness:
            Bool,
        shouldDeferRendererNoPlatformObjectNsViewCreateDestroyReadiness:
            Bool,
        shouldReportRendererNoPlatformObjectNsViewCreateDestroyBlocked:
            Bool,
        didPreserveRendererPlatformObjectNsViewObjectTableReadiness: Bool,
        didConfirmFixedCapacityNsViewTable: Bool,
        didConfirmMainThreadCreateDestroyGate: Bool,
        didConfirmOpaqueTokenIdentity: Bool,
        didConfirmTokenNotPointer: Bool,
        didConfirmCreateClassifyDestroyLifecycle: Bool,
        didConfirmDestroyedTokenStale: Bool,
        didConfirmDoubleDestroyFailClosed: Bool,
        didConfirmInvalidTokenFailClosed: Bool,
        didConfirmNoNsWindowNsApplicationLayerMetal: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNsViewCreateDestroyReadinessDehydrated: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.nsViewObjectTableReadiness = nsViewObjectTableReadiness
        this.createDestroyObservation = createDestroyObservation
        this
            .didPrepareRendererNoPlatformObjectNsViewCreateDestroyReadiness =
            didPrepareRendererNoPlatformObjectNsViewCreateDestroyReadiness
        this.shouldDeferRendererNoPlatformObjectNsViewCreateDestroyReadiness =
            shouldDeferRendererNoPlatformObjectNsViewCreateDestroyReadiness
        this.shouldReportRendererNoPlatformObjectNsViewCreateDestroyBlocked =
            shouldReportRendererNoPlatformObjectNsViewCreateDestroyBlocked
        this.didPreserveRendererPlatformObjectNsViewObjectTableReadiness =
            didPreserveRendererPlatformObjectNsViewObjectTableReadiness
        this.didConfirmFixedCapacityNsViewTable =
            didConfirmFixedCapacityNsViewTable
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
        this.didConfirmNoNsWindowNsApplicationLayerMetal =
            didConfirmNoNsWindowNsApplicationLayerMetal
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth =
            didConfirmNoBackendReadyTruth
        this.didKeepNsViewCreateDestroyReadinessDehydrated =
            didKeepNsViewCreateDestroyReadinessDehydrated
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererPlatformObjectNsViewCreateDestroyValues():
    CjguiInternalRendererPlatformObjectNsViewCreateDestroyObservation {
    let occupiedBefore = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    var createdToken = UInt64(0)
    let createStatus = unsafe {
        cjgui_native_bridge_nsview_create(inout createdToken)
    }
    let occupiedAfterCreate = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    let validTokenClass = unsafe {
        cjgui_native_bridge_nsview_token_classify(createdToken)
    }
    let invalidDestroyStatus = unsafe {
        cjgui_native_bridge_nsview_destroy(UInt64(0))
    }
    let destroyRequiresMainThread = unsafe {
        cjgui_native_bridge_nsview_destroy_requires_main_thread()
    }
    let destroyStatus = unsafe {
        cjgui_native_bridge_nsview_destroy(createdToken)
    }
    let occupiedAfterDestroy = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    let destroyedTokenClass = unsafe {
        cjgui_native_bridge_nsview_token_classify(createdToken)
    }
    let doubleDestroyStatus = unsafe {
        cjgui_native_bridge_nsview_destroy(createdToken)
    }
    let doubleDestroyClass = unsafe {
        cjgui_native_bridge_nsview_double_destroy_classify(createdToken)
    }

    return CjguiInternalRendererPlatformObjectNsViewCreateDestroyObservation(
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
        validTokenClass == Int32(40),
        occupiedBefore == UInt32(0) &&
            occupiedAfterCreate == UInt32(1) &&
            occupiedAfterDestroy == UInt32(0),
        createStatus == Int32(0) &&
            createdToken != UInt64(0) &&
            validTokenClass == Int32(40) &&
            destroyStatus == Int32(0),
        destroyStatus == Int32(0),
        destroyedTokenClass == Int32(-43),
        doubleDestroyStatus == Int32(-46) &&
            doubleDestroyClass == Int32(-46),
        invalidDestroyStatus == Int32(-42),
        destroyRequiresMainThread == Int32(-41),
        true,
        true
    )
}

func cjguiInternalBuildRendererPlatformObjectNsViewCreateDestroyReadiness(
    nsViewObjectTableReadiness:
        CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness,
    createDestroyObservation:
        CjguiInternalRendererPlatformObjectNsViewCreateDestroyObservation
): CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness {
    let upstreamReady =
        nsViewObjectTableReadiness
            .didPrepareRendererNoPlatformObjectNsViewObjectTableReadiness &&
        nsViewObjectTableReadiness.didConfirmFixedCapacityNsViewTableShell &&
        nsViewObjectTableReadiness.didConfirmTableEnabled &&
        nsViewObjectTableReadiness.didConfirmMainThreadConfinementPolicy &&
        nsViewObjectTableReadiness.didConfirmNoPointerHandleClassIdReturn &&
        nsViewObjectTableReadiness.didConfirmNoNsWindowNsApplicationLayerMetal &&
        nsViewObjectTableReadiness.didConfirmNoPublicSurface &&
        nsViewObjectTableReadiness.didConfirmNoRendererStateWrite &&
        nsViewObjectTableReadiness.didConfirmNoBackendReadyTruth
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
        createDestroyObservation.didConfirmNoPointerHandleClassIdReturn &&
        createDestroyObservation.didConfirmNoNsWindowNsApplicationLayerMetal
    let readinessReady = upstreamReady && observationReady
    return CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness(
        nsViewObjectTableReadiness,
        createDestroyObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        nsViewObjectTableReadiness.didConfirmFixedCapacityNsViewTableShell,
        createDestroyObservation.didObserveDestroyRequiresMainThread,
        createDestroyObservation.didObserveOpaqueToken,
        createDestroyObservation.createdTokenValue < UInt64(4294967296),
        createDestroyObservation.didObserveCreateClassifyDestroyLifecycle,
        createDestroyObservation.didObserveDestroyedTokenStale,
        createDestroyObservation.didObserveDoubleDestroyFailClosed,
        createDestroyObservation.didObserveInvalidTokenFailClosed,
        createDestroyObservation.didConfirmNoNsWindowNsApplicationLayerMetal,
        createDestroyObservation.didConfirmNoPointerHandleClassIdReturn,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererPlatformObjectNsViewCreateDestroyDraft():
    CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness {
    let nsViewObjectTableReadiness =
        cjguiInternalExecuteDefaultRendererPlatformObjectNsViewObjectTableDraft()
    let createDestroyObservation =
        cjguiInternalObserveRendererPlatformObjectNsViewCreateDestroyValues()
    return cjguiInternalBuildRendererPlatformObjectNsViewCreateDestroyReadiness(
        nsViewObjectTableReadiness,
        createDestroyObservation
    )
}
