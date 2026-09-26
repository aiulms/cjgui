package cjgui

// Owner: Renderer encoder lifecycle value boundary.
// Truth: 只消费 CjguiInternalRendererNoRenderPassReadiness，表达 future encoder
// lifecycle intent、encoding scope policy、pipeline binding guard、end-encoding policy
// 与 no-encoder readiness 的内部 value facts。
// Stop-line: 这里不创建或持有 MTLRenderCommandEncoder / MTLRenderPassDescriptor /
// pipeline state / command-buffer / drawable / texture / native resource token /
// pointer-like resource，不接后端，不触发绘制，不改 renderer state。
// Same-shape Boundary Brake: 本 owner 新增 encoding scope / pipeline binding guard /
// end-encoding / no-encoder vocabulary，不把 no-render-pass readiness 包成 receipt /
// record / emission。

// Encoder lifecycle intent 只表达 future lifecycle intent；
// 它不是 encoder creation，也不是 backend readiness wrapper。
struct CjguiInternalRendererEncoderLifecycleIntent {
    let noRenderPassReadiness: CjguiInternalRendererNoRenderPassReadiness
    let didPrepareRendererEncoderLifecycleIntent: Bool
    let shouldDeferRendererEncoderLifecycleIntent: Bool
    let shouldReportRendererEncoderLifecycleIntentBlocked: Bool
    let didPreserveRendererNoRenderPassReadiness: Bool
    let didDefineFutureEncoderLifecycleIntent: Bool
    let didDescribeEncodingScopeFacts: Bool
    let didDescribeRenderPassCommandRelation: Bool
    let didKeepEncoderLifecycleIntentValueOnly: Bool
    let didAvoidEncoderCreation: Bool
    let didAvoidBackendPermission: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidRenderingPermission: Bool
    let didAvoidThinWrapper: Bool

