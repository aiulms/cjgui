// 中文维护注释：本文件是 visible-window production harness NSApplication
// application-singleton CJGUI-owned lifecycle main-thread / headless fail-closed
// evidence probe preflight owner。
// Owner: runtime renderer internal CJGUI-owned application lifecycle evidence
// probe preflight owner。
// Truth: 只消费 CJGUI-owned lifecycle main-thread / headless fail-closed value
// boundary readiness，把 main-thread confinement evidence probe 与 headless / CI
// fail-closed evidence probe 固定为 no-singleton-creation preflight facts；不创建
// singleton，不调用 application accessor，不执行 cleanup / teardown，不把
// readiness 升级成 production singleton ownership truth。
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightFacts {
    let didConsumeMainThreadHeadlessFailClosedValueBoundaryReadiness: Bool
    let didOpenMainThreadHeadlessFailClosedEvidenceProbePreflight: Bool
    let didRequireMainThreadConfinementEvidenceProbePreflight: Bool
    let didRequireHeadlessFailClosedEvidenceProbePreflight: Bool
    let didRequireNoSingletonCreationDuringEvidenceProbe: Bool
    let didRequireNoApplicationSingletonAccessorCallDuringEvidenceProbe: Bool
    let didRequireProbeUsesExistingNoSideEffectEvidenceOnly: Bool
    let didRequireNoNativeBridgeExpansionForProbePreflight: Bool
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
    let didKeepEvidenceProbePreflightReadinessDehydrated: Bool
    let didRequireFutureEvidenceProbeFirstSliceSeparateBoundary: Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidSingletonOwnerReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didConsumeMainThreadHeadlessFailClosedValueBoundaryReadiness: Bool,
        didOpenMainThreadHeadlessFailClosedEvidenceProbePreflight: Bool,
        didRequireMainThreadConfinementEvidenceProbePreflight: Bool,
        didRequireHeadlessFailClosedEvidenceProbePreflight: Bool,
        didRequireNoSingletonCreationDuringEvidenceProbe: Bool,
        didRequireNoApplicationSingletonAccessorCallDuringEvidenceProbe: Bool,
        didRequireProbeUsesExistingNoSideEffectEvidenceOnly: Bool,
        didRequireNoNativeBridgeExpansionForProbePreflight: Bool,
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
        didKeepEvidenceProbePreflightReadinessDehydrated: Bool,
        didRequireFutureEvidenceProbeFirstSliceSeparateBoundary: Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidSingletonOwnerReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didConsumeMainThreadHeadlessFailClosedValueBoundaryReadiness =
            didConsumeMainThreadHeadlessFailClosedValueBoundaryReadiness
        this.didOpenMainThreadHeadlessFailClosedEvidenceProbePreflight =
            didOpenMainThreadHeadlessFailClosedEvidenceProbePreflight
        this.didRequireMainThreadConfinementEvidenceProbePreflight =
            didRequireMainThreadConfinementEvidenceProbePreflight
        this.didRequireHeadlessFailClosedEvidenceProbePreflight =
            didRequireHeadlessFailClosedEvidenceProbePreflight
        this.didRequireNoSingletonCreationDuringEvidenceProbe =
            didRequireNoSingletonCreationDuringEvidenceProbe
        this.didRequireNoApplicationSingletonAccessorCallDuringEvidenceProbe =
            didRequireNoApplicationSingletonAccessorCallDuringEvidenceProbe
        this.didRequireProbeUsesExistingNoSideEffectEvidenceOnly =
            didRequireProbeUsesExistingNoSideEffectEvidenceOnly
        this.didRequireNoNativeBridgeExpansionForProbePreflight =
            didRequireNoNativeBridgeExpansionForProbePreflight
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
        this.didKeepEvidenceProbePreflightReadinessDehydrated =
            didKeepEvidenceProbePreflightReadinessDehydrated
        this.didRequireFutureEvidenceProbeFirstSliceSeparateBoundary =
            didRequireFutureEvidenceProbeFirstSliceSeparateBoundary
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidSingletonOwnerReadyWrapper =
            didAvoidSingletonOwnerReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflight {
    let evidenceProbePreflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightFacts
    let didAdmitEvidenceProbePreflight: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldReportEvidenceProbePreflightBlocked: Bool
    let didRequireNoSingletonCreationDuringEvidenceProbe: Bool
    let didRequireNoNativeBridgeExpansionForProbePreflight: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepEvidenceProbePreflightReadinessDehydrated: Bool

    init(
        evidenceProbePreflightFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightFacts,
        didAdmitEvidenceProbePreflight: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldReportEvidenceProbePreflightBlocked: Bool,
        didRequireNoSingletonCreationDuringEvidenceProbe: Bool,
        didRequireNoNativeBridgeExpansionForProbePreflight: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepEvidenceProbePreflightReadinessDehydrated: Bool
    ) {
        this.evidenceProbePreflightFacts = evidenceProbePreflightFacts
        this.didAdmitEvidenceProbePreflight = didAdmitEvidenceProbePreflight
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldReportEvidenceProbePreflightBlocked =
            shouldReportEvidenceProbePreflightBlocked
        this.didRequireNoSingletonCreationDuringEvidenceProbe =
            didRequireNoSingletonCreationDuringEvidenceProbe
        this.didRequireNoNativeBridgeExpansionForProbePreflight =
            didRequireNoNativeBridgeExpansionForProbePreflight
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepEvidenceProbePreflightReadinessDehydrated =
            didKeepEvidenceProbePreflightReadinessDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness {
    let mainThreadHeadlessFailClosedValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryReadiness
    let evidenceProbePreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflight
    let didPrepareEvidenceProbePreflightReadiness: Bool
    let shouldDeferProductionSingletonOwnerImplementation: Bool
    let shouldDeferApplicationSingletonAccessorCall: Bool
    let shouldDeferCleanupTeardownExecution: Bool
    let shouldReportEvidenceProbePreflightBlocked: Bool
    let didOpenMainThreadHeadlessFailClosedEvidenceProbePreflight: Bool
    let didRequireMainThreadConfinementEvidenceProbePreflight: Bool
    let didRequireHeadlessFailClosedEvidenceProbePreflight: Bool
    let didRequireNoSingletonCreationDuringEvidenceProbe: Bool
    let didRequireNoApplicationSingletonAccessorCallDuringEvidenceProbe: Bool
    let didRequireProbeUsesExistingNoSideEffectEvidenceOnly: Bool
    let didRequireNoNativeBridgeExpansionForProbePreflight: Bool
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
    let didKeepEvidenceProbePreflightReadinessDehydrated: Bool

    init(
        mainThreadHeadlessFailClosedValueBoundaryReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryReadiness,
        evidenceProbePreflight:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflight,
        didPrepareEvidenceProbePreflightReadiness: Bool,
        shouldDeferProductionSingletonOwnerImplementation: Bool,
        shouldDeferApplicationSingletonAccessorCall: Bool,
        shouldDeferCleanupTeardownExecution: Bool,
        shouldReportEvidenceProbePreflightBlocked: Bool,
        didOpenMainThreadHeadlessFailClosedEvidenceProbePreflight: Bool,
        didRequireMainThreadConfinementEvidenceProbePreflight: Bool,
        didRequireHeadlessFailClosedEvidenceProbePreflight: Bool,
        didRequireNoSingletonCreationDuringEvidenceProbe: Bool,
        didRequireNoApplicationSingletonAccessorCallDuringEvidenceProbe: Bool,
        didRequireProbeUsesExistingNoSideEffectEvidenceOnly: Bool,
        didRequireNoNativeBridgeExpansionForProbePreflight: Bool,
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
        didKeepEvidenceProbePreflightReadinessDehydrated: Bool
    ) {
        this.mainThreadHeadlessFailClosedValueBoundaryReadiness =
            mainThreadHeadlessFailClosedValueBoundaryReadiness
        this.evidenceProbePreflight = evidenceProbePreflight
        this.didPrepareEvidenceProbePreflightReadiness =
            didPrepareEvidenceProbePreflightReadiness
        this.shouldDeferProductionSingletonOwnerImplementation =
            shouldDeferProductionSingletonOwnerImplementation
        this.shouldDeferApplicationSingletonAccessorCall =
            shouldDeferApplicationSingletonAccessorCall
        this.shouldDeferCleanupTeardownExecution =
            shouldDeferCleanupTeardownExecution
        this.shouldReportEvidenceProbePreflightBlocked =
            shouldReportEvidenceProbePreflightBlocked
        this.didOpenMainThreadHeadlessFailClosedEvidenceProbePreflight =
            didOpenMainThreadHeadlessFailClosedEvidenceProbePreflight
        this.didRequireMainThreadConfinementEvidenceProbePreflight =
            didRequireMainThreadConfinementEvidenceProbePreflight
        this.didRequireHeadlessFailClosedEvidenceProbePreflight =
            didRequireHeadlessFailClosedEvidenceProbePreflight
        this.didRequireNoSingletonCreationDuringEvidenceProbe =
            didRequireNoSingletonCreationDuringEvidenceProbe
        this.didRequireNoApplicationSingletonAccessorCallDuringEvidenceProbe =
            didRequireNoApplicationSingletonAccessorCallDuringEvidenceProbe
        this.didRequireProbeUsesExistingNoSideEffectEvidenceOnly =
            didRequireProbeUsesExistingNoSideEffectEvidenceOnly
        this.didRequireNoNativeBridgeExpansionForProbePreflight =
            didRequireNoNativeBridgeExpansionForProbePreflight
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
        this.didKeepEvidenceProbePreflightReadinessDehydrated =
            didKeepEvidenceProbePreflightReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightFacts(
    mainThreadHeadlessFailClosedValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightFacts {
    let valueBoundaryReady =
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didPrepareMainThreadHeadlessFailClosedValueBoundaryReadiness &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .shouldDeferProductionSingletonOwnerImplementation &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .shouldDeferApplicationSingletonAccessorCall &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .shouldDeferCleanupTeardownExecution &&
        !mainThreadHeadlessFailClosedValueBoundaryReadiness
            .shouldReportMainThreadHeadlessFailClosedValueBoundaryBlocked &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didOpenMainThreadHeadlessFailClosedValueBoundary &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didCarryForwardTeardownCleanupResponsibilityOwnerRequired &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didRequireMainThreadCreationConfinement &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didRequireMainThreadCleanupConfinement &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didRequireHeadlessCiFailClosedBeforeSingletonCreation &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didForbidBackgroundThreadApplicationSingletonCreation &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didForbidHeadlessApplicationSingletonCreation &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness.didDeferActivation &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didDeferActivationPolicyMutation &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness.didDeferAppKitEventLoop &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didDeferBoundedRunLoopPump &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness.didDeferVisibleOrder &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didDeferDrawableAndRender &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didBlockArtifactPublicDiagnosticsPublication &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness.didConfirmNoPublicApi &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didConfirmNoProductionPublicCAbi &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didConfirmNoRendererStateWrite &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didConfirmNoRuntimeStateWrite &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness.didConfirmNoCjpmTomlChange &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didKeepProductionSingletonOwnershipTruthFalse &&
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didKeepMainThreadHeadlessFailClosedReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightFacts(
        valueBoundaryReady,
        valueBoundaryReady,
        valueBoundaryReady,
        valueBoundaryReady,
        valueBoundaryReady &&
            mainThreadHeadlessFailClosedValueBoundaryReadiness
                .didForbidBackgroundThreadApplicationSingletonCreation &&
            mainThreadHeadlessFailClosedValueBoundaryReadiness
                .didForbidHeadlessApplicationSingletonCreation,
        valueBoundaryReady &&
            mainThreadHeadlessFailClosedValueBoundaryReadiness
                .didConfirmNoNewApplicationSingletonAccessorCall,
        valueBoundaryReady,
        valueBoundaryReady,
        valueBoundaryReady &&
            mainThreadHeadlessFailClosedValueBoundaryReadiness
                .didCarryForwardTeardownCleanupResponsibilityOwnerRequired,
        valueBoundaryReady &&
            mainThreadHeadlessFailClosedValueBoundaryReadiness
                .didRequireMainThreadCreationConfinement,
        valueBoundaryReady &&
            mainThreadHeadlessFailClosedValueBoundaryReadiness
                .didRequireMainThreadCleanupConfinement,
        valueBoundaryReady &&
            mainThreadHeadlessFailClosedValueBoundaryReadiness
                .didRequireHeadlessCiFailClosedBeforeSingletonCreation,
        valueBoundaryReady &&
            mainThreadHeadlessFailClosedValueBoundaryReadiness
                .shouldDeferProductionSingletonOwnerImplementation,
        valueBoundaryReady &&
            mainThreadHeadlessFailClosedValueBoundaryReadiness
                .shouldDeferApplicationSingletonAccessorCall,
        valueBoundaryReady &&
            mainThreadHeadlessFailClosedValueBoundaryReadiness
                .shouldDeferCleanupTeardownExecution,
        mainThreadHeadlessFailClosedValueBoundaryReadiness.didDeferActivation,
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didDeferActivationPolicyMutation,
        mainThreadHeadlessFailClosedValueBoundaryReadiness.didDeferAppKitEventLoop,
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didDeferBoundedRunLoopPump,
        mainThreadHeadlessFailClosedValueBoundaryReadiness.didDeferVisibleOrder,
        mainThreadHeadlessFailClosedValueBoundaryReadiness.didDeferDrawableAndRender,
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didBlockArtifactPublicDiagnosticsPublication,
        mainThreadHeadlessFailClosedValueBoundaryReadiness.didConfirmNoPublicApi,
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didConfirmNoProductionPublicCAbi,
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didConfirmNoRendererStateWrite,
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didConfirmNoRuntimeStateWrite,
        mainThreadHeadlessFailClosedValueBoundaryReadiness.didConfirmNoCjpmTomlChange,
        mainThreadHeadlessFailClosedValueBoundaryReadiness
            .didKeepProductionSingletonOwnershipTruthFalse,
        valueBoundaryReady,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflight(
    evidenceProbePreflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflight {
    let admitted =
        evidenceProbePreflightFacts
            .didConsumeMainThreadHeadlessFailClosedValueBoundaryReadiness &&
        evidenceProbePreflightFacts
            .didOpenMainThreadHeadlessFailClosedEvidenceProbePreflight &&
        evidenceProbePreflightFacts
            .didRequireMainThreadConfinementEvidenceProbePreflight &&
        evidenceProbePreflightFacts
            .didRequireHeadlessFailClosedEvidenceProbePreflight &&
        evidenceProbePreflightFacts
            .didRequireNoSingletonCreationDuringEvidenceProbe &&
        evidenceProbePreflightFacts
            .didRequireNoApplicationSingletonAccessorCallDuringEvidenceProbe &&
        evidenceProbePreflightFacts
            .didRequireProbeUsesExistingNoSideEffectEvidenceOnly &&
        evidenceProbePreflightFacts
            .didRequireNoNativeBridgeExpansionForProbePreflight &&
        evidenceProbePreflightFacts
            .didCarryForwardTeardownCleanupResponsibilityOwnerRequired &&
        evidenceProbePreflightFacts
            .didCarryForwardMainThreadCreationConfinement &&
        evidenceProbePreflightFacts
            .didCarryForwardMainThreadCleanupConfinement &&
        evidenceProbePreflightFacts
            .didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation &&
        evidenceProbePreflightFacts.didDeferProductionSingletonOwnerImplementation &&
        evidenceProbePreflightFacts.didDeferApplicationSingletonAccessorCall &&
        evidenceProbePreflightFacts.didDeferCleanupTeardownExecution &&
        evidenceProbePreflightFacts.didDeferActivation &&
        evidenceProbePreflightFacts.didDeferActivationPolicyMutation &&
        evidenceProbePreflightFacts.didDeferAppKitEventLoop &&
        evidenceProbePreflightFacts.didDeferBoundedRunLoopPump &&
        evidenceProbePreflightFacts.didDeferVisibleOrder &&
        evidenceProbePreflightFacts.didDeferDrawableAndRender &&
        evidenceProbePreflightFacts.didBlockArtifactPublicDiagnosticsPublication &&
        evidenceProbePreflightFacts.didConfirmNoPublicApi &&
        evidenceProbePreflightFacts.didConfirmNoProductionPublicCAbi &&
        evidenceProbePreflightFacts.didConfirmNoRendererStateWrite &&
        evidenceProbePreflightFacts.didConfirmNoRuntimeStateWrite &&
        evidenceProbePreflightFacts.didConfirmNoCjpmTomlChange &&
        evidenceProbePreflightFacts.didKeepProductionSingletonOwnershipTruthFalse &&
        evidenceProbePreflightFacts.didKeepEvidenceProbePreflightReadinessDehydrated &&
        evidenceProbePreflightFacts
            .didRequireFutureEvidenceProbeFirstSliceSeparateBoundary &&
        evidenceProbePreflightFacts.didAvoidApplicationReadyWrapper &&
        evidenceProbePreflightFacts.didAvoidSingletonOwnerReadyWrapper &&
        evidenceProbePreflightFacts.didAvoidBackendReadyWrapper

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflight(
        evidenceProbePreflightFacts,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        evidenceProbePreflightFacts
            .didRequireNoSingletonCreationDuringEvidenceProbe,
        evidenceProbePreflightFacts
            .didRequireNoNativeBridgeExpansionForProbePreflight,
        evidenceProbePreflightFacts.didKeepProductionSingletonOwnershipTruthFalse,
        evidenceProbePreflightFacts
            .didKeepEvidenceProbePreflightReadinessDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness(
    mainThreadHeadlessFailClosedValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryReadiness,
    evidenceProbePreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflight
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness {
    let facts = evidenceProbePreflight.evidenceProbePreflightFacts
    let admitted = evidenceProbePreflight.didAdmitEvidenceProbePreflight

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness(
        mainThreadHeadlessFailClosedValueBoundaryReadiness,
        evidenceProbePreflight,
        admitted,
        admitted,
        admitted,
        admitted,
        !admitted,
        facts.didOpenMainThreadHeadlessFailClosedEvidenceProbePreflight,
        facts.didRequireMainThreadConfinementEvidenceProbePreflight,
        facts.didRequireHeadlessFailClosedEvidenceProbePreflight,
        facts.didRequireNoSingletonCreationDuringEvidenceProbe,
        facts.didRequireNoApplicationSingletonAccessorCallDuringEvidenceProbe,
        facts.didRequireProbeUsesExistingNoSideEffectEvidenceOnly,
        facts.didRequireNoNativeBridgeExpansionForProbePreflight,
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
        facts.didKeepEvidenceProbePreflightReadinessDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness {
    let mainThreadHeadlessFailClosedValueBoundaryReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryDraft()
    let evidenceProbePreflightFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightFacts(
            mainThreadHeadlessFailClosedValueBoundaryReadiness
        )
    let evidenceProbePreflight =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflight(
            evidenceProbePreflightFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness(
        mainThreadHeadlessFailClosedValueBoundaryReadiness,
        evidenceProbePreflight
    )
}
