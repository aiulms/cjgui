// 中文维护注释：本文件是 visible-window production harness NSApplication
// application-singleton CJGUI-owned lifecycle main-thread / headless fail-closed
// evidence probe runtime native-readiness probe execution preflight owner。
// Owner: runtime renderer internal CJGUI-owned application lifecycle runtime
// native-readiness probe execution preflight owner。
// Truth: 只消费 runtime native-readiness probe value boundary readiness，把
// runtime native-readiness probe execution preflight 固定为 no-accessor /
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightFacts {
    let didConsumeRuntimeNativeReadinessProbeValueBoundaryReadiness: Bool
    let didOpenRuntimeNativeReadinessProbeExecutionPreflight: Bool
    let didRequireRuntimeNativeReadinessProbeExecutionPreflightBeforeExecution:
        Bool
    let didRequireNoApplicationAccessorCallForRuntimeNativeProbeExecutionPreflight:
        Bool
    let didRequireNoNativeBridgeExpansionForRuntimeNativeProbeExecutionPreflight:
        Bool
    let didRequireNoRuntimeNativeProbeExecutionForPreflight: Bool
    let didRequireNoSingletonCreationDuringRuntimeNativeProbeExecutionPreflight:
        Bool
    let didConfirmExistingOwnerProbeAndForbiddenScan: Bool
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
    let didKeepRuntimeNativeReadinessProbeExecutionPreflightReadinessDehydrated:
        Bool
    let didRequireFutureRuntimeNativeReadinessProbeExecutionValueBoundarySeparateBoundary:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidSingletonOwnerReadyWrapper: Bool
    let didAvoidNativeProbeReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didConsumeRuntimeNativeReadinessProbeValueBoundaryReadiness: Bool,
        didOpenRuntimeNativeReadinessProbeExecutionPreflight: Bool,
        didRequireRuntimeNativeReadinessProbeExecutionPreflightBeforeExecution:
            Bool,
        didRequireNoApplicationAccessorCallForRuntimeNativeProbeExecutionPreflight:
            Bool,
        didRequireNoNativeBridgeExpansionForRuntimeNativeProbeExecutionPreflight:
            Bool,
        didRequireNoRuntimeNativeProbeExecutionForPreflight: Bool,
        didRequireNoSingletonCreationDuringRuntimeNativeProbeExecutionPreflight:
            Bool,
        didConfirmExistingOwnerProbeAndForbiddenScan: Bool,
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
        didKeepRuntimeNativeReadinessProbeExecutionPreflightReadinessDehydrated:
            Bool,
        didRequireFutureRuntimeNativeReadinessProbeExecutionValueBoundarySeparateBoundary:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidSingletonOwnerReadyWrapper: Bool,
        didAvoidNativeProbeReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didConsumeRuntimeNativeReadinessProbeValueBoundaryReadiness =
            didConsumeRuntimeNativeReadinessProbeValueBoundaryReadiness
        this.didOpenRuntimeNativeReadinessProbeExecutionPreflight =
            didOpenRuntimeNativeReadinessProbeExecutionPreflight
        this.didRequireRuntimeNativeReadinessProbeExecutionPreflightBeforeExecution =
            didRequireRuntimeNativeReadinessProbeExecutionPreflightBeforeExecution
        this.didRequireNoApplicationAccessorCallForRuntimeNativeProbeExecutionPreflight =
            didRequireNoApplicationAccessorCallForRuntimeNativeProbeExecutionPreflight
        this.didRequireNoNativeBridgeExpansionForRuntimeNativeProbeExecutionPreflight =
            didRequireNoNativeBridgeExpansionForRuntimeNativeProbeExecutionPreflight
        this.didRequireNoRuntimeNativeProbeExecutionForPreflight =
            didRequireNoRuntimeNativeProbeExecutionForPreflight
        this.didRequireNoSingletonCreationDuringRuntimeNativeProbeExecutionPreflight =
            didRequireNoSingletonCreationDuringRuntimeNativeProbeExecutionPreflight
        this.didConfirmExistingOwnerProbeAndForbiddenScan =
            didConfirmExistingOwnerProbeAndForbiddenScan
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
        this.didKeepRuntimeNativeReadinessProbeExecutionPreflightReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionPreflightReadinessDehydrated
        this.didRequireFutureRuntimeNativeReadinessProbeExecutionValueBoundarySeparateBoundary =
            didRequireFutureRuntimeNativeReadinessProbeExecutionValueBoundarySeparateBoundary
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidSingletonOwnerReadyWrapper =
            didAvoidSingletonOwnerReadyWrapper
        this.didAvoidNativeProbeReadyWrapper = didAvoidNativeProbeReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflight {
    let runtimeNativeReadinessProbeExecutionPreflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightFacts
    let didAdmitRuntimeNativeReadinessProbeExecutionPreflight: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeNativeProbeExecution: Bool
    let shouldReportRuntimeNativeReadinessProbeExecutionPreflightBlocked:
        Bool
    let didRequireNoApplicationAccessorCallForRuntimeNativeProbeExecutionPreflight:
        Bool
    let didRequireNoNativeBridgeExpansionForRuntimeNativeProbeExecutionPreflight:
        Bool
    let didRequireNoRuntimeNativeProbeExecutionForPreflight: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepRuntimeNativeReadinessProbeExecutionPreflightReadinessDehydrated:
        Bool

    init(
        runtimeNativeReadinessProbeExecutionPreflightFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightFacts,
        didAdmitRuntimeNativeReadinessProbeExecutionPreflight: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeNativeProbeExecution: Bool,
        shouldReportRuntimeNativeReadinessProbeExecutionPreflightBlocked:
            Bool,
        didRequireNoApplicationAccessorCallForRuntimeNativeProbeExecutionPreflight:
            Bool,
        didRequireNoNativeBridgeExpansionForRuntimeNativeProbeExecutionPreflight:
            Bool,
        didRequireNoRuntimeNativeProbeExecutionForPreflight: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepRuntimeNativeReadinessProbeExecutionPreflightReadinessDehydrated:
            Bool
    ) {
        this.runtimeNativeReadinessProbeExecutionPreflightFacts =
            runtimeNativeReadinessProbeExecutionPreflightFacts
        this.didAdmitRuntimeNativeReadinessProbeExecutionPreflight =
            didAdmitRuntimeNativeReadinessProbeExecutionPreflight
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeNativeProbeExecution =
            shouldDeferRuntimeNativeProbeExecution
        this.shouldReportRuntimeNativeReadinessProbeExecutionPreflightBlocked =
            shouldReportRuntimeNativeReadinessProbeExecutionPreflightBlocked
        this.didRequireNoApplicationAccessorCallForRuntimeNativeProbeExecutionPreflight =
            didRequireNoApplicationAccessorCallForRuntimeNativeProbeExecutionPreflight
        this.didRequireNoNativeBridgeExpansionForRuntimeNativeProbeExecutionPreflight =
            didRequireNoNativeBridgeExpansionForRuntimeNativeProbeExecutionPreflight
        this.didRequireNoRuntimeNativeProbeExecutionForPreflight =
            didRequireNoRuntimeNativeProbeExecutionForPreflight
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepRuntimeNativeReadinessProbeExecutionPreflightReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionPreflightReadinessDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightReadiness {
    let runtimeNativeReadinessProbeValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryReadiness
    let runtimeNativeReadinessProbeExecutionPreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflight
    let didPrepareRuntimeNativeReadinessProbeExecutionPreflightReadiness:
        Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeNativeProbeExecution: Bool
    let shouldReportRuntimeNativeReadinessProbeExecutionPreflightBlocked:
        Bool
    let didOpenRuntimeNativeReadinessProbeExecutionPreflight: Bool
    let didRequireRuntimeNativeReadinessProbeExecutionPreflightBeforeExecution:
        Bool
    let didRequireNoApplicationAccessorCallForRuntimeNativeProbeExecutionPreflight:
        Bool
    let didRequireNoNativeBridgeExpansionForRuntimeNativeProbeExecutionPreflight:
        Bool
    let didRequireNoRuntimeNativeProbeExecutionForPreflight: Bool
    let didRequireNoSingletonCreationDuringRuntimeNativeProbeExecutionPreflight:
        Bool
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
    let didKeepRuntimeNativeReadinessProbeExecutionPreflightReadinessDehydrated:
        Bool

    init(
        runtimeNativeReadinessProbeValueBoundaryReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryReadiness,
        runtimeNativeReadinessProbeExecutionPreflight:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflight,
        didPrepareRuntimeNativeReadinessProbeExecutionPreflightReadiness:
            Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeNativeProbeExecution: Bool,
        shouldReportRuntimeNativeReadinessProbeExecutionPreflightBlocked:
            Bool,
        didOpenRuntimeNativeReadinessProbeExecutionPreflight: Bool,
        didRequireRuntimeNativeReadinessProbeExecutionPreflightBeforeExecution:
            Bool,
        didRequireNoApplicationAccessorCallForRuntimeNativeProbeExecutionPreflight:
            Bool,
        didRequireNoNativeBridgeExpansionForRuntimeNativeProbeExecutionPreflight:
            Bool,
        didRequireNoRuntimeNativeProbeExecutionForPreflight: Bool,
        didRequireNoSingletonCreationDuringRuntimeNativeProbeExecutionPreflight:
            Bool,
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
        didKeepRuntimeNativeReadinessProbeExecutionPreflightReadinessDehydrated:
            Bool
    ) {
        this.runtimeNativeReadinessProbeValueBoundaryReadiness =
            runtimeNativeReadinessProbeValueBoundaryReadiness
        this.runtimeNativeReadinessProbeExecutionPreflight =
            runtimeNativeReadinessProbeExecutionPreflight
        this.didPrepareRuntimeNativeReadinessProbeExecutionPreflightReadiness =
            didPrepareRuntimeNativeReadinessProbeExecutionPreflightReadiness
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeNativeProbeExecution =
            shouldDeferRuntimeNativeProbeExecution
        this.shouldReportRuntimeNativeReadinessProbeExecutionPreflightBlocked =
            shouldReportRuntimeNativeReadinessProbeExecutionPreflightBlocked
        this.didOpenRuntimeNativeReadinessProbeExecutionPreflight =
            didOpenRuntimeNativeReadinessProbeExecutionPreflight
        this.didRequireRuntimeNativeReadinessProbeExecutionPreflightBeforeExecution =
            didRequireRuntimeNativeReadinessProbeExecutionPreflightBeforeExecution
        this.didRequireNoApplicationAccessorCallForRuntimeNativeProbeExecutionPreflight =
            didRequireNoApplicationAccessorCallForRuntimeNativeProbeExecutionPreflight
        this.didRequireNoNativeBridgeExpansionForRuntimeNativeProbeExecutionPreflight =
            didRequireNoNativeBridgeExpansionForRuntimeNativeProbeExecutionPreflight
        this.didRequireNoRuntimeNativeProbeExecutionForPreflight =
            didRequireNoRuntimeNativeProbeExecutionForPreflight
        this.didRequireNoSingletonCreationDuringRuntimeNativeProbeExecutionPreflight =
            didRequireNoSingletonCreationDuringRuntimeNativeProbeExecutionPreflight
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
        this.didKeepRuntimeNativeReadinessProbeExecutionPreflightReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionPreflightReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightFacts(
    runtimeNativeReadinessProbeValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightFacts {
    let valueBoundaryFacts =
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .runtimeNativeReadinessProbeValueBoundary
            .runtimeNativeReadinessProbeValueBoundaryFacts
    let valueBoundaryReady =
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didPrepareRuntimeNativeReadinessProbeValueBoundaryReadiness &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .shouldDeferProductionSingletonOwnerImplementation &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .shouldDeferApplicationSingletonAccessorCall &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .shouldDeferCleanupTeardownExecution &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .shouldDeferRuntimeNativeProbeExecution &&
        !runtimeNativeReadinessProbeValueBoundaryReadiness
            .shouldReportRuntimeNativeReadinessProbeValueBoundaryBlocked &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didOpenRuntimeNativeReadinessProbeValueBoundary &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didConfirmRuntimeNativeReadinessProbePreflightComplete &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeValue &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeValue &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didConfirmNoRuntimeNativeProbeExecutionForValue &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didConfirmNoSingletonCreationDuringRuntimeNativeProbeValue &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didCarryForwardRuntimeNativeReadinessProbePreflight &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didCarryForwardNativeReadinessValueBoundary &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didCarryForwardScanOnlyNativeReadinessEvidence &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didCarryForwardNoSideEffectEvidenceOnly &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didCarryForwardMainThreadCreationConfinement &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        runtimeNativeReadinessProbeValueBoundaryReadiness.didDeferActivation &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didDeferActivationPolicyMutation &&
        runtimeNativeReadinessProbeValueBoundaryReadiness.didDeferAppKitEventLoop &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didDeferBoundedRunLoopPump &&
        runtimeNativeReadinessProbeValueBoundaryReadiness.didDeferVisibleOrder &&
        runtimeNativeReadinessProbeValueBoundaryReadiness.didDeferDrawableAndRender &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didBlockArtifactPublicDiagnosticsPublication &&
        runtimeNativeReadinessProbeValueBoundaryReadiness.didConfirmNoPublicApi &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didConfirmNoProductionPublicCAbi &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didConfirmNoRendererStateWrite &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didConfirmNoRuntimeStateWrite &&
        runtimeNativeReadinessProbeValueBoundaryReadiness.didConfirmNoCjpmTomlChange &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didKeepProductionSingletonOwnershipTruthFalse &&
        runtimeNativeReadinessProbeValueBoundaryReadiness
            .didKeepRuntimeNativeReadinessProbeValueBoundaryReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightFacts(
        valueBoundaryReady,
        valueBoundaryReady,
        valueBoundaryReady,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeValue,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeValue,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .didConfirmNoRuntimeNativeProbeExecutionForValue,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .didConfirmNoSingletonCreationDuringRuntimeNativeProbeValue,
        valueBoundaryReady && valueBoundaryFacts.didConfirmExistingOwnerProbeAndForbiddenScan,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .didOpenRuntimeNativeReadinessProbeValueBoundary,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .didCarryForwardRuntimeNativeReadinessProbePreflight,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .didCarryForwardNativeReadinessValueBoundary,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .didCarryForwardScanOnlyNativeReadinessEvidence,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .didCarryForwardNoSideEffectEvidenceOnly,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .didCarryForwardMainThreadCreationConfinement,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .shouldDeferProductionSingletonOwnerImplementation,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .shouldDeferApplicationSingletonAccessorCall,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .shouldDeferCleanupTeardownExecution,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .shouldDeferRuntimeNativeProbeExecution,
        valueBoundaryReady && runtimeNativeReadinessProbeValueBoundaryReadiness.didDeferActivation,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .didDeferActivationPolicyMutation,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness.didDeferAppKitEventLoop,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .didDeferBoundedRunLoopPump,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness.didDeferVisibleOrder,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness.didDeferDrawableAndRender,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .didBlockArtifactPublicDiagnosticsPublication,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness.didConfirmNoPublicApi,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .didConfirmNoProductionPublicCAbi,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .didConfirmNoRendererStateWrite,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .didConfirmNoRuntimeStateWrite,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness.didConfirmNoCjpmTomlChange,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeValueBoundaryReadiness
                .didKeepProductionSingletonOwnershipTruthFalse,
        valueBoundaryReady,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflight(
    runtimeNativeReadinessProbeExecutionPreflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflight {
    let admitted =
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didConsumeRuntimeNativeReadinessProbeValueBoundaryReadiness &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didOpenRuntimeNativeReadinessProbeExecutionPreflight &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didRequireRuntimeNativeReadinessProbeExecutionPreflightBeforeExecution &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didRequireNoApplicationAccessorCallForRuntimeNativeProbeExecutionPreflight &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didRequireNoNativeBridgeExpansionForRuntimeNativeProbeExecutionPreflight &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didRequireNoRuntimeNativeProbeExecutionForPreflight &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didRequireNoSingletonCreationDuringRuntimeNativeProbeExecutionPreflight &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didConfirmExistingOwnerProbeAndForbiddenScan &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didCarryForwardRuntimeNativeReadinessProbeValueBoundary &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didCarryForwardRuntimeNativeReadinessProbePreflight &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didCarryForwardNativeReadinessValueBoundary &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didCarryForwardScanOnlyNativeReadinessEvidence &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didCarryForwardNoSideEffectEvidenceOnly &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didCarryForwardMainThreadCreationConfinement &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didDeferProductionSingletonOwnerImplementation &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didDeferApplicationSingletonAccessorCall &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didDeferCleanupTeardownExecution &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didDeferRuntimeNativeProbeExecution &&
        runtimeNativeReadinessProbeExecutionPreflightFacts.didDeferActivation &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didDeferActivationPolicyMutation &&
        runtimeNativeReadinessProbeExecutionPreflightFacts.didDeferAppKitEventLoop &&
        runtimeNativeReadinessProbeExecutionPreflightFacts.didDeferBoundedRunLoopPump &&
        runtimeNativeReadinessProbeExecutionPreflightFacts.didDeferVisibleOrder &&
        runtimeNativeReadinessProbeExecutionPreflightFacts.didDeferDrawableAndRender &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didBlockArtifactPublicDiagnosticsPublication &&
        runtimeNativeReadinessProbeExecutionPreflightFacts.didConfirmNoPublicApi &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didConfirmNoProductionPublicCAbi &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didConfirmNoRendererStateWrite &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didConfirmNoRuntimeStateWrite &&
        runtimeNativeReadinessProbeExecutionPreflightFacts.didConfirmNoCjpmTomlChange &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didKeepProductionSingletonOwnershipTruthFalse &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didKeepRuntimeNativeReadinessProbeExecutionPreflightReadinessDehydrated &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didRequireFutureRuntimeNativeReadinessProbeExecutionValueBoundarySeparateBoundary &&
        runtimeNativeReadinessProbeExecutionPreflightFacts.didAvoidApplicationReadyWrapper &&
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didAvoidSingletonOwnerReadyWrapper &&
        runtimeNativeReadinessProbeExecutionPreflightFacts.didAvoidNativeProbeReadyWrapper &&
        runtimeNativeReadinessProbeExecutionPreflightFacts.didAvoidBackendReadyWrapper

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflight(
        runtimeNativeReadinessProbeExecutionPreflightFacts,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didRequireNoApplicationAccessorCallForRuntimeNativeProbeExecutionPreflight,
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didRequireNoNativeBridgeExpansionForRuntimeNativeProbeExecutionPreflight,
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didRequireNoRuntimeNativeProbeExecutionForPreflight,
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didKeepProductionSingletonOwnershipTruthFalse,
        runtimeNativeReadinessProbeExecutionPreflightFacts
            .didKeepRuntimeNativeReadinessProbeExecutionPreflightReadinessDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightReadiness(
    runtimeNativeReadinessProbeValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryReadiness,
    runtimeNativeReadinessProbeExecutionPreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflight
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightReadiness {
    let facts =
        runtimeNativeReadinessProbeExecutionPreflight
            .runtimeNativeReadinessProbeExecutionPreflightFacts
    let admitted =
        runtimeNativeReadinessProbeExecutionPreflight
            .didAdmitRuntimeNativeReadinessProbeExecutionPreflight

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightReadiness(
        runtimeNativeReadinessProbeValueBoundaryReadiness,
        runtimeNativeReadinessProbeExecutionPreflight,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        facts.didOpenRuntimeNativeReadinessProbeExecutionPreflight,
        facts.didRequireRuntimeNativeReadinessProbeExecutionPreflightBeforeExecution,
        facts.didRequireNoApplicationAccessorCallForRuntimeNativeProbeExecutionPreflight,
        facts.didRequireNoNativeBridgeExpansionForRuntimeNativeProbeExecutionPreflight,
        facts.didRequireNoRuntimeNativeProbeExecutionForPreflight,
        facts.didRequireNoSingletonCreationDuringRuntimeNativeProbeExecutionPreflight,
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
        facts.didKeepRuntimeNativeReadinessProbeExecutionPreflightReadinessDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightReadiness {
    let runtimeNativeReadinessProbeValueBoundaryReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryDraft()
    let runtimeNativeReadinessProbeExecutionPreflightFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightFacts(
            runtimeNativeReadinessProbeValueBoundaryReadiness
        )
    let runtimeNativeReadinessProbeExecutionPreflight =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflight(
            runtimeNativeReadinessProbeExecutionPreflightFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightReadiness(
        runtimeNativeReadinessProbeValueBoundaryReadiness,
        runtimeNativeReadinessProbeExecutionPreflight
    )
}
