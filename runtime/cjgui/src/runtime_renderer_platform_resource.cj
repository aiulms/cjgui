package cjgui

// Owner: Renderer platform resource owner value boundary.
// Truth: 只消费 CjguiInternalRendererPacketOrderingHardeningResult，表达 future platform
// owner intent、resource confinement、drawable acquisition、command queue ownership 与
// no-platform-resource readiness 的内部 value facts。
// Stop-line: 这里不创建或持有 MTLDevice / CAMetalLayer / queue / drawable / pass /
// encoder / NativeHandle / RawPointer，不接平台实现，不触发绘制，不写 renderer state。
// Same-shape Boundary Brake: 本 owner 新增 platform resource ownership vocabulary，
// 不把 ordering hardening result 包成 receipt / record / publication。

// Platform resource owner intent 只表达 future owner intent；
// 它不是后端 owner 实现，也不复用旧 handoff receipt 语义。
struct CjguiInternalRendererPlatformResourceOwnerIntent {
    let orderingHardeningResult: CjguiInternalRendererPacketOrderingHardeningResult
    let didPrepareRendererPlatformResourceOwnerIntent: Bool
    let shouldDeferRendererPlatformResourceOwnerIntent: Bool
    let shouldReportRendererPlatformResourceOwnerIntentBlocked: Bool
    let didPreserveRendererPacketOrderingHardeningResult: Bool
    let didDefineFuturePlatformOwnerIntent: Bool
    let didKeepPlatformOwnerIntentValueOnly: Bool
    let didAvoidPlatformResourceCreation: Bool
    let didAvoidRendererBackendPermission: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didStayFullRebuildOnly: Bool

