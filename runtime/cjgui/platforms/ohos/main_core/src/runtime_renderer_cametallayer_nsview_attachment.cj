// 维护注释：本文件是 CAMetalLayer token-backed NSView attachment first-slice owner。
// Truth: 只消费 CjguiInternalRendererNoCAMetalLayerCreateDestroyReadiness，
// 调用 attach / detach / classify C ABI，并把返回值脱水为 internal facts。
// Stop-line: 不 import Metal，不设置 CAMetalLayer.device，不获取 drawable，
// 不返回 pointer / handle / Class / id，不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: 不得把 attachment facts 包成 backend-ready、render-ready、
// Metal device、drawable、GPU submission、state write 或 publication。
package cjgui

foreign func cjgui_native_bridge_cametallayer_attach_to_nsview(
    layerToken: UInt64,
    viewToken: UInt64
): Int32
foreign func cjgui_native_bridge_cametallayer_detach_from_nsview(
    layerToken: UInt64,
    viewToken: UInt64
): Int32
foreign func cjgui_native_bridge_cametallayer_attachment_classify(
    layerToken: UInt64,
    viewToken: UInt64
): Int32
foreign func cjgui_native_bridge_cametallayer_double_detach_classify(
    layerToken: UInt64,
    viewToken: UInt64
): Int32
foreign func cjgui_native_bridge_cametallayer_attach_requires_main_thread():
    Int32
foreign func
cjgui_native_bridge_cametallayer_device_binding_after_attach_still_blocked():
    Int32

struct CjguiInternalRendererCAMetalLayerNSViewAttachmentObservation {
    let viewCreateStatusValue: Int32
    let layerCreateStatusValue: Int32
    let attachStatusValue: Int32
    let attachedClassValue: Int32
    let doubleAttachStatusValue: Int32
    let detachStatusValue: Int32
    let detachedClassValue: Int32
    let doubleDetachStatusValue: Int32
    let doubleDetachClassValue: Int32
    let invalidAttachStatusValue: Int32
    let layerDestroyStatusValue: Int32
    let viewDestroyStatusValue: Int32
    let staleAttachmentClassValue: Int32
    let attachRequiresMainThreadValue: Int32
    let deviceBindingStillBlockedValue: Int32
    let nsviewOccupiedBeforeValue: UInt32
    let nsviewOccupiedAfterCleanupValue: UInt32
    let layerOccupiedBeforeValue: UInt32
    let layerOccupiedAfterCleanupValue: UInt32
    let didObserveCreateTokens: Bool
    let didObserveAttach: Bool
    let didObserveAttachedClassification: Bool
    let didObserveDoubleAttachFailClosed: Bool
    let didObserveDetach: Bool
    let didObserveDetachedClassification: Bool
    let didObserveDoubleDetachFailClosed: Bool
    let didObserveInvalidTokenFailClosed: Bool
    let didObserveStaleTokenFailClosed: Bool
    let didObserveCleanupCounts: Bool
    let didObserveMainThreadRequired: Bool
    let didObserveDeviceBindingStillBlocked: Bool

