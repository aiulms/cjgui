// Owner：本文件固定 draw call implementation admission 的 internal-only owner 边界。
// Truth：唯一 runtime input 是 CjguiInternalRendererNoPipelineStateImplementationReadiness，
// canonical endpoint 是 CjguiInternalRendererNoDrawCallImplementationReadiness。
// Stop-line：只生成 value facts，不发绘制命令，不占有几何资源，不接外部图形调用，
// 不提交工作，不执行渲染，不写 renderer 状态，不开放接口。
// Same-shape Boundary Brake：本文件新增 primitive / geometry / ordering admission
// 语义，不把上一层 readiness 包成 permission wrapper、receipt、record 或发布凭据。
package cjgui

struct CjguiInternalRendererDrawCallImplementationIntent {
    let noPipelineStateImplementationReadiness:
        CjguiInternalRendererNoPipelineStateImplementationReadiness
    let didPrepareRendererDrawCallImplementationIntent: Bool
    let shouldDeferRendererDrawCallImplementationIntent: Bool
    let shouldReportRendererDrawCallImplementationIntentBlocked: Bool
    let didPreserveRendererNoPipelineStateImplementationReadiness: Bool
    let didDefineFutureDrawCallImplementationIntent: Bool
    let didDescribePrimitiveCommandAdmissionNeed: Bool
    let didDescribeGeometryBindingAdmissionNeed: Bool
    let didDescribeDrawOrderingAdmissionNeed: Bool
    let didKeepDrawCallImplementationIntentValueOnly: Bool
    let didAvoidDrawReadyPermissionWrapper: Bool
    let didAvoidBackendImplementationWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        noPipelineStateImplementationReadiness:
            CjguiInternalRendererNoPipelineStateImplementationReadiness,
        didPrepareRendererDrawCallImplementationIntent: Bool,
        shouldDeferRendererDrawCallImplementationIntent: Bool,
        shouldReportRendererDrawCallImplementationIntentBlocked: Bool,
        didPreserveRendererNoPipelineStateImplementationReadiness: Bool,
        didDefineFutureDrawCallImplementationIntent: Bool,
        didDescribePrimitiveCommandAdmissionNeed: Bool,
        didDescribeGeometryBindingAdmissionNeed: Bool,
        didDescribeDrawOrderingAdmissionNeed: Bool,
        didKeepDrawCallImplementationIntentValueOnly: Bool,
        didAvoidDrawReadyPermissionWrapper: Bool,
        didAvoidBackendImplementationWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noPipelineStateImplementationReadiness =
            noPipelineStateImplementationReadiness
        this.didPrepareRendererDrawCallImplementationIntent =
            didPrepareRendererDrawCallImplementationIntent
        this.shouldDeferRendererDrawCallImplementationIntent =
            shouldDeferRendererDrawCallImplementationIntent
        this.shouldReportRendererDrawCallImplementationIntentBlocked =
            shouldReportRendererDrawCallImplementationIntentBlocked
        this.didPreserveRendererNoPipelineStateImplementationReadiness =
            didPreserveRendererNoPipelineStateImplementationReadiness
        this.didDefineFutureDrawCallImplementationIntent =
            didDefineFutureDrawCallImplementationIntent
        this.didDescribePrimitiveCommandAdmissionNeed =
            didDescribePrimitiveCommandAdmissionNeed
        this.didDescribeGeometryBindingAdmissionNeed =
            didDescribeGeometryBindingAdmissionNeed
        this.didDescribeDrawOrderingAdmissionNeed =
            didDescribeDrawOrderingAdmissionNeed
        this.didKeepDrawCallImplementationIntentValueOnly =
            didKeepDrawCallImplementationIntentValueOnly
        this.didAvoidDrawReadyPermissionWrapper =
            didAvoidDrawReadyPermissionWrapper
        this.didAvoidBackendImplementationWrapper =
            didAvoidBackendImplementationWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererPrimitiveCommandAdmissionPolicy {
    let implementationIntent:
        CjguiInternalRendererDrawCallImplementationIntent
    let didPrepareRendererPrimitiveCommandAdmissionPolicy: Bool
    let shouldDeferRendererPrimitiveCommandAdmissionPolicy: Bool
    let shouldReportRendererPrimitiveCommandAdmissionPolicyBlocked: Bool
    let didPreserveRendererDrawCallImplementationIntent: Bool
    let didDefineFuturePrimitiveCommandAdmissionPolicy: Bool
    let didDescribePrimitiveKindAdmissionFacts: Bool
    let didDescribeVertexCountAdmissionFacts: Bool
    let didDescribeInstanceCountAdmissionFacts: Bool
    let didConfirmNoDrawCommandIssued: Bool
    let didConfirmNoPrimitiveCommandInvoked: Bool
    let didKeepPrimitiveCommandAdmissionPolicyValueOnly: Bool
    let didAvoidPrimitiveCommandPermissionWrapper: Bool
    let didAvoidDrawReadyPermissionWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        implementationIntent:
            CjguiInternalRendererDrawCallImplementationIntent,
        didPrepareRendererPrimitiveCommandAdmissionPolicy: Bool,
        shouldDeferRendererPrimitiveCommandAdmissionPolicy: Bool,
        shouldReportRendererPrimitiveCommandAdmissionPolicyBlocked: Bool,
        didPreserveRendererDrawCallImplementationIntent: Bool,
        didDefineFuturePrimitiveCommandAdmissionPolicy: Bool,
        didDescribePrimitiveKindAdmissionFacts: Bool,
        didDescribeVertexCountAdmissionFacts: Bool,
        didDescribeInstanceCountAdmissionFacts: Bool,
        didConfirmNoDrawCommandIssued: Bool,
        didConfirmNoPrimitiveCommandInvoked: Bool,
        didKeepPrimitiveCommandAdmissionPolicyValueOnly: Bool,
        didAvoidPrimitiveCommandPermissionWrapper: Bool,
        didAvoidDrawReadyPermissionWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.implementationIntent = implementationIntent
        this.didPrepareRendererPrimitiveCommandAdmissionPolicy =
            didPrepareRendererPrimitiveCommandAdmissionPolicy
        this.shouldDeferRendererPrimitiveCommandAdmissionPolicy =
            shouldDeferRendererPrimitiveCommandAdmissionPolicy
        this.shouldReportRendererPrimitiveCommandAdmissionPolicyBlocked =
            shouldReportRendererPrimitiveCommandAdmissionPolicyBlocked
        this.didPreserveRendererDrawCallImplementationIntent =
            didPreserveRendererDrawCallImplementationIntent
        this.didDefineFuturePrimitiveCommandAdmissionPolicy =
            didDefineFuturePrimitiveCommandAdmissionPolicy
        this.didDescribePrimitiveKindAdmissionFacts =
            didDescribePrimitiveKindAdmissionFacts
        this.didDescribeVertexCountAdmissionFacts =
            didDescribeVertexCountAdmissionFacts
        this.didDescribeInstanceCountAdmissionFacts =
            didDescribeInstanceCountAdmissionFacts
        this.didConfirmNoDrawCommandIssued = didConfirmNoDrawCommandIssued
        this.didConfirmNoPrimitiveCommandInvoked =
            didConfirmNoPrimitiveCommandInvoked
        this.didKeepPrimitiveCommandAdmissionPolicyValueOnly =
            didKeepPrimitiveCommandAdmissionPolicyValueOnly
        this.didAvoidPrimitiveCommandPermissionWrapper =
            didAvoidPrimitiveCommandPermissionWrapper
        this.didAvoidDrawReadyPermissionWrapper =
            didAvoidDrawReadyPermissionWrapper
        this.didAvoidRenderPermissionWrapper =
            didAvoidRenderPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererGeometryBindingAdmissionGuard {
    let primitiveCommandAdmissionPolicy:
        CjguiInternalRendererPrimitiveCommandAdmissionPolicy
    let didPrepareRendererGeometryBindingAdmissionGuard: Bool
    let shouldDeferRendererGeometryBindingAdmissionGuard: Bool
    let shouldReportRendererGeometryBindingAdmissionGuardBlocked: Bool
    let didPreserveRendererPrimitiveCommandAdmissionPolicy: Bool
    let didDefineFutureGeometryBindingAdmissionGuard: Bool
    let didDescribeGeometrySourceAdmissionFacts: Bool
    let didDescribeIndexSourceAdmissionFacts: Bool
    let didDescribeResourcePlaceholderFacts: Bool
    let didConfirmNoVertexResourceHeld: Bool
    let didConfirmNoIndexResourceHeld: Bool
    let didConfirmNoTextureResourceHeld: Bool
    let didConfirmNoSamplerResourceHeld: Bool
    let didConfirmNoExternalResourceHeld: Bool
    let didKeepGeometryBindingAdmissionGuardValueOnly: Bool
    let didAvoidGeometryPermissionWrapper: Bool
    let didAvoidResourcePermissionWrapper: Bool
    let didAvoidDrawReadyPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        primitiveCommandAdmissionPolicy:
            CjguiInternalRendererPrimitiveCommandAdmissionPolicy,
        didPrepareRendererGeometryBindingAdmissionGuard: Bool,
        shouldDeferRendererGeometryBindingAdmissionGuard: Bool,
        shouldReportRendererGeometryBindingAdmissionGuardBlocked: Bool,
        didPreserveRendererPrimitiveCommandAdmissionPolicy: Bool,
        didDefineFutureGeometryBindingAdmissionGuard: Bool,
        didDescribeGeometrySourceAdmissionFacts: Bool,
        didDescribeIndexSourceAdmissionFacts: Bool,
        didDescribeResourcePlaceholderFacts: Bool,
        didConfirmNoVertexResourceHeld: Bool,
        didConfirmNoIndexResourceHeld: Bool,
        didConfirmNoTextureResourceHeld: Bool,
        didConfirmNoSamplerResourceHeld: Bool,
        didConfirmNoExternalResourceHeld: Bool,
        didKeepGeometryBindingAdmissionGuardValueOnly: Bool,
        didAvoidGeometryPermissionWrapper: Bool,
        didAvoidResourcePermissionWrapper: Bool,
        didAvoidDrawReadyPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.primitiveCommandAdmissionPolicy = primitiveCommandAdmissionPolicy
        this.didPrepareRendererGeometryBindingAdmissionGuard =
            didPrepareRendererGeometryBindingAdmissionGuard
        this.shouldDeferRendererGeometryBindingAdmissionGuard =
            shouldDeferRendererGeometryBindingAdmissionGuard
        this.shouldReportRendererGeometryBindingAdmissionGuardBlocked =
            shouldReportRendererGeometryBindingAdmissionGuardBlocked
        this.didPreserveRendererPrimitiveCommandAdmissionPolicy =
            didPreserveRendererPrimitiveCommandAdmissionPolicy
        this.didDefineFutureGeometryBindingAdmissionGuard =
            didDefineFutureGeometryBindingAdmissionGuard
        this.didDescribeGeometrySourceAdmissionFacts =
            didDescribeGeometrySourceAdmissionFacts
        this.didDescribeIndexSourceAdmissionFacts =
            didDescribeIndexSourceAdmissionFacts
        this.didDescribeResourcePlaceholderFacts =
            didDescribeResourcePlaceholderFacts
        this.didConfirmNoVertexResourceHeld = didConfirmNoVertexResourceHeld
        this.didConfirmNoIndexResourceHeld = didConfirmNoIndexResourceHeld
        this.didConfirmNoTextureResourceHeld = didConfirmNoTextureResourceHeld
        this.didConfirmNoSamplerResourceHeld = didConfirmNoSamplerResourceHeld
        this.didConfirmNoExternalResourceHeld =
            didConfirmNoExternalResourceHeld
        this.didKeepGeometryBindingAdmissionGuardValueOnly =
            didKeepGeometryBindingAdmissionGuardValueOnly
        this.didAvoidGeometryPermissionWrapper =
            didAvoidGeometryPermissionWrapper
        this.didAvoidResourcePermissionWrapper =
            didAvoidResourcePermissionWrapper
        this.didAvoidDrawReadyPermissionWrapper =
            didAvoidDrawReadyPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererDrawOrderingAdmissionPolicy {
    let geometryBindingAdmissionGuard:
        CjguiInternalRendererGeometryBindingAdmissionGuard
    let didPrepareRendererDrawOrderingAdmissionPolicy: Bool
    let shouldDeferRendererDrawOrderingAdmissionPolicy: Bool
    let shouldReportRendererDrawOrderingAdmissionPolicyBlocked: Bool
    let didPreserveRendererGeometryBindingAdmissionGuard: Bool
    let didDefineFutureDrawOrderingAdmissionPolicy: Bool
    let didDescribeDrawOrderAdmissionFacts: Bool
    let didDescribeMaterialGroupingAdmissionFacts: Bool
    let didDescribeStateDependencyAdmissionFacts: Bool
    let didConfirmNoDrawQueueMutation: Bool
    let didConfirmNoMaterialBatching: Bool
    let didConfirmNoGpuOrderingWork: Bool
    let didKeepDrawOrderingAdmissionPolicyValueOnly: Bool
    let didAvoidDrawReadyPermissionWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidStateWriteWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        geometryBindingAdmissionGuard:
            CjguiInternalRendererGeometryBindingAdmissionGuard,
        didPrepareRendererDrawOrderingAdmissionPolicy: Bool,
        shouldDeferRendererDrawOrderingAdmissionPolicy: Bool,
        shouldReportRendererDrawOrderingAdmissionPolicyBlocked: Bool,
        didPreserveRendererGeometryBindingAdmissionGuard: Bool,
        didDefineFutureDrawOrderingAdmissionPolicy: Bool,
        didDescribeDrawOrderAdmissionFacts: Bool,
        didDescribeMaterialGroupingAdmissionFacts: Bool,
        didDescribeStateDependencyAdmissionFacts: Bool,
        didConfirmNoDrawQueueMutation: Bool,
        didConfirmNoMaterialBatching: Bool,
        didConfirmNoGpuOrderingWork: Bool,
        didKeepDrawOrderingAdmissionPolicyValueOnly: Bool,
        didAvoidDrawReadyPermissionWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidStateWriteWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.geometryBindingAdmissionGuard = geometryBindingAdmissionGuard
        this.didPrepareRendererDrawOrderingAdmissionPolicy =
            didPrepareRendererDrawOrderingAdmissionPolicy
        this.shouldDeferRendererDrawOrderingAdmissionPolicy =
            shouldDeferRendererDrawOrderingAdmissionPolicy
        this.shouldReportRendererDrawOrderingAdmissionPolicyBlocked =
            shouldReportRendererDrawOrderingAdmissionPolicyBlocked
        this.didPreserveRendererGeometryBindingAdmissionGuard =
            didPreserveRendererGeometryBindingAdmissionGuard
        this.didDefineFutureDrawOrderingAdmissionPolicy =
            didDefineFutureDrawOrderingAdmissionPolicy
        this.didDescribeDrawOrderAdmissionFacts =
            didDescribeDrawOrderAdmissionFacts
        this.didDescribeMaterialGroupingAdmissionFacts =
            didDescribeMaterialGroupingAdmissionFacts
        this.didDescribeStateDependencyAdmissionFacts =
            didDescribeStateDependencyAdmissionFacts
        this.didConfirmNoDrawQueueMutation = didConfirmNoDrawQueueMutation
        this.didConfirmNoMaterialBatching = didConfirmNoMaterialBatching
        this.didConfirmNoGpuOrderingWork = didConfirmNoGpuOrderingWork
        this.didKeepDrawOrderingAdmissionPolicyValueOnly =
            didKeepDrawOrderingAdmissionPolicyValueOnly
        this.didAvoidDrawReadyPermissionWrapper =
            didAvoidDrawReadyPermissionWrapper
        this.didAvoidRenderPermissionWrapper =
            didAvoidRenderPermissionWrapper
        this.didAvoidStateWriteWrapper = didAvoidStateWriteWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoDrawCallImplementationReadiness {
    let drawOrderingAdmissionPolicy:
        CjguiInternalRendererDrawOrderingAdmissionPolicy
    let isRendererNoDrawCallImplementationReady: Bool
    let canFutureRendererDrawCallImplementationBoundaryEvaluate: Bool
    let shouldDeferRendererNoDrawCallImplementationReadiness: Bool
    let shouldReportRendererNoDrawCallImplementationReadinessBlocked: Bool
    let didSealRendererNoDrawCallImplementationReadiness: Bool
    let didPreserveRendererDrawOrderingAdmissionPolicy: Bool
    let didKeepNoDrawCallImplementationReadinessValueOnly: Bool
    let didConfirmNoDrawCommand: Bool
    let didConfirmNoPrimitiveCommandInvocation: Bool
    let didConfirmNoGeometryResourceHeld: Bool
    let didConfirmNoTextureResourceHeld: Bool
    let didConfirmNoSamplerResourceHeld: Bool
    let didConfirmNoPipelineUse: Bool
    let didConfirmNoPipelineStateObject: Bool
    let didConfirmNoShaderObject: Bool
    let didConfirmNoDescriptorObject: Bool
    let didConfirmNoEncoderObject: Bool
    let didConfirmNoCommandBufferObject: Bool
    let didConfirmNoForeignDeclaration: Bool
    let didConfirmNoForeignInvocation: Bool
    let didConfirmNoExternalHandle: Bool
    let didConfirmNoPointerResource: Bool
    let didConfirmNoGpuWork: Bool
    let didConfirmNoRenderExecution: Bool
    let didConfirmNoRenderStateMutation: Bool
    let didAvoidDrawReadyPermissionWrapper: Bool
    let didAvoidPrimitiveCommandPermissionWrapper: Bool
    let didAvoidGeometryPermissionWrapper: Bool
    let didAvoidResourcePermissionWrapper: Bool
    let didAvoidPipelinePermissionWrapper: Bool
    let didAvoidEncoderPermissionWrapper: Bool
    let didAvoidGpuWorkWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidStateWriteWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool
    let didStayFullRebuildOnly: Bool

    init(
        drawOrderingAdmissionPolicy:
            CjguiInternalRendererDrawOrderingAdmissionPolicy,
        isRendererNoDrawCallImplementationReady: Bool,
        canFutureRendererDrawCallImplementationBoundaryEvaluate: Bool,
        shouldDeferRendererNoDrawCallImplementationReadiness: Bool,
        shouldReportRendererNoDrawCallImplementationReadinessBlocked: Bool,
        didSealRendererNoDrawCallImplementationReadiness: Bool,
        didPreserveRendererDrawOrderingAdmissionPolicy: Bool,
        didKeepNoDrawCallImplementationReadinessValueOnly: Bool,
        didConfirmNoDrawCommand: Bool,
        didConfirmNoPrimitiveCommandInvocation: Bool,
        didConfirmNoGeometryResourceHeld: Bool,
        didConfirmNoTextureResourceHeld: Bool,
        didConfirmNoSamplerResourceHeld: Bool,
        didConfirmNoPipelineUse: Bool,
        didConfirmNoPipelineStateObject: Bool,
        didConfirmNoShaderObject: Bool,
        didConfirmNoDescriptorObject: Bool,
        didConfirmNoEncoderObject: Bool,
        didConfirmNoCommandBufferObject: Bool,
        didConfirmNoForeignDeclaration: Bool,
        didConfirmNoForeignInvocation: Bool,
        didConfirmNoExternalHandle: Bool,
        didConfirmNoPointerResource: Bool,
        didConfirmNoGpuWork: Bool,
        didConfirmNoRenderExecution: Bool,
        didConfirmNoRenderStateMutation: Bool,
        didAvoidDrawReadyPermissionWrapper: Bool,
        didAvoidPrimitiveCommandPermissionWrapper: Bool,
        didAvoidGeometryPermissionWrapper: Bool,
        didAvoidResourcePermissionWrapper: Bool,
        didAvoidPipelinePermissionWrapper: Bool,
        didAvoidEncoderPermissionWrapper: Bool,
        didAvoidGpuWorkWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidStateWriteWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.drawOrderingAdmissionPolicy = drawOrderingAdmissionPolicy
        this.isRendererNoDrawCallImplementationReady =
            isRendererNoDrawCallImplementationReady
        this.canFutureRendererDrawCallImplementationBoundaryEvaluate =
            canFutureRendererDrawCallImplementationBoundaryEvaluate
        this.shouldDeferRendererNoDrawCallImplementationReadiness =
            shouldDeferRendererNoDrawCallImplementationReadiness
        this.shouldReportRendererNoDrawCallImplementationReadinessBlocked =
            shouldReportRendererNoDrawCallImplementationReadinessBlocked
        this.didSealRendererNoDrawCallImplementationReadiness =
            didSealRendererNoDrawCallImplementationReadiness
        this.didPreserveRendererDrawOrderingAdmissionPolicy =
            didPreserveRendererDrawOrderingAdmissionPolicy
        this.didKeepNoDrawCallImplementationReadinessValueOnly =
            didKeepNoDrawCallImplementationReadinessValueOnly
        this.didConfirmNoDrawCommand = didConfirmNoDrawCommand
        this.didConfirmNoPrimitiveCommandInvocation =
            didConfirmNoPrimitiveCommandInvocation
        this.didConfirmNoGeometryResourceHeld =
            didConfirmNoGeometryResourceHeld
        this.didConfirmNoTextureResourceHeld = didConfirmNoTextureResourceHeld
        this.didConfirmNoSamplerResourceHeld = didConfirmNoSamplerResourceHeld
        this.didConfirmNoPipelineUse = didConfirmNoPipelineUse
        this.didConfirmNoPipelineStateObject = didConfirmNoPipelineStateObject
        this.didConfirmNoShaderObject = didConfirmNoShaderObject
        this.didConfirmNoDescriptorObject = didConfirmNoDescriptorObject
        this.didConfirmNoEncoderObject = didConfirmNoEncoderObject
        this.didConfirmNoCommandBufferObject =
            didConfirmNoCommandBufferObject
        this.didConfirmNoForeignDeclaration = didConfirmNoForeignDeclaration
        this.didConfirmNoForeignInvocation = didConfirmNoForeignInvocation
        this.didConfirmNoExternalHandle = didConfirmNoExternalHandle
        this.didConfirmNoPointerResource = didConfirmNoPointerResource
        this.didConfirmNoGpuWork = didConfirmNoGpuWork
        this.didConfirmNoRenderExecution = didConfirmNoRenderExecution
        this.didConfirmNoRenderStateMutation =
            didConfirmNoRenderStateMutation
        this.didAvoidDrawReadyPermissionWrapper =
            didAvoidDrawReadyPermissionWrapper
        this.didAvoidPrimitiveCommandPermissionWrapper =
            didAvoidPrimitiveCommandPermissionWrapper
        this.didAvoidGeometryPermissionWrapper =
            didAvoidGeometryPermissionWrapper
        this.didAvoidResourcePermissionWrapper =
            didAvoidResourcePermissionWrapper
        this.didAvoidPipelinePermissionWrapper =
            didAvoidPipelinePermissionWrapper
        this.didAvoidEncoderPermissionWrapper =
            didAvoidEncoderPermissionWrapper
        this.didAvoidGpuWorkWrapper = didAvoidGpuWorkWrapper
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidStateWriteWrapper = didAvoidStateWriteWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererDrawCallImplementationIntent(
    noPipelineStateImplementationReadiness:
        CjguiInternalRendererNoPipelineStateImplementationReadiness
): CjguiInternalRendererDrawCallImplementationIntent {
    let upstreamCanEvaluate =
        noPipelineStateImplementationReadiness
            .canFutureRendererPipelineStateImplementationBoundaryEvaluate
    let upstreamEndpointReady =
        noPipelineStateImplementationReadiness
            .isRendererNoPipelineStateImplementationReady
    let upstreamShouldDefer =
        noPipelineStateImplementationReadiness
            .shouldDeferRendererNoPipelineStateImplementationReadiness
    let upstreamBlocked =
        noPipelineStateImplementationReadiness
            .shouldReportRendererNoPipelineStateImplementationReadinessBlocked
    let upstreamReady =
        upstreamEndpointReady &&
        upstreamCanEvaluate &&
        noPipelineStateImplementationReadiness
            .didSealRendererNoPipelineStateImplementationReadiness &&
        noPipelineStateImplementationReadiness
            .didPreserveRendererPipelineCompatibilityAdmissionGuard &&
        noPipelineStateImplementationReadiness
            .didKeepNoPipelineStateImplementationReadinessValueOnly &&
        noPipelineStateImplementationReadiness.didConfirmNoPipelineStateObject &&
        noPipelineStateImplementationReadiness.didConfirmNoShaderLibraryObject &&
        noPipelineStateImplementationReadiness.didConfirmNoShaderFunctionObject &&
        noPipelineStateImplementationReadiness
            .didConfirmNoPipelineDescriptorObject &&
        noPipelineStateImplementationReadiness.didConfirmNoEncoderObject &&
        noPipelineStateImplementationReadiness.didConfirmNoCommandBufferObject &&
        noPipelineStateImplementationReadiness.didConfirmNoForeignDeclaration &&
        noPipelineStateImplementationReadiness.didConfirmNoForeignInvocation &&
        noPipelineStateImplementationReadiness.didConfirmNoResourceToken &&
        noPipelineStateImplementationReadiness.didConfirmNoPointerResource &&
        noPipelineStateImplementationReadiness.didConfirmNoGpuWork &&
        noPipelineStateImplementationReadiness.didConfirmNoRenderExecution &&
        noPipelineStateImplementationReadiness.didConfirmNoDrawCommand &&
        noPipelineStateImplementationReadiness.didConfirmNoRenderStateMutation &&
        noPipelineStateImplementationReadiness
            .didAvoidPipelineReadyPermissionWrapper &&
        noPipelineStateImplementationReadiness
            .didAvoidShaderFunctionPermissionWrapper &&
        noPipelineStateImplementationReadiness
            .didAvoidPipelineDescriptorPermissionWrapper &&
        noPipelineStateImplementationReadiness
            .didAvoidEncoderPermissionWrapper &&
        noPipelineStateImplementationReadiness
            .didAvoidCommandBufferPermissionWrapper &&
        noPipelineStateImplementationReadiness
            .didAvoidResourcePermissionWrapper &&
        noPipelineStateImplementationReadiness.didAvoidGpuWorkWrapper &&
        noPipelineStateImplementationReadiness.didAvoidRenderPermissionWrapper &&
        noPipelineStateImplementationReadiness.didAvoidStateWriteWrapper &&
        noPipelineStateImplementationReadiness.didAvoidReceiptRecordOutput &&
        noPipelineStateImplementationReadiness.didAvoidThinWrapper &&
        noPipelineStateImplementationReadiness.didStayFullRebuildOnly &&
        upstreamShouldDefer == false &&
        upstreamBlocked == false
    let upstreamDeferred = upstreamShouldDefer && upstreamBlocked == false
    let upstreamInconsistent =
        upstreamBlocked ||
        (upstreamCanEvaluate && upstreamEndpointReady == false) ||
        (upstreamShouldDefer && upstreamBlocked)

    if (upstreamInconsistent) {
        return CjguiInternalRendererDrawCallImplementationIntent(
            noPipelineStateImplementationReadiness,
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
        return CjguiInternalRendererDrawCallImplementationIntent(
            noPipelineStateImplementationReadiness,
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

    return CjguiInternalRendererDrawCallImplementationIntent(
        noPipelineStateImplementationReadiness,
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

func cjguiInternalBuildRendererPrimitiveCommandAdmissionPolicy(
    implementationIntent:
        CjguiInternalRendererDrawCallImplementationIntent
): CjguiInternalRendererPrimitiveCommandAdmissionPolicy {
    let intentPrepared =
        implementationIntent.didPrepareRendererDrawCallImplementationIntent
    let intentShouldDefer =
        implementationIntent.shouldDeferRendererDrawCallImplementationIntent
    let intentBlocked =
        implementationIntent
            .shouldReportRendererDrawCallImplementationIntentBlocked
    let intentReady =
        intentPrepared &&
        implementationIntent
            .didPreserveRendererNoPipelineStateImplementationReadiness &&
        implementationIntent.didDefineFutureDrawCallImplementationIntent &&
        implementationIntent.didDescribePrimitiveCommandAdmissionNeed &&
        implementationIntent.didDescribeGeometryBindingAdmissionNeed &&
        implementationIntent.didDescribeDrawOrderingAdmissionNeed &&
        implementationIntent.didKeepDrawCallImplementationIntentValueOnly &&
        implementationIntent.didAvoidDrawReadyPermissionWrapper &&
        implementationIntent.didAvoidBackendImplementationWrapper &&
        implementationIntent.didAvoidReceiptRecordOutput &&
        implementationIntent.didAvoidThinWrapper &&
        intentShouldDefer == false &&
        intentBlocked == false
    let intentDeferred = intentShouldDefer && intentBlocked == false
    let intentInconsistent =
        intentBlocked ||
        (intentPrepared && intentReady == false) ||
        (intentShouldDefer && intentBlocked)

    if (intentInconsistent) {
        return CjguiInternalRendererPrimitiveCommandAdmissionPolicy(
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
        return CjguiInternalRendererPrimitiveCommandAdmissionPolicy(
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

    return CjguiInternalRendererPrimitiveCommandAdmissionPolicy(
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

func cjguiInternalBuildRendererGeometryBindingAdmissionGuard(
    primitiveCommandAdmissionPolicy:
        CjguiInternalRendererPrimitiveCommandAdmissionPolicy
): CjguiInternalRendererGeometryBindingAdmissionGuard {
    let primitiveReady =
        primitiveCommandAdmissionPolicy
            .didPrepareRendererPrimitiveCommandAdmissionPolicy &&
        primitiveCommandAdmissionPolicy
            .didPreserveRendererDrawCallImplementationIntent &&
        primitiveCommandAdmissionPolicy
            .didDefineFuturePrimitiveCommandAdmissionPolicy &&
        primitiveCommandAdmissionPolicy.didDescribePrimitiveKindAdmissionFacts &&
        primitiveCommandAdmissionPolicy.didDescribeVertexCountAdmissionFacts &&
        primitiveCommandAdmissionPolicy.didDescribeInstanceCountAdmissionFacts &&
        primitiveCommandAdmissionPolicy.didConfirmNoDrawCommandIssued &&
        primitiveCommandAdmissionPolicy.didConfirmNoPrimitiveCommandInvoked &&
        primitiveCommandAdmissionPolicy
            .didKeepPrimitiveCommandAdmissionPolicyValueOnly &&
        primitiveCommandAdmissionPolicy
            .didAvoidPrimitiveCommandPermissionWrapper &&
        primitiveCommandAdmissionPolicy.didAvoidDrawReadyPermissionWrapper &&
        primitiveCommandAdmissionPolicy.didAvoidRenderPermissionWrapper &&
        primitiveCommandAdmissionPolicy.didAvoidThinWrapper &&
        primitiveCommandAdmissionPolicy
            .shouldDeferRendererPrimitiveCommandAdmissionPolicy == false &&
        primitiveCommandAdmissionPolicy
            .shouldReportRendererPrimitiveCommandAdmissionPolicyBlocked ==
            false
    let primitiveDeferred =
        primitiveCommandAdmissionPolicy
            .shouldDeferRendererPrimitiveCommandAdmissionPolicy &&
        primitiveCommandAdmissionPolicy
            .shouldReportRendererPrimitiveCommandAdmissionPolicyBlocked ==
            false
    let primitiveInconsistent =
        primitiveCommandAdmissionPolicy
            .shouldReportRendererPrimitiveCommandAdmissionPolicyBlocked ||
        (
            primitiveCommandAdmissionPolicy
                .didPrepareRendererPrimitiveCommandAdmissionPolicy &&
            primitiveReady == false
        ) ||
        (
            primitiveCommandAdmissionPolicy
                .shouldDeferRendererPrimitiveCommandAdmissionPolicy &&
            primitiveCommandAdmissionPolicy
                .shouldReportRendererPrimitiveCommandAdmissionPolicyBlocked
        )

    if (primitiveInconsistent) {
        return CjguiInternalRendererGeometryBindingAdmissionGuard(
            primitiveCommandAdmissionPolicy,
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
            true,
            true,
            true
        )
    }

    if (primitiveDeferred || primitiveReady == false) {
        return CjguiInternalRendererGeometryBindingAdmissionGuard(
            primitiveCommandAdmissionPolicy,
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
            true,
            true
        )
    }

    return CjguiInternalRendererGeometryBindingAdmissionGuard(
        primitiveCommandAdmissionPolicy,
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

func cjguiInternalBuildRendererDrawOrderingAdmissionPolicy(
    geometryBindingAdmissionGuard:
        CjguiInternalRendererGeometryBindingAdmissionGuard
): CjguiInternalRendererDrawOrderingAdmissionPolicy {
    let geometryReady =
        geometryBindingAdmissionGuard
            .didPrepareRendererGeometryBindingAdmissionGuard &&
        geometryBindingAdmissionGuard
            .didPreserveRendererPrimitiveCommandAdmissionPolicy &&
        geometryBindingAdmissionGuard
            .didDefineFutureGeometryBindingAdmissionGuard &&
        geometryBindingAdmissionGuard.didDescribeGeometrySourceAdmissionFacts &&
        geometryBindingAdmissionGuard.didDescribeIndexSourceAdmissionFacts &&
        geometryBindingAdmissionGuard.didDescribeResourcePlaceholderFacts &&
        geometryBindingAdmissionGuard.didConfirmNoVertexResourceHeld &&
        geometryBindingAdmissionGuard.didConfirmNoIndexResourceHeld &&
        geometryBindingAdmissionGuard.didConfirmNoTextureResourceHeld &&
        geometryBindingAdmissionGuard.didConfirmNoSamplerResourceHeld &&
        geometryBindingAdmissionGuard.didConfirmNoExternalResourceHeld &&
        geometryBindingAdmissionGuard
            .didKeepGeometryBindingAdmissionGuardValueOnly &&
        geometryBindingAdmissionGuard.didAvoidGeometryPermissionWrapper &&
        geometryBindingAdmissionGuard.didAvoidResourcePermissionWrapper &&
        geometryBindingAdmissionGuard.didAvoidDrawReadyPermissionWrapper &&
        geometryBindingAdmissionGuard.didAvoidThinWrapper &&
        geometryBindingAdmissionGuard
            .shouldDeferRendererGeometryBindingAdmissionGuard == false &&
        geometryBindingAdmissionGuard
            .shouldReportRendererGeometryBindingAdmissionGuardBlocked == false
    let geometryDeferred =
        geometryBindingAdmissionGuard
            .shouldDeferRendererGeometryBindingAdmissionGuard &&
        geometryBindingAdmissionGuard
            .shouldReportRendererGeometryBindingAdmissionGuardBlocked == false
    let geometryInconsistent =
        geometryBindingAdmissionGuard
            .shouldReportRendererGeometryBindingAdmissionGuardBlocked ||
        (
            geometryBindingAdmissionGuard
                .didPrepareRendererGeometryBindingAdmissionGuard &&
            geometryReady == false
        ) ||
        (
            geometryBindingAdmissionGuard
                .shouldDeferRendererGeometryBindingAdmissionGuard &&
            geometryBindingAdmissionGuard
                .shouldReportRendererGeometryBindingAdmissionGuardBlocked
        )

    if (geometryInconsistent) {
        return CjguiInternalRendererDrawOrderingAdmissionPolicy(
            geometryBindingAdmissionGuard,
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

    if (geometryDeferred || geometryReady == false) {
        return CjguiInternalRendererDrawOrderingAdmissionPolicy(
            geometryBindingAdmissionGuard,
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

    return CjguiInternalRendererDrawOrderingAdmissionPolicy(
        geometryBindingAdmissionGuard,
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

func cjguiInternalBuildRendererNoDrawCallImplementationReadiness(
    drawOrderingAdmissionPolicy:
        CjguiInternalRendererDrawOrderingAdmissionPolicy
): CjguiInternalRendererNoDrawCallImplementationReadiness {
    let orderingReady =
        drawOrderingAdmissionPolicy
            .didPrepareRendererDrawOrderingAdmissionPolicy &&
        drawOrderingAdmissionPolicy
            .didPreserveRendererGeometryBindingAdmissionGuard &&
        drawOrderingAdmissionPolicy.didDefineFutureDrawOrderingAdmissionPolicy &&
        drawOrderingAdmissionPolicy.didDescribeDrawOrderAdmissionFacts &&
        drawOrderingAdmissionPolicy.didDescribeMaterialGroupingAdmissionFacts &&
        drawOrderingAdmissionPolicy.didDescribeStateDependencyAdmissionFacts &&
        drawOrderingAdmissionPolicy.didConfirmNoDrawQueueMutation &&
        drawOrderingAdmissionPolicy.didConfirmNoMaterialBatching &&
        drawOrderingAdmissionPolicy.didConfirmNoGpuOrderingWork &&
        drawOrderingAdmissionPolicy
            .didKeepDrawOrderingAdmissionPolicyValueOnly &&
        drawOrderingAdmissionPolicy.didAvoidDrawReadyPermissionWrapper &&
        drawOrderingAdmissionPolicy.didAvoidRenderPermissionWrapper &&
        drawOrderingAdmissionPolicy.didAvoidStateWriteWrapper &&
        drawOrderingAdmissionPolicy.didAvoidThinWrapper &&
        drawOrderingAdmissionPolicy
            .shouldDeferRendererDrawOrderingAdmissionPolicy == false &&
        drawOrderingAdmissionPolicy
            .shouldReportRendererDrawOrderingAdmissionPolicyBlocked == false
    let orderingDeferred =
        drawOrderingAdmissionPolicy
            .shouldDeferRendererDrawOrderingAdmissionPolicy &&
        drawOrderingAdmissionPolicy
            .shouldReportRendererDrawOrderingAdmissionPolicyBlocked == false
    let orderingInconsistent =
        drawOrderingAdmissionPolicy
            .shouldReportRendererDrawOrderingAdmissionPolicyBlocked ||
        (
            drawOrderingAdmissionPolicy
                .didPrepareRendererDrawOrderingAdmissionPolicy &&
            orderingReady == false
        ) ||
        (
            drawOrderingAdmissionPolicy
                .shouldDeferRendererDrawOrderingAdmissionPolicy &&
            drawOrderingAdmissionPolicy
                .shouldReportRendererDrawOrderingAdmissionPolicyBlocked
        )

    if (orderingInconsistent) {
        return CjguiInternalRendererNoDrawCallImplementationReadiness(
            drawOrderingAdmissionPolicy,
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
            true
        )
    }

    if (orderingDeferred || orderingReady == false) {
        return CjguiInternalRendererNoDrawCallImplementationReadiness(
            drawOrderingAdmissionPolicy,
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
            true
        )
    }

    return CjguiInternalRendererNoDrawCallImplementationReadiness(
        drawOrderingAdmissionPolicy,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft():
    CjguiInternalRendererNoDrawCallImplementationReadiness {
    let noPipelineStateImplementationReadiness =
        cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()
    let implementationIntent =
        cjguiInternalBuildRendererDrawCallImplementationIntent(
            noPipelineStateImplementationReadiness
        )
    let primitiveCommandAdmissionPolicy =
        cjguiInternalBuildRendererPrimitiveCommandAdmissionPolicy(
            implementationIntent
        )
    let geometryBindingAdmissionGuard =
        cjguiInternalBuildRendererGeometryBindingAdmissionGuard(
            primitiveCommandAdmissionPolicy
        )
    let drawOrderingAdmissionPolicy =
        cjguiInternalBuildRendererDrawOrderingAdmissionPolicy(
            geometryBindingAdmissionGuard
        )
    return cjguiInternalBuildRendererNoDrawCallImplementationReadiness(
        drawOrderingAdmissionPolicy
    )
}
