// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application production singleton ownership value boundary owner。
// Owner: runtime renderer internal production singleton ownership value
// boundary owner。
// Truth: 只消费 source readiness truth value boundary 与既有 source/cleanup
// boundary readiness，把 production singleton ownership 固定为 value-boundary /
// still-false；不把 source readiness、throwaway creation 或 isolated accessor
// probe 升级成 production singleton ownership truth。
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryFacts {
    let didPreserveSourceReadinessTruthValueBoundaryReadiness: Bool
    let didPreserveProductionSingletonOwnershipSourceCleanupBoundaryReadiness:
        Bool
    let didOpenProductionSingletonOwnershipValueBoundary: Bool
    let didRequireSourceReadinessTruthBeforeOwnershipTruth: Bool
    let didRequireExternalPreexistingSingletonSourceBeforeOwnershipTruth:
        Bool
    let didRequireWitnessTruthBeforeOwnershipTruth: Bool
    let didRequireCleanupOwnershipBeforeImplementation: Bool
    let didRequireMainThreadConfinement: Bool
    let didRequireHeadlessFailClosed: Bool
    let didConfirmSourceReadinessTruthValueFalse: Bool
    let didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse:
        Bool
    let didConfirmProductionSingletonOwnershipTruthFalse: Bool
    let didConfirmProductionSingletonImplementationBlocked: Bool
    let didConfirmProductionActualAccessorCallSiteBlocked: Bool
    let didRejectThrowawayCreationAsProductionOwnershipTruth: Bool
    let didKeepActualAccessorCallInIsolatedNativeProbeOnly: Bool
    let didConfirmNoActivationPolicyMutation: Bool
    let didConfirmNoApplicationActivation: Bool
    let didConfirmNoAppKitEventLoop: Bool
    let didConfirmNoBoundedRunLoopPump: Bool
    let didConfirmNoCleanupTeardownExecution: Bool
    let didConfirmNoWindowViewLayerCreation: Bool
    let didConfirmNoVisibleOrder: Bool
    let didConfirmNoDrawable: Bool
    let didConfirmNoCommandQueueBufferEncoder: Bool
    let didConfirmNoRenderCommitPresentGpuSubmission: Bool
    let didConfirmNoArtifactOrDiagnosticsPublication: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepProductionSingletonOwnershipValueBoundaryDehydrated: Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidAccessorReadyWrapper: Bool
    let didAvoidSingletonOwnerReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didPreserveSourceReadinessTruthValueBoundaryReadiness: Bool,
        didPreserveProductionSingletonOwnershipSourceCleanupBoundaryReadiness:
            Bool,
        didOpenProductionSingletonOwnershipValueBoundary: Bool,
        didRequireSourceReadinessTruthBeforeOwnershipTruth: Bool,
        didRequireExternalPreexistingSingletonSourceBeforeOwnershipTruth:
            Bool,
        didRequireWitnessTruthBeforeOwnershipTruth: Bool,
        didRequireCleanupOwnershipBeforeImplementation: Bool,
        didRequireMainThreadConfinement: Bool,
        didRequireHeadlessFailClosed: Bool,
        didConfirmSourceReadinessTruthValueFalse: Bool,
        didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse:
            Bool,
        didConfirmProductionSingletonOwnershipTruthFalse: Bool,
        didConfirmProductionSingletonImplementationBlocked: Bool,
        didConfirmProductionActualAccessorCallSiteBlocked: Bool,
        didRejectThrowawayCreationAsProductionOwnershipTruth: Bool,
        didKeepActualAccessorCallInIsolatedNativeProbeOnly: Bool,
        didConfirmNoActivationPolicyMutation: Bool,
        didConfirmNoApplicationActivation: Bool,
        didConfirmNoAppKitEventLoop: Bool,
        didConfirmNoBoundedRunLoopPump: Bool,
        didConfirmNoCleanupTeardownExecution: Bool,
        didConfirmNoWindowViewLayerCreation: Bool,
        didConfirmNoVisibleOrder: Bool,
        didConfirmNoDrawable: Bool,
        didConfirmNoCommandQueueBufferEncoder: Bool,
        didConfirmNoRenderCommitPresentGpuSubmission: Bool,
        didConfirmNoArtifactOrDiagnosticsPublication: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepProductionSingletonOwnershipValueBoundaryDehydrated: Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidAccessorReadyWrapper: Bool,
        didAvoidSingletonOwnerReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didPreserveSourceReadinessTruthValueBoundaryReadiness =
            didPreserveSourceReadinessTruthValueBoundaryReadiness
        this.didPreserveProductionSingletonOwnershipSourceCleanupBoundaryReadiness =
            didPreserveProductionSingletonOwnershipSourceCleanupBoundaryReadiness
        this.didOpenProductionSingletonOwnershipValueBoundary =
            didOpenProductionSingletonOwnershipValueBoundary
        this.didRequireSourceReadinessTruthBeforeOwnershipTruth =
            didRequireSourceReadinessTruthBeforeOwnershipTruth
        this.didRequireExternalPreexistingSingletonSourceBeforeOwnershipTruth =
            didRequireExternalPreexistingSingletonSourceBeforeOwnershipTruth
        this.didRequireWitnessTruthBeforeOwnershipTruth =
            didRequireWitnessTruthBeforeOwnershipTruth
        this.didRequireCleanupOwnershipBeforeImplementation =
            didRequireCleanupOwnershipBeforeImplementation
        this.didRequireMainThreadConfinement =
            didRequireMainThreadConfinement
        this.didRequireHeadlessFailClosed = didRequireHeadlessFailClosed
        this.didConfirmSourceReadinessTruthValueFalse =
            didConfirmSourceReadinessTruthValueFalse
        this.didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse =
            didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse
        this.didConfirmProductionSingletonOwnershipTruthFalse =
            didConfirmProductionSingletonOwnershipTruthFalse
        this.didConfirmProductionSingletonImplementationBlocked =
            didConfirmProductionSingletonImplementationBlocked
        this.didConfirmProductionActualAccessorCallSiteBlocked =
            didConfirmProductionActualAccessorCallSiteBlocked
        this.didRejectThrowawayCreationAsProductionOwnershipTruth =
            didRejectThrowawayCreationAsProductionOwnershipTruth
        this.didKeepActualAccessorCallInIsolatedNativeProbeOnly =
            didKeepActualAccessorCallInIsolatedNativeProbeOnly
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
        this.didConfirmNoCommandQueueBufferEncoder =
            didConfirmNoCommandQueueBufferEncoder
        this.didConfirmNoRenderCommitPresentGpuSubmission =
            didConfirmNoRenderCommitPresentGpuSubmission
        this.didConfirmNoArtifactOrDiagnosticsPublication =
            didConfirmNoArtifactOrDiagnosticsPublication
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite =
            didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepProductionSingletonOwnershipValueBoundaryDehydrated =
            didKeepProductionSingletonOwnershipValueBoundaryDehydrated
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidAccessorReadyWrapper = didAvoidAccessorReadyWrapper
        this.didAvoidSingletonOwnerReadyWrapper =
            didAvoidSingletonOwnerReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundary {
    let productionSingletonOwnershipValueBoundaryFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryFacts
    let didAdmitProductionSingletonOwnershipValueBoundary: Bool
    let shouldDeferProductionSingletonOwnershipValueBoundary: Bool
    let shouldReportProductionSingletonOwnershipValueBoundaryBlocked: Bool
    let didConfirmProductionSingletonOwnershipTruthFalse: Bool
    let didConfirmProductionSingletonImplementationBlocked: Bool
    let didConfirmProductionActualAccessorCallSiteBlocked: Bool
    let didKeepProductionSingletonOwnershipValueBoundaryDehydrated: Bool

    init(
        productionSingletonOwnershipValueBoundaryFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryFacts,
        didAdmitProductionSingletonOwnershipValueBoundary: Bool,
        shouldDeferProductionSingletonOwnershipValueBoundary: Bool,
        shouldReportProductionSingletonOwnershipValueBoundaryBlocked: Bool,
        didConfirmProductionSingletonOwnershipTruthFalse: Bool,
        didConfirmProductionSingletonImplementationBlocked: Bool,
        didConfirmProductionActualAccessorCallSiteBlocked: Bool,
        didKeepProductionSingletonOwnershipValueBoundaryDehydrated: Bool
    ) {
        this.productionSingletonOwnershipValueBoundaryFacts =
            productionSingletonOwnershipValueBoundaryFacts
        this.didAdmitProductionSingletonOwnershipValueBoundary =
            didAdmitProductionSingletonOwnershipValueBoundary
        this.shouldDeferProductionSingletonOwnershipValueBoundary =
            shouldDeferProductionSingletonOwnershipValueBoundary
        this.shouldReportProductionSingletonOwnershipValueBoundaryBlocked =
            shouldReportProductionSingletonOwnershipValueBoundaryBlocked
        this.didConfirmProductionSingletonOwnershipTruthFalse =
            didConfirmProductionSingletonOwnershipTruthFalse
        this.didConfirmProductionSingletonImplementationBlocked =
            didConfirmProductionSingletonImplementationBlocked
        this.didConfirmProductionActualAccessorCallSiteBlocked =
            didConfirmProductionActualAccessorCallSiteBlocked
        this.didKeepProductionSingletonOwnershipValueBoundaryDehydrated =
            didKeepProductionSingletonOwnershipValueBoundaryDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryReadiness {
    let sourceReadinessTruthValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessTruthValueBoundaryReadiness
    let sourceCleanupBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryReadiness
    let productionSingletonOwnershipValueBoundary:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundary
    let didPrepareProductionSingletonOwnershipValueBoundaryReadiness: Bool
    let shouldDeferProductionSingletonOwnershipValueBoundaryReadiness: Bool
    let shouldReportProductionSingletonOwnershipValueBoundaryBlocked: Bool
    let didOpenProductionSingletonOwnershipValueBoundary: Bool
    let didRequireSourceReadinessTruthBeforeOwnershipTruth: Bool
    let didConfirmSourceReadinessTruthValueFalse: Bool
    let didConfirmProductionSingletonOwnershipTruthFalse: Bool
    let didConfirmProductionSingletonImplementationBlocked: Bool
    let didConfirmProductionActualAccessorCallSiteBlocked: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didKeepProductionSingletonOwnershipValueBoundaryReadinessDehydrated:
        Bool

    init(
        sourceReadinessTruthValueBoundaryReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessTruthValueBoundaryReadiness,
        sourceCleanupBoundaryReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryReadiness,
        productionSingletonOwnershipValueBoundary:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundary,
        didPrepareProductionSingletonOwnershipValueBoundaryReadiness: Bool,
        shouldDeferProductionSingletonOwnershipValueBoundaryReadiness:
            Bool,
        shouldReportProductionSingletonOwnershipValueBoundaryBlocked:
            Bool,
        didOpenProductionSingletonOwnershipValueBoundary: Bool,
        didRequireSourceReadinessTruthBeforeOwnershipTruth: Bool,
        didConfirmSourceReadinessTruthValueFalse: Bool,
        didConfirmProductionSingletonOwnershipTruthFalse: Bool,
        didConfirmProductionSingletonImplementationBlocked: Bool,
        didConfirmProductionActualAccessorCallSiteBlocked: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didKeepProductionSingletonOwnershipValueBoundaryReadinessDehydrated:
            Bool
    ) {
        this.sourceReadinessTruthValueBoundaryReadiness =
            sourceReadinessTruthValueBoundaryReadiness
        this.sourceCleanupBoundaryReadiness = sourceCleanupBoundaryReadiness
        this.productionSingletonOwnershipValueBoundary =
            productionSingletonOwnershipValueBoundary
        this.didPrepareProductionSingletonOwnershipValueBoundaryReadiness =
            didPrepareProductionSingletonOwnershipValueBoundaryReadiness
        this.shouldDeferProductionSingletonOwnershipValueBoundaryReadiness =
            shouldDeferProductionSingletonOwnershipValueBoundaryReadiness
        this.shouldReportProductionSingletonOwnershipValueBoundaryBlocked =
            shouldReportProductionSingletonOwnershipValueBoundaryBlocked
        this.didOpenProductionSingletonOwnershipValueBoundary =
            didOpenProductionSingletonOwnershipValueBoundary
        this.didRequireSourceReadinessTruthBeforeOwnershipTruth =
            didRequireSourceReadinessTruthBeforeOwnershipTruth
        this.didConfirmSourceReadinessTruthValueFalse =
            didConfirmSourceReadinessTruthValueFalse
        this.didConfirmProductionSingletonOwnershipTruthFalse =
            didConfirmProductionSingletonOwnershipTruthFalse
        this.didConfirmProductionSingletonImplementationBlocked =
            didConfirmProductionSingletonImplementationBlocked
        this.didConfirmProductionActualAccessorCallSiteBlocked =
            didConfirmProductionActualAccessorCallSiteBlocked
        this.didConfirmNoRuntimeStateWrite =
            didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didKeepProductionSingletonOwnershipValueBoundaryReadinessDehydrated =
            didKeepProductionSingletonOwnershipValueBoundaryReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryFacts(
    sourceReadinessTruthValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessTruthValueBoundaryReadiness,
    sourceCleanupBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryFacts {
    let sourceFacts =
        sourceReadinessTruthValueBoundaryReadiness
            .sourceReadinessTruthValueBoundary
            .sourceReadinessTruthValueBoundaryFacts
    let cleanupFacts =
        sourceCleanupBoundaryReadiness
            .productionSingletonOwnershipSourceCleanupBoundary
            .sourceCleanupBoundaryFacts
    let sourceReady =
        sourceReadinessTruthValueBoundaryReadiness
            .didPrepareSourceReadinessTruthValueBoundaryReadiness &&
        sourceReadinessTruthValueBoundaryReadiness
            .didKeepSourceReadinessTruthConditional &&
        sourceReadinessTruthValueBoundaryReadiness
            .didConfirmSourceReadinessTruthValueFalse &&
        sourceReadinessTruthValueBoundaryReadiness
            .didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse &&
        sourceReadinessTruthValueBoundaryReadiness
            .didConfirmProductionSingletonOwnershipTruthFalse &&
        sourceReadinessTruthValueBoundaryReadiness
            .didConfirmProductionSingletonImplementationBlocked &&
        sourceReadinessTruthValueBoundaryReadiness
            .didConfirmProductionActualAccessorCallSiteBlocked &&
        sourceReadinessTruthValueBoundaryReadiness
            .didConfirmNoRuntimeStateWrite &&
        sourceReadinessTruthValueBoundaryReadiness
            .didConfirmNoCjpmTomlChange &&
        sourceReadinessTruthValueBoundaryReadiness
            .didKeepSourceReadinessTruthValueBoundaryReadinessDehydrated
    let cleanupReady =
        sourceCleanupBoundaryReadiness
            .didPrepareProductionSingletonOwnershipSourceCleanupBoundaryReadiness &&
        sourceCleanupBoundaryReadiness
            .didRejectThrowawaySingletonAsProductionOwnershipSource &&
        sourceCleanupBoundaryReadiness
            .didRequireExternalPreexistingSingletonSource &&
        sourceCleanupBoundaryReadiness
            .didRequireFutureRuntimeOwnerExplicitApproval &&
        sourceCleanupBoundaryReadiness
            .didRequireCleanupResponsibilityBeforeImplementation &&
        sourceCleanupBoundaryReadiness
            .didConfirmProductionSingletonOwnershipTruthFalse &&
        sourceCleanupBoundaryReadiness
            .didConfirmProductionSingletonImplementationBlocked &&
        sourceCleanupBoundaryReadiness
            .didConfirmProductionActualAccessorCallSiteBlocked &&
        sourceCleanupBoundaryReadiness
            .didKeepProductionSingletonOwnershipSourceCleanupBoundaryReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryFacts(
        sourceReady,
        cleanupReady,
        true,
        true,
        sourceFacts.didRequireExternalOwnerIdentityCarryForward &&
            sourceFacts.didRequirePreexistingSingletonObservationCarryForward &&
            cleanupFacts.didRequireExternalPreexistingSingletonSource,
        sourceFacts.didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse,
        sourceFacts.didRequireCleanupOwnershipCarryForward &&
            cleanupFacts.didRequireCleanupResponsibilityBeforeImplementation,
        sourceFacts.didRequireMainThreadObservationCarryForward &&
            cleanupFacts.didRequireMainThreadConfinement,
        sourceFacts.didRequireHeadlessFailClosedCarryForward &&
            cleanupFacts.didRequireHeadlessFailClosed,
        sourceReadinessTruthValueBoundaryReadiness
            .didConfirmSourceReadinessTruthValueFalse,
        sourceReadinessTruthValueBoundaryReadiness
            .didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse,
        sourceReadinessTruthValueBoundaryReadiness
            .didConfirmProductionSingletonOwnershipTruthFalse &&
            sourceCleanupBoundaryReadiness
                .didConfirmProductionSingletonOwnershipTruthFalse,
        sourceReadinessTruthValueBoundaryReadiness
            .didConfirmProductionSingletonImplementationBlocked &&
            sourceCleanupBoundaryReadiness
                .didConfirmProductionSingletonImplementationBlocked,
        sourceReadinessTruthValueBoundaryReadiness
            .didConfirmProductionActualAccessorCallSiteBlocked &&
            sourceCleanupBoundaryReadiness
                .didConfirmProductionActualAccessorCallSiteBlocked,
        sourceFacts.didRejectThrowawayCreationAsProductionOwnershipTruth &&
            cleanupFacts.didRejectThrowawaySingletonAsProductionOwnershipSource,
        sourceFacts.didKeepActualAccessorCallInIsolatedNativeProbeOnly,
        sourceFacts.didConfirmNoActivationPolicyMutation &&
            cleanupFacts.didConfirmNoActivationPolicyMutation,
        sourceFacts.didConfirmNoApplicationActivation &&
            cleanupFacts.didConfirmNoApplicationActivation,
        sourceFacts.didConfirmNoAppKitEventLoop &&
            cleanupFacts.didConfirmNoAppKitEventLoop,
        sourceFacts.didConfirmNoBoundedRunLoopPump &&
            cleanupFacts.didConfirmNoBoundedRunLoopPump,
        sourceFacts.didConfirmNoCleanupTeardownExecution &&
            cleanupFacts.didKeepCleanupExecutionBlocked,
        sourceFacts.didConfirmNoWindowViewLayerCreation &&
            cleanupFacts.didConfirmNoWindowViewLayerCreation,
        sourceFacts.didConfirmNoVisibleOrder &&
            cleanupFacts.didConfirmNoVisibleOrder,
        sourceFacts.didConfirmNoDrawable && cleanupFacts.didConfirmNoDrawable,
        sourceFacts.didConfirmNoCommandQueueBufferEncoder &&
            cleanupFacts.didConfirmNoCommandQueueBufferEncoder,
        sourceFacts.didConfirmNoRenderCommitPresentGpuSubmission &&
            cleanupFacts.didConfirmNoRenderCommitPresentGpuSubmission,
        sourceFacts.didConfirmNoArtifactOrDiagnosticsPublication &&
            cleanupFacts.didConfirmNoArtifactOrDiagnosticsPublication,
        sourceFacts.didConfirmNoPublicApi &&
            cleanupFacts.didConfirmNoPublicApi,
        sourceFacts.didConfirmNoProductionPublicCAbi &&
            cleanupFacts.didConfirmNoProductionPublicCAbi,
        sourceReadinessTruthValueBoundaryReadiness
            .didConfirmNoRuntimeStateWrite &&
            cleanupFacts.didConfirmNoRuntimeStateWrite,
        sourceReadinessTruthValueBoundaryReadiness.didConfirmNoCjpmTomlChange &&
            cleanupFacts.didConfirmNoCjpmTomlChange,
        sourceFacts.didConfirmNoPointerHandleClassIdReturn &&
            cleanupFacts.didConfirmNoPointerHandleClassIdReturn,
        sourceFacts.didConfirmNoRendererStateWrite &&
            cleanupFacts.didConfirmNoRendererStateWrite,
        sourceFacts.didConfirmNoBackendReadyTruth &&
            cleanupFacts.didConfirmNoBackendReadyTruth,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundary(
    productionSingletonOwnershipValueBoundaryFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundary {
    let admitted =
        productionSingletonOwnershipValueBoundaryFacts
            .didPreserveSourceReadinessTruthValueBoundaryReadiness &&
        productionSingletonOwnershipValueBoundaryFacts
            .didPreserveProductionSingletonOwnershipSourceCleanupBoundaryReadiness &&
        productionSingletonOwnershipValueBoundaryFacts
            .didOpenProductionSingletonOwnershipValueBoundary &&
        productionSingletonOwnershipValueBoundaryFacts
            .didRequireSourceReadinessTruthBeforeOwnershipTruth &&
        productionSingletonOwnershipValueBoundaryFacts
            .didRequireExternalPreexistingSingletonSourceBeforeOwnershipTruth &&
        productionSingletonOwnershipValueBoundaryFacts
            .didRequireWitnessTruthBeforeOwnershipTruth &&
        productionSingletonOwnershipValueBoundaryFacts
            .didRequireCleanupOwnershipBeforeImplementation &&
        productionSingletonOwnershipValueBoundaryFacts
            .didRequireMainThreadConfinement &&
        productionSingletonOwnershipValueBoundaryFacts
            .didRequireHeadlessFailClosed &&
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmSourceReadinessTruthValueFalse &&
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse &&
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmProductionSingletonOwnershipTruthFalse &&
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmProductionSingletonImplementationBlocked &&
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmProductionActualAccessorCallSiteBlocked &&
        productionSingletonOwnershipValueBoundaryFacts
            .didRejectThrowawayCreationAsProductionOwnershipTruth &&
        productionSingletonOwnershipValueBoundaryFacts
            .didKeepActualAccessorCallInIsolatedNativeProbeOnly &&
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmNoActivationPolicyMutation &&
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmNoApplicationActivation &&
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmNoAppKitEventLoop &&
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmNoBoundedRunLoopPump &&
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmNoCleanupTeardownExecution &&
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmNoWindowViewLayerCreation &&
        productionSingletonOwnershipValueBoundaryFacts.didConfirmNoVisibleOrder &&
        productionSingletonOwnershipValueBoundaryFacts.didConfirmNoDrawable &&
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmNoCommandQueueBufferEncoder &&
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmNoRenderCommitPresentGpuSubmission &&
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmNoArtifactOrDiagnosticsPublication &&
        productionSingletonOwnershipValueBoundaryFacts.didConfirmNoPublicApi &&
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmNoProductionPublicCAbi &&
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmNoRuntimeStateWrite &&
        productionSingletonOwnershipValueBoundaryFacts.didConfirmNoCjpmTomlChange &&
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmNoPointerHandleClassIdReturn &&
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmNoRendererStateWrite &&
        productionSingletonOwnershipValueBoundaryFacts.didConfirmNoBackendReadyTruth &&
        productionSingletonOwnershipValueBoundaryFacts
            .didKeepProductionSingletonOwnershipValueBoundaryDehydrated &&
        productionSingletonOwnershipValueBoundaryFacts
            .didAvoidApplicationReadyWrapper &&
        productionSingletonOwnershipValueBoundaryFacts
            .didAvoidAccessorReadyWrapper &&
        productionSingletonOwnershipValueBoundaryFacts
            .didAvoidSingletonOwnerReadyWrapper &&
        productionSingletonOwnershipValueBoundaryFacts.didAvoidBackendReadyWrapper

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundary(
        productionSingletonOwnershipValueBoundaryFacts,
        admitted,
        !admitted,
        !admitted,
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmProductionSingletonOwnershipTruthFalse,
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmProductionSingletonImplementationBlocked,
        productionSingletonOwnershipValueBoundaryFacts
            .didConfirmProductionActualAccessorCallSiteBlocked,
        productionSingletonOwnershipValueBoundaryFacts
            .didKeepProductionSingletonOwnershipValueBoundaryDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryReadiness(
    sourceReadinessTruthValueBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessTruthValueBoundaryReadiness,
    sourceCleanupBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryReadiness,
    productionSingletonOwnershipValueBoundary:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundary
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryReadiness {
    let facts =
        productionSingletonOwnershipValueBoundary
            .productionSingletonOwnershipValueBoundaryFacts
    let admitted =
        productionSingletonOwnershipValueBoundary
            .didAdmitProductionSingletonOwnershipValueBoundary

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryReadiness(
        sourceReadinessTruthValueBoundaryReadiness,
        sourceCleanupBoundaryReadiness,
        productionSingletonOwnershipValueBoundary,
        admitted,
        !admitted,
        !admitted,
        facts.didOpenProductionSingletonOwnershipValueBoundary,
        facts.didRequireSourceReadinessTruthBeforeOwnershipTruth,
        facts.didConfirmSourceReadinessTruthValueFalse,
        productionSingletonOwnershipValueBoundary
            .didConfirmProductionSingletonOwnershipTruthFalse,
        productionSingletonOwnershipValueBoundary
            .didConfirmProductionSingletonImplementationBlocked,
        productionSingletonOwnershipValueBoundary
            .didConfirmProductionActualAccessorCallSiteBlocked,
        facts.didConfirmNoRuntimeStateWrite,
        facts.didConfirmNoCjpmTomlChange,
        facts.didKeepProductionSingletonOwnershipValueBoundaryDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryReadiness {
    let sourceReadinessTruthValueBoundaryReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessTruthValueBoundaryDraft()
    let sourceCleanupBoundaryReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryDraft()
    let productionSingletonOwnershipValueBoundaryFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryFacts(
            sourceReadinessTruthValueBoundaryReadiness,
            sourceCleanupBoundaryReadiness
        )
    let productionSingletonOwnershipValueBoundary =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundary(
            productionSingletonOwnershipValueBoundaryFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryReadiness(
        sourceReadinessTruthValueBoundaryReadiness,
        sourceCleanupBoundaryReadiness,
        productionSingletonOwnershipValueBoundary
    )
}
