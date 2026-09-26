package cjgui

// Owner: Renderer backend platform object owner value boundary.
// Truth: 只消费 CjguiInternalRendererNoBackendReadyReadiness，表达 future
// backend platform object owner intent、native resource ownership policy、
// lifecycle teardown policy、confinement failure policy 与 no-platform-object
// readiness 的内部 value facts。
// Stop-line: 这里不创建 platform object，不创建 MTLDevice / CAMetalLayer，
// 不创建 command queue、drawable、command buffer、render pass、encoder 或
// pipeline state，不定义 retain / release / destroy FFI call，不提交 GPU work，
// 不触发 render side effect，不写 renderer state，不开放 external surface。
// Same-shape Boundary Brake: 本 owner 新增 native resource ownership /
// lifecycle teardown / confinement failure / no-platform-object vocabulary，
// 不把 no-backend-ready readiness 包成 receipt / record / publication。

// Backend platform object owner intent 只表达 future owner intent；
// 它不是 platform object creation，也不是 backend implementation permission。
struct CjguiInternalRendererBackendPlatformObjectOwnerIntent {
    let noBackendReadyReadiness: CjguiInternalRendererNoBackendReadyReadiness
    let didPrepareRendererBackendPlatformObjectOwnerIntent: Bool
    let shouldDeferRendererBackendPlatformObjectOwnerIntent: Bool
    let shouldReportRendererBackendPlatformObjectOwnerIntentBlocked: Bool
    let didPreserveRendererNoBackendReadyReadiness: Bool
    let didDefineFutureBackendPlatformObjectOwnerIntent: Bool
    let didDescribeNativeResourceOwnerFacts: Bool
    let didDescribeLifecycleTeardownFacts: Bool
    let didDescribeConfinementFailureFacts: Bool
    let didKeepBackendPlatformObjectOwnerIntentValueOnly: Bool
    let didAvoidPlatformObjectCreation: Bool
    let didAvoidNativeResourceSurface: Bool
    let didAvoidBackendImplementationPermission: Bool
    let didAvoidDeviceLayerReadinessWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        noBackendReadyReadiness: CjguiInternalRendererNoBackendReadyReadiness,
        didPrepareRendererBackendPlatformObjectOwnerIntent: Bool,
        shouldDeferRendererBackendPlatformObjectOwnerIntent: Bool,
        shouldReportRendererBackendPlatformObjectOwnerIntentBlocked: Bool,
        didPreserveRendererNoBackendReadyReadiness: Bool,
        didDefineFutureBackendPlatformObjectOwnerIntent: Bool,
        didDescribeNativeResourceOwnerFacts: Bool,
        didDescribeLifecycleTeardownFacts: Bool,
        didDescribeConfinementFailureFacts: Bool,
        didKeepBackendPlatformObjectOwnerIntentValueOnly: Bool,
        didAvoidPlatformObjectCreation: Bool,
        didAvoidNativeResourceSurface: Bool,
        didAvoidBackendImplementationPermission: Bool,
        didAvoidDeviceLayerReadinessWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noBackendReadyReadiness = noBackendReadyReadiness
        this.didPrepareRendererBackendPlatformObjectOwnerIntent =
            didPrepareRendererBackendPlatformObjectOwnerIntent
        this.shouldDeferRendererBackendPlatformObjectOwnerIntent =
            shouldDeferRendererBackendPlatformObjectOwnerIntent
        this.shouldReportRendererBackendPlatformObjectOwnerIntentBlocked =
            shouldReportRendererBackendPlatformObjectOwnerIntentBlocked
        this.didPreserveRendererNoBackendReadyReadiness =
            didPreserveRendererNoBackendReadyReadiness
        this.didDefineFutureBackendPlatformObjectOwnerIntent =
            didDefineFutureBackendPlatformObjectOwnerIntent
        this.didDescribeNativeResourceOwnerFacts =
            didDescribeNativeResourceOwnerFacts
        this.didDescribeLifecycleTeardownFacts =
            didDescribeLifecycleTeardownFacts
        this.didDescribeConfinementFailureFacts =
            didDescribeConfinementFailureFacts
        this.didKeepBackendPlatformObjectOwnerIntentValueOnly =
            didKeepBackendPlatformObjectOwnerIntentValueOnly
        this.didAvoidPlatformObjectCreation = didAvoidPlatformObjectCreation
        this.didAvoidNativeResourceSurface = didAvoidNativeResourceSurface
        this.didAvoidBackendImplementationPermission =
            didAvoidBackendImplementationPermission
        this.didAvoidDeviceLayerReadinessWrapper =
            didAvoidDeviceLayerReadinessWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

// Native resource ownership policy 只表达 future owner-local resource vocabulary；
// 它不创建 native handle / raw pointer，也不暴露 resource token。
struct CjguiInternalRendererNativeResourceOwnershipPolicy {
    let ownerIntent: CjguiInternalRendererBackendPlatformObjectOwnerIntent
    let didPrepareRendererNativeResourceOwnershipPolicy: Bool
    let shouldDeferRendererNativeResourceOwnershipPolicy: Bool
    let shouldReportRendererNativeResourceOwnershipPolicyBlocked: Bool
    let didPreserveRendererBackendPlatformObjectOwnerIntent: Bool
    let didDefineFutureNativeResourceOwnershipPolicy: Bool
    let didDescribeOwnerLocalNativeResourceVocabulary: Bool
    let didDescribeNoHandleSurfaceFacts: Bool
    let didDescribeResourceConfinementFacts: Bool
    let didKeepNativeResourceOwnershipPolicyValueOnly: Bool
    let didAvoidPlatformObjectCreation: Bool
    let didAvoidNativeResourceTokenCreation: Bool
    let didAvoidPointerLikeResource: Bool
    let didAvoidRealFfiRetainRelease: Bool

