// 维护注释：本文件是 CAMetalLayer attachment runtime FFI call owner。
// Truth: 只消费 CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness，
// 复用已验证 internal foreign declarations，执行局部 attach / classify /
// detach / cleanup 序列，并把结果脱水为 internal facts。
// Stop-line: 不 import Metal，不设置 CAMetalLayer.device，不获取 drawable，
// 不返回 token / pointer / handle / Class / id，不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: 不得把 runtime attachment facts 包成 backend-ready、
// render-ready、Metal device、drawable、GPU submission、state write 或 publication。
package cjgui

struct CjguiInternalRendererCAMetalLayerAttachmentRuntimeCallObservation {
    let viewCreateStatusValue: Int32
    let layerCreateStatusValue: Int32
    let attachStatusValue: Int32
    let attachedClassValue: Int32
    let detachStatusValue: Int32
    let detachedClassValue: Int32
    let doubleDetachStatusValue: Int32
    let doubleDetachClassValue: Int32
    let layerDestroyStatusValue: Int32
    let viewDestroyStatusValue: Int32
    let attachRequiresMainThreadValue: Int32
    let deviceBindingStillBlockedValue: Int32
    let nsviewOccupiedBeforeValue: UInt32
    let nsviewOccupiedAfterCleanupValue: UInt32
    let layerOccupiedBeforeValue: UInt32
    let layerOccupiedAfterCleanupValue: UInt32
    let didObserveCreateTokens: Bool
    let didObserveAttach: Bool
    let didObserveAttachedClassification: Bool
    let didObserveDetach: Bool
    let didObserveDetachedClassification: Bool
    let didObserveDoubleDetachFailClosed: Bool
    let didObserveCleanupCounts: Bool
    let didObserveMainThreadRequired: Bool
    let didObserveDeviceBindingStillBlocked: Bool
    let didKeepTokensFunctionLocal: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoMetalDeviceDrawableOrRender: Bool

    init(
        viewCreateStatusValue: Int32,
        layerCreateStatusValue: Int32,
        attachStatusValue: Int32,
        attachedClassValue: Int32,
        detachStatusValue: Int32,
        detachedClassValue: Int32,
        doubleDetachStatusValue: Int32,
        doubleDetachClassValue: Int32,
        layerDestroyStatusValue: Int32,
        viewDestroyStatusValue: Int32,
        attachRequiresMainThreadValue: Int32,
        deviceBindingStillBlockedValue: Int32,
        nsviewOccupiedBeforeValue: UInt32,
        nsviewOccupiedAfterCleanupValue: UInt32,
        layerOccupiedBeforeValue: UInt32,
        layerOccupiedAfterCleanupValue: UInt32,
        didObserveCreateTokens: Bool,
        didObserveAttach: Bool,
        didObserveAttachedClassification: Bool,
        didObserveDetach: Bool,
        didObserveDetachedClassification: Bool,
        didObserveDoubleDetachFailClosed: Bool,
        didObserveCleanupCounts: Bool,
        didObserveMainThreadRequired: Bool,
        didObserveDeviceBindingStillBlocked: Bool,
        didKeepTokensFunctionLocal: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoMetalDeviceDrawableOrRender: Bool
    ) {
        this.viewCreateStatusValue = viewCreateStatusValue
        this.layerCreateStatusValue = layerCreateStatusValue
        this.attachStatusValue = attachStatusValue
        this.attachedClassValue = attachedClassValue
        this.detachStatusValue = detachStatusValue
        this.detachedClassValue = detachedClassValue
        this.doubleDetachStatusValue = doubleDetachStatusValue
        this.doubleDetachClassValue = doubleDetachClassValue
        this.layerDestroyStatusValue = layerDestroyStatusValue
        this.viewDestroyStatusValue = viewDestroyStatusValue
        this.attachRequiresMainThreadValue = attachRequiresMainThreadValue
        this.deviceBindingStillBlockedValue = deviceBindingStillBlockedValue
        this.nsviewOccupiedBeforeValue = nsviewOccupiedBeforeValue
        this.nsviewOccupiedAfterCleanupValue =
            nsviewOccupiedAfterCleanupValue
        this.layerOccupiedBeforeValue = layerOccupiedBeforeValue
        this.layerOccupiedAfterCleanupValue =
            layerOccupiedAfterCleanupValue
        this.didObserveCreateTokens = didObserveCreateTokens
        this.didObserveAttach = didObserveAttach
        this.didObserveAttachedClassification =
            didObserveAttachedClassification
        this.didObserveDetach = didObserveDetach
        this.didObserveDetachedClassification =
            didObserveDetachedClassification
        this.didObserveDoubleDetachFailClosed =
            didObserveDoubleDetachFailClosed
        this.didObserveCleanupCounts = didObserveCleanupCounts
        this.didObserveMainThreadRequired = didObserveMainThreadRequired
        this.didObserveDeviceBindingStillBlocked =
            didObserveDeviceBindingStillBlocked
        this.didKeepTokensFunctionLocal = didKeepTokensFunctionLocal
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoMetalDeviceDrawableOrRender =
            didConfirmNoMetalDeviceDrawableOrRender
    }
}

