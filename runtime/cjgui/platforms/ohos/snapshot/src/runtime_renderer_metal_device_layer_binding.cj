// 维护注释：本文件是 MTLDevice token 绑定到 token-backed CAMetalLayer 的 internal owner。
// Truth: 只消费 CjguiInternalRendererNoMetalDeviceCreateDestroyReadiness，
// 局部执行 NSView / CAMetalLayer / MTLDevice create、attach、bind、unbind、cleanup，
// 并把结果脱水为 internal facts。
// Stop-line: 不获取 drawable，不创建 command queue / command buffer / encoder，
// 不提交 GPU work，不返回 token 到 public surface，不写 runtime_state.cj。
// Same-shape Boundary Brake: device-layer binding facts 不得包装成 backend-ready、
// render-ready、drawable-ready、GPU submission、state write、receipt、record 或 publication。
package cjgui

foreign func cjgui_native_bridge_cametallayer_bind_metal_device(
    layerToken: UInt64,
    deviceToken: UInt64
): Int32
foreign func cjgui_native_bridge_cametallayer_unbind_metal_device(
    layerToken: UInt64,
    deviceToken: UInt64
): Int32
foreign func cjgui_native_bridge_cametallayer_device_binding_classify(
    layerToken: UInt64,
    deviceToken: UInt64
): Int32
foreign func cjgui_native_bridge_cametallayer_double_unbind_device_classify(
    layerToken: UInt64,
    deviceToken: UInt64
): Int32
foreign func cjgui_native_bridge_cametallayer_device_binding_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked():
    Int32

struct CjguiInternalRendererMetalDeviceLayerBindingObservation {
    let viewCreateStatusValue: Int32
    let layerCreateStatusValue: Int32
    let layerAttachStatusValue: Int32
    let deviceCreateStatusValue: Int32
    let bindStatusValue: Int32
    let boundClassValue: Int32
    let unbindStatusValue: Int32
    let unboundClassValue: Int32
    let doubleUnbindStatusValue: Int32
    let doubleUnbindClassValue: Int32
    let deviceDestroyStatusValue: Int32
    let layerDetachStatusValue: Int32
    let layerDestroyStatusValue: Int32
    let viewDestroyStatusValue: Int32
    let bindingRequiresMainThreadValue: Int32
    let drawableStillBlockedValue: Int32
    let commandQueueStillBlockedValue: Int32
    let viewOccupiedBeforeValue: UInt32
    let viewOccupiedAfterCleanupValue: UInt32
    let layerOccupiedBeforeValue: UInt32
    let layerOccupiedAfterCleanupValue: UInt32
    let deviceOccupiedBeforeValue: UInt32
    let deviceOccupiedAfterCleanupValue: UInt32
    let didObserveLocalTokens: Bool
    let didObserveAttachBeforeBinding: Bool
    let didObserveBind: Bool
    let didObserveBoundClassification: Bool
    let didObserveUnbind: Bool
    let didObserveUnboundClassification: Bool
    let didObserveDoubleUnbindFailClosed: Bool
    let didObserveCleanupCounts: Bool
    let didObserveMainThreadBindingGate: Bool
    let didObserveDrawableStillBlocked: Bool
    let didObserveCommandQueueStillBlocked: Bool
    let didKeepTokensFunctionLocal: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoDrawableQueueBufferOrRender: Bool

