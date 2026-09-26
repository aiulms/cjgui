// Owner: native bridge teardown callable planning value boundary。
// Truth: 只消费 CjguiInternalRendererNoNativeTokenTableOwnershipReadiness，
// 记录 no-destroy callable policy、revoke-before-destroy callable policy、
// double-destroy / dangling-token classification policy、main-thread
// destroy callable gate policy 与 no-native-bridge-teardown-callable
// readiness facts。
// Stop-line: 不新增 teardown C ABI，不执行真实 destroy，不调用 retain /
// release / destroy，不实现 token table，不创建 native object / handle /
// pointer，不返回 native pointer，不改 runtime_state.cj，不把 teardown
// callable planning 解释成 native bridge ready 或 backend-ready truth。
// Same-shape Boundary Brake: 不得把本 owner 包成 destroy permission、
// native object permission、native handle permission、resource creation、
// Metal/AppKit、backend-ready、public API、receipt、record 或 publication
// wrapper。
package cjgui

struct CjguiInternalRendererNativeBridgeTeardownCallableIntent {
    let tokenTableOwnershipReadiness:
        CjguiInternalRendererNoNativeTokenTableOwnershipReadiness
    let didPrepareRendererNativeBridgeTeardownCallableIntent: Bool
    let shouldDeferRendererNativeBridgeTeardownCallableIntent: Bool
    let shouldReportRendererNativeBridgeTeardownCallableIntentBlocked: Bool
    let didPreserveRendererNativeTokenTableOwnershipReadiness: Bool
    let didDefineFutureNativeBridgeTeardownCallableIntent: Bool
    let didRequirePlanningBeforeCallableImplementation: Bool
    let didKeepTeardownCallableIntentDehydrated: Bool
    let didAvoidDestroyPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        tokenTableOwnershipReadiness:
            CjguiInternalRendererNoNativeTokenTableOwnershipReadiness,
        didPrepareRendererNativeBridgeTeardownCallableIntent: Bool,
        shouldDeferRendererNativeBridgeTeardownCallableIntent: Bool,
        shouldReportRendererNativeBridgeTeardownCallableIntentBlocked: Bool,
        didPreserveRendererNativeTokenTableOwnershipReadiness: Bool,
        didDefineFutureNativeBridgeTeardownCallableIntent: Bool,
        didRequirePlanningBeforeCallableImplementation: Bool,
        didKeepTeardownCallableIntentDehydrated: Bool,
        didAvoidDestroyPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.tokenTableOwnershipReadiness = tokenTableOwnershipReadiness
        this.didPrepareRendererNativeBridgeTeardownCallableIntent =
            didPrepareRendererNativeBridgeTeardownCallableIntent
        this.shouldDeferRendererNativeBridgeTeardownCallableIntent =
            shouldDeferRendererNativeBridgeTeardownCallableIntent
        this
            .shouldReportRendererNativeBridgeTeardownCallableIntentBlocked =
            shouldReportRendererNativeBridgeTeardownCallableIntentBlocked
        this.didPreserveRendererNativeTokenTableOwnershipReadiness =
            didPreserveRendererNativeTokenTableOwnershipReadiness
        this.didDefineFutureNativeBridgeTeardownCallableIntent =
            didDefineFutureNativeBridgeTeardownCallableIntent
        this.didRequirePlanningBeforeCallableImplementation =
            didRequirePlanningBeforeCallableImplementation
        this.didKeepTeardownCallableIntentDehydrated =
            didKeepTeardownCallableIntentDehydrated
        this.didAvoidDestroyPermissionWrapper =
            didAvoidDestroyPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoDestroyCallablePolicy {
    let teardownCallableIntent:
        CjguiInternalRendererNativeBridgeTeardownCallableIntent
    let didPrepareRendererNoDestroyCallablePolicy: Bool
    let shouldDeferRendererNoDestroyCallablePolicy: Bool
    let shouldReportRendererNoDestroyCallablePolicyBlocked: Bool
    let didPreserveRendererNativeBridgeTeardownCallableIntent: Bool
    let didRequireTeardownAdmissionOnly: Bool
    let didForbidActualDestroyRetainRelease: Bool
    let didForbidDestroyCallbackImplementation: Bool
    let didKeepNoDestroyCallablePolicyDehydrated: Bool
    let didAvoidNativeBridgeImplementationWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        teardownCallableIntent:
            CjguiInternalRendererNativeBridgeTeardownCallableIntent,
        didPrepareRendererNoDestroyCallablePolicy: Bool,
        shouldDeferRendererNoDestroyCallablePolicy: Bool,
        shouldReportRendererNoDestroyCallablePolicyBlocked: Bool,
        didPreserveRendererNativeBridgeTeardownCallableIntent: Bool,
        didRequireTeardownAdmissionOnly: Bool,
        didForbidActualDestroyRetainRelease: Bool,
        didForbidDestroyCallbackImplementation: Bool,
        didKeepNoDestroyCallablePolicyDehydrated: Bool,
        didAvoidNativeBridgeImplementationWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.teardownCallableIntent = teardownCallableIntent
        this.didPrepareRendererNoDestroyCallablePolicy =
            didPrepareRendererNoDestroyCallablePolicy
        this.shouldDeferRendererNoDestroyCallablePolicy =
            shouldDeferRendererNoDestroyCallablePolicy
        this.shouldReportRendererNoDestroyCallablePolicyBlocked =
            shouldReportRendererNoDestroyCallablePolicyBlocked
        this.didPreserveRendererNativeBridgeTeardownCallableIntent =
            didPreserveRendererNativeBridgeTeardownCallableIntent
        this.didRequireTeardownAdmissionOnly =
            didRequireTeardownAdmissionOnly
        this.didForbidActualDestroyRetainRelease =
            didForbidActualDestroyRetainRelease
        this.didForbidDestroyCallbackImplementation =
            didForbidDestroyCallbackImplementation
        this.didKeepNoDestroyCallablePolicyDehydrated =
            didKeepNoDestroyCallablePolicyDehydrated
        this.didAvoidNativeBridgeImplementationWrapper =
            didAvoidNativeBridgeImplementationWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRevokeBeforeDestroyCallablePolicy {
    let noDestroyCallablePolicy:
        CjguiInternalRendererNoDestroyCallablePolicy
    let didPrepareRendererRevokeBeforeDestroyCallablePolicy: Bool
    let shouldDeferRendererRevokeBeforeDestroyCallablePolicy: Bool
    let shouldReportRendererRevokeBeforeDestroyCallablePolicyBlocked: Bool
    let didPreserveRendererNoDestroyCallablePolicy: Bool
    let didRequireRevokeBeforeDestroyOrdering: Bool
    let didRequireTokenInvalidationBeforeNativeLifecycle: Bool
    let didForbidTokenTableMutationInCurrentSlice: Bool
    let didKeepRevokeBeforeDestroyCallablePolicyDehydrated: Bool
    let didAvoidTokenTableImplementationWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        noDestroyCallablePolicy:
            CjguiInternalRendererNoDestroyCallablePolicy,
        didPrepareRendererRevokeBeforeDestroyCallablePolicy: Bool,
        shouldDeferRendererRevokeBeforeDestroyCallablePolicy: Bool,
        shouldReportRendererRevokeBeforeDestroyCallablePolicyBlocked: Bool,
        didPreserveRendererNoDestroyCallablePolicy: Bool,
        didRequireRevokeBeforeDestroyOrdering: Bool,
        didRequireTokenInvalidationBeforeNativeLifecycle: Bool,
        didForbidTokenTableMutationInCurrentSlice: Bool,
        didKeepRevokeBeforeDestroyCallablePolicyDehydrated: Bool,
        didAvoidTokenTableImplementationWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noDestroyCallablePolicy = noDestroyCallablePolicy
        this.didPrepareRendererRevokeBeforeDestroyCallablePolicy =
            didPrepareRendererRevokeBeforeDestroyCallablePolicy
        this.shouldDeferRendererRevokeBeforeDestroyCallablePolicy =
            shouldDeferRendererRevokeBeforeDestroyCallablePolicy
        this
            .shouldReportRendererRevokeBeforeDestroyCallablePolicyBlocked =
            shouldReportRendererRevokeBeforeDestroyCallablePolicyBlocked
        this.didPreserveRendererNoDestroyCallablePolicy =
            didPreserveRendererNoDestroyCallablePolicy
        this.didRequireRevokeBeforeDestroyOrdering =
            didRequireRevokeBeforeDestroyOrdering
        this.didRequireTokenInvalidationBeforeNativeLifecycle =
            didRequireTokenInvalidationBeforeNativeLifecycle
        this.didForbidTokenTableMutationInCurrentSlice =
            didForbidTokenTableMutationInCurrentSlice
        this.didKeepRevokeBeforeDestroyCallablePolicyDehydrated =
            didKeepRevokeBeforeDestroyCallablePolicyDehydrated
        this.didAvoidTokenTableImplementationWrapper =
            didAvoidTokenTableImplementationWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererTeardownCallableFailureClassificationPolicy {
    let revokeBeforeDestroyCallablePolicy:
        CjguiInternalRendererRevokeBeforeDestroyCallablePolicy
    let didPrepareRendererTeardownCallableFailureClassificationPolicy:
        Bool
    let shouldDeferRendererTeardownCallableFailureClassificationPolicy:
        Bool
    let shouldReportRendererTeardownCallableFailureClassificationPolicyBlocked:
        Bool
    let didPreserveRendererRevokeBeforeDestroyCallablePolicy: Bool
    let didClassifyDoubleDestroy: Bool
    let didClassifyDanglingToken: Bool
    let didClassifyDoubleRevoke: Bool
    let didClassifyMissingTokenTable: Bool
    let didKeepFailureClassificationPolicyDehydrated: Bool
    let didAvoidDiagnosticsWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        revokeBeforeDestroyCallablePolicy:
            CjguiInternalRendererRevokeBeforeDestroyCallablePolicy,
        didPrepareRendererTeardownCallableFailureClassificationPolicy:
            Bool,
        shouldDeferRendererTeardownCallableFailureClassificationPolicy:
            Bool,
        shouldReportRendererTeardownCallableFailureClassificationPolicyBlocked:
            Bool,
        didPreserveRendererRevokeBeforeDestroyCallablePolicy: Bool,
        didClassifyDoubleDestroy: Bool,
        didClassifyDanglingToken: Bool,
        didClassifyDoubleRevoke: Bool,
        didClassifyMissingTokenTable: Bool,
        didKeepFailureClassificationPolicyDehydrated: Bool,
        didAvoidDiagnosticsWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.revokeBeforeDestroyCallablePolicy =
            revokeBeforeDestroyCallablePolicy
        this
            .didPrepareRendererTeardownCallableFailureClassificationPolicy =
            didPrepareRendererTeardownCallableFailureClassificationPolicy
        this
            .shouldDeferRendererTeardownCallableFailureClassificationPolicy =
            shouldDeferRendererTeardownCallableFailureClassificationPolicy
        this
            .shouldReportRendererTeardownCallableFailureClassificationPolicyBlocked =
            shouldReportRendererTeardownCallableFailureClassificationPolicyBlocked
        this.didPreserveRendererRevokeBeforeDestroyCallablePolicy =
            didPreserveRendererRevokeBeforeDestroyCallablePolicy
        this.didClassifyDoubleDestroy = didClassifyDoubleDestroy
        this.didClassifyDanglingToken = didClassifyDanglingToken
        this.didClassifyDoubleRevoke = didClassifyDoubleRevoke
        this.didClassifyMissingTokenTable = didClassifyMissingTokenTable
        this.didKeepFailureClassificationPolicyDehydrated =
            didKeepFailureClassificationPolicyDehydrated
        this.didAvoidDiagnosticsWrapper = didAvoidDiagnosticsWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererMainThreadDestroyCallableGatePolicy {
    let failureClassificationPolicy:
        CjguiInternalRendererTeardownCallableFailureClassificationPolicy
    let didPrepareRendererMainThreadDestroyCallableGatePolicy: Bool
    let shouldDeferRendererMainThreadDestroyCallableGatePolicy: Bool
    let shouldReportRendererMainThreadDestroyCallableGatePolicyBlocked: Bool
    let didPreserveRendererTeardownCallableFailureClassificationPolicy:
        Bool
    let didRequireMainThreadDestroyConfinement: Bool
    let didUseMainThreadQueryAsEvidenceOnly: Bool
    let didForbidMainThreadDispatchInCurrentSlice: Bool
    let didKeepMainThreadDestroyCallableGatePolicyDehydrated: Bool
    let didAvoidAppKitPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        failureClassificationPolicy:
            CjguiInternalRendererTeardownCallableFailureClassificationPolicy,
        didPrepareRendererMainThreadDestroyCallableGatePolicy: Bool,
        shouldDeferRendererMainThreadDestroyCallableGatePolicy: Bool,
        shouldReportRendererMainThreadDestroyCallableGatePolicyBlocked: Bool,
        didPreserveRendererTeardownCallableFailureClassificationPolicy:
            Bool,
        didRequireMainThreadDestroyConfinement: Bool,
        didUseMainThreadQueryAsEvidenceOnly: Bool,
        didForbidMainThreadDispatchInCurrentSlice: Bool,
        didKeepMainThreadDestroyCallableGatePolicyDehydrated: Bool,
        didAvoidAppKitPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.failureClassificationPolicy = failureClassificationPolicy
        this.didPrepareRendererMainThreadDestroyCallableGatePolicy =
            didPrepareRendererMainThreadDestroyCallableGatePolicy
        this.shouldDeferRendererMainThreadDestroyCallableGatePolicy =
            shouldDeferRendererMainThreadDestroyCallableGatePolicy
        this
            .shouldReportRendererMainThreadDestroyCallableGatePolicyBlocked =
            shouldReportRendererMainThreadDestroyCallableGatePolicyBlocked
        this
            .didPreserveRendererTeardownCallableFailureClassificationPolicy =
            didPreserveRendererTeardownCallableFailureClassificationPolicy
        this.didRequireMainThreadDestroyConfinement =
            didRequireMainThreadDestroyConfinement
        this.didUseMainThreadQueryAsEvidenceOnly =
            didUseMainThreadQueryAsEvidenceOnly
        this.didForbidMainThreadDispatchInCurrentSlice =
            didForbidMainThreadDispatchInCurrentSlice
        this.didKeepMainThreadDestroyCallableGatePolicyDehydrated =
            didKeepMainThreadDestroyCallableGatePolicyDehydrated
        this.didAvoidAppKitPermissionWrapper =
            didAvoidAppKitPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness {
    let mainThreadDestroyCallableGatePolicy:
        CjguiInternalRendererMainThreadDestroyCallableGatePolicy
    let didPrepareRendererNoNativeBridgeTeardownCallableReadiness: Bool
    let shouldDeferRendererNoNativeBridgeTeardownCallableReadiness: Bool
    let shouldReportRendererNoNativeBridgeTeardownCallableReadinessBlocked:
        Bool
    let didPreserveRendererMainThreadDestroyCallableGatePolicy: Bool
    let didConfirmNoDestroyCallablePolicy: Bool
    let didConfirmRevokeBeforeDestroyCallablePolicy: Bool
    let didConfirmDoubleDestroyDanglingTokenClassification: Bool
    let didConfirmMainThreadDestroyCallableGatePolicy: Bool
    let didConfirmNoTeardownCAbiImplementation: Bool
    let didConfirmNoActualDestroyRetainRelease: Bool
    let didConfirmNoTokenTableImplementation: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoResourceCallable: Bool
    let didConfirmNoNativeObjectHandleOrPointer: Bool
    let didConfirmNoMetalOrAppKitUsage: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoNativeBridgeTeardownCallableReadinessDehydrated: Bool
    let didAvoidDestroyPermissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        mainThreadDestroyCallableGatePolicy:
            CjguiInternalRendererMainThreadDestroyCallableGatePolicy,
        didPrepareRendererNoNativeBridgeTeardownCallableReadiness: Bool,
        shouldDeferRendererNoNativeBridgeTeardownCallableReadiness: Bool,
        shouldReportRendererNoNativeBridgeTeardownCallableReadinessBlocked:
            Bool,
        didPreserveRendererMainThreadDestroyCallableGatePolicy: Bool,
        didConfirmNoDestroyCallablePolicy: Bool,
        didConfirmRevokeBeforeDestroyCallablePolicy: Bool,
        didConfirmDoubleDestroyDanglingTokenClassification: Bool,
        didConfirmMainThreadDestroyCallableGatePolicy: Bool,
        didConfirmNoTeardownCAbiImplementation: Bool,
        didConfirmNoActualDestroyRetainRelease: Bool,
        didConfirmNoTokenTableImplementation: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoResourceCallable: Bool,
        didConfirmNoNativeObjectHandleOrPointer: Bool,
        didConfirmNoMetalOrAppKitUsage: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoNativeBridgeTeardownCallableReadinessDehydrated: Bool,
        didAvoidDestroyPermissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.mainThreadDestroyCallableGatePolicy =
            mainThreadDestroyCallableGatePolicy
        this
            .didPrepareRendererNoNativeBridgeTeardownCallableReadiness =
            didPrepareRendererNoNativeBridgeTeardownCallableReadiness
        this.shouldDeferRendererNoNativeBridgeTeardownCallableReadiness =
            shouldDeferRendererNoNativeBridgeTeardownCallableReadiness
        this
            .shouldReportRendererNoNativeBridgeTeardownCallableReadinessBlocked =
            shouldReportRendererNoNativeBridgeTeardownCallableReadinessBlocked
        this.didPreserveRendererMainThreadDestroyCallableGatePolicy =
            didPreserveRendererMainThreadDestroyCallableGatePolicy
        this.didConfirmNoDestroyCallablePolicy =
            didConfirmNoDestroyCallablePolicy
        this.didConfirmRevokeBeforeDestroyCallablePolicy =
            didConfirmRevokeBeforeDestroyCallablePolicy
        this.didConfirmDoubleDestroyDanglingTokenClassification =
            didConfirmDoubleDestroyDanglingTokenClassification
        this.didConfirmMainThreadDestroyCallableGatePolicy =
            didConfirmMainThreadDestroyCallableGatePolicy
        this.didConfirmNoTeardownCAbiImplementation =
            didConfirmNoTeardownCAbiImplementation
        this.didConfirmNoActualDestroyRetainRelease =
            didConfirmNoActualDestroyRetainRelease
        this.didConfirmNoTokenTableImplementation =
            didConfirmNoTokenTableImplementation
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoResourceCallable = didConfirmNoResourceCallable
        this.didConfirmNoNativeObjectHandleOrPointer =
            didConfirmNoNativeObjectHandleOrPointer
        this.didConfirmNoMetalOrAppKitUsage =
            didConfirmNoMetalOrAppKitUsage
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNoNativeBridgeTeardownCallableReadinessDehydrated =
            didKeepNoNativeBridgeTeardownCallableReadinessDehydrated
        this.didAvoidDestroyPermissionWrapper =
            didAvoidDestroyPermissionWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererNativeBridgeTeardownCallableReadiness(
    tokenTableOwnershipReadiness:
        CjguiInternalRendererNoNativeTokenTableOwnershipReadiness
): CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness {
    let upstreamEvidenceReady =
        tokenTableOwnershipReadiness
            .didPrepareRendererNoNativeTokenTableOwnershipReadiness &&
        tokenTableOwnershipReadiness
            .didConfirmBridgeLocalOpaqueTokenTablePolicy &&
        tokenTableOwnershipReadiness
            .didConfirmTableMutabilityConfinementPolicy &&
        tokenTableOwnershipReadiness.didConfirmNoSecondRendererTruthSource &&
        tokenTableOwnershipReadiness
            .didConfirmGenerationEpochInvalidationPolicy &&
        tokenTableOwnershipReadiness
            .didConfirmRevokeBeforeDestroyOrderingPolicy &&
        tokenTableOwnershipReadiness
            .didConfirmDoubleRevokeDanglingTokenFailureClassification &&
        tokenTableOwnershipReadiness.didConfirmMainThreadConfinementPolicy &&
        tokenTableOwnershipReadiness.didConfirmNoActualTokenTable &&
        tokenTableOwnershipReadiness.didConfirmNoNativeTokenCAbi &&
        tokenTableOwnershipReadiness.didConfirmNoPublicSurface &&
        tokenTableOwnershipReadiness.didConfirmNoResourceCallable &&
        tokenTableOwnershipReadiness.didConfirmNoNativeObjectHandleOrPointer &&
        tokenTableOwnershipReadiness.didConfirmNoRendererStateWrite &&
        tokenTableOwnershipReadiness.didConfirmNoBackendReadyTruth &&
        tokenTableOwnershipReadiness
            .shouldReportRendererNoNativeTokenTableOwnershipReadinessBlocked ==
            false
    let shouldDeferTeardownCallableImplementation = true
    let intent =
        CjguiInternalRendererNativeBridgeTeardownCallableIntent(
            tokenTableOwnershipReadiness,
            upstreamEvidenceReady,
            shouldDeferTeardownCallableImplementation,
            false,
            upstreamEvidenceReady,
            true,
            true,
            true,
            true,
            true
        )
    let noDestroyPolicy =
        CjguiInternalRendererNoDestroyCallablePolicy(
            intent,
            upstreamEvidenceReady,
            shouldDeferTeardownCallableImplementation,
            false,
            upstreamEvidenceReady,
            true,
            true,
            true,
            true,
            true,
            true
        )
    let orderingPolicy =
        CjguiInternalRendererRevokeBeforeDestroyCallablePolicy(
            noDestroyPolicy,
            upstreamEvidenceReady,
            shouldDeferTeardownCallableImplementation,
            false,
            upstreamEvidenceReady,
            true,
            true,
            true,
            true,
            true,
            true
        )
    let failurePolicy =
        CjguiInternalRendererTeardownCallableFailureClassificationPolicy(
            orderingPolicy,
            upstreamEvidenceReady,
            shouldDeferTeardownCallableImplementation,
            false,
            upstreamEvidenceReady,
            true,
            true,
            true,
            true,
            true,
            true,
            true
        )
    let mainThreadGatePolicy =
        CjguiInternalRendererMainThreadDestroyCallableGatePolicy(
            failurePolicy,
            upstreamEvidenceReady,
            shouldDeferTeardownCallableImplementation,
            false,
            upstreamEvidenceReady,
            true,
            true,
            true,
            true,
            true,
            true
        )
    return CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness(
        mainThreadGatePolicy,
        upstreamEvidenceReady,
        shouldDeferTeardownCallableImplementation,
        false,
        upstreamEvidenceReady,
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
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererNativeBridgeTeardownCallableDraft():
    CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness {
    let tokenTableOwnershipReadiness =
        cjguiInternalExecuteDefaultRendererNativeTokenTableOwnershipDraft()
    return cjguiInternalBuildRendererNativeBridgeTeardownCallableReadiness(
        tokenTableOwnershipReadiness
    )
}
