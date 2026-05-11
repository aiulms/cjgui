// 维护注释：本文件是 CAMetalLayer allocation without attachment internal owner。
// Truth: 只消费 CjguiInternalRendererNoCAMetalLayerNoAttachCallReadiness，
// 调用 allocation feasibility C ABI，并把返回值脱水为 internal facts。
// Stop-line: 不 attach 到 NSView，不设置 wantsLayer / layer，不设置 Metal device，
// 不获取 drawable，不返回 pointer / handle / Class / id，不写 runtime_state.cj。
// Same-shape Boundary Brake: 不得把 allocation feasibility 包成 attachment、
// Metal device、drawable、backend-ready、render-ready、GPU submission 或 state write。
package cjgui

foreign func cjgui_native_bridge_cametallayer_allocation_feasible(): Int32
foreign func cjgui_native_bridge_cametallayer_allocation_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_cametallayer_allocation_no_attach_admission():
    Int32
foreign func cjgui_native_bridge_cametallayer_allocation_device_binding_blocked():
    Int32
foreign func cjgui_native_bridge_cametallayer_allocation_feasibility_probe():
    Int32

struct CjguiInternalRendererCAMetalLayerAllocationObservation {
    let allocationFeasibleValue: Int32
    let allocationRequiresMainThreadValue: Int32
    let allocationNoAttachAdmissionValue: Int32
    let allocationDeviceBindingBlockedValue: Int32
    let allocationFeasibilityProbeValue: Int32
    let didObserveAllocationFeasible: Bool
    let didObserveMainThreadRequired: Bool
    let didObserveNoAttachAdmission: Bool
    let didObserveDeviceBindingBlocked: Bool
    let didObserveFeasibilityProbe: Bool
    let didConfirmNoAttachment: Bool
    let didConfirmNoMetalDeviceOrDrawable: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        allocationFeasibleValue: Int32,
        allocationRequiresMainThreadValue: Int32,
        allocationNoAttachAdmissionValue: Int32,
        allocationDeviceBindingBlockedValue: Int32,
        allocationFeasibilityProbeValue: Int32,
        didObserveAllocationFeasible: Bool,
        didObserveMainThreadRequired: Bool,
        didObserveNoAttachAdmission: Bool,
        didObserveDeviceBindingBlocked: Bool,
        didObserveFeasibilityProbe: Bool,
        didConfirmNoAttachment: Bool,
        didConfirmNoMetalDeviceOrDrawable: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.allocationFeasibleValue = allocationFeasibleValue
        this.allocationRequiresMainThreadValue =
            allocationRequiresMainThreadValue
        this.allocationNoAttachAdmissionValue =
            allocationNoAttachAdmissionValue
        this.allocationDeviceBindingBlockedValue =
            allocationDeviceBindingBlockedValue
        this.allocationFeasibilityProbeValue =
            allocationFeasibilityProbeValue
        this.didObserveAllocationFeasible = didObserveAllocationFeasible
        this.didObserveMainThreadRequired = didObserveMainThreadRequired
        this.didObserveNoAttachAdmission = didObserveNoAttachAdmission
        this.didObserveDeviceBindingBlocked = didObserveDeviceBindingBlocked
        this.didObserveFeasibilityProbe = didObserveFeasibilityProbe
        this.didConfirmNoAttachment = didConfirmNoAttachment
        this.didConfirmNoMetalDeviceOrDrawable =
            didConfirmNoMetalDeviceOrDrawable
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoCAMetalLayerAllocationReadiness {
    let didPrepareRendererNoCAMetalLayerAllocationReadiness: Bool
    let shouldDeferRendererNoCAMetalLayerAllocationReadiness: Bool
    let shouldReportRendererNoCAMetalLayerAllocationBlocked: Bool
    let didPreserveRendererCAMetalLayerNoAttachCallReadiness: Bool
    let didConfirmAllocationFeasible: Bool
    let didConfirmMainThreadRequired: Bool
    let didConfirmNoAttachAdmission: Bool
    let didConfirmDeviceBindingBlocked: Bool
    let didConfirmImmediateCleanupFeasibility: Bool
    let didConfirmNoAttachment: Bool
    let didConfirmNoMetalDeviceOrDrawable: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepCAMetalLayerAllocationReadinessDehydrated: Bool
    let didAvoidAttachWrapper: Bool
    let didAvoidMetalReadyWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        didPrepareRendererNoCAMetalLayerAllocationReadiness: Bool,
        shouldDeferRendererNoCAMetalLayerAllocationReadiness: Bool,
        shouldReportRendererNoCAMetalLayerAllocationBlocked: Bool,
        didPreserveRendererCAMetalLayerNoAttachCallReadiness: Bool,
        didConfirmAllocationFeasible: Bool,
        didConfirmMainThreadRequired: Bool,
        didConfirmNoAttachAdmission: Bool,
        didConfirmDeviceBindingBlocked: Bool,
        didConfirmImmediateCleanupFeasibility: Bool,
        didConfirmNoAttachment: Bool,
        didConfirmNoMetalDeviceOrDrawable: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepCAMetalLayerAllocationReadinessDehydrated: Bool,
        didAvoidAttachWrapper: Bool,
        didAvoidMetalReadyWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.didPrepareRendererNoCAMetalLayerAllocationReadiness =
            didPrepareRendererNoCAMetalLayerAllocationReadiness
        this.shouldDeferRendererNoCAMetalLayerAllocationReadiness =
            shouldDeferRendererNoCAMetalLayerAllocationReadiness
        this.shouldReportRendererNoCAMetalLayerAllocationBlocked =
            shouldReportRendererNoCAMetalLayerAllocationBlocked
        this.didPreserveRendererCAMetalLayerNoAttachCallReadiness =
            didPreserveRendererCAMetalLayerNoAttachCallReadiness
        this.didConfirmAllocationFeasible = didConfirmAllocationFeasible
        this.didConfirmMainThreadRequired = didConfirmMainThreadRequired
        this.didConfirmNoAttachAdmission = didConfirmNoAttachAdmission
        this.didConfirmDeviceBindingBlocked =
            didConfirmDeviceBindingBlocked
        this.didConfirmImmediateCleanupFeasibility =
            didConfirmImmediateCleanupFeasibility
        this.didConfirmNoAttachment = didConfirmNoAttachment
        this.didConfirmNoMetalDeviceOrDrawable =
            didConfirmNoMetalDeviceOrDrawable
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepCAMetalLayerAllocationReadinessDehydrated =
            didKeepCAMetalLayerAllocationReadinessDehydrated
        this.didAvoidAttachWrapper = didAvoidAttachWrapper
        this.didAvoidMetalReadyWrapper = didAvoidMetalReadyWrapper
        this.didAvoidRenderPermissionWrapper =
            didAvoidRenderPermissionWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
    }
}

