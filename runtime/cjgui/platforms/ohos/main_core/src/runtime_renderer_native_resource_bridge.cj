package cjgui

// Owner: Renderer native resource bridge value boundary.
// Truth: only consumes CjguiInternalRendererNoResourceBackendShellReadiness and
// records bridge intent, handle confinement, bridge admission, teardown
// contract, and no-native-resource-bridge readiness facts.
// Stop-line: no native resource handle, pointer-like resource, foreign call,
// finalization side effect, work submit, render side effect, renderer state
// mutation, external ABI surface, external API surface, or mutable module state.
// Same-shape Boundary Brake: this owner adds handle confinement / bridge
// admission / teardown contract vocabulary; it is not a permission wrapper.

struct CjguiInternalRendererNativeResourceBridgeIntent {
    let noResourceBackendShellReadiness: CjguiInternalRendererNoResourceBackendShellReadiness
    let didPrepareRendererNativeResourceBridgeIntent: Bool
    let shouldDeferRendererNativeResourceBridgeIntent: Bool
    let shouldReportRendererNativeResourceBridgeIntentBlocked: Bool
    let didPreserveRendererNoResourceBackendShellReadiness: Bool
    let didDefineFutureNativeResourceBridgeIntent: Bool
    let didDescribeHandleConfinementNeed: Bool
    let didDescribeBridgeAdmissionNeed: Bool
    let didDescribeNativeTeardownContractNeed: Bool
    let didKeepNativeResourceBridgeIntentValueOnly: Bool
    let didAvoidNativeBridgePermissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        noResourceBackendShellReadiness: CjguiInternalRendererNoResourceBackendShellReadiness,
        didPrepareRendererNativeResourceBridgeIntent: Bool,
        shouldDeferRendererNativeResourceBridgeIntent: Bool,
        shouldReportRendererNativeResourceBridgeIntentBlocked: Bool,
        didPreserveRendererNoResourceBackendShellReadiness: Bool,
        didDefineFutureNativeResourceBridgeIntent: Bool,
        didDescribeHandleConfinementNeed: Bool,
        didDescribeBridgeAdmissionNeed: Bool,
        didDescribeNativeTeardownContractNeed: Bool,
        didKeepNativeResourceBridgeIntentValueOnly: Bool,
        didAvoidNativeBridgePermissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noResourceBackendShellReadiness =
            noResourceBackendShellReadiness
        this.didPrepareRendererNativeResourceBridgeIntent =
            didPrepareRendererNativeResourceBridgeIntent
        this.shouldDeferRendererNativeResourceBridgeIntent =
            shouldDeferRendererNativeResourceBridgeIntent
        this.shouldReportRendererNativeResourceBridgeIntentBlocked =
            shouldReportRendererNativeResourceBridgeIntentBlocked
        this.didPreserveRendererNoResourceBackendShellReadiness =
            didPreserveRendererNoResourceBackendShellReadiness
        this.didDefineFutureNativeResourceBridgeIntent =
            didDefineFutureNativeResourceBridgeIntent
        this.didDescribeHandleConfinementNeed =
            didDescribeHandleConfinementNeed
        this.didDescribeBridgeAdmissionNeed =
            didDescribeBridgeAdmissionNeed
        this.didDescribeNativeTeardownContractNeed =
            didDescribeNativeTeardownContractNeed
        this.didKeepNativeResourceBridgeIntentValueOnly =
            didKeepNativeResourceBridgeIntentValueOnly
        this.didAvoidNativeBridgePermissionWrapper =
            didAvoidNativeBridgePermissionWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeHandleConfinementPolicy {
    let nativeResourceBridgeIntent: CjguiInternalRendererNativeResourceBridgeIntent
    let didPrepareRendererNativeHandleConfinementPolicy: Bool
    let shouldDeferRendererNativeHandleConfinementPolicy: Bool
    let shouldReportRendererNativeHandleConfinementPolicyBlocked: Bool
    let didPreserveRendererNativeResourceBridgeIntent: Bool
    let didDefineFutureNativeHandleConfinementPolicy: Bool
    let didConfirmNoNativeResourceHandle: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didConfirmNoForeignResourceToken: Bool
    let didConfirmNoHandleExposure: Bool
    let didKeepNativeHandleConfinementPolicyValueOnly: Bool
    let didAvoidNativeHandlePermissionWrapper: Bool
    let didAvoidPlatformObjectPermissionWrapper: Bool

    init(
        nativeResourceBridgeIntent: CjguiInternalRendererNativeResourceBridgeIntent,
        didPrepareRendererNativeHandleConfinementPolicy: Bool,
        shouldDeferRendererNativeHandleConfinementPolicy: Bool,
        shouldReportRendererNativeHandleConfinementPolicyBlocked: Bool,
        didPreserveRendererNativeResourceBridgeIntent: Bool,
        didDefineFutureNativeHandleConfinementPolicy: Bool,
        didConfirmNoNativeResourceHandle: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didConfirmNoForeignResourceToken: Bool,
        didConfirmNoHandleExposure: Bool,
        didKeepNativeHandleConfinementPolicyValueOnly: Bool,
        didAvoidNativeHandlePermissionWrapper: Bool,
        didAvoidPlatformObjectPermissionWrapper: Bool
    ) {
        this.nativeResourceBridgeIntent = nativeResourceBridgeIntent
        this.didPrepareRendererNativeHandleConfinementPolicy =
            didPrepareRendererNativeHandleConfinementPolicy
        this.shouldDeferRendererNativeHandleConfinementPolicy =
            shouldDeferRendererNativeHandleConfinementPolicy
        this.shouldReportRendererNativeHandleConfinementPolicyBlocked =
            shouldReportRendererNativeHandleConfinementPolicyBlocked
        this.didPreserveRendererNativeResourceBridgeIntent =
            didPreserveRendererNativeResourceBridgeIntent
        this.didDefineFutureNativeHandleConfinementPolicy =
            didDefineFutureNativeHandleConfinementPolicy
        this.didConfirmNoNativeResourceHandle =
            didConfirmNoNativeResourceHandle
        this.didConfirmNoPointerLikeResource =
            didConfirmNoPointerLikeResource
        this.didConfirmNoForeignResourceToken =
            didConfirmNoForeignResourceToken
        this.didConfirmNoHandleExposure = didConfirmNoHandleExposure
        this.didKeepNativeHandleConfinementPolicyValueOnly =
            didKeepNativeHandleConfinementPolicyValueOnly
        this.didAvoidNativeHandlePermissionWrapper =
            didAvoidNativeHandlePermissionWrapper
        this.didAvoidPlatformObjectPermissionWrapper =
            didAvoidPlatformObjectPermissionWrapper
    }
}

struct CjguiInternalRendererBridgeCallAdmissionGuard {
    let nativeHandleConfinementPolicy: CjguiInternalRendererNativeHandleConfinementPolicy
    let didPrepareRendererBridgeCallAdmissionGuard: Bool
    let shouldDeferRendererBridgeCallAdmissionGuard: Bool
    let shouldReportRendererBridgeCallAdmissionGuardBlocked: Bool
    let didPreserveRendererNativeHandleConfinementPolicy: Bool
    let didDefineFutureBridgeCallAdmissionGuard: Bool
    let didConfirmNoBridgeCall: Bool
    let didConfirmNoForeignFunctionDeclaration: Bool
    let didConfirmNoExternalAbiSurface: Bool
    let didConfirmNoForeignPlatformApiCall: Bool
    let didKeepBridgeCallAdmissionGuardValueOnly: Bool
    let didAvoidBridgePermissionWrapper: Bool
    let didAvoidBackendImplementationWrapper: Bool

