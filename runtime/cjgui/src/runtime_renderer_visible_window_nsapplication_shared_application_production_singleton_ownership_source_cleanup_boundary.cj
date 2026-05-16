// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application production singleton ownership source / cleanup boundary
// owner。
// Owner: runtime renderer internal production singleton ownership
// source-cleanup boundary owner。
// Truth: 只消费 throwaway creation probe evidence readiness，并固定
// production singleton source selection、cleanup responsibility、main-thread
// confinement 与 headless fail-closed 都必须先明确；throwaway singleton side
// effect 不能升级成 production ownership truth。
// Stop-line: 不实现 production singleton owner，不创建或激活 NSApplication，
// 不修改 activation policy，不运行 AppKit event loop / bounded pump，不执行
// cleanup / teardown，不创建 window / view / layer，不 visible order，不取
// drawable，不创建 command queue / command buffer / encoder，不 render /
// commit / present / GPU submission，不写 artifact / diagnostics
// publication，不返回 Class / id / pointer / handle，不写 runtime_state.cj，
// 不改 cjpm.toml，不扩 public API，不新增 production C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、
// accessor-ready、visible-ready、drawable-ready、render-ready、backend-ready、
// renderer state write、receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryFacts {
    let didPreserveThrowawayCreationProbeEvidenceReadiness: Bool
    let didConfirmProductionSingletonOwnershipSourceCleanupBoundaryDecision:
        Bool
    let didRejectThrowawaySingletonAsProductionOwnershipSource: Bool
    let didRequireExternalPreexistingSingletonSource: Bool
    let didRequireFutureRuntimeOwnerExplicitApproval: Bool
    let didRequireCleanupResponsibilityBeforeImplementation: Bool
    let didKeepCleanupExecutionBlocked: Bool
    let didRequireMainThreadConfinement: Bool
    let didRequireHeadlessFailClosed: Bool
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
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepProductionSingletonOwnershipSourceCleanupBoundaryValueOnly:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidAccessorReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidRenderReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        didPreserveThrowawayCreationProbeEvidenceReadiness: Bool,
        didConfirmProductionSingletonOwnershipSourceCleanupBoundaryDecision:
            Bool,
        didRejectThrowawaySingletonAsProductionOwnershipSource: Bool,
        didRequireExternalPreexistingSingletonSource: Bool,
        didRequireFutureRuntimeOwnerExplicitApproval: Bool,
        didRequireCleanupResponsibilityBeforeImplementation: Bool,
        didKeepCleanupExecutionBlocked: Bool,
        didRequireMainThreadConfinement: Bool,
        didRequireHeadlessFailClosed: Bool,
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
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepProductionSingletonOwnershipSourceCleanupBoundaryValueOnly:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidAccessorReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidRenderReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.didPreserveThrowawayCreationProbeEvidenceReadiness =
            didPreserveThrowawayCreationProbeEvidenceReadiness
        this.didConfirmProductionSingletonOwnershipSourceCleanupBoundaryDecision =
            didConfirmProductionSingletonOwnershipSourceCleanupBoundaryDecision
        this.didRejectThrowawaySingletonAsProductionOwnershipSource =
            didRejectThrowawaySingletonAsProductionOwnershipSource
        this.didRequireExternalPreexistingSingletonSource =
            didRequireExternalPreexistingSingletonSource
        this.didRequireFutureRuntimeOwnerExplicitApproval =
            didRequireFutureRuntimeOwnerExplicitApproval
        this.didRequireCleanupResponsibilityBeforeImplementation =
            didRequireCleanupResponsibilityBeforeImplementation
        this.didKeepCleanupExecutionBlocked = didKeepCleanupExecutionBlocked
        this.didRequireMainThreadConfinement =
            didRequireMainThreadConfinement
        this.didRequireHeadlessFailClosed = didRequireHeadlessFailClosed
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
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepProductionSingletonOwnershipSourceCleanupBoundaryValueOnly =
            didKeepProductionSingletonOwnershipSourceCleanupBoundaryValueOnly
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidAccessorReadyWrapper = didAvoidAccessorReadyWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidRenderReadyWrapper = didAvoidRenderReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundary {
    let sourceCleanupBoundaryFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryFacts
    let didAdmitProductionSingletonOwnershipSourceCleanupBoundary: Bool
    let shouldDeferProductionSingletonOwnershipSourceCleanupBoundary: Bool
    let shouldReportProductionSingletonOwnershipSourceCleanupBoundaryBlocked:
        Bool
    let didRejectThrowawaySingletonAsProductionOwnershipSource: Bool
    let didRequireExternalPreexistingSingletonSource: Bool
    let didRequireFutureRuntimeOwnerExplicitApproval: Bool
    let didRequireCleanupResponsibilityBeforeImplementation: Bool
    let didConfirmProductionSingletonOwnershipTruthFalse: Bool
    let didConfirmProductionSingletonImplementationBlocked: Bool
    let didConfirmProductionActualAccessorCallSiteBlocked: Bool
    let didKeepProductionSingletonOwnershipSourceCleanupBoundaryValueOnly:
        Bool

    init(
        sourceCleanupBoundaryFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryFacts,
        didAdmitProductionSingletonOwnershipSourceCleanupBoundary: Bool,
        shouldDeferProductionSingletonOwnershipSourceCleanupBoundary: Bool,
        shouldReportProductionSingletonOwnershipSourceCleanupBoundaryBlocked:
            Bool,
        didRejectThrowawaySingletonAsProductionOwnershipSource: Bool,
        didRequireExternalPreexistingSingletonSource: Bool,
        didRequireFutureRuntimeOwnerExplicitApproval: Bool,
        didRequireCleanupResponsibilityBeforeImplementation: Bool,
        didConfirmProductionSingletonOwnershipTruthFalse: Bool,
        didConfirmProductionSingletonImplementationBlocked: Bool,
        didConfirmProductionActualAccessorCallSiteBlocked: Bool,
        didKeepProductionSingletonOwnershipSourceCleanupBoundaryValueOnly:
            Bool
    ) {
        this.sourceCleanupBoundaryFacts = sourceCleanupBoundaryFacts
        this.didAdmitProductionSingletonOwnershipSourceCleanupBoundary =
            didAdmitProductionSingletonOwnershipSourceCleanupBoundary
        this.shouldDeferProductionSingletonOwnershipSourceCleanupBoundary =
            shouldDeferProductionSingletonOwnershipSourceCleanupBoundary
        this.shouldReportProductionSingletonOwnershipSourceCleanupBoundaryBlocked =
            shouldReportProductionSingletonOwnershipSourceCleanupBoundaryBlocked
        this.didRejectThrowawaySingletonAsProductionOwnershipSource =
            didRejectThrowawaySingletonAsProductionOwnershipSource
        this.didRequireExternalPreexistingSingletonSource =
            didRequireExternalPreexistingSingletonSource
        this.didRequireFutureRuntimeOwnerExplicitApproval =
            didRequireFutureRuntimeOwnerExplicitApproval
        this.didRequireCleanupResponsibilityBeforeImplementation =
            didRequireCleanupResponsibilityBeforeImplementation
        this.didConfirmProductionSingletonOwnershipTruthFalse =
            didConfirmProductionSingletonOwnershipTruthFalse
        this.didConfirmProductionSingletonImplementationBlocked =
            didConfirmProductionSingletonImplementationBlocked
        this.didConfirmProductionActualAccessorCallSiteBlocked =
            didConfirmProductionActualAccessorCallSiteBlocked
        this.didKeepProductionSingletonOwnershipSourceCleanupBoundaryValueOnly =
            didKeepProductionSingletonOwnershipSourceCleanupBoundaryValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryReadiness {
    let nsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness
    let productionSingletonOwnershipSourceCleanupBoundary:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundary
    let didPrepareProductionSingletonOwnershipSourceCleanupBoundaryReadiness:
        Bool
    let shouldDeferProductionSingletonOwnershipSourceCleanupBoundaryReadiness:
        Bool
    let shouldReportProductionSingletonOwnershipSourceCleanupBoundaryBlocked:
        Bool
    let didPreserveThrowawayCreationProbeEvidenceReadiness: Bool
    let didRejectThrowawaySingletonAsProductionOwnershipSource: Bool
    let didRequireExternalPreexistingSingletonSource: Bool
    let didRequireFutureRuntimeOwnerExplicitApproval: Bool
    let didRequireCleanupResponsibilityBeforeImplementation: Bool
    let didConfirmProductionSingletonOwnershipTruthFalse: Bool
    let didConfirmProductionSingletonImplementationBlocked: Bool
    let didConfirmProductionActualAccessorCallSiteBlocked: Bool
    let didKeepProductionSingletonOwnershipSourceCleanupBoundaryReadinessDehydrated:
        Bool

    init(
        nsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness,
        productionSingletonOwnershipSourceCleanupBoundary:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundary,
        didPrepareProductionSingletonOwnershipSourceCleanupBoundaryReadiness:
            Bool,
        shouldDeferProductionSingletonOwnershipSourceCleanupBoundaryReadiness:
            Bool,
        shouldReportProductionSingletonOwnershipSourceCleanupBoundaryBlocked:
            Bool,
        didPreserveThrowawayCreationProbeEvidenceReadiness: Bool,
        didRejectThrowawaySingletonAsProductionOwnershipSource: Bool,
        didRequireExternalPreexistingSingletonSource: Bool,
        didRequireFutureRuntimeOwnerExplicitApproval: Bool,
        didRequireCleanupResponsibilityBeforeImplementation: Bool,
        didConfirmProductionSingletonOwnershipTruthFalse: Bool,
        didConfirmProductionSingletonImplementationBlocked: Bool,
        didConfirmProductionActualAccessorCallSiteBlocked: Bool,
        didKeepProductionSingletonOwnershipSourceCleanupBoundaryReadinessDehydrated:
            Bool
    ) {
        this.nsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness =
            nsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness
        this.productionSingletonOwnershipSourceCleanupBoundary =
            productionSingletonOwnershipSourceCleanupBoundary
        this.didPrepareProductionSingletonOwnershipSourceCleanupBoundaryReadiness =
            didPrepareProductionSingletonOwnershipSourceCleanupBoundaryReadiness
        this.shouldDeferProductionSingletonOwnershipSourceCleanupBoundaryReadiness =
            shouldDeferProductionSingletonOwnershipSourceCleanupBoundaryReadiness
        this.shouldReportProductionSingletonOwnershipSourceCleanupBoundaryBlocked =
            shouldReportProductionSingletonOwnershipSourceCleanupBoundaryBlocked
        this.didPreserveThrowawayCreationProbeEvidenceReadiness =
            didPreserveThrowawayCreationProbeEvidenceReadiness
        this.didRejectThrowawaySingletonAsProductionOwnershipSource =
            didRejectThrowawaySingletonAsProductionOwnershipSource
        this.didRequireExternalPreexistingSingletonSource =
            didRequireExternalPreexistingSingletonSource
        this.didRequireFutureRuntimeOwnerExplicitApproval =
            didRequireFutureRuntimeOwnerExplicitApproval
        this.didRequireCleanupResponsibilityBeforeImplementation =
            didRequireCleanupResponsibilityBeforeImplementation
        this.didConfirmProductionSingletonOwnershipTruthFalse =
            didConfirmProductionSingletonOwnershipTruthFalse
        this.didConfirmProductionSingletonImplementationBlocked =
            didConfirmProductionSingletonImplementationBlocked
        this.didConfirmProductionActualAccessorCallSiteBlocked =
            didConfirmProductionActualAccessorCallSiteBlocked
        this.didKeepProductionSingletonOwnershipSourceCleanupBoundaryReadinessDehydrated =
            didKeepProductionSingletonOwnershipSourceCleanupBoundaryReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryFacts(
    throwawayCreationProbeEvidenceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryFacts {
    let upstreamReady =
        throwawayCreationProbeEvidenceReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness &&
        throwawayCreationProbeEvidenceReadiness
            .didPreserveIsolatedActualAccessorCallProbeEvidenceReadiness &&
        throwawayCreationProbeEvidenceReadiness
            .didConfirmExplicitHumanApprovalForThrowawayCreationProbeFirstSlice &&
        throwawayCreationProbeEvidenceReadiness
            .didConfineThrowawayCreationToIsolatedNativeProbe &&
        throwawayCreationProbeEvidenceReadiness
            .didAllowNsApplicationSharedApplicationToCreateThrowawaySingleton &&
        throwawayCreationProbeEvidenceReadiness
            .didRecordThrowawayCreationEvidenceNotProductionOwnershipTruth &&
        throwawayCreationProbeEvidenceReadiness
            .didReturnIntegerClassificationOnly &&
        throwawayCreationProbeEvidenceReadiness.didReturnDehydratedFactsOnly &&
        throwawayCreationProbeEvidenceReadiness
            .didKeepNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryFacts(
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

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundary(
    sourceCleanupBoundaryFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundary {
    let admitted =
        sourceCleanupBoundaryFacts
            .didPreserveThrowawayCreationProbeEvidenceReadiness &&
        sourceCleanupBoundaryFacts
            .didConfirmProductionSingletonOwnershipSourceCleanupBoundaryDecision &&
        sourceCleanupBoundaryFacts
            .didRejectThrowawaySingletonAsProductionOwnershipSource &&
        sourceCleanupBoundaryFacts
            .didRequireExternalPreexistingSingletonSource &&
        sourceCleanupBoundaryFacts
            .didRequireFutureRuntimeOwnerExplicitApproval &&
        sourceCleanupBoundaryFacts
            .didRequireCleanupResponsibilityBeforeImplementation &&
        sourceCleanupBoundaryFacts.didKeepCleanupExecutionBlocked &&
        sourceCleanupBoundaryFacts.didRequireMainThreadConfinement &&
        sourceCleanupBoundaryFacts.didRequireHeadlessFailClosed &&
        sourceCleanupBoundaryFacts
            .didConfirmProductionSingletonOwnershipTruthFalse &&
        sourceCleanupBoundaryFacts
            .didConfirmProductionSingletonImplementationBlocked &&
        sourceCleanupBoundaryFacts
            .didConfirmProductionActualAccessorCallSiteBlocked &&
        sourceCleanupBoundaryFacts.didConfirmNoActivationPolicyMutation &&
        sourceCleanupBoundaryFacts.didConfirmNoApplicationActivation &&
        sourceCleanupBoundaryFacts.didConfirmNoAppKitEventLoop &&
        sourceCleanupBoundaryFacts.didConfirmNoBoundedRunLoopPump &&
        sourceCleanupBoundaryFacts.didConfirmNoWindowViewLayerCreation &&
        sourceCleanupBoundaryFacts.didConfirmNoVisibleOrder &&
        sourceCleanupBoundaryFacts.didConfirmNoDrawable &&
        sourceCleanupBoundaryFacts.didConfirmNoCommandQueueBufferEncoder &&
        sourceCleanupBoundaryFacts
            .didConfirmNoRenderCommitPresentGpuSubmission &&
        sourceCleanupBoundaryFacts
            .didConfirmNoArtifactOrDiagnosticsPublication &&
        sourceCleanupBoundaryFacts.didConfirmNoPublicApi &&
        sourceCleanupBoundaryFacts.didConfirmNoProductionPublicCAbi &&
        sourceCleanupBoundaryFacts.didConfirmNoRuntimeStateWrite &&
        sourceCleanupBoundaryFacts.didConfirmNoCjpmTomlChange &&
        sourceCleanupBoundaryFacts.didConfirmNoPointerHandleClassIdReturn &&
        sourceCleanupBoundaryFacts.didConfirmNoRendererStateWrite &&
        sourceCleanupBoundaryFacts.didConfirmNoBackendReadyTruth &&
        sourceCleanupBoundaryFacts
            .didKeepProductionSingletonOwnershipSourceCleanupBoundaryValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundary(
        sourceCleanupBoundaryFacts,
        admitted,
        !admitted,
        !admitted,
        sourceCleanupBoundaryFacts
            .didRejectThrowawaySingletonAsProductionOwnershipSource,
        sourceCleanupBoundaryFacts.didRequireExternalPreexistingSingletonSource,
        sourceCleanupBoundaryFacts
            .didRequireFutureRuntimeOwnerExplicitApproval,
        sourceCleanupBoundaryFacts
            .didRequireCleanupResponsibilityBeforeImplementation,
        sourceCleanupBoundaryFacts
            .didConfirmProductionSingletonOwnershipTruthFalse,
        sourceCleanupBoundaryFacts
            .didConfirmProductionSingletonImplementationBlocked,
        sourceCleanupBoundaryFacts
            .didConfirmProductionActualAccessorCallSiteBlocked,
        sourceCleanupBoundaryFacts
            .didKeepProductionSingletonOwnershipSourceCleanupBoundaryValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryReadiness(
    throwawayCreationProbeEvidenceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness,
    sourceCleanupBoundary:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundary
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryReadiness {
    let admitted =
        sourceCleanupBoundary
            .didAdmitProductionSingletonOwnershipSourceCleanupBoundary
    let facts = sourceCleanupBoundary.sourceCleanupBoundaryFacts

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryReadiness(
        throwawayCreationProbeEvidenceReadiness,
        sourceCleanupBoundary,
        admitted,
        !admitted,
        !admitted,
        facts.didPreserveThrowawayCreationProbeEvidenceReadiness,
        sourceCleanupBoundary
            .didRejectThrowawaySingletonAsProductionOwnershipSource,
        sourceCleanupBoundary.didRequireExternalPreexistingSingletonSource,
        sourceCleanupBoundary.didRequireFutureRuntimeOwnerExplicitApproval,
        sourceCleanupBoundary
            .didRequireCleanupResponsibilityBeforeImplementation,
        sourceCleanupBoundary
            .didConfirmProductionSingletonOwnershipTruthFalse,
        sourceCleanupBoundary
            .didConfirmProductionSingletonImplementationBlocked,
        sourceCleanupBoundary
            .didConfirmProductionActualAccessorCallSiteBlocked,
        sourceCleanupBoundary
            .didKeepProductionSingletonOwnershipSourceCleanupBoundaryValueOnly
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryReadiness {
    let throwawayCreationProbeEvidenceReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceDraft()
    let sourceCleanupBoundaryFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryFacts(
            throwawayCreationProbeEvidenceReadiness
        )
    let sourceCleanupBoundary =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundary(
            sourceCleanupBoundaryFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryReadiness(
        throwawayCreationProbeEvidenceReadiness,
        sourceCleanupBoundary
    )
}
