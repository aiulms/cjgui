package cjgui

// Owner: Renderer Metal device-layer implementation admission value boundary.
// Truth: consumes only CjguiInternalRendererNoPlatformObjectImplementationReadiness
// and emits value facts for future device/layer admission without touching real
// platform, bridge, GPU, render, or renderer state surfaces.

struct CjguiInternalRendererMetalDeviceLayerImplementationIntent {
    let noPlatformObjectImplementationReadiness: CjguiInternalRendererNoPlatformObjectImplementationReadiness
    let didPrepareRendererMetalDeviceLayerImplementationIntent: Bool
    let shouldDeferRendererMetalDeviceLayerImplementationIntent: Bool
    let shouldReportRendererMetalDeviceLayerImplementationIntentBlocked: Bool
    let didPreserveRendererNoPlatformObjectImplementationReadiness: Bool
    let didDefineFutureMetalDeviceLayerImplementationIntent: Bool
    let didDescribeDeviceCreationAdmissionNeed: Bool
    let didDescribeLayerBindingAdmissionNeed: Bool
    let didDescribeScaleColorSpaceAdmissionNeed: Bool
    let didKeepMetalDeviceLayerImplementationIntentValueOnly: Bool
    let didAvoidDeviceReadyPermissionWrapper: Bool
    let didAvoidLayerReadyPermissionWrapper: Bool
    let didAvoidDeviceLayerImplementationPermissionWrapper: Bool
    let didAvoidMetalObjectPermissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        noPlatformObjectImplementationReadiness: CjguiInternalRendererNoPlatformObjectImplementationReadiness,
        didPrepareRendererMetalDeviceLayerImplementationIntent: Bool,
        shouldDeferRendererMetalDeviceLayerImplementationIntent: Bool,
        shouldReportRendererMetalDeviceLayerImplementationIntentBlocked: Bool,
        didPreserveRendererNoPlatformObjectImplementationReadiness: Bool,
        didDefineFutureMetalDeviceLayerImplementationIntent: Bool,
        didDescribeDeviceCreationAdmissionNeed: Bool,
        didDescribeLayerBindingAdmissionNeed: Bool,
        didDescribeScaleColorSpaceAdmissionNeed: Bool,
        didKeepMetalDeviceLayerImplementationIntentValueOnly: Bool,
        didAvoidDeviceReadyPermissionWrapper: Bool,
        didAvoidLayerReadyPermissionWrapper: Bool,
        didAvoidDeviceLayerImplementationPermissionWrapper: Bool,
        didAvoidMetalObjectPermissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noPlatformObjectImplementationReadiness = noPlatformObjectImplementationReadiness
        this.didPrepareRendererMetalDeviceLayerImplementationIntent =
            didPrepareRendererMetalDeviceLayerImplementationIntent
        this.shouldDeferRendererMetalDeviceLayerImplementationIntent =
            shouldDeferRendererMetalDeviceLayerImplementationIntent
        this.shouldReportRendererMetalDeviceLayerImplementationIntentBlocked =
            shouldReportRendererMetalDeviceLayerImplementationIntentBlocked
        this.didPreserveRendererNoPlatformObjectImplementationReadiness =
            didPreserveRendererNoPlatformObjectImplementationReadiness
        this.didDefineFutureMetalDeviceLayerImplementationIntent =
            didDefineFutureMetalDeviceLayerImplementationIntent
        this.didDescribeDeviceCreationAdmissionNeed = didDescribeDeviceCreationAdmissionNeed
        this.didDescribeLayerBindingAdmissionNeed = didDescribeLayerBindingAdmissionNeed
        this.didDescribeScaleColorSpaceAdmissionNeed = didDescribeScaleColorSpaceAdmissionNeed
        this.didKeepMetalDeviceLayerImplementationIntentValueOnly =
            didKeepMetalDeviceLayerImplementationIntentValueOnly
        this.didAvoidDeviceReadyPermissionWrapper = didAvoidDeviceReadyPermissionWrapper
        this.didAvoidLayerReadyPermissionWrapper = didAvoidLayerReadyPermissionWrapper
        this.didAvoidDeviceLayerImplementationPermissionWrapper =
            didAvoidDeviceLayerImplementationPermissionWrapper
        this.didAvoidMetalObjectPermissionWrapper = didAvoidMetalObjectPermissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererMetalDeviceCreationAdmissionPolicy {
    let implementationIntent: CjguiInternalRendererMetalDeviceLayerImplementationIntent
    let didPrepareRendererMetalDeviceCreationAdmissionPolicy: Bool
    let shouldDeferRendererMetalDeviceCreationAdmissionPolicy: Bool
    let shouldReportRendererMetalDeviceCreationAdmissionPolicyBlocked: Bool
    let didPreserveRendererMetalDeviceLayerImplementationIntent: Bool
    let didDefineFutureMetalDeviceCreationAdmissionPolicy: Bool
    let didDescribeFutureDeviceSelectionFacts: Bool
    let didDescribeNoDeviceFallbackFacts: Bool
    let didConfirmNoMetalDeviceCreation: Bool
    let didConfirmNoDeviceQueryCall: Bool
    let didConfirmNoCommandQueueCreation: Bool
    let didKeepMetalDeviceCreationAdmissionPolicyValueOnly: Bool
    let didAvoidDeviceReadyPermissionWrapper: Bool
    let didAvoidNativeHandlePermissionWrapper: Bool
    let didAvoidCAbiFfiPermissionWrapper: Bool

    init(
        implementationIntent: CjguiInternalRendererMetalDeviceLayerImplementationIntent,
        didPrepareRendererMetalDeviceCreationAdmissionPolicy: Bool,
        shouldDeferRendererMetalDeviceCreationAdmissionPolicy: Bool,
        shouldReportRendererMetalDeviceCreationAdmissionPolicyBlocked: Bool,
        didPreserveRendererMetalDeviceLayerImplementationIntent: Bool,
        didDefineFutureMetalDeviceCreationAdmissionPolicy: Bool,
        didDescribeFutureDeviceSelectionFacts: Bool,
        didDescribeNoDeviceFallbackFacts: Bool,
        didConfirmNoMetalDeviceCreation: Bool,
        didConfirmNoDeviceQueryCall: Bool,
        didConfirmNoCommandQueueCreation: Bool,
        didKeepMetalDeviceCreationAdmissionPolicyValueOnly: Bool,
        didAvoidDeviceReadyPermissionWrapper: Bool,
        didAvoidNativeHandlePermissionWrapper: Bool,
        didAvoidCAbiFfiPermissionWrapper: Bool
    ) {
        this.implementationIntent = implementationIntent
        this.didPrepareRendererMetalDeviceCreationAdmissionPolicy =
            didPrepareRendererMetalDeviceCreationAdmissionPolicy
        this.shouldDeferRendererMetalDeviceCreationAdmissionPolicy =
            shouldDeferRendererMetalDeviceCreationAdmissionPolicy
        this.shouldReportRendererMetalDeviceCreationAdmissionPolicyBlocked =
            shouldReportRendererMetalDeviceCreationAdmissionPolicyBlocked
        this.didPreserveRendererMetalDeviceLayerImplementationIntent =
            didPreserveRendererMetalDeviceLayerImplementationIntent
        this.didDefineFutureMetalDeviceCreationAdmissionPolicy =
            didDefineFutureMetalDeviceCreationAdmissionPolicy
        this.didDescribeFutureDeviceSelectionFacts = didDescribeFutureDeviceSelectionFacts
        this.didDescribeNoDeviceFallbackFacts = didDescribeNoDeviceFallbackFacts
        this.didConfirmNoMetalDeviceCreation = didConfirmNoMetalDeviceCreation
        this.didConfirmNoDeviceQueryCall = didConfirmNoDeviceQueryCall
        this.didConfirmNoCommandQueueCreation = didConfirmNoCommandQueueCreation
        this.didKeepMetalDeviceCreationAdmissionPolicyValueOnly =
            didKeepMetalDeviceCreationAdmissionPolicyValueOnly
        this.didAvoidDeviceReadyPermissionWrapper = didAvoidDeviceReadyPermissionWrapper
        this.didAvoidNativeHandlePermissionWrapper = didAvoidNativeHandlePermissionWrapper
        this.didAvoidCAbiFfiPermissionWrapper = didAvoidCAbiFfiPermissionWrapper
    }
}

struct CjguiInternalRendererMetalLayerBindingAdmissionGuard {
    let deviceCreationAdmissionPolicy: CjguiInternalRendererMetalDeviceCreationAdmissionPolicy
    let didPrepareRendererMetalLayerBindingAdmissionGuard: Bool
    let shouldDeferRendererMetalLayerBindingAdmissionGuard: Bool
    let shouldReportRendererMetalLayerBindingAdmissionGuardBlocked: Bool
    let didPreserveRendererMetalDeviceCreationAdmissionPolicy: Bool
    let didDefineFutureMetalLayerBindingAdmissionGuard: Bool
    let didDescribeFutureLayerBindingFacts: Bool
    let didDescribeDrawablePoolBoundaryFacts: Bool
    let didDescribeNoLayerFallbackFacts: Bool
    let didConfirmNoMetalLayerCreation: Bool
    let didConfirmNoMetalLayerBinding: Bool
    let didConfirmNoDrawableAcquisition: Bool
    let didKeepMetalLayerBindingAdmissionGuardValueOnly: Bool
    let didAvoidLayerReadyPermissionWrapper: Bool
    let didAvoidPlatformObjectWrapper: Bool
    let didAvoidBackendImplementationWrapper: Bool

