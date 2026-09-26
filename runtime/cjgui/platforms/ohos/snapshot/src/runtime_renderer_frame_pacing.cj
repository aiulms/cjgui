package cjgui

// Owner: Renderer frame pacing owner value boundary.
// Truth: 只消费 CjguiInternalRendererNoBackendObjectReadiness，表达 future frame
// pacing owner intent、display timing policy、frame request gate、pacing failure
// policy 与 no-frame-scheduler readiness 的内部 value facts。
// Stop-line: 这里不创建 frame scheduler，不创建 frame clock，不绑定 frame callback，
// 不启动 continuous frame driver，不提交 GPU work，不触发 render side effect，
// 不写 renderer state，不持有 resource handle 或 pointer-like resource。
// Same-shape Boundary Brake: 本 owner 新增 display timing / frame request gate /
// pacing failure / no-frame-scheduler vocabulary，不把 no-backend-object readiness
// 包成 receipt / record / publication。

// Frame pacing owner intent 只表达 future owner intent；
// 它不是 frame scheduler implementation，也不是 backend-readiness wrapper。
struct CjguiInternalRendererFramePacingOwnerIntent {
    let noBackendObjectReadiness: CjguiInternalRendererNoBackendObjectReadiness
    let didPrepareRendererFramePacingOwnerIntent: Bool
    let shouldDeferRendererFramePacingOwnerIntent: Bool
    let shouldReportRendererFramePacingOwnerIntentBlocked: Bool
    let didPreserveRendererNoBackendObjectReadiness: Bool
    let didDefineFutureFramePacingOwnerIntent: Bool
    let didDescribeDisplayTimingOwnerFacts: Bool
    let didDescribeFrameRequestGateFacts: Bool
    let didDescribePacingFailureFacts: Bool
    let didKeepFramePacingOwnerIntentValueOnly: Bool
    let didAvoidFrameSchedulerCreation: Bool
    let didAvoidFrameCallbackBinding: Bool
    let didAvoidRenderSideEffect: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidThinWrapper: Bool