struct CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness {
    let attachmentReadiness:
        CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness
    let runtimeCallObservation:
        CjguiInternalRendererCAMetalLayerAttachmentRuntimeCallObservation
    let didPrepareRendererNoCAMetalLayerAttachmentRuntimeCallReadiness:
        Bool
    let shouldDeferRendererNoCAMetalLayerAttachmentRuntimeCallReadiness:
        Bool
    let shouldReportRendererNoCAMetalLayerAttachmentRuntimeCallBlocked:
        Bool
    let didPreserveRendererCAMetalLayerNSViewAttachmentReadiness: Bool
    let didConfirmExistingForeignDeclarationsReused: Bool
    let didConfirmRuntimeInternalCallExecuted: Bool
    let didConfirmTokensStayedFunctionLocal: Bool
    let didConfirmAttachClassifyDetachLifecycle: Bool
    let didConfirmDoubleDetachFailClosed: Bool
    let didConfirmCleanupCountsReturnToZero: Bool
    let didConfirmMainThreadAttachmentGate: Bool
    let didConfirmDeviceBindingStillBlocked: Bool
    let didConfirmNoMetalDeviceDrawableOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepCAMetalLayerAttachmentRuntimeCallReadinessDehydrated:
        Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        attachmentReadiness:
            CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness,
        runtimeCallObservation:
            CjguiInternalRendererCAMetalLayerAttachmentRuntimeCallObservation,
        didPrepareRendererNoCAMetalLayerAttachmentRuntimeCallReadiness:
            Bool,
        shouldDeferRendererNoCAMetalLayerAttachmentRuntimeCallReadiness:
            Bool,
        shouldReportRendererNoCAMetalLayerAttachmentRuntimeCallBlocked:
            Bool,
        didPreserveRendererCAMetalLayerNSViewAttachmentReadiness: Bool,
        didConfirmExistingForeignDeclarationsReused: Bool,
        didConfirmRuntimeInternalCallExecuted: Bool,
        didConfirmTokensStayedFunctionLocal: Bool,
        didConfirmAttachClassifyDetachLifecycle: Bool,
        didConfirmDoubleDetachFailClosed: Bool,
        didConfirmCleanupCountsReturnToZero: Bool,
        didConfirmMainThreadAttachmentGate: Bool,
        didConfirmDeviceBindingStillBlocked: Bool,
        didConfirmNoMetalDeviceDrawableOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepCAMetalLayerAttachmentRuntimeCallReadinessDehydrated:
            Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.attachmentReadiness = attachmentReadiness
        this.runtimeCallObservation = runtimeCallObservation
        this
            .didPrepareRendererNoCAMetalLayerAttachmentRuntimeCallReadiness =
            didPrepareRendererNoCAMetalLayerAttachmentRuntimeCallReadiness
        this.shouldDeferRendererNoCAMetalLayerAttachmentRuntimeCallReadiness =
            shouldDeferRendererNoCAMetalLayerAttachmentRuntimeCallReadiness
        this.shouldReportRendererNoCAMetalLayerAttachmentRuntimeCallBlocked =
            shouldReportRendererNoCAMetalLayerAttachmentRuntimeCallBlocked
        this.didPreserveRendererCAMetalLayerNSViewAttachmentReadiness =
            didPreserveRendererCAMetalLayerNSViewAttachmentReadiness
        this.didConfirmExistingForeignDeclarationsReused =
            didConfirmExistingForeignDeclarationsReused
        this.didConfirmRuntimeInternalCallExecuted =
            didConfirmRuntimeInternalCallExecuted
        this.didConfirmTokensStayedFunctionLocal =
            didConfirmTokensStayedFunctionLocal
        this.didConfirmAttachClassifyDetachLifecycle =
            didConfirmAttachClassifyDetachLifecycle
        this.didConfirmDoubleDetachFailClosed =
            didConfirmDoubleDetachFailClosed
        this.didConfirmCleanupCountsReturnToZero =
            didConfirmCleanupCountsReturnToZero
        this.didConfirmMainThreadAttachmentGate =
            didConfirmMainThreadAttachmentGate
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
        this.didKeepCAMetalLayerAttachmentRuntimeCallReadinessDehydrated =
            didKeepCAMetalLayerAttachmentRuntimeCallReadinessDehydrated
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererCAMetalLayerAttachmentRuntimeCallValues():
    CjguiInternalRendererCAMetalLayerAttachmentRuntimeCallObservation {
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
    let nsviewOccupiedAfterCleanup = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    let layerOccupiedAfterCleanup = unsafe {
        cjgui_native_bridge_cametallayer_table_occupied_count()
    }

    return CjguiInternalRendererCAMetalLayerAttachmentRuntimeCallObservation(
        viewCreateStatus,
        layerCreateStatus,
        attachStatus,
        attachedClass,
        detachStatus,
        detachedClass,
        doubleDetachStatus,
        doubleDetachClass,
        layerDestroyStatus,
        viewDestroyStatus,
        attachRequiresMainThread,
        deviceBindingStillBlocked,
        nsviewOccupiedBefore,
        nsviewOccupiedAfterCleanup,
        layerOccupiedBefore,
        layerOccupiedAfterCleanup,
        viewCreateStatus == Int32(0) &&
            layerCreateStatus == Int32(0) &&
            viewToken != UInt64(0) &&
            layerToken != UInt64(0),
        attachStatus == Int32(0),
        attachedClass == Int32(90),
        detachStatus == Int32(0),
        detachedClass == Int32(-90),
        doubleDetachStatus == Int32(-96) &&
            doubleDetachClass == Int32(-96),
        layerDestroyStatus == Int32(0) &&
            viewDestroyStatus == Int32(0) &&
            nsviewOccupiedBefore == UInt32(0) &&
            layerOccupiedBefore == UInt32(0) &&
            nsviewOccupiedAfterCleanup == UInt32(0) &&
            layerOccupiedAfterCleanup == UInt32(0),
        attachRequiresMainThread == Int32(-91),
        deviceBindingStillBlocked == Int32(-100),
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererCAMetalLayerAttachmentRuntimeCallReadiness(
    attachmentReadiness:
        CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness,
    runtimeCallObservation:
        CjguiInternalRendererCAMetalLayerAttachmentRuntimeCallObservation
): CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness {
    let upstreamReady =
        attachmentReadiness
            .didPrepareRendererNoCAMetalLayerNSViewAttachmentReadiness &&
        attachmentReadiness.didConfirmAttachClassifyDetachLifecycle &&
        attachmentReadiness.didConfirmCleanupCountsReturnToZero &&
        attachmentReadiness.didConfirmDeviceBindingStillBlocked &&
        attachmentReadiness.didConfirmNoMetalDeviceDrawableOrRender &&
        attachmentReadiness.didConfirmNoPublicSurface &&
        attachmentReadiness.didConfirmNoRendererStateWrite &&
        attachmentReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        runtimeCallObservation.didObserveCreateTokens &&
        runtimeCallObservation.didObserveAttach &&
        runtimeCallObservation.didObserveAttachedClassification &&
        runtimeCallObservation.didObserveDetach &&
        runtimeCallObservation.didObserveDetachedClassification &&
        runtimeCallObservation.didObserveDoubleDetachFailClosed &&
        runtimeCallObservation.didObserveCleanupCounts &&
        runtimeCallObservation.didObserveMainThreadRequired &&
        runtimeCallObservation.didObserveDeviceBindingStillBlocked &&
        runtimeCallObservation.didKeepTokensFunctionLocal &&
        runtimeCallObservation.didConfirmNoPointerHandleClassIdReturn &&
        runtimeCallObservation.didConfirmNoMetalDeviceDrawableOrRender
    let readinessReady = upstreamReady && observationReady

    return CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness(
        attachmentReadiness,
        runtimeCallObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        true,
        observationReady,
        runtimeCallObservation.didKeepTokensFunctionLocal,
        runtimeCallObservation.didObserveAttach &&
            runtimeCallObservation.didObserveAttachedClassification &&
            runtimeCallObservation.didObserveDetach &&
            runtimeCallObservation.didObserveDetachedClassification,
        runtimeCallObservation.didObserveDoubleDetachFailClosed,
        runtimeCallObservation.didObserveCleanupCounts,
        runtimeCallObservation.didObserveMainThreadRequired,
        runtimeCallObservation.didObserveDeviceBindingStillBlocked,
        runtimeCallObservation.didConfirmNoMetalDeviceDrawableOrRender,
        runtimeCallObservation.didConfirmNoPointerHandleClassIdReturn,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererCAMetalLayerAttachmentRuntimeCallDraft():
    CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness {
    let attachmentReadiness =
        cjguiInternalExecuteDefaultRendererCAMetalLayerNSViewAttachmentDraft()
    let runtimeCallObservation =
        cjguiInternalObserveRendererCAMetalLayerAttachmentRuntimeCallValues()
    return cjguiInternalBuildRendererCAMetalLayerAttachmentRuntimeCallReadiness(
        attachmentReadiness,
        runtimeCallObservation
    )
}
