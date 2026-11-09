// 中文维护注释：本文件是 visible-window production harness NSApplication
// application-singleton CJGUI-owned lifecycle main-thread / headless fail-closed
// evidence probe runtime native-readiness probe execution closure preflight owner。
// Owner: runtime renderer internal CJGUI-owned application lifecycle runtime
// native-readiness probe execution closure preflight owner。
// Truth: 只消费 runtime native-readiness probe execution first slice
// readiness，把 runtime native-readiness probe execution closure preflight 固定为
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightFacts {
    let didConsumeRuntimeNativeReadinessProbeExecutionFirstSliceReadiness:
        Bool
    let didOpenRuntimeNativeReadinessProbeExecutionClosurePreflight: Bool
    let didConfirmRuntimeNativeReadinessProbeExecutionFirstSliceComplete:
        Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosurePreflight:
        Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosurePreflight:
        Bool
    let didConfirmNoRuntimeNativeProbeExecutionForClosurePreflight: Bool
    let didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosurePreflight:
        Bool
    let didConfirmExistingOwnerProbeAndForbiddenScan: Bool
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
    let didKeepRuntimeNativeReadinessProbeExecutionClosurePreflightReadinessDehydrated:
        Bool
    let didRequireFutureRuntimeNativeReadinessProbeExecutionClosureValueBoundarySeparateBoundary:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidSingletonOwnerReadyWrapper: Bool
    let didAvoidNativeProbeReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didConsumeRuntimeNativeReadinessProbeExecutionFirstSliceReadiness:
            Bool,
        didOpenRuntimeNativeReadinessProbeExecutionClosurePreflight: Bool,
        didConfirmRuntimeNativeReadinessProbeExecutionFirstSliceComplete:
            Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosurePreflight:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosurePreflight:
            Bool,
        didConfirmNoRuntimeNativeProbeExecutionForClosurePreflight: Bool,
        didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosurePreflight:
            Bool,
        didConfirmExistingOwnerProbeAndForbiddenScan: Bool,
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
        didKeepRuntimeNativeReadinessProbeExecutionClosurePreflightReadinessDehydrated:
            Bool,
        didRequireFutureRuntimeNativeReadinessProbeExecutionClosureValueBoundarySeparateBoundary:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidSingletonOwnerReadyWrapper: Bool,
        didAvoidNativeProbeReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didConsumeRuntimeNativeReadinessProbeExecutionFirstSliceReadiness =
            didConsumeRuntimeNativeReadinessProbeExecutionFirstSliceReadiness
        this.didOpenRuntimeNativeReadinessProbeExecutionClosurePreflight =
            didOpenRuntimeNativeReadinessProbeExecutionClosurePreflight
        this.didConfirmRuntimeNativeReadinessProbeExecutionFirstSliceComplete =
            didConfirmRuntimeNativeReadinessProbeExecutionFirstSliceComplete
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosurePreflight =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosurePreflight
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosurePreflight =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosurePreflight
        this.didConfirmNoRuntimeNativeProbeExecutionForClosurePreflight =
            didConfirmNoRuntimeNativeProbeExecutionForClosurePreflight
        this.didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosurePreflight =
            didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosurePreflight
        this.didConfirmExistingOwnerProbeAndForbiddenScan =
            didConfirmExistingOwnerProbeAndForbiddenScan
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
        this.didKeepRuntimeNativeReadinessProbeExecutionClosurePreflightReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionClosurePreflightReadinessDehydrated
        this.didRequireFutureRuntimeNativeReadinessProbeExecutionClosureValueBoundarySeparateBoundary =
            didRequireFutureRuntimeNativeReadinessProbeExecutionClosureValueBoundarySeparateBoundary
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidSingletonOwnerReadyWrapper =
            didAvoidSingletonOwnerReadyWrapper
        this.didAvoidNativeProbeReadyWrapper = didAvoidNativeProbeReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflight {
    let runtimeNativeReadinessProbeExecutionClosurePreflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightFacts
    let didAdmitRuntimeNativeReadinessProbeExecutionClosurePreflight: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeNativeProbeExecution: Bool
    let shouldReportRuntimeNativeReadinessProbeExecutionClosurePreflightBlocked:
        Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosurePreflight:
        Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosurePreflight:
        Bool
    let didConfirmNoRuntimeNativeProbeExecutionForClosurePreflight: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepRuntimeNativeReadinessProbeExecutionClosurePreflightReadinessDehydrated:
        Bool

    init(
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightFacts,
        didAdmitRuntimeNativeReadinessProbeExecutionClosurePreflight: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeNativeProbeExecution: Bool,
        shouldReportRuntimeNativeReadinessProbeExecutionClosurePreflightBlocked:
            Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosurePreflight:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosurePreflight:
            Bool,
        didConfirmNoRuntimeNativeProbeExecutionForClosurePreflight: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepRuntimeNativeReadinessProbeExecutionClosurePreflightReadinessDehydrated:
            Bool
    ) {
        this.runtimeNativeReadinessProbeExecutionClosurePreflightFacts =
            runtimeNativeReadinessProbeExecutionClosurePreflightFacts
        this.didAdmitRuntimeNativeReadinessProbeExecutionClosurePreflight =
            didAdmitRuntimeNativeReadinessProbeExecutionClosurePreflight
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeNativeProbeExecution =
            shouldDeferRuntimeNativeProbeExecution
        this.shouldReportRuntimeNativeReadinessProbeExecutionClosurePreflightBlocked =
            shouldReportRuntimeNativeReadinessProbeExecutionClosurePreflightBlocked
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosurePreflight =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosurePreflight
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosurePreflight =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosurePreflight
        this.didConfirmNoRuntimeNativeProbeExecutionForClosurePreflight =
            didConfirmNoRuntimeNativeProbeExecutionForClosurePreflight
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepRuntimeNativeReadinessProbeExecutionClosurePreflightReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionClosurePreflightReadinessDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness {
    let runtimeNativeReadinessProbeExecutionFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceReadiness
    let runtimeNativeReadinessProbeExecutionClosurePreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflight
    let didPrepareRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness:
        Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeNativeProbeExecution: Bool
    let shouldReportRuntimeNativeReadinessProbeExecutionClosurePreflightBlocked:
        Bool
    let didOpenRuntimeNativeReadinessProbeExecutionClosurePreflight: Bool
    let didConfirmRuntimeNativeReadinessProbeExecutionFirstSliceComplete:
        Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosurePreflight:
        Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosurePreflight:
        Bool
    let didConfirmNoRuntimeNativeProbeExecutionForClosurePreflight: Bool
    let didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosurePreflight:
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
    let didKeepRuntimeNativeReadinessProbeExecutionClosurePreflightReadinessDehydrated:
        Bool

    init(
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceReadiness,
        runtimeNativeReadinessProbeExecutionClosurePreflight:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflight,
        didPrepareRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness:
            Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeNativeProbeExecution: Bool,
        shouldReportRuntimeNativeReadinessProbeExecutionClosurePreflightBlocked:
            Bool,
        didOpenRuntimeNativeReadinessProbeExecutionClosurePreflight: Bool,
        didConfirmRuntimeNativeReadinessProbeExecutionFirstSliceComplete:
            Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosurePreflight:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosurePreflight:
            Bool,
        didConfirmNoRuntimeNativeProbeExecutionForClosurePreflight: Bool,
        didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosurePreflight:
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
        didKeepRuntimeNativeReadinessProbeExecutionClosurePreflightReadinessDehydrated:
            Bool
    ) {
        this.runtimeNativeReadinessProbeExecutionFirstSliceReadiness =
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
        this.runtimeNativeReadinessProbeExecutionClosurePreflight =
            runtimeNativeReadinessProbeExecutionClosurePreflight
        this.didPrepareRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness =
            didPrepareRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeNativeProbeExecution =
            shouldDeferRuntimeNativeProbeExecution
        this.shouldReportRuntimeNativeReadinessProbeExecutionClosurePreflightBlocked =
            shouldReportRuntimeNativeReadinessProbeExecutionClosurePreflightBlocked
        this.didOpenRuntimeNativeReadinessProbeExecutionClosurePreflight =
            didOpenRuntimeNativeReadinessProbeExecutionClosurePreflight
        this.didConfirmRuntimeNativeReadinessProbeExecutionFirstSliceComplete =
            didConfirmRuntimeNativeReadinessProbeExecutionFirstSliceComplete
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosurePreflight =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosurePreflight
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosurePreflight =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosurePreflight
        this.didConfirmNoRuntimeNativeProbeExecutionForClosurePreflight =
            didConfirmNoRuntimeNativeProbeExecutionForClosurePreflight
        this.didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosurePreflight =
            didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosurePreflight
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
        this.didKeepRuntimeNativeReadinessProbeExecutionClosurePreflightReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionClosurePreflightReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightFacts(
    runtimeNativeReadinessProbeExecutionFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightFacts {
    let firstSliceFacts =
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .runtimeNativeReadinessProbeExecutionFirstSlice
            .runtimeNativeReadinessProbeExecutionFirstSliceFacts
    let firstSliceReady =
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didPrepareRuntimeNativeReadinessProbeExecutionFirstSliceReadiness &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .shouldDeferProductionSingletonOwnerImplementation &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .shouldDeferApplicationSingletonAccessorCall &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .shouldDeferCleanupTeardownExecution &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .shouldDeferRuntimeNativeProbeExecution &&
        !runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .shouldReportRuntimeNativeReadinessProbeExecutionFirstSliceBlocked &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didOpenRuntimeNativeReadinessProbeExecutionFirstSlice &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didConfirmRuntimeNativeReadinessProbeExecutionValueBoundaryComplete &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionFirstSlice &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionFirstSlice &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didConfirmNoRuntimeNativeProbeExecutionForFirstSlice &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionFirstSlice &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didCarryForwardRuntimeNativeReadinessProbeValueBoundary &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didCarryForwardRuntimeNativeReadinessProbePreflight &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didCarryForwardNativeReadinessValueBoundary &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didCarryForwardScanOnlyNativeReadinessEvidence &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didCarryForwardNoSideEffectEvidenceOnly &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didCarryForwardMainThreadCreationConfinement &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didDeferActivation &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didDeferActivationPolicyMutation &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didDeferAppKitEventLoop &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didDeferBoundedRunLoopPump &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didDeferVisibleOrder &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didDeferDrawableAndRender &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didBlockArtifactPublicDiagnosticsPublication &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didConfirmNoPublicApi &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didConfirmNoProductionPublicCAbi &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didConfirmNoRendererStateWrite &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didConfirmNoRuntimeStateWrite &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didConfirmNoCjpmTomlChange &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didKeepProductionSingletonOwnershipTruthFalse &&
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness
            .didKeepRuntimeNativeReadinessProbeExecutionFirstSliceReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightFacts(
        firstSliceReady,
        firstSliceReady,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didOpenRuntimeNativeReadinessProbeExecutionFirstSlice,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionFirstSlice,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionFirstSlice,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didConfirmNoRuntimeNativeProbeExecutionForFirstSlice,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionFirstSlice,
        firstSliceReady && firstSliceFacts.didConfirmExistingOwnerProbeAndForbiddenScan,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didOpenRuntimeNativeReadinessProbeExecutionFirstSlice,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didCarryForwardRuntimeNativeReadinessProbeValueBoundary,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didCarryForwardRuntimeNativeReadinessProbePreflight,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didCarryForwardNativeReadinessValueBoundary,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didCarryForwardScanOnlyNativeReadinessEvidence,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didCarryForwardNoSideEffectEvidenceOnly,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didCarryForwardMainThreadCreationConfinement,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .shouldDeferProductionSingletonOwnerImplementation,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .shouldDeferApplicationSingletonAccessorCall,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .shouldDeferCleanupTeardownExecution,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .shouldDeferRuntimeNativeProbeExecution,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didDeferActivation,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didDeferActivationPolicyMutation,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didDeferAppKitEventLoop,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didDeferBoundedRunLoopPump,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didDeferVisibleOrder,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didDeferDrawableAndRender,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didBlockArtifactPublicDiagnosticsPublication,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didConfirmNoPublicApi,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didConfirmNoProductionPublicCAbi,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didConfirmNoRendererStateWrite,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didConfirmNoRuntimeStateWrite,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didConfirmNoCjpmTomlChange,
        firstSliceReady &&
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
                .didKeepProductionSingletonOwnershipTruthFalse,
        firstSliceReady,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflight(
    runtimeNativeReadinessProbeExecutionClosurePreflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflight {
    let admitted =
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didConsumeRuntimeNativeReadinessProbeExecutionFirstSliceReadiness &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didOpenRuntimeNativeReadinessProbeExecutionClosurePreflight &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didConfirmRuntimeNativeReadinessProbeExecutionFirstSliceComplete &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosurePreflight &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosurePreflight &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didConfirmNoRuntimeNativeProbeExecutionForClosurePreflight &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosurePreflight &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didConfirmExistingOwnerProbeAndForbiddenScan &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didCarryForwardRuntimeNativeReadinessProbeExecutionFirstSlice &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didCarryForwardRuntimeNativeReadinessProbeValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didCarryForwardRuntimeNativeReadinessProbePreflight &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didCarryForwardNativeReadinessValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didCarryForwardScanOnlyNativeReadinessEvidence &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didCarryForwardNoSideEffectEvidenceOnly &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didCarryForwardMainThreadCreationConfinement &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didDeferProductionSingletonOwnerImplementation &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didDeferApplicationSingletonAccessorCall &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didDeferCleanupTeardownExecution &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didDeferRuntimeNativeProbeExecution &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts.didDeferActivation &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didDeferActivationPolicyMutation &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didDeferAppKitEventLoop &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didDeferBoundedRunLoopPump &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts.didDeferVisibleOrder &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didDeferDrawableAndRender &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didBlockArtifactPublicDiagnosticsPublication &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts.didConfirmNoPublicApi &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didConfirmNoProductionPublicCAbi &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didConfirmNoRendererStateWrite &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didConfirmNoRuntimeStateWrite &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts.didConfirmNoCjpmTomlChange &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didKeepProductionSingletonOwnershipTruthFalse &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didKeepRuntimeNativeReadinessProbeExecutionClosurePreflightReadinessDehydrated &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didRequireFutureRuntimeNativeReadinessProbeExecutionClosureValueBoundarySeparateBoundary &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts.didAvoidApplicationReadyWrapper &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didAvoidSingletonOwnerReadyWrapper &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts.didAvoidNativeProbeReadyWrapper &&
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts.didAvoidBackendReadyWrapper

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflight(
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosurePreflight,
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosurePreflight,
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didConfirmNoRuntimeNativeProbeExecutionForClosurePreflight,
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didKeepProductionSingletonOwnershipTruthFalse,
        runtimeNativeReadinessProbeExecutionClosurePreflightFacts
            .didKeepRuntimeNativeReadinessProbeExecutionClosurePreflightReadinessDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness(
    runtimeNativeReadinessProbeExecutionFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceReadiness,
    runtimeNativeReadinessProbeExecutionClosurePreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflight
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness {
    let facts =
        runtimeNativeReadinessProbeExecutionClosurePreflight
            .runtimeNativeReadinessProbeExecutionClosurePreflightFacts
    let admitted =
        runtimeNativeReadinessProbeExecutionClosurePreflight
            .didAdmitRuntimeNativeReadinessProbeExecutionClosurePreflight

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness(
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness,
        runtimeNativeReadinessProbeExecutionClosurePreflight,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        facts.didOpenRuntimeNativeReadinessProbeExecutionClosurePreflight,
        facts.didConfirmRuntimeNativeReadinessProbeExecutionFirstSliceComplete,
        facts.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosurePreflight,
        facts.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosurePreflight,
        facts.didConfirmNoRuntimeNativeProbeExecutionForClosurePreflight,
        facts.didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosurePreflight,
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
        facts.didKeepRuntimeNativeReadinessProbeExecutionClosurePreflightReadinessDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness {
    let runtimeNativeReadinessProbeExecutionFirstSliceReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceDraft()
    let runtimeNativeReadinessProbeExecutionClosurePreflightFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightFacts(
            runtimeNativeReadinessProbeExecutionFirstSliceReadiness
        )
    let runtimeNativeReadinessProbeExecutionClosurePreflight =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflight(
            runtimeNativeReadinessProbeExecutionClosurePreflightFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosurePreflightReadiness(
        runtimeNativeReadinessProbeExecutionFirstSliceReadiness,
        runtimeNativeReadinessProbeExecutionClosurePreflight
    )
}
