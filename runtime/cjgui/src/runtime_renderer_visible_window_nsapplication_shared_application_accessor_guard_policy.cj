// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application accessor guard policy value boundary owner。
// Owner: runtime renderer internal NSApplication shared-application accessor
// guard policy owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness，
// 固定 accessor call / accessor scope / singleton creation 仍 blocked、main-thread
// gate、bounded run loop、auto-close、teardown / non-user-visible mode、activation
// policy / activation / event loop blocked、visible-order / drawable / render
// still-blocked facts。
// Stop-line: 不调用 application singleton accessor，不创建 NSApplication，不
// activation，不修改 activation policy，不运行 event loop，不做 native visible
// order implementation，不获取 drawable，不创建 encoder，不 draw，不提交 GPU work，
// 不执行 render，不返回 Class / id / pointer / handle，不写 runtime_state.cj，
// 不扩 public API，不新增 native bridge C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、visible-ready、
// drawable-ready、render-ready、backend-ready、renderer state write、receipt、record
// 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyFacts {
    let didKeepApplicationSingletonAccessorCallBlocked: Bool
    let didKeepApplicationSingletonAccessorScopeBlocked: Bool
    let didKeepApplicationSingletonCreationBlocked: Bool
    let didRequireSharedApplicationMainThreadGate: Bool
    let didRequireBoundedRunLoopBeforeAccessorGuardPolicy: Bool
    let didRequireAutoCloseBeforeAccessorGuardPolicy: Bool
    let didKeepHeadlessCiFailClosedRoute: Bool
    let didRequireTeardownBeforeVisibleMode: Bool
    let didRequireNonUserVisibleMode: Bool
    let didKeepActivationPolicyMutationBlocked: Bool
    let didKeepApplicationActivationBlocked: Bool
    let didKeepEventLoopBlocked: Bool
    let didKeepNativeVisibleOrderImplementationBlocked: Bool
    let didKeepProductionDrawablePermissionBlocked: Bool
    let didKeepRenderPermissionBlocked: Bool
    let didConfirmNoApplicationSingletonAccessorCall: Bool
    let didConfirmNoApplicationCreationOrActivation: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepAccessorGuardPolicyFactsValueOnly: Bool

    init(
        didKeepApplicationSingletonAccessorCallBlocked: Bool,
        didKeepApplicationSingletonAccessorScopeBlocked: Bool,
        didKeepApplicationSingletonCreationBlocked: Bool,
        didRequireSharedApplicationMainThreadGate: Bool,
        didRequireBoundedRunLoopBeforeAccessorGuardPolicy: Bool,
        didRequireAutoCloseBeforeAccessorGuardPolicy: Bool,
        didKeepHeadlessCiFailClosedRoute: Bool,
        didRequireTeardownBeforeVisibleMode: Bool,
        didRequireNonUserVisibleMode: Bool,
        didKeepActivationPolicyMutationBlocked: Bool,
        didKeepApplicationActivationBlocked: Bool,
        didKeepEventLoopBlocked: Bool,
        didKeepNativeVisibleOrderImplementationBlocked: Bool,
        didKeepProductionDrawablePermissionBlocked: Bool,
        didKeepRenderPermissionBlocked: Bool,
        didConfirmNoApplicationSingletonAccessorCall: Bool,
        didConfirmNoApplicationCreationOrActivation: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepAccessorGuardPolicyFactsValueOnly: Bool
    ) {
        this.didKeepApplicationSingletonAccessorCallBlocked =
            didKeepApplicationSingletonAccessorCallBlocked
        this.didKeepApplicationSingletonAccessorScopeBlocked =
            didKeepApplicationSingletonAccessorScopeBlocked
        this.didKeepApplicationSingletonCreationBlocked =
            didKeepApplicationSingletonCreationBlocked
        this.didRequireSharedApplicationMainThreadGate =
            didRequireSharedApplicationMainThreadGate
        this.didRequireBoundedRunLoopBeforeAccessorGuardPolicy =
            didRequireBoundedRunLoopBeforeAccessorGuardPolicy
        this.didRequireAutoCloseBeforeAccessorGuardPolicy =
            didRequireAutoCloseBeforeAccessorGuardPolicy
        this.didKeepHeadlessCiFailClosedRoute =
            didKeepHeadlessCiFailClosedRoute
        this.didRequireTeardownBeforeVisibleMode =
            didRequireTeardownBeforeVisibleMode
        this.didRequireNonUserVisibleMode = didRequireNonUserVisibleMode
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
        this.didConfirmNoApplicationSingletonAccessorCall =
            didConfirmNoApplicationSingletonAccessorCall
        this.didConfirmNoApplicationCreationOrActivation =
            didConfirmNoApplicationCreationOrActivation
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepAccessorGuardPolicyFactsValueOnly =
            didKeepAccessorGuardPolicyFactsValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyAdmission {
    let policyFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyFacts
    let didAdmitNsApplicationSharedApplicationAccessorGuardPolicyBoundary:
        Bool
    let shouldDeferNsApplicationSharedApplicationAccessorGuardPolicyBoundary:
        Bool
    let shouldReportNsApplicationSharedApplicationAccessorGuardPolicyBlocked:
        Bool
    let didConfirmApplicationSingletonAccessorCallStillBlocked: Bool
    let didConfirmApplicationSingletonAccessorScopeStillBlocked: Bool
    let didConfirmApplicationSingletonCreationStillBlocked: Bool
    let didConfirmSharedApplicationMainThreadGateRequired: Bool
    let didConfirmBoundedRunLoopPrerequisiteRequired: Bool
    let didConfirmAutoClosePrerequisiteRequired: Bool
    let didConfirmHeadlessCiFailClosedRoute: Bool
    let didConfirmTeardownBeforeVisibleModeRequired: Bool
    let didConfirmNonUserVisibleModeRequired: Bool
    let didConfirmActivationPolicyMutationStillBlocked: Bool
    let didConfirmApplicationActivationStillBlocked: Bool
    let didConfirmEventLoopStillBlocked: Bool
    let didConfirmNativeVisibleOrderStillBlocked: Bool
    let didConfirmProductionDrawableStillBlocked: Bool
    let didConfirmRenderStillBlocked: Bool
    let didConfirmNoApplicationSingletonAccessorCall: Bool
    let didKeepNsApplicationSharedApplicationAccessorGuardPolicyValueOnly:
        Bool

    init(
        policyFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyFacts,
        didAdmitNsApplicationSharedApplicationAccessorGuardPolicyBoundary:
            Bool,
        shouldDeferNsApplicationSharedApplicationAccessorGuardPolicyBoundary:
            Bool,
        shouldReportNsApplicationSharedApplicationAccessorGuardPolicyBlocked:
            Bool,
        didConfirmApplicationSingletonAccessorCallStillBlocked: Bool,
        didConfirmApplicationSingletonAccessorScopeStillBlocked: Bool,
        didConfirmApplicationSingletonCreationStillBlocked: Bool,
        didConfirmSharedApplicationMainThreadGateRequired: Bool,
        didConfirmBoundedRunLoopPrerequisiteRequired: Bool,
        didConfirmAutoClosePrerequisiteRequired: Bool,
        didConfirmHeadlessCiFailClosedRoute: Bool,
        didConfirmTeardownBeforeVisibleModeRequired: Bool,
        didConfirmNonUserVisibleModeRequired: Bool,
        didConfirmActivationPolicyMutationStillBlocked: Bool,
        didConfirmApplicationActivationStillBlocked: Bool,
        didConfirmEventLoopStillBlocked: Bool,
        didConfirmNativeVisibleOrderStillBlocked: Bool,
        didConfirmProductionDrawableStillBlocked: Bool,
        didConfirmRenderStillBlocked: Bool,
        didConfirmNoApplicationSingletonAccessorCall: Bool,
        didKeepNsApplicationSharedApplicationAccessorGuardPolicyValueOnly:
            Bool
    ) {
        this.policyFacts = policyFacts
        this.didAdmitNsApplicationSharedApplicationAccessorGuardPolicyBoundary =
            didAdmitNsApplicationSharedApplicationAccessorGuardPolicyBoundary
        this.shouldDeferNsApplicationSharedApplicationAccessorGuardPolicyBoundary =
            shouldDeferNsApplicationSharedApplicationAccessorGuardPolicyBoundary
        this.shouldReportNsApplicationSharedApplicationAccessorGuardPolicyBlocked =
            shouldReportNsApplicationSharedApplicationAccessorGuardPolicyBlocked
        this.didConfirmApplicationSingletonAccessorCallStillBlocked =
            didConfirmApplicationSingletonAccessorCallStillBlocked
        this.didConfirmApplicationSingletonAccessorScopeStillBlocked =
            didConfirmApplicationSingletonAccessorScopeStillBlocked
        this.didConfirmApplicationSingletonCreationStillBlocked =
            didConfirmApplicationSingletonCreationStillBlocked
        this.didConfirmSharedApplicationMainThreadGateRequired =
            didConfirmSharedApplicationMainThreadGateRequired
        this.didConfirmBoundedRunLoopPrerequisiteRequired =
            didConfirmBoundedRunLoopPrerequisiteRequired
        this.didConfirmAutoClosePrerequisiteRequired =
            didConfirmAutoClosePrerequisiteRequired
        this.didConfirmHeadlessCiFailClosedRoute =
            didConfirmHeadlessCiFailClosedRoute
        this.didConfirmTeardownBeforeVisibleModeRequired =
            didConfirmTeardownBeforeVisibleModeRequired
        this.didConfirmNonUserVisibleModeRequired =
            didConfirmNonUserVisibleModeRequired
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
        this.didConfirmNoApplicationSingletonAccessorCall =
            didConfirmNoApplicationSingletonAccessorCall
        this.didKeepNsApplicationSharedApplicationAccessorGuardPolicyValueOnly =
            didKeepNsApplicationSharedApplicationAccessorGuardPolicyValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness {
    let nsApplicationSharedApplicationAccessorNativeGuardReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness
    let nsApplicationSharedApplicationAccessorGuardPolicyAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyAdmission
    let didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness:
        Bool
    let shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness:
        Bool
    let shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyBlocked:
        Bool
    let didPreserveNsApplicationSharedApplicationAccessorNativeGuardReadiness:
        Bool
    let didConfirmApplicationSingletonAccessorCallStillBlocked: Bool
    let didConfirmApplicationSingletonAccessorScopeStillBlocked: Bool
    let didConfirmApplicationSingletonCreationStillBlocked: Bool
    let didConfirmSharedApplicationMainThreadGateRequired: Bool
    let didConfirmBoundedRunLoopPrerequisiteRequired: Bool
    let didConfirmAutoClosePrerequisiteRequired: Bool
    let didConfirmHeadlessCiFailClosedRoute: Bool
    let didConfirmTeardownBeforeVisibleModeRequired: Bool
    let didConfirmNonUserVisibleModeRequired: Bool
    let didConfirmActivationPolicyMutationStillBlocked: Bool
    let didConfirmApplicationActivationStillBlocked: Bool
    let didConfirmEventLoopStillBlocked: Bool
    let didConfirmNativeVisibleOrderStillBlocked: Bool
    let didConfirmProductionDrawableStillBlocked: Bool
    let didConfirmRenderStillBlocked: Bool
    let didConfirmNoApplicationSingletonAccessorCall: Bool
    let didConfirmNoApplicationCreationOrActivation: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNsApplicationSharedApplicationAccessorGuardPolicyReadinessDehydrated:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        nsApplicationSharedApplicationAccessorNativeGuardReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness,
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyAdmission,
        didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness:
            Bool,
        shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness:
            Bool,
        shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyBlocked:
            Bool,
        didPreserveNsApplicationSharedApplicationAccessorNativeGuardReadiness:
            Bool,
        didConfirmApplicationSingletonAccessorCallStillBlocked: Bool,
        didConfirmApplicationSingletonAccessorScopeStillBlocked: Bool,
        didConfirmApplicationSingletonCreationStillBlocked: Bool,
        didConfirmSharedApplicationMainThreadGateRequired: Bool,
        didConfirmBoundedRunLoopPrerequisiteRequired: Bool,
        didConfirmAutoClosePrerequisiteRequired: Bool,
        didConfirmHeadlessCiFailClosedRoute: Bool,
        didConfirmTeardownBeforeVisibleModeRequired: Bool,
        didConfirmNonUserVisibleModeRequired: Bool,
        didConfirmActivationPolicyMutationStillBlocked: Bool,
        didConfirmApplicationActivationStillBlocked: Bool,
        didConfirmEventLoopStillBlocked: Bool,
        didConfirmNativeVisibleOrderStillBlocked: Bool,
        didConfirmProductionDrawableStillBlocked: Bool,
        didConfirmRenderStillBlocked: Bool,
        didConfirmNoApplicationSingletonAccessorCall: Bool,
        didConfirmNoApplicationCreationOrActivation: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNsApplicationSharedApplicationAccessorGuardPolicyReadinessDehydrated:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.nsApplicationSharedApplicationAccessorNativeGuardReadiness =
            nsApplicationSharedApplicationAccessorNativeGuardReadiness
        this.nsApplicationSharedApplicationAccessorGuardPolicyAdmission =
            nsApplicationSharedApplicationAccessorGuardPolicyAdmission
        this.didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness =
            didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness
        this.shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness =
            shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness
        this.shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyBlocked =
            shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyBlocked
        this.didPreserveNsApplicationSharedApplicationAccessorNativeGuardReadiness =
            didPreserveNsApplicationSharedApplicationAccessorNativeGuardReadiness
        this.didConfirmApplicationSingletonAccessorCallStillBlocked =
            didConfirmApplicationSingletonAccessorCallStillBlocked
        this.didConfirmApplicationSingletonAccessorScopeStillBlocked =
            didConfirmApplicationSingletonAccessorScopeStillBlocked
        this.didConfirmApplicationSingletonCreationStillBlocked =
            didConfirmApplicationSingletonCreationStillBlocked
        this.didConfirmSharedApplicationMainThreadGateRequired =
            didConfirmSharedApplicationMainThreadGateRequired
        this.didConfirmBoundedRunLoopPrerequisiteRequired =
            didConfirmBoundedRunLoopPrerequisiteRequired
        this.didConfirmAutoClosePrerequisiteRequired =
            didConfirmAutoClosePrerequisiteRequired
        this.didConfirmHeadlessCiFailClosedRoute =
            didConfirmHeadlessCiFailClosedRoute
        this.didConfirmTeardownBeforeVisibleModeRequired =
            didConfirmTeardownBeforeVisibleModeRequired
        this.didConfirmNonUserVisibleModeRequired =
            didConfirmNonUserVisibleModeRequired
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
        this.didConfirmNoApplicationSingletonAccessorCall =
            didConfirmNoApplicationSingletonAccessorCall
        this.didConfirmNoApplicationCreationOrActivation =
            didConfirmNoApplicationCreationOrActivation
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNsApplicationSharedApplicationAccessorGuardPolicyReadinessDehydrated =
            didKeepNsApplicationSharedApplicationAccessorGuardPolicyReadinessDehydrated
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyFacts(
    nsApplicationSharedApplicationAccessorNativeGuardReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyFacts {
    let upstreamReady =
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmApplicationSingletonAccessorCallStillBlocked &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmApplicationSingletonAccessorScopeStillBlocked &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmApplicationSingletonCreationStillBlocked &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmSharedApplicationMainThreadGateRequired &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmBoundedRunLoopPrerequisiteRequired &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmAutoClosePrerequisiteRequired &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmHeadlessCiFailClosedRoute &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmTeardownBeforeVisibleModeRequired &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmNonUserVisibleModeRequired &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmActivationPolicyMutationStillBlocked &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmApplicationActivationStillBlocked &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmEventLoopStillBlocked &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmNativeVisibleOrderStillBlocked &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmProductionDrawableStillBlocked &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmRenderStillBlocked &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmNoApplicationSingletonAccessorCall &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmNoApplicationCreationOrActivation &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmNoPointerHandleClassIdReturn &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmNoPublicSurface &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmNoRendererStateWrite &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmNoBackendReadyTruth &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didKeepNsApplicationSharedApplicationAccessorNativeGuardReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyFacts(
        upstreamReady,
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmApplicationSingletonAccessorScopeStillBlocked,
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmApplicationSingletonCreationStillBlocked,
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmSharedApplicationMainThreadGateRequired,
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmBoundedRunLoopPrerequisiteRequired,
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmAutoClosePrerequisiteRequired,
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmHeadlessCiFailClosedRoute,
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmTeardownBeforeVisibleModeRequired,
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmNonUserVisibleModeRequired,
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmActivationPolicyMutationStillBlocked,
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmApplicationActivationStillBlocked,
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmEventLoopStillBlocked,
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmNativeVisibleOrderStillBlocked,
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmProductionDrawableStillBlocked,
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmRenderStillBlocked,
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmNoApplicationSingletonAccessorCall,
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmNoApplicationCreationOrActivation,
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmNoPointerHandleClassIdReturn,
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmNoPublicSurface,
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmNoRendererStateWrite,
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmNoBackendReadyTruth,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyAdmission(
    policyFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyAdmission {
    let didAdmit =
        policyFacts.didKeepApplicationSingletonAccessorCallBlocked &&
        policyFacts.didKeepApplicationSingletonAccessorScopeBlocked &&
        policyFacts.didKeepApplicationSingletonCreationBlocked &&
        policyFacts.didRequireSharedApplicationMainThreadGate &&
        policyFacts.didRequireBoundedRunLoopBeforeAccessorGuardPolicy &&
        policyFacts.didRequireAutoCloseBeforeAccessorGuardPolicy &&
        policyFacts.didKeepHeadlessCiFailClosedRoute &&
        policyFacts.didRequireTeardownBeforeVisibleMode &&
        policyFacts.didRequireNonUserVisibleMode &&
        policyFacts.didKeepActivationPolicyMutationBlocked &&
        policyFacts.didKeepApplicationActivationBlocked &&
        policyFacts.didKeepEventLoopBlocked &&
        policyFacts.didKeepNativeVisibleOrderImplementationBlocked &&
        policyFacts.didKeepProductionDrawablePermissionBlocked &&
        policyFacts.didKeepRenderPermissionBlocked &&
        policyFacts.didConfirmNoApplicationSingletonAccessorCall &&
        policyFacts.didConfirmNoApplicationCreationOrActivation &&
        policyFacts.didConfirmNoPointerHandleClassIdReturn &&
        policyFacts.didConfirmNoPublicSurface &&
        policyFacts.didConfirmNoRendererStateWrite &&
        policyFacts.didConfirmNoBackendReadyTruth &&
        policyFacts.didKeepAccessorGuardPolicyFactsValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyAdmission(
        policyFacts,
        didAdmit,
        !didAdmit,
        !didAdmit,
        policyFacts.didKeepApplicationSingletonAccessorCallBlocked,
        policyFacts.didKeepApplicationSingletonAccessorScopeBlocked,
        policyFacts.didKeepApplicationSingletonCreationBlocked,
        policyFacts.didRequireSharedApplicationMainThreadGate,
        policyFacts.didRequireBoundedRunLoopBeforeAccessorGuardPolicy,
        policyFacts.didRequireAutoCloseBeforeAccessorGuardPolicy,
        policyFacts.didKeepHeadlessCiFailClosedRoute,
        policyFacts.didRequireTeardownBeforeVisibleMode,
        policyFacts.didRequireNonUserVisibleMode,
        policyFacts.didKeepActivationPolicyMutationBlocked,
        policyFacts.didKeepApplicationActivationBlocked,
        policyFacts.didKeepEventLoopBlocked,
        policyFacts.didKeepNativeVisibleOrderImplementationBlocked,
        policyFacts.didKeepProductionDrawablePermissionBlocked,
        policyFacts.didKeepRenderPermissionBlocked,
        policyFacts.didConfirmNoApplicationSingletonAccessorCall,
        policyFacts.didKeepAccessorGuardPolicyFactsValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness(
    nsApplicationSharedApplicationAccessorNativeGuardReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness,
    nsApplicationSharedApplicationAccessorGuardPolicyAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyAdmission
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness {
    let upstreamReady =
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmNoRendererStateWrite &&
        nsApplicationSharedApplicationAccessorNativeGuardReadiness
            .didConfirmNoBackendReadyTruth
    let admissionReady =
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didAdmitNsApplicationSharedApplicationAccessorGuardPolicyBoundary &&
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmApplicationSingletonAccessorCallStillBlocked &&
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmApplicationSingletonAccessorScopeStillBlocked &&
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmApplicationSingletonCreationStillBlocked &&
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmSharedApplicationMainThreadGateRequired &&
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmBoundedRunLoopPrerequisiteRequired &&
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmAutoClosePrerequisiteRequired &&
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmHeadlessCiFailClosedRoute &&
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmTeardownBeforeVisibleModeRequired &&
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmNonUserVisibleModeRequired &&
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmActivationPolicyMutationStillBlocked &&
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmApplicationActivationStillBlocked &&
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmEventLoopStillBlocked &&
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmNativeVisibleOrderStillBlocked &&
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmProductionDrawableStillBlocked &&
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmRenderStillBlocked &&
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmNoApplicationSingletonAccessorCall &&
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didKeepNsApplicationSharedApplicationAccessorGuardPolicyValueOnly
    let readinessReady = upstreamReady && admissionReady
    let policyFacts = nsApplicationSharedApplicationAccessorGuardPolicyAdmission
        .policyFacts

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness(
        nsApplicationSharedApplicationAccessorNativeGuardReadiness,
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmApplicationSingletonAccessorCallStillBlocked,
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmApplicationSingletonAccessorScopeStillBlocked,
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmApplicationSingletonCreationStillBlocked,
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmSharedApplicationMainThreadGateRequired,
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmBoundedRunLoopPrerequisiteRequired,
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmAutoClosePrerequisiteRequired,
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmHeadlessCiFailClosedRoute,
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmTeardownBeforeVisibleModeRequired,
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmNonUserVisibleModeRequired,
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmActivationPolicyMutationStillBlocked,
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmApplicationActivationStillBlocked,
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmEventLoopStillBlocked,
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmNativeVisibleOrderStillBlocked,
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmProductionDrawableStillBlocked,
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmRenderStillBlocked,
        nsApplicationSharedApplicationAccessorGuardPolicyAdmission
            .didConfirmNoApplicationSingletonAccessorCall,
        policyFacts.didConfirmNoApplicationCreationOrActivation,
        policyFacts.didConfirmNoPointerHandleClassIdReturn,
        policyFacts.didConfirmNoPublicSurface,
        policyFacts.didConfirmNoRendererStateWrite,
        policyFacts.didConfirmNoBackendReadyTruth,
        policyFacts.didKeepAccessorGuardPolicyFactsValueOnly,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness {
    let accessorNativeGuardReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardDraft()
    let policyFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyFacts(
            accessorNativeGuardReadiness
        )
    let policyAdmission =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyAdmission(
            policyFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness(
        accessorNativeGuardReadiness,
        policyAdmission
    )
}
