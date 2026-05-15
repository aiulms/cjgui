// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application guard policy value boundary owner。
// Owner: runtime renderer internal NSApplication shared-application guard policy
// owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationNativeGuardReadiness，
// 固定 application singleton accessor / creation 仍 blocked、main-thread gate、
// bounded run loop、auto-close、teardown / non-user-visible mode、activation
// policy / activation / event loop blocked、visible-order / drawable / render
// still-blocked facts。
// Stop-line: 不调用 application singleton accessor，不创建 NSApplication，不
// activation，不修改 activation policy，不运行 event loop，不做 native visible
// order implementation，不获取 drawable，不创建 encoder，不 draw，不提交 GPU work，
// 不执行 render，不返回 Class / id / pointer / handle，不写 runtime_state.cj，
// 不扩 public API。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、visible-ready、
// drawable-ready、render-ready、backend-ready、renderer state write、receipt、record
// 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyFacts {
    let didKeepApplicationSingletonAccessorBlocked: Bool
    let didKeepApplicationSingletonCreationBlocked: Bool
    let didRequireSharedApplicationMainThreadGate: Bool
    let didRequireBoundedRunLoopBeforeSharedApplicationAccess: Bool
    let didRequireAutoCloseBeforeVisibleMode: Bool
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
    let didKeepGuardPolicyFactsValueOnly: Bool

    init(
        didKeepApplicationSingletonAccessorBlocked: Bool,
        didKeepApplicationSingletonCreationBlocked: Bool,
        didRequireSharedApplicationMainThreadGate: Bool,
        didRequireBoundedRunLoopBeforeSharedApplicationAccess: Bool,
        didRequireAutoCloseBeforeVisibleMode: Bool,
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
        didKeepGuardPolicyFactsValueOnly: Bool
    ) {
        this.didKeepApplicationSingletonAccessorBlocked =
            didKeepApplicationSingletonAccessorBlocked
        this.didKeepApplicationSingletonCreationBlocked =
            didKeepApplicationSingletonCreationBlocked
        this.didRequireSharedApplicationMainThreadGate =
            didRequireSharedApplicationMainThreadGate
        this.didRequireBoundedRunLoopBeforeSharedApplicationAccess =
            didRequireBoundedRunLoopBeforeSharedApplicationAccess
        this.didRequireAutoCloseBeforeVisibleMode =
            didRequireAutoCloseBeforeVisibleMode
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
        this.didKeepGuardPolicyFactsValueOnly =
            didKeepGuardPolicyFactsValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyAdmission {
    let policyFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyFacts
    let didAdmitNsApplicationSharedApplicationGuardPolicyBoundary: Bool
    let shouldDeferNsApplicationSharedApplicationGuardPolicyBoundary: Bool
    let shouldReportNsApplicationSharedApplicationGuardPolicyBlocked: Bool
    let didConfirmApplicationSingletonAccessorStillBlocked: Bool
    let didConfirmApplicationSingletonCreationStillBlocked: Bool
    let didConfirmSharedApplicationMainThreadGateRequired: Bool
    let didConfirmBoundedRunLoopPrerequisiteRequired: Bool
    let didConfirmAutoClosePrerequisiteRequired: Bool
    let didKeepHeadlessCiFailClosedRoute: Bool
    let didConfirmTeardownBeforeVisibleModeRequired: Bool
    let didConfirmNonUserVisibleModeRequired: Bool
    let didConfirmActivationPolicyMutationStillBlocked: Bool
    let didConfirmApplicationActivationStillBlocked: Bool
    let didConfirmEventLoopStillBlocked: Bool
    let didConfirmNativeVisibleOrderStillBlocked: Bool
    let didConfirmProductionDrawableStillBlocked: Bool
    let didConfirmRenderStillBlocked: Bool
    let didConfirmNoApplicationSingletonAccessorCall: Bool
    let didKeepNsApplicationSharedApplicationGuardPolicyValueOnly: Bool

    init(
        policyFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyFacts,
        didAdmitNsApplicationSharedApplicationGuardPolicyBoundary: Bool,
        shouldDeferNsApplicationSharedApplicationGuardPolicyBoundary: Bool,
        shouldReportNsApplicationSharedApplicationGuardPolicyBlocked: Bool,
        didConfirmApplicationSingletonAccessorStillBlocked: Bool,
        didConfirmApplicationSingletonCreationStillBlocked: Bool,
        didConfirmSharedApplicationMainThreadGateRequired: Bool,
        didConfirmBoundedRunLoopPrerequisiteRequired: Bool,
        didConfirmAutoClosePrerequisiteRequired: Bool,
        didKeepHeadlessCiFailClosedRoute: Bool,
        didConfirmTeardownBeforeVisibleModeRequired: Bool,
        didConfirmNonUserVisibleModeRequired: Bool,
        didConfirmActivationPolicyMutationStillBlocked: Bool,
        didConfirmApplicationActivationStillBlocked: Bool,
        didConfirmEventLoopStillBlocked: Bool,
        didConfirmNativeVisibleOrderStillBlocked: Bool,
        didConfirmProductionDrawableStillBlocked: Bool,
        didConfirmRenderStillBlocked: Bool,
        didConfirmNoApplicationSingletonAccessorCall: Bool,
        didKeepNsApplicationSharedApplicationGuardPolicyValueOnly: Bool
    ) {
        this.policyFacts = policyFacts
        this.didAdmitNsApplicationSharedApplicationGuardPolicyBoundary =
            didAdmitNsApplicationSharedApplicationGuardPolicyBoundary
        this.shouldDeferNsApplicationSharedApplicationGuardPolicyBoundary =
            shouldDeferNsApplicationSharedApplicationGuardPolicyBoundary
        this.shouldReportNsApplicationSharedApplicationGuardPolicyBlocked =
            shouldReportNsApplicationSharedApplicationGuardPolicyBlocked
        this.didConfirmApplicationSingletonAccessorStillBlocked =
            didConfirmApplicationSingletonAccessorStillBlocked
        this.didConfirmApplicationSingletonCreationStillBlocked =
            didConfirmApplicationSingletonCreationStillBlocked
        this.didConfirmSharedApplicationMainThreadGateRequired =
            didConfirmSharedApplicationMainThreadGateRequired
        this.didConfirmBoundedRunLoopPrerequisiteRequired =
            didConfirmBoundedRunLoopPrerequisiteRequired
        this.didConfirmAutoClosePrerequisiteRequired =
            didConfirmAutoClosePrerequisiteRequired
        this.didKeepHeadlessCiFailClosedRoute =
            didKeepHeadlessCiFailClosedRoute
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
        this.didKeepNsApplicationSharedApplicationGuardPolicyValueOnly =
            didKeepNsApplicationSharedApplicationGuardPolicyValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness {
    let nsApplicationSharedApplicationNativeGuardReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationNativeGuardReadiness
    let nsApplicationSharedApplicationGuardPolicyAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyAdmission
    let didPrepareRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness:
        Bool
    let shouldDeferRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness:
        Bool
    let shouldReportRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyBlocked:
        Bool
    let didPreserveNsApplicationSharedApplicationNativeGuardReadiness: Bool
    let didConfirmApplicationSingletonAccessorStillBlocked: Bool
    let didConfirmApplicationSingletonCreationStillBlocked: Bool
    let didConfirmSharedApplicationMainThreadGateRequired: Bool
    let didConfirmBoundedRunLoopPrerequisiteRequired: Bool
    let didConfirmAutoClosePrerequisiteRequired: Bool
    let didKeepHeadlessCiFailClosedRoute: Bool
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
    let didKeepNsApplicationSharedApplicationGuardPolicyReadinessDehydrated:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        nsApplicationSharedApplicationNativeGuardReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationNativeGuardReadiness,
        nsApplicationSharedApplicationGuardPolicyAdmission:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyAdmission,
        didPrepareRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness:
            Bool,
        shouldDeferRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness:
            Bool,
        shouldReportRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyBlocked:
            Bool,
        didPreserveNsApplicationSharedApplicationNativeGuardReadiness: Bool,
        didConfirmApplicationSingletonAccessorStillBlocked: Bool,
        didConfirmApplicationSingletonCreationStillBlocked: Bool,
        didConfirmSharedApplicationMainThreadGateRequired: Bool,
        didConfirmBoundedRunLoopPrerequisiteRequired: Bool,
        didConfirmAutoClosePrerequisiteRequired: Bool,
        didKeepHeadlessCiFailClosedRoute: Bool,
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
        didKeepNsApplicationSharedApplicationGuardPolicyReadinessDehydrated:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.nsApplicationSharedApplicationNativeGuardReadiness =
            nsApplicationSharedApplicationNativeGuardReadiness
        this.nsApplicationSharedApplicationGuardPolicyAdmission =
            nsApplicationSharedApplicationGuardPolicyAdmission
        this.didPrepareRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness =
            didPrepareRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness
        this.shouldDeferRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness =
            shouldDeferRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness
        this.shouldReportRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyBlocked =
            shouldReportRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyBlocked
        this.didPreserveNsApplicationSharedApplicationNativeGuardReadiness =
            didPreserveNsApplicationSharedApplicationNativeGuardReadiness
        this.didConfirmApplicationSingletonAccessorStillBlocked =
            didConfirmApplicationSingletonAccessorStillBlocked
        this.didConfirmApplicationSingletonCreationStillBlocked =
            didConfirmApplicationSingletonCreationStillBlocked
        this.didConfirmSharedApplicationMainThreadGateRequired =
            didConfirmSharedApplicationMainThreadGateRequired
        this.didConfirmBoundedRunLoopPrerequisiteRequired =
            didConfirmBoundedRunLoopPrerequisiteRequired
        this.didConfirmAutoClosePrerequisiteRequired =
            didConfirmAutoClosePrerequisiteRequired
        this.didKeepHeadlessCiFailClosedRoute =
            didKeepHeadlessCiFailClosedRoute
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
        this.didKeepNsApplicationSharedApplicationGuardPolicyReadinessDehydrated =
            didKeepNsApplicationSharedApplicationGuardPolicyReadinessDehydrated
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyFacts(
    nsApplicationSharedApplicationNativeGuardReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationNativeGuardReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyFacts {
    let upstreamReady =
        nsApplicationSharedApplicationNativeGuardReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationNativeGuardReadiness &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmApplicationSingletonAccessorStillBlocked &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmApplicationSingletonCreationStillBlocked &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmMainThreadAffinityRequired &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmBoundedRunLoopPrerequisiteRequired &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmAutoClosePrerequisiteRequired &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmHeadlessCiFailClosedRoute &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmTeardownBeforeVisibleModeRequired &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmNonUserVisibleModeRequired &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmActivationPolicyMutationStillBlocked &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmApplicationActivationStillBlocked &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmEventLoopStillBlocked &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmNativeVisibleOrderStillBlocked &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmProductionDrawableStillBlocked &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmRenderStillBlocked &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmNoApplicationCreationOrActivation &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmNoPointerHandleClassIdReturn &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmNoPublicSurface &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmNoRendererStateWrite &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmNoBackendReadyTruth &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didKeepNsApplicationSharedApplicationNativeGuardReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyFacts(
        upstreamReady,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmHeadlessCiFailClosedRoute,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmNativeVisibleOrderStillBlocked,
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmProductionDrawableStillBlocked,
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmRenderStillBlocked,
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmApplicationSingletonAccessorStillBlocked,
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmNoApplicationCreationOrActivation,
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmNoPointerHandleClassIdReturn,
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmNoPublicSurface,
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmNoRendererStateWrite,
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmNoBackendReadyTruth,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyAdmission(
    policyFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyAdmission {
    let didAdmit =
        policyFacts.didKeepApplicationSingletonAccessorBlocked &&
        policyFacts.didKeepApplicationSingletonCreationBlocked &&
        policyFacts.didRequireSharedApplicationMainThreadGate &&
        policyFacts.didRequireBoundedRunLoopBeforeSharedApplicationAccess &&
        policyFacts.didRequireAutoCloseBeforeVisibleMode &&
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
        policyFacts.didKeepGuardPolicyFactsValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyAdmission(
        policyFacts,
        didAdmit,
        !didAdmit,
        !didAdmit,
        policyFacts.didKeepApplicationSingletonAccessorBlocked,
        policyFacts.didKeepApplicationSingletonCreationBlocked,
        policyFacts.didRequireSharedApplicationMainThreadGate,
        policyFacts.didRequireBoundedRunLoopBeforeSharedApplicationAccess,
        policyFacts.didRequireAutoCloseBeforeVisibleMode,
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
        policyFacts.didKeepGuardPolicyFactsValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness(
    nsApplicationSharedApplicationNativeGuardReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationNativeGuardReadiness,
    nsApplicationSharedApplicationGuardPolicyAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyAdmission
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness {
    let upstreamReady =
        nsApplicationSharedApplicationNativeGuardReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationNativeGuardReadiness &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmNoRendererStateWrite &&
        nsApplicationSharedApplicationNativeGuardReadiness
            .didConfirmNoBackendReadyTruth
    let admissionReady =
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didAdmitNsApplicationSharedApplicationGuardPolicyBoundary &&
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmApplicationSingletonAccessorStillBlocked &&
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmApplicationSingletonCreationStillBlocked &&
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmSharedApplicationMainThreadGateRequired &&
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmBoundedRunLoopPrerequisiteRequired &&
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmAutoClosePrerequisiteRequired &&
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didKeepHeadlessCiFailClosedRoute &&
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmTeardownBeforeVisibleModeRequired &&
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmNonUserVisibleModeRequired &&
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmActivationPolicyMutationStillBlocked &&
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmApplicationActivationStillBlocked &&
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmEventLoopStillBlocked &&
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmNativeVisibleOrderStillBlocked &&
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmProductionDrawableStillBlocked &&
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmRenderStillBlocked &&
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmNoApplicationSingletonAccessorCall &&
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didKeepNsApplicationSharedApplicationGuardPolicyValueOnly
    let readinessReady = upstreamReady && admissionReady
    let policyFacts = nsApplicationSharedApplicationGuardPolicyAdmission
        .policyFacts

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness(
        nsApplicationSharedApplicationNativeGuardReadiness,
        nsApplicationSharedApplicationGuardPolicyAdmission,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmApplicationSingletonAccessorStillBlocked,
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmApplicationSingletonCreationStillBlocked,
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmSharedApplicationMainThreadGateRequired,
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmBoundedRunLoopPrerequisiteRequired,
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmAutoClosePrerequisiteRequired,
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didKeepHeadlessCiFailClosedRoute,
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmTeardownBeforeVisibleModeRequired,
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmNonUserVisibleModeRequired,
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmActivationPolicyMutationStillBlocked,
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmApplicationActivationStillBlocked,
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmEventLoopStillBlocked,
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmNativeVisibleOrderStillBlocked,
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmProductionDrawableStillBlocked,
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmRenderStillBlocked,
        nsApplicationSharedApplicationGuardPolicyAdmission
            .didConfirmNoApplicationSingletonAccessorCall,
        policyFacts.didConfirmNoApplicationCreationOrActivation,
        policyFacts.didConfirmNoPointerHandleClassIdReturn,
        policyFacts.didConfirmNoPublicSurface,
        policyFacts.didConfirmNoRendererStateWrite,
        policyFacts.didConfirmNoBackendReadyTruth,
        policyFacts.didKeepGuardPolicyFactsValueOnly,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness {
    let nativeGuardReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationNativeGuardDraft()
    let policyFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyFacts(
            nativeGuardReadiness
        )
    let policyAdmission =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyAdmission(
            policyFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness(
        nativeGuardReadiness,
        policyAdmission
    )
}
