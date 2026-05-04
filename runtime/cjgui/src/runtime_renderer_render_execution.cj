package cjgui

// Owner: Renderer render execution no-op value boundary.
// Truth: 只消费 CjguiInternalRendererNoPipelineStateReadiness，表达 future render
// execution intent、execution ordering policy、no-submit guard、completion observation
// policy 与 no-render-execution readiness 的内部 value facts。
// Stop-line: 这里不执行 render，不提交 command buffer，不提交 GPU work，不调用
// MTLRenderCommandEncoder，不绑定 MTLRenderPipelineState，不 present drawable，
// 不接后端，不写 renderer state，不持有 native handle 或 raw pointer。
// Same-shape Boundary Brake: 本 owner 新增 execution ordering / no-submit /
// completion observation / rollback-no-draw / no-render-execution vocabulary，
// 不把 no-pipeline-state readiness 包成 receipt / record / publication。

// Render execution intent 只表达 future execution intent；
// 它不是 render implementation，也不是 backend readiness wrapper。
struct CjguiInternalRendererRenderExecutionIntent {
    let noPipelineStateReadiness: CjguiInternalRendererNoPipelineStateReadiness
    let didPrepareRendererRenderExecutionIntent: Bool
    let shouldDeferRendererRenderExecutionIntent: Bool
    let shouldReportRendererRenderExecutionIntentBlocked: Bool
    let didPreserveRendererNoPipelineStateReadiness: Bool
    let didDefineFutureRenderExecutionIntent: Bool
    let didDescribeExecutionPhaseFacts: Bool
    let didDescribeCommandSequencingSummary: Bool
    let didDescribeRollbackNoDrawFallback: Bool
    let didKeepRenderExecutionIntentValueOnly: Bool
    let didAvoidRenderExecution: Bool
    let didAvoidGpuSubmission: Bool
    let didAvoidBackendPermission: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidThinWrapper: Bool

