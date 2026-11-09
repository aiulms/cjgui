package cjgui

// Owner: Renderer draw call lifecycle value boundary.
// Truth: 只消费 CjguiInternalRendererNoEncoderReadiness，表达 future draw call
// lifecycle intent、draw command shape policy、geometry source policy、draw sequencing
// guard 与 no-draw-call readiness 的内部 value facts。
// Stop-line: 这里不执行 draw call，不调用 MTLRenderCommandEncoder，不绑定 pipeline
// state / vertex buffer / index buffer / texture，不提交 GPU work，不接后端，不触发
// render execution，不写 renderer state，不持有 native handle 或 raw pointer。
// Same-shape Boundary Brake: 本 owner 新增 draw command shape / geometry source /
// sequencing / no-draw-call vocabulary，不把 no-encoder readiness 包成 receipt / record /
// emission。

// Draw call lifecycle intent 只表达 future lifecycle intent；
// 它不是 executable draw call owner，也不是 backend readiness wrapper。
struct CjguiInternalRendererDrawCallLifecycleIntent {
    let noEncoderReadiness: CjguiInternalRendererNoEncoderReadiness
    let didPrepareRendererDrawCallLifecycleIntent: Bool
    let shouldDeferRendererDrawCallLifecycleIntent: Bool
    let shouldReportRendererDrawCallLifecycleIntentBlocked: Bool
    let didPreserveRendererNoEncoderReadiness: Bool
    let didDefineFutureDrawCallLifecycleIntent: Bool
    let didDescribeDrawCommandShapeFacts: Bool
    let didDescribeEncoderMaterialRelation: Bool
    let didKeepDrawCallLifecycleIntentValueOnly: Bool
    let didAvoidDrawCallExecution: Bool
    let didAvoidEncoderCall: Bool
    let didAvoidBackendPermission: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool
    let didAvoidThinWrapper: Bool

