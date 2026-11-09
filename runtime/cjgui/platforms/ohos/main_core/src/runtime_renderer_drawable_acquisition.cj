package cjgui

// Owner: Renderer drawable acquisition lifecycle value boundary.
// Truth: 只消费 CjguiInternalRendererNoCommandQueueReadiness，表达 future drawable
// lifecycle intent、availability policy、acquisition timing guard、presentation ownership
// policy 与 no-drawable readiness 的内部 value facts。
// Stop-line: 这里不获取或持有 CAMetalLayer / CAMetalDrawable / MTLDrawable / drawable /
// command-buffer / pass / encoder / NativeHandle / RawPointer，不接平台实现，不触发绘制，
// 不写 renderer state。
// Same-shape Boundary Brake: 本 owner 新增 drawable lifecycle / availability / timing /
// presentation ownership vocabulary，不把 no-command-queue readiness 包成 receipt / record /
// emission。

// Drawable lifecycle intent 只表达 future lifecycle intent；
// 它不是 drawable acquisition implementation，也不是 command queue / backend permission。
struct CjguiInternalRendererDrawableLifecycleIntent {
    let noCommandQueueReadiness: CjguiInternalRendererNoCommandQueueReadiness
    let didPrepareRendererDrawableLifecycleIntent: Bool
    let shouldDeferRendererDrawableLifecycleIntent: Bool
    let shouldReportRendererDrawableLifecycleIntentBlocked: Bool
    let didPreserveRendererNoCommandQueueReadiness: Bool
    let didDefineFutureDrawableLifecycleIntent: Bool
    let didDescribeDrawableAvailabilityPhase: Bool
    let didDescribeResizeScaleColorRelation: Bool
    let didKeepDrawableLifecycleIntentValueOnly: Bool
    let didAvoidDrawableAcquisition: Bool
    let didAvoidPlatformObjectReference: Bool
    let didAvoidBackendPermission: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool
    let didAvoidReceiptRecordEmission: Bool

    init(
        noCommandQueueReadiness: CjguiInternalRendererNoCommandQueueReadiness,
        didPrepareRendererDrawableLifecycleIntent: Bool,
        shouldDeferRendererDrawableLifecycleIntent: Bool,
        shouldReportRendererDrawableLifecycleIntentBlocked: Bool,
        didPreserveRendererNoCommandQueueReadiness: Bool,
        didDefineFutureDrawableLifecycleIntent: Bool,
        didDescribeDrawableAvailabilityPhase: Bool,
        didDescribeResizeScaleColorRelation: Bool,
        didKeepDrawableLifecycleIntentValueOnly: Bool,
        didAvoidDrawableAcquisition: Bool,
        didAvoidPlatformObjectReference: Bool,
        didAvoidBackendPermission: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool,
        didAvoidReceiptRecordEmission: Bool
    ) {
        this.noCommandQueueReadiness = noCommandQueueReadiness
        this.didPrepareRendererDrawableLifecycleIntent =
            didPrepareRendererDrawableLifecycleIntent
        this.shouldDeferRendererDrawableLifecycleIntent =
            shouldDeferRendererDrawableLifecycleIntent
        this.shouldReportRendererDrawableLifecycleIntentBlocked =
            shouldReportRendererDrawableLifecycleIntentBlocked
        this.didPreserveRendererNoCommandQueueReadiness =
            didPreserveRendererNoCommandQueueReadiness
        this.didDefineFutureDrawableLifecycleIntent =
            didDefineFutureDrawableLifecycleIntent
        this.didDescribeDrawableAvailabilityPhase = didDescribeDrawableAvailabilityPhase
        this.didDescribeResizeScaleColorRelation = didDescribeResizeScaleColorRelation
        this.didKeepDrawableLifecycleIntentValueOnly =
            didKeepDrawableLifecycleIntentValueOnly
        this.didAvoidDrawableAcquisition = didAvoidDrawableAcquisition
        this.didAvoidPlatformObjectReference = didAvoidPlatformObjectReference
        this.didAvoidBackendPermission = didAvoidBackendPermission
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
        this.didAvoidReceiptRecordEmission = didAvoidReceiptRecordEmission
    }
}

// Drawable availability policy 只表达 future availability / unavailable / failure facts；
// 它不调用或持有 drawable，也不创建平台对象。
struct CjguiInternalRendererDrawableAvailabilityPolicy {
    let lifecycleIntent: CjguiInternalRendererDrawableLifecycleIntent
    let didPrepareRendererDrawableAvailabilityPolicy: Bool
    let shouldDeferRendererDrawableAvailabilityPolicy: Bool
    let shouldReportRendererDrawableAvailabilityPolicyBlocked: Bool
    let didPreserveRendererDrawableLifecycleIntent: Bool
    let didDefineFutureDrawableAvailabilityPolicy: Bool
    let didDescribeDrawableUnavailableFailureFacts: Bool
    let didDescribeNoDrawFallbackFacts: Bool
    let didKeepDrawableAvailabilityPolicyValueOnly: Bool
    let didAvoidDrawableAcquisition: Bool
    let didAvoidDrawableOwnership: Bool
    let didAvoidPlatformObjectReference: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool

