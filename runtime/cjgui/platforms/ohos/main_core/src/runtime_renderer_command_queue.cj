package cjgui

// Owner: Renderer command queue lifecycle value boundary.
// Truth: 只消费 CjguiInternalRendererNoPlatformResourceReadiness，表达 future command
// queue lifecycle intent、ownership policy、creation guard、lifetime policy 与
// no-command-queue readiness 的内部 value facts。
// Stop-line: 这里不创建或持有 MTLCommandQueue / MTLDevice / CAMetalLayer / drawable /
// command-buffer / pass / encoder / NativeHandle / RawPointer，不接平台实现，不触发绘制，
// 不写 renderer state。
// Same-shape Boundary Brake: 本 owner 新增 command queue ownership / creation guard /
// lifetime vocabulary，不把 no-platform-resource readiness 包成 receipt / record /
// publication。

// Command queue lifecycle intent 只表达 future lifecycle intent；
// 它不是 command queue implementation，也不是 backend readiness wrapper。
struct CjguiInternalRendererCommandQueueLifecycleIntent {
    let noPlatformResourceReadiness: CjguiInternalRendererNoPlatformResourceReadiness
    let didPrepareRendererCommandQueueLifecycleIntent: Bool
    let shouldDeferRendererCommandQueueLifecycleIntent: Bool
    let shouldReportRendererCommandQueueLifecycleIntentBlocked: Bool
    let didPreserveRendererNoPlatformResourceReadiness: Bool
    let didDefineFutureCommandQueueLifecycleIntent: Bool
    let didDescribeQueueOwnerIdentityFact: Bool
    let didDescribeFramePacingRelationship: Bool
    let didKeepCommandQueueLifecycleIntentValueOnly: Bool
    let didAvoidCommandQueueCreation: Bool
    let didAvoidBackendPermission: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        noPlatformResourceReadiness: CjguiInternalRendererNoPlatformResourceReadiness,
        didPrepareRendererCommandQueueLifecycleIntent: Bool,
        shouldDeferRendererCommandQueueLifecycleIntent: Bool,
        shouldReportRendererCommandQueueLifecycleIntentBlocked: Bool,
        didPreserveRendererNoPlatformResourceReadiness: Bool,
        didDefineFutureCommandQueueLifecycleIntent: Bool,
        didDescribeQueueOwnerIdentityFact: Bool,
        didDescribeFramePacingRelationship: Bool,
        didKeepCommandQueueLifecycleIntentValueOnly: Bool,
        didAvoidCommandQueueCreation: Bool,
        didAvoidBackendPermission: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.noPlatformResourceReadiness = noPlatformResourceReadiness
        this.didPrepareRendererCommandQueueLifecycleIntent =
            didPrepareRendererCommandQueueLifecycleIntent
        this.shouldDeferRendererCommandQueueLifecycleIntent =
            shouldDeferRendererCommandQueueLifecycleIntent
        this.shouldReportRendererCommandQueueLifecycleIntentBlocked =
            shouldReportRendererCommandQueueLifecycleIntentBlocked
        this.didPreserveRendererNoPlatformResourceReadiness =
            didPreserveRendererNoPlatformResourceReadiness
        this.didDefineFutureCommandQueueLifecycleIntent =
            didDefineFutureCommandQueueLifecycleIntent
        this.didDescribeQueueOwnerIdentityFact = didDescribeQueueOwnerIdentityFact
        this.didDescribeFramePacingRelationship = didDescribeFramePacingRelationship
        this.didKeepCommandQueueLifecycleIntentValueOnly =
            didKeepCommandQueueLifecycleIntentValueOnly
        this.didAvoidCommandQueueCreation = didAvoidCommandQueueCreation
        this.didAvoidBackendPermission = didAvoidBackendPermission
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
    }
}

// Lifecycle ownership policy 是本 owner 的 queue ownership 语义；
// 现有 CjguiInternalRendererCommandQueueOwnershipPolicy 已属于 platform resource owner。
struct CjguiInternalRendererCommandQueueLifecycleOwnershipPolicy {
    let lifecycleIntent: CjguiInternalRendererCommandQueueLifecycleIntent
    let didPrepareRendererCommandQueueLifecycleOwnershipPolicy: Bool
    let shouldDeferRendererCommandQueueLifecycleOwnershipPolicy: Bool
    let shouldReportRendererCommandQueueLifecycleOwnershipPolicyBlocked: Bool
    let didPreserveRendererCommandQueueLifecycleIntent: Bool
    let didDefineFutureCommandQueueOwnershipPolicy: Bool
    let didKeepFutureQueueInBackendPlatformOwner: Bool
    let didKeepQueueOutOfCorePacket: Bool
    let didDescribeQueueDeviceLayerDrawableRelation: Bool
    let didKeepCommandQueueLifecycleOwnershipValueOnly: Bool
    let didAvoidCommandQueueCreation: Bool
    let didAvoidBackendPermission: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool

