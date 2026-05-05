package cjgui

// Owner: Renderer Metal device-layer owner value boundary.
// Truth: 只消费 CjguiInternalRendererNoPlatformObjectReadiness，表达 future
// device-layer owner intent、device selection policy、layer binding policy、
// scale/color-space policy 与 no-metal-device-layer readiness 的内部 value facts。
// Stop-line: 这里不创建 device、layer、queue、drawable、buffer、pass、encoder
// 或 pipeline，不创建 resource token，不调用 foreign platform API，不提交 work，
// 不触发 render side effect，不写 renderer state，不开放 external surface。
// Same-shape Boundary Brake: 本 owner 新增 device selection / layer binding /
// scale-color-space / no-metal-device-layer vocabulary，不把 no-platform-object
// readiness 包成 receipt / record / publication。

// Metal device-layer owner intent 只表达 future device-layer owner intent；
// 它不是 device creation，也不是 layer creation permission。
struct CjguiInternalRendererMetalDeviceLayerOwnerIntent {
    let noPlatformObjectReadiness: CjguiInternalRendererNoPlatformObjectReadiness
    let didPrepareRendererMetalDeviceLayerOwnerIntent: Bool
    let shouldDeferRendererMetalDeviceLayerOwnerIntent: Bool
    let shouldReportRendererMetalDeviceLayerOwnerIntentBlocked: Bool
    let didPreserveRendererNoPlatformObjectReadiness: Bool
    let didDefineFutureMetalDeviceLayerOwnerIntent: Bool
    let didDescribeDeviceSelectionFacts: Bool
    let didDescribeLayerBindingFacts: Bool
    let didDescribeScaleColorSpaceFacts: Bool
    let didKeepMetalDeviceLayerOwnerIntentValueOnly: Bool
    let didAvoidDeviceCreation: Bool
    let didAvoidLayerCreation: Bool
    let didAvoidPlatformResourceMaterialization: Bool
    let didAvoidForeignApiCalls: Bool
    let didAvoidThinWrapper: Bool

