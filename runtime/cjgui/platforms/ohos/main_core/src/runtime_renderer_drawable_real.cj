// Owner: real drawable 第一刀 internal-only shell 边界。
// Truth: 只消费 CjguiInternalRendererNoRealCommandQueueShellReadiness，并记录
// drawable shell intent、availability admission shell、acquisition denial proof、
// presentation denial proof、teardown / failure classification 与
// no-real-drawable-shell readiness facts。
// Stop-line: 只产出 internal-only shell / dehydrated facts；不是 drawable 获取、
// nextDrawable、present、command buffer、GPU work、native bridge、native handle、
// C ABI / FFI、renderer state write 或 public API 许可。
// Same-shape Boundary Brake: 不得把本 shell 包成 drawable-ready、queue-ready、
// backend-ready、native-handle-ready、GPU-submission、render-permission、receipt、
// record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererRealDrawableShellIntent {
    let noRealCommandQueueShellReadiness:
        CjguiInternalRendererNoRealCommandQueueShellReadiness
    let didPrepareRendererRealDrawableShellIntent: Bool
    let shouldDeferRendererRealDrawableShellIntent: Bool
    let shouldReportRendererRealDrawableShellIntentBlocked: Bool
    let didPreserveRendererNoRealCommandQueueShellReadiness: Bool
    let didDefineFutureDrawableShellIntent: Bool
    let didDescribeDrawableAvailabilityNeed: Bool
    let didDescribeDrawableAcquisitionDenialNeed: Bool
    let didDescribeDrawablePresentationDenialNeed: Bool
    let didKeepDrawableShellIntentDehydrated: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidQueueReadyWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool

    init(
        noRealCommandQueueShellReadiness:
            CjguiInternalRendererNoRealCommandQueueShellReadiness,
        didPrepareRendererRealDrawableShellIntent: Bool,
        shouldDeferRendererRealDrawableShellIntent: Bool,
        shouldReportRendererRealDrawableShellIntentBlocked: Bool,
        didPreserveRendererNoRealCommandQueueShellReadiness: Bool,
        didDefineFutureDrawableShellIntent: Bool,
        didDescribeDrawableAvailabilityNeed: Bool,
        didDescribeDrawableAcquisitionDenialNeed: Bool,
        didDescribeDrawablePresentationDenialNeed: Bool,
        didKeepDrawableShellIntentDehydrated: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidQueueReadyWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool
    ) {
        this.noRealCommandQueueShellReadiness =
            noRealCommandQueueShellReadiness
        this.didPrepareRendererRealDrawableShellIntent =
            didPrepareRendererRealDrawableShellIntent
        this.shouldDeferRendererRealDrawableShellIntent =
            shouldDeferRendererRealDrawableShellIntent
        this.shouldReportRendererRealDrawableShellIntentBlocked =
            shouldReportRendererRealDrawableShellIntentBlocked
        this.didPreserveRendererNoRealCommandQueueShellReadiness =
            didPreserveRendererNoRealCommandQueueShellReadiness
        this.didDefineFutureDrawableShellIntent =
            didDefineFutureDrawableShellIntent
        this.didDescribeDrawableAvailabilityNeed =
            didDescribeDrawableAvailabilityNeed
        this.didDescribeDrawableAcquisitionDenialNeed =
            didDescribeDrawableAcquisitionDenialNeed
        this.didDescribeDrawablePresentationDenialNeed =
            didDescribeDrawablePresentationDenialNeed
        this.didKeepDrawableShellIntentDehydrated =
            didKeepDrawableShellIntentDehydrated
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidQueueReadyWrapper = didAvoidQueueReadyWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
    }
}