    init(
        viewCreateStatusValue: Int32,
        layerCreateStatusValue: Int32,
        attachStatusValue: Int32,
        attachedClassValue: Int32,
        doubleAttachStatusValue: Int32,
        detachStatusValue: Int32,
        detachedClassValue: Int32,
        doubleDetachStatusValue: Int32,
        doubleDetachClassValue: Int32,
        invalidAttachStatusValue: Int32,
        layerDestroyStatusValue: Int32,
        viewDestroyStatusValue: Int32,
        staleAttachmentClassValue: Int32,
        attachRequiresMainThreadValue: Int32,
        deviceBindingStillBlockedValue: Int32,
        nsviewOccupiedBeforeValue: UInt32,
        nsviewOccupiedAfterCleanupValue: UInt32,
        layerOccupiedBeforeValue: UInt32,
        layerOccupiedAfterCleanupValue: UInt32,
        didObserveCreateTokens: Bool,
        didObserveAttach: Bool,
        didObserveAttachedClassification: Bool,
        didObserveDoubleAttachFailClosed: Bool,
        didObserveDetach: Bool,
        didObserveDetachedClassification: Bool,
        didObserveDoubleDetachFailClosed: Bool,
        didObserveInvalidTokenFailClosed: Bool,
        didObserveStaleTokenFailClosed: Bool,
        didObserveCleanupCounts: Bool,
        didObserveMainThreadRequired: Bool,
        didObserveDeviceBindingStillBlocked: Bool
    ) {
        this.viewCreateStatusValue = viewCreateStatusValue
        this.layerCreateStatusValue = layerCreateStatusValue
        this.attachStatusValue = attachStatusValue
        this.attachedClassValue = attachedClassValue
        this.doubleAttachStatusValue = doubleAttachStatusValue
        this.detachStatusValue = detachStatusValue
        this.detachedClassValue = detachedClassValue
        this.doubleDetachStatusValue = doubleDetachStatusValue
        this.doubleDetachClassValue = doubleDetachClassValue
        this.invalidAttachStatusValue = invalidAttachStatusValue
        this.layerDestroyStatusValue = layerDestroyStatusValue
        this.viewDestroyStatusValue = viewDestroyStatusValue
        this.staleAttachmentClassValue = staleAttachmentClassValue
        this.attachRequiresMainThreadValue = attachRequiresMainThreadValue
        this.deviceBindingStillBlockedValue = deviceBindingStillBlockedValue
        this.nsviewOccupiedBeforeValue = nsviewOccupiedBeforeValue
        this.nsviewOccupiedAfterCleanupValue = nsviewOccupiedAfterCleanupValue
        this.layerOccupiedBeforeValue = layerOccupiedBeforeValue
        this.layerOccupiedAfterCleanupValue = layerOccupiedAfterCleanupValue
        this.didObserveCreateTokens = didObserveCreateTokens
        this.didObserveAttach = didObserveAttach
        this.didObserveAttachedClassification = didObserveAttachedClassification
        this.didObserveDoubleAttachFailClosed =
            didObserveDoubleAttachFailClosed
        this.didObserveDetach = didObserveDetach
        this.didObserveDetachedClassification =
            didObserveDetachedClassification
        this.didObserveDoubleDetachFailClosed =
            didObserveDoubleDetachFailClosed
        this.didObserveInvalidTokenFailClosed =
            didObserveInvalidTokenFailClosed
        this.didObserveStaleTokenFailClosed = didObserveStaleTokenFailClosed
        this.didObserveCleanupCounts = didObserveCleanupCounts
        this.didObserveMainThreadRequired = didObserveMainThreadRequired
        this.didObserveDeviceBindingStillBlocked =
            didObserveDeviceBindingStillBlocked
    }
}

