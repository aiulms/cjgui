// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application runtime native-readiness explicit approval replay audit owner。
// Owner: runtime renderer internal explicit approval replay audit owner。
// Truth: 只消费 explicit approval rerun contract readiness，把 stage91 regression
// suite packet、handoff packet replay、source/build replay guard 与 focused audit
// suite 固定为 non-D3 可重放证据路线；即使 automation shell Metal-capable，也不执行
// D3 runtime native probe，不创建 singleton，不调用 application accessor，不扩 native
// bridge，不消费 human approval，不升级 production ownership truth。
// Stop-line: 不实现 production singleton owner，不新增 production accessor call site，
// 不调用 application singleton accessor，不创建或激活 NSApplication，不修改 activation
// policy，不运行 AppKit event loop / bounded pump，不执行 cleanup / teardown，不创建
// window / view / layer，不 visible order，不取 drawable，不创建 command queue /
// command buffer / encoder，不 render / commit / present / GPU submission，不发布
// artifact / diagnostics，不返回 native identity，不写 runtime_state.cj，不改
// cjpm.toml，不扩 public API，不新增 production C ABI。
// Same-shape Boundary Brake: 本 owner 必须带 suite packet audit、handoff packet replay、
// source/build replay guard 与 focused replay audit suite 证据路线，不得退化成
// no-accessor / no-bridge / no-runtime-execution 同构 wrapper，也不得包装成
// application-ready、native-probe-ready、backend-ready、renderer state write、receipt、
// record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayAuditFacts {
    let didConsumeExplicitApprovalRerunContractReadiness: Bool
    let didOpenExplicitApprovalReplayAuditRoute: Bool
    let didRequireRegressionSuitePacketAudit: Bool
    let didRequireHandoffReplayContract: Bool
    let didRequireSourceBuildReplayGuard: Bool
    let didRequireFocusedReplayAuditSuite: Bool
    let didRequirePacketPathReachabilityEvidence: Bool
    let didKeepMetalCapabilitySeparateFromD3Approval: Bool
    let didKeepD3RuntimeNativeProbeApprovalExternal: Bool
    let didKeepRuntimeNativeProbeExecutionBlocked: Bool
    let didKeepHumanApprovedD3ExecutionUnconsumed: Bool
    let didKeepCodeFailureDomainFalse: Bool
    let didConfirmNoApplicationAccessorCall: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didAvoidSameShapeNoAccessorWrapper: Bool
    let didKeepExplicitApprovalReplayAuditDehydrated: Bool

    init(
        didConsumeExplicitApprovalRerunContractReadiness: Bool,
        didOpenExplicitApprovalReplayAuditRoute: Bool,
        didRequireRegressionSuitePacketAudit: Bool,
        didRequireHandoffReplayContract: Bool,
        didRequireSourceBuildReplayGuard: Bool,
        didRequireFocusedReplayAuditSuite: Bool,
        didRequirePacketPathReachabilityEvidence: Bool,
        didKeepMetalCapabilitySeparateFromD3Approval: Bool,
        didKeepD3RuntimeNativeProbeApprovalExternal: Bool,
        didKeepRuntimeNativeProbeExecutionBlocked: Bool,
        didKeepHumanApprovedD3ExecutionUnconsumed: Bool,
        didKeepCodeFailureDomainFalse: Bool,
        didConfirmNoApplicationAccessorCall: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didAvoidSameShapeNoAccessorWrapper: Bool,
        didKeepExplicitApprovalReplayAuditDehydrated: Bool
    ) {
        this.didConsumeExplicitApprovalRerunContractReadiness =
            didConsumeExplicitApprovalRerunContractReadiness
        this.didOpenExplicitApprovalReplayAuditRoute =
            didOpenExplicitApprovalReplayAuditRoute
        this.didRequireRegressionSuitePacketAudit =
            didRequireRegressionSuitePacketAudit
        this.didRequireHandoffReplayContract = didRequireHandoffReplayContract
        this.didRequireSourceBuildReplayGuard =
            didRequireSourceBuildReplayGuard
        this.didRequireFocusedReplayAuditSuite =
            didRequireFocusedReplayAuditSuite
        this.didRequirePacketPathReachabilityEvidence =
            didRequirePacketPathReachabilityEvidence
        this.didKeepMetalCapabilitySeparateFromD3Approval =
            didKeepMetalCapabilitySeparateFromD3Approval
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
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didAvoidSameShapeNoAccessorWrapper =
            didAvoidSameShapeNoAccessorWrapper
        this.didKeepExplicitApprovalReplayAuditDehydrated =
            didKeepExplicitApprovalReplayAuditDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayAuditReadiness {
    let explicitApprovalRerunContractReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalRerunContractReadiness
    let explicitApprovalReplayAuditFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayAuditFacts
    let didPrepareRuntimeNativeProbeExplicitApprovalReplayAuditReadiness:
        Bool
    let shouldDeferRuntimeNativeProbeExecutionToExplicitHumanApproval: Bool
    let shouldContinueNonD3ExplicitApprovalReplayAuditRoute: Bool
    let shouldReportRuntimeNativeProbeExplicitApprovalReplayAuditBlocked: Bool
    let didConfirmExplicitApprovalRerunContractInput: Bool
    let didConfirmRegressionSuitePacketAuditRequired: Bool
    let didConfirmHandoffReplayContractRequired: Bool
    let didConfirmSourceBuildReplayGuardRequired: Bool
    let didConfirmFocusedReplayAuditSuiteRequired: Bool
    let didConfirmPacketPathReachabilityEvidenceRequired: Bool
    let didConfirmMetalCapabilitySeparateFromD3Approval: Bool
    let didConfirmD3ApprovalStillExternal: Bool
    let didConfirmRuntimeNativeProbeExecutionStillBlocked: Bool
    let didConfirmHumanApprovedD3ExecutionUnconsumed: Bool
    let didConfirmCodeFailureDomainFalse: Bool
    let didConfirmNoApplicationAccessorCall: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didAvoidSameShapeNoAccessorWrapper: Bool
    let didKeepExplicitApprovalReplayAuditDehydrated: Bool

    init(
        explicitApprovalRerunContractReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalRerunContractReadiness,
        explicitApprovalReplayAuditFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayAuditFacts,
        didPrepareRuntimeNativeProbeExplicitApprovalReplayAuditReadiness:
            Bool,
        shouldDeferRuntimeNativeProbeExecutionToExplicitHumanApproval:
            Bool,
        shouldContinueNonD3ExplicitApprovalReplayAuditRoute: Bool,
        shouldReportRuntimeNativeProbeExplicitApprovalReplayAuditBlocked:
            Bool,
        didConfirmExplicitApprovalRerunContractInput: Bool,
        didConfirmRegressionSuitePacketAuditRequired: Bool,
        didConfirmHandoffReplayContractRequired: Bool,
        didConfirmSourceBuildReplayGuardRequired: Bool,
        didConfirmFocusedReplayAuditSuiteRequired: Bool,
        didConfirmPacketPathReachabilityEvidenceRequired: Bool,
        didConfirmMetalCapabilitySeparateFromD3Approval: Bool,
        didConfirmD3ApprovalStillExternal: Bool,
        didConfirmRuntimeNativeProbeExecutionStillBlocked: Bool,
        didConfirmHumanApprovedD3ExecutionUnconsumed: Bool,
        didConfirmCodeFailureDomainFalse: Bool,
        didConfirmNoApplicationAccessorCall: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didAvoidSameShapeNoAccessorWrapper: Bool,
        didKeepExplicitApprovalReplayAuditDehydrated: Bool
    ) {
        this.explicitApprovalRerunContractReadiness =
            explicitApprovalRerunContractReadiness
        this.explicitApprovalReplayAuditFacts = explicitApprovalReplayAuditFacts
        this.didPrepareRuntimeNativeProbeExplicitApprovalReplayAuditReadiness =
            didPrepareRuntimeNativeProbeExplicitApprovalReplayAuditReadiness
        this.shouldDeferRuntimeNativeProbeExecutionToExplicitHumanApproval =
            shouldDeferRuntimeNativeProbeExecutionToExplicitHumanApproval
        this.shouldContinueNonD3ExplicitApprovalReplayAuditRoute =
            shouldContinueNonD3ExplicitApprovalReplayAuditRoute
        this.shouldReportRuntimeNativeProbeExplicitApprovalReplayAuditBlocked =
            shouldReportRuntimeNativeProbeExplicitApprovalReplayAuditBlocked
        this.didConfirmExplicitApprovalRerunContractInput =
            didConfirmExplicitApprovalRerunContractInput
        this.didConfirmRegressionSuitePacketAuditRequired =
            didConfirmRegressionSuitePacketAuditRequired
        this.didConfirmHandoffReplayContractRequired =
            didConfirmHandoffReplayContractRequired
        this.didConfirmSourceBuildReplayGuardRequired =
            didConfirmSourceBuildReplayGuardRequired
        this.didConfirmFocusedReplayAuditSuiteRequired =
            didConfirmFocusedReplayAuditSuiteRequired
        this.didConfirmPacketPathReachabilityEvidenceRequired =
            didConfirmPacketPathReachabilityEvidenceRequired
        this.didConfirmMetalCapabilitySeparateFromD3Approval =
            didConfirmMetalCapabilitySeparateFromD3Approval
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
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didAvoidSameShapeNoAccessorWrapper =
            didAvoidSameShapeNoAccessorWrapper
        this.didKeepExplicitApprovalReplayAuditDehydrated =
            didKeepExplicitApprovalReplayAuditDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayAuditFacts(
    explicitApprovalRerunContractReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalRerunContractReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayAuditFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayAuditFacts(
        explicitApprovalRerunContractReadiness
            .didPrepareRuntimeNativeProbeExplicitApprovalRerunContractReadiness,
        true,
        true,
        true,
        true,
        true,
        true,
        explicitApprovalRerunContractReadiness
            .didConfirmMetalCapabilitySeparateFromD3Approval,
        explicitApprovalRerunContractReadiness.didConfirmD3ApprovalStillExternal,
        explicitApprovalRerunContractReadiness
            .didConfirmRuntimeNativeProbeExecutionStillBlocked,
        explicitApprovalRerunContractReadiness
            .didConfirmHumanApprovedD3ExecutionUnconsumed,
        explicitApprovalRerunContractReadiness.didConfirmCodeFailureDomainFalse,
        explicitApprovalRerunContractReadiness
            .didConfirmNoApplicationAccessorCall,
        explicitApprovalRerunContractReadiness.didConfirmNoNativeBridgeExpansion,
        explicitApprovalRerunContractReadiness.didConfirmNoPublicApi,
        explicitApprovalRerunContractReadiness.didConfirmNoProductionPublicCAbi,
        explicitApprovalRerunContractReadiness.didConfirmNoRendererStateWrite,
        explicitApprovalRerunContractReadiness.didConfirmNoRuntimeStateWrite,
        explicitApprovalRerunContractReadiness.didConfirmNoCjpmTomlChange,
        explicitApprovalRerunContractReadiness.didAvoidSameShapeNoAccessorWrapper,
        explicitApprovalRerunContractReadiness
            .didKeepExplicitApprovalRerunContractDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayAuditReadiness(
    explicitApprovalRerunContractReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalRerunContractReadiness,
    explicitApprovalReplayAuditFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayAuditFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayAuditReadiness {
    let replayAuditReady =
        explicitApprovalReplayAuditFacts
            .didConsumeExplicitApprovalRerunContractReadiness &&
        explicitApprovalReplayAuditFacts.didOpenExplicitApprovalReplayAuditRoute &&
        explicitApprovalReplayAuditFacts.didRequireRegressionSuitePacketAudit &&
        explicitApprovalReplayAuditFacts.didRequireHandoffReplayContract &&
        explicitApprovalReplayAuditFacts.didRequireSourceBuildReplayGuard &&
        explicitApprovalReplayAuditFacts.didRequireFocusedReplayAuditSuite &&
        explicitApprovalReplayAuditFacts
            .didRequirePacketPathReachabilityEvidence &&
        explicitApprovalReplayAuditFacts
            .didKeepMetalCapabilitySeparateFromD3Approval &&
        explicitApprovalReplayAuditFacts
            .didKeepD3RuntimeNativeProbeApprovalExternal &&
        explicitApprovalReplayAuditFacts
            .didKeepRuntimeNativeProbeExecutionBlocked &&
        explicitApprovalReplayAuditFacts
            .didKeepHumanApprovedD3ExecutionUnconsumed &&
        explicitApprovalReplayAuditFacts.didKeepCodeFailureDomainFalse &&
        explicitApprovalReplayAuditFacts.didConfirmNoApplicationAccessorCall &&
        explicitApprovalReplayAuditFacts.didConfirmNoNativeBridgeExpansion &&
        explicitApprovalReplayAuditFacts.didConfirmNoPublicApi &&
        explicitApprovalReplayAuditFacts.didConfirmNoProductionPublicCAbi &&
        explicitApprovalReplayAuditFacts.didConfirmNoRendererStateWrite &&
        explicitApprovalReplayAuditFacts.didConfirmNoRuntimeStateWrite &&
        explicitApprovalReplayAuditFacts.didConfirmNoCjpmTomlChange &&
        explicitApprovalReplayAuditFacts.didAvoidSameShapeNoAccessorWrapper &&
        explicitApprovalReplayAuditFacts
            .didKeepExplicitApprovalReplayAuditDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayAuditReadiness(
        explicitApprovalRerunContractReadiness,
        explicitApprovalReplayAuditFacts,
        replayAuditReady,
        true,
        replayAuditReady,
        !replayAuditReady,
        explicitApprovalReplayAuditFacts
            .didConsumeExplicitApprovalRerunContractReadiness,
        explicitApprovalReplayAuditFacts.didRequireRegressionSuitePacketAudit,
        explicitApprovalReplayAuditFacts.didRequireHandoffReplayContract,
        explicitApprovalReplayAuditFacts.didRequireSourceBuildReplayGuard,
        explicitApprovalReplayAuditFacts.didRequireFocusedReplayAuditSuite,
        explicitApprovalReplayAuditFacts.didRequirePacketPathReachabilityEvidence,
        explicitApprovalReplayAuditFacts
            .didKeepMetalCapabilitySeparateFromD3Approval,
        explicitApprovalReplayAuditFacts
            .didKeepD3RuntimeNativeProbeApprovalExternal,
        explicitApprovalReplayAuditFacts
            .didKeepRuntimeNativeProbeExecutionBlocked,
        explicitApprovalReplayAuditFacts
            .didKeepHumanApprovedD3ExecutionUnconsumed,
        explicitApprovalReplayAuditFacts.didKeepCodeFailureDomainFalse,
        explicitApprovalReplayAuditFacts.didConfirmNoApplicationAccessorCall,
        explicitApprovalReplayAuditFacts.didConfirmNoNativeBridgeExpansion,
        explicitApprovalReplayAuditFacts.didConfirmNoPublicApi,
        explicitApprovalReplayAuditFacts.didConfirmNoProductionPublicCAbi,
        explicitApprovalReplayAuditFacts.didConfirmNoRendererStateWrite,
        explicitApprovalReplayAuditFacts.didConfirmNoRuntimeStateWrite,
        explicitApprovalReplayAuditFacts.didConfirmNoCjpmTomlChange,
        explicitApprovalReplayAuditFacts.didAvoidSameShapeNoAccessorWrapper,
        explicitApprovalReplayAuditFacts
            .didKeepExplicitApprovalReplayAuditDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayAuditDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayAuditReadiness {
    let explicitApprovalRerunContractReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalRerunContractDraft()
    let explicitApprovalReplayAuditFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayAuditFacts(
            explicitApprovalRerunContractReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayAuditReadiness(
        explicitApprovalRerunContractReadiness,
        explicitApprovalReplayAuditFacts
    )
}
