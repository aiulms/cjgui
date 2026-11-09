package cjgui

// Owner: Renderer pipeline state lifecycle value boundary.
// Truth: 只消费 CjguiInternalRendererNoDrawCallReadiness，表达 future pipeline
// state lifecycle intent、shader role policy、descriptor policy、compatibility
// guard 与 no-pipeline-state readiness 的内部 value facts。
// Stop-line: 这里不创建 MTLRenderPipelineState / MTLRenderPipelineDescriptor，
// 不加载 shader library / function，不调用 encoder，不绑定 buffer / texture，
// 不提交 GPU work，不接后端，不触发 render execution，不写 renderer state，
// 不持有 native resource token 或 pointer-like resource。
// Same-shape Boundary Brake: 本 owner 新增 shader role / descriptor policy /
// compatibility / no-pipeline-state vocabulary，不把 no-draw-call readiness 包成
// receipt / record / emission。

// Pipeline state lifecycle intent 只表达 future lifecycle intent；
// 它不是 pipeline implementation，也不是 backend readiness wrapper。
struct CjguiInternalRendererPipelineStateLifecycleIntent {
    let noDrawCallReadiness: CjguiInternalRendererNoDrawCallReadiness
    let didPrepareRendererPipelineStateLifecycleIntent: Bool
    let shouldDeferRendererPipelineStateLifecycleIntent: Bool
    let shouldReportRendererPipelineStateLifecycleIntentBlocked: Bool
    let didPreserveRendererNoDrawCallReadiness: Bool
    let didDefineFuturePipelineStateLifecycleIntent: Bool
    let didDescribeShaderRoleFacts: Bool
    let didDescribeDescriptorPolicyFacts: Bool
    let didDescribeCompatibilityFacts: Bool
    let didKeepPipelineStateLifecycleIntentValueOnly: Bool
    let didAvoidPipelineObjectCreation: Bool
    let didAvoidShaderAssetResolution: Bool
    let didAvoidBackendPermission: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidRenderingPermission: Bool
    let didAvoidThinWrapper: Bool

