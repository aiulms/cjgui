// Owner：本文件固定 pipeline state implementation admission 的 internal-only owner 边界。
// Truth：唯一 runtime input 是 CjguiInternalRendererNoEncoderImplementationReadiness，
// canonical endpoint 是 CjguiInternalRendererNoPipelineStateImplementationReadiness。
// Stop-line：只生成 value facts，不创建管线对象、着色资源、描述器或编码资源，
// 不进入外部图形调用，不提交工作，不执行绘制，不写状态，不开放接口。
// Same-shape Boundary Brake：本文件新增 shader / descriptor / compatibility
// admission 语义，不把上一层 readiness 包成 permission wrapper、receipt、record 或发布凭据。
package cjgui

struct CjguiInternalRendererPipelineStateImplementationIntent {
    let noEncoderImplementationReadiness:
        CjguiInternalRendererNoEncoderImplementationReadiness
    let didPrepareRendererPipelineStateImplementationIntent: Bool
    let shouldDeferRendererPipelineStateImplementationIntent: Bool
    let shouldReportRendererPipelineStateImplementationIntentBlocked: Bool
    let didPreserveRendererNoEncoderImplementationReadiness: Bool
    let didDefineFuturePipelineStateImplementationIntent: Bool
    let didDescribeShaderFunctionAdmissionNeed: Bool
    let didDescribePipelineDescriptorAdmissionNeed: Bool
    let didDescribePipelineCompatibilityAdmissionNeed: Bool
    let didKeepPipelineStateImplementationIntentValueOnly: Bool
    let didAvoidPipelineReadyPermissionWrapper: Bool
    let didAvoidBackendImplementationWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        noEncoderImplementationReadiness:
            CjguiInternalRendererNoEncoderImplementationReadiness,
        didPrepareRendererPipelineStateImplementationIntent: Bool,
        shouldDeferRendererPipelineStateImplementationIntent: Bool,
        shouldReportRendererPipelineStateImplementationIntentBlocked: Bool,
        didPreserveRendererNoEncoderImplementationReadiness: Bool,
        didDefineFuturePipelineStateImplementationIntent: Bool,
        didDescribeShaderFunctionAdmissionNeed: Bool,
        didDescribePipelineDescriptorAdmissionNeed: Bool,
        didDescribePipelineCompatibilityAdmissionNeed: Bool,
        didKeepPipelineStateImplementationIntentValueOnly: Bool,
        didAvoidPipelineReadyPermissionWrapper: Bool,
        didAvoidBackendImplementationWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noEncoderImplementationReadiness =
            noEncoderImplementationReadiness
        this.didPrepareRendererPipelineStateImplementationIntent =
            didPrepareRendererPipelineStateImplementationIntent
        this.shouldDeferRendererPipelineStateImplementationIntent =
            shouldDeferRendererPipelineStateImplementationIntent
        this.shouldReportRendererPipelineStateImplementationIntentBlocked =
            shouldReportRendererPipelineStateImplementationIntentBlocked
        this.didPreserveRendererNoEncoderImplementationReadiness =
            didPreserveRendererNoEncoderImplementationReadiness
        this.didDefineFuturePipelineStateImplementationIntent =
            didDefineFuturePipelineStateImplementationIntent
        this.didDescribeShaderFunctionAdmissionNeed =
            didDescribeShaderFunctionAdmissionNeed
        this.didDescribePipelineDescriptorAdmissionNeed =
            didDescribePipelineDescriptorAdmissionNeed
        this.didDescribePipelineCompatibilityAdmissionNeed =
            didDescribePipelineCompatibilityAdmissionNeed
        this.didKeepPipelineStateImplementationIntentValueOnly =
            didKeepPipelineStateImplementationIntentValueOnly
        this.didAvoidPipelineReadyPermissionWrapper =
            didAvoidPipelineReadyPermissionWrapper
        this.didAvoidBackendImplementationWrapper =
            didAvoidBackendImplementationWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererShaderFunctionAdmissionPolicy {
    let implementationIntent:
        CjguiInternalRendererPipelineStateImplementationIntent
    let didPrepareRendererShaderFunctionAdmissionPolicy: Bool
    let shouldDeferRendererShaderFunctionAdmissionPolicy: Bool
    let shouldReportRendererShaderFunctionAdmissionPolicyBlocked: Bool
    let didPreserveRendererPipelineStateImplementationIntent: Bool
    let didDefineFutureShaderFunctionAdmissionPolicy: Bool
    let didDescribeShaderRoleAdmissionFacts: Bool
    let didDescribeNoShaderAssetResolutionFacts: Bool
    let didDescribeShaderFailureFallbackFacts: Bool
    let didConfirmNoShaderLibraryLoaded: Bool
    let didConfirmNoShaderFunctionResolved: Bool
    let didKeepShaderFunctionAdmissionPolicyValueOnly: Bool
    let didAvoidShaderFunctionPermissionWrapper: Bool
    let didAvoidPipelineReadyPermissionWrapper: Bool
    let didAvoidBackendImplementationWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        implementationIntent:
            CjguiInternalRendererPipelineStateImplementationIntent,
        didPrepareRendererShaderFunctionAdmissionPolicy: Bool,
        shouldDeferRendererShaderFunctionAdmissionPolicy: Bool,
        shouldReportRendererShaderFunctionAdmissionPolicyBlocked: Bool,
        didPreserveRendererPipelineStateImplementationIntent: Bool,
        didDefineFutureShaderFunctionAdmissionPolicy: Bool,
        didDescribeShaderRoleAdmissionFacts: Bool,
        didDescribeNoShaderAssetResolutionFacts: Bool,
        didDescribeShaderFailureFallbackFacts: Bool,
        didConfirmNoShaderLibraryLoaded: Bool,
        didConfirmNoShaderFunctionResolved: Bool,
        didKeepShaderFunctionAdmissionPolicyValueOnly: Bool,
        didAvoidShaderFunctionPermissionWrapper: Bool,
        didAvoidPipelineReadyPermissionWrapper: Bool,
        didAvoidBackendImplementationWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.implementationIntent = implementationIntent
        this.didPrepareRendererShaderFunctionAdmissionPolicy =
            didPrepareRendererShaderFunctionAdmissionPolicy
        this.shouldDeferRendererShaderFunctionAdmissionPolicy =
            shouldDeferRendererShaderFunctionAdmissionPolicy
        this.shouldReportRendererShaderFunctionAdmissionPolicyBlocked =
            shouldReportRendererShaderFunctionAdmissionPolicyBlocked
        this.didPreserveRendererPipelineStateImplementationIntent =
            didPreserveRendererPipelineStateImplementationIntent
        this.didDefineFutureShaderFunctionAdmissionPolicy =
            didDefineFutureShaderFunctionAdmissionPolicy
        this.didDescribeShaderRoleAdmissionFacts =
            didDescribeShaderRoleAdmissionFacts
        this.didDescribeNoShaderAssetResolutionFacts =
            didDescribeNoShaderAssetResolutionFacts
        this.didDescribeShaderFailureFallbackFacts =
            didDescribeShaderFailureFallbackFacts
        this.didConfirmNoShaderLibraryLoaded =
            didConfirmNoShaderLibraryLoaded
        this.didConfirmNoShaderFunctionResolved =
            didConfirmNoShaderFunctionResolved
        this.didKeepShaderFunctionAdmissionPolicyValueOnly =
            didKeepShaderFunctionAdmissionPolicyValueOnly
        this.didAvoidShaderFunctionPermissionWrapper =
            didAvoidShaderFunctionPermissionWrapper
        this.didAvoidPipelineReadyPermissionWrapper =
            didAvoidPipelineReadyPermissionWrapper
        this.didAvoidBackendImplementationWrapper =
            didAvoidBackendImplementationWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererPipelineDescriptorAdmissionPolicy {
    let shaderFunctionAdmissionPolicy:
        CjguiInternalRendererShaderFunctionAdmissionPolicy
    let didPrepareRendererPipelineDescriptorAdmissionPolicy: Bool
    let shouldDeferRendererPipelineDescriptorAdmissionPolicy: Bool
    let shouldReportRendererPipelineDescriptorAdmissionPolicyBlocked: Bool
    let didPreserveRendererShaderFunctionAdmissionPolicy: Bool
    let didDefineFuturePipelineDescriptorAdmissionPolicy: Bool
    let didDescribeDescriptorFieldAdmissionFacts: Bool
    let didDescribeRenderTargetCompatibilityFacts: Bool
    let didDescribeNoDescriptorResourceFacts: Bool
    let didConfirmNoPipelineDescriptorBuilt: Bool
    let didConfirmNoPipelineStateBuilt: Bool
    let didConfirmNoPlatformDescriptorResource: Bool
    let didKeepPipelineDescriptorAdmissionPolicyValueOnly: Bool
    let didAvoidPipelineDescriptorPermissionWrapper: Bool
    let didAvoidPipelineReadyPermissionWrapper: Bool
    let didAvoidRenderPassPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        shaderFunctionAdmissionPolicy:
            CjguiInternalRendererShaderFunctionAdmissionPolicy,
        didPrepareRendererPipelineDescriptorAdmissionPolicy: Bool,
        shouldDeferRendererPipelineDescriptorAdmissionPolicy: Bool,
        shouldReportRendererPipelineDescriptorAdmissionPolicyBlocked: Bool,
        didPreserveRendererShaderFunctionAdmissionPolicy: Bool,
        didDefineFuturePipelineDescriptorAdmissionPolicy: Bool,
        didDescribeDescriptorFieldAdmissionFacts: Bool,
        didDescribeRenderTargetCompatibilityFacts: Bool,
        didDescribeNoDescriptorResourceFacts: Bool,
        didConfirmNoPipelineDescriptorBuilt: Bool,
        didConfirmNoPipelineStateBuilt: Bool,
        didConfirmNoPlatformDescriptorResource: Bool,
        didKeepPipelineDescriptorAdmissionPolicyValueOnly: Bool,
        didAvoidPipelineDescriptorPermissionWrapper: Bool,
        didAvoidPipelineReadyPermissionWrapper: Bool,
        didAvoidRenderPassPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.shaderFunctionAdmissionPolicy = shaderFunctionAdmissionPolicy
        this.didPrepareRendererPipelineDescriptorAdmissionPolicy =
            didPrepareRendererPipelineDescriptorAdmissionPolicy
        this.shouldDeferRendererPipelineDescriptorAdmissionPolicy =
            shouldDeferRendererPipelineDescriptorAdmissionPolicy
        this.shouldReportRendererPipelineDescriptorAdmissionPolicyBlocked =
            shouldReportRendererPipelineDescriptorAdmissionPolicyBlocked
        this.didPreserveRendererShaderFunctionAdmissionPolicy =
            didPreserveRendererShaderFunctionAdmissionPolicy
        this.didDefineFuturePipelineDescriptorAdmissionPolicy =
            didDefineFuturePipelineDescriptorAdmissionPolicy
        this.didDescribeDescriptorFieldAdmissionFacts =
            didDescribeDescriptorFieldAdmissionFacts
        this.didDescribeRenderTargetCompatibilityFacts =
            didDescribeRenderTargetCompatibilityFacts
        this.didDescribeNoDescriptorResourceFacts =
            didDescribeNoDescriptorResourceFacts
        this.didConfirmNoPipelineDescriptorBuilt =
            didConfirmNoPipelineDescriptorBuilt
        this.didConfirmNoPipelineStateBuilt = didConfirmNoPipelineStateBuilt
        this.didConfirmNoPlatformDescriptorResource =
            didConfirmNoPlatformDescriptorResource
        this.didKeepPipelineDescriptorAdmissionPolicyValueOnly =
            didKeepPipelineDescriptorAdmissionPolicyValueOnly
        this.didAvoidPipelineDescriptorPermissionWrapper =
            didAvoidPipelineDescriptorPermissionWrapper
        this.didAvoidPipelineReadyPermissionWrapper =
            didAvoidPipelineReadyPermissionWrapper
        this.didAvoidRenderPassPermissionWrapper =
            didAvoidRenderPassPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererPipelineCompatibilityAdmissionGuard {
    let descriptorAdmissionPolicy:
        CjguiInternalRendererPipelineDescriptorAdmissionPolicy
    let didPrepareRendererPipelineCompatibilityAdmissionGuard: Bool
    let shouldDeferRendererPipelineCompatibilityAdmissionGuard: Bool
    let shouldReportRendererPipelineCompatibilityAdmissionGuardBlocked: Bool
    let didPreserveRendererPipelineDescriptorAdmissionPolicy: Bool
    let didDefineFuturePipelineCompatibilityAdmissionGuard: Bool
    let didDescribeRenderPassCompatibilityAdmissionFacts: Bool
    let didDescribeEncoderCompatibilityAdmissionFacts: Bool
    let didDescribeDrawCallCompatibilityAdmissionFacts: Bool
    let didDescribeNoPipelineBindingFacts: Bool
    let didConfirmNoPipelineBinding: Bool
    let didConfirmNoBufferBinding: Bool
    let didConfirmNoTextureBinding: Bool
    let didConfirmNoResourceBinding: Bool
    let didKeepPipelineCompatibilityAdmissionGuardValueOnly: Bool
    let didAvoidPipelineBindingPermissionWrapper: Bool
    let didAvoidEncoderPermissionWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        descriptorAdmissionPolicy:
            CjguiInternalRendererPipelineDescriptorAdmissionPolicy,
        didPrepareRendererPipelineCompatibilityAdmissionGuard: Bool,
        shouldDeferRendererPipelineCompatibilityAdmissionGuard: Bool,
        shouldReportRendererPipelineCompatibilityAdmissionGuardBlocked: Bool,
        didPreserveRendererPipelineDescriptorAdmissionPolicy: Bool,
        didDefineFuturePipelineCompatibilityAdmissionGuard: Bool,
        didDescribeRenderPassCompatibilityAdmissionFacts: Bool,
        didDescribeEncoderCompatibilityAdmissionFacts: Bool,
        didDescribeDrawCallCompatibilityAdmissionFacts: Bool,
        didDescribeNoPipelineBindingFacts: Bool,
        didConfirmNoPipelineBinding: Bool,
        didConfirmNoBufferBinding: Bool,
        didConfirmNoTextureBinding: Bool,
        didConfirmNoResourceBinding: Bool,
        didKeepPipelineCompatibilityAdmissionGuardValueOnly: Bool,
        didAvoidPipelineBindingPermissionWrapper: Bool,
        didAvoidEncoderPermissionWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.descriptorAdmissionPolicy = descriptorAdmissionPolicy
        this.didPrepareRendererPipelineCompatibilityAdmissionGuard =
            didPrepareRendererPipelineCompatibilityAdmissionGuard
        this.shouldDeferRendererPipelineCompatibilityAdmissionGuard =
            shouldDeferRendererPipelineCompatibilityAdmissionGuard
        this.shouldReportRendererPipelineCompatibilityAdmissionGuardBlocked =
            shouldReportRendererPipelineCompatibilityAdmissionGuardBlocked
        this.didPreserveRendererPipelineDescriptorAdmissionPolicy =
            didPreserveRendererPipelineDescriptorAdmissionPolicy
        this.didDefineFuturePipelineCompatibilityAdmissionGuard =
            didDefineFuturePipelineCompatibilityAdmissionGuard
        this.didDescribeRenderPassCompatibilityAdmissionFacts =
            didDescribeRenderPassCompatibilityAdmissionFacts
        this.didDescribeEncoderCompatibilityAdmissionFacts =
            didDescribeEncoderCompatibilityAdmissionFacts
        this.didDescribeDrawCallCompatibilityAdmissionFacts =
            didDescribeDrawCallCompatibilityAdmissionFacts
        this.didDescribeNoPipelineBindingFacts =
            didDescribeNoPipelineBindingFacts
        this.didConfirmNoPipelineBinding = didConfirmNoPipelineBinding
        this.didConfirmNoBufferBinding = didConfirmNoBufferBinding
        this.didConfirmNoTextureBinding = didConfirmNoTextureBinding
        this.didConfirmNoResourceBinding = didConfirmNoResourceBinding
        this.didKeepPipelineCompatibilityAdmissionGuardValueOnly =
            didKeepPipelineCompatibilityAdmissionGuardValueOnly
        this.didAvoidPipelineBindingPermissionWrapper =
            didAvoidPipelineBindingPermissionWrapper
        this.didAvoidEncoderPermissionWrapper =
            didAvoidEncoderPermissionWrapper
        this.didAvoidRenderPermissionWrapper =
            didAvoidRenderPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoPipelineStateImplementationReadiness {
    let compatibilityAdmissionGuard:
        CjguiInternalRendererPipelineCompatibilityAdmissionGuard
    let isRendererNoPipelineStateImplementationReady: Bool
    let canFutureRendererPipelineStateImplementationBoundaryEvaluate: Bool
    let shouldDeferRendererNoPipelineStateImplementationReadiness: Bool
    let shouldReportRendererNoPipelineStateImplementationReadinessBlocked: Bool
    let didSealRendererNoPipelineStateImplementationReadiness: Bool
    let didPreserveRendererPipelineCompatibilityAdmissionGuard: Bool
    let didKeepNoPipelineStateImplementationReadinessValueOnly: Bool
    let didConfirmNoPipelineStateObject: Bool
    let didConfirmNoShaderLibraryObject: Bool
    let didConfirmNoShaderFunctionObject: Bool
    let didConfirmNoPipelineDescriptorObject: Bool
    let didConfirmNoPipelineBinding: Bool
    let didConfirmNoBufferBinding: Bool
    let didConfirmNoTextureBinding: Bool
    let didConfirmNoResourceBinding: Bool
    let didConfirmNoEncoderObject: Bool
    let didConfirmNoCommandBufferObject: Bool
    let didConfirmNoForeignDeclaration: Bool
    let didConfirmNoForeignInvocation: Bool
    let didConfirmNoResourceToken: Bool
    let didConfirmNoPointerResource: Bool
    let didConfirmNoGpuWork: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoDrawCommand: Bool
    let didConfirmNoRenderStateMutation: Bool
    let didAvoidPipelineReadyPermissionWrapper: Bool
    let didAvoidShaderFunctionPermissionWrapper: Bool
    let didAvoidPipelineDescriptorPermissionWrapper: Bool
    let didAvoidPipelineBindingPermissionWrapper: Bool
    let didAvoidEncoderPermissionWrapper: Bool
    let didAvoidCommandBufferPermissionWrapper: Bool
    let didAvoidResourcePermissionWrapper: Bool
    let didAvoidGpuWorkWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidStateWriteWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidPublicationOutput: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        compatibilityAdmissionGuard:
            CjguiInternalRendererPipelineCompatibilityAdmissionGuard,
        isRendererNoPipelineStateImplementationReady: Bool,
        canFutureRendererPipelineStateImplementationBoundaryEvaluate: Bool,
        shouldDeferRendererNoPipelineStateImplementationReadiness: Bool,
        shouldReportRendererNoPipelineStateImplementationReadinessBlocked: Bool,
        didSealRendererNoPipelineStateImplementationReadiness: Bool,
        didPreserveRendererPipelineCompatibilityAdmissionGuard: Bool,
        didKeepNoPipelineStateImplementationReadinessValueOnly: Bool,
        didConfirmNoPipelineStateObject: Bool,
        didConfirmNoShaderLibraryObject: Bool,
        didConfirmNoShaderFunctionObject: Bool,
        didConfirmNoPipelineDescriptorObject: Bool,
        didConfirmNoPipelineBinding: Bool,
        didConfirmNoBufferBinding: Bool,
        didConfirmNoTextureBinding: Bool,
        didConfirmNoResourceBinding: Bool,
        didConfirmNoEncoderObject: Bool,
        didConfirmNoCommandBufferObject: Bool,
        didConfirmNoForeignDeclaration: Bool,
        didConfirmNoForeignInvocation: Bool,
        didConfirmNoResourceToken: Bool,
        didConfirmNoPointerResource: Bool,
        didConfirmNoGpuWork: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoDrawCommand: Bool,
        didConfirmNoRenderStateMutation: Bool,
        didAvoidPipelineReadyPermissionWrapper: Bool,
        didAvoidShaderFunctionPermissionWrapper: Bool,
        didAvoidPipelineDescriptorPermissionWrapper: Bool,
        didAvoidPipelineBindingPermissionWrapper: Bool,
        didAvoidEncoderPermissionWrapper: Bool,
        didAvoidCommandBufferPermissionWrapper: Bool,
        didAvoidResourcePermissionWrapper: Bool,
        didAvoidGpuWorkWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidStateWriteWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidPublicationOutput: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.compatibilityAdmissionGuard = compatibilityAdmissionGuard
        this.isRendererNoPipelineStateImplementationReady =
            isRendererNoPipelineStateImplementationReady
        this.canFutureRendererPipelineStateImplementationBoundaryEvaluate =
            canFutureRendererPipelineStateImplementationBoundaryEvaluate
        this.shouldDeferRendererNoPipelineStateImplementationReadiness =
            shouldDeferRendererNoPipelineStateImplementationReadiness
        this.shouldReportRendererNoPipelineStateImplementationReadinessBlocked =
            shouldReportRendererNoPipelineStateImplementationReadinessBlocked
        this.didSealRendererNoPipelineStateImplementationReadiness =
            didSealRendererNoPipelineStateImplementationReadiness
        this.didPreserveRendererPipelineCompatibilityAdmissionGuard =
            didPreserveRendererPipelineCompatibilityAdmissionGuard
        this.didKeepNoPipelineStateImplementationReadinessValueOnly =
            didKeepNoPipelineStateImplementationReadinessValueOnly
        this.didConfirmNoPipelineStateObject =
            didConfirmNoPipelineStateObject
        this.didConfirmNoShaderLibraryObject =
            didConfirmNoShaderLibraryObject
        this.didConfirmNoShaderFunctionObject =
            didConfirmNoShaderFunctionObject
        this.didConfirmNoPipelineDescriptorObject =
            didConfirmNoPipelineDescriptorObject
        this.didConfirmNoPipelineBinding = didConfirmNoPipelineBinding
        this.didConfirmNoBufferBinding = didConfirmNoBufferBinding
        this.didConfirmNoTextureBinding = didConfirmNoTextureBinding
        this.didConfirmNoResourceBinding = didConfirmNoResourceBinding
        this.didConfirmNoEncoderObject = didConfirmNoEncoderObject
        this.didConfirmNoCommandBufferObject =
            didConfirmNoCommandBufferObject
        this.didConfirmNoForeignDeclaration = didConfirmNoForeignDeclaration
        this.didConfirmNoForeignInvocation = didConfirmNoForeignInvocation
        this.didConfirmNoResourceToken = didConfirmNoResourceToken
        this.didConfirmNoPointerResource = didConfirmNoPointerResource
        this.didConfirmNoGpuWork = didConfirmNoGpuWork
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoDrawCommand = didConfirmNoDrawCommand
        this.didConfirmNoRenderStateMutation =
            didConfirmNoRenderStateMutation
        this.didAvoidPipelineReadyPermissionWrapper =
            didAvoidPipelineReadyPermissionWrapper
        this.didAvoidShaderFunctionPermissionWrapper =
            didAvoidShaderFunctionPermissionWrapper
        this.didAvoidPipelineDescriptorPermissionWrapper =
            didAvoidPipelineDescriptorPermissionWrapper
        this.didAvoidPipelineBindingPermissionWrapper =
            didAvoidPipelineBindingPermissionWrapper
        this.didAvoidEncoderPermissionWrapper =
            didAvoidEncoderPermissionWrapper
        this.didAvoidCommandBufferPermissionWrapper =
            didAvoidCommandBufferPermissionWrapper
        this.didAvoidResourcePermissionWrapper =
            didAvoidResourcePermissionWrapper
        this.didAvoidGpuWorkWrapper = didAvoidGpuWorkWrapper
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidStateWriteWrapper = didAvoidStateWriteWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidPublicationOutput = didAvoidPublicationOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererPipelineStateImplementationIntent(
    noEncoderImplementationReadiness:
        CjguiInternalRendererNoEncoderImplementationReadiness
): CjguiInternalRendererPipelineStateImplementationIntent {
    let upstreamReady =
        noEncoderImplementationReadiness
            .isRendererNoEncoderImplementationReady &&
        noEncoderImplementationReadiness
            .canFutureRendererEncoderImplementationBoundaryEvaluate &&
        noEncoderImplementationReadiness
            .didSealRendererNoEncoderImplementationReadiness &&
        noEncoderImplementationReadiness
            .didPreserveRendererEndEncodingAdmissionPolicy &&
        noEncoderImplementationReadiness
            .didKeepNoEncoderImplementationReadinessValueOnly &&
        noEncoderImplementationReadiness.didConfirmNoEncoderObjectCreated &&
        noEncoderImplementationReadiness.didConfirmNoEncoderFactoryCall &&
        noEncoderImplementationReadiness.didConfirmNoEncodingCloseCall &&
        noEncoderImplementationReadiness.didConfirmNoPipelineBinding &&
        noEncoderImplementationReadiness.didConfirmNoBufferBinding &&
        noEncoderImplementationReadiness.didConfirmNoTextureBinding &&
        noEncoderImplementationReadiness.didConfirmNoResourceBinding &&
        noEncoderImplementationReadiness.didConfirmNoPassPlanBuilt &&
        noEncoderImplementationReadiness.didConfirmNoTargetResourceBuilt &&
        noEncoderImplementationReadiness.didConfirmNoBufferObjectBuilt &&
        noEncoderImplementationReadiness.didConfirmNoForeignDeclaration &&
        noEncoderImplementationReadiness.didConfirmNoForeignInvocation &&
        noEncoderImplementationReadiness.didConfirmNoResourceToken &&
        noEncoderImplementationReadiness.didConfirmNoPointerResource &&
        noEncoderImplementationReadiness.didConfirmNoGpuWork &&
        noEncoderImplementationReadiness.didConfirmNoRenderExecution &&
        noEncoderImplementationReadiness.didConfirmNoDrawCommand &&
        noEncoderImplementationReadiness.didConfirmNoRenderStateMutation &&
        noEncoderImplementationReadiness.didAvoidEncoderReadyPermissionWrapper &&
        noEncoderImplementationReadiness
            .didAvoidEncoderFactoryPermissionWrapper &&
        noEncoderImplementationReadiness
            .didAvoidEncoderClosePermissionWrapper &&
        noEncoderImplementationReadiness
            .didAvoidPipelineBindingPermissionWrapper &&
        noEncoderImplementationReadiness
            .didAvoidCommandBufferPermissionWrapper &&
        noEncoderImplementationReadiness.didAvoidResourcePermissionWrapper &&
        noEncoderImplementationReadiness.didAvoidGpuWorkWrapper &&
        noEncoderImplementationReadiness.didAvoidRenderPermissionWrapper &&
        noEncoderImplementationReadiness.didAvoidStateWriteWrapper &&
        noEncoderImplementationReadiness.didAvoidReceiptRecordOutput &&
        noEncoderImplementationReadiness.didAvoidPublicationOutput &&
        noEncoderImplementationReadiness.didAvoidThinWrapper &&
        noEncoderImplementationReadiness.didStayFullRebuildOnly &&
        noEncoderImplementationReadiness
            .shouldDeferRendererNoEncoderImplementationReadiness == false &&
        noEncoderImplementationReadiness
            .shouldReportRendererNoEncoderImplementationReadinessBlocked ==
            false
    let upstreamDeferred =
        noEncoderImplementationReadiness
            .shouldDeferRendererNoEncoderImplementationReadiness &&
        noEncoderImplementationReadiness
            .shouldReportRendererNoEncoderImplementationReadinessBlocked ==
            false
    let upstreamInconsistent =
        noEncoderImplementationReadiness
            .shouldReportRendererNoEncoderImplementationReadinessBlocked ||
        (
            noEncoderImplementationReadiness
                .canFutureRendererEncoderImplementationBoundaryEvaluate &&
            noEncoderImplementationReadiness
                .isRendererNoEncoderImplementationReady == false
        ) ||
        (
            noEncoderImplementationReadiness
                .shouldDeferRendererNoEncoderImplementationReadiness &&
            noEncoderImplementationReadiness
                .shouldReportRendererNoEncoderImplementationReadinessBlocked
        )

    if (upstreamInconsistent) {
        return CjguiInternalRendererPipelineStateImplementationIntent(
            noEncoderImplementationReadiness,
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
        return CjguiInternalRendererPipelineStateImplementationIntent(
            noEncoderImplementationReadiness,
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

    return CjguiInternalRendererPipelineStateImplementationIntent(
        noEncoderImplementationReadiness,
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

func cjguiInternalBuildRendererShaderFunctionAdmissionPolicy(
    implementationIntent:
        CjguiInternalRendererPipelineStateImplementationIntent
): CjguiInternalRendererShaderFunctionAdmissionPolicy {
    let intentReady =
        implementationIntent
            .didPrepareRendererPipelineStateImplementationIntent &&
        implementationIntent
            .didPreserveRendererNoEncoderImplementationReadiness &&
        implementationIntent.didDefineFuturePipelineStateImplementationIntent &&
        implementationIntent.didDescribeShaderFunctionAdmissionNeed &&
        implementationIntent.didDescribePipelineDescriptorAdmissionNeed &&
        implementationIntent.didDescribePipelineCompatibilityAdmissionNeed &&
        implementationIntent
            .didKeepPipelineStateImplementationIntentValueOnly &&
        implementationIntent.didAvoidPipelineReadyPermissionWrapper &&
        implementationIntent.didAvoidBackendImplementationWrapper &&
        implementationIntent.didAvoidReceiptRecordOutput &&
        implementationIntent.didAvoidThinWrapper &&
        implementationIntent
            .shouldDeferRendererPipelineStateImplementationIntent == false &&
        implementationIntent
            .shouldReportRendererPipelineStateImplementationIntentBlocked ==
            false
    let intentDeferred =
        implementationIntent
            .shouldDeferRendererPipelineStateImplementationIntent &&
        implementationIntent
            .shouldReportRendererPipelineStateImplementationIntentBlocked ==
            false
    let intentInconsistent =
        implementationIntent
            .shouldReportRendererPipelineStateImplementationIntentBlocked ||
        (
            implementationIntent
                .didPrepareRendererPipelineStateImplementationIntent &&
            intentReady == false
        ) ||
        (
            implementationIntent
                .shouldDeferRendererPipelineStateImplementationIntent &&
            implementationIntent
                .shouldReportRendererPipelineStateImplementationIntentBlocked
        )

    if (intentInconsistent) {
        return CjguiInternalRendererShaderFunctionAdmissionPolicy(
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
            true,
            true
        )
    }

    if (intentDeferred || intentReady == false) {
        return CjguiInternalRendererShaderFunctionAdmissionPolicy(
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
            true,
            true
        )
    }

    return CjguiInternalRendererShaderFunctionAdmissionPolicy(
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
        true,
        true
    )
}

func cjguiInternalBuildRendererPipelineDescriptorAdmissionPolicy(
    shaderFunctionAdmissionPolicy:
        CjguiInternalRendererShaderFunctionAdmissionPolicy
): CjguiInternalRendererPipelineDescriptorAdmissionPolicy {
    let shaderReady =
        shaderFunctionAdmissionPolicy
            .didPrepareRendererShaderFunctionAdmissionPolicy &&
        shaderFunctionAdmissionPolicy
            .didPreserveRendererPipelineStateImplementationIntent &&
        shaderFunctionAdmissionPolicy
            .didDefineFutureShaderFunctionAdmissionPolicy &&
        shaderFunctionAdmissionPolicy.didDescribeShaderRoleAdmissionFacts &&
        shaderFunctionAdmissionPolicy
            .didDescribeNoShaderAssetResolutionFacts &&
        shaderFunctionAdmissionPolicy.didDescribeShaderFailureFallbackFacts &&
        shaderFunctionAdmissionPolicy.didConfirmNoShaderLibraryLoaded &&
        shaderFunctionAdmissionPolicy.didConfirmNoShaderFunctionResolved &&
        shaderFunctionAdmissionPolicy
            .didKeepShaderFunctionAdmissionPolicyValueOnly &&
        shaderFunctionAdmissionPolicy.didAvoidShaderFunctionPermissionWrapper &&
        shaderFunctionAdmissionPolicy.didAvoidPipelineReadyPermissionWrapper &&
        shaderFunctionAdmissionPolicy.didAvoidBackendImplementationWrapper &&
        shaderFunctionAdmissionPolicy.didAvoidThinWrapper &&
        shaderFunctionAdmissionPolicy
            .shouldDeferRendererShaderFunctionAdmissionPolicy == false &&
        shaderFunctionAdmissionPolicy
            .shouldReportRendererShaderFunctionAdmissionPolicyBlocked == false
    let shaderDeferred =
        shaderFunctionAdmissionPolicy
            .shouldDeferRendererShaderFunctionAdmissionPolicy &&
        shaderFunctionAdmissionPolicy
            .shouldReportRendererShaderFunctionAdmissionPolicyBlocked == false
    let shaderInconsistent =
        shaderFunctionAdmissionPolicy
            .shouldReportRendererShaderFunctionAdmissionPolicyBlocked ||
        (
            shaderFunctionAdmissionPolicy
                .didPrepareRendererShaderFunctionAdmissionPolicy &&
            shaderReady == false
        ) ||
        (
            shaderFunctionAdmissionPolicy
                .shouldDeferRendererShaderFunctionAdmissionPolicy &&
            shaderFunctionAdmissionPolicy
                .shouldReportRendererShaderFunctionAdmissionPolicyBlocked
        )

    if (shaderInconsistent) {
        return CjguiInternalRendererPipelineDescriptorAdmissionPolicy(
            shaderFunctionAdmissionPolicy,
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
            true,
            true
        )
    }

    if (shaderDeferred || shaderReady == false) {
        return CjguiInternalRendererPipelineDescriptorAdmissionPolicy(
            shaderFunctionAdmissionPolicy,
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
            true,
            true
        )
    }

    return CjguiInternalRendererPipelineDescriptorAdmissionPolicy(
        shaderFunctionAdmissionPolicy,
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

func cjguiInternalBuildRendererPipelineCompatibilityAdmissionGuard(
    descriptorAdmissionPolicy:
        CjguiInternalRendererPipelineDescriptorAdmissionPolicy
): CjguiInternalRendererPipelineCompatibilityAdmissionGuard {
    let descriptorReady =
        descriptorAdmissionPolicy
            .didPrepareRendererPipelineDescriptorAdmissionPolicy &&
        descriptorAdmissionPolicy
            .didPreserveRendererShaderFunctionAdmissionPolicy &&
        descriptorAdmissionPolicy
            .didDefineFuturePipelineDescriptorAdmissionPolicy &&
        descriptorAdmissionPolicy.didDescribeDescriptorFieldAdmissionFacts &&
        descriptorAdmissionPolicy.didDescribeRenderTargetCompatibilityFacts &&
        descriptorAdmissionPolicy.didDescribeNoDescriptorResourceFacts &&
        descriptorAdmissionPolicy.didConfirmNoPipelineDescriptorBuilt &&
        descriptorAdmissionPolicy.didConfirmNoPipelineStateBuilt &&
        descriptorAdmissionPolicy.didConfirmNoPlatformDescriptorResource &&
        descriptorAdmissionPolicy
            .didKeepPipelineDescriptorAdmissionPolicyValueOnly &&
        descriptorAdmissionPolicy
            .didAvoidPipelineDescriptorPermissionWrapper &&
        descriptorAdmissionPolicy.didAvoidPipelineReadyPermissionWrapper &&
        descriptorAdmissionPolicy.didAvoidRenderPassPermissionWrapper &&
        descriptorAdmissionPolicy.didAvoidThinWrapper &&
        descriptorAdmissionPolicy
            .shouldDeferRendererPipelineDescriptorAdmissionPolicy == false &&
        descriptorAdmissionPolicy
            .shouldReportRendererPipelineDescriptorAdmissionPolicyBlocked ==
            false
    let descriptorDeferred =
        descriptorAdmissionPolicy
            .shouldDeferRendererPipelineDescriptorAdmissionPolicy &&
        descriptorAdmissionPolicy
            .shouldReportRendererPipelineDescriptorAdmissionPolicyBlocked ==
            false
    let descriptorInconsistent =
        descriptorAdmissionPolicy
            .shouldReportRendererPipelineDescriptorAdmissionPolicyBlocked ||
        (
            descriptorAdmissionPolicy
                .didPrepareRendererPipelineDescriptorAdmissionPolicy &&
            descriptorReady == false
        ) ||
        (
            descriptorAdmissionPolicy
                .shouldDeferRendererPipelineDescriptorAdmissionPolicy &&
            descriptorAdmissionPolicy
                .shouldReportRendererPipelineDescriptorAdmissionPolicyBlocked
        )

    if (descriptorInconsistent) {
        return CjguiInternalRendererPipelineCompatibilityAdmissionGuard(
            descriptorAdmissionPolicy,
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
            true,
            true,
            true,
            true,
            true
        )
    }

    if (descriptorDeferred || descriptorReady == false) {
        return CjguiInternalRendererPipelineCompatibilityAdmissionGuard(
            descriptorAdmissionPolicy,
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
            true,
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererPipelineCompatibilityAdmissionGuard(
        descriptorAdmissionPolicy,
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
        true
    )
}

func cjguiInternalBuildRendererNoPipelineStateImplementationReadiness(
    compatibilityAdmissionGuard:
        CjguiInternalRendererPipelineCompatibilityAdmissionGuard
): CjguiInternalRendererNoPipelineStateImplementationReadiness {
    let compatibilityReady =
        compatibilityAdmissionGuard
            .didPrepareRendererPipelineCompatibilityAdmissionGuard &&
        compatibilityAdmissionGuard
            .didPreserveRendererPipelineDescriptorAdmissionPolicy &&
        compatibilityAdmissionGuard
            .didDefineFuturePipelineCompatibilityAdmissionGuard &&
        compatibilityAdmissionGuard
            .didDescribeRenderPassCompatibilityAdmissionFacts &&
        compatibilityAdmissionGuard
            .didDescribeEncoderCompatibilityAdmissionFacts &&
        compatibilityAdmissionGuard
            .didDescribeDrawCallCompatibilityAdmissionFacts &&
        compatibilityAdmissionGuard.didDescribeNoPipelineBindingFacts &&
        compatibilityAdmissionGuard.didConfirmNoPipelineBinding &&
        compatibilityAdmissionGuard.didConfirmNoBufferBinding &&
        compatibilityAdmissionGuard.didConfirmNoTextureBinding &&
        compatibilityAdmissionGuard.didConfirmNoResourceBinding &&
        compatibilityAdmissionGuard
            .didKeepPipelineCompatibilityAdmissionGuardValueOnly &&
        compatibilityAdmissionGuard.didAvoidPipelineBindingPermissionWrapper &&
        compatibilityAdmissionGuard.didAvoidEncoderPermissionWrapper &&
        compatibilityAdmissionGuard.didAvoidRenderPermissionWrapper &&
        compatibilityAdmissionGuard.didAvoidThinWrapper &&
        compatibilityAdmissionGuard
            .shouldDeferRendererPipelineCompatibilityAdmissionGuard == false &&
        compatibilityAdmissionGuard
            .shouldReportRendererPipelineCompatibilityAdmissionGuardBlocked ==
            false
    let compatibilityDeferred =
        compatibilityAdmissionGuard
            .shouldDeferRendererPipelineCompatibilityAdmissionGuard &&
        compatibilityAdmissionGuard
            .shouldReportRendererPipelineCompatibilityAdmissionGuardBlocked ==
            false
    let compatibilityInconsistent =
        compatibilityAdmissionGuard
            .shouldReportRendererPipelineCompatibilityAdmissionGuardBlocked ||
        (
            compatibilityAdmissionGuard
                .didPrepareRendererPipelineCompatibilityAdmissionGuard &&
            compatibilityReady == false
        ) ||
        (
            compatibilityAdmissionGuard
                .shouldDeferRendererPipelineCompatibilityAdmissionGuard &&
            compatibilityAdmissionGuard
                .shouldReportRendererPipelineCompatibilityAdmissionGuardBlocked
        )

    if (compatibilityInconsistent) {
        return CjguiInternalRendererNoPipelineStateImplementationReadiness(
            compatibilityAdmissionGuard,
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
            true,
            true,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (compatibilityDeferred || compatibilityReady == false) {
        return CjguiInternalRendererNoPipelineStateImplementationReadiness(
            compatibilityAdmissionGuard,
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
            true,
            true,
            true,
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererNoPipelineStateImplementationReadiness(
        compatibilityAdmissionGuard,
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
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft():
    CjguiInternalRendererNoPipelineStateImplementationReadiness {
    let noEncoderImplementationReadiness =
        cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()
    let implementationIntent =
        cjguiInternalBuildRendererPipelineStateImplementationIntent(
            noEncoderImplementationReadiness
        )
    let shaderFunctionAdmissionPolicy =
        cjguiInternalBuildRendererShaderFunctionAdmissionPolicy(
            implementationIntent
        )
    let pipelineDescriptorAdmissionPolicy =
        cjguiInternalBuildRendererPipelineDescriptorAdmissionPolicy(
            shaderFunctionAdmissionPolicy
        )
    let pipelineCompatibilityAdmissionGuard =
        cjguiInternalBuildRendererPipelineCompatibilityAdmissionGuard(
            pipelineDescriptorAdmissionPolicy
        )
    return cjguiInternalBuildRendererNoPipelineStateImplementationReadiness(
        pipelineCompatibilityAdmissionGuard
    )
}
