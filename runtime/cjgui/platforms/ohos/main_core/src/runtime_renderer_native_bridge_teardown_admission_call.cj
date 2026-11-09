// Owner: native bridge teardown admission no-resource callable owner。
// Truth: 只消费 CjguiInternalRendererNoPlatformObjectNativeCallableReadiness，
// 调用 teardown admission / not-supported / revoke-before-destroy-required /
// double-destroy classification C ABI，并把返回值脱水为 internal facts。
// Stop-line: 不执行真实 destroy，不调用 retain / release，不绑定 native
// object，不返回 pointer / handle，不写 runtime_state.cj，不把 admission
// 解释成 resource destroyed 或 backend-ready truth。
// Same-shape Boundary Brake: 不得把本 owner 包成 destroy permission、
// native object permission、resource creation、native handle、Metal/AppKit、
// public API、backend-ready、receipt、record 或 publication wrapper。
package cjgui

foreign func cjgui_native_bridge_teardown_admission(token: UInt64): Int32
foreign func cjgui_native_bridge_destroy_not_supported(): Int32
foreign func cjgui_native_bridge_revoke_before_destroy_required(): Int32
foreign func cjgui_native_bridge_double_destroy_classify(
    token: UInt64
): Int32

struct CjguiInternalRendererNativeBridgeTeardownAdmissionCallIntent {
    let platformObjectNativeCallableReadiness:
        CjguiInternalRendererNoPlatformObjectNativeCallableReadiness
    let didPrepareRendererNativeBridgeTeardownAdmissionCallIntent: Bool
    let shouldDeferRendererNativeBridgeTeardownAdmissionCallIntent: Bool
    let shouldReportRendererNativeBridgeTeardownAdmissionCallIntentBlocked:
        Bool
    let didPreserveRendererPlatformObjectNativeCallableReadiness: Bool
    let didConfirmNoResourceTeardownAdmissionIntent: Bool
    let didConfirmRevokeBeforeDestroyRequiredIntent: Bool
    let didConfirmDestroyNotSupportedIntent: Bool
    let didKeepTeardownAdmissionCallInternalOnly: Bool
    let didAvoidDestroyPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        platformObjectNativeCallableReadiness:
            CjguiInternalRendererNoPlatformObjectNativeCallableReadiness,
        didPrepareRendererNativeBridgeTeardownAdmissionCallIntent: Bool,
        shouldDeferRendererNativeBridgeTeardownAdmissionCallIntent: Bool,
        shouldReportRendererNativeBridgeTeardownAdmissionCallIntentBlocked:
            Bool,
        didPreserveRendererPlatformObjectNativeCallableReadiness: Bool,
        didConfirmNoResourceTeardownAdmissionIntent: Bool,
        didConfirmRevokeBeforeDestroyRequiredIntent: Bool,
        didConfirmDestroyNotSupportedIntent: Bool,
        didKeepTeardownAdmissionCallInternalOnly: Bool,
        didAvoidDestroyPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.platformObjectNativeCallableReadiness =
            platformObjectNativeCallableReadiness
        this.didPrepareRendererNativeBridgeTeardownAdmissionCallIntent =
            didPrepareRendererNativeBridgeTeardownAdmissionCallIntent
        this.shouldDeferRendererNativeBridgeTeardownAdmissionCallIntent =
            shouldDeferRendererNativeBridgeTeardownAdmissionCallIntent
        this
            .shouldReportRendererNativeBridgeTeardownAdmissionCallIntentBlocked =
            shouldReportRendererNativeBridgeTeardownAdmissionCallIntentBlocked
        this.didPreserveRendererPlatformObjectNativeCallableReadiness =
            didPreserveRendererPlatformObjectNativeCallableReadiness
        this.didConfirmNoResourceTeardownAdmissionIntent =
            didConfirmNoResourceTeardownAdmissionIntent
        this.didConfirmRevokeBeforeDestroyRequiredIntent =
            didConfirmRevokeBeforeDestroyRequiredIntent
        this.didConfirmDestroyNotSupportedIntent =
            didConfirmDestroyNotSupportedIntent
        this.didKeepTeardownAdmissionCallInternalOnly =
            didKeepTeardownAdmissionCallInternalOnly
        this.didAvoidDestroyPermissionWrapper =
            didAvoidDestroyPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeBridgeTeardownAdmissionObservation {
    let invalidTokenAdmissionValue: Int32
    let destroyNotSupportedValue: Int32
    let revokeBeforeDestroyRequiredValue: Int32
    let validTokenAdmissionValue: Int32
    let revokeStatusValue: Int32
    let doubleDestroyClassificationValue: Int32
    let danglingTokenAdmissionValue: Int32
    let didObserveDestroyNotSupported: Bool
    let didObserveRevokeBeforeDestroyRequired: Bool
    let didObserveInvalidTokenFailClosed: Bool
    let didObserveValidTokenAdmissionDenied: Bool
    let didObserveRevokeBeforeClassification: Bool
    let didObserveDoubleDestroyDenied: Bool
    let didObserveDanglingTokenDenied: Bool
    let didKeepObservationSideEffectBounded: Bool
    let didDenyNativePointerReturn: Bool
    let didAvoidResourceCallable: Bool

    init(
        invalidTokenAdmissionValue: Int32,
        destroyNotSupportedValue: Int32,
        revokeBeforeDestroyRequiredValue: Int32,
        validTokenAdmissionValue: Int32,
        revokeStatusValue: Int32,
        doubleDestroyClassificationValue: Int32,
        danglingTokenAdmissionValue: Int32,
        didObserveDestroyNotSupported: Bool,
        didObserveRevokeBeforeDestroyRequired: Bool,
        didObserveInvalidTokenFailClosed: Bool,
        didObserveValidTokenAdmissionDenied: Bool,
        didObserveRevokeBeforeClassification: Bool,
        didObserveDoubleDestroyDenied: Bool,
        didObserveDanglingTokenDenied: Bool,
        didKeepObservationSideEffectBounded: Bool,
        didDenyNativePointerReturn: Bool,
        didAvoidResourceCallable: Bool
    ) {
        this.invalidTokenAdmissionValue = invalidTokenAdmissionValue
        this.destroyNotSupportedValue = destroyNotSupportedValue
        this.revokeBeforeDestroyRequiredValue =
            revokeBeforeDestroyRequiredValue
        this.validTokenAdmissionValue = validTokenAdmissionValue
        this.revokeStatusValue = revokeStatusValue
        this.doubleDestroyClassificationValue =
            doubleDestroyClassificationValue
        this.danglingTokenAdmissionValue = danglingTokenAdmissionValue
        this.didObserveDestroyNotSupported =
            didObserveDestroyNotSupported
        this.didObserveRevokeBeforeDestroyRequired =
            didObserveRevokeBeforeDestroyRequired
        this.didObserveInvalidTokenFailClosed =
            didObserveInvalidTokenFailClosed
        this.didObserveValidTokenAdmissionDenied =
            didObserveValidTokenAdmissionDenied
        this.didObserveRevokeBeforeClassification =
            didObserveRevokeBeforeClassification
        this.didObserveDoubleDestroyDenied =
            didObserveDoubleDestroyDenied
        this.didObserveDanglingTokenDenied =
            didObserveDanglingTokenDenied
        this.didKeepObservationSideEffectBounded =
            didKeepObservationSideEffectBounded
        this.didDenyNativePointerReturn = didDenyNativePointerReturn
        this.didAvoidResourceCallable = didAvoidResourceCallable
    }
}

struct CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness {
    let teardownAdmissionCallIntent:
        CjguiInternalRendererNativeBridgeTeardownAdmissionCallIntent
    let teardownAdmissionObservation:
        CjguiInternalRendererNativeBridgeTeardownAdmissionObservation
    let didPrepareRendererNoNativeBridgeTeardownAdmissionCallReadiness:
        Bool
    let shouldDeferRendererNoNativeBridgeTeardownAdmissionCallReadiness:
        Bool
    let shouldReportRendererNoNativeBridgeTeardownAdmissionCallReadinessBlocked:
        Bool
    let didPreserveRendererNativeBridgeTeardownAdmissionCallIntent: Bool
    let didPreserveRendererNativeBridgeTeardownAdmissionObservation: Bool
    let didConfirmDestroyNotSupported: Bool
    let didConfirmRevokeBeforeDestroyRequired: Bool
    let didConfirmInvalidTokenFailClosed: Bool
    let didConfirmValidTokenAdmissionDenied: Bool
    let didConfirmDoubleDestroyDenied: Bool
    let didConfirmDanglingTokenDenied: Bool
    let didConfirmNoActualDestroy: Bool
    let didConfirmNoRetainRelease: Bool
    let didConfirmNoResourceBinding: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoResourceCallable: Bool
    let didConfirmNoNativeObjectHandleOrPointer: Bool
    let didConfirmNoMetalOrAppKitUsage: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoNativeBridgeTeardownAdmissionCallReadinessDehydrated:
        Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        teardownAdmissionCallIntent:
            CjguiInternalRendererNativeBridgeTeardownAdmissionCallIntent,
        teardownAdmissionObservation:
            CjguiInternalRendererNativeBridgeTeardownAdmissionObservation,
        didPrepareRendererNoNativeBridgeTeardownAdmissionCallReadiness:
            Bool,
        shouldDeferRendererNoNativeBridgeTeardownAdmissionCallReadiness:
            Bool,
        shouldReportRendererNoNativeBridgeTeardownAdmissionCallReadinessBlocked:
            Bool,
        didPreserveRendererNativeBridgeTeardownAdmissionCallIntent: Bool,
        didPreserveRendererNativeBridgeTeardownAdmissionObservation: Bool,
        didConfirmDestroyNotSupported: Bool,
        didConfirmRevokeBeforeDestroyRequired: Bool,
        didConfirmInvalidTokenFailClosed: Bool,
        didConfirmValidTokenAdmissionDenied: Bool,
        didConfirmDoubleDestroyDenied: Bool,
        didConfirmDanglingTokenDenied: Bool,
        didConfirmNoActualDestroy: Bool,
        didConfirmNoRetainRelease: Bool,
        didConfirmNoResourceBinding: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoResourceCallable: Bool,
        didConfirmNoNativeObjectHandleOrPointer: Bool,
        didConfirmNoMetalOrAppKitUsage: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoNativeBridgeTeardownAdmissionCallReadinessDehydrated:
            Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.teardownAdmissionCallIntent = teardownAdmissionCallIntent
        this.teardownAdmissionObservation = teardownAdmissionObservation
        this.didPrepareRendererNoNativeBridgeTeardownAdmissionCallReadiness =
            didPrepareRendererNoNativeBridgeTeardownAdmissionCallReadiness
        this.shouldDeferRendererNoNativeBridgeTeardownAdmissionCallReadiness =
            shouldDeferRendererNoNativeBridgeTeardownAdmissionCallReadiness
        this
            .shouldReportRendererNoNativeBridgeTeardownAdmissionCallReadinessBlocked =
            shouldReportRendererNoNativeBridgeTeardownAdmissionCallReadinessBlocked
        this.didPreserveRendererNativeBridgeTeardownAdmissionCallIntent =
            didPreserveRendererNativeBridgeTeardownAdmissionCallIntent
        this.didPreserveRendererNativeBridgeTeardownAdmissionObservation =
            didPreserveRendererNativeBridgeTeardownAdmissionObservation
        this.didConfirmDestroyNotSupported =
            didConfirmDestroyNotSupported
        this.didConfirmRevokeBeforeDestroyRequired =
            didConfirmRevokeBeforeDestroyRequired
        this.didConfirmInvalidTokenFailClosed =
            didConfirmInvalidTokenFailClosed
        this.didConfirmValidTokenAdmissionDenied =
            didConfirmValidTokenAdmissionDenied
        this.didConfirmDoubleDestroyDenied =
            didConfirmDoubleDestroyDenied
        this.didConfirmDanglingTokenDenied =
            didConfirmDanglingTokenDenied
        this.didConfirmNoActualDestroy = didConfirmNoActualDestroy
        this.didConfirmNoRetainRelease = didConfirmNoRetainRelease
        this.didConfirmNoResourceBinding = didConfirmNoResourceBinding
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoResourceCallable = didConfirmNoResourceCallable
        this.didConfirmNoNativeObjectHandleOrPointer =
            didConfirmNoNativeObjectHandleOrPointer
        this.didConfirmNoMetalOrAppKitUsage =
            didConfirmNoMetalOrAppKitUsage
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this
            .didKeepNoNativeBridgeTeardownAdmissionCallReadinessDehydrated =
            didKeepNoNativeBridgeTeardownAdmissionCallReadinessDehydrated
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererNativeBridgeTeardownAdmissionValues():
    CjguiInternalRendererNativeBridgeTeardownAdmissionObservation {
    let invalidToken = unsafe {
        cjgui_native_bridge_token_invalid()
    }
    let invalidTokenAdmission = unsafe {
        cjgui_native_bridge_teardown_admission(invalidToken)
    }
    let destroyNotSupported = unsafe {
        cjgui_native_bridge_destroy_not_supported()
    }
    let revokeBeforeDestroyRequired = unsafe {
        cjgui_native_bridge_revoke_before_destroy_required()
    }
    let issuedToken = unsafe {
        cjgui_native_bridge_token_issue()
    }
    let validTokenAdmission = unsafe {
        cjgui_native_bridge_teardown_admission(issuedToken)
    }
    let revokeStatus = unsafe {
        cjgui_native_bridge_token_revoke(issuedToken)
    }
    let doubleDestroyClassification = unsafe {
        cjgui_native_bridge_double_destroy_classify(issuedToken)
    }
    let danglingTokenAdmission = unsafe {
        cjgui_native_bridge_teardown_admission(issuedToken)
    }
    return CjguiInternalRendererNativeBridgeTeardownAdmissionObservation(
        invalidTokenAdmission,
        destroyNotSupported,
        revokeBeforeDestroyRequired,
        validTokenAdmission,
        revokeStatus,
        doubleDestroyClassification,
        danglingTokenAdmission,
        destroyNotSupported == Int32(-10),
        revokeBeforeDestroyRequired == Int32(-11),
        invalidTokenAdmission == Int32(-13),
        issuedToken != UInt64(0) && validTokenAdmission == Int32(-11),
        revokeStatus == Int32(0),
        doubleDestroyClassification == Int32(-12),
        danglingTokenAdmission == Int32(-13),
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererNativeBridgeTeardownAdmissionCallReadiness(
    platformObjectNativeCallableReadiness:
        CjguiInternalRendererNoPlatformObjectNativeCallableReadiness,
    teardownAdmissionObservation:
        CjguiInternalRendererNativeBridgeTeardownAdmissionObservation
): CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness {
    let upstreamReady =
        platformObjectNativeCallableReadiness
            .didPrepareRendererNoPlatformObjectNativeCallableReadiness &&
        platformObjectNativeCallableReadiness
            .didConfirmNoObjectAdmissionPolicy &&
        platformObjectNativeCallableReadiness
            .didConfirmMainThreadPrerequisite &&
        platformObjectNativeCallableReadiness
            .didConfirmTokenIssueRevokePrerequisite &&
        platformObjectNativeCallableReadiness
            .didConfirmTeardownPolicyPrerequisite &&
        platformObjectNativeCallableReadiness
            .didConfirmNoTokenReturnBeforeObjectPolicy &&
        platformObjectNativeCallableReadiness
            .didConfirmNoPlatformObjectCreation &&
        platformObjectNativeCallableReadiness.didConfirmNoPublicSurface &&
        platformObjectNativeCallableReadiness.didConfirmNoResourceCallable &&
        platformObjectNativeCallableReadiness
            .didConfirmNoNativeObjectHandleOrPointer &&
        platformObjectNativeCallableReadiness
            .didConfirmNoCocoaAppKitMetalQuartzCoreUsage &&
        platformObjectNativeCallableReadiness
            .didConfirmNoRendererStateWrite &&
        platformObjectNativeCallableReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        teardownAdmissionObservation.didObserveDestroyNotSupported &&
        teardownAdmissionObservation.didObserveRevokeBeforeDestroyRequired &&
        teardownAdmissionObservation.didObserveInvalidTokenFailClosed &&
        teardownAdmissionObservation.didObserveValidTokenAdmissionDenied &&
        teardownAdmissionObservation.didObserveRevokeBeforeClassification &&
        teardownAdmissionObservation.didObserveDoubleDestroyDenied &&
        teardownAdmissionObservation.didObserveDanglingTokenDenied &&
        teardownAdmissionObservation.didKeepObservationSideEffectBounded &&
        teardownAdmissionObservation.didDenyNativePointerReturn &&
        teardownAdmissionObservation.didAvoidResourceCallable
    let readinessReady = upstreamReady && observationReady
    let intent =
        CjguiInternalRendererNativeBridgeTeardownAdmissionCallIntent(
            platformObjectNativeCallableReadiness,
            readinessReady,
            !readinessReady,
            !readinessReady,
            upstreamReady,
            true,
            true,
            true,
            true,
            true,
            true
        )
    return CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness(
        intent,
        teardownAdmissionObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        readinessReady,
        observationReady,
        teardownAdmissionObservation.didObserveDestroyNotSupported,
        teardownAdmissionObservation.didObserveRevokeBeforeDestroyRequired,
        teardownAdmissionObservation.didObserveInvalidTokenFailClosed,
        teardownAdmissionObservation.didObserveValidTokenAdmissionDenied,
        teardownAdmissionObservation.didObserveDoubleDestroyDenied,
        teardownAdmissionObservation.didObserveDanglingTokenDenied,
        true,
        true,
        true,
        true,
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

func cjguiInternalExecuteDefaultRendererNativeBridgeTeardownAdmissionCallDraft():
    CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness {
    let platformObjectNativeCallableReadiness =
        cjguiInternalExecuteDefaultRendererPlatformObjectNativeCallableDraft()
    let teardownAdmissionObservation =
        cjguiInternalObserveRendererNativeBridgeTeardownAdmissionValues()
    return cjguiInternalBuildRendererNativeBridgeTeardownAdmissionCallReadiness(
        platformObjectNativeCallableReadiness,
        teardownAdmissionObservation
    )
}