    init(
        noRenderPassReadiness: CjguiInternalRendererNoRenderPassReadiness,
        didPrepareRendererEncoderLifecycleIntent: Bool,
        shouldDeferRendererEncoderLifecycleIntent: Bool,
        shouldReportRendererEncoderLifecycleIntentBlocked: Bool,
        didPreserveRendererNoRenderPassReadiness: Bool,
        didDefineFutureEncoderLifecycleIntent: Bool,
        didDescribeEncodingScopeFacts: Bool,
        didDescribeRenderPassCommandRelation: Bool,
        didKeepEncoderLifecycleIntentValueOnly: Bool,
        didAvoidEncoderCreation: Bool,
        didAvoidBackendPermission: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidRenderingPermission: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noRenderPassReadiness = noRenderPassReadiness
        this.didPrepareRendererEncoderLifecycleIntent =
            didPrepareRendererEncoderLifecycleIntent
        this.shouldDeferRendererEncoderLifecycleIntent =
            shouldDeferRendererEncoderLifecycleIntent
        this.shouldReportRendererEncoderLifecycleIntentBlocked =
            shouldReportRendererEncoderLifecycleIntentBlocked
        this.didPreserveRendererNoRenderPassReadiness =
            didPreserveRendererNoRenderPassReadiness
        this.didDefineFutureEncoderLifecycleIntent =
            didDefineFutureEncoderLifecycleIntent
        this.didDescribeEncodingScopeFacts = didDescribeEncodingScopeFacts
        this.didDescribeRenderPassCommandRelation =
            didDescribeRenderPassCommandRelation
        this.didKeepEncoderLifecycleIntentValueOnly =
            didKeepEncoderLifecycleIntentValueOnly
        this.didAvoidEncoderCreation = didAvoidEncoderCreation
        this.didAvoidBackendPermission = didAvoidBackendPermission
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

// Encoding scope policy 只表达 future encoding scope / command sequencing facts；
// 它不 begin encoding，不设置 viewport 或 scissor state。
struct CjguiInternalRendererEncodingScopePolicy {
    let lifecycleIntent: CjguiInternalRendererEncoderLifecycleIntent
    let didPrepareRendererEncodingScopePolicy: Bool
    let shouldDeferRendererEncodingScopePolicy: Bool
    let shouldReportRendererEncodingScopePolicyBlocked: Bool
    let didPreserveRendererEncoderLifecycleIntent: Bool
    let didDefineFutureEncodingScopePolicy: Bool
    let didDescribeCommandSequencingBoundary: Bool
    let didDescribeViewportScissorPlaceholders: Bool
    let didDescribeFailureNoDrawFallback: Bool
    let didKeepEncodingScopePolicyValueOnly: Bool
    let didAvoidBeginEncoding: Bool
    let didAvoidViewportScissorStateSetting: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidRenderingPermission: Bool

    init(
        lifecycleIntent: CjguiInternalRendererEncoderLifecycleIntent,
        didPrepareRendererEncodingScopePolicy: Bool,
        shouldDeferRendererEncodingScopePolicy: Bool,
        shouldReportRendererEncodingScopePolicyBlocked: Bool,
        didPreserveRendererEncoderLifecycleIntent: Bool,
        didDefineFutureEncodingScopePolicy: Bool,
        didDescribeCommandSequencingBoundary: Bool,
        didDescribeViewportScissorPlaceholders: Bool,
        didDescribeFailureNoDrawFallback: Bool,
        didKeepEncodingScopePolicyValueOnly: Bool,
        didAvoidBeginEncoding: Bool,
        didAvoidViewportScissorStateSetting: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.lifecycleIntent = lifecycleIntent
        this.didPrepareRendererEncodingScopePolicy =
            didPrepareRendererEncodingScopePolicy
        this.shouldDeferRendererEncodingScopePolicy =
            shouldDeferRendererEncodingScopePolicy
        this.shouldReportRendererEncodingScopePolicyBlocked =
            shouldReportRendererEncodingScopePolicyBlocked
        this.didPreserveRendererEncoderLifecycleIntent =
            didPreserveRendererEncoderLifecycleIntent
        this.didDefineFutureEncodingScopePolicy = didDefineFutureEncodingScopePolicy
        this.didDescribeCommandSequencingBoundary =
            didDescribeCommandSequencingBoundary
        this.didDescribeViewportScissorPlaceholders =
            didDescribeViewportScissorPlaceholders
        this.didDescribeFailureNoDrawFallback = didDescribeFailureNoDrawFallback
        this.didKeepEncodingScopePolicyValueOnly =
            didKeepEncodingScopePolicyValueOnly
        this.didAvoidBeginEncoding = didAvoidBeginEncoding
        this.didAvoidViewportScissorStateSetting =
            didAvoidViewportScissorStateSetting
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// Pipeline binding guard 只表达 future pipeline/resource binding preconditions；
// 它不绑定 pipeline，不持有 pipeline state，也不进入 draw-command lifecycle。
struct CjguiInternalRendererPipelineBindingGuard {
    let encodingScopePolicy: CjguiInternalRendererEncodingScopePolicy
    let didPrepareRendererPipelineBindingGuard: Bool
    let shouldDeferRendererPipelineBindingGuard: Bool
    let shouldReportRendererPipelineBindingGuardBlocked: Bool
    let didPreserveRendererEncodingScopePolicy: Bool
    let didDefineFuturePipelineBindingGuard: Bool
    let didDescribePipelineBindingPreconditions: Bool
    let didDescribeResourceBindingPlaceholderFacts: Bool
    let didDescribeDrawCommandSequencingGuard: Bool
    let didKeepPipelineBindingGuardValueOnly: Bool
    let didAvoidPipelineBinding: Bool
    let didAvoidPipelineStateObject: Bool
    let didAvoidDrawCommandEmission: Bool
    let didAvoidRenderingPermission: Bool

    init(
        encodingScopePolicy: CjguiInternalRendererEncodingScopePolicy,
        didPrepareRendererPipelineBindingGuard: Bool,
        shouldDeferRendererPipelineBindingGuard: Bool,
        shouldReportRendererPipelineBindingGuardBlocked: Bool,
        didPreserveRendererEncodingScopePolicy: Bool,
        didDefineFuturePipelineBindingGuard: Bool,
        didDescribePipelineBindingPreconditions: Bool,
        didDescribeResourceBindingPlaceholderFacts: Bool,
        didDescribeDrawCommandSequencingGuard: Bool,
        didKeepPipelineBindingGuardValueOnly: Bool,
        didAvoidPipelineBinding: Bool,
        didAvoidPipelineStateObject: Bool,
        didAvoidDrawCommandEmission: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.encodingScopePolicy = encodingScopePolicy
        this.didPrepareRendererPipelineBindingGuard =
            didPrepareRendererPipelineBindingGuard
        this.shouldDeferRendererPipelineBindingGuard =
            shouldDeferRendererPipelineBindingGuard
        this.shouldReportRendererPipelineBindingGuardBlocked =
            shouldReportRendererPipelineBindingGuardBlocked
        this.didPreserveRendererEncodingScopePolicy =
            didPreserveRendererEncodingScopePolicy
        this.didDefineFuturePipelineBindingGuard =
            didDefineFuturePipelineBindingGuard
        this.didDescribePipelineBindingPreconditions =
            didDescribePipelineBindingPreconditions
        this.didDescribeResourceBindingPlaceholderFacts =
            didDescribeResourceBindingPlaceholderFacts
        this.didDescribeDrawCommandSequencingGuard =
            didDescribeDrawCommandSequencingGuard
        this.didKeepPipelineBindingGuardValueOnly =
            didKeepPipelineBindingGuardValueOnly
        this.didAvoidPipelineBinding = didAvoidPipelineBinding
        this.didAvoidPipelineStateObject = didAvoidPipelineStateObject
        this.didAvoidDrawCommandEmission = didAvoidDrawCommandEmission
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// End-encoding policy 只表达 future end-encoding boundary facts；
// 它不 end encoding，不 close encoder，也不提交 platform work.
struct CjguiInternalRendererEndEncodingPolicy {
    let pipelineBindingGuard: CjguiInternalRendererPipelineBindingGuard
    let didPrepareRendererEndEncodingPolicy: Bool
    let shouldDeferRendererEndEncodingPolicy: Bool
    let shouldReportRendererEndEncodingPolicyBlocked: Bool
    let didPreserveRendererPipelineBindingGuard: Bool
    let didDefineFutureEndEncodingPolicy: Bool
    let didDescribeEndEncodingBoundary: Bool
    let didDescribePostEncodingInvalidationFacts: Bool
    let didDescribeFailureRollbackFacts: Bool
    let didKeepEndEncodingPolicyValueOnly: Bool
    let didAvoidEndEncodingCall: Bool
    let didAvoidEncoderLifetimeManagement: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidRenderingPermission: Bool

    init(
        pipelineBindingGuard: CjguiInternalRendererPipelineBindingGuard,
        didPrepareRendererEndEncodingPolicy: Bool,
        shouldDeferRendererEndEncodingPolicy: Bool,
        shouldReportRendererEndEncodingPolicyBlocked: Bool,
        didPreserveRendererPipelineBindingGuard: Bool,
        didDefineFutureEndEncodingPolicy: Bool,
        didDescribeEndEncodingBoundary: Bool,
        didDescribePostEncodingInvalidationFacts: Bool,
        didDescribeFailureRollbackFacts: Bool,
        didKeepEndEncodingPolicyValueOnly: Bool,
        didAvoidEndEncodingCall: Bool,
        didAvoidEncoderLifetimeManagement: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.pipelineBindingGuard = pipelineBindingGuard
        this.didPrepareRendererEndEncodingPolicy =
            didPrepareRendererEndEncodingPolicy
        this.shouldDeferRendererEndEncodingPolicy =
            shouldDeferRendererEndEncodingPolicy
        this.shouldReportRendererEndEncodingPolicyBlocked =
            shouldReportRendererEndEncodingPolicyBlocked
        this.didPreserveRendererPipelineBindingGuard =
            didPreserveRendererPipelineBindingGuard
        this.didDefineFutureEndEncodingPolicy = didDefineFutureEndEncodingPolicy
        this.didDescribeEndEncodingBoundary = didDescribeEndEncodingBoundary
        this.didDescribePostEncodingInvalidationFacts =
            didDescribePostEncodingInvalidationFacts
        this.didDescribeFailureRollbackFacts = didDescribeFailureRollbackFacts
        this.didKeepEndEncodingPolicyValueOnly = didKeepEndEncodingPolicyValueOnly
        this.didAvoidEndEncodingCall = didAvoidEndEncodingCall
        this.didAvoidEncoderLifetimeManagement = didAvoidEncoderLifetimeManagement
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// No-encoder readiness 是本 owner 的 endpoint；
// readiness 只表示 future encoder lifecycle boundary 可以继续评估，不代表
// MTLRenderCommandEncoder、pipeline state、draw-command、descriptor、command-buffer、
// backend 或 render permission。
struct CjguiInternalRendererNoEncoderReadiness {
    let endEncodingPolicy: CjguiInternalRendererEndEncodingPolicy
    let isRendererNoEncoderReady: Bool
    let canFutureRendererEncoderBoundaryEvaluate: Bool
    let shouldDeferRendererNoEncoderReadiness: Bool
    let shouldReportRendererNoEncoderReadinessBlocked: Bool
    let didSealRendererNoEncoderReadiness: Bool
    let didPreserveRendererEndEncodingPolicy: Bool
    let didKeepNoEncoderReadinessValueOnly: Bool
    let didConfirmNoEncoderCreated: Bool
    let didConfirmNoPipelineStateObject: Bool
    let didConfirmNoDrawCommandIssued: Bool
    let didConfirmNoRenderPassDescriptorObject: Bool
    let didConfirmNoCommandBufferObject: Bool
    let didConfirmNoNativeResourceToken: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didAvoidBackendPermission: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidRenderingPermission: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        endEncodingPolicy: CjguiInternalRendererEndEncodingPolicy,
        isRendererNoEncoderReady: Bool,
        canFutureRendererEncoderBoundaryEvaluate: Bool,
        shouldDeferRendererNoEncoderReadiness: Bool,
        shouldReportRendererNoEncoderReadinessBlocked: Bool,
        didSealRendererNoEncoderReadiness: Bool,
        didPreserveRendererEndEncodingPolicy: Bool,
        didKeepNoEncoderReadinessValueOnly: Bool,
        didConfirmNoEncoderCreated: Bool,
        didConfirmNoPipelineStateObject: Bool,
        didConfirmNoDrawCommandIssued: Bool,
        didConfirmNoRenderPassDescriptorObject: Bool,
        didConfirmNoCommandBufferObject: Bool,
        didConfirmNoNativeResourceToken: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didAvoidBackendPermission: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidRenderingPermission: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.endEncodingPolicy = endEncodingPolicy
        this.isRendererNoEncoderReady = isRendererNoEncoderReady
        this.canFutureRendererEncoderBoundaryEvaluate =
            canFutureRendererEncoderBoundaryEvaluate
        this.shouldDeferRendererNoEncoderReadiness =
            shouldDeferRendererNoEncoderReadiness
        this.shouldReportRendererNoEncoderReadinessBlocked =
            shouldReportRendererNoEncoderReadinessBlocked
        this.didSealRendererNoEncoderReadiness = didSealRendererNoEncoderReadiness
        this.didPreserveRendererEndEncodingPolicy =
            didPreserveRendererEndEncodingPolicy
        this.didKeepNoEncoderReadinessValueOnly =
            didKeepNoEncoderReadinessValueOnly
        this.didConfirmNoEncoderCreated = didConfirmNoEncoderCreated
        this.didConfirmNoPipelineStateObject = didConfirmNoPipelineStateObject
        this.didConfirmNoDrawCommandIssued = didConfirmNoDrawCommandIssued
        this.didConfirmNoRenderPassDescriptorObject =
            didConfirmNoRenderPassDescriptorObject
        this.didConfirmNoCommandBufferObject = didConfirmNoCommandBufferObject
        this.didConfirmNoNativeResourceToken = didConfirmNoNativeResourceToken
        this.didConfirmNoPointerLikeResource = didConfirmNoPointerLikeResource
        this.didAvoidBackendPermission = didAvoidBackendPermission
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererEncoderLifecycleIntent(
    noRenderPassReadiness: CjguiInternalRendererNoRenderPassReadiness
): CjguiInternalRendererEncoderLifecycleIntent {
    let noRenderPassReady = noRenderPassReadiness.isRendererNoRenderPassReady &&
        noRenderPassReadiness.canFutureRendererRenderPassBoundaryEvaluate &&
        noRenderPassReadiness.didSealRendererNoRenderPassReadiness &&
        noRenderPassReadiness.didPreserveRendererRenderPassClearColorPolicy &&
        noRenderPassReadiness.didKeepNoRenderPassReadinessValueOnly &&
        noRenderPassReadiness.didConfirmNoRenderPassDescriptorCreated &&
        noRenderPassReadiness.didConfirmNoEncoderCreated &&
        noRenderPassReadiness.didConfirmNoDrawableTextureOrAttachmentObject &&
        noRenderPassReadiness.didConfirmNoCommandBufferObject &&
        noRenderPassReadiness.didConfirmNoPlatformObjectReference &&
        noRenderPassReadiness.didConfirmNoPointerLikeResource &&
        noRenderPassReadiness.didAvoidBackendPermission &&
        noRenderPassReadiness.didAvoidRendererStateWrite &&
        noRenderPassReadiness.didAvoidRenderingPermission &&
        noRenderPassReadiness.didAvoidReceiptRecordEmission &&
        noRenderPassReadiness.didStayFullRebuildOnly &&
        noRenderPassReadiness.shouldDeferRendererNoRenderPassReadiness == false &&
        noRenderPassReadiness.shouldReportRendererNoRenderPassReadinessBlocked == false
    let intentDeferred = noRenderPassReadiness.isRendererNoRenderPassReady == false &&
        noRenderPassReadiness.canFutureRendererRenderPassBoundaryEvaluate == false &&
        noRenderPassReadiness.shouldDeferRendererNoRenderPassReadiness &&
        noRenderPassReadiness.shouldReportRendererNoRenderPassReadinessBlocked == false
    let intentInconsistent = (
        noRenderPassReadiness.isRendererNoRenderPassReady &&
            (
                noRenderPassReadiness.canFutureRendererRenderPassBoundaryEvaluate == false ||
                noRenderPassReadiness.didSealRendererNoRenderPassReadiness == false ||
                noRenderPassReadiness.didPreserveRendererRenderPassClearColorPolicy == false ||
                noRenderPassReadiness.didKeepNoRenderPassReadinessValueOnly == false ||
                noRenderPassReadiness.didConfirmNoRenderPassDescriptorCreated == false ||
                noRenderPassReadiness.didConfirmNoEncoderCreated == false ||
                noRenderPassReadiness.didConfirmNoDrawableTextureOrAttachmentObject == false ||
                noRenderPassReadiness.didConfirmNoCommandBufferObject == false ||
                noRenderPassReadiness.didConfirmNoPlatformObjectReference == false ||
                noRenderPassReadiness.didConfirmNoPointerLikeResource == false ||
                noRenderPassReadiness.didAvoidBackendPermission == false ||
                noRenderPassReadiness.didAvoidRendererStateWrite == false ||
                noRenderPassReadiness.didAvoidRenderingPermission == false ||
                noRenderPassReadiness.didAvoidReceiptRecordEmission == false ||
                noRenderPassReadiness.didStayFullRebuildOnly == false ||
                noRenderPassReadiness.shouldDeferRendererNoRenderPassReadiness ||
                noRenderPassReadiness.shouldReportRendererNoRenderPassReadinessBlocked
            )
        ) ||
        (noRenderPassReadiness.canFutureRendererRenderPassBoundaryEvaluate &&
            noRenderPassReadiness.isRendererNoRenderPassReady == false) ||
        (noRenderPassReadiness.shouldDeferRendererNoRenderPassReadiness &&
            noRenderPassReadiness.shouldReportRendererNoRenderPassReadinessBlocked)

    // fail-closed：不能把 no-render-pass readiness 薄包成 encoder lifecycle intent。
    if (
        noRenderPassReadiness.shouldReportRendererNoRenderPassReadinessBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererEncoderLifecycleIntent(
            noRenderPassReadiness,
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

    if (noRenderPassReady) {
        return CjguiInternalRendererEncoderLifecycleIntent(
            noRenderPassReadiness,
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
        return CjguiInternalRendererEncoderLifecycleIntent(
            noRenderPassReadiness,
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

    return CjguiInternalRendererEncoderLifecycleIntent(
        noRenderPassReadiness,
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

func cjguiInternalBuildRendererEncodingScopePolicy(
    lifecycleIntent: CjguiInternalRendererEncoderLifecycleIntent
): CjguiInternalRendererEncodingScopePolicy {
    let intentReady = lifecycleIntent.didPrepareRendererEncoderLifecycleIntent &&
        lifecycleIntent.didPreserveRendererNoRenderPassReadiness &&
        lifecycleIntent.didDefineFutureEncoderLifecycleIntent &&
        lifecycleIntent.didDescribeEncodingScopeFacts &&
        lifecycleIntent.didDescribeRenderPassCommandRelation &&
        lifecycleIntent.didKeepEncoderLifecycleIntentValueOnly &&
        lifecycleIntent.didAvoidEncoderCreation &&
        lifecycleIntent.didAvoidBackendPermission &&
        lifecycleIntent.didAvoidRendererStateMutation &&
        lifecycleIntent.didAvoidRenderingPermission &&
        lifecycleIntent.didAvoidThinWrapper &&
        lifecycleIntent.shouldDeferRendererEncoderLifecycleIntent == false &&
        lifecycleIntent.shouldReportRendererEncoderLifecycleIntentBlocked == false
    let policyDeferred =
        lifecycleIntent.didPrepareRendererEncoderLifecycleIntent == false &&
        lifecycleIntent.shouldDeferRendererEncoderLifecycleIntent &&
        lifecycleIntent.shouldReportRendererEncoderLifecycleIntentBlocked == false
    let policyInconsistent = (
        lifecycleIntent.didPrepareRendererEncoderLifecycleIntent &&
            (
                lifecycleIntent.didPreserveRendererNoRenderPassReadiness == false ||
                lifecycleIntent.didDefineFutureEncoderLifecycleIntent == false ||
                lifecycleIntent.didDescribeEncodingScopeFacts == false ||
                lifecycleIntent.didDescribeRenderPassCommandRelation == false ||
                lifecycleIntent.didKeepEncoderLifecycleIntentValueOnly == false ||
                lifecycleIntent.didAvoidEncoderCreation == false ||
                lifecycleIntent.didAvoidBackendPermission == false ||
                lifecycleIntent.didAvoidRendererStateMutation == false ||
                lifecycleIntent.didAvoidRenderingPermission == false ||
                lifecycleIntent.didAvoidThinWrapper == false ||
                lifecycleIntent.shouldDeferRendererEncoderLifecycleIntent ||
                lifecycleIntent.shouldReportRendererEncoderLifecycleIntentBlocked
            )
        ) ||
        (lifecycleIntent.didPreserveRendererNoRenderPassReadiness &&
            lifecycleIntent.didPrepareRendererEncoderLifecycleIntent == false) ||
        (lifecycleIntent.shouldDeferRendererEncoderLifecycleIntent &&
            lifecycleIntent.shouldReportRendererEncoderLifecycleIntentBlocked)

    // encoding scope policy 只描述 scope / sequencing facts；这里不 begin encoding。
    if (
        lifecycleIntent.shouldReportRendererEncoderLifecycleIntentBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererEncodingScopePolicy(
            lifecycleIntent,
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
        return CjguiInternalRendererEncodingScopePolicy(
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
            true,
            true
        )
    }

    if (policyDeferred) {
        return CjguiInternalRendererEncodingScopePolicy(
            lifecycleIntent,
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

    return CjguiInternalRendererEncodingScopePolicy(
        lifecycleIntent,
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

func cjguiInternalBuildRendererPipelineBindingGuard(
    encodingScopePolicy: CjguiInternalRendererEncodingScopePolicy
): CjguiInternalRendererPipelineBindingGuard {
    let policyReady = encodingScopePolicy.didPrepareRendererEncodingScopePolicy &&
        encodingScopePolicy.didPreserveRendererEncoderLifecycleIntent &&
        encodingScopePolicy.didDefineFutureEncodingScopePolicy &&
        encodingScopePolicy.didDescribeCommandSequencingBoundary &&
        encodingScopePolicy.didDescribeViewportScissorPlaceholders &&
        encodingScopePolicy.didDescribeFailureNoDrawFallback &&
        encodingScopePolicy.didKeepEncodingScopePolicyValueOnly &&
        encodingScopePolicy.didAvoidBeginEncoding &&
        encodingScopePolicy.didAvoidViewportScissorStateSetting &&
        encodingScopePolicy.didAvoidRendererStateMutation &&
        encodingScopePolicy.didAvoidRenderingPermission &&
        encodingScopePolicy.shouldDeferRendererEncodingScopePolicy == false &&
        encodingScopePolicy.shouldReportRendererEncodingScopePolicyBlocked == false
    let guardDeferred =
        encodingScopePolicy.didPrepareRendererEncodingScopePolicy == false &&
        encodingScopePolicy.shouldDeferRendererEncodingScopePolicy &&
        encodingScopePolicy.shouldReportRendererEncodingScopePolicyBlocked == false
    let guardInconsistent = (
        encodingScopePolicy.didPrepareRendererEncodingScopePolicy &&
            (
                encodingScopePolicy.didPreserveRendererEncoderLifecycleIntent == false ||
                encodingScopePolicy.didDefineFutureEncodingScopePolicy == false ||
                encodingScopePolicy.didDescribeCommandSequencingBoundary == false ||
                encodingScopePolicy.didDescribeViewportScissorPlaceholders == false ||
                encodingScopePolicy.didDescribeFailureNoDrawFallback == false ||
                encodingScopePolicy.didKeepEncodingScopePolicyValueOnly == false ||
                encodingScopePolicy.didAvoidBeginEncoding == false ||
                encodingScopePolicy.didAvoidViewportScissorStateSetting == false ||
                encodingScopePolicy.didAvoidRendererStateMutation == false ||
                encodingScopePolicy.didAvoidRenderingPermission == false ||
                encodingScopePolicy.shouldDeferRendererEncodingScopePolicy ||
                encodingScopePolicy.shouldReportRendererEncodingScopePolicyBlocked
            )
        ) ||
        (encodingScopePolicy.didPreserveRendererEncoderLifecycleIntent &&
            encodingScopePolicy.didPrepareRendererEncodingScopePolicy == false) ||
        (encodingScopePolicy.shouldDeferRendererEncodingScopePolicy &&
            encodingScopePolicy.shouldReportRendererEncodingScopePolicyBlocked)

    // pipeline binding guard 只表达 preconditions；这里不绑定 pipeline。
    if (
        encodingScopePolicy.shouldReportRendererEncodingScopePolicyBlocked ||
        guardInconsistent
    ) {
        return CjguiInternalRendererPipelineBindingGuard(
            encodingScopePolicy,
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
        return CjguiInternalRendererPipelineBindingGuard(
            encodingScopePolicy,
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
        return CjguiInternalRendererPipelineBindingGuard(
            encodingScopePolicy,
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

    return CjguiInternalRendererPipelineBindingGuard(
        encodingScopePolicy,
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

func cjguiInternalBuildRendererEndEncodingPolicy(
    pipelineBindingGuard: CjguiInternalRendererPipelineBindingGuard
): CjguiInternalRendererEndEncodingPolicy {
    let guardReady = pipelineBindingGuard.didPrepareRendererPipelineBindingGuard &&
        pipelineBindingGuard.didPreserveRendererEncodingScopePolicy &&
        pipelineBindingGuard.didDefineFuturePipelineBindingGuard &&
        pipelineBindingGuard.didDescribePipelineBindingPreconditions &&
        pipelineBindingGuard.didDescribeResourceBindingPlaceholderFacts &&
        pipelineBindingGuard.didDescribeDrawCommandSequencingGuard &&
        pipelineBindingGuard.didKeepPipelineBindingGuardValueOnly &&
        pipelineBindingGuard.didAvoidPipelineBinding &&
        pipelineBindingGuard.didAvoidPipelineStateObject &&
        pipelineBindingGuard.didAvoidDrawCommandEmission &&
        pipelineBindingGuard.didAvoidRenderingPermission &&
        pipelineBindingGuard.shouldDeferRendererPipelineBindingGuard == false &&
        pipelineBindingGuard.shouldReportRendererPipelineBindingGuardBlocked == false
    let policyDeferred =
        pipelineBindingGuard.didPrepareRendererPipelineBindingGuard == false &&
        pipelineBindingGuard.shouldDeferRendererPipelineBindingGuard &&
        pipelineBindingGuard.shouldReportRendererPipelineBindingGuardBlocked == false
    let policyInconsistent = (
        pipelineBindingGuard.didPrepareRendererPipelineBindingGuard &&
            (
                pipelineBindingGuard.didPreserveRendererEncodingScopePolicy == false ||
                pipelineBindingGuard.didDefineFuturePipelineBindingGuard == false ||
                pipelineBindingGuard.didDescribePipelineBindingPreconditions == false ||
                pipelineBindingGuard.didDescribeResourceBindingPlaceholderFacts == false ||
                pipelineBindingGuard.didDescribeDrawCommandSequencingGuard == false ||
                pipelineBindingGuard.didKeepPipelineBindingGuardValueOnly == false ||
                pipelineBindingGuard.didAvoidPipelineBinding == false ||
                pipelineBindingGuard.didAvoidPipelineStateObject == false ||
                pipelineBindingGuard.didAvoidDrawCommandEmission == false ||
                pipelineBindingGuard.didAvoidRenderingPermission == false ||
                pipelineBindingGuard.shouldDeferRendererPipelineBindingGuard ||
                pipelineBindingGuard.shouldReportRendererPipelineBindingGuardBlocked
            )
        ) ||
        (pipelineBindingGuard.didPreserveRendererEncodingScopePolicy &&
            pipelineBindingGuard.didPrepareRendererPipelineBindingGuard == false) ||
        (pipelineBindingGuard.shouldDeferRendererPipelineBindingGuard &&
            pipelineBindingGuard.shouldReportRendererPipelineBindingGuardBlocked)

    // end-encoding policy 只表达 boundary facts；这里不 end encoding。
    if (
        pipelineBindingGuard.shouldReportRendererPipelineBindingGuardBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererEndEncodingPolicy(
            pipelineBindingGuard,
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
        return CjguiInternalRendererEndEncodingPolicy(
            pipelineBindingGuard,
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
        return CjguiInternalRendererEndEncodingPolicy(
            pipelineBindingGuard,
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

    return CjguiInternalRendererEndEncodingPolicy(
        pipelineBindingGuard,
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

func cjguiInternalBuildRendererNoEncoderReadiness(
    endEncodingPolicy: CjguiInternalRendererEndEncodingPolicy
): CjguiInternalRendererNoEncoderReadiness {
    let policyReady = endEncodingPolicy.didPrepareRendererEndEncodingPolicy &&
        endEncodingPolicy.didPreserveRendererPipelineBindingGuard &&
        endEncodingPolicy.didDefineFutureEndEncodingPolicy &&
        endEncodingPolicy.didDescribeEndEncodingBoundary &&
        endEncodingPolicy.didDescribePostEncodingInvalidationFacts &&
        endEncodingPolicy.didDescribeFailureRollbackFacts &&
        endEncodingPolicy.didKeepEndEncodingPolicyValueOnly &&
        endEncodingPolicy.didAvoidEndEncodingCall &&
        endEncodingPolicy.didAvoidEncoderLifetimeManagement &&
        endEncodingPolicy.didAvoidRendererStateMutation &&
        endEncodingPolicy.didAvoidRenderingPermission &&
        endEncodingPolicy.shouldDeferRendererEndEncodingPolicy == false &&
        endEncodingPolicy.shouldReportRendererEndEncodingPolicyBlocked == false
    let readinessDeferred =
        endEncodingPolicy.didPrepareRendererEndEncodingPolicy == false &&
        endEncodingPolicy.shouldDeferRendererEndEncodingPolicy &&
        endEncodingPolicy.shouldReportRendererEndEncodingPolicyBlocked == false
    let readinessInconsistent = (
        endEncodingPolicy.didPrepareRendererEndEncodingPolicy &&
            (
                endEncodingPolicy.didPreserveRendererPipelineBindingGuard == false ||
                endEncodingPolicy.didDefineFutureEndEncodingPolicy == false ||
                endEncodingPolicy.didDescribeEndEncodingBoundary == false ||
                endEncodingPolicy.didDescribePostEncodingInvalidationFacts == false ||
                endEncodingPolicy.didDescribeFailureRollbackFacts == false ||
                endEncodingPolicy.didKeepEndEncodingPolicyValueOnly == false ||
                endEncodingPolicy.didAvoidEndEncodingCall == false ||
                endEncodingPolicy.didAvoidEncoderLifetimeManagement == false ||
                endEncodingPolicy.didAvoidRendererStateMutation == false ||
                endEncodingPolicy.didAvoidRenderingPermission == false ||
                endEncodingPolicy.shouldDeferRendererEndEncodingPolicy ||
                endEncodingPolicy.shouldReportRendererEndEncodingPolicyBlocked
            )
        ) ||
        (endEncodingPolicy.didPreserveRendererPipelineBindingGuard &&
            endEncodingPolicy.didPrepareRendererEndEncodingPolicy == false) ||
        (endEncodingPolicy.shouldDeferRendererEndEncodingPolicy &&
            endEncodingPolicy.shouldReportRendererEndEncodingPolicyBlocked)

    // no-encoder readiness 只封口 value facts；这里不生成 receipt / record / emission。
    if (
        endEncodingPolicy.shouldReportRendererEndEncodingPolicyBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoEncoderReadiness(
            endEncodingPolicy,
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
            true
        )
    }

    if (policyReady) {
        return CjguiInternalRendererNoEncoderReadiness(
            endEncodingPolicy,
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
            true
        )
    }

    if (readinessDeferred) {
        return CjguiInternalRendererNoEncoderReadiness(
            endEncodingPolicy,
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
            true
        )
    }

    return CjguiInternalRendererNoEncoderReadiness(
        endEncodingPolicy,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererEncoderLifecycleDraft(
): CjguiInternalRendererNoEncoderReadiness {
    let noRenderPassReadiness =
        cjguiInternalExecuteDefaultRendererRenderPassLifecycleDraft()
    let lifecycleIntent = cjguiInternalBuildRendererEncoderLifecycleIntent(
        noRenderPassReadiness
    )
    let encodingScopePolicy = cjguiInternalBuildRendererEncodingScopePolicy(
        lifecycleIntent
    )
    let pipelineBindingGuard = cjguiInternalBuildRendererPipelineBindingGuard(
        encodingScopePolicy
    )
    let endEncodingPolicy = cjguiInternalBuildRendererEndEncodingPolicy(
        pipelineBindingGuard
    )
    return cjguiInternalBuildRendererNoEncoderReadiness(endEncodingPolicy)
}
