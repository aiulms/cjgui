// 中文维护注释：本文件是 visible-window production harness NSApplication
// application-singleton CJGUI-owned lifecycle preflight owner。
// Owner: runtime renderer internal CJGUI-owned application lifecycle planning
// readiness owner。
// Truth: 只消费 source witness recovery false-branch downstream readiness 与
// route C hosted / owned 双模式选择，把 hosted mode 标记为 evidence absent /
// unavailable，并把 owned mode 标记为当前 recovery route；不把 hosted witness、
// source readiness、isolated probe 或 owned planning readiness 升级成 production
// singleton ownership truth。
// Stop-line: 不实现 production singleton owner，不新增 production accessor call
// site，不调用 application singleton accessor，不创建或激活 NSApplication，不修改
// activation policy，不运行 AppKit event loop / bounded pump，不执行 cleanup /
// teardown，不创建 window / view / layer，不 visible order，不取 drawable，不创建
// command queue / command buffer / encoder，不 render / commit / present / GPU
// submission，不发布 artifact / diagnostics，不返回 native identity，不写
// runtime_state.cj，不改 cjpm.toml，不扩 public API，不新增 production C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、
// accessor-ready、singleton-owner-ready、hosted-owner-ready、source-ready、
// visible-ready、drawable-ready、render-ready、backend-ready、renderer state
// write、receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightFacts {
    let didConsumeExternalWitnessRecoveryFalseBranchDownstream: Bool
    let didConsumeRouteCHostedOwnedDualModeSelection: Bool
    let didMarkHostedModeExternalOwnerWitnessEvidenceAbsent: Bool
    let didMarkHostedModeUnavailableForCurrentRunway: Bool
    let didRejectIsolatedProbeAsHostedOwnerTruth: Bool
    let didSelectCjguiOwnedModeAsRecoveryRoute: Bool
    let didRequireMainThreadCreation: Bool
    let didRequireHeadlessCiFailClosed: Bool
    let didDeferActivation: Bool
    let didDeferActivationPolicyMutation: Bool
    let didDeferAppKitEventLoop: Bool
    let didDeferBoundedRunLoopPump: Bool
    let didDeferVisibleOrder: Bool
    let didDeferDrawableAndRender: Bool
    let didRequireTeardownCleanupResponsibilityBeforeImplementation: Bool
    let didBlockArtifactPublicDiagnosticsPublication: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didKeepHostedOwnerTruthFalse: Bool
    let didKeepSourceReadinessTruthValueFalse: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepProductionSingletonImplementationBlocked: Bool
    let didKeepProductionActualAccessorCallSiteBlocked: Bool
    let didConfirmNoNewApplicationSingletonAccessorCall: Bool
    let didRequireFutureProductionImplementationSeparateApproval: Bool
    let didKeepOwnedLifecyclePreflightReadinessDehydrated: Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidSingletonOwnerReadyWrapper: Bool
    let didAvoidHostedOwnerTruthWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didConsumeExternalWitnessRecoveryFalseBranchDownstream: Bool,
        didConsumeRouteCHostedOwnedDualModeSelection: Bool,
        didMarkHostedModeExternalOwnerWitnessEvidenceAbsent: Bool,
        didMarkHostedModeUnavailableForCurrentRunway: Bool,
        didRejectIsolatedProbeAsHostedOwnerTruth: Bool,
        didSelectCjguiOwnedModeAsRecoveryRoute: Bool,
        didRequireMainThreadCreation: Bool,
        didRequireHeadlessCiFailClosed: Bool,
        didDeferActivation: Bool,
        didDeferActivationPolicyMutation: Bool,
        didDeferAppKitEventLoop: Bool,
        didDeferBoundedRunLoopPump: Bool,
        didDeferVisibleOrder: Bool,
        didDeferDrawableAndRender: Bool,
        didRequireTeardownCleanupResponsibilityBeforeImplementation: Bool,
        didBlockArtifactPublicDiagnosticsPublication: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didKeepHostedOwnerTruthFalse: Bool,
        didKeepSourceReadinessTruthValueFalse: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepProductionSingletonImplementationBlocked: Bool,
        didKeepProductionActualAccessorCallSiteBlocked: Bool,
        didConfirmNoNewApplicationSingletonAccessorCall: Bool,
        didRequireFutureProductionImplementationSeparateApproval: Bool,
        didKeepOwnedLifecyclePreflightReadinessDehydrated: Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidSingletonOwnerReadyWrapper: Bool,
        didAvoidHostedOwnerTruthWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didConsumeExternalWitnessRecoveryFalseBranchDownstream =
            didConsumeExternalWitnessRecoveryFalseBranchDownstream
        this.didConsumeRouteCHostedOwnedDualModeSelection =
            didConsumeRouteCHostedOwnedDualModeSelection
        this.didMarkHostedModeExternalOwnerWitnessEvidenceAbsent =
            didMarkHostedModeExternalOwnerWitnessEvidenceAbsent
        this.didMarkHostedModeUnavailableForCurrentRunway =
            didMarkHostedModeUnavailableForCurrentRunway
        this.didRejectIsolatedProbeAsHostedOwnerTruth =
            didRejectIsolatedProbeAsHostedOwnerTruth
        this.didSelectCjguiOwnedModeAsRecoveryRoute =
            didSelectCjguiOwnedModeAsRecoveryRoute
        this.didRequireMainThreadCreation = didRequireMainThreadCreation
        this.didRequireHeadlessCiFailClosed = didRequireHeadlessCiFailClosed
        this.didDeferActivation = didDeferActivation
        this.didDeferActivationPolicyMutation =
            didDeferActivationPolicyMutation
        this.didDeferAppKitEventLoop = didDeferAppKitEventLoop
        this.didDeferBoundedRunLoopPump = didDeferBoundedRunLoopPump
        this.didDeferVisibleOrder = didDeferVisibleOrder
        this.didDeferDrawableAndRender = didDeferDrawableAndRender
        this.didRequireTeardownCleanupResponsibilityBeforeImplementation =
            didRequireTeardownCleanupResponsibilityBeforeImplementation
        this.didBlockArtifactPublicDiagnosticsPublication =
            didBlockArtifactPublicDiagnosticsPublication
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoRuntimeStateWrite =
            didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didKeepHostedOwnerTruthFalse = didKeepHostedOwnerTruthFalse
        this.didKeepSourceReadinessTruthValueFalse =
            didKeepSourceReadinessTruthValueFalse
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepProductionSingletonImplementationBlocked =
            didKeepProductionSingletonImplementationBlocked
        this.didKeepProductionActualAccessorCallSiteBlocked =
            didKeepProductionActualAccessorCallSiteBlocked
        this.didConfirmNoNewApplicationSingletonAccessorCall =
            didConfirmNoNewApplicationSingletonAccessorCall
        this.didRequireFutureProductionImplementationSeparateApproval =
            didRequireFutureProductionImplementationSeparateApproval
        this.didKeepOwnedLifecyclePreflightReadinessDehydrated =
            didKeepOwnedLifecyclePreflightReadinessDehydrated
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidSingletonOwnerReadyWrapper =
            didAvoidSingletonOwnerReadyWrapper
        this.didAvoidHostedOwnerTruthWrapper = didAvoidHostedOwnerTruthWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflight {
    let cjguiOwnedSingletonLifecyclePreflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightFacts
    let didAdmitCjguiOwnedSingletonLifecyclePreflight: Bool
    let shouldDeferCjguiOwnedSingletonLifecycleImplementation: Bool
    let shouldReportCjguiOwnedSingletonLifecyclePreflightBlocked: Bool
    let didMarkHostedModeExternalOwnerWitnessEvidenceAbsent: Bool
    let didSelectCjguiOwnedModeAsRecoveryRoute: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepProductionSingletonImplementationBlocked: Bool
    let didConfirmNoNewApplicationSingletonAccessorCall: Bool
    let didKeepOwnedLifecyclePreflightDehydrated: Bool

    init(
        cjguiOwnedSingletonLifecyclePreflightFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightFacts,
        didAdmitCjguiOwnedSingletonLifecyclePreflight: Bool,
        shouldDeferCjguiOwnedSingletonLifecycleImplementation: Bool,
        shouldReportCjguiOwnedSingletonLifecyclePreflightBlocked: Bool,
        didMarkHostedModeExternalOwnerWitnessEvidenceAbsent: Bool,
        didSelectCjguiOwnedModeAsRecoveryRoute: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepProductionSingletonImplementationBlocked: Bool,
        didConfirmNoNewApplicationSingletonAccessorCall: Bool,
        didKeepOwnedLifecyclePreflightDehydrated: Bool
    ) {
        this.cjguiOwnedSingletonLifecyclePreflightFacts =
            cjguiOwnedSingletonLifecyclePreflightFacts
        this.didAdmitCjguiOwnedSingletonLifecyclePreflight =
            didAdmitCjguiOwnedSingletonLifecyclePreflight
        this.shouldDeferCjguiOwnedSingletonLifecycleImplementation =
            shouldDeferCjguiOwnedSingletonLifecycleImplementation
        this.shouldReportCjguiOwnedSingletonLifecyclePreflightBlocked =
            shouldReportCjguiOwnedSingletonLifecyclePreflightBlocked
        this.didMarkHostedModeExternalOwnerWitnessEvidenceAbsent =
            didMarkHostedModeExternalOwnerWitnessEvidenceAbsent
        this.didSelectCjguiOwnedModeAsRecoveryRoute =
            didSelectCjguiOwnedModeAsRecoveryRoute
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepProductionSingletonImplementationBlocked =
            didKeepProductionSingletonImplementationBlocked
        this.didConfirmNoNewApplicationSingletonAccessorCall =
            didConfirmNoNewApplicationSingletonAccessorCall
        this.didKeepOwnedLifecyclePreflightDehydrated =
            didKeepOwnedLifecyclePreflightDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightReadiness {
    let externalWitnessRecoveryFalseBranchDownstreamReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthRecoveryFalseBranchDownstreamReadiness
    let cjguiOwnedSingletonLifecyclePreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflight
    let didPrepareCjguiOwnedSingletonLifecyclePreflightReadiness: Bool
    let shouldDeferCjguiOwnedSingletonLifecycleImplementation: Bool
    let shouldReportCjguiOwnedSingletonLifecyclePreflightBlocked: Bool
    let didConsumeRouteCHostedOwnedDualModeSelection: Bool
    let didMarkHostedModeExternalOwnerWitnessEvidenceAbsent: Bool
    let didMarkHostedModeUnavailableForCurrentRunway: Bool
    let didSelectCjguiOwnedModeAsRecoveryRoute: Bool
    let didRequireMainThreadCreation: Bool
    let didRequireHeadlessCiFailClosed: Bool
    let didDeferActivation: Bool
    let didDeferActivationPolicyMutation: Bool
    let didDeferAppKitEventLoop: Bool
    let didDeferBoundedRunLoopPump: Bool
    let didDeferVisibleOrder: Bool
    let didDeferDrawableAndRender: Bool
    let didRequireTeardownCleanupResponsibilityBeforeImplementation: Bool
    let didBlockArtifactPublicDiagnosticsPublication: Bool
    let didKeepHostedOwnerTruthFalse: Bool
    let didKeepSourceReadinessTruthValueFalse: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepProductionSingletonImplementationBlocked: Bool
    let didKeepProductionActualAccessorCallSiteBlocked: Bool
    let didConfirmNoNewApplicationSingletonAccessorCall: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didKeepOwnedLifecyclePreflightReadinessDehydrated: Bool

    init(
        externalWitnessRecoveryFalseBranchDownstreamReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthRecoveryFalseBranchDownstreamReadiness,
        cjguiOwnedSingletonLifecyclePreflight:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflight,
        didPrepareCjguiOwnedSingletonLifecyclePreflightReadiness: Bool,
        shouldDeferCjguiOwnedSingletonLifecycleImplementation: Bool,
        shouldReportCjguiOwnedSingletonLifecyclePreflightBlocked: Bool,
        didConsumeRouteCHostedOwnedDualModeSelection: Bool,
        didMarkHostedModeExternalOwnerWitnessEvidenceAbsent: Bool,
        didMarkHostedModeUnavailableForCurrentRunway: Bool,
        didSelectCjguiOwnedModeAsRecoveryRoute: Bool,
        didRequireMainThreadCreation: Bool,
        didRequireHeadlessCiFailClosed: Bool,
        didDeferActivation: Bool,
        didDeferActivationPolicyMutation: Bool,
        didDeferAppKitEventLoop: Bool,
        didDeferBoundedRunLoopPump: Bool,
        didDeferVisibleOrder: Bool,
        didDeferDrawableAndRender: Bool,
        didRequireTeardownCleanupResponsibilityBeforeImplementation: Bool,
        didBlockArtifactPublicDiagnosticsPublication: Bool,
        didKeepHostedOwnerTruthFalse: Bool,
        didKeepSourceReadinessTruthValueFalse: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepProductionSingletonImplementationBlocked: Bool,
        didKeepProductionActualAccessorCallSiteBlocked: Bool,
        didConfirmNoNewApplicationSingletonAccessorCall: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didKeepOwnedLifecyclePreflightReadinessDehydrated: Bool
    ) {
        this.externalWitnessRecoveryFalseBranchDownstreamReadiness =
            externalWitnessRecoveryFalseBranchDownstreamReadiness
        this.cjguiOwnedSingletonLifecyclePreflight =
            cjguiOwnedSingletonLifecyclePreflight
        this.didPrepareCjguiOwnedSingletonLifecyclePreflightReadiness =
            didPrepareCjguiOwnedSingletonLifecyclePreflightReadiness
        this.shouldDeferCjguiOwnedSingletonLifecycleImplementation =
            shouldDeferCjguiOwnedSingletonLifecycleImplementation
        this.shouldReportCjguiOwnedSingletonLifecyclePreflightBlocked =
            shouldReportCjguiOwnedSingletonLifecyclePreflightBlocked
        this.didConsumeRouteCHostedOwnedDualModeSelection =
            didConsumeRouteCHostedOwnedDualModeSelection
        this.didMarkHostedModeExternalOwnerWitnessEvidenceAbsent =
            didMarkHostedModeExternalOwnerWitnessEvidenceAbsent
        this.didMarkHostedModeUnavailableForCurrentRunway =
            didMarkHostedModeUnavailableForCurrentRunway
        this.didSelectCjguiOwnedModeAsRecoveryRoute =
            didSelectCjguiOwnedModeAsRecoveryRoute
        this.didRequireMainThreadCreation = didRequireMainThreadCreation
        this.didRequireHeadlessCiFailClosed = didRequireHeadlessCiFailClosed
        this.didDeferActivation = didDeferActivation
        this.didDeferActivationPolicyMutation =
            didDeferActivationPolicyMutation
        this.didDeferAppKitEventLoop = didDeferAppKitEventLoop
        this.didDeferBoundedRunLoopPump = didDeferBoundedRunLoopPump
        this.didDeferVisibleOrder = didDeferVisibleOrder
        this.didDeferDrawableAndRender = didDeferDrawableAndRender
        this.didRequireTeardownCleanupResponsibilityBeforeImplementation =
            didRequireTeardownCleanupResponsibilityBeforeImplementation
        this.didBlockArtifactPublicDiagnosticsPublication =
            didBlockArtifactPublicDiagnosticsPublication
        this.didKeepHostedOwnerTruthFalse = didKeepHostedOwnerTruthFalse
        this.didKeepSourceReadinessTruthValueFalse =
            didKeepSourceReadinessTruthValueFalse
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepProductionSingletonImplementationBlocked =
            didKeepProductionSingletonImplementationBlocked
        this.didKeepProductionActualAccessorCallSiteBlocked =
            didKeepProductionActualAccessorCallSiteBlocked
        this.didConfirmNoNewApplicationSingletonAccessorCall =
            didConfirmNoNewApplicationSingletonAccessorCall
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoRuntimeStateWrite =
            didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didKeepOwnedLifecyclePreflightReadinessDehydrated =
            didKeepOwnedLifecyclePreflightReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightFacts(
    externalWitnessRecoveryFalseBranchDownstreamReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthRecoveryFalseBranchDownstreamReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightFacts {
    let falseBranchReady =
        externalWitnessRecoveryFalseBranchDownstreamReadiness
            .didPrepareSourceWitnessTruthRecoveryFalseBranchDownstreamReadiness &&
        externalWitnessRecoveryFalseBranchDownstreamReadiness
            .didClassifySourceWitnessTruthRecoveryFalseBranch &&
        externalWitnessRecoveryFalseBranchDownstreamReadiness
            .didRouteBackToExternalOwnerWitnessPacketEvidenceGap &&
        externalWitnessRecoveryFalseBranchDownstreamReadiness
            .didRouteBackToSourceReadinessEvidenceGap &&
        externalWitnessRecoveryFalseBranchDownstreamReadiness
            .didKeepExternalPreexistingSingletonSourceWitnessTruthFalse &&
        externalWitnessRecoveryFalseBranchDownstreamReadiness
            .didKeepSourceReadinessTruthValueFalse &&
        externalWitnessRecoveryFalseBranchDownstreamReadiness
            .didKeepProductionSingletonOwnershipTruthFalse &&
        externalWitnessRecoveryFalseBranchDownstreamReadiness
            .didKeepProductionSingletonImplementationBlocked &&
        externalWitnessRecoveryFalseBranchDownstreamReadiness
            .didKeepProductionActualAccessorCallSiteBlocked &&
        externalWitnessRecoveryFalseBranchDownstreamReadiness
            .didConfirmNoRuntimeStateWrite &&
        externalWitnessRecoveryFalseBranchDownstreamReadiness
            .didConfirmNoCjpmTomlChange &&
        externalWitnessRecoveryFalseBranchDownstreamReadiness
            .didKeepFalseBranchDownstreamReadinessDehydrated

    let hostedEvidenceAbsent =
        falseBranchReady &&
        externalWitnessRecoveryFalseBranchDownstreamReadiness
            .didRouteBackToExternalOwnerWitnessPacketEvidenceGap &&
        externalWitnessRecoveryFalseBranchDownstreamReadiness
            .didKeepExternalPreexistingSingletonSourceWitnessTruthFalse

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightFacts(
        falseBranchReady,
        true,
        hostedEvidenceAbsent,
        hostedEvidenceAbsent,
        true,
        hostedEvidenceAbsent,
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
        externalWitnessRecoveryFalseBranchDownstreamReadiness
            .didConfirmNoRuntimeStateWrite,
        externalWitnessRecoveryFalseBranchDownstreamReadiness
            .didConfirmNoCjpmTomlChange,
        hostedEvidenceAbsent,
        externalWitnessRecoveryFalseBranchDownstreamReadiness
            .didKeepSourceReadinessTruthValueFalse,
        externalWitnessRecoveryFalseBranchDownstreamReadiness
            .didKeepProductionSingletonOwnershipTruthFalse,
        externalWitnessRecoveryFalseBranchDownstreamReadiness
            .didKeepProductionSingletonImplementationBlocked,
        externalWitnessRecoveryFalseBranchDownstreamReadiness
            .didKeepProductionActualAccessorCallSiteBlocked,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflight(
    cjguiOwnedSingletonLifecyclePreflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflight {
    let admitted =
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didConsumeExternalWitnessRecoveryFalseBranchDownstream &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didConsumeRouteCHostedOwnedDualModeSelection &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didMarkHostedModeExternalOwnerWitnessEvidenceAbsent &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didMarkHostedModeUnavailableForCurrentRunway &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didRejectIsolatedProbeAsHostedOwnerTruth &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didSelectCjguiOwnedModeAsRecoveryRoute &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didRequireMainThreadCreation &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didRequireHeadlessCiFailClosed &&
        cjguiOwnedSingletonLifecyclePreflightFacts.didDeferActivation &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didDeferActivationPolicyMutation &&
        cjguiOwnedSingletonLifecyclePreflightFacts.didDeferAppKitEventLoop &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didDeferBoundedRunLoopPump &&
        cjguiOwnedSingletonLifecyclePreflightFacts.didDeferVisibleOrder &&
        cjguiOwnedSingletonLifecyclePreflightFacts.didDeferDrawableAndRender &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didRequireTeardownCleanupResponsibilityBeforeImplementation &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didBlockArtifactPublicDiagnosticsPublication &&
        cjguiOwnedSingletonLifecyclePreflightFacts.didConfirmNoPublicApi &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didConfirmNoProductionPublicCAbi &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didConfirmNoRendererStateWrite &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didConfirmNoRuntimeStateWrite &&
        cjguiOwnedSingletonLifecyclePreflightFacts.didConfirmNoCjpmTomlChange &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didKeepHostedOwnerTruthFalse &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didKeepSourceReadinessTruthValueFalse &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didKeepProductionSingletonOwnershipTruthFalse &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didKeepProductionSingletonImplementationBlocked &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didKeepProductionActualAccessorCallSiteBlocked &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didConfirmNoNewApplicationSingletonAccessorCall &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didRequireFutureProductionImplementationSeparateApproval &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didKeepOwnedLifecyclePreflightReadinessDehydrated &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didAvoidApplicationReadyWrapper &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didAvoidSingletonOwnerReadyWrapper &&
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didAvoidHostedOwnerTruthWrapper &&
        cjguiOwnedSingletonLifecyclePreflightFacts.didAvoidBackendReadyWrapper

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflight(
        cjguiOwnedSingletonLifecyclePreflightFacts,
        admitted,
        admitted,
        !admitted,
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didMarkHostedModeExternalOwnerWitnessEvidenceAbsent,
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didSelectCjguiOwnedModeAsRecoveryRoute,
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didKeepProductionSingletonOwnershipTruthFalse,
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didKeepProductionSingletonImplementationBlocked,
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didConfirmNoNewApplicationSingletonAccessorCall,
        cjguiOwnedSingletonLifecyclePreflightFacts
            .didKeepOwnedLifecyclePreflightReadinessDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightReadiness(
    externalWitnessRecoveryFalseBranchDownstreamReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthRecoveryFalseBranchDownstreamReadiness,
    cjguiOwnedSingletonLifecyclePreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflight
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightReadiness {
    let facts =
        cjguiOwnedSingletonLifecyclePreflight
            .cjguiOwnedSingletonLifecyclePreflightFacts
    let admitted =
        cjguiOwnedSingletonLifecyclePreflight
            .didAdmitCjguiOwnedSingletonLifecyclePreflight

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightReadiness(
        externalWitnessRecoveryFalseBranchDownstreamReadiness,
        cjguiOwnedSingletonLifecyclePreflight,
        admitted,
        admitted,
        !admitted,
        facts.didConsumeRouteCHostedOwnedDualModeSelection,
        facts.didMarkHostedModeExternalOwnerWitnessEvidenceAbsent,
        facts.didMarkHostedModeUnavailableForCurrentRunway,
        facts.didSelectCjguiOwnedModeAsRecoveryRoute,
        facts.didRequireMainThreadCreation,
        facts.didRequireHeadlessCiFailClosed,
        facts.didDeferActivation,
        facts.didDeferActivationPolicyMutation,
        facts.didDeferAppKitEventLoop,
        facts.didDeferBoundedRunLoopPump,
        facts.didDeferVisibleOrder,
        facts.didDeferDrawableAndRender,
        facts.didRequireTeardownCleanupResponsibilityBeforeImplementation,
        facts.didBlockArtifactPublicDiagnosticsPublication,
        facts.didKeepHostedOwnerTruthFalse,
        facts.didKeepSourceReadinessTruthValueFalse,
        facts.didKeepProductionSingletonOwnershipTruthFalse,
        facts.didKeepProductionSingletonImplementationBlocked,
        facts.didKeepProductionActualAccessorCallSiteBlocked,
        facts.didConfirmNoNewApplicationSingletonAccessorCall,
        facts.didConfirmNoPublicApi,
        facts.didConfirmNoProductionPublicCAbi,
        facts.didConfirmNoRendererStateWrite,
        facts.didConfirmNoRuntimeStateWrite,
        facts.didConfirmNoCjpmTomlChange,
        facts.didKeepOwnedLifecyclePreflightReadinessDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightReadiness {
    let externalWitnessRecoveryFalseBranchDownstreamReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthRecoveryFalseBranchDownstreamDraft()
    let cjguiOwnedSingletonLifecyclePreflightFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightFacts(
            externalWitnessRecoveryFalseBranchDownstreamReadiness
        )
    let cjguiOwnedSingletonLifecyclePreflight =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflight(
            cjguiOwnedSingletonLifecyclePreflightFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightReadiness(
        externalWitnessRecoveryFalseBranchDownstreamReadiness,
        cjguiOwnedSingletonLifecyclePreflight
    )
}
