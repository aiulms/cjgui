// 中文维护注释：本文件是 visible-window production harness NSApplication
// application-singleton CJGUI-owned lifecycle main-thread / headless fail-closed
// evidence probe runtime native-readiness probe execution closure value boundary owner。
// Owner: runtime renderer internal CJGUI-owned application lifecycle runtime
// native-readiness probe execution closure value boundary owner。
// Truth: 只消费 runtime native-readiness probe execution closure preflight
// readiness，把 runtime native-readiness probe execution closure value boundary 固定为
// no-accessor / no-bridge-expansion / no-runtime-probe-execution facts；不创建
// singleton，不调用 application accessor，不扩展 native bridge，不执行 native
// probe，不把 readiness 升级成 production singleton ownership truth。
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryFacts {
    let didConsumeRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness:
        Bool
    let didOpenRuntimeNativeReadinessProbeExecutionClosureValueBoundary: Bool
    let didConfirmRuntimeNativeReadinessProbeExecutionClosurePreflightComplete:
        Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureValueBoundary:
        Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureValueBoundary:
        Bool
    let didConfirmNoRuntimeNativeProbeExecutionForClosureValueBoundary: Bool
    let didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureValueBoundary:
        Bool
    let didConfirmExistingOwnerProbeAndForbiddenScan: Bool
    let didCarryForwardRuntimeNativeReadinessProbeExecutionClosurePreflight:
        Bool
    let didCarryForwardRuntimeNativeReadinessProbeExecutionFirstSlice:
        Bool
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
    let didKeepRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadinessDehydrated:
        Bool
    let didRequireFutureRuntimeNativeReadinessProbeExecutionClosureFirstSliceSeparateBoundary:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidSingletonOwnerReadyWrapper: Bool
    let didAvoidNativeProbeReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didConsumeRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness:
            Bool,
        didOpenRuntimeNativeReadinessProbeExecutionClosureValueBoundary: Bool,
        didConfirmRuntimeNativeReadinessProbeExecutionClosurePreflightComplete:
            Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureValueBoundary:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureValueBoundary:
            Bool,
        didConfirmNoRuntimeNativeProbeExecutionForClosureValueBoundary: Bool,
        didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureValueBoundary:
            Bool,
        didConfirmExistingOwnerProbeAndForbiddenScan: Bool,
        didCarryForwardRuntimeNativeReadinessProbeExecutionClosurePreflight:
            Bool,
        didCarryForwardRuntimeNativeReadinessProbeExecutionFirstSlice:
            Bool,
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
        didKeepRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadinessDehydrated:
            Bool,
        didRequireFutureRuntimeNativeReadinessProbeExecutionClosureFirstSliceSeparateBoundary:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidSingletonOwnerReadyWrapper: Bool,
        didAvoidNativeProbeReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didConsumeRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness =
            didConsumeRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness
        this.didOpenRuntimeNativeReadinessProbeExecutionClosureValueBoundary =
            didOpenRuntimeNativeReadinessProbeExecutionClosureValueBoundary
        this.didConfirmRuntimeNativeReadinessProbeExecutionClosurePreflightComplete =
            didConfirmRuntimeNativeReadinessProbeExecutionClosurePreflightComplete
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureValueBoundary =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureValueBoundary
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureValueBoundary =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureValueBoundary
        this.didConfirmNoRuntimeNativeProbeExecutionForClosureValueBoundary =
            didConfirmNoRuntimeNativeProbeExecutionForClosureValueBoundary
        this.didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureValueBoundary =
            didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureValueBoundary
        this.didConfirmExistingOwnerProbeAndForbiddenScan =
            didConfirmExistingOwnerProbeAndForbiddenScan
        this.didCarryForwardRuntimeNativeReadinessProbeExecutionClosurePreflight =
            didCarryForwardRuntimeNativeReadinessProbeExecutionClosurePreflight
        this.didCarryForwardRuntimeNativeReadinessProbeExecutionFirstSlice =
            didCarryForwardRuntimeNativeReadinessProbeExecutionFirstSlice
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
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadinessDehydrated
        this.didRequireFutureRuntimeNativeReadinessProbeExecutionClosureFirstSliceSeparateBoundary =
            didRequireFutureRuntimeNativeReadinessProbeExecutionClosureFirstSliceSeparateBoundary
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidSingletonOwnerReadyWrapper =
            didAvoidSingletonOwnerReadyWrapper
        this.didAvoidNativeProbeReadyWrapper = didAvoidNativeProbeReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundary {
    let runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
    let didAdmitRuntimeNativeReadinessProbeExecutionClosureValueBoundary: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeNativeProbeExecution: Bool
    let shouldReportRuntimeNativeReadinessProbeExecutionClosureValueBoundaryBlocked:
        Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureValueBoundary:
        Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureValueBoundary:
        Bool
    let didConfirmNoRuntimeNativeProbeExecutionForClosureValueBoundary: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadinessDehydrated:
        Bool

    init(
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryFacts,
        didAdmitRuntimeNativeReadinessProbeExecutionClosureValueBoundary: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeNativeProbeExecution: Bool,
        shouldReportRuntimeNativeReadinessProbeExecutionClosureValueBoundaryBlocked:
            Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureValueBoundary:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureValueBoundary:
            Bool,
        didConfirmNoRuntimeNativeProbeExecutionForClosureValueBoundary: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadinessDehydrated:
            Bool
    ) {
        this.runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts =
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
        this.didAdmitRuntimeNativeReadinessProbeExecutionClosureValueBoundary =
            didAdmitRuntimeNativeReadinessProbeExecutionClosureValueBoundary
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeNativeProbeExecution =
            shouldDeferRuntimeNativeProbeExecution
        this.shouldReportRuntimeNativeReadinessProbeExecutionClosureValueBoundaryBlocked =
            shouldReportRuntimeNativeReadinessProbeExecutionClosureValueBoundaryBlocked
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureValueBoundary =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureValueBoundary
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureValueBoundary =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureValueBoundary
        this.didConfirmNoRuntimeNativeProbeExecutionForClosureValueBoundary =
            didConfirmNoRuntimeNativeProbeExecutionForClosureValueBoundary
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadinessDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness {
    let runtimeNativeReadinessProbeExecutionClosurePreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness
    let runtimeNativeReadinessProbeExecutionClosureValueBoundary:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundary
    let didPrepareRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness:
        Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeNativeProbeExecution: Bool
    let shouldReportRuntimeNativeReadinessProbeExecutionClosureValueBoundaryBlocked:
        Bool
    let didOpenRuntimeNativeReadinessProbeExecutionClosureValueBoundary: Bool
    let didConfirmRuntimeNativeReadinessProbeExecutionClosurePreflightComplete:
        Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureValueBoundary:
        Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureValueBoundary:
        Bool
    let didConfirmNoRuntimeNativeProbeExecutionForClosureValueBoundary: Bool
    let didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureValueBoundary:
        Bool
    let didCarryForwardRuntimeNativeReadinessProbeExecutionClosurePreflight:
        Bool
    let didCarryForwardRuntimeNativeReadinessProbeExecutionFirstSlice:
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
    let didKeepRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadinessDehydrated:
        Bool

    init(
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness,
        runtimeNativeReadinessProbeExecutionClosureValueBoundary:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundary,
        didPrepareRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness:
            Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeNativeProbeExecution: Bool,
        shouldReportRuntimeNativeReadinessProbeExecutionClosureValueBoundaryBlocked:
            Bool,
        didOpenRuntimeNativeReadinessProbeExecutionClosureValueBoundary: Bool,
        didConfirmRuntimeNativeReadinessProbeExecutionClosurePreflightComplete:
            Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureValueBoundary:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureValueBoundary:
            Bool,
        didConfirmNoRuntimeNativeProbeExecutionForClosureValueBoundary: Bool,
        didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureValueBoundary:
            Bool,
        didCarryForwardRuntimeNativeReadinessProbeExecutionClosurePreflight:
            Bool,
        didCarryForwardRuntimeNativeReadinessProbeExecutionFirstSlice:
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
        didKeepRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadinessDehydrated:
            Bool
    ) {
        this.runtimeNativeReadinessProbeExecutionClosurePreflightReadiness =
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
        this.runtimeNativeReadinessProbeExecutionClosureValueBoundary =
            runtimeNativeReadinessProbeExecutionClosureValueBoundary
        this.didPrepareRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness =
            didPrepareRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeNativeProbeExecution =
            shouldDeferRuntimeNativeProbeExecution
        this.shouldReportRuntimeNativeReadinessProbeExecutionClosureValueBoundaryBlocked =
            shouldReportRuntimeNativeReadinessProbeExecutionClosureValueBoundaryBlocked
        this.didOpenRuntimeNativeReadinessProbeExecutionClosureValueBoundary =
            didOpenRuntimeNativeReadinessProbeExecutionClosureValueBoundary
        this.didConfirmRuntimeNativeReadinessProbeExecutionClosurePreflightComplete =
            didConfirmRuntimeNativeReadinessProbeExecutionClosurePreflightComplete
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureValueBoundary =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureValueBoundary
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureValueBoundary =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureValueBoundary
        this.didConfirmNoRuntimeNativeProbeExecutionForClosureValueBoundary =
            didConfirmNoRuntimeNativeProbeExecutionForClosureValueBoundary
        this.didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureValueBoundary =
            didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureValueBoundary
        this.didCarryForwardRuntimeNativeReadinessProbeExecutionClosurePreflight =
            didCarryForwardRuntimeNativeReadinessProbeExecutionClosurePreflight
        this.didCarryForwardRuntimeNativeReadinessProbeExecutionFirstSlice =
            didCarryForwardRuntimeNativeReadinessProbeExecutionFirstSlice
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
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryFacts(
    runtimeNativeReadinessProbeExecutionClosurePreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryFacts {
    let closurePreflightFacts =
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .runtimeNativeReadinessProbeExecutionClosurePreflight
            .runtimeNativeReadinessProbeExecutionClosurePreflightFacts
    let closurePreflightReady =
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didPrepareRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .shouldDeferProductionSingletonOwnerImplementation &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .shouldDeferApplicationSingletonAccessorCall &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .shouldDeferCleanupTeardownExecution &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .shouldDeferRuntimeNativeProbeExecution &&
        !runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .shouldReportRuntimeNativeReadinessProbeExecutionClosurePreflightBlocked &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didOpenRuntimeNativeReadinessProbeExecutionClosurePreflight &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didConfirmRuntimeNativeReadinessProbeExecutionFirstSliceComplete &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosurePreflight &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosurePreflight &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didConfirmNoRuntimeNativeProbeExecutionForClosurePreflight &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosurePreflight &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didCarryForwardRuntimeNativeReadinessProbeExecutionFirstSlice &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didCarryForwardRuntimeNativeReadinessProbeValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didCarryForwardRuntimeNativeReadinessProbePreflight &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didCarryForwardNativeReadinessValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didCarryForwardScanOnlyNativeReadinessEvidence &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didCarryForwardNoSideEffectEvidenceOnly &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didCarryForwardMainThreadCreationConfinement &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didDeferActivation &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didDeferActivationPolicyMutation &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didDeferAppKitEventLoop &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didDeferBoundedRunLoopPump &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didDeferVisibleOrder &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didDeferDrawableAndRender &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didBlockArtifactPublicDiagnosticsPublication &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didConfirmNoPublicApi &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didConfirmNoProductionPublicCAbi &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didConfirmNoRendererStateWrite &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didConfirmNoRuntimeStateWrite &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didConfirmNoCjpmTomlChange &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didKeepProductionSingletonOwnershipTruthFalse &&
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
            .didKeepRuntimeNativeReadinessProbeExecutionClosurePreflightReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryFacts(
        closurePreflightReady,
        closurePreflightReady,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didOpenRuntimeNativeReadinessProbeExecutionClosurePreflight,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosurePreflight,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosurePreflight,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didConfirmNoRuntimeNativeProbeExecutionForClosurePreflight,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosurePreflight,
        closurePreflightReady && closurePreflightFacts.didConfirmExistingOwnerProbeAndForbiddenScan,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didOpenRuntimeNativeReadinessProbeExecutionClosurePreflight,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didCarryForwardRuntimeNativeReadinessProbeExecutionFirstSlice,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didCarryForwardRuntimeNativeReadinessProbeValueBoundary,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didCarryForwardRuntimeNativeReadinessProbePreflight,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didCarryForwardNativeReadinessValueBoundary,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didCarryForwardScanOnlyNativeReadinessEvidence,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didCarryForwardNoSideEffectEvidenceOnly,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didCarryForwardMainThreadCreationConfinement,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .shouldDeferProductionSingletonOwnerImplementation,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .shouldDeferApplicationSingletonAccessorCall,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .shouldDeferCleanupTeardownExecution,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .shouldDeferRuntimeNativeProbeExecution,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didDeferActivation,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didDeferActivationPolicyMutation,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didDeferAppKitEventLoop,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didDeferBoundedRunLoopPump,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didDeferVisibleOrder,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didDeferDrawableAndRender,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didBlockArtifactPublicDiagnosticsPublication,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didConfirmNoPublicApi,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didConfirmNoProductionPublicCAbi,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didConfirmNoRendererStateWrite,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didConfirmNoRuntimeStateWrite,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didConfirmNoCjpmTomlChange,
        closurePreflightReady &&
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
                .didKeepProductionSingletonOwnershipTruthFalse,
        closurePreflightReady,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundary(
    runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundary {
    let admitted =
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didConsumeRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didOpenRuntimeNativeReadinessProbeExecutionClosureValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didConfirmRuntimeNativeReadinessProbeExecutionClosurePreflightComplete &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didConfirmNoRuntimeNativeProbeExecutionForClosureValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didConfirmExistingOwnerProbeAndForbiddenScan &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didCarryForwardRuntimeNativeReadinessProbeExecutionClosurePreflight &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didCarryForwardRuntimeNativeReadinessProbeExecutionFirstSlice &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didCarryForwardRuntimeNativeReadinessProbeValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didCarryForwardRuntimeNativeReadinessProbePreflight &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didCarryForwardNativeReadinessValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didCarryForwardScanOnlyNativeReadinessEvidence &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didCarryForwardNoSideEffectEvidenceOnly &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didCarryForwardMainThreadCreationConfinement &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didDeferProductionSingletonOwnerImplementation &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didDeferApplicationSingletonAccessorCall &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didDeferCleanupTeardownExecution &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didDeferRuntimeNativeProbeExecution &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts.didDeferActivation &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didDeferActivationPolicyMutation &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didDeferAppKitEventLoop &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didDeferBoundedRunLoopPump &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts.didDeferVisibleOrder &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didDeferDrawableAndRender &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didBlockArtifactPublicDiagnosticsPublication &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts.didConfirmNoPublicApi &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didConfirmNoProductionPublicCAbi &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didConfirmNoRendererStateWrite &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didConfirmNoRuntimeStateWrite &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts.didConfirmNoCjpmTomlChange &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didKeepProductionSingletonOwnershipTruthFalse &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didKeepRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadinessDehydrated &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didRequireFutureRuntimeNativeReadinessProbeExecutionClosureFirstSliceSeparateBoundary &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts.didAvoidApplicationReadyWrapper &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didAvoidSingletonOwnerReadyWrapper &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts.didAvoidNativeProbeReadyWrapper &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts.didAvoidBackendReadyWrapper

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundary(
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureValueBoundary,
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureValueBoundary,
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didConfirmNoRuntimeNativeProbeExecutionForClosureValueBoundary,
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didKeepProductionSingletonOwnershipTruthFalse,
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
            .didKeepRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadinessDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness(
    runtimeNativeReadinessProbeExecutionClosurePreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness,
    runtimeNativeReadinessProbeExecutionClosureValueBoundary:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundary
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness {
    let facts =
        runtimeNativeReadinessProbeExecutionClosureValueBoundary
            .runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
    let admitted =
        runtimeNativeReadinessProbeExecutionClosureValueBoundary
            .didAdmitRuntimeNativeReadinessProbeExecutionClosureValueBoundary

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness(
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness,
        runtimeNativeReadinessProbeExecutionClosureValueBoundary,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        facts.didOpenRuntimeNativeReadinessProbeExecutionClosureValueBoundary,
        facts.didConfirmRuntimeNativeReadinessProbeExecutionClosurePreflightComplete,
        facts.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureValueBoundary,
        facts.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureValueBoundary,
        facts.didConfirmNoRuntimeNativeProbeExecutionForClosureValueBoundary,
        facts.didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureValueBoundary,
        facts.didCarryForwardRuntimeNativeReadinessProbeExecutionClosurePreflight,
        facts.didCarryForwardRuntimeNativeReadinessProbeExecutionFirstSlice,
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
        facts.didKeepRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadinessDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness {
    let runtimeNativeReadinessProbeExecutionClosurePreflightReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightDraft()
    let runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryFacts(
            runtimeNativeReadinessProbeExecutionClosurePreflightReadiness
        )
    let runtimeNativeReadinessProbeExecutionClosureValueBoundary =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundary(
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness(
        runtimeNativeReadinessProbeExecutionClosurePreflightReadiness,
        runtimeNativeReadinessProbeExecutionClosureValueBoundary
    )
}
