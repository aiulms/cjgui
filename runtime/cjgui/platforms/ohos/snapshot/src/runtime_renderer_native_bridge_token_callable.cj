// Owner: native bridge token callable planning value boundary。
// Truth: 只消费 CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness，
// 记录 opaque token type、no-pointer token、token table mutability denial、
// revoke-without-destroy 与 no-native-token-callable readiness facts。
// Stop-line: 不新增 native callable，不创建 native object / handle /
// pointer，不返回 native pointer，不改 runtime_state.cj，不把 token policy
// 解释成 native resource ready 或 backend-ready truth。
// Same-shape Boundary Brake: 不得把本 owner 包成 native handle permission、
// native object、destroy permission、Metal/AppKit、backend-ready、public API、
// receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererNativeBridgeTokenCallableIntent {
    let mainThreadCallReadiness:
        CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness
    let didPrepareRendererNativeBridgeTokenCallableIntent: Bool
    let shouldDeferRendererNativeBridgeTokenCallableIntent: Bool
    let shouldReportRendererNativeBridgeTokenCallableIntentBlocked: Bool
    let didPreserveRendererNativeBridgeMainThreadCallReadiness: Bool
    let didDefineFutureNativeTokenCallableIntent: Bool
    let didSelectPlanningValueBoundaryRoute: Bool
    let didDeferNativeTokenCallableImplementation: Bool
    let didKeepTokenCallableIntentInternalOnly: Bool
    let didAvoidNativeHandlePermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        mainThreadCallReadiness:
            CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness,
        didPrepareRendererNativeBridgeTokenCallableIntent: Bool,
        shouldDeferRendererNativeBridgeTokenCallableIntent: Bool,
        shouldReportRendererNativeBridgeTokenCallableIntentBlocked: Bool,
        didPreserveRendererNativeBridgeMainThreadCallReadiness: Bool,
        didDefineFutureNativeTokenCallableIntent: Bool,
        didSelectPlanningValueBoundaryRoute: Bool,
        didDeferNativeTokenCallableImplementation: Bool,
        didKeepTokenCallableIntentInternalOnly: Bool,
        didAvoidNativeHandlePermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.mainThreadCallReadiness = mainThreadCallReadiness
        this.didPrepareRendererNativeBridgeTokenCallableIntent =
            didPrepareRendererNativeBridgeTokenCallableIntent
        this.shouldDeferRendererNativeBridgeTokenCallableIntent =
            shouldDeferRendererNativeBridgeTokenCallableIntent
        this
            .shouldReportRendererNativeBridgeTokenCallableIntentBlocked =
            shouldReportRendererNativeBridgeTokenCallableIntentBlocked
        this.didPreserveRendererNativeBridgeMainThreadCallReadiness =
            didPreserveRendererNativeBridgeMainThreadCallReadiness
        this.didDefineFutureNativeTokenCallableIntent =
            didDefineFutureNativeTokenCallableIntent
        this.didSelectPlanningValueBoundaryRoute =
            didSelectPlanningValueBoundaryRoute
        this.didDeferNativeTokenCallableImplementation =
            didDeferNativeTokenCallableImplementation
        this.didKeepTokenCallableIntentInternalOnly =
            didKeepTokenCallableIntentInternalOnly
        this.didAvoidNativeHandlePermissionWrapper =
            didAvoidNativeHandlePermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererOpaqueTokenCallableTypePolicy {
    let tokenCallableIntent:
        CjguiInternalRendererNativeBridgeTokenCallableIntent
    let didPrepareRendererOpaqueTokenCallableTypePolicy: Bool
    let shouldDeferRendererOpaqueTokenCallableTypePolicy: Bool
    let shouldReportRendererOpaqueTokenCallableTypePolicyBlocked: Bool
    let didPreserveRendererNativeBridgeTokenCallableIntent: Bool
    let didRequireUInt64OpaqueTokenShape: Bool
    let didForbidStructTokenShape: Bool
    let didForbidTokenEncodingNativePointer: Bool
    let didKeepTokenBridgeLocalIdentifier: Bool
    let didKeepTokenOutOfPublicApi: Bool
    let didKeepOpaqueTokenCallableTypePolicyDehydrated: Bool
    let didAvoidPointerHandleWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        tokenCallableIntent:
            CjguiInternalRendererNativeBridgeTokenCallableIntent,
        didPrepareRendererOpaqueTokenCallableTypePolicy: Bool,
        shouldDeferRendererOpaqueTokenCallableTypePolicy: Bool,
        shouldReportRendererOpaqueTokenCallableTypePolicyBlocked: Bool,
        didPreserveRendererNativeBridgeTokenCallableIntent: Bool,
        didRequireUInt64OpaqueTokenShape: Bool,
        didForbidStructTokenShape: Bool,
        didForbidTokenEncodingNativePointer: Bool,
        didKeepTokenBridgeLocalIdentifier: Bool,
        didKeepTokenOutOfPublicApi: Bool,
        didKeepOpaqueTokenCallableTypePolicyDehydrated: Bool,
        didAvoidPointerHandleWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.tokenCallableIntent = tokenCallableIntent
        this.didPrepareRendererOpaqueTokenCallableTypePolicy =
            didPrepareRendererOpaqueTokenCallableTypePolicy
        this.shouldDeferRendererOpaqueTokenCallableTypePolicy =
            shouldDeferRendererOpaqueTokenCallableTypePolicy
        this
            .shouldReportRendererOpaqueTokenCallableTypePolicyBlocked =
            shouldReportRendererOpaqueTokenCallableTypePolicyBlocked
        this.didPreserveRendererNativeBridgeTokenCallableIntent =
            didPreserveRendererNativeBridgeTokenCallableIntent
        this.didRequireUInt64OpaqueTokenShape =
            didRequireUInt64OpaqueTokenShape
        this.didForbidStructTokenShape = didForbidStructTokenShape
        this.didForbidTokenEncodingNativePointer =
            didForbidTokenEncodingNativePointer
        this.didKeepTokenBridgeLocalIdentifier =
            didKeepTokenBridgeLocalIdentifier
        this.didKeepTokenOutOfPublicApi = didKeepTokenOutOfPublicApi
        this.didKeepOpaqueTokenCallableTypePolicyDehydrated =
            didKeepOpaqueTokenCallableTypePolicyDehydrated
        this.didAvoidPointerHandleWrapper = didAvoidPointerHandleWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeBridgeTokenTableMutabilityPolicy {
    let opaqueTokenTypePolicy:
        CjguiInternalRendererOpaqueTokenCallableTypePolicy
    let didPrepareRendererNativeBridgeTokenTableMutabilityPolicy: Bool
    let shouldDeferRendererNativeBridgeTokenTableMutabilityPolicy: Bool
    let shouldReportRendererNativeBridgeTokenTableMutabilityPolicyBlocked:
        Bool
    let didPreserveRendererOpaqueTokenCallableTypePolicy: Bool
    let didDenyRuntimeGlobalMutableTokenTable: Bool
    let didDenyNativeGlobalMutableTokenTable: Bool
    let didDeferIssueRevokeUntilOwnershipTablePreflight: Bool
    let didRequireFailClosedTokenValidationWithoutTable: Bool
    let didRequireMainThreadGateBeforeFutureTokenMutation: Bool
    let didKeepTokenTableMutabilityPolicyDehydrated: Bool
    let didAvoidTokenReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        opaqueTokenTypePolicy:
            CjguiInternalRendererOpaqueTokenCallableTypePolicy,
        didPrepareRendererNativeBridgeTokenTableMutabilityPolicy: Bool,
        shouldDeferRendererNativeBridgeTokenTableMutabilityPolicy: Bool,
        shouldReportRendererNativeBridgeTokenTableMutabilityPolicyBlocked:
            Bool,
        didPreserveRendererOpaqueTokenCallableTypePolicy: Bool,
        didDenyRuntimeGlobalMutableTokenTable: Bool,
        didDenyNativeGlobalMutableTokenTable: Bool,
        didDeferIssueRevokeUntilOwnershipTablePreflight: Bool,
        didRequireFailClosedTokenValidationWithoutTable: Bool,
        didRequireMainThreadGateBeforeFutureTokenMutation: Bool,
        didKeepTokenTableMutabilityPolicyDehydrated: Bool,
        didAvoidTokenReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.opaqueTokenTypePolicy = opaqueTokenTypePolicy
        this.didPrepareRendererNativeBridgeTokenTableMutabilityPolicy =
            didPrepareRendererNativeBridgeTokenTableMutabilityPolicy
        this.shouldDeferRendererNativeBridgeTokenTableMutabilityPolicy =
            shouldDeferRendererNativeBridgeTokenTableMutabilityPolicy
        this
            .shouldReportRendererNativeBridgeTokenTableMutabilityPolicyBlocked =
            shouldReportRendererNativeBridgeTokenTableMutabilityPolicyBlocked
        this.didPreserveRendererOpaqueTokenCallableTypePolicy =
            didPreserveRendererOpaqueTokenCallableTypePolicy
        this.didDenyRuntimeGlobalMutableTokenTable =
            didDenyRuntimeGlobalMutableTokenTable
        this.didDenyNativeGlobalMutableTokenTable =
            didDenyNativeGlobalMutableTokenTable
        this.didDeferIssueRevokeUntilOwnershipTablePreflight =
            didDeferIssueRevokeUntilOwnershipTablePreflight
        this.didRequireFailClosedTokenValidationWithoutTable =
            didRequireFailClosedTokenValidationWithoutTable
        this.didRequireMainThreadGateBeforeFutureTokenMutation =
            didRequireMainThreadGateBeforeFutureTokenMutation
        this.didKeepTokenTableMutabilityPolicyDehydrated =
            didKeepTokenTableMutabilityPolicyDehydrated
        this.didAvoidTokenReadyWrapper = didAvoidTokenReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeBridgeTokenRevocationSeparationPolicy {
    let tokenTableMutabilityPolicy:
        CjguiInternalRendererNativeBridgeTokenTableMutabilityPolicy
    let didPrepareRendererNativeBridgeTokenRevocationSeparationPolicy:
        Bool
    let shouldDeferRendererNativeBridgeTokenRevocationSeparationPolicy:
        Bool
    let shouldReportRendererNativeBridgeTokenRevocationSeparationPolicyBlocked:
        Bool
    let didPreserveRendererNativeBridgeTokenTableMutabilityPolicy: Bool
    let didSeparateRevocationFromDestroy: Bool
    let didDenyRetainReleaseDestroy: Bool
    let didDenyNativeLifecycleMutation: Bool
    let didRequireRevokeWithoutDestroyPolicy: Bool
    let didRequireDoubleRevokeFailClosedPolicy: Bool
    let didKeepTokenRevocationSeparationPolicyDehydrated: Bool
    let didAvoidDestroyPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        tokenTableMutabilityPolicy:
            CjguiInternalRendererNativeBridgeTokenTableMutabilityPolicy,
        didPrepareRendererNativeBridgeTokenRevocationSeparationPolicy:
            Bool,
        shouldDeferRendererNativeBridgeTokenRevocationSeparationPolicy:
            Bool,
        shouldReportRendererNativeBridgeTokenRevocationSeparationPolicyBlocked:
            Bool,
        didPreserveRendererNativeBridgeTokenTableMutabilityPolicy: Bool,
        didSeparateRevocationFromDestroy: Bool,
        didDenyRetainReleaseDestroy: Bool,
        didDenyNativeLifecycleMutation: Bool,
        didRequireRevokeWithoutDestroyPolicy: Bool,
        didRequireDoubleRevokeFailClosedPolicy: Bool,
        didKeepTokenRevocationSeparationPolicyDehydrated: Bool,
        didAvoidDestroyPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.tokenTableMutabilityPolicy = tokenTableMutabilityPolicy
        this
            .didPrepareRendererNativeBridgeTokenRevocationSeparationPolicy =
            didPrepareRendererNativeBridgeTokenRevocationSeparationPolicy
        this
            .shouldDeferRendererNativeBridgeTokenRevocationSeparationPolicy =
            shouldDeferRendererNativeBridgeTokenRevocationSeparationPolicy
        this
            .shouldReportRendererNativeBridgeTokenRevocationSeparationPolicyBlocked =
            shouldReportRendererNativeBridgeTokenRevocationSeparationPolicyBlocked
        this.didPreserveRendererNativeBridgeTokenTableMutabilityPolicy =
            didPreserveRendererNativeBridgeTokenTableMutabilityPolicy
        this.didSeparateRevocationFromDestroy =
            didSeparateRevocationFromDestroy
        this.didDenyRetainReleaseDestroy = didDenyRetainReleaseDestroy
        this.didDenyNativeLifecycleMutation =
            didDenyNativeLifecycleMutation
        this.didRequireRevokeWithoutDestroyPolicy =
            didRequireRevokeWithoutDestroyPolicy
        this.didRequireDoubleRevokeFailClosedPolicy =
            didRequireDoubleRevokeFailClosedPolicy
        this.didKeepTokenRevocationSeparationPolicyDehydrated =
            didKeepTokenRevocationSeparationPolicyDehydrated
        this.didAvoidDestroyPermissionWrapper =
            didAvoidDestroyPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoNativeBridgeTokenCallableReadiness {
    let revocationSeparationPolicy:
        CjguiInternalRendererNativeBridgeTokenRevocationSeparationPolicy
    let didPrepareRendererNoNativeBridgeTokenCallableReadiness: Bool
    let shouldDeferRendererNoNativeBridgeTokenCallableReadiness: Bool
    let shouldReportRendererNoNativeBridgeTokenCallableReadinessBlocked:
        Bool
    let didPreserveRendererNativeBridgeTokenRevocationSeparationPolicy:
        Bool
    let didConfirmOpaqueTokenTypePolicy: Bool
    let didConfirmNoPointerTokenPolicy: Bool
    let didConfirmTokenTableMutabilityDenied: Bool
    let didConfirmIssueRevokeImplementationDeferred: Bool
    let didConfirmRevokeWithoutDestroyPolicy: Bool
    let didConfirmMainThreadGatePreserved: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoResourceCallable: Bool
    let didConfirmNoNativeObjectHandleOrPointer: Bool
    let didConfirmNoMetalOrAppKitUsage: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoNativeBridgeTokenCallableReadinessDehydrated: Bool
    let didAvoidNativeHandlePermissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        revocationSeparationPolicy:
            CjguiInternalRendererNativeBridgeTokenRevocationSeparationPolicy,
        didPrepareRendererNoNativeBridgeTokenCallableReadiness: Bool,
        shouldDeferRendererNoNativeBridgeTokenCallableReadiness: Bool,
        shouldReportRendererNoNativeBridgeTokenCallableReadinessBlocked:
            Bool,
        didPreserveRendererNativeBridgeTokenRevocationSeparationPolicy:
            Bool,
        didConfirmOpaqueTokenTypePolicy: Bool,
        didConfirmNoPointerTokenPolicy: Bool,
        didConfirmTokenTableMutabilityDenied: Bool,
        didConfirmIssueRevokeImplementationDeferred: Bool,
        didConfirmRevokeWithoutDestroyPolicy: Bool,
        didConfirmMainThreadGatePreserved: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoResourceCallable: Bool,
        didConfirmNoNativeObjectHandleOrPointer: Bool,
        didConfirmNoMetalOrAppKitUsage: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoNativeBridgeTokenCallableReadinessDehydrated: Bool,
        didAvoidNativeHandlePermissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.revocationSeparationPolicy = revocationSeparationPolicy
        this.didPrepareRendererNoNativeBridgeTokenCallableReadiness =
            didPrepareRendererNoNativeBridgeTokenCallableReadiness
        this.shouldDeferRendererNoNativeBridgeTokenCallableReadiness =
            shouldDeferRendererNoNativeBridgeTokenCallableReadiness
        this
            .shouldReportRendererNoNativeBridgeTokenCallableReadinessBlocked =
            shouldReportRendererNoNativeBridgeTokenCallableReadinessBlocked
        this.didPreserveRendererNativeBridgeTokenRevocationSeparationPolicy =
            didPreserveRendererNativeBridgeTokenRevocationSeparationPolicy
        this.didConfirmOpaqueTokenTypePolicy =
            didConfirmOpaqueTokenTypePolicy
        this.didConfirmNoPointerTokenPolicy =
            didConfirmNoPointerTokenPolicy
        this.didConfirmTokenTableMutabilityDenied =
            didConfirmTokenTableMutabilityDenied
        this.didConfirmIssueRevokeImplementationDeferred =
            didConfirmIssueRevokeImplementationDeferred
        this.didConfirmRevokeWithoutDestroyPolicy =
            didConfirmRevokeWithoutDestroyPolicy
        this.didConfirmMainThreadGatePreserved =
            didConfirmMainThreadGatePreserved
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoResourceCallable = didConfirmNoResourceCallable
        this.didConfirmNoNativeObjectHandleOrPointer =
            didConfirmNoNativeObjectHandleOrPointer
        this.didConfirmNoMetalOrAppKitUsage =
            didConfirmNoMetalOrAppKitUsage
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNoNativeBridgeTokenCallableReadinessDehydrated =
            didKeepNoNativeBridgeTokenCallableReadinessDehydrated
        this.didAvoidNativeHandlePermissionWrapper =
            didAvoidNativeHandlePermissionWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererNativeBridgeTokenCallableReadiness(
    mainThreadCallReadiness:
        CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness
): CjguiInternalRendererNoNativeBridgeTokenCallableReadiness {
    let upstreamReady =
        mainThreadCallReadiness
            .didPrepareRendererNoNativeBridgeMainThreadCallReadiness &&
        mainThreadCallReadiness.didConfirmMainThreadQueryObserved &&
        mainThreadCallReadiness.didConfirmNoPublicSurface &&
        mainThreadCallReadiness.didConfirmNoResourceCallable &&
        mainThreadCallReadiness.didConfirmNoNativeObjectHandleOrPointer &&
        mainThreadCallReadiness
            .didConfirmNoFoundationCocoaMetalOrQuartzCoreImport &&
        mainThreadCallReadiness.didConfirmNoRendererStateWrite &&
        mainThreadCallReadiness.didConfirmNoBackendReadyTruth
    let shouldDeferTokenImplementation = true
    let intent = CjguiInternalRendererNativeBridgeTokenCallableIntent(
        mainThreadCallReadiness,
        upstreamReady,
        !upstreamReady,
        !upstreamReady,
        upstreamReady,
        true,
        true,
        shouldDeferTokenImplementation,
        true,
        true,
        true
    )
    let typePolicy = CjguiInternalRendererOpaqueTokenCallableTypePolicy(
        intent,
        upstreamReady,
        !upstreamReady,
        !upstreamReady,
        upstreamReady,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
    let tablePolicy =
        CjguiInternalRendererNativeBridgeTokenTableMutabilityPolicy(
            typePolicy,
            upstreamReady,
            true,
            false,
            upstreamReady,
            true,
            true,
            true,
            true,
            true,
            true,
            true,
            true
        )
    let revocationPolicy =
        CjguiInternalRendererNativeBridgeTokenRevocationSeparationPolicy(
            tablePolicy,
            upstreamReady,
            true,
            false,
            upstreamReady,
            true,
            true,
            true,
            true,
            true,
            true,
            true,
            true
        )
    return CjguiInternalRendererNoNativeBridgeTokenCallableReadiness(
        revocationPolicy,
        upstreamReady,
        true,
        false,
        upstreamReady,
        true,
        true,
        true,
        true,
        true,
        upstreamReady,
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

func cjguiInternalExecuteDefaultRendererNativeBridgeTokenCallableDraft():
    CjguiInternalRendererNoNativeBridgeTokenCallableReadiness {
    let mainThreadCallReadiness =
        cjguiInternalExecuteDefaultRendererNativeBridgeMainThreadCallDraft()
    return cjguiInternalBuildRendererNativeBridgeTokenCallableReadiness(
        mainThreadCallReadiness
    )
}