    init(
        viewCreateStatusValue: Int32,
        layerCreateStatusValue: Int32,
        layerAttachStatusValue: Int32,
        deviceCreateStatusValue: Int32,
        bindStatusValue: Int32,
        boundClassValue: Int32,
        unbindStatusValue: Int32,
        unboundClassValue: Int32,
        doubleUnbindStatusValue: Int32,
        doubleUnbindClassValue: Int32,
        deviceDestroyStatusValue: Int32,
        layerDetachStatusValue: Int32,
        layerDestroyStatusValue: Int32,
        viewDestroyStatusValue: Int32,
        bindingRequiresMainThreadValue: Int32,
        drawableStillBlockedValue: Int32,
        commandQueueStillBlockedValue: Int32,
        viewOccupiedBeforeValue: UInt32,
        viewOccupiedAfterCleanupValue: UInt32,
        layerOccupiedBeforeValue: UInt32,
        layerOccupiedAfterCleanupValue: UInt32,
        deviceOccupiedBeforeValue: UInt32,
        deviceOccupiedAfterCleanupValue: UInt32,
        didObserveLocalTokens: Bool,
        didObserveAttachBeforeBinding: Bool,
        didObserveBind: Bool,
        didObserveBoundClassification: Bool,
        didObserveUnbind: Bool,
        didObserveUnboundClassification: Bool,
        didObserveDoubleUnbindFailClosed: Bool,
        didObserveCleanupCounts: Bool,
        didObserveMainThreadBindingGate: Bool,
        didObserveDrawableStillBlocked: Bool,
        didObserveCommandQueueStillBlocked: Bool,
        didKeepTokensFunctionLocal: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoDrawableQueueBufferOrRender: Bool
    ) {
        this.viewCreateStatusValue = viewCreateStatusValue
        this.layerCreateStatusValue = layerCreateStatusValue
        this.layerAttachStatusValue = layerAttachStatusValue
        this.deviceCreateStatusValue = deviceCreateStatusValue
        this.bindStatusValue = bindStatusValue
        this.boundClassValue = boundClassValue
        this.unbindStatusValue = unbindStatusValue
        this.unboundClassValue = unboundClassValue
        this.doubleUnbindStatusValue = doubleUnbindStatusValue
        this.doubleUnbindClassValue = doubleUnbindClassValue
        this.deviceDestroyStatusValue = deviceDestroyStatusValue
        this.layerDetachStatusValue = layerDetachStatusValue
        this.layerDestroyStatusValue = layerDestroyStatusValue
        this.viewDestroyStatusValue = viewDestroyStatusValue
        this.bindingRequiresMainThreadValue = bindingRequiresMainThreadValue
        this.drawableStillBlockedValue = drawableStillBlockedValue
        this.commandQueueStillBlockedValue = commandQueueStillBlockedValue
        this.viewOccupiedBeforeValue = viewOccupiedBeforeValue
        this.viewOccupiedAfterCleanupValue = viewOccupiedAfterCleanupValue
        this.layerOccupiedBeforeValue = layerOccupiedBeforeValue
        this.layerOccupiedAfterCleanupValue = layerOccupiedAfterCleanupValue
        this.deviceOccupiedBeforeValue = deviceOccupiedBeforeValue
        this.deviceOccupiedAfterCleanupValue = deviceOccupiedAfterCleanupValue
        this.didObserveLocalTokens = didObserveLocalTokens
        this.didObserveAttachBeforeBinding = didObserveAttachBeforeBinding
        this.didObserveBind = didObserveBind
        this.didObserveBoundClassification = didObserveBoundClassification
        this.didObserveUnbind = didObserveUnbind
        this.didObserveUnboundClassification = didObserveUnboundClassification
        this.didObserveDoubleUnbindFailClosed =
            didObserveDoubleUnbindFailClosed
        this.didObserveCleanupCounts = didObserveCleanupCounts
        this.didObserveMainThreadBindingGate = didObserveMainThreadBindingGate
        this.didObserveDrawableStillBlocked = didObserveDrawableStillBlocked
        this.didObserveCommandQueueStillBlocked =
            didObserveCommandQueueStillBlocked
        this.didKeepTokensFunctionLocal = didKeepTokensFunctionLocal
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoDrawableQueueBufferOrRender =
            didConfirmNoDrawableQueueBufferOrRender
    }
}