    init(
        noPlatformObjectReadiness: CjguiInternalRendererNoPlatformObjectReadiness,
        didPrepareRendererMetalDeviceLayerOwnerIntent: Bool,
        shouldDeferRendererMetalDeviceLayerOwnerIntent: Bool,
        shouldReportRendererMetalDeviceLayerOwnerIntentBlocked: Bool,
        didPreserveRendererNoPlatformObjectReadiness: Bool,
        didDefineFutureMetalDeviceLayerOwnerIntent: Bool,
        didDescribeDeviceSelectionFacts: Bool,
        didDescribeLayerBindingFacts: Bool,
        didDescribeScaleColorSpaceFacts: Bool,
        didKeepMetalDeviceLayerOwnerIntentValueOnly: Bool,
        didAvoidDeviceCreation: Bool,
        didAvoidLayerCreation: Bool,
        didAvoidPlatformResourceMaterialization: Bool,
        didAvoidForeignApiCalls: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noPlatformObjectReadiness = noPlatformObjectReadiness
        this.didPrepareRendererMetalDeviceLayerOwnerIntent =
            didPrepareRendererMetalDeviceLayerOwnerIntent
        this.shouldDeferRendererMetalDeviceLayerOwnerIntent =
            shouldDeferRendererMetalDeviceLayerOwnerIntent
        this.shouldReportRendererMetalDeviceLayerOwnerIntentBlocked =
            shouldReportRendererMetalDeviceLayerOwnerIntentBlocked
        this.didPreserveRendererNoPlatformObjectReadiness =
            didPreserveRendererNoPlatformObjectReadiness
        this.didDefineFutureMetalDeviceLayerOwnerIntent =
            didDefineFutureMetalDeviceLayerOwnerIntent
        this.didDescribeDeviceSelectionFacts =
            didDescribeDeviceSelectionFacts
        this.didDescribeLayerBindingFacts = didDescribeLayerBindingFacts
        this.didDescribeScaleColorSpaceFacts =
            didDescribeScaleColorSpaceFacts
        this.didKeepMetalDeviceLayerOwnerIntentValueOnly =
            didKeepMetalDeviceLayerOwnerIntentValueOnly
        this.didAvoidDeviceCreation = didAvoidDeviceCreation
        this.didAvoidLayerCreation = didAvoidLayerCreation
        this.didAvoidPlatformResourceMaterialization =
            didAvoidPlatformResourceMaterialization
        this.didAvoidForeignApiCalls = didAvoidForeignApiCalls
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

// Device selection policy 只表达 future device choice / fallback facts；
// 它不查询 device，不创建 resource，也不授予 device-ready permission。
struct CjguiInternalRendererMetalDeviceSelectionPolicy {
    let ownerIntent: CjguiInternalRendererMetalDeviceLayerOwnerIntent
    let didPrepareRendererMetalDeviceSelectionPolicy: Bool
    let shouldDeferRendererMetalDeviceSelectionPolicy: Bool
    let shouldReportRendererMetalDeviceSelectionPolicyBlocked: Bool
    let didPreserveRendererMetalDeviceLayerOwnerIntent: Bool
    let didDefineFutureMetalDeviceSelectionPolicy: Bool
    let didDescribeDeviceChoiceFacts: Bool
    let didDescribeCapabilityFallbackFacts: Bool
    let didDescribeNoDeviceFallbackFacts: Bool
    let didKeepMetalDeviceSelectionPolicyValueOnly: Bool
    let didAvoidDeviceCreation: Bool
    let didAvoidDeviceQueryCall: Bool
    let didAvoidDeviceReadyPermission: Bool
    let didAvoidQueueCreationPermission: Bool

    init(
        ownerIntent: CjguiInternalRendererMetalDeviceLayerOwnerIntent,
        didPrepareRendererMetalDeviceSelectionPolicy: Bool,
        shouldDeferRendererMetalDeviceSelectionPolicy: Bool,
        shouldReportRendererMetalDeviceSelectionPolicyBlocked: Bool,
        didPreserveRendererMetalDeviceLayerOwnerIntent: Bool,
        didDefineFutureMetalDeviceSelectionPolicy: Bool,
        didDescribeDeviceChoiceFacts: Bool,
        didDescribeCapabilityFallbackFacts: Bool,
        didDescribeNoDeviceFallbackFacts: Bool,
        didKeepMetalDeviceSelectionPolicyValueOnly: Bool,
        didAvoidDeviceCreation: Bool,
        didAvoidDeviceQueryCall: Bool,
        didAvoidDeviceReadyPermission: Bool,
        didAvoidQueueCreationPermission: Bool
    ) {
        this.ownerIntent = ownerIntent
        this.didPrepareRendererMetalDeviceSelectionPolicy =
            didPrepareRendererMetalDeviceSelectionPolicy
        this.shouldDeferRendererMetalDeviceSelectionPolicy =
            shouldDeferRendererMetalDeviceSelectionPolicy
        this.shouldReportRendererMetalDeviceSelectionPolicyBlocked =
            shouldReportRendererMetalDeviceSelectionPolicyBlocked
        this.didPreserveRendererMetalDeviceLayerOwnerIntent =
            didPreserveRendererMetalDeviceLayerOwnerIntent
        this.didDefineFutureMetalDeviceSelectionPolicy =
            didDefineFutureMetalDeviceSelectionPolicy
        this.didDescribeDeviceChoiceFacts = didDescribeDeviceChoiceFacts
        this.didDescribeCapabilityFallbackFacts =
            didDescribeCapabilityFallbackFacts
        this.didDescribeNoDeviceFallbackFacts =
            didDescribeNoDeviceFallbackFacts
        this.didKeepMetalDeviceSelectionPolicyValueOnly =
            didKeepMetalDeviceSelectionPolicyValueOnly
        this.didAvoidDeviceCreation = didAvoidDeviceCreation
        this.didAvoidDeviceQueryCall = didAvoidDeviceQueryCall
        this.didAvoidDeviceReadyPermission = didAvoidDeviceReadyPermission
        this.didAvoidQueueCreationPermission = didAvoidQueueCreationPermission
    }
}

// Layer binding policy 只表达 future layer-hosting relation facts；
// 它不创建 layer，不 acquire drawable，也不 configure platform state。
struct CjguiInternalRendererMetalLayerBindingPolicy {
    let selectionPolicy: CjguiInternalRendererMetalDeviceSelectionPolicy
    let didPrepareRendererMetalLayerBindingPolicy: Bool
    let shouldDeferRendererMetalLayerBindingPolicy: Bool
    let shouldReportRendererMetalLayerBindingPolicyBlocked: Bool
    let didPreserveRendererMetalDeviceSelectionPolicy: Bool
    let didDefineFutureMetalLayerBindingPolicy: Bool
    let didDescribeLayerHostRelationFacts: Bool
    let didDescribeDrawablePoolBoundaryFacts: Bool
    let didDescribeNoLayerFallbackFacts: Bool
    let didKeepMetalLayerBindingPolicyValueOnly: Bool
    let didAvoidLayerCreation: Bool
    let didAvoidDrawableAcquisition: Bool
    let didAvoidLayerReadyPermission: Bool
    let didAvoidQueueDrawableBufferPassEncoderPipelineCreation: Bool
    let didAvoidForeignApiCalls: Bool

    init(
        selectionPolicy: CjguiInternalRendererMetalDeviceSelectionPolicy,
        didPrepareRendererMetalLayerBindingPolicy: Bool,
        shouldDeferRendererMetalLayerBindingPolicy: Bool,
        shouldReportRendererMetalLayerBindingPolicyBlocked: Bool,
        didPreserveRendererMetalDeviceSelectionPolicy: Bool,
        didDefineFutureMetalLayerBindingPolicy: Bool,
        didDescribeLayerHostRelationFacts: Bool,
        didDescribeDrawablePoolBoundaryFacts: Bool,
        didDescribeNoLayerFallbackFacts: Bool,
        didKeepMetalLayerBindingPolicyValueOnly: Bool,
        didAvoidLayerCreation: Bool,
        didAvoidDrawableAcquisition: Bool,
        didAvoidLayerReadyPermission: Bool,
        didAvoidQueueDrawableBufferPassEncoderPipelineCreation: Bool,
        didAvoidForeignApiCalls: Bool
    ) {
        this.selectionPolicy = selectionPolicy
        this.didPrepareRendererMetalLayerBindingPolicy =
            didPrepareRendererMetalLayerBindingPolicy
        this.shouldDeferRendererMetalLayerBindingPolicy =
            shouldDeferRendererMetalLayerBindingPolicy
        this.shouldReportRendererMetalLayerBindingPolicyBlocked =
            shouldReportRendererMetalLayerBindingPolicyBlocked
        this.didPreserveRendererMetalDeviceSelectionPolicy =
            didPreserveRendererMetalDeviceSelectionPolicy
        this.didDefineFutureMetalLayerBindingPolicy =
            didDefineFutureMetalLayerBindingPolicy
        this.didDescribeLayerHostRelationFacts =
            didDescribeLayerHostRelationFacts
        this.didDescribeDrawablePoolBoundaryFacts =
            didDescribeDrawablePoolBoundaryFacts
        this.didDescribeNoLayerFallbackFacts =
            didDescribeNoLayerFallbackFacts
        this.didKeepMetalLayerBindingPolicyValueOnly =
            didKeepMetalLayerBindingPolicyValueOnly
        this.didAvoidLayerCreation = didAvoidLayerCreation
        this.didAvoidDrawableAcquisition = didAvoidDrawableAcquisition
        this.didAvoidLayerReadyPermission = didAvoidLayerReadyPermission
        this.didAvoidQueueDrawableBufferPassEncoderPipelineCreation =
            didAvoidQueueDrawableBufferPassEncoderPipelineCreation
        this.didAvoidForeignApiCalls = didAvoidForeignApiCalls
    }
}

// Scale/color-space policy 只表达 dehydrated size / scale / color facts；
// 它不 read platform view state，也不 configure layer state。
struct CjguiInternalRendererMetalScaleColorSpacePolicy {
    let layerBindingPolicy: CjguiInternalRendererMetalLayerBindingPolicy
    let didPrepareRendererMetalScaleColorSpacePolicy: Bool
    let shouldDeferRendererMetalScaleColorSpacePolicy: Bool
    let shouldReportRendererMetalScaleColorSpacePolicyBlocked: Bool
    let didPreserveRendererMetalLayerBindingPolicy: Bool
    let didDefineFutureMetalScaleColorSpacePolicy: Bool
    let didDescribeDrawableSizeFacts: Bool
    let didDescribeBackingScaleFacts: Bool
    let didDescribePixelFormatColorSpaceFacts: Bool
    let didKeepMetalScaleColorSpacePolicyValueOnly: Bool
    let didAvoidPlatformScaleQuery: Bool
    let didAvoidLayerConfiguration: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidExternalObservationSurface: Bool

    init(
        layerBindingPolicy: CjguiInternalRendererMetalLayerBindingPolicy,
        didPrepareRendererMetalScaleColorSpacePolicy: Bool,
        shouldDeferRendererMetalScaleColorSpacePolicy: Bool,
        shouldReportRendererMetalScaleColorSpacePolicyBlocked: Bool,
        didPreserveRendererMetalLayerBindingPolicy: Bool,
        didDefineFutureMetalScaleColorSpacePolicy: Bool,
        didDescribeDrawableSizeFacts: Bool,
        didDescribeBackingScaleFacts: Bool,
        didDescribePixelFormatColorSpaceFacts: Bool,
        didKeepMetalScaleColorSpacePolicyValueOnly: Bool,
        didAvoidPlatformScaleQuery: Bool,
        didAvoidLayerConfiguration: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidExternalObservationSurface: Bool
    ) {
        this.layerBindingPolicy = layerBindingPolicy
        this.didPrepareRendererMetalScaleColorSpacePolicy =
            didPrepareRendererMetalScaleColorSpacePolicy
        this.shouldDeferRendererMetalScaleColorSpacePolicy =
            shouldDeferRendererMetalScaleColorSpacePolicy
        this.shouldReportRendererMetalScaleColorSpacePolicyBlocked =
            shouldReportRendererMetalScaleColorSpacePolicyBlocked
        this.didPreserveRendererMetalLayerBindingPolicy =
            didPreserveRendererMetalLayerBindingPolicy
        this.didDefineFutureMetalScaleColorSpacePolicy =
            didDefineFutureMetalScaleColorSpacePolicy
        this.didDescribeDrawableSizeFacts = didDescribeDrawableSizeFacts
        this.didDescribeBackingScaleFacts = didDescribeBackingScaleFacts
        this.didDescribePixelFormatColorSpaceFacts =
            didDescribePixelFormatColorSpaceFacts
        this.didKeepMetalScaleColorSpacePolicyValueOnly =
            didKeepMetalScaleColorSpacePolicyValueOnly
        this.didAvoidPlatformScaleQuery = didAvoidPlatformScaleQuery
        this.didAvoidLayerConfiguration = didAvoidLayerConfiguration
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidExternalObservationSurface =
            didAvoidExternalObservationSurface
    }
}

// No-metal-device-layer readiness 是本 owner 的 endpoint；它确认当前没有
// device / layer resource，不代表 backend, render, submit, state, or API permission。
struct CjguiInternalRendererNoMetalDeviceLayerReadiness {
    let scaleColorSpacePolicy: CjguiInternalRendererMetalScaleColorSpacePolicy
    let isRendererNoMetalDeviceLayerReady: Bool
    let canFutureRendererMetalDeviceLayerBoundaryEvaluate: Bool
    let shouldDeferRendererNoMetalDeviceLayerReadiness: Bool
    let shouldReportRendererNoMetalDeviceLayerReadinessBlocked: Bool
    let didSealRendererNoMetalDeviceLayerReadiness: Bool
    let didPreserveRendererMetalScaleColorSpacePolicy: Bool
    let didKeepNoMetalDeviceLayerReadinessValueOnly: Bool
    let didConfirmNoDeviceCreated: Bool
    let didConfirmNoLayerCreated: Bool
    let didConfirmNoPlatformResourceMaterialized: Bool
    let didConfirmNoForeignResourceToken: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didConfirmNoCommandQueueDrawableBufferPassEncoderPipeline: Bool
    let didConfirmNoCommandBufferCommit: Bool
    let didConfirmNoGpuSubmission: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoRendererStateMutation: Bool
    let didConfirmNoBridgeSmokeHarnessEntryChange: Bool
    let didConfirmNoExternalApiSurface: Bool
    let didAvoidDevicePermission: Bool
    let didAvoidLayerPermission: Bool
    let didAvoidForeignResourceReadinessWrapper: Bool
    let didAvoidBackendImplementationWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        scaleColorSpacePolicy: CjguiInternalRendererMetalScaleColorSpacePolicy,
        isRendererNoMetalDeviceLayerReady: Bool,
        canFutureRendererMetalDeviceLayerBoundaryEvaluate: Bool,
        shouldDeferRendererNoMetalDeviceLayerReadiness: Bool,
        shouldReportRendererNoMetalDeviceLayerReadinessBlocked: Bool,
        didSealRendererNoMetalDeviceLayerReadiness: Bool,
        didPreserveRendererMetalScaleColorSpacePolicy: Bool,
        didKeepNoMetalDeviceLayerReadinessValueOnly: Bool,
        didConfirmNoDeviceCreated: Bool,
        didConfirmNoLayerCreated: Bool,
        didConfirmNoPlatformResourceMaterialized: Bool,
        didConfirmNoForeignResourceToken: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didConfirmNoCommandQueueDrawableBufferPassEncoderPipeline: Bool,
        didConfirmNoCommandBufferCommit: Bool,
        didConfirmNoGpuSubmission: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoRendererStateMutation: Bool,
        didConfirmNoBridgeSmokeHarnessEntryChange: Bool,
        didConfirmNoExternalApiSurface: Bool,
        didAvoidDevicePermission: Bool,
        didAvoidLayerPermission: Bool,
        didAvoidForeignResourceReadinessWrapper: Bool,
        didAvoidBackendImplementationWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.scaleColorSpacePolicy = scaleColorSpacePolicy
        this.isRendererNoMetalDeviceLayerReady =
            isRendererNoMetalDeviceLayerReady
        this.canFutureRendererMetalDeviceLayerBoundaryEvaluate =
            canFutureRendererMetalDeviceLayerBoundaryEvaluate
        this.shouldDeferRendererNoMetalDeviceLayerReadiness =
            shouldDeferRendererNoMetalDeviceLayerReadiness
        this.shouldReportRendererNoMetalDeviceLayerReadinessBlocked =
            shouldReportRendererNoMetalDeviceLayerReadinessBlocked
        this.didSealRendererNoMetalDeviceLayerReadiness =
            didSealRendererNoMetalDeviceLayerReadiness
        this.didPreserveRendererMetalScaleColorSpacePolicy =
            didPreserveRendererMetalScaleColorSpacePolicy
        this.didKeepNoMetalDeviceLayerReadinessValueOnly =
            didKeepNoMetalDeviceLayerReadinessValueOnly
        this.didConfirmNoDeviceCreated = didConfirmNoDeviceCreated
        this.didConfirmNoLayerCreated = didConfirmNoLayerCreated
        this.didConfirmNoPlatformResourceMaterialized =
            didConfirmNoPlatformResourceMaterialized
        this.didConfirmNoForeignResourceToken =
            didConfirmNoForeignResourceToken
        this.didConfirmNoPointerLikeResource = didConfirmNoPointerLikeResource
        this.didConfirmNoCommandQueueDrawableBufferPassEncoderPipeline =
            didConfirmNoCommandQueueDrawableBufferPassEncoderPipeline
        this.didConfirmNoCommandBufferCommit =
            didConfirmNoCommandBufferCommit
        this.didConfirmNoGpuSubmission = didConfirmNoGpuSubmission
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoRendererStateMutation =
            didConfirmNoRendererStateMutation
        this.didConfirmNoBridgeSmokeHarnessEntryChange =
            didConfirmNoBridgeSmokeHarnessEntryChange
        this.didConfirmNoExternalApiSurface = didConfirmNoExternalApiSurface
        this.didAvoidDevicePermission = didAvoidDevicePermission
        this.didAvoidLayerPermission = didAvoidLayerPermission
        this.didAvoidForeignResourceReadinessWrapper =
            didAvoidForeignResourceReadinessWrapper
        this.didAvoidBackendImplementationWrapper =
            didAvoidBackendImplementationWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererMetalDeviceLayerOwnerIntent(
    noPlatformObjectReadiness: CjguiInternalRendererNoPlatformObjectReadiness
): CjguiInternalRendererMetalDeviceLayerOwnerIntent {
    let noPlatformObject =
        noPlatformObjectReadiness.isRendererNoPlatformObjectReady &&
        noPlatformObjectReadiness.canFutureRendererBackendPlatformObjectBoundaryEvaluate &&
        noPlatformObjectReadiness.didSealRendererNoPlatformObjectReadiness &&
        noPlatformObjectReadiness.didPreserveRendererConfinementFailurePolicy &&
        noPlatformObjectReadiness.didKeepNoPlatformObjectReadinessValueOnly &&
        noPlatformObjectReadiness.didConfirmNoPlatformObjectCreated &&
        noPlatformObjectReadiness.didConfirmNoBackendObjectCreated &&
        noPlatformObjectReadiness.didConfirmNoNativeResourceToken &&
        noPlatformObjectReadiness.didConfirmNoPointerLikeResource &&
        noPlatformObjectReadiness.didConfirmNoDeviceOrLayer &&
        noPlatformObjectReadiness.didConfirmNoCommandQueueDrawableBufferPassEncoderPipeline &&
        noPlatformObjectReadiness.didConfirmNoCommandBufferCommit &&
        noPlatformObjectReadiness.didConfirmNoGpuSubmission &&
        noPlatformObjectReadiness.didConfirmNoRenderExecution &&
        noPlatformObjectReadiness.didConfirmNoRendererStateMutation &&
        noPlatformObjectReadiness.didConfirmNoBridgeSmokeHarnessEntryChange &&
        noPlatformObjectReadiness.didConfirmNoExternalApiSurface &&
        noPlatformObjectReadiness.didAvoidPlatformObjectPermission &&
        noPlatformObjectReadiness.didAvoidResourceTokenReadinessWrapper &&
        noPlatformObjectReadiness.didAvoidBackendImplementationWrapper &&
        noPlatformObjectReadiness.didAvoidDeviceLayerReadinessWrapper &&
        noPlatformObjectReadiness.didAvoidBackendReadyPermissionWrapper &&
        noPlatformObjectReadiness.didAvoidReceiptRecordPublication &&
        noPlatformObjectReadiness.didAvoidThinWrapper &&
        noPlatformObjectReadiness.didStayFullRebuildOnly &&
        noPlatformObjectReadiness.shouldDeferRendererNoPlatformObjectReadiness == false &&
        noPlatformObjectReadiness.shouldReportRendererNoPlatformObjectReadinessBlocked == false
    let intentDeferred =
        noPlatformObjectReadiness.isRendererNoPlatformObjectReady == false &&
        noPlatformObjectReadiness.canFutureRendererBackendPlatformObjectBoundaryEvaluate == false &&
        noPlatformObjectReadiness.shouldDeferRendererNoPlatformObjectReadiness &&
        noPlatformObjectReadiness.shouldReportRendererNoPlatformObjectReadinessBlocked == false
    let intentInconsistent = (
        noPlatformObjectReadiness.isRendererNoPlatformObjectReady &&
            (
                noPlatformObjectReadiness.canFutureRendererBackendPlatformObjectBoundaryEvaluate == false ||
                noPlatformObjectReadiness.didSealRendererNoPlatformObjectReadiness == false ||
                noPlatformObjectReadiness.didPreserveRendererConfinementFailurePolicy == false ||
                noPlatformObjectReadiness.didKeepNoPlatformObjectReadinessValueOnly == false ||
                noPlatformObjectReadiness.didConfirmNoPlatformObjectCreated == false ||
                noPlatformObjectReadiness.didConfirmNoBackendObjectCreated == false ||
                noPlatformObjectReadiness.didConfirmNoNativeResourceToken == false ||
                noPlatformObjectReadiness.didConfirmNoPointerLikeResource == false ||
                noPlatformObjectReadiness.didConfirmNoDeviceOrLayer == false ||
                noPlatformObjectReadiness.didConfirmNoCommandQueueDrawableBufferPassEncoderPipeline == false ||
                noPlatformObjectReadiness.didConfirmNoCommandBufferCommit == false ||
                noPlatformObjectReadiness.didConfirmNoGpuSubmission == false ||
                noPlatformObjectReadiness.didConfirmNoRenderExecution == false ||
                noPlatformObjectReadiness.didConfirmNoRendererStateMutation == false ||
                noPlatformObjectReadiness.didConfirmNoBridgeSmokeHarnessEntryChange == false ||
                noPlatformObjectReadiness.didConfirmNoExternalApiSurface == false ||
                noPlatformObjectReadiness.didAvoidPlatformObjectPermission == false ||
                noPlatformObjectReadiness.didAvoidResourceTokenReadinessWrapper == false ||
                noPlatformObjectReadiness.didAvoidBackendImplementationWrapper == false ||
                noPlatformObjectReadiness.didAvoidDeviceLayerReadinessWrapper == false ||
                noPlatformObjectReadiness.didAvoidBackendReadyPermissionWrapper == false ||
                noPlatformObjectReadiness.didAvoidReceiptRecordPublication == false ||
                noPlatformObjectReadiness.didAvoidThinWrapper == false ||
                noPlatformObjectReadiness.didStayFullRebuildOnly == false ||
                noPlatformObjectReadiness.shouldDeferRendererNoPlatformObjectReadiness ||
                noPlatformObjectReadiness.shouldReportRendererNoPlatformObjectReadinessBlocked
            )
        ) ||
        (noPlatformObjectReadiness.canFutureRendererBackendPlatformObjectBoundaryEvaluate &&
            noPlatformObjectReadiness.isRendererNoPlatformObjectReady == false) ||
        (noPlatformObjectReadiness.shouldDeferRendererNoPlatformObjectReadiness &&
            noPlatformObjectReadiness.shouldReportRendererNoPlatformObjectReadinessBlocked)

    // fail-closed：不能把 no-platform-object endpoint 薄包成 device-layer intent。
    if (
        noPlatformObjectReadiness.shouldReportRendererNoPlatformObjectReadinessBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererMetalDeviceLayerOwnerIntent(
            noPlatformObjectReadiness,
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

    if (noPlatformObject) {
        return CjguiInternalRendererMetalDeviceLayerOwnerIntent(
            noPlatformObjectReadiness,
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

    if (intentDeferred) {
        return CjguiInternalRendererMetalDeviceLayerOwnerIntent(
            noPlatformObjectReadiness,
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

    return CjguiInternalRendererMetalDeviceLayerOwnerIntent(
        noPlatformObjectReadiness,
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

func cjguiInternalBuildRendererMetalDeviceSelectionPolicy(
    ownerIntent: CjguiInternalRendererMetalDeviceLayerOwnerIntent
): CjguiInternalRendererMetalDeviceSelectionPolicy {
    let intentReady =
        ownerIntent.didPrepareRendererMetalDeviceLayerOwnerIntent &&
        ownerIntent.didPreserveRendererNoPlatformObjectReadiness &&
        ownerIntent.didDefineFutureMetalDeviceLayerOwnerIntent &&
        ownerIntent.didDescribeDeviceSelectionFacts &&
        ownerIntent.didDescribeLayerBindingFacts &&
        ownerIntent.didDescribeScaleColorSpaceFacts &&
        ownerIntent.didKeepMetalDeviceLayerOwnerIntentValueOnly &&
        ownerIntent.didAvoidDeviceCreation &&
        ownerIntent.didAvoidLayerCreation &&
        ownerIntent.didAvoidPlatformResourceMaterialization &&
        ownerIntent.didAvoidForeignApiCalls &&
        ownerIntent.didAvoidThinWrapper &&
        ownerIntent.shouldDeferRendererMetalDeviceLayerOwnerIntent == false &&
        ownerIntent.shouldReportRendererMetalDeviceLayerOwnerIntentBlocked == false
    let selectionDeferred =
        ownerIntent.didPrepareRendererMetalDeviceLayerOwnerIntent == false &&
        ownerIntent.shouldDeferRendererMetalDeviceLayerOwnerIntent &&
        ownerIntent.shouldReportRendererMetalDeviceLayerOwnerIntentBlocked == false
    let selectionInconsistent = (
        ownerIntent.didPrepareRendererMetalDeviceLayerOwnerIntent &&
            (
                ownerIntent.didPreserveRendererNoPlatformObjectReadiness == false ||
                ownerIntent.didDefineFutureMetalDeviceLayerOwnerIntent == false ||
                ownerIntent.didDescribeDeviceSelectionFacts == false ||
                ownerIntent.didDescribeLayerBindingFacts == false ||
                ownerIntent.didDescribeScaleColorSpaceFacts == false ||
                ownerIntent.didKeepMetalDeviceLayerOwnerIntentValueOnly == false ||
                ownerIntent.didAvoidDeviceCreation == false ||
                ownerIntent.didAvoidLayerCreation == false ||
                ownerIntent.didAvoidPlatformResourceMaterialization == false ||
                ownerIntent.didAvoidForeignApiCalls == false ||
                ownerIntent.didAvoidThinWrapper == false ||
                ownerIntent.shouldDeferRendererMetalDeviceLayerOwnerIntent ||
                ownerIntent.shouldReportRendererMetalDeviceLayerOwnerIntentBlocked
            )
        ) ||
        (ownerIntent.didPreserveRendererNoPlatformObjectReadiness &&
            ownerIntent.didPrepareRendererMetalDeviceLayerOwnerIntent == false) ||
        (ownerIntent.shouldDeferRendererMetalDeviceLayerOwnerIntent &&
            ownerIntent.shouldReportRendererMetalDeviceLayerOwnerIntentBlocked)

    // device selection policy 只记录 choice / fallback facts；这里不 query device。
    if (
        ownerIntent.shouldReportRendererMetalDeviceLayerOwnerIntentBlocked ||
        selectionInconsistent
    ) {
        return CjguiInternalRendererMetalDeviceSelectionPolicy(
            ownerIntent,
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

    if (intentReady) {
        return CjguiInternalRendererMetalDeviceSelectionPolicy(
            ownerIntent,
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

    if (selectionDeferred) {
        return CjguiInternalRendererMetalDeviceSelectionPolicy(
            ownerIntent,
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

    return CjguiInternalRendererMetalDeviceSelectionPolicy(
        ownerIntent,
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

func cjguiInternalBuildRendererMetalLayerBindingPolicy(
    selectionPolicy: CjguiInternalRendererMetalDeviceSelectionPolicy
): CjguiInternalRendererMetalLayerBindingPolicy {
    let selectionReady =
        selectionPolicy.didPrepareRendererMetalDeviceSelectionPolicy &&
        selectionPolicy.didPreserveRendererMetalDeviceLayerOwnerIntent &&
        selectionPolicy.didDefineFutureMetalDeviceSelectionPolicy &&
        selectionPolicy.didDescribeDeviceChoiceFacts &&
        selectionPolicy.didDescribeCapabilityFallbackFacts &&
        selectionPolicy.didDescribeNoDeviceFallbackFacts &&
        selectionPolicy.didKeepMetalDeviceSelectionPolicyValueOnly &&
        selectionPolicy.didAvoidDeviceCreation &&
        selectionPolicy.didAvoidDeviceQueryCall &&
        selectionPolicy.didAvoidDeviceReadyPermission &&
        selectionPolicy.didAvoidQueueCreationPermission &&
        selectionPolicy.shouldDeferRendererMetalDeviceSelectionPolicy == false &&
        selectionPolicy.shouldReportRendererMetalDeviceSelectionPolicyBlocked == false
    let bindingDeferred =
        selectionPolicy.didPrepareRendererMetalDeviceSelectionPolicy == false &&
        selectionPolicy.shouldDeferRendererMetalDeviceSelectionPolicy &&
        selectionPolicy.shouldReportRendererMetalDeviceSelectionPolicyBlocked == false
    let bindingInconsistent = (
        selectionPolicy.didPrepareRendererMetalDeviceSelectionPolicy &&
            (
                selectionPolicy.didPreserveRendererMetalDeviceLayerOwnerIntent == false ||
                selectionPolicy.didDefineFutureMetalDeviceSelectionPolicy == false ||
                selectionPolicy.didDescribeDeviceChoiceFacts == false ||
                selectionPolicy.didDescribeCapabilityFallbackFacts == false ||
                selectionPolicy.didDescribeNoDeviceFallbackFacts == false ||
                selectionPolicy.didKeepMetalDeviceSelectionPolicyValueOnly == false ||
                selectionPolicy.didAvoidDeviceCreation == false ||
                selectionPolicy.didAvoidDeviceQueryCall == false ||
                selectionPolicy.didAvoidDeviceReadyPermission == false ||
                selectionPolicy.didAvoidQueueCreationPermission == false ||
                selectionPolicy.shouldDeferRendererMetalDeviceSelectionPolicy ||
                selectionPolicy.shouldReportRendererMetalDeviceSelectionPolicyBlocked
            )
        ) ||
        (selectionPolicy.didPreserveRendererMetalDeviceLayerOwnerIntent &&
            selectionPolicy.didPrepareRendererMetalDeviceSelectionPolicy == false) ||
        (selectionPolicy.shouldDeferRendererMetalDeviceSelectionPolicy &&
            selectionPolicy.shouldReportRendererMetalDeviceSelectionPolicyBlocked)

    // layer binding policy 只记录 host relation facts；这里不 acquire drawable。
    if (
        selectionPolicy.shouldReportRendererMetalDeviceSelectionPolicyBlocked ||
        bindingInconsistent
    ) {
        return CjguiInternalRendererMetalLayerBindingPolicy(
            selectionPolicy,
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

    if (selectionReady) {
        return CjguiInternalRendererMetalLayerBindingPolicy(
            selectionPolicy,
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

    if (bindingDeferred) {
        return CjguiInternalRendererMetalLayerBindingPolicy(
            selectionPolicy,
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

    return CjguiInternalRendererMetalLayerBindingPolicy(
        selectionPolicy,
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

func cjguiInternalBuildRendererMetalScaleColorSpacePolicy(
    layerBindingPolicy: CjguiInternalRendererMetalLayerBindingPolicy
): CjguiInternalRendererMetalScaleColorSpacePolicy {
    let bindingReady =
        layerBindingPolicy.didPrepareRendererMetalLayerBindingPolicy &&
        layerBindingPolicy.didPreserveRendererMetalDeviceSelectionPolicy &&
        layerBindingPolicy.didDefineFutureMetalLayerBindingPolicy &&
        layerBindingPolicy.didDescribeLayerHostRelationFacts &&
        layerBindingPolicy.didDescribeDrawablePoolBoundaryFacts &&
        layerBindingPolicy.didDescribeNoLayerFallbackFacts &&
        layerBindingPolicy.didKeepMetalLayerBindingPolicyValueOnly &&
        layerBindingPolicy.didAvoidLayerCreation &&
        layerBindingPolicy.didAvoidDrawableAcquisition &&
        layerBindingPolicy.didAvoidLayerReadyPermission &&
        layerBindingPolicy.didAvoidQueueDrawableBufferPassEncoderPipelineCreation &&
        layerBindingPolicy.didAvoidForeignApiCalls &&
        layerBindingPolicy.shouldDeferRendererMetalLayerBindingPolicy == false &&
        layerBindingPolicy.shouldReportRendererMetalLayerBindingPolicyBlocked == false
    let scaleDeferred =
        layerBindingPolicy.didPrepareRendererMetalLayerBindingPolicy == false &&
        layerBindingPolicy.shouldDeferRendererMetalLayerBindingPolicy &&
        layerBindingPolicy.shouldReportRendererMetalLayerBindingPolicyBlocked == false
    let scaleInconsistent = (
        layerBindingPolicy.didPrepareRendererMetalLayerBindingPolicy &&
            (
                layerBindingPolicy.didPreserveRendererMetalDeviceSelectionPolicy == false ||
                layerBindingPolicy.didDefineFutureMetalLayerBindingPolicy == false ||
                layerBindingPolicy.didDescribeLayerHostRelationFacts == false ||
                layerBindingPolicy.didDescribeDrawablePoolBoundaryFacts == false ||
                layerBindingPolicy.didDescribeNoLayerFallbackFacts == false ||
                layerBindingPolicy.didKeepMetalLayerBindingPolicyValueOnly == false ||
                layerBindingPolicy.didAvoidLayerCreation == false ||
                layerBindingPolicy.didAvoidDrawableAcquisition == false ||
                layerBindingPolicy.didAvoidLayerReadyPermission == false ||
                layerBindingPolicy.didAvoidQueueDrawableBufferPassEncoderPipelineCreation == false ||
                layerBindingPolicy.didAvoidForeignApiCalls == false ||
                layerBindingPolicy.shouldDeferRendererMetalLayerBindingPolicy ||
                layerBindingPolicy.shouldReportRendererMetalLayerBindingPolicyBlocked
            )
        ) ||
        (layerBindingPolicy.didPreserveRendererMetalDeviceSelectionPolicy &&
            layerBindingPolicy.didPrepareRendererMetalLayerBindingPolicy == false) ||
        (layerBindingPolicy.shouldDeferRendererMetalLayerBindingPolicy &&
            layerBindingPolicy.shouldReportRendererMetalLayerBindingPolicyBlocked)

    // scale/color-space policy 只记录 dehydrated facts；这里不 configure layer。
    if (
        layerBindingPolicy.shouldReportRendererMetalLayerBindingPolicyBlocked ||
        scaleInconsistent
    ) {
        return CjguiInternalRendererMetalScaleColorSpacePolicy(
            layerBindingPolicy,
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

    if (bindingReady) {
        return CjguiInternalRendererMetalScaleColorSpacePolicy(
            layerBindingPolicy,
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

    if (scaleDeferred) {
        return CjguiInternalRendererMetalScaleColorSpacePolicy(
            layerBindingPolicy,
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

    return CjguiInternalRendererMetalScaleColorSpacePolicy(
        layerBindingPolicy,
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

func cjguiInternalBuildRendererNoMetalDeviceLayerReadiness(
    scaleColorSpacePolicy: CjguiInternalRendererMetalScaleColorSpacePolicy
): CjguiInternalRendererNoMetalDeviceLayerReadiness {
    let scaleReady =
        scaleColorSpacePolicy.didPrepareRendererMetalScaleColorSpacePolicy &&
        scaleColorSpacePolicy.didPreserveRendererMetalLayerBindingPolicy &&
        scaleColorSpacePolicy.didDefineFutureMetalScaleColorSpacePolicy &&
        scaleColorSpacePolicy.didDescribeDrawableSizeFacts &&
        scaleColorSpacePolicy.didDescribeBackingScaleFacts &&
        scaleColorSpacePolicy.didDescribePixelFormatColorSpaceFacts &&
        scaleColorSpacePolicy.didKeepMetalScaleColorSpacePolicyValueOnly &&
        scaleColorSpacePolicy.didAvoidPlatformScaleQuery &&
        scaleColorSpacePolicy.didAvoidLayerConfiguration &&
        scaleColorSpacePolicy.didAvoidRendererStateMutation &&
        scaleColorSpacePolicy.didAvoidExternalObservationSurface &&
        scaleColorSpacePolicy.shouldDeferRendererMetalScaleColorSpacePolicy == false &&
        scaleColorSpacePolicy.shouldReportRendererMetalScaleColorSpacePolicyBlocked == false
    let readinessDeferred =
        scaleColorSpacePolicy.didPrepareRendererMetalScaleColorSpacePolicy == false &&
        scaleColorSpacePolicy.shouldDeferRendererMetalScaleColorSpacePolicy &&
        scaleColorSpacePolicy.shouldReportRendererMetalScaleColorSpacePolicyBlocked == false
    let readinessInconsistent = (
        scaleColorSpacePolicy.didPrepareRendererMetalScaleColorSpacePolicy &&
            (
                scaleColorSpacePolicy.didPreserveRendererMetalLayerBindingPolicy == false ||
                scaleColorSpacePolicy.didDefineFutureMetalScaleColorSpacePolicy == false ||
                scaleColorSpacePolicy.didDescribeDrawableSizeFacts == false ||
                scaleColorSpacePolicy.didDescribeBackingScaleFacts == false ||
                scaleColorSpacePolicy.didDescribePixelFormatColorSpaceFacts == false ||
                scaleColorSpacePolicy.didKeepMetalScaleColorSpacePolicyValueOnly == false ||
                scaleColorSpacePolicy.didAvoidPlatformScaleQuery == false ||
                scaleColorSpacePolicy.didAvoidLayerConfiguration == false ||
                scaleColorSpacePolicy.didAvoidRendererStateMutation == false ||
                scaleColorSpacePolicy.didAvoidExternalObservationSurface == false ||
                scaleColorSpacePolicy.shouldDeferRendererMetalScaleColorSpacePolicy ||
                scaleColorSpacePolicy.shouldReportRendererMetalScaleColorSpacePolicyBlocked
            )
        ) ||
        (scaleColorSpacePolicy.didPreserveRendererMetalLayerBindingPolicy &&
            scaleColorSpacePolicy.didPrepareRendererMetalScaleColorSpacePolicy == false) ||
        (scaleColorSpacePolicy.shouldDeferRendererMetalScaleColorSpacePolicy &&
            scaleColorSpacePolicy.shouldReportRendererMetalScaleColorSpacePolicyBlocked)

    // endpoint 只 sealing no-device-layer facts；这里不 create receipt / record。
    if (
        scaleColorSpacePolicy.shouldReportRendererMetalScaleColorSpacePolicyBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoMetalDeviceLayerReadiness(
            scaleColorSpacePolicy,
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
            true
        )
    }

    if (scaleReady) {
        return CjguiInternalRendererNoMetalDeviceLayerReadiness(
            scaleColorSpacePolicy,
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
            true
        )
    }

    if (readinessDeferred) {
        return CjguiInternalRendererNoMetalDeviceLayerReadiness(
            scaleColorSpacePolicy,
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
            true
        )
    }

    return CjguiInternalRendererNoMetalDeviceLayerReadiness(
        scaleColorSpacePolicy,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft(
): CjguiInternalRendererNoMetalDeviceLayerReadiness {
    let noPlatformObjectReadiness =
        cjguiInternalExecuteDefaultRendererBackendPlatformObjectOwnerDraft()
    let ownerIntent =
        cjguiInternalBuildRendererMetalDeviceLayerOwnerIntent(
            noPlatformObjectReadiness
        )
    let selectionPolicy =
        cjguiInternalBuildRendererMetalDeviceSelectionPolicy(ownerIntent)
    let bindingPolicy =
        cjguiInternalBuildRendererMetalLayerBindingPolicy(selectionPolicy)
    let scaleColorSpacePolicy =
        cjguiInternalBuildRendererMetalScaleColorSpacePolicy(bindingPolicy)
    return cjguiInternalBuildRendererNoMetalDeviceLayerReadiness(
        scaleColorSpacePolicy
    )
}
