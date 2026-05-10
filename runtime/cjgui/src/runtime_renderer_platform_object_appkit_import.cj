// Owner: platform object AppKit import no-object boundary owner。
// Truth: 只消费 CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness，
// 调用 AppKit import available / no-object admission / platform object still
// blocked C ABI，并把返回值脱水为 internal facts。
// Stop-line: 只证明 AppKit import 可编译与 no-object facts；不创建
// platform object，不返回 pointer / handle，不导入 Metal / QuartzCore，不写
// runtime_state.cj，不把 import 解释成 object exists 或 backend-ready truth。
// Same-shape Boundary Brake: 不得把本 owner 包成 platform object creation、
// AppKit object permission、native handle、Metal、public API、backend-ready、
// receipt、record 或 publication wrapper。
package cjgui

foreign func cjgui_native_bridge_appkit_import_available(): Int32
foreign func cjgui_native_bridge_appkit_no_object_admission(): Int32
foreign func cjgui_native_bridge_platform_object_create_still_blocked(): Int32

struct CjguiInternalRendererPlatformObjectAppKitImportObservation {
    let appkitImportAvailableValue: Int32
    let appkitNoObjectAdmissionValue: Int32
    let platformObjectCreateStillBlockedValue: Int32
    let didObserveAppKitImportAvailable: Bool
    let didObserveAppKitNoObjectAdmission: Bool
    let didObservePlatformObjectCreationStillBlocked: Bool
    let didConfirmNoPointerOrHandleReturn: Bool
    let didConfirmNoMetalQuartzCoreUsage: Bool
    let didConfirmNoPlatformObjectCreation: Bool

    init(
        appkitImportAvailableValue: Int32,
        appkitNoObjectAdmissionValue: Int32,
        platformObjectCreateStillBlockedValue: Int32,
        didObserveAppKitImportAvailable: Bool,
        didObserveAppKitNoObjectAdmission: Bool,
        didObservePlatformObjectCreationStillBlocked: Bool,
        didConfirmNoPointerOrHandleReturn: Bool,
        didConfirmNoMetalQuartzCoreUsage: Bool,
        didConfirmNoPlatformObjectCreation: Bool
    ) {
        this.appkitImportAvailableValue = appkitImportAvailableValue
        this.appkitNoObjectAdmissionValue = appkitNoObjectAdmissionValue
        this.platformObjectCreateStillBlockedValue =
            platformObjectCreateStillBlockedValue
        this.didObserveAppKitImportAvailable =
            didObserveAppKitImportAvailable
        this.didObserveAppKitNoObjectAdmission =
            didObserveAppKitNoObjectAdmission
        this.didObservePlatformObjectCreationStillBlocked =
            didObservePlatformObjectCreationStillBlocked
        this.didConfirmNoPointerOrHandleReturn =
            didConfirmNoPointerOrHandleReturn
        this.didConfirmNoMetalQuartzCoreUsage =
            didConfirmNoMetalQuartzCoreUsage
        this.didConfirmNoPlatformObjectCreation =
            didConfirmNoPlatformObjectCreation
    }
}

