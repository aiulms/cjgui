// 维护注释：本文件是 CAMetalLayer token-backed table shell internal owner。
// Truth: 只消费 CjguiInternalRendererNoCAMetalLayerAllocationReadiness，
// 调用 table metadata / classification C ABI，并把返回值脱水为 internal facts。
// Stop-line: 不创建 layer，不 attach 到 NSView，不设置 device，不获取 drawable，
// 不返回 pointer / handle / Class / id，不写 runtime_state.cj。
// Same-shape Boundary Brake: table shell 不得被包装成 retention、attachment、
// Metal device、backend-ready、render-ready、GPU submission 或 state write。
package cjgui

foreign func cjgui_native_bridge_cametallayer_table_capacity(): UInt32
foreign func cjgui_native_bridge_cametallayer_table_enabled(): UInt32
foreign func cjgui_native_bridge_cametallayer_table_empty(): Int32
foreign func cjgui_native_bridge_cametallayer_table_token_classify(
    token: UInt64
): Int32
foreign func cjgui_native_bridge_cametallayer_table_allocation_still_blocked():
    Int32
foreign func cjgui_native_bridge_cametallayer_table_destroy_still_blocked():
    Int32

struct CjguiInternalRendererCAMetalLayerObjectTableObservation {
    let tableCapacityValue: UInt32
    let tableEnabledValue: UInt32
    let tableEmptyValue: Int32
    let invalidTokenClassValue: Int32
    let allocationStillBlockedValue: Int32
    let destroyStillBlockedValue: Int32
    let didObserveFixedCapacityTable: Bool
    let didObserveTableEnabled: Bool
    let didObserveEmptyTableFact: Bool
    let didObserveInvalidTokenFailClosed: Bool
    let didObserveAllocationStillBlocked: Bool
    let didObserveDestroyStillBlocked: Bool
    let didConfirmNoLayerAllocation: Bool
    let didConfirmNoAttachment: Bool
    let didConfirmNoMetalDeviceOrDrawable: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        tableCapacityValue: UInt32,
        tableEnabledValue: UInt32,
        tableEmptyValue: Int32,
        invalidTokenClassValue: Int32,
        allocationStillBlockedValue: Int32,
        destroyStillBlockedValue: Int32,
        didObserveFixedCapacityTable: Bool,
        didObserveTableEnabled: Bool,
        didObserveEmptyTableFact: Bool,
        didObserveInvalidTokenFailClosed: Bool,
        didObserveAllocationStillBlocked: Bool,
        didObserveDestroyStillBlocked: Bool,
        didConfirmNoLayerAllocation: Bool,
        didConfirmNoAttachment: Bool,
        didConfirmNoMetalDeviceOrDrawable: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.tableCapacityValue = tableCapacityValue
        this.tableEnabledValue = tableEnabledValue
        this.tableEmptyValue = tableEmptyValue
        this.invalidTokenClassValue = invalidTokenClassValue
        this.allocationStillBlockedValue = allocationStillBlockedValue
        this.destroyStillBlockedValue = destroyStillBlockedValue
        this.didObserveFixedCapacityTable = didObserveFixedCapacityTable
        this.didObserveTableEnabled = didObserveTableEnabled
        this.didObserveEmptyTableFact = didObserveEmptyTableFact
        this.didObserveInvalidTokenFailClosed =
            didObserveInvalidTokenFailClosed
        this.didObserveAllocationStillBlocked =
            didObserveAllocationStillBlocked
        this.didObserveDestroyStillBlocked = didObserveDestroyStillBlocked
        this.didConfirmNoLayerAllocation = didConfirmNoLayerAllocation
        this.didConfirmNoAttachment = didConfirmNoAttachment
        this.didConfirmNoMetalDeviceOrDrawable =
            didConfirmNoMetalDeviceOrDrawable
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererNoCAMetalLayerObjectTableReadiness {
    let didPrepareRendererNoCAMetalLayerObjectTableReadiness: Bool
    let shouldDeferRendererNoCAMetalLayerObjectTableReadiness: Bool
    let shouldReportRendererNoCAMetalLayerObjectTableBlocked: Bool
    let didPreserveRendererCAMetalLayerAllocationReadiness: Bool
    let didConfirmFixedCapacityCAMetalLayerTableShell: Bool
    let didConfirmTableEnabled: Bool
    let didConfirmInvalidTokenFailClosed: Bool
    let didConfirmAllocationStillBlockedAtTableShell: Bool
    let didConfirmDestroyStillBlockedAtTableShell: Bool
    let didConfirmNoLayerAllocation: Bool
    let didConfirmNoAttachment: Bool
    let didConfirmNoMetalDeviceOrDrawable: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepCAMetalLayerObjectTableReadinessDehydrated: Bool
    let didAvoidRetentionWrapper: Bool
    let didAvoidAttachWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        didPrepareRendererNoCAMetalLayerObjectTableReadiness: Bool,
        shouldDeferRendererNoCAMetalLayerObjectTableReadiness: Bool,
        shouldReportRendererNoCAMetalLayerObjectTableBlocked: Bool,
        didPreserveRendererCAMetalLayerAllocationReadiness: Bool,
        didConfirmFixedCapacityCAMetalLayerTableShell: Bool,
        didConfirmTableEnabled: Bool,
        didConfirmInvalidTokenFailClosed: Bool,
        didConfirmAllocationStillBlockedAtTableShell: Bool,
        didConfirmDestroyStillBlockedAtTableShell: Bool,
        didConfirmNoLayerAllocation: Bool,
        didConfirmNoAttachment: Bool,
        didConfirmNoMetalDeviceOrDrawable: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepCAMetalLayerObjectTableReadinessDehydrated: Bool,
        didAvoidRetentionWrapper: Bool,
        didAvoidAttachWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.didPrepareRendererNoCAMetalLayerObjectTableReadiness =
            didPrepareRendererNoCAMetalLayerObjectTableReadiness
        this.shouldDeferRendererNoCAMetalLayerObjectTableReadiness =
            shouldDeferRendererNoCAMetalLayerObjectTableReadiness
        this.shouldReportRendererNoCAMetalLayerObjectTableBlocked =
            shouldReportRendererNoCAMetalLayerObjectTableBlocked
        this.didPreserveRendererCAMetalLayerAllocationReadiness =
            didPreserveRendererCAMetalLayerAllocationReadiness
        this.didConfirmFixedCapacityCAMetalLayerTableShell =
            didConfirmFixedCapacityCAMetalLayerTableShell
        this.didConfirmTableEnabled = didConfirmTableEnabled
        this.didConfirmInvalidTokenFailClosed =
            didConfirmInvalidTokenFailClosed
        this.didConfirmAllocationStillBlockedAtTableShell =
            didConfirmAllocationStillBlockedAtTableShell
        this.didConfirmDestroyStillBlockedAtTableShell =
            didConfirmDestroyStillBlockedAtTableShell
        this.didConfirmNoLayerAllocation = didConfirmNoLayerAllocation
        this.didConfirmNoAttachment = didConfirmNoAttachment
        this.didConfirmNoMetalDeviceOrDrawable =
            didConfirmNoMetalDeviceOrDrawable
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepCAMetalLayerObjectTableReadinessDehydrated =
            didKeepCAMetalLayerObjectTableReadinessDehydrated
        this.didAvoidRetentionWrapper = didAvoidRetentionWrapper
        this.didAvoidAttachWrapper = didAvoidAttachWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
    }
}

