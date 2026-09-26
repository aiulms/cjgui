// 维护注释：本文件是 Metal default device availability no-bind facts owner。
// Truth: 只消费 CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness，
// 调用 Metal import / default device availability / no-command-queue C ABI，
// 并把返回值脱水为 internal facts。
// Stop-line: 不创建持久 MTLDevice，不绑定 CAMetalLayer，不创建 command queue /
// drawable / command buffer，不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: availability facts 不得包装成 backend-ready、
// render-ready、GPU submission、state write、receipt、record 或 publication。
package cjgui

foreign func cjgui_native_bridge_metal_import_available(): Int32
foreign func cjgui_native_bridge_metal_default_device_available(): Int32
foreign func cjgui_native_bridge_metal_device_no_command_queue_admission(): Int32
foreign func cjgui_native_bridge_metal_device_creation_still_blocked(): Int32

struct CjguiInternalRendererMetalDeviceAvailabilityObservation {
    let metalImportValue: Int32
    let defaultDeviceAvailabilityValue: Int32
    let noCommandQueueAdmissionValue: Int32
    let creationStillBlockedValue: Int32
    let didObserveMetalImport: Bool
    let didObserveDefaultDeviceAvailability: Bool
    let didObserveCommandQueueStillBlocked: Bool
    let didObserveCreationStillClassified: Bool
    let didConfirmNoDeviceBindingDrawableOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        metalImportValue: Int32,
        defaultDeviceAvailabilityValue: Int32,
        noCommandQueueAdmissionValue: Int32,
        creationStillBlockedValue: Int32,
        didObserveMetalImport: Bool,
        didObserveDefaultDeviceAvailability: Bool,
        didObserveCommandQueueStillBlocked: Bool,
        didObserveCreationStillClassified: Bool,
        didConfirmNoDeviceBindingDrawableOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.metalImportValue = metalImportValue
        this.defaultDeviceAvailabilityValue = defaultDeviceAvailabilityValue
        this.noCommandQueueAdmissionValue = noCommandQueueAdmissionValue
        this.creationStillBlockedValue = creationStillBlockedValue
        this.didObserveMetalImport = didObserveMetalImport
        this.didObserveDefaultDeviceAvailability =
            didObserveDefaultDeviceAvailability
        this.didObserveCommandQueueStillBlocked =
            didObserveCommandQueueStillBlocked
        this.didObserveCreationStillClassified =
            didObserveCreationStillClassified
        this.didConfirmNoDeviceBindingDrawableOrRender =
            didConfirmNoDeviceBindingDrawableOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoMetalDeviceAvailabilityReadiness {
    let attachmentRuntimeCallReadiness:
        CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness
    let availabilityObservation:
        CjguiInternalRendererMetalDeviceAvailabilityObservation
    let didPrepareRendererNoMetalDeviceAvailabilityReadiness: Bool
    let shouldDeferRendererNoMetalDeviceAvailabilityReadiness: Bool
    let shouldReportRendererNoMetalDeviceAvailabilityBlocked: Bool
    let didPreserveRendererCAMetalLayerAttachmentRuntimeCallReadiness: Bool
    let didConfirmMetalImportObserved: Bool
    let didConfirmDefaultDeviceAvailabilityObserved: Bool
    let didConfirmNoCommandQueueDrawableOrRender: Bool
    let didConfirmNoDeviceBinding: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepMetalDeviceAvailabilityReadinessDehydrated: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        attachmentRuntimeCallReadiness:
            CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness,
        availabilityObservation:
            CjguiInternalRendererMetalDeviceAvailabilityObservation,
        didPrepareRendererNoMetalDeviceAvailabilityReadiness: Bool,
        shouldDeferRendererNoMetalDeviceAvailabilityReadiness: Bool,
        shouldReportRendererNoMetalDeviceAvailabilityBlocked: Bool,
        didPreserveRendererCAMetalLayerAttachmentRuntimeCallReadiness: Bool,
        didConfirmMetalImportObserved: Bool,
        didConfirmDefaultDeviceAvailabilityObserved: Bool,
        didConfirmNoCommandQueueDrawableOrRender: Bool,
        didConfirmNoDeviceBinding: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepMetalDeviceAvailabilityReadinessDehydrated: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.attachmentRuntimeCallReadiness = attachmentRuntimeCallReadiness
        this.availabilityObservation = availabilityObservation
        this.didPrepareRendererNoMetalDeviceAvailabilityReadiness =
            didPrepareRendererNoMetalDeviceAvailabilityReadiness
        this.shouldDeferRendererNoMetalDeviceAvailabilityReadiness =
            shouldDeferRendererNoMetalDeviceAvailabilityReadiness
        this.shouldReportRendererNoMetalDeviceAvailabilityBlocked =
            shouldReportRendererNoMetalDeviceAvailabilityBlocked
        this.didPreserveRendererCAMetalLayerAttachmentRuntimeCallReadiness =
            didPreserveRendererCAMetalLayerAttachmentRuntimeCallReadiness
        this.didConfirmMetalImportObserved = didConfirmMetalImportObserved
        this.didConfirmDefaultDeviceAvailabilityObserved =
            didConfirmDefaultDeviceAvailabilityObserved
        this.didConfirmNoCommandQueueDrawableOrRender =
            didConfirmNoCommandQueueDrawableOrRender
        this.didConfirmNoDeviceBinding = didConfirmNoDeviceBinding
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepMetalDeviceAvailabilityReadinessDehydrated =
            didKeepMetalDeviceAvailabilityReadinessDehydrated
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererMetalDeviceAvailabilityValues():
    CjguiInternalRendererMetalDeviceAvailabilityObservation {
    let metalImport = unsafe {
        cjgui_native_bridge_metal_import_available()
    }
    let defaultDeviceAvailability = unsafe {
        cjgui_native_bridge_metal_default_device_available()
    }
    let noCommandQueueAdmission = unsafe {
        cjgui_native_bridge_metal_device_no_command_queue_admission()
    }
    let creationStillBlocked = unsafe {
        cjgui_native_bridge_metal_device_creation_still_blocked()
    }

    return CjguiInternalRendererMetalDeviceAvailabilityObservation(
        metalImport,
        defaultDeviceAvailability,
        noCommandQueueAdmission,
        creationStillBlocked,
        metalImport == Int32(100),
        defaultDeviceAvailability == Int32(101),
        noCommandQueueAdmission == Int32(-110),
        creationStillBlocked == Int32(-112),
        true,
        true
    )
}

func cjguiInternalBuildRendererMetalDeviceAvailabilityReadiness(
    attachmentRuntimeCallReadiness:
        CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness,
    availabilityObservation:
        CjguiInternalRendererMetalDeviceAvailabilityObservation
): CjguiInternalRendererNoMetalDeviceAvailabilityReadiness {
    let upstreamReady =
        attachmentRuntimeCallReadiness
            .didPrepareRendererNoCAMetalLayerAttachmentRuntimeCallReadiness &&
        attachmentRuntimeCallReadiness.didConfirmNoMetalDeviceDrawableOrRender &&
        attachmentRuntimeCallReadiness.didConfirmNoPublicSurface &&
        attachmentRuntimeCallReadiness.didConfirmNoRendererStateWrite &&
        attachmentRuntimeCallReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        availabilityObservation.didObserveMetalImport &&
        availabilityObservation.didObserveDefaultDeviceAvailability &&
        availabilityObservation.didObserveCommandQueueStillBlocked &&
        availabilityObservation.didObserveCreationStillClassified &&
        availabilityObservation.didConfirmNoDeviceBindingDrawableOrRender &&
        availabilityObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady

    return CjguiInternalRendererNoMetalDeviceAvailabilityReadiness(
        attachmentRuntimeCallReadiness,
        availabilityObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        availabilityObservation.didObserveMetalImport,
        availabilityObservation.didObserveDefaultDeviceAvailability,
        availabilityObservation.didConfirmNoDeviceBindingDrawableOrRender,
        true,
        availabilityObservation.didConfirmNoPointerHandleClassIdReturn,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererMetalDeviceAvailabilityDraft():
    CjguiInternalRendererNoMetalDeviceAvailabilityReadiness {
    let attachmentRuntimeCallReadiness =
        cjguiInternalExecuteDefaultRendererCAMetalLayerAttachmentRuntimeCallDraft()
    let availabilityObservation =
        cjguiInternalObserveRendererMetalDeviceAvailabilityValues()
    return cjguiInternalBuildRendererMetalDeviceAvailabilityReadiness(
        attachmentRuntimeCallReadiness,
        availabilityObservation
    )
}
