package cjgui

// Owner: Renderer command buffer lifecycle value boundary.
// Truth: 只消费 CjguiInternalRendererNoDrawableReadiness，表达 future command buffer
// lifecycle intent、creation policy、commit timing guard、single-use policy 与
// no-command-buffer readiness 的内部 value facts。
// Stop-line: 这里不创建或持有 MTLCommandBuffer / MTLCommandQueue / drawable / pass /
// encoder / native resource token / pointer-like resource，不接平台实现，不提交绘制，
// 不写 renderer state。
// Same-shape Boundary Brake: 本 owner 新增 creation / commit timing / single-use /
// failure rollback vocabulary，不把 no-drawable readiness 包成 receipt / record /
// publication。

// Command buffer lifecycle intent 只表达 future lifecycle intent；
// 它不是 command buffer creation，也不是 backend readiness wrapper。
struct CjguiInternalRendererCommandBufferLifecycleIntent {
    let noDrawableReadiness: CjguiInternalRendererNoDrawableReadiness
    let didPrepareRendererCommandBufferLifecycleIntent: Bool
    let shouldDeferRendererCommandBufferLifecycleIntent: Bool
    let shouldReportRendererCommandBufferLifecycleIntentBlocked: Bool
    let didPreserveRendererNoDrawableReadiness: Bool
    let didDefineFutureCommandBufferLifecycleIntent: Bool
    let didDescribeCommandBufferCreationPhase: Bool
    let didDescribeQueueDrawableRelationship: Bool
    let didKeepCommandBufferLifecycleIntentValueOnly: Bool
    let didAvoidCommandBufferCreation: Bool
    let didAvoidBackendPermission: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool
    let didAvoidThinWrapper: Bool

