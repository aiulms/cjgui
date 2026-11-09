package cjgui

// Owner: Renderer state write no-write value boundary.
// Truth: 只消费 CjguiInternalRendererNoFrameSchedulerReadiness，表达 future
// renderer state write intent、state mutation policy、commit visibility guard、
// rollback state policy 与 no-state-write readiness 的内部 value facts。
// Stop-line: 这里不修改 renderer state，不接全局可变状态，不新增 module-level
// mutable state，不记录 frame completion，不提交 GPU work，不触发 render side effect，
// 不创建 backend / platform object，不开放 external reporting surface。
// Same-shape Boundary Brake: 本 owner 新增 mutation / visibility / rollback /
// no-state-write vocabulary，不把 no-frame-scheduler readiness 包成 receipt /
// record / publication。

// State write intent 只表达 future state write owner intent；
// 它不是 renderer state mutation，也不是 backend-readiness wrapper。
struct CjguiInternalRendererStateWriteIntent {
    let noFrameSchedulerReadiness: CjguiInternalRendererNoFrameSchedulerReadiness
    let didPrepareRendererStateWriteIntent: Bool
    let shouldDeferRendererStateWriteIntent: Bool
    let shouldReportRendererStateWriteIntentBlocked: Bool
    let didPreserveRendererNoFrameSchedulerReadiness: Bool
    let didDefineFutureStateWriteIntent: Bool
    let didDescribeStateMutationIntentFacts: Bool
    let didDescribeCommitVisibilityFacts: Bool
    let didDescribeRollbackStateFacts: Bool
    let didKeepStateWriteIntentValueOnly: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidBackendReadinessPermission: Bool
    let didAvoidFrameCompletionRecording: Bool
    let didAvoidThinWrapper: Bool