    init(
        noPipelineStateReadiness: CjguiInternalRendererNoPipelineStateReadiness,
        didPrepareRendererRenderExecutionIntent: Bool,
        shouldDeferRendererRenderExecutionIntent: Bool,
        shouldReportRendererRenderExecutionIntentBlocked: Bool,
        didPreserveRendererNoPipelineStateReadiness: Bool,
        didDefineFutureRenderExecutionIntent: Bool,
        didDescribeExecutionPhaseFacts: Bool,
        didDescribeCommandSequencingSummary: Bool,
        didDescribeRollbackNoDrawFallback: Bool,
        didKeepRenderExecutionIntentValueOnly: Bool,
        didAvoidRenderExecution: Bool,
        didAvoidGpuSubmission: Bool,
        didAvoidBackendPermission: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noPipelineStateReadiness = noPipelineStateReadiness
        this.didPrepareRendererRenderExecutionIntent =
            didPrepareRendererRenderExecutionIntent
        this.shouldDeferRendererRenderExecutionIntent =
            shouldDeferRendererRenderExecutionIntent
        this.shouldReportRendererRenderExecutionIntentBlocked =
            shouldReportRendererRenderExecutionIntentBlocked
        this.didPreserveRendererNoPipelineStateReadiness =
            didPreserveRendererNoPipelineStateReadiness
        this.didDefineFutureRenderExecutionIntent =
            didDefineFutureRenderExecutionIntent
        this.didDescribeExecutionPhaseFacts = didDescribeExecutionPhaseFacts
        this.didDescribeCommandSequencingSummary =
            didDescribeCommandSequencingSummary
        this.didDescribeRollbackNoDrawFallback = didDescribeRollbackNoDrawFallback
        this.didKeepRenderExecutionIntentValueOnly =
            didKeepRenderExecutionIntentValueOnly
        this.didAvoidRenderExecution = didAvoidRenderExecution
        this.didAvoidGpuSubmission = didAvoidGpuSubmission
        this.didAvoidBackendPermission = didAvoidBackendPermission
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

// Execution ordering policy 只表达 command sequencing summary / execution phase；
// 它不排序、不提交、不执行，也不把 draw sequencing 变成 GPU work。
struct CjguiInternalRendererExecutionOrderingPolicy {
    let renderExecutionIntent: CjguiInternalRendererRenderExecutionIntent
    let didPrepareRendererExecutionOrderingPolicy: Bool
    let shouldDeferRendererExecutionOrderingPolicy: Bool
    let shouldReportRendererExecutionOrderingPolicyBlocked: Bool
    let didPreserveRendererRenderExecutionIntent: Bool
    let didDefineFutureExecutionOrderingPolicy: Bool
    let didDescribeCommandSequencingSummary: Bool
    let didDescribeEncoderEndRelation: Bool
    let didDescribeDrawPipelineRelation: Bool
    let didDescribeFramePacingRelation: Bool
    let didKeepExecutionOrderingPolicyValueOnly: Bool
    let didAvoidSortingSideEffect: Bool
    let didAvoidCommandSubmission: Bool
    let didAvoidRenderExecution: Bool
    let didAvoidRendererStateWrite: Bool

    init(
        renderExecutionIntent: CjguiInternalRendererRenderExecutionIntent,
        didPrepareRendererExecutionOrderingPolicy: Bool,
        shouldDeferRendererExecutionOrderingPolicy: Bool,
        shouldReportRendererExecutionOrderingPolicyBlocked: Bool,
        didPreserveRendererRenderExecutionIntent: Bool,
        didDefineFutureExecutionOrderingPolicy: Bool,
        didDescribeCommandSequencingSummary: Bool,
        didDescribeEncoderEndRelation: Bool,
        didDescribeDrawPipelineRelation: Bool,
        didDescribeFramePacingRelation: Bool,
        didKeepExecutionOrderingPolicyValueOnly: Bool,
        didAvoidSortingSideEffect: Bool,
        didAvoidCommandSubmission: Bool,
        didAvoidRenderExecution: Bool,
        didAvoidRendererStateWrite: Bool
    ) {
        this.renderExecutionIntent = renderExecutionIntent
        this.didPrepareRendererExecutionOrderingPolicy =
            didPrepareRendererExecutionOrderingPolicy
        this.shouldDeferRendererExecutionOrderingPolicy =
            shouldDeferRendererExecutionOrderingPolicy
        this.shouldReportRendererExecutionOrderingPolicyBlocked =
            shouldReportRendererExecutionOrderingPolicyBlocked
        this.didPreserveRendererRenderExecutionIntent =
            didPreserveRendererRenderExecutionIntent
        this.didDefineFutureExecutionOrderingPolicy =
            didDefineFutureExecutionOrderingPolicy
        this.didDescribeCommandSequencingSummary =
            didDescribeCommandSequencingSummary
        this.didDescribeEncoderEndRelation = didDescribeEncoderEndRelation
        this.didDescribeDrawPipelineRelation = didDescribeDrawPipelineRelation
        this.didDescribeFramePacingRelation = didDescribeFramePacingRelation
        this.didKeepExecutionOrderingPolicyValueOnly =
            didKeepExecutionOrderingPolicyValueOnly
        this.didAvoidSortingSideEffect = didAvoidSortingSideEffect
        this.didAvoidCommandSubmission = didAvoidCommandSubmission
        this.didAvoidRenderExecution = didAvoidRenderExecution
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
    }
}

// No-submit guard 只表达 future command buffer / GPU submission stop-line；
// 它不 commit command buffer，不 submit GPU work，不 present drawable。
struct CjguiInternalRendererNoSubmitGuard {
    let orderingPolicy: CjguiInternalRendererExecutionOrderingPolicy
    let didPrepareRendererNoSubmitGuard: Bool
    let shouldDeferRendererNoSubmitGuard: Bool
    let shouldReportRendererNoSubmitGuardBlocked: Bool
    let didPreserveRendererExecutionOrderingPolicy: Bool
    let didDefineFutureNoSubmitGuard: Bool
    let didDescribeCommandBufferCommitStopLine: Bool
    let didDescribeGpuSubmissionStopLine: Bool
    let didDescribeDrawablePresentationStopLine: Bool
    let didKeepNoSubmitGuardValueOnly: Bool
    let didConfirmNoCommandBufferCommit: Bool
    let didConfirmNoGpuSubmission: Bool
    let didConfirmNoDrawablePresentation: Bool
    let didAvoidBackendPermission: Bool
    let didAvoidRendererStateWrite: Bool

    init(
        orderingPolicy: CjguiInternalRendererExecutionOrderingPolicy,
        didPrepareRendererNoSubmitGuard: Bool,
        shouldDeferRendererNoSubmitGuard: Bool,
        shouldReportRendererNoSubmitGuardBlocked: Bool,
        didPreserveRendererExecutionOrderingPolicy: Bool,
        didDefineFutureNoSubmitGuard: Bool,
        didDescribeCommandBufferCommitStopLine: Bool,
        didDescribeGpuSubmissionStopLine: Bool,
        didDescribeDrawablePresentationStopLine: Bool,
        didKeepNoSubmitGuardValueOnly: Bool,
        didConfirmNoCommandBufferCommit: Bool,
        didConfirmNoGpuSubmission: Bool,
        didConfirmNoDrawablePresentation: Bool,
        didAvoidBackendPermission: Bool,
        didAvoidRendererStateWrite: Bool
    ) {
        this.orderingPolicy = orderingPolicy
        this.didPrepareRendererNoSubmitGuard = didPrepareRendererNoSubmitGuard
        this.shouldDeferRendererNoSubmitGuard = shouldDeferRendererNoSubmitGuard
        this.shouldReportRendererNoSubmitGuardBlocked =
            shouldReportRendererNoSubmitGuardBlocked
        this.didPreserveRendererExecutionOrderingPolicy =
            didPreserveRendererExecutionOrderingPolicy
        this.didDefineFutureNoSubmitGuard = didDefineFutureNoSubmitGuard
        this.didDescribeCommandBufferCommitStopLine =
            didDescribeCommandBufferCommitStopLine
        this.didDescribeGpuSubmissionStopLine =
            didDescribeGpuSubmissionStopLine
        this.didDescribeDrawablePresentationStopLine =
            didDescribeDrawablePresentationStopLine
        this.didKeepNoSubmitGuardValueOnly = didKeepNoSubmitGuardValueOnly
        this.didConfirmNoCommandBufferCommit = didConfirmNoCommandBufferCommit
        this.didConfirmNoGpuSubmission = didConfirmNoGpuSubmission
        this.didConfirmNoDrawablePresentation = didConfirmNoDrawablePresentation
        this.didAvoidBackendPermission = didAvoidBackendPermission
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
    }
}

// Completion observation policy 只表达 future completion / failure facts；
// 它不注册 completion handler，不观察真实 GPU completion，不发布 diagnostics。
struct CjguiInternalRendererCompletionObservationPolicy {
    let noSubmitGuard: CjguiInternalRendererNoSubmitGuard
    let didPrepareRendererCompletionObservationPolicy: Bool
    let shouldDeferRendererCompletionObservationPolicy: Bool
    let shouldReportRendererCompletionObservationPolicyBlocked: Bool
    let didPreserveRendererNoSubmitGuard: Bool
    let didDefineFutureCompletionObservationPolicy: Bool
    let didDescribeCompletionObservationFacts: Bool
    let didDescribeFailureObservationFacts: Bool
    let didDescribeRollbackNoDrawFallback: Bool
    let didKeepCompletionObservationPolicyValueOnly: Bool
    let didAvoidCompletionHandlerRegistration: Bool
    let didAvoidRealGpuCompletionObservation: Bool
    let didAvoidDiagnosticsPublication: Bool
    let didAvoidBackendPermission: Bool
    let didAvoidRendererStateWrite: Bool

    init(
        noSubmitGuard: CjguiInternalRendererNoSubmitGuard,
        didPrepareRendererCompletionObservationPolicy: Bool,
        shouldDeferRendererCompletionObservationPolicy: Bool,
        shouldReportRendererCompletionObservationPolicyBlocked: Bool,
        didPreserveRendererNoSubmitGuard: Bool,
        didDefineFutureCompletionObservationPolicy: Bool,
        didDescribeCompletionObservationFacts: Bool,
        didDescribeFailureObservationFacts: Bool,
        didDescribeRollbackNoDrawFallback: Bool,
        didKeepCompletionObservationPolicyValueOnly: Bool,
        didAvoidCompletionHandlerRegistration: Bool,
        didAvoidRealGpuCompletionObservation: Bool,
        didAvoidDiagnosticsPublication: Bool,
        didAvoidBackendPermission: Bool,
        didAvoidRendererStateWrite: Bool
    ) {
        this.noSubmitGuard = noSubmitGuard
        this.didPrepareRendererCompletionObservationPolicy =
            didPrepareRendererCompletionObservationPolicy
        this.shouldDeferRendererCompletionObservationPolicy =
            shouldDeferRendererCompletionObservationPolicy
        this.shouldReportRendererCompletionObservationPolicyBlocked =
            shouldReportRendererCompletionObservationPolicyBlocked
        this.didPreserveRendererNoSubmitGuard = didPreserveRendererNoSubmitGuard
        this.didDefineFutureCompletionObservationPolicy =
            didDefineFutureCompletionObservationPolicy
        this.didDescribeCompletionObservationFacts =
            didDescribeCompletionObservationFacts
        this.didDescribeFailureObservationFacts =
            didDescribeFailureObservationFacts
        this.didDescribeRollbackNoDrawFallback = didDescribeRollbackNoDrawFallback
        this.didKeepCompletionObservationPolicyValueOnly =
            didKeepCompletionObservationPolicyValueOnly
        this.didAvoidCompletionHandlerRegistration =
            didAvoidCompletionHandlerRegistration
        this.didAvoidRealGpuCompletionObservation =
            didAvoidRealGpuCompletionObservation
        this.didAvoidDiagnosticsPublication = didAvoidDiagnosticsPublication
        this.didAvoidBackendPermission = didAvoidBackendPermission
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
    }
}

// No-render-execution readiness 是本 owner 的 endpoint；readiness 只表示 future
// render execution no-op boundary 可以继续评估，不代表 render、GPU submission、
// command buffer commit、encoder call、pipeline binding、drawable presentation、
// renderer state write、native handle / raw pointer、backend 或 platform permission。
struct CjguiInternalRendererNoRenderExecutionReadiness {
    let completionObservationPolicy: CjguiInternalRendererCompletionObservationPolicy
    let isRendererNoRenderExecutionReady: Bool
    let canFutureRendererRenderExecutionBoundaryEvaluate: Bool
    let shouldDeferRendererNoRenderExecutionReadiness: Bool
    let shouldReportRendererNoRenderExecutionReadinessBlocked: Bool
    let didSealRendererNoRenderExecutionReadiness: Bool
    let didPreserveRendererCompletionObservationPolicy: Bool
    let didKeepNoRenderExecutionReadinessValueOnly: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoGpuSubmission: Bool
    let didConfirmNoCommandBufferCommit: Bool
    let didConfirmNoEncoderCall: Bool
    let didConfirmNoPipelineBinding: Bool
    let didConfirmNoDrawablePresentation: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoNativeResourceToken: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didAvoidBackendPermission: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        completionObservationPolicy: CjguiInternalRendererCompletionObservationPolicy,
        isRendererNoRenderExecutionReady: Bool,
        canFutureRendererRenderExecutionBoundaryEvaluate: Bool,
        shouldDeferRendererNoRenderExecutionReadiness: Bool,
        shouldReportRendererNoRenderExecutionReadinessBlocked: Bool,
        didSealRendererNoRenderExecutionReadiness: Bool,
        didPreserveRendererCompletionObservationPolicy: Bool,
        didKeepNoRenderExecutionReadinessValueOnly: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoGpuSubmission: Bool,
        didConfirmNoCommandBufferCommit: Bool,
        didConfirmNoEncoderCall: Bool,
        didConfirmNoPipelineBinding: Bool,
        didConfirmNoDrawablePresentation: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoNativeResourceToken: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didAvoidBackendPermission: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.completionObservationPolicy = completionObservationPolicy
        this.isRendererNoRenderExecutionReady = isRendererNoRenderExecutionReady
        this.canFutureRendererRenderExecutionBoundaryEvaluate =
            canFutureRendererRenderExecutionBoundaryEvaluate
        this.shouldDeferRendererNoRenderExecutionReadiness =
            shouldDeferRendererNoRenderExecutionReadiness
        this.shouldReportRendererNoRenderExecutionReadinessBlocked =
            shouldReportRendererNoRenderExecutionReadinessBlocked
        this.didSealRendererNoRenderExecutionReadiness =
            didSealRendererNoRenderExecutionReadiness
        this.didPreserveRendererCompletionObservationPolicy =
            didPreserveRendererCompletionObservationPolicy
        this.didKeepNoRenderExecutionReadinessValueOnly =
            didKeepNoRenderExecutionReadinessValueOnly
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoGpuSubmission = didConfirmNoGpuSubmission
        this.didConfirmNoCommandBufferCommit = didConfirmNoCommandBufferCommit
        this.didConfirmNoEncoderCall = didConfirmNoEncoderCall
        this.didConfirmNoPipelineBinding = didConfirmNoPipelineBinding
        this.didConfirmNoDrawablePresentation = didConfirmNoDrawablePresentation
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoNativeResourceToken = didConfirmNoNativeResourceToken
        this.didConfirmNoPointerLikeResource = didConfirmNoPointerLikeResource
        this.didAvoidBackendPermission = didAvoidBackendPermission
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererRenderExecutionIntent(
    noPipelineStateReadiness: CjguiInternalRendererNoPipelineStateReadiness
): CjguiInternalRendererRenderExecutionIntent {
    let noPipelineStateReady = noPipelineStateReadiness.isRendererNoPipelineStateReady &&
        noPipelineStateReadiness.canFutureRendererPipelineStateBoundaryEvaluate &&
        noPipelineStateReadiness.didSealRendererNoPipelineStateReadiness &&
        noPipelineStateReadiness.didPreserveRendererPipelineCompatibilityGuard &&
        noPipelineStateReadiness.didKeepNoPipelineStateReadinessValueOnly &&
        noPipelineStateReadiness.didConfirmNoPipelineStateObject &&
        noPipelineStateReadiness.didConfirmNoShaderLibraryObject &&
        noPipelineStateReadiness.didConfirmNoShaderFunctionObject &&
        noPipelineStateReadiness.didConfirmNoPipelineDescriptorObject &&
        noPipelineStateReadiness.didConfirmNoEncoderInvocation &&
        noPipelineStateReadiness.didConfirmNoBufferBinding &&
        noPipelineStateReadiness.didConfirmNoTextureBinding &&
        noPipelineStateReadiness.didConfirmNoNativeResourceToken &&
        noPipelineStateReadiness.didConfirmNoPointerLikeResource &&
        noPipelineStateReadiness.didAvoidBackendPermission &&
        noPipelineStateReadiness.didAvoidRendererStateMutation &&
        noPipelineStateReadiness.didAvoidRenderingPermission &&
        noPipelineStateReadiness.didAvoidThinWrapper &&
        noPipelineStateReadiness.didStayFullRebuildOnly &&
        noPipelineStateReadiness.shouldDeferRendererNoPipelineStateReadiness == false &&
        noPipelineStateReadiness.shouldReportRendererNoPipelineStateReadinessBlocked == false
    let intentDeferred =
        noPipelineStateReadiness.isRendererNoPipelineStateReady == false &&
        noPipelineStateReadiness.canFutureRendererPipelineStateBoundaryEvaluate == false &&
        noPipelineStateReadiness.shouldDeferRendererNoPipelineStateReadiness &&
        noPipelineStateReadiness.shouldReportRendererNoPipelineStateReadinessBlocked == false
    let intentInconsistent = (
        noPipelineStateReadiness.isRendererNoPipelineStateReady &&
            (
                noPipelineStateReadiness.canFutureRendererPipelineStateBoundaryEvaluate == false ||
                noPipelineStateReadiness.didSealRendererNoPipelineStateReadiness == false ||
                noPipelineStateReadiness.didPreserveRendererPipelineCompatibilityGuard == false ||
                noPipelineStateReadiness.didKeepNoPipelineStateReadinessValueOnly == false ||
                noPipelineStateReadiness.didConfirmNoPipelineStateObject == false ||
                noPipelineStateReadiness.didConfirmNoShaderLibraryObject == false ||
                noPipelineStateReadiness.didConfirmNoShaderFunctionObject == false ||
                noPipelineStateReadiness.didConfirmNoPipelineDescriptorObject == false ||
                noPipelineStateReadiness.didConfirmNoEncoderInvocation == false ||
                noPipelineStateReadiness.didConfirmNoBufferBinding == false ||
                noPipelineStateReadiness.didConfirmNoTextureBinding == false ||
                noPipelineStateReadiness.didConfirmNoNativeResourceToken == false ||
                noPipelineStateReadiness.didConfirmNoPointerLikeResource == false ||
                noPipelineStateReadiness.didAvoidBackendPermission == false ||
                noPipelineStateReadiness.didAvoidRendererStateMutation == false ||
                noPipelineStateReadiness.didAvoidRenderingPermission == false ||
                noPipelineStateReadiness.didAvoidThinWrapper == false ||
                noPipelineStateReadiness.didStayFullRebuildOnly == false ||
                noPipelineStateReadiness.shouldDeferRendererNoPipelineStateReadiness ||
                noPipelineStateReadiness.shouldReportRendererNoPipelineStateReadinessBlocked
            )
        ) ||
        (noPipelineStateReadiness.canFutureRendererPipelineStateBoundaryEvaluate &&
            noPipelineStateReadiness.isRendererNoPipelineStateReady == false) ||
        (noPipelineStateReadiness.shouldDeferRendererNoPipelineStateReadiness &&
            noPipelineStateReadiness.shouldReportRendererNoPipelineStateReadinessBlocked)

    // fail-closed：不能把 no-pipeline-state readiness 薄包成 render execution intent。
    if (
        noPipelineStateReadiness.shouldReportRendererNoPipelineStateReadinessBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererRenderExecutionIntent(
            noPipelineStateReadiness,
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

    if (noPipelineStateReady) {
        return CjguiInternalRendererRenderExecutionIntent(
            noPipelineStateReadiness,
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
        return CjguiInternalRendererRenderExecutionIntent(
            noPipelineStateReadiness,
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

    return CjguiInternalRendererRenderExecutionIntent(
        noPipelineStateReadiness,
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

func cjguiInternalBuildRendererExecutionOrderingPolicy(
    renderExecutionIntent: CjguiInternalRendererRenderExecutionIntent
): CjguiInternalRendererExecutionOrderingPolicy {
    let intentReady =
        renderExecutionIntent.didPrepareRendererRenderExecutionIntent &&
        renderExecutionIntent.didPreserveRendererNoPipelineStateReadiness &&
        renderExecutionIntent.didDefineFutureRenderExecutionIntent &&
        renderExecutionIntent.didDescribeExecutionPhaseFacts &&
        renderExecutionIntent.didDescribeCommandSequencingSummary &&
        renderExecutionIntent.didDescribeRollbackNoDrawFallback &&
        renderExecutionIntent.didKeepRenderExecutionIntentValueOnly &&
        renderExecutionIntent.didAvoidRenderExecution &&
        renderExecutionIntent.didAvoidGpuSubmission &&
        renderExecutionIntent.didAvoidBackendPermission &&
        renderExecutionIntent.didAvoidRendererStateWrite &&
        renderExecutionIntent.didAvoidThinWrapper &&
        renderExecutionIntent.shouldDeferRendererRenderExecutionIntent == false &&
        renderExecutionIntent.shouldReportRendererRenderExecutionIntentBlocked == false
    let policyDeferred =
        renderExecutionIntent.didPrepareRendererRenderExecutionIntent == false &&
        renderExecutionIntent.shouldDeferRendererRenderExecutionIntent &&
        renderExecutionIntent.shouldReportRendererRenderExecutionIntentBlocked == false
    let policyInconsistent = (
        renderExecutionIntent.didPrepareRendererRenderExecutionIntent &&
            (
                renderExecutionIntent.didPreserveRendererNoPipelineStateReadiness == false ||
                renderExecutionIntent.didDefineFutureRenderExecutionIntent == false ||
                renderExecutionIntent.didDescribeExecutionPhaseFacts == false ||
                renderExecutionIntent.didDescribeCommandSequencingSummary == false ||
                renderExecutionIntent.didDescribeRollbackNoDrawFallback == false ||
                renderExecutionIntent.didKeepRenderExecutionIntentValueOnly == false ||
                renderExecutionIntent.didAvoidRenderExecution == false ||
                renderExecutionIntent.didAvoidGpuSubmission == false ||
                renderExecutionIntent.didAvoidBackendPermission == false ||
                renderExecutionIntent.didAvoidRendererStateWrite == false ||
                renderExecutionIntent.didAvoidThinWrapper == false ||
                renderExecutionIntent.shouldDeferRendererRenderExecutionIntent ||
                renderExecutionIntent.shouldReportRendererRenderExecutionIntentBlocked
            )
        ) ||
        (renderExecutionIntent.didPreserveRendererNoPipelineStateReadiness &&
            renderExecutionIntent.didPrepareRendererRenderExecutionIntent == false) ||
        (renderExecutionIntent.shouldDeferRendererRenderExecutionIntent &&
            renderExecutionIntent.shouldReportRendererRenderExecutionIntentBlocked)

    // ordering policy 只记录 sequencing / relation facts；这里不排序、不执行。
    if (
        renderExecutionIntent.shouldReportRendererRenderExecutionIntentBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererExecutionOrderingPolicy(
            renderExecutionIntent,
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
        return CjguiInternalRendererExecutionOrderingPolicy(
            renderExecutionIntent,
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
        return CjguiInternalRendererExecutionOrderingPolicy(
            renderExecutionIntent,
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

    return CjguiInternalRendererExecutionOrderingPolicy(
        renderExecutionIntent,
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

func cjguiInternalBuildRendererNoSubmitGuard(
    orderingPolicy: CjguiInternalRendererExecutionOrderingPolicy
): CjguiInternalRendererNoSubmitGuard {
    let policyReady = orderingPolicy.didPrepareRendererExecutionOrderingPolicy &&
        orderingPolicy.didPreserveRendererRenderExecutionIntent &&
        orderingPolicy.didDefineFutureExecutionOrderingPolicy &&
        orderingPolicy.didDescribeCommandSequencingSummary &&
        orderingPolicy.didDescribeEncoderEndRelation &&
        orderingPolicy.didDescribeDrawPipelineRelation &&
        orderingPolicy.didDescribeFramePacingRelation &&
        orderingPolicy.didKeepExecutionOrderingPolicyValueOnly &&
        orderingPolicy.didAvoidSortingSideEffect &&
        orderingPolicy.didAvoidCommandSubmission &&
        orderingPolicy.didAvoidRenderExecution &&
        orderingPolicy.didAvoidRendererStateWrite &&
        orderingPolicy.shouldDeferRendererExecutionOrderingPolicy == false &&
        orderingPolicy.shouldReportRendererExecutionOrderingPolicyBlocked == false
    let guardDeferred =
        orderingPolicy.didPrepareRendererExecutionOrderingPolicy == false &&
        orderingPolicy.shouldDeferRendererExecutionOrderingPolicy &&
        orderingPolicy.shouldReportRendererExecutionOrderingPolicyBlocked == false
    let guardInconsistent = (
        orderingPolicy.didPrepareRendererExecutionOrderingPolicy &&
            (
                orderingPolicy.didPreserveRendererRenderExecutionIntent == false ||
                orderingPolicy.didDefineFutureExecutionOrderingPolicy == false ||
                orderingPolicy.didDescribeCommandSequencingSummary == false ||
                orderingPolicy.didDescribeEncoderEndRelation == false ||
                orderingPolicy.didDescribeDrawPipelineRelation == false ||
                orderingPolicy.didDescribeFramePacingRelation == false ||
                orderingPolicy.didKeepExecutionOrderingPolicyValueOnly == false ||
                orderingPolicy.didAvoidSortingSideEffect == false ||
                orderingPolicy.didAvoidCommandSubmission == false ||
                orderingPolicy.didAvoidRenderExecution == false ||
                orderingPolicy.didAvoidRendererStateWrite == false ||
                orderingPolicy.shouldDeferRendererExecutionOrderingPolicy ||
                orderingPolicy.shouldReportRendererExecutionOrderingPolicyBlocked
            )
        ) ||
        (orderingPolicy.didPreserveRendererRenderExecutionIntent &&
            orderingPolicy.didPrepareRendererExecutionOrderingPolicy == false) ||
        (orderingPolicy.shouldDeferRendererExecutionOrderingPolicy &&
            orderingPolicy.shouldReportRendererExecutionOrderingPolicyBlocked)

    // no-submit guard 只确认 stop-line；这里不 commit、不 submit、不 present。
    if (
        orderingPolicy.shouldReportRendererExecutionOrderingPolicyBlocked ||
        guardInconsistent
    ) {
        return CjguiInternalRendererNoSubmitGuard(
            orderingPolicy,
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
        return CjguiInternalRendererNoSubmitGuard(
            orderingPolicy,
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

    if (guardDeferred) {
        return CjguiInternalRendererNoSubmitGuard(
            orderingPolicy,
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

    return CjguiInternalRendererNoSubmitGuard(
        orderingPolicy,
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

func cjguiInternalBuildRendererCompletionObservationPolicy(
    noSubmitGuard: CjguiInternalRendererNoSubmitGuard
): CjguiInternalRendererCompletionObservationPolicy {
    let guardReady = noSubmitGuard.didPrepareRendererNoSubmitGuard &&
        noSubmitGuard.didPreserveRendererExecutionOrderingPolicy &&
        noSubmitGuard.didDefineFutureNoSubmitGuard &&
        noSubmitGuard.didDescribeCommandBufferCommitStopLine &&
        noSubmitGuard.didDescribeGpuSubmissionStopLine &&
        noSubmitGuard.didDescribeDrawablePresentationStopLine &&
        noSubmitGuard.didKeepNoSubmitGuardValueOnly &&
        noSubmitGuard.didConfirmNoCommandBufferCommit &&
        noSubmitGuard.didConfirmNoGpuSubmission &&
        noSubmitGuard.didConfirmNoDrawablePresentation &&
        noSubmitGuard.didAvoidBackendPermission &&
        noSubmitGuard.didAvoidRendererStateWrite &&
        noSubmitGuard.shouldDeferRendererNoSubmitGuard == false &&
        noSubmitGuard.shouldReportRendererNoSubmitGuardBlocked == false
    let policyDeferred = noSubmitGuard.didPrepareRendererNoSubmitGuard == false &&
        noSubmitGuard.shouldDeferRendererNoSubmitGuard &&
        noSubmitGuard.shouldReportRendererNoSubmitGuardBlocked == false
    let policyInconsistent = (
        noSubmitGuard.didPrepareRendererNoSubmitGuard &&
            (
                noSubmitGuard.didPreserveRendererExecutionOrderingPolicy == false ||
                noSubmitGuard.didDefineFutureNoSubmitGuard == false ||
                noSubmitGuard.didDescribeCommandBufferCommitStopLine == false ||
                noSubmitGuard.didDescribeGpuSubmissionStopLine == false ||
                noSubmitGuard.didDescribeDrawablePresentationStopLine == false ||
                noSubmitGuard.didKeepNoSubmitGuardValueOnly == false ||
                noSubmitGuard.didConfirmNoCommandBufferCommit == false ||
                noSubmitGuard.didConfirmNoGpuSubmission == false ||
                noSubmitGuard.didConfirmNoDrawablePresentation == false ||
                noSubmitGuard.didAvoidBackendPermission == false ||
                noSubmitGuard.didAvoidRendererStateWrite == false ||
                noSubmitGuard.shouldDeferRendererNoSubmitGuard ||
                noSubmitGuard.shouldReportRendererNoSubmitGuardBlocked
            )
        ) ||
        (noSubmitGuard.didPreserveRendererExecutionOrderingPolicy &&
            noSubmitGuard.didPrepareRendererNoSubmitGuard == false) ||
        (noSubmitGuard.shouldDeferRendererNoSubmitGuard &&
            noSubmitGuard.shouldReportRendererNoSubmitGuardBlocked)

    // completion policy 只表达 observation vocabulary；这里不注册 handler。
    if (
        noSubmitGuard.shouldReportRendererNoSubmitGuardBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererCompletionObservationPolicy(
            noSubmitGuard,
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

    if (guardReady) {
        return CjguiInternalRendererCompletionObservationPolicy(
            noSubmitGuard,
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
        return CjguiInternalRendererCompletionObservationPolicy(
            noSubmitGuard,
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

    return CjguiInternalRendererCompletionObservationPolicy(
        noSubmitGuard,
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

func cjguiInternalBuildRendererNoRenderExecutionReadiness(
    completionObservationPolicy: CjguiInternalRendererCompletionObservationPolicy
): CjguiInternalRendererNoRenderExecutionReadiness {
    let policyReady =
        completionObservationPolicy.didPrepareRendererCompletionObservationPolicy &&
        completionObservationPolicy.didPreserveRendererNoSubmitGuard &&
        completionObservationPolicy.didDefineFutureCompletionObservationPolicy &&
        completionObservationPolicy.didDescribeCompletionObservationFacts &&
        completionObservationPolicy.didDescribeFailureObservationFacts &&
        completionObservationPolicy.didDescribeRollbackNoDrawFallback &&
        completionObservationPolicy.didKeepCompletionObservationPolicyValueOnly &&
        completionObservationPolicy.didAvoidCompletionHandlerRegistration &&
        completionObservationPolicy.didAvoidRealGpuCompletionObservation &&
        completionObservationPolicy.didAvoidDiagnosticsPublication &&
        completionObservationPolicy.didAvoidBackendPermission &&
        completionObservationPolicy.didAvoidRendererStateWrite &&
        completionObservationPolicy.shouldDeferRendererCompletionObservationPolicy == false &&
        completionObservationPolicy.shouldReportRendererCompletionObservationPolicyBlocked == false
    let readinessDeferred =
        completionObservationPolicy.didPrepareRendererCompletionObservationPolicy == false &&
        completionObservationPolicy.shouldDeferRendererCompletionObservationPolicy &&
        completionObservationPolicy.shouldReportRendererCompletionObservationPolicyBlocked == false
    let readinessInconsistent = (
        completionObservationPolicy.didPrepareRendererCompletionObservationPolicy &&
            (
                completionObservationPolicy.didPreserveRendererNoSubmitGuard == false ||
                completionObservationPolicy.didDefineFutureCompletionObservationPolicy == false ||
                completionObservationPolicy.didDescribeCompletionObservationFacts == false ||
                completionObservationPolicy.didDescribeFailureObservationFacts == false ||
                completionObservationPolicy.didDescribeRollbackNoDrawFallback == false ||
                completionObservationPolicy.didKeepCompletionObservationPolicyValueOnly == false ||
                completionObservationPolicy.didAvoidCompletionHandlerRegistration == false ||
                completionObservationPolicy.didAvoidRealGpuCompletionObservation == false ||
                completionObservationPolicy.didAvoidDiagnosticsPublication == false ||
                completionObservationPolicy.didAvoidBackendPermission == false ||
                completionObservationPolicy.didAvoidRendererStateWrite == false ||
                completionObservationPolicy.shouldDeferRendererCompletionObservationPolicy ||
                completionObservationPolicy.shouldReportRendererCompletionObservationPolicyBlocked
            )
        ) ||
        (completionObservationPolicy.didPreserveRendererNoSubmitGuard &&
            completionObservationPolicy.didPrepareRendererCompletionObservationPolicy == false) ||
        (
            completionObservationPolicy.shouldDeferRendererCompletionObservationPolicy &&
            completionObservationPolicy.shouldReportRendererCompletionObservationPolicyBlocked
        )

    // no-render-execution readiness 是 endpoint；这里不发布 receipt / record。
    if (
        completionObservationPolicy.shouldReportRendererCompletionObservationPolicyBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoRenderExecutionReadiness(
            completionObservationPolicy,
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
        return CjguiInternalRendererNoRenderExecutionReadiness(
            completionObservationPolicy,
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
        return CjguiInternalRendererNoRenderExecutionReadiness(
            completionObservationPolicy,
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

    return CjguiInternalRendererNoRenderExecutionReadiness(
        completionObservationPolicy,
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

func cjguiInternalExecuteDefaultRendererRenderExecutionNoOpDraft(
): CjguiInternalRendererNoRenderExecutionReadiness {
    let noPipelineStateReadiness =
        cjguiInternalExecuteDefaultRendererPipelineStateLifecycleDraft()
    let renderExecutionIntent =
        cjguiInternalBuildRendererRenderExecutionIntent(noPipelineStateReadiness)
    let orderingPolicy =
        cjguiInternalBuildRendererExecutionOrderingPolicy(renderExecutionIntent)
    let noSubmitGuard = cjguiInternalBuildRendererNoSubmitGuard(orderingPolicy)
    let completionPolicy =
        cjguiInternalBuildRendererCompletionObservationPolicy(noSubmitGuard)
    return cjguiInternalBuildRendererNoRenderExecutionReadiness(completionPolicy)
}
