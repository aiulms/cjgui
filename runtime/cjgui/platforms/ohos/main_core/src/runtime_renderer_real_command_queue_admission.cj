package cjgui

struct CjguiInternalRendererRealCommandQueueImplementationIntent {
    let noMetalDeviceLayerImplementationReadiness:
        CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness
    let didPrepareRendererRealCommandQueueImplementationIntent: Bool
    let shouldDeferRendererRealCommandQueueImplementationIntent: Bool
    let shouldReportRendererRealCommandQueueImplementationIntentBlocked: Bool
    let didPreserveRendererNoMetalDeviceLayerImplementationReadiness: Bool
    let didDefineFutureRealCommandQueueImplementationIntent: Bool
    let didDescribeQueueCreationAdmissionNeed: Bool
    let didDescribeQueueOwnershipAdmissionNeed: Bool
    let didDescribeQueueTeardownFailureNeed: Bool
    let didKeepRealCommandQueueImplementationIntentValueOnly: Bool
    let didAvoidQueueReadyPermissionWrapper: Bool
    let didAvoidResourceTokenWrapper: Bool
    let didAvoidBackendImplementationWrapper: Bool
    let didAvoidWorkSubmitWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        noMetalDeviceLayerImplementationReadiness:
            CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness,
        didPrepareRendererRealCommandQueueImplementationIntent: Bool,
        shouldDeferRendererRealCommandQueueImplementationIntent: Bool,
        shouldReportRendererRealCommandQueueImplementationIntentBlocked: Bool,
        didPreserveRendererNoMetalDeviceLayerImplementationReadiness: Bool,
        didDefineFutureRealCommandQueueImplementationIntent: Bool,
        didDescribeQueueCreationAdmissionNeed: Bool,
        didDescribeQueueOwnershipAdmissionNeed: Bool,
        didDescribeQueueTeardownFailureNeed: Bool,
        didKeepRealCommandQueueImplementationIntentValueOnly: Bool,
        didAvoidQueueReadyPermissionWrapper: Bool,
        didAvoidResourceTokenWrapper: Bool,
        didAvoidBackendImplementationWrapper: Bool,
        didAvoidWorkSubmitWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noMetalDeviceLayerImplementationReadiness =
            noMetalDeviceLayerImplementationReadiness
        this.didPrepareRendererRealCommandQueueImplementationIntent =
            didPrepareRendererRealCommandQueueImplementationIntent
        this.shouldDeferRendererRealCommandQueueImplementationIntent =
            shouldDeferRendererRealCommandQueueImplementationIntent
        this.shouldReportRendererRealCommandQueueImplementationIntentBlocked =
            shouldReportRendererRealCommandQueueImplementationIntentBlocked
        this.didPreserveRendererNoMetalDeviceLayerImplementationReadiness =
            didPreserveRendererNoMetalDeviceLayerImplementationReadiness
        this.didDefineFutureRealCommandQueueImplementationIntent =
            didDefineFutureRealCommandQueueImplementationIntent
        this.didDescribeQueueCreationAdmissionNeed =
            didDescribeQueueCreationAdmissionNeed
        this.didDescribeQueueOwnershipAdmissionNeed =
            didDescribeQueueOwnershipAdmissionNeed
        this.didDescribeQueueTeardownFailureNeed =
            didDescribeQueueTeardownFailureNeed
        this.didKeepRealCommandQueueImplementationIntentValueOnly =
            didKeepRealCommandQueueImplementationIntentValueOnly
        this.didAvoidQueueReadyPermissionWrapper = didAvoidQueueReadyPermissionWrapper
        this.didAvoidResourceTokenWrapper = didAvoidResourceTokenWrapper
        this.didAvoidBackendImplementationWrapper = didAvoidBackendImplementationWrapper
        this.didAvoidWorkSubmitWrapper = didAvoidWorkSubmitWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealCommandQueueCreationAdmissionPolicy {
    let implementationIntent: CjguiInternalRendererRealCommandQueueImplementationIntent
    let didPrepareRendererRealCommandQueueCreationAdmissionPolicy: Bool
    let shouldDeferRendererRealCommandQueueCreationAdmissionPolicy: Bool
    let shouldReportRendererRealCommandQueueCreationAdmissionPolicyBlocked: Bool
    let didPreserveRendererRealCommandQueueImplementationIntent: Bool
    let didDefineFutureQueueCreationAdmissionPolicy: Bool
    let didDescribeDeviceRelationAdmissionFacts: Bool
    let didDescribeQueueFactoryAdmissionFacts: Bool
    let didDescribeNoQueueAvailabilityFacts: Bool
    let didConfirmNoQueueCreation: Bool
    let didConfirmNoQueueFactoryCall: Bool
    let didConfirmNoCommandBufferCreation: Bool
    let didKeepQueueCreationAdmissionPolicyValueOnly: Bool
    let didAvoidQueueReadyPermissionWrapper: Bool
    let didAvoidExternalCallSurface: Bool
    let didAvoidDeviceReadyPermissionWrapper: Bool

    init(
        implementationIntent: CjguiInternalRendererRealCommandQueueImplementationIntent,
        didPrepareRendererRealCommandQueueCreationAdmissionPolicy: Bool,
        shouldDeferRendererRealCommandQueueCreationAdmissionPolicy: Bool,
        shouldReportRendererRealCommandQueueCreationAdmissionPolicyBlocked: Bool,
        didPreserveRendererRealCommandQueueImplementationIntent: Bool,
        didDefineFutureQueueCreationAdmissionPolicy: Bool,
        didDescribeDeviceRelationAdmissionFacts: Bool,
        didDescribeQueueFactoryAdmissionFacts: Bool,
        didDescribeNoQueueAvailabilityFacts: Bool,
        didConfirmNoQueueCreation: Bool,
        didConfirmNoQueueFactoryCall: Bool,
        didConfirmNoCommandBufferCreation: Bool,
        didKeepQueueCreationAdmissionPolicyValueOnly: Bool,
        didAvoidQueueReadyPermissionWrapper: Bool,
        didAvoidExternalCallSurface: Bool,
        didAvoidDeviceReadyPermissionWrapper: Bool
    ) {
        this.implementationIntent = implementationIntent
        this.didPrepareRendererRealCommandQueueCreationAdmissionPolicy =
            didPrepareRendererRealCommandQueueCreationAdmissionPolicy
        this.shouldDeferRendererRealCommandQueueCreationAdmissionPolicy =
            shouldDeferRendererRealCommandQueueCreationAdmissionPolicy
        this.shouldReportRendererRealCommandQueueCreationAdmissionPolicyBlocked =
            shouldReportRendererRealCommandQueueCreationAdmissionPolicyBlocked
        this.didPreserveRendererRealCommandQueueImplementationIntent =
            didPreserveRendererRealCommandQueueImplementationIntent
        this.didDefineFutureQueueCreationAdmissionPolicy =
            didDefineFutureQueueCreationAdmissionPolicy
        this.didDescribeDeviceRelationAdmissionFacts =
            didDescribeDeviceRelationAdmissionFacts
        this.didDescribeQueueFactoryAdmissionFacts = didDescribeQueueFactoryAdmissionFacts
        this.didDescribeNoQueueAvailabilityFacts =
            didDescribeNoQueueAvailabilityFacts
        this.didConfirmNoQueueCreation = didConfirmNoQueueCreation
        this.didConfirmNoQueueFactoryCall = didConfirmNoQueueFactoryCall
        this.didConfirmNoCommandBufferCreation = didConfirmNoCommandBufferCreation
        this.didKeepQueueCreationAdmissionPolicyValueOnly =
            didKeepQueueCreationAdmissionPolicyValueOnly
        this.didAvoidQueueReadyPermissionWrapper = didAvoidQueueReadyPermissionWrapper
        this.didAvoidExternalCallSurface = didAvoidExternalCallSurface
        this.didAvoidDeviceReadyPermissionWrapper = didAvoidDeviceReadyPermissionWrapper
    }
}

struct CjguiInternalRendererRealCommandQueueOwnershipAdmissionGuard {
    let creationAdmissionPolicy: CjguiInternalRendererRealCommandQueueCreationAdmissionPolicy
    let didPrepareRendererRealCommandQueueOwnershipAdmissionGuard: Bool
    let shouldDeferRendererRealCommandQueueOwnershipAdmissionGuard: Bool
    let shouldReportRendererRealCommandQueueOwnershipAdmissionGuardBlocked: Bool
    let didPreserveRendererRealCommandQueueCreationAdmissionPolicy: Bool
    let didDefineFutureQueueOwnershipAdmissionGuard: Bool
    let didDescribeOwnerLocalQueueAdmissionFacts: Bool
    let didDescribeNoResourceExportFacts: Bool
    let didDescribeNoPointerResourceFacts: Bool
    let didConfirmNoQueueResourceStored: Bool
    let didConfirmNoForeignResourceToken: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didKeepQueueOwnershipAdmissionGuardValueOnly: Bool
    let didAvoidResourceTokenWrapper: Bool
    let didAvoidBackendImplementationWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        creationAdmissionPolicy: CjguiInternalRendererRealCommandQueueCreationAdmissionPolicy,
        didPrepareRendererRealCommandQueueOwnershipAdmissionGuard: Bool,
        shouldDeferRendererRealCommandQueueOwnershipAdmissionGuard: Bool,
        shouldReportRendererRealCommandQueueOwnershipAdmissionGuardBlocked: Bool,
        didPreserveRendererRealCommandQueueCreationAdmissionPolicy: Bool,
        didDefineFutureQueueOwnershipAdmissionGuard: Bool,
        didDescribeOwnerLocalQueueAdmissionFacts: Bool,
        didDescribeNoResourceExportFacts: Bool,
        didDescribeNoPointerResourceFacts: Bool,
        didConfirmNoQueueResourceStored: Bool,
        didConfirmNoForeignResourceToken: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didKeepQueueOwnershipAdmissionGuardValueOnly: Bool,
        didAvoidResourceTokenWrapper: Bool,
        didAvoidBackendImplementationWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.creationAdmissionPolicy = creationAdmissionPolicy
        this.didPrepareRendererRealCommandQueueOwnershipAdmissionGuard =
            didPrepareRendererRealCommandQueueOwnershipAdmissionGuard
        this.shouldDeferRendererRealCommandQueueOwnershipAdmissionGuard =
            shouldDeferRendererRealCommandQueueOwnershipAdmissionGuard
        this.shouldReportRendererRealCommandQueueOwnershipAdmissionGuardBlocked =
            shouldReportRendererRealCommandQueueOwnershipAdmissionGuardBlocked
        this.didPreserveRendererRealCommandQueueCreationAdmissionPolicy =
            didPreserveRendererRealCommandQueueCreationAdmissionPolicy
        this.didDefineFutureQueueOwnershipAdmissionGuard =
            didDefineFutureQueueOwnershipAdmissionGuard
        this.didDescribeOwnerLocalQueueAdmissionFacts =
            didDescribeOwnerLocalQueueAdmissionFacts
        this.didDescribeNoResourceExportFacts = didDescribeNoResourceExportFacts
        this.didDescribeNoPointerResourceFacts = didDescribeNoPointerResourceFacts
        this.didConfirmNoQueueResourceStored = didConfirmNoQueueResourceStored
        this.didConfirmNoForeignResourceToken = didConfirmNoForeignResourceToken
        this.didConfirmNoPointerLikeResource = didConfirmNoPointerLikeResource
        this.didKeepQueueOwnershipAdmissionGuardValueOnly =
            didKeepQueueOwnershipAdmissionGuardValueOnly
        this.didAvoidResourceTokenWrapper = didAvoidResourceTokenWrapper
        this.didAvoidBackendImplementationWrapper = didAvoidBackendImplementationWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
    }
}

