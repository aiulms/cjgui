// Owner: platform object AppKit class availability no-object boundary owner。
// Truth: 只消费 CjguiInternalRendererNoPlatformObjectAppKitImportReadiness，
// 调用 AppKit class lookup / no-object admission C ABI，并把返回值脱水为 internal facts。
// Stop-line: 只证明 NSWindow / NSView class lookup 可观察；不创建 AppKit
// object，不返回 Class / id / pointer / handle，不导入 Metal / QuartzCore，不写 runtime_state.cj。
// Same-shape Boundary Brake: 不得把本 owner 包成 platform object creation、
// AppKit object permission、native handle、Metal、public API、backend-ready、
// receipt、record 或 publication wrapper。
package cjgui

foreign func cjgui_native_bridge_appkit_nswindow_class_available(): Int32
foreign func cjgui_native_bridge_appkit_nsview_class_available(): Int32
foreign func cjgui_native_bridge_appkit_class_lookup_no_object_admission():
    Int32
foreign func cjgui_native_bridge_platform_object_allocation_still_blocked():
    Int32

struct CjguiInternalRendererPlatformObjectAppKitClassAvailabilityObservation {
    let nsWindowClassAvailableValue: Int32
    let nsViewClassAvailableValue: Int32
    let classLookupNoObjectAdmissionValue: Int32
    let platformObjectAllocationStillBlockedValue: Int32
    let didObserveNSWindowClassAvailable: Bool
    let didObserveNSViewClassAvailable: Bool
    let didObserveClassLookupNoObjectAdmission: Bool
    let didObservePlatformObjectAllocationStillBlocked: Bool
    let didConfirmNoClassIdPointerOrHandleReturn: Bool
    let didConfirmNoAppKitObjectAllocation: Bool
    let didConfirmNoMetalQuartzCoreUsage: Bool

    init(
        nsWindowClassAvailableValue: Int32,
        nsViewClassAvailableValue: Int32,
        classLookupNoObjectAdmissionValue: Int32,
        platformObjectAllocationStillBlockedValue: Int32,
        didObserveNSWindowClassAvailable: Bool,
        didObserveNSViewClassAvailable: Bool,
        didObserveClassLookupNoObjectAdmission: Bool,
        didObservePlatformObjectAllocationStillBlocked: Bool,
        didConfirmNoClassIdPointerOrHandleReturn: Bool,
        didConfirmNoAppKitObjectAllocation: Bool,
        didConfirmNoMetalQuartzCoreUsage: Bool
    ) {
        this.nsWindowClassAvailableValue = nsWindowClassAvailableValue
        this.nsViewClassAvailableValue = nsViewClassAvailableValue
        this.classLookupNoObjectAdmissionValue =
            classLookupNoObjectAdmissionValue
        this.platformObjectAllocationStillBlockedValue =
            platformObjectAllocationStillBlockedValue
        this.didObserveNSWindowClassAvailable =
            didObserveNSWindowClassAvailable
        this.didObserveNSViewClassAvailable =
            didObserveNSViewClassAvailable
        this.didObserveClassLookupNoObjectAdmission =
            didObserveClassLookupNoObjectAdmission
        this.didObservePlatformObjectAllocationStillBlocked =
            didObservePlatformObjectAllocationStillBlocked
        this.didConfirmNoClassIdPointerOrHandleReturn =
            didConfirmNoClassIdPointerOrHandleReturn
        this.didConfirmNoAppKitObjectAllocation =
            didConfirmNoAppKitObjectAllocation
        this.didConfirmNoMetalQuartzCoreUsage =
            didConfirmNoMetalQuartzCoreUsage
    }
}