struct CjguiInternalRendererNoMetalDeviceLayerBindingReadiness {
    let deviceCreateDestroyReadiness:
        CjguiInternalRendererNoMetalDeviceCreateDestroyReadiness
    let layerBindingObservation:
        CjguiInternalRendererMetalDeviceLayerBindingObservation
    let didPrepareRendererNoMetalDeviceLayerBindingReadiness: Bool
    let shouldDeferRendererNoMetalDeviceLayerBindingReadiness: Bool
    let shouldReportRendererNoMetalDeviceLayerBindingBlocked: Bool
    let didPreserveRendererMetalDeviceCreateDestroyReadiness: Bool
    let didConfirmTokenBackedLayerAndDeviceBinding: Bool
    let didConfirmMainThreadLayerBindingGate: Bool
    let didConfirmBindClassifyUnbindLifecycle: Bool
    let didConfirmDoubleUnbindFailClosed: Bool
    let didConfirmCleanupCountsReturnToZero: Bool
    let didConfirmNoDrawableAcquisition: Bool
    let didConfirmNoCommandQueueBufferEncoderOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepMetalDeviceLayerBindingReadinessDehydrated: Bool
    let didKeepTokensFunctionLocal: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        deviceCreateDestroyReadiness:
            CjguiInternalRendererNoMetalDeviceCreateDestroyReadiness,
        layerBindingObservation:
            CjguiInternalRendererMetalDeviceLayerBindingObservation,
        didPrepareRendererNoMetalDeviceLayerBindingReadiness: Bool,
        shouldDeferRendererNoMetalDeviceLayerBindingReadiness: Bool,
        shouldReportRendererNoMetalDeviceLayerBindingBlocked: Bool,
        didPreserveRendererMetalDeviceCreateDestroyReadiness: Bool,
        didConfirmTokenBackedLayerAndDeviceBinding: Bool,
        didConfirmMainThreadLayerBindingGate: Bool,
        didConfirmBindClassifyUnbindLifecycle: Bool,
        didConfirmDoubleUnbindFailClosed: Bool,
        didConfirmCleanupCountsReturnToZero: Bool,
        didConfirmNoDrawableAcquisition: Bool,
        didConfirmNoCommandQueueBufferEncoderOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepMetalDeviceLayerBindingReadinessDehydrated: Bool,
        didKeepTokensFunctionLocal: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.deviceCreateDestroyReadiness = deviceCreateDestroyReadiness
        this.layerBindingObservation = layerBindingObservation
        this.didPrepareRendererNoMetalDeviceLayerBindingReadiness =
            didPrepareRendererNoMetalDeviceLayerBindingReadiness
        this.shouldDeferRendererNoMetalDeviceLayerBindingReadiness =
            shouldDeferRendererNoMetalDeviceLayerBindingReadiness
        this.shouldReportRendererNoMetalDeviceLayerBindingBlocked =
            shouldReportRendererNoMetalDeviceLayerBindingBlocked
        this.didPreserveRendererMetalDeviceCreateDestroyReadiness =
            didPreserveRendererMetalDeviceCreateDestroyReadiness
        this.didConfirmTokenBackedLayerAndDeviceBinding =
            didConfirmTokenBackedLayerAndDeviceBinding
        this.didConfirmMainThreadLayerBindingGate =
            didConfirmMainThreadLayerBindingGate
        this.didConfirmBindClassifyUnbindLifecycle =
            didConfirmBindClassifyUnbindLifecycle
        this.didConfirmDoubleUnbindFailClosed =
            didConfirmDoubleUnbindFailClosed
        this.didConfirmCleanupCountsReturnToZero =
            didConfirmCleanupCountsReturnToZero
        this.didConfirmNoDrawableAcquisition =
            didConfirmNoDrawableAcquisition
        this.didConfirmNoCommandQueueBufferEncoderOrRender =
            didConfirmNoCommandQueueBufferEncoderOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepMetalDeviceLayerBindingReadinessDehydrated =
            didKeepMetalDeviceLayerBindingReadinessDehydrated
        this.didKeepTokensFunctionLocal = didKeepTokensFunctionLocal
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererMetalDeviceLayerBindingValues():
    CjguiInternalRendererMetalDeviceLayerBindingObservation {
    let viewOccupiedBefore = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    let layerOccupiedBefore = unsafe {
        cjgui_native_bridge_cametallayer_table_occupied_count()
    }
    let deviceOccupiedBefore = unsafe {
        cjgui_native_bridge_metal_device_table_occupied_count()
    }
    var viewToken = UInt64(0)
    var layerToken = UInt64(0)
    var deviceToken = UInt64(0)
    let viewCreateStatus = unsafe {
        cjgui_native_bridge_nsview_create(inout viewToken)
    }
    let layerCreateStatus = unsafe {
        cjgui_native_bridge_cametallayer_create(inout layerToken)
    }
    let layerAttachStatus = unsafe {
        cjgui_native_bridge_cametallayer_attach_to_nsview(
            layerToken,
            viewToken
        )
    }
    let deviceCreateStatus = unsafe {
        cjgui_native_bridge_metal_default_device_create(inout deviceToken)
    }
    let bindingRequiresMainThread = unsafe {
        cjgui_native_bridge_cametallayer_device_binding_requires_main_thread()
    }
    let drawableStillBlocked = unsafe {
        cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked()
    }
    let commandQueueStillBlocked = unsafe {
        cjgui_native_bridge_metal_device_command_queue_still_blocked()
    }
    let bindStatus = unsafe {
        cjgui_native_bridge_cametallayer_bind_metal_device(
            layerToken,
            deviceToken
        )
    }
    let boundClass = unsafe {
        cjgui_native_bridge_cametallayer_device_binding_classify(
            layerToken,
            deviceToken
        )
    }
    let unbindStatus = unsafe {
        cjgui_native_bridge_cametallayer_unbind_metal_device(
            layerToken,
            deviceToken
        )
    }
    let unboundClass = unsafe {
        cjgui_native_bridge_cametallayer_device_binding_classify(
            layerToken,
            deviceToken
        )
    }
    let doubleUnbindStatus = unsafe {
        cjgui_native_bridge_cametallayer_unbind_metal_device(
            layerToken,
            deviceToken
        )
    }
    let doubleUnbindClass = unsafe {
        cjgui_native_bridge_cametallayer_double_unbind_device_classify(
            layerToken,
            deviceToken
        )
    }
    let deviceDestroyStatus = unsafe {
        cjgui_native_bridge_metal_device_destroy(deviceToken)
    }
    let layerDetachStatus = unsafe {
        cjgui_native_bridge_cametallayer_detach_from_nsview(
            layerToken,
            viewToken
        )
    }
    let layerDestroyStatus = unsafe {
        cjgui_native_bridge_cametallayer_destroy(layerToken)
    }
    let viewDestroyStatus = unsafe {
        cjgui_native_bridge_nsview_destroy(viewToken)
    }
    let viewOccupiedAfterCleanup = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    let layerOccupiedAfterCleanup = unsafe {
        cjgui_native_bridge_cametallayer_table_occupied_count()
    }
    let deviceOccupiedAfterCleanup = unsafe {
        cjgui_native_bridge_metal_device_table_occupied_count()
    }

    return CjguiInternalRendererMetalDeviceLayerBindingObservation(
        viewCreateStatus,
        layerCreateStatus,
        layerAttachStatus,
        deviceCreateStatus,
        bindStatus,
        boundClass,
        unbindStatus,
        unboundClass,
        doubleUnbindStatus,
        doubleUnbindClass,
        deviceDestroyStatus,
        layerDetachStatus,
        layerDestroyStatus,
        viewDestroyStatus,
        bindingRequiresMainThread,
        drawableStillBlocked,
        commandQueueStillBlocked,
        viewOccupiedBefore,
        viewOccupiedAfterCleanup,
        layerOccupiedBefore,
        layerOccupiedAfterCleanup,
        deviceOccupiedBefore,
        deviceOccupiedAfterCleanup,
        viewCreateStatus == Int32(0) &&
            layerCreateStatus == Int32(0) &&
            deviceCreateStatus == Int32(0) &&
            viewToken != UInt64(0) &&
            layerToken != UInt64(0) &&
            deviceToken != UInt64(0),
        layerAttachStatus == Int32(0),
        bindStatus == Int32(0),
        boundClass == Int32(140),
        unbindStatus == Int32(0),
        unboundClass == Int32(-140),
        doubleUnbindStatus == Int32(-146) &&
            doubleUnbindClass == Int32(-146),
        deviceDestroyStatus == Int32(0) &&
            layerDetachStatus == Int32(0) &&
            layerDestroyStatus == Int32(0) &&
            viewDestroyStatus == Int32(0) &&
            viewOccupiedBefore == viewOccupiedAfterCleanup &&
            layerOccupiedBefore == layerOccupiedAfterCleanup &&
            deviceOccupiedBefore == deviceOccupiedAfterCleanup,
        bindingRequiresMainThread == Int32(-141),
        drawableStillBlocked == Int32(-150),
        commandQueueStillBlocked == Int32(-129),
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererMetalDeviceLayerBindingReadiness(
    deviceCreateDestroyReadiness:
        CjguiInternalRendererNoMetalDeviceCreateDestroyReadiness,
    layerBindingObservation:
        CjguiInternalRendererMetalDeviceLayerBindingObservation
): CjguiInternalRendererNoMetalDeviceLayerBindingReadiness {
    let upstreamReady =
        deviceCreateDestroyReadiness
            .didPrepareRendererNoMetalDeviceCreateDestroyReadiness &&
        deviceCreateDestroyReadiness.didConfirmCreateClassifyDestroyLifecycle &&
        deviceCreateDestroyReadiness.didConfirmNoCommandQueueDrawableOrRender &&
        deviceCreateDestroyReadiness.didConfirmNoPublicSurface &&
        deviceCreateDestroyReadiness.didConfirmNoRendererStateWrite &&
        deviceCreateDestroyReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        layerBindingObservation.didObserveLocalTokens &&
        layerBindingObservation.didObserveAttachBeforeBinding &&
        layerBindingObservation.didObserveBind &&
        layerBindingObservation.didObserveBoundClassification &&
        layerBindingObservation.didObserveUnbind &&
        layerBindingObservation.didObserveUnboundClassification &&
        layerBindingObservation.didObserveDoubleUnbindFailClosed &&
        layerBindingObservation.didObserveCleanupCounts &&
        layerBindingObservation.didObserveMainThreadBindingGate &&
        layerBindingObservation.didObserveDrawableStillBlocked &&
        layerBindingObservation.didObserveCommandQueueStillBlocked &&
        layerBindingObservation.didKeepTokensFunctionLocal &&
        layerBindingObservation.didConfirmNoPointerHandleClassIdReturn &&
        layerBindingObservation.didConfirmNoDrawableQueueBufferOrRender
    let readinessReady = upstreamReady && observationReady

    return CjguiInternalRendererNoMetalDeviceLayerBindingReadiness(
        deviceCreateDestroyReadiness,
        layerBindingObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        layerBindingObservation.didObserveLocalTokens &&
            layerBindingObservation.didObserveBind &&
            layerBindingObservation.didObserveBoundClassification,
        layerBindingObservation.didObserveMainThreadBindingGate,
        layerBindingObservation.didObserveBind &&
            layerBindingObservation.didObserveBoundClassification &&
            layerBindingObservation.didObserveUnbind &&
            layerBindingObservation.didObserveUnboundClassification,
        layerBindingObservation.didObserveDoubleUnbindFailClosed,
        layerBindingObservation.didObserveCleanupCounts,
        layerBindingObservation.didObserveDrawableStillBlocked,
        layerBindingObservation.didConfirmNoDrawableQueueBufferOrRender,
        layerBindingObservation.didConfirmNoPointerHandleClassIdReturn,
        true,
        true,
        true,
        true,
        layerBindingObservation.didKeepTokensFunctionLocal,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererMetalDeviceLayerBindingDraft():
    CjguiInternalRendererNoMetalDeviceLayerBindingReadiness {
    let deviceCreateDestroyReadiness =
        cjguiInternalExecuteDefaultRendererMetalDeviceCreateDestroyDraft()
    let layerBindingObservation =
        cjguiInternalObserveRendererMetalDeviceLayerBindingValues()
    return cjguiInternalBuildRendererMetalDeviceLayerBindingReadiness(
        deviceCreateDestroyReadiness,
        layerBindingObservation
    )
}
