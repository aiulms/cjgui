// Owner: native teardown contract hardening value boundary.
// Truth: consumes CjguiInternalRendererNoRealBackendPlatformObjectReadiness and
// records teardown intent, ownership release policy, failure classification,
// main-thread confinement, and no-native-teardown-implementation facts.
// Stop-line: no external lifecycle surface, foreign resource surface, graphics
// resource, work submit, render side effect, state mutation, or public surface.
// Same-shape Boundary Brake: this owner adds teardown hardening vocabulary; it
// is not a native lifecycle, backend-ready, resource-ready, or public wrapper.
package cjgui

struct CjguiInternalRendererNativeTeardownContractIntent {
    let noRealBackendPlatformObjectReadiness:
        CjguiInternalRendererNoRealBackendPlatformObjectReadiness
    let didPrepareRendererNativeTeardownContractIntent: Bool
    let shouldDeferRendererNativeTeardownContractIntent: Bool
    let shouldReportRendererNativeTeardownContractIntentBlocked: Bool
    let didPreserveRendererNoRealBackendPlatformObjectReadiness: Bool
    let didDefineNativeTeardownContractHardeningIntent: Bool
    let didDescribeOwnershipReleasePolicyNeed: Bool
    let didDescribeFailureClassificationNeed: Bool
    let didDescribeMainThreadConfinementNeed: Bool
    let didKeepNativeTeardownContractIntentValueOnly: Bool
    let didAvoidNativeLifecyclePermissionWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        noRealBackendPlatformObjectReadiness:
            CjguiInternalRendererNoRealBackendPlatformObjectReadiness,
        didPrepareRendererNativeTeardownContractIntent: Bool,
        shouldDeferRendererNativeTeardownContractIntent: Bool,
        shouldReportRendererNativeTeardownContractIntentBlocked: Bool,
        didPreserveRendererNoRealBackendPlatformObjectReadiness: Bool,
        didDefineNativeTeardownContractHardeningIntent: Bool,
        didDescribeOwnershipReleasePolicyNeed: Bool,
        didDescribeFailureClassificationNeed: Bool,
        didDescribeMainThreadConfinementNeed: Bool,
        didKeepNativeTeardownContractIntentValueOnly: Bool,
        didAvoidNativeLifecyclePermissionWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noRealBackendPlatformObjectReadiness =
            noRealBackendPlatformObjectReadiness
        this.didPrepareRendererNativeTeardownContractIntent =
            didPrepareRendererNativeTeardownContractIntent
        this.shouldDeferRendererNativeTeardownContractIntent =
            shouldDeferRendererNativeTeardownContractIntent
        this.shouldReportRendererNativeTeardownContractIntentBlocked =
            shouldReportRendererNativeTeardownContractIntentBlocked
        this.didPreserveRendererNoRealBackendPlatformObjectReadiness =
            didPreserveRendererNoRealBackendPlatformObjectReadiness
        this.didDefineNativeTeardownContractHardeningIntent =
            didDefineNativeTeardownContractHardeningIntent
        this.didDescribeOwnershipReleasePolicyNeed =
            didDescribeOwnershipReleasePolicyNeed
        this.didDescribeFailureClassificationNeed =
            didDescribeFailureClassificationNeed
        this.didDescribeMainThreadConfinementNeed =
            didDescribeMainThreadConfinementNeed
        this.didKeepNativeTeardownContractIntentValueOnly =
            didKeepNativeTeardownContractIntentValueOnly
        this.didAvoidNativeLifecyclePermissionWrapper =
            didAvoidNativeLifecyclePermissionWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeOwnershipReleasePolicy {
    let teardownContractIntent:
        CjguiInternalRendererNativeTeardownContractIntent
    let didPrepareRendererNativeOwnershipReleasePolicy: Bool
    let shouldDeferRendererNativeOwnershipReleasePolicy: Bool
    let shouldReportRendererNativeOwnershipReleasePolicyBlocked: Bool
    let didPreserveRendererNativeTeardownContractIntent: Bool
    let didDefineOwnerLocalReleaseOrdering: Bool
    let didDefineIdempotentTeardownExpectation: Bool
    let didFailClosedDoubleReleaseRisk: Bool
    let didFailClosedDanglingResourceRisk: Bool
    let didConfirmNoExternalLifecycleSurface: Bool
    let didKeepNativeOwnershipReleasePolicyValueOnly: Bool
    let didAvoidNativeLifecyclePermissionWrapper: Bool
    let didAvoidResourceReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        teardownContractIntent:
            CjguiInternalRendererNativeTeardownContractIntent,
        didPrepareRendererNativeOwnershipReleasePolicy: Bool,
        shouldDeferRendererNativeOwnershipReleasePolicy: Bool,
        shouldReportRendererNativeOwnershipReleasePolicyBlocked: Bool,
        didPreserveRendererNativeTeardownContractIntent: Bool,
        didDefineOwnerLocalReleaseOrdering: Bool,
        didDefineIdempotentTeardownExpectation: Bool,
        didFailClosedDoubleReleaseRisk: Bool,
        didFailClosedDanglingResourceRisk: Bool,
        didConfirmNoExternalLifecycleSurface: Bool,
        didKeepNativeOwnershipReleasePolicyValueOnly: Bool,
        didAvoidNativeLifecyclePermissionWrapper: Bool,
        didAvoidResourceReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.teardownContractIntent = teardownContractIntent
        this.didPrepareRendererNativeOwnershipReleasePolicy =
            didPrepareRendererNativeOwnershipReleasePolicy
        this.shouldDeferRendererNativeOwnershipReleasePolicy =
            shouldDeferRendererNativeOwnershipReleasePolicy
        this.shouldReportRendererNativeOwnershipReleasePolicyBlocked =
            shouldReportRendererNativeOwnershipReleasePolicyBlocked
        this.didPreserveRendererNativeTeardownContractIntent =
            didPreserveRendererNativeTeardownContractIntent
        this.didDefineOwnerLocalReleaseOrdering =
            didDefineOwnerLocalReleaseOrdering
        this.didDefineIdempotentTeardownExpectation =
            didDefineIdempotentTeardownExpectation
        this.didFailClosedDoubleReleaseRisk =
            didFailClosedDoubleReleaseRisk
        this.didFailClosedDanglingResourceRisk =
            didFailClosedDanglingResourceRisk
        this.didConfirmNoExternalLifecycleSurface =
            didConfirmNoExternalLifecycleSurface
        this.didKeepNativeOwnershipReleasePolicyValueOnly =
            didKeepNativeOwnershipReleasePolicyValueOnly
        this.didAvoidNativeLifecyclePermissionWrapper =
            didAvoidNativeLifecyclePermissionWrapper
        this.didAvoidResourceReadyWrapper = didAvoidResourceReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeTeardownFailureClassification {
    let ownershipReleasePolicy:
        CjguiInternalRendererNativeOwnershipReleasePolicy
    let didPrepareRendererNativeTeardownFailureClassification: Bool
    let shouldDeferRendererNativeTeardownFailureClassification: Bool
    let shouldReportRendererNativeTeardownFailureClassificationBlocked: Bool
    let didPreserveRendererNativeOwnershipReleasePolicy: Bool
    let didDefineOwnerLocalFailureClassification: Bool
    let didClassifyCreateUnavailableAsFailClosed: Bool
    let didClassifyReleaseFailureAsFailClosed: Bool
    let didClassifyAlreadyClosedAsFailClosed: Bool
    let didClassifyStaleResourceAsFailClosed: Bool
    let didClassifyBridgeOptimismAsFailClosed: Bool
    let didKeepNativeTeardownFailureClassificationValueOnly: Bool
    let didAvoidFailurePublicationWrapper: Bool
    let didAvoidPublicDiagnosticsWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        ownershipReleasePolicy:
            CjguiInternalRendererNativeOwnershipReleasePolicy,
        didPrepareRendererNativeTeardownFailureClassification: Bool,
        shouldDeferRendererNativeTeardownFailureClassification: Bool,
        shouldReportRendererNativeTeardownFailureClassificationBlocked:
            Bool,
        didPreserveRendererNativeOwnershipReleasePolicy: Bool,
        didDefineOwnerLocalFailureClassification: Bool,
        didClassifyCreateUnavailableAsFailClosed: Bool,
        didClassifyReleaseFailureAsFailClosed: Bool,
        didClassifyAlreadyClosedAsFailClosed: Bool,
        didClassifyStaleResourceAsFailClosed: Bool,
        didClassifyBridgeOptimismAsFailClosed: Bool,
        didKeepNativeTeardownFailureClassificationValueOnly: Bool,
        didAvoidFailurePublicationWrapper: Bool,
        didAvoidPublicDiagnosticsWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.ownershipReleasePolicy = ownershipReleasePolicy
        this.didPrepareRendererNativeTeardownFailureClassification =
            didPrepareRendererNativeTeardownFailureClassification
        this.shouldDeferRendererNativeTeardownFailureClassification =
            shouldDeferRendererNativeTeardownFailureClassification
        this.shouldReportRendererNativeTeardownFailureClassificationBlocked =
            shouldReportRendererNativeTeardownFailureClassificationBlocked
        this.didPreserveRendererNativeOwnershipReleasePolicy =
            didPreserveRendererNativeOwnershipReleasePolicy
        this.didDefineOwnerLocalFailureClassification =
            didDefineOwnerLocalFailureClassification
        this.didClassifyCreateUnavailableAsFailClosed =
            didClassifyCreateUnavailableAsFailClosed
        this.didClassifyReleaseFailureAsFailClosed =
            didClassifyReleaseFailureAsFailClosed
        this.didClassifyAlreadyClosedAsFailClosed =
            didClassifyAlreadyClosedAsFailClosed
        this.didClassifyStaleResourceAsFailClosed =
            didClassifyStaleResourceAsFailClosed
        this.didClassifyBridgeOptimismAsFailClosed =
            didClassifyBridgeOptimismAsFailClosed
        this.didKeepNativeTeardownFailureClassificationValueOnly =
            didKeepNativeTeardownFailureClassificationValueOnly
        this.didAvoidFailurePublicationWrapper =
            didAvoidFailurePublicationWrapper
        this.didAvoidPublicDiagnosticsWrapper =
            didAvoidPublicDiagnosticsWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeMainThreadConfinementGuard {
    let failureClassification:
        CjguiInternalRendererNativeTeardownFailureClassification
    let didPrepareRendererNativeMainThreadConfinementGuard: Bool
    let shouldDeferRendererNativeMainThreadConfinementGuard: Bool
    let shouldReportRendererNativeMainThreadConfinementGuardBlocked: Bool
    let didPreserveRendererNativeTeardownFailureClassification: Bool
    let didDefineOwnerLocalMainThreadConfinement: Bool
    let didClassifyWrongThreadAsFailClosed: Bool
    let didRequireLifecycleFactsToStayDehydrated: Bool
    let didConfirmNoStateMutation: Bool
    let didConfirmNoPublicSurface: Bool
    let didKeepNativeMainThreadConfinementGuardValueOnly: Bool
    let didAvoidThreadPermissionWrapper: Bool
    let didAvoidExternalLifecycleWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        failureClassification:
            CjguiInternalRendererNativeTeardownFailureClassification,
        didPrepareRendererNativeMainThreadConfinementGuard: Bool,
        shouldDeferRendererNativeMainThreadConfinementGuard: Bool,
        shouldReportRendererNativeMainThreadConfinementGuardBlocked:
            Bool,
        didPreserveRendererNativeTeardownFailureClassification: Bool,
        didDefineOwnerLocalMainThreadConfinement: Bool,
        didClassifyWrongThreadAsFailClosed: Bool,
        didRequireLifecycleFactsToStayDehydrated: Bool,
        didConfirmNoStateMutation: Bool,
        didConfirmNoPublicSurface: Bool,
        didKeepNativeMainThreadConfinementGuardValueOnly: Bool,
        didAvoidThreadPermissionWrapper: Bool,
        didAvoidExternalLifecycleWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.failureClassification = failureClassification
        this.didPrepareRendererNativeMainThreadConfinementGuard =
            didPrepareRendererNativeMainThreadConfinementGuard
        this.shouldDeferRendererNativeMainThreadConfinementGuard =
            shouldDeferRendererNativeMainThreadConfinementGuard
        this.shouldReportRendererNativeMainThreadConfinementGuardBlocked =
            shouldReportRendererNativeMainThreadConfinementGuardBlocked
        this.didPreserveRendererNativeTeardownFailureClassification =
            didPreserveRendererNativeTeardownFailureClassification
        this.didDefineOwnerLocalMainThreadConfinement =
            didDefineOwnerLocalMainThreadConfinement
        this.didClassifyWrongThreadAsFailClosed =
            didClassifyWrongThreadAsFailClosed
        this.didRequireLifecycleFactsToStayDehydrated =
            didRequireLifecycleFactsToStayDehydrated
        this.didConfirmNoStateMutation = didConfirmNoStateMutation
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didKeepNativeMainThreadConfinementGuardValueOnly =
            didKeepNativeMainThreadConfinementGuardValueOnly
        this.didAvoidThreadPermissionWrapper =
            didAvoidThreadPermissionWrapper
        this.didAvoidExternalLifecycleWrapper =
            didAvoidExternalLifecycleWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoNativeTeardownImplementationReadiness {
    let confinementGuard:
        CjguiInternalRendererNativeMainThreadConfinementGuard
    let isRendererNoNativeTeardownImplementationReady: Bool
    let canFutureRendererNativeTeardownImplementationBoundaryEvaluate: Bool
    let shouldDeferRendererNoNativeTeardownImplementationReadiness: Bool
    let shouldReportRendererNoNativeTeardownImplementationReadinessBlocked:
        Bool
    let didSealRendererNoNativeTeardownImplementationReadiness: Bool
    let didPreserveRendererNativeMainThreadConfinementGuard: Bool
    let didKeepNoNativeTeardownImplementationReadinessValueOnly: Bool
    let didConfirmNoExternalLifecycleSurface: Bool
    let didConfirmNoForeignDeclaration: Bool
    let didConfirmNoForeignResourceSurface: Bool
    let didConfirmNoForeignPlatformResource: Bool
    let didConfirmNoGraphicsResource: Bool
    let didConfirmNoWorkSubmit: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoRendererStateMutation: Bool
    let didConfirmNoRuntimeStateTouch: Bool
    let didConfirmNoModuleLevelMutableState: Bool
    let didConfirmNoPublicSurface: Bool
    let didFailClosedDoubleReleaseRisk: Bool
    let didFailClosedDanglingResourceRisk: Bool
    let didFailClosedWrongThreadRisk: Bool
    let didFailClosedBridgeOptimismRisk: Bool
    let didAvoidNativeLifecyclePermissionWrapper: Bool
    let didAvoidResourceReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidStateMutationWrapper: Bool
    let didAvoidPublicSurfaceWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidNativeTeardownReadyWrapper: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        confinementGuard:
            CjguiInternalRendererNativeMainThreadConfinementGuard,
        isRendererNoNativeTeardownImplementationReady: Bool,
        canFutureRendererNativeTeardownImplementationBoundaryEvaluate: Bool,
        shouldDeferRendererNoNativeTeardownImplementationReadiness: Bool,
        shouldReportRendererNoNativeTeardownImplementationReadinessBlocked:
            Bool,
        didSealRendererNoNativeTeardownImplementationReadiness: Bool,
        didPreserveRendererNativeMainThreadConfinementGuard: Bool,
        didKeepNoNativeTeardownImplementationReadinessValueOnly: Bool,
        didConfirmNoExternalLifecycleSurface: Bool,
        didConfirmNoForeignDeclaration: Bool,
        didConfirmNoForeignResourceSurface: Bool,
        didConfirmNoForeignPlatformResource: Bool,
        didConfirmNoGraphicsResource: Bool,
        didConfirmNoWorkSubmit: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoRendererStateMutation: Bool,
        didConfirmNoRuntimeStateTouch: Bool,
        didConfirmNoModuleLevelMutableState: Bool,
        didConfirmNoPublicSurface: Bool,
        didFailClosedDoubleReleaseRisk: Bool,
        didFailClosedDanglingResourceRisk: Bool,
        didFailClosedWrongThreadRisk: Bool,
        didFailClosedBridgeOptimismRisk: Bool,
        didAvoidNativeLifecyclePermissionWrapper: Bool,
        didAvoidResourceReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidStateMutationWrapper: Bool,
        didAvoidPublicSurfaceWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidNativeTeardownReadyWrapper: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.confinementGuard = confinementGuard
        this.isRendererNoNativeTeardownImplementationReady =
            isRendererNoNativeTeardownImplementationReady
        this.canFutureRendererNativeTeardownImplementationBoundaryEvaluate =
            canFutureRendererNativeTeardownImplementationBoundaryEvaluate
        this.shouldDeferRendererNoNativeTeardownImplementationReadiness =
            shouldDeferRendererNoNativeTeardownImplementationReadiness
        this.shouldReportRendererNoNativeTeardownImplementationReadinessBlocked =
            shouldReportRendererNoNativeTeardownImplementationReadinessBlocked
        this.didSealRendererNoNativeTeardownImplementationReadiness =
            didSealRendererNoNativeTeardownImplementationReadiness
        this.didPreserveRendererNativeMainThreadConfinementGuard =
            didPreserveRendererNativeMainThreadConfinementGuard
        this.didKeepNoNativeTeardownImplementationReadinessValueOnly =
            didKeepNoNativeTeardownImplementationReadinessValueOnly
        this.didConfirmNoExternalLifecycleSurface =
            didConfirmNoExternalLifecycleSurface
        this.didConfirmNoForeignDeclaration = didConfirmNoForeignDeclaration
        this.didConfirmNoForeignResourceSurface =
            didConfirmNoForeignResourceSurface
        this.didConfirmNoForeignPlatformResource =
            didConfirmNoForeignPlatformResource
        this.didConfirmNoGraphicsResource = didConfirmNoGraphicsResource
        this.didConfirmNoWorkSubmit = didConfirmNoWorkSubmit
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoRendererStateMutation =
            didConfirmNoRendererStateMutation
        this.didConfirmNoRuntimeStateTouch = didConfirmNoRuntimeStateTouch
        this.didConfirmNoModuleLevelMutableState =
            didConfirmNoModuleLevelMutableState
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didFailClosedDoubleReleaseRisk =
            didFailClosedDoubleReleaseRisk
        this.didFailClosedDanglingResourceRisk =
            didFailClosedDanglingResourceRisk
        this.didFailClosedWrongThreadRisk = didFailClosedWrongThreadRisk
        this.didFailClosedBridgeOptimismRisk =
            didFailClosedBridgeOptimismRisk
        this.didAvoidNativeLifecyclePermissionWrapper =
            didAvoidNativeLifecyclePermissionWrapper
        this.didAvoidResourceReadyWrapper = didAvoidResourceReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidRenderPermissionWrapper =
            didAvoidRenderPermissionWrapper
        this.didAvoidStateMutationWrapper = didAvoidStateMutationWrapper
        this.didAvoidPublicSurfaceWrapper = didAvoidPublicSurfaceWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidNativeTeardownReadyWrapper =
            didAvoidNativeTeardownReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererNativeTeardownContractIntent(
    noRealBackendPlatformObjectReadiness:
        CjguiInternalRendererNoRealBackendPlatformObjectReadiness
): CjguiInternalRendererNativeTeardownContractIntent {
    let upstreamReady =
        noRealBackendPlatformObjectReadiness
            .isRendererNoRealBackendPlatformObjectReady &&
        noRealBackendPlatformObjectReadiness
            .canFutureRendererRealBackendPlatformObjectBoundaryEvaluate &&
        noRealBackendPlatformObjectReadiness
            .didSealRendererNoRealBackendPlatformObjectReadiness &&
        noRealBackendPlatformObjectReadiness
            .didPreserveRendererRealBackendPlatformObjectFailurePolicy &&
        noRealBackendPlatformObjectReadiness
            .didKeepNoRealBackendPlatformObjectReadinessShellOnly &&
        noRealBackendPlatformObjectReadiness.didConfirmNoBackendReadyTruth &&
        noRealBackendPlatformObjectReadiness
            .didConfirmNoPlatformResourceObject &&
        noRealBackendPlatformObjectReadiness
            .didConfirmNoExternalResourceSurface &&
        noRealBackendPlatformObjectReadiness
            .didConfirmNoExternalLifecycleCall &&
        noRealBackendPlatformObjectReadiness.didConfirmNoGraphicsWork &&
        noRealBackendPlatformObjectReadiness.didConfirmNoStateMutation &&
        noRealBackendPlatformObjectReadiness.didConfirmNoRuntimeStateTouch &&
        noRealBackendPlatformObjectReadiness
            .didConfirmNoModuleLevelMutableState &&
        noRealBackendPlatformObjectReadiness.didConfirmNoPublicSurface &&
        noRealBackendPlatformObjectReadiness
            .didAvoidPlatformObjectPermissionWrapper &&
        noRealBackendPlatformObjectReadiness.didAvoidResourceReadyWrapper &&
        noRealBackendPlatformObjectReadiness.didAvoidBackendReadyWrapper &&
        noRealBackendPlatformObjectReadiness.didAvoidGraphicsWorkWrapper &&
        noRealBackendPlatformObjectReadiness.didAvoidStateMutationWrapper &&
        noRealBackendPlatformObjectReadiness.didAvoidPublicSurfaceWrapper &&
        noRealBackendPlatformObjectReadiness.didAvoidReceiptRecordOutput &&
        noRealBackendPlatformObjectReadiness.didAvoidThinWrapper &&
        noRealBackendPlatformObjectReadiness.didStayFullRebuildOnly &&
        noRealBackendPlatformObjectReadiness
            .shouldDeferRendererNoRealBackendPlatformObjectReadiness ==
            false &&
        noRealBackendPlatformObjectReadiness
            .shouldReportRendererNoRealBackendPlatformObjectReadinessBlocked ==
            false
    let upstreamDeferred =
        noRealBackendPlatformObjectReadiness
            .isRendererNoRealBackendPlatformObjectReady == false &&
        noRealBackendPlatformObjectReadiness
            .canFutureRendererRealBackendPlatformObjectBoundaryEvaluate ==
            false &&
        noRealBackendPlatformObjectReadiness
            .shouldDeferRendererNoRealBackendPlatformObjectReadiness &&
        noRealBackendPlatformObjectReadiness
            .shouldReportRendererNoRealBackendPlatformObjectReadinessBlocked ==
            false
    let upstreamInconsistent =
        noRealBackendPlatformObjectReadiness
            .shouldReportRendererNoRealBackendPlatformObjectReadinessBlocked ||
        (
            noRealBackendPlatformObjectReadiness
                .isRendererNoRealBackendPlatformObjectReady &&
            (
                upstreamReady == false ||
                noRealBackendPlatformObjectReadiness
                    .shouldDeferRendererNoRealBackendPlatformObjectReadiness
            )
        ) ||
        (
            noRealBackendPlatformObjectReadiness
                .canFutureRendererRealBackendPlatformObjectBoundaryEvaluate &&
            noRealBackendPlatformObjectReadiness
                .isRendererNoRealBackendPlatformObjectReady == false
        ) ||
        (
            noRealBackendPlatformObjectReadiness
                .shouldDeferRendererNoRealBackendPlatformObjectReadiness &&
            noRealBackendPlatformObjectReadiness
                .shouldReportRendererNoRealBackendPlatformObjectReadinessBlocked
        )

    if (upstreamInconsistent) {
        return CjguiInternalRendererNativeTeardownContractIntent(
            noRealBackendPlatformObjectReadiness,
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

    if (upstreamReady) {
        return CjguiInternalRendererNativeTeardownContractIntent(
            noRealBackendPlatformObjectReadiness,
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

    if (upstreamDeferred) {
        return CjguiInternalRendererNativeTeardownContractIntent(
            noRealBackendPlatformObjectReadiness,
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

    return CjguiInternalRendererNativeTeardownContractIntent(
        noRealBackendPlatformObjectReadiness,
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

func cjguiInternalBuildRendererNativeOwnershipReleasePolicy(
    teardownContractIntent:
        CjguiInternalRendererNativeTeardownContractIntent
): CjguiInternalRendererNativeOwnershipReleasePolicy {
    let intentReady =
        teardownContractIntent
            .didPrepareRendererNativeTeardownContractIntent &&
        teardownContractIntent
            .didPreserveRendererNoRealBackendPlatformObjectReadiness &&
        teardownContractIntent
            .didDefineNativeTeardownContractHardeningIntent &&
        teardownContractIntent.didDescribeOwnershipReleasePolicyNeed &&
        teardownContractIntent.didDescribeFailureClassificationNeed &&
        teardownContractIntent.didDescribeMainThreadConfinementNeed &&
        teardownContractIntent
            .didKeepNativeTeardownContractIntentValueOnly &&
        teardownContractIntent.didAvoidNativeLifecyclePermissionWrapper &&
        teardownContractIntent.didAvoidBackendReadyWrapper &&
        teardownContractIntent.didAvoidReceiptRecordOutput &&
        teardownContractIntent.didAvoidThinWrapper &&
        teardownContractIntent
            .shouldDeferRendererNativeTeardownContractIntent == false &&
        teardownContractIntent
            .shouldReportRendererNativeTeardownContractIntentBlocked ==
            false
    let intentDeferred =
        teardownContractIntent
            .didPrepareRendererNativeTeardownContractIntent == false &&
        teardownContractIntent.shouldDeferRendererNativeTeardownContractIntent &&
        teardownContractIntent
            .shouldReportRendererNativeTeardownContractIntentBlocked == false
    let intentInconsistent =
        teardownContractIntent
            .shouldReportRendererNativeTeardownContractIntentBlocked ||
        (
            teardownContractIntent
                .didPrepareRendererNativeTeardownContractIntent &&
            intentReady == false
        ) ||
        (
            teardownContractIntent
                .didPreserveRendererNoRealBackendPlatformObjectReadiness &&
            teardownContractIntent
                .didPrepareRendererNativeTeardownContractIntent == false
        )

    if (intentInconsistent) {
        return CjguiInternalRendererNativeOwnershipReleasePolicy(
            teardownContractIntent,
            false,
            false,
            true,
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

    if (intentReady) {
        return CjguiInternalRendererNativeOwnershipReleasePolicy(
            teardownContractIntent,
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

    if (intentDeferred) {
        return CjguiInternalRendererNativeOwnershipReleasePolicy(
            teardownContractIntent,
            false,
            true,
            false,
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

    return CjguiInternalRendererNativeOwnershipReleasePolicy(
        teardownContractIntent,
        false,
        false,
        true,
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

func cjguiInternalBuildRendererNativeTeardownFailureClassification(
    ownershipReleasePolicy:
        CjguiInternalRendererNativeOwnershipReleasePolicy
): CjguiInternalRendererNativeTeardownFailureClassification {
    let policyReady =
        ownershipReleasePolicy
            .didPrepareRendererNativeOwnershipReleasePolicy &&
        ownershipReleasePolicy
            .didPreserveRendererNativeTeardownContractIntent &&
        ownershipReleasePolicy.didDefineOwnerLocalReleaseOrdering &&
        ownershipReleasePolicy.didDefineIdempotentTeardownExpectation &&
        ownershipReleasePolicy.didFailClosedDoubleReleaseRisk &&
        ownershipReleasePolicy.didFailClosedDanglingResourceRisk &&
        ownershipReleasePolicy.didConfirmNoExternalLifecycleSurface &&
        ownershipReleasePolicy.didKeepNativeOwnershipReleasePolicyValueOnly &&
        ownershipReleasePolicy.didAvoidNativeLifecyclePermissionWrapper &&
        ownershipReleasePolicy.didAvoidResourceReadyWrapper &&
        ownershipReleasePolicy.didAvoidThinWrapper &&
        ownershipReleasePolicy
            .shouldDeferRendererNativeOwnershipReleasePolicy == false &&
        ownershipReleasePolicy
            .shouldReportRendererNativeOwnershipReleasePolicyBlocked == false
    let policyDeferred =
        ownershipReleasePolicy
            .didPrepareRendererNativeOwnershipReleasePolicy == false &&
        ownershipReleasePolicy.shouldDeferRendererNativeOwnershipReleasePolicy &&
        ownershipReleasePolicy
            .shouldReportRendererNativeOwnershipReleasePolicyBlocked == false
    let policyInconsistent =
        ownershipReleasePolicy
            .shouldReportRendererNativeOwnershipReleasePolicyBlocked ||
        (
            ownershipReleasePolicy
                .didPrepareRendererNativeOwnershipReleasePolicy &&
            policyReady == false
        ) ||
        (
            ownershipReleasePolicy
                .didPreserveRendererNativeTeardownContractIntent &&
            ownershipReleasePolicy
                .didPrepareRendererNativeOwnershipReleasePolicy == false
        )

    if (policyInconsistent) {
        return CjguiInternalRendererNativeTeardownFailureClassification(
            ownershipReleasePolicy,
            false,
            false,
            true,
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

    if (policyReady) {
        return CjguiInternalRendererNativeTeardownFailureClassification(
            ownershipReleasePolicy,
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

    if (policyDeferred) {
        return CjguiInternalRendererNativeTeardownFailureClassification(
            ownershipReleasePolicy,
            false,
            true,
            false,
            false,
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

    return CjguiInternalRendererNativeTeardownFailureClassification(
        ownershipReleasePolicy,
        false,
        false,
        true,
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

func cjguiInternalBuildRendererNativeMainThreadConfinementGuard(
    failureClassification:
        CjguiInternalRendererNativeTeardownFailureClassification
): CjguiInternalRendererNativeMainThreadConfinementGuard {
    let classificationReady =
        failureClassification
            .didPrepareRendererNativeTeardownFailureClassification &&
        failureClassification
            .didPreserveRendererNativeOwnershipReleasePolicy &&
        failureClassification.didDefineOwnerLocalFailureClassification &&
        failureClassification.didClassifyCreateUnavailableAsFailClosed &&
        failureClassification.didClassifyReleaseFailureAsFailClosed &&
        failureClassification.didClassifyAlreadyClosedAsFailClosed &&
        failureClassification.didClassifyStaleResourceAsFailClosed &&
        failureClassification.didClassifyBridgeOptimismAsFailClosed &&
        failureClassification
            .didKeepNativeTeardownFailureClassificationValueOnly &&
        failureClassification.didAvoidFailurePublicationWrapper &&
        failureClassification.didAvoidPublicDiagnosticsWrapper &&
        failureClassification.didAvoidThinWrapper &&
        failureClassification
            .shouldDeferRendererNativeTeardownFailureClassification ==
            false &&
        failureClassification
            .shouldReportRendererNativeTeardownFailureClassificationBlocked ==
            false
    let classificationDeferred =
        failureClassification
            .didPrepareRendererNativeTeardownFailureClassification ==
            false &&
        failureClassification
            .shouldDeferRendererNativeTeardownFailureClassification &&
        failureClassification
            .shouldReportRendererNativeTeardownFailureClassificationBlocked ==
            false
    let classificationInconsistent =
        failureClassification
            .shouldReportRendererNativeTeardownFailureClassificationBlocked ||
        (
            failureClassification
                .didPrepareRendererNativeTeardownFailureClassification &&
            classificationReady == false
        ) ||
        (
            failureClassification
                .didPreserveRendererNativeOwnershipReleasePolicy &&
            failureClassification
                .didPrepareRendererNativeTeardownFailureClassification ==
                false
        )

    if (classificationInconsistent) {
        return CjguiInternalRendererNativeMainThreadConfinementGuard(
            failureClassification,
            false,
            false,
            true,
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

    if (classificationReady) {
        return CjguiInternalRendererNativeMainThreadConfinementGuard(
            failureClassification,
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

    if (classificationDeferred) {
        return CjguiInternalRendererNativeMainThreadConfinementGuard(
            failureClassification,
            false,
            true,
            false,
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

    return CjguiInternalRendererNativeMainThreadConfinementGuard(
        failureClassification,
        false,
        false,
        true,
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

func cjguiInternalBuildRendererNoNativeTeardownImplementationReadiness(
    confinementGuard:
        CjguiInternalRendererNativeMainThreadConfinementGuard
): CjguiInternalRendererNoNativeTeardownImplementationReadiness {
    let guardReady =
        confinementGuard
            .didPrepareRendererNativeMainThreadConfinementGuard &&
        confinementGuard
            .didPreserveRendererNativeTeardownFailureClassification &&
        confinementGuard.didDefineOwnerLocalMainThreadConfinement &&
        confinementGuard.didClassifyWrongThreadAsFailClosed &&
        confinementGuard.didRequireLifecycleFactsToStayDehydrated &&
        confinementGuard.didConfirmNoStateMutation &&
        confinementGuard.didConfirmNoPublicSurface &&
        confinementGuard.didKeepNativeMainThreadConfinementGuardValueOnly &&
        confinementGuard.didAvoidThreadPermissionWrapper &&
        confinementGuard.didAvoidExternalLifecycleWrapper &&
        confinementGuard.didAvoidThinWrapper &&
        confinementGuard
            .shouldDeferRendererNativeMainThreadConfinementGuard == false &&
        confinementGuard
            .shouldReportRendererNativeMainThreadConfinementGuardBlocked ==
            false
    let guardDeferred =
        confinementGuard
            .didPrepareRendererNativeMainThreadConfinementGuard == false &&
        confinementGuard.shouldDeferRendererNativeMainThreadConfinementGuard &&
        confinementGuard
            .shouldReportRendererNativeMainThreadConfinementGuardBlocked ==
            false
    let guardInconsistent =
        confinementGuard
            .shouldReportRendererNativeMainThreadConfinementGuardBlocked ||
        (
            confinementGuard
                .didPrepareRendererNativeMainThreadConfinementGuard &&
            guardReady == false
        ) ||
        (
            confinementGuard
                .didPreserveRendererNativeTeardownFailureClassification &&
            confinementGuard
                .didPrepareRendererNativeMainThreadConfinementGuard == false
        )

    if (guardInconsistent) {
        return CjguiInternalRendererNoNativeTeardownImplementationReadiness(
            confinementGuard,
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
            true
        )
    }

    if (guardReady) {
        return CjguiInternalRendererNoNativeTeardownImplementationReadiness(
            confinementGuard,
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
            true
        )
    }

    if (guardDeferred) {
        return CjguiInternalRendererNoNativeTeardownImplementationReadiness(
            confinementGuard,
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
            true
        )
    }

    return CjguiInternalRendererNoNativeTeardownImplementationReadiness(
        confinementGuard,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft():
    CjguiInternalRendererNoNativeTeardownImplementationReadiness {
    let noRealBackendPlatformObjectReadiness =
        cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()
    let teardownIntent =
        cjguiInternalBuildRendererNativeTeardownContractIntent(
            noRealBackendPlatformObjectReadiness
        )
    let releasePolicy =
        cjguiInternalBuildRendererNativeOwnershipReleasePolicy(
            teardownIntent
        )
    let failureClassification =
        cjguiInternalBuildRendererNativeTeardownFailureClassification(
            releasePolicy
        )
    let confinementGuard =
        cjguiInternalBuildRendererNativeMainThreadConfinementGuard(
            failureClassification
        )
    return cjguiInternalBuildRendererNoNativeTeardownImplementationReadiness(
        confinementGuard
    )
}
