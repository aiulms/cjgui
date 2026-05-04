package cjgui

// Owner: Renderer backend object owner value boundary.
// Truth: 只消费 CjguiInternalRendererNoRenderExecutionReadiness，表达 future
// backend object owner intent、lifecycle ownership policy、acceptance gate、
// platform confinement guard 与 no-backend-object readiness 的内部 value facts。
// Stop-line: 这里不创建 backend object，不创建 MTLDevice / CAMetalLayer，不创建
// command queue、drawable、command buffer、render pass descriptor、encoder 或
// pipeline state，不提交 GPU work，不触发 render side effect，不写 renderer state。
// Same-shape Boundary Brake: 本 owner 新增 owner / lifecycle / acceptance gate /
// platform confinement / no-backend-object vocabulary，不把 no-render-execution
// readiness 包成 receipt / record / publication。

// Backend object owner intent 只表达 future owner intent；
// 它不是 backend object creation，也不是 backend-readiness final gate。
struct CjguiInternalRendererBackendObjectOwnerIntent {
    let noRenderExecutionReadiness: CjguiInternalRendererNoRenderExecutionReadiness
    let didPrepareRendererBackendObjectOwnerIntent: Bool
    let shouldDeferRendererBackendObjectOwnerIntent: Bool
    let shouldReportRendererBackendObjectOwnerIntentBlocked: Bool
    let didPreserveRendererNoRenderExecutionReadiness: Bool
    let didDefineFutureBackendObjectOwnerIntent: Bool
    let didDescribeBackendOwnerIdentityFacts: Bool
    let didDescribeBackendLifecycleOwnerFacts: Bool
    let didDescribeBackendAcceptanceFacts: Bool
    let didKeepBackendObjectOwnerIntentValueOnly: Bool
    let didAvoidBackendObjectCreation: Bool
    let didAvoidPlatformObjectCreation: Bool
    let didAvoidRenderSideEffect: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidThinWrapper: Bool