struct CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness {
    let appkitImportReadiness:
        CjguiInternalRendererNoPlatformObjectAppKitImportReadiness
    let classAvailabilityObservation:
        CjguiInternalRendererPlatformObjectAppKitClassAvailabilityObservation
    let didPrepareRendererNoPlatformObjectAppKitClassAvailabilityReadiness:
        Bool
    let shouldDeferRendererNoPlatformObjectAppKitClassAvailabilityReadiness:
        Bool
    let shouldReportRendererNoPlatformObjectAppKitClassAvailabilityBlocked:
        Bool
    let didPreserveRendererPlatformObjectAppKitImportReadiness: Bool
    let didConfirmNSWindowClassAvailability: Bool
    let didConfirmNSViewClassAvailability: Bool
    let didConfirmClassLookupNoObjectAdmission: Bool
    let didConfirmPlatformObjectAllocationStillBlocked: Bool
    let didConfirmNoClassIdPointerOrHandleReturn: Bool
    let didConfirmNoAppKitObjectAllocation: Bool
    let didConfirmNoMetalQuartzCoreUsage: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoPlatformObjectAppKitClassAvailabilityDehydrated: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        appkitImportReadiness:
            CjguiInternalRendererNoPlatformObjectAppKitImportReadiness,
        classAvailabilityObservation:
            CjguiInternalRendererPlatformObjectAppKitClassAvailabilityObservation,
        didPrepareRendererNoPlatformObjectAppKitClassAvailabilityReadiness:
            Bool,
        shouldDeferRendererNoPlatformObjectAppKitClassAvailabilityReadiness:
            Bool,
        shouldReportRendererNoPlatformObjectAppKitClassAvailabilityBlocked:
            Bool,
        didPreserveRendererPlatformObjectAppKitImportReadiness: Bool,
        didConfirmNSWindowClassAvailability: Bool,
        didConfirmNSViewClassAvailability: Bool,
        didConfirmClassLookupNoObjectAdmission: Bool,
        didConfirmPlatformObjectAllocationStillBlocked: Bool,
        didConfirmNoClassIdPointerOrHandleReturn: Bool,
        didConfirmNoAppKitObjectAllocation: Bool,
        didConfirmNoMetalQuartzCoreUsage: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoPlatformObjectAppKitClassAvailabilityDehydrated: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.appkitImportReadiness = appkitImportReadiness
        this.classAvailabilityObservation = classAvailabilityObservation
        this
            .didPrepareRendererNoPlatformObjectAppKitClassAvailabilityReadiness =
            didPrepareRendererNoPlatformObjectAppKitClassAvailabilityReadiness
        this
            .shouldDeferRendererNoPlatformObjectAppKitClassAvailabilityReadiness =
            shouldDeferRendererNoPlatformObjectAppKitClassAvailabilityReadiness
        this
            .shouldReportRendererNoPlatformObjectAppKitClassAvailabilityBlocked =
            shouldReportRendererNoPlatformObjectAppKitClassAvailabilityBlocked
        this.didPreserveRendererPlatformObjectAppKitImportReadiness =
            didPreserveRendererPlatformObjectAppKitImportReadiness
        this.didConfirmNSWindowClassAvailability =
            didConfirmNSWindowClassAvailability
        this.didConfirmNSViewClassAvailability =
            didConfirmNSViewClassAvailability
        this.didConfirmClassLookupNoObjectAdmission =
            didConfirmClassLookupNoObjectAdmission
        this.didConfirmPlatformObjectAllocationStillBlocked =
            didConfirmPlatformObjectAllocationStillBlocked
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
        this.didKeepNoPlatformObjectAppKitClassAvailabilityDehydrated =
            didKeepNoPlatformObjectAppKitClassAvailabilityDehydrated
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererPlatformObjectAppKitClassAvailabilityValues():
    CjguiInternalRendererPlatformObjectAppKitClassAvailabilityObservation {
    let nsWindowClassAvailable = unsafe {
        cjgui_native_bridge_appkit_nswindow_class_available()
    }
    let nsViewClassAvailable = unsafe {
        cjgui_native_bridge_appkit_nsview_class_available()
    }
    let classLookupNoObjectAdmission = unsafe {
        cjgui_native_bridge_appkit_class_lookup_no_object_admission()
    }
    let platformObjectAllocationStillBlocked = unsafe {
        cjgui_native_bridge_platform_object_allocation_still_blocked()
    }
    return CjguiInternalRendererPlatformObjectAppKitClassAvailabilityObservation(
        nsWindowClassAvailable,
        nsViewClassAvailable,
        classLookupNoObjectAdmission,
        platformObjectAllocationStillBlocked,
        nsWindowClassAvailable == Int32(22),
        nsViewClassAvailable == Int32(23),
        classLookupNoObjectAdmission == Int32(24),
        platformObjectAllocationStillBlocked == Int32(-21),
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererPlatformObjectAppKitClassAvailabilityReadiness(
    appkitImportReadiness:
        CjguiInternalRendererNoPlatformObjectAppKitImportReadiness,
    classAvailabilityObservation:
        CjguiInternalRendererPlatformObjectAppKitClassAvailabilityObservation
): CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness {
    let upstreamReady =
        appkitImportReadiness
            .didPrepareRendererNoPlatformObjectAppKitImportReadiness &&
        appkitImportReadiness.didConfirmAppKitImportBoundary &&
        appkitImportReadiness.didConfirmNoObjectAppKitAdmission &&
        appkitImportReadiness.didConfirmPlatformObjectCreationStillBlocked &&
        appkitImportReadiness.didConfirmMainThreadPrerequisite &&
        appkitImportReadiness.didConfirmTokenTeardownPrerequisites &&
        appkitImportReadiness.didConfirmNoMetalQuartzCoreUsage &&
        appkitImportReadiness.didConfirmNoNativeObjectHandleOrPointer &&
        appkitImportReadiness.didConfirmNoPublicSurface &&
        appkitImportReadiness.didConfirmNoRendererStateWrite &&
        appkitImportReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        classAvailabilityObservation.didObserveNSWindowClassAvailable &&
        classAvailabilityObservation.didObserveNSViewClassAvailable &&
        classAvailabilityObservation.didObserveClassLookupNoObjectAdmission &&
        classAvailabilityObservation
            .didObservePlatformObjectAllocationStillBlocked &&
        classAvailabilityObservation
            .didConfirmNoClassIdPointerOrHandleReturn &&
        classAvailabilityObservation.didConfirmNoAppKitObjectAllocation &&
        classAvailabilityObservation.didConfirmNoMetalQuartzCoreUsage
    let readinessReady = upstreamReady && observationReady
    return CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness(
        appkitImportReadiness,
        classAvailabilityObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        classAvailabilityObservation.didObserveNSWindowClassAvailable,
        classAvailabilityObservation.didObserveNSViewClassAvailable,
        classAvailabilityObservation.didObserveClassLookupNoObjectAdmission,
        classAvailabilityObservation
            .didObservePlatformObjectAllocationStillBlocked,
        classAvailabilityObservation
            .didConfirmNoClassIdPointerOrHandleReturn,
        classAvailabilityObservation.didConfirmNoAppKitObjectAllocation,
        classAvailabilityObservation.didConfirmNoMetalQuartzCoreUsage,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererPlatformObjectAppKitClassAvailabilityDraft():
    CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness {
    let appkitImportReadiness =
        cjguiInternalExecuteDefaultRendererPlatformObjectAppKitImportDraft()
    let classAvailabilityObservation =
        cjguiInternalObserveRendererPlatformObjectAppKitClassAvailabilityValues()
    return cjguiInternalBuildRendererPlatformObjectAppKitClassAvailabilityReadiness(
        appkitImportReadiness,
        classAvailabilityObservation
    )
}
