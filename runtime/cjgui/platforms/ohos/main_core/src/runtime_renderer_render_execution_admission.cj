// Owner：本文件固定 render execution implementation admission 的 internal-only owner 边界。
// Truth：唯一 runtime input 是 CjguiInternalRendererNoDrawCallImplementationReadiness，
// canonical endpoint 是 CjguiInternalRendererNoRenderExecutionImplementationReadiness。
// Stop-line：只生成 value facts，不执行渲染，不提交图形工作，不创建命令或编码对象，
// 不接外部图形调用，不写 renderer 状态，不开放接口。
// Same-shape Boundary Brake：本文件新增 execution / completion / rollback admission
// 语义，不把上一层 readiness 包成 permission wrapper、receipt、record 或发布凭据。
package cjgui

struct CjguiInternalRendererRenderExecutionImplementationIntent {
    let noDrawCallImplementationReadiness:
        CjguiInternalRendererNoDrawCallImplementationReadiness
    let didPrepareRendererRenderExecutionImplementationIntent: Bool
    let shouldDeferRendererRenderExecutionImplementationIntent: Bool
    let shouldReportRendererRenderExecutionImplementationIntentBlocked: Bool
    let didPreserveRendererNoDrawCallImplementationReadiness: Bool
    let didDefineFutureRenderExecutionImplementationIntent: Bool
    let didDescribeExecutionAdmissionNeed: Bool
    let didDescribeCompletionObservationAdmissionNeed: Bool
    let didDescribeRollbackAdmissionNeed: Bool
    let didKeepRenderExecutionImplementationIntentValueOnly: Bool
    let didAvoidRenderReadyPermissionWrapper: Bool
    let didAvoidCommandWorkPermissionWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        noDrawCallImplementationReadiness:
            CjguiInternalRendererNoDrawCallImplementationReadiness,
        didPrepareRendererRenderExecutionImplementationIntent: Bool,
        shouldDeferRendererRenderExecutionImplementationIntent: Bool,
        shouldReportRendererRenderExecutionImplementationIntentBlocked: Bool,
        didPreserveRendererNoDrawCallImplementationReadiness: Bool,
        didDefineFutureRenderExecutionImplementationIntent: Bool,
        didDescribeExecutionAdmissionNeed: Bool,
        didDescribeCompletionObservationAdmissionNeed: Bool,
        didDescribeRollbackAdmissionNeed: Bool,
        didKeepRenderExecutionImplementationIntentValueOnly: Bool,
        didAvoidRenderReadyPermissionWrapper: Bool,
        didAvoidCommandWorkPermissionWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noDrawCallImplementationReadiness =
            noDrawCallImplementationReadiness
        this.didPrepareRendererRenderExecutionImplementationIntent =
            didPrepareRendererRenderExecutionImplementationIntent
        this.shouldDeferRendererRenderExecutionImplementationIntent =
            shouldDeferRendererRenderExecutionImplementationIntent
        this.shouldReportRendererRenderExecutionImplementationIntentBlocked =
            shouldReportRendererRenderExecutionImplementationIntentBlocked
        this.didPreserveRendererNoDrawCallImplementationReadiness =
            didPreserveRendererNoDrawCallImplementationReadiness
        this.didDefineFutureRenderExecutionImplementationIntent =
            didDefineFutureRenderExecutionImplementationIntent
        this.didDescribeExecutionAdmissionNeed =
            didDescribeExecutionAdmissionNeed
        this.didDescribeCompletionObservationAdmissionNeed =
            didDescribeCompletionObservationAdmissionNeed
        this.didDescribeRollbackAdmissionNeed =
            didDescribeRollbackAdmissionNeed
        this.didKeepRenderExecutionImplementationIntentValueOnly =
            didKeepRenderExecutionImplementationIntentValueOnly
        this.didAvoidRenderReadyPermissionWrapper =
            didAvoidRenderReadyPermissionWrapper
        this.didAvoidCommandWorkPermissionWrapper =
            didAvoidCommandWorkPermissionWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererExecutionAdmissionPolicy {
    let implementationIntent:
        CjguiInternalRendererRenderExecutionImplementationIntent
    let didPrepareRendererExecutionAdmissionPolicy: Bool
    let shouldDeferRendererExecutionAdmissionPolicy: Bool
    let shouldReportRendererExecutionAdmissionPolicyBlocked: Bool
    let didPreserveRendererRenderExecutionImplementationIntent: Bool
    let didDefineFutureExecutionAdmissionPolicy: Bool
    let didDescribeFrameExecutionAdmissionFacts: Bool
    let didDescribeCommandWorkAdmissionFacts: Bool
    let didDescribeNoGpuWorkFacts: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoGpuWork: Bool
    let didConfirmNoCommandObjectWork: Bool
    let didKeepExecutionAdmissionPolicyValueOnly: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidCommandWorkPermissionWrapper: Bool
    let didAvoidGpuWorkWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        implementationIntent:
            CjguiInternalRendererRenderExecutionImplementationIntent,
        didPrepareRendererExecutionAdmissionPolicy: Bool,
        shouldDeferRendererExecutionAdmissionPolicy: Bool,
        shouldReportRendererExecutionAdmissionPolicyBlocked: Bool,
        didPreserveRendererRenderExecutionImplementationIntent: Bool,
        didDefineFutureExecutionAdmissionPolicy: Bool,
        didDescribeFrameExecutionAdmissionFacts: Bool,
        didDescribeCommandWorkAdmissionFacts: Bool,
        didDescribeNoGpuWorkFacts: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoGpuWork: Bool,
        didConfirmNoCommandObjectWork: Bool,
        didKeepExecutionAdmissionPolicyValueOnly: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidCommandWorkPermissionWrapper: Bool,
        didAvoidGpuWorkWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.implementationIntent = implementationIntent
        this.didPrepareRendererExecutionAdmissionPolicy =
            didPrepareRendererExecutionAdmissionPolicy
        this.shouldDeferRendererExecutionAdmissionPolicy =
            shouldDeferRendererExecutionAdmissionPolicy
        this.shouldReportRendererExecutionAdmissionPolicyBlocked =
            shouldReportRendererExecutionAdmissionPolicyBlocked
        this.didPreserveRendererRenderExecutionImplementationIntent =
            didPreserveRendererRenderExecutionImplementationIntent
        this.didDefineFutureExecutionAdmissionPolicy =
            didDefineFutureExecutionAdmissionPolicy
        this.didDescribeFrameExecutionAdmissionFacts =
            didDescribeFrameExecutionAdmissionFacts
        this.didDescribeCommandWorkAdmissionFacts =
            didDescribeCommandWorkAdmissionFacts
        this.didDescribeNoGpuWorkFacts = didDescribeNoGpuWorkFacts
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoGpuWork = didConfirmNoGpuWork
        this.didConfirmNoCommandObjectWork = didConfirmNoCommandObjectWork
        this.didKeepExecutionAdmissionPolicyValueOnly =
            didKeepExecutionAdmissionPolicyValueOnly
        this.didAvoidRenderPermissionWrapper =
            didAvoidRenderPermissionWrapper
        this.didAvoidCommandWorkPermissionWrapper =
            didAvoidCommandWorkPermissionWrapper
        this.didAvoidGpuWorkWrapper = didAvoidGpuWorkWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererCompletionObservationAdmissionGuard {
    let executionAdmissionPolicy:
        CjguiInternalRendererExecutionAdmissionPolicy
    let didPrepareRendererCompletionObservationAdmissionGuard: Bool
    let shouldDeferRendererCompletionObservationAdmissionGuard: Bool
    let shouldReportRendererCompletionObservationAdmissionGuardBlocked: Bool
    let didPreserveRendererExecutionAdmissionPolicy: Bool
    let didDefineFutureCompletionObservationAdmissionGuard: Bool
    let didDescribeCompletionObservationFacts: Bool
    let didDescribeFailureObservationFacts: Bool
    let didDescribeNoCallbackFacts: Bool
    let didConfirmNoCompletionCallback: Bool
    let didConfirmNoRealCompletionObservation: Bool
    let didConfirmNoTelemetryPublication: Bool
    let didKeepCompletionObservationAdmissionGuardValueOnly: Bool
    let didAvoidCompletionPermissionWrapper: Bool
    let didAvoidStateWriteWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        executionAdmissionPolicy:
            CjguiInternalRendererExecutionAdmissionPolicy,
        didPrepareRendererCompletionObservationAdmissionGuard: Bool,
        shouldDeferRendererCompletionObservationAdmissionGuard: Bool,
        shouldReportRendererCompletionObservationAdmissionGuardBlocked: Bool,
        didPreserveRendererExecutionAdmissionPolicy: Bool,
        didDefineFutureCompletionObservationAdmissionGuard: Bool,
        didDescribeCompletionObservationFacts: Bool,
        didDescribeFailureObservationFacts: Bool,
        didDescribeNoCallbackFacts: Bool,
        didConfirmNoCompletionCallback: Bool,
        didConfirmNoRealCompletionObservation: Bool,
        didConfirmNoTelemetryPublication: Bool,
        didKeepCompletionObservationAdmissionGuardValueOnly: Bool,
        didAvoidCompletionPermissionWrapper: Bool,
        didAvoidStateWriteWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.executionAdmissionPolicy = executionAdmissionPolicy
        this.didPrepareRendererCompletionObservationAdmissionGuard =
            didPrepareRendererCompletionObservationAdmissionGuard
        this.shouldDeferRendererCompletionObservationAdmissionGuard =
            shouldDeferRendererCompletionObservationAdmissionGuard
        this.shouldReportRendererCompletionObservationAdmissionGuardBlocked =
            shouldReportRendererCompletionObservationAdmissionGuardBlocked
        this.didPreserveRendererExecutionAdmissionPolicy =
            didPreserveRendererExecutionAdmissionPolicy
        this.didDefineFutureCompletionObservationAdmissionGuard =
            didDefineFutureCompletionObservationAdmissionGuard
        this.didDescribeCompletionObservationFacts =
            didDescribeCompletionObservationFacts
        this.didDescribeFailureObservationFacts =
            didDescribeFailureObservationFacts
        this.didDescribeNoCallbackFacts = didDescribeNoCallbackFacts
        this.didConfirmNoCompletionCallback =
            didConfirmNoCompletionCallback
        this.didConfirmNoRealCompletionObservation =
            didConfirmNoRealCompletionObservation
        this.didConfirmNoTelemetryPublication =
            didConfirmNoTelemetryPublication
        this.didKeepCompletionObservationAdmissionGuardValueOnly =
            didKeepCompletionObservationAdmissionGuardValueOnly
        this.didAvoidCompletionPermissionWrapper =
            didAvoidCompletionPermissionWrapper
        this.didAvoidStateWriteWrapper = didAvoidStateWriteWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRollbackAdmissionPolicy {
    let completionObservationAdmissionGuard:
        CjguiInternalRendererCompletionObservationAdmissionGuard
    let didPrepareRendererRollbackAdmissionPolicy: Bool
    let shouldDeferRendererRollbackAdmissionPolicy: Bool
    let shouldReportRendererRollbackAdmissionPolicyBlocked: Bool
    let didPreserveRendererCompletionObservationAdmissionGuard: Bool
    let didDefineFutureRollbackAdmissionPolicy: Bool
    let didDescribeRollbackAdmissionFacts: Bool
    let didDescribeFailureContainmentFacts: Bool
    let didDescribeNoDrawFallbackFacts: Bool
    let didConfirmNoRollbackCallback: Bool
    let didConfirmNoRendererStateMutation: Bool
    let didConfirmNoExternalPublication: Bool
    let didKeepRollbackAdmissionPolicyValueOnly: Bool
    let didAvoidRendererStateWriteWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        completionObservationAdmissionGuard:
            CjguiInternalRendererCompletionObservationAdmissionGuard,
        didPrepareRendererRollbackAdmissionPolicy: Bool,
        shouldDeferRendererRollbackAdmissionPolicy: Bool,
        shouldReportRendererRollbackAdmissionPolicyBlocked: Bool,
        didPreserveRendererCompletionObservationAdmissionGuard: Bool,
        didDefineFutureRollbackAdmissionPolicy: Bool,
        didDescribeRollbackAdmissionFacts: Bool,
        didDescribeFailureContainmentFacts: Bool,
        didDescribeNoDrawFallbackFacts: Bool,
        didConfirmNoRollbackCallback: Bool,
        didConfirmNoRendererStateMutation: Bool,
        didConfirmNoExternalPublication: Bool,
        didKeepRollbackAdmissionPolicyValueOnly: Bool,
        didAvoidRendererStateWriteWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.completionObservationAdmissionGuard =
            completionObservationAdmissionGuard
        this.didPrepareRendererRollbackAdmissionPolicy =
            didPrepareRendererRollbackAdmissionPolicy
        this.shouldDeferRendererRollbackAdmissionPolicy =
            shouldDeferRendererRollbackAdmissionPolicy
        this.shouldReportRendererRollbackAdmissionPolicyBlocked =
            shouldReportRendererRollbackAdmissionPolicyBlocked
        this.didPreserveRendererCompletionObservationAdmissionGuard =
            didPreserveRendererCompletionObservationAdmissionGuard
        this.didDefineFutureRollbackAdmissionPolicy =
            didDefineFutureRollbackAdmissionPolicy
        this.didDescribeRollbackAdmissionFacts =
            didDescribeRollbackAdmissionFacts
        this.didDescribeFailureContainmentFacts =
            didDescribeFailureContainmentFacts
        this.didDescribeNoDrawFallbackFacts =
            didDescribeNoDrawFallbackFacts
        this.didConfirmNoRollbackCallback = didConfirmNoRollbackCallback
        this.didConfirmNoRendererStateMutation =
            didConfirmNoRendererStateMutation
        this.didConfirmNoExternalPublication =
            didConfirmNoExternalPublication
        this.didKeepRollbackAdmissionPolicyValueOnly =
            didKeepRollbackAdmissionPolicyValueOnly
        this.didAvoidRendererStateWriteWrapper =
            didAvoidRendererStateWriteWrapper
        this.didAvoidRenderPermissionWrapper =
            didAvoidRenderPermissionWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoRenderExecutionImplementationReadiness {
    let rollbackAdmissionPolicy:
        CjguiInternalRendererRollbackAdmissionPolicy
    let isRendererNoRenderExecutionImplementationReady: Bool
    let canFutureRendererRenderExecutionImplementationBoundaryEvaluate: Bool
    let shouldDeferRendererNoRenderExecutionImplementationReadiness: Bool
    let shouldReportRendererNoRenderExecutionImplementationReadinessBlocked:
        Bool
    let didSealRendererNoRenderExecutionImplementationReadiness: Bool
    let didPreserveRendererRollbackAdmissionPolicy: Bool
    let didKeepNoRenderExecutionImplementationReadinessValueOnly: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoGpuWork: Bool
    let didConfirmNoCommandObjectWork: Bool
    let didConfirmNoEncoderObject: Bool
    let didConfirmNoDrawCommand: Bool
    let didConfirmNoPipelineUse: Bool
    let didConfirmNoResourceBinding: Bool
    let didConfirmNoForeignDeclaration: Bool
    let didConfirmNoForeignInvocation: Bool
    let didConfirmNoExternalHandle: Bool
    let didConfirmNoPointerResource: Bool
    let didConfirmNoRenderStateMutation: Bool
    let didAvoidRenderReadyPermissionWrapper: Bool
    let didAvoidCompletionPermissionWrapper: Bool
    let didAvoidCommandWorkPermissionWrapper: Bool
    let didAvoidPresentationPermissionWrapper: Bool
    let didAvoidGpuWorkWrapper: Bool
    let didAvoidStateWriteWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        rollbackAdmissionPolicy:
            CjguiInternalRendererRollbackAdmissionPolicy,
        isRendererNoRenderExecutionImplementationReady: Bool,
        canFutureRendererRenderExecutionImplementationBoundaryEvaluate: Bool,
        shouldDeferRendererNoRenderExecutionImplementationReadiness: Bool,
        shouldReportRendererNoRenderExecutionImplementationReadinessBlocked:
            Bool,
        didSealRendererNoRenderExecutionImplementationReadiness: Bool,
        didPreserveRendererRollbackAdmissionPolicy: Bool,
        didKeepNoRenderExecutionImplementationReadinessValueOnly: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoGpuWork: Bool,
        didConfirmNoCommandObjectWork: Bool,
        didConfirmNoEncoderObject: Bool,
        didConfirmNoDrawCommand: Bool,
        didConfirmNoPipelineUse: Bool,
        didConfirmNoResourceBinding: Bool,
        didConfirmNoForeignDeclaration: Bool,
        didConfirmNoForeignInvocation: Bool,
        didConfirmNoExternalHandle: Bool,
        didConfirmNoPointerResource: Bool,
        didConfirmNoRenderStateMutation: Bool,
        didAvoidRenderReadyPermissionWrapper: Bool,
        didAvoidCompletionPermissionWrapper: Bool,
        didAvoidCommandWorkPermissionWrapper: Bool,
        didAvoidPresentationPermissionWrapper: Bool,
        didAvoidGpuWorkWrapper: Bool,
        didAvoidStateWriteWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.rollbackAdmissionPolicy = rollbackAdmissionPolicy
        this.isRendererNoRenderExecutionImplementationReady =
            isRendererNoRenderExecutionImplementationReady
        this.canFutureRendererRenderExecutionImplementationBoundaryEvaluate =
            canFutureRendererRenderExecutionImplementationBoundaryEvaluate
        this.shouldDeferRendererNoRenderExecutionImplementationReadiness =
            shouldDeferRendererNoRenderExecutionImplementationReadiness
        this
            .shouldReportRendererNoRenderExecutionImplementationReadinessBlocked =
            shouldReportRendererNoRenderExecutionImplementationReadinessBlocked
        this.didSealRendererNoRenderExecutionImplementationReadiness =
            didSealRendererNoRenderExecutionImplementationReadiness
        this.didPreserveRendererRollbackAdmissionPolicy =
            didPreserveRendererRollbackAdmissionPolicy
        this.didKeepNoRenderExecutionImplementationReadinessValueOnly =
            didKeepNoRenderExecutionImplementationReadinessValueOnly
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoGpuWork = didConfirmNoGpuWork
        this.didConfirmNoCommandObjectWork = didConfirmNoCommandObjectWork
        this.didConfirmNoEncoderObject = didConfirmNoEncoderObject
        this.didConfirmNoDrawCommand = didConfirmNoDrawCommand
        this.didConfirmNoPipelineUse = didConfirmNoPipelineUse
        this.didConfirmNoResourceBinding = didConfirmNoResourceBinding
        this.didConfirmNoForeignDeclaration = didConfirmNoForeignDeclaration
        this.didConfirmNoForeignInvocation = didConfirmNoForeignInvocation
        this.didConfirmNoExternalHandle = didConfirmNoExternalHandle
        this.didConfirmNoPointerResource = didConfirmNoPointerResource
        this.didConfirmNoRenderStateMutation =
            didConfirmNoRenderStateMutation
        this.didAvoidRenderReadyPermissionWrapper =
            didAvoidRenderReadyPermissionWrapper
        this.didAvoidCompletionPermissionWrapper =
            didAvoidCompletionPermissionWrapper
        this.didAvoidCommandWorkPermissionWrapper =
            didAvoidCommandWorkPermissionWrapper
        this.didAvoidPresentationPermissionWrapper =
            didAvoidPresentationPermissionWrapper
        this.didAvoidGpuWorkWrapper = didAvoidGpuWorkWrapper
        this.didAvoidStateWriteWrapper = didAvoidStateWriteWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererRenderExecutionImplementationIntent(
    noDrawCallImplementationReadiness:
        CjguiInternalRendererNoDrawCallImplementationReadiness
): CjguiInternalRendererRenderExecutionImplementationIntent {
    let upstreamEndpointReady =
        noDrawCallImplementationReadiness
            .isRendererNoDrawCallImplementationReady
    let upstreamCanEvaluate =
        noDrawCallImplementationReadiness
            .canFutureRendererDrawCallImplementationBoundaryEvaluate
    let upstreamShouldDefer =
        noDrawCallImplementationReadiness
            .shouldDeferRendererNoDrawCallImplementationReadiness
    let upstreamBlocked =
        noDrawCallImplementationReadiness
            .shouldReportRendererNoDrawCallImplementationReadinessBlocked
    let upstreamReady =
        upstreamEndpointReady &&
        upstreamCanEvaluate &&
        noDrawCallImplementationReadiness
            .didSealRendererNoDrawCallImplementationReadiness &&
        noDrawCallImplementationReadiness
            .didPreserveRendererDrawOrderingAdmissionPolicy &&
        noDrawCallImplementationReadiness
            .didKeepNoDrawCallImplementationReadinessValueOnly &&
        noDrawCallImplementationReadiness.didConfirmNoDrawCommand &&
        noDrawCallImplementationReadiness
            .didConfirmNoPrimitiveCommandInvocation &&
        noDrawCallImplementationReadiness.didConfirmNoGeometryResourceHeld &&
        noDrawCallImplementationReadiness.didConfirmNoTextureResourceHeld &&
        noDrawCallImplementationReadiness.didConfirmNoSamplerResourceHeld &&
        noDrawCallImplementationReadiness.didConfirmNoPipelineUse &&
        noDrawCallImplementationReadiness.didConfirmNoEncoderObject &&
        noDrawCallImplementationReadiness.didConfirmNoCommandBufferObject &&
        noDrawCallImplementationReadiness.didConfirmNoGpuWork &&
        noDrawCallImplementationReadiness.didConfirmNoRenderExecution &&
        noDrawCallImplementationReadiness.didConfirmNoRenderStateMutation &&
        noDrawCallImplementationReadiness.didAvoidDrawReadyPermissionWrapper &&
        noDrawCallImplementationReadiness
            .didAvoidPrimitiveCommandPermissionWrapper &&
        noDrawCallImplementationReadiness.didAvoidGeometryPermissionWrapper &&
        noDrawCallImplementationReadiness.didAvoidResourcePermissionWrapper &&
        noDrawCallImplementationReadiness.didAvoidPipelinePermissionWrapper &&
        noDrawCallImplementationReadiness.didAvoidEncoderPermissionWrapper &&
        noDrawCallImplementationReadiness.didAvoidGpuWorkWrapper &&
        noDrawCallImplementationReadiness.didAvoidRenderPermissionWrapper &&
        noDrawCallImplementationReadiness.didAvoidStateWriteWrapper &&
        noDrawCallImplementationReadiness.didAvoidReceiptRecordOutput &&
        noDrawCallImplementationReadiness.didAvoidThinWrapper &&
        noDrawCallImplementationReadiness.didStayFullRebuildOnly &&
        upstreamShouldDefer == false &&
        upstreamBlocked == false
    let upstreamDeferred = upstreamShouldDefer && upstreamBlocked == false
    let upstreamInconsistent =
        upstreamBlocked ||
        (upstreamCanEvaluate && upstreamEndpointReady == false) ||
        (upstreamShouldDefer && upstreamBlocked)

    if (upstreamInconsistent) {
        return CjguiInternalRendererRenderExecutionImplementationIntent(
            noDrawCallImplementationReadiness,
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

    if (upstreamDeferred || upstreamReady == false) {
        return CjguiInternalRendererRenderExecutionImplementationIntent(
            noDrawCallImplementationReadiness,
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

    return CjguiInternalRendererRenderExecutionImplementationIntent(
        noDrawCallImplementationReadiness,
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

func cjguiInternalBuildRendererExecutionAdmissionPolicy(
    implementationIntent:
        CjguiInternalRendererRenderExecutionImplementationIntent
): CjguiInternalRendererExecutionAdmissionPolicy {
    let intentPrepared =
        implementationIntent
            .didPrepareRendererRenderExecutionImplementationIntent
    let intentShouldDefer =
        implementationIntent
            .shouldDeferRendererRenderExecutionImplementationIntent
    let intentBlocked =
        implementationIntent
            .shouldReportRendererRenderExecutionImplementationIntentBlocked
    let intentReady =
        intentPrepared &&
        implementationIntent
            .didPreserveRendererNoDrawCallImplementationReadiness &&
        implementationIntent
            .didDefineFutureRenderExecutionImplementationIntent &&
        implementationIntent.didDescribeExecutionAdmissionNeed &&
        implementationIntent.didDescribeCompletionObservationAdmissionNeed &&
        implementationIntent.didDescribeRollbackAdmissionNeed &&
        implementationIntent
            .didKeepRenderExecutionImplementationIntentValueOnly &&
        implementationIntent.didAvoidRenderReadyPermissionWrapper &&
        implementationIntent.didAvoidCommandWorkPermissionWrapper &&
        implementationIntent.didAvoidReceiptRecordOutput &&
        implementationIntent.didAvoidThinWrapper &&
        intentShouldDefer == false &&
        intentBlocked == false
    let intentDeferred = intentShouldDefer && intentBlocked == false
    let intentInconsistent =
        intentBlocked ||
        (intentPrepared && intentReady == false) ||
        (intentShouldDefer && intentBlocked)

    if (intentInconsistent) {
        return CjguiInternalRendererExecutionAdmissionPolicy(
            implementationIntent,
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
            true,
            true
        )
    }

    if (intentDeferred || intentReady == false) {
        return CjguiInternalRendererExecutionAdmissionPolicy(
            implementationIntent,
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
            true,
            true
        )
    }

    return CjguiInternalRendererExecutionAdmissionPolicy(
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
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererCompletionObservationAdmissionGuard(
    executionAdmissionPolicy:
        CjguiInternalRendererExecutionAdmissionPolicy
): CjguiInternalRendererCompletionObservationAdmissionGuard {
    let executionReady =
        executionAdmissionPolicy.didPrepareRendererExecutionAdmissionPolicy &&
        executionAdmissionPolicy
            .didPreserveRendererRenderExecutionImplementationIntent &&
        executionAdmissionPolicy.didDefineFutureExecutionAdmissionPolicy &&
        executionAdmissionPolicy.didDescribeFrameExecutionAdmissionFacts &&
        executionAdmissionPolicy.didDescribeCommandWorkAdmissionFacts &&
        executionAdmissionPolicy.didDescribeNoGpuWorkFacts &&
        executionAdmissionPolicy.didConfirmNoRenderExecution &&
        executionAdmissionPolicy.didConfirmNoGpuWork &&
        executionAdmissionPolicy.didConfirmNoCommandObjectWork &&
        executionAdmissionPolicy.didKeepExecutionAdmissionPolicyValueOnly &&
        executionAdmissionPolicy.didAvoidRenderPermissionWrapper &&
        executionAdmissionPolicy.didAvoidCommandWorkPermissionWrapper &&
        executionAdmissionPolicy.didAvoidGpuWorkWrapper &&
        executionAdmissionPolicy.didAvoidThinWrapper &&
        executionAdmissionPolicy
            .shouldDeferRendererExecutionAdmissionPolicy == false &&
        executionAdmissionPolicy
            .shouldReportRendererExecutionAdmissionPolicyBlocked == false
    let executionDeferred =
        executionAdmissionPolicy.shouldDeferRendererExecutionAdmissionPolicy &&
        executionAdmissionPolicy
            .shouldReportRendererExecutionAdmissionPolicyBlocked == false
    let executionInconsistent =
        executionAdmissionPolicy
            .shouldReportRendererExecutionAdmissionPolicyBlocked ||
        (
            executionAdmissionPolicy
                .didPrepareRendererExecutionAdmissionPolicy &&
            executionReady == false
        ) ||
        (
            executionAdmissionPolicy
                .shouldDeferRendererExecutionAdmissionPolicy &&
            executionAdmissionPolicy
                .shouldReportRendererExecutionAdmissionPolicyBlocked
        )

    if (executionInconsistent) {
        return CjguiInternalRendererCompletionObservationAdmissionGuard(
            executionAdmissionPolicy,
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
            true,
            true
        )
    }

    if (executionDeferred || executionReady == false) {
        return CjguiInternalRendererCompletionObservationAdmissionGuard(
            executionAdmissionPolicy,
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
            true,
            true
        )
    }

    return CjguiInternalRendererCompletionObservationAdmissionGuard(
        executionAdmissionPolicy,
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

func cjguiInternalBuildRendererRollbackAdmissionPolicy(
    completionObservationAdmissionGuard:
        CjguiInternalRendererCompletionObservationAdmissionGuard
): CjguiInternalRendererRollbackAdmissionPolicy {
    let completionReady =
        completionObservationAdmissionGuard
            .didPrepareRendererCompletionObservationAdmissionGuard &&
        completionObservationAdmissionGuard
            .didPreserveRendererExecutionAdmissionPolicy &&
        completionObservationAdmissionGuard
            .didDefineFutureCompletionObservationAdmissionGuard &&
        completionObservationAdmissionGuard
            .didDescribeCompletionObservationFacts &&
        completionObservationAdmissionGuard.didDescribeFailureObservationFacts &&
        completionObservationAdmissionGuard.didDescribeNoCallbackFacts &&
        completionObservationAdmissionGuard.didConfirmNoCompletionCallback &&
        completionObservationAdmissionGuard
            .didConfirmNoRealCompletionObservation &&
        completionObservationAdmissionGuard.didConfirmNoTelemetryPublication &&
        completionObservationAdmissionGuard
            .didKeepCompletionObservationAdmissionGuardValueOnly &&
        completionObservationAdmissionGuard.didAvoidCompletionPermissionWrapper &&
        completionObservationAdmissionGuard.didAvoidStateWriteWrapper &&
        completionObservationAdmissionGuard.didAvoidReceiptRecordOutput &&
        completionObservationAdmissionGuard.didAvoidThinWrapper &&
        completionObservationAdmissionGuard
            .shouldDeferRendererCompletionObservationAdmissionGuard == false &&
        completionObservationAdmissionGuard
            .shouldReportRendererCompletionObservationAdmissionGuardBlocked ==
            false
    let completionDeferred =
        completionObservationAdmissionGuard
            .shouldDeferRendererCompletionObservationAdmissionGuard &&
        completionObservationAdmissionGuard
            .shouldReportRendererCompletionObservationAdmissionGuardBlocked ==
            false
    let completionInconsistent =
        completionObservationAdmissionGuard
            .shouldReportRendererCompletionObservationAdmissionGuardBlocked ||
        (
            completionObservationAdmissionGuard
                .didPrepareRendererCompletionObservationAdmissionGuard &&
            completionReady == false
        ) ||
        (
            completionObservationAdmissionGuard
                .shouldDeferRendererCompletionObservationAdmissionGuard &&
            completionObservationAdmissionGuard
                .shouldReportRendererCompletionObservationAdmissionGuardBlocked
        )

    if (completionInconsistent) {
        return CjguiInternalRendererRollbackAdmissionPolicy(
            completionObservationAdmissionGuard,
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
            true,
            true
        )
    }

    if (completionDeferred || completionReady == false) {
        return CjguiInternalRendererRollbackAdmissionPolicy(
            completionObservationAdmissionGuard,
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
            true,
            true
        )
    }

    return CjguiInternalRendererRollbackAdmissionPolicy(
        completionObservationAdmissionGuard,
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

func cjguiInternalBuildRendererNoRenderExecutionImplementationReadiness(
    rollbackAdmissionPolicy:
        CjguiInternalRendererRollbackAdmissionPolicy
): CjguiInternalRendererNoRenderExecutionImplementationReadiness {
    let rollbackReady =
        rollbackAdmissionPolicy.didPrepareRendererRollbackAdmissionPolicy &&
        rollbackAdmissionPolicy
            .didPreserveRendererCompletionObservationAdmissionGuard &&
        rollbackAdmissionPolicy.didDefineFutureRollbackAdmissionPolicy &&
        rollbackAdmissionPolicy.didDescribeRollbackAdmissionFacts &&
        rollbackAdmissionPolicy.didDescribeFailureContainmentFacts &&
        rollbackAdmissionPolicy.didDescribeNoDrawFallbackFacts &&
        rollbackAdmissionPolicy.didConfirmNoRollbackCallback &&
        rollbackAdmissionPolicy.didConfirmNoRendererStateMutation &&
        rollbackAdmissionPolicy.didConfirmNoExternalPublication &&
        rollbackAdmissionPolicy.didKeepRollbackAdmissionPolicyValueOnly &&
        rollbackAdmissionPolicy.didAvoidRendererStateWriteWrapper &&
        rollbackAdmissionPolicy.didAvoidRenderPermissionWrapper &&
        rollbackAdmissionPolicy.didAvoidReceiptRecordOutput &&
        rollbackAdmissionPolicy.didAvoidThinWrapper &&
        rollbackAdmissionPolicy
            .shouldDeferRendererRollbackAdmissionPolicy == false &&
        rollbackAdmissionPolicy
            .shouldReportRendererRollbackAdmissionPolicyBlocked == false
    let rollbackDeferred =
        rollbackAdmissionPolicy.shouldDeferRendererRollbackAdmissionPolicy &&
        rollbackAdmissionPolicy
            .shouldReportRendererRollbackAdmissionPolicyBlocked == false
    let rollbackInconsistent =
        rollbackAdmissionPolicy
            .shouldReportRendererRollbackAdmissionPolicyBlocked ||
        (
            rollbackAdmissionPolicy
                .didPrepareRendererRollbackAdmissionPolicy &&
            rollbackReady == false
        ) ||
        (
            rollbackAdmissionPolicy
                .shouldDeferRendererRollbackAdmissionPolicy &&
            rollbackAdmissionPolicy
                .shouldReportRendererRollbackAdmissionPolicyBlocked
        )

    if (rollbackInconsistent) {
        return CjguiInternalRendererNoRenderExecutionImplementationReadiness(
            rollbackAdmissionPolicy,
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
            true
        )
    }

    if (rollbackDeferred || rollbackReady == false) {
        return CjguiInternalRendererNoRenderExecutionImplementationReadiness(
            rollbackAdmissionPolicy,
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
            true
        )
    }

    return CjguiInternalRendererNoRenderExecutionImplementationReadiness(
        rollbackAdmissionPolicy,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererRenderExecutionAdmissionDraft():
    CjguiInternalRendererNoRenderExecutionImplementationReadiness {
    let noDrawCallImplementationReadiness =
        cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()
    let implementationIntent =
        cjguiInternalBuildRendererRenderExecutionImplementationIntent(
            noDrawCallImplementationReadiness
        )
    let executionAdmissionPolicy =
        cjguiInternalBuildRendererExecutionAdmissionPolicy(
            implementationIntent
        )
    let completionObservationAdmissionGuard =
        cjguiInternalBuildRendererCompletionObservationAdmissionGuard(
            executionAdmissionPolicy
        )
    let rollbackAdmissionPolicy =
        cjguiInternalBuildRendererRollbackAdmissionPolicy(
            completionObservationAdmissionGuard
        )
    return cjguiInternalBuildRendererNoRenderExecutionImplementationReadiness(
        rollbackAdmissionPolicy
    )
}