    init(
        nativeHandleConfinementPolicy: CjguiInternalRendererNativeHandleConfinementPolicy,
        didPrepareRendererBridgeCallAdmissionGuard: Bool,
        shouldDeferRendererBridgeCallAdmissionGuard: Bool,
        shouldReportRendererBridgeCallAdmissionGuardBlocked: Bool,
        didPreserveRendererNativeHandleConfinementPolicy: Bool,
        didDefineFutureBridgeCallAdmissionGuard: Bool,
        didConfirmNoBridgeCall: Bool,
        didConfirmNoForeignFunctionDeclaration: Bool,
        didConfirmNoExternalAbiSurface: Bool,
        didConfirmNoForeignPlatformApiCall: Bool,
        didKeepBridgeCallAdmissionGuardValueOnly: Bool,
        didAvoidBridgePermissionWrapper: Bool,
        didAvoidBackendImplementationWrapper: Bool
    ) {
        this.nativeHandleConfinementPolicy =
            nativeHandleConfinementPolicy
        this.didPrepareRendererBridgeCallAdmissionGuard =
            didPrepareRendererBridgeCallAdmissionGuard
        this.shouldDeferRendererBridgeCallAdmissionGuard =
            shouldDeferRendererBridgeCallAdmissionGuard
        this.shouldReportRendererBridgeCallAdmissionGuardBlocked =
            shouldReportRendererBridgeCallAdmissionGuardBlocked
        this.didPreserveRendererNativeHandleConfinementPolicy =
            didPreserveRendererNativeHandleConfinementPolicy
        this.didDefineFutureBridgeCallAdmissionGuard =
            didDefineFutureBridgeCallAdmissionGuard
        this.didConfirmNoBridgeCall = didConfirmNoBridgeCall
        this.didConfirmNoForeignFunctionDeclaration =
            didConfirmNoForeignFunctionDeclaration
        this.didConfirmNoExternalAbiSurface =
            didConfirmNoExternalAbiSurface
        this.didConfirmNoForeignPlatformApiCall =
            didConfirmNoForeignPlatformApiCall
        this.didKeepBridgeCallAdmissionGuardValueOnly =
            didKeepBridgeCallAdmissionGuardValueOnly
        this.didAvoidBridgePermissionWrapper =
            didAvoidBridgePermissionWrapper
        this.didAvoidBackendImplementationWrapper =
            didAvoidBackendImplementationWrapper
    }
}

struct CjguiInternalRendererNativeTeardownContractPolicy {
    let bridgeCallAdmissionGuard: CjguiInternalRendererBridgeCallAdmissionGuard
    let didPrepareRendererNativeTeardownContractPolicy: Bool
    let shouldDeferRendererNativeTeardownContractPolicy: Bool
    let shouldReportRendererNativeTeardownContractPolicyBlocked: Bool
    let didPreserveRendererBridgeCallAdmissionGuard: Bool
    let didDefineFutureNativeTeardownContractPolicy: Bool
    let didDescribeTeardownOrderingFacts: Bool
    let didDescribeFailureRollbackFacts: Bool
    let didDescribeNoResourceFinalizationFacts: Bool
    let didKeepNativeTeardownContractPolicyValueOnly: Bool
    let didAvoidForeignLifecycleCall: Bool
    let didAvoidResourceFinalizationSideEffect: Bool
    let didAvoidBridgeSmokeHarnessEntryChange: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidExternalApiSurface: Bool