    init(
        noDrawableReadiness: CjguiInternalRendererNoDrawableReadiness,
        didPrepareRendererCommandBufferLifecycleIntent: Bool,
        shouldDeferRendererCommandBufferLifecycleIntent: Bool,
        shouldReportRendererCommandBufferLifecycleIntentBlocked: Bool,
        didPreserveRendererNoDrawableReadiness: Bool,
        didDefineFutureCommandBufferLifecycleIntent: Bool,
        didDescribeCommandBufferCreationPhase: Bool,
        didDescribeQueueDrawableRelationship: Bool,
        didKeepCommandBufferLifecycleIntentValueOnly: Bool,
        didAvoidCommandBufferCreation: Bool,
        didAvoidBackendPermission: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noDrawableReadiness = noDrawableReadiness
        this.didPrepareRendererCommandBufferLifecycleIntent =
            didPrepareRendererCommandBufferLifecycleIntent
        this.shouldDeferRendererCommandBufferLifecycleIntent =
            shouldDeferRendererCommandBufferLifecycleIntent
        this.shouldReportRendererCommandBufferLifecycleIntentBlocked =
            shouldReportRendererCommandBufferLifecycleIntentBlocked
        this.didPreserveRendererNoDrawableReadiness =
            didPreserveRendererNoDrawableReadiness
        this.didDefineFutureCommandBufferLifecycleIntent =
            didDefineFutureCommandBufferLifecycleIntent
        this.didDescribeCommandBufferCreationPhase =
            didDescribeCommandBufferCreationPhase
        this.didDescribeQueueDrawableRelationship = didDescribeQueueDrawableRelationship
        this.didKeepCommandBufferLifecycleIntentValueOnly =
            didKeepCommandBufferLifecycleIntentValueOnly
        this.didAvoidCommandBufferCreation = didAvoidCommandBufferCreation
        this.didAvoidBackendPermission = didAvoidBackendPermission
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

// Creation policy 只表达 future creation preconditions；
// 它不创建 command buffer，不创建平台对象，也不进入 render pass / encoder lifecycle。
struct CjguiInternalRendererCommandBufferCreationPolicy {
    let lifecycleIntent: CjguiInternalRendererCommandBufferLifecycleIntent
    let didPrepareRendererCommandBufferCreationPolicy: Bool
    let shouldDeferRendererCommandBufferCreationPolicy: Bool
    let shouldReportRendererCommandBufferCreationPolicyBlocked: Bool
    let didPreserveRendererCommandBufferLifecycleIntent: Bool
    let didDefineFutureCommandBufferCreationPreconditions: Bool
    let didDescribeCommandBufferCreationPhaseBoundary: Bool
    let didDescribeEncodingPhaseBoundary: Bool
    let didKeepCommandBufferCreationPolicyValueOnly: Bool
    let didAvoidCommandBufferCreation: Bool
    let didAvoidPlatformObjectCreation: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool

    init(
        lifecycleIntent: CjguiInternalRendererCommandBufferLifecycleIntent,
        didPrepareRendererCommandBufferCreationPolicy: Bool,
        shouldDeferRendererCommandBufferCreationPolicy: Bool,
        shouldReportRendererCommandBufferCreationPolicyBlocked: Bool,
        didPreserveRendererCommandBufferLifecycleIntent: Bool,
        didDefineFutureCommandBufferCreationPreconditions: Bool,
        didDescribeCommandBufferCreationPhaseBoundary: Bool,
        didDescribeEncodingPhaseBoundary: Bool,
        didKeepCommandBufferCreationPolicyValueOnly: Bool,
        didAvoidCommandBufferCreation: Bool,
        didAvoidPlatformObjectCreation: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.lifecycleIntent = lifecycleIntent
        this.didPrepareRendererCommandBufferCreationPolicy =
            didPrepareRendererCommandBufferCreationPolicy
        this.shouldDeferRendererCommandBufferCreationPolicy =
            shouldDeferRendererCommandBufferCreationPolicy
        this.shouldReportRendererCommandBufferCreationPolicyBlocked =
            shouldReportRendererCommandBufferCreationPolicyBlocked
        this.didPreserveRendererCommandBufferLifecycleIntent =
            didPreserveRendererCommandBufferLifecycleIntent
        this.didDefineFutureCommandBufferCreationPreconditions =
            didDefineFutureCommandBufferCreationPreconditions
        this.didDescribeCommandBufferCreationPhaseBoundary =
            didDescribeCommandBufferCreationPhaseBoundary
        this.didDescribeEncodingPhaseBoundary = didDescribeEncodingPhaseBoundary
        this.didKeepCommandBufferCreationPolicyValueOnly =
            didKeepCommandBufferCreationPolicyValueOnly
        this.didAvoidCommandBufferCreation = didAvoidCommandBufferCreation
        this.didAvoidPlatformObjectCreation = didAvoidPlatformObjectCreation
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// Commit timing guard 只表达 future commit timing constraints；
// 它不 commit，不提交 command buffer，也不注册 completion callback。
struct CjguiInternalRendererCommandBufferCommitTimingGuard {
    let creationPolicy: CjguiInternalRendererCommandBufferCreationPolicy
    let didPrepareRendererCommandBufferCommitTimingGuard: Bool
    let shouldDeferRendererCommandBufferCommitTimingGuard: Bool
    let shouldReportRendererCommandBufferCommitTimingGuardBlocked: Bool
    let didPreserveRendererCommandBufferCreationPolicy: Bool
    let didDefineFutureCommitTimingConstraints: Bool
    let didDescribeAfterEncodingBeforeCommitBoundary: Bool
    let didDescribeFramePacingCommitRelation: Bool
    let didKeepCommandBufferCommitTimingGuardValueOnly: Bool
    let didAvoidCommitSubmission: Bool
    let didAvoidCompletionCallback: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool

    init(
        creationPolicy: CjguiInternalRendererCommandBufferCreationPolicy,
        didPrepareRendererCommandBufferCommitTimingGuard: Bool,
        shouldDeferRendererCommandBufferCommitTimingGuard: Bool,
        shouldReportRendererCommandBufferCommitTimingGuardBlocked: Bool,
        didPreserveRendererCommandBufferCreationPolicy: Bool,
        didDefineFutureCommitTimingConstraints: Bool,
        didDescribeAfterEncodingBeforeCommitBoundary: Bool,
        didDescribeFramePacingCommitRelation: Bool,
        didKeepCommandBufferCommitTimingGuardValueOnly: Bool,
        didAvoidCommitSubmission: Bool,
        didAvoidCompletionCallback: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.creationPolicy = creationPolicy
        this.didPrepareRendererCommandBufferCommitTimingGuard =
            didPrepareRendererCommandBufferCommitTimingGuard
        this.shouldDeferRendererCommandBufferCommitTimingGuard =
            shouldDeferRendererCommandBufferCommitTimingGuard
        this.shouldReportRendererCommandBufferCommitTimingGuardBlocked =
            shouldReportRendererCommandBufferCommitTimingGuardBlocked
        this.didPreserveRendererCommandBufferCreationPolicy =
            didPreserveRendererCommandBufferCreationPolicy
        this.didDefineFutureCommitTimingConstraints =
            didDefineFutureCommitTimingConstraints
        this.didDescribeAfterEncodingBeforeCommitBoundary =
            didDescribeAfterEncodingBeforeCommitBoundary
        this.didDescribeFramePacingCommitRelation = didDescribeFramePacingCommitRelation
        this.didKeepCommandBufferCommitTimingGuardValueOnly =
            didKeepCommandBufferCommitTimingGuardValueOnly
        this.didAvoidCommitSubmission = didAvoidCommitSubmission
        this.didAvoidCompletionCallback = didAvoidCompletionCallback
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// Single-use policy 只表达 future single-use、post-commit invalidation、
// completion-failure 与 rollback / no-draw facts；它不管理真实 buffer lifetime。
struct CjguiInternalRendererCommandBufferSingleUsePolicy {
    let commitTimingGuard: CjguiInternalRendererCommandBufferCommitTimingGuard
    let didPrepareRendererCommandBufferSingleUsePolicy: Bool
    let shouldDeferRendererCommandBufferSingleUsePolicy: Bool
    let shouldReportRendererCommandBufferSingleUsePolicyBlocked: Bool
    let didPreserveRendererCommandBufferCommitTimingGuard: Bool
    let didDefineFutureCommandBufferSingleUsePolicy: Bool
    let didDescribePostCommitInvalidationFact: Bool
    let didDescribeCompletionFailureFacts: Bool
    let didDescribeRollbackNoDrawFallback: Bool
    let didKeepCommandBufferSingleUsePolicyValueOnly: Bool
    let didAvoidRealBufferLifetimeManagement: Bool
    let didAvoidPassOrEncoderLifecycle: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool

    init(
        commitTimingGuard: CjguiInternalRendererCommandBufferCommitTimingGuard,
        didPrepareRendererCommandBufferSingleUsePolicy: Bool,
        shouldDeferRendererCommandBufferSingleUsePolicy: Bool,
        shouldReportRendererCommandBufferSingleUsePolicyBlocked: Bool,
        didPreserveRendererCommandBufferCommitTimingGuard: Bool,
        didDefineFutureCommandBufferSingleUsePolicy: Bool,
        didDescribePostCommitInvalidationFact: Bool,
        didDescribeCompletionFailureFacts: Bool,
        didDescribeRollbackNoDrawFallback: Bool,
        didKeepCommandBufferSingleUsePolicyValueOnly: Bool,
        didAvoidRealBufferLifetimeManagement: Bool,
        didAvoidPassOrEncoderLifecycle: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.commitTimingGuard = commitTimingGuard
        this.didPrepareRendererCommandBufferSingleUsePolicy =
            didPrepareRendererCommandBufferSingleUsePolicy
        this.shouldDeferRendererCommandBufferSingleUsePolicy =
            shouldDeferRendererCommandBufferSingleUsePolicy
        this.shouldReportRendererCommandBufferSingleUsePolicyBlocked =
            shouldReportRendererCommandBufferSingleUsePolicyBlocked
        this.didPreserveRendererCommandBufferCommitTimingGuard =
            didPreserveRendererCommandBufferCommitTimingGuard
        this.didDefineFutureCommandBufferSingleUsePolicy =
            didDefineFutureCommandBufferSingleUsePolicy
        this.didDescribePostCommitInvalidationFact =
            didDescribePostCommitInvalidationFact
        this.didDescribeCompletionFailureFacts = didDescribeCompletionFailureFacts
        this.didDescribeRollbackNoDrawFallback = didDescribeRollbackNoDrawFallback
        this.didKeepCommandBufferSingleUsePolicyValueOnly =
            didKeepCommandBufferSingleUsePolicyValueOnly
        this.didAvoidRealBufferLifetimeManagement = didAvoidRealBufferLifetimeManagement
        this.didAvoidPassOrEncoderLifecycle = didAvoidPassOrEncoderLifecycle
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// No-command-buffer readiness 是本 owner 的 endpoint；
// readiness 只表示 future command buffer lifecycle boundary 可以继续评估，不代表
// command buffer、render pass、encoder、backend 或 render permission。
struct CjguiInternalRendererNoCommandBufferReadiness {
    let singleUsePolicy: CjguiInternalRendererCommandBufferSingleUsePolicy
    let isRendererNoCommandBufferReady: Bool
    let canFutureRendererCommandBufferBoundaryEvaluate: Bool
    let shouldDeferRendererNoCommandBufferReadiness: Bool
    let shouldReportRendererNoCommandBufferReadinessBlocked: Bool
    let didSealRendererNoCommandBufferReadiness: Bool
    let didPreserveRendererCommandBufferSingleUsePolicy: Bool
    let didKeepNoCommandBufferReadinessValueOnly: Bool
    let didConfirmNoCommandBufferCreated: Bool
    let didConfirmNoQueueOrDrawableObject: Bool
    let didConfirmNoRenderPassOrEncoderObject: Bool
    let didConfirmNoNativeResourceToken: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didAvoidBackendPermission: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        singleUsePolicy: CjguiInternalRendererCommandBufferSingleUsePolicy,
        isRendererNoCommandBufferReady: Bool,
        canFutureRendererCommandBufferBoundaryEvaluate: Bool,
        shouldDeferRendererNoCommandBufferReadiness: Bool,
        shouldReportRendererNoCommandBufferReadinessBlocked: Bool,
        didSealRendererNoCommandBufferReadiness: Bool,
        didPreserveRendererCommandBufferSingleUsePolicy: Bool,
        didKeepNoCommandBufferReadinessValueOnly: Bool,
        didConfirmNoCommandBufferCreated: Bool,
        didConfirmNoQueueOrDrawableObject: Bool,
        didConfirmNoRenderPassOrEncoderObject: Bool,
        didConfirmNoNativeResourceToken: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didAvoidBackendPermission: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.singleUsePolicy = singleUsePolicy
        this.isRendererNoCommandBufferReady = isRendererNoCommandBufferReady
        this.canFutureRendererCommandBufferBoundaryEvaluate =
            canFutureRendererCommandBufferBoundaryEvaluate
        this.shouldDeferRendererNoCommandBufferReadiness =
            shouldDeferRendererNoCommandBufferReadiness
        this.shouldReportRendererNoCommandBufferReadinessBlocked =
            shouldReportRendererNoCommandBufferReadinessBlocked
        this.didSealRendererNoCommandBufferReadiness =
            didSealRendererNoCommandBufferReadiness
        this.didPreserveRendererCommandBufferSingleUsePolicy =
            didPreserveRendererCommandBufferSingleUsePolicy
        this.didKeepNoCommandBufferReadinessValueOnly =
            didKeepNoCommandBufferReadinessValueOnly
        this.didConfirmNoCommandBufferCreated = didConfirmNoCommandBufferCreated
        this.didConfirmNoQueueOrDrawableObject = didConfirmNoQueueOrDrawableObject
        this.didConfirmNoRenderPassOrEncoderObject = didConfirmNoRenderPassOrEncoderObject
        this.didConfirmNoNativeResourceToken = didConfirmNoNativeResourceToken
        this.didConfirmNoPointerLikeResource = didConfirmNoPointerLikeResource
        this.didAvoidBackendPermission = didAvoidBackendPermission
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererCommandBufferLifecycleIntent(
    noDrawableReadiness: CjguiInternalRendererNoDrawableReadiness
): CjguiInternalRendererCommandBufferLifecycleIntent {
    let noDrawableReady = noDrawableReadiness.isRendererNoDrawableReady &&
        noDrawableReadiness.canFutureRendererDrawableAcquisitionBoundaryEvaluate &&
        noDrawableReadiness.didRecordRendererNoDrawableReadiness &&
        noDrawableReadiness.didPreserveRendererPresentationOwnershipPolicy &&
        noDrawableReadiness.didKeepNoDrawableReadinessValueOnly &&
        noDrawableReadiness.didConfirmNoDrawableAcquired &&
        noDrawableReadiness.didConfirmNoLayerOrDrawableObject &&
        noDrawableReadiness.didConfirmNoSubmissionPassOrEncoderObject &&
        noDrawableReadiness.didConfirmNoNativeResourceToken &&
        noDrawableReadiness.didConfirmNoPointerLikeResource &&
        noDrawableReadiness.didAvoidBackendPermission &&
        noDrawableReadiness.didAvoidRendererStateWrite &&
        noDrawableReadiness.didAvoidRenderingPermission &&
        noDrawableReadiness.didAvoidReceiptRecordEmission &&
        noDrawableReadiness.didStayFullRebuildOnly &&
        noDrawableReadiness.shouldDeferRendererNoDrawableReadiness == false &&
        noDrawableReadiness.shouldReportRendererNoDrawableReadinessBlocked == false
    let intentDeferred = noDrawableReadiness.isRendererNoDrawableReady == false &&
        noDrawableReadiness.canFutureRendererDrawableAcquisitionBoundaryEvaluate == false &&
        noDrawableReadiness.shouldDeferRendererNoDrawableReadiness &&
        noDrawableReadiness.shouldReportRendererNoDrawableReadinessBlocked == false
    let intentInconsistent = (
        noDrawableReadiness.isRendererNoDrawableReady &&
            (
                noDrawableReadiness.canFutureRendererDrawableAcquisitionBoundaryEvaluate == false ||
                noDrawableReadiness.didRecordRendererNoDrawableReadiness == false ||
                noDrawableReadiness.didPreserveRendererPresentationOwnershipPolicy == false ||
                noDrawableReadiness.didKeepNoDrawableReadinessValueOnly == false ||
                noDrawableReadiness.didConfirmNoDrawableAcquired == false ||
                noDrawableReadiness.didConfirmNoLayerOrDrawableObject == false ||
                noDrawableReadiness.didConfirmNoSubmissionPassOrEncoderObject == false ||
                noDrawableReadiness.didConfirmNoNativeResourceToken == false ||
                noDrawableReadiness.didConfirmNoPointerLikeResource == false ||
                noDrawableReadiness.didAvoidBackendPermission == false ||
                noDrawableReadiness.didAvoidRendererStateWrite == false ||
                noDrawableReadiness.didAvoidRenderingPermission == false ||
                noDrawableReadiness.didAvoidReceiptRecordEmission == false ||
                noDrawableReadiness.didStayFullRebuildOnly == false ||
                noDrawableReadiness.shouldDeferRendererNoDrawableReadiness ||
                noDrawableReadiness.shouldReportRendererNoDrawableReadinessBlocked
            )
        ) ||
        (noDrawableReadiness.canFutureRendererDrawableAcquisitionBoundaryEvaluate &&
            noDrawableReadiness.isRendererNoDrawableReady == false) ||
        (noDrawableReadiness.shouldDeferRendererNoDrawableReadiness &&
            noDrawableReadiness.shouldReportRendererNoDrawableReadinessBlocked)

    // fail-closed：不能把 no-drawable readiness 薄包成 command buffer lifecycle intent。
    if (
        noDrawableReadiness.shouldReportRendererNoDrawableReadinessBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererCommandBufferLifecycleIntent(
            noDrawableReadiness,
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
            true
        )
    }

    if (noDrawableReady) {
        return CjguiInternalRendererCommandBufferLifecycleIntent(
            noDrawableReadiness,
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
        return CjguiInternalRendererCommandBufferLifecycleIntent(
            noDrawableReadiness,
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

    return CjguiInternalRendererCommandBufferLifecycleIntent(
        noDrawableReadiness,
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
        true
    )
}

func cjguiInternalBuildRendererCommandBufferCreationPolicy(
    lifecycleIntent: CjguiInternalRendererCommandBufferLifecycleIntent
): CjguiInternalRendererCommandBufferCreationPolicy {
    let intentReady = lifecycleIntent.didPrepareRendererCommandBufferLifecycleIntent &&
        lifecycleIntent.didPreserveRendererNoDrawableReadiness &&
        lifecycleIntent.didDefineFutureCommandBufferLifecycleIntent &&
        lifecycleIntent.didDescribeCommandBufferCreationPhase &&
        lifecycleIntent.didDescribeQueueDrawableRelationship &&
        lifecycleIntent.didKeepCommandBufferLifecycleIntentValueOnly &&
        lifecycleIntent.didAvoidCommandBufferCreation &&
        lifecycleIntent.didAvoidBackendPermission &&
        lifecycleIntent.didAvoidRendererStateWrite &&
        lifecycleIntent.didAvoidRenderingPermission &&
        lifecycleIntent.didAvoidThinWrapper &&
        lifecycleIntent.shouldDeferRendererCommandBufferLifecycleIntent == false &&
        lifecycleIntent.shouldReportRendererCommandBufferLifecycleIntentBlocked == false
    let policyDeferred =
        lifecycleIntent.didPrepareRendererCommandBufferLifecycleIntent == false &&
        lifecycleIntent.shouldDeferRendererCommandBufferLifecycleIntent &&
        lifecycleIntent.shouldReportRendererCommandBufferLifecycleIntentBlocked == false
    let policyInconsistent = (
        lifecycleIntent.didPrepareRendererCommandBufferLifecycleIntent &&
            (
                lifecycleIntent.didPreserveRendererNoDrawableReadiness == false ||
                lifecycleIntent.didDefineFutureCommandBufferLifecycleIntent == false ||
                lifecycleIntent.didDescribeCommandBufferCreationPhase == false ||
                lifecycleIntent.didDescribeQueueDrawableRelationship == false ||
                lifecycleIntent.didKeepCommandBufferLifecycleIntentValueOnly == false ||
                lifecycleIntent.didAvoidCommandBufferCreation == false ||
                lifecycleIntent.didAvoidBackendPermission == false ||
                lifecycleIntent.didAvoidRendererStateWrite == false ||
                lifecycleIntent.didAvoidRenderingPermission == false ||
                lifecycleIntent.didAvoidThinWrapper == false ||
                lifecycleIntent.shouldDeferRendererCommandBufferLifecycleIntent ||
                lifecycleIntent.shouldReportRendererCommandBufferLifecycleIntentBlocked
            )
        ) ||
        (lifecycleIntent.didPreserveRendererNoDrawableReadiness &&
            lifecycleIntent.didPrepareRendererCommandBufferLifecycleIntent == false) ||
        (lifecycleIntent.shouldDeferRendererCommandBufferLifecycleIntent &&
            lifecycleIntent.shouldReportRendererCommandBufferLifecycleIntentBlocked)

    // creation policy 只描述 future creation preconditions；这里不创建 command buffer。
    if (
        lifecycleIntent.shouldReportRendererCommandBufferLifecycleIntentBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererCommandBufferCreationPolicy(
            lifecycleIntent,
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
            true
        )
    }

    if (intentReady) {
        return CjguiInternalRendererCommandBufferCreationPolicy(
            lifecycleIntent,
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

    if (policyDeferred) {
        return CjguiInternalRendererCommandBufferCreationPolicy(
            lifecycleIntent,
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

    return CjguiInternalRendererCommandBufferCreationPolicy(
        lifecycleIntent,
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
        true
    )
}

func cjguiInternalBuildRendererCommandBufferCommitTimingGuard(
    creationPolicy: CjguiInternalRendererCommandBufferCreationPolicy
): CjguiInternalRendererCommandBufferCommitTimingGuard {
    let policyReady = creationPolicy.didPrepareRendererCommandBufferCreationPolicy &&
        creationPolicy.didPreserveRendererCommandBufferLifecycleIntent &&
        creationPolicy.didDefineFutureCommandBufferCreationPreconditions &&
        creationPolicy.didDescribeCommandBufferCreationPhaseBoundary &&
        creationPolicy.didDescribeEncodingPhaseBoundary &&
        creationPolicy.didKeepCommandBufferCreationPolicyValueOnly &&
        creationPolicy.didAvoidCommandBufferCreation &&
        creationPolicy.didAvoidPlatformObjectCreation &&
        creationPolicy.didAvoidRendererStateWrite &&
        creationPolicy.didAvoidRenderingPermission &&
        creationPolicy.shouldDeferRendererCommandBufferCreationPolicy == false &&
        creationPolicy.shouldReportRendererCommandBufferCreationPolicyBlocked == false
    let guardDeferred =
        creationPolicy.didPrepareRendererCommandBufferCreationPolicy == false &&
        creationPolicy.shouldDeferRendererCommandBufferCreationPolicy &&
        creationPolicy.shouldReportRendererCommandBufferCreationPolicyBlocked == false
    let guardInconsistent = (
        creationPolicy.didPrepareRendererCommandBufferCreationPolicy &&
            (
                creationPolicy.didPreserveRendererCommandBufferLifecycleIntent == false ||
                creationPolicy.didDefineFutureCommandBufferCreationPreconditions == false ||
                creationPolicy.didDescribeCommandBufferCreationPhaseBoundary == false ||
                creationPolicy.didDescribeEncodingPhaseBoundary == false ||
                creationPolicy.didKeepCommandBufferCreationPolicyValueOnly == false ||
                creationPolicy.didAvoidCommandBufferCreation == false ||
                creationPolicy.didAvoidPlatformObjectCreation == false ||
                creationPolicy.didAvoidRendererStateWrite == false ||
                creationPolicy.didAvoidRenderingPermission == false ||
                creationPolicy.shouldDeferRendererCommandBufferCreationPolicy ||
                creationPolicy.shouldReportRendererCommandBufferCreationPolicyBlocked
            )
        ) ||
        (creationPolicy.didPreserveRendererCommandBufferLifecycleIntent &&
            creationPolicy.didPrepareRendererCommandBufferCreationPolicy == false) ||
        (creationPolicy.shouldDeferRendererCommandBufferCreationPolicy &&
            creationPolicy.shouldReportRendererCommandBufferCreationPolicyBlocked)

    // commit timing guard 只表达 timing constraints；这里不 commit。
    if (
        creationPolicy.shouldReportRendererCommandBufferCreationPolicyBlocked ||
        guardInconsistent
    ) {
        return CjguiInternalRendererCommandBufferCommitTimingGuard(
            creationPolicy,
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
            true
        )
    }

    if (policyReady) {
        return CjguiInternalRendererCommandBufferCommitTimingGuard(
            creationPolicy,
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

    if (guardDeferred) {
        return CjguiInternalRendererCommandBufferCommitTimingGuard(
            creationPolicy,
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

    return CjguiInternalRendererCommandBufferCommitTimingGuard(
        creationPolicy,
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
        true
    )
}

func cjguiInternalBuildRendererCommandBufferSingleUsePolicy(
    commitTimingGuard: CjguiInternalRendererCommandBufferCommitTimingGuard
): CjguiInternalRendererCommandBufferSingleUsePolicy {
    let guardReady = commitTimingGuard.didPrepareRendererCommandBufferCommitTimingGuard &&
        commitTimingGuard.didPreserveRendererCommandBufferCreationPolicy &&
        commitTimingGuard.didDefineFutureCommitTimingConstraints &&
        commitTimingGuard.didDescribeAfterEncodingBeforeCommitBoundary &&
        commitTimingGuard.didDescribeFramePacingCommitRelation &&
        commitTimingGuard.didKeepCommandBufferCommitTimingGuardValueOnly &&
        commitTimingGuard.didAvoidCommitSubmission &&
        commitTimingGuard.didAvoidCompletionCallback &&
        commitTimingGuard.didAvoidRendererStateWrite &&
        commitTimingGuard.didAvoidRenderingPermission &&
        commitTimingGuard.shouldDeferRendererCommandBufferCommitTimingGuard == false &&
        commitTimingGuard.shouldReportRendererCommandBufferCommitTimingGuardBlocked == false
    let policyDeferred =
        commitTimingGuard.didPrepareRendererCommandBufferCommitTimingGuard == false &&
        commitTimingGuard.shouldDeferRendererCommandBufferCommitTimingGuard &&
        commitTimingGuard.shouldReportRendererCommandBufferCommitTimingGuardBlocked == false
    let policyInconsistent = (
        commitTimingGuard.didPrepareRendererCommandBufferCommitTimingGuard &&
            (
                commitTimingGuard.didPreserveRendererCommandBufferCreationPolicy == false ||
                commitTimingGuard.didDefineFutureCommitTimingConstraints == false ||
                commitTimingGuard.didDescribeAfterEncodingBeforeCommitBoundary == false ||
                commitTimingGuard.didDescribeFramePacingCommitRelation == false ||
                commitTimingGuard.didKeepCommandBufferCommitTimingGuardValueOnly == false ||
                commitTimingGuard.didAvoidCommitSubmission == false ||
                commitTimingGuard.didAvoidCompletionCallback == false ||
                commitTimingGuard.didAvoidRendererStateWrite == false ||
                commitTimingGuard.didAvoidRenderingPermission == false ||
                commitTimingGuard.shouldDeferRendererCommandBufferCommitTimingGuard ||
                commitTimingGuard.shouldReportRendererCommandBufferCommitTimingGuardBlocked
            )
        ) ||
        (commitTimingGuard.didPreserveRendererCommandBufferCreationPolicy &&
            commitTimingGuard.didPrepareRendererCommandBufferCommitTimingGuard == false) ||
        (commitTimingGuard.shouldDeferRendererCommandBufferCommitTimingGuard &&
            commitTimingGuard.shouldReportRendererCommandBufferCommitTimingGuardBlocked)

    // single-use policy 不管理真实 command buffer lifetime。
    if (
        commitTimingGuard.shouldReportRendererCommandBufferCommitTimingGuardBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererCommandBufferSingleUsePolicy(
            commitTimingGuard,
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

    if (guardReady) {
        return CjguiInternalRendererCommandBufferSingleUsePolicy(
            commitTimingGuard,
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
        return CjguiInternalRendererCommandBufferSingleUsePolicy(
            commitTimingGuard,
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

    return CjguiInternalRendererCommandBufferSingleUsePolicy(
        commitTimingGuard,
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

func cjguiInternalBuildRendererNoCommandBufferReadiness(
    singleUsePolicy: CjguiInternalRendererCommandBufferSingleUsePolicy
): CjguiInternalRendererNoCommandBufferReadiness {
    let policyReady = singleUsePolicy.didPrepareRendererCommandBufferSingleUsePolicy &&
        singleUsePolicy.didPreserveRendererCommandBufferCommitTimingGuard &&
        singleUsePolicy.didDefineFutureCommandBufferSingleUsePolicy &&
        singleUsePolicy.didDescribePostCommitInvalidationFact &&
        singleUsePolicy.didDescribeCompletionFailureFacts &&
        singleUsePolicy.didDescribeRollbackNoDrawFallback &&
        singleUsePolicy.didKeepCommandBufferSingleUsePolicyValueOnly &&
        singleUsePolicy.didAvoidRealBufferLifetimeManagement &&
        singleUsePolicy.didAvoidPassOrEncoderLifecycle &&
        singleUsePolicy.didAvoidRendererStateWrite &&
        singleUsePolicy.didAvoidRenderingPermission &&
        singleUsePolicy.shouldDeferRendererCommandBufferSingleUsePolicy == false &&
        singleUsePolicy.shouldReportRendererCommandBufferSingleUsePolicyBlocked == false
    let readinessDeferred =
        singleUsePolicy.didPrepareRendererCommandBufferSingleUsePolicy == false &&
        singleUsePolicy.shouldDeferRendererCommandBufferSingleUsePolicy &&
        singleUsePolicy.shouldReportRendererCommandBufferSingleUsePolicyBlocked == false
    let readinessInconsistent = (
        singleUsePolicy.didPrepareRendererCommandBufferSingleUsePolicy &&
            (
                singleUsePolicy.didPreserveRendererCommandBufferCommitTimingGuard == false ||
                singleUsePolicy.didDefineFutureCommandBufferSingleUsePolicy == false ||
                singleUsePolicy.didDescribePostCommitInvalidationFact == false ||
                singleUsePolicy.didDescribeCompletionFailureFacts == false ||
                singleUsePolicy.didDescribeRollbackNoDrawFallback == false ||
                singleUsePolicy.didKeepCommandBufferSingleUsePolicyValueOnly == false ||
                singleUsePolicy.didAvoidRealBufferLifetimeManagement == false ||
                singleUsePolicy.didAvoidPassOrEncoderLifecycle == false ||
                singleUsePolicy.didAvoidRendererStateWrite == false ||
                singleUsePolicy.didAvoidRenderingPermission == false ||
                singleUsePolicy.shouldDeferRendererCommandBufferSingleUsePolicy ||
                singleUsePolicy.shouldReportRendererCommandBufferSingleUsePolicyBlocked
            )
        ) ||
        (singleUsePolicy.didPreserveRendererCommandBufferCommitTimingGuard &&
            singleUsePolicy.didPrepareRendererCommandBufferSingleUsePolicy == false) ||
        (singleUsePolicy.shouldDeferRendererCommandBufferSingleUsePolicy &&
            singleUsePolicy.shouldReportRendererCommandBufferSingleUsePolicyBlocked)

    // endpoint 只记录 no-command-buffer value facts；它不授予 backend 或 render permission。
    if (
        singleUsePolicy.shouldReportRendererCommandBufferSingleUsePolicyBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoCommandBufferReadiness(
            singleUsePolicy,
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
            true
        )
    }

    if (policyReady) {
        return CjguiInternalRendererNoCommandBufferReadiness(
            singleUsePolicy,
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
            true
        )
    }

    if (readinessDeferred) {
        return CjguiInternalRendererNoCommandBufferReadiness(
            singleUsePolicy,
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
            true
        )
    }

    return CjguiInternalRendererNoCommandBufferReadiness(
        singleUsePolicy,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererCommandBufferLifecycleDraft(
): CjguiInternalRendererNoCommandBufferReadiness {
    // 默认 draft 只串联 no-drawable -> command buffer lifecycle value facts；
    // 它不创建 command buffer、不创建平台对象、不提交或执行任何绘制。
    let noDrawableReadiness = cjguiInternalExecuteDefaultRendererDrawableAcquisitionDraft()
    let lifecycleIntent =
        cjguiInternalBuildRendererCommandBufferLifecycleIntent(noDrawableReadiness)
    let creationPolicy =
        cjguiInternalBuildRendererCommandBufferCreationPolicy(lifecycleIntent)
    let commitTimingGuard =
        cjguiInternalBuildRendererCommandBufferCommitTimingGuard(creationPolicy)
    let singleUsePolicy =
        cjguiInternalBuildRendererCommandBufferSingleUsePolicy(commitTimingGuard)
    return cjguiInternalBuildRendererNoCommandBufferReadiness(singleUsePolicy)
}