    init(
        orderingHardeningResult: CjguiInternalRendererPacketOrderingHardeningResult,
        didPrepareRendererPlatformResourceOwnerIntent: Bool,
        shouldDeferRendererPlatformResourceOwnerIntent: Bool,
        shouldReportRendererPlatformResourceOwnerIntentBlocked: Bool,
        didPreserveRendererPacketOrderingHardeningResult: Bool,
        didDefineFuturePlatformOwnerIntent: Bool,
        didKeepPlatformOwnerIntentValueOnly: Bool,
        didAvoidPlatformResourceCreation: Bool,
        didAvoidRendererBackendPermission: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.orderingHardeningResult = orderingHardeningResult
        this.didPrepareRendererPlatformResourceOwnerIntent =
            didPrepareRendererPlatformResourceOwnerIntent
        this.shouldDeferRendererPlatformResourceOwnerIntent =
            shouldDeferRendererPlatformResourceOwnerIntent
        this.shouldReportRendererPlatformResourceOwnerIntentBlocked =
            shouldReportRendererPlatformResourceOwnerIntentBlocked
        this.didPreserveRendererPacketOrderingHardeningResult =
            didPreserveRendererPacketOrderingHardeningResult
        this.didDefineFuturePlatformOwnerIntent = didDefineFuturePlatformOwnerIntent
        this.didKeepPlatformOwnerIntentValueOnly = didKeepPlatformOwnerIntentValueOnly
        this.didAvoidPlatformResourceCreation = didAvoidPlatformResourceCreation
        this.didAvoidRendererBackendPermission = didAvoidRendererBackendPermission
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Resource confinement policy 只表达 future device / layer / queue / drawable / pass
// 等平台资源必须局限在 future backend owner 内；它不把平台对象放进 core packet。
struct CjguiInternalRendererResourceConfinementPolicy {
    let ownerIntent: CjguiInternalRendererPlatformResourceOwnerIntent
    let didPrepareRendererResourceConfinementPolicy: Bool
    let shouldDeferRendererResourceConfinementPolicy: Bool
    let shouldReportRendererResourceConfinementPolicyBlocked: Bool
    let didPreserveRendererPlatformResourceOwnerIntent: Bool
    let didDefineFutureResourceConfinement: Bool
    let didKeepConfinementPolicyValueOnly: Bool
    let didKeepFutureResourcesInBackendOwner: Bool
    let didKeepPlatformObjectsOutOfCorePacket: Bool
    let didAllowOnlyDehydratedResizeScaleColorPacingFacts: Bool
    let didAvoidPlatformResourceCreation: Bool
    let didAvoidNativeHandle: Bool
    let didAvoidRawPointer: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool

    init(
        ownerIntent: CjguiInternalRendererPlatformResourceOwnerIntent,
        didPrepareRendererResourceConfinementPolicy: Bool,
        shouldDeferRendererResourceConfinementPolicy: Bool,
        shouldReportRendererResourceConfinementPolicyBlocked: Bool,
        didPreserveRendererPlatformResourceOwnerIntent: Bool,
        didDefineFutureResourceConfinement: Bool,
        didKeepConfinementPolicyValueOnly: Bool,
        didKeepFutureResourcesInBackendOwner: Bool,
        didKeepPlatformObjectsOutOfCorePacket: Bool,
        didAllowOnlyDehydratedResizeScaleColorPacingFacts: Bool,
        didAvoidPlatformResourceCreation: Bool,
        didAvoidNativeHandle: Bool,
        didAvoidRawPointer: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.ownerIntent = ownerIntent
        this.didPrepareRendererResourceConfinementPolicy =
            didPrepareRendererResourceConfinementPolicy
        this.shouldDeferRendererResourceConfinementPolicy =
            shouldDeferRendererResourceConfinementPolicy
        this.shouldReportRendererResourceConfinementPolicyBlocked =
            shouldReportRendererResourceConfinementPolicyBlocked
        this.didPreserveRendererPlatformResourceOwnerIntent =
            didPreserveRendererPlatformResourceOwnerIntent
        this.didDefineFutureResourceConfinement = didDefineFutureResourceConfinement
        this.didKeepConfinementPolicyValueOnly = didKeepConfinementPolicyValueOnly
        this.didKeepFutureResourcesInBackendOwner = didKeepFutureResourcesInBackendOwner
        this.didKeepPlatformObjectsOutOfCorePacket = didKeepPlatformObjectsOutOfCorePacket
        this.didAllowOnlyDehydratedResizeScaleColorPacingFacts =
            didAllowOnlyDehydratedResizeScaleColorPacingFacts
        this.didAvoidPlatformResourceCreation = didAvoidPlatformResourceCreation
        this.didAvoidNativeHandle = didAvoidNativeHandle
        this.didAvoidRawPointer = didAvoidRawPointer
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// Drawable acquisition policy 只描述 future drawable acquisition 的 value policy；
// 它不请求 drawable，不持有 drawable，也不创建任何平台资源。
struct CjguiInternalRendererDrawableAcquisitionPolicy {
    let confinementPolicy: CjguiInternalRendererResourceConfinementPolicy
    let didPrepareRendererDrawableAcquisitionPolicy: Bool
    let shouldDeferRendererDrawableAcquisitionPolicy: Bool
    let shouldReportRendererDrawableAcquisitionPolicyBlocked: Bool
    let didPreserveRendererResourceConfinementPolicy: Bool
    let didDefineFutureDrawableAcquisitionPolicy: Bool
    let didKeepDrawableAcquisitionPolicyValueOnly: Bool
    let didKeepDrawableAcquisitionLateBound: Bool
    let didDescribeNoDrawFailureValueFacts: Bool
    let didAvoidDrawableAcquisition: Bool
    let didAvoidDrawableOwnership: Bool
    let didAvoidPlatformResourceCreation: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool

    init(
        confinementPolicy: CjguiInternalRendererResourceConfinementPolicy,
        didPrepareRendererDrawableAcquisitionPolicy: Bool,
        shouldDeferRendererDrawableAcquisitionPolicy: Bool,
        shouldReportRendererDrawableAcquisitionPolicyBlocked: Bool,
        didPreserveRendererResourceConfinementPolicy: Bool,
        didDefineFutureDrawableAcquisitionPolicy: Bool,
        didKeepDrawableAcquisitionPolicyValueOnly: Bool,
        didKeepDrawableAcquisitionLateBound: Bool,
        didDescribeNoDrawFailureValueFacts: Bool,
        didAvoidDrawableAcquisition: Bool,
        didAvoidDrawableOwnership: Bool,
        didAvoidPlatformResourceCreation: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.confinementPolicy = confinementPolicy
        this.didPrepareRendererDrawableAcquisitionPolicy =
            didPrepareRendererDrawableAcquisitionPolicy
        this.shouldDeferRendererDrawableAcquisitionPolicy =
            shouldDeferRendererDrawableAcquisitionPolicy
        this.shouldReportRendererDrawableAcquisitionPolicyBlocked =
            shouldReportRendererDrawableAcquisitionPolicyBlocked
        this.didPreserveRendererResourceConfinementPolicy =
            didPreserveRendererResourceConfinementPolicy
        this.didDefineFutureDrawableAcquisitionPolicy = didDefineFutureDrawableAcquisitionPolicy
        this.didKeepDrawableAcquisitionPolicyValueOnly = didKeepDrawableAcquisitionPolicyValueOnly
        this.didKeepDrawableAcquisitionLateBound = didKeepDrawableAcquisitionLateBound
        this.didDescribeNoDrawFailureValueFacts = didDescribeNoDrawFailureValueFacts
        this.didAvoidDrawableAcquisition = didAvoidDrawableAcquisition
        this.didAvoidDrawableOwnership = didAvoidDrawableOwnership
        this.didAvoidPlatformResourceCreation = didAvoidPlatformResourceCreation
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// Command queue ownership policy 只表达 future queue ownership policy；
// 它不创建 queue，不提交 work，也不代表平台 owner 已存在。
struct CjguiInternalRendererCommandQueueOwnershipPolicy {
    let drawableAcquisitionPolicy: CjguiInternalRendererDrawableAcquisitionPolicy
    let didPrepareRendererCommandQueueOwnershipPolicy: Bool
    let shouldDeferRendererCommandQueueOwnershipPolicy: Bool
    let shouldReportRendererCommandQueueOwnershipPolicyBlocked: Bool
    let didPreserveRendererDrawableAcquisitionPolicy: Bool
    let didDefineFutureCommandQueueOwnershipPolicy: Bool
    let didKeepCommandQueueOwnershipPolicyValueOnly: Bool
    let didKeepQueueOwnershipInFutureBackendOwner: Bool
    let didAvoidCommandQueueCreation: Bool
    let didAvoidSubmissionObjectCreation: Bool
    let didAvoidPlatformResourceCreation: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        drawableAcquisitionPolicy: CjguiInternalRendererDrawableAcquisitionPolicy,
        didPrepareRendererCommandQueueOwnershipPolicy: Bool,
        shouldDeferRendererCommandQueueOwnershipPolicy: Bool,
        shouldReportRendererCommandQueueOwnershipPolicyBlocked: Bool,
        didPreserveRendererDrawableAcquisitionPolicy: Bool,
        didDefineFutureCommandQueueOwnershipPolicy: Bool,
        didKeepCommandQueueOwnershipPolicyValueOnly: Bool,
        didKeepQueueOwnershipInFutureBackendOwner: Bool,
        didAvoidCommandQueueCreation: Bool,
        didAvoidSubmissionObjectCreation: Bool,
        didAvoidPlatformResourceCreation: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.drawableAcquisitionPolicy = drawableAcquisitionPolicy
        this.didPrepareRendererCommandQueueOwnershipPolicy =
            didPrepareRendererCommandQueueOwnershipPolicy
        this.shouldDeferRendererCommandQueueOwnershipPolicy =
            shouldDeferRendererCommandQueueOwnershipPolicy
        this.shouldReportRendererCommandQueueOwnershipPolicyBlocked =
            shouldReportRendererCommandQueueOwnershipPolicyBlocked
        this.didPreserveRendererDrawableAcquisitionPolicy =
            didPreserveRendererDrawableAcquisitionPolicy
        this.didDefineFutureCommandQueueOwnershipPolicy = didDefineFutureCommandQueueOwnershipPolicy
        this.didKeepCommandQueueOwnershipPolicyValueOnly =
            didKeepCommandQueueOwnershipPolicyValueOnly
        this.didKeepQueueOwnershipInFutureBackendOwner = didKeepQueueOwnershipInFutureBackendOwner
        this.didAvoidCommandQueueCreation = didAvoidCommandQueueCreation
        this.didAvoidSubmissionObjectCreation = didAvoidSubmissionObjectCreation
        this.didAvoidPlatformResourceCreation = didAvoidPlatformResourceCreation
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// No-platform-resource readiness 是本 owner 的 endpoint；
// readiness 只表示 future platform owner boundary 可以继续评估，不代表平台或绘制许可。
struct CjguiInternalRendererNoPlatformResourceReadiness {
    let commandQueueOwnershipPolicy: CjguiInternalRendererCommandQueueOwnershipPolicy
    let isRendererNoPlatformResourceReady: Bool
    let canFutureRendererPlatformResourceBoundaryEvaluate: Bool
    let shouldDeferRendererNoPlatformResourceReadiness: Bool
    let shouldReportRendererNoPlatformResourceReadinessBlocked: Bool
    let didRecordRendererNoPlatformResourceReadiness: Bool
    let didPreserveRendererCommandQueueOwnershipPolicy: Bool
    let didKeepNoPlatformResourceReadinessValueOnly: Bool
    let didConfirmNoPlatformResourceCreated: Bool
    let didConfirmNoPlatformLayerOrDeviceObject: Bool
    let didConfirmNoQueueDrawableOrSubmissionObject: Bool
    let didConfirmNoRenderPassOrEncoderObject: Bool
    let didConfirmNoNativeHandle: Bool
    let didConfirmNoRawPointer: Bool
    let didAvoidRendererBackendPermission: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didStayFullRebuildOnly: Bool

    init(
        commandQueueOwnershipPolicy: CjguiInternalRendererCommandQueueOwnershipPolicy,
        isRendererNoPlatformResourceReady: Bool,
        canFutureRendererPlatformResourceBoundaryEvaluate: Bool,
        shouldDeferRendererNoPlatformResourceReadiness: Bool,
        shouldReportRendererNoPlatformResourceReadinessBlocked: Bool,
        didRecordRendererNoPlatformResourceReadiness: Bool,
        didPreserveRendererCommandQueueOwnershipPolicy: Bool,
        didKeepNoPlatformResourceReadinessValueOnly: Bool,
        didConfirmNoPlatformResourceCreated: Bool,
        didConfirmNoPlatformLayerOrDeviceObject: Bool,
        didConfirmNoQueueDrawableOrSubmissionObject: Bool,
        didConfirmNoRenderPassOrEncoderObject: Bool,
        didConfirmNoNativeHandle: Bool,
        didConfirmNoRawPointer: Bool,
        didAvoidRendererBackendPermission: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.commandQueueOwnershipPolicy = commandQueueOwnershipPolicy
        this.isRendererNoPlatformResourceReady = isRendererNoPlatformResourceReady
        this.canFutureRendererPlatformResourceBoundaryEvaluate =
            canFutureRendererPlatformResourceBoundaryEvaluate
        this.shouldDeferRendererNoPlatformResourceReadiness =
            shouldDeferRendererNoPlatformResourceReadiness
        this.shouldReportRendererNoPlatformResourceReadinessBlocked =
            shouldReportRendererNoPlatformResourceReadinessBlocked
        this.didRecordRendererNoPlatformResourceReadiness = didRecordRendererNoPlatformResourceReadiness
        this.didPreserveRendererCommandQueueOwnershipPolicy =
            didPreserveRendererCommandQueueOwnershipPolicy
        this.didKeepNoPlatformResourceReadinessValueOnly =
            didKeepNoPlatformResourceReadinessValueOnly
        this.didConfirmNoPlatformResourceCreated = didConfirmNoPlatformResourceCreated
        this.didConfirmNoPlatformLayerOrDeviceObject = didConfirmNoPlatformLayerOrDeviceObject
        this.didConfirmNoQueueDrawableOrSubmissionObject =
            didConfirmNoQueueDrawableOrSubmissionObject
        this.didConfirmNoRenderPassOrEncoderObject = didConfirmNoRenderPassOrEncoderObject
        this.didConfirmNoNativeHandle = didConfirmNoNativeHandle
        this.didConfirmNoRawPointer = didConfirmNoRawPointer
        this.didAvoidRendererBackendPermission = didAvoidRendererBackendPermission
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererPlatformResourceOwnerIntent(
    orderingHardeningResult: CjguiInternalRendererPacketOrderingHardeningResult
): CjguiInternalRendererPlatformResourceOwnerIntent {
    let orderingReady = orderingHardeningResult.isRendererPacketOrderingHardeningAccepted &&
        orderingHardeningResult.canFutureRendererBoundaryUseHardenedOrderingFacts &&
        orderingHardeningResult.didSealRendererPacketOrderingHardeningResult &&
        orderingHardeningResult.didPreserveRendererNoSortNoMergeGate &&
        orderingHardeningResult.didKeepOrderingHardeningResultValueOnly &&
        orderingHardeningResult.didAvoidPacketMutation &&
        orderingHardeningResult.didAvoidRendererStateWrite &&
        orderingHardeningResult.didAvoidDrawingPermission &&
        orderingHardeningResult.didStayFullRebuildOnly &&
        orderingHardeningResult.shouldDeferRendererPacketOrderingHardeningResult == false &&
        orderingHardeningResult.shouldReportRendererPacketOrderingHardeningResultBlocked == false
    let intentDeferred = orderingHardeningResult.isRendererPacketOrderingHardeningAccepted == false &&
        orderingHardeningResult.canFutureRendererBoundaryUseHardenedOrderingFacts == false &&
        orderingHardeningResult.shouldDeferRendererPacketOrderingHardeningResult &&
        orderingHardeningResult.shouldReportRendererPacketOrderingHardeningResultBlocked == false
    let intentInconsistent = (
        orderingHardeningResult.isRendererPacketOrderingHardeningAccepted &&
            (
                orderingHardeningResult.canFutureRendererBoundaryUseHardenedOrderingFacts == false ||
                orderingHardeningResult.didSealRendererPacketOrderingHardeningResult == false ||
                orderingHardeningResult.didPreserveRendererNoSortNoMergeGate == false ||
                orderingHardeningResult.didKeepOrderingHardeningResultValueOnly == false ||
                orderingHardeningResult.didAvoidPacketMutation == false ||
                orderingHardeningResult.didAvoidRendererStateWrite == false ||
                orderingHardeningResult.didAvoidDrawingPermission == false ||
                orderingHardeningResult.didStayFullRebuildOnly == false ||
                orderingHardeningResult.shouldDeferRendererPacketOrderingHardeningResult ||
                orderingHardeningResult.shouldReportRendererPacketOrderingHardeningResultBlocked
            )
        ) ||
        (orderingHardeningResult.canFutureRendererBoundaryUseHardenedOrderingFacts &&
            orderingHardeningResult.isRendererPacketOrderingHardeningAccepted == false) ||
        (orderingHardeningResult.shouldDeferRendererPacketOrderingHardeningResult &&
            orderingHardeningResult.shouldReportRendererPacketOrderingHardeningResultBlocked)

    // fail-closed：不能把 ordering hardening result 薄包成 platform owner intent。
    if (
        orderingHardeningResult.shouldReportRendererPacketOrderingHardeningResultBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererPlatformResourceOwnerIntent(
            orderingHardeningResult,
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
            true
        )
    }

    if (orderingReady) {
        return CjguiInternalRendererPlatformResourceOwnerIntent(
            orderingHardeningResult,
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

    if (intentDeferred) {
        return CjguiInternalRendererPlatformResourceOwnerIntent(
            orderingHardeningResult,
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
            true
        )
    }

    return CjguiInternalRendererPlatformResourceOwnerIntent(
        orderingHardeningResult,
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
        true
    )
}

func cjguiInternalBuildRendererResourceConfinementPolicy(
    ownerIntent: CjguiInternalRendererPlatformResourceOwnerIntent
): CjguiInternalRendererResourceConfinementPolicy {
    let intentReady = ownerIntent.didPrepareRendererPlatformResourceOwnerIntent &&
        ownerIntent.didPreserveRendererPacketOrderingHardeningResult &&
        ownerIntent.didDefineFuturePlatformOwnerIntent &&
        ownerIntent.didKeepPlatformOwnerIntentValueOnly &&
        ownerIntent.didAvoidPlatformResourceCreation &&
        ownerIntent.didAvoidRendererBackendPermission &&
        ownerIntent.didAvoidRendererStateWrite &&
        ownerIntent.didAvoidRenderingPermission &&
        ownerIntent.didAvoidReceiptRecordPublication &&
        ownerIntent.didStayFullRebuildOnly &&
        ownerIntent.shouldDeferRendererPlatformResourceOwnerIntent == false &&
        ownerIntent.shouldReportRendererPlatformResourceOwnerIntentBlocked == false
    let policyDeferred = ownerIntent.didPrepareRendererPlatformResourceOwnerIntent == false &&
        ownerIntent.shouldDeferRendererPlatformResourceOwnerIntent &&
        ownerIntent.shouldReportRendererPlatformResourceOwnerIntentBlocked == false
    let policyInconsistent = (
        ownerIntent.didPrepareRendererPlatformResourceOwnerIntent &&
            (
                ownerIntent.didPreserveRendererPacketOrderingHardeningResult == false ||
                ownerIntent.didDefineFuturePlatformOwnerIntent == false ||
                ownerIntent.didKeepPlatformOwnerIntentValueOnly == false ||
                ownerIntent.didAvoidPlatformResourceCreation == false ||
                ownerIntent.didAvoidRendererBackendPermission == false ||
                ownerIntent.didAvoidRendererStateWrite == false ||
                ownerIntent.didAvoidRenderingPermission == false ||
                ownerIntent.didAvoidReceiptRecordPublication == false ||
                ownerIntent.didStayFullRebuildOnly == false ||
                ownerIntent.shouldDeferRendererPlatformResourceOwnerIntent ||
                ownerIntent.shouldReportRendererPlatformResourceOwnerIntentBlocked
            )
        ) ||
        (ownerIntent.didPreserveRendererPacketOrderingHardeningResult &&
            ownerIntent.didPrepareRendererPlatformResourceOwnerIntent == false) ||
        (ownerIntent.shouldDeferRendererPlatformResourceOwnerIntent &&
            ownerIntent.shouldReportRendererPlatformResourceOwnerIntentBlocked)

    // confinement policy 不一致时必须 fail-closed，不能让平台资源进入 core packet。
    if (
        ownerIntent.shouldReportRendererPlatformResourceOwnerIntentBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererResourceConfinementPolicy(
            ownerIntent,
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
            true
        )
    }

    if (intentReady) {
        return CjguiInternalRendererResourceConfinementPolicy(
            ownerIntent,
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
        return CjguiInternalRendererResourceConfinementPolicy(
            ownerIntent,
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
            true
        )
    }

    return CjguiInternalRendererResourceConfinementPolicy(
        ownerIntent,
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
        true
    )
}

func cjguiInternalBuildRendererDrawableAcquisitionPolicy(
    confinementPolicy: CjguiInternalRendererResourceConfinementPolicy
): CjguiInternalRendererDrawableAcquisitionPolicy {
    let confinementReady = confinementPolicy.didPrepareRendererResourceConfinementPolicy &&
        confinementPolicy.didPreserveRendererPlatformResourceOwnerIntent &&
        confinementPolicy.didDefineFutureResourceConfinement &&
        confinementPolicy.didKeepConfinementPolicyValueOnly &&
        confinementPolicy.didKeepFutureResourcesInBackendOwner &&
        confinementPolicy.didKeepPlatformObjectsOutOfCorePacket &&
        confinementPolicy.didAllowOnlyDehydratedResizeScaleColorPacingFacts &&
        confinementPolicy.didAvoidPlatformResourceCreation &&
        confinementPolicy.didAvoidNativeHandle &&
        confinementPolicy.didAvoidRawPointer &&
        confinementPolicy.didAvoidRendererStateWrite &&
        confinementPolicy.didAvoidRenderingPermission &&
        confinementPolicy.shouldDeferRendererResourceConfinementPolicy == false &&
        confinementPolicy.shouldReportRendererResourceConfinementPolicyBlocked == false
    let acquisitionDeferred = confinementPolicy.didPrepareRendererResourceConfinementPolicy == false &&
        confinementPolicy.shouldDeferRendererResourceConfinementPolicy &&
        confinementPolicy.shouldReportRendererResourceConfinementPolicyBlocked == false
    let acquisitionInconsistent = (
        confinementPolicy.didPrepareRendererResourceConfinementPolicy &&
            (
                confinementPolicy.didPreserveRendererPlatformResourceOwnerIntent == false ||
                confinementPolicy.didDefineFutureResourceConfinement == false ||
                confinementPolicy.didKeepConfinementPolicyValueOnly == false ||
                confinementPolicy.didKeepFutureResourcesInBackendOwner == false ||
                confinementPolicy.didKeepPlatformObjectsOutOfCorePacket == false ||
                confinementPolicy.didAllowOnlyDehydratedResizeScaleColorPacingFacts == false ||
                confinementPolicy.didAvoidPlatformResourceCreation == false ||
                confinementPolicy.didAvoidNativeHandle == false ||
                confinementPolicy.didAvoidRawPointer == false ||
                confinementPolicy.didAvoidRendererStateWrite == false ||
                confinementPolicy.didAvoidRenderingPermission == false ||
                confinementPolicy.shouldDeferRendererResourceConfinementPolicy ||
                confinementPolicy.shouldReportRendererResourceConfinementPolicyBlocked
            )
        ) ||
        (confinementPolicy.didPreserveRendererPlatformResourceOwnerIntent &&
            confinementPolicy.didPrepareRendererResourceConfinementPolicy == false) ||
        (confinementPolicy.shouldDeferRendererResourceConfinementPolicy &&
            confinementPolicy.shouldReportRendererResourceConfinementPolicyBlocked)

    // drawable acquisition policy 只描述 future policy；这里不请求或持有 drawable。
    if (
        confinementPolicy.shouldReportRendererResourceConfinementPolicyBlocked ||
        acquisitionInconsistent
    ) {
        return CjguiInternalRendererDrawableAcquisitionPolicy(
            confinementPolicy,
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
            true
        )
    }

    if (confinementReady) {
        return CjguiInternalRendererDrawableAcquisitionPolicy(
            confinementPolicy,
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

    if (acquisitionDeferred) {
        return CjguiInternalRendererDrawableAcquisitionPolicy(
            confinementPolicy,
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
            true
        )
    }

    return CjguiInternalRendererDrawableAcquisitionPolicy(
        confinementPolicy,
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
        true
    )
}

func cjguiInternalBuildRendererCommandQueueOwnershipPolicy(
    drawableAcquisitionPolicy: CjguiInternalRendererDrawableAcquisitionPolicy
): CjguiInternalRendererCommandQueueOwnershipPolicy {
    let acquisitionReady = drawableAcquisitionPolicy.didPrepareRendererDrawableAcquisitionPolicy &&
        drawableAcquisitionPolicy.didPreserveRendererResourceConfinementPolicy &&
        drawableAcquisitionPolicy.didDefineFutureDrawableAcquisitionPolicy &&
        drawableAcquisitionPolicy.didKeepDrawableAcquisitionPolicyValueOnly &&
        drawableAcquisitionPolicy.didKeepDrawableAcquisitionLateBound &&
        drawableAcquisitionPolicy.didDescribeNoDrawFailureValueFacts &&
        drawableAcquisitionPolicy.didAvoidDrawableAcquisition &&
        drawableAcquisitionPolicy.didAvoidDrawableOwnership &&
        drawableAcquisitionPolicy.didAvoidPlatformResourceCreation &&
        drawableAcquisitionPolicy.didAvoidRendererStateWrite &&
        drawableAcquisitionPolicy.didAvoidRenderingPermission &&
        drawableAcquisitionPolicy.shouldDeferRendererDrawableAcquisitionPolicy == false &&
        drawableAcquisitionPolicy.shouldReportRendererDrawableAcquisitionPolicyBlocked == false
    let ownershipDeferred = drawableAcquisitionPolicy.didPrepareRendererDrawableAcquisitionPolicy == false &&
        drawableAcquisitionPolicy.shouldDeferRendererDrawableAcquisitionPolicy &&
        drawableAcquisitionPolicy.shouldReportRendererDrawableAcquisitionPolicyBlocked == false
    let ownershipInconsistent = (
        drawableAcquisitionPolicy.didPrepareRendererDrawableAcquisitionPolicy &&
            (
                drawableAcquisitionPolicy.didPreserveRendererResourceConfinementPolicy == false ||
                drawableAcquisitionPolicy.didDefineFutureDrawableAcquisitionPolicy == false ||
                drawableAcquisitionPolicy.didKeepDrawableAcquisitionPolicyValueOnly == false ||
                drawableAcquisitionPolicy.didKeepDrawableAcquisitionLateBound == false ||
                drawableAcquisitionPolicy.didDescribeNoDrawFailureValueFacts == false ||
                drawableAcquisitionPolicy.didAvoidDrawableAcquisition == false ||
                drawableAcquisitionPolicy.didAvoidDrawableOwnership == false ||
                drawableAcquisitionPolicy.didAvoidPlatformResourceCreation == false ||
                drawableAcquisitionPolicy.didAvoidRendererStateWrite == false ||
                drawableAcquisitionPolicy.didAvoidRenderingPermission == false ||
                drawableAcquisitionPolicy.shouldDeferRendererDrawableAcquisitionPolicy ||
                drawableAcquisitionPolicy.shouldReportRendererDrawableAcquisitionPolicyBlocked
            )
        ) ||
        (drawableAcquisitionPolicy.didPreserveRendererResourceConfinementPolicy &&
            drawableAcquisitionPolicy.didPrepareRendererDrawableAcquisitionPolicy == false) ||
        (drawableAcquisitionPolicy.shouldDeferRendererDrawableAcquisitionPolicy &&
            drawableAcquisitionPolicy.shouldReportRendererDrawableAcquisitionPolicyBlocked)

    // command queue ownership policy 只表达 future ownership；这里不创建 queue。
    if (
        drawableAcquisitionPolicy.shouldReportRendererDrawableAcquisitionPolicyBlocked ||
        ownershipInconsistent
    ) {
        return CjguiInternalRendererCommandQueueOwnershipPolicy(
            drawableAcquisitionPolicy,
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
            true
        )
    }

    if (acquisitionReady) {
        return CjguiInternalRendererCommandQueueOwnershipPolicy(
            drawableAcquisitionPolicy,
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

    if (ownershipDeferred) {
        return CjguiInternalRendererCommandQueueOwnershipPolicy(
            drawableAcquisitionPolicy,
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
            true
        )
    }

    return CjguiInternalRendererCommandQueueOwnershipPolicy(
        drawableAcquisitionPolicy,
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
        true
    )
}

func cjguiInternalBuildRendererNoPlatformResourceReadiness(
    commandQueueOwnershipPolicy: CjguiInternalRendererCommandQueueOwnershipPolicy
): CjguiInternalRendererNoPlatformResourceReadiness {
    let ownershipReady = commandQueueOwnershipPolicy.didPrepareRendererCommandQueueOwnershipPolicy &&
        commandQueueOwnershipPolicy.didPreserveRendererDrawableAcquisitionPolicy &&
        commandQueueOwnershipPolicy.didDefineFutureCommandQueueOwnershipPolicy &&
        commandQueueOwnershipPolicy.didKeepCommandQueueOwnershipPolicyValueOnly &&
        commandQueueOwnershipPolicy.didKeepQueueOwnershipInFutureBackendOwner &&
        commandQueueOwnershipPolicy.didAvoidCommandQueueCreation &&
        commandQueueOwnershipPolicy.didAvoidSubmissionObjectCreation &&
        commandQueueOwnershipPolicy.didAvoidPlatformResourceCreation &&
        commandQueueOwnershipPolicy.didAvoidRendererStateWrite &&
        commandQueueOwnershipPolicy.didAvoidRenderingPermission &&
        commandQueueOwnershipPolicy.didStayFullRebuildOnly &&
        commandQueueOwnershipPolicy.shouldDeferRendererCommandQueueOwnershipPolicy == false &&
        commandQueueOwnershipPolicy.shouldReportRendererCommandQueueOwnershipPolicyBlocked == false
    let readinessDeferred =
        commandQueueOwnershipPolicy.didPrepareRendererCommandQueueOwnershipPolicy == false &&
        commandQueueOwnershipPolicy.shouldDeferRendererCommandQueueOwnershipPolicy &&
        commandQueueOwnershipPolicy.shouldReportRendererCommandQueueOwnershipPolicyBlocked == false
    let readinessInconsistent = (
        commandQueueOwnershipPolicy.didPrepareRendererCommandQueueOwnershipPolicy &&
            (
                commandQueueOwnershipPolicy.didPreserveRendererDrawableAcquisitionPolicy == false ||
                commandQueueOwnershipPolicy.didDefineFutureCommandQueueOwnershipPolicy == false ||
                commandQueueOwnershipPolicy.didKeepCommandQueueOwnershipPolicyValueOnly == false ||
                commandQueueOwnershipPolicy.didKeepQueueOwnershipInFutureBackendOwner == false ||
                commandQueueOwnershipPolicy.didAvoidCommandQueueCreation == false ||
                commandQueueOwnershipPolicy.didAvoidSubmissionObjectCreation == false ||
                commandQueueOwnershipPolicy.didAvoidPlatformResourceCreation == false ||
                commandQueueOwnershipPolicy.didAvoidRendererStateWrite == false ||
                commandQueueOwnershipPolicy.didAvoidRenderingPermission == false ||
                commandQueueOwnershipPolicy.didStayFullRebuildOnly == false ||
                commandQueueOwnershipPolicy.shouldDeferRendererCommandQueueOwnershipPolicy ||
                commandQueueOwnershipPolicy.shouldReportRendererCommandQueueOwnershipPolicyBlocked
            )
        ) ||
        (commandQueueOwnershipPolicy.didPreserveRendererDrawableAcquisitionPolicy &&
            commandQueueOwnershipPolicy.didPrepareRendererCommandQueueOwnershipPolicy == false) ||
        (commandQueueOwnershipPolicy.shouldDeferRendererCommandQueueOwnershipPolicy &&
            commandQueueOwnershipPolicy.shouldReportRendererCommandQueueOwnershipPolicyBlocked)

    // no-platform-resource readiness 是 endpoint；它不授予平台资源或绘制许可。
    if (
        commandQueueOwnershipPolicy.shouldReportRendererCommandQueueOwnershipPolicyBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoPlatformResourceReadiness(
            commandQueueOwnershipPolicy,
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

    if (ownershipReady) {
        return CjguiInternalRendererNoPlatformResourceReadiness(
            commandQueueOwnershipPolicy,
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
        return CjguiInternalRendererNoPlatformResourceReadiness(
            commandQueueOwnershipPolicy,
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

    return CjguiInternalRendererNoPlatformResourceReadiness(
        commandQueueOwnershipPolicy,
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

func cjguiInternalExecuteDefaultRendererPlatformResourceOwnerDraft(
): CjguiInternalRendererNoPlatformResourceReadiness {
    // 默认 draft 只串联 ordering hardening -> platform resource owner value facts；
    // 它不创建平台资源、不接平台实现、不触发绘制。
    let orderingHardeningResult = cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()
    let ownerIntent = cjguiInternalBuildRendererPlatformResourceOwnerIntent(orderingHardeningResult)
    let confinementPolicy = cjguiInternalBuildRendererResourceConfinementPolicy(ownerIntent)
    let acquisitionPolicy = cjguiInternalBuildRendererDrawableAcquisitionPolicy(confinementPolicy)
    let queuePolicy = cjguiInternalBuildRendererCommandQueueOwnershipPolicy(acquisitionPolicy)
    return cjguiInternalBuildRendererNoPlatformResourceReadiness(queuePolicy)
}
