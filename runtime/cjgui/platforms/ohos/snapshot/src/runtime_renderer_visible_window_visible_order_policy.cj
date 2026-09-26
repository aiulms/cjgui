// 中文维护注释：本文件是 visible-window production harness visible-order
// policy value boundary owner。
// Owner: runtime renderer internal visible-order policy owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness，
// 固定 application ownership、activation、bounded run loop、auto-close、
// headless / CI-like fail-closed route 与 cleanup co-ownership policy facts。
// Stop-line: 不做 native visible order implementation，不创建 application side
// effect，不获取 drawable，不创建 encoder，不 draw，不提交 GPU work，不执行 render，
// 不返回 Class / id / pointer / handle，不写 runtime_state.cj，不扩 public API。
// Same-shape Boundary Brake: 不得把本 owner 包成 visible-ready、drawable-ready、
// render-ready、backend-ready、renderer state write、receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowVisibleOrderPolicyFacts {
    let didRequireApplicationOwnershipDecision: Bool
    let didKeepApplicationCreationDeferred: Bool
    let didKeepActivationPolicyDeferred: Bool
    let didRequireBoundedRunLoopBeforeVisibleOrder: Bool
    let didRequireAutoCloseBeforeVisibleOrderSmoke: Bool
    let didKeepHeadlessCiFailClosedRoute: Bool
    let didRequireContentViewCleanupCoOwnership: Bool
    let didKeepUserVisibleSideEffectGateClosed: Bool
    let didConfirmNoNativeVisibleOrderImplementation: Bool
    let didConfirmNoProductionDrawablePermission: Bool
    let didConfirmNoCommandBufferEncoderSubmissionRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepPolicyFactsValueOnly: Bool

    init(
        didRequireApplicationOwnershipDecision: Bool,
        didKeepApplicationCreationDeferred: Bool,
        didKeepActivationPolicyDeferred: Bool,
        didRequireBoundedRunLoopBeforeVisibleOrder: Bool,
        didRequireAutoCloseBeforeVisibleOrderSmoke: Bool,
        didKeepHeadlessCiFailClosedRoute: Bool,
        didRequireContentViewCleanupCoOwnership: Bool,
        didKeepUserVisibleSideEffectGateClosed: Bool,
        didConfirmNoNativeVisibleOrderImplementation: Bool,
        didConfirmNoProductionDrawablePermission: Bool,
        didConfirmNoCommandBufferEncoderSubmissionRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepPolicyFactsValueOnly: Bool
    ) {
        this.didRequireApplicationOwnershipDecision =
            didRequireApplicationOwnershipDecision
        this.didKeepApplicationCreationDeferred =
            didKeepApplicationCreationDeferred
        this.didKeepActivationPolicyDeferred =
            didKeepActivationPolicyDeferred
        this.didRequireBoundedRunLoopBeforeVisibleOrder =
            didRequireBoundedRunLoopBeforeVisibleOrder
        this.didRequireAutoCloseBeforeVisibleOrderSmoke =
            didRequireAutoCloseBeforeVisibleOrderSmoke
        this.didKeepHeadlessCiFailClosedRoute =
            didKeepHeadlessCiFailClosedRoute
        this.didRequireContentViewCleanupCoOwnership =
            didRequireContentViewCleanupCoOwnership
        this.didKeepUserVisibleSideEffectGateClosed =
            didKeepUserVisibleSideEffectGateClosed
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
        this.didKeepPolicyFactsValueOnly = didKeepPolicyFactsValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowVisibleOrderPolicyAdmission {
    let policyFacts: CjguiInternalRendererVisibleWindowVisibleOrderPolicyFacts
    let didAdmitVisibleOrderPolicyBoundary: Bool
    let shouldDeferVisibleOrderPolicyBoundary: Bool
    let shouldReportVisibleOrderPolicyBoundaryBlocked: Bool
    let didConfirmApplicationOwnershipStillPolicyOnly: Bool
    let didConfirmApplicationCreationStillDeferred: Bool
    let didConfirmActivationStillDeferred: Bool
    let didRequireBoundedRunLoopBeforeVisibleOrder: Bool
    let didRequireAutoCloseBeforeVisibleOrderSmoke: Bool
    let didKeepHeadlessCiFailClosedRoute: Bool
    let didConfirmNoNativeVisibleOrderImplementation: Bool
    let didConfirmNoProductionDrawablePermission: Bool
    let didKeepVisibleOrderPolicyValueOnly: Bool

    init(
        policyFacts: CjguiInternalRendererVisibleWindowVisibleOrderPolicyFacts,
        didAdmitVisibleOrderPolicyBoundary: Bool,
        shouldDeferVisibleOrderPolicyBoundary: Bool,
        shouldReportVisibleOrderPolicyBoundaryBlocked: Bool,
        didConfirmApplicationOwnershipStillPolicyOnly: Bool,
        didConfirmApplicationCreationStillDeferred: Bool,
        didConfirmActivationStillDeferred: Bool,
        didRequireBoundedRunLoopBeforeVisibleOrder: Bool,
        didRequireAutoCloseBeforeVisibleOrderSmoke: Bool,
        didKeepHeadlessCiFailClosedRoute: Bool,
        didConfirmNoNativeVisibleOrderImplementation: Bool,
        didConfirmNoProductionDrawablePermission: Bool,
        didKeepVisibleOrderPolicyValueOnly: Bool
    ) {
        this.policyFacts = policyFacts
        this.didAdmitVisibleOrderPolicyBoundary =
            didAdmitVisibleOrderPolicyBoundary
        this.shouldDeferVisibleOrderPolicyBoundary =
            shouldDeferVisibleOrderPolicyBoundary
        this.shouldReportVisibleOrderPolicyBoundaryBlocked =
            shouldReportVisibleOrderPolicyBoundaryBlocked
        this.didConfirmApplicationOwnershipStillPolicyOnly =
            didConfirmApplicationOwnershipStillPolicyOnly
        this.didConfirmApplicationCreationStillDeferred =
            didConfirmApplicationCreationStillDeferred
        this.didConfirmActivationStillDeferred =
            didConfirmActivationStillDeferred
        this.didRequireBoundedRunLoopBeforeVisibleOrder =
            didRequireBoundedRunLoopBeforeVisibleOrder
        this.didRequireAutoCloseBeforeVisibleOrderSmoke =
            didRequireAutoCloseBeforeVisibleOrderSmoke
        this.didKeepHeadlessCiFailClosedRoute =
            didKeepHeadlessCiFailClosedRoute
        this.didConfirmNoNativeVisibleOrderImplementation =
            didConfirmNoNativeVisibleOrderImplementation
        this.didConfirmNoProductionDrawablePermission =
            didConfirmNoProductionDrawablePermission
        this.didKeepVisibleOrderPolicyValueOnly =
            didKeepVisibleOrderPolicyValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness {
    let contentViewAttachmentReadiness:
        CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness
    let visibleOrderPolicyAdmission:
        CjguiInternalRendererVisibleWindowVisibleOrderPolicyAdmission
    let didPrepareRendererVisibleWindowVisibleOrderPolicyReadiness: Bool
    let shouldDeferRendererVisibleWindowVisibleOrderPolicyReadiness: Bool
    let shouldReportRendererVisibleWindowVisibleOrderPolicyBlocked: Bool
    let didPreserveContentViewAttachmentReadiness: Bool
    let didConfirmApplicationOwnershipStillPolicyOnly: Bool
    let didConfirmApplicationCreationStillDeferred: Bool
    let didConfirmActivationStillDeferred: Bool
    let didRequireBoundedRunLoopBeforeVisibleOrder: Bool
    let didRequireAutoCloseBeforeVisibleOrderSmoke: Bool
    let didKeepHeadlessCiFailClosedRoute: Bool
    let didConfirmNoNativeVisibleOrderImplementation: Bool
    let didConfirmNoProductionDrawablePermission: Bool
    let didConfirmNoCommandBufferEncoderSubmissionRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepVisibleOrderPolicyReadinessDehydrated: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        contentViewAttachmentReadiness:
            CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness,
        visibleOrderPolicyAdmission:
            CjguiInternalRendererVisibleWindowVisibleOrderPolicyAdmission,
        didPrepareRendererVisibleWindowVisibleOrderPolicyReadiness: Bool,
        shouldDeferRendererVisibleWindowVisibleOrderPolicyReadiness: Bool,
        shouldReportRendererVisibleWindowVisibleOrderPolicyBlocked: Bool,
        didPreserveContentViewAttachmentReadiness: Bool,
        didConfirmApplicationOwnershipStillPolicyOnly: Bool,
        didConfirmApplicationCreationStillDeferred: Bool,
        didConfirmActivationStillDeferred: Bool,
        didRequireBoundedRunLoopBeforeVisibleOrder: Bool,
        didRequireAutoCloseBeforeVisibleOrderSmoke: Bool,
        didKeepHeadlessCiFailClosedRoute: Bool,
        didConfirmNoNativeVisibleOrderImplementation: Bool,
        didConfirmNoProductionDrawablePermission: Bool,
        didConfirmNoCommandBufferEncoderSubmissionRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepVisibleOrderPolicyReadinessDehydrated: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.contentViewAttachmentReadiness = contentViewAttachmentReadiness
        this.visibleOrderPolicyAdmission = visibleOrderPolicyAdmission
        this.didPrepareRendererVisibleWindowVisibleOrderPolicyReadiness =
            didPrepareRendererVisibleWindowVisibleOrderPolicyReadiness
        this.shouldDeferRendererVisibleWindowVisibleOrderPolicyReadiness =
            shouldDeferRendererVisibleWindowVisibleOrderPolicyReadiness
        this.shouldReportRendererVisibleWindowVisibleOrderPolicyBlocked =
            shouldReportRendererVisibleWindowVisibleOrderPolicyBlocked
        this.didPreserveContentViewAttachmentReadiness =
            didPreserveContentViewAttachmentReadiness
        this.didConfirmApplicationOwnershipStillPolicyOnly =
            didConfirmApplicationOwnershipStillPolicyOnly
        this.didConfirmApplicationCreationStillDeferred =
            didConfirmApplicationCreationStillDeferred
        this.didConfirmActivationStillDeferred =
            didConfirmActivationStillDeferred
        this.didRequireBoundedRunLoopBeforeVisibleOrder =
            didRequireBoundedRunLoopBeforeVisibleOrder
        this.didRequireAutoCloseBeforeVisibleOrderSmoke =
            didRequireAutoCloseBeforeVisibleOrderSmoke
        this.didKeepHeadlessCiFailClosedRoute =
            didKeepHeadlessCiFailClosedRoute
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
        this.didKeepVisibleOrderPolicyReadinessDehydrated =
            didKeepVisibleOrderPolicyReadinessDehydrated
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowVisibleOrderPolicyFacts(
    contentViewAttachmentReadiness:
        CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness
): CjguiInternalRendererVisibleWindowVisibleOrderPolicyFacts {
    let upstreamReady =
        contentViewAttachmentReadiness
            .didPrepareRendererVisibleWindowContentViewAttachmentReadiness &&
        contentViewAttachmentReadiness
            .didConfirmContentViewAttachClassifyDetachLifecycle &&
        contentViewAttachmentReadiness.didConfirmMainThreadContentViewGate &&
        contentViewAttachmentReadiness.didConfirmVisibleOrderStillBlocked &&
        contentViewAttachmentReadiness
            .didConfirmProductionNextDrawableStillBlocked &&
        contentViewAttachmentReadiness
            .didConfirmNoCommandBufferEncoderCommitPresentGpuRender &&
        contentViewAttachmentReadiness.didConfirmNoPointerHandleClassIdReturn &&
        contentViewAttachmentReadiness.didConfirmNoPublicSurface &&
        contentViewAttachmentReadiness.didConfirmNoRendererStateWrite &&
        contentViewAttachmentReadiness.didConfirmNoBackendReadyTruth

    return CjguiInternalRendererVisibleWindowVisibleOrderPolicyFacts(
        upstreamReady,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        contentViewAttachmentReadiness
            .didConfirmDestroyBeforeDetachFailClosed &&
            contentViewAttachmentReadiness.didConfirmCleanupCountsReturnToZero,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        contentViewAttachmentReadiness.didConfirmNoPointerHandleClassIdReturn,
        contentViewAttachmentReadiness.didConfirmNoPublicSurface,
        contentViewAttachmentReadiness.didConfirmNoRendererStateWrite,
        contentViewAttachmentReadiness.didConfirmNoBackendReadyTruth,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowVisibleOrderPolicyAdmission(
    policyFacts: CjguiInternalRendererVisibleWindowVisibleOrderPolicyFacts
): CjguiInternalRendererVisibleWindowVisibleOrderPolicyAdmission {
    let didAdmit =
        policyFacts.didRequireApplicationOwnershipDecision &&
        policyFacts.didKeepApplicationCreationDeferred &&
        policyFacts.didKeepActivationPolicyDeferred &&
        policyFacts.didRequireBoundedRunLoopBeforeVisibleOrder &&
        policyFacts.didRequireAutoCloseBeforeVisibleOrderSmoke &&
        policyFacts.didKeepHeadlessCiFailClosedRoute &&
        policyFacts.didRequireContentViewCleanupCoOwnership &&
        policyFacts.didKeepUserVisibleSideEffectGateClosed &&
        policyFacts.didConfirmNoNativeVisibleOrderImplementation &&
        policyFacts.didConfirmNoProductionDrawablePermission &&
        policyFacts.didConfirmNoCommandBufferEncoderSubmissionRender &&
        policyFacts.didConfirmNoPointerHandleClassIdReturn &&
        policyFacts.didConfirmNoPublicSurface &&
        policyFacts.didConfirmNoRendererStateWrite &&
        policyFacts.didConfirmNoBackendReadyTruth &&
        policyFacts.didKeepPolicyFactsValueOnly

    return CjguiInternalRendererVisibleWindowVisibleOrderPolicyAdmission(
        policyFacts,
        didAdmit,
        !didAdmit,
        !didAdmit,
        policyFacts.didRequireApplicationOwnershipDecision,
        policyFacts.didKeepApplicationCreationDeferred,
        policyFacts.didKeepActivationPolicyDeferred,
        policyFacts.didRequireBoundedRunLoopBeforeVisibleOrder,
        policyFacts.didRequireAutoCloseBeforeVisibleOrderSmoke,
        policyFacts.didKeepHeadlessCiFailClosedRoute,
        policyFacts.didConfirmNoNativeVisibleOrderImplementation,
        policyFacts.didConfirmNoProductionDrawablePermission,
        policyFacts.didKeepPolicyFactsValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowVisibleOrderPolicyReadiness(
    contentViewAttachmentReadiness:
        CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness,
    visibleOrderPolicyAdmission:
        CjguiInternalRendererVisibleWindowVisibleOrderPolicyAdmission
): CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness {
    let upstreamReady =
        contentViewAttachmentReadiness
            .didPrepareRendererVisibleWindowContentViewAttachmentReadiness &&
        contentViewAttachmentReadiness.didConfirmNoRendererStateWrite &&
        contentViewAttachmentReadiness.didConfirmNoBackendReadyTruth
    let admissionReady =
        visibleOrderPolicyAdmission.didAdmitVisibleOrderPolicyBoundary &&
        visibleOrderPolicyAdmission
            .didConfirmApplicationOwnershipStillPolicyOnly &&
        visibleOrderPolicyAdmission
            .didConfirmApplicationCreationStillDeferred &&
        visibleOrderPolicyAdmission.didConfirmActivationStillDeferred &&
        visibleOrderPolicyAdmission
            .didRequireBoundedRunLoopBeforeVisibleOrder &&
        visibleOrderPolicyAdmission
            .didRequireAutoCloseBeforeVisibleOrderSmoke &&
        visibleOrderPolicyAdmission.didKeepHeadlessCiFailClosedRoute &&
        visibleOrderPolicyAdmission
            .didConfirmNoNativeVisibleOrderImplementation &&
        visibleOrderPolicyAdmission.didConfirmNoProductionDrawablePermission &&
        visibleOrderPolicyAdmission.didKeepVisibleOrderPolicyValueOnly
    let readinessReady = upstreamReady && admissionReady
    let policyFacts = visibleOrderPolicyAdmission.policyFacts

    return CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness(
        contentViewAttachmentReadiness,
        visibleOrderPolicyAdmission,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        visibleOrderPolicyAdmission
            .didConfirmApplicationOwnershipStillPolicyOnly,
        visibleOrderPolicyAdmission
            .didConfirmApplicationCreationStillDeferred,
        visibleOrderPolicyAdmission.didConfirmActivationStillDeferred,
        visibleOrderPolicyAdmission
            .didRequireBoundedRunLoopBeforeVisibleOrder,
        visibleOrderPolicyAdmission
            .didRequireAutoCloseBeforeVisibleOrderSmoke,
        visibleOrderPolicyAdmission.didKeepHeadlessCiFailClosedRoute,
        visibleOrderPolicyAdmission
            .didConfirmNoNativeVisibleOrderImplementation,
        visibleOrderPolicyAdmission.didConfirmNoProductionDrawablePermission,
        policyFacts.didConfirmNoCommandBufferEncoderSubmissionRender,
        policyFacts.didConfirmNoPointerHandleClassIdReturn,
        policyFacts.didConfirmNoPublicSurface,
        policyFacts.didConfirmNoRendererStateWrite,
        policyFacts.didConfirmNoBackendReadyTruth,
        policyFacts.didKeepPolicyFactsValueOnly,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowVisibleOrderPolicyDraft():
    CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness {
    let contentViewAttachmentReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowContentViewAttachmentDraft()
    let policyFacts =
        cjguiInternalBuildRendererVisibleWindowVisibleOrderPolicyFacts(
            contentViewAttachmentReadiness
        )
    let policyAdmission =
        cjguiInternalBuildRendererVisibleWindowVisibleOrderPolicyAdmission(
            policyFacts
        )
    return cjguiInternalBuildRendererVisibleWindowVisibleOrderPolicyReadiness(
        contentViewAttachmentReadiness,
        policyAdmission
    )
}
