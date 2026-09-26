// 中文维护注释：本文件是 visible-window production harness application
// activation policy value boundary owner。
// Owner: runtime renderer internal application activation policy owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness，
// 固定 application singleton ownership、main-thread gate、creation/activation
// deferred、bounded run loop、auto-close、headless fail-closed、content-view
// prerequisite 与 no-render permission facts。
// Stop-line: 不创建 NSApplication，不 activation，不运行 event loop，不做 native
// visible order implementation，不获取 drawable，不创建 encoder，不 draw，不提交 GPU
// work，不执行 render，不返回 Class / id / pointer / handle，不写 runtime_state.cj，
// 不扩 public API。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、visible-ready、
// drawable-ready、render-ready、backend-ready、renderer state write、receipt、record
// 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowApplicationActivationPolicyFacts {
    let didRequireApplicationSingletonOwnershipScope: Bool
    let didKeepApplicationCreationPolicyOnly: Bool
    let didKeepActivationPolicyOnly: Bool
    let didRequireMainThreadApplicationGate: Bool
    let didRequireBoundedRunLoopBeforeApplicationCreation: Bool
    let didRequireAutoCloseBeforeUserVisibleActivation: Bool
    let didKeepHeadlessCiFailClosedRoute: Bool
    let didRequireContentViewBeforeActivation: Bool
    let didKeepNativeVisibleOrderImplementationBlocked: Bool
    let didKeepProductionDrawablePermissionBlocked: Bool
    let didKeepCommandBufferEncoderSubmissionRenderBlocked: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepPolicyFactsValueOnly: Bool

    init(
        didRequireApplicationSingletonOwnershipScope: Bool,
        didKeepApplicationCreationPolicyOnly: Bool,
        didKeepActivationPolicyOnly: Bool,
        didRequireMainThreadApplicationGate: Bool,
        didRequireBoundedRunLoopBeforeApplicationCreation: Bool,
        didRequireAutoCloseBeforeUserVisibleActivation: Bool,
        didKeepHeadlessCiFailClosedRoute: Bool,
        didRequireContentViewBeforeActivation: Bool,
        didKeepNativeVisibleOrderImplementationBlocked: Bool,
        didKeepProductionDrawablePermissionBlocked: Bool,
        didKeepCommandBufferEncoderSubmissionRenderBlocked: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepPolicyFactsValueOnly: Bool
    ) {
        this.didRequireApplicationSingletonOwnershipScope =
            didRequireApplicationSingletonOwnershipScope
        this.didKeepApplicationCreationPolicyOnly =
            didKeepApplicationCreationPolicyOnly
        this.didKeepActivationPolicyOnly = didKeepActivationPolicyOnly
        this.didRequireMainThreadApplicationGate =
            didRequireMainThreadApplicationGate
        this.didRequireBoundedRunLoopBeforeApplicationCreation =
            didRequireBoundedRunLoopBeforeApplicationCreation
        this.didRequireAutoCloseBeforeUserVisibleActivation =
            didRequireAutoCloseBeforeUserVisibleActivation
        this.didKeepHeadlessCiFailClosedRoute =
            didKeepHeadlessCiFailClosedRoute
        this.didRequireContentViewBeforeActivation =
            didRequireContentViewBeforeActivation
        this.didKeepNativeVisibleOrderImplementationBlocked =
            didKeepNativeVisibleOrderImplementationBlocked
        this.didKeepProductionDrawablePermissionBlocked =
            didKeepProductionDrawablePermissionBlocked
        this.didKeepCommandBufferEncoderSubmissionRenderBlocked =
            didKeepCommandBufferEncoderSubmissionRenderBlocked
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepPolicyFactsValueOnly = didKeepPolicyFactsValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowApplicationActivationPolicyAdmission {
    let policyFacts:
        CjguiInternalRendererVisibleWindowApplicationActivationPolicyFacts
    let didAdmitApplicationActivationPolicyBoundary: Bool
    let shouldDeferApplicationActivationPolicyBoundary: Bool
    let shouldReportApplicationActivationPolicyBlocked: Bool
    let didConfirmApplicationOwnershipScopeOnly: Bool
    let didConfirmApplicationCreationStillDeferred: Bool
    let didConfirmActivationStillDeferred: Bool
    let didConfirmMainThreadGateRequired: Bool
    let didConfirmBoundedRunLoopRequired: Bool
    let didConfirmAutoCloseRequired: Bool
    let didKeepHeadlessCiFailClosedRoute: Bool
    let didConfirmContentViewPrerequisiteRequired: Bool
    let didConfirmNoNativeVisibleOrderImplementation: Bool
    let didConfirmNoProductionDrawablePermission: Bool
    let didKeepApplicationActivationPolicyValueOnly: Bool

    init(
        policyFacts:
            CjguiInternalRendererVisibleWindowApplicationActivationPolicyFacts,
        didAdmitApplicationActivationPolicyBoundary: Bool,
        shouldDeferApplicationActivationPolicyBoundary: Bool,
        shouldReportApplicationActivationPolicyBlocked: Bool,
        didConfirmApplicationOwnershipScopeOnly: Bool,
        didConfirmApplicationCreationStillDeferred: Bool,
        didConfirmActivationStillDeferred: Bool,
        didConfirmMainThreadGateRequired: Bool,
        didConfirmBoundedRunLoopRequired: Bool,
        didConfirmAutoCloseRequired: Bool,
        didKeepHeadlessCiFailClosedRoute: Bool,
        didConfirmContentViewPrerequisiteRequired: Bool,
        didConfirmNoNativeVisibleOrderImplementation: Bool,
        didConfirmNoProductionDrawablePermission: Bool,
        didKeepApplicationActivationPolicyValueOnly: Bool
    ) {
        this.policyFacts = policyFacts
        this.didAdmitApplicationActivationPolicyBoundary =
            didAdmitApplicationActivationPolicyBoundary
        this.shouldDeferApplicationActivationPolicyBoundary =
            shouldDeferApplicationActivationPolicyBoundary
        this.shouldReportApplicationActivationPolicyBlocked =
            shouldReportApplicationActivationPolicyBlocked
        this.didConfirmApplicationOwnershipScopeOnly =
            didConfirmApplicationOwnershipScopeOnly
        this.didConfirmApplicationCreationStillDeferred =
            didConfirmApplicationCreationStillDeferred
        this.didConfirmActivationStillDeferred =
            didConfirmActivationStillDeferred
        this.didConfirmMainThreadGateRequired =
            didConfirmMainThreadGateRequired
        this.didConfirmBoundedRunLoopRequired =
            didConfirmBoundedRunLoopRequired
        this.didConfirmAutoCloseRequired = didConfirmAutoCloseRequired
        this.didKeepHeadlessCiFailClosedRoute =
            didKeepHeadlessCiFailClosedRoute
        this.didConfirmContentViewPrerequisiteRequired =
            didConfirmContentViewPrerequisiteRequired
        this.didConfirmNoNativeVisibleOrderImplementation =
            didConfirmNoNativeVisibleOrderImplementation
        this.didConfirmNoProductionDrawablePermission =
            didConfirmNoProductionDrawablePermission
        this.didKeepApplicationActivationPolicyValueOnly =
            didKeepApplicationActivationPolicyValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowApplicationActivationPolicyReadiness {
    let visibleOrderNativeGuardReadiness:
        CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness
    let applicationActivationPolicyAdmission:
        CjguiInternalRendererVisibleWindowApplicationActivationPolicyAdmission
    let didPrepareRendererVisibleWindowApplicationActivationPolicyReadiness:
        Bool
    let shouldDeferRendererVisibleWindowApplicationActivationPolicyReadiness:
        Bool
    let shouldReportRendererVisibleWindowApplicationActivationPolicyBlocked:
        Bool
    let didPreserveVisibleOrderNativeGuardReadiness: Bool
    let didConfirmApplicationOwnershipScopeOnly: Bool
    let didConfirmApplicationCreationStillDeferred: Bool
    let didConfirmActivationStillDeferred: Bool
    let didConfirmMainThreadGateRequired: Bool
    let didConfirmBoundedRunLoopRequired: Bool
    let didConfirmAutoCloseRequired: Bool
    let didKeepHeadlessCiFailClosedRoute: Bool
    let didConfirmContentViewPrerequisiteRequired: Bool
    let didConfirmNoNativeVisibleOrderImplementation: Bool
    let didConfirmNoProductionDrawablePermission: Bool
    let didConfirmNoCommandBufferEncoderSubmissionRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepApplicationActivationPolicyReadinessDehydrated: Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        visibleOrderNativeGuardReadiness:
            CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness,
        applicationActivationPolicyAdmission:
            CjguiInternalRendererVisibleWindowApplicationActivationPolicyAdmission,
        didPrepareRendererVisibleWindowApplicationActivationPolicyReadiness:
            Bool,
        shouldDeferRendererVisibleWindowApplicationActivationPolicyReadiness:
            Bool,
        shouldReportRendererVisibleWindowApplicationActivationPolicyBlocked:
            Bool,
        didPreserveVisibleOrderNativeGuardReadiness: Bool,
        didConfirmApplicationOwnershipScopeOnly: Bool,
        didConfirmApplicationCreationStillDeferred: Bool,
        didConfirmActivationStillDeferred: Bool,
        didConfirmMainThreadGateRequired: Bool,
        didConfirmBoundedRunLoopRequired: Bool,
        didConfirmAutoCloseRequired: Bool,
        didKeepHeadlessCiFailClosedRoute: Bool,
        didConfirmContentViewPrerequisiteRequired: Bool,
        didConfirmNoNativeVisibleOrderImplementation: Bool,
        didConfirmNoProductionDrawablePermission: Bool,
        didConfirmNoCommandBufferEncoderSubmissionRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepApplicationActivationPolicyReadinessDehydrated: Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.visibleOrderNativeGuardReadiness =
            visibleOrderNativeGuardReadiness
        this.applicationActivationPolicyAdmission =
            applicationActivationPolicyAdmission
        this.didPrepareRendererVisibleWindowApplicationActivationPolicyReadiness =
            didPrepareRendererVisibleWindowApplicationActivationPolicyReadiness
        this.shouldDeferRendererVisibleWindowApplicationActivationPolicyReadiness =
            shouldDeferRendererVisibleWindowApplicationActivationPolicyReadiness
        this.shouldReportRendererVisibleWindowApplicationActivationPolicyBlocked =
            shouldReportRendererVisibleWindowApplicationActivationPolicyBlocked
        this.didPreserveVisibleOrderNativeGuardReadiness =
            didPreserveVisibleOrderNativeGuardReadiness
        this.didConfirmApplicationOwnershipScopeOnly =
            didConfirmApplicationOwnershipScopeOnly
        this.didConfirmApplicationCreationStillDeferred =
            didConfirmApplicationCreationStillDeferred
        this.didConfirmActivationStillDeferred =
            didConfirmActivationStillDeferred
        this.didConfirmMainThreadGateRequired =
            didConfirmMainThreadGateRequired
        this.didConfirmBoundedRunLoopRequired =
            didConfirmBoundedRunLoopRequired
        this.didConfirmAutoCloseRequired = didConfirmAutoCloseRequired
        this.didKeepHeadlessCiFailClosedRoute =
            didKeepHeadlessCiFailClosedRoute
        this.didConfirmContentViewPrerequisiteRequired =
            didConfirmContentViewPrerequisiteRequired
        this.didConfirmNoNativeVisibleOrderImplementation =
            didConfirmNoNativeVisibleOrderImplementation
        this.didConfirmNoProductionDrawablePermission =
            didConfirmNoProductionDrawablePermission
        this.didConfirmNoCommandBufferEncoderSubmissionRender =
            didConfirmNoCommandBufferEncoderSubmissionRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepApplicationActivationPolicyReadinessDehydrated =
            didKeepApplicationActivationPolicyReadinessDehydrated
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowApplicationActivationPolicyFacts(
    visibleOrderNativeGuardReadiness:
        CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness
): CjguiInternalRendererVisibleWindowApplicationActivationPolicyFacts {
    let upstreamReady =
        visibleOrderNativeGuardReadiness
            .didPrepareRendererVisibleWindowVisibleOrderNativeGuardReadiness &&
        visibleOrderNativeGuardReadiness
            .didConfirmApplicationOwnershipRequired &&
        visibleOrderNativeGuardReadiness
            .didConfirmApplicationCreationStillDeferred &&
        visibleOrderNativeGuardReadiness.didConfirmActivationStillDeferred &&
        visibleOrderNativeGuardReadiness
            .didConfirmBoundedRunLoopStillRequired &&
        visibleOrderNativeGuardReadiness.didConfirmAutoCloseStillRequired &&
        visibleOrderNativeGuardReadiness.didConfirmHeadlessCiFailClosedRoute &&
        visibleOrderNativeGuardReadiness
            .didConfirmContentViewPrerequisiteStillRequired &&
        visibleOrderNativeGuardReadiness
            .didConfirmNativeVisibleOrderStillBlocked &&
        visibleOrderNativeGuardReadiness
            .didConfirmProductionDrawableStillBlocked &&
        visibleOrderNativeGuardReadiness.didConfirmRenderStillBlocked &&
        visibleOrderNativeGuardReadiness
            .didConfirmNoApplicationCreationOrActivation &&
        visibleOrderNativeGuardReadiness.didConfirmNoPointerHandleClassIdReturn &&
        visibleOrderNativeGuardReadiness.didConfirmNoPublicSurface &&
        visibleOrderNativeGuardReadiness.didConfirmNoRendererStateWrite &&
        visibleOrderNativeGuardReadiness.didConfirmNoBackendReadyTruth

    return CjguiInternalRendererVisibleWindowApplicationActivationPolicyFacts(
        upstreamReady,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        visibleOrderNativeGuardReadiness.didConfirmHeadlessCiFailClosedRoute,
        visibleOrderNativeGuardReadiness
            .didConfirmContentViewPrerequisiteStillRequired,
        visibleOrderNativeGuardReadiness
            .didConfirmNativeVisibleOrderStillBlocked,
        visibleOrderNativeGuardReadiness
            .didConfirmProductionDrawableStillBlocked,
        visibleOrderNativeGuardReadiness.didConfirmRenderStillBlocked,
        visibleOrderNativeGuardReadiness.didConfirmNoPointerHandleClassIdReturn,
        visibleOrderNativeGuardReadiness.didConfirmNoPublicSurface,
        visibleOrderNativeGuardReadiness.didConfirmNoRendererStateWrite,
        visibleOrderNativeGuardReadiness.didConfirmNoBackendReadyTruth,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowApplicationActivationPolicyAdmission(
    policyFacts:
        CjguiInternalRendererVisibleWindowApplicationActivationPolicyFacts
): CjguiInternalRendererVisibleWindowApplicationActivationPolicyAdmission {
    let didAdmit =
        policyFacts.didRequireApplicationSingletonOwnershipScope &&
        policyFacts.didKeepApplicationCreationPolicyOnly &&
        policyFacts.didKeepActivationPolicyOnly &&
        policyFacts.didRequireMainThreadApplicationGate &&
        policyFacts.didRequireBoundedRunLoopBeforeApplicationCreation &&
        policyFacts.didRequireAutoCloseBeforeUserVisibleActivation &&
        policyFacts.didKeepHeadlessCiFailClosedRoute &&
        policyFacts.didRequireContentViewBeforeActivation &&
        policyFacts.didKeepNativeVisibleOrderImplementationBlocked &&
        policyFacts.didKeepProductionDrawablePermissionBlocked &&
        policyFacts.didKeepCommandBufferEncoderSubmissionRenderBlocked &&
        policyFacts.didConfirmNoPointerHandleClassIdReturn &&
        policyFacts.didConfirmNoPublicSurface &&
        policyFacts.didConfirmNoRendererStateWrite &&
        policyFacts.didConfirmNoBackendReadyTruth &&
        policyFacts.didKeepPolicyFactsValueOnly

    return CjguiInternalRendererVisibleWindowApplicationActivationPolicyAdmission(
        policyFacts,
        didAdmit,
        !didAdmit,
        !didAdmit,
        policyFacts.didRequireApplicationSingletonOwnershipScope,
        policyFacts.didKeepApplicationCreationPolicyOnly,
        policyFacts.didKeepActivationPolicyOnly,
        policyFacts.didRequireMainThreadApplicationGate,
        policyFacts.didRequireBoundedRunLoopBeforeApplicationCreation,
        policyFacts.didRequireAutoCloseBeforeUserVisibleActivation,
        policyFacts.didKeepHeadlessCiFailClosedRoute,
        policyFacts.didRequireContentViewBeforeActivation,
        policyFacts.didKeepNativeVisibleOrderImplementationBlocked,
        policyFacts.didKeepProductionDrawablePermissionBlocked,
        policyFacts.didKeepPolicyFactsValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowApplicationActivationPolicyReadiness(
    visibleOrderNativeGuardReadiness:
        CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness,
    applicationActivationPolicyAdmission:
        CjguiInternalRendererVisibleWindowApplicationActivationPolicyAdmission
): CjguiInternalRendererVisibleWindowApplicationActivationPolicyReadiness {
    let upstreamReady =
        visibleOrderNativeGuardReadiness
            .didPrepareRendererVisibleWindowVisibleOrderNativeGuardReadiness &&
        visibleOrderNativeGuardReadiness.didConfirmNoRendererStateWrite &&
        visibleOrderNativeGuardReadiness.didConfirmNoBackendReadyTruth
    let admissionReady =
        applicationActivationPolicyAdmission
            .didAdmitApplicationActivationPolicyBoundary &&
        applicationActivationPolicyAdmission
            .didConfirmApplicationOwnershipScopeOnly &&
        applicationActivationPolicyAdmission
            .didConfirmApplicationCreationStillDeferred &&
        applicationActivationPolicyAdmission.didConfirmActivationStillDeferred &&
        applicationActivationPolicyAdmission.didConfirmMainThreadGateRequired &&
        applicationActivationPolicyAdmission.didConfirmBoundedRunLoopRequired &&
        applicationActivationPolicyAdmission.didConfirmAutoCloseRequired &&
        applicationActivationPolicyAdmission.didKeepHeadlessCiFailClosedRoute &&
        applicationActivationPolicyAdmission
            .didConfirmContentViewPrerequisiteRequired &&
        applicationActivationPolicyAdmission
            .didConfirmNoNativeVisibleOrderImplementation &&
        applicationActivationPolicyAdmission
            .didConfirmNoProductionDrawablePermission &&
        applicationActivationPolicyAdmission
            .didKeepApplicationActivationPolicyValueOnly
    let readinessReady = upstreamReady && admissionReady
    let policyFacts = applicationActivationPolicyAdmission.policyFacts

    return CjguiInternalRendererVisibleWindowApplicationActivationPolicyReadiness(
        visibleOrderNativeGuardReadiness,
        applicationActivationPolicyAdmission,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        applicationActivationPolicyAdmission
            .didConfirmApplicationOwnershipScopeOnly,
        applicationActivationPolicyAdmission
            .didConfirmApplicationCreationStillDeferred,
        applicationActivationPolicyAdmission.didConfirmActivationStillDeferred,
        applicationActivationPolicyAdmission.didConfirmMainThreadGateRequired,
        applicationActivationPolicyAdmission.didConfirmBoundedRunLoopRequired,
        applicationActivationPolicyAdmission.didConfirmAutoCloseRequired,
        applicationActivationPolicyAdmission.didKeepHeadlessCiFailClosedRoute,
        applicationActivationPolicyAdmission
            .didConfirmContentViewPrerequisiteRequired,
        applicationActivationPolicyAdmission
            .didConfirmNoNativeVisibleOrderImplementation,
        applicationActivationPolicyAdmission
            .didConfirmNoProductionDrawablePermission,
        policyFacts.didKeepCommandBufferEncoderSubmissionRenderBlocked,
        policyFacts.didConfirmNoPointerHandleClassIdReturn,
        policyFacts.didConfirmNoPublicSurface,
        policyFacts.didConfirmNoRendererStateWrite,
        policyFacts.didConfirmNoBackendReadyTruth,
        policyFacts.didKeepPolicyFactsValueOnly,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowApplicationActivationPolicyDraft():
    CjguiInternalRendererVisibleWindowApplicationActivationPolicyReadiness {
    let nativeGuardReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowVisibleOrderNativeGuardDraft()
    let policyFacts =
        cjguiInternalBuildRendererVisibleWindowApplicationActivationPolicyFacts(
            nativeGuardReadiness
        )
    let policyAdmission =
        cjguiInternalBuildRendererVisibleWindowApplicationActivationPolicyAdmission(
            policyFacts
        )
    return cjguiInternalBuildRendererVisibleWindowApplicationActivationPolicyReadiness(
        nativeGuardReadiness,
        policyAdmission
    )
}

