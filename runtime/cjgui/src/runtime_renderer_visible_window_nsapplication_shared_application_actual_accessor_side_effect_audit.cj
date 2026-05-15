// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application actual accessor side-effect audit value boundary owner。
// Owner: runtime renderer internal NSApplication shared-application actual
// accessor side-effect audit owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSingletonAccessorAdmissionReadiness，
// 固定 actual accessor side-effect audit required、application singleton
// lifecycle side-effect risk classified、main-thread / headless / teardown /
// artifact diagnostics / rollback cleanup audit required，以及 actual accessor
// call still blocked 与 no backend-ready truth facts。
// Stop-line: 不调用 application singleton accessor，不创建 NSApplication，不
// activation，不修改 activation policy，不运行 event loop，不实现 bounded pump，
// 不执行 actual teardown，不写 artifact，不发布 diagnostics，不做 native visible
// order implementation，不获取 drawable，不创建 encoder，不 draw，不提交 GPU work，
// 不执行 render，不返回 Class / id / pointer / handle，不写 runtime_state.cj，
// 不扩 public API，不新增 native bridge C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、
// accessor-ready、visible-ready、drawable-ready、render-ready、backend-ready、
// renderer state write、receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditFacts {
    let didPreserveSingletonAccessorAdmissionReadiness: Bool
    let didRequireActualAccessorSideEffectAudit: Bool
    let didClassifyApplicationSingletonLifecycleSideEffectRisk: Bool
    let didRequireMainThreadAuditBeforeAccessorCall: Bool
    let didRequireHeadlessFailClosedAudit: Bool
    let didRequireTeardownBeforeVisibleAudit: Bool
    let didRequireArtifactDiagnosticsNonPublicationAudit: Bool
    let didRequireRollbackCleanupEvidenceBeforeAccessorCall: Bool
    let didKeepActualApplicationSingletonAccessorCallBlocked: Bool
    let didKeepNoApplicationSingletonAccessorCall: Bool
    let didKeepApplicationSingletonCreationBlocked: Bool
    let didKeepArtifactWriteBlocked: Bool
    let didKeepArtifactPublicationBlocked: Bool
    let didKeepPublicDiagnosticsBlocked: Bool
    let didKeepActualTeardownExecutionBlocked: Bool
    let didKeepActualEventLoopBlocked: Bool
    let didKeepActualRunLoopPumpBlocked: Bool
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
    let didKeepActualAccessorSideEffectAuditValueOnly: Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidAccessorReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidRenderReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        didPreserveSingletonAccessorAdmissionReadiness: Bool,
        didRequireActualAccessorSideEffectAudit: Bool,
        didClassifyApplicationSingletonLifecycleSideEffectRisk: Bool,
        didRequireMainThreadAuditBeforeAccessorCall: Bool,
        didRequireHeadlessFailClosedAudit: Bool,
        didRequireTeardownBeforeVisibleAudit: Bool,
        didRequireArtifactDiagnosticsNonPublicationAudit: Bool,
        didRequireRollbackCleanupEvidenceBeforeAccessorCall: Bool,
        didKeepActualApplicationSingletonAccessorCallBlocked: Bool,
        didKeepNoApplicationSingletonAccessorCall: Bool,
        didKeepApplicationSingletonCreationBlocked: Bool,
        didKeepArtifactWriteBlocked: Bool,
        didKeepArtifactPublicationBlocked: Bool,
        didKeepPublicDiagnosticsBlocked: Bool,
        didKeepActualTeardownExecutionBlocked: Bool,
        didKeepActualEventLoopBlocked: Bool,
        didKeepActualRunLoopPumpBlocked: Bool,
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
        didKeepActualAccessorSideEffectAuditValueOnly: Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidAccessorReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidRenderReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.didPreserveSingletonAccessorAdmissionReadiness =
            didPreserveSingletonAccessorAdmissionReadiness
        this.didRequireActualAccessorSideEffectAudit =
            didRequireActualAccessorSideEffectAudit
        this.didClassifyApplicationSingletonLifecycleSideEffectRisk =
            didClassifyApplicationSingletonLifecycleSideEffectRisk
        this.didRequireMainThreadAuditBeforeAccessorCall =
            didRequireMainThreadAuditBeforeAccessorCall
        this.didRequireHeadlessFailClosedAudit =
            didRequireHeadlessFailClosedAudit
        this.didRequireTeardownBeforeVisibleAudit =
            didRequireTeardownBeforeVisibleAudit
        this.didRequireArtifactDiagnosticsNonPublicationAudit =
            didRequireArtifactDiagnosticsNonPublicationAudit
        this.didRequireRollbackCleanupEvidenceBeforeAccessorCall =
            didRequireRollbackCleanupEvidenceBeforeAccessorCall
        this.didKeepActualApplicationSingletonAccessorCallBlocked =
            didKeepActualApplicationSingletonAccessorCallBlocked
        this.didKeepNoApplicationSingletonAccessorCall =
            didKeepNoApplicationSingletonAccessorCall
        this.didKeepApplicationSingletonCreationBlocked =
            didKeepApplicationSingletonCreationBlocked
        this.didKeepArtifactWriteBlocked = didKeepArtifactWriteBlocked
        this.didKeepArtifactPublicationBlocked =
            didKeepArtifactPublicationBlocked
        this.didKeepPublicDiagnosticsBlocked =
            didKeepPublicDiagnosticsBlocked
        this.didKeepActualTeardownExecutionBlocked =
            didKeepActualTeardownExecutionBlocked
        this.didKeepActualEventLoopBlocked = didKeepActualEventLoopBlocked
        this.didKeepActualRunLoopPumpBlocked =
            didKeepActualRunLoopPumpBlocked
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
        this.didKeepActualAccessorSideEffectAuditValueOnly =
            didKeepActualAccessorSideEffectAuditValueOnly
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAudit {
    let actualAccessorSideEffectAuditFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditFacts
    let didAdmitNsApplicationSharedApplicationActualAccessorSideEffectAuditBoundary:
        Bool
    let shouldDeferNsApplicationSharedApplicationActualAccessorSideEffectAuditBoundary:
        Bool
    let shouldReportNsApplicationSharedApplicationActualAccessorSideEffectAuditBlocked:
        Bool
    let didConfirmActualAccessorSideEffectAuditRequired: Bool
    let didConfirmApplicationSingletonLifecycleSideEffectRiskClassified:
        Bool
    let didConfirmMainThreadAuditBeforeAccessorCallRequired: Bool
    let didConfirmHeadlessFailClosedAuditRequired: Bool
    let didConfirmTeardownBeforeVisibleAuditRequired: Bool
    let didConfirmArtifactDiagnosticsNonPublicationAuditRequired: Bool
    let didConfirmRollbackCleanupEvidenceBeforeAccessorCallRequired: Bool
    let didConfirmActualApplicationSingletonAccessorCallStillBlocked:
        Bool
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
    let didKeepNsApplicationSharedApplicationActualAccessorSideEffectAuditValueOnly:
        Bool

    init(
        actualAccessorSideEffectAuditFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditFacts,
        didAdmitNsApplicationSharedApplicationActualAccessorSideEffectAuditBoundary:
            Bool,
        shouldDeferNsApplicationSharedApplicationActualAccessorSideEffectAuditBoundary:
            Bool,
        shouldReportNsApplicationSharedApplicationActualAccessorSideEffectAuditBlocked:
            Bool,
        didConfirmActualAccessorSideEffectAuditRequired: Bool,
        didConfirmApplicationSingletonLifecycleSideEffectRiskClassified:
            Bool,
        didConfirmMainThreadAuditBeforeAccessorCallRequired: Bool,
        didConfirmHeadlessFailClosedAuditRequired: Bool,
        didConfirmTeardownBeforeVisibleAuditRequired: Bool,
        didConfirmArtifactDiagnosticsNonPublicationAuditRequired: Bool,
        didConfirmRollbackCleanupEvidenceBeforeAccessorCallRequired: Bool,
        didConfirmActualApplicationSingletonAccessorCallStillBlocked:
            Bool,
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
        didKeepNsApplicationSharedApplicationActualAccessorSideEffectAuditValueOnly:
            Bool
    ) {
        this.actualAccessorSideEffectAuditFacts =
            actualAccessorSideEffectAuditFacts
        this.didAdmitNsApplicationSharedApplicationActualAccessorSideEffectAuditBoundary =
            didAdmitNsApplicationSharedApplicationActualAccessorSideEffectAuditBoundary
        this.shouldDeferNsApplicationSharedApplicationActualAccessorSideEffectAuditBoundary =
            shouldDeferNsApplicationSharedApplicationActualAccessorSideEffectAuditBoundary
        this.shouldReportNsApplicationSharedApplicationActualAccessorSideEffectAuditBlocked =
            shouldReportNsApplicationSharedApplicationActualAccessorSideEffectAuditBlocked
        this.didConfirmActualAccessorSideEffectAuditRequired =
            didConfirmActualAccessorSideEffectAuditRequired
        this.didConfirmApplicationSingletonLifecycleSideEffectRiskClassified =
            didConfirmApplicationSingletonLifecycleSideEffectRiskClassified
        this.didConfirmMainThreadAuditBeforeAccessorCallRequired =
            didConfirmMainThreadAuditBeforeAccessorCallRequired
        this.didConfirmHeadlessFailClosedAuditRequired =
            didConfirmHeadlessFailClosedAuditRequired
        this.didConfirmTeardownBeforeVisibleAuditRequired =
            didConfirmTeardownBeforeVisibleAuditRequired
        this.didConfirmArtifactDiagnosticsNonPublicationAuditRequired =
            didConfirmArtifactDiagnosticsNonPublicationAuditRequired
        this.didConfirmRollbackCleanupEvidenceBeforeAccessorCallRequired =
            didConfirmRollbackCleanupEvidenceBeforeAccessorCallRequired
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
        this.didKeepNsApplicationSharedApplicationActualAccessorSideEffectAuditValueOnly =
            didKeepNsApplicationSharedApplicationActualAccessorSideEffectAuditValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness {
    let nsApplicationSharedApplicationSingletonAccessorAdmissionReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSingletonAccessorAdmissionReadiness
    let nsApplicationSharedApplicationActualAccessorSideEffectAudit:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAudit
    let didPrepareRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness:
        Bool
    let shouldDeferRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness:
        Bool
    let shouldReportRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditBlocked:
        Bool
    let didPreserveNsApplicationSharedApplicationSingletonAccessorAdmissionReadiness:
        Bool
    let didConfirmActualAccessorSideEffectAuditRequired: Bool
    let didConfirmApplicationSingletonLifecycleSideEffectRiskClassified:
        Bool
    let didConfirmMainThreadAuditBeforeAccessorCallRequired: Bool
    let didConfirmHeadlessFailClosedAuditRequired: Bool
    let didConfirmTeardownBeforeVisibleAuditRequired: Bool
    let didConfirmArtifactDiagnosticsNonPublicationAuditRequired: Bool
    let didConfirmRollbackCleanupEvidenceBeforeAccessorCallRequired: Bool
    let didConfirmActualApplicationSingletonAccessorCallStillBlocked:
        Bool
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
    let didKeepNsApplicationSharedApplicationActualAccessorSideEffectAuditReadinessDehydrated:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidAccessorReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidRenderReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        nsApplicationSharedApplicationSingletonAccessorAdmissionReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSingletonAccessorAdmissionReadiness,
        nsApplicationSharedApplicationActualAccessorSideEffectAudit:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAudit,
        didPrepareRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness:
            Bool,
        shouldDeferRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness:
            Bool,
        shouldReportRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditBlocked:
            Bool,
        didPreserveNsApplicationSharedApplicationSingletonAccessorAdmissionReadiness:
            Bool,
        didConfirmActualAccessorSideEffectAuditRequired: Bool,
        didConfirmApplicationSingletonLifecycleSideEffectRiskClassified:
            Bool,
        didConfirmMainThreadAuditBeforeAccessorCallRequired: Bool,
        didConfirmHeadlessFailClosedAuditRequired: Bool,
        didConfirmTeardownBeforeVisibleAuditRequired: Bool,
        didConfirmArtifactDiagnosticsNonPublicationAuditRequired: Bool,
        didConfirmRollbackCleanupEvidenceBeforeAccessorCallRequired: Bool,
        didConfirmActualApplicationSingletonAccessorCallStillBlocked:
            Bool,
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
        didKeepNsApplicationSharedApplicationActualAccessorSideEffectAuditReadinessDehydrated:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidAccessorReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidRenderReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.nsApplicationSharedApplicationSingletonAccessorAdmissionReadiness =
            nsApplicationSharedApplicationSingletonAccessorAdmissionReadiness
        this.nsApplicationSharedApplicationActualAccessorSideEffectAudit =
            nsApplicationSharedApplicationActualAccessorSideEffectAudit
        this.didPrepareRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness =
            didPrepareRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness
        this.shouldDeferRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness =
            shouldDeferRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness
        this.shouldReportRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditBlocked =
            shouldReportRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditBlocked
        this.didPreserveNsApplicationSharedApplicationSingletonAccessorAdmissionReadiness =
            didPreserveNsApplicationSharedApplicationSingletonAccessorAdmissionReadiness
        this.didConfirmActualAccessorSideEffectAuditRequired =
            didConfirmActualAccessorSideEffectAuditRequired
        this.didConfirmApplicationSingletonLifecycleSideEffectRiskClassified =
            didConfirmApplicationSingletonLifecycleSideEffectRiskClassified
        this.didConfirmMainThreadAuditBeforeAccessorCallRequired =
            didConfirmMainThreadAuditBeforeAccessorCallRequired
        this.didConfirmHeadlessFailClosedAuditRequired =
            didConfirmHeadlessFailClosedAuditRequired
        this.didConfirmTeardownBeforeVisibleAuditRequired =
            didConfirmTeardownBeforeVisibleAuditRequired
        this.didConfirmArtifactDiagnosticsNonPublicationAuditRequired =
            didConfirmArtifactDiagnosticsNonPublicationAuditRequired
        this.didConfirmRollbackCleanupEvidenceBeforeAccessorCallRequired =
            didConfirmRollbackCleanupEvidenceBeforeAccessorCallRequired
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
        this.didKeepNsApplicationSharedApplicationActualAccessorSideEffectAuditReadinessDehydrated =
            didKeepNsApplicationSharedApplicationActualAccessorSideEffectAuditReadinessDehydrated
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

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditFacts(
    singletonAccessorAdmissionReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSingletonAccessorAdmissionReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditFacts {
    let upstreamReady =
        singletonAccessorAdmissionReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationSingletonAccessorAdmissionReadiness &&
        singletonAccessorAdmissionReadiness
            .didConfirmFutureActualAccessorCallDecisionRequired &&
        singletonAccessorAdmissionReadiness
            .didConfirmNativeSideEffectAuditBeforeActualAccessorCallRequired &&
        singletonAccessorAdmissionReadiness
            .didConfirmActualApplicationSingletonAccessorCallStillBlocked &&
        singletonAccessorAdmissionReadiness
            .didConfirmNoApplicationSingletonAccessorCall &&
        singletonAccessorAdmissionReadiness
            .didConfirmApplicationSingletonCreationStillBlocked &&
        singletonAccessorAdmissionReadiness
            .didConfirmArtifactWriteStillBlocked &&
        singletonAccessorAdmissionReadiness
            .didConfirmArtifactPublicationStillBlocked &&
        singletonAccessorAdmissionReadiness
            .didConfirmPublicDiagnosticsStillBlocked &&
        singletonAccessorAdmissionReadiness
            .didConfirmActualTeardownExecutionStillBlocked &&
        singletonAccessorAdmissionReadiness
            .didConfirmActualEventLoopStillBlocked &&
        singletonAccessorAdmissionReadiness
            .didConfirmActualRunLoopPumpStillBlocked &&
        singletonAccessorAdmissionReadiness
            .didConfirmActivationPolicyMutationStillBlocked &&
        singletonAccessorAdmissionReadiness
            .didConfirmApplicationActivationStillBlocked &&
        singletonAccessorAdmissionReadiness
            .didConfirmNativeVisibleOrderStillBlocked &&
        singletonAccessorAdmissionReadiness
            .didConfirmProductionDrawableStillBlocked &&
        singletonAccessorAdmissionReadiness.didConfirmRenderStillBlocked &&
        singletonAccessorAdmissionReadiness
            .didConfirmNoApplicationCreationOrActivation &&
        singletonAccessorAdmissionReadiness
            .didConfirmNoPointerHandleClassIdReturn &&
        singletonAccessorAdmissionReadiness.didConfirmNoPublicSurface &&
        singletonAccessorAdmissionReadiness.didConfirmNoPublicCAbi &&
        singletonAccessorAdmissionReadiness.didConfirmNoRendererStateWrite &&
        singletonAccessorAdmissionReadiness.didConfirmNoBackendReadyTruth &&
        singletonAccessorAdmissionReadiness
            .didKeepNsApplicationSharedApplicationSingletonAccessorAdmissionReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditFacts(
        upstreamReady,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        singletonAccessorAdmissionReadiness
            .didConfirmActualApplicationSingletonAccessorCallStillBlocked,
        singletonAccessorAdmissionReadiness
            .didConfirmNoApplicationSingletonAccessorCall,
        singletonAccessorAdmissionReadiness
            .didConfirmApplicationSingletonCreationStillBlocked,
        singletonAccessorAdmissionReadiness.didConfirmArtifactWriteStillBlocked,
        singletonAccessorAdmissionReadiness
            .didConfirmArtifactPublicationStillBlocked,
        singletonAccessorAdmissionReadiness
            .didConfirmPublicDiagnosticsStillBlocked,
        singletonAccessorAdmissionReadiness
            .didConfirmActualTeardownExecutionStillBlocked,
        singletonAccessorAdmissionReadiness.didConfirmActualEventLoopStillBlocked,
        singletonAccessorAdmissionReadiness
            .didConfirmActualRunLoopPumpStillBlocked,
        singletonAccessorAdmissionReadiness
            .didConfirmActivationPolicyMutationStillBlocked,
        singletonAccessorAdmissionReadiness
            .didConfirmApplicationActivationStillBlocked,
        singletonAccessorAdmissionReadiness
            .didConfirmNativeVisibleOrderStillBlocked,
        singletonAccessorAdmissionReadiness
            .didConfirmProductionDrawableStillBlocked,
        singletonAccessorAdmissionReadiness.didConfirmRenderStillBlocked,
        singletonAccessorAdmissionReadiness
            .didConfirmNoApplicationCreationOrActivation,
        singletonAccessorAdmissionReadiness
            .didConfirmNoPointerHandleClassIdReturn,
        singletonAccessorAdmissionReadiness.didConfirmNoPublicSurface,
        singletonAccessorAdmissionReadiness.didConfirmNoPublicCAbi,
        singletonAccessorAdmissionReadiness.didConfirmNoRendererStateWrite,
        singletonAccessorAdmissionReadiness.didConfirmNoBackendReadyTruth,
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

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAudit(
    actualAccessorSideEffectAuditFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAudit {
    let admitted =
        actualAccessorSideEffectAuditFacts
            .didPreserveSingletonAccessorAdmissionReadiness &&
        actualAccessorSideEffectAuditFacts
            .didRequireActualAccessorSideEffectAudit &&
        actualAccessorSideEffectAuditFacts
            .didClassifyApplicationSingletonLifecycleSideEffectRisk &&
        actualAccessorSideEffectAuditFacts
            .didRequireMainThreadAuditBeforeAccessorCall &&
        actualAccessorSideEffectAuditFacts.didRequireHeadlessFailClosedAudit &&
        actualAccessorSideEffectAuditFacts
            .didRequireTeardownBeforeVisibleAudit &&
        actualAccessorSideEffectAuditFacts
            .didRequireArtifactDiagnosticsNonPublicationAudit &&
        actualAccessorSideEffectAuditFacts
            .didRequireRollbackCleanupEvidenceBeforeAccessorCall &&
        actualAccessorSideEffectAuditFacts
            .didKeepActualApplicationSingletonAccessorCallBlocked &&
        actualAccessorSideEffectAuditFacts
            .didKeepNoApplicationSingletonAccessorCall &&
        actualAccessorSideEffectAuditFacts
            .didKeepApplicationSingletonCreationBlocked &&
        actualAccessorSideEffectAuditFacts.didKeepArtifactWriteBlocked &&
        actualAccessorSideEffectAuditFacts
            .didKeepArtifactPublicationBlocked &&
        actualAccessorSideEffectAuditFacts.didKeepPublicDiagnosticsBlocked &&
        actualAccessorSideEffectAuditFacts
            .didKeepActualTeardownExecutionBlocked &&
        actualAccessorSideEffectAuditFacts.didKeepActualEventLoopBlocked &&
        actualAccessorSideEffectAuditFacts.didKeepActualRunLoopPumpBlocked &&
        actualAccessorSideEffectAuditFacts
            .didKeepActivationPolicyMutationBlocked &&
        actualAccessorSideEffectAuditFacts.didKeepApplicationActivationBlocked &&
        actualAccessorSideEffectAuditFacts.didConfirmNoPublicSurface &&
        actualAccessorSideEffectAuditFacts.didConfirmNoPublicCAbi &&
        actualAccessorSideEffectAuditFacts.didConfirmNoRendererStateWrite &&
        actualAccessorSideEffectAuditFacts.didConfirmNoBackendReadyTruth &&
        actualAccessorSideEffectAuditFacts
            .didKeepActualAccessorSideEffectAuditValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAudit(
        actualAccessorSideEffectAuditFacts,
        admitted,
        !admitted,
        !admitted,
        actualAccessorSideEffectAuditFacts
            .didRequireActualAccessorSideEffectAudit,
        actualAccessorSideEffectAuditFacts
            .didClassifyApplicationSingletonLifecycleSideEffectRisk,
        actualAccessorSideEffectAuditFacts
            .didRequireMainThreadAuditBeforeAccessorCall,
        actualAccessorSideEffectAuditFacts.didRequireHeadlessFailClosedAudit,
        actualAccessorSideEffectAuditFacts
            .didRequireTeardownBeforeVisibleAudit,
        actualAccessorSideEffectAuditFacts
            .didRequireArtifactDiagnosticsNonPublicationAudit,
        actualAccessorSideEffectAuditFacts
            .didRequireRollbackCleanupEvidenceBeforeAccessorCall,
        actualAccessorSideEffectAuditFacts
            .didKeepActualApplicationSingletonAccessorCallBlocked,
        actualAccessorSideEffectAuditFacts
            .didKeepNoApplicationSingletonAccessorCall,
        actualAccessorSideEffectAuditFacts
            .didKeepApplicationSingletonCreationBlocked,
        actualAccessorSideEffectAuditFacts.didKeepArtifactWriteBlocked,
        actualAccessorSideEffectAuditFacts
            .didKeepArtifactPublicationBlocked,
        actualAccessorSideEffectAuditFacts.didKeepPublicDiagnosticsBlocked,
        actualAccessorSideEffectAuditFacts
            .didKeepActualTeardownExecutionBlocked,
        actualAccessorSideEffectAuditFacts.didKeepActualEventLoopBlocked,
        actualAccessorSideEffectAuditFacts.didKeepActualRunLoopPumpBlocked,
        actualAccessorSideEffectAuditFacts
            .didKeepActivationPolicyMutationBlocked,
        actualAccessorSideEffectAuditFacts.didKeepApplicationActivationBlocked,
        actualAccessorSideEffectAuditFacts
            .didKeepActualAccessorSideEffectAuditValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness(
    singletonAccessorAdmissionReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSingletonAccessorAdmissionReadiness,
    actualAccessorSideEffectAudit:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAudit
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness {
    let admitted =
        actualAccessorSideEffectAudit
            .didAdmitNsApplicationSharedApplicationActualAccessorSideEffectAuditBoundary
    let actualAccessorSideEffectAuditFacts =
        actualAccessorSideEffectAudit.actualAccessorSideEffectAuditFacts

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness(
        singletonAccessorAdmissionReadiness,
        actualAccessorSideEffectAudit,
        admitted,
        !admitted,
        !admitted,
        actualAccessorSideEffectAuditFacts
            .didPreserveSingletonAccessorAdmissionReadiness,
        actualAccessorSideEffectAudit
            .didConfirmActualAccessorSideEffectAuditRequired,
        actualAccessorSideEffectAudit
            .didConfirmApplicationSingletonLifecycleSideEffectRiskClassified,
        actualAccessorSideEffectAudit
            .didConfirmMainThreadAuditBeforeAccessorCallRequired,
        actualAccessorSideEffectAudit
            .didConfirmHeadlessFailClosedAuditRequired,
        actualAccessorSideEffectAudit
            .didConfirmTeardownBeforeVisibleAuditRequired,
        actualAccessorSideEffectAudit
            .didConfirmArtifactDiagnosticsNonPublicationAuditRequired,
        actualAccessorSideEffectAudit
            .didConfirmRollbackCleanupEvidenceBeforeAccessorCallRequired,
        actualAccessorSideEffectAudit
            .didConfirmActualApplicationSingletonAccessorCallStillBlocked,
        actualAccessorSideEffectAudit
            .didConfirmNoApplicationSingletonAccessorCall,
        actualAccessorSideEffectAudit
            .didConfirmApplicationSingletonCreationStillBlocked,
        actualAccessorSideEffectAudit.didConfirmArtifactWriteStillBlocked,
        actualAccessorSideEffectAudit.didConfirmArtifactPublicationStillBlocked,
        actualAccessorSideEffectAudit.didConfirmPublicDiagnosticsStillBlocked,
        actualAccessorSideEffectAudit
            .didConfirmActualTeardownExecutionStillBlocked,
        actualAccessorSideEffectAudit.didConfirmActualEventLoopStillBlocked,
        actualAccessorSideEffectAudit.didConfirmActualRunLoopPumpStillBlocked,
        actualAccessorSideEffectAudit
            .didConfirmActivationPolicyMutationStillBlocked,
        actualAccessorSideEffectAudit.didConfirmApplicationActivationStillBlocked,
        actualAccessorSideEffectAuditFacts
            .didKeepNativeVisibleOrderImplementationBlocked,
        actualAccessorSideEffectAuditFacts
            .didKeepProductionDrawablePermissionBlocked,
        actualAccessorSideEffectAuditFacts.didKeepRenderPermissionBlocked,
        actualAccessorSideEffectAuditFacts
            .didConfirmNoApplicationCreationOrActivation,
        actualAccessorSideEffectAuditFacts
            .didConfirmNoPointerHandleClassIdReturn,
        actualAccessorSideEffectAuditFacts.didConfirmNoPublicSurface,
        actualAccessorSideEffectAuditFacts.didConfirmNoPublicCAbi,
        actualAccessorSideEffectAuditFacts.didConfirmNoRendererStateWrite,
        actualAccessorSideEffectAuditFacts.didConfirmNoBackendReadyTruth,
        actualAccessorSideEffectAudit
            .didKeepNsApplicationSharedApplicationActualAccessorSideEffectAuditValueOnly,
        actualAccessorSideEffectAuditFacts.didAvoidApplicationReadyWrapper,
        actualAccessorSideEffectAuditFacts.didAvoidAccessorReadyWrapper,
        actualAccessorSideEffectAuditFacts.didAvoidVisibleReadyWrapper,
        actualAccessorSideEffectAuditFacts.didAvoidDrawableReadyWrapper,
        actualAccessorSideEffectAuditFacts.didAvoidRenderReadyWrapper,
        actualAccessorSideEffectAuditFacts.didAvoidBackendReadyWrapper,
        actualAccessorSideEffectAuditFacts.didAvoidReceiptRecordPublication
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness {
    let singletonAccessorAdmissionReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationSingletonAccessorAdmissionDraft()
    let actualAccessorSideEffectAuditFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditFacts(
            singletonAccessorAdmissionReadiness
        )
    let actualAccessorSideEffectAudit =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAudit(
            actualAccessorSideEffectAuditFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness(
        singletonAccessorAdmissionReadiness,
        actualAccessorSideEffectAudit
    )
}
