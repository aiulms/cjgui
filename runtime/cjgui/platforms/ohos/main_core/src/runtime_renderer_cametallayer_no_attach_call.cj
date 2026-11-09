// 维护注释：本文件是 CAMetalLayer no-attach class/runtime FFI call owner。
// Truth: 只消费 CjguiInternalRendererNoCAMetalLayerAttachmentReadiness，
// 调用 QuartzCore import / CAMetalLayer class lookup / no-attach admission C ABI，
// 并把返回值脱水为 internal facts。
// Stop-line: 不创建 CAMetalLayer / CALayer，不 attach 到 NSView，不设置
// wantsLayer，不创建 Metal device / drawable，不返回 pointer / handle / Class / id，
// 不写 runtime_state.cj，不新增 public API。
// Same-shape Boundary Brake: 不得把本 owner 包成 layer attachment permission、
// Metal device permission、backend-ready、render-ready、GPU-submission、renderer
// state write、receipt、record 或 publication wrapper。
package cjgui

foreign func cjgui_native_bridge_quartzcore_import_available(): Int32
foreign func cjgui_native_bridge_cametallayer_class_available(): Int32
foreign func cjgui_native_bridge_cametallayer_no_attach_admission(): Int32
foreign func cjgui_native_bridge_cametallayer_allocation_still_blocked():
    Int32
foreign func cjgui_native_bridge_cametallayer_device_binding_still_blocked():
    Int32

