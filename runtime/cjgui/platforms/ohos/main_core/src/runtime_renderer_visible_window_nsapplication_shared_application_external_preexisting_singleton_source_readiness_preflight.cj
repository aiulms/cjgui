// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application external preexisting singleton source readiness preflight
// owner。
// Owner: runtime renderer internal external preexisting singleton source
// readiness preflight owner。
// Truth: 只消费 production singleton ownership source-cleanup boundary
// readiness，并固定 external source 必须由外部 app shell / user-controlled
// owner 提供；Renderer 不能把 throwaway singleton、probe evidence 或自身创建
// 行为升级成 production singleton source。
// Stop-line: 不实现 production singleton owner，不调用 application singleton
// accessor，不创建或激活 NSApplication，不修改 activation policy，不运行
// AppKit event loop / bounded pump，不执行 cleanup / teardown，不创建 window /
// view / layer，不 visible order，不取 drawable，不创建 command queue / command
// buffer / encoder，不 render / commit / present / GPU submission，不写 artifact
// / diagnostics publication，不返回 Class / id / pointer / handle，不写
// runtime_state.cj，不改 cjpm.toml，不扩 public API，不新增 production C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、
// accessor-ready、visible-ready、drawable-ready、render-ready、backend-ready、
// renderer state write、receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightFacts {
    let didPreserveProductionSingletonOwnershipSourceCleanupBoundaryReadiness:
        Bool
    let didConfirmExternalPreexistingSingletonSourceReadinessPreflightDecision:
        Bool
    let didRequireExternalOwnerProvidedPreexistingSingleton: Bool
    let didRequireExternalSourceWitnessBeforeRuntimeOwner: Bool
    let didRejectThrowawaySingletonAsExternalSource: Bool
    let didRequireNoRendererCreatedSingleton: Bool
    let didRequireSourceLifetimeOutlivesRendererObservation: Bool
    let didRequireCleanupOwnedByExternalSource: Bool
    let didKeepRendererCleanupExecutionBlocked: Bool
    let didRequireMainThreadConfinement: Bool
    let didRequireHeadlessFailClosed: Bool
    let didRequireFutureExplicitRuntimeOwnerApproval: Bool
    let didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse:
        Bool
    let didConfirmProductionSingletonOwnershipTruthFalse: Bool
    let didConfirmProductionSingletonImplementationBlocked: Bool
    let didConfirmProductionActualAccessorCallSiteBlocked: Bool
    let didConfirmNoAccessorCall: Bool
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
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepExternalPreexistingSingletonSourceReadinessPreflightValueOnly:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didPreserveProductionSingletonOwnershipSourceCleanupBoundaryReadiness:
            Bool,
        didConfirmExternalPreexistingSingletonSourceReadinessPreflightDecision:
            Bool,
        didRequireExternalOwnerProvidedPreexistingSingleton: Bool,
        didRequireExternalSourceWitnessBeforeRuntimeOwner: Bool,
        didRejectThrowawaySingletonAsExternalSource: Bool,
        didRequireNoRendererCreatedSingleton: Bool,
        didRequireSourceLifetimeOutlivesRendererObservation: Bool,
        didRequireCleanupOwnedByExternalSource: Bool,
        didKeepRendererCleanupExecutionBlocked: Bool,
        didRequireMainThreadConfinement: Bool,
        didRequireHeadlessFailClosed: Bool,
        didRequireFutureExplicitRuntimeOwnerApproval: Bool,
        didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse:
            Bool,
        didConfirmProductionSingletonOwnershipTruthFalse: Bool,
        didConfirmProductionSingletonImplementationBlocked: Bool,
        didConfirmProductionActualAccessorCallSiteBlocked: Bool,
        didConfirmNoAccessorCall: Bool,
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
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepExternalPreexistingSingletonSourceReadinessPreflightValueOnly:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didPreserveProductionSingletonOwnershipSourceCleanupBoundaryReadiness =
            didPreserveProductionSingletonOwnershipSourceCleanupBoundaryReadiness
        this.didConfirmExternalPreexistingSingletonSourceReadinessPreflightDecision =
            didConfirmExternalPreexistingSingletonSourceReadinessPreflightDecision
        this.didRequireExternalOwnerProvidedPreexistingSingleton =
            didRequireExternalOwnerProvidedPreexistingSingleton
        this.didRequireExternalSourceWitnessBeforeRuntimeOwner =
            didRequireExternalSourceWitnessBeforeRuntimeOwner
        this.didRejectThrowawaySingletonAsExternalSource =
            didRejectThrowawaySingletonAsExternalSource
        this.didRequireNoRendererCreatedSingleton =
            didRequireNoRendererCreatedSingleton
        this.didRequireSourceLifetimeOutlivesRendererObservation =
            didRequireSourceLifetimeOutlivesRendererObservation
        this.didRequireCleanupOwnedByExternalSource =
            didRequireCleanupOwnedByExternalSource
        this.didKeepRendererCleanupExecutionBlocked =
            didKeepRendererCleanupExecutionBlocked
        this.didRequireMainThreadConfinement =
            didRequireMainThreadConfinement
        this.didRequireHeadlessFailClosed = didRequireHeadlessFailClosed
        this.didRequireFutureExplicitRuntimeOwnerApproval =
            didRequireFutureExplicitRuntimeOwnerApproval
        this.didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse =
            didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse
        this.didConfirmProductionSingletonOwnershipTruthFalse =
            didConfirmProductionSingletonOwnershipTruthFalse
        this.didConfirmProductionSingletonImplementationBlocked =
            didConfirmProductionSingletonImplementationBlocked
        this.didConfirmProductionActualAccessorCallSiteBlocked =
            didConfirmProductionActualAccessorCallSiteBlocked
        this.didConfirmNoAccessorCall = didConfirmNoAccessorCall
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
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite =
            didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepExternalPreexistingSingletonSourceReadinessPreflightValueOnly =
            didKeepExternalPreexistingSingletonSourceReadinessPreflightValueOnly
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflight {
    let externalPreexistingSingletonSourceReadinessPreflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightFacts
    let didAdmitExternalPreexistingSingletonSourceReadinessPreflight: Bool
    let shouldDeferExternalPreexistingSingletonSourceReadinessPreflight: Bool
    let shouldReportExternalPreexistingSingletonSourceReadinessBlocked: Bool
    let didRequireExternalOwnerProvidedPreexistingSingleton: Bool
    let didRequireExternalSourceWitnessBeforeRuntimeOwner: Bool
    let didRejectThrowawaySingletonAsExternalSource: Bool
    let didRequireCleanupOwnedByExternalSource: Bool
    let didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse:
        Bool
    let didConfirmProductionSingletonOwnershipTruthFalse: Bool
    let didConfirmProductionSingletonImplementationBlocked: Bool
    let didConfirmProductionActualAccessorCallSiteBlocked: Bool
    let didKeepExternalPreexistingSingletonSourceReadinessPreflightValueOnly:
        Bool

    init(
        externalPreexistingSingletonSourceReadinessPreflightFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightFacts,
        didAdmitExternalPreexistingSingletonSourceReadinessPreflight: Bool,
        shouldDeferExternalPreexistingSingletonSourceReadinessPreflight:
            Bool,
        shouldReportExternalPreexistingSingletonSourceReadinessBlocked:
            Bool,
        didRequireExternalOwnerProvidedPreexistingSingleton: Bool,
        didRequireExternalSourceWitnessBeforeRuntimeOwner: Bool,
        didRejectThrowawaySingletonAsExternalSource: Bool,
        didRequireCleanupOwnedByExternalSource: Bool,
        didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse:
            Bool,
        didConfirmProductionSingletonOwnershipTruthFalse: Bool,
        didConfirmProductionSingletonImplementationBlocked: Bool,
        didConfirmProductionActualAccessorCallSiteBlocked: Bool,
        didKeepExternalPreexistingSingletonSourceReadinessPreflightValueOnly:
            Bool
    ) {
        this.externalPreexistingSingletonSourceReadinessPreflightFacts =
            externalPreexistingSingletonSourceReadinessPreflightFacts
        this.didAdmitExternalPreexistingSingletonSourceReadinessPreflight =
            didAdmitExternalPreexistingSingletonSourceReadinessPreflight
        this.shouldDeferExternalPreexistingSingletonSourceReadinessPreflight =
            shouldDeferExternalPreexistingSingletonSourceReadinessPreflight
        this.shouldReportExternalPreexistingSingletonSourceReadinessBlocked =
            shouldReportExternalPreexistingSingletonSourceReadinessBlocked
        this.didRequireExternalOwnerProvidedPreexistingSingleton =
            didRequireExternalOwnerProvidedPreexistingSingleton
        this.didRequireExternalSourceWitnessBeforeRuntimeOwner =
            didRequireExternalSourceWitnessBeforeRuntimeOwner
        this.didRejectThrowawaySingletonAsExternalSource =
            didRejectThrowawaySingletonAsExternalSource
        this.didRequireCleanupOwnedByExternalSource =
            didRequireCleanupOwnedByExternalSource
        this.didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse =
            didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse
        this.didConfirmProductionSingletonOwnershipTruthFalse =
            didConfirmProductionSingletonOwnershipTruthFalse
        this.didConfirmProductionSingletonImplementationBlocked =
            didConfirmProductionSingletonImplementationBlocked
        this.didConfirmProductionActualAccessorCallSiteBlocked =
            didConfirmProductionActualAccessorCallSiteBlocked
        this.didKeepExternalPreexistingSingletonSourceReadinessPreflightValueOnly =
            didKeepExternalPreexistingSingletonSourceReadinessPreflightValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightReadiness {
    let productionSingletonOwnershipSourceCleanupBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryReadiness
    let externalPreexistingSingletonSourceReadinessPreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflight
    let didPrepareExternalPreexistingSingletonSourceReadinessPreflight:
        Bool
    let shouldDeferExternalPreexistingSingletonSourceReadinessPreflight:
        Bool
    let shouldReportExternalPreexistingSingletonSourceReadinessBlocked:
        Bool
    let didPreserveProductionSingletonOwnershipSourceCleanupBoundaryReadiness:
        Bool
    let didRequireExternalOwnerProvidedPreexistingSingleton: Bool
    let didRequireExternalSourceWitnessBeforeRuntimeOwner: Bool
    let didRejectThrowawaySingletonAsExternalSource: Bool
    let didRequireCleanupOwnedByExternalSource: Bool
    let didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse:
        Bool
    let didConfirmProductionSingletonOwnershipTruthFalse: Bool
    let didConfirmProductionSingletonImplementationBlocked: Bool
    let didConfirmProductionActualAccessorCallSiteBlocked: Bool
    let didKeepExternalPreexistingSingletonSourceReadinessPreflightDehydrated:
        Bool

    init(
        productionSingletonOwnershipSourceCleanupBoundaryReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryReadiness,
        externalPreexistingSingletonSourceReadinessPreflight:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflight,
        didPrepareExternalPreexistingSingletonSourceReadinessPreflight:
            Bool,
        shouldDeferExternalPreexistingSingletonSourceReadinessPreflight:
            Bool,
        shouldReportExternalPreexistingSingletonSourceReadinessBlocked:
            Bool,
        didPreserveProductionSingletonOwnershipSourceCleanupBoundaryReadiness:
            Bool,
        didRequireExternalOwnerProvidedPreexistingSingleton: Bool,
        didRequireExternalSourceWitnessBeforeRuntimeOwner: Bool,
        didRejectThrowawaySingletonAsExternalSource: Bool,
        didRequireCleanupOwnedByExternalSource: Bool,
        didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse:
            Bool,
        didConfirmProductionSingletonOwnershipTruthFalse: Bool,
        didConfirmProductionSingletonImplementationBlocked: Bool,
        didConfirmProductionActualAccessorCallSiteBlocked: Bool,
        didKeepExternalPreexistingSingletonSourceReadinessPreflightDehydrated:
            Bool
    ) {
        this.productionSingletonOwnershipSourceCleanupBoundaryReadiness =
            productionSingletonOwnershipSourceCleanupBoundaryReadiness
        this.externalPreexistingSingletonSourceReadinessPreflight =
            externalPreexistingSingletonSourceReadinessPreflight
        this.didPrepareExternalPreexistingSingletonSourceReadinessPreflight =
            didPrepareExternalPreexistingSingletonSourceReadinessPreflight
        this.shouldDeferExternalPreexistingSingletonSourceReadinessPreflight =
            shouldDeferExternalPreexistingSingletonSourceReadinessPreflight
        this.shouldReportExternalPreexistingSingletonSourceReadinessBlocked =
            shouldReportExternalPreexistingSingletonSourceReadinessBlocked
        this.didPreserveProductionSingletonOwnershipSourceCleanupBoundaryReadiness =
            didPreserveProductionSingletonOwnershipSourceCleanupBoundaryReadiness
        this.didRequireExternalOwnerProvidedPreexistingSingleton =
            didRequireExternalOwnerProvidedPreexistingSingleton
        this.didRequireExternalSourceWitnessBeforeRuntimeOwner =
            didRequireExternalSourceWitnessBeforeRuntimeOwner
        this.didRejectThrowawaySingletonAsExternalSource =
            didRejectThrowawaySingletonAsExternalSource
        this.didRequireCleanupOwnedByExternalSource =
            didRequireCleanupOwnedByExternalSource
        this.didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse =
            didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse
        this.didConfirmProductionSingletonOwnershipTruthFalse =
            didConfirmProductionSingletonOwnershipTruthFalse
        this.didConfirmProductionSingletonImplementationBlocked =
            didConfirmProductionSingletonImplementationBlocked
        this.didConfirmProductionActualAccessorCallSiteBlocked =
            didConfirmProductionActualAccessorCallSiteBlocked
        this.didKeepExternalPreexistingSingletonSourceReadinessPreflightDehydrated =
            didKeepExternalPreexistingSingletonSourceReadinessPreflightDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightFacts(
    sourceCleanupBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightFacts {
    let upstreamReady =
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

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightFacts(
        upstreamReady,
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

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflight(
    externalPreexistingSingletonSourceReadinessPreflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflight {
    let admitted =
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didPreserveProductionSingletonOwnershipSourceCleanupBoundaryReadiness &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmExternalPreexistingSingletonSourceReadinessPreflightDecision &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didRequireExternalOwnerProvidedPreexistingSingleton &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didRequireExternalSourceWitnessBeforeRuntimeOwner &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didRejectThrowawaySingletonAsExternalSource &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didRequireNoRendererCreatedSingleton &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didRequireSourceLifetimeOutlivesRendererObservation &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didRequireCleanupOwnedByExternalSource &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didKeepRendererCleanupExecutionBlocked &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didRequireMainThreadConfinement &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didRequireHeadlessFailClosed &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didRequireFutureExplicitRuntimeOwnerApproval &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmProductionSingletonOwnershipTruthFalse &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmProductionSingletonImplementationBlocked &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmProductionActualAccessorCallSiteBlocked &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmNoAccessorCall &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmNoActivationPolicyMutation &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmNoApplicationActivation &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmNoAppKitEventLoop &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmNoBoundedRunLoopPump &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmNoWindowViewLayerCreation &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmNoVisibleOrder &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmNoDrawable &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmNoCommandQueueBufferEncoder &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmNoRenderCommitPresentGpuSubmission &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmNoArtifactOrDiagnosticsPublication &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmNoPublicApi &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmNoProductionPublicCAbi &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmNoRuntimeStateWrite &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmNoCjpmTomlChange &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmNoPointerHandleClassIdReturn &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmNoRendererStateWrite &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmNoBackendReadyTruth &&
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didKeepExternalPreexistingSingletonSourceReadinessPreflightValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflight(
        externalPreexistingSingletonSourceReadinessPreflightFacts,
        admitted,
        !admitted,
        !admitted,
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didRequireExternalOwnerProvidedPreexistingSingleton,
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didRequireExternalSourceWitnessBeforeRuntimeOwner,
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didRejectThrowawaySingletonAsExternalSource,
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didRequireCleanupOwnedByExternalSource,
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse,
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmProductionSingletonOwnershipTruthFalse,
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmProductionSingletonImplementationBlocked,
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didConfirmProductionActualAccessorCallSiteBlocked,
        externalPreexistingSingletonSourceReadinessPreflightFacts
            .didKeepExternalPreexistingSingletonSourceReadinessPreflightValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightReadiness(
    sourceCleanupBoundaryReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryReadiness,
    externalPreexistingSingletonSourceReadinessPreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflight
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightReadiness {
    let admitted =
        externalPreexistingSingletonSourceReadinessPreflight
            .didAdmitExternalPreexistingSingletonSourceReadinessPreflight
    let facts =
        externalPreexistingSingletonSourceReadinessPreflight
            .externalPreexistingSingletonSourceReadinessPreflightFacts

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightReadiness(
        sourceCleanupBoundaryReadiness,
        externalPreexistingSingletonSourceReadinessPreflight,
        admitted,
        !admitted,
        !admitted,
        facts
            .didPreserveProductionSingletonOwnershipSourceCleanupBoundaryReadiness,
        externalPreexistingSingletonSourceReadinessPreflight
            .didRequireExternalOwnerProvidedPreexistingSingleton,
        externalPreexistingSingletonSourceReadinessPreflight
            .didRequireExternalSourceWitnessBeforeRuntimeOwner,
        externalPreexistingSingletonSourceReadinessPreflight
            .didRejectThrowawaySingletonAsExternalSource,
        externalPreexistingSingletonSourceReadinessPreflight
            .didRequireCleanupOwnedByExternalSource,
        externalPreexistingSingletonSourceReadinessPreflight
            .didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse,
        externalPreexistingSingletonSourceReadinessPreflight
            .didConfirmProductionSingletonOwnershipTruthFalse,
        externalPreexistingSingletonSourceReadinessPreflight
            .didConfirmProductionSingletonImplementationBlocked,
        externalPreexistingSingletonSourceReadinessPreflight
            .didConfirmProductionActualAccessorCallSiteBlocked,
        externalPreexistingSingletonSourceReadinessPreflight
            .didKeepExternalPreexistingSingletonSourceReadinessPreflightValueOnly
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightReadiness {
    let sourceCleanupBoundaryReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryDraft()
    let externalPreexistingSingletonSourceReadinessPreflightFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightFacts(
            sourceCleanupBoundaryReadiness
        )
    let externalPreexistingSingletonSourceReadinessPreflight =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflight(
            externalPreexistingSingletonSourceReadinessPreflightFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightReadiness(
        sourceCleanupBoundaryReadiness,
        externalPreexistingSingletonSourceReadinessPreflight
    )
}
