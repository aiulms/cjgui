// 中文维护注释：本文件是 visible-window runtime native probe 的
// pipeline-state / vertex-buffer preparation first-slice readiness owner。
// Owner: runtime renderer internal pipeline / vertex preparation first slice。
// Truth: 消费 stage110 render command encoder first-slice readiness，把下一步
// 收敛为 bounded isolated probe-local shader library / functions、pipeline
// descriptor / pipeline state 与 static triangle vertex buffer 创建合约。
// Stop-line: 本 owner 不绑定 pipeline，不绑定 vertex buffer，不 draw，不
// commit / present，不提交 GPU work，不写 renderer state，不把 isolated
// evidence 升级为 production truth，也不扩 production native bridge C ABI。
// Same-shape Boundary Brake: 本 owner 必须表达 pipeline / vertex preparation
// first-slice contract；不得退化成 approval、external packet、recovery、
// report wrapper 或 generic guard。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceFacts {
    let didConsumeRenderCommandEncoderFirstSliceReadiness: Bool
    let didRequirePositiveEncoderEnvelopeBeforePreparation: Bool
    let didRequireBoundedIsolatedPipelineVertexProbe: Bool
    let didRequireProbeLocalShaderLibrary: Bool
    let didRequireProbeLocalShaderFunctions: Bool
    let didRequireProbeLocalPipelineDescriptor: Bool
    let didRequireProbeLocalPipelineState: Bool
    let didRequireProbeLocalStaticTriangleVertexBuffer: Bool
    let didRequireEncoderEndEncodingBeforePreparationCleanup: Bool
    let didKeepPipelineBindingBlocked: Bool
    let didKeepVertexBufferBindingBlocked: Bool
    let didKeepDrawCommitPresentGpuRenderBlocked: Bool
    let didRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didConfirmNoProductionTruthUpgrade: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didConfirmNoProductionNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didAvoidApprovalExternalPacketRecoveryOrReportWrapper: Bool

    init(
        didConsumeRenderCommandEncoderFirstSliceReadiness: Bool,
        didRequirePositiveEncoderEnvelopeBeforePreparation: Bool,
        didRequireBoundedIsolatedPipelineVertexProbe: Bool,
        didRequireProbeLocalShaderLibrary: Bool,
        didRequireProbeLocalShaderFunctions: Bool,
        didRequireProbeLocalPipelineDescriptor: Bool,
        didRequireProbeLocalPipelineState: Bool,
        didRequireProbeLocalStaticTriangleVertexBuffer: Bool,
        didRequireEncoderEndEncodingBeforePreparationCleanup: Bool,
        didKeepPipelineBindingBlocked: Bool,
        didKeepVertexBufferBindingBlocked: Bool,
        didKeepDrawCommitPresentGpuRenderBlocked: Bool,
        didRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didConfirmNoProductionTruthUpgrade: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didConfirmNoProductionNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didAvoidApprovalExternalPacketRecoveryOrReportWrapper: Bool
    ) {
        this.didConsumeRenderCommandEncoderFirstSliceReadiness =
            didConsumeRenderCommandEncoderFirstSliceReadiness
        this.didRequirePositiveEncoderEnvelopeBeforePreparation =
            didRequirePositiveEncoderEnvelopeBeforePreparation
        this.didRequireBoundedIsolatedPipelineVertexProbe =
            didRequireBoundedIsolatedPipelineVertexProbe
        this.didRequireProbeLocalShaderLibrary =
            didRequireProbeLocalShaderLibrary
        this.didRequireProbeLocalShaderFunctions =
            didRequireProbeLocalShaderFunctions
        this.didRequireProbeLocalPipelineDescriptor =
            didRequireProbeLocalPipelineDescriptor
        this.didRequireProbeLocalPipelineState =
            didRequireProbeLocalPipelineState
        this.didRequireProbeLocalStaticTriangleVertexBuffer =
            didRequireProbeLocalStaticTriangleVertexBuffer
        this.didRequireEncoderEndEncodingBeforePreparationCleanup =
            didRequireEncoderEndEncodingBeforePreparationCleanup
        this.didKeepPipelineBindingBlocked = didKeepPipelineBindingBlocked
        this.didKeepVertexBufferBindingBlocked =
            didKeepVertexBufferBindingBlocked
        this.didKeepDrawCommitPresentGpuRenderBlocked =
            didKeepDrawCommitPresentGpuRenderBlocked
        this.didRequireProductionWriteAdmissionBeforeRendererStateWrite =
            didRequireProductionWriteAdmissionBeforeRendererStateWrite
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didConfirmNoProductionTruthUpgrade =
            didConfirmNoProductionTruthUpgrade
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didConfirmNoProductionNativeBridgeExpansion =
            didConfirmNoProductionNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didAvoidApprovalExternalPacketRecoveryOrReportWrapper =
            didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceReadiness {
    let encoderFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceReadiness
    let pipelineVertexPreparationFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceFacts
    let didPrepareRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceReadiness:
        Bool
    let shouldConsumeRenderCommandEncoderFirstSliceReadiness: Bool
    let shouldRequirePositiveEncoderEnvelopeBeforePreparation: Bool
    let shouldRequireBoundedIsolatedPipelineVertexProbe: Bool
    let shouldRequireProbeLocalShaderLibrary: Bool
    let shouldRequireProbeLocalShaderFunctions: Bool
    let shouldRequireProbeLocalPipelineDescriptor: Bool
    let shouldRequireProbeLocalPipelineState: Bool
    let shouldRequireProbeLocalStaticTriangleVertexBuffer: Bool
    let shouldRequireEncoderEndEncodingBeforePreparationCleanup: Bool
    let shouldKeepPipelineBindingBlocked: Bool
    let shouldKeepVertexBufferBindingBlocked: Bool
    let shouldKeepDrawCommitPresentGpuRenderBlocked: Bool
    let shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool
    let shouldKeepRendererStateWriteBlocked: Bool
    let didConfirmRenderCommandEncoderFirstSliceInput: Bool
    let didConfirmPipelineVertexPreparationOrdering: Bool
    let didConfirmPipelineVertexPreparationStopLine: Bool
    let didConfirmNoProductionTruthUpgrade: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didConfirmNoProductionNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didAvoidApprovalExternalPacketRecoveryOrReportWrapper: Bool

    init(
        encoderFirstSliceReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceReadiness,
        pipelineVertexPreparationFirstSliceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceFacts,
        didPrepareRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceReadiness:
            Bool,
        shouldConsumeRenderCommandEncoderFirstSliceReadiness: Bool,
        shouldRequirePositiveEncoderEnvelopeBeforePreparation: Bool,
        shouldRequireBoundedIsolatedPipelineVertexProbe: Bool,
        shouldRequireProbeLocalShaderLibrary: Bool,
        shouldRequireProbeLocalShaderFunctions: Bool,
        shouldRequireProbeLocalPipelineDescriptor: Bool,
        shouldRequireProbeLocalPipelineState: Bool,
        shouldRequireProbeLocalStaticTriangleVertexBuffer: Bool,
        shouldRequireEncoderEndEncodingBeforePreparationCleanup: Bool,
        shouldKeepPipelineBindingBlocked: Bool,
        shouldKeepVertexBufferBindingBlocked: Bool,
        shouldKeepDrawCommitPresentGpuRenderBlocked: Bool,
        shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool,
        shouldKeepRendererStateWriteBlocked: Bool,
        didConfirmRenderCommandEncoderFirstSliceInput: Bool,
        didConfirmPipelineVertexPreparationOrdering: Bool,
        didConfirmPipelineVertexPreparationStopLine: Bool,
        didConfirmNoProductionTruthUpgrade: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didConfirmNoProductionNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didAvoidApprovalExternalPacketRecoveryOrReportWrapper: Bool
    ) {
        this.encoderFirstSliceReadiness =
            encoderFirstSliceReadiness
        this.pipelineVertexPreparationFirstSliceFacts =
            pipelineVertexPreparationFirstSliceFacts
        this.didPrepareRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceReadiness =
            didPrepareRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceReadiness
        this.shouldConsumeRenderCommandEncoderFirstSliceReadiness =
            shouldConsumeRenderCommandEncoderFirstSliceReadiness
        this.shouldRequirePositiveEncoderEnvelopeBeforePreparation =
            shouldRequirePositiveEncoderEnvelopeBeforePreparation
        this.shouldRequireBoundedIsolatedPipelineVertexProbe =
            shouldRequireBoundedIsolatedPipelineVertexProbe
        this.shouldRequireProbeLocalShaderLibrary =
            shouldRequireProbeLocalShaderLibrary
        this.shouldRequireProbeLocalShaderFunctions =
            shouldRequireProbeLocalShaderFunctions
        this.shouldRequireProbeLocalPipelineDescriptor =
            shouldRequireProbeLocalPipelineDescriptor
        this.shouldRequireProbeLocalPipelineState =
            shouldRequireProbeLocalPipelineState
        this.shouldRequireProbeLocalStaticTriangleVertexBuffer =
            shouldRequireProbeLocalStaticTriangleVertexBuffer
        this.shouldRequireEncoderEndEncodingBeforePreparationCleanup =
            shouldRequireEncoderEndEncodingBeforePreparationCleanup
        this.shouldKeepPipelineBindingBlocked = shouldKeepPipelineBindingBlocked
        this.shouldKeepVertexBufferBindingBlocked =
            shouldKeepVertexBufferBindingBlocked
        this.shouldKeepDrawCommitPresentGpuRenderBlocked =
            shouldKeepDrawCommitPresentGpuRenderBlocked
        this.shouldRequireProductionWriteAdmissionBeforeRendererStateWrite =
            shouldRequireProductionWriteAdmissionBeforeRendererStateWrite
        this.shouldKeepRendererStateWriteBlocked =
            shouldKeepRendererStateWriteBlocked
        this.didConfirmRenderCommandEncoderFirstSliceInput =
            didConfirmRenderCommandEncoderFirstSliceInput
        this.didConfirmPipelineVertexPreparationOrdering =
            didConfirmPipelineVertexPreparationOrdering
        this.didConfirmPipelineVertexPreparationStopLine =
            didConfirmPipelineVertexPreparationStopLine
        this.didConfirmNoProductionTruthUpgrade =
            didConfirmNoProductionTruthUpgrade
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didConfirmNoProductionNativeBridgeExpansion =
            didConfirmNoProductionNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didAvoidApprovalExternalPacketRecoveryOrReportWrapper =
            didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceFacts(
    encoderFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceFacts(
        encoderFirstSliceReadiness
            .didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceReadiness,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        encoderFirstSliceReadiness
            .shouldRequireEndEncodingBeforeCleanup,
        true,
        true,
        encoderFirstSliceReadiness
            .shouldKeepPipelineVertexDrawCommitPresentGpuRenderBlocked,
        encoderFirstSliceReadiness
            .shouldRequireProductionWriteAdmissionBeforeRendererStateWrite,
        encoderFirstSliceReadiness.shouldKeepRendererStateWriteBlocked,
        encoderFirstSliceReadiness.didConfirmNoProductionTruthUpgrade,
        encoderFirstSliceReadiness.didConfirmNoBackendReadyTruth,
        encoderFirstSliceReadiness
            .didConfirmNoProductionNativeBridgeExpansion,
        encoderFirstSliceReadiness.didConfirmNoPublicApi,
        encoderFirstSliceReadiness.didConfirmNoProductionPublicCAbi,
        encoderFirstSliceReadiness.didConfirmNoRuntimeStateWrite,
        encoderFirstSliceReadiness.didConfirmNoCjpmTomlChange,
        encoderFirstSliceReadiness.didConfirmNoRendererStateWrite,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceReadiness(
    encoderFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceReadiness,
    pipelineVertexPreparationFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceReadiness {
    let encoderInputReady =
        pipelineVertexPreparationFirstSliceFacts
            .didConsumeRenderCommandEncoderFirstSliceReadiness &&
        encoderFirstSliceReadiness
            .didConfirmRenderCommandEncoderFirstSliceOrdering &&
        encoderFirstSliceReadiness
            .didConfirmRenderCommandEncoderFirstSliceStopLine
    let orderingReady =
        pipelineVertexPreparationFirstSliceFacts
            .didRequirePositiveEncoderEnvelopeBeforePreparation &&
        pipelineVertexPreparationFirstSliceFacts
            .didRequireBoundedIsolatedPipelineVertexProbe &&
        pipelineVertexPreparationFirstSliceFacts
            .didRequireProbeLocalShaderLibrary &&
        pipelineVertexPreparationFirstSliceFacts
            .didRequireProbeLocalShaderFunctions &&
        pipelineVertexPreparationFirstSliceFacts
            .didRequireProbeLocalPipelineDescriptor &&
        pipelineVertexPreparationFirstSliceFacts
            .didRequireProbeLocalPipelineState &&
        pipelineVertexPreparationFirstSliceFacts
            .didRequireProbeLocalStaticTriangleVertexBuffer &&
        pipelineVertexPreparationFirstSliceFacts
            .didRequireEncoderEndEncodingBeforePreparationCleanup
    let stopLineReady =
        pipelineVertexPreparationFirstSliceFacts.didKeepPipelineBindingBlocked &&
        pipelineVertexPreparationFirstSliceFacts
            .didKeepVertexBufferBindingBlocked &&
        pipelineVertexPreparationFirstSliceFacts
            .didKeepDrawCommitPresentGpuRenderBlocked &&
        pipelineVertexPreparationFirstSliceFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite &&
        pipelineVertexPreparationFirstSliceFacts.didKeepRendererStateWriteBlocked &&
        pipelineVertexPreparationFirstSliceFacts
            .didConfirmNoProductionTruthUpgrade &&
        pipelineVertexPreparationFirstSliceFacts.didConfirmNoBackendReadyTruth &&
        pipelineVertexPreparationFirstSliceFacts
            .didConfirmNoProductionNativeBridgeExpansion &&
        pipelineVertexPreparationFirstSliceFacts.didConfirmNoPublicApi &&
        pipelineVertexPreparationFirstSliceFacts
            .didConfirmNoProductionPublicCAbi &&
        pipelineVertexPreparationFirstSliceFacts.didConfirmNoRuntimeStateWrite &&
        pipelineVertexPreparationFirstSliceFacts.didConfirmNoCjpmTomlChange &&
        pipelineVertexPreparationFirstSliceFacts.didConfirmNoRendererStateWrite &&
        pipelineVertexPreparationFirstSliceFacts
            .didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    let readinessReady = encoderInputReady && orderingReady && stopLineReady

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceReadiness(
        encoderFirstSliceReadiness,
        pipelineVertexPreparationFirstSliceFacts,
        readinessReady,
        pipelineVertexPreparationFirstSliceFacts
            .didConsumeRenderCommandEncoderFirstSliceReadiness,
        pipelineVertexPreparationFirstSliceFacts
            .didRequirePositiveEncoderEnvelopeBeforePreparation,
        pipelineVertexPreparationFirstSliceFacts
            .didRequireBoundedIsolatedPipelineVertexProbe,
        pipelineVertexPreparationFirstSliceFacts.didRequireProbeLocalShaderLibrary,
        pipelineVertexPreparationFirstSliceFacts
            .didRequireProbeLocalShaderFunctions,
        pipelineVertexPreparationFirstSliceFacts
            .didRequireProbeLocalPipelineDescriptor,
        pipelineVertexPreparationFirstSliceFacts
            .didRequireProbeLocalPipelineState,
        pipelineVertexPreparationFirstSliceFacts
            .didRequireProbeLocalStaticTriangleVertexBuffer,
        pipelineVertexPreparationFirstSliceFacts
            .didRequireEncoderEndEncodingBeforePreparationCleanup,
        pipelineVertexPreparationFirstSliceFacts.didKeepPipelineBindingBlocked,
        pipelineVertexPreparationFirstSliceFacts
            .didKeepVertexBufferBindingBlocked,
        pipelineVertexPreparationFirstSliceFacts
            .didKeepDrawCommitPresentGpuRenderBlocked,
        pipelineVertexPreparationFirstSliceFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite,
        pipelineVertexPreparationFirstSliceFacts.didKeepRendererStateWriteBlocked,
        encoderInputReady,
        orderingReady,
        stopLineReady,
        pipelineVertexPreparationFirstSliceFacts
            .didConfirmNoProductionTruthUpgrade,
        pipelineVertexPreparationFirstSliceFacts.didConfirmNoBackendReadyTruth,
        pipelineVertexPreparationFirstSliceFacts
            .didConfirmNoProductionNativeBridgeExpansion,
        pipelineVertexPreparationFirstSliceFacts.didConfirmNoPublicApi,
        pipelineVertexPreparationFirstSliceFacts
            .didConfirmNoProductionPublicCAbi,
        pipelineVertexPreparationFirstSliceFacts.didConfirmNoRuntimeStateWrite,
        pipelineVertexPreparationFirstSliceFacts.didConfirmNoCjpmTomlChange,
        pipelineVertexPreparationFirstSliceFacts.didConfirmNoRendererStateWrite,
        pipelineVertexPreparationFirstSliceFacts
            .didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceReadiness {
    let encoderFirstSliceReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRenderCommandEncoderFirstSliceDraft()
    let pipelineVertexPreparationFirstSliceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceFacts(
            encoderFirstSliceReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationFirstSliceReadiness(
        encoderFirstSliceReadiness,
        pipelineVertexPreparationFirstSliceFacts
    )
}