struct CjguiInternalRendererRealCommandQueueTeardownFailurePolicy {
    let ownershipAdmissionGuard: CjguiInternalRendererRealCommandQueueOwnershipAdmissionGuard
    let didPrepareRendererRealCommandQueueTeardownFailurePolicy: Bool
    let shouldDeferRendererRealCommandQueueTeardownFailurePolicy: Bool
    let shouldReportRendererRealCommandQueueTeardownFailurePolicyBlocked: Bool
    let didPreserveRendererRealCommandQueueOwnershipAdmissionGuard: Bool
    let didDefineFutureQueueTeardownFailurePolicy: Bool
    let didDescribeFutureQueueShutdownOrderingFacts: Bool
    let didDescribeFailureRollbackFacts: Bool
    let didDescribeNoQueueCleanupInvocationFacts: Bool
    let didConfirmNoForeignLifecycleCall: Bool
    let didConfirmNoBridgeInvocation: Bool
    let didConfirmNoStateMutation: Bool
    let didKeepQueueTeardownFailurePolicyValueOnly: Bool
    let didAvoidWorkSubmitWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidStateWriteWrapper: Bool

    init(
        ownershipAdmissionGuard: CjguiInternalRendererRealCommandQueueOwnershipAdmissionGuard,
        didPrepareRendererRealCommandQueueTeardownFailurePolicy: Bool,
        shouldDeferRendererRealCommandQueueTeardownFailurePolicy: Bool,
        shouldReportRendererRealCommandQueueTeardownFailurePolicyBlocked: Bool,
        didPreserveRendererRealCommandQueueOwnershipAdmissionGuard: Bool,
        didDefineFutureQueueTeardownFailurePolicy: Bool,
        didDescribeFutureQueueShutdownOrderingFacts: Bool,
        didDescribeFailureRollbackFacts: Bool,
        didDescribeNoQueueCleanupInvocationFacts: Bool,
        didConfirmNoForeignLifecycleCall: Bool,
        didConfirmNoBridgeInvocation: Bool,
        didConfirmNoStateMutation: Bool,
        didKeepQueueTeardownFailurePolicyValueOnly: Bool,
        didAvoidWorkSubmitWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidStateWriteWrapper: Bool
    ) {
        this.ownershipAdmissionGuard = ownershipAdmissionGuard
        this.didPrepareRendererRealCommandQueueTeardownFailurePolicy =
            didPrepareRendererRealCommandQueueTeardownFailurePolicy
        this.shouldDeferRendererRealCommandQueueTeardownFailurePolicy =
            shouldDeferRendererRealCommandQueueTeardownFailurePolicy
        this.shouldReportRendererRealCommandQueueTeardownFailurePolicyBlocked =
            shouldReportRendererRealCommandQueueTeardownFailurePolicyBlocked
        this.didPreserveRendererRealCommandQueueOwnershipAdmissionGuard =
            didPreserveRendererRealCommandQueueOwnershipAdmissionGuard
        this.didDefineFutureQueueTeardownFailurePolicy =
            didDefineFutureQueueTeardownFailurePolicy
        this.didDescribeFutureQueueShutdownOrderingFacts =
            didDescribeFutureQueueShutdownOrderingFacts
        this.didDescribeFailureRollbackFacts = didDescribeFailureRollbackFacts
        this.didDescribeNoQueueCleanupInvocationFacts =
            didDescribeNoQueueCleanupInvocationFacts
        this.didConfirmNoForeignLifecycleCall = didConfirmNoForeignLifecycleCall
        this.didConfirmNoBridgeInvocation = didConfirmNoBridgeInvocation
        this.didConfirmNoStateMutation = didConfirmNoStateMutation
        this.didKeepQueueTeardownFailurePolicyValueOnly =
            didKeepQueueTeardownFailurePolicyValueOnly
        this.didAvoidWorkSubmitWrapper = didAvoidWorkSubmitWrapper
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidStateWriteWrapper = didAvoidStateWriteWrapper
    }
}