    init(
        noEncoderReadiness: CjguiInternalRendererNoEncoderReadiness,
        didPrepareRendererDrawCallLifecycleIntent: Bool,
        shouldDeferRendererDrawCallLifecycleIntent: Bool,
        shouldReportRendererDrawCallLifecycleIntentBlocked: Bool,
        didPreserveRendererNoEncoderReadiness: Bool,
        didDefineFutureDrawCallLifecycleIntent: Bool,
        didDescribeDrawCommandShapeFacts: Bool,
        didDescribeEncoderMaterialRelation: Bool,
        didKeepDrawCallLifecycleIntentValueOnly: Bool,
        didAvoidDrawCallExecution: Bool,
        didAvoidEncoderCall: Bool,
        didAvoidBackendPermission: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noEncoderReadiness = noEncoderReadiness
        this.didPrepareRendererDrawCallLifecycleIntent =
            didPrepareRendererDrawCallLifecycleIntent
        this.shouldDeferRendererDrawCallLifecycleIntent =
            shouldDeferRendererDrawCallLifecycleIntent
        this.shouldReportRendererDrawCallLifecycleIntentBlocked =
            shouldReportRendererDrawCallLifecycleIntentBlocked
        this.didPreserveRendererNoEncoderReadiness =
            didPreserveRendererNoEncoderReadiness
        this.didDefineFutureDrawCallLifecycleIntent =
            didDefineFutureDrawCallLifecycleIntent
        this.didDescribeDrawCommandShapeFacts = didDescribeDrawCommandShapeFacts
        this.didDescribeEncoderMaterialRelation =
            didDescribeEncoderMaterialRelation
        this.didKeepDrawCallLifecycleIntentValueOnly =
            didKeepDrawCallLifecycleIntentValueOnly
        this.didAvoidDrawCallExecution = didAvoidDrawCallExecution
        this.didAvoidEncoderCall = didAvoidEncoderCall
        this.didAvoidBackendPermission = didAvoidBackendPermission
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

// Draw command shape policy 只表达 primitive kind / instance count placeholder facts；
// 它不发 draw command，不绑定 pipeline，也不改 command packet。
struct CjguiInternalRendererDrawCommandShapePolicy {
    let lifecycleIntent: CjguiInternalRendererDrawCallLifecycleIntent
    let didPrepareRendererDrawCommandShapePolicy: Bool
    let shouldDeferRendererDrawCommandShapePolicy: Bool
    let shouldReportRendererDrawCommandShapePolicyBlocked: Bool
    let didPreserveRendererDrawCallLifecycleIntent: Bool
    let didDefineFutureDrawCommandShapePolicy: Bool
    let didDescribePrimitiveKindPlaceholder: Bool
    let didDescribeInstanceCountPlaceholder: Bool
    let didDescribeRenderCommandPacketRelation: Bool
    let didKeepDrawCommandShapePolicyValueOnly: Bool
    let didAvoidDrawCommandEmission: Bool
    let didAvoidPipelineBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool

    init(
        lifecycleIntent: CjguiInternalRendererDrawCallLifecycleIntent,
        didPrepareRendererDrawCommandShapePolicy: Bool,
        shouldDeferRendererDrawCommandShapePolicy: Bool,
        shouldReportRendererDrawCommandShapePolicyBlocked: Bool,
        didPreserveRendererDrawCallLifecycleIntent: Bool,
        didDefineFutureDrawCommandShapePolicy: Bool,
        didDescribePrimitiveKindPlaceholder: Bool,
        didDescribeInstanceCountPlaceholder: Bool,
        didDescribeRenderCommandPacketRelation: Bool,
        didKeepDrawCommandShapePolicyValueOnly: Bool,
        didAvoidDrawCommandEmission: Bool,
        didAvoidPipelineBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.lifecycleIntent = lifecycleIntent
        this.didPrepareRendererDrawCommandShapePolicy =
            didPrepareRendererDrawCommandShapePolicy
        this.shouldDeferRendererDrawCommandShapePolicy =
            shouldDeferRendererDrawCommandShapePolicy
        this.shouldReportRendererDrawCommandShapePolicyBlocked =
            shouldReportRendererDrawCommandShapePolicyBlocked
        this.didPreserveRendererDrawCallLifecycleIntent =
            didPreserveRendererDrawCallLifecycleIntent
        this.didDefineFutureDrawCommandShapePolicy =
            didDefineFutureDrawCommandShapePolicy
        this.didDescribePrimitiveKindPlaceholder =
            didDescribePrimitiveKindPlaceholder
        this.didDescribeInstanceCountPlaceholder =
            didDescribeInstanceCountPlaceholder
        this.didDescribeRenderCommandPacketRelation =
            didDescribeRenderCommandPacketRelation
        this.didKeepDrawCommandShapePolicyValueOnly =
            didKeepDrawCommandShapePolicyValueOnly
        this.didAvoidDrawCommandEmission = didAvoidDrawCommandEmission
        this.didAvoidPipelineBinding = didAvoidPipelineBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// Geometry source policy 只表达 future vertex / index source policy；
// 它不绑定 buffer，不持有 platform resource，也不创建 resource view。
struct CjguiInternalRendererGeometrySourcePolicy {
    let shapePolicy: CjguiInternalRendererDrawCommandShapePolicy
    let didPrepareRendererGeometrySourcePolicy: Bool
    let shouldDeferRendererGeometrySourcePolicy: Bool
    let shouldReportRendererGeometrySourcePolicyBlocked: Bool
    let didPreserveRendererDrawCommandShapePolicy: Bool
    let didDefineFutureGeometrySourcePolicy: Bool
    let didDescribeVertexSourcePolicyFacts: Bool
    let didDescribeIndexSourcePolicyFacts: Bool
    let didDescribeGeometryFallbackFacts: Bool
    let didKeepGeometrySourcePolicyValueOnly: Bool
    let didAvoidBufferBinding: Bool
    let didAvoidPlatformResourceReference: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool

    init(
        shapePolicy: CjguiInternalRendererDrawCommandShapePolicy,
        didPrepareRendererGeometrySourcePolicy: Bool,
        shouldDeferRendererGeometrySourcePolicy: Bool,
        shouldReportRendererGeometrySourcePolicyBlocked: Bool,
        didPreserveRendererDrawCommandShapePolicy: Bool,
        didDefineFutureGeometrySourcePolicy: Bool,
        didDescribeVertexSourcePolicyFacts: Bool,
        didDescribeIndexSourcePolicyFacts: Bool,
        didDescribeGeometryFallbackFacts: Bool,
        didKeepGeometrySourcePolicyValueOnly: Bool,
        didAvoidBufferBinding: Bool,
        didAvoidPlatformResourceReference: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.shapePolicy = shapePolicy
        this.didPrepareRendererGeometrySourcePolicy =
            didPrepareRendererGeometrySourcePolicy
        this.shouldDeferRendererGeometrySourcePolicy =
            shouldDeferRendererGeometrySourcePolicy
        this.shouldReportRendererGeometrySourcePolicyBlocked =
            shouldReportRendererGeometrySourcePolicyBlocked
        this.didPreserveRendererDrawCommandShapePolicy =
            didPreserveRendererDrawCommandShapePolicy
        this.didDefineFutureGeometrySourcePolicy =
            didDefineFutureGeometrySourcePolicy
        this.didDescribeVertexSourcePolicyFacts =
            didDescribeVertexSourcePolicyFacts
        this.didDescribeIndexSourcePolicyFacts = didDescribeIndexSourcePolicyFacts
        this.didDescribeGeometryFallbackFacts = didDescribeGeometryFallbackFacts
        this.didKeepGeometrySourcePolicyValueOnly =
            didKeepGeometrySourcePolicyValueOnly
        this.didAvoidBufferBinding = didAvoidBufferBinding
        this.didAvoidPlatformResourceReference = didAvoidPlatformResourceReference
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// Draw sequencing guard 只表达 draw order relation / material grouping hints；
// 它不排序、不提交、不执行，不把 material hints 变成 GPU batching。
struct CjguiInternalRendererDrawSequencingGuard {
    let geometrySourcePolicy: CjguiInternalRendererGeometrySourcePolicy
    let didPrepareRendererDrawSequencingGuard: Bool
    let shouldDeferRendererDrawSequencingGuard: Bool
    let shouldReportRendererDrawSequencingGuardBlocked: Bool
    let didPreserveRendererGeometrySourcePolicy: Bool
    let didDefineFutureDrawSequencingGuard: Bool
    let didDescribeDrawOrderRelation: Bool
    let didDescribeMaterialGroupingHintRelation: Bool
    let didDescribeFailureNoDrawFallback: Bool
    let didKeepDrawSequencingGuardValueOnly: Bool
    let didAvoidSortingSideEffect: Bool
    let didAvoidGpuSubmission: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool

    init(
        geometrySourcePolicy: CjguiInternalRendererGeometrySourcePolicy,
        didPrepareRendererDrawSequencingGuard: Bool,
        shouldDeferRendererDrawSequencingGuard: Bool,
        shouldReportRendererDrawSequencingGuardBlocked: Bool,
        didPreserveRendererGeometrySourcePolicy: Bool,
        didDefineFutureDrawSequencingGuard: Bool,
        didDescribeDrawOrderRelation: Bool,
        didDescribeMaterialGroupingHintRelation: Bool,
        didDescribeFailureNoDrawFallback: Bool,
        didKeepDrawSequencingGuardValueOnly: Bool,
        didAvoidSortingSideEffect: Bool,
        didAvoidGpuSubmission: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.geometrySourcePolicy = geometrySourcePolicy
        this.didPrepareRendererDrawSequencingGuard =
            didPrepareRendererDrawSequencingGuard
        this.shouldDeferRendererDrawSequencingGuard =
            shouldDeferRendererDrawSequencingGuard
        this.shouldReportRendererDrawSequencingGuardBlocked =
            shouldReportRendererDrawSequencingGuardBlocked
        this.didPreserveRendererGeometrySourcePolicy =
            didPreserveRendererGeometrySourcePolicy
        this.didDefineFutureDrawSequencingGuard =
            didDefineFutureDrawSequencingGuard
        this.didDescribeDrawOrderRelation = didDescribeDrawOrderRelation
        this.didDescribeMaterialGroupingHintRelation =
            didDescribeMaterialGroupingHintRelation
        this.didDescribeFailureNoDrawFallback = didDescribeFailureNoDrawFallback
        this.didKeepDrawSequencingGuardValueOnly =
            didKeepDrawSequencingGuardValueOnly
        this.didAvoidSortingSideEffect = didAvoidSortingSideEffect
        this.didAvoidGpuSubmission = didAvoidGpuSubmission
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// No-draw-call readiness 是本 owner 的 endpoint；readiness 只表示 future draw call
// lifecycle boundary 可以继续评估，不代表 draw call、encoder call、pipeline binding、
// buffer binding、texture binding、GPU submission、native handle / raw pointer、
// backend 或 render permission。
struct CjguiInternalRendererNoDrawCallReadiness {
    let sequencingGuard: CjguiInternalRendererDrawSequencingGuard
    let isRendererNoDrawCallReady: Bool
    let canFutureRendererDrawCallBoundaryEvaluate: Bool
    let shouldDeferRendererNoDrawCallReadiness: Bool
    let shouldReportRendererNoDrawCallReadinessBlocked: Bool
    let didSealRendererNoDrawCallReadiness: Bool
    let didPreserveRendererDrawSequencingGuard: Bool
    let didKeepNoDrawCallReadinessValueOnly: Bool
    let didConfirmNoDrawCallExecuted: Bool
    let didConfirmNoEncoderCall: Bool
    let didConfirmNoPipelineOrResourceBinding: Bool
    let didConfirmNoBufferBinding: Bool
    let didConfirmNoGpuSubmission: Bool
    let didConfirmNoNativeResourceToken: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didAvoidBackendPermission: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        sequencingGuard: CjguiInternalRendererDrawSequencingGuard,
        isRendererNoDrawCallReady: Bool,
        canFutureRendererDrawCallBoundaryEvaluate: Bool,
        shouldDeferRendererNoDrawCallReadiness: Bool,
        shouldReportRendererNoDrawCallReadinessBlocked: Bool,
        didSealRendererNoDrawCallReadiness: Bool,
        didPreserveRendererDrawSequencingGuard: Bool,
        didKeepNoDrawCallReadinessValueOnly: Bool,
        didConfirmNoDrawCallExecuted: Bool,
        didConfirmNoEncoderCall: Bool,
        didConfirmNoPipelineOrResourceBinding: Bool,
        didConfirmNoBufferBinding: Bool,
        didConfirmNoGpuSubmission: Bool,
        didConfirmNoNativeResourceToken: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didAvoidBackendPermission: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.sequencingGuard = sequencingGuard
        this.isRendererNoDrawCallReady = isRendererNoDrawCallReady
        this.canFutureRendererDrawCallBoundaryEvaluate =
            canFutureRendererDrawCallBoundaryEvaluate
        this.shouldDeferRendererNoDrawCallReadiness =
            shouldDeferRendererNoDrawCallReadiness
        this.shouldReportRendererNoDrawCallReadinessBlocked =
            shouldReportRendererNoDrawCallReadinessBlocked
        this.didSealRendererNoDrawCallReadiness = didSealRendererNoDrawCallReadiness
        this.didPreserveRendererDrawSequencingGuard =
            didPreserveRendererDrawSequencingGuard
        this.didKeepNoDrawCallReadinessValueOnly =
            didKeepNoDrawCallReadinessValueOnly
        this.didConfirmNoDrawCallExecuted = didConfirmNoDrawCallExecuted
        this.didConfirmNoEncoderCall = didConfirmNoEncoderCall
        this.didConfirmNoPipelineOrResourceBinding =
            didConfirmNoPipelineOrResourceBinding
        this.didConfirmNoBufferBinding = didConfirmNoBufferBinding
        this.didConfirmNoGpuSubmission = didConfirmNoGpuSubmission
        this.didConfirmNoNativeResourceToken = didConfirmNoNativeResourceToken
        this.didConfirmNoPointerLikeResource = didConfirmNoPointerLikeResource
        this.didAvoidBackendPermission = didAvoidBackendPermission
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererDrawCallLifecycleIntent(
    noEncoderReadiness: CjguiInternalRendererNoEncoderReadiness
): CjguiInternalRendererDrawCallLifecycleIntent {
    let noEncoderReady = noEncoderReadiness.isRendererNoEncoderReady &&
        noEncoderReadiness.canFutureRendererEncoderBoundaryEvaluate &&
        noEncoderReadiness.didSealRendererNoEncoderReadiness &&
        noEncoderReadiness.didPreserveRendererEndEncodingPolicy &&
        noEncoderReadiness.didKeepNoEncoderReadinessValueOnly &&
        noEncoderReadiness.didConfirmNoEncoderCreated &&
        noEncoderReadiness.didConfirmNoPipelineStateObject &&
        noEncoderReadiness.didConfirmNoDrawCommandIssued &&
        noEncoderReadiness.didConfirmNoRenderPassDescriptorObject &&
        noEncoderReadiness.didConfirmNoCommandBufferObject &&
        noEncoderReadiness.didConfirmNoNativeResourceToken &&
        noEncoderReadiness.didConfirmNoPointerLikeResource &&
        noEncoderReadiness.didAvoidBackendPermission &&
        noEncoderReadiness.didAvoidRendererStateMutation &&
        noEncoderReadiness.didAvoidRenderingPermission &&
        noEncoderReadiness.didAvoidThinWrapper &&
        noEncoderReadiness.didStayFullRebuildOnly &&
        noEncoderReadiness.shouldDeferRendererNoEncoderReadiness == false &&
        noEncoderReadiness.shouldReportRendererNoEncoderReadinessBlocked == false
    let intentDeferred = noEncoderReadiness.isRendererNoEncoderReady == false &&
        noEncoderReadiness.canFutureRendererEncoderBoundaryEvaluate == false &&
        noEncoderReadiness.shouldDeferRendererNoEncoderReadiness &&
        noEncoderReadiness.shouldReportRendererNoEncoderReadinessBlocked == false
    let intentInconsistent = (
        noEncoderReadiness.isRendererNoEncoderReady &&
            (
                noEncoderReadiness.canFutureRendererEncoderBoundaryEvaluate == false ||
                noEncoderReadiness.didSealRendererNoEncoderReadiness == false ||
                noEncoderReadiness.didPreserveRendererEndEncodingPolicy == false ||
                noEncoderReadiness.didKeepNoEncoderReadinessValueOnly == false ||
                noEncoderReadiness.didConfirmNoEncoderCreated == false ||
                noEncoderReadiness.didConfirmNoPipelineStateObject == false ||
                noEncoderReadiness.didConfirmNoDrawCommandIssued == false ||
                noEncoderReadiness.didConfirmNoRenderPassDescriptorObject == false ||
                noEncoderReadiness.didConfirmNoCommandBufferObject == false ||
                noEncoderReadiness.didConfirmNoNativeResourceToken == false ||
                noEncoderReadiness.didConfirmNoPointerLikeResource == false ||
                noEncoderReadiness.didAvoidBackendPermission == false ||
                noEncoderReadiness.didAvoidRendererStateMutation == false ||
                noEncoderReadiness.didAvoidRenderingPermission == false ||
                noEncoderReadiness.didAvoidThinWrapper == false ||
                noEncoderReadiness.didStayFullRebuildOnly == false ||
                noEncoderReadiness.shouldDeferRendererNoEncoderReadiness ||
                noEncoderReadiness.shouldReportRendererNoEncoderReadinessBlocked
            )
        ) ||
        (noEncoderReadiness.canFutureRendererEncoderBoundaryEvaluate &&
            noEncoderReadiness.isRendererNoEncoderReady == false) ||
        (noEncoderReadiness.shouldDeferRendererNoEncoderReadiness &&
            noEncoderReadiness.shouldReportRendererNoEncoderReadinessBlocked)

    // fail-closed：不能把 no-encoder readiness 薄包成 draw call lifecycle intent。
    if (
        noEncoderReadiness.shouldReportRendererNoEncoderReadinessBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererDrawCallLifecycleIntent(
            noEncoderReadiness,
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

    if (noEncoderReady) {
        return CjguiInternalRendererDrawCallLifecycleIntent(
            noEncoderReadiness,
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
        return CjguiInternalRendererDrawCallLifecycleIntent(
            noEncoderReadiness,
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

    return CjguiInternalRendererDrawCallLifecycleIntent(
        noEncoderReadiness,
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

func cjguiInternalBuildRendererDrawCommandShapePolicy(
    lifecycleIntent: CjguiInternalRendererDrawCallLifecycleIntent
): CjguiInternalRendererDrawCommandShapePolicy {
    let intentReady = lifecycleIntent.didPrepareRendererDrawCallLifecycleIntent &&
        lifecycleIntent.didPreserveRendererNoEncoderReadiness &&
        lifecycleIntent.didDefineFutureDrawCallLifecycleIntent &&
        lifecycleIntent.didDescribeDrawCommandShapeFacts &&
        lifecycleIntent.didDescribeEncoderMaterialRelation &&
        lifecycleIntent.didKeepDrawCallLifecycleIntentValueOnly &&
        lifecycleIntent.didAvoidDrawCallExecution &&
        lifecycleIntent.didAvoidEncoderCall &&
        lifecycleIntent.didAvoidBackendPermission &&
        lifecycleIntent.didAvoidRendererStateWrite &&
        lifecycleIntent.didAvoidRenderingPermission &&
        lifecycleIntent.didAvoidThinWrapper &&
        lifecycleIntent.shouldDeferRendererDrawCallLifecycleIntent == false &&
        lifecycleIntent.shouldReportRendererDrawCallLifecycleIntentBlocked == false
    let policyDeferred =
        lifecycleIntent.didPrepareRendererDrawCallLifecycleIntent == false &&
        lifecycleIntent.shouldDeferRendererDrawCallLifecycleIntent &&
        lifecycleIntent.shouldReportRendererDrawCallLifecycleIntentBlocked == false
    let policyInconsistent = (
        lifecycleIntent.didPrepareRendererDrawCallLifecycleIntent &&
            (
                lifecycleIntent.didPreserveRendererNoEncoderReadiness == false ||
                lifecycleIntent.didDefineFutureDrawCallLifecycleIntent == false ||
                lifecycleIntent.didDescribeDrawCommandShapeFacts == false ||
                lifecycleIntent.didDescribeEncoderMaterialRelation == false ||
                lifecycleIntent.didKeepDrawCallLifecycleIntentValueOnly == false ||
                lifecycleIntent.didAvoidDrawCallExecution == false ||
                lifecycleIntent.didAvoidEncoderCall == false ||
                lifecycleIntent.didAvoidBackendPermission == false ||
                lifecycleIntent.didAvoidRendererStateWrite == false ||
                lifecycleIntent.didAvoidRenderingPermission == false ||
                lifecycleIntent.didAvoidThinWrapper == false ||
                lifecycleIntent.shouldDeferRendererDrawCallLifecycleIntent ||
                lifecycleIntent.shouldReportRendererDrawCallLifecycleIntentBlocked
            )
        ) ||
        (lifecycleIntent.didPreserveRendererNoEncoderReadiness &&
            lifecycleIntent.didPrepareRendererDrawCallLifecycleIntent == false) ||
        (lifecycleIntent.shouldDeferRendererDrawCallLifecycleIntent &&
            lifecycleIntent.shouldReportRendererDrawCallLifecycleIntentBlocked)

    // draw command shape policy 只表达 primitive / instance facts；这里不发 command。
    if (
        lifecycleIntent.shouldReportRendererDrawCallLifecycleIntentBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererDrawCommandShapePolicy(
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
        return CjguiInternalRendererDrawCommandShapePolicy(
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
        return CjguiInternalRendererDrawCommandShapePolicy(
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

    return CjguiInternalRendererDrawCommandShapePolicy(
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

func cjguiInternalBuildRendererGeometrySourcePolicy(
    shapePolicy: CjguiInternalRendererDrawCommandShapePolicy
): CjguiInternalRendererGeometrySourcePolicy {
    let policyReady = shapePolicy.didPrepareRendererDrawCommandShapePolicy &&
        shapePolicy.didPreserveRendererDrawCallLifecycleIntent &&
        shapePolicy.didDefineFutureDrawCommandShapePolicy &&
        shapePolicy.didDescribePrimitiveKindPlaceholder &&
        shapePolicy.didDescribeInstanceCountPlaceholder &&
        shapePolicy.didDescribeRenderCommandPacketRelation &&
        shapePolicy.didKeepDrawCommandShapePolicyValueOnly &&
        shapePolicy.didAvoidDrawCommandEmission &&
        shapePolicy.didAvoidPipelineBinding &&
        shapePolicy.didAvoidRendererStateWrite &&
        shapePolicy.didAvoidRenderingPermission &&
        shapePolicy.shouldDeferRendererDrawCommandShapePolicy == false &&
        shapePolicy.shouldReportRendererDrawCommandShapePolicyBlocked == false
    let geometryDeferred =
        shapePolicy.didPrepareRendererDrawCommandShapePolicy == false &&
        shapePolicy.shouldDeferRendererDrawCommandShapePolicy &&
        shapePolicy.shouldReportRendererDrawCommandShapePolicyBlocked == false
    let geometryInconsistent = (
        shapePolicy.didPrepareRendererDrawCommandShapePolicy &&
            (
                shapePolicy.didPreserveRendererDrawCallLifecycleIntent == false ||
                shapePolicy.didDefineFutureDrawCommandShapePolicy == false ||
                shapePolicy.didDescribePrimitiveKindPlaceholder == false ||
                shapePolicy.didDescribeInstanceCountPlaceholder == false ||
                shapePolicy.didDescribeRenderCommandPacketRelation == false ||
                shapePolicy.didKeepDrawCommandShapePolicyValueOnly == false ||
                shapePolicy.didAvoidDrawCommandEmission == false ||
                shapePolicy.didAvoidPipelineBinding == false ||
                shapePolicy.didAvoidRendererStateWrite == false ||
                shapePolicy.didAvoidRenderingPermission == false ||
                shapePolicy.shouldDeferRendererDrawCommandShapePolicy ||
                shapePolicy.shouldReportRendererDrawCommandShapePolicyBlocked
            )
        ) ||
        (shapePolicy.didPreserveRendererDrawCallLifecycleIntent &&
            shapePolicy.didPrepareRendererDrawCommandShapePolicy == false) ||
        (shapePolicy.shouldDeferRendererDrawCommandShapePolicy &&
            shapePolicy.shouldReportRendererDrawCommandShapePolicyBlocked)

    // geometry source policy 只描述 source facts；这里不绑定 buffer。
    if (
        shapePolicy.shouldReportRendererDrawCommandShapePolicyBlocked ||
        geometryInconsistent
    ) {
        return CjguiInternalRendererGeometrySourcePolicy(
            shapePolicy,
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
        return CjguiInternalRendererGeometrySourcePolicy(
            shapePolicy,
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

    if (geometryDeferred) {
        return CjguiInternalRendererGeometrySourcePolicy(
            shapePolicy,
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

    return CjguiInternalRendererGeometrySourcePolicy(
        shapePolicy,
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

func cjguiInternalBuildRendererDrawSequencingGuard(
    geometrySourcePolicy: CjguiInternalRendererGeometrySourcePolicy
): CjguiInternalRendererDrawSequencingGuard {
    let policyReady = geometrySourcePolicy.didPrepareRendererGeometrySourcePolicy &&
        geometrySourcePolicy.didPreserveRendererDrawCommandShapePolicy &&
        geometrySourcePolicy.didDefineFutureGeometrySourcePolicy &&
        geometrySourcePolicy.didDescribeVertexSourcePolicyFacts &&
        geometrySourcePolicy.didDescribeIndexSourcePolicyFacts &&
        geometrySourcePolicy.didDescribeGeometryFallbackFacts &&
        geometrySourcePolicy.didKeepGeometrySourcePolicyValueOnly &&
        geometrySourcePolicy.didAvoidBufferBinding &&
        geometrySourcePolicy.didAvoidPlatformResourceReference &&
        geometrySourcePolicy.didAvoidRendererStateWrite &&
        geometrySourcePolicy.didAvoidRenderingPermission &&
        geometrySourcePolicy.shouldDeferRendererGeometrySourcePolicy == false &&
        geometrySourcePolicy.shouldReportRendererGeometrySourcePolicyBlocked == false
    let guardDeferred =
        geometrySourcePolicy.didPrepareRendererGeometrySourcePolicy == false &&
        geometrySourcePolicy.shouldDeferRendererGeometrySourcePolicy &&
        geometrySourcePolicy.shouldReportRendererGeometrySourcePolicyBlocked == false
    let guardInconsistent = (
        geometrySourcePolicy.didPrepareRendererGeometrySourcePolicy &&
            (
                geometrySourcePolicy.didPreserveRendererDrawCommandShapePolicy == false ||
                geometrySourcePolicy.didDefineFutureGeometrySourcePolicy == false ||
                geometrySourcePolicy.didDescribeVertexSourcePolicyFacts == false ||
                geometrySourcePolicy.didDescribeIndexSourcePolicyFacts == false ||
                geometrySourcePolicy.didDescribeGeometryFallbackFacts == false ||
                geometrySourcePolicy.didKeepGeometrySourcePolicyValueOnly == false ||
                geometrySourcePolicy.didAvoidBufferBinding == false ||
                geometrySourcePolicy.didAvoidPlatformResourceReference == false ||
                geometrySourcePolicy.didAvoidRendererStateWrite == false ||
                geometrySourcePolicy.didAvoidRenderingPermission == false ||
                geometrySourcePolicy.shouldDeferRendererGeometrySourcePolicy ||
                geometrySourcePolicy.shouldReportRendererGeometrySourcePolicyBlocked
            )
        ) ||
        (geometrySourcePolicy.didPreserveRendererDrawCommandShapePolicy &&
            geometrySourcePolicy.didPrepareRendererGeometrySourcePolicy == false) ||
        (geometrySourcePolicy.shouldDeferRendererGeometrySourcePolicy &&
            geometrySourcePolicy.shouldReportRendererGeometrySourcePolicyBlocked)

    // draw sequencing guard 只记录 order / hint facts；这里不排序、不提交。
    if (
        geometrySourcePolicy.shouldReportRendererGeometrySourcePolicyBlocked ||
        guardInconsistent
    ) {
        return CjguiInternalRendererDrawSequencingGuard(
            geometrySourcePolicy,
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
        return CjguiInternalRendererDrawSequencingGuard(
            geometrySourcePolicy,
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
        return CjguiInternalRendererDrawSequencingGuard(
            geometrySourcePolicy,
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

    return CjguiInternalRendererDrawSequencingGuard(
        geometrySourcePolicy,
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

func cjguiInternalBuildRendererNoDrawCallReadiness(
    sequencingGuard: CjguiInternalRendererDrawSequencingGuard
): CjguiInternalRendererNoDrawCallReadiness {
    let guardReady = sequencingGuard.didPrepareRendererDrawSequencingGuard &&
        sequencingGuard.didPreserveRendererGeometrySourcePolicy &&
        sequencingGuard.didDefineFutureDrawSequencingGuard &&
        sequencingGuard.didDescribeDrawOrderRelation &&
        sequencingGuard.didDescribeMaterialGroupingHintRelation &&
        sequencingGuard.didDescribeFailureNoDrawFallback &&
        sequencingGuard.didKeepDrawSequencingGuardValueOnly &&
        sequencingGuard.didAvoidSortingSideEffect &&
        sequencingGuard.didAvoidGpuSubmission &&
        sequencingGuard.didAvoidRendererStateWrite &&
        sequencingGuard.didAvoidRenderingPermission &&
        sequencingGuard.shouldDeferRendererDrawSequencingGuard == false &&
        sequencingGuard.shouldReportRendererDrawSequencingGuardBlocked == false
    let readinessDeferred =
        sequencingGuard.didPrepareRendererDrawSequencingGuard == false &&
        sequencingGuard.shouldDeferRendererDrawSequencingGuard &&
        sequencingGuard.shouldReportRendererDrawSequencingGuardBlocked == false
    let readinessInconsistent = (
        sequencingGuard.didPrepareRendererDrawSequencingGuard &&
            (
                sequencingGuard.didPreserveRendererGeometrySourcePolicy == false ||
                sequencingGuard.didDefineFutureDrawSequencingGuard == false ||
                sequencingGuard.didDescribeDrawOrderRelation == false ||
                sequencingGuard.didDescribeMaterialGroupingHintRelation == false ||
                sequencingGuard.didDescribeFailureNoDrawFallback == false ||
                sequencingGuard.didKeepDrawSequencingGuardValueOnly == false ||
                sequencingGuard.didAvoidSortingSideEffect == false ||
                sequencingGuard.didAvoidGpuSubmission == false ||
                sequencingGuard.didAvoidRendererStateWrite == false ||
                sequencingGuard.didAvoidRenderingPermission == false ||
                sequencingGuard.shouldDeferRendererDrawSequencingGuard ||
                sequencingGuard.shouldReportRendererDrawSequencingGuardBlocked
            )
        ) ||
        (sequencingGuard.didPreserveRendererGeometrySourcePolicy &&
            sequencingGuard.didPrepareRendererDrawSequencingGuard == false) ||
        (sequencingGuard.shouldDeferRendererDrawSequencingGuard &&
            sequencingGuard.shouldReportRendererDrawSequencingGuardBlocked)

    // no-draw-call readiness 只封口 value facts；这里不生成 receipt / record / emission。
    if (
        sequencingGuard.shouldReportRendererDrawSequencingGuardBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoDrawCallReadiness(
            sequencingGuard,
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

    if (guardReady) {
        return CjguiInternalRendererNoDrawCallReadiness(
            sequencingGuard,
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
        return CjguiInternalRendererNoDrawCallReadiness(
            sequencingGuard,
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

    return CjguiInternalRendererNoDrawCallReadiness(
        sequencingGuard,
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

func cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft(
): CjguiInternalRendererNoDrawCallReadiness {
    let noEncoderReadiness =
        cjguiInternalExecuteDefaultRendererEncoderLifecycleDraft()
    let lifecycleIntent = cjguiInternalBuildRendererDrawCallLifecycleIntent(
        noEncoderReadiness
    )
    let shapePolicy = cjguiInternalBuildRendererDrawCommandShapePolicy(
        lifecycleIntent
    )
    let geometrySourcePolicy = cjguiInternalBuildRendererGeometrySourcePolicy(
        shapePolicy
    )
    let sequencingGuard = cjguiInternalBuildRendererDrawSequencingGuard(
        geometrySourcePolicy
    )
    return cjguiInternalBuildRendererNoDrawCallReadiness(sequencingGuard)
}