    init(
        ownerIntent: CjguiInternalRendererBackendPlatformObjectOwnerIntent,
        didPrepareRendererNativeResourceOwnershipPolicy: Bool,
        shouldDeferRendererNativeResourceOwnershipPolicy: Bool,
        shouldReportRendererNativeResourceOwnershipPolicyBlocked: Bool,
        didPreserveRendererBackendPlatformObjectOwnerIntent: Bool,
        didDefineFutureNativeResourceOwnershipPolicy: Bool,
        didDescribeOwnerLocalNativeResourceVocabulary: Bool,
        didDescribeNoHandleSurfaceFacts: Bool,
        didDescribeResourceConfinementFacts: Bool,
        didKeepNativeResourceOwnershipPolicyValueOnly: Bool,
        didAvoidPlatformObjectCreation: Bool,
        didAvoidNativeResourceTokenCreation: Bool,
        didAvoidPointerLikeResource: Bool,
        didAvoidRealFfiRetainRelease: Bool
    ) {
        this.ownerIntent = ownerIntent
        this.didPrepareRendererNativeResourceOwnershipPolicy =
            didPrepareRendererNativeResourceOwnershipPolicy
        this.shouldDeferRendererNativeResourceOwnershipPolicy =
            shouldDeferRendererNativeResourceOwnershipPolicy
        this.shouldReportRendererNativeResourceOwnershipPolicyBlocked =
            shouldReportRendererNativeResourceOwnershipPolicyBlocked
        this.didPreserveRendererBackendPlatformObjectOwnerIntent =
            didPreserveRendererBackendPlatformObjectOwnerIntent
        this.didDefineFutureNativeResourceOwnershipPolicy =
            didDefineFutureNativeResourceOwnershipPolicy
        this.didDescribeOwnerLocalNativeResourceVocabulary =
            didDescribeOwnerLocalNativeResourceVocabulary
        this.didDescribeNoHandleSurfaceFacts =
            didDescribeNoHandleSurfaceFacts
        this.didDescribeResourceConfinementFacts =
            didDescribeResourceConfinementFacts
        this.didKeepNativeResourceOwnershipPolicyValueOnly =
            didKeepNativeResourceOwnershipPolicyValueOnly
        this.didAvoidPlatformObjectCreation = didAvoidPlatformObjectCreation
        this.didAvoidNativeResourceTokenCreation =
            didAvoidNativeResourceTokenCreation
        this.didAvoidPointerLikeResource = didAvoidPointerLikeResource
        this.didAvoidRealFfiRetainRelease = didAvoidRealFfiRetainRelease
    }
}

// Lifecycle teardown policy 只表达 future create / retain / release / destroy
// ordering facts；它不定义 FFI call，也不管理真实 resource lifetime。
struct CjguiInternalRendererLifecycleTeardownPolicy {
    let ownershipPolicy: CjguiInternalRendererNativeResourceOwnershipPolicy
    let didPrepareRendererLifecycleTeardownPolicy: Bool
    let shouldDeferRendererLifecycleTeardownPolicy: Bool
    let shouldReportRendererLifecycleTeardownPolicyBlocked: Bool
    let didPreserveRendererNativeResourceOwnershipPolicy: Bool
    let didDefineFutureLifecycleTeardownPolicy: Bool
    let didDescribeAcquireRetainReleaseDestroyOrderFacts: Bool
    let didDescribeFailureRollbackTeardownFacts: Bool
    let didDescribeNoDrawTeardownFallbackFacts: Bool
    let didKeepLifecycleTeardownPolicyValueOnly: Bool
    let didAvoidRealFfiRetainRelease: Bool
    let didAvoidDestroyCallSurface: Bool
    let didAvoidBridgeSmokeHarnessModification: Bool
    let didAvoidBackendImplementation: Bool

