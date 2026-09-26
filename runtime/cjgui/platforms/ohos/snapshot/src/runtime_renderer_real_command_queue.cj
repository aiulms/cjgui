package cjgui

// This owner adds value-only facts for a future real queue lifecycle. It
// deliberately records policy and stop-line facts instead of materializing
// platform resources.
struct CjguiInternalRendererRealCommandQueueLifecycleIntent {
    let noBackendShellReadiness: CjguiInternalRendererNoBackendShellReadiness
    let didPrepareRendererRealCommandQueueLifecycleIntent: Bool
    let shouldDeferRendererRealCommandQueueLifecycleIntent: Bool
    let shouldReportRendererRealCommandQueueLifecycleIntentBlocked: Bool
    let didPreserveRendererNoBackendShellReadiness: Bool
    let didDefineFutureRealCommandQueueLifecycleIntent: Bool
    let didDescribeQueueCreationPolicyFacts: Bool
    let didDescribeQueueOwnershipGuardFacts: Bool
    let didDescribeQueueTeardownPolicyFacts: Bool
    let didKeepRealCommandQueueLifecycleIntentValueOnly: Bool
    let didAvoidRealQueueCreation: Bool
    let didAvoidForeignApiCall: Bool
    let didAvoidThinWrapper: Bool

    init(
        noBackendShellReadiness: CjguiInternalRendererNoBackendShellReadiness,
        didPrepareRendererRealCommandQueueLifecycleIntent: Bool,
        shouldDeferRendererRealCommandQueueLifecycleIntent: Bool,
        shouldReportRendererRealCommandQueueLifecycleIntentBlocked: Bool,
        didPreserveRendererNoBackendShellReadiness: Bool,
        didDefineFutureRealCommandQueueLifecycleIntent: Bool,
        didDescribeQueueCreationPolicyFacts: Bool,
        didDescribeQueueOwnershipGuardFacts: Bool,
        didDescribeQueueTeardownPolicyFacts: Bool,
        didKeepRealCommandQueueLifecycleIntentValueOnly: Bool,
        didAvoidRealQueueCreation: Bool,
        didAvoidForeignApiCall: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noBackendShellReadiness = noBackendShellReadiness
        this.didPrepareRendererRealCommandQueueLifecycleIntent =
            didPrepareRendererRealCommandQueueLifecycleIntent
        this.shouldDeferRendererRealCommandQueueLifecycleIntent =
            shouldDeferRendererRealCommandQueueLifecycleIntent
        this.shouldReportRendererRealCommandQueueLifecycleIntentBlocked =
            shouldReportRendererRealCommandQueueLifecycleIntentBlocked
        this.didPreserveRendererNoBackendShellReadiness =
            didPreserveRendererNoBackendShellReadiness
        this.didDefineFutureRealCommandQueueLifecycleIntent =
            didDefineFutureRealCommandQueueLifecycleIntent
        this.didDescribeQueueCreationPolicyFacts =
            didDescribeQueueCreationPolicyFacts
        this.didDescribeQueueOwnershipGuardFacts =
            didDescribeQueueOwnershipGuardFacts
        this.didDescribeQueueTeardownPolicyFacts =
            didDescribeQueueTeardownPolicyFacts
        this.didKeepRealCommandQueueLifecycleIntentValueOnly =
            didKeepRealCommandQueueLifecycleIntentValueOnly
        this.didAvoidRealQueueCreation = didAvoidRealQueueCreation
        this.didAvoidForeignApiCall = didAvoidForeignApiCall
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

// Creation policy facts describe future prerequisites and fallback handling.
// They do not allocate, call a platform API, or grant queue-ready permission.
struct CjguiInternalRendererRealCommandQueueCreationPolicy {
    let lifecycleIntent: CjguiInternalRendererRealCommandQueueLifecycleIntent
    let didPrepareRendererRealCommandQueueCreationPolicy: Bool
    let shouldDeferRendererRealCommandQueueCreationPolicy: Bool
    let shouldReportRendererRealCommandQueueCreationPolicyBlocked: Bool
    let didPreserveRendererRealCommandQueueLifecycleIntent: Bool
    let didDefineFutureQueueCreationPolicy: Bool
    let didDescribeCreationPrerequisiteFacts: Bool
    let didDescribeNoBackendResourceFallbackFacts: Bool
    let didDescribeNoQueueCreationFacts: Bool
    let didKeepQueueCreationPolicyValueOnly: Bool
    let didAvoidRealQueueCreation: Bool
    let didAvoidForeignApiCall: Bool
    let didAvoidQueueReadyPermission: Bool

    init(
        lifecycleIntent: CjguiInternalRendererRealCommandQueueLifecycleIntent,
        didPrepareRendererRealCommandQueueCreationPolicy: Bool,
        shouldDeferRendererRealCommandQueueCreationPolicy: Bool,
        shouldReportRendererRealCommandQueueCreationPolicyBlocked: Bool,
        didPreserveRendererRealCommandQueueLifecycleIntent: Bool,
        didDefineFutureQueueCreationPolicy: Bool,
        didDescribeCreationPrerequisiteFacts: Bool,
        didDescribeNoBackendResourceFallbackFacts: Bool,
        didDescribeNoQueueCreationFacts: Bool,
        didKeepQueueCreationPolicyValueOnly: Bool,
        didAvoidRealQueueCreation: Bool,
        didAvoidForeignApiCall: Bool,
        didAvoidQueueReadyPermission: Bool
    ) {
        this.lifecycleIntent = lifecycleIntent
        this.didPrepareRendererRealCommandQueueCreationPolicy =
            didPrepareRendererRealCommandQueueCreationPolicy
        this.shouldDeferRendererRealCommandQueueCreationPolicy =
            shouldDeferRendererRealCommandQueueCreationPolicy
        this.shouldReportRendererRealCommandQueueCreationPolicyBlocked =
            shouldReportRendererRealCommandQueueCreationPolicyBlocked
        this.didPreserveRendererRealCommandQueueLifecycleIntent =
            didPreserveRendererRealCommandQueueLifecycleIntent
        this.didDefineFutureQueueCreationPolicy =
            didDefineFutureQueueCreationPolicy
        this.didDescribeCreationPrerequisiteFacts =
            didDescribeCreationPrerequisiteFacts
        this.didDescribeNoBackendResourceFallbackFacts =
            didDescribeNoBackendResourceFallbackFacts
        this.didDescribeNoQueueCreationFacts = didDescribeNoQueueCreationFacts
        this.didKeepQueueCreationPolicyValueOnly =
            didKeepQueueCreationPolicyValueOnly
        this.didAvoidRealQueueCreation = didAvoidRealQueueCreation
        this.didAvoidForeignApiCall = didAvoidForeignApiCall
        this.didAvoidQueueReadyPermission = didAvoidQueueReadyPermission
    }
}

// Ownership guard facts keep a future queue local to the future backend owner.
// They do not leak resource tokens or pointer-like resources into core facts.
struct CjguiInternalRendererRealCommandQueueOwnershipGuard {
    let creationPolicy: CjguiInternalRendererRealCommandQueueCreationPolicy
    let didPrepareRendererRealCommandQueueOwnershipGuard: Bool
    let shouldDeferRendererRealCommandQueueOwnershipGuard: Bool
    let shouldReportRendererRealCommandQueueOwnershipGuardBlocked: Bool
    let didPreserveRendererRealCommandQueueCreationPolicy: Bool
    let didDefineFutureQueueOwnershipGuard: Bool
    let didDescribeBackendLocalConfinementFacts: Bool
    let didDescribeNoCoreResourceLeakFacts: Bool
    let didDescribeNoResourceBorrowFacts: Bool
    let didKeepQueueOwnershipGuardValueOnly: Bool
    let didAvoidForeignResourceToken: Bool
    let didAvoidPointerLikeResource: Bool
    let didAvoidBackendImplementationPermission: Bool

    init(
        creationPolicy: CjguiInternalRendererRealCommandQueueCreationPolicy,
        didPrepareRendererRealCommandQueueOwnershipGuard: Bool,
        shouldDeferRendererRealCommandQueueOwnershipGuard: Bool,
        shouldReportRendererRealCommandQueueOwnershipGuardBlocked: Bool,
        didPreserveRendererRealCommandQueueCreationPolicy: Bool,
        didDefineFutureQueueOwnershipGuard: Bool,
        didDescribeBackendLocalConfinementFacts: Bool,
        didDescribeNoCoreResourceLeakFacts: Bool,
        didDescribeNoResourceBorrowFacts: Bool,
        didKeepQueueOwnershipGuardValueOnly: Bool,
        didAvoidForeignResourceToken: Bool,
        didAvoidPointerLikeResource: Bool,
        didAvoidBackendImplementationPermission: Bool
    ) {
        this.creationPolicy = creationPolicy
        this.didPrepareRendererRealCommandQueueOwnershipGuard =
            didPrepareRendererRealCommandQueueOwnershipGuard
        this.shouldDeferRendererRealCommandQueueOwnershipGuard =
            shouldDeferRendererRealCommandQueueOwnershipGuard
        this.shouldReportRendererRealCommandQueueOwnershipGuardBlocked =
            shouldReportRendererRealCommandQueueOwnershipGuardBlocked
        this.didPreserveRendererRealCommandQueueCreationPolicy =
            didPreserveRendererRealCommandQueueCreationPolicy
        this.didDefineFutureQueueOwnershipGuard =
            didDefineFutureQueueOwnershipGuard
        this.didDescribeBackendLocalConfinementFacts =
            didDescribeBackendLocalConfinementFacts
        this.didDescribeNoCoreResourceLeakFacts =
            didDescribeNoCoreResourceLeakFacts
        this.didDescribeNoResourceBorrowFacts =
            didDescribeNoResourceBorrowFacts
        this.didKeepQueueOwnershipGuardValueOnly =
            didKeepQueueOwnershipGuardValueOnly
        this.didAvoidForeignResourceToken = didAvoidForeignResourceToken
        this.didAvoidPointerLikeResource = didAvoidPointerLikeResource
        this.didAvoidBackendImplementationPermission =
            didAvoidBackendImplementationPermission
    }
}

// Teardown policy facts describe future shutdown and rollback ordering only.
// No foreign teardown call or state mutation is performed here.
struct CjguiInternalRendererRealCommandQueueTeardownPolicy {
    let ownershipGuard: CjguiInternalRendererRealCommandQueueOwnershipGuard
    let didPrepareRendererRealCommandQueueTeardownPolicy: Bool
    let shouldDeferRendererRealCommandQueueTeardownPolicy: Bool
    let shouldReportRendererRealCommandQueueTeardownPolicyBlocked: Bool
    let didPreserveRendererRealCommandQueueOwnershipGuard: Bool
    let didDefineFutureQueueTeardownPolicy: Bool
    let didDescribeQueueShutdownOrderingFacts: Bool
    let didDescribeFailureRollbackFacts: Bool
    let didDescribeNoRealQueueCleanupFacts: Bool
    let didKeepQueueTeardownPolicyValueOnly: Bool
    let didAvoidForeignTeardownCall: Bool
    let didAvoidBridgeSmokeHarnessEntryChange: Bool
    let didAvoidStateMutation: Bool
    let didAvoidQueueReadyPermission: Bool

    init(
        ownershipGuard: CjguiInternalRendererRealCommandQueueOwnershipGuard,
        didPrepareRendererRealCommandQueueTeardownPolicy: Bool,
        shouldDeferRendererRealCommandQueueTeardownPolicy: Bool,
        shouldReportRendererRealCommandQueueTeardownPolicyBlocked: Bool,
        didPreserveRendererRealCommandQueueOwnershipGuard: Bool,
        didDefineFutureQueueTeardownPolicy: Bool,
        didDescribeQueueShutdownOrderingFacts: Bool,
        didDescribeFailureRollbackFacts: Bool,
        didDescribeNoRealQueueCleanupFacts: Bool,
        didKeepQueueTeardownPolicyValueOnly: Bool,
        didAvoidForeignTeardownCall: Bool,
        didAvoidBridgeSmokeHarnessEntryChange: Bool,
        didAvoidStateMutation: Bool,
        didAvoidQueueReadyPermission: Bool
    ) {
        this.ownershipGuard = ownershipGuard
        this.didPrepareRendererRealCommandQueueTeardownPolicy =
            didPrepareRendererRealCommandQueueTeardownPolicy
        this.shouldDeferRendererRealCommandQueueTeardownPolicy =
            shouldDeferRendererRealCommandQueueTeardownPolicy
        this.shouldReportRendererRealCommandQueueTeardownPolicyBlocked =
            shouldReportRendererRealCommandQueueTeardownPolicyBlocked
        this.didPreserveRendererRealCommandQueueOwnershipGuard =
            didPreserveRendererRealCommandQueueOwnershipGuard
        this.didDefineFutureQueueTeardownPolicy =
            didDefineFutureQueueTeardownPolicy
        this.didDescribeQueueShutdownOrderingFacts =
            didDescribeQueueShutdownOrderingFacts
        this.didDescribeFailureRollbackFacts =
            didDescribeFailureRollbackFacts
        this.didDescribeNoRealQueueCleanupFacts =
            didDescribeNoRealQueueCleanupFacts
        this.didKeepQueueTeardownPolicyValueOnly =
            didKeepQueueTeardownPolicyValueOnly
        this.didAvoidForeignTeardownCall = didAvoidForeignTeardownCall
        this.didAvoidBridgeSmokeHarnessEntryChange =
            didAvoidBridgeSmokeHarnessEntryChange
        this.didAvoidStateMutation = didAvoidStateMutation
        this.didAvoidQueueReadyPermission = didAvoidQueueReadyPermission
    }
}

// This endpoint seals no-real-command-queue value facts. It is not a
// queue-ready permission, backend implementation permission, or submit gate.
struct CjguiInternalRendererNoRealCommandQueueReadiness {
    let teardownPolicy: CjguiInternalRendererRealCommandQueueTeardownPolicy
    let isRendererNoRealCommandQueueReady: Bool
    let canFutureRendererRealCommandQueueBoundaryEvaluate: Bool
    let shouldDeferRendererNoRealCommandQueueReadiness: Bool
    let shouldReportRendererNoRealCommandQueueReadinessBlocked: Bool
    let didSealRendererNoRealCommandQueueReadiness: Bool
    let didPreserveRendererRealCommandQueueTeardownPolicy: Bool
    let didKeepNoRealCommandQueueReadinessValueOnly: Bool
    let didConfirmNoRealQueueCreated: Bool
    let didConfirmNoForeignApiCall: Bool
    let didConfirmNoBackendResourceCreated: Bool
    let didConfirmNoResourceBorrow: Bool
    let didConfirmNoForeignResourceToken: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didConfirmNoWorkSubmit: Bool
    let didConfirmNoRenderWork: Bool
    let didConfirmNoStateMutation: Bool
    let didConfirmNoBridgeSmokeHarnessEntryChange: Bool
    let didConfirmNoExternalSurface: Bool
    let didAvoidQueueReadyPermission: Bool
    let didAvoidBackendImplementationWrapper: Bool
    let didAvoidWorkSubmitWrapper: Bool
    let didAvoidBufferReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        teardownPolicy: CjguiInternalRendererRealCommandQueueTeardownPolicy,
        isRendererNoRealCommandQueueReady: Bool,
        canFutureRendererRealCommandQueueBoundaryEvaluate: Bool,
        shouldDeferRendererNoRealCommandQueueReadiness: Bool,
        shouldReportRendererNoRealCommandQueueReadinessBlocked: Bool,
        didSealRendererNoRealCommandQueueReadiness: Bool,
        didPreserveRendererRealCommandQueueTeardownPolicy: Bool,
        didKeepNoRealCommandQueueReadinessValueOnly: Bool,
        didConfirmNoRealQueueCreated: Bool,
        didConfirmNoForeignApiCall: Bool,
        didConfirmNoBackendResourceCreated: Bool,
        didConfirmNoResourceBorrow: Bool,
        didConfirmNoForeignResourceToken: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didConfirmNoWorkSubmit: Bool,
        didConfirmNoRenderWork: Bool,
        didConfirmNoStateMutation: Bool,
        didConfirmNoBridgeSmokeHarnessEntryChange: Bool,
        didConfirmNoExternalSurface: Bool,
        didAvoidQueueReadyPermission: Bool,
        didAvoidBackendImplementationWrapper: Bool,
        didAvoidWorkSubmitWrapper: Bool,
        didAvoidBufferReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.teardownPolicy = teardownPolicy
        this.isRendererNoRealCommandQueueReady =
            isRendererNoRealCommandQueueReady
        this.canFutureRendererRealCommandQueueBoundaryEvaluate =
            canFutureRendererRealCommandQueueBoundaryEvaluate
        this.shouldDeferRendererNoRealCommandQueueReadiness =
            shouldDeferRendererNoRealCommandQueueReadiness
        this.shouldReportRendererNoRealCommandQueueReadinessBlocked =
            shouldReportRendererNoRealCommandQueueReadinessBlocked
        this.didSealRendererNoRealCommandQueueReadiness =
            didSealRendererNoRealCommandQueueReadiness
        this.didPreserveRendererRealCommandQueueTeardownPolicy =
            didPreserveRendererRealCommandQueueTeardownPolicy
        this.didKeepNoRealCommandQueueReadinessValueOnly =
            didKeepNoRealCommandQueueReadinessValueOnly
        this.didConfirmNoRealQueueCreated = didConfirmNoRealQueueCreated
        this.didConfirmNoForeignApiCall = didConfirmNoForeignApiCall
        this.didConfirmNoBackendResourceCreated =
            didConfirmNoBackendResourceCreated
        this.didConfirmNoResourceBorrow = didConfirmNoResourceBorrow
        this.didConfirmNoForeignResourceToken =
            didConfirmNoForeignResourceToken
        this.didConfirmNoPointerLikeResource =
            didConfirmNoPointerLikeResource
        this.didConfirmNoWorkSubmit = didConfirmNoWorkSubmit
        this.didConfirmNoRenderWork = didConfirmNoRenderWork
        this.didConfirmNoStateMutation = didConfirmNoStateMutation
        this.didConfirmNoBridgeSmokeHarnessEntryChange =
            didConfirmNoBridgeSmokeHarnessEntryChange
        this.didConfirmNoExternalSurface = didConfirmNoExternalSurface
        this.didAvoidQueueReadyPermission = didAvoidQueueReadyPermission
        this.didAvoidBackendImplementationWrapper =
            didAvoidBackendImplementationWrapper
        this.didAvoidWorkSubmitWrapper = didAvoidWorkSubmitWrapper
        this.didAvoidBufferReadyWrapper = didAvoidBufferReadyWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererRealCommandQueueLifecycleIntent(
    noBackendShellReadiness: CjguiInternalRendererNoBackendShellReadiness
): CjguiInternalRendererRealCommandQueueLifecycleIntent {
    let noBackendShell =
        noBackendShellReadiness.isRendererNoBackendShellReady &&
        noBackendShellReadiness.canFutureRendererNoDrawBackendShellBoundaryEvaluate &&
        noBackendShellReadiness.didSealRendererNoBackendShellReadiness &&
        noBackendShellReadiness.didPreserveRendererShellTeardownPolicy &&
        noBackendShellReadiness.didKeepNoBackendShellReadinessValueOnly &&
        noBackendShellReadiness.didConfirmNoBackendShellObjectCreated &&
        noBackendShellReadiness.didConfirmNoBackendObjectCreated &&
        noBackendShellReadiness.didConfirmNoPlatformObjectCreated &&
        noBackendShellReadiness.didConfirmNoResourceToken &&
        noBackendShellReadiness.didConfirmNoPointerLikeResource &&
        noBackendShellReadiness.didConfirmNoDeviceOrLayer &&
        noBackendShellReadiness.didConfirmNoExternalApiSurface &&
        noBackendShellReadiness.didAvoidBackendShellReadyPermission &&
        noBackendShellReadiness.didAvoidBackendImplementationWrapper &&
        noBackendShellReadiness.didAvoidReceiptRecordPublication &&
        noBackendShellReadiness.didAvoidThinWrapper &&
        noBackendShellReadiness.didStayFullRebuildOnly &&
        noBackendShellReadiness.shouldDeferRendererNoBackendShellReadiness == false &&
        noBackendShellReadiness.shouldReportRendererNoBackendShellReadinessBlocked == false
    let intentDeferred =
        noBackendShellReadiness.isRendererNoBackendShellReady == false &&
        noBackendShellReadiness.canFutureRendererNoDrawBackendShellBoundaryEvaluate == false &&
        noBackendShellReadiness.shouldDeferRendererNoBackendShellReadiness &&
        noBackendShellReadiness.shouldReportRendererNoBackendShellReadinessBlocked == false
    let intentInconsistent = (
        noBackendShellReadiness.isRendererNoBackendShellReady &&
            (
                noBackendShellReadiness.canFutureRendererNoDrawBackendShellBoundaryEvaluate == false ||
                noBackendShellReadiness.didSealRendererNoBackendShellReadiness == false ||
                noBackendShellReadiness.didPreserveRendererShellTeardownPolicy == false ||
                noBackendShellReadiness.didKeepNoBackendShellReadinessValueOnly == false ||
                noBackendShellReadiness.didConfirmNoBackendShellObjectCreated == false ||
                noBackendShellReadiness.didConfirmNoBackendObjectCreated == false ||
                noBackendShellReadiness.didConfirmNoPlatformObjectCreated == false ||
                noBackendShellReadiness.didConfirmNoResourceToken == false ||
                noBackendShellReadiness.didConfirmNoPointerLikeResource == false ||
                noBackendShellReadiness.didConfirmNoDeviceOrLayer == false ||
                noBackendShellReadiness.didConfirmNoExternalApiSurface == false ||
                noBackendShellReadiness.didAvoidBackendShellReadyPermission == false ||
                noBackendShellReadiness.didAvoidBackendImplementationWrapper == false ||
                noBackendShellReadiness.didAvoidReceiptRecordPublication == false ||
                noBackendShellReadiness.didAvoidThinWrapper == false ||
                noBackendShellReadiness.didStayFullRebuildOnly == false ||
                noBackendShellReadiness.shouldDeferRendererNoBackendShellReadiness ||
                noBackendShellReadiness.shouldReportRendererNoBackendShellReadinessBlocked
            )
        ) ||
        (noBackendShellReadiness.canFutureRendererNoDrawBackendShellBoundaryEvaluate &&
            noBackendShellReadiness.isRendererNoBackendShellReady == false) ||
        (noBackendShellReadiness.shouldDeferRendererNoBackendShellReadiness &&
            noBackendShellReadiness.shouldReportRendererNoBackendShellReadinessBlocked)

    if (
        noBackendShellReadiness.shouldReportRendererNoBackendShellReadinessBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererRealCommandQueueLifecycleIntent(
            noBackendShellReadiness,
            false,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            true
        )
    }

    if (noBackendShell) {
        return CjguiInternalRendererRealCommandQueueLifecycleIntent(
            noBackendShellReadiness,
            true,
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
            true
        )
    }

    if (intentDeferred) {
        return CjguiInternalRendererRealCommandQueueLifecycleIntent(
            noBackendShellReadiness,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererRealCommandQueueLifecycleIntent(
        noBackendShellReadiness,
        false,
        false,
        true,
        false,
        false,
        false,
        false,
        false,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererRealCommandQueueCreationPolicy(
    lifecycleIntent: CjguiInternalRendererRealCommandQueueLifecycleIntent
): CjguiInternalRendererRealCommandQueueCreationPolicy {
    let intentReady =
        lifecycleIntent.didPrepareRendererRealCommandQueueLifecycleIntent &&
        lifecycleIntent.didPreserveRendererNoBackendShellReadiness &&
        lifecycleIntent.didDefineFutureRealCommandQueueLifecycleIntent &&
        lifecycleIntent.didDescribeQueueCreationPolicyFacts &&
        lifecycleIntent.didDescribeQueueOwnershipGuardFacts &&
        lifecycleIntent.didDescribeQueueTeardownPolicyFacts &&
        lifecycleIntent.didKeepRealCommandQueueLifecycleIntentValueOnly &&
        lifecycleIntent.didAvoidRealQueueCreation &&
        lifecycleIntent.didAvoidForeignApiCall &&
        lifecycleIntent.didAvoidThinWrapper &&
        lifecycleIntent.shouldDeferRendererRealCommandQueueLifecycleIntent == false &&
        lifecycleIntent.shouldReportRendererRealCommandQueueLifecycleIntentBlocked == false
    let creationDeferred =
        lifecycleIntent.didPrepareRendererRealCommandQueueLifecycleIntent == false &&
        lifecycleIntent.shouldDeferRendererRealCommandQueueLifecycleIntent &&
        lifecycleIntent.shouldReportRendererRealCommandQueueLifecycleIntentBlocked == false
    let creationInconsistent = (
        lifecycleIntent.didPrepareRendererRealCommandQueueLifecycleIntent &&
            (
                lifecycleIntent.didPreserveRendererNoBackendShellReadiness == false ||
                lifecycleIntent.didDefineFutureRealCommandQueueLifecycleIntent == false ||
                lifecycleIntent.didDescribeQueueCreationPolicyFacts == false ||
                lifecycleIntent.didDescribeQueueOwnershipGuardFacts == false ||
                lifecycleIntent.didDescribeQueueTeardownPolicyFacts == false ||
                lifecycleIntent.didKeepRealCommandQueueLifecycleIntentValueOnly == false ||
                lifecycleIntent.didAvoidRealQueueCreation == false ||
                lifecycleIntent.didAvoidForeignApiCall == false ||
                lifecycleIntent.didAvoidThinWrapper == false ||
                lifecycleIntent.shouldDeferRendererRealCommandQueueLifecycleIntent ||
                lifecycleIntent.shouldReportRendererRealCommandQueueLifecycleIntentBlocked
            )
        ) ||
        (lifecycleIntent.didPreserveRendererNoBackendShellReadiness &&
            lifecycleIntent.didPrepareRendererRealCommandQueueLifecycleIntent == false) ||
        (lifecycleIntent.shouldDeferRendererRealCommandQueueLifecycleIntent &&
            lifecycleIntent.shouldReportRendererRealCommandQueueLifecycleIntentBlocked)

    if (
        lifecycleIntent.shouldReportRendererRealCommandQueueLifecycleIntentBlocked ||
        creationInconsistent
    ) {
        return CjguiInternalRendererRealCommandQueueCreationPolicy(
            lifecycleIntent,
            false,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            true
        )
    }

    if (intentReady) {
        return CjguiInternalRendererRealCommandQueueCreationPolicy(
            lifecycleIntent,
            true,
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
            true
        )
    }

    if (creationDeferred) {
        return CjguiInternalRendererRealCommandQueueCreationPolicy(
            lifecycleIntent,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererRealCommandQueueCreationPolicy(
        lifecycleIntent,
        false,
        false,
        true,
        false,
        false,
        false,
        false,
        false,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererRealCommandQueueOwnershipGuard(
    creationPolicy: CjguiInternalRendererRealCommandQueueCreationPolicy
): CjguiInternalRendererRealCommandQueueOwnershipGuard {
    let creationReady =
        creationPolicy.didPrepareRendererRealCommandQueueCreationPolicy &&
        creationPolicy.didPreserveRendererRealCommandQueueLifecycleIntent &&
        creationPolicy.didDefineFutureQueueCreationPolicy &&
        creationPolicy.didDescribeCreationPrerequisiteFacts &&
        creationPolicy.didDescribeNoBackendResourceFallbackFacts &&
        creationPolicy.didDescribeNoQueueCreationFacts &&
        creationPolicy.didKeepQueueCreationPolicyValueOnly &&
        creationPolicy.didAvoidRealQueueCreation &&
        creationPolicy.didAvoidForeignApiCall &&
        creationPolicy.didAvoidQueueReadyPermission &&
        creationPolicy.shouldDeferRendererRealCommandQueueCreationPolicy == false &&
        creationPolicy.shouldReportRendererRealCommandQueueCreationPolicyBlocked == false
    let ownershipDeferred =
        creationPolicy.didPrepareRendererRealCommandQueueCreationPolicy == false &&
        creationPolicy.shouldDeferRendererRealCommandQueueCreationPolicy &&
        creationPolicy.shouldReportRendererRealCommandQueueCreationPolicyBlocked == false
    let ownershipInconsistent = (
        creationPolicy.didPrepareRendererRealCommandQueueCreationPolicy &&
            (
                creationPolicy.didPreserveRendererRealCommandQueueLifecycleIntent == false ||
                creationPolicy.didDefineFutureQueueCreationPolicy == false ||
                creationPolicy.didDescribeCreationPrerequisiteFacts == false ||
                creationPolicy.didDescribeNoBackendResourceFallbackFacts == false ||
                creationPolicy.didDescribeNoQueueCreationFacts == false ||
                creationPolicy.didKeepQueueCreationPolicyValueOnly == false ||
                creationPolicy.didAvoidRealQueueCreation == false ||
                creationPolicy.didAvoidForeignApiCall == false ||
                creationPolicy.didAvoidQueueReadyPermission == false ||
                creationPolicy.shouldDeferRendererRealCommandQueueCreationPolicy ||
                creationPolicy.shouldReportRendererRealCommandQueueCreationPolicyBlocked
            )
        ) ||
        (creationPolicy.didPreserveRendererRealCommandQueueLifecycleIntent &&
            creationPolicy.didPrepareRendererRealCommandQueueCreationPolicy == false) ||
        (creationPolicy.shouldDeferRendererRealCommandQueueCreationPolicy &&
            creationPolicy.shouldReportRendererRealCommandQueueCreationPolicyBlocked)

    if (
        creationPolicy.shouldReportRendererRealCommandQueueCreationPolicyBlocked ||
        ownershipInconsistent
    ) {
        return CjguiInternalRendererRealCommandQueueOwnershipGuard(
            creationPolicy,
            false,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            true
        )
    }

    if (creationReady) {
        return CjguiInternalRendererRealCommandQueueOwnershipGuard(
            creationPolicy,
            true,
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
            true
        )
    }

    if (ownershipDeferred) {
        return CjguiInternalRendererRealCommandQueueOwnershipGuard(
            creationPolicy,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererRealCommandQueueOwnershipGuard(
        creationPolicy,
        false,
        false,
        true,
        false,
        false,
        false,
        false,
        false,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererRealCommandQueueTeardownPolicy(
    ownershipGuard: CjguiInternalRendererRealCommandQueueOwnershipGuard
): CjguiInternalRendererRealCommandQueueTeardownPolicy {
    let ownershipReady =
        ownershipGuard.didPrepareRendererRealCommandQueueOwnershipGuard &&
        ownershipGuard.didPreserveRendererRealCommandQueueCreationPolicy &&
        ownershipGuard.didDefineFutureQueueOwnershipGuard &&
        ownershipGuard.didDescribeBackendLocalConfinementFacts &&
        ownershipGuard.didDescribeNoCoreResourceLeakFacts &&
        ownershipGuard.didDescribeNoResourceBorrowFacts &&
        ownershipGuard.didKeepQueueOwnershipGuardValueOnly &&
        ownershipGuard.didAvoidForeignResourceToken &&
        ownershipGuard.didAvoidPointerLikeResource &&
        ownershipGuard.didAvoidBackendImplementationPermission &&
        ownershipGuard.shouldDeferRendererRealCommandQueueOwnershipGuard == false &&
        ownershipGuard.shouldReportRendererRealCommandQueueOwnershipGuardBlocked == false
    let teardownDeferred =
        ownershipGuard.didPrepareRendererRealCommandQueueOwnershipGuard == false &&
        ownershipGuard.shouldDeferRendererRealCommandQueueOwnershipGuard &&
        ownershipGuard.shouldReportRendererRealCommandQueueOwnershipGuardBlocked == false
    let teardownInconsistent = (
        ownershipGuard.didPrepareRendererRealCommandQueueOwnershipGuard &&
            (
                ownershipGuard.didPreserveRendererRealCommandQueueCreationPolicy == false ||
                ownershipGuard.didDefineFutureQueueOwnershipGuard == false ||
                ownershipGuard.didDescribeBackendLocalConfinementFacts == false ||
                ownershipGuard.didDescribeNoCoreResourceLeakFacts == false ||
                ownershipGuard.didDescribeNoResourceBorrowFacts == false ||
                ownershipGuard.didKeepQueueOwnershipGuardValueOnly == false ||
                ownershipGuard.didAvoidForeignResourceToken == false ||
                ownershipGuard.didAvoidPointerLikeResource == false ||
                ownershipGuard.didAvoidBackendImplementationPermission == false ||
                ownershipGuard.shouldDeferRendererRealCommandQueueOwnershipGuard ||
                ownershipGuard.shouldReportRendererRealCommandQueueOwnershipGuardBlocked
            )
        ) ||
        (ownershipGuard.didPreserveRendererRealCommandQueueCreationPolicy &&
            ownershipGuard.didPrepareRendererRealCommandQueueOwnershipGuard == false) ||
        (ownershipGuard.shouldDeferRendererRealCommandQueueOwnershipGuard &&
            ownershipGuard.shouldReportRendererRealCommandQueueOwnershipGuardBlocked)

    if (
        ownershipGuard.shouldReportRendererRealCommandQueueOwnershipGuardBlocked ||
        teardownInconsistent
    ) {
        return CjguiInternalRendererRealCommandQueueTeardownPolicy(
            ownershipGuard,
            false,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (ownershipReady) {
        return CjguiInternalRendererRealCommandQueueTeardownPolicy(
            ownershipGuard,
            true,
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

    if (teardownDeferred) {
        return CjguiInternalRendererRealCommandQueueTeardownPolicy(
            ownershipGuard,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererRealCommandQueueTeardownPolicy(
        ownershipGuard,
        false,
        false,
        true,
        false,
        false,
        false,
        false,
        false,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererNoRealCommandQueueReadiness(
    teardownPolicy: CjguiInternalRendererRealCommandQueueTeardownPolicy
): CjguiInternalRendererNoRealCommandQueueReadiness {
    let teardownReady =
        teardownPolicy.didPrepareRendererRealCommandQueueTeardownPolicy &&
        teardownPolicy.didPreserveRendererRealCommandQueueOwnershipGuard &&
        teardownPolicy.didDefineFutureQueueTeardownPolicy &&
        teardownPolicy.didDescribeQueueShutdownOrderingFacts &&
        teardownPolicy.didDescribeFailureRollbackFacts &&
        teardownPolicy.didDescribeNoRealQueueCleanupFacts &&
        teardownPolicy.didKeepQueueTeardownPolicyValueOnly &&
        teardownPolicy.didAvoidForeignTeardownCall &&
        teardownPolicy.didAvoidBridgeSmokeHarnessEntryChange &&
        teardownPolicy.didAvoidStateMutation &&
        teardownPolicy.didAvoidQueueReadyPermission &&
        teardownPolicy.shouldDeferRendererRealCommandQueueTeardownPolicy == false &&
        teardownPolicy.shouldReportRendererRealCommandQueueTeardownPolicyBlocked == false
    let readinessDeferred =
        teardownPolicy.didPrepareRendererRealCommandQueueTeardownPolicy == false &&
        teardownPolicy.shouldDeferRendererRealCommandQueueTeardownPolicy &&
        teardownPolicy.shouldReportRendererRealCommandQueueTeardownPolicyBlocked == false
    let readinessInconsistent = (
        teardownPolicy.didPrepareRendererRealCommandQueueTeardownPolicy &&
            (
                teardownPolicy.didPreserveRendererRealCommandQueueOwnershipGuard == false ||
                teardownPolicy.didDefineFutureQueueTeardownPolicy == false ||
                teardownPolicy.didDescribeQueueShutdownOrderingFacts == false ||
                teardownPolicy.didDescribeFailureRollbackFacts == false ||
                teardownPolicy.didDescribeNoRealQueueCleanupFacts == false ||
                teardownPolicy.didKeepQueueTeardownPolicyValueOnly == false ||
                teardownPolicy.didAvoidForeignTeardownCall == false ||
                teardownPolicy.didAvoidBridgeSmokeHarnessEntryChange == false ||
                teardownPolicy.didAvoidStateMutation == false ||
                teardownPolicy.didAvoidQueueReadyPermission == false ||
                teardownPolicy.shouldDeferRendererRealCommandQueueTeardownPolicy ||
                teardownPolicy.shouldReportRendererRealCommandQueueTeardownPolicyBlocked
            )
        ) ||
        (teardownPolicy.didPreserveRendererRealCommandQueueOwnershipGuard &&
            teardownPolicy.didPrepareRendererRealCommandQueueTeardownPolicy == false) ||
        (teardownPolicy.shouldDeferRendererRealCommandQueueTeardownPolicy &&
            teardownPolicy.shouldReportRendererRealCommandQueueTeardownPolicyBlocked)

    if (
        teardownPolicy.shouldReportRendererRealCommandQueueTeardownPolicyBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoRealCommandQueueReadiness(
            teardownPolicy,
            false,
            false,
            false,
            true,
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

    if (teardownReady) {
        return CjguiInternalRendererNoRealCommandQueueReadiness(
            teardownPolicy,
            true,
            true,
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

    if (readinessDeferred) {
        return CjguiInternalRendererNoRealCommandQueueReadiness(
            teardownPolicy,
            false,
            false,
            true,
            false,
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

    return CjguiInternalRendererNoRealCommandQueueReadiness(
        teardownPolicy,
        false,
        false,
        false,
        true,
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

func cjguiInternalExecuteDefaultRendererRealCommandQueueLifecycleDraft(
): CjguiInternalRendererNoRealCommandQueueReadiness {
    let noBackendShellReadiness =
        cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()
    let lifecycleIntent =
        cjguiInternalBuildRendererRealCommandQueueLifecycleIntent(
            noBackendShellReadiness
        )
    let creationPolicy =
        cjguiInternalBuildRendererRealCommandQueueCreationPolicy(
            lifecycleIntent
        )
    let ownershipGuard =
        cjguiInternalBuildRendererRealCommandQueueOwnershipGuard(
            creationPolicy
        )
    let teardownPolicy =
        cjguiInternalBuildRendererRealCommandQueueTeardownPolicy(
            ownershipGuard
        )
    return cjguiInternalBuildRendererNoRealCommandQueueReadiness(
        teardownPolicy
    )
}
