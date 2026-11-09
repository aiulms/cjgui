// 中文维护注释：本文件是 visible-window production harness NSApplication
// application-singleton CJGUI-owned lifecycle main-thread / headless fail-closed
// evidence probe native-readiness preflight owner。
// Owner: runtime renderer internal CJGUI-owned application lifecycle native
// readiness preflight owner。
// Truth: 只消费 evidence probe first-slice readiness，把 native-readiness
// preflight 固定为 no-accessor / no-bridge-expansion / no-runtime-probe facts；
// 不创建 singleton，不调用 application accessor，不扩展 native bridge，不执行
// native probe，不把 readiness 升级成 production singleton ownership truth。
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightFacts {
    let didConsumeMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness:
        Bool
    let didOpenEvidenceProbeNativeReadinessPreflight: Bool
    let didRequireNativeReadinessPreflightBeforeRuntimeProbe: Bool
    let didRequireNoApplicationAccessorCallForNativeReadiness: Bool
    let didRequireNoNativeBridgeExpansionForNativeReadiness: Bool
    let didRequireNoRuntimeProbeExecutionForNativeReadinessPreflight: Bool
    let didRequireNoSingletonCreationDuringNativeReadiness: Bool
    let didRequireScanOnlyEvidenceInputs: Bool
    let didRequireExistingOwnerProbeAndForbiddenScan: Bool
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
    let didKeepNativeReadinessPreflightReadinessDehydrated: Bool
    let didRequireFutureNativeReadinessValueBoundarySeparateBoundary: Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidSingletonOwnerReadyWrapper: Bool
    let didAvoidNativeProbeReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didConsumeMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness:
            Bool,
        didOpenEvidenceProbeNativeReadinessPreflight: Bool,
        didRequireNativeReadinessPreflightBeforeRuntimeProbe: Bool,
        didRequireNoApplicationAccessorCallForNativeReadiness: Bool,
        didRequireNoNativeBridgeExpansionForNativeReadiness: Bool,
        didRequireNoRuntimeProbeExecutionForNativeReadinessPreflight: Bool,
        didRequireNoSingletonCreationDuringNativeReadiness: Bool,
        didRequireScanOnlyEvidenceInputs: Bool,
        didRequireExistingOwnerProbeAndForbiddenScan: Bool,
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
        didKeepNativeReadinessPreflightReadinessDehydrated: Bool,
        didRequireFutureNativeReadinessValueBoundarySeparateBoundary: Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidSingletonOwnerReadyWrapper: Bool,
        didAvoidNativeProbeReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didConsumeMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness =
            didConsumeMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness
        this.didOpenEvidenceProbeNativeReadinessPreflight =
            didOpenEvidenceProbeNativeReadinessPreflight
        this.didRequireNativeReadinessPreflightBeforeRuntimeProbe =
            didRequireNativeReadinessPreflightBeforeRuntimeProbe
        this.didRequireNoApplicationAccessorCallForNativeReadiness =
            didRequireNoApplicationAccessorCallForNativeReadiness
        this.didRequireNoNativeBridgeExpansionForNativeReadiness =
            didRequireNoNativeBridgeExpansionForNativeReadiness
        this.didRequireNoRuntimeProbeExecutionForNativeReadinessPreflight =
            didRequireNoRuntimeProbeExecutionForNativeReadinessPreflight
        this.didRequireNoSingletonCreationDuringNativeReadiness =
            didRequireNoSingletonCreationDuringNativeReadiness
        this.didRequireScanOnlyEvidenceInputs =
            didRequireScanOnlyEvidenceInputs
        this.didRequireExistingOwnerProbeAndForbiddenScan =
            didRequireExistingOwnerProbeAndForbiddenScan
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
        this.didKeepNativeReadinessPreflightReadinessDehydrated =
            didKeepNativeReadinessPreflightReadinessDehydrated
        this.didRequireFutureNativeReadinessValueBoundarySeparateBoundary =
            didRequireFutureNativeReadinessValueBoundarySeparateBoundary
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidSingletonOwnerReadyWrapper =
            didAvoidSingletonOwnerReadyWrapper
        this.didAvoidNativeProbeReadyWrapper = didAvoidNativeProbeReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflight {
    let nativeReadinessPreflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightFacts
    let didAdmitEvidenceProbeNativeReadinessPreflight: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeProbeExecution: Bool
    let shouldReportEvidenceProbeNativeReadinessPreflightBlocked: Bool
    let didRequireNoApplicationAccessorCallForNativeReadiness: Bool
    let didRequireNoNativeBridgeExpansionForNativeReadiness: Bool
    let didRequireNoRuntimeProbeExecutionForNativeReadinessPreflight: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepNativeReadinessPreflightReadinessDehydrated: Bool

    init(
        nativeReadinessPreflightFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightFacts,
        didAdmitEvidenceProbeNativeReadinessPreflight: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeProbeExecution: Bool,
        shouldReportEvidenceProbeNativeReadinessPreflightBlocked: Bool,
        didRequireNoApplicationAccessorCallForNativeReadiness: Bool,
        didRequireNoNativeBridgeExpansionForNativeReadiness: Bool,
        didRequireNoRuntimeProbeExecutionForNativeReadinessPreflight: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepNativeReadinessPreflightReadinessDehydrated: Bool
    ) {
        this.nativeReadinessPreflightFacts = nativeReadinessPreflightFacts
        this.didAdmitEvidenceProbeNativeReadinessPreflight =
            didAdmitEvidenceProbeNativeReadinessPreflight
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeProbeExecution =
            shouldDeferRuntimeProbeExecution
        this.shouldReportEvidenceProbeNativeReadinessPreflightBlocked =
            shouldReportEvidenceProbeNativeReadinessPreflightBlocked
        this.didRequireNoApplicationAccessorCallForNativeReadiness =
            didRequireNoApplicationAccessorCallForNativeReadiness
        this.didRequireNoNativeBridgeExpansionForNativeReadiness =
            didRequireNoNativeBridgeExpansionForNativeReadiness
        this.didRequireNoRuntimeProbeExecutionForNativeReadinessPreflight =
            didRequireNoRuntimeProbeExecutionForNativeReadinessPreflight
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepNativeReadinessPreflightReadinessDehydrated =
            didKeepNativeReadinessPreflightReadinessDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightReadiness {
    let evidenceProbeFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness
    let nativeReadinessPreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflight
    let didPrepareEvidenceProbeNativeReadinessPreflightReadiness: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldDeferRuntimeProbeExecution: Bool
    let shouldReportEvidenceProbeNativeReadinessPreflightBlocked: Bool
    let didOpenEvidenceProbeNativeReadinessPreflight: Bool
    let didRequireNativeReadinessPreflightBeforeRuntimeProbe: Bool
    let didRequireNoApplicationAccessorCallForNativeReadiness: Bool
    let didRequireNoNativeBridgeExpansionForNativeReadiness: Bool
    let didRequireNoRuntimeProbeExecutionForNativeReadinessPreflight: Bool
    let didRequireNoSingletonCreationDuringNativeReadiness: Bool
    let didRequireScanOnlyEvidenceInputs: Bool
    let didRequireExistingOwnerProbeAndForbiddenScan: Bool
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
    let didKeepNativeReadinessPreflightReadinessDehydrated: Bool

    init(
        evidenceProbeFirstSliceReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness,
        nativeReadinessPreflight:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflight,
        didPrepareEvidenceProbeNativeReadinessPreflightReadiness: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldDeferRuntimeProbeExecution: Bool,
        shouldReportEvidenceProbeNativeReadinessPreflightBlocked: Bool,
        didOpenEvidenceProbeNativeReadinessPreflight: Bool,
        didRequireNativeReadinessPreflightBeforeRuntimeProbe: Bool,
        didRequireNoApplicationAccessorCallForNativeReadiness: Bool,
        didRequireNoNativeBridgeExpansionForNativeReadiness: Bool,
        didRequireNoRuntimeProbeExecutionForNativeReadinessPreflight: Bool,
        didRequireNoSingletonCreationDuringNativeReadiness: Bool,
        didRequireScanOnlyEvidenceInputs: Bool,
        didRequireExistingOwnerProbeAndForbiddenScan: Bool,
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
        didKeepNativeReadinessPreflightReadinessDehydrated: Bool
    ) {
        this.evidenceProbeFirstSliceReadiness =
            evidenceProbeFirstSliceReadiness
        this.nativeReadinessPreflight = nativeReadinessPreflight
        this.didPrepareEvidenceProbeNativeReadinessPreflightReadiness =
            didPrepareEvidenceProbeNativeReadinessPreflightReadiness
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldDeferRuntimeProbeExecution =
            shouldDeferRuntimeProbeExecution
        this.shouldReportEvidenceProbeNativeReadinessPreflightBlocked =
            shouldReportEvidenceProbeNativeReadinessPreflightBlocked
        this.didOpenEvidenceProbeNativeReadinessPreflight =
            didOpenEvidenceProbeNativeReadinessPreflight
        this.didRequireNativeReadinessPreflightBeforeRuntimeProbe =
            didRequireNativeReadinessPreflightBeforeRuntimeProbe
        this.didRequireNoApplicationAccessorCallForNativeReadiness =
            didRequireNoApplicationAccessorCallForNativeReadiness
        this.didRequireNoNativeBridgeExpansionForNativeReadiness =
            didRequireNoNativeBridgeExpansionForNativeReadiness
        this.didRequireNoRuntimeProbeExecutionForNativeReadinessPreflight =
            didRequireNoRuntimeProbeExecutionForNativeReadinessPreflight
        this.didRequireNoSingletonCreationDuringNativeReadiness =
            didRequireNoSingletonCreationDuringNativeReadiness
        this.didRequireScanOnlyEvidenceInputs =
            didRequireScanOnlyEvidenceInputs
        this.didRequireExistingOwnerProbeAndForbiddenScan =
            didRequireExistingOwnerProbeAndForbiddenScan
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
        this.didKeepNativeReadinessPreflightReadinessDehydrated =
            didKeepNativeReadinessPreflightReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightFacts(
    evidenceProbeFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightFacts {
    let firstSliceReady =
        evidenceProbeFirstSliceReadiness
            .didPrepareEvidenceProbeFirstSliceReadiness &&
        evidenceProbeFirstSliceReadiness
            .shouldDeferProductionSingletonOwnerImplementation &&
        evidenceProbeFirstSliceReadiness
            .shouldDeferApplicationSingletonAccessorCall &&
        evidenceProbeFirstSliceReadiness.shouldDeferCleanupTeardownExecution &&
        !evidenceProbeFirstSliceReadiness
            .shouldReportEvidenceProbeFirstSliceBlocked &&
        evidenceProbeFirstSliceReadiness
            .didOpenMainThreadHeadlessFailClosedEvidenceProbeFirstSlice &&
        evidenceProbeFirstSliceReadiness
            .didRecordScanOnlyMainThreadConfinementEvidence &&
        evidenceProbeFirstSliceReadiness
            .didRecordScanOnlyHeadlessFailClosedEvidence &&
        evidenceProbeFirstSliceReadiness.didConfirmScanOnlyNoSingletonCreation &&
        evidenceProbeFirstSliceReadiness
            .didConfirmScanOnlyNoApplicationAccessorCall &&
        evidenceProbeFirstSliceReadiness.didConfirmNoNativeBridgeExpansion &&
        evidenceProbeFirstSliceReadiness.didConfirmNoRuntimeProbeExecution &&
        evidenceProbeFirstSliceReadiness.didCarryForwardNoSideEffectEvidenceOnly &&
        evidenceProbeFirstSliceReadiness
            .didCarryForwardTeardownCleanupResponsibilityOwnerRequired &&
        evidenceProbeFirstSliceReadiness
            .didCarryForwardMainThreadCreationConfinement &&
        evidenceProbeFirstSliceReadiness
            .didCarryForwardMainThreadCleanupConfinement &&
        evidenceProbeFirstSliceReadiness
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        evidenceProbeFirstSliceReadiness.didDeferActivation &&
        evidenceProbeFirstSliceReadiness.didDeferActivationPolicyMutation &&
        evidenceProbeFirstSliceReadiness.didDeferAppKitEventLoop &&
        evidenceProbeFirstSliceReadiness.didDeferBoundedRunLoopPump &&
        evidenceProbeFirstSliceReadiness.didDeferVisibleOrder &&
        evidenceProbeFirstSliceReadiness.didDeferDrawableAndRender &&
        evidenceProbeFirstSliceReadiness
            .didBlockArtifactPublicDiagnosticsPublication &&
        evidenceProbeFirstSliceReadiness.didConfirmNoPublicApi &&
        evidenceProbeFirstSliceReadiness.didConfirmNoProductionPublicCAbi &&
        evidenceProbeFirstSliceReadiness.didConfirmNoRendererStateWrite &&
        evidenceProbeFirstSliceReadiness.didConfirmNoRuntimeStateWrite &&
        evidenceProbeFirstSliceReadiness.didConfirmNoCjpmTomlChange &&
        evidenceProbeFirstSliceReadiness
            .didKeepProductionSingletonOwnershipTruthFalse &&
        evidenceProbeFirstSliceReadiness
            .didKeepEvidenceProbeFirstSliceReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightFacts(
        firstSliceReady,
        firstSliceReady,
        firstSliceReady,
        firstSliceReady &&
            evidenceProbeFirstSliceReadiness
                .didConfirmScanOnlyNoApplicationAccessorCall,
        firstSliceReady &&
            evidenceProbeFirstSliceReadiness.didConfirmNoNativeBridgeExpansion,
        firstSliceReady &&
            evidenceProbeFirstSliceReadiness.didConfirmNoRuntimeProbeExecution,
        firstSliceReady &&
            evidenceProbeFirstSliceReadiness
                .didConfirmScanOnlyNoSingletonCreation,
        firstSliceReady &&
            evidenceProbeFirstSliceReadiness
                .didCarryForwardNoSideEffectEvidenceOnly,
        firstSliceReady,
        firstSliceReady &&
            evidenceProbeFirstSliceReadiness
                .didRecordScanOnlyMainThreadConfinementEvidence,
        firstSliceReady &&
            evidenceProbeFirstSliceReadiness
                .didRecordScanOnlyHeadlessFailClosedEvidence,
        firstSliceReady &&
            evidenceProbeFirstSliceReadiness
                .didCarryForwardNoSideEffectEvidenceOnly,
        firstSliceReady &&
            evidenceProbeFirstSliceReadiness
                .didCarryForwardTeardownCleanupResponsibilityOwnerRequired,
        firstSliceReady &&
            evidenceProbeFirstSliceReadiness
                .didCarryForwardMainThreadCreationConfinement,
        firstSliceReady &&
            evidenceProbeFirstSliceReadiness
                .didCarryForwardMainThreadCleanupConfinement,
        firstSliceReady &&
            evidenceProbeFirstSliceReadiness
                .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation,
        firstSliceReady &&
            evidenceProbeFirstSliceReadiness
                .shouldDeferProductionSingletonOwnerImplementation,
        firstSliceReady &&
            evidenceProbeFirstSliceReadiness
                .shouldDeferApplicationSingletonAccessorCall,
        firstSliceReady &&
            evidenceProbeFirstSliceReadiness.shouldDeferCleanupTeardownExecution,
        evidenceProbeFirstSliceReadiness.didDeferActivation,
        evidenceProbeFirstSliceReadiness.didDeferActivationPolicyMutation,
        evidenceProbeFirstSliceReadiness.didDeferAppKitEventLoop,
        evidenceProbeFirstSliceReadiness.didDeferBoundedRunLoopPump,
        evidenceProbeFirstSliceReadiness.didDeferVisibleOrder,
        evidenceProbeFirstSliceReadiness.didDeferDrawableAndRender,
        evidenceProbeFirstSliceReadiness
            .didBlockArtifactPublicDiagnosticsPublication,
        evidenceProbeFirstSliceReadiness.didConfirmNoPublicApi,
        evidenceProbeFirstSliceReadiness.didConfirmNoProductionPublicCAbi,
        evidenceProbeFirstSliceReadiness.didConfirmNoRendererStateWrite,
        evidenceProbeFirstSliceReadiness.didConfirmNoRuntimeStateWrite,
        evidenceProbeFirstSliceReadiness.didConfirmNoCjpmTomlChange,
        evidenceProbeFirstSliceReadiness
            .didKeepProductionSingletonOwnershipTruthFalse,
        firstSliceReady,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflight(
    nativeReadinessPreflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflight {
    let admitted =
        nativeReadinessPreflightFacts
            .didConsumeMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness &&
        nativeReadinessPreflightFacts
            .didOpenEvidenceProbeNativeReadinessPreflight &&
        nativeReadinessPreflightFacts
            .didRequireNativeReadinessPreflightBeforeRuntimeProbe &&
        nativeReadinessPreflightFacts
            .didRequireNoApplicationAccessorCallForNativeReadiness &&
        nativeReadinessPreflightFacts
            .didRequireNoNativeBridgeExpansionForNativeReadiness &&
        nativeReadinessPreflightFacts
            .didRequireNoRuntimeProbeExecutionForNativeReadinessPreflight &&
        nativeReadinessPreflightFacts
            .didRequireNoSingletonCreationDuringNativeReadiness &&
        nativeReadinessPreflightFacts.didRequireScanOnlyEvidenceInputs &&
        nativeReadinessPreflightFacts.didRequireExistingOwnerProbeAndForbiddenScan &&
        nativeReadinessPreflightFacts
            .didCarryForwardScanOnlyMainThreadConfinementEvidence &&
        nativeReadinessPreflightFacts
            .didCarryForwardScanOnlyHeadlessFailClosedEvidence &&
        nativeReadinessPreflightFacts.didCarryForwardNoSideEffectEvidenceOnly &&
        nativeReadinessPreflightFacts
            .didCarryForwardTeardownCleanupResponsibilityOwnerRequired &&
        nativeReadinessPreflightFacts
            .didCarryForwardMainThreadCreationConfinement &&
        nativeReadinessPreflightFacts
            .didCarryForwardMainThreadCleanupConfinement &&
        nativeReadinessPreflightFacts
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        nativeReadinessPreflightFacts
            .didDeferProductionSingletonOwnerImplementation &&
        nativeReadinessPreflightFacts
            .didDeferApplicationSingletonAccessorCall &&
        nativeReadinessPreflightFacts.didDeferCleanupTeardownExecution &&
        nativeReadinessPreflightFacts.didDeferActivation &&
        nativeReadinessPreflightFacts.didDeferActivationPolicyMutation &&
        nativeReadinessPreflightFacts.didDeferAppKitEventLoop &&
        nativeReadinessPreflightFacts.didDeferBoundedRunLoopPump &&
        nativeReadinessPreflightFacts.didDeferVisibleOrder &&
        nativeReadinessPreflightFacts.didDeferDrawableAndRender &&
        nativeReadinessPreflightFacts
            .didBlockArtifactPublicDiagnosticsPublication &&
        nativeReadinessPreflightFacts.didConfirmNoPublicApi &&
        nativeReadinessPreflightFacts.didConfirmNoProductionPublicCAbi &&
        nativeReadinessPreflightFacts.didConfirmNoRendererStateWrite &&
        nativeReadinessPreflightFacts.didConfirmNoRuntimeStateWrite &&
        nativeReadinessPreflightFacts.didConfirmNoCjpmTomlChange &&
        nativeReadinessPreflightFacts
            .didKeepProductionSingletonOwnershipTruthFalse &&
        nativeReadinessPreflightFacts
            .didKeepNativeReadinessPreflightReadinessDehydrated &&
        nativeReadinessPreflightFacts
            .didRequireFutureNativeReadinessValueBoundarySeparateBoundary &&
        nativeReadinessPreflightFacts.didAvoidApplicationReadyWrapper &&
        nativeReadinessPreflightFacts.didAvoidSingletonOwnerReadyWrapper &&
        nativeReadinessPreflightFacts.didAvoidNativeProbeReadyWrapper &&
        nativeReadinessPreflightFacts.didAvoidBackendReadyWrapper

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflight(
        nativeReadinessPreflightFacts,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        nativeReadinessPreflightFacts
            .didRequireNoApplicationAccessorCallForNativeReadiness,
        nativeReadinessPreflightFacts
            .didRequireNoNativeBridgeExpansionForNativeReadiness,
        nativeReadinessPreflightFacts
            .didRequireNoRuntimeProbeExecutionForNativeReadinessPreflight,
        nativeReadinessPreflightFacts
            .didKeepProductionSingletonOwnershipTruthFalse,
        nativeReadinessPreflightFacts
            .didKeepNativeReadinessPreflightReadinessDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightReadiness(
    evidenceProbeFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness,
    nativeReadinessPreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflight
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightReadiness {
    let facts = nativeReadinessPreflight.nativeReadinessPreflightFacts
    let admitted =
        nativeReadinessPreflight.didAdmitEvidenceProbeNativeReadinessPreflight

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightReadiness(
        evidenceProbeFirstSliceReadiness,
        nativeReadinessPreflight,
        admitted,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        facts.didOpenEvidenceProbeNativeReadinessPreflight,
        facts.didRequireNativeReadinessPreflightBeforeRuntimeProbe,
        facts.didRequireNoApplicationAccessorCallForNativeReadiness,
        facts.didRequireNoNativeBridgeExpansionForNativeReadiness,
        facts.didRequireNoRuntimeProbeExecutionForNativeReadinessPreflight,
        facts.didRequireNoSingletonCreationDuringNativeReadiness,
        facts.didRequireScanOnlyEvidenceInputs,
        facts.didRequireExistingOwnerProbeAndForbiddenScan,
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
        facts.didKeepNativeReadinessPreflightReadinessDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightReadiness {
    let evidenceProbeFirstSliceReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceDraft()
    let nativeReadinessPreflightFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightFacts(
            evidenceProbeFirstSliceReadiness
        )
    let nativeReadinessPreflight =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflight(
            nativeReadinessPreflightFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightReadiness(
        evidenceProbeFirstSliceReadiness,
        nativeReadinessPreflight
    )
}
