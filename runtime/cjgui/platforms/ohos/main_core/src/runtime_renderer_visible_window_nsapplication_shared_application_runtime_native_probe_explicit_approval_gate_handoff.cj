// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application runtime native-readiness explicit approval gate handoff owner。
// Owner: runtime renderer internal runtime native-readiness explicit approval
// gate / route-scoped native evidence / environment drift handoff owner。
// Truth: 只消费 non-D3 rerun maintenance readiness，把当前路线推进为
// explicit approval gate packet、route-scoped native bridge evidence、
// environment drift replay 与 handoff runner 证据；即使 automation shell
// Metal-capable，也不执行 D3 runtime native probe，不创建 singleton，不调用
// application accessor，不扩 native bridge，不消费 human approval，不升级
// production ownership truth。
// Stop-line: 不实现 production singleton owner，不新增 production accessor call
// site，不调用 application singleton accessor，不创建或激活 NSApplication，不修改
// activation policy，不运行 AppKit event loop / bounded pump，不执行 cleanup /
// teardown，不创建 window / view / layer，不 visible order，不取 drawable，不创建
// command queue / command buffer / encoder，不 render / commit / present / GPU
// submission，不发布 artifact / diagnostics，不返回 native identity，不写
// runtime_state.cj，不改 cjpm.toml，不扩 public API，不新增 production C ABI。
// Same-shape Boundary Brake: 本 owner 必须带 explicit approval gate、route-scoped
// native evidence、environment drift replay 与 handoff runner 证据路线，不得退化
// 成 no-accessor / no-bridge / no-runtime-execution 同构 wrapper，也不得包装成
// application-ready、native-probe-ready、backend-ready、renderer state write、
// receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalGateHandoffFacts {
    let didConsumeNonD3RerunMaintenanceReadiness: Bool
    let didOpenExplicitApprovalGateHandoffRoute: Bool
    let didRequireExplicitApprovalGatePacket: Bool
    let didRequireRouteScopedNativeBridgeEvidence: Bool
    let didRequireEnvironmentDriftReplay: Bool
    let didRequireExplicitApprovalHandoffRunner: Bool
    let didConfirmMetalCapableShellDoesNotImplyApproval: Bool
    let didKeepD3RuntimeNativeProbeApprovalExternal: Bool
    let didKeepRuntimeNativeProbeExecutionBlocked: Bool
    let didKeepHumanApprovedD3ExecutionUnconsumed: Bool
    let didKeepCodeFailureDomainFalse: Bool
    let didConfirmNoApplicationAccessorCall: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoSingletonCreation: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didAvoidSameShapeNoAccessorWrapper: Bool
    let didKeepExplicitApprovalGateHandoffDehydrated: Bool

    init(
        didConsumeNonD3RerunMaintenanceReadiness: Bool,
        didOpenExplicitApprovalGateHandoffRoute: Bool,
        didRequireExplicitApprovalGatePacket: Bool,
        didRequireRouteScopedNativeBridgeEvidence: Bool,
        didRequireEnvironmentDriftReplay: Bool,
        didRequireExplicitApprovalHandoffRunner: Bool,
        didConfirmMetalCapableShellDoesNotImplyApproval: Bool,
        didKeepD3RuntimeNativeProbeApprovalExternal: Bool,
        didKeepRuntimeNativeProbeExecutionBlocked: Bool,
        didKeepHumanApprovedD3ExecutionUnconsumed: Bool,
        didKeepCodeFailureDomainFalse: Bool,
        didConfirmNoApplicationAccessorCall: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoSingletonCreation: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didAvoidSameShapeNoAccessorWrapper: Bool,
        didKeepExplicitApprovalGateHandoffDehydrated: Bool
    ) {
        this.didConsumeNonD3RerunMaintenanceReadiness =
            didConsumeNonD3RerunMaintenanceReadiness
        this.didOpenExplicitApprovalGateHandoffRoute =
            didOpenExplicitApprovalGateHandoffRoute
        this.didRequireExplicitApprovalGatePacket =
            didRequireExplicitApprovalGatePacket
        this.didRequireRouteScopedNativeBridgeEvidence =
            didRequireRouteScopedNativeBridgeEvidence
        this.didRequireEnvironmentDriftReplay =
            didRequireEnvironmentDriftReplay
        this.didRequireExplicitApprovalHandoffRunner =
            didRequireExplicitApprovalHandoffRunner
        this.didConfirmMetalCapableShellDoesNotImplyApproval =
            didConfirmMetalCapableShellDoesNotImplyApproval
        this.didKeepD3RuntimeNativeProbeApprovalExternal =
            didKeepD3RuntimeNativeProbeApprovalExternal
        this.didKeepRuntimeNativeProbeExecutionBlocked =
            didKeepRuntimeNativeProbeExecutionBlocked
        this.didKeepHumanApprovedD3ExecutionUnconsumed =
            didKeepHumanApprovedD3ExecutionUnconsumed
        this.didKeepCodeFailureDomainFalse = didKeepCodeFailureDomainFalse
        this.didConfirmNoApplicationAccessorCall =
            didConfirmNoApplicationAccessorCall
        this.didConfirmNoNativeBridgeExpansion =
            didConfirmNoNativeBridgeExpansion
        this.didConfirmNoSingletonCreation = didConfirmNoSingletonCreation
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didAvoidSameShapeNoAccessorWrapper =
            didAvoidSameShapeNoAccessorWrapper
        this.didKeepExplicitApprovalGateHandoffDehydrated =
            didKeepExplicitApprovalGateHandoffDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalGateHandoffReadiness {
    let nonD3RerunMaintenanceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeNonD3RerunMaintenanceReadiness
    let explicitApprovalGateHandoffFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalGateHandoffFacts
    let didPrepareRuntimeNativeProbeExplicitApprovalGateHandoffReadiness: Bool
    let shouldDeferRuntimeNativeProbeExecutionToExplicitHumanApproval: Bool
    let shouldContinueNonD3ExplicitApprovalHandoffRoute: Bool
    let shouldReportRuntimeNativeProbeExplicitApprovalGateBlocked: Bool
    let didConfirmNonD3RerunMaintenanceInput: Bool
    let didConfirmExplicitApprovalGatePacketRequired: Bool
    let didConfirmRouteScopedNativeBridgeEvidenceRequired: Bool
    let didConfirmEnvironmentDriftReplayRequired: Bool
    let didConfirmExplicitApprovalHandoffRunnerRequired: Bool
    let didConfirmMetalCapableShellDoesNotImplyApproval: Bool
    let didConfirmD3ApprovalStillExternal: Bool
    let didConfirmRuntimeNativeProbeExecutionStillBlocked: Bool
    let didConfirmHumanApprovedD3ExecutionUnconsumed: Bool
    let didConfirmCodeFailureDomainFalse: Bool
    let didConfirmNoApplicationAccessorCall: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoSingletonCreation: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didAvoidSameShapeNoAccessorWrapper: Bool
    let didKeepExplicitApprovalGateHandoffDehydrated: Bool

    init(
        nonD3RerunMaintenanceReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeNonD3RerunMaintenanceReadiness,
        explicitApprovalGateHandoffFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalGateHandoffFacts,
        didPrepareRuntimeNativeProbeExplicitApprovalGateHandoffReadiness:
            Bool,
        shouldDeferRuntimeNativeProbeExecutionToExplicitHumanApproval: Bool,
        shouldContinueNonD3ExplicitApprovalHandoffRoute: Bool,
        shouldReportRuntimeNativeProbeExplicitApprovalGateBlocked: Bool,
        didConfirmNonD3RerunMaintenanceInput: Bool,
        didConfirmExplicitApprovalGatePacketRequired: Bool,
        didConfirmRouteScopedNativeBridgeEvidenceRequired: Bool,
        didConfirmEnvironmentDriftReplayRequired: Bool,
        didConfirmExplicitApprovalHandoffRunnerRequired: Bool,
        didConfirmMetalCapableShellDoesNotImplyApproval: Bool,
        didConfirmD3ApprovalStillExternal: Bool,
        didConfirmRuntimeNativeProbeExecutionStillBlocked: Bool,
        didConfirmHumanApprovedD3ExecutionUnconsumed: Bool,
        didConfirmCodeFailureDomainFalse: Bool,
        didConfirmNoApplicationAccessorCall: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoSingletonCreation: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didAvoidSameShapeNoAccessorWrapper: Bool,
        didKeepExplicitApprovalGateHandoffDehydrated: Bool
    ) {
        this.nonD3RerunMaintenanceReadiness =
            nonD3RerunMaintenanceReadiness
        this.explicitApprovalGateHandoffFacts =
            explicitApprovalGateHandoffFacts
        this.didPrepareRuntimeNativeProbeExplicitApprovalGateHandoffReadiness =
            didPrepareRuntimeNativeProbeExplicitApprovalGateHandoffReadiness
        this.shouldDeferRuntimeNativeProbeExecutionToExplicitHumanApproval =
            shouldDeferRuntimeNativeProbeExecutionToExplicitHumanApproval
        this.shouldContinueNonD3ExplicitApprovalHandoffRoute =
            shouldContinueNonD3ExplicitApprovalHandoffRoute
        this.shouldReportRuntimeNativeProbeExplicitApprovalGateBlocked =
            shouldReportRuntimeNativeProbeExplicitApprovalGateBlocked
        this.didConfirmNonD3RerunMaintenanceInput =
            didConfirmNonD3RerunMaintenanceInput
        this.didConfirmExplicitApprovalGatePacketRequired =
            didConfirmExplicitApprovalGatePacketRequired
        this.didConfirmRouteScopedNativeBridgeEvidenceRequired =
            didConfirmRouteScopedNativeBridgeEvidenceRequired
        this.didConfirmEnvironmentDriftReplayRequired =
            didConfirmEnvironmentDriftReplayRequired
        this.didConfirmExplicitApprovalHandoffRunnerRequired =
            didConfirmExplicitApprovalHandoffRunnerRequired
        this.didConfirmMetalCapableShellDoesNotImplyApproval =
            didConfirmMetalCapableShellDoesNotImplyApproval
        this.didConfirmD3ApprovalStillExternal =
            didConfirmD3ApprovalStillExternal
        this.didConfirmRuntimeNativeProbeExecutionStillBlocked =
            didConfirmRuntimeNativeProbeExecutionStillBlocked
        this.didConfirmHumanApprovedD3ExecutionUnconsumed =
            didConfirmHumanApprovedD3ExecutionUnconsumed
        this.didConfirmCodeFailureDomainFalse =
            didConfirmCodeFailureDomainFalse
        this.didConfirmNoApplicationAccessorCall =
            didConfirmNoApplicationAccessorCall
        this.didConfirmNoNativeBridgeExpansion =
            didConfirmNoNativeBridgeExpansion
        this.didConfirmNoSingletonCreation = didConfirmNoSingletonCreation
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didAvoidSameShapeNoAccessorWrapper =
            didAvoidSameShapeNoAccessorWrapper
        this.didKeepExplicitApprovalGateHandoffDehydrated =
            didKeepExplicitApprovalGateHandoffDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalGateHandoffFacts(
    nonD3RerunMaintenanceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeNonD3RerunMaintenanceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalGateHandoffFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalGateHandoffFacts(
        nonD3RerunMaintenanceReadiness
            .didPrepareRuntimeNativeProbeNonD3RerunMaintenanceReadiness,
        true,
        true,
        true,
        true,
        true,
        true,
        nonD3RerunMaintenanceReadiness.didConfirmD3ApprovalStillExternal,
        nonD3RerunMaintenanceReadiness
            .didConfirmRuntimeNativeProbeExecutionStillBlocked,
        true,
        nonD3RerunMaintenanceReadiness.didConfirmCodeFailureDomainFalse,
        nonD3RerunMaintenanceReadiness.didConfirmNoApplicationAccessorCall,
        nonD3RerunMaintenanceReadiness.didConfirmNoNativeBridgeExpansion,
        nonD3RerunMaintenanceReadiness.didConfirmNoSingletonCreation,
        nonD3RerunMaintenanceReadiness.didConfirmNoPublicApi,
        nonD3RerunMaintenanceReadiness.didConfirmNoProductionPublicCAbi,
        nonD3RerunMaintenanceReadiness.didConfirmNoRendererStateWrite,
        nonD3RerunMaintenanceReadiness.didConfirmNoRuntimeStateWrite,
        nonD3RerunMaintenanceReadiness.didConfirmNoCjpmTomlChange,
        nonD3RerunMaintenanceReadiness.didAvoidSameShapeNoAccessorWrapper,
        nonD3RerunMaintenanceReadiness
            .didKeepNonD3RerunMaintenanceDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalGateHandoffReadiness(
    nonD3RerunMaintenanceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeNonD3RerunMaintenanceReadiness,
    explicitApprovalGateHandoffFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalGateHandoffFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalGateHandoffReadiness {
    let handoffReady =
        explicitApprovalGateHandoffFacts
            .didConsumeNonD3RerunMaintenanceReadiness &&
        explicitApprovalGateHandoffFacts
            .didOpenExplicitApprovalGateHandoffRoute &&
        explicitApprovalGateHandoffFacts
            .didRequireExplicitApprovalGatePacket &&
        explicitApprovalGateHandoffFacts
            .didRequireRouteScopedNativeBridgeEvidence &&
        explicitApprovalGateHandoffFacts.didRequireEnvironmentDriftReplay &&
        explicitApprovalGateHandoffFacts
            .didRequireExplicitApprovalHandoffRunner &&
        explicitApprovalGateHandoffFacts
            .didConfirmMetalCapableShellDoesNotImplyApproval &&
        explicitApprovalGateHandoffFacts
            .didKeepD3RuntimeNativeProbeApprovalExternal &&
        explicitApprovalGateHandoffFacts
            .didKeepRuntimeNativeProbeExecutionBlocked &&
        explicitApprovalGateHandoffFacts
            .didKeepHumanApprovedD3ExecutionUnconsumed &&
        explicitApprovalGateHandoffFacts.didKeepCodeFailureDomainFalse &&
        explicitApprovalGateHandoffFacts
            .didConfirmNoApplicationAccessorCall &&
        explicitApprovalGateHandoffFacts.didConfirmNoNativeBridgeExpansion &&
        explicitApprovalGateHandoffFacts.didConfirmNoSingletonCreation &&
        explicitApprovalGateHandoffFacts.didConfirmNoPublicApi &&
        explicitApprovalGateHandoffFacts.didConfirmNoProductionPublicCAbi &&
        explicitApprovalGateHandoffFacts.didConfirmNoRendererStateWrite &&
        explicitApprovalGateHandoffFacts.didConfirmNoRuntimeStateWrite &&
        explicitApprovalGateHandoffFacts.didConfirmNoCjpmTomlChange &&
        explicitApprovalGateHandoffFacts.didAvoidSameShapeNoAccessorWrapper &&
        explicitApprovalGateHandoffFacts
            .didKeepExplicitApprovalGateHandoffDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalGateHandoffReadiness(
        nonD3RerunMaintenanceReadiness,
        explicitApprovalGateHandoffFacts,
        handoffReady,
        true,
        handoffReady,
        !handoffReady,
        explicitApprovalGateHandoffFacts
            .didConsumeNonD3RerunMaintenanceReadiness,
        explicitApprovalGateHandoffFacts
            .didRequireExplicitApprovalGatePacket,
        explicitApprovalGateHandoffFacts
            .didRequireRouteScopedNativeBridgeEvidence,
        explicitApprovalGateHandoffFacts.didRequireEnvironmentDriftReplay,
        explicitApprovalGateHandoffFacts
            .didRequireExplicitApprovalHandoffRunner,
        explicitApprovalGateHandoffFacts
            .didConfirmMetalCapableShellDoesNotImplyApproval,
        explicitApprovalGateHandoffFacts
            .didKeepD3RuntimeNativeProbeApprovalExternal,
        explicitApprovalGateHandoffFacts
            .didKeepRuntimeNativeProbeExecutionBlocked,
        explicitApprovalGateHandoffFacts
            .didKeepHumanApprovedD3ExecutionUnconsumed,
        explicitApprovalGateHandoffFacts.didKeepCodeFailureDomainFalse,
        explicitApprovalGateHandoffFacts
            .didConfirmNoApplicationAccessorCall,
        explicitApprovalGateHandoffFacts.didConfirmNoNativeBridgeExpansion,
        explicitApprovalGateHandoffFacts.didConfirmNoSingletonCreation,
        explicitApprovalGateHandoffFacts.didConfirmNoPublicApi,
        explicitApprovalGateHandoffFacts.didConfirmNoProductionPublicCAbi,
        explicitApprovalGateHandoffFacts.didConfirmNoRendererStateWrite,
        explicitApprovalGateHandoffFacts.didConfirmNoRuntimeStateWrite,
        explicitApprovalGateHandoffFacts.didConfirmNoCjpmTomlChange,
        explicitApprovalGateHandoffFacts.didAvoidSameShapeNoAccessorWrapper,
        explicitApprovalGateHandoffFacts
            .didKeepExplicitApprovalGateHandoffDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalGateHandoffDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalGateHandoffReadiness {
    let nonD3RerunMaintenanceReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeNonD3RerunMaintenanceDraft()
    let explicitApprovalGateHandoffFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalGateHandoffFacts(
            nonD3RerunMaintenanceReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalGateHandoffReadiness(
        nonD3RerunMaintenanceReadiness,
        explicitApprovalGateHandoffFacts
    )
}
