// 中文维护注释：本文件是 visible-window production harness NSApplication
// application-singleton CJGUI-owned lifecycle main-thread / headless fail-closed
// evidence probe runtime native-readiness probe preflight owner。
// Owner: runtime renderer internal CJGUI-owned application lifecycle runtime
// native-readiness probe preflight owner。
// Truth: 只消费 native-readiness value boundary readiness，把 runtime native
// readiness probe preflight 固定为 no-accessor / no-bridge-expansion /
// no-runtime-probe-execution facts；不创建 singleton，不调用 application
// accessor，不扩展 native bridge，不执行 native probe，不把 readiness 升级成
// production singleton ownership truth。
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflightFacts {
    let didConsumeEvidenceProbeNativeReadinessValueBoundaryReadiness: Bool
    let didOpenRuntimeNativeReadinessProbePreflight: Bool
    let didRequireRuntimeNativeReadinessProbePreflightBeforeExecution: Bool
    let didRequireNoApplicationAccessorCallForRuntimeNativeProbePreflight:
        Bool
    let didRequireNoNativeBridgeExpansionForRuntimeNativeProbePreflight: Bool
    let didRequireNoRuntimeNativeProbeExecutionForPreflight: Bool
    let didRequireNoSingletonCreationDuringRuntimeNativeProbePreflight: Bool
    let didRequireExistingOwnerProbeAndForbiddenScan: Bool
    let didCarryForwardNativeReadinessValueBoundary: Bool
    let didCarryForwardScanOnlyNativeReadinessEvidence: Bool
    let didCarryForwardNoSideEffectEvidenceOnly: Bool
    let didCarryForwardTeardownCleanupResponsibilityOwnerRequired: Bool
    let didCarryForwardMainThreadCreationConfinement: Bool
    let didCarryForwardMainThreadCleanupConfinement: Bool
    let didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation: Bool
    let didDeferProductionSingletonOwnerImplementation: Bool
    let didDeferApplicationSingletonAccessorCall: Bool
    let didDeferCleanupTeardownExecution: Bool
    let didDeferRuntimeNativeProbeExecution: Bool
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
    let didKeepRuntimeNativeReadinessProbePreflightReadinessDehydrated:
        Bool
    let didRequireFutureRuntimeNativeReadinessProbeValueBoundarySeparateBoundary:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidSingletonOwnerReadyWrapper: Bool
    let didAvoidNativeProbeReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didConsumeEvidenceProbeNativeReadinessValueBoundaryReadiness: Bool,
        didOpenRuntimeNativeReadinessProbePreflight: Bool,
        didRequireRuntimeNativeReadinessProbePreflightBeforeExecution: Bool,
        didRequireNoApplicationAccessorCallForRuntimeNativeProbePreflight:
            Bool,
        didRequireNoNativeBridgeExpansionForRuntimeNativeProbePreflight:
            Bool,
        didRequireNoRuntimeNativeProbeExecutionForPreflight: Bool,
        didRequireNoSingletonCreationDuringRuntimeNativeProbePreflight:
            Bool,
        didRequireExistingOwnerProbeAndForbiddenScan: Bool,
        didCarryForwardNativeReadinessValueBoundary: Bool,
        didCarryForwardScanOnlyNativeReadinessEvidence: Bool,
        didCarryForwardNoSideEffectEvidenceOnly: Bool,
        didCarryForwardTeardownCleanupResponsibilityOwnerRequired: Bool,
        didCarryForwardMainThreadCreationConfinement: Bool,
        didCarryForwardMainThreadCleanupConfinement: Bool,
        didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation: Bool,
        didDeferProductionSingletonOwnerImplementation: Bool,
        didDeferApplicationSingletonAccessorCall: Bool,
        didDeferCleanupTeardownExecution: Bool,
        didDeferRuntimeNativeProbeExecution: Bool,
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
        didKeepRuntimeNativeReadinessProbePreflightReadinessDehydrated:
            Bool,
        didRequireFutureRuntimeNativeReadinessProbeValueBoundarySeparateBoundary:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidSingletonOwnerReadyWrapper: Bool,
        didAvoidNativeProbeReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didConsumeEvidenceProbeNativeReadinessValueBoundaryReadiness =
            didConsumeEvidenceProbeNativeReadinessValueBoundaryReadiness
        this.didOpenRuntimeNativeReadinessProbePreflight =
            didOpenRuntimeNativeReadinessProbePreflight
        this.didRequireRuntimeNativeReadinessProbePreflightBeforeExecution =
            didRequireRuntimeNativeReadinessProbePreflightBeforeExecution
        this.didRequireNoApplicationAccessorCallForRuntimeNativeProbePreflight =
            didRequireNoApplicationAccessorCallForRuntimeNativeProbePreflight
        this.didRequireNoNativeBridgeExpansionForRuntimeNativeProbePreflight =
            didRequireNoNativeBridgeExpansionForRuntimeNativeProbePreflight
        this.didRequireNoRuntimeNativeProbeExecutionForPreflight =
            didRequireNoRuntimeNativeProbeExecutionForPreflight
        this.didRequireNoSingletonCreationDuringRuntimeNativeProbePreflight =
            didRequireNoSingletonCreationDuringRuntimeNativeProbePreflight
        this.didRequireExistingOwnerProbeAndForbiddenScan =
            didRequireExistingOwnerProbeAndForbiddenScan
        this.didCarryForwardNativeReadinessValueBoundary =
            didCarryForwardNativeReadinessValueBoundary
        this.didCarryForwardScanOnlyNativeReadinessEvidence =
            didCarryForwardScanOnlyNativeReadinessEvidence
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
        this.didDeferRuntimeNativeProbeExecution =
            didDeferRuntimeNativeProbeExecution
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
        this.didKeepRuntimeNativeReadinessProbePreflightReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbePreflightReadinessDehydrated
        this.didRequireFutureRuntimeNativeReadinessProbeValueBoundarySeparateBoundary =
            didRequireFutureRuntimeNativeReadinessProbeValueBoundarySeparateBoundary
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidSingletonOwnerReadyWrapper =
            didAvoidSingletonOwnerReadyWrapper
        this.didAvoidNativeProbeReadyWrapper = didAvoidNativeProbeReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflight {
    let runtimeNativeReadinessProbePreflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflightFacts
    let didAdmitRuntimeNativeReadinessProbePreflight: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeNativeProbeExecution: Bool
    let shouldReportRuntimeNativeReadinessProbePreflightBlocked: Bool
    let didRequireNoApplicationAccessorCallForRuntimeNativeProbePreflight:
        Bool
    let didRequireNoNativeBridgeExpansionForRuntimeNativeProbePreflight: Bool
    let didRequireNoRuntimeNativeProbeExecutionForPreflight: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepRuntimeNativeReadinessProbePreflightReadinessDehydrated:
        Bool

    init(
        runtimeNativeReadinessProbePreflightFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflightFacts,
        didAdmitRuntimeNativeReadinessProbePreflight: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeNativeProbeExecution: Bool,
        shouldReportRuntimeNativeReadinessProbePreflightBlocked: Bool,
        didRequireNoApplicationAccessorCallForRuntimeNativeProbePreflight:
            Bool,
        didRequireNoNativeBridgeExpansionForRuntimeNativeProbePreflight:
            Bool,
        didRequireNoRuntimeNativeProbeExecutionForPreflight: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepRuntimeNativeReadinessProbePreflightReadinessDehydrated:
            Bool
    ) {
        this.runtimeNativeReadinessProbePreflightFacts =
            runtimeNativeReadinessProbePreflightFacts
        this.didAdmitRuntimeNativeReadinessProbePreflight =
            didAdmitRuntimeNativeReadinessProbePreflight
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeNativeProbeExecution =
            shouldDeferRuntimeNativeProbeExecution
        this.shouldReportRuntimeNativeReadinessProbePreflightBlocked =
            shouldReportRuntimeNativeReadinessProbePreflightBlocked
        this.didRequireNoApplicationAccessorCallForRuntimeNativeProbePreflight =
            didRequireNoApplicationAccessorCallForRuntimeNativeProbePreflight
        this.didRequireNoNativeBridgeExpansionForRuntimeNativeProbePreflight =
            didRequireNoNativeBridgeExpansionForRuntimeNativeProbePreflight
        this.didRequireNoRuntimeNativeProbeExecutionForPreflight =
            didRequireNoRuntimeNativeProbeExecutionForPreflight
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepRuntimeNativeReadinessProbePreflightReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbePreflightReadinessDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflightReadiness {
    let nativeReadinessValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryReadiness
    let runtimeNativeReadinessProbePreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflight
    let didPrepareRuntimeNativeReadinessProbePreflightReadiness: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeNativeProbeExecution: Bool
    let shouldReportRuntimeNativeReadinessProbePreflightBlocked: Bool
    let didOpenRuntimeNativeReadinessProbePreflight: Bool
    let didRequireRuntimeNativeReadinessProbePreflightBeforeExecution: Bool
    let didRequireNoApplicationAccessorCallForRuntimeNativeProbePreflight:
        Bool
    let didRequireNoNativeBridgeExpansionForRuntimeNativeProbePreflight: Bool
    let didRequireNoRuntimeNativeProbeExecutionForPreflight: Bool
    let didRequireNoSingletonCreationDuringRuntimeNativeProbePreflight: Bool
    let didCarryForwardNativeReadinessValueBoundary: Bool
    let didCarryForwardScanOnlyNativeReadinessEvidence: Bool
    let didCarryForwardNoSideEffectEvidenceOnly: Bool
    let didCarryForwardMainThreadCreationConfinement: Bool
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
    let didKeepRuntimeNativeReadinessProbePreflightReadinessDehydrated:
        Bool

    init(
        nativeReadinessValueBoundaryReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryReadiness,
        runtimeNativeReadinessProbePreflight:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflight,
        didPrepareRuntimeNativeReadinessProbePreflightReadiness: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeNativeProbeExecution: Bool,
        shouldReportRuntimeNativeReadinessProbePreflightBlocked: Bool,
        didOpenRuntimeNativeReadinessProbePreflight: Bool,
        didRequireRuntimeNativeReadinessProbePreflightBeforeExecution: Bool,
        didRequireNoApplicationAccessorCallForRuntimeNativeProbePreflight:
            Bool,
        didRequireNoNativeBridgeExpansionForRuntimeNativeProbePreflight:
            Bool,
        didRequireNoRuntimeNativeProbeExecutionForPreflight: Bool,
        didRequireNoSingletonCreationDuringRuntimeNativeProbePreflight:
            Bool,
        didCarryForwardNativeReadinessValueBoundary: Bool,
        didCarryForwardScanOnlyNativeReadinessEvidence: Bool,
        didCarryForwardNoSideEffectEvidenceOnly: Bool,
        didCarryForwardMainThreadCreationConfinement: Bool,
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
        didKeepRuntimeNativeReadinessProbePreflightReadinessDehydrated:
            Bool
    ) {
        this.nativeReadinessValueBoundaryReadiness =
            nativeReadinessValueBoundaryReadiness
        this.runtimeNativeReadinessProbePreflight =
            runtimeNativeReadinessProbePreflight
        this.didPrepareRuntimeNativeReadinessProbePreflightReadiness =
            didPrepareRuntimeNativeReadinessProbePreflightReadiness
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeNativeProbeExecution =
            shouldDeferRuntimeNativeProbeExecution
        this.shouldReportRuntimeNativeReadinessProbePreflightBlocked =
            shouldReportRuntimeNativeReadinessProbePreflightBlocked
        this.didOpenRuntimeNativeReadinessProbePreflight =
            didOpenRuntimeNativeReadinessProbePreflight
        this.didRequireRuntimeNativeReadinessProbePreflightBeforeExecution =
            didRequireRuntimeNativeReadinessProbePreflightBeforeExecution
        this.didRequireNoApplicationAccessorCallForRuntimeNativeProbePreflight =
            didRequireNoApplicationAccessorCallForRuntimeNativeProbePreflight
        this.didRequireNoNativeBridgeExpansionForRuntimeNativeProbePreflight =
            didRequireNoNativeBridgeExpansionForRuntimeNativeProbePreflight
        this.didRequireNoRuntimeNativeProbeExecutionForPreflight =
            didRequireNoRuntimeNativeProbeExecutionForPreflight
        this.didRequireNoSingletonCreationDuringRuntimeNativeProbePreflight =
            didRequireNoSingletonCreationDuringRuntimeNativeProbePreflight
        this.didCarryForwardNativeReadinessValueBoundary =
            didCarryForwardNativeReadinessValueBoundary
        this.didCarryForwardScanOnlyNativeReadinessEvidence =
            didCarryForwardScanOnlyNativeReadinessEvidence
        this.didCarryForwardNoSideEffectEvidenceOnly =
            didCarryForwardNoSideEffectEvidenceOnly
        this.didCarryForwardMainThreadCreationConfinement =
            didCarryForwardMainThreadCreationConfinement
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
        this.didKeepRuntimeNativeReadinessProbePreflightReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbePreflightReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflightFacts(
    nativeReadinessValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflightFacts {
    let valueBoundaryReady =
        nativeReadinessValueBoundaryReadiness
            .didPrepareEvidenceProbeNativeReadinessValueBoundaryReadiness &&
        nativeReadinessValueBoundaryReadiness
            .shouldDeferProductionSingletonOwnerImplementation &&
        nativeReadinessValueBoundaryReadiness
            .shouldDeferApplicationSingletonAccessorCall &&
        nativeReadinessValueBoundaryReadiness
            .shouldDeferCleanupTeardownExecution &&
        nativeReadinessValueBoundaryReadiness.shouldDeferRuntimeProbeExecution &&
        !nativeReadinessValueBoundaryReadiness
            .shouldReportEvidenceProbeNativeReadinessValueBoundaryBlocked &&
        nativeReadinessValueBoundaryReadiness
            .didOpenEvidenceProbeNativeReadinessValueBoundary &&
        nativeReadinessValueBoundaryReadiness
            .didConfirmNoApplicationAccessorCallForNativeReadinessValue &&
        nativeReadinessValueBoundaryReadiness
            .didConfirmNoNativeBridgeExpansionForNativeReadinessValue &&
        nativeReadinessValueBoundaryReadiness
            .didConfirmNoRuntimeProbeExecutionForNativeReadinessValue &&
        nativeReadinessValueBoundaryReadiness
            .didConfirmNoSingletonCreationDuringNativeReadinessValue &&
        nativeReadinessValueBoundaryReadiness
            .didConfirmScanOnlyNativeReadinessEvidence &&
        nativeReadinessValueBoundaryReadiness
            .didConfirmExistingOwnerProbeAndForbiddenScan &&
        nativeReadinessValueBoundaryReadiness
            .didCarryForwardNativeReadinessPreflight &&
        nativeReadinessValueBoundaryReadiness
            .didCarryForwardNoSideEffectEvidenceOnly &&
        nativeReadinessValueBoundaryReadiness
            .didCarryForwardMainThreadCreationConfinement &&
        nativeReadinessValueBoundaryReadiness
            .didCarryForwardMainThreadCleanupConfinement &&
        nativeReadinessValueBoundaryReadiness
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        nativeReadinessValueBoundaryReadiness.didDeferActivation &&
        nativeReadinessValueBoundaryReadiness.didDeferActivationPolicyMutation &&
        nativeReadinessValueBoundaryReadiness.didDeferAppKitEventLoop &&
        nativeReadinessValueBoundaryReadiness.didDeferBoundedRunLoopPump &&
        nativeReadinessValueBoundaryReadiness.didDeferVisibleOrder &&
        nativeReadinessValueBoundaryReadiness.didDeferDrawableAndRender &&
        nativeReadinessValueBoundaryReadiness
            .didBlockArtifactPublicDiagnosticsPublication &&
        nativeReadinessValueBoundaryReadiness.didConfirmNoPublicApi &&
        nativeReadinessValueBoundaryReadiness.didConfirmNoProductionPublicCAbi &&
        nativeReadinessValueBoundaryReadiness.didConfirmNoRendererStateWrite &&
        nativeReadinessValueBoundaryReadiness.didConfirmNoRuntimeStateWrite &&
        nativeReadinessValueBoundaryReadiness.didConfirmNoCjpmTomlChange &&
        nativeReadinessValueBoundaryReadiness
            .didKeepProductionSingletonOwnershipTruthFalse &&
        nativeReadinessValueBoundaryReadiness
            .didKeepNativeReadinessValueBoundaryReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflightFacts(
        valueBoundaryReady,
        valueBoundaryReady,
        valueBoundaryReady,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness
                .didConfirmNoApplicationAccessorCallForNativeReadinessValue,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness
                .didConfirmNoNativeBridgeExpansionForNativeReadinessValue,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness
                .didConfirmNoRuntimeProbeExecutionForNativeReadinessValue,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness
                .didConfirmNoSingletonCreationDuringNativeReadinessValue,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness
                .didConfirmExistingOwnerProbeAndForbiddenScan,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness
                .didOpenEvidenceProbeNativeReadinessValueBoundary,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness
                .didConfirmScanOnlyNativeReadinessEvidence,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness
                .didCarryForwardNoSideEffectEvidenceOnly,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness
                .didCarryForwardTeardownCleanupResponsibilityOwnerRequired,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness
                .didCarryForwardMainThreadCreationConfinement,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness
                .didCarryForwardMainThreadCleanupConfinement,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness
                .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness
                .shouldDeferProductionSingletonOwnerImplementation,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness
                .shouldDeferApplicationSingletonAccessorCall,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness
                .shouldDeferCleanupTeardownExecution,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness.shouldDeferRuntimeProbeExecution,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness.didDeferActivation,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness
                .didDeferActivationPolicyMutation,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness.didDeferAppKitEventLoop,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness.didDeferBoundedRunLoopPump,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness.didDeferVisibleOrder,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness.didDeferDrawableAndRender,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness
                .didBlockArtifactPublicDiagnosticsPublication,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness.didConfirmNoPublicApi,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness.didConfirmNoProductionPublicCAbi,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness.didConfirmNoRendererStateWrite,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness.didConfirmNoRuntimeStateWrite,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness.didConfirmNoCjpmTomlChange,
        valueBoundaryReady &&
            nativeReadinessValueBoundaryReadiness
                .didKeepProductionSingletonOwnershipTruthFalse,
        valueBoundaryReady,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflight(
    runtimeNativeReadinessProbePreflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflightFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflight {
    let admitted =
        runtimeNativeReadinessProbePreflightFacts
            .didConsumeEvidenceProbeNativeReadinessValueBoundaryReadiness &&
        runtimeNativeReadinessProbePreflightFacts
            .didOpenRuntimeNativeReadinessProbePreflight &&
        runtimeNativeReadinessProbePreflightFacts
            .didRequireRuntimeNativeReadinessProbePreflightBeforeExecution &&
        runtimeNativeReadinessProbePreflightFacts
            .didRequireNoApplicationAccessorCallForRuntimeNativeProbePreflight &&
        runtimeNativeReadinessProbePreflightFacts
            .didRequireNoNativeBridgeExpansionForRuntimeNativeProbePreflight &&
        runtimeNativeReadinessProbePreflightFacts
            .didRequireNoRuntimeNativeProbeExecutionForPreflight &&
        runtimeNativeReadinessProbePreflightFacts
            .didRequireNoSingletonCreationDuringRuntimeNativeProbePreflight &&
        runtimeNativeReadinessProbePreflightFacts
            .didRequireExistingOwnerProbeAndForbiddenScan &&
        runtimeNativeReadinessProbePreflightFacts
            .didCarryForwardNativeReadinessValueBoundary &&
        runtimeNativeReadinessProbePreflightFacts
            .didCarryForwardScanOnlyNativeReadinessEvidence &&
        runtimeNativeReadinessProbePreflightFacts
            .didCarryForwardNoSideEffectEvidenceOnly &&
        runtimeNativeReadinessProbePreflightFacts
            .didCarryForwardTeardownCleanupResponsibilityOwnerRequired &&
        runtimeNativeReadinessProbePreflightFacts
            .didCarryForwardMainThreadCreationConfinement &&
        runtimeNativeReadinessProbePreflightFacts
            .didCarryForwardMainThreadCleanupConfinement &&
        runtimeNativeReadinessProbePreflightFacts
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        runtimeNativeReadinessProbePreflightFacts
            .didDeferProductionSingletonOwnerImplementation &&
        runtimeNativeReadinessProbePreflightFacts
            .didDeferApplicationSingletonAccessorCall &&
        runtimeNativeReadinessProbePreflightFacts.didDeferCleanupTeardownExecution &&
        runtimeNativeReadinessProbePreflightFacts
            .didDeferRuntimeNativeProbeExecution &&
        runtimeNativeReadinessProbePreflightFacts.didDeferActivation &&
        runtimeNativeReadinessProbePreflightFacts
            .didDeferActivationPolicyMutation &&
        runtimeNativeReadinessProbePreflightFacts.didDeferAppKitEventLoop &&
        runtimeNativeReadinessProbePreflightFacts.didDeferBoundedRunLoopPump &&
        runtimeNativeReadinessProbePreflightFacts.didDeferVisibleOrder &&
        runtimeNativeReadinessProbePreflightFacts.didDeferDrawableAndRender &&
        runtimeNativeReadinessProbePreflightFacts
            .didBlockArtifactPublicDiagnosticsPublication &&
        runtimeNativeReadinessProbePreflightFacts.didConfirmNoPublicApi &&
        runtimeNativeReadinessProbePreflightFacts.didConfirmNoProductionPublicCAbi &&
        runtimeNativeReadinessProbePreflightFacts.didConfirmNoRendererStateWrite &&
        runtimeNativeReadinessProbePreflightFacts.didConfirmNoRuntimeStateWrite &&
        runtimeNativeReadinessProbePreflightFacts.didConfirmNoCjpmTomlChange &&
        runtimeNativeReadinessProbePreflightFacts
            .didKeepProductionSingletonOwnershipTruthFalse &&
        runtimeNativeReadinessProbePreflightFacts
            .didKeepRuntimeNativeReadinessProbePreflightReadinessDehydrated &&
        runtimeNativeReadinessProbePreflightFacts
            .didRequireFutureRuntimeNativeReadinessProbeValueBoundarySeparateBoundary &&
        runtimeNativeReadinessProbePreflightFacts.didAvoidApplicationReadyWrapper &&
        runtimeNativeReadinessProbePreflightFacts
            .didAvoidSingletonOwnerReadyWrapper &&
        runtimeNativeReadinessProbePreflightFacts.didAvoidNativeProbeReadyWrapper &&
        runtimeNativeReadinessProbePreflightFacts.didAvoidBackendReadyWrapper

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflight(
        runtimeNativeReadinessProbePreflightFacts,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        runtimeNativeReadinessProbePreflightFacts
            .didRequireNoApplicationAccessorCallForRuntimeNativeProbePreflight,
        runtimeNativeReadinessProbePreflightFacts
            .didRequireNoNativeBridgeExpansionForRuntimeNativeProbePreflight,
        runtimeNativeReadinessProbePreflightFacts
            .didRequireNoRuntimeNativeProbeExecutionForPreflight,
        runtimeNativeReadinessProbePreflightFacts
            .didKeepProductionSingletonOwnershipTruthFalse,
        runtimeNativeReadinessProbePreflightFacts
            .didKeepRuntimeNativeReadinessProbePreflightReadinessDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflightReadiness(
    nativeReadinessValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryReadiness,
    runtimeNativeReadinessProbePreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflight
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflightReadiness {
    let facts =
        runtimeNativeReadinessProbePreflight
            .runtimeNativeReadinessProbePreflightFacts
    let admitted =
        runtimeNativeReadinessProbePreflight
            .didAdmitRuntimeNativeReadinessProbePreflight

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflightReadiness(
        nativeReadinessValueBoundaryReadiness,
        runtimeNativeReadinessProbePreflight,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        facts.didOpenRuntimeNativeReadinessProbePreflight,
        facts.didRequireRuntimeNativeReadinessProbePreflightBeforeExecution,
        facts.didRequireNoApplicationAccessorCallForRuntimeNativeProbePreflight,
        facts.didRequireNoNativeBridgeExpansionForRuntimeNativeProbePreflight,
        facts.didRequireNoRuntimeNativeProbeExecutionForPreflight,
        facts.didRequireNoSingletonCreationDuringRuntimeNativeProbePreflight,
        facts.didCarryForwardNativeReadinessValueBoundary,
        facts.didCarryForwardScanOnlyNativeReadinessEvidence,
        facts.didCarryForwardNoSideEffectEvidenceOnly,
        facts.didCarryForwardMainThreadCreationConfinement,
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
        facts.didKeepRuntimeNativeReadinessProbePreflightReadinessDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflightDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflightReadiness {
    let nativeReadinessValueBoundaryReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryDraft()
    let runtimeNativeReadinessProbePreflightFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflightFacts(
            nativeReadinessValueBoundaryReadiness
        )
    let runtimeNativeReadinessProbePreflight =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflight(
            runtimeNativeReadinessProbePreflightFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflightReadiness(
        nativeReadinessValueBoundaryReadiness,
        runtimeNativeReadinessProbePreflight
    )
}
