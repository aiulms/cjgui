// Owner: native token table no-resource shell callable owner。
// Truth: 只消费 CjguiInternalRendererNoNativeTokenTableImplementationReadiness，
// 调用 token table shell no-resource C ABI，并把 invalid / capacity /
// enabled / classification 返回值脱水成 internal facts。
// Stop-line: 不绑定 native
// object / handle / pointer，不保存 raw pointer，不写 runtime_state.cj，不把
// token shell 解释成 resource exists 或 backend-ready truth。
// Same-shape Boundary Brake: 不得把本 owner 包成 resource table
// permission、native object permission、native handle permission、Metal/AppKit、
// backend-ready、public API、receipt、record 或 publication wrapper。
package cjgui

foreign func cjgui_native_bridge_token_invalid(): UInt64
foreign func cjgui_native_bridge_token_table_capacity(): UInt32
foreign func cjgui_native_bridge_token_table_enabled(): UInt32
foreign func cjgui_native_bridge_token_classify(token: UInt64): Int32

struct CjguiInternalRendererNativeTokenTableShellIntent {
    let tokenTableImplementationReadiness:
        CjguiInternalRendererNoNativeTokenTableImplementationReadiness
    let didPrepareRendererNativeTokenTableShellIntent: Bool
    let shouldDeferRendererNativeTokenTableShellIntent: Bool
    let shouldReportRendererNativeTokenTableShellIntentBlocked: Bool
    let didPreserveRendererNativeTokenTableImplementationReadiness: Bool
    let didConfirmClassificationOnlyShell: Bool
    let didConfirmIssueRevokeDeferred: Bool
    let didKeepTokenTableShellInternalOnly: Bool
    let didAvoidResourceTableWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        tokenTableImplementationReadiness:
            CjguiInternalRendererNoNativeTokenTableImplementationReadiness,
        didPrepareRendererNativeTokenTableShellIntent: Bool,
        shouldDeferRendererNativeTokenTableShellIntent: Bool,
        shouldReportRendererNativeTokenTableShellIntentBlocked: Bool,
        didPreserveRendererNativeTokenTableImplementationReadiness: Bool,
        didConfirmClassificationOnlyShell: Bool,
        didConfirmIssueRevokeDeferred: Bool,
        didKeepTokenTableShellInternalOnly: Bool,
        didAvoidResourceTableWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.tokenTableImplementationReadiness =
            tokenTableImplementationReadiness
        this.didPrepareRendererNativeTokenTableShellIntent =
            didPrepareRendererNativeTokenTableShellIntent
        this.shouldDeferRendererNativeTokenTableShellIntent =
            shouldDeferRendererNativeTokenTableShellIntent
        this.shouldReportRendererNativeTokenTableShellIntentBlocked =
            shouldReportRendererNativeTokenTableShellIntentBlocked
        this.didPreserveRendererNativeTokenTableImplementationReadiness =
            didPreserveRendererNativeTokenTableImplementationReadiness
        this.didConfirmClassificationOnlyShell =
            didConfirmClassificationOnlyShell
        this.didConfirmIssueRevokeDeferred = didConfirmIssueRevokeDeferred
        this.didKeepTokenTableShellInternalOnly =
            didKeepTokenTableShellInternalOnly
        this.didAvoidResourceTableWrapper = didAvoidResourceTableWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeTokenTableShellObservation {
    let invalidTokenValue: UInt64
    let tableCapacityValue: UInt32
    let tableEnabledValue: UInt32
    let invalidTokenClassificationValue: Int32
    let nonZeroTokenClassificationValue: Int32
    let didObserveInvalidTokenConstant: Bool
    let didObserveFixedCapacity: Bool
    let didObserveTableEnabled: Bool
    let didClassifyInvalidToken: Bool
    let didClassifyNonZeroTokenAsStale: Bool
    let didKeepObservationSideEffectFree: Bool
    let didDenyNativePointerReturn: Bool
    let didAvoidResourceCallable: Bool

    init(
        invalidTokenValue: UInt64,
        tableCapacityValue: UInt32,
        tableEnabledValue: UInt32,
        invalidTokenClassificationValue: Int32,
        nonZeroTokenClassificationValue: Int32,
        didObserveInvalidTokenConstant: Bool,
        didObserveFixedCapacity: Bool,
        didObserveTableEnabled: Bool,
        didClassifyInvalidToken: Bool,
        didClassifyNonZeroTokenAsStale: Bool,
        didKeepObservationSideEffectFree: Bool,
        didDenyNativePointerReturn: Bool,
        didAvoidResourceCallable: Bool
    ) {
        this.invalidTokenValue = invalidTokenValue
        this.tableCapacityValue = tableCapacityValue
        this.tableEnabledValue = tableEnabledValue
        this.invalidTokenClassificationValue =
            invalidTokenClassificationValue
        this.nonZeroTokenClassificationValue =
            nonZeroTokenClassificationValue
        this.didObserveInvalidTokenConstant =
            didObserveInvalidTokenConstant
        this.didObserveFixedCapacity = didObserveFixedCapacity
        this.didObserveTableEnabled = didObserveTableEnabled
        this.didClassifyInvalidToken = didClassifyInvalidToken
        this.didClassifyNonZeroTokenAsStale =
            didClassifyNonZeroTokenAsStale
        this.didKeepObservationSideEffectFree =
            didKeepObservationSideEffectFree
        this.didDenyNativePointerReturn = didDenyNativePointerReturn
        this.didAvoidResourceCallable = didAvoidResourceCallable
    }
}

struct CjguiInternalRendererNoNativeTokenTableShellReadiness {
    let shellIntent: CjguiInternalRendererNativeTokenTableShellIntent
    let shellObservation:
        CjguiInternalRendererNativeTokenTableShellObservation
    let didPrepareRendererNoNativeTokenTableShellReadiness: Bool
    let shouldDeferRendererNoNativeTokenTableShellReadiness: Bool
    let shouldReportRendererNoNativeTokenTableShellReadinessBlocked: Bool
    let didPreserveRendererNativeTokenTableShellIntent: Bool
    let didPreserveRendererNativeTokenTableShellObservation: Bool
    let didConfirmInvalidTokenObserved: Bool
    let didConfirmTableCapacityObserved: Bool
    let didConfirmTableEnabledObserved: Bool
    let didConfirmTokenClassificationObserved: Bool
    let didConfirmNoIssueRevokeCallable: Bool
    let didConfirmNoMutableTokenTable: Bool
    let didConfirmNoResourceBinding: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoResourceCallable: Bool
    let didConfirmNoNativeObjectHandleOrPointer: Bool
    let didConfirmNoMetalOrAppKitUsage: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoNativeTokenTableShellReadinessDehydrated: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        shellIntent: CjguiInternalRendererNativeTokenTableShellIntent,
        shellObservation:
            CjguiInternalRendererNativeTokenTableShellObservation,
        didPrepareRendererNoNativeTokenTableShellReadiness: Bool,
        shouldDeferRendererNoNativeTokenTableShellReadiness: Bool,
        shouldReportRendererNoNativeTokenTableShellReadinessBlocked: Bool,
        didPreserveRendererNativeTokenTableShellIntent: Bool,
        didPreserveRendererNativeTokenTableShellObservation: Bool,
        didConfirmInvalidTokenObserved: Bool,
        didConfirmTableCapacityObserved: Bool,
        didConfirmTableEnabledObserved: Bool,
        didConfirmTokenClassificationObserved: Bool,
        didConfirmNoIssueRevokeCallable: Bool,
        didConfirmNoMutableTokenTable: Bool,
        didConfirmNoResourceBinding: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoResourceCallable: Bool,
        didConfirmNoNativeObjectHandleOrPointer: Bool,
        didConfirmNoMetalOrAppKitUsage: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoNativeTokenTableShellReadinessDehydrated: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.shellIntent = shellIntent
        this.shellObservation = shellObservation
        this.didPrepareRendererNoNativeTokenTableShellReadiness =
            didPrepareRendererNoNativeTokenTableShellReadiness
        this.shouldDeferRendererNoNativeTokenTableShellReadiness =
            shouldDeferRendererNoNativeTokenTableShellReadiness
        this
            .shouldReportRendererNoNativeTokenTableShellReadinessBlocked =
            shouldReportRendererNoNativeTokenTableShellReadinessBlocked
        this.didPreserveRendererNativeTokenTableShellIntent =
            didPreserveRendererNativeTokenTableShellIntent
        this.didPreserveRendererNativeTokenTableShellObservation =
            didPreserveRendererNativeTokenTableShellObservation
        this.didConfirmInvalidTokenObserved = didConfirmInvalidTokenObserved
        this.didConfirmTableCapacityObserved =
            didConfirmTableCapacityObserved
        this.didConfirmTableEnabledObserved =
            didConfirmTableEnabledObserved
        this.didConfirmTokenClassificationObserved =
            didConfirmTokenClassificationObserved
        this.didConfirmNoIssueRevokeCallable =
            didConfirmNoIssueRevokeCallable
        this.didConfirmNoMutableTokenTable = didConfirmNoMutableTokenTable
        this.didConfirmNoResourceBinding = didConfirmNoResourceBinding
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoResourceCallable = didConfirmNoResourceCallable
        this.didConfirmNoNativeObjectHandleOrPointer =
            didConfirmNoNativeObjectHandleOrPointer
        this.didConfirmNoMetalOrAppKitUsage =
            didConfirmNoMetalOrAppKitUsage
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNoNativeTokenTableShellReadinessDehydrated =
            didKeepNoNativeTokenTableShellReadinessDehydrated
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererNativeTokenTableShellValues():
    CjguiInternalRendererNativeTokenTableShellObservation {
    let invalidToken = unsafe {
        cjgui_native_bridge_token_invalid()
    }
    let tableCapacity = unsafe {
        cjgui_native_bridge_token_table_capacity()
    }
    let tableEnabled = unsafe {
        cjgui_native_bridge_token_table_enabled()
    }
    let invalidTokenClass = unsafe {
        cjgui_native_bridge_token_classify(invalidToken)
    }
    let nonZeroTokenClass = unsafe {
        cjgui_native_bridge_token_classify(UInt64(1))
    }
    return CjguiInternalRendererNativeTokenTableShellObservation(
        invalidToken,
        tableCapacity,
        tableEnabled,
        invalidTokenClass,
        nonZeroTokenClass,
        invalidToken == UInt64(0),
        tableCapacity == UInt32(8),
        tableEnabled == UInt32(1),
        invalidTokenClass == Int32(0),
        nonZeroTokenClass == Int32(-2),
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererNativeTokenTableShellReadiness(
    tokenTableImplementationReadiness:
        CjguiInternalRendererNoNativeTokenTableImplementationReadiness,
    shellObservation:
        CjguiInternalRendererNativeTokenTableShellObservation
): CjguiInternalRendererNoNativeTokenTableShellReadiness {
    let upstreamReady =
        tokenTableImplementationReadiness
            .didPrepareRendererNoNativeTokenTableImplementationReadiness &&
        tokenTableImplementationReadiness
            .didConfirmBridgeLocalTableShellPolicy &&
        tokenTableImplementationReadiness
            .didConfirmNoPointerTableEntryPolicy &&
        tokenTableImplementationReadiness.didConfirmGenerationSlotEpochPolicy &&
        tokenTableImplementationReadiness
            .didConfirmCapacityAllocationFailureClassification &&
        tokenTableImplementationReadiness
            .didConfirmNoActualTokenTableImplementation &&
        tokenTableImplementationReadiness.didConfirmNoResourceObjectTable &&
        tokenTableImplementationReadiness.didConfirmNoNativeObjectBinding &&
        tokenTableImplementationReadiness
            .didConfirmNoRawPointerStorageOrReturn &&
        tokenTableImplementationReadiness.didConfirmNoPublicSurface &&
        tokenTableImplementationReadiness.didConfirmNoResourceCallable &&
        tokenTableImplementationReadiness.didConfirmNoMetalOrAppKitUsage &&
        tokenTableImplementationReadiness.didConfirmNoRendererStateWrite &&
        tokenTableImplementationReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        shellObservation.didObserveInvalidTokenConstant &&
        shellObservation.didObserveFixedCapacity &&
        shellObservation.didObserveTableEnabled &&
        shellObservation.didClassifyInvalidToken &&
        shellObservation.didClassifyNonZeroTokenAsStale &&
        shellObservation.didKeepObservationSideEffectFree &&
        shellObservation.didDenyNativePointerReturn &&
        shellObservation.didAvoidResourceCallable
    let readinessReady = upstreamReady && observationReady
    let intent = CjguiInternalRendererNativeTokenTableShellIntent(
        tokenTableImplementationReadiness,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        true,
        true,
        true,
        true,
        true
    )
    return CjguiInternalRendererNoNativeTokenTableShellReadiness(
        intent,
        shellObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        readinessReady,
        observationReady,
        shellObservation.didObserveInvalidTokenConstant,
        shellObservation.didObserveFixedCapacity,
        shellObservation.didObserveTableEnabled,
        shellObservation.didClassifyInvalidToken &&
            shellObservation.didClassifyNonZeroTokenAsStale,
        false,
        false,
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

func cjguiInternalExecuteDefaultRendererNativeTokenTableShellDraft():
    CjguiInternalRendererNoNativeTokenTableShellReadiness {
    let tokenTableImplementationReadiness =
        cjguiInternalExecuteDefaultRendererNativeTokenTableImplementationDraft()
    let shellObservation =
        cjguiInternalObserveRendererNativeTokenTableShellValues()
    return cjguiInternalBuildRendererNativeTokenTableShellReadiness(
        tokenTableImplementationReadiness,
        shellObservation
    )
}