    init(
        ownershipPolicy: CjguiInternalRendererNativeResourceOwnershipPolicy,
        didPrepareRendererLifecycleTeardownPolicy: Bool,
        shouldDeferRendererLifecycleTeardownPolicy: Bool,
        shouldReportRendererLifecycleTeardownPolicyBlocked: Bool,
        didPreserveRendererNativeResourceOwnershipPolicy: Bool,
        didDefineFutureLifecycleTeardownPolicy: Bool,
        didDescribeAcquireRetainReleaseDestroyOrderFacts: Bool,
        didDescribeFailureRollbackTeardownFacts: Bool,
        didDescribeNoDrawTeardownFallbackFacts: Bool,
        didKeepLifecycleTeardownPolicyValueOnly: Bool,
        didAvoidRealFfiRetainRelease: Bool,
        didAvoidDestroyCallSurface: Bool,
        didAvoidBridgeSmokeHarnessModification: Bool,
        didAvoidBackendImplementation: Bool
    ) {
        this.ownershipPolicy = ownershipPolicy
        this.didPrepareRendererLifecycleTeardownPolicy =
            didPrepareRendererLifecycleTeardownPolicy
        this.shouldDeferRendererLifecycleTeardownPolicy =
            shouldDeferRendererLifecycleTeardownPolicy
        this.shouldReportRendererLifecycleTeardownPolicyBlocked =
            shouldReportRendererLifecycleTeardownPolicyBlocked
        this.didPreserveRendererNativeResourceOwnershipPolicy =
            didPreserveRendererNativeResourceOwnershipPolicy
        this.didDefineFutureLifecycleTeardownPolicy =
            didDefineFutureLifecycleTeardownPolicy
        this.didDescribeAcquireRetainReleaseDestroyOrderFacts =
            didDescribeAcquireRetainReleaseDestroyOrderFacts
        this.didDescribeFailureRollbackTeardownFacts =
            didDescribeFailureRollbackTeardownFacts
        this.didDescribeNoDrawTeardownFallbackFacts =
            didDescribeNoDrawTeardownFallbackFacts
        this.didKeepLifecycleTeardownPolicyValueOnly =
            didKeepLifecycleTeardownPolicyValueOnly
        this.didAvoidRealFfiRetainRelease = didAvoidRealFfiRetainRelease
        this.didAvoidDestroyCallSurface = didAvoidDestroyCallSurface
        this.didAvoidBridgeSmokeHarnessModification =
            didAvoidBridgeSmokeHarnessModification
        this.didAvoidBackendImplementation = didAvoidBackendImplementation
    }
}

// Confinement failure policy 只表达 future degraded / no-draw containment facts；
// 它不观察真实 native failure，也不把 platform object 交给 core packet。
struct CjguiInternalRendererConfinementFailurePolicy {
    let teardownPolicy: CjguiInternalRendererLifecycleTeardownPolicy
    let didPrepareRendererConfinementFailurePolicy: Bool
    let shouldDeferRendererConfinementFailurePolicy: Bool
    let shouldReportRendererConfinementFailurePolicyBlocked: Bool
    let didPreserveRendererLifecycleTeardownPolicy: Bool
    let didDefineFutureConfinementFailurePolicy: Bool
    let didDescribeOwnerLocalConfinementFacts: Bool
    let didDescribeFailureDegradedNoDrawFacts: Bool
    let didDescribeNoPlatformLeakageFacts: Bool
    let didKeepConfinementFailurePolicyValueOnly: Bool
    let didAvoidPlatformObjectEscape: Bool
    let didAvoidDeviceLayerOwnership: Bool
    let didAvoidGpuSubmission: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidExternalObservationSurface: Bool