    init(
        noFrameSchedulerReadiness: CjguiInternalRendererNoFrameSchedulerReadiness,
        didPrepareRendererStateWriteIntent: Bool,
        shouldDeferRendererStateWriteIntent: Bool,
        shouldReportRendererStateWriteIntentBlocked: Bool,
        didPreserveRendererNoFrameSchedulerReadiness: Bool,
        didDefineFutureStateWriteIntent: Bool,
        didDescribeStateMutationIntentFacts: Bool,
        didDescribeCommitVisibilityFacts: Bool,
        didDescribeRollbackStateFacts: Bool,
        didKeepStateWriteIntentValueOnly: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidBackendReadinessPermission: Bool,
        didAvoidFrameCompletionRecording: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noFrameSchedulerReadiness = noFrameSchedulerReadiness
        this.didPrepareRendererStateWriteIntent =
            didPrepareRendererStateWriteIntent
        this.shouldDeferRendererStateWriteIntent =
            shouldDeferRendererStateWriteIntent
        this.shouldReportRendererStateWriteIntentBlocked =
            shouldReportRendererStateWriteIntentBlocked
        this.didPreserveRendererNoFrameSchedulerReadiness =
            didPreserveRendererNoFrameSchedulerReadiness
        this.didDefineFutureStateWriteIntent = didDefineFutureStateWriteIntent
        this.didDescribeStateMutationIntentFacts =
            didDescribeStateMutationIntentFacts
        this.didDescribeCommitVisibilityFacts =
            didDescribeCommitVisibilityFacts
        this.didDescribeRollbackStateFacts = didDescribeRollbackStateFacts
        this.didKeepStateWriteIntentValueOnly =
            didKeepStateWriteIntentValueOnly
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidBackendReadinessPermission =
            didAvoidBackendReadinessPermission
        this.didAvoidFrameCompletionRecording =
            didAvoidFrameCompletionRecording
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

// State mutation policy 只表达 future mutation vocabulary；
// 它不写 state，不接全局可变状态，也不创建 mutable singleton。
struct CjguiInternalRendererStateMutationPolicy {
    let stateWriteIntent: CjguiInternalRendererStateWriteIntent
    let didPrepareRendererStateMutationPolicy: Bool
    let shouldDeferRendererStateMutationPolicy: Bool
    let shouldReportRendererStateMutationPolicyBlocked: Bool
    let didPreserveRendererStateWriteIntent: Bool
    let didDefineFutureStateMutationPolicy: Bool
    let didDescribeMutationScopeFacts: Bool
    let didDescribeNoMutationStopLine: Bool
    let didDescribeNoFrameCompletionRecordFacts: Bool
    let didKeepStateMutationPolicyValueOnly: Bool
    let didAvoidGlobalMutableState: Bool
    let didAvoidModuleLevelMutableState: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidBackendReadinessPermission: Bool

    init(
        stateWriteIntent: CjguiInternalRendererStateWriteIntent,
        didPrepareRendererStateMutationPolicy: Bool,
        shouldDeferRendererStateMutationPolicy: Bool,
        shouldReportRendererStateMutationPolicyBlocked: Bool,
        didPreserveRendererStateWriteIntent: Bool,
        didDefineFutureStateMutationPolicy: Bool,
        didDescribeMutationScopeFacts: Bool,
        didDescribeNoMutationStopLine: Bool,
        didDescribeNoFrameCompletionRecordFacts: Bool,
        didKeepStateMutationPolicyValueOnly: Bool,
        didAvoidGlobalMutableState: Bool,
        didAvoidModuleLevelMutableState: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidBackendReadinessPermission: Bool
    ) {
        this.stateWriteIntent = stateWriteIntent
        this.didPrepareRendererStateMutationPolicy =
            didPrepareRendererStateMutationPolicy
        this.shouldDeferRendererStateMutationPolicy =
            shouldDeferRendererStateMutationPolicy
        this.shouldReportRendererStateMutationPolicyBlocked =
            shouldReportRendererStateMutationPolicyBlocked
        this.didPreserveRendererStateWriteIntent =
            didPreserveRendererStateWriteIntent
        this.didDefineFutureStateMutationPolicy =
            didDefineFutureStateMutationPolicy
        this.didDescribeMutationScopeFacts = didDescribeMutationScopeFacts
        this.didDescribeNoMutationStopLine = didDescribeNoMutationStopLine
        this.didDescribeNoFrameCompletionRecordFacts =
            didDescribeNoFrameCompletionRecordFacts
        this.didKeepStateMutationPolicyValueOnly =
            didKeepStateMutationPolicyValueOnly
        this.didAvoidGlobalMutableState = didAvoidGlobalMutableState
        this.didAvoidModuleLevelMutableState = didAvoidModuleLevelMutableState
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidBackendReadinessPermission =
            didAvoidBackendReadinessPermission
    }
}

// Commit visibility guard 只表达 future visibility constraints；
// 它不提交 command buffer，不提交 GPU work，也不记录 completion。
struct CjguiInternalRendererCommitVisibilityGuard {
    let mutationPolicy: CjguiInternalRendererStateMutationPolicy
    let didPrepareRendererCommitVisibilityGuard: Bool
    let shouldDeferRendererCommitVisibilityGuard: Bool
    let shouldReportRendererCommitVisibilityGuardBlocked: Bool
    let didPreserveRendererStateMutationPolicy: Bool
    let didDefineFutureCommitVisibilityGuard: Bool
    let didDescribeCommitVisibilityFacts: Bool
    let didDescribeNoSubmitVisibilityStopLine: Bool
    let didDescribeFrameCompletionNonRecordingFacts: Bool
    let didKeepCommitVisibilityGuardValueOnly: Bool
    let didAvoidCommandBufferCommit: Bool
    let didAvoidGpuSubmission: Bool
    let didAvoidFrameCompletionRecording: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidExternalReportSurface: Bool

    init(
        mutationPolicy: CjguiInternalRendererStateMutationPolicy,
        didPrepareRendererCommitVisibilityGuard: Bool,
        shouldDeferRendererCommitVisibilityGuard: Bool,
        shouldReportRendererCommitVisibilityGuardBlocked: Bool,
        didPreserveRendererStateMutationPolicy: Bool,
        didDefineFutureCommitVisibilityGuard: Bool,
        didDescribeCommitVisibilityFacts: Bool,
        didDescribeNoSubmitVisibilityStopLine: Bool,
        didDescribeFrameCompletionNonRecordingFacts: Bool,
        didKeepCommitVisibilityGuardValueOnly: Bool,
        didAvoidCommandBufferCommit: Bool,
        didAvoidGpuSubmission: Bool,
        didAvoidFrameCompletionRecording: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidExternalReportSurface: Bool
    ) {
        this.mutationPolicy = mutationPolicy
        this.didPrepareRendererCommitVisibilityGuard =
            didPrepareRendererCommitVisibilityGuard
        this.shouldDeferRendererCommitVisibilityGuard =
            shouldDeferRendererCommitVisibilityGuard
        this.shouldReportRendererCommitVisibilityGuardBlocked =
            shouldReportRendererCommitVisibilityGuardBlocked
        this.didPreserveRendererStateMutationPolicy =
            didPreserveRendererStateMutationPolicy
        this.didDefineFutureCommitVisibilityGuard =
            didDefineFutureCommitVisibilityGuard
        this.didDescribeCommitVisibilityFacts =
            didDescribeCommitVisibilityFacts
        this.didDescribeNoSubmitVisibilityStopLine =
            didDescribeNoSubmitVisibilityStopLine
        this.didDescribeFrameCompletionNonRecordingFacts =
            didDescribeFrameCompletionNonRecordingFacts
        this.didKeepCommitVisibilityGuardValueOnly =
            didKeepCommitVisibilityGuardValueOnly
        this.didAvoidCommandBufferCommit = didAvoidCommandBufferCommit
        this.didAvoidGpuSubmission = didAvoidGpuSubmission
        this.didAvoidFrameCompletionRecording =
            didAvoidFrameCompletionRecording
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidExternalReportSurface = didAvoidExternalReportSurface
    }
}

// Rollback state policy 只表达 future rollback / no-write fallback facts；
// 它不发布 external report，不注册 external signal，也不 mutate renderer state。
struct CjguiInternalRendererRollbackStatePolicy {
    let visibilityGuard: CjguiInternalRendererCommitVisibilityGuard
    let didPrepareRendererRollbackStatePolicy: Bool
    let shouldDeferRendererRollbackStatePolicy: Bool
    let shouldReportRendererRollbackStatePolicyBlocked: Bool
    let didPreserveRendererCommitVisibilityGuard: Bool
    let didDefineFutureRollbackStatePolicy: Bool
    let didDescribeRollbackStateFacts: Bool
    let didDescribeFailureStatePreservationFacts: Bool
    let didDescribeNoDrawNoWriteFallbackFacts: Bool
    let didKeepRollbackStatePolicyValueOnly: Bool
    let didAvoidStateSnapshotPublication: Bool
    let didAvoidExternalReportPublication: Bool
    let didAvoidExternalSignalSurface: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidBackendReadinessPermission: Bool

    init(
        visibilityGuard: CjguiInternalRendererCommitVisibilityGuard,
        didPrepareRendererRollbackStatePolicy: Bool,
        shouldDeferRendererRollbackStatePolicy: Bool,
        shouldReportRendererRollbackStatePolicyBlocked: Bool,
        didPreserveRendererCommitVisibilityGuard: Bool,
        didDefineFutureRollbackStatePolicy: Bool,
        didDescribeRollbackStateFacts: Bool,
        didDescribeFailureStatePreservationFacts: Bool,
        didDescribeNoDrawNoWriteFallbackFacts: Bool,
        didKeepRollbackStatePolicyValueOnly: Bool,
        didAvoidStateSnapshotPublication: Bool,
        didAvoidExternalReportPublication: Bool,
        didAvoidExternalSignalSurface: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidBackendReadinessPermission: Bool
    ) {
        this.visibilityGuard = visibilityGuard
        this.didPrepareRendererRollbackStatePolicy =
            didPrepareRendererRollbackStatePolicy
        this.shouldDeferRendererRollbackStatePolicy =
            shouldDeferRendererRollbackStatePolicy
        this.shouldReportRendererRollbackStatePolicyBlocked =
            shouldReportRendererRollbackStatePolicyBlocked
        this.didPreserveRendererCommitVisibilityGuard =
            didPreserveRendererCommitVisibilityGuard
        this.didDefineFutureRollbackStatePolicy =
            didDefineFutureRollbackStatePolicy
        this.didDescribeRollbackStateFacts = didDescribeRollbackStateFacts
        this.didDescribeFailureStatePreservationFacts =
            didDescribeFailureStatePreservationFacts
        this.didDescribeNoDrawNoWriteFallbackFacts =
            didDescribeNoDrawNoWriteFallbackFacts
        this.didKeepRollbackStatePolicyValueOnly =
            didKeepRollbackStatePolicyValueOnly
        this.didAvoidStateSnapshotPublication =
            didAvoidStateSnapshotPublication
        this.didAvoidExternalReportPublication =
            didAvoidExternalReportPublication
        this.didAvoidExternalSignalSurface = didAvoidExternalSignalSurface
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidBackendReadinessPermission =
            didAvoidBackendReadinessPermission
    }
}

// No-state-write readiness 是本 owner 的 endpoint；readiness 只表示 future
// state write boundary 可以继续评估，不代表 mutation, backend, render, submit,
// completion recording, external report, or external API permission。
struct CjguiInternalRendererNoStateWriteReadiness {
    let rollbackPolicy: CjguiInternalRendererRollbackStatePolicy
    let isRendererNoStateWriteReady: Bool
    let canFutureRendererStateWriteBoundaryEvaluate: Bool
    let shouldDeferRendererNoStateWriteReadiness: Bool
    let shouldReportRendererNoStateWriteReadinessBlocked: Bool
    let didSealRendererNoStateWriteReadiness: Bool
    let didPreserveRendererRollbackStatePolicy: Bool
    let didKeepNoStateWriteReadinessValueOnly: Bool
    let didConfirmNoRendererStateMutation: Bool
    let didConfirmNoGlobalMutableState: Bool
    let didConfirmNoModuleLevelMutableState: Bool
    let didConfirmNoCommandBufferCommit: Bool
    let didConfirmNoGpuSubmission: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoFrameCompletionRecord: Bool
    let didConfirmNoBackendReadinessImplementation: Bool
    let didConfirmNoExternalReportSurface: Bool
    let didConfirmNoExternalApiSurface: Bool
    let didConfirmNoPlatformObjectCreation: Bool
    let didConfirmNoResourceHandleSurface: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didAvoidBackendReadinessWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidFrameCompletionWrapper: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        rollbackPolicy: CjguiInternalRendererRollbackStatePolicy,
        isRendererNoStateWriteReady: Bool,
        canFutureRendererStateWriteBoundaryEvaluate: Bool,
        shouldDeferRendererNoStateWriteReadiness: Bool,
        shouldReportRendererNoStateWriteReadinessBlocked: Bool,
        didSealRendererNoStateWriteReadiness: Bool,
        didPreserveRendererRollbackStatePolicy: Bool,
        didKeepNoStateWriteReadinessValueOnly: Bool,
        didConfirmNoRendererStateMutation: Bool,
        didConfirmNoGlobalMutableState: Bool,
        didConfirmNoModuleLevelMutableState: Bool,
        didConfirmNoCommandBufferCommit: Bool,
        didConfirmNoGpuSubmission: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoFrameCompletionRecord: Bool,
        didConfirmNoBackendReadinessImplementation: Bool,
        didConfirmNoExternalReportSurface: Bool,
        didConfirmNoExternalApiSurface: Bool,
        didConfirmNoPlatformObjectCreation: Bool,
        didConfirmNoResourceHandleSurface: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didAvoidBackendReadinessWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidFrameCompletionWrapper: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.rollbackPolicy = rollbackPolicy
        this.isRendererNoStateWriteReady = isRendererNoStateWriteReady
        this.canFutureRendererStateWriteBoundaryEvaluate =
            canFutureRendererStateWriteBoundaryEvaluate
        this.shouldDeferRendererNoStateWriteReadiness =
            shouldDeferRendererNoStateWriteReadiness
        this.shouldReportRendererNoStateWriteReadinessBlocked =
            shouldReportRendererNoStateWriteReadinessBlocked
        this.didSealRendererNoStateWriteReadiness =
            didSealRendererNoStateWriteReadiness
        this.didPreserveRendererRollbackStatePolicy =
            didPreserveRendererRollbackStatePolicy
        this.didKeepNoStateWriteReadinessValueOnly =
            didKeepNoStateWriteReadinessValueOnly
        this.didConfirmNoRendererStateMutation =
            didConfirmNoRendererStateMutation
        this.didConfirmNoGlobalMutableState = didConfirmNoGlobalMutableState
        this.didConfirmNoModuleLevelMutableState =
            didConfirmNoModuleLevelMutableState
        this.didConfirmNoCommandBufferCommit = didConfirmNoCommandBufferCommit
        this.didConfirmNoGpuSubmission = didConfirmNoGpuSubmission
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoFrameCompletionRecord =
            didConfirmNoFrameCompletionRecord
        this.didConfirmNoBackendReadinessImplementation =
            didConfirmNoBackendReadinessImplementation
        this.didConfirmNoExternalReportSurface =
            didConfirmNoExternalReportSurface
        this.didConfirmNoExternalApiSurface = didConfirmNoExternalApiSurface
        this.didConfirmNoPlatformObjectCreation =
            didConfirmNoPlatformObjectCreation
        this.didConfirmNoResourceHandleSurface =
            didConfirmNoResourceHandleSurface
        this.didConfirmNoPointerLikeResource = didConfirmNoPointerLikeResource
        this.didAvoidBackendReadinessWrapper = didAvoidBackendReadinessWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidFrameCompletionWrapper = didAvoidFrameCompletionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererStateWriteIntent(
    noFrameSchedulerReadiness: CjguiInternalRendererNoFrameSchedulerReadiness
): CjguiInternalRendererStateWriteIntent {
    let noFrameSchedulerReady =
        noFrameSchedulerReadiness.isRendererNoFrameSchedulerReady &&
        noFrameSchedulerReadiness.canFutureRendererFramePacingBoundaryEvaluate &&
        noFrameSchedulerReadiness.didSealRendererNoFrameSchedulerReadiness &&
        noFrameSchedulerReadiness.didPreserveRendererPacingFailurePolicy &&
        noFrameSchedulerReadiness.didKeepNoFrameSchedulerReadinessValueOnly &&
        noFrameSchedulerReadiness.didConfirmNoFrameSchedulerCreated &&
        noFrameSchedulerReadiness.didConfirmNoFrameClockCreated &&
        noFrameSchedulerReadiness.didConfirmNoFrameCallbackBound &&
        noFrameSchedulerReadiness.didConfirmNoContinuousFrameDriverStarted &&
        noFrameSchedulerReadiness.didConfirmNoBackendObjectCreated &&
        noFrameSchedulerReadiness.didConfirmNoPlatformObjectCreated &&
        noFrameSchedulerReadiness.didConfirmNoCommandBufferCommit &&
        noFrameSchedulerReadiness.didConfirmNoGpuSubmission &&
        noFrameSchedulerReadiness.didConfirmNoRenderSideEffect &&
        noFrameSchedulerReadiness.didConfirmNoRendererStateMutation &&
        noFrameSchedulerReadiness.didConfirmNoResourceHandleSurface &&
        noFrameSchedulerReadiness.didConfirmNoPointerLikeResource &&
        noFrameSchedulerReadiness.didAvoidBackendReadinessPermission &&
        noFrameSchedulerReadiness.didAvoidThinWrapper &&
        noFrameSchedulerReadiness.didStayFullRebuildOnly &&
        noFrameSchedulerReadiness.shouldDeferRendererNoFrameSchedulerReadiness == false &&
        noFrameSchedulerReadiness.shouldReportRendererNoFrameSchedulerReadinessBlocked == false
    let intentDeferred =
        noFrameSchedulerReadiness.isRendererNoFrameSchedulerReady == false &&
        noFrameSchedulerReadiness.canFutureRendererFramePacingBoundaryEvaluate == false &&
        noFrameSchedulerReadiness.shouldDeferRendererNoFrameSchedulerReadiness &&
        noFrameSchedulerReadiness.shouldReportRendererNoFrameSchedulerReadinessBlocked == false
    let intentInconsistent = (
        noFrameSchedulerReadiness.isRendererNoFrameSchedulerReady &&
            (
                noFrameSchedulerReadiness.canFutureRendererFramePacingBoundaryEvaluate == false ||
                noFrameSchedulerReadiness.didSealRendererNoFrameSchedulerReadiness == false ||
                noFrameSchedulerReadiness.didPreserveRendererPacingFailurePolicy == false ||
                noFrameSchedulerReadiness.didKeepNoFrameSchedulerReadinessValueOnly == false ||
                noFrameSchedulerReadiness.didConfirmNoFrameSchedulerCreated == false ||
                noFrameSchedulerReadiness.didConfirmNoFrameClockCreated == false ||
                noFrameSchedulerReadiness.didConfirmNoFrameCallbackBound == false ||
                noFrameSchedulerReadiness.didConfirmNoContinuousFrameDriverStarted == false ||
                noFrameSchedulerReadiness.didConfirmNoBackendObjectCreated == false ||
                noFrameSchedulerReadiness.didConfirmNoPlatformObjectCreated == false ||
                noFrameSchedulerReadiness.didConfirmNoCommandBufferCommit == false ||
                noFrameSchedulerReadiness.didConfirmNoGpuSubmission == false ||
                noFrameSchedulerReadiness.didConfirmNoRenderSideEffect == false ||
                noFrameSchedulerReadiness.didConfirmNoRendererStateMutation == false ||
                noFrameSchedulerReadiness.didConfirmNoResourceHandleSurface == false ||
                noFrameSchedulerReadiness.didConfirmNoPointerLikeResource == false ||
                noFrameSchedulerReadiness.didAvoidBackendReadinessPermission == false ||
                noFrameSchedulerReadiness.didAvoidThinWrapper == false ||
                noFrameSchedulerReadiness.didStayFullRebuildOnly == false ||
                noFrameSchedulerReadiness.shouldDeferRendererNoFrameSchedulerReadiness ||
                noFrameSchedulerReadiness.shouldReportRendererNoFrameSchedulerReadinessBlocked
            )
        ) ||
        (noFrameSchedulerReadiness.canFutureRendererFramePacingBoundaryEvaluate &&
            noFrameSchedulerReadiness.isRendererNoFrameSchedulerReady == false) ||
        (noFrameSchedulerReadiness.shouldDeferRendererNoFrameSchedulerReadiness &&
            noFrameSchedulerReadiness.shouldReportRendererNoFrameSchedulerReadinessBlocked)

    // fail-closed：不能把 no-frame-scheduler readiness 薄包成 state write intent。
    if (
        noFrameSchedulerReadiness.shouldReportRendererNoFrameSchedulerReadinessBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererStateWriteIntent(
            noFrameSchedulerReadiness,
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

    if (noFrameSchedulerReady) {
        return CjguiInternalRendererStateWriteIntent(
            noFrameSchedulerReadiness,
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
        return CjguiInternalRendererStateWriteIntent(
            noFrameSchedulerReadiness,
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

    return CjguiInternalRendererStateWriteIntent(
        noFrameSchedulerReadiness,
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

func cjguiInternalBuildRendererStateMutationPolicy(
    stateWriteIntent: CjguiInternalRendererStateWriteIntent
): CjguiInternalRendererStateMutationPolicy {
    let intentReady =
        stateWriteIntent.didPrepareRendererStateWriteIntent &&
        stateWriteIntent.didPreserveRendererNoFrameSchedulerReadiness &&
        stateWriteIntent.didDefineFutureStateWriteIntent &&
        stateWriteIntent.didDescribeStateMutationIntentFacts &&
        stateWriteIntent.didDescribeCommitVisibilityFacts &&
        stateWriteIntent.didDescribeRollbackStateFacts &&
        stateWriteIntent.didKeepStateWriteIntentValueOnly &&
        stateWriteIntent.didAvoidRendererStateMutation &&
        stateWriteIntent.didAvoidBackendReadinessPermission &&
        stateWriteIntent.didAvoidFrameCompletionRecording &&
        stateWriteIntent.didAvoidThinWrapper &&
        stateWriteIntent.shouldDeferRendererStateWriteIntent == false &&
        stateWriteIntent.shouldReportRendererStateWriteIntentBlocked == false
    let policyDeferred =
        stateWriteIntent.didPrepareRendererStateWriteIntent == false &&
        stateWriteIntent.shouldDeferRendererStateWriteIntent &&
        stateWriteIntent.shouldReportRendererStateWriteIntentBlocked == false
    let policyInconsistent = (
        stateWriteIntent.didPrepareRendererStateWriteIntent &&
            (
                stateWriteIntent.didPreserveRendererNoFrameSchedulerReadiness == false ||
                stateWriteIntent.didDefineFutureStateWriteIntent == false ||
                stateWriteIntent.didDescribeStateMutationIntentFacts == false ||
                stateWriteIntent.didDescribeCommitVisibilityFacts == false ||
                stateWriteIntent.didDescribeRollbackStateFacts == false ||
                stateWriteIntent.didKeepStateWriteIntentValueOnly == false ||
                stateWriteIntent.didAvoidRendererStateMutation == false ||
                stateWriteIntent.didAvoidBackendReadinessPermission == false ||
                stateWriteIntent.didAvoidFrameCompletionRecording == false ||
                stateWriteIntent.didAvoidThinWrapper == false ||
                stateWriteIntent.shouldDeferRendererStateWriteIntent ||
                stateWriteIntent.shouldReportRendererStateWriteIntentBlocked
            )
        ) ||
        (stateWriteIntent.didPreserveRendererNoFrameSchedulerReadiness &&
            stateWriteIntent.didPrepareRendererStateWriteIntent == false) ||
        (stateWriteIntent.shouldDeferRendererStateWriteIntent &&
            stateWriteIntent.shouldReportRendererStateWriteIntentBlocked)

    // mutation policy 只记录 policy vocabulary；这里不 mutate renderer state。
    if (
        stateWriteIntent.shouldReportRendererStateWriteIntentBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererStateMutationPolicy(
            stateWriteIntent,
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
        return CjguiInternalRendererStateMutationPolicy(
            stateWriteIntent,
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
        return CjguiInternalRendererStateMutationPolicy(
            stateWriteIntent,
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

    return CjguiInternalRendererStateMutationPolicy(
        stateWriteIntent,
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

func cjguiInternalBuildRendererCommitVisibilityGuard(
    mutationPolicy: CjguiInternalRendererStateMutationPolicy
): CjguiInternalRendererCommitVisibilityGuard {
    let policyReady =
        mutationPolicy.didPrepareRendererStateMutationPolicy &&
        mutationPolicy.didPreserveRendererStateWriteIntent &&
        mutationPolicy.didDefineFutureStateMutationPolicy &&
        mutationPolicy.didDescribeMutationScopeFacts &&
        mutationPolicy.didDescribeNoMutationStopLine &&
        mutationPolicy.didDescribeNoFrameCompletionRecordFacts &&
        mutationPolicy.didKeepStateMutationPolicyValueOnly &&
        mutationPolicy.didAvoidGlobalMutableState &&
        mutationPolicy.didAvoidModuleLevelMutableState &&
        mutationPolicy.didAvoidRendererStateMutation &&
        mutationPolicy.didAvoidBackendReadinessPermission &&
        mutationPolicy.shouldDeferRendererStateMutationPolicy == false &&
        mutationPolicy.shouldReportRendererStateMutationPolicyBlocked == false
    let guardDeferred =
        mutationPolicy.didPrepareRendererStateMutationPolicy == false &&
        mutationPolicy.shouldDeferRendererStateMutationPolicy &&
        mutationPolicy.shouldReportRendererStateMutationPolicyBlocked == false
    let guardInconsistent = (
        mutationPolicy.didPrepareRendererStateMutationPolicy &&
            (
                mutationPolicy.didPreserveRendererStateWriteIntent == false ||
                mutationPolicy.didDefineFutureStateMutationPolicy == false ||
                mutationPolicy.didDescribeMutationScopeFacts == false ||
                mutationPolicy.didDescribeNoMutationStopLine == false ||
                mutationPolicy.didDescribeNoFrameCompletionRecordFacts == false ||
                mutationPolicy.didKeepStateMutationPolicyValueOnly == false ||
                mutationPolicy.didAvoidGlobalMutableState == false ||
                mutationPolicy.didAvoidModuleLevelMutableState == false ||
                mutationPolicy.didAvoidRendererStateMutation == false ||
                mutationPolicy.didAvoidBackendReadinessPermission == false ||
                mutationPolicy.shouldDeferRendererStateMutationPolicy ||
                mutationPolicy.shouldReportRendererStateMutationPolicyBlocked
            )
        ) ||
        (mutationPolicy.didPreserveRendererStateWriteIntent &&
            mutationPolicy.didPrepareRendererStateMutationPolicy == false) ||
        (mutationPolicy.shouldDeferRendererStateMutationPolicy &&
            mutationPolicy.shouldReportRendererStateMutationPolicyBlocked)

    // visibility guard 只记录 commit visibility facts；这里不 submit GPU work。
    if (
        mutationPolicy.shouldReportRendererStateMutationPolicyBlocked ||
        guardInconsistent
    ) {
        return CjguiInternalRendererCommitVisibilityGuard(
            mutationPolicy,
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
        return CjguiInternalRendererCommitVisibilityGuard(
            mutationPolicy,
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
        return CjguiInternalRendererCommitVisibilityGuard(
            mutationPolicy,
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

    return CjguiInternalRendererCommitVisibilityGuard(
        mutationPolicy,
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

func cjguiInternalBuildRendererRollbackStatePolicy(
    visibilityGuard: CjguiInternalRendererCommitVisibilityGuard
): CjguiInternalRendererRollbackStatePolicy {
    let guardReady =
        visibilityGuard.didPrepareRendererCommitVisibilityGuard &&
        visibilityGuard.didPreserveRendererStateMutationPolicy &&
        visibilityGuard.didDefineFutureCommitVisibilityGuard &&
        visibilityGuard.didDescribeCommitVisibilityFacts &&
        visibilityGuard.didDescribeNoSubmitVisibilityStopLine &&
        visibilityGuard.didDescribeFrameCompletionNonRecordingFacts &&
        visibilityGuard.didKeepCommitVisibilityGuardValueOnly &&
        visibilityGuard.didAvoidCommandBufferCommit &&
        visibilityGuard.didAvoidGpuSubmission &&
        visibilityGuard.didAvoidFrameCompletionRecording &&
        visibilityGuard.didAvoidRendererStateMutation &&
        visibilityGuard.didAvoidExternalReportSurface &&
        visibilityGuard.shouldDeferRendererCommitVisibilityGuard == false &&
        visibilityGuard.shouldReportRendererCommitVisibilityGuardBlocked == false
    let policyDeferred =
        visibilityGuard.didPrepareRendererCommitVisibilityGuard == false &&
        visibilityGuard.shouldDeferRendererCommitVisibilityGuard &&
        visibilityGuard.shouldReportRendererCommitVisibilityGuardBlocked == false
    let policyInconsistent = (
        visibilityGuard.didPrepareRendererCommitVisibilityGuard &&
            (
                visibilityGuard.didPreserveRendererStateMutationPolicy == false ||
                visibilityGuard.didDefineFutureCommitVisibilityGuard == false ||
                visibilityGuard.didDescribeCommitVisibilityFacts == false ||
                visibilityGuard.didDescribeNoSubmitVisibilityStopLine == false ||
                visibilityGuard.didDescribeFrameCompletionNonRecordingFacts == false ||
                visibilityGuard.didKeepCommitVisibilityGuardValueOnly == false ||
                visibilityGuard.didAvoidCommandBufferCommit == false ||
                visibilityGuard.didAvoidGpuSubmission == false ||
                visibilityGuard.didAvoidFrameCompletionRecording == false ||
                visibilityGuard.didAvoidRendererStateMutation == false ||
                visibilityGuard.didAvoidExternalReportSurface == false ||
                visibilityGuard.shouldDeferRendererCommitVisibilityGuard ||
                visibilityGuard.shouldReportRendererCommitVisibilityGuardBlocked
            )
        ) ||
        (visibilityGuard.didPreserveRendererStateMutationPolicy &&
            visibilityGuard.didPrepareRendererCommitVisibilityGuard == false) ||
        (visibilityGuard.shouldDeferRendererCommitVisibilityGuard &&
            visibilityGuard.shouldReportRendererCommitVisibilityGuardBlocked)

    // rollback policy 只记录 fallback facts；这里不 publish external report。
    if (
        visibilityGuard.shouldReportRendererCommitVisibilityGuardBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererRollbackStatePolicy(
            visibilityGuard,
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
        return CjguiInternalRendererRollbackStatePolicy(
            visibilityGuard,
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
        return CjguiInternalRendererRollbackStatePolicy(
            visibilityGuard,
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

    return CjguiInternalRendererRollbackStatePolicy(
        visibilityGuard,
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

func cjguiInternalBuildRendererNoStateWriteReadiness(
    rollbackPolicy: CjguiInternalRendererRollbackStatePolicy
): CjguiInternalRendererNoStateWriteReadiness {
    let policyReady =
        rollbackPolicy.didPrepareRendererRollbackStatePolicy &&
        rollbackPolicy.didPreserveRendererCommitVisibilityGuard &&
        rollbackPolicy.didDefineFutureRollbackStatePolicy &&
        rollbackPolicy.didDescribeRollbackStateFacts &&
        rollbackPolicy.didDescribeFailureStatePreservationFacts &&
        rollbackPolicy.didDescribeNoDrawNoWriteFallbackFacts &&
        rollbackPolicy.didKeepRollbackStatePolicyValueOnly &&
        rollbackPolicy.didAvoidStateSnapshotPublication &&
        rollbackPolicy.didAvoidExternalReportPublication &&
        rollbackPolicy.didAvoidExternalSignalSurface &&
        rollbackPolicy.didAvoidRendererStateMutation &&
        rollbackPolicy.didAvoidBackendReadinessPermission &&
        rollbackPolicy.shouldDeferRendererRollbackStatePolicy == false &&
        rollbackPolicy.shouldReportRendererRollbackStatePolicyBlocked == false
    let readinessDeferred =
        rollbackPolicy.didPrepareRendererRollbackStatePolicy == false &&
        rollbackPolicy.shouldDeferRendererRollbackStatePolicy &&
        rollbackPolicy.shouldReportRendererRollbackStatePolicyBlocked == false
    let readinessInconsistent = (
        rollbackPolicy.didPrepareRendererRollbackStatePolicy &&
            (
                rollbackPolicy.didPreserveRendererCommitVisibilityGuard == false ||
                rollbackPolicy.didDefineFutureRollbackStatePolicy == false ||
                rollbackPolicy.didDescribeRollbackStateFacts == false ||
                rollbackPolicy.didDescribeFailureStatePreservationFacts == false ||
                rollbackPolicy.didDescribeNoDrawNoWriteFallbackFacts == false ||
                rollbackPolicy.didKeepRollbackStatePolicyValueOnly == false ||
                rollbackPolicy.didAvoidStateSnapshotPublication == false ||
                rollbackPolicy.didAvoidExternalReportPublication == false ||
                rollbackPolicy.didAvoidExternalSignalSurface == false ||
                rollbackPolicy.didAvoidRendererStateMutation == false ||
                rollbackPolicy.didAvoidBackendReadinessPermission == false ||
                rollbackPolicy.shouldDeferRendererRollbackStatePolicy ||
                rollbackPolicy.shouldReportRendererRollbackStatePolicyBlocked
            )
        ) ||
        (rollbackPolicy.didPreserveRendererCommitVisibilityGuard &&
            rollbackPolicy.didPrepareRendererRollbackStatePolicy == false) ||
        (rollbackPolicy.shouldDeferRendererRollbackStatePolicy &&
            rollbackPolicy.shouldReportRendererRollbackStatePolicyBlocked)

    // readiness endpoint 只封 no-write facts；这里不 create receipt or record。
    if (
        rollbackPolicy.shouldReportRendererRollbackStatePolicyBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoStateWriteReadiness(
            rollbackPolicy,
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
            true
        )
    }

    if (policyReady) {
        return CjguiInternalRendererNoStateWriteReadiness(
            rollbackPolicy,
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
            true
        )
    }

    if (readinessDeferred) {
        return CjguiInternalRendererNoStateWriteReadiness(
            rollbackPolicy,
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
            true
        )
    }

    return CjguiInternalRendererNoStateWriteReadiness(
        rollbackPolicy,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererStateWriteNoWriteDraft(
): CjguiInternalRendererNoStateWriteReadiness {
    let noFrameSchedulerReadiness =
        cjguiInternalExecuteDefaultRendererFramePacingOwnerDraft()
    let stateWriteIntent =
        cjguiInternalBuildRendererStateWriteIntent(noFrameSchedulerReadiness)
    let mutationPolicy =
        cjguiInternalBuildRendererStateMutationPolicy(stateWriteIntent)
    let visibilityGuard =
        cjguiInternalBuildRendererCommitVisibilityGuard(mutationPolicy)
    let rollbackPolicy =
        cjguiInternalBuildRendererRollbackStatePolicy(visibilityGuard)
    return cjguiInternalBuildRendererNoStateWriteReadiness(rollbackPolicy)
}
