// 中文维护注释：本文件是 visible-window production harness NSApplication
// application-singleton CJGUI-owned lifecycle main-thread / headless fail-closed
// evidence probe runtime native-readiness probe execution closure completion owner。
// Owner: runtime renderer internal CJGUI-owned application lifecycle runtime
// native-readiness probe execution closure completion owner。
// Truth: 只消费 runtime native-readiness probe execution closure first slice
// readiness，把 runtime native-readiness probe execution closure completion 固定为
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletionFacts {
    let didConsumeRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness:
        Bool
    let didOpenRuntimeNativeReadinessProbeExecutionClosureCompletion: Bool
    let didConfirmRuntimeNativeReadinessProbeExecutionClosureFirstSliceComplete:
        Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureCompletion:
        Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureCompletion:
        Bool
    let didConfirmNoRuntimeNativeProbeExecutionForClosureCompletion: Bool
    let didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureCompletion:
        Bool
    let didConfirmExistingOwnerProbeAndForbiddenScan: Bool
    let didCarryForwardRuntimeNativeReadinessProbeExecutionClosureFirstSlice:
        Bool
    let didCarryForwardRuntimeNativeReadinessProbeExecutionClosureValueBoundary:
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
    let didKeepRuntimeNativeReadinessProbeExecutionClosureCompletionReadinessDehydrated:
        Bool
    let didRequireFutureRuntimeNativeReadinessProbeExecutionClosureCompactManifestSeparateBoundary:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidSingletonOwnerReadyWrapper: Bool
    let didAvoidNativeProbeReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didConsumeRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness:
            Bool,
        didOpenRuntimeNativeReadinessProbeExecutionClosureCompletion: Bool,
        didConfirmRuntimeNativeReadinessProbeExecutionClosureFirstSliceComplete:
            Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureCompletion:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureCompletion:
            Bool,
        didConfirmNoRuntimeNativeProbeExecutionForClosureCompletion: Bool,
        didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureCompletion:
            Bool,
        didConfirmExistingOwnerProbeAndForbiddenScan: Bool,
        didCarryForwardRuntimeNativeReadinessProbeExecutionClosureFirstSlice:
            Bool,
        didCarryForwardRuntimeNativeReadinessProbeExecutionClosureValueBoundary:
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
        didKeepRuntimeNativeReadinessProbeExecutionClosureCompletionReadinessDehydrated:
            Bool,
        didRequireFutureRuntimeNativeReadinessProbeExecutionClosureCompactManifestSeparateBoundary:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidSingletonOwnerReadyWrapper: Bool,
        didAvoidNativeProbeReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didConsumeRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness =
            didConsumeRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
        this.didOpenRuntimeNativeReadinessProbeExecutionClosureCompletion =
            didOpenRuntimeNativeReadinessProbeExecutionClosureCompletion
        this.didConfirmRuntimeNativeReadinessProbeExecutionClosureFirstSliceComplete =
            didConfirmRuntimeNativeReadinessProbeExecutionClosureFirstSliceComplete
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureCompletion =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureCompletion
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureCompletion =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureCompletion
        this.didConfirmNoRuntimeNativeProbeExecutionForClosureCompletion =
            didConfirmNoRuntimeNativeProbeExecutionForClosureCompletion
        this.didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureCompletion =
            didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureCompletion
        this.didConfirmExistingOwnerProbeAndForbiddenScan =
            didConfirmExistingOwnerProbeAndForbiddenScan
        this.didCarryForwardRuntimeNativeReadinessProbeExecutionClosureFirstSlice =
            didCarryForwardRuntimeNativeReadinessProbeExecutionClosureFirstSlice
        this.didCarryForwardRuntimeNativeReadinessProbeExecutionClosureValueBoundary =
            didCarryForwardRuntimeNativeReadinessProbeExecutionClosureValueBoundary
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
        this.didKeepRuntimeNativeReadinessProbeExecutionClosureCompletionReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionClosureCompletionReadinessDehydrated
        this.didRequireFutureRuntimeNativeReadinessProbeExecutionClosureCompactManifestSeparateBoundary =
            didRequireFutureRuntimeNativeReadinessProbeExecutionClosureCompactManifestSeparateBoundary
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidSingletonOwnerReadyWrapper =
            didAvoidSingletonOwnerReadyWrapper
        this.didAvoidNativeProbeReadyWrapper = didAvoidNativeProbeReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletion {
    let runtimeNativeReadinessProbeExecutionClosureCompletionFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletionFacts
    let didAdmitRuntimeNativeReadinessProbeExecutionClosureCompletion: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeNativeProbeExecution: Bool
    let shouldReportRuntimeNativeReadinessProbeExecutionClosureCompletionBlocked:
        Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureCompletion:
        Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureCompletion:
        Bool
    let didConfirmNoRuntimeNativeProbeExecutionForClosureCompletion: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepRuntimeNativeReadinessProbeExecutionClosureCompletionReadinessDehydrated:
        Bool

    init(
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletionFacts,
        didAdmitRuntimeNativeReadinessProbeExecutionClosureCompletion: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeNativeProbeExecution: Bool,
        shouldReportRuntimeNativeReadinessProbeExecutionClosureCompletionBlocked:
            Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureCompletion:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureCompletion:
            Bool,
        didConfirmNoRuntimeNativeProbeExecutionForClosureCompletion: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepRuntimeNativeReadinessProbeExecutionClosureCompletionReadinessDehydrated:
            Bool
    ) {
        this.runtimeNativeReadinessProbeExecutionClosureCompletionFacts =
            runtimeNativeReadinessProbeExecutionClosureCompletionFacts
        this.didAdmitRuntimeNativeReadinessProbeExecutionClosureCompletion =
            didAdmitRuntimeNativeReadinessProbeExecutionClosureCompletion
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeNativeProbeExecution =
            shouldDeferRuntimeNativeProbeExecution
        this.shouldReportRuntimeNativeReadinessProbeExecutionClosureCompletionBlocked =
            shouldReportRuntimeNativeReadinessProbeExecutionClosureCompletionBlocked
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureCompletion =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureCompletion
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureCompletion =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureCompletion
        this.didConfirmNoRuntimeNativeProbeExecutionForClosureCompletion =
            didConfirmNoRuntimeNativeProbeExecutionForClosureCompletion
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepRuntimeNativeReadinessProbeExecutionClosureCompletionReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionClosureCompletionReadinessDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletionReadiness {
    let runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
    let runtimeNativeReadinessProbeExecutionClosureCompletion:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletion
    let didPrepareRuntimeNativeReadinessProbeExecutionClosureCompletionReadiness:
        Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeNativeProbeExecution: Bool
    let shouldReportRuntimeNativeReadinessProbeExecutionClosureCompletionBlocked:
        Bool
    let didOpenRuntimeNativeReadinessProbeExecutionClosureCompletion: Bool
    let didConfirmRuntimeNativeReadinessProbeExecutionClosureFirstSliceComplete:
        Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureCompletion:
        Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureCompletion:
        Bool
    let didConfirmNoRuntimeNativeProbeExecutionForClosureCompletion: Bool
    let didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureCompletion:
        Bool
    let didCarryForwardRuntimeNativeReadinessProbeExecutionClosureFirstSlice:
        Bool
    let didCarryForwardRuntimeNativeReadinessProbeExecutionClosureValueBoundary:
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
    let didKeepRuntimeNativeReadinessProbeExecutionClosureCompletionReadinessDehydrated:
        Bool

    init(
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness,
        runtimeNativeReadinessProbeExecutionClosureCompletion:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletion,
        didPrepareRuntimeNativeReadinessProbeExecutionClosureCompletionReadiness:
            Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeNativeProbeExecution: Bool,
        shouldReportRuntimeNativeReadinessProbeExecutionClosureCompletionBlocked:
            Bool,
        didOpenRuntimeNativeReadinessProbeExecutionClosureCompletion: Bool,
        didConfirmRuntimeNativeReadinessProbeExecutionClosureFirstSliceComplete:
            Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureCompletion:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureCompletion:
            Bool,
        didConfirmNoRuntimeNativeProbeExecutionForClosureCompletion: Bool,
        didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureCompletion:
            Bool,
        didCarryForwardRuntimeNativeReadinessProbeExecutionClosureFirstSlice:
            Bool,
        didCarryForwardRuntimeNativeReadinessProbeExecutionClosureValueBoundary:
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
        didKeepRuntimeNativeReadinessProbeExecutionClosureCompletionReadinessDehydrated:
            Bool
    ) {
        this.runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness =
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
        this.runtimeNativeReadinessProbeExecutionClosureCompletion =
            runtimeNativeReadinessProbeExecutionClosureCompletion
        this.didPrepareRuntimeNativeReadinessProbeExecutionClosureCompletionReadiness =
            didPrepareRuntimeNativeReadinessProbeExecutionClosureCompletionReadiness
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeNativeProbeExecution =
            shouldDeferRuntimeNativeProbeExecution
        this.shouldReportRuntimeNativeReadinessProbeExecutionClosureCompletionBlocked =
            shouldReportRuntimeNativeReadinessProbeExecutionClosureCompletionBlocked
        this.didOpenRuntimeNativeReadinessProbeExecutionClosureCompletion =
            didOpenRuntimeNativeReadinessProbeExecutionClosureCompletion
        this.didConfirmRuntimeNativeReadinessProbeExecutionClosureFirstSliceComplete =
            didConfirmRuntimeNativeReadinessProbeExecutionClosureFirstSliceComplete
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureCompletion =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureCompletion
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureCompletion =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureCompletion
        this.didConfirmNoRuntimeNativeProbeExecutionForClosureCompletion =
            didConfirmNoRuntimeNativeProbeExecutionForClosureCompletion
        this.didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureCompletion =
            didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureCompletion
        this.didCarryForwardRuntimeNativeReadinessProbeExecutionClosureFirstSlice =
            didCarryForwardRuntimeNativeReadinessProbeExecutionClosureFirstSlice
        this.didCarryForwardRuntimeNativeReadinessProbeExecutionClosureValueBoundary =
            didCarryForwardRuntimeNativeReadinessProbeExecutionClosureValueBoundary
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
        this.didKeepRuntimeNativeReadinessProbeExecutionClosureCompletionReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionClosureCompletionReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletionFacts(
    runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletionFacts {
    let closureFirstSliceFacts =
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .runtimeNativeReadinessProbeExecutionClosureFirstSlice
            .runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
    let closureFirstSliceReady =
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didPrepareRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .shouldDeferProductionSingletonOwnerImplementation &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .shouldDeferApplicationSingletonAccessorCall &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .shouldDeferCleanupTeardownExecution &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .shouldDeferRuntimeNativeProbeExecution &&
        !runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .shouldReportRuntimeNativeReadinessProbeExecutionClosureFirstSliceBlocked &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didOpenRuntimeNativeReadinessProbeExecutionClosureFirstSlice &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didConfirmRuntimeNativeReadinessProbeExecutionClosureValueBoundaryComplete &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureFirstSlice &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureFirstSlice &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didConfirmNoRuntimeNativeProbeExecutionForClosureFirstSlice &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureFirstSlice &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didCarryForwardRuntimeNativeReadinessProbeExecutionClosureValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didCarryForwardRuntimeNativeReadinessProbeExecutionClosurePreflight &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didCarryForwardRuntimeNativeReadinessProbeExecutionFirstSlice &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didCarryForwardRuntimeNativeReadinessProbeValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didCarryForwardRuntimeNativeReadinessProbePreflight &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didCarryForwardNativeReadinessValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didCarryForwardScanOnlyNativeReadinessEvidence &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didCarryForwardNoSideEffectEvidenceOnly &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didCarryForwardMainThreadCreationConfinement &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didDeferActivation &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didDeferActivationPolicyMutation &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didDeferAppKitEventLoop &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didDeferBoundedRunLoopPump &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didDeferVisibleOrder &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didDeferDrawableAndRender &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didBlockArtifactPublicDiagnosticsPublication &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didConfirmNoPublicApi &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didConfirmNoProductionPublicCAbi &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didConfirmNoRendererStateWrite &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didConfirmNoRuntimeStateWrite &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didConfirmNoCjpmTomlChange &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didKeepProductionSingletonOwnershipTruthFalse &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
            .didKeepRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletionFacts(
        closureFirstSliceReady,
        closureFirstSliceReady,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didOpenRuntimeNativeReadinessProbeExecutionClosureFirstSlice,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureFirstSlice,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureFirstSlice,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didConfirmNoRuntimeNativeProbeExecutionForClosureFirstSlice,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureFirstSlice,
        closureFirstSliceReady && closureFirstSliceFacts.didConfirmExistingOwnerProbeAndForbiddenScan,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didOpenRuntimeNativeReadinessProbeExecutionClosureFirstSlice,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didCarryForwardRuntimeNativeReadinessProbeExecutionClosureValueBoundary,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didCarryForwardRuntimeNativeReadinessProbeExecutionClosurePreflight,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didCarryForwardRuntimeNativeReadinessProbeExecutionFirstSlice,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didCarryForwardRuntimeNativeReadinessProbeValueBoundary,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didCarryForwardRuntimeNativeReadinessProbePreflight,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didCarryForwardNativeReadinessValueBoundary,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didCarryForwardScanOnlyNativeReadinessEvidence,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didCarryForwardNoSideEffectEvidenceOnly,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didCarryForwardMainThreadCreationConfinement,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .shouldDeferProductionSingletonOwnerImplementation,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .shouldDeferApplicationSingletonAccessorCall,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .shouldDeferCleanupTeardownExecution,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .shouldDeferRuntimeNativeProbeExecution,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didDeferActivation,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didDeferActivationPolicyMutation,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didDeferAppKitEventLoop,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didDeferBoundedRunLoopPump,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didDeferVisibleOrder,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didDeferDrawableAndRender,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didBlockArtifactPublicDiagnosticsPublication,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didConfirmNoPublicApi,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didConfirmNoProductionPublicCAbi,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didConfirmNoRendererStateWrite,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didConfirmNoRuntimeStateWrite,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didConfirmNoCjpmTomlChange,
        closureFirstSliceReady &&
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
                .didKeepProductionSingletonOwnershipTruthFalse,
        closureFirstSliceReady,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletion(
    runtimeNativeReadinessProbeExecutionClosureCompletionFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletionFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletion {
    let admitted =
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didConsumeRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didOpenRuntimeNativeReadinessProbeExecutionClosureCompletion &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didConfirmRuntimeNativeReadinessProbeExecutionClosureFirstSliceComplete &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureCompletion &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureCompletion &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didConfirmNoRuntimeNativeProbeExecutionForClosureCompletion &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureCompletion &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didConfirmExistingOwnerProbeAndForbiddenScan &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didCarryForwardRuntimeNativeReadinessProbeExecutionClosureFirstSlice &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didCarryForwardRuntimeNativeReadinessProbeExecutionClosureValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didCarryForwardRuntimeNativeReadinessProbeExecutionClosurePreflight &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didCarryForwardRuntimeNativeReadinessProbeExecutionFirstSlice &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didCarryForwardRuntimeNativeReadinessProbeValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didCarryForwardRuntimeNativeReadinessProbePreflight &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didCarryForwardNativeReadinessValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didCarryForwardScanOnlyNativeReadinessEvidence &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didCarryForwardNoSideEffectEvidenceOnly &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didCarryForwardMainThreadCreationConfinement &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didDeferProductionSingletonOwnerImplementation &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didDeferApplicationSingletonAccessorCall &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didDeferCleanupTeardownExecution &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didDeferRuntimeNativeProbeExecution &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts.didDeferActivation &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didDeferActivationPolicyMutation &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didDeferAppKitEventLoop &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didDeferBoundedRunLoopPump &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts.didDeferVisibleOrder &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didDeferDrawableAndRender &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didBlockArtifactPublicDiagnosticsPublication &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts.didConfirmNoPublicApi &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didConfirmNoProductionPublicCAbi &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didConfirmNoRendererStateWrite &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didConfirmNoRuntimeStateWrite &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts.didConfirmNoCjpmTomlChange &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didKeepProductionSingletonOwnershipTruthFalse &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didKeepRuntimeNativeReadinessProbeExecutionClosureCompletionReadinessDehydrated &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didRequireFutureRuntimeNativeReadinessProbeExecutionClosureCompactManifestSeparateBoundary &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts.didAvoidApplicationReadyWrapper &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didAvoidSingletonOwnerReadyWrapper &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts.didAvoidNativeProbeReadyWrapper &&
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts.didAvoidBackendReadyWrapper

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletion(
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureCompletion,
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureCompletion,
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didConfirmNoRuntimeNativeProbeExecutionForClosureCompletion,
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didKeepProductionSingletonOwnershipTruthFalse,
        runtimeNativeReadinessProbeExecutionClosureCompletionFacts
            .didKeepRuntimeNativeReadinessProbeExecutionClosureCompletionReadinessDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletionReadiness(
    runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness,
    runtimeNativeReadinessProbeExecutionClosureCompletion:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletion
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletionReadiness {
    let facts =
        runtimeNativeReadinessProbeExecutionClosureCompletion
            .runtimeNativeReadinessProbeExecutionClosureCompletionFacts
    let admitted =
        runtimeNativeReadinessProbeExecutionClosureCompletion
            .didAdmitRuntimeNativeReadinessProbeExecutionClosureCompletion

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletionReadiness(
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness,
        runtimeNativeReadinessProbeExecutionClosureCompletion,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        facts.didOpenRuntimeNativeReadinessProbeExecutionClosureCompletion,
        facts.didConfirmRuntimeNativeReadinessProbeExecutionClosureFirstSliceComplete,
        facts.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureCompletion,
        facts.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureCompletion,
        facts.didConfirmNoRuntimeNativeProbeExecutionForClosureCompletion,
        facts.didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureCompletion,
        facts.didCarryForwardRuntimeNativeReadinessProbeExecutionClosureFirstSlice,
        facts.didCarryForwardRuntimeNativeReadinessProbeExecutionClosureValueBoundary,
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
        facts.didKeepRuntimeNativeReadinessProbeExecutionClosureCompletionReadinessDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletionDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletionReadiness {
    let runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceDraft()
    let runtimeNativeReadinessProbeExecutionClosureCompletionFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletionFacts(
            runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
        )
    let runtimeNativeReadinessProbeExecutionClosureCompletion =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletion(
            runtimeNativeReadinessProbeExecutionClosureCompletionFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletionReadiness(
        runtimeNativeReadinessProbeExecutionClosureFirstSliceReadiness,
        runtimeNativeReadinessProbeExecutionClosureCompletion
    )
}