    init(
        noRenderExecutionReadiness: CjguiInternalRendererNoRenderExecutionReadiness,
        didPrepareRendererBackendObjectOwnerIntent: Bool,
        shouldDeferRendererBackendObjectOwnerIntent: Bool,
        shouldReportRendererBackendObjectOwnerIntentBlocked: Bool,
        didPreserveRendererNoRenderExecutionReadiness: Bool,
        didDefineFutureBackendObjectOwnerIntent: Bool,
        didDescribeBackendOwnerIdentityFacts: Bool,
        didDescribeBackendLifecycleOwnerFacts: Bool,
        didDescribeBackendAcceptanceFacts: Bool,
        didKeepBackendObjectOwnerIntentValueOnly: Bool,
        didAvoidBackendObjectCreation: Bool,
        didAvoidPlatformObjectCreation: Bool,
        didAvoidRenderSideEffect: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noRenderExecutionReadiness = noRenderExecutionReadiness
        this.didPrepareRendererBackendObjectOwnerIntent =
            didPrepareRendererBackendObjectOwnerIntent
        this.shouldDeferRendererBackendObjectOwnerIntent =
            shouldDeferRendererBackendObjectOwnerIntent
        this.shouldReportRendererBackendObjectOwnerIntentBlocked =
            shouldReportRendererBackendObjectOwnerIntentBlocked
        this.didPreserveRendererNoRenderExecutionReadiness =
            didPreserveRendererNoRenderExecutionReadiness
        this.didDefineFutureBackendObjectOwnerIntent =
            didDefineFutureBackendObjectOwnerIntent
        this.didDescribeBackendOwnerIdentityFacts =
            didDescribeBackendOwnerIdentityFacts
        this.didDescribeBackendLifecycleOwnerFacts =
            didDescribeBackendLifecycleOwnerFacts
        this.didDescribeBackendAcceptanceFacts =
            didDescribeBackendAcceptanceFacts
        this.didKeepBackendObjectOwnerIntentValueOnly =
            didKeepBackendObjectOwnerIntentValueOnly
        this.didAvoidBackendObjectCreation = didAvoidBackendObjectCreation
        this.didAvoidPlatformObjectCreation = didAvoidPlatformObjectCreation
        this.didAvoidRenderSideEffect = didAvoidRenderSideEffect
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

// Backend lifecycle ownership policy 只表达 future init / active / teardown /
// failure / rollback lifecycle facts；它不管理真实 backend lifetime。
struct CjguiInternalRendererBackendLifecycleOwnershipPolicy {
    let ownerIntent: CjguiInternalRendererBackendObjectOwnerIntent
    let didPrepareRendererBackendLifecycleOwnershipPolicy: Bool
    let shouldDeferRendererBackendLifecycleOwnershipPolicy: Bool
    let shouldReportRendererBackendLifecycleOwnershipPolicyBlocked: Bool
    let didPreserveRendererBackendObjectOwnerIntent: Bool
    let didDefineFutureBackendLifecycleOwnershipPolicy: Bool
    let didDescribeBackendInitPhaseFacts: Bool
    let didDescribeBackendActivePhaseFacts: Bool
    let didDescribeBackendTeardownPhaseFacts: Bool
    let didDescribeBackendFailureRollbackFacts: Bool
    let didKeepBackendLifecycleOwnershipPolicyValueOnly: Bool
    let didAvoidBackendObjectCreation: Bool
    let didAvoidResourceLifetimeManagement: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidRenderSideEffect: Bool

    init(
        ownerIntent: CjguiInternalRendererBackendObjectOwnerIntent,
        didPrepareRendererBackendLifecycleOwnershipPolicy: Bool,
        shouldDeferRendererBackendLifecycleOwnershipPolicy: Bool,
        shouldReportRendererBackendLifecycleOwnershipPolicyBlocked: Bool,
        didPreserveRendererBackendObjectOwnerIntent: Bool,
        didDefineFutureBackendLifecycleOwnershipPolicy: Bool,
        didDescribeBackendInitPhaseFacts: Bool,
        didDescribeBackendActivePhaseFacts: Bool,
        didDescribeBackendTeardownPhaseFacts: Bool,
        didDescribeBackendFailureRollbackFacts: Bool,
        didKeepBackendLifecycleOwnershipPolicyValueOnly: Bool,
        didAvoidBackendObjectCreation: Bool,
        didAvoidResourceLifetimeManagement: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidRenderSideEffect: Bool
    ) {
        this.ownerIntent = ownerIntent
        this.didPrepareRendererBackendLifecycleOwnershipPolicy =
            didPrepareRendererBackendLifecycleOwnershipPolicy
        this.shouldDeferRendererBackendLifecycleOwnershipPolicy =
            shouldDeferRendererBackendLifecycleOwnershipPolicy
        this.shouldReportRendererBackendLifecycleOwnershipPolicyBlocked =
            shouldReportRendererBackendLifecycleOwnershipPolicyBlocked
        this.didPreserveRendererBackendObjectOwnerIntent =
            didPreserveRendererBackendObjectOwnerIntent
        this.didDefineFutureBackendLifecycleOwnershipPolicy =
            didDefineFutureBackendLifecycleOwnershipPolicy
        this.didDescribeBackendInitPhaseFacts =
            didDescribeBackendInitPhaseFacts
        this.didDescribeBackendActivePhaseFacts =
            didDescribeBackendActivePhaseFacts
        this.didDescribeBackendTeardownPhaseFacts =
            didDescribeBackendTeardownPhaseFacts
        this.didDescribeBackendFailureRollbackFacts =
            didDescribeBackendFailureRollbackFacts
        this.didKeepBackendLifecycleOwnershipPolicyValueOnly =
            didKeepBackendLifecycleOwnershipPolicyValueOnly
        this.didAvoidBackendObjectCreation = didAvoidBackendObjectCreation
        this.didAvoidResourceLifetimeManagement =
            didAvoidResourceLifetimeManagement
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidRenderSideEffect = didAvoidRenderSideEffect
    }
}

// Backend acceptance gate 只表达 future acceptance constraints；
// 它不授予 backend readiness，不打开 platform or render permission。
struct CjguiInternalRendererBackendAcceptanceGate {
    let lifecyclePolicy: CjguiInternalRendererBackendLifecycleOwnershipPolicy
    let didPrepareRendererBackendAcceptanceGate: Bool
    let shouldDeferRendererBackendAcceptanceGate: Bool
    let shouldReportRendererBackendAcceptanceGateBlocked: Bool
    let didPreserveRendererBackendLifecycleOwnershipPolicy: Bool
    let didDefineFutureBackendAcceptanceGate: Bool
    let didDescribeLifecycleCoverageAcceptance: Bool
    let didDescribeNoSubmitAcceptance: Bool
    let didDescribeNoDrawRollbackAcceptance: Bool
    let didKeepBackendAcceptanceGateValueOnly: Bool
    let didAvoidBackendReadinessPermission: Bool
    let didAvoidPlatformPermission: Bool
    let didAvoidRenderPermission: Bool
    let didAvoidRendererStateMutation: Bool

    init(
        lifecyclePolicy: CjguiInternalRendererBackendLifecycleOwnershipPolicy,
        didPrepareRendererBackendAcceptanceGate: Bool,
        shouldDeferRendererBackendAcceptanceGate: Bool,
        shouldReportRendererBackendAcceptanceGateBlocked: Bool,
        didPreserveRendererBackendLifecycleOwnershipPolicy: Bool,
        didDefineFutureBackendAcceptanceGate: Bool,
        didDescribeLifecycleCoverageAcceptance: Bool,
        didDescribeNoSubmitAcceptance: Bool,
        didDescribeNoDrawRollbackAcceptance: Bool,
        didKeepBackendAcceptanceGateValueOnly: Bool,
        didAvoidBackendReadinessPermission: Bool,
        didAvoidPlatformPermission: Bool,
        didAvoidRenderPermission: Bool,
        didAvoidRendererStateMutation: Bool
    ) {
        this.lifecyclePolicy = lifecyclePolicy
        this.didPrepareRendererBackendAcceptanceGate =
            didPrepareRendererBackendAcceptanceGate
        this.shouldDeferRendererBackendAcceptanceGate =
            shouldDeferRendererBackendAcceptanceGate
        this.shouldReportRendererBackendAcceptanceGateBlocked =
            shouldReportRendererBackendAcceptanceGateBlocked
        this.didPreserveRendererBackendLifecycleOwnershipPolicy =
            didPreserveRendererBackendLifecycleOwnershipPolicy
        this.didDefineFutureBackendAcceptanceGate =
            didDefineFutureBackendAcceptanceGate
        this.didDescribeLifecycleCoverageAcceptance =
            didDescribeLifecycleCoverageAcceptance
        this.didDescribeNoSubmitAcceptance = didDescribeNoSubmitAcceptance
        this.didDescribeNoDrawRollbackAcceptance =
            didDescribeNoDrawRollbackAcceptance
        this.didKeepBackendAcceptanceGateValueOnly =
            didKeepBackendAcceptanceGateValueOnly
        this.didAvoidBackendReadinessPermission =
            didAvoidBackendReadinessPermission
        this.didAvoidPlatformPermission = didAvoidPlatformPermission
        this.didAvoidRenderPermission = didAvoidRenderPermission
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
    }
}

// Platform confinement guard 只表达 future platform ownership confinement；
// platform concepts may be policy targets, but no platform object is held here.
struct CjguiInternalRendererPlatformConfinementGuard {
    let acceptanceGate: CjguiInternalRendererBackendAcceptanceGate
    let didPrepareRendererPlatformConfinementGuard: Bool
    let shouldDeferRendererPlatformConfinementGuard: Bool
    let shouldReportRendererPlatformConfinementGuardBlocked: Bool
    let didPreserveRendererBackendAcceptanceGate: Bool
    let didDefineFuturePlatformConfinementGuard: Bool
    let didConfineDeviceAndLayerToFutureBackendOwner: Bool
    let didConfineQueueDrawableBufferPassEncoderPipeline: Bool
    let didKeepCorePacketFreeOfPlatformObjects: Bool
    let didKeepPlatformConfinementGuardValueOnly: Bool
    let didAvoidPlatformObjectCreation: Bool
    let didAvoidResourceHandleSurface: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidRenderSideEffect: Bool

    init(
        acceptanceGate: CjguiInternalRendererBackendAcceptanceGate,
        didPrepareRendererPlatformConfinementGuard: Bool,
        shouldDeferRendererPlatformConfinementGuard: Bool,
        shouldReportRendererPlatformConfinementGuardBlocked: Bool,
        didPreserveRendererBackendAcceptanceGate: Bool,
        didDefineFuturePlatformConfinementGuard: Bool,
        didConfineDeviceAndLayerToFutureBackendOwner: Bool,
        didConfineQueueDrawableBufferPassEncoderPipeline: Bool,
        didKeepCorePacketFreeOfPlatformObjects: Bool,
        didKeepPlatformConfinementGuardValueOnly: Bool,
        didAvoidPlatformObjectCreation: Bool,
        didAvoidResourceHandleSurface: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidRenderSideEffect: Bool
    ) {
        this.acceptanceGate = acceptanceGate
        this.didPrepareRendererPlatformConfinementGuard =
            didPrepareRendererPlatformConfinementGuard
        this.shouldDeferRendererPlatformConfinementGuard =
            shouldDeferRendererPlatformConfinementGuard
        this.shouldReportRendererPlatformConfinementGuardBlocked =
            shouldReportRendererPlatformConfinementGuardBlocked
        this.didPreserveRendererBackendAcceptanceGate =
            didPreserveRendererBackendAcceptanceGate
        this.didDefineFuturePlatformConfinementGuard =
            didDefineFuturePlatformConfinementGuard
        this.didConfineDeviceAndLayerToFutureBackendOwner =
            didConfineDeviceAndLayerToFutureBackendOwner
        this.didConfineQueueDrawableBufferPassEncoderPipeline =
            didConfineQueueDrawableBufferPassEncoderPipeline
        this.didKeepCorePacketFreeOfPlatformObjects =
            didKeepCorePacketFreeOfPlatformObjects
        this.didKeepPlatformConfinementGuardValueOnly =
            didKeepPlatformConfinementGuardValueOnly
        this.didAvoidPlatformObjectCreation = didAvoidPlatformObjectCreation
        this.didAvoidResourceHandleSurface = didAvoidResourceHandleSurface
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidRenderSideEffect = didAvoidRenderSideEffect
    }
}

// No-backend-object readiness 是本 owner 的 endpoint；readiness 只表示 future
// backend object owner boundary 可以继续评估，不代表 backend, platform, submit,
// render, or renderer-state permission。
struct CjguiInternalRendererNoBackendObjectReadiness {
    let confinementGuard: CjguiInternalRendererPlatformConfinementGuard
    let isRendererNoBackendObjectReady: Bool
    let canFutureRendererBackendObjectBoundaryEvaluate: Bool
    let shouldDeferRendererNoBackendObjectReadiness: Bool
    let shouldReportRendererNoBackendObjectReadinessBlocked: Bool
    let didSealRendererNoBackendObjectReadiness: Bool
    let didPreserveRendererPlatformConfinementGuard: Bool
    let didKeepNoBackendObjectReadinessValueOnly: Bool
    let didConfirmNoBackendObjectCreated: Bool
    let didConfirmNoPlatformObjectCreated: Bool
    let didConfirmNoCommandBufferCommit: Bool
    let didConfirmNoGpuSubmission: Bool
    let didConfirmNoRenderSideEffect: Bool
    let didConfirmNoRendererStateMutation: Bool
    let didConfirmNoResourceHandleSurface: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didAvoidBackendReadinessPermission: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        confinementGuard: CjguiInternalRendererPlatformConfinementGuard,
        isRendererNoBackendObjectReady: Bool,
        canFutureRendererBackendObjectBoundaryEvaluate: Bool,
        shouldDeferRendererNoBackendObjectReadiness: Bool,
        shouldReportRendererNoBackendObjectReadinessBlocked: Bool,
        didSealRendererNoBackendObjectReadiness: Bool,
        didPreserveRendererPlatformConfinementGuard: Bool,
        didKeepNoBackendObjectReadinessValueOnly: Bool,
        didConfirmNoBackendObjectCreated: Bool,
        didConfirmNoPlatformObjectCreated: Bool,
        didConfirmNoCommandBufferCommit: Bool,
        didConfirmNoGpuSubmission: Bool,
        didConfirmNoRenderSideEffect: Bool,
        didConfirmNoRendererStateMutation: Bool,
        didConfirmNoResourceHandleSurface: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didAvoidBackendReadinessPermission: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.confinementGuard = confinementGuard
        this.isRendererNoBackendObjectReady = isRendererNoBackendObjectReady
        this.canFutureRendererBackendObjectBoundaryEvaluate =
            canFutureRendererBackendObjectBoundaryEvaluate
        this.shouldDeferRendererNoBackendObjectReadiness =
            shouldDeferRendererNoBackendObjectReadiness
        this.shouldReportRendererNoBackendObjectReadinessBlocked =
            shouldReportRendererNoBackendObjectReadinessBlocked
        this.didSealRendererNoBackendObjectReadiness =
            didSealRendererNoBackendObjectReadiness
        this.didPreserveRendererPlatformConfinementGuard =
            didPreserveRendererPlatformConfinementGuard
        this.didKeepNoBackendObjectReadinessValueOnly =
            didKeepNoBackendObjectReadinessValueOnly
        this.didConfirmNoBackendObjectCreated = didConfirmNoBackendObjectCreated
        this.didConfirmNoPlatformObjectCreated = didConfirmNoPlatformObjectCreated
        this.didConfirmNoCommandBufferCommit = didConfirmNoCommandBufferCommit
        this.didConfirmNoGpuSubmission = didConfirmNoGpuSubmission
        this.didConfirmNoRenderSideEffect = didConfirmNoRenderSideEffect
        this.didConfirmNoRendererStateMutation = didConfirmNoRendererStateMutation
        this.didConfirmNoResourceHandleSurface = didConfirmNoResourceHandleSurface
        this.didConfirmNoPointerLikeResource = didConfirmNoPointerLikeResource
        this.didAvoidBackendReadinessPermission =
            didAvoidBackendReadinessPermission
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererBackendObjectOwnerIntent(
    noRenderExecutionReadiness: CjguiInternalRendererNoRenderExecutionReadiness
): CjguiInternalRendererBackendObjectOwnerIntent {
    let noRenderExecutionReady =
        noRenderExecutionReadiness.isRendererNoRenderExecutionReady &&
        noRenderExecutionReadiness.canFutureRendererRenderExecutionBoundaryEvaluate &&
        noRenderExecutionReadiness.didSealRendererNoRenderExecutionReadiness &&
        noRenderExecutionReadiness.didPreserveRendererCompletionObservationPolicy &&
        noRenderExecutionReadiness.didKeepNoRenderExecutionReadinessValueOnly &&
        noRenderExecutionReadiness.didConfirmNoRenderExecution &&
        noRenderExecutionReadiness.didConfirmNoGpuSubmission &&
        noRenderExecutionReadiness.didConfirmNoCommandBufferCommit &&
        noRenderExecutionReadiness.didConfirmNoEncoderCall &&
        noRenderExecutionReadiness.didConfirmNoPipelineBinding &&
        noRenderExecutionReadiness.didConfirmNoDrawablePresentation &&
        noRenderExecutionReadiness.didConfirmNoRendererStateWrite &&
        noRenderExecutionReadiness.didConfirmNoNativeResourceToken &&
        noRenderExecutionReadiness.didConfirmNoPointerLikeResource &&
        noRenderExecutionReadiness.didAvoidBackendPermission &&
        noRenderExecutionReadiness.didAvoidThinWrapper &&
        noRenderExecutionReadiness.didStayFullRebuildOnly &&
        noRenderExecutionReadiness.shouldDeferRendererNoRenderExecutionReadiness == false &&
        noRenderExecutionReadiness.shouldReportRendererNoRenderExecutionReadinessBlocked == false
    let intentDeferred =
        noRenderExecutionReadiness.isRendererNoRenderExecutionReady == false &&
        noRenderExecutionReadiness.canFutureRendererRenderExecutionBoundaryEvaluate == false &&
        noRenderExecutionReadiness.shouldDeferRendererNoRenderExecutionReadiness &&
        noRenderExecutionReadiness.shouldReportRendererNoRenderExecutionReadinessBlocked == false
    let intentInconsistent = (
        noRenderExecutionReadiness.isRendererNoRenderExecutionReady &&
            (
                noRenderExecutionReadiness.canFutureRendererRenderExecutionBoundaryEvaluate == false ||
                noRenderExecutionReadiness.didSealRendererNoRenderExecutionReadiness == false ||
                noRenderExecutionReadiness.didPreserveRendererCompletionObservationPolicy == false ||
                noRenderExecutionReadiness.didKeepNoRenderExecutionReadinessValueOnly == false ||
                noRenderExecutionReadiness.didConfirmNoRenderExecution == false ||
                noRenderExecutionReadiness.didConfirmNoGpuSubmission == false ||
                noRenderExecutionReadiness.didConfirmNoCommandBufferCommit == false ||
                noRenderExecutionReadiness.didConfirmNoEncoderCall == false ||
                noRenderExecutionReadiness.didConfirmNoPipelineBinding == false ||
                noRenderExecutionReadiness.didConfirmNoDrawablePresentation == false ||
                noRenderExecutionReadiness.didConfirmNoRendererStateWrite == false ||
                noRenderExecutionReadiness.didConfirmNoNativeResourceToken == false ||
                noRenderExecutionReadiness.didConfirmNoPointerLikeResource == false ||
                noRenderExecutionReadiness.didAvoidBackendPermission == false ||
                noRenderExecutionReadiness.didAvoidThinWrapper == false ||
                noRenderExecutionReadiness.didStayFullRebuildOnly == false ||
                noRenderExecutionReadiness.shouldDeferRendererNoRenderExecutionReadiness ||
                noRenderExecutionReadiness.shouldReportRendererNoRenderExecutionReadinessBlocked
            )
        ) ||
        (noRenderExecutionReadiness.canFutureRendererRenderExecutionBoundaryEvaluate &&
            noRenderExecutionReadiness.isRendererNoRenderExecutionReady == false) ||
        (noRenderExecutionReadiness.shouldDeferRendererNoRenderExecutionReadiness &&
            noRenderExecutionReadiness.shouldReportRendererNoRenderExecutionReadinessBlocked)

    // fail-closed：不能把 no-render-execution readiness 薄包成 backend object intent。
    if (
        noRenderExecutionReadiness.shouldReportRendererNoRenderExecutionReadinessBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererBackendObjectOwnerIntent(
            noRenderExecutionReadiness,
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

    if (noRenderExecutionReady) {
        return CjguiInternalRendererBackendObjectOwnerIntent(
            noRenderExecutionReadiness,
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
        return CjguiInternalRendererBackendObjectOwnerIntent(
            noRenderExecutionReadiness,
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

    return CjguiInternalRendererBackendObjectOwnerIntent(
        noRenderExecutionReadiness,
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

func cjguiInternalBuildRendererBackendLifecycleOwnershipPolicy(
    ownerIntent: CjguiInternalRendererBackendObjectOwnerIntent
): CjguiInternalRendererBackendLifecycleOwnershipPolicy {
    let intentReady =
        ownerIntent.didPrepareRendererBackendObjectOwnerIntent &&
        ownerIntent.didPreserveRendererNoRenderExecutionReadiness &&
        ownerIntent.didDefineFutureBackendObjectOwnerIntent &&
        ownerIntent.didDescribeBackendOwnerIdentityFacts &&
        ownerIntent.didDescribeBackendLifecycleOwnerFacts &&
        ownerIntent.didDescribeBackendAcceptanceFacts &&
        ownerIntent.didKeepBackendObjectOwnerIntentValueOnly &&
        ownerIntent.didAvoidBackendObjectCreation &&
        ownerIntent.didAvoidPlatformObjectCreation &&
        ownerIntent.didAvoidRenderSideEffect &&
        ownerIntent.didAvoidRendererStateMutation &&
        ownerIntent.didAvoidThinWrapper &&
        ownerIntent.shouldDeferRendererBackendObjectOwnerIntent == false &&
        ownerIntent.shouldReportRendererBackendObjectOwnerIntentBlocked == false
    let policyDeferred =
        ownerIntent.didPrepareRendererBackendObjectOwnerIntent == false &&
        ownerIntent.shouldDeferRendererBackendObjectOwnerIntent &&
        ownerIntent.shouldReportRendererBackendObjectOwnerIntentBlocked == false
    let policyInconsistent = (
        ownerIntent.didPrepareRendererBackendObjectOwnerIntent &&
            (
                ownerIntent.didPreserveRendererNoRenderExecutionReadiness == false ||
                ownerIntent.didDefineFutureBackendObjectOwnerIntent == false ||
                ownerIntent.didDescribeBackendOwnerIdentityFacts == false ||
                ownerIntent.didDescribeBackendLifecycleOwnerFacts == false ||
                ownerIntent.didDescribeBackendAcceptanceFacts == false ||
                ownerIntent.didKeepBackendObjectOwnerIntentValueOnly == false ||
                ownerIntent.didAvoidBackendObjectCreation == false ||
                ownerIntent.didAvoidPlatformObjectCreation == false ||
                ownerIntent.didAvoidRenderSideEffect == false ||
                ownerIntent.didAvoidRendererStateMutation == false ||
                ownerIntent.didAvoidThinWrapper == false ||
                ownerIntent.shouldDeferRendererBackendObjectOwnerIntent ||
                ownerIntent.shouldReportRendererBackendObjectOwnerIntentBlocked
            )
        ) ||
        (ownerIntent.didPreserveRendererNoRenderExecutionReadiness &&
            ownerIntent.didPrepareRendererBackendObjectOwnerIntent == false) ||
        (ownerIntent.shouldDeferRendererBackendObjectOwnerIntent &&
            ownerIntent.shouldReportRendererBackendObjectOwnerIntentBlocked)

    // lifecycle policy 只记录 lifecycle facts；这里不创建或管理 backend lifetime。
    if (
        ownerIntent.shouldReportRendererBackendObjectOwnerIntentBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererBackendLifecycleOwnershipPolicy(
            ownerIntent,
            false,
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

    if (intentReady) {
        return CjguiInternalRendererBackendLifecycleOwnershipPolicy(
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
            true,
            true
        )
    }

    if (policyDeferred) {
        return CjguiInternalRendererBackendLifecycleOwnershipPolicy(
            ownerIntent,
            false,
            true,
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
            true,
            true
        )
    }

    return CjguiInternalRendererBackendLifecycleOwnershipPolicy(
        ownerIntent,
        false,
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

func cjguiInternalBuildRendererBackendAcceptanceGate(
    lifecyclePolicy: CjguiInternalRendererBackendLifecycleOwnershipPolicy
): CjguiInternalRendererBackendAcceptanceGate {
    let policyReady =
        lifecyclePolicy.didPrepareRendererBackendLifecycleOwnershipPolicy &&
        lifecyclePolicy.didPreserveRendererBackendObjectOwnerIntent &&
        lifecyclePolicy.didDefineFutureBackendLifecycleOwnershipPolicy &&
        lifecyclePolicy.didDescribeBackendInitPhaseFacts &&
        lifecyclePolicy.didDescribeBackendActivePhaseFacts &&
        lifecyclePolicy.didDescribeBackendTeardownPhaseFacts &&
        lifecyclePolicy.didDescribeBackendFailureRollbackFacts &&
        lifecyclePolicy.didKeepBackendLifecycleOwnershipPolicyValueOnly &&
        lifecyclePolicy.didAvoidBackendObjectCreation &&
        lifecyclePolicy.didAvoidResourceLifetimeManagement &&
        lifecyclePolicy.didAvoidRendererStateMutation &&
        lifecyclePolicy.didAvoidRenderSideEffect &&
        lifecyclePolicy.shouldDeferRendererBackendLifecycleOwnershipPolicy == false &&
        lifecyclePolicy.shouldReportRendererBackendLifecycleOwnershipPolicyBlocked == false
    let gateDeferred =
        lifecyclePolicy.didPrepareRendererBackendLifecycleOwnershipPolicy == false &&
        lifecyclePolicy.shouldDeferRendererBackendLifecycleOwnershipPolicy &&
        lifecyclePolicy.shouldReportRendererBackendLifecycleOwnershipPolicyBlocked == false
    let gateInconsistent = (
        lifecyclePolicy.didPrepareRendererBackendLifecycleOwnershipPolicy &&
            (
                lifecyclePolicy.didPreserveRendererBackendObjectOwnerIntent == false ||
                lifecyclePolicy.didDefineFutureBackendLifecycleOwnershipPolicy == false ||
                lifecyclePolicy.didDescribeBackendInitPhaseFacts == false ||
                lifecyclePolicy.didDescribeBackendActivePhaseFacts == false ||
                lifecyclePolicy.didDescribeBackendTeardownPhaseFacts == false ||
                lifecyclePolicy.didDescribeBackendFailureRollbackFacts == false ||
                lifecyclePolicy.didKeepBackendLifecycleOwnershipPolicyValueOnly == false ||
                lifecyclePolicy.didAvoidBackendObjectCreation == false ||
                lifecyclePolicy.didAvoidResourceLifetimeManagement == false ||
                lifecyclePolicy.didAvoidRendererStateMutation == false ||
                lifecyclePolicy.didAvoidRenderSideEffect == false ||
                lifecyclePolicy.shouldDeferRendererBackendLifecycleOwnershipPolicy ||
                lifecyclePolicy.shouldReportRendererBackendLifecycleOwnershipPolicyBlocked
            )
        ) ||
        (lifecyclePolicy.didPreserveRendererBackendObjectOwnerIntent &&
            lifecyclePolicy.didPrepareRendererBackendLifecycleOwnershipPolicy == false) ||
        (lifecyclePolicy.shouldDeferRendererBackendLifecycleOwnershipPolicy &&
            lifecyclePolicy.shouldReportRendererBackendLifecycleOwnershipPolicyBlocked)

    // acceptance gate 只表达 constraints；这里不授予 backend readiness。
    if (
        lifecyclePolicy.shouldReportRendererBackendLifecycleOwnershipPolicyBlocked ||
        gateInconsistent
    ) {
        return CjguiInternalRendererBackendAcceptanceGate(
            lifecyclePolicy,
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
        return CjguiInternalRendererBackendAcceptanceGate(
            lifecyclePolicy,
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

    if (gateDeferred) {
        return CjguiInternalRendererBackendAcceptanceGate(
            lifecyclePolicy,
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

    return CjguiInternalRendererBackendAcceptanceGate(
        lifecyclePolicy,
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

func cjguiInternalBuildRendererPlatformConfinementGuard(
    acceptanceGate: CjguiInternalRendererBackendAcceptanceGate
): CjguiInternalRendererPlatformConfinementGuard {
    let gateReady = acceptanceGate.didPrepareRendererBackendAcceptanceGate &&
        acceptanceGate.didPreserveRendererBackendLifecycleOwnershipPolicy &&
        acceptanceGate.didDefineFutureBackendAcceptanceGate &&
        acceptanceGate.didDescribeLifecycleCoverageAcceptance &&
        acceptanceGate.didDescribeNoSubmitAcceptance &&
        acceptanceGate.didDescribeNoDrawRollbackAcceptance &&
        acceptanceGate.didKeepBackendAcceptanceGateValueOnly &&
        acceptanceGate.didAvoidBackendReadinessPermission &&
        acceptanceGate.didAvoidPlatformPermission &&
        acceptanceGate.didAvoidRenderPermission &&
        acceptanceGate.didAvoidRendererStateMutation &&
        acceptanceGate.shouldDeferRendererBackendAcceptanceGate == false &&
        acceptanceGate.shouldReportRendererBackendAcceptanceGateBlocked == false
    let guardDeferred =
        acceptanceGate.didPrepareRendererBackendAcceptanceGate == false &&
        acceptanceGate.shouldDeferRendererBackendAcceptanceGate &&
        acceptanceGate.shouldReportRendererBackendAcceptanceGateBlocked == false
    let guardInconsistent = (
        acceptanceGate.didPrepareRendererBackendAcceptanceGate &&
            (
                acceptanceGate.didPreserveRendererBackendLifecycleOwnershipPolicy == false ||
                acceptanceGate.didDefineFutureBackendAcceptanceGate == false ||
                acceptanceGate.didDescribeLifecycleCoverageAcceptance == false ||
                acceptanceGate.didDescribeNoSubmitAcceptance == false ||
                acceptanceGate.didDescribeNoDrawRollbackAcceptance == false ||
                acceptanceGate.didKeepBackendAcceptanceGateValueOnly == false ||
                acceptanceGate.didAvoidBackendReadinessPermission == false ||
                acceptanceGate.didAvoidPlatformPermission == false ||
                acceptanceGate.didAvoidRenderPermission == false ||
                acceptanceGate.didAvoidRendererStateMutation == false ||
                acceptanceGate.shouldDeferRendererBackendAcceptanceGate ||
                acceptanceGate.shouldReportRendererBackendAcceptanceGateBlocked
            )
        ) ||
        (acceptanceGate.didPreserveRendererBackendLifecycleOwnershipPolicy &&
            acceptanceGate.didPrepareRendererBackendAcceptanceGate == false) ||
        (acceptanceGate.shouldDeferRendererBackendAcceptanceGate &&
            acceptanceGate.shouldReportRendererBackendAcceptanceGateBlocked)

    // confinement guard 只表达 future ownership confinement；这里不创建平台对象。
    if (
        acceptanceGate.shouldReportRendererBackendAcceptanceGateBlocked ||
        guardInconsistent
    ) {
        return CjguiInternalRendererPlatformConfinementGuard(
            acceptanceGate,
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

    if (gateReady) {
        return CjguiInternalRendererPlatformConfinementGuard(
            acceptanceGate,
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

    if (guardDeferred) {
        return CjguiInternalRendererPlatformConfinementGuard(
            acceptanceGate,
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

    return CjguiInternalRendererPlatformConfinementGuard(
        acceptanceGate,
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

func cjguiInternalBuildRendererNoBackendObjectReadiness(
    confinementGuard: CjguiInternalRendererPlatformConfinementGuard
): CjguiInternalRendererNoBackendObjectReadiness {
    let guardReady = confinementGuard.didPrepareRendererPlatformConfinementGuard &&
        confinementGuard.didPreserveRendererBackendAcceptanceGate &&
        confinementGuard.didDefineFuturePlatformConfinementGuard &&
        confinementGuard.didConfineDeviceAndLayerToFutureBackendOwner &&
        confinementGuard.didConfineQueueDrawableBufferPassEncoderPipeline &&
        confinementGuard.didKeepCorePacketFreeOfPlatformObjects &&
        confinementGuard.didKeepPlatformConfinementGuardValueOnly &&
        confinementGuard.didAvoidPlatformObjectCreation &&
        confinementGuard.didAvoidResourceHandleSurface &&
        confinementGuard.didAvoidRendererStateMutation &&
        confinementGuard.didAvoidRenderSideEffect &&
        confinementGuard.shouldDeferRendererPlatformConfinementGuard == false &&
        confinementGuard.shouldReportRendererPlatformConfinementGuardBlocked == false
    let readinessDeferred =
        confinementGuard.didPrepareRendererPlatformConfinementGuard == false &&
        confinementGuard.shouldDeferRendererPlatformConfinementGuard &&
        confinementGuard.shouldReportRendererPlatformConfinementGuardBlocked == false
    let readinessInconsistent = (
        confinementGuard.didPrepareRendererPlatformConfinementGuard &&
            (
                confinementGuard.didPreserveRendererBackendAcceptanceGate == false ||
                confinementGuard.didDefineFuturePlatformConfinementGuard == false ||
                confinementGuard.didConfineDeviceAndLayerToFutureBackendOwner == false ||
                confinementGuard.didConfineQueueDrawableBufferPassEncoderPipeline == false ||
                confinementGuard.didKeepCorePacketFreeOfPlatformObjects == false ||
                confinementGuard.didKeepPlatformConfinementGuardValueOnly == false ||
                confinementGuard.didAvoidPlatformObjectCreation == false ||
                confinementGuard.didAvoidResourceHandleSurface == false ||
                confinementGuard.didAvoidRendererStateMutation == false ||
                confinementGuard.didAvoidRenderSideEffect == false ||
                confinementGuard.shouldDeferRendererPlatformConfinementGuard ||
                confinementGuard.shouldReportRendererPlatformConfinementGuardBlocked
            )
        ) ||
        (confinementGuard.didPreserveRendererBackendAcceptanceGate &&
            confinementGuard.didPrepareRendererPlatformConfinementGuard == false) ||
        (confinementGuard.shouldDeferRendererPlatformConfinementGuard &&
            confinementGuard.shouldReportRendererPlatformConfinementGuardBlocked)

    // readiness 只 sealing no-object facts；它不是 backend-readiness final gate。
    if (
        confinementGuard.shouldReportRendererPlatformConfinementGuardBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoBackendObjectReadiness(
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
            true
        )
    }

    if (guardReady) {
        return CjguiInternalRendererNoBackendObjectReadiness(
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
            true
        )
    }

    if (readinessDeferred) {
        return CjguiInternalRendererNoBackendObjectReadiness(
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
            true
        )
    }

    return CjguiInternalRendererNoBackendObjectReadiness(
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererBackendObjectOwnerDraft(
): CjguiInternalRendererNoBackendObjectReadiness {
    let noRenderExecutionReadiness =
        cjguiInternalExecuteDefaultRendererRenderExecutionNoOpDraft()
    let ownerIntent =
        cjguiInternalBuildRendererBackendObjectOwnerIntent(noRenderExecutionReadiness)
    let lifecyclePolicy =
        cjguiInternalBuildRendererBackendLifecycleOwnershipPolicy(ownerIntent)
    let acceptanceGate =
        cjguiInternalBuildRendererBackendAcceptanceGate(lifecyclePolicy)
    let confinementGuard =
        cjguiInternalBuildRendererPlatformConfinementGuard(acceptanceGate)
    return cjguiInternalBuildRendererNoBackendObjectReadiness(confinementGuard)
}
