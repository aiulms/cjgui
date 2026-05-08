// Owner: real pipeline state 第一刀 internal-only shell 边界。
// Truth: 只消费 CjguiInternalRendererNoRealEncoderShellReadiness，并记录
// pipeline state shell intent、shader function denial proof、descriptor denial
// proof、pipeline binding denial proof、compatibility failure classification 与
// no-real-pipeline-state-shell readiness facts。
// Stop-line: 只产出 internal-only shell / dehydrated facts；不是真实 pipeline
// state、shader function、pipeline descriptor、pipeline binding、GPU work、
// native bridge、native handle、C ABI / FFI、renderer state write 或 public API
// 许可。
// Same-shape Boundary Brake: 不得把本 shell 包成 pipeline-ready、shader-ready、
// binding-ready、GPU-submission、render-permission、renderer-state-write、
// receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererRealPipelineStateShellIntent {
    let noRealEncoderShellReadiness:
        CjguiInternalRendererNoRealEncoderShellReadiness
    let didPrepareRendererRealPipelineStateShellIntent: Bool
    let shouldDeferRendererRealPipelineStateShellIntent: Bool
    let shouldReportRendererRealPipelineStateShellIntentBlocked: Bool
    let didPreserveRendererNoRealEncoderShellReadiness: Bool
    let didDefineFuturePipelineStateShellIntent: Bool
    let didDescribeShaderFunctionDenialNeed: Bool
    let didDescribePipelineDescriptorDenialNeed: Bool
    let didDescribePipelineBindingDenialNeed: Bool
    let didDescribeCompatibilityFailureNeed: Bool
    let didKeepPipelineStateShellIntentDehydrated: Bool
    let didAvoidPipelineReadyWrapper: Bool
    let didAvoidEncoderReadyWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        noRealEncoderShellReadiness:
            CjguiInternalRendererNoRealEncoderShellReadiness,
        didPrepareRendererRealPipelineStateShellIntent: Bool,
        shouldDeferRendererRealPipelineStateShellIntent: Bool,
        shouldReportRendererRealPipelineStateShellIntentBlocked: Bool,
        didPreserveRendererNoRealEncoderShellReadiness: Bool,
        didDefineFuturePipelineStateShellIntent: Bool,
        didDescribeShaderFunctionDenialNeed: Bool,
        didDescribePipelineDescriptorDenialNeed: Bool,
        didDescribePipelineBindingDenialNeed: Bool,
        didDescribeCompatibilityFailureNeed: Bool,
        didKeepPipelineStateShellIntentDehydrated: Bool,
        didAvoidPipelineReadyWrapper: Bool,
        didAvoidEncoderReadyWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noRealEncoderShellReadiness = noRealEncoderShellReadiness
        this.didPrepareRendererRealPipelineStateShellIntent =
            didPrepareRendererRealPipelineStateShellIntent
        this.shouldDeferRendererRealPipelineStateShellIntent =
            shouldDeferRendererRealPipelineStateShellIntent
        this.shouldReportRendererRealPipelineStateShellIntentBlocked =
            shouldReportRendererRealPipelineStateShellIntentBlocked
        this.didPreserveRendererNoRealEncoderShellReadiness =
            didPreserveRendererNoRealEncoderShellReadiness
        this.didDefineFuturePipelineStateShellIntent =
            didDefineFuturePipelineStateShellIntent
        this.didDescribeShaderFunctionDenialNeed =
            didDescribeShaderFunctionDenialNeed
        this.didDescribePipelineDescriptorDenialNeed =
            didDescribePipelineDescriptorDenialNeed
        this.didDescribePipelineBindingDenialNeed =
            didDescribePipelineBindingDenialNeed
        this.didDescribeCompatibilityFailureNeed =
            didDescribeCompatibilityFailureNeed
        this.didKeepPipelineStateShellIntentDehydrated =
            didKeepPipelineStateShellIntentDehydrated
        this.didAvoidPipelineReadyWrapper = didAvoidPipelineReadyWrapper
        this.didAvoidEncoderReadyWrapper = didAvoidEncoderReadyWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealPipelineStateShaderFunctionDenialProof {
    let shellIntent:
        CjguiInternalRendererRealPipelineStateShellIntent
    let didPrepareRendererRealPipelineStateShaderFunctionDenialProof: Bool
    let shouldDeferRendererRealPipelineStateShaderFunctionDenialProof: Bool
    let shouldReportRendererRealPipelineStateShaderFunctionDenialProofBlocked:
        Bool
    let didPreserveRendererRealPipelineStateShellIntent: Bool
    let didDefineOwnerLocalShaderFunctionDenialProof: Bool
    let didConfirmNoShaderLibraryLoad: Bool
    let didConfirmNoShaderFunctionLookup: Bool
    let didConfirmNoShaderCompilation: Bool
    let didKeepShaderFunctionDenialProofDehydrated: Bool
    let didAvoidShaderReadyWrapper: Bool
    let didAvoidPipelineReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        shellIntent:
            CjguiInternalRendererRealPipelineStateShellIntent,
        didPrepareRendererRealPipelineStateShaderFunctionDenialProof: Bool,
        shouldDeferRendererRealPipelineStateShaderFunctionDenialProof: Bool,
        shouldReportRendererRealPipelineStateShaderFunctionDenialProofBlocked:
            Bool,
        didPreserveRendererRealPipelineStateShellIntent: Bool,
        didDefineOwnerLocalShaderFunctionDenialProof: Bool,
        didConfirmNoShaderLibraryLoad: Bool,
        didConfirmNoShaderFunctionLookup: Bool,
        didConfirmNoShaderCompilation: Bool,
        didKeepShaderFunctionDenialProofDehydrated: Bool,
        didAvoidShaderReadyWrapper: Bool,
        didAvoidPipelineReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.shellIntent = shellIntent
        this.didPrepareRendererRealPipelineStateShaderFunctionDenialProof =
            didPrepareRendererRealPipelineStateShaderFunctionDenialProof
        this.shouldDeferRendererRealPipelineStateShaderFunctionDenialProof =
            shouldDeferRendererRealPipelineStateShaderFunctionDenialProof
        this
            .shouldReportRendererRealPipelineStateShaderFunctionDenialProofBlocked =
            shouldReportRendererRealPipelineStateShaderFunctionDenialProofBlocked
        this.didPreserveRendererRealPipelineStateShellIntent =
            didPreserveRendererRealPipelineStateShellIntent
        this.didDefineOwnerLocalShaderFunctionDenialProof =
            didDefineOwnerLocalShaderFunctionDenialProof
        this.didConfirmNoShaderLibraryLoad = didConfirmNoShaderLibraryLoad
        this.didConfirmNoShaderFunctionLookup =
            didConfirmNoShaderFunctionLookup
        this.didConfirmNoShaderCompilation = didConfirmNoShaderCompilation
        this.didKeepShaderFunctionDenialProofDehydrated =
            didKeepShaderFunctionDenialProofDehydrated
        this.didAvoidShaderReadyWrapper = didAvoidShaderReadyWrapper
        this.didAvoidPipelineReadyWrapper = didAvoidPipelineReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealPipelineStateDescriptorDenialProof {
    let shaderFunctionDenialProof:
        CjguiInternalRendererRealPipelineStateShaderFunctionDenialProof
    let didPrepareRendererRealPipelineStateDescriptorDenialProof: Bool
    let shouldDeferRendererRealPipelineStateDescriptorDenialProof: Bool
    let shouldReportRendererRealPipelineStateDescriptorDenialProofBlocked:
        Bool
    let didPreserveRendererRealPipelineStateShaderFunctionDenialProof: Bool
    let didDefineOwnerLocalPipelineDescriptorDenialProof: Bool
    let didConfirmNoPipelineDescriptorObject: Bool
    let didConfirmNoDescriptorFieldWrite: Bool
    let didConfirmNoColorAttachmentBinding: Bool
    let didConfirmNoDepthStencilBinding: Bool
    let didKeepPipelineDescriptorDenialProofDehydrated: Bool
    let didAvoidDescriptorReadyWrapper: Bool
    let didAvoidRenderPassReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        shaderFunctionDenialProof:
            CjguiInternalRendererRealPipelineStateShaderFunctionDenialProof,
        didPrepareRendererRealPipelineStateDescriptorDenialProof: Bool,
        shouldDeferRendererRealPipelineStateDescriptorDenialProof: Bool,
        shouldReportRendererRealPipelineStateDescriptorDenialProofBlocked:
            Bool,
        didPreserveRendererRealPipelineStateShaderFunctionDenialProof: Bool,
        didDefineOwnerLocalPipelineDescriptorDenialProof: Bool,
        didConfirmNoPipelineDescriptorObject: Bool,
        didConfirmNoDescriptorFieldWrite: Bool,
        didConfirmNoColorAttachmentBinding: Bool,
        didConfirmNoDepthStencilBinding: Bool,
        didKeepPipelineDescriptorDenialProofDehydrated: Bool,
        didAvoidDescriptorReadyWrapper: Bool,
        didAvoidRenderPassReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.shaderFunctionDenialProof = shaderFunctionDenialProof
        this.didPrepareRendererRealPipelineStateDescriptorDenialProof =
            didPrepareRendererRealPipelineStateDescriptorDenialProof
        this.shouldDeferRendererRealPipelineStateDescriptorDenialProof =
            shouldDeferRendererRealPipelineStateDescriptorDenialProof
        this
            .shouldReportRendererRealPipelineStateDescriptorDenialProofBlocked =
            shouldReportRendererRealPipelineStateDescriptorDenialProofBlocked
        this.didPreserveRendererRealPipelineStateShaderFunctionDenialProof =
            didPreserveRendererRealPipelineStateShaderFunctionDenialProof
        this.didDefineOwnerLocalPipelineDescriptorDenialProof =
            didDefineOwnerLocalPipelineDescriptorDenialProof
        this.didConfirmNoPipelineDescriptorObject =
            didConfirmNoPipelineDescriptorObject
        this.didConfirmNoDescriptorFieldWrite =
            didConfirmNoDescriptorFieldWrite
        this.didConfirmNoColorAttachmentBinding =
            didConfirmNoColorAttachmentBinding
        this.didConfirmNoDepthStencilBinding =
            didConfirmNoDepthStencilBinding
        this.didKeepPipelineDescriptorDenialProofDehydrated =
            didKeepPipelineDescriptorDenialProofDehydrated
        this.didAvoidDescriptorReadyWrapper = didAvoidDescriptorReadyWrapper
        this.didAvoidRenderPassReadyWrapper = didAvoidRenderPassReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealPipelineStateBindingDenialProof {
    let descriptorDenialProof:
        CjguiInternalRendererRealPipelineStateDescriptorDenialProof
    let didPrepareRendererRealPipelineStateBindingDenialProof: Bool
    let shouldDeferRendererRealPipelineStateBindingDenialProof: Bool
    let shouldReportRendererRealPipelineStateBindingDenialProofBlocked: Bool
    let didPreserveRendererRealPipelineStateDescriptorDenialProof: Bool
    let didDefineOwnerLocalPipelineBindingDenialProof: Bool
    let didConfirmNoPipelineObjectBinding: Bool
    let didConfirmNoBufferBinding: Bool
    let didConfirmNoTextureBinding: Bool
    let didConfirmNoResourceBinding: Bool
    let didConfirmNoEncoderMutation: Bool
    let didKeepPipelineBindingDenialProofDehydrated: Bool
    let didAvoidBindingReadyWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        descriptorDenialProof:
            CjguiInternalRendererRealPipelineStateDescriptorDenialProof,
        didPrepareRendererRealPipelineStateBindingDenialProof: Bool,
        shouldDeferRendererRealPipelineStateBindingDenialProof: Bool,
        shouldReportRendererRealPipelineStateBindingDenialProofBlocked: Bool,
        didPreserveRendererRealPipelineStateDescriptorDenialProof: Bool,
        didDefineOwnerLocalPipelineBindingDenialProof: Bool,
        didConfirmNoPipelineObjectBinding: Bool,
        didConfirmNoBufferBinding: Bool,
        didConfirmNoTextureBinding: Bool,
        didConfirmNoResourceBinding: Bool,
        didConfirmNoEncoderMutation: Bool,
        didKeepPipelineBindingDenialProofDehydrated: Bool,
        didAvoidBindingReadyWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.descriptorDenialProof = descriptorDenialProof
        this.didPrepareRendererRealPipelineStateBindingDenialProof =
            didPrepareRendererRealPipelineStateBindingDenialProof
        this.shouldDeferRendererRealPipelineStateBindingDenialProof =
            shouldDeferRendererRealPipelineStateBindingDenialProof
        this.shouldReportRendererRealPipelineStateBindingDenialProofBlocked =
            shouldReportRendererRealPipelineStateBindingDenialProofBlocked
        this.didPreserveRendererRealPipelineStateDescriptorDenialProof =
            didPreserveRendererRealPipelineStateDescriptorDenialProof
        this.didDefineOwnerLocalPipelineBindingDenialProof =
            didDefineOwnerLocalPipelineBindingDenialProof
        this.didConfirmNoPipelineObjectBinding =
            didConfirmNoPipelineObjectBinding
        this.didConfirmNoBufferBinding = didConfirmNoBufferBinding
        this.didConfirmNoTextureBinding = didConfirmNoTextureBinding
        this.didConfirmNoResourceBinding = didConfirmNoResourceBinding
        this.didConfirmNoEncoderMutation = didConfirmNoEncoderMutation
        this.didKeepPipelineBindingDenialProofDehydrated =
            didKeepPipelineBindingDenialProofDehydrated
        this.didAvoidBindingReadyWrapper = didAvoidBindingReadyWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealPipelineStateCompatibilityFailureClassification {
    let bindingDenialProof:
        CjguiInternalRendererRealPipelineStateBindingDenialProof
    let didPrepareRendererRealPipelineStateCompatibilityFailureClassification:
        Bool
    let shouldDeferRendererRealPipelineStateCompatibilityFailureClassification:
        Bool
    let shouldReportRendererRealPipelineStateCompatibilityFailureClassificationBlocked:
        Bool
    let didPreserveRendererRealPipelineStateBindingDenialProof: Bool
    let didDefineOwnerLocalPipelineCompatibilityFailureClassification: Bool
    let didFailClosedMissingPipelineStateObject: Bool
    let didFailClosedShaderMismatchRisk: Bool
    let didFailClosedDescriptorMismatchRisk: Bool
    let didFailClosedEncoderMismatchRisk: Bool
    let didConfirmNoFailurePublication: Bool
    let didConfirmNoPublicDiagnostics: Bool
    let didKeepPipelineCompatibilityFailureDehydrated: Bool
    let didAvoidPipelineReadyWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        bindingDenialProof:
            CjguiInternalRendererRealPipelineStateBindingDenialProof,
        didPrepareRendererRealPipelineStateCompatibilityFailureClassification:
            Bool,
        shouldDeferRendererRealPipelineStateCompatibilityFailureClassification:
            Bool,
        shouldReportRendererRealPipelineStateCompatibilityFailureClassificationBlocked:
            Bool,
        didPreserveRendererRealPipelineStateBindingDenialProof: Bool,
        didDefineOwnerLocalPipelineCompatibilityFailureClassification: Bool,
        didFailClosedMissingPipelineStateObject: Bool,
        didFailClosedShaderMismatchRisk: Bool,
        didFailClosedDescriptorMismatchRisk: Bool,
        didFailClosedEncoderMismatchRisk: Bool,
        didConfirmNoFailurePublication: Bool,
        didConfirmNoPublicDiagnostics: Bool,
        didKeepPipelineCompatibilityFailureDehydrated: Bool,
        didAvoidPipelineReadyWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.bindingDenialProof = bindingDenialProof
        this
            .didPrepareRendererRealPipelineStateCompatibilityFailureClassification =
            didPrepareRendererRealPipelineStateCompatibilityFailureClassification
        this
            .shouldDeferRendererRealPipelineStateCompatibilityFailureClassification =
            shouldDeferRendererRealPipelineStateCompatibilityFailureClassification
        this
            .shouldReportRendererRealPipelineStateCompatibilityFailureClassificationBlocked =
            shouldReportRendererRealPipelineStateCompatibilityFailureClassificationBlocked
        this.didPreserveRendererRealPipelineStateBindingDenialProof =
            didPreserveRendererRealPipelineStateBindingDenialProof
        this.didDefineOwnerLocalPipelineCompatibilityFailureClassification =
            didDefineOwnerLocalPipelineCompatibilityFailureClassification
        this.didFailClosedMissingPipelineStateObject =
            didFailClosedMissingPipelineStateObject
        this.didFailClosedShaderMismatchRisk =
            didFailClosedShaderMismatchRisk
        this.didFailClosedDescriptorMismatchRisk =
            didFailClosedDescriptorMismatchRisk
        this.didFailClosedEncoderMismatchRisk =
            didFailClosedEncoderMismatchRisk
        this.didConfirmNoFailurePublication =
            didConfirmNoFailurePublication
        this.didConfirmNoPublicDiagnostics =
            didConfirmNoPublicDiagnostics
        this.didKeepPipelineCompatibilityFailureDehydrated =
            didKeepPipelineCompatibilityFailureDehydrated
        this.didAvoidPipelineReadyWrapper = didAvoidPipelineReadyWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoRealPipelineStateShellReadiness {
    let compatibilityFailureClassification:
        CjguiInternalRendererRealPipelineStateCompatibilityFailureClassification
    let isRendererNoRealPipelineStateShellReady: Bool
    let canFutureRendererRealPipelineStateBoundaryEvaluate: Bool
    let shouldDeferRendererNoRealPipelineStateShellReadiness: Bool
    let shouldReportRendererNoRealPipelineStateShellReadinessBlocked: Bool
    let didSealRendererNoRealPipelineStateShellReadiness: Bool
    let didPreserveRendererRealPipelineStateCompatibilityFailureClassification:
        Bool
    let didKeepNoRealPipelineStateShellReadinessDehydrated: Bool
    let didConfirmNoPipelineStateObject: Bool
    let didConfirmNoShaderLibraryLoad: Bool
    let didConfirmNoShaderFunctionLookup: Bool
    let didConfirmNoShaderCompilation: Bool
    let didConfirmNoPipelineDescriptorObject: Bool
    let didConfirmNoDescriptorFieldWrite: Bool
    let didConfirmNoPipelineBinding: Bool
    let didConfirmNoBufferBinding: Bool
    let didConfirmNoTextureBinding: Bool
    let didConfirmNoResourceBinding: Bool
    let didConfirmNoEncoderMutation: Bool
    let didConfirmNoCommandBufferFactoryInvocation: Bool
    let didConfirmNoWorkSubmit: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoStateMutation: Bool
    let didConfirmNoRuntimeStateTouch: Bool
    let didConfirmNoModuleLevelMutableState: Bool
    let didConfirmNoNativeResourceStored: Bool
    let didConfirmNoPointerLikeResource: Bool
    let didConfirmNoPublicDiagnostics: Bool
    let didAvoidPipelineReadyWrapper: Bool
    let didAvoidShaderReadyWrapper: Bool
    let didAvoidDescriptorReadyWrapper: Bool
    let didAvoidBindingReadyWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidStateMutationWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        compatibilityFailureClassification:
            CjguiInternalRendererRealPipelineStateCompatibilityFailureClassification,
        isRendererNoRealPipelineStateShellReady: Bool,
        canFutureRendererRealPipelineStateBoundaryEvaluate: Bool,
        shouldDeferRendererNoRealPipelineStateShellReadiness: Bool,
        shouldReportRendererNoRealPipelineStateShellReadinessBlocked: Bool,
        didSealRendererNoRealPipelineStateShellReadiness: Bool,
        didPreserveRendererRealPipelineStateCompatibilityFailureClassification:
            Bool,
        didKeepNoRealPipelineStateShellReadinessDehydrated: Bool,
        didConfirmNoPipelineStateObject: Bool,
        didConfirmNoShaderLibraryLoad: Bool,
        didConfirmNoShaderFunctionLookup: Bool,
        didConfirmNoShaderCompilation: Bool,
        didConfirmNoPipelineDescriptorObject: Bool,
        didConfirmNoDescriptorFieldWrite: Bool,
        didConfirmNoPipelineBinding: Bool,
        didConfirmNoBufferBinding: Bool,
        didConfirmNoTextureBinding: Bool,
        didConfirmNoResourceBinding: Bool,
        didConfirmNoEncoderMutation: Bool,
        didConfirmNoCommandBufferFactoryInvocation: Bool,
        didConfirmNoWorkSubmit: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoStateMutation: Bool,
        didConfirmNoRuntimeStateTouch: Bool,
        didConfirmNoModuleLevelMutableState: Bool,
        didConfirmNoNativeResourceStored: Bool,
        didConfirmNoPointerLikeResource: Bool,
        didConfirmNoPublicDiagnostics: Bool,
        didAvoidPipelineReadyWrapper: Bool,
        didAvoidShaderReadyWrapper: Bool,
        didAvoidDescriptorReadyWrapper: Bool,
        didAvoidBindingReadyWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidStateMutationWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.compatibilityFailureClassification =
            compatibilityFailureClassification
        this.isRendererNoRealPipelineStateShellReady =
            isRendererNoRealPipelineStateShellReady
        this.canFutureRendererRealPipelineStateBoundaryEvaluate =
            canFutureRendererRealPipelineStateBoundaryEvaluate
        this.shouldDeferRendererNoRealPipelineStateShellReadiness =
            shouldDeferRendererNoRealPipelineStateShellReadiness
        this.shouldReportRendererNoRealPipelineStateShellReadinessBlocked =
            shouldReportRendererNoRealPipelineStateShellReadinessBlocked
        this.didSealRendererNoRealPipelineStateShellReadiness =
            didSealRendererNoRealPipelineStateShellReadiness
        this
            .didPreserveRendererRealPipelineStateCompatibilityFailureClassification =
            didPreserveRendererRealPipelineStateCompatibilityFailureClassification
        this.didKeepNoRealPipelineStateShellReadinessDehydrated =
            didKeepNoRealPipelineStateShellReadinessDehydrated
        this.didConfirmNoPipelineStateObject =
            didConfirmNoPipelineStateObject
        this.didConfirmNoShaderLibraryLoad = didConfirmNoShaderLibraryLoad
        this.didConfirmNoShaderFunctionLookup =
            didConfirmNoShaderFunctionLookup
        this.didConfirmNoShaderCompilation = didConfirmNoShaderCompilation
        this.didConfirmNoPipelineDescriptorObject =
            didConfirmNoPipelineDescriptorObject
        this.didConfirmNoDescriptorFieldWrite =
            didConfirmNoDescriptorFieldWrite
        this.didConfirmNoPipelineBinding = didConfirmNoPipelineBinding
        this.didConfirmNoBufferBinding = didConfirmNoBufferBinding
        this.didConfirmNoTextureBinding = didConfirmNoTextureBinding
        this.didConfirmNoResourceBinding = didConfirmNoResourceBinding
        this.didConfirmNoEncoderMutation = didConfirmNoEncoderMutation
        this.didConfirmNoCommandBufferFactoryInvocation =
            didConfirmNoCommandBufferFactoryInvocation
        this.didConfirmNoWorkSubmit = didConfirmNoWorkSubmit
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoStateMutation = didConfirmNoStateMutation
        this.didConfirmNoRuntimeStateTouch = didConfirmNoRuntimeStateTouch
        this.didConfirmNoModuleLevelMutableState =
            didConfirmNoModuleLevelMutableState
        this.didConfirmNoNativeResourceStored =
            didConfirmNoNativeResourceStored
        this.didConfirmNoPointerLikeResource =
            didConfirmNoPointerLikeResource
        this.didConfirmNoPublicDiagnostics = didConfirmNoPublicDiagnostics
        this.didAvoidPipelineReadyWrapper = didAvoidPipelineReadyWrapper
        this.didAvoidShaderReadyWrapper = didAvoidShaderReadyWrapper
        this.didAvoidDescriptorReadyWrapper = didAvoidDescriptorReadyWrapper
        this.didAvoidBindingReadyWrapper = didAvoidBindingReadyWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidStateMutationWrapper = didAvoidStateMutationWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererRealPipelineStateShellIntent(
    noRealEncoderShellReadiness:
        CjguiInternalRendererNoRealEncoderShellReadiness
): CjguiInternalRendererRealPipelineStateShellIntent {
    let intentReady =
        noRealEncoderShellReadiness.isRendererNoRealEncoderShellReady &&
        noRealEncoderShellReadiness
            .canFutureRendererRealEncoderShellBoundaryEvaluate &&
        noRealEncoderShellReadiness
            .shouldDeferRendererNoRealEncoderShellReadiness == false &&
        noRealEncoderShellReadiness
            .shouldReportRendererNoRealEncoderShellReadinessBlocked ==
            false &&
        noRealEncoderShellReadiness.didConfirmNoPipelineBinding &&
        noRealEncoderShellReadiness.didConfirmNoBufferBinding &&
        noRealEncoderShellReadiness.didConfirmNoTextureBinding &&
        noRealEncoderShellReadiness.didConfirmNoResourceBinding &&
        noRealEncoderShellReadiness.didConfirmNoWorkSubmit &&
        noRealEncoderShellReadiness.didConfirmNoRenderExecution &&
        noRealEncoderShellReadiness.didConfirmNoStateMutation &&
        noRealEncoderShellReadiness.didAvoidBindingReadyWrapper &&
        noRealEncoderShellReadiness.didAvoidRenderPermissionWrapper
    let intentDeferred =
        noRealEncoderShellReadiness.isRendererNoRealEncoderShellReady ==
            false &&
        noRealEncoderShellReadiness
            .shouldDeferRendererNoRealEncoderShellReadiness &&
        noRealEncoderShellReadiness
            .shouldReportRendererNoRealEncoderShellReadinessBlocked ==
            false
    let intentInconsistent =
        noRealEncoderShellReadiness
            .shouldReportRendererNoRealEncoderShellReadinessBlocked ||
        (
            noRealEncoderShellReadiness.isRendererNoRealEncoderShellReady &&
            intentReady == false
        )

    return CjguiInternalRendererRealPipelineStateShellIntent(
        noRealEncoderShellReadiness,
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
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererRealPipelineStateShaderFunctionDenialProof(
    shellIntent:
        CjguiInternalRendererRealPipelineStateShellIntent
): CjguiInternalRendererRealPipelineStateShaderFunctionDenialProof {
    let proofReady =
        shellIntent.didPrepareRendererRealPipelineStateShellIntent &&
        shellIntent.didPreserveRendererNoRealEncoderShellReadiness &&
        shellIntent.didDefineFuturePipelineStateShellIntent &&
        shellIntent.didDescribeShaderFunctionDenialNeed &&
        shellIntent.didKeepPipelineStateShellIntentDehydrated &&
        shellIntent.didAvoidPipelineReadyWrapper &&
        shellIntent.didAvoidThinWrapper &&
        shellIntent.shouldDeferRendererRealPipelineStateShellIntent ==
            false &&
        shellIntent
            .shouldReportRendererRealPipelineStateShellIntentBlocked ==
            false
    let proofDeferred =
        shellIntent.didPrepareRendererRealPipelineStateShellIntent ==
            false &&
        shellIntent.shouldDeferRendererRealPipelineStateShellIntent &&
        shellIntent
            .shouldReportRendererRealPipelineStateShellIntentBlocked ==
            false
    let proofInconsistent =
        shellIntent
            .shouldReportRendererRealPipelineStateShellIntentBlocked ||
        (
            shellIntent.didPrepareRendererRealPipelineStateShellIntent &&
            proofReady == false
        )

    return CjguiInternalRendererRealPipelineStateShaderFunctionDenialProof(
        shellIntent,
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
        true
    )
}

func cjguiInternalBuildRendererRealPipelineStateDescriptorDenialProof(
    shaderFunctionDenialProof:
        CjguiInternalRendererRealPipelineStateShaderFunctionDenialProof
): CjguiInternalRendererRealPipelineStateDescriptorDenialProof {
    let proofReady =
        shaderFunctionDenialProof
            .didPrepareRendererRealPipelineStateShaderFunctionDenialProof &&
        shaderFunctionDenialProof
            .didPreserveRendererRealPipelineStateShellIntent &&
        shaderFunctionDenialProof
            .didDefineOwnerLocalShaderFunctionDenialProof &&
        shaderFunctionDenialProof.didConfirmNoShaderLibraryLoad &&
        shaderFunctionDenialProof.didConfirmNoShaderFunctionLookup &&
        shaderFunctionDenialProof.didConfirmNoShaderCompilation &&
        shaderFunctionDenialProof.didKeepShaderFunctionDenialProofDehydrated &&
        shaderFunctionDenialProof.didAvoidShaderReadyWrapper &&
        shaderFunctionDenialProof.didAvoidPipelineReadyWrapper &&
        shaderFunctionDenialProof.didAvoidThinWrapper &&
        shaderFunctionDenialProof
            .shouldDeferRendererRealPipelineStateShaderFunctionDenialProof ==
            false &&
        shaderFunctionDenialProof
            .shouldReportRendererRealPipelineStateShaderFunctionDenialProofBlocked ==
            false
    let proofDeferred =
        shaderFunctionDenialProof
            .didPrepareRendererRealPipelineStateShaderFunctionDenialProof ==
            false &&
        shaderFunctionDenialProof
            .shouldDeferRendererRealPipelineStateShaderFunctionDenialProof &&
        shaderFunctionDenialProof
            .shouldReportRendererRealPipelineStateShaderFunctionDenialProofBlocked ==
            false
    let proofInconsistent =
        shaderFunctionDenialProof
            .shouldReportRendererRealPipelineStateShaderFunctionDenialProofBlocked ||
        (
            shaderFunctionDenialProof
                .didPrepareRendererRealPipelineStateShaderFunctionDenialProof &&
            proofReady == false
        )

    return CjguiInternalRendererRealPipelineStateDescriptorDenialProof(
        shaderFunctionDenialProof,
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

func cjguiInternalBuildRendererRealPipelineStateBindingDenialProof(
    descriptorDenialProof:
        CjguiInternalRendererRealPipelineStateDescriptorDenialProof
): CjguiInternalRendererRealPipelineStateBindingDenialProof {
    let proofReady =
        descriptorDenialProof
            .didPrepareRendererRealPipelineStateDescriptorDenialProof &&
        descriptorDenialProof
            .didPreserveRendererRealPipelineStateShaderFunctionDenialProof &&
        descriptorDenialProof
            .didDefineOwnerLocalPipelineDescriptorDenialProof &&
        descriptorDenialProof.didConfirmNoPipelineDescriptorObject &&
        descriptorDenialProof.didConfirmNoDescriptorFieldWrite &&
        descriptorDenialProof.didConfirmNoColorAttachmentBinding &&
        descriptorDenialProof.didConfirmNoDepthStencilBinding &&
        descriptorDenialProof.didKeepPipelineDescriptorDenialProofDehydrated &&
        descriptorDenialProof.didAvoidDescriptorReadyWrapper &&
        descriptorDenialProof.didAvoidRenderPassReadyWrapper &&
        descriptorDenialProof.didAvoidThinWrapper &&
        descriptorDenialProof
            .shouldDeferRendererRealPipelineStateDescriptorDenialProof ==
            false &&
        descriptorDenialProof
            .shouldReportRendererRealPipelineStateDescriptorDenialProofBlocked ==
            false
    let proofDeferred =
        descriptorDenialProof
            .didPrepareRendererRealPipelineStateDescriptorDenialProof ==
            false &&
        descriptorDenialProof
            .shouldDeferRendererRealPipelineStateDescriptorDenialProof &&
        descriptorDenialProof
            .shouldReportRendererRealPipelineStateDescriptorDenialProofBlocked ==
            false
    let proofInconsistent =
        descriptorDenialProof
            .shouldReportRendererRealPipelineStateDescriptorDenialProofBlocked ||
        (
            descriptorDenialProof
                .didPrepareRendererRealPipelineStateDescriptorDenialProof &&
            proofReady == false
        )

    return CjguiInternalRendererRealPipelineStateBindingDenialProof(
        descriptorDenialProof,
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
        true
    )
}

func cjguiInternalBuildRendererRealPipelineStateCompatibilityFailureClassification(
    bindingDenialProof:
        CjguiInternalRendererRealPipelineStateBindingDenialProof
):
    CjguiInternalRendererRealPipelineStateCompatibilityFailureClassification {
    let proofReady =
        bindingDenialProof
            .didPrepareRendererRealPipelineStateBindingDenialProof &&
        bindingDenialProof
            .didPreserveRendererRealPipelineStateDescriptorDenialProof &&
        bindingDenialProof
            .didDefineOwnerLocalPipelineBindingDenialProof &&
        bindingDenialProof.didConfirmNoPipelineObjectBinding &&
        bindingDenialProof.didConfirmNoBufferBinding &&
        bindingDenialProof.didConfirmNoTextureBinding &&
        bindingDenialProof.didConfirmNoResourceBinding &&
        bindingDenialProof.didConfirmNoEncoderMutation &&
        bindingDenialProof.didKeepPipelineBindingDenialProofDehydrated &&
        bindingDenialProof.didAvoidBindingReadyWrapper &&
        bindingDenialProof.didAvoidGpuSubmissionWrapper &&
        bindingDenialProof.didAvoidThinWrapper &&
        bindingDenialProof
            .shouldDeferRendererRealPipelineStateBindingDenialProof ==
            false &&
        bindingDenialProof
            .shouldReportRendererRealPipelineStateBindingDenialProofBlocked ==
            false
    let proofDeferred =
        bindingDenialProof
            .didPrepareRendererRealPipelineStateBindingDenialProof ==
            false &&
        bindingDenialProof
            .shouldDeferRendererRealPipelineStateBindingDenialProof &&
        bindingDenialProof
            .shouldReportRendererRealPipelineStateBindingDenialProofBlocked ==
            false
    let proofInconsistent =
        bindingDenialProof
            .shouldReportRendererRealPipelineStateBindingDenialProofBlocked ||
        (
            bindingDenialProof
                .didPrepareRendererRealPipelineStateBindingDenialProof &&
            proofReady == false
        )

    return CjguiInternalRendererRealPipelineStateCompatibilityFailureClassification(
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
            true,
            true,
            true
        )
}

func cjguiInternalBuildRendererNoRealPipelineStateShellReadiness(
    compatibilityFailureClassification:
        CjguiInternalRendererRealPipelineStateCompatibilityFailureClassification
): CjguiInternalRendererNoRealPipelineStateShellReadiness {
    let failureReady =
        compatibilityFailureClassification
            .didPrepareRendererRealPipelineStateCompatibilityFailureClassification &&
        compatibilityFailureClassification
            .didPreserveRendererRealPipelineStateBindingDenialProof &&
        compatibilityFailureClassification
            .didDefineOwnerLocalPipelineCompatibilityFailureClassification &&
        compatibilityFailureClassification
            .didFailClosedMissingPipelineStateObject &&
        compatibilityFailureClassification.didFailClosedShaderMismatchRisk &&
        compatibilityFailureClassification
            .didFailClosedDescriptorMismatchRisk &&
        compatibilityFailureClassification.didFailClosedEncoderMismatchRisk &&
        compatibilityFailureClassification.didConfirmNoFailurePublication &&
        compatibilityFailureClassification.didConfirmNoPublicDiagnostics &&
        compatibilityFailureClassification
            .didKeepPipelineCompatibilityFailureDehydrated &&
        compatibilityFailureClassification.didAvoidPipelineReadyWrapper &&
        compatibilityFailureClassification.didAvoidReceiptRecordOutput &&
        compatibilityFailureClassification.didAvoidThinWrapper &&
        compatibilityFailureClassification
            .shouldDeferRendererRealPipelineStateCompatibilityFailureClassification ==
            false &&
        compatibilityFailureClassification
            .shouldReportRendererRealPipelineStateCompatibilityFailureClassificationBlocked ==
            false
    let failureDeferred =
        compatibilityFailureClassification
            .didPrepareRendererRealPipelineStateCompatibilityFailureClassification ==
            false &&
        compatibilityFailureClassification
            .shouldDeferRendererRealPipelineStateCompatibilityFailureClassification &&
        compatibilityFailureClassification
            .shouldReportRendererRealPipelineStateCompatibilityFailureClassificationBlocked ==
            false
    let failureInconsistent =
        compatibilityFailureClassification
            .shouldReportRendererRealPipelineStateCompatibilityFailureClassificationBlocked ||
        (
            compatibilityFailureClassification
                .didPrepareRendererRealPipelineStateCompatibilityFailureClassification &&
            failureReady == false
        )

    return CjguiInternalRendererNoRealPipelineStateShellReadiness(
        compatibilityFailureClassification,
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

func cjguiInternalExecuteDefaultRendererRealPipelineStateShellDraft():
    CjguiInternalRendererNoRealPipelineStateShellReadiness {
    let noRealEncoderShellReadiness =
        cjguiInternalExecuteDefaultRendererRealEncoderShellDraft()
    let shellIntent =
        cjguiInternalBuildRendererRealPipelineStateShellIntent(
            noRealEncoderShellReadiness
        )
    let shaderFunctionDenialProof =
        cjguiInternalBuildRendererRealPipelineStateShaderFunctionDenialProof(
            shellIntent
        )
    let descriptorDenialProof =
        cjguiInternalBuildRendererRealPipelineStateDescriptorDenialProof(
            shaderFunctionDenialProof
        )
    let bindingDenialProof =
        cjguiInternalBuildRendererRealPipelineStateBindingDenialProof(
            descriptorDenialProof
        )
    let compatibilityFailureClassification =
        cjguiInternalBuildRendererRealPipelineStateCompatibilityFailureClassification(
            bindingDenialProof
        )
    return cjguiInternalBuildRendererNoRealPipelineStateShellReadiness(
        compatibilityFailureClassification
    )
}