struct CjguiInternalRendererNoRealCommandQueueImplementationReadiness {
    let teardownFailurePolicy: CjguiInternalRendererRealCommandQueueTeardownFailurePolicy
    let isRendererNoRealCommandQueueImplementationReady: Bool
    let canFutureRendererRealCommandQueueImplementationBoundaryEvaluate: Bool
    let shouldDeferRendererNoRealCommandQueueImplementationReadiness: Bool
    let shouldReportRendererNoRealCommandQueueImplementationReadinessBlocked: Bool
    let didSealRendererNoRealCommandQueueImplementationReadiness: Bool
    let didPreserveRendererRealCommandQueueTeardownFailurePolicy: Bool
    let didKeepNoRealCommandQueueImplementationReadinessValueOnly: Bool
    let didConfirmNoQueueCreated: Bool
    let didConfirmNoQueueFactoryCall: Bool
    let didConfirmNoCommandBufferCreated: Bool
    let didConfirmNoDrawableAcquired: Bool
    let didConfirmNoDeviceOrLayerCreated: Bool
    let didConfirmNoPlatformObjectCreated: Bool
    let didConfirmNoResourceToken: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didConfirmNoForeignFunctionDeclaration: Bool
    let didConfirmNoExternalAbiSurface: Bool
    let didConfirmNoBridgeInvocation: Bool
    let didConfirmNoForeignLifecycleCall: Bool
    let didConfirmNoWorkSubmit: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoRendererStateMutation: Bool
    let didConfirmNoExternalApiSurface: Bool
    let didAvoidQueueReadyPermissionWrapper: Bool
    let didAvoidResourceTokenWrapper: Bool
    let didAvoidExternalAbiPermissionWrapper: Bool
    let didAvoidDevicePermissionWrapper: Bool
    let didAvoidBackendImplementationWrapper: Bool
    let didAvoidWorkSubmitWrapper: Bool
    let didAvoidBufferReadyWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidStateWriteWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        teardownFailurePolicy: CjguiInternalRendererRealCommandQueueTeardownFailurePolicy,
        isRendererNoRealCommandQueueImplementationReady: Bool,
        canFutureRendererRealCommandQueueImplementationBoundaryEvaluate: Bool,
        shouldDeferRendererNoRealCommandQueueImplementationReadiness: Bool,
        shouldReportRendererNoRealCommandQueueImplementationReadinessBlocked: Bool,
        didSealRendererNoRealCommandQueueImplementationReadiness: Bool,
        didPreserveRendererRealCommandQueueTeardownFailurePolicy: Bool,
        didKeepNoRealCommandQueueImplementationReadinessValueOnly: Bool,
        didConfirmNoQueueCreated: Bool,
        didConfirmNoQueueFactoryCall: Bool,
        didConfirmNoCommandBufferCreated: Bool,
        didConfirmNoDrawableAcquired: Bool,
        didConfirmNoDeviceOrLayerCreated: Bool,
        didConfirmNoPlatformObjectCreated: Bool,
        didConfirmNoResourceToken: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didConfirmNoForeignFunctionDeclaration: Bool,
        didConfirmNoExternalAbiSurface: Bool,
        didConfirmNoBridgeInvocation: Bool,
        didConfirmNoForeignLifecycleCall: Bool,
        didConfirmNoWorkSubmit: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoRendererStateMutation: Bool,
        didConfirmNoExternalApiSurface: Bool,
        didAvoidQueueReadyPermissionWrapper: Bool,
        didAvoidResourceTokenWrapper: Bool,
        didAvoidExternalAbiPermissionWrapper: Bool,
        didAvoidDevicePermissionWrapper: Bool,
        didAvoidBackendImplementationWrapper: Bool,
        didAvoidWorkSubmitWrapper: Bool,
        didAvoidBufferReadyWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidStateWriteWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.teardownFailurePolicy = teardownFailurePolicy
        this.isRendererNoRealCommandQueueImplementationReady =
            isRendererNoRealCommandQueueImplementationReady
        this.canFutureRendererRealCommandQueueImplementationBoundaryEvaluate =
            canFutureRendererRealCommandQueueImplementationBoundaryEvaluate
        this.shouldDeferRendererNoRealCommandQueueImplementationReadiness =
            shouldDeferRendererNoRealCommandQueueImplementationReadiness
        this.shouldReportRendererNoRealCommandQueueImplementationReadinessBlocked =
            shouldReportRendererNoRealCommandQueueImplementationReadinessBlocked
        this.didSealRendererNoRealCommandQueueImplementationReadiness =
            didSealRendererNoRealCommandQueueImplementationReadiness
        this.didPreserveRendererRealCommandQueueTeardownFailurePolicy =
            didPreserveRendererRealCommandQueueTeardownFailurePolicy
        this.didKeepNoRealCommandQueueImplementationReadinessValueOnly =
            didKeepNoRealCommandQueueImplementationReadinessValueOnly
        this.didConfirmNoQueueCreated = didConfirmNoQueueCreated
        this.didConfirmNoQueueFactoryCall = didConfirmNoQueueFactoryCall
        this.didConfirmNoCommandBufferCreated = didConfirmNoCommandBufferCreated
        this.didConfirmNoDrawableAcquired = didConfirmNoDrawableAcquired
        this.didConfirmNoDeviceOrLayerCreated = didConfirmNoDeviceOrLayerCreated
        this.didConfirmNoPlatformObjectCreated = didConfirmNoPlatformObjectCreated
        this.didConfirmNoResourceToken = didConfirmNoResourceToken
        this.didConfirmNoPointerLikeResource = didConfirmNoPointerLikeResource
        this.didConfirmNoForeignFunctionDeclaration = didConfirmNoForeignFunctionDeclaration
        this.didConfirmNoExternalAbiSurface = didConfirmNoExternalAbiSurface
        this.didConfirmNoBridgeInvocation = didConfirmNoBridgeInvocation
        this.didConfirmNoForeignLifecycleCall = didConfirmNoForeignLifecycleCall
        this.didConfirmNoWorkSubmit = didConfirmNoWorkSubmit
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoRendererStateMutation = didConfirmNoRendererStateMutation
        this.didConfirmNoExternalApiSurface = didConfirmNoExternalApiSurface
        this.didAvoidQueueReadyPermissionWrapper = didAvoidQueueReadyPermissionWrapper
        this.didAvoidResourceTokenWrapper = didAvoidResourceTokenWrapper
        this.didAvoidExternalAbiPermissionWrapper = didAvoidExternalAbiPermissionWrapper
        this.didAvoidDevicePermissionWrapper = didAvoidDevicePermissionWrapper
        this.didAvoidBackendImplementationWrapper = didAvoidBackendImplementationWrapper
        this.didAvoidWorkSubmitWrapper = didAvoidWorkSubmitWrapper
        this.didAvoidBufferReadyWrapper = didAvoidBufferReadyWrapper
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidStateWriteWrapper = didAvoidStateWriteWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererRealCommandQueueImplementationIntent(
    noMetalDeviceLayerImplementationReadiness:
        CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness
): CjguiInternalRendererRealCommandQueueImplementationIntent {
    let upstreamReady =
        noMetalDeviceLayerImplementationReadiness.isRendererNoMetalDeviceLayerImplementationReady &&
        noMetalDeviceLayerImplementationReadiness
            .canFutureRendererMetalDeviceLayerImplementationBoundaryEvaluate &&
        noMetalDeviceLayerImplementationReadiness
            .didSealRendererNoMetalDeviceLayerImplementationReadiness &&
        noMetalDeviceLayerImplementationReadiness
            .didPreserveRendererMetalScaleColorSpaceAdmissionPolicy &&
        noMetalDeviceLayerImplementationReadiness
            .didKeepNoMetalDeviceLayerImplementationReadinessValueOnly &&
        noMetalDeviceLayerImplementationReadiness.didConfirmNoMetalDeviceCreation &&
        noMetalDeviceLayerImplementationReadiness.didConfirmNoMetalLayerCreation &&
        noMetalDeviceLayerImplementationReadiness.didConfirmNoMetalLayerBinding &&
        noMetalDeviceLayerImplementationReadiness.didConfirmNoPlatformObjectCreation &&
        noMetalDeviceLayerImplementationReadiness.didConfirmNoNativeResourceHandle &&
        noMetalDeviceLayerImplementationReadiness.didConfirmNoPointerLikeResource &&
        noMetalDeviceLayerImplementationReadiness.didConfirmNoForeignResourceToken &&
        noMetalDeviceLayerImplementationReadiness.didConfirmNoHandleExposure &&
        noMetalDeviceLayerImplementationReadiness.didConfirmNoForeignFunctionDeclaration &&
        noMetalDeviceLayerImplementationReadiness.didConfirmNoExternalAbiSurface &&
        noMetalDeviceLayerImplementationReadiness.didConfirmNoBridgeCall &&
        noMetalDeviceLayerImplementationReadiness.didConfirmNoRetainReleaseDestroy &&
        noMetalDeviceLayerImplementationReadiness.didConfirmNoDeviceQueryCall &&
        noMetalDeviceLayerImplementationReadiness.didConfirmNoCommandQueueCreation &&
        noMetalDeviceLayerImplementationReadiness.didConfirmNoDrawableAcquisition &&
        noMetalDeviceLayerImplementationReadiness.didConfirmNoCommandBufferCreation &&
        noMetalDeviceLayerImplementationReadiness.didConfirmNoWorkSubmit &&
        noMetalDeviceLayerImplementationReadiness.didConfirmNoRenderExecution &&
        noMetalDeviceLayerImplementationReadiness.didConfirmNoRendererStateMutation &&
        noMetalDeviceLayerImplementationReadiness.didConfirmNoExternalApiSurface &&
        noMetalDeviceLayerImplementationReadiness.didAvoidDeviceReadyPermissionWrapper &&
        noMetalDeviceLayerImplementationReadiness.didAvoidNativeHandlePermissionWrapper &&
        noMetalDeviceLayerImplementationReadiness.didAvoidCAbiFfiPermissionWrapper &&
        noMetalDeviceLayerImplementationReadiness.didAvoidBackendImplementationWrapper &&
        noMetalDeviceLayerImplementationReadiness.didAvoidGpuSubmissionWrapper &&
        noMetalDeviceLayerImplementationReadiness.didAvoidRenderPermissionWrapper &&
        noMetalDeviceLayerImplementationReadiness.didAvoidRendererStateWriteWrapper &&
        noMetalDeviceLayerImplementationReadiness.didAvoidReceiptRecordPublication &&
        noMetalDeviceLayerImplementationReadiness.didAvoidThinWrapper &&
        noMetalDeviceLayerImplementationReadiness.didStayFullRebuildOnly &&
        noMetalDeviceLayerImplementationReadiness
            .shouldDeferRendererNoMetalDeviceLayerImplementationReadiness == false &&
        noMetalDeviceLayerImplementationReadiness
            .shouldReportRendererNoMetalDeviceLayerImplementationReadinessBlocked == false
    let upstreamDeferred =
        noMetalDeviceLayerImplementationReadiness
            .shouldDeferRendererNoMetalDeviceLayerImplementationReadiness &&
        noMetalDeviceLayerImplementationReadiness
            .shouldReportRendererNoMetalDeviceLayerImplementationReadinessBlocked == false
    let upstreamInconsistent =
        noMetalDeviceLayerImplementationReadiness
            .shouldReportRendererNoMetalDeviceLayerImplementationReadinessBlocked ||
        (
            noMetalDeviceLayerImplementationReadiness
                .canFutureRendererMetalDeviceLayerImplementationBoundaryEvaluate &&
            noMetalDeviceLayerImplementationReadiness
                .isRendererNoMetalDeviceLayerImplementationReady == false
        ) ||
        (
            noMetalDeviceLayerImplementationReadiness
                .shouldDeferRendererNoMetalDeviceLayerImplementationReadiness &&
            noMetalDeviceLayerImplementationReadiness
                .shouldReportRendererNoMetalDeviceLayerImplementationReadinessBlocked
        )

    if (upstreamInconsistent) {
        return CjguiInternalRendererRealCommandQueueImplementationIntent(
            noMetalDeviceLayerImplementationReadiness,
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
            true,
            true
        )
    }

    if (upstreamDeferred || upstreamReady == false) {
        return CjguiInternalRendererRealCommandQueueImplementationIntent(
            noMetalDeviceLayerImplementationReadiness,
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
            true,
            true
        )
    }

    return CjguiInternalRendererRealCommandQueueImplementationIntent(
        noMetalDeviceLayerImplementationReadiness,
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
        true
    )
}

func cjguiInternalBuildRendererRealCommandQueueCreationAdmissionPolicy(
    implementationIntent: CjguiInternalRendererRealCommandQueueImplementationIntent
): CjguiInternalRendererRealCommandQueueCreationAdmissionPolicy {
    let intentReady =
        implementationIntent.didPrepareRendererRealCommandQueueImplementationIntent &&
        implementationIntent.didPreserveRendererNoMetalDeviceLayerImplementationReadiness &&
        implementationIntent.didDefineFutureRealCommandQueueImplementationIntent &&
        implementationIntent.didDescribeQueueCreationAdmissionNeed &&
        implementationIntent.didDescribeQueueOwnershipAdmissionNeed &&
        implementationIntent.didDescribeQueueTeardownFailureNeed &&
        implementationIntent.didKeepRealCommandQueueImplementationIntentValueOnly &&
        implementationIntent.didAvoidQueueReadyPermissionWrapper &&
        implementationIntent.didAvoidResourceTokenWrapper &&
        implementationIntent.didAvoidBackendImplementationWrapper &&
        implementationIntent.didAvoidWorkSubmitWrapper &&
        implementationIntent.didAvoidReceiptRecordPublication &&
        implementationIntent.didAvoidThinWrapper &&
        implementationIntent.shouldDeferRendererRealCommandQueueImplementationIntent == false &&
        implementationIntent
            .shouldReportRendererRealCommandQueueImplementationIntentBlocked == false
    let intentDeferred =
        implementationIntent.shouldDeferRendererRealCommandQueueImplementationIntent &&
        implementationIntent
            .shouldReportRendererRealCommandQueueImplementationIntentBlocked == false
    let intentInconsistent =
        implementationIntent.shouldReportRendererRealCommandQueueImplementationIntentBlocked ||
        (
            implementationIntent.didPrepareRendererRealCommandQueueImplementationIntent &&
            intentReady == false
        ) ||
        (
            implementationIntent.shouldDeferRendererRealCommandQueueImplementationIntent &&
            implementationIntent
                .shouldReportRendererRealCommandQueueImplementationIntentBlocked
        )

    if (intentInconsistent) {
        return CjguiInternalRendererRealCommandQueueCreationAdmissionPolicy(
            implementationIntent,
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
            true,
            true,
            true,
            true,
            true
        )
    }

    if (intentDeferred || intentReady == false) {
        return CjguiInternalRendererRealCommandQueueCreationAdmissionPolicy(
            implementationIntent,
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
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererRealCommandQueueCreationAdmissionPolicy(
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
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererRealCommandQueueOwnershipAdmissionGuard(
    creationAdmissionPolicy: CjguiInternalRendererRealCommandQueueCreationAdmissionPolicy
): CjguiInternalRendererRealCommandQueueOwnershipAdmissionGuard {
    let creationPolicyReady =
        creationAdmissionPolicy.didPrepareRendererRealCommandQueueCreationAdmissionPolicy &&
        creationAdmissionPolicy.didPreserveRendererRealCommandQueueImplementationIntent &&
        creationAdmissionPolicy.didDefineFutureQueueCreationAdmissionPolicy &&
        creationAdmissionPolicy.didDescribeDeviceRelationAdmissionFacts &&
        creationAdmissionPolicy.didDescribeQueueFactoryAdmissionFacts &&
        creationAdmissionPolicy.didDescribeNoQueueAvailabilityFacts &&
        creationAdmissionPolicy.didConfirmNoQueueCreation &&
        creationAdmissionPolicy.didConfirmNoQueueFactoryCall &&
        creationAdmissionPolicy.didConfirmNoCommandBufferCreation &&
        creationAdmissionPolicy.didKeepQueueCreationAdmissionPolicyValueOnly &&
        creationAdmissionPolicy.didAvoidQueueReadyPermissionWrapper &&
        creationAdmissionPolicy.didAvoidExternalCallSurface &&
        creationAdmissionPolicy.didAvoidDeviceReadyPermissionWrapper &&
        creationAdmissionPolicy
            .shouldDeferRendererRealCommandQueueCreationAdmissionPolicy == false &&
        creationAdmissionPolicy
            .shouldReportRendererRealCommandQueueCreationAdmissionPolicyBlocked == false
    let creationPolicyDeferred =
        creationAdmissionPolicy.shouldDeferRendererRealCommandQueueCreationAdmissionPolicy &&
        creationAdmissionPolicy
            .shouldReportRendererRealCommandQueueCreationAdmissionPolicyBlocked == false
    let creationPolicyInconsistent =
        creationAdmissionPolicy
            .shouldReportRendererRealCommandQueueCreationAdmissionPolicyBlocked ||
        (
            creationAdmissionPolicy.didPrepareRendererRealCommandQueueCreationAdmissionPolicy &&
            creationPolicyReady == false
        ) ||
        (
            creationAdmissionPolicy.shouldDeferRendererRealCommandQueueCreationAdmissionPolicy &&
            creationAdmissionPolicy
                .shouldReportRendererRealCommandQueueCreationAdmissionPolicyBlocked
        )

    if (creationPolicyInconsistent) {
        return CjguiInternalRendererRealCommandQueueOwnershipAdmissionGuard(
            creationAdmissionPolicy,
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
            true,
            true
        )
    }

    if (creationPolicyDeferred || creationPolicyReady == false) {
        return CjguiInternalRendererRealCommandQueueOwnershipAdmissionGuard(
            creationAdmissionPolicy,
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
            true,
            true
        )
    }

    return CjguiInternalRendererRealCommandQueueOwnershipAdmissionGuard(
        creationAdmissionPolicy,
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
        true
    )
}

func cjguiInternalBuildRendererRealCommandQueueTeardownFailurePolicy(
    ownershipAdmissionGuard: CjguiInternalRendererRealCommandQueueOwnershipAdmissionGuard
): CjguiInternalRendererRealCommandQueueTeardownFailurePolicy {
    let ownershipGuardReady =
        ownershipAdmissionGuard.didPrepareRendererRealCommandQueueOwnershipAdmissionGuard &&
        ownershipAdmissionGuard.didPreserveRendererRealCommandQueueCreationAdmissionPolicy &&
        ownershipAdmissionGuard.didDefineFutureQueueOwnershipAdmissionGuard &&
        ownershipAdmissionGuard.didDescribeOwnerLocalQueueAdmissionFacts &&
        ownershipAdmissionGuard.didDescribeNoResourceExportFacts &&
        ownershipAdmissionGuard.didDescribeNoPointerResourceFacts &&
        ownershipAdmissionGuard.didConfirmNoQueueResourceStored &&
        ownershipAdmissionGuard.didConfirmNoForeignResourceToken &&
        ownershipAdmissionGuard.didConfirmNoPointerLikeResource &&
        ownershipAdmissionGuard.didKeepQueueOwnershipAdmissionGuardValueOnly &&
        ownershipAdmissionGuard.didAvoidResourceTokenWrapper &&
        ownershipAdmissionGuard.didAvoidBackendImplementationWrapper &&
        ownershipAdmissionGuard.didAvoidReceiptRecordPublication &&
        ownershipAdmissionGuard
            .shouldDeferRendererRealCommandQueueOwnershipAdmissionGuard == false &&
        ownershipAdmissionGuard
            .shouldReportRendererRealCommandQueueOwnershipAdmissionGuardBlocked == false
    let ownershipGuardDeferred =
        ownershipAdmissionGuard.shouldDeferRendererRealCommandQueueOwnershipAdmissionGuard &&
        ownershipAdmissionGuard
            .shouldReportRendererRealCommandQueueOwnershipAdmissionGuardBlocked == false
    let ownershipGuardInconsistent =
        ownershipAdmissionGuard
            .shouldReportRendererRealCommandQueueOwnershipAdmissionGuardBlocked ||
        (
            ownershipAdmissionGuard.didPrepareRendererRealCommandQueueOwnershipAdmissionGuard &&
            ownershipGuardReady == false
        ) ||
        (
            ownershipAdmissionGuard.shouldDeferRendererRealCommandQueueOwnershipAdmissionGuard &&
            ownershipAdmissionGuard
                .shouldReportRendererRealCommandQueueOwnershipAdmissionGuardBlocked
        )

    if (ownershipGuardInconsistent) {
        return CjguiInternalRendererRealCommandQueueTeardownFailurePolicy(
            ownershipAdmissionGuard,
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
            true,
            true,
            true,
            true,
            true
        )
    }

    if (ownershipGuardDeferred || ownershipGuardReady == false) {
        return CjguiInternalRendererRealCommandQueueTeardownFailurePolicy(
            ownershipAdmissionGuard,
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
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererRealCommandQueueTeardownFailurePolicy(
        ownershipAdmissionGuard,
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
        true
    )
}

func cjguiInternalBuildRendererNoRealCommandQueueImplementationReadiness(
    teardownFailurePolicy: CjguiInternalRendererRealCommandQueueTeardownFailurePolicy
): CjguiInternalRendererNoRealCommandQueueImplementationReadiness {
    let teardownPolicyReady =
        teardownFailurePolicy.didPrepareRendererRealCommandQueueTeardownFailurePolicy &&
        teardownFailurePolicy.didPreserveRendererRealCommandQueueOwnershipAdmissionGuard &&
        teardownFailurePolicy.didDefineFutureQueueTeardownFailurePolicy &&
        teardownFailurePolicy.didDescribeFutureQueueShutdownOrderingFacts &&
        teardownFailurePolicy.didDescribeFailureRollbackFacts &&
        teardownFailurePolicy.didDescribeNoQueueCleanupInvocationFacts &&
        teardownFailurePolicy.didConfirmNoForeignLifecycleCall &&
        teardownFailurePolicy.didConfirmNoBridgeInvocation &&
        teardownFailurePolicy.didConfirmNoStateMutation &&
        teardownFailurePolicy.didKeepQueueTeardownFailurePolicyValueOnly &&
        teardownFailurePolicy.didAvoidWorkSubmitWrapper &&
        teardownFailurePolicy.didAvoidRenderPermissionWrapper &&
        teardownFailurePolicy.didAvoidStateWriteWrapper &&
        teardownFailurePolicy.shouldDeferRendererRealCommandQueueTeardownFailurePolicy == false &&
        teardownFailurePolicy
            .shouldReportRendererRealCommandQueueTeardownFailurePolicyBlocked == false
    let teardownPolicyDeferred =
        teardownFailurePolicy.shouldDeferRendererRealCommandQueueTeardownFailurePolicy &&
        teardownFailurePolicy
            .shouldReportRendererRealCommandQueueTeardownFailurePolicyBlocked == false
    let teardownPolicyInconsistent =
        teardownFailurePolicy.shouldReportRendererRealCommandQueueTeardownFailurePolicyBlocked ||
        (
            teardownFailurePolicy.didPrepareRendererRealCommandQueueTeardownFailurePolicy &&
            teardownPolicyReady == false
        ) ||
        (
            teardownFailurePolicy.shouldDeferRendererRealCommandQueueTeardownFailurePolicy &&
            teardownFailurePolicy.shouldReportRendererRealCommandQueueTeardownFailurePolicyBlocked
        )

    if (teardownPolicyInconsistent) {
        return CjguiInternalRendererNoRealCommandQueueImplementationReadiness(
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
            true,
            true
        )
    }

    if (teardownPolicyDeferred || teardownPolicyReady == false) {
        return CjguiInternalRendererNoRealCommandQueueImplementationReadiness(
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
            true,
            true
        )
    }

    return CjguiInternalRendererNoRealCommandQueueImplementationReadiness(
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
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererRealCommandQueueAdmissionDraft():
    CjguiInternalRendererNoRealCommandQueueImplementationReadiness {
    let noMetalDeviceLayerImplementationReadiness =
        cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft()
    let implementationIntent =
        cjguiInternalBuildRendererRealCommandQueueImplementationIntent(
            noMetalDeviceLayerImplementationReadiness
        )
    let creationAdmissionPolicy =
        cjguiInternalBuildRendererRealCommandQueueCreationAdmissionPolicy(
            implementationIntent
        )
    let ownershipAdmissionGuard =
        cjguiInternalBuildRendererRealCommandQueueOwnershipAdmissionGuard(
            creationAdmissionPolicy
        )
    let teardownFailurePolicy =
        cjguiInternalBuildRendererRealCommandQueueTeardownFailurePolicy(
            ownershipAdmissionGuard
        )
    return cjguiInternalBuildRendererNoRealCommandQueueImplementationReadiness(
        teardownFailurePolicy
    )
}