    init(
        deviceCreationAdmissionPolicy: CjguiInternalRendererMetalDeviceCreationAdmissionPolicy,
        didPrepareRendererMetalLayerBindingAdmissionGuard: Bool,
        shouldDeferRendererMetalLayerBindingAdmissionGuard: Bool,
        shouldReportRendererMetalLayerBindingAdmissionGuardBlocked: Bool,
        didPreserveRendererMetalDeviceCreationAdmissionPolicy: Bool,
        didDefineFutureMetalLayerBindingAdmissionGuard: Bool,
        didDescribeFutureLayerBindingFacts: Bool,
        didDescribeDrawablePoolBoundaryFacts: Bool,
        didDescribeNoLayerFallbackFacts: Bool,
        didConfirmNoMetalLayerCreation: Bool,
        didConfirmNoMetalLayerBinding: Bool,
        didConfirmNoDrawableAcquisition: Bool,
        didKeepMetalLayerBindingAdmissionGuardValueOnly: Bool,
        didAvoidLayerReadyPermissionWrapper: Bool,
        didAvoidPlatformObjectWrapper: Bool,
        didAvoidBackendImplementationWrapper: Bool
    ) {
        this.deviceCreationAdmissionPolicy = deviceCreationAdmissionPolicy
        this.didPrepareRendererMetalLayerBindingAdmissionGuard =
            didPrepareRendererMetalLayerBindingAdmissionGuard
        this.shouldDeferRendererMetalLayerBindingAdmissionGuard =
            shouldDeferRendererMetalLayerBindingAdmissionGuard
        this.shouldReportRendererMetalLayerBindingAdmissionGuardBlocked =
            shouldReportRendererMetalLayerBindingAdmissionGuardBlocked
        this.didPreserveRendererMetalDeviceCreationAdmissionPolicy =
            didPreserveRendererMetalDeviceCreationAdmissionPolicy
        this.didDefineFutureMetalLayerBindingAdmissionGuard =
            didDefineFutureMetalLayerBindingAdmissionGuard
        this.didDescribeFutureLayerBindingFacts = didDescribeFutureLayerBindingFacts
        this.didDescribeDrawablePoolBoundaryFacts = didDescribeDrawablePoolBoundaryFacts
        this.didDescribeNoLayerFallbackFacts = didDescribeNoLayerFallbackFacts
        this.didConfirmNoMetalLayerCreation = didConfirmNoMetalLayerCreation
        this.didConfirmNoMetalLayerBinding = didConfirmNoMetalLayerBinding
        this.didConfirmNoDrawableAcquisition = didConfirmNoDrawableAcquisition
        this.didKeepMetalLayerBindingAdmissionGuardValueOnly =
            didKeepMetalLayerBindingAdmissionGuardValueOnly
        this.didAvoidLayerReadyPermissionWrapper = didAvoidLayerReadyPermissionWrapper
        this.didAvoidPlatformObjectWrapper = didAvoidPlatformObjectWrapper
        this.didAvoidBackendImplementationWrapper = didAvoidBackendImplementationWrapper
    }
}

struct CjguiInternalRendererMetalScaleColorSpaceAdmissionPolicy {
    let layerBindingAdmissionGuard: CjguiInternalRendererMetalLayerBindingAdmissionGuard
    let didPrepareRendererMetalScaleColorSpaceAdmissionPolicy: Bool
    let shouldDeferRendererMetalScaleColorSpaceAdmissionPolicy: Bool
    let shouldReportRendererMetalScaleColorSpaceAdmissionPolicyBlocked: Bool
    let didPreserveRendererMetalLayerBindingAdmissionGuard: Bool
    let didDefineFutureMetalScaleColorSpaceAdmissionPolicy: Bool
    let didDescribeDrawableSizeAdmissionFacts: Bool
    let didDescribeBackingScaleAdmissionFacts: Bool
    let didDescribePixelFormatColorSpaceAdmissionFacts: Bool
    let didConfirmNoRealScreenQuery: Bool
    let didConfirmNoRealLayerQuery: Bool
    let didConfirmNoRealColorSpaceQuery: Bool
    let didConfirmNoRendererStateMutation: Bool
    let didKeepMetalScaleColorSpaceAdmissionPolicyValueOnly: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidRendererStateWriteWrapper: Bool

