// Owner: real Metal device-layer first-slice shell boundary.
// Truth: consumes CjguiInternalRendererNoNativeTeardownImplementationReadiness
// and records device-layer intent, shell policies, teardown proof, and
// no-real-metal-device-layer readiness facts.
// Stop-line: no external platform resource, no cross-language surface, no
// graphics work, no state mutation, no runtime state touch, no outward surface.
// Same-shape Boundary Brake: this shell is not a Metal-ready, device-ready,
// layer-ready, backend-ready, resource-ready, receipt, record, or publication
// wrapper.
package cjgui

struct CjguiInternalRendererRealMetalDeviceLayerIntent {
    let noNativeTeardownImplementationReadiness:
        CjguiInternalRendererNoNativeTeardownImplementationReadiness
    let didPrepareRendererRealMetalDeviceLayerIntent: Bool
    let shouldDeferRendererRealMetalDeviceLayerIntent: Bool
    let shouldReportRendererRealMetalDeviceLayerIntentBlocked: Bool
    let didPreserveRendererNoNativeTeardownImplementationReadiness: Bool
    let didDefineFutureRealMetalDeviceLayerShellIntent: Bool
    let didDescribeRealMetalDeviceShellPolicyNeed: Bool
    let didDescribeRealMetalLayerBindingShellPolicyNeed: Bool
    let didDescribeRealMetalDeviceLayerTeardownProofNeed: Bool
    let didKeepRealMetalDeviceLayerIntentShellOnly: Bool
    let didAvoidMetalReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        noNativeTeardownImplementationReadiness:
            CjguiInternalRendererNoNativeTeardownImplementationReadiness,
        didPrepareRendererRealMetalDeviceLayerIntent: Bool,
        shouldDeferRendererRealMetalDeviceLayerIntent: Bool,
        shouldReportRendererRealMetalDeviceLayerIntentBlocked: Bool,
        didPreserveRendererNoNativeTeardownImplementationReadiness: Bool,
        didDefineFutureRealMetalDeviceLayerShellIntent: Bool,
        didDescribeRealMetalDeviceShellPolicyNeed: Bool,
        didDescribeRealMetalLayerBindingShellPolicyNeed: Bool,
        didDescribeRealMetalDeviceLayerTeardownProofNeed: Bool,
        didKeepRealMetalDeviceLayerIntentShellOnly: Bool,
        didAvoidMetalReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noNativeTeardownImplementationReadiness =
            noNativeTeardownImplementationReadiness
        this.didPrepareRendererRealMetalDeviceLayerIntent =
            didPrepareRendererRealMetalDeviceLayerIntent
        this.shouldDeferRendererRealMetalDeviceLayerIntent =
            shouldDeferRendererRealMetalDeviceLayerIntent
        this.shouldReportRendererRealMetalDeviceLayerIntentBlocked =
            shouldReportRendererRealMetalDeviceLayerIntentBlocked
        this.didPreserveRendererNoNativeTeardownImplementationReadiness =
            didPreserveRendererNoNativeTeardownImplementationReadiness
        this.didDefineFutureRealMetalDeviceLayerShellIntent =
            didDefineFutureRealMetalDeviceLayerShellIntent
        this.didDescribeRealMetalDeviceShellPolicyNeed =
            didDescribeRealMetalDeviceShellPolicyNeed
        this.didDescribeRealMetalLayerBindingShellPolicyNeed =
            didDescribeRealMetalLayerBindingShellPolicyNeed
        this.didDescribeRealMetalDeviceLayerTeardownProofNeed =
            didDescribeRealMetalDeviceLayerTeardownProofNeed
        this.didKeepRealMetalDeviceLayerIntentShellOnly =
            didKeepRealMetalDeviceLayerIntentShellOnly
        this.didAvoidMetalReadyWrapper = didAvoidMetalReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealMetalDeviceShellPolicy {
    let deviceLayerIntent:
        CjguiInternalRendererRealMetalDeviceLayerIntent
    let didPrepareRendererRealMetalDeviceShellPolicy: Bool
    let shouldDeferRendererRealMetalDeviceShellPolicy: Bool
    let shouldReportRendererRealMetalDeviceShellPolicyBlocked: Bool
    let didPreserveRendererRealMetalDeviceLayerIntent: Bool
    let didDefineOwnerLocalDeviceShellPolicy: Bool
    let didConfirmNoConcreteDeviceObject: Bool
    let didConfirmNoForeignResourceSurface: Bool
    let didConfirmNoWorkSubmit: Bool
    let didKeepRealMetalDeviceShellPolicyShellOnly: Bool
    let didAvoidDeviceReadyWrapper: Bool
    let didAvoidResourceReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        deviceLayerIntent:
            CjguiInternalRendererRealMetalDeviceLayerIntent,
        didPrepareRendererRealMetalDeviceShellPolicy: Bool,
        shouldDeferRendererRealMetalDeviceShellPolicy: Bool,
        shouldReportRendererRealMetalDeviceShellPolicyBlocked: Bool,
        didPreserveRendererRealMetalDeviceLayerIntent: Bool,
        didDefineOwnerLocalDeviceShellPolicy: Bool,
        didConfirmNoConcreteDeviceObject: Bool,
        didConfirmNoForeignResourceSurface: Bool,
        didConfirmNoWorkSubmit: Bool,
        didKeepRealMetalDeviceShellPolicyShellOnly: Bool,
        didAvoidDeviceReadyWrapper: Bool,
        didAvoidResourceReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.deviceLayerIntent = deviceLayerIntent
        this.didPrepareRendererRealMetalDeviceShellPolicy =
            didPrepareRendererRealMetalDeviceShellPolicy
        this.shouldDeferRendererRealMetalDeviceShellPolicy =
            shouldDeferRendererRealMetalDeviceShellPolicy
        this.shouldReportRendererRealMetalDeviceShellPolicyBlocked =
            shouldReportRendererRealMetalDeviceShellPolicyBlocked
        this.didPreserveRendererRealMetalDeviceLayerIntent =
            didPreserveRendererRealMetalDeviceLayerIntent
        this.didDefineOwnerLocalDeviceShellPolicy =
            didDefineOwnerLocalDeviceShellPolicy
        this.didConfirmNoConcreteDeviceObject =
            didConfirmNoConcreteDeviceObject
        this.didConfirmNoForeignResourceSurface =
            didConfirmNoForeignResourceSurface
        this.didConfirmNoWorkSubmit = didConfirmNoWorkSubmit
        this.didKeepRealMetalDeviceShellPolicyShellOnly =
            didKeepRealMetalDeviceShellPolicyShellOnly
        this.didAvoidDeviceReadyWrapper = didAvoidDeviceReadyWrapper
        this.didAvoidResourceReadyWrapper = didAvoidResourceReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealMetalLayerBindingShellPolicy {
    let deviceShellPolicy:
        CjguiInternalRendererRealMetalDeviceShellPolicy
    let didPrepareRendererRealMetalLayerBindingShellPolicy: Bool
    let shouldDeferRendererRealMetalLayerBindingShellPolicy: Bool
    let shouldReportRendererRealMetalLayerBindingShellPolicyBlocked: Bool
    let didPreserveRendererRealMetalDeviceShellPolicy: Bool
    let didDefineOwnerLocalLayerBindingShellPolicy: Bool
    let didConfirmNoConcreteLayerObject: Bool
    let didConfirmNoSurfaceAcquisition: Bool
    let didConfirmNoWorkSurface: Bool
    let didKeepRealMetalLayerBindingShellPolicyShellOnly: Bool
    let didAvoidLayerReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        deviceShellPolicy:
            CjguiInternalRendererRealMetalDeviceShellPolicy,
        didPrepareRendererRealMetalLayerBindingShellPolicy: Bool,
        shouldDeferRendererRealMetalLayerBindingShellPolicy: Bool,
        shouldReportRendererRealMetalLayerBindingShellPolicyBlocked: Bool,
        didPreserveRendererRealMetalDeviceShellPolicy: Bool,
        didDefineOwnerLocalLayerBindingShellPolicy: Bool,
        didConfirmNoConcreteLayerObject: Bool,
        didConfirmNoSurfaceAcquisition: Bool,
        didConfirmNoWorkSurface: Bool,
        didKeepRealMetalLayerBindingShellPolicyShellOnly: Bool,
        didAvoidLayerReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.deviceShellPolicy = deviceShellPolicy
        this.didPrepareRendererRealMetalLayerBindingShellPolicy =
            didPrepareRendererRealMetalLayerBindingShellPolicy
        this.shouldDeferRendererRealMetalLayerBindingShellPolicy =
            shouldDeferRendererRealMetalLayerBindingShellPolicy
        this.shouldReportRendererRealMetalLayerBindingShellPolicyBlocked =
            shouldReportRendererRealMetalLayerBindingShellPolicyBlocked
        this.didPreserveRendererRealMetalDeviceShellPolicy =
            didPreserveRendererRealMetalDeviceShellPolicy
        this.didDefineOwnerLocalLayerBindingShellPolicy =
            didDefineOwnerLocalLayerBindingShellPolicy
        this.didConfirmNoConcreteLayerObject =
            didConfirmNoConcreteLayerObject
        this.didConfirmNoSurfaceAcquisition =
            didConfirmNoSurfaceAcquisition
        this.didConfirmNoWorkSurface = didConfirmNoWorkSurface
        this.didKeepRealMetalLayerBindingShellPolicyShellOnly =
            didKeepRealMetalLayerBindingShellPolicyShellOnly
        this.didAvoidLayerReadyWrapper = didAvoidLayerReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealMetalDeviceLayerTeardownProof {
    let layerBindingShellPolicy:
        CjguiInternalRendererRealMetalLayerBindingShellPolicy
    let didPrepareRendererRealMetalDeviceLayerTeardownProof: Bool
    let shouldDeferRendererRealMetalDeviceLayerTeardownProof: Bool
    let shouldReportRendererRealMetalDeviceLayerTeardownProofBlocked: Bool
    let didPreserveRendererRealMetalLayerBindingShellPolicy: Bool
    let didDefineOwnerLocalTeardownProof: Bool
    let didDescribeOrderedCloseProof: Bool
    let didDescribeRepeatableCloseProof: Bool
    let didDescribeFailureSafeCloseProof: Bool
    let didConfirmNoExternalLifecycleCall: Bool
    let didConfirmNoStateMutation: Bool
    let didKeepRealMetalDeviceLayerTeardownProofShellOnly: Bool
    let didAvoidLifecyclePermissionWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        layerBindingShellPolicy:
            CjguiInternalRendererRealMetalLayerBindingShellPolicy,
        didPrepareRendererRealMetalDeviceLayerTeardownProof: Bool,
        shouldDeferRendererRealMetalDeviceLayerTeardownProof: Bool,
        shouldReportRendererRealMetalDeviceLayerTeardownProofBlocked:
            Bool,
        didPreserveRendererRealMetalLayerBindingShellPolicy: Bool,
        didDefineOwnerLocalTeardownProof: Bool,
        didDescribeOrderedCloseProof: Bool,
        didDescribeRepeatableCloseProof: Bool,
        didDescribeFailureSafeCloseProof: Bool,
        didConfirmNoExternalLifecycleCall: Bool,
        didConfirmNoStateMutation: Bool,
        didKeepRealMetalDeviceLayerTeardownProofShellOnly: Bool,
        didAvoidLifecyclePermissionWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.layerBindingShellPolicy = layerBindingShellPolicy
        this.didPrepareRendererRealMetalDeviceLayerTeardownProof =
            didPrepareRendererRealMetalDeviceLayerTeardownProof
        this.shouldDeferRendererRealMetalDeviceLayerTeardownProof =
            shouldDeferRendererRealMetalDeviceLayerTeardownProof
        this.shouldReportRendererRealMetalDeviceLayerTeardownProofBlocked =
            shouldReportRendererRealMetalDeviceLayerTeardownProofBlocked
        this.didPreserveRendererRealMetalLayerBindingShellPolicy =
            didPreserveRendererRealMetalLayerBindingShellPolicy
        this.didDefineOwnerLocalTeardownProof =
            didDefineOwnerLocalTeardownProof
        this.didDescribeOrderedCloseProof = didDescribeOrderedCloseProof
        this.didDescribeRepeatableCloseProof = didDescribeRepeatableCloseProof
        this.didDescribeFailureSafeCloseProof =
            didDescribeFailureSafeCloseProof
        this.didConfirmNoExternalLifecycleCall =
            didConfirmNoExternalLifecycleCall
        this.didConfirmNoStateMutation = didConfirmNoStateMutation
        this.didKeepRealMetalDeviceLayerTeardownProofShellOnly =
            didKeepRealMetalDeviceLayerTeardownProofShellOnly
        this.didAvoidLifecyclePermissionWrapper =
            didAvoidLifecyclePermissionWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoRealMetalDeviceLayerReadiness {
    let teardownProof:
        CjguiInternalRendererRealMetalDeviceLayerTeardownProof
    let isRendererNoRealMetalDeviceLayerReady: Bool
    let canFutureRendererRealMetalDeviceLayerBoundaryEvaluate: Bool
    let shouldDeferRendererNoRealMetalDeviceLayerReadiness: Bool
    let shouldReportRendererNoRealMetalDeviceLayerReadinessBlocked: Bool
    let didSealRendererNoRealMetalDeviceLayerReadiness: Bool
    let didPreserveRendererRealMetalDeviceLayerTeardownProof: Bool
    let didKeepNoRealMetalDeviceLayerReadinessShellOnly: Bool
    let didConfirmNoConcreteDeviceObject: Bool
    let didConfirmNoConcreteLayerObject: Bool
    let didConfirmNoForeignResourceSurface: Bool
    let didConfirmNoSurfaceAcquisition: Bool
    let didConfirmNoWorkSurface: Bool
    let didConfirmNoWorkSubmit: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoStateMutation: Bool
    let didConfirmNoRuntimeStateTouch: Bool
    let didConfirmNoModuleLevelMutableState: Bool
    let didAvoidMetalReadyWrapper: Bool
    let didAvoidDeviceReadyWrapper: Bool
    let didAvoidLayerReadyWrapper: Bool
    let didAvoidResourceReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidWorkSubmitWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidStateMutationWrapper: Bool
    let didAvoidExternalSurfaceWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        teardownProof:
            CjguiInternalRendererRealMetalDeviceLayerTeardownProof,
        isRendererNoRealMetalDeviceLayerReady: Bool,
        canFutureRendererRealMetalDeviceLayerBoundaryEvaluate: Bool,
        shouldDeferRendererNoRealMetalDeviceLayerReadiness: Bool,
        shouldReportRendererNoRealMetalDeviceLayerReadinessBlocked: Bool,
        didSealRendererNoRealMetalDeviceLayerReadiness: Bool,
        didPreserveRendererRealMetalDeviceLayerTeardownProof: Bool,
        didKeepNoRealMetalDeviceLayerReadinessShellOnly: Bool,
        didConfirmNoConcreteDeviceObject: Bool,
        didConfirmNoConcreteLayerObject: Bool,
        didConfirmNoForeignResourceSurface: Bool,
        didConfirmNoSurfaceAcquisition: Bool,
        didConfirmNoWorkSurface: Bool,
        didConfirmNoWorkSubmit: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoStateMutation: Bool,
        didConfirmNoRuntimeStateTouch: Bool,
        didConfirmNoModuleLevelMutableState: Bool,
        didAvoidMetalReadyWrapper: Bool,
        didAvoidDeviceReadyWrapper: Bool,
        didAvoidLayerReadyWrapper: Bool,
        didAvoidResourceReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidWorkSubmitWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidStateMutationWrapper: Bool,
        didAvoidExternalSurfaceWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.teardownProof = teardownProof
        this.isRendererNoRealMetalDeviceLayerReady =
            isRendererNoRealMetalDeviceLayerReady
        this.canFutureRendererRealMetalDeviceLayerBoundaryEvaluate =
            canFutureRendererRealMetalDeviceLayerBoundaryEvaluate
        this.shouldDeferRendererNoRealMetalDeviceLayerReadiness =
            shouldDeferRendererNoRealMetalDeviceLayerReadiness
        this.shouldReportRendererNoRealMetalDeviceLayerReadinessBlocked =
            shouldReportRendererNoRealMetalDeviceLayerReadinessBlocked
        this.didSealRendererNoRealMetalDeviceLayerReadiness =
            didSealRendererNoRealMetalDeviceLayerReadiness
        this.didPreserveRendererRealMetalDeviceLayerTeardownProof =
            didPreserveRendererRealMetalDeviceLayerTeardownProof
        this.didKeepNoRealMetalDeviceLayerReadinessShellOnly =
            didKeepNoRealMetalDeviceLayerReadinessShellOnly
        this.didConfirmNoConcreteDeviceObject =
            didConfirmNoConcreteDeviceObject
        this.didConfirmNoConcreteLayerObject = didConfirmNoConcreteLayerObject
        this.didConfirmNoForeignResourceSurface =
            didConfirmNoForeignResourceSurface
        this.didConfirmNoSurfaceAcquisition =
            didConfirmNoSurfaceAcquisition
        this.didConfirmNoWorkSurface = didConfirmNoWorkSurface
        this.didConfirmNoWorkSubmit = didConfirmNoWorkSubmit
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoStateMutation = didConfirmNoStateMutation
        this.didConfirmNoRuntimeStateTouch = didConfirmNoRuntimeStateTouch
        this.didConfirmNoModuleLevelMutableState =
            didConfirmNoModuleLevelMutableState
        this.didAvoidMetalReadyWrapper = didAvoidMetalReadyWrapper
        this.didAvoidDeviceReadyWrapper = didAvoidDeviceReadyWrapper
        this.didAvoidLayerReadyWrapper = didAvoidLayerReadyWrapper
        this.didAvoidResourceReadyWrapper = didAvoidResourceReadyWrapper
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

func cjguiInternalBuildRendererRealMetalDeviceLayerIntent(
    noNativeTeardownImplementationReadiness:
        CjguiInternalRendererNoNativeTeardownImplementationReadiness
): CjguiInternalRendererRealMetalDeviceLayerIntent {
    let upstreamReady =
        noNativeTeardownImplementationReadiness
            .isRendererNoNativeTeardownImplementationReady &&
        noNativeTeardownImplementationReadiness
            .canFutureRendererNativeTeardownImplementationBoundaryEvaluate &&
        noNativeTeardownImplementationReadiness
            .didSealRendererNoNativeTeardownImplementationReadiness &&
        noNativeTeardownImplementationReadiness
            .didPreserveRendererNativeMainThreadConfinementGuard &&
        noNativeTeardownImplementationReadiness
            .didKeepNoNativeTeardownImplementationReadinessValueOnly &&
        noNativeTeardownImplementationReadiness
            .didConfirmNoExternalLifecycleSurface &&
        noNativeTeardownImplementationReadiness
            .didConfirmNoForeignDeclaration &&
        noNativeTeardownImplementationReadiness
            .didConfirmNoForeignResourceSurface &&
        noNativeTeardownImplementationReadiness
            .didConfirmNoForeignPlatformResource &&
        noNativeTeardownImplementationReadiness
            .didConfirmNoGraphicsResource &&
        noNativeTeardownImplementationReadiness.didConfirmNoWorkSubmit &&
        noNativeTeardownImplementationReadiness.didConfirmNoRenderExecution &&
        noNativeTeardownImplementationReadiness
            .didConfirmNoRendererStateMutation &&
        noNativeTeardownImplementationReadiness.didConfirmNoRuntimeStateTouch &&
        noNativeTeardownImplementationReadiness
            .didConfirmNoModuleLevelMutableState &&
        noNativeTeardownImplementationReadiness
            .didFailClosedDoubleReleaseRisk &&
        noNativeTeardownImplementationReadiness
            .didFailClosedDanglingResourceRisk &&
        noNativeTeardownImplementationReadiness.didFailClosedWrongThreadRisk &&
        noNativeTeardownImplementationReadiness
            .didAvoidNativeLifecyclePermissionWrapper &&
        noNativeTeardownImplementationReadiness.didAvoidResourceReadyWrapper &&
        noNativeTeardownImplementationReadiness.didAvoidBackendReadyWrapper &&
        noNativeTeardownImplementationReadiness.didAvoidRenderPermissionWrapper &&
        noNativeTeardownImplementationReadiness.didAvoidStateMutationWrapper &&
        noNativeTeardownImplementationReadiness.didAvoidReceiptRecordOutput &&
        noNativeTeardownImplementationReadiness
            .didAvoidNativeTeardownReadyWrapper &&
        noNativeTeardownImplementationReadiness.didAvoidThinWrapper &&
        noNativeTeardownImplementationReadiness.didStayFullRebuildOnly &&
        noNativeTeardownImplementationReadiness
            .shouldDeferRendererNoNativeTeardownImplementationReadiness ==
            false &&
        noNativeTeardownImplementationReadiness
            .shouldReportRendererNoNativeTeardownImplementationReadinessBlocked ==
            false
    let upstreamDeferred =
        noNativeTeardownImplementationReadiness
            .isRendererNoNativeTeardownImplementationReady == false &&
        noNativeTeardownImplementationReadiness
            .canFutureRendererNativeTeardownImplementationBoundaryEvaluate ==
            false &&
        noNativeTeardownImplementationReadiness
            .shouldDeferRendererNoNativeTeardownImplementationReadiness &&
        noNativeTeardownImplementationReadiness
            .shouldReportRendererNoNativeTeardownImplementationReadinessBlocked ==
            false
    let upstreamInconsistent =
        noNativeTeardownImplementationReadiness
            .shouldReportRendererNoNativeTeardownImplementationReadinessBlocked ||
        (
            noNativeTeardownImplementationReadiness
                .isRendererNoNativeTeardownImplementationReady &&
            (
                upstreamReady == false ||
                noNativeTeardownImplementationReadiness
                    .shouldDeferRendererNoNativeTeardownImplementationReadiness
            )
        ) ||
        (
            noNativeTeardownImplementationReadiness
                .canFutureRendererNativeTeardownImplementationBoundaryEvaluate &&
            noNativeTeardownImplementationReadiness
                .isRendererNoNativeTeardownImplementationReady == false
        ) ||
        (
            noNativeTeardownImplementationReadiness
                .shouldDeferRendererNoNativeTeardownImplementationReadiness &&
            noNativeTeardownImplementationReadiness
                .shouldReportRendererNoNativeTeardownImplementationReadinessBlocked
        )

    if (upstreamInconsistent) {
        return CjguiInternalRendererRealMetalDeviceLayerIntent(
            noNativeTeardownImplementationReadiness,
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

    if (upstreamReady) {
        return CjguiInternalRendererRealMetalDeviceLayerIntent(
            noNativeTeardownImplementationReadiness,
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

    if (upstreamDeferred) {
        return CjguiInternalRendererRealMetalDeviceLayerIntent(
            noNativeTeardownImplementationReadiness,
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

    return CjguiInternalRendererRealMetalDeviceLayerIntent(
        noNativeTeardownImplementationReadiness,
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

func cjguiInternalBuildRendererRealMetalDeviceShellPolicy(
    deviceLayerIntent:
        CjguiInternalRendererRealMetalDeviceLayerIntent
): CjguiInternalRendererRealMetalDeviceShellPolicy {
    let intentReady =
        deviceLayerIntent.didPrepareRendererRealMetalDeviceLayerIntent &&
        deviceLayerIntent
            .didPreserveRendererNoNativeTeardownImplementationReadiness &&
        deviceLayerIntent.didDefineFutureRealMetalDeviceLayerShellIntent &&
        deviceLayerIntent.didDescribeRealMetalDeviceShellPolicyNeed &&
        deviceLayerIntent.didDescribeRealMetalLayerBindingShellPolicyNeed &&
        deviceLayerIntent.didDescribeRealMetalDeviceLayerTeardownProofNeed &&
        deviceLayerIntent.didKeepRealMetalDeviceLayerIntentShellOnly &&
        deviceLayerIntent.didAvoidMetalReadyWrapper &&
        deviceLayerIntent.didAvoidBackendReadyWrapper &&
        deviceLayerIntent.didAvoidReceiptRecordOutput &&
        deviceLayerIntent.didAvoidThinWrapper &&
        deviceLayerIntent.shouldDeferRendererRealMetalDeviceLayerIntent ==
            false &&
        deviceLayerIntent
            .shouldReportRendererRealMetalDeviceLayerIntentBlocked == false
    let intentDeferred =
        deviceLayerIntent.didPrepareRendererRealMetalDeviceLayerIntent ==
            false &&
        deviceLayerIntent.shouldDeferRendererRealMetalDeviceLayerIntent &&
        deviceLayerIntent
            .shouldReportRendererRealMetalDeviceLayerIntentBlocked == false
    let intentInconsistent =
        deviceLayerIntent
            .shouldReportRendererRealMetalDeviceLayerIntentBlocked ||
        (
            deviceLayerIntent.didPrepareRendererRealMetalDeviceLayerIntent &&
            intentReady == false
        ) ||
        (
            deviceLayerIntent
                .didPreserveRendererNoNativeTeardownImplementationReadiness &&
            deviceLayerIntent.didPrepareRendererRealMetalDeviceLayerIntent ==
                false
        )

    if (intentInconsistent) {
        return CjguiInternalRendererRealMetalDeviceShellPolicy(
            deviceLayerIntent,
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
        return CjguiInternalRendererRealMetalDeviceShellPolicy(
            deviceLayerIntent,
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
        return CjguiInternalRendererRealMetalDeviceShellPolicy(
            deviceLayerIntent,
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

    return CjguiInternalRendererRealMetalDeviceShellPolicy(
        deviceLayerIntent,
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

func cjguiInternalBuildRendererRealMetalLayerBindingShellPolicy(
    deviceShellPolicy:
        CjguiInternalRendererRealMetalDeviceShellPolicy
): CjguiInternalRendererRealMetalLayerBindingShellPolicy {
    let policyReady =
        deviceShellPolicy.didPrepareRendererRealMetalDeviceShellPolicy &&
        deviceShellPolicy.didPreserveRendererRealMetalDeviceLayerIntent &&
        deviceShellPolicy.didDefineOwnerLocalDeviceShellPolicy &&
        deviceShellPolicy.didConfirmNoConcreteDeviceObject &&
        deviceShellPolicy.didConfirmNoForeignResourceSurface &&
        deviceShellPolicy.didConfirmNoWorkSubmit &&
        deviceShellPolicy.didKeepRealMetalDeviceShellPolicyShellOnly &&
        deviceShellPolicy.didAvoidDeviceReadyWrapper &&
        deviceShellPolicy.didAvoidResourceReadyWrapper &&
        deviceShellPolicy.didAvoidThinWrapper &&
        deviceShellPolicy.shouldDeferRendererRealMetalDeviceShellPolicy ==
            false &&
        deviceShellPolicy
            .shouldReportRendererRealMetalDeviceShellPolicyBlocked == false
    let policyDeferred =
        deviceShellPolicy.didPrepareRendererRealMetalDeviceShellPolicy ==
            false &&
        deviceShellPolicy.shouldDeferRendererRealMetalDeviceShellPolicy &&
        deviceShellPolicy
            .shouldReportRendererRealMetalDeviceShellPolicyBlocked == false
    let policyInconsistent =
        deviceShellPolicy
            .shouldReportRendererRealMetalDeviceShellPolicyBlocked ||
        (
            deviceShellPolicy.didPrepareRendererRealMetalDeviceShellPolicy &&
            policyReady == false
        ) ||
        (
            deviceShellPolicy.didPreserveRendererRealMetalDeviceLayerIntent &&
            deviceShellPolicy.didPrepareRendererRealMetalDeviceShellPolicy ==
                false
        )

    if (policyInconsistent) {
        return CjguiInternalRendererRealMetalLayerBindingShellPolicy(
            deviceShellPolicy,
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

    if (policyReady) {
        return CjguiInternalRendererRealMetalLayerBindingShellPolicy(
            deviceShellPolicy,
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

    if (policyDeferred) {
        return CjguiInternalRendererRealMetalLayerBindingShellPolicy(
            deviceShellPolicy,
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

    return CjguiInternalRendererRealMetalLayerBindingShellPolicy(
        deviceShellPolicy,
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

func cjguiInternalBuildRendererRealMetalDeviceLayerTeardownProof(
    layerBindingShellPolicy:
        CjguiInternalRendererRealMetalLayerBindingShellPolicy
): CjguiInternalRendererRealMetalDeviceLayerTeardownProof {
    let policyReady =
        layerBindingShellPolicy
            .didPrepareRendererRealMetalLayerBindingShellPolicy &&
        layerBindingShellPolicy
            .didPreserveRendererRealMetalDeviceShellPolicy &&
        layerBindingShellPolicy.didDefineOwnerLocalLayerBindingShellPolicy &&
        layerBindingShellPolicy.didConfirmNoConcreteLayerObject &&
        layerBindingShellPolicy.didConfirmNoSurfaceAcquisition &&
        layerBindingShellPolicy.didConfirmNoWorkSurface &&
        layerBindingShellPolicy
            .didKeepRealMetalLayerBindingShellPolicyShellOnly &&
        layerBindingShellPolicy.didAvoidLayerReadyWrapper &&
        layerBindingShellPolicy.didAvoidBackendReadyWrapper &&
        layerBindingShellPolicy.didAvoidThinWrapper &&
        layerBindingShellPolicy
            .shouldDeferRendererRealMetalLayerBindingShellPolicy == false &&
        layerBindingShellPolicy
            .shouldReportRendererRealMetalLayerBindingShellPolicyBlocked ==
            false
    let policyDeferred =
        layerBindingShellPolicy
            .didPrepareRendererRealMetalLayerBindingShellPolicy == false &&
        layerBindingShellPolicy
            .shouldDeferRendererRealMetalLayerBindingShellPolicy &&
        layerBindingShellPolicy
            .shouldReportRendererRealMetalLayerBindingShellPolicyBlocked ==
            false
    let policyInconsistent =
        layerBindingShellPolicy
            .shouldReportRendererRealMetalLayerBindingShellPolicyBlocked ||
        (
            layerBindingShellPolicy
                .didPrepareRendererRealMetalLayerBindingShellPolicy &&
            policyReady == false
        ) ||
        (
            layerBindingShellPolicy
                .didPreserveRendererRealMetalDeviceShellPolicy &&
            layerBindingShellPolicy
                .didPrepareRendererRealMetalLayerBindingShellPolicy == false
        )

    if (policyInconsistent) {
        return CjguiInternalRendererRealMetalDeviceLayerTeardownProof(
            layerBindingShellPolicy,
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

    if (policyReady) {
        return CjguiInternalRendererRealMetalDeviceLayerTeardownProof(
            layerBindingShellPolicy,
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
        return CjguiInternalRendererRealMetalDeviceLayerTeardownProof(
            layerBindingShellPolicy,
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

    return CjguiInternalRendererRealMetalDeviceLayerTeardownProof(
        layerBindingShellPolicy,
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

func cjguiInternalBuildRendererNoRealMetalDeviceLayerReadiness(
    teardownProof:
        CjguiInternalRendererRealMetalDeviceLayerTeardownProof
): CjguiInternalRendererNoRealMetalDeviceLayerReadiness {
    let proofReady =
        teardownProof.didPrepareRendererRealMetalDeviceLayerTeardownProof &&
        teardownProof.didPreserveRendererRealMetalLayerBindingShellPolicy &&
        teardownProof.didDefineOwnerLocalTeardownProof &&
        teardownProof.didDescribeOrderedCloseProof &&
        teardownProof.didDescribeRepeatableCloseProof &&
        teardownProof.didDescribeFailureSafeCloseProof &&
        teardownProof.didConfirmNoExternalLifecycleCall &&
        teardownProof.didConfirmNoStateMutation &&
        teardownProof.didKeepRealMetalDeviceLayerTeardownProofShellOnly &&
        teardownProof.didAvoidLifecyclePermissionWrapper &&
        teardownProof.didAvoidReceiptRecordOutput &&
        teardownProof.didAvoidThinWrapper &&
        teardownProof.shouldDeferRendererRealMetalDeviceLayerTeardownProof ==
            false &&
        teardownProof
            .shouldReportRendererRealMetalDeviceLayerTeardownProofBlocked ==
            false
    let proofDeferred =
        teardownProof.didPrepareRendererRealMetalDeviceLayerTeardownProof ==
            false &&
        teardownProof.shouldDeferRendererRealMetalDeviceLayerTeardownProof &&
        teardownProof
            .shouldReportRendererRealMetalDeviceLayerTeardownProofBlocked ==
            false
    let proofInconsistent =
        teardownProof
            .shouldReportRendererRealMetalDeviceLayerTeardownProofBlocked ||
        (
            teardownProof.didPrepareRendererRealMetalDeviceLayerTeardownProof &&
            proofReady == false
        ) ||
        (
            teardownProof.didPreserveRendererRealMetalLayerBindingShellPolicy &&
            teardownProof.didPrepareRendererRealMetalDeviceLayerTeardownProof ==
                false
        )

    if (proofInconsistent) {
        return CjguiInternalRendererNoRealMetalDeviceLayerReadiness(
            teardownProof,
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
            true
        )
    }

    if (proofReady) {
        return CjguiInternalRendererNoRealMetalDeviceLayerReadiness(
            teardownProof,
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
            true
        )
    }

    if (proofDeferred) {
        return CjguiInternalRendererNoRealMetalDeviceLayerReadiness(
            teardownProof,
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
            true
        )
    }

    return CjguiInternalRendererNoRealMetalDeviceLayerReadiness(
        teardownProof,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft():
    CjguiInternalRendererNoRealMetalDeviceLayerReadiness {
    let noNativeTeardownImplementationReadiness =
        cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()
    let deviceLayerIntent =
        cjguiInternalBuildRendererRealMetalDeviceLayerIntent(
            noNativeTeardownImplementationReadiness
        )
    let deviceShellPolicy =
        cjguiInternalBuildRendererRealMetalDeviceShellPolicy(
            deviceLayerIntent
        )
    let layerBindingShellPolicy =
        cjguiInternalBuildRendererRealMetalLayerBindingShellPolicy(
            deviceShellPolicy
        )
    let teardownProof =
        cjguiInternalBuildRendererRealMetalDeviceLayerTeardownProof(
            layerBindingShellPolicy
        )
    return cjguiInternalBuildRendererNoRealMetalDeviceLayerReadiness(
        teardownProof
    )
}