    init(
        noBackendObjectReadiness: CjguiInternalRendererNoBackendObjectReadiness,
        didPrepareRendererFramePacingOwnerIntent: Bool,
        shouldDeferRendererFramePacingOwnerIntent: Bool,
        shouldReportRendererFramePacingOwnerIntentBlocked: Bool,
        didPreserveRendererNoBackendObjectReadiness: Bool,
        didDefineFutureFramePacingOwnerIntent: Bool,
        didDescribeDisplayTimingOwnerFacts: Bool,
        didDescribeFrameRequestGateFacts: Bool,
        didDescribePacingFailureFacts: Bool,
        didKeepFramePacingOwnerIntentValueOnly: Bool,
        didAvoidFrameSchedulerCreation: Bool,
        didAvoidFrameCallbackBinding: Bool,
        didAvoidRenderSideEffect: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noBackendObjectReadiness = noBackendObjectReadiness
        this.didPrepareRendererFramePacingOwnerIntent =
            didPrepareRendererFramePacingOwnerIntent
        this.shouldDeferRendererFramePacingOwnerIntent =
            shouldDeferRendererFramePacingOwnerIntent
        this.shouldReportRendererFramePacingOwnerIntentBlocked =
            shouldReportRendererFramePacingOwnerIntentBlocked
        this.didPreserveRendererNoBackendObjectReadiness =
            didPreserveRendererNoBackendObjectReadiness
        this.didDefineFutureFramePacingOwnerIntent =
            didDefineFutureFramePacingOwnerIntent
        this.didDescribeDisplayTimingOwnerFacts =
            didDescribeDisplayTimingOwnerFacts
        this.didDescribeFrameRequestGateFacts =
            didDescribeFrameRequestGateFacts
        this.didDescribePacingFailureFacts = didDescribePacingFailureFacts
        this.didKeepFramePacingOwnerIntentValueOnly =
            didKeepFramePacingOwnerIntentValueOnly
        this.didAvoidFrameSchedulerCreation = didAvoidFrameSchedulerCreation
        this.didAvoidFrameCallbackBinding = didAvoidFrameCallbackBinding
        this.didAvoidRenderSideEffect = didAvoidRenderSideEffect
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

// Display timing policy 只表达 future display timing / refresh relation facts；
// 它不创建 frame clock，也不绑定 platform callback。
struct CjguiInternalRendererDisplayTimingPolicy {
    let ownerIntent: CjguiInternalRendererFramePacingOwnerIntent
    let didPrepareRendererDisplayTimingPolicy: Bool
    let shouldDeferRendererDisplayTimingPolicy: Bool
    let shouldReportRendererDisplayTimingPolicyBlocked: Bool
    let didPreserveRendererFramePacingOwnerIntent: Bool
    let didDefineFutureDisplayTimingPolicy: Bool
    let didDescribeDisplayRefreshRelation: Bool
    let didDescribeDrawableTimingRelation: Bool
    let didDescribeResizeScaleColorRelation: Bool
    let didKeepDisplayTimingPolicyValueOnly: Bool
    let didAvoidFrameClockCreation: Bool
    let didAvoidFrameCallbackBinding: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidRenderSideEffect: Bool

    init(
        ownerIntent: CjguiInternalRendererFramePacingOwnerIntent,
        didPrepareRendererDisplayTimingPolicy: Bool,
        shouldDeferRendererDisplayTimingPolicy: Bool,
        shouldReportRendererDisplayTimingPolicyBlocked: Bool,
        didPreserveRendererFramePacingOwnerIntent: Bool,
        didDefineFutureDisplayTimingPolicy: Bool,
        didDescribeDisplayRefreshRelation: Bool,
        didDescribeDrawableTimingRelation: Bool,
        didDescribeResizeScaleColorRelation: Bool,
        didKeepDisplayTimingPolicyValueOnly: Bool,
        didAvoidFrameClockCreation: Bool,
        didAvoidFrameCallbackBinding: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidRenderSideEffect: Bool
    ) {
        this.ownerIntent = ownerIntent
        this.didPrepareRendererDisplayTimingPolicy =
            didPrepareRendererDisplayTimingPolicy
        this.shouldDeferRendererDisplayTimingPolicy =
            shouldDeferRendererDisplayTimingPolicy
        this.shouldReportRendererDisplayTimingPolicyBlocked =
            shouldReportRendererDisplayTimingPolicyBlocked
        this.didPreserveRendererFramePacingOwnerIntent =
            didPreserveRendererFramePacingOwnerIntent
        this.didDefineFutureDisplayTimingPolicy =
            didDefineFutureDisplayTimingPolicy
        this.didDescribeDisplayRefreshRelation =
            didDescribeDisplayRefreshRelation
        this.didDescribeDrawableTimingRelation =
            didDescribeDrawableTimingRelation
        this.didDescribeResizeScaleColorRelation =
            didDescribeResizeScaleColorRelation
        this.didKeepDisplayTimingPolicyValueOnly =
            didKeepDisplayTimingPolicyValueOnly
        this.didAvoidFrameClockCreation = didAvoidFrameClockCreation
        this.didAvoidFrameCallbackBinding = didAvoidFrameCallbackBinding
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidRenderSideEffect = didAvoidRenderSideEffect
    }
}

// Frame request gate 只表达 future request admission / defer / no-draw facts；
// 它不触发 frame driver，也不请求 platform drawable。
struct CjguiInternalRendererFrameRequestGate {
    let displayTimingPolicy: CjguiInternalRendererDisplayTimingPolicy
    let didPrepareRendererFrameRequestGate: Bool
    let shouldDeferRendererFrameRequestGate: Bool
    let shouldReportRendererFrameRequestGateBlocked: Bool
    let didPreserveRendererDisplayTimingPolicy: Bool
    let didDefineFutureFrameRequestGate: Bool
    let didDescribeFrameRequestAdmissionFacts: Bool
    let didDescribeDeferredFrameFacts: Bool
    let didDescribeNoDrawFallbackFacts: Bool
    let didKeepFrameRequestGateValueOnly: Bool
    let didAvoidContinuousFrameDriverStart: Bool
    let didAvoidCommandBufferCommit: Bool
    let didAvoidGpuSubmission: Bool
    let didAvoidRenderSideEffect: Bool
    let didAvoidRendererStateMutation: Bool

    init(
        displayTimingPolicy: CjguiInternalRendererDisplayTimingPolicy,
        didPrepareRendererFrameRequestGate: Bool,
        shouldDeferRendererFrameRequestGate: Bool,
        shouldReportRendererFrameRequestGateBlocked: Bool,
        didPreserveRendererDisplayTimingPolicy: Bool,
        didDefineFutureFrameRequestGate: Bool,
        didDescribeFrameRequestAdmissionFacts: Bool,
        didDescribeDeferredFrameFacts: Bool,
        didDescribeNoDrawFallbackFacts: Bool,
        didKeepFrameRequestGateValueOnly: Bool,
        didAvoidContinuousFrameDriverStart: Bool,
        didAvoidCommandBufferCommit: Bool,
        didAvoidGpuSubmission: Bool,
        didAvoidRenderSideEffect: Bool,
        didAvoidRendererStateMutation: Bool
    ) {
        this.displayTimingPolicy = displayTimingPolicy
        this.didPrepareRendererFrameRequestGate =
            didPrepareRendererFrameRequestGate
        this.shouldDeferRendererFrameRequestGate =
            shouldDeferRendererFrameRequestGate
        this.shouldReportRendererFrameRequestGateBlocked =
            shouldReportRendererFrameRequestGateBlocked
        this.didPreserveRendererDisplayTimingPolicy =
            didPreserveRendererDisplayTimingPolicy
        this.didDefineFutureFrameRequestGate = didDefineFutureFrameRequestGate
        this.didDescribeFrameRequestAdmissionFacts =
            didDescribeFrameRequestAdmissionFacts
        this.didDescribeDeferredFrameFacts = didDescribeDeferredFrameFacts
        this.didDescribeNoDrawFallbackFacts = didDescribeNoDrawFallbackFacts
        this.didKeepFrameRequestGateValueOnly =
            didKeepFrameRequestGateValueOnly
        this.didAvoidContinuousFrameDriverStart =
            didAvoidContinuousFrameDriverStart
        this.didAvoidCommandBufferCommit = didAvoidCommandBufferCommit
        this.didAvoidGpuSubmission = didAvoidGpuSubmission
        this.didAvoidRenderSideEffect = didAvoidRenderSideEffect
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
    }
}

// Pacing failure policy 只表达 future failure / rollback / no-draw facts；
// 它不注册 callback，不发布 diagnostics，不写 renderer state。
struct CjguiInternalRendererPacingFailurePolicy {
    let frameRequestGate: CjguiInternalRendererFrameRequestGate
    let didPrepareRendererPacingFailurePolicy: Bool
    let shouldDeferRendererPacingFailurePolicy: Bool
    let shouldReportRendererPacingFailurePolicyBlocked: Bool
    let didPreserveRendererFrameRequestGate: Bool
    let didDefineFuturePacingFailurePolicy: Bool
    let didDescribeFrameDropDeferFacts: Bool
    let didDescribeNoDrawableFailureFacts: Bool
    let didDescribeRollbackNoDrawFacts: Bool
    let didKeepPacingFailurePolicyValueOnly: Bool
    let didAvoidCallbackRegistration: Bool
    let didAvoidDiagnosticsPublication: Bool
    let didAvoidRenderSideEffect: Bool
    let didAvoidRendererStateMutation: Bool

    init(
        frameRequestGate: CjguiInternalRendererFrameRequestGate,
        didPrepareRendererPacingFailurePolicy: Bool,
        shouldDeferRendererPacingFailurePolicy: Bool,
        shouldReportRendererPacingFailurePolicyBlocked: Bool,
        didPreserveRendererFrameRequestGate: Bool,
        didDefineFuturePacingFailurePolicy: Bool,
        didDescribeFrameDropDeferFacts: Bool,
        didDescribeNoDrawableFailureFacts: Bool,
        didDescribeRollbackNoDrawFacts: Bool,
        didKeepPacingFailurePolicyValueOnly: Bool,
        didAvoidCallbackRegistration: Bool,
        didAvoidDiagnosticsPublication: Bool,
        didAvoidRenderSideEffect: Bool,
        didAvoidRendererStateMutation: Bool
    ) {
        this.frameRequestGate = frameRequestGate
        this.didPrepareRendererPacingFailurePolicy =
            didPrepareRendererPacingFailurePolicy
        this.shouldDeferRendererPacingFailurePolicy =
            shouldDeferRendererPacingFailurePolicy
        this.shouldReportRendererPacingFailurePolicyBlocked =
            shouldReportRendererPacingFailurePolicyBlocked
        this.didPreserveRendererFrameRequestGate =
            didPreserveRendererFrameRequestGate
        this.didDefineFuturePacingFailurePolicy =
            didDefineFuturePacingFailurePolicy
        this.didDescribeFrameDropDeferFacts =
            didDescribeFrameDropDeferFacts
        this.didDescribeNoDrawableFailureFacts =
            didDescribeNoDrawableFailureFacts
        this.didDescribeRollbackNoDrawFacts =
            didDescribeRollbackNoDrawFacts
        this.didKeepPacingFailurePolicyValueOnly =
            didKeepPacingFailurePolicyValueOnly
        this.didAvoidCallbackRegistration = didAvoidCallbackRegistration
        this.didAvoidDiagnosticsPublication = didAvoidDiagnosticsPublication
        this.didAvoidRenderSideEffect = didAvoidRenderSideEffect
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
    }
}

// No-frame-scheduler readiness 是本 owner 的 endpoint；readiness 只表示 future
// frame pacing boundary 可以继续评估，不代表 frame driver or render permission。
struct CjguiInternalRendererNoFrameSchedulerReadiness {
    let pacingFailurePolicy: CjguiInternalRendererPacingFailurePolicy
    let isRendererNoFrameSchedulerReady: Bool
    let canFutureRendererFramePacingBoundaryEvaluate: Bool
    let shouldDeferRendererNoFrameSchedulerReadiness: Bool
    let shouldReportRendererNoFrameSchedulerReadinessBlocked: Bool
    let didSealRendererNoFrameSchedulerReadiness: Bool
    let didPreserveRendererPacingFailurePolicy: Bool
    let didKeepNoFrameSchedulerReadinessValueOnly: Bool
    let didConfirmNoFrameSchedulerCreated: Bool
    let didConfirmNoFrameClockCreated: Bool
    let didConfirmNoFrameCallbackBound: Bool
    let didConfirmNoContinuousFrameDriverStarted: Bool
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
        pacingFailurePolicy: CjguiInternalRendererPacingFailurePolicy,
        isRendererNoFrameSchedulerReady: Bool,
        canFutureRendererFramePacingBoundaryEvaluate: Bool,
        shouldDeferRendererNoFrameSchedulerReadiness: Bool,
        shouldReportRendererNoFrameSchedulerReadinessBlocked: Bool,
        didSealRendererNoFrameSchedulerReadiness: Bool,
        didPreserveRendererPacingFailurePolicy: Bool,
        didKeepNoFrameSchedulerReadinessValueOnly: Bool,
        didConfirmNoFrameSchedulerCreated: Bool,
        didConfirmNoFrameClockCreated: Bool,
        didConfirmNoFrameCallbackBound: Bool,
        didConfirmNoContinuousFrameDriverStarted: Bool,
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
        this.pacingFailurePolicy = pacingFailurePolicy
        this.isRendererNoFrameSchedulerReady = isRendererNoFrameSchedulerReady
        this.canFutureRendererFramePacingBoundaryEvaluate =
            canFutureRendererFramePacingBoundaryEvaluate
        this.shouldDeferRendererNoFrameSchedulerReadiness =
            shouldDeferRendererNoFrameSchedulerReadiness
        this.shouldReportRendererNoFrameSchedulerReadinessBlocked =
            shouldReportRendererNoFrameSchedulerReadinessBlocked
        this.didSealRendererNoFrameSchedulerReadiness =
            didSealRendererNoFrameSchedulerReadiness
        this.didPreserveRendererPacingFailurePolicy =
            didPreserveRendererPacingFailurePolicy
        this.didKeepNoFrameSchedulerReadinessValueOnly =
            didKeepNoFrameSchedulerReadinessValueOnly
        this.didConfirmNoFrameSchedulerCreated =
            didConfirmNoFrameSchedulerCreated
        this.didConfirmNoFrameClockCreated = didConfirmNoFrameClockCreated
        this.didConfirmNoFrameCallbackBound = didConfirmNoFrameCallbackBound
        this.didConfirmNoContinuousFrameDriverStarted =
            didConfirmNoContinuousFrameDriverStarted
        this.didConfirmNoBackendObjectCreated = didConfirmNoBackendObjectCreated
        this.didConfirmNoPlatformObjectCreated =
            didConfirmNoPlatformObjectCreated
        this.didConfirmNoCommandBufferCommit = didConfirmNoCommandBufferCommit
        this.didConfirmNoGpuSubmission = didConfirmNoGpuSubmission
        this.didConfirmNoRenderSideEffect = didConfirmNoRenderSideEffect
        this.didConfirmNoRendererStateMutation =
            didConfirmNoRendererStateMutation
        this.didConfirmNoResourceHandleSurface =
            didConfirmNoResourceHandleSurface
        this.didConfirmNoPointerLikeResource =
            didConfirmNoPointerLikeResource
        this.didAvoidBackendReadinessPermission =
            didAvoidBackendReadinessPermission
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererFramePacingOwnerIntent(
    noBackendObjectReadiness: CjguiInternalRendererNoBackendObjectReadiness
): CjguiInternalRendererFramePacingOwnerIntent {
    let noBackendObjectReady =
        noBackendObjectReadiness.isRendererNoBackendObjectReady &&
        noBackendObjectReadiness.canFutureRendererBackendObjectBoundaryEvaluate &&
        noBackendObjectReadiness.didSealRendererNoBackendObjectReadiness &&
        noBackendObjectReadiness.didPreserveRendererPlatformConfinementGuard &&
        noBackendObjectReadiness.didKeepNoBackendObjectReadinessValueOnly &&
        noBackendObjectReadiness.didConfirmNoBackendObjectCreated &&
        noBackendObjectReadiness.didConfirmNoPlatformObjectCreated &&
        noBackendObjectReadiness.didConfirmNoCommandBufferCommit &&
        noBackendObjectReadiness.didConfirmNoGpuSubmission &&
        noBackendObjectReadiness.didConfirmNoRenderSideEffect &&
        noBackendObjectReadiness.didConfirmNoRendererStateMutation &&
        noBackendObjectReadiness.didConfirmNoResourceHandleSurface &&
        noBackendObjectReadiness.didConfirmNoPointerLikeResource &&
        noBackendObjectReadiness.didAvoidBackendReadinessPermission &&
        noBackendObjectReadiness.didAvoidThinWrapper &&
        noBackendObjectReadiness.didStayFullRebuildOnly &&
        noBackendObjectReadiness.shouldDeferRendererNoBackendObjectReadiness == false &&
        noBackendObjectReadiness.shouldReportRendererNoBackendObjectReadinessBlocked == false
    let intentDeferred =
        noBackendObjectReadiness.isRendererNoBackendObjectReady == false &&
        noBackendObjectReadiness.canFutureRendererBackendObjectBoundaryEvaluate == false &&
        noBackendObjectReadiness.shouldDeferRendererNoBackendObjectReadiness &&
        noBackendObjectReadiness.shouldReportRendererNoBackendObjectReadinessBlocked == false
    let intentInconsistent = (
        noBackendObjectReadiness.isRendererNoBackendObjectReady &&
            (
                noBackendObjectReadiness.canFutureRendererBackendObjectBoundaryEvaluate == false ||
                noBackendObjectReadiness.didSealRendererNoBackendObjectReadiness == false ||
                noBackendObjectReadiness.didPreserveRendererPlatformConfinementGuard == false ||
                noBackendObjectReadiness.didKeepNoBackendObjectReadinessValueOnly == false ||
                noBackendObjectReadiness.didConfirmNoBackendObjectCreated == false ||
                noBackendObjectReadiness.didConfirmNoPlatformObjectCreated == false ||
                noBackendObjectReadiness.didConfirmNoCommandBufferCommit == false ||
                noBackendObjectReadiness.didConfirmNoGpuSubmission == false ||
                noBackendObjectReadiness.didConfirmNoRenderSideEffect == false ||
                noBackendObjectReadiness.didConfirmNoRendererStateMutation == false ||
                noBackendObjectReadiness.didConfirmNoResourceHandleSurface == false ||
                noBackendObjectReadiness.didConfirmNoPointerLikeResource == false ||
                noBackendObjectReadiness.didAvoidBackendReadinessPermission == false ||
                noBackendObjectReadiness.didAvoidThinWrapper == false ||
                noBackendObjectReadiness.didStayFullRebuildOnly == false ||
                noBackendObjectReadiness.shouldDeferRendererNoBackendObjectReadiness ||
                noBackendObjectReadiness.shouldReportRendererNoBackendObjectReadinessBlocked
            )
        ) ||
        (noBackendObjectReadiness.canFutureRendererBackendObjectBoundaryEvaluate &&
            noBackendObjectReadiness.isRendererNoBackendObjectReady == false) ||
        (noBackendObjectReadiness.shouldDeferRendererNoBackendObjectReadiness &&
            noBackendObjectReadiness.shouldReportRendererNoBackendObjectReadinessBlocked)

    // fail-closed：不能把 no-backend-object readiness 薄包成 pacing intent。
    if (
        noBackendObjectReadiness.shouldReportRendererNoBackendObjectReadinessBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererFramePacingOwnerIntent(
            noBackendObjectReadiness,
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

    if (noBackendObjectReady) {
        return CjguiInternalRendererFramePacingOwnerIntent(
            noBackendObjectReadiness,
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
        return CjguiInternalRendererFramePacingOwnerIntent(
            noBackendObjectReadiness,
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

    return CjguiInternalRendererFramePacingOwnerIntent(
        noBackendObjectReadiness,
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

func cjguiInternalBuildRendererDisplayTimingPolicy(
    ownerIntent: CjguiInternalRendererFramePacingOwnerIntent
): CjguiInternalRendererDisplayTimingPolicy {
    let intentReady =
        ownerIntent.didPrepareRendererFramePacingOwnerIntent &&
        ownerIntent.didPreserveRendererNoBackendObjectReadiness &&
        ownerIntent.didDefineFutureFramePacingOwnerIntent &&
        ownerIntent.didDescribeDisplayTimingOwnerFacts &&
        ownerIntent.didDescribeFrameRequestGateFacts &&
        ownerIntent.didDescribePacingFailureFacts &&
        ownerIntent.didKeepFramePacingOwnerIntentValueOnly &&
        ownerIntent.didAvoidFrameSchedulerCreation &&
        ownerIntent.didAvoidFrameCallbackBinding &&
        ownerIntent.didAvoidRenderSideEffect &&
        ownerIntent.didAvoidRendererStateMutation &&
        ownerIntent.didAvoidThinWrapper &&
        ownerIntent.shouldDeferRendererFramePacingOwnerIntent == false &&
        ownerIntent.shouldReportRendererFramePacingOwnerIntentBlocked == false
    let policyDeferred =
        ownerIntent.didPrepareRendererFramePacingOwnerIntent == false &&
        ownerIntent.shouldDeferRendererFramePacingOwnerIntent &&
        ownerIntent.shouldReportRendererFramePacingOwnerIntentBlocked == false
    let policyInconsistent = (
        ownerIntent.didPrepareRendererFramePacingOwnerIntent &&
            (
                ownerIntent.didPreserveRendererNoBackendObjectReadiness == false ||
                ownerIntent.didDefineFutureFramePacingOwnerIntent == false ||
                ownerIntent.didDescribeDisplayTimingOwnerFacts == false ||
                ownerIntent.didDescribeFrameRequestGateFacts == false ||
                ownerIntent.didDescribePacingFailureFacts == false ||
                ownerIntent.didKeepFramePacingOwnerIntentValueOnly == false ||
                ownerIntent.didAvoidFrameSchedulerCreation == false ||
                ownerIntent.didAvoidFrameCallbackBinding == false ||
                ownerIntent.didAvoidRenderSideEffect == false ||
                ownerIntent.didAvoidRendererStateMutation == false ||
                ownerIntent.didAvoidThinWrapper == false ||
                ownerIntent.shouldDeferRendererFramePacingOwnerIntent ||
                ownerIntent.shouldReportRendererFramePacingOwnerIntentBlocked
            )
        ) ||
        (ownerIntent.didPreserveRendererNoBackendObjectReadiness &&
            ownerIntent.didPrepareRendererFramePacingOwnerIntent == false) ||
        (ownerIntent.shouldDeferRendererFramePacingOwnerIntent &&
            ownerIntent.shouldReportRendererFramePacingOwnerIntentBlocked)

    // display timing policy 只记录 timing vocabulary；这里不创建 frame clock。
    if (
        ownerIntent.shouldReportRendererFramePacingOwnerIntentBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererDisplayTimingPolicy(
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
        return CjguiInternalRendererDisplayTimingPolicy(
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
        return CjguiInternalRendererDisplayTimingPolicy(
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

    return CjguiInternalRendererDisplayTimingPolicy(
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

func cjguiInternalBuildRendererFrameRequestGate(
    displayTimingPolicy: CjguiInternalRendererDisplayTimingPolicy
): CjguiInternalRendererFrameRequestGate {
    let policyReady =
        displayTimingPolicy.didPrepareRendererDisplayTimingPolicy &&
        displayTimingPolicy.didPreserveRendererFramePacingOwnerIntent &&
        displayTimingPolicy.didDefineFutureDisplayTimingPolicy &&
        displayTimingPolicy.didDescribeDisplayRefreshRelation &&
        displayTimingPolicy.didDescribeDrawableTimingRelation &&
        displayTimingPolicy.didDescribeResizeScaleColorRelation &&
        displayTimingPolicy.didKeepDisplayTimingPolicyValueOnly &&
        displayTimingPolicy.didAvoidFrameClockCreation &&
        displayTimingPolicy.didAvoidFrameCallbackBinding &&
        displayTimingPolicy.didAvoidRendererStateMutation &&
        displayTimingPolicy.didAvoidRenderSideEffect &&
        displayTimingPolicy.shouldDeferRendererDisplayTimingPolicy == false &&
        displayTimingPolicy.shouldReportRendererDisplayTimingPolicyBlocked == false
    let gateDeferred =
        displayTimingPolicy.didPrepareRendererDisplayTimingPolicy == false &&
        displayTimingPolicy.shouldDeferRendererDisplayTimingPolicy &&
        displayTimingPolicy.shouldReportRendererDisplayTimingPolicyBlocked == false
    let gateInconsistent = (
        displayTimingPolicy.didPrepareRendererDisplayTimingPolicy &&
            (
                displayTimingPolicy.didPreserveRendererFramePacingOwnerIntent == false ||
                displayTimingPolicy.didDefineFutureDisplayTimingPolicy == false ||
                displayTimingPolicy.didDescribeDisplayRefreshRelation == false ||
                displayTimingPolicy.didDescribeDrawableTimingRelation == false ||
                displayTimingPolicy.didDescribeResizeScaleColorRelation == false ||
                displayTimingPolicy.didKeepDisplayTimingPolicyValueOnly == false ||
                displayTimingPolicy.didAvoidFrameClockCreation == false ||
                displayTimingPolicy.didAvoidFrameCallbackBinding == false ||
                displayTimingPolicy.didAvoidRendererStateMutation == false ||
                displayTimingPolicy.didAvoidRenderSideEffect == false ||
                displayTimingPolicy.shouldDeferRendererDisplayTimingPolicy ||
                displayTimingPolicy.shouldReportRendererDisplayTimingPolicyBlocked
            )
        ) ||
        (displayTimingPolicy.didPreserveRendererFramePacingOwnerIntent &&
            displayTimingPolicy.didPrepareRendererDisplayTimingPolicy == false) ||
        (displayTimingPolicy.shouldDeferRendererDisplayTimingPolicy &&
            displayTimingPolicy.shouldReportRendererDisplayTimingPolicyBlocked)

    // request gate 只表达 admission / defer / no-draw facts；这里不启动 frame driver。
    if (
        displayTimingPolicy.shouldReportRendererDisplayTimingPolicyBlocked ||
        gateInconsistent
    ) {
        return CjguiInternalRendererFrameRequestGate(
            displayTimingPolicy,
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

    if (policyReady) {
        return CjguiInternalRendererFrameRequestGate(
            displayTimingPolicy,
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

    if (gateDeferred) {
        return CjguiInternalRendererFrameRequestGate(
            displayTimingPolicy,
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

    return CjguiInternalRendererFrameRequestGate(
        displayTimingPolicy,
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

func cjguiInternalBuildRendererPacingFailurePolicy(
    frameRequestGate: CjguiInternalRendererFrameRequestGate
): CjguiInternalRendererPacingFailurePolicy {
    let gateReady =
        frameRequestGate.didPrepareRendererFrameRequestGate &&
        frameRequestGate.didPreserveRendererDisplayTimingPolicy &&
        frameRequestGate.didDefineFutureFrameRequestGate &&
        frameRequestGate.didDescribeFrameRequestAdmissionFacts &&
        frameRequestGate.didDescribeDeferredFrameFacts &&
        frameRequestGate.didDescribeNoDrawFallbackFacts &&
        frameRequestGate.didKeepFrameRequestGateValueOnly &&
        frameRequestGate.didAvoidContinuousFrameDriverStart &&
        frameRequestGate.didAvoidCommandBufferCommit &&
        frameRequestGate.didAvoidGpuSubmission &&
        frameRequestGate.didAvoidRenderSideEffect &&
        frameRequestGate.didAvoidRendererStateMutation &&
        frameRequestGate.shouldDeferRendererFrameRequestGate == false &&
        frameRequestGate.shouldReportRendererFrameRequestGateBlocked == false
    let policyDeferred =
        frameRequestGate.didPrepareRendererFrameRequestGate == false &&
        frameRequestGate.shouldDeferRendererFrameRequestGate &&
        frameRequestGate.shouldReportRendererFrameRequestGateBlocked == false
    let policyInconsistent = (
        frameRequestGate.didPrepareRendererFrameRequestGate &&
            (
                frameRequestGate.didPreserveRendererDisplayTimingPolicy == false ||
                frameRequestGate.didDefineFutureFrameRequestGate == false ||
                frameRequestGate.didDescribeFrameRequestAdmissionFacts == false ||
                frameRequestGate.didDescribeDeferredFrameFacts == false ||
                frameRequestGate.didDescribeNoDrawFallbackFacts == false ||
                frameRequestGate.didKeepFrameRequestGateValueOnly == false ||
                frameRequestGate.didAvoidContinuousFrameDriverStart == false ||
                frameRequestGate.didAvoidCommandBufferCommit == false ||
                frameRequestGate.didAvoidGpuSubmission == false ||
                frameRequestGate.didAvoidRenderSideEffect == false ||
                frameRequestGate.didAvoidRendererStateMutation == false ||
                frameRequestGate.shouldDeferRendererFrameRequestGate ||
                frameRequestGate.shouldReportRendererFrameRequestGateBlocked
            )
        ) ||
        (frameRequestGate.didPreserveRendererDisplayTimingPolicy &&
            frameRequestGate.didPrepareRendererFrameRequestGate == false) ||
        (frameRequestGate.shouldDeferRendererFrameRequestGate &&
            frameRequestGate.shouldReportRendererFrameRequestGateBlocked)

    // failure policy 只表达 failure / rollback / no-draw facts；这里不注册 callback。
    if (
        frameRequestGate.shouldReportRendererFrameRequestGateBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererPacingFailurePolicy(
            frameRequestGate,
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
        return CjguiInternalRendererPacingFailurePolicy(
            frameRequestGate,
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
        return CjguiInternalRendererPacingFailurePolicy(
            frameRequestGate,
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

    return CjguiInternalRendererPacingFailurePolicy(
        frameRequestGate,
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

func cjguiInternalBuildRendererNoFrameSchedulerReadiness(
    pacingFailurePolicy: CjguiInternalRendererPacingFailurePolicy
): CjguiInternalRendererNoFrameSchedulerReadiness {
    let policyReady =
        pacingFailurePolicy.didPrepareRendererPacingFailurePolicy &&
        pacingFailurePolicy.didPreserveRendererFrameRequestGate &&
        pacingFailurePolicy.didDefineFuturePacingFailurePolicy &&
        pacingFailurePolicy.didDescribeFrameDropDeferFacts &&
        pacingFailurePolicy.didDescribeNoDrawableFailureFacts &&
        pacingFailurePolicy.didDescribeRollbackNoDrawFacts &&
        pacingFailurePolicy.didKeepPacingFailurePolicyValueOnly &&
        pacingFailurePolicy.didAvoidCallbackRegistration &&
        pacingFailurePolicy.didAvoidDiagnosticsPublication &&
        pacingFailurePolicy.didAvoidRenderSideEffect &&
        pacingFailurePolicy.didAvoidRendererStateMutation &&
        pacingFailurePolicy.shouldDeferRendererPacingFailurePolicy == false &&
        pacingFailurePolicy.shouldReportRendererPacingFailurePolicyBlocked == false
    let readinessDeferred =
        pacingFailurePolicy.didPrepareRendererPacingFailurePolicy == false &&
        pacingFailurePolicy.shouldDeferRendererPacingFailurePolicy &&
        pacingFailurePolicy.shouldReportRendererPacingFailurePolicyBlocked == false
    let readinessInconsistent = (
        pacingFailurePolicy.didPrepareRendererPacingFailurePolicy &&
            (
                pacingFailurePolicy.didPreserveRendererFrameRequestGate == false ||
                pacingFailurePolicy.didDefineFuturePacingFailurePolicy == false ||
                pacingFailurePolicy.didDescribeFrameDropDeferFacts == false ||
                pacingFailurePolicy.didDescribeNoDrawableFailureFacts == false ||
                pacingFailurePolicy.didDescribeRollbackNoDrawFacts == false ||
                pacingFailurePolicy.didKeepPacingFailurePolicyValueOnly == false ||
                pacingFailurePolicy.didAvoidCallbackRegistration == false ||
                pacingFailurePolicy.didAvoidDiagnosticsPublication == false ||
                pacingFailurePolicy.didAvoidRenderSideEffect == false ||
                pacingFailurePolicy.didAvoidRendererStateMutation == false ||
                pacingFailurePolicy.shouldDeferRendererPacingFailurePolicy ||
                pacingFailurePolicy.shouldReportRendererPacingFailurePolicyBlocked
            )
        ) ||
        (pacingFailurePolicy.didPreserveRendererFrameRequestGate &&
            pacingFailurePolicy.didPrepareRendererPacingFailurePolicy == false) ||
        (pacingFailurePolicy.shouldDeferRendererPacingFailurePolicy &&
            pacingFailurePolicy.shouldReportRendererPacingFailurePolicyBlocked)

    // readiness 只 sealing no-frame-scheduler facts；它不是 scheduler permission。
    if (
        pacingFailurePolicy.shouldReportRendererPacingFailurePolicyBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoFrameSchedulerReadiness(
            pacingFailurePolicy,
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
            true
        )
    }

    if (policyReady) {
        return CjguiInternalRendererNoFrameSchedulerReadiness(
            pacingFailurePolicy,
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
            true
        )
    }

    if (readinessDeferred) {
        return CjguiInternalRendererNoFrameSchedulerReadiness(
            pacingFailurePolicy,
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
            true
        )
    }

    return CjguiInternalRendererNoFrameSchedulerReadiness(
        pacingFailurePolicy,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererFramePacingOwnerDraft(
): CjguiInternalRendererNoFrameSchedulerReadiness {
    let noBackendObjectReadiness =
        cjguiInternalExecuteDefaultRendererBackendObjectOwnerDraft()
    let ownerIntent =
        cjguiInternalBuildRendererFramePacingOwnerIntent(noBackendObjectReadiness)
    let displayTimingPolicy =
        cjguiInternalBuildRendererDisplayTimingPolicy(ownerIntent)
    let frameRequestGate =
        cjguiInternalBuildRendererFrameRequestGate(displayTimingPolicy)
    let pacingFailurePolicy =
        cjguiInternalBuildRendererPacingFailurePolicy(frameRequestGate)
    return cjguiInternalBuildRendererNoFrameSchedulerReadiness(pacingFailurePolicy)
}
