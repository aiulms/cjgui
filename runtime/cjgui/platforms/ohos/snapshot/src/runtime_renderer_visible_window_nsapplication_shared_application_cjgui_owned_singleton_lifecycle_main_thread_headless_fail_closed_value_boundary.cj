// 中文维护注释：本文件是 visible-window production harness NSApplication
// application-singleton CJGUI-owned lifecycle main-thread / headless fail-closed
// value boundary owner。
// Owner: runtime renderer internal CJGUI-owned application lifecycle
// main-thread confinement and headless fail-closed owner。
// Truth: 只消费 CJGUI-owned lifecycle value boundary readiness，把 main-thread
// creation / cleanup confinement 与 headless / CI fail-closed 固定为 production
// singleton owner implementation 前置 value boundary；不创建 singleton，不调用
// application accessor，不执行 cleanup / teardown，不把 readiness 升级成
// production singleton ownership truth。
// Stop-line: 不实现 production singleton owner，不新增 production accessor call
// site，不调用 application singleton accessor，不创建或激活 NSApplication，不修改
// activation policy，不运行 AppKit event loop / bounded pump，不执行 cleanup /
// teardown，不创建 window / view / layer，不 visible order，不取 drawable，不创建
// command queue / command buffer / encoder，不 render / commit / present / GPU
// submission，不发布 artifact / diagnostics，不返回 native identity，不写
// runtime_state.cj，不改 cjpm.toml，不扩 public API，不新增 production C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、
// accessor-ready、singleton-owner-ready、cleanup-execution-ready、visible-ready、
// drawable-ready、render-ready、backend-ready、renderer state write、receipt、
// record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryFacts {
    let didConsumeCjguiOwnedSingletonLifecycleValueBoundaryReadiness: Bool
    let didOpenMainThreadHeadlessFailClosedValueBoundary: Bool
    let didCarryForwardTeardownCleanupResponsibilityOwnerRequired: Bool
    let didRequireMainThreadCreationConfinement: Bool
    let didRequireMainThreadCleanupConfinement: Bool
    let didRequireSingleMainThreadOwnershipDecisionBeforeImplementation: Bool
    let didRequireHeadlessEnvironmentDetectionBeforeSingletonCreation: Bool
    let didRequireHeadlessCiFailClosedBeforeSingletonCreation: Bool
    let didForbidBackgroundThreadApplicationSingletonCreation: Bool
    let didForbidHeadlessApplicationSingletonCreation: Bool
    let didDeferProductionSingletonOwnerImplementation: Bool
    let didDeferApplicationSingletonAccessorCall: Bool
    let didDeferCleanupTeardownExecution: Bool
    let didDeferActivation: Bool
    let didDeferActivationPolicyMutation: Bool
    let didDeferAppKitEventLoop: Bool
    let didDeferBoundedRunLoopPump: Bool
    let didDeferVisibleOrder: Bool
    let didDeferDrawableAndRender: Bool
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
    let didKeepMainThreadHeadlessFailClosedReadinessDehydrated: Bool
    let didRequireFutureMainThreadConfinementProbeSeparateBoundary: Bool
    let didRequireFutureHeadlessFailClosedProbeSeparateBoundary: Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidSingletonOwnerReadyWrapper: Bool
    let didAvoidCleanupExecutionWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didConsumeCjguiOwnedSingletonLifecycleValueBoundaryReadiness: Bool,
        didOpenMainThreadHeadlessFailClosedValueBoundary: Bool,
        didCarryForwardTeardownCleanupResponsibilityOwnerRequired: Bool,
        didRequireMainThreadCreationConfinement: Bool,
        didRequireMainThreadCleanupConfinement: Bool,
        didRequireSingleMainThreadOwnershipDecisionBeforeImplementation: Bool,
        didRequireHeadlessEnvironmentDetectionBeforeSingletonCreation: Bool,
        didRequireHeadlessCiFailClosedBeforeSingletonCreation: Bool,
        didForbidBackgroundThreadApplicationSingletonCreation: Bool,
        didForbidHeadlessApplicationSingletonCreation: Bool,
        didDeferProductionSingletonOwnerImplementation: Bool,
        didDeferApplicationSingletonAccessorCall: Bool,
        didDeferCleanupTeardownExecution: Bool,
        didDeferActivation: Bool,
        didDeferActivationPolicyMutation: Bool,
        didDeferAppKitEventLoop: Bool,
        didDeferBoundedRunLoopPump: Bool,
        didDeferVisibleOrder: Bool,
        didDeferDrawableAndRender: Bool,
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
        didKeepMainThreadHeadlessFailClosedReadinessDehydrated: Bool,
        didRequireFutureMainThreadConfinementProbeSeparateBoundary: Bool,
        didRequireFutureHeadlessFailClosedProbeSeparateBoundary: Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidSingletonOwnerReadyWrapper: Bool,
        didAvoidCleanupExecutionWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didConsumeCjguiOwnedSingletonLifecycleValueBoundaryReadiness =
            didConsumeCjguiOwnedSingletonLifecycleValueBoundaryReadiness
        this.didOpenMainThreadHeadlessFailClosedValueBoundary =
            didOpenMainThreadHeadlessFailClosedValueBoundary
        this.didCarryForwardTeardownCleanupResponsibilityOwnerRequired =
            didCarryForwardTeardownCleanupResponsibilityOwnerRequired
        this.didRequireMainThreadCreationConfinement =
            didRequireMainThreadCreationConfinement
        this.didRequireMainThreadCleanupConfinement =
            didRequireMainThreadCleanupConfinement
        this.didRequireSingleMainThreadOwnershipDecisionBeforeImplementation =
            didRequireSingleMainThreadOwnershipDecisionBeforeImplementation
        this.didRequireHeadlessEnvironmentDetectionBeforeSingletonCreation =
            didRequireHeadlessEnvironmentDetectionBeforeSingletonCreation
        this.didRequireHeadlessCiFailClosedBeforeSingletonCreation =
            didRequireHeadlessCiFailClosedBeforeSingletonCreation
        this.didForbidBackgroundThreadApplicationSingletonCreation =
            didForbidBackgroundThreadApplicationSingletonCreation
        this.didForbidHeadlessApplicationSingletonCreation =
            didForbidHeadlessApplicationSingletonCreation
        this.didDeferProductionSingletonOwnerImplementation =
            didDeferProductionSingletonOwnerImplementation
        this.didDeferApplicationSingletonAccessorCall =
            didDeferApplicationSingletonAccessorCall
        this.didDeferCleanupTeardownExecution =
            didDeferCleanupTeardownExecution
        this.didDeferActivation = didDeferActivation
        this.didDeferActivationPolicyMutation =
            didDeferActivationPolicyMutation
        this.didDeferAppKitEventLoop = didDeferAppKitEventLoop
        this.didDeferBoundedRunLoopPump = didDeferBoundedRunLoopPump
        this.didDeferVisibleOrder = didDeferVisibleOrder
        this.didDeferDrawableAndRender = didDeferDrawableAndRender
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
        this.didKeepMainThreadHeadlessFailClosedReadinessDehydrated =
            didKeepMainThreadHeadlessFailClosedReadinessDehydrated
        this.didRequireFutureMainThreadConfinementProbeSeparateBoundary =
            didRequireFutureMainThreadConfinementProbeSeparateBoundary
        this.didRequireFutureHeadlessFailClosedProbeSeparateBoundary =
            didRequireFutureHeadlessFailClosedProbeSeparateBoundary
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidSingletonOwnerReadyWrapper =
            didAvoidSingletonOwnerReadyWrapper
        this.didAvoidCleanupExecutionWrapper =
            didAvoidCleanupExecutionWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundary {
    let mainThreadHeadlessFailClosedValueBoundaryFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryFacts
    let didAdmitMainThreadHeadlessFailClosedValueBoundary: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldReportMainThreadHeadlessFailClosedValueBoundaryBlocked: Bool
    let didRequireMainThreadCreationConfinement: Bool
    let didRequireMainThreadCleanupConfinement: Bool
    let didRequireHeadlessCiFailClosedBeforeSingletonCreation: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepMainThreadHeadlessFailClosedReadinessDehydrated: Bool

    init(
        mainThreadHeadlessFailClosedValueBoundaryFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryFacts,
        didAdmitMainThreadHeadlessFailClosedValueBoundary: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldReportMainThreadHeadlessFailClosedValueBoundaryBlocked: Bool,
        didRequireMainThreadCreationConfinement: Bool,
        didRequireMainThreadCleanupConfinement: Bool,
        didRequireHeadlessCiFailClosedBeforeSingletonCreation: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepMainThreadHeadlessFailClosedReadinessDehydrated: Bool
    ) {
        this.mainThreadHeadlessFailClosedValueBoundaryFacts =
            mainThreadHeadlessFailClosedValueBoundaryFacts
        this.didAdmitMainThreadHeadlessFailClosedValueBoundary =
            didAdmitMainThreadHeadlessFailClosedValueBoundary
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldReportMainThreadHeadlessFailClosedValueBoundaryBlocked =
            shouldReportMainThreadHeadlessFailClosedValueBoundaryBlocked
        this.didRequireMainThreadCreationConfinement =
            didRequireMainThreadCreationConfinement
        this.didRequireMainThreadCleanupConfinement =
            didRequireMainThreadCleanupConfinement
        this.didRequireHeadlessCiFailClosedBeforeSingletonCreation =
            didRequireHeadlessCiFailClosedBeforeSingletonCreation
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepMainThreadHeadlessFailClosedReadinessDehydrated =
            didKeepMainThreadHeadlessFailClosedReadinessDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryReadiness {
    let cjguiOwnedSingletonLifecycleValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryReadiness
    let mainThreadHeadlessFailClosedValueBoundary:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundary
    let didPrepareMainThreadHeadlessFailClosedValueBoundaryReadiness: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldReportMainThreadHeadlessFailClosedValueBoundaryBlocked: Bool
    let didOpenMainThreadHeadlessFailClosedValueBoundary: Bool
    let didCarryForwardTeardownCleanupResponsibilityOwnerRequired: Bool
    let didRequireMainThreadCreationConfinement: Bool
    let didRequireMainThreadCleanupConfinement: Bool
    let didRequireSingleMainThreadOwnershipDecisionBeforeImplementation: Bool
    let didRequireHeadlessEnvironmentDetectionBeforeSingletonCreation: Bool
    let didRequireHeadlessCiFailClosedBeforeSingletonCreation: Bool
    let didForbidBackgroundThreadApplicationSingletonCreation: Bool
    let didForbidHeadlessApplicationSingletonCreation: Bool
    let didDeferActivation: Bool
    let didDeferActivationPolicyMutation: Bool
    let didDeferAppKitEventLoop: Bool
    let didDeferBoundedRunLoopPump: Bool
    let didDeferVisibleOrder: Bool
    let didDeferDrawableAndRender: Bool
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
    let didKeepMainThreadHeadlessFailClosedReadinessDehydrated: Bool

    init(
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryReadiness,
        mainThreadHeadlessFailClosedValueBoundary:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundary,
        didPrepareMainThreadHeadlessFailClosedValueBoundaryReadiness: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldReportMainThreadHeadlessFailClosedValueBoundaryBlocked: Bool,
        didOpenMainThreadHeadlessFailClosedValueBoundary: Bool,
        didCarryForwardTeardownCleanupResponsibilityOwnerRequired: Bool,
        didRequireMainThreadCreationConfinement: Bool,
        didRequireMainThreadCleanupConfinement: Bool,
        didRequireSingleMainThreadOwnershipDecisionBeforeImplementation: Bool,
        didRequireHeadlessEnvironmentDetectionBeforeSingletonCreation: Bool,
        didRequireHeadlessCiFailClosedBeforeSingletonCreation: Bool,
        didForbidBackgroundThreadApplicationSingletonCreation: Bool,
        didForbidHeadlessApplicationSingletonCreation: Bool,
        didDeferActivation: Bool,
        didDeferActivationPolicyMutation: Bool,
        didDeferAppKitEventLoop: Bool,
        didDeferBoundedRunLoopPump: Bool,
        didDeferVisibleOrder: Bool,
        didDeferDrawableAndRender: Bool,
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
        didKeepMainThreadHeadlessFailClosedReadinessDehydrated: Bool
    ) {
        this.cjguiOwnedSingletonLifecycleValueBoundaryReadiness =
            cjguiOwnedSingletonLifecycleValueBoundaryReadiness
        this.mainThreadHeadlessFailClosedValueBoundary =
            mainThreadHeadlessFailClosedValueBoundary
        this.didPrepareMainThreadHeadlessFailClosedValueBoundaryReadiness =
            didPrepareMainThreadHeadlessFailClosedValueBoundaryReadiness
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldReportMainThreadHeadlessFailClosedValueBoundaryBlocked =
            shouldReportMainThreadHeadlessFailClosedValueBoundaryBlocked
        this.didOpenMainThreadHeadlessFailClosedValueBoundary =
            didOpenMainThreadHeadlessFailClosedValueBoundary
        this.didCarryForwardTeardownCleanupResponsibilityOwnerRequired =
            didCarryForwardTeardownCleanupResponsibilityOwnerRequired
        this.didRequireMainThreadCreationConfinement =
            didRequireMainThreadCreationConfinement
        this.didRequireMainThreadCleanupConfinement =
            didRequireMainThreadCleanupConfinement
        this.didRequireSingleMainThreadOwnershipDecisionBeforeImplementation =
            didRequireSingleMainThreadOwnershipDecisionBeforeImplementation
        this.didRequireHeadlessEnvironmentDetectionBeforeSingletonCreation =
            didRequireHeadlessEnvironmentDetectionBeforeSingletonCreation
        this.didRequireHeadlessCiFailClosedBeforeSingletonCreation =
            didRequireHeadlessCiFailClosedBeforeSingletonCreation
        this.didForbidBackgroundThreadApplicationSingletonCreation =
            didForbidBackgroundThreadApplicationSingletonCreation
        this.didForbidHeadlessApplicationSingletonCreation =
            didForbidHeadlessApplicationSingletonCreation
        this.didDeferActivation = didDeferActivation
        this.didDeferActivationPolicyMutation =
            didDeferActivationPolicyMutation
        this.didDeferAppKitEventLoop = didDeferAppKitEventLoop
        this.didDeferBoundedRunLoopPump = didDeferBoundedRunLoopPump
        this.didDeferVisibleOrder = didDeferVisibleOrder
        this.didDeferDrawableAndRender = didDeferDrawableAndRender
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
        this.didKeepMainThreadHeadlessFailClosedReadinessDehydrated =
            didKeepMainThreadHeadlessFailClosedReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryFacts(
    cjguiOwnedSingletonLifecycleValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryFacts {
    let preflightReadiness =
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .cjguiOwnedSingletonLifecyclePreflightReadiness
    let valueBoundaryReady =
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didPrepareCjguiOwnedSingletonLifecycleValueBoundaryReadiness &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .shouldDeferCjguiOwnedSingletonLifecycleImplementation &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .shouldDeferTeardownCleanupExecution &&
        !cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .shouldReportCjguiOwnedSingletonLifecycleValueBoundaryBlocked &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didDeclareTeardownCleanupResponsibilityOwnerRequired &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didRequireMainThreadCleanup &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didRequireHeadlessCiFailClosed &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didDeferCleanupExecution &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness.didDeferActivation &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didDeferActivationPolicyMutation &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness.didDeferAppKitEventLoop &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didDeferBoundedRunLoopPump &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness.didDeferVisibleOrder &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didDeferDrawableAndRender &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didBlockArtifactPublicDiagnosticsPublication &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didKeepProductionSingletonOwnershipTruthFalse &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didKeepProductionSingletonImplementationBlocked &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didKeepProductionActualAccessorCallSiteBlocked &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didConfirmNoNewApplicationSingletonAccessorCall &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness.didConfirmNoPublicApi &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didConfirmNoProductionPublicCAbi &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didConfirmNoRendererStateWrite &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didConfirmNoRuntimeStateWrite &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness.didConfirmNoCjpmTomlChange

    let mainThreadCreationConfinement =
        valueBoundaryReady && preflightReadiness.didRequireMainThreadCreation
    let mainThreadCleanupConfinement =
        valueBoundaryReady &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didRequireMainThreadCleanup
    let headlessFailClosedBeforeSingletonCreation =
        valueBoundaryReady &&
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didRequireHeadlessCiFailClosed

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryFacts(
        valueBoundaryReady,
        valueBoundaryReady,
        valueBoundaryReady &&
            cjguiOwnedSingletonLifecycleValueBoundaryReadiness
                .didDeclareTeardownCleanupResponsibilityOwnerRequired,
        mainThreadCreationConfinement,
        mainThreadCleanupConfinement,
        mainThreadCreationConfinement && mainThreadCleanupConfinement,
        headlessFailClosedBeforeSingletonCreation,
        headlessFailClosedBeforeSingletonCreation,
        mainThreadCreationConfinement,
        headlessFailClosedBeforeSingletonCreation,
        valueBoundaryReady &&
            cjguiOwnedSingletonLifecycleValueBoundaryReadiness
                .didKeepProductionSingletonImplementationBlocked,
        valueBoundaryReady &&
            cjguiOwnedSingletonLifecycleValueBoundaryReadiness
                .didConfirmNoNewApplicationSingletonAccessorCall,
        valueBoundaryReady &&
            cjguiOwnedSingletonLifecycleValueBoundaryReadiness
                .didDeferCleanupExecution,
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness.didDeferActivation,
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didDeferActivationPolicyMutation,
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness.didDeferAppKitEventLoop,
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didDeferBoundedRunLoopPump,
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness.didDeferVisibleOrder,
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didDeferDrawableAndRender,
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didBlockArtifactPublicDiagnosticsPublication,
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness.didConfirmNoPublicApi,
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didConfirmNoProductionPublicCAbi,
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didConfirmNoRendererStateWrite,
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didConfirmNoRuntimeStateWrite,
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness.didConfirmNoCjpmTomlChange,
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didKeepHostedOwnerTruthFalse,
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didKeepSourceReadinessTruthValueFalse,
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didKeepProductionSingletonOwnershipTruthFalse,
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didKeepProductionSingletonImplementationBlocked,
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didKeepProductionActualAccessorCallSiteBlocked,
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness
            .didConfirmNoNewApplicationSingletonAccessorCall,
        valueBoundaryReady,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundary(
    mainThreadHeadlessFailClosedValueBoundaryFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundary {
    let admitted =
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didConsumeCjguiOwnedSingletonLifecycleValueBoundaryReadiness &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didOpenMainThreadHeadlessFailClosedValueBoundary &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didCarryForwardTeardownCleanupResponsibilityOwnerRequired &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didRequireMainThreadCreationConfinement &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didRequireMainThreadCleanupConfinement &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didRequireSingleMainThreadOwnershipDecisionBeforeImplementation &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didRequireHeadlessEnvironmentDetectionBeforeSingletonCreation &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didRequireHeadlessCiFailClosedBeforeSingletonCreation &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didForbidBackgroundThreadApplicationSingletonCreation &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didForbidHeadlessApplicationSingletonCreation &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didDeferProductionSingletonOwnerImplementation &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didDeferApplicationSingletonAccessorCall &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didDeferCleanupTeardownExecution &&
        mainThreadHeadlessFailClosedValueBoundaryFacts.didDeferActivation &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didDeferActivationPolicyMutation &&
        mainThreadHeadlessFailClosedValueBoundaryFacts.didDeferAppKitEventLoop &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didDeferBoundedRunLoopPump &&
        mainThreadHeadlessFailClosedValueBoundaryFacts.didDeferVisibleOrder &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didDeferDrawableAndRender &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didBlockArtifactPublicDiagnosticsPublication &&
        mainThreadHeadlessFailClosedValueBoundaryFacts.didConfirmNoPublicApi &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didConfirmNoProductionPublicCAbi &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didConfirmNoRendererStateWrite &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didConfirmNoRuntimeStateWrite &&
        mainThreadHeadlessFailClosedValueBoundaryFacts.didConfirmNoCjpmTomlChange &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didKeepHostedOwnerTruthFalse &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didKeepSourceReadinessTruthValueFalse &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didKeepProductionSingletonOwnershipTruthFalse &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didKeepProductionSingletonImplementationBlocked &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didKeepProductionActualAccessorCallSiteBlocked &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didConfirmNoNewApplicationSingletonAccessorCall &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didKeepMainThreadHeadlessFailClosedReadinessDehydrated &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didRequireFutureMainThreadConfinementProbeSeparateBoundary &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didRequireFutureHeadlessFailClosedProbeSeparateBoundary &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didAvoidApplicationReadyWrapper &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didAvoidSingletonOwnerReadyWrapper &&
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didAvoidCleanupExecutionWrapper &&
        mainThreadHeadlessFailClosedValueBoundaryFacts.didAvoidBackendReadyWrapper

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundary(
        mainThreadHeadlessFailClosedValueBoundaryFacts,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didRequireMainThreadCreationConfinement,
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didRequireMainThreadCleanupConfinement,
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didRequireHeadlessCiFailClosedBeforeSingletonCreation,
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didKeepProductionSingletonOwnershipTruthFalse,
        mainThreadHeadlessFailClosedValueBoundaryFacts
            .didKeepMainThreadHeadlessFailClosedReadinessDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryReadiness(
    cjguiOwnedSingletonLifecycleValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryReadiness,
    mainThreadHeadlessFailClosedValueBoundary:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundary
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryReadiness {
    let facts =
        mainThreadHeadlessFailClosedValueBoundary
            .mainThreadHeadlessFailClosedValueBoundaryFacts
    let admitted =
        mainThreadHeadlessFailClosedValueBoundary
            .didAdmitMainThreadHeadlessFailClosedValueBoundary

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryReadiness(
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness,
        mainThreadHeadlessFailClosedValueBoundary,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        facts.didOpenMainThreadHeadlessFailClosedValueBoundary,
        facts.didCarryForwardTeardownCleanupResponsibilityOwnerRequired,
        facts.didRequireMainThreadCreationConfinement,
        facts.didRequireMainThreadCleanupConfinement,
        facts.didRequireSingleMainThreadOwnershipDecisionBeforeImplementation,
        facts.didRequireHeadlessEnvironmentDetectionBeforeSingletonCreation,
        facts.didRequireHeadlessCiFailClosedBeforeSingletonCreation,
        facts.didForbidBackgroundThreadApplicationSingletonCreation,
        facts.didForbidHeadlessApplicationSingletonCreation,
        facts.didDeferActivation,
        facts.didDeferActivationPolicyMutation,
        facts.didDeferAppKitEventLoop,
        facts.didDeferBoundedRunLoopPump,
        facts.didDeferVisibleOrder,
        facts.didDeferDrawableAndRender,
        facts.didBlockArtifactPublicDiagnosticsPublication,
        facts.didConfirmNoPublicApi,
        facts.didConfirmNoProductionPublicCAbi,
        facts.didConfirmNoRendererStateWrite,
        facts.didConfirmNoRuntimeStateWrite,
        facts.didConfirmNoCjpmTomlChange,
        facts.didKeepHostedOwnerTruthFalse,
        facts.didKeepSourceReadinessTruthValueFalse,
        facts.didKeepProductionSingletonOwnershipTruthFalse,
        facts.didKeepProductionSingletonImplementationBlocked,
        facts.didKeepProductionActualAccessorCallSiteBlocked,
        facts.didConfirmNoNewApplicationSingletonAccessorCall,
        facts.didKeepMainThreadHeadlessFailClosedReadinessDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryReadiness {
    let cjguiOwnedSingletonLifecycleValueBoundaryReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryDraft()
    let mainThreadHeadlessFailClosedValueBoundaryFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryFacts(
            cjguiOwnedSingletonLifecycleValueBoundaryReadiness
        )
    let mainThreadHeadlessFailClosedValueBoundary =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundary(
            mainThreadHeadlessFailClosedValueBoundaryFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryReadiness(
        cjguiOwnedSingletonLifecycleValueBoundaryReadiness,
        mainThreadHeadlessFailClosedValueBoundary
    )
}