    init(
        layerBindingAdmissionGuard: CjguiInternalRendererMetalLayerBindingAdmissionGuard,
        didPrepareRendererMetalScaleColorSpaceAdmissionPolicy: Bool,
        shouldDeferRendererMetalScaleColorSpaceAdmissionPolicy: Bool,
        shouldReportRendererMetalScaleColorSpaceAdmissionPolicyBlocked: Bool,
        didPreserveRendererMetalLayerBindingAdmissionGuard: Bool,
        didDefineFutureMetalScaleColorSpaceAdmissionPolicy: Bool,
        didDescribeDrawableSizeAdmissionFacts: Bool,
        didDescribeBackingScaleAdmissionFacts: Bool,
        didDescribePixelFormatColorSpaceAdmissionFacts: Bool,
        didConfirmNoRealScreenQuery: Bool,
        didConfirmNoRealLayerQuery: Bool,
        didConfirmNoRealColorSpaceQuery: Bool,
        didConfirmNoRendererStateMutation: Bool,
        didKeepMetalScaleColorSpaceAdmissionPolicyValueOnly: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidRendererStateWriteWrapper: Bool
    ) {
        this.layerBindingAdmissionGuard = layerBindingAdmissionGuard
        this.didPrepareRendererMetalScaleColorSpaceAdmissionPolicy =
            didPrepareRendererMetalScaleColorSpaceAdmissionPolicy
        this.shouldDeferRendererMetalScaleColorSpaceAdmissionPolicy =
            shouldDeferRendererMetalScaleColorSpaceAdmissionPolicy
        this.shouldReportRendererMetalScaleColorSpaceAdmissionPolicyBlocked =
            shouldReportRendererMetalScaleColorSpaceAdmissionPolicyBlocked
        this.didPreserveRendererMetalLayerBindingAdmissionGuard =
            didPreserveRendererMetalLayerBindingAdmissionGuard
        this.didDefineFutureMetalScaleColorSpaceAdmissionPolicy =
            didDefineFutureMetalScaleColorSpaceAdmissionPolicy
        this.didDescribeDrawableSizeAdmissionFacts = didDescribeDrawableSizeAdmissionFacts
        this.didDescribeBackingScaleAdmissionFacts = didDescribeBackingScaleAdmissionFacts
        this.didDescribePixelFormatColorSpaceAdmissionFacts =
            didDescribePixelFormatColorSpaceAdmissionFacts
        this.didConfirmNoRealScreenQuery = didConfirmNoRealScreenQuery
        this.didConfirmNoRealLayerQuery = didConfirmNoRealLayerQuery
        this.didConfirmNoRealColorSpaceQuery = didConfirmNoRealColorSpaceQuery
        this.didConfirmNoRendererStateMutation = didConfirmNoRendererStateMutation
        this.didKeepMetalScaleColorSpaceAdmissionPolicyValueOnly =
            didKeepMetalScaleColorSpaceAdmissionPolicyValueOnly
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidRendererStateWriteWrapper = didAvoidRendererStateWriteWrapper
    }
}

struct CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness {
    let scaleColorSpaceAdmissionPolicy: CjguiInternalRendererMetalScaleColorSpaceAdmissionPolicy
    let isRendererNoMetalDeviceLayerImplementationReady: Bool
    let canFutureRendererMetalDeviceLayerImplementationBoundaryEvaluate: Bool
    let shouldDeferRendererNoMetalDeviceLayerImplementationReadiness: Bool
    let shouldReportRendererNoMetalDeviceLayerImplementationReadinessBlocked: Bool
    let didSealRendererNoMetalDeviceLayerImplementationReadiness: Bool
    let didPreserveRendererMetalScaleColorSpaceAdmissionPolicy: Bool
    let didKeepNoMetalDeviceLayerImplementationReadinessValueOnly: Bool
    let didConfirmNoMetalDeviceCreation: Bool
    let didConfirmNoMetalLayerCreation: Bool
    let didConfirmNoMetalLayerBinding: Bool
    let didConfirmNoPlatformObjectCreation: Bool
    let didConfirmNoNativeResourceHandle: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didConfirmNoForeignResourceToken: Bool
    let didConfirmNoHandleExposure: Bool
    let didConfirmNoForeignFunctionDeclaration: Bool
    let didConfirmNoExternalAbiSurface: Bool
    let didConfirmNoBridgeCall: Bool
    let didConfirmNoRetainReleaseDestroy: Bool
    let didConfirmNoDeviceQueryCall: Bool
    let didConfirmNoCommandQueueCreation: Bool
    let didConfirmNoDrawableAcquisition: Bool
    let didConfirmNoCommandBufferCreation: Bool
    let didConfirmNoWorkSubmit: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoRendererStateMutation: Bool
    let didConfirmNoExternalApiSurface: Bool
    let didConfirmNoRealScreenLayerColorSpaceQuery: Bool
    let didAvoidDeviceReadyPermissionWrapper: Bool
    let didAvoidLayerReadyPermissionWrapper: Bool
    let didAvoidDeviceLayerImplementationPermissionWrapper: Bool
    let didAvoidMetalObjectPermissionWrapper: Bool
    let didAvoidNativeHandlePermissionWrapper: Bool
    let didAvoidCAbiFfiPermissionWrapper: Bool
    let didAvoidPlatformObjectWrapper: Bool
    let didAvoidBackendImplementationWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidRendererStateWriteWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        scaleColorSpaceAdmissionPolicy: CjguiInternalRendererMetalScaleColorSpaceAdmissionPolicy,
        isRendererNoMetalDeviceLayerImplementationReady: Bool,
        canFutureRendererMetalDeviceLayerImplementationBoundaryEvaluate: Bool,
        shouldDeferRendererNoMetalDeviceLayerImplementationReadiness: Bool,
        shouldReportRendererNoMetalDeviceLayerImplementationReadinessBlocked: Bool,
        didSealRendererNoMetalDeviceLayerImplementationReadiness: Bool,
        didPreserveRendererMetalScaleColorSpaceAdmissionPolicy: Bool,
        didKeepNoMetalDeviceLayerImplementationReadinessValueOnly: Bool,
        didConfirmNoMetalDeviceCreation: Bool,
        didConfirmNoMetalLayerCreation: Bool,
        didConfirmNoMetalLayerBinding: Bool,
        didConfirmNoPlatformObjectCreation: Bool,
        didConfirmNoNativeResourceHandle: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didConfirmNoForeignResourceToken: Bool,
        didConfirmNoHandleExposure: Bool,
        didConfirmNoForeignFunctionDeclaration: Bool,
        didConfirmNoExternalAbiSurface: Bool,
        didConfirmNoBridgeCall: Bool,
        didConfirmNoRetainReleaseDestroy: Bool,
        didConfirmNoDeviceQueryCall: Bool,
        didConfirmNoCommandQueueCreation: Bool,
        didConfirmNoDrawableAcquisition: Bool,
        didConfirmNoCommandBufferCreation: Bool,
        didConfirmNoWorkSubmit: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoRendererStateMutation: Bool,
        didConfirmNoExternalApiSurface: Bool,
        didConfirmNoRealScreenLayerColorSpaceQuery: Bool,
        didAvoidDeviceReadyPermissionWrapper: Bool,
        didAvoidLayerReadyPermissionWrapper: Bool,
        didAvoidDeviceLayerImplementationPermissionWrapper: Bool,
        didAvoidMetalObjectPermissionWrapper: Bool,
        didAvoidNativeHandlePermissionWrapper: Bool,
        didAvoidCAbiFfiPermissionWrapper: Bool,
        didAvoidPlatformObjectWrapper: Bool,
        didAvoidBackendImplementationWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidRendererStateWriteWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.scaleColorSpaceAdmissionPolicy = scaleColorSpaceAdmissionPolicy
        this.isRendererNoMetalDeviceLayerImplementationReady =
            isRendererNoMetalDeviceLayerImplementationReady
        this.canFutureRendererMetalDeviceLayerImplementationBoundaryEvaluate =
            canFutureRendererMetalDeviceLayerImplementationBoundaryEvaluate
        this.shouldDeferRendererNoMetalDeviceLayerImplementationReadiness =
            shouldDeferRendererNoMetalDeviceLayerImplementationReadiness
        this.shouldReportRendererNoMetalDeviceLayerImplementationReadinessBlocked =
            shouldReportRendererNoMetalDeviceLayerImplementationReadinessBlocked
        this.didSealRendererNoMetalDeviceLayerImplementationReadiness =
            didSealRendererNoMetalDeviceLayerImplementationReadiness
        this.didPreserveRendererMetalScaleColorSpaceAdmissionPolicy =
            didPreserveRendererMetalScaleColorSpaceAdmissionPolicy
        this.didKeepNoMetalDeviceLayerImplementationReadinessValueOnly =
            didKeepNoMetalDeviceLayerImplementationReadinessValueOnly
        this.didConfirmNoMetalDeviceCreation = didConfirmNoMetalDeviceCreation
        this.didConfirmNoMetalLayerCreation = didConfirmNoMetalLayerCreation
        this.didConfirmNoMetalLayerBinding = didConfirmNoMetalLayerBinding
        this.didConfirmNoPlatformObjectCreation = didConfirmNoPlatformObjectCreation
        this.didConfirmNoNativeResourceHandle = didConfirmNoNativeResourceHandle
        this.didConfirmNoPointerLikeResource = didConfirmNoPointerLikeResource
        this.didConfirmNoForeignResourceToken = didConfirmNoForeignResourceToken
        this.didConfirmNoHandleExposure = didConfirmNoHandleExposure
        this.didConfirmNoForeignFunctionDeclaration = didConfirmNoForeignFunctionDeclaration
        this.didConfirmNoExternalAbiSurface = didConfirmNoExternalAbiSurface
        this.didConfirmNoBridgeCall = didConfirmNoBridgeCall
        this.didConfirmNoRetainReleaseDestroy = didConfirmNoRetainReleaseDestroy
        this.didConfirmNoDeviceQueryCall = didConfirmNoDeviceQueryCall
        this.didConfirmNoCommandQueueCreation = didConfirmNoCommandQueueCreation
        this.didConfirmNoDrawableAcquisition = didConfirmNoDrawableAcquisition
        this.didConfirmNoCommandBufferCreation = didConfirmNoCommandBufferCreation
        this.didConfirmNoWorkSubmit = didConfirmNoWorkSubmit
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoRendererStateMutation = didConfirmNoRendererStateMutation
        this.didConfirmNoExternalApiSurface = didConfirmNoExternalApiSurface
        this.didConfirmNoRealScreenLayerColorSpaceQuery =
            didConfirmNoRealScreenLayerColorSpaceQuery
        this.didAvoidDeviceReadyPermissionWrapper = didAvoidDeviceReadyPermissionWrapper
        this.didAvoidLayerReadyPermissionWrapper = didAvoidLayerReadyPermissionWrapper
        this.didAvoidDeviceLayerImplementationPermissionWrapper =
            didAvoidDeviceLayerImplementationPermissionWrapper
        this.didAvoidMetalObjectPermissionWrapper = didAvoidMetalObjectPermissionWrapper
        this.didAvoidNativeHandlePermissionWrapper = didAvoidNativeHandlePermissionWrapper
        this.didAvoidCAbiFfiPermissionWrapper = didAvoidCAbiFfiPermissionWrapper
        this.didAvoidPlatformObjectWrapper = didAvoidPlatformObjectWrapper
        this.didAvoidBackendImplementationWrapper = didAvoidBackendImplementationWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidRendererStateWriteWrapper = didAvoidRendererStateWriteWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererMetalDeviceLayerImplementationIntent(
    noPlatformObjectImplementationReadiness: CjguiInternalRendererNoPlatformObjectImplementationReadiness
): CjguiInternalRendererMetalDeviceLayerImplementationIntent {
    let upstreamReady =
        noPlatformObjectImplementationReadiness.isRendererNoPlatformObjectImplementationReady &&
        noPlatformObjectImplementationReadiness
            .canFutureRendererPlatformObjectImplementationBoundaryEvaluate &&
        noPlatformObjectImplementationReadiness.didSealRendererNoPlatformObjectImplementationReadiness &&
        noPlatformObjectImplementationReadiness
            .didPreserveRendererPlatformObjectTeardownFailurePolicy &&
        noPlatformObjectImplementationReadiness.didKeepNoPlatformObjectImplementationReadinessValueOnly &&
        noPlatformObjectImplementationReadiness.didConfirmNoPlatformObjectCreation &&
        noPlatformObjectImplementationReadiness.didConfirmNoNativeResourceHandle &&
        noPlatformObjectImplementationReadiness.didConfirmNoPointerLikeResource &&
        noPlatformObjectImplementationReadiness.didConfirmNoForeignResourceToken &&
        noPlatformObjectImplementationReadiness.didConfirmNoHandleExposure &&
        noPlatformObjectImplementationReadiness.didConfirmNoBridgeCall &&
        noPlatformObjectImplementationReadiness.didConfirmNoForeignFunctionDeclaration &&
        noPlatformObjectImplementationReadiness.didConfirmNoExternalAbiSurface &&
        noPlatformObjectImplementationReadiness.didConfirmNoRetainReleaseDestroy &&
        noPlatformObjectImplementationReadiness.didConfirmNoForeignPlatformApiCall &&
        noPlatformObjectImplementationReadiness.didConfirmNoBackendObject &&
        noPlatformObjectImplementationReadiness.didConfirmNoWorkSubmit &&
        noPlatformObjectImplementationReadiness.didConfirmNoRenderExecution &&
        noPlatformObjectImplementationReadiness.didConfirmNoRendererStateMutation &&
        noPlatformObjectImplementationReadiness.didConfirmNoExternalApiSurface &&
        noPlatformObjectImplementationReadiness.didAvoidPlatformObjectPermissionWrapper &&
        noPlatformObjectImplementationReadiness.didAvoidNativeHandlePermissionWrapper &&
        noPlatformObjectImplementationReadiness.didAvoidCAbiFfiPermissionWrapper &&
        noPlatformObjectImplementationReadiness.didAvoidDeviceLayerPermissionWrapper &&
        noPlatformObjectImplementationReadiness.didAvoidBackendImplementationWrapper &&
        noPlatformObjectImplementationReadiness.didAvoidGpuSubmissionWrapper &&
        noPlatformObjectImplementationReadiness.didAvoidRenderPermissionWrapper &&
        noPlatformObjectImplementationReadiness.didAvoidRendererStateWriteWrapper &&
        noPlatformObjectImplementationReadiness.didAvoidReceiptRecordPublication &&
        noPlatformObjectImplementationReadiness.didAvoidThinWrapper &&
        noPlatformObjectImplementationReadiness.didStayFullRebuildOnly &&
        noPlatformObjectImplementationReadiness
            .shouldDeferRendererNoPlatformObjectImplementationReadiness == false &&
        noPlatformObjectImplementationReadiness
            .shouldReportRendererNoPlatformObjectImplementationReadinessBlocked == false
    let upstreamDeferred =
        noPlatformObjectImplementationReadiness
            .shouldDeferRendererNoPlatformObjectImplementationReadiness &&
        noPlatformObjectImplementationReadiness
            .shouldReportRendererNoPlatformObjectImplementationReadinessBlocked == false
    let upstreamInconsistent =
        noPlatformObjectImplementationReadiness
            .shouldReportRendererNoPlatformObjectImplementationReadinessBlocked ||
        (
            noPlatformObjectImplementationReadiness
                .canFutureRendererPlatformObjectImplementationBoundaryEvaluate &&
            noPlatformObjectImplementationReadiness.isRendererNoPlatformObjectImplementationReady == false
        ) ||
        (
            noPlatformObjectImplementationReadiness
                .shouldDeferRendererNoPlatformObjectImplementationReadiness &&
            noPlatformObjectImplementationReadiness
                .shouldReportRendererNoPlatformObjectImplementationReadinessBlocked
        )

    if (upstreamInconsistent) {
        return CjguiInternalRendererMetalDeviceLayerImplementationIntent(
            noPlatformObjectImplementationReadiness,
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
        return CjguiInternalRendererMetalDeviceLayerImplementationIntent(
            noPlatformObjectImplementationReadiness,
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

    return CjguiInternalRendererMetalDeviceLayerImplementationIntent(
        noPlatformObjectImplementationReadiness,
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

func cjguiInternalBuildRendererMetalDeviceCreationAdmissionPolicy(
    implementationIntent: CjguiInternalRendererMetalDeviceLayerImplementationIntent
): CjguiInternalRendererMetalDeviceCreationAdmissionPolicy {
    let intentReady =
        implementationIntent.didPrepareRendererMetalDeviceLayerImplementationIntent &&
        implementationIntent.didPreserveRendererNoPlatformObjectImplementationReadiness &&
        implementationIntent.didDefineFutureMetalDeviceLayerImplementationIntent &&
        implementationIntent.didDescribeDeviceCreationAdmissionNeed &&
        implementationIntent.didDescribeLayerBindingAdmissionNeed &&
        implementationIntent.didDescribeScaleColorSpaceAdmissionNeed &&
        implementationIntent.didKeepMetalDeviceLayerImplementationIntentValueOnly &&
        implementationIntent.didAvoidDeviceReadyPermissionWrapper &&
        implementationIntent.didAvoidLayerReadyPermissionWrapper &&
        implementationIntent.didAvoidDeviceLayerImplementationPermissionWrapper &&
        implementationIntent.didAvoidMetalObjectPermissionWrapper &&
        implementationIntent.didAvoidReceiptRecordPublication &&
        implementationIntent.didAvoidThinWrapper &&
        implementationIntent.shouldDeferRendererMetalDeviceLayerImplementationIntent == false &&
        implementationIntent.shouldReportRendererMetalDeviceLayerImplementationIntentBlocked == false
    let intentDeferred =
        implementationIntent.shouldDeferRendererMetalDeviceLayerImplementationIntent &&
        implementationIntent.shouldReportRendererMetalDeviceLayerImplementationIntentBlocked == false
    let intentInconsistent =
        implementationIntent.shouldReportRendererMetalDeviceLayerImplementationIntentBlocked ||
        (
            implementationIntent.didPrepareRendererMetalDeviceLayerImplementationIntent &&
            intentReady == false
        ) ||
        (
            implementationIntent.shouldDeferRendererMetalDeviceLayerImplementationIntent &&
            implementationIntent.shouldReportRendererMetalDeviceLayerImplementationIntentBlocked
        )

    if (intentInconsistent) {
        return CjguiInternalRendererMetalDeviceCreationAdmissionPolicy(
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
            true
        )
    }

    if (intentDeferred || intentReady == false) {
        return CjguiInternalRendererMetalDeviceCreationAdmissionPolicy(
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
            true
        )
    }

    return CjguiInternalRendererMetalDeviceCreationAdmissionPolicy(
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
        true
    )
}

func cjguiInternalBuildRendererMetalLayerBindingAdmissionGuard(
    deviceCreationAdmissionPolicy: CjguiInternalRendererMetalDeviceCreationAdmissionPolicy
): CjguiInternalRendererMetalLayerBindingAdmissionGuard {
    let devicePolicyReady =
        deviceCreationAdmissionPolicy.didPrepareRendererMetalDeviceCreationAdmissionPolicy &&
        deviceCreationAdmissionPolicy.didPreserveRendererMetalDeviceLayerImplementationIntent &&
        deviceCreationAdmissionPolicy.didDefineFutureMetalDeviceCreationAdmissionPolicy &&
        deviceCreationAdmissionPolicy.didDescribeFutureDeviceSelectionFacts &&
        deviceCreationAdmissionPolicy.didDescribeNoDeviceFallbackFacts &&
        deviceCreationAdmissionPolicy.didConfirmNoMetalDeviceCreation &&
        deviceCreationAdmissionPolicy.didConfirmNoDeviceQueryCall &&
        deviceCreationAdmissionPolicy.didConfirmNoCommandQueueCreation &&
        deviceCreationAdmissionPolicy.didKeepMetalDeviceCreationAdmissionPolicyValueOnly &&
        deviceCreationAdmissionPolicy.didAvoidDeviceReadyPermissionWrapper &&
        deviceCreationAdmissionPolicy.didAvoidNativeHandlePermissionWrapper &&
        deviceCreationAdmissionPolicy.didAvoidCAbiFfiPermissionWrapper &&
        deviceCreationAdmissionPolicy.shouldDeferRendererMetalDeviceCreationAdmissionPolicy == false &&
        deviceCreationAdmissionPolicy
            .shouldReportRendererMetalDeviceCreationAdmissionPolicyBlocked == false
    let devicePolicyDeferred =
        deviceCreationAdmissionPolicy.shouldDeferRendererMetalDeviceCreationAdmissionPolicy &&
        deviceCreationAdmissionPolicy
            .shouldReportRendererMetalDeviceCreationAdmissionPolicyBlocked == false
    let devicePolicyInconsistent =
        deviceCreationAdmissionPolicy.shouldReportRendererMetalDeviceCreationAdmissionPolicyBlocked ||
        (
            deviceCreationAdmissionPolicy.didPrepareRendererMetalDeviceCreationAdmissionPolicy &&
            devicePolicyReady == false
        ) ||
        (
            deviceCreationAdmissionPolicy.shouldDeferRendererMetalDeviceCreationAdmissionPolicy &&
            deviceCreationAdmissionPolicy.shouldReportRendererMetalDeviceCreationAdmissionPolicyBlocked
        )

    if (devicePolicyInconsistent) {
        return CjguiInternalRendererMetalLayerBindingAdmissionGuard(
            deviceCreationAdmissionPolicy,
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

    if (devicePolicyDeferred || devicePolicyReady == false) {
        return CjguiInternalRendererMetalLayerBindingAdmissionGuard(
            deviceCreationAdmissionPolicy,
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

    return CjguiInternalRendererMetalLayerBindingAdmissionGuard(
        deviceCreationAdmissionPolicy,
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

func cjguiInternalBuildRendererMetalScaleColorSpaceAdmissionPolicy(
    layerBindingAdmissionGuard: CjguiInternalRendererMetalLayerBindingAdmissionGuard
): CjguiInternalRendererMetalScaleColorSpaceAdmissionPolicy {
    let layerGuardReady =
        layerBindingAdmissionGuard.didPrepareRendererMetalLayerBindingAdmissionGuard &&
        layerBindingAdmissionGuard.didPreserveRendererMetalDeviceCreationAdmissionPolicy &&
        layerBindingAdmissionGuard.didDefineFutureMetalLayerBindingAdmissionGuard &&
        layerBindingAdmissionGuard.didDescribeFutureLayerBindingFacts &&
        layerBindingAdmissionGuard.didDescribeDrawablePoolBoundaryFacts &&
        layerBindingAdmissionGuard.didDescribeNoLayerFallbackFacts &&
        layerBindingAdmissionGuard.didConfirmNoMetalLayerCreation &&
        layerBindingAdmissionGuard.didConfirmNoMetalLayerBinding &&
        layerBindingAdmissionGuard.didConfirmNoDrawableAcquisition &&
        layerBindingAdmissionGuard.didKeepMetalLayerBindingAdmissionGuardValueOnly &&
        layerBindingAdmissionGuard.didAvoidLayerReadyPermissionWrapper &&
        layerBindingAdmissionGuard.didAvoidPlatformObjectWrapper &&
        layerBindingAdmissionGuard.didAvoidBackendImplementationWrapper &&
        layerBindingAdmissionGuard.shouldDeferRendererMetalLayerBindingAdmissionGuard == false &&
        layerBindingAdmissionGuard
            .shouldReportRendererMetalLayerBindingAdmissionGuardBlocked == false
    let layerGuardDeferred =
        layerBindingAdmissionGuard.shouldDeferRendererMetalLayerBindingAdmissionGuard &&
        layerBindingAdmissionGuard
            .shouldReportRendererMetalLayerBindingAdmissionGuardBlocked == false
    let layerGuardInconsistent =
        layerBindingAdmissionGuard.shouldReportRendererMetalLayerBindingAdmissionGuardBlocked ||
        (
            layerBindingAdmissionGuard.didPrepareRendererMetalLayerBindingAdmissionGuard &&
            layerGuardReady == false
        ) ||
        (
            layerBindingAdmissionGuard.shouldDeferRendererMetalLayerBindingAdmissionGuard &&
            layerBindingAdmissionGuard.shouldReportRendererMetalLayerBindingAdmissionGuardBlocked
        )

    if (layerGuardInconsistent) {
        return CjguiInternalRendererMetalScaleColorSpaceAdmissionPolicy(
            layerBindingAdmissionGuard,
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

    if (layerGuardDeferred || layerGuardReady == false) {
        return CjguiInternalRendererMetalScaleColorSpaceAdmissionPolicy(
            layerBindingAdmissionGuard,
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

    return CjguiInternalRendererMetalScaleColorSpaceAdmissionPolicy(
        layerBindingAdmissionGuard,
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

func cjguiInternalBuildRendererNoMetalDeviceLayerImplementationReadiness(
    scaleColorSpaceAdmissionPolicy: CjguiInternalRendererMetalScaleColorSpaceAdmissionPolicy
): CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness {
    let scalePolicyReady =
        scaleColorSpaceAdmissionPolicy.didPrepareRendererMetalScaleColorSpaceAdmissionPolicy &&
        scaleColorSpaceAdmissionPolicy.didPreserveRendererMetalLayerBindingAdmissionGuard &&
        scaleColorSpaceAdmissionPolicy.didDefineFutureMetalScaleColorSpaceAdmissionPolicy &&
        scaleColorSpaceAdmissionPolicy.didDescribeDrawableSizeAdmissionFacts &&
        scaleColorSpaceAdmissionPolicy.didDescribeBackingScaleAdmissionFacts &&
        scaleColorSpaceAdmissionPolicy.didDescribePixelFormatColorSpaceAdmissionFacts &&
        scaleColorSpaceAdmissionPolicy.didConfirmNoRealScreenQuery &&
        scaleColorSpaceAdmissionPolicy.didConfirmNoRealLayerQuery &&
        scaleColorSpaceAdmissionPolicy.didConfirmNoRealColorSpaceQuery &&
        scaleColorSpaceAdmissionPolicy.didConfirmNoRendererStateMutation &&
        scaleColorSpaceAdmissionPolicy.didKeepMetalScaleColorSpaceAdmissionPolicyValueOnly &&
        scaleColorSpaceAdmissionPolicy.didAvoidRenderPermissionWrapper &&
        scaleColorSpaceAdmissionPolicy.didAvoidRendererStateWriteWrapper &&
        scaleColorSpaceAdmissionPolicy.shouldDeferRendererMetalScaleColorSpaceAdmissionPolicy == false &&
        scaleColorSpaceAdmissionPolicy
            .shouldReportRendererMetalScaleColorSpaceAdmissionPolicyBlocked == false
    let scalePolicyDeferred =
        scaleColorSpaceAdmissionPolicy.shouldDeferRendererMetalScaleColorSpaceAdmissionPolicy &&
        scaleColorSpaceAdmissionPolicy
            .shouldReportRendererMetalScaleColorSpaceAdmissionPolicyBlocked == false
    let scalePolicyInconsistent =
        scaleColorSpaceAdmissionPolicy.shouldReportRendererMetalScaleColorSpaceAdmissionPolicyBlocked ||
        (
            scaleColorSpaceAdmissionPolicy.didPrepareRendererMetalScaleColorSpaceAdmissionPolicy &&
            scalePolicyReady == false
        ) ||
        (
            scaleColorSpaceAdmissionPolicy.shouldDeferRendererMetalScaleColorSpaceAdmissionPolicy &&
            scaleColorSpaceAdmissionPolicy
                .shouldReportRendererMetalScaleColorSpaceAdmissionPolicyBlocked
        )

    if (scalePolicyInconsistent) {
        return CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness(
            scaleColorSpaceAdmissionPolicy,
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

    if (scalePolicyDeferred || scalePolicyReady == false) {
        return CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness(
            scaleColorSpaceAdmissionPolicy,
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

    return CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness(
        scaleColorSpaceAdmissionPolicy,
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

func cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft():
    CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness {
    let noPlatformObjectImplementationReadiness =
        cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()
    let implementationIntent =
        cjguiInternalBuildRendererMetalDeviceLayerImplementationIntent(
            noPlatformObjectImplementationReadiness
        )
    let deviceCreationAdmissionPolicy =
        cjguiInternalBuildRendererMetalDeviceCreationAdmissionPolicy(implementationIntent)
    let layerBindingAdmissionGuard =
        cjguiInternalBuildRendererMetalLayerBindingAdmissionGuard(deviceCreationAdmissionPolicy)
    let scaleColorSpaceAdmissionPolicy =
        cjguiInternalBuildRendererMetalScaleColorSpaceAdmissionPolicy(layerBindingAdmissionGuard)
    return cjguiInternalBuildRendererNoMetalDeviceLayerImplementationReadiness(
        scaleColorSpaceAdmissionPolicy
    )
}
