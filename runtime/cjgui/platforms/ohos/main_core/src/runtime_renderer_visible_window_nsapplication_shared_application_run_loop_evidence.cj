// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application run-loop execution evidence value boundary owner。
// Owner: runtime renderer internal NSApplication shared-application run-loop
// evidence owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness，
// 固定 run-loop execution、bounded owner、stop condition、auto-close 与
// main-thread affinity 仍是后续 visible-window harness 的 internal evidence
// facts。
// Stop-line: 不运行 AppKit event loop，不实现 bounded pump，不调用
// application singleton accessor，不创建 NSApplication，不 activation，不修改
// activation policy，不做 native visible order implementation，不获取 drawable，
// 不创建 encoder，不 draw，不提交 GPU work，不执行 render，不返回 Class / id /
// pointer / handle，不写 runtime_state.cj，不扩 public API，不新增 native bridge
// C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 event-loop-ready、
// visible-ready、drawable-ready、render-ready、backend-ready、renderer state
// write、receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceFacts {
    let didPreserveLifecycleEvidenceReadiness: Bool
    let didKeepRunLoopExecutionEvidenceRequired: Bool
    let didRequireBoundedRunLoopOwnerEvidence: Bool
    let didRequireStopConditionEvidence: Bool
    let didRequireAutoCloseEvidenceBeforeVisibleMode: Bool
    let didRequireMainThreadRunLoopAffinityEvidence: Bool
    let didKeepActualEventLoopBlocked: Bool
    let didKeepActualRunLoopPumpBlocked: Bool
    let didKeepLifecycleOwnerEvidenceRequired: Bool
    let didKeepApplicationSingletonOwnershipEvidenceRequired: Bool
    let didKeepTeardownOrderingEvidenceRequired: Bool
    let didKeepHeadlessArtifactPolicyEvidenceOnly: Bool
    let didKeepSideEffectContainmentEvidenceRequired: Bool
    let didKeepActualApplicationSingletonAccessorCallBlocked: Bool
    let didKeepNoApplicationSingletonAccessorCall: Bool
    let didKeepApplicationSingletonCreationBlocked: Bool
    let didKeepApplicationSideEffectBlocked: Bool
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
    let didKeepRunLoopEvidenceFactsValueOnly: Bool

    init(
        didPreserveLifecycleEvidenceReadiness: Bool,
        didKeepRunLoopExecutionEvidenceRequired: Bool,
        didRequireBoundedRunLoopOwnerEvidence: Bool,
        didRequireStopConditionEvidence: Bool,
        didRequireAutoCloseEvidenceBeforeVisibleMode: Bool,
        didRequireMainThreadRunLoopAffinityEvidence: Bool,
        didKeepActualEventLoopBlocked: Bool,
        didKeepActualRunLoopPumpBlocked: Bool,
        didKeepLifecycleOwnerEvidenceRequired: Bool,
        didKeepApplicationSingletonOwnershipEvidenceRequired: Bool,
        didKeepTeardownOrderingEvidenceRequired: Bool,
        didKeepHeadlessArtifactPolicyEvidenceOnly: Bool,
        didKeepSideEffectContainmentEvidenceRequired: Bool,
        didKeepActualApplicationSingletonAccessorCallBlocked: Bool,
        didKeepNoApplicationSingletonAccessorCall: Bool,
        didKeepApplicationSingletonCreationBlocked: Bool,
        didKeepApplicationSideEffectBlocked: Bool,
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
        didKeepRunLoopEvidenceFactsValueOnly: Bool
    ) {
        this.didPreserveLifecycleEvidenceReadiness =
            didPreserveLifecycleEvidenceReadiness
        this.didKeepRunLoopExecutionEvidenceRequired =
            didKeepRunLoopExecutionEvidenceRequired
        this.didRequireBoundedRunLoopOwnerEvidence =
            didRequireBoundedRunLoopOwnerEvidence
        this.didRequireStopConditionEvidence = didRequireStopConditionEvidence
        this.didRequireAutoCloseEvidenceBeforeVisibleMode =
            didRequireAutoCloseEvidenceBeforeVisibleMode
        this.didRequireMainThreadRunLoopAffinityEvidence =
            didRequireMainThreadRunLoopAffinityEvidence
        this.didKeepActualEventLoopBlocked = didKeepActualEventLoopBlocked
        this.didKeepActualRunLoopPumpBlocked = didKeepActualRunLoopPumpBlocked
        this.didKeepLifecycleOwnerEvidenceRequired =
            didKeepLifecycleOwnerEvidenceRequired
        this.didKeepApplicationSingletonOwnershipEvidenceRequired =
            didKeepApplicationSingletonOwnershipEvidenceRequired
        this.didKeepTeardownOrderingEvidenceRequired =
            didKeepTeardownOrderingEvidenceRequired
        this.didKeepHeadlessArtifactPolicyEvidenceOnly =
            didKeepHeadlessArtifactPolicyEvidenceOnly
        this.didKeepSideEffectContainmentEvidenceRequired =
            didKeepSideEffectContainmentEvidenceRequired
        this.didKeepActualApplicationSingletonAccessorCallBlocked =
            didKeepActualApplicationSingletonAccessorCallBlocked
        this.didKeepNoApplicationSingletonAccessorCall =
            didKeepNoApplicationSingletonAccessorCall
        this.didKeepApplicationSingletonCreationBlocked =
            didKeepApplicationSingletonCreationBlocked
        this.didKeepApplicationSideEffectBlocked =
            didKeepApplicationSideEffectBlocked
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
        this.didKeepRunLoopEvidenceFactsValueOnly =
            didKeepRunLoopEvidenceFactsValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceAdmission {
    let runLoopEvidenceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceFacts
    let didAdmitNsApplicationSharedApplicationRunLoopEvidenceBoundary:
        Bool
    let shouldDeferNsApplicationSharedApplicationRunLoopEvidenceBoundary:
        Bool
    let shouldReportNsApplicationSharedApplicationRunLoopEvidenceBlocked:
        Bool
    let didConfirmRunLoopExecutionEvidenceStillRequired: Bool
    let didConfirmBoundedRunLoopOwnerEvidenceRequired: Bool
    let didConfirmStopConditionEvidenceRequired: Bool
    let didConfirmAutoCloseEvidenceBeforeVisibleModeRequired: Bool
    let didConfirmMainThreadRunLoopAffinityEvidenceRequired: Bool
    let didConfirmActualEventLoopStillBlocked: Bool
    let didConfirmActualRunLoopPumpStillBlocked: Bool
    let didConfirmActualApplicationSingletonAccessorCallStillBlocked: Bool
    let didKeepNsApplicationSharedApplicationRunLoopEvidenceValueOnly: Bool

    init(
        runLoopEvidenceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceFacts,
        didAdmitNsApplicationSharedApplicationRunLoopEvidenceBoundary:
            Bool,
        shouldDeferNsApplicationSharedApplicationRunLoopEvidenceBoundary:
            Bool,
        shouldReportNsApplicationSharedApplicationRunLoopEvidenceBlocked:
            Bool,
        didConfirmRunLoopExecutionEvidenceStillRequired: Bool,
        didConfirmBoundedRunLoopOwnerEvidenceRequired: Bool,
        didConfirmStopConditionEvidenceRequired: Bool,
        didConfirmAutoCloseEvidenceBeforeVisibleModeRequired: Bool,
        didConfirmMainThreadRunLoopAffinityEvidenceRequired: Bool,
        didConfirmActualEventLoopStillBlocked: Bool,
        didConfirmActualRunLoopPumpStillBlocked: Bool,
        didConfirmActualApplicationSingletonAccessorCallStillBlocked: Bool,
        didKeepNsApplicationSharedApplicationRunLoopEvidenceValueOnly: Bool
    ) {
        this.runLoopEvidenceFacts = runLoopEvidenceFacts
        this.didAdmitNsApplicationSharedApplicationRunLoopEvidenceBoundary =
            didAdmitNsApplicationSharedApplicationRunLoopEvidenceBoundary
        this.shouldDeferNsApplicationSharedApplicationRunLoopEvidenceBoundary =
            shouldDeferNsApplicationSharedApplicationRunLoopEvidenceBoundary
        this.shouldReportNsApplicationSharedApplicationRunLoopEvidenceBlocked =
            shouldReportNsApplicationSharedApplicationRunLoopEvidenceBlocked
        this.didConfirmRunLoopExecutionEvidenceStillRequired =
            didConfirmRunLoopExecutionEvidenceStillRequired
        this.didConfirmBoundedRunLoopOwnerEvidenceRequired =
            didConfirmBoundedRunLoopOwnerEvidenceRequired
        this.didConfirmStopConditionEvidenceRequired =
            didConfirmStopConditionEvidenceRequired
        this.didConfirmAutoCloseEvidenceBeforeVisibleModeRequired =
            didConfirmAutoCloseEvidenceBeforeVisibleModeRequired
        this.didConfirmMainThreadRunLoopAffinityEvidenceRequired =
            didConfirmMainThreadRunLoopAffinityEvidenceRequired
        this.didConfirmActualEventLoopStillBlocked =
            didConfirmActualEventLoopStillBlocked
        this.didConfirmActualRunLoopPumpStillBlocked =
            didConfirmActualRunLoopPumpStillBlocked
        this.didConfirmActualApplicationSingletonAccessorCallStillBlocked =
            didConfirmActualApplicationSingletonAccessorCallStillBlocked
        this.didKeepNsApplicationSharedApplicationRunLoopEvidenceValueOnly =
            didKeepNsApplicationSharedApplicationRunLoopEvidenceValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness {
    let nsApplicationSharedApplicationLifecycleEvidenceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness
    let nsApplicationSharedApplicationRunLoopEvidenceAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceAdmission
    let didPrepareRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness:
        Bool
    let shouldDeferRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness:
        Bool
    let shouldReportRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceBlocked:
        Bool
    let didPreserveNsApplicationSharedApplicationLifecycleEvidenceReadiness:
        Bool
    let didConfirmRunLoopExecutionEvidenceStillRequired: Bool
    let didConfirmBoundedRunLoopOwnerEvidenceRequired: Bool
    let didConfirmStopConditionEvidenceRequired: Bool
    let didConfirmAutoCloseEvidenceBeforeVisibleModeRequired: Bool
    let didConfirmMainThreadRunLoopAffinityEvidenceRequired: Bool
    let didConfirmActualEventLoopStillBlocked: Bool
    let didConfirmActualRunLoopPumpStillBlocked: Bool
    let didConfirmLifecycleOwnerEvidenceStillRequired: Bool
    let didConfirmApplicationSingletonOwnershipEvidenceStillRequired: Bool
    let didConfirmTeardownOrderingEvidenceStillRequired: Bool
    let didConfirmHeadlessArtifactPolicyEvidenceOnly: Bool
    let didConfirmSideEffectContainmentEvidenceStillRequired: Bool
    let didConfirmActualApplicationSingletonAccessorCallStillBlocked: Bool
    let didConfirmNoApplicationSingletonAccessorCall: Bool
    let didConfirmApplicationSingletonCreationStillBlocked: Bool
    let didConfirmApplicationSideEffectStillBlocked: Bool
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
    let didKeepNsApplicationSharedApplicationRunLoopEvidenceReadinessDehydrated:
        Bool
    let didAvoidEventLoopReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        nsApplicationSharedApplicationLifecycleEvidenceReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness,
        nsApplicationSharedApplicationRunLoopEvidenceAdmission:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceAdmission,
        didPrepareRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness:
            Bool,
        shouldDeferRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness:
            Bool,
        shouldReportRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceBlocked:
            Bool,
        didPreserveNsApplicationSharedApplicationLifecycleEvidenceReadiness:
            Bool,
        didConfirmRunLoopExecutionEvidenceStillRequired: Bool,
        didConfirmBoundedRunLoopOwnerEvidenceRequired: Bool,
        didConfirmStopConditionEvidenceRequired: Bool,
        didConfirmAutoCloseEvidenceBeforeVisibleModeRequired: Bool,
        didConfirmMainThreadRunLoopAffinityEvidenceRequired: Bool,
        didConfirmActualEventLoopStillBlocked: Bool,
        didConfirmActualRunLoopPumpStillBlocked: Bool,
        didConfirmLifecycleOwnerEvidenceStillRequired: Bool,
        didConfirmApplicationSingletonOwnershipEvidenceStillRequired: Bool,
        didConfirmTeardownOrderingEvidenceStillRequired: Bool,
        didConfirmHeadlessArtifactPolicyEvidenceOnly: Bool,
        didConfirmSideEffectContainmentEvidenceStillRequired: Bool,
        didConfirmActualApplicationSingletonAccessorCallStillBlocked: Bool,
        didConfirmNoApplicationSingletonAccessorCall: Bool,
        didConfirmApplicationSingletonCreationStillBlocked: Bool,
        didConfirmApplicationSideEffectStillBlocked: Bool,
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
        didKeepNsApplicationSharedApplicationRunLoopEvidenceReadinessDehydrated:
            Bool,
        didAvoidEventLoopReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.nsApplicationSharedApplicationLifecycleEvidenceReadiness =
            nsApplicationSharedApplicationLifecycleEvidenceReadiness
        this.nsApplicationSharedApplicationRunLoopEvidenceAdmission =
            nsApplicationSharedApplicationRunLoopEvidenceAdmission
        this.didPrepareRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness =
            didPrepareRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness
        this.shouldDeferRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness =
            shouldDeferRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness
        this.shouldReportRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceBlocked =
            shouldReportRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceBlocked
        this.didPreserveNsApplicationSharedApplicationLifecycleEvidenceReadiness =
            didPreserveNsApplicationSharedApplicationLifecycleEvidenceReadiness
        this.didConfirmRunLoopExecutionEvidenceStillRequired =
            didConfirmRunLoopExecutionEvidenceStillRequired
        this.didConfirmBoundedRunLoopOwnerEvidenceRequired =
            didConfirmBoundedRunLoopOwnerEvidenceRequired
        this.didConfirmStopConditionEvidenceRequired =
            didConfirmStopConditionEvidenceRequired
        this.didConfirmAutoCloseEvidenceBeforeVisibleModeRequired =
            didConfirmAutoCloseEvidenceBeforeVisibleModeRequired
        this.didConfirmMainThreadRunLoopAffinityEvidenceRequired =
            didConfirmMainThreadRunLoopAffinityEvidenceRequired
        this.didConfirmActualEventLoopStillBlocked =
            didConfirmActualEventLoopStillBlocked
        this.didConfirmActualRunLoopPumpStillBlocked =
            didConfirmActualRunLoopPumpStillBlocked
        this.didConfirmLifecycleOwnerEvidenceStillRequired =
            didConfirmLifecycleOwnerEvidenceStillRequired
        this.didConfirmApplicationSingletonOwnershipEvidenceStillRequired =
            didConfirmApplicationSingletonOwnershipEvidenceStillRequired
        this.didConfirmTeardownOrderingEvidenceStillRequired =
            didConfirmTeardownOrderingEvidenceStillRequired
        this.didConfirmHeadlessArtifactPolicyEvidenceOnly =
            didConfirmHeadlessArtifactPolicyEvidenceOnly
        this.didConfirmSideEffectContainmentEvidenceStillRequired =
            didConfirmSideEffectContainmentEvidenceStillRequired
        this.didConfirmActualApplicationSingletonAccessorCallStillBlocked =
            didConfirmActualApplicationSingletonAccessorCallStillBlocked
        this.didConfirmNoApplicationSingletonAccessorCall =
            didConfirmNoApplicationSingletonAccessorCall
        this.didConfirmApplicationSingletonCreationStillBlocked =
            didConfirmApplicationSingletonCreationStillBlocked
        this.didConfirmApplicationSideEffectStillBlocked =
            didConfirmApplicationSideEffectStillBlocked
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
        this.didKeepNsApplicationSharedApplicationRunLoopEvidenceReadinessDehydrated =
            didKeepNsApplicationSharedApplicationRunLoopEvidenceReadinessDehydrated
        this.didAvoidEventLoopReadyWrapper = didAvoidEventLoopReadyWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceFacts(
    lifecycleReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceFacts {
    let upstreamReady =
        lifecycleReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness &&
        lifecycleReadiness.didConfirmLifecycleOwnerEvidenceRequired &&
        lifecycleReadiness.didConfirmApplicationSingletonOwnershipEvidenceRequired &&
        lifecycleReadiness.didConfirmRunLoopExecutionEvidenceStillRequired &&
        lifecycleReadiness.didConfirmTeardownOrderingEvidenceStillRequired &&
        lifecycleReadiness.didConfirmHeadlessArtifactPolicyEvidenceOnly &&
        lifecycleReadiness.didConfirmSideEffectContainmentEvidenceStillRequired &&
        lifecycleReadiness.didConfirmActualApplicationSingletonAccessorCallStillBlocked &&
        lifecycleReadiness.didConfirmNoApplicationSingletonAccessorCall &&
        lifecycleReadiness.didConfirmApplicationSingletonCreationStillBlocked &&
        lifecycleReadiness.didConfirmApplicationSideEffectStillBlocked &&
        lifecycleReadiness.didConfirmActivationPolicyMutationStillBlocked &&
        lifecycleReadiness.didConfirmApplicationActivationStillBlocked &&
        lifecycleReadiness.didConfirmEventLoopStillBlocked &&
        lifecycleReadiness.didConfirmNativeVisibleOrderStillBlocked &&
        lifecycleReadiness.didConfirmProductionDrawableStillBlocked &&
        lifecycleReadiness.didConfirmRenderStillBlocked &&
        lifecycleReadiness.didConfirmNoApplicationCreationOrActivation &&
        lifecycleReadiness.didConfirmNoPointerHandleClassIdReturn &&
        lifecycleReadiness.didConfirmNoPublicSurface &&
        lifecycleReadiness.didConfirmNoPublicCAbi &&
        lifecycleReadiness.didConfirmNoRendererStateWrite &&
        lifecycleReadiness.didConfirmNoBackendReadyTruth &&
        lifecycleReadiness
            .didKeepNsApplicationSharedApplicationLifecycleEvidenceReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceFacts(
        upstreamReady,
        lifecycleReadiness.didConfirmRunLoopExecutionEvidenceStillRequired,
        true,
        true,
        true,
        true,
        lifecycleReadiness.didConfirmEventLoopStillBlocked,
        true,
        lifecycleReadiness.didConfirmLifecycleOwnerEvidenceRequired,
        lifecycleReadiness
            .didConfirmApplicationSingletonOwnershipEvidenceRequired,
        lifecycleReadiness.didConfirmTeardownOrderingEvidenceStillRequired,
        lifecycleReadiness.didConfirmHeadlessArtifactPolicyEvidenceOnly,
        lifecycleReadiness.didConfirmSideEffectContainmentEvidenceStillRequired,
        lifecycleReadiness.didConfirmActualApplicationSingletonAccessorCallStillBlocked,
        lifecycleReadiness.didConfirmNoApplicationSingletonAccessorCall,
        lifecycleReadiness.didConfirmApplicationSingletonCreationStillBlocked,
        lifecycleReadiness.didConfirmApplicationSideEffectStillBlocked,
        lifecycleReadiness.didConfirmActivationPolicyMutationStillBlocked,
        lifecycleReadiness.didConfirmApplicationActivationStillBlocked,
        lifecycleReadiness.didConfirmNativeVisibleOrderStillBlocked,
        lifecycleReadiness.didConfirmProductionDrawableStillBlocked,
        lifecycleReadiness.didConfirmRenderStillBlocked,
        lifecycleReadiness.didConfirmNoApplicationCreationOrActivation,
        lifecycleReadiness.didConfirmNoPointerHandleClassIdReturn,
        lifecycleReadiness.didConfirmNoPublicSurface,
        lifecycleReadiness.didConfirmNoPublicCAbi,
        lifecycleReadiness.didConfirmNoRendererStateWrite,
        lifecycleReadiness.didConfirmNoBackendReadyTruth,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceAdmission(
    runLoopEvidenceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceAdmission {
    let admitted =
        runLoopEvidenceFacts.didPreserveLifecycleEvidenceReadiness &&
        runLoopEvidenceFacts.didKeepRunLoopExecutionEvidenceRequired &&
        runLoopEvidenceFacts.didRequireBoundedRunLoopOwnerEvidence &&
        runLoopEvidenceFacts.didRequireStopConditionEvidence &&
        runLoopEvidenceFacts.didRequireAutoCloseEvidenceBeforeVisibleMode &&
        runLoopEvidenceFacts.didRequireMainThreadRunLoopAffinityEvidence &&
        runLoopEvidenceFacts.didKeepActualEventLoopBlocked &&
        runLoopEvidenceFacts.didKeepActualRunLoopPumpBlocked &&
        runLoopEvidenceFacts.didKeepLifecycleOwnerEvidenceRequired &&
        runLoopEvidenceFacts.didKeepApplicationSingletonOwnershipEvidenceRequired &&
        runLoopEvidenceFacts.didKeepTeardownOrderingEvidenceRequired &&
        runLoopEvidenceFacts.didKeepHeadlessArtifactPolicyEvidenceOnly &&
        runLoopEvidenceFacts.didKeepSideEffectContainmentEvidenceRequired &&
        runLoopEvidenceFacts.didKeepActualApplicationSingletonAccessorCallBlocked &&
        runLoopEvidenceFacts.didKeepNoApplicationSingletonAccessorCall &&
        runLoopEvidenceFacts.didKeepApplicationSingletonCreationBlocked &&
        runLoopEvidenceFacts.didKeepApplicationSideEffectBlocked &&
        runLoopEvidenceFacts.didKeepActivationPolicyMutationBlocked &&
        runLoopEvidenceFacts.didKeepApplicationActivationBlocked &&
        runLoopEvidenceFacts.didKeepNativeVisibleOrderImplementationBlocked &&
        runLoopEvidenceFacts.didKeepProductionDrawablePermissionBlocked &&
        runLoopEvidenceFacts.didKeepRenderPermissionBlocked &&
        runLoopEvidenceFacts.didConfirmNoApplicationCreationOrActivation &&
        runLoopEvidenceFacts.didConfirmNoPointerHandleClassIdReturn &&
        runLoopEvidenceFacts.didConfirmNoPublicSurface &&
        runLoopEvidenceFacts.didConfirmNoPublicCAbi &&
        runLoopEvidenceFacts.didConfirmNoRendererStateWrite &&
        runLoopEvidenceFacts.didConfirmNoBackendReadyTruth &&
        runLoopEvidenceFacts.didKeepRunLoopEvidenceFactsValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceAdmission(
        runLoopEvidenceFacts,
        admitted,
        !admitted,
        !admitted,
        runLoopEvidenceFacts.didKeepRunLoopExecutionEvidenceRequired,
        runLoopEvidenceFacts.didRequireBoundedRunLoopOwnerEvidence,
        runLoopEvidenceFacts.didRequireStopConditionEvidence,
        runLoopEvidenceFacts.didRequireAutoCloseEvidenceBeforeVisibleMode,
        runLoopEvidenceFacts.didRequireMainThreadRunLoopAffinityEvidence,
        runLoopEvidenceFacts.didKeepActualEventLoopBlocked,
        runLoopEvidenceFacts.didKeepActualRunLoopPumpBlocked,
        runLoopEvidenceFacts.didKeepActualApplicationSingletonAccessorCallBlocked,
        runLoopEvidenceFacts.didKeepRunLoopEvidenceFactsValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness(
    lifecycleReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness,
    runLoopEvidenceAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceAdmission
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness {
    let admitted =
        runLoopEvidenceAdmission
            .didAdmitNsApplicationSharedApplicationRunLoopEvidenceBoundary
    let runLoopEvidenceFacts =
        runLoopEvidenceAdmission.runLoopEvidenceFacts

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness(
        lifecycleReadiness,
        runLoopEvidenceAdmission,
        admitted,
        !admitted,
        !admitted,
        runLoopEvidenceFacts.didPreserveLifecycleEvidenceReadiness,
        runLoopEvidenceAdmission.didConfirmRunLoopExecutionEvidenceStillRequired,
        runLoopEvidenceAdmission.didConfirmBoundedRunLoopOwnerEvidenceRequired,
        runLoopEvidenceAdmission.didConfirmStopConditionEvidenceRequired,
        runLoopEvidenceAdmission
            .didConfirmAutoCloseEvidenceBeforeVisibleModeRequired,
        runLoopEvidenceAdmission
            .didConfirmMainThreadRunLoopAffinityEvidenceRequired,
        runLoopEvidenceAdmission.didConfirmActualEventLoopStillBlocked,
        runLoopEvidenceAdmission.didConfirmActualRunLoopPumpStillBlocked,
        runLoopEvidenceFacts.didKeepLifecycleOwnerEvidenceRequired,
        runLoopEvidenceFacts
            .didKeepApplicationSingletonOwnershipEvidenceRequired,
        runLoopEvidenceFacts.didKeepTeardownOrderingEvidenceRequired,
        runLoopEvidenceFacts.didKeepHeadlessArtifactPolicyEvidenceOnly,
        runLoopEvidenceFacts.didKeepSideEffectContainmentEvidenceRequired,
        runLoopEvidenceAdmission
            .didConfirmActualApplicationSingletonAccessorCallStillBlocked,
        runLoopEvidenceFacts.didKeepNoApplicationSingletonAccessorCall,
        runLoopEvidenceFacts.didKeepApplicationSingletonCreationBlocked,
        runLoopEvidenceFacts.didKeepApplicationSideEffectBlocked,
        runLoopEvidenceFacts.didKeepActivationPolicyMutationBlocked,
        runLoopEvidenceFacts.didKeepApplicationActivationBlocked,
        runLoopEvidenceFacts.didKeepNativeVisibleOrderImplementationBlocked,
        runLoopEvidenceFacts.didKeepProductionDrawablePermissionBlocked,
        runLoopEvidenceFacts.didKeepRenderPermissionBlocked,
        runLoopEvidenceFacts.didConfirmNoApplicationCreationOrActivation,
        runLoopEvidenceFacts.didConfirmNoPointerHandleClassIdReturn,
        runLoopEvidenceFacts.didConfirmNoPublicSurface,
        runLoopEvidenceFacts.didConfirmNoPublicCAbi,
        runLoopEvidenceFacts.didConfirmNoRendererStateWrite,
        runLoopEvidenceFacts.didConfirmNoBackendReadyTruth,
        runLoopEvidenceAdmission
            .didKeepNsApplicationSharedApplicationRunLoopEvidenceValueOnly,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness {
    let lifecycleReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceDraft()
    let runLoopEvidenceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceFacts(
            lifecycleReadiness
        )
    let runLoopEvidenceAdmission =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceAdmission(
            runLoopEvidenceFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness(
        lifecycleReadiness,
        runLoopEvidenceAdmission
    )
}