    init(
        teardownPolicy: CjguiInternalRendererLifecycleTeardownPolicy,
        didPrepareRendererConfinementFailurePolicy: Bool,
        shouldDeferRendererConfinementFailurePolicy: Bool,
        shouldReportRendererConfinementFailurePolicyBlocked: Bool,
        didPreserveRendererLifecycleTeardownPolicy: Bool,
        didDefineFutureConfinementFailurePolicy: Bool,
        didDescribeOwnerLocalConfinementFacts: Bool,
        didDescribeFailureDegradedNoDrawFacts: Bool,
        didDescribeNoPlatformLeakageFacts: Bool,
        didKeepConfinementFailurePolicyValueOnly: Bool,
        didAvoidPlatformObjectEscape: Bool,
        didAvoidDeviceLayerOwnership: Bool,
        didAvoidGpuSubmission: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidExternalObservationSurface: Bool
    ) {
        this.teardownPolicy = teardownPolicy
        this.didPrepareRendererConfinementFailurePolicy =
            didPrepareRendererConfinementFailurePolicy
        this.shouldDeferRendererConfinementFailurePolicy =
            shouldDeferRendererConfinementFailurePolicy
        this.shouldReportRendererConfinementFailurePolicyBlocked =
            shouldReportRendererConfinementFailurePolicyBlocked
        this.didPreserveRendererLifecycleTeardownPolicy =
            didPreserveRendererLifecycleTeardownPolicy
        this.didDefineFutureConfinementFailurePolicy =
            didDefineFutureConfinementFailurePolicy
        this.didDescribeOwnerLocalConfinementFacts =
            didDescribeOwnerLocalConfinementFacts
        this.didDescribeFailureDegradedNoDrawFacts =
            didDescribeFailureDegradedNoDrawFacts
        this.didDescribeNoPlatformLeakageFacts =
            didDescribeNoPlatformLeakageFacts
        this.didKeepConfinementFailurePolicyValueOnly =
            didKeepConfinementFailurePolicyValueOnly
        this.didAvoidPlatformObjectEscape = didAvoidPlatformObjectEscape
        this.didAvoidDeviceLayerOwnership = didAvoidDeviceLayerOwnership
        this.didAvoidGpuSubmission = didAvoidGpuSubmission
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidExternalObservationSurface =
            didAvoidExternalObservationSurface
    }
}

// No-platform-object readiness 是本 owner 的 endpoint；它确认当前没有
// native handle / raw pointer，也不代表 platform, backend, Metal, submit,
// render, renderer-state, or external API permission。
struct CjguiInternalRendererNoPlatformObjectReadiness {
    let confinementPolicy: CjguiInternalRendererConfinementFailurePolicy
    let isRendererNoPlatformObjectReady: Bool
    let canFutureRendererBackendPlatformObjectBoundaryEvaluate: Bool
    let shouldDeferRendererNoPlatformObjectReadiness: Bool
    let shouldReportRendererNoPlatformObjectReadinessBlocked: Bool
    let didSealRendererNoPlatformObjectReadiness: Bool
    let didPreserveRendererConfinementFailurePolicy: Bool
    let didKeepNoPlatformObjectReadinessValueOnly: Bool
    let didConfirmNoPlatformObjectCreated: Bool
    let didConfirmNoBackendObjectCreated: Bool
    let didConfirmNoNativeResourceToken: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didConfirmNoDeviceOrLayer: Bool
    let didConfirmNoCommandQueueDrawableBufferPassEncoderPipeline: Bool
    let didConfirmNoCommandBufferCommit: Bool
    let didConfirmNoGpuSubmission: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoRendererStateMutation: Bool
    let didConfirmNoBridgeSmokeHarnessEntryChange: Bool
    let didConfirmNoExternalApiSurface: Bool
    let didAvoidPlatformObjectPermission: Bool
    let didAvoidResourceTokenReadinessWrapper: Bool
    let didAvoidBackendImplementationWrapper: Bool
    let didAvoidDeviceLayerReadinessWrapper: Bool
    let didAvoidBackendReadyPermissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        confinementPolicy: CjguiInternalRendererConfinementFailurePolicy,
        isRendererNoPlatformObjectReady: Bool,
        canFutureRendererBackendPlatformObjectBoundaryEvaluate: Bool,
        shouldDeferRendererNoPlatformObjectReadiness: Bool,
        shouldReportRendererNoPlatformObjectReadinessBlocked: Bool,
        didSealRendererNoPlatformObjectReadiness: Bool,
        didPreserveRendererConfinementFailurePolicy: Bool,
        didKeepNoPlatformObjectReadinessValueOnly: Bool,
        didConfirmNoPlatformObjectCreated: Bool,
        didConfirmNoBackendObjectCreated: Bool,
        didConfirmNoNativeResourceToken: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didConfirmNoDeviceOrLayer: Bool,
        didConfirmNoCommandQueueDrawableBufferPassEncoderPipeline: Bool,
        didConfirmNoCommandBufferCommit: Bool,
        didConfirmNoGpuSubmission: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoRendererStateMutation: Bool,
        didConfirmNoBridgeSmokeHarnessEntryChange: Bool,
        didConfirmNoExternalApiSurface: Bool,
        didAvoidPlatformObjectPermission: Bool,
        didAvoidResourceTokenReadinessWrapper: Bool,
        didAvoidBackendImplementationWrapper: Bool,
        didAvoidDeviceLayerReadinessWrapper: Bool,
        didAvoidBackendReadyPermissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.confinementPolicy = confinementPolicy
        this.isRendererNoPlatformObjectReady = isRendererNoPlatformObjectReady
        this.canFutureRendererBackendPlatformObjectBoundaryEvaluate =
            canFutureRendererBackendPlatformObjectBoundaryEvaluate
        this.shouldDeferRendererNoPlatformObjectReadiness =
            shouldDeferRendererNoPlatformObjectReadiness
        this.shouldReportRendererNoPlatformObjectReadinessBlocked =
            shouldReportRendererNoPlatformObjectReadinessBlocked
        this.didSealRendererNoPlatformObjectReadiness =
            didSealRendererNoPlatformObjectReadiness
        this.didPreserveRendererConfinementFailurePolicy =
            didPreserveRendererConfinementFailurePolicy
        this.didKeepNoPlatformObjectReadinessValueOnly =
            didKeepNoPlatformObjectReadinessValueOnly
        this.didConfirmNoPlatformObjectCreated =
            didConfirmNoPlatformObjectCreated
        this.didConfirmNoBackendObjectCreated =
            didConfirmNoBackendObjectCreated
        this.didConfirmNoNativeResourceToken =
            didConfirmNoNativeResourceToken
        this.didConfirmNoPointerLikeResource = didConfirmNoPointerLikeResource
        this.didConfirmNoDeviceOrLayer = didConfirmNoDeviceOrLayer
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
        this.didAvoidPlatformObjectPermission =
            didAvoidPlatformObjectPermission
        this.didAvoidResourceTokenReadinessWrapper =
            didAvoidResourceTokenReadinessWrapper
        this.didAvoidBackendImplementationWrapper =
            didAvoidBackendImplementationWrapper
        this.didAvoidDeviceLayerReadinessWrapper =
            didAvoidDeviceLayerReadinessWrapper
        this.didAvoidBackendReadyPermissionWrapper =
            didAvoidBackendReadyPermissionWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererBackendPlatformObjectOwnerIntent(
    noBackendReadyReadiness: CjguiInternalRendererNoBackendReadyReadiness
): CjguiInternalRendererBackendPlatformObjectOwnerIntent {
    let noBackendReady =
        noBackendReadyReadiness.isRendererNoBackendReadyReady &&
        noBackendReadyReadiness.canFutureRendererBackendReadinessBoundaryEvaluate &&
        noBackendReadyReadiness.didSealRendererNoBackendReadyReadiness &&
        noBackendReadyReadiness.didPreserveRendererStateVisibilityGate &&
        noBackendReadyReadiness.didKeepNoBackendReadyReadinessValueOnly &&
        noBackendReadyReadiness.didConfirmNoBackendObjectCreated &&
        noBackendReadyReadiness.didConfirmNoPlatformObjectCreated &&
        noBackendReadyReadiness.didConfirmNoCommandBufferCommit &&
        noBackendReadyReadiness.didConfirmNoGpuSubmission &&
        noBackendReadyReadiness.didConfirmNoRenderExecution &&
        noBackendReadyReadiness.didConfirmNoRendererStateMutation &&
        noBackendReadyReadiness.didConfirmNoExternalApiSurface &&
        noBackendReadyReadiness.didConfirmNoResourceHandleSurface &&
        noBackendReadyReadiness.didConfirmNoPointerLikeResource &&
        noBackendReadyReadiness.didAvoidBackendReadyPermission &&
        noBackendReadyReadiness.didAvoidRenderPermissionWrapper &&
        noBackendReadyReadiness.didAvoidGpuSubmissionWrapper &&
        noBackendReadyReadiness.didAvoidBackendReadinessReceipt &&
        noBackendReadyReadiness.didAvoidThinWrapper &&
        noBackendReadyReadiness.didStayFullRebuildOnly &&
        noBackendReadyReadiness.shouldDeferRendererNoBackendReadyReadiness == false &&
        noBackendReadyReadiness.shouldReportRendererNoBackendReadyReadinessBlocked == false
    let intentDeferred =
        noBackendReadyReadiness.isRendererNoBackendReadyReady == false &&
        noBackendReadyReadiness.canFutureRendererBackendReadinessBoundaryEvaluate == false &&
        noBackendReadyReadiness.shouldDeferRendererNoBackendReadyReadiness &&
        noBackendReadyReadiness.shouldReportRendererNoBackendReadyReadinessBlocked == false
    let intentInconsistent = (
        noBackendReadyReadiness.isRendererNoBackendReadyReady &&
            (
                noBackendReadyReadiness.canFutureRendererBackendReadinessBoundaryEvaluate == false ||
                noBackendReadyReadiness.didSealRendererNoBackendReadyReadiness == false ||
                noBackendReadyReadiness.didPreserveRendererStateVisibilityGate == false ||
                noBackendReadyReadiness.didKeepNoBackendReadyReadinessValueOnly == false ||
                noBackendReadyReadiness.didConfirmNoBackendObjectCreated == false ||
                noBackendReadyReadiness.didConfirmNoPlatformObjectCreated == false ||
                noBackendReadyReadiness.didConfirmNoCommandBufferCommit == false ||
                noBackendReadyReadiness.didConfirmNoGpuSubmission == false ||
                noBackendReadyReadiness.didConfirmNoRenderExecution == false ||
                noBackendReadyReadiness.didConfirmNoRendererStateMutation == false ||
                noBackendReadyReadiness.didConfirmNoExternalApiSurface == false ||
                noBackendReadyReadiness.didConfirmNoResourceHandleSurface == false ||
                noBackendReadyReadiness.didConfirmNoPointerLikeResource == false ||
                noBackendReadyReadiness.didAvoidBackendReadyPermission == false ||
                noBackendReadyReadiness.didAvoidRenderPermissionWrapper == false ||
                noBackendReadyReadiness.didAvoidGpuSubmissionWrapper == false ||
                noBackendReadyReadiness.didAvoidBackendReadinessReceipt == false ||
                noBackendReadyReadiness.didAvoidThinWrapper == false ||
                noBackendReadyReadiness.didStayFullRebuildOnly == false ||
                noBackendReadyReadiness.shouldDeferRendererNoBackendReadyReadiness ||
                noBackendReadyReadiness.shouldReportRendererNoBackendReadyReadinessBlocked
            )
        ) ||
        (noBackendReadyReadiness.canFutureRendererBackendReadinessBoundaryEvaluate &&
            noBackendReadyReadiness.isRendererNoBackendReadyReady == false) ||
        (noBackendReadyReadiness.shouldDeferRendererNoBackendReadyReadiness &&
            noBackendReadyReadiness.shouldReportRendererNoBackendReadyReadinessBlocked)

    // fail-closed：不能把 no-backend-ready readiness 薄包成 platform object intent。
    if (
        noBackendReadyReadiness.shouldReportRendererNoBackendReadyReadinessBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererBackendPlatformObjectOwnerIntent(
            noBackendReadyReadiness,
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

    if (noBackendReady) {
        return CjguiInternalRendererBackendPlatformObjectOwnerIntent(
            noBackendReadyReadiness,
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
        return CjguiInternalRendererBackendPlatformObjectOwnerIntent(
            noBackendReadyReadiness,
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

    return CjguiInternalRendererBackendPlatformObjectOwnerIntent(
        noBackendReadyReadiness,
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

func cjguiInternalBuildRendererNativeResourceOwnershipPolicy(
    ownerIntent: CjguiInternalRendererBackendPlatformObjectOwnerIntent
): CjguiInternalRendererNativeResourceOwnershipPolicy {
    let intentReady =
        ownerIntent.didPrepareRendererBackendPlatformObjectOwnerIntent &&
        ownerIntent.didPreserveRendererNoBackendReadyReadiness &&
        ownerIntent.didDefineFutureBackendPlatformObjectOwnerIntent &&
        ownerIntent.didDescribeNativeResourceOwnerFacts &&
        ownerIntent.didDescribeLifecycleTeardownFacts &&
        ownerIntent.didDescribeConfinementFailureFacts &&
        ownerIntent.didKeepBackendPlatformObjectOwnerIntentValueOnly &&
        ownerIntent.didAvoidPlatformObjectCreation &&
        ownerIntent.didAvoidNativeResourceSurface &&
        ownerIntent.didAvoidBackendImplementationPermission &&
        ownerIntent.didAvoidDeviceLayerReadinessWrapper &&
        ownerIntent.didAvoidThinWrapper &&
        ownerIntent.shouldDeferRendererBackendPlatformObjectOwnerIntent == false &&
        ownerIntent.shouldReportRendererBackendPlatformObjectOwnerIntentBlocked == false
    let policyDeferred =
        ownerIntent.didPrepareRendererBackendPlatformObjectOwnerIntent == false &&
        ownerIntent.shouldDeferRendererBackendPlatformObjectOwnerIntent &&
        ownerIntent.shouldReportRendererBackendPlatformObjectOwnerIntentBlocked == false
    let policyInconsistent = (
        ownerIntent.didPrepareRendererBackendPlatformObjectOwnerIntent &&
            (
                ownerIntent.didPreserveRendererNoBackendReadyReadiness == false ||
                ownerIntent.didDefineFutureBackendPlatformObjectOwnerIntent == false ||
                ownerIntent.didDescribeNativeResourceOwnerFacts == false ||
                ownerIntent.didDescribeLifecycleTeardownFacts == false ||
                ownerIntent.didDescribeConfinementFailureFacts == false ||
                ownerIntent.didKeepBackendPlatformObjectOwnerIntentValueOnly == false ||
                ownerIntent.didAvoidPlatformObjectCreation == false ||
                ownerIntent.didAvoidNativeResourceSurface == false ||
                ownerIntent.didAvoidBackendImplementationPermission == false ||
                ownerIntent.didAvoidDeviceLayerReadinessWrapper == false ||
                ownerIntent.didAvoidThinWrapper == false ||
                ownerIntent.shouldDeferRendererBackendPlatformObjectOwnerIntent ||
                ownerIntent.shouldReportRendererBackendPlatformObjectOwnerIntentBlocked
            )
        ) ||
        (ownerIntent.didPreserveRendererNoBackendReadyReadiness &&
            ownerIntent.didPrepareRendererBackendPlatformObjectOwnerIntent == false) ||
        (ownerIntent.shouldDeferRendererBackendPlatformObjectOwnerIntent &&
            ownerIntent.shouldReportRendererBackendPlatformObjectOwnerIntentBlocked)

    // ownership policy 只记录 owner-local vocabulary；这里不创建 resource handle。
    if (
        ownerIntent.shouldReportRendererBackendPlatformObjectOwnerIntentBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererNativeResourceOwnershipPolicy(
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
        return CjguiInternalRendererNativeResourceOwnershipPolicy(
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

    if (policyDeferred) {
        return CjguiInternalRendererNativeResourceOwnershipPolicy(
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

    return CjguiInternalRendererNativeResourceOwnershipPolicy(
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

func cjguiInternalBuildRendererLifecycleTeardownPolicy(
    ownershipPolicy: CjguiInternalRendererNativeResourceOwnershipPolicy
): CjguiInternalRendererLifecycleTeardownPolicy {
    let policyReady =
        ownershipPolicy.didPrepareRendererNativeResourceOwnershipPolicy &&
        ownershipPolicy.didPreserveRendererBackendPlatformObjectOwnerIntent &&
        ownershipPolicy.didDefineFutureNativeResourceOwnershipPolicy &&
        ownershipPolicy.didDescribeOwnerLocalNativeResourceVocabulary &&
        ownershipPolicy.didDescribeNoHandleSurfaceFacts &&
        ownershipPolicy.didDescribeResourceConfinementFacts &&
        ownershipPolicy.didKeepNativeResourceOwnershipPolicyValueOnly &&
        ownershipPolicy.didAvoidPlatformObjectCreation &&
        ownershipPolicy.didAvoidNativeResourceTokenCreation &&
        ownershipPolicy.didAvoidPointerLikeResource &&
        ownershipPolicy.didAvoidRealFfiRetainRelease &&
        ownershipPolicy.shouldDeferRendererNativeResourceOwnershipPolicy == false &&
        ownershipPolicy.shouldReportRendererNativeResourceOwnershipPolicyBlocked == false
    let teardownDeferred =
        ownershipPolicy.didPrepareRendererNativeResourceOwnershipPolicy == false &&
        ownershipPolicy.shouldDeferRendererNativeResourceOwnershipPolicy &&
        ownershipPolicy.shouldReportRendererNativeResourceOwnershipPolicyBlocked == false
    let teardownInconsistent = (
        ownershipPolicy.didPrepareRendererNativeResourceOwnershipPolicy &&
            (
                ownershipPolicy.didPreserveRendererBackendPlatformObjectOwnerIntent == false ||
                ownershipPolicy.didDefineFutureNativeResourceOwnershipPolicy == false ||
                ownershipPolicy.didDescribeOwnerLocalNativeResourceVocabulary == false ||
                ownershipPolicy.didDescribeNoHandleSurfaceFacts == false ||
                ownershipPolicy.didDescribeResourceConfinementFacts == false ||
                ownershipPolicy.didKeepNativeResourceOwnershipPolicyValueOnly == false ||
                ownershipPolicy.didAvoidPlatformObjectCreation == false ||
                ownershipPolicy.didAvoidNativeResourceTokenCreation == false ||
                ownershipPolicy.didAvoidPointerLikeResource == false ||
                ownershipPolicy.didAvoidRealFfiRetainRelease == false ||
                ownershipPolicy.shouldDeferRendererNativeResourceOwnershipPolicy ||
                ownershipPolicy.shouldReportRendererNativeResourceOwnershipPolicyBlocked
            )
        ) ||
        (ownershipPolicy.didPreserveRendererBackendPlatformObjectOwnerIntent &&
            ownershipPolicy.didPrepareRendererNativeResourceOwnershipPolicy == false) ||
        (ownershipPolicy.shouldDeferRendererNativeResourceOwnershipPolicy &&
            ownershipPolicy.shouldReportRendererNativeResourceOwnershipPolicyBlocked)

    // teardown policy 只记录 order facts；这里不定义 retain / release call。
    if (
        ownershipPolicy.shouldReportRendererNativeResourceOwnershipPolicyBlocked ||
        teardownInconsistent
    ) {
        return CjguiInternalRendererLifecycleTeardownPolicy(
            ownershipPolicy,
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

    if (policyReady) {
        return CjguiInternalRendererLifecycleTeardownPolicy(
            ownershipPolicy,
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
        return CjguiInternalRendererLifecycleTeardownPolicy(
            ownershipPolicy,
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

    return CjguiInternalRendererLifecycleTeardownPolicy(
        ownershipPolicy,
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

func cjguiInternalBuildRendererConfinementFailurePolicy(
    teardownPolicy: CjguiInternalRendererLifecycleTeardownPolicy
): CjguiInternalRendererConfinementFailurePolicy {
    let teardownReady =
        teardownPolicy.didPrepareRendererLifecycleTeardownPolicy &&
        teardownPolicy.didPreserveRendererNativeResourceOwnershipPolicy &&
        teardownPolicy.didDefineFutureLifecycleTeardownPolicy &&
        teardownPolicy.didDescribeAcquireRetainReleaseDestroyOrderFacts &&
        teardownPolicy.didDescribeFailureRollbackTeardownFacts &&
        teardownPolicy.didDescribeNoDrawTeardownFallbackFacts &&
        teardownPolicy.didKeepLifecycleTeardownPolicyValueOnly &&
        teardownPolicy.didAvoidRealFfiRetainRelease &&
        teardownPolicy.didAvoidDestroyCallSurface &&
        teardownPolicy.didAvoidBridgeSmokeHarnessModification &&
        teardownPolicy.didAvoidBackendImplementation &&
        teardownPolicy.shouldDeferRendererLifecycleTeardownPolicy == false &&
        teardownPolicy.shouldReportRendererLifecycleTeardownPolicyBlocked == false
    let confinementDeferred =
        teardownPolicy.didPrepareRendererLifecycleTeardownPolicy == false &&
        teardownPolicy.shouldDeferRendererLifecycleTeardownPolicy &&
        teardownPolicy.shouldReportRendererLifecycleTeardownPolicyBlocked == false
    let confinementInconsistent = (
        teardownPolicy.didPrepareRendererLifecycleTeardownPolicy &&
            (
                teardownPolicy.didPreserveRendererNativeResourceOwnershipPolicy == false ||
                teardownPolicy.didDefineFutureLifecycleTeardownPolicy == false ||
                teardownPolicy.didDescribeAcquireRetainReleaseDestroyOrderFacts == false ||
                teardownPolicy.didDescribeFailureRollbackTeardownFacts == false ||
                teardownPolicy.didDescribeNoDrawTeardownFallbackFacts == false ||
                teardownPolicy.didKeepLifecycleTeardownPolicyValueOnly == false ||
                teardownPolicy.didAvoidRealFfiRetainRelease == false ||
                teardownPolicy.didAvoidDestroyCallSurface == false ||
                teardownPolicy.didAvoidBridgeSmokeHarnessModification == false ||
                teardownPolicy.didAvoidBackendImplementation == false ||
                teardownPolicy.shouldDeferRendererLifecycleTeardownPolicy ||
                teardownPolicy.shouldReportRendererLifecycleTeardownPolicyBlocked
            )
        ) ||
        (teardownPolicy.didPreserveRendererNativeResourceOwnershipPolicy &&
            teardownPolicy.didPrepareRendererLifecycleTeardownPolicy == false) ||
        (teardownPolicy.shouldDeferRendererLifecycleTeardownPolicy &&
            teardownPolicy.shouldReportRendererLifecycleTeardownPolicyBlocked)

    // confinement policy 只记录 degraded / no-draw facts；这里不观察 native failure。
    if (
        teardownPolicy.shouldReportRendererLifecycleTeardownPolicyBlocked ||
        confinementInconsistent
    ) {
        return CjguiInternalRendererConfinementFailurePolicy(
            teardownPolicy,
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

    if (teardownReady) {
        return CjguiInternalRendererConfinementFailurePolicy(
            teardownPolicy,
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

    if (confinementDeferred) {
        return CjguiInternalRendererConfinementFailurePolicy(
            teardownPolicy,
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

    return CjguiInternalRendererConfinementFailurePolicy(
        teardownPolicy,
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

func cjguiInternalBuildRendererNoPlatformObjectReadiness(
    confinementPolicy: CjguiInternalRendererConfinementFailurePolicy
): CjguiInternalRendererNoPlatformObjectReadiness {
    let confinementReady =
        confinementPolicy.didPrepareRendererConfinementFailurePolicy &&
        confinementPolicy.didPreserveRendererLifecycleTeardownPolicy &&
        confinementPolicy.didDefineFutureConfinementFailurePolicy &&
        confinementPolicy.didDescribeOwnerLocalConfinementFacts &&
        confinementPolicy.didDescribeFailureDegradedNoDrawFacts &&
        confinementPolicy.didDescribeNoPlatformLeakageFacts &&
        confinementPolicy.didKeepConfinementFailurePolicyValueOnly &&
        confinementPolicy.didAvoidPlatformObjectEscape &&
        confinementPolicy.didAvoidDeviceLayerOwnership &&
        confinementPolicy.didAvoidGpuSubmission &&
        confinementPolicy.didAvoidRendererStateMutation &&
        confinementPolicy.didAvoidExternalObservationSurface &&
        confinementPolicy.shouldDeferRendererConfinementFailurePolicy == false &&
        confinementPolicy.shouldReportRendererConfinementFailurePolicyBlocked == false
    let readinessDeferred =
        confinementPolicy.didPrepareRendererConfinementFailurePolicy == false &&
        confinementPolicy.shouldDeferRendererConfinementFailurePolicy &&
        confinementPolicy.shouldReportRendererConfinementFailurePolicyBlocked == false
    let readinessInconsistent = (
        confinementPolicy.didPrepareRendererConfinementFailurePolicy &&
            (
                confinementPolicy.didPreserveRendererLifecycleTeardownPolicy == false ||
                confinementPolicy.didDefineFutureConfinementFailurePolicy == false ||
                confinementPolicy.didDescribeOwnerLocalConfinementFacts == false ||
                confinementPolicy.didDescribeFailureDegradedNoDrawFacts == false ||
                confinementPolicy.didDescribeNoPlatformLeakageFacts == false ||
                confinementPolicy.didKeepConfinementFailurePolicyValueOnly == false ||
                confinementPolicy.didAvoidPlatformObjectEscape == false ||
                confinementPolicy.didAvoidDeviceLayerOwnership == false ||
                confinementPolicy.didAvoidGpuSubmission == false ||
                confinementPolicy.didAvoidRendererStateMutation == false ||
                confinementPolicy.didAvoidExternalObservationSurface == false ||
                confinementPolicy.shouldDeferRendererConfinementFailurePolicy ||
                confinementPolicy.shouldReportRendererConfinementFailurePolicyBlocked
            )
        ) ||
        (confinementPolicy.didPreserveRendererLifecycleTeardownPolicy &&
            confinementPolicy.didPrepareRendererConfinementFailurePolicy == false) ||
        (confinementPolicy.shouldDeferRendererConfinementFailurePolicy &&
            confinementPolicy.shouldReportRendererConfinementFailurePolicyBlocked)

    // endpoint 只 sealing no-platform-object facts；这里不 create receipt / record。
    if (
        confinementPolicy.shouldReportRendererConfinementFailurePolicyBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoPlatformObjectReadiness(
            confinementPolicy,
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

    if (confinementReady) {
        return CjguiInternalRendererNoPlatformObjectReadiness(
            confinementPolicy,
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
        return CjguiInternalRendererNoPlatformObjectReadiness(
            confinementPolicy,
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

    return CjguiInternalRendererNoPlatformObjectReadiness(
        confinementPolicy,
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

func cjguiInternalExecuteDefaultRendererBackendPlatformObjectOwnerDraft(
): CjguiInternalRendererNoPlatformObjectReadiness {
    let noBackendReadyReadiness =
        cjguiInternalExecuteDefaultRendererBackendReadinessDraft()
    let ownerIntent =
        cjguiInternalBuildRendererBackendPlatformObjectOwnerIntent(
            noBackendReadyReadiness
        )
    let ownershipPolicy =
        cjguiInternalBuildRendererNativeResourceOwnershipPolicy(ownerIntent)
    let teardownPolicy =
        cjguiInternalBuildRendererLifecycleTeardownPolicy(ownershipPolicy)
    let confinementPolicy =
        cjguiInternalBuildRendererConfinementFailurePolicy(teardownPolicy)
    return cjguiInternalBuildRendererNoPlatformObjectReadiness(
        confinementPolicy
    )
}
