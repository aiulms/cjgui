package cjgui

// This owner records value-only facts for future command submission. It keeps
// commit policy, presentation gates, and failure policy inert.
struct CjguiInternalRendererCommandSubmissionIntent {
    let noRealDrawableReadiness: CjguiInternalRendererNoRealDrawableReadiness
    let didPrepareRendererCommandSubmissionIntent: Bool
    let shouldDeferRendererCommandSubmissionIntent: Bool
    let shouldReportRendererCommandSubmissionIntentBlocked: Bool
    let didPreserveRendererNoRealDrawableReadiness: Bool
    let didDefineFutureCommandSubmissionIntent: Bool
    let didDescribeCommitPolicyNeed: Bool
    let didDescribePresentationGateNeed: Bool
    let didDescribeSubmissionFailureNeed: Bool
    let didKeepCommandSubmissionIntentValueOnly: Bool
    let didAvoidExecutionPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        noRealDrawableReadiness: CjguiInternalRendererNoRealDrawableReadiness,
        didPrepareRendererCommandSubmissionIntent: Bool,
        shouldDeferRendererCommandSubmissionIntent: Bool,
        shouldReportRendererCommandSubmissionIntentBlocked: Bool,
        didPreserveRendererNoRealDrawableReadiness: Bool,
        didDefineFutureCommandSubmissionIntent: Bool,
        didDescribeCommitPolicyNeed: Bool,
        didDescribePresentationGateNeed: Bool,
        didDescribeSubmissionFailureNeed: Bool,
        didKeepCommandSubmissionIntentValueOnly: Bool,
        didAvoidExecutionPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noRealDrawableReadiness = noRealDrawableReadiness
        this.didPrepareRendererCommandSubmissionIntent =
            didPrepareRendererCommandSubmissionIntent
        this.shouldDeferRendererCommandSubmissionIntent =
            shouldDeferRendererCommandSubmissionIntent
        this.shouldReportRendererCommandSubmissionIntentBlocked =
            shouldReportRendererCommandSubmissionIntentBlocked
        this.didPreserveRendererNoRealDrawableReadiness =
            didPreserveRendererNoRealDrawableReadiness
        this.didDefineFutureCommandSubmissionIntent =
            didDefineFutureCommandSubmissionIntent
        this.didDescribeCommitPolicyNeed = didDescribeCommitPolicyNeed
        this.didDescribePresentationGateNeed =
            didDescribePresentationGateNeed
        this.didDescribeSubmissionFailureNeed =
            didDescribeSubmissionFailureNeed
        this.didKeepCommandSubmissionIntentValueOnly =
            didKeepCommandSubmissionIntentValueOnly
        this.didAvoidExecutionPermissionWrapper =
            didAvoidExecutionPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

// Commit policy facts describe future timing and single-use constraints. They
// do not create a command buffer or commit work.
struct CjguiInternalRendererCommandBufferCommitPolicy {
    let commandSubmissionIntent: CjguiInternalRendererCommandSubmissionIntent
    let didPrepareRendererCommandBufferCommitPolicy: Bool
    let shouldDeferRendererCommandBufferCommitPolicy: Bool
    let shouldReportRendererCommandBufferCommitPolicyBlocked: Bool
    let didPreserveRendererCommandSubmissionIntent: Bool
    let didDescribeCommitTimingFacts: Bool
    let didDescribeSingleUseFacts: Bool
    let didDescribeNoCommitFacts: Bool
    let didKeepCommandBufferCommitPolicyValueOnly: Bool
    let didAvoidCommandBufferObject: Bool
    let didAvoidCommandBufferCommit: Bool
    let didAvoidCommandBufferReadyPermission: Bool

