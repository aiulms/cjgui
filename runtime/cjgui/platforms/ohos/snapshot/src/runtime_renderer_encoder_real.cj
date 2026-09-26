// Owner: real encoder 第一刀 internal-only shell 边界。
// Truth: 只消费 CjguiInternalRendererNoRealRenderPassShellReadiness，并记录
// encoder shell intent、creation admission shell、binding denial proof、
// end-encoding denial proof、teardown / failure classification 与
// no-real-encoder-shell readiness facts。
// Stop-line: 只产出 internal-only shell / dehydrated facts；不是 encoder、
// renderCommandEncoder、endEncoding、pipeline / buffer / texture / resource
// binding、render pass descriptor、commandBuffer、commit、present、
// nextDrawable、GPU work、native bridge、native handle、C ABI / FFI、
// renderer state write 或 public API 许可。
// Same-shape Boundary Brake: 不得把本 shell 包成 encoder-ready、
// binding-ready、GPU-submission、render-permission、renderer-state-write、
// receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererRealEncoderShellIntent {
    let noRealRenderPassShellReadiness:
        CjguiInternalRendererNoRealRenderPassShellReadiness
    let didPrepareRendererRealEncoderShellIntent: Bool
    let shouldDeferRendererRealEncoderShellIntent: Bool
    let shouldReportRendererRealEncoderShellIntentBlocked: Bool
    let didPreserveRendererNoRealRenderPassShellReadiness: Bool
    let didDefineFutureEncoderShellIntent: Bool
    let didDescribeEncoderCreationAdmissionNeed: Bool
    let didDescribeBindingDenialNeed: Bool
    let didDescribeEndEncodingDenialNeed: Bool
    let didDescribeEncoderFailureClassificationNeed: Bool
    let didKeepEncoderShellIntentDehydrated: Bool
    let didAvoidEncoderReadyWrapper: Bool
    let didAvoidRenderPassReadyWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        noRealRenderPassShellReadiness:
            CjguiInternalRendererNoRealRenderPassShellReadiness,
        didPrepareRendererRealEncoderShellIntent: Bool,
        shouldDeferRendererRealEncoderShellIntent: Bool,
        shouldReportRendererRealEncoderShellIntentBlocked: Bool,
        didPreserveRendererNoRealRenderPassShellReadiness: Bool,
        didDefineFutureEncoderShellIntent: Bool,
        didDescribeEncoderCreationAdmissionNeed: Bool,
        didDescribeBindingDenialNeed: Bool,
        didDescribeEndEncodingDenialNeed: Bool,
        didDescribeEncoderFailureClassificationNeed: Bool,
        didKeepEncoderShellIntentDehydrated: Bool,
        didAvoidEncoderReadyWrapper: Bool,
        didAvoidRenderPassReadyWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noRealRenderPassShellReadiness =
            noRealRenderPassShellReadiness
        this.didPrepareRendererRealEncoderShellIntent =
            didPrepareRendererRealEncoderShellIntent
        this.shouldDeferRendererRealEncoderShellIntent =
            shouldDeferRendererRealEncoderShellIntent
        this.shouldReportRendererRealEncoderShellIntentBlocked =
            shouldReportRendererRealEncoderShellIntentBlocked
        this.didPreserveRendererNoRealRenderPassShellReadiness =
            didPreserveRendererNoRealRenderPassShellReadiness
        this.didDefineFutureEncoderShellIntent =
            didDefineFutureEncoderShellIntent
        this.didDescribeEncoderCreationAdmissionNeed =
            didDescribeEncoderCreationAdmissionNeed
        this.didDescribeBindingDenialNeed = didDescribeBindingDenialNeed
        this.didDescribeEndEncodingDenialNeed =
            didDescribeEndEncodingDenialNeed
        this.didDescribeEncoderFailureClassificationNeed =
            didDescribeEncoderFailureClassificationNeed
        this.didKeepEncoderShellIntentDehydrated =
            didKeepEncoderShellIntentDehydrated
        this.didAvoidEncoderReadyWrapper = didAvoidEncoderReadyWrapper
        this.didAvoidRenderPassReadyWrapper = didAvoidRenderPassReadyWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealEncoderCreationAdmissionShell {
    let shellIntent: CjguiInternalRendererRealEncoderShellIntent
    let didPrepareRendererRealEncoderCreationAdmissionShell: Bool
    let shouldDeferRendererRealEncoderCreationAdmissionShell: Bool
    let shouldReportRendererRealEncoderCreationAdmissionShellBlocked: Bool
    let didPreserveRendererRealEncoderShellIntent: Bool
    let didDefineOwnerLocalEncoderCreationAdmissionShell: Bool
    let didConfirmNoConcreteEncoderObject: Bool
    let didConfirmNoEncoderFactoryInvocation: Bool
    let didConfirmNoRenderPassDescriptorMutation: Bool
    let didKeepEncoderCreationAdmissionShellDehydrated: Bool
    let didAvoidEncoderReadyWrapper: Bool
    let didAvoidRenderPassReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        shellIntent: CjguiInternalRendererRealEncoderShellIntent,
        didPrepareRendererRealEncoderCreationAdmissionShell: Bool,
        shouldDeferRendererRealEncoderCreationAdmissionShell: Bool,
        shouldReportRendererRealEncoderCreationAdmissionShellBlocked: Bool,
        didPreserveRendererRealEncoderShellIntent: Bool,
        didDefineOwnerLocalEncoderCreationAdmissionShell: Bool,
        didConfirmNoConcreteEncoderObject: Bool,
        didConfirmNoEncoderFactoryInvocation: Bool,
        didConfirmNoRenderPassDescriptorMutation: Bool,
        didKeepEncoderCreationAdmissionShellDehydrated: Bool,
        didAvoidEncoderReadyWrapper: Bool,
        didAvoidRenderPassReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.shellIntent = shellIntent
        this.didPrepareRendererRealEncoderCreationAdmissionShell =
            didPrepareRendererRealEncoderCreationAdmissionShell
        this.shouldDeferRendererRealEncoderCreationAdmissionShell =
            shouldDeferRendererRealEncoderCreationAdmissionShell
        this.shouldReportRendererRealEncoderCreationAdmissionShellBlocked =
            shouldReportRendererRealEncoderCreationAdmissionShellBlocked
        this.didPreserveRendererRealEncoderShellIntent =
            didPreserveRendererRealEncoderShellIntent
        this.didDefineOwnerLocalEncoderCreationAdmissionShell =
            didDefineOwnerLocalEncoderCreationAdmissionShell
        this.didConfirmNoConcreteEncoderObject =
            didConfirmNoConcreteEncoderObject
        this.didConfirmNoEncoderFactoryInvocation =
            didConfirmNoEncoderFactoryInvocation
        this.didConfirmNoRenderPassDescriptorMutation =
            didConfirmNoRenderPassDescriptorMutation
        this.didKeepEncoderCreationAdmissionShellDehydrated =
            didKeepEncoderCreationAdmissionShellDehydrated
        this.didAvoidEncoderReadyWrapper = didAvoidEncoderReadyWrapper
        this.didAvoidRenderPassReadyWrapper = didAvoidRenderPassReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealEncoderBindingDenialProof {
    let creationAdmissionShell:
        CjguiInternalRendererRealEncoderCreationAdmissionShell
    let didPrepareRendererRealEncoderBindingDenialProof: Bool
    let shouldDeferRendererRealEncoderBindingDenialProof: Bool
    let shouldReportRendererRealEncoderBindingDenialProofBlocked: Bool
    let didPreserveRendererRealEncoderCreationAdmissionShell: Bool
    let didDefineOwnerLocalEncoderBindingDenialProof: Bool
    let didConfirmNoPipelineBinding: Bool
    let didConfirmNoBufferBinding: Bool
    let didConfirmNoTextureBinding: Bool
    let didConfirmNoResourceBinding: Bool
    let didKeepEncoderBindingDenialProofDehydrated: Bool
    let didAvoidBindingReadyWrapper: Bool
    let didAvoidResourceBindingWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        creationAdmissionShell:
            CjguiInternalRendererRealEncoderCreationAdmissionShell,
        didPrepareRendererRealEncoderBindingDenialProof: Bool,
        shouldDeferRendererRealEncoderBindingDenialProof: Bool,
        shouldReportRendererRealEncoderBindingDenialProofBlocked: Bool,
        didPreserveRendererRealEncoderCreationAdmissionShell: Bool,
        didDefineOwnerLocalEncoderBindingDenialProof: Bool,
        didConfirmNoPipelineBinding: Bool,
        didConfirmNoBufferBinding: Bool,
        didConfirmNoTextureBinding: Bool,
        didConfirmNoResourceBinding: Bool,
        didKeepEncoderBindingDenialProofDehydrated: Bool,
        didAvoidBindingReadyWrapper: Bool,
        didAvoidResourceBindingWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.creationAdmissionShell = creationAdmissionShell
        this.didPrepareRendererRealEncoderBindingDenialProof =
            didPrepareRendererRealEncoderBindingDenialProof
        this.shouldDeferRendererRealEncoderBindingDenialProof =
            shouldDeferRendererRealEncoderBindingDenialProof
        this.shouldReportRendererRealEncoderBindingDenialProofBlocked =
            shouldReportRendererRealEncoderBindingDenialProofBlocked
        this.didPreserveRendererRealEncoderCreationAdmissionShell =
            didPreserveRendererRealEncoderCreationAdmissionShell
        this.didDefineOwnerLocalEncoderBindingDenialProof =
            didDefineOwnerLocalEncoderBindingDenialProof
        this.didConfirmNoPipelineBinding = didConfirmNoPipelineBinding
        this.didConfirmNoBufferBinding = didConfirmNoBufferBinding
        this.didConfirmNoTextureBinding = didConfirmNoTextureBinding
        this.didConfirmNoResourceBinding = didConfirmNoResourceBinding
        this.didKeepEncoderBindingDenialProofDehydrated =
            didKeepEncoderBindingDenialProofDehydrated
        this.didAvoidBindingReadyWrapper = didAvoidBindingReadyWrapper
        this.didAvoidResourceBindingWrapper = didAvoidResourceBindingWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealEncoderEndEncodingDenialProof {
    let bindingDenialProof:
        CjguiInternalRendererRealEncoderBindingDenialProof
    let didPrepareRendererRealEncoderEndEncodingDenialProof: Bool
    let shouldDeferRendererRealEncoderEndEncodingDenialProof: Bool
    let shouldReportRendererRealEncoderEndEncodingDenialProofBlocked: Bool
    let didPreserveRendererRealEncoderBindingDenialProof: Bool
    let didDefineOwnerLocalEncoderEndEncodingDenialProof: Bool
    let didConfirmNoEndEncodingInvocation: Bool
    let didConfirmNoCommandBufferFinalizeRelation: Bool
    let didConfirmNoWorkSubmissionRelation: Bool
    let didConfirmNoCompletionObservation: Bool
    let didKeepEncoderEndEncodingDenialProofDehydrated: Bool
    let didAvoidEndEncodingReadyWrapper: Bool
    let didAvoidWorkSubmitWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        bindingDenialProof:
            CjguiInternalRendererRealEncoderBindingDenialProof,
        didPrepareRendererRealEncoderEndEncodingDenialProof: Bool,
        shouldDeferRendererRealEncoderEndEncodingDenialProof: Bool,
        shouldReportRendererRealEncoderEndEncodingDenialProofBlocked: Bool,
        didPreserveRendererRealEncoderBindingDenialProof: Bool,
        didDefineOwnerLocalEncoderEndEncodingDenialProof: Bool,
        didConfirmNoEndEncodingInvocation: Bool,
        didConfirmNoCommandBufferFinalizeRelation: Bool,
        didConfirmNoWorkSubmissionRelation: Bool,
        didConfirmNoCompletionObservation: Bool,
        didKeepEncoderEndEncodingDenialProofDehydrated: Bool,
        didAvoidEndEncodingReadyWrapper: Bool,
        didAvoidWorkSubmitWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.bindingDenialProof = bindingDenialProof
        this.didPrepareRendererRealEncoderEndEncodingDenialProof =
            didPrepareRendererRealEncoderEndEncodingDenialProof
        this.shouldDeferRendererRealEncoderEndEncodingDenialProof =
            shouldDeferRendererRealEncoderEndEncodingDenialProof
        this.shouldReportRendererRealEncoderEndEncodingDenialProofBlocked =
            shouldReportRendererRealEncoderEndEncodingDenialProofBlocked
        this.didPreserveRendererRealEncoderBindingDenialProof =
            didPreserveRendererRealEncoderBindingDenialProof
        this.didDefineOwnerLocalEncoderEndEncodingDenialProof =
            didDefineOwnerLocalEncoderEndEncodingDenialProof
        this.didConfirmNoEndEncodingInvocation =
            didConfirmNoEndEncodingInvocation
        this.didConfirmNoCommandBufferFinalizeRelation =
            didConfirmNoCommandBufferFinalizeRelation
        this.didConfirmNoWorkSubmissionRelation =
            didConfirmNoWorkSubmissionRelation
        this.didConfirmNoCompletionObservation =
            didConfirmNoCompletionObservation
        this.didKeepEncoderEndEncodingDenialProofDehydrated =
            didKeepEncoderEndEncodingDenialProofDehydrated
        this.didAvoidEndEncodingReadyWrapper =
            didAvoidEndEncodingReadyWrapper
        this.didAvoidWorkSubmitWrapper = didAvoidWorkSubmitWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealEncoderTeardownFailureClassification {
    let endEncodingDenialProof:
        CjguiInternalRendererRealEncoderEndEncodingDenialProof
    let didPrepareRendererRealEncoderTeardownFailureClassification: Bool
    let shouldDeferRendererRealEncoderTeardownFailureClassification: Bool
    let shouldReportRendererRealEncoderTeardownFailureClassificationBlocked:
        Bool
    let didPreserveRendererRealEncoderEndEncodingDenialProof: Bool
    let didDefineOwnerLocalEncoderTeardownFailureClassification: Bool
    let didFailClosedMissingEncoderObject: Bool
    let didFailClosedWrongThreadRisk: Bool
    let didFailClosedStaleEncodingScopeRisk: Bool
    let didFailClosedBridgeOptimism: Bool
    let didConfirmNoFailurePublication: Bool
    let didConfirmNoPublicDiagnostics: Bool
    let didKeepEncoderTeardownFailureDehydrated: Bool
    let didAvoidEncoderReadyWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        endEncodingDenialProof:
            CjguiInternalRendererRealEncoderEndEncodingDenialProof,
        didPrepareRendererRealEncoderTeardownFailureClassification: Bool,
        shouldDeferRendererRealEncoderTeardownFailureClassification: Bool,
        shouldReportRendererRealEncoderTeardownFailureClassificationBlocked:
            Bool,
        didPreserveRendererRealEncoderEndEncodingDenialProof: Bool,
        didDefineOwnerLocalEncoderTeardownFailureClassification: Bool,
        didFailClosedMissingEncoderObject: Bool,
        didFailClosedWrongThreadRisk: Bool,
        didFailClosedStaleEncodingScopeRisk: Bool,
        didFailClosedBridgeOptimism: Bool,
        didConfirmNoFailurePublication: Bool,
        didConfirmNoPublicDiagnostics: Bool,
        didKeepEncoderTeardownFailureDehydrated: Bool,
        didAvoidEncoderReadyWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.endEncodingDenialProof = endEncodingDenialProof
        this.didPrepareRendererRealEncoderTeardownFailureClassification =
            didPrepareRendererRealEncoderTeardownFailureClassification
        this.shouldDeferRendererRealEncoderTeardownFailureClassification =
            shouldDeferRendererRealEncoderTeardownFailureClassification
        this
            .shouldReportRendererRealEncoderTeardownFailureClassificationBlocked =
            shouldReportRendererRealEncoderTeardownFailureClassificationBlocked
        this.didPreserveRendererRealEncoderEndEncodingDenialProof =
            didPreserveRendererRealEncoderEndEncodingDenialProof
        this.didDefineOwnerLocalEncoderTeardownFailureClassification =
            didDefineOwnerLocalEncoderTeardownFailureClassification
        this.didFailClosedMissingEncoderObject =
            didFailClosedMissingEncoderObject
        this.didFailClosedWrongThreadRisk = didFailClosedWrongThreadRisk
        this.didFailClosedStaleEncodingScopeRisk =
            didFailClosedStaleEncodingScopeRisk
        this.didFailClosedBridgeOptimism = didFailClosedBridgeOptimism
        this.didConfirmNoFailurePublication =
            didConfirmNoFailurePublication
        this.didConfirmNoPublicDiagnostics = didConfirmNoPublicDiagnostics
        this.didKeepEncoderTeardownFailureDehydrated =
            didKeepEncoderTeardownFailureDehydrated
        this.didAvoidEncoderReadyWrapper = didAvoidEncoderReadyWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoRealEncoderShellReadiness {
    let teardownFailureClassification:
        CjguiInternalRendererRealEncoderTeardownFailureClassification
    let isRendererNoRealEncoderShellReady: Bool
    let canFutureRendererRealEncoderShellBoundaryEvaluate: Bool
    let shouldDeferRendererNoRealEncoderShellReadiness: Bool
    let shouldReportRendererNoRealEncoderShellReadinessBlocked: Bool
    let didSealRendererNoRealEncoderShellReadiness: Bool
    let didPreserveRendererRealEncoderTeardownFailureClassification: Bool
    let didKeepNoRealEncoderShellReadinessDehydrated: Bool
    let didConfirmNoConcreteEncoderObject: Bool
    let didConfirmNoEncoderFactoryInvocation: Bool
    let didConfirmNoEndEncodingInvocation: Bool
    let didConfirmNoPipelineBinding: Bool
    let didConfirmNoBufferBinding: Bool
    let didConfirmNoTextureBinding: Bool
    let didConfirmNoResourceBinding: Bool
    let didConfirmNoRenderPassDescriptorMutation: Bool
    let didConfirmNoCommandBufferFactoryInvocation: Bool
    let didConfirmNoWorkFinalize: Bool
    let didConfirmNoPresentationCall: Bool
    let didConfirmNoDrawableAcquisition: Bool
    let didConfirmNoDrawCall: Bool
    let didConfirmNoWorkSubmit: Bool
    let didConfirmNoNativeResourceStored: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoStateMutation: Bool
    let didConfirmNoRuntimeStateTouch: Bool
    let didConfirmNoModuleLevelMutableState: Bool
    let didConfirmNoPublicDiagnostics: Bool
    let didAvoidEncoderReadyWrapper: Bool
    let didAvoidBindingReadyWrapper: Bool
    let didAvoidRenderPassReadyWrapper: Bool
    let didAvoidCommandBufferReadyWrapper: Bool
    let didAvoidWorkSubmitWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidStateMutationWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        teardownFailureClassification:
            CjguiInternalRendererRealEncoderTeardownFailureClassification,
        isRendererNoRealEncoderShellReady: Bool,
        canFutureRendererRealEncoderShellBoundaryEvaluate: Bool,
        shouldDeferRendererNoRealEncoderShellReadiness: Bool,
        shouldReportRendererNoRealEncoderShellReadinessBlocked: Bool,
        didSealRendererNoRealEncoderShellReadiness: Bool,
        didPreserveRendererRealEncoderTeardownFailureClassification: Bool,
        didKeepNoRealEncoderShellReadinessDehydrated: Bool,
        didConfirmNoConcreteEncoderObject: Bool,
        didConfirmNoEncoderFactoryInvocation: Bool,
        didConfirmNoEndEncodingInvocation: Bool,
        didConfirmNoPipelineBinding: Bool,
        didConfirmNoBufferBinding: Bool,
        didConfirmNoTextureBinding: Bool,
        didConfirmNoResourceBinding: Bool,
        didConfirmNoRenderPassDescriptorMutation: Bool,
        didConfirmNoCommandBufferFactoryInvocation: Bool,
        didConfirmNoWorkFinalize: Bool,
        didConfirmNoPresentationCall: Bool,
        didConfirmNoDrawableAcquisition: Bool,
        didConfirmNoDrawCall: Bool,
        didConfirmNoWorkSubmit: Bool,
        didConfirmNoNativeResourceStored: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoStateMutation: Bool,
        didConfirmNoRuntimeStateTouch: Bool,
        didConfirmNoModuleLevelMutableState: Bool,
        didConfirmNoPublicDiagnostics: Bool,
        didAvoidEncoderReadyWrapper: Bool,
        didAvoidBindingReadyWrapper: Bool,
        didAvoidRenderPassReadyWrapper: Bool,
        didAvoidCommandBufferReadyWrapper: Bool,
        didAvoidWorkSubmitWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidStateMutationWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.teardownFailureClassification = teardownFailureClassification
        this.isRendererNoRealEncoderShellReady =
            isRendererNoRealEncoderShellReady
        this.canFutureRendererRealEncoderShellBoundaryEvaluate =
            canFutureRendererRealEncoderShellBoundaryEvaluate
        this.shouldDeferRendererNoRealEncoderShellReadiness =
            shouldDeferRendererNoRealEncoderShellReadiness
        this.shouldReportRendererNoRealEncoderShellReadinessBlocked =
            shouldReportRendererNoRealEncoderShellReadinessBlocked
        this.didSealRendererNoRealEncoderShellReadiness =
            didSealRendererNoRealEncoderShellReadiness
        this.didPreserveRendererRealEncoderTeardownFailureClassification =
            didPreserveRendererRealEncoderTeardownFailureClassification
        this.didKeepNoRealEncoderShellReadinessDehydrated =
            didKeepNoRealEncoderShellReadinessDehydrated
        this.didConfirmNoConcreteEncoderObject =
            didConfirmNoConcreteEncoderObject
        this.didConfirmNoEncoderFactoryInvocation =
            didConfirmNoEncoderFactoryInvocation
        this.didConfirmNoEndEncodingInvocation =
            didConfirmNoEndEncodingInvocation
        this.didConfirmNoPipelineBinding = didConfirmNoPipelineBinding
        this.didConfirmNoBufferBinding = didConfirmNoBufferBinding
        this.didConfirmNoTextureBinding = didConfirmNoTextureBinding
        this.didConfirmNoResourceBinding = didConfirmNoResourceBinding
        this.didConfirmNoRenderPassDescriptorMutation =
            didConfirmNoRenderPassDescriptorMutation
        this.didConfirmNoCommandBufferFactoryInvocation =
            didConfirmNoCommandBufferFactoryInvocation
        this.didConfirmNoWorkFinalize = didConfirmNoWorkFinalize
        this.didConfirmNoPresentationCall = didConfirmNoPresentationCall
        this.didConfirmNoDrawableAcquisition =
            didConfirmNoDrawableAcquisition
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
        this.didAvoidEncoderReadyWrapper = didAvoidEncoderReadyWrapper
        this.didAvoidBindingReadyWrapper = didAvoidBindingReadyWrapper
        this.didAvoidRenderPassReadyWrapper = didAvoidRenderPassReadyWrapper
        this.didAvoidCommandBufferReadyWrapper =
            didAvoidCommandBufferReadyWrapper
        this.didAvoidWorkSubmitWrapper = didAvoidWorkSubmitWrapper
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidStateMutationWrapper = didAvoidStateMutationWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererRealEncoderShellIntent(
    noRealRenderPassShellReadiness:
        CjguiInternalRendererNoRealRenderPassShellReadiness
): CjguiInternalRendererRealEncoderShellIntent {
    let upstreamReady =
        noRealRenderPassShellReadiness
            .isRendererNoRealRenderPassShellReady &&
        noRealRenderPassShellReadiness
            .canFutureRendererRealRenderPassShellBoundaryEvaluate &&
        noRealRenderPassShellReadiness
            .didSealRendererNoRealRenderPassShellReadiness &&
        noRealRenderPassShellReadiness
            .didPreserveRendererRealRenderPassTeardownFailureClassification &&
        noRealRenderPassShellReadiness
            .didKeepNoRealRenderPassShellReadinessDehydrated &&
        noRealRenderPassShellReadiness
            .didConfirmNoConcreteRenderPassDescriptor &&
        noRealRenderPassShellReadiness.didConfirmNoAttachmentObject &&
        noRealRenderPassShellReadiness.didConfirmNoAttachmentTextureView &&
        noRealRenderPassShellReadiness.didConfirmNoDrawableTextureExposure &&
        noRealRenderPassShellReadiness.didConfirmNoEncodingObject &&
        noRealRenderPassShellReadiness.didConfirmNoEncoderFactoryInvocation &&
        noRealRenderPassShellReadiness.didConfirmNoEncodingFinalization &&
        noRealRenderPassShellReadiness
            .didConfirmNoCommandBufferFactoryInvocation &&
        noRealRenderPassShellReadiness.didConfirmNoWorkFinalize &&
        noRealRenderPassShellReadiness.didConfirmNoPresentationCall &&
        noRealRenderPassShellReadiness.didConfirmNoDrawableAcquisition &&
        noRealRenderPassShellReadiness.didConfirmNoPipelineRelation &&
        noRealRenderPassShellReadiness.didConfirmNoDrawCall &&
        noRealRenderPassShellReadiness.didConfirmNoWorkSubmit &&
        noRealRenderPassShellReadiness.didConfirmNoNativeResourceStored &&
        noRealRenderPassShellReadiness.didConfirmNoPointerLikeResource &&
        noRealRenderPassShellReadiness.didConfirmNoRenderExecution &&
        noRealRenderPassShellReadiness.didConfirmNoStateMutation &&
        noRealRenderPassShellReadiness.didConfirmNoRuntimeStateTouch &&
        noRealRenderPassShellReadiness
            .didConfirmNoModuleLevelMutableState &&
        noRealRenderPassShellReadiness.didConfirmNoPublicDiagnostics &&
        noRealRenderPassShellReadiness.didAvoidRenderPassReadyWrapper &&
        noRealRenderPassShellReadiness.didAvoidEncoderReadyWrapper &&
        noRealRenderPassShellReadiness.didAvoidCommandBufferReadyWrapper &&
        noRealRenderPassShellReadiness.didAvoidWorkSubmitWrapper &&
        noRealRenderPassShellReadiness.didAvoidRenderPermissionWrapper &&
        noRealRenderPassShellReadiness.didAvoidStateMutationWrapper &&
        noRealRenderPassShellReadiness.didAvoidReceiptRecordOutput &&
        noRealRenderPassShellReadiness.didAvoidThinWrapper &&
        noRealRenderPassShellReadiness.didStayFullRebuildOnly &&
        noRealRenderPassShellReadiness
            .shouldDeferRendererNoRealRenderPassShellReadiness == false &&
        noRealRenderPassShellReadiness
            .shouldReportRendererNoRealRenderPassShellReadinessBlocked ==
            false
    let upstreamDeferred =
        noRealRenderPassShellReadiness
            .isRendererNoRealRenderPassShellReady == false &&
        noRealRenderPassShellReadiness
            .canFutureRendererRealRenderPassShellBoundaryEvaluate ==
            false &&
        noRealRenderPassShellReadiness
            .shouldDeferRendererNoRealRenderPassShellReadiness &&
        noRealRenderPassShellReadiness
            .shouldReportRendererNoRealRenderPassShellReadinessBlocked ==
            false
    let upstreamInconsistent =
        noRealRenderPassShellReadiness
            .shouldReportRendererNoRealRenderPassShellReadinessBlocked ||
        (
            noRealRenderPassShellReadiness
                .isRendererNoRealRenderPassShellReady &&
            (
                upstreamReady == false ||
                noRealRenderPassShellReadiness
                    .shouldDeferRendererNoRealRenderPassShellReadiness
            )
        ) ||
        (
            noRealRenderPassShellReadiness
                .canFutureRendererRealRenderPassShellBoundaryEvaluate &&
            noRealRenderPassShellReadiness
                .isRendererNoRealRenderPassShellReady == false
        )

    if (upstreamInconsistent) {
        return CjguiInternalRendererRealEncoderShellIntent(
            noRealRenderPassShellReadiness,
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
        return CjguiInternalRendererRealEncoderShellIntent(
            noRealRenderPassShellReadiness,
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
        return CjguiInternalRendererRealEncoderShellIntent(
            noRealRenderPassShellReadiness,
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

    return CjguiInternalRendererRealEncoderShellIntent(
        noRealRenderPassShellReadiness,
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

func cjguiInternalBuildRendererRealEncoderCreationAdmissionShell(
    shellIntent:
        CjguiInternalRendererRealEncoderShellIntent
): CjguiInternalRendererRealEncoderCreationAdmissionShell {
    let intentReady =
        shellIntent.didPrepareRendererRealEncoderShellIntent &&
        shellIntent.didPreserveRendererNoRealRenderPassShellReadiness &&
        shellIntent.didDefineFutureEncoderShellIntent &&
        shellIntent.didDescribeEncoderCreationAdmissionNeed &&
        shellIntent.didDescribeBindingDenialNeed &&
        shellIntent.didDescribeEndEncodingDenialNeed &&
        shellIntent.didDescribeEncoderFailureClassificationNeed &&
        shellIntent.didKeepEncoderShellIntentDehydrated &&
        shellIntent.didAvoidEncoderReadyWrapper &&
        shellIntent.didAvoidRenderPassReadyWrapper &&
        shellIntent.didAvoidReceiptRecordOutput &&
        shellIntent.didAvoidThinWrapper &&
        shellIntent.shouldDeferRendererRealEncoderShellIntent == false &&
        shellIntent
            .shouldReportRendererRealEncoderShellIntentBlocked == false
    let intentDeferred =
        shellIntent.didPrepareRendererRealEncoderShellIntent == false &&
        shellIntent.shouldDeferRendererRealEncoderShellIntent &&
        shellIntent
            .shouldReportRendererRealEncoderShellIntentBlocked == false
    let intentInconsistent =
        shellIntent.shouldReportRendererRealEncoderShellIntentBlocked ||
        (
            shellIntent.didPrepareRendererRealEncoderShellIntent &&
            intentReady == false
        )

    return CjguiInternalRendererRealEncoderCreationAdmissionShell(
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

func cjguiInternalBuildRendererRealEncoderBindingDenialProof(
    creationAdmissionShell:
        CjguiInternalRendererRealEncoderCreationAdmissionShell
): CjguiInternalRendererRealEncoderBindingDenialProof {
    let shellReady =
        creationAdmissionShell
            .didPrepareRendererRealEncoderCreationAdmissionShell &&
        creationAdmissionShell.didPreserveRendererRealEncoderShellIntent &&
        creationAdmissionShell
            .didDefineOwnerLocalEncoderCreationAdmissionShell &&
        creationAdmissionShell.didConfirmNoConcreteEncoderObject &&
        creationAdmissionShell.didConfirmNoEncoderFactoryInvocation &&
        creationAdmissionShell.didConfirmNoRenderPassDescriptorMutation &&
        creationAdmissionShell
            .didKeepEncoderCreationAdmissionShellDehydrated &&
        creationAdmissionShell.didAvoidEncoderReadyWrapper &&
        creationAdmissionShell.didAvoidRenderPassReadyWrapper &&
        creationAdmissionShell.didAvoidThinWrapper &&
        creationAdmissionShell
            .shouldDeferRendererRealEncoderCreationAdmissionShell == false &&
        creationAdmissionShell
            .shouldReportRendererRealEncoderCreationAdmissionShellBlocked ==
            false
    let shellDeferred =
        creationAdmissionShell
            .didPrepareRendererRealEncoderCreationAdmissionShell == false &&
        creationAdmissionShell
            .shouldDeferRendererRealEncoderCreationAdmissionShell &&
        creationAdmissionShell
            .shouldReportRendererRealEncoderCreationAdmissionShellBlocked ==
            false
    let shellInconsistent =
        creationAdmissionShell
            .shouldReportRendererRealEncoderCreationAdmissionShellBlocked ||
        (
            creationAdmissionShell
                .didPrepareRendererRealEncoderCreationAdmissionShell &&
            shellReady == false
        )

    return CjguiInternalRendererRealEncoderBindingDenialProof(
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
        true,
        true
    )
}

func cjguiInternalBuildRendererRealEncoderEndEncodingDenialProof(
    bindingDenialProof:
        CjguiInternalRendererRealEncoderBindingDenialProof
): CjguiInternalRendererRealEncoderEndEncodingDenialProof {
    let proofReady =
        bindingDenialProof
            .didPrepareRendererRealEncoderBindingDenialProof &&
        bindingDenialProof
            .didPreserveRendererRealEncoderCreationAdmissionShell &&
        bindingDenialProof.didDefineOwnerLocalEncoderBindingDenialProof &&
        bindingDenialProof.didConfirmNoPipelineBinding &&
        bindingDenialProof.didConfirmNoBufferBinding &&
        bindingDenialProof.didConfirmNoTextureBinding &&
        bindingDenialProof.didConfirmNoResourceBinding &&
        bindingDenialProof.didKeepEncoderBindingDenialProofDehydrated &&
        bindingDenialProof.didAvoidBindingReadyWrapper &&
        bindingDenialProof.didAvoidResourceBindingWrapper &&
        bindingDenialProof.didAvoidThinWrapper &&
        bindingDenialProof
            .shouldDeferRendererRealEncoderBindingDenialProof == false &&
        bindingDenialProof
            .shouldReportRendererRealEncoderBindingDenialProofBlocked ==
            false
    let proofDeferred =
        bindingDenialProof
            .didPrepareRendererRealEncoderBindingDenialProof == false &&
        bindingDenialProof.shouldDeferRendererRealEncoderBindingDenialProof &&
        bindingDenialProof
            .shouldReportRendererRealEncoderBindingDenialProofBlocked ==
            false
    let proofInconsistent =
        bindingDenialProof
            .shouldReportRendererRealEncoderBindingDenialProofBlocked ||
        (
            bindingDenialProof
                .didPrepareRendererRealEncoderBindingDenialProof &&
            proofReady == false
        )

    return CjguiInternalRendererRealEncoderEndEncodingDenialProof(
        bindingDenialProof,
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
        true
    )
}

func cjguiInternalBuildRendererRealEncoderTeardownFailureClassification(
    endEncodingDenialProof:
        CjguiInternalRendererRealEncoderEndEncodingDenialProof
): CjguiInternalRendererRealEncoderTeardownFailureClassification {
    let proofReady =
        endEncodingDenialProof
            .didPrepareRendererRealEncoderEndEncodingDenialProof &&
        endEncodingDenialProof
            .didPreserveRendererRealEncoderBindingDenialProof &&
        endEncodingDenialProof
            .didDefineOwnerLocalEncoderEndEncodingDenialProof &&
        endEncodingDenialProof.didConfirmNoEndEncodingInvocation &&
        endEncodingDenialProof.didConfirmNoCommandBufferFinalizeRelation &&
        endEncodingDenialProof.didConfirmNoWorkSubmissionRelation &&
        endEncodingDenialProof.didConfirmNoCompletionObservation &&
        endEncodingDenialProof
            .didKeepEncoderEndEncodingDenialProofDehydrated &&
        endEncodingDenialProof.didAvoidEndEncodingReadyWrapper &&
        endEncodingDenialProof.didAvoidWorkSubmitWrapper &&
        endEncodingDenialProof.didAvoidThinWrapper &&
        endEncodingDenialProof
            .shouldDeferRendererRealEncoderEndEncodingDenialProof == false &&
        endEncodingDenialProof
            .shouldReportRendererRealEncoderEndEncodingDenialProofBlocked ==
            false
    let proofDeferred =
        endEncodingDenialProof
            .didPrepareRendererRealEncoderEndEncodingDenialProof == false &&
        endEncodingDenialProof
            .shouldDeferRendererRealEncoderEndEncodingDenialProof &&
        endEncodingDenialProof
            .shouldReportRendererRealEncoderEndEncodingDenialProofBlocked ==
            false
    let proofInconsistent =
        endEncodingDenialProof
            .shouldReportRendererRealEncoderEndEncodingDenialProofBlocked ||
        (
            endEncodingDenialProof
                .didPrepareRendererRealEncoderEndEncodingDenialProof &&
            proofReady == false
        )

    return CjguiInternalRendererRealEncoderTeardownFailureClassification(
        endEncodingDenialProof,
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

func cjguiInternalBuildRendererNoRealEncoderShellReadiness(
    teardownFailureClassification:
        CjguiInternalRendererRealEncoderTeardownFailureClassification
): CjguiInternalRendererNoRealEncoderShellReadiness {
    let failureReady =
        teardownFailureClassification
            .didPrepareRendererRealEncoderTeardownFailureClassification &&
        teardownFailureClassification
            .didPreserveRendererRealEncoderEndEncodingDenialProof &&
        teardownFailureClassification
            .didDefineOwnerLocalEncoderTeardownFailureClassification &&
        teardownFailureClassification.didFailClosedMissingEncoderObject &&
        teardownFailureClassification.didFailClosedWrongThreadRisk &&
        teardownFailureClassification.didFailClosedStaleEncodingScopeRisk &&
        teardownFailureClassification.didFailClosedBridgeOptimism &&
        teardownFailureClassification.didConfirmNoFailurePublication &&
        teardownFailureClassification.didConfirmNoPublicDiagnostics &&
        teardownFailureClassification
            .didKeepEncoderTeardownFailureDehydrated &&
        teardownFailureClassification.didAvoidEncoderReadyWrapper &&
        teardownFailureClassification.didAvoidReceiptRecordOutput &&
        teardownFailureClassification.didAvoidThinWrapper &&
        teardownFailureClassification
            .shouldDeferRendererRealEncoderTeardownFailureClassification ==
            false &&
        teardownFailureClassification
            .shouldReportRendererRealEncoderTeardownFailureClassificationBlocked ==
            false
    let failureDeferred =
        teardownFailureClassification
            .didPrepareRendererRealEncoderTeardownFailureClassification ==
            false &&
        teardownFailureClassification
            .shouldDeferRendererRealEncoderTeardownFailureClassification &&
        teardownFailureClassification
            .shouldReportRendererRealEncoderTeardownFailureClassificationBlocked ==
            false
    let failureInconsistent =
        teardownFailureClassification
            .shouldReportRendererRealEncoderTeardownFailureClassificationBlocked ||
        (
            teardownFailureClassification
                .didPrepareRendererRealEncoderTeardownFailureClassification &&
            failureReady == false
        )

    return CjguiInternalRendererNoRealEncoderShellReadiness(
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
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererRealEncoderShellDraft():
    CjguiInternalRendererNoRealEncoderShellReadiness {
    let noRealRenderPassShellReadiness =
        cjguiInternalExecuteDefaultRendererRealRenderPassShellDraft()
    let shellIntent =
        cjguiInternalBuildRendererRealEncoderShellIntent(
            noRealRenderPassShellReadiness
        )
    let creationAdmissionShell =
        cjguiInternalBuildRendererRealEncoderCreationAdmissionShell(
            shellIntent
        )
    let bindingDenialProof =
        cjguiInternalBuildRendererRealEncoderBindingDenialProof(
            creationAdmissionShell
        )
    let endEncodingDenialProof =
        cjguiInternalBuildRendererRealEncoderEndEncodingDenialProof(
            bindingDenialProof
        )
    let teardownFailureClassification =
        cjguiInternalBuildRendererRealEncoderTeardownFailureClassification(
            endEncodingDenialProof
        )
    return cjguiInternalBuildRendererNoRealEncoderShellReadiness(
        teardownFailureClassification
    )
}
