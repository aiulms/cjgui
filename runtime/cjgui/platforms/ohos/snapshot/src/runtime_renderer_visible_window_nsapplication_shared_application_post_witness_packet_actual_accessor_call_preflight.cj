// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application post-witness-packet actual accessor call preflight owner。
// Owner: runtime renderer internal post-witness-packet actual-call preflight
// revalidation owner。
// Truth: 只消费 witness packet truth admission preflight 与既有 no-call
// preflight guard readiness，固定本阶段只打开 actual-call preflight
// revalidation；不把 packet truth admission 升级为 witness truth、source
// readiness truth、production singleton ownership truth 或 actual accessor
// call permission。
// Stop-line: 不调用 application singleton accessor，不创建或激活
// NSApplication，不修改 activation policy，不运行 AppKit event loop /
// bounded pump，不执行 cleanup / teardown，不创建 window / view / layer，不
// visible order，不取 drawable，不 render / commit / present / GPU
// submission，不发布 artifact / diagnostics，不返回 native identity，不写
// runtime_state.cj，不改 cjpm.toml，不扩 public API，不新增 production C
// ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、
// accessor-ready、singleton-owner-ready、source-ready、visible-ready、
// drawable-ready、render-ready、backend-ready、renderer state write、receipt、
// record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightFacts {
    let didPreserveWitnessPacketTruthAdmissionPreflightReadiness: Bool
    let didPreserveActualAccessorCallPreflightGuardReadiness: Bool
    let didOpenPostWitnessPacketActualAccessorCallPreflightRevalidation: Bool
    let didConfirmOnlyActualCallPreflightOpened: Bool
    let didConfirmNoActualAccessorCallImplementation: Bool
    let didConfirmNoProductionActualAccessorCallSite: Bool
    let didRejectPacketTruthAdmissionAsWitnessTruth: Bool
    let didRejectPacketTruthAdmissionAsSourceReadinessTruth: Bool
    let didRejectPacketTruthAdmissionAsProductionSingletonOwnershipTruth:
        Bool
    let didRequireExplicitHumanDecisionBeforeActualCallFirstSlice: Bool
    let didRequireMainThreadConfinedFutureFirstSlice: Bool
    let didRequireIsolatedProbeFirstFutureFirstSlice: Bool
    let didConfirmNoActivationPolicyMutation: Bool
    let didConfirmNoApplicationActivation: Bool
    let didConfirmNoAppKitEventLoop: Bool
    let didConfirmNoBoundedRunLoopPump: Bool
    let didConfirmNoCleanupTeardownExecution: Bool
    let didConfirmNoWindowViewLayerCreation: Bool
    let didConfirmNoVisibleOrder: Bool
    let didConfirmNoDrawable: Bool
    let didConfirmNoRender: Bool
    let didConfirmNoArtifactPublication: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepPostWitnessPacketActualAccessorCallPreflightValueOnly: Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidAccessorReadyWrapper: Bool
    let didAvoidSingletonOwnerReadyWrapper: Bool
    let didAvoidSourceReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidRenderReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        didPreserveWitnessPacketTruthAdmissionPreflightReadiness: Bool,
        didPreserveActualAccessorCallPreflightGuardReadiness: Bool,
        didOpenPostWitnessPacketActualAccessorCallPreflightRevalidation:
            Bool,
        didConfirmOnlyActualCallPreflightOpened: Bool,
        didConfirmNoActualAccessorCallImplementation: Bool,
        didConfirmNoProductionActualAccessorCallSite: Bool,
        didRejectPacketTruthAdmissionAsWitnessTruth: Bool,
        didRejectPacketTruthAdmissionAsSourceReadinessTruth: Bool,
        didRejectPacketTruthAdmissionAsProductionSingletonOwnershipTruth:
            Bool,
        didRequireExplicitHumanDecisionBeforeActualCallFirstSlice: Bool,
        didRequireMainThreadConfinedFutureFirstSlice: Bool,
        didRequireIsolatedProbeFirstFutureFirstSlice: Bool,
        didConfirmNoActivationPolicyMutation: Bool,
        didConfirmNoApplicationActivation: Bool,
        didConfirmNoAppKitEventLoop: Bool,
        didConfirmNoBoundedRunLoopPump: Bool,
        didConfirmNoCleanupTeardownExecution: Bool,
        didConfirmNoWindowViewLayerCreation: Bool,
        didConfirmNoVisibleOrder: Bool,
        didConfirmNoDrawable: Bool,
        didConfirmNoRender: Bool,
        didConfirmNoArtifactPublication: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepPostWitnessPacketActualAccessorCallPreflightValueOnly:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidAccessorReadyWrapper: Bool,
        didAvoidSingletonOwnerReadyWrapper: Bool,
        didAvoidSourceReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidRenderReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.didPreserveWitnessPacketTruthAdmissionPreflightReadiness =
            didPreserveWitnessPacketTruthAdmissionPreflightReadiness
        this.didPreserveActualAccessorCallPreflightGuardReadiness =
            didPreserveActualAccessorCallPreflightGuardReadiness
        this.didOpenPostWitnessPacketActualAccessorCallPreflightRevalidation =
            didOpenPostWitnessPacketActualAccessorCallPreflightRevalidation
        this.didConfirmOnlyActualCallPreflightOpened =
            didConfirmOnlyActualCallPreflightOpened
        this.didConfirmNoActualAccessorCallImplementation =
            didConfirmNoActualAccessorCallImplementation
        this.didConfirmNoProductionActualAccessorCallSite =
            didConfirmNoProductionActualAccessorCallSite
        this.didRejectPacketTruthAdmissionAsWitnessTruth =
            didRejectPacketTruthAdmissionAsWitnessTruth
        this.didRejectPacketTruthAdmissionAsSourceReadinessTruth =
            didRejectPacketTruthAdmissionAsSourceReadinessTruth
        this.didRejectPacketTruthAdmissionAsProductionSingletonOwnershipTruth =
            didRejectPacketTruthAdmissionAsProductionSingletonOwnershipTruth
        this.didRequireExplicitHumanDecisionBeforeActualCallFirstSlice =
            didRequireExplicitHumanDecisionBeforeActualCallFirstSlice
        this.didRequireMainThreadConfinedFutureFirstSlice =
            didRequireMainThreadConfinedFutureFirstSlice
        this.didRequireIsolatedProbeFirstFutureFirstSlice =
            didRequireIsolatedProbeFirstFutureFirstSlice
        this.didConfirmNoActivationPolicyMutation =
            didConfirmNoActivationPolicyMutation
        this.didConfirmNoApplicationActivation =
            didConfirmNoApplicationActivation
        this.didConfirmNoAppKitEventLoop = didConfirmNoAppKitEventLoop
        this.didConfirmNoBoundedRunLoopPump =
            didConfirmNoBoundedRunLoopPump
        this.didConfirmNoCleanupTeardownExecution =
            didConfirmNoCleanupTeardownExecution
        this.didConfirmNoWindowViewLayerCreation =
            didConfirmNoWindowViewLayerCreation
        this.didConfirmNoVisibleOrder = didConfirmNoVisibleOrder
        this.didConfirmNoDrawable = didConfirmNoDrawable
        this.didConfirmNoRender = didConfirmNoRender
        this.didConfirmNoArtifactPublication =
            didConfirmNoArtifactPublication
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoRuntimeStateWrite =
            didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepPostWitnessPacketActualAccessorCallPreflightValueOnly =
            didKeepPostWitnessPacketActualAccessorCallPreflightValueOnly
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidAccessorReadyWrapper = didAvoidAccessorReadyWrapper
        this.didAvoidSingletonOwnerReadyWrapper =
            didAvoidSingletonOwnerReadyWrapper
        this.didAvoidSourceReadyWrapper = didAvoidSourceReadyWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidRenderReadyWrapper = didAvoidRenderReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflight {
    let postWitnessPacketActualAccessorCallPreflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightFacts
    let didAdmitPostWitnessPacketActualAccessorCallPreflight: Bool
    let shouldDeferPostWitnessPacketActualAccessorCallPreflight: Bool
    let shouldReportPostWitnessPacketActualAccessorCallBlocked: Bool
    let didConfirmOnlyActualCallPreflightOpened: Bool
    let didConfirmNoActualAccessorCallImplementation: Bool
    let didConfirmNoProductionActualAccessorCallSite: Bool
    let didRequireExplicitHumanDecisionBeforeActualCallFirstSlice: Bool
    let didRequireMainThreadConfinedFutureFirstSlice: Bool
    let didRequireIsolatedProbeFirstFutureFirstSlice: Bool
    let didConfirmNoActivationPolicyMutation: Bool
    let didConfirmNoApplicationActivation: Bool
    let didConfirmNoAppKitEventLoop: Bool
    let didConfirmNoBoundedRunLoopPump: Bool
    let didConfirmNoCleanupTeardownExecution: Bool
    let didConfirmNoVisibleOrder: Bool
    let didConfirmNoDrawable: Bool
    let didConfirmNoRender: Bool
    let didConfirmNoArtifactPublication: Bool
    let didKeepPostWitnessPacketActualAccessorCallPreflightValueOnly: Bool

    init(
        postWitnessPacketActualAccessorCallPreflightFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightFacts,
        didAdmitPostWitnessPacketActualAccessorCallPreflight: Bool,
        shouldDeferPostWitnessPacketActualAccessorCallPreflight: Bool,
        shouldReportPostWitnessPacketActualAccessorCallBlocked: Bool,
        didConfirmOnlyActualCallPreflightOpened: Bool,
        didConfirmNoActualAccessorCallImplementation: Bool,
        didConfirmNoProductionActualAccessorCallSite: Bool,
        didRequireExplicitHumanDecisionBeforeActualCallFirstSlice: Bool,
        didRequireMainThreadConfinedFutureFirstSlice: Bool,
        didRequireIsolatedProbeFirstFutureFirstSlice: Bool,
        didConfirmNoActivationPolicyMutation: Bool,
        didConfirmNoApplicationActivation: Bool,
        didConfirmNoAppKitEventLoop: Bool,
        didConfirmNoBoundedRunLoopPump: Bool,
        didConfirmNoCleanupTeardownExecution: Bool,
        didConfirmNoVisibleOrder: Bool,
        didConfirmNoDrawable: Bool,
        didConfirmNoRender: Bool,
        didConfirmNoArtifactPublication: Bool,
        didKeepPostWitnessPacketActualAccessorCallPreflightValueOnly: Bool
    ) {
        this.postWitnessPacketActualAccessorCallPreflightFacts =
            postWitnessPacketActualAccessorCallPreflightFacts
        this.didAdmitPostWitnessPacketActualAccessorCallPreflight =
            didAdmitPostWitnessPacketActualAccessorCallPreflight
        this.shouldDeferPostWitnessPacketActualAccessorCallPreflight =
            shouldDeferPostWitnessPacketActualAccessorCallPreflight
        this.shouldReportPostWitnessPacketActualAccessorCallBlocked =
            shouldReportPostWitnessPacketActualAccessorCallBlocked
        this.didConfirmOnlyActualCallPreflightOpened =
            didConfirmOnlyActualCallPreflightOpened
        this.didConfirmNoActualAccessorCallImplementation =
            didConfirmNoActualAccessorCallImplementation
        this.didConfirmNoProductionActualAccessorCallSite =
            didConfirmNoProductionActualAccessorCallSite
        this.didRequireExplicitHumanDecisionBeforeActualCallFirstSlice =
            didRequireExplicitHumanDecisionBeforeActualCallFirstSlice
        this.didRequireMainThreadConfinedFutureFirstSlice =
            didRequireMainThreadConfinedFutureFirstSlice
        this.didRequireIsolatedProbeFirstFutureFirstSlice =
            didRequireIsolatedProbeFirstFutureFirstSlice
        this.didConfirmNoActivationPolicyMutation =
            didConfirmNoActivationPolicyMutation
        this.didConfirmNoApplicationActivation =
            didConfirmNoApplicationActivation
        this.didConfirmNoAppKitEventLoop = didConfirmNoAppKitEventLoop
        this.didConfirmNoBoundedRunLoopPump =
            didConfirmNoBoundedRunLoopPump
        this.didConfirmNoCleanupTeardownExecution =
            didConfirmNoCleanupTeardownExecution
        this.didConfirmNoVisibleOrder = didConfirmNoVisibleOrder
        this.didConfirmNoDrawable = didConfirmNoDrawable
        this.didConfirmNoRender = didConfirmNoRender
        this.didConfirmNoArtifactPublication =
            didConfirmNoArtifactPublication
        this.didKeepPostWitnessPacketActualAccessorCallPreflightValueOnly =
            didKeepPostWitnessPacketActualAccessorCallPreflightValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightReadiness {
    let witnessPacketTruthAdmissionPreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightReadiness
    let actualAccessorCallPreflightGuardReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness
    let postWitnessPacketActualAccessorCallPreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflight
    let didPreparePostWitnessPacketActualAccessorCallPreflight: Bool
    let shouldDeferPostWitnessPacketActualAccessorCallPreflight: Bool
    let shouldReportPostWitnessPacketActualAccessorCallBlocked: Bool
    let didOpenPostWitnessPacketActualAccessorCallPreflightRevalidation: Bool
    let didConfirmOnlyActualCallPreflightOpened: Bool
    let didConfirmNoActualAccessorCallImplementation: Bool
    let didConfirmNoProductionActualAccessorCallSite: Bool
    let didRejectPacketTruthAdmissionAsWitnessTruth: Bool
    let didRejectPacketTruthAdmissionAsSourceReadinessTruth: Bool
    let didRejectPacketTruthAdmissionAsProductionSingletonOwnershipTruth:
        Bool
    let didRequireExplicitHumanDecisionBeforeActualCallFirstSlice: Bool
    let didRequireMainThreadConfinedFutureFirstSlice: Bool
    let didRequireIsolatedProbeFirstFutureFirstSlice: Bool
    let didConfirmNoActivationPolicyMutation: Bool
    let didConfirmNoApplicationActivation: Bool
    let didConfirmNoAppKitEventLoop: Bool
    let didConfirmNoBoundedRunLoopPump: Bool
    let didConfirmNoCleanupTeardownExecution: Bool
    let didConfirmNoWindowViewLayerCreation: Bool
    let didConfirmNoVisibleOrder: Bool
    let didConfirmNoDrawable: Bool
    let didConfirmNoRender: Bool
    let didConfirmNoArtifactPublication: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepPostWitnessPacketActualAccessorCallPreflightValueOnly: Bool

    init(
        witnessPacketTruthAdmissionPreflightReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightReadiness,
        actualAccessorCallPreflightGuardReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness,
        postWitnessPacketActualAccessorCallPreflight:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflight,
        didPreparePostWitnessPacketActualAccessorCallPreflight: Bool,
        shouldDeferPostWitnessPacketActualAccessorCallPreflight: Bool,
        shouldReportPostWitnessPacketActualAccessorCallBlocked: Bool,
        didOpenPostWitnessPacketActualAccessorCallPreflightRevalidation:
            Bool,
        didConfirmOnlyActualCallPreflightOpened: Bool,
        didConfirmNoActualAccessorCallImplementation: Bool,
        didConfirmNoProductionActualAccessorCallSite: Bool,
        didRejectPacketTruthAdmissionAsWitnessTruth: Bool,
        didRejectPacketTruthAdmissionAsSourceReadinessTruth: Bool,
        didRejectPacketTruthAdmissionAsProductionSingletonOwnershipTruth:
            Bool,
        didRequireExplicitHumanDecisionBeforeActualCallFirstSlice: Bool,
        didRequireMainThreadConfinedFutureFirstSlice: Bool,
        didRequireIsolatedProbeFirstFutureFirstSlice: Bool,
        didConfirmNoActivationPolicyMutation: Bool,
        didConfirmNoApplicationActivation: Bool,
        didConfirmNoAppKitEventLoop: Bool,
        didConfirmNoBoundedRunLoopPump: Bool,
        didConfirmNoCleanupTeardownExecution: Bool,
        didConfirmNoWindowViewLayerCreation: Bool,
        didConfirmNoVisibleOrder: Bool,
        didConfirmNoDrawable: Bool,
        didConfirmNoRender: Bool,
        didConfirmNoArtifactPublication: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepPostWitnessPacketActualAccessorCallPreflightValueOnly:
            Bool
    ) {
        this.witnessPacketTruthAdmissionPreflightReadiness =
            witnessPacketTruthAdmissionPreflightReadiness
        this.actualAccessorCallPreflightGuardReadiness =
            actualAccessorCallPreflightGuardReadiness
        this.postWitnessPacketActualAccessorCallPreflight =
            postWitnessPacketActualAccessorCallPreflight
        this.didPreparePostWitnessPacketActualAccessorCallPreflight =
            didPreparePostWitnessPacketActualAccessorCallPreflight
        this.shouldDeferPostWitnessPacketActualAccessorCallPreflight =
            shouldDeferPostWitnessPacketActualAccessorCallPreflight
        this.shouldReportPostWitnessPacketActualAccessorCallBlocked =
            shouldReportPostWitnessPacketActualAccessorCallBlocked
        this.didOpenPostWitnessPacketActualAccessorCallPreflightRevalidation =
            didOpenPostWitnessPacketActualAccessorCallPreflightRevalidation
        this.didConfirmOnlyActualCallPreflightOpened =
            didConfirmOnlyActualCallPreflightOpened
        this.didConfirmNoActualAccessorCallImplementation =
            didConfirmNoActualAccessorCallImplementation
        this.didConfirmNoProductionActualAccessorCallSite =
            didConfirmNoProductionActualAccessorCallSite
        this.didRejectPacketTruthAdmissionAsWitnessTruth =
            didRejectPacketTruthAdmissionAsWitnessTruth
        this.didRejectPacketTruthAdmissionAsSourceReadinessTruth =
            didRejectPacketTruthAdmissionAsSourceReadinessTruth
        this.didRejectPacketTruthAdmissionAsProductionSingletonOwnershipTruth =
            didRejectPacketTruthAdmissionAsProductionSingletonOwnershipTruth
        this.didRequireExplicitHumanDecisionBeforeActualCallFirstSlice =
            didRequireExplicitHumanDecisionBeforeActualCallFirstSlice
        this.didRequireMainThreadConfinedFutureFirstSlice =
            didRequireMainThreadConfinedFutureFirstSlice
        this.didRequireIsolatedProbeFirstFutureFirstSlice =
            didRequireIsolatedProbeFirstFutureFirstSlice
        this.didConfirmNoActivationPolicyMutation =
            didConfirmNoActivationPolicyMutation
        this.didConfirmNoApplicationActivation =
            didConfirmNoApplicationActivation
        this.didConfirmNoAppKitEventLoop = didConfirmNoAppKitEventLoop
        this.didConfirmNoBoundedRunLoopPump =
            didConfirmNoBoundedRunLoopPump
        this.didConfirmNoCleanupTeardownExecution =
            didConfirmNoCleanupTeardownExecution
        this.didConfirmNoWindowViewLayerCreation =
            didConfirmNoWindowViewLayerCreation
        this.didConfirmNoVisibleOrder = didConfirmNoVisibleOrder
        this.didConfirmNoDrawable = didConfirmNoDrawable
        this.didConfirmNoRender = didConfirmNoRender
        this.didConfirmNoArtifactPublication =
            didConfirmNoArtifactPublication
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoRuntimeStateWrite =
            didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepPostWitnessPacketActualAccessorCallPreflightValueOnly =
            didKeepPostWitnessPacketActualAccessorCallPreflightValueOnly
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightFacts(
    witnessPacketTruthAdmissionPreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightReadiness,
    actualAccessorCallPreflightGuardReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightFacts {
    let witnessPacketReady =
        witnessPacketTruthAdmissionPreflightReadiness
            .didPrepareExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflight &&
        witnessPacketTruthAdmissionPreflightReadiness
            .didRequireWitnessPacketAcceptanceGateBeforeTruthAdmission &&
        witnessPacketTruthAdmissionPreflightReadiness
            .didRequireAcceptedPacketReadinessCarryForward &&
        witnessPacketTruthAdmissionPreflightReadiness
            .didRequireAcceptedPacketRemainDehydrated &&
        witnessPacketTruthAdmissionPreflightReadiness
            .didRequireWitnessPacketTruthAdmissionRemainPreTruth &&
        witnessPacketTruthAdmissionPreflightReadiness
            .didRequireWitnessPacketTruthAdmissionRemainDehydrated &&
        witnessPacketTruthAdmissionPreflightReadiness
            .didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse &&
        witnessPacketTruthAdmissionPreflightReadiness
            .didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse &&
        witnessPacketTruthAdmissionPreflightReadiness
            .didConfirmProductionSingletonOwnershipTruthFalse &&
        witnessPacketTruthAdmissionPreflightReadiness
            .didConfirmProductionActualAccessorCallSiteBlocked &&
        witnessPacketTruthAdmissionPreflightReadiness
            .didKeepExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightDehydrated
    let guardReady =
        actualAccessorCallPreflightGuardReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness &&
        actualAccessorCallPreflightGuardReadiness
            .didConfirmActualCallFirstSliceExplicitApprovalMissing &&
        actualAccessorCallPreflightGuardReadiness
            .didConfirmMainThreadConfinedPreflightRequired &&
        actualAccessorCallPreflightGuardReadiness
            .didConfirmIsolatedProbeFirstRouteRequired &&
        actualAccessorCallPreflightGuardReadiness
            .didConfirmActualApplicationSingletonAccessorCallStillBlocked &&
        actualAccessorCallPreflightGuardReadiness
            .didConfirmNoApplicationSingletonAccessorCall &&
        actualAccessorCallPreflightGuardReadiness
            .didKeepNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightFacts(
        witnessPacketReady,
        guardReady,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflight(
    postWitnessPacketActualAccessorCallPreflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflight {
    let admitted =
        postWitnessPacketActualAccessorCallPreflightFacts
            .didPreserveWitnessPacketTruthAdmissionPreflightReadiness &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didPreserveActualAccessorCallPreflightGuardReadiness &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didOpenPostWitnessPacketActualAccessorCallPreflightRevalidation &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmOnlyActualCallPreflightOpened &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoActualAccessorCallImplementation &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoProductionActualAccessorCallSite &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didRejectPacketTruthAdmissionAsWitnessTruth &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didRejectPacketTruthAdmissionAsSourceReadinessTruth &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didRejectPacketTruthAdmissionAsProductionSingletonOwnershipTruth &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didRequireExplicitHumanDecisionBeforeActualCallFirstSlice &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didRequireMainThreadConfinedFutureFirstSlice &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didRequireIsolatedProbeFirstFutureFirstSlice &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoActivationPolicyMutation &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoApplicationActivation &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoAppKitEventLoop &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoBoundedRunLoopPump &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoCleanupTeardownExecution &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoWindowViewLayerCreation &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoVisibleOrder &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoDrawable &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoRender &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoArtifactPublication &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoPublicApi &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoRuntimeStateWrite &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoCjpmTomlChange &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoProductionPublicCAbi &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoPointerHandleClassIdReturn &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoRendererStateWrite &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoBackendReadyTruth &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didKeepPostWitnessPacketActualAccessorCallPreflightValueOnly &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didAvoidApplicationReadyWrapper &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didAvoidAccessorReadyWrapper &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didAvoidSingletonOwnerReadyWrapper &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didAvoidSourceReadyWrapper &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didAvoidVisibleReadyWrapper &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didAvoidDrawableReadyWrapper &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didAvoidRenderReadyWrapper &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didAvoidBackendReadyWrapper &&
        postWitnessPacketActualAccessorCallPreflightFacts
            .didAvoidReceiptRecordPublication

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflight(
        postWitnessPacketActualAccessorCallPreflightFacts,
        admitted,
        !admitted,
        !admitted,
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmOnlyActualCallPreflightOpened,
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoActualAccessorCallImplementation,
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoProductionActualAccessorCallSite,
        postWitnessPacketActualAccessorCallPreflightFacts
            .didRequireExplicitHumanDecisionBeforeActualCallFirstSlice,
        postWitnessPacketActualAccessorCallPreflightFacts
            .didRequireMainThreadConfinedFutureFirstSlice,
        postWitnessPacketActualAccessorCallPreflightFacts
            .didRequireIsolatedProbeFirstFutureFirstSlice,
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoActivationPolicyMutation,
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoApplicationActivation,
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoAppKitEventLoop,
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoBoundedRunLoopPump,
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoCleanupTeardownExecution,
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoVisibleOrder,
        postWitnessPacketActualAccessorCallPreflightFacts.didConfirmNoDrawable,
        postWitnessPacketActualAccessorCallPreflightFacts.didConfirmNoRender,
        postWitnessPacketActualAccessorCallPreflightFacts
            .didConfirmNoArtifactPublication,
        postWitnessPacketActualAccessorCallPreflightFacts
            .didKeepPostWitnessPacketActualAccessorCallPreflightValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightReadiness(
    witnessPacketTruthAdmissionPreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightReadiness,
    actualAccessorCallPreflightGuardReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness,
    postWitnessPacketActualAccessorCallPreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflight
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightReadiness {
    let admitted =
        postWitnessPacketActualAccessorCallPreflight
            .didAdmitPostWitnessPacketActualAccessorCallPreflight
    let facts =
        postWitnessPacketActualAccessorCallPreflight
            .postWitnessPacketActualAccessorCallPreflightFacts

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightReadiness(
        witnessPacketTruthAdmissionPreflightReadiness,
        actualAccessorCallPreflightGuardReadiness,
        postWitnessPacketActualAccessorCallPreflight,
        admitted,
        !admitted,
        !admitted,
        facts.didOpenPostWitnessPacketActualAccessorCallPreflightRevalidation,
        postWitnessPacketActualAccessorCallPreflight
            .didConfirmOnlyActualCallPreflightOpened,
        postWitnessPacketActualAccessorCallPreflight
            .didConfirmNoActualAccessorCallImplementation,
        postWitnessPacketActualAccessorCallPreflight
            .didConfirmNoProductionActualAccessorCallSite,
        facts.didRejectPacketTruthAdmissionAsWitnessTruth,
        facts.didRejectPacketTruthAdmissionAsSourceReadinessTruth,
        facts.didRejectPacketTruthAdmissionAsProductionSingletonOwnershipTruth,
        postWitnessPacketActualAccessorCallPreflight
            .didRequireExplicitHumanDecisionBeforeActualCallFirstSlice,
        postWitnessPacketActualAccessorCallPreflight
            .didRequireMainThreadConfinedFutureFirstSlice,
        postWitnessPacketActualAccessorCallPreflight
            .didRequireIsolatedProbeFirstFutureFirstSlice,
        postWitnessPacketActualAccessorCallPreflight
            .didConfirmNoActivationPolicyMutation,
        postWitnessPacketActualAccessorCallPreflight
            .didConfirmNoApplicationActivation,
        postWitnessPacketActualAccessorCallPreflight
            .didConfirmNoAppKitEventLoop,
        postWitnessPacketActualAccessorCallPreflight
            .didConfirmNoBoundedRunLoopPump,
        postWitnessPacketActualAccessorCallPreflight
            .didConfirmNoCleanupTeardownExecution,
        facts.didConfirmNoWindowViewLayerCreation,
        postWitnessPacketActualAccessorCallPreflight.didConfirmNoVisibleOrder,
        postWitnessPacketActualAccessorCallPreflight.didConfirmNoDrawable,
        postWitnessPacketActualAccessorCallPreflight.didConfirmNoRender,
        postWitnessPacketActualAccessorCallPreflight
            .didConfirmNoArtifactPublication,
        facts.didConfirmNoPublicApi,
        facts.didConfirmNoRuntimeStateWrite,
        facts.didConfirmNoCjpmTomlChange,
        facts.didConfirmNoProductionPublicCAbi,
        facts.didConfirmNoPointerHandleClassIdReturn,
        facts.didConfirmNoRendererStateWrite,
        facts.didConfirmNoBackendReadyTruth,
        postWitnessPacketActualAccessorCallPreflight
            .didKeepPostWitnessPacketActualAccessorCallPreflightValueOnly
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightReadiness {
    let witnessPacketTruthAdmissionPreflightReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightDraft()
    let actualAccessorCallPreflightGuardReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft()
    let postWitnessPacketActualAccessorCallPreflightFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightFacts(
            witnessPacketTruthAdmissionPreflightReadiness,
            actualAccessorCallPreflightGuardReadiness
        )
    let postWitnessPacketActualAccessorCallPreflight =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflight(
            postWitnessPacketActualAccessorCallPreflightFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightReadiness(
        witnessPacketTruthAdmissionPreflightReadiness,
        actualAccessorCallPreflightGuardReadiness,
        postWitnessPacketActualAccessorCallPreflight
    )
}
