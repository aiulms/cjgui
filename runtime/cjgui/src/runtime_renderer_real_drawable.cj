package cjgui

// This owner records value-only facts for a future real drawable lifecycle.
// It describes availability, lookup guard, and presentation ownership without
// touching platform resources or submitting work.
struct CjguiInternalRendererRealDrawableLifecycleIntent {
    let noRealCommandQueueReadiness: CjguiInternalRendererNoRealCommandQueueReadiness
    let didPrepareRendererRealDrawableLifecycleIntent: Bool
    let shouldDeferRendererRealDrawableLifecycleIntent: Bool
    let shouldReportRendererRealDrawableLifecycleIntentBlocked: Bool
    let didPreserveRendererNoRealCommandQueueReadiness: Bool
    let didDefineFutureRealDrawableLifecycleIntent: Bool
    let didDescribeDrawableAvailabilityFacts: Bool
    let didDescribeDrawableAcquisitionGuardFacts: Bool
    let didDescribePresentationOwnershipFacts: Bool
    let didKeepRealDrawableLifecycleIntentValueOnly: Bool
    let didAvoidDrawableLookup: Bool
    let didAvoidForeignApiCall: Bool
    let didAvoidThinWrapper: Bool

    init(
        noRealCommandQueueReadiness: CjguiInternalRendererNoRealCommandQueueReadiness,
        didPrepareRendererRealDrawableLifecycleIntent: Bool,
        shouldDeferRendererRealDrawableLifecycleIntent: Bool,
        shouldReportRendererRealDrawableLifecycleIntentBlocked: Bool,
        didPreserveRendererNoRealCommandQueueReadiness: Bool,
        didDefineFutureRealDrawableLifecycleIntent: Bool,
        didDescribeDrawableAvailabilityFacts: Bool,
        didDescribeDrawableAcquisitionGuardFacts: Bool,
        didDescribePresentationOwnershipFacts: Bool,
        didKeepRealDrawableLifecycleIntentValueOnly: Bool,
        didAvoidDrawableLookup: Bool,
        didAvoidForeignApiCall: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noRealCommandQueueReadiness = noRealCommandQueueReadiness
        this.didPrepareRendererRealDrawableLifecycleIntent =
            didPrepareRendererRealDrawableLifecycleIntent
        this.shouldDeferRendererRealDrawableLifecycleIntent =
            shouldDeferRendererRealDrawableLifecycleIntent
        this.shouldReportRendererRealDrawableLifecycleIntentBlocked =
            shouldReportRendererRealDrawableLifecycleIntentBlocked
        this.didPreserveRendererNoRealCommandQueueReadiness =
            didPreserveRendererNoRealCommandQueueReadiness
        this.didDefineFutureRealDrawableLifecycleIntent =
            didDefineFutureRealDrawableLifecycleIntent
        this.didDescribeDrawableAvailabilityFacts =
            didDescribeDrawableAvailabilityFacts
        this.didDescribeDrawableAcquisitionGuardFacts =
            didDescribeDrawableAcquisitionGuardFacts
        this.didDescribePresentationOwnershipFacts =
            didDescribePresentationOwnershipFacts
        this.didKeepRealDrawableLifecycleIntentValueOnly =
            didKeepRealDrawableLifecycleIntentValueOnly
        this.didAvoidDrawableLookup = didAvoidDrawableLookup
        this.didAvoidForeignApiCall = didAvoidForeignApiCall
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

// Availability facts describe future available, unavailable, and fallback
// states. They do not borrow a drawable or grant drawable-ready permission.
struct CjguiInternalRendererRealDrawableAvailabilityPolicy {
    let lifecycleIntent: CjguiInternalRendererRealDrawableLifecycleIntent
    let didPrepareRendererRealDrawableAvailabilityPolicy: Bool
    let shouldDeferRendererRealDrawableAvailabilityPolicy: Bool
    let shouldReportRendererRealDrawableAvailabilityPolicyBlocked: Bool
    let didPreserveRendererRealDrawableLifecycleIntent: Bool
    let didDefineFutureDrawableAvailabilityPolicy: Bool
    let didDescribeDrawableUnavailableFailureFacts: Bool
    let didDescribeNoDrawFallbackFacts: Bool
    let didDescribeResizeScaleColorRelationFacts: Bool
    let didKeepDrawableAvailabilityPolicyValueOnly: Bool
    let didAvoidDrawableLookup: Bool
    let didAvoidDrawableOwnership: Bool
    let didAvoidDrawableReadyPermission: Bool

    init(
        lifecycleIntent: CjguiInternalRendererRealDrawableLifecycleIntent,
        didPrepareRendererRealDrawableAvailabilityPolicy: Bool,
        shouldDeferRendererRealDrawableAvailabilityPolicy: Bool,
        shouldReportRendererRealDrawableAvailabilityPolicyBlocked: Bool,
        didPreserveRendererRealDrawableLifecycleIntent: Bool,
        didDefineFutureDrawableAvailabilityPolicy: Bool,
        didDescribeDrawableUnavailableFailureFacts: Bool,
        didDescribeNoDrawFallbackFacts: Bool,
        didDescribeResizeScaleColorRelationFacts: Bool,
        didKeepDrawableAvailabilityPolicyValueOnly: Bool,
        didAvoidDrawableLookup: Bool,
        didAvoidDrawableOwnership: Bool,
        didAvoidDrawableReadyPermission: Bool
    ) {
        this.lifecycleIntent = lifecycleIntent
        this.didPrepareRendererRealDrawableAvailabilityPolicy =
            didPrepareRendererRealDrawableAvailabilityPolicy
        this.shouldDeferRendererRealDrawableAvailabilityPolicy =
            shouldDeferRendererRealDrawableAvailabilityPolicy
        this.shouldReportRendererRealDrawableAvailabilityPolicyBlocked =
            shouldReportRendererRealDrawableAvailabilityPolicyBlocked
        this.didPreserveRendererRealDrawableLifecycleIntent =
            didPreserveRendererRealDrawableLifecycleIntent
        this.didDefineFutureDrawableAvailabilityPolicy =
            didDefineFutureDrawableAvailabilityPolicy
        this.didDescribeDrawableUnavailableFailureFacts =
            didDescribeDrawableUnavailableFailureFacts
        this.didDescribeNoDrawFallbackFacts = didDescribeNoDrawFallbackFacts
        this.didDescribeResizeScaleColorRelationFacts =
            didDescribeResizeScaleColorRelationFacts
        this.didKeepDrawableAvailabilityPolicyValueOnly =
            didKeepDrawableAvailabilityPolicyValueOnly
        this.didAvoidDrawableLookup = didAvoidDrawableLookup
        this.didAvoidDrawableOwnership = didAvoidDrawableOwnership
        this.didAvoidDrawableReadyPermission = didAvoidDrawableReadyPermission
    }
}

// The guard captures late-bound lookup constraints and unavailable fallback
// facts. It does not perform a lookup or block on a foreign call.
struct CjguiInternalRendererRealDrawableAcquisitionGuard {
    let availabilityPolicy: CjguiInternalRendererRealDrawableAvailabilityPolicy
    let didPrepareRendererRealDrawableAcquisitionGuard: Bool
    let shouldDeferRendererRealDrawableAcquisitionGuard: Bool
    let shouldReportRendererRealDrawableAcquisitionGuardBlocked: Bool
    let didPreserveRendererRealDrawableAvailabilityPolicy: Bool
    let didDefineFutureDrawableAcquisitionGuard: Bool
    let didDescribeLateBoundDrawableFacts: Bool
    let didDescribeUnavailableTimeoutFallbackFacts: Bool
    let didDescribeNoBorrowedResourceFacts: Bool
    let didKeepDrawableAcquisitionGuardValueOnly: Bool
    let didAvoidDrawableLookup: Bool
    let didAvoidBlockingForeignCall: Bool
    let didAvoidResourceToken: Bool

    init(
        availabilityPolicy: CjguiInternalRendererRealDrawableAvailabilityPolicy,
        didPrepareRendererRealDrawableAcquisitionGuard: Bool,
        shouldDeferRendererRealDrawableAcquisitionGuard: Bool,
        shouldReportRendererRealDrawableAcquisitionGuardBlocked: Bool,
        didPreserveRendererRealDrawableAvailabilityPolicy: Bool,
        didDefineFutureDrawableAcquisitionGuard: Bool,
        didDescribeLateBoundDrawableFacts: Bool,
        didDescribeUnavailableTimeoutFallbackFacts: Bool,
        didDescribeNoBorrowedResourceFacts: Bool,
        didKeepDrawableAcquisitionGuardValueOnly: Bool,
        didAvoidDrawableLookup: Bool,
        didAvoidBlockingForeignCall: Bool,
        didAvoidResourceToken: Bool
    ) {
        this.availabilityPolicy = availabilityPolicy
        this.didPrepareRendererRealDrawableAcquisitionGuard =
            didPrepareRendererRealDrawableAcquisitionGuard
        this.shouldDeferRendererRealDrawableAcquisitionGuard =
            shouldDeferRendererRealDrawableAcquisitionGuard
        this.shouldReportRendererRealDrawableAcquisitionGuardBlocked =
            shouldReportRendererRealDrawableAcquisitionGuardBlocked
        this.didPreserveRendererRealDrawableAvailabilityPolicy =
            didPreserveRendererRealDrawableAvailabilityPolicy
        this.didDefineFutureDrawableAcquisitionGuard =
            didDefineFutureDrawableAcquisitionGuard
        this.didDescribeLateBoundDrawableFacts =
            didDescribeLateBoundDrawableFacts
        this.didDescribeUnavailableTimeoutFallbackFacts =
            didDescribeUnavailableTimeoutFallbackFacts
        this.didDescribeNoBorrowedResourceFacts =
            didDescribeNoBorrowedResourceFacts
        this.didKeepDrawableAcquisitionGuardValueOnly =
            didKeepDrawableAcquisitionGuardValueOnly
        this.didAvoidDrawableLookup = didAvoidDrawableLookup
        this.didAvoidBlockingForeignCall = didAvoidBlockingForeignCall
        this.didAvoidResourceToken = didAvoidResourceToken
    }
}

// Presentation ownership facts describe future ownership and release
// expectations. They do not present, create pass objects, or submit work.
struct CjguiInternalRendererRealDrawablePresentationOwnershipPolicy {
    let acquisitionGuard: CjguiInternalRendererRealDrawableAcquisitionGuard
    let didPrepareRendererRealDrawablePresentationOwnershipPolicy: Bool
    let shouldDeferRendererRealDrawablePresentationOwnershipPolicy: Bool
    let shouldReportRendererRealDrawablePresentationOwnershipPolicyBlocked: Bool
    let didPreserveRendererRealDrawableAcquisitionGuard: Bool
    let didDefineFutureDrawablePresentationOwnershipPolicy: Bool
    let didDescribePresentationOwnerFacts: Bool
    let didDescribeDrawableReleaseExpectationFacts: Bool
    let didDescribeNoPresentFacts: Bool
    let didKeepDrawablePresentationOwnershipPolicyValueOnly: Bool
    let didAvoidPresentingDrawable: Bool
    let didAvoidSubmitWork: Bool
    let didAvoidPassOrEncoderObject: Bool
    let didAvoidStateMutation: Bool

    init(
        acquisitionGuard: CjguiInternalRendererRealDrawableAcquisitionGuard,
        didPrepareRendererRealDrawablePresentationOwnershipPolicy: Bool,
        shouldDeferRendererRealDrawablePresentationOwnershipPolicy: Bool,
        shouldReportRendererRealDrawablePresentationOwnershipPolicyBlocked: Bool,
        didPreserveRendererRealDrawableAcquisitionGuard: Bool,
        didDefineFutureDrawablePresentationOwnershipPolicy: Bool,
        didDescribePresentationOwnerFacts: Bool,
        didDescribeDrawableReleaseExpectationFacts: Bool,
        didDescribeNoPresentFacts: Bool,
        didKeepDrawablePresentationOwnershipPolicyValueOnly: Bool,
        didAvoidPresentingDrawable: Bool,
        didAvoidSubmitWork: Bool,
        didAvoidPassOrEncoderObject: Bool,
        didAvoidStateMutation: Bool
    ) {
        this.acquisitionGuard = acquisitionGuard
        this.didPrepareRendererRealDrawablePresentationOwnershipPolicy =
            didPrepareRendererRealDrawablePresentationOwnershipPolicy
        this.shouldDeferRendererRealDrawablePresentationOwnershipPolicy =
            shouldDeferRendererRealDrawablePresentationOwnershipPolicy
        this.shouldReportRendererRealDrawablePresentationOwnershipPolicyBlocked =
            shouldReportRendererRealDrawablePresentationOwnershipPolicyBlocked
        this.didPreserveRendererRealDrawableAcquisitionGuard =
            didPreserveRendererRealDrawableAcquisitionGuard
        this.didDefineFutureDrawablePresentationOwnershipPolicy =
            didDefineFutureDrawablePresentationOwnershipPolicy
        this.didDescribePresentationOwnerFacts =
            didDescribePresentationOwnerFacts
        this.didDescribeDrawableReleaseExpectationFacts =
            didDescribeDrawableReleaseExpectationFacts
        this.didDescribeNoPresentFacts = didDescribeNoPresentFacts
        this.didKeepDrawablePresentationOwnershipPolicyValueOnly =
            didKeepDrawablePresentationOwnershipPolicyValueOnly
        this.didAvoidPresentingDrawable = didAvoidPresentingDrawable
        this.didAvoidSubmitWork = didAvoidSubmitWork
        this.didAvoidPassOrEncoderObject = didAvoidPassOrEncoderObject
        this.didAvoidStateMutation = didAvoidStateMutation
    }
}

// This endpoint seals no-real-drawable value facts. It is not a drawable-ready
// permission, backend implementation permission, or work submission gate.
struct CjguiInternalRendererNoRealDrawableReadiness {
    let presentationOwnershipPolicy:
        CjguiInternalRendererRealDrawablePresentationOwnershipPolicy
    let isRendererNoRealDrawableReady: Bool
    let canFutureRendererRealDrawableBoundaryEvaluate: Bool
    let shouldDeferRendererNoRealDrawableReadiness: Bool
    let shouldReportRendererNoRealDrawableReadinessBlocked: Bool
    let didSealRendererNoRealDrawableReadiness: Bool
    let didPreserveRendererRealDrawablePresentationOwnershipPolicy: Bool
    let didKeepNoRealDrawableReadinessValueOnly: Bool
    let didConfirmNoDrawableAcquired: Bool
    let didConfirmNoDrawableObjectHeld: Bool
    let didConfirmNoDrawableTextureExposed: Bool
    let didConfirmNoSubmissionObjectCreated: Bool
    let didConfirmNoPassOrEncoderObject: Bool
    let didConfirmNoForeignApiCall: Bool
    let didConfirmNoResourceToken: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didConfirmNoWorkSubmit: Bool
    let didConfirmNoRenderWork: Bool
    let didConfirmNoStateMutation: Bool
    let didConfirmNoBridgeSmokeHarnessEntryChange: Bool
    let didAvoidDrawableReadyPermission: Bool
    let didAvoidBackendImplementationWrapper: Bool
    let didAvoidWorkSubmitWrapper: Bool
    let didAvoidBufferReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        presentationOwnershipPolicy:
            CjguiInternalRendererRealDrawablePresentationOwnershipPolicy,
        isRendererNoRealDrawableReady: Bool,
        canFutureRendererRealDrawableBoundaryEvaluate: Bool,
        shouldDeferRendererNoRealDrawableReadiness: Bool,
        shouldReportRendererNoRealDrawableReadinessBlocked: Bool,
        didSealRendererNoRealDrawableReadiness: Bool,
        didPreserveRendererRealDrawablePresentationOwnershipPolicy: Bool,
        didKeepNoRealDrawableReadinessValueOnly: Bool,
        didConfirmNoDrawableAcquired: Bool,
        didConfirmNoDrawableObjectHeld: Bool,
        didConfirmNoDrawableTextureExposed: Bool,
        didConfirmNoSubmissionObjectCreated: Bool,
        didConfirmNoPassOrEncoderObject: Bool,
        didConfirmNoForeignApiCall: Bool,
        didConfirmNoResourceToken: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didConfirmNoWorkSubmit: Bool,
        didConfirmNoRenderWork: Bool,
        didConfirmNoStateMutation: Bool,
        didConfirmNoBridgeSmokeHarnessEntryChange: Bool,
        didAvoidDrawableReadyPermission: Bool,
        didAvoidBackendImplementationWrapper: Bool,
        didAvoidWorkSubmitWrapper: Bool,
        didAvoidBufferReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.presentationOwnershipPolicy = presentationOwnershipPolicy
        this.isRendererNoRealDrawableReady = isRendererNoRealDrawableReady
        this.canFutureRendererRealDrawableBoundaryEvaluate =
            canFutureRendererRealDrawableBoundaryEvaluate
        this.shouldDeferRendererNoRealDrawableReadiness =
            shouldDeferRendererNoRealDrawableReadiness
        this.shouldReportRendererNoRealDrawableReadinessBlocked =
            shouldReportRendererNoRealDrawableReadinessBlocked
        this.didSealRendererNoRealDrawableReadiness =
            didSealRendererNoRealDrawableReadiness
        this.didPreserveRendererRealDrawablePresentationOwnershipPolicy =
            didPreserveRendererRealDrawablePresentationOwnershipPolicy
        this.didKeepNoRealDrawableReadinessValueOnly =
            didKeepNoRealDrawableReadinessValueOnly
        this.didConfirmNoDrawableAcquired = didConfirmNoDrawableAcquired
        this.didConfirmNoDrawableObjectHeld = didConfirmNoDrawableObjectHeld
        this.didConfirmNoDrawableTextureExposed =
            didConfirmNoDrawableTextureExposed
        this.didConfirmNoSubmissionObjectCreated =
            didConfirmNoSubmissionObjectCreated
        this.didConfirmNoPassOrEncoderObject =
            didConfirmNoPassOrEncoderObject
        this.didConfirmNoForeignApiCall = didConfirmNoForeignApiCall
        this.didConfirmNoResourceToken = didConfirmNoResourceToken
        this.didConfirmNoPointerLikeResource =
            didConfirmNoPointerLikeResource
        this.didConfirmNoWorkSubmit = didConfirmNoWorkSubmit
        this.didConfirmNoRenderWork = didConfirmNoRenderWork
        this.didConfirmNoStateMutation = didConfirmNoStateMutation
        this.didConfirmNoBridgeSmokeHarnessEntryChange =
            didConfirmNoBridgeSmokeHarnessEntryChange
        this.didAvoidDrawableReadyPermission = didAvoidDrawableReadyPermission
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

func cjguiInternalBuildRendererRealDrawableLifecycleIntent(
    noRealCommandQueueReadiness: CjguiInternalRendererNoRealCommandQueueReadiness
): CjguiInternalRendererRealDrawableLifecycleIntent {
    let noRealCommandQueue =
        noRealCommandQueueReadiness.isRendererNoRealCommandQueueReady &&
        noRealCommandQueueReadiness.canFutureRendererRealCommandQueueBoundaryEvaluate &&
        noRealCommandQueueReadiness.didSealRendererNoRealCommandQueueReadiness &&
        noRealCommandQueueReadiness.didPreserveRendererRealCommandQueueTeardownPolicy &&
        noRealCommandQueueReadiness.didKeepNoRealCommandQueueReadinessValueOnly &&
        noRealCommandQueueReadiness.didConfirmNoRealQueueCreated &&
        noRealCommandQueueReadiness.didConfirmNoForeignApiCall &&
        noRealCommandQueueReadiness.didConfirmNoBackendResourceCreated &&
        noRealCommandQueueReadiness.didConfirmNoResourceBorrow &&
        noRealCommandQueueReadiness.didConfirmNoForeignResourceToken &&
        noRealCommandQueueReadiness.didConfirmNoPointerLikeResource &&
        noRealCommandQueueReadiness.didConfirmNoWorkSubmit &&
        noRealCommandQueueReadiness.didConfirmNoRenderWork &&
        noRealCommandQueueReadiness.didConfirmNoStateMutation &&
        noRealCommandQueueReadiness.didConfirmNoBridgeSmokeHarnessEntryChange &&
        noRealCommandQueueReadiness.didConfirmNoExternalSurface &&
        noRealCommandQueueReadiness.didAvoidQueueReadyPermission &&
        noRealCommandQueueReadiness.didAvoidBackendImplementationWrapper &&
        noRealCommandQueueReadiness.didAvoidWorkSubmitWrapper &&
        noRealCommandQueueReadiness.didAvoidBufferReadyWrapper &&
        noRealCommandQueueReadiness.didAvoidReceiptRecordPublication &&
        noRealCommandQueueReadiness.didAvoidThinWrapper &&
        noRealCommandQueueReadiness.didStayFullRebuildOnly &&
        noRealCommandQueueReadiness.shouldDeferRendererNoRealCommandQueueReadiness == false &&
        noRealCommandQueueReadiness.shouldReportRendererNoRealCommandQueueReadinessBlocked == false
    let intentDeferred =
        noRealCommandQueueReadiness.isRendererNoRealCommandQueueReady == false &&
        noRealCommandQueueReadiness.canFutureRendererRealCommandQueueBoundaryEvaluate == false &&
        noRealCommandQueueReadiness.shouldDeferRendererNoRealCommandQueueReadiness &&
        noRealCommandQueueReadiness.shouldReportRendererNoRealCommandQueueReadinessBlocked == false
    let intentInconsistent = (
        noRealCommandQueueReadiness.isRendererNoRealCommandQueueReady &&
            (
                noRealCommandQueueReadiness.canFutureRendererRealCommandQueueBoundaryEvaluate == false ||
                noRealCommandQueueReadiness.didSealRendererNoRealCommandQueueReadiness == false ||
                noRealCommandQueueReadiness.didPreserveRendererRealCommandQueueTeardownPolicy == false ||
                noRealCommandQueueReadiness.didKeepNoRealCommandQueueReadinessValueOnly == false ||
                noRealCommandQueueReadiness.didConfirmNoRealQueueCreated == false ||
                noRealCommandQueueReadiness.didConfirmNoForeignApiCall == false ||
                noRealCommandQueueReadiness.didConfirmNoBackendResourceCreated == false ||
                noRealCommandQueueReadiness.didConfirmNoResourceBorrow == false ||
                noRealCommandQueueReadiness.didConfirmNoForeignResourceToken == false ||
                noRealCommandQueueReadiness.didConfirmNoPointerLikeResource == false ||
                noRealCommandQueueReadiness.didConfirmNoWorkSubmit == false ||
                noRealCommandQueueReadiness.didConfirmNoRenderWork == false ||
                noRealCommandQueueReadiness.didConfirmNoStateMutation == false ||
                noRealCommandQueueReadiness.didConfirmNoBridgeSmokeHarnessEntryChange == false ||
                noRealCommandQueueReadiness.didConfirmNoExternalSurface == false ||
                noRealCommandQueueReadiness.didAvoidQueueReadyPermission == false ||
                noRealCommandQueueReadiness.didAvoidBackendImplementationWrapper == false ||
                noRealCommandQueueReadiness.didAvoidWorkSubmitWrapper == false ||
                noRealCommandQueueReadiness.didAvoidBufferReadyWrapper == false ||
                noRealCommandQueueReadiness.didAvoidReceiptRecordPublication == false ||
                noRealCommandQueueReadiness.didAvoidThinWrapper == false ||
                noRealCommandQueueReadiness.didStayFullRebuildOnly == false ||
                noRealCommandQueueReadiness.shouldDeferRendererNoRealCommandQueueReadiness ||
                noRealCommandQueueReadiness.shouldReportRendererNoRealCommandQueueReadinessBlocked
            )
        ) ||
        (noRealCommandQueueReadiness.canFutureRendererRealCommandQueueBoundaryEvaluate &&
            noRealCommandQueueReadiness.isRendererNoRealCommandQueueReady == false) ||
        (noRealCommandQueueReadiness.shouldDeferRendererNoRealCommandQueueReadiness &&
            noRealCommandQueueReadiness.shouldReportRendererNoRealCommandQueueReadinessBlocked)

    if (
        noRealCommandQueueReadiness.shouldReportRendererNoRealCommandQueueReadinessBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererRealDrawableLifecycleIntent(
            noRealCommandQueueReadiness,
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

    if (noRealCommandQueue) {
        return CjguiInternalRendererRealDrawableLifecycleIntent(
            noRealCommandQueueReadiness,
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
        return CjguiInternalRendererRealDrawableLifecycleIntent(
            noRealCommandQueueReadiness,
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

    return CjguiInternalRendererRealDrawableLifecycleIntent(
        noRealCommandQueueReadiness,
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

func cjguiInternalBuildRendererRealDrawableAvailabilityPolicy(
    lifecycleIntent: CjguiInternalRendererRealDrawableLifecycleIntent
): CjguiInternalRendererRealDrawableAvailabilityPolicy {
    let intentReady =
        lifecycleIntent.didPrepareRendererRealDrawableLifecycleIntent &&
        lifecycleIntent.didPreserveRendererNoRealCommandQueueReadiness &&
        lifecycleIntent.didDefineFutureRealDrawableLifecycleIntent &&
        lifecycleIntent.didDescribeDrawableAvailabilityFacts &&
        lifecycleIntent.didDescribeDrawableAcquisitionGuardFacts &&
        lifecycleIntent.didDescribePresentationOwnershipFacts &&
        lifecycleIntent.didKeepRealDrawableLifecycleIntentValueOnly &&
        lifecycleIntent.didAvoidDrawableLookup &&
        lifecycleIntent.didAvoidForeignApiCall &&
        lifecycleIntent.didAvoidThinWrapper &&
        lifecycleIntent.shouldDeferRendererRealDrawableLifecycleIntent == false &&
        lifecycleIntent.shouldReportRendererRealDrawableLifecycleIntentBlocked == false
    let policyDeferred =
        lifecycleIntent.didPrepareRendererRealDrawableLifecycleIntent == false &&
        lifecycleIntent.shouldDeferRendererRealDrawableLifecycleIntent &&
        lifecycleIntent.shouldReportRendererRealDrawableLifecycleIntentBlocked == false
    let policyInconsistent = (
        lifecycleIntent.didPrepareRendererRealDrawableLifecycleIntent &&
            (
                lifecycleIntent.didPreserveRendererNoRealCommandQueueReadiness == false ||
                lifecycleIntent.didDefineFutureRealDrawableLifecycleIntent == false ||
                lifecycleIntent.didDescribeDrawableAvailabilityFacts == false ||
                lifecycleIntent.didDescribeDrawableAcquisitionGuardFacts == false ||
                lifecycleIntent.didDescribePresentationOwnershipFacts == false ||
                lifecycleIntent.didKeepRealDrawableLifecycleIntentValueOnly == false ||
                lifecycleIntent.didAvoidDrawableLookup == false ||
                lifecycleIntent.didAvoidForeignApiCall == false ||
                lifecycleIntent.didAvoidThinWrapper == false ||
                lifecycleIntent.shouldDeferRendererRealDrawableLifecycleIntent ||
                lifecycleIntent.shouldReportRendererRealDrawableLifecycleIntentBlocked
            )
        ) ||
        (lifecycleIntent.didPreserveRendererNoRealCommandQueueReadiness &&
            lifecycleIntent.didPrepareRendererRealDrawableLifecycleIntent == false) ||
        (lifecycleIntent.shouldDeferRendererRealDrawableLifecycleIntent &&
            lifecycleIntent.shouldReportRendererRealDrawableLifecycleIntentBlocked)

    if (
        lifecycleIntent.shouldReportRendererRealDrawableLifecycleIntentBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererRealDrawableAvailabilityPolicy(
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
        return CjguiInternalRendererRealDrawableAvailabilityPolicy(
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

    if (policyDeferred) {
        return CjguiInternalRendererRealDrawableAvailabilityPolicy(
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

    return CjguiInternalRendererRealDrawableAvailabilityPolicy(
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

func cjguiInternalBuildRendererRealDrawableAcquisitionGuard(
    availabilityPolicy: CjguiInternalRendererRealDrawableAvailabilityPolicy
): CjguiInternalRendererRealDrawableAcquisitionGuard {
    let policyReady =
        availabilityPolicy.didPrepareRendererRealDrawableAvailabilityPolicy &&
        availabilityPolicy.didPreserveRendererRealDrawableLifecycleIntent &&
        availabilityPolicy.didDefineFutureDrawableAvailabilityPolicy &&
        availabilityPolicy.didDescribeDrawableUnavailableFailureFacts &&
        availabilityPolicy.didDescribeNoDrawFallbackFacts &&
        availabilityPolicy.didDescribeResizeScaleColorRelationFacts &&
        availabilityPolicy.didKeepDrawableAvailabilityPolicyValueOnly &&
        availabilityPolicy.didAvoidDrawableLookup &&
        availabilityPolicy.didAvoidDrawableOwnership &&
        availabilityPolicy.didAvoidDrawableReadyPermission &&
        availabilityPolicy.shouldDeferRendererRealDrawableAvailabilityPolicy == false &&
        availabilityPolicy.shouldReportRendererRealDrawableAvailabilityPolicyBlocked == false
    let guardDeferred =
        availabilityPolicy.didPrepareRendererRealDrawableAvailabilityPolicy == false &&
        availabilityPolicy.shouldDeferRendererRealDrawableAvailabilityPolicy &&
        availabilityPolicy.shouldReportRendererRealDrawableAvailabilityPolicyBlocked == false
    let guardInconsistent = (
        availabilityPolicy.didPrepareRendererRealDrawableAvailabilityPolicy &&
            (
                availabilityPolicy.didPreserveRendererRealDrawableLifecycleIntent == false ||
                availabilityPolicy.didDefineFutureDrawableAvailabilityPolicy == false ||
                availabilityPolicy.didDescribeDrawableUnavailableFailureFacts == false ||
                availabilityPolicy.didDescribeNoDrawFallbackFacts == false ||
                availabilityPolicy.didDescribeResizeScaleColorRelationFacts == false ||
                availabilityPolicy.didKeepDrawableAvailabilityPolicyValueOnly == false ||
                availabilityPolicy.didAvoidDrawableLookup == false ||
                availabilityPolicy.didAvoidDrawableOwnership == false ||
                availabilityPolicy.didAvoidDrawableReadyPermission == false ||
                availabilityPolicy.shouldDeferRendererRealDrawableAvailabilityPolicy ||
                availabilityPolicy.shouldReportRendererRealDrawableAvailabilityPolicyBlocked
            )
        ) ||
        (availabilityPolicy.didPreserveRendererRealDrawableLifecycleIntent &&
            availabilityPolicy.didPrepareRendererRealDrawableAvailabilityPolicy == false) ||
        (availabilityPolicy.shouldDeferRendererRealDrawableAvailabilityPolicy &&
            availabilityPolicy.shouldReportRendererRealDrawableAvailabilityPolicyBlocked)

    if (
        availabilityPolicy.shouldReportRendererRealDrawableAvailabilityPolicyBlocked ||
        guardInconsistent
    ) {
        return CjguiInternalRendererRealDrawableAcquisitionGuard(
            availabilityPolicy,
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

    if (policyReady) {
        return CjguiInternalRendererRealDrawableAcquisitionGuard(
            availabilityPolicy,
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

    if (guardDeferred) {
        return CjguiInternalRendererRealDrawableAcquisitionGuard(
            availabilityPolicy,
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

    return CjguiInternalRendererRealDrawableAcquisitionGuard(
        availabilityPolicy,
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

func cjguiInternalBuildRendererRealDrawablePresentationOwnershipPolicy(
    acquisitionGuard: CjguiInternalRendererRealDrawableAcquisitionGuard
): CjguiInternalRendererRealDrawablePresentationOwnershipPolicy {
    let guardReady =
        acquisitionGuard.didPrepareRendererRealDrawableAcquisitionGuard &&
        acquisitionGuard.didPreserveRendererRealDrawableAvailabilityPolicy &&
        acquisitionGuard.didDefineFutureDrawableAcquisitionGuard &&
        acquisitionGuard.didDescribeLateBoundDrawableFacts &&
        acquisitionGuard.didDescribeUnavailableTimeoutFallbackFacts &&
        acquisitionGuard.didDescribeNoBorrowedResourceFacts &&
        acquisitionGuard.didKeepDrawableAcquisitionGuardValueOnly &&
        acquisitionGuard.didAvoidDrawableLookup &&
        acquisitionGuard.didAvoidBlockingForeignCall &&
        acquisitionGuard.didAvoidResourceToken &&
        acquisitionGuard.shouldDeferRendererRealDrawableAcquisitionGuard == false &&
        acquisitionGuard.shouldReportRendererRealDrawableAcquisitionGuardBlocked == false
    let policyDeferred =
        acquisitionGuard.didPrepareRendererRealDrawableAcquisitionGuard == false &&
        acquisitionGuard.shouldDeferRendererRealDrawableAcquisitionGuard &&
        acquisitionGuard.shouldReportRendererRealDrawableAcquisitionGuardBlocked == false
    let policyInconsistent = (
        acquisitionGuard.didPrepareRendererRealDrawableAcquisitionGuard &&
            (
                acquisitionGuard.didPreserveRendererRealDrawableAvailabilityPolicy == false ||
                acquisitionGuard.didDefineFutureDrawableAcquisitionGuard == false ||
                acquisitionGuard.didDescribeLateBoundDrawableFacts == false ||
                acquisitionGuard.didDescribeUnavailableTimeoutFallbackFacts == false ||
                acquisitionGuard.didDescribeNoBorrowedResourceFacts == false ||
                acquisitionGuard.didKeepDrawableAcquisitionGuardValueOnly == false ||
                acquisitionGuard.didAvoidDrawableLookup == false ||
                acquisitionGuard.didAvoidBlockingForeignCall == false ||
                acquisitionGuard.didAvoidResourceToken == false ||
                acquisitionGuard.shouldDeferRendererRealDrawableAcquisitionGuard ||
                acquisitionGuard.shouldReportRendererRealDrawableAcquisitionGuardBlocked
            )
        ) ||
        (acquisitionGuard.didPreserveRendererRealDrawableAvailabilityPolicy &&
            acquisitionGuard.didPrepareRendererRealDrawableAcquisitionGuard == false) ||
        (acquisitionGuard.shouldDeferRendererRealDrawableAcquisitionGuard &&
            acquisitionGuard.shouldReportRendererRealDrawableAcquisitionGuardBlocked)

    if (
        acquisitionGuard.shouldReportRendererRealDrawableAcquisitionGuardBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererRealDrawablePresentationOwnershipPolicy(
            acquisitionGuard,
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

    if (guardReady) {
        return CjguiInternalRendererRealDrawablePresentationOwnershipPolicy(
            acquisitionGuard,
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

    if (policyDeferred) {
        return CjguiInternalRendererRealDrawablePresentationOwnershipPolicy(
            acquisitionGuard,
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

    return CjguiInternalRendererRealDrawablePresentationOwnershipPolicy(
        acquisitionGuard,
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

func cjguiInternalBuildRendererNoRealDrawableReadiness(
    presentationOwnershipPolicy:
        CjguiInternalRendererRealDrawablePresentationOwnershipPolicy
): CjguiInternalRendererNoRealDrawableReadiness {
    let presentationReady =
        presentationOwnershipPolicy.didPrepareRendererRealDrawablePresentationOwnershipPolicy &&
        presentationOwnershipPolicy.didPreserveRendererRealDrawableAcquisitionGuard &&
        presentationOwnershipPolicy.didDefineFutureDrawablePresentationOwnershipPolicy &&
        presentationOwnershipPolicy.didDescribePresentationOwnerFacts &&
        presentationOwnershipPolicy.didDescribeDrawableReleaseExpectationFacts &&
        presentationOwnershipPolicy.didDescribeNoPresentFacts &&
        presentationOwnershipPolicy.didKeepDrawablePresentationOwnershipPolicyValueOnly &&
        presentationOwnershipPolicy.didAvoidPresentingDrawable &&
        presentationOwnershipPolicy.didAvoidSubmitWork &&
        presentationOwnershipPolicy.didAvoidPassOrEncoderObject &&
        presentationOwnershipPolicy.didAvoidStateMutation &&
        presentationOwnershipPolicy.shouldDeferRendererRealDrawablePresentationOwnershipPolicy == false &&
        presentationOwnershipPolicy.shouldReportRendererRealDrawablePresentationOwnershipPolicyBlocked == false
    let readinessDeferred =
        presentationOwnershipPolicy.didPrepareRendererRealDrawablePresentationOwnershipPolicy == false &&
        presentationOwnershipPolicy.shouldDeferRendererRealDrawablePresentationOwnershipPolicy &&
        presentationOwnershipPolicy.shouldReportRendererRealDrawablePresentationOwnershipPolicyBlocked == false
    let readinessInconsistent = (
        presentationOwnershipPolicy.didPrepareRendererRealDrawablePresentationOwnershipPolicy &&
            (
                presentationOwnershipPolicy.didPreserveRendererRealDrawableAcquisitionGuard == false ||
                presentationOwnershipPolicy.didDefineFutureDrawablePresentationOwnershipPolicy == false ||
                presentationOwnershipPolicy.didDescribePresentationOwnerFacts == false ||
                presentationOwnershipPolicy.didDescribeDrawableReleaseExpectationFacts == false ||
                presentationOwnershipPolicy.didDescribeNoPresentFacts == false ||
                presentationOwnershipPolicy.didKeepDrawablePresentationOwnershipPolicyValueOnly == false ||
                presentationOwnershipPolicy.didAvoidPresentingDrawable == false ||
                presentationOwnershipPolicy.didAvoidSubmitWork == false ||
                presentationOwnershipPolicy.didAvoidPassOrEncoderObject == false ||
                presentationOwnershipPolicy.didAvoidStateMutation == false ||
                presentationOwnershipPolicy.shouldDeferRendererRealDrawablePresentationOwnershipPolicy ||
                presentationOwnershipPolicy.shouldReportRendererRealDrawablePresentationOwnershipPolicyBlocked
            )
        ) ||
        (presentationOwnershipPolicy.didPreserveRendererRealDrawableAcquisitionGuard &&
            presentationOwnershipPolicy.didPrepareRendererRealDrawablePresentationOwnershipPolicy == false) ||
        (presentationOwnershipPolicy.shouldDeferRendererRealDrawablePresentationOwnershipPolicy &&
            presentationOwnershipPolicy.shouldReportRendererRealDrawablePresentationOwnershipPolicyBlocked)

    if (
        presentationOwnershipPolicy.shouldReportRendererRealDrawablePresentationOwnershipPolicyBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoRealDrawableReadiness(
            presentationOwnershipPolicy,
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
            true,
            true
        )
    }

    if (presentationReady) {
        return CjguiInternalRendererNoRealDrawableReadiness(
            presentationOwnershipPolicy,
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
            true,
            true
        )
    }

    if (readinessDeferred) {
        return CjguiInternalRendererNoRealDrawableReadiness(
            presentationOwnershipPolicy,
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
            true,
            true
        )
    }

    return CjguiInternalRendererNoRealDrawableReadiness(
        presentationOwnershipPolicy,
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
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererRealDrawableLifecycleDraft(
): CjguiInternalRendererNoRealDrawableReadiness {
    let noRealCommandQueueReadiness =
        cjguiInternalExecuteDefaultRendererRealCommandQueueLifecycleDraft()
    let lifecycleIntent =
        cjguiInternalBuildRendererRealDrawableLifecycleIntent(
            noRealCommandQueueReadiness
        )
    let availabilityPolicy =
        cjguiInternalBuildRendererRealDrawableAvailabilityPolicy(
            lifecycleIntent
        )
    let acquisitionGuard =
        cjguiInternalBuildRendererRealDrawableAcquisitionGuard(
            availabilityPolicy
        )
    let presentationOwnershipPolicy =
        cjguiInternalBuildRendererRealDrawablePresentationOwnershipPolicy(
            acquisitionGuard
        )
    return cjguiInternalBuildRendererNoRealDrawableReadiness(
        presentationOwnershipPolicy
    )
}
