// 中文维护注释：本文件是 visible-window production harness NSApplication
// native guard policy value boundary owner。
// Owner: runtime renderer internal NSApplication guard policy owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowNsApplicationNativeGuardReadiness，
// 固定 application singleton ownership、main-thread gate、creation / activation /
// activation policy / event loop deferred、bounded run loop、auto-close、
// headless fail-closed、visible-order / drawable / render still-blocked facts。
// Stop-line: 不创建 NSApplication，不 activation，不修改 activation policy，
// 不运行 event loop，不做 native visible order implementation，不获取 drawable，
// 不创建 encoder，不 draw，不提交 GPU work，不执行 render，不返回 Class / id /
// pointer / handle，不写 runtime_state.cj，不扩 public API。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、visible-ready、
// drawable-ready、render-ready、backend-ready、renderer state write、receipt、record
// 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyFacts {
    let didRequireApplicationSingletonOwnership: Bool
    let didRequireMainThreadGate: Bool
    let didKeepApplicationCreationPolicyDeferred: Bool
    let didKeepActivationPolicyDeferred: Bool
    let didKeepActivationPolicyMutationDeferred: Bool
    let didKeepEventLoopPolicyDeferred: Bool
    let didRequireBoundedRunLoopBeforeApplicationCreation: Bool
    let didRequireAutoCloseBeforeActivation: Bool
    let didKeepHeadlessCiFailClosedRoute: Bool
    let didKeepNativeVisibleOrderImplementationBlocked: Bool
    let didKeepProductionDrawablePermissionBlocked: Bool
    let didKeepRenderPermissionBlocked: Bool
    let didConfirmNoApplicationCreationOrActivation: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepGuardPolicyFactsValueOnly: Bool

    init(
        didRequireApplicationSingletonOwnership: Bool,
        didRequireMainThreadGate: Bool,
        didKeepApplicationCreationPolicyDeferred: Bool,
        didKeepActivationPolicyDeferred: Bool,
        didKeepActivationPolicyMutationDeferred: Bool,
        didKeepEventLoopPolicyDeferred: Bool,
        didRequireBoundedRunLoopBeforeApplicationCreation: Bool,
        didRequireAutoCloseBeforeActivation: Bool,
        didKeepHeadlessCiFailClosedRoute: Bool,
        didKeepNativeVisibleOrderImplementationBlocked: Bool,
        didKeepProductionDrawablePermissionBlocked: Bool,
        didKeepRenderPermissionBlocked: Bool,
        didConfirmNoApplicationCreationOrActivation: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepGuardPolicyFactsValueOnly: Bool
    ) {
        this.didRequireApplicationSingletonOwnership =
            didRequireApplicationSingletonOwnership
        this.didRequireMainThreadGate = didRequireMainThreadGate
        this.didKeepApplicationCreationPolicyDeferred =
            didKeepApplicationCreationPolicyDeferred
        this.didKeepActivationPolicyDeferred =
            didKeepActivationPolicyDeferred
        this.didKeepActivationPolicyMutationDeferred =
            didKeepActivationPolicyMutationDeferred
        this.didKeepEventLoopPolicyDeferred = didKeepEventLoopPolicyDeferred
        this.didRequireBoundedRunLoopBeforeApplicationCreation =
            didRequireBoundedRunLoopBeforeApplicationCreation
        this.didRequireAutoCloseBeforeActivation =
            didRequireAutoCloseBeforeActivation
        this.didKeepHeadlessCiFailClosedRoute =
            didKeepHeadlessCiFailClosedRoute
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
        this.didKeepGuardPolicyFactsValueOnly =
            didKeepGuardPolicyFactsValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyAdmission {
    let policyFacts:
        CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyFacts
    let didAdmitNsApplicationGuardPolicyBoundary: Bool
    let shouldDeferNsApplicationGuardPolicyBoundary: Bool
    let shouldReportNsApplicationGuardPolicyBlocked: Bool
    let didConfirmApplicationSingletonOwnershipRequired: Bool
    let didConfirmMainThreadGateRequired: Bool
    let didConfirmApplicationCreationStillDeferred: Bool
    let didConfirmActivationStillDeferred: Bool
    let didConfirmActivationPolicyStillDeferred: Bool
    let didConfirmEventLoopStillDeferred: Bool
    let didConfirmBoundedRunLoopRequired: Bool
    let didConfirmAutoCloseRequired: Bool
    let didKeepHeadlessCiFailClosedRoute: Bool
    let didConfirmNativeVisibleOrderStillBlocked: Bool
    let didConfirmProductionDrawableStillBlocked: Bool
    let didConfirmRenderStillBlocked: Bool
    let didKeepNsApplicationGuardPolicyValueOnly: Bool

    init(
        policyFacts:
            CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyFacts,
        didAdmitNsApplicationGuardPolicyBoundary: Bool,
        shouldDeferNsApplicationGuardPolicyBoundary: Bool,
        shouldReportNsApplicationGuardPolicyBlocked: Bool,
        didConfirmApplicationSingletonOwnershipRequired: Bool,
        didConfirmMainThreadGateRequired: Bool,
        didConfirmApplicationCreationStillDeferred: Bool,
        didConfirmActivationStillDeferred: Bool,
        didConfirmActivationPolicyStillDeferred: Bool,
        didConfirmEventLoopStillDeferred: Bool,
        didConfirmBoundedRunLoopRequired: Bool,
        didConfirmAutoCloseRequired: Bool,
        didKeepHeadlessCiFailClosedRoute: Bool,
        didConfirmNativeVisibleOrderStillBlocked: Bool,
        didConfirmProductionDrawableStillBlocked: Bool,
        didConfirmRenderStillBlocked: Bool,
        didKeepNsApplicationGuardPolicyValueOnly: Bool
    ) {
        this.policyFacts = policyFacts
        this.didAdmitNsApplicationGuardPolicyBoundary =
            didAdmitNsApplicationGuardPolicyBoundary
        this.shouldDeferNsApplicationGuardPolicyBoundary =
            shouldDeferNsApplicationGuardPolicyBoundary
        this.shouldReportNsApplicationGuardPolicyBlocked =
            shouldReportNsApplicationGuardPolicyBlocked
        this.didConfirmApplicationSingletonOwnershipRequired =
            didConfirmApplicationSingletonOwnershipRequired
        this.didConfirmMainThreadGateRequired =
            didConfirmMainThreadGateRequired
        this.didConfirmApplicationCreationStillDeferred =
            didConfirmApplicationCreationStillDeferred
        this.didConfirmActivationStillDeferred =
            didConfirmActivationStillDeferred
        this.didConfirmActivationPolicyStillDeferred =
            didConfirmActivationPolicyStillDeferred
        this.didConfirmEventLoopStillDeferred =
            didConfirmEventLoopStillDeferred
        this.didConfirmBoundedRunLoopRequired =
            didConfirmBoundedRunLoopRequired
        this.didConfirmAutoCloseRequired = didConfirmAutoCloseRequired
        this.didKeepHeadlessCiFailClosedRoute =
            didKeepHeadlessCiFailClosedRoute
        this.didConfirmNativeVisibleOrderStillBlocked =
            didConfirmNativeVisibleOrderStillBlocked
        this.didConfirmProductionDrawableStillBlocked =
            didConfirmProductionDrawableStillBlocked
        this.didConfirmRenderStillBlocked = didConfirmRenderStillBlocked
        this.didKeepNsApplicationGuardPolicyValueOnly =
            didKeepNsApplicationGuardPolicyValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyReadiness {
    let nsApplicationNativeGuardReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationNativeGuardReadiness
    let nsApplicationGuardPolicyAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyAdmission
    let didPrepareRendererVisibleWindowNsApplicationGuardPolicyReadiness:
        Bool
    let shouldDeferRendererVisibleWindowNsApplicationGuardPolicyReadiness:
        Bool
    let shouldReportRendererVisibleWindowNsApplicationGuardPolicyBlocked:
        Bool
    let didPreserveNsApplicationNativeGuardReadiness: Bool
    let didConfirmApplicationSingletonOwnershipRequired: Bool
    let didConfirmMainThreadGateRequired: Bool
    let didConfirmApplicationCreationStillDeferred: Bool
    let didConfirmActivationStillDeferred: Bool
    let didConfirmActivationPolicyStillDeferred: Bool
    let didConfirmEventLoopStillDeferred: Bool
    let didConfirmBoundedRunLoopRequired: Bool
    let didConfirmAutoCloseRequired: Bool
    let didKeepHeadlessCiFailClosedRoute: Bool
    let didConfirmNativeVisibleOrderStillBlocked: Bool
    let didConfirmProductionDrawableStillBlocked: Bool
    let didConfirmRenderStillBlocked: Bool
    let didConfirmNoApplicationCreationOrActivation: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNsApplicationGuardPolicyReadinessDehydrated: Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        nsApplicationNativeGuardReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationNativeGuardReadiness,
        nsApplicationGuardPolicyAdmission:
            CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyAdmission,
        didPrepareRendererVisibleWindowNsApplicationGuardPolicyReadiness:
            Bool,
        shouldDeferRendererVisibleWindowNsApplicationGuardPolicyReadiness:
            Bool,
        shouldReportRendererVisibleWindowNsApplicationGuardPolicyBlocked:
            Bool,
        didPreserveNsApplicationNativeGuardReadiness: Bool,
        didConfirmApplicationSingletonOwnershipRequired: Bool,
        didConfirmMainThreadGateRequired: Bool,
        didConfirmApplicationCreationStillDeferred: Bool,
        didConfirmActivationStillDeferred: Bool,
        didConfirmActivationPolicyStillDeferred: Bool,
        didConfirmEventLoopStillDeferred: Bool,
        didConfirmBoundedRunLoopRequired: Bool,
        didConfirmAutoCloseRequired: Bool,
        didKeepHeadlessCiFailClosedRoute: Bool,
        didConfirmNativeVisibleOrderStillBlocked: Bool,
        didConfirmProductionDrawableStillBlocked: Bool,
        didConfirmRenderStillBlocked: Bool,
        didConfirmNoApplicationCreationOrActivation: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNsApplicationGuardPolicyReadinessDehydrated: Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.nsApplicationNativeGuardReadiness =
            nsApplicationNativeGuardReadiness
        this.nsApplicationGuardPolicyAdmission =
            nsApplicationGuardPolicyAdmission
        this.didPrepareRendererVisibleWindowNsApplicationGuardPolicyReadiness =
            didPrepareRendererVisibleWindowNsApplicationGuardPolicyReadiness
        this.shouldDeferRendererVisibleWindowNsApplicationGuardPolicyReadiness =
            shouldDeferRendererVisibleWindowNsApplicationGuardPolicyReadiness
        this.shouldReportRendererVisibleWindowNsApplicationGuardPolicyBlocked =
            shouldReportRendererVisibleWindowNsApplicationGuardPolicyBlocked
        this.didPreserveNsApplicationNativeGuardReadiness =
            didPreserveNsApplicationNativeGuardReadiness
        this.didConfirmApplicationSingletonOwnershipRequired =
            didConfirmApplicationSingletonOwnershipRequired
        this.didConfirmMainThreadGateRequired =
            didConfirmMainThreadGateRequired
        this.didConfirmApplicationCreationStillDeferred =
            didConfirmApplicationCreationStillDeferred
        this.didConfirmActivationStillDeferred =
            didConfirmActivationStillDeferred
        this.didConfirmActivationPolicyStillDeferred =
            didConfirmActivationPolicyStillDeferred
        this.didConfirmEventLoopStillDeferred =
            didConfirmEventLoopStillDeferred
        this.didConfirmBoundedRunLoopRequired =
            didConfirmBoundedRunLoopRequired
        this.didConfirmAutoCloseRequired = didConfirmAutoCloseRequired
        this.didKeepHeadlessCiFailClosedRoute =
            didKeepHeadlessCiFailClosedRoute
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
        this.didKeepNsApplicationGuardPolicyReadinessDehydrated =
            didKeepNsApplicationGuardPolicyReadinessDehydrated
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationGuardPolicyFacts(
    nsApplicationNativeGuardReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationNativeGuardReadiness
): CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyFacts {
    let upstreamReady =
        nsApplicationNativeGuardReadiness
            .didPrepareRendererVisibleWindowNsApplicationNativeGuardReadiness &&
        nsApplicationNativeGuardReadiness
            .didConfirmApplicationOwnershipRequired &&
        nsApplicationNativeGuardReadiness.didConfirmMainThreadGateRequired &&
        nsApplicationNativeGuardReadiness
            .didConfirmApplicationCreationStillDeferred &&
        nsApplicationNativeGuardReadiness.didConfirmActivationStillDeferred &&
        nsApplicationNativeGuardReadiness
            .didConfirmActivationPolicyStillDeferred &&
        nsApplicationNativeGuardReadiness.didConfirmEventLoopStillDeferred &&
        nsApplicationNativeGuardReadiness
            .didConfirmBoundedRunLoopStillRequired &&
        nsApplicationNativeGuardReadiness.didConfirmAutoCloseStillRequired &&
        nsApplicationNativeGuardReadiness
            .didConfirmHeadlessCiFailClosedRoute &&
        nsApplicationNativeGuardReadiness
            .didConfirmNativeVisibleOrderStillBlocked &&
        nsApplicationNativeGuardReadiness
            .didConfirmProductionDrawableStillBlocked &&
        nsApplicationNativeGuardReadiness.didConfirmRenderStillBlocked &&
        nsApplicationNativeGuardReadiness
            .didConfirmNoApplicationCreationOrActivation &&
        nsApplicationNativeGuardReadiness
            .didConfirmNoPointerHandleClassIdReturn &&
        nsApplicationNativeGuardReadiness.didConfirmNoPublicSurface &&
        nsApplicationNativeGuardReadiness.didConfirmNoRendererStateWrite &&
        nsApplicationNativeGuardReadiness.didConfirmNoBackendReadyTruth &&
        nsApplicationNativeGuardReadiness.didKeepNativeGuardReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyFacts(
        upstreamReady,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        nsApplicationNativeGuardReadiness.didConfirmHeadlessCiFailClosedRoute,
        nsApplicationNativeGuardReadiness
            .didConfirmNativeVisibleOrderStillBlocked,
        nsApplicationNativeGuardReadiness
            .didConfirmProductionDrawableStillBlocked,
        nsApplicationNativeGuardReadiness.didConfirmRenderStillBlocked,
        nsApplicationNativeGuardReadiness
            .didConfirmNoApplicationCreationOrActivation,
        nsApplicationNativeGuardReadiness.didConfirmNoPointerHandleClassIdReturn,
        nsApplicationNativeGuardReadiness.didConfirmNoPublicSurface,
        nsApplicationNativeGuardReadiness.didConfirmNoRendererStateWrite,
        nsApplicationNativeGuardReadiness.didConfirmNoBackendReadyTruth,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationGuardPolicyAdmission(
    policyFacts:
        CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyFacts
): CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyAdmission {
    let didAdmit =
        policyFacts.didRequireApplicationSingletonOwnership &&
        policyFacts.didRequireMainThreadGate &&
        policyFacts.didKeepApplicationCreationPolicyDeferred &&
        policyFacts.didKeepActivationPolicyDeferred &&
        policyFacts.didKeepActivationPolicyMutationDeferred &&
        policyFacts.didKeepEventLoopPolicyDeferred &&
        policyFacts.didRequireBoundedRunLoopBeforeApplicationCreation &&
        policyFacts.didRequireAutoCloseBeforeActivation &&
        policyFacts.didKeepHeadlessCiFailClosedRoute &&
        policyFacts.didKeepNativeVisibleOrderImplementationBlocked &&
        policyFacts.didKeepProductionDrawablePermissionBlocked &&
        policyFacts.didKeepRenderPermissionBlocked &&
        policyFacts.didConfirmNoApplicationCreationOrActivation &&
        policyFacts.didConfirmNoPointerHandleClassIdReturn &&
        policyFacts.didConfirmNoPublicSurface &&
        policyFacts.didConfirmNoRendererStateWrite &&
        policyFacts.didConfirmNoBackendReadyTruth &&
        policyFacts.didKeepGuardPolicyFactsValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyAdmission(
        policyFacts,
        didAdmit,
        !didAdmit,
        !didAdmit,
        policyFacts.didRequireApplicationSingletonOwnership,
        policyFacts.didRequireMainThreadGate,
        policyFacts.didKeepApplicationCreationPolicyDeferred,
        policyFacts.didKeepActivationPolicyDeferred,
        policyFacts.didKeepActivationPolicyMutationDeferred,
        policyFacts.didKeepEventLoopPolicyDeferred,
        policyFacts.didRequireBoundedRunLoopBeforeApplicationCreation,
        policyFacts.didRequireAutoCloseBeforeActivation,
        policyFacts.didKeepHeadlessCiFailClosedRoute,
        policyFacts.didKeepNativeVisibleOrderImplementationBlocked,
        policyFacts.didKeepProductionDrawablePermissionBlocked,
        policyFacts.didKeepRenderPermissionBlocked,
        policyFacts.didKeepGuardPolicyFactsValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationGuardPolicyReadiness(
    nsApplicationNativeGuardReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationNativeGuardReadiness,
    nsApplicationGuardPolicyAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyAdmission
): CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyReadiness {
    let upstreamReady =
        nsApplicationNativeGuardReadiness
            .didPrepareRendererVisibleWindowNsApplicationNativeGuardReadiness &&
        nsApplicationNativeGuardReadiness.didConfirmNoRendererStateWrite &&
        nsApplicationNativeGuardReadiness.didConfirmNoBackendReadyTruth
    let admissionReady =
        nsApplicationGuardPolicyAdmission
            .didAdmitNsApplicationGuardPolicyBoundary &&
        nsApplicationGuardPolicyAdmission
            .didConfirmApplicationSingletonOwnershipRequired &&
        nsApplicationGuardPolicyAdmission.didConfirmMainThreadGateRequired &&
        nsApplicationGuardPolicyAdmission
            .didConfirmApplicationCreationStillDeferred &&
        nsApplicationGuardPolicyAdmission.didConfirmActivationStillDeferred &&
        nsApplicationGuardPolicyAdmission
            .didConfirmActivationPolicyStillDeferred &&
        nsApplicationGuardPolicyAdmission.didConfirmEventLoopStillDeferred &&
        nsApplicationGuardPolicyAdmission.didConfirmBoundedRunLoopRequired &&
        nsApplicationGuardPolicyAdmission.didConfirmAutoCloseRequired &&
        nsApplicationGuardPolicyAdmission.didKeepHeadlessCiFailClosedRoute &&
        nsApplicationGuardPolicyAdmission
            .didConfirmNativeVisibleOrderStillBlocked &&
        nsApplicationGuardPolicyAdmission
            .didConfirmProductionDrawableStillBlocked &&
        nsApplicationGuardPolicyAdmission.didConfirmRenderStillBlocked &&
        nsApplicationGuardPolicyAdmission
            .didKeepNsApplicationGuardPolicyValueOnly
    let readinessReady = upstreamReady && admissionReady
    let policyFacts = nsApplicationGuardPolicyAdmission.policyFacts

    return CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyReadiness(
        nsApplicationNativeGuardReadiness,
        nsApplicationGuardPolicyAdmission,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        nsApplicationGuardPolicyAdmission
            .didConfirmApplicationSingletonOwnershipRequired,
        nsApplicationGuardPolicyAdmission.didConfirmMainThreadGateRequired,
        nsApplicationGuardPolicyAdmission
            .didConfirmApplicationCreationStillDeferred,
        nsApplicationGuardPolicyAdmission.didConfirmActivationStillDeferred,
        nsApplicationGuardPolicyAdmission
            .didConfirmActivationPolicyStillDeferred,
        nsApplicationGuardPolicyAdmission.didConfirmEventLoopStillDeferred,
        nsApplicationGuardPolicyAdmission.didConfirmBoundedRunLoopRequired,
        nsApplicationGuardPolicyAdmission.didConfirmAutoCloseRequired,
        nsApplicationGuardPolicyAdmission.didKeepHeadlessCiFailClosedRoute,
        nsApplicationGuardPolicyAdmission
            .didConfirmNativeVisibleOrderStillBlocked,
        nsApplicationGuardPolicyAdmission
            .didConfirmProductionDrawableStillBlocked,
        nsApplicationGuardPolicyAdmission.didConfirmRenderStillBlocked,
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

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationGuardPolicyDraft():
    CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyReadiness {
    let nativeGuardReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationNativeGuardDraft()
    let policyFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationGuardPolicyFacts(
            nativeGuardReadiness
        )
    let policyAdmission =
        cjguiInternalBuildRendererVisibleWindowNsApplicationGuardPolicyAdmission(
            policyFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationGuardPolicyReadiness(
        nativeGuardReadiness,
        policyAdmission
    )
}

