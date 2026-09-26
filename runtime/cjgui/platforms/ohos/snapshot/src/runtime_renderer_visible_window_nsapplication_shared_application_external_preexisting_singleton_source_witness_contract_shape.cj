// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application external preexisting singleton source witness contract
// shape owner。
// Owner: runtime renderer internal external preexisting singleton source
// witness contract shape owner。
// Truth: 只消费 external preexisting singleton source readiness preflight，
// 固定未来 witness contract 必须由外部 app shell / user-controlled owner
// 提供，并声明 preexisting singleton、main-thread confinement、source
// lifetime、cleanup ownership、headless fail-closed 与 non-creation invariant。
// Stop-line: 不实现 production singleton owner，不调用 application singleton
// accessor，不创建或激活 NSApplication，不修改 activation policy，不运行
// AppKit event loop / bounded pump，不执行 cleanup / teardown，不创建 window /
// view / layer，不 visible order，不取 drawable，不创建 command queue / command
// buffer / encoder，不 render / commit / present / GPU submission，不写 artifact
// / diagnostics publication，不返回 Class / id / pointer / handle，不写
// runtime_state.cj，不改 cjpm.toml，不扩 public API，不新增 production C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、
// accessor-ready、singleton-owner-ready、visible-ready、drawable-ready、
// render-ready、backend-ready、renderer state write、receipt、record 或
// publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeFacts {
    let didPreserveExternalPreexistingSingletonSourceReadinessPreflight:
        Bool
    let didConfirmExternalPreexistingSingletonSourceWitnessContractShapeDecision:
        Bool
    let didRequireWitnessProvidedByExternalOwner: Bool
    let didRequirePreexistingSingletonBeforeRendererObservation: Bool
    let didRequireWitnessCapturedBeforeRuntimeOwner: Bool
    let didRequireMainThreadWitnessDeclaration: Bool
    let didRequireNoRendererCreationInvariant: Bool
    let didRequireNoRendererAccessorCallInvariant: Bool
    let didRequireNoPointerHandleClassIdReturn: Bool
    let didRequireSourceLifetimeOutlivesRendererObservation: Bool
    let didRequireCleanupOwnershipRetainedByExternalSource: Bool
    let didKeepRendererCleanupExecutionBlocked: Bool
    let didRequireHeadlessFailClosedWitness: Bool
    let didRequireNonUserVisibleObservation: Bool
    let didRejectThrowawaySingletonAsWitness: Bool
    let didRejectSmokeHarnessAsProductionWitness: Bool
    let didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse:
        Bool
    let didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse:
        Bool
    let didConfirmProductionSingletonOwnershipTruthFalse: Bool
    let didConfirmProductionSingletonImplementationBlocked: Bool
    let didConfirmProductionActualAccessorCallSiteBlocked: Bool
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
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepExternalPreexistingSingletonSourceWitnessContractShapeValueOnly:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didPreserveExternalPreexistingSingletonSourceReadinessPreflight:
            Bool,
        didConfirmExternalPreexistingSingletonSourceWitnessContractShapeDecision:
            Bool,
        didRequireWitnessProvidedByExternalOwner: Bool,
        didRequirePreexistingSingletonBeforeRendererObservation: Bool,
        didRequireWitnessCapturedBeforeRuntimeOwner: Bool,
        didRequireMainThreadWitnessDeclaration: Bool,
        didRequireNoRendererCreationInvariant: Bool,
        didRequireNoRendererAccessorCallInvariant: Bool,
        didRequireNoPointerHandleClassIdReturn: Bool,
        didRequireSourceLifetimeOutlivesRendererObservation: Bool,
        didRequireCleanupOwnershipRetainedByExternalSource: Bool,
        didKeepRendererCleanupExecutionBlocked: Bool,
        didRequireHeadlessFailClosedWitness: Bool,
        didRequireNonUserVisibleObservation: Bool,
        didRejectThrowawaySingletonAsWitness: Bool,
        didRejectSmokeHarnessAsProductionWitness: Bool,
        didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse:
            Bool,
        didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse:
            Bool,
        didConfirmProductionSingletonOwnershipTruthFalse: Bool,
        didConfirmProductionSingletonImplementationBlocked: Bool,
        didConfirmProductionActualAccessorCallSiteBlocked: Bool,
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
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepExternalPreexistingSingletonSourceWitnessContractShapeValueOnly:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didPreserveExternalPreexistingSingletonSourceReadinessPreflight =
            didPreserveExternalPreexistingSingletonSourceReadinessPreflight
        this.didConfirmExternalPreexistingSingletonSourceWitnessContractShapeDecision =
            didConfirmExternalPreexistingSingletonSourceWitnessContractShapeDecision
        this.didRequireWitnessProvidedByExternalOwner =
            didRequireWitnessProvidedByExternalOwner
        this.didRequirePreexistingSingletonBeforeRendererObservation =
            didRequirePreexistingSingletonBeforeRendererObservation
        this.didRequireWitnessCapturedBeforeRuntimeOwner =
            didRequireWitnessCapturedBeforeRuntimeOwner
        this.didRequireMainThreadWitnessDeclaration =
            didRequireMainThreadWitnessDeclaration
        this.didRequireNoRendererCreationInvariant =
            didRequireNoRendererCreationInvariant
        this.didRequireNoRendererAccessorCallInvariant =
            didRequireNoRendererAccessorCallInvariant
        this.didRequireNoPointerHandleClassIdReturn =
            didRequireNoPointerHandleClassIdReturn
        this.didRequireSourceLifetimeOutlivesRendererObservation =
            didRequireSourceLifetimeOutlivesRendererObservation
        this.didRequireCleanupOwnershipRetainedByExternalSource =
            didRequireCleanupOwnershipRetainedByExternalSource
        this.didKeepRendererCleanupExecutionBlocked =
            didKeepRendererCleanupExecutionBlocked
        this.didRequireHeadlessFailClosedWitness =
            didRequireHeadlessFailClosedWitness
        this.didRequireNonUserVisibleObservation =
            didRequireNonUserVisibleObservation
        this.didRejectThrowawaySingletonAsWitness =
            didRejectThrowawaySingletonAsWitness
        this.didRejectSmokeHarnessAsProductionWitness =
            didRejectSmokeHarnessAsProductionWitness
        this.didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse =
            didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse
        this.didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse =
            didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse
        this.didConfirmProductionSingletonOwnershipTruthFalse =
            didConfirmProductionSingletonOwnershipTruthFalse
        this.didConfirmProductionSingletonImplementationBlocked =
            didConfirmProductionSingletonImplementationBlocked
        this.didConfirmProductionActualAccessorCallSiteBlocked =
            didConfirmProductionActualAccessorCallSiteBlocked
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
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepExternalPreexistingSingletonSourceWitnessContractShapeValueOnly =
            didKeepExternalPreexistingSingletonSourceWitnessContractShapeValueOnly
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShape {
    let sourceWitnessContractShapeFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeFacts
    let didAdmitExternalPreexistingSingletonSourceWitnessContractShape:
        Bool
    let shouldDeferExternalPreexistingSingletonSourceWitnessContractShape:
        Bool
    let shouldReportExternalPreexistingSingletonSourceWitnessBlocked:
        Bool
    let didRequireWitnessProvidedByExternalOwner: Bool
    let didRequirePreexistingSingletonBeforeRendererObservation: Bool
    let didRequireWitnessCapturedBeforeRuntimeOwner: Bool
    let didRequireMainThreadWitnessDeclaration: Bool
    let didRequireNoRendererCreationInvariant: Bool
    let didRequireNoRendererAccessorCallInvariant: Bool
    let didRequireCleanupOwnershipRetainedByExternalSource: Bool
    let didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse:
        Bool
    let didConfirmProductionSingletonOwnershipTruthFalse: Bool
    let didConfirmProductionSingletonImplementationBlocked: Bool
    let didConfirmProductionActualAccessorCallSiteBlocked: Bool
    let didKeepExternalPreexistingSingletonSourceWitnessContractShapeValueOnly:
        Bool

    init(
        sourceWitnessContractShapeFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeFacts,
        didAdmitExternalPreexistingSingletonSourceWitnessContractShape:
            Bool,
        shouldDeferExternalPreexistingSingletonSourceWitnessContractShape:
            Bool,
        shouldReportExternalPreexistingSingletonSourceWitnessBlocked:
            Bool,
        didRequireWitnessProvidedByExternalOwner: Bool,
        didRequirePreexistingSingletonBeforeRendererObservation: Bool,
        didRequireWitnessCapturedBeforeRuntimeOwner: Bool,
        didRequireMainThreadWitnessDeclaration: Bool,
        didRequireNoRendererCreationInvariant: Bool,
        didRequireNoRendererAccessorCallInvariant: Bool,
        didRequireCleanupOwnershipRetainedByExternalSource: Bool,
        didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse:
            Bool,
        didConfirmProductionSingletonOwnershipTruthFalse: Bool,
        didConfirmProductionSingletonImplementationBlocked: Bool,
        didConfirmProductionActualAccessorCallSiteBlocked: Bool,
        didKeepExternalPreexistingSingletonSourceWitnessContractShapeValueOnly:
            Bool
    ) {
        this.sourceWitnessContractShapeFacts = sourceWitnessContractShapeFacts
        this.didAdmitExternalPreexistingSingletonSourceWitnessContractShape =
            didAdmitExternalPreexistingSingletonSourceWitnessContractShape
        this.shouldDeferExternalPreexistingSingletonSourceWitnessContractShape =
            shouldDeferExternalPreexistingSingletonSourceWitnessContractShape
        this.shouldReportExternalPreexistingSingletonSourceWitnessBlocked =
            shouldReportExternalPreexistingSingletonSourceWitnessBlocked
        this.didRequireWitnessProvidedByExternalOwner =
            didRequireWitnessProvidedByExternalOwner
        this.didRequirePreexistingSingletonBeforeRendererObservation =
            didRequirePreexistingSingletonBeforeRendererObservation
        this.didRequireWitnessCapturedBeforeRuntimeOwner =
            didRequireWitnessCapturedBeforeRuntimeOwner
        this.didRequireMainThreadWitnessDeclaration =
            didRequireMainThreadWitnessDeclaration
        this.didRequireNoRendererCreationInvariant =
            didRequireNoRendererCreationInvariant
        this.didRequireNoRendererAccessorCallInvariant =
            didRequireNoRendererAccessorCallInvariant
        this.didRequireCleanupOwnershipRetainedByExternalSource =
            didRequireCleanupOwnershipRetainedByExternalSource
        this.didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse =
            didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse
        this.didConfirmProductionSingletonOwnershipTruthFalse =
            didConfirmProductionSingletonOwnershipTruthFalse
        this.didConfirmProductionSingletonImplementationBlocked =
            didConfirmProductionSingletonImplementationBlocked
        this.didConfirmProductionActualAccessorCallSiteBlocked =
            didConfirmProductionActualAccessorCallSiteBlocked
        this.didKeepExternalPreexistingSingletonSourceWitnessContractShapeValueOnly =
            didKeepExternalPreexistingSingletonSourceWitnessContractShapeValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeReadiness {
    let externalPreexistingSingletonSourceReadinessPreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightReadiness
    let sourceWitnessContractShape:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShape
    let didPrepareExternalPreexistingSingletonSourceWitnessContractShape:
        Bool
    let shouldDeferExternalPreexistingSingletonSourceWitnessContractShape:
        Bool
    let shouldReportExternalPreexistingSingletonSourceWitnessBlocked:
        Bool
    let didPreserveExternalPreexistingSingletonSourceReadinessPreflight:
        Bool
    let didRequireWitnessProvidedByExternalOwner: Bool
    let didRequirePreexistingSingletonBeforeRendererObservation: Bool
    let didRequireWitnessCapturedBeforeRuntimeOwner: Bool
    let didRequireMainThreadWitnessDeclaration: Bool
    let didRequireNoRendererCreationInvariant: Bool
    let didRequireNoRendererAccessorCallInvariant: Bool
    let didRequireCleanupOwnershipRetainedByExternalSource: Bool
    let didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse:
        Bool
    let didConfirmProductionSingletonOwnershipTruthFalse: Bool
    let didConfirmProductionSingletonImplementationBlocked: Bool
    let didConfirmProductionActualAccessorCallSiteBlocked: Bool
    let didKeepExternalPreexistingSingletonSourceWitnessContractShapeDehydrated:
        Bool

    init(
        externalPreexistingSingletonSourceReadinessPreflightReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightReadiness,
        sourceWitnessContractShape:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShape,
        didPrepareExternalPreexistingSingletonSourceWitnessContractShape:
            Bool,
        shouldDeferExternalPreexistingSingletonSourceWitnessContractShape:
            Bool,
        shouldReportExternalPreexistingSingletonSourceWitnessBlocked:
            Bool,
        didPreserveExternalPreexistingSingletonSourceReadinessPreflight:
            Bool,
        didRequireWitnessProvidedByExternalOwner: Bool,
        didRequirePreexistingSingletonBeforeRendererObservation: Bool,
        didRequireWitnessCapturedBeforeRuntimeOwner: Bool,
        didRequireMainThreadWitnessDeclaration: Bool,
        didRequireNoRendererCreationInvariant: Bool,
        didRequireNoRendererAccessorCallInvariant: Bool,
        didRequireCleanupOwnershipRetainedByExternalSource: Bool,
        didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse:
            Bool,
        didConfirmProductionSingletonOwnershipTruthFalse: Bool,
        didConfirmProductionSingletonImplementationBlocked: Bool,
        didConfirmProductionActualAccessorCallSiteBlocked: Bool,
        didKeepExternalPreexistingSingletonSourceWitnessContractShapeDehydrated:
            Bool
    ) {
        this.externalPreexistingSingletonSourceReadinessPreflightReadiness =
            externalPreexistingSingletonSourceReadinessPreflightReadiness
        this.sourceWitnessContractShape = sourceWitnessContractShape
        this.didPrepareExternalPreexistingSingletonSourceWitnessContractShape =
            didPrepareExternalPreexistingSingletonSourceWitnessContractShape
        this.shouldDeferExternalPreexistingSingletonSourceWitnessContractShape =
            shouldDeferExternalPreexistingSingletonSourceWitnessContractShape
        this.shouldReportExternalPreexistingSingletonSourceWitnessBlocked =
            shouldReportExternalPreexistingSingletonSourceWitnessBlocked
        this.didPreserveExternalPreexistingSingletonSourceReadinessPreflight =
            didPreserveExternalPreexistingSingletonSourceReadinessPreflight
        this.didRequireWitnessProvidedByExternalOwner =
            didRequireWitnessProvidedByExternalOwner
        this.didRequirePreexistingSingletonBeforeRendererObservation =
            didRequirePreexistingSingletonBeforeRendererObservation
        this.didRequireWitnessCapturedBeforeRuntimeOwner =
            didRequireWitnessCapturedBeforeRuntimeOwner
        this.didRequireMainThreadWitnessDeclaration =
            didRequireMainThreadWitnessDeclaration
        this.didRequireNoRendererCreationInvariant =
            didRequireNoRendererCreationInvariant
        this.didRequireNoRendererAccessorCallInvariant =
            didRequireNoRendererAccessorCallInvariant
        this.didRequireCleanupOwnershipRetainedByExternalSource =
            didRequireCleanupOwnershipRetainedByExternalSource
        this.didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse =
            didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse
        this.didConfirmProductionSingletonOwnershipTruthFalse =
            didConfirmProductionSingletonOwnershipTruthFalse
        this.didConfirmProductionSingletonImplementationBlocked =
            didConfirmProductionSingletonImplementationBlocked
        this.didConfirmProductionActualAccessorCallSiteBlocked =
            didConfirmProductionActualAccessorCallSiteBlocked
        this.didKeepExternalPreexistingSingletonSourceWitnessContractShapeDehydrated =
            didKeepExternalPreexistingSingletonSourceWitnessContractShapeDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeFacts(
    sourceReadinessPreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeFacts {
    let upstreamReady =
        sourceReadinessPreflight
            .didPrepareExternalPreexistingSingletonSourceReadinessPreflight &&
        sourceReadinessPreflight
            .didRequireExternalOwnerProvidedPreexistingSingleton &&
        sourceReadinessPreflight
            .didRequireExternalSourceWitnessBeforeRuntimeOwner &&
        sourceReadinessPreflight
            .didRejectThrowawaySingletonAsExternalSource &&
        sourceReadinessPreflight
            .didRequireCleanupOwnedByExternalSource &&
        sourceReadinessPreflight
            .didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse &&
        sourceReadinessPreflight
            .didConfirmProductionSingletonOwnershipTruthFalse &&
        sourceReadinessPreflight
            .didConfirmProductionSingletonImplementationBlocked &&
        sourceReadinessPreflight
            .didConfirmProductionActualAccessorCallSiteBlocked &&
        sourceReadinessPreflight
            .didKeepExternalPreexistingSingletonSourceReadinessPreflightDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeFacts(
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
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShape(
    sourceWitnessContractShapeFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShape {
    let admitted =
        sourceWitnessContractShapeFacts
            .didPreserveExternalPreexistingSingletonSourceReadinessPreflight &&
        sourceWitnessContractShapeFacts
            .didConfirmExternalPreexistingSingletonSourceWitnessContractShapeDecision &&
        sourceWitnessContractShapeFacts
            .didRequireWitnessProvidedByExternalOwner &&
        sourceWitnessContractShapeFacts
            .didRequirePreexistingSingletonBeforeRendererObservation &&
        sourceWitnessContractShapeFacts
            .didRequireWitnessCapturedBeforeRuntimeOwner &&
        sourceWitnessContractShapeFacts
            .didRequireMainThreadWitnessDeclaration &&
        sourceWitnessContractShapeFacts
            .didRequireNoRendererCreationInvariant &&
        sourceWitnessContractShapeFacts
            .didRequireNoRendererAccessorCallInvariant &&
        sourceWitnessContractShapeFacts
            .didRequireNoPointerHandleClassIdReturn &&
        sourceWitnessContractShapeFacts
            .didRequireSourceLifetimeOutlivesRendererObservation &&
        sourceWitnessContractShapeFacts
            .didRequireCleanupOwnershipRetainedByExternalSource &&
        sourceWitnessContractShapeFacts
            .didKeepRendererCleanupExecutionBlocked &&
        sourceWitnessContractShapeFacts
            .didRequireHeadlessFailClosedWitness &&
        sourceWitnessContractShapeFacts
            .didRequireNonUserVisibleObservation &&
        sourceWitnessContractShapeFacts
            .didRejectThrowawaySingletonAsWitness &&
        sourceWitnessContractShapeFacts
            .didRejectSmokeHarnessAsProductionWitness &&
        sourceWitnessContractShapeFacts
            .didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse &&
        sourceWitnessContractShapeFacts
            .didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse &&
        sourceWitnessContractShapeFacts
            .didConfirmProductionSingletonOwnershipTruthFalse &&
        sourceWitnessContractShapeFacts
            .didConfirmProductionSingletonImplementationBlocked &&
        sourceWitnessContractShapeFacts
            .didConfirmProductionActualAccessorCallSiteBlocked &&
        sourceWitnessContractShapeFacts
            .didConfirmNoActivationPolicyMutation &&
        sourceWitnessContractShapeFacts
            .didConfirmNoApplicationActivation &&
        sourceWitnessContractShapeFacts
            .didConfirmNoAppKitEventLoop &&
        sourceWitnessContractShapeFacts
            .didConfirmNoBoundedRunLoopPump &&
        sourceWitnessContractShapeFacts
            .didConfirmNoWindowViewLayerCreation &&
        sourceWitnessContractShapeFacts
            .didConfirmNoVisibleOrder &&
        sourceWitnessContractShapeFacts
            .didConfirmNoDrawable &&
        sourceWitnessContractShapeFacts
            .didConfirmNoCommandQueueBufferEncoder &&
        sourceWitnessContractShapeFacts
            .didConfirmNoRenderCommitPresentGpuSubmission &&
        sourceWitnessContractShapeFacts
            .didConfirmNoArtifactOrDiagnosticsPublication &&
        sourceWitnessContractShapeFacts
            .didConfirmNoPublicApi &&
        sourceWitnessContractShapeFacts
            .didConfirmNoProductionPublicCAbi &&
        sourceWitnessContractShapeFacts
            .didConfirmNoRuntimeStateWrite &&
        sourceWitnessContractShapeFacts
            .didConfirmNoCjpmTomlChange &&
        sourceWitnessContractShapeFacts
            .didConfirmNoRendererStateWrite &&
        sourceWitnessContractShapeFacts
            .didConfirmNoBackendReadyTruth &&
        sourceWitnessContractShapeFacts
            .didKeepExternalPreexistingSingletonSourceWitnessContractShapeValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShape(
        sourceWitnessContractShapeFacts,
        admitted,
        !admitted,
        !admitted,
        sourceWitnessContractShapeFacts
            .didRequireWitnessProvidedByExternalOwner,
        sourceWitnessContractShapeFacts
            .didRequirePreexistingSingletonBeforeRendererObservation,
        sourceWitnessContractShapeFacts
            .didRequireWitnessCapturedBeforeRuntimeOwner,
        sourceWitnessContractShapeFacts
            .didRequireMainThreadWitnessDeclaration,
        sourceWitnessContractShapeFacts
            .didRequireNoRendererCreationInvariant,
        sourceWitnessContractShapeFacts
            .didRequireNoRendererAccessorCallInvariant,
        sourceWitnessContractShapeFacts
            .didRequireCleanupOwnershipRetainedByExternalSource,
        sourceWitnessContractShapeFacts
            .didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse,
        sourceWitnessContractShapeFacts
            .didConfirmProductionSingletonOwnershipTruthFalse,
        sourceWitnessContractShapeFacts
            .didConfirmProductionSingletonImplementationBlocked,
        sourceWitnessContractShapeFacts
            .didConfirmProductionActualAccessorCallSiteBlocked,
        sourceWitnessContractShapeFacts
            .didKeepExternalPreexistingSingletonSourceWitnessContractShapeValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeReadiness(
    sourceReadinessPreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightReadiness,
    sourceWitnessContractShape:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShape
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeReadiness {
    let admitted =
        sourceWitnessContractShape
            .didAdmitExternalPreexistingSingletonSourceWitnessContractShape
    let facts =
        sourceWitnessContractShape.sourceWitnessContractShapeFacts

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeReadiness(
        sourceReadinessPreflight,
        sourceWitnessContractShape,
        admitted,
        !admitted,
        !admitted,
        facts
            .didPreserveExternalPreexistingSingletonSourceReadinessPreflight,
        sourceWitnessContractShape.didRequireWitnessProvidedByExternalOwner,
        sourceWitnessContractShape
            .didRequirePreexistingSingletonBeforeRendererObservation,
        sourceWitnessContractShape.didRequireWitnessCapturedBeforeRuntimeOwner,
        sourceWitnessContractShape.didRequireMainThreadWitnessDeclaration,
        sourceWitnessContractShape.didRequireNoRendererCreationInvariant,
        sourceWitnessContractShape.didRequireNoRendererAccessorCallInvariant,
        sourceWitnessContractShape
            .didRequireCleanupOwnershipRetainedByExternalSource,
        sourceWitnessContractShape
            .didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse,
        sourceWitnessContractShape.didConfirmProductionSingletonOwnershipTruthFalse,
        sourceWitnessContractShape
            .didConfirmProductionSingletonImplementationBlocked,
        sourceWitnessContractShape
            .didConfirmProductionActualAccessorCallSiteBlocked,
        sourceWitnessContractShape
            .didKeepExternalPreexistingSingletonSourceWitnessContractShapeValueOnly
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeReadiness {
    let sourceReadinessPreflight =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightDraft()
    let sourceWitnessContractShapeFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeFacts(
            sourceReadinessPreflight
        )
    let sourceWitnessContractShape =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShape(
            sourceWitnessContractShapeFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeReadiness(
        sourceReadinessPreflight,
        sourceWitnessContractShape
    )
}
