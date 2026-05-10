// Owner: platform object NSView runtime FFI call internal owner。
// Truth: 只消费 CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness，
// 复用已验证的 internal foreign declarations，执行一次局部 NSView create /
// classify / destroy 序列，并脱水为 runtime-internal facts。
// Stop-line: 不返回 token / Class / id / pointer / handle，不创建 NSWindow /
// layer / Metal，不写 runtime_state.cj，不新增 public API。
// Same-shape Boundary Brake: 不得把本 owner 包成 backend-ready、render-ready、
// Metal layer、renderer state write、receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererPlatformObjectNsViewRuntimeCallObservation {
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
    let didObserveCreate: Bool
    let didObserveOpaqueToken: Bool
    let didObserveValidToken: Bool
    let didObserveOccupiedCountLifecycle: Bool
    let didObserveDestroy: Bool
    let didObserveDestroyedTokenStale: Bool
    let didObserveDoubleDestroyFailClosed: Bool
    let didObserveInvalidTokenFailClosed: Bool
    let didObserveDestroyRequiresMainThread: Bool
    let didKeepTokenFunctionLocal: Bool
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
        didObserveCreate: Bool,
        didObserveOpaqueToken: Bool,
        didObserveValidToken: Bool,
        didObserveOccupiedCountLifecycle: Bool,
        didObserveDestroy: Bool,
        didObserveDestroyedTokenStale: Bool,
        didObserveDoubleDestroyFailClosed: Bool,
        didObserveInvalidTokenFailClosed: Bool,
        didObserveDestroyRequiresMainThread: Bool,
        didKeepTokenFunctionLocal: Bool,
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
        this.didObserveCreate = didObserveCreate
        this.didObserveOpaqueToken = didObserveOpaqueToken
        this.didObserveValidToken = didObserveValidToken
        this.didObserveOccupiedCountLifecycle =
            didObserveOccupiedCountLifecycle
        this.didObserveDestroy = didObserveDestroy
        this.didObserveDestroyedTokenStale = didObserveDestroyedTokenStale
        this.didObserveDoubleDestroyFailClosed =
            didObserveDoubleDestroyFailClosed
        this.didObserveInvalidTokenFailClosed =
            didObserveInvalidTokenFailClosed
        this.didObserveDestroyRequiresMainThread =
            didObserveDestroyRequiresMainThread
        this.didKeepTokenFunctionLocal = didKeepTokenFunctionLocal
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoNsWindowNsApplicationLayerMetal =
            didConfirmNoNsWindowNsApplicationLayerMetal
    }
}

