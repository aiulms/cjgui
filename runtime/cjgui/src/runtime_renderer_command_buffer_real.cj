// Owner: real command buffer 第一刀 internal-only shell 边界。
// Truth: 只消费 CjguiInternalRendererNoRealDrawableShellReadiness，并记录
// command buffer shell intent、creation admission shell、commit denial proof、
// completion denial proof、teardown / failure classification 与
// no-real-command-buffer-shell readiness facts。
// Stop-line: 只产出 internal-only shell / dehydrated facts；不是 commandBuffer、
// commit、render pass、encoder、GPU work、native bridge、native handle、C ABI / FFI、
// renderer state write 或 public API 许可。
// Same-shape Boundary Brake: 不得把本 shell 包成 command-buffer-ready、
// drawable-ready、GPU-submission、render-permission、receipt、record 或
// publication wrapper。
package cjgui

struct CjguiInternalRendererRealCommandBufferShellIntent {
    let noRealDrawableShellReadiness:
        CjguiInternalRendererNoRealDrawableShellReadiness
    let didPrepareRendererRealCommandBufferShellIntent: Bool
    let shouldDeferRendererRealCommandBufferShellIntent: Bool
    let shouldReportRendererRealCommandBufferShellIntentBlocked: Bool
    let didPreserveRendererNoRealDrawableShellReadiness: Bool
    let didDefineFutureCommandBufferShellIntent: Bool
    let didDescribeCommandBufferCreationAdmissionNeed: Bool
    let didDescribeCommitDenialNeed: Bool
    let didDescribeCompletionDenialNeed: Bool
    let didDescribeCommandBufferFailureClassificationNeed: Bool
    let didKeepCommandBufferShellIntentDehydrated: Bool
    let didAvoidCommandBufferReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        noRealDrawableShellReadiness:
            CjguiInternalRendererNoRealDrawableShellReadiness,
        didPrepareRendererRealCommandBufferShellIntent: Bool,
        shouldDeferRendererRealCommandBufferShellIntent: Bool,
        shouldReportRendererRealCommandBufferShellIntentBlocked: Bool,
        didPreserveRendererNoRealDrawableShellReadiness: Bool,
        didDefineFutureCommandBufferShellIntent: Bool,
        didDescribeCommandBufferCreationAdmissionNeed: Bool,
        didDescribeCommitDenialNeed: Bool,
        didDescribeCompletionDenialNeed: Bool,
        didDescribeCommandBufferFailureClassificationNeed: Bool,
        didKeepCommandBufferShellIntentDehydrated: Bool,
        didAvoidCommandBufferReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noRealDrawableShellReadiness = noRealDrawableShellReadiness
        this.didPrepareRendererRealCommandBufferShellIntent =
            didPrepareRendererRealCommandBufferShellIntent
        this.shouldDeferRendererRealCommandBufferShellIntent =
            shouldDeferRendererRealCommandBufferShellIntent
        this.shouldReportRendererRealCommandBufferShellIntentBlocked =
            shouldReportRendererRealCommandBufferShellIntentBlocked
        this.didPreserveRendererNoRealDrawableShellReadiness =
            didPreserveRendererNoRealDrawableShellReadiness
        this.didDefineFutureCommandBufferShellIntent =
            didDefineFutureCommandBufferShellIntent
        this.didDescribeCommandBufferCreationAdmissionNeed =
            didDescribeCommandBufferCreationAdmissionNeed
        this.didDescribeCommitDenialNeed = didDescribeCommitDenialNeed
        this.didDescribeCompletionDenialNeed =
            didDescribeCompletionDenialNeed
        this.didDescribeCommandBufferFailureClassificationNeed =
            didDescribeCommandBufferFailureClassificationNeed
        this.didKeepCommandBufferShellIntentDehydrated =
            didKeepCommandBufferShellIntentDehydrated
        this.didAvoidCommandBufferReadyWrapper =
            didAvoidCommandBufferReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealCommandBufferCreationAdmissionShell {
    let shellIntent:
        CjguiInternalRendererRealCommandBufferShellIntent
    let didPrepareRendererRealCommandBufferCreationAdmissionShell: Bool
    let shouldDeferRendererRealCommandBufferCreationAdmissionShell: Bool
    let shouldReportRendererRealCommandBufferCreationAdmissionShellBlocked:
        Bool
    let didPreserveRendererRealCommandBufferShellIntent: Bool
    let didDefineOwnerLocalCommandBufferCreationAdmissionShell: Bool
    let didConfirmNoConcreteCommandBufferObject: Bool
    let didConfirmNoCommandQueueFactoryInvocation: Bool
    let didConfirmNoEncodingRelation: Bool
    let didKeepCommandBufferCreationAdmissionShellDehydrated: Bool
    let didAvoidCommandBufferReadyWrapper: Bool
    let didAvoidWorkSubmitWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        shellIntent:
            CjguiInternalRendererRealCommandBufferShellIntent,
        didPrepareRendererRealCommandBufferCreationAdmissionShell: Bool,
        shouldDeferRendererRealCommandBufferCreationAdmissionShell: Bool,
        shouldReportRendererRealCommandBufferCreationAdmissionShellBlocked:
            Bool,
        didPreserveRendererRealCommandBufferShellIntent: Bool,
        didDefineOwnerLocalCommandBufferCreationAdmissionShell: Bool,
        didConfirmNoConcreteCommandBufferObject: Bool,
        didConfirmNoCommandQueueFactoryInvocation: Bool,
        didConfirmNoEncodingRelation: Bool,
        didKeepCommandBufferCreationAdmissionShellDehydrated: Bool,
        didAvoidCommandBufferReadyWrapper: Bool,
        didAvoidWorkSubmitWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.shellIntent = shellIntent
        this.didPrepareRendererRealCommandBufferCreationAdmissionShell =
            didPrepareRendererRealCommandBufferCreationAdmissionShell
        this.shouldDeferRendererRealCommandBufferCreationAdmissionShell =
            shouldDeferRendererRealCommandBufferCreationAdmissionShell
        this
            .shouldReportRendererRealCommandBufferCreationAdmissionShellBlocked =
            shouldReportRendererRealCommandBufferCreationAdmissionShellBlocked
        this.didPreserveRendererRealCommandBufferShellIntent =
            didPreserveRendererRealCommandBufferShellIntent
        this.didDefineOwnerLocalCommandBufferCreationAdmissionShell =
            didDefineOwnerLocalCommandBufferCreationAdmissionShell
        this.didConfirmNoConcreteCommandBufferObject =
            didConfirmNoConcreteCommandBufferObject
        this.didConfirmNoCommandQueueFactoryInvocation =
            didConfirmNoCommandQueueFactoryInvocation
        this.didConfirmNoEncodingRelation = didConfirmNoEncodingRelation
        this.didKeepCommandBufferCreationAdmissionShellDehydrated =
            didKeepCommandBufferCreationAdmissionShellDehydrated
        this.didAvoidCommandBufferReadyWrapper =
            didAvoidCommandBufferReadyWrapper
        this.didAvoidWorkSubmitWrapper = didAvoidWorkSubmitWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealCommandBufferCommitDenialProof {
    let creationAdmissionShell:
        CjguiInternalRendererRealCommandBufferCreationAdmissionShell
    let didPrepareRendererRealCommandBufferCommitDenialProof: Bool
    let shouldDeferRendererRealCommandBufferCommitDenialProof: Bool
    let shouldReportRendererRealCommandBufferCommitDenialProofBlocked: Bool
    let didPreserveRendererRealCommandBufferCreationAdmissionShell: Bool
    let didDefineOwnerLocalCommitDenialProof: Bool
    let didConfirmNoCommitInvocation: Bool
    let didConfirmNoWorkSubmit: Bool
    let didConfirmNoPresentationRelation: Bool
    let didKeepCommitDenialProofDehydrated: Bool
    let didAvoidCommitPermissionWrapper: Bool
    let didAvoidWorkSubmitWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        creationAdmissionShell:
            CjguiInternalRendererRealCommandBufferCreationAdmissionShell,
        didPrepareRendererRealCommandBufferCommitDenialProof: Bool,
        shouldDeferRendererRealCommandBufferCommitDenialProof: Bool,
        shouldReportRendererRealCommandBufferCommitDenialProofBlocked: Bool,
        didPreserveRendererRealCommandBufferCreationAdmissionShell: Bool,
        didDefineOwnerLocalCommitDenialProof: Bool,
        didConfirmNoCommitInvocation: Bool,
        didConfirmNoWorkSubmit: Bool,
        didConfirmNoPresentationRelation: Bool,
        didKeepCommitDenialProofDehydrated: Bool,
        didAvoidCommitPermissionWrapper: Bool,
        didAvoidWorkSubmitWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.creationAdmissionShell = creationAdmissionShell
        this.didPrepareRendererRealCommandBufferCommitDenialProof =
            didPrepareRendererRealCommandBufferCommitDenialProof
        this.shouldDeferRendererRealCommandBufferCommitDenialProof =
            shouldDeferRendererRealCommandBufferCommitDenialProof
        this.shouldReportRendererRealCommandBufferCommitDenialProofBlocked =
            shouldReportRendererRealCommandBufferCommitDenialProofBlocked
        this.didPreserveRendererRealCommandBufferCreationAdmissionShell =
            didPreserveRendererRealCommandBufferCreationAdmissionShell
        this.didDefineOwnerLocalCommitDenialProof =
            didDefineOwnerLocalCommitDenialProof
        this.didConfirmNoCommitInvocation = didConfirmNoCommitInvocation
        this.didConfirmNoWorkSubmit = didConfirmNoWorkSubmit
        this.didConfirmNoPresentationRelation =
            didConfirmNoPresentationRelation
        this.didKeepCommitDenialProofDehydrated =
            didKeepCommitDenialProofDehydrated
        this.didAvoidCommitPermissionWrapper =
            didAvoidCommitPermissionWrapper
        this.didAvoidWorkSubmitWrapper = didAvoidWorkSubmitWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealCommandBufferCompletionDenialProof {
    let commitDenialProof:
        CjguiInternalRendererRealCommandBufferCommitDenialProof
    let didPrepareRendererRealCommandBufferCompletionDenialProof: Bool
    let shouldDeferRendererRealCommandBufferCompletionDenialProof: Bool
    let shouldReportRendererRealCommandBufferCompletionDenialProofBlocked:
        Bool
    let didPreserveRendererRealCommandBufferCommitDenialProof: Bool
    let didDefineOwnerLocalCompletionDenialProof: Bool
    let didConfirmNoCompletionCallback: Bool
    let didConfirmNoGpuCompletionObservation: Bool
    let didConfirmNoStateVisibilityPublication: Bool
    let didKeepCompletionDenialProofDehydrated: Bool
    let didAvoidCompletionPermissionWrapper: Bool
    let didAvoidStateMutationWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        commitDenialProof:
            CjguiInternalRendererRealCommandBufferCommitDenialProof,
        didPrepareRendererRealCommandBufferCompletionDenialProof: Bool,
        shouldDeferRendererRealCommandBufferCompletionDenialProof: Bool,
        shouldReportRendererRealCommandBufferCompletionDenialProofBlocked:
            Bool,
        didPreserveRendererRealCommandBufferCommitDenialProof: Bool,
        didDefineOwnerLocalCompletionDenialProof: Bool,
        didConfirmNoCompletionCallback: Bool,
        didConfirmNoGpuCompletionObservation: Bool,
        didConfirmNoStateVisibilityPublication: Bool,
        didKeepCompletionDenialProofDehydrated: Bool,
        didAvoidCompletionPermissionWrapper: Bool,
        didAvoidStateMutationWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.commitDenialProof = commitDenialProof
        this.didPrepareRendererRealCommandBufferCompletionDenialProof =
            didPrepareRendererRealCommandBufferCompletionDenialProof
        this.shouldDeferRendererRealCommandBufferCompletionDenialProof =
            shouldDeferRendererRealCommandBufferCompletionDenialProof
        this
            .shouldReportRendererRealCommandBufferCompletionDenialProofBlocked =
            shouldReportRendererRealCommandBufferCompletionDenialProofBlocked
        this.didPreserveRendererRealCommandBufferCommitDenialProof =
            didPreserveRendererRealCommandBufferCommitDenialProof
        this.didDefineOwnerLocalCompletionDenialProof =
            didDefineOwnerLocalCompletionDenialProof
        this.didConfirmNoCompletionCallback =
            didConfirmNoCompletionCallback
        this.didConfirmNoGpuCompletionObservation =
            didConfirmNoGpuCompletionObservation
        this.didConfirmNoStateVisibilityPublication =
            didConfirmNoStateVisibilityPublication
        this.didKeepCompletionDenialProofDehydrated =
            didKeepCompletionDenialProofDehydrated
        this.didAvoidCompletionPermissionWrapper =
            didAvoidCompletionPermissionWrapper
        this.didAvoidStateMutationWrapper = didAvoidStateMutationWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealCommandBufferTeardownFailureClassification {
    let completionDenialProof:
        CjguiInternalRendererRealCommandBufferCompletionDenialProof
    let didPrepareRendererRealCommandBufferTeardownFailureClassification:
        Bool
    let shouldDeferRendererRealCommandBufferTeardownFailureClassification:
        Bool
    let shouldReportRendererRealCommandBufferTeardownFailureClassificationBlocked:
        Bool
    let didPreserveRendererRealCommandBufferCompletionDenialProof: Bool
    let didDefineOwnerLocalCommandBufferTeardownFailureClassification: Bool
    let didFailClosedMissingCommandBuffer: Bool
    let didFailClosedWrongThreadRisk: Bool
    let didFailClosedStaleCommandBufferRisk: Bool
    let didFailClosedBridgeOptimism: Bool
    let didConfirmNoFailurePublication: Bool
    let didConfirmNoPublicDiagnostics: Bool
    let didKeepCommandBufferTeardownFailureDehydrated: Bool
    let didAvoidCommandBufferReadyWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        completionDenialProof:
            CjguiInternalRendererRealCommandBufferCompletionDenialProof,
        didPrepareRendererRealCommandBufferTeardownFailureClassification:
            Bool,
        shouldDeferRendererRealCommandBufferTeardownFailureClassification:
            Bool,
        shouldReportRendererRealCommandBufferTeardownFailureClassificationBlocked:
            Bool,
        didPreserveRendererRealCommandBufferCompletionDenialProof: Bool,
        didDefineOwnerLocalCommandBufferTeardownFailureClassification: Bool,
        didFailClosedMissingCommandBuffer: Bool,
        didFailClosedWrongThreadRisk: Bool,
        didFailClosedStaleCommandBufferRisk: Bool,
        didFailClosedBridgeOptimism: Bool,
        didConfirmNoFailurePublication: Bool,
        didConfirmNoPublicDiagnostics: Bool,
        didKeepCommandBufferTeardownFailureDehydrated: Bool,
        didAvoidCommandBufferReadyWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.completionDenialProof = completionDenialProof
        this
            .didPrepareRendererRealCommandBufferTeardownFailureClassification =
            didPrepareRendererRealCommandBufferTeardownFailureClassification
        this
            .shouldDeferRendererRealCommandBufferTeardownFailureClassification =
            shouldDeferRendererRealCommandBufferTeardownFailureClassification
        this
            .shouldReportRendererRealCommandBufferTeardownFailureClassificationBlocked =
            shouldReportRendererRealCommandBufferTeardownFailureClassificationBlocked
        this.didPreserveRendererRealCommandBufferCompletionDenialProof =
            didPreserveRendererRealCommandBufferCompletionDenialProof
        this
            .didDefineOwnerLocalCommandBufferTeardownFailureClassification =
            didDefineOwnerLocalCommandBufferTeardownFailureClassification
        this.didFailClosedMissingCommandBuffer =
            didFailClosedMissingCommandBuffer
        this.didFailClosedWrongThreadRisk = didFailClosedWrongThreadRisk
        this.didFailClosedStaleCommandBufferRisk =
            didFailClosedStaleCommandBufferRisk
        this.didFailClosedBridgeOptimism = didFailClosedBridgeOptimism
        this.didConfirmNoFailurePublication =
            didConfirmNoFailurePublication
        this.didConfirmNoPublicDiagnostics = didConfirmNoPublicDiagnostics
        this.didKeepCommandBufferTeardownFailureDehydrated =
            didKeepCommandBufferTeardownFailureDehydrated
        this.didAvoidCommandBufferReadyWrapper =
            didAvoidCommandBufferReadyWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoRealCommandBufferShellReadiness {
    let teardownFailureClassification:
        CjguiInternalRendererRealCommandBufferTeardownFailureClassification
    let isRendererNoRealCommandBufferShellReady: Bool
    let canFutureRendererRealCommandBufferShellBoundaryEvaluate: Bool
    let shouldDeferRendererNoRealCommandBufferShellReadiness: Bool
    let shouldReportRendererNoRealCommandBufferShellReadinessBlocked: Bool
    let didSealRendererNoRealCommandBufferShellReadiness: Bool
    let didPreserveRendererRealCommandBufferTeardownFailureClassification:
        Bool
    let didKeepNoRealCommandBufferShellReadinessDehydrated: Bool
    let didConfirmNoConcreteCommandBufferObject: Bool
    let didConfirmNoCommandBufferFactoryInvocation: Bool
    let didConfirmNoCommitInvocation: Bool
    let didConfirmNoPresentationCall: Bool
    let didConfirmNoDrawableAcquisition: Bool
    let didConfirmNoEncodingObject: Bool
    let didConfirmNoRenderPassObject: Bool
    let didConfirmNoPipelineObject: Bool
    let didConfirmNoDrawCall: Bool
    let didConfirmNoWorkSubmit: Bool
    let didConfirmNoNativeResourceStored: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoStateMutation: Bool
    let didConfirmNoRuntimeStateTouch: Bool
    let didConfirmNoModuleLevelMutableState: Bool
    let didConfirmNoPublicDiagnostics: Bool
    let didAvoidCommandBufferReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidWorkSubmitWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidStateMutationWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        teardownFailureClassification:
            CjguiInternalRendererRealCommandBufferTeardownFailureClassification,
        isRendererNoRealCommandBufferShellReady: Bool,
        canFutureRendererRealCommandBufferShellBoundaryEvaluate: Bool,
        shouldDeferRendererNoRealCommandBufferShellReadiness: Bool,
        shouldReportRendererNoRealCommandBufferShellReadinessBlocked: Bool,
        didSealRendererNoRealCommandBufferShellReadiness: Bool,
        didPreserveRendererRealCommandBufferTeardownFailureClassification:
            Bool,
        didKeepNoRealCommandBufferShellReadinessDehydrated: Bool,
        didConfirmNoConcreteCommandBufferObject: Bool,
        didConfirmNoCommandBufferFactoryInvocation: Bool,
        didConfirmNoCommitInvocation: Bool,
        didConfirmNoPresentationCall: Bool,
        didConfirmNoDrawableAcquisition: Bool,
        didConfirmNoEncodingObject: Bool,
        didConfirmNoRenderPassObject: Bool,
        didConfirmNoPipelineObject: Bool,
        didConfirmNoDrawCall: Bool,
        didConfirmNoWorkSubmit: Bool,
        didConfirmNoNativeResourceStored: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoStateMutation: Bool,
        didConfirmNoRuntimeStateTouch: Bool,
        didConfirmNoModuleLevelMutableState: Bool,
        didConfirmNoPublicDiagnostics: Bool,
        didAvoidCommandBufferReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidWorkSubmitWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidStateMutationWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.teardownFailureClassification = teardownFailureClassification
        this.isRendererNoRealCommandBufferShellReady =
            isRendererNoRealCommandBufferShellReady
        this.canFutureRendererRealCommandBufferShellBoundaryEvaluate =
            canFutureRendererRealCommandBufferShellBoundaryEvaluate
        this.shouldDeferRendererNoRealCommandBufferShellReadiness =
            shouldDeferRendererNoRealCommandBufferShellReadiness
        this.shouldReportRendererNoRealCommandBufferShellReadinessBlocked =
            shouldReportRendererNoRealCommandBufferShellReadinessBlocked
        this.didSealRendererNoRealCommandBufferShellReadiness =
            didSealRendererNoRealCommandBufferShellReadiness
        this
            .didPreserveRendererRealCommandBufferTeardownFailureClassification =
            didPreserveRendererRealCommandBufferTeardownFailureClassification
        this.didKeepNoRealCommandBufferShellReadinessDehydrated =
            didKeepNoRealCommandBufferShellReadinessDehydrated
        this.didConfirmNoConcreteCommandBufferObject =
            didConfirmNoConcreteCommandBufferObject
        this.didConfirmNoCommandBufferFactoryInvocation =
            didConfirmNoCommandBufferFactoryInvocation
        this.didConfirmNoCommitInvocation = didConfirmNoCommitInvocation
        this.didConfirmNoPresentationCall = didConfirmNoPresentationCall
        this.didConfirmNoDrawableAcquisition =
            didConfirmNoDrawableAcquisition
        this.didConfirmNoEncodingObject = didConfirmNoEncodingObject
        this.didConfirmNoRenderPassObject = didConfirmNoRenderPassObject
        this.didConfirmNoPipelineObject = didConfirmNoPipelineObject
        this.didConfirmNoDrawCall = didConfirmNoDrawCall
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
        this.didAvoidCommandBufferReadyWrapper =
            didAvoidCommandBufferReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidWorkSubmitWrapper = didAvoidWorkSubmitWrapper
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidStateMutationWrapper = didAvoidStateMutationWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererRealCommandBufferShellIntent(
    noRealDrawableShellReadiness:
        CjguiInternalRendererNoRealDrawableShellReadiness
): CjguiInternalRendererRealCommandBufferShellIntent {
    let upstreamReady =
        noRealDrawableShellReadiness.isRendererNoRealDrawableShellReady &&
        noRealDrawableShellReadiness
            .canFutureRendererRealDrawableShellBoundaryEvaluate &&
        noRealDrawableShellReadiness
            .didSealRendererNoRealDrawableShellReadiness &&
        noRealDrawableShellReadiness
            .didPreserveRendererDrawableTeardownFailureClassification &&
        noRealDrawableShellReadiness
            .didKeepNoRealDrawableShellReadinessDehydrated &&
        noRealDrawableShellReadiness.didConfirmNoDrawableAcquisition &&
        noRealDrawableShellReadiness.didConfirmNoDrawableTextureExposure &&
        noRealDrawableShellReadiness.didConfirmNoPresentationCall &&
        noRealDrawableShellReadiness.didConfirmNoCommandBufferCreation &&
        noRealDrawableShellReadiness.didConfirmNoWorkSubmit &&
        noRealDrawableShellReadiness.didConfirmNoNativeResourceStored &&
        noRealDrawableShellReadiness.didConfirmNoPointerLikeResource &&
        noRealDrawableShellReadiness.didConfirmNoRenderExecution &&
        noRealDrawableShellReadiness.didConfirmNoStateMutation &&
        noRealDrawableShellReadiness.didConfirmNoRuntimeStateTouch &&
        noRealDrawableShellReadiness
            .didConfirmNoModuleLevelMutableState &&
        noRealDrawableShellReadiness.didConfirmNoPublicDiagnostics &&
        noRealDrawableShellReadiness.didAvoidDrawableReadyWrapper &&
        noRealDrawableShellReadiness.didAvoidQueueReadyWrapper &&
        noRealDrawableShellReadiness.didAvoidNativeHandleWrapper &&
        noRealDrawableShellReadiness.didAvoidWorkSubmitWrapper &&
        noRealDrawableShellReadiness.didAvoidRenderPermissionWrapper &&
        noRealDrawableShellReadiness.didAvoidStateMutationWrapper &&
        noRealDrawableShellReadiness.didAvoidReceiptRecordOutput &&
        noRealDrawableShellReadiness.didAvoidThinWrapper &&
        noRealDrawableShellReadiness
            .shouldDeferRendererNoRealDrawableShellReadiness == false &&
        noRealDrawableShellReadiness
            .shouldReportRendererNoRealDrawableShellReadinessBlocked ==
            false
    let upstreamDeferred =
        noRealDrawableShellReadiness.isRendererNoRealDrawableShellReady ==
            false &&
        noRealDrawableShellReadiness
            .canFutureRendererRealDrawableShellBoundaryEvaluate == false &&
        noRealDrawableShellReadiness
            .shouldDeferRendererNoRealDrawableShellReadiness &&
        noRealDrawableShellReadiness
            .shouldReportRendererNoRealDrawableShellReadinessBlocked ==
            false
    let upstreamInconsistent =
        noRealDrawableShellReadiness
            .shouldReportRendererNoRealDrawableShellReadinessBlocked ||
        (
            noRealDrawableShellReadiness.isRendererNoRealDrawableShellReady &&
            (
                upstreamReady == false ||
                noRealDrawableShellReadiness
                    .shouldDeferRendererNoRealDrawableShellReadiness
            )
        ) ||
        (
            noRealDrawableShellReadiness
                .canFutureRendererRealDrawableShellBoundaryEvaluate &&
            noRealDrawableShellReadiness
                .isRendererNoRealDrawableShellReady == false
        )

    if (upstreamInconsistent) {
        return CjguiInternalRendererRealCommandBufferShellIntent(
            noRealDrawableShellReadiness,
            false,
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

    if (upstreamReady) {
        return CjguiInternalRendererRealCommandBufferShellIntent(
            noRealDrawableShellReadiness,
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

    if (upstreamDeferred) {
        return CjguiInternalRendererRealCommandBufferShellIntent(
            noRealDrawableShellReadiness,
            false,
            true,
            false,
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

    return CjguiInternalRendererRealCommandBufferShellIntent(
        noRealDrawableShellReadiness,
        false,
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

func cjguiInternalBuildRendererRealCommandBufferCreationAdmissionShell(
    shellIntent:
        CjguiInternalRendererRealCommandBufferShellIntent
): CjguiInternalRendererRealCommandBufferCreationAdmissionShell {
    let intentReady =
        shellIntent.didPrepareRendererRealCommandBufferShellIntent &&
        shellIntent.didPreserveRendererNoRealDrawableShellReadiness &&
        shellIntent.didDefineFutureCommandBufferShellIntent &&
        shellIntent.didDescribeCommandBufferCreationAdmissionNeed &&
        shellIntent.didDescribeCommitDenialNeed &&
        shellIntent.didDescribeCompletionDenialNeed &&
        shellIntent.didDescribeCommandBufferFailureClassificationNeed &&
        shellIntent.didKeepCommandBufferShellIntentDehydrated &&
        shellIntent.didAvoidCommandBufferReadyWrapper &&
        shellIntent.didAvoidDrawableReadyWrapper &&
        shellIntent.didAvoidReceiptRecordOutput &&
        shellIntent.didAvoidThinWrapper &&
        shellIntent.shouldDeferRendererRealCommandBufferShellIntent ==
            false &&
        shellIntent
            .shouldReportRendererRealCommandBufferShellIntentBlocked ==
            false
    let intentDeferred =
        shellIntent.didPrepareRendererRealCommandBufferShellIntent == false &&
        shellIntent.shouldDeferRendererRealCommandBufferShellIntent &&
        shellIntent
            .shouldReportRendererRealCommandBufferShellIntentBlocked ==
            false
    let intentInconsistent =
        shellIntent
            .shouldReportRendererRealCommandBufferShellIntentBlocked ||
        (
            shellIntent.didPrepareRendererRealCommandBufferShellIntent &&
            intentReady == false
        )

    return CjguiInternalRendererRealCommandBufferCreationAdmissionShell(
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

func cjguiInternalBuildRendererRealCommandBufferCommitDenialProof(
    creationAdmissionShell:
        CjguiInternalRendererRealCommandBufferCreationAdmissionShell
): CjguiInternalRendererRealCommandBufferCommitDenialProof {
    let shellReady =
        creationAdmissionShell
            .didPrepareRendererRealCommandBufferCreationAdmissionShell &&
        creationAdmissionShell
            .didPreserveRendererRealCommandBufferShellIntent &&
        creationAdmissionShell
            .didDefineOwnerLocalCommandBufferCreationAdmissionShell &&
        creationAdmissionShell.didConfirmNoConcreteCommandBufferObject &&
        creationAdmissionShell.didConfirmNoCommandQueueFactoryInvocation &&
        creationAdmissionShell.didConfirmNoEncodingRelation &&
        creationAdmissionShell
            .didKeepCommandBufferCreationAdmissionShellDehydrated &&
        creationAdmissionShell.didAvoidCommandBufferReadyWrapper &&
        creationAdmissionShell.didAvoidWorkSubmitWrapper &&
        creationAdmissionShell.didAvoidThinWrapper &&
        creationAdmissionShell
            .shouldDeferRendererRealCommandBufferCreationAdmissionShell ==
            false &&
        creationAdmissionShell
            .shouldReportRendererRealCommandBufferCreationAdmissionShellBlocked ==
            false
    let shellDeferred =
        creationAdmissionShell
            .didPrepareRendererRealCommandBufferCreationAdmissionShell ==
            false &&
        creationAdmissionShell
            .shouldDeferRendererRealCommandBufferCreationAdmissionShell &&
        creationAdmissionShell
            .shouldReportRendererRealCommandBufferCreationAdmissionShellBlocked ==
            false
    let shellInconsistent =
        creationAdmissionShell
            .shouldReportRendererRealCommandBufferCreationAdmissionShellBlocked ||
        (
            creationAdmissionShell
                .didPrepareRendererRealCommandBufferCreationAdmissionShell &&
            shellReady == false
        )

    return CjguiInternalRendererRealCommandBufferCommitDenialProof(
        creationAdmissionShell,
        shellReady,
        shellDeferred,
        shellInconsistent,
        shellReady,
        shellReady,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererRealCommandBufferCompletionDenialProof(
    commitDenialProof:
        CjguiInternalRendererRealCommandBufferCommitDenialProof
): CjguiInternalRendererRealCommandBufferCompletionDenialProof {
    let denialReady =
        commitDenialProof
            .didPrepareRendererRealCommandBufferCommitDenialProof &&
        commitDenialProof
            .didPreserveRendererRealCommandBufferCreationAdmissionShell &&
        commitDenialProof.didDefineOwnerLocalCommitDenialProof &&
        commitDenialProof.didConfirmNoCommitInvocation &&
        commitDenialProof.didConfirmNoWorkSubmit &&
        commitDenialProof.didConfirmNoPresentationRelation &&
        commitDenialProof.didKeepCommitDenialProofDehydrated &&
        commitDenialProof.didAvoidCommitPermissionWrapper &&
        commitDenialProof.didAvoidWorkSubmitWrapper &&
        commitDenialProof.didAvoidThinWrapper &&
        commitDenialProof
            .shouldDeferRendererRealCommandBufferCommitDenialProof == false &&
        commitDenialProof
            .shouldReportRendererRealCommandBufferCommitDenialProofBlocked ==
            false
    let denialDeferred =
        commitDenialProof
            .didPrepareRendererRealCommandBufferCommitDenialProof == false &&
        commitDenialProof
            .shouldDeferRendererRealCommandBufferCommitDenialProof &&
        commitDenialProof
            .shouldReportRendererRealCommandBufferCommitDenialProofBlocked ==
            false
    let denialInconsistent =
        commitDenialProof
            .shouldReportRendererRealCommandBufferCommitDenialProofBlocked ||
        (
            commitDenialProof
                .didPrepareRendererRealCommandBufferCommitDenialProof &&
            denialReady == false
        )

    return CjguiInternalRendererRealCommandBufferCompletionDenialProof(
        commitDenialProof,
        denialReady,
        denialDeferred,
        denialInconsistent,
        denialReady,
        denialReady,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererRealCommandBufferTeardownFailureClassification(
    completionDenialProof:
        CjguiInternalRendererRealCommandBufferCompletionDenialProof
): CjguiInternalRendererRealCommandBufferTeardownFailureClassification {
    let proofReady =
        completionDenialProof
            .didPrepareRendererRealCommandBufferCompletionDenialProof &&
        completionDenialProof
            .didPreserveRendererRealCommandBufferCommitDenialProof &&
        completionDenialProof.didDefineOwnerLocalCompletionDenialProof &&
        completionDenialProof.didConfirmNoCompletionCallback &&
        completionDenialProof.didConfirmNoGpuCompletionObservation &&
        completionDenialProof.didConfirmNoStateVisibilityPublication &&
        completionDenialProof.didKeepCompletionDenialProofDehydrated &&
        completionDenialProof.didAvoidCompletionPermissionWrapper &&
        completionDenialProof.didAvoidStateMutationWrapper &&
        completionDenialProof.didAvoidThinWrapper &&
        completionDenialProof
            .shouldDeferRendererRealCommandBufferCompletionDenialProof ==
            false &&
        completionDenialProof
            .shouldReportRendererRealCommandBufferCompletionDenialProofBlocked ==
            false
    let proofDeferred =
        completionDenialProof
            .didPrepareRendererRealCommandBufferCompletionDenialProof ==
            false &&
        completionDenialProof
            .shouldDeferRendererRealCommandBufferCompletionDenialProof &&
        completionDenialProof
            .shouldReportRendererRealCommandBufferCompletionDenialProofBlocked ==
            false
    let proofInconsistent =
        completionDenialProof
            .shouldReportRendererRealCommandBufferCompletionDenialProofBlocked ||
        (
            completionDenialProof
                .didPrepareRendererRealCommandBufferCompletionDenialProof &&
            proofReady == false
        )

    return CjguiInternalRendererRealCommandBufferTeardownFailureClassification(
        completionDenialProof,
        proofReady,
        proofDeferred,
        proofInconsistent,
        proofReady,
        proofReady,
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

func cjguiInternalBuildRendererNoRealCommandBufferShellReadiness(
    teardownFailureClassification:
        CjguiInternalRendererRealCommandBufferTeardownFailureClassification
): CjguiInternalRendererNoRealCommandBufferShellReadiness {
    let failureReady =
        teardownFailureClassification
            .didPrepareRendererRealCommandBufferTeardownFailureClassification &&
        teardownFailureClassification
            .didPreserveRendererRealCommandBufferCompletionDenialProof &&
        teardownFailureClassification
            .didDefineOwnerLocalCommandBufferTeardownFailureClassification &&
        teardownFailureClassification.didFailClosedMissingCommandBuffer &&
        teardownFailureClassification.didFailClosedWrongThreadRisk &&
        teardownFailureClassification.didFailClosedStaleCommandBufferRisk &&
        teardownFailureClassification.didFailClosedBridgeOptimism &&
        teardownFailureClassification.didConfirmNoFailurePublication &&
        teardownFailureClassification.didConfirmNoPublicDiagnostics &&
        teardownFailureClassification
            .didKeepCommandBufferTeardownFailureDehydrated &&
        teardownFailureClassification.didAvoidCommandBufferReadyWrapper &&
        teardownFailureClassification.didAvoidReceiptRecordOutput &&
        teardownFailureClassification.didAvoidThinWrapper &&
        teardownFailureClassification
            .shouldDeferRendererRealCommandBufferTeardownFailureClassification ==
            false &&
        teardownFailureClassification
            .shouldReportRendererRealCommandBufferTeardownFailureClassificationBlocked ==
            false
    let failureDeferred =
        teardownFailureClassification
            .didPrepareRendererRealCommandBufferTeardownFailureClassification ==
            false &&
        teardownFailureClassification
            .shouldDeferRendererRealCommandBufferTeardownFailureClassification &&
        teardownFailureClassification
            .shouldReportRendererRealCommandBufferTeardownFailureClassificationBlocked ==
            false
    let failureInconsistent =
        teardownFailureClassification
            .shouldReportRendererRealCommandBufferTeardownFailureClassificationBlocked ||
        (
            teardownFailureClassification
                .didPrepareRendererRealCommandBufferTeardownFailureClassification &&
            failureReady == false
        )

    return CjguiInternalRendererNoRealCommandBufferShellReadiness(
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
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererRealCommandBufferShellDraft():
    CjguiInternalRendererNoRealCommandBufferShellReadiness {
    let noRealDrawableShellReadiness =
        cjguiInternalExecuteDefaultRendererRealDrawableShellDraft()
    let shellIntent =
        cjguiInternalBuildRendererRealCommandBufferShellIntent(
            noRealDrawableShellReadiness
        )
    let creationAdmissionShell =
        cjguiInternalBuildRendererRealCommandBufferCreationAdmissionShell(
            shellIntent
        )
    let commitDenialProof =
        cjguiInternalBuildRendererRealCommandBufferCommitDenialProof(
            creationAdmissionShell
        )
    let completionDenialProof =
        cjguiInternalBuildRendererRealCommandBufferCompletionDenialProof(
            commitDenialProof
        )
    let teardownFailureClassification =
        cjguiInternalBuildRendererRealCommandBufferTeardownFailureClassification(
            completionDenialProof
        )
    return cjguiInternalBuildRendererNoRealCommandBufferShellReadiness(
        teardownFailureClassification
    )
}
