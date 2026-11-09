// 中文维护注释：本文件是 visible-window production harness NSApplication
// application-singleton CJGUI-owned lifecycle main-thread / headless fail-closed
// evidence probe native-readiness value boundary owner。
// Owner: runtime renderer internal CJGUI-owned application lifecycle native
// readiness value boundary owner。
// Truth: 只消费 native-readiness preflight readiness，把 native-readiness
// value boundary 固定为 no-accessor / no-bridge-expansion / no-runtime-probe
// facts；不创建 singleton，不调用 application accessor，不扩展 native bridge，
// 不执行 native probe，不把 readiness 升级成 production singleton ownership
// truth。
// Stop-line: 不实现 production singleton owner，不新增 production accessor call
// site，不调用 application singleton accessor，不创建或激活 NSApplication，不修改
// activation policy，不运行 AppKit event loop / bounded pump，不执行 cleanup /
// teardown，不创建 window / view / layer，不 visible order，不取 drawable，不创建
// command queue / command buffer / encoder，不 render / commit / present / GPU
// submission，不发布 artifact / diagnostics，不返回 native identity，不写
// runtime_state.cj，不改 cjpm.toml，不扩 public API，不新增 production C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、
// accessor-ready、singleton-owner-ready、native-probe-ready、cleanup-execution-ready、
// visible-ready、drawable-ready、render-ready、backend-ready、renderer state write、
// receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryFacts {
    let didConsumeEvidenceProbeNativeReadinessPreflightReadiness: Bool
    let didOpenEvidenceProbeNativeReadinessValueBoundary: Bool
    let didConfirmNoApplicationAccessorCallForNativeReadinessValue: Bool
    let didConfirmNoNativeBridgeExpansionForNativeReadinessValue: Bool
    let didConfirmNoRuntimeProbeExecutionForNativeReadinessValue: Bool
    let didConfirmNoSingletonCreationDuringNativeReadinessValue: Bool
    let didConfirmScanOnlyNativeReadinessEvidence: Bool
    let didConfirmExistingOwnerProbeAndForbiddenScan: Bool
    let didCarryForwardNativeReadinessPreflight: Bool
    let didCarryForwardScanOnlyMainThreadConfinementEvidence: Bool
    let didCarryForwardScanOnlyHeadlessFailClosedEvidence: Bool
    let didCarryForwardNoSideEffectEvidenceOnly: Bool
    let didCarryForwardTeardownCleanupResponsibilityOwnerRequired: Bool
    let didCarryForwardMainThreadCreationConfinement: Bool
    let didCarryForwardMainThreadCleanupConfinement: Bool
    let didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation: Bool
    let didDeferProductionSingletonOwnerImplementation: Bool
    let didDeferApplicationSingletonAccessorCall: Bool
    let didDeferCleanupTeardownExecution: Bool
    let didDeferRuntimeProbeExecution: Bool
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
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepNativeReadinessValueBoundaryReadinessDehydrated: Bool
    let didRequireFutureRuntimeNativeReadinessProbePreflightSeparateBoundary:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidSingletonOwnerReadyWrapper: Bool
    let didAvoidNativeProbeReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didConsumeEvidenceProbeNativeReadinessPreflightReadiness: Bool,
        didOpenEvidenceProbeNativeReadinessValueBoundary: Bool,
        didConfirmNoApplicationAccessorCallForNativeReadinessValue: Bool,
        didConfirmNoNativeBridgeExpansionForNativeReadinessValue: Bool,
        didConfirmNoRuntimeProbeExecutionForNativeReadinessValue: Bool,
        didConfirmNoSingletonCreationDuringNativeReadinessValue: Bool,
        didConfirmScanOnlyNativeReadinessEvidence: Bool,
        didConfirmExistingOwnerProbeAndForbiddenScan: Bool,
        didCarryForwardNativeReadinessPreflight: Bool,
        didCarryForwardScanOnlyMainThreadConfinementEvidence: Bool,
        didCarryForwardScanOnlyHeadlessFailClosedEvidence: Bool,
        didCarryForwardNoSideEffectEvidenceOnly: Bool,
        didCarryForwardTeardownCleanupResponsibilityOwnerRequired: Bool,
        didCarryForwardMainThreadCreationConfinement: Bool,
        didCarryForwardMainThreadCleanupConfinement: Bool,
        didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation: Bool,
        didDeferProductionSingletonOwnerImplementation: Bool,
        didDeferApplicationSingletonAccessorCall: Bool,
        didDeferCleanupTeardownExecution: Bool,
        didDeferRuntimeProbeExecution: Bool,
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
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepNativeReadinessValueBoundaryReadinessDehydrated: Bool,
        didRequireFutureRuntimeNativeReadinessProbePreflightSeparateBoundary:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidSingletonOwnerReadyWrapper: Bool,
        didAvoidNativeProbeReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didConsumeEvidenceProbeNativeReadinessPreflightReadiness =
            didConsumeEvidenceProbeNativeReadinessPreflightReadiness
        this.didOpenEvidenceProbeNativeReadinessValueBoundary =
            didOpenEvidenceProbeNativeReadinessValueBoundary
        this.didConfirmNoApplicationAccessorCallForNativeReadinessValue =
            didConfirmNoApplicationAccessorCallForNativeReadinessValue
        this.didConfirmNoNativeBridgeExpansionForNativeReadinessValue =
            didConfirmNoNativeBridgeExpansionForNativeReadinessValue
        this.didConfirmNoRuntimeProbeExecutionForNativeReadinessValue =
            didConfirmNoRuntimeProbeExecutionForNativeReadinessValue
        this.didConfirmNoSingletonCreationDuringNativeReadinessValue =
            didConfirmNoSingletonCreationDuringNativeReadinessValue
        this.didConfirmScanOnlyNativeReadinessEvidence =
            didConfirmScanOnlyNativeReadinessEvidence
        this.didConfirmExistingOwnerProbeAndForbiddenScan =
            didConfirmExistingOwnerProbeAndForbiddenScan
        this.didCarryForwardNativeReadinessPreflight =
            didCarryForwardNativeReadinessPreflight
        this.didCarryForwardScanOnlyMainThreadConfinementEvidence =
            didCarryForwardScanOnlyMainThreadConfinementEvidence
        this.didCarryForwardScanOnlyHeadlessFailClosedEvidence =
            didCarryForwardScanOnlyHeadlessFailClosedEvidence
        this.didCarryForwardNoSideEffectEvidenceOnly =
            didCarryForwardNoSideEffectEvidenceOnly
        this.didCarryForwardTeardownCleanupResponsibilityOwnerRequired =
            didCarryForwardTeardownCleanupResponsibilityOwnerRequired
        this.didCarryForwardMainThreadCreationConfinement =
            didCarryForwardMainThreadCreationConfinement
        this.didCarryForwardMainThreadCleanupConfinement =
            didCarryForwardMainThreadCleanupConfinement
        this.didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation =
            didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation
        this.didDeferProductionSingletonOwnerImplementation =
            didDeferProductionSingletonOwnerImplementation
        this.didDeferApplicationSingletonAccessorCall =
            didDeferApplicationSingletonAccessorCall
        this.didDeferCleanupTeardownExecution =
            didDeferCleanupTeardownExecution
        this.didDeferRuntimeProbeExecution = didDeferRuntimeProbeExecution
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
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepNativeReadinessValueBoundaryReadinessDehydrated =
            didKeepNativeReadinessValueBoundaryReadinessDehydrated
        this.didRequireFutureRuntimeNativeReadinessProbePreflightSeparateBoundary =
            didRequireFutureRuntimeNativeReadinessProbePreflightSeparateBoundary
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidSingletonOwnerReadyWrapper =
            didAvoidSingletonOwnerReadyWrapper
        this.didAvoidNativeProbeReadyWrapper = didAvoidNativeProbeReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundary {
    let nativeReadinessValueBoundaryFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryFacts
    let didAdmitEvidenceProbeNativeReadinessValueBoundary: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeProbeExecution: Bool
    let shouldReportEvidenceProbeNativeReadinessValueBoundaryBlocked: Bool
    let didConfirmNoApplicationAccessorCallForNativeReadinessValue: Bool
    let didConfirmNoNativeBridgeExpansionForNativeReadinessValue: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepNativeReadinessValueBoundaryReadinessDehydrated: Bool

    init(
        nativeReadinessValueBoundaryFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryFacts,
        didAdmitEvidenceProbeNativeReadinessValueBoundary: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeProbeExecution: Bool,
        shouldReportEvidenceProbeNativeReadinessValueBoundaryBlocked: Bool,
        didConfirmNoApplicationAccessorCallForNativeReadinessValue: Bool,
        didConfirmNoNativeBridgeExpansionForNativeReadinessValue: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepNativeReadinessValueBoundaryReadinessDehydrated: Bool
    ) {
        this.nativeReadinessValueBoundaryFacts =
            nativeReadinessValueBoundaryFacts
        this.didAdmitEvidenceProbeNativeReadinessValueBoundary =
            didAdmitEvidenceProbeNativeReadinessValueBoundary
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeProbeExecution =
            shouldDeferRuntimeProbeExecution
        this.shouldReportEvidenceProbeNativeReadinessValueBoundaryBlocked =
            shouldReportEvidenceProbeNativeReadinessValueBoundaryBlocked
        this.didConfirmNoApplicationAccessorCallForNativeReadinessValue =
            didConfirmNoApplicationAccessorCallForNativeReadinessValue
        this.didConfirmNoNativeBridgeExpansionForNativeReadinessValue =
            didConfirmNoNativeBridgeExpansionForNativeReadinessValue
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepNativeReadinessValueBoundaryReadinessDehydrated =
            didKeepNativeReadinessValueBoundaryReadinessDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryReadiness {
    let nativeReadinessPreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightReadiness
    let nativeReadinessValueBoundary:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundary
    let didPrepareEvidenceProbeNativeReadinessValueBoundaryReadiness: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeProbeExecution: Bool
    let shouldReportEvidenceProbeNativeReadinessValueBoundaryBlocked: Bool
    let didOpenEvidenceProbeNativeReadinessValueBoundary: Bool
    let didConfirmNoApplicationAccessorCallForNativeReadinessValue: Bool
    let didConfirmNoNativeBridgeExpansionForNativeReadinessValue: Bool
    let didConfirmNoRuntimeProbeExecutionForNativeReadinessValue: Bool
    let didConfirmNoSingletonCreationDuringNativeReadinessValue: Bool
    let didConfirmScanOnlyNativeReadinessEvidence: Bool
    let didConfirmExistingOwnerProbeAndForbiddenScan: Bool
    let didCarryForwardNativeReadinessPreflight: Bool
    let didCarryForwardScanOnlyMainThreadConfinementEvidence: Bool
    let didCarryForwardScanOnlyHeadlessFailClosedEvidence: Bool
    let didCarryForwardNoSideEffectEvidenceOnly: Bool
    let didCarryForwardTeardownCleanupResponsibilityOwnerRequired: Bool
    let didCarryForwardMainThreadCreationConfinement: Bool
    let didCarryForwardMainThreadCleanupConfinement: Bool
    let didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation: Bool
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
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepNativeReadinessValueBoundaryReadinessDehydrated: Bool

    init(
        nativeReadinessPreflightReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightReadiness,
        nativeReadinessValueBoundary:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundary,
        didPrepareEvidenceProbeNativeReadinessValueBoundaryReadiness: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeProbeExecution: Bool,
        shouldReportEvidenceProbeNativeReadinessValueBoundaryBlocked: Bool,
        didOpenEvidenceProbeNativeReadinessValueBoundary: Bool,
        didConfirmNoApplicationAccessorCallForNativeReadinessValue: Bool,
        didConfirmNoNativeBridgeExpansionForNativeReadinessValue: Bool,
        didConfirmNoRuntimeProbeExecutionForNativeReadinessValue: Bool,
        didConfirmNoSingletonCreationDuringNativeReadinessValue: Bool,
        didConfirmScanOnlyNativeReadinessEvidence: Bool,
        didConfirmExistingOwnerProbeAndForbiddenScan: Bool,
        didCarryForwardNativeReadinessPreflight: Bool,
        didCarryForwardScanOnlyMainThreadConfinementEvidence: Bool,
        didCarryForwardScanOnlyHeadlessFailClosedEvidence: Bool,
        didCarryForwardNoSideEffectEvidenceOnly: Bool,
        didCarryForwardTeardownCleanupResponsibilityOwnerRequired: Bool,
        didCarryForwardMainThreadCreationConfinement: Bool,
        didCarryForwardMainThreadCleanupConfinement: Bool,
        didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation: Bool,
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
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepNativeReadinessValueBoundaryReadinessDehydrated: Bool
    ) {
        this.nativeReadinessPreflightReadiness =
            nativeReadinessPreflightReadiness
        this.nativeReadinessValueBoundary = nativeReadinessValueBoundary
        this.didPrepareEvidenceProbeNativeReadinessValueBoundaryReadiness =
            didPrepareEvidenceProbeNativeReadinessValueBoundaryReadiness
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeProbeExecution =
            shouldDeferRuntimeProbeExecution
        this.shouldReportEvidenceProbeNativeReadinessValueBoundaryBlocked =
            shouldReportEvidenceProbeNativeReadinessValueBoundaryBlocked
        this.didOpenEvidenceProbeNativeReadinessValueBoundary =
            didOpenEvidenceProbeNativeReadinessValueBoundary
        this.didConfirmNoApplicationAccessorCallForNativeReadinessValue =
            didConfirmNoApplicationAccessorCallForNativeReadinessValue
        this.didConfirmNoNativeBridgeExpansionForNativeReadinessValue =
            didConfirmNoNativeBridgeExpansionForNativeReadinessValue
        this.didConfirmNoRuntimeProbeExecutionForNativeReadinessValue =
            didConfirmNoRuntimeProbeExecutionForNativeReadinessValue
        this.didConfirmNoSingletonCreationDuringNativeReadinessValue =
            didConfirmNoSingletonCreationDuringNativeReadinessValue
        this.didConfirmScanOnlyNativeReadinessEvidence =
            didConfirmScanOnlyNativeReadinessEvidence
        this.didConfirmExistingOwnerProbeAndForbiddenScan =
            didConfirmExistingOwnerProbeAndForbiddenScan
        this.didCarryForwardNativeReadinessPreflight =
            didCarryForwardNativeReadinessPreflight
        this.didCarryForwardScanOnlyMainThreadConfinementEvidence =
            didCarryForwardScanOnlyMainThreadConfinementEvidence
        this.didCarryForwardScanOnlyHeadlessFailClosedEvidence =
            didCarryForwardScanOnlyHeadlessFailClosedEvidence
        this.didCarryForwardNoSideEffectEvidenceOnly =
            didCarryForwardNoSideEffectEvidenceOnly
        this.didCarryForwardTeardownCleanupResponsibilityOwnerRequired =
            didCarryForwardTeardownCleanupResponsibilityOwnerRequired
        this.didCarryForwardMainThreadCreationConfinement =
            didCarryForwardMainThreadCreationConfinement
        this.didCarryForwardMainThreadCleanupConfinement =
            didCarryForwardMainThreadCleanupConfinement
        this.didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation =
            didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation
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
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepNativeReadinessValueBoundaryReadinessDehydrated =
            didKeepNativeReadinessValueBoundaryReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryFacts(
    nativeReadinessPreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryFacts {
    let preflightReady =
        nativeReadinessPreflightReadiness
            .didPrepareEvidenceProbeNativeReadinessPreflightReadiness &&
        nativeReadinessPreflightReadiness
            .shouldDeferProductionSingletonOwnerImplementation &&
        nativeReadinessPreflightReadiness
            .shouldDeferApplicationSingletonAccessorCall &&
        nativeReadinessPreflightReadiness.shouldDeferCleanupTeardownExecution &&
        nativeReadinessPreflightReadiness.shouldDeferRuntimeProbeExecution &&
        !nativeReadinessPreflightReadiness
            .shouldReportEvidenceProbeNativeReadinessPreflightBlocked &&
        nativeReadinessPreflightReadiness
            .didOpenEvidenceProbeNativeReadinessPreflight &&
        nativeReadinessPreflightReadiness
            .didRequireNoApplicationAccessorCallForNativeReadiness &&
        nativeReadinessPreflightReadiness
            .didRequireNoNativeBridgeExpansionForNativeReadiness &&
        nativeReadinessPreflightReadiness
            .didRequireNoRuntimeProbeExecutionForNativeReadinessPreflight &&
        nativeReadinessPreflightReadiness
            .didRequireNoSingletonCreationDuringNativeReadiness &&
        nativeReadinessPreflightReadiness.didRequireScanOnlyEvidenceInputs &&
        nativeReadinessPreflightReadiness
            .didRequireExistingOwnerProbeAndForbiddenScan &&
        nativeReadinessPreflightReadiness
            .didCarryForwardScanOnlyMainThreadConfinementEvidence &&
        nativeReadinessPreflightReadiness
            .didCarryForwardScanOnlyHeadlessFailClosedEvidence &&
        nativeReadinessPreflightReadiness
            .didCarryForwardNoSideEffectEvidenceOnly &&
        nativeReadinessPreflightReadiness
            .didCarryForwardTeardownCleanupResponsibilityOwnerRequired &&
        nativeReadinessPreflightReadiness
            .didCarryForwardMainThreadCreationConfinement &&
        nativeReadinessPreflightReadiness
            .didCarryForwardMainThreadCleanupConfinement &&
        nativeReadinessPreflightReadiness
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        nativeReadinessPreflightReadiness.didDeferActivation &&
        nativeReadinessPreflightReadiness.didDeferActivationPolicyMutation &&
        nativeReadinessPreflightReadiness.didDeferAppKitEventLoop &&
        nativeReadinessPreflightReadiness.didDeferBoundedRunLoopPump &&
        nativeReadinessPreflightReadiness.didDeferVisibleOrder &&
        nativeReadinessPreflightReadiness.didDeferDrawableAndRender &&
        nativeReadinessPreflightReadiness
            .didBlockArtifactPublicDiagnosticsPublication &&
        nativeReadinessPreflightReadiness.didConfirmNoPublicApi &&
        nativeReadinessPreflightReadiness.didConfirmNoProductionPublicCAbi &&
        nativeReadinessPreflightReadiness.didConfirmNoRendererStateWrite &&
        nativeReadinessPreflightReadiness.didConfirmNoRuntimeStateWrite &&
        nativeReadinessPreflightReadiness.didConfirmNoCjpmTomlChange &&
        nativeReadinessPreflightReadiness
            .didKeepProductionSingletonOwnershipTruthFalse &&
        nativeReadinessPreflightReadiness
            .didKeepNativeReadinessPreflightReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryFacts(
        preflightReady,
        preflightReady,
        preflightReady &&
            nativeReadinessPreflightReadiness
                .didRequireNoApplicationAccessorCallForNativeReadiness,
        preflightReady &&
            nativeReadinessPreflightReadiness
                .didRequireNoNativeBridgeExpansionForNativeReadiness,
        preflightReady &&
            nativeReadinessPreflightReadiness
                .didRequireNoRuntimeProbeExecutionForNativeReadinessPreflight,
        preflightReady &&
            nativeReadinessPreflightReadiness
                .didRequireNoSingletonCreationDuringNativeReadiness,
        preflightReady &&
            nativeReadinessPreflightReadiness.didRequireScanOnlyEvidenceInputs,
        preflightReady &&
            nativeReadinessPreflightReadiness
                .didRequireExistingOwnerProbeAndForbiddenScan,
        preflightReady &&
            nativeReadinessPreflightReadiness
                .didOpenEvidenceProbeNativeReadinessPreflight,
        preflightReady &&
            nativeReadinessPreflightReadiness
                .didCarryForwardScanOnlyMainThreadConfinementEvidence,
        preflightReady &&
            nativeReadinessPreflightReadiness
                .didCarryForwardScanOnlyHeadlessFailClosedEvidence,
        preflightReady &&
            nativeReadinessPreflightReadiness
                .didCarryForwardNoSideEffectEvidenceOnly,
        preflightReady &&
            nativeReadinessPreflightReadiness
                .didCarryForwardTeardownCleanupResponsibilityOwnerRequired,
        preflightReady &&
            nativeReadinessPreflightReadiness
                .didCarryForwardMainThreadCreationConfinement,
        preflightReady &&
            nativeReadinessPreflightReadiness
                .didCarryForwardMainThreadCleanupConfinement,
        preflightReady &&
            nativeReadinessPreflightReadiness
                .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation,
        preflightReady &&
            nativeReadinessPreflightReadiness
                .shouldDeferProductionSingletonOwnerImplementation,
        preflightReady &&
            nativeReadinessPreflightReadiness
                .shouldDeferApplicationSingletonAccessorCall,
        preflightReady &&
            nativeReadinessPreflightReadiness
                .shouldDeferCleanupTeardownExecution,
        preflightReady &&
            nativeReadinessPreflightReadiness.shouldDeferRuntimeProbeExecution,
        preflightReady && nativeReadinessPreflightReadiness.didDeferActivation,
        preflightReady &&
            nativeReadinessPreflightReadiness.didDeferActivationPolicyMutation,
        preflightReady &&
            nativeReadinessPreflightReadiness.didDeferAppKitEventLoop,
        preflightReady &&
            nativeReadinessPreflightReadiness.didDeferBoundedRunLoopPump,
        preflightReady && nativeReadinessPreflightReadiness.didDeferVisibleOrder,
        preflightReady &&
            nativeReadinessPreflightReadiness.didDeferDrawableAndRender,
        preflightReady &&
            nativeReadinessPreflightReadiness
                .didBlockArtifactPublicDiagnosticsPublication,
        preflightReady && nativeReadinessPreflightReadiness.didConfirmNoPublicApi,
        preflightReady &&
            nativeReadinessPreflightReadiness.didConfirmNoProductionPublicCAbi,
        preflightReady &&
            nativeReadinessPreflightReadiness.didConfirmNoRendererStateWrite,
        preflightReady &&
            nativeReadinessPreflightReadiness.didConfirmNoRuntimeStateWrite,
        preflightReady &&
            nativeReadinessPreflightReadiness.didConfirmNoCjpmTomlChange,
        preflightReady &&
            nativeReadinessPreflightReadiness
                .didKeepProductionSingletonOwnershipTruthFalse,
        preflightReady,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundary(
    nativeReadinessValueBoundaryFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundary {
    let admitted =
        nativeReadinessValueBoundaryFacts
            .didConsumeEvidenceProbeNativeReadinessPreflightReadiness &&
        nativeReadinessValueBoundaryFacts
            .didOpenEvidenceProbeNativeReadinessValueBoundary &&
        nativeReadinessValueBoundaryFacts
            .didConfirmNoApplicationAccessorCallForNativeReadinessValue &&
        nativeReadinessValueBoundaryFacts
            .didConfirmNoNativeBridgeExpansionForNativeReadinessValue &&
        nativeReadinessValueBoundaryFacts
            .didConfirmNoRuntimeProbeExecutionForNativeReadinessValue &&
        nativeReadinessValueBoundaryFacts
            .didConfirmNoSingletonCreationDuringNativeReadinessValue &&
        nativeReadinessValueBoundaryFacts
            .didConfirmScanOnlyNativeReadinessEvidence &&
        nativeReadinessValueBoundaryFacts
            .didConfirmExistingOwnerProbeAndForbiddenScan &&
        nativeReadinessValueBoundaryFacts
            .didCarryForwardNativeReadinessPreflight &&
        nativeReadinessValueBoundaryFacts
            .didCarryForwardScanOnlyMainThreadConfinementEvidence &&
        nativeReadinessValueBoundaryFacts
            .didCarryForwardScanOnlyHeadlessFailClosedEvidence &&
        nativeReadinessValueBoundaryFacts.didCarryForwardNoSideEffectEvidenceOnly &&
        nativeReadinessValueBoundaryFacts
            .didCarryForwardTeardownCleanupResponsibilityOwnerRequired &&
        nativeReadinessValueBoundaryFacts
            .didCarryForwardMainThreadCreationConfinement &&
        nativeReadinessValueBoundaryFacts
            .didCarryForwardMainThreadCleanupConfinement &&
        nativeReadinessValueBoundaryFacts
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        nativeReadinessValueBoundaryFacts
            .didDeferProductionSingletonOwnerImplementation &&
        nativeReadinessValueBoundaryFacts
            .didDeferApplicationSingletonAccessorCall &&
        nativeReadinessValueBoundaryFacts.didDeferCleanupTeardownExecution &&
        nativeReadinessValueBoundaryFacts.didDeferRuntimeProbeExecution &&
        nativeReadinessValueBoundaryFacts.didDeferActivation &&
        nativeReadinessValueBoundaryFacts.didDeferActivationPolicyMutation &&
        nativeReadinessValueBoundaryFacts.didDeferAppKitEventLoop &&
        nativeReadinessValueBoundaryFacts.didDeferBoundedRunLoopPump &&
        nativeReadinessValueBoundaryFacts.didDeferVisibleOrder &&
        nativeReadinessValueBoundaryFacts.didDeferDrawableAndRender &&
        nativeReadinessValueBoundaryFacts
            .didBlockArtifactPublicDiagnosticsPublication &&
        nativeReadinessValueBoundaryFacts.didConfirmNoPublicApi &&
        nativeReadinessValueBoundaryFacts.didConfirmNoProductionPublicCAbi &&
        nativeReadinessValueBoundaryFacts.didConfirmNoRendererStateWrite &&
        nativeReadinessValueBoundaryFacts.didConfirmNoRuntimeStateWrite &&
        nativeReadinessValueBoundaryFacts.didConfirmNoCjpmTomlChange &&
        nativeReadinessValueBoundaryFacts
            .didKeepProductionSingletonOwnershipTruthFalse &&
        nativeReadinessValueBoundaryFacts
            .didKeepNativeReadinessValueBoundaryReadinessDehydrated &&
        nativeReadinessValueBoundaryFacts
            .didRequireFutureRuntimeNativeReadinessProbePreflightSeparateBoundary &&
        nativeReadinessValueBoundaryFacts.didAvoidApplicationReadyWrapper &&
        nativeReadinessValueBoundaryFacts.didAvoidSingletonOwnerReadyWrapper &&
        nativeReadinessValueBoundaryFacts.didAvoidNativeProbeReadyWrapper &&
        nativeReadinessValueBoundaryFacts.didAvoidBackendReadyWrapper

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundary(
        nativeReadinessValueBoundaryFacts,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        nativeReadinessValueBoundaryFacts
            .didConfirmNoApplicationAccessorCallForNativeReadinessValue,
        nativeReadinessValueBoundaryFacts
            .didConfirmNoNativeBridgeExpansionForNativeReadinessValue,
        nativeReadinessValueBoundaryFacts
            .didKeepProductionSingletonOwnershipTruthFalse,
        nativeReadinessValueBoundaryFacts
            .didKeepNativeReadinessValueBoundaryReadinessDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryReadiness(
    nativeReadinessPreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightReadiness,
    nativeReadinessValueBoundary:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundary
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryReadiness {
    let facts = nativeReadinessValueBoundary.nativeReadinessValueBoundaryFacts
    let admitted =
        nativeReadinessValueBoundary
            .didAdmitEvidenceProbeNativeReadinessValueBoundary

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryReadiness(
        nativeReadinessPreflightReadiness,
        nativeReadinessValueBoundary,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        facts.didOpenEvidenceProbeNativeReadinessValueBoundary,
        facts.didConfirmNoApplicationAccessorCallForNativeReadinessValue,
        facts.didConfirmNoNativeBridgeExpansionForNativeReadinessValue,
        facts.didConfirmNoRuntimeProbeExecutionForNativeReadinessValue,
        facts.didConfirmNoSingletonCreationDuringNativeReadinessValue,
        facts.didConfirmScanOnlyNativeReadinessEvidence,
        facts.didConfirmExistingOwnerProbeAndForbiddenScan,
        facts.didCarryForwardNativeReadinessPreflight,
        facts.didCarryForwardScanOnlyMainThreadConfinementEvidence,
        facts.didCarryForwardScanOnlyHeadlessFailClosedEvidence,
        facts.didCarryForwardNoSideEffectEvidenceOnly,
        facts.didCarryForwardTeardownCleanupResponsibilityOwnerRequired,
        facts.didCarryForwardMainThreadCreationConfinement,
        facts.didCarryForwardMainThreadCleanupConfinement,
        facts.didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation,
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
        facts.didKeepProductionSingletonOwnershipTruthFalse,
        facts.didKeepNativeReadinessValueBoundaryReadinessDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryReadiness {
    let nativeReadinessPreflightReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightDraft()
    let nativeReadinessValueBoundaryFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryFacts(
            nativeReadinessPreflightReadiness
        )
    let nativeReadinessValueBoundary =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundary(
            nativeReadinessValueBoundaryFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryReadiness(
        nativeReadinessPreflightReadiness,
        nativeReadinessValueBoundary
    )
}
