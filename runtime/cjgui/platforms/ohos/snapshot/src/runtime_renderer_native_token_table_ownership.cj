// Owner: native token table ownership hardening value boundary。
// Truth: 只消费 CjguiInternalRendererNoNativeBridgeTokenCallableReadiness，
// 记录 bridge-local opaque token table ownership、table mutability
// confinement、generation / epoch invalidation、revoke-before-destroy
// ordering、double-revoke / dangling-token failure classification 与
// no-native-token-table-ownership readiness facts。
// Stop-line: 不实现 token table，不新增 native token C ABI，不创建
// native object / handle / pointer，不返回 native pointer，不改
// runtime_state.cj，不把 token table policy 解释成 native resource ready
// 或 backend-ready truth。
// Same-shape Boundary Brake: 不得把本 owner 包成 token table
// implementation permission、native handle permission、native object、
// destroy permission、Metal/AppKit、backend-ready、public API、receipt、
// record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererNativeTokenTableOwnershipIntent {
    let tokenCallableReadiness:
        CjguiInternalRendererNoNativeBridgeTokenCallableReadiness
    let didPrepareRendererNativeTokenTableOwnershipIntent: Bool
    let shouldDeferRendererNativeTokenTableOwnershipIntent: Bool
    let shouldReportRendererNativeTokenTableOwnershipIntentBlocked: Bool
    let didPreserveRendererNativeBridgeTokenCallableReadiness: Bool
    let didDefineFutureNativeTokenTableOwnershipIntent: Bool
    let didRequireValueBoundaryBeforeImplementation: Bool
    let didKeepTokenTableOutOfCurrentRuntimeTruth: Bool
    let didKeepNativeTokenTableOwnershipIntentDehydrated: Bool
    let didAvoidTokenTableImplementationWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        tokenCallableReadiness:
            CjguiInternalRendererNoNativeBridgeTokenCallableReadiness,
        didPrepareRendererNativeTokenTableOwnershipIntent: Bool,
        shouldDeferRendererNativeTokenTableOwnershipIntent: Bool,
        shouldReportRendererNativeTokenTableOwnershipIntentBlocked: Bool,
        didPreserveRendererNativeBridgeTokenCallableReadiness: Bool,
        didDefineFutureNativeTokenTableOwnershipIntent: Bool,
        didRequireValueBoundaryBeforeImplementation: Bool,
        didKeepTokenTableOutOfCurrentRuntimeTruth: Bool,
        didKeepNativeTokenTableOwnershipIntentDehydrated: Bool,
        didAvoidTokenTableImplementationWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.tokenCallableReadiness = tokenCallableReadiness
        this.didPrepareRendererNativeTokenTableOwnershipIntent =
            didPrepareRendererNativeTokenTableOwnershipIntent
        this.shouldDeferRendererNativeTokenTableOwnershipIntent =
            shouldDeferRendererNativeTokenTableOwnershipIntent
        this
            .shouldReportRendererNativeTokenTableOwnershipIntentBlocked =
            shouldReportRendererNativeTokenTableOwnershipIntentBlocked
        this.didPreserveRendererNativeBridgeTokenCallableReadiness =
            didPreserveRendererNativeBridgeTokenCallableReadiness
        this.didDefineFutureNativeTokenTableOwnershipIntent =
            didDefineFutureNativeTokenTableOwnershipIntent
        this.didRequireValueBoundaryBeforeImplementation =
            didRequireValueBoundaryBeforeImplementation
        this.didKeepTokenTableOutOfCurrentRuntimeTruth =
            didKeepTokenTableOutOfCurrentRuntimeTruth
        this.didKeepNativeTokenTableOwnershipIntentDehydrated =
            didKeepNativeTokenTableOwnershipIntentDehydrated
        this.didAvoidTokenTableImplementationWrapper =
            didAvoidTokenTableImplementationWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererBridgeLocalOpaqueTokenTablePolicy {
    let ownershipIntent:
        CjguiInternalRendererNativeTokenTableOwnershipIntent
    let didPrepareRendererBridgeLocalOpaqueTokenTablePolicy: Bool
    let shouldDeferRendererBridgeLocalOpaqueTokenTablePolicy: Bool
    let shouldReportRendererBridgeLocalOpaqueTokenTablePolicyBlocked: Bool
    let didPreserveRendererNativeTokenTableOwnershipIntent: Bool
    let didRequireBridgeLocalOpaqueTokenIdentifier: Bool
    let didForbidTokenEncodingNativePointer: Bool
    let didForbidRuntimePublicTokenSurface: Bool
    let didForbidObjectiveCTruthSource: Bool
    let didKeepOpaqueTokenTablePolicyDehydrated: Bool
    let didAvoidNativeHandlePermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        ownershipIntent:
            CjguiInternalRendererNativeTokenTableOwnershipIntent,
        didPrepareRendererBridgeLocalOpaqueTokenTablePolicy: Bool,
        shouldDeferRendererBridgeLocalOpaqueTokenTablePolicy: Bool,
        shouldReportRendererBridgeLocalOpaqueTokenTablePolicyBlocked: Bool,
        didPreserveRendererNativeTokenTableOwnershipIntent: Bool,
        didRequireBridgeLocalOpaqueTokenIdentifier: Bool,
        didForbidTokenEncodingNativePointer: Bool,
        didForbidRuntimePublicTokenSurface: Bool,
        didForbidObjectiveCTruthSource: Bool,
        didKeepOpaqueTokenTablePolicyDehydrated: Bool,
        didAvoidNativeHandlePermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.ownershipIntent = ownershipIntent
        this.didPrepareRendererBridgeLocalOpaqueTokenTablePolicy =
            didPrepareRendererBridgeLocalOpaqueTokenTablePolicy
        this.shouldDeferRendererBridgeLocalOpaqueTokenTablePolicy =
            shouldDeferRendererBridgeLocalOpaqueTokenTablePolicy
        this
            .shouldReportRendererBridgeLocalOpaqueTokenTablePolicyBlocked =
            shouldReportRendererBridgeLocalOpaqueTokenTablePolicyBlocked
        this.didPreserveRendererNativeTokenTableOwnershipIntent =
            didPreserveRendererNativeTokenTableOwnershipIntent
        this.didRequireBridgeLocalOpaqueTokenIdentifier =
            didRequireBridgeLocalOpaqueTokenIdentifier
        this.didForbidTokenEncodingNativePointer =
            didForbidTokenEncodingNativePointer
        this.didForbidRuntimePublicTokenSurface =
            didForbidRuntimePublicTokenSurface
        this.didForbidObjectiveCTruthSource =
            didForbidObjectiveCTruthSource
        this.didKeepOpaqueTokenTablePolicyDehydrated =
            didKeepOpaqueTokenTablePolicyDehydrated
        this.didAvoidNativeHandlePermissionWrapper =
            didAvoidNativeHandlePermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeTokenTableMutabilityConfinementPolicy {
    let opaqueTokenTablePolicy:
        CjguiInternalRendererBridgeLocalOpaqueTokenTablePolicy
    let didPrepareRendererNativeTokenTableMutabilityConfinementPolicy: Bool
    let shouldDeferRendererNativeTokenTableMutabilityConfinementPolicy:
        Bool
    let shouldReportRendererNativeTokenTableMutabilityConfinementPolicyBlocked:
        Bool
    let didPreserveRendererBridgeLocalOpaqueTokenTablePolicy: Bool
    let didDenyCurrentTokenTableImplementation: Bool
    let didRequireFutureBridgePrivateOwner: Bool
    let didRequireMainThreadConfinement: Bool
    let didDenySecondRendererTruthSource: Bool
    let didKeepMutabilityConfinementPolicyDehydrated: Bool
    let didAvoidMutableStateWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        opaqueTokenTablePolicy:
            CjguiInternalRendererBridgeLocalOpaqueTokenTablePolicy,
        didPrepareRendererNativeTokenTableMutabilityConfinementPolicy: Bool,
        shouldDeferRendererNativeTokenTableMutabilityConfinementPolicy:
            Bool,
        shouldReportRendererNativeTokenTableMutabilityConfinementPolicyBlocked:
            Bool,
        didPreserveRendererBridgeLocalOpaqueTokenTablePolicy: Bool,
        didDenyCurrentTokenTableImplementation: Bool,
        didRequireFutureBridgePrivateOwner: Bool,
        didRequireMainThreadConfinement: Bool,
        didDenySecondRendererTruthSource: Bool,
        didKeepMutabilityConfinementPolicyDehydrated: Bool,
        didAvoidMutableStateWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.opaqueTokenTablePolicy = opaqueTokenTablePolicy
        this
            .didPrepareRendererNativeTokenTableMutabilityConfinementPolicy =
            didPrepareRendererNativeTokenTableMutabilityConfinementPolicy
        this
            .shouldDeferRendererNativeTokenTableMutabilityConfinementPolicy =
            shouldDeferRendererNativeTokenTableMutabilityConfinementPolicy
        this
            .shouldReportRendererNativeTokenTableMutabilityConfinementPolicyBlocked =
            shouldReportRendererNativeTokenTableMutabilityConfinementPolicyBlocked
        this.didPreserveRendererBridgeLocalOpaqueTokenTablePolicy =
            didPreserveRendererBridgeLocalOpaqueTokenTablePolicy
        this.didDenyCurrentTokenTableImplementation =
            didDenyCurrentTokenTableImplementation
        this.didRequireFutureBridgePrivateOwner =
            didRequireFutureBridgePrivateOwner
        this.didRequireMainThreadConfinement =
            didRequireMainThreadConfinement
        this.didDenySecondRendererTruthSource =
            didDenySecondRendererTruthSource
        this.didKeepMutabilityConfinementPolicyDehydrated =
            didKeepMutabilityConfinementPolicyDehydrated
        this.didAvoidMutableStateWrapper = didAvoidMutableStateWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeTokenGenerationInvalidationPolicy {
    let mutabilityConfinementPolicy:
        CjguiInternalRendererNativeTokenTableMutabilityConfinementPolicy
    let didPrepareRendererNativeTokenGenerationInvalidationPolicy: Bool
    let shouldDeferRendererNativeTokenGenerationInvalidationPolicy: Bool
    let shouldReportRendererNativeTokenGenerationInvalidationPolicyBlocked:
        Bool
    let didPreserveRendererNativeTokenTableMutabilityConfinementPolicy:
        Bool
    let didRequireGenerationEpochFacts: Bool
    let didRequireStaleGenerationFailClosed: Bool
    let didRequireDanglingTokenFailClosed: Bool
    let didRequireInvalidationBeforeReuse: Bool
    let didKeepGenerationInvalidationPolicyDehydrated: Bool
    let didAvoidTokenReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        mutabilityConfinementPolicy:
            CjguiInternalRendererNativeTokenTableMutabilityConfinementPolicy,
        didPrepareRendererNativeTokenGenerationInvalidationPolicy: Bool,
        shouldDeferRendererNativeTokenGenerationInvalidationPolicy: Bool,
        shouldReportRendererNativeTokenGenerationInvalidationPolicyBlocked:
            Bool,
        didPreserveRendererNativeTokenTableMutabilityConfinementPolicy:
            Bool,
        didRequireGenerationEpochFacts: Bool,
        didRequireStaleGenerationFailClosed: Bool,
        didRequireDanglingTokenFailClosed: Bool,
        didRequireInvalidationBeforeReuse: Bool,
        didKeepGenerationInvalidationPolicyDehydrated: Bool,
        didAvoidTokenReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.mutabilityConfinementPolicy = mutabilityConfinementPolicy
        this.didPrepareRendererNativeTokenGenerationInvalidationPolicy =
            didPrepareRendererNativeTokenGenerationInvalidationPolicy
        this.shouldDeferRendererNativeTokenGenerationInvalidationPolicy =
            shouldDeferRendererNativeTokenGenerationInvalidationPolicy
        this
            .shouldReportRendererNativeTokenGenerationInvalidationPolicyBlocked =
            shouldReportRendererNativeTokenGenerationInvalidationPolicyBlocked
        this
            .didPreserveRendererNativeTokenTableMutabilityConfinementPolicy =
            didPreserveRendererNativeTokenTableMutabilityConfinementPolicy
        this.didRequireGenerationEpochFacts =
            didRequireGenerationEpochFacts
        this.didRequireStaleGenerationFailClosed =
            didRequireStaleGenerationFailClosed
        this.didRequireDanglingTokenFailClosed =
            didRequireDanglingTokenFailClosed
        this.didRequireInvalidationBeforeReuse =
            didRequireInvalidationBeforeReuse
        this.didKeepGenerationInvalidationPolicyDehydrated =
            didKeepGenerationInvalidationPolicyDehydrated
        this.didAvoidTokenReadyWrapper = didAvoidTokenReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeTokenRevokeDestroyOrderingPolicy {
    let generationInvalidationPolicy:
        CjguiInternalRendererNativeTokenGenerationInvalidationPolicy
    let didPrepareRendererNativeTokenRevokeDestroyOrderingPolicy: Bool
    let shouldDeferRendererNativeTokenRevokeDestroyOrderingPolicy: Bool
    let shouldReportRendererNativeTokenRevokeDestroyOrderingPolicyBlocked:
        Bool
    let didPreserveRendererNativeTokenGenerationInvalidationPolicy: Bool
    let didRequireRevokeBeforeDestroy: Bool
    let didRequireDestroySeparateFromRevoke: Bool
    let didRequireTableEntryInvalidationAfterDestroyAttempt: Bool
    let didRequireFailureClassificationAfterOrdering: Bool
    let didKeepRevokeDestroyOrderingPolicyDehydrated: Bool
    let didAvoidDestroyPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        generationInvalidationPolicy:
            CjguiInternalRendererNativeTokenGenerationInvalidationPolicy,
        didPrepareRendererNativeTokenRevokeDestroyOrderingPolicy: Bool,
        shouldDeferRendererNativeTokenRevokeDestroyOrderingPolicy: Bool,
        shouldReportRendererNativeTokenRevokeDestroyOrderingPolicyBlocked:
            Bool,
        didPreserveRendererNativeTokenGenerationInvalidationPolicy: Bool,
        didRequireRevokeBeforeDestroy: Bool,
        didRequireDestroySeparateFromRevoke: Bool,
        didRequireTableEntryInvalidationAfterDestroyAttempt: Bool,
        didRequireFailureClassificationAfterOrdering: Bool,
        didKeepRevokeDestroyOrderingPolicyDehydrated: Bool,
        didAvoidDestroyPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.generationInvalidationPolicy = generationInvalidationPolicy
        this.didPrepareRendererNativeTokenRevokeDestroyOrderingPolicy =
            didPrepareRendererNativeTokenRevokeDestroyOrderingPolicy
        this.shouldDeferRendererNativeTokenRevokeDestroyOrderingPolicy =
            shouldDeferRendererNativeTokenRevokeDestroyOrderingPolicy
        this
            .shouldReportRendererNativeTokenRevokeDestroyOrderingPolicyBlocked =
            shouldReportRendererNativeTokenRevokeDestroyOrderingPolicyBlocked
        this.didPreserveRendererNativeTokenGenerationInvalidationPolicy =
            didPreserveRendererNativeTokenGenerationInvalidationPolicy
        this.didRequireRevokeBeforeDestroy = didRequireRevokeBeforeDestroy
        this.didRequireDestroySeparateFromRevoke =
            didRequireDestroySeparateFromRevoke
        this.didRequireTableEntryInvalidationAfterDestroyAttempt =
            didRequireTableEntryInvalidationAfterDestroyAttempt
        this.didRequireFailureClassificationAfterOrdering =
            didRequireFailureClassificationAfterOrdering
        this.didKeepRevokeDestroyOrderingPolicyDehydrated =
            didKeepRevokeDestroyOrderingPolicyDehydrated
        this.didAvoidDestroyPermissionWrapper =
            didAvoidDestroyPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeTokenTableFailureClassificationPolicy {
    let revokeDestroyOrderingPolicy:
        CjguiInternalRendererNativeTokenRevokeDestroyOrderingPolicy
    let didPrepareRendererNativeTokenTableFailureClassificationPolicy:
        Bool
    let shouldDeferRendererNativeTokenTableFailureClassificationPolicy:
        Bool
    let shouldReportRendererNativeTokenTableFailureClassificationPolicyBlocked:
        Bool
    let didPreserveRendererNativeTokenRevokeDestroyOrderingPolicy: Bool
    let didClassifyDoubleRevoke: Bool
    let didClassifyDoubleDestroy: Bool
    let didClassifyDanglingToken: Bool
    let didClassifyWrongThreadTokenMutation: Bool
    let didKeepFailureClassificationPolicyDehydrated: Bool
    let didAvoidDiagnosticsWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        revokeDestroyOrderingPolicy:
            CjguiInternalRendererNativeTokenRevokeDestroyOrderingPolicy,
        didPrepareRendererNativeTokenTableFailureClassificationPolicy:
            Bool,
        shouldDeferRendererNativeTokenTableFailureClassificationPolicy:
            Bool,
        shouldReportRendererNativeTokenTableFailureClassificationPolicyBlocked:
            Bool,
        didPreserveRendererNativeTokenRevokeDestroyOrderingPolicy: Bool,
        didClassifyDoubleRevoke: Bool,
        didClassifyDoubleDestroy: Bool,
        didClassifyDanglingToken: Bool,
        didClassifyWrongThreadTokenMutation: Bool,
        didKeepFailureClassificationPolicyDehydrated: Bool,
        didAvoidDiagnosticsWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.revokeDestroyOrderingPolicy = revokeDestroyOrderingPolicy
        this
            .didPrepareRendererNativeTokenTableFailureClassificationPolicy =
            didPrepareRendererNativeTokenTableFailureClassificationPolicy
        this
            .shouldDeferRendererNativeTokenTableFailureClassificationPolicy =
            shouldDeferRendererNativeTokenTableFailureClassificationPolicy
        this
            .shouldReportRendererNativeTokenTableFailureClassificationPolicyBlocked =
            shouldReportRendererNativeTokenTableFailureClassificationPolicyBlocked
        this.didPreserveRendererNativeTokenRevokeDestroyOrderingPolicy =
            didPreserveRendererNativeTokenRevokeDestroyOrderingPolicy
        this.didClassifyDoubleRevoke = didClassifyDoubleRevoke
        this.didClassifyDoubleDestroy = didClassifyDoubleDestroy
        this.didClassifyDanglingToken = didClassifyDanglingToken
        this.didClassifyWrongThreadTokenMutation =
            didClassifyWrongThreadTokenMutation
        this.didKeepFailureClassificationPolicyDehydrated =
            didKeepFailureClassificationPolicyDehydrated
        this.didAvoidDiagnosticsWrapper = didAvoidDiagnosticsWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoNativeTokenTableOwnershipReadiness {
    let failureClassificationPolicy:
        CjguiInternalRendererNativeTokenTableFailureClassificationPolicy
    let didPrepareRendererNoNativeTokenTableOwnershipReadiness: Bool
    let shouldDeferRendererNoNativeTokenTableOwnershipReadiness: Bool
    let shouldReportRendererNoNativeTokenTableOwnershipReadinessBlocked:
        Bool
    let didPreserveRendererNativeTokenTableFailureClassificationPolicy:
        Bool
    let didConfirmBridgeLocalOpaqueTokenTablePolicy: Bool
    let didConfirmTableMutabilityConfinementPolicy: Bool
    let didConfirmNoSecondRendererTruthSource: Bool
    let didConfirmGenerationEpochInvalidationPolicy: Bool
    let didConfirmRevokeBeforeDestroyOrderingPolicy: Bool
    let didConfirmDoubleRevokeDanglingTokenFailureClassification: Bool
    let didConfirmMainThreadConfinementPolicy: Bool
    let didConfirmNoActualTokenTable: Bool
    let didConfirmNoNativeTokenCAbi: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoResourceCallable: Bool
    let didConfirmNoNativeObjectHandleOrPointer: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoNativeTokenTableOwnershipReadinessDehydrated: Bool
    let didAvoidTokenTableImplementationWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        failureClassificationPolicy:
            CjguiInternalRendererNativeTokenTableFailureClassificationPolicy,
        didPrepareRendererNoNativeTokenTableOwnershipReadiness: Bool,
        shouldDeferRendererNoNativeTokenTableOwnershipReadiness: Bool,
        shouldReportRendererNoNativeTokenTableOwnershipReadinessBlocked:
            Bool,
        didPreserveRendererNativeTokenTableFailureClassificationPolicy:
            Bool,
        didConfirmBridgeLocalOpaqueTokenTablePolicy: Bool,
        didConfirmTableMutabilityConfinementPolicy: Bool,
        didConfirmNoSecondRendererTruthSource: Bool,
        didConfirmGenerationEpochInvalidationPolicy: Bool,
        didConfirmRevokeBeforeDestroyOrderingPolicy: Bool,
        didConfirmDoubleRevokeDanglingTokenFailureClassification: Bool,
        didConfirmMainThreadConfinementPolicy: Bool,
        didConfirmNoActualTokenTable: Bool,
        didConfirmNoNativeTokenCAbi: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoResourceCallable: Bool,
        didConfirmNoNativeObjectHandleOrPointer: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoNativeTokenTableOwnershipReadinessDehydrated: Bool,
        didAvoidTokenTableImplementationWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.failureClassificationPolicy = failureClassificationPolicy
        this.didPrepareRendererNoNativeTokenTableOwnershipReadiness =
            didPrepareRendererNoNativeTokenTableOwnershipReadiness
        this.shouldDeferRendererNoNativeTokenTableOwnershipReadiness =
            shouldDeferRendererNoNativeTokenTableOwnershipReadiness
        this
            .shouldReportRendererNoNativeTokenTableOwnershipReadinessBlocked =
            shouldReportRendererNoNativeTokenTableOwnershipReadinessBlocked
        this
            .didPreserveRendererNativeTokenTableFailureClassificationPolicy =
            didPreserveRendererNativeTokenTableFailureClassificationPolicy
        this.didConfirmBridgeLocalOpaqueTokenTablePolicy =
            didConfirmBridgeLocalOpaqueTokenTablePolicy
        this.didConfirmTableMutabilityConfinementPolicy =
            didConfirmTableMutabilityConfinementPolicy
        this.didConfirmNoSecondRendererTruthSource =
            didConfirmNoSecondRendererTruthSource
        this.didConfirmGenerationEpochInvalidationPolicy =
            didConfirmGenerationEpochInvalidationPolicy
        this.didConfirmRevokeBeforeDestroyOrderingPolicy =
            didConfirmRevokeBeforeDestroyOrderingPolicy
        this.didConfirmDoubleRevokeDanglingTokenFailureClassification =
            didConfirmDoubleRevokeDanglingTokenFailureClassification
        this.didConfirmMainThreadConfinementPolicy =
            didConfirmMainThreadConfinementPolicy
        this.didConfirmNoActualTokenTable = didConfirmNoActualTokenTable
        this.didConfirmNoNativeTokenCAbi = didConfirmNoNativeTokenCAbi
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoResourceCallable = didConfirmNoResourceCallable
        this.didConfirmNoNativeObjectHandleOrPointer =
            didConfirmNoNativeObjectHandleOrPointer
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNoNativeTokenTableOwnershipReadinessDehydrated =
            didKeepNoNativeTokenTableOwnershipReadinessDehydrated
        this.didAvoidTokenTableImplementationWrapper =
            didAvoidTokenTableImplementationWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererNativeTokenTableOwnershipReadiness(
    tokenCallableReadiness:
        CjguiInternalRendererNoNativeBridgeTokenCallableReadiness
): CjguiInternalRendererNoNativeTokenTableOwnershipReadiness {
    let upstreamEvidenceReady =
        tokenCallableReadiness
            .didPrepareRendererNoNativeBridgeTokenCallableReadiness &&
        tokenCallableReadiness.didConfirmOpaqueTokenTypePolicy &&
        tokenCallableReadiness.didConfirmNoPointerTokenPolicy &&
        tokenCallableReadiness.didConfirmTokenTableMutabilityDenied &&
        tokenCallableReadiness.didConfirmIssueRevokeImplementationDeferred &&
        tokenCallableReadiness.didConfirmRevokeWithoutDestroyPolicy &&
        tokenCallableReadiness.didConfirmMainThreadGatePreserved &&
        tokenCallableReadiness.didConfirmNoPublicSurface &&
        tokenCallableReadiness.didConfirmNoResourceCallable &&
        tokenCallableReadiness.didConfirmNoNativeObjectHandleOrPointer &&
        tokenCallableReadiness.didConfirmNoMetalOrAppKitUsage &&
        tokenCallableReadiness.didConfirmNoRendererStateWrite &&
        tokenCallableReadiness.didConfirmNoBackendReadyTruth &&
        tokenCallableReadiness
            .shouldReportRendererNoNativeBridgeTokenCallableReadinessBlocked ==
            false
    let shouldDeferTableImplementation = true
    let intent = CjguiInternalRendererNativeTokenTableOwnershipIntent(
        tokenCallableReadiness,
        upstreamEvidenceReady,
        !upstreamEvidenceReady,
        !upstreamEvidenceReady,
        upstreamEvidenceReady,
        true,
        true,
        true,
        true,
        true,
        true
    )
    let opaquePolicy = CjguiInternalRendererBridgeLocalOpaqueTokenTablePolicy(
        intent,
        upstreamEvidenceReady,
        !upstreamEvidenceReady,
        !upstreamEvidenceReady,
        upstreamEvidenceReady,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
    let mutabilityPolicy =
        CjguiInternalRendererNativeTokenTableMutabilityConfinementPolicy(
            opaquePolicy,
            upstreamEvidenceReady,
            shouldDeferTableImplementation,
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
    let generationPolicy =
        CjguiInternalRendererNativeTokenGenerationInvalidationPolicy(
            mutabilityPolicy,
            upstreamEvidenceReady,
            shouldDeferTableImplementation,
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
    let orderingPolicy =
        CjguiInternalRendererNativeTokenRevokeDestroyOrderingPolicy(
            generationPolicy,
            upstreamEvidenceReady,
            shouldDeferTableImplementation,
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
    let failurePolicy =
        CjguiInternalRendererNativeTokenTableFailureClassificationPolicy(
            orderingPolicy,
            upstreamEvidenceReady,
            shouldDeferTableImplementation,
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
    return CjguiInternalRendererNoNativeTokenTableOwnershipReadiness(
        failurePolicy,
        upstreamEvidenceReady,
        shouldDeferTableImplementation,
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
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererNativeTokenTableOwnershipDraft():
    CjguiInternalRendererNoNativeTokenTableOwnershipReadiness {
    let tokenCallableReadiness =
        cjguiInternalExecuteDefaultRendererNativeBridgeTokenCallableDraft()
    return cjguiInternalBuildRendererNativeTokenTableOwnershipReadiness(
        tokenCallableReadiness
    )
}
