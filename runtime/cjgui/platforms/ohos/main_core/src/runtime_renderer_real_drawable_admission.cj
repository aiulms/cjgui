// Owner：本文件固定 real drawable implementation admission 的 internal-only owner 边界。
// Truth：唯一 runtime input 是 CjguiInternalRendererNoRealCommandQueueImplementationReadiness，
// canonical endpoint 是 CjguiInternalRendererNoRealDrawableImplementationReadiness。
// Stop-line：只生成 value facts，不获取 drawable，不创建图形资源，不调用外部桥接，
// 不创建提交相关对象，不执行渲染，不写 renderer 状态，不开放外部接口。
// Same-shape Boundary Brake：本文件新增 acquisition / availability / display admission
// 语义，不把上一层 readiness 包成 permission wrapper、receipt、record 或发布凭据。
package cjgui

struct CjguiInternalRendererRealDrawableImplementationIntent {
    let noRealCommandQueueImplementationReadiness:
        CjguiInternalRendererNoRealCommandQueueImplementationReadiness
    let didPrepareRendererRealDrawableImplementationIntent: Bool
    let shouldDeferRendererRealDrawableImplementationIntent: Bool
    let shouldReportRendererRealDrawableImplementationIntentBlocked: Bool
    let didPreserveRendererNoRealCommandQueueImplementationReadiness: Bool
    let didDefineFutureRealDrawableImplementationIntent: Bool
    let didDescribeDrawableAcquisitionAdmissionNeed: Bool
    let didDescribeDrawableAvailabilityAdmissionNeed: Bool
    let didDescribeDrawablePresentationAdmissionNeed: Bool
    let didKeepRealDrawableImplementationIntentValueOnly: Bool
    let didAvoidDrawableReadyPermissionWrapper: Bool
    let didAvoidBackendImplementationWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        noRealCommandQueueImplementationReadiness:
            CjguiInternalRendererNoRealCommandQueueImplementationReadiness,
        didPrepareRendererRealDrawableImplementationIntent: Bool,
        shouldDeferRendererRealDrawableImplementationIntent: Bool,
        shouldReportRendererRealDrawableImplementationIntentBlocked: Bool,
        didPreserveRendererNoRealCommandQueueImplementationReadiness: Bool,
        didDefineFutureRealDrawableImplementationIntent: Bool,
        didDescribeDrawableAcquisitionAdmissionNeed: Bool,
        didDescribeDrawableAvailabilityAdmissionNeed: Bool,
        didDescribeDrawablePresentationAdmissionNeed: Bool,
        didKeepRealDrawableImplementationIntentValueOnly: Bool,
        didAvoidDrawableReadyPermissionWrapper: Bool,
        didAvoidBackendImplementationWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noRealCommandQueueImplementationReadiness =
            noRealCommandQueueImplementationReadiness
        this.didPrepareRendererRealDrawableImplementationIntent =
            didPrepareRendererRealDrawableImplementationIntent
        this.shouldDeferRendererRealDrawableImplementationIntent =
            shouldDeferRendererRealDrawableImplementationIntent
        this.shouldReportRendererRealDrawableImplementationIntentBlocked =
            shouldReportRendererRealDrawableImplementationIntentBlocked
        this.didPreserveRendererNoRealCommandQueueImplementationReadiness =
            didPreserveRendererNoRealCommandQueueImplementationReadiness
        this.didDefineFutureRealDrawableImplementationIntent =
            didDefineFutureRealDrawableImplementationIntent
        this.didDescribeDrawableAcquisitionAdmissionNeed =
            didDescribeDrawableAcquisitionAdmissionNeed
        this.didDescribeDrawableAvailabilityAdmissionNeed =
            didDescribeDrawableAvailabilityAdmissionNeed
        this.didDescribeDrawablePresentationAdmissionNeed =
            didDescribeDrawablePresentationAdmissionNeed
        this.didKeepRealDrawableImplementationIntentValueOnly =
            didKeepRealDrawableImplementationIntentValueOnly
        this.didAvoidDrawableReadyPermissionWrapper =
            didAvoidDrawableReadyPermissionWrapper
        this.didAvoidBackendImplementationWrapper =
            didAvoidBackendImplementationWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealDrawableAcquisitionAdmissionPolicy {
    let implementationIntent:
        CjguiInternalRendererRealDrawableImplementationIntent
    let didPrepareRendererRealDrawableAcquisitionAdmissionPolicy: Bool
    let shouldDeferRendererRealDrawableAcquisitionAdmissionPolicy: Bool
    let shouldReportRendererRealDrawableAcquisitionAdmissionPolicyBlocked: Bool
    let didPreserveRendererRealDrawableImplementationIntent: Bool
    let didDefineFutureDrawableAcquisitionAdmissionPolicy: Bool
    let didDescribeLateDrawableBorrowAdmissionFacts: Bool
    let didDescribeNoLookupCallFacts: Bool
    let didDescribeNoBorrowedDrawableFacts: Bool
    let didConfirmNoDrawableObtained: Bool
    let didConfirmNoDrawableLookupCall: Bool
    let didKeepDrawableAcquisitionAdmissionPolicyValueOnly: Bool
    let didAvoidDrawableLookupPermissionWrapper: Bool
    let didAvoidDrawableReadyPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        implementationIntent:
            CjguiInternalRendererRealDrawableImplementationIntent,
        didPrepareRendererRealDrawableAcquisitionAdmissionPolicy: Bool,
        shouldDeferRendererRealDrawableAcquisitionAdmissionPolicy: Bool,
        shouldReportRendererRealDrawableAcquisitionAdmissionPolicyBlocked: Bool,
        didPreserveRendererRealDrawableImplementationIntent: Bool,
        didDefineFutureDrawableAcquisitionAdmissionPolicy: Bool,
        didDescribeLateDrawableBorrowAdmissionFacts: Bool,
        didDescribeNoLookupCallFacts: Bool,
        didDescribeNoBorrowedDrawableFacts: Bool,
        didConfirmNoDrawableObtained: Bool,
        didConfirmNoDrawableLookupCall: Bool,
        didKeepDrawableAcquisitionAdmissionPolicyValueOnly: Bool,
        didAvoidDrawableLookupPermissionWrapper: Bool,
        didAvoidDrawableReadyPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.implementationIntent = implementationIntent
        this.didPrepareRendererRealDrawableAcquisitionAdmissionPolicy =
            didPrepareRendererRealDrawableAcquisitionAdmissionPolicy
        this.shouldDeferRendererRealDrawableAcquisitionAdmissionPolicy =
            shouldDeferRendererRealDrawableAcquisitionAdmissionPolicy
        this.shouldReportRendererRealDrawableAcquisitionAdmissionPolicyBlocked =
            shouldReportRendererRealDrawableAcquisitionAdmissionPolicyBlocked
        this.didPreserveRendererRealDrawableImplementationIntent =
            didPreserveRendererRealDrawableImplementationIntent
        this.didDefineFutureDrawableAcquisitionAdmissionPolicy =
            didDefineFutureDrawableAcquisitionAdmissionPolicy
        this.didDescribeLateDrawableBorrowAdmissionFacts =
            didDescribeLateDrawableBorrowAdmissionFacts
        this.didDescribeNoLookupCallFacts = didDescribeNoLookupCallFacts
        this.didDescribeNoBorrowedDrawableFacts =
            didDescribeNoBorrowedDrawableFacts
        this.didConfirmNoDrawableObtained = didConfirmNoDrawableObtained
        this.didConfirmNoDrawableLookupCall = didConfirmNoDrawableLookupCall
        this.didKeepDrawableAcquisitionAdmissionPolicyValueOnly =
            didKeepDrawableAcquisitionAdmissionPolicyValueOnly
        this.didAvoidDrawableLookupPermissionWrapper =
            didAvoidDrawableLookupPermissionWrapper
        this.didAvoidDrawableReadyPermissionWrapper =
            didAvoidDrawableReadyPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealDrawableAvailabilityAdmissionGuard {
    let acquisitionAdmissionPolicy:
        CjguiInternalRendererRealDrawableAcquisitionAdmissionPolicy
    let didPrepareRendererRealDrawableAvailabilityAdmissionGuard: Bool
    let shouldDeferRendererRealDrawableAvailabilityAdmissionGuard: Bool
    let shouldReportRendererRealDrawableAvailabilityAdmissionGuardBlocked: Bool
    let didPreserveRendererRealDrawableAcquisitionAdmissionPolicy: Bool
    let didDefineFutureDrawableAvailabilityAdmissionGuard: Bool
    let didDescribeDrawableUnavailableAdmissionFacts: Bool
    let didDescribeDrawablePoolNotQueriedFacts: Bool
    let didDescribeNoDrawableTokenFacts: Bool
    let didConfirmNoDrawablePoolQuery: Bool
    let didConfirmNoDrawableTokenHeld: Bool
    let didKeepDrawableAvailabilityAdmissionGuardValueOnly: Bool
    let didAvoidDrawableReadyPermissionWrapper: Bool
    let didAvoidResourceTokenWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        acquisitionAdmissionPolicy:
            CjguiInternalRendererRealDrawableAcquisitionAdmissionPolicy,
        didPrepareRendererRealDrawableAvailabilityAdmissionGuard: Bool,
        shouldDeferRendererRealDrawableAvailabilityAdmissionGuard: Bool,
        shouldReportRendererRealDrawableAvailabilityAdmissionGuardBlocked: Bool,
        didPreserveRendererRealDrawableAcquisitionAdmissionPolicy: Bool,
        didDefineFutureDrawableAvailabilityAdmissionGuard: Bool,
        didDescribeDrawableUnavailableAdmissionFacts: Bool,
        didDescribeDrawablePoolNotQueriedFacts: Bool,
        didDescribeNoDrawableTokenFacts: Bool,
        didConfirmNoDrawablePoolQuery: Bool,
        didConfirmNoDrawableTokenHeld: Bool,
        didKeepDrawableAvailabilityAdmissionGuardValueOnly: Bool,
        didAvoidDrawableReadyPermissionWrapper: Bool,
        didAvoidResourceTokenWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.acquisitionAdmissionPolicy = acquisitionAdmissionPolicy
        this.didPrepareRendererRealDrawableAvailabilityAdmissionGuard =
            didPrepareRendererRealDrawableAvailabilityAdmissionGuard
        this.shouldDeferRendererRealDrawableAvailabilityAdmissionGuard =
            shouldDeferRendererRealDrawableAvailabilityAdmissionGuard
        this.shouldReportRendererRealDrawableAvailabilityAdmissionGuardBlocked =
            shouldReportRendererRealDrawableAvailabilityAdmissionGuardBlocked
        this.didPreserveRendererRealDrawableAcquisitionAdmissionPolicy =
            didPreserveRendererRealDrawableAcquisitionAdmissionPolicy
        this.didDefineFutureDrawableAvailabilityAdmissionGuard =
            didDefineFutureDrawableAvailabilityAdmissionGuard
        this.didDescribeDrawableUnavailableAdmissionFacts =
            didDescribeDrawableUnavailableAdmissionFacts
        this.didDescribeDrawablePoolNotQueriedFacts =
            didDescribeDrawablePoolNotQueriedFacts
        this.didDescribeNoDrawableTokenFacts =
            didDescribeNoDrawableTokenFacts
        this.didConfirmNoDrawablePoolQuery = didConfirmNoDrawablePoolQuery
        this.didConfirmNoDrawableTokenHeld = didConfirmNoDrawableTokenHeld
        this.didKeepDrawableAvailabilityAdmissionGuardValueOnly =
            didKeepDrawableAvailabilityAdmissionGuardValueOnly
        this.didAvoidDrawableReadyPermissionWrapper =
            didAvoidDrawableReadyPermissionWrapper
        this.didAvoidResourceTokenWrapper = didAvoidResourceTokenWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealDrawablePresentationAdmissionPolicy {
    let availabilityAdmissionGuard:
        CjguiInternalRendererRealDrawableAvailabilityAdmissionGuard
    let didPrepareRendererRealDrawablePresentationAdmissionPolicy: Bool
    let shouldDeferRendererRealDrawablePresentationAdmissionPolicy: Bool
    let shouldReportRendererRealDrawablePresentationAdmissionPolicyBlocked: Bool
    let didPreserveRendererRealDrawableAvailabilityAdmissionGuard: Bool
    let didDefineFutureDrawablePresentationAdmissionPolicy: Bool
    let didDescribeDrawableDisplayOrderingFacts: Bool
    let didDescribeNoCommandWorkFacts: Bool
    let didDescribeNoDrawableDisplayCallFacts: Bool
    let didConfirmNoDrawableDisplayCall: Bool
    let didConfirmNoCommandBufferCreated: Bool
    let didConfirmNoWorkSubmit: Bool
    let didKeepDrawablePresentationAdmissionPolicyValueOnly: Bool
    let didAvoidDrawableDisplayPermissionWrapper: Bool
    let didAvoidWorkSubmitWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        availabilityAdmissionGuard:
            CjguiInternalRendererRealDrawableAvailabilityAdmissionGuard,
        didPrepareRendererRealDrawablePresentationAdmissionPolicy: Bool,
        shouldDeferRendererRealDrawablePresentationAdmissionPolicy: Bool,
        shouldReportRendererRealDrawablePresentationAdmissionPolicyBlocked: Bool,
        didPreserveRendererRealDrawableAvailabilityAdmissionGuard: Bool,
        didDefineFutureDrawablePresentationAdmissionPolicy: Bool,
        didDescribeDrawableDisplayOrderingFacts: Bool,
        didDescribeNoCommandWorkFacts: Bool,
        didDescribeNoDrawableDisplayCallFacts: Bool,
        didConfirmNoDrawableDisplayCall: Bool,
        didConfirmNoCommandBufferCreated: Bool,
        didConfirmNoWorkSubmit: Bool,
        didKeepDrawablePresentationAdmissionPolicyValueOnly: Bool,
        didAvoidDrawableDisplayPermissionWrapper: Bool,
        didAvoidWorkSubmitWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.availabilityAdmissionGuard = availabilityAdmissionGuard
        this.didPrepareRendererRealDrawablePresentationAdmissionPolicy =
            didPrepareRendererRealDrawablePresentationAdmissionPolicy
        this.shouldDeferRendererRealDrawablePresentationAdmissionPolicy =
            shouldDeferRendererRealDrawablePresentationAdmissionPolicy
        this.shouldReportRendererRealDrawablePresentationAdmissionPolicyBlocked =
            shouldReportRendererRealDrawablePresentationAdmissionPolicyBlocked
        this.didPreserveRendererRealDrawableAvailabilityAdmissionGuard =
            didPreserveRendererRealDrawableAvailabilityAdmissionGuard
        this.didDefineFutureDrawablePresentationAdmissionPolicy =
            didDefineFutureDrawablePresentationAdmissionPolicy
        this.didDescribeDrawableDisplayOrderingFacts =
            didDescribeDrawableDisplayOrderingFacts
        this.didDescribeNoCommandWorkFacts = didDescribeNoCommandWorkFacts
        this.didDescribeNoDrawableDisplayCallFacts =
            didDescribeNoDrawableDisplayCallFacts
        this.didConfirmNoDrawableDisplayCall = didConfirmNoDrawableDisplayCall
        this.didConfirmNoCommandBufferCreated =
            didConfirmNoCommandBufferCreated
        this.didConfirmNoWorkSubmit = didConfirmNoWorkSubmit
        this.didKeepDrawablePresentationAdmissionPolicyValueOnly =
            didKeepDrawablePresentationAdmissionPolicyValueOnly
        this.didAvoidDrawableDisplayPermissionWrapper =
            didAvoidDrawableDisplayPermissionWrapper
        this.didAvoidWorkSubmitWrapper = didAvoidWorkSubmitWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoRealDrawableImplementationReadiness {
    let displayAdmissionPolicy:
        CjguiInternalRendererRealDrawablePresentationAdmissionPolicy
    let isRendererNoRealDrawableImplementationReady: Bool
    let canFutureRendererRealDrawableImplementationBoundaryEvaluate: Bool
    let shouldDeferRendererNoRealDrawableImplementationReadiness: Bool
    let shouldReportRendererNoRealDrawableImplementationReadinessBlocked: Bool
    let didSealRendererNoRealDrawableImplementationReadiness: Bool
    let didPreserveRendererRealDrawablePresentationAdmissionPolicy: Bool
    let didKeepNoRealDrawableImplementationReadinessValueOnly: Bool
    let didConfirmNoDrawableObtained: Bool
    let didConfirmNoDrawableLookupCall: Bool
    let didConfirmNoDrawablePoolQuery: Bool
    let didConfirmNoDrawableTokenHeld: Bool
    let didConfirmNoDrawableDisplayCall: Bool
    let didConfirmNoCommandBufferCreated: Bool
    let didConfirmNoWorkSubmit: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoRendererStateMutation: Bool
    let didConfirmNoForeignFunctionDeclaration: Bool
    let didConfirmNoExternalAbiSurface: Bool
    let didConfirmNoBridgeInvocation: Bool
    let didConfirmNoResourceToken: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didAvoidDrawableReadyPermissionWrapper: Bool
    let didAvoidDrawableLookupPermissionWrapper: Bool
    let didAvoidDrawableDisplayPermissionWrapper: Bool
    let didAvoidResourceTokenWrapper: Bool
    let didAvoidExternalAbiPermissionWrapper: Bool
    let didAvoidBackendImplementationWrapper: Bool
    let didAvoidWorkSubmitWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidStateWriteWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        displayAdmissionPolicy:
            CjguiInternalRendererRealDrawablePresentationAdmissionPolicy,
        isRendererNoRealDrawableImplementationReady: Bool,
        canFutureRendererRealDrawableImplementationBoundaryEvaluate: Bool,
        shouldDeferRendererNoRealDrawableImplementationReadiness: Bool,
        shouldReportRendererNoRealDrawableImplementationReadinessBlocked: Bool,
        didSealRendererNoRealDrawableImplementationReadiness: Bool,
        didPreserveRendererRealDrawablePresentationAdmissionPolicy: Bool,
        didKeepNoRealDrawableImplementationReadinessValueOnly: Bool,
        didConfirmNoDrawableObtained: Bool,
        didConfirmNoDrawableLookupCall: Bool,
        didConfirmNoDrawablePoolQuery: Bool,
        didConfirmNoDrawableTokenHeld: Bool,
        didConfirmNoDrawableDisplayCall: Bool,
        didConfirmNoCommandBufferCreated: Bool,
        didConfirmNoWorkSubmit: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoRendererStateMutation: Bool,
        didConfirmNoForeignFunctionDeclaration: Bool,
        didConfirmNoExternalAbiSurface: Bool,
        didConfirmNoBridgeInvocation: Bool,
        didConfirmNoResourceToken: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didAvoidDrawableReadyPermissionWrapper: Bool,
        didAvoidDrawableLookupPermissionWrapper: Bool,
        didAvoidDrawableDisplayPermissionWrapper: Bool,
        didAvoidResourceTokenWrapper: Bool,
        didAvoidExternalAbiPermissionWrapper: Bool,
        didAvoidBackendImplementationWrapper: Bool,
        didAvoidWorkSubmitWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidStateWriteWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.displayAdmissionPolicy = displayAdmissionPolicy
        this.isRendererNoRealDrawableImplementationReady =
            isRendererNoRealDrawableImplementationReady
        this.canFutureRendererRealDrawableImplementationBoundaryEvaluate =
            canFutureRendererRealDrawableImplementationBoundaryEvaluate
        this.shouldDeferRendererNoRealDrawableImplementationReadiness =
            shouldDeferRendererNoRealDrawableImplementationReadiness
        this.shouldReportRendererNoRealDrawableImplementationReadinessBlocked =
            shouldReportRendererNoRealDrawableImplementationReadinessBlocked
        this.didSealRendererNoRealDrawableImplementationReadiness =
            didSealRendererNoRealDrawableImplementationReadiness
        this.didPreserveRendererRealDrawablePresentationAdmissionPolicy =
            didPreserveRendererRealDrawablePresentationAdmissionPolicy
        this.didKeepNoRealDrawableImplementationReadinessValueOnly =
            didKeepNoRealDrawableImplementationReadinessValueOnly
        this.didConfirmNoDrawableObtained = didConfirmNoDrawableObtained
        this.didConfirmNoDrawableLookupCall = didConfirmNoDrawableLookupCall
        this.didConfirmNoDrawablePoolQuery = didConfirmNoDrawablePoolQuery
        this.didConfirmNoDrawableTokenHeld = didConfirmNoDrawableTokenHeld
        this.didConfirmNoDrawableDisplayCall = didConfirmNoDrawableDisplayCall
        this.didConfirmNoCommandBufferCreated =
            didConfirmNoCommandBufferCreated
        this.didConfirmNoWorkSubmit = didConfirmNoWorkSubmit
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoRendererStateMutation =
            didConfirmNoRendererStateMutation
        this.didConfirmNoForeignFunctionDeclaration =
            didConfirmNoForeignFunctionDeclaration
        this.didConfirmNoExternalAbiSurface = didConfirmNoExternalAbiSurface
        this.didConfirmNoBridgeInvocation = didConfirmNoBridgeInvocation
        this.didConfirmNoResourceToken = didConfirmNoResourceToken
        this.didConfirmNoPointerLikeResource =
            didConfirmNoPointerLikeResource
        this.didAvoidDrawableReadyPermissionWrapper =
            didAvoidDrawableReadyPermissionWrapper
        this.didAvoidDrawableLookupPermissionWrapper =
            didAvoidDrawableLookupPermissionWrapper
        this.didAvoidDrawableDisplayPermissionWrapper =
            didAvoidDrawableDisplayPermissionWrapper
        this.didAvoidResourceTokenWrapper = didAvoidResourceTokenWrapper
        this.didAvoidExternalAbiPermissionWrapper =
            didAvoidExternalAbiPermissionWrapper
        this.didAvoidBackendImplementationWrapper =
            didAvoidBackendImplementationWrapper
        this.didAvoidWorkSubmitWrapper = didAvoidWorkSubmitWrapper
        this.didAvoidRenderPermissionWrapper =
            didAvoidRenderPermissionWrapper
        this.didAvoidStateWriteWrapper = didAvoidStateWriteWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererRealDrawableImplementationIntent(
    noRealCommandQueueImplementationReadiness:
        CjguiInternalRendererNoRealCommandQueueImplementationReadiness
): CjguiInternalRendererRealDrawableImplementationIntent {
    let upstreamReady =
        noRealCommandQueueImplementationReadiness
            .isRendererNoRealCommandQueueImplementationReady &&
        noRealCommandQueueImplementationReadiness
            .canFutureRendererRealCommandQueueImplementationBoundaryEvaluate &&
        noRealCommandQueueImplementationReadiness
            .didSealRendererNoRealCommandQueueImplementationReadiness &&
        noRealCommandQueueImplementationReadiness
            .didPreserveRendererRealCommandQueueTeardownFailurePolicy &&
        noRealCommandQueueImplementationReadiness
            .didKeepNoRealCommandQueueImplementationReadinessValueOnly &&
        noRealCommandQueueImplementationReadiness.didConfirmNoQueueCreated &&
        noRealCommandQueueImplementationReadiness.didConfirmNoQueueFactoryCall &&
        noRealCommandQueueImplementationReadiness.didConfirmNoCommandBufferCreated &&
        noRealCommandQueueImplementationReadiness.didConfirmNoDrawableAcquired &&
        noRealCommandQueueImplementationReadiness.didConfirmNoWorkSubmit &&
        noRealCommandQueueImplementationReadiness.didConfirmNoRenderExecution &&
        noRealCommandQueueImplementationReadiness.didConfirmNoRendererStateMutation &&
        noRealCommandQueueImplementationReadiness.didAvoidQueueReadyPermissionWrapper &&
        noRealCommandQueueImplementationReadiness.didAvoidBackendImplementationWrapper &&
        noRealCommandQueueImplementationReadiness.didAvoidThinWrapper &&
        noRealCommandQueueImplementationReadiness
            .shouldDeferRendererNoRealCommandQueueImplementationReadiness == false &&
        noRealCommandQueueImplementationReadiness
            .shouldReportRendererNoRealCommandQueueImplementationReadinessBlocked == false
    let upstreamDeferred =
        noRealCommandQueueImplementationReadiness
            .shouldDeferRendererNoRealCommandQueueImplementationReadiness &&
        noRealCommandQueueImplementationReadiness
            .shouldReportRendererNoRealCommandQueueImplementationReadinessBlocked == false
    let upstreamInconsistent =
        noRealCommandQueueImplementationReadiness
            .shouldReportRendererNoRealCommandQueueImplementationReadinessBlocked ||
        (
            noRealCommandQueueImplementationReadiness
                .canFutureRendererRealCommandQueueImplementationBoundaryEvaluate &&
            noRealCommandQueueImplementationReadiness
                .isRendererNoRealCommandQueueImplementationReady == false
        ) ||
        (
            noRealCommandQueueImplementationReadiness
                .shouldDeferRendererNoRealCommandQueueImplementationReadiness &&
            noRealCommandQueueImplementationReadiness
                .shouldReportRendererNoRealCommandQueueImplementationReadinessBlocked
        )

    if (upstreamInconsistent) {
        return CjguiInternalRendererRealDrawableImplementationIntent(
            noRealCommandQueueImplementationReadiness,
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
        return CjguiInternalRendererRealDrawableImplementationIntent(
            noRealCommandQueueImplementationReadiness,
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

    return CjguiInternalRendererRealDrawableImplementationIntent(
        noRealCommandQueueImplementationReadiness,
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

func cjguiInternalBuildRendererRealDrawableAcquisitionAdmissionPolicy(
    implementationIntent: CjguiInternalRendererRealDrawableImplementationIntent
): CjguiInternalRendererRealDrawableAcquisitionAdmissionPolicy {
    let intentReady =
        implementationIntent.didPrepareRendererRealDrawableImplementationIntent &&
        implementationIntent.didPreserveRendererNoRealCommandQueueImplementationReadiness &&
        implementationIntent.didDefineFutureRealDrawableImplementationIntent &&
        implementationIntent.didDescribeDrawableAcquisitionAdmissionNeed &&
        implementationIntent.didDescribeDrawableAvailabilityAdmissionNeed &&
        implementationIntent.didDescribeDrawablePresentationAdmissionNeed &&
        implementationIntent.didKeepRealDrawableImplementationIntentValueOnly &&
        implementationIntent.didAvoidDrawableReadyPermissionWrapper &&
        implementationIntent.didAvoidBackendImplementationWrapper &&
        implementationIntent.didAvoidReceiptRecordOutput &&
        implementationIntent.didAvoidThinWrapper &&
        implementationIntent.shouldDeferRendererRealDrawableImplementationIntent == false &&
        implementationIntent
            .shouldReportRendererRealDrawableImplementationIntentBlocked == false
    let intentDeferred =
        implementationIntent.shouldDeferRendererRealDrawableImplementationIntent &&
        implementationIntent
            .shouldReportRendererRealDrawableImplementationIntentBlocked == false
    let intentInconsistent =
        implementationIntent
            .shouldReportRendererRealDrawableImplementationIntentBlocked ||
        (
            implementationIntent.didPrepareRendererRealDrawableImplementationIntent &&
            intentReady == false
        ) ||
        (
            implementationIntent.shouldDeferRendererRealDrawableImplementationIntent &&
            implementationIntent
                .shouldReportRendererRealDrawableImplementationIntentBlocked
        )

    if (intentInconsistent) {
        return CjguiInternalRendererRealDrawableAcquisitionAdmissionPolicy(
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
            true
        )
    }

    if (intentDeferred || intentReady == false) {
        return CjguiInternalRendererRealDrawableAcquisitionAdmissionPolicy(
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
            true
        )
    }

    return CjguiInternalRendererRealDrawableAcquisitionAdmissionPolicy(
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
        true
    )
}

func cjguiInternalBuildRendererRealDrawableAvailabilityAdmissionGuard(
    acquisitionAdmissionPolicy:
        CjguiInternalRendererRealDrawableAcquisitionAdmissionPolicy
): CjguiInternalRendererRealDrawableAvailabilityAdmissionGuard {
    let acquisitionPolicyReady =
        acquisitionAdmissionPolicy
            .didPrepareRendererRealDrawableAcquisitionAdmissionPolicy &&
        acquisitionAdmissionPolicy
            .didPreserveRendererRealDrawableImplementationIntent &&
        acquisitionAdmissionPolicy
            .didDefineFutureDrawableAcquisitionAdmissionPolicy &&
        acquisitionAdmissionPolicy.didDescribeLateDrawableBorrowAdmissionFacts &&
        acquisitionAdmissionPolicy.didDescribeNoLookupCallFacts &&
        acquisitionAdmissionPolicy.didDescribeNoBorrowedDrawableFacts &&
        acquisitionAdmissionPolicy.didConfirmNoDrawableObtained &&
        acquisitionAdmissionPolicy.didConfirmNoDrawableLookupCall &&
        acquisitionAdmissionPolicy
            .didKeepDrawableAcquisitionAdmissionPolicyValueOnly &&
        acquisitionAdmissionPolicy.didAvoidDrawableLookupPermissionWrapper &&
        acquisitionAdmissionPolicy.didAvoidDrawableReadyPermissionWrapper &&
        acquisitionAdmissionPolicy.didAvoidThinWrapper &&
        acquisitionAdmissionPolicy
            .shouldDeferRendererRealDrawableAcquisitionAdmissionPolicy == false &&
        acquisitionAdmissionPolicy
            .shouldReportRendererRealDrawableAcquisitionAdmissionPolicyBlocked == false
    let acquisitionPolicyDeferred =
        acquisitionAdmissionPolicy
            .shouldDeferRendererRealDrawableAcquisitionAdmissionPolicy &&
        acquisitionAdmissionPolicy
            .shouldReportRendererRealDrawableAcquisitionAdmissionPolicyBlocked == false
    let acquisitionPolicyInconsistent =
        acquisitionAdmissionPolicy
            .shouldReportRendererRealDrawableAcquisitionAdmissionPolicyBlocked ||
        (
            acquisitionAdmissionPolicy
                .didPrepareRendererRealDrawableAcquisitionAdmissionPolicy &&
            acquisitionPolicyReady == false
        ) ||
        (
            acquisitionAdmissionPolicy
                .shouldDeferRendererRealDrawableAcquisitionAdmissionPolicy &&
            acquisitionAdmissionPolicy
                .shouldReportRendererRealDrawableAcquisitionAdmissionPolicyBlocked
        )

    if (acquisitionPolicyInconsistent) {
        return CjguiInternalRendererRealDrawableAvailabilityAdmissionGuard(
            acquisitionAdmissionPolicy,
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

    if (acquisitionPolicyDeferred || acquisitionPolicyReady == false) {
        return CjguiInternalRendererRealDrawableAvailabilityAdmissionGuard(
            acquisitionAdmissionPolicy,
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

    return CjguiInternalRendererRealDrawableAvailabilityAdmissionGuard(
        acquisitionAdmissionPolicy,
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

func cjguiInternalBuildRendererRealDrawablePresentationAdmissionPolicy(
    availabilityAdmissionGuard:
        CjguiInternalRendererRealDrawableAvailabilityAdmissionGuard
): CjguiInternalRendererRealDrawablePresentationAdmissionPolicy {
    let availabilityGuardReady =
        availabilityAdmissionGuard
            .didPrepareRendererRealDrawableAvailabilityAdmissionGuard &&
        availabilityAdmissionGuard
            .didPreserveRendererRealDrawableAcquisitionAdmissionPolicy &&
        availabilityAdmissionGuard
            .didDefineFutureDrawableAvailabilityAdmissionGuard &&
        availabilityAdmissionGuard.didDescribeDrawableUnavailableAdmissionFacts &&
        availabilityAdmissionGuard.didDescribeDrawablePoolNotQueriedFacts &&
        availabilityAdmissionGuard.didDescribeNoDrawableTokenFacts &&
        availabilityAdmissionGuard.didConfirmNoDrawablePoolQuery &&
        availabilityAdmissionGuard.didConfirmNoDrawableTokenHeld &&
        availabilityAdmissionGuard
            .didKeepDrawableAvailabilityAdmissionGuardValueOnly &&
        availabilityAdmissionGuard.didAvoidDrawableReadyPermissionWrapper &&
        availabilityAdmissionGuard.didAvoidResourceTokenWrapper &&
        availabilityAdmissionGuard.didAvoidThinWrapper &&
        availabilityAdmissionGuard
            .shouldDeferRendererRealDrawableAvailabilityAdmissionGuard == false &&
        availabilityAdmissionGuard
            .shouldReportRendererRealDrawableAvailabilityAdmissionGuardBlocked == false
    let availabilityGuardDeferred =
        availabilityAdmissionGuard
            .shouldDeferRendererRealDrawableAvailabilityAdmissionGuard &&
        availabilityAdmissionGuard
            .shouldReportRendererRealDrawableAvailabilityAdmissionGuardBlocked == false
    let availabilityGuardInconsistent =
        availabilityAdmissionGuard
            .shouldReportRendererRealDrawableAvailabilityAdmissionGuardBlocked ||
        (
            availabilityAdmissionGuard
                .didPrepareRendererRealDrawableAvailabilityAdmissionGuard &&
            availabilityGuardReady == false
        ) ||
        (
            availabilityAdmissionGuard
                .shouldDeferRendererRealDrawableAvailabilityAdmissionGuard &&
            availabilityAdmissionGuard
                .shouldReportRendererRealDrawableAvailabilityAdmissionGuardBlocked
        )

    if (availabilityGuardInconsistent) {
        return CjguiInternalRendererRealDrawablePresentationAdmissionPolicy(
            availabilityAdmissionGuard,
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
            true
        )
    }

    if (availabilityGuardDeferred || availabilityGuardReady == false) {
        return CjguiInternalRendererRealDrawablePresentationAdmissionPolicy(
            availabilityAdmissionGuard,
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
            true
        )
    }

    return CjguiInternalRendererRealDrawablePresentationAdmissionPolicy(
        availabilityAdmissionGuard,
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

func cjguiInternalBuildRendererNoRealDrawableImplementationReadiness(
    displayAdmissionPolicy:
        CjguiInternalRendererRealDrawablePresentationAdmissionPolicy
): CjguiInternalRendererNoRealDrawableImplementationReadiness {
    let displayPolicyReady =
        displayAdmissionPolicy
            .didPrepareRendererRealDrawablePresentationAdmissionPolicy &&
        displayAdmissionPolicy
            .didPreserveRendererRealDrawableAvailabilityAdmissionGuard &&
        displayAdmissionPolicy
            .didDefineFutureDrawablePresentationAdmissionPolicy &&
        displayAdmissionPolicy.didDescribeDrawableDisplayOrderingFacts &&
        displayAdmissionPolicy.didDescribeNoCommandWorkFacts &&
        displayAdmissionPolicy.didDescribeNoDrawableDisplayCallFacts &&
        displayAdmissionPolicy.didConfirmNoDrawableDisplayCall &&
        displayAdmissionPolicy.didConfirmNoCommandBufferCreated &&
        displayAdmissionPolicy.didConfirmNoWorkSubmit &&
        displayAdmissionPolicy
            .didKeepDrawablePresentationAdmissionPolicyValueOnly &&
        displayAdmissionPolicy.didAvoidDrawableDisplayPermissionWrapper &&
        displayAdmissionPolicy.didAvoidWorkSubmitWrapper &&
        displayAdmissionPolicy.didAvoidThinWrapper &&
        displayAdmissionPolicy
            .shouldDeferRendererRealDrawablePresentationAdmissionPolicy == false &&
        displayAdmissionPolicy
            .shouldReportRendererRealDrawablePresentationAdmissionPolicyBlocked == false
    let displayPolicyDeferred =
        displayAdmissionPolicy
            .shouldDeferRendererRealDrawablePresentationAdmissionPolicy &&
        displayAdmissionPolicy
            .shouldReportRendererRealDrawablePresentationAdmissionPolicyBlocked == false
    let displayPolicyInconsistent =
        displayAdmissionPolicy
            .shouldReportRendererRealDrawablePresentationAdmissionPolicyBlocked ||
        (
            displayAdmissionPolicy
                .didPrepareRendererRealDrawablePresentationAdmissionPolicy &&
            displayPolicyReady == false
        ) ||
        (
            displayAdmissionPolicy
                .shouldDeferRendererRealDrawablePresentationAdmissionPolicy &&
            displayAdmissionPolicy
                .shouldReportRendererRealDrawablePresentationAdmissionPolicyBlocked
        )

    if (displayPolicyInconsistent) {
        return CjguiInternalRendererNoRealDrawableImplementationReadiness(
            displayAdmissionPolicy,
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
            true
        )
    }

    if (displayPolicyDeferred || displayPolicyReady == false) {
        return CjguiInternalRendererNoRealDrawableImplementationReadiness(
            displayAdmissionPolicy,
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
            true
        )
    }

    return CjguiInternalRendererNoRealDrawableImplementationReadiness(
        displayAdmissionPolicy,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft():
    CjguiInternalRendererNoRealDrawableImplementationReadiness {
    let noRealCommandQueueImplementationReadiness =
        cjguiInternalExecuteDefaultRendererRealCommandQueueAdmissionDraft()
    let implementationIntent =
        cjguiInternalBuildRendererRealDrawableImplementationIntent(
            noRealCommandQueueImplementationReadiness
        )
    let acquisitionAdmissionPolicy =
        cjguiInternalBuildRendererRealDrawableAcquisitionAdmissionPolicy(
            implementationIntent
        )
    let availabilityAdmissionGuard =
        cjguiInternalBuildRendererRealDrawableAvailabilityAdmissionGuard(
            acquisitionAdmissionPolicy
        )
    let displayAdmissionPolicy =
        cjguiInternalBuildRendererRealDrawablePresentationAdmissionPolicy(
            availabilityAdmissionGuard
        )
    return cjguiInternalBuildRendererNoRealDrawableImplementationReadiness(
        displayAdmissionPolicy
    )
}
