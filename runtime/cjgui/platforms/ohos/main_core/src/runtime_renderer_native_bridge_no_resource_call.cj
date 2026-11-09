// Owner: native bridge no-resource runtime FFI call owner。
// Truth: 只消费 CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness，
// 调用四个 no-resource C ABI，并把返回值脱水成 internal-only facts。
// Stop-line: 不扩 public API，不调用 resource callable，不创建 native object /
// handle / pointer，不改 runtime_state.cj，不把 no-resource call 解释成
// backend-ready truth。
// Same-shape Boundary Brake: 不得把本 owner 包成 public API、resource
// callable、native object、Metal/AppKit、backend-ready、receipt、record 或
// publication wrapper。
package cjgui

struct CjguiInternalRendererNativeBridgeNoResourceRuntimeCallIntent {
    let packageConfigLinkReadiness:
        CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness
    let didPrepareRendererNativeBridgeNoResourceRuntimeCallIntent: Bool
    let shouldDeferRendererNativeBridgeNoResourceRuntimeCallIntent: Bool
    let shouldReportRendererNativeBridgeNoResourceRuntimeCallIntentBlocked:
        Bool
    let didPreserveRendererNativeBridgePackageConfigLinkReadiness: Bool
    let didConfirmScriptManagedPackageLinkRoute: Bool
    let didAcknowledgeRuntimePackageConfigStillDeferred: Bool
    let didPrepareOnlyNoResourceCallableInvocation: Bool
    let didKeepRuntimeCallIntentInternalOnly: Bool
    let didAvoidBackendReadyTruthWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        packageConfigLinkReadiness:
            CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness,
        didPrepareRendererNativeBridgeNoResourceRuntimeCallIntent: Bool,
        shouldDeferRendererNativeBridgeNoResourceRuntimeCallIntent: Bool,
        shouldReportRendererNativeBridgeNoResourceRuntimeCallIntentBlocked:
            Bool,
        didPreserveRendererNativeBridgePackageConfigLinkReadiness: Bool,
        didConfirmScriptManagedPackageLinkRoute: Bool,
        didAcknowledgeRuntimePackageConfigStillDeferred: Bool,
        didPrepareOnlyNoResourceCallableInvocation: Bool,
        didKeepRuntimeCallIntentInternalOnly: Bool,
        didAvoidBackendReadyTruthWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.packageConfigLinkReadiness = packageConfigLinkReadiness
        this.didPrepareRendererNativeBridgeNoResourceRuntimeCallIntent =
            didPrepareRendererNativeBridgeNoResourceRuntimeCallIntent
        this.shouldDeferRendererNativeBridgeNoResourceRuntimeCallIntent =
            shouldDeferRendererNativeBridgeNoResourceRuntimeCallIntent
        this
            .shouldReportRendererNativeBridgeNoResourceRuntimeCallIntentBlocked =
            shouldReportRendererNativeBridgeNoResourceRuntimeCallIntentBlocked
        this.didPreserveRendererNativeBridgePackageConfigLinkReadiness =
            didPreserveRendererNativeBridgePackageConfigLinkReadiness
        this.didConfirmScriptManagedPackageLinkRoute =
            didConfirmScriptManagedPackageLinkRoute
        this.didAcknowledgeRuntimePackageConfigStillDeferred =
            didAcknowledgeRuntimePackageConfigStillDeferred
        this.didPrepareOnlyNoResourceCallableInvocation =
            didPrepareOnlyNoResourceCallableInvocation
        this.didKeepRuntimeCallIntentInternalOnly =
            didKeepRuntimeCallIntentInternalOnly
        this.didAvoidBackendReadyTruthWrapper =
            didAvoidBackendReadyTruthWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeBridgeNoResourceRuntimeCallObservation {
    let surfaceVersionValue: UInt32
    let surfaceCapabilitiesValue: UInt32
    let statusOkValue: UInt32
    let noResourceAdmissionValue: UInt32
    let didObserveSurfaceVersion: Bool
    let didObserveCapabilities: Bool
    let didObserveStatusOk: Bool
    let didObserveNoResourceAdmission: Bool
    let didKeepObservationSideEffectFree: Bool
    let didDenyNativePointerReturn: Bool
    let didAvoidResourceCallable: Bool

    init(
        surfaceVersionValue: UInt32,
        surfaceCapabilitiesValue: UInt32,
        statusOkValue: UInt32,
        noResourceAdmissionValue: UInt32,
        didObserveSurfaceVersion: Bool,
        didObserveCapabilities: Bool,
        didObserveStatusOk: Bool,
        didObserveNoResourceAdmission: Bool,
        didKeepObservationSideEffectFree: Bool,
        didDenyNativePointerReturn: Bool,
        didAvoidResourceCallable: Bool
    ) {
        this.surfaceVersionValue = surfaceVersionValue
        this.surfaceCapabilitiesValue = surfaceCapabilitiesValue
        this.statusOkValue = statusOkValue
        this.noResourceAdmissionValue = noResourceAdmissionValue
        this.didObserveSurfaceVersion = didObserveSurfaceVersion
        this.didObserveCapabilities = didObserveCapabilities
        this.didObserveStatusOk = didObserveStatusOk
        this.didObserveNoResourceAdmission = didObserveNoResourceAdmission
        this.didKeepObservationSideEffectFree =
            didKeepObservationSideEffectFree
        this.didDenyNativePointerReturn = didDenyNativePointerReturn
        this.didAvoidResourceCallable = didAvoidResourceCallable
    }
}

struct CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness {
    let runtimeCallIntent:
        CjguiInternalRendererNativeBridgeNoResourceRuntimeCallIntent
    let runtimeCallObservation:
        CjguiInternalRendererNativeBridgeNoResourceRuntimeCallObservation
    let didPrepareRendererNoNativeBridgeNoResourceRuntimeCallReadiness:
        Bool
    let shouldDeferRendererNoNativeBridgeNoResourceRuntimeCallReadiness:
        Bool
    let shouldReportRendererNoNativeBridgeNoResourceRuntimeCallReadinessBlocked:
        Bool
    let didPreserveRendererNativeBridgeNoResourceRuntimeCallIntent: Bool
    let didPreserveRendererNativeBridgeNoResourceRuntimeCallObservation:
        Bool
    let didConfirmSurfaceVersionObserved: Bool
    let didConfirmCapabilitiesObserved: Bool
    let didConfirmStatusOkObserved: Bool
    let didConfirmNoResourceAdmissionObserved: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoResourceCallable: Bool
    let didConfirmNoNativeObjectHandleOrPointer: Bool
    let didConfirmNoMetalOrAppKitUsage: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didFailClosedOnUnexpectedNoResourceResult: Bool
    let didKeepNoNativeBridgeNoResourceRuntimeCallReadinessDehydrated:
        Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        runtimeCallIntent:
            CjguiInternalRendererNativeBridgeNoResourceRuntimeCallIntent,
        runtimeCallObservation:
            CjguiInternalRendererNativeBridgeNoResourceRuntimeCallObservation,
        didPrepareRendererNoNativeBridgeNoResourceRuntimeCallReadiness:
            Bool,
        shouldDeferRendererNoNativeBridgeNoResourceRuntimeCallReadiness:
            Bool,
        shouldReportRendererNoNativeBridgeNoResourceRuntimeCallReadinessBlocked:
            Bool,
        didPreserveRendererNativeBridgeNoResourceRuntimeCallIntent: Bool,
        didPreserveRendererNativeBridgeNoResourceRuntimeCallObservation:
            Bool,
        didConfirmSurfaceVersionObserved: Bool,
        didConfirmCapabilitiesObserved: Bool,
        didConfirmStatusOkObserved: Bool,
        didConfirmNoResourceAdmissionObserved: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoResourceCallable: Bool,
        didConfirmNoNativeObjectHandleOrPointer: Bool,
        didConfirmNoMetalOrAppKitUsage: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didFailClosedOnUnexpectedNoResourceResult: Bool,
        didKeepNoNativeBridgeNoResourceRuntimeCallReadinessDehydrated:
            Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.runtimeCallIntent = runtimeCallIntent
        this.runtimeCallObservation = runtimeCallObservation
        this
            .didPrepareRendererNoNativeBridgeNoResourceRuntimeCallReadiness =
            didPrepareRendererNoNativeBridgeNoResourceRuntimeCallReadiness
        this.shouldDeferRendererNoNativeBridgeNoResourceRuntimeCallReadiness =
            shouldDeferRendererNoNativeBridgeNoResourceRuntimeCallReadiness
        this
            .shouldReportRendererNoNativeBridgeNoResourceRuntimeCallReadinessBlocked =
            shouldReportRendererNoNativeBridgeNoResourceRuntimeCallReadinessBlocked
        this.didPreserveRendererNativeBridgeNoResourceRuntimeCallIntent =
            didPreserveRendererNativeBridgeNoResourceRuntimeCallIntent
        this.didPreserveRendererNativeBridgeNoResourceRuntimeCallObservation =
            didPreserveRendererNativeBridgeNoResourceRuntimeCallObservation
        this.didConfirmSurfaceVersionObserved =
            didConfirmSurfaceVersionObserved
        this.didConfirmCapabilitiesObserved = didConfirmCapabilitiesObserved
        this.didConfirmStatusOkObserved = didConfirmStatusOkObserved
        this.didConfirmNoResourceAdmissionObserved =
            didConfirmNoResourceAdmissionObserved
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoResourceCallable = didConfirmNoResourceCallable
        this.didConfirmNoNativeObjectHandleOrPointer =
            didConfirmNoNativeObjectHandleOrPointer
        this.didConfirmNoMetalOrAppKitUsage =
            didConfirmNoMetalOrAppKitUsage
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didFailClosedOnUnexpectedNoResourceResult =
            didFailClosedOnUnexpectedNoResourceResult
        this
            .didKeepNoNativeBridgeNoResourceRuntimeCallReadinessDehydrated =
            didKeepNoNativeBridgeNoResourceRuntimeCallReadinessDehydrated
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererNativeBridgeNoResourceRuntimeCallValues():
    CjguiInternalRendererNativeBridgeNoResourceRuntimeCallObservation {
    let surfaceVersion = unsafe {
        cjgui_native_bridge_surface_version()
    }
    let surfaceCapabilities = unsafe {
        cjgui_native_bridge_surface_capabilities()
    }
    let statusOk = unsafe {
        cjgui_native_bridge_status_ok()
    }
    let noResourceAdmission = unsafe {
        cjgui_native_bridge_no_resource_admission()
    }
    return CjguiInternalRendererNativeBridgeNoResourceRuntimeCallObservation(
        surfaceVersion,
        surfaceCapabilities,
        statusOk,
        noResourceAdmission,
        surfaceVersion == UInt32(1),
        surfaceCapabilities != UInt32(0),
        statusOk == UInt32(0),
        noResourceAdmission == UInt32(0),
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererNativeBridgeNoResourceRuntimeCallReadiness(
    packageConfigLinkReadiness:
        CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness,
    runtimeCallObservation:
        CjguiInternalRendererNativeBridgeNoResourceRuntimeCallObservation
): CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness {
    let packageRouteReady =
        packageConfigLinkReadiness
            .didPrepareRendererNoNativeBridgePackageConfigLinkReadiness &&
        packageConfigLinkReadiness.didConfirmScriptManagedRouteStable &&
        packageConfigLinkReadiness.didConfirmPackageConfigLinkStillDeferred &&
        packageConfigLinkReadiness.didConfirmNoPublicSurface &&
        packageConfigLinkReadiness.didConfirmNoResourceCallable &&
        packageConfigLinkReadiness.didConfirmNoNativeObjectHandleOrPointer &&
        packageConfigLinkReadiness.didConfirmNoMetalOrAppKitUsage &&
        packageConfigLinkReadiness.didConfirmNoRendererStateWrite &&
        packageConfigLinkReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        runtimeCallObservation.didObserveSurfaceVersion &&
        runtimeCallObservation.didObserveCapabilities &&
        runtimeCallObservation.didObserveStatusOk &&
        runtimeCallObservation.didObserveNoResourceAdmission &&
        runtimeCallObservation.didKeepObservationSideEffectFree &&
        runtimeCallObservation.didDenyNativePointerReturn &&
        runtimeCallObservation.didAvoidResourceCallable
    let readinessReady = packageRouteReady && observationReady
    let intent = CjguiInternalRendererNativeBridgeNoResourceRuntimeCallIntent(
        packageConfigLinkReadiness,
        readinessReady,
        !readinessReady,
        !readinessReady,
        packageRouteReady,
        packageConfigLinkReadiness.didConfirmScriptManagedRouteStable,
        packageConfigLinkReadiness.didConfirmPackageConfigLinkStillDeferred,
        true,
        true,
        true,
        true
    )
    return CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness(
        intent,
        runtimeCallObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        readinessReady,
        observationReady,
        runtimeCallObservation.didObserveSurfaceVersion,
        runtimeCallObservation.didObserveCapabilities,
        runtimeCallObservation.didObserveStatusOk,
        runtimeCallObservation.didObserveNoResourceAdmission,
        true,
        true,
        true,
        true,
        true,
        true,
        !readinessReady,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererNativeBridgeNoResourceRuntimeCallDraft():
    CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness {
    let packageConfigLinkReadiness =
        cjguiInternalExecuteDefaultRendererNativeBridgePackageConfigLinkDraft()
    let runtimeCallObservation =
        cjguiInternalObserveRendererNativeBridgeNoResourceRuntimeCallValues()
    return cjguiInternalBuildRendererNativeBridgeNoResourceRuntimeCallReadiness(
        packageConfigLinkReadiness,
        runtimeCallObservation
    )
}
