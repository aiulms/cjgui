// Owner: native token table no-resource issue/revoke callable owner。
// Truth: 只消费 CjguiInternalRendererNoNativeTokenTableShellReadiness，
// 调用 token issue / classify / revoke no-resource C ABI，并把固定容量、
// generation 失效、double revoke 与 fail-closed 返回值脱水成 internal facts。
// Stop-line: 不绑定 native object / handle / pointer，不保存 raw pointer，
// 不执行 retain / release / destroy，不写 runtime_state.cj，不把 issue /
// revoke 解释成 resource exists 或 backend-ready truth。
// Same-shape Boundary Brake: 不得把本 owner 包成 resource table permission、
// native object permission、native handle permission、Metal/AppKit、
// backend-ready、public API、receipt、record 或 publication wrapper。
package cjgui

foreign func cjgui_native_bridge_token_issue(): UInt64
foreign func cjgui_native_bridge_token_revoke(token: UInt64): Int32

struct CjguiInternalRendererNativeTokenTableIssueRevokeIntent {
    let tokenTableShellReadiness:
        CjguiInternalRendererNoNativeTokenTableShellReadiness
    let didPrepareRendererNativeTokenTableIssueRevokeIntent: Bool
    let shouldDeferRendererNativeTokenTableIssueRevokeIntent: Bool
    let shouldReportRendererNativeTokenTableIssueRevokeIntentBlocked: Bool
    let didPreserveRendererNativeTokenTableShellReadiness: Bool
    let didConfirmFixedCapacityIssueRevokeIntent: Bool
    let didConfirmGenerationInvalidationIntent: Bool
    let didConfirmRevokeWithoutResourceTeardown: Bool
    let didKeepIssueRevokeInternalOnly: Bool
    let didAvoidResourceTableWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        tokenTableShellReadiness:
            CjguiInternalRendererNoNativeTokenTableShellReadiness,
        didPrepareRendererNativeTokenTableIssueRevokeIntent: Bool,
        shouldDeferRendererNativeTokenTableIssueRevokeIntent: Bool,
        shouldReportRendererNativeTokenTableIssueRevokeIntentBlocked: Bool,
        didPreserveRendererNativeTokenTableShellReadiness: Bool,
        didConfirmFixedCapacityIssueRevokeIntent: Bool,
        didConfirmGenerationInvalidationIntent: Bool,
        didConfirmRevokeWithoutResourceTeardown: Bool,
        didKeepIssueRevokeInternalOnly: Bool,
        didAvoidResourceTableWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.tokenTableShellReadiness = tokenTableShellReadiness
        this.didPrepareRendererNativeTokenTableIssueRevokeIntent =
            didPrepareRendererNativeTokenTableIssueRevokeIntent
        this.shouldDeferRendererNativeTokenTableIssueRevokeIntent =
            shouldDeferRendererNativeTokenTableIssueRevokeIntent
        this.shouldReportRendererNativeTokenTableIssueRevokeIntentBlocked =
            shouldReportRendererNativeTokenTableIssueRevokeIntentBlocked
        this.didPreserveRendererNativeTokenTableShellReadiness =
            didPreserveRendererNativeTokenTableShellReadiness
        this.didConfirmFixedCapacityIssueRevokeIntent =
            didConfirmFixedCapacityIssueRevokeIntent
        this.didConfirmGenerationInvalidationIntent =
            didConfirmGenerationInvalidationIntent
        this.didConfirmRevokeWithoutResourceTeardown =
            didConfirmRevokeWithoutResourceTeardown
        this.didKeepIssueRevokeInternalOnly =
            didKeepIssueRevokeInternalOnly
        this.didAvoidResourceTableWrapper = didAvoidResourceTableWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeTokenTableIssueRevokeObservation {
    let invalidTokenValue: UInt64
    let tableCapacityValue: UInt32
    let tableEnabledValue: UInt32
    let issuedTokenValue: UInt64
    let issuedTokenClassificationValue: Int32
    let revokeStatusValue: Int32
    let revokedTokenClassificationValue: Int32
    let doubleRevokeStatusValue: Int32
    let invalidTokenClassificationValue: Int32
    let didObserveFixedCapacity: Bool
    let didObserveTableEnabled: Bool
    let didIssueOpaqueToken: Bool
    let didClassifyIssuedTokenAsValid: Bool
    let didRevokeIssuedToken: Bool
    let didClassifyRevokedTokenAsStale: Bool
    let didClassifyDoubleRevokeAsStale: Bool
    let didClassifyInvalidToken: Bool
    let didKeepObservationSideEffectBounded: Bool
    let didDenyNativePointerReturn: Bool
    let didAvoidResourceCallable: Bool

    init(
        invalidTokenValue: UInt64,
        tableCapacityValue: UInt32,
        tableEnabledValue: UInt32,
        issuedTokenValue: UInt64,
        issuedTokenClassificationValue: Int32,
        revokeStatusValue: Int32,
        revokedTokenClassificationValue: Int32,
        doubleRevokeStatusValue: Int32,
        invalidTokenClassificationValue: Int32,
        didObserveFixedCapacity: Bool,
        didObserveTableEnabled: Bool,
        didIssueOpaqueToken: Bool,
        didClassifyIssuedTokenAsValid: Bool,
        didRevokeIssuedToken: Bool,
        didClassifyRevokedTokenAsStale: Bool,
        didClassifyDoubleRevokeAsStale: Bool,
        didClassifyInvalidToken: Bool,
        didKeepObservationSideEffectBounded: Bool,
        didDenyNativePointerReturn: Bool,
        didAvoidResourceCallable: Bool
    ) {
        this.invalidTokenValue = invalidTokenValue
        this.tableCapacityValue = tableCapacityValue
        this.tableEnabledValue = tableEnabledValue
        this.issuedTokenValue = issuedTokenValue
        this.issuedTokenClassificationValue =
            issuedTokenClassificationValue
        this.revokeStatusValue = revokeStatusValue
        this.revokedTokenClassificationValue =
            revokedTokenClassificationValue
        this.doubleRevokeStatusValue = doubleRevokeStatusValue
        this.invalidTokenClassificationValue =
            invalidTokenClassificationValue
        this.didObserveFixedCapacity = didObserveFixedCapacity
        this.didObserveTableEnabled = didObserveTableEnabled
        this.didIssueOpaqueToken = didIssueOpaqueToken
        this.didClassifyIssuedTokenAsValid =
            didClassifyIssuedTokenAsValid
        this.didRevokeIssuedToken = didRevokeIssuedToken
        this.didClassifyRevokedTokenAsStale =
            didClassifyRevokedTokenAsStale
        this.didClassifyDoubleRevokeAsStale =
            didClassifyDoubleRevokeAsStale
        this.didClassifyInvalidToken = didClassifyInvalidToken
        this.didKeepObservationSideEffectBounded =
            didKeepObservationSideEffectBounded
        this.didDenyNativePointerReturn = didDenyNativePointerReturn
        this.didAvoidResourceCallable = didAvoidResourceCallable
    }
}

struct CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness {
    let issueRevokeIntent:
        CjguiInternalRendererNativeTokenTableIssueRevokeIntent
    let issueRevokeObservation:
        CjguiInternalRendererNativeTokenTableIssueRevokeObservation
    let didPrepareRendererNoNativeTokenTableIssueRevokeReadiness: Bool
    let shouldDeferRendererNoNativeTokenTableIssueRevokeReadiness: Bool
    let shouldReportRendererNoNativeTokenTableIssueRevokeReadinessBlocked:
        Bool
    let didPreserveRendererNativeTokenTableIssueRevokeIntent: Bool
    let didPreserveRendererNativeTokenTableIssueRevokeObservation: Bool
    let didConfirmFixedCapacity: Bool
    let didConfirmIssueOpaqueToken: Bool
    let didConfirmIssuedTokenValid: Bool
    let didConfirmRevokeWithoutResourceTeardown: Bool
    let didConfirmRevokedTokenInvalidated: Bool
    let didConfirmDoubleRevokeFailClosed: Bool
    let didConfirmInvalidTokenFailClosed: Bool
    let didConfirmNoResourceBinding: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoResourceCallable: Bool
    let didConfirmNoNativeObjectHandleOrPointer: Bool
    let didConfirmNoMetalOrAppKitUsage: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoNativeTokenTableIssueRevokeReadinessDehydrated: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        issueRevokeIntent:
            CjguiInternalRendererNativeTokenTableIssueRevokeIntent,
        issueRevokeObservation:
            CjguiInternalRendererNativeTokenTableIssueRevokeObservation,
        didPrepareRendererNoNativeTokenTableIssueRevokeReadiness: Bool,
        shouldDeferRendererNoNativeTokenTableIssueRevokeReadiness: Bool,
        shouldReportRendererNoNativeTokenTableIssueRevokeReadinessBlocked:
            Bool,
        didPreserveRendererNativeTokenTableIssueRevokeIntent: Bool,
        didPreserveRendererNativeTokenTableIssueRevokeObservation: Bool,
        didConfirmFixedCapacity: Bool,
        didConfirmIssueOpaqueToken: Bool,
        didConfirmIssuedTokenValid: Bool,
        didConfirmRevokeWithoutResourceTeardown: Bool,
        didConfirmRevokedTokenInvalidated: Bool,
        didConfirmDoubleRevokeFailClosed: Bool,
        didConfirmInvalidTokenFailClosed: Bool,
        didConfirmNoResourceBinding: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoResourceCallable: Bool,
        didConfirmNoNativeObjectHandleOrPointer: Bool,
        didConfirmNoMetalOrAppKitUsage: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoNativeTokenTableIssueRevokeReadinessDehydrated: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.issueRevokeIntent = issueRevokeIntent
        this.issueRevokeObservation = issueRevokeObservation
        this.didPrepareRendererNoNativeTokenTableIssueRevokeReadiness =
            didPrepareRendererNoNativeTokenTableIssueRevokeReadiness
        this.shouldDeferRendererNoNativeTokenTableIssueRevokeReadiness =
            shouldDeferRendererNoNativeTokenTableIssueRevokeReadiness
        this
            .shouldReportRendererNoNativeTokenTableIssueRevokeReadinessBlocked =
            shouldReportRendererNoNativeTokenTableIssueRevokeReadinessBlocked
        this.didPreserveRendererNativeTokenTableIssueRevokeIntent =
            didPreserveRendererNativeTokenTableIssueRevokeIntent
        this.didPreserveRendererNativeTokenTableIssueRevokeObservation =
            didPreserveRendererNativeTokenTableIssueRevokeObservation
        this.didConfirmFixedCapacity = didConfirmFixedCapacity
        this.didConfirmIssueOpaqueToken = didConfirmIssueOpaqueToken
        this.didConfirmIssuedTokenValid = didConfirmIssuedTokenValid
        this.didConfirmRevokeWithoutResourceTeardown =
            didConfirmRevokeWithoutResourceTeardown
        this.didConfirmRevokedTokenInvalidated =
            didConfirmRevokedTokenInvalidated
        this.didConfirmDoubleRevokeFailClosed =
            didConfirmDoubleRevokeFailClosed
        this.didConfirmInvalidTokenFailClosed =
            didConfirmInvalidTokenFailClosed
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
        this.didKeepNoNativeTokenTableIssueRevokeReadinessDehydrated =
            didKeepNoNativeTokenTableIssueRevokeReadinessDehydrated
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererNativeTokenTableIssueRevokeValues():
    CjguiInternalRendererNativeTokenTableIssueRevokeObservation {
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
    let issuedToken = unsafe {
        cjgui_native_bridge_token_issue()
    }
    let issuedTokenClass = unsafe {
        cjgui_native_bridge_token_classify(issuedToken)
    }
    let revokeStatus = unsafe {
        cjgui_native_bridge_token_revoke(issuedToken)
    }
    let revokedTokenClass = unsafe {
        cjgui_native_bridge_token_classify(issuedToken)
    }
    let doubleRevokeStatus = unsafe {
        cjgui_native_bridge_token_revoke(issuedToken)
    }
    return CjguiInternalRendererNativeTokenTableIssueRevokeObservation(
        invalidToken,
        tableCapacity,
        tableEnabled,
        issuedToken,
        issuedTokenClass,
        revokeStatus,
        revokedTokenClass,
        doubleRevokeStatus,
        invalidTokenClass,
        tableCapacity == UInt32(8),
        tableEnabled == UInt32(1),
        issuedToken != UInt64(0),
        issuedTokenClass == Int32(1),
        revokeStatus == Int32(0),
        revokedTokenClass == Int32(-2),
        doubleRevokeStatus == Int32(-2),
        invalidTokenClass == Int32(0),
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererNativeTokenTableIssueRevokeReadiness(
    tokenTableShellReadiness:
        CjguiInternalRendererNoNativeTokenTableShellReadiness,
    issueRevokeObservation:
        CjguiInternalRendererNativeTokenTableIssueRevokeObservation
): CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness {
    let upstreamReady =
        tokenTableShellReadiness
            .didPrepareRendererNoNativeTokenTableShellReadiness &&
        tokenTableShellReadiness.didConfirmInvalidTokenObserved &&
        tokenTableShellReadiness.didConfirmTableCapacityObserved &&
        tokenTableShellReadiness.didConfirmTableEnabledObserved &&
        tokenTableShellReadiness.didConfirmTokenClassificationObserved &&
        tokenTableShellReadiness.didConfirmNoResourceBinding &&
        tokenTableShellReadiness.didConfirmNoPublicSurface &&
        tokenTableShellReadiness.didConfirmNoResourceCallable &&
        tokenTableShellReadiness.didConfirmNoNativeObjectHandleOrPointer &&
        tokenTableShellReadiness.didConfirmNoMetalOrAppKitUsage &&
        tokenTableShellReadiness.didConfirmNoRendererStateWrite &&
        tokenTableShellReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        issueRevokeObservation.didObserveFixedCapacity &&
        issueRevokeObservation.didObserveTableEnabled &&
        issueRevokeObservation.didIssueOpaqueToken &&
        issueRevokeObservation.didClassifyIssuedTokenAsValid &&
        issueRevokeObservation.didRevokeIssuedToken &&
        issueRevokeObservation.didClassifyRevokedTokenAsStale &&
        issueRevokeObservation.didClassifyDoubleRevokeAsStale &&
        issueRevokeObservation.didClassifyInvalidToken &&
        issueRevokeObservation.didKeepObservationSideEffectBounded &&
        issueRevokeObservation.didDenyNativePointerReturn &&
        issueRevokeObservation.didAvoidResourceCallable
    let readinessReady = upstreamReady && observationReady
    let intent = CjguiInternalRendererNativeTokenTableIssueRevokeIntent(
        tokenTableShellReadiness,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        true,
        true,
        true,
        true,
        true,
        true
    )
    return CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness(
        intent,
        issueRevokeObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        readinessReady,
        observationReady,
        issueRevokeObservation.didObserveFixedCapacity,
        issueRevokeObservation.didIssueOpaqueToken,
        issueRevokeObservation.didClassifyIssuedTokenAsValid,
        issueRevokeObservation.didRevokeIssuedToken,
        issueRevokeObservation.didClassifyRevokedTokenAsStale,
        issueRevokeObservation.didClassifyDoubleRevokeAsStale,
        issueRevokeObservation.didClassifyInvalidToken,
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

func cjguiInternalExecuteDefaultRendererNativeTokenTableIssueRevokeDraft():
    CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness {
    let tokenTableShellReadiness =
        cjguiInternalExecuteDefaultRendererNativeTokenTableShellDraft()
    let issueRevokeObservation =
        cjguiInternalObserveRendererNativeTokenTableIssueRevokeValues()
    return cjguiInternalBuildRendererNativeTokenTableIssueRevokeReadiness(
        tokenTableShellReadiness,
        issueRevokeObservation
    )
}
