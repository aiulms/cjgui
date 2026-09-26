package cjgui

// Owner: Renderer no-draw backend shell value boundary.
// Truth: 只消费 CjguiInternalRendererNoMetalDeviceLayerReadiness，表达
// future no-draw backend shell intent、shell lifecycle policy、no-draw
// execution gate、shell teardown policy 与 no-backend-shell readiness facts。
// Stop-line: 这里不创建 shell object、backend object、platform resource、
// resource token、pointer-like resource、device、layer、queue、drawable、
// buffer、pass、encoder 或 pipeline，不调用 foreign platform API，不提交
// work，不触发 render side effect，不写 renderer state，不开放 external surface。
// Same-shape Boundary Brake: 本 owner 新增 shell lifecycle / no-draw gate /
// teardown / no-backend-shell vocabulary，不把 no-metal-device-layer readiness
// 包成 receipt / record / publication。

// No-draw backend shell intent 只表达 future shell intent；它不是 shell object
// creation，也不是 backend-ready permission。
struct CjguiInternalRendererNoDrawBackendShellIntent {
    let noMetalDeviceLayerReadiness: CjguiInternalRendererNoMetalDeviceLayerReadiness
    let didPrepareRendererNoDrawBackendShellIntent: Bool
    let shouldDeferRendererNoDrawBackendShellIntent: Bool
    let shouldReportRendererNoDrawBackendShellIntentBlocked: Bool
    let didPreserveRendererNoMetalDeviceLayerReadiness: Bool
    let didDefineFutureNoDrawBackendShellIntent: Bool
    let didDescribeShellLifecycleFacts: Bool
    let didDescribeNoDrawFallbackFacts: Bool
    let didDescribeShellTeardownFacts: Bool
    let didKeepNoDrawBackendShellIntentValueOnly: Bool
    let didAvoidBackendShellObjectCreation: Bool
    let didAvoidBackendObjectCreation: Bool
    let didAvoidPlatformResourceMaterialization: Bool
    let didAvoidForeignPlatformCalls: Bool
    let didAvoidThinWrapper: Bool

