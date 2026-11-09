// Owner: platform object NSView object table no-allocation internal owner。
// Truth: 只消费 CjguiInternalRendererNoPlatformObjectNsViewAllocationReadiness，
// 调用 NSView table shell no-allocation C ABI，并把固定容量、empty、
// fail-closed token classification、allocation blocked 与 destroy blocked
// 返回值脱水为 internal facts。
// Stop-line: 不创建或保存 NSView，不绑定 token 到 native object，不返回
// Class / id / pointer / handle，不实现 retention table，不写 runtime_state.cj。
// Same-shape Boundary Brake: 不得把本 owner 包成 NSView retention、
// platform object creation、native handle、Metal / QuartzCore、backend-ready、
// renderer state write、render、receipt、record 或 publication wrapper。
package cjgui

foreign func cjgui_native_bridge_nsview_table_capacity(): UInt32
foreign func cjgui_native_bridge_nsview_table_enabled(): UInt32
foreign func cjgui_native_bridge_nsview_table_empty(): Int32
foreign func cjgui_native_bridge_nsview_table_token_classify(token: UInt64):
    Int32
foreign func cjgui_native_bridge_nsview_table_allocation_still_blocked():
    Int32
foreign func cjgui_native_bridge_nsview_table_destroy_still_blocked():
    Int32

struct CjguiInternalRendererPlatformObjectNsViewObjectTableObservation {
    let tableCapacityValue: UInt32
    let tableEnabledValue: UInt32
    let tableEmptyValue: Int32
    let invalidTokenClassValue: Int32
    let allocationBlockedValue: Int32
    let destroyBlockedValue: Int32
    let didObserveFixedSmallCapacity: Bool
    let didObserveTableEnabled: Bool
    let didObserveTableEmpty: Bool
    let didClassifyInvalidTokenFailClosed: Bool
    let didObserveAllocationStillBlocked: Bool
    let didObserveDestroyStillBlocked: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoNsViewAllocationOrStorage: Bool
    let didConfirmNoMetalQuartzCoreUsage: Bool

    init(
        tableCapacityValue: UInt32,
        tableEnabledValue: UInt32,
        tableEmptyValue: Int32,
        invalidTokenClassValue: Int32,
        allocationBlockedValue: Int32,
        destroyBlockedValue: Int32,
        didObserveFixedSmallCapacity: Bool,
        didObserveTableEnabled: Bool,
        didObserveTableEmpty: Bool,
        didClassifyInvalidTokenFailClosed: Bool,
        didObserveAllocationStillBlocked: Bool,
        didObserveDestroyStillBlocked: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoNsViewAllocationOrStorage: Bool,
        didConfirmNoMetalQuartzCoreUsage: Bool
    ) {
        this.tableCapacityValue = tableCapacityValue
        this.tableEnabledValue = tableEnabledValue
        this.tableEmptyValue = tableEmptyValue
        this.invalidTokenClassValue = invalidTokenClassValue
        this.allocationBlockedValue = allocationBlockedValue
        this.destroyBlockedValue = destroyBlockedValue
        this.didObserveFixedSmallCapacity = didObserveFixedSmallCapacity
        this.didObserveTableEnabled = didObserveTableEnabled
        this.didObserveTableEmpty = didObserveTableEmpty
        this.didClassifyInvalidTokenFailClosed =
            didClassifyInvalidTokenFailClosed
        this.didObserveAllocationStillBlocked =
            didObserveAllocationStillBlocked
        this.didObserveDestroyStillBlocked = didObserveDestroyStillBlocked
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoNsViewAllocationOrStorage =
            didConfirmNoNsViewAllocationOrStorage
        this.didConfirmNoMetalQuartzCoreUsage =
            didConfirmNoMetalQuartzCoreUsage
    }
}

