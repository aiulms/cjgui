// Owner: real command queue 第一刀 internal-only shell 边界。
// Truth: 只消费 CjguiInternalRendererNoRealMetalDeviceLayerReadiness，并记录
// command queue shell intent、creation admission shell、ownership proof、
// teardown proof、failure classification 与 no-real-command-queue shell
// readiness facts。
// Stop-line: 只产出 internal-only shell / dehydrated facts；不是
// MTLCommandQueue 或 newCommandQueue 许可，不创建 native resource，不开放跨语言
// surface，不执行 graphics work，不写 state，不触碰 runtime state，不发布 public surface。
// Same-shape Boundary Brake: 不得把本 shell 包成 queue-ready、backend-ready、
// native-handle-ready、GPU-submission、render-permission、receipt、record 或
// publication wrapper。
package cjgui

struct CjguiInternalRendererRealCommandQueueShellIntent {
    let noRealMetalDeviceLayerReadiness:
        CjguiInternalRendererNoRealMetalDeviceLayerReadiness
    let didPrepareRendererRealCommandQueueShellIntent: Bool
    let shouldDeferRendererRealCommandQueueShellIntent: Bool
    let shouldReportRendererRealCommandQueueShellIntentBlocked: Bool
    let didPreserveRendererNoRealMetalDeviceLayerReadiness: Bool
    let didDefineFutureRealCommandQueueShellIntent: Bool
    let didDescribeQueueCreationAdmissionShellNeed: Bool
    let didDescribeQueueOwnershipProofNeed: Bool
    let didDescribeQueueTeardownProofNeed: Bool
    let didDescribeQueueFailureClassificationNeed: Bool
    let didKeepRealCommandQueueShellIntentDehydrated: Bool
    let didAvoidQueueReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        noRealMetalDeviceLayerReadiness:
            CjguiInternalRendererNoRealMetalDeviceLayerReadiness,
        didPrepareRendererRealCommandQueueShellIntent: Bool,
        shouldDeferRendererRealCommandQueueShellIntent: Bool,
        shouldReportRendererRealCommandQueueShellIntentBlocked: Bool,
        didPreserveRendererNoRealMetalDeviceLayerReadiness: Bool,
        didDefineFutureRealCommandQueueShellIntent: Bool,
        didDescribeQueueCreationAdmissionShellNeed: Bool,
        didDescribeQueueOwnershipProofNeed: Bool,
        didDescribeQueueTeardownProofNeed: Bool,
        didDescribeQueueFailureClassificationNeed: Bool,
        didKeepRealCommandQueueShellIntentDehydrated: Bool,
        didAvoidQueueReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noRealMetalDeviceLayerReadiness =
            noRealMetalDeviceLayerReadiness
        this.didPrepareRendererRealCommandQueueShellIntent =
            didPrepareRendererRealCommandQueueShellIntent
        this.shouldDeferRendererRealCommandQueueShellIntent =
            shouldDeferRendererRealCommandQueueShellIntent
        this.shouldReportRendererRealCommandQueueShellIntentBlocked =
            shouldReportRendererRealCommandQueueShellIntentBlocked
        this.didPreserveRendererNoRealMetalDeviceLayerReadiness =
            didPreserveRendererNoRealMetalDeviceLayerReadiness
        this.didDefineFutureRealCommandQueueShellIntent =
            didDefineFutureRealCommandQueueShellIntent
        this.didDescribeQueueCreationAdmissionShellNeed =
            didDescribeQueueCreationAdmissionShellNeed
        this.didDescribeQueueOwnershipProofNeed =
            didDescribeQueueOwnershipProofNeed
        this.didDescribeQueueTeardownProofNeed =
            didDescribeQueueTeardownProofNeed
        this.didDescribeQueueFailureClassificationNeed =
            didDescribeQueueFailureClassificationNeed
        this.didKeepRealCommandQueueShellIntentDehydrated =
            didKeepRealCommandQueueShellIntentDehydrated
        this.didAvoidQueueReadyWrapper = didAvoidQueueReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealCommandQueueCreationAdmissionShell {
    let shellIntent:
        CjguiInternalRendererRealCommandQueueShellIntent
    let didPrepareRendererRealCommandQueueCreationAdmissionShell: Bool
    let shouldDeferRendererRealCommandQueueCreationAdmissionShell: Bool
    let shouldReportRendererRealCommandQueueCreationAdmissionShellBlocked:
        Bool
    let didPreserveRendererRealCommandQueueShellIntent: Bool
    let didDefineOwnerLocalQueueCreationAdmissionShell: Bool
    let didConfirmNoConcreteCommandQueueObject: Bool
    let didConfirmNoQueueFactoryCall: Bool
    let didConfirmNoCommandBufferCreation: Bool
    let didKeepQueueCreationAdmissionShellDehydrated: Bool
    let didAvoidQueueReadyWrapper: Bool
    let didAvoidDeviceReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        shellIntent:
            CjguiInternalRendererRealCommandQueueShellIntent,
        didPrepareRendererRealCommandQueueCreationAdmissionShell: Bool,
        shouldDeferRendererRealCommandQueueCreationAdmissionShell: Bool,
        shouldReportRendererRealCommandQueueCreationAdmissionShellBlocked:
            Bool,
        didPreserveRendererRealCommandQueueShellIntent: Bool,
        didDefineOwnerLocalQueueCreationAdmissionShell: Bool,
        didConfirmNoConcreteCommandQueueObject: Bool,
        didConfirmNoQueueFactoryCall: Bool,
        didConfirmNoCommandBufferCreation: Bool,
        didKeepQueueCreationAdmissionShellDehydrated: Bool,
        didAvoidQueueReadyWrapper: Bool,
        didAvoidDeviceReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.shellIntent = shellIntent
        this.didPrepareRendererRealCommandQueueCreationAdmissionShell =
            didPrepareRendererRealCommandQueueCreationAdmissionShell
        this.shouldDeferRendererRealCommandQueueCreationAdmissionShell =
            shouldDeferRendererRealCommandQueueCreationAdmissionShell
        this.shouldReportRendererRealCommandQueueCreationAdmissionShellBlocked =
            shouldReportRendererRealCommandQueueCreationAdmissionShellBlocked
        this.didPreserveRendererRealCommandQueueShellIntent =
            didPreserveRendererRealCommandQueueShellIntent
        this.didDefineOwnerLocalQueueCreationAdmissionShell =
            didDefineOwnerLocalQueueCreationAdmissionShell
        this.didConfirmNoConcreteCommandQueueObject =
            didConfirmNoConcreteCommandQueueObject
        this.didConfirmNoQueueFactoryCall = didConfirmNoQueueFactoryCall
        this.didConfirmNoCommandBufferCreation =
            didConfirmNoCommandBufferCreation
        this.didKeepQueueCreationAdmissionShellDehydrated =
            didKeepQueueCreationAdmissionShellDehydrated
        this.didAvoidQueueReadyWrapper = didAvoidQueueReadyWrapper
        this.didAvoidDeviceReadyWrapper = didAvoidDeviceReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealCommandQueueOwnershipProof {
    let creationAdmissionShell:
        CjguiInternalRendererRealCommandQueueCreationAdmissionShell
    let didPrepareRendererRealCommandQueueOwnershipProof: Bool
    let shouldDeferRendererRealCommandQueueOwnershipProof: Bool
    let shouldReportRendererRealCommandQueueOwnershipProofBlocked: Bool
    let didPreserveRendererRealCommandQueueCreationAdmissionShell: Bool
    let didDefineOwnerLocalQueueOwnershipProof: Bool
    let didDescribeOwnerLocalConfinementProof: Bool
    let didConfirmNoNativeResourceStored: Bool
    let didConfirmNoForeignResourceToken: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didKeepQueueOwnershipProofDehydrated: Bool
    let didAvoidNativeHandleWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        creationAdmissionShell:
            CjguiInternalRendererRealCommandQueueCreationAdmissionShell,
        didPrepareRendererRealCommandQueueOwnershipProof: Bool,
        shouldDeferRendererRealCommandQueueOwnershipProof: Bool,
        shouldReportRendererRealCommandQueueOwnershipProofBlocked: Bool,
        didPreserveRendererRealCommandQueueCreationAdmissionShell: Bool,
        didDefineOwnerLocalQueueOwnershipProof: Bool,
        didDescribeOwnerLocalConfinementProof: Bool,
        didConfirmNoNativeResourceStored: Bool,
        didConfirmNoForeignResourceToken: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didKeepQueueOwnershipProofDehydrated: Bool,
        didAvoidNativeHandleWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.creationAdmissionShell = creationAdmissionShell
        this.didPrepareRendererRealCommandQueueOwnershipProof =
            didPrepareRendererRealCommandQueueOwnershipProof
        this.shouldDeferRendererRealCommandQueueOwnershipProof =
            shouldDeferRendererRealCommandQueueOwnershipProof
        this.shouldReportRendererRealCommandQueueOwnershipProofBlocked =
            shouldReportRendererRealCommandQueueOwnershipProofBlocked
        this.didPreserveRendererRealCommandQueueCreationAdmissionShell =
            didPreserveRendererRealCommandQueueCreationAdmissionShell
        this.didDefineOwnerLocalQueueOwnershipProof =
            didDefineOwnerLocalQueueOwnershipProof
        this.didDescribeOwnerLocalConfinementProof =
            didDescribeOwnerLocalConfinementProof
        this.didConfirmNoNativeResourceStored =
            didConfirmNoNativeResourceStored
        this.didConfirmNoForeignResourceToken =
            didConfirmNoForeignResourceToken
        this.didConfirmNoPointerLikeResource =
            didConfirmNoPointerLikeResource
        this.didKeepQueueOwnershipProofDehydrated =
            didKeepQueueOwnershipProofDehydrated
        this.didAvoidNativeHandleWrapper = didAvoidNativeHandleWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealCommandQueueTeardownProof {
    let ownershipProof:
        CjguiInternalRendererRealCommandQueueOwnershipProof
    let didPrepareRendererRealCommandQueueTeardownProof: Bool
    let shouldDeferRendererRealCommandQueueTeardownProof: Bool
    let shouldReportRendererRealCommandQueueTeardownProofBlocked: Bool
    let didPreserveRendererRealCommandQueueOwnershipProof: Bool
    let didDefineOwnerLocalQueueTeardownProof: Bool
    let didDescribeOrderedCloseProof: Bool
    let didDescribeRepeatableCloseProof: Bool
    let didDescribeFailureSafeCloseProof: Bool
    let didConfirmNoExternalLifecycleCall: Bool
    let didConfirmNoStateMutation: Bool
    let didKeepQueueTeardownProofDehydrated: Bool
    let didAvoidLifecyclePermissionWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        ownershipProof:
            CjguiInternalRendererRealCommandQueueOwnershipProof,
        didPrepareRendererRealCommandQueueTeardownProof: Bool,
        shouldDeferRendererRealCommandQueueTeardownProof: Bool,
        shouldReportRendererRealCommandQueueTeardownProofBlocked: Bool,
        didPreserveRendererRealCommandQueueOwnershipProof: Bool,
        didDefineOwnerLocalQueueTeardownProof: Bool,
        didDescribeOrderedCloseProof: Bool,
        didDescribeRepeatableCloseProof: Bool,
        didDescribeFailureSafeCloseProof: Bool,
        didConfirmNoExternalLifecycleCall: Bool,
        didConfirmNoStateMutation: Bool,
        didKeepQueueTeardownProofDehydrated: Bool,
        didAvoidLifecyclePermissionWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.ownershipProof = ownershipProof
        this.didPrepareRendererRealCommandQueueTeardownProof =
            didPrepareRendererRealCommandQueueTeardownProof
        this.shouldDeferRendererRealCommandQueueTeardownProof =
            shouldDeferRendererRealCommandQueueTeardownProof
        this.shouldReportRendererRealCommandQueueTeardownProofBlocked =
            shouldReportRendererRealCommandQueueTeardownProofBlocked
        this.didPreserveRendererRealCommandQueueOwnershipProof =
            didPreserveRendererRealCommandQueueOwnershipProof
        this.didDefineOwnerLocalQueueTeardownProof =
            didDefineOwnerLocalQueueTeardownProof
        this.didDescribeOrderedCloseProof = didDescribeOrderedCloseProof
        this.didDescribeRepeatableCloseProof = didDescribeRepeatableCloseProof
        this.didDescribeFailureSafeCloseProof =
            didDescribeFailureSafeCloseProof
        this.didConfirmNoExternalLifecycleCall =
            didConfirmNoExternalLifecycleCall
        this.didConfirmNoStateMutation = didConfirmNoStateMutation
        this.didKeepQueueTeardownProofDehydrated =
            didKeepQueueTeardownProofDehydrated
        this.didAvoidLifecyclePermissionWrapper =
            didAvoidLifecyclePermissionWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealCommandQueueFailureClassification {
    let teardownProof:
        CjguiInternalRendererRealCommandQueueTeardownProof
    let didPrepareRendererRealCommandQueueFailureClassification: Bool
    let shouldDeferRendererRealCommandQueueFailureClassification: Bool
    let shouldReportRendererRealCommandQueueFailureClassificationBlocked:
        Bool
    let didPreserveRendererRealCommandQueueTeardownProof: Bool
    let didDefineOwnerLocalQueueFailureClassification: Bool
    let didFailClosedUnavailableQueueCreation: Bool
    let didFailClosedWrongThreadRisk: Bool
    let didFailClosedDanglingResourceRisk: Bool
    let didFailClosedBridgeOptimism: Bool
    let didConfirmNoFailurePublication: Bool
    let didConfirmNoPublicDiagnostics: Bool
    let didKeepQueueFailureClassificationDehydrated: Bool
    let didAvoidQueueReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        teardownProof:
            CjguiInternalRendererRealCommandQueueTeardownProof,
        didPrepareRendererRealCommandQueueFailureClassification: Bool,
        shouldDeferRendererRealCommandQueueFailureClassification: Bool,
        shouldReportRendererRealCommandQueueFailureClassificationBlocked:
            Bool,
        didPreserveRendererRealCommandQueueTeardownProof: Bool,
        didDefineOwnerLocalQueueFailureClassification: Bool,
        didFailClosedUnavailableQueueCreation: Bool,
        didFailClosedWrongThreadRisk: Bool,
        didFailClosedDanglingResourceRisk: Bool,
        didFailClosedBridgeOptimism: Bool,
        didConfirmNoFailurePublication: Bool,
        didConfirmNoPublicDiagnostics: Bool,
        didKeepQueueFailureClassificationDehydrated: Bool,
        didAvoidQueueReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.teardownProof = teardownProof
        this.didPrepareRendererRealCommandQueueFailureClassification =
            didPrepareRendererRealCommandQueueFailureClassification
        this.shouldDeferRendererRealCommandQueueFailureClassification =
            shouldDeferRendererRealCommandQueueFailureClassification
        this
            .shouldReportRendererRealCommandQueueFailureClassificationBlocked =
            shouldReportRendererRealCommandQueueFailureClassificationBlocked
        this.didPreserveRendererRealCommandQueueTeardownProof =
            didPreserveRendererRealCommandQueueTeardownProof
        this.didDefineOwnerLocalQueueFailureClassification =
            didDefineOwnerLocalQueueFailureClassification
        this.didFailClosedUnavailableQueueCreation =
            didFailClosedUnavailableQueueCreation
        this.didFailClosedWrongThreadRisk = didFailClosedWrongThreadRisk
        this.didFailClosedDanglingResourceRisk =
            didFailClosedDanglingResourceRisk
        this.didFailClosedBridgeOptimism = didFailClosedBridgeOptimism
        this.didConfirmNoFailurePublication =
            didConfirmNoFailurePublication
        this.didConfirmNoPublicDiagnostics = didConfirmNoPublicDiagnostics
        this.didKeepQueueFailureClassificationDehydrated =
            didKeepQueueFailureClassificationDehydrated
        this.didAvoidQueueReadyWrapper = didAvoidQueueReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoRealCommandQueueShellReadiness {
    let failureClassification:
        CjguiInternalRendererRealCommandQueueFailureClassification
    let isRendererNoRealCommandQueueShellReady: Bool
    let canFutureRendererRealCommandQueueShellBoundaryEvaluate: Bool
    let shouldDeferRendererNoRealCommandQueueShellReadiness: Bool
    let shouldReportRendererNoRealCommandQueueShellReadinessBlocked: Bool
    let didSealRendererNoRealCommandQueueShellReadiness: Bool
    let didPreserveRendererRealCommandQueueFailureClassification: Bool
    let didKeepNoRealCommandQueueReadinessDehydrated: Bool
    let didConfirmNoConcreteCommandQueueObject: Bool
    let didConfirmNoQueueFactoryCall: Bool
    let didConfirmNoForeignResourceSurface: Bool
    let didConfirmNoNativeResourceStored: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didConfirmNoDrawableAcquisition: Bool
    let didConfirmNoCommandBufferCreation: Bool
    let didConfirmNoWorkSubmit: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoStateMutation: Bool
    let didConfirmNoRuntimeStateTouch: Bool
    let didConfirmNoModuleLevelMutableState: Bool
    let didConfirmNoPublicDiagnostics: Bool
    let didAvoidQueueReadyWrapper: Bool
    let didAvoidNativeHandleWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidWorkSubmitWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidStateMutationWrapper: Bool
    let didAvoidExternalSurfaceWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        failureClassification:
            CjguiInternalRendererRealCommandQueueFailureClassification,
        isRendererNoRealCommandQueueShellReady: Bool,
        canFutureRendererRealCommandQueueShellBoundaryEvaluate: Bool,
        shouldDeferRendererNoRealCommandQueueShellReadiness: Bool,
        shouldReportRendererNoRealCommandQueueShellReadinessBlocked: Bool,
        didSealRendererNoRealCommandQueueShellReadiness: Bool,
        didPreserveRendererRealCommandQueueFailureClassification: Bool,
        didKeepNoRealCommandQueueReadinessDehydrated: Bool,
        didConfirmNoConcreteCommandQueueObject: Bool,
        didConfirmNoQueueFactoryCall: Bool,
        didConfirmNoForeignResourceSurface: Bool,
        didConfirmNoNativeResourceStored: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didConfirmNoDrawableAcquisition: Bool,
        didConfirmNoCommandBufferCreation: Bool,
        didConfirmNoWorkSubmit: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoStateMutation: Bool,
        didConfirmNoRuntimeStateTouch: Bool,
        didConfirmNoModuleLevelMutableState: Bool,
        didConfirmNoPublicDiagnostics: Bool,
        didAvoidQueueReadyWrapper: Bool,
        didAvoidNativeHandleWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidWorkSubmitWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidStateMutationWrapper: Bool,
        didAvoidExternalSurfaceWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.failureClassification = failureClassification
        this.isRendererNoRealCommandQueueShellReady =
            isRendererNoRealCommandQueueShellReady
        this.canFutureRendererRealCommandQueueShellBoundaryEvaluate =
            canFutureRendererRealCommandQueueShellBoundaryEvaluate
        this.shouldDeferRendererNoRealCommandQueueShellReadiness =
            shouldDeferRendererNoRealCommandQueueShellReadiness
        this.shouldReportRendererNoRealCommandQueueShellReadinessBlocked =
            shouldReportRendererNoRealCommandQueueShellReadinessBlocked
        this.didSealRendererNoRealCommandQueueShellReadiness =
            didSealRendererNoRealCommandQueueShellReadiness
        this.didPreserveRendererRealCommandQueueFailureClassification =
            didPreserveRendererRealCommandQueueFailureClassification
        this.didKeepNoRealCommandQueueReadinessDehydrated =
            didKeepNoRealCommandQueueReadinessDehydrated
        this.didConfirmNoConcreteCommandQueueObject =
            didConfirmNoConcreteCommandQueueObject
        this.didConfirmNoQueueFactoryCall = didConfirmNoQueueFactoryCall
        this.didConfirmNoForeignResourceSurface =
            didConfirmNoForeignResourceSurface
        this.didConfirmNoNativeResourceStored =
            didConfirmNoNativeResourceStored
        this.didConfirmNoPointerLikeResource = didConfirmNoPointerLikeResource
        this.didConfirmNoDrawableAcquisition =
            didConfirmNoDrawableAcquisition
        this.didConfirmNoCommandBufferCreation =
            didConfirmNoCommandBufferCreation
        this.didConfirmNoWorkSubmit = didConfirmNoWorkSubmit
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoStateMutation = didConfirmNoStateMutation
        this.didConfirmNoRuntimeStateTouch = didConfirmNoRuntimeStateTouch
        this.didConfirmNoModuleLevelMutableState =
            didConfirmNoModuleLevelMutableState
        this.didConfirmNoPublicDiagnostics = didConfirmNoPublicDiagnostics
        this.didAvoidQueueReadyWrapper = didAvoidQueueReadyWrapper
        this.didAvoidNativeHandleWrapper = didAvoidNativeHandleWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
        this.didAvoidWorkSubmitWrapper = didAvoidWorkSubmitWrapper
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidStateMutationWrapper = didAvoidStateMutationWrapper
        this.didAvoidExternalSurfaceWrapper = didAvoidExternalSurfaceWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererRealCommandQueueShellIntent(
    noRealMetalDeviceLayerReadiness:
        CjguiInternalRendererNoRealMetalDeviceLayerReadiness
): CjguiInternalRendererRealCommandQueueShellIntent {
    let upstreamReady =
        noRealMetalDeviceLayerReadiness
            .isRendererNoRealMetalDeviceLayerReady &&
        noRealMetalDeviceLayerReadiness
            .canFutureRendererRealMetalDeviceLayerBoundaryEvaluate &&
        noRealMetalDeviceLayerReadiness
            .didSealRendererNoRealMetalDeviceLayerReadiness &&
        noRealMetalDeviceLayerReadiness
            .didPreserveRendererRealMetalDeviceLayerTeardownProof &&
        noRealMetalDeviceLayerReadiness
            .didKeepNoRealMetalDeviceLayerReadinessShellOnly &&
        noRealMetalDeviceLayerReadiness
            .didConfirmNoConcreteDeviceObject &&
        noRealMetalDeviceLayerReadiness.didConfirmNoConcreteLayerObject &&
        noRealMetalDeviceLayerReadiness
            .didConfirmNoForeignResourceSurface &&
        noRealMetalDeviceLayerReadiness.didConfirmNoSurfaceAcquisition &&
        noRealMetalDeviceLayerReadiness.didConfirmNoWorkSurface &&
        noRealMetalDeviceLayerReadiness.didConfirmNoWorkSubmit &&
        noRealMetalDeviceLayerReadiness.didConfirmNoRenderExecution &&
        noRealMetalDeviceLayerReadiness.didConfirmNoStateMutation &&
        noRealMetalDeviceLayerReadiness.didConfirmNoRuntimeStateTouch &&
        noRealMetalDeviceLayerReadiness
            .didConfirmNoModuleLevelMutableState &&
        noRealMetalDeviceLayerReadiness.didAvoidMetalReadyWrapper &&
        noRealMetalDeviceLayerReadiness.didAvoidDeviceReadyWrapper &&
        noRealMetalDeviceLayerReadiness.didAvoidLayerReadyWrapper &&
        noRealMetalDeviceLayerReadiness.didAvoidResourceReadyWrapper &&
        noRealMetalDeviceLayerReadiness.didAvoidBackendReadyWrapper &&
        noRealMetalDeviceLayerReadiness.didAvoidWorkSubmitWrapper &&
        noRealMetalDeviceLayerReadiness.didAvoidRenderPermissionWrapper &&
        noRealMetalDeviceLayerReadiness.didAvoidStateMutationWrapper &&
        noRealMetalDeviceLayerReadiness.didAvoidExternalSurfaceWrapper &&
        noRealMetalDeviceLayerReadiness.didAvoidReceiptRecordOutput &&
        noRealMetalDeviceLayerReadiness.didAvoidThinWrapper &&
        noRealMetalDeviceLayerReadiness.didStayFullRebuildOnly &&
        noRealMetalDeviceLayerReadiness
            .shouldDeferRendererNoRealMetalDeviceLayerReadiness == false &&
        noRealMetalDeviceLayerReadiness
            .shouldReportRendererNoRealMetalDeviceLayerReadinessBlocked ==
            false
    let upstreamDeferred =
        noRealMetalDeviceLayerReadiness
            .isRendererNoRealMetalDeviceLayerReady == false &&
        noRealMetalDeviceLayerReadiness
            .canFutureRendererRealMetalDeviceLayerBoundaryEvaluate == false &&
        noRealMetalDeviceLayerReadiness
            .shouldDeferRendererNoRealMetalDeviceLayerReadiness &&
        noRealMetalDeviceLayerReadiness
            .shouldReportRendererNoRealMetalDeviceLayerReadinessBlocked ==
            false
    let upstreamInconsistent =
        noRealMetalDeviceLayerReadiness
            .shouldReportRendererNoRealMetalDeviceLayerReadinessBlocked ||
        (
            noRealMetalDeviceLayerReadiness
                .isRendererNoRealMetalDeviceLayerReady &&
            (
                upstreamReady == false ||
                noRealMetalDeviceLayerReadiness
                    .shouldDeferRendererNoRealMetalDeviceLayerReadiness
            )
        ) ||
        (
            noRealMetalDeviceLayerReadiness
                .canFutureRendererRealMetalDeviceLayerBoundaryEvaluate &&
            noRealMetalDeviceLayerReadiness
                .isRendererNoRealMetalDeviceLayerReady == false
        ) ||
        (
            noRealMetalDeviceLayerReadiness
                .shouldDeferRendererNoRealMetalDeviceLayerReadiness &&
            noRealMetalDeviceLayerReadiness
                .shouldReportRendererNoRealMetalDeviceLayerReadinessBlocked
        )

    if (upstreamInconsistent) {
        return CjguiInternalRendererRealCommandQueueShellIntent(
            noRealMetalDeviceLayerReadiness,
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
        return CjguiInternalRendererRealCommandQueueShellIntent(
            noRealMetalDeviceLayerReadiness,
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
        return CjguiInternalRendererRealCommandQueueShellIntent(
            noRealMetalDeviceLayerReadiness,
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

    return CjguiInternalRendererRealCommandQueueShellIntent(
        noRealMetalDeviceLayerReadiness,
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

func cjguiInternalBuildRendererRealCommandQueueCreationAdmissionShell(
    shellIntent:
        CjguiInternalRendererRealCommandQueueShellIntent
): CjguiInternalRendererRealCommandQueueCreationAdmissionShell {
    let intentReady =
        shellIntent.didPrepareRendererRealCommandQueueShellIntent &&
        shellIntent.didPreserveRendererNoRealMetalDeviceLayerReadiness &&
        shellIntent.didDefineFutureRealCommandQueueShellIntent &&
        shellIntent.didDescribeQueueCreationAdmissionShellNeed &&
        shellIntent.didDescribeQueueOwnershipProofNeed &&
        shellIntent.didDescribeQueueTeardownProofNeed &&
        shellIntent.didDescribeQueueFailureClassificationNeed &&
        shellIntent.didKeepRealCommandQueueShellIntentDehydrated &&
        shellIntent.didAvoidQueueReadyWrapper &&
        shellIntent.didAvoidBackendReadyWrapper &&
        shellIntent.didAvoidReceiptRecordOutput &&
        shellIntent.didAvoidThinWrapper &&
        shellIntent.shouldDeferRendererRealCommandQueueShellIntent ==
            false &&
        shellIntent.shouldReportRendererRealCommandQueueShellIntentBlocked ==
            false
    let intentDeferred =
        shellIntent.didPrepareRendererRealCommandQueueShellIntent == false &&
        shellIntent.shouldDeferRendererRealCommandQueueShellIntent &&
        shellIntent.shouldReportRendererRealCommandQueueShellIntentBlocked ==
            false
    let intentInconsistent =
        shellIntent.shouldReportRendererRealCommandQueueShellIntentBlocked ||
        (
            shellIntent.didPrepareRendererRealCommandQueueShellIntent &&
            intentReady == false
        ) ||
        (
            shellIntent.didPreserveRendererNoRealMetalDeviceLayerReadiness &&
            shellIntent.didPrepareRendererRealCommandQueueShellIntent ==
                false
        )

    if (intentInconsistent) {
        return CjguiInternalRendererRealCommandQueueCreationAdmissionShell(
            shellIntent,
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

    if (intentReady) {
        return CjguiInternalRendererRealCommandQueueCreationAdmissionShell(
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
            true
        )
    }

    if (intentDeferred) {
        return CjguiInternalRendererRealCommandQueueCreationAdmissionShell(
            shellIntent,
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

    return CjguiInternalRendererRealCommandQueueCreationAdmissionShell(
        shellIntent,
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

func cjguiInternalBuildRendererRealCommandQueueOwnershipProof(
    creationAdmissionShell:
        CjguiInternalRendererRealCommandQueueCreationAdmissionShell
): CjguiInternalRendererRealCommandQueueOwnershipProof {
    let shellReady =
        creationAdmissionShell
            .didPrepareRendererRealCommandQueueCreationAdmissionShell &&
        creationAdmissionShell
            .didPreserveRendererRealCommandQueueShellIntent &&
        creationAdmissionShell
            .didDefineOwnerLocalQueueCreationAdmissionShell &&
        creationAdmissionShell.didConfirmNoConcreteCommandQueueObject &&
        creationAdmissionShell.didConfirmNoQueueFactoryCall &&
        creationAdmissionShell.didConfirmNoCommandBufferCreation &&
        creationAdmissionShell.didKeepQueueCreationAdmissionShellDehydrated &&
        creationAdmissionShell.didAvoidQueueReadyWrapper &&
        creationAdmissionShell.didAvoidDeviceReadyWrapper &&
        creationAdmissionShell.didAvoidThinWrapper &&
        creationAdmissionShell
            .shouldDeferRendererRealCommandQueueCreationAdmissionShell ==
            false &&
        creationAdmissionShell
            .shouldReportRendererRealCommandQueueCreationAdmissionShellBlocked ==
            false
    let shellDeferred =
        creationAdmissionShell
            .didPrepareRendererRealCommandQueueCreationAdmissionShell ==
            false &&
        creationAdmissionShell
            .shouldDeferRendererRealCommandQueueCreationAdmissionShell &&
        creationAdmissionShell
            .shouldReportRendererRealCommandQueueCreationAdmissionShellBlocked ==
            false
    let shellInconsistent =
        creationAdmissionShell
            .shouldReportRendererRealCommandQueueCreationAdmissionShellBlocked ||
        (
            creationAdmissionShell
                .didPrepareRendererRealCommandQueueCreationAdmissionShell &&
            shellReady == false
        ) ||
        (
            creationAdmissionShell
                .didPreserveRendererRealCommandQueueShellIntent &&
            creationAdmissionShell
                .didPrepareRendererRealCommandQueueCreationAdmissionShell ==
                false
        )

    if (shellInconsistent) {
        return CjguiInternalRendererRealCommandQueueOwnershipProof(
            creationAdmissionShell,
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
            true
        )
    }

    if (shellReady) {
        return CjguiInternalRendererRealCommandQueueOwnershipProof(
            creationAdmissionShell,
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

    if (shellDeferred) {
        return CjguiInternalRendererRealCommandQueueOwnershipProof(
            creationAdmissionShell,
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
            true,
            true
        )
    }

    return CjguiInternalRendererRealCommandQueueOwnershipProof(
        creationAdmissionShell,
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
        true
    )
}

func cjguiInternalBuildRendererRealCommandQueueTeardownProof(
    ownershipProof:
        CjguiInternalRendererRealCommandQueueOwnershipProof
): CjguiInternalRendererRealCommandQueueTeardownProof {
    let proofReady =
        ownershipProof.didPrepareRendererRealCommandQueueOwnershipProof &&
        ownershipProof.didPreserveRendererRealCommandQueueCreationAdmissionShell &&
        ownershipProof.didDefineOwnerLocalQueueOwnershipProof &&
        ownershipProof.didDescribeOwnerLocalConfinementProof &&
        ownershipProof.didConfirmNoNativeResourceStored &&
        ownershipProof.didConfirmNoForeignResourceToken &&
        ownershipProof.didConfirmNoPointerLikeResource &&
        ownershipProof.didKeepQueueOwnershipProofDehydrated &&
        ownershipProof.didAvoidNativeHandleWrapper &&
        ownershipProof.didAvoidBackendReadyWrapper &&
        ownershipProof.didAvoidReceiptRecordOutput &&
        ownershipProof.didAvoidThinWrapper &&
        ownershipProof.shouldDeferRendererRealCommandQueueOwnershipProof ==
            false &&
        ownershipProof
            .shouldReportRendererRealCommandQueueOwnershipProofBlocked ==
            false
    let proofDeferred =
        ownershipProof.didPrepareRendererRealCommandQueueOwnershipProof ==
            false &&
        ownershipProof.shouldDeferRendererRealCommandQueueOwnershipProof &&
        ownershipProof
            .shouldReportRendererRealCommandQueueOwnershipProofBlocked ==
            false
    let proofInconsistent =
        ownershipProof.shouldReportRendererRealCommandQueueOwnershipProofBlocked ||
        (
            ownershipProof.didPrepareRendererRealCommandQueueOwnershipProof &&
            proofReady == false
        ) ||
        (
            ownershipProof
                .didPreserveRendererRealCommandQueueCreationAdmissionShell &&
            ownershipProof.didPrepareRendererRealCommandQueueOwnershipProof ==
                false
        )

    if (proofInconsistent) {
        return CjguiInternalRendererRealCommandQueueTeardownProof(
            ownershipProof,
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

    if (proofReady) {
        return CjguiInternalRendererRealCommandQueueTeardownProof(
            ownershipProof,
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

    if (proofDeferred) {
        return CjguiInternalRendererRealCommandQueueTeardownProof(
            ownershipProof,
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

    return CjguiInternalRendererRealCommandQueueTeardownProof(
        ownershipProof,
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

func cjguiInternalBuildRendererRealCommandQueueFailureClassification(
    teardownProof:
        CjguiInternalRendererRealCommandQueueTeardownProof
): CjguiInternalRendererRealCommandQueueFailureClassification {
    let proofReady =
        teardownProof.didPrepareRendererRealCommandQueueTeardownProof &&
        teardownProof.didPreserveRendererRealCommandQueueOwnershipProof &&
        teardownProof.didDefineOwnerLocalQueueTeardownProof &&
        teardownProof.didDescribeOrderedCloseProof &&
        teardownProof.didDescribeRepeatableCloseProof &&
        teardownProof.didDescribeFailureSafeCloseProof &&
        teardownProof.didConfirmNoExternalLifecycleCall &&
        teardownProof.didConfirmNoStateMutation &&
        teardownProof.didKeepQueueTeardownProofDehydrated &&
        teardownProof.didAvoidLifecyclePermissionWrapper &&
        teardownProof.didAvoidReceiptRecordOutput &&
        teardownProof.didAvoidThinWrapper &&
        teardownProof.shouldDeferRendererRealCommandQueueTeardownProof ==
            false &&
        teardownProof.shouldReportRendererRealCommandQueueTeardownProofBlocked ==
            false
    let proofDeferred =
        teardownProof.didPrepareRendererRealCommandQueueTeardownProof ==
            false &&
        teardownProof.shouldDeferRendererRealCommandQueueTeardownProof &&
        teardownProof.shouldReportRendererRealCommandQueueTeardownProofBlocked ==
            false
    let proofInconsistent =
        teardownProof
            .shouldReportRendererRealCommandQueueTeardownProofBlocked ||
        (
            teardownProof.didPrepareRendererRealCommandQueueTeardownProof &&
            proofReady == false
        ) ||
        (
            teardownProof.didPreserveRendererRealCommandQueueOwnershipProof &&
            teardownProof.didPrepareRendererRealCommandQueueTeardownProof ==
                false
        )

    if (proofInconsistent) {
        return CjguiInternalRendererRealCommandQueueFailureClassification(
            teardownProof,
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

    if (proofReady) {
        return CjguiInternalRendererRealCommandQueueFailureClassification(
            teardownProof,
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

    if (proofDeferred) {
        return CjguiInternalRendererRealCommandQueueFailureClassification(
            teardownProof,
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

    return CjguiInternalRendererRealCommandQueueFailureClassification(
        teardownProof,
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

func cjguiInternalBuildRendererNoRealCommandQueueShellReadiness(
    failureClassification:
        CjguiInternalRendererRealCommandQueueFailureClassification
): CjguiInternalRendererNoRealCommandQueueShellReadiness {
    let failureReady =
        failureClassification
            .didPrepareRendererRealCommandQueueFailureClassification &&
        failureClassification
            .didPreserveRendererRealCommandQueueTeardownProof &&
        failureClassification
            .didDefineOwnerLocalQueueFailureClassification &&
        failureClassification.didFailClosedUnavailableQueueCreation &&
        failureClassification.didFailClosedWrongThreadRisk &&
        failureClassification.didFailClosedDanglingResourceRisk &&
        failureClassification.didFailClosedBridgeOptimism &&
        failureClassification.didConfirmNoFailurePublication &&
        failureClassification.didConfirmNoPublicDiagnostics &&
        failureClassification.didKeepQueueFailureClassificationDehydrated &&
        failureClassification.didAvoidQueueReadyWrapper &&
        failureClassification.didAvoidBackendReadyWrapper &&
        failureClassification.didAvoidReceiptRecordOutput &&
        failureClassification.didAvoidThinWrapper &&
        failureClassification
            .shouldDeferRendererRealCommandQueueFailureClassification ==
            false &&
        failureClassification
            .shouldReportRendererRealCommandQueueFailureClassificationBlocked ==
            false
    let failureDeferred =
        failureClassification
            .didPrepareRendererRealCommandQueueFailureClassification ==
            false &&
        failureClassification
            .shouldDeferRendererRealCommandQueueFailureClassification &&
        failureClassification
            .shouldReportRendererRealCommandQueueFailureClassificationBlocked ==
            false
    let failureInconsistent =
        failureClassification
            .shouldReportRendererRealCommandQueueFailureClassificationBlocked ||
        (
            failureClassification
                .didPrepareRendererRealCommandQueueFailureClassification &&
            failureReady == false
        ) ||
        (
            failureClassification
                .didPreserveRendererRealCommandQueueTeardownProof &&
            failureClassification
                .didPrepareRendererRealCommandQueueFailureClassification ==
                false
        )

    if (failureInconsistent) {
        return CjguiInternalRendererNoRealCommandQueueShellReadiness(
            failureClassification,
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
            true
        )
    }

    if (failureReady) {
        return CjguiInternalRendererNoRealCommandQueueShellReadiness(
            failureClassification,
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
            true
        )
    }

    if (failureDeferred) {
        return CjguiInternalRendererNoRealCommandQueueShellReadiness(
            failureClassification,
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
            true
        )
    }

    return CjguiInternalRendererNoRealCommandQueueShellReadiness(
        failureClassification,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft():
    CjguiInternalRendererNoRealCommandQueueShellReadiness {
    let noRealMetalDeviceLayerReadiness =
        cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()
    let shellIntent =
        cjguiInternalBuildRendererRealCommandQueueShellIntent(
            noRealMetalDeviceLayerReadiness
        )
    let creationAdmissionShell =
        cjguiInternalBuildRendererRealCommandQueueCreationAdmissionShell(
            shellIntent
        )
    let ownershipProof =
        cjguiInternalBuildRendererRealCommandQueueOwnershipProof(
            creationAdmissionShell
        )
    let teardownProof =
        cjguiInternalBuildRendererRealCommandQueueTeardownProof(
            ownershipProof
        )
    let failureClassification =
        cjguiInternalBuildRendererRealCommandQueueFailureClassification(
            teardownProof
        )
    return cjguiInternalBuildRendererNoRealCommandQueueShellReadiness(
        failureClassification
    )
}
