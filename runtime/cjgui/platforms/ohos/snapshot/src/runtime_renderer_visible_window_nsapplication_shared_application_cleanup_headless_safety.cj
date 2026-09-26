// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application cleanup / headless safety value boundary owner。
// Owner: runtime renderer internal NSApplication shared-application cleanup
// and headless safety evidence owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness，
// 固定 actual application singleton accessor call 仍 blocked，并把 cleanup
// co-ownership、headless fail-closed、CI artifact policy、main-thread
// ownership、teardown proof 与 non-user-visible mode 保持为后续 visible
// window harness 的 internal value facts。
// Stop-line: 不调用 application singleton accessor，不创建 NSApplication，不
// activation，不修改 activation policy，不运行 event loop，不做 native visible
// order implementation，不获取 drawable，不创建 encoder，不 draw，不提交 GPU work，
// 不执行 render，不返回 Class / id / pointer / handle，不写 runtime_state.cj，
// 不扩 public API，不新增 native bridge C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、visible-ready、
// drawable-ready、render-ready、backend-ready、renderer state write、receipt、record
// 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyFacts {
    let didPreserveAccessorCallContainmentPolicyReadiness: Bool
    let didKeepActualApplicationSingletonAccessorCallBlocked: Bool
    let didKeepNoApplicationSingletonAccessorCall: Bool
    let didKeepApplicationSingletonCreationBlocked: Bool
    let didRequireCleanupCoOwnershipBeforeVisibleMode: Bool
    let didRequireHeadlessSafetyFailClosedRoute: Bool
    let didKeepCiArtifactPolicyEvidenceOnly: Bool
    let didRequireMainThreadOwnershipProofBeforeAccessorCall: Bool
    let didRequireTeardownProofBeforeVisibleMode: Bool
    let didRequireNonUserVisibleMode: Bool
    let didRequireBoundedRunLoopPrerequisite: Bool
    let didRequireAutoClosePrerequisite: Bool
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
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepCleanupHeadlessSafetyFactsValueOnly: Bool

    init(
        didPreserveAccessorCallContainmentPolicyReadiness: Bool,
        didKeepActualApplicationSingletonAccessorCallBlocked: Bool,
        didKeepNoApplicationSingletonAccessorCall: Bool,
        didKeepApplicationSingletonCreationBlocked: Bool,
        didRequireCleanupCoOwnershipBeforeVisibleMode: Bool,
        didRequireHeadlessSafetyFailClosedRoute: Bool,
        didKeepCiArtifactPolicyEvidenceOnly: Bool,
        didRequireMainThreadOwnershipProofBeforeAccessorCall: Bool,
        didRequireTeardownProofBeforeVisibleMode: Bool,
        didRequireNonUserVisibleMode: Bool,
        didRequireBoundedRunLoopPrerequisite: Bool,
        didRequireAutoClosePrerequisite: Bool,
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
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepCleanupHeadlessSafetyFactsValueOnly: Bool
    ) {
        this.didPreserveAccessorCallContainmentPolicyReadiness =
            didPreserveAccessorCallContainmentPolicyReadiness
        this.didKeepActualApplicationSingletonAccessorCallBlocked =
            didKeepActualApplicationSingletonAccessorCallBlocked
        this.didKeepNoApplicationSingletonAccessorCall =
            didKeepNoApplicationSingletonAccessorCall
        this.didKeepApplicationSingletonCreationBlocked =
            didKeepApplicationSingletonCreationBlocked
        this.didRequireCleanupCoOwnershipBeforeVisibleMode =
            didRequireCleanupCoOwnershipBeforeVisibleMode
        this.didRequireHeadlessSafetyFailClosedRoute =
            didRequireHeadlessSafetyFailClosedRoute
        this.didKeepCiArtifactPolicyEvidenceOnly =
            didKeepCiArtifactPolicyEvidenceOnly
        this.didRequireMainThreadOwnershipProofBeforeAccessorCall =
            didRequireMainThreadOwnershipProofBeforeAccessorCall
        this.didRequireTeardownProofBeforeVisibleMode =
            didRequireTeardownProofBeforeVisibleMode
        this.didRequireNonUserVisibleMode = didRequireNonUserVisibleMode
        this.didRequireBoundedRunLoopPrerequisite =
            didRequireBoundedRunLoopPrerequisite
        this.didRequireAutoClosePrerequisite =
            didRequireAutoClosePrerequisite
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
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepCleanupHeadlessSafetyFactsValueOnly =
            didKeepCleanupHeadlessSafetyFactsValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyAdmission {
    let safetyFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyFacts
    let didAdmitNsApplicationSharedApplicationCleanupHeadlessSafetyBoundary:
        Bool
    let shouldDeferNsApplicationSharedApplicationCleanupHeadlessSafetyBoundary:
        Bool
    let shouldReportNsApplicationSharedApplicationCleanupHeadlessSafetyBlocked:
        Bool
    let didConfirmCleanupCoOwnershipRequired: Bool
    let didConfirmHeadlessSafetyFailClosed: Bool
    let didConfirmCiArtifactPolicyEvidenceOnly: Bool
    let didConfirmMainThreadOwnershipProofRequired: Bool
    let didConfirmTeardownProofRequired: Bool
    let didConfirmActualAccessorCallStillBlocked: Bool
    let didKeepNsApplicationSharedApplicationCleanupHeadlessSafetyValueOnly:
        Bool

    init(
        safetyFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyFacts,
        didAdmitNsApplicationSharedApplicationCleanupHeadlessSafetyBoundary:
            Bool,
        shouldDeferNsApplicationSharedApplicationCleanupHeadlessSafetyBoundary:
            Bool,
        shouldReportNsApplicationSharedApplicationCleanupHeadlessSafetyBlocked:
            Bool,
        didConfirmCleanupCoOwnershipRequired: Bool,
        didConfirmHeadlessSafetyFailClosed: Bool,
        didConfirmCiArtifactPolicyEvidenceOnly: Bool,
        didConfirmMainThreadOwnershipProofRequired: Bool,
        didConfirmTeardownProofRequired: Bool,
        didConfirmActualAccessorCallStillBlocked: Bool,
        didKeepNsApplicationSharedApplicationCleanupHeadlessSafetyValueOnly:
            Bool
    ) {
        this.safetyFacts = safetyFacts
        this.didAdmitNsApplicationSharedApplicationCleanupHeadlessSafetyBoundary =
            didAdmitNsApplicationSharedApplicationCleanupHeadlessSafetyBoundary
        this.shouldDeferNsApplicationSharedApplicationCleanupHeadlessSafetyBoundary =
            shouldDeferNsApplicationSharedApplicationCleanupHeadlessSafetyBoundary
        this.shouldReportNsApplicationSharedApplicationCleanupHeadlessSafetyBlocked =
            shouldReportNsApplicationSharedApplicationCleanupHeadlessSafetyBlocked
        this.didConfirmCleanupCoOwnershipRequired =
            didConfirmCleanupCoOwnershipRequired
        this.didConfirmHeadlessSafetyFailClosed =
            didConfirmHeadlessSafetyFailClosed
        this.didConfirmCiArtifactPolicyEvidenceOnly =
            didConfirmCiArtifactPolicyEvidenceOnly
        this.didConfirmMainThreadOwnershipProofRequired =
            didConfirmMainThreadOwnershipProofRequired
        this.didConfirmTeardownProofRequired = didConfirmTeardownProofRequired
        this.didConfirmActualAccessorCallStillBlocked =
            didConfirmActualAccessorCallStillBlocked
        this.didKeepNsApplicationSharedApplicationCleanupHeadlessSafetyValueOnly =
            didKeepNsApplicationSharedApplicationCleanupHeadlessSafetyValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness {
    let nsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness
    let nsApplicationSharedApplicationCleanupHeadlessSafetyAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyAdmission
    let didPrepareRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness:
        Bool
    let shouldDeferRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness:
        Bool
    let shouldReportRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyBlocked:
        Bool
    let didPreserveNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness:
        Bool
    let didConfirmCleanupCoOwnershipBeforeVisibleModeRequired: Bool
    let didConfirmHeadlessSafetyFailClosedRoute: Bool
    let didConfirmCiArtifactPolicyEvidenceOnly: Bool
    let didConfirmMainThreadOwnershipProofBeforeAccessorCallRequired: Bool
    let didConfirmTeardownProofBeforeVisibleModeRequired: Bool
    let didConfirmNonUserVisibleModeRequired: Bool
    let didConfirmActualApplicationSingletonAccessorCallStillBlocked: Bool
    let didConfirmNoApplicationSingletonAccessorCall: Bool
    let didConfirmApplicationSingletonCreationStillBlocked: Bool
    let didConfirmBoundedRunLoopPrerequisiteRequired: Bool
    let didConfirmAutoClosePrerequisiteRequired: Bool
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
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNsApplicationSharedApplicationCleanupHeadlessSafetyReadinessDehydrated:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        nsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness,
        nsApplicationSharedApplicationCleanupHeadlessSafetyAdmission:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyAdmission,
        didPrepareRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness:
            Bool,
        shouldDeferRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness:
            Bool,
        shouldReportRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyBlocked:
            Bool,
        didPreserveNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness:
            Bool,
        didConfirmCleanupCoOwnershipBeforeVisibleModeRequired: Bool,
        didConfirmHeadlessSafetyFailClosedRoute: Bool,
        didConfirmCiArtifactPolicyEvidenceOnly: Bool,
        didConfirmMainThreadOwnershipProofBeforeAccessorCallRequired: Bool,
        didConfirmTeardownProofBeforeVisibleModeRequired: Bool,
        didConfirmNonUserVisibleModeRequired: Bool,
        didConfirmActualApplicationSingletonAccessorCallStillBlocked: Bool,
        didConfirmNoApplicationSingletonAccessorCall: Bool,
        didConfirmApplicationSingletonCreationStillBlocked: Bool,
        didConfirmBoundedRunLoopPrerequisiteRequired: Bool,
        didConfirmAutoClosePrerequisiteRequired: Bool,
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
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNsApplicationSharedApplicationCleanupHeadlessSafetyReadinessDehydrated:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.nsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness =
            nsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness
        this.nsApplicationSharedApplicationCleanupHeadlessSafetyAdmission =
            nsApplicationSharedApplicationCleanupHeadlessSafetyAdmission
        this.didPrepareRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness =
            didPrepareRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness
        this.shouldDeferRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness =
            shouldDeferRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness
        this.shouldReportRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyBlocked =
            shouldReportRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyBlocked
        this.didPreserveNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness =
            didPreserveNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness
        this.didConfirmCleanupCoOwnershipBeforeVisibleModeRequired =
            didConfirmCleanupCoOwnershipBeforeVisibleModeRequired
        this.didConfirmHeadlessSafetyFailClosedRoute =
            didConfirmHeadlessSafetyFailClosedRoute
        this.didConfirmCiArtifactPolicyEvidenceOnly =
            didConfirmCiArtifactPolicyEvidenceOnly
        this.didConfirmMainThreadOwnershipProofBeforeAccessorCallRequired =
            didConfirmMainThreadOwnershipProofBeforeAccessorCallRequired
        this.didConfirmTeardownProofBeforeVisibleModeRequired =
            didConfirmTeardownProofBeforeVisibleModeRequired
        this.didConfirmNonUserVisibleModeRequired =
            didConfirmNonUserVisibleModeRequired
        this.didConfirmActualApplicationSingletonAccessorCallStillBlocked =
            didConfirmActualApplicationSingletonAccessorCallStillBlocked
        this.didConfirmNoApplicationSingletonAccessorCall =
            didConfirmNoApplicationSingletonAccessorCall
        this.didConfirmApplicationSingletonCreationStillBlocked =
            didConfirmApplicationSingletonCreationStillBlocked
        this.didConfirmBoundedRunLoopPrerequisiteRequired =
            didConfirmBoundedRunLoopPrerequisiteRequired
        this.didConfirmAutoClosePrerequisiteRequired =
            didConfirmAutoClosePrerequisiteRequired
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
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNsApplicationSharedApplicationCleanupHeadlessSafetyReadinessDehydrated =
            didKeepNsApplicationSharedApplicationCleanupHeadlessSafetyReadinessDehydrated
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyFacts(
    policyReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyFacts {
    let upstreamReady =
        policyReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness &&
        policyReadiness.didConfirmApplicationSingletonAccessorCallStillBlocked &&
        policyReadiness.didConfirmNoApplicationSingletonAccessorCall &&
        policyReadiness.didConfirmApplicationSingletonCreationStillBlocked &&
        policyReadiness.didConfirmSharedApplicationMainThreadGateRequired &&
        policyReadiness.didConfirmBoundedRunLoopPrerequisiteRequired &&
        policyReadiness.didConfirmAutoClosePrerequisiteRequired &&
        policyReadiness.didConfirmTeardownBeforeVisibleModeRequired &&
        policyReadiness.didConfirmNonUserVisibleModeRequired &&
        policyReadiness.didConfirmApplicationSideEffectStillBlocked &&
        policyReadiness.didConfirmActivationPolicyMutationStillBlocked &&
        policyReadiness.didConfirmApplicationActivationStillBlocked &&
        policyReadiness.didConfirmEventLoopStillBlocked &&
        policyReadiness.didConfirmNativeVisibleOrderStillBlocked &&
        policyReadiness.didConfirmProductionDrawableStillBlocked &&
        policyReadiness.didConfirmRenderStillBlocked &&
        policyReadiness.didConfirmNoApplicationCreationOrActivation &&
        policyReadiness.didConfirmNoPointerHandleClassIdReturn &&
        policyReadiness.didConfirmNoPublicSurface &&
        policyReadiness.didConfirmNoRendererStateWrite &&
        policyReadiness.didConfirmNoBackendReadyTruth &&
        policyReadiness
            .didKeepNsApplicationSharedApplicationAccessorCallContainmentPolicyReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyFacts(
        upstreamReady,
        policyReadiness.didConfirmApplicationSingletonAccessorCallStillBlocked,
        policyReadiness.didConfirmNoApplicationSingletonAccessorCall,
        policyReadiness.didConfirmApplicationSingletonCreationStillBlocked,
        true,
        true,
        true,
        policyReadiness.didConfirmSharedApplicationMainThreadGateRequired,
        policyReadiness.didConfirmTeardownBeforeVisibleModeRequired,
        policyReadiness.didConfirmNonUserVisibleModeRequired,
        policyReadiness.didConfirmBoundedRunLoopPrerequisiteRequired,
        policyReadiness.didConfirmAutoClosePrerequisiteRequired,
        policyReadiness.didConfirmApplicationSideEffectStillBlocked,
        policyReadiness.didConfirmActivationPolicyMutationStillBlocked,
        policyReadiness.didConfirmApplicationActivationStillBlocked,
        policyReadiness.didConfirmEventLoopStillBlocked,
        policyReadiness.didConfirmNativeVisibleOrderStillBlocked,
        policyReadiness.didConfirmProductionDrawableStillBlocked,
        policyReadiness.didConfirmRenderStillBlocked,
        policyReadiness.didConfirmNoApplicationCreationOrActivation,
        policyReadiness.didConfirmNoPointerHandleClassIdReturn,
        policyReadiness.didConfirmNoPublicSurface,
        policyReadiness.didConfirmNoRendererStateWrite,
        policyReadiness.didConfirmNoBackendReadyTruth,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyAdmission(
    safetyFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyAdmission {
    let admitted =
        safetyFacts.didPreserveAccessorCallContainmentPolicyReadiness &&
        safetyFacts.didKeepActualApplicationSingletonAccessorCallBlocked &&
        safetyFacts.didKeepNoApplicationSingletonAccessorCall &&
        safetyFacts.didKeepApplicationSingletonCreationBlocked &&
        safetyFacts.didRequireCleanupCoOwnershipBeforeVisibleMode &&
        safetyFacts.didRequireHeadlessSafetyFailClosedRoute &&
        safetyFacts.didKeepCiArtifactPolicyEvidenceOnly &&
        safetyFacts.didRequireMainThreadOwnershipProofBeforeAccessorCall &&
        safetyFacts.didRequireTeardownProofBeforeVisibleMode &&
        safetyFacts.didRequireNonUserVisibleMode &&
        safetyFacts.didRequireBoundedRunLoopPrerequisite &&
        safetyFacts.didRequireAutoClosePrerequisite &&
        safetyFacts.didKeepApplicationSideEffectBlocked &&
        safetyFacts.didKeepActivationPolicyMutationBlocked &&
        safetyFacts.didKeepApplicationActivationBlocked &&
        safetyFacts.didKeepEventLoopBlocked &&
        safetyFacts.didKeepNativeVisibleOrderImplementationBlocked &&
        safetyFacts.didKeepProductionDrawablePermissionBlocked &&
        safetyFacts.didKeepRenderPermissionBlocked &&
        safetyFacts.didConfirmNoApplicationCreationOrActivation &&
        safetyFacts.didConfirmNoPointerHandleClassIdReturn &&
        safetyFacts.didConfirmNoPublicSurface &&
        safetyFacts.didConfirmNoRendererStateWrite &&
        safetyFacts.didConfirmNoBackendReadyTruth &&
        safetyFacts.didKeepCleanupHeadlessSafetyFactsValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyAdmission(
        safetyFacts,
        admitted,
        !admitted,
        !admitted,
        safetyFacts.didRequireCleanupCoOwnershipBeforeVisibleMode,
        safetyFacts.didRequireHeadlessSafetyFailClosedRoute,
        safetyFacts.didKeepCiArtifactPolicyEvidenceOnly,
        safetyFacts.didRequireMainThreadOwnershipProofBeforeAccessorCall,
        safetyFacts.didRequireTeardownProofBeforeVisibleMode,
        safetyFacts.didKeepActualApplicationSingletonAccessorCallBlocked,
        safetyFacts.didKeepCleanupHeadlessSafetyFactsValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness(
    policyReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness,
    safetyAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyAdmission
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness {
    let admitted =
        safetyAdmission.didAdmitNsApplicationSharedApplicationCleanupHeadlessSafetyBoundary
    let safetyFacts = safetyAdmission.safetyFacts

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness(
        policyReadiness,
        safetyAdmission,
        admitted,
        !admitted,
        !admitted,
        safetyFacts.didPreserveAccessorCallContainmentPolicyReadiness,
        safetyAdmission.didConfirmCleanupCoOwnershipRequired,
        safetyAdmission.didConfirmHeadlessSafetyFailClosed,
        safetyAdmission.didConfirmCiArtifactPolicyEvidenceOnly,
        safetyAdmission.didConfirmMainThreadOwnershipProofRequired,
        safetyAdmission.didConfirmTeardownProofRequired,
        safetyFacts.didRequireNonUserVisibleMode,
        safetyAdmission.didConfirmActualAccessorCallStillBlocked,
        safetyFacts.didKeepNoApplicationSingletonAccessorCall,
        safetyFacts.didKeepApplicationSingletonCreationBlocked,
        safetyFacts.didRequireBoundedRunLoopPrerequisite,
        safetyFacts.didRequireAutoClosePrerequisite,
        safetyFacts.didKeepApplicationSideEffectBlocked,
        safetyFacts.didKeepActivationPolicyMutationBlocked,
        safetyFacts.didKeepApplicationActivationBlocked,
        safetyFacts.didKeepEventLoopBlocked,
        safetyFacts.didKeepNativeVisibleOrderImplementationBlocked,
        safetyFacts.didKeepProductionDrawablePermissionBlocked,
        safetyFacts.didKeepRenderPermissionBlocked,
        safetyFacts.didConfirmNoApplicationCreationOrActivation,
        safetyFacts.didConfirmNoPointerHandleClassIdReturn,
        safetyFacts.didConfirmNoPublicSurface,
        safetyFacts.didConfirmNoRendererStateWrite,
        safetyFacts.didConfirmNoBackendReadyTruth,
        safetyAdmission
            .didKeepNsApplicationSharedApplicationCleanupHeadlessSafetyValueOnly,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness {
    let policyReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyDraft()
    let safetyFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyFacts(
            policyReadiness
        )
    let safetyAdmission =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyAdmission(
            safetyFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness(
        policyReadiness,
        safetyAdmission
    )
}
