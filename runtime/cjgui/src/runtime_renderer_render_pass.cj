package cjgui

// Owner: Renderer render pass lifecycle value boundary.
// Truth: 只消费 CjguiInternalRendererNoCommandBufferReadiness，表达 future render pass
// lifecycle intent、attachment policy、load-store policy、clear-color policy 与
// no-render-pass readiness 的内部 value facts。
// Stop-line: 这里不创建或持有 MTLRenderPassDescriptor / MTLRenderCommandEncoder /
// drawable / texture / attachment object / command buffer，也不让平台对象或指针类资源
// 进入 core value pipeline，不接后端，不触发绘制，不写 renderer state。
// Same-shape Boundary Brake: 本 owner 新增 attachment / load-store / clear-color /
// no-render-pass vocabulary，不把 no-command-buffer readiness 包成 receipt / record /
// publication。

// Render pass lifecycle intent 只表达 future lifecycle intent；
// 它不是 descriptor creation，也不是 backend / render permission。
struct CjguiInternalRendererRenderPassLifecycleIntent {
    let noCommandBufferReadiness: CjguiInternalRendererNoCommandBufferReadiness
    let didPrepareRendererRenderPassLifecycleIntent: Bool
    let shouldDeferRendererRenderPassLifecycleIntent: Bool
    let shouldReportRendererRenderPassLifecycleIntentBlocked: Bool
    let didPreserveRendererNoCommandBufferReadiness: Bool
    let didDefineFutureRenderPassLifecycleIntent: Bool
    let didDescribeAttachmentRoleFacts: Bool
    let didDescribeDrawableSizeColorRelation: Bool
    let didKeepRenderPassLifecycleIntentValueOnly: Bool
    let didAvoidDescriptorCreation: Bool
    let didAvoidEncoderCreation: Bool
    let didAvoidBackendPermission: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool
    let didAvoidReceiptRecordEmission: Bool

    init(
        noCommandBufferReadiness: CjguiInternalRendererNoCommandBufferReadiness,
        didPrepareRendererRenderPassLifecycleIntent: Bool,
        shouldDeferRendererRenderPassLifecycleIntent: Bool,
        shouldReportRendererRenderPassLifecycleIntentBlocked: Bool,
        didPreserveRendererNoCommandBufferReadiness: Bool,
        didDefineFutureRenderPassLifecycleIntent: Bool,
        didDescribeAttachmentRoleFacts: Bool,
        didDescribeDrawableSizeColorRelation: Bool,
        didKeepRenderPassLifecycleIntentValueOnly: Bool,
        didAvoidDescriptorCreation: Bool,
        didAvoidEncoderCreation: Bool,
        didAvoidBackendPermission: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool,
        didAvoidReceiptRecordEmission: Bool
    ) {
        this.noCommandBufferReadiness = noCommandBufferReadiness
        this.didPrepareRendererRenderPassLifecycleIntent =
            didPrepareRendererRenderPassLifecycleIntent
        this.shouldDeferRendererRenderPassLifecycleIntent =
            shouldDeferRendererRenderPassLifecycleIntent
        this.shouldReportRendererRenderPassLifecycleIntentBlocked =
            shouldReportRendererRenderPassLifecycleIntentBlocked
        this.didPreserveRendererNoCommandBufferReadiness =
            didPreserveRendererNoCommandBufferReadiness
        this.didDefineFutureRenderPassLifecycleIntent =
            didDefineFutureRenderPassLifecycleIntent
        this.didDescribeAttachmentRoleFacts = didDescribeAttachmentRoleFacts
        this.didDescribeDrawableSizeColorRelation = didDescribeDrawableSizeColorRelation
        this.didKeepRenderPassLifecycleIntentValueOnly =
            didKeepRenderPassLifecycleIntentValueOnly
        this.didAvoidDescriptorCreation = didAvoidDescriptorCreation
        this.didAvoidEncoderCreation = didAvoidEncoderCreation
        this.didAvoidBackendPermission = didAvoidBackendPermission
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
        this.didAvoidReceiptRecordEmission = didAvoidReceiptRecordEmission
    }
}

// Attachment policy 只表达 future attachment role / target relation facts；
// 它不创建 texture、attachment object 或 descriptor。
struct CjguiInternalRendererRenderPassAttachmentPolicy {
    let lifecycleIntent: CjguiInternalRendererRenderPassLifecycleIntent
    let didPrepareRendererRenderPassAttachmentPolicy: Bool
    let shouldDeferRendererRenderPassAttachmentPolicy: Bool
    let shouldReportRendererRenderPassAttachmentPolicyBlocked: Bool
    let didPreserveRendererRenderPassLifecycleIntent: Bool
    let didDefineFutureAttachmentPolicy: Bool
    let didDescribeAttachmentRoleFacts: Bool
    let didDescribeTargetRelationFacts: Bool
    let didKeepAttachmentPolicyValueOnly: Bool
    let didAvoidTextureOrAttachmentObject: Bool
    let didAvoidDescriptorCreation: Bool
    let didAvoidPlatformObjectReference: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool

