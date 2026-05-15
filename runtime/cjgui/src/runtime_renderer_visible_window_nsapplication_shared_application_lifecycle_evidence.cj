// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application lifecycle evidence value boundary owner。
// Owner: runtime renderer internal NSApplication shared-application lifecycle
// evidence owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness，
// 固定 lifecycle owner evidence、application singleton ownership evidence、
// run-loop execution evidence、teardown ordering evidence、headless artifact
// policy 与 side-effect containment evidence 仍是后续进入 visible-window
// harness 的 internal value facts。
// Stop-line: 不调用 application singleton accessor，不创建 NSApplication，不
// activation，不修改 activation policy，不运行 event loop，不做 native visible
// order implementation，不获取 drawable，不创建 encoder，不 draw，不提交 GPU work，
// 不执行 render，不返回 Class / id / pointer / handle，不写 runtime_state.cj，
// 不扩 public API，不新增 native bridge C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、visible-ready、
// drawable-ready、render-ready、backend-ready、renderer state write、receipt、record
// 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceFacts {
    let didPreserveCleanupHeadlessSafetyReadiness: Bool
    let didRequireLifecycleOwnerEvidence: Bool
    let didRequireApplicationSingletonOwnershipEvidence: Bool
    let didKeepRunLoopExecutionEvidenceGap: Bool
    let didKeepTeardownOrderingEvidenceGap: Bool
    let didKeepHeadlessArtifactPolicyEvidenceOnly: Bool
    let didRequireSideEffectContainmentEvidenceBeforeAccessorCall: Bool
    let didKeepActualApplicationSingletonAccessorCallBlocked: Bool
    let didKeepNoApplicationSingletonAccessorCall: Bool
    let didKeepApplicationSingletonCreationBlocked: Bool
    let didKeepMainThreadOwnershipProofRequired: Bool
    let didKeepBoundedRunLoopPrerequisiteRequired: Bool
    let didKeepAutoClosePrerequisiteRequired: Bool
    let didKeepApplicationSideEffectBlocked: Bool
    let didKeepActivationPolicyMutationBlocked: Bool
    let didKeepApplicationActivationBlocked: Bool
    let didKeepEventLoopBlocked: Bool
    let didKeepNativeVisibleOrderImplementationBlocked: Bool
    let didKeepProductionDrawablePermissionBlocked: Bool
    let didKeepRenderPermissionBlocked: Bool
    let didConfirmNoApplicationCreationOrActivation: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoPublicCAbi: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepLifecycleEvidenceFactsValueOnly: Bool

    init(
        didPreserveCleanupHeadlessSafetyReadiness: Bool,
        didRequireLifecycleOwnerEvidence: Bool,
        didRequireApplicationSingletonOwnershipEvidence: Bool,
        didKeepRunLoopExecutionEvidenceGap: Bool,
        didKeepTeardownOrderingEvidenceGap: Bool,
        didKeepHeadlessArtifactPolicyEvidenceOnly: Bool,
        didRequireSideEffectContainmentEvidenceBeforeAccessorCall: Bool,
        didKeepActualApplicationSingletonAccessorCallBlocked: Bool,
        didKeepNoApplicationSingletonAccessorCall: Bool,
        didKeepApplicationSingletonCreationBlocked: Bool,
        didKeepMainThreadOwnershipProofRequired: Bool,
        didKeepBoundedRunLoopPrerequisiteRequired: Bool,
        didKeepAutoClosePrerequisiteRequired: Bool,
        didKeepApplicationSideEffectBlocked: Bool,
        didKeepActivationPolicyMutationBlocked: Bool,
        didKeepApplicationActivationBlocked: Bool,
        didKeepEventLoopBlocked: Bool,
        didKeepNativeVisibleOrderImplementationBlocked: Bool,
        didKeepProductionDrawablePermissionBlocked: Bool,
        didKeepRenderPermissionBlocked: Bool,
        didConfirmNoApplicationCreationOrActivation: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoPublicCAbi: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepLifecycleEvidenceFactsValueOnly: Bool
    ) {
        this.didPreserveCleanupHeadlessSafetyReadiness =
            didPreserveCleanupHeadlessSafetyReadiness
        this.didRequireLifecycleOwnerEvidence =
            didRequireLifecycleOwnerEvidence
        this.didRequireApplicationSingletonOwnershipEvidence =
            didRequireApplicationSingletonOwnershipEvidence
        this.didKeepRunLoopExecutionEvidenceGap =
            didKeepRunLoopExecutionEvidenceGap
        this.didKeepTeardownOrderingEvidenceGap =
            didKeepTeardownOrderingEvidenceGap
        this.didKeepHeadlessArtifactPolicyEvidenceOnly =
            didKeepHeadlessArtifactPolicyEvidenceOnly
        this.didRequireSideEffectContainmentEvidenceBeforeAccessorCall =
            didRequireSideEffectContainmentEvidenceBeforeAccessorCall
        this.didKeepActualApplicationSingletonAccessorCallBlocked =
            didKeepActualApplicationSingletonAccessorCallBlocked
        this.didKeepNoApplicationSingletonAccessorCall =
            didKeepNoApplicationSingletonAccessorCall
        this.didKeepApplicationSingletonCreationBlocked =
            didKeepApplicationSingletonCreationBlocked
        this.didKeepMainThreadOwnershipProofRequired =
            didKeepMainThreadOwnershipProofRequired
        this.didKeepBoundedRunLoopPrerequisiteRequired =
            didKeepBoundedRunLoopPrerequisiteRequired
        this.didKeepAutoClosePrerequisiteRequired =
            didKeepAutoClosePrerequisiteRequired
        this.didKeepApplicationSideEffectBlocked =
            didKeepApplicationSideEffectBlocked
        this.didKeepActivationPolicyMutationBlocked =
            didKeepActivationPolicyMutationBlocked
        this.didKeepApplicationActivationBlocked =
            didKeepApplicationActivationBlocked
        this.didKeepEventLoopBlocked = didKeepEventLoopBlocked
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
        this.didKeepLifecycleEvidenceFactsValueOnly =
            didKeepLifecycleEvidenceFactsValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceAdmission {
    let lifecycleEvidenceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceFacts
    let didAdmitNsApplicationSharedApplicationLifecycleEvidenceBoundary:
        Bool
    let shouldDeferNsApplicationSharedApplicationLifecycleEvidenceBoundary:
        Bool
    let shouldReportNsApplicationSharedApplicationLifecycleEvidenceBlocked:
        Bool
    let didConfirmLifecycleOwnerEvidenceRequired: Bool
    let didConfirmApplicationSingletonOwnershipEvidenceRequired: Bool
    let didConfirmRunLoopExecutionEvidenceStillRequired: Bool
    let didConfirmTeardownOrderingEvidenceStillRequired: Bool
    let didConfirmHeadlessArtifactPolicyEvidenceOnly: Bool
    let didConfirmSideEffectContainmentEvidenceStillRequired: Bool
    let didConfirmActualApplicationSingletonAccessorCallStillBlocked: Bool
    let didKeepNsApplicationSharedApplicationLifecycleEvidenceValueOnly:
        Bool

    init(
        lifecycleEvidenceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceFacts,
        didAdmitNsApplicationSharedApplicationLifecycleEvidenceBoundary:
            Bool,
        shouldDeferNsApplicationSharedApplicationLifecycleEvidenceBoundary:
            Bool,
        shouldReportNsApplicationSharedApplicationLifecycleEvidenceBlocked:
            Bool,
        didConfirmLifecycleOwnerEvidenceRequired: Bool,
        didConfirmApplicationSingletonOwnershipEvidenceRequired: Bool,
        didConfirmRunLoopExecutionEvidenceStillRequired: Bool,
        didConfirmTeardownOrderingEvidenceStillRequired: Bool,
        didConfirmHeadlessArtifactPolicyEvidenceOnly: Bool,
        didConfirmSideEffectContainmentEvidenceStillRequired: Bool,
        didConfirmActualApplicationSingletonAccessorCallStillBlocked: Bool,
        didKeepNsApplicationSharedApplicationLifecycleEvidenceValueOnly:
            Bool
    ) {
        this.lifecycleEvidenceFacts = lifecycleEvidenceFacts
        this.didAdmitNsApplicationSharedApplicationLifecycleEvidenceBoundary =
            didAdmitNsApplicationSharedApplicationLifecycleEvidenceBoundary
        this.shouldDeferNsApplicationSharedApplicationLifecycleEvidenceBoundary =
            shouldDeferNsApplicationSharedApplicationLifecycleEvidenceBoundary
        this.shouldReportNsApplicationSharedApplicationLifecycleEvidenceBlocked =
            shouldReportNsApplicationSharedApplicationLifecycleEvidenceBlocked
        this.didConfirmLifecycleOwnerEvidenceRequired =
            didConfirmLifecycleOwnerEvidenceRequired
        this.didConfirmApplicationSingletonOwnershipEvidenceRequired =
            didConfirmApplicationSingletonOwnershipEvidenceRequired
        this.didConfirmRunLoopExecutionEvidenceStillRequired =
            didConfirmRunLoopExecutionEvidenceStillRequired
        this.didConfirmTeardownOrderingEvidenceStillRequired =
            didConfirmTeardownOrderingEvidenceStillRequired
        this.didConfirmHeadlessArtifactPolicyEvidenceOnly =
            didConfirmHeadlessArtifactPolicyEvidenceOnly
        this.didConfirmSideEffectContainmentEvidenceStillRequired =
            didConfirmSideEffectContainmentEvidenceStillRequired
        this.didConfirmActualApplicationSingletonAccessorCallStillBlocked =
            didConfirmActualApplicationSingletonAccessorCallStillBlocked
        this.didKeepNsApplicationSharedApplicationLifecycleEvidenceValueOnly =
            didKeepNsApplicationSharedApplicationLifecycleEvidenceValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness {
    let nsApplicationSharedApplicationCleanupHeadlessSafetyReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness
    let nsApplicationSharedApplicationLifecycleEvidenceAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceAdmission
    let didPrepareRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness:
        Bool
    let shouldDeferRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness:
        Bool
    let shouldReportRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceBlocked:
        Bool
    let didPreserveNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness:
        Bool
    let didConfirmLifecycleOwnerEvidenceRequired: Bool
    let didConfirmApplicationSingletonOwnershipEvidenceRequired: Bool
    let didConfirmRunLoopExecutionEvidenceStillRequired: Bool
    let didConfirmTeardownOrderingEvidenceStillRequired: Bool
    let didConfirmHeadlessArtifactPolicyEvidenceOnly: Bool
    let didConfirmSideEffectContainmentEvidenceStillRequired: Bool
    let didConfirmActualApplicationSingletonAccessorCallStillBlocked: Bool
    let didConfirmNoApplicationSingletonAccessorCall: Bool
    let didConfirmApplicationSingletonCreationStillBlocked: Bool
    let didConfirmMainThreadOwnershipProofStillRequired: Bool
    let didConfirmBoundedRunLoopPrerequisiteStillRequired: Bool
    let didConfirmAutoClosePrerequisiteStillRequired: Bool
    let didConfirmApplicationSideEffectStillBlocked: Bool
    let didConfirmActivationPolicyMutationStillBlocked: Bool
    let didConfirmApplicationActivationStillBlocked: Bool
    let didConfirmEventLoopStillBlocked: Bool
    let didConfirmNativeVisibleOrderStillBlocked: Bool
    let didConfirmProductionDrawableStillBlocked: Bool
    let didConfirmRenderStillBlocked: Bool
    let didConfirmNoApplicationCreationOrActivation: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoPublicCAbi: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNsApplicationSharedApplicationLifecycleEvidenceReadinessDehydrated:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        nsApplicationSharedApplicationCleanupHeadlessSafetyReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness,
        nsApplicationSharedApplicationLifecycleEvidenceAdmission:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceAdmission,
        didPrepareRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness:
            Bool,
        shouldDeferRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness:
            Bool,
        shouldReportRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceBlocked:
            Bool,
        didPreserveNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness:
            Bool,
        didConfirmLifecycleOwnerEvidenceRequired: Bool,
        didConfirmApplicationSingletonOwnershipEvidenceRequired: Bool,
        didConfirmRunLoopExecutionEvidenceStillRequired: Bool,
        didConfirmTeardownOrderingEvidenceStillRequired: Bool,
        didConfirmHeadlessArtifactPolicyEvidenceOnly: Bool,
        didConfirmSideEffectContainmentEvidenceStillRequired: Bool,
        didConfirmActualApplicationSingletonAccessorCallStillBlocked: Bool,
        didConfirmNoApplicationSingletonAccessorCall: Bool,
        didConfirmApplicationSingletonCreationStillBlocked: Bool,
        didConfirmMainThreadOwnershipProofStillRequired: Bool,
        didConfirmBoundedRunLoopPrerequisiteStillRequired: Bool,
        didConfirmAutoClosePrerequisiteStillRequired: Bool,
        didConfirmApplicationSideEffectStillBlocked: Bool,
        didConfirmActivationPolicyMutationStillBlocked: Bool,
        didConfirmApplicationActivationStillBlocked: Bool,
        didConfirmEventLoopStillBlocked: Bool,
        didConfirmNativeVisibleOrderStillBlocked: Bool,
        didConfirmProductionDrawableStillBlocked: Bool,
        didConfirmRenderStillBlocked: Bool,
        didConfirmNoApplicationCreationOrActivation: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoPublicCAbi: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNsApplicationSharedApplicationLifecycleEvidenceReadinessDehydrated:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.nsApplicationSharedApplicationCleanupHeadlessSafetyReadiness =
            nsApplicationSharedApplicationCleanupHeadlessSafetyReadiness
        this.nsApplicationSharedApplicationLifecycleEvidenceAdmission =
            nsApplicationSharedApplicationLifecycleEvidenceAdmission
        this.didPrepareRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness =
            didPrepareRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness
        this.shouldDeferRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness =
            shouldDeferRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness
        this.shouldReportRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceBlocked =
            shouldReportRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceBlocked
        this.didPreserveNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness =
            didPreserveNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness
        this.didConfirmLifecycleOwnerEvidenceRequired =
            didConfirmLifecycleOwnerEvidenceRequired
        this.didConfirmApplicationSingletonOwnershipEvidenceRequired =
            didConfirmApplicationSingletonOwnershipEvidenceRequired
        this.didConfirmRunLoopExecutionEvidenceStillRequired =
            didConfirmRunLoopExecutionEvidenceStillRequired
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
        this.didConfirmMainThreadOwnershipProofStillRequired =
            didConfirmMainThreadOwnershipProofStillRequired
        this.didConfirmBoundedRunLoopPrerequisiteStillRequired =
            didConfirmBoundedRunLoopPrerequisiteStillRequired
        this.didConfirmAutoClosePrerequisiteStillRequired =
            didConfirmAutoClosePrerequisiteStillRequired
        this.didConfirmApplicationSideEffectStillBlocked =
            didConfirmApplicationSideEffectStillBlocked
        this.didConfirmActivationPolicyMutationStillBlocked =
            didConfirmActivationPolicyMutationStillBlocked
        this.didConfirmApplicationActivationStillBlocked =
            didConfirmApplicationActivationStillBlocked
        this.didConfirmEventLoopStillBlocked = didConfirmEventLoopStillBlocked
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
        this.didKeepNsApplicationSharedApplicationLifecycleEvidenceReadinessDehydrated =
            didKeepNsApplicationSharedApplicationLifecycleEvidenceReadinessDehydrated
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceFacts(
    safetyReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceFacts {
    let upstreamReady =
        safetyReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness &&
        safetyReadiness.didConfirmCleanupCoOwnershipBeforeVisibleModeRequired &&
        safetyReadiness.didConfirmHeadlessSafetyFailClosedRoute &&
        safetyReadiness.didConfirmCiArtifactPolicyEvidenceOnly &&
        safetyReadiness.didConfirmMainThreadOwnershipProofBeforeAccessorCallRequired &&
        safetyReadiness.didConfirmTeardownProofBeforeVisibleModeRequired &&
        safetyReadiness.didConfirmNonUserVisibleModeRequired &&
        safetyReadiness.didConfirmActualApplicationSingletonAccessorCallStillBlocked &&
        safetyReadiness.didConfirmNoApplicationSingletonAccessorCall &&
        safetyReadiness.didConfirmApplicationSingletonCreationStillBlocked &&
        safetyReadiness.didConfirmBoundedRunLoopPrerequisiteRequired &&
        safetyReadiness.didConfirmAutoClosePrerequisiteRequired &&
        safetyReadiness.didConfirmApplicationSideEffectStillBlocked &&
        safetyReadiness.didConfirmActivationPolicyMutationStillBlocked &&
        safetyReadiness.didConfirmApplicationActivationStillBlocked &&
        safetyReadiness.didConfirmEventLoopStillBlocked &&
        safetyReadiness.didConfirmNativeVisibleOrderStillBlocked &&
        safetyReadiness.didConfirmProductionDrawableStillBlocked &&
        safetyReadiness.didConfirmRenderStillBlocked &&
        safetyReadiness.didConfirmNoApplicationCreationOrActivation &&
        safetyReadiness.didConfirmNoPointerHandleClassIdReturn &&
        safetyReadiness.didConfirmNoPublicSurface &&
        safetyReadiness.didConfirmNoRendererStateWrite &&
        safetyReadiness.didConfirmNoBackendReadyTruth &&
        safetyReadiness
            .didKeepNsApplicationSharedApplicationCleanupHeadlessSafetyReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceFacts(
        upstreamReady,
        true,
        true,
        true,
        true,
        safetyReadiness.didConfirmCiArtifactPolicyEvidenceOnly,
        true,
        safetyReadiness.didConfirmActualApplicationSingletonAccessorCallStillBlocked,
        safetyReadiness.didConfirmNoApplicationSingletonAccessorCall,
        safetyReadiness.didConfirmApplicationSingletonCreationStillBlocked,
        safetyReadiness
            .didConfirmMainThreadOwnershipProofBeforeAccessorCallRequired,
        safetyReadiness.didConfirmBoundedRunLoopPrerequisiteRequired,
        safetyReadiness.didConfirmAutoClosePrerequisiteRequired,
        safetyReadiness.didConfirmApplicationSideEffectStillBlocked,
        safetyReadiness.didConfirmActivationPolicyMutationStillBlocked,
        safetyReadiness.didConfirmApplicationActivationStillBlocked,
        safetyReadiness.didConfirmEventLoopStillBlocked,
        safetyReadiness.didConfirmNativeVisibleOrderStillBlocked,
        safetyReadiness.didConfirmProductionDrawableStillBlocked,
        safetyReadiness.didConfirmRenderStillBlocked,
        safetyReadiness.didConfirmNoApplicationCreationOrActivation,
        safetyReadiness.didConfirmNoPointerHandleClassIdReturn,
        safetyReadiness.didConfirmNoPublicSurface,
        true,
        safetyReadiness.didConfirmNoRendererStateWrite,
        safetyReadiness.didConfirmNoBackendReadyTruth,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceAdmission(
    lifecycleEvidenceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceAdmission {
    let admitted =
        lifecycleEvidenceFacts.didPreserveCleanupHeadlessSafetyReadiness &&
        lifecycleEvidenceFacts.didRequireLifecycleOwnerEvidence &&
        lifecycleEvidenceFacts.didRequireApplicationSingletonOwnershipEvidence &&
        lifecycleEvidenceFacts.didKeepRunLoopExecutionEvidenceGap &&
        lifecycleEvidenceFacts.didKeepTeardownOrderingEvidenceGap &&
        lifecycleEvidenceFacts.didKeepHeadlessArtifactPolicyEvidenceOnly &&
        lifecycleEvidenceFacts.didRequireSideEffectContainmentEvidenceBeforeAccessorCall &&
        lifecycleEvidenceFacts.didKeepActualApplicationSingletonAccessorCallBlocked &&
        lifecycleEvidenceFacts.didKeepNoApplicationSingletonAccessorCall &&
        lifecycleEvidenceFacts.didKeepApplicationSingletonCreationBlocked &&
        lifecycleEvidenceFacts.didKeepMainThreadOwnershipProofRequired &&
        lifecycleEvidenceFacts.didKeepBoundedRunLoopPrerequisiteRequired &&
        lifecycleEvidenceFacts.didKeepAutoClosePrerequisiteRequired &&
        lifecycleEvidenceFacts.didKeepApplicationSideEffectBlocked &&
        lifecycleEvidenceFacts.didKeepActivationPolicyMutationBlocked &&
        lifecycleEvidenceFacts.didKeepApplicationActivationBlocked &&
        lifecycleEvidenceFacts.didKeepEventLoopBlocked &&
        lifecycleEvidenceFacts.didKeepNativeVisibleOrderImplementationBlocked &&
        lifecycleEvidenceFacts.didKeepProductionDrawablePermissionBlocked &&
        lifecycleEvidenceFacts.didKeepRenderPermissionBlocked &&
        lifecycleEvidenceFacts.didConfirmNoApplicationCreationOrActivation &&
        lifecycleEvidenceFacts.didConfirmNoPointerHandleClassIdReturn &&
        lifecycleEvidenceFacts.didConfirmNoPublicSurface &&
        lifecycleEvidenceFacts.didConfirmNoPublicCAbi &&
        lifecycleEvidenceFacts.didConfirmNoRendererStateWrite &&
        lifecycleEvidenceFacts.didConfirmNoBackendReadyTruth &&
        lifecycleEvidenceFacts.didKeepLifecycleEvidenceFactsValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceAdmission(
        lifecycleEvidenceFacts,
        admitted,
        !admitted,
        !admitted,
        lifecycleEvidenceFacts.didRequireLifecycleOwnerEvidence,
        lifecycleEvidenceFacts.didRequireApplicationSingletonOwnershipEvidence,
        lifecycleEvidenceFacts.didKeepRunLoopExecutionEvidenceGap,
        lifecycleEvidenceFacts.didKeepTeardownOrderingEvidenceGap,
        lifecycleEvidenceFacts.didKeepHeadlessArtifactPolicyEvidenceOnly,
        lifecycleEvidenceFacts
            .didRequireSideEffectContainmentEvidenceBeforeAccessorCall,
        lifecycleEvidenceFacts.didKeepActualApplicationSingletonAccessorCallBlocked,
        lifecycleEvidenceFacts.didKeepLifecycleEvidenceFactsValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness(
    safetyReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness,
    lifecycleEvidenceAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceAdmission
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness {
    let admitted =
        lifecycleEvidenceAdmission
            .didAdmitNsApplicationSharedApplicationLifecycleEvidenceBoundary
    let lifecycleEvidenceFacts =
        lifecycleEvidenceAdmission.lifecycleEvidenceFacts

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness(
        safetyReadiness,
        lifecycleEvidenceAdmission,
        admitted,
        !admitted,
        !admitted,
        lifecycleEvidenceFacts.didPreserveCleanupHeadlessSafetyReadiness,
        lifecycleEvidenceAdmission.didConfirmLifecycleOwnerEvidenceRequired,
        lifecycleEvidenceAdmission
            .didConfirmApplicationSingletonOwnershipEvidenceRequired,
        lifecycleEvidenceAdmission.didConfirmRunLoopExecutionEvidenceStillRequired,
        lifecycleEvidenceAdmission.didConfirmTeardownOrderingEvidenceStillRequired,
        lifecycleEvidenceAdmission.didConfirmHeadlessArtifactPolicyEvidenceOnly,
        lifecycleEvidenceAdmission
            .didConfirmSideEffectContainmentEvidenceStillRequired,
        lifecycleEvidenceAdmission
            .didConfirmActualApplicationSingletonAccessorCallStillBlocked,
        lifecycleEvidenceFacts.didKeepNoApplicationSingletonAccessorCall,
        lifecycleEvidenceFacts.didKeepApplicationSingletonCreationBlocked,
        lifecycleEvidenceFacts.didKeepMainThreadOwnershipProofRequired,
        lifecycleEvidenceFacts.didKeepBoundedRunLoopPrerequisiteRequired,
        lifecycleEvidenceFacts.didKeepAutoClosePrerequisiteRequired,
        lifecycleEvidenceFacts.didKeepApplicationSideEffectBlocked,
        lifecycleEvidenceFacts.didKeepActivationPolicyMutationBlocked,
        lifecycleEvidenceFacts.didKeepApplicationActivationBlocked,
        lifecycleEvidenceFacts.didKeepEventLoopBlocked,
        lifecycleEvidenceFacts.didKeepNativeVisibleOrderImplementationBlocked,
        lifecycleEvidenceFacts.didKeepProductionDrawablePermissionBlocked,
        lifecycleEvidenceFacts.didKeepRenderPermissionBlocked,
        lifecycleEvidenceFacts.didConfirmNoApplicationCreationOrActivation,
        lifecycleEvidenceFacts.didConfirmNoPointerHandleClassIdReturn,
        lifecycleEvidenceFacts.didConfirmNoPublicSurface,
        lifecycleEvidenceFacts.didConfirmNoPublicCAbi,
        lifecycleEvidenceFacts.didConfirmNoRendererStateWrite,
        lifecycleEvidenceFacts.didConfirmNoBackendReadyTruth,
        lifecycleEvidenceAdmission
            .didKeepNsApplicationSharedApplicationLifecycleEvidenceValueOnly,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness {
    let safetyReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyDraft()
    let lifecycleEvidenceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceFacts(
            safetyReadiness
        )
    let lifecycleEvidenceAdmission =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceAdmission(
            lifecycleEvidenceFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness(
        safetyReadiness,
        lifecycleEvidenceAdmission
    )
}
