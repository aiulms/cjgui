package cjgui

// Owner: Renderer platform object implementation admission value boundary.
// Truth: only consumes CjguiInternalRendererNoNativeResourceBridgeReadiness and
// records implementation admission, native-handle admission, lifecycle
// admission, teardown failure, and no-platform-object-implementation facts.
// Stop-line: no platform object, native resource handle, pointer-like resource,
// foreign declaration, bridge invocation, lifecycle side effect, work submit,
// render side effect, renderer state mutation, external API surface, or mutable
// module state.
// Same-shape Boundary Brake: this owner adds admission / lifecycle / teardown
// failure vocabulary; it is not a permission wrapper.

struct CjguiInternalRendererPlatformObjectImplementationIntent {
    let noNativeResourceBridgeReadiness: CjguiInternalRendererNoNativeResourceBridgeReadiness
    let didPrepareRendererPlatformObjectImplementationIntent: Bool
    let shouldDeferRendererPlatformObjectImplementationIntent: Bool
    let shouldReportRendererPlatformObjectImplementationIntentBlocked: Bool
    let didPreserveRendererNoNativeResourceBridgeReadiness: Bool
    let didDefineFuturePlatformObjectImplementationIntent: Bool
    let didDescribeNativeHandleAdmissionNeed: Bool
    let didDescribeLifecycleAdmissionNeed: Bool
    let didDescribeTeardownFailureNeed: Bool
    let didKeepPlatformObjectImplementationIntentValueOnly: Bool
    let didAvoidPlatformObjectPermissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        noNativeResourceBridgeReadiness: CjguiInternalRendererNoNativeResourceBridgeReadiness,
        didPrepareRendererPlatformObjectImplementationIntent: Bool,
        shouldDeferRendererPlatformObjectImplementationIntent: Bool,
        shouldReportRendererPlatformObjectImplementationIntentBlocked: Bool,
        didPreserveRendererNoNativeResourceBridgeReadiness: Bool,
        didDefineFuturePlatformObjectImplementationIntent: Bool,
        didDescribeNativeHandleAdmissionNeed: Bool,
        didDescribeLifecycleAdmissionNeed: Bool,
        didDescribeTeardownFailureNeed: Bool,
        didKeepPlatformObjectImplementationIntentValueOnly: Bool,
        didAvoidPlatformObjectPermissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noNativeResourceBridgeReadiness =
            noNativeResourceBridgeReadiness
        this.didPrepareRendererPlatformObjectImplementationIntent =
            didPrepareRendererPlatformObjectImplementationIntent
        this.shouldDeferRendererPlatformObjectImplementationIntent =
            shouldDeferRendererPlatformObjectImplementationIntent
        this.shouldReportRendererPlatformObjectImplementationIntentBlocked =
            shouldReportRendererPlatformObjectImplementationIntentBlocked
        this.didPreserveRendererNoNativeResourceBridgeReadiness =
            didPreserveRendererNoNativeResourceBridgeReadiness
        this.didDefineFuturePlatformObjectImplementationIntent =
            didDefineFuturePlatformObjectImplementationIntent
        this.didDescribeNativeHandleAdmissionNeed =
            didDescribeNativeHandleAdmissionNeed
        this.didDescribeLifecycleAdmissionNeed =
            didDescribeLifecycleAdmissionNeed
        this.didDescribeTeardownFailureNeed =
            didDescribeTeardownFailureNeed
        this.didKeepPlatformObjectImplementationIntentValueOnly =
            didKeepPlatformObjectImplementationIntentValueOnly
        this.didAvoidPlatformObjectPermissionWrapper =
            didAvoidPlatformObjectPermissionWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeHandleAdmissionPolicy {
    let implementationIntent: CjguiInternalRendererPlatformObjectImplementationIntent
    let didPrepareRendererNativeHandleAdmissionPolicy: Bool
    let shouldDeferRendererNativeHandleAdmissionPolicy: Bool
    let shouldReportRendererNativeHandleAdmissionPolicyBlocked: Bool
    let didPreserveRendererPlatformObjectImplementationIntent: Bool
    let didDefineFutureNativeHandleAdmissionPolicy: Bool
    let didConfirmNoNativeResourceHandle: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didConfirmNoForeignResourceToken: Bool
    let didConfirmNoHandleExposure: Bool
    let didKeepNativeHandleAdmissionPolicyValueOnly: Bool
    let didAvoidNativeHandlePermissionWrapper: Bool
    let didAvoidCAbiFfiPermissionWrapper: Bool

    init(
        implementationIntent: CjguiInternalRendererPlatformObjectImplementationIntent,
        didPrepareRendererNativeHandleAdmissionPolicy: Bool,
        shouldDeferRendererNativeHandleAdmissionPolicy: Bool,
        shouldReportRendererNativeHandleAdmissionPolicyBlocked: Bool,
        didPreserveRendererPlatformObjectImplementationIntent: Bool,
        didDefineFutureNativeHandleAdmissionPolicy: Bool,
        didConfirmNoNativeResourceHandle: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didConfirmNoForeignResourceToken: Bool,
        didConfirmNoHandleExposure: Bool,
        didKeepNativeHandleAdmissionPolicyValueOnly: Bool,
        didAvoidNativeHandlePermissionWrapper: Bool,
        didAvoidCAbiFfiPermissionWrapper: Bool
    ) {
        this.implementationIntent = implementationIntent
        this.didPrepareRendererNativeHandleAdmissionPolicy =
            didPrepareRendererNativeHandleAdmissionPolicy
        this.shouldDeferRendererNativeHandleAdmissionPolicy =
            shouldDeferRendererNativeHandleAdmissionPolicy
        this.shouldReportRendererNativeHandleAdmissionPolicyBlocked =
            shouldReportRendererNativeHandleAdmissionPolicyBlocked
        this.didPreserveRendererPlatformObjectImplementationIntent =
            didPreserveRendererPlatformObjectImplementationIntent
        this.didDefineFutureNativeHandleAdmissionPolicy =
            didDefineFutureNativeHandleAdmissionPolicy
        this.didConfirmNoNativeResourceHandle =
            didConfirmNoNativeResourceHandle
        this.didConfirmNoPointerLikeResource =
            didConfirmNoPointerLikeResource
        this.didConfirmNoForeignResourceToken =
            didConfirmNoForeignResourceToken
        this.didConfirmNoHandleExposure = didConfirmNoHandleExposure
        this.didKeepNativeHandleAdmissionPolicyValueOnly =
            didKeepNativeHandleAdmissionPolicyValueOnly
        this.didAvoidNativeHandlePermissionWrapper =
            didAvoidNativeHandlePermissionWrapper
        this.didAvoidCAbiFfiPermissionWrapper =
            didAvoidCAbiFfiPermissionWrapper
    }
}

struct CjguiInternalRendererPlatformObjectLifecycleAdmissionGuard {
    let nativeHandleAdmissionPolicy: CjguiInternalRendererNativeHandleAdmissionPolicy
    let didPrepareRendererPlatformObjectLifecycleAdmissionGuard: Bool
    let shouldDeferRendererPlatformObjectLifecycleAdmissionGuard: Bool
    let shouldReportRendererPlatformObjectLifecycleAdmissionGuardBlocked: Bool
    let didPreserveRendererNativeHandleAdmissionPolicy: Bool
    let didDefineFuturePlatformObjectLifecycleAdmissionGuard: Bool
    let didConfirmNoPlatformObjectCreation: Bool
    let didConfirmNoBridgeCall: Bool
    let didConfirmNoForeignPlatformApiCall: Bool
    let didConfirmNoBackendObject: Bool
    let didKeepPlatformObjectLifecycleAdmissionGuardValueOnly: Bool
    let didAvoidPlatformObjectPermissionWrapper: Bool
    let didAvoidBackendImplementationWrapper: Bool

