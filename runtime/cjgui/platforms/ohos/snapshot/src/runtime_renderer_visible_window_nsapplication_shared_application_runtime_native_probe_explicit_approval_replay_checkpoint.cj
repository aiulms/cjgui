// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application runtime native-readiness explicit approval replay checkpoint owner。
// Owner: runtime renderer internal explicit approval replay checkpoint owner。
// Truth: 只消费 explicit approval replay audit readiness，把 replay audit suite packet、
// checkpoint packet reuse、failure-domain classifier、source/build checkpoint guard 与
// focused checkpoint suite 固定为 non-D3 可重放检查点；即使 automation shell
// Metal-capable，也不执行 D3 runtime native probe，不创建 singleton，不调用
// application accessor，不扩 native bridge，不消费 human approval，不升级 production
// ownership truth。
// Stop-line: 不实现 production singleton owner，不新增 production accessor call site，
// 不调用 application singleton accessor，不创建或激活 NSApplication，不修改 activation
// policy，不运行 AppKit event loop / bounded pump，不执行 cleanup / teardown，不创建
// window / view / layer，不 visible order，不取 drawable，不创建 command queue /
// command buffer / encoder，不 render / commit / present / GPU submission，不发布
// artifact / diagnostics，不返回 native identity，不写 runtime_state.cj，不改
// cjpm.toml，不扩 public API，不新增 production C ABI。
// Same-shape Boundary Brake: 本 owner 必须带 checkpoint packet reuse、
// failure-domain classifier、source/build checkpoint guard 与 focused checkpoint suite
// 证据路线，不得退化成 no-accessor / no-bridge / no-runtime-execution 同构 wrapper，
// 也不得包装成 application-ready、native-probe-ready、backend-ready、renderer state
// write、receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayCheckpointFacts {
    let didConsumeExplicitApprovalReplayAuditReadiness: Bool
    let didOpenExplicitApprovalReplayCheckpointRoute: Bool
    let didRequireReplayAuditSuitePacket: Bool
    let didRequireCheckpointPacketReuseContract: Bool
    let didRequireFailureDomainClassifier: Bool
    let didRequireSourceBuildCheckpointGuard: Bool
    let didRequireFocusedCheckpointSuite: Bool
    let didRequireBoundedRerunDefault: Bool
    let didKeepDeepReplayExplicitPacketOnly: Bool
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
    let didKeepExplicitApprovalReplayCheckpointDehydrated: Bool

    init(
        didConsumeExplicitApprovalReplayAuditReadiness: Bool,
        didOpenExplicitApprovalReplayCheckpointRoute: Bool,
        didRequireReplayAuditSuitePacket: Bool,
        didRequireCheckpointPacketReuseContract: Bool,
        didRequireFailureDomainClassifier: Bool,
        didRequireSourceBuildCheckpointGuard: Bool,
        didRequireFocusedCheckpointSuite: Bool,
        didRequireBoundedRerunDefault: Bool,
        didKeepDeepReplayExplicitPacketOnly: Bool,
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
        didKeepExplicitApprovalReplayCheckpointDehydrated: Bool
    ) {
        this.didConsumeExplicitApprovalReplayAuditReadiness =
            didConsumeExplicitApprovalReplayAuditReadiness
        this.didOpenExplicitApprovalReplayCheckpointRoute =
            didOpenExplicitApprovalReplayCheckpointRoute
        this.didRequireReplayAuditSuitePacket =
            didRequireReplayAuditSuitePacket
        this.didRequireCheckpointPacketReuseContract =
            didRequireCheckpointPacketReuseContract
        this.didRequireFailureDomainClassifier =
            didRequireFailureDomainClassifier
        this.didRequireSourceBuildCheckpointGuard =
            didRequireSourceBuildCheckpointGuard
        this.didRequireFocusedCheckpointSuite =
            didRequireFocusedCheckpointSuite
        this.didRequireBoundedRerunDefault = didRequireBoundedRerunDefault
        this.didKeepDeepReplayExplicitPacketOnly =
            didKeepDeepReplayExplicitPacketOnly
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
        this.didKeepExplicitApprovalReplayCheckpointDehydrated =
            didKeepExplicitApprovalReplayCheckpointDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayCheckpointReadiness {
    let explicitApprovalReplayAuditReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayAuditReadiness
    let explicitApprovalReplayCheckpointFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayCheckpointFacts
    let didPrepareRuntimeNativeProbeExplicitApprovalReplayCheckpointReadiness:
        Bool
    let shouldDeferRuntimeNativeProbeExecutionToExplicitHumanApproval: Bool
    let shouldContinueNonD3ExplicitApprovalReplayCheckpointRoute: Bool
    let shouldReportRuntimeNativeProbeExplicitApprovalReplayCheckpointBlocked:
        Bool
    let didConfirmExplicitApprovalReplayAuditInput: Bool
    let didConfirmReplayAuditSuitePacketRequired: Bool
    let didConfirmCheckpointPacketReuseContractRequired: Bool
    let didConfirmFailureDomainClassifierRequired: Bool
    let didConfirmSourceBuildCheckpointGuardRequired: Bool
    let didConfirmFocusedCheckpointSuiteRequired: Bool
    let didConfirmBoundedRerunDefaultRequired: Bool
    let didConfirmDeepReplayExplicitPacketOnly: Bool
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
    let didKeepExplicitApprovalReplayCheckpointDehydrated: Bool

    init(
        explicitApprovalReplayAuditReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayAuditReadiness,
        explicitApprovalReplayCheckpointFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayCheckpointFacts,
        didPrepareRuntimeNativeProbeExplicitApprovalReplayCheckpointReadiness:
            Bool,
        shouldDeferRuntimeNativeProbeExecutionToExplicitHumanApproval:
            Bool,
        shouldContinueNonD3ExplicitApprovalReplayCheckpointRoute: Bool,
        shouldReportRuntimeNativeProbeExplicitApprovalReplayCheckpointBlocked:
            Bool,
        didConfirmExplicitApprovalReplayAuditInput: Bool,
        didConfirmReplayAuditSuitePacketRequired: Bool,
        didConfirmCheckpointPacketReuseContractRequired: Bool,
        didConfirmFailureDomainClassifierRequired: Bool,
        didConfirmSourceBuildCheckpointGuardRequired: Bool,
        didConfirmFocusedCheckpointSuiteRequired: Bool,
        didConfirmBoundedRerunDefaultRequired: Bool,
        didConfirmDeepReplayExplicitPacketOnly: Bool,
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
        didKeepExplicitApprovalReplayCheckpointDehydrated: Bool
    ) {
        this.explicitApprovalReplayAuditReadiness =
            explicitApprovalReplayAuditReadiness
        this.explicitApprovalReplayCheckpointFacts =
            explicitApprovalReplayCheckpointFacts
        this.didPrepareRuntimeNativeProbeExplicitApprovalReplayCheckpointReadiness =
            didPrepareRuntimeNativeProbeExplicitApprovalReplayCheckpointReadiness
        this.shouldDeferRuntimeNativeProbeExecutionToExplicitHumanApproval =
            shouldDeferRuntimeNativeProbeExecutionToExplicitHumanApproval
        this.shouldContinueNonD3ExplicitApprovalReplayCheckpointRoute =
            shouldContinueNonD3ExplicitApprovalReplayCheckpointRoute
        this.shouldReportRuntimeNativeProbeExplicitApprovalReplayCheckpointBlocked =
            shouldReportRuntimeNativeProbeExplicitApprovalReplayCheckpointBlocked
        this.didConfirmExplicitApprovalReplayAuditInput =
            didConfirmExplicitApprovalReplayAuditInput
        this.didConfirmReplayAuditSuitePacketRequired =
            didConfirmReplayAuditSuitePacketRequired
        this.didConfirmCheckpointPacketReuseContractRequired =
            didConfirmCheckpointPacketReuseContractRequired
        this.didConfirmFailureDomainClassifierRequired =
            didConfirmFailureDomainClassifierRequired
        this.didConfirmSourceBuildCheckpointGuardRequired =
            didConfirmSourceBuildCheckpointGuardRequired
        this.didConfirmFocusedCheckpointSuiteRequired =
            didConfirmFocusedCheckpointSuiteRequired
        this.didConfirmBoundedRerunDefaultRequired =
            didConfirmBoundedRerunDefaultRequired
        this.didConfirmDeepReplayExplicitPacketOnly =
            didConfirmDeepReplayExplicitPacketOnly
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
        this.didKeepExplicitApprovalReplayCheckpointDehydrated =
            didKeepExplicitApprovalReplayCheckpointDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayCheckpointFacts(
    explicitApprovalReplayAuditReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayAuditReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayCheckpointFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayCheckpointFacts(
        explicitApprovalReplayAuditReadiness
            .didPrepareRuntimeNativeProbeExplicitApprovalReplayAuditReadiness,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        explicitApprovalReplayAuditReadiness
            .didConfirmMetalCapabilitySeparateFromD3Approval,
        explicitApprovalReplayAuditReadiness.didConfirmD3ApprovalStillExternal,
        explicitApprovalReplayAuditReadiness
            .didConfirmRuntimeNativeProbeExecutionStillBlocked,
        explicitApprovalReplayAuditReadiness
            .didConfirmHumanApprovedD3ExecutionUnconsumed,
        explicitApprovalReplayAuditReadiness.didConfirmCodeFailureDomainFalse,
        explicitApprovalReplayAuditReadiness
            .didConfirmNoApplicationAccessorCall,
        explicitApprovalReplayAuditReadiness.didConfirmNoNativeBridgeExpansion,
        explicitApprovalReplayAuditReadiness.didConfirmNoPublicApi,
        explicitApprovalReplayAuditReadiness.didConfirmNoProductionPublicCAbi,
        explicitApprovalReplayAuditReadiness.didConfirmNoRendererStateWrite,
        explicitApprovalReplayAuditReadiness.didConfirmNoRuntimeStateWrite,
        explicitApprovalReplayAuditReadiness.didConfirmNoCjpmTomlChange,
        explicitApprovalReplayAuditReadiness.didAvoidSameShapeNoAccessorWrapper,
        explicitApprovalReplayAuditReadiness
            .didKeepExplicitApprovalReplayAuditDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayCheckpointReadiness(
    explicitApprovalReplayAuditReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayAuditReadiness,
    explicitApprovalReplayCheckpointFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayCheckpointFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayCheckpointReadiness {
    let replayCheckpointReady =
        explicitApprovalReplayCheckpointFacts
            .didConsumeExplicitApprovalReplayAuditReadiness &&
        explicitApprovalReplayCheckpointFacts
            .didOpenExplicitApprovalReplayCheckpointRoute &&
        explicitApprovalReplayCheckpointFacts.didRequireReplayAuditSuitePacket &&
        explicitApprovalReplayCheckpointFacts
            .didRequireCheckpointPacketReuseContract &&
        explicitApprovalReplayCheckpointFacts.didRequireFailureDomainClassifier &&
        explicitApprovalReplayCheckpointFacts
            .didRequireSourceBuildCheckpointGuard &&
        explicitApprovalReplayCheckpointFacts.didRequireFocusedCheckpointSuite &&
        explicitApprovalReplayCheckpointFacts.didRequireBoundedRerunDefault &&
        explicitApprovalReplayCheckpointFacts
            .didKeepDeepReplayExplicitPacketOnly &&
        explicitApprovalReplayCheckpointFacts
            .didKeepMetalCapabilitySeparateFromD3Approval &&
        explicitApprovalReplayCheckpointFacts
            .didKeepD3RuntimeNativeProbeApprovalExternal &&
        explicitApprovalReplayCheckpointFacts
            .didKeepRuntimeNativeProbeExecutionBlocked &&
        explicitApprovalReplayCheckpointFacts
            .didKeepHumanApprovedD3ExecutionUnconsumed &&
        explicitApprovalReplayCheckpointFacts.didKeepCodeFailureDomainFalse &&
        explicitApprovalReplayCheckpointFacts
            .didConfirmNoApplicationAccessorCall &&
        explicitApprovalReplayCheckpointFacts.didConfirmNoNativeBridgeExpansion &&
        explicitApprovalReplayCheckpointFacts.didConfirmNoPublicApi &&
        explicitApprovalReplayCheckpointFacts.didConfirmNoProductionPublicCAbi &&
        explicitApprovalReplayCheckpointFacts.didConfirmNoRendererStateWrite &&
        explicitApprovalReplayCheckpointFacts.didConfirmNoRuntimeStateWrite &&
        explicitApprovalReplayCheckpointFacts.didConfirmNoCjpmTomlChange &&
        explicitApprovalReplayCheckpointFacts.didAvoidSameShapeNoAccessorWrapper &&
        explicitApprovalReplayCheckpointFacts
            .didKeepExplicitApprovalReplayCheckpointDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayCheckpointReadiness(
        explicitApprovalReplayAuditReadiness,
        explicitApprovalReplayCheckpointFacts,
        replayCheckpointReady,
        true,
        replayCheckpointReady,
        !replayCheckpointReady,
        explicitApprovalReplayCheckpointFacts
            .didConsumeExplicitApprovalReplayAuditReadiness,
        explicitApprovalReplayCheckpointFacts.didRequireReplayAuditSuitePacket,
        explicitApprovalReplayCheckpointFacts
            .didRequireCheckpointPacketReuseContract,
        explicitApprovalReplayCheckpointFacts.didRequireFailureDomainClassifier,
        explicitApprovalReplayCheckpointFacts
            .didRequireSourceBuildCheckpointGuard,
        explicitApprovalReplayCheckpointFacts.didRequireFocusedCheckpointSuite,
        explicitApprovalReplayCheckpointFacts.didRequireBoundedRerunDefault,
        explicitApprovalReplayCheckpointFacts
            .didKeepDeepReplayExplicitPacketOnly,
        explicitApprovalReplayCheckpointFacts
            .didKeepMetalCapabilitySeparateFromD3Approval,
        explicitApprovalReplayCheckpointFacts
            .didKeepD3RuntimeNativeProbeApprovalExternal,
        explicitApprovalReplayCheckpointFacts
            .didKeepRuntimeNativeProbeExecutionBlocked,
        explicitApprovalReplayCheckpointFacts
            .didKeepHumanApprovedD3ExecutionUnconsumed,
        explicitApprovalReplayCheckpointFacts.didKeepCodeFailureDomainFalse,
        explicitApprovalReplayCheckpointFacts
            .didConfirmNoApplicationAccessorCall,
        explicitApprovalReplayCheckpointFacts.didConfirmNoNativeBridgeExpansion,
        explicitApprovalReplayCheckpointFacts.didConfirmNoPublicApi,
        explicitApprovalReplayCheckpointFacts.didConfirmNoProductionPublicCAbi,
        explicitApprovalReplayCheckpointFacts.didConfirmNoRendererStateWrite,
        explicitApprovalReplayCheckpointFacts.didConfirmNoRuntimeStateWrite,
        explicitApprovalReplayCheckpointFacts.didConfirmNoCjpmTomlChange,
        explicitApprovalReplayCheckpointFacts.didAvoidSameShapeNoAccessorWrapper,
        explicitApprovalReplayCheckpointFacts
            .didKeepExplicitApprovalReplayCheckpointDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayCheckpointDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayCheckpointReadiness {
    let explicitApprovalReplayAuditReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayAuditDraft()
    let explicitApprovalReplayCheckpointFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayCheckpointFacts(
            explicitApprovalReplayAuditReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayCheckpointReadiness(
        explicitApprovalReplayAuditReadiness,
        explicitApprovalReplayCheckpointFacts
    )
}
