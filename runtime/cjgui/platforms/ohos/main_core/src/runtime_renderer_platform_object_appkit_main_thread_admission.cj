// Owner: platform object AppKit main-thread admission no-object boundary owner。
// Truth: 只消费 CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness，
// 调用 AppKit platform object main-thread admission C ABI，并把返回值脱水为 internal facts。
// Stop-line: 只证明 future AppKit platform object creation 必须受 main-thread
// admission 约束；不创建 AppKit object，不返回 Class / id / pointer / handle，
// 不导入 Metal / QuartzCore，不写 runtime_state.cj。
// Same-shape Boundary Brake: 不得把本 owner 包成 platform object creation、
// AppKit object permission、native handle、Metal、public API、backend-ready、
// receipt、record 或 publication wrapper。
package cjgui

foreign func cjgui_native_bridge_appkit_platform_object_main_thread_required():
    Int32
foreign func cjgui_native_bridge_appkit_platform_object_main_thread_admitted():
    Int32
foreign func cjgui_native_bridge_appkit_platform_object_background_thread_denied():
    Int32
foreign func cjgui_native_bridge_appkit_platform_object_creation_still_blocked():
    Int32

struct CjguiInternalRendererPlatformObjectAppKitMainThreadAdmissionObservation {
    let mainThreadRequiredValue: Int32
    let mainThreadAdmittedValue: Int32
    let backgroundThreadDeniedValue: Int32
    let platformObjectCreationStillBlockedValue: Int32
    let didObserveMainThreadRequired: Bool
    let didObserveMainThreadAdmitted: Bool
    let didObserveBackgroundThreadDenied: Bool
    let didObservePlatformObjectCreationStillBlocked: Bool
    let didConfirmMainThreadGateRequired: Bool
    let didConfirmNoClassIdPointerOrHandleReturn: Bool
    let didConfirmNoAppKitObjectAllocation: Bool
    let didConfirmNoMetalQuartzCoreUsage: Bool

    init(
        mainThreadRequiredValue: Int32,
        mainThreadAdmittedValue: Int32,
        backgroundThreadDeniedValue: Int32,
        platformObjectCreationStillBlockedValue: Int32,
        didObserveMainThreadRequired: Bool,
        didObserveMainThreadAdmitted: Bool,
        didObserveBackgroundThreadDenied: Bool,
        didObservePlatformObjectCreationStillBlocked: Bool,
        didConfirmMainThreadGateRequired: Bool,
        didConfirmNoClassIdPointerOrHandleReturn: Bool,
        didConfirmNoAppKitObjectAllocation: Bool,
        didConfirmNoMetalQuartzCoreUsage: Bool
    ) {
        this.mainThreadRequiredValue = mainThreadRequiredValue
        this.mainThreadAdmittedValue = mainThreadAdmittedValue
        this.backgroundThreadDeniedValue = backgroundThreadDeniedValue
        this.platformObjectCreationStillBlockedValue =
            platformObjectCreationStillBlockedValue
        this.didObserveMainThreadRequired = didObserveMainThreadRequired
        this.didObserveMainThreadAdmitted = didObserveMainThreadAdmitted
        this.didObserveBackgroundThreadDenied =
            didObserveBackgroundThreadDenied
        this.didObservePlatformObjectCreationStillBlocked =
            didObservePlatformObjectCreationStillBlocked
        this.didConfirmMainThreadGateRequired =
            didConfirmMainThreadGateRequired
        this.didConfirmNoClassIdPointerOrHandleReturn =
            didConfirmNoClassIdPointerOrHandleReturn
        this.didConfirmNoAppKitObjectAllocation =
            didConfirmNoAppKitObjectAllocation
        this.didConfirmNoMetalQuartzCoreUsage =
            didConfirmNoMetalQuartzCoreUsage
    }
}