struct CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness {
    let nsViewAllocationReadiness:
        CjguiInternalRendererNoPlatformObjectNsViewAllocationReadiness
    let objectTableObservation:
        CjguiInternalRendererPlatformObjectNsViewObjectTableObservation
    let didPrepareRendererNoPlatformObjectNsViewObjectTableReadiness:
        Bool
    let shouldDeferRendererNoPlatformObjectNsViewObjectTableReadiness:
        Bool
    let shouldReportRendererNoPlatformObjectNsViewObjectTableBlocked:
        Bool
    let didPreserveRendererPlatformObjectNsViewAllocationReadiness: Bool
    let didConfirmFixedCapacityNsViewTableShell: Bool
    let didConfirmTableEnabled: Bool
    let didConfirmTableEmpty: Bool
    let didConfirmTokenClassificationFailClosed: Bool
    let didConfirmAllocationStillBlocked: Bool
    let didConfirmDestroyStillBlocked: Bool
    let didConfirmMainThreadConfinementPolicy: Bool
    let didConfirmNoNsViewAllocation: Bool
    let didConfirmNoLongLivedNsViewStorage: Bool
    let didConfirmNoTokenBindingToNativeObject: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoNsWindowNsApplicationLayerMetal: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNsViewObjectTableReadinessDehydrated: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        nsViewAllocationReadiness:
            CjguiInternalRendererNoPlatformObjectNsViewAllocationReadiness,
        objectTableObservation:
            CjguiInternalRendererPlatformObjectNsViewObjectTableObservation,
        didPrepareRendererNoPlatformObjectNsViewObjectTableReadiness:
            Bool,
        shouldDeferRendererNoPlatformObjectNsViewObjectTableReadiness:
            Bool,
        shouldReportRendererNoPlatformObjectNsViewObjectTableBlocked:
            Bool,
        didPreserveRendererPlatformObjectNsViewAllocationReadiness:
            Bool,
        didConfirmFixedCapacityNsViewTableShell: Bool,
        didConfirmTableEnabled: Bool,
        didConfirmTableEmpty: Bool,
        didConfirmTokenClassificationFailClosed: Bool,
        didConfirmAllocationStillBlocked: Bool,
        didConfirmDestroyStillBlocked: Bool,
        didConfirmMainThreadConfinementPolicy: Bool,
        didConfirmNoNsViewAllocation: Bool,
        didConfirmNoLongLivedNsViewStorage: Bool,
        didConfirmNoTokenBindingToNativeObject: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoNsWindowNsApplicationLayerMetal: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNsViewObjectTableReadinessDehydrated: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.nsViewAllocationReadiness = nsViewAllocationReadiness
        this.objectTableObservation = objectTableObservation
        this
            .didPrepareRendererNoPlatformObjectNsViewObjectTableReadiness =
            didPrepareRendererNoPlatformObjectNsViewObjectTableReadiness
        this.shouldDeferRendererNoPlatformObjectNsViewObjectTableReadiness =
            shouldDeferRendererNoPlatformObjectNsViewObjectTableReadiness
        this.shouldReportRendererNoPlatformObjectNsViewObjectTableBlocked =
            shouldReportRendererNoPlatformObjectNsViewObjectTableBlocked
        this.didPreserveRendererPlatformObjectNsViewAllocationReadiness =
            didPreserveRendererPlatformObjectNsViewAllocationReadiness
        this.didConfirmFixedCapacityNsViewTableShell =
            didConfirmFixedCapacityNsViewTableShell
        this.didConfirmTableEnabled = didConfirmTableEnabled
        this.didConfirmTableEmpty = didConfirmTableEmpty
        this.didConfirmTokenClassificationFailClosed =
            didConfirmTokenClassificationFailClosed
        this.didConfirmAllocationStillBlocked =
            didConfirmAllocationStillBlocked
        this.didConfirmDestroyStillBlocked = didConfirmDestroyStillBlocked
        this.didConfirmMainThreadConfinementPolicy =
            didConfirmMainThreadConfinementPolicy
        this.didConfirmNoNsViewAllocation = didConfirmNoNsViewAllocation
        this.didConfirmNoLongLivedNsViewStorage =
            didConfirmNoLongLivedNsViewStorage
        this.didConfirmNoTokenBindingToNativeObject =
            didConfirmNoTokenBindingToNativeObject
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoNsWindowNsApplicationLayerMetal =
            didConfirmNoNsWindowNsApplicationLayerMetal
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth =
            didConfirmNoBackendReadyTruth
        this.didKeepNsViewObjectTableReadinessDehydrated =
            didKeepNsViewObjectTableReadinessDehydrated
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererPlatformObjectNsViewObjectTableValues():
    CjguiInternalRendererPlatformObjectNsViewObjectTableObservation {
    let tableCapacity = unsafe {
        cjgui_native_bridge_nsview_table_capacity()
    }
    let tableEnabled = unsafe {
        cjgui_native_bridge_nsview_table_enabled()
    }
    let tableEmpty = unsafe {
        cjgui_native_bridge_nsview_table_empty()
    }
    let invalidTokenClass = unsafe {
        cjgui_native_bridge_nsview_table_token_classify(UInt64(0))
    }
    let allocationBlocked = unsafe {
        cjgui_native_bridge_nsview_table_allocation_still_blocked()
    }
    let destroyBlocked = unsafe {
        cjgui_native_bridge_nsview_table_destroy_still_blocked()
    }
    return CjguiInternalRendererPlatformObjectNsViewObjectTableObservation(
        tableCapacity,
        tableEnabled,
        tableEmpty,
        invalidTokenClass,
        allocationBlocked,
        destroyBlocked,
        tableCapacity == UInt32(4),
        tableEnabled == UInt32(1),
        tableEmpty == Int32(30),
        invalidTokenClass == Int32(0),
        allocationBlocked == Int32(-31),
        destroyBlocked == Int32(-32),
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererPlatformObjectNsViewObjectTableReadiness(
    nsViewAllocationReadiness:
        CjguiInternalRendererNoPlatformObjectNsViewAllocationReadiness,
    objectTableObservation:
        CjguiInternalRendererPlatformObjectNsViewObjectTableObservation
): CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness {
    let upstreamReady =
        nsViewAllocationReadiness
            .didPrepareRendererNoPlatformObjectNsViewAllocationReadiness &&
        nsViewAllocationReadiness.didConfirmNsViewAllocationFeasibilityIntent &&
        nsViewAllocationReadiness.didConfirmMainThreadAllocationGate &&
        nsViewAllocationReadiness
            .didConfirmImmediateReleaseFeasibilityRoute &&
        nsViewAllocationReadiness.didConfirmTokenBackedRetentionStillBlocked &&
        nsViewAllocationReadiness.didConfirmObjectTableStillAbsent &&
        nsViewAllocationReadiness
            .didConfirmDestroyRevokeDependencyStillRequired &&
        nsViewAllocationReadiness.didConfirmNoProductionAllocationCallable &&
        nsViewAllocationReadiness.didConfirmNoLongLivedNsViewStorage &&
        nsViewAllocationReadiness.didConfirmNoPointerHandleClassIdReturn &&
        nsViewAllocationReadiness.didConfirmNoNsWindowNsApplicationLayerMetal &&
        nsViewAllocationReadiness.didConfirmNoPublicSurface &&
        nsViewAllocationReadiness.didConfirmNoRendererStateWrite &&
        nsViewAllocationReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        objectTableObservation.didObserveFixedSmallCapacity &&
        objectTableObservation.didObserveTableEnabled &&
        objectTableObservation.didObserveTableEmpty &&
        objectTableObservation.didClassifyInvalidTokenFailClosed &&
        objectTableObservation.didObserveAllocationStillBlocked &&
        objectTableObservation.didObserveDestroyStillBlocked &&
        objectTableObservation.didConfirmNoPointerHandleClassIdReturn &&
        objectTableObservation.didConfirmNoNsViewAllocationOrStorage &&
        objectTableObservation.didConfirmNoMetalQuartzCoreUsage
    let readinessReady = upstreamReady && observationReady
    return CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness(
        nsViewAllocationReadiness,
        objectTableObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        objectTableObservation.didObserveFixedSmallCapacity,
        objectTableObservation.didObserveTableEnabled,
        objectTableObservation.didObserveTableEmpty,
        objectTableObservation.didClassifyInvalidTokenFailClosed,
        objectTableObservation.didObserveAllocationStillBlocked,
        objectTableObservation.didObserveDestroyStillBlocked,
        true,
        true,
        true,
        true,
        objectTableObservation.didConfirmNoPointerHandleClassIdReturn,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererPlatformObjectNsViewObjectTableDraft():
    CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness {
    let nsViewAllocationReadiness =
        cjguiInternalExecuteDefaultRendererPlatformObjectNsViewAllocationDraft()
    let objectTableObservation =
        cjguiInternalObserveRendererPlatformObjectNsViewObjectTableValues()
    return cjguiInternalBuildRendererPlatformObjectNsViewObjectTableReadiness(
        nsViewAllocationReadiness,
        objectTableObservation
    )
}