    init(
        commandSubmissionIntent: CjguiInternalRendererCommandSubmissionIntent,
        didPrepareRendererCommandBufferCommitPolicy: Bool,
        shouldDeferRendererCommandBufferCommitPolicy: Bool,
        shouldReportRendererCommandBufferCommitPolicyBlocked: Bool,
        didPreserveRendererCommandSubmissionIntent: Bool,
        didDescribeCommitTimingFacts: Bool,
        didDescribeSingleUseFacts: Bool,
        didDescribeNoCommitFacts: Bool,
        didKeepCommandBufferCommitPolicyValueOnly: Bool,
        didAvoidCommandBufferObject: Bool,
        didAvoidCommandBufferCommit: Bool,
        didAvoidCommandBufferReadyPermission: Bool
    ) {
        this.commandSubmissionIntent = commandSubmissionIntent
        this.didPrepareRendererCommandBufferCommitPolicy =
            didPrepareRendererCommandBufferCommitPolicy
        this.shouldDeferRendererCommandBufferCommitPolicy =
            shouldDeferRendererCommandBufferCommitPolicy
        this.shouldReportRendererCommandBufferCommitPolicyBlocked =
            shouldReportRendererCommandBufferCommitPolicyBlocked
        this.didPreserveRendererCommandSubmissionIntent =
            didPreserveRendererCommandSubmissionIntent
        this.didDescribeCommitTimingFacts = didDescribeCommitTimingFacts
        this.didDescribeSingleUseFacts = didDescribeSingleUseFacts
        this.didDescribeNoCommitFacts = didDescribeNoCommitFacts
        this.didKeepCommandBufferCommitPolicyValueOnly =
            didKeepCommandBufferCommitPolicyValueOnly
        this.didAvoidCommandBufferObject = didAvoidCommandBufferObject
        this.didAvoidCommandBufferCommit = didAvoidCommandBufferCommit
        this.didAvoidCommandBufferReadyPermission =
            didAvoidCommandBufferReadyPermission
    }
}

// Presentation gate facts describe future ordering relation only. They do not
// acquire or present a drawable.
struct CjguiInternalRendererDrawablePresentationGate {
    let commitPolicy: CjguiInternalRendererCommandBufferCommitPolicy
    let didPrepareRendererDrawablePresentationGate: Bool
    let shouldDeferRendererDrawablePresentationGate: Bool
    let shouldReportRendererDrawablePresentationGateBlocked: Bool
    let didPreserveRendererCommandBufferCommitPolicy: Bool
    let didDescribePresentationOrderingFacts: Bool
    let didDescribeNoPresentFacts: Bool
    let didDescribeNoDrawableAcquisitionFacts: Bool
    let didKeepDrawablePresentationGateValueOnly: Bool
    let didAvoidDrawablePresentation: Bool
    let didAvoidDrawableObject: Bool
    let didAvoidDrawablePresentReadyWrapper: Bool

    init(
        commitPolicy: CjguiInternalRendererCommandBufferCommitPolicy,
        didPrepareRendererDrawablePresentationGate: Bool,
        shouldDeferRendererDrawablePresentationGate: Bool,
        shouldReportRendererDrawablePresentationGateBlocked: Bool,
        didPreserveRendererCommandBufferCommitPolicy: Bool,
        didDescribePresentationOrderingFacts: Bool,
        didDescribeNoPresentFacts: Bool,
        didDescribeNoDrawableAcquisitionFacts: Bool,
        didKeepDrawablePresentationGateValueOnly: Bool,
        didAvoidDrawablePresentation: Bool,
        didAvoidDrawableObject: Bool,
        didAvoidDrawablePresentReadyWrapper: Bool
    ) {
        this.commitPolicy = commitPolicy
        this.didPrepareRendererDrawablePresentationGate =
            didPrepareRendererDrawablePresentationGate
        this.shouldDeferRendererDrawablePresentationGate =
            shouldDeferRendererDrawablePresentationGate
        this.shouldReportRendererDrawablePresentationGateBlocked =
            shouldReportRendererDrawablePresentationGateBlocked
        this.didPreserveRendererCommandBufferCommitPolicy =
            didPreserveRendererCommandBufferCommitPolicy
        this.didDescribePresentationOrderingFacts =
            didDescribePresentationOrderingFacts
        this.didDescribeNoPresentFacts = didDescribeNoPresentFacts
        this.didDescribeNoDrawableAcquisitionFacts =
            didDescribeNoDrawableAcquisitionFacts
        this.didKeepDrawablePresentationGateValueOnly =
            didKeepDrawablePresentationGateValueOnly
        this.didAvoidDrawablePresentation = didAvoidDrawablePresentation
        this.didAvoidDrawableObject = didAvoidDrawableObject
        this.didAvoidDrawablePresentReadyWrapper =
            didAvoidDrawablePresentReadyWrapper
    }
}

// Failure policy facts describe future completion, rollback, and no-draw
// fallback relation. They do not register callbacks or observe real work.
struct CjguiInternalRendererGpuSubmissionFailurePolicy {
    let presentationGate: CjguiInternalRendererDrawablePresentationGate
    let didPrepareRendererGpuSubmissionFailurePolicy: Bool
    let shouldDeferRendererGpuSubmissionFailurePolicy: Bool
    let shouldReportRendererGpuSubmissionFailurePolicyBlocked: Bool
    let didPreserveRendererDrawablePresentationGate: Bool
    let didDescribeCompletionFailureFacts: Bool
    let didDescribeRollbackNoDrawFacts: Bool
    let didDescribeResourceRetentionConcernFacts: Bool
    let didKeepGpuSubmissionFailurePolicyValueOnly: Bool
    let didAvoidGpuCompletionObservation: Bool
    let didAvoidCallbackRegistration: Bool
    let didAvoidTelemetryPublication: Bool