struct CjguiInternalRendererNoPlatformObjectAppKitImportReadiness {
    let teardownAdmissionCallReadiness:
        CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness
    let appkitImportObservation:
        CjguiInternalRendererPlatformObjectAppKitImportObservation
    let didPrepareRendererNoPlatformObjectAppKitImportReadiness: Bool
    let shouldDeferRendererNoPlatformObjectAppKitImportReadiness: Bool
    let shouldReportRendererNoPlatformObjectAppKitImportReadinessBlocked:
        Bool
    let didPreserveRendererNativeBridgeTeardownAdmissionCallReadiness: Bool
    let didConfirmAppKitImportBoundary: Bool
    let didConfirmNoObjectAppKitAdmission: Bool
    let didConfirmPlatformObjectCreationStillBlocked: Bool
    let didConfirmMainThreadPrerequisite: Bool
    let didConfirmTokenTeardownPrerequisites: Bool
    let didConfirmNoMetalQuartzCoreUsage: Bool
    let didConfirmNoNativeObjectHandleOrPointer: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoPlatformObjectAppKitImportReadinessDehydrated: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        teardownAdmissionCallReadiness:
            CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness,
        appkitImportObservation:
            CjguiInternalRendererPlatformObjectAppKitImportObservation,
        didPrepareRendererNoPlatformObjectAppKitImportReadiness: Bool,
        shouldDeferRendererNoPlatformObjectAppKitImportReadiness: Bool,
        shouldReportRendererNoPlatformObjectAppKitImportReadinessBlocked:
            Bool,
        didPreserveRendererNativeBridgeTeardownAdmissionCallReadiness: Bool,
        didConfirmAppKitImportBoundary: Bool,
        didConfirmNoObjectAppKitAdmission: Bool,
        didConfirmPlatformObjectCreationStillBlocked: Bool,
        didConfirmMainThreadPrerequisite: Bool,
        didConfirmTokenTeardownPrerequisites: Bool,
        didConfirmNoMetalQuartzCoreUsage: Bool,
        didConfirmNoNativeObjectHandleOrPointer: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoPlatformObjectAppKitImportReadinessDehydrated: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.teardownAdmissionCallReadiness =
            teardownAdmissionCallReadiness
        this.appkitImportObservation = appkitImportObservation
        this.didPrepareRendererNoPlatformObjectAppKitImportReadiness =
            didPrepareRendererNoPlatformObjectAppKitImportReadiness
        this.shouldDeferRendererNoPlatformObjectAppKitImportReadiness =
            shouldDeferRendererNoPlatformObjectAppKitImportReadiness
        this
            .shouldReportRendererNoPlatformObjectAppKitImportReadinessBlocked =
            shouldReportRendererNoPlatformObjectAppKitImportReadinessBlocked
        this.didPreserveRendererNativeBridgeTeardownAdmissionCallReadiness =
            didPreserveRendererNativeBridgeTeardownAdmissionCallReadiness
        this.didConfirmAppKitImportBoundary =
            didConfirmAppKitImportBoundary
        this.didConfirmNoObjectAppKitAdmission =
            didConfirmNoObjectAppKitAdmission
        this.didConfirmPlatformObjectCreationStillBlocked =
            didConfirmPlatformObjectCreationStillBlocked
        this.didConfirmMainThreadPrerequisite =
            didConfirmMainThreadPrerequisite
        this.didConfirmTokenTeardownPrerequisites =
            didConfirmTokenTeardownPrerequisites
        this.didConfirmNoMetalQuartzCoreUsage =
            didConfirmNoMetalQuartzCoreUsage
        this.didConfirmNoNativeObjectHandleOrPointer =
            didConfirmNoNativeObjectHandleOrPointer
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNoPlatformObjectAppKitImportReadinessDehydrated =
            didKeepNoPlatformObjectAppKitImportReadinessDehydrated
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererPlatformObjectAppKitImportValues():
    CjguiInternalRendererPlatformObjectAppKitImportObservation {
    let appkitImportAvailable = unsafe {
        cjgui_native_bridge_appkit_import_available()
    }
    let appkitNoObjectAdmission = unsafe {
        cjgui_native_bridge_appkit_no_object_admission()
    }
    let platformObjectCreateStillBlocked = unsafe {
        cjgui_native_bridge_platform_object_create_still_blocked()
    }
    return CjguiInternalRendererPlatformObjectAppKitImportObservation(
        appkitImportAvailable,
        appkitNoObjectAdmission,
        platformObjectCreateStillBlocked,
        appkitImportAvailable == Int32(20),
        appkitNoObjectAdmission == Int32(21),
        platformObjectCreateStillBlocked == Int32(-20),
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererPlatformObjectAppKitImportReadiness(
    teardownAdmissionCallReadiness:
        CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness,
    appkitImportObservation:
        CjguiInternalRendererPlatformObjectAppKitImportObservation
): CjguiInternalRendererNoPlatformObjectAppKitImportReadiness {
    let upstreamReady =
        teardownAdmissionCallReadiness
            .didPrepareRendererNoNativeBridgeTeardownAdmissionCallReadiness &&
        teardownAdmissionCallReadiness.didConfirmDestroyNotSupported &&
        teardownAdmissionCallReadiness
            .didConfirmRevokeBeforeDestroyRequired &&
        teardownAdmissionCallReadiness.didConfirmInvalidTokenFailClosed &&
        teardownAdmissionCallReadiness.didConfirmDoubleDestroyDenied &&
        teardownAdmissionCallReadiness.didConfirmDanglingTokenDenied &&
        teardownAdmissionCallReadiness.didConfirmNoActualDestroy &&
        teardownAdmissionCallReadiness.didConfirmNoRetainRelease &&
        teardownAdmissionCallReadiness.didConfirmNoResourceBinding &&
        teardownAdmissionCallReadiness.didConfirmNoPublicSurface &&
        teardownAdmissionCallReadiness
            .didConfirmNoNativeObjectHandleOrPointer &&
        teardownAdmissionCallReadiness.didConfirmNoRendererStateWrite &&
        teardownAdmissionCallReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        appkitImportObservation.didObserveAppKitImportAvailable &&
        appkitImportObservation.didObserveAppKitNoObjectAdmission &&
        appkitImportObservation
            .didObservePlatformObjectCreationStillBlocked &&
        appkitImportObservation.didConfirmNoPointerOrHandleReturn &&
        appkitImportObservation.didConfirmNoMetalQuartzCoreUsage &&
        appkitImportObservation.didConfirmNoPlatformObjectCreation
    let readinessReady = upstreamReady && observationReady
    return CjguiInternalRendererNoPlatformObjectAppKitImportReadiness(
        teardownAdmissionCallReadiness,
        appkitImportObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        appkitImportObservation.didObserveAppKitImportAvailable,
        appkitImportObservation.didObserveAppKitNoObjectAdmission,
        appkitImportObservation.didObservePlatformObjectCreationStillBlocked,
        upstreamReady,
        upstreamReady,
        appkitImportObservation.didConfirmNoMetalQuartzCoreUsage,
        appkitImportObservation.didConfirmNoPointerOrHandleReturn,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererPlatformObjectAppKitImportDraft():
    CjguiInternalRendererNoPlatformObjectAppKitImportReadiness {
    let teardownAdmissionCallReadiness =
        cjguiInternalExecuteDefaultRendererNativeBridgeTeardownAdmissionCallDraft()
    let appkitImportObservation =
        cjguiInternalObserveRendererPlatformObjectAppKitImportValues()
    return cjguiInternalBuildRendererPlatformObjectAppKitImportReadiness(
        teardownAdmissionCallReadiness,
        appkitImportObservation
    )
}