    init(
        lifecycleIntent: CjguiInternalRendererDrawableLifecycleIntent,
        didPrepareRendererDrawableAvailabilityPolicy: Bool,
        shouldDeferRendererDrawableAvailabilityPolicy: Bool,
        shouldReportRendererDrawableAvailabilityPolicyBlocked: Bool,
        didPreserveRendererDrawableLifecycleIntent: Bool,
        didDefineFutureDrawableAvailabilityPolicy: Bool,
        didDescribeDrawableUnavailableFailureFacts: Bool,
        didDescribeNoDrawFallbackFacts: Bool,
        didKeepDrawableAvailabilityPolicyValueOnly: Bool,
        didAvoidDrawableAcquisition: Bool,
        didAvoidDrawableOwnership: Bool,
        didAvoidPlatformObjectReference: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.lifecycleIntent = lifecycleIntent
        this.didPrepareRendererDrawableAvailabilityPolicy =
            didPrepareRendererDrawableAvailabilityPolicy
        this.shouldDeferRendererDrawableAvailabilityPolicy =
            shouldDeferRendererDrawableAvailabilityPolicy
        this.shouldReportRendererDrawableAvailabilityPolicyBlocked =
            shouldReportRendererDrawableAvailabilityPolicyBlocked
        this.didPreserveRendererDrawableLifecycleIntent =
            didPreserveRendererDrawableLifecycleIntent
        this.didDefineFutureDrawableAvailabilityPolicy =
            didDefineFutureDrawableAvailabilityPolicy
        this.didDescribeDrawableUnavailableFailureFacts =
            didDescribeDrawableUnavailableFailureFacts
        this.didDescribeNoDrawFallbackFacts = didDescribeNoDrawFallbackFacts
        this.didKeepDrawableAvailabilityPolicyValueOnly =
            didKeepDrawableAvailabilityPolicyValueOnly
        this.didAvoidDrawableAcquisition = didAvoidDrawableAcquisition
        this.didAvoidDrawableOwnership = didAvoidDrawableOwnership
        this.didAvoidPlatformObjectReference = didAvoidPlatformObjectReference
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// Acquisition timing guard 只表达 future timing constraints；
// 它不获取 drawable，不阻塞平台调用，也不调度 frame callback。
struct CjguiInternalRendererDrawableAcquisitionTimingGuard {
    let availabilityPolicy: CjguiInternalRendererDrawableAvailabilityPolicy
    let didPrepareRendererDrawableAcquisitionTimingGuard: Bool
    let shouldDeferRendererDrawableAcquisitionTimingGuard: Bool
    let shouldReportRendererDrawableAcquisitionTimingGuardBlocked: Bool
    let didPreserveRendererDrawableAvailabilityPolicy: Bool
    let didDefineFutureDrawableAcquisitionTimingGuard: Bool
    let didDescribeLateBoundAcquisitionTiming: Bool
    let didDescribeFramePacingRelation: Bool
    let didDescribeResizeScaleColorTimingRelation: Bool
    let didKeepDrawableAcquisitionTimingGuardValueOnly: Bool
    let didAvoidDrawableAcquisition: Bool
    let didAvoidBlockingPlatformCall: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool

    init(
        availabilityPolicy: CjguiInternalRendererDrawableAvailabilityPolicy,
        didPrepareRendererDrawableAcquisitionTimingGuard: Bool,
        shouldDeferRendererDrawableAcquisitionTimingGuard: Bool,
        shouldReportRendererDrawableAcquisitionTimingGuardBlocked: Bool,
        didPreserveRendererDrawableAvailabilityPolicy: Bool,
        didDefineFutureDrawableAcquisitionTimingGuard: Bool,
        didDescribeLateBoundAcquisitionTiming: Bool,
        didDescribeFramePacingRelation: Bool,
        didDescribeResizeScaleColorTimingRelation: Bool,
        didKeepDrawableAcquisitionTimingGuardValueOnly: Bool,
        didAvoidDrawableAcquisition: Bool,
        didAvoidBlockingPlatformCall: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.availabilityPolicy = availabilityPolicy
        this.didPrepareRendererDrawableAcquisitionTimingGuard =
            didPrepareRendererDrawableAcquisitionTimingGuard
        this.shouldDeferRendererDrawableAcquisitionTimingGuard =
            shouldDeferRendererDrawableAcquisitionTimingGuard
        this.shouldReportRendererDrawableAcquisitionTimingGuardBlocked =
            shouldReportRendererDrawableAcquisitionTimingGuardBlocked
        this.didPreserveRendererDrawableAvailabilityPolicy =
            didPreserveRendererDrawableAvailabilityPolicy
        this.didDefineFutureDrawableAcquisitionTimingGuard =
            didDefineFutureDrawableAcquisitionTimingGuard
        this.didDescribeLateBoundAcquisitionTiming = didDescribeLateBoundAcquisitionTiming
        this.didDescribeFramePacingRelation = didDescribeFramePacingRelation
        this.didDescribeResizeScaleColorTimingRelation =
            didDescribeResizeScaleColorTimingRelation
        this.didKeepDrawableAcquisitionTimingGuardValueOnly =
            didKeepDrawableAcquisitionTimingGuardValueOnly
        this.didAvoidDrawableAcquisition = didAvoidDrawableAcquisition
        this.didAvoidBlockingPlatformCall = didAvoidBlockingPlatformCall
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// Presentation ownership policy 只表达 future presentation owner facts；
// 它不 present drawable，不创建 submission object，也不接 render-pass lifecycle。
struct CjguiInternalRendererPresentationOwnershipPolicy {
    let timingGuard: CjguiInternalRendererDrawableAcquisitionTimingGuard
    let didPrepareRendererPresentationOwnershipPolicy: Bool
    let shouldDeferRendererPresentationOwnershipPolicy: Bool
    let shouldReportRendererPresentationOwnershipPolicyBlocked: Bool
    let didPreserveRendererDrawableAcquisitionTimingGuard: Bool
    let didDefineFuturePresentationOwnershipPolicy: Bool
    let didDescribePresentationOwnerFact: Bool
    let didDescribeDrawableReleaseExpectationFact: Bool
    let didKeepPresentationOwnershipPolicyValueOnly: Bool
    let didAvoidPresentingDrawable: Bool
    let didAvoidSubmissionObjectCreation: Bool
    let didAvoidPassOrEncoderLifecycle: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool

    init(
        timingGuard: CjguiInternalRendererDrawableAcquisitionTimingGuard,
        didPrepareRendererPresentationOwnershipPolicy: Bool,
        shouldDeferRendererPresentationOwnershipPolicy: Bool,
        shouldReportRendererPresentationOwnershipPolicyBlocked: Bool,
        didPreserveRendererDrawableAcquisitionTimingGuard: Bool,
        didDefineFuturePresentationOwnershipPolicy: Bool,
        didDescribePresentationOwnerFact: Bool,
        didDescribeDrawableReleaseExpectationFact: Bool,
        didKeepPresentationOwnershipPolicyValueOnly: Bool,
        didAvoidPresentingDrawable: Bool,
        didAvoidSubmissionObjectCreation: Bool,
        didAvoidPassOrEncoderLifecycle: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool
    ) {
        this.timingGuard = timingGuard
        this.didPrepareRendererPresentationOwnershipPolicy =
            didPrepareRendererPresentationOwnershipPolicy
        this.shouldDeferRendererPresentationOwnershipPolicy =
            shouldDeferRendererPresentationOwnershipPolicy
        this.shouldReportRendererPresentationOwnershipPolicyBlocked =
            shouldReportRendererPresentationOwnershipPolicyBlocked
        this.didPreserveRendererDrawableAcquisitionTimingGuard =
            didPreserveRendererDrawableAcquisitionTimingGuard
        this.didDefineFuturePresentationOwnershipPolicy =
            didDefineFuturePresentationOwnershipPolicy
        this.didDescribePresentationOwnerFact = didDescribePresentationOwnerFact
        this.didDescribeDrawableReleaseExpectationFact =
            didDescribeDrawableReleaseExpectationFact
        this.didKeepPresentationOwnershipPolicyValueOnly =
            didKeepPresentationOwnershipPolicyValueOnly
        this.didAvoidPresentingDrawable = didAvoidPresentingDrawable
        this.didAvoidSubmissionObjectCreation = didAvoidSubmissionObjectCreation
        this.didAvoidPassOrEncoderLifecycle = didAvoidPassOrEncoderLifecycle
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
    }
}

// No-drawable readiness 是本 owner 的 endpoint；
// readiness 只表示 future drawable acquisition lifecycle boundary 可以继续评估，不代表
// CAMetalLayer / drawable / submission / pass / encoder / NativeHandle / RawPointer 存在。
struct CjguiInternalRendererNoDrawableReadiness {
    let presentationOwnershipPolicy: CjguiInternalRendererPresentationOwnershipPolicy
    let isRendererNoDrawableReady: Bool
    let canFutureRendererDrawableAcquisitionBoundaryEvaluate: Bool
    let shouldDeferRendererNoDrawableReadiness: Bool
    let shouldReportRendererNoDrawableReadinessBlocked: Bool
    let didRecordRendererNoDrawableReadiness: Bool
    let didPreserveRendererPresentationOwnershipPolicy: Bool
    let didKeepNoDrawableReadinessValueOnly: Bool
    let didConfirmNoDrawableAcquired: Bool
    let didConfirmNoLayerOrDrawableObject: Bool
    let didConfirmNoSubmissionPassOrEncoderObject: Bool
    let didConfirmNoNativeResourceToken: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didAvoidBackendPermission: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidRenderingPermission: Bool
    let didAvoidReceiptRecordEmission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        presentationOwnershipPolicy: CjguiInternalRendererPresentationOwnershipPolicy,
        isRendererNoDrawableReady: Bool,
        canFutureRendererDrawableAcquisitionBoundaryEvaluate: Bool,
        shouldDeferRendererNoDrawableReadiness: Bool,
        shouldReportRendererNoDrawableReadinessBlocked: Bool,
        didRecordRendererNoDrawableReadiness: Bool,
        didPreserveRendererPresentationOwnershipPolicy: Bool,
        didKeepNoDrawableReadinessValueOnly: Bool,
        didConfirmNoDrawableAcquired: Bool,
        didConfirmNoLayerOrDrawableObject: Bool,
        didConfirmNoSubmissionPassOrEncoderObject: Bool,
        didConfirmNoNativeResourceToken: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didAvoidBackendPermission: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidRenderingPermission: Bool,
        didAvoidReceiptRecordEmission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.presentationOwnershipPolicy = presentationOwnershipPolicy
        this.isRendererNoDrawableReady = isRendererNoDrawableReady
        this.canFutureRendererDrawableAcquisitionBoundaryEvaluate =
            canFutureRendererDrawableAcquisitionBoundaryEvaluate
        this.shouldDeferRendererNoDrawableReadiness = shouldDeferRendererNoDrawableReadiness
        this.shouldReportRendererNoDrawableReadinessBlocked =
            shouldReportRendererNoDrawableReadinessBlocked
        this.didRecordRendererNoDrawableReadiness = didRecordRendererNoDrawableReadiness
        this.didPreserveRendererPresentationOwnershipPolicy =
            didPreserveRendererPresentationOwnershipPolicy
        this.didKeepNoDrawableReadinessValueOnly = didKeepNoDrawableReadinessValueOnly
        this.didConfirmNoDrawableAcquired = didConfirmNoDrawableAcquired
        this.didConfirmNoLayerOrDrawableObject = didConfirmNoLayerOrDrawableObject
        this.didConfirmNoSubmissionPassOrEncoderObject =
            didConfirmNoSubmissionPassOrEncoderObject
        this.didConfirmNoNativeResourceToken = didConfirmNoNativeResourceToken
        this.didConfirmNoPointerLikeResource = didConfirmNoPointerLikeResource
        this.didAvoidBackendPermission = didAvoidBackendPermission
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidRenderingPermission = didAvoidRenderingPermission
        this.didAvoidReceiptRecordEmission = didAvoidReceiptRecordEmission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererDrawableLifecycleIntent(
    noCommandQueueReadiness: CjguiInternalRendererNoCommandQueueReadiness
): CjguiInternalRendererDrawableLifecycleIntent {
    let noQueueReady = noCommandQueueReadiness.isRendererNoCommandQueueReady &&
        noCommandQueueReadiness.canFutureRendererCommandQueueBoundaryEvaluate &&
        noCommandQueueReadiness.didRecordRendererNoCommandQueueReadiness &&
        noCommandQueueReadiness.didPreserveRendererCommandQueueLifetimePolicy &&
        noCommandQueueReadiness.didKeepNoCommandQueueReadinessValueOnly &&
        noCommandQueueReadiness.didConfirmNoCommandQueueCreated &&
        noCommandQueueReadiness.didConfirmNoDeviceLayerOrDrawableObject &&
        noCommandQueueReadiness.didConfirmNoCommandBufferPassOrEncoderObject &&
        noCommandQueueReadiness.didConfirmNoNativeResourceToken &&
        noCommandQueueReadiness.didConfirmNoPointerLikeResource &&
        noCommandQueueReadiness.didAvoidBackendPermission &&
        noCommandQueueReadiness.didAvoidRendererStateWrite &&
        noCommandQueueReadiness.didAvoidRenderingPermission &&
        noCommandQueueReadiness.didStayFullRebuildOnly &&
        noCommandQueueReadiness.shouldDeferRendererNoCommandQueueReadiness == false &&
        noCommandQueueReadiness.shouldReportRendererNoCommandQueueReadinessBlocked == false
    let intentDeferred = noCommandQueueReadiness.isRendererNoCommandQueueReady == false &&
        noCommandQueueReadiness.canFutureRendererCommandQueueBoundaryEvaluate == false &&
        noCommandQueueReadiness.shouldDeferRendererNoCommandQueueReadiness &&
        noCommandQueueReadiness.shouldReportRendererNoCommandQueueReadinessBlocked == false
    let intentInconsistent = (
        noCommandQueueReadiness.isRendererNoCommandQueueReady &&
            (
                noCommandQueueReadiness.canFutureRendererCommandQueueBoundaryEvaluate == false ||
                noCommandQueueReadiness.didRecordRendererNoCommandQueueReadiness == false ||
                noCommandQueueReadiness.didPreserveRendererCommandQueueLifetimePolicy == false ||
                noCommandQueueReadiness.didKeepNoCommandQueueReadinessValueOnly == false ||
                noCommandQueueReadiness.didConfirmNoCommandQueueCreated == false ||
                noCommandQueueReadiness.didConfirmNoDeviceLayerOrDrawableObject == false ||
                noCommandQueueReadiness.didConfirmNoCommandBufferPassOrEncoderObject == false ||
                noCommandQueueReadiness.didConfirmNoNativeResourceToken == false ||
                noCommandQueueReadiness.didConfirmNoPointerLikeResource == false ||
                noCommandQueueReadiness.didAvoidBackendPermission == false ||
                noCommandQueueReadiness.didAvoidRendererStateWrite == false ||
                noCommandQueueReadiness.didAvoidRenderingPermission == false ||
                noCommandQueueReadiness.didStayFullRebuildOnly == false ||
                noCommandQueueReadiness.shouldDeferRendererNoCommandQueueReadiness ||
                noCommandQueueReadiness.shouldReportRendererNoCommandQueueReadinessBlocked
            )
        ) ||
        (noCommandQueueReadiness.canFutureRendererCommandQueueBoundaryEvaluate &&
            noCommandQueueReadiness.isRendererNoCommandQueueReady == false) ||
        (noCommandQueueReadiness.shouldDeferRendererNoCommandQueueReadiness &&
            noCommandQueueReadiness.shouldReportRendererNoCommandQueueReadinessBlocked)

    // fail-closed：不能把 no-command-queue readiness 薄包成 drawable lifecycle intent。
    if (
        noCommandQueueReadiness.shouldReportRendererNoCommandQueueReadinessBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererDrawableLifecycleIntent(
            noCommandQueueReadiness,
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

    if (noQueueReady) {
        return CjguiInternalRendererDrawableLifecycleIntent(
            noCommandQueueReadiness,
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
        return CjguiInternalRendererDrawableLifecycleIntent(
            noCommandQueueReadiness,
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

    return CjguiInternalRendererDrawableLifecycleIntent(
        noCommandQueueReadiness,
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

func cjguiInternalBuildRendererDrawableAvailabilityPolicy(
    lifecycleIntent: CjguiInternalRendererDrawableLifecycleIntent
): CjguiInternalRendererDrawableAvailabilityPolicy {
    let intentReady = lifecycleIntent.didPrepareRendererDrawableLifecycleIntent &&
        lifecycleIntent.didPreserveRendererNoCommandQueueReadiness &&
        lifecycleIntent.didDefineFutureDrawableLifecycleIntent &&
        lifecycleIntent.didDescribeDrawableAvailabilityPhase &&
        lifecycleIntent.didDescribeResizeScaleColorRelation &&
        lifecycleIntent.didKeepDrawableLifecycleIntentValueOnly &&
        lifecycleIntent.didAvoidDrawableAcquisition &&
        lifecycleIntent.didAvoidPlatformObjectReference &&
        lifecycleIntent.didAvoidBackendPermission &&
        lifecycleIntent.didAvoidRendererStateWrite &&
        lifecycleIntent.didAvoidRenderingPermission &&
        lifecycleIntent.didAvoidReceiptRecordEmission &&
        lifecycleIntent.shouldDeferRendererDrawableLifecycleIntent == false &&
        lifecycleIntent.shouldReportRendererDrawableLifecycleIntentBlocked == false
    let policyDeferred = lifecycleIntent.didPrepareRendererDrawableLifecycleIntent == false &&
        lifecycleIntent.shouldDeferRendererDrawableLifecycleIntent &&
        lifecycleIntent.shouldReportRendererDrawableLifecycleIntentBlocked == false
    let policyInconsistent = (
        lifecycleIntent.didPrepareRendererDrawableLifecycleIntent &&
            (
                lifecycleIntent.didPreserveRendererNoCommandQueueReadiness == false ||
                lifecycleIntent.didDefineFutureDrawableLifecycleIntent == false ||
                lifecycleIntent.didDescribeDrawableAvailabilityPhase == false ||
                lifecycleIntent.didDescribeResizeScaleColorRelation == false ||
                lifecycleIntent.didKeepDrawableLifecycleIntentValueOnly == false ||
                lifecycleIntent.didAvoidDrawableAcquisition == false ||
                lifecycleIntent.didAvoidPlatformObjectReference == false ||
                lifecycleIntent.didAvoidBackendPermission == false ||
                lifecycleIntent.didAvoidRendererStateWrite == false ||
                lifecycleIntent.didAvoidRenderingPermission == false ||
                lifecycleIntent.didAvoidReceiptRecordEmission == false ||
                lifecycleIntent.shouldDeferRendererDrawableLifecycleIntent ||
                lifecycleIntent.shouldReportRendererDrawableLifecycleIntentBlocked
            )
        ) ||
        (lifecycleIntent.didPreserveRendererNoCommandQueueReadiness &&
            lifecycleIntent.didPrepareRendererDrawableLifecycleIntent == false) ||
        (lifecycleIntent.shouldDeferRendererDrawableLifecycleIntent &&
            lifecycleIntent.shouldReportRendererDrawableLifecycleIntentBlocked)

    // availability policy 只描述 future drawable availability / failure，不请求 drawable。
    if (
        lifecycleIntent.shouldReportRendererDrawableLifecycleIntentBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererDrawableAvailabilityPolicy(
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
        return CjguiInternalRendererDrawableAvailabilityPolicy(
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
        return CjguiInternalRendererDrawableAvailabilityPolicy(
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

    return CjguiInternalRendererDrawableAvailabilityPolicy(
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

func cjguiInternalBuildRendererDrawableAcquisitionTimingGuard(
    availabilityPolicy: CjguiInternalRendererDrawableAvailabilityPolicy
): CjguiInternalRendererDrawableAcquisitionTimingGuard {
    let policyReady = availabilityPolicy.didPrepareRendererDrawableAvailabilityPolicy &&
        availabilityPolicy.didPreserveRendererDrawableLifecycleIntent &&
        availabilityPolicy.didDefineFutureDrawableAvailabilityPolicy &&
        availabilityPolicy.didDescribeDrawableUnavailableFailureFacts &&
        availabilityPolicy.didDescribeNoDrawFallbackFacts &&
        availabilityPolicy.didKeepDrawableAvailabilityPolicyValueOnly &&
        availabilityPolicy.didAvoidDrawableAcquisition &&
        availabilityPolicy.didAvoidDrawableOwnership &&
        availabilityPolicy.didAvoidPlatformObjectReference &&
        availabilityPolicy.didAvoidRendererStateWrite &&
        availabilityPolicy.didAvoidRenderingPermission &&
        availabilityPolicy.shouldDeferRendererDrawableAvailabilityPolicy == false &&
        availabilityPolicy.shouldReportRendererDrawableAvailabilityPolicyBlocked == false
    let guardDeferred =
        availabilityPolicy.didPrepareRendererDrawableAvailabilityPolicy == false &&
        availabilityPolicy.shouldDeferRendererDrawableAvailabilityPolicy &&
        availabilityPolicy.shouldReportRendererDrawableAvailabilityPolicyBlocked == false
    let guardInconsistent = (
        availabilityPolicy.didPrepareRendererDrawableAvailabilityPolicy &&
            (
                availabilityPolicy.didPreserveRendererDrawableLifecycleIntent == false ||
                availabilityPolicy.didDefineFutureDrawableAvailabilityPolicy == false ||
                availabilityPolicy.didDescribeDrawableUnavailableFailureFacts == false ||
                availabilityPolicy.didDescribeNoDrawFallbackFacts == false ||
                availabilityPolicy.didKeepDrawableAvailabilityPolicyValueOnly == false ||
                availabilityPolicy.didAvoidDrawableAcquisition == false ||
                availabilityPolicy.didAvoidDrawableOwnership == false ||
                availabilityPolicy.didAvoidPlatformObjectReference == false ||
                availabilityPolicy.didAvoidRendererStateWrite == false ||
                availabilityPolicy.didAvoidRenderingPermission == false ||
                availabilityPolicy.shouldDeferRendererDrawableAvailabilityPolicy ||
                availabilityPolicy.shouldReportRendererDrawableAvailabilityPolicyBlocked
            )
        ) ||
        (availabilityPolicy.didPreserveRendererDrawableLifecycleIntent &&
            availabilityPolicy.didPrepareRendererDrawableAvailabilityPolicy == false) ||
        (availabilityPolicy.shouldDeferRendererDrawableAvailabilityPolicy &&
            availabilityPolicy.shouldReportRendererDrawableAvailabilityPolicyBlocked)

    // timing guard 只表达 future timing constraints；这里不获取 drawable。
    if (
        availabilityPolicy.shouldReportRendererDrawableAvailabilityPolicyBlocked ||
        guardInconsistent
    ) {
        return CjguiInternalRendererDrawableAcquisitionTimingGuard(
            availabilityPolicy,
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
        return CjguiInternalRendererDrawableAcquisitionTimingGuard(
            availabilityPolicy,
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
        return CjguiInternalRendererDrawableAcquisitionTimingGuard(
            availabilityPolicy,
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

    return CjguiInternalRendererDrawableAcquisitionTimingGuard(
        availabilityPolicy,
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

func cjguiInternalBuildRendererPresentationOwnershipPolicy(
    timingGuard: CjguiInternalRendererDrawableAcquisitionTimingGuard
): CjguiInternalRendererPresentationOwnershipPolicy {
    let guardReady = timingGuard.didPrepareRendererDrawableAcquisitionTimingGuard &&
        timingGuard.didPreserveRendererDrawableAvailabilityPolicy &&
        timingGuard.didDefineFutureDrawableAcquisitionTimingGuard &&
        timingGuard.didDescribeLateBoundAcquisitionTiming &&
        timingGuard.didDescribeFramePacingRelation &&
        timingGuard.didDescribeResizeScaleColorTimingRelation &&
        timingGuard.didKeepDrawableAcquisitionTimingGuardValueOnly &&
        timingGuard.didAvoidDrawableAcquisition &&
        timingGuard.didAvoidBlockingPlatformCall &&
        timingGuard.didAvoidRendererStateWrite &&
        timingGuard.didAvoidRenderingPermission &&
        timingGuard.shouldDeferRendererDrawableAcquisitionTimingGuard == false &&
        timingGuard.shouldReportRendererDrawableAcquisitionTimingGuardBlocked == false
    let policyDeferred =
        timingGuard.didPrepareRendererDrawableAcquisitionTimingGuard == false &&
        timingGuard.shouldDeferRendererDrawableAcquisitionTimingGuard &&
        timingGuard.shouldReportRendererDrawableAcquisitionTimingGuardBlocked == false
    let policyInconsistent = (
        timingGuard.didPrepareRendererDrawableAcquisitionTimingGuard &&
            (
                timingGuard.didPreserveRendererDrawableAvailabilityPolicy == false ||
                timingGuard.didDefineFutureDrawableAcquisitionTimingGuard == false ||
                timingGuard.didDescribeLateBoundAcquisitionTiming == false ||
                timingGuard.didDescribeFramePacingRelation == false ||
                timingGuard.didDescribeResizeScaleColorTimingRelation == false ||
                timingGuard.didKeepDrawableAcquisitionTimingGuardValueOnly == false ||
                timingGuard.didAvoidDrawableAcquisition == false ||
                timingGuard.didAvoidBlockingPlatformCall == false ||
                timingGuard.didAvoidRendererStateWrite == false ||
                timingGuard.didAvoidRenderingPermission == false ||
                timingGuard.shouldDeferRendererDrawableAcquisitionTimingGuard ||
                timingGuard.shouldReportRendererDrawableAcquisitionTimingGuardBlocked
            )
        ) ||
        (timingGuard.didPreserveRendererDrawableAvailabilityPolicy &&
            timingGuard.didPrepareRendererDrawableAcquisitionTimingGuard == false) ||
        (timingGuard.shouldDeferRendererDrawableAcquisitionTimingGuard &&
            timingGuard.shouldReportRendererDrawableAcquisitionTimingGuardBlocked)

    // presentation ownership 只表达 owner facts；这里不 present drawable。
    if (
        timingGuard.shouldReportRendererDrawableAcquisitionTimingGuardBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererPresentationOwnershipPolicy(
            timingGuard,
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

    if (guardReady) {
        return CjguiInternalRendererPresentationOwnershipPolicy(
            timingGuard,
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
        return CjguiInternalRendererPresentationOwnershipPolicy(
            timingGuard,
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

    return CjguiInternalRendererPresentationOwnershipPolicy(
        timingGuard,
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

func cjguiInternalBuildRendererNoDrawableReadiness(
    presentationOwnershipPolicy: CjguiInternalRendererPresentationOwnershipPolicy
): CjguiInternalRendererNoDrawableReadiness {
    let policyReady = presentationOwnershipPolicy.didPrepareRendererPresentationOwnershipPolicy &&
        presentationOwnershipPolicy.didPreserveRendererDrawableAcquisitionTimingGuard &&
        presentationOwnershipPolicy.didDefineFuturePresentationOwnershipPolicy &&
        presentationOwnershipPolicy.didDescribePresentationOwnerFact &&
        presentationOwnershipPolicy.didDescribeDrawableReleaseExpectationFact &&
        presentationOwnershipPolicy.didKeepPresentationOwnershipPolicyValueOnly &&
        presentationOwnershipPolicy.didAvoidPresentingDrawable &&
        presentationOwnershipPolicy.didAvoidSubmissionObjectCreation &&
        presentationOwnershipPolicy.didAvoidPassOrEncoderLifecycle &&
        presentationOwnershipPolicy.didAvoidRendererStateWrite &&
        presentationOwnershipPolicy.didAvoidRenderingPermission &&
        presentationOwnershipPolicy.shouldDeferRendererPresentationOwnershipPolicy == false &&
        presentationOwnershipPolicy.shouldReportRendererPresentationOwnershipPolicyBlocked == false
    let readinessDeferred =
        presentationOwnershipPolicy.didPrepareRendererPresentationOwnershipPolicy == false &&
        presentationOwnershipPolicy.shouldDeferRendererPresentationOwnershipPolicy &&
        presentationOwnershipPolicy.shouldReportRendererPresentationOwnershipPolicyBlocked == false
    let readinessInconsistent = (
        presentationOwnershipPolicy.didPrepareRendererPresentationOwnershipPolicy &&
            (
                presentationOwnershipPolicy.didPreserveRendererDrawableAcquisitionTimingGuard == false ||
                presentationOwnershipPolicy.didDefineFuturePresentationOwnershipPolicy == false ||
                presentationOwnershipPolicy.didDescribePresentationOwnerFact == false ||
                presentationOwnershipPolicy.didDescribeDrawableReleaseExpectationFact == false ||
                presentationOwnershipPolicy.didKeepPresentationOwnershipPolicyValueOnly == false ||
                presentationOwnershipPolicy.didAvoidPresentingDrawable == false ||
                presentationOwnershipPolicy.didAvoidSubmissionObjectCreation == false ||
                presentationOwnershipPolicy.didAvoidPassOrEncoderLifecycle == false ||
                presentationOwnershipPolicy.didAvoidRendererStateWrite == false ||
                presentationOwnershipPolicy.didAvoidRenderingPermission == false ||
                presentationOwnershipPolicy.shouldDeferRendererPresentationOwnershipPolicy ||
                presentationOwnershipPolicy.shouldReportRendererPresentationOwnershipPolicyBlocked
            )
        ) ||
        (presentationOwnershipPolicy.didPreserveRendererDrawableAcquisitionTimingGuard &&
            presentationOwnershipPolicy.didPrepareRendererPresentationOwnershipPolicy == false) ||
        (presentationOwnershipPolicy.shouldDeferRendererPresentationOwnershipPolicy &&
            presentationOwnershipPolicy.shouldReportRendererPresentationOwnershipPolicyBlocked)

    // endpoint 只记录 no-drawable value facts；它不授予平台对象或绘制许可。
    if (
        presentationOwnershipPolicy.shouldReportRendererPresentationOwnershipPolicyBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererNoDrawableReadiness(
            presentationOwnershipPolicy,
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

    if (policyReady) {
        return CjguiInternalRendererNoDrawableReadiness(
            presentationOwnershipPolicy,
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
        return CjguiInternalRendererNoDrawableReadiness(
            presentationOwnershipPolicy,
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

    return CjguiInternalRendererNoDrawableReadiness(
        presentationOwnershipPolicy,
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

func cjguiInternalExecuteDefaultRendererDrawableAcquisitionDraft(
): CjguiInternalRendererNoDrawableReadiness {
    // 默认 draft 只串联 no-command-queue -> drawable acquisition lifecycle value facts；
    // 它不获取 drawable、不创建平台对象、不提交或执行任何绘制。
    let noCommandQueueReadiness = cjguiInternalExecuteDefaultRendererCommandQueueLifecycleDraft()
    let lifecycleIntent =
        cjguiInternalBuildRendererDrawableLifecycleIntent(noCommandQueueReadiness)
    let availabilityPolicy =
        cjguiInternalBuildRendererDrawableAvailabilityPolicy(lifecycleIntent)
    let timingGuard =
        cjguiInternalBuildRendererDrawableAcquisitionTimingGuard(availabilityPolicy)
    let presentationPolicy = cjguiInternalBuildRendererPresentationOwnershipPolicy(timingGuard)
    return cjguiInternalBuildRendererNoDrawableReadiness(presentationPolicy)
}
