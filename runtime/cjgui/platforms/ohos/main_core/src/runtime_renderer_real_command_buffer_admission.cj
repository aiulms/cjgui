// Owner：本文件固定 real command buffer implementation admission 的 internal-only owner 边界。
// Truth：唯一 runtime input 是 CjguiInternalRendererNoRealDrawableImplementationReadiness，
// canonical endpoint 是 CjguiInternalRendererNoRealCommandBufferImplementationReadiness。
// Stop-line：只生成 value facts，不创建缓冲对象，不调用外部队列/提交/绘制通路，
// 不创建图形阶段对象，不持有外部资源或指针，不写 renderer 状态，不开放接口。
// Same-shape Boundary Brake：本文件新增 creation / single-use / failure admission
// 语义，不把上一层 readiness 包成 permission wrapper、receipt、record 或发布凭据。
package cjgui

struct CjguiInternalRendererRealCommandBufferImplementationIntent {
    let noRealDrawableImplementationReadiness:
        CjguiInternalRendererNoRealDrawableImplementationReadiness
    let didPrepareRendererRealCommandBufferImplementationIntent: Bool
    let shouldDeferRendererRealCommandBufferImplementationIntent: Bool
    let shouldReportRendererRealCommandBufferImplementationIntentBlocked: Bool
    let didPreserveRendererNoRealDrawableImplementationReadiness: Bool
    let didDefineFutureRealCommandBufferImplementationIntent: Bool
    let didDescribeBufferCreationAdmissionNeed: Bool
    let didDescribeSingleUseAdmissionNeed: Bool
    let didDescribeBufferFailurePolicyNeed: Bool
    let didKeepRealCommandBufferImplementationIntentValueOnly: Bool
    let didAvoidBufferReadyPermissionWrapper: Bool
    let didAvoidBackendImplementationWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        noRealDrawableImplementationReadiness:
            CjguiInternalRendererNoRealDrawableImplementationReadiness,
        didPrepareRendererRealCommandBufferImplementationIntent: Bool,
        shouldDeferRendererRealCommandBufferImplementationIntent: Bool,
        shouldReportRendererRealCommandBufferImplementationIntentBlocked: Bool,
        didPreserveRendererNoRealDrawableImplementationReadiness: Bool,
        didDefineFutureRealCommandBufferImplementationIntent: Bool,
        didDescribeBufferCreationAdmissionNeed: Bool,
        didDescribeSingleUseAdmissionNeed: Bool,
        didDescribeBufferFailurePolicyNeed: Bool,
        didKeepRealCommandBufferImplementationIntentValueOnly: Bool,
        didAvoidBufferReadyPermissionWrapper: Bool,
        didAvoidBackendImplementationWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noRealDrawableImplementationReadiness =
            noRealDrawableImplementationReadiness
        this.didPrepareRendererRealCommandBufferImplementationIntent =
            didPrepareRendererRealCommandBufferImplementationIntent
        this.shouldDeferRendererRealCommandBufferImplementationIntent =
            shouldDeferRendererRealCommandBufferImplementationIntent
        this.shouldReportRendererRealCommandBufferImplementationIntentBlocked =
            shouldReportRendererRealCommandBufferImplementationIntentBlocked
        this.didPreserveRendererNoRealDrawableImplementationReadiness =
            didPreserveRendererNoRealDrawableImplementationReadiness
        this.didDefineFutureRealCommandBufferImplementationIntent =
            didDefineFutureRealCommandBufferImplementationIntent
        this.didDescribeBufferCreationAdmissionNeed =
            didDescribeBufferCreationAdmissionNeed
        this.didDescribeSingleUseAdmissionNeed =
            didDescribeSingleUseAdmissionNeed
        this.didDescribeBufferFailurePolicyNeed =
            didDescribeBufferFailurePolicyNeed
        this.didKeepRealCommandBufferImplementationIntentValueOnly =
            didKeepRealCommandBufferImplementationIntentValueOnly
        this.didAvoidBufferReadyPermissionWrapper =
            didAvoidBufferReadyPermissionWrapper
        this.didAvoidBackendImplementationWrapper =
            didAvoidBackendImplementationWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealCommandBufferCreationAdmissionPolicy {
    let implementationIntent:
        CjguiInternalRendererRealCommandBufferImplementationIntent
    let didPrepareRendererRealCommandBufferCreationAdmissionPolicy: Bool
    let shouldDeferRendererRealCommandBufferCreationAdmissionPolicy: Bool
    let shouldReportRendererRealCommandBufferCreationAdmissionPolicyBlocked: Bool
    let didPreserveRendererRealCommandBufferImplementationIntent: Bool
    let didDefineFutureBufferCreationAdmissionPolicy: Bool
    let didDescribeBufferFactoryAdmissionFacts: Bool
    let didDescribeNoBufferObjectFacts: Bool
    let didConfirmNoBufferObjectCreated: Bool
    let didConfirmNoBufferFactoryCall: Bool
    let didKeepBufferCreationAdmissionPolicyValueOnly: Bool
    let didAvoidBufferFactoryPermissionWrapper: Bool
    let didAvoidBufferReadyPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        implementationIntent:
            CjguiInternalRendererRealCommandBufferImplementationIntent,
        didPrepareRendererRealCommandBufferCreationAdmissionPolicy: Bool,
        shouldDeferRendererRealCommandBufferCreationAdmissionPolicy: Bool,
        shouldReportRendererRealCommandBufferCreationAdmissionPolicyBlocked: Bool,
        didPreserveRendererRealCommandBufferImplementationIntent: Bool,
        didDefineFutureBufferCreationAdmissionPolicy: Bool,
        didDescribeBufferFactoryAdmissionFacts: Bool,
        didDescribeNoBufferObjectFacts: Bool,
        didConfirmNoBufferObjectCreated: Bool,
        didConfirmNoBufferFactoryCall: Bool,
        didKeepBufferCreationAdmissionPolicyValueOnly: Bool,
        didAvoidBufferFactoryPermissionWrapper: Bool,
        didAvoidBufferReadyPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.implementationIntent = implementationIntent
        this.didPrepareRendererRealCommandBufferCreationAdmissionPolicy =
            didPrepareRendererRealCommandBufferCreationAdmissionPolicy
        this.shouldDeferRendererRealCommandBufferCreationAdmissionPolicy =
            shouldDeferRendererRealCommandBufferCreationAdmissionPolicy
        this.shouldReportRendererRealCommandBufferCreationAdmissionPolicyBlocked =
            shouldReportRendererRealCommandBufferCreationAdmissionPolicyBlocked
        this.didPreserveRendererRealCommandBufferImplementationIntent =
            didPreserveRendererRealCommandBufferImplementationIntent
        this.didDefineFutureBufferCreationAdmissionPolicy =
            didDefineFutureBufferCreationAdmissionPolicy
        this.didDescribeBufferFactoryAdmissionFacts =
            didDescribeBufferFactoryAdmissionFacts
        this.didDescribeNoBufferObjectFacts = didDescribeNoBufferObjectFacts
        this.didConfirmNoBufferObjectCreated = didConfirmNoBufferObjectCreated
        this.didConfirmNoBufferFactoryCall = didConfirmNoBufferFactoryCall
        this.didKeepBufferCreationAdmissionPolicyValueOnly =
            didKeepBufferCreationAdmissionPolicyValueOnly
        this.didAvoidBufferFactoryPermissionWrapper =
            didAvoidBufferFactoryPermissionWrapper
        this.didAvoidBufferReadyPermissionWrapper =
            didAvoidBufferReadyPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealCommandBufferSingleUseAdmissionGuard {
    let creationAdmissionPolicy:
        CjguiInternalRendererRealCommandBufferCreationAdmissionPolicy
    let didPrepareRendererRealCommandBufferSingleUseAdmissionGuard: Bool
    let shouldDeferRendererRealCommandBufferSingleUseAdmissionGuard: Bool
    let shouldReportRendererRealCommandBufferSingleUseAdmissionGuardBlocked: Bool
    let didPreserveRendererRealCommandBufferCreationAdmissionPolicy: Bool
    let didDefineFutureBufferSingleUseAdmissionGuard: Bool
    let didDescribeSingleUseAdmissionFacts: Bool
    let didDescribeNoPostSubmitReusableFacts: Bool
    let didConfirmNoBufferTokenHeld: Bool
    let didConfirmNoPostSubmitUsablePermission: Bool
    let didKeepBufferSingleUseAdmissionGuardValueOnly: Bool
    let didAvoidBufferReadyPermissionWrapper: Bool
    let didAvoidBufferSubmitPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        creationAdmissionPolicy:
            CjguiInternalRendererRealCommandBufferCreationAdmissionPolicy,
        didPrepareRendererRealCommandBufferSingleUseAdmissionGuard: Bool,
        shouldDeferRendererRealCommandBufferSingleUseAdmissionGuard: Bool,
        shouldReportRendererRealCommandBufferSingleUseAdmissionGuardBlocked: Bool,
        didPreserveRendererRealCommandBufferCreationAdmissionPolicy: Bool,
        didDefineFutureBufferSingleUseAdmissionGuard: Bool,
        didDescribeSingleUseAdmissionFacts: Bool,
        didDescribeNoPostSubmitReusableFacts: Bool,
        didConfirmNoBufferTokenHeld: Bool,
        didConfirmNoPostSubmitUsablePermission: Bool,
        didKeepBufferSingleUseAdmissionGuardValueOnly: Bool,
        didAvoidBufferReadyPermissionWrapper: Bool,
        didAvoidBufferSubmitPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.creationAdmissionPolicy = creationAdmissionPolicy
        this.didPrepareRendererRealCommandBufferSingleUseAdmissionGuard =
            didPrepareRendererRealCommandBufferSingleUseAdmissionGuard
        this.shouldDeferRendererRealCommandBufferSingleUseAdmissionGuard =
            shouldDeferRendererRealCommandBufferSingleUseAdmissionGuard
        this.shouldReportRendererRealCommandBufferSingleUseAdmissionGuardBlocked =
            shouldReportRendererRealCommandBufferSingleUseAdmissionGuardBlocked
        this.didPreserveRendererRealCommandBufferCreationAdmissionPolicy =
            didPreserveRendererRealCommandBufferCreationAdmissionPolicy
        this.didDefineFutureBufferSingleUseAdmissionGuard =
            didDefineFutureBufferSingleUseAdmissionGuard
        this.didDescribeSingleUseAdmissionFacts =
            didDescribeSingleUseAdmissionFacts
        this.didDescribeNoPostSubmitReusableFacts =
            didDescribeNoPostSubmitReusableFacts
        this.didConfirmNoBufferTokenHeld = didConfirmNoBufferTokenHeld
        this.didConfirmNoPostSubmitUsablePermission =
            didConfirmNoPostSubmitUsablePermission
        this.didKeepBufferSingleUseAdmissionGuardValueOnly =
            didKeepBufferSingleUseAdmissionGuardValueOnly
        this.didAvoidBufferReadyPermissionWrapper =
            didAvoidBufferReadyPermissionWrapper
        this.didAvoidBufferSubmitPermissionWrapper =
            didAvoidBufferSubmitPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealCommandBufferFailurePolicy {
    let singleUseAdmissionGuard:
        CjguiInternalRendererRealCommandBufferSingleUseAdmissionGuard
    let didPrepareRendererRealCommandBufferFailurePolicy: Bool
    let shouldDeferRendererRealCommandBufferFailurePolicy: Bool
    let shouldReportRendererRealCommandBufferFailurePolicyBlocked: Bool
    let didPreserveRendererRealCommandBufferSingleUseAdmissionGuard: Bool
    let didDefineFutureBufferFailurePolicy: Bool
    let didDescribeFailureAdmissionFacts: Bool
    let didDescribeNoCompletionObservationFacts: Bool
    let didConfirmNoCompletionCallbackRegistered: Bool
    let didConfirmNoGpuCompletionObserved: Bool
    let didKeepBufferFailurePolicyValueOnly: Bool
    let didAvoidGpuWorkWrapper: Bool
    let didAvoidStateWriteWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        singleUseAdmissionGuard:
            CjguiInternalRendererRealCommandBufferSingleUseAdmissionGuard,
        didPrepareRendererRealCommandBufferFailurePolicy: Bool,
        shouldDeferRendererRealCommandBufferFailurePolicy: Bool,
        shouldReportRendererRealCommandBufferFailurePolicyBlocked: Bool,
        didPreserveRendererRealCommandBufferSingleUseAdmissionGuard: Bool,
        didDefineFutureBufferFailurePolicy: Bool,
        didDescribeFailureAdmissionFacts: Bool,
        didDescribeNoCompletionObservationFacts: Bool,
        didConfirmNoCompletionCallbackRegistered: Bool,
        didConfirmNoGpuCompletionObserved: Bool,
        didKeepBufferFailurePolicyValueOnly: Bool,
        didAvoidGpuWorkWrapper: Bool,
        didAvoidStateWriteWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.singleUseAdmissionGuard = singleUseAdmissionGuard
        this.didPrepareRendererRealCommandBufferFailurePolicy =
            didPrepareRendererRealCommandBufferFailurePolicy
        this.shouldDeferRendererRealCommandBufferFailurePolicy =
            shouldDeferRendererRealCommandBufferFailurePolicy
        this.shouldReportRendererRealCommandBufferFailurePolicyBlocked =
            shouldReportRendererRealCommandBufferFailurePolicyBlocked
        this.didPreserveRendererRealCommandBufferSingleUseAdmissionGuard =
            didPreserveRendererRealCommandBufferSingleUseAdmissionGuard
        this.didDefineFutureBufferFailurePolicy =
            didDefineFutureBufferFailurePolicy
        this.didDescribeFailureAdmissionFacts =
            didDescribeFailureAdmissionFacts
        this.didDescribeNoCompletionObservationFacts =
            didDescribeNoCompletionObservationFacts
        this.didConfirmNoCompletionCallbackRegistered =
            didConfirmNoCompletionCallbackRegistered
        this.didConfirmNoGpuCompletionObserved =
            didConfirmNoGpuCompletionObserved
        this.didKeepBufferFailurePolicyValueOnly =
            didKeepBufferFailurePolicyValueOnly
        this.didAvoidGpuWorkWrapper = didAvoidGpuWorkWrapper
        this.didAvoidStateWriteWrapper = didAvoidStateWriteWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoRealCommandBufferImplementationReadiness {
    let failurePolicy:
        CjguiInternalRendererRealCommandBufferFailurePolicy
    let isRendererNoRealCommandBufferImplementationReady: Bool
    let canFutureRendererRealCommandBufferImplementationBoundaryEvaluate: Bool
    let shouldDeferRendererNoRealCommandBufferImplementationReadiness: Bool
    let shouldReportRendererNoRealCommandBufferImplementationReadinessBlocked: Bool
    let didSealRendererNoRealCommandBufferImplementationReadiness: Bool
    let didPreserveRendererRealCommandBufferFailurePolicy: Bool
    let didKeepNoRealCommandBufferImplementationReadinessValueOnly: Bool
    let didConfirmNoBufferObjectCreated: Bool
    let didConfirmNoBufferFactoryCall: Bool
    let didConfirmNoSubmitCall: Bool
    let didConfirmNoStageObjectsCreated: Bool
    let didConfirmNoDrawableInteraction: Bool
    let didConfirmNoForeignDeclaration: Bool
    let didConfirmNoExternalSurface: Bool
    let didConfirmNoForeignInvocation: Bool
    let didConfirmNoResourceToken: Bool
    let didConfirmNoPointerResource: Bool
    let didConfirmNoGpuWork: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoRenderStateMutation: Bool
    let didAvoidBufferReadyPermissionWrapper: Bool
    let didAvoidBufferFactoryPermissionWrapper: Bool
    let didAvoidBufferSubmitPermissionWrapper: Bool
    let didAvoidResourcePermissionWrapper: Bool
    let didAvoidExternalSurfacePermissionWrapper: Bool
    let didAvoidGpuWorkWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidStateWriteWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        failurePolicy:
            CjguiInternalRendererRealCommandBufferFailurePolicy,
        isRendererNoRealCommandBufferImplementationReady: Bool,
        canFutureRendererRealCommandBufferImplementationBoundaryEvaluate: Bool,
        shouldDeferRendererNoRealCommandBufferImplementationReadiness: Bool,
        shouldReportRendererNoRealCommandBufferImplementationReadinessBlocked:
            Bool,
        didSealRendererNoRealCommandBufferImplementationReadiness: Bool,
        didPreserveRendererRealCommandBufferFailurePolicy: Bool,
        didKeepNoRealCommandBufferImplementationReadinessValueOnly: Bool,
        didConfirmNoBufferObjectCreated: Bool,
        didConfirmNoBufferFactoryCall: Bool,
        didConfirmNoSubmitCall: Bool,
        didConfirmNoStageObjectsCreated: Bool,
        didConfirmNoDrawableInteraction: Bool,
        didConfirmNoForeignDeclaration: Bool,
        didConfirmNoExternalSurface: Bool,
        didConfirmNoForeignInvocation: Bool,
        didConfirmNoResourceToken: Bool,
        didConfirmNoPointerResource: Bool,
        didConfirmNoGpuWork: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoRenderStateMutation: Bool,
        didAvoidBufferReadyPermissionWrapper: Bool,
        didAvoidBufferFactoryPermissionWrapper: Bool,
        didAvoidBufferSubmitPermissionWrapper: Bool,
        didAvoidResourcePermissionWrapper: Bool,
        didAvoidExternalSurfacePermissionWrapper: Bool,
        didAvoidGpuWorkWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidStateWriteWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.failurePolicy = failurePolicy
        this.isRendererNoRealCommandBufferImplementationReady =
            isRendererNoRealCommandBufferImplementationReady
        this.canFutureRendererRealCommandBufferImplementationBoundaryEvaluate =
            canFutureRendererRealCommandBufferImplementationBoundaryEvaluate
        this.shouldDeferRendererNoRealCommandBufferImplementationReadiness =
            shouldDeferRendererNoRealCommandBufferImplementationReadiness
        this.shouldReportRendererNoRealCommandBufferImplementationReadinessBlocked =
            shouldReportRendererNoRealCommandBufferImplementationReadinessBlocked
        this.didSealRendererNoRealCommandBufferImplementationReadiness =
            didSealRendererNoRealCommandBufferImplementationReadiness
        this.didPreserveRendererRealCommandBufferFailurePolicy =
            didPreserveRendererRealCommandBufferFailurePolicy
        this.didKeepNoRealCommandBufferImplementationReadinessValueOnly =
            didKeepNoRealCommandBufferImplementationReadinessValueOnly
        this.didConfirmNoBufferObjectCreated = didConfirmNoBufferObjectCreated
        this.didConfirmNoBufferFactoryCall = didConfirmNoBufferFactoryCall
        this.didConfirmNoSubmitCall = didConfirmNoSubmitCall
        this.didConfirmNoStageObjectsCreated =
            didConfirmNoStageObjectsCreated
        this.didConfirmNoDrawableInteraction = didConfirmNoDrawableInteraction
        this.didConfirmNoForeignDeclaration = didConfirmNoForeignDeclaration
        this.didConfirmNoExternalSurface = didConfirmNoExternalSurface
        this.didConfirmNoForeignInvocation = didConfirmNoForeignInvocation
        this.didConfirmNoResourceToken = didConfirmNoResourceToken
        this.didConfirmNoPointerResource = didConfirmNoPointerResource
        this.didConfirmNoGpuWork = didConfirmNoGpuWork
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoRenderStateMutation = didConfirmNoRenderStateMutation
        this.didAvoidBufferReadyPermissionWrapper =
            didAvoidBufferReadyPermissionWrapper
        this.didAvoidBufferFactoryPermissionWrapper =
            didAvoidBufferFactoryPermissionWrapper
        this.didAvoidBufferSubmitPermissionWrapper =
            didAvoidBufferSubmitPermissionWrapper
        this.didAvoidResourcePermissionWrapper =
            didAvoidResourcePermissionWrapper
        this.didAvoidExternalSurfacePermissionWrapper =
            didAvoidExternalSurfacePermissionWrapper
        this.didAvoidGpuWorkWrapper = didAvoidGpuWorkWrapper
        this.didAvoidRenderPermissionWrapper =
            didAvoidRenderPermissionWrapper
        this.didAvoidStateWriteWrapper = didAvoidStateWriteWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererRealCommandBufferImplementationIntent(
    noRealDrawableImplementationReadiness:
        CjguiInternalRendererNoRealDrawableImplementationReadiness
): CjguiInternalRendererRealCommandBufferImplementationIntent {
    let upstreamReady =
        noRealDrawableImplementationReadiness
            .isRendererNoRealDrawableImplementationReady &&
        noRealDrawableImplementationReadiness
            .canFutureRendererRealDrawableImplementationBoundaryEvaluate &&
        noRealDrawableImplementationReadiness
            .didSealRendererNoRealDrawableImplementationReadiness &&
        noRealDrawableImplementationReadiness
            .didPreserveRendererRealDrawablePresentationAdmissionPolicy &&
        noRealDrawableImplementationReadiness
            .didKeepNoRealDrawableImplementationReadinessValueOnly &&
        noRealDrawableImplementationReadiness.didConfirmNoCommandBufferCreated &&
        noRealDrawableImplementationReadiness.didConfirmNoWorkSubmit &&
        noRealDrawableImplementationReadiness.didConfirmNoRenderExecution &&
        noRealDrawableImplementationReadiness.didConfirmNoRendererStateMutation &&
        noRealDrawableImplementationReadiness.didAvoidBackendImplementationWrapper &&
        noRealDrawableImplementationReadiness.didAvoidWorkSubmitWrapper &&
        noRealDrawableImplementationReadiness.didAvoidRenderPermissionWrapper &&
        noRealDrawableImplementationReadiness.didAvoidStateWriteWrapper &&
        noRealDrawableImplementationReadiness.didAvoidReceiptRecordOutput &&
        noRealDrawableImplementationReadiness.didAvoidThinWrapper &&
        noRealDrawableImplementationReadiness
            .shouldDeferRendererNoRealDrawableImplementationReadiness == false &&
        noRealDrawableImplementationReadiness
            .shouldReportRendererNoRealDrawableImplementationReadinessBlocked == false
    let upstreamDeferred =
        noRealDrawableImplementationReadiness
            .shouldDeferRendererNoRealDrawableImplementationReadiness &&
        noRealDrawableImplementationReadiness
            .shouldReportRendererNoRealDrawableImplementationReadinessBlocked == false
    let upstreamInconsistent =
        noRealDrawableImplementationReadiness
            .shouldReportRendererNoRealDrawableImplementationReadinessBlocked ||
        (
            noRealDrawableImplementationReadiness
                .canFutureRendererRealDrawableImplementationBoundaryEvaluate &&
            noRealDrawableImplementationReadiness
                .isRendererNoRealDrawableImplementationReady == false
        ) ||
        (
            noRealDrawableImplementationReadiness
                .shouldDeferRendererNoRealDrawableImplementationReadiness &&
            noRealDrawableImplementationReadiness
                .shouldReportRendererNoRealDrawableImplementationReadinessBlocked
        )

    if (upstreamInconsistent) {
        return CjguiInternalRendererRealCommandBufferImplementationIntent(
            noRealDrawableImplementationReadiness,
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
        return CjguiInternalRendererRealCommandBufferImplementationIntent(
            noRealDrawableImplementationReadiness,
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

    return CjguiInternalRendererRealCommandBufferImplementationIntent(
        noRealDrawableImplementationReadiness,
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

func cjguiInternalBuildRendererRealCommandBufferCreationAdmissionPolicy(
    implementationIntent:
        CjguiInternalRendererRealCommandBufferImplementationIntent
): CjguiInternalRendererRealCommandBufferCreationAdmissionPolicy {
    let intentReady =
        implementationIntent
            .didPrepareRendererRealCommandBufferImplementationIntent &&
        implementationIntent
            .didPreserveRendererNoRealDrawableImplementationReadiness &&
        implementationIntent.didDefineFutureRealCommandBufferImplementationIntent &&
        implementationIntent.didDescribeBufferCreationAdmissionNeed &&
        implementationIntent.didDescribeSingleUseAdmissionNeed &&
        implementationIntent.didDescribeBufferFailurePolicyNeed &&
        implementationIntent.didKeepRealCommandBufferImplementationIntentValueOnly &&
        implementationIntent.didAvoidBufferReadyPermissionWrapper &&
        implementationIntent.didAvoidBackendImplementationWrapper &&
        implementationIntent.didAvoidReceiptRecordOutput &&
        implementationIntent.didAvoidThinWrapper &&
        implementationIntent
            .shouldDeferRendererRealCommandBufferImplementationIntent == false &&
        implementationIntent
            .shouldReportRendererRealCommandBufferImplementationIntentBlocked == false
    let intentDeferred =
        implementationIntent
            .shouldDeferRendererRealCommandBufferImplementationIntent &&
        implementationIntent
            .shouldReportRendererRealCommandBufferImplementationIntentBlocked == false
    let intentInconsistent =
        implementationIntent
            .shouldReportRendererRealCommandBufferImplementationIntentBlocked ||
        (
            implementationIntent
                .didPrepareRendererRealCommandBufferImplementationIntent &&
            intentReady == false
        ) ||
        (
            implementationIntent
                .shouldDeferRendererRealCommandBufferImplementationIntent &&
            implementationIntent
                .shouldReportRendererRealCommandBufferImplementationIntentBlocked
        )

    if (intentInconsistent) {
        return CjguiInternalRendererRealCommandBufferCreationAdmissionPolicy(
            implementationIntent,
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

    if (intentDeferred || intentReady == false) {
        return CjguiInternalRendererRealCommandBufferCreationAdmissionPolicy(
            implementationIntent,
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

    return CjguiInternalRendererRealCommandBufferCreationAdmissionPolicy(
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
        true
    )
}

func cjguiInternalBuildRendererRealCommandBufferSingleUseAdmissionGuard(
    creationAdmissionPolicy:
        CjguiInternalRendererRealCommandBufferCreationAdmissionPolicy
): CjguiInternalRendererRealCommandBufferSingleUseAdmissionGuard {
    let creationReady =
        creationAdmissionPolicy
            .didPrepareRendererRealCommandBufferCreationAdmissionPolicy &&
        creationAdmissionPolicy
            .didPreserveRendererRealCommandBufferImplementationIntent &&
        creationAdmissionPolicy.didDefineFutureBufferCreationAdmissionPolicy &&
        creationAdmissionPolicy.didDescribeBufferFactoryAdmissionFacts &&
        creationAdmissionPolicy.didDescribeNoBufferObjectFacts &&
        creationAdmissionPolicy.didConfirmNoBufferObjectCreated &&
        creationAdmissionPolicy.didConfirmNoBufferFactoryCall &&
        creationAdmissionPolicy.didKeepBufferCreationAdmissionPolicyValueOnly &&
        creationAdmissionPolicy.didAvoidBufferFactoryPermissionWrapper &&
        creationAdmissionPolicy.didAvoidBufferReadyPermissionWrapper &&
        creationAdmissionPolicy.didAvoidThinWrapper &&
        creationAdmissionPolicy
            .shouldDeferRendererRealCommandBufferCreationAdmissionPolicy == false &&
        creationAdmissionPolicy
            .shouldReportRendererRealCommandBufferCreationAdmissionPolicyBlocked == false
    let creationDeferred =
        creationAdmissionPolicy
            .shouldDeferRendererRealCommandBufferCreationAdmissionPolicy &&
        creationAdmissionPolicy
            .shouldReportRendererRealCommandBufferCreationAdmissionPolicyBlocked == false
    let creationInconsistent =
        creationAdmissionPolicy
            .shouldReportRendererRealCommandBufferCreationAdmissionPolicyBlocked ||
        (
            creationAdmissionPolicy
                .didPrepareRendererRealCommandBufferCreationAdmissionPolicy &&
            creationReady == false
        ) ||
        (
            creationAdmissionPolicy
                .shouldDeferRendererRealCommandBufferCreationAdmissionPolicy &&
            creationAdmissionPolicy
                .shouldReportRendererRealCommandBufferCreationAdmissionPolicyBlocked
        )

    if (creationInconsistent) {
        return CjguiInternalRendererRealCommandBufferSingleUseAdmissionGuard(
            creationAdmissionPolicy,
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

    if (creationDeferred || creationReady == false) {
        return CjguiInternalRendererRealCommandBufferSingleUseAdmissionGuard(
            creationAdmissionPolicy,
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

    return CjguiInternalRendererRealCommandBufferSingleUseAdmissionGuard(
        creationAdmissionPolicy,
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

func cjguiInternalBuildRendererRealCommandBufferFailurePolicy(
    singleUseAdmissionGuard:
        CjguiInternalRendererRealCommandBufferSingleUseAdmissionGuard
): CjguiInternalRendererRealCommandBufferFailurePolicy {
    let singleUseReady =
        singleUseAdmissionGuard
            .didPrepareRendererRealCommandBufferSingleUseAdmissionGuard &&
        singleUseAdmissionGuard
            .didPreserveRendererRealCommandBufferCreationAdmissionPolicy &&
        singleUseAdmissionGuard.didDefineFutureBufferSingleUseAdmissionGuard &&
        singleUseAdmissionGuard.didDescribeSingleUseAdmissionFacts &&
        singleUseAdmissionGuard.didDescribeNoPostSubmitReusableFacts &&
        singleUseAdmissionGuard.didConfirmNoBufferTokenHeld &&
        singleUseAdmissionGuard.didConfirmNoPostSubmitUsablePermission &&
        singleUseAdmissionGuard.didKeepBufferSingleUseAdmissionGuardValueOnly &&
        singleUseAdmissionGuard.didAvoidBufferReadyPermissionWrapper &&
        singleUseAdmissionGuard.didAvoidBufferSubmitPermissionWrapper &&
        singleUseAdmissionGuard.didAvoidThinWrapper &&
        singleUseAdmissionGuard
            .shouldDeferRendererRealCommandBufferSingleUseAdmissionGuard == false &&
        singleUseAdmissionGuard
            .shouldReportRendererRealCommandBufferSingleUseAdmissionGuardBlocked == false
    let singleUseDeferred =
        singleUseAdmissionGuard
            .shouldDeferRendererRealCommandBufferSingleUseAdmissionGuard &&
        singleUseAdmissionGuard
            .shouldReportRendererRealCommandBufferSingleUseAdmissionGuardBlocked == false
    let singleUseInconsistent =
        singleUseAdmissionGuard
            .shouldReportRendererRealCommandBufferSingleUseAdmissionGuardBlocked ||
        (
            singleUseAdmissionGuard
                .didPrepareRendererRealCommandBufferSingleUseAdmissionGuard &&
            singleUseReady == false
        ) ||
        (
            singleUseAdmissionGuard
                .shouldDeferRendererRealCommandBufferSingleUseAdmissionGuard &&
            singleUseAdmissionGuard
                .shouldReportRendererRealCommandBufferSingleUseAdmissionGuardBlocked
        )

    if (singleUseInconsistent) {
        return CjguiInternalRendererRealCommandBufferFailurePolicy(
            singleUseAdmissionGuard,
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

    if (singleUseDeferred || singleUseReady == false) {
        return CjguiInternalRendererRealCommandBufferFailurePolicy(
            singleUseAdmissionGuard,
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

    return CjguiInternalRendererRealCommandBufferFailurePolicy(
        singleUseAdmissionGuard,
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

func cjguiInternalBuildRendererNoRealCommandBufferImplementationReadiness(
    failurePolicy: CjguiInternalRendererRealCommandBufferFailurePolicy
): CjguiInternalRendererNoRealCommandBufferImplementationReadiness {
    let failureReady =
        failurePolicy.didPrepareRendererRealCommandBufferFailurePolicy &&
        failurePolicy.didPreserveRendererRealCommandBufferSingleUseAdmissionGuard &&
        failurePolicy.didDefineFutureBufferFailurePolicy &&
        failurePolicy.didDescribeFailureAdmissionFacts &&
        failurePolicy.didDescribeNoCompletionObservationFacts &&
        failurePolicy.didConfirmNoCompletionCallbackRegistered &&
        failurePolicy.didConfirmNoGpuCompletionObserved &&
        failurePolicy.didKeepBufferFailurePolicyValueOnly &&
        failurePolicy.didAvoidGpuWorkWrapper &&
        failurePolicy.didAvoidStateWriteWrapper &&
        failurePolicy.didAvoidThinWrapper &&
        failurePolicy.shouldDeferRendererRealCommandBufferFailurePolicy == false &&
        failurePolicy
            .shouldReportRendererRealCommandBufferFailurePolicyBlocked == false
    let failureDeferred =
        failurePolicy.shouldDeferRendererRealCommandBufferFailurePolicy &&
        failurePolicy
            .shouldReportRendererRealCommandBufferFailurePolicyBlocked == false
    let failureInconsistent =
        failurePolicy.shouldReportRendererRealCommandBufferFailurePolicyBlocked ||
        (
            failurePolicy.didPrepareRendererRealCommandBufferFailurePolicy &&
            failureReady == false
        ) ||
        (
            failurePolicy.shouldDeferRendererRealCommandBufferFailurePolicy &&
            failurePolicy
                .shouldReportRendererRealCommandBufferFailurePolicyBlocked
        )

    if (failureInconsistent) {
        return CjguiInternalRendererNoRealCommandBufferImplementationReadiness(
            failurePolicy,
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
            true,
            true,
            true,
            true
        )
    }

    if (failureDeferred || failureReady == false) {
        return CjguiInternalRendererNoRealCommandBufferImplementationReadiness(
            failurePolicy,
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
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererNoRealCommandBufferImplementationReadiness(
        failurePolicy,
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
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererRealCommandBufferAdmissionDraft():
    CjguiInternalRendererNoRealCommandBufferImplementationReadiness {
    let noRealDrawableImplementationReadiness =
        cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft()
    let implementationIntent =
        cjguiInternalBuildRendererRealCommandBufferImplementationIntent(
            noRealDrawableImplementationReadiness
        )
    let creationAdmissionPolicy =
        cjguiInternalBuildRendererRealCommandBufferCreationAdmissionPolicy(
            implementationIntent
        )
    let singleUseAdmissionGuard =
        cjguiInternalBuildRendererRealCommandBufferSingleUseAdmissionGuard(
            creationAdmissionPolicy
        )
    let failurePolicy =
        cjguiInternalBuildRendererRealCommandBufferFailurePolicy(
            singleUseAdmissionGuard
        )
    return cjguiInternalBuildRendererNoRealCommandBufferImplementationReadiness(
        failurePolicy
    )
}
