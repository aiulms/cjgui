// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application production singleton ownership false-branch downstream
// owner。
// Owner: runtime renderer internal production singleton ownership false-branch
// downstream owner。
// Truth: 只消费 production singleton ownership value boundary readiness，把
// production singleton ownership false branch 路由回 source readiness / witness
// truth evidence gap；不把 value boundary 升级成 production singleton ownership
// truth、implementation permission 或 actual accessor call site。
// Stop-line: 不实现 production singleton owner，不新增 production accessor call
// site，不调用 application singleton accessor，不创建或激活 NSApplication，不修改
// activation policy，不运行 AppKit event loop / bounded pump，不执行 cleanup /
// teardown，不创建 window / view / layer，不 visible order，不取 drawable，不创建
// command queue / command buffer / encoder，不 render / commit / present / GPU
// submission，不发布 artifact / diagnostics，不返回 native identity，不写
// runtime_state.cj，不改 cjpm.toml，不扩 public API，不新增 production C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、
// accessor-ready、singleton-owner-ready、source-ready、visible-ready、
// drawable-ready、render-ready、backend-ready、renderer state write、receipt、
// record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstreamFacts {
    let didPreserveProductionSingletonOwnershipValueBoundaryReadiness: Bool
    let didClassifyProductionSingletonOwnershipFalseBranch: Bool
    let didRouteBackToSourceReadinessEvidenceGap: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepExternalPreexistingSingletonSourceWitnessTruthFalse: Bool
    let didKeepSourceReadinessTruthValueFalse: Bool
    let didKeepProductionSingletonImplementationBlocked: Bool
    let didKeepProductionActualAccessorCallSiteBlocked: Bool
    let didRequireExternalWitnessTruthBeforeImplementation: Bool
    let didRequireSourceReadinessTruthBeforeImplementation: Bool
    let didRequireCleanupOwnershipBeforeImplementation: Bool
    let didRequireMainThreadConfinementBeforeImplementation: Bool
    let didRequireHeadlessFailClosedBeforeImplementation: Bool
    let didKeepCleanupTeardownExecutionBlocked: Bool
    let didConfirmNoActualAccessorProductionCallSite: Bool
    let didConfirmNoApplicationAccessorCall: Bool
    let didConfirmNoActivationPolicyMutation: Bool
    let didConfirmNoApplicationActivation: Bool
    let didConfirmNoAppKitEventLoop: Bool
    let didConfirmNoBoundedRunLoopPump: Bool
    let didConfirmNoWindowViewLayerCreation: Bool
    let didConfirmNoVisibleOrder: Bool
    let didConfirmNoDrawable: Bool
    let didConfirmNoCommandQueueBufferEncoder: Bool
    let didConfirmNoRenderCommitPresentGpuSubmission: Bool
    let didConfirmNoArtifactOrDiagnosticsPublication: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepFalseBranchDownstreamReadinessDehydrated: Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidAccessorReadyWrapper: Bool
    let didAvoidSingletonOwnerReadyWrapper: Bool
    let didAvoidSourceReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        didPreserveProductionSingletonOwnershipValueBoundaryReadiness: Bool,
        didClassifyProductionSingletonOwnershipFalseBranch: Bool,
        didRouteBackToSourceReadinessEvidenceGap: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepExternalPreexistingSingletonSourceWitnessTruthFalse:
            Bool,
        didKeepSourceReadinessTruthValueFalse: Bool,
        didKeepProductionSingletonImplementationBlocked: Bool,
        didKeepProductionActualAccessorCallSiteBlocked: Bool,
        didRequireExternalWitnessTruthBeforeImplementation: Bool,
        didRequireSourceReadinessTruthBeforeImplementation: Bool,
        didRequireCleanupOwnershipBeforeImplementation: Bool,
        didRequireMainThreadConfinementBeforeImplementation: Bool,
        didRequireHeadlessFailClosedBeforeImplementation: Bool,
        didKeepCleanupTeardownExecutionBlocked: Bool,
        didConfirmNoActualAccessorProductionCallSite: Bool,
        didConfirmNoApplicationAccessorCall: Bool,
        didConfirmNoActivationPolicyMutation: Bool,
        didConfirmNoApplicationActivation: Bool,
        didConfirmNoAppKitEventLoop: Bool,
        didConfirmNoBoundedRunLoopPump: Bool,
        didConfirmNoWindowViewLayerCreation: Bool,
        didConfirmNoVisibleOrder: Bool,
        didConfirmNoDrawable: Bool,
        didConfirmNoCommandQueueBufferEncoder: Bool,
        didConfirmNoRenderCommitPresentGpuSubmission: Bool,
        didConfirmNoArtifactOrDiagnosticsPublication: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepFalseBranchDownstreamReadinessDehydrated: Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidAccessorReadyWrapper: Bool,
        didAvoidSingletonOwnerReadyWrapper: Bool,
        didAvoidSourceReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.didPreserveProductionSingletonOwnershipValueBoundaryReadiness =
            didPreserveProductionSingletonOwnershipValueBoundaryReadiness
        this.didClassifyProductionSingletonOwnershipFalseBranch =
            didClassifyProductionSingletonOwnershipFalseBranch
        this.didRouteBackToSourceReadinessEvidenceGap =
            didRouteBackToSourceReadinessEvidenceGap
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepExternalPreexistingSingletonSourceWitnessTruthFalse =
            didKeepExternalPreexistingSingletonSourceWitnessTruthFalse
        this.didKeepSourceReadinessTruthValueFalse =
            didKeepSourceReadinessTruthValueFalse
        this.didKeepProductionSingletonImplementationBlocked =
            didKeepProductionSingletonImplementationBlocked
        this.didKeepProductionActualAccessorCallSiteBlocked =
            didKeepProductionActualAccessorCallSiteBlocked
        this.didRequireExternalWitnessTruthBeforeImplementation =
            didRequireExternalWitnessTruthBeforeImplementation
        this.didRequireSourceReadinessTruthBeforeImplementation =
            didRequireSourceReadinessTruthBeforeImplementation
        this.didRequireCleanupOwnershipBeforeImplementation =
            didRequireCleanupOwnershipBeforeImplementation
        this.didRequireMainThreadConfinementBeforeImplementation =
            didRequireMainThreadConfinementBeforeImplementation
        this.didRequireHeadlessFailClosedBeforeImplementation =
            didRequireHeadlessFailClosedBeforeImplementation
        this.didKeepCleanupTeardownExecutionBlocked =
            didKeepCleanupTeardownExecutionBlocked
        this.didConfirmNoActualAccessorProductionCallSite =
            didConfirmNoActualAccessorProductionCallSite
        this.didConfirmNoApplicationAccessorCall =
            didConfirmNoApplicationAccessorCall
        this.didConfirmNoActivationPolicyMutation =
            didConfirmNoActivationPolicyMutation
        this.didConfirmNoApplicationActivation =
            didConfirmNoApplicationActivation
        this.didConfirmNoAppKitEventLoop = didConfirmNoAppKitEventLoop
        this.didConfirmNoBoundedRunLoopPump =
            didConfirmNoBoundedRunLoopPump
        this.didConfirmNoWindowViewLayerCreation =
            didConfirmNoWindowViewLayerCreation
        this.didConfirmNoVisibleOrder = didConfirmNoVisibleOrder
        this.didConfirmNoDrawable = didConfirmNoDrawable
        this.didConfirmNoCommandQueueBufferEncoder =
            didConfirmNoCommandQueueBufferEncoder
        this.didConfirmNoRenderCommitPresentGpuSubmission =
            didConfirmNoRenderCommitPresentGpuSubmission
        this.didConfirmNoArtifactOrDiagnosticsPublication =
            didConfirmNoArtifactOrDiagnosticsPublication
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite =
            didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepFalseBranchDownstreamReadinessDehydrated =
            didKeepFalseBranchDownstreamReadinessDehydrated
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidAccessorReadyWrapper = didAvoidAccessorReadyWrapper
        this.didAvoidSingletonOwnerReadyWrapper =
            didAvoidSingletonOwnerReadyWrapper
        this.didAvoidSourceReadyWrapper = didAvoidSourceReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstream {
    let falseBranchDownstreamFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstreamFacts
    let didAdmitProductionSingletonOwnershipFalseBranchDownstream: Bool
    let shouldDeferProductionSingletonOwnershipFalseBranchDownstream:
        Bool
    let shouldReportProductionSingletonOwnershipFalseBranchDownstreamBlocked:
        Bool
    let didClassifyProductionSingletonOwnershipFalseBranch: Bool
    let didRouteBackToSourceReadinessEvidenceGap: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepProductionSingletonImplementationBlocked: Bool
    let didKeepProductionActualAccessorCallSiteBlocked: Bool
    let didKeepFalseBranchDownstreamDehydrated: Bool

    init(
        falseBranchDownstreamFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstreamFacts,
        didAdmitProductionSingletonOwnershipFalseBranchDownstream: Bool,
        shouldDeferProductionSingletonOwnershipFalseBranchDownstream:
            Bool,
        shouldReportProductionSingletonOwnershipFalseBranchDownstreamBlocked:
            Bool,
        didClassifyProductionSingletonOwnershipFalseBranch: Bool,
        didRouteBackToSourceReadinessEvidenceGap: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepProductionSingletonImplementationBlocked: Bool,
        didKeepProductionActualAccessorCallSiteBlocked: Bool,
        didKeepFalseBranchDownstreamDehydrated: Bool
    ) {
        this.falseBranchDownstreamFacts = falseBranchDownstreamFacts
        this.didAdmitProductionSingletonOwnershipFalseBranchDownstream =
            didAdmitProductionSingletonOwnershipFalseBranchDownstream
        this.shouldDeferProductionSingletonOwnershipFalseBranchDownstream =
            shouldDeferProductionSingletonOwnershipFalseBranchDownstream
        this.shouldReportProductionSingletonOwnershipFalseBranchDownstreamBlocked =
            shouldReportProductionSingletonOwnershipFalseBranchDownstreamBlocked
        this.didClassifyProductionSingletonOwnershipFalseBranch =
            didClassifyProductionSingletonOwnershipFalseBranch
        this.didRouteBackToSourceReadinessEvidenceGap =
            didRouteBackToSourceReadinessEvidenceGap
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepProductionSingletonImplementationBlocked =
            didKeepProductionSingletonImplementationBlocked
        this.didKeepProductionActualAccessorCallSiteBlocked =
            didKeepProductionActualAccessorCallSiteBlocked
        this.didKeepFalseBranchDownstreamDehydrated =
            didKeepFalseBranchDownstreamDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstreamReadiness {
    let productionSingletonOwnershipValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryReadiness
    let productionSingletonOwnershipFalseBranchDownstream:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstream
    let didPrepareProductionSingletonOwnershipFalseBranchDownstreamReadiness:
        Bool
    let shouldDeferProductionSingletonOwnershipFalseBranchDownstreamReadiness:
        Bool
    let shouldReportProductionSingletonOwnershipFalseBranchDownstreamBlocked:
        Bool
    let didPreserveProductionSingletonOwnershipValueBoundaryReadiness: Bool
    let didClassifyProductionSingletonOwnershipFalseBranch: Bool
    let didRouteBackToSourceReadinessEvidenceGap: Bool
    let didKeepProductionSingletonOwnershipTruthFalse: Bool
    let didKeepProductionSingletonImplementationBlocked: Bool
    let didKeepProductionActualAccessorCallSiteBlocked: Bool
    let didKeepFalseBranchDownstreamReadinessDehydrated: Bool

    init(
        productionSingletonOwnershipValueBoundaryReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryReadiness,
        productionSingletonOwnershipFalseBranchDownstream:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstream,
        didPrepareProductionSingletonOwnershipFalseBranchDownstreamReadiness:
            Bool,
        shouldDeferProductionSingletonOwnershipFalseBranchDownstreamReadiness:
            Bool,
        shouldReportProductionSingletonOwnershipFalseBranchDownstreamBlocked:
            Bool,
        didPreserveProductionSingletonOwnershipValueBoundaryReadiness:
            Bool,
        didClassifyProductionSingletonOwnershipFalseBranch: Bool,
        didRouteBackToSourceReadinessEvidenceGap: Bool,
        didKeepProductionSingletonOwnershipTruthFalse: Bool,
        didKeepProductionSingletonImplementationBlocked: Bool,
        didKeepProductionActualAccessorCallSiteBlocked: Bool,
        didKeepFalseBranchDownstreamReadinessDehydrated: Bool
    ) {
        this.productionSingletonOwnershipValueBoundaryReadiness =
            productionSingletonOwnershipValueBoundaryReadiness
        this.productionSingletonOwnershipFalseBranchDownstream =
            productionSingletonOwnershipFalseBranchDownstream
        this.didPrepareProductionSingletonOwnershipFalseBranchDownstreamReadiness =
            didPrepareProductionSingletonOwnershipFalseBranchDownstreamReadiness
        this.shouldDeferProductionSingletonOwnershipFalseBranchDownstreamReadiness =
            shouldDeferProductionSingletonOwnershipFalseBranchDownstreamReadiness
        this.shouldReportProductionSingletonOwnershipFalseBranchDownstreamBlocked =
            shouldReportProductionSingletonOwnershipFalseBranchDownstreamBlocked
        this.didPreserveProductionSingletonOwnershipValueBoundaryReadiness =
            didPreserveProductionSingletonOwnershipValueBoundaryReadiness
        this.didClassifyProductionSingletonOwnershipFalseBranch =
            didClassifyProductionSingletonOwnershipFalseBranch
        this.didRouteBackToSourceReadinessEvidenceGap =
            didRouteBackToSourceReadinessEvidenceGap
        this.didKeepProductionSingletonOwnershipTruthFalse =
            didKeepProductionSingletonOwnershipTruthFalse
        this.didKeepProductionSingletonImplementationBlocked =
            didKeepProductionSingletonImplementationBlocked
        this.didKeepProductionActualAccessorCallSiteBlocked =
            didKeepProductionActualAccessorCallSiteBlocked
        this.didKeepFalseBranchDownstreamReadinessDehydrated =
            didKeepFalseBranchDownstreamReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstreamFacts(
    productionSingletonOwnershipValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstreamFacts {
    let valueBoundary =
        productionSingletonOwnershipValueBoundaryReadiness
            .productionSingletonOwnershipValueBoundary
    let valueFacts =
        valueBoundary.productionSingletonOwnershipValueBoundaryFacts
    let valueBoundaryReady =
        productionSingletonOwnershipValueBoundaryReadiness
            .didPrepareProductionSingletonOwnershipValueBoundaryReadiness &&
        productionSingletonOwnershipValueBoundaryReadiness
            .didOpenProductionSingletonOwnershipValueBoundary &&
        productionSingletonOwnershipValueBoundaryReadiness
            .didConfirmSourceReadinessTruthValueFalse &&
        productionSingletonOwnershipValueBoundaryReadiness
            .didConfirmProductionSingletonOwnershipTruthFalse &&
        productionSingletonOwnershipValueBoundaryReadiness
            .didConfirmProductionSingletonImplementationBlocked &&
        productionSingletonOwnershipValueBoundaryReadiness
            .didConfirmProductionActualAccessorCallSiteBlocked &&
        productionSingletonOwnershipValueBoundaryReadiness
            .didConfirmNoRuntimeStateWrite &&
        productionSingletonOwnershipValueBoundaryReadiness
            .didConfirmNoCjpmTomlChange &&
        productionSingletonOwnershipValueBoundaryReadiness
            .didKeepProductionSingletonOwnershipValueBoundaryReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstreamFacts(
        valueBoundaryReady,
        valueBoundary.didConfirmProductionSingletonOwnershipTruthFalse,
        productionSingletonOwnershipValueBoundaryReadiness
            .didConfirmSourceReadinessTruthValueFalse &&
            valueFacts.didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse,
        productionSingletonOwnershipValueBoundaryReadiness
            .didConfirmProductionSingletonOwnershipTruthFalse,
        valueFacts.didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse,
        productionSingletonOwnershipValueBoundaryReadiness
            .didConfirmSourceReadinessTruthValueFalse,
        productionSingletonOwnershipValueBoundaryReadiness
            .didConfirmProductionSingletonImplementationBlocked,
        productionSingletonOwnershipValueBoundaryReadiness
            .didConfirmProductionActualAccessorCallSiteBlocked,
        valueFacts.didRequireExternalPreexistingSingletonSourceBeforeOwnershipTruth &&
            valueFacts.didRequireWitnessTruthBeforeOwnershipTruth,
        valueFacts.didRequireSourceReadinessTruthBeforeOwnershipTruth,
        valueFacts.didRequireCleanupOwnershipBeforeImplementation,
        valueFacts.didRequireMainThreadConfinement,
        valueFacts.didRequireHeadlessFailClosed,
        valueFacts.didConfirmNoCleanupTeardownExecution,
        productionSingletonOwnershipValueBoundaryReadiness
            .didConfirmProductionActualAccessorCallSiteBlocked,
        valueFacts.didKeepActualAccessorCallInIsolatedNativeProbeOnly,
        valueFacts.didConfirmNoActivationPolicyMutation,
        valueFacts.didConfirmNoApplicationActivation,
        valueFacts.didConfirmNoAppKitEventLoop,
        valueFacts.didConfirmNoBoundedRunLoopPump,
        valueFacts.didConfirmNoWindowViewLayerCreation,
        valueFacts.didConfirmNoVisibleOrder,
        valueFacts.didConfirmNoDrawable,
        valueFacts.didConfirmNoCommandQueueBufferEncoder,
        valueFacts.didConfirmNoRenderCommitPresentGpuSubmission,
        valueFacts.didConfirmNoArtifactOrDiagnosticsPublication,
        valueFacts.didConfirmNoPointerHandleClassIdReturn,
        valueFacts.didConfirmNoPublicApi,
        valueFacts.didConfirmNoProductionPublicCAbi,
        productionSingletonOwnershipValueBoundaryReadiness
            .didConfirmNoRuntimeStateWrite,
        productionSingletonOwnershipValueBoundaryReadiness.didConfirmNoCjpmTomlChange,
        valueFacts.didConfirmNoRendererStateWrite,
        valueFacts.didConfirmNoBackendReadyTruth,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstream(
    falseBranchDownstreamFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstreamFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstream {
    let admitted =
        falseBranchDownstreamFacts
            .didPreserveProductionSingletonOwnershipValueBoundaryReadiness &&
        falseBranchDownstreamFacts
            .didClassifyProductionSingletonOwnershipFalseBranch &&
        falseBranchDownstreamFacts.didRouteBackToSourceReadinessEvidenceGap &&
        falseBranchDownstreamFacts.didKeepProductionSingletonOwnershipTruthFalse &&
        falseBranchDownstreamFacts
            .didKeepExternalPreexistingSingletonSourceWitnessTruthFalse &&
        falseBranchDownstreamFacts.didKeepSourceReadinessTruthValueFalse &&
        falseBranchDownstreamFacts
            .didKeepProductionSingletonImplementationBlocked &&
        falseBranchDownstreamFacts
            .didKeepProductionActualAccessorCallSiteBlocked &&
        falseBranchDownstreamFacts
            .didRequireExternalWitnessTruthBeforeImplementation &&
        falseBranchDownstreamFacts
            .didRequireSourceReadinessTruthBeforeImplementation &&
        falseBranchDownstreamFacts
            .didRequireCleanupOwnershipBeforeImplementation &&
        falseBranchDownstreamFacts
            .didRequireMainThreadConfinementBeforeImplementation &&
        falseBranchDownstreamFacts
            .didRequireHeadlessFailClosedBeforeImplementation &&
        falseBranchDownstreamFacts.didKeepCleanupTeardownExecutionBlocked &&
        falseBranchDownstreamFacts
            .didConfirmNoActualAccessorProductionCallSite &&
        falseBranchDownstreamFacts.didConfirmNoApplicationAccessorCall &&
        falseBranchDownstreamFacts.didConfirmNoActivationPolicyMutation &&
        falseBranchDownstreamFacts.didConfirmNoApplicationActivation &&
        falseBranchDownstreamFacts.didConfirmNoAppKitEventLoop &&
        falseBranchDownstreamFacts.didConfirmNoBoundedRunLoopPump &&
        falseBranchDownstreamFacts.didConfirmNoWindowViewLayerCreation &&
        falseBranchDownstreamFacts.didConfirmNoVisibleOrder &&
        falseBranchDownstreamFacts.didConfirmNoDrawable &&
        falseBranchDownstreamFacts.didConfirmNoCommandQueueBufferEncoder &&
        falseBranchDownstreamFacts
            .didConfirmNoRenderCommitPresentGpuSubmission &&
        falseBranchDownstreamFacts
            .didConfirmNoArtifactOrDiagnosticsPublication &&
        falseBranchDownstreamFacts.didConfirmNoPointerHandleClassIdReturn &&
        falseBranchDownstreamFacts.didConfirmNoPublicApi &&
        falseBranchDownstreamFacts.didConfirmNoProductionPublicCAbi &&
        falseBranchDownstreamFacts.didConfirmNoRuntimeStateWrite &&
        falseBranchDownstreamFacts.didConfirmNoCjpmTomlChange &&
        falseBranchDownstreamFacts.didConfirmNoRendererStateWrite &&
        falseBranchDownstreamFacts.didConfirmNoBackendReadyTruth &&
        falseBranchDownstreamFacts
            .didKeepFalseBranchDownstreamReadinessDehydrated &&
        falseBranchDownstreamFacts.didAvoidApplicationReadyWrapper &&
        falseBranchDownstreamFacts.didAvoidAccessorReadyWrapper &&
        falseBranchDownstreamFacts.didAvoidSingletonOwnerReadyWrapper &&
        falseBranchDownstreamFacts.didAvoidSourceReadyWrapper &&
        falseBranchDownstreamFacts.didAvoidBackendReadyWrapper &&
        falseBranchDownstreamFacts.didAvoidReceiptRecordPublication

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstream(
        falseBranchDownstreamFacts,
        admitted,
        !admitted,
        !admitted,
        falseBranchDownstreamFacts
            .didClassifyProductionSingletonOwnershipFalseBranch,
        falseBranchDownstreamFacts.didRouteBackToSourceReadinessEvidenceGap,
        falseBranchDownstreamFacts
            .didKeepProductionSingletonOwnershipTruthFalse,
        falseBranchDownstreamFacts
            .didKeepProductionSingletonImplementationBlocked,
        falseBranchDownstreamFacts
            .didKeepProductionActualAccessorCallSiteBlocked,
        falseBranchDownstreamFacts
            .didKeepFalseBranchDownstreamReadinessDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstreamReadiness(
    productionSingletonOwnershipValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryReadiness,
    productionSingletonOwnershipFalseBranchDownstream:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstream
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstreamReadiness {
    let facts =
        productionSingletonOwnershipFalseBranchDownstream
            .falseBranchDownstreamFacts
    let admitted =
        productionSingletonOwnershipFalseBranchDownstream
            .didAdmitProductionSingletonOwnershipFalseBranchDownstream

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstreamReadiness(
        productionSingletonOwnershipValueBoundaryReadiness,
        productionSingletonOwnershipFalseBranchDownstream,
        admitted,
        !admitted,
        !admitted,
        facts.didPreserveProductionSingletonOwnershipValueBoundaryReadiness,
        productionSingletonOwnershipFalseBranchDownstream
            .didClassifyProductionSingletonOwnershipFalseBranch,
        productionSingletonOwnershipFalseBranchDownstream
            .didRouteBackToSourceReadinessEvidenceGap,
        productionSingletonOwnershipFalseBranchDownstream
            .didKeepProductionSingletonOwnershipTruthFalse,
        productionSingletonOwnershipFalseBranchDownstream
            .didKeepProductionSingletonImplementationBlocked,
        productionSingletonOwnershipFalseBranchDownstream
            .didKeepProductionActualAccessorCallSiteBlocked,
        facts.didKeepFalseBranchDownstreamReadinessDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstreamDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstreamReadiness {
    let productionSingletonOwnershipValueBoundaryReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryDraft()
    let falseBranchDownstreamFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstreamFacts(
            productionSingletonOwnershipValueBoundaryReadiness
        )
    let falseBranchDownstream =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstream(
            falseBranchDownstreamFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstreamReadiness(
        productionSingletonOwnershipValueBoundaryReadiness,
        falseBranchDownstream
    )
}
