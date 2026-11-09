// 中文维护注释：本文件是 visible-window production harness NSApplication
// application-singleton CJGUI-owned lifecycle main-thread / headless fail-closed
// evidence probe runtime native-readiness probe execution closure first slice owner。
// Owner: runtime renderer internal CJGUI-owned application lifecycle runtime
// native-readiness probe execution closure first slice owner。
// Truth: 只消费 runtime native-readiness probe execution closure value boundary
// readiness，把 runtime native-readiness probe execution closure first slice 固定为
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceFacts {
    let didConsumeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness:
        Bool
    let didOpenRuntimeNativeReadinessProbeExecutionClosureFirstSlice: Bool
    let didConfirmRuntimeNativeReadinessProbeExecutionClosureValueBoundaryComplete:
        Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureFirstSlice:
        Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureFirstSlice:
        Bool
    let didConfirmNoRuntimeNativeProbeExecutionForClosureFirstSlice: Bool
    let didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureFirstSlice:
        Bool
    let didConfirmExistingOwnerProbeAndForbiddenScan: Bool
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
    let didKeepRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadinessDehydrated:
        Bool
    let didRequireFutureRuntimeNativeReadinessProbeExecutionClosureCompletionSeparateBoundary:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidSingletonOwnerReadyWrapper: Bool
    let didAvoidNativeProbeReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didConsumeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness:
            Bool,
        didOpenRuntimeNativeReadinessProbeExecutionClosureFirstSlice: Bool,
        didConfirmRuntimeNativeReadinessProbeExecutionClosureValueBoundaryComplete:
            Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureFirstSlice:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureFirstSlice:
            Bool,
        didConfirmNoRuntimeNativeProbeExecutionForClosureFirstSlice: Bool,
        didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureFirstSlice:
            Bool,
        didConfirmExistingOwnerProbeAndForbiddenScan: Bool,
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
        didKeepRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadinessDehydrated:
            Bool,
        didRequireFutureRuntimeNativeReadinessProbeExecutionClosureCompletionSeparateBoundary:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidSingletonOwnerReadyWrapper: Bool,
        didAvoidNativeProbeReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didConsumeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness =
            didConsumeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
        this.didOpenRuntimeNativeReadinessProbeExecutionClosureFirstSlice =
            didOpenRuntimeNativeReadinessProbeExecutionClosureFirstSlice
        this.didConfirmRuntimeNativeReadinessProbeExecutionClosureValueBoundaryComplete =
            didConfirmRuntimeNativeReadinessProbeExecutionClosureValueBoundaryComplete
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureFirstSlice =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureFirstSlice
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureFirstSlice =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureFirstSlice
        this.didConfirmNoRuntimeNativeProbeExecutionForClosureFirstSlice =
            didConfirmNoRuntimeNativeProbeExecutionForClosureFirstSlice
        this.didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureFirstSlice =
            didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureFirstSlice
        this.didConfirmExistingOwnerProbeAndForbiddenScan =
            didConfirmExistingOwnerProbeAndForbiddenScan
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
        this.didKeepRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadinessDehydrated
        this.didRequireFutureRuntimeNativeReadinessProbeExecutionClosureCompletionSeparateBoundary =
            didRequireFutureRuntimeNativeReadinessProbeExecutionClosureCompletionSeparateBoundary
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidSingletonOwnerReadyWrapper =
            didAvoidSingletonOwnerReadyWrapper
        this.didAvoidNativeProbeReadyWrapper = didAvoidNativeProbeReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSlice {
    let runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceFacts
    let didAdmitRuntimeNativeReadinessProbeExecutionClosureFirstSlice: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeNativeProbeExecution: Bool
    let shouldReportRuntimeNativeReadinessProbeExecutionClosureFirstSliceBlocked:
        Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureFirstSlice:
        Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureFirstSlice:
        Bool
    let didConfirmNoRuntimeNativeProbeExecutionForClosureFirstSlice: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadinessDehydrated:
        Bool

    init(
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceFacts,
        didAdmitRuntimeNativeReadinessProbeExecutionClosureFirstSlice: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeNativeProbeExecution: Bool,
        shouldReportRuntimeNativeReadinessProbeExecutionClosureFirstSliceBlocked:
            Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureFirstSlice:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureFirstSlice:
            Bool,
        didConfirmNoRuntimeNativeProbeExecutionForClosureFirstSlice: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadinessDehydrated:
            Bool
    ) {
        this.runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts =
            runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
        this.didAdmitRuntimeNativeReadinessProbeExecutionClosureFirstSlice =
            didAdmitRuntimeNativeReadinessProbeExecutionClosureFirstSlice
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeNativeProbeExecution =
            shouldDeferRuntimeNativeProbeExecution
        this.shouldReportRuntimeNativeReadinessProbeExecutionClosureFirstSliceBlocked =
            shouldReportRuntimeNativeReadinessProbeExecutionClosureFirstSliceBlocked
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureFirstSlice =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureFirstSlice
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureFirstSlice =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureFirstSlice
        this.didConfirmNoRuntimeNativeProbeExecutionForClosureFirstSlice =
            didConfirmNoRuntimeNativeProbeExecutionForClosureFirstSlice
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadinessDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness {
    let runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
    let runtimeNativeReadinessProbeExecutionClosureFirstSlice:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSlice
    let didPrepareRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness:
        Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeNativeProbeExecution: Bool
    let shouldReportRuntimeNativeReadinessProbeExecutionClosureFirstSliceBlocked:
        Bool
    let didOpenRuntimeNativeReadinessProbeExecutionClosureFirstSlice: Bool
    let didConfirmRuntimeNativeReadinessProbeExecutionClosureValueBoundaryComplete:
        Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureFirstSlice:
        Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureFirstSlice:
        Bool
    let didConfirmNoRuntimeNativeProbeExecutionForClosureFirstSlice: Bool
    let didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureFirstSlice:
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
    let didKeepRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadinessDehydrated:
        Bool

    init(
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness,
        runtimeNativeReadinessProbeExecutionClosureFirstSlice:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSlice,
        didPrepareRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness:
            Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeNativeProbeExecution: Bool,
        shouldReportRuntimeNativeReadinessProbeExecutionClosureFirstSliceBlocked:
            Bool,
        didOpenRuntimeNativeReadinessProbeExecutionClosureFirstSlice: Bool,
        didConfirmRuntimeNativeReadinessProbeExecutionClosureValueBoundaryComplete:
            Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureFirstSlice:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureFirstSlice:
            Bool,
        didConfirmNoRuntimeNativeProbeExecutionForClosureFirstSlice: Bool,
        didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureFirstSlice:
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
        didKeepRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadinessDehydrated:
            Bool
    ) {
        this.runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness =
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
        this.runtimeNativeReadinessProbeExecutionClosureFirstSlice =
            runtimeNativeReadinessProbeExecutionClosureFirstSlice
        this.didPrepareRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness =
            didPrepareRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeNativeProbeExecution =
            shouldDeferRuntimeNativeProbeExecution
        this.shouldReportRuntimeNativeReadinessProbeExecutionClosureFirstSliceBlocked =
            shouldReportRuntimeNativeReadinessProbeExecutionClosureFirstSliceBlocked
        this.didOpenRuntimeNativeReadinessProbeExecutionClosureFirstSlice =
            didOpenRuntimeNativeReadinessProbeExecutionClosureFirstSlice
        this.didConfirmRuntimeNativeReadinessProbeExecutionClosureValueBoundaryComplete =
            didConfirmRuntimeNativeReadinessProbeExecutionClosureValueBoundaryComplete
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureFirstSlice =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureFirstSlice
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureFirstSlice =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureFirstSlice
        this.didConfirmNoRuntimeNativeProbeExecutionForClosureFirstSlice =
            didConfirmNoRuntimeNativeProbeExecutionForClosureFirstSlice
        this.didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureFirstSlice =
            didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureFirstSlice
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
        this.didKeepRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceFacts(
    runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceFacts {
    let closureValueBoundaryFacts =
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .runtimeNativeReadinessProbeExecutionClosureValueBoundary
            .runtimeNativeReadinessProbeExecutionClosureValueBoundaryFacts
    let closureValueBoundaryReady =
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didPrepareRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .shouldDeferProductionSingletonOwnerImplementation &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .shouldDeferApplicationSingletonAccessorCall &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .shouldDeferCleanupTeardownExecution &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .shouldDeferRuntimeNativeProbeExecution &&
        !runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .shouldReportRuntimeNativeReadinessProbeExecutionClosureValueBoundaryBlocked &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didOpenRuntimeNativeReadinessProbeExecutionClosureValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didConfirmRuntimeNativeReadinessProbeExecutionClosurePreflightComplete &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didConfirmNoRuntimeNativeProbeExecutionForClosureValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didCarryForwardRuntimeNativeReadinessProbeExecutionClosurePreflight &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didCarryForwardRuntimeNativeReadinessProbeExecutionFirstSlice &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didCarryForwardRuntimeNativeReadinessProbeValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didCarryForwardRuntimeNativeReadinessProbePreflight &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didCarryForwardNativeReadinessValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didCarryForwardScanOnlyNativeReadinessEvidence &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didCarryForwardNoSideEffectEvidenceOnly &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didCarryForwardMainThreadCreationConfinement &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didDeferActivation &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didDeferActivationPolicyMutation &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didDeferAppKitEventLoop &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didDeferBoundedRunLoopPump &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didDeferVisibleOrder &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didDeferDrawableAndRender &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didBlockArtifactPublicDiagnosticsPublication &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didConfirmNoPublicApi &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didConfirmNoProductionPublicCAbi &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didConfirmNoRendererStateWrite &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didConfirmNoRuntimeStateWrite &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didConfirmNoCjpmTomlChange &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didKeepProductionSingletonOwnershipTruthFalse &&
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
            .didKeepRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceFacts(
        closureValueBoundaryReady,
        closureValueBoundaryReady,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didOpenRuntimeNativeReadinessProbeExecutionClosureValueBoundary,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureValueBoundary,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureValueBoundary,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didConfirmNoRuntimeNativeProbeExecutionForClosureValueBoundary,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureValueBoundary,
        closureValueBoundaryReady && closureValueBoundaryFacts.didConfirmExistingOwnerProbeAndForbiddenScan,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didOpenRuntimeNativeReadinessProbeExecutionClosureValueBoundary,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didCarryForwardRuntimeNativeReadinessProbeExecutionClosurePreflight,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didCarryForwardRuntimeNativeReadinessProbeExecutionFirstSlice,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didCarryForwardRuntimeNativeReadinessProbeValueBoundary,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didCarryForwardRuntimeNativeReadinessProbePreflight,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didCarryForwardNativeReadinessValueBoundary,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didCarryForwardScanOnlyNativeReadinessEvidence,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didCarryForwardNoSideEffectEvidenceOnly,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didCarryForwardMainThreadCreationConfinement,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .shouldDeferProductionSingletonOwnerImplementation,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .shouldDeferApplicationSingletonAccessorCall,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .shouldDeferCleanupTeardownExecution,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .shouldDeferRuntimeNativeProbeExecution,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didDeferActivation,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didDeferActivationPolicyMutation,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didDeferAppKitEventLoop,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didDeferBoundedRunLoopPump,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didDeferVisibleOrder,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didDeferDrawableAndRender,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didBlockArtifactPublicDiagnosticsPublication,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didConfirmNoPublicApi,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didConfirmNoProductionPublicCAbi,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didConfirmNoRendererStateWrite,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didConfirmNoRuntimeStateWrite,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didConfirmNoCjpmTomlChange,
        closureValueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
                .didKeepProductionSingletonOwnershipTruthFalse,
        closureValueBoundaryReady,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSlice(
    runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSlice {
    let admitted =
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didConsumeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didOpenRuntimeNativeReadinessProbeExecutionClosureFirstSlice &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didConfirmRuntimeNativeReadinessProbeExecutionClosureValueBoundaryComplete &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureFirstSlice &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureFirstSlice &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didConfirmNoRuntimeNativeProbeExecutionForClosureFirstSlice &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureFirstSlice &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didConfirmExistingOwnerProbeAndForbiddenScan &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didCarryForwardRuntimeNativeReadinessProbeExecutionClosureValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didCarryForwardRuntimeNativeReadinessProbeExecutionClosurePreflight &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didCarryForwardRuntimeNativeReadinessProbeExecutionFirstSlice &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didCarryForwardRuntimeNativeReadinessProbeValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didCarryForwardRuntimeNativeReadinessProbePreflight &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didCarryForwardNativeReadinessValueBoundary &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didCarryForwardScanOnlyNativeReadinessEvidence &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didCarryForwardNoSideEffectEvidenceOnly &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didCarryForwardMainThreadCreationConfinement &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didDeferProductionSingletonOwnerImplementation &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didDeferApplicationSingletonAccessorCall &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didDeferCleanupTeardownExecution &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didDeferRuntimeNativeProbeExecution &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts.didDeferActivation &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didDeferActivationPolicyMutation &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didDeferAppKitEventLoop &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didDeferBoundedRunLoopPump &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts.didDeferVisibleOrder &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didDeferDrawableAndRender &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didBlockArtifactPublicDiagnosticsPublication &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts.didConfirmNoPublicApi &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didConfirmNoProductionPublicCAbi &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didConfirmNoRendererStateWrite &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didConfirmNoRuntimeStateWrite &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts.didConfirmNoCjpmTomlChange &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didKeepProductionSingletonOwnershipTruthFalse &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didKeepRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadinessDehydrated &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didRequireFutureRuntimeNativeReadinessProbeExecutionClosureCompletionSeparateBoundary &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts.didAvoidApplicationReadyWrapper &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didAvoidSingletonOwnerReadyWrapper &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts.didAvoidNativeProbeReadyWrapper &&
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts.didAvoidBackendReadyWrapper

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSlice(
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureFirstSlice,
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureFirstSlice,
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didConfirmNoRuntimeNativeProbeExecutionForClosureFirstSlice,
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didKeepProductionSingletonOwnershipTruthFalse,
        runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
            .didKeepRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadinessDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness(
    runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness,
    runtimeNativeReadinessProbeExecutionClosureFirstSlice:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSlice
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness {
    let facts =
        runtimeNativeReadinessProbeExecutionClosureFirstSlice
            .runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
    let admitted =
        runtimeNativeReadinessProbeExecutionClosureFirstSlice
            .didAdmitRuntimeNativeReadinessProbeExecutionClosureFirstSlice

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness(
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness,
        runtimeNativeReadinessProbeExecutionClosureFirstSlice,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        facts.didOpenRuntimeNativeReadinessProbeExecutionClosureFirstSlice,
        facts.didConfirmRuntimeNativeReadinessProbeExecutionClosureValueBoundaryComplete,
        facts.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionClosureFirstSlice,
        facts.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionClosureFirstSlice,
        facts.didConfirmNoRuntimeNativeProbeExecutionForClosureFirstSlice,
        facts.didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionClosureFirstSlice,
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
        facts.didKeepRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadinessDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness {
    let runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureValueBoundaryDraft()
    let runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceFacts(
            runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness
        )
    let runtimeNativeReadinessProbeExecutionClosureFirstSlice =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSlice(
            runtimeNativeReadinessProbeExecutionClosureFirstSliceFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness(
        runtimeNativeReadinessProbeExecutionClosureValueBoundaryReadiness,
        runtimeNativeReadinessProbeExecutionClosureFirstSlice
    )
}
