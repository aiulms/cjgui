// 中文维护注释：本文件是 visible-window production harness NSApplication
// application-singleton CJGUI-owned lifecycle value boundary owner。
// Owner: runtime renderer internal CJGUI-owned application lifecycle value
// boundary / teardown-cleanup responsibility owner。
// Truth: 只消费 CJGUI-owned lifecycle preflight readiness，把 teardown /
// cleanup responsibility 固定为 owned mode production singleton owner
// implementation 的前置责任；不执行 cleanup / teardown，不把 value boundary
// 升级成 production singleton ownership truth。
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryFacts {
    let didConsumeCjguiOwnedSingletonLifecyclePreflightReadiness: Bool
    let didOpenCjguiOwnedSingletonLifecycleValueBoundary: Bool
    let didDeclareTeardownCleanupResponsibilityOwnerRequired: Bool
    let didClassifyCleanupResponsibilityAsOwnedModePrerequisite: Bool
    let didRequireCleanupBeforeProductionSingletonImplementation: Bool
    let didRequireMainThreadCleanup: Bool
    let didRequireCleanupIdempotency: Bool
    let didRequireCleanupBeforeVisibleOrder: Bool
    let didRequireCleanupBeforeDrawableRender: Bool
    let didRequireHeadlessCiFailClosed: Bool
    let didDeferCleanupExecution: Bool
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
    let didRequireFutureTeardownImplementationSeparateApproval: Bool
    let didRequireFutureProductionImplementationSeparateApproval: Bool
    let didKeepOwnedLifecycleValueBoundaryReadinessDehydrated: Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidSingletonOwnerReadyWrapper: Bool
    let didAvoidCleanupExecutionWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didConsumeCjguiOwnedSingletonLifecyclePreflightReadiness: Bool,
        didOpenCjguiOwnedSingletonLifecycleValueBoundary: Bool,
        didDeclareTeardownCleanupResponsibilityOwnerRequired: Bool,
        didClassifyCleanupResponsibilityAsOwnedModePrerequisite: Bool,
        didRequireCleanupBeforeProductionSingletonImplementation: Bool,
        didRequireMainThreadCleanup: Bool,
        didRequireCleanupIdempotency: Bool,
        didRequireCleanupBeforeVisibleOrder: Bool,
        didRequireCleanupBeforeDrawableRender: Bool,
        didRequireHeadlessCiFailClosed: Bool,
        didDeferCleanupExecution: Bool,
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
        didRequireFutureTeardownImplementationSeparateApproval: Bool,
        didRequireFutureProductionImplementationSeparateApproval: Bool,
        didKeepOwnedLifecycleValueBoundaryReadinessDehydrated: Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidSingletonOwnerReadyWrapper: Bool,
        didAvoidCleanupExecutionWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didConsumeCjguiOwnedSingletonLifecyclePreflightReadiness =
            didConsumeCjguiOwnedSingletonLifecyclePreflightReadiness
        this.didOpenCjguiOwnedSingletonLifecycleValueBoundary =
            didOpenCjguiOwnedSingletonLifecycleValueBoundary
        this.didDeclareTeardownCleanupResponsibilityOwnerRequired =
            didDeclareTeardownCleanupResponsibilityOwnerRequired
        this.didClassifyCleanupResponsibilityAsOwnedModePrerequisite =
            didClassifyCleanupResponsibilityAsOwnedModePrerequisite
        this.didRequireCleanupBeforeProductionSingletonImplementation =
            didRequireCleanupBeforeProductionSingletonImplementation
        this.didRequireMainThreadCleanup = didRequireMainThreadCleanup
        this.didRequireCleanupIdempotency = didRequireCleanupIdempotency
        this.didRequireCleanupBeforeVisibleOrder =
            didRequireCleanupBeforeVisibleOrder
        this.didRequireCleanupBeforeDrawableRender =
            didRequireCleanupBeforeDrawableRender
        this.didRequireHeadlessCiFailClosed = didRequireHeadlessCiFailClosed
        this.didDeferCleanupExecution = didDeferCleanupExecution
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
        this.didRequireFutureTeardownImplementationSeparateApproval =
            didRequireFutureTeardownImplementationSeparateApproval
        this.didRequireFutureProductionImplementationSeparateApproval =
            didRequireFutureProductionImplementationSeparateApproval
        this.didKeepOwnedLifecycleValueBoundaryReadinessDehydrated =
            didKeepOwnedLifecycleValueBoundaryReadinessDehydrated
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidSingletonOwnerReadyWrapper =
            didAvoidSingletonOwnerReadyWrapper
        this.didAvoidCleanupExecutionWrapper =
            didAvoidCleanupExecutionWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundary {
    let cjguiOwnedSingletonLifecycleValueBoundaryFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryFacts
    let didAdmitCjguiOwnedSingletonLifecycleValueBoundary: Bool
    let shouldDeferCjguiOwnedSingletonLifecycleImplementation: Bool
    let shouldDeferTeardownCleanupExecution: Bool
    let shouldReportCjguiOwnedSingletonLifecycleValueBoundaryBlocked: Bool
    let didDeclareTeardownCleanupResponsibilityOwnerRequired: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepProductionSingletonImplementationBlocked: Bool
    let didConfirmNoNewApplicationSingletonAccessorCall: Bool
    let didKeepOwnedLifecycleValueBoundaryDehydrated: Bool

    init(
        cjguiOwnedSingletonLifecycleValueBoundaryFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryFacts,
        didAdmitCjguiOwnedSingletonLifecycleValueBoundary: Bool,
        shouldDeferCjguiOwnedSingletonLifecycleImplementation: Bool,
        shouldDeferTeardownCleanupExecution: Bool,
        shouldReportCjguiOwnedSingletonLifecycleValueBoundaryBlocked: Bool,
        didDeclareTeardownCleanupResponsibilityOwnerRequired: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepProductionSingletonImplementationBlocked: Bool,
        didConfirmNoNewApplicationSingletonAccessorCall: Bool,
        didKeepOwnedLifecycleValueBoundaryDehydrated: Bool
    ) {
        this.cjguiOwnedSingletonLifecycleValueBoundaryFacts =
            cjguiOwnedSingletonLifecycleValueBoundaryFacts
        this.didAdmitCjguiOwnedSingletonLifecycleValueBoundary =
            didAdmitCjguiOwnedSingletonLifecycleValueBoundary
        this.shouldDeferCjguiOwnedSingletonLifecycleImplementation =
            shouldDeferCjguiOwnedSingletonLifecycleImplementation
        this.shouldDeferTeardownCleanupExecution =
            shouldDeferTeardownCleanupExecution
        this.shouldReportCjguiOwnedSingletonLifecycleValueBoundaryBlocked =
            shouldReportCjguiOwnedSingletonLifecycleValueBoundaryBlocked
        this.didDeclareTeardownCleanupResponsibilityOwnerRequired =
            didDeclareTeardownCleanupResponsibilityOwnerRequired
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepProductionSingletonImplementationBlocked =
            didKeepProductionSingletonImplementationBlocked
        this.didConfirmNoNewApplicationSingletonAccessorCall =
            didConfirmNoNewApplicationSingletonAccessorCall
        this.didKeepOwnedLifecycleValueBoundaryDehydrated =
            didKeepOwnedLifecycleValueBoundaryDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryReadiness {
    let cjguiOwnedSingletonLifecyclePreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightReadiness
    let cjguiOwnedSingletonLifecycleValueBoundary:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundary
    let didPrepareCjguiOwnedSingletonLifecycleValueBoundaryReadiness: Bool
    let shouldDeferCjguiOwnedSingletonLifecycleImplementation: Bool
    let shouldDeferTeardownCleanupExecution: Bool
    let shouldReportCjguiOwnedSingletonLifecycleValueBoundaryBlocked: Bool
    let didOpenCjguiOwnedSingletonLifecycleValueBoundary: Bool
    let didDeclareTeardownCleanupResponsibilityOwnerRequired: Bool
    let didClassifyCleanupResponsibilityAsOwnedModePrerequisite: Bool
    let didRequireCleanupBeforeProductionSingletonImplementation: Bool
    let didRequireMainThreadCleanup: Bool
    let didRequireCleanupIdempotency: Bool
    let didRequireCleanupBeforeVisibleOrder: Bool
    let didRequireCleanupBeforeDrawableRender: Bool
    let didRequireHeadlessCiFailClosed: Bool
    let didDeferCleanupExecution: Bool
    let didDeferActivation: Bool
    let didDeferActivationPolicyMutation: Bool
    let didDeferAppKitEventLoop: Bool
    let didDeferBoundedRunLoopPump: Bool
    let didDeferVisibleOrder: Bool
    let didDeferDrawableAndRender: Bool
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
    let didKeepOwnedLifecycleValueBoundaryReadinessDehydrated: Bool

    init(
        cjguiOwnedSingletonLifecyclePreflightReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightReadiness,
        cjguiOwnedSingletonLifecycleValueBoundary:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundary,
        didPrepareCjguiOwnedSingletonLifecycleValueBoundaryReadiness: Bool,
        shouldDeferCjguiOwnedSingletonLifecycleImplementation: Bool,
        shouldDeferTeardownCleanupExecution: Bool,
        shouldReportCjguiOwnedSingletonLifecycleValueBoundaryBlocked: Bool,
        didOpenCjguiOwnedSingletonLifecycleValueBoundary: Bool,
        didDeclareTeardownCleanupResponsibilityOwnerRequired: Bool,
        didClassifyCleanupResponsibilityAsOwnedModePrerequisite: Bool,
        didRequireCleanupBeforeProductionSingletonImplementation: Bool,
        didRequireMainThreadCleanup: Bool,
        didRequireCleanupIdempotency: Bool,
        didRequireCleanupBeforeVisibleOrder: Bool,
        didRequireCleanupBeforeDrawableRender: Bool,
        didRequireHeadlessCiFailClosed: Bool,
        didDeferCleanupExecution: Bool,
        didDeferActivation: Bool,
        didDeferActivationPolicyMutation: Bool,
        didDeferAppKitEventLoop: Bool,
        didDeferBoundedRunLoopPump: Bool,
        didDeferVisibleOrder: Bool,
        didDeferDrawableAndRender: Bool,
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
        didKeepOwnedLifecycleValueBoundaryReadinessDehydrated: Bool
    ) {
        this.cjguiOwnedSingletonLifecyclePreflightReadiness =
            cjguiOwnedSingletonLifecyclePreflightReadiness
        this.cjguiOwnedSingletonLifecycleValueBoundary =
            cjguiOwnedSingletonLifecycleValueBoundary
        this.didPrepareCjguiOwnedSingletonLifecycleValueBoundaryReadiness =
            didPrepareCjguiOwnedSingletonLifecycleValueBoundaryReadiness
        this.shouldDeferCjguiOwnedSingletonLifecycleImplementation =
            shouldDeferCjguiOwnedSingletonLifecycleImplementation
        this.shouldDeferTeardownCleanupExecution =
            shouldDeferTeardownCleanupExecution
        this.shouldReportCjguiOwnedSingletonLifecycleValueBoundaryBlocked =
            shouldReportCjguiOwnedSingletonLifecycleValueBoundaryBlocked
        this.didOpenCjguiOwnedSingletonLifecycleValueBoundary =
            didOpenCjguiOwnedSingletonLifecycleValueBoundary
        this.didDeclareTeardownCleanupResponsibilityOwnerRequired =
            didDeclareTeardownCleanupResponsibilityOwnerRequired
        this.didClassifyCleanupResponsibilityAsOwnedModePrerequisite =
            didClassifyCleanupResponsibilityAsOwnedModePrerequisite
        this.didRequireCleanupBeforeProductionSingletonImplementation =
            didRequireCleanupBeforeProductionSingletonImplementation
        this.didRequireMainThreadCleanup = didRequireMainThreadCleanup
        this.didRequireCleanupIdempotency = didRequireCleanupIdempotency
        this.didRequireCleanupBeforeVisibleOrder =
            didRequireCleanupBeforeVisibleOrder
        this.didRequireCleanupBeforeDrawableRender =
            didRequireCleanupBeforeDrawableRender
        this.didRequireHeadlessCiFailClosed = didRequireHeadlessCiFailClosed
        this.didDeferCleanupExecution = didDeferCleanupExecution
        this.didDeferActivation = didDeferActivation
        this.didDeferActivationPolicyMutation =
            didDeferActivationPolicyMutation
        this.didDeferAppKitEventLoop = didDeferAppKitEventLoop
        this.didDeferBoundedRunLoopPump = didDeferBoundedRunLoopPump
        this.didDeferVisibleOrder = didDeferVisibleOrder
        this.didDeferDrawableAndRender = didDeferDrawableAndRender
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
        this.didKeepOwnedLifecycleValueBoundaryReadinessDehydrated =
            didKeepOwnedLifecycleValueBoundaryReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryFacts(
    cjguiOwnedSingletonLifecyclePreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryFacts {
    let preflightReady =
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didPrepareCjguiOwnedSingletonLifecyclePreflightReadiness &&
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .shouldDeferCjguiOwnedSingletonLifecycleImplementation &&
        !cjguiOwnedSingletonLifecyclePreflightReadiness
            .shouldReportCjguiOwnedSingletonLifecyclePreflightBlocked &&
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didSelectCjguiOwnedModeAsRecoveryRoute &&
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didRequireMainThreadCreation &&
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didRequireHeadlessCiFailClosed &&
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didRequireTeardownCleanupResponsibilityBeforeImplementation &&
        cjguiOwnedSingletonLifecyclePreflightReadiness.didDeferActivation &&
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didDeferActivationPolicyMutation &&
        cjguiOwnedSingletonLifecyclePreflightReadiness.didDeferAppKitEventLoop &&
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didDeferBoundedRunLoopPump &&
        cjguiOwnedSingletonLifecyclePreflightReadiness.didDeferVisibleOrder &&
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didDeferDrawableAndRender &&
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didKeepHostedOwnerTruthFalse &&
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didKeepSourceReadinessTruthValueFalse &&
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didKeepProductionSingletonOwnershipTruthFalse &&
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didKeepProductionSingletonImplementationBlocked &&
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didKeepProductionActualAccessorCallSiteBlocked &&
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didConfirmNoNewApplicationSingletonAccessorCall &&
        cjguiOwnedSingletonLifecyclePreflightReadiness.didConfirmNoPublicApi &&
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didConfirmNoProductionPublicCAbi &&
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didConfirmNoRendererStateWrite &&
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didConfirmNoRuntimeStateWrite &&
        cjguiOwnedSingletonLifecyclePreflightReadiness.didConfirmNoCjpmTomlChange

    let cleanupResponsibilityRequired =
        preflightReady &&
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didRequireTeardownCleanupResponsibilityBeforeImplementation

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryFacts(
        preflightReady,
        preflightReady,
        cleanupResponsibilityRequired,
        cleanupResponsibilityRequired,
        cleanupResponsibilityRequired,
        cleanupResponsibilityRequired,
        cleanupResponsibilityRequired,
        cleanupResponsibilityRequired,
        cleanupResponsibilityRequired,
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didRequireHeadlessCiFailClosed,
        cleanupResponsibilityRequired,
        cjguiOwnedSingletonLifecyclePreflightReadiness.didDeferActivation,
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didDeferActivationPolicyMutation,
        cjguiOwnedSingletonLifecyclePreflightReadiness.didDeferAppKitEventLoop,
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didDeferBoundedRunLoopPump,
        cjguiOwnedSingletonLifecyclePreflightReadiness.didDeferVisibleOrder,
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didDeferDrawableAndRender,
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didBlockArtifactPublicDiagnosticsPublication,
        cjguiOwnedSingletonLifecyclePreflightReadiness.didConfirmNoPublicApi,
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didConfirmNoProductionPublicCAbi,
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didConfirmNoRendererStateWrite,
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didConfirmNoRuntimeStateWrite,
        cjguiOwnedSingletonLifecyclePreflightReadiness.didConfirmNoCjpmTomlChange,
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didKeepHostedOwnerTruthFalse,
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didKeepSourceReadinessTruthValueFalse,
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didKeepProductionSingletonOwnershipTruthFalse,
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didKeepProductionSingletonImplementationBlocked,
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didKeepProductionActualAccessorCallSiteBlocked,
        cjguiOwnedSingletonLifecyclePreflightReadiness
            .didConfirmNoNewApplicationSingletonAccessorCall,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundary(
    cjguiOwnedSingletonLifecycleValueBoundaryFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundary {
    let admitted =
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didConsumeCjguiOwnedSingletonLifecyclePreflightReadiness &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didOpenCjguiOwnedSingletonLifecycleValueBoundary &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didDeclareTeardownCleanupResponsibilityOwnerRequired &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didClassifyCleanupResponsibilityAsOwnedModePrerequisite &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didRequireCleanupBeforeProductionSingletonImplementation &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didRequireMainThreadCleanup &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didRequireCleanupIdempotency &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didRequireCleanupBeforeVisibleOrder &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didRequireCleanupBeforeDrawableRender &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didRequireHeadlessCiFailClosed &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didDeferCleanupExecution &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts.didDeferActivation &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didDeferActivationPolicyMutation &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts.didDeferAppKitEventLoop &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didDeferBoundedRunLoopPump &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts.didDeferVisibleOrder &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didDeferDrawableAndRender &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didBlockArtifactPublicDiagnosticsPublication &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts.didConfirmNoPublicApi &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didConfirmNoProductionPublicCAbi &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didConfirmNoRendererStateWrite &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didConfirmNoRuntimeStateWrite &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didConfirmNoCjpmTomlChange &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didKeepHostedOwnerTruthFalse &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didKeepSourceReadinessTruthValueFalse &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didKeepProductionSingletonOwnershipTruthFalse &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didKeepProductionSingletonImplementationBlocked &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didKeepProductionActualAccessorCallSiteBlocked &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didConfirmNoNewApplicationSingletonAccessorCall &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didRequireFutureTeardownImplementationSeparateApproval &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didRequireFutureProductionImplementationSeparateApproval &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didKeepOwnedLifecycleValueBoundaryReadinessDehydrated &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didAvoidApplicationReadyWrapper &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didAvoidSingletonOwnerReadyWrapper &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didAvoidCleanupExecutionWrapper &&
        cjguiOwnedSingletonLifecycleValueBoundaryFacts.didAvoidBackendReadyWrapper

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundary(
        cjguiOwnedSingletonLifecycleValueBoundaryFacts,
        admitted,
        admitted,
        admitted,
        !admitted,
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didDeclareTeardownCleanupResponsibilityOwnerRequired,
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didKeepProductionSingletonOwnershipTruthFalse,
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didKeepProductionSingletonImplementationBlocked,
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didConfirmNoNewApplicationSingletonAccessorCall,
        cjguiOwnedSingletonLifecycleValueBoundaryFacts
            .didKeepOwnedLifecycleValueBoundaryReadinessDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryReadiness(
    cjguiOwnedSingletonLifecyclePreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightReadiness,
    cjguiOwnedSingletonLifecycleValueBoundary:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundary
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryReadiness {
    let facts =
        cjguiOwnedSingletonLifecycleValueBoundary
            .cjguiOwnedSingletonLifecycleValueBoundaryFacts
    let admitted =
        cjguiOwnedSingletonLifecycleValueBoundary
            .didAdmitCjguiOwnedSingletonLifecycleValueBoundary

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryReadiness(
        cjguiOwnedSingletonLifecyclePreflightReadiness,
        cjguiOwnedSingletonLifecycleValueBoundary,
        admitted,
        admitted,
        admitted,
        !admitted,
        facts.didOpenCjguiOwnedSingletonLifecycleValueBoundary,
        facts.didDeclareTeardownCleanupResponsibilityOwnerRequired,
        facts.didClassifyCleanupResponsibilityAsOwnedModePrerequisite,
        facts.didRequireCleanupBeforeProductionSingletonImplementation,
        facts.didRequireMainThreadCleanup,
        facts.didRequireCleanupIdempotency,
        facts.didRequireCleanupBeforeVisibleOrder,
        facts.didRequireCleanupBeforeDrawableRender,
        facts.didRequireHeadlessCiFailClosed,
        facts.didDeferCleanupExecution,
        facts.didDeferActivation,
        facts.didDeferActivationPolicyMutation,
        facts.didDeferAppKitEventLoop,
        facts.didDeferBoundedRunLoopPump,
        facts.didDeferVisibleOrder,
        facts.didDeferDrawableAndRender,
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
        facts.didKeepOwnedLifecycleValueBoundaryReadinessDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryReadiness {
    let cjguiOwnedSingletonLifecyclePreflightReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightDraft()
    let cjguiOwnedSingletonLifecycleValueBoundaryFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryFacts(
            cjguiOwnedSingletonLifecyclePreflightReadiness
        )
    let cjguiOwnedSingletonLifecycleValueBoundary =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundary(
            cjguiOwnedSingletonLifecycleValueBoundaryFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryReadiness(
        cjguiOwnedSingletonLifecyclePreflightReadiness,
        cjguiOwnedSingletonLifecycleValueBoundary
    )
}
