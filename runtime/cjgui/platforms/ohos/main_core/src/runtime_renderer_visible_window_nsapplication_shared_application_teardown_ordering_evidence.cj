// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application teardown ordering evidence value boundary owner。
// Owner: runtime renderer internal NSApplication shared-application teardown
// ordering evidence owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness，
// 固定 teardown ordering、teardown-before-visible、bounded owner shutdown、
// stop-condition-before-teardown、auto-close cleanup 与 fail-closed teardown
// route 仍是后续 visible-window harness 的 internal evidence facts。
// Stop-line: 不执行真实 teardown，不运行 AppKit event loop，不实现 bounded pump，
// 不调用 application singleton accessor，不创建 NSApplication，不 activation，不修改
// activation policy，不做 native visible order implementation，不获取 drawable，
// 不创建 encoder，不 draw，不提交 GPU work，不执行 render，不返回 Class / id /
// pointer / handle，不写 runtime_state.cj，不扩 public API，不新增 native bridge
// C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 teardown-ready、
// event-loop-ready、visible-ready、drawable-ready、render-ready、backend-ready、
// renderer state write、receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceFacts {
    let didPreserveRunLoopEvidenceReadiness: Bool
    let didKeepTeardownOrderingEvidenceRequired: Bool
    let didRequireTeardownBeforeVisibleEvidence: Bool
    let didRequireBoundedOwnerShutdownEvidence: Bool
    let didRequireStopConditionBeforeTeardownEvidence: Bool
    let didRequireAutoCloseCleanupEvidence: Bool
    let didRequireFailClosedTeardownRoute: Bool
    let didKeepActualTeardownExecutionBlocked: Bool
    let didKeepRunLoopExecutionEvidenceRequired: Bool
    let didKeepBoundedRunLoopOwnerEvidenceRequired: Bool
    let didKeepStopConditionEvidenceRequired: Bool
    let didKeepAutoCloseEvidenceBeforeVisibleModeRequired: Bool
    let didKeepMainThreadRunLoopAffinityEvidenceRequired: Bool
    let didKeepActualEventLoopBlocked: Bool
    let didKeepActualRunLoopPumpBlocked: Bool
    let didKeepLifecycleOwnerEvidenceRequired: Bool
    let didKeepApplicationSingletonOwnershipEvidenceRequired: Bool
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
    let didKeepTeardownOrderingEvidenceFactsValueOnly: Bool

    init(
        didPreserveRunLoopEvidenceReadiness: Bool,
        didKeepTeardownOrderingEvidenceRequired: Bool,
        didRequireTeardownBeforeVisibleEvidence: Bool,
        didRequireBoundedOwnerShutdownEvidence: Bool,
        didRequireStopConditionBeforeTeardownEvidence: Bool,
        didRequireAutoCloseCleanupEvidence: Bool,
        didRequireFailClosedTeardownRoute: Bool,
        didKeepActualTeardownExecutionBlocked: Bool,
        didKeepRunLoopExecutionEvidenceRequired: Bool,
        didKeepBoundedRunLoopOwnerEvidenceRequired: Bool,
        didKeepStopConditionEvidenceRequired: Bool,
        didKeepAutoCloseEvidenceBeforeVisibleModeRequired: Bool,
        didKeepMainThreadRunLoopAffinityEvidenceRequired: Bool,
        didKeepActualEventLoopBlocked: Bool,
        didKeepActualRunLoopPumpBlocked: Bool,
        didKeepLifecycleOwnerEvidenceRequired: Bool,
        didKeepApplicationSingletonOwnershipEvidenceRequired: Bool,
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
        didKeepTeardownOrderingEvidenceFactsValueOnly: Bool
    ) {
        this.didPreserveRunLoopEvidenceReadiness =
            didPreserveRunLoopEvidenceReadiness
        this.didKeepTeardownOrderingEvidenceRequired =
            didKeepTeardownOrderingEvidenceRequired
        this.didRequireTeardownBeforeVisibleEvidence =
            didRequireTeardownBeforeVisibleEvidence
        this.didRequireBoundedOwnerShutdownEvidence =
            didRequireBoundedOwnerShutdownEvidence
        this.didRequireStopConditionBeforeTeardownEvidence =
            didRequireStopConditionBeforeTeardownEvidence
        this.didRequireAutoCloseCleanupEvidence =
            didRequireAutoCloseCleanupEvidence
        this.didRequireFailClosedTeardownRoute =
            didRequireFailClosedTeardownRoute
        this.didKeepActualTeardownExecutionBlocked =
            didKeepActualTeardownExecutionBlocked
        this.didKeepRunLoopExecutionEvidenceRequired =
            didKeepRunLoopExecutionEvidenceRequired
        this.didKeepBoundedRunLoopOwnerEvidenceRequired =
            didKeepBoundedRunLoopOwnerEvidenceRequired
        this.didKeepStopConditionEvidenceRequired =
            didKeepStopConditionEvidenceRequired
        this.didKeepAutoCloseEvidenceBeforeVisibleModeRequired =
            didKeepAutoCloseEvidenceBeforeVisibleModeRequired
        this.didKeepMainThreadRunLoopAffinityEvidenceRequired =
            didKeepMainThreadRunLoopAffinityEvidenceRequired
        this.didKeepActualEventLoopBlocked = didKeepActualEventLoopBlocked
        this.didKeepActualRunLoopPumpBlocked = didKeepActualRunLoopPumpBlocked
        this.didKeepLifecycleOwnerEvidenceRequired =
            didKeepLifecycleOwnerEvidenceRequired
        this.didKeepApplicationSingletonOwnershipEvidenceRequired =
            didKeepApplicationSingletonOwnershipEvidenceRequired
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
        this.didKeepTeardownOrderingEvidenceFactsValueOnly =
            didKeepTeardownOrderingEvidenceFactsValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceAdmission {
    let teardownOrderingEvidenceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceFacts
    let didAdmitNsApplicationSharedApplicationTeardownOrderingEvidenceBoundary:
        Bool
    let shouldDeferNsApplicationSharedApplicationTeardownOrderingEvidenceBoundary:
        Bool
    let shouldReportNsApplicationSharedApplicationTeardownOrderingEvidenceBlocked:
        Bool
    let didConfirmTeardownOrderingEvidenceStillRequired: Bool
    let didConfirmTeardownBeforeVisibleEvidenceRequired: Bool
    let didConfirmBoundedOwnerShutdownEvidenceRequired: Bool
    let didConfirmStopConditionBeforeTeardownEvidenceRequired: Bool
    let didConfirmAutoCloseCleanupEvidenceRequired: Bool
    let didConfirmFailClosedTeardownRouteRequired: Bool
    let didConfirmActualTeardownExecutionStillBlocked: Bool
    let didConfirmActualEventLoopStillBlocked: Bool
    let didConfirmActualRunLoopPumpStillBlocked: Bool
    let didConfirmActualApplicationSingletonAccessorCallStillBlocked: Bool
    let didKeepNsApplicationSharedApplicationTeardownOrderingEvidenceValueOnly:
        Bool

    init(
        teardownOrderingEvidenceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceFacts,
        didAdmitNsApplicationSharedApplicationTeardownOrderingEvidenceBoundary:
            Bool,
        shouldDeferNsApplicationSharedApplicationTeardownOrderingEvidenceBoundary:
            Bool,
        shouldReportNsApplicationSharedApplicationTeardownOrderingEvidenceBlocked:
            Bool,
        didConfirmTeardownOrderingEvidenceStillRequired: Bool,
        didConfirmTeardownBeforeVisibleEvidenceRequired: Bool,
        didConfirmBoundedOwnerShutdownEvidenceRequired: Bool,
        didConfirmStopConditionBeforeTeardownEvidenceRequired: Bool,
        didConfirmAutoCloseCleanupEvidenceRequired: Bool,
        didConfirmFailClosedTeardownRouteRequired: Bool,
        didConfirmActualTeardownExecutionStillBlocked: Bool,
        didConfirmActualEventLoopStillBlocked: Bool,
        didConfirmActualRunLoopPumpStillBlocked: Bool,
        didConfirmActualApplicationSingletonAccessorCallStillBlocked: Bool,
        didKeepNsApplicationSharedApplicationTeardownOrderingEvidenceValueOnly:
            Bool
    ) {
        this.teardownOrderingEvidenceFacts = teardownOrderingEvidenceFacts
        this.didAdmitNsApplicationSharedApplicationTeardownOrderingEvidenceBoundary =
            didAdmitNsApplicationSharedApplicationTeardownOrderingEvidenceBoundary
        this.shouldDeferNsApplicationSharedApplicationTeardownOrderingEvidenceBoundary =
            shouldDeferNsApplicationSharedApplicationTeardownOrderingEvidenceBoundary
        this.shouldReportNsApplicationSharedApplicationTeardownOrderingEvidenceBlocked =
            shouldReportNsApplicationSharedApplicationTeardownOrderingEvidenceBlocked
        this.didConfirmTeardownOrderingEvidenceStillRequired =
            didConfirmTeardownOrderingEvidenceStillRequired
        this.didConfirmTeardownBeforeVisibleEvidenceRequired =
            didConfirmTeardownBeforeVisibleEvidenceRequired
        this.didConfirmBoundedOwnerShutdownEvidenceRequired =
            didConfirmBoundedOwnerShutdownEvidenceRequired
        this.didConfirmStopConditionBeforeTeardownEvidenceRequired =
            didConfirmStopConditionBeforeTeardownEvidenceRequired
        this.didConfirmAutoCloseCleanupEvidenceRequired =
            didConfirmAutoCloseCleanupEvidenceRequired
        this.didConfirmFailClosedTeardownRouteRequired =
            didConfirmFailClosedTeardownRouteRequired
        this.didConfirmActualTeardownExecutionStillBlocked =
            didConfirmActualTeardownExecutionStillBlocked
        this.didConfirmActualEventLoopStillBlocked =
            didConfirmActualEventLoopStillBlocked
        this.didConfirmActualRunLoopPumpStillBlocked =
            didConfirmActualRunLoopPumpStillBlocked
        this.didConfirmActualApplicationSingletonAccessorCallStillBlocked =
            didConfirmActualApplicationSingletonAccessorCallStillBlocked
        this.didKeepNsApplicationSharedApplicationTeardownOrderingEvidenceValueOnly =
            didKeepNsApplicationSharedApplicationTeardownOrderingEvidenceValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness {
    let nsApplicationSharedApplicationRunLoopEvidenceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness
    let nsApplicationSharedApplicationTeardownOrderingEvidenceAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceAdmission
    let didPrepareRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness:
        Bool
    let shouldDeferRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness:
        Bool
    let shouldReportRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceBlocked:
        Bool
    let didPreserveNsApplicationSharedApplicationRunLoopEvidenceReadiness:
        Bool
    let didConfirmTeardownOrderingEvidenceStillRequired: Bool
    let didConfirmTeardownBeforeVisibleEvidenceRequired: Bool
    let didConfirmBoundedOwnerShutdownEvidenceRequired: Bool
    let didConfirmStopConditionBeforeTeardownEvidenceRequired: Bool
    let didConfirmAutoCloseCleanupEvidenceRequired: Bool
    let didConfirmFailClosedTeardownRouteRequired: Bool
    let didConfirmActualTeardownExecutionStillBlocked: Bool
    let didConfirmRunLoopExecutionEvidenceStillRequired: Bool
    let didConfirmBoundedRunLoopOwnerEvidenceRequired: Bool
    let didConfirmStopConditionEvidenceRequired: Bool
    let didConfirmAutoCloseEvidenceBeforeVisibleModeRequired: Bool
    let didConfirmMainThreadRunLoopAffinityEvidenceRequired: Bool
    let didConfirmActualEventLoopStillBlocked: Bool
    let didConfirmActualRunLoopPumpStillBlocked: Bool
    let didConfirmLifecycleOwnerEvidenceStillRequired: Bool
    let didConfirmApplicationSingletonOwnershipEvidenceStillRequired: Bool
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
    let didKeepNsApplicationSharedApplicationTeardownOrderingEvidenceReadinessDehydrated:
        Bool
    let didAvoidTeardownReadyWrapper: Bool
    let didAvoidEventLoopReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        nsApplicationSharedApplicationRunLoopEvidenceReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness,
        nsApplicationSharedApplicationTeardownOrderingEvidenceAdmission:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceAdmission,
        didPrepareRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness:
            Bool,
        shouldDeferRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness:
            Bool,
        shouldReportRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceBlocked:
            Bool,
        didPreserveNsApplicationSharedApplicationRunLoopEvidenceReadiness:
            Bool,
        didConfirmTeardownOrderingEvidenceStillRequired: Bool,
        didConfirmTeardownBeforeVisibleEvidenceRequired: Bool,
        didConfirmBoundedOwnerShutdownEvidenceRequired: Bool,
        didConfirmStopConditionBeforeTeardownEvidenceRequired: Bool,
        didConfirmAutoCloseCleanupEvidenceRequired: Bool,
        didConfirmFailClosedTeardownRouteRequired: Bool,
        didConfirmActualTeardownExecutionStillBlocked: Bool,
        didConfirmRunLoopExecutionEvidenceStillRequired: Bool,
        didConfirmBoundedRunLoopOwnerEvidenceRequired: Bool,
        didConfirmStopConditionEvidenceRequired: Bool,
        didConfirmAutoCloseEvidenceBeforeVisibleModeRequired: Bool,
        didConfirmMainThreadRunLoopAffinityEvidenceRequired: Bool,
        didConfirmActualEventLoopStillBlocked: Bool,
        didConfirmActualRunLoopPumpStillBlocked: Bool,
        didConfirmLifecycleOwnerEvidenceStillRequired: Bool,
        didConfirmApplicationSingletonOwnershipEvidenceStillRequired: Bool,
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
        didKeepNsApplicationSharedApplicationTeardownOrderingEvidenceReadinessDehydrated:
            Bool,
        didAvoidTeardownReadyWrapper: Bool,
        didAvoidEventLoopReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.nsApplicationSharedApplicationRunLoopEvidenceReadiness =
            nsApplicationSharedApplicationRunLoopEvidenceReadiness
        this.nsApplicationSharedApplicationTeardownOrderingEvidenceAdmission =
            nsApplicationSharedApplicationTeardownOrderingEvidenceAdmission
        this.didPrepareRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness =
            didPrepareRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness
        this.shouldDeferRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness =
            shouldDeferRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness
        this.shouldReportRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceBlocked =
            shouldReportRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceBlocked
        this.didPreserveNsApplicationSharedApplicationRunLoopEvidenceReadiness =
            didPreserveNsApplicationSharedApplicationRunLoopEvidenceReadiness
        this.didConfirmTeardownOrderingEvidenceStillRequired =
            didConfirmTeardownOrderingEvidenceStillRequired
        this.didConfirmTeardownBeforeVisibleEvidenceRequired =
            didConfirmTeardownBeforeVisibleEvidenceRequired
        this.didConfirmBoundedOwnerShutdownEvidenceRequired =
            didConfirmBoundedOwnerShutdownEvidenceRequired
        this.didConfirmStopConditionBeforeTeardownEvidenceRequired =
            didConfirmStopConditionBeforeTeardownEvidenceRequired
        this.didConfirmAutoCloseCleanupEvidenceRequired =
            didConfirmAutoCloseCleanupEvidenceRequired
        this.didConfirmFailClosedTeardownRouteRequired =
            didConfirmFailClosedTeardownRouteRequired
        this.didConfirmActualTeardownExecutionStillBlocked =
            didConfirmActualTeardownExecutionStillBlocked
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
        this.didKeepNsApplicationSharedApplicationTeardownOrderingEvidenceReadinessDehydrated =
            didKeepNsApplicationSharedApplicationTeardownOrderingEvidenceReadinessDehydrated
        this.didAvoidTeardownReadyWrapper = didAvoidTeardownReadyWrapper
        this.didAvoidEventLoopReadyWrapper = didAvoidEventLoopReadyWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceFacts(
    runLoopReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceFacts {
    let upstreamReady =
        runLoopReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness &&
        runLoopReadiness.didConfirmRunLoopExecutionEvidenceStillRequired &&
        runLoopReadiness.didConfirmBoundedRunLoopOwnerEvidenceRequired &&
        runLoopReadiness.didConfirmStopConditionEvidenceRequired &&
        runLoopReadiness.didConfirmAutoCloseEvidenceBeforeVisibleModeRequired &&
        runLoopReadiness.didConfirmMainThreadRunLoopAffinityEvidenceRequired &&
        runLoopReadiness.didConfirmActualEventLoopStillBlocked &&
        runLoopReadiness.didConfirmActualRunLoopPumpStillBlocked &&
        runLoopReadiness.didConfirmTeardownOrderingEvidenceStillRequired &&
        runLoopReadiness
            .didConfirmActualApplicationSingletonAccessorCallStillBlocked &&
        runLoopReadiness.didConfirmNoApplicationSingletonAccessorCall &&
        runLoopReadiness.didConfirmApplicationSingletonCreationStillBlocked &&
        runLoopReadiness.didConfirmApplicationSideEffectStillBlocked &&
        runLoopReadiness.didConfirmActivationPolicyMutationStillBlocked &&
        runLoopReadiness.didConfirmApplicationActivationStillBlocked &&
        runLoopReadiness.didConfirmNativeVisibleOrderStillBlocked &&
        runLoopReadiness.didConfirmProductionDrawableStillBlocked &&
        runLoopReadiness.didConfirmRenderStillBlocked &&
        runLoopReadiness.didConfirmNoApplicationCreationOrActivation &&
        runLoopReadiness.didConfirmNoPointerHandleClassIdReturn &&
        runLoopReadiness.didConfirmNoPublicSurface &&
        runLoopReadiness.didConfirmNoPublicCAbi &&
        runLoopReadiness.didConfirmNoRendererStateWrite &&
        runLoopReadiness.didConfirmNoBackendReadyTruth &&
        runLoopReadiness
            .didKeepNsApplicationSharedApplicationRunLoopEvidenceReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceFacts(
        upstreamReady,
        runLoopReadiness.didConfirmTeardownOrderingEvidenceStillRequired,
        true,
        true,
        true,
        true,
        true,
        true,
        runLoopReadiness.didConfirmRunLoopExecutionEvidenceStillRequired,
        runLoopReadiness.didConfirmBoundedRunLoopOwnerEvidenceRequired,
        runLoopReadiness.didConfirmStopConditionEvidenceRequired,
        runLoopReadiness.didConfirmAutoCloseEvidenceBeforeVisibleModeRequired,
        runLoopReadiness.didConfirmMainThreadRunLoopAffinityEvidenceRequired,
        runLoopReadiness.didConfirmActualEventLoopStillBlocked,
        runLoopReadiness.didConfirmActualRunLoopPumpStillBlocked,
        runLoopReadiness.didConfirmLifecycleOwnerEvidenceStillRequired,
        runLoopReadiness.didConfirmApplicationSingletonOwnershipEvidenceStillRequired,
        runLoopReadiness.didConfirmHeadlessArtifactPolicyEvidenceOnly,
        runLoopReadiness.didConfirmSideEffectContainmentEvidenceStillRequired,
        runLoopReadiness.didConfirmActualApplicationSingletonAccessorCallStillBlocked,
        runLoopReadiness.didConfirmNoApplicationSingletonAccessorCall,
        runLoopReadiness.didConfirmApplicationSingletonCreationStillBlocked,
        runLoopReadiness.didConfirmApplicationSideEffectStillBlocked,
        runLoopReadiness.didConfirmActivationPolicyMutationStillBlocked,
        runLoopReadiness.didConfirmApplicationActivationStillBlocked,
        runLoopReadiness.didConfirmNativeVisibleOrderStillBlocked,
        runLoopReadiness.didConfirmProductionDrawableStillBlocked,
        runLoopReadiness.didConfirmRenderStillBlocked,
        runLoopReadiness.didConfirmNoApplicationCreationOrActivation,
        runLoopReadiness.didConfirmNoPointerHandleClassIdReturn,
        runLoopReadiness.didConfirmNoPublicSurface,
        runLoopReadiness.didConfirmNoPublicCAbi,
        runLoopReadiness.didConfirmNoRendererStateWrite,
        runLoopReadiness.didConfirmNoBackendReadyTruth,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceAdmission(
    teardownOrderingEvidenceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceAdmission {
    let admitted =
        teardownOrderingEvidenceFacts.didPreserveRunLoopEvidenceReadiness &&
        teardownOrderingEvidenceFacts.didKeepTeardownOrderingEvidenceRequired &&
        teardownOrderingEvidenceFacts.didRequireTeardownBeforeVisibleEvidence &&
        teardownOrderingEvidenceFacts.didRequireBoundedOwnerShutdownEvidence &&
        teardownOrderingEvidenceFacts
            .didRequireStopConditionBeforeTeardownEvidence &&
        teardownOrderingEvidenceFacts.didRequireAutoCloseCleanupEvidence &&
        teardownOrderingEvidenceFacts.didRequireFailClosedTeardownRoute &&
        teardownOrderingEvidenceFacts.didKeepActualTeardownExecutionBlocked &&
        teardownOrderingEvidenceFacts.didKeepActualEventLoopBlocked &&
        teardownOrderingEvidenceFacts.didKeepActualRunLoopPumpBlocked &&
        teardownOrderingEvidenceFacts
            .didKeepActualApplicationSingletonAccessorCallBlocked &&
        teardownOrderingEvidenceFacts.didKeepNoApplicationSingletonAccessorCall &&
        teardownOrderingEvidenceFacts.didKeepApplicationSingletonCreationBlocked &&
        teardownOrderingEvidenceFacts.didKeepApplicationActivationBlocked &&
        teardownOrderingEvidenceFacts.didKeepNativeVisibleOrderImplementationBlocked &&
        teardownOrderingEvidenceFacts.didKeepProductionDrawablePermissionBlocked &&
        teardownOrderingEvidenceFacts.didKeepRenderPermissionBlocked &&
        teardownOrderingEvidenceFacts.didConfirmNoPublicSurface &&
        teardownOrderingEvidenceFacts.didConfirmNoPublicCAbi &&
        teardownOrderingEvidenceFacts.didConfirmNoRendererStateWrite &&
        teardownOrderingEvidenceFacts.didConfirmNoBackendReadyTruth &&
        teardownOrderingEvidenceFacts.didKeepTeardownOrderingEvidenceFactsValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceAdmission(
        teardownOrderingEvidenceFacts,
        admitted,
        !admitted,
        !admitted,
        teardownOrderingEvidenceFacts.didKeepTeardownOrderingEvidenceRequired,
        teardownOrderingEvidenceFacts.didRequireTeardownBeforeVisibleEvidence,
        teardownOrderingEvidenceFacts.didRequireBoundedOwnerShutdownEvidence,
        teardownOrderingEvidenceFacts
            .didRequireStopConditionBeforeTeardownEvidence,
        teardownOrderingEvidenceFacts.didRequireAutoCloseCleanupEvidence,
        teardownOrderingEvidenceFacts.didRequireFailClosedTeardownRoute,
        teardownOrderingEvidenceFacts.didKeepActualTeardownExecutionBlocked,
        teardownOrderingEvidenceFacts.didKeepActualEventLoopBlocked,
        teardownOrderingEvidenceFacts.didKeepActualRunLoopPumpBlocked,
        teardownOrderingEvidenceFacts
            .didKeepActualApplicationSingletonAccessorCallBlocked,
        teardownOrderingEvidenceFacts.didKeepTeardownOrderingEvidenceFactsValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness(
    runLoopReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness,
    teardownOrderingEvidenceAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceAdmission
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness {
    let admitted =
        teardownOrderingEvidenceAdmission
            .didAdmitNsApplicationSharedApplicationTeardownOrderingEvidenceBoundary
    let teardownOrderingEvidenceFacts =
        teardownOrderingEvidenceAdmission.teardownOrderingEvidenceFacts

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness(
        runLoopReadiness,
        teardownOrderingEvidenceAdmission,
        admitted,
        !admitted,
        !admitted,
        teardownOrderingEvidenceFacts.didPreserveRunLoopEvidenceReadiness,
        teardownOrderingEvidenceAdmission.didConfirmTeardownOrderingEvidenceStillRequired,
        teardownOrderingEvidenceAdmission
            .didConfirmTeardownBeforeVisibleEvidenceRequired,
        teardownOrderingEvidenceAdmission
            .didConfirmBoundedOwnerShutdownEvidenceRequired,
        teardownOrderingEvidenceAdmission
            .didConfirmStopConditionBeforeTeardownEvidenceRequired,
        teardownOrderingEvidenceAdmission.didConfirmAutoCloseCleanupEvidenceRequired,
        teardownOrderingEvidenceAdmission.didConfirmFailClosedTeardownRouteRequired,
        teardownOrderingEvidenceAdmission
            .didConfirmActualTeardownExecutionStillBlocked,
        teardownOrderingEvidenceFacts.didKeepRunLoopExecutionEvidenceRequired,
        teardownOrderingEvidenceFacts.didKeepBoundedRunLoopOwnerEvidenceRequired,
        teardownOrderingEvidenceFacts.didKeepStopConditionEvidenceRequired,
        teardownOrderingEvidenceFacts
            .didKeepAutoCloseEvidenceBeforeVisibleModeRequired,
        teardownOrderingEvidenceFacts
            .didKeepMainThreadRunLoopAffinityEvidenceRequired,
        teardownOrderingEvidenceAdmission.didConfirmActualEventLoopStillBlocked,
        teardownOrderingEvidenceAdmission.didConfirmActualRunLoopPumpStillBlocked,
        teardownOrderingEvidenceFacts.didKeepLifecycleOwnerEvidenceRequired,
        teardownOrderingEvidenceFacts
            .didKeepApplicationSingletonOwnershipEvidenceRequired,
        teardownOrderingEvidenceFacts.didKeepHeadlessArtifactPolicyEvidenceOnly,
        teardownOrderingEvidenceFacts.didKeepSideEffectContainmentEvidenceRequired,
        teardownOrderingEvidenceAdmission
            .didConfirmActualApplicationSingletonAccessorCallStillBlocked,
        teardownOrderingEvidenceFacts.didKeepNoApplicationSingletonAccessorCall,
        teardownOrderingEvidenceFacts.didKeepApplicationSingletonCreationBlocked,
        teardownOrderingEvidenceFacts.didKeepApplicationSideEffectBlocked,
        teardownOrderingEvidenceFacts.didKeepActivationPolicyMutationBlocked,
        teardownOrderingEvidenceFacts.didKeepApplicationActivationBlocked,
        teardownOrderingEvidenceFacts
            .didKeepNativeVisibleOrderImplementationBlocked,
        teardownOrderingEvidenceFacts.didKeepProductionDrawablePermissionBlocked,
        teardownOrderingEvidenceFacts.didKeepRenderPermissionBlocked,
        teardownOrderingEvidenceFacts.didConfirmNoApplicationCreationOrActivation,
        teardownOrderingEvidenceFacts.didConfirmNoPointerHandleClassIdReturn,
        teardownOrderingEvidenceFacts.didConfirmNoPublicSurface,
        teardownOrderingEvidenceFacts.didConfirmNoPublicCAbi,
        teardownOrderingEvidenceFacts.didConfirmNoRendererStateWrite,
        teardownOrderingEvidenceFacts.didConfirmNoBackendReadyTruth,
        teardownOrderingEvidenceAdmission
            .didKeepNsApplicationSharedApplicationTeardownOrderingEvidenceValueOnly,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness {
    let runLoopReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceDraft()
    let teardownOrderingEvidenceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceFacts(
            runLoopReadiness
        )
    let teardownOrderingEvidenceAdmission =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceAdmission(
            teardownOrderingEvidenceFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness(
        runLoopReadiness,
        teardownOrderingEvidenceAdmission
    )
}