func cjguiInternalObserveRendererCAMetalLayerAllocationValues():
    CjguiInternalRendererCAMetalLayerAllocationObservation {
    let allocationFeasible = unsafe {
        cjgui_native_bridge_cametallayer_allocation_feasible()
    }
    let mainThreadRequired = unsafe {
        cjgui_native_bridge_cametallayer_allocation_requires_main_thread()
    }
    let noAttachAdmission = unsafe {
        cjgui_native_bridge_cametallayer_allocation_no_attach_admission()
    }
    let deviceBindingBlocked = unsafe {
        cjgui_native_bridge_cametallayer_allocation_device_binding_blocked()
    }
    let feasibilityProbe = unsafe {
        cjgui_native_bridge_cametallayer_allocation_feasibility_probe()
    }
    return CjguiInternalRendererCAMetalLayerAllocationObservation(
        allocationFeasible,
        mainThreadRequired,
        noAttachAdmission,
        deviceBindingBlocked,
        feasibilityProbe,
        allocationFeasible == Int32(60),
        mainThreadRequired == Int32(-60),
        noAttachAdmission == Int32(61),
        deviceBindingBlocked == Int32(-62),
        feasibilityProbe == Int32(62),
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererCAMetalLayerAllocationReadiness(
    noAttachReadiness:
        CjguiInternalRendererNoCAMetalLayerNoAttachCallReadiness,
    allocationObservation:
        CjguiInternalRendererCAMetalLayerAllocationObservation
): CjguiInternalRendererNoCAMetalLayerAllocationReadiness {
    let upstreamReady =
        noAttachReadiness.didPrepareRendererNoCAMetalLayerNoAttachCallReadiness &&
        noAttachReadiness.didConfirmQuartzCoreImportAvailable &&
        noAttachReadiness.didConfirmCAMetalLayerClassAvailable &&
        noAttachReadiness.didConfirmCAMetalLayerNoAttachAdmission &&
        noAttachReadiness.didConfirmNoLayerAttachment &&
        noAttachReadiness.didConfirmNoMetalDeviceOrDrawable &&
        noAttachReadiness.didConfirmNoPointerHandleClassIdReturn &&
        noAttachReadiness.didConfirmNoRendererStateWrite &&
        noAttachReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        allocationObservation.didObserveAllocationFeasible &&
        allocationObservation.didObserveMainThreadRequired &&
        allocationObservation.didObserveNoAttachAdmission &&
        allocationObservation.didObserveDeviceBindingBlocked &&
        allocationObservation.didObserveFeasibilityProbe &&
        allocationObservation.didConfirmNoAttachment &&
        allocationObservation.didConfirmNoMetalDeviceOrDrawable &&
        allocationObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady
    return CjguiInternalRendererNoCAMetalLayerAllocationReadiness(
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        allocationObservation.didObserveAllocationFeasible,
        allocationObservation.didObserveMainThreadRequired,
        allocationObservation.didObserveNoAttachAdmission,
        allocationObservation.didObserveDeviceBindingBlocked,
        allocationObservation.didObserveFeasibilityProbe,
        allocationObservation.didConfirmNoAttachment,
        allocationObservation.didConfirmNoMetalDeviceOrDrawable,
        allocationObservation.didConfirmNoPointerHandleClassIdReturn,
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

func cjguiInternalExecuteDefaultRendererCAMetalLayerAllocationDraft():
    CjguiInternalRendererNoCAMetalLayerAllocationReadiness {
    let noAttachReadiness =
        cjguiInternalExecuteDefaultRendererCAMetalLayerNoAttachCallDraft()
    let allocationObservation =
        cjguiInternalObserveRendererCAMetalLayerAllocationValues()
    return cjguiInternalBuildRendererCAMetalLayerAllocationReadiness(
        noAttachReadiness,
        allocationObservation
    )
}