    init(
        nativeHandleAdmissionPolicy: CjguiInternalRendererNativeHandleAdmissionPolicy,
        didPrepareRendererPlatformObjectLifecycleAdmissionGuard: Bool,
        shouldDeferRendererPlatformObjectLifecycleAdmissionGuard: Bool,
        shouldReportRendererPlatformObjectLifecycleAdmissionGuardBlocked: Bool,
        didPreserveRendererNativeHandleAdmissionPolicy: Bool,
        didDefineFuturePlatformObjectLifecycleAdmissionGuard: Bool,
        didConfirmNoPlatformObjectCreation: Bool,
        didConfirmNoBridgeCall: Bool,
        didConfirmNoForeignPlatformApiCall: Bool,
        didConfirmNoBackendObject: Bool,
        didKeepPlatformObjectLifecycleAdmissionGuardValueOnly: Bool,
        didAvoidPlatformObjectPermissionWrapper: Bool,
        didAvoidBackendImplementationWrapper: Bool
    ) {
        this.nativeHandleAdmissionPolicy = nativeHandleAdmissionPolicy
        this.didPrepareRendererPlatformObjectLifecycleAdmissionGuard =
            didPrepareRendererPlatformObjectLifecycleAdmissionGuard
        this.shouldDeferRendererPlatformObjectLifecycleAdmissionGuard =
            shouldDeferRendererPlatformObjectLifecycleAdmissionGuard
        this.shouldReportRendererPlatformObjectLifecycleAdmissionGuardBlocked =
            shouldReportRendererPlatformObjectLifecycleAdmissionGuardBlocked
        this.didPreserveRendererNativeHandleAdmissionPolicy =
            didPreserveRendererNativeHandleAdmissionPolicy
        this.didDefineFuturePlatformObjectLifecycleAdmissionGuard =
            didDefineFuturePlatformObjectLifecycleAdmissionGuard
        this.didConfirmNoPlatformObjectCreation =
            didConfirmNoPlatformObjectCreation
        this.didConfirmNoBridgeCall = didConfirmNoBridgeCall
        this.didConfirmNoForeignPlatformApiCall =
            didConfirmNoForeignPlatformApiCall
        this.didConfirmNoBackendObject = didConfirmNoBackendObject
        this.didKeepPlatformObjectLifecycleAdmissionGuardValueOnly =
            didKeepPlatformObjectLifecycleAdmissionGuardValueOnly
        this.didAvoidPlatformObjectPermissionWrapper =
            didAvoidPlatformObjectPermissionWrapper
        this.didAvoidBackendImplementationWrapper =
            didAvoidBackendImplementationWrapper
    }
}

struct CjguiInternalRendererPlatformObjectTeardownFailurePolicy {
    let lifecycleAdmissionGuard: CjguiInternalRendererPlatformObjectLifecycleAdmissionGuard
    let didPrepareRendererPlatformObjectTeardownFailurePolicy: Bool
    let shouldDeferRendererPlatformObjectTeardownFailurePolicy: Bool
    let shouldReportRendererPlatformObjectTeardownFailurePolicyBlocked: Bool
    let didPreserveRendererPlatformObjectLifecycleAdmissionGuard: Bool
    let didDefineFuturePlatformObjectTeardownFailurePolicy: Bool
    let didDescribeTeardownOrderingFacts: Bool
    let didDescribeFailureRollbackFacts: Bool
    let didConfirmNoRetainReleaseDestroy: Bool
    let didConfirmNoResourceFinalizationSideEffect: Bool
    let didKeepPlatformObjectTeardownFailurePolicyValueOnly: Bool
    let didAvoidTeardownSideEffect: Bool
    let didAvoidRendererStateMutation: Bool