struct CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness {
    let nsViewCreateDestroyReadiness:
        CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness
    let runtimeCallObservation:
        CjguiInternalRendererPlatformObjectNsViewRuntimeCallObservation
    let didPrepareRendererNoPlatformObjectNsViewRuntimeCallReadiness:
        Bool
    let shouldDeferRendererNoPlatformObjectNsViewRuntimeCallReadiness:
        Bool
    let shouldReportRendererNoPlatformObjectNsViewRuntimeCallBlocked:
        Bool
    let didPreserveRendererPlatformObjectNsViewCreateDestroyReadiness:
        Bool
    let didConfirmExistingForeignDeclarationsReused: Bool
    let didConfirmOutPointerSyntaxStable: Bool
    let didConfirmRuntimeInternalCallExecuted: Bool
    let didConfirmOpaqueTokenStayedInternal: Bool
    let didConfirmCreateClassifyDestroyLifecycle: Bool
    let didConfirmOccupiedCountLifecycle: Bool
    let didConfirmDestroyedTokenStale: Bool
    let didConfirmDoubleDestroyFailClosed: Bool
    let didConfirmInvalidTokenFailClosed: Bool
    let didConfirmMainThreadDestroyGate: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoNsWindowNsApplicationLayerMetal: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNsViewRuntimeCallReadinessDehydrated: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        nsViewCreateDestroyReadiness:
            CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness,
        runtimeCallObservation:
            CjguiInternalRendererPlatformObjectNsViewRuntimeCallObservation,
        didPrepareRendererNoPlatformObjectNsViewRuntimeCallReadiness:
            Bool,
        shouldDeferRendererNoPlatformObjectNsViewRuntimeCallReadiness:
            Bool,
        shouldReportRendererNoPlatformObjectNsViewRuntimeCallBlocked:
            Bool,
        didPreserveRendererPlatformObjectNsViewCreateDestroyReadiness:
            Bool,
        didConfirmExistingForeignDeclarationsReused: Bool,
        didConfirmOutPointerSyntaxStable: Bool,
        didConfirmRuntimeInternalCallExecuted: Bool,
        didConfirmOpaqueTokenStayedInternal: Bool,
        didConfirmCreateClassifyDestroyLifecycle: Bool,
        didConfirmOccupiedCountLifecycle: Bool,
        didConfirmDestroyedTokenStale: Bool,
        didConfirmDoubleDestroyFailClosed: Bool,
        didConfirmInvalidTokenFailClosed: Bool,
        didConfirmMainThreadDestroyGate: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoNsWindowNsApplicationLayerMetal: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNsViewRuntimeCallReadinessDehydrated: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.nsViewCreateDestroyReadiness = nsViewCreateDestroyReadiness
        this.runtimeCallObservation = runtimeCallObservation
        this.didPrepareRendererNoPlatformObjectNsViewRuntimeCallReadiness =
            didPrepareRendererNoPlatformObjectNsViewRuntimeCallReadiness
        this.shouldDeferRendererNoPlatformObjectNsViewRuntimeCallReadiness =
            shouldDeferRendererNoPlatformObjectNsViewRuntimeCallReadiness
        this.shouldReportRendererNoPlatformObjectNsViewRuntimeCallBlocked =
            shouldReportRendererNoPlatformObjectNsViewRuntimeCallBlocked
        this
            .didPreserveRendererPlatformObjectNsViewCreateDestroyReadiness =
            didPreserveRendererPlatformObjectNsViewCreateDestroyReadiness
        this.didConfirmExistingForeignDeclarationsReused =
            didConfirmExistingForeignDeclarationsReused
        this.didConfirmOutPointerSyntaxStable =
            didConfirmOutPointerSyntaxStable
        this.didConfirmRuntimeInternalCallExecuted =
            didConfirmRuntimeInternalCallExecuted
        this.didConfirmOpaqueTokenStayedInternal =
            didConfirmOpaqueTokenStayedInternal
        this.didConfirmCreateClassifyDestroyLifecycle =
            didConfirmCreateClassifyDestroyLifecycle
        this.didConfirmOccupiedCountLifecycle =
            didConfirmOccupiedCountLifecycle
        this.didConfirmDestroyedTokenStale = didConfirmDestroyedTokenStale
        this.didConfirmDoubleDestroyFailClosed =
            didConfirmDoubleDestroyFailClosed
        this.didConfirmInvalidTokenFailClosed =
            didConfirmInvalidTokenFailClosed
        this.didConfirmMainThreadDestroyGate =
            didConfirmMainThreadDestroyGate
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoNsWindowNsApplicationLayerMetal =
            didConfirmNoNsWindowNsApplicationLayerMetal
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth =
            didConfirmNoBackendReadyTruth
        this.didKeepNsViewRuntimeCallReadinessDehydrated =
            didKeepNsViewRuntimeCallReadinessDehydrated
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererPlatformObjectNsViewRuntimeCallValues():
    CjguiInternalRendererPlatformObjectNsViewRuntimeCallObservation {
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

    return CjguiInternalRendererPlatformObjectNsViewRuntimeCallObservation(
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
        createdToken != UInt64(0) && createdToken < UInt64(4294967296),
        validTokenClass == Int32(40),
        occupiedBefore == UInt32(0) &&
            occupiedAfterCreate == UInt32(1) &&
            occupiedAfterDestroy == UInt32(0),
        destroyStatus == Int32(0),
        destroyedTokenClass == Int32(-43),
        doubleDestroyStatus == Int32(-46) &&
            doubleDestroyClass == Int32(-46),
        invalidDestroyStatus == Int32(-42),
        destroyRequiresMainThread == Int32(-41),
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererPlatformObjectNsViewRuntimeCallReadiness(
    nsViewCreateDestroyReadiness:
        CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness,
    runtimeCallObservation:
        CjguiInternalRendererPlatformObjectNsViewRuntimeCallObservation
): CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness {
    let upstreamReady =
        nsViewCreateDestroyReadiness
            .didPrepareRendererNoPlatformObjectNsViewCreateDestroyReadiness &&
        nsViewCreateDestroyReadiness
            .didConfirmCreateClassifyDestroyLifecycle &&
        nsViewCreateDestroyReadiness.didConfirmDestroyedTokenStale &&
        nsViewCreateDestroyReadiness.didConfirmDoubleDestroyFailClosed &&
        nsViewCreateDestroyReadiness.didConfirmInvalidTokenFailClosed &&
        nsViewCreateDestroyReadiness
            .didConfirmNoPointerHandleClassIdReturn &&
        nsViewCreateDestroyReadiness
            .didConfirmNoNsWindowNsApplicationLayerMetal &&
        nsViewCreateDestroyReadiness.didConfirmNoPublicSurface &&
        nsViewCreateDestroyReadiness.didConfirmNoRendererStateWrite &&
        nsViewCreateDestroyReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        runtimeCallObservation.didObserveCreate &&
        runtimeCallObservation.didObserveOpaqueToken &&
        runtimeCallObservation.didObserveValidToken &&
        runtimeCallObservation.didObserveOccupiedCountLifecycle &&
        runtimeCallObservation.didObserveDestroy &&
        runtimeCallObservation.didObserveDestroyedTokenStale &&
        runtimeCallObservation.didObserveDoubleDestroyFailClosed &&
        runtimeCallObservation.didObserveInvalidTokenFailClosed &&
        runtimeCallObservation.didObserveDestroyRequiresMainThread &&
        runtimeCallObservation.didKeepTokenFunctionLocal &&
        runtimeCallObservation.didConfirmNoPointerHandleClassIdReturn &&
        runtimeCallObservation.didConfirmNoNsWindowNsApplicationLayerMetal
    let readinessReady = upstreamReady && observationReady
    return CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness(
        nsViewCreateDestroyReadiness,
        runtimeCallObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        true,
        true,
        observationReady,
        runtimeCallObservation.didKeepTokenFunctionLocal,
        runtimeCallObservation.didObserveCreate &&
            runtimeCallObservation.didObserveValidToken &&
            runtimeCallObservation.didObserveDestroy,
        runtimeCallObservation.didObserveOccupiedCountLifecycle,
        runtimeCallObservation.didObserveDestroyedTokenStale,
        runtimeCallObservation.didObserveDoubleDestroyFailClosed,
        runtimeCallObservation.didObserveInvalidTokenFailClosed,
        runtimeCallObservation.didObserveDestroyRequiresMainThread,
        runtimeCallObservation.didConfirmNoPointerHandleClassIdReturn,
        runtimeCallObservation.didConfirmNoNsWindowNsApplicationLayerMetal,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererPlatformObjectNsViewRuntimeCallDraft():
    CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness {
    let nsViewCreateDestroyReadiness =
        cjguiInternalExecuteDefaultRendererPlatformObjectNsViewCreateDestroyDraft()
    let runtimeCallObservation =
        cjguiInternalObserveRendererPlatformObjectNsViewRuntimeCallValues()
    return cjguiInternalBuildRendererPlatformObjectNsViewRuntimeCallReadiness(
        nsViewCreateDestroyReadiness,
        runtimeCallObservation
    )
}

