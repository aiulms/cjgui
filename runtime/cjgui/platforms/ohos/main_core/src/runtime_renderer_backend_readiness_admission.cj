// Owner：本文件固定 backend readiness finalization admission 的 internal-only owner 边界。
// Truth：唯一 runtime input 是 CjguiInternalRendererNoStateWriteImplementationReadiness，
// canonical endpoint 是 CjguiInternalRendererNoBackendReadyImplementationReadiness。
// Stop-line：只生成 value facts，不产生后端就绪 truth，不创建资源对象，不写状态，
// 不做图形执行，不开放诊断或接口。
// Same-shape Boundary Brake：本文件新增 resource chain / execution-state visibility
// / failure policy 语义，不把上一层 readiness 包成 permission wrapper、receipt 或 record。
package cjgui

struct CjguiInternalRendererBackendReadinessFinalizationIntent {
    let noStateWriteImplementationReadiness:
        CjguiInternalRendererNoStateWriteImplementationReadiness
    let didPrepareRendererBackendReadinessFinalizationIntent: Bool
    let shouldDeferRendererBackendReadinessFinalizationIntent: Bool
    let shouldReportRendererBackendReadinessFinalizationIntentBlocked: Bool
    let didPreserveRendererNoStateWriteImplementationReadiness: Bool
    let didDefineFutureBackendReadinessFinalizationIntent: Bool
    let didDescribeResourceChainAdmissionNeed: Bool
    let didDescribeExecutionStateVisibilityAdmissionNeed: Bool
    let didDescribeBackendReadinessFinalizationFailureNeed: Bool
    let didKeepBackendReadinessFinalizationIntentValueOnly: Bool
    let didAvoidBackendReadyPermissionWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        noStateWriteImplementationReadiness:
            CjguiInternalRendererNoStateWriteImplementationReadiness,
        didPrepareRendererBackendReadinessFinalizationIntent: Bool,
        shouldDeferRendererBackendReadinessFinalizationIntent: Bool,
        shouldReportRendererBackendReadinessFinalizationIntentBlocked: Bool,
        didPreserveRendererNoStateWriteImplementationReadiness: Bool,
        didDefineFutureBackendReadinessFinalizationIntent: Bool,
        didDescribeResourceChainAdmissionNeed: Bool,
        didDescribeExecutionStateVisibilityAdmissionNeed: Bool,
        didDescribeBackendReadinessFinalizationFailureNeed: Bool,
        didKeepBackendReadinessFinalizationIntentValueOnly: Bool,
        didAvoidBackendReadyPermissionWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noStateWriteImplementationReadiness =
            noStateWriteImplementationReadiness
        this.didPrepareRendererBackendReadinessFinalizationIntent =
            didPrepareRendererBackendReadinessFinalizationIntent
        this.shouldDeferRendererBackendReadinessFinalizationIntent =
            shouldDeferRendererBackendReadinessFinalizationIntent
        this
            .shouldReportRendererBackendReadinessFinalizationIntentBlocked =
            shouldReportRendererBackendReadinessFinalizationIntentBlocked
        this.didPreserveRendererNoStateWriteImplementationReadiness =
            didPreserveRendererNoStateWriteImplementationReadiness
        this.didDefineFutureBackendReadinessFinalizationIntent =
            didDefineFutureBackendReadinessFinalizationIntent
        this.didDescribeResourceChainAdmissionNeed =
            didDescribeResourceChainAdmissionNeed
        this.didDescribeExecutionStateVisibilityAdmissionNeed =
            didDescribeExecutionStateVisibilityAdmissionNeed
        this.didDescribeBackendReadinessFinalizationFailureNeed =
            didDescribeBackendReadinessFinalizationFailureNeed
        this.didKeepBackendReadinessFinalizationIntentValueOnly =
            didKeepBackendReadinessFinalizationIntentValueOnly
        this.didAvoidBackendReadyPermissionWrapper =
            didAvoidBackendReadyPermissionWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererResourceChainAdmissionPolicy {
    let finalizationIntent:
        CjguiInternalRendererBackendReadinessFinalizationIntent
    let didPrepareRendererResourceChainAdmissionPolicy: Bool
    let shouldDeferRendererResourceChainAdmissionPolicy: Bool
    let shouldReportRendererResourceChainAdmissionPolicyBlocked: Bool
    let didPreserveRendererBackendReadinessFinalizationIntent: Bool
    let didDefineFutureResourceChainAdmissionPolicy: Bool
    let didDescribeResourceChainCompletenessFacts: Bool
    let didDescribeNoBackendResourceFacts: Bool
    let didDescribeNoPlatformResourceFacts: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didConfirmNoBackendResourceObject: Bool
    let didConfirmNoPlatformObject: Bool
    let didKeepResourceChainAdmissionPolicyValueOnly: Bool
    let didAvoidResourceReadyPermissionWrapper: Bool
    let didAvoidBackendReadyPermissionWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        finalizationIntent:
            CjguiInternalRendererBackendReadinessFinalizationIntent,
        didPrepareRendererResourceChainAdmissionPolicy: Bool,
        shouldDeferRendererResourceChainAdmissionPolicy: Bool,
        shouldReportRendererResourceChainAdmissionPolicyBlocked: Bool,
        didPreserveRendererBackendReadinessFinalizationIntent: Bool,
        didDefineFutureResourceChainAdmissionPolicy: Bool,
        didDescribeResourceChainCompletenessFacts: Bool,
        didDescribeNoBackendResourceFacts: Bool,
        didDescribeNoPlatformResourceFacts: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didConfirmNoBackendResourceObject: Bool,
        didConfirmNoPlatformObject: Bool,
        didKeepResourceChainAdmissionPolicyValueOnly: Bool,
        didAvoidResourceReadyPermissionWrapper: Bool,
        didAvoidBackendReadyPermissionWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.finalizationIntent = finalizationIntent
        this.didPrepareRendererResourceChainAdmissionPolicy =
            didPrepareRendererResourceChainAdmissionPolicy
        this.shouldDeferRendererResourceChainAdmissionPolicy =
            shouldDeferRendererResourceChainAdmissionPolicy
        this.shouldReportRendererResourceChainAdmissionPolicyBlocked =
            shouldReportRendererResourceChainAdmissionPolicyBlocked
        this.didPreserveRendererBackendReadinessFinalizationIntent =
            didPreserveRendererBackendReadinessFinalizationIntent
        this.didDefineFutureResourceChainAdmissionPolicy =
            didDefineFutureResourceChainAdmissionPolicy
        this.didDescribeResourceChainCompletenessFacts =
            didDescribeResourceChainCompletenessFacts
        this.didDescribeNoBackendResourceFacts =
            didDescribeNoBackendResourceFacts
        this.didDescribeNoPlatformResourceFacts =
            didDescribeNoPlatformResourceFacts
        this.didConfirmNoBackendReadyTruth =
            didConfirmNoBackendReadyTruth
        this.didConfirmNoBackendResourceObject =
            didConfirmNoBackendResourceObject
        this.didConfirmNoPlatformObject = didConfirmNoPlatformObject
        this.didKeepResourceChainAdmissionPolicyValueOnly =
            didKeepResourceChainAdmissionPolicyValueOnly
        this.didAvoidResourceReadyPermissionWrapper =
            didAvoidResourceReadyPermissionWrapper
        this.didAvoidBackendReadyPermissionWrapper =
            didAvoidBackendReadyPermissionWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererExecutionStateVisibilityAdmissionGuard {
    let resourceChainAdmissionPolicy:
        CjguiInternalRendererResourceChainAdmissionPolicy
    let didPrepareRendererExecutionStateVisibilityAdmissionGuard: Bool
    let shouldDeferRendererExecutionStateVisibilityAdmissionGuard: Bool
    let shouldReportRendererExecutionStateVisibilityAdmissionGuardBlocked:
        Bool
    let didPreserveRendererResourceChainAdmissionPolicy: Bool
    let didDefineFutureExecutionStateVisibilityAdmissionGuard: Bool
    let didDescribeExecutionStateVisibilityFacts: Bool
    let didDescribeNoStateMutationFacts: Bool
    let didDescribeNoExternalPublicationFacts: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoRuntimeStateTouch: Bool
    let didConfirmNoPublicDiagnostics: Bool
    let didConfirmNoPublicApi: Bool
    let didKeepExecutionStateVisibilityAdmissionGuardValueOnly: Bool
    let didAvoidStateVisiblePermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidPublicApiWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        resourceChainAdmissionPolicy:
            CjguiInternalRendererResourceChainAdmissionPolicy,
        didPrepareRendererExecutionStateVisibilityAdmissionGuard: Bool,
        shouldDeferRendererExecutionStateVisibilityAdmissionGuard: Bool,
        shouldReportRendererExecutionStateVisibilityAdmissionGuardBlocked:
            Bool,
        didPreserveRendererResourceChainAdmissionPolicy: Bool,
        didDefineFutureExecutionStateVisibilityAdmissionGuard: Bool,
        didDescribeExecutionStateVisibilityFacts: Bool,
        didDescribeNoStateMutationFacts: Bool,
        didDescribeNoExternalPublicationFacts: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoRuntimeStateTouch: Bool,
        didConfirmNoPublicDiagnostics: Bool,
        didConfirmNoPublicApi: Bool,
        didKeepExecutionStateVisibilityAdmissionGuardValueOnly: Bool,
        didAvoidStateVisiblePermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidPublicApiWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.resourceChainAdmissionPolicy = resourceChainAdmissionPolicy
        this.didPrepareRendererExecutionStateVisibilityAdmissionGuard =
            didPrepareRendererExecutionStateVisibilityAdmissionGuard
        this.shouldDeferRendererExecutionStateVisibilityAdmissionGuard =
            shouldDeferRendererExecutionStateVisibilityAdmissionGuard
        this
            .shouldReportRendererExecutionStateVisibilityAdmissionGuardBlocked =
            shouldReportRendererExecutionStateVisibilityAdmissionGuardBlocked
        this.didPreserveRendererResourceChainAdmissionPolicy =
            didPreserveRendererResourceChainAdmissionPolicy
        this.didDefineFutureExecutionStateVisibilityAdmissionGuard =
            didDefineFutureExecutionStateVisibilityAdmissionGuard
        this.didDescribeExecutionStateVisibilityFacts =
            didDescribeExecutionStateVisibilityFacts
        this.didDescribeNoStateMutationFacts =
            didDescribeNoStateMutationFacts
        this.didDescribeNoExternalPublicationFacts =
            didDescribeNoExternalPublicationFacts
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoRuntimeStateTouch = didConfirmNoRuntimeStateTouch
        this.didConfirmNoPublicDiagnostics = didConfirmNoPublicDiagnostics
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didKeepExecutionStateVisibilityAdmissionGuardValueOnly =
            didKeepExecutionStateVisibilityAdmissionGuardValueOnly
        this.didAvoidStateVisiblePermissionWrapper =
            didAvoidStateVisiblePermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidPublicApiWrapper = didAvoidPublicApiWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererBackendReadinessFinalizationFailurePolicy {
    let executionStateVisibilityAdmissionGuard:
        CjguiInternalRendererExecutionStateVisibilityAdmissionGuard
    let didPrepareRendererBackendReadinessFinalizationFailurePolicy: Bool
    let shouldDeferRendererBackendReadinessFinalizationFailurePolicy: Bool
    let shouldReportRendererBackendReadinessFinalizationFailurePolicyBlocked:
        Bool
    let didPreserveRendererExecutionStateVisibilityAdmissionGuard: Bool
    let didDefineFutureBackendReadinessFinalizationFailurePolicy: Bool
    let didDescribeFinalizationFailureFacts: Bool
    let didDescribeFailClosedFacts: Bool
    let didDescribeNoReadyFallbackFacts: Bool
    let didConfirmNoBackendReadyMutation: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoExternalArtifact: Bool
    let didKeepBackendReadinessFinalizationFailurePolicyValueOnly: Bool
    let didAvoidImplementationFinalizedWrapper: Bool
    let didAvoidBackendReadyPermissionWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        executionStateVisibilityAdmissionGuard:
            CjguiInternalRendererExecutionStateVisibilityAdmissionGuard,
        didPrepareRendererBackendReadinessFinalizationFailurePolicy: Bool,
        shouldDeferRendererBackendReadinessFinalizationFailurePolicy: Bool,
        shouldReportRendererBackendReadinessFinalizationFailurePolicyBlocked:
            Bool,
        didPreserveRendererExecutionStateVisibilityAdmissionGuard: Bool,
        didDefineFutureBackendReadinessFinalizationFailurePolicy: Bool,
        didDescribeFinalizationFailureFacts: Bool,
        didDescribeFailClosedFacts: Bool,
        didDescribeNoReadyFallbackFacts: Bool,
        didConfirmNoBackendReadyMutation: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoExternalArtifact: Bool,
        didKeepBackendReadinessFinalizationFailurePolicyValueOnly: Bool,
        didAvoidImplementationFinalizedWrapper: Bool,
        didAvoidBackendReadyPermissionWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.executionStateVisibilityAdmissionGuard =
            executionStateVisibilityAdmissionGuard
        this.didPrepareRendererBackendReadinessFinalizationFailurePolicy =
            didPrepareRendererBackendReadinessFinalizationFailurePolicy
        this.shouldDeferRendererBackendReadinessFinalizationFailurePolicy =
            shouldDeferRendererBackendReadinessFinalizationFailurePolicy
        this
            .shouldReportRendererBackendReadinessFinalizationFailurePolicyBlocked =
            shouldReportRendererBackendReadinessFinalizationFailurePolicyBlocked
        this.didPreserveRendererExecutionStateVisibilityAdmissionGuard =
            didPreserveRendererExecutionStateVisibilityAdmissionGuard
        this.didDefineFutureBackendReadinessFinalizationFailurePolicy =
            didDefineFutureBackendReadinessFinalizationFailurePolicy
        this.didDescribeFinalizationFailureFacts =
            didDescribeFinalizationFailureFacts
        this.didDescribeFailClosedFacts = didDescribeFailClosedFacts
        this.didDescribeNoReadyFallbackFacts =
            didDescribeNoReadyFallbackFacts
        this.didConfirmNoBackendReadyMutation =
            didConfirmNoBackendReadyMutation
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoExternalArtifact = didConfirmNoExternalArtifact
        this.didKeepBackendReadinessFinalizationFailurePolicyValueOnly =
            didKeepBackendReadinessFinalizationFailurePolicyValueOnly
        this.didAvoidImplementationFinalizedWrapper =
            didAvoidImplementationFinalizedWrapper
        this.didAvoidBackendReadyPermissionWrapper =
            didAvoidBackendReadyPermissionWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoBackendReadyImplementationReadiness {
    let finalizationFailurePolicy:
        CjguiInternalRendererBackendReadinessFinalizationFailurePolicy
    let isRendererNoBackendReadyImplementationReady: Bool
    let canFutureRendererBackendReadinessFinalizationBoundaryEvaluate: Bool
    let shouldDeferRendererNoBackendReadyImplementationReadiness: Bool
    let shouldReportRendererNoBackendReadyImplementationReadinessBlocked:
        Bool
    let didSealRendererNoBackendReadyImplementationReadiness: Bool
    let didPreserveRendererBackendReadinessFinalizationFailurePolicy: Bool
    let didKeepNoBackendReadyImplementationReadinessValueOnly: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didConfirmNoBackendReadyMutation: Bool
    let didConfirmNoBackendObject: Bool
    let didConfirmNoPlatformObject: Bool
    let didConfirmNoExternalResourceHandle: Bool
    let didConfirmNoPointerResource: Bool
    let didConfirmNoForeignDeclaration: Bool
    let didConfirmNoForeignInvocation: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoRuntimeStateTouch: Bool
    let didConfirmNoModuleLevelMutableState: Bool
    let didConfirmNoPublicDiagnostics: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoGpuWork: Bool
    let didConfirmNoCommandObjectWork: Bool
    let didConfirmNoEncoderObject: Bool
    let didConfirmNoDrawCommand: Bool
    let didConfirmNoPipelineUse: Bool
    let didConfirmNoResourceBinding: Bool
    let didAvoidBackendReadyPermissionWrapper: Bool
    let didAvoidImplementationFinalizedWrapper: Bool
    let didAvoidResourceReadyPermissionWrapper: Bool
    let didAvoidStateVisiblePermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidRendererStateWriteWrapper: Bool
    let didAvoidNativeHandlePermissionWrapper: Bool
    let didAvoidCAbiFfiPermissionWrapper: Bool
    let didAvoidPublicApiWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        finalizationFailurePolicy:
            CjguiInternalRendererBackendReadinessFinalizationFailurePolicy,
        isRendererNoBackendReadyImplementationReady: Bool,
        canFutureRendererBackendReadinessFinalizationBoundaryEvaluate: Bool,
        shouldDeferRendererNoBackendReadyImplementationReadiness: Bool,
        shouldReportRendererNoBackendReadyImplementationReadinessBlocked:
            Bool,
        didSealRendererNoBackendReadyImplementationReadiness: Bool,
        didPreserveRendererBackendReadinessFinalizationFailurePolicy: Bool,
        didKeepNoBackendReadyImplementationReadinessValueOnly: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didConfirmNoBackendReadyMutation: Bool,
        didConfirmNoBackendObject: Bool,
        didConfirmNoPlatformObject: Bool,
        didConfirmNoExternalResourceHandle: Bool,
        didConfirmNoPointerResource: Bool,
        didConfirmNoForeignDeclaration: Bool,
        didConfirmNoForeignInvocation: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoRuntimeStateTouch: Bool,
        didConfirmNoModuleLevelMutableState: Bool,
        didConfirmNoPublicDiagnostics: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoGpuWork: Bool,
        didConfirmNoCommandObjectWork: Bool,
        didConfirmNoEncoderObject: Bool,
        didConfirmNoDrawCommand: Bool,
        didConfirmNoPipelineUse: Bool,
        didConfirmNoResourceBinding: Bool,
        didAvoidBackendReadyPermissionWrapper: Bool,
        didAvoidImplementationFinalizedWrapper: Bool,
        didAvoidResourceReadyPermissionWrapper: Bool,
        didAvoidStateVisiblePermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidRendererStateWriteWrapper: Bool,
        didAvoidNativeHandlePermissionWrapper: Bool,
        didAvoidCAbiFfiPermissionWrapper: Bool,
        didAvoidPublicApiWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.finalizationFailurePolicy = finalizationFailurePolicy
        this.isRendererNoBackendReadyImplementationReady =
            isRendererNoBackendReadyImplementationReady
        this.canFutureRendererBackendReadinessFinalizationBoundaryEvaluate =
            canFutureRendererBackendReadinessFinalizationBoundaryEvaluate
        this.shouldDeferRendererNoBackendReadyImplementationReadiness =
            shouldDeferRendererNoBackendReadyImplementationReadiness
        this
            .shouldReportRendererNoBackendReadyImplementationReadinessBlocked =
            shouldReportRendererNoBackendReadyImplementationReadinessBlocked
        this.didSealRendererNoBackendReadyImplementationReadiness =
            didSealRendererNoBackendReadyImplementationReadiness
        this.didPreserveRendererBackendReadinessFinalizationFailurePolicy =
            didPreserveRendererBackendReadinessFinalizationFailurePolicy
        this.didKeepNoBackendReadyImplementationReadinessValueOnly =
            didKeepNoBackendReadyImplementationReadinessValueOnly
        this.didConfirmNoBackendReadyTruth =
            didConfirmNoBackendReadyTruth
        this.didConfirmNoBackendReadyMutation =
            didConfirmNoBackendReadyMutation
        this.didConfirmNoBackendObject = didConfirmNoBackendObject
        this.didConfirmNoPlatformObject = didConfirmNoPlatformObject
        this.didConfirmNoExternalResourceHandle =
            didConfirmNoExternalResourceHandle
        this.didConfirmNoPointerResource = didConfirmNoPointerResource
        this.didConfirmNoForeignDeclaration =
            didConfirmNoForeignDeclaration
        this.didConfirmNoForeignInvocation = didConfirmNoForeignInvocation
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoRuntimeStateTouch = didConfirmNoRuntimeStateTouch
        this.didConfirmNoModuleLevelMutableState =
            didConfirmNoModuleLevelMutableState
        this.didConfirmNoPublicDiagnostics = didConfirmNoPublicDiagnostics
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoGpuWork = didConfirmNoGpuWork
        this.didConfirmNoCommandObjectWork = didConfirmNoCommandObjectWork
        this.didConfirmNoEncoderObject = didConfirmNoEncoderObject
        this.didConfirmNoDrawCommand = didConfirmNoDrawCommand
        this.didConfirmNoPipelineUse = didConfirmNoPipelineUse
        this.didConfirmNoResourceBinding = didConfirmNoResourceBinding
        this.didAvoidBackendReadyPermissionWrapper =
            didAvoidBackendReadyPermissionWrapper
        this.didAvoidImplementationFinalizedWrapper =
            didAvoidImplementationFinalizedWrapper
        this.didAvoidResourceReadyPermissionWrapper =
            didAvoidResourceReadyPermissionWrapper
        this.didAvoidStateVisiblePermissionWrapper =
            didAvoidStateVisiblePermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidRenderPermissionWrapper =
            didAvoidRenderPermissionWrapper
        this.didAvoidRendererStateWriteWrapper =
            didAvoidRendererStateWriteWrapper
        this.didAvoidNativeHandlePermissionWrapper =
            didAvoidNativeHandlePermissionWrapper
        this.didAvoidCAbiFfiPermissionWrapper =
            didAvoidCAbiFfiPermissionWrapper
        this.didAvoidPublicApiWrapper = didAvoidPublicApiWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererBackendReadinessFinalizationIntent(
    noStateWriteImplementationReadiness:
        CjguiInternalRendererNoStateWriteImplementationReadiness
): CjguiInternalRendererBackendReadinessFinalizationIntent {
    let upstreamEndpointReady =
        noStateWriteImplementationReadiness
            .isRendererNoStateWriteImplementationReady
    let upstreamCanEvaluate =
        noStateWriteImplementationReadiness
            .canFutureRendererStateWriteImplementationBoundaryEvaluate
    let upstreamShouldDefer =
        noStateWriteImplementationReadiness
            .shouldDeferRendererNoStateWriteImplementationReadiness
    let upstreamBlocked =
        noStateWriteImplementationReadiness
            .shouldReportRendererNoStateWriteImplementationReadinessBlocked
    let upstreamReady =
        upstreamEndpointReady &&
        upstreamCanEvaluate &&
        noStateWriteImplementationReadiness
            .didSealRendererNoStateWriteImplementationReadiness &&
        noStateWriteImplementationReadiness
            .didPreserveRendererRollbackStateAdmissionPolicy &&
        noStateWriteImplementationReadiness
            .didKeepNoStateWriteImplementationReadinessValueOnly &&
        noStateWriteImplementationReadiness.didConfirmNoRendererStateWrite &&
        noStateWriteImplementationReadiness.didConfirmNoRuntimeStateTouch &&
        noStateWriteImplementationReadiness
            .didConfirmNoModuleLevelMutableState &&
        noStateWriteImplementationReadiness.didConfirmNoPublicDiagnostics &&
        noStateWriteImplementationReadiness.didConfirmNoPublicApi &&
        noStateWriteImplementationReadiness.didConfirmNoRenderExecution &&
        noStateWriteImplementationReadiness.didConfirmNoGpuWork &&
        noStateWriteImplementationReadiness.didConfirmNoCommandObjectWork &&
        noStateWriteImplementationReadiness.didConfirmNoEncoderObject &&
        noStateWriteImplementationReadiness.didConfirmNoDrawCommand &&
        noStateWriteImplementationReadiness.didConfirmNoPipelineUse &&
        noStateWriteImplementationReadiness.didConfirmNoResourceBinding &&
        noStateWriteImplementationReadiness.didConfirmNoForeignDeclaration &&
        noStateWriteImplementationReadiness.didConfirmNoForeignInvocation &&
        noStateWriteImplementationReadiness.didConfirmNoExternalHandle &&
        noStateWriteImplementationReadiness.didConfirmNoPointerResource &&
        noStateWriteImplementationReadiness
            .didAvoidStateReadyPermissionWrapper &&
        noStateWriteImplementationReadiness.didAvoidBackendReadyWrapper &&
        noStateWriteImplementationReadiness.didAvoidGpuSubmissionWrapper &&
        noStateWriteImplementationReadiness.didAvoidRenderPermissionWrapper &&
        noStateWriteImplementationReadiness
            .didAvoidNativeHandlePermissionWrapper &&
        noStateWriteImplementationReadiness.didAvoidCAbiFfiPermissionWrapper &&
        noStateWriteImplementationReadiness.didAvoidPublicApiWrapper &&
        noStateWriteImplementationReadiness.didAvoidReceiptRecordOutput &&
        noStateWriteImplementationReadiness.didAvoidThinWrapper &&
        noStateWriteImplementationReadiness.didStayFullRebuildOnly &&
        upstreamShouldDefer == false &&
        upstreamBlocked == false
    let upstreamDeferred = upstreamShouldDefer && upstreamBlocked == false
    let upstreamInconsistent =
        upstreamBlocked ||
        (upstreamCanEvaluate && upstreamEndpointReady == false) ||
        (upstreamShouldDefer && upstreamBlocked)

    if (upstreamInconsistent) {
        return CjguiInternalRendererBackendReadinessFinalizationIntent(
            noStateWriteImplementationReadiness,
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
            true
        )
    }

    if (upstreamDeferred || upstreamReady == false) {
        return CjguiInternalRendererBackendReadinessFinalizationIntent(
            noStateWriteImplementationReadiness,
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
            true
        )
    }

    return CjguiInternalRendererBackendReadinessFinalizationIntent(
        noStateWriteImplementationReadiness,
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

func cjguiInternalBuildRendererResourceChainAdmissionPolicy(
    finalizationIntent:
        CjguiInternalRendererBackendReadinessFinalizationIntent
): CjguiInternalRendererResourceChainAdmissionPolicy {
    let intentPrepared =
        finalizationIntent
            .didPrepareRendererBackendReadinessFinalizationIntent
    let intentShouldDefer =
        finalizationIntent
            .shouldDeferRendererBackendReadinessFinalizationIntent
    let intentBlocked =
        finalizationIntent
            .shouldReportRendererBackendReadinessFinalizationIntentBlocked
    let intentReady =
        intentPrepared &&
        finalizationIntent
            .didPreserveRendererNoStateWriteImplementationReadiness &&
        finalizationIntent
            .didDefineFutureBackendReadinessFinalizationIntent &&
        finalizationIntent.didDescribeResourceChainAdmissionNeed &&
        finalizationIntent.didDescribeExecutionStateVisibilityAdmissionNeed &&
        finalizationIntent
            .didDescribeBackendReadinessFinalizationFailureNeed &&
        finalizationIntent
            .didKeepBackendReadinessFinalizationIntentValueOnly &&
        finalizationIntent.didAvoidBackendReadyPermissionWrapper &&
        finalizationIntent.didAvoidReceiptRecordOutput &&
        finalizationIntent.didAvoidThinWrapper &&
        intentShouldDefer == false &&
        intentBlocked == false
    let intentDeferred = intentShouldDefer && intentBlocked == false
    let intentInconsistent =
        intentBlocked ||
        (intentPrepared && intentReady == false) ||
        (intentShouldDefer && intentBlocked)

    if (intentInconsistent) {
        return CjguiInternalRendererResourceChainAdmissionPolicy(
            finalizationIntent,
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
        return CjguiInternalRendererResourceChainAdmissionPolicy(
            finalizationIntent,
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

    return CjguiInternalRendererResourceChainAdmissionPolicy(
        finalizationIntent,
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

func cjguiInternalBuildRendererExecutionStateVisibilityAdmissionGuard(
    resourceChainAdmissionPolicy:
        CjguiInternalRendererResourceChainAdmissionPolicy
): CjguiInternalRendererExecutionStateVisibilityAdmissionGuard {
    let resourceChainReady =
        resourceChainAdmissionPolicy
            .didPrepareRendererResourceChainAdmissionPolicy &&
        resourceChainAdmissionPolicy
            .didPreserveRendererBackendReadinessFinalizationIntent &&
        resourceChainAdmissionPolicy
            .didDefineFutureResourceChainAdmissionPolicy &&
        resourceChainAdmissionPolicy
            .didDescribeResourceChainCompletenessFacts &&
        resourceChainAdmissionPolicy.didDescribeNoBackendResourceFacts &&
        resourceChainAdmissionPolicy.didDescribeNoPlatformResourceFacts &&
        resourceChainAdmissionPolicy.didConfirmNoBackendReadyTruth &&
        resourceChainAdmissionPolicy.didConfirmNoBackendResourceObject &&
        resourceChainAdmissionPolicy.didConfirmNoPlatformObject &&
        resourceChainAdmissionPolicy
            .didKeepResourceChainAdmissionPolicyValueOnly &&
        resourceChainAdmissionPolicy.didAvoidResourceReadyPermissionWrapper &&
        resourceChainAdmissionPolicy.didAvoidBackendReadyPermissionWrapper &&
        resourceChainAdmissionPolicy.didAvoidReceiptRecordOutput &&
        resourceChainAdmissionPolicy.didAvoidThinWrapper &&
        resourceChainAdmissionPolicy
            .shouldDeferRendererResourceChainAdmissionPolicy == false &&
        resourceChainAdmissionPolicy
            .shouldReportRendererResourceChainAdmissionPolicyBlocked == false
    let resourceChainDeferred =
        resourceChainAdmissionPolicy
            .shouldDeferRendererResourceChainAdmissionPolicy &&
        resourceChainAdmissionPolicy
            .shouldReportRendererResourceChainAdmissionPolicyBlocked == false
    let resourceChainInconsistent =
        resourceChainAdmissionPolicy
            .shouldReportRendererResourceChainAdmissionPolicyBlocked ||
        (
            resourceChainAdmissionPolicy
                .didPrepareRendererResourceChainAdmissionPolicy &&
            resourceChainReady == false
        ) ||
        (
            resourceChainAdmissionPolicy
                .shouldDeferRendererResourceChainAdmissionPolicy &&
            resourceChainAdmissionPolicy
                .shouldReportRendererResourceChainAdmissionPolicyBlocked
        )

    if (resourceChainInconsistent) {
        return CjguiInternalRendererExecutionStateVisibilityAdmissionGuard(
            resourceChainAdmissionPolicy,
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
            true,
            true
        )
    }

    if (resourceChainDeferred || resourceChainReady == false) {
        return CjguiInternalRendererExecutionStateVisibilityAdmissionGuard(
            resourceChainAdmissionPolicy,
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
            true,
            true
        )
    }

    return CjguiInternalRendererExecutionStateVisibilityAdmissionGuard(
        resourceChainAdmissionPolicy,
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

func cjguiInternalBuildRendererBackendReadinessFinalizationFailurePolicy(
    executionStateVisibilityAdmissionGuard:
        CjguiInternalRendererExecutionStateVisibilityAdmissionGuard
): CjguiInternalRendererBackendReadinessFinalizationFailurePolicy {
    let visibilityReady =
        executionStateVisibilityAdmissionGuard
            .didPrepareRendererExecutionStateVisibilityAdmissionGuard &&
        executionStateVisibilityAdmissionGuard
            .didPreserveRendererResourceChainAdmissionPolicy &&
        executionStateVisibilityAdmissionGuard
            .didDefineFutureExecutionStateVisibilityAdmissionGuard &&
        executionStateVisibilityAdmissionGuard
            .didDescribeExecutionStateVisibilityFacts &&
        executionStateVisibilityAdmissionGuard.didDescribeNoStateMutationFacts &&
        executionStateVisibilityAdmissionGuard
            .didDescribeNoExternalPublicationFacts &&
        executionStateVisibilityAdmissionGuard.didConfirmNoRendererStateWrite &&
        executionStateVisibilityAdmissionGuard.didConfirmNoRuntimeStateTouch &&
        executionStateVisibilityAdmissionGuard.didConfirmNoPublicDiagnostics &&
        executionStateVisibilityAdmissionGuard.didConfirmNoPublicApi &&
        executionStateVisibilityAdmissionGuard
            .didKeepExecutionStateVisibilityAdmissionGuardValueOnly &&
        executionStateVisibilityAdmissionGuard
            .didAvoidStateVisiblePermissionWrapper &&
        executionStateVisibilityAdmissionGuard.didAvoidGpuSubmissionWrapper &&
        executionStateVisibilityAdmissionGuard.didAvoidPublicApiWrapper &&
        executionStateVisibilityAdmissionGuard.didAvoidThinWrapper &&
        executionStateVisibilityAdmissionGuard
            .shouldDeferRendererExecutionStateVisibilityAdmissionGuard ==
            false &&
        executionStateVisibilityAdmissionGuard
            .shouldReportRendererExecutionStateVisibilityAdmissionGuardBlocked ==
            false
    let visibilityDeferred =
        executionStateVisibilityAdmissionGuard
            .shouldDeferRendererExecutionStateVisibilityAdmissionGuard &&
        executionStateVisibilityAdmissionGuard
            .shouldReportRendererExecutionStateVisibilityAdmissionGuardBlocked ==
            false
    let visibilityInconsistent =
        executionStateVisibilityAdmissionGuard
            .shouldReportRendererExecutionStateVisibilityAdmissionGuardBlocked ||
        (
            executionStateVisibilityAdmissionGuard
                .didPrepareRendererExecutionStateVisibilityAdmissionGuard &&
            visibilityReady == false
        ) ||
        (
            executionStateVisibilityAdmissionGuard
                .shouldDeferRendererExecutionStateVisibilityAdmissionGuard &&
            executionStateVisibilityAdmissionGuard
                .shouldReportRendererExecutionStateVisibilityAdmissionGuardBlocked
        )

    if (visibilityInconsistent) {
        return CjguiInternalRendererBackendReadinessFinalizationFailurePolicy(
            executionStateVisibilityAdmissionGuard,
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

    if (visibilityDeferred || visibilityReady == false) {
        return CjguiInternalRendererBackendReadinessFinalizationFailurePolicy(
            executionStateVisibilityAdmissionGuard,
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

    return CjguiInternalRendererBackendReadinessFinalizationFailurePolicy(
        executionStateVisibilityAdmissionGuard,
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

func cjguiInternalBuildRendererNoBackendReadyImplementationReadiness(
    finalizationFailurePolicy:
        CjguiInternalRendererBackendReadinessFinalizationFailurePolicy
): CjguiInternalRendererNoBackendReadyImplementationReadiness {
    let failurePolicyReady =
        finalizationFailurePolicy
            .didPrepareRendererBackendReadinessFinalizationFailurePolicy &&
        finalizationFailurePolicy
            .didPreserveRendererExecutionStateVisibilityAdmissionGuard &&
        finalizationFailurePolicy
            .didDefineFutureBackendReadinessFinalizationFailurePolicy &&
        finalizationFailurePolicy.didDescribeFinalizationFailureFacts &&
        finalizationFailurePolicy.didDescribeFailClosedFacts &&
        finalizationFailurePolicy.didDescribeNoReadyFallbackFacts &&
        finalizationFailurePolicy.didConfirmNoBackendReadyMutation &&
        finalizationFailurePolicy.didConfirmNoRendererStateWrite &&
        finalizationFailurePolicy.didConfirmNoExternalArtifact &&
        finalizationFailurePolicy
            .didKeepBackendReadinessFinalizationFailurePolicyValueOnly &&
        finalizationFailurePolicy.didAvoidImplementationFinalizedWrapper &&
        finalizationFailurePolicy.didAvoidBackendReadyPermissionWrapper &&
        finalizationFailurePolicy.didAvoidReceiptRecordOutput &&
        finalizationFailurePolicy.didAvoidThinWrapper &&
        finalizationFailurePolicy
            .shouldDeferRendererBackendReadinessFinalizationFailurePolicy ==
            false &&
        finalizationFailurePolicy
            .shouldReportRendererBackendReadinessFinalizationFailurePolicyBlocked ==
            false
    let failurePolicyDeferred =
        finalizationFailurePolicy
            .shouldDeferRendererBackendReadinessFinalizationFailurePolicy &&
        finalizationFailurePolicy
            .shouldReportRendererBackendReadinessFinalizationFailurePolicyBlocked ==
            false
    let failurePolicyInconsistent =
        finalizationFailurePolicy
            .shouldReportRendererBackendReadinessFinalizationFailurePolicyBlocked ||
        (
            finalizationFailurePolicy
                .didPrepareRendererBackendReadinessFinalizationFailurePolicy &&
            failurePolicyReady == false
        ) ||
        (
            finalizationFailurePolicy
                .shouldDeferRendererBackendReadinessFinalizationFailurePolicy &&
            finalizationFailurePolicy
                .shouldReportRendererBackendReadinessFinalizationFailurePolicyBlocked
        )

    if (failurePolicyInconsistent) {
        return CjguiInternalRendererNoBackendReadyImplementationReadiness(
            finalizationFailurePolicy,
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

    if (failurePolicyDeferred || failurePolicyReady == false) {
        return CjguiInternalRendererNoBackendReadyImplementationReadiness(
            finalizationFailurePolicy,
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

    return CjguiInternalRendererNoBackendReadyImplementationReadiness(
        finalizationFailurePolicy,
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

func cjguiInternalExecuteDefaultRendererBackendReadinessFinalizationDraft():
    CjguiInternalRendererNoBackendReadyImplementationReadiness {
    let noStateWriteImplementationReadiness =
        cjguiInternalExecuteDefaultRendererStateWriteAdmissionDraft()
    let finalizationIntent =
        cjguiInternalBuildRendererBackendReadinessFinalizationIntent(
            noStateWriteImplementationReadiness
        )
    let resourceChainAdmissionPolicy =
        cjguiInternalBuildRendererResourceChainAdmissionPolicy(
            finalizationIntent
        )
    let executionStateVisibilityAdmissionGuard =
        cjguiInternalBuildRendererExecutionStateVisibilityAdmissionGuard(
            resourceChainAdmissionPolicy
        )
    let finalizationFailurePolicy =
        cjguiInternalBuildRendererBackendReadinessFinalizationFailurePolicy(
            executionStateVisibilityAdmissionGuard
        )
    return cjguiInternalBuildRendererNoBackendReadyImplementationReadiness(
        finalizationFailurePolicy
    )
}