    init(
        bridgeCallAdmissionGuard: CjguiInternalRendererBridgeCallAdmissionGuard,
        didPrepareRendererNativeTeardownContractPolicy: Bool,
        shouldDeferRendererNativeTeardownContractPolicy: Bool,
        shouldReportRendererNativeTeardownContractPolicyBlocked: Bool,
        didPreserveRendererBridgeCallAdmissionGuard: Bool,
        didDefineFutureNativeTeardownContractPolicy: Bool,
        didDescribeTeardownOrderingFacts: Bool,
        didDescribeFailureRollbackFacts: Bool,
        didDescribeNoResourceFinalizationFacts: Bool,
        didKeepNativeTeardownContractPolicyValueOnly: Bool,
        didAvoidForeignLifecycleCall: Bool,
        didAvoidResourceFinalizationSideEffect: Bool,
        didAvoidBridgeSmokeHarnessEntryChange: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidExternalApiSurface: Bool
    ) {
        this.bridgeCallAdmissionGuard = bridgeCallAdmissionGuard
        this.didPrepareRendererNativeTeardownContractPolicy =
            didPrepareRendererNativeTeardownContractPolicy
        this.shouldDeferRendererNativeTeardownContractPolicy =
            shouldDeferRendererNativeTeardownContractPolicy
        this.shouldReportRendererNativeTeardownContractPolicyBlocked =
            shouldReportRendererNativeTeardownContractPolicyBlocked
        this.didPreserveRendererBridgeCallAdmissionGuard =
            didPreserveRendererBridgeCallAdmissionGuard
        this.didDefineFutureNativeTeardownContractPolicy =
            didDefineFutureNativeTeardownContractPolicy
        this.didDescribeTeardownOrderingFacts =
            didDescribeTeardownOrderingFacts
        this.didDescribeFailureRollbackFacts =
            didDescribeFailureRollbackFacts
        this.didDescribeNoResourceFinalizationFacts =
            didDescribeNoResourceFinalizationFacts
        this.didKeepNativeTeardownContractPolicyValueOnly =
            didKeepNativeTeardownContractPolicyValueOnly
        this.didAvoidForeignLifecycleCall = didAvoidForeignLifecycleCall
        this.didAvoidResourceFinalizationSideEffect =
            didAvoidResourceFinalizationSideEffect
        this.didAvoidBridgeSmokeHarnessEntryChange =
            didAvoidBridgeSmokeHarnessEntryChange
        this.didAvoidRendererStateMutation =
            didAvoidRendererStateMutation
        this.didAvoidExternalApiSurface = didAvoidExternalApiSurface
    }
}

struct CjguiInternalRendererNoNativeResourceBridgeReadiness {
    let nativeTeardownContractPolicy: CjguiInternalRendererNativeTeardownContractPolicy
    let isRendererNoNativeResourceBridgeReady: Bool
    let canFutureRendererNativeResourceBridgeBoundaryEvaluate: Bool
    let shouldDeferRendererNoNativeResourceBridgeReadiness: Bool
    let shouldReportRendererNoNativeResourceBridgeReadinessBlocked: Bool
    let didSealRendererNoNativeResourceBridgeReadiness: Bool
    let didPreserveRendererNativeTeardownContractPolicy: Bool
    let didKeepNoNativeResourceBridgeReadinessValueOnly: Bool
    let didConfirmNoNativeResourceHandle: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didConfirmNoForeignResourceToken: Bool
    let didConfirmNoHandleExposure: Bool
    let didConfirmNoBridgeCall: Bool
    let didConfirmNoForeignFunctionDeclaration: Bool
    let didConfirmNoExternalAbiSurface: Bool
    let didConfirmNoResourceFinalizationSideEffect: Bool
    let didConfirmNoBridgeSmokeHarnessEntryChange: Bool
    let didConfirmNoWorkSubmit: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoRendererStateMutation: Bool
    let didConfirmNoExternalApiSurface: Bool
    let didAvoidNativeBridgePermissionWrapper: Bool
    let didAvoidNativeHandlePermissionWrapper: Bool
    let didAvoidPlatformObjectPermissionWrapper: Bool
    let didAvoidDeviceLayerPermissionWrapper: Bool
    let didAvoidBackendImplementationWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidRendererStateWriteWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        nativeTeardownContractPolicy: CjguiInternalRendererNativeTeardownContractPolicy,
        isRendererNoNativeResourceBridgeReady: Bool,
        canFutureRendererNativeResourceBridgeBoundaryEvaluate: Bool,
        shouldDeferRendererNoNativeResourceBridgeReadiness: Bool,
        shouldReportRendererNoNativeResourceBridgeReadinessBlocked: Bool,
        didSealRendererNoNativeResourceBridgeReadiness: Bool,
        didPreserveRendererNativeTeardownContractPolicy: Bool,
        didKeepNoNativeResourceBridgeReadinessValueOnly: Bool,
        didConfirmNoNativeResourceHandle: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didConfirmNoForeignResourceToken: Bool,
        didConfirmNoHandleExposure: Bool,
        didConfirmNoBridgeCall: Bool,
        didConfirmNoForeignFunctionDeclaration: Bool,
        didConfirmNoExternalAbiSurface: Bool,
        didConfirmNoResourceFinalizationSideEffect: Bool,
        didConfirmNoBridgeSmokeHarnessEntryChange: Bool,
        didConfirmNoWorkSubmit: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoRendererStateMutation: Bool,
        didConfirmNoExternalApiSurface: Bool,
        didAvoidNativeBridgePermissionWrapper: Bool,
        didAvoidNativeHandlePermissionWrapper: Bool,
        didAvoidPlatformObjectPermissionWrapper: Bool,
        didAvoidDeviceLayerPermissionWrapper: Bool,
        didAvoidBackendImplementationWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidRendererStateWriteWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.nativeTeardownContractPolicy = nativeTeardownContractPolicy
        this.isRendererNoNativeResourceBridgeReady =
            isRendererNoNativeResourceBridgeReady
        this.canFutureRendererNativeResourceBridgeBoundaryEvaluate =
            canFutureRendererNativeResourceBridgeBoundaryEvaluate
        this.shouldDeferRendererNoNativeResourceBridgeReadiness =
            shouldDeferRendererNoNativeResourceBridgeReadiness
        this.shouldReportRendererNoNativeResourceBridgeReadinessBlocked =
            shouldReportRendererNoNativeResourceBridgeReadinessBlocked
        this.didSealRendererNoNativeResourceBridgeReadiness =
            didSealRendererNoNativeResourceBridgeReadiness
        this.didPreserveRendererNativeTeardownContractPolicy =
            didPreserveRendererNativeTeardownContractPolicy
        this.didKeepNoNativeResourceBridgeReadinessValueOnly =
            didKeepNoNativeResourceBridgeReadinessValueOnly
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
        this.didConfirmNoResourceFinalizationSideEffect =
            didConfirmNoResourceFinalizationSideEffect
        this.didConfirmNoBridgeSmokeHarnessEntryChange =
            didConfirmNoBridgeSmokeHarnessEntryChange
        this.didConfirmNoWorkSubmit = didConfirmNoWorkSubmit
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoRendererStateMutation =
            didConfirmNoRendererStateMutation
        this.didConfirmNoExternalApiSurface =
            didConfirmNoExternalApiSurface
        this.didAvoidNativeBridgePermissionWrapper =
            didAvoidNativeBridgePermissionWrapper
        this.didAvoidNativeHandlePermissionWrapper =
            didAvoidNativeHandlePermissionWrapper
        this.didAvoidPlatformObjectPermissionWrapper =
            didAvoidPlatformObjectPermissionWrapper
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

func cjguiInternalBuildRendererNativeResourceBridgeIntent(
    noResourceBackendShellReadiness: CjguiInternalRendererNoResourceBackendShellReadiness
): CjguiInternalRendererNativeResourceBridgeIntent {
    let noResourceBackendShell =
        noResourceBackendShellReadiness.isRendererNoResourceBackendShellReady &&
        noResourceBackendShellReadiness.canFutureRendererBackendShellSkeletonBoundaryEvaluate &&
        noResourceBackendShellReadiness.didSealRendererNoResourceBackendShellReadiness &&
        noResourceBackendShellReadiness.didPreserveRendererBackendShellTeardownConfinementPolicy &&
        noResourceBackendShellReadiness.didKeepNoResourceBackendShellReadinessValueOnly &&
        noResourceBackendShellReadiness.didConfirmNoBackendShellInstance &&
        noResourceBackendShellReadiness.didConfirmNoBackendObject &&
        noResourceBackendShellReadiness.didConfirmNoPlatformObject &&
        noResourceBackendShellReadiness.didConfirmNoForeignResourceToken &&
        noResourceBackendShellReadiness.didConfirmNoPointerLikeResource &&
        noResourceBackendShellReadiness.didConfirmNoBridgeCall &&
        noResourceBackendShellReadiness.didConfirmNoResourceReleaseSideEffect &&
        noResourceBackendShellReadiness.didConfirmNoWorkSubmit &&
        noResourceBackendShellReadiness.didConfirmNoRenderExecution &&
        noResourceBackendShellReadiness.didConfirmNoRendererStateMutation &&
        noResourceBackendShellReadiness.didConfirmNoExternalApiSurface &&
        noResourceBackendShellReadiness.didAvoidBackendShellReadyPermissionWrapper &&
        noResourceBackendShellReadiness.didAvoidNativeResourceWrapper &&
        noResourceBackendShellReadiness.didAvoidPlatformObjectWrapper &&
        noResourceBackendShellReadiness.didAvoidDeviceLayerWrapper &&
        noResourceBackendShellReadiness.didAvoidWorkSubmitWrapper &&
        noResourceBackendShellReadiness.didAvoidRenderPermissionWrapper &&
        noResourceBackendShellReadiness.didAvoidBackendShellSkeletonTailWrapper &&
        noResourceBackendShellReadiness.didAvoidReceiptRecordPublication &&
        noResourceBackendShellReadiness.didAvoidThinWrapper &&
        noResourceBackendShellReadiness.didStayFullRebuildOnly &&
        noResourceBackendShellReadiness.shouldDeferRendererNoResourceBackendShellReadiness == false &&
        noResourceBackendShellReadiness.shouldReportRendererNoResourceBackendShellReadinessBlocked == false
    let intentDeferred =
        noResourceBackendShellReadiness.isRendererNoResourceBackendShellReady == false &&
        noResourceBackendShellReadiness.canFutureRendererBackendShellSkeletonBoundaryEvaluate == false &&
        noResourceBackendShellReadiness.shouldDeferRendererNoResourceBackendShellReadiness &&
        noResourceBackendShellReadiness.shouldReportRendererNoResourceBackendShellReadinessBlocked == false
    let intentInconsistent = (
        noResourceBackendShellReadiness.isRendererNoResourceBackendShellReady &&
            (
                noResourceBackendShellReadiness.canFutureRendererBackendShellSkeletonBoundaryEvaluate == false ||
                noResourceBackendShellReadiness.didSealRendererNoResourceBackendShellReadiness == false ||
                noResourceBackendShellReadiness.didPreserveRendererBackendShellTeardownConfinementPolicy == false ||
                noResourceBackendShellReadiness.didKeepNoResourceBackendShellReadinessValueOnly == false ||
                noResourceBackendShellReadiness.didConfirmNoBackendShellInstance == false ||
                noResourceBackendShellReadiness.didConfirmNoBackendObject == false ||
                noResourceBackendShellReadiness.didConfirmNoPlatformObject == false ||
                noResourceBackendShellReadiness.didConfirmNoForeignResourceToken == false ||
                noResourceBackendShellReadiness.didConfirmNoPointerLikeResource == false ||
                noResourceBackendShellReadiness.didConfirmNoBridgeCall == false ||
                noResourceBackendShellReadiness.didConfirmNoResourceReleaseSideEffect == false ||
                noResourceBackendShellReadiness.didConfirmNoWorkSubmit == false ||
                noResourceBackendShellReadiness.didConfirmNoRenderExecution == false ||
                noResourceBackendShellReadiness.didConfirmNoRendererStateMutation == false ||
                noResourceBackendShellReadiness.didConfirmNoExternalApiSurface == false ||
                noResourceBackendShellReadiness.didAvoidBackendShellReadyPermissionWrapper == false ||
                noResourceBackendShellReadiness.didAvoidNativeResourceWrapper == false ||
                noResourceBackendShellReadiness.didAvoidPlatformObjectWrapper == false ||
                noResourceBackendShellReadiness.didAvoidDeviceLayerWrapper == false ||
                noResourceBackendShellReadiness.didAvoidWorkSubmitWrapper == false ||
                noResourceBackendShellReadiness.didAvoidRenderPermissionWrapper == false ||
                noResourceBackendShellReadiness.didAvoidBackendShellSkeletonTailWrapper == false ||
                noResourceBackendShellReadiness.didAvoidReceiptRecordPublication == false ||
                noResourceBackendShellReadiness.didAvoidThinWrapper == false ||
                noResourceBackendShellReadiness.didStayFullRebuildOnly == false ||
                noResourceBackendShellReadiness.shouldDeferRendererNoResourceBackendShellReadiness ||
                noResourceBackendShellReadiness.shouldReportRendererNoResourceBackendShellReadinessBlocked
            )
        ) ||
        (
            noResourceBackendShellReadiness.canFutureRendererBackendShellSkeletonBoundaryEvaluate &&
            noResourceBackendShellReadiness.isRendererNoResourceBackendShellReady == false
        ) ||
        (
            noResourceBackendShellReadiness.shouldDeferRendererNoResourceBackendShellReadiness &&
            noResourceBackendShellReadiness.shouldReportRendererNoResourceBackendShellReadinessBlocked
        )

    if (
        noResourceBackendShellReadiness.shouldReportRendererNoResourceBackendShellReadinessBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererNativeResourceBridgeIntent(
            noResourceBackendShellReadiness,
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

    if (noResourceBackendShell) {
        return CjguiInternalRendererNativeResourceBridgeIntent(
            noResourceBackendShellReadiness,
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
        return CjguiInternalRendererNativeResourceBridgeIntent(
            noResourceBackendShellReadiness,
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

    return CjguiInternalRendererNativeResourceBridgeIntent(
        noResourceBackendShellReadiness,
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

func cjguiInternalBuildRendererNativeHandleConfinementPolicy(
    nativeResourceBridgeIntent: CjguiInternalRendererNativeResourceBridgeIntent
): CjguiInternalRendererNativeHandleConfinementPolicy {
    let intentReady =
        nativeResourceBridgeIntent.didPrepareRendererNativeResourceBridgeIntent &&
        nativeResourceBridgeIntent.didPreserveRendererNoResourceBackendShellReadiness &&
        nativeResourceBridgeIntent.didDefineFutureNativeResourceBridgeIntent &&
        nativeResourceBridgeIntent.didDescribeHandleConfinementNeed &&
        nativeResourceBridgeIntent.didDescribeBridgeAdmissionNeed &&
        nativeResourceBridgeIntent.didDescribeNativeTeardownContractNeed &&
        nativeResourceBridgeIntent.didKeepNativeResourceBridgeIntentValueOnly &&
        nativeResourceBridgeIntent.didAvoidNativeBridgePermissionWrapper &&
        nativeResourceBridgeIntent.didAvoidReceiptRecordPublication &&
        nativeResourceBridgeIntent.didAvoidThinWrapper &&
        nativeResourceBridgeIntent.shouldDeferRendererNativeResourceBridgeIntent == false &&
        nativeResourceBridgeIntent.shouldReportRendererNativeResourceBridgeIntentBlocked == false
    let confinementDeferred =
        nativeResourceBridgeIntent.didPrepareRendererNativeResourceBridgeIntent == false &&
        nativeResourceBridgeIntent.shouldDeferRendererNativeResourceBridgeIntent &&
        nativeResourceBridgeIntent.shouldReportRendererNativeResourceBridgeIntentBlocked == false
    let confinementInconsistent = (
        nativeResourceBridgeIntent.didPrepareRendererNativeResourceBridgeIntent &&
            (
                nativeResourceBridgeIntent.didPreserveRendererNoResourceBackendShellReadiness == false ||
                nativeResourceBridgeIntent.didDefineFutureNativeResourceBridgeIntent == false ||
                nativeResourceBridgeIntent.didDescribeHandleConfinementNeed == false ||
                nativeResourceBridgeIntent.didDescribeBridgeAdmissionNeed == false ||
                nativeResourceBridgeIntent.didDescribeNativeTeardownContractNeed == false ||
                nativeResourceBridgeIntent.didKeepNativeResourceBridgeIntentValueOnly == false ||
                nativeResourceBridgeIntent.didAvoidNativeBridgePermissionWrapper == false ||
                nativeResourceBridgeIntent.didAvoidReceiptRecordPublication == false ||
                nativeResourceBridgeIntent.didAvoidThinWrapper == false ||
                nativeResourceBridgeIntent.shouldDeferRendererNativeResourceBridgeIntent ||
                nativeResourceBridgeIntent.shouldReportRendererNativeResourceBridgeIntentBlocked
            )
        ) ||
        (
            nativeResourceBridgeIntent.didPreserveRendererNoResourceBackendShellReadiness &&
            nativeResourceBridgeIntent.didPrepareRendererNativeResourceBridgeIntent == false
        ) ||
        (
            nativeResourceBridgeIntent.shouldDeferRendererNativeResourceBridgeIntent &&
            nativeResourceBridgeIntent.shouldReportRendererNativeResourceBridgeIntentBlocked
        )

    if (
        nativeResourceBridgeIntent.shouldReportRendererNativeResourceBridgeIntentBlocked ||
        confinementInconsistent
    ) {
        return CjguiInternalRendererNativeHandleConfinementPolicy(
            nativeResourceBridgeIntent,
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
        return CjguiInternalRendererNativeHandleConfinementPolicy(
            nativeResourceBridgeIntent,
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

    if (confinementDeferred) {
        return CjguiInternalRendererNativeHandleConfinementPolicy(
            nativeResourceBridgeIntent,
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

    return CjguiInternalRendererNativeHandleConfinementPolicy(
        nativeResourceBridgeIntent,
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

func cjguiInternalBuildRendererBridgeCallAdmissionGuard(
    nativeHandleConfinementPolicy: CjguiInternalRendererNativeHandleConfinementPolicy
): CjguiInternalRendererBridgeCallAdmissionGuard {
    let confinementReady =
        nativeHandleConfinementPolicy.didPrepareRendererNativeHandleConfinementPolicy &&
        nativeHandleConfinementPolicy.didPreserveRendererNativeResourceBridgeIntent &&
        nativeHandleConfinementPolicy.didDefineFutureNativeHandleConfinementPolicy &&
        nativeHandleConfinementPolicy.didConfirmNoNativeResourceHandle &&
        nativeHandleConfinementPolicy.didConfirmNoPointerLikeResource &&
        nativeHandleConfinementPolicy.didConfirmNoForeignResourceToken &&
        nativeHandleConfinementPolicy.didConfirmNoHandleExposure &&
        nativeHandleConfinementPolicy.didKeepNativeHandleConfinementPolicyValueOnly &&
        nativeHandleConfinementPolicy.didAvoidNativeHandlePermissionWrapper &&
        nativeHandleConfinementPolicy.didAvoidPlatformObjectPermissionWrapper &&
        nativeHandleConfinementPolicy.shouldDeferRendererNativeHandleConfinementPolicy == false &&
        nativeHandleConfinementPolicy.shouldReportRendererNativeHandleConfinementPolicyBlocked == false
    let admissionDeferred =
        nativeHandleConfinementPolicy.didPrepareRendererNativeHandleConfinementPolicy == false &&
        nativeHandleConfinementPolicy.shouldDeferRendererNativeHandleConfinementPolicy &&
        nativeHandleConfinementPolicy.shouldReportRendererNativeHandleConfinementPolicyBlocked == false
    let admissionInconsistent = (
        nativeHandleConfinementPolicy.didPrepareRendererNativeHandleConfinementPolicy &&
            (
                nativeHandleConfinementPolicy.didPreserveRendererNativeResourceBridgeIntent == false ||
                nativeHandleConfinementPolicy.didDefineFutureNativeHandleConfinementPolicy == false ||
                nativeHandleConfinementPolicy.didConfirmNoNativeResourceHandle == false ||
                nativeHandleConfinementPolicy.didConfirmNoPointerLikeResource == false ||
                nativeHandleConfinementPolicy.didConfirmNoForeignResourceToken == false ||
                nativeHandleConfinementPolicy.didConfirmNoHandleExposure == false ||
                nativeHandleConfinementPolicy.didKeepNativeHandleConfinementPolicyValueOnly == false ||
                nativeHandleConfinementPolicy.didAvoidNativeHandlePermissionWrapper == false ||
                nativeHandleConfinementPolicy.didAvoidPlatformObjectPermissionWrapper == false ||
                nativeHandleConfinementPolicy.shouldDeferRendererNativeHandleConfinementPolicy ||
                nativeHandleConfinementPolicy.shouldReportRendererNativeHandleConfinementPolicyBlocked
            )
        ) ||
        (
            nativeHandleConfinementPolicy.didPreserveRendererNativeResourceBridgeIntent &&
            nativeHandleConfinementPolicy.didPrepareRendererNativeHandleConfinementPolicy == false
        ) ||
        (
            nativeHandleConfinementPolicy.shouldDeferRendererNativeHandleConfinementPolicy &&
            nativeHandleConfinementPolicy.shouldReportRendererNativeHandleConfinementPolicyBlocked
        )

    if (
        nativeHandleConfinementPolicy.shouldReportRendererNativeHandleConfinementPolicyBlocked ||
        admissionInconsistent
    ) {
        return CjguiInternalRendererBridgeCallAdmissionGuard(
            nativeHandleConfinementPolicy,
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

    if (confinementReady) {
        return CjguiInternalRendererBridgeCallAdmissionGuard(
            nativeHandleConfinementPolicy,
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
        return CjguiInternalRendererBridgeCallAdmissionGuard(
            nativeHandleConfinementPolicy,
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

    return CjguiInternalRendererBridgeCallAdmissionGuard(
        nativeHandleConfinementPolicy,
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

func cjguiInternalBuildRendererNativeTeardownContractPolicy(
    bridgeCallAdmissionGuard: CjguiInternalRendererBridgeCallAdmissionGuard
): CjguiInternalRendererNativeTeardownContractPolicy {
    let admissionReady =
        bridgeCallAdmissionGuard.didPrepareRendererBridgeCallAdmissionGuard &&
        bridgeCallAdmissionGuard.didPreserveRendererNativeHandleConfinementPolicy &&
        bridgeCallAdmissionGuard.didDefineFutureBridgeCallAdmissionGuard &&
        bridgeCallAdmissionGuard.didConfirmNoBridgeCall &&
        bridgeCallAdmissionGuard.didConfirmNoForeignFunctionDeclaration &&
        bridgeCallAdmissionGuard.didConfirmNoExternalAbiSurface &&
        bridgeCallAdmissionGuard.didConfirmNoForeignPlatformApiCall &&
        bridgeCallAdmissionGuard.didKeepBridgeCallAdmissionGuardValueOnly &&
        bridgeCallAdmissionGuard.didAvoidBridgePermissionWrapper &&
        bridgeCallAdmissionGuard.didAvoidBackendImplementationWrapper &&
        bridgeCallAdmissionGuard.shouldDeferRendererBridgeCallAdmissionGuard == false &&
        bridgeCallAdmissionGuard.shouldReportRendererBridgeCallAdmissionGuardBlocked == false
    let teardownDeferred =
        bridgeCallAdmissionGuard.didPrepareRendererBridgeCallAdmissionGuard == false &&
        bridgeCallAdmissionGuard.shouldDeferRendererBridgeCallAdmissionGuard &&
        bridgeCallAdmissionGuard.shouldReportRendererBridgeCallAdmissionGuardBlocked == false
    let teardownInconsistent = (
        bridgeCallAdmissionGuard.didPrepareRendererBridgeCallAdmissionGuard &&
            (
                bridgeCallAdmissionGuard.didPreserveRendererNativeHandleConfinementPolicy == false ||
                bridgeCallAdmissionGuard.didDefineFutureBridgeCallAdmissionGuard == false ||
                bridgeCallAdmissionGuard.didConfirmNoBridgeCall == false ||
                bridgeCallAdmissionGuard.didConfirmNoForeignFunctionDeclaration == false ||
                bridgeCallAdmissionGuard.didConfirmNoExternalAbiSurface == false ||
                bridgeCallAdmissionGuard.didConfirmNoForeignPlatformApiCall == false ||
                bridgeCallAdmissionGuard.didKeepBridgeCallAdmissionGuardValueOnly == false ||
                bridgeCallAdmissionGuard.didAvoidBridgePermissionWrapper == false ||
                bridgeCallAdmissionGuard.didAvoidBackendImplementationWrapper == false ||
                bridgeCallAdmissionGuard.shouldDeferRendererBridgeCallAdmissionGuard ||
                bridgeCallAdmissionGuard.shouldReportRendererBridgeCallAdmissionGuardBlocked
            )
        ) ||
        (
            bridgeCallAdmissionGuard.didPreserveRendererNativeHandleConfinementPolicy &&
            bridgeCallAdmissionGuard.didPrepareRendererBridgeCallAdmissionGuard == false
        ) ||
        (
            bridgeCallAdmissionGuard.shouldDeferRendererBridgeCallAdmissionGuard &&
            bridgeCallAdmissionGuard.shouldReportRendererBridgeCallAdmissionGuardBlocked
        )

    if (
        bridgeCallAdmissionGuard.shouldReportRendererBridgeCallAdmissionGuardBlocked ||
        teardownInconsistent
    ) {
        return CjguiInternalRendererNativeTeardownContractPolicy(
            bridgeCallAdmissionGuard,
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
            true,
            true
        )
    }

    if (admissionReady) {
        return CjguiInternalRendererNativeTeardownContractPolicy(
            bridgeCallAdmissionGuard,
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
            true
        )
    }

    if (teardownDeferred) {
        return CjguiInternalRendererNativeTeardownContractPolicy(
            bridgeCallAdmissionGuard,
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
            true,
            true
        )
    }

    return CjguiInternalRendererNativeTeardownContractPolicy(
        bridgeCallAdmissionGuard,
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
        true,
        true
    )
}

func cjguiInternalBuildRendererNoNativeResourceBridgeReadiness(
    nativeTeardownContractPolicy: CjguiInternalRendererNativeTeardownContractPolicy
): CjguiInternalRendererNoNativeResourceBridgeReadiness {
    let contractReady =
        nativeTeardownContractPolicy.didPrepareRendererNativeTeardownContractPolicy &&
        nativeTeardownContractPolicy.didPreserveRendererBridgeCallAdmissionGuard &&
        nativeTeardownContractPolicy.didDefineFutureNativeTeardownContractPolicy &&
        nativeTeardownContractPolicy.didDescribeTeardownOrderingFacts &&
        nativeTeardownContractPolicy.didDescribeFailureRollbackFacts &&
        nativeTeardownContractPolicy.didDescribeNoResourceFinalizationFacts &&
        nativeTeardownContractPolicy.didKeepNativeTeardownContractPolicyValueOnly &&
        nativeTeardownContractPolicy.didAvoidForeignLifecycleCall &&
        nativeTeardownContractPolicy.didAvoidResourceFinalizationSideEffect &&
        nativeTeardownContractPolicy.didAvoidBridgeSmokeHarnessEntryChange &&
        nativeTeardownContractPolicy.didAvoidRendererStateMutation &&
        nativeTeardownContractPolicy.didAvoidExternalApiSurface &&
        nativeTeardownContractPolicy.shouldDeferRendererNativeTeardownContractPolicy == false &&
        nativeTeardownContractPolicy.shouldReportRendererNativeTeardownContractPolicyBlocked == false
    let readinessDeferred =
        nativeTeardownContractPolicy.didPrepareRendererNativeTeardownContractPolicy == false &&
        nativeTeardownContractPolicy.shouldDeferRendererNativeTeardownContractPolicy &&
        nativeTeardownContractPolicy.shouldReportRendererNativeTeardownContractPolicyBlocked == false
    let readinessInconsistent = (
        nativeTeardownContractPolicy.didPrepareRendererNativeTeardownContractPolicy &&
            (
                nativeTeardownContractPolicy.didPreserveRendererBridgeCallAdmissionGuard == false ||
                nativeTeardownContractPolicy.didDefineFutureNativeTeardownContractPolicy == false ||
                nativeTeardownContractPolicy.didDescribeTeardownOrderingFacts == false ||
                nativeTeardownContractPolicy.didDescribeFailureRollbackFacts == false ||
                nativeTeardownContractPolicy.didDescribeNoResourceFinalizationFacts == false ||
                nativeTeardownContractPolicy.didKeepNativeTeardownContractPolicyValueOnly == false ||
                nativeTeardownContractPolicy.didAvoidForeignLifecycleCall == false ||
                nativeTeardownContractPolicy.didAvoidResourceFinalizationSideEffect == false ||
                nativeTeardownContractPolicy.didAvoidBridgeSmokeHarnessEntryChange == false ||
                nativeTeardownContractPolicy.didAvoidRendererStateMutation == false ||
                nativeTeardownContractPolicy.didAvoidExternalApiSurface == false ||
                nativeTeardownContractPolicy.shouldDeferRendererNativeTeardownContractPolicy ||
                nativeTeardownContractPolicy.shouldReportRendererNativeTeardownContractPolicyBlocked
            )
        ) ||
        (
            nativeTeardownContractPolicy.didPreserveRendererBridgeCallAdmissionGuard &&
            nativeTeardownContractPolicy.didPrepareRendererNativeTeardownContractPolicy == false
        ) ||
        (
            nativeTeardownContractPolicy.shouldDeferRendererNativeTeardownContractPolicy &&
            nativeTeardownContractPolicy.shouldReportRendererNativeTeardownContractPolicyBlocked
        )

    if (
        nativeTeardownContractPolicy.shouldReportRendererNativeTeardownContractPolicyBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoNativeResourceBridgeReadiness(
            nativeTeardownContractPolicy,
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
            true
        )
    }

    if (contractReady) {
        return CjguiInternalRendererNoNativeResourceBridgeReadiness(
            nativeTeardownContractPolicy,
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
            true
        )
    }

    if (readinessDeferred) {
        return CjguiInternalRendererNoNativeResourceBridgeReadiness(
            nativeTeardownContractPolicy,
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
            true
        )
    }

    return CjguiInternalRendererNoNativeResourceBridgeReadiness(
        nativeTeardownContractPolicy,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft(
): CjguiInternalRendererNoNativeResourceBridgeReadiness {
    let noResourceBackendShellReadiness =
        cjguiInternalExecuteDefaultRendererBackendShellSkeletonDraft()
    let nativeResourceBridgeIntent =
        cjguiInternalBuildRendererNativeResourceBridgeIntent(
            noResourceBackendShellReadiness
        )
    let nativeHandleConfinementPolicy =
        cjguiInternalBuildRendererNativeHandleConfinementPolicy(
            nativeResourceBridgeIntent
        )
    let bridgeCallAdmissionGuard =
        cjguiInternalBuildRendererBridgeCallAdmissionGuard(
            nativeHandleConfinementPolicy
        )
    let nativeTeardownContractPolicy =
        cjguiInternalBuildRendererNativeTeardownContractPolicy(
            bridgeCallAdmissionGuard
        )
    return cjguiInternalBuildRendererNoNativeResourceBridgeReadiness(
        nativeTeardownContractPolicy
    )
}