struct CjguiInternalRendererCAMetalLayerNoAttachObservation {
    let quartzCoreImportAvailableValue: Int32
    let cametalLayerClassAvailableValue: Int32
    let cametalLayerNoAttachAdmissionValue: Int32
    let cametalLayerAllocationStillBlockedValue: Int32
    let cametalLayerDeviceBindingStillBlockedValue: Int32
    let didObserveQuartzCoreImportAvailable: Bool
    let didObserveCAMetalLayerClassAvailable: Bool
    let didObserveCAMetalLayerNoAttachAdmission: Bool
    let didObserveCAMetalLayerAllocationStillBlocked: Bool
    let didObserveCAMetalLayerDeviceBindingStillBlocked: Bool
    let didConfirmNoLayerObjectCreation: Bool
    let didConfirmNoLayerAttachment: Bool
    let didConfirmNoMetalDeviceOrDrawable: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        quartzCoreImportAvailableValue: Int32,
        cametalLayerClassAvailableValue: Int32,
        cametalLayerNoAttachAdmissionValue: Int32,
        cametalLayerAllocationStillBlockedValue: Int32,
        cametalLayerDeviceBindingStillBlockedValue: Int32,
        didObserveQuartzCoreImportAvailable: Bool,
        didObserveCAMetalLayerClassAvailable: Bool,
        didObserveCAMetalLayerNoAttachAdmission: Bool,
        didObserveCAMetalLayerAllocationStillBlocked: Bool,
        didObserveCAMetalLayerDeviceBindingStillBlocked: Bool,
        didConfirmNoLayerObjectCreation: Bool,
        didConfirmNoLayerAttachment: Bool,
        didConfirmNoMetalDeviceOrDrawable: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.quartzCoreImportAvailableValue =
            quartzCoreImportAvailableValue
        this.cametalLayerClassAvailableValue =
            cametalLayerClassAvailableValue
        this.cametalLayerNoAttachAdmissionValue =
            cametalLayerNoAttachAdmissionValue
        this.cametalLayerAllocationStillBlockedValue =
            cametalLayerAllocationStillBlockedValue
        this.cametalLayerDeviceBindingStillBlockedValue =
            cametalLayerDeviceBindingStillBlockedValue
        this.didObserveQuartzCoreImportAvailable =
            didObserveQuartzCoreImportAvailable
        this.didObserveCAMetalLayerClassAvailable =
            didObserveCAMetalLayerClassAvailable
        this.didObserveCAMetalLayerNoAttachAdmission =
            didObserveCAMetalLayerNoAttachAdmission
        this.didObserveCAMetalLayerAllocationStillBlocked =
            didObserveCAMetalLayerAllocationStillBlocked
        this.didObserveCAMetalLayerDeviceBindingStillBlocked =
            didObserveCAMetalLayerDeviceBindingStillBlocked
        this.didConfirmNoLayerObjectCreation =
            didConfirmNoLayerObjectCreation
        this.didConfirmNoLayerAttachment = didConfirmNoLayerAttachment
        this.didConfirmNoMetalDeviceOrDrawable =
            didConfirmNoMetalDeviceOrDrawable
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoCAMetalLayerNoAttachCallReadiness {
    let didPrepareRendererNoCAMetalLayerNoAttachCallReadiness: Bool
    let shouldDeferRendererNoCAMetalLayerNoAttachCallReadiness: Bool
    let shouldReportRendererNoCAMetalLayerNoAttachCallBlocked: Bool
    let didPreserveRendererCAMetalLayerAttachmentReadiness: Bool
    let didConfirmQuartzCoreImportAvailable: Bool
    let didConfirmCAMetalLayerClassAvailable: Bool
    let didConfirmCAMetalLayerNoAttachAdmission: Bool
    let didConfirmCAMetalLayerAllocationStillBlocked: Bool
    let didConfirmCAMetalLayerDeviceBindingStillBlocked: Bool
    let didConfirmNoLayerObjectCreation: Bool
    let didConfirmNoLayerAttachment: Bool
    let didConfirmNoMetalDeviceOrDrawable: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoCAMetalLayerNoAttachCallReadinessDehydrated: Bool
    let didAvoidLayerAttachmentWrapper: Bool
    let didAvoidMetalReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidGPUSubmissionWrapper: Bool
    let didAvoidRendererStateWriteWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        didPrepareRendererNoCAMetalLayerNoAttachCallReadiness: Bool,
        shouldDeferRendererNoCAMetalLayerNoAttachCallReadiness: Bool,
        shouldReportRendererNoCAMetalLayerNoAttachCallBlocked: Bool,
        didPreserveRendererCAMetalLayerAttachmentReadiness: Bool,
        didConfirmQuartzCoreImportAvailable: Bool,
        didConfirmCAMetalLayerClassAvailable: Bool,
        didConfirmCAMetalLayerNoAttachAdmission: Bool,
        didConfirmCAMetalLayerAllocationStillBlocked: Bool,
        didConfirmCAMetalLayerDeviceBindingStillBlocked: Bool,
        didConfirmNoLayerObjectCreation: Bool,
        didConfirmNoLayerAttachment: Bool,
        didConfirmNoMetalDeviceOrDrawable: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoCAMetalLayerNoAttachCallReadinessDehydrated: Bool,
        didAvoidLayerAttachmentWrapper: Bool,
        didAvoidMetalReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidGPUSubmissionWrapper: Bool,
        didAvoidRendererStateWriteWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.didPrepareRendererNoCAMetalLayerNoAttachCallReadiness =
            didPrepareRendererNoCAMetalLayerNoAttachCallReadiness
        this.shouldDeferRendererNoCAMetalLayerNoAttachCallReadiness =
            shouldDeferRendererNoCAMetalLayerNoAttachCallReadiness
        this.shouldReportRendererNoCAMetalLayerNoAttachCallBlocked =
            shouldReportRendererNoCAMetalLayerNoAttachCallBlocked
        this.didPreserveRendererCAMetalLayerAttachmentReadiness =
            didPreserveRendererCAMetalLayerAttachmentReadiness
        this.didConfirmQuartzCoreImportAvailable =
            didConfirmQuartzCoreImportAvailable
        this.didConfirmCAMetalLayerClassAvailable =
            didConfirmCAMetalLayerClassAvailable
        this.didConfirmCAMetalLayerNoAttachAdmission =
            didConfirmCAMetalLayerNoAttachAdmission
        this.didConfirmCAMetalLayerAllocationStillBlocked =
            didConfirmCAMetalLayerAllocationStillBlocked
        this.didConfirmCAMetalLayerDeviceBindingStillBlocked =
            didConfirmCAMetalLayerDeviceBindingStillBlocked
        this.didConfirmNoLayerObjectCreation =
            didConfirmNoLayerObjectCreation
        this.didConfirmNoLayerAttachment = didConfirmNoLayerAttachment
        this.didConfirmNoMetalDeviceOrDrawable =
            didConfirmNoMetalDeviceOrDrawable
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth =
            didConfirmNoBackendReadyTruth
        this.didKeepNoCAMetalLayerNoAttachCallReadinessDehydrated =
            didKeepNoCAMetalLayerNoAttachCallReadinessDehydrated
        this.didAvoidLayerAttachmentWrapper = didAvoidLayerAttachmentWrapper
        this.didAvoidMetalReadyWrapper = didAvoidMetalReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
        this.didAvoidRenderPermissionWrapper =
            didAvoidRenderPermissionWrapper
        this.didAvoidGPUSubmissionWrapper = didAvoidGPUSubmissionWrapper
        this.didAvoidRendererStateWriteWrapper =
            didAvoidRendererStateWriteWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererCAMetalLayerNoAttachValues():
    CjguiInternalRendererCAMetalLayerNoAttachObservation {
    let quartzCoreImportAvailable = unsafe {
        cjgui_native_bridge_quartzcore_import_available()
    }
    let cametalLayerClassAvailable = unsafe {
        cjgui_native_bridge_cametallayer_class_available()
    }
    let cametalLayerNoAttachAdmission = unsafe {
        cjgui_native_bridge_cametallayer_no_attach_admission()
    }
    let cametalLayerAllocationStillBlocked = unsafe {
        cjgui_native_bridge_cametallayer_allocation_still_blocked()
    }
    let cametalLayerDeviceBindingStillBlocked = unsafe {
        cjgui_native_bridge_cametallayer_device_binding_still_blocked()
    }
    return CjguiInternalRendererCAMetalLayerNoAttachObservation(
        quartzCoreImportAvailable,
        cametalLayerClassAvailable,
        cametalLayerNoAttachAdmission,
        cametalLayerAllocationStillBlocked,
        cametalLayerDeviceBindingStillBlocked,
        quartzCoreImportAvailable == Int32(50),
        cametalLayerClassAvailable == Int32(51),
        cametalLayerNoAttachAdmission == Int32(52),
        cametalLayerAllocationStillBlocked == Int32(-50),
        cametalLayerDeviceBindingStillBlocked == Int32(-51),
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererCAMetalLayerNoAttachCallReadiness(
    cametalLayerAttachmentReadiness:
        CjguiInternalRendererNoCAMetalLayerAttachmentReadiness,
    noAttachObservation:
        CjguiInternalRendererCAMetalLayerNoAttachObservation
): CjguiInternalRendererNoCAMetalLayerNoAttachCallReadiness {
    let upstreamReady =
        cametalLayerAttachmentReadiness
            .didPrepareRendererNoCAMetalLayerAttachmentReadiness &&
        cametalLayerAttachmentReadiness
            .didConfirmCAMetalLayerAttachmentIntent &&
        cametalLayerAttachmentReadiness
            .didConfirmQuartzCoreImportAdmissionPolicy &&
        cametalLayerAttachmentReadiness
            .didConfirmCAMetalLayerClassAvailabilityObservationPolicy &&
        cametalLayerAttachmentReadiness
            .didConfirmNsViewLayerAttachmentStillBlocked &&
        cametalLayerAttachmentReadiness
            .didConfirmNoCAMetalLayerOrCALayerCreation &&
        cametalLayerAttachmentReadiness.didConfirmNoWantsLayerMutation &&
        cametalLayerAttachmentReadiness
            .didConfirmNoMetalDeviceOrDrawableBinding &&
        cametalLayerAttachmentReadiness.didConfirmNoRendererStateWrite &&
        cametalLayerAttachmentReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        noAttachObservation.didObserveQuartzCoreImportAvailable &&
        noAttachObservation.didObserveCAMetalLayerClassAvailable &&
        noAttachObservation.didObserveCAMetalLayerNoAttachAdmission &&
        noAttachObservation.didObserveCAMetalLayerAllocationStillBlocked &&
        noAttachObservation.didObserveCAMetalLayerDeviceBindingStillBlocked &&
        noAttachObservation.didConfirmNoLayerObjectCreation &&
        noAttachObservation.didConfirmNoLayerAttachment &&
        noAttachObservation.didConfirmNoMetalDeviceOrDrawable &&
        noAttachObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady
    return CjguiInternalRendererNoCAMetalLayerNoAttachCallReadiness(
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        noAttachObservation.didObserveQuartzCoreImportAvailable,
        noAttachObservation.didObserveCAMetalLayerClassAvailable,
        noAttachObservation.didObserveCAMetalLayerNoAttachAdmission,
        noAttachObservation.didObserveCAMetalLayerAllocationStillBlocked,
        noAttachObservation.didObserveCAMetalLayerDeviceBindingStillBlocked,
        noAttachObservation.didConfirmNoLayerObjectCreation,
        noAttachObservation.didConfirmNoLayerAttachment,
        noAttachObservation.didConfirmNoMetalDeviceOrDrawable,
        noAttachObservation.didConfirmNoPointerHandleClassIdReturn,
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

func cjguiInternalExecuteDefaultRendererCAMetalLayerNoAttachCallDraft():
    CjguiInternalRendererNoCAMetalLayerNoAttachCallReadiness {
    let cametalLayerAttachmentReadiness =
        cjguiInternalExecuteDefaultRendererCAMetalLayerAttachmentDraft()
    let noAttachObservation =
        cjguiInternalObserveRendererCAMetalLayerNoAttachValues()
    return cjguiInternalBuildRendererCAMetalLayerNoAttachCallReadiness(
        cametalLayerAttachmentReadiness,
        noAttachObservation
    )
}