    init(
        lifecycleIntent: CjguiInternalRendererRenderPassLifecycleIntent,
        didPrepareRendererRenderPassAttachmentPolicy: Bool,
        shouldDeferRendererRenderPassAttachmentPolicy: Bool,
        shouldReportRendererRenderPassAttachmentPolicyBlocked: Bool,
        didPreserveRendererRenderPassLifecycleIntent: Bool,
        didDefineFutureAttachmentPolicy: Bool,
        didDescribeAttachmentRoleFacts: Bool,
        didDescribeTargetRelationFacts: Bool,
        didKeepAttachmentPolicyValueOnly: Bool,
        didAvoidTextureOrAttachmentObject: Bool,
        didAvoidDescriptorCreation: Bool,
        didAvoidPlatformObjectReference: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.lifecycleIntent = lifecycleIntent
        this.didPrepareRendererRenderPassAttachmentPolicy =
            didPrepareRendererRenderPassAttachmentPolicy
        this.shouldDeferRendererRenderPassAttachmentPolicy =
            shouldDeferRendererRenderPassAttachmentPolicy
        this.shouldReportRendererRenderPassAttachmentPolicyBlocked =
            shouldReportRendererRenderPassAttachmentPolicyBlocked
        this.didPreserveRendererRenderPassLifecycleIntent =
            didPreserveRendererRenderPassLifecycleIntent
        this.didDefineFutureAttachmentPolicy = didDefineFutureAttachmentPolicy
        this.didDescribeAttachmentRoleFacts = didDescribeAttachmentRoleFacts
        this.didDescribeTargetRelationFacts = didDescribeTargetRelationFacts
        this.didKeepAttachmentPolicyValueOnly = didKeepAttachmentPolicyValueOnly
        this.didAvoidTextureOrAttachmentObject = didAvoidTextureOrAttachmentObject
        this.didAvoidDescriptorCreation = didAvoidDescriptorCreation
        this.didAvoidPlatformObjectReference = didAvoidPlatformObjectReference
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// Load-store policy 只表达 future load/store intent；
// 它不操作 attachment，也不改 descriptor。
struct CjguiInternalRendererRenderPassLoadStorePolicy {
    let attachmentPolicy: CjguiInternalRendererRenderPassAttachmentPolicy
    let didPrepareRendererRenderPassLoadStorePolicy: Bool
    let shouldDeferRendererRenderPassLoadStorePolicy: Bool
    let shouldReportRendererRenderPassLoadStorePolicyBlocked: Bool
    let didPreserveRendererRenderPassAttachmentPolicy: Bool
    let didDefineFutureLoadStorePolicy: Bool
    let didDescribeLoadIntentFacts: Bool
    let didDescribeStoreIntentFacts: Bool
    let didDescribeFailureNoDrawFallback: Bool
    let didKeepLoadStorePolicyValueOnly: Bool
    let didAvoidAttachmentMutation: Bool
    let didAvoidDescriptorMutation: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool

    init(
        attachmentPolicy: CjguiInternalRendererRenderPassAttachmentPolicy,
        didPrepareRendererRenderPassLoadStorePolicy: Bool,
        shouldDeferRendererRenderPassLoadStorePolicy: Bool,
        shouldReportRendererRenderPassLoadStorePolicyBlocked: Bool,
        didPreserveRendererRenderPassAttachmentPolicy: Bool,
        didDefineFutureLoadStorePolicy: Bool,
        didDescribeLoadIntentFacts: Bool,
        didDescribeStoreIntentFacts: Bool,
        didDescribeFailureNoDrawFallback: Bool,
        didKeepLoadStorePolicyValueOnly: Bool,
        didAvoidAttachmentMutation: Bool,
        didAvoidDescriptorMutation: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.attachmentPolicy = attachmentPolicy
        this.didPrepareRendererRenderPassLoadStorePolicy =
            didPrepareRendererRenderPassLoadStorePolicy
        this.shouldDeferRendererRenderPassLoadStorePolicy =
            shouldDeferRendererRenderPassLoadStorePolicy
        this.shouldReportRendererRenderPassLoadStorePolicyBlocked =
            shouldReportRendererRenderPassLoadStorePolicyBlocked
        this.didPreserveRendererRenderPassAttachmentPolicy =
            didPreserveRendererRenderPassAttachmentPolicy
        this.didDefineFutureLoadStorePolicy = didDefineFutureLoadStorePolicy
        this.didDescribeLoadIntentFacts = didDescribeLoadIntentFacts
        this.didDescribeStoreIntentFacts = didDescribeStoreIntentFacts
        this.didDescribeFailureNoDrawFallback = didDescribeFailureNoDrawFallback
        this.didKeepLoadStorePolicyValueOnly = didKeepLoadStorePolicyValueOnly
        this.didAvoidAttachmentMutation = didAvoidAttachmentMutation
        this.didAvoidDescriptorMutation = didAvoidDescriptorMutation
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// Clear-color policy 只表达 dehydrated clear-color facts；
// 它不设置平台 descriptor，也不进入 encoder lifecycle。
struct CjguiInternalRendererRenderPassClearColorPolicy {
    let loadStorePolicy: CjguiInternalRendererRenderPassLoadStorePolicy
    let didPrepareRendererRenderPassClearColorPolicy: Bool
    let shouldDeferRendererRenderPassClearColorPolicy: Bool
    let shouldReportRendererRenderPassClearColorPolicyBlocked: Bool
    let didPreserveRendererRenderPassLoadStorePolicy: Bool
    let didDefineFutureClearColorPolicy: Bool
    let didDescribeDehydratedClearColorFacts: Bool
    let didDescribeColorSpaceRelationFacts: Bool
    let didDescribeResizeRelationFacts: Bool
    let didKeepClearColorPolicyValueOnly: Bool
    let didAvoidPlatformDescriptorMutation: Bool
    let didAvoidEncoderLifecycle: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool

    init(
        loadStorePolicy: CjguiInternalRendererRenderPassLoadStorePolicy,
        didPrepareRendererRenderPassClearColorPolicy: Bool,
        shouldDeferRendererRenderPassClearColorPolicy: Bool,
        shouldReportRendererRenderPassClearColorPolicyBlocked: Bool,
        didPreserveRendererRenderPassLoadStorePolicy: Bool,
        didDefineFutureClearColorPolicy: Bool,
        didDescribeDehydratedClearColorFacts: Bool,
        didDescribeColorSpaceRelationFacts: Bool,
        didDescribeResizeRelationFacts: Bool,
        didKeepClearColorPolicyValueOnly: Bool,
        didAvoidPlatformDescriptorMutation: Bool,
        didAvoidEncoderLifecycle: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.loadStorePolicy = loadStorePolicy
        this.didPrepareRendererRenderPassClearColorPolicy =
            didPrepareRendererRenderPassClearColorPolicy
        this.shouldDeferRendererRenderPassClearColorPolicy =
            shouldDeferRendererRenderPassClearColorPolicy
        this.shouldReportRendererRenderPassClearColorPolicyBlocked =
            shouldReportRendererRenderPassClearColorPolicyBlocked
        this.didPreserveRendererRenderPassLoadStorePolicy =
            didPreserveRendererRenderPassLoadStorePolicy
        this.didDefineFutureClearColorPolicy = didDefineFutureClearColorPolicy
        this.didDescribeDehydratedClearColorFacts =
            didDescribeDehydratedClearColorFacts
        this.didDescribeColorSpaceRelationFacts = didDescribeColorSpaceRelationFacts
        this.didDescribeResizeRelationFacts = didDescribeResizeRelationFacts
        this.didKeepClearColorPolicyValueOnly = didKeepClearColorPolicyValueOnly
        this.didAvoidPlatformDescriptorMutation = didAvoidPlatformDescriptorMutation
        this.didAvoidEncoderLifecycle = didAvoidEncoderLifecycle
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// No-render-pass readiness 是本 owner 的 endpoint；
// readiness 只表示 future render pass lifecycle boundary 可以继续评估，不代表
// descriptor、encoder、backend 或 render permission。
struct CjguiInternalRendererNoRenderPassReadiness {
    let clearColorPolicy: CjguiInternalRendererRenderPassClearColorPolicy
    let isRendererNoRenderPassReady: Bool
    let canFutureRendererRenderPassBoundaryEvaluate: Bool
    let shouldDeferRendererNoRenderPassReadiness: Bool
    let shouldReportRendererNoRenderPassReadinessBlocked: Bool
    let didSealRendererNoRenderPassReadiness: Bool
    let didPreserveRendererRenderPassClearColorPolicy: Bool
    let didKeepNoRenderPassReadinessValueOnly: Bool
    let didConfirmNoRenderPassDescriptorCreated: Bool
    let didConfirmNoEncoderCreated: Bool
    let didConfirmNoDrawableTextureOrAttachmentObject: Bool
    let didConfirmNoCommandBufferObject: Bool
    let didConfirmNoPlatformObjectReference: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didAvoidBackendPermission: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool
    let didAvoidReceiptRecordEmission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        clearColorPolicy: CjguiInternalRendererRenderPassClearColorPolicy,
        isRendererNoRenderPassReady: Bool,
        canFutureRendererRenderPassBoundaryEvaluate: Bool,
        shouldDeferRendererNoRenderPassReadiness: Bool,
        shouldReportRendererNoRenderPassReadinessBlocked: Bool,
        didSealRendererNoRenderPassReadiness: Bool,
        didPreserveRendererRenderPassClearColorPolicy: Bool,
        didKeepNoRenderPassReadinessValueOnly: Bool,
        didConfirmNoRenderPassDescriptorCreated: Bool,
        didConfirmNoEncoderCreated: Bool,
        didConfirmNoDrawableTextureOrAttachmentObject: Bool,
        didConfirmNoCommandBufferObject: Bool,
        didConfirmNoPlatformObjectReference: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didAvoidBackendPermission: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool,
        didAvoidReceiptRecordEmission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.clearColorPolicy = clearColorPolicy
        this.isRendererNoRenderPassReady = isRendererNoRenderPassReady
        this.canFutureRendererRenderPassBoundaryEvaluate =
            canFutureRendererRenderPassBoundaryEvaluate
        this.shouldDeferRendererNoRenderPassReadiness =
            shouldDeferRendererNoRenderPassReadiness
        this.shouldReportRendererNoRenderPassReadinessBlocked =
            shouldReportRendererNoRenderPassReadinessBlocked
        this.didSealRendererNoRenderPassReadiness = didSealRendererNoRenderPassReadiness
        this.didPreserveRendererRenderPassClearColorPolicy =
            didPreserveRendererRenderPassClearColorPolicy
        this.didKeepNoRenderPassReadinessValueOnly =
            didKeepNoRenderPassReadinessValueOnly
        this.didConfirmNoRenderPassDescriptorCreated =
            didConfirmNoRenderPassDescriptorCreated
        this.didConfirmNoEncoderCreated = didConfirmNoEncoderCreated
        this.didConfirmNoDrawableTextureOrAttachmentObject =
            didConfirmNoDrawableTextureOrAttachmentObject
        this.didConfirmNoCommandBufferObject = didConfirmNoCommandBufferObject
        this.didConfirmNoPlatformObjectReference = didConfirmNoPlatformObjectReference
        this.didConfirmNoPointerLikeResource = didConfirmNoPointerLikeResource
        this.didAvoidBackendPermission = didAvoidBackendPermission
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
        this.didAvoidReceiptRecordEmission = didAvoidReceiptRecordEmission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererRenderPassLifecycleIntent(
    noCommandBufferReadiness: CjguiInternalRendererNoCommandBufferReadiness
): CjguiInternalRendererRenderPassLifecycleIntent {
    let noCommandBufferReady = noCommandBufferReadiness.isRendererNoCommandBufferReady &&
        noCommandBufferReadiness.canFutureRendererCommandBufferBoundaryEvaluate &&
        noCommandBufferReadiness.didSealRendererNoCommandBufferReadiness &&
        noCommandBufferReadiness.didPreserveRendererCommandBufferSingleUsePolicy &&
        noCommandBufferReadiness.didKeepNoCommandBufferReadinessValueOnly &&
        noCommandBufferReadiness.didConfirmNoCommandBufferCreated &&
        noCommandBufferReadiness.didConfirmNoQueueOrDrawableObject &&
        noCommandBufferReadiness.didConfirmNoRenderPassOrEncoderObject &&
        noCommandBufferReadiness.didConfirmNoNativeResourceToken &&
        noCommandBufferReadiness.didConfirmNoPointerLikeResource &&
        noCommandBufferReadiness.didAvoidBackendPermission &&
        noCommandBufferReadiness.didAvoidRendererStateWrite &&
        noCommandBufferReadiness.didAvoidRenderingPermission &&
        noCommandBufferReadiness.didAvoidThinWrapper &&
        noCommandBufferReadiness.didStayFullRebuildOnly &&
        noCommandBufferReadiness.shouldDeferRendererNoCommandBufferReadiness == false &&
        noCommandBufferReadiness.shouldReportRendererNoCommandBufferReadinessBlocked == false
    let intentDeferred =
        noCommandBufferReadiness.isRendererNoCommandBufferReady == false &&
        noCommandBufferReadiness.canFutureRendererCommandBufferBoundaryEvaluate == false &&
        noCommandBufferReadiness.shouldDeferRendererNoCommandBufferReadiness &&
        noCommandBufferReadiness.shouldReportRendererNoCommandBufferReadinessBlocked == false
    let intentInconsistent = (
        noCommandBufferReadiness.isRendererNoCommandBufferReady &&
            (
                noCommandBufferReadiness.canFutureRendererCommandBufferBoundaryEvaluate == false ||
                noCommandBufferReadiness.didSealRendererNoCommandBufferReadiness == false ||
                noCommandBufferReadiness.didPreserveRendererCommandBufferSingleUsePolicy == false ||
                noCommandBufferReadiness.didKeepNoCommandBufferReadinessValueOnly == false ||
                noCommandBufferReadiness.didConfirmNoCommandBufferCreated == false ||
                noCommandBufferReadiness.didConfirmNoQueueOrDrawableObject == false ||
                noCommandBufferReadiness.didConfirmNoRenderPassOrEncoderObject == false ||
                noCommandBufferReadiness.didConfirmNoNativeResourceToken == false ||
                noCommandBufferReadiness.didConfirmNoPointerLikeResource == false ||
                noCommandBufferReadiness.didAvoidBackendPermission == false ||
                noCommandBufferReadiness.didAvoidRendererStateWrite == false ||
                noCommandBufferReadiness.didAvoidRenderingPermission == false ||
                noCommandBufferReadiness.didAvoidThinWrapper == false ||
                noCommandBufferReadiness.didStayFullRebuildOnly == false ||
                noCommandBufferReadiness.shouldDeferRendererNoCommandBufferReadiness ||
                noCommandBufferReadiness.shouldReportRendererNoCommandBufferReadinessBlocked
            )
        ) ||
        (noCommandBufferReadiness.canFutureRendererCommandBufferBoundaryEvaluate &&
            noCommandBufferReadiness.isRendererNoCommandBufferReady == false) ||
        (noCommandBufferReadiness.shouldDeferRendererNoCommandBufferReadiness &&
            noCommandBufferReadiness.shouldReportRendererNoCommandBufferReadinessBlocked)

    // fail-closed：不能把 no-command-buffer readiness 薄包成 render pass lifecycle intent。
    if (
        noCommandBufferReadiness.shouldReportRendererNoCommandBufferReadinessBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererRenderPassLifecycleIntent(
            noCommandBufferReadiness,
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

    if (noCommandBufferReady) {
        return CjguiInternalRendererRenderPassLifecycleIntent(
            noCommandBufferReadiness,
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
        return CjguiInternalRendererRenderPassLifecycleIntent(
            noCommandBufferReadiness,
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

    return CjguiInternalRendererRenderPassLifecycleIntent(
        noCommandBufferReadiness,
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

func cjguiInternalBuildRendererRenderPassAttachmentPolicy(
    lifecycleIntent: CjguiInternalRendererRenderPassLifecycleIntent
): CjguiInternalRendererRenderPassAttachmentPolicy {
    let intentReady = lifecycleIntent.didPrepareRendererRenderPassLifecycleIntent &&
        lifecycleIntent.didPreserveRendererNoCommandBufferReadiness &&
        lifecycleIntent.didDefineFutureRenderPassLifecycleIntent &&
        lifecycleIntent.didDescribeAttachmentRoleFacts &&
        lifecycleIntent.didDescribeDrawableSizeColorRelation &&
        lifecycleIntent.didKeepRenderPassLifecycleIntentValueOnly &&
        lifecycleIntent.didAvoidDescriptorCreation &&
        lifecycleIntent.didAvoidEncoderCreation &&
        lifecycleIntent.didAvoidBackendPermission &&
        lifecycleIntent.didAvoidRendererStateWrite &&
        lifecycleIntent.didAvoidRenderingPermission &&
        lifecycleIntent.didAvoidReceiptRecordEmission &&
        lifecycleIntent.shouldDeferRendererRenderPassLifecycleIntent == false &&
        lifecycleIntent.shouldReportRendererRenderPassLifecycleIntentBlocked == false
    let policyDeferred =
        lifecycleIntent.didPrepareRendererRenderPassLifecycleIntent == false &&
        lifecycleIntent.shouldDeferRendererRenderPassLifecycleIntent &&
        lifecycleIntent.shouldReportRendererRenderPassLifecycleIntentBlocked == false
    let policyInconsistent = (
        lifecycleIntent.didPrepareRendererRenderPassLifecycleIntent &&
            (
                lifecycleIntent.didPreserveRendererNoCommandBufferReadiness == false ||
                lifecycleIntent.didDefineFutureRenderPassLifecycleIntent == false ||
                lifecycleIntent.didDescribeAttachmentRoleFacts == false ||
                lifecycleIntent.didDescribeDrawableSizeColorRelation == false ||
                lifecycleIntent.didKeepRenderPassLifecycleIntentValueOnly == false ||
                lifecycleIntent.didAvoidDescriptorCreation == false ||
                lifecycleIntent.didAvoidEncoderCreation == false ||
                lifecycleIntent.didAvoidBackendPermission == false ||
                lifecycleIntent.didAvoidRendererStateWrite == false ||
                lifecycleIntent.didAvoidRenderingPermission == false ||
                lifecycleIntent.didAvoidReceiptRecordEmission == false ||
                lifecycleIntent.shouldDeferRendererRenderPassLifecycleIntent ||
                lifecycleIntent.shouldReportRendererRenderPassLifecycleIntentBlocked
            )
        ) ||
        (lifecycleIntent.didPreserveRendererNoCommandBufferReadiness &&
            lifecycleIntent.didPrepareRendererRenderPassLifecycleIntent == false) ||
        (lifecycleIntent.shouldDeferRendererRenderPassLifecycleIntent &&
            lifecycleIntent.shouldReportRendererRenderPassLifecycleIntentBlocked)

    // attachment policy 只记录 role / target relation facts；这里不创建 attachment。
    if (
        lifecycleIntent.shouldReportRendererRenderPassLifecycleIntentBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererRenderPassAttachmentPolicy(
            lifecycleIntent,
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

    if (intentReady) {
        return CjguiInternalRendererRenderPassAttachmentPolicy(
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
        return CjguiInternalRendererRenderPassAttachmentPolicy(
            lifecycleIntent,
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

    return CjguiInternalRendererRenderPassAttachmentPolicy(
        lifecycleIntent,
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

func cjguiInternalBuildRendererRenderPassLoadStorePolicy(
    attachmentPolicy: CjguiInternalRendererRenderPassAttachmentPolicy
): CjguiInternalRendererRenderPassLoadStorePolicy {
    let policyReady = attachmentPolicy.didPrepareRendererRenderPassAttachmentPolicy &&
        attachmentPolicy.didPreserveRendererRenderPassLifecycleIntent &&
        attachmentPolicy.didDefineFutureAttachmentPolicy &&
        attachmentPolicy.didDescribeAttachmentRoleFacts &&
        attachmentPolicy.didDescribeTargetRelationFacts &&
        attachmentPolicy.didKeepAttachmentPolicyValueOnly &&
        attachmentPolicy.didAvoidTextureOrAttachmentObject &&
        attachmentPolicy.didAvoidDescriptorCreation &&
        attachmentPolicy.didAvoidPlatformObjectReference &&
        attachmentPolicy.didAvoidRendererStateWrite &&
        attachmentPolicy.didAvoidRenderingPermission &&
        attachmentPolicy.shouldDeferRendererRenderPassAttachmentPolicy == false &&
        attachmentPolicy.shouldReportRendererRenderPassAttachmentPolicyBlocked == false
    let loadStoreDeferred =
        attachmentPolicy.didPrepareRendererRenderPassAttachmentPolicy == false &&
        attachmentPolicy.shouldDeferRendererRenderPassAttachmentPolicy &&
        attachmentPolicy.shouldReportRendererRenderPassAttachmentPolicyBlocked == false
    let loadStoreInconsistent = (
        attachmentPolicy.didPrepareRendererRenderPassAttachmentPolicy &&
            (
                attachmentPolicy.didPreserveRendererRenderPassLifecycleIntent == false ||
                attachmentPolicy.didDefineFutureAttachmentPolicy == false ||
                attachmentPolicy.didDescribeAttachmentRoleFacts == false ||
                attachmentPolicy.didDescribeTargetRelationFacts == false ||
                attachmentPolicy.didKeepAttachmentPolicyValueOnly == false ||
                attachmentPolicy.didAvoidTextureOrAttachmentObject == false ||
                attachmentPolicy.didAvoidDescriptorCreation == false ||
                attachmentPolicy.didAvoidPlatformObjectReference == false ||
                attachmentPolicy.didAvoidRendererStateWrite == false ||
                attachmentPolicy.didAvoidRenderingPermission == false ||
                attachmentPolicy.shouldDeferRendererRenderPassAttachmentPolicy ||
                attachmentPolicy.shouldReportRendererRenderPassAttachmentPolicyBlocked
            )
        ) ||
        (attachmentPolicy.didPreserveRendererRenderPassLifecycleIntent &&
            attachmentPolicy.didPrepareRendererRenderPassAttachmentPolicy == false) ||
        (attachmentPolicy.shouldDeferRendererRenderPassAttachmentPolicy &&
            attachmentPolicy.shouldReportRendererRenderPassAttachmentPolicyBlocked)

    // load-store policy 只表达 intent facts；这里不操作 attachment。
    if (
        attachmentPolicy.shouldReportRendererRenderPassAttachmentPolicyBlocked ||
        loadStoreInconsistent
    ) {
        return CjguiInternalRendererRenderPassLoadStorePolicy(
            attachmentPolicy,
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
        return CjguiInternalRendererRenderPassLoadStorePolicy(
            attachmentPolicy,
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

    if (loadStoreDeferred) {
        return CjguiInternalRendererRenderPassLoadStorePolicy(
            attachmentPolicy,
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

    return CjguiInternalRendererRenderPassLoadStorePolicy(
        attachmentPolicy,
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

func cjguiInternalBuildRendererRenderPassClearColorPolicy(
    loadStorePolicy: CjguiInternalRendererRenderPassLoadStorePolicy
): CjguiInternalRendererRenderPassClearColorPolicy {
    let policyReady = loadStorePolicy.didPrepareRendererRenderPassLoadStorePolicy &&
        loadStorePolicy.didPreserveRendererRenderPassAttachmentPolicy &&
        loadStorePolicy.didDefineFutureLoadStorePolicy &&
        loadStorePolicy.didDescribeLoadIntentFacts &&
        loadStorePolicy.didDescribeStoreIntentFacts &&
        loadStorePolicy.didDescribeFailureNoDrawFallback &&
        loadStorePolicy.didKeepLoadStorePolicyValueOnly &&
        loadStorePolicy.didAvoidAttachmentMutation &&
        loadStorePolicy.didAvoidDescriptorMutation &&
        loadStorePolicy.didAvoidRendererStateWrite &&
        loadStorePolicy.didAvoidRenderingPermission &&
        loadStorePolicy.shouldDeferRendererRenderPassLoadStorePolicy == false &&
        loadStorePolicy.shouldReportRendererRenderPassLoadStorePolicyBlocked == false
    let clearDeferred =
        loadStorePolicy.didPrepareRendererRenderPassLoadStorePolicy == false &&
        loadStorePolicy.shouldDeferRendererRenderPassLoadStorePolicy &&
        loadStorePolicy.shouldReportRendererRenderPassLoadStorePolicyBlocked == false
    let clearInconsistent = (
        loadStorePolicy.didPrepareRendererRenderPassLoadStorePolicy &&
            (
                loadStorePolicy.didPreserveRendererRenderPassAttachmentPolicy == false ||
                loadStorePolicy.didDefineFutureLoadStorePolicy == false ||
                loadStorePolicy.didDescribeLoadIntentFacts == false ||
                loadStorePolicy.didDescribeStoreIntentFacts == false ||
                loadStorePolicy.didDescribeFailureNoDrawFallback == false ||
                loadStorePolicy.didKeepLoadStorePolicyValueOnly == false ||
                loadStorePolicy.didAvoidAttachmentMutation == false ||
                loadStorePolicy.didAvoidDescriptorMutation == false ||
                loadStorePolicy.didAvoidRendererStateWrite == false ||
                loadStorePolicy.didAvoidRenderingPermission == false ||
                loadStorePolicy.shouldDeferRendererRenderPassLoadStorePolicy ||
                loadStorePolicy.shouldReportRendererRenderPassLoadStorePolicyBlocked
            )
        ) ||
        (loadStorePolicy.didPreserveRendererRenderPassAttachmentPolicy &&
            loadStorePolicy.didPrepareRendererRenderPassLoadStorePolicy == false) ||
        (loadStorePolicy.shouldDeferRendererRenderPassLoadStorePolicy &&
            loadStorePolicy.shouldReportRendererRenderPassLoadStorePolicyBlocked)

    // clear-color policy 只表达 dehydrated facts；这里不设置平台 descriptor。
    if (
        loadStorePolicy.shouldReportRendererRenderPassLoadStorePolicyBlocked ||
        clearInconsistent
    ) {
        return CjguiInternalRendererRenderPassClearColorPolicy(
            loadStorePolicy,
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
        return CjguiInternalRendererRenderPassClearColorPolicy(
            loadStorePolicy,
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

    if (clearDeferred) {
        return CjguiInternalRendererRenderPassClearColorPolicy(
            loadStorePolicy,
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

    return CjguiInternalRendererRenderPassClearColorPolicy(
        loadStorePolicy,
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

func cjguiInternalBuildRendererNoRenderPassReadiness(
    clearColorPolicy: CjguiInternalRendererRenderPassClearColorPolicy
): CjguiInternalRendererNoRenderPassReadiness {
    let policyReady = clearColorPolicy.didPrepareRendererRenderPassClearColorPolicy &&
        clearColorPolicy.didPreserveRendererRenderPassLoadStorePolicy &&
        clearColorPolicy.didDefineFutureClearColorPolicy &&
        clearColorPolicy.didDescribeDehydratedClearColorFacts &&
        clearColorPolicy.didDescribeColorSpaceRelationFacts &&
        clearColorPolicy.didDescribeResizeRelationFacts &&
        clearColorPolicy.didKeepClearColorPolicyValueOnly &&
        clearColorPolicy.didAvoidPlatformDescriptorMutation &&
        clearColorPolicy.didAvoidEncoderLifecycle &&
        clearColorPolicy.didAvoidRendererStateWrite &&
        clearColorPolicy.didAvoidRenderingPermission &&
        clearColorPolicy.shouldDeferRendererRenderPassClearColorPolicy == false &&
        clearColorPolicy.shouldReportRendererRenderPassClearColorPolicyBlocked == false
    let readinessDeferred =
        clearColorPolicy.didPrepareRendererRenderPassClearColorPolicy == false &&
        clearColorPolicy.shouldDeferRendererRenderPassClearColorPolicy &&
        clearColorPolicy.shouldReportRendererRenderPassClearColorPolicyBlocked == false
    let readinessInconsistent = (
        clearColorPolicy.didPrepareRendererRenderPassClearColorPolicy &&
            (
                clearColorPolicy.didPreserveRendererRenderPassLoadStorePolicy == false ||
                clearColorPolicy.didDefineFutureClearColorPolicy == false ||
                clearColorPolicy.didDescribeDehydratedClearColorFacts == false ||
                clearColorPolicy.didDescribeColorSpaceRelationFacts == false ||
                clearColorPolicy.didDescribeResizeRelationFacts == false ||
                clearColorPolicy.didKeepClearColorPolicyValueOnly == false ||
                clearColorPolicy.didAvoidPlatformDescriptorMutation == false ||
                clearColorPolicy.didAvoidEncoderLifecycle == false ||
                clearColorPolicy.didAvoidRendererStateWrite == false ||
                clearColorPolicy.didAvoidRenderingPermission == false ||
                clearColorPolicy.shouldDeferRendererRenderPassClearColorPolicy ||
                clearColorPolicy.shouldReportRendererRenderPassClearColorPolicyBlocked
            )
        ) ||
        (clearColorPolicy.didPreserveRendererRenderPassLoadStorePolicy &&
            clearColorPolicy.didPrepareRendererRenderPassClearColorPolicy == false) ||
        (clearColorPolicy.shouldDeferRendererRenderPassClearColorPolicy &&
            clearColorPolicy.shouldReportRendererRenderPassClearColorPolicyBlocked)

    // endpoint 只记录 no-render-pass value facts；它不授予 backend 或 render permission。
    if (
        clearColorPolicy.shouldReportRendererRenderPassClearColorPolicyBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoRenderPassReadiness(
            clearColorPolicy,
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
            true
        )
    }

    if (policyReady) {
        return CjguiInternalRendererNoRenderPassReadiness(
            clearColorPolicy,
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
            true
        )
    }

    if (readinessDeferred) {
        return CjguiInternalRendererNoRenderPassReadiness(
            clearColorPolicy,
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
            true
        )
    }

    return CjguiInternalRendererNoRenderPassReadiness(
        clearColorPolicy,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererRenderPassLifecycleDraft(
): CjguiInternalRendererNoRenderPassReadiness {
    // 默认 draft 只串联 no-command-buffer -> render pass lifecycle value facts；
    // 它不创建 descriptor、encoder、attachment 或任何平台资源。
    let noCommandBufferReadiness =
        cjguiInternalExecuteDefaultRendererCommandBufferLifecycleDraft()
    let lifecycleIntent =
        cjguiInternalBuildRendererRenderPassLifecycleIntent(noCommandBufferReadiness)
    let attachmentPolicy =
        cjguiInternalBuildRendererRenderPassAttachmentPolicy(lifecycleIntent)
    let loadStorePolicy =
        cjguiInternalBuildRendererRenderPassLoadStorePolicy(attachmentPolicy)
    let clearColorPolicy =
        cjguiInternalBuildRendererRenderPassClearColorPolicy(loadStorePolicy)
    return cjguiInternalBuildRendererNoRenderPassReadiness(clearColorPolicy)
}