struct CjguiInternalRendererRealDrawableAvailabilityAdmissionShell {
    let shellIntent: CjguiInternalRendererRealDrawableShellIntent
    let didPrepareRendererDrawableAvailabilityAdmissionShell: Bool
    let shouldDeferRendererDrawableAvailabilityAdmissionShell: Bool
    let shouldReportRendererDrawableAvailabilityAdmissionShellBlocked: Bool
    let didPreserveRendererRealDrawableShellIntent: Bool
    let didDefineOwnerLocalDrawableAvailabilityShell: Bool
    let didConfirmNoDrawablePoolQuery: Bool
    let didConfirmNoDrawableTokenStored: Bool
    let didConfirmNoNativeResourceSurface: Bool
    let didKeepDrawableAvailabilityShellDehydrated: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        shellIntent: CjguiInternalRendererRealDrawableShellIntent,
        didPrepareRendererDrawableAvailabilityAdmissionShell: Bool,
        shouldDeferRendererDrawableAvailabilityAdmissionShell: Bool,
        shouldReportRendererDrawableAvailabilityAdmissionShellBlocked: Bool,
        didPreserveRendererRealDrawableShellIntent: Bool,
        didDefineOwnerLocalDrawableAvailabilityShell: Bool,
        didConfirmNoDrawablePoolQuery: Bool,
        didConfirmNoDrawableTokenStored: Bool,
        didConfirmNoNativeResourceSurface: Bool,
        didKeepDrawableAvailabilityShellDehydrated: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.shellIntent = shellIntent
        this.didPrepareRendererDrawableAvailabilityAdmissionShell =
            didPrepareRendererDrawableAvailabilityAdmissionShell
        this.shouldDeferRendererDrawableAvailabilityAdmissionShell =
            shouldDeferRendererDrawableAvailabilityAdmissionShell
        this
            .shouldReportRendererDrawableAvailabilityAdmissionShellBlocked =
            shouldReportRendererDrawableAvailabilityAdmissionShellBlocked
        this.didPreserveRendererRealDrawableShellIntent =
            didPreserveRendererRealDrawableShellIntent
        this.didDefineOwnerLocalDrawableAvailabilityShell =
            didDefineOwnerLocalDrawableAvailabilityShell
        this.didConfirmNoDrawablePoolQuery = didConfirmNoDrawablePoolQuery
        this.didConfirmNoDrawableTokenStored =
            didConfirmNoDrawableTokenStored
        this.didConfirmNoNativeResourceSurface =
            didConfirmNoNativeResourceSurface
        this.didKeepDrawableAvailabilityShellDehydrated =
            didKeepDrawableAvailabilityShellDehydrated
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererDrawableAcquisitionDenialProof {
    let availabilityAdmissionShell:
        CjguiInternalRendererRealDrawableAvailabilityAdmissionShell
    let didPrepareRendererDrawableAcquisitionDenialProof: Bool
    let shouldDeferRendererDrawableAcquisitionDenialProof: Bool
    let shouldReportRendererDrawableAcquisitionDenialProofBlocked: Bool
    let didPreserveRendererDrawableAvailabilityAdmissionShell: Bool
    let didDefineOwnerLocalDrawableAcquisitionDenial: Bool
    let didConfirmNoDrawableBorrow: Bool
    let didConfirmNoDrawableTextureExposure: Bool
    let didConfirmNoBlockingForeignCall: Bool
    let didKeepDrawableAcquisitionDenialDehydrated: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidNativeHandleWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        availabilityAdmissionShell:
            CjguiInternalRendererRealDrawableAvailabilityAdmissionShell,
        didPrepareRendererDrawableAcquisitionDenialProof: Bool,
        shouldDeferRendererDrawableAcquisitionDenialProof: Bool,
        shouldReportRendererDrawableAcquisitionDenialProofBlocked: Bool,
        didPreserveRendererDrawableAvailabilityAdmissionShell: Bool,
        didDefineOwnerLocalDrawableAcquisitionDenial: Bool,
        didConfirmNoDrawableBorrow: Bool,
        didConfirmNoDrawableTextureExposure: Bool,
        didConfirmNoBlockingForeignCall: Bool,
        didKeepDrawableAcquisitionDenialDehydrated: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidNativeHandleWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.availabilityAdmissionShell = availabilityAdmissionShell
        this.didPrepareRendererDrawableAcquisitionDenialProof =
            didPrepareRendererDrawableAcquisitionDenialProof
        this.shouldDeferRendererDrawableAcquisitionDenialProof =
            shouldDeferRendererDrawableAcquisitionDenialProof
        this.shouldReportRendererDrawableAcquisitionDenialProofBlocked =
            shouldReportRendererDrawableAcquisitionDenialProofBlocked
        this.didPreserveRendererDrawableAvailabilityAdmissionShell =
            didPreserveRendererDrawableAvailabilityAdmissionShell
        this.didDefineOwnerLocalDrawableAcquisitionDenial =
            didDefineOwnerLocalDrawableAcquisitionDenial
        this.didConfirmNoDrawableBorrow = didConfirmNoDrawableBorrow
        this.didConfirmNoDrawableTextureExposure =
            didConfirmNoDrawableTextureExposure
        this.didConfirmNoBlockingForeignCall = didConfirmNoBlockingForeignCall
        this.didKeepDrawableAcquisitionDenialDehydrated =
            didKeepDrawableAcquisitionDenialDehydrated
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidNativeHandleWrapper = didAvoidNativeHandleWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererDrawablePresentationDenialProof {
    let acquisitionDenialProof:
        CjguiInternalRendererDrawableAcquisitionDenialProof
    let didPrepareRendererDrawablePresentationDenialProof: Bool
    let shouldDeferRendererDrawablePresentationDenialProof: Bool
    let shouldReportRendererDrawablePresentationDenialProofBlocked: Bool
    let didPreserveRendererDrawableAcquisitionDenialProof: Bool
    let didDefineOwnerLocalDrawablePresentationDenial: Bool
    let didConfirmNoPresentationCall: Bool
    let didConfirmNoCommandBufferRelation: Bool
    let didConfirmNoWorkSubmit: Bool
    let didKeepDrawablePresentationDenialDehydrated: Bool
    let didAvoidPresentationPermissionWrapper: Bool
    let didAvoidWorkSubmitWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        acquisitionDenialProof:
            CjguiInternalRendererDrawableAcquisitionDenialProof,
        didPrepareRendererDrawablePresentationDenialProof: Bool,
        shouldDeferRendererDrawablePresentationDenialProof: Bool,
        shouldReportRendererDrawablePresentationDenialProofBlocked: Bool,
        didPreserveRendererDrawableAcquisitionDenialProof: Bool,
        didDefineOwnerLocalDrawablePresentationDenial: Bool,
        didConfirmNoPresentationCall: Bool,
        didConfirmNoCommandBufferRelation: Bool,
        didConfirmNoWorkSubmit: Bool,
        didKeepDrawablePresentationDenialDehydrated: Bool,
        didAvoidPresentationPermissionWrapper: Bool,
        didAvoidWorkSubmitWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.acquisitionDenialProof = acquisitionDenialProof
        this.didPrepareRendererDrawablePresentationDenialProof =
            didPrepareRendererDrawablePresentationDenialProof
        this.shouldDeferRendererDrawablePresentationDenialProof =
            shouldDeferRendererDrawablePresentationDenialProof
        this.shouldReportRendererDrawablePresentationDenialProofBlocked =
            shouldReportRendererDrawablePresentationDenialProofBlocked
        this.didPreserveRendererDrawableAcquisitionDenialProof =
            didPreserveRendererDrawableAcquisitionDenialProof
        this.didDefineOwnerLocalDrawablePresentationDenial =
            didDefineOwnerLocalDrawablePresentationDenial
        this.didConfirmNoPresentationCall = didConfirmNoPresentationCall
        this.didConfirmNoCommandBufferRelation =
            didConfirmNoCommandBufferRelation
        this.didConfirmNoWorkSubmit = didConfirmNoWorkSubmit
        this.didKeepDrawablePresentationDenialDehydrated =
            didKeepDrawablePresentationDenialDehydrated
        this.didAvoidPresentationPermissionWrapper =
            didAvoidPresentationPermissionWrapper
        this.didAvoidWorkSubmitWrapper = didAvoidWorkSubmitWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererDrawableTeardownFailureClassification {
    let presentationDenialProof:
        CjguiInternalRendererDrawablePresentationDenialProof
    let didPrepareRendererDrawableTeardownFailureClassification: Bool
    let shouldDeferRendererDrawableTeardownFailureClassification: Bool
    let shouldReportRendererDrawableTeardownFailureClassificationBlocked:
        Bool
    let didPreserveRendererDrawablePresentationDenialProof: Bool
    let didDefineOwnerLocalDrawableTeardownFailureClassification: Bool
    let didFailClosedUnavailableDrawable: Bool
    let didFailClosedWrongThreadRisk: Bool
    let didFailClosedStaleDrawableRisk: Bool
    let didFailClosedBridgeOptimism: Bool
    let didConfirmNoFailurePublication: Bool
    let didConfirmNoPublicDiagnostics: Bool
    let didKeepDrawableTeardownFailureDehydrated: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        presentationDenialProof:
            CjguiInternalRendererDrawablePresentationDenialProof,
        didPrepareRendererDrawableTeardownFailureClassification: Bool,
        shouldDeferRendererDrawableTeardownFailureClassification: Bool,
        shouldReportRendererDrawableTeardownFailureClassificationBlocked:
            Bool,
        didPreserveRendererDrawablePresentationDenialProof: Bool,
        didDefineOwnerLocalDrawableTeardownFailureClassification: Bool,
        didFailClosedUnavailableDrawable: Bool,
        didFailClosedWrongThreadRisk: Bool,
        didFailClosedStaleDrawableRisk: Bool,
        didFailClosedBridgeOptimism: Bool,
        didConfirmNoFailurePublication: Bool,
        didConfirmNoPublicDiagnostics: Bool,
        didKeepDrawableTeardownFailureDehydrated: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.presentationDenialProof = presentationDenialProof
        this.didPrepareRendererDrawableTeardownFailureClassification =
            didPrepareRendererDrawableTeardownFailureClassification
        this.shouldDeferRendererDrawableTeardownFailureClassification =
            shouldDeferRendererDrawableTeardownFailureClassification
        this
            .shouldReportRendererDrawableTeardownFailureClassificationBlocked =
            shouldReportRendererDrawableTeardownFailureClassificationBlocked
        this.didPreserveRendererDrawablePresentationDenialProof =
            didPreserveRendererDrawablePresentationDenialProof
        this.didDefineOwnerLocalDrawableTeardownFailureClassification =
            didDefineOwnerLocalDrawableTeardownFailureClassification
        this.didFailClosedUnavailableDrawable =
            didFailClosedUnavailableDrawable
        this.didFailClosedWrongThreadRisk = didFailClosedWrongThreadRisk
        this.didFailClosedStaleDrawableRisk = didFailClosedStaleDrawableRisk
        this.didFailClosedBridgeOptimism = didFailClosedBridgeOptimism
        this.didConfirmNoFailurePublication = didConfirmNoFailurePublication
        this.didConfirmNoPublicDiagnostics = didConfirmNoPublicDiagnostics
        this.didKeepDrawableTeardownFailureDehydrated =
            didKeepDrawableTeardownFailureDehydrated
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoRealDrawableShellReadiness {
    let teardownFailureClassification:
        CjguiInternalRendererDrawableTeardownFailureClassification
    let isRendererNoRealDrawableShellReady: Bool
    let canFutureRendererRealDrawableShellBoundaryEvaluate: Bool
    let shouldDeferRendererNoRealDrawableShellReadiness: Bool
    let shouldReportRendererNoRealDrawableShellReadinessBlocked: Bool
    let didSealRendererNoRealDrawableShellReadiness: Bool
    let didPreserveRendererDrawableTeardownFailureClassification: Bool
    let didKeepNoRealDrawableShellReadinessDehydrated: Bool
    let didConfirmNoDrawableAcquisition: Bool
    let didConfirmNoDrawableTextureExposure: Bool
    let didConfirmNoPresentationCall: Bool
    let didConfirmNoCommandBufferCreation: Bool
    let didConfirmNoWorkSubmit: Bool
    let didConfirmNoNativeResourceStored: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoStateMutation: Bool
    let didConfirmNoRuntimeStateTouch: Bool
    let didConfirmNoModuleLevelMutableState: Bool
    let didConfirmNoPublicDiagnostics: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidQueueReadyWrapper: Bool
    let didAvoidNativeHandleWrapper: Bool
    let didAvoidWorkSubmitWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidStateMutationWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        teardownFailureClassification:
            CjguiInternalRendererDrawableTeardownFailureClassification,
        isRendererNoRealDrawableShellReady: Bool,
        canFutureRendererRealDrawableShellBoundaryEvaluate: Bool,
        shouldDeferRendererNoRealDrawableShellReadiness: Bool,
        shouldReportRendererNoRealDrawableShellReadinessBlocked: Bool,
        didSealRendererNoRealDrawableShellReadiness: Bool,
        didPreserveRendererDrawableTeardownFailureClassification: Bool,
        didKeepNoRealDrawableShellReadinessDehydrated: Bool,
        didConfirmNoDrawableAcquisition: Bool,
        didConfirmNoDrawableTextureExposure: Bool,
        didConfirmNoPresentationCall: Bool,
        didConfirmNoCommandBufferCreation: Bool,
        didConfirmNoWorkSubmit: Bool,
        didConfirmNoNativeResourceStored: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoStateMutation: Bool,
        didConfirmNoRuntimeStateTouch: Bool,
        didConfirmNoModuleLevelMutableState: Bool,
        didConfirmNoPublicDiagnostics: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidQueueReadyWrapper: Bool,
        didAvoidNativeHandleWrapper: Bool,
        didAvoidWorkSubmitWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidStateMutationWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.teardownFailureClassification = teardownFailureClassification
        this.isRendererNoRealDrawableShellReady =
            isRendererNoRealDrawableShellReady
        this.canFutureRendererRealDrawableShellBoundaryEvaluate =
            canFutureRendererRealDrawableShellBoundaryEvaluate
        this.shouldDeferRendererNoRealDrawableShellReadiness =
            shouldDeferRendererNoRealDrawableShellReadiness
        this.shouldReportRendererNoRealDrawableShellReadinessBlocked =
            shouldReportRendererNoRealDrawableShellReadinessBlocked
        this.didSealRendererNoRealDrawableShellReadiness =
            didSealRendererNoRealDrawableShellReadiness
        this.didPreserveRendererDrawableTeardownFailureClassification =
            didPreserveRendererDrawableTeardownFailureClassification
        this.didKeepNoRealDrawableShellReadinessDehydrated =
            didKeepNoRealDrawableShellReadinessDehydrated
        this.didConfirmNoDrawableAcquisition =
            didConfirmNoDrawableAcquisition
        this.didConfirmNoDrawableTextureExposure =
            didConfirmNoDrawableTextureExposure
        this.didConfirmNoPresentationCall = didConfirmNoPresentationCall
        this.didConfirmNoCommandBufferCreation =
            didConfirmNoCommandBufferCreation
        this.didConfirmNoWorkSubmit = didConfirmNoWorkSubmit
        this.didConfirmNoNativeResourceStored =
            didConfirmNoNativeResourceStored
        this.didConfirmNoPointerLikeResource =
            didConfirmNoPointerLikeResource
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoStateMutation = didConfirmNoStateMutation
        this.didConfirmNoRuntimeStateTouch = didConfirmNoRuntimeStateTouch
        this.didConfirmNoModuleLevelMutableState =
            didConfirmNoModuleLevelMutableState
        this.didConfirmNoPublicDiagnostics = didConfirmNoPublicDiagnostics
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidQueueReadyWrapper = didAvoidQueueReadyWrapper
        this.didAvoidNativeHandleWrapper = didAvoidNativeHandleWrapper
        this.didAvoidWorkSubmitWrapper = didAvoidWorkSubmitWrapper
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidStateMutationWrapper = didAvoidStateMutationWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererRealDrawableShellIntent(
    noRealCommandQueueShellReadiness:
        CjguiInternalRendererNoRealCommandQueueShellReadiness
): CjguiInternalRendererRealDrawableShellIntent {
    let upstreamReady =
        noRealCommandQueueShellReadiness
            .isRendererNoRealCommandQueueShellReady &&
        noRealCommandQueueShellReadiness
            .canFutureRendererRealCommandQueueShellBoundaryEvaluate &&
        noRealCommandQueueShellReadiness
            .didSealRendererNoRealCommandQueueShellReadiness &&
        noRealCommandQueueShellReadiness
            .didPreserveRendererRealCommandQueueFailureClassification &&
        noRealCommandQueueShellReadiness
            .didKeepNoRealCommandQueueReadinessDehydrated &&
        noRealCommandQueueShellReadiness
            .didConfirmNoConcreteCommandQueueObject &&
        noRealCommandQueueShellReadiness.didConfirmNoQueueFactoryCall &&
        noRealCommandQueueShellReadiness.didConfirmNoForeignResourceSurface &&
        noRealCommandQueueShellReadiness.didConfirmNoNativeResourceStored &&
        noRealCommandQueueShellReadiness.didConfirmNoPointerLikeResource &&
        noRealCommandQueueShellReadiness.didConfirmNoDrawableAcquisition &&
        noRealCommandQueueShellReadiness.didConfirmNoCommandBufferCreation &&
        noRealCommandQueueShellReadiness.didConfirmNoWorkSubmit &&
        noRealCommandQueueShellReadiness.didConfirmNoRenderExecution &&
        noRealCommandQueueShellReadiness.didConfirmNoStateMutation &&
        noRealCommandQueueShellReadiness.didConfirmNoRuntimeStateTouch &&
        noRealCommandQueueShellReadiness
            .didConfirmNoModuleLevelMutableState &&
        noRealCommandQueueShellReadiness.didConfirmNoPublicDiagnostics &&
        noRealCommandQueueShellReadiness.didAvoidQueueReadyWrapper &&
        noRealCommandQueueShellReadiness.didAvoidNativeHandleWrapper &&
        noRealCommandQueueShellReadiness.didAvoidBackendReadyWrapper &&
        noRealCommandQueueShellReadiness.didAvoidWorkSubmitWrapper &&
        noRealCommandQueueShellReadiness.didAvoidRenderPermissionWrapper &&
        noRealCommandQueueShellReadiness.didAvoidStateMutationWrapper &&
        noRealCommandQueueShellReadiness.didAvoidExternalSurfaceWrapper &&
        noRealCommandQueueShellReadiness.didAvoidReceiptRecordOutput &&
        noRealCommandQueueShellReadiness.didAvoidThinWrapper &&
        noRealCommandQueueShellReadiness.didStayFullRebuildOnly &&
        noRealCommandQueueShellReadiness
            .shouldDeferRendererNoRealCommandQueueShellReadiness == false &&
        noRealCommandQueueShellReadiness
            .shouldReportRendererNoRealCommandQueueShellReadinessBlocked ==
            false
    let upstreamDeferred =
        noRealCommandQueueShellReadiness
            .isRendererNoRealCommandQueueShellReady == false &&
        noRealCommandQueueShellReadiness
            .canFutureRendererRealCommandQueueShellBoundaryEvaluate == false &&
        noRealCommandQueueShellReadiness
            .shouldDeferRendererNoRealCommandQueueShellReadiness &&
        noRealCommandQueueShellReadiness
            .shouldReportRendererNoRealCommandQueueShellReadinessBlocked ==
            false
    let upstreamInconsistent =
        noRealCommandQueueShellReadiness
            .shouldReportRendererNoRealCommandQueueShellReadinessBlocked ||
        (
            noRealCommandQueueShellReadiness
                .isRendererNoRealCommandQueueShellReady &&
            (
                upstreamReady == false ||
                noRealCommandQueueShellReadiness
                    .shouldDeferRendererNoRealCommandQueueShellReadiness
            )
        ) ||
        (
            noRealCommandQueueShellReadiness
                .canFutureRendererRealCommandQueueShellBoundaryEvaluate &&
            noRealCommandQueueShellReadiness
                .isRendererNoRealCommandQueueShellReady == false
        )

    if (upstreamInconsistent) {
        return CjguiInternalRendererRealDrawableShellIntent(
            noRealCommandQueueShellReadiness,
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

    if (upstreamReady) {
        return CjguiInternalRendererRealDrawableShellIntent(
            noRealCommandQueueShellReadiness,
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

    if (upstreamDeferred) {
        return CjguiInternalRendererRealDrawableShellIntent(
            noRealCommandQueueShellReadiness,
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

    return CjguiInternalRendererRealDrawableShellIntent(
        noRealCommandQueueShellReadiness,
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

func cjguiInternalBuildRendererDrawableAvailabilityAdmissionShell(
    shellIntent: CjguiInternalRendererRealDrawableShellIntent
): CjguiInternalRendererRealDrawableAvailabilityAdmissionShell {
    let intentReady =
        shellIntent.didPrepareRendererRealDrawableShellIntent &&
        shellIntent.didPreserveRendererNoRealCommandQueueShellReadiness &&
        shellIntent.didDefineFutureDrawableShellIntent &&
        shellIntent.didDescribeDrawableAvailabilityNeed &&
        shellIntent.didDescribeDrawableAcquisitionDenialNeed &&
        shellIntent.didDescribeDrawablePresentationDenialNeed &&
        shellIntent.didKeepDrawableShellIntentDehydrated &&
        shellIntent.didAvoidDrawableReadyWrapper &&
        shellIntent.didAvoidQueueReadyWrapper &&
        shellIntent.didAvoidReceiptRecordOutput &&
        shellIntent.shouldDeferRendererRealDrawableShellIntent == false &&
        shellIntent.shouldReportRendererRealDrawableShellIntentBlocked ==
            false
    let intentDeferred =
        shellIntent.didPrepareRendererRealDrawableShellIntent == false &&
        shellIntent.shouldDeferRendererRealDrawableShellIntent &&
        shellIntent.shouldReportRendererRealDrawableShellIntentBlocked ==
            false
    let intentInconsistent =
        shellIntent.shouldReportRendererRealDrawableShellIntentBlocked ||
        (
            shellIntent.didPrepareRendererRealDrawableShellIntent &&
            intentReady == false
        )

    return CjguiInternalRendererRealDrawableAvailabilityAdmissionShell(
        shellIntent,
        intentReady,
        intentDeferred,
        intentInconsistent,
        intentReady,
        intentReady,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererDrawableAcquisitionDenialProof(
    availabilityAdmissionShell:
        CjguiInternalRendererRealDrawableAvailabilityAdmissionShell
): CjguiInternalRendererDrawableAcquisitionDenialProof {
    let availabilityReady =
        availabilityAdmissionShell
            .didPrepareRendererDrawableAvailabilityAdmissionShell &&
        availabilityAdmissionShell
            .didPreserveRendererRealDrawableShellIntent &&
        availabilityAdmissionShell
            .didDefineOwnerLocalDrawableAvailabilityShell &&
        availabilityAdmissionShell.didConfirmNoDrawablePoolQuery &&
        availabilityAdmissionShell.didConfirmNoDrawableTokenStored &&
        availabilityAdmissionShell.didConfirmNoNativeResourceSurface &&
        availabilityAdmissionShell
            .didKeepDrawableAvailabilityShellDehydrated &&
        availabilityAdmissionShell.didAvoidDrawableReadyWrapper &&
        availabilityAdmissionShell.didAvoidBackendReadyWrapper &&
        availabilityAdmissionShell.didAvoidThinWrapper &&
        availabilityAdmissionShell
            .shouldDeferRendererDrawableAvailabilityAdmissionShell == false &&
        availabilityAdmissionShell
            .shouldReportRendererDrawableAvailabilityAdmissionShellBlocked ==
            false
    let availabilityDeferred =
        availabilityAdmissionShell
            .didPrepareRendererDrawableAvailabilityAdmissionShell == false &&
        availabilityAdmissionShell
            .shouldDeferRendererDrawableAvailabilityAdmissionShell &&
        availabilityAdmissionShell
            .shouldReportRendererDrawableAvailabilityAdmissionShellBlocked ==
            false
    let availabilityInconsistent =
        availabilityAdmissionShell
            .shouldReportRendererDrawableAvailabilityAdmissionShellBlocked ||
        (
            availabilityAdmissionShell
                .didPrepareRendererDrawableAvailabilityAdmissionShell &&
            availabilityReady == false
        )

    return CjguiInternalRendererDrawableAcquisitionDenialProof(
        availabilityAdmissionShell,
        availabilityReady,
        availabilityDeferred,
        availabilityInconsistent,
        availabilityReady,
        availabilityReady,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererDrawablePresentationDenialProof(
    acquisitionDenialProof:
        CjguiInternalRendererDrawableAcquisitionDenialProof
): CjguiInternalRendererDrawablePresentationDenialProof {
    let acquisitionReady =
        acquisitionDenialProof
            .didPrepareRendererDrawableAcquisitionDenialProof &&
        acquisitionDenialProof
            .didPreserveRendererDrawableAvailabilityAdmissionShell &&
        acquisitionDenialProof
            .didDefineOwnerLocalDrawableAcquisitionDenial &&
        acquisitionDenialProof.didConfirmNoDrawableBorrow &&
        acquisitionDenialProof.didConfirmNoDrawableTextureExposure &&
        acquisitionDenialProof.didConfirmNoBlockingForeignCall &&
        acquisitionDenialProof.didKeepDrawableAcquisitionDenialDehydrated &&
        acquisitionDenialProof.didAvoidDrawableReadyWrapper &&
        acquisitionDenialProof.didAvoidNativeHandleWrapper &&
        acquisitionDenialProof.didAvoidThinWrapper &&
        acquisitionDenialProof
            .shouldDeferRendererDrawableAcquisitionDenialProof == false &&
        acquisitionDenialProof
            .shouldReportRendererDrawableAcquisitionDenialProofBlocked ==
            false
    let acquisitionDeferred =
        acquisitionDenialProof
            .didPrepareRendererDrawableAcquisitionDenialProof == false &&
        acquisitionDenialProof
            .shouldDeferRendererDrawableAcquisitionDenialProof &&
        acquisitionDenialProof
            .shouldReportRendererDrawableAcquisitionDenialProofBlocked ==
            false
    let acquisitionInconsistent =
        acquisitionDenialProof
            .shouldReportRendererDrawableAcquisitionDenialProofBlocked ||
        (
            acquisitionDenialProof
                .didPrepareRendererDrawableAcquisitionDenialProof &&
            acquisitionReady == false
        )

    return CjguiInternalRendererDrawablePresentationDenialProof(
        acquisitionDenialProof,
        acquisitionReady,
        acquisitionDeferred,
        acquisitionInconsistent,
        acquisitionReady,
        acquisitionReady,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererDrawableTeardownFailureClassification(
    presentationDenialProof:
        CjguiInternalRendererDrawablePresentationDenialProof
): CjguiInternalRendererDrawableTeardownFailureClassification {
    let presentationReady =
        presentationDenialProof
            .didPrepareRendererDrawablePresentationDenialProof &&
        presentationDenialProof
            .didPreserveRendererDrawableAcquisitionDenialProof &&
        presentationDenialProof
            .didDefineOwnerLocalDrawablePresentationDenial &&
        presentationDenialProof.didConfirmNoPresentationCall &&
        presentationDenialProof.didConfirmNoCommandBufferRelation &&
        presentationDenialProof.didConfirmNoWorkSubmit &&
        presentationDenialProof.didKeepDrawablePresentationDenialDehydrated &&
        presentationDenialProof.didAvoidPresentationPermissionWrapper &&
        presentationDenialProof.didAvoidWorkSubmitWrapper &&
        presentationDenialProof.didAvoidThinWrapper &&
        presentationDenialProof
            .shouldDeferRendererDrawablePresentationDenialProof == false &&
        presentationDenialProof
            .shouldReportRendererDrawablePresentationDenialProofBlocked ==
            false
    let presentationDeferred =
        presentationDenialProof
            .didPrepareRendererDrawablePresentationDenialProof == false &&
        presentationDenialProof
            .shouldDeferRendererDrawablePresentationDenialProof &&
        presentationDenialProof
            .shouldReportRendererDrawablePresentationDenialProofBlocked ==
            false
    let presentationInconsistent =
        presentationDenialProof
            .shouldReportRendererDrawablePresentationDenialProofBlocked ||
        (
            presentationDenialProof
                .didPrepareRendererDrawablePresentationDenialProof &&
            presentationReady == false
        )

    return CjguiInternalRendererDrawableTeardownFailureClassification(
        presentationDenialProof,
        presentationReady,
        presentationDeferred,
        presentationInconsistent,
        presentationReady,
        presentationReady,
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

func cjguiInternalBuildRendererNoRealDrawableShellReadiness(
    teardownFailureClassification:
        CjguiInternalRendererDrawableTeardownFailureClassification
): CjguiInternalRendererNoRealDrawableShellReadiness {
    let failureReady =
        teardownFailureClassification
            .didPrepareRendererDrawableTeardownFailureClassification &&
        teardownFailureClassification
            .didPreserveRendererDrawablePresentationDenialProof &&
        teardownFailureClassification
            .didDefineOwnerLocalDrawableTeardownFailureClassification &&
        teardownFailureClassification.didFailClosedUnavailableDrawable &&
        teardownFailureClassification.didFailClosedWrongThreadRisk &&
        teardownFailureClassification.didFailClosedStaleDrawableRisk &&
        teardownFailureClassification.didFailClosedBridgeOptimism &&
        teardownFailureClassification.didConfirmNoFailurePublication &&
        teardownFailureClassification.didConfirmNoPublicDiagnostics &&
        teardownFailureClassification.didKeepDrawableTeardownFailureDehydrated &&
        teardownFailureClassification.didAvoidDrawableReadyWrapper &&
        teardownFailureClassification.didAvoidReceiptRecordOutput &&
        teardownFailureClassification.didAvoidThinWrapper &&
        teardownFailureClassification
            .shouldDeferRendererDrawableTeardownFailureClassification ==
            false &&
        teardownFailureClassification
            .shouldReportRendererDrawableTeardownFailureClassificationBlocked ==
            false
    let failureDeferred =
        teardownFailureClassification
            .didPrepareRendererDrawableTeardownFailureClassification ==
            false &&
        teardownFailureClassification
            .shouldDeferRendererDrawableTeardownFailureClassification &&
        teardownFailureClassification
            .shouldReportRendererDrawableTeardownFailureClassificationBlocked ==
            false
    let failureInconsistent =
        teardownFailureClassification
            .shouldReportRendererDrawableTeardownFailureClassificationBlocked ||
        (
            teardownFailureClassification
                .didPrepareRendererDrawableTeardownFailureClassification &&
            failureReady == false
        )

    return CjguiInternalRendererNoRealDrawableShellReadiness(
        teardownFailureClassification,
        failureReady,
        failureReady,
        failureDeferred,
        failureInconsistent,
        failureReady,
        failureReady,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
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

func cjguiInternalExecuteDefaultRendererRealDrawableShellDraft():
    CjguiInternalRendererNoRealDrawableShellReadiness {
    let noRealCommandQueueShellReadiness =
        cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft()
    let shellIntent =
        cjguiInternalBuildRendererRealDrawableShellIntent(
            noRealCommandQueueShellReadiness
        )
    let availabilityAdmissionShell =
        cjguiInternalBuildRendererDrawableAvailabilityAdmissionShell(
            shellIntent
        )
    let acquisitionDenialProof =
        cjguiInternalBuildRendererDrawableAcquisitionDenialProof(
            availabilityAdmissionShell
        )
    let presentationDenialProof =
        cjguiInternalBuildRendererDrawablePresentationDenialProof(
            acquisitionDenialProof
        )
    let teardownFailureClassification =
        cjguiInternalBuildRendererDrawableTeardownFailureClassification(
            presentationDenialProof
        )
    return cjguiInternalBuildRendererNoRealDrawableShellReadiness(
        teardownFailureClassification
    )
}