    init(
        lifecycleIntent: CjguiInternalRendererCommandQueueLifecycleIntent,
        didPrepareRendererCommandQueueLifecycleOwnershipPolicy: Bool,
        shouldDeferRendererCommandQueueLifecycleOwnershipPolicy: Bool,
        shouldReportRendererCommandQueueLifecycleOwnershipPolicyBlocked: Bool,
        didPreserveRendererCommandQueueLifecycleIntent: Bool,
        didDefineFutureCommandQueueOwnershipPolicy: Bool,
        didKeepFutureQueueInBackendPlatformOwner: Bool,
        didKeepQueueOutOfCorePacket: Bool,
        didDescribeQueueDeviceLayerDrawableRelation: Bool,
        didKeepCommandQueueLifecycleOwnershipValueOnly: Bool,
        didAvoidCommandQueueCreation: Bool,
        didAvoidBackendPermission: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.lifecycleIntent = lifecycleIntent
        this.didPrepareRendererCommandQueueLifecycleOwnershipPolicy =
            didPrepareRendererCommandQueueLifecycleOwnershipPolicy
        this.shouldDeferRendererCommandQueueLifecycleOwnershipPolicy =
            shouldDeferRendererCommandQueueLifecycleOwnershipPolicy
        this.shouldReportRendererCommandQueueLifecycleOwnershipPolicyBlocked =
            shouldReportRendererCommandQueueLifecycleOwnershipPolicyBlocked
        this.didPreserveRendererCommandQueueLifecycleIntent =
            didPreserveRendererCommandQueueLifecycleIntent
        this.didDefineFutureCommandQueueOwnershipPolicy =
            didDefineFutureCommandQueueOwnershipPolicy
        this.didKeepFutureQueueInBackendPlatformOwner =
            didKeepFutureQueueInBackendPlatformOwner
        this.didKeepQueueOutOfCorePacket = didKeepQueueOutOfCorePacket
        this.didDescribeQueueDeviceLayerDrawableRelation =
            didDescribeQueueDeviceLayerDrawableRelation
        this.didKeepCommandQueueLifecycleOwnershipValueOnly =
            didKeepCommandQueueLifecycleOwnershipValueOnly
        this.didAvoidCommandQueueCreation = didAvoidCommandQueueCreation
        this.didAvoidBackendPermission = didAvoidBackendPermission
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// Creation guard 只表达 future creation preconditions；
// 它不创建 queue，不创建平台对象，也不创建 submission object。
struct CjguiInternalRendererCommandQueueCreationGuard {
    let lifecycleOwnershipPolicy: CjguiInternalRendererCommandQueueLifecycleOwnershipPolicy
    let didPrepareRendererCommandQueueCreationGuard: Bool
    let shouldDeferRendererCommandQueueCreationGuard: Bool
    let shouldReportRendererCommandQueueCreationGuardBlocked: Bool
    let didPreserveRendererCommandQueueLifecycleOwnershipPolicy: Bool
    let didDefineFutureQueueCreationPreconditions: Bool
    let didDescribeNoDrawFailureValueFacts: Bool
    let didDescribeShutdownRollbackGuard: Bool
    let didKeepQueueCreationGuardValueOnly: Bool
    let didAvoidCommandQueueCreation: Bool
    let didAvoidPlatformObjectCreation: Bool
    let didAvoidCommandBufferCreation: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool

    init(
        lifecycleOwnershipPolicy: CjguiInternalRendererCommandQueueLifecycleOwnershipPolicy,
        didPrepareRendererCommandQueueCreationGuard: Bool,
        shouldDeferRendererCommandQueueCreationGuard: Bool,
        shouldReportRendererCommandQueueCreationGuardBlocked: Bool,
        didPreserveRendererCommandQueueLifecycleOwnershipPolicy: Bool,
        didDefineFutureQueueCreationPreconditions: Bool,
        didDescribeNoDrawFailureValueFacts: Bool,
        didDescribeShutdownRollbackGuard: Bool,
        didKeepQueueCreationGuardValueOnly: Bool,
        didAvoidCommandQueueCreation: Bool,
        didAvoidPlatformObjectCreation: Bool,
        didAvoidCommandBufferCreation: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.lifecycleOwnershipPolicy = lifecycleOwnershipPolicy
        this.didPrepareRendererCommandQueueCreationGuard =
            didPrepareRendererCommandQueueCreationGuard
        this.shouldDeferRendererCommandQueueCreationGuard =
            shouldDeferRendererCommandQueueCreationGuard
        this.shouldReportRendererCommandQueueCreationGuardBlocked =
            shouldReportRendererCommandQueueCreationGuardBlocked
        this.didPreserveRendererCommandQueueLifecycleOwnershipPolicy =
            didPreserveRendererCommandQueueLifecycleOwnershipPolicy
        this.didDefineFutureQueueCreationPreconditions =
            didDefineFutureQueueCreationPreconditions
        this.didDescribeNoDrawFailureValueFacts = didDescribeNoDrawFailureValueFacts
        this.didDescribeShutdownRollbackGuard = didDescribeShutdownRollbackGuard
        this.didKeepQueueCreationGuardValueOnly = didKeepQueueCreationGuardValueOnly
        this.didAvoidCommandQueueCreation = didAvoidCommandQueueCreation
        this.didAvoidPlatformObjectCreation = didAvoidPlatformObjectCreation
        this.didAvoidCommandBufferCreation = didAvoidCommandBufferCreation
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// Lifetime policy 只表达 future lifetime / shutdown / rollback facts；
// 它不管理真实 queue lifetime，也不驱动 frame submission。
struct CjguiInternalRendererCommandQueueLifetimePolicy {
    let creationGuard: CjguiInternalRendererCommandQueueCreationGuard
    let didPrepareRendererCommandQueueLifetimePolicy: Bool
    let shouldDeferRendererCommandQueueLifetimePolicy: Bool
    let shouldReportRendererCommandQueueLifetimePolicyBlocked: Bool
    let didPreserveRendererCommandQueueCreationGuard: Bool
    let didDefineFutureQueueLifetimePolicy: Bool
    let didDescribeFutureShutdownPolicy: Bool
    let didDescribeFutureRollbackPolicy: Bool
    let didDescribeFramePacingRelationship: Bool
    let didKeepQueueLifetimePolicyValueOnly: Bool
    let didAvoidRealQueueLifetimeManagement: Bool
    let didAvoidCommandQueueCreation: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool

    init(
        creationGuard: CjguiInternalRendererCommandQueueCreationGuard,
        didPrepareRendererCommandQueueLifetimePolicy: Bool,
        shouldDeferRendererCommandQueueLifetimePolicy: Bool,
        shouldReportRendererCommandQueueLifetimePolicyBlocked: Bool,
        didPreserveRendererCommandQueueCreationGuard: Bool,
        didDefineFutureQueueLifetimePolicy: Bool,
        didDescribeFutureShutdownPolicy: Bool,
        didDescribeFutureRollbackPolicy: Bool,
        didDescribeFramePacingRelationship: Bool,
        didKeepQueueLifetimePolicyValueOnly: Bool,
        didAvoidRealQueueLifetimeManagement: Bool,
        didAvoidCommandQueueCreation: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.creationGuard = creationGuard
        this.didPrepareRendererCommandQueueLifetimePolicy =
            didPrepareRendererCommandQueueLifetimePolicy
        this.shouldDeferRendererCommandQueueLifetimePolicy =
            shouldDeferRendererCommandQueueLifetimePolicy
        this.shouldReportRendererCommandQueueLifetimePolicyBlocked =
            shouldReportRendererCommandQueueLifetimePolicyBlocked
        this.didPreserveRendererCommandQueueCreationGuard =
            didPreserveRendererCommandQueueCreationGuard
        this.didDefineFutureQueueLifetimePolicy = didDefineFutureQueueLifetimePolicy
        this.didDescribeFutureShutdownPolicy = didDescribeFutureShutdownPolicy
        this.didDescribeFutureRollbackPolicy = didDescribeFutureRollbackPolicy
        this.didDescribeFramePacingRelationship = didDescribeFramePacingRelationship
        this.didKeepQueueLifetimePolicyValueOnly = didKeepQueueLifetimePolicyValueOnly
        this.didAvoidRealQueueLifetimeManagement = didAvoidRealQueueLifetimeManagement
        this.didAvoidCommandQueueCreation = didAvoidCommandQueueCreation
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// No-command-queue readiness 是本 owner 的 endpoint；
// readiness 只表示 future command queue lifecycle boundary 可以继续评估，不代表 queue
// creation、backend、platform object、command-buffer 或 render permission。
struct CjguiInternalRendererNoCommandQueueReadiness {
    let lifetimePolicy: CjguiInternalRendererCommandQueueLifetimePolicy
    let isRendererNoCommandQueueReady: Bool
    let canFutureRendererCommandQueueBoundaryEvaluate: Bool
    let shouldDeferRendererNoCommandQueueReadiness: Bool
    let shouldReportRendererNoCommandQueueReadinessBlocked: Bool
    let didRecordRendererNoCommandQueueReadiness: Bool
    let didPreserveRendererCommandQueueLifetimePolicy: Bool
    let didKeepNoCommandQueueReadinessValueOnly: Bool
    let didConfirmNoCommandQueueCreated: Bool
    let didConfirmNoDeviceLayerOrDrawableObject: Bool
    let didConfirmNoCommandBufferPassOrEncoderObject: Bool
    let didConfirmNoNativeResourceToken: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didAvoidBackendPermission: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didStayFullRebuildOnly: Bool

    init(
        lifetimePolicy: CjguiInternalRendererCommandQueueLifetimePolicy,
        isRendererNoCommandQueueReady: Bool,
        canFutureRendererCommandQueueBoundaryEvaluate: Bool,
        shouldDeferRendererNoCommandQueueReadiness: Bool,
        shouldReportRendererNoCommandQueueReadinessBlocked: Bool,
        didRecordRendererNoCommandQueueReadiness: Bool,
        didPreserveRendererCommandQueueLifetimePolicy: Bool,
        didKeepNoCommandQueueReadinessValueOnly: Bool,
        didConfirmNoCommandQueueCreated: Bool,
        didConfirmNoDeviceLayerOrDrawableObject: Bool,
        didConfirmNoCommandBufferPassOrEncoderObject: Bool,
        didConfirmNoNativeResourceToken: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didAvoidBackendPermission: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.lifetimePolicy = lifetimePolicy
        this.isRendererNoCommandQueueReady = isRendererNoCommandQueueReady
        this.canFutureRendererCommandQueueBoundaryEvaluate =
            canFutureRendererCommandQueueBoundaryEvaluate
        this.shouldDeferRendererNoCommandQueueReadiness =
            shouldDeferRendererNoCommandQueueReadiness
        this.shouldReportRendererNoCommandQueueReadinessBlocked =
            shouldReportRendererNoCommandQueueReadinessBlocked
        this.didRecordRendererNoCommandQueueReadiness = didRecordRendererNoCommandQueueReadiness
        this.didPreserveRendererCommandQueueLifetimePolicy =
            didPreserveRendererCommandQueueLifetimePolicy
        this.didKeepNoCommandQueueReadinessValueOnly = didKeepNoCommandQueueReadinessValueOnly
        this.didConfirmNoCommandQueueCreated = didConfirmNoCommandQueueCreated
        this.didConfirmNoDeviceLayerOrDrawableObject = didConfirmNoDeviceLayerOrDrawableObject
        this.didConfirmNoCommandBufferPassOrEncoderObject =
            didConfirmNoCommandBufferPassOrEncoderObject
        this.didConfirmNoNativeResourceToken = didConfirmNoNativeResourceToken
        this.didConfirmNoPointerLikeResource = didConfirmNoPointerLikeResource
        this.didAvoidBackendPermission = didAvoidBackendPermission
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererCommandQueueLifecycleIntent(
    noPlatformResourceReadiness: CjguiInternalRendererNoPlatformResourceReadiness
): CjguiInternalRendererCommandQueueLifecycleIntent {
    let noPlatformReady = noPlatformResourceReadiness.isRendererNoPlatformResourceReady &&
        noPlatformResourceReadiness.canFutureRendererPlatformResourceBoundaryEvaluate &&
        noPlatformResourceReadiness.didRecordRendererNoPlatformResourceReadiness &&
        noPlatformResourceReadiness.didPreserveRendererCommandQueueOwnershipPolicy &&
        noPlatformResourceReadiness.didKeepNoPlatformResourceReadinessValueOnly &&
        noPlatformResourceReadiness.didConfirmNoPlatformResourceCreated &&
        noPlatformResourceReadiness.didConfirmNoPlatformLayerOrDeviceObject &&
        noPlatformResourceReadiness.didConfirmNoQueueDrawableOrSubmissionObject &&
        noPlatformResourceReadiness.didConfirmNoRenderPassOrEncoderObject &&
        noPlatformResourceReadiness.didConfirmNoNativeHandle &&
        noPlatformResourceReadiness.didConfirmNoRawPointer &&
        noPlatformResourceReadiness.didAvoidRendererBackendPermission &&
        noPlatformResourceReadiness.didAvoidRendererStateWrite &&
        noPlatformResourceReadiness.didAvoidRenderingPermission &&
        noPlatformResourceReadiness.didAvoidReceiptRecordPublication &&
        noPlatformResourceReadiness.didStayFullRebuildOnly &&
        noPlatformResourceReadiness.shouldDeferRendererNoPlatformResourceReadiness == false &&
        noPlatformResourceReadiness.shouldReportRendererNoPlatformResourceReadinessBlocked == false
    let intentDeferred = noPlatformResourceReadiness.isRendererNoPlatformResourceReady == false &&
        noPlatformResourceReadiness.canFutureRendererPlatformResourceBoundaryEvaluate == false &&
        noPlatformResourceReadiness.shouldDeferRendererNoPlatformResourceReadiness &&
        noPlatformResourceReadiness.shouldReportRendererNoPlatformResourceReadinessBlocked == false
    let intentInconsistent = (
        noPlatformResourceReadiness.isRendererNoPlatformResourceReady &&
            (
                noPlatformResourceReadiness.canFutureRendererPlatformResourceBoundaryEvaluate == false ||
                noPlatformResourceReadiness.didRecordRendererNoPlatformResourceReadiness == false ||
                noPlatformResourceReadiness.didPreserveRendererCommandQueueOwnershipPolicy == false ||
                noPlatformResourceReadiness.didKeepNoPlatformResourceReadinessValueOnly == false ||
                noPlatformResourceReadiness.didConfirmNoPlatformResourceCreated == false ||
                noPlatformResourceReadiness.didConfirmNoPlatformLayerOrDeviceObject == false ||
                noPlatformResourceReadiness.didConfirmNoQueueDrawableOrSubmissionObject == false ||
                noPlatformResourceReadiness.didConfirmNoRenderPassOrEncoderObject == false ||
                noPlatformResourceReadiness.didConfirmNoNativeHandle == false ||
                noPlatformResourceReadiness.didConfirmNoRawPointer == false ||
                noPlatformResourceReadiness.didAvoidRendererBackendPermission == false ||
                noPlatformResourceReadiness.didAvoidRendererStateWrite == false ||
                noPlatformResourceReadiness.didAvoidRenderingPermission == false ||
                noPlatformResourceReadiness.didAvoidReceiptRecordPublication == false ||
                noPlatformResourceReadiness.didStayFullRebuildOnly == false ||
                noPlatformResourceReadiness.shouldDeferRendererNoPlatformResourceReadiness ||
                noPlatformResourceReadiness.shouldReportRendererNoPlatformResourceReadinessBlocked
            )
        ) ||
        (noPlatformResourceReadiness.canFutureRendererPlatformResourceBoundaryEvaluate &&
            noPlatformResourceReadiness.isRendererNoPlatformResourceReady == false) ||
        (noPlatformResourceReadiness.shouldDeferRendererNoPlatformResourceReadiness &&
            noPlatformResourceReadiness.shouldReportRendererNoPlatformResourceReadinessBlocked)

    // fail-closed：不能把 no-platform-resource readiness 薄包成 queue lifecycle intent。
    if (
        noPlatformResourceReadiness.shouldReportRendererNoPlatformResourceReadinessBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererCommandQueueLifecycleIntent(
            noPlatformResourceReadiness,
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

    if (noPlatformReady) {
        return CjguiInternalRendererCommandQueueLifecycleIntent(
            noPlatformResourceReadiness,
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
        return CjguiInternalRendererCommandQueueLifecycleIntent(
            noPlatformResourceReadiness,
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

    return CjguiInternalRendererCommandQueueLifecycleIntent(
        noPlatformResourceReadiness,
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

func cjguiInternalBuildRendererCommandQueueLifecycleOwnershipPolicy(
    lifecycleIntent: CjguiInternalRendererCommandQueueLifecycleIntent
): CjguiInternalRendererCommandQueueLifecycleOwnershipPolicy {
    let intentReady = lifecycleIntent.didPrepareRendererCommandQueueLifecycleIntent &&
        lifecycleIntent.didPreserveRendererNoPlatformResourceReadiness &&
        lifecycleIntent.didDefineFutureCommandQueueLifecycleIntent &&
        lifecycleIntent.didDescribeQueueOwnerIdentityFact &&
        lifecycleIntent.didDescribeFramePacingRelationship &&
        lifecycleIntent.didKeepCommandQueueLifecycleIntentValueOnly &&
        lifecycleIntent.didAvoidCommandQueueCreation &&
        lifecycleIntent.didAvoidBackendPermission &&
        lifecycleIntent.didAvoidRendererStateWrite &&
        lifecycleIntent.didAvoidRenderingPermission &&
        lifecycleIntent.didAvoidReceiptRecordPublication &&
        lifecycleIntent.shouldDeferRendererCommandQueueLifecycleIntent == false &&
        lifecycleIntent.shouldReportRendererCommandQueueLifecycleIntentBlocked == false
    let policyDeferred = lifecycleIntent.didPrepareRendererCommandQueueLifecycleIntent == false &&
        lifecycleIntent.shouldDeferRendererCommandQueueLifecycleIntent &&
        lifecycleIntent.shouldReportRendererCommandQueueLifecycleIntentBlocked == false
    let policyInconsistent = (
        lifecycleIntent.didPrepareRendererCommandQueueLifecycleIntent &&
            (
                lifecycleIntent.didPreserveRendererNoPlatformResourceReadiness == false ||
                lifecycleIntent.didDefineFutureCommandQueueLifecycleIntent == false ||
                lifecycleIntent.didDescribeQueueOwnerIdentityFact == false ||
                lifecycleIntent.didDescribeFramePacingRelationship == false ||
                lifecycleIntent.didKeepCommandQueueLifecycleIntentValueOnly == false ||
                lifecycleIntent.didAvoidCommandQueueCreation == false ||
                lifecycleIntent.didAvoidBackendPermission == false ||
                lifecycleIntent.didAvoidRendererStateWrite == false ||
                lifecycleIntent.didAvoidRenderingPermission == false ||
                lifecycleIntent.didAvoidReceiptRecordPublication == false ||
                lifecycleIntent.shouldDeferRendererCommandQueueLifecycleIntent ||
                lifecycleIntent.shouldReportRendererCommandQueueLifecycleIntentBlocked
            )
        ) ||
        (lifecycleIntent.didPreserveRendererNoPlatformResourceReadiness &&
            lifecycleIntent.didPrepareRendererCommandQueueLifecycleIntent == false) ||
        (lifecycleIntent.shouldDeferRendererCommandQueueLifecycleIntent &&
            lifecycleIntent.shouldReportRendererCommandQueueLifecycleIntentBlocked)

    // ownership policy 不一致时必须 fail-closed，不能让 queue 进入 core packet。
    if (
        lifecycleIntent.shouldReportRendererCommandQueueLifecycleIntentBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererCommandQueueLifecycleOwnershipPolicy(
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
        return CjguiInternalRendererCommandQueueLifecycleOwnershipPolicy(
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
        return CjguiInternalRendererCommandQueueLifecycleOwnershipPolicy(
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

    return CjguiInternalRendererCommandQueueLifecycleOwnershipPolicy(
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

func cjguiInternalBuildRendererCommandQueueCreationGuard(
    lifecycleOwnershipPolicy: CjguiInternalRendererCommandQueueLifecycleOwnershipPolicy
): CjguiInternalRendererCommandQueueCreationGuard {
    let ownershipReady =
        lifecycleOwnershipPolicy.didPrepareRendererCommandQueueLifecycleOwnershipPolicy &&
        lifecycleOwnershipPolicy.didPreserveRendererCommandQueueLifecycleIntent &&
        lifecycleOwnershipPolicy.didDefineFutureCommandQueueOwnershipPolicy &&
        lifecycleOwnershipPolicy.didKeepFutureQueueInBackendPlatformOwner &&
        lifecycleOwnershipPolicy.didKeepQueueOutOfCorePacket &&
        lifecycleOwnershipPolicy.didDescribeQueueDeviceLayerDrawableRelation &&
        lifecycleOwnershipPolicy.didKeepCommandQueueLifecycleOwnershipValueOnly &&
        lifecycleOwnershipPolicy.didAvoidCommandQueueCreation &&
        lifecycleOwnershipPolicy.didAvoidBackendPermission &&
        lifecycleOwnershipPolicy.didAvoidRendererStateWrite &&
        lifecycleOwnershipPolicy.didAvoidRenderingPermission &&
        lifecycleOwnershipPolicy.shouldDeferRendererCommandQueueLifecycleOwnershipPolicy == false &&
        lifecycleOwnershipPolicy.shouldReportRendererCommandQueueLifecycleOwnershipPolicyBlocked == false
    let guardDeferred =
        lifecycleOwnershipPolicy.didPrepareRendererCommandQueueLifecycleOwnershipPolicy == false &&
        lifecycleOwnershipPolicy.shouldDeferRendererCommandQueueLifecycleOwnershipPolicy &&
        lifecycleOwnershipPolicy.shouldReportRendererCommandQueueLifecycleOwnershipPolicyBlocked == false
    let guardInconsistent = (
        lifecycleOwnershipPolicy.didPrepareRendererCommandQueueLifecycleOwnershipPolicy &&
            (
                lifecycleOwnershipPolicy.didPreserveRendererCommandQueueLifecycleIntent == false ||
                lifecycleOwnershipPolicy.didDefineFutureCommandQueueOwnershipPolicy == false ||
                lifecycleOwnershipPolicy.didKeepFutureQueueInBackendPlatformOwner == false ||
                lifecycleOwnershipPolicy.didKeepQueueOutOfCorePacket == false ||
                lifecycleOwnershipPolicy.didDescribeQueueDeviceLayerDrawableRelation == false ||
                lifecycleOwnershipPolicy.didKeepCommandQueueLifecycleOwnershipValueOnly == false ||
                lifecycleOwnershipPolicy.didAvoidCommandQueueCreation == false ||
                lifecycleOwnershipPolicy.didAvoidBackendPermission == false ||
                lifecycleOwnershipPolicy.didAvoidRendererStateWrite == false ||
                lifecycleOwnershipPolicy.didAvoidRenderingPermission == false ||
                lifecycleOwnershipPolicy.shouldDeferRendererCommandQueueLifecycleOwnershipPolicy ||
                lifecycleOwnershipPolicy.shouldReportRendererCommandQueueLifecycleOwnershipPolicyBlocked
            )
        ) ||
        (lifecycleOwnershipPolicy.didPreserveRendererCommandQueueLifecycleIntent &&
            lifecycleOwnershipPolicy.didPrepareRendererCommandQueueLifecycleOwnershipPolicy == false) ||
        (lifecycleOwnershipPolicy.shouldDeferRendererCommandQueueLifecycleOwnershipPolicy &&
            lifecycleOwnershipPolicy.shouldReportRendererCommandQueueLifecycleOwnershipPolicyBlocked)

    // creation guard 只描述 future preconditions；这里不创建 queue 或 submission object。
    if (
        lifecycleOwnershipPolicy.shouldReportRendererCommandQueueLifecycleOwnershipPolicyBlocked ||
        guardInconsistent
    ) {
        return CjguiInternalRendererCommandQueueCreationGuard(
            lifecycleOwnershipPolicy,
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

    if (ownershipReady) {
        return CjguiInternalRendererCommandQueueCreationGuard(
            lifecycleOwnershipPolicy,
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
        return CjguiInternalRendererCommandQueueCreationGuard(
            lifecycleOwnershipPolicy,
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

    return CjguiInternalRendererCommandQueueCreationGuard(
        lifecycleOwnershipPolicy,
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

func cjguiInternalBuildRendererCommandQueueLifetimePolicy(
    creationGuard: CjguiInternalRendererCommandQueueCreationGuard
): CjguiInternalRendererCommandQueueLifetimePolicy {
    let guardReady = creationGuard.didPrepareRendererCommandQueueCreationGuard &&
        creationGuard.didPreserveRendererCommandQueueLifecycleOwnershipPolicy &&
        creationGuard.didDefineFutureQueueCreationPreconditions &&
        creationGuard.didDescribeNoDrawFailureValueFacts &&
        creationGuard.didDescribeShutdownRollbackGuard &&
        creationGuard.didKeepQueueCreationGuardValueOnly &&
        creationGuard.didAvoidCommandQueueCreation &&
        creationGuard.didAvoidPlatformObjectCreation &&
        creationGuard.didAvoidCommandBufferCreation &&
        creationGuard.didAvoidRendererStateWrite &&
        creationGuard.didAvoidRenderingPermission &&
        creationGuard.shouldDeferRendererCommandQueueCreationGuard == false &&
        creationGuard.shouldReportRendererCommandQueueCreationGuardBlocked == false
    let lifetimeDeferred = creationGuard.didPrepareRendererCommandQueueCreationGuard == false &&
        creationGuard.shouldDeferRendererCommandQueueCreationGuard &&
        creationGuard.shouldReportRendererCommandQueueCreationGuardBlocked == false
    let lifetimeInconsistent = (
        creationGuard.didPrepareRendererCommandQueueCreationGuard &&
            (
                creationGuard.didPreserveRendererCommandQueueLifecycleOwnershipPolicy == false ||
                creationGuard.didDefineFutureQueueCreationPreconditions == false ||
                creationGuard.didDescribeNoDrawFailureValueFacts == false ||
                creationGuard.didDescribeShutdownRollbackGuard == false ||
                creationGuard.didKeepQueueCreationGuardValueOnly == false ||
                creationGuard.didAvoidCommandQueueCreation == false ||
                creationGuard.didAvoidPlatformObjectCreation == false ||
                creationGuard.didAvoidCommandBufferCreation == false ||
                creationGuard.didAvoidRendererStateWrite == false ||
                creationGuard.didAvoidRenderingPermission == false ||
                creationGuard.shouldDeferRendererCommandQueueCreationGuard ||
                creationGuard.shouldReportRendererCommandQueueCreationGuardBlocked
            )
        ) ||
        (creationGuard.didPreserveRendererCommandQueueLifecycleOwnershipPolicy &&
            creationGuard.didPrepareRendererCommandQueueCreationGuard == false) ||
        (creationGuard.shouldDeferRendererCommandQueueCreationGuard &&
            creationGuard.shouldReportRendererCommandQueueCreationGuardBlocked)

    // lifetime policy 不管理真实 queue lifetime；不一致时保持 fail-closed。
    if (
        creationGuard.shouldReportRendererCommandQueueCreationGuardBlocked ||
        lifetimeInconsistent
    ) {
        return CjguiInternalRendererCommandQueueLifetimePolicy(
            creationGuard,
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
        return CjguiInternalRendererCommandQueueLifetimePolicy(
            creationGuard,
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

    if (lifetimeDeferred) {
        return CjguiInternalRendererCommandQueueLifetimePolicy(
            creationGuard,
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

    return CjguiInternalRendererCommandQueueLifetimePolicy(
        creationGuard,
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

func cjguiInternalBuildRendererNoCommandQueueReadiness(
    lifetimePolicy: CjguiInternalRendererCommandQueueLifetimePolicy
): CjguiInternalRendererNoCommandQueueReadiness {
    let lifetimeReady = lifetimePolicy.didPrepareRendererCommandQueueLifetimePolicy &&
        lifetimePolicy.didPreserveRendererCommandQueueCreationGuard &&
        lifetimePolicy.didDefineFutureQueueLifetimePolicy &&
        lifetimePolicy.didDescribeFutureShutdownPolicy &&
        lifetimePolicy.didDescribeFutureRollbackPolicy &&
        lifetimePolicy.didDescribeFramePacingRelationship &&
        lifetimePolicy.didKeepQueueLifetimePolicyValueOnly &&
        lifetimePolicy.didAvoidRealQueueLifetimeManagement &&
        lifetimePolicy.didAvoidCommandQueueCreation &&
        lifetimePolicy.didAvoidRendererStateWrite &&
        lifetimePolicy.didAvoidRenderingPermission &&
        lifetimePolicy.shouldDeferRendererCommandQueueLifetimePolicy == false &&
        lifetimePolicy.shouldReportRendererCommandQueueLifetimePolicyBlocked == false
    let readinessDeferred = lifetimePolicy.didPrepareRendererCommandQueueLifetimePolicy == false &&
        lifetimePolicy.shouldDeferRendererCommandQueueLifetimePolicy &&
        lifetimePolicy.shouldReportRendererCommandQueueLifetimePolicyBlocked == false
    let readinessInconsistent = (
        lifetimePolicy.didPrepareRendererCommandQueueLifetimePolicy &&
            (
                lifetimePolicy.didPreserveRendererCommandQueueCreationGuard == false ||
                lifetimePolicy.didDefineFutureQueueLifetimePolicy == false ||
                lifetimePolicy.didDescribeFutureShutdownPolicy == false ||
                lifetimePolicy.didDescribeFutureRollbackPolicy == false ||
                lifetimePolicy.didDescribeFramePacingRelationship == false ||
                lifetimePolicy.didKeepQueueLifetimePolicyValueOnly == false ||
                lifetimePolicy.didAvoidRealQueueLifetimeManagement == false ||
                lifetimePolicy.didAvoidCommandQueueCreation == false ||
                lifetimePolicy.didAvoidRendererStateWrite == false ||
                lifetimePolicy.didAvoidRenderingPermission == false ||
                lifetimePolicy.shouldDeferRendererCommandQueueLifetimePolicy ||
                lifetimePolicy.shouldReportRendererCommandQueueLifetimePolicyBlocked
            )
        ) ||
        (lifetimePolicy.didPreserveRendererCommandQueueCreationGuard &&
            lifetimePolicy.didPrepareRendererCommandQueueLifetimePolicy == false) ||
        (lifetimePolicy.shouldDeferRendererCommandQueueLifetimePolicy &&
            lifetimePolicy.shouldReportRendererCommandQueueLifetimePolicyBlocked)

    // endpoint 只记录 no-command-queue value facts；它不授予 backend 或 render permission。
    if (
        lifetimePolicy.shouldReportRendererCommandQueueLifetimePolicyBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoCommandQueueReadiness(
            lifetimePolicy,
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
            true
        )
    }

    if (lifetimeReady) {
        return CjguiInternalRendererNoCommandQueueReadiness(
            lifetimePolicy,
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
            true
        )
    }

    if (readinessDeferred) {
        return CjguiInternalRendererNoCommandQueueReadiness(
            lifetimePolicy,
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
            true
        )
    }

    return CjguiInternalRendererNoCommandQueueReadiness(
        lifetimePolicy,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererCommandQueueLifecycleDraft(
): CjguiInternalRendererNoCommandQueueReadiness {
    // 默认 draft 只串联 no-platform-resource -> command queue lifecycle value facts；
    // 它不创建 command queue、不创建平台对象、不提交或执行任何绘制。
    let noPlatformResourceReadiness = cjguiInternalExecuteDefaultRendererPlatformResourceOwnerDraft()
    let lifecycleIntent =
        cjguiInternalBuildRendererCommandQueueLifecycleIntent(noPlatformResourceReadiness)
    let ownershipPolicy =
        cjguiInternalBuildRendererCommandQueueLifecycleOwnershipPolicy(lifecycleIntent)
    let creationGuard = cjguiInternalBuildRendererCommandQueueCreationGuard(ownershipPolicy)
    let lifetimePolicy = cjguiInternalBuildRendererCommandQueueLifetimePolicy(creationGuard)
    return cjguiInternalBuildRendererNoCommandQueueReadiness(lifetimePolicy)
}
