package cjgui

// Owner: Renderer backend-readiness value boundary.
// Truth: 只消费 CjguiInternalRendererNoStateWriteReadiness，表达 future
// backend readiness intent、platform lifecycle gate、execution admission gate、
// state visibility gate 与 no-backend-ready readiness 的内部 value facts。
// Stop-line: 这里不创建 backend object，不创建 platform object，不提交 GPU work，
// 不执行 render，不写 renderer state，不暴露 external reporting or API surface。
// Same-shape Boundary Brake: 本 owner 新增 platform lifecycle / execution
// admission / state visibility / no-backend-ready vocabulary，不把 no-state-write
// readiness 包成 receipt / record / publication。

// Backend readiness intent 只表达 future readiness owner intent；
// 它不是 backend-ready permission，也不是 render permission。
struct CjguiInternalRendererBackendReadinessIntent {
    let noStateWriteReadiness: CjguiInternalRendererNoStateWriteReadiness
    let didPrepareRendererBackendReadinessIntent: Bool
    let shouldDeferRendererBackendReadinessIntent: Bool
    let shouldReportRendererBackendReadinessIntentBlocked: Bool
    let didPreserveRendererNoStateWriteReadiness: Bool
    let didDefineFutureBackendReadinessIntent: Bool
    let didDescribePlatformLifecycleGateFacts: Bool
    let didDescribeExecutionAdmissionGateFacts: Bool
    let didDescribeStateVisibilityGateFacts: Bool
    let didKeepBackendReadinessIntentValueOnly: Bool
    let didAvoidBackendReadyPermission: Bool
    let didAvoidPlatformObjectPermission: Bool
    let didAvoidRenderPermission: Bool
    let didAvoidThinWrapper: Bool