func cjguiInternalObserveRendererCAMetalLayerObjectTableValues():
    CjguiInternalRendererCAMetalLayerObjectTableObservation {
    let capacity = unsafe {
        cjgui_native_bridge_cametallayer_table_capacity()
    }
    let enabled = unsafe {
        cjgui_native_bridge_cametallayer_table_enabled()
    }
    let empty = unsafe {
        cjgui_native_bridge_cametallayer_table_empty()
    }
    let invalidTokenClass = unsafe {
        cjgui_native_bridge_cametallayer_table_token_classify(UInt64(0))
    }
    let allocationStillBlocked = unsafe {
        cjgui_native_bridge_cametallayer_table_allocation_still_blocked()
    }
    let destroyStillBlocked = unsafe {
        cjgui_native_bridge_cametallayer_table_destroy_still_blocked()
    }
    return CjguiInternalRendererCAMetalLayerObjectTableObservation(
        capacity,
        enabled,
        empty,
        invalidTokenClass,
        allocationStillBlocked,
        destroyStillBlocked,
        capacity == UInt32(4),
        enabled == UInt32(1),
        empty == Int32(70),
        invalidTokenClass == Int32(0),
        allocationStillBlocked == Int32(-71),
        destroyStillBlocked == Int32(-72),
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererCAMetalLayerObjectTableReadiness(
    allocationReadiness:
        CjguiInternalRendererNoCAMetalLayerAllocationReadiness,
    tableObservation:
        CjguiInternalRendererCAMetalLayerObjectTableObservation
): CjguiInternalRendererNoCAMetalLayerObjectTableReadiness {
    let upstreamReady =
        allocationReadiness
            .didPrepareRendererNoCAMetalLayerAllocationReadiness &&
        allocationReadiness.didConfirmAllocationFeasible &&
        allocationReadiness.didConfirmNoAttachAdmission &&
        allocationReadiness.didConfirmDeviceBindingBlocked &&
        allocationReadiness.didConfirmNoAttachment &&
        allocationReadiness.didConfirmNoMetalDeviceOrDrawable &&
        allocationReadiness.didConfirmNoPointerHandleClassIdReturn &&
        allocationReadiness.didConfirmNoRendererStateWrite &&
        allocationReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        tableObservation.didObserveFixedCapacityTable &&
        tableObservation.didObserveTableEnabled &&
        tableObservation.didObserveEmptyTableFact &&
        tableObservation.didObserveInvalidTokenFailClosed &&
        tableObservation.didObserveAllocationStillBlocked &&
        tableObservation.didObserveDestroyStillBlocked &&
        tableObservation.didConfirmNoLayerAllocation &&
        tableObservation.didConfirmNoAttachment &&
        tableObservation.didConfirmNoMetalDeviceOrDrawable &&
        tableObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady
    return CjguiInternalRendererNoCAMetalLayerObjectTableReadiness(
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        tableObservation.didObserveFixedCapacityTable,
        tableObservation.didObserveTableEnabled,
        tableObservation.didObserveInvalidTokenFailClosed,
        tableObservation.didObserveAllocationStillBlocked,
        tableObservation.didObserveDestroyStillBlocked,
        tableObservation.didConfirmNoLayerAllocation,
        tableObservation.didConfirmNoAttachment,
        tableObservation.didConfirmNoMetalDeviceOrDrawable,
        tableObservation.didConfirmNoPointerHandleClassIdReturn,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererCAMetalLayerObjectTableDraft():
    CjguiInternalRendererNoCAMetalLayerObjectTableReadiness {
    let allocationReadiness =
        cjguiInternalExecuteDefaultRendererCAMetalLayerAllocationDraft()
    let tableObservation =
        cjguiInternalObserveRendererCAMetalLayerObjectTableValues()
    return cjguiInternalBuildRendererCAMetalLayerObjectTableReadiness(
        allocationReadiness,
        tableObservation
    )
}