struct CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness {
    let didPrepareRendererNoCAMetalLayerNSViewAttachmentReadiness: Bool
    let shouldDeferRendererNoCAMetalLayerNSViewAttachmentReadiness: Bool
    let shouldReportRendererNoCAMetalLayerNSViewAttachmentBlocked: Bool
    let didPreserveRendererCAMetalLayerCreateDestroyReadiness: Bool
    let didConfirmTokenBackedNSViewAndLayerInputs: Bool
    let didConfirmMainThreadAttachmentGate: Bool
    let didConfirmAttachClassifyDetachLifecycle: Bool
    let didConfirmDoubleAttachFailClosed: Bool
    let didConfirmDoubleDetachFailClosed: Bool
    let didConfirmInvalidAndStaleTokenFailClosed: Bool
    let didConfirmCleanupCountsReturnToZero: Bool
    let didConfirmDeviceBindingStillBlocked: Bool
    let didConfirmNoMetalDeviceDrawableOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepCAMetalLayerNSViewAttachmentReadinessDehydrated: Bool
    let didAvoidMetalReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        didPrepareRendererNoCAMetalLayerNSViewAttachmentReadiness: Bool,
        shouldDeferRendererNoCAMetalLayerNSViewAttachmentReadiness: Bool,
        shouldReportRendererNoCAMetalLayerNSViewAttachmentBlocked: Bool,
        didPreserveRendererCAMetalLayerCreateDestroyReadiness: Bool,
        didConfirmTokenBackedNSViewAndLayerInputs: Bool,
        didConfirmMainThreadAttachmentGate: Bool,
        didConfirmAttachClassifyDetachLifecycle: Bool,
        didConfirmDoubleAttachFailClosed: Bool,
        didConfirmDoubleDetachFailClosed: Bool,
        didConfirmInvalidAndStaleTokenFailClosed: Bool,
        didConfirmCleanupCountsReturnToZero: Bool,
        didConfirmDeviceBindingStillBlocked: Bool,
        didConfirmNoMetalDeviceDrawableOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepCAMetalLayerNSViewAttachmentReadinessDehydrated: Bool,
        didAvoidMetalReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.didPrepareRendererNoCAMetalLayerNSViewAttachmentReadiness =
            didPrepareRendererNoCAMetalLayerNSViewAttachmentReadiness
        this.shouldDeferRendererNoCAMetalLayerNSViewAttachmentReadiness =
            shouldDeferRendererNoCAMetalLayerNSViewAttachmentReadiness
        this.shouldReportRendererNoCAMetalLayerNSViewAttachmentBlocked =
            shouldReportRendererNoCAMetalLayerNSViewAttachmentBlocked
        this.didPreserveRendererCAMetalLayerCreateDestroyReadiness =
            didPreserveRendererCAMetalLayerCreateDestroyReadiness
        this.didConfirmTokenBackedNSViewAndLayerInputs =
            didConfirmTokenBackedNSViewAndLayerInputs
        this.didConfirmMainThreadAttachmentGate =
            didConfirmMainThreadAttachmentGate
        this.didConfirmAttachClassifyDetachLifecycle =
            didConfirmAttachClassifyDetachLifecycle
        this.didConfirmDoubleAttachFailClosed =
            didConfirmDoubleAttachFailClosed
        this.didConfirmDoubleDetachFailClosed =
            didConfirmDoubleDetachFailClosed
        this.didConfirmInvalidAndStaleTokenFailClosed =
            didConfirmInvalidAndStaleTokenFailClosed
        this.didConfirmCleanupCountsReturnToZero =
            didConfirmCleanupCountsReturnToZero
        this.didConfirmDeviceBindingStillBlocked =
            didConfirmDeviceBindingStillBlocked
        this.didConfirmNoMetalDeviceDrawableOrRender =
            didConfirmNoMetalDeviceDrawableOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth =
            didConfirmNoBackendReadyTruth
        this.didKeepCAMetalLayerNSViewAttachmentReadinessDehydrated =
            didKeepCAMetalLayerNSViewAttachmentReadinessDehydrated
        this.didAvoidMetalReadyWrapper = didAvoidMetalReadyWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
    }
}

