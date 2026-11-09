// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application throwaway creation probe evidence owner。
// Owner: runtime renderer internal NSApplication shared-application throwaway
// creation probe evidence owner。
// Truth: 只消费 isolated actual accessor call probe evidence readiness；本阶段
// 人工批准 first slice 只在 isolated native probe 中调用 shared-application
// accessor，并允许它在没有 preexisting singleton 时创建
// throwaway singleton。该事实只作为 throwaway creation evidence，不是
// production singleton ownership truth。
// Stop-line: 不 activation，不改 activation policy，不运行 AppKit loop / app
// lifecycle shutdown，不创建 window / view / layer，不 visible order，不取 drawable，不
// 创建 command queue / command buffer / encoder，不 render / commit / present /
// GPU submission，不写 artifact / diagnostics publication，不返回 Class / id /
// pointer / handle，不写 runtime_state.cj，不改 cjpm.toml，不扩 public API，不
// 新增 production C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、
// accessor-ready、visible-ready、drawable-ready、render-ready、backend-ready、
// renderer state write、receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceFacts {
    let didPreserveIsolatedActualAccessorCallProbeEvidenceReadiness: Bool
    let didConfirmExplicitHumanApprovalForThrowawayCreationProbeFirstSlice:
        Bool
    let didConfineThrowawayCreationToIsolatedNativeProbe: Bool
    let didAllowNsApplicationSharedApplicationToCreateThrowawaySingleton:
        Bool
    let didRecordThrowawayCreationEvidenceNotProductionOwnershipTruth: Bool
    let didObserveAccessorReturnOnly: Bool
    let didObserveSingletonExistenceOnly: Bool
    let didRequireMainThreadConfinement: Bool
    let didRequireFailClosedClassification: Bool
    let didReturnIntegerClassificationOnly: Bool
    let didReturnDehydratedFactsOnly: Bool
    let didConfirmNoActivationPolicyMutation: Bool
    let didConfirmNoApplicationActivation: Bool
    let didConfirmNoRunStopTerminate: Bool
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
    let didKeepThrowawayCreationProbeEvidenceValueOnly: Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidAccessorReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidRenderReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        didPreserveIsolatedActualAccessorCallProbeEvidenceReadiness: Bool,
        didConfirmExplicitHumanApprovalForThrowawayCreationProbeFirstSlice:
            Bool,
        didConfineThrowawayCreationToIsolatedNativeProbe: Bool,
        didAllowNsApplicationSharedApplicationToCreateThrowawaySingleton:
            Bool,
        didRecordThrowawayCreationEvidenceNotProductionOwnershipTruth:
            Bool,
        didObserveAccessorReturnOnly: Bool,
        didObserveSingletonExistenceOnly: Bool,
        didRequireMainThreadConfinement: Bool,
        didRequireFailClosedClassification: Bool,
        didReturnIntegerClassificationOnly: Bool,
        didReturnDehydratedFactsOnly: Bool,
        didConfirmNoActivationPolicyMutation: Bool,
        didConfirmNoApplicationActivation: Bool,
        didConfirmNoRunStopTerminate: Bool,
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
        didKeepThrowawayCreationProbeEvidenceValueOnly: Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidAccessorReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidRenderReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.didPreserveIsolatedActualAccessorCallProbeEvidenceReadiness =
            didPreserveIsolatedActualAccessorCallProbeEvidenceReadiness
        this.didConfirmExplicitHumanApprovalForThrowawayCreationProbeFirstSlice =
            didConfirmExplicitHumanApprovalForThrowawayCreationProbeFirstSlice
        this.didConfineThrowawayCreationToIsolatedNativeProbe =
            didConfineThrowawayCreationToIsolatedNativeProbe
        this.didAllowNsApplicationSharedApplicationToCreateThrowawaySingleton =
            didAllowNsApplicationSharedApplicationToCreateThrowawaySingleton
        this.didRecordThrowawayCreationEvidenceNotProductionOwnershipTruth =
            didRecordThrowawayCreationEvidenceNotProductionOwnershipTruth
        this.didObserveAccessorReturnOnly = didObserveAccessorReturnOnly
        this.didObserveSingletonExistenceOnly =
            didObserveSingletonExistenceOnly
        this.didRequireMainThreadConfinement =
            didRequireMainThreadConfinement
        this.didRequireFailClosedClassification =
            didRequireFailClosedClassification
        this.didReturnIntegerClassificationOnly =
            didReturnIntegerClassificationOnly
        this.didReturnDehydratedFactsOnly = didReturnDehydratedFactsOnly
        this.didConfirmNoActivationPolicyMutation =
            didConfirmNoActivationPolicyMutation
        this.didConfirmNoApplicationActivation =
            didConfirmNoApplicationActivation
        this.didConfirmNoRunStopTerminate = didConfirmNoRunStopTerminate
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
        this.didKeepThrowawayCreationProbeEvidenceValueOnly =
            didKeepThrowawayCreationProbeEvidenceValueOnly
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidence {
    let throwawayCreationProbeEvidenceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceFacts
    let didAdmitNsApplicationSharedApplicationThrowawayCreationProbeEvidenceBoundary:
        Bool
    let shouldDeferNsApplicationSharedApplicationThrowawayCreationProbeEvidenceBoundary:
        Bool
    let shouldReportNsApplicationSharedApplicationThrowawayCreationProbeEvidenceBlocked:
        Bool
    let didConfirmExplicitHumanApprovalForThrowawayCreationProbeFirstSlice:
        Bool
    let didConfineThrowawayCreationToIsolatedNativeProbe: Bool
    let didAllowNsApplicationSharedApplicationToCreateThrowawaySingleton:
        Bool
    let didRecordThrowawayCreationEvidenceNotProductionOwnershipTruth: Bool
    let didReturnIntegerClassificationOnly: Bool
    let didReturnDehydratedFactsOnly: Bool
    let didKeepNsApplicationSharedApplicationThrowawayCreationProbeEvidenceValueOnly:
        Bool

    init(
        throwawayCreationProbeEvidenceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceFacts,
        didAdmitNsApplicationSharedApplicationThrowawayCreationProbeEvidenceBoundary:
            Bool,
        shouldDeferNsApplicationSharedApplicationThrowawayCreationProbeEvidenceBoundary:
            Bool,
        shouldReportNsApplicationSharedApplicationThrowawayCreationProbeEvidenceBlocked:
            Bool,
        didConfirmExplicitHumanApprovalForThrowawayCreationProbeFirstSlice:
            Bool,
        didConfineThrowawayCreationToIsolatedNativeProbe: Bool,
        didAllowNsApplicationSharedApplicationToCreateThrowawaySingleton:
            Bool,
        didRecordThrowawayCreationEvidenceNotProductionOwnershipTruth:
            Bool,
        didReturnIntegerClassificationOnly: Bool,
        didReturnDehydratedFactsOnly: Bool,
        didKeepNsApplicationSharedApplicationThrowawayCreationProbeEvidenceValueOnly:
            Bool
    ) {
        this.throwawayCreationProbeEvidenceFacts =
            throwawayCreationProbeEvidenceFacts
        this.didAdmitNsApplicationSharedApplicationThrowawayCreationProbeEvidenceBoundary =
            didAdmitNsApplicationSharedApplicationThrowawayCreationProbeEvidenceBoundary
        this.shouldDeferNsApplicationSharedApplicationThrowawayCreationProbeEvidenceBoundary =
            shouldDeferNsApplicationSharedApplicationThrowawayCreationProbeEvidenceBoundary
        this.shouldReportNsApplicationSharedApplicationThrowawayCreationProbeEvidenceBlocked =
            shouldReportNsApplicationSharedApplicationThrowawayCreationProbeEvidenceBlocked
        this.didConfirmExplicitHumanApprovalForThrowawayCreationProbeFirstSlice =
            didConfirmExplicitHumanApprovalForThrowawayCreationProbeFirstSlice
        this.didConfineThrowawayCreationToIsolatedNativeProbe =
            didConfineThrowawayCreationToIsolatedNativeProbe
        this.didAllowNsApplicationSharedApplicationToCreateThrowawaySingleton =
            didAllowNsApplicationSharedApplicationToCreateThrowawaySingleton
        this.didRecordThrowawayCreationEvidenceNotProductionOwnershipTruth =
            didRecordThrowawayCreationEvidenceNotProductionOwnershipTruth
        this.didReturnIntegerClassificationOnly =
            didReturnIntegerClassificationOnly
        this.didReturnDehydratedFactsOnly = didReturnDehydratedFactsOnly
        this.didKeepNsApplicationSharedApplicationThrowawayCreationProbeEvidenceValueOnly =
            didKeepNsApplicationSharedApplicationThrowawayCreationProbeEvidenceValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness {
    let nsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness
    let nsApplicationSharedApplicationThrowawayCreationProbeEvidence:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidence
    let didPrepareRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness:
        Bool
    let shouldDeferRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness:
        Bool
    let shouldReportRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceBlocked:
        Bool
    let didPreserveIsolatedActualAccessorCallProbeEvidenceReadiness: Bool
    let didConfirmExplicitHumanApprovalForThrowawayCreationProbeFirstSlice:
        Bool
    let didConfineThrowawayCreationToIsolatedNativeProbe: Bool
    let didAllowNsApplicationSharedApplicationToCreateThrowawaySingleton:
        Bool
    let didRecordThrowawayCreationEvidenceNotProductionOwnershipTruth: Bool
    let didReturnIntegerClassificationOnly: Bool
    let didReturnDehydratedFactsOnly: Bool
    let didKeepNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadinessDehydrated:
        Bool

    init(
        nsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness,
        nsApplicationSharedApplicationThrowawayCreationProbeEvidence:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidence,
        didPrepareRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness:
            Bool,
        shouldDeferRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness:
            Bool,
        shouldReportRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceBlocked:
            Bool,
        didPreserveIsolatedActualAccessorCallProbeEvidenceReadiness: Bool,
        didConfirmExplicitHumanApprovalForThrowawayCreationProbeFirstSlice:
            Bool,
        didConfineThrowawayCreationToIsolatedNativeProbe: Bool,
        didAllowNsApplicationSharedApplicationToCreateThrowawaySingleton:
            Bool,
        didRecordThrowawayCreationEvidenceNotProductionOwnershipTruth:
            Bool,
        didReturnIntegerClassificationOnly: Bool,
        didReturnDehydratedFactsOnly: Bool,
        didKeepNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadinessDehydrated:
            Bool
    ) {
        this.nsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness =
            nsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness
        this.nsApplicationSharedApplicationThrowawayCreationProbeEvidence =
            nsApplicationSharedApplicationThrowawayCreationProbeEvidence
        this.didPrepareRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness =
            didPrepareRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness
        this.shouldDeferRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness =
            shouldDeferRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness
        this.shouldReportRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceBlocked =
            shouldReportRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceBlocked
        this.didPreserveIsolatedActualAccessorCallProbeEvidenceReadiness =
            didPreserveIsolatedActualAccessorCallProbeEvidenceReadiness
        this.didConfirmExplicitHumanApprovalForThrowawayCreationProbeFirstSlice =
            didConfirmExplicitHumanApprovalForThrowawayCreationProbeFirstSlice
        this.didConfineThrowawayCreationToIsolatedNativeProbe =
            didConfineThrowawayCreationToIsolatedNativeProbe
        this.didAllowNsApplicationSharedApplicationToCreateThrowawaySingleton =
            didAllowNsApplicationSharedApplicationToCreateThrowawaySingleton
        this.didRecordThrowawayCreationEvidenceNotProductionOwnershipTruth =
            didRecordThrowawayCreationEvidenceNotProductionOwnershipTruth
        this.didReturnIntegerClassificationOnly =
            didReturnIntegerClassificationOnly
        this.didReturnDehydratedFactsOnly = didReturnDehydratedFactsOnly
        this.didKeepNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadinessDehydrated =
            didKeepNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceFacts(
    isolatedActualAccessorCallProbeEvidenceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceFacts {
    let upstreamReady =
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness &&
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didPreserveActualAccessorCallPreflightGuardReadiness &&
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didConfineActualAccessorCallToIsolatedNativeProbe &&
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didRequireMainThreadGateBeforeActualAccessorCall &&
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didReturnIntegerClassificationOnly &&
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didReturnDehydratedFactsOnly &&
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didConfirmNoActivationPolicyMutation &&
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didConfirmNoApplicationActivation &&
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didConfirmNoAppKitEventLoop &&
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didConfirmNoBoundedRunLoopPump &&
        isolatedActualAccessorCallProbeEvidenceReadiness.didConfirmNoVisibleOrder &&
        isolatedActualAccessorCallProbeEvidenceReadiness.didConfirmNoDrawable &&
        isolatedActualAccessorCallProbeEvidenceReadiness.didConfirmNoRender &&
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didConfirmNoArtifactPublication &&
        isolatedActualAccessorCallProbeEvidenceReadiness.didConfirmNoPublicApi &&
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didConfirmNoProductionPublicCAbi &&
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didConfirmNoRuntimeStateWrite &&
        isolatedActualAccessorCallProbeEvidenceReadiness.didConfirmNoCjpmTomlChange &&
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didKeepNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceFacts(
        upstreamReady,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didReturnIntegerClassificationOnly,
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didReturnDehydratedFactsOnly,
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didConfirmNoActivationPolicyMutation,
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didConfirmNoApplicationActivation,
        true,
        true,
        isolatedActualAccessorCallProbeEvidenceReadiness.didConfirmNoVisibleOrder,
        isolatedActualAccessorCallProbeEvidenceReadiness.didConfirmNoDrawable,
        true,
        true,
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didConfirmNoArtifactPublication,
        isolatedActualAccessorCallProbeEvidenceReadiness.didConfirmNoPublicApi,
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didConfirmNoProductionPublicCAbi,
        isolatedActualAccessorCallProbeEvidenceReadiness
            .didConfirmNoRuntimeStateWrite,
        isolatedActualAccessorCallProbeEvidenceReadiness.didConfirmNoCjpmTomlChange,
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

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidence(
    throwawayCreationProbeEvidenceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidence {
    let admitted =
        throwawayCreationProbeEvidenceFacts
            .didPreserveIsolatedActualAccessorCallProbeEvidenceReadiness &&
        throwawayCreationProbeEvidenceFacts
            .didConfirmExplicitHumanApprovalForThrowawayCreationProbeFirstSlice &&
        throwawayCreationProbeEvidenceFacts
            .didConfineThrowawayCreationToIsolatedNativeProbe &&
        throwawayCreationProbeEvidenceFacts
            .didAllowNsApplicationSharedApplicationToCreateThrowawaySingleton &&
        throwawayCreationProbeEvidenceFacts
            .didRecordThrowawayCreationEvidenceNotProductionOwnershipTruth &&
        throwawayCreationProbeEvidenceFacts.didObserveAccessorReturnOnly &&
        throwawayCreationProbeEvidenceFacts.didObserveSingletonExistenceOnly &&
        throwawayCreationProbeEvidenceFacts.didRequireMainThreadConfinement &&
        throwawayCreationProbeEvidenceFacts.didRequireFailClosedClassification &&
        throwawayCreationProbeEvidenceFacts.didReturnIntegerClassificationOnly &&
        throwawayCreationProbeEvidenceFacts.didReturnDehydratedFactsOnly &&
        throwawayCreationProbeEvidenceFacts
            .didConfirmNoActivationPolicyMutation &&
        throwawayCreationProbeEvidenceFacts.didConfirmNoApplicationActivation &&
        throwawayCreationProbeEvidenceFacts.didConfirmNoRunStopTerminate &&
        throwawayCreationProbeEvidenceFacts.didConfirmNoWindowViewLayerCreation &&
        throwawayCreationProbeEvidenceFacts.didConfirmNoVisibleOrder &&
        throwawayCreationProbeEvidenceFacts.didConfirmNoDrawable &&
        throwawayCreationProbeEvidenceFacts.didConfirmNoCommandQueueBufferEncoder &&
        throwawayCreationProbeEvidenceFacts
            .didConfirmNoRenderCommitPresentGpuSubmission &&
        throwawayCreationProbeEvidenceFacts
            .didConfirmNoArtifactOrDiagnosticsPublication &&
        throwawayCreationProbeEvidenceFacts.didConfirmNoPublicApi &&
        throwawayCreationProbeEvidenceFacts.didConfirmNoProductionPublicCAbi &&
        throwawayCreationProbeEvidenceFacts.didConfirmNoRuntimeStateWrite &&
        throwawayCreationProbeEvidenceFacts.didConfirmNoCjpmTomlChange &&
        throwawayCreationProbeEvidenceFacts
            .didConfirmNoPointerHandleClassIdReturn &&
        throwawayCreationProbeEvidenceFacts.didConfirmNoRendererStateWrite &&
        throwawayCreationProbeEvidenceFacts.didConfirmNoBackendReadyTruth &&
        throwawayCreationProbeEvidenceFacts
            .didKeepThrowawayCreationProbeEvidenceValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidence(
        throwawayCreationProbeEvidenceFacts,
        admitted,
        !admitted,
        !admitted,
        throwawayCreationProbeEvidenceFacts
            .didConfirmExplicitHumanApprovalForThrowawayCreationProbeFirstSlice,
        throwawayCreationProbeEvidenceFacts
            .didConfineThrowawayCreationToIsolatedNativeProbe,
        throwawayCreationProbeEvidenceFacts
            .didAllowNsApplicationSharedApplicationToCreateThrowawaySingleton,
        throwawayCreationProbeEvidenceFacts
            .didRecordThrowawayCreationEvidenceNotProductionOwnershipTruth,
        throwawayCreationProbeEvidenceFacts
            .didReturnIntegerClassificationOnly,
        throwawayCreationProbeEvidenceFacts.didReturnDehydratedFactsOnly,
        throwawayCreationProbeEvidenceFacts
            .didKeepThrowawayCreationProbeEvidenceValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness(
    isolatedActualAccessorCallProbeEvidenceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness,
    throwawayCreationProbeEvidence:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidence
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness {
    let admitted =
        throwawayCreationProbeEvidence
            .didAdmitNsApplicationSharedApplicationThrowawayCreationProbeEvidenceBoundary
    let facts =
        throwawayCreationProbeEvidence.throwawayCreationProbeEvidenceFacts

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness(
        isolatedActualAccessorCallProbeEvidenceReadiness,
        throwawayCreationProbeEvidence,
        admitted,
        !admitted,
        !admitted,
        facts.didPreserveIsolatedActualAccessorCallProbeEvidenceReadiness,
        throwawayCreationProbeEvidence
            .didConfirmExplicitHumanApprovalForThrowawayCreationProbeFirstSlice,
        throwawayCreationProbeEvidence
            .didConfineThrowawayCreationToIsolatedNativeProbe,
        throwawayCreationProbeEvidence
            .didAllowNsApplicationSharedApplicationToCreateThrowawaySingleton,
        throwawayCreationProbeEvidence
            .didRecordThrowawayCreationEvidenceNotProductionOwnershipTruth,
        throwawayCreationProbeEvidence.didReturnIntegerClassificationOnly,
        throwawayCreationProbeEvidence.didReturnDehydratedFactsOnly,
        throwawayCreationProbeEvidence
            .didKeepNsApplicationSharedApplicationThrowawayCreationProbeEvidenceValueOnly
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness {
    let isolatedActualAccessorCallProbeEvidenceReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceDraft()
    let throwawayCreationProbeEvidenceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceFacts(
            isolatedActualAccessorCallProbeEvidenceReadiness
        )
    let throwawayCreationProbeEvidence =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidence(
            throwawayCreationProbeEvidenceFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness(
        isolatedActualAccessorCallProbeEvidenceReadiness,
        throwawayCreationProbeEvidence
    )
}