    init(
        presentationGate: CjguiInternalRendererDrawablePresentationGate,
        didPrepareRendererGpuSubmissionFailurePolicy: Bool,
        shouldDeferRendererGpuSubmissionFailurePolicy: Bool,
        shouldReportRendererGpuSubmissionFailurePolicyBlocked: Bool,
        didPreserveRendererDrawablePresentationGate: Bool,
        didDescribeCompletionFailureFacts: Bool,
        didDescribeRollbackNoDrawFacts: Bool,
        didDescribeResourceRetentionConcernFacts: Bool,
        didKeepGpuSubmissionFailurePolicyValueOnly: Bool,
        didAvoidGpuCompletionObservation: Bool,
        didAvoidCallbackRegistration: Bool,
        didAvoidTelemetryPublication: Bool
    ) {
        this.presentationGate = presentationGate
        this.didPrepareRendererGpuSubmissionFailurePolicy =
            didPrepareRendererGpuSubmissionFailurePolicy
        this.shouldDeferRendererGpuSubmissionFailurePolicy =
            shouldDeferRendererGpuSubmissionFailurePolicy
        this.shouldReportRendererGpuSubmissionFailurePolicyBlocked =
            shouldReportRendererGpuSubmissionFailurePolicyBlocked
        this.didPreserveRendererDrawablePresentationGate =
            didPreserveRendererDrawablePresentationGate
        this.didDescribeCompletionFailureFacts =
            didDescribeCompletionFailureFacts
        this.didDescribeRollbackNoDrawFacts = didDescribeRollbackNoDrawFacts
        this.didDescribeResourceRetentionConcernFacts =
            didDescribeResourceRetentionConcernFacts
        this.didKeepGpuSubmissionFailurePolicyValueOnly =
            didKeepGpuSubmissionFailurePolicyValueOnly
        this.didAvoidGpuCompletionObservation =
            didAvoidGpuCompletionObservation
        this.didAvoidCallbackRegistration = didAvoidCallbackRegistration
        this.didAvoidTelemetryPublication = didAvoidTelemetryPublication
    }
}

// This endpoint seals no-gpu-submission value facts. It is not permission to
// submit work, present output, execute render work, or write renderer state.
struct CjguiInternalRendererNoGpuSubmissionReadiness {
    let failurePolicy: CjguiInternalRendererGpuSubmissionFailurePolicy
    let isRendererNoGpuSubmissionReady: Bool
    let canFutureRendererCommandSubmissionBoundaryEvaluate: Bool
    let shouldDeferRendererNoGpuSubmissionReadiness: Bool
    let shouldReportRendererNoGpuSubmissionReadinessBlocked: Bool
    let didSealRendererNoGpuSubmissionReadiness: Bool
    let didPreserveRendererGpuSubmissionFailurePolicy: Bool
    let didKeepNoGpuSubmissionReadinessValueOnly: Bool
    let didConfirmNoCommandBufferCreated: Bool
    let didConfirmNoCommandBufferCommit: Bool
    let didConfirmNoDrawablePresented: Bool
    let didConfirmNoGpuWorkSubmitted: Bool
    let didConfirmNoRenderExecutionOrRendererStateWrite: Bool
    let didConfirmNoForeignOrPointerResource: Bool
    let didConfirmNoCallbackOrTelemetryPublication: Bool
    let didConfirmNoBridgeSmokeHarnessEntryChange: Bool
    let didAvoidGpuSubmissionPermission: Bool
    let didAvoidCommandBufferReadyWrapper: Bool
    let didAvoidDrawablePresentReadyWrapper: Bool
    let didAvoidBackendImplementationWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        failurePolicy: CjguiInternalRendererGpuSubmissionFailurePolicy,
        isRendererNoGpuSubmissionReady: Bool,
        canFutureRendererCommandSubmissionBoundaryEvaluate: Bool,
        shouldDeferRendererNoGpuSubmissionReadiness: Bool,
        shouldReportRendererNoGpuSubmissionReadinessBlocked: Bool,
        didSealRendererNoGpuSubmissionReadiness: Bool,
        didPreserveRendererGpuSubmissionFailurePolicy: Bool,
        didKeepNoGpuSubmissionReadinessValueOnly: Bool,
        didConfirmNoCommandBufferCreated: Bool,
        didConfirmNoCommandBufferCommit: Bool,
        didConfirmNoDrawablePresented: Bool,
        didConfirmNoGpuWorkSubmitted: Bool,
        didConfirmNoRenderExecutionOrRendererStateWrite: Bool,
        didConfirmNoForeignOrPointerResource: Bool,
        didConfirmNoCallbackOrTelemetryPublication: Bool,
        didConfirmNoBridgeSmokeHarnessEntryChange: Bool,
        didAvoidGpuSubmissionPermission: Bool,
        didAvoidCommandBufferReadyWrapper: Bool,
        didAvoidDrawablePresentReadyWrapper: Bool,
        didAvoidBackendImplementationWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.failurePolicy = failurePolicy
        this.isRendererNoGpuSubmissionReady = isRendererNoGpuSubmissionReady
        this.canFutureRendererCommandSubmissionBoundaryEvaluate =
            canFutureRendererCommandSubmissionBoundaryEvaluate
        this.shouldDeferRendererNoGpuSubmissionReadiness =
            shouldDeferRendererNoGpuSubmissionReadiness
        this.shouldReportRendererNoGpuSubmissionReadinessBlocked =
            shouldReportRendererNoGpuSubmissionReadinessBlocked
        this.didSealRendererNoGpuSubmissionReadiness =
            didSealRendererNoGpuSubmissionReadiness
        this.didPreserveRendererGpuSubmissionFailurePolicy =
            didPreserveRendererGpuSubmissionFailurePolicy
        this.didKeepNoGpuSubmissionReadinessValueOnly =
            didKeepNoGpuSubmissionReadinessValueOnly
        this.didConfirmNoCommandBufferCreated =
            didConfirmNoCommandBufferCreated
        this.didConfirmNoCommandBufferCommit =
            didConfirmNoCommandBufferCommit
        this.didConfirmNoDrawablePresented = didConfirmNoDrawablePresented
        this.didConfirmNoGpuWorkSubmitted = didConfirmNoGpuWorkSubmitted
        this.didConfirmNoRenderExecutionOrRendererStateWrite =
            didConfirmNoRenderExecutionOrRendererStateWrite
        this.didConfirmNoForeignOrPointerResource =
            didConfirmNoForeignOrPointerResource
        this.didConfirmNoCallbackOrTelemetryPublication =
            didConfirmNoCallbackOrTelemetryPublication
        this.didConfirmNoBridgeSmokeHarnessEntryChange =
            didConfirmNoBridgeSmokeHarnessEntryChange
        this.didAvoidGpuSubmissionPermission =
            didAvoidGpuSubmissionPermission
        this.didAvoidCommandBufferReadyWrapper =
            didAvoidCommandBufferReadyWrapper
        this.didAvoidDrawablePresentReadyWrapper =
            didAvoidDrawablePresentReadyWrapper
        this.didAvoidBackendImplementationWrapper =
            didAvoidBackendImplementationWrapper
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererCommandSubmissionIntent(
    noRealDrawableReadiness: CjguiInternalRendererNoRealDrawableReadiness
): CjguiInternalRendererCommandSubmissionIntent {
    let noRealDrawable =
        noRealDrawableReadiness.isRendererNoRealDrawableReady &&
        noRealDrawableReadiness.canFutureRendererRealDrawableBoundaryEvaluate &&
        noRealDrawableReadiness.didSealRendererNoRealDrawableReadiness &&
        noRealDrawableReadiness.didPreserveRendererRealDrawablePresentationOwnershipPolicy &&
        noRealDrawableReadiness.didKeepNoRealDrawableReadinessValueOnly &&
        noRealDrawableReadiness.didConfirmNoDrawableAcquired &&
        noRealDrawableReadiness.didConfirmNoDrawableObjectHeld &&
        noRealDrawableReadiness.didConfirmNoDrawableTextureExposed &&
        noRealDrawableReadiness.didConfirmNoSubmissionObjectCreated &&
        noRealDrawableReadiness.didConfirmNoPassOrEncoderObject &&
        noRealDrawableReadiness.didConfirmNoForeignApiCall &&
        noRealDrawableReadiness.didConfirmNoResourceToken &&
        noRealDrawableReadiness.didConfirmNoPointerLikeResource &&
        noRealDrawableReadiness.didConfirmNoWorkSubmit &&
        noRealDrawableReadiness.didConfirmNoRenderWork &&
        noRealDrawableReadiness.didConfirmNoStateMutation &&
        noRealDrawableReadiness.didConfirmNoBridgeSmokeHarnessEntryChange &&
        noRealDrawableReadiness.didAvoidDrawableReadyPermission &&
        noRealDrawableReadiness.didAvoidBackendImplementationWrapper &&
        noRealDrawableReadiness.didAvoidWorkSubmitWrapper &&
        noRealDrawableReadiness.didAvoidBufferReadyWrapper &&
        noRealDrawableReadiness.didAvoidReceiptRecordPublication &&
        noRealDrawableReadiness.didAvoidThinWrapper &&
        noRealDrawableReadiness.didStayFullRebuildOnly &&
        noRealDrawableReadiness.shouldDeferRendererNoRealDrawableReadiness == false &&
        noRealDrawableReadiness.shouldReportRendererNoRealDrawableReadinessBlocked == false
    let intentDeferred =
        noRealDrawableReadiness.isRendererNoRealDrawableReady == false &&
        noRealDrawableReadiness.canFutureRendererRealDrawableBoundaryEvaluate == false &&
        noRealDrawableReadiness.shouldDeferRendererNoRealDrawableReadiness &&
        noRealDrawableReadiness.shouldReportRendererNoRealDrawableReadinessBlocked == false
    let intentInconsistent = (
        noRealDrawableReadiness.isRendererNoRealDrawableReady &&
            (
                noRealDrawableReadiness.canFutureRendererRealDrawableBoundaryEvaluate == false ||
                noRealDrawableReadiness.didSealRendererNoRealDrawableReadiness == false ||
                noRealDrawableReadiness.didPreserveRendererRealDrawablePresentationOwnershipPolicy == false ||
                noRealDrawableReadiness.didKeepNoRealDrawableReadinessValueOnly == false ||
                noRealDrawableReadiness.didConfirmNoDrawableAcquired == false ||
                noRealDrawableReadiness.didConfirmNoDrawableObjectHeld == false ||
                noRealDrawableReadiness.didConfirmNoDrawableTextureExposed == false ||
                noRealDrawableReadiness.didConfirmNoSubmissionObjectCreated == false ||
                noRealDrawableReadiness.didConfirmNoPassOrEncoderObject == false ||
                noRealDrawableReadiness.didConfirmNoForeignApiCall == false ||
                noRealDrawableReadiness.didConfirmNoResourceToken == false ||
                noRealDrawableReadiness.didConfirmNoPointerLikeResource == false ||
                noRealDrawableReadiness.didConfirmNoWorkSubmit == false ||
                noRealDrawableReadiness.didConfirmNoRenderWork == false ||
                noRealDrawableReadiness.didConfirmNoStateMutation == false ||
                noRealDrawableReadiness.didConfirmNoBridgeSmokeHarnessEntryChange == false ||
                noRealDrawableReadiness.didAvoidDrawableReadyPermission == false ||
                noRealDrawableReadiness.didAvoidBackendImplementationWrapper == false ||
                noRealDrawableReadiness.didAvoidWorkSubmitWrapper == false ||
                noRealDrawableReadiness.didAvoidBufferReadyWrapper == false ||
                noRealDrawableReadiness.didAvoidReceiptRecordPublication == false ||
                noRealDrawableReadiness.didAvoidThinWrapper == false ||
                noRealDrawableReadiness.didStayFullRebuildOnly == false ||
                noRealDrawableReadiness.shouldDeferRendererNoRealDrawableReadiness ||
                noRealDrawableReadiness.shouldReportRendererNoRealDrawableReadinessBlocked
            )
        ) ||
        (noRealDrawableReadiness.canFutureRendererRealDrawableBoundaryEvaluate &&
            noRealDrawableReadiness.isRendererNoRealDrawableReady == false) ||
        (noRealDrawableReadiness.shouldDeferRendererNoRealDrawableReadiness &&
            noRealDrawableReadiness.shouldReportRendererNoRealDrawableReadinessBlocked)

    if (
        noRealDrawableReadiness.shouldReportRendererNoRealDrawableReadinessBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererCommandSubmissionIntent(
            noRealDrawableReadiness,
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
            true
        )
    }

    if (noRealDrawable) {
        return CjguiInternalRendererCommandSubmissionIntent(
            noRealDrawableReadiness,
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
            true
        )
    }

    if (intentDeferred) {
        return CjguiInternalRendererCommandSubmissionIntent(
            noRealDrawableReadiness,
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
            true
        )
    }

    return CjguiInternalRendererCommandSubmissionIntent(
        noRealDrawableReadiness,
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
        true
    )
}

func cjguiInternalBuildRendererCommandBufferCommitPolicy(
    commandSubmissionIntent: CjguiInternalRendererCommandSubmissionIntent
): CjguiInternalRendererCommandBufferCommitPolicy {
    let intentReady =
        commandSubmissionIntent.didPrepareRendererCommandSubmissionIntent &&
        commandSubmissionIntent.didPreserveRendererNoRealDrawableReadiness &&
        commandSubmissionIntent.didDefineFutureCommandSubmissionIntent &&
        commandSubmissionIntent.didDescribeCommitPolicyNeed &&
        commandSubmissionIntent.didDescribePresentationGateNeed &&
        commandSubmissionIntent.didDescribeSubmissionFailureNeed &&
        commandSubmissionIntent.didKeepCommandSubmissionIntentValueOnly &&
        commandSubmissionIntent.didAvoidExecutionPermissionWrapper &&
        commandSubmissionIntent.didAvoidThinWrapper &&
        commandSubmissionIntent.shouldDeferRendererCommandSubmissionIntent == false &&
        commandSubmissionIntent.shouldReportRendererCommandSubmissionIntentBlocked == false
    let policyDeferred =
        commandSubmissionIntent.didPrepareRendererCommandSubmissionIntent == false &&
        commandSubmissionIntent.shouldDeferRendererCommandSubmissionIntent &&
        commandSubmissionIntent.shouldReportRendererCommandSubmissionIntentBlocked == false
    let policyInconsistent = (
        commandSubmissionIntent.didPrepareRendererCommandSubmissionIntent &&
            (
                commandSubmissionIntent.didPreserveRendererNoRealDrawableReadiness == false ||
                commandSubmissionIntent.didDefineFutureCommandSubmissionIntent == false ||
                commandSubmissionIntent.didDescribeCommitPolicyNeed == false ||
                commandSubmissionIntent.didDescribePresentationGateNeed == false ||
                commandSubmissionIntent.didDescribeSubmissionFailureNeed == false ||
                commandSubmissionIntent.didKeepCommandSubmissionIntentValueOnly == false ||
                commandSubmissionIntent.didAvoidExecutionPermissionWrapper == false ||
                commandSubmissionIntent.didAvoidThinWrapper == false ||
                commandSubmissionIntent.shouldDeferRendererCommandSubmissionIntent ||
                commandSubmissionIntent.shouldReportRendererCommandSubmissionIntentBlocked
            )
        ) ||
        (commandSubmissionIntent.didPreserveRendererNoRealDrawableReadiness &&
            commandSubmissionIntent.didPrepareRendererCommandSubmissionIntent == false) ||
        (commandSubmissionIntent.shouldDeferRendererCommandSubmissionIntent &&
            commandSubmissionIntent.shouldReportRendererCommandSubmissionIntentBlocked)

    if (
        commandSubmissionIntent.shouldReportRendererCommandSubmissionIntentBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererCommandBufferCommitPolicy(
            commandSubmissionIntent,
            false,
            false,
            true,
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
        return CjguiInternalRendererCommandBufferCommitPolicy(
            commandSubmissionIntent,
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
            true
        )
    }

    if (policyDeferred) {
        return CjguiInternalRendererCommandBufferCommitPolicy(
            commandSubmissionIntent,
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

    return CjguiInternalRendererCommandBufferCommitPolicy(
        commandSubmissionIntent,
        false,
        false,
        true,
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

func cjguiInternalBuildRendererDrawablePresentationGate(
    commitPolicy: CjguiInternalRendererCommandBufferCommitPolicy
): CjguiInternalRendererDrawablePresentationGate {
    let policyReady =
        commitPolicy.didPrepareRendererCommandBufferCommitPolicy &&
        commitPolicy.didPreserveRendererCommandSubmissionIntent &&
        commitPolicy.didDescribeCommitTimingFacts &&
        commitPolicy.didDescribeSingleUseFacts &&
        commitPolicy.didDescribeNoCommitFacts &&
        commitPolicy.didKeepCommandBufferCommitPolicyValueOnly &&
        commitPolicy.didAvoidCommandBufferObject &&
        commitPolicy.didAvoidCommandBufferCommit &&
        commitPolicy.didAvoidCommandBufferReadyPermission &&
        commitPolicy.shouldDeferRendererCommandBufferCommitPolicy == false &&
        commitPolicy.shouldReportRendererCommandBufferCommitPolicyBlocked == false
    let gateDeferred =
        commitPolicy.didPrepareRendererCommandBufferCommitPolicy == false &&
        commitPolicy.shouldDeferRendererCommandBufferCommitPolicy &&
        commitPolicy.shouldReportRendererCommandBufferCommitPolicyBlocked == false
    let gateInconsistent = (
        commitPolicy.didPrepareRendererCommandBufferCommitPolicy &&
            (
                commitPolicy.didPreserveRendererCommandSubmissionIntent == false ||
                commitPolicy.didDescribeCommitTimingFacts == false ||
                commitPolicy.didDescribeSingleUseFacts == false ||
                commitPolicy.didDescribeNoCommitFacts == false ||
                commitPolicy.didKeepCommandBufferCommitPolicyValueOnly == false ||
                commitPolicy.didAvoidCommandBufferObject == false ||
                commitPolicy.didAvoidCommandBufferCommit == false ||
                commitPolicy.didAvoidCommandBufferReadyPermission == false ||
                commitPolicy.shouldDeferRendererCommandBufferCommitPolicy ||
                commitPolicy.shouldReportRendererCommandBufferCommitPolicyBlocked
            )
        ) ||
        (commitPolicy.didPreserveRendererCommandSubmissionIntent &&
            commitPolicy.didPrepareRendererCommandBufferCommitPolicy == false) ||
        (commitPolicy.shouldDeferRendererCommandBufferCommitPolicy &&
            commitPolicy.shouldReportRendererCommandBufferCommitPolicyBlocked)

    if (
        commitPolicy.shouldReportRendererCommandBufferCommitPolicyBlocked ||
        gateInconsistent
    ) {
        return CjguiInternalRendererDrawablePresentationGate(
            commitPolicy,
            false,
            false,
            true,
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
        return CjguiInternalRendererDrawablePresentationGate(
            commitPolicy,
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
            true
        )
    }

    if (gateDeferred) {
        return CjguiInternalRendererDrawablePresentationGate(
            commitPolicy,
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

    return CjguiInternalRendererDrawablePresentationGate(
        commitPolicy,
        false,
        false,
        true,
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

func cjguiInternalBuildRendererGpuSubmissionFailurePolicy(
    presentationGate: CjguiInternalRendererDrawablePresentationGate
): CjguiInternalRendererGpuSubmissionFailurePolicy {
    let gateReady =
        presentationGate.didPrepareRendererDrawablePresentationGate &&
        presentationGate.didPreserveRendererCommandBufferCommitPolicy &&
        presentationGate.didDescribePresentationOrderingFacts &&
        presentationGate.didDescribeNoPresentFacts &&
        presentationGate.didDescribeNoDrawableAcquisitionFacts &&
        presentationGate.didKeepDrawablePresentationGateValueOnly &&
        presentationGate.didAvoidDrawablePresentation &&
        presentationGate.didAvoidDrawableObject &&
        presentationGate.didAvoidDrawablePresentReadyWrapper &&
        presentationGate.shouldDeferRendererDrawablePresentationGate == false &&
        presentationGate.shouldReportRendererDrawablePresentationGateBlocked == false
    let policyDeferred =
        presentationGate.didPrepareRendererDrawablePresentationGate == false &&
        presentationGate.shouldDeferRendererDrawablePresentationGate &&
        presentationGate.shouldReportRendererDrawablePresentationGateBlocked == false
    let policyInconsistent = (
        presentationGate.didPrepareRendererDrawablePresentationGate &&
            (
                presentationGate.didPreserveRendererCommandBufferCommitPolicy == false ||
                presentationGate.didDescribePresentationOrderingFacts == false ||
                presentationGate.didDescribeNoPresentFacts == false ||
                presentationGate.didDescribeNoDrawableAcquisitionFacts == false ||
                presentationGate.didKeepDrawablePresentationGateValueOnly == false ||
                presentationGate.didAvoidDrawablePresentation == false ||
                presentationGate.didAvoidDrawableObject == false ||
                presentationGate.didAvoidDrawablePresentReadyWrapper == false ||
                presentationGate.shouldDeferRendererDrawablePresentationGate ||
                presentationGate.shouldReportRendererDrawablePresentationGateBlocked
            )
        ) ||
        (presentationGate.didPreserveRendererCommandBufferCommitPolicy &&
            presentationGate.didPrepareRendererDrawablePresentationGate == false) ||
        (presentationGate.shouldDeferRendererDrawablePresentationGate &&
            presentationGate.shouldReportRendererDrawablePresentationGateBlocked)

    if (
        presentationGate.shouldReportRendererDrawablePresentationGateBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererGpuSubmissionFailurePolicy(
            presentationGate,
            false,
            false,
            true,
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

    if (gateReady) {
        return CjguiInternalRendererGpuSubmissionFailurePolicy(
            presentationGate,
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
            true
        )
    }

    if (policyDeferred) {
        return CjguiInternalRendererGpuSubmissionFailurePolicy(
            presentationGate,
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

    return CjguiInternalRendererGpuSubmissionFailurePolicy(
        presentationGate,
        false,
        false,
        true,
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

func cjguiInternalBuildRendererNoGpuSubmissionReadiness(
    failurePolicy: CjguiInternalRendererGpuSubmissionFailurePolicy
): CjguiInternalRendererNoGpuSubmissionReadiness {
    let policyReady =
        failurePolicy.didPrepareRendererGpuSubmissionFailurePolicy &&
        failurePolicy.didPreserveRendererDrawablePresentationGate &&
        failurePolicy.didDescribeCompletionFailureFacts &&
        failurePolicy.didDescribeRollbackNoDrawFacts &&
        failurePolicy.didDescribeResourceRetentionConcernFacts &&
        failurePolicy.didKeepGpuSubmissionFailurePolicyValueOnly &&
        failurePolicy.didAvoidGpuCompletionObservation &&
        failurePolicy.didAvoidCallbackRegistration &&
        failurePolicy.didAvoidTelemetryPublication &&
        failurePolicy.shouldDeferRendererGpuSubmissionFailurePolicy == false &&
        failurePolicy.shouldReportRendererGpuSubmissionFailurePolicyBlocked == false
    let readinessDeferred =
        failurePolicy.didPrepareRendererGpuSubmissionFailurePolicy == false &&
        failurePolicy.shouldDeferRendererGpuSubmissionFailurePolicy &&
        failurePolicy.shouldReportRendererGpuSubmissionFailurePolicyBlocked == false
    let readinessInconsistent = (
        failurePolicy.didPrepareRendererGpuSubmissionFailurePolicy &&
            (
                failurePolicy.didPreserveRendererDrawablePresentationGate == false ||
                failurePolicy.didDescribeCompletionFailureFacts == false ||
                failurePolicy.didDescribeRollbackNoDrawFacts == false ||
                failurePolicy.didDescribeResourceRetentionConcernFacts == false ||
                failurePolicy.didKeepGpuSubmissionFailurePolicyValueOnly == false ||
                failurePolicy.didAvoidGpuCompletionObservation == false ||
                failurePolicy.didAvoidCallbackRegistration == false ||
                failurePolicy.didAvoidTelemetryPublication == false ||
                failurePolicy.shouldDeferRendererGpuSubmissionFailurePolicy ||
                failurePolicy.shouldReportRendererGpuSubmissionFailurePolicyBlocked
            )
        ) ||
        (failurePolicy.didPreserveRendererDrawablePresentationGate &&
            failurePolicy.didPrepareRendererGpuSubmissionFailurePolicy == false) ||
        (failurePolicy.shouldDeferRendererGpuSubmissionFailurePolicy &&
            failurePolicy.shouldReportRendererGpuSubmissionFailurePolicyBlocked)

    if (
        failurePolicy.shouldReportRendererGpuSubmissionFailurePolicyBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoGpuSubmissionReadiness(
            failurePolicy,
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
            true
        )
    }

    if (policyReady) {
        return CjguiInternalRendererNoGpuSubmissionReadiness(
            failurePolicy,
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
            true
        )
    }

    if (readinessDeferred) {
        return CjguiInternalRendererNoGpuSubmissionReadiness(
            failurePolicy,
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
            true
        )
    }

    return CjguiInternalRendererNoGpuSubmissionReadiness(
        failurePolicy,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererCommandSubmissionDraft(
): CjguiInternalRendererNoGpuSubmissionReadiness {
    let noRealDrawableReadiness =
        cjguiInternalExecuteDefaultRendererRealDrawableLifecycleDraft()
    let commandSubmissionIntent =
        cjguiInternalBuildRendererCommandSubmissionIntent(
            noRealDrawableReadiness
        )
    let commitPolicy =
        cjguiInternalBuildRendererCommandBufferCommitPolicy(
            commandSubmissionIntent
        )
    let presentationGate =
        cjguiInternalBuildRendererDrawablePresentationGate(
            commitPolicy
        )
    let failurePolicy =
        cjguiInternalBuildRendererGpuSubmissionFailurePolicy(
            presentationGate
        )
    return cjguiInternalBuildRendererNoGpuSubmissionReadiness(
        failurePolicy
    )
}
