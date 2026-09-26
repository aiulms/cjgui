// Owner: real render pass 第一刀 internal-only shell 边界。
// Truth: 只消费 CjguiInternalRendererNoRealCommandBufferShellReadiness，并记录
// render pass shell intent、descriptor admission shell、attachment denial proof、
// encoder denial proof、teardown / failure classification 与
// no-real-render-pass-shell readiness facts。
// Stop-line: 只产出 internal-only shell / dehydrated facts；不是 render pass
// descriptor、attachment、texture view、renderCommandEncoder、endEncoding、
// commandBuffer、commit、present、nextDrawable、GPU work、native bridge、
// native handle、C ABI / FFI、renderer state write 或 public API 许可。
// Same-shape Boundary Brake: 不得把本 shell 包成 render-pass-ready、
// encoder-ready、GPU-submission、render-permission、renderer-state-write、
// receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererRealRenderPassShellIntent {
    let noRealCommandBufferShellReadiness:
        CjguiInternalRendererNoRealCommandBufferShellReadiness
    let didPrepareRendererRealRenderPassShellIntent: Bool
    let shouldDeferRendererRealRenderPassShellIntent: Bool
    let shouldReportRendererRealRenderPassShellIntentBlocked: Bool
    let didPreserveRendererNoRealCommandBufferShellReadiness: Bool
    let didDefineFutureRenderPassShellIntent: Bool
    let didDescribeRenderPassDescriptorAdmissionNeed: Bool
    let didDescribeAttachmentDenialNeed: Bool
    let didDescribeEncoderDenialNeed: Bool
    let didDescribeRenderPassFailureClassificationNeed: Bool
    let didKeepRenderPassShellIntentDehydrated: Bool
    let didAvoidRenderPassReadyWrapper: Bool
    let didAvoidCommandBufferReadyWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        noRealCommandBufferShellReadiness:
            CjguiInternalRendererNoRealCommandBufferShellReadiness,
        didPrepareRendererRealRenderPassShellIntent: Bool,
        shouldDeferRendererRealRenderPassShellIntent: Bool,
        shouldReportRendererRealRenderPassShellIntentBlocked: Bool,
        didPreserveRendererNoRealCommandBufferShellReadiness: Bool,
        didDefineFutureRenderPassShellIntent: Bool,
        didDescribeRenderPassDescriptorAdmissionNeed: Bool,
        didDescribeAttachmentDenialNeed: Bool,
        didDescribeEncoderDenialNeed: Bool,
        didDescribeRenderPassFailureClassificationNeed: Bool,
        didKeepRenderPassShellIntentDehydrated: Bool,
        didAvoidRenderPassReadyWrapper: Bool,
        didAvoidCommandBufferReadyWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noRealCommandBufferShellReadiness =
            noRealCommandBufferShellReadiness
        this.didPrepareRendererRealRenderPassShellIntent =
            didPrepareRendererRealRenderPassShellIntent
        this.shouldDeferRendererRealRenderPassShellIntent =
            shouldDeferRendererRealRenderPassShellIntent
        this.shouldReportRendererRealRenderPassShellIntentBlocked =
            shouldReportRendererRealRenderPassShellIntentBlocked
        this.didPreserveRendererNoRealCommandBufferShellReadiness =
            didPreserveRendererNoRealCommandBufferShellReadiness
        this.didDefineFutureRenderPassShellIntent =
            didDefineFutureRenderPassShellIntent
        this.didDescribeRenderPassDescriptorAdmissionNeed =
            didDescribeRenderPassDescriptorAdmissionNeed
        this.didDescribeAttachmentDenialNeed =
            didDescribeAttachmentDenialNeed
        this.didDescribeEncoderDenialNeed = didDescribeEncoderDenialNeed
        this.didDescribeRenderPassFailureClassificationNeed =
            didDescribeRenderPassFailureClassificationNeed
        this.didKeepRenderPassShellIntentDehydrated =
            didKeepRenderPassShellIntentDehydrated
        this.didAvoidRenderPassReadyWrapper = didAvoidRenderPassReadyWrapper
        this.didAvoidCommandBufferReadyWrapper =
            didAvoidCommandBufferReadyWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealRenderPassDescriptorAdmissionShell {
    let shellIntent: CjguiInternalRendererRealRenderPassShellIntent
    let didPrepareRendererRealRenderPassDescriptorAdmissionShell: Bool
    let shouldDeferRendererRealRenderPassDescriptorAdmissionShell: Bool
    let shouldReportRendererRealRenderPassDescriptorAdmissionShellBlocked:
        Bool
    let didPreserveRendererRealRenderPassShellIntent: Bool
    let didDefineOwnerLocalRenderPassDescriptorAdmissionShell: Bool
    let didConfirmNoConcreteRenderPassDescriptor: Bool
    let didConfirmNoAttachmentObject: Bool
    let didConfirmNoEncoderRelation: Bool
    let didKeepRenderPassDescriptorAdmissionShellDehydrated: Bool
    let didAvoidRenderPassReadyWrapper: Bool
    let didAvoidEncoderReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        shellIntent: CjguiInternalRendererRealRenderPassShellIntent,
        didPrepareRendererRealRenderPassDescriptorAdmissionShell: Bool,
        shouldDeferRendererRealRenderPassDescriptorAdmissionShell: Bool,
        shouldReportRendererRealRenderPassDescriptorAdmissionShellBlocked:
            Bool,
        didPreserveRendererRealRenderPassShellIntent: Bool,
        didDefineOwnerLocalRenderPassDescriptorAdmissionShell: Bool,
        didConfirmNoConcreteRenderPassDescriptor: Bool,
        didConfirmNoAttachmentObject: Bool,
        didConfirmNoEncoderRelation: Bool,
        didKeepRenderPassDescriptorAdmissionShellDehydrated: Bool,
        didAvoidRenderPassReadyWrapper: Bool,
        didAvoidEncoderReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.shellIntent = shellIntent
        this.didPrepareRendererRealRenderPassDescriptorAdmissionShell =
            didPrepareRendererRealRenderPassDescriptorAdmissionShell
        this.shouldDeferRendererRealRenderPassDescriptorAdmissionShell =
            shouldDeferRendererRealRenderPassDescriptorAdmissionShell
        this
            .shouldReportRendererRealRenderPassDescriptorAdmissionShellBlocked =
            shouldReportRendererRealRenderPassDescriptorAdmissionShellBlocked
        this.didPreserveRendererRealRenderPassShellIntent =
            didPreserveRendererRealRenderPassShellIntent
        this.didDefineOwnerLocalRenderPassDescriptorAdmissionShell =
            didDefineOwnerLocalRenderPassDescriptorAdmissionShell
        this.didConfirmNoConcreteRenderPassDescriptor =
            didConfirmNoConcreteRenderPassDescriptor
        this.didConfirmNoAttachmentObject = didConfirmNoAttachmentObject
        this.didConfirmNoEncoderRelation = didConfirmNoEncoderRelation
        this.didKeepRenderPassDescriptorAdmissionShellDehydrated =
            didKeepRenderPassDescriptorAdmissionShellDehydrated
        this.didAvoidRenderPassReadyWrapper = didAvoidRenderPassReadyWrapper
        this.didAvoidEncoderReadyWrapper = didAvoidEncoderReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealRenderPassAttachmentDenialProof {
    let descriptorAdmissionShell:
        CjguiInternalRendererRealRenderPassDescriptorAdmissionShell
    let didPrepareRendererRealRenderPassAttachmentDenialProof: Bool
    let shouldDeferRendererRealRenderPassAttachmentDenialProof: Bool
    let shouldReportRendererRealRenderPassAttachmentDenialProofBlocked: Bool
    let didPreserveRendererRealRenderPassDescriptorAdmissionShell: Bool
    let didDefineOwnerLocalRenderPassAttachmentDenialProof: Bool
    let didConfirmNoAttachmentTextureView: Bool
    let didConfirmNoDrawableTextureExposure: Bool
    let didConfirmNoResourceBindingRelation: Bool
    let didKeepRenderPassAttachmentDenialProofDehydrated: Bool
    let didAvoidAttachmentPermissionWrapper: Bool
    let didAvoidResourceBindingWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        descriptorAdmissionShell:
            CjguiInternalRendererRealRenderPassDescriptorAdmissionShell,
        didPrepareRendererRealRenderPassAttachmentDenialProof: Bool,
        shouldDeferRendererRealRenderPassAttachmentDenialProof: Bool,
        shouldReportRendererRealRenderPassAttachmentDenialProofBlocked: Bool,
        didPreserveRendererRealRenderPassDescriptorAdmissionShell: Bool,
        didDefineOwnerLocalRenderPassAttachmentDenialProof: Bool,
        didConfirmNoAttachmentTextureView: Bool,
        didConfirmNoDrawableTextureExposure: Bool,
        didConfirmNoResourceBindingRelation: Bool,
        didKeepRenderPassAttachmentDenialProofDehydrated: Bool,
        didAvoidAttachmentPermissionWrapper: Bool,
        didAvoidResourceBindingWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.descriptorAdmissionShell = descriptorAdmissionShell
        this.didPrepareRendererRealRenderPassAttachmentDenialProof =
            didPrepareRendererRealRenderPassAttachmentDenialProof
        this.shouldDeferRendererRealRenderPassAttachmentDenialProof =
            shouldDeferRendererRealRenderPassAttachmentDenialProof
        this.shouldReportRendererRealRenderPassAttachmentDenialProofBlocked =
            shouldReportRendererRealRenderPassAttachmentDenialProofBlocked
        this.didPreserveRendererRealRenderPassDescriptorAdmissionShell =
            didPreserveRendererRealRenderPassDescriptorAdmissionShell
        this.didDefineOwnerLocalRenderPassAttachmentDenialProof =
            didDefineOwnerLocalRenderPassAttachmentDenialProof
        this.didConfirmNoAttachmentTextureView =
            didConfirmNoAttachmentTextureView
        this.didConfirmNoDrawableTextureExposure =
            didConfirmNoDrawableTextureExposure
        this.didConfirmNoResourceBindingRelation =
            didConfirmNoResourceBindingRelation
        this.didKeepRenderPassAttachmentDenialProofDehydrated =
            didKeepRenderPassAttachmentDenialProofDehydrated
        this.didAvoidAttachmentPermissionWrapper =
            didAvoidAttachmentPermissionWrapper
        this.didAvoidResourceBindingWrapper = didAvoidResourceBindingWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealRenderPassEncoderDenialProof {
    let attachmentDenialProof:
        CjguiInternalRendererRealRenderPassAttachmentDenialProof
    let didPrepareRendererRealRenderPassEncoderDenialProof: Bool
    let shouldDeferRendererRealRenderPassEncoderDenialProof: Bool
    let shouldReportRendererRealRenderPassEncoderDenialProofBlocked: Bool
    let didPreserveRendererRealRenderPassAttachmentDenialProof: Bool
    let didDefineOwnerLocalRenderPassEncoderDenialProof: Bool
    let didConfirmNoEncodingObject: Bool
    let didConfirmNoEncoderFactoryInvocation: Bool
    let didConfirmNoEncodingFinalization: Bool
    let didConfirmNoPipelineRelation: Bool
    let didKeepRenderPassEncoderDenialProofDehydrated: Bool
    let didAvoidEncoderReadyWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        attachmentDenialProof:
            CjguiInternalRendererRealRenderPassAttachmentDenialProof,
        didPrepareRendererRealRenderPassEncoderDenialProof: Bool,
        shouldDeferRendererRealRenderPassEncoderDenialProof: Bool,
        shouldReportRendererRealRenderPassEncoderDenialProofBlocked: Bool,
        didPreserveRendererRealRenderPassAttachmentDenialProof: Bool,
        didDefineOwnerLocalRenderPassEncoderDenialProof: Bool,
        didConfirmNoEncodingObject: Bool,
        didConfirmNoEncoderFactoryInvocation: Bool,
        didConfirmNoEncodingFinalization: Bool,
        didConfirmNoPipelineRelation: Bool,
        didKeepRenderPassEncoderDenialProofDehydrated: Bool,
        didAvoidEncoderReadyWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.attachmentDenialProof = attachmentDenialProof
        this.didPrepareRendererRealRenderPassEncoderDenialProof =
            didPrepareRendererRealRenderPassEncoderDenialProof
        this.shouldDeferRendererRealRenderPassEncoderDenialProof =
            shouldDeferRendererRealRenderPassEncoderDenialProof
        this.shouldReportRendererRealRenderPassEncoderDenialProofBlocked =
            shouldReportRendererRealRenderPassEncoderDenialProofBlocked
        this.didPreserveRendererRealRenderPassAttachmentDenialProof =
            didPreserveRendererRealRenderPassAttachmentDenialProof
        this.didDefineOwnerLocalRenderPassEncoderDenialProof =
            didDefineOwnerLocalRenderPassEncoderDenialProof
        this.didConfirmNoEncodingObject = didConfirmNoEncodingObject
        this.didConfirmNoEncoderFactoryInvocation =
            didConfirmNoEncoderFactoryInvocation
        this.didConfirmNoEncodingFinalization =
            didConfirmNoEncodingFinalization
        this.didConfirmNoPipelineRelation = didConfirmNoPipelineRelation
        this.didKeepRenderPassEncoderDenialProofDehydrated =
            didKeepRenderPassEncoderDenialProofDehydrated
        this.didAvoidEncoderReadyWrapper = didAvoidEncoderReadyWrapper
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealRenderPassTeardownFailureClassification {
    let encoderDenialProof:
        CjguiInternalRendererRealRenderPassEncoderDenialProof
    let didPrepareRendererRealRenderPassTeardownFailureClassification: Bool
    let shouldDeferRendererRealRenderPassTeardownFailureClassification: Bool
    let shouldReportRendererRealRenderPassTeardownFailureClassificationBlocked:
        Bool
    let didPreserveRendererRealRenderPassEncoderDenialProof: Bool
    let didDefineOwnerLocalRenderPassTeardownFailureClassification: Bool
    let didFailClosedMissingRenderPassDescriptor: Bool
    let didFailClosedWrongThreadRisk: Bool
    let didFailClosedStaleAttachmentRisk: Bool
    let didFailClosedBridgeOptimism: Bool
    let didConfirmNoFailurePublication: Bool
    let didConfirmNoPublicDiagnostics: Bool
    let didKeepRenderPassTeardownFailureDehydrated: Bool
    let didAvoidRenderPassReadyWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        encoderDenialProof:
            CjguiInternalRendererRealRenderPassEncoderDenialProof,
        didPrepareRendererRealRenderPassTeardownFailureClassification: Bool,
        shouldDeferRendererRealRenderPassTeardownFailureClassification: Bool,
        shouldReportRendererRealRenderPassTeardownFailureClassificationBlocked:
            Bool,
        didPreserveRendererRealRenderPassEncoderDenialProof: Bool,
        didDefineOwnerLocalRenderPassTeardownFailureClassification: Bool,
        didFailClosedMissingRenderPassDescriptor: Bool,
        didFailClosedWrongThreadRisk: Bool,
        didFailClosedStaleAttachmentRisk: Bool,
        didFailClosedBridgeOptimism: Bool,
        didConfirmNoFailurePublication: Bool,
        didConfirmNoPublicDiagnostics: Bool,
        didKeepRenderPassTeardownFailureDehydrated: Bool,
        didAvoidRenderPassReadyWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.encoderDenialProof = encoderDenialProof
        this.didPrepareRendererRealRenderPassTeardownFailureClassification =
            didPrepareRendererRealRenderPassTeardownFailureClassification
        this.shouldDeferRendererRealRenderPassTeardownFailureClassification =
            shouldDeferRendererRealRenderPassTeardownFailureClassification
        this
            .shouldReportRendererRealRenderPassTeardownFailureClassificationBlocked =
            shouldReportRendererRealRenderPassTeardownFailureClassificationBlocked
        this.didPreserveRendererRealRenderPassEncoderDenialProof =
            didPreserveRendererRealRenderPassEncoderDenialProof
        this.didDefineOwnerLocalRenderPassTeardownFailureClassification =
            didDefineOwnerLocalRenderPassTeardownFailureClassification
        this.didFailClosedMissingRenderPassDescriptor =
            didFailClosedMissingRenderPassDescriptor
        this.didFailClosedWrongThreadRisk = didFailClosedWrongThreadRisk
        this.didFailClosedStaleAttachmentRisk =
            didFailClosedStaleAttachmentRisk
        this.didFailClosedBridgeOptimism = didFailClosedBridgeOptimism
        this.didConfirmNoFailurePublication =
            didConfirmNoFailurePublication
        this.didConfirmNoPublicDiagnostics = didConfirmNoPublicDiagnostics
        this.didKeepRenderPassTeardownFailureDehydrated =
            didKeepRenderPassTeardownFailureDehydrated
        this.didAvoidRenderPassReadyWrapper = didAvoidRenderPassReadyWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoRealRenderPassShellReadiness {
    let teardownFailureClassification:
        CjguiInternalRendererRealRenderPassTeardownFailureClassification
    let isRendererNoRealRenderPassShellReady: Bool
    let canFutureRendererRealRenderPassShellBoundaryEvaluate: Bool
    let shouldDeferRendererNoRealRenderPassShellReadiness: Bool
    let shouldReportRendererNoRealRenderPassShellReadinessBlocked: Bool
    let didSealRendererNoRealRenderPassShellReadiness: Bool
    let didPreserveRendererRealRenderPassTeardownFailureClassification:
        Bool
    let didKeepNoRealRenderPassShellReadinessDehydrated: Bool
    let didConfirmNoConcreteRenderPassDescriptor: Bool
    let didConfirmNoAttachmentObject: Bool
    let didConfirmNoAttachmentTextureView: Bool
    let didConfirmNoDrawableTextureExposure: Bool
    let didConfirmNoEncodingObject: Bool
    let didConfirmNoEncoderFactoryInvocation: Bool
    let didConfirmNoEncodingFinalization: Bool
    let didConfirmNoCommandBufferFactoryInvocation: Bool
    let didConfirmNoWorkFinalize: Bool
    let didConfirmNoPresentationCall: Bool
    let didConfirmNoDrawableAcquisition: Bool
    let didConfirmNoPipelineRelation: Bool
    let didConfirmNoDrawCall: Bool
    let didConfirmNoWorkSubmit: Bool
    let didConfirmNoNativeResourceStored: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoStateMutation: Bool
    let didConfirmNoRuntimeStateTouch: Bool
    let didConfirmNoModuleLevelMutableState: Bool
    let didConfirmNoPublicDiagnostics: Bool
    let didAvoidRenderPassReadyWrapper: Bool
    let didAvoidEncoderReadyWrapper: Bool
    let didAvoidCommandBufferReadyWrapper: Bool
    let didAvoidWorkSubmitWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidStateMutationWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        teardownFailureClassification:
            CjguiInternalRendererRealRenderPassTeardownFailureClassification,
        isRendererNoRealRenderPassShellReady: Bool,
        canFutureRendererRealRenderPassShellBoundaryEvaluate: Bool,
        shouldDeferRendererNoRealRenderPassShellReadiness: Bool,
        shouldReportRendererNoRealRenderPassShellReadinessBlocked: Bool,
        didSealRendererNoRealRenderPassShellReadiness: Bool,
        didPreserveRendererRealRenderPassTeardownFailureClassification:
            Bool,
        didKeepNoRealRenderPassShellReadinessDehydrated: Bool,
        didConfirmNoConcreteRenderPassDescriptor: Bool,
        didConfirmNoAttachmentObject: Bool,
        didConfirmNoAttachmentTextureView: Bool,
        didConfirmNoDrawableTextureExposure: Bool,
        didConfirmNoEncodingObject: Bool,
        didConfirmNoEncoderFactoryInvocation: Bool,
        didConfirmNoEncodingFinalization: Bool,
        didConfirmNoCommandBufferFactoryInvocation: Bool,
        didConfirmNoWorkFinalize: Bool,
        didConfirmNoPresentationCall: Bool,
        didConfirmNoDrawableAcquisition: Bool,
        didConfirmNoPipelineRelation: Bool,
        didConfirmNoDrawCall: Bool,
        didConfirmNoWorkSubmit: Bool,
        didConfirmNoNativeResourceStored: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoStateMutation: Bool,
        didConfirmNoRuntimeStateTouch: Bool,
        didConfirmNoModuleLevelMutableState: Bool,
        didConfirmNoPublicDiagnostics: Bool,
        didAvoidRenderPassReadyWrapper: Bool,
        didAvoidEncoderReadyWrapper: Bool,
        didAvoidCommandBufferReadyWrapper: Bool,
        didAvoidWorkSubmitWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidStateMutationWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.teardownFailureClassification = teardownFailureClassification
        this.isRendererNoRealRenderPassShellReady =
            isRendererNoRealRenderPassShellReady
        this.canFutureRendererRealRenderPassShellBoundaryEvaluate =
            canFutureRendererRealRenderPassShellBoundaryEvaluate
        this.shouldDeferRendererNoRealRenderPassShellReadiness =
            shouldDeferRendererNoRealRenderPassShellReadiness
        this.shouldReportRendererNoRealRenderPassShellReadinessBlocked =
            shouldReportRendererNoRealRenderPassShellReadinessBlocked
        this.didSealRendererNoRealRenderPassShellReadiness =
            didSealRendererNoRealRenderPassShellReadiness
        this.didPreserveRendererRealRenderPassTeardownFailureClassification =
            didPreserveRendererRealRenderPassTeardownFailureClassification
        this.didKeepNoRealRenderPassShellReadinessDehydrated =
            didKeepNoRealRenderPassShellReadinessDehydrated
        this.didConfirmNoConcreteRenderPassDescriptor =
            didConfirmNoConcreteRenderPassDescriptor
        this.didConfirmNoAttachmentObject = didConfirmNoAttachmentObject
        this.didConfirmNoAttachmentTextureView =
            didConfirmNoAttachmentTextureView
        this.didConfirmNoDrawableTextureExposure =
            didConfirmNoDrawableTextureExposure
        this.didConfirmNoEncodingObject = didConfirmNoEncodingObject
        this.didConfirmNoEncoderFactoryInvocation =
            didConfirmNoEncoderFactoryInvocation
        this.didConfirmNoEncodingFinalization =
            didConfirmNoEncodingFinalization
        this.didConfirmNoCommandBufferFactoryInvocation =
            didConfirmNoCommandBufferFactoryInvocation
        this.didConfirmNoWorkFinalize = didConfirmNoWorkFinalize
        this.didConfirmNoPresentationCall = didConfirmNoPresentationCall
        this.didConfirmNoDrawableAcquisition =
            didConfirmNoDrawableAcquisition
        this.didConfirmNoPipelineRelation = didConfirmNoPipelineRelation
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
        this.didAvoidRenderPassReadyWrapper = didAvoidRenderPassReadyWrapper
        this.didAvoidEncoderReadyWrapper = didAvoidEncoderReadyWrapper
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

func cjguiInternalBuildRendererRealRenderPassShellIntent(
    noRealCommandBufferShellReadiness:
        CjguiInternalRendererNoRealCommandBufferShellReadiness
): CjguiInternalRendererRealRenderPassShellIntent {
    let upstreamReady =
        noRealCommandBufferShellReadiness
            .isRendererNoRealCommandBufferShellReady &&
        noRealCommandBufferShellReadiness
            .canFutureRendererRealCommandBufferShellBoundaryEvaluate &&
        noRealCommandBufferShellReadiness
            .didSealRendererNoRealCommandBufferShellReadiness &&
        noRealCommandBufferShellReadiness
            .didPreserveRendererRealCommandBufferTeardownFailureClassification &&
        noRealCommandBufferShellReadiness
            .didKeepNoRealCommandBufferShellReadinessDehydrated &&
        noRealCommandBufferShellReadiness
            .didConfirmNoConcreteCommandBufferObject &&
        noRealCommandBufferShellReadiness
            .didConfirmNoCommandBufferFactoryInvocation &&
        noRealCommandBufferShellReadiness.didConfirmNoCommitInvocation &&
        noRealCommandBufferShellReadiness.didConfirmNoPresentationCall &&
        noRealCommandBufferShellReadiness.didConfirmNoDrawableAcquisition &&
        noRealCommandBufferShellReadiness.didConfirmNoEncodingObject &&
        noRealCommandBufferShellReadiness.didConfirmNoRenderPassObject &&
        noRealCommandBufferShellReadiness.didConfirmNoPipelineObject &&
        noRealCommandBufferShellReadiness.didConfirmNoDrawCall &&
        noRealCommandBufferShellReadiness.didConfirmNoWorkSubmit &&
        noRealCommandBufferShellReadiness.didConfirmNoNativeResourceStored &&
        noRealCommandBufferShellReadiness.didConfirmNoPointerLikeResource &&
        noRealCommandBufferShellReadiness.didConfirmNoRenderExecution &&
        noRealCommandBufferShellReadiness.didConfirmNoStateMutation &&
        noRealCommandBufferShellReadiness.didConfirmNoRuntimeStateTouch &&
        noRealCommandBufferShellReadiness
            .didConfirmNoModuleLevelMutableState &&
        noRealCommandBufferShellReadiness.didConfirmNoPublicDiagnostics &&
        noRealCommandBufferShellReadiness.didAvoidCommandBufferReadyWrapper &&
        noRealCommandBufferShellReadiness.didAvoidDrawableReadyWrapper &&
        noRealCommandBufferShellReadiness.didAvoidWorkSubmitWrapper &&
        noRealCommandBufferShellReadiness.didAvoidRenderPermissionWrapper &&
        noRealCommandBufferShellReadiness.didAvoidStateMutationWrapper &&
        noRealCommandBufferShellReadiness.didAvoidReceiptRecordOutput &&
        noRealCommandBufferShellReadiness.didAvoidThinWrapper &&
        noRealCommandBufferShellReadiness.didStayFullRebuildOnly &&
        noRealCommandBufferShellReadiness
            .shouldDeferRendererNoRealCommandBufferShellReadiness == false &&
        noRealCommandBufferShellReadiness
            .shouldReportRendererNoRealCommandBufferShellReadinessBlocked ==
            false
    let upstreamDeferred =
        noRealCommandBufferShellReadiness
            .isRendererNoRealCommandBufferShellReady == false &&
        noRealCommandBufferShellReadiness
            .canFutureRendererRealCommandBufferShellBoundaryEvaluate ==
            false &&
        noRealCommandBufferShellReadiness
            .shouldDeferRendererNoRealCommandBufferShellReadiness &&
        noRealCommandBufferShellReadiness
            .shouldReportRendererNoRealCommandBufferShellReadinessBlocked ==
            false
    let upstreamInconsistent =
        noRealCommandBufferShellReadiness
            .shouldReportRendererNoRealCommandBufferShellReadinessBlocked ||
        (
            noRealCommandBufferShellReadiness
                .isRendererNoRealCommandBufferShellReady &&
            (
                upstreamReady == false ||
                noRealCommandBufferShellReadiness
                    .shouldDeferRendererNoRealCommandBufferShellReadiness
            )
        ) ||
        (
            noRealCommandBufferShellReadiness
                .canFutureRendererRealCommandBufferShellBoundaryEvaluate &&
            noRealCommandBufferShellReadiness
                .isRendererNoRealCommandBufferShellReady == false
        )

    if (upstreamInconsistent) {
        return CjguiInternalRendererRealRenderPassShellIntent(
            noRealCommandBufferShellReadiness,
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
        return CjguiInternalRendererRealRenderPassShellIntent(
            noRealCommandBufferShellReadiness,
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
        return CjguiInternalRendererRealRenderPassShellIntent(
            noRealCommandBufferShellReadiness,
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

    return CjguiInternalRendererRealRenderPassShellIntent(
        noRealCommandBufferShellReadiness,
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

func cjguiInternalBuildRendererRealRenderPassDescriptorAdmissionShell(
    shellIntent:
        CjguiInternalRendererRealRenderPassShellIntent
): CjguiInternalRendererRealRenderPassDescriptorAdmissionShell {
    let intentReady =
        shellIntent.didPrepareRendererRealRenderPassShellIntent &&
        shellIntent.didPreserveRendererNoRealCommandBufferShellReadiness &&
        shellIntent.didDefineFutureRenderPassShellIntent &&
        shellIntent.didDescribeRenderPassDescriptorAdmissionNeed &&
        shellIntent.didDescribeAttachmentDenialNeed &&
        shellIntent.didDescribeEncoderDenialNeed &&
        shellIntent.didDescribeRenderPassFailureClassificationNeed &&
        shellIntent.didKeepRenderPassShellIntentDehydrated &&
        shellIntent.didAvoidRenderPassReadyWrapper &&
        shellIntent.didAvoidCommandBufferReadyWrapper &&
        shellIntent.didAvoidReceiptRecordOutput &&
        shellIntent.didAvoidThinWrapper &&
        shellIntent.shouldDeferRendererRealRenderPassShellIntent == false &&
        shellIntent
            .shouldReportRendererRealRenderPassShellIntentBlocked == false
    let intentDeferred =
        shellIntent.didPrepareRendererRealRenderPassShellIntent == false &&
        shellIntent.shouldDeferRendererRealRenderPassShellIntent &&
        shellIntent
            .shouldReportRendererRealRenderPassShellIntentBlocked == false
    let intentInconsistent =
        shellIntent.shouldReportRendererRealRenderPassShellIntentBlocked ||
        (
            shellIntent.didPrepareRendererRealRenderPassShellIntent &&
            intentReady == false
        )

    return CjguiInternalRendererRealRenderPassDescriptorAdmissionShell(
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

func cjguiInternalBuildRendererRealRenderPassAttachmentDenialProof(
    descriptorAdmissionShell:
        CjguiInternalRendererRealRenderPassDescriptorAdmissionShell
): CjguiInternalRendererRealRenderPassAttachmentDenialProof {
    let shellReady =
        descriptorAdmissionShell
            .didPrepareRendererRealRenderPassDescriptorAdmissionShell &&
        descriptorAdmissionShell
            .didPreserveRendererRealRenderPassShellIntent &&
        descriptorAdmissionShell
            .didDefineOwnerLocalRenderPassDescriptorAdmissionShell &&
        descriptorAdmissionShell.didConfirmNoConcreteRenderPassDescriptor &&
        descriptorAdmissionShell.didConfirmNoAttachmentObject &&
        descriptorAdmissionShell.didConfirmNoEncoderRelation &&
        descriptorAdmissionShell
            .didKeepRenderPassDescriptorAdmissionShellDehydrated &&
        descriptorAdmissionShell.didAvoidRenderPassReadyWrapper &&
        descriptorAdmissionShell.didAvoidEncoderReadyWrapper &&
        descriptorAdmissionShell.didAvoidThinWrapper &&
        descriptorAdmissionShell
            .shouldDeferRendererRealRenderPassDescriptorAdmissionShell ==
            false &&
        descriptorAdmissionShell
            .shouldReportRendererRealRenderPassDescriptorAdmissionShellBlocked ==
            false
    let shellDeferred =
        descriptorAdmissionShell
            .didPrepareRendererRealRenderPassDescriptorAdmissionShell ==
            false &&
        descriptorAdmissionShell
            .shouldDeferRendererRealRenderPassDescriptorAdmissionShell &&
        descriptorAdmissionShell
            .shouldReportRendererRealRenderPassDescriptorAdmissionShellBlocked ==
            false
    let shellInconsistent =
        descriptorAdmissionShell
            .shouldReportRendererRealRenderPassDescriptorAdmissionShellBlocked ||
        (
            descriptorAdmissionShell
                .didPrepareRendererRealRenderPassDescriptorAdmissionShell &&
            shellReady == false
        )

    return CjguiInternalRendererRealRenderPassAttachmentDenialProof(
        descriptorAdmissionShell,
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

func cjguiInternalBuildRendererRealRenderPassEncoderDenialProof(
    attachmentDenialProof:
        CjguiInternalRendererRealRenderPassAttachmentDenialProof
): CjguiInternalRendererRealRenderPassEncoderDenialProof {
    let proofReady =
        attachmentDenialProof
            .didPrepareRendererRealRenderPassAttachmentDenialProof &&
        attachmentDenialProof
            .didPreserveRendererRealRenderPassDescriptorAdmissionShell &&
        attachmentDenialProof
            .didDefineOwnerLocalRenderPassAttachmentDenialProof &&
        attachmentDenialProof.didConfirmNoAttachmentTextureView &&
        attachmentDenialProof.didConfirmNoDrawableTextureExposure &&
        attachmentDenialProof.didConfirmNoResourceBindingRelation &&
        attachmentDenialProof
            .didKeepRenderPassAttachmentDenialProofDehydrated &&
        attachmentDenialProof.didAvoidAttachmentPermissionWrapper &&
        attachmentDenialProof.didAvoidResourceBindingWrapper &&
        attachmentDenialProof.didAvoidThinWrapper &&
        attachmentDenialProof
            .shouldDeferRendererRealRenderPassAttachmentDenialProof == false &&
        attachmentDenialProof
            .shouldReportRendererRealRenderPassAttachmentDenialProofBlocked ==
            false
    let proofDeferred =
        attachmentDenialProof
            .didPrepareRendererRealRenderPassAttachmentDenialProof == false &&
        attachmentDenialProof
            .shouldDeferRendererRealRenderPassAttachmentDenialProof &&
        attachmentDenialProof
            .shouldReportRendererRealRenderPassAttachmentDenialProofBlocked ==
            false
    let proofInconsistent =
        attachmentDenialProof
            .shouldReportRendererRealRenderPassAttachmentDenialProofBlocked ||
        (
            attachmentDenialProof
                .didPrepareRendererRealRenderPassAttachmentDenialProof &&
            proofReady == false
        )

    return CjguiInternalRendererRealRenderPassEncoderDenialProof(
        attachmentDenialProof,
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

func cjguiInternalBuildRendererRealRenderPassTeardownFailureClassification(
    encoderDenialProof:
        CjguiInternalRendererRealRenderPassEncoderDenialProof
): CjguiInternalRendererRealRenderPassTeardownFailureClassification {
    let proofReady =
        encoderDenialProof
            .didPrepareRendererRealRenderPassEncoderDenialProof &&
        encoderDenialProof
            .didPreserveRendererRealRenderPassAttachmentDenialProof &&
        encoderDenialProof.didDefineOwnerLocalRenderPassEncoderDenialProof &&
        encoderDenialProof.didConfirmNoEncodingObject &&
        encoderDenialProof.didConfirmNoEncoderFactoryInvocation &&
        encoderDenialProof.didConfirmNoEncodingFinalization &&
        encoderDenialProof.didConfirmNoPipelineRelation &&
        encoderDenialProof.didKeepRenderPassEncoderDenialProofDehydrated &&
        encoderDenialProof.didAvoidEncoderReadyWrapper &&
        encoderDenialProof.didAvoidRenderPermissionWrapper &&
        encoderDenialProof.didAvoidThinWrapper &&
        encoderDenialProof
            .shouldDeferRendererRealRenderPassEncoderDenialProof == false &&
        encoderDenialProof
            .shouldReportRendererRealRenderPassEncoderDenialProofBlocked ==
            false
    let proofDeferred =
        encoderDenialProof
            .didPrepareRendererRealRenderPassEncoderDenialProof == false &&
        encoderDenialProof
            .shouldDeferRendererRealRenderPassEncoderDenialProof &&
        encoderDenialProof
            .shouldReportRendererRealRenderPassEncoderDenialProofBlocked ==
            false
    let proofInconsistent =
        encoderDenialProof
            .shouldReportRendererRealRenderPassEncoderDenialProofBlocked ||
        (
            encoderDenialProof
                .didPrepareRendererRealRenderPassEncoderDenialProof &&
            proofReady == false
        )

    return CjguiInternalRendererRealRenderPassTeardownFailureClassification(
        encoderDenialProof,
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

func cjguiInternalBuildRendererNoRealRenderPassShellReadiness(
    teardownFailureClassification:
        CjguiInternalRendererRealRenderPassTeardownFailureClassification
): CjguiInternalRendererNoRealRenderPassShellReadiness {
    let failureReady =
        teardownFailureClassification
            .didPrepareRendererRealRenderPassTeardownFailureClassification &&
        teardownFailureClassification
            .didPreserveRendererRealRenderPassEncoderDenialProof &&
        teardownFailureClassification
            .didDefineOwnerLocalRenderPassTeardownFailureClassification &&
        teardownFailureClassification
            .didFailClosedMissingRenderPassDescriptor &&
        teardownFailureClassification.didFailClosedWrongThreadRisk &&
        teardownFailureClassification.didFailClosedStaleAttachmentRisk &&
        teardownFailureClassification.didFailClosedBridgeOptimism &&
        teardownFailureClassification.didConfirmNoFailurePublication &&
        teardownFailureClassification.didConfirmNoPublicDiagnostics &&
        teardownFailureClassification.didKeepRenderPassTeardownFailureDehydrated &&
        teardownFailureClassification.didAvoidRenderPassReadyWrapper &&
        teardownFailureClassification.didAvoidReceiptRecordOutput &&
        teardownFailureClassification.didAvoidThinWrapper &&
        teardownFailureClassification
            .shouldDeferRendererRealRenderPassTeardownFailureClassification ==
            false &&
        teardownFailureClassification
            .shouldReportRendererRealRenderPassTeardownFailureClassificationBlocked ==
            false
    let failureDeferred =
        teardownFailureClassification
            .didPrepareRendererRealRenderPassTeardownFailureClassification ==
            false &&
        teardownFailureClassification
            .shouldDeferRendererRealRenderPassTeardownFailureClassification &&
        teardownFailureClassification
            .shouldReportRendererRealRenderPassTeardownFailureClassificationBlocked ==
            false
    let failureInconsistent =
        teardownFailureClassification
            .shouldReportRendererRealRenderPassTeardownFailureClassificationBlocked ||
        (
            teardownFailureClassification
                .didPrepareRendererRealRenderPassTeardownFailureClassification &&
            failureReady == false
        )

    return CjguiInternalRendererNoRealRenderPassShellReadiness(
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererRealRenderPassShellDraft():
    CjguiInternalRendererNoRealRenderPassShellReadiness {
    let noRealCommandBufferShellReadiness =
        cjguiInternalExecuteDefaultRendererRealCommandBufferShellDraft()
    let shellIntent =
        cjguiInternalBuildRendererRealRenderPassShellIntent(
            noRealCommandBufferShellReadiness
        )
    let descriptorAdmissionShell =
        cjguiInternalBuildRendererRealRenderPassDescriptorAdmissionShell(
            shellIntent
        )
    let attachmentDenialProof =
        cjguiInternalBuildRendererRealRenderPassAttachmentDenialProof(
            descriptorAdmissionShell
        )
    let encoderDenialProof =
        cjguiInternalBuildRendererRealRenderPassEncoderDenialProof(
            attachmentDenialProof
        )
    let teardownFailureClassification =
        cjguiInternalBuildRendererRealRenderPassTeardownFailureClassification(
            encoderDenialProof
        )
    return cjguiInternalBuildRendererNoRealRenderPassShellReadiness(
        teardownFailureClassification
    )
}
