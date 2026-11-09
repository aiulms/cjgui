// 中文维护注释：本文件是 visible-window runtime native probe 的
// command queue / command buffer first-slice readiness owner。
// Owner: runtime renderer internal command queue / command buffer first slice。
// Truth: 只消费 stage105 command-pipeline readiness envelope，并把第一帧链路
// 中 Metal device 后的 command queue / command buffer create-destroy first
// slice 建模为 bounded current-shell execution contract。它不创建 encoder，
// 不提交或 present，不写 renderer state，不把 current-shell evidence 升级为
// production truth。
// Stop-line: 不新增 production accessor call site，不调用 application
// singleton accessor，不创建或激活 NSApplication，不扩 native bridge / public
// API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
// Same-shape Boundary Brake: 本 owner 必须表达 command queue / command buffer
// first-slice contract；不得退化成 approval、recovery、external packet、
// report wrapper 或 no-runtime-execution 包装。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceFacts {
    let didConsumeCommandPipelineReadinessEnvelope: Bool
    let didRequireMetalDeviceForNativeFirstSlice: Bool
    let didAllowCommandQueueCreateDestroyFirstSlice: Bool
    let didAllowCommandBufferCreateDestroyFirstSlice: Bool
    let didRequireCommandQueueBeforeCommandBuffer: Bool
    let didKeepEncoderCreationBlocked: Bool
    let didKeepCommitPresentBlocked: Bool
    let didRequireTokenLocalCleanup: Bool
    let didKeepFirstSliceCurrentShellBounded: Bool
    let didRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didConfirmNoProductionTruthUpgrade: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didAvoidApprovalRecoveryOrReportWrapper: Bool

    init(
        didConsumeCommandPipelineReadinessEnvelope: Bool,
        didRequireMetalDeviceForNativeFirstSlice: Bool,
        didAllowCommandQueueCreateDestroyFirstSlice: Bool,
        didAllowCommandBufferCreateDestroyFirstSlice: Bool,
        didRequireCommandQueueBeforeCommandBuffer: Bool,
        didKeepEncoderCreationBlocked: Bool,
        didKeepCommitPresentBlocked: Bool,
        didRequireTokenLocalCleanup: Bool,
        didKeepFirstSliceCurrentShellBounded: Bool,
        didRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didConfirmNoProductionTruthUpgrade: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didAvoidApprovalRecoveryOrReportWrapper: Bool
    ) {
        this.didConsumeCommandPipelineReadinessEnvelope =
            didConsumeCommandPipelineReadinessEnvelope
        this.didRequireMetalDeviceForNativeFirstSlice =
            didRequireMetalDeviceForNativeFirstSlice
        this.didAllowCommandQueueCreateDestroyFirstSlice =
            didAllowCommandQueueCreateDestroyFirstSlice
        this.didAllowCommandBufferCreateDestroyFirstSlice =
            didAllowCommandBufferCreateDestroyFirstSlice
        this.didRequireCommandQueueBeforeCommandBuffer =
            didRequireCommandQueueBeforeCommandBuffer
        this.didKeepEncoderCreationBlocked = didKeepEncoderCreationBlocked
        this.didKeepCommitPresentBlocked = didKeepCommitPresentBlocked
        this.didRequireTokenLocalCleanup = didRequireTokenLocalCleanup
        this.didKeepFirstSliceCurrentShellBounded =
            didKeepFirstSliceCurrentShellBounded
        this.didRequireProductionWriteAdmissionBeforeRendererStateWrite =
            didRequireProductionWriteAdmissionBeforeRendererStateWrite
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didConfirmNoProductionTruthUpgrade =
            didConfirmNoProductionTruthUpgrade
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didConfirmNoNativeBridgeExpansion =
            didConfirmNoNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didAvoidApprovalRecoveryOrReportWrapper =
            didAvoidApprovalRecoveryOrReportWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceReadiness {
    let commandPipelineReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineReadiness
    let commandQueueCommandBufferFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceFacts
    let didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceReadiness:
        Bool
    let shouldConsumeCommandPipelineReadinessEnvelope: Bool
    let shouldRequireMetalDeviceForNativeFirstSlice: Bool
    let shouldAllowCommandQueueCreateDestroyFirstSlice: Bool
    let shouldAllowCommandBufferCreateDestroyFirstSlice: Bool
    let shouldRequireCommandQueueBeforeCommandBuffer: Bool
    let shouldKeepEncoderCreationBlocked: Bool
    let shouldKeepCommitPresentBlocked: Bool
    let shouldRequireTokenLocalCleanup: Bool
    let shouldKeepCurrentShellFirstSliceBounded: Bool
    let shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool
    let shouldKeepRendererStateWriteBlocked: Bool
    let didConfirmCommandPipelineInput: Bool
    let didConfirmFirstSliceOrdering: Bool
    let didConfirmFirstSliceStopLine: Bool
    let didConfirmNoProductionTruthUpgrade: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didAvoidApprovalRecoveryOrReportWrapper: Bool

    init(
        commandPipelineReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineReadiness,
        commandQueueCommandBufferFirstSliceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceFacts,
        didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceReadiness:
            Bool,
        shouldConsumeCommandPipelineReadinessEnvelope: Bool,
        shouldRequireMetalDeviceForNativeFirstSlice: Bool,
        shouldAllowCommandQueueCreateDestroyFirstSlice: Bool,
        shouldAllowCommandBufferCreateDestroyFirstSlice: Bool,
        shouldRequireCommandQueueBeforeCommandBuffer: Bool,
        shouldKeepEncoderCreationBlocked: Bool,
        shouldKeepCommitPresentBlocked: Bool,
        shouldRequireTokenLocalCleanup: Bool,
        shouldKeepCurrentShellFirstSliceBounded: Bool,
        shouldRequireProductionWriteAdmissionBeforeRendererStateWrite: Bool,
        shouldKeepRendererStateWriteBlocked: Bool,
        didConfirmCommandPipelineInput: Bool,
        didConfirmFirstSliceOrdering: Bool,
        didConfirmFirstSliceStopLine: Bool,
        didConfirmNoProductionTruthUpgrade: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didAvoidApprovalRecoveryOrReportWrapper: Bool
    ) {
        this.commandPipelineReadiness = commandPipelineReadiness
        this.commandQueueCommandBufferFirstSliceFacts =
            commandQueueCommandBufferFirstSliceFacts
        this.didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceReadiness =
            didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceReadiness
        this.shouldConsumeCommandPipelineReadinessEnvelope =
            shouldConsumeCommandPipelineReadinessEnvelope
        this.shouldRequireMetalDeviceForNativeFirstSlice =
            shouldRequireMetalDeviceForNativeFirstSlice
        this.shouldAllowCommandQueueCreateDestroyFirstSlice =
            shouldAllowCommandQueueCreateDestroyFirstSlice
        this.shouldAllowCommandBufferCreateDestroyFirstSlice =
            shouldAllowCommandBufferCreateDestroyFirstSlice
        this.shouldRequireCommandQueueBeforeCommandBuffer =
            shouldRequireCommandQueueBeforeCommandBuffer
        this.shouldKeepEncoderCreationBlocked =
            shouldKeepEncoderCreationBlocked
        this.shouldKeepCommitPresentBlocked = shouldKeepCommitPresentBlocked
        this.shouldRequireTokenLocalCleanup = shouldRequireTokenLocalCleanup
        this.shouldKeepCurrentShellFirstSliceBounded =
            shouldKeepCurrentShellFirstSliceBounded
        this.shouldRequireProductionWriteAdmissionBeforeRendererStateWrite =
            shouldRequireProductionWriteAdmissionBeforeRendererStateWrite
        this.shouldKeepRendererStateWriteBlocked =
            shouldKeepRendererStateWriteBlocked
        this.didConfirmCommandPipelineInput =
            didConfirmCommandPipelineInput
        this.didConfirmFirstSliceOrdering = didConfirmFirstSliceOrdering
        this.didConfirmFirstSliceStopLine = didConfirmFirstSliceStopLine
        this.didConfirmNoProductionTruthUpgrade =
            didConfirmNoProductionTruthUpgrade
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didConfirmNoNativeBridgeExpansion =
            didConfirmNoNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didAvoidApprovalRecoveryOrReportWrapper =
            didAvoidApprovalRecoveryOrReportWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceFacts(
    commandPipelineReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceFacts(
        commandPipelineReadiness
            .didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineReadiness,
        commandPipelineReadiness.shouldRequireMetalDeviceBeforeCommandQueue,
        true,
        true,
        commandPipelineReadiness.shouldRequireCommandQueueBeforeCommandBuffer,
        true,
        true,
        true,
        commandPipelineReadiness.shouldKeepCurrentShellCommandPipelineBounded,
        commandPipelineReadiness
            .shouldRequireProductionWriteAdmissionBeforeRendererStateWrite,
        commandPipelineReadiness.shouldKeepRendererStateWriteBlocked,
        commandPipelineReadiness.didConfirmNoProductionTruthUpgrade,
        commandPipelineReadiness.didConfirmNoBackendReadyTruth,
        commandPipelineReadiness.didConfirmNoNativeBridgeExpansion,
        commandPipelineReadiness.didConfirmNoPublicApi,
        commandPipelineReadiness.didConfirmNoProductionPublicCAbi,
        commandPipelineReadiness.didConfirmNoRuntimeStateWrite,
        commandPipelineReadiness.didConfirmNoCjpmTomlChange,
        commandPipelineReadiness.didConfirmNoRendererStateWrite,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceReadiness(
    commandPipelineReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineReadiness,
    firstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceReadiness {
    let firstSliceOrderingReady =
        firstSliceFacts.didRequireMetalDeviceForNativeFirstSlice &&
        firstSliceFacts.didAllowCommandQueueCreateDestroyFirstSlice &&
        firstSliceFacts.didAllowCommandBufferCreateDestroyFirstSlice &&
        firstSliceFacts.didRequireCommandQueueBeforeCommandBuffer
    let firstSliceStopLineReady =
        firstSliceFacts.didKeepEncoderCreationBlocked &&
        firstSliceFacts.didKeepCommitPresentBlocked &&
        firstSliceFacts.didRequireTokenLocalCleanup &&
        firstSliceFacts.didKeepFirstSliceCurrentShellBounded &&
        firstSliceFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite &&
        firstSliceFacts.didKeepRendererStateWriteBlocked &&
        firstSliceFacts.didConfirmNoProductionTruthUpgrade &&
        firstSliceFacts.didConfirmNoBackendReadyTruth &&
        firstSliceFacts.didConfirmNoNativeBridgeExpansion &&
        firstSliceFacts.didConfirmNoPublicApi &&
        firstSliceFacts.didConfirmNoProductionPublicCAbi &&
        firstSliceFacts.didConfirmNoRuntimeStateWrite &&
        firstSliceFacts.didConfirmNoCjpmTomlChange &&
        firstSliceFacts.didConfirmNoRendererStateWrite &&
        firstSliceFacts.didAvoidApprovalRecoveryOrReportWrapper
    let firstSliceReadinessReady =
        firstSliceFacts.didConsumeCommandPipelineReadinessEnvelope &&
        firstSliceOrderingReady &&
        firstSliceStopLineReady

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceReadiness(
        commandPipelineReadiness,
        firstSliceFacts,
        firstSliceReadinessReady,
        firstSliceFacts.didConsumeCommandPipelineReadinessEnvelope,
        firstSliceFacts.didRequireMetalDeviceForNativeFirstSlice,
        firstSliceFacts.didAllowCommandQueueCreateDestroyFirstSlice,
        firstSliceFacts.didAllowCommandBufferCreateDestroyFirstSlice,
        firstSliceFacts.didRequireCommandQueueBeforeCommandBuffer,
        firstSliceFacts.didKeepEncoderCreationBlocked,
        firstSliceFacts.didKeepCommitPresentBlocked,
        firstSliceFacts.didRequireTokenLocalCleanup,
        firstSliceFacts.didKeepFirstSliceCurrentShellBounded,
        firstSliceFacts
            .didRequireProductionWriteAdmissionBeforeRendererStateWrite,
        firstSliceFacts.didKeepRendererStateWriteBlocked,
        firstSliceFacts.didConsumeCommandPipelineReadinessEnvelope,
        firstSliceOrderingReady,
        firstSliceStopLineReady,
        firstSliceFacts.didConfirmNoProductionTruthUpgrade,
        firstSliceFacts.didConfirmNoBackendReadyTruth,
        firstSliceFacts.didConfirmNoNativeBridgeExpansion,
        firstSliceFacts.didConfirmNoPublicApi,
        firstSliceFacts.didConfirmNoProductionPublicCAbi,
        firstSliceFacts.didConfirmNoRuntimeStateWrite,
        firstSliceFacts.didConfirmNoCjpmTomlChange,
        firstSliceFacts.didConfirmNoRendererStateWrite,
        firstSliceFacts.didAvoidApprovalRecoveryOrReportWrapper
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceReadiness {
    let commandPipelineReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineReadinessDraft()
    let firstSliceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceFacts(
            commandPipelineReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandQueueCommandBufferFirstSliceReadiness(
        commandPipelineReadiness,
        firstSliceFacts
    )
}
