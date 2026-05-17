// 中文维护注释：本文件是 visible-window production harness NSApplication
// application-singleton CJGUI-owned lifecycle main-thread / headless fail-closed
// evidence probe runtime native-readiness probe execution first slice owner。
// Owner: runtime renderer internal CJGUI-owned application lifecycle runtime
// native-readiness probe execution first slice owner。
// Truth: 只消费 runtime native-readiness probe execution value boundary
// readiness，把 runtime native-readiness probe execution first slice 固定为
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceFacts {
    let didConsumeRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness:
        Bool
    let didOpenRuntimeNativeReadinessProbeExecutionFirstSlice: Bool
    let didConfirmRuntimeNativeReadinessProbeExecutionValueBoundaryComplete:
        Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionFirstSlice:
        Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionFirstSlice:
        Bool
    let didConfirmNoRuntimeNativeProbeExecutionForFirstSlice: Bool
    let didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionFirstSlice:
        Bool
    let didConfirmExistingOwnerProbeAndForbiddenScan: Bool
    let didCarryForwardRuntimeNativeReadinessProbeExecutionValueBoundary:
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
    let didKeepRuntimeNativeReadinessProbeExecutionFirstSliceReadinessDehydrated:
        Bool
    let didRequireFutureRuntimeNativeReadinessProbeExecutionClosurePreflightSeparateBoundary:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidSingletonOwnerReadyWrapper: Bool
    let didAvoidNativeProbeReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didConsumeRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness:
            Bool,
        didOpenRuntimeNativeReadinessProbeExecutionFirstSlice: Bool,
        didConfirmRuntimeNativeReadinessProbeExecutionValueBoundaryComplete:
            Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionFirstSlice:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionFirstSlice:
            Bool,
        didConfirmNoRuntimeNativeProbeExecutionForFirstSlice: Bool,
        didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionFirstSlice:
            Bool,
        didConfirmExistingOwnerProbeAndForbiddenScan: Bool,
        didCarryForwardRuntimeNativeReadinessProbeExecutionValueBoundary:
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
        didKeepRuntimeNativeReadinessProbeExecutionFirstSliceReadinessDehydrated:
            Bool,
        didRequireFutureRuntimeNativeReadinessProbeExecutionClosurePreflightSeparateBoundary:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidSingletonOwnerReadyWrapper: Bool,
        didAvoidNativeProbeReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didConsumeRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness =
            didConsumeRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness
        this.didOpenRuntimeNativeReadinessProbeExecutionFirstSlice =
            didOpenRuntimeNativeReadinessProbeExecutionFirstSlice
        this.didConfirmRuntimeNativeReadinessProbeExecutionValueBoundaryComplete =
            didConfirmRuntimeNativeReadinessProbeExecutionValueBoundaryComplete
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionFirstSlice =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionFirstSlice
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionFirstSlice =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionFirstSlice
        this.didConfirmNoRuntimeNativeProbeExecutionForFirstSlice =
            didConfirmNoRuntimeNativeProbeExecutionForFirstSlice
        this.didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionFirstSlice =
            didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionFirstSlice
        this.didConfirmExistingOwnerProbeAndForbiddenScan =
            didConfirmExistingOwnerProbeAndForbiddenScan
        this.didCarryForwardRuntimeNativeReadinessProbeExecutionValueBoundary =
            didCarryForwardRuntimeNativeReadinessProbeExecutionValueBoundary
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
        this.didKeepRuntimeNativeReadinessProbeExecutionFirstSliceReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionFirstSliceReadinessDehydrated
        this.didRequireFutureRuntimeNativeReadinessProbeExecutionClosurePreflightSeparateBoundary =
            didRequireFutureRuntimeNativeReadinessProbeExecutionClosurePreflightSeparateBoundary
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidSingletonOwnerReadyWrapper =
            didAvoidSingletonOwnerReadyWrapper
        this.didAvoidNativeProbeReadyWrapper = didAvoidNativeProbeReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSlice {
    let runtimeNativeReadinessProbeExecutionFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceFacts
    let didAdmitRuntimeNativeReadinessProbeExecutionFirstSlice: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeNativeProbeExecution: Bool
    let shouldReportRuntimeNativeReadinessProbeExecutionFirstSliceBlocked:
        Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionFirstSlice:
        Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionFirstSlice:
        Bool
    let didConfirmNoRuntimeNativeProbeExecutionForFirstSlice: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepRuntimeNativeReadinessProbeExecutionFirstSliceReadinessDehydrated:
        Bool

    init(
        runtimeNativeReadinessProbeExecutionFirstSliceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceFacts,
        didAdmitRuntimeNativeReadinessProbeExecutionFirstSlice: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeNativeProbeExecution: Bool,
        shouldReportRuntimeNativeReadinessProbeExecutionFirstSliceBlocked:
            Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionFirstSlice:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionFirstSlice:
            Bool,
        didConfirmNoRuntimeNativeProbeExecutionForFirstSlice: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepRuntimeNativeReadinessProbeExecutionFirstSliceReadinessDehydrated:
            Bool
    ) {
        this.runtimeNativeReadinessProbeExecutionFirstSliceFacts =
            runtimeNativeReadinessProbeExecutionFirstSliceFacts
        this.didAdmitRuntimeNativeReadinessProbeExecutionFirstSlice =
            didAdmitRuntimeNativeReadinessProbeExecutionFirstSlice
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeNativeProbeExecution =
            shouldDeferRuntimeNativeProbeExecution
        this.shouldReportRuntimeNativeReadinessProbeExecutionFirstSliceBlocked =
            shouldReportRuntimeNativeReadinessProbeExecutionFirstSliceBlocked
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionFirstSlice =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionFirstSlice
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionFirstSlice =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionFirstSlice
        this.didConfirmNoRuntimeNativeProbeExecutionForFirstSlice =
            didConfirmNoRuntimeNativeProbeExecutionForFirstSlice
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepRuntimeNativeReadinessProbeExecutionFirstSliceReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionFirstSliceReadinessDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceReadiness {
    let runtimeNativeReadinessProbeExecutionValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness
    let runtimeNativeReadinessProbeExecutionFirstSlice:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSlice
    let didPrepareRuntimeNativeReadinessProbeExecutionFirstSliceReadiness:
        Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeNativeProbeExecution: Bool
    let shouldReportRuntimeNativeReadinessProbeExecutionFirstSliceBlocked:
        Bool
    let didOpenRuntimeNativeReadinessProbeExecutionFirstSlice: Bool
    let didConfirmRuntimeNativeReadinessProbeExecutionValueBoundaryComplete:
        Bool
    let didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionFirstSlice:
        Bool
    let didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionFirstSlice:
        Bool
    let didConfirmNoRuntimeNativeProbeExecutionForFirstSlice: Bool
    let didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionFirstSlice:
        Bool
    let didCarryForwardRuntimeNativeReadinessProbeExecutionValueBoundary:
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
    let didKeepRuntimeNativeReadinessProbeExecutionFirstSliceReadinessDehydrated:
        Bool

    init(
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness,
        runtimeNativeReadinessProbeExecutionFirstSlice:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSlice,
        didPrepareRuntimeNativeReadinessProbeExecutionFirstSliceReadiness:
            Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeNativeProbeExecution: Bool,
        shouldReportRuntimeNativeReadinessProbeExecutionFirstSliceBlocked:
            Bool,
        didOpenRuntimeNativeReadinessProbeExecutionFirstSlice: Bool,
        didConfirmRuntimeNativeReadinessProbeExecutionValueBoundaryComplete:
            Bool,
        didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionFirstSlice:
            Bool,
        didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionFirstSlice:
            Bool,
        didConfirmNoRuntimeNativeProbeExecutionForFirstSlice: Bool,
        didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionFirstSlice:
            Bool,
        didCarryForwardRuntimeNativeReadinessProbeExecutionValueBoundary:
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
        didKeepRuntimeNativeReadinessProbeExecutionFirstSliceReadinessDehydrated:
            Bool
    ) {
        this.runtimeNativeReadinessProbeExecutionValueBoundaryReadiness =
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
        this.runtimeNativeReadinessProbeExecutionFirstSlice =
            runtimeNativeReadinessProbeExecutionFirstSlice
        this.didPrepareRuntimeNativeReadinessProbeExecutionFirstSliceReadiness =
            didPrepareRuntimeNativeReadinessProbeExecutionFirstSliceReadiness
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeNativeProbeExecution =
            shouldDeferRuntimeNativeProbeExecution
        this.shouldReportRuntimeNativeReadinessProbeExecutionFirstSliceBlocked =
            shouldReportRuntimeNativeReadinessProbeExecutionFirstSliceBlocked
        this.didOpenRuntimeNativeReadinessProbeExecutionFirstSlice =
            didOpenRuntimeNativeReadinessProbeExecutionFirstSlice
        this.didConfirmRuntimeNativeReadinessProbeExecutionValueBoundaryComplete =
            didConfirmRuntimeNativeReadinessProbeExecutionValueBoundaryComplete
        this.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionFirstSlice =
            didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionFirstSlice
        this.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionFirstSlice =
            didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionFirstSlice
        this.didConfirmNoRuntimeNativeProbeExecutionForFirstSlice =
            didConfirmNoRuntimeNativeProbeExecutionForFirstSlice
        this.didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionFirstSlice =
            didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionFirstSlice
        this.didCarryForwardRuntimeNativeReadinessProbeExecutionValueBoundary =
            didCarryForwardRuntimeNativeReadinessProbeExecutionValueBoundary
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
        this.didKeepRuntimeNativeReadinessProbeExecutionFirstSliceReadinessDehydrated =
            didKeepRuntimeNativeReadinessProbeExecutionFirstSliceReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceFacts(
    runtimeNativeReadinessProbeExecutionValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceFacts {
    let valueBoundaryFacts =
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .runtimeNativeReadinessProbeExecutionValueBoundary
            .runtimeNativeReadinessProbeExecutionValueBoundaryFacts
    let valueBoundaryReady =
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didPrepareRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .shouldDeferProductionSingletonOwnerImplementation &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .shouldDeferApplicationSingletonAccessorCall &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .shouldDeferCleanupTeardownExecution &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .shouldDeferRuntimeNativeProbeExecution &&
        !runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .shouldReportRuntimeNativeReadinessProbeExecutionValueBoundaryBlocked &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didOpenRuntimeNativeReadinessProbeExecutionValueBoundary &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didConfirmRuntimeNativeReadinessProbeExecutionPreflightComplete &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionValue &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionValue &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didConfirmNoRuntimeNativeProbeExecutionForValue &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionValue &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didCarryForwardRuntimeNativeReadinessProbeValueBoundary &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didCarryForwardRuntimeNativeReadinessProbePreflight &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didCarryForwardNativeReadinessValueBoundary &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didCarryForwardScanOnlyNativeReadinessEvidence &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didCarryForwardNoSideEffectEvidenceOnly &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didCarryForwardMainThreadCreationConfinement &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didDeferActivation &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didDeferActivationPolicyMutation &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didDeferAppKitEventLoop &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didDeferBoundedRunLoopPump &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didDeferVisibleOrder &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didDeferDrawableAndRender &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didBlockArtifactPublicDiagnosticsPublication &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didConfirmNoPublicApi &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didConfirmNoProductionPublicCAbi &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didConfirmNoRendererStateWrite &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didConfirmNoRuntimeStateWrite &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didConfirmNoCjpmTomlChange &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didKeepProductionSingletonOwnershipTruthFalse &&
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
            .didKeepRuntimeNativeReadinessProbeExecutionValueBoundaryReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceFacts(
        valueBoundaryReady,
        valueBoundaryReady,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didOpenRuntimeNativeReadinessProbeExecutionValueBoundary,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionValue,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionValue,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didConfirmNoRuntimeNativeProbeExecutionForValue,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionValue,
        valueBoundaryReady && valueBoundaryFacts.didConfirmExistingOwnerProbeAndForbiddenScan,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didOpenRuntimeNativeReadinessProbeExecutionValueBoundary,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didCarryForwardRuntimeNativeReadinessProbeValueBoundary,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didCarryForwardRuntimeNativeReadinessProbePreflight,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didCarryForwardNativeReadinessValueBoundary,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didCarryForwardScanOnlyNativeReadinessEvidence,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didCarryForwardNoSideEffectEvidenceOnly,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didCarryForwardMainThreadCreationConfinement,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .shouldDeferProductionSingletonOwnerImplementation,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .shouldDeferApplicationSingletonAccessorCall,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .shouldDeferCleanupTeardownExecution,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .shouldDeferRuntimeNativeProbeExecution,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didDeferActivation,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didDeferActivationPolicyMutation,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didDeferAppKitEventLoop,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didDeferBoundedRunLoopPump,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didDeferVisibleOrder,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didDeferDrawableAndRender,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didBlockArtifactPublicDiagnosticsPublication,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didConfirmNoPublicApi,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didConfirmNoProductionPublicCAbi,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didConfirmNoRendererStateWrite,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didConfirmNoRuntimeStateWrite,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didConfirmNoCjpmTomlChange,
        valueBoundaryReady &&
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
                .didKeepProductionSingletonOwnershipTruthFalse,
        valueBoundaryReady,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSlice(
    runtimeNativeReadinessProbeExecutionFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSlice {
    let admitted =
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didConsumeRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didOpenRuntimeNativeReadinessProbeExecutionFirstSlice &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didConfirmRuntimeNativeReadinessProbeExecutionValueBoundaryComplete &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionFirstSlice &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionFirstSlice &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didConfirmNoRuntimeNativeProbeExecutionForFirstSlice &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionFirstSlice &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didConfirmExistingOwnerProbeAndForbiddenScan &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didCarryForwardRuntimeNativeReadinessProbeExecutionValueBoundary &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didCarryForwardRuntimeNativeReadinessProbeExecutionPreflight &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didCarryForwardRuntimeNativeReadinessProbeValueBoundary &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didCarryForwardRuntimeNativeReadinessProbePreflight &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didCarryForwardNativeReadinessValueBoundary &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didCarryForwardScanOnlyNativeReadinessEvidence &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didCarryForwardNoSideEffectEvidenceOnly &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didCarryForwardMainThreadCreationConfinement &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didDeferProductionSingletonOwnerImplementation &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didDeferApplicationSingletonAccessorCall &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didDeferCleanupTeardownExecution &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didDeferRuntimeNativeProbeExecution &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts.didDeferActivation &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didDeferActivationPolicyMutation &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didDeferAppKitEventLoop &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didDeferBoundedRunLoopPump &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts.didDeferVisibleOrder &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didDeferDrawableAndRender &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didBlockArtifactPublicDiagnosticsPublication &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts.didConfirmNoPublicApi &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didConfirmNoProductionPublicCAbi &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didConfirmNoRendererStateWrite &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didConfirmNoRuntimeStateWrite &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts.didConfirmNoCjpmTomlChange &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didKeepProductionSingletonOwnershipTruthFalse &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didKeepRuntimeNativeReadinessProbeExecutionFirstSliceReadinessDehydrated &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didRequireFutureRuntimeNativeReadinessProbeExecutionClosurePreflightSeparateBoundary &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts.didAvoidApplicationReadyWrapper &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didAvoidSingletonOwnerReadyWrapper &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts.didAvoidNativeProbeReadyWrapper &&
        runtimeNativeReadinessProbeExecutionFirstSliceFacts.didAvoidBackendReadyWrapper

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSlice(
        runtimeNativeReadinessProbeExecutionFirstSliceFacts,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionFirstSlice,
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionFirstSlice,
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didConfirmNoRuntimeNativeProbeExecutionForFirstSlice,
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didKeepProductionSingletonOwnershipTruthFalse,
        runtimeNativeReadinessProbeExecutionFirstSliceFacts
            .didKeepRuntimeNativeReadinessProbeExecutionFirstSliceReadinessDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceReadiness(
    runtimeNativeReadinessProbeExecutionValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness,
    runtimeNativeReadinessProbeExecutionFirstSlice:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSlice
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceReadiness {
    let facts =
        runtimeNativeReadinessProbeExecutionFirstSlice
            .runtimeNativeReadinessProbeExecutionFirstSliceFacts
    let admitted =
        runtimeNativeReadinessProbeExecutionFirstSlice
            .didAdmitRuntimeNativeReadinessProbeExecutionFirstSlice

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceReadiness(
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness,
        runtimeNativeReadinessProbeExecutionFirstSlice,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        facts.didOpenRuntimeNativeReadinessProbeExecutionFirstSlice,
        facts.didConfirmRuntimeNativeReadinessProbeExecutionValueBoundaryComplete,
        facts.didConfirmNoApplicationAccessorCallForRuntimeNativeProbeExecutionFirstSlice,
        facts.didConfirmNoNativeBridgeExpansionForRuntimeNativeProbeExecutionFirstSlice,
        facts.didConfirmNoRuntimeNativeProbeExecutionForFirstSlice,
        facts.didConfirmNoSingletonCreationDuringRuntimeNativeProbeExecutionFirstSlice,
        facts.didCarryForwardRuntimeNativeReadinessProbeExecutionValueBoundary,
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
        facts.didKeepRuntimeNativeReadinessProbeExecutionFirstSliceReadinessDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceReadiness {
    let runtimeNativeReadinessProbeExecutionValueBoundaryReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryDraft()
    let runtimeNativeReadinessProbeExecutionFirstSliceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceFacts(
            runtimeNativeReadinessProbeExecutionValueBoundaryReadiness
        )
    let runtimeNativeReadinessProbeExecutionFirstSlice =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSlice(
            runtimeNativeReadinessProbeExecutionFirstSliceFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionFirstSliceReadiness(
        runtimeNativeReadinessProbeExecutionValueBoundaryReadiness,
        runtimeNativeReadinessProbeExecutionFirstSlice
    )
}
