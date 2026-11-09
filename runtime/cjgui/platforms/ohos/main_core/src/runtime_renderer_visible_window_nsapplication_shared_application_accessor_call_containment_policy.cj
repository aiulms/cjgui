// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application accessor call containment policy value boundary owner。
// Owner: runtime renderer internal NSApplication shared-application accessor
// call containment policy owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness，
// 继续保持 actual application singleton accessor call blocked、no singleton
// accessor call、singleton creation blocked、application side effect blocked、
// activation policy / activation / event loop blocked、visible-order / drawable /
// render blocked、no public surface、no state write、no backend-ready truth facts。
// Stop-line: 不调用 application singleton accessor，不创建 NSApplication，不
// activation，不修改 activation policy，不运行 event loop，不做 native visible
// order implementation，不获取 drawable，不创建 encoder，不 draw，不提交 GPU work，
// 不执行 render，不返回 Class / id / pointer / handle，不写 runtime_state.cj，
// 不扩 public API，不新增 native bridge C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、visible-ready、
// drawable-ready、render-ready、backend-ready、renderer state write、receipt、record
// 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyFacts {
    let didPreserveAccessorCallContainmentReadiness: Bool
    let didKeepActualApplicationSingletonAccessorCallBlocked: Bool
    let didKeepNoApplicationSingletonAccessorCall: Bool
    let didKeepApplicationSingletonCreationBlocked: Bool
    let didRequireSharedApplicationMainThreadGate: Bool
    let didRequireBoundedRunLoopBeforeAccessorCallContainmentPolicy: Bool
    let didRequireAutoCloseBeforeAccessorCallContainmentPolicy: Bool
    let didRequireTeardownBeforeVisibleMode: Bool
    let didRequireNonUserVisibleMode: Bool
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
    let didKeepAccessorCallContainmentPolicyFactsValueOnly: Bool

    init(
        didPreserveAccessorCallContainmentReadiness: Bool,
        didKeepActualApplicationSingletonAccessorCallBlocked: Bool,
        didKeepNoApplicationSingletonAccessorCall: Bool,
        didKeepApplicationSingletonCreationBlocked: Bool,
        didRequireSharedApplicationMainThreadGate: Bool,
        didRequireBoundedRunLoopBeforeAccessorCallContainmentPolicy: Bool,
        didRequireAutoCloseBeforeAccessorCallContainmentPolicy: Bool,
        didRequireTeardownBeforeVisibleMode: Bool,
        didRequireNonUserVisibleMode: Bool,
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
        didKeepAccessorCallContainmentPolicyFactsValueOnly: Bool
    ) {
        this.didPreserveAccessorCallContainmentReadiness =
            didPreserveAccessorCallContainmentReadiness
        this.didKeepActualApplicationSingletonAccessorCallBlocked =
            didKeepActualApplicationSingletonAccessorCallBlocked
        this.didKeepNoApplicationSingletonAccessorCall =
            didKeepNoApplicationSingletonAccessorCall
        this.didKeepApplicationSingletonCreationBlocked =
            didKeepApplicationSingletonCreationBlocked
        this.didRequireSharedApplicationMainThreadGate =
            didRequireSharedApplicationMainThreadGate
        this.didRequireBoundedRunLoopBeforeAccessorCallContainmentPolicy =
            didRequireBoundedRunLoopBeforeAccessorCallContainmentPolicy
        this.didRequireAutoCloseBeforeAccessorCallContainmentPolicy =
            didRequireAutoCloseBeforeAccessorCallContainmentPolicy
        this.didRequireTeardownBeforeVisibleMode =
            didRequireTeardownBeforeVisibleMode
        this.didRequireNonUserVisibleMode = didRequireNonUserVisibleMode
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
        this.didKeepAccessorCallContainmentPolicyFactsValueOnly =
            didKeepAccessorCallContainmentPolicyFactsValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyAdmission {
    let policyFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyFacts
    let didAdmitNsApplicationSharedApplicationAccessorCallContainmentPolicyBoundary:
        Bool
    let shouldDeferNsApplicationSharedApplicationAccessorCallContainmentPolicyBoundary:
        Bool
    let shouldReportNsApplicationSharedApplicationAccessorCallContainmentPolicyBlocked:
        Bool
    let didConfirmApplicationSingletonAccessorCallStillBlocked: Bool
    let didConfirmNoApplicationSingletonAccessorCall: Bool
    let didConfirmApplicationSingletonCreationStillBlocked: Bool
    let didConfirmApplicationSideEffectStillBlocked: Bool
    let didConfirmNoApplicationCreationOrActivation: Bool
    let didKeepNsApplicationSharedApplicationAccessorCallContainmentPolicyValueOnly:
        Bool

    init(
        policyFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyFacts,
        didAdmitNsApplicationSharedApplicationAccessorCallContainmentPolicyBoundary:
            Bool,
        shouldDeferNsApplicationSharedApplicationAccessorCallContainmentPolicyBoundary:
            Bool,
        shouldReportNsApplicationSharedApplicationAccessorCallContainmentPolicyBlocked:
            Bool,
        didConfirmApplicationSingletonAccessorCallStillBlocked: Bool,
        didConfirmNoApplicationSingletonAccessorCall: Bool,
        didConfirmApplicationSingletonCreationStillBlocked: Bool,
        didConfirmApplicationSideEffectStillBlocked: Bool,
        didConfirmNoApplicationCreationOrActivation: Bool,
        didKeepNsApplicationSharedApplicationAccessorCallContainmentPolicyValueOnly:
            Bool
    ) {
        this.policyFacts = policyFacts
        this.didAdmitNsApplicationSharedApplicationAccessorCallContainmentPolicyBoundary =
            didAdmitNsApplicationSharedApplicationAccessorCallContainmentPolicyBoundary
        this.shouldDeferNsApplicationSharedApplicationAccessorCallContainmentPolicyBoundary =
            shouldDeferNsApplicationSharedApplicationAccessorCallContainmentPolicyBoundary
        this.shouldReportNsApplicationSharedApplicationAccessorCallContainmentPolicyBlocked =
            shouldReportNsApplicationSharedApplicationAccessorCallContainmentPolicyBlocked
        this.didConfirmApplicationSingletonAccessorCallStillBlocked =
            didConfirmApplicationSingletonAccessorCallStillBlocked
        this.didConfirmNoApplicationSingletonAccessorCall =
            didConfirmNoApplicationSingletonAccessorCall
        this.didConfirmApplicationSingletonCreationStillBlocked =
            didConfirmApplicationSingletonCreationStillBlocked
        this.didConfirmApplicationSideEffectStillBlocked =
            didConfirmApplicationSideEffectStillBlocked
        this.didConfirmNoApplicationCreationOrActivation =
            didConfirmNoApplicationCreationOrActivation
        this.didKeepNsApplicationSharedApplicationAccessorCallContainmentPolicyValueOnly =
            didKeepNsApplicationSharedApplicationAccessorCallContainmentPolicyValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness {
    let nsApplicationSharedApplicationAccessorCallContainmentReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness
    let nsApplicationSharedApplicationAccessorCallContainmentPolicyAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyAdmission
    let didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness:
        Bool
    let shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness:
        Bool
    let shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyBlocked:
        Bool
    let didPreserveNsApplicationSharedApplicationAccessorCallContainmentReadiness:
        Bool
    let didConfirmApplicationSingletonAccessorCallStillBlocked: Bool
    let didConfirmNoApplicationSingletonAccessorCall: Bool
    let didConfirmApplicationSingletonCreationStillBlocked: Bool
    let didConfirmSharedApplicationMainThreadGateRequired: Bool
    let didConfirmBoundedRunLoopPrerequisiteRequired: Bool
    let didConfirmAutoClosePrerequisiteRequired: Bool
    let didConfirmTeardownBeforeVisibleModeRequired: Bool
    let didConfirmNonUserVisibleModeRequired: Bool
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
    let didKeepNsApplicationSharedApplicationAccessorCallContainmentPolicyReadinessDehydrated:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        nsApplicationSharedApplicationAccessorCallContainmentReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness,
        nsApplicationSharedApplicationAccessorCallContainmentPolicyAdmission:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyAdmission,
        didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness:
            Bool,
        shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness:
            Bool,
        shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyBlocked:
            Bool,
        didPreserveNsApplicationSharedApplicationAccessorCallContainmentReadiness:
            Bool,
        didConfirmApplicationSingletonAccessorCallStillBlocked: Bool,
        didConfirmNoApplicationSingletonAccessorCall: Bool,
        didConfirmApplicationSingletonCreationStillBlocked: Bool,
        didConfirmSharedApplicationMainThreadGateRequired: Bool,
        didConfirmBoundedRunLoopPrerequisiteRequired: Bool,
        didConfirmAutoClosePrerequisiteRequired: Bool,
        didConfirmTeardownBeforeVisibleModeRequired: Bool,
        didConfirmNonUserVisibleModeRequired: Bool,
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
        didKeepNsApplicationSharedApplicationAccessorCallContainmentPolicyReadinessDehydrated:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.nsApplicationSharedApplicationAccessorCallContainmentReadiness =
            nsApplicationSharedApplicationAccessorCallContainmentReadiness
        this.nsApplicationSharedApplicationAccessorCallContainmentPolicyAdmission =
            nsApplicationSharedApplicationAccessorCallContainmentPolicyAdmission
        this.didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness =
            didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness
        this.shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness =
            shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness
        this.shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyBlocked =
            shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyBlocked
        this.didPreserveNsApplicationSharedApplicationAccessorCallContainmentReadiness =
            didPreserveNsApplicationSharedApplicationAccessorCallContainmentReadiness
        this.didConfirmApplicationSingletonAccessorCallStillBlocked =
            didConfirmApplicationSingletonAccessorCallStillBlocked
        this.didConfirmNoApplicationSingletonAccessorCall =
            didConfirmNoApplicationSingletonAccessorCall
        this.didConfirmApplicationSingletonCreationStillBlocked =
            didConfirmApplicationSingletonCreationStillBlocked
        this.didConfirmSharedApplicationMainThreadGateRequired =
            didConfirmSharedApplicationMainThreadGateRequired
        this.didConfirmBoundedRunLoopPrerequisiteRequired =
            didConfirmBoundedRunLoopPrerequisiteRequired
        this.didConfirmAutoClosePrerequisiteRequired =
            didConfirmAutoClosePrerequisiteRequired
        this.didConfirmTeardownBeforeVisibleModeRequired =
            didConfirmTeardownBeforeVisibleModeRequired
        this.didConfirmNonUserVisibleModeRequired =
            didConfirmNonUserVisibleModeRequired
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
        this.didKeepNsApplicationSharedApplicationAccessorCallContainmentPolicyReadinessDehydrated =
            didKeepNsApplicationSharedApplicationAccessorCallContainmentPolicyReadinessDehydrated
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyFacts(
    containmentReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyFacts(
        containmentReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness,
        containmentReadiness
            .didConfirmApplicationSingletonAccessorCallStillBlocked,
        containmentReadiness.didConfirmNoApplicationSingletonAccessorCall,
        containmentReadiness.didConfirmApplicationSingletonCreationStillBlocked,
        containmentReadiness.didConfirmSharedApplicationMainThreadGateRequired,
        containmentReadiness.didConfirmBoundedRunLoopPrerequisiteRequired,
        containmentReadiness.didConfirmAutoClosePrerequisiteRequired,
        containmentReadiness.didConfirmTeardownBeforeVisibleModeRequired,
        containmentReadiness.didConfirmNonUserVisibleModeRequired,
        containmentReadiness.didConfirmApplicationSideEffectStillBlocked,
        containmentReadiness.didConfirmActivationPolicyMutationStillBlocked,
        containmentReadiness.didConfirmApplicationActivationStillBlocked,
        containmentReadiness.didConfirmEventLoopStillBlocked,
        containmentReadiness.didConfirmNativeVisibleOrderStillBlocked,
        containmentReadiness.didConfirmProductionDrawableStillBlocked,
        containmentReadiness.didConfirmRenderStillBlocked,
        containmentReadiness.didConfirmNoApplicationCreationOrActivation,
        containmentReadiness.didConfirmNoPointerHandleClassIdReturn,
        containmentReadiness.didConfirmNoPublicSurface,
        containmentReadiness.didConfirmNoRendererStateWrite,
        containmentReadiness.didConfirmNoBackendReadyTruth,
        containmentReadiness
            .didKeepNsApplicationSharedApplicationAccessorCallContainmentReadinessDehydrated
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyAdmission(
    policyFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyAdmission {
    let admitted =
        policyFacts.didPreserveAccessorCallContainmentReadiness &&
        policyFacts.didKeepActualApplicationSingletonAccessorCallBlocked &&
        policyFacts.didKeepNoApplicationSingletonAccessorCall &&
        policyFacts.didKeepApplicationSingletonCreationBlocked &&
        policyFacts.didRequireSharedApplicationMainThreadGate &&
        policyFacts
            .didRequireBoundedRunLoopBeforeAccessorCallContainmentPolicy &&
        policyFacts.didRequireAutoCloseBeforeAccessorCallContainmentPolicy &&
        policyFacts.didRequireTeardownBeforeVisibleMode &&
        policyFacts.didRequireNonUserVisibleMode &&
        policyFacts.didKeepApplicationSideEffectBlocked &&
        policyFacts.didKeepActivationPolicyMutationBlocked &&
        policyFacts.didKeepApplicationActivationBlocked &&
        policyFacts.didKeepEventLoopBlocked &&
        policyFacts.didKeepNativeVisibleOrderImplementationBlocked &&
        policyFacts.didKeepProductionDrawablePermissionBlocked &&
        policyFacts.didKeepRenderPermissionBlocked &&
        policyFacts.didConfirmNoApplicationCreationOrActivation &&
        policyFacts.didConfirmNoPointerHandleClassIdReturn &&
        policyFacts.didConfirmNoPublicSurface &&
        policyFacts.didConfirmNoRendererStateWrite &&
        policyFacts.didConfirmNoBackendReadyTruth &&
        policyFacts.didKeepAccessorCallContainmentPolicyFactsValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyAdmission(
        policyFacts,
        admitted,
        !admitted,
        !admitted,
        policyFacts.didKeepActualApplicationSingletonAccessorCallBlocked,
        policyFacts.didKeepNoApplicationSingletonAccessorCall,
        policyFacts.didKeepApplicationSingletonCreationBlocked,
        policyFacts.didKeepApplicationSideEffectBlocked,
        policyFacts.didConfirmNoApplicationCreationOrActivation,
        policyFacts.didKeepAccessorCallContainmentPolicyFactsValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness(
    containmentReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness,
    policyAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyAdmission
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness {
    let admitted =
        policyAdmission
            .didAdmitNsApplicationSharedApplicationAccessorCallContainmentPolicyBoundary

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness(
        containmentReadiness,
        policyAdmission,
        admitted,
        !admitted,
        !admitted,
        policyAdmission.policyFacts.didPreserveAccessorCallContainmentReadiness,
        policyAdmission.didConfirmApplicationSingletonAccessorCallStillBlocked,
        policyAdmission.didConfirmNoApplicationSingletonAccessorCall,
        policyAdmission.didConfirmApplicationSingletonCreationStillBlocked,
        policyAdmission.policyFacts.didRequireSharedApplicationMainThreadGate,
        policyAdmission.policyFacts
            .didRequireBoundedRunLoopBeforeAccessorCallContainmentPolicy,
        policyAdmission.policyFacts
            .didRequireAutoCloseBeforeAccessorCallContainmentPolicy,
        policyAdmission.policyFacts.didRequireTeardownBeforeVisibleMode,
        policyAdmission.policyFacts.didRequireNonUserVisibleMode,
        policyAdmission.didConfirmApplicationSideEffectStillBlocked,
        policyAdmission.policyFacts.didKeepActivationPolicyMutationBlocked,
        policyAdmission.policyFacts.didKeepApplicationActivationBlocked,
        policyAdmission.policyFacts.didKeepEventLoopBlocked,
        policyAdmission.policyFacts
            .didKeepNativeVisibleOrderImplementationBlocked,
        policyAdmission.policyFacts.didKeepProductionDrawablePermissionBlocked,
        policyAdmission.policyFacts.didKeepRenderPermissionBlocked,
        policyAdmission.didConfirmNoApplicationCreationOrActivation,
        policyAdmission.policyFacts.didConfirmNoPointerHandleClassIdReturn,
        policyAdmission.policyFacts.didConfirmNoPublicSurface,
        policyAdmission.policyFacts.didConfirmNoRendererStateWrite,
        policyAdmission.policyFacts.didConfirmNoBackendReadyTruth,
        policyAdmission
            .didKeepNsApplicationSharedApplicationAccessorCallContainmentPolicyValueOnly,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness {
    let containmentReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentDraft()
    let policyFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyFacts(
            containmentReadiness
        )
    let policyAdmission =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyAdmission(
            policyFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness(
        containmentReadiness,
        policyAdmission
    )
}
