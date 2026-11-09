// 中文维护注释：本文件是 visible-window production harness NSApplication
// application-singleton CJGUI-owned lifecycle main-thread / headless fail-closed
// evidence probe runtime native-readiness probe execution value boundary owner。
// Owner: runtime renderer internal CJGUI-owned application lifecycle runtime
// native-readiness probe execution value boundary owner。
// Truth: 只消费 runtime native-readiness probe execution preflight readiness，把
// runtime native-readiness probe execution value boundary 固定为 no-accessor /
// no-bridge-expansion / no-runtime-probe-execution facts；不创建 singleton，
// 不调用 application accessor，不扩展 native bridge，不执行 native probe，
// 不把 readiness 升级成 production singleton ownership truth。
// Stop-line: 不实现 production singleton owner，不新增 production accessor call
// site，不调用 application singleton accessor，不创建或激活 NSApplication，不修改
// activation policy，不运行 AppKit event loop / bounded pump，不执行 cleanup /
// teardown，不创建 window / view / layer，不 visible order，不取 drawable，不创建
// command queue / command buffer / encoder，不 render / commit / present / GPU
// submission，不发布 artifact / diagnostics，不返回 native identity，不写
// runtime_state.cj，不改 cjpm.toml，不扩 public API，不新增 production C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、
// accessor-ready、singleton-owner-ready、native-probe-ready、
// cleanup-execution-ready、visible-ready、drawable-ready、render-ready、
// backend-ready、renderer state write、receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryFacts {
    let didConsumeRuntimeNativeReadinessProbeExecutionPreflightReadiness:
        Bool
    let didOpenRuntimeNativeReadinessProbeExecutionValueBoundary: Bool
    let didConfirmRuntimeNativeReadinessProbeExecutionPreflightComplete:
        Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionValue:
        Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionValue:
        Bool
    let didConfirmNoRuntimeNativeProbeExecutionForValue: Bool
    let didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionValue:
        Bool
    let didConfirmExistingOwnerProbeAndForbiddenScan: Bool
    let didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight: Bool
    let didCarryForwardRuntimeNativeReadinessProbeValueBoundary: Bool
    let didCarryForwardRuntimeNativeReadinessProbePreflight: Bool
    let didCarryForwardNativeReadinessValueBoundary: Bool
    let didCarryForwardScanOnlyNativeReadinessEvidence: Bool
    let didCarryForwardNoSideEffectEvidenceOnly: Bool
    let didCarryForwardMainThreadCreationConfinement: Bool
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
    let didKeepRuntimeNativeReadinessProbeExecutionValueBoundaryReadinessDehydrated:
        Bool
    let didRequireFutureRuntimeNativeReadinessProbeExecutionFirstSliceSeparateBoundary:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidSingletonOwnerReadyWrapper: Bool
    let didAvoidNativeProbeReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didConsumeRuntimeNativeReadinessProbeExecutionPreflightReadiness:
            Bool,
        didOpenRuntimeNativeReadinessProbeExecutionValueBoundary: Bool,
        didConfirmRuntimeNativeReadinessProbeExecutionPreflightComplete:
            Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionValue:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionValue:
            Bool,
        didConfirmNoRuntimeNativeProbeExecutionForValue: Bool,
        didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionValue:
            Bool,
        didConfirmExistingOwnerProbeAndForbiddenScan: Bool,
        didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight: Bool,
        didCarryForwardRuntimeNativeReadinessProbeValueBoundary: Bool,
        didCarryForwardRuntimeNativeReadinessProbePreflight: Bool,
        didCarryForwardNativeReadinessValueBoundary: Bool,
        didCarryForwardScanOnlyNativeReadinessEvidence: Bool,
        didCarryForwardNoSideEffectEvidenceOnly: Bool,
        didCarryForwardMainThreadCreationConfinement: Bool,
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
        didKeepRuntimeNativeReadinessProbeExecutionValueBoundaryReadinessDehydrated:
            Bool,
        didRequireFutureRuntimeNativeReadinessProbeExecutionFirstSliceSeparateBoundary:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidSingletonOwnerReadyWrapper: Bool,
        didAvoidNativeProbeReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didConsumeRuntimeNativeReadinessProbeExecutionPreflightReadiness =
            didConsumeRuntimeNativeReadinessProbeExecutionPreflightReadiness
        this.didOpenRuntimeNativeReadinessProbeExecutionValueBoundary =
            didOpenRuntimeNativeReadinessProbeExecutionValueBoundary
        this.didConfirmRuntimeNativeReadinessProbeExecutionPreflightComplete =
            didConfirmRuntimeNativeReadinessProbeExecutionPreflightComplete
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionValue =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionValue
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionValue =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionValue
        this.didConfirmNoRuntimeNativeProbeExecutionForValue =
            didConfirmNoRuntimeNativeProbeExecutionForValue
        this.didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionValue =
            didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionValue
        this.didConfirmExistingOwnerProbeAndForbiddenScan =
            didConfirmExistingOwnerProbeAndForbiddenScan
        this.didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight =
            didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight
        this.didCarryForwardRuntimeNativeReadinessProbeValueBoundary =
            didCarryForwardRuntimeNativeReadinessProbeValueBoundary
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
        this.didKeepRuntimeNativeReadinessProbeExecutionValueBoundaryReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionValueBoundaryReadinessDehydrated
        this.didRequireFutureRuntimeNativeReadinessProbeExecutionFirstSliceSeparateBoundary =
            didRequireFutureRuntimeNativeReadinessProbeExecutionFirstSliceSeparateBoundary
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidSingletonOwnerReadyWrapper =
            didAvoidSingletonOwnerReadyWrapper
        this.didAvoidNativeProbeReadyWrapper = didAvoidNativeProbeReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundary {
    let runtimeNativeReadinessProbeExecutionValueBoundaryFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryFacts
    let didAdmitRuntimeNativeReadinessProbeExecutionValueBoundary: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeNativeProbeExecution: Bool
    let shouldReportRuntimeNativeReadinessProbeExecutionValueBoundaryBlocked:
        Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionValue:
        Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionValue:
        Bool
    let didConfirmNoRuntimeNativeProbeExecutionForValue: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepRuntimeNativeReadinessProbeExecutionValueBoundaryReadinessDehydrated:
        Bool

    init(
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryFacts,
        didAdmitRuntimeNativeReadinessProbeExecutionValueBoundary: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeNativeProbeExecution: Bool,
        shouldReportRuntimeNativeReadinessProbeExecutionValueBoundaryBlocked:
            Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionValue:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionValue:
            Bool,
        didConfirmNoRuntimeNativeProbeExecutionForValue: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepRuntimeNativeReadinessProbeExecutionValueBoundaryReadinessDehydrated:
            Bool
    ) {
        this.runtimeNativeReadinessProbeExecutionValueBoundaryFacts =
            runtimeNativeReadinessProbeExecutionValueBoundaryFacts
        this.didAdmitRuntimeNativeReadinessProbeExecutionValueBoundary =
            didAdmitRuntimeNativeReadinessProbeExecutionValueBoundary
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeNativeProbeExecution =
            shouldDeferRuntimeNativeProbeExecution
        this.shouldReportRuntimeNativeReadinessProbeExecutionValueBoundaryBlocked =
            shouldReportRuntimeNativeReadinessProbeExecutionValueBoundaryBlocked
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionValue =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionValue
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionValue =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionValue
        this.didConfirmNoRuntimeNativeProbeExecutionForValue =
            didConfirmNoRuntimeNativeProbeExecutionForValue
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepRuntimeNativeReadinessProbeExecutionValueBoundaryReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionValueBoundaryReadinessDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness {
    let runtimeNativeReadinessProbeExecutionPreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightReadiness
    let runtimeNativeReadinessProbeExecutionValueBoundary:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundary
    let didPrepareRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness:
        Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeNativeProbeExecution: Bool
    let shouldReportRuntimeNativeReadinessProbeExecutionValueBoundaryBlocked:
        Bool
    let didOpenRuntimeNativeReadinessProbeExecutionValueBoundary: Bool
    let didConfirmRuntimeNativeReadinessProbeExecutionPreflightComplete:
        Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionValue:
        Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionValue:
        Bool
    let didConfirmNoRuntimeNativeProbeExecutionForValue: Bool
    let didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionValue:
        Bool
    let didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight: Bool
    let didCarryForwardRuntimeNativeReadinessProbeValueBoundary: Bool
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
    let didKeepRuntimeNativeReadinessProbeExecutionValueBoundaryReadinessDehydrated:
        Bool

    init(
        runtimeNativeReadinessProbeExecutionPreflightReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightReadiness,
        runtimeNativeReadinessProbeExecutionValueBoundary:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundary,
        didPrepareRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness:
            Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeNativeProbeExecution: Bool,
        shouldReportRuntimeNativeReadinessProbeExecutionValueBoundaryBlocked:
            Bool,
        didOpenRuntimeNativeReadinessProbeExecutionValueBoundary: Bool,
        didConfirmRuntimeNativeReadinessProbeExecutionPreflightComplete:
            Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionValue:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionValue:
            Bool,
        didConfirmNoRuntimeNativeProbeExecutionForValue: Bool,
        didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionValue:
            Bool,
        didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight: Bool,
        didCarryForwardRuntimeNativeReadinessProbeValueBoundary: Bool,
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
        didKeepRuntimeNativeReadinessProbeExecutionValueBoundaryReadinessDehydrated:
            Bool
    ) {
        this.runtimeNativeReadinessProbeExecutionPreflightReadiness =
            runtimeNativeReadinessProbeExecutionPreflightReadiness
        this.runtimeNativeReadinessProbeExecutionValueBoundary =
            runtimeNativeReadinessProbeExecutionValueBoundary
        this.didPrepareRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness =
            didPrepareRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeNativeProbeExecution =
            shouldDeferRuntimeNativeProbeExecution
        this.shouldReportRuntimeNativeReadinessProbeExecutionValueBoundaryBlocked =
            shouldReportRuntimeNativeReadinessProbeExecutionValueBoundaryBlocked
        this.didOpenRuntimeNativeReadinessProbeExecutionValueBoundary =
            didOpenRuntimeNativeReadinessProbeExecutionValueBoundary
        this.didConfirmRuntimeNativeReadinessProbeExecutionPreflightComplete =
            didConfirmRuntimeNativeReadinessProbeExecutionPreflightComplete
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionValue =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionValue
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionValue =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionValue
        this.didConfirmNoRuntimeNativeProbeExecutionForValue =
            didConfirmNoRuntimeNativeProbeExecutionForValue
        this.didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionValue =
            didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionValue
        this.didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight =
            didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight
        this.didCarryForwardRuntimeNativeReadinessProbeValueBoundary =
            didCarryForwardRuntimeNativeReadinessProbeValueBoundary
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
        this.didKeepRuntimeNativeReadinessProbeExecutionValueBoundaryReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionValueBoundaryReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryFacts(
    runtimeNativeReadinessProbeExecutionPreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryFacts {
    let preflightFacts =
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .runtimeNativeReadinessProbeExecutionPreflight
            .runtimeNativeReadinessProbeExecutionPreflightFacts
    let preflightReady =
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didPrepareRuntimeNativeReadinessProbeExecutionPreflightReadiness &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .shouldDeferProductionSingletonOwnerImplementation &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .shouldDeferApplicationSingletonAccessorCall &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .shouldDeferCleanupTeardownExecution &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .shouldDeferRuntimeNativeProbeExecution &&
        !runtimeNativeReadinessProbeExecutionPreflightReadiness
            .shouldReportRuntimeNativeReadinessProbeExecutionPreflightBlocked &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didOpenRuntimeNativeReadinessProbeExecutionPreflight &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didRequireRuntimeNativeReadinessProbeExecutionPreflightBeforeExecution &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didRequireNoApplicationAccessorCallForRuntimeNativeProbeExecutionPreflight &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didRequireNoNativeBridgeExpansionForRuntimeNativeProbeExecutionPreflight &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didRequireNoRuntimeNativeProbeExecutionForPreflight &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didRequireNoSingletonCreationDuringRuntimeNativeProbeExecutionPreflight &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didCarryForwardRuntimeNativeReadinessProbeValueBoundary &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didCarryForwardRuntimeNativeReadinessProbePreflight &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didCarryForwardNativeReadinessValueBoundary &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didCarryForwardScanOnlyNativeReadinessEvidence &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didCarryForwardNoSideEffectEvidenceOnly &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didCarryForwardMainThreadCreationConfinement &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness.didDeferActivation &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didDeferActivationPolicyMutation &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didDeferAppKitEventLoop &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didDeferBoundedRunLoopPump &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didDeferVisibleOrder &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didDeferDrawableAndRender &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didBlockArtifactPublicDiagnosticsPublication &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didConfirmNoPublicApi &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didConfirmNoProductionPublicCAbi &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didConfirmNoRendererStateWrite &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didConfirmNoRuntimeStateWrite &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didConfirmNoCjpmTomlChange &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didKeepProductionSingletonOwnershipTruthFalse &&
        runtimeNativeReadinessProbeExecutionPreflightReadiness
            .didKeepRuntimeNativeReadinessProbeExecutionPreflightReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryFacts(
        preflightReady,
        preflightReady,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didOpenRuntimeNativeReadinessProbeExecutionPreflight,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didRequireNoApplicationAccessorCallForRuntimeNativeProbeExecutionPreflight,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didRequireNoNativeBridgeExpansionForRuntimeNativeProbeExecutionPreflight,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didRequireNoRuntimeNativeProbeExecutionForPreflight,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didRequireNoSingletonCreationDuringRuntimeNativeProbeExecutionPreflight,
        preflightReady && preflightFacts.didConfirmExistingOwnerProbeAndForbiddenScan,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didOpenRuntimeNativeReadinessProbeExecutionPreflight,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didCarryForwardRuntimeNativeReadinessProbeValueBoundary,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didCarryForwardRuntimeNativeReadinessProbePreflight,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didCarryForwardNativeReadinessValueBoundary,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didCarryForwardScanOnlyNativeReadinessEvidence,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didCarryForwardNoSideEffectEvidenceOnly,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didCarryForwardMainThreadCreationConfinement,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .shouldDeferProductionSingletonOwnerImplementation,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .shouldDeferApplicationSingletonAccessorCall,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .shouldDeferCleanupTeardownExecution,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .shouldDeferRuntimeNativeProbeExecution,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didDeferActivation,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didDeferActivationPolicyMutation,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didDeferAppKitEventLoop,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didDeferBoundedRunLoopPump,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didDeferVisibleOrder,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didDeferDrawableAndRender,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didBlockArtifactPublicDiagnosticsPublication,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didConfirmNoPublicApi,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didConfirmNoProductionPublicCAbi,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didConfirmNoRendererStateWrite,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didConfirmNoRuntimeStateWrite,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didConfirmNoCjpmTomlChange,
        preflightReady &&
            runtimeNativeReadinessProbeExecutionPreflightReadiness
                .didKeepProductionSingletonOwnershipTruthFalse,
        preflightReady,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundary(
    runtimeNativeReadinessProbeExecutionValueBoundaryFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundary {
    let admitted =
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didConsumeRuntimeNativeReadinessProbeExecutionPreflightReadiness &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didOpenRuntimeNativeReadinessProbeExecutionValueBoundary &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didConfirmRuntimeNativeReadinessProbeExecutionPreflightComplete &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionValue &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionValue &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didConfirmNoRuntimeNativeProbeExecutionForValue &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionValue &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didConfirmExistingOwnerProbeAndForbiddenScan &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didCarryForwardRuntimeNativeReadinessProbeValueBoundary &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didCarryForwardRuntimeNativeReadinessProbePreflight &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didCarryForwardNativeReadinessValueBoundary &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didCarryForwardScanOnlyNativeReadinessEvidence &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didCarryForwardNoSideEffectEvidenceOnly &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didCarryForwardMainThreadCreationConfinement &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didDeferProductionSingletonOwnerImplementation &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didDeferApplicationSingletonAccessorCall &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didDeferCleanupTeardownExecution &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didDeferRuntimeNativeProbeExecution &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts.didDeferActivation &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didDeferActivationPolicyMutation &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didDeferAppKitEventLoop &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didDeferBoundedRunLoopPump &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts.didDeferVisibleOrder &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didDeferDrawableAndRender &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didBlockArtifactPublicDiagnosticsPublication &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts.didConfirmNoPublicApi &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didConfirmNoProductionPublicCAbi &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didConfirmNoRendererStateWrite &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didConfirmNoRuntimeStateWrite &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts.didConfirmNoCjpmTomlChange &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didKeepProductionSingletonOwnershipTruthFalse &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didKeepRuntimeNativeReadinessProbeExecutionValueBoundaryReadinessDehydrated &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didRequireFutureRuntimeNativeReadinessProbeExecutionFirstSliceSeparateBoundary &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts.didAvoidApplicationReadyWrapper &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didAvoidSingletonOwnerReadyWrapper &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts.didAvoidNativeProbeReadyWrapper &&
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts.didAvoidBackendReadyWrapper

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundary(
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionValue,
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionValue,
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didConfirmNoRuntimeNativeProbeExecutionForValue,
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didKeepProductionSingletonOwnershipTruthFalse,
        runtimeNativeReadinessProbeExecutionValueBoundaryFacts
            .didKeepRuntimeNativeReadinessProbeExecutionValueBoundaryReadinessDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness(
    runtimeNativeReadinessProbeExecutionPreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightReadiness,
    runtimeNativeReadinessProbeExecutionValueBoundary:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundary
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness {
    let facts =
        runtimeNativeReadinessProbeExecutionValueBoundary
            .runtimeNativeReadinessProbeExecutionValueBoundaryFacts
    let admitted =
        runtimeNativeReadinessProbeExecutionValueBoundary
            .didAdmitRuntimeNativeReadinessProbeExecutionValueBoundary

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness(
        runtimeNativeReadinessProbeExecutionPreflightReadiness,
        runtimeNativeReadinessProbeExecutionValueBoundary,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        facts.didOpenRuntimeNativeReadinessProbeExecutionValueBoundary,
        facts.didConfirmRuntimeNativeReadinessProbeExecutionPreflightComplete,
        facts.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionValue,
        facts.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionValue,
        facts.didConfirmNoRuntimeNativeProbeExecutionForValue,
        facts.didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionValue,
        facts.didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight,
        facts.didCarryForwardRuntimeNativeReadinessProbeValueBoundary,
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
        facts.didKeepRuntimeNativeReadinessProbeExecutionValueBoundaryReadinessDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness {
    let runtimeNativeReadinessProbeExecutionPreflightReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightDraft()
    let runtimeNativeReadinessProbeExecutionValueBoundaryFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryFacts(
            runtimeNativeReadinessProbeExecutionPreflightReadiness
        )
    let runtimeNativeReadinessProbeExecutionValueBoundary =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundary(
            runtimeNativeReadinessProbeExecutionValueBoundaryFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness(
        runtimeNativeReadinessProbeExecutionPreflightReadiness,
        runtimeNativeReadinessProbeExecutionValueBoundary
    )
}
