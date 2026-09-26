// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application side-effect containment evidence value boundary owner。
// Owner: runtime renderer internal NSApplication shared-application side-effect
// containment evidence owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness，
// 固定 side-effect containment、accessor-call containment carry-forward、
// artifact non-publication、application side effect blocked 与 no backend-ready
// truth 仍是后续 visible-window harness 的 internal evidence facts。
// Stop-line: 不写 artifact，不发布 diagnostics，不执行真实 teardown，不运行
// AppKit event loop，不实现 bounded pump，不调用 application singleton accessor，
// 不创建 NSApplication，不 activation，不修改 activation policy，不做 native
// visible order implementation，不获取 drawable，不创建 encoder，不 draw，不提交
// GPU work，不执行 render，不返回 Class / id / pointer / handle，不写
// runtime_state.cj，不扩 public API，不新增 native bridge C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、
// accessor-ready、artifact-ready、diagnostics-ready、visible-ready、
// drawable-ready、render-ready、backend-ready、renderer state write、receipt、
// record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceFacts {
    let didPreserveHeadlessArtifactPolicyEvidenceReadiness: Bool
    let didRequireSideEffectContainmentEvidence: Bool
    let didCarryForwardAccessorCallContainmentEvidence: Bool
    let didCarryForwardApplicationSideEffectBlocked: Bool
    let didCarryForwardHeadlessArtifactPolicyEvidence: Bool
    let didKeepArtifactWriteBlocked: Bool
    let didKeepArtifactPublicationBlocked: Bool
    let didKeepPublicDiagnosticsBlocked: Bool
    let didKeepArtifactEvidenceNonRuntimeTruth: Bool
    let didKeepActualTeardownExecutionBlocked: Bool
    let didKeepActualEventLoopBlocked: Bool
    let didKeepActualRunLoopPumpBlocked: Bool
    let didKeepActualApplicationSingletonAccessorCallBlocked: Bool
    let didKeepNoApplicationSingletonAccessorCall: Bool
    let didKeepApplicationSingletonCreationBlocked: Bool
    let didKeepActivationPolicyMutationBlocked: Bool
    let didKeepApplicationActivationBlocked: Bool
    let didKeepNativeVisibleOrderImplementationBlocked: Bool
    let didKeepProductionDrawablePermissionBlocked: Bool
    let didKeepRenderPermissionBlocked: Bool
    let didConfirmNoApplicationCreationOrActivation: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoPublicCAbi: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepSideEffectContainmentEvidenceValueOnly: Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidAccessorReadyWrapper: Bool
    let didAvoidArtifactDiagnosticsWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidRenderReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        didPreserveHeadlessArtifactPolicyEvidenceReadiness: Bool,
        didRequireSideEffectContainmentEvidence: Bool,
        didCarryForwardAccessorCallContainmentEvidence: Bool,
        didCarryForwardApplicationSideEffectBlocked: Bool,
        didCarryForwardHeadlessArtifactPolicyEvidence: Bool,
        didKeepArtifactWriteBlocked: Bool,
        didKeepArtifactPublicationBlocked: Bool,
        didKeepPublicDiagnosticsBlocked: Bool,
        didKeepArtifactEvidenceNonRuntimeTruth: Bool,
        didKeepActualTeardownExecutionBlocked: Bool,
        didKeepActualEventLoopBlocked: Bool,
        didKeepActualRunLoopPumpBlocked: Bool,
        didKeepActualApplicationSingletonAccessorCallBlocked: Bool,
        didKeepNoApplicationSingletonAccessorCall: Bool,
        didKeepApplicationSingletonCreationBlocked: Bool,
        didKeepActivationPolicyMutationBlocked: Bool,
        didKeepApplicationActivationBlocked: Bool,
        didKeepNativeVisibleOrderImplementationBlocked: Bool,
        didKeepProductionDrawablePermissionBlocked: Bool,
        didKeepRenderPermissionBlocked: Bool,
        didConfirmNoApplicationCreationOrActivation: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoPublicCAbi: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepSideEffectContainmentEvidenceValueOnly: Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidAccessorReadyWrapper: Bool,
        didAvoidArtifactDiagnosticsWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidRenderReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.didPreserveHeadlessArtifactPolicyEvidenceReadiness =
            didPreserveHeadlessArtifactPolicyEvidenceReadiness
        this.didRequireSideEffectContainmentEvidence =
            didRequireSideEffectContainmentEvidence
        this.didCarryForwardAccessorCallContainmentEvidence =
            didCarryForwardAccessorCallContainmentEvidence
        this.didCarryForwardApplicationSideEffectBlocked =
            didCarryForwardApplicationSideEffectBlocked
        this.didCarryForwardHeadlessArtifactPolicyEvidence =
            didCarryForwardHeadlessArtifactPolicyEvidence
        this.didKeepArtifactWriteBlocked = didKeepArtifactWriteBlocked
        this.didKeepArtifactPublicationBlocked =
            didKeepArtifactPublicationBlocked
        this.didKeepPublicDiagnosticsBlocked =
            didKeepPublicDiagnosticsBlocked
        this.didKeepArtifactEvidenceNonRuntimeTruth =
            didKeepArtifactEvidenceNonRuntimeTruth
        this.didKeepActualTeardownExecutionBlocked =
            didKeepActualTeardownExecutionBlocked
        this.didKeepActualEventLoopBlocked = didKeepActualEventLoopBlocked
        this.didKeepActualRunLoopPumpBlocked =
            didKeepActualRunLoopPumpBlocked
        this.didKeepActualApplicationSingletonAccessorCallBlocked =
            didKeepActualApplicationSingletonAccessorCallBlocked
        this.didKeepNoApplicationSingletonAccessorCall =
            didKeepNoApplicationSingletonAccessorCall
        this.didKeepApplicationSingletonCreationBlocked =
            didKeepApplicationSingletonCreationBlocked
        this.didKeepActivationPolicyMutationBlocked =
            didKeepActivationPolicyMutationBlocked
        this.didKeepApplicationActivationBlocked =
            didKeepApplicationActivationBlocked
        this.didKeepNativeVisibleOrderImplementationBlocked =
            didKeepNativeVisibleOrderImplementationBlocked
        this.didKeepProductionDrawablePermissionBlocked =
            didKeepProductionDrawablePermissionBlocked
        this.didKeepRenderPermissionBlocked = didKeepRenderPermissionBlocked
        this.didConfirmNoApplicationCreationOrActivation =
            didConfirmNoApplicationCreationOrActivation
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoPublicCAbi = didConfirmNoPublicCAbi
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepSideEffectContainmentEvidenceValueOnly =
            didKeepSideEffectContainmentEvidenceValueOnly
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidAccessorReadyWrapper = didAvoidAccessorReadyWrapper
        this.didAvoidArtifactDiagnosticsWrapper =
            didAvoidArtifactDiagnosticsWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidRenderReadyWrapper = didAvoidRenderReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceAdmission {
    let sideEffectContainmentEvidenceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceFacts
    let didAdmitNsApplicationSharedApplicationSideEffectContainmentEvidenceBoundary:
        Bool
    let shouldDeferNsApplicationSharedApplicationSideEffectContainmentEvidenceBoundary:
        Bool
    let shouldReportNsApplicationSharedApplicationSideEffectContainmentEvidenceBlocked:
        Bool
    let didConfirmSideEffectContainmentEvidenceRequired: Bool
    let didConfirmAccessorCallContainmentEvidenceCarriedForward: Bool
    let didConfirmApplicationSideEffectStillBlocked: Bool
    let didConfirmActualApplicationSingletonAccessorCallStillBlocked: Bool
    let didConfirmNoApplicationSingletonAccessorCall: Bool
    let didConfirmApplicationSingletonCreationStillBlocked: Bool
    let didConfirmArtifactWriteStillBlocked: Bool
    let didConfirmArtifactPublicationStillBlocked: Bool
    let didConfirmPublicDiagnosticsStillBlocked: Bool
    let didConfirmActualTeardownExecutionStillBlocked: Bool
    let didConfirmActualEventLoopStillBlocked: Bool
    let didConfirmActualRunLoopPumpStillBlocked: Bool
    let didConfirmActivationPolicyMutationStillBlocked: Bool
    let didConfirmApplicationActivationStillBlocked: Bool
    let didKeepNsApplicationSharedApplicationSideEffectContainmentEvidenceValueOnly:
        Bool

    init(
        sideEffectContainmentEvidenceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceFacts,
        didAdmitNsApplicationSharedApplicationSideEffectContainmentEvidenceBoundary:
            Bool,
        shouldDeferNsApplicationSharedApplicationSideEffectContainmentEvidenceBoundary:
            Bool,
        shouldReportNsApplicationSharedApplicationSideEffectContainmentEvidenceBlocked:
            Bool,
        didConfirmSideEffectContainmentEvidenceRequired: Bool,
        didConfirmAccessorCallContainmentEvidenceCarriedForward: Bool,
        didConfirmApplicationSideEffectStillBlocked: Bool,
        didConfirmActualApplicationSingletonAccessorCallStillBlocked: Bool,
        didConfirmNoApplicationSingletonAccessorCall: Bool,
        didConfirmApplicationSingletonCreationStillBlocked: Bool,
        didConfirmArtifactWriteStillBlocked: Bool,
        didConfirmArtifactPublicationStillBlocked: Bool,
        didConfirmPublicDiagnosticsStillBlocked: Bool,
        didConfirmActualTeardownExecutionStillBlocked: Bool,
        didConfirmActualEventLoopStillBlocked: Bool,
        didConfirmActualRunLoopPumpStillBlocked: Bool,
        didConfirmActivationPolicyMutationStillBlocked: Bool,
        didConfirmApplicationActivationStillBlocked: Bool,
        didKeepNsApplicationSharedApplicationSideEffectContainmentEvidenceValueOnly:
            Bool
    ) {
        this.sideEffectContainmentEvidenceFacts =
            sideEffectContainmentEvidenceFacts
        this.didAdmitNsApplicationSharedApplicationSideEffectContainmentEvidenceBoundary =
            didAdmitNsApplicationSharedApplicationSideEffectContainmentEvidenceBoundary
        this.shouldDeferNsApplicationSharedApplicationSideEffectContainmentEvidenceBoundary =
            shouldDeferNsApplicationSharedApplicationSideEffectContainmentEvidenceBoundary
        this.shouldReportNsApplicationSharedApplicationSideEffectContainmentEvidenceBlocked =
            shouldReportNsApplicationSharedApplicationSideEffectContainmentEvidenceBlocked
        this.didConfirmSideEffectContainmentEvidenceRequired =
            didConfirmSideEffectContainmentEvidenceRequired
        this.didConfirmAccessorCallContainmentEvidenceCarriedForward =
            didConfirmAccessorCallContainmentEvidenceCarriedForward
        this.didConfirmApplicationSideEffectStillBlocked =
            didConfirmApplicationSideEffectStillBlocked
        this.didConfirmActualApplicationSingletonAccessorCallStillBlocked =
            didConfirmActualApplicationSingletonAccessorCallStillBlocked
        this.didConfirmNoApplicationSingletonAccessorCall =
            didConfirmNoApplicationSingletonAccessorCall
        this.didConfirmApplicationSingletonCreationStillBlocked =
            didConfirmApplicationSingletonCreationStillBlocked
        this.didConfirmArtifactWriteStillBlocked =
            didConfirmArtifactWriteStillBlocked
        this.didConfirmArtifactPublicationStillBlocked =
            didConfirmArtifactPublicationStillBlocked
        this.didConfirmPublicDiagnosticsStillBlocked =
            didConfirmPublicDiagnosticsStillBlocked
        this.didConfirmActualTeardownExecutionStillBlocked =
            didConfirmActualTeardownExecutionStillBlocked
        this.didConfirmActualEventLoopStillBlocked =
            didConfirmActualEventLoopStillBlocked
        this.didConfirmActualRunLoopPumpStillBlocked =
            didConfirmActualRunLoopPumpStillBlocked
        this.didConfirmActivationPolicyMutationStillBlocked =
            didConfirmActivationPolicyMutationStillBlocked
        this.didConfirmApplicationActivationStillBlocked =
            didConfirmApplicationActivationStillBlocked
        this.didKeepNsApplicationSharedApplicationSideEffectContainmentEvidenceValueOnly =
            didKeepNsApplicationSharedApplicationSideEffectContainmentEvidenceValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceReadiness {
    let nsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness
    let nsApplicationSharedApplicationSideEffectContainmentEvidenceAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceAdmission
    let didPrepareRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceReadiness:
        Bool
    let shouldDeferRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceReadiness:
        Bool
    let shouldReportRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceBlocked:
        Bool
    let didPreserveNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness:
        Bool
    let didConfirmSideEffectContainmentEvidenceRequired: Bool
    let didConfirmAccessorCallContainmentEvidenceCarriedForward: Bool
    let didConfirmApplicationSideEffectStillBlocked: Bool
    let didConfirmActualApplicationSingletonAccessorCallStillBlocked: Bool
    let didConfirmNoApplicationSingletonAccessorCall: Bool
    let didConfirmApplicationSingletonCreationStillBlocked: Bool
    let didConfirmArtifactWriteStillBlocked: Bool
    let didConfirmArtifactPublicationStillBlocked: Bool
    let didConfirmPublicDiagnosticsStillBlocked: Bool
    let didConfirmActualTeardownExecutionStillBlocked: Bool
    let didConfirmActualEventLoopStillBlocked: Bool
    let didConfirmActualRunLoopPumpStillBlocked: Bool
    let didConfirmActivationPolicyMutationStillBlocked: Bool
    let didConfirmApplicationActivationStillBlocked: Bool
    let didConfirmNativeVisibleOrderStillBlocked: Bool
    let didConfirmProductionDrawableStillBlocked: Bool
    let didConfirmRenderStillBlocked: Bool
    let didConfirmNoApplicationCreationOrActivation: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoPublicCAbi: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNsApplicationSharedApplicationSideEffectContainmentEvidenceReadinessDehydrated:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidAccessorReadyWrapper: Bool
    let didAvoidArtifactDiagnosticsWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidRenderReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        nsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness,
        nsApplicationSharedApplicationSideEffectContainmentEvidenceAdmission:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceAdmission,
        didPrepareRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceReadiness:
            Bool,
        shouldDeferRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceReadiness:
            Bool,
        shouldReportRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceBlocked:
            Bool,
        didPreserveNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness:
            Bool,
        didConfirmSideEffectContainmentEvidenceRequired: Bool,
        didConfirmAccessorCallContainmentEvidenceCarriedForward: Bool,
        didConfirmApplicationSideEffectStillBlocked: Bool,
        didConfirmActualApplicationSingletonAccessorCallStillBlocked: Bool,
        didConfirmNoApplicationSingletonAccessorCall: Bool,
        didConfirmApplicationSingletonCreationStillBlocked: Bool,
        didConfirmArtifactWriteStillBlocked: Bool,
        didConfirmArtifactPublicationStillBlocked: Bool,
        didConfirmPublicDiagnosticsStillBlocked: Bool,
        didConfirmActualTeardownExecutionStillBlocked: Bool,
        didConfirmActualEventLoopStillBlocked: Bool,
        didConfirmActualRunLoopPumpStillBlocked: Bool,
        didConfirmActivationPolicyMutationStillBlocked: Bool,
        didConfirmApplicationActivationStillBlocked: Bool,
        didConfirmNativeVisibleOrderStillBlocked: Bool,
        didConfirmProductionDrawableStillBlocked: Bool,
        didConfirmRenderStillBlocked: Bool,
        didConfirmNoApplicationCreationOrActivation: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoPublicCAbi: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNsApplicationSharedApplicationSideEffectContainmentEvidenceReadinessDehydrated:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidAccessorReadyWrapper: Bool,
        didAvoidArtifactDiagnosticsWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidRenderReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.nsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness =
            nsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness
        this.nsApplicationSharedApplicationSideEffectContainmentEvidenceAdmission =
            nsApplicationSharedApplicationSideEffectContainmentEvidenceAdmission
        this.didPrepareRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceReadiness =
            didPrepareRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceReadiness
        this.shouldDeferRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceReadiness =
            shouldDeferRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceReadiness
        this.shouldReportRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceBlocked =
            shouldReportRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceBlocked
        this.didPreserveNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness =
            didPreserveNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness
        this.didConfirmSideEffectContainmentEvidenceRequired =
            didConfirmSideEffectContainmentEvidenceRequired
        this.didConfirmAccessorCallContainmentEvidenceCarriedForward =
            didConfirmAccessorCallContainmentEvidenceCarriedForward
        this.didConfirmApplicationSideEffectStillBlocked =
            didConfirmApplicationSideEffectStillBlocked
        this.didConfirmActualApplicationSingletonAccessorCallStillBlocked =
            didConfirmActualApplicationSingletonAccessorCallStillBlocked
        this.didConfirmNoApplicationSingletonAccessorCall =
            didConfirmNoApplicationSingletonAccessorCall
        this.didConfirmApplicationSingletonCreationStillBlocked =
            didConfirmApplicationSingletonCreationStillBlocked
        this.didConfirmArtifactWriteStillBlocked =
            didConfirmArtifactWriteStillBlocked
        this.didConfirmArtifactPublicationStillBlocked =
            didConfirmArtifactPublicationStillBlocked
        this.didConfirmPublicDiagnosticsStillBlocked =
            didConfirmPublicDiagnosticsStillBlocked
        this.didConfirmActualTeardownExecutionStillBlocked =
            didConfirmActualTeardownExecutionStillBlocked
        this.didConfirmActualEventLoopStillBlocked =
            didConfirmActualEventLoopStillBlocked
        this.didConfirmActualRunLoopPumpStillBlocked =
            didConfirmActualRunLoopPumpStillBlocked
        this.didConfirmActivationPolicyMutationStillBlocked =
            didConfirmActivationPolicyMutationStillBlocked
        this.didConfirmApplicationActivationStillBlocked =
            didConfirmApplicationActivationStillBlocked
        this.didConfirmNativeVisibleOrderStillBlocked =
            didConfirmNativeVisibleOrderStillBlocked
        this.didConfirmProductionDrawableStillBlocked =
            didConfirmProductionDrawableStillBlocked
        this.didConfirmRenderStillBlocked = didConfirmRenderStillBlocked
        this.didConfirmNoApplicationCreationOrActivation =
            didConfirmNoApplicationCreationOrActivation
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoPublicCAbi = didConfirmNoPublicCAbi
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNsApplicationSharedApplicationSideEffectContainmentEvidenceReadinessDehydrated =
            didKeepNsApplicationSharedApplicationSideEffectContainmentEvidenceReadinessDehydrated
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidAccessorReadyWrapper = didAvoidAccessorReadyWrapper
        this.didAvoidArtifactDiagnosticsWrapper =
            didAvoidArtifactDiagnosticsWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidRenderReadyWrapper = didAvoidRenderReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceFacts(
    headlessArtifactPolicyEvidenceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceFacts {
    let upstreamReady =
        headlessArtifactPolicyEvidenceReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness &&
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmHeadlessArtifactPolicyEvidenceRequired &&
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmActualArtifactWriteStillBlocked &&
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmArtifactPublicationStillBlocked &&
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmArtifactEvidenceStillNonRuntimeTruth &&
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmActualTeardownExecutionStillBlocked &&
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmActualEventLoopStillBlocked &&
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmActualRunLoopPumpStillBlocked &&
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmSideEffectContainmentEvidenceStillRequired &&
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmActualApplicationSingletonAccessorCallStillBlocked &&
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmNoApplicationSingletonAccessorCall &&
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmApplicationSingletonCreationStillBlocked &&
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmApplicationSideEffectStillBlocked &&
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmActivationPolicyMutationStillBlocked &&
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmApplicationActivationStillBlocked &&
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmNativeVisibleOrderStillBlocked &&
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmProductionDrawableStillBlocked &&
        headlessArtifactPolicyEvidenceReadiness.didConfirmRenderStillBlocked &&
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmNoApplicationCreationOrActivation &&
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmNoPointerHandleClassIdReturn &&
        headlessArtifactPolicyEvidenceReadiness.didConfirmNoPublicSurface &&
        headlessArtifactPolicyEvidenceReadiness.didConfirmNoPublicCAbi &&
        headlessArtifactPolicyEvidenceReadiness.didConfirmNoRendererStateWrite &&
        headlessArtifactPolicyEvidenceReadiness.didConfirmNoBackendReadyTruth &&
        headlessArtifactPolicyEvidenceReadiness
            .didKeepNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceFacts(
        upstreamReady,
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmSideEffectContainmentEvidenceStillRequired,
        true,
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmApplicationSideEffectStillBlocked,
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmHeadlessArtifactPolicyEvidenceRequired,
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmActualArtifactWriteStillBlocked,
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmArtifactPublicationStillBlocked,
        true,
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmArtifactEvidenceStillNonRuntimeTruth,
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmActualTeardownExecutionStillBlocked,
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmActualEventLoopStillBlocked,
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmActualRunLoopPumpStillBlocked,
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmActualApplicationSingletonAccessorCallStillBlocked,
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmNoApplicationSingletonAccessorCall,
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmApplicationSingletonCreationStillBlocked,
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmActivationPolicyMutationStillBlocked,
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmApplicationActivationStillBlocked,
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmNativeVisibleOrderStillBlocked,
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmProductionDrawableStillBlocked,
        headlessArtifactPolicyEvidenceReadiness.didConfirmRenderStillBlocked,
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmNoApplicationCreationOrActivation,
        headlessArtifactPolicyEvidenceReadiness
            .didConfirmNoPointerHandleClassIdReturn,
        headlessArtifactPolicyEvidenceReadiness.didConfirmNoPublicSurface,
        headlessArtifactPolicyEvidenceReadiness.didConfirmNoPublicCAbi,
        headlessArtifactPolicyEvidenceReadiness.didConfirmNoRendererStateWrite,
        headlessArtifactPolicyEvidenceReadiness.didConfirmNoBackendReadyTruth,
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

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceAdmission(
    sideEffectContainmentEvidenceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceAdmission {
    let admitted =
        sideEffectContainmentEvidenceFacts
            .didPreserveHeadlessArtifactPolicyEvidenceReadiness &&
        sideEffectContainmentEvidenceFacts
            .didRequireSideEffectContainmentEvidence &&
        sideEffectContainmentEvidenceFacts
            .didCarryForwardAccessorCallContainmentEvidence &&
        sideEffectContainmentEvidenceFacts
            .didCarryForwardApplicationSideEffectBlocked &&
        sideEffectContainmentEvidenceFacts.didKeepArtifactWriteBlocked &&
        sideEffectContainmentEvidenceFacts.didKeepArtifactPublicationBlocked &&
        sideEffectContainmentEvidenceFacts.didKeepPublicDiagnosticsBlocked &&
        sideEffectContainmentEvidenceFacts
            .didKeepActualTeardownExecutionBlocked &&
        sideEffectContainmentEvidenceFacts.didKeepActualEventLoopBlocked &&
        sideEffectContainmentEvidenceFacts.didKeepActualRunLoopPumpBlocked &&
        sideEffectContainmentEvidenceFacts
            .didKeepActualApplicationSingletonAccessorCallBlocked &&
        sideEffectContainmentEvidenceFacts
            .didKeepNoApplicationSingletonAccessorCall &&
        sideEffectContainmentEvidenceFacts
            .didKeepApplicationSingletonCreationBlocked &&
        sideEffectContainmentEvidenceFacts
            .didKeepActivationPolicyMutationBlocked &&
        sideEffectContainmentEvidenceFacts.didKeepApplicationActivationBlocked &&
        sideEffectContainmentEvidenceFacts
            .didKeepNativeVisibleOrderImplementationBlocked &&
        sideEffectContainmentEvidenceFacts
            .didKeepProductionDrawablePermissionBlocked &&
        sideEffectContainmentEvidenceFacts.didKeepRenderPermissionBlocked &&
        sideEffectContainmentEvidenceFacts.didConfirmNoPublicSurface &&
        sideEffectContainmentEvidenceFacts.didConfirmNoPublicCAbi &&
        sideEffectContainmentEvidenceFacts.didConfirmNoRendererStateWrite &&
        sideEffectContainmentEvidenceFacts.didConfirmNoBackendReadyTruth &&
        sideEffectContainmentEvidenceFacts
            .didKeepSideEffectContainmentEvidenceValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceAdmission(
        sideEffectContainmentEvidenceFacts,
        admitted,
        !admitted,
        !admitted,
        sideEffectContainmentEvidenceFacts
            .didRequireSideEffectContainmentEvidence,
        sideEffectContainmentEvidenceFacts
            .didCarryForwardAccessorCallContainmentEvidence,
        sideEffectContainmentEvidenceFacts
            .didCarryForwardApplicationSideEffectBlocked,
        sideEffectContainmentEvidenceFacts
            .didKeepActualApplicationSingletonAccessorCallBlocked,
        sideEffectContainmentEvidenceFacts
            .didKeepNoApplicationSingletonAccessorCall,
        sideEffectContainmentEvidenceFacts
            .didKeepApplicationSingletonCreationBlocked,
        sideEffectContainmentEvidenceFacts.didKeepArtifactWriteBlocked,
        sideEffectContainmentEvidenceFacts.didKeepArtifactPublicationBlocked,
        sideEffectContainmentEvidenceFacts.didKeepPublicDiagnosticsBlocked,
        sideEffectContainmentEvidenceFacts
            .didKeepActualTeardownExecutionBlocked,
        sideEffectContainmentEvidenceFacts.didKeepActualEventLoopBlocked,
        sideEffectContainmentEvidenceFacts.didKeepActualRunLoopPumpBlocked,
        sideEffectContainmentEvidenceFacts
            .didKeepActivationPolicyMutationBlocked,
        sideEffectContainmentEvidenceFacts.didKeepApplicationActivationBlocked,
        sideEffectContainmentEvidenceFacts
            .didKeepSideEffectContainmentEvidenceValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceReadiness(
    headlessArtifactPolicyEvidenceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness,
    sideEffectContainmentEvidenceAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceAdmission
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceReadiness {
    let admitted =
        sideEffectContainmentEvidenceAdmission
            .didAdmitNsApplicationSharedApplicationSideEffectContainmentEvidenceBoundary
    let sideEffectContainmentEvidenceFacts =
        sideEffectContainmentEvidenceAdmission
            .sideEffectContainmentEvidenceFacts

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceReadiness(
        headlessArtifactPolicyEvidenceReadiness,
        sideEffectContainmentEvidenceAdmission,
        admitted,
        !admitted,
        !admitted,
        sideEffectContainmentEvidenceFacts
            .didPreserveHeadlessArtifactPolicyEvidenceReadiness,
        sideEffectContainmentEvidenceAdmission
            .didConfirmSideEffectContainmentEvidenceRequired,
        sideEffectContainmentEvidenceAdmission
            .didConfirmAccessorCallContainmentEvidenceCarriedForward,
        sideEffectContainmentEvidenceAdmission
            .didConfirmApplicationSideEffectStillBlocked,
        sideEffectContainmentEvidenceAdmission
            .didConfirmActualApplicationSingletonAccessorCallStillBlocked,
        sideEffectContainmentEvidenceAdmission
            .didConfirmNoApplicationSingletonAccessorCall,
        sideEffectContainmentEvidenceAdmission
            .didConfirmApplicationSingletonCreationStillBlocked,
        sideEffectContainmentEvidenceAdmission
            .didConfirmArtifactWriteStillBlocked,
        sideEffectContainmentEvidenceAdmission
            .didConfirmArtifactPublicationStillBlocked,
        sideEffectContainmentEvidenceAdmission
            .didConfirmPublicDiagnosticsStillBlocked,
        sideEffectContainmentEvidenceAdmission
            .didConfirmActualTeardownExecutionStillBlocked,
        sideEffectContainmentEvidenceAdmission
            .didConfirmActualEventLoopStillBlocked,
        sideEffectContainmentEvidenceAdmission
            .didConfirmActualRunLoopPumpStillBlocked,
        sideEffectContainmentEvidenceAdmission
            .didConfirmActivationPolicyMutationStillBlocked,
        sideEffectContainmentEvidenceAdmission
            .didConfirmApplicationActivationStillBlocked,
        sideEffectContainmentEvidenceFacts
            .didKeepNativeVisibleOrderImplementationBlocked,
        sideEffectContainmentEvidenceFacts
            .didKeepProductionDrawablePermissionBlocked,
        sideEffectContainmentEvidenceFacts.didKeepRenderPermissionBlocked,
        sideEffectContainmentEvidenceFacts
            .didConfirmNoApplicationCreationOrActivation,
        sideEffectContainmentEvidenceFacts.didConfirmNoPointerHandleClassIdReturn,
        sideEffectContainmentEvidenceFacts.didConfirmNoPublicSurface,
        sideEffectContainmentEvidenceFacts.didConfirmNoPublicCAbi,
        sideEffectContainmentEvidenceFacts.didConfirmNoRendererStateWrite,
        sideEffectContainmentEvidenceFacts.didConfirmNoBackendReadyTruth,
        sideEffectContainmentEvidenceAdmission
            .didKeepNsApplicationSharedApplicationSideEffectContainmentEvidenceValueOnly,
        sideEffectContainmentEvidenceFacts.didAvoidApplicationReadyWrapper,
        sideEffectContainmentEvidenceFacts.didAvoidAccessorReadyWrapper,
        sideEffectContainmentEvidenceFacts.didAvoidArtifactDiagnosticsWrapper,
        sideEffectContainmentEvidenceFacts.didAvoidVisibleReadyWrapper,
        sideEffectContainmentEvidenceFacts.didAvoidDrawableReadyWrapper,
        sideEffectContainmentEvidenceFacts.didAvoidRenderReadyWrapper,
        sideEffectContainmentEvidenceFacts.didAvoidBackendReadyWrapper,
        sideEffectContainmentEvidenceFacts.didAvoidReceiptRecordPublication
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceReadiness {
    let headlessArtifactPolicyEvidenceReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceDraft()
    let sideEffectContainmentEvidenceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceFacts(
            headlessArtifactPolicyEvidenceReadiness
        )
    let sideEffectContainmentEvidenceAdmission =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceAdmission(
            sideEffectContainmentEvidenceFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceReadiness(
        headlessArtifactPolicyEvidenceReadiness,
        sideEffectContainmentEvidenceAdmission
    )
}