func cjguiInternalObserveRendererCAMetalLayerNSViewAttachmentValues():
    CjguiInternalRendererCAMetalLayerNSViewAttachmentObservation {
    let nsviewOccupiedBefore = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    let layerOccupiedBefore = unsafe {
        cjgui_native_bridge_cametallayer_table_occupied_count()
    }

    var viewToken = UInt64(0)
    var layerToken = UInt64(0)
    let viewCreateStatus = unsafe {
        cjgui_native_bridge_nsview_create(inout viewToken)
    }
    let layerCreateStatus = unsafe {
        cjgui_native_bridge_cametallayer_create(inout layerToken)
    }
    let attachRequiresMainThread = unsafe {
        cjgui_native_bridge_cametallayer_attach_requires_main_thread()
    }
    let deviceBindingStillBlocked = unsafe {
        cjgui_native_bridge_cametallayer_device_binding_after_attach_still_blocked()
    }
    let invalidAttachStatus = unsafe {
        cjgui_native_bridge_cametallayer_attach_to_nsview(
            UInt64(0),
            viewToken
        )
    }
    let attachStatus = unsafe {
        cjgui_native_bridge_cametallayer_attach_to_nsview(
            layerToken,
            viewToken
        )
    }
    let attachedClass = unsafe {
        cjgui_native_bridge_cametallayer_attachment_classify(
            layerToken,
            viewToken
        )
    }
    let doubleAttachStatus = unsafe {
        cjgui_native_bridge_cametallayer_attach_to_nsview(
            layerToken,
            viewToken
        )
    }
    let detachStatus = unsafe {
        cjgui_native_bridge_cametallayer_detach_from_nsview(
            layerToken,
            viewToken
        )
    }
    let detachedClass = unsafe {
        cjgui_native_bridge_cametallayer_attachment_classify(
            layerToken,
            viewToken
        )
    }
    let doubleDetachStatus = unsafe {
        cjgui_native_bridge_cametallayer_detach_from_nsview(
            layerToken,
            viewToken
        )
    }
    let doubleDetachClass = unsafe {
        cjgui_native_bridge_cametallayer_double_detach_classify(
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
    let staleAttachmentClass = unsafe {
        cjgui_native_bridge_cametallayer_attachment_classify(
            layerToken,
            viewToken
        )
    }
    let nsviewOccupiedAfterCleanup = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    let layerOccupiedAfterCleanup = unsafe {
        cjgui_native_bridge_cametallayer_table_occupied_count()
    }

    return CjguiInternalRendererCAMetalLayerNSViewAttachmentObservation(
        viewCreateStatus,
        layerCreateStatus,
        attachStatus,
        attachedClass,
        doubleAttachStatus,
        detachStatus,
        detachedClass,
        doubleDetachStatus,
        doubleDetachClass,
        invalidAttachStatus,
        layerDestroyStatus,
        viewDestroyStatus,
        staleAttachmentClass,
        attachRequiresMainThread,
        deviceBindingStillBlocked,
        nsviewOccupiedBefore,
        nsviewOccupiedAfterCleanup,
        layerOccupiedBefore,
        layerOccupiedAfterCleanup,
        viewCreateStatus == 0 &&
            layerCreateStatus == 0 &&
            viewToken != UInt64(0) &&
            layerToken != UInt64(0),
        attachStatus == 0,
        attachedClass == 90,
        doubleAttachStatus == -97,
        detachStatus == 0,
        detachedClass == -90,
        doubleDetachStatus == -96 &&
            doubleDetachClass == -96,
        invalidAttachStatus == -92,
        staleAttachmentClass == -94,
        nsviewOccupiedBefore == 0 &&
            layerOccupiedBefore == 0 &&
            nsviewOccupiedAfterCleanup == 0 &&
            layerOccupiedAfterCleanup == 0,
        attachRequiresMainThread == -91,
        deviceBindingStillBlocked == -100
    )
}

func cjguiInternalBuildRendererCAMetalLayerNSViewAttachmentReadiness(
    input: CjguiInternalRendererNoCAMetalLayerCreateDestroyReadiness,
    observation: CjguiInternalRendererCAMetalLayerNSViewAttachmentObservation
): CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness {
    let upstreamReady =
        input.didPrepareRendererNoCAMetalLayerCreateDestroyReadiness &&
        input.didConfirmCreateClassifyDestroyLifecycle &&
        input.didConfirmNoDeviceDrawableOrRender
    let attachmentReady = upstreamReady &&
        observation.didObserveCreateTokens &&
        observation.didObserveAttach &&
        observation.didObserveAttachedClassification &&
        observation.didObserveDoubleAttachFailClosed &&
        observation.didObserveDetach &&
        observation.didObserveDetachedClassification &&
        observation.didObserveDoubleDetachFailClosed &&
        observation.didObserveInvalidTokenFailClosed &&
        observation.didObserveStaleTokenFailClosed &&
        observation.didObserveCleanupCounts &&
        observation.didObserveMainThreadRequired &&
        observation.didObserveDeviceBindingStillBlocked

    return CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness(
        attachmentReady,
        !attachmentReady,
        !attachmentReady,
        upstreamReady,
        observation.didObserveCreateTokens,
        observation.didObserveMainThreadRequired,
        observation.didObserveAttach &&
            observation.didObserveAttachedClassification &&
            observation.didObserveDetach &&
            observation.didObserveDetachedClassification,
        observation.didObserveDoubleAttachFailClosed,
        observation.didObserveDoubleDetachFailClosed,
        observation.didObserveInvalidTokenFailClosed &&
            observation.didObserveStaleTokenFailClosed,
        observation.didObserveCleanupCounts,
        observation.didObserveDeviceBindingStillBlocked,
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

func cjguiInternalExecuteDefaultRendererCAMetalLayerNSViewAttachmentDraft():
    CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness {
    let input = cjguiInternalExecuteDefaultRendererCAMetalLayerCreateDestroyDraft()
    let observation =
        cjguiInternalObserveRendererCAMetalLayerNSViewAttachmentValues()
    return cjguiInternalBuildRendererCAMetalLayerNSViewAttachmentReadiness(
        input,
        observation
    )
}