    init(
        lifecycleAdmissionGuard: CjguiInternalRendererPlatformObjectLifecycleAdmissionGuard,
        didPrepareRendererPlatformObjectTeardownFailurePolicy: Bool,
        shouldDeferRendererPlatformObjectTeardownFailurePolicy: Bool,
        shouldReportRendererPlatformObjectTeardownFailurePolicyBlocked: Bool,
        didPreserveRendererPlatformObjectLifecycleAdmissionGuard: Bool,
        didDefineFuturePlatformObjectTeardownFailurePolicy: Bool,
        didDescribeTeardownOrderingFacts: Bool,
        didDescribeFailureRollbackFacts: Bool,
        didConfirmNoRetainReleaseDestroy: Bool,
        didConfirmNoResourceFinalizationSideEffect: Bool,
        didKeepPlatformObjectTeardownFailurePolicyValueOnly: Bool,
        didAvoidTeardownSideEffect: Bool,
        didAvoidRendererStateMutation: Bool
    ) {
        this.lifecycleAdmissionGuard = lifecycleAdmissionGuard
        this.didPrepareRendererPlatformObjectTeardownFailurePolicy =
            didPrepareRendererPlatformObjectTeardownFailurePolicy
        this.shouldDeferRendererPlatformObjectTeardownFailurePolicy =
            shouldDeferRendererPlatformObjectTeardownFailurePolicy
        this.shouldReportRendererPlatformObjectTeardownFailurePolicyBlocked =
            shouldReportRendererPlatformObjectTeardownFailurePolicyBlocked
        this.didPreserveRendererPlatformObjectLifecycleAdmissionGuard =
            didPreserveRendererPlatformObjectLifecycleAdmissionGuard
        this.didDefineFuturePlatformObjectTeardownFailurePolicy =
            didDefineFuturePlatformObjectTeardownFailurePolicy
        this.didDescribeTeardownOrderingFacts =
            didDescribeTeardownOrderingFacts
        this.didDescribeFailureRollbackFacts =
            didDescribeFailureRollbackFacts
        this.didConfirmNoRetainReleaseDestroy =
            didConfirmNoRetainReleaseDestroy
        this.didConfirmNoResourceFinalizationSideEffect =
            didConfirmNoResourceFinalizationSideEffect
        this.didKeepPlatformObjectTeardownFailurePolicyValueOnly =
            didKeepPlatformObjectTeardownFailurePolicyValueOnly
        this.didAvoidTeardownSideEffect = didAvoidTeardownSideEffect
        this.didAvoidRendererStateMutation =
            didAvoidRendererStateMutation
    }
}

struct CjguiInternalRendererNoPlatformObjectImplementationReadiness {
    let teardownFailurePolicy: CjguiInternalRendererPlatformObjectTeardownFailurePolicy
    let isRendererNoPlatformObjectImplementationReady: Bool
    let canFutureRendererPlatformObjectImplementationBoundaryEvaluate: Bool
    let shouldDeferRendererNoPlatformObjectImplementationReadiness: Bool
    let shouldReportRendererNoPlatformObjectImplementationReadinessBlocked: Bool
    let didSealRendererNoPlatformObjectImplementationReadiness: Bool
    let didPreserveRendererPlatformObjectTeardownFailurePolicy: Bool
    let didKeepNoPlatformObjectImplementationReadinessValueOnly: Bool
    let didConfirmNoPlatformObjectCreation: Bool
    let didConfirmNoNativeResourceHandle: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didConfirmNoForeignResourceToken: Bool
    let didConfirmNoHandleExposure: Bool
    let didConfirmNoBridgeCall: Bool
    let didConfirmNoForeignFunctionDeclaration: Bool
    let didConfirmNoExternalAbiSurface: Bool
    let didConfirmNoRetainReleaseDestroy: Bool
    let didConfirmNoResourceFinalizationSideEffect: Bool
    let didConfirmNoForeignPlatformApiCall: Bool
    let didConfirmNoBackendObject: Bool
    let didConfirmNoWorkSubmit: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoRendererStateMutation: Bool
    let didConfirmNoExternalApiSurface: Bool
    let didAvoidPlatformObjectPermissionWrapper: Bool
    let didAvoidNativeHandlePermissionWrapper: Bool
    let didAvoidCAbiFfiPermissionWrapper: Bool
    let didAvoidDeviceLayerPermissionWrapper: Bool
    let didAvoidBackendImplementationWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidRendererStateWriteWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        teardownFailurePolicy: CjguiInternalRendererPlatformObjectTeardownFailurePolicy,
        isRendererNoPlatformObjectImplementationReady: Bool,
        canFutureRendererPlatformObjectImplementationBoundaryEvaluate: Bool,
        shouldDeferRendererNoPlatformObjectImplementationReadiness: Bool,
        shouldReportRendererNoPlatformObjectImplementationReadinessBlocked: Bool,
        didSealRendererNoPlatformObjectImplementationReadiness: Bool,
        didPreserveRendererPlatformObjectTeardownFailurePolicy: Bool,
        didKeepNoPlatformObjectImplementationReadinessValueOnly: Bool,
        didConfirmNoPlatformObjectCreation: Bool,
        didConfirmNoNativeResourceHandle: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didConfirmNoForeignResourceToken: Bool,
        didConfirmNoHandleExposure: Bool,
        didConfirmNoBridgeCall: Bool,
        didConfirmNoForeignFunctionDeclaration: Bool,
        didConfirmNoExternalAbiSurface: Bool,
        didConfirmNoRetainReleaseDestroy: Bool,
        didConfirmNoResourceFinalizationSideEffect: Bool,
        didConfirmNoForeignPlatformApiCall: Bool,
        didConfirmNoBackendObject: Bool,
        didConfirmNoWorkSubmit: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoRendererStateMutation: Bool,
        didConfirmNoExternalApiSurface: Bool,
        didAvoidPlatformObjectPermissionWrapper: Bool,
        didAvoidNativeHandlePermissionWrapper: Bool,
        didAvoidCAbiFfiPermissionWrapper: Bool,
        didAvoidDeviceLayerPermissionWrapper: Bool,
        didAvoidBackendImplementationWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidRendererStateWriteWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.teardownFailurePolicy = teardownFailurePolicy
        this.isRendererNoPlatformObjectImplementationReady =
            isRendererNoPlatformObjectImplementationReady
        this.canFutureRendererPlatformObjectImplementationBoundaryEvaluate =
            canFutureRendererPlatformObjectImplementationBoundaryEvaluate
        this.shouldDeferRendererNoPlatformObjectImplementationReadiness =
            shouldDeferRendererNoPlatformObjectImplementationReadiness
        this.shouldReportRendererNoPlatformObjectImplementationReadinessBlocked =
            shouldReportRendererNoPlatformObjectImplementationReadinessBlocked
        this.didSealRendererNoPlatformObjectImplementationReadiness =
            didSealRendererNoPlatformObjectImplementationReadiness
        this.didPreserveRendererPlatformObjectTeardownFailurePolicy =
            didPreserveRendererPlatformObjectTeardownFailurePolicy
        this.didKeepNoPlatformObjectImplementationReadinessValueOnly =
            didKeepNoPlatformObjectImplementationReadinessValueOnly
        this.didConfirmNoPlatformObjectCreation =
            didConfirmNoPlatformObjectCreation
        this.didConfirmNoNativeResourceHandle =
            didConfirmNoNativeResourceHandle
        this.didConfirmNoPointerLikeResource =
            didConfirmNoPointerLikeResource
        this.didConfirmNoForeignResourceToken =
            didConfirmNoForeignResourceToken
        this.didConfirmNoHandleExposure = didConfirmNoHandleExposure
        this.didConfirmNoBridgeCall = didConfirmNoBridgeCall
        this.didConfirmNoForeignFunctionDeclaration =
            didConfirmNoForeignFunctionDeclaration
        this.didConfirmNoExternalAbiSurface =
            didConfirmNoExternalAbiSurface
        this.didConfirmNoRetainReleaseDestroy =
            didConfirmNoRetainReleaseDestroy
        this.didConfirmNoResourceFinalizationSideEffect =
            didConfirmNoResourceFinalizationSideEffect
        this.didConfirmNoForeignPlatformApiCall =
            didConfirmNoForeignPlatformApiCall
        this.didConfirmNoBackendObject = didConfirmNoBackendObject
        this.didConfirmNoWorkSubmit = didConfirmNoWorkSubmit
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoRendererStateMutation =
            didConfirmNoRendererStateMutation
        this.didConfirmNoExternalApiSurface =
            didConfirmNoExternalApiSurface
        this.didAvoidPlatformObjectPermissionWrapper =
            didAvoidPlatformObjectPermissionWrapper
        this.didAvoidNativeHandlePermissionWrapper =
            didAvoidNativeHandlePermissionWrapper
        this.didAvoidCAbiFfiPermissionWrapper =
            didAvoidCAbiFfiPermissionWrapper
        this.didAvoidDeviceLayerPermissionWrapper =
            didAvoidDeviceLayerPermissionWrapper
        this.didAvoidBackendImplementationWrapper =
            didAvoidBackendImplementationWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidRenderPermissionWrapper =
            didAvoidRenderPermissionWrapper
        this.didAvoidRendererStateWriteWrapper =
            didAvoidRendererStateWriteWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererPlatformObjectImplementationIntent(
    noNativeResourceBridgeReadiness: CjguiInternalRendererNoNativeResourceBridgeReadiness
): CjguiInternalRendererPlatformObjectImplementationIntent {
    let noNativeResourceBridge =
        noNativeResourceBridgeReadiness.isRendererNoNativeResourceBridgeReady &&
        noNativeResourceBridgeReadiness.canFutureRendererNativeResourceBridgeBoundaryEvaluate &&
        noNativeResourceBridgeReadiness.didSealRendererNoNativeResourceBridgeReadiness &&
        noNativeResourceBridgeReadiness.didPreserveRendererNativeTeardownContractPolicy &&
        noNativeResourceBridgeReadiness.didKeepNoNativeResourceBridgeReadinessValueOnly &&
        noNativeResourceBridgeReadiness.didConfirmNoNativeResourceHandle &&
        noNativeResourceBridgeReadiness.didConfirmNoPointerLikeResource &&
        noNativeResourceBridgeReadiness.didConfirmNoForeignResourceToken &&
        noNativeResourceBridgeReadiness.didConfirmNoHandleExposure &&
        noNativeResourceBridgeReadiness.didConfirmNoBridgeCall &&
        noNativeResourceBridgeReadiness.didConfirmNoForeignFunctionDeclaration &&
        noNativeResourceBridgeReadiness.didConfirmNoExternalAbiSurface &&
        noNativeResourceBridgeReadiness.didConfirmNoResourceFinalizationSideEffect &&
        noNativeResourceBridgeReadiness.didConfirmNoBridgeSmokeHarnessEntryChange &&
        noNativeResourceBridgeReadiness.didConfirmNoWorkSubmit &&
        noNativeResourceBridgeReadiness.didConfirmNoRenderExecution &&
        noNativeResourceBridgeReadiness.didConfirmNoRendererStateMutation &&
        noNativeResourceBridgeReadiness.didConfirmNoExternalApiSurface &&
        noNativeResourceBridgeReadiness.didAvoidNativeBridgePermissionWrapper &&
        noNativeResourceBridgeReadiness.didAvoidNativeHandlePermissionWrapper &&
        noNativeResourceBridgeReadiness.didAvoidPlatformObjectPermissionWrapper &&
        noNativeResourceBridgeReadiness.didAvoidDeviceLayerPermissionWrapper &&
        noNativeResourceBridgeReadiness.didAvoidBackendImplementationWrapper &&
        noNativeResourceBridgeReadiness.didAvoidGpuSubmissionWrapper &&
        noNativeResourceBridgeReadiness.didAvoidRenderPermissionWrapper &&
        noNativeResourceBridgeReadiness.didAvoidRendererStateWriteWrapper &&
        noNativeResourceBridgeReadiness.didAvoidReceiptRecordPublication &&
        noNativeResourceBridgeReadiness.didAvoidThinWrapper &&
        noNativeResourceBridgeReadiness.didStayFullRebuildOnly &&
        noNativeResourceBridgeReadiness.shouldDeferRendererNoNativeResourceBridgeReadiness == false &&
        noNativeResourceBridgeReadiness.shouldReportRendererNoNativeResourceBridgeReadinessBlocked == false
    let intentDeferred =
        noNativeResourceBridgeReadiness.isRendererNoNativeResourceBridgeReady == false &&
        noNativeResourceBridgeReadiness.canFutureRendererNativeResourceBridgeBoundaryEvaluate == false &&
        noNativeResourceBridgeReadiness.shouldDeferRendererNoNativeResourceBridgeReadiness &&
        noNativeResourceBridgeReadiness.shouldReportRendererNoNativeResourceBridgeReadinessBlocked == false
    let intentInconsistent = (
        noNativeResourceBridgeReadiness.isRendererNoNativeResourceBridgeReady &&
            (
                noNativeResourceBridgeReadiness.canFutureRendererNativeResourceBridgeBoundaryEvaluate == false ||
                noNativeResourceBridgeReadiness.didSealRendererNoNativeResourceBridgeReadiness == false ||
                noNativeResourceBridgeReadiness.didPreserveRendererNativeTeardownContractPolicy == false ||
                noNativeResourceBridgeReadiness.didKeepNoNativeResourceBridgeReadinessValueOnly == false ||
                noNativeResourceBridgeReadiness.didConfirmNoNativeResourceHandle == false ||
                noNativeResourceBridgeReadiness.didConfirmNoPointerLikeResource == false ||
                noNativeResourceBridgeReadiness.didConfirmNoForeignResourceToken == false ||
                noNativeResourceBridgeReadiness.didConfirmNoHandleExposure == false ||
                noNativeResourceBridgeReadiness.didConfirmNoBridgeCall == false ||
                noNativeResourceBridgeReadiness.didConfirmNoForeignFunctionDeclaration == false ||
                noNativeResourceBridgeReadiness.didConfirmNoExternalAbiSurface == false ||
                noNativeResourceBridgeReadiness.didConfirmNoResourceFinalizationSideEffect == false ||
                noNativeResourceBridgeReadiness.didConfirmNoBridgeSmokeHarnessEntryChange == false ||
                noNativeResourceBridgeReadiness.didConfirmNoWorkSubmit == false ||
                noNativeResourceBridgeReadiness.didConfirmNoRenderExecution == false ||
                noNativeResourceBridgeReadiness.didConfirmNoRendererStateMutation == false ||
                noNativeResourceBridgeReadiness.didConfirmNoExternalApiSurface == false ||
                noNativeResourceBridgeReadiness.didAvoidNativeBridgePermissionWrapper == false ||
                noNativeResourceBridgeReadiness.didAvoidNativeHandlePermissionWrapper == false ||
                noNativeResourceBridgeReadiness.didAvoidPlatformObjectPermissionWrapper == false ||
                noNativeResourceBridgeReadiness.didAvoidDeviceLayerPermissionWrapper == false ||
                noNativeResourceBridgeReadiness.didAvoidBackendImplementationWrapper == false ||
                noNativeResourceBridgeReadiness.didAvoidGpuSubmissionWrapper == false ||
                noNativeResourceBridgeReadiness.didAvoidRenderPermissionWrapper == false ||
                noNativeResourceBridgeReadiness.didAvoidRendererStateWriteWrapper == false ||
                noNativeResourceBridgeReadiness.didAvoidReceiptRecordPublication == false ||
                noNativeResourceBridgeReadiness.didAvoidThinWrapper == false ||
                noNativeResourceBridgeReadiness.didStayFullRebuildOnly == false ||
                noNativeResourceBridgeReadiness.shouldDeferRendererNoNativeResourceBridgeReadiness ||
                noNativeResourceBridgeReadiness.shouldReportRendererNoNativeResourceBridgeReadinessBlocked
            )
        ) ||
        (
            noNativeResourceBridgeReadiness.canFutureRendererNativeResourceBridgeBoundaryEvaluate &&
            noNativeResourceBridgeReadiness.isRendererNoNativeResourceBridgeReady == false
        ) ||
        (
            noNativeResourceBridgeReadiness.shouldDeferRendererNoNativeResourceBridgeReadiness &&
            noNativeResourceBridgeReadiness.shouldReportRendererNoNativeResourceBridgeReadinessBlocked
        )

    if (
        noNativeResourceBridgeReadiness.shouldReportRendererNoNativeResourceBridgeReadinessBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererPlatformObjectImplementationIntent(
            noNativeResourceBridgeReadiness,
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

    if (noNativeResourceBridge) {
        return CjguiInternalRendererPlatformObjectImplementationIntent(
            noNativeResourceBridgeReadiness,
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
        return CjguiInternalRendererPlatformObjectImplementationIntent(
            noNativeResourceBridgeReadiness,
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

    return CjguiInternalRendererPlatformObjectImplementationIntent(
        noNativeResourceBridgeReadiness,
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

func cjguiInternalBuildRendererNativeHandleAdmissionPolicy(
    implementationIntent: CjguiInternalRendererPlatformObjectImplementationIntent
): CjguiInternalRendererNativeHandleAdmissionPolicy {
    let intentReady =
        implementationIntent.didPrepareRendererPlatformObjectImplementationIntent &&
        implementationIntent.didPreserveRendererNoNativeResourceBridgeReadiness &&
        implementationIntent.didDefineFuturePlatformObjectImplementationIntent &&
        implementationIntent.didDescribeNativeHandleAdmissionNeed &&
        implementationIntent.didDescribeLifecycleAdmissionNeed &&
        implementationIntent.didDescribeTeardownFailureNeed &&
        implementationIntent.didKeepPlatformObjectImplementationIntentValueOnly &&
        implementationIntent.didAvoidPlatformObjectPermissionWrapper &&
        implementationIntent.didAvoidReceiptRecordPublication &&
        implementationIntent.didAvoidThinWrapper &&
        implementationIntent.shouldDeferRendererPlatformObjectImplementationIntent == false &&
        implementationIntent.shouldReportRendererPlatformObjectImplementationIntentBlocked == false
    let admissionDeferred =
        implementationIntent.didPrepareRendererPlatformObjectImplementationIntent == false &&
        implementationIntent.shouldDeferRendererPlatformObjectImplementationIntent &&
        implementationIntent.shouldReportRendererPlatformObjectImplementationIntentBlocked == false
    let admissionInconsistent = (
        implementationIntent.didPrepareRendererPlatformObjectImplementationIntent &&
            (
                implementationIntent.didPreserveRendererNoNativeResourceBridgeReadiness == false ||
                implementationIntent.didDefineFuturePlatformObjectImplementationIntent == false ||
                implementationIntent.didDescribeNativeHandleAdmissionNeed == false ||
                implementationIntent.didDescribeLifecycleAdmissionNeed == false ||
                implementationIntent.didDescribeTeardownFailureNeed == false ||
                implementationIntent.didKeepPlatformObjectImplementationIntentValueOnly == false ||
                implementationIntent.didAvoidPlatformObjectPermissionWrapper == false ||
                implementationIntent.didAvoidReceiptRecordPublication == false ||
                implementationIntent.didAvoidThinWrapper == false ||
                implementationIntent.shouldDeferRendererPlatformObjectImplementationIntent ||
                implementationIntent.shouldReportRendererPlatformObjectImplementationIntentBlocked
            )
        ) ||
        (
            implementationIntent.didPreserveRendererNoNativeResourceBridgeReadiness &&
            implementationIntent.didPrepareRendererPlatformObjectImplementationIntent == false
        ) ||
        (
            implementationIntent.shouldDeferRendererPlatformObjectImplementationIntent &&
            implementationIntent.shouldReportRendererPlatformObjectImplementationIntentBlocked
        )

    if (
        implementationIntent.shouldReportRendererPlatformObjectImplementationIntentBlocked ||
        admissionInconsistent
    ) {
        return CjguiInternalRendererNativeHandleAdmissionPolicy(
            implementationIntent,
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
            true
        )
    }

    if (intentReady) {
        return CjguiInternalRendererNativeHandleAdmissionPolicy(
            implementationIntent,
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

    if (admissionDeferred) {
        return CjguiInternalRendererNativeHandleAdmissionPolicy(
            implementationIntent,
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
            true
        )
    }

    return CjguiInternalRendererNativeHandleAdmissionPolicy(
        implementationIntent,
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
        true
    )
}

func cjguiInternalBuildRendererPlatformObjectLifecycleAdmissionGuard(
    nativeHandleAdmissionPolicy: CjguiInternalRendererNativeHandleAdmissionPolicy
): CjguiInternalRendererPlatformObjectLifecycleAdmissionGuard {
    let admissionReady =
        nativeHandleAdmissionPolicy.didPrepareRendererNativeHandleAdmissionPolicy &&
        nativeHandleAdmissionPolicy.didPreserveRendererPlatformObjectImplementationIntent &&
        nativeHandleAdmissionPolicy.didDefineFutureNativeHandleAdmissionPolicy &&
        nativeHandleAdmissionPolicy.didConfirmNoNativeResourceHandle &&
        nativeHandleAdmissionPolicy.didConfirmNoPointerLikeResource &&
        nativeHandleAdmissionPolicy.didConfirmNoForeignResourceToken &&
        nativeHandleAdmissionPolicy.didConfirmNoHandleExposure &&
        nativeHandleAdmissionPolicy.didKeepNativeHandleAdmissionPolicyValueOnly &&
        nativeHandleAdmissionPolicy.didAvoidNativeHandlePermissionWrapper &&
        nativeHandleAdmissionPolicy.didAvoidCAbiFfiPermissionWrapper &&
        nativeHandleAdmissionPolicy.shouldDeferRendererNativeHandleAdmissionPolicy == false &&
        nativeHandleAdmissionPolicy.shouldReportRendererNativeHandleAdmissionPolicyBlocked == false
    let lifecycleDeferred =
        nativeHandleAdmissionPolicy.didPrepareRendererNativeHandleAdmissionPolicy == false &&
        nativeHandleAdmissionPolicy.shouldDeferRendererNativeHandleAdmissionPolicy &&
        nativeHandleAdmissionPolicy.shouldReportRendererNativeHandleAdmissionPolicyBlocked == false
    let lifecycleInconsistent = (
        nativeHandleAdmissionPolicy.didPrepareRendererNativeHandleAdmissionPolicy &&
            (
                nativeHandleAdmissionPolicy.didPreserveRendererPlatformObjectImplementationIntent == false ||
                nativeHandleAdmissionPolicy.didDefineFutureNativeHandleAdmissionPolicy == false ||
                nativeHandleAdmissionPolicy.didConfirmNoNativeResourceHandle == false ||
                nativeHandleAdmissionPolicy.didConfirmNoPointerLikeResource == false ||
                nativeHandleAdmissionPolicy.didConfirmNoForeignResourceToken == false ||
                nativeHandleAdmissionPolicy.didConfirmNoHandleExposure == false ||
                nativeHandleAdmissionPolicy.didKeepNativeHandleAdmissionPolicyValueOnly == false ||
                nativeHandleAdmissionPolicy.didAvoidNativeHandlePermissionWrapper == false ||
                nativeHandleAdmissionPolicy.didAvoidCAbiFfiPermissionWrapper == false ||
                nativeHandleAdmissionPolicy.shouldDeferRendererNativeHandleAdmissionPolicy ||
                nativeHandleAdmissionPolicy.shouldReportRendererNativeHandleAdmissionPolicyBlocked
            )
        ) ||
        (
            nativeHandleAdmissionPolicy.didPreserveRendererPlatformObjectImplementationIntent &&
            nativeHandleAdmissionPolicy.didPrepareRendererNativeHandleAdmissionPolicy == false
        ) ||
        (
            nativeHandleAdmissionPolicy.shouldDeferRendererNativeHandleAdmissionPolicy &&
            nativeHandleAdmissionPolicy.shouldReportRendererNativeHandleAdmissionPolicyBlocked
        )

    if (
        nativeHandleAdmissionPolicy.shouldReportRendererNativeHandleAdmissionPolicyBlocked ||
        lifecycleInconsistent
    ) {
        return CjguiInternalRendererPlatformObjectLifecycleAdmissionGuard(
            nativeHandleAdmissionPolicy,
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
            true
        )
    }

    if (admissionReady) {
        return CjguiInternalRendererPlatformObjectLifecycleAdmissionGuard(
            nativeHandleAdmissionPolicy,
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

    if (lifecycleDeferred) {
        return CjguiInternalRendererPlatformObjectLifecycleAdmissionGuard(
            nativeHandleAdmissionPolicy,
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
            true
        )
    }

    return CjguiInternalRendererPlatformObjectLifecycleAdmissionGuard(
        nativeHandleAdmissionPolicy,
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
        true
    )
}

func cjguiInternalBuildRendererPlatformObjectTeardownFailurePolicy(
    lifecycleAdmissionGuard: CjguiInternalRendererPlatformObjectLifecycleAdmissionGuard
): CjguiInternalRendererPlatformObjectTeardownFailurePolicy {
    let lifecycleReady =
        lifecycleAdmissionGuard.didPrepareRendererPlatformObjectLifecycleAdmissionGuard &&
        lifecycleAdmissionGuard.didPreserveRendererNativeHandleAdmissionPolicy &&
        lifecycleAdmissionGuard.didDefineFuturePlatformObjectLifecycleAdmissionGuard &&
        lifecycleAdmissionGuard.didConfirmNoPlatformObjectCreation &&
        lifecycleAdmissionGuard.didConfirmNoBridgeCall &&
        lifecycleAdmissionGuard.didConfirmNoForeignPlatformApiCall &&
        lifecycleAdmissionGuard.didConfirmNoBackendObject &&
        lifecycleAdmissionGuard.didKeepPlatformObjectLifecycleAdmissionGuardValueOnly &&
        lifecycleAdmissionGuard.didAvoidPlatformObjectPermissionWrapper &&
        lifecycleAdmissionGuard.didAvoidBackendImplementationWrapper &&
        lifecycleAdmissionGuard.shouldDeferRendererPlatformObjectLifecycleAdmissionGuard == false &&
        lifecycleAdmissionGuard.shouldReportRendererPlatformObjectLifecycleAdmissionGuardBlocked == false
    let teardownDeferred =
        lifecycleAdmissionGuard.didPrepareRendererPlatformObjectLifecycleAdmissionGuard == false &&
        lifecycleAdmissionGuard.shouldDeferRendererPlatformObjectLifecycleAdmissionGuard &&
        lifecycleAdmissionGuard.shouldReportRendererPlatformObjectLifecycleAdmissionGuardBlocked == false
    let teardownInconsistent = (
        lifecycleAdmissionGuard.didPrepareRendererPlatformObjectLifecycleAdmissionGuard &&
            (
                lifecycleAdmissionGuard.didPreserveRendererNativeHandleAdmissionPolicy == false ||
                lifecycleAdmissionGuard.didDefineFuturePlatformObjectLifecycleAdmissionGuard == false ||
                lifecycleAdmissionGuard.didConfirmNoPlatformObjectCreation == false ||
                lifecycleAdmissionGuard.didConfirmNoBridgeCall == false ||
                lifecycleAdmissionGuard.didConfirmNoForeignPlatformApiCall == false ||
                lifecycleAdmissionGuard.didConfirmNoBackendObject == false ||
                lifecycleAdmissionGuard.didKeepPlatformObjectLifecycleAdmissionGuardValueOnly == false ||
                lifecycleAdmissionGuard.didAvoidPlatformObjectPermissionWrapper == false ||
                lifecycleAdmissionGuard.didAvoidBackendImplementationWrapper == false ||
                lifecycleAdmissionGuard.shouldDeferRendererPlatformObjectLifecycleAdmissionGuard ||
                lifecycleAdmissionGuard.shouldReportRendererPlatformObjectLifecycleAdmissionGuardBlocked
            )
        ) ||
        (
            lifecycleAdmissionGuard.didPreserveRendererNativeHandleAdmissionPolicy &&
            lifecycleAdmissionGuard.didPrepareRendererPlatformObjectLifecycleAdmissionGuard == false
        ) ||
        (
            lifecycleAdmissionGuard.shouldDeferRendererPlatformObjectLifecycleAdmissionGuard &&
            lifecycleAdmissionGuard.shouldReportRendererPlatformObjectLifecycleAdmissionGuardBlocked
        )

    if (
        lifecycleAdmissionGuard.shouldReportRendererPlatformObjectLifecycleAdmissionGuardBlocked ||
        teardownInconsistent
    ) {
        return CjguiInternalRendererPlatformObjectTeardownFailurePolicy(
            lifecycleAdmissionGuard,
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
            true
        )
    }

    if (lifecycleReady) {
        return CjguiInternalRendererPlatformObjectTeardownFailurePolicy(
            lifecycleAdmissionGuard,
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

    if (teardownDeferred) {
        return CjguiInternalRendererPlatformObjectTeardownFailurePolicy(
            lifecycleAdmissionGuard,
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
            true
        )
    }

    return CjguiInternalRendererPlatformObjectTeardownFailurePolicy(
        lifecycleAdmissionGuard,
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
        true
    )
}

func cjguiInternalBuildRendererNoPlatformObjectImplementationReadiness(
    teardownFailurePolicy: CjguiInternalRendererPlatformObjectTeardownFailurePolicy
): CjguiInternalRendererNoPlatformObjectImplementationReadiness {
    let teardownReady =
        teardownFailurePolicy.didPrepareRendererPlatformObjectTeardownFailurePolicy &&
        teardownFailurePolicy.didPreserveRendererPlatformObjectLifecycleAdmissionGuard &&
        teardownFailurePolicy.didDefineFuturePlatformObjectTeardownFailurePolicy &&
        teardownFailurePolicy.didDescribeTeardownOrderingFacts &&
        teardownFailurePolicy.didDescribeFailureRollbackFacts &&
        teardownFailurePolicy.didConfirmNoRetainReleaseDestroy &&
        teardownFailurePolicy.didConfirmNoResourceFinalizationSideEffect &&
        teardownFailurePolicy.didKeepPlatformObjectTeardownFailurePolicyValueOnly &&
        teardownFailurePolicy.didAvoidTeardownSideEffect &&
        teardownFailurePolicy.didAvoidRendererStateMutation &&
        teardownFailurePolicy.shouldDeferRendererPlatformObjectTeardownFailurePolicy == false &&
        teardownFailurePolicy.shouldReportRendererPlatformObjectTeardownFailurePolicyBlocked == false
    let readinessDeferred =
        teardownFailurePolicy.didPrepareRendererPlatformObjectTeardownFailurePolicy == false &&
        teardownFailurePolicy.shouldDeferRendererPlatformObjectTeardownFailurePolicy &&
        teardownFailurePolicy.shouldReportRendererPlatformObjectTeardownFailurePolicyBlocked == false
    let readinessInconsistent = (
        teardownFailurePolicy.didPrepareRendererPlatformObjectTeardownFailurePolicy &&
            (
                teardownFailurePolicy.didPreserveRendererPlatformObjectLifecycleAdmissionGuard == false ||
                teardownFailurePolicy.didDefineFuturePlatformObjectTeardownFailurePolicy == false ||
                teardownFailurePolicy.didDescribeTeardownOrderingFacts == false ||
                teardownFailurePolicy.didDescribeFailureRollbackFacts == false ||
                teardownFailurePolicy.didConfirmNoRetainReleaseDestroy == false ||
                teardownFailurePolicy.didConfirmNoResourceFinalizationSideEffect == false ||
                teardownFailurePolicy.didKeepPlatformObjectTeardownFailurePolicyValueOnly == false ||
                teardownFailurePolicy.didAvoidTeardownSideEffect == false ||
                teardownFailurePolicy.didAvoidRendererStateMutation == false ||
                teardownFailurePolicy.shouldDeferRendererPlatformObjectTeardownFailurePolicy ||
                teardownFailurePolicy.shouldReportRendererPlatformObjectTeardownFailurePolicyBlocked
            )
        ) ||
        (
            teardownFailurePolicy.didPreserveRendererPlatformObjectLifecycleAdmissionGuard &&
            teardownFailurePolicy.didPrepareRendererPlatformObjectTeardownFailurePolicy == false
        ) ||
        (
            teardownFailurePolicy.shouldDeferRendererPlatformObjectTeardownFailurePolicy &&
            teardownFailurePolicy.shouldReportRendererPlatformObjectTeardownFailurePolicyBlocked
        )

    if (
        teardownFailurePolicy.shouldReportRendererPlatformObjectTeardownFailurePolicyBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoPlatformObjectImplementationReadiness(
            teardownFailurePolicy,
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
        return CjguiInternalRendererNoPlatformObjectImplementationReadiness(
            teardownFailurePolicy,
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
        return CjguiInternalRendererNoPlatformObjectImplementationReadiness(
            teardownFailurePolicy,
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

    return CjguiInternalRendererNoPlatformObjectImplementationReadiness(
        teardownFailurePolicy,
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

func cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft():
    CjguiInternalRendererNoPlatformObjectImplementationReadiness {
    let noNativeResourceBridgeReadiness =
        cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()
    let implementationIntent =
        cjguiInternalBuildRendererPlatformObjectImplementationIntent(
            noNativeResourceBridgeReadiness
        )
    let nativeHandleAdmissionPolicy =
        cjguiInternalBuildRendererNativeHandleAdmissionPolicy(
            implementationIntent
        )
    let lifecycleAdmissionGuard =
        cjguiInternalBuildRendererPlatformObjectLifecycleAdmissionGuard(
            nativeHandleAdmissionPolicy
        )
    let teardownFailurePolicy =
        cjguiInternalBuildRendererPlatformObjectTeardownFailurePolicy(
            lifecycleAdmissionGuard
        )
    return cjguiInternalBuildRendererNoPlatformObjectImplementationReadiness(
        teardownFailurePolicy
    )
}
