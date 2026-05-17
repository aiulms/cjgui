// 中文维护注释：本文件是 visible-window production harness NSApplication
// application-singleton CJGUI-owned lifecycle main-thread / headless fail-closed
// evidence probe first-slice owner。
// Owner: runtime renderer internal CJGUI-owned application lifecycle scan-only
// evidence probe owner。
// Truth: 只消费 evidence probe preflight readiness，把 main-thread confinement
// evidence 与 headless / CI fail-closed evidence 记录为 scan-only / no-side-effect
// facts；不创建 singleton，不调用 application accessor，不扩展 native bridge，不执行
// cleanup / teardown，不把 readiness 升级成 production singleton ownership truth。
// Stop-line: 不实现 production singleton owner，不新增 production accessor call
// site，不调用 application singleton accessor，不创建或激活 NSApplication，不修改
// activation policy，不运行 AppKit event loop / bounded pump，不执行 cleanup /
// teardown，不创建 window / view / layer，不 visible order，不取 drawable，不创建
// command queue / command buffer / encoder，不 render / commit / present / GPU
// submission，不发布 artifact / diagnostics，不返回 native identity，不写
// runtime_state.cj，不改 cjpm.toml，不扩 public API，不新增 production C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、
// accessor-ready、singleton-owner-ready、cleanup-execution-ready、visible-ready、
// drawable-ready、render-ready、backend-ready、renderer state write、receipt、
// record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceFacts {
    let didConsumeMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness:
        Bool
    let didOpenMainThreadHeadlessFailClosedEvidenceProbeFirstSlice: Bool
    let didRecordScanOnlyMainThreadConfinementEvidence: Bool
    let didRecordScanOnlyHeadlessFailClosedEvidence: Bool
    let didConfirmScanOnlyNoSingletonCreation: Bool
    let didConfirmScanOnlyNoApplicationAccessorCall: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoRuntimeProbeExecution: Bool
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
    let didKeepEvidenceProbeFirstSliceReadinessDehydrated: Bool
    let didRequireFutureEvidenceProbeNativeSliceSeparateBoundary: Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidSingletonOwnerReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didConsumeMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness:
            Bool,
        didOpenMainThreadHeadlessFailClosedEvidenceProbeFirstSlice: Bool,
        didRecordScanOnlyMainThreadConfinementEvidence: Bool,
        didRecordScanOnlyHeadlessFailClosedEvidence: Bool,
        didConfirmScanOnlyNoSingletonCreation: Bool,
        didConfirmScanOnlyNoApplicationAccessorCall: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoRuntimeProbeExecution: Bool,
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
        didKeepEvidenceProbeFirstSliceReadinessDehydrated: Bool,
        didRequireFutureEvidenceProbeNativeSliceSeparateBoundary: Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidSingletonOwnerReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didConsumeMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness =
            didConsumeMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness
        this.didOpenMainThreadHeadlessFailClosedEvidenceProbeFirstSlice =
            didOpenMainThreadHeadlessFailClosedEvidenceProbeFirstSlice
        this.didRecordScanOnlyMainThreadConfinementEvidence =
            didRecordScanOnlyMainThreadConfinementEvidence
        this.didRecordScanOnlyHeadlessFailClosedEvidence =
            didRecordScanOnlyHeadlessFailClosedEvidence
        this.didConfirmScanOnlyNoSingletonCreation =
            didConfirmScanOnlyNoSingletonCreation
        this.didConfirmScanOnlyNoApplicationAccessorCall =
            didConfirmScanOnlyNoApplicationAccessorCall
        this.didConfirmNoNativeBridgeExpansion =
            didConfirmNoNativeBridgeExpansion
        this.didConfirmNoRuntimeProbeExecution =
            didConfirmNoRuntimeProbeExecution
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
        this.didKeepEvidenceProbeFirstSliceReadinessDehydrated =
            didKeepEvidenceProbeFirstSliceReadinessDehydrated
        this.didRequireFutureEvidenceProbeNativeSliceSeparateBoundary =
            didRequireFutureEvidenceProbeNativeSliceSeparateBoundary
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidSingletonOwnerReadyWrapper =
            didAvoidSingletonOwnerReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSlice {
    let evidenceProbeFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceFacts
    let didAdmitEvidenceProbeFirstSlice: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldReportEvidenceProbeFirstSliceBlocked: Bool
    let didConfirmScanOnlyNoSingletonCreation: Bool
    let didConfirmScanOnlyNoApplicationAccessorCall: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepEvidenceProbeFirstSliceReadinessDehydrated: Bool

    init(
        evidenceProbeFirstSliceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceFacts,
        didAdmitEvidenceProbeFirstSlice: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldReportEvidenceProbeFirstSliceBlocked: Bool,
        didConfirmScanOnlyNoSingletonCreation: Bool,
        didConfirmScanOnlyNoApplicationAccessorCall: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepEvidenceProbeFirstSliceReadinessDehydrated: Bool
    ) {
        this.evidenceProbeFirstSliceFacts = evidenceProbeFirstSliceFacts
        this.didAdmitEvidenceProbeFirstSlice =
            didAdmitEvidenceProbeFirstSlice
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldReportEvidenceProbeFirstSliceBlocked =
            shouldReportEvidenceProbeFirstSliceBlocked
        this.didConfirmScanOnlyNoSingletonCreation =
            didConfirmScanOnlyNoSingletonCreation
        this.didConfirmScanOnlyNoApplicationAccessorCall =
            didConfirmScanOnlyNoApplicationAccessorCall
        this.didConfirmNoNativeBridgeExpansion =
            didConfirmNoNativeBridgeExpansion
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepEvidenceProbeFirstSliceReadinessDehydrated =
            didKeepEvidenceProbeFirstSliceReadinessDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness {
    let evidenceProbePreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness
    let evidenceProbeFirstSlice:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSlice
    let didPrepareEvidenceProbeFirstSliceReadiness: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldReportEvidenceProbeFirstSliceBlocked: Bool
    let didOpenMainThreadHeadlessFailClosedEvidenceProbeFirstSlice: Bool
    let didRecordScanOnlyMainThreadConfinementEvidence: Bool
    let didRecordScanOnlyHeadlessFailClosedEvidence: Bool
    let didConfirmScanOnlyNoSingletonCreation: Bool
    let didConfirmScanOnlyNoApplicationAccessorCall: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoRuntimeProbeExecution: Bool
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
    let didKeepEvidenceProbeFirstSliceReadinessDehydrated: Bool

    init(
        evidenceProbePreflightReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness,
        evidenceProbeFirstSlice:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSlice,
        didPrepareEvidenceProbeFirstSliceReadiness: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldReportEvidenceProbeFirstSliceBlocked: Bool,
        didOpenMainThreadHeadlessFailClosedEvidenceProbeFirstSlice: Bool,
        didRecordScanOnlyMainThreadConfinementEvidence: Bool,
        didRecordScanOnlyHeadlessFailClosedEvidence: Bool,
        didConfirmScanOnlyNoSingletonCreation: Bool,
        didConfirmScanOnlyNoApplicationAccessorCall: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoRuntimeProbeExecution: Bool,
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
        didKeepEvidenceProbeFirstSliceReadinessDehydrated: Bool
    ) {
        this.evidenceProbePreflightReadiness =
            evidenceProbePreflightReadiness
        this.evidenceProbeFirstSlice = evidenceProbeFirstSlice
        this.didPrepareEvidenceProbeFirstSliceReadiness =
            didPrepareEvidenceProbeFirstSliceReadiness
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldReportEvidenceProbeFirstSliceBlocked =
            shouldReportEvidenceProbeFirstSliceBlocked
        this.didOpenMainThreadHeadlessFailClosedEvidenceProbeFirstSlice =
            didOpenMainThreadHeadlessFailClosedEvidenceProbeFirstSlice
        this.didRecordScanOnlyMainThreadConfinementEvidence =
            didRecordScanOnlyMainThreadConfinementEvidence
        this.didRecordScanOnlyHeadlessFailClosedEvidence =
            didRecordScanOnlyHeadlessFailClosedEvidence
        this.didConfirmScanOnlyNoSingletonCreation =
            didConfirmScanOnlyNoSingletonCreation
        this.didConfirmScanOnlyNoApplicationAccessorCall =
            didConfirmScanOnlyNoApplicationAccessorCall
        this.didConfirmNoNativeBridgeExpansion =
            didConfirmNoNativeBridgeExpansion
        this.didConfirmNoRuntimeProbeExecution =
            didConfirmNoRuntimeProbeExecution
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
        this.didKeepEvidenceProbeFirstSliceReadinessDehydrated =
            didKeepEvidenceProbeFirstSliceReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceFacts(
    evidenceProbePreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceFacts {
    let preflightReady =
        evidenceProbePreflightReadiness
            .didPrepareEvidenceProbePreflightReadiness &&
        evidenceProbePreflightReadiness
            .shouldDeferProductionSingletonOwnerImplementation &&
        evidenceProbePreflightReadiness
            .shouldDeferApplicationSingletonAccessorCall &&
        evidenceProbePreflightReadiness.shouldDeferCleanupTeardownExecution &&
        !evidenceProbePreflightReadiness
            .shouldReportEvidenceProbePreflightBlocked &&
        evidenceProbePreflightReadiness
            .didOpenMainThreadHeadlessFailClosedEvidenceProbePreflight &&
        evidenceProbePreflightReadiness
            .didRequireMainThreadConfinementEvidenceProbePreflight &&
        evidenceProbePreflightReadiness
            .didRequireHeadlessFailClosedEvidenceProbePreflight &&
        evidenceProbePreflightReadiness
            .didRequireNoSingletonCreationDuringEvidenceProbe &&
        evidenceProbePreflightReadiness
            .didRequireNoApplicationSingletonAccessorCallDuringEvidenceProbe &&
        evidenceProbePreflightReadiness
            .didRequireProbeUsesExistingNoSideEffectEvidenceOnly &&
        evidenceProbePreflightReadiness
            .didRequireNoNativeBridgeExpansionForProbePreflight &&
        evidenceProbePreflightReadiness
            .didCarryForwardTeardownCleanupResponsibilityOwnerRequired &&
        evidenceProbePreflightReadiness
            .didCarryForwardMainThreadCreationConfinement &&
        evidenceProbePreflightReadiness
            .didCarryForwardMainThreadCleanupConfinement &&
        evidenceProbePreflightReadiness
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        evidenceProbePreflightReadiness.didDeferActivation &&
        evidenceProbePreflightReadiness.didDeferActivationPolicyMutation &&
        evidenceProbePreflightReadiness.didDeferAppKitEventLoop &&
        evidenceProbePreflightReadiness.didDeferBoundedRunLoopPump &&
        evidenceProbePreflightReadiness.didDeferVisibleOrder &&
        evidenceProbePreflightReadiness.didDeferDrawableAndRender &&
        evidenceProbePreflightReadiness
            .didBlockArtifactPublicDiagnosticsPublication &&
        evidenceProbePreflightReadiness.didConfirmNoPublicApi &&
        evidenceProbePreflightReadiness.didConfirmNoProductionPublicCAbi &&
        evidenceProbePreflightReadiness.didConfirmNoRendererStateWrite &&
        evidenceProbePreflightReadiness.didConfirmNoRuntimeStateWrite &&
        evidenceProbePreflightReadiness.didConfirmNoCjpmTomlChange &&
        evidenceProbePreflightReadiness
            .didKeepProductionSingletonOwnershipTruthFalse &&
        evidenceProbePreflightReadiness
            .didKeepEvidenceProbePreflightReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceFacts(
        preflightReady,
        preflightReady,
        preflightReady &&
            evidenceProbePreflightReadiness
                .didRequireMainThreadConfinementEvidenceProbePreflight,
        preflightReady &&
            evidenceProbePreflightReadiness
                .didRequireHeadlessFailClosedEvidenceProbePreflight,
        preflightReady &&
            evidenceProbePreflightReadiness
                .didRequireNoSingletonCreationDuringEvidenceProbe,
        preflightReady &&
            evidenceProbePreflightReadiness
                .didRequireNoApplicationSingletonAccessorCallDuringEvidenceProbe,
        preflightReady &&
            evidenceProbePreflightReadiness
                .didRequireNoNativeBridgeExpansionForProbePreflight,
        preflightReady,
        preflightReady &&
            evidenceProbePreflightReadiness
                .didRequireProbeUsesExistingNoSideEffectEvidenceOnly,
        preflightReady &&
            evidenceProbePreflightReadiness
                .didCarryForwardTeardownCleanupResponsibilityOwnerRequired,
        preflightReady &&
            evidenceProbePreflightReadiness
                .didCarryForwardMainThreadCreationConfinement,
        preflightReady &&
            evidenceProbePreflightReadiness
                .didCarryForwardMainThreadCleanupConfinement,
        preflightReady &&
            evidenceProbePreflightReadiness
                .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation,
        preflightReady &&
            evidenceProbePreflightReadiness
                .shouldDeferProductionSingletonOwnerImplementation,
        preflightReady &&
            evidenceProbePreflightReadiness
                .shouldDeferApplicationSingletonAccessorCall,
        preflightReady &&
            evidenceProbePreflightReadiness
                .shouldDeferCleanupTeardownExecution,
        evidenceProbePreflightReadiness.didDeferActivation,
        evidenceProbePreflightReadiness.didDeferActivationPolicyMutation,
        evidenceProbePreflightReadiness.didDeferAppKitEventLoop,
        evidenceProbePreflightReadiness.didDeferBoundedRunLoopPump,
        evidenceProbePreflightReadiness.didDeferVisibleOrder,
        evidenceProbePreflightReadiness.didDeferDrawableAndRender,
        evidenceProbePreflightReadiness
            .didBlockArtifactPublicDiagnosticsPublication,
        evidenceProbePreflightReadiness.didConfirmNoPublicApi,
        evidenceProbePreflightReadiness.didConfirmNoProductionPublicCAbi,
        evidenceProbePreflightReadiness.didConfirmNoRendererStateWrite,
        evidenceProbePreflightReadiness.didConfirmNoRuntimeStateWrite,
        evidenceProbePreflightReadiness.didConfirmNoCjpmTomlChange,
        evidenceProbePreflightReadiness
            .didKeepProductionSingletonOwnershipTruthFalse,
        preflightReady,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSlice(
    evidenceProbeFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSlice {
    let admitted =
        evidenceProbeFirstSliceFacts
            .didConsumeMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness &&
        evidenceProbeFirstSliceFacts
            .didOpenMainThreadHeadlessFailClosedEvidenceProbeFirstSlice &&
        evidenceProbeFirstSliceFacts
            .didRecordScanOnlyMainThreadConfinementEvidence &&
        evidenceProbeFirstSliceFacts
            .didRecordScanOnlyHeadlessFailClosedEvidence &&
        evidenceProbeFirstSliceFacts.didConfirmScanOnlyNoSingletonCreation &&
        evidenceProbeFirstSliceFacts
            .didConfirmScanOnlyNoApplicationAccessorCall &&
        evidenceProbeFirstSliceFacts.didConfirmNoNativeBridgeExpansion &&
        evidenceProbeFirstSliceFacts.didConfirmNoRuntimeProbeExecution &&
        evidenceProbeFirstSliceFacts.didCarryForwardNoSideEffectEvidenceOnly &&
        evidenceProbeFirstSliceFacts
            .didCarryForwardTeardownCleanupResponsibilityOwnerRequired &&
        evidenceProbeFirstSliceFacts
            .didCarryForwardMainThreadCreationConfinement &&
        evidenceProbeFirstSliceFacts
            .didCarryForwardMainThreadCleanupConfinement &&
        evidenceProbeFirstSliceFacts
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        evidenceProbeFirstSliceFacts
            .didDeferProductionSingletonOwnerImplementation &&
        evidenceProbeFirstSliceFacts.didDeferApplicationSingletonAccessorCall &&
        evidenceProbeFirstSliceFacts.didDeferCleanupTeardownExecution &&
        evidenceProbeFirstSliceFacts.didDeferActivation &&
        evidenceProbeFirstSliceFacts.didDeferActivationPolicyMutation &&
        evidenceProbeFirstSliceFacts.didDeferAppKitEventLoop &&
        evidenceProbeFirstSliceFacts.didDeferBoundedRunLoopPump &&
        evidenceProbeFirstSliceFacts.didDeferVisibleOrder &&
        evidenceProbeFirstSliceFacts.didDeferDrawableAndRender &&
        evidenceProbeFirstSliceFacts
            .didBlockArtifactPublicDiagnosticsPublication &&
        evidenceProbeFirstSliceFacts.didConfirmNoPublicApi &&
        evidenceProbeFirstSliceFacts.didConfirmNoProductionPublicCAbi &&
        evidenceProbeFirstSliceFacts.didConfirmNoRendererStateWrite &&
        evidenceProbeFirstSliceFacts.didConfirmNoRuntimeStateWrite &&
        evidenceProbeFirstSliceFacts.didConfirmNoCjpmTomlChange &&
        evidenceProbeFirstSliceFacts
            .didKeepProductionSingletonOwnershipTruthFalse &&
        evidenceProbeFirstSliceFacts
            .didKeepEvidenceProbeFirstSliceReadinessDehydrated &&
        evidenceProbeFirstSliceFacts
            .didRequireFutureEvidenceProbeNativeSliceSeparateBoundary &&
        evidenceProbeFirstSliceFacts.didAvoidApplicationReadyWrapper &&
        evidenceProbeFirstSliceFacts.didAvoidSingletonOwnerReadyWrapper &&
        evidenceProbeFirstSliceFacts.didAvoidBackendReadyWrapper

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSlice(
        evidenceProbeFirstSliceFacts,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        evidenceProbeFirstSliceFacts.didConfirmScanOnlyNoSingletonCreation,
        evidenceProbeFirstSliceFacts
            .didConfirmScanOnlyNoApplicationAccessorCall,
        evidenceProbeFirstSliceFacts.didConfirmNoNativeBridgeExpansion,
        evidenceProbeFirstSliceFacts
            .didKeepProductionSingletonOwnershipTruthFalse,
        evidenceProbeFirstSliceFacts
            .didKeepEvidenceProbeFirstSliceReadinessDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness(
    evidenceProbePreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness,
    evidenceProbeFirstSlice:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSlice
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness {
    let facts = evidenceProbeFirstSlice.evidenceProbeFirstSliceFacts
    let admitted = evidenceProbeFirstSlice.didAdmitEvidenceProbeFirstSlice

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness(
        evidenceProbePreflightReadiness,
        evidenceProbeFirstSlice,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        facts.didOpenMainThreadHeadlessFailClosedEvidenceProbeFirstSlice,
        facts.didRecordScanOnlyMainThreadConfinementEvidence,
        facts.didRecordScanOnlyHeadlessFailClosedEvidence,
        facts.didConfirmScanOnlyNoSingletonCreation,
        facts.didConfirmScanOnlyNoApplicationAccessorCall,
        facts.didConfirmNoNativeBridgeExpansion,
        facts.didConfirmNoRuntimeProbeExecution,
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
        facts.didKeepEvidenceProbeFirstSliceReadinessDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness {
    let evidenceProbePreflightReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightDraft()
    let evidenceProbeFirstSliceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceFacts(
            evidenceProbePreflightReadiness
        )
    let evidenceProbeFirstSlice =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSlice(
            evidenceProbeFirstSliceFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness(
        evidenceProbePreflightReadiness,
        evidenceProbeFirstSlice
    )
}