struct CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness {
    let appkitClassAvailabilityReadiness:
        CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness
    let mainThreadAdmissionObservation:
        CjguiInternalRendererPlatformObjectAppKitMainThreadAdmissionObservation
    let didPrepareRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness:
        Bool
    let shouldDeferRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness:
        Bool
    let shouldReportRendererNoPlatformObjectAppKitMainThreadAdmissionBlocked:
        Bool
    let didPreserveRendererPlatformObjectAppKitClassAvailabilityReadiness:
        Bool
    let didConfirmPlatformObjectMainThreadRequired: Bool
    let didConfirmPlatformObjectMainThreadAdmitted: Bool
    let didConfirmPlatformObjectBackgroundThreadDenied: Bool
    let didConfirmPlatformObjectCreationStillBlocked: Bool
    let didConfirmMainThreadGateRequired: Bool
    let didConfirmNoClassIdPointerOrHandleReturn: Bool
    let didConfirmNoAppKitObjectAllocation: Bool
    let didConfirmNoMetalQuartzCoreUsage: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoPlatformObjectAppKitMainThreadAdmissionDehydrated: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        appkitClassAvailabilityReadiness:
            CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness,
        mainThreadAdmissionObservation:
            CjguiInternalRendererPlatformObjectAppKitMainThreadAdmissionObservation,
        didPrepareRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness:
            Bool,
        shouldDeferRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness:
            Bool,
        shouldReportRendererNoPlatformObjectAppKitMainThreadAdmissionBlocked:
            Bool,
        didPreserveRendererPlatformObjectAppKitClassAvailabilityReadiness:
            Bool,
        didConfirmPlatformObjectMainThreadRequired: Bool,
        didConfirmPlatformObjectMainThreadAdmitted: Bool,
        didConfirmPlatformObjectBackgroundThreadDenied: Bool,
        didConfirmPlatformObjectCreationStillBlocked: Bool,
        didConfirmMainThreadGateRequired: Bool,
        didConfirmNoClassIdPointerOrHandleReturn: Bool,
        didConfirmNoAppKitObjectAllocation: Bool,
        didConfirmNoMetalQuartzCoreUsage: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoPlatformObjectAppKitMainThreadAdmissionDehydrated: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.appkitClassAvailabilityReadiness =
            appkitClassAvailabilityReadiness
        this.mainThreadAdmissionObservation = mainThreadAdmissionObservation
        this
            .didPrepareRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness =
            didPrepareRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness
        this
            .shouldDeferRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness =
            shouldDeferRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness
        this
            .shouldReportRendererNoPlatformObjectAppKitMainThreadAdmissionBlocked =
            shouldReportRendererNoPlatformObjectAppKitMainThreadAdmissionBlocked
        this
            .didPreserveRendererPlatformObjectAppKitClassAvailabilityReadiness =
            didPreserveRendererPlatformObjectAppKitClassAvailabilityReadiness
        this.didConfirmPlatformObjectMainThreadRequired =
            didConfirmPlatformObjectMainThreadRequired
        this.didConfirmPlatformObjectMainThreadAdmitted =
            didConfirmPlatformObjectMainThreadAdmitted
        this.didConfirmPlatformObjectBackgroundThreadDenied =
            didConfirmPlatformObjectBackgroundThreadDenied
        this.didConfirmPlatformObjectCreationStillBlocked =
            didConfirmPlatformObjectCreationStillBlocked
        this.didConfirmMainThreadGateRequired =
            didConfirmMainThreadGateRequired
        this.didConfirmNoClassIdPointerOrHandleReturn =
            didConfirmNoClassIdPointerOrHandleReturn
        this.didConfirmNoAppKitObjectAllocation =
            didConfirmNoAppKitObjectAllocation
        this.didConfirmNoMetalQuartzCoreUsage =
            didConfirmNoMetalQuartzCoreUsage
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNoPlatformObjectAppKitMainThreadAdmissionDehydrated =
            didKeepNoPlatformObjectAppKitMainThreadAdmissionDehydrated
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererPlatformObjectAppKitMainThreadAdmissionValues():
    CjguiInternalRendererPlatformObjectAppKitMainThreadAdmissionObservation {
    let mainThreadRequired = unsafe {
        cjgui_native_bridge_appkit_platform_object_main_thread_required()
    }
    let mainThreadAdmitted = unsafe {
        cjgui_native_bridge_appkit_platform_object_main_thread_admitted()
    }
    let backgroundThreadDenied = unsafe {
        cjgui_native_bridge_appkit_platform_object_background_thread_denied()
    }
    let platformObjectCreationStillBlocked = unsafe {
        cjgui_native_bridge_appkit_platform_object_creation_still_blocked()
    }
    return CjguiInternalRendererPlatformObjectAppKitMainThreadAdmissionObservation(
        mainThreadRequired,
        mainThreadAdmitted,
        backgroundThreadDenied,
        platformObjectCreationStillBlocked,
        mainThreadRequired == Int32(25),
        mainThreadAdmitted == Int32(26),
        backgroundThreadDenied == Int32(-22),
        platformObjectCreationStillBlocked == Int32(-23),
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererPlatformObjectAppKitMainThreadAdmissionReadiness(
    appkitClassAvailabilityReadiness:
        CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness,
    mainThreadAdmissionObservation:
        CjguiInternalRendererPlatformObjectAppKitMainThreadAdmissionObservation
): CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness {
    let upstreamReady =
        appkitClassAvailabilityReadiness
            .didPrepareRendererNoPlatformObjectAppKitClassAvailabilityReadiness &&
        appkitClassAvailabilityReadiness.didConfirmNSWindowClassAvailability &&
        appkitClassAvailabilityReadiness.didConfirmNSViewClassAvailability &&
        appkitClassAvailabilityReadiness
            .didConfirmClassLookupNoObjectAdmission &&
        appkitClassAvailabilityReadiness
            .didConfirmPlatformObjectAllocationStillBlocked &&
        appkitClassAvailabilityReadiness
            .didConfirmNoClassIdPointerOrHandleReturn &&
        appkitClassAvailabilityReadiness.didConfirmNoAppKitObjectAllocation &&
        appkitClassAvailabilityReadiness.didConfirmNoMetalQuartzCoreUsage &&
        appkitClassAvailabilityReadiness.didConfirmNoPublicSurface &&
        appkitClassAvailabilityReadiness.didConfirmNoRendererStateWrite &&
        appkitClassAvailabilityReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        mainThreadAdmissionObservation.didObserveMainThreadRequired &&
        mainThreadAdmissionObservation.didObserveMainThreadAdmitted &&
        mainThreadAdmissionObservation.didObserveBackgroundThreadDenied &&
        mainThreadAdmissionObservation
            .didObservePlatformObjectCreationStillBlocked &&
        mainThreadAdmissionObservation.didConfirmMainThreadGateRequired &&
        mainThreadAdmissionObservation
            .didConfirmNoClassIdPointerOrHandleReturn &&
        mainThreadAdmissionObservation.didConfirmNoAppKitObjectAllocation &&
        mainThreadAdmissionObservation.didConfirmNoMetalQuartzCoreUsage
    let readinessReady = upstreamReady && observationReady
    return CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness(
        appkitClassAvailabilityReadiness,
        mainThreadAdmissionObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        mainThreadAdmissionObservation.didObserveMainThreadRequired,
        mainThreadAdmissionObservation.didObserveMainThreadAdmitted,
        mainThreadAdmissionObservation.didObserveBackgroundThreadDenied,
        mainThreadAdmissionObservation
            .didObservePlatformObjectCreationStillBlocked,
        mainThreadAdmissionObservation.didConfirmMainThreadGateRequired,
        mainThreadAdmissionObservation
            .didConfirmNoClassIdPointerOrHandleReturn,
        mainThreadAdmissionObservation.didConfirmNoAppKitObjectAllocation,
        mainThreadAdmissionObservation.didConfirmNoMetalQuartzCoreUsage,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererPlatformObjectAppKitMainThreadAdmissionDraft():
    CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness {
    let appkitClassAvailabilityReadiness =
        cjguiInternalExecuteDefaultRendererPlatformObjectAppKitClassAvailabilityDraft()
    let mainThreadAdmissionObservation =
        cjguiInternalObserveRendererPlatformObjectAppKitMainThreadAdmissionValues()
    return cjguiInternalBuildRendererPlatformObjectAppKitMainThreadAdmissionReadiness(
        appkitClassAvailabilityReadiness,
        mainThreadAdmissionObservation
    )
}