    init(
        noStateWriteReadiness: CjguiInternalRendererNoStateWriteReadiness,
        didPrepareRendererBackendReadinessIntent: Bool,
        shouldDeferRendererBackendReadinessIntent: Bool,
        shouldReportRendererBackendReadinessIntentBlocked: Bool,
        didPreserveRendererNoStateWriteReadiness: Bool,
        didDefineFutureBackendReadinessIntent: Bool,
        didDescribePlatformLifecycleGateFacts: Bool,
        didDescribeExecutionAdmissionGateFacts: Bool,
        didDescribeStateVisibilityGateFacts: Bool,
        didKeepBackendReadinessIntentValueOnly: Bool,
        didAvoidBackendReadyPermission: Bool,
        didAvoidPlatformObjectPermission: Bool,
        didAvoidRenderPermission: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noStateWriteReadiness = noStateWriteReadiness
        this.didPrepareRendererBackendReadinessIntent =
            didPrepareRendererBackendReadinessIntent
        this.shouldDeferRendererBackendReadinessIntent =
            shouldDeferRendererBackendReadinessIntent
        this.shouldReportRendererBackendReadinessIntentBlocked =
            shouldReportRendererBackendReadinessIntentBlocked
        this.didPreserveRendererNoStateWriteReadiness =
            didPreserveRendererNoStateWriteReadiness
        this.didDefineFutureBackendReadinessIntent =
            didDefineFutureBackendReadinessIntent
        this.didDescribePlatformLifecycleGateFacts =
            didDescribePlatformLifecycleGateFacts
        this.didDescribeExecutionAdmissionGateFacts =
            didDescribeExecutionAdmissionGateFacts
        this.didDescribeStateVisibilityGateFacts =
            didDescribeStateVisibilityGateFacts
        this.didKeepBackendReadinessIntentValueOnly =
            didKeepBackendReadinessIntentValueOnly
        this.didAvoidBackendReadyPermission = didAvoidBackendReadyPermission
        this.didAvoidPlatformObjectPermission =
            didAvoidPlatformObjectPermission
        this.didAvoidRenderPermission = didAvoidRenderPermission
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

// Platform lifecycle gate 只表达 future lifecycle coverage facts；
// 它不创建 backend object，不创建 platform object，也不持有 resource handle。
struct CjguiInternalRendererPlatformLifecycleGate {
    let readinessIntent: CjguiInternalRendererBackendReadinessIntent
    let didPrepareRendererPlatformLifecycleGate: Bool
    let shouldDeferRendererPlatformLifecycleGate: Bool
    let shouldReportRendererPlatformLifecycleGateBlocked: Bool
    let didPreserveRendererBackendReadinessIntent: Bool
    let didDefineFuturePlatformLifecycleGate: Bool
    let didDescribePlatformResourceCoverageFacts: Bool
    let didDescribeBackendObjectCoverageFacts: Bool
    let didDescribeFramePacingCoverageFacts: Bool
    let didKeepPlatformLifecycleGateValueOnly: Bool
    let didAvoidBackendObjectCreation: Bool
    let didAvoidPlatformObjectCreation: Bool
    let didAvoidResourceHandleSurface: Bool
    let didAvoidPointerLikeResource: Bool
    let didAvoidBackendReadyPermission: Bool

    init(
        readinessIntent: CjguiInternalRendererBackendReadinessIntent,
        didPrepareRendererPlatformLifecycleGate: Bool,
        shouldDeferRendererPlatformLifecycleGate: Bool,
        shouldReportRendererPlatformLifecycleGateBlocked: Bool,
        didPreserveRendererBackendReadinessIntent: Bool,
        didDefineFuturePlatformLifecycleGate: Bool,
        didDescribePlatformResourceCoverageFacts: Bool,
        didDescribeBackendObjectCoverageFacts: Bool,
        didDescribeFramePacingCoverageFacts: Bool,
        didKeepPlatformLifecycleGateValueOnly: Bool,
        didAvoidBackendObjectCreation: Bool,
        didAvoidPlatformObjectCreation: Bool,
        didAvoidResourceHandleSurface: Bool,
        didAvoidPointerLikeResource: Bool,
        didAvoidBackendReadyPermission: Bool
    ) {
        this.readinessIntent = readinessIntent
        this.didPrepareRendererPlatformLifecycleGate =
            didPrepareRendererPlatformLifecycleGate
        this.shouldDeferRendererPlatformLifecycleGate =
            shouldDeferRendererPlatformLifecycleGate
        this.shouldReportRendererPlatformLifecycleGateBlocked =
            shouldReportRendererPlatformLifecycleGateBlocked
        this.didPreserveRendererBackendReadinessIntent =
            didPreserveRendererBackendReadinessIntent
        this.didDefineFuturePlatformLifecycleGate =
            didDefineFuturePlatformLifecycleGate
        this.didDescribePlatformResourceCoverageFacts =
            didDescribePlatformResourceCoverageFacts
        this.didDescribeBackendObjectCoverageFacts =
            didDescribeBackendObjectCoverageFacts
        this.didDescribeFramePacingCoverageFacts =
            didDescribeFramePacingCoverageFacts
        this.didKeepPlatformLifecycleGateValueOnly =
            didKeepPlatformLifecycleGateValueOnly
        this.didAvoidBackendObjectCreation = didAvoidBackendObjectCreation
        this.didAvoidPlatformObjectCreation = didAvoidPlatformObjectCreation
        this.didAvoidResourceHandleSurface = didAvoidResourceHandleSurface
        this.didAvoidPointerLikeResource = didAvoidPointerLikeResource
        this.didAvoidBackendReadyPermission = didAvoidBackendReadyPermission
    }
}

// Execution admission gate 只表达 future no-submit admission facts；
// 它不提交 work，不执行 render，也不观察真实 completion。
struct CjguiInternalRendererExecutionAdmissionGate {
    let platformLifecycleGate: CjguiInternalRendererPlatformLifecycleGate
    let didPrepareRendererExecutionAdmissionGate: Bool
    let shouldDeferRendererExecutionAdmissionGate: Bool
    let shouldReportRendererExecutionAdmissionGateBlocked: Bool
    let didPreserveRendererPlatformLifecycleGate: Bool
    let didDefineFutureExecutionAdmissionGate: Bool
    let didDescribeNoSubmitAdmissionFacts: Bool
    let didDescribeNoRenderExecutionFacts: Bool
    let didDescribeNoCommandCommitFacts: Bool
    let didKeepExecutionAdmissionGateValueOnly: Bool
    let didAvoidCommandBufferCommit: Bool
    let didAvoidGpuSubmission: Bool
    let didAvoidRenderExecution: Bool
    let didAvoidRenderPermission: Bool
    let didAvoidExternalObservationSurface: Bool

    init(
        platformLifecycleGate: CjguiInternalRendererPlatformLifecycleGate,
        didPrepareRendererExecutionAdmissionGate: Bool,
        shouldDeferRendererExecutionAdmissionGate: Bool,
        shouldReportRendererExecutionAdmissionGateBlocked: Bool,
        didPreserveRendererPlatformLifecycleGate: Bool,
        didDefineFutureExecutionAdmissionGate: Bool,
        didDescribeNoSubmitAdmissionFacts: Bool,
        didDescribeNoRenderExecutionFacts: Bool,
        didDescribeNoCommandCommitFacts: Bool,
        didKeepExecutionAdmissionGateValueOnly: Bool,
        didAvoidCommandBufferCommit: Bool,
        didAvoidGpuSubmission: Bool,
        didAvoidRenderExecution: Bool,
        didAvoidRenderPermission: Bool,
        didAvoidExternalObservationSurface: Bool
    ) {
        this.platformLifecycleGate = platformLifecycleGate
        this.didPrepareRendererExecutionAdmissionGate =
            didPrepareRendererExecutionAdmissionGate
        this.shouldDeferRendererExecutionAdmissionGate =
            shouldDeferRendererExecutionAdmissionGate
        this.shouldReportRendererExecutionAdmissionGateBlocked =
            shouldReportRendererExecutionAdmissionGateBlocked
        this.didPreserveRendererPlatformLifecycleGate =
            didPreserveRendererPlatformLifecycleGate
        this.didDefineFutureExecutionAdmissionGate =
            didDefineFutureExecutionAdmissionGate
        this.didDescribeNoSubmitAdmissionFacts =
            didDescribeNoSubmitAdmissionFacts
        this.didDescribeNoRenderExecutionFacts =
            didDescribeNoRenderExecutionFacts
        this.didDescribeNoCommandCommitFacts =
            didDescribeNoCommandCommitFacts
        this.didKeepExecutionAdmissionGateValueOnly =
            didKeepExecutionAdmissionGateValueOnly
        this.didAvoidCommandBufferCommit = didAvoidCommandBufferCommit
        this.didAvoidGpuSubmission = didAvoidGpuSubmission
        this.didAvoidRenderExecution = didAvoidRenderExecution
        this.didAvoidRenderPermission = didAvoidRenderPermission
        this.didAvoidExternalObservationSurface =
            didAvoidExternalObservationSurface
    }
}

// State visibility gate 只表达 future visibility / rollback facts；
// 它不写 renderer state，不记录 frame completion，也不开放 API surface。
struct CjguiInternalRendererStateVisibilityGate {
    let executionAdmissionGate: CjguiInternalRendererExecutionAdmissionGate
    let didPrepareRendererStateVisibilityGate: Bool
    let shouldDeferRendererStateVisibilityGate: Bool
    let shouldReportRendererStateVisibilityGateBlocked: Bool
    let didPreserveRendererExecutionAdmissionGate: Bool
    let didDefineFutureStateVisibilityGate: Bool
    let didDescribeNoStateWriteFacts: Bool
    let didDescribeCommitVisibilityFacts: Bool
    let didDescribeRollbackNoDrawFacts: Bool
    let didKeepStateVisibilityGateValueOnly: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidGlobalMutableState: Bool
    let didAvoidModuleLevelMutableState: Bool
    let didAvoidFrameCompletionRecording: Bool
    let didAvoidExternalApiSurface: Bool

    init(
        executionAdmissionGate: CjguiInternalRendererExecutionAdmissionGate,
        didPrepareRendererStateVisibilityGate: Bool,
        shouldDeferRendererStateVisibilityGate: Bool,
        shouldReportRendererStateVisibilityGateBlocked: Bool,
        didPreserveRendererExecutionAdmissionGate: Bool,
        didDefineFutureStateVisibilityGate: Bool,
        didDescribeNoStateWriteFacts: Bool,
        didDescribeCommitVisibilityFacts: Bool,
        didDescribeRollbackNoDrawFacts: Bool,
        didKeepStateVisibilityGateValueOnly: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidGlobalMutableState: Bool,
        didAvoidModuleLevelMutableState: Bool,
        didAvoidFrameCompletionRecording: Bool,
        didAvoidExternalApiSurface: Bool
    ) {
        this.executionAdmissionGate = executionAdmissionGate
        this.didPrepareRendererStateVisibilityGate =
            didPrepareRendererStateVisibilityGate
        this.shouldDeferRendererStateVisibilityGate =
            shouldDeferRendererStateVisibilityGate
        this.shouldReportRendererStateVisibilityGateBlocked =
            shouldReportRendererStateVisibilityGateBlocked
        this.didPreserveRendererExecutionAdmissionGate =
            didPreserveRendererExecutionAdmissionGate
        this.didDefineFutureStateVisibilityGate =
            didDefineFutureStateVisibilityGate
        this.didDescribeNoStateWriteFacts = didDescribeNoStateWriteFacts
        this.didDescribeCommitVisibilityFacts =
            didDescribeCommitVisibilityFacts
        this.didDescribeRollbackNoDrawFacts = didDescribeRollbackNoDrawFacts
        this.didKeepStateVisibilityGateValueOnly =
            didKeepStateVisibilityGateValueOnly
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidGlobalMutableState = didAvoidGlobalMutableState
        this.didAvoidModuleLevelMutableState = didAvoidModuleLevelMutableState
        this.didAvoidFrameCompletionRecording =
            didAvoidFrameCompletionRecording
        this.didAvoidExternalApiSurface = didAvoidExternalApiSurface
    }
}

// No-backend-ready readiness 是本 owner 的 endpoint；readiness 只表示 future
// backend-readiness boundary 可以继续评估，不代表 backend, render, submit, state
// write, platform object, or external API permission。
struct CjguiInternalRendererNoBackendReadyReadiness {
    let stateVisibilityGate: CjguiInternalRendererStateVisibilityGate
    let isRendererNoBackendReadyReady: Bool
    let canFutureRendererBackendReadinessBoundaryEvaluate: Bool
    let shouldDeferRendererNoBackendReadyReadiness: Bool
    let shouldReportRendererNoBackendReadyReadinessBlocked: Bool
    let didSealRendererNoBackendReadyReadiness: Bool
    let didPreserveRendererStateVisibilityGate: Bool
    let didKeepNoBackendReadyReadinessValueOnly: Bool
    let didConfirmNoBackendObjectCreated: Bool
    let didConfirmNoPlatformObjectCreated: Bool
    let didConfirmNoCommandBufferCommit: Bool
    let didConfirmNoGpuSubmission: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoRendererStateMutation: Bool
    let didConfirmNoExternalApiSurface: Bool
    let didConfirmNoResourceHandleSurface: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didAvoidBackendReadyPermission: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidBackendReadinessReceipt: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        stateVisibilityGate: CjguiInternalRendererStateVisibilityGate,
        isRendererNoBackendReadyReady: Bool,
        canFutureRendererBackendReadinessBoundaryEvaluate: Bool,
        shouldDeferRendererNoBackendReadyReadiness: Bool,
        shouldReportRendererNoBackendReadyReadinessBlocked: Bool,
        didSealRendererNoBackendReadyReadiness: Bool,
        didPreserveRendererStateVisibilityGate: Bool,
        didKeepNoBackendReadyReadinessValueOnly: Bool,
        didConfirmNoBackendObjectCreated: Bool,
        didConfirmNoPlatformObjectCreated: Bool,
        didConfirmNoCommandBufferCommit: Bool,
        didConfirmNoGpuSubmission: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoRendererStateMutation: Bool,
        didConfirmNoExternalApiSurface: Bool,
        didConfirmNoResourceHandleSurface: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didAvoidBackendReadyPermission: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidBackendReadinessReceipt: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.stateVisibilityGate = stateVisibilityGate
        this.isRendererNoBackendReadyReady = isRendererNoBackendReadyReady
        this.canFutureRendererBackendReadinessBoundaryEvaluate =
            canFutureRendererBackendReadinessBoundaryEvaluate
        this.shouldDeferRendererNoBackendReadyReadiness =
            shouldDeferRendererNoBackendReadyReadiness
        this.shouldReportRendererNoBackendReadyReadinessBlocked =
            shouldReportRendererNoBackendReadyReadinessBlocked
        this.didSealRendererNoBackendReadyReadiness =
            didSealRendererNoBackendReadyReadiness
        this.didPreserveRendererStateVisibilityGate =
            didPreserveRendererStateVisibilityGate
        this.didKeepNoBackendReadyReadinessValueOnly =
            didKeepNoBackendReadyReadinessValueOnly
        this.didConfirmNoBackendObjectCreated =
            didConfirmNoBackendObjectCreated
        this.didConfirmNoPlatformObjectCreated =
            didConfirmNoPlatformObjectCreated
        this.didConfirmNoCommandBufferCommit =
            didConfirmNoCommandBufferCommit
        this.didConfirmNoGpuSubmission = didConfirmNoGpuSubmission
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoRendererStateMutation =
            didConfirmNoRendererStateMutation
        this.didConfirmNoExternalApiSurface = didConfirmNoExternalApiSurface
        this.didConfirmNoResourceHandleSurface =
            didConfirmNoResourceHandleSurface
        this.didConfirmNoPointerLikeResource =
            didConfirmNoPointerLikeResource
        this.didAvoidBackendReadyPermission = didAvoidBackendReadyPermission
        this.didAvoidRenderPermissionWrapper =
            didAvoidRenderPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidBackendReadinessReceipt =
            didAvoidBackendReadinessReceipt
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererBackendReadinessIntent(
    noStateWriteReadiness: CjguiInternalRendererNoStateWriteReadiness
): CjguiInternalRendererBackendReadinessIntent {
    let noStateWriteReady =
        noStateWriteReadiness.isRendererNoStateWriteReady &&
        noStateWriteReadiness.canFutureRendererStateWriteBoundaryEvaluate &&
        noStateWriteReadiness.didSealRendererNoStateWriteReadiness &&
        noStateWriteReadiness.didPreserveRendererRollbackStatePolicy &&
        noStateWriteReadiness.didKeepNoStateWriteReadinessValueOnly &&
        noStateWriteReadiness.didConfirmNoRendererStateMutation &&
        noStateWriteReadiness.didConfirmNoGlobalMutableState &&
        noStateWriteReadiness.didConfirmNoModuleLevelMutableState &&
        noStateWriteReadiness.didConfirmNoCommandBufferCommit &&
        noStateWriteReadiness.didConfirmNoGpuSubmission &&
        noStateWriteReadiness.didConfirmNoRenderExecution &&
        noStateWriteReadiness.didConfirmNoFrameCompletionRecord &&
        noStateWriteReadiness.didConfirmNoBackendReadinessImplementation &&
        noStateWriteReadiness.didConfirmNoExternalReportSurface &&
        noStateWriteReadiness.didConfirmNoExternalApiSurface &&
        noStateWriteReadiness.didConfirmNoPlatformObjectCreation &&
        noStateWriteReadiness.didConfirmNoResourceHandleSurface &&
        noStateWriteReadiness.didConfirmNoPointerLikeResource &&
        noStateWriteReadiness.didAvoidBackendReadinessWrapper &&
        noStateWriteReadiness.didAvoidGpuSubmissionWrapper &&
        noStateWriteReadiness.didAvoidFrameCompletionWrapper &&
        noStateWriteReadiness.didAvoidThinWrapper &&
        noStateWriteReadiness.didStayFullRebuildOnly &&
        noStateWriteReadiness.shouldDeferRendererNoStateWriteReadiness == false &&
        noStateWriteReadiness.shouldReportRendererNoStateWriteReadinessBlocked == false
    let intentDeferred =
        noStateWriteReadiness.isRendererNoStateWriteReady == false &&
        noStateWriteReadiness.canFutureRendererStateWriteBoundaryEvaluate == false &&
        noStateWriteReadiness.shouldDeferRendererNoStateWriteReadiness &&
        noStateWriteReadiness.shouldReportRendererNoStateWriteReadinessBlocked == false
    let intentInconsistent = (
        noStateWriteReadiness.isRendererNoStateWriteReady &&
            (
                noStateWriteReadiness.canFutureRendererStateWriteBoundaryEvaluate == false ||
                noStateWriteReadiness.didSealRendererNoStateWriteReadiness == false ||
                noStateWriteReadiness.didPreserveRendererRollbackStatePolicy == false ||
                noStateWriteReadiness.didKeepNoStateWriteReadinessValueOnly == false ||
                noStateWriteReadiness.didConfirmNoRendererStateMutation == false ||
                noStateWriteReadiness.didConfirmNoGlobalMutableState == false ||
                noStateWriteReadiness.didConfirmNoModuleLevelMutableState == false ||
                noStateWriteReadiness.didConfirmNoCommandBufferCommit == false ||
                noStateWriteReadiness.didConfirmNoGpuSubmission == false ||
                noStateWriteReadiness.didConfirmNoRenderExecution == false ||
                noStateWriteReadiness.didConfirmNoFrameCompletionRecord == false ||
                noStateWriteReadiness.didConfirmNoBackendReadinessImplementation == false ||
                noStateWriteReadiness.didConfirmNoExternalReportSurface == false ||
                noStateWriteReadiness.didConfirmNoExternalApiSurface == false ||
                noStateWriteReadiness.didConfirmNoPlatformObjectCreation == false ||
                noStateWriteReadiness.didConfirmNoResourceHandleSurface == false ||
                noStateWriteReadiness.didConfirmNoPointerLikeResource == false ||
                noStateWriteReadiness.didAvoidBackendReadinessWrapper == false ||
                noStateWriteReadiness.didAvoidGpuSubmissionWrapper == false ||
                noStateWriteReadiness.didAvoidFrameCompletionWrapper == false ||
                noStateWriteReadiness.didAvoidThinWrapper == false ||
                noStateWriteReadiness.didStayFullRebuildOnly == false ||
                noStateWriteReadiness.shouldDeferRendererNoStateWriteReadiness ||
                noStateWriteReadiness.shouldReportRendererNoStateWriteReadinessBlocked
            )
        ) ||
        (noStateWriteReadiness.canFutureRendererStateWriteBoundaryEvaluate &&
            noStateWriteReadiness.isRendererNoStateWriteReady == false) ||
        (noStateWriteReadiness.shouldDeferRendererNoStateWriteReadiness &&
            noStateWriteReadiness.shouldReportRendererNoStateWriteReadinessBlocked)

    // fail-closed：不能把 no-state-write readiness 薄包成 backend readiness intent。
    if (
        noStateWriteReadiness.shouldReportRendererNoStateWriteReadinessBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererBackendReadinessIntent(
            noStateWriteReadiness,
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

    if (noStateWriteReady) {
        return CjguiInternalRendererBackendReadinessIntent(
            noStateWriteReadiness,
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
        return CjguiInternalRendererBackendReadinessIntent(
            noStateWriteReadiness,
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

    return CjguiInternalRendererBackendReadinessIntent(
        noStateWriteReadiness,
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

func cjguiInternalBuildRendererPlatformLifecycleGate(
    readinessIntent: CjguiInternalRendererBackendReadinessIntent
): CjguiInternalRendererPlatformLifecycleGate {
    let intentReady =
        readinessIntent.didPrepareRendererBackendReadinessIntent &&
        readinessIntent.didPreserveRendererNoStateWriteReadiness &&
        readinessIntent.didDefineFutureBackendReadinessIntent &&
        readinessIntent.didDescribePlatformLifecycleGateFacts &&
        readinessIntent.didDescribeExecutionAdmissionGateFacts &&
        readinessIntent.didDescribeStateVisibilityGateFacts &&
        readinessIntent.didKeepBackendReadinessIntentValueOnly &&
        readinessIntent.didAvoidBackendReadyPermission &&
        readinessIntent.didAvoidPlatformObjectPermission &&
        readinessIntent.didAvoidRenderPermission &&
        readinessIntent.didAvoidThinWrapper &&
        readinessIntent.shouldDeferRendererBackendReadinessIntent == false &&
        readinessIntent.shouldReportRendererBackendReadinessIntentBlocked == false
    let gateDeferred =
        readinessIntent.didPrepareRendererBackendReadinessIntent == false &&
        readinessIntent.shouldDeferRendererBackendReadinessIntent &&
        readinessIntent.shouldReportRendererBackendReadinessIntentBlocked == false
    let gateInconsistent = (
        readinessIntent.didPrepareRendererBackendReadinessIntent &&
            (
                readinessIntent.didPreserveRendererNoStateWriteReadiness == false ||
                readinessIntent.didDefineFutureBackendReadinessIntent == false ||
                readinessIntent.didDescribePlatformLifecycleGateFacts == false ||
                readinessIntent.didDescribeExecutionAdmissionGateFacts == false ||
                readinessIntent.didDescribeStateVisibilityGateFacts == false ||
                readinessIntent.didKeepBackendReadinessIntentValueOnly == false ||
                readinessIntent.didAvoidBackendReadyPermission == false ||
                readinessIntent.didAvoidPlatformObjectPermission == false ||
                readinessIntent.didAvoidRenderPermission == false ||
                readinessIntent.didAvoidThinWrapper == false ||
                readinessIntent.shouldDeferRendererBackendReadinessIntent ||
                readinessIntent.shouldReportRendererBackendReadinessIntentBlocked
            )
        ) ||
        (readinessIntent.didPreserveRendererNoStateWriteReadiness &&
            readinessIntent.didPrepareRendererBackendReadinessIntent == false) ||
        (readinessIntent.shouldDeferRendererBackendReadinessIntent &&
            readinessIntent.shouldReportRendererBackendReadinessIntentBlocked)

    // platform lifecycle gate 只记录 coverage facts；这里不创建 platform object。
    if (
        readinessIntent.shouldReportRendererBackendReadinessIntentBlocked ||
        gateInconsistent
    ) {
        return CjguiInternalRendererPlatformLifecycleGate(
            readinessIntent,
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

    if (intentReady) {
        return CjguiInternalRendererPlatformLifecycleGate(
            readinessIntent,
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
        return CjguiInternalRendererPlatformLifecycleGate(
            readinessIntent,
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

    return CjguiInternalRendererPlatformLifecycleGate(
        readinessIntent,
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

func cjguiInternalBuildRendererExecutionAdmissionGate(
    platformLifecycleGate: CjguiInternalRendererPlatformLifecycleGate
): CjguiInternalRendererExecutionAdmissionGate {
    let gateReady =
        platformLifecycleGate.didPrepareRendererPlatformLifecycleGate &&
        platformLifecycleGate.didPreserveRendererBackendReadinessIntent &&
        platformLifecycleGate.didDefineFuturePlatformLifecycleGate &&
        platformLifecycleGate.didDescribePlatformResourceCoverageFacts &&
        platformLifecycleGate.didDescribeBackendObjectCoverageFacts &&
        platformLifecycleGate.didDescribeFramePacingCoverageFacts &&
        platformLifecycleGate.didKeepPlatformLifecycleGateValueOnly &&
        platformLifecycleGate.didAvoidBackendObjectCreation &&
        platformLifecycleGate.didAvoidPlatformObjectCreation &&
        platformLifecycleGate.didAvoidResourceHandleSurface &&
        platformLifecycleGate.didAvoidPointerLikeResource &&
        platformLifecycleGate.didAvoidBackendReadyPermission &&
        platformLifecycleGate.shouldDeferRendererPlatformLifecycleGate == false &&
        platformLifecycleGate.shouldReportRendererPlatformLifecycleGateBlocked == false
    let admissionDeferred =
        platformLifecycleGate.didPrepareRendererPlatformLifecycleGate == false &&
        platformLifecycleGate.shouldDeferRendererPlatformLifecycleGate &&
        platformLifecycleGate.shouldReportRendererPlatformLifecycleGateBlocked == false
    let admissionInconsistent = (
        platformLifecycleGate.didPrepareRendererPlatformLifecycleGate &&
            (
                platformLifecycleGate.didPreserveRendererBackendReadinessIntent == false ||
                platformLifecycleGate.didDefineFuturePlatformLifecycleGate == false ||
                platformLifecycleGate.didDescribePlatformResourceCoverageFacts == false ||
                platformLifecycleGate.didDescribeBackendObjectCoverageFacts == false ||
                platformLifecycleGate.didDescribeFramePacingCoverageFacts == false ||
                platformLifecycleGate.didKeepPlatformLifecycleGateValueOnly == false ||
                platformLifecycleGate.didAvoidBackendObjectCreation == false ||
                platformLifecycleGate.didAvoidPlatformObjectCreation == false ||
                platformLifecycleGate.didAvoidResourceHandleSurface == false ||
                platformLifecycleGate.didAvoidPointerLikeResource == false ||
                platformLifecycleGate.didAvoidBackendReadyPermission == false ||
                platformLifecycleGate.shouldDeferRendererPlatformLifecycleGate ||
                platformLifecycleGate.shouldReportRendererPlatformLifecycleGateBlocked
            )
        ) ||
        (platformLifecycleGate.didPreserveRendererBackendReadinessIntent &&
            platformLifecycleGate.didPrepareRendererPlatformLifecycleGate == false) ||
        (platformLifecycleGate.shouldDeferRendererPlatformLifecycleGate &&
            platformLifecycleGate.shouldReportRendererPlatformLifecycleGateBlocked)

    // execution admission gate 只记录 no-submit facts；这里不 execute render。
    if (
        platformLifecycleGate.shouldReportRendererPlatformLifecycleGateBlocked ||
        admissionInconsistent
    ) {
        return CjguiInternalRendererExecutionAdmissionGate(
            platformLifecycleGate,
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

    if (gateReady) {
        return CjguiInternalRendererExecutionAdmissionGate(
            platformLifecycleGate,
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

    if (admissionDeferred) {
        return CjguiInternalRendererExecutionAdmissionGate(
            platformLifecycleGate,
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

    return CjguiInternalRendererExecutionAdmissionGate(
        platformLifecycleGate,
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

func cjguiInternalBuildRendererStateVisibilityGate(
    executionAdmissionGate: CjguiInternalRendererExecutionAdmissionGate
): CjguiInternalRendererStateVisibilityGate {
    let gateReady =
        executionAdmissionGate.didPrepareRendererExecutionAdmissionGate &&
        executionAdmissionGate.didPreserveRendererPlatformLifecycleGate &&
        executionAdmissionGate.didDefineFutureExecutionAdmissionGate &&
        executionAdmissionGate.didDescribeNoSubmitAdmissionFacts &&
        executionAdmissionGate.didDescribeNoRenderExecutionFacts &&
        executionAdmissionGate.didDescribeNoCommandCommitFacts &&
        executionAdmissionGate.didKeepExecutionAdmissionGateValueOnly &&
        executionAdmissionGate.didAvoidCommandBufferCommit &&
        executionAdmissionGate.didAvoidGpuSubmission &&
        executionAdmissionGate.didAvoidRenderExecution &&
        executionAdmissionGate.didAvoidRenderPermission &&
        executionAdmissionGate.didAvoidExternalObservationSurface &&
        executionAdmissionGate.shouldDeferRendererExecutionAdmissionGate == false &&
        executionAdmissionGate.shouldReportRendererExecutionAdmissionGateBlocked == false
    let stateGateDeferred =
        executionAdmissionGate.didPrepareRendererExecutionAdmissionGate == false &&
        executionAdmissionGate.shouldDeferRendererExecutionAdmissionGate &&
        executionAdmissionGate.shouldReportRendererExecutionAdmissionGateBlocked == false
    let stateGateInconsistent = (
        executionAdmissionGate.didPrepareRendererExecutionAdmissionGate &&
            (
                executionAdmissionGate.didPreserveRendererPlatformLifecycleGate == false ||
                executionAdmissionGate.didDefineFutureExecutionAdmissionGate == false ||
                executionAdmissionGate.didDescribeNoSubmitAdmissionFacts == false ||
                executionAdmissionGate.didDescribeNoRenderExecutionFacts == false ||
                executionAdmissionGate.didDescribeNoCommandCommitFacts == false ||
                executionAdmissionGate.didKeepExecutionAdmissionGateValueOnly == false ||
                executionAdmissionGate.didAvoidCommandBufferCommit == false ||
                executionAdmissionGate.didAvoidGpuSubmission == false ||
                executionAdmissionGate.didAvoidRenderExecution == false ||
                executionAdmissionGate.didAvoidRenderPermission == false ||
                executionAdmissionGate.didAvoidExternalObservationSurface == false ||
                executionAdmissionGate.shouldDeferRendererExecutionAdmissionGate ||
                executionAdmissionGate.shouldReportRendererExecutionAdmissionGateBlocked
            )
        ) ||
        (executionAdmissionGate.didPreserveRendererPlatformLifecycleGate &&
            executionAdmissionGate.didPrepareRendererExecutionAdmissionGate == false) ||
        (executionAdmissionGate.shouldDeferRendererExecutionAdmissionGate &&
            executionAdmissionGate.shouldReportRendererExecutionAdmissionGateBlocked)

    // state visibility gate 只记录 visibility facts；这里不 mutate renderer state。
    if (
        executionAdmissionGate.shouldReportRendererExecutionAdmissionGateBlocked ||
        stateGateInconsistent
    ) {
        return CjguiInternalRendererStateVisibilityGate(
            executionAdmissionGate,
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

    if (gateReady) {
        return CjguiInternalRendererStateVisibilityGate(
            executionAdmissionGate,
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

    if (stateGateDeferred) {
        return CjguiInternalRendererStateVisibilityGate(
            executionAdmissionGate,
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

    return CjguiInternalRendererStateVisibilityGate(
        executionAdmissionGate,
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

func cjguiInternalBuildRendererNoBackendReadyReadiness(
    stateVisibilityGate: CjguiInternalRendererStateVisibilityGate
): CjguiInternalRendererNoBackendReadyReadiness {
    let gateReady =
        stateVisibilityGate.didPrepareRendererStateVisibilityGate &&
        stateVisibilityGate.didPreserveRendererExecutionAdmissionGate &&
        stateVisibilityGate.didDefineFutureStateVisibilityGate &&
        stateVisibilityGate.didDescribeNoStateWriteFacts &&
        stateVisibilityGate.didDescribeCommitVisibilityFacts &&
        stateVisibilityGate.didDescribeRollbackNoDrawFacts &&
        stateVisibilityGate.didKeepStateVisibilityGateValueOnly &&
        stateVisibilityGate.didAvoidRendererStateMutation &&
        stateVisibilityGate.didAvoidGlobalMutableState &&
        stateVisibilityGate.didAvoidModuleLevelMutableState &&
        stateVisibilityGate.didAvoidFrameCompletionRecording &&
        stateVisibilityGate.didAvoidExternalApiSurface &&
        stateVisibilityGate.shouldDeferRendererStateVisibilityGate == false &&
        stateVisibilityGate.shouldReportRendererStateVisibilityGateBlocked == false
    let readinessDeferred =
        stateVisibilityGate.didPrepareRendererStateVisibilityGate == false &&
        stateVisibilityGate.shouldDeferRendererStateVisibilityGate &&
        stateVisibilityGate.shouldReportRendererStateVisibilityGateBlocked == false
    let readinessInconsistent = (
        stateVisibilityGate.didPrepareRendererStateVisibilityGate &&
            (
                stateVisibilityGate.didPreserveRendererExecutionAdmissionGate == false ||
                stateVisibilityGate.didDefineFutureStateVisibilityGate == false ||
                stateVisibilityGate.didDescribeNoStateWriteFacts == false ||
                stateVisibilityGate.didDescribeCommitVisibilityFacts == false ||
                stateVisibilityGate.didDescribeRollbackNoDrawFacts == false ||
                stateVisibilityGate.didKeepStateVisibilityGateValueOnly == false ||
                stateVisibilityGate.didAvoidRendererStateMutation == false ||
                stateVisibilityGate.didAvoidGlobalMutableState == false ||
                stateVisibilityGate.didAvoidModuleLevelMutableState == false ||
                stateVisibilityGate.didAvoidFrameCompletionRecording == false ||
                stateVisibilityGate.didAvoidExternalApiSurface == false ||
                stateVisibilityGate.shouldDeferRendererStateVisibilityGate ||
                stateVisibilityGate.shouldReportRendererStateVisibilityGateBlocked
            )
        ) ||
        (stateVisibilityGate.didPreserveRendererExecutionAdmissionGate &&
            stateVisibilityGate.didPrepareRendererStateVisibilityGate == false) ||
        (stateVisibilityGate.shouldDeferRendererStateVisibilityGate &&
            stateVisibilityGate.shouldReportRendererStateVisibilityGateBlocked)

    // endpoint 只封 no-backend-ready facts；这里不 create receipt or record。
    if (
        stateVisibilityGate.shouldReportRendererStateVisibilityGateBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoBackendReadyReadiness(
            stateVisibilityGate,
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

    if (gateReady) {
        return CjguiInternalRendererNoBackendReadyReadiness(
            stateVisibilityGate,
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
        return CjguiInternalRendererNoBackendReadyReadiness(
            stateVisibilityGate,
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

    return CjguiInternalRendererNoBackendReadyReadiness(
        stateVisibilityGate,
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

func cjguiInternalExecuteDefaultRendererBackendReadinessDraft(
): CjguiInternalRendererNoBackendReadyReadiness {
    let noStateWriteReadiness =
        cjguiInternalExecuteDefaultRendererStateWriteNoWriteDraft()
    let readinessIntent =
        cjguiInternalBuildRendererBackendReadinessIntent(noStateWriteReadiness)
    let platformGate =
        cjguiInternalBuildRendererPlatformLifecycleGate(readinessIntent)
    let executionGate =
        cjguiInternalBuildRendererExecutionAdmissionGate(platformGate)
    let stateGate =
        cjguiInternalBuildRendererStateVisibilityGate(executionGate)
    return cjguiInternalBuildRendererNoBackendReadyReadiness(stateGate)
}