    init(
        noDrawCallReadiness: CjguiInternalRendererNoDrawCallReadiness,
        didPrepareRendererPipelineStateLifecycleIntent: Bool,
        shouldDeferRendererPipelineStateLifecycleIntent: Bool,
        shouldReportRendererPipelineStateLifecycleIntentBlocked: Bool,
        didPreserveRendererNoDrawCallReadiness: Bool,
        didDefineFuturePipelineStateLifecycleIntent: Bool,
        didDescribeShaderRoleFacts: Bool,
        didDescribeDescriptorPolicyFacts: Bool,
        didDescribeCompatibilityFacts: Bool,
        didKeepPipelineStateLifecycleIntentValueOnly: Bool,
        didAvoidPipelineObjectCreation: Bool,
        didAvoidShaderAssetResolution: Bool,
        didAvoidBackendPermission: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidRenderingPermission: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noDrawCallReadiness = noDrawCallReadiness
        this.didPrepareRendererPipelineStateLifecycleIntent =
            didPrepareRendererPipelineStateLifecycleIntent
        this.shouldDeferRendererPipelineStateLifecycleIntent =
            shouldDeferRendererPipelineStateLifecycleIntent
        this.shouldReportRendererPipelineStateLifecycleIntentBlocked =
            shouldReportRendererPipelineStateLifecycleIntentBlocked
        this.didPreserveRendererNoDrawCallReadiness =
            didPreserveRendererNoDrawCallReadiness
        this.didDefineFuturePipelineStateLifecycleIntent =
            didDefineFuturePipelineStateLifecycleIntent
        this.didDescribeShaderRoleFacts = didDescribeShaderRoleFacts
        this.didDescribeDescriptorPolicyFacts = didDescribeDescriptorPolicyFacts
        this.didDescribeCompatibilityFacts = didDescribeCompatibilityFacts
        this.didKeepPipelineStateLifecycleIntentValueOnly =
            didKeepPipelineStateLifecycleIntentValueOnly
        this.didAvoidPipelineObjectCreation = didAvoidPipelineObjectCreation
        this.didAvoidShaderAssetResolution = didAvoidShaderAssetResolution
        this.didAvoidBackendPermission = didAvoidBackendPermission
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

// Shader function policy 只表达 shader role placeholder / future selection facts；
// 它不加载 shader library，不解析 function object，不创建 backend asset。
struct CjguiInternalRendererShaderFunctionPolicy {
    let lifecycleIntent: CjguiInternalRendererPipelineStateLifecycleIntent
    let didPrepareRendererShaderFunctionPolicy: Bool
    let shouldDeferRendererShaderFunctionPolicy: Bool
    let shouldReportRendererShaderFunctionPolicyBlocked: Bool
    let didPreserveRendererPipelineStateLifecycleIntent: Bool
    let didDefineFutureShaderFunctionPolicy: Bool
    let didDescribeShaderRolePlaceholder: Bool
    let didDescribeFutureShaderSelectionFacts: Bool
    let didDescribeShaderFailureFallback: Bool
    let didKeepShaderFunctionPolicyValueOnly: Bool
    let didAvoidShaderAssetResolution: Bool
    let didAvoidShaderFunctionObject: Bool
    let didAvoidBackendPermission: Bool
    let didAvoidRenderingPermission: Bool

    init(
        lifecycleIntent: CjguiInternalRendererPipelineStateLifecycleIntent,
        didPrepareRendererShaderFunctionPolicy: Bool,
        shouldDeferRendererShaderFunctionPolicy: Bool,
        shouldReportRendererShaderFunctionPolicyBlocked: Bool,
        didPreserveRendererPipelineStateLifecycleIntent: Bool,
        didDefineFutureShaderFunctionPolicy: Bool,
        didDescribeShaderRolePlaceholder: Bool,
        didDescribeFutureShaderSelectionFacts: Bool,
        didDescribeShaderFailureFallback: Bool,
        didKeepShaderFunctionPolicyValueOnly: Bool,
        didAvoidShaderAssetResolution: Bool,
        didAvoidShaderFunctionObject: Bool,
        didAvoidBackendPermission: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.lifecycleIntent = lifecycleIntent
        this.didPrepareRendererShaderFunctionPolicy =
            didPrepareRendererShaderFunctionPolicy
        this.shouldDeferRendererShaderFunctionPolicy =
            shouldDeferRendererShaderFunctionPolicy
        this.shouldReportRendererShaderFunctionPolicyBlocked =
            shouldReportRendererShaderFunctionPolicyBlocked
        this.didPreserveRendererPipelineStateLifecycleIntent =
            didPreserveRendererPipelineStateLifecycleIntent
        this.didDefineFutureShaderFunctionPolicy =
            didDefineFutureShaderFunctionPolicy
        this.didDescribeShaderRolePlaceholder =
            didDescribeShaderRolePlaceholder
        this.didDescribeFutureShaderSelectionFacts =
            didDescribeFutureShaderSelectionFacts
        this.didDescribeShaderFailureFallback =
            didDescribeShaderFailureFallback
        this.didKeepShaderFunctionPolicyValueOnly =
            didKeepShaderFunctionPolicyValueOnly
        this.didAvoidShaderAssetResolution = didAvoidShaderAssetResolution
        this.didAvoidShaderFunctionObject = didAvoidShaderFunctionObject
        this.didAvoidBackendPermission = didAvoidBackendPermission
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// Pipeline descriptor policy 只表达 vertex layout / color attachment / blend /
// depth-stencil placeholder facts；它不创建 platform descriptor。
struct CjguiInternalRendererPipelineDescriptorPolicy {
    let shaderFunctionPolicy: CjguiInternalRendererShaderFunctionPolicy
    let didPrepareRendererPipelineDescriptorPolicy: Bool
    let shouldDeferRendererPipelineDescriptorPolicy: Bool
    let shouldReportRendererPipelineDescriptorPolicyBlocked: Bool
    let didPreserveRendererShaderFunctionPolicy: Bool
    let didDefineFuturePipelineDescriptorPolicy: Bool
    let didDescribeVertexLayoutPlaceholder: Bool
    let didDescribeColorAttachmentFormatRelation: Bool
    let didDescribeBlendDepthStencilPlaceholders: Bool
    let didKeepPipelineDescriptorPolicyValueOnly: Bool
    let didAvoidDescriptorObjectCreation: Bool
    let didAvoidPlatformResourceReference: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidRenderingPermission: Bool

    init(
        shaderFunctionPolicy: CjguiInternalRendererShaderFunctionPolicy,
        didPrepareRendererPipelineDescriptorPolicy: Bool,
        shouldDeferRendererPipelineDescriptorPolicy: Bool,
        shouldReportRendererPipelineDescriptorPolicyBlocked: Bool,
        didPreserveRendererShaderFunctionPolicy: Bool,
        didDefineFuturePipelineDescriptorPolicy: Bool,
        didDescribeVertexLayoutPlaceholder: Bool,
        didDescribeColorAttachmentFormatRelation: Bool,
        didDescribeBlendDepthStencilPlaceholders: Bool,
        didKeepPipelineDescriptorPolicyValueOnly: Bool,
        didAvoidDescriptorObjectCreation: Bool,
        didAvoidPlatformResourceReference: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.shaderFunctionPolicy = shaderFunctionPolicy
        this.didPrepareRendererPipelineDescriptorPolicy =
            didPrepareRendererPipelineDescriptorPolicy
        this.shouldDeferRendererPipelineDescriptorPolicy =
            shouldDeferRendererPipelineDescriptorPolicy
        this.shouldReportRendererPipelineDescriptorPolicyBlocked =
            shouldReportRendererPipelineDescriptorPolicyBlocked
        this.didPreserveRendererShaderFunctionPolicy =
            didPreserveRendererShaderFunctionPolicy
        this.didDefineFuturePipelineDescriptorPolicy =
            didDefineFuturePipelineDescriptorPolicy
        this.didDescribeVertexLayoutPlaceholder =
            didDescribeVertexLayoutPlaceholder
        this.didDescribeColorAttachmentFormatRelation =
            didDescribeColorAttachmentFormatRelation
        this.didDescribeBlendDepthStencilPlaceholders =
            didDescribeBlendDepthStencilPlaceholders
        this.didKeepPipelineDescriptorPolicyValueOnly =
            didKeepPipelineDescriptorPolicyValueOnly
        this.didAvoidDescriptorObjectCreation = didAvoidDescriptorObjectCreation
        this.didAvoidPlatformResourceReference = didAvoidPlatformResourceReference
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// Pipeline compatibility guard 只表达 material key / render pass / encoder /
// draw call compatibility facts；它不编译、不缓存、不绑定 pipeline。
struct CjguiInternalRendererPipelineCompatibilityGuard {
    let descriptorPolicy: CjguiInternalRendererPipelineDescriptorPolicy
    let didPrepareRendererPipelineCompatibilityGuard: Bool
    let shouldDeferRendererPipelineCompatibilityGuard: Bool
    let shouldReportRendererPipelineCompatibilityGuardBlocked: Bool
    let didPreserveRendererPipelineDescriptorPolicy: Bool
    let didDefineFuturePipelineCompatibilityGuard: Bool
    let didDescribeMaterialKeyCompatibilityRelation: Bool
    let didDescribeRenderPassCompatibilityRelation: Bool
    let didDescribeEncoderDrawCallCompatibilityRelation: Bool
    let didDescribeFailureNoPipelineFallback: Bool
    let didKeepPipelineCompatibilityGuardValueOnly: Bool
    let didAvoidPipelineCompilation: Bool
    let didAvoidPipelineCacheMutation: Bool
    let didAvoidEncoderInvocation: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidRenderingPermission: Bool

    init(
        descriptorPolicy: CjguiInternalRendererPipelineDescriptorPolicy,
        didPrepareRendererPipelineCompatibilityGuard: Bool,
        shouldDeferRendererPipelineCompatibilityGuard: Bool,
        shouldReportRendererPipelineCompatibilityGuardBlocked: Bool,
        didPreserveRendererPipelineDescriptorPolicy: Bool,
        didDefineFuturePipelineCompatibilityGuard: Bool,
        didDescribeMaterialKeyCompatibilityRelation: Bool,
        didDescribeRenderPassCompatibilityRelation: Bool,
        didDescribeEncoderDrawCallCompatibilityRelation: Bool,
        didDescribeFailureNoPipelineFallback: Bool,
        didKeepPipelineCompatibilityGuardValueOnly: Bool,
        didAvoidPipelineCompilation: Bool,
        didAvoidPipelineCacheMutation: Bool,
        didAvoidEncoderInvocation: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.descriptorPolicy = descriptorPolicy
        this.didPrepareRendererPipelineCompatibilityGuard =
            didPrepareRendererPipelineCompatibilityGuard
        this.shouldDeferRendererPipelineCompatibilityGuard =
            shouldDeferRendererPipelineCompatibilityGuard
        this.shouldReportRendererPipelineCompatibilityGuardBlocked =
            shouldReportRendererPipelineCompatibilityGuardBlocked
        this.didPreserveRendererPipelineDescriptorPolicy =
            didPreserveRendererPipelineDescriptorPolicy
        this.didDefineFuturePipelineCompatibilityGuard =
            didDefineFuturePipelineCompatibilityGuard
        this.didDescribeMaterialKeyCompatibilityRelation =
            didDescribeMaterialKeyCompatibilityRelation
        this.didDescribeRenderPassCompatibilityRelation =
            didDescribeRenderPassCompatibilityRelation
        this.didDescribeEncoderDrawCallCompatibilityRelation =
            didDescribeEncoderDrawCallCompatibilityRelation
        this.didDescribeFailureNoPipelineFallback =
            didDescribeFailureNoPipelineFallback
        this.didKeepPipelineCompatibilityGuardValueOnly =
            didKeepPipelineCompatibilityGuardValueOnly
        this.didAvoidPipelineCompilation = didAvoidPipelineCompilation
        this.didAvoidPipelineCacheMutation = didAvoidPipelineCacheMutation
        this.didAvoidEncoderInvocation = didAvoidEncoderInvocation
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// No-pipeline-state readiness 是本 owner 的 endpoint；readiness 只表示 future
// pipeline state lifecycle boundary 可以继续评估，不代表 pipeline object、
// shader asset、descriptor、encoder invocation、resource binding、backend 或 render
// permission。
struct CjguiInternalRendererNoPipelineStateReadiness {
    let compatibilityGuard: CjguiInternalRendererPipelineCompatibilityGuard
    let isRendererNoPipelineStateReady: Bool
    let canFutureRendererPipelineStateBoundaryEvaluate: Bool
    let shouldDeferRendererNoPipelineStateReadiness: Bool
    let shouldReportRendererNoPipelineStateReadinessBlocked: Bool
    let didSealRendererNoPipelineStateReadiness: Bool
    let didPreserveRendererPipelineCompatibilityGuard: Bool
    let didKeepNoPipelineStateReadinessValueOnly: Bool
    let didConfirmNoPipelineStateObject: Bool
    let didConfirmNoShaderLibraryObject: Bool
    let didConfirmNoShaderFunctionObject: Bool
    let didConfirmNoPipelineDescriptorObject: Bool
    let didConfirmNoEncoderInvocation: Bool
    let didConfirmNoBufferBinding: Bool
    let didConfirmNoTextureBinding: Bool
    let didConfirmNoNativeResourceToken: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didAvoidBackendPermission: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidRenderingPermission: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        compatibilityGuard: CjguiInternalRendererPipelineCompatibilityGuard,
        isRendererNoPipelineStateReady: Bool,
        canFutureRendererPipelineStateBoundaryEvaluate: Bool,
        shouldDeferRendererNoPipelineStateReadiness: Bool,
        shouldReportRendererNoPipelineStateReadinessBlocked: Bool,
        didSealRendererNoPipelineStateReadiness: Bool,
        didPreserveRendererPipelineCompatibilityGuard: Bool,
        didKeepNoPipelineStateReadinessValueOnly: Bool,
        didConfirmNoPipelineStateObject: Bool,
        didConfirmNoShaderLibraryObject: Bool,
        didConfirmNoShaderFunctionObject: Bool,
        didConfirmNoPipelineDescriptorObject: Bool,
        didConfirmNoEncoderInvocation: Bool,
        didConfirmNoBufferBinding: Bool,
        didConfirmNoTextureBinding: Bool,
        didConfirmNoNativeResourceToken: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didAvoidBackendPermission: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidRenderingPermission: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.compatibilityGuard = compatibilityGuard
        this.isRendererNoPipelineStateReady = isRendererNoPipelineStateReady
        this.canFutureRendererPipelineStateBoundaryEvaluate =
            canFutureRendererPipelineStateBoundaryEvaluate
        this.shouldDeferRendererNoPipelineStateReadiness =
            shouldDeferRendererNoPipelineStateReadiness
        this.shouldReportRendererNoPipelineStateReadinessBlocked =
            shouldReportRendererNoPipelineStateReadinessBlocked
        this.didSealRendererNoPipelineStateReadiness =
            didSealRendererNoPipelineStateReadiness
        this.didPreserveRendererPipelineCompatibilityGuard =
            didPreserveRendererPipelineCompatibilityGuard
        this.didKeepNoPipelineStateReadinessValueOnly =
            didKeepNoPipelineStateReadinessValueOnly
        this.didConfirmNoPipelineStateObject = didConfirmNoPipelineStateObject
        this.didConfirmNoShaderLibraryObject = didConfirmNoShaderLibraryObject
        this.didConfirmNoShaderFunctionObject = didConfirmNoShaderFunctionObject
        this.didConfirmNoPipelineDescriptorObject =
            didConfirmNoPipelineDescriptorObject
        this.didConfirmNoEncoderInvocation = didConfirmNoEncoderInvocation
        this.didConfirmNoBufferBinding = didConfirmNoBufferBinding
        this.didConfirmNoTextureBinding = didConfirmNoTextureBinding
        this.didConfirmNoNativeResourceToken = didConfirmNoNativeResourceToken
        this.didConfirmNoPointerLikeResource = didConfirmNoPointerLikeResource
        this.didAvoidBackendPermission = didAvoidBackendPermission
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererPipelineStateLifecycleIntent(
    noDrawCallReadiness: CjguiInternalRendererNoDrawCallReadiness
): CjguiInternalRendererPipelineStateLifecycleIntent {
    let noDrawCallReady = noDrawCallReadiness.isRendererNoDrawCallReady &&
        noDrawCallReadiness.canFutureRendererDrawCallBoundaryEvaluate &&
        noDrawCallReadiness.didSealRendererNoDrawCallReadiness &&
        noDrawCallReadiness.didPreserveRendererDrawSequencingGuard &&
        noDrawCallReadiness.didKeepNoDrawCallReadinessValueOnly &&
        noDrawCallReadiness.didConfirmNoDrawCallExecuted &&
        noDrawCallReadiness.didConfirmNoEncoderCall &&
        noDrawCallReadiness.didConfirmNoPipelineOrResourceBinding &&
        noDrawCallReadiness.didConfirmNoBufferBinding &&
        noDrawCallReadiness.didConfirmNoGpuSubmission &&
        noDrawCallReadiness.didConfirmNoNativeResourceToken &&
        noDrawCallReadiness.didConfirmNoPointerLikeResource &&
        noDrawCallReadiness.didAvoidBackendPermission &&
        noDrawCallReadiness.didAvoidRendererStateWrite &&
        noDrawCallReadiness.didAvoidRenderingPermission &&
        noDrawCallReadiness.didAvoidThinWrapper &&
        noDrawCallReadiness.didStayFullRebuildOnly &&
        noDrawCallReadiness.shouldDeferRendererNoDrawCallReadiness == false &&
        noDrawCallReadiness.shouldReportRendererNoDrawCallReadinessBlocked == false
    let intentDeferred =
        noDrawCallReadiness.isRendererNoDrawCallReady == false &&
        noDrawCallReadiness.canFutureRendererDrawCallBoundaryEvaluate == false &&
        noDrawCallReadiness.shouldDeferRendererNoDrawCallReadiness &&
        noDrawCallReadiness.shouldReportRendererNoDrawCallReadinessBlocked == false
    let intentInconsistent = (
        noDrawCallReadiness.isRendererNoDrawCallReady &&
            (
                noDrawCallReadiness.canFutureRendererDrawCallBoundaryEvaluate == false ||
                noDrawCallReadiness.didSealRendererNoDrawCallReadiness == false ||
                noDrawCallReadiness.didPreserveRendererDrawSequencingGuard == false ||
                noDrawCallReadiness.didKeepNoDrawCallReadinessValueOnly == false ||
                noDrawCallReadiness.didConfirmNoDrawCallExecuted == false ||
                noDrawCallReadiness.didConfirmNoEncoderCall == false ||
                noDrawCallReadiness.didConfirmNoPipelineOrResourceBinding == false ||
                noDrawCallReadiness.didConfirmNoBufferBinding == false ||
                noDrawCallReadiness.didConfirmNoGpuSubmission == false ||
                noDrawCallReadiness.didConfirmNoNativeResourceToken == false ||
                noDrawCallReadiness.didConfirmNoPointerLikeResource == false ||
                noDrawCallReadiness.didAvoidBackendPermission == false ||
                noDrawCallReadiness.didAvoidRendererStateWrite == false ||
                noDrawCallReadiness.didAvoidRenderingPermission == false ||
                noDrawCallReadiness.didAvoidThinWrapper == false ||
                noDrawCallReadiness.didStayFullRebuildOnly == false ||
                noDrawCallReadiness.shouldDeferRendererNoDrawCallReadiness ||
                noDrawCallReadiness.shouldReportRendererNoDrawCallReadinessBlocked
            )
        ) ||
        (noDrawCallReadiness.canFutureRendererDrawCallBoundaryEvaluate &&
            noDrawCallReadiness.isRendererNoDrawCallReady == false) ||
        (noDrawCallReadiness.shouldDeferRendererNoDrawCallReadiness &&
            noDrawCallReadiness.shouldReportRendererNoDrawCallReadinessBlocked)

    // fail-closed：不能把 no-draw-call readiness 薄包成 pipeline state intent。
    if (
        noDrawCallReadiness.shouldReportRendererNoDrawCallReadinessBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererPipelineStateLifecycleIntent(
            noDrawCallReadiness,
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

    if (noDrawCallReady) {
        return CjguiInternalRendererPipelineStateLifecycleIntent(
            noDrawCallReadiness,
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

    if (intentDeferred) {
        return CjguiInternalRendererPipelineStateLifecycleIntent(
            noDrawCallReadiness,
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

    return CjguiInternalRendererPipelineStateLifecycleIntent(
        noDrawCallReadiness,
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

func cjguiInternalBuildRendererShaderFunctionPolicy(
    lifecycleIntent: CjguiInternalRendererPipelineStateLifecycleIntent
): CjguiInternalRendererShaderFunctionPolicy {
    let intentReady =
        lifecycleIntent.didPrepareRendererPipelineStateLifecycleIntent &&
        lifecycleIntent.didPreserveRendererNoDrawCallReadiness &&
        lifecycleIntent.didDefineFuturePipelineStateLifecycleIntent &&
        lifecycleIntent.didDescribeShaderRoleFacts &&
        lifecycleIntent.didDescribeDescriptorPolicyFacts &&
        lifecycleIntent.didDescribeCompatibilityFacts &&
        lifecycleIntent.didKeepPipelineStateLifecycleIntentValueOnly &&
        lifecycleIntent.didAvoidPipelineObjectCreation &&
        lifecycleIntent.didAvoidShaderAssetResolution &&
        lifecycleIntent.didAvoidBackendPermission &&
        lifecycleIntent.didAvoidRendererStateMutation &&
        lifecycleIntent.didAvoidRenderingPermission &&
        lifecycleIntent.didAvoidThinWrapper &&
        lifecycleIntent.shouldDeferRendererPipelineStateLifecycleIntent == false &&
        lifecycleIntent.shouldReportRendererPipelineStateLifecycleIntentBlocked == false
    let policyDeferred =
        lifecycleIntent.didPrepareRendererPipelineStateLifecycleIntent == false &&
        lifecycleIntent.shouldDeferRendererPipelineStateLifecycleIntent &&
        lifecycleIntent.shouldReportRendererPipelineStateLifecycleIntentBlocked == false
    let policyInconsistent = (
        lifecycleIntent.didPrepareRendererPipelineStateLifecycleIntent &&
            (
                lifecycleIntent.didPreserveRendererNoDrawCallReadiness == false ||
                lifecycleIntent.didDefineFuturePipelineStateLifecycleIntent == false ||
                lifecycleIntent.didDescribeShaderRoleFacts == false ||
                lifecycleIntent.didDescribeDescriptorPolicyFacts == false ||
                lifecycleIntent.didDescribeCompatibilityFacts == false ||
                lifecycleIntent.didKeepPipelineStateLifecycleIntentValueOnly == false ||
                lifecycleIntent.didAvoidPipelineObjectCreation == false ||
                lifecycleIntent.didAvoidShaderAssetResolution == false ||
                lifecycleIntent.didAvoidBackendPermission == false ||
                lifecycleIntent.didAvoidRendererStateMutation == false ||
                lifecycleIntent.didAvoidRenderingPermission == false ||
                lifecycleIntent.didAvoidThinWrapper == false ||
                lifecycleIntent.shouldDeferRendererPipelineStateLifecycleIntent ||
                lifecycleIntent.shouldReportRendererPipelineStateLifecycleIntentBlocked
            )
        ) ||
        (lifecycleIntent.didPreserveRendererNoDrawCallReadiness &&
            lifecycleIntent.didPrepareRendererPipelineStateLifecycleIntent == false) ||
        (lifecycleIntent.shouldDeferRendererPipelineStateLifecycleIntent &&
            lifecycleIntent.shouldReportRendererPipelineStateLifecycleIntentBlocked)

    // shader function policy 只记录 role / fallback facts；这里不加载 shader asset。
    if (
        lifecycleIntent.shouldReportRendererPipelineStateLifecycleIntentBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererShaderFunctionPolicy(
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
        return CjguiInternalRendererShaderFunctionPolicy(
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
        return CjguiInternalRendererShaderFunctionPolicy(
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

    return CjguiInternalRendererShaderFunctionPolicy(
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

func cjguiInternalBuildRendererPipelineDescriptorPolicy(
    shaderFunctionPolicy: CjguiInternalRendererShaderFunctionPolicy
): CjguiInternalRendererPipelineDescriptorPolicy {
    let policyReady = shaderFunctionPolicy.didPrepareRendererShaderFunctionPolicy &&
        shaderFunctionPolicy.didPreserveRendererPipelineStateLifecycleIntent &&
        shaderFunctionPolicy.didDefineFutureShaderFunctionPolicy &&
        shaderFunctionPolicy.didDescribeShaderRolePlaceholder &&
        shaderFunctionPolicy.didDescribeFutureShaderSelectionFacts &&
        shaderFunctionPolicy.didDescribeShaderFailureFallback &&
        shaderFunctionPolicy.didKeepShaderFunctionPolicyValueOnly &&
        shaderFunctionPolicy.didAvoidShaderAssetResolution &&
        shaderFunctionPolicy.didAvoidShaderFunctionObject &&
        shaderFunctionPolicy.didAvoidBackendPermission &&
        shaderFunctionPolicy.didAvoidRenderingPermission &&
        shaderFunctionPolicy.shouldDeferRendererShaderFunctionPolicy == false &&
        shaderFunctionPolicy.shouldReportRendererShaderFunctionPolicyBlocked == false
    let descriptorDeferred =
        shaderFunctionPolicy.didPrepareRendererShaderFunctionPolicy == false &&
        shaderFunctionPolicy.shouldDeferRendererShaderFunctionPolicy &&
        shaderFunctionPolicy.shouldReportRendererShaderFunctionPolicyBlocked == false
    let descriptorInconsistent = (
        shaderFunctionPolicy.didPrepareRendererShaderFunctionPolicy &&
            (
                shaderFunctionPolicy.didPreserveRendererPipelineStateLifecycleIntent == false ||
                shaderFunctionPolicy.didDefineFutureShaderFunctionPolicy == false ||
                shaderFunctionPolicy.didDescribeShaderRolePlaceholder == false ||
                shaderFunctionPolicy.didDescribeFutureShaderSelectionFacts == false ||
                shaderFunctionPolicy.didDescribeShaderFailureFallback == false ||
                shaderFunctionPolicy.didKeepShaderFunctionPolicyValueOnly == false ||
                shaderFunctionPolicy.didAvoidShaderAssetResolution == false ||
                shaderFunctionPolicy.didAvoidShaderFunctionObject == false ||
                shaderFunctionPolicy.didAvoidBackendPermission == false ||
                shaderFunctionPolicy.didAvoidRenderingPermission == false ||
                shaderFunctionPolicy.shouldDeferRendererShaderFunctionPolicy ||
                shaderFunctionPolicy.shouldReportRendererShaderFunctionPolicyBlocked
            )
        ) ||
        (shaderFunctionPolicy.didPreserveRendererPipelineStateLifecycleIntent &&
            shaderFunctionPolicy.didPrepareRendererShaderFunctionPolicy == false) ||
        (shaderFunctionPolicy.shouldDeferRendererShaderFunctionPolicy &&
            shaderFunctionPolicy.shouldReportRendererShaderFunctionPolicyBlocked)

    // descriptor policy 只记录 layout / attachment / blend-depth facts。
    if (
        shaderFunctionPolicy.shouldReportRendererShaderFunctionPolicyBlocked ||
        descriptorInconsistent
    ) {
        return CjguiInternalRendererPipelineDescriptorPolicy(
            shaderFunctionPolicy,
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
        return CjguiInternalRendererPipelineDescriptorPolicy(
            shaderFunctionPolicy,
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

    if (descriptorDeferred) {
        return CjguiInternalRendererPipelineDescriptorPolicy(
            shaderFunctionPolicy,
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

    return CjguiInternalRendererPipelineDescriptorPolicy(
        shaderFunctionPolicy,
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

func cjguiInternalBuildRendererPipelineCompatibilityGuard(
    descriptorPolicy: CjguiInternalRendererPipelineDescriptorPolicy
): CjguiInternalRendererPipelineCompatibilityGuard {
    let policyReady = descriptorPolicy.didPrepareRendererPipelineDescriptorPolicy &&
        descriptorPolicy.didPreserveRendererShaderFunctionPolicy &&
        descriptorPolicy.didDefineFuturePipelineDescriptorPolicy &&
        descriptorPolicy.didDescribeVertexLayoutPlaceholder &&
        descriptorPolicy.didDescribeColorAttachmentFormatRelation &&
        descriptorPolicy.didDescribeBlendDepthStencilPlaceholders &&
        descriptorPolicy.didKeepPipelineDescriptorPolicyValueOnly &&
        descriptorPolicy.didAvoidDescriptorObjectCreation &&
        descriptorPolicy.didAvoidPlatformResourceReference &&
        descriptorPolicy.didAvoidRendererStateMutation &&
        descriptorPolicy.didAvoidRenderingPermission &&
        descriptorPolicy.shouldDeferRendererPipelineDescriptorPolicy == false &&
        descriptorPolicy.shouldReportRendererPipelineDescriptorPolicyBlocked == false
    let guardDeferred =
        descriptorPolicy.didPrepareRendererPipelineDescriptorPolicy == false &&
        descriptorPolicy.shouldDeferRendererPipelineDescriptorPolicy &&
        descriptorPolicy.shouldReportRendererPipelineDescriptorPolicyBlocked == false
    let guardInconsistent = (
        descriptorPolicy.didPrepareRendererPipelineDescriptorPolicy &&
            (
                descriptorPolicy.didPreserveRendererShaderFunctionPolicy == false ||
                descriptorPolicy.didDefineFuturePipelineDescriptorPolicy == false ||
                descriptorPolicy.didDescribeVertexLayoutPlaceholder == false ||
                descriptorPolicy.didDescribeColorAttachmentFormatRelation == false ||
                descriptorPolicy.didDescribeBlendDepthStencilPlaceholders == false ||
                descriptorPolicy.didKeepPipelineDescriptorPolicyValueOnly == false ||
                descriptorPolicy.didAvoidDescriptorObjectCreation == false ||
                descriptorPolicy.didAvoidPlatformResourceReference == false ||
                descriptorPolicy.didAvoidRendererStateMutation == false ||
                descriptorPolicy.didAvoidRenderingPermission == false ||
                descriptorPolicy.shouldDeferRendererPipelineDescriptorPolicy ||
                descriptorPolicy.shouldReportRendererPipelineDescriptorPolicyBlocked
            )
        ) ||
        (descriptorPolicy.didPreserveRendererShaderFunctionPolicy &&
            descriptorPolicy.didPrepareRendererPipelineDescriptorPolicy == false) ||
        (descriptorPolicy.shouldDeferRendererPipelineDescriptorPolicy &&
            descriptorPolicy.shouldReportRendererPipelineDescriptorPolicyBlocked)

    // compatibility guard 只记录 relation facts；这里不 compile/cache/bind pipeline。
    if (
        descriptorPolicy.shouldReportRendererPipelineDescriptorPolicyBlocked ||
        guardInconsistent
    ) {
        return CjguiInternalRendererPipelineCompatibilityGuard(
            descriptorPolicy,
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
            true,
            true
        )
    }

    if (policyReady) {
        return CjguiInternalRendererPipelineCompatibilityGuard(
            descriptorPolicy,
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

    if (guardDeferred) {
        return CjguiInternalRendererPipelineCompatibilityGuard(
            descriptorPolicy,
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
            true,
            true
        )
    }

    return CjguiInternalRendererPipelineCompatibilityGuard(
        descriptorPolicy,
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
        true,
        true
    )
}

func cjguiInternalBuildRendererNoPipelineStateReadiness(
    compatibilityGuard: CjguiInternalRendererPipelineCompatibilityGuard
): CjguiInternalRendererNoPipelineStateReadiness {
    let guardReady = compatibilityGuard.didPrepareRendererPipelineCompatibilityGuard &&
        compatibilityGuard.didPreserveRendererPipelineDescriptorPolicy &&
        compatibilityGuard.didDefineFuturePipelineCompatibilityGuard &&
        compatibilityGuard.didDescribeMaterialKeyCompatibilityRelation &&
        compatibilityGuard.didDescribeRenderPassCompatibilityRelation &&
        compatibilityGuard.didDescribeEncoderDrawCallCompatibilityRelation &&
        compatibilityGuard.didDescribeFailureNoPipelineFallback &&
        compatibilityGuard.didKeepPipelineCompatibilityGuardValueOnly &&
        compatibilityGuard.didAvoidPipelineCompilation &&
        compatibilityGuard.didAvoidPipelineCacheMutation &&
        compatibilityGuard.didAvoidEncoderInvocation &&
        compatibilityGuard.didAvoidRendererStateMutation &&
        compatibilityGuard.didAvoidRenderingPermission &&
        compatibilityGuard.shouldDeferRendererPipelineCompatibilityGuard == false &&
        compatibilityGuard.shouldReportRendererPipelineCompatibilityGuardBlocked == false
    let readinessDeferred =
        compatibilityGuard.didPrepareRendererPipelineCompatibilityGuard == false &&
        compatibilityGuard.shouldDeferRendererPipelineCompatibilityGuard &&
        compatibilityGuard.shouldReportRendererPipelineCompatibilityGuardBlocked == false
    let readinessInconsistent = (
        compatibilityGuard.didPrepareRendererPipelineCompatibilityGuard &&
            (
                compatibilityGuard.didPreserveRendererPipelineDescriptorPolicy == false ||
                compatibilityGuard.didDefineFuturePipelineCompatibilityGuard == false ||
                compatibilityGuard.didDescribeMaterialKeyCompatibilityRelation == false ||
                compatibilityGuard.didDescribeRenderPassCompatibilityRelation == false ||
                compatibilityGuard.didDescribeEncoderDrawCallCompatibilityRelation == false ||
                compatibilityGuard.didDescribeFailureNoPipelineFallback == false ||
                compatibilityGuard.didKeepPipelineCompatibilityGuardValueOnly == false ||
                compatibilityGuard.didAvoidPipelineCompilation == false ||
                compatibilityGuard.didAvoidPipelineCacheMutation == false ||
                compatibilityGuard.didAvoidEncoderInvocation == false ||
                compatibilityGuard.didAvoidRendererStateMutation == false ||
                compatibilityGuard.didAvoidRenderingPermission == false ||
                compatibilityGuard.shouldDeferRendererPipelineCompatibilityGuard ||
                compatibilityGuard.shouldReportRendererPipelineCompatibilityGuardBlocked
            )
        ) ||
        (compatibilityGuard.didPreserveRendererPipelineDescriptorPolicy &&
            compatibilityGuard.didPrepareRendererPipelineCompatibilityGuard == false) ||
        (compatibilityGuard.shouldDeferRendererPipelineCompatibilityGuard &&
            compatibilityGuard.shouldReportRendererPipelineCompatibilityGuardBlocked)

    // no-pipeline-state readiness 只封口 value facts；这里不生成 receipt / record。
    if (
        compatibilityGuard.shouldReportRendererPipelineCompatibilityGuardBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoPipelineStateReadiness(
            compatibilityGuard,
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
            true
        )
    }

    if (guardReady) {
        return CjguiInternalRendererNoPipelineStateReadiness(
            compatibilityGuard,
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
            true
        )
    }

    if (readinessDeferred) {
        return CjguiInternalRendererNoPipelineStateReadiness(
            compatibilityGuard,
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
            true
        )
    }

    return CjguiInternalRendererNoPipelineStateReadiness(
        compatibilityGuard,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererPipelineStateLifecycleDraft(
): CjguiInternalRendererNoPipelineStateReadiness {
    let noDrawCallReadiness =
        cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft()
    let lifecycleIntent =
        cjguiInternalBuildRendererPipelineStateLifecycleIntent(
            noDrawCallReadiness
        )
    let shaderFunctionPolicy =
        cjguiInternalBuildRendererShaderFunctionPolicy(lifecycleIntent)
    let descriptorPolicy =
        cjguiInternalBuildRendererPipelineDescriptorPolicy(shaderFunctionPolicy)
    let compatibilityGuard =
        cjguiInternalBuildRendererPipelineCompatibilityGuard(descriptorPolicy)
    return cjguiInternalBuildRendererNoPipelineStateReadiness(compatibilityGuard)
}
