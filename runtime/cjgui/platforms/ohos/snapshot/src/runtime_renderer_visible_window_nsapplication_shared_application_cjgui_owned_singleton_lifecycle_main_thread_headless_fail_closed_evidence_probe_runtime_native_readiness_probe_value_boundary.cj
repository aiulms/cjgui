// 中文维护注释：本文件是 visible-window production harness NSApplication
// application-singleton CJGUI-owned lifecycle main-thread / headless fail-closed
// evidence probe runtime native-readiness probe value boundary owner。
// Owner: runtime renderer internal CJGUI-owned application lifecycle runtime
// native-readiness probe value boundary owner。
// Truth: 只消费 runtime native-readiness probe preflight readiness，把 runtime
// native-readiness probe value boundary 固定为 no-accessor / no-bridge-expansion /
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryFacts {
    let didConsumeRuntimeNativeReadinessProbePreflightReadiness: Bool
    let didOpenRuntimeNativeReadinessProbeValueBoundary: Bool
    let didConfirmRuntimeNativeReadinessProbePreflightComplete: Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeValue: Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeValue: Bool
    let didConfirmNoRuntimeNativeProbeExecutionForValue: Bool
    let didConfirmNoSingletonCreationDuringRuntimeNativeProbeValue: Bool
    let didConfirmExistingOwnerProbeAndForbiddenScan: Bool
    let didCarryForwardRuntimeNativeReadinessProbePreflight: Bool
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
    let didKeepRuntimeNativeReadinessProbeValueBoundaryReadinessDehydrated:
        Bool
    let didRequireFutureRuntimeNativeReadinessProbeExecutionPreflightSeparateBoundary:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidSingletonOwnerReadyWrapper: Bool
    let didAvoidNativeProbeReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didConsumeRuntimeNativeReadinessProbePreflightReadiness: Bool,
        didOpenRuntimeNativeReadinessProbeValueBoundary: Bool,
        didConfirmRuntimeNativeReadinessProbePreflightComplete: Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeValue:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeValue: Bool,
        didConfirmNoRuntimeNativeProbeExecutionForValue: Bool,
        didConfirmNoSingletonCreationDuringRuntimeNativeProbeValue: Bool,
        didConfirmExistingOwnerProbeAndForbiddenScan: Bool,
        didCarryForwardRuntimeNativeReadinessProbePreflight: Bool,
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
        didKeepRuntimeNativeReadinessProbeValueBoundaryReadinessDehydrated:
            Bool,
        didRequireFutureRuntimeNativeReadinessProbeExecutionPreflightSeparateBoundary:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidSingletonOwnerReadyWrapper: Bool,
        didAvoidNativeProbeReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didConsumeRuntimeNativeReadinessProbePreflightReadiness =
            didConsumeRuntimeNativeReadinessProbePreflightReadiness
        this.didOpenRuntimeNativeReadinessProbeValueBoundary =
            didOpenRuntimeNativeReadinessProbeValueBoundary
        this.didConfirmRuntimeNativeReadinessProbePreflightComplete =
            didConfirmRuntimeNativeReadinessProbePreflightComplete
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeValue =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeValue
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeValue =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeValue
        this.didConfirmNoRuntimeNativeProbeExecutionForValue =
            didConfirmNoRuntimeNativeProbeExecutionForValue
        this.didConfirmNoSingletonCreationDuringRuntimeNativeProbeValue =
            didConfirmNoSingletonCreationDuringRuntimeNativeProbeValue
        this.didConfirmExistingOwnerProbeAndForbiddenScan =
            didConfirmExistingOwnerProbeAndForbiddenScan
        this.didCarryForwardRuntimeNativeReadinessProbePreflight =
            didCarryForwardRuntimeNativeReadinessProbePreflight
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
        this.didKeepRuntimeNativeReadinessProbeValueBoundaryReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeValueBoundaryReadinessDehydrated
        this.didRequireFutureRuntimeNativeReadinessProbeExecutionPreflightSeparateBoundary =
            didRequireFutureRuntimeNativeReadinessProbeExecutionPreflightSeparateBoundary
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidSingletonOwnerReadyWrapper =
            didAvoidSingletonOwnerReadyWrapper
        this.didAvoidNativeProbeReadyWrapper = didAvoidNativeProbeReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundary {
    let runtimeNativeReadinessProbeValueBoundaryFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryFacts
    let didAdmitRuntimeNativeReadinessProbeValueBoundary: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeNativeProbeExecution: Bool
    let shouldReportRuntimeNativeReadinessProbeValueBoundaryBlocked: Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeValue: Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeValue: Bool
    let didConfirmNoRuntimeNativeProbeExecutionForValue: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepRuntimeNativeReadinessProbeValueBoundaryReadinessDehydrated:
        Bool

    init(
        runtimeNativeReadinessProbeValueBoundaryFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryFacts,
        didAdmitRuntimeNativeReadinessProbeValueBoundary: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeNativeProbeExecution: Bool,
        shouldReportRuntimeNativeReadinessProbeValueBoundaryBlocked: Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeValue:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeValue: Bool,
        didConfirmNoRuntimeNativeProbeExecutionForValue: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepRuntimeNativeReadinessProbeValueBoundaryReadinessDehydrated:
            Bool
    ) {
        this.runtimeNativeReadinessProbeValueBoundaryFacts =
            runtimeNativeReadinessProbeValueBoundaryFacts
        this.didAdmitRuntimeNativeReadinessProbeValueBoundary =
            didAdmitRuntimeNativeReadinessProbeValueBoundary
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeNativeProbeExecution =
            shouldDeferRuntimeNativeProbeExecution
        this.shouldReportRuntimeNativeReadinessProbeValueBoundaryBlocked =
            shouldReportRuntimeNativeReadinessProbeValueBoundaryBlocked
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeValue =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeValue
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeValue =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeValue
        this.didConfirmNoRuntimeNativeProbeExecutionForValue =
            didConfirmNoRuntimeNativeProbeExecutionForValue
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepRuntimeNativeReadinessProbeValueBoundaryReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeValueBoundaryReadinessDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryReadiness {
    let runtimeNativeReadinessProbePreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflightReadiness
    let runtimeNativeReadinessProbeValueBoundary:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundary
    let didPrepareRuntimeNativeReadinessProbeValueBoundaryReadiness: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeNativeProbeExecution: Bool
    let shouldReportRuntimeNativeReadinessProbeValueBoundaryBlocked: Bool
    let didOpenRuntimeNativeReadinessProbeValueBoundary: Bool
    let didConfirmRuntimeNativeReadinessProbePreflightComplete: Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeValue: Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeValue: Bool
    let didConfirmNoRuntimeNativeProbeExecutionForValue: Bool
    let didConfirmNoSingletonCreationDuringRuntimeNativeProbeValue: Bool
    let didCarryForwardRuntimeNativeReadinessProbePreflight: Bool
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
    let didKeepRuntimeNativeReadinessProbeValueBoundaryReadinessDehydrated:
        Bool

    init(
        runtimeNativeReadinessProbePreflightReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflightReadiness,
        runtimeNativeReadinessProbeValueBoundary:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundary,
        didPrepareRuntimeNativeReadinessProbeValueBoundaryReadiness: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeNativeProbeExecution: Bool,
        shouldReportRuntimeNativeReadinessProbeValueBoundaryBlocked: Bool,
        didOpenRuntimeNativeReadinessProbeValueBoundary: Bool,
        didConfirmRuntimeNativeReadinessProbePreflightComplete: Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeValue:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeValue: Bool,
        didConfirmNoRuntimeNativeProbeExecutionForValue: Bool,
        didConfirmNoSingletonCreationDuringRuntimeNativeProbeValue: Bool,
        didCarryForwardRuntimeNativeReadinessProbePreflight: Bool,
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
        didKeepRuntimeNativeReadinessProbeValueBoundaryReadinessDehydrated:
            Bool
    ) {
        this.runtimeNativeReadinessProbePreflightReadiness =
            runtimeNativeReadinessProbePreflightReadiness
        this.runtimeNativeReadinessProbeValueBoundary =
            runtimeNativeReadinessProbeValueBoundary
        this.didPrepareRuntimeNativeReadinessProbeValueBoundaryReadiness =
            didPrepareRuntimeNativeReadinessProbeValueBoundaryReadiness
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeNativeProbeExecution =
            shouldDeferRuntimeNativeProbeExecution
        this.shouldReportRuntimeNativeReadinessProbeValueBoundaryBlocked =
            shouldReportRuntimeNativeReadinessProbeValueBoundaryBlocked
        this.didOpenRuntimeNativeReadinessProbeValueBoundary =
            didOpenRuntimeNativeReadinessProbeValueBoundary
        this.didConfirmRuntimeNativeReadinessProbePreflightComplete =
            didConfirmRuntimeNativeReadinessProbePreflightComplete
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeValue =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeValue
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeValue =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeValue
        this.didConfirmNoRuntimeNativeProbeExecutionForValue =
            didConfirmNoRuntimeNativeProbeExecutionForValue
        this.didConfirmNoSingletonCreationDuringRuntimeNativeProbeValue =
            didConfirmNoSingletonCreationDuringRuntimeNativeProbeValue
        this.didCarryForwardRuntimeNativeReadinessProbePreflight =
            didCarryForwardRuntimeNativeReadinessProbePreflight
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
        this.didKeepRuntimeNativeReadinessProbeValueBoundaryReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeValueBoundaryReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryFacts(
    runtimeNativeReadinessProbePreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflightReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryFacts {
    let preflightFacts =
        runtimeNativeReadinessProbePreflightReadiness
            .runtimeNativeReadinessProbePreflight
            .runtimeNativeReadinessProbePreflightFacts
    let preflightReady =
        runtimeNativeReadinessProbePreflightReadiness
            .didPrepareRuntimeNativeReadinessProbePreflightReadiness &&
        runtimeNativeReadinessProbePreflightReadiness
            .shouldDeferProductionSingletonOwnerImplementation &&
        runtimeNativeReadinessProbePreflightReadiness
            .shouldDeferApplicationSingletonAccessorCall &&
        runtimeNativeReadinessProbePreflightReadiness
            .shouldDeferCleanupTeardownExecution &&
        runtimeNativeReadinessProbePreflightReadiness
            .shouldDeferRuntimeNativeProbeExecution &&
        !runtimeNativeReadinessProbePreflightReadiness
            .shouldReportRuntimeNativeReadinessProbePreflightBlocked &&
        runtimeNativeReadinessProbePreflightReadiness
            .didOpenRuntimeNativeReadinessProbePreflight &&
        runtimeNativeReadinessProbePreflightReadiness
            .didRequireRuntimeNativeReadinessProbePreflightBeforeExecution &&
        runtimeNativeReadinessProbePreflightReadiness
            .didRequireNoApplicationAccessorCallForRuntimeNativeProbePreflight &&
        runtimeNativeReadinessProbePreflightReadiness
            .didRequireNoNativeBridgeExpansionForRuntimeNativeProbePreflight &&
        runtimeNativeReadinessProbePreflightReadiness
            .didRequireNoRuntimeNativeProbeExecutionForPreflight &&
        runtimeNativeReadinessProbePreflightReadiness
            .didRequireNoSingletonCreationDuringRuntimeNativeProbePreflight &&
        runtimeNativeReadinessProbePreflightReadiness
            .didCarryForwardNativeReadinessValueBoundary &&
        runtimeNativeReadinessProbePreflightReadiness
            .didCarryForwardScanOnlyNativeReadinessEvidence &&
        runtimeNativeReadinessProbePreflightReadiness
            .didCarryForwardNoSideEffectEvidenceOnly &&
        runtimeNativeReadinessProbePreflightReadiness
            .didCarryForwardMainThreadCreationConfinement &&
        runtimeNativeReadinessProbePreflightReadiness
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        runtimeNativeReadinessProbePreflightReadiness.didDeferActivation &&
        runtimeNativeReadinessProbePreflightReadiness
            .didDeferActivationPolicyMutation &&
        runtimeNativeReadinessProbePreflightReadiness.didDeferAppKitEventLoop &&
        runtimeNativeReadinessProbePreflightReadiness
            .didDeferBoundedRunLoopPump &&
        runtimeNativeReadinessProbePreflightReadiness.didDeferVisibleOrder &&
        runtimeNativeReadinessProbePreflightReadiness.didDeferDrawableAndRender &&
        runtimeNativeReadinessProbePreflightReadiness
            .didBlockArtifactPublicDiagnosticsPublication &&
        runtimeNativeReadinessProbePreflightReadiness.didConfirmNoPublicApi &&
        runtimeNativeReadinessProbePreflightReadiness
            .didConfirmNoProductionPublicCAbi &&
        runtimeNativeReadinessProbePreflightReadiness
            .didConfirmNoRendererStateWrite &&
        runtimeNativeReadinessProbePreflightReadiness
            .didConfirmNoRuntimeStateWrite &&
        runtimeNativeReadinessProbePreflightReadiness.didConfirmNoCjpmTomlChange &&
        runtimeNativeReadinessProbePreflightReadiness
            .didKeepProductionSingletonOwnershipTruthFalse &&
        runtimeNativeReadinessProbePreflightReadiness
            .didKeepRuntimeNativeReadinessProbePreflightReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryFacts(
        preflightReady,
        preflightReady,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .didRequireRuntimeNativeReadinessProbePreflightBeforeExecution,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .didRequireNoApplicationAccessorCallForRuntimeNativeProbePreflight,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .didRequireNoNativeBridgeExpansionForRuntimeNativeProbePreflight,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .didRequireNoRuntimeNativeProbeExecutionForPreflight,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .didRequireNoSingletonCreationDuringRuntimeNativeProbePreflight,
        preflightReady && preflightFacts.didRequireExistingOwnerProbeAndForbiddenScan,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .didOpenRuntimeNativeReadinessProbePreflight,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .didCarryForwardNativeReadinessValueBoundary,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .didCarryForwardScanOnlyNativeReadinessEvidence,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .didCarryForwardNoSideEffectEvidenceOnly,
        preflightReady &&
            preflightFacts.didCarryForwardTeardownCleanupResponsibilityOwnerRequired,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .didCarryForwardMainThreadCreationConfinement,
        preflightReady && preflightFacts.didCarryForwardMainThreadCleanupConfinement,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .shouldDeferProductionSingletonOwnerImplementation,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .shouldDeferApplicationSingletonAccessorCall,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .shouldDeferCleanupTeardownExecution,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .shouldDeferRuntimeNativeProbeExecution,
        preflightReady && runtimeNativeReadinessProbePreflightReadiness.didDeferActivation,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .didDeferActivationPolicyMutation,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness.didDeferAppKitEventLoop,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .didDeferBoundedRunLoopPump,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness.didDeferVisibleOrder,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness.didDeferDrawableAndRender,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .didBlockArtifactPublicDiagnosticsPublication,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness.didConfirmNoPublicApi,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .didConfirmNoProductionPublicCAbi,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .didConfirmNoRendererStateWrite,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .didConfirmNoRuntimeStateWrite,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness.didConfirmNoCjpmTomlChange,
        preflightReady &&
            runtimeNativeReadinessProbePreflightReadiness
                .didKeepProductionSingletonOwnershipTruthFalse,
        preflightReady,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundary(
    runtimeNativeReadinessProbeValueBoundaryFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundary {
    let admitted =
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didConsumeRuntimeNativeReadinessProbePreflightReadiness &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didOpenRuntimeNativeReadinessProbeValueBoundary &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didConfirmRuntimeNativeReadinessProbePreflightComplete &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeValue &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeValue &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didConfirmNoRuntimeNativeProbeExecutionForValue &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didConfirmNoSingletonCreationDuringRuntimeNativeProbeValue &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didConfirmExistingOwnerProbeAndForbiddenScan &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didCarryForwardRuntimeNativeReadinessProbePreflight &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didCarryForwardNativeReadinessValueBoundary &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didCarryForwardScanOnlyNativeReadinessEvidence &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didCarryForwardNoSideEffectEvidenceOnly &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didCarryForwardTeardownCleanupResponsibilityOwnerRequired &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didCarryForwardMainThreadCreationConfinement &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didCarryForwardMainThreadCleanupConfinement &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didDeferProductionSingletonOwnerImplementation &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didDeferApplicationSingletonAccessorCall &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didDeferCleanupTeardownExecution &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didDeferRuntimeNativeProbeExecution &&
        runtimeNativeReadinessProbeValueBoundaryFacts.didDeferActivation &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didDeferActivationPolicyMutation &&
        runtimeNativeReadinessProbeValueBoundaryFacts.didDeferAppKitEventLoop &&
        runtimeNativeReadinessProbeValueBoundaryFacts.didDeferBoundedRunLoopPump &&
        runtimeNativeReadinessProbeValueBoundaryFacts.didDeferVisibleOrder &&
        runtimeNativeReadinessProbeValueBoundaryFacts.didDeferDrawableAndRender &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didBlockArtifactPublicDiagnosticsPublication &&
        runtimeNativeReadinessProbeValueBoundaryFacts.didConfirmNoPublicApi &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didConfirmNoProductionPublicCAbi &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didConfirmNoRendererStateWrite &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didConfirmNoRuntimeStateWrite &&
        runtimeNativeReadinessProbeValueBoundaryFacts.didConfirmNoCjpmTomlChange &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didKeepProductionSingletonOwnershipTruthFalse &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didKeepRuntimeNativeReadinessProbeValueBoundaryReadinessDehydrated &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didRequireFutureRuntimeNativeReadinessProbeExecutionPreflightSeparateBoundary &&
        runtimeNativeReadinessProbeValueBoundaryFacts.didAvoidApplicationReadyWrapper &&
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didAvoidSingletonOwnerReadyWrapper &&
        runtimeNativeReadinessProbeValueBoundaryFacts.didAvoidNativeProbeReadyWrapper &&
        runtimeNativeReadinessProbeValueBoundaryFacts.didAvoidBackendReadyWrapper

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundary(
        runtimeNativeReadinessProbeValueBoundaryFacts,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeValue,
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeValue,
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didConfirmNoRuntimeNativeProbeExecutionForValue,
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didKeepProductionSingletonOwnershipTruthFalse,
        runtimeNativeReadinessProbeValueBoundaryFacts
            .didKeepRuntimeNativeReadinessProbeValueBoundaryReadinessDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryReadiness(
    runtimeNativeReadinessProbePreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflightReadiness,
    runtimeNativeReadinessProbeValueBoundary:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundary
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryReadiness {
    let facts =
        runtimeNativeReadinessProbeValueBoundary
            .runtimeNativeReadinessProbeValueBoundaryFacts
    let admitted =
        runtimeNativeReadinessProbeValueBoundary
            .didAdmitRuntimeNativeReadinessProbeValueBoundary

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryReadiness(
        runtimeNativeReadinessProbePreflightReadiness,
        runtimeNativeReadinessProbeValueBoundary,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        facts.didOpenRuntimeNativeReadinessProbeValueBoundary,
        facts.didConfirmRuntimeNativeReadinessProbePreflightComplete,
        facts.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeValue,
        facts.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeValue,
        facts.didConfirmNoRuntimeNativeProbeExecutionForValue,
        facts.didConfirmNoSingletonCreationDuringRuntimeNativeProbeValue,
        facts.didCarryForwardRuntimeNativeReadinessProbePreflight,
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
        facts.didKeepRuntimeNativeReadinessProbeValueBoundaryReadinessDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryReadiness {
    let runtimeNativeReadinessProbePreflightReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbePreflightDraft()
    let runtimeNativeReadinessProbeValueBoundaryFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryFacts(
            runtimeNativeReadinessProbePreflightReadiness
        )
    let runtimeNativeReadinessProbeValueBoundary =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundary(
            runtimeNativeReadinessProbeValueBoundaryFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryReadiness(
        runtimeNativeReadinessProbePreflightReadiness,
        runtimeNativeReadinessProbeValueBoundary
    )
}