    init(
        noMetalDeviceLayerReadiness: CjguiInternalRendererNoMetalDeviceLayerReadiness,
        didPrepareRendererNoDrawBackendShellIntent: Bool,
        shouldDeferRendererNoDrawBackendShellIntent: Bool,
        shouldReportRendererNoDrawBackendShellIntentBlocked: Bool,
        didPreserveRendererNoMetalDeviceLayerReadiness: Bool,
        didDefineFutureNoDrawBackendShellIntent: Bool,
        didDescribeShellLifecycleFacts: Bool,
        didDescribeNoDrawFallbackFacts: Bool,
        didDescribeShellTeardownFacts: Bool,
        didKeepNoDrawBackendShellIntentValueOnly: Bool,
        didAvoidBackendShellObjectCreation: Bool,
        didAvoidBackendObjectCreation: Bool,
        didAvoidPlatformResourceMaterialization: Bool,
        didAvoidForeignPlatformCalls: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noMetalDeviceLayerReadiness = noMetalDeviceLayerReadiness
        this.didPrepareRendererNoDrawBackendShellIntent =
            didPrepareRendererNoDrawBackendShellIntent
        this.shouldDeferRendererNoDrawBackendShellIntent =
            shouldDeferRendererNoDrawBackendShellIntent
        this.shouldReportRendererNoDrawBackendShellIntentBlocked =
            shouldReportRendererNoDrawBackendShellIntentBlocked
        this.didPreserveRendererNoMetalDeviceLayerReadiness =
            didPreserveRendererNoMetalDeviceLayerReadiness
        this.didDefineFutureNoDrawBackendShellIntent =
            didDefineFutureNoDrawBackendShellIntent
        this.didDescribeShellLifecycleFacts =
            didDescribeShellLifecycleFacts
        this.didDescribeNoDrawFallbackFacts = didDescribeNoDrawFallbackFacts
        this.didDescribeShellTeardownFacts =
            didDescribeShellTeardownFacts
        this.didKeepNoDrawBackendShellIntentValueOnly =
            didKeepNoDrawBackendShellIntentValueOnly
        this.didAvoidBackendShellObjectCreation =
            didAvoidBackendShellObjectCreation
        this.didAvoidBackendObjectCreation = didAvoidBackendObjectCreation
        this.didAvoidPlatformResourceMaterialization =
            didAvoidPlatformResourceMaterialization
        this.didAvoidForeignPlatformCalls = didAvoidForeignPlatformCalls
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

// Backend shell lifecycle policy 只表达 future init / active / degraded /
// teardown facts；它不创建 backend object，也不管理真实 lifecycle。
struct CjguiInternalRendererBackendShellLifecyclePolicy {
    let shellIntent: CjguiInternalRendererNoDrawBackendShellIntent
    let didPrepareRendererBackendShellLifecyclePolicy: Bool
    let shouldDeferRendererBackendShellLifecyclePolicy: Bool
    let shouldReportRendererBackendShellLifecyclePolicyBlocked: Bool
    let didPreserveRendererNoDrawBackendShellIntent: Bool
    let didDefineFutureBackendShellLifecyclePolicy: Bool
    let didDescribeFutureInitActiveDegradedFacts: Bool
    let didDescribeNoBackendObjectLifecycleFacts: Bool
    let didDescribeFailureNoDrawLifecycleFacts: Bool
    let didKeepBackendShellLifecyclePolicyValueOnly: Bool
    let didAvoidBackendLifecycleManagement: Bool
    let didAvoidBackendObjectCreation: Bool
    let didAvoidPlatformResourceMaterialization: Bool
    let didAvoidBackendReadyPermission: Bool

    init(
        shellIntent: CjguiInternalRendererNoDrawBackendShellIntent,
        didPrepareRendererBackendShellLifecyclePolicy: Bool,
        shouldDeferRendererBackendShellLifecyclePolicy: Bool,
        shouldReportRendererBackendShellLifecyclePolicyBlocked: Bool,
        didPreserveRendererNoDrawBackendShellIntent: Bool,
        didDefineFutureBackendShellLifecyclePolicy: Bool,
        didDescribeFutureInitActiveDegradedFacts: Bool,
        didDescribeNoBackendObjectLifecycleFacts: Bool,
        didDescribeFailureNoDrawLifecycleFacts: Bool,
        didKeepBackendShellLifecyclePolicyValueOnly: Bool,
        didAvoidBackendLifecycleManagement: Bool,
        didAvoidBackendObjectCreation: Bool,
        didAvoidPlatformResourceMaterialization: Bool,
        didAvoidBackendReadyPermission: Bool
    ) {
        this.shellIntent = shellIntent
        this.didPrepareRendererBackendShellLifecyclePolicy =
            didPrepareRendererBackendShellLifecyclePolicy
        this.shouldDeferRendererBackendShellLifecyclePolicy =
            shouldDeferRendererBackendShellLifecyclePolicy
        this.shouldReportRendererBackendShellLifecyclePolicyBlocked =
            shouldReportRendererBackendShellLifecyclePolicyBlocked
        this.didPreserveRendererNoDrawBackendShellIntent =
            didPreserveRendererNoDrawBackendShellIntent
        this.didDefineFutureBackendShellLifecyclePolicy =
            didDefineFutureBackendShellLifecyclePolicy
        this.didDescribeFutureInitActiveDegradedFacts =
            didDescribeFutureInitActiveDegradedFacts
        this.didDescribeNoBackendObjectLifecycleFacts =
            didDescribeNoBackendObjectLifecycleFacts
        this.didDescribeFailureNoDrawLifecycleFacts =
            didDescribeFailureNoDrawLifecycleFacts
        this.didKeepBackendShellLifecyclePolicyValueOnly =
            didKeepBackendShellLifecyclePolicyValueOnly
        this.didAvoidBackendLifecycleManagement =
            didAvoidBackendLifecycleManagement
        this.didAvoidBackendObjectCreation = didAvoidBackendObjectCreation
        this.didAvoidPlatformResourceMaterialization =
            didAvoidPlatformResourceMaterialization
        this.didAvoidBackendReadyPermission =
            didAvoidBackendReadyPermission
    }
}

// No-draw execution gate 只表达 no-draw / no-submit / no-render admission
// facts；它不提交 work，不 present drawable，也不执行 render。
struct CjguiInternalRendererNoDrawExecutionGate {
    let lifecyclePolicy: CjguiInternalRendererBackendShellLifecyclePolicy
    let didPrepareRendererNoDrawExecutionGate: Bool
    let shouldDeferRendererNoDrawExecutionGate: Bool
    let shouldReportRendererNoDrawExecutionGateBlocked: Bool
    let didPreserveRendererBackendShellLifecyclePolicy: Bool
    let didDefineFutureNoDrawExecutionGate: Bool
    let didDescribeNoDrawAdmissionFacts: Bool
    let didDescribeNoSubmitFacts: Bool
    let didDescribeNoRenderFacts: Bool
    let didKeepNoDrawExecutionGateValueOnly: Bool
    let didAvoidCommandBufferCommit: Bool
    let didAvoidDrawablePresent: Bool
    let didAvoidGpuSubmission: Bool
    let didAvoidRenderExecution: Bool
    let didAvoidRenderPermission: Bool

    init(
        lifecyclePolicy: CjguiInternalRendererBackendShellLifecyclePolicy,
        didPrepareRendererNoDrawExecutionGate: Bool,
        shouldDeferRendererNoDrawExecutionGate: Bool,
        shouldReportRendererNoDrawExecutionGateBlocked: Bool,
        didPreserveRendererBackendShellLifecyclePolicy: Bool,
        didDefineFutureNoDrawExecutionGate: Bool,
        didDescribeNoDrawAdmissionFacts: Bool,
        didDescribeNoSubmitFacts: Bool,
        didDescribeNoRenderFacts: Bool,
        didKeepNoDrawExecutionGateValueOnly: Bool,
        didAvoidCommandBufferCommit: Bool,
        didAvoidDrawablePresent: Bool,
        didAvoidGpuSubmission: Bool,
        didAvoidRenderExecution: Bool,
        didAvoidRenderPermission: Bool
    ) {
        this.lifecyclePolicy = lifecyclePolicy
        this.didPrepareRendererNoDrawExecutionGate =
            didPrepareRendererNoDrawExecutionGate
        this.shouldDeferRendererNoDrawExecutionGate =
            shouldDeferRendererNoDrawExecutionGate
        this.shouldReportRendererNoDrawExecutionGateBlocked =
            shouldReportRendererNoDrawExecutionGateBlocked
        this.didPreserveRendererBackendShellLifecyclePolicy =
            didPreserveRendererBackendShellLifecyclePolicy
        this.didDefineFutureNoDrawExecutionGate =
            didDefineFutureNoDrawExecutionGate
        this.didDescribeNoDrawAdmissionFacts =
            didDescribeNoDrawAdmissionFacts
        this.didDescribeNoSubmitFacts = didDescribeNoSubmitFacts
        this.didDescribeNoRenderFacts = didDescribeNoRenderFacts
        this.didKeepNoDrawExecutionGateValueOnly =
            didKeepNoDrawExecutionGateValueOnly
        this.didAvoidCommandBufferCommit = didAvoidCommandBufferCommit
        this.didAvoidDrawablePresent = didAvoidDrawablePresent
        this.didAvoidGpuSubmission = didAvoidGpuSubmission
        this.didAvoidRenderExecution = didAvoidRenderExecution
        this.didAvoidRenderPermission = didAvoidRenderPermission
    }
}

// Shell teardown policy 只表达 future teardown ordering / rollback /
// idempotent cleanup facts；它不调用 foreign teardown，也不写 renderer state。
struct CjguiInternalRendererShellTeardownPolicy {
    let executionGate: CjguiInternalRendererNoDrawExecutionGate
    let didPrepareRendererShellTeardownPolicy: Bool
    let shouldDeferRendererShellTeardownPolicy: Bool
    let shouldReportRendererShellTeardownPolicyBlocked: Bool
    let didPreserveRendererNoDrawExecutionGate: Bool
    let didDefineFutureShellTeardownPolicy: Bool
    let didDescribeTeardownOrderingFacts: Bool
    let didDescribeFailureRollbackFacts: Bool
    let didDescribeIdempotentCleanupFacts: Bool
    let didKeepShellTeardownPolicyValueOnly: Bool
    let didAvoidForeignTeardownCall: Bool
    let didAvoidBridgeSmokeHarnessEntryChange: Bool
    let didAvoidRendererStateMutation: Bool
    let didAvoidDiagnosticsSurface: Bool
    let didAvoidBackendShellReadyPermission: Bool

    init(
        executionGate: CjguiInternalRendererNoDrawExecutionGate,
        didPrepareRendererShellTeardownPolicy: Bool,
        shouldDeferRendererShellTeardownPolicy: Bool,
        shouldReportRendererShellTeardownPolicyBlocked: Bool,
        didPreserveRendererNoDrawExecutionGate: Bool,
        didDefineFutureShellTeardownPolicy: Bool,
        didDescribeTeardownOrderingFacts: Bool,
        didDescribeFailureRollbackFacts: Bool,
        didDescribeIdempotentCleanupFacts: Bool,
        didKeepShellTeardownPolicyValueOnly: Bool,
        didAvoidForeignTeardownCall: Bool,
        didAvoidBridgeSmokeHarnessEntryChange: Bool,
        didAvoidRendererStateMutation: Bool,
        didAvoidDiagnosticsSurface: Bool,
        didAvoidBackendShellReadyPermission: Bool
    ) {
        this.executionGate = executionGate
        this.didPrepareRendererShellTeardownPolicy =
            didPrepareRendererShellTeardownPolicy
        this.shouldDeferRendererShellTeardownPolicy =
            shouldDeferRendererShellTeardownPolicy
        this.shouldReportRendererShellTeardownPolicyBlocked =
            shouldReportRendererShellTeardownPolicyBlocked
        this.didPreserveRendererNoDrawExecutionGate =
            didPreserveRendererNoDrawExecutionGate
        this.didDefineFutureShellTeardownPolicy =
            didDefineFutureShellTeardownPolicy
        this.didDescribeTeardownOrderingFacts =
            didDescribeTeardownOrderingFacts
        this.didDescribeFailureRollbackFacts =
            didDescribeFailureRollbackFacts
        this.didDescribeIdempotentCleanupFacts =
            didDescribeIdempotentCleanupFacts
        this.didKeepShellTeardownPolicyValueOnly =
            didKeepShellTeardownPolicyValueOnly
        this.didAvoidForeignTeardownCall = didAvoidForeignTeardownCall
        this.didAvoidBridgeSmokeHarnessEntryChange =
            didAvoidBridgeSmokeHarnessEntryChange
        this.didAvoidRendererStateMutation = didAvoidRendererStateMutation
        this.didAvoidDiagnosticsSurface = didAvoidDiagnosticsSurface
        this.didAvoidBackendShellReadyPermission =
            didAvoidBackendShellReadyPermission
    }
}

// No-backend-shell readiness 是本 owner 的 endpoint；它确认当前没有 shell
// object 或 platform resource，不代表 backend, submit, render, state, or API permission。
struct CjguiInternalRendererNoBackendShellReadiness {
    let teardownPolicy: CjguiInternalRendererShellTeardownPolicy
    let isRendererNoBackendShellReady: Bool
    let canFutureRendererNoDrawBackendShellBoundaryEvaluate: Bool
    let shouldDeferRendererNoBackendShellReadiness: Bool
    let shouldReportRendererNoBackendShellReadinessBlocked: Bool
    let didSealRendererNoBackendShellReadiness: Bool
    let didPreserveRendererShellTeardownPolicy: Bool
    let didKeepNoBackendShellReadinessValueOnly: Bool
    let didConfirmNoBackendShellObjectCreated: Bool
    let didConfirmNoBackendObjectCreated: Bool
    let didConfirmNoPlatformObjectCreated: Bool
    let didConfirmNoResourceToken: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didConfirmNoDeviceOrLayer: Bool
    let didConfirmNoCommandQueueDrawableBufferPassEncoderPipeline: Bool
    let didConfirmNoCommandBufferCommit: Bool
    let didConfirmNoDrawablePresent: Bool
    let didConfirmNoGpuSubmission: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoRendererStateMutation: Bool
    let didConfirmNoBridgeSmokeHarnessEntryChange: Bool
    let didConfirmNoExternalApiSurface: Bool
    let didAvoidBackendShellReadyPermission: Bool
    let didAvoidBackendImplementationWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        teardownPolicy: CjguiInternalRendererShellTeardownPolicy,
        isRendererNoBackendShellReady: Bool,
        canFutureRendererNoDrawBackendShellBoundaryEvaluate: Bool,
        shouldDeferRendererNoBackendShellReadiness: Bool,
        shouldReportRendererNoBackendShellReadinessBlocked: Bool,
        didSealRendererNoBackendShellReadiness: Bool,
        didPreserveRendererShellTeardownPolicy: Bool,
        didKeepNoBackendShellReadinessValueOnly: Bool,
        didConfirmNoBackendShellObjectCreated: Bool,
        didConfirmNoBackendObjectCreated: Bool,
        didConfirmNoPlatformObjectCreated: Bool,
        didConfirmNoResourceToken: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didConfirmNoDeviceOrLayer: Bool,
        didConfirmNoCommandQueueDrawableBufferPassEncoderPipeline: Bool,
        didConfirmNoCommandBufferCommit: Bool,
        didConfirmNoDrawablePresent: Bool,
        didConfirmNoGpuSubmission: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoRendererStateMutation: Bool,
        didConfirmNoBridgeSmokeHarnessEntryChange: Bool,
        didConfirmNoExternalApiSurface: Bool,
        didAvoidBackendShellReadyPermission: Bool,
        didAvoidBackendImplementationWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.teardownPolicy = teardownPolicy
        this.isRendererNoBackendShellReady = isRendererNoBackendShellReady
        this.canFutureRendererNoDrawBackendShellBoundaryEvaluate =
            canFutureRendererNoDrawBackendShellBoundaryEvaluate
        this.shouldDeferRendererNoBackendShellReadiness =
            shouldDeferRendererNoBackendShellReadiness
        this.shouldReportRendererNoBackendShellReadinessBlocked =
            shouldReportRendererNoBackendShellReadinessBlocked
        this.didSealRendererNoBackendShellReadiness =
            didSealRendererNoBackendShellReadiness
        this.didPreserveRendererShellTeardownPolicy =
            didPreserveRendererShellTeardownPolicy
        this.didKeepNoBackendShellReadinessValueOnly =
            didKeepNoBackendShellReadinessValueOnly
        this.didConfirmNoBackendShellObjectCreated =
            didConfirmNoBackendShellObjectCreated
        this.didConfirmNoBackendObjectCreated =
            didConfirmNoBackendObjectCreated
        this.didConfirmNoPlatformObjectCreated =
            didConfirmNoPlatformObjectCreated
        this.didConfirmNoResourceToken = didConfirmNoResourceToken
        this.didConfirmNoPointerLikeResource = didConfirmNoPointerLikeResource
        this.didConfirmNoDeviceOrLayer = didConfirmNoDeviceOrLayer
        this.didConfirmNoCommandQueueDrawableBufferPassEncoderPipeline =
            didConfirmNoCommandQueueDrawableBufferPassEncoderPipeline
        this.didConfirmNoCommandBufferCommit =
            didConfirmNoCommandBufferCommit
        this.didConfirmNoDrawablePresent = didConfirmNoDrawablePresent
        this.didConfirmNoGpuSubmission = didConfirmNoGpuSubmission
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoRendererStateMutation =
            didConfirmNoRendererStateMutation
        this.didConfirmNoBridgeSmokeHarnessEntryChange =
            didConfirmNoBridgeSmokeHarnessEntryChange
        this.didConfirmNoExternalApiSurface = didConfirmNoExternalApiSurface
        this.didAvoidBackendShellReadyPermission =
            didAvoidBackendShellReadyPermission
        this.didAvoidBackendImplementationWrapper =
            didAvoidBackendImplementationWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererNoDrawBackendShellIntent(
    noMetalDeviceLayerReadiness: CjguiInternalRendererNoMetalDeviceLayerReadiness
): CjguiInternalRendererNoDrawBackendShellIntent {
    let noMetalDeviceLayer =
        noMetalDeviceLayerReadiness.isRendererNoMetalDeviceLayerReady &&
        noMetalDeviceLayerReadiness.canFutureRendererMetalDeviceLayerBoundaryEvaluate &&
        noMetalDeviceLayerReadiness.didSealRendererNoMetalDeviceLayerReadiness &&
        noMetalDeviceLayerReadiness.didPreserveRendererMetalScaleColorSpacePolicy &&
        noMetalDeviceLayerReadiness.didKeepNoMetalDeviceLayerReadinessValueOnly &&
        noMetalDeviceLayerReadiness.didConfirmNoDeviceCreated &&
        noMetalDeviceLayerReadiness.didConfirmNoLayerCreated &&
        noMetalDeviceLayerReadiness.didConfirmNoPlatformResourceMaterialized &&
        noMetalDeviceLayerReadiness.didConfirmNoForeignResourceToken &&
        noMetalDeviceLayerReadiness.didConfirmNoPointerLikeResource &&
        noMetalDeviceLayerReadiness.didConfirmNoCommandQueueDrawableBufferPassEncoderPipeline &&
        noMetalDeviceLayerReadiness.didConfirmNoCommandBufferCommit &&
        noMetalDeviceLayerReadiness.didConfirmNoGpuSubmission &&
        noMetalDeviceLayerReadiness.didConfirmNoRenderExecution &&
        noMetalDeviceLayerReadiness.didConfirmNoRendererStateMutation &&
        noMetalDeviceLayerReadiness.didConfirmNoBridgeSmokeHarnessEntryChange &&
        noMetalDeviceLayerReadiness.didConfirmNoExternalApiSurface &&
        noMetalDeviceLayerReadiness.didAvoidDevicePermission &&
        noMetalDeviceLayerReadiness.didAvoidLayerPermission &&
        noMetalDeviceLayerReadiness.didAvoidForeignResourceReadinessWrapper &&
        noMetalDeviceLayerReadiness.didAvoidBackendImplementationWrapper &&
        noMetalDeviceLayerReadiness.didAvoidGpuSubmissionWrapper &&
        noMetalDeviceLayerReadiness.didAvoidReceiptRecordPublication &&
        noMetalDeviceLayerReadiness.didAvoidThinWrapper &&
        noMetalDeviceLayerReadiness.didStayFullRebuildOnly &&
        noMetalDeviceLayerReadiness.shouldDeferRendererNoMetalDeviceLayerReadiness == false &&
        noMetalDeviceLayerReadiness.shouldReportRendererNoMetalDeviceLayerReadinessBlocked == false
    let intentDeferred =
        noMetalDeviceLayerReadiness.isRendererNoMetalDeviceLayerReady == false &&
        noMetalDeviceLayerReadiness.canFutureRendererMetalDeviceLayerBoundaryEvaluate == false &&
        noMetalDeviceLayerReadiness.shouldDeferRendererNoMetalDeviceLayerReadiness &&
        noMetalDeviceLayerReadiness.shouldReportRendererNoMetalDeviceLayerReadinessBlocked == false
    let intentInconsistent = (
        noMetalDeviceLayerReadiness.isRendererNoMetalDeviceLayerReady &&
            (
                noMetalDeviceLayerReadiness.canFutureRendererMetalDeviceLayerBoundaryEvaluate == false ||
                noMetalDeviceLayerReadiness.didSealRendererNoMetalDeviceLayerReadiness == false ||
                noMetalDeviceLayerReadiness.didPreserveRendererMetalScaleColorSpacePolicy == false ||
                noMetalDeviceLayerReadiness.didKeepNoMetalDeviceLayerReadinessValueOnly == false ||
                noMetalDeviceLayerReadiness.didConfirmNoDeviceCreated == false ||
                noMetalDeviceLayerReadiness.didConfirmNoLayerCreated == false ||
                noMetalDeviceLayerReadiness.didConfirmNoPlatformResourceMaterialized == false ||
                noMetalDeviceLayerReadiness.didConfirmNoForeignResourceToken == false ||
                noMetalDeviceLayerReadiness.didConfirmNoPointerLikeResource == false ||
                noMetalDeviceLayerReadiness.didConfirmNoCommandQueueDrawableBufferPassEncoderPipeline == false ||
                noMetalDeviceLayerReadiness.didConfirmNoCommandBufferCommit == false ||
                noMetalDeviceLayerReadiness.didConfirmNoGpuSubmission == false ||
                noMetalDeviceLayerReadiness.didConfirmNoRenderExecution == false ||
                noMetalDeviceLayerReadiness.didConfirmNoRendererStateMutation == false ||
                noMetalDeviceLayerReadiness.didConfirmNoBridgeSmokeHarnessEntryChange == false ||
                noMetalDeviceLayerReadiness.didConfirmNoExternalApiSurface == false ||
                noMetalDeviceLayerReadiness.didAvoidDevicePermission == false ||
                noMetalDeviceLayerReadiness.didAvoidLayerPermission == false ||
                noMetalDeviceLayerReadiness.didAvoidForeignResourceReadinessWrapper == false ||
                noMetalDeviceLayerReadiness.didAvoidBackendImplementationWrapper == false ||
                noMetalDeviceLayerReadiness.didAvoidGpuSubmissionWrapper == false ||
                noMetalDeviceLayerReadiness.didAvoidReceiptRecordPublication == false ||
                noMetalDeviceLayerReadiness.didAvoidThinWrapper == false ||
                noMetalDeviceLayerReadiness.didStayFullRebuildOnly == false ||
                noMetalDeviceLayerReadiness.shouldDeferRendererNoMetalDeviceLayerReadiness ||
                noMetalDeviceLayerReadiness.shouldReportRendererNoMetalDeviceLayerReadinessBlocked
            )
        ) ||
        (noMetalDeviceLayerReadiness.canFutureRendererMetalDeviceLayerBoundaryEvaluate &&
            noMetalDeviceLayerReadiness.isRendererNoMetalDeviceLayerReady == false) ||
        (noMetalDeviceLayerReadiness.shouldDeferRendererNoMetalDeviceLayerReadiness &&
            noMetalDeviceLayerReadiness.shouldReportRendererNoMetalDeviceLayerReadinessBlocked)

    // fail-closed：不能把 no-metal-device-layer endpoint 薄包成 shell intent。
    if (
        noMetalDeviceLayerReadiness.shouldReportRendererNoMetalDeviceLayerReadinessBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererNoDrawBackendShellIntent(
            noMetalDeviceLayerReadiness,
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

    if (noMetalDeviceLayer) {
        return CjguiInternalRendererNoDrawBackendShellIntent(
            noMetalDeviceLayerReadiness,
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
        return CjguiInternalRendererNoDrawBackendShellIntent(
            noMetalDeviceLayerReadiness,
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

    return CjguiInternalRendererNoDrawBackendShellIntent(
        noMetalDeviceLayerReadiness,
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

func cjguiInternalBuildRendererBackendShellLifecyclePolicy(
    shellIntent: CjguiInternalRendererNoDrawBackendShellIntent
): CjguiInternalRendererBackendShellLifecyclePolicy {
    let intentReady =
        shellIntent.didPrepareRendererNoDrawBackendShellIntent &&
        shellIntent.didPreserveRendererNoMetalDeviceLayerReadiness &&
        shellIntent.didDefineFutureNoDrawBackendShellIntent &&
        shellIntent.didDescribeShellLifecycleFacts &&
        shellIntent.didDescribeNoDrawFallbackFacts &&
        shellIntent.didDescribeShellTeardownFacts &&
        shellIntent.didKeepNoDrawBackendShellIntentValueOnly &&
        shellIntent.didAvoidBackendShellObjectCreation &&
        shellIntent.didAvoidBackendObjectCreation &&
        shellIntent.didAvoidPlatformResourceMaterialization &&
        shellIntent.didAvoidForeignPlatformCalls &&
        shellIntent.didAvoidThinWrapper &&
        shellIntent.shouldDeferRendererNoDrawBackendShellIntent == false &&
        shellIntent.shouldReportRendererNoDrawBackendShellIntentBlocked == false
    let lifecycleDeferred =
        shellIntent.didPrepareRendererNoDrawBackendShellIntent == false &&
        shellIntent.shouldDeferRendererNoDrawBackendShellIntent &&
        shellIntent.shouldReportRendererNoDrawBackendShellIntentBlocked == false
    let lifecycleInconsistent = (
        shellIntent.didPrepareRendererNoDrawBackendShellIntent &&
            (
                shellIntent.didPreserveRendererNoMetalDeviceLayerReadiness == false ||
                shellIntent.didDefineFutureNoDrawBackendShellIntent == false ||
                shellIntent.didDescribeShellLifecycleFacts == false ||
                shellIntent.didDescribeNoDrawFallbackFacts == false ||
                shellIntent.didDescribeShellTeardownFacts == false ||
                shellIntent.didKeepNoDrawBackendShellIntentValueOnly == false ||
                shellIntent.didAvoidBackendShellObjectCreation == false ||
                shellIntent.didAvoidBackendObjectCreation == false ||
                shellIntent.didAvoidPlatformResourceMaterialization == false ||
                shellIntent.didAvoidForeignPlatformCalls == false ||
                shellIntent.didAvoidThinWrapper == false ||
                shellIntent.shouldDeferRendererNoDrawBackendShellIntent ||
                shellIntent.shouldReportRendererNoDrawBackendShellIntentBlocked
            )
        ) ||
        (shellIntent.didPreserveRendererNoMetalDeviceLayerReadiness &&
            shellIntent.didPrepareRendererNoDrawBackendShellIntent == false) ||
        (shellIntent.shouldDeferRendererNoDrawBackendShellIntent &&
            shellIntent.shouldReportRendererNoDrawBackendShellIntentBlocked)

    // lifecycle policy 只记录 shell lifecycle facts；这里不 manage lifecycle。
    if (
        shellIntent.shouldReportRendererNoDrawBackendShellIntentBlocked ||
        lifecycleInconsistent
    ) {
        return CjguiInternalRendererBackendShellLifecyclePolicy(
            shellIntent,
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
        return CjguiInternalRendererBackendShellLifecyclePolicy(
            shellIntent,
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

    if (lifecycleDeferred) {
        return CjguiInternalRendererBackendShellLifecyclePolicy(
            shellIntent,
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

    return CjguiInternalRendererBackendShellLifecyclePolicy(
        shellIntent,
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

func cjguiInternalBuildRendererNoDrawExecutionGate(
    lifecyclePolicy: CjguiInternalRendererBackendShellLifecyclePolicy
): CjguiInternalRendererNoDrawExecutionGate {
    let lifecycleReady =
        lifecyclePolicy.didPrepareRendererBackendShellLifecyclePolicy &&
        lifecyclePolicy.didPreserveRendererNoDrawBackendShellIntent &&
        lifecyclePolicy.didDefineFutureBackendShellLifecyclePolicy &&
        lifecyclePolicy.didDescribeFutureInitActiveDegradedFacts &&
        lifecyclePolicy.didDescribeNoBackendObjectLifecycleFacts &&
        lifecyclePolicy.didDescribeFailureNoDrawLifecycleFacts &&
        lifecyclePolicy.didKeepBackendShellLifecyclePolicyValueOnly &&
        lifecyclePolicy.didAvoidBackendLifecycleManagement &&
        lifecyclePolicy.didAvoidBackendObjectCreation &&
        lifecyclePolicy.didAvoidPlatformResourceMaterialization &&
        lifecyclePolicy.didAvoidBackendReadyPermission &&
        lifecyclePolicy.shouldDeferRendererBackendShellLifecyclePolicy == false &&
        lifecyclePolicy.shouldReportRendererBackendShellLifecyclePolicyBlocked == false
    let gateDeferred =
        lifecyclePolicy.didPrepareRendererBackendShellLifecyclePolicy == false &&
        lifecyclePolicy.shouldDeferRendererBackendShellLifecyclePolicy &&
        lifecyclePolicy.shouldReportRendererBackendShellLifecyclePolicyBlocked == false
    let gateInconsistent = (
        lifecyclePolicy.didPrepareRendererBackendShellLifecyclePolicy &&
            (
                lifecyclePolicy.didPreserveRendererNoDrawBackendShellIntent == false ||
                lifecyclePolicy.didDefineFutureBackendShellLifecyclePolicy == false ||
                lifecyclePolicy.didDescribeFutureInitActiveDegradedFacts == false ||
                lifecyclePolicy.didDescribeNoBackendObjectLifecycleFacts == false ||
                lifecyclePolicy.didDescribeFailureNoDrawLifecycleFacts == false ||
                lifecyclePolicy.didKeepBackendShellLifecyclePolicyValueOnly == false ||
                lifecyclePolicy.didAvoidBackendLifecycleManagement == false ||
                lifecyclePolicy.didAvoidBackendObjectCreation == false ||
                lifecyclePolicy.didAvoidPlatformResourceMaterialization == false ||
                lifecyclePolicy.didAvoidBackendReadyPermission == false ||
                lifecyclePolicy.shouldDeferRendererBackendShellLifecyclePolicy ||
                lifecyclePolicy.shouldReportRendererBackendShellLifecyclePolicyBlocked
            )
        ) ||
        (lifecyclePolicy.didPreserveRendererNoDrawBackendShellIntent &&
            lifecyclePolicy.didPrepareRendererBackendShellLifecyclePolicy == false) ||
        (lifecyclePolicy.shouldDeferRendererBackendShellLifecyclePolicy &&
            lifecyclePolicy.shouldReportRendererBackendShellLifecyclePolicyBlocked)

    // no-draw execution gate 只记录 no-submit / no-render facts。
    if (
        lifecyclePolicy.shouldReportRendererBackendShellLifecyclePolicyBlocked ||
        gateInconsistent
    ) {
        return CjguiInternalRendererNoDrawExecutionGate(
            lifecyclePolicy,
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

    if (lifecycleReady) {
        return CjguiInternalRendererNoDrawExecutionGate(
            lifecyclePolicy,
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
        return CjguiInternalRendererNoDrawExecutionGate(
            lifecyclePolicy,
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

    return CjguiInternalRendererNoDrawExecutionGate(
        lifecyclePolicy,
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

func cjguiInternalBuildRendererShellTeardownPolicy(
    executionGate: CjguiInternalRendererNoDrawExecutionGate
): CjguiInternalRendererShellTeardownPolicy {
    let gateReady =
        executionGate.didPrepareRendererNoDrawExecutionGate &&
        executionGate.didPreserveRendererBackendShellLifecyclePolicy &&
        executionGate.didDefineFutureNoDrawExecutionGate &&
        executionGate.didDescribeNoDrawAdmissionFacts &&
        executionGate.didDescribeNoSubmitFacts &&
        executionGate.didDescribeNoRenderFacts &&
        executionGate.didKeepNoDrawExecutionGateValueOnly &&
        executionGate.didAvoidCommandBufferCommit &&
        executionGate.didAvoidDrawablePresent &&
        executionGate.didAvoidGpuSubmission &&
        executionGate.didAvoidRenderExecution &&
        executionGate.didAvoidRenderPermission &&
        executionGate.shouldDeferRendererNoDrawExecutionGate == false &&
        executionGate.shouldReportRendererNoDrawExecutionGateBlocked == false
    let teardownDeferred =
        executionGate.didPrepareRendererNoDrawExecutionGate == false &&
        executionGate.shouldDeferRendererNoDrawExecutionGate &&
        executionGate.shouldReportRendererNoDrawExecutionGateBlocked == false
    let teardownInconsistent = (
        executionGate.didPrepareRendererNoDrawExecutionGate &&
            (
                executionGate.didPreserveRendererBackendShellLifecyclePolicy == false ||
                executionGate.didDefineFutureNoDrawExecutionGate == false ||
                executionGate.didDescribeNoDrawAdmissionFacts == false ||
                executionGate.didDescribeNoSubmitFacts == false ||
                executionGate.didDescribeNoRenderFacts == false ||
                executionGate.didKeepNoDrawExecutionGateValueOnly == false ||
                executionGate.didAvoidCommandBufferCommit == false ||
                executionGate.didAvoidDrawablePresent == false ||
                executionGate.didAvoidGpuSubmission == false ||
                executionGate.didAvoidRenderExecution == false ||
                executionGate.didAvoidRenderPermission == false ||
                executionGate.shouldDeferRendererNoDrawExecutionGate ||
                executionGate.shouldReportRendererNoDrawExecutionGateBlocked
            )
        ) ||
        (executionGate.didPreserveRendererBackendShellLifecyclePolicy &&
            executionGate.didPrepareRendererNoDrawExecutionGate == false) ||
        (executionGate.shouldDeferRendererNoDrawExecutionGate &&
            executionGate.shouldReportRendererNoDrawExecutionGateBlocked)

    // teardown policy 只记录 ordering / rollback facts；这里不 call teardown.
    if (
        executionGate.shouldReportRendererNoDrawExecutionGateBlocked ||
        teardownInconsistent
    ) {
        return CjguiInternalRendererShellTeardownPolicy(
            executionGate,
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
        return CjguiInternalRendererShellTeardownPolicy(
            executionGate,
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

    if (teardownDeferred) {
        return CjguiInternalRendererShellTeardownPolicy(
            executionGate,
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

    return CjguiInternalRendererShellTeardownPolicy(
        executionGate,
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

func cjguiInternalBuildRendererNoBackendShellReadiness(
    teardownPolicy: CjguiInternalRendererShellTeardownPolicy
): CjguiInternalRendererNoBackendShellReadiness {
    let teardownReady =
        teardownPolicy.didPrepareRendererShellTeardownPolicy &&
        teardownPolicy.didPreserveRendererNoDrawExecutionGate &&
        teardownPolicy.didDefineFutureShellTeardownPolicy &&
        teardownPolicy.didDescribeTeardownOrderingFacts &&
        teardownPolicy.didDescribeFailureRollbackFacts &&
        teardownPolicy.didDescribeIdempotentCleanupFacts &&
        teardownPolicy.didKeepShellTeardownPolicyValueOnly &&
        teardownPolicy.didAvoidForeignTeardownCall &&
        teardownPolicy.didAvoidBridgeSmokeHarnessEntryChange &&
        teardownPolicy.didAvoidRendererStateMutation &&
        teardownPolicy.didAvoidDiagnosticsSurface &&
        teardownPolicy.didAvoidBackendShellReadyPermission &&
        teardownPolicy.shouldDeferRendererShellTeardownPolicy == false &&
        teardownPolicy.shouldReportRendererShellTeardownPolicyBlocked == false
    let readinessDeferred =
        teardownPolicy.didPrepareRendererShellTeardownPolicy == false &&
        teardownPolicy.shouldDeferRendererShellTeardownPolicy &&
        teardownPolicy.shouldReportRendererShellTeardownPolicyBlocked == false
    let readinessInconsistent = (
        teardownPolicy.didPrepareRendererShellTeardownPolicy &&
            (
                teardownPolicy.didPreserveRendererNoDrawExecutionGate == false ||
                teardownPolicy.didDefineFutureShellTeardownPolicy == false ||
                teardownPolicy.didDescribeTeardownOrderingFacts == false ||
                teardownPolicy.didDescribeFailureRollbackFacts == false ||
                teardownPolicy.didDescribeIdempotentCleanupFacts == false ||
                teardownPolicy.didKeepShellTeardownPolicyValueOnly == false ||
                teardownPolicy.didAvoidForeignTeardownCall == false ||
                teardownPolicy.didAvoidBridgeSmokeHarnessEntryChange == false ||
                teardownPolicy.didAvoidRendererStateMutation == false ||
                teardownPolicy.didAvoidDiagnosticsSurface == false ||
                teardownPolicy.didAvoidBackendShellReadyPermission == false ||
                teardownPolicy.shouldDeferRendererShellTeardownPolicy ||
                teardownPolicy.shouldReportRendererShellTeardownPolicyBlocked
            )
        ) ||
        (teardownPolicy.didPreserveRendererNoDrawExecutionGate &&
            teardownPolicy.didPrepareRendererShellTeardownPolicy == false) ||
        (teardownPolicy.shouldDeferRendererShellTeardownPolicy &&
            teardownPolicy.shouldReportRendererShellTeardownPolicyBlocked)

    // endpoint 只 sealing no-backend-shell facts；这里不 create receipt / record。
    if (
        teardownPolicy.shouldReportRendererShellTeardownPolicyBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoBackendShellReadiness(
            teardownPolicy,
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

    if (teardownReady) {
        return CjguiInternalRendererNoBackendShellReadiness(
            teardownPolicy,
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

    if (readinessDeferred) {
        return CjguiInternalRendererNoBackendShellReadiness(
            teardownPolicy,
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

    return CjguiInternalRendererNoBackendShellReadiness(
        teardownPolicy,
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

func cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft(
): CjguiInternalRendererNoBackendShellReadiness {
    let noMetalDeviceLayerReadiness =
        cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()
    let shellIntent =
        cjguiInternalBuildRendererNoDrawBackendShellIntent(
            noMetalDeviceLayerReadiness
        )
    let lifecyclePolicy =
        cjguiInternalBuildRendererBackendShellLifecyclePolicy(shellIntent)
    let executionGate =
        cjguiInternalBuildRendererNoDrawExecutionGate(lifecyclePolicy)
    let teardownPolicy =
        cjguiInternalBuildRendererShellTeardownPolicy(executionGate)
    return cjguiInternalBuildRendererNoBackendShellReadiness(teardownPolicy)
}
