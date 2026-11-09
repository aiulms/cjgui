// 中文维护注释：本文件是 visible-window production harness NSApplication
// creation / activation scope value boundary owner。
// Owner: runtime renderer internal NSApplication creation / activation scope owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyReadiness，
// 固定 application singleton creation、activation policy mutation、activation、
// event loop 仍 blocked，并保留 bounded run loop、auto-close、headless fail-closed、
// visible-order / drawable / render still-blocked facts。
// Stop-line: 不创建 NSApplication，不 activation，不修改 activation policy，
// 不运行 event loop，不做 native visible order implementation，不获取 drawable，
// 不创建 encoder，不 draw，不提交 GPU work，不执行 render，不返回 Class / id /
// pointer / handle，不写 runtime_state.cj，不扩 public API。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、visible-ready、
// drawable-ready、render-ready、backend-ready、renderer state write、receipt、record
// 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeFacts {
    let didKeepApplicationSingletonCreationBlocked: Bool
    let didKeepActivationPolicyMutationBlocked: Bool
    let didKeepApplicationActivationBlocked: Bool
    let didKeepEventLoopBlocked: Bool
    let didRequireBoundedRunLoopPrerequisite: Bool
    let didRequireAutoClosePrerequisite: Bool
    let didKeepHeadlessCiFailClosedRoute: Bool
    let didKeepNativeVisibleOrderImplementationBlocked: Bool
    let didKeepProductionDrawablePermissionBlocked: Bool
    let didKeepRenderPermissionBlocked: Bool
    let didConfirmNoApplicationCreationOrActivation: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepScopeFactsValueOnly: Bool

    init(
        didKeepApplicationSingletonCreationBlocked: Bool,
        didKeepActivationPolicyMutationBlocked: Bool,
        didKeepApplicationActivationBlocked: Bool,
        didKeepEventLoopBlocked: Bool,
        didRequireBoundedRunLoopPrerequisite: Bool,
        didRequireAutoClosePrerequisite: Bool,
        didKeepHeadlessCiFailClosedRoute: Bool,
        didKeepNativeVisibleOrderImplementationBlocked: Bool,
        didKeepProductionDrawablePermissionBlocked: Bool,
        didKeepRenderPermissionBlocked: Bool,
        didConfirmNoApplicationCreationOrActivation: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepScopeFactsValueOnly: Bool
    ) {
        this.didKeepApplicationSingletonCreationBlocked =
            didKeepApplicationSingletonCreationBlocked
        this.didKeepActivationPolicyMutationBlocked =
            didKeepActivationPolicyMutationBlocked
        this.didKeepApplicationActivationBlocked =
            didKeepApplicationActivationBlocked
        this.didKeepEventLoopBlocked = didKeepEventLoopBlocked
        this.didRequireBoundedRunLoopPrerequisite =
            didRequireBoundedRunLoopPrerequisite
        this.didRequireAutoClosePrerequisite =
            didRequireAutoClosePrerequisite
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
        this.didKeepScopeFactsValueOnly = didKeepScopeFactsValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeAdmission {
    let scopeFacts:
        CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeFacts
    let didAdmitNsApplicationCreationActivationScopeBoundary: Bool
    let shouldDeferNsApplicationCreationActivationScopeBoundary: Bool
    let shouldReportNsApplicationCreationActivationScopeBlocked: Bool
    let didConfirmApplicationSingletonCreationStillBlocked: Bool
    let didConfirmActivationPolicyMutationStillBlocked: Bool
    let didConfirmApplicationActivationStillBlocked: Bool
    let didConfirmEventLoopStillBlocked: Bool
    let didConfirmBoundedRunLoopPrerequisiteRequired: Bool
    let didConfirmAutoClosePrerequisiteRequired: Bool
    let didKeepHeadlessCiFailClosedRoute: Bool
    let didConfirmNativeVisibleOrderStillBlocked: Bool
    let didConfirmProductionDrawableStillBlocked: Bool
    let didConfirmRenderStillBlocked: Bool
    let didKeepNsApplicationCreationActivationScopeValueOnly: Bool

    init(
        scopeFacts:
            CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeFacts,
        didAdmitNsApplicationCreationActivationScopeBoundary: Bool,
        shouldDeferNsApplicationCreationActivationScopeBoundary: Bool,
        shouldReportNsApplicationCreationActivationScopeBlocked: Bool,
        didConfirmApplicationSingletonCreationStillBlocked: Bool,
        didConfirmActivationPolicyMutationStillBlocked: Bool,
        didConfirmApplicationActivationStillBlocked: Bool,
        didConfirmEventLoopStillBlocked: Bool,
        didConfirmBoundedRunLoopPrerequisiteRequired: Bool,
        didConfirmAutoClosePrerequisiteRequired: Bool,
        didKeepHeadlessCiFailClosedRoute: Bool,
        didConfirmNativeVisibleOrderStillBlocked: Bool,
        didConfirmProductionDrawableStillBlocked: Bool,
        didConfirmRenderStillBlocked: Bool,
        didKeepNsApplicationCreationActivationScopeValueOnly: Bool
    ) {
        this.scopeFacts = scopeFacts
        this.didAdmitNsApplicationCreationActivationScopeBoundary =
            didAdmitNsApplicationCreationActivationScopeBoundary
        this.shouldDeferNsApplicationCreationActivationScopeBoundary =
            shouldDeferNsApplicationCreationActivationScopeBoundary
        this.shouldReportNsApplicationCreationActivationScopeBlocked =
            shouldReportNsApplicationCreationActivationScopeBlocked
        this.didConfirmApplicationSingletonCreationStillBlocked =
            didConfirmApplicationSingletonCreationStillBlocked
        this.didConfirmActivationPolicyMutationStillBlocked =
            didConfirmActivationPolicyMutationStillBlocked
        this.didConfirmApplicationActivationStillBlocked =
            didConfirmApplicationActivationStillBlocked
        this.didConfirmEventLoopStillBlocked =
            didConfirmEventLoopStillBlocked
        this.didConfirmBoundedRunLoopPrerequisiteRequired =
            didConfirmBoundedRunLoopPrerequisiteRequired
        this.didConfirmAutoClosePrerequisiteRequired =
            didConfirmAutoClosePrerequisiteRequired
        this.didKeepHeadlessCiFailClosedRoute =
            didKeepHeadlessCiFailClosedRoute
        this.didConfirmNativeVisibleOrderStillBlocked =
            didConfirmNativeVisibleOrderStillBlocked
        this.didConfirmProductionDrawableStillBlocked =
            didConfirmProductionDrawableStillBlocked
        this.didConfirmRenderStillBlocked = didConfirmRenderStillBlocked
        this.didKeepNsApplicationCreationActivationScopeValueOnly =
            didKeepNsApplicationCreationActivationScopeValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeReadiness {
    let nsApplicationGuardPolicyReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyReadiness
    let nsApplicationCreationActivationScopeAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeAdmission
    let didPrepareRendererVisibleWindowNsApplicationCreationActivationScopeReadiness:
        Bool
    let shouldDeferRendererVisibleWindowNsApplicationCreationActivationScopeReadiness:
        Bool
    let shouldReportRendererVisibleWindowNsApplicationCreationActivationScopeBlocked:
        Bool
    let didPreserveNsApplicationGuardPolicyReadiness: Bool
    let didConfirmApplicationSingletonCreationStillBlocked: Bool
    let didConfirmActivationPolicyMutationStillBlocked: Bool
    let didConfirmApplicationActivationStillBlocked: Bool
    let didConfirmEventLoopStillBlocked: Bool
    let didConfirmBoundedRunLoopPrerequisiteRequired: Bool
    let didConfirmAutoClosePrerequisiteRequired: Bool
    let didKeepHeadlessCiFailClosedRoute: Bool
    let didConfirmNativeVisibleOrderStillBlocked: Bool
    let didConfirmProductionDrawableStillBlocked: Bool
    let didConfirmRenderStillBlocked: Bool
    let didConfirmNoApplicationCreationOrActivation: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNsApplicationCreationActivationScopeReadinessDehydrated: Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        nsApplicationGuardPolicyReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyReadiness,
        nsApplicationCreationActivationScopeAdmission:
            CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeAdmission,
        didPrepareRendererVisibleWindowNsApplicationCreationActivationScopeReadiness:
            Bool,
        shouldDeferRendererVisibleWindowNsApplicationCreationActivationScopeReadiness:
            Bool,
        shouldReportRendererVisibleWindowNsApplicationCreationActivationScopeBlocked:
            Bool,
        didPreserveNsApplicationGuardPolicyReadiness: Bool,
        didConfirmApplicationSingletonCreationStillBlocked: Bool,
        didConfirmActivationPolicyMutationStillBlocked: Bool,
        didConfirmApplicationActivationStillBlocked: Bool,
        didConfirmEventLoopStillBlocked: Bool,
        didConfirmBoundedRunLoopPrerequisiteRequired: Bool,
        didConfirmAutoClosePrerequisiteRequired: Bool,
        didKeepHeadlessCiFailClosedRoute: Bool,
        didConfirmNativeVisibleOrderStillBlocked: Bool,
        didConfirmProductionDrawableStillBlocked: Bool,
        didConfirmRenderStillBlocked: Bool,
        didConfirmNoApplicationCreationOrActivation: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNsApplicationCreationActivationScopeReadinessDehydrated: Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.nsApplicationGuardPolicyReadiness =
            nsApplicationGuardPolicyReadiness
        this.nsApplicationCreationActivationScopeAdmission =
            nsApplicationCreationActivationScopeAdmission
        this.didPrepareRendererVisibleWindowNsApplicationCreationActivationScopeReadiness =
            didPrepareRendererVisibleWindowNsApplicationCreationActivationScopeReadiness
        this.shouldDeferRendererVisibleWindowNsApplicationCreationActivationScopeReadiness =
            shouldDeferRendererVisibleWindowNsApplicationCreationActivationScopeReadiness
        this.shouldReportRendererVisibleWindowNsApplicationCreationActivationScopeBlocked =
            shouldReportRendererVisibleWindowNsApplicationCreationActivationScopeBlocked
        this.didPreserveNsApplicationGuardPolicyReadiness =
            didPreserveNsApplicationGuardPolicyReadiness
        this.didConfirmApplicationSingletonCreationStillBlocked =
            didConfirmApplicationSingletonCreationStillBlocked
        this.didConfirmActivationPolicyMutationStillBlocked =
            didConfirmActivationPolicyMutationStillBlocked
        this.didConfirmApplicationActivationStillBlocked =
            didConfirmApplicationActivationStillBlocked
        this.didConfirmEventLoopStillBlocked =
            didConfirmEventLoopStillBlocked
        this.didConfirmBoundedRunLoopPrerequisiteRequired =
            didConfirmBoundedRunLoopPrerequisiteRequired
        this.didConfirmAutoClosePrerequisiteRequired =
            didConfirmAutoClosePrerequisiteRequired
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
        this.didKeepNsApplicationCreationActivationScopeReadinessDehydrated =
            didKeepNsApplicationCreationActivationScopeReadinessDehydrated
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationCreationActivationScopeFacts(
    nsApplicationGuardPolicyReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyReadiness
): CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeFacts {
    let upstreamReady =
        nsApplicationGuardPolicyReadiness
            .didPrepareRendererVisibleWindowNsApplicationGuardPolicyReadiness &&
        nsApplicationGuardPolicyReadiness
            .didConfirmApplicationSingletonOwnershipRequired &&
        nsApplicationGuardPolicyReadiness.didConfirmMainThreadGateRequired &&
        nsApplicationGuardPolicyReadiness
            .didConfirmApplicationCreationStillDeferred &&
        nsApplicationGuardPolicyReadiness.didConfirmActivationStillDeferred &&
        nsApplicationGuardPolicyReadiness
            .didConfirmActivationPolicyStillDeferred &&
        nsApplicationGuardPolicyReadiness.didConfirmEventLoopStillDeferred &&
        nsApplicationGuardPolicyReadiness.didConfirmBoundedRunLoopRequired &&
        nsApplicationGuardPolicyReadiness.didConfirmAutoCloseRequired &&
        nsApplicationGuardPolicyReadiness.didKeepHeadlessCiFailClosedRoute &&
        nsApplicationGuardPolicyReadiness
            .didConfirmNativeVisibleOrderStillBlocked &&
        nsApplicationGuardPolicyReadiness
            .didConfirmProductionDrawableStillBlocked &&
        nsApplicationGuardPolicyReadiness.didConfirmRenderStillBlocked &&
        nsApplicationGuardPolicyReadiness
            .didConfirmNoApplicationCreationOrActivation &&
        nsApplicationGuardPolicyReadiness
            .didConfirmNoPointerHandleClassIdReturn &&
        nsApplicationGuardPolicyReadiness.didConfirmNoPublicSurface &&
        nsApplicationGuardPolicyReadiness.didConfirmNoRendererStateWrite &&
        nsApplicationGuardPolicyReadiness.didConfirmNoBackendReadyTruth &&
        nsApplicationGuardPolicyReadiness
            .didKeepNsApplicationGuardPolicyReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeFacts(
        upstreamReady,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        nsApplicationGuardPolicyReadiness.didKeepHeadlessCiFailClosedRoute,
        nsApplicationGuardPolicyReadiness
            .didConfirmNativeVisibleOrderStillBlocked,
        nsApplicationGuardPolicyReadiness
            .didConfirmProductionDrawableStillBlocked,
        nsApplicationGuardPolicyReadiness.didConfirmRenderStillBlocked,
        nsApplicationGuardPolicyReadiness
            .didConfirmNoApplicationCreationOrActivation,
        nsApplicationGuardPolicyReadiness.didConfirmNoPointerHandleClassIdReturn,
        nsApplicationGuardPolicyReadiness.didConfirmNoPublicSurface,
        nsApplicationGuardPolicyReadiness.didConfirmNoRendererStateWrite,
        nsApplicationGuardPolicyReadiness.didConfirmNoBackendReadyTruth,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationCreationActivationScopeAdmission(
    scopeFacts:
        CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeFacts
): CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeAdmission {
    let didAdmit =
        scopeFacts.didKeepApplicationSingletonCreationBlocked &&
        scopeFacts.didKeepActivationPolicyMutationBlocked &&
        scopeFacts.didKeepApplicationActivationBlocked &&
        scopeFacts.didKeepEventLoopBlocked &&
        scopeFacts.didRequireBoundedRunLoopPrerequisite &&
        scopeFacts.didRequireAutoClosePrerequisite &&
        scopeFacts.didKeepHeadlessCiFailClosedRoute &&
        scopeFacts.didKeepNativeVisibleOrderImplementationBlocked &&
        scopeFacts.didKeepProductionDrawablePermissionBlocked &&
        scopeFacts.didKeepRenderPermissionBlocked &&
        scopeFacts.didConfirmNoApplicationCreationOrActivation &&
        scopeFacts.didConfirmNoPointerHandleClassIdReturn &&
        scopeFacts.didConfirmNoPublicSurface &&
        scopeFacts.didConfirmNoRendererStateWrite &&
        scopeFacts.didConfirmNoBackendReadyTruth &&
        scopeFacts.didKeepScopeFactsValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeAdmission(
        scopeFacts,
        didAdmit,
        !didAdmit,
        !didAdmit,
        scopeFacts.didKeepApplicationSingletonCreationBlocked,
        scopeFacts.didKeepActivationPolicyMutationBlocked,
        scopeFacts.didKeepApplicationActivationBlocked,
        scopeFacts.didKeepEventLoopBlocked,
        scopeFacts.didRequireBoundedRunLoopPrerequisite,
        scopeFacts.didRequireAutoClosePrerequisite,
        scopeFacts.didKeepHeadlessCiFailClosedRoute,
        scopeFacts.didKeepNativeVisibleOrderImplementationBlocked,
        scopeFacts.didKeepProductionDrawablePermissionBlocked,
        scopeFacts.didKeepRenderPermissionBlocked,
        scopeFacts.didKeepScopeFactsValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationCreationActivationScopeReadiness(
    nsApplicationGuardPolicyReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyReadiness,
    nsApplicationCreationActivationScopeAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeAdmission
): CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeReadiness {
    let upstreamReady =
        nsApplicationGuardPolicyReadiness
            .didPrepareRendererVisibleWindowNsApplicationGuardPolicyReadiness &&
        nsApplicationGuardPolicyReadiness.didConfirmNoRendererStateWrite &&
        nsApplicationGuardPolicyReadiness.didConfirmNoBackendReadyTruth
    let admissionReady =
        nsApplicationCreationActivationScopeAdmission
            .didAdmitNsApplicationCreationActivationScopeBoundary &&
        nsApplicationCreationActivationScopeAdmission
            .didConfirmApplicationSingletonCreationStillBlocked &&
        nsApplicationCreationActivationScopeAdmission
            .didConfirmActivationPolicyMutationStillBlocked &&
        nsApplicationCreationActivationScopeAdmission
            .didConfirmApplicationActivationStillBlocked &&
        nsApplicationCreationActivationScopeAdmission
            .didConfirmEventLoopStillBlocked &&
        nsApplicationCreationActivationScopeAdmission
            .didConfirmBoundedRunLoopPrerequisiteRequired &&
        nsApplicationCreationActivationScopeAdmission
            .didConfirmAutoClosePrerequisiteRequired &&
        nsApplicationCreationActivationScopeAdmission
            .didKeepHeadlessCiFailClosedRoute &&
        nsApplicationCreationActivationScopeAdmission
            .didConfirmNativeVisibleOrderStillBlocked &&
        nsApplicationCreationActivationScopeAdmission
            .didConfirmProductionDrawableStillBlocked &&
        nsApplicationCreationActivationScopeAdmission.didConfirmRenderStillBlocked &&
        nsApplicationCreationActivationScopeAdmission
            .didKeepNsApplicationCreationActivationScopeValueOnly
    let readinessReady = upstreamReady && admissionReady
    let scopeFacts = nsApplicationCreationActivationScopeAdmission.scopeFacts

    return CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeReadiness(
        nsApplicationGuardPolicyReadiness,
        nsApplicationCreationActivationScopeAdmission,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        nsApplicationCreationActivationScopeAdmission
            .didConfirmApplicationSingletonCreationStillBlocked,
        nsApplicationCreationActivationScopeAdmission
            .didConfirmActivationPolicyMutationStillBlocked,
        nsApplicationCreationActivationScopeAdmission
            .didConfirmApplicationActivationStillBlocked,
        nsApplicationCreationActivationScopeAdmission
            .didConfirmEventLoopStillBlocked,
        nsApplicationCreationActivationScopeAdmission
            .didConfirmBoundedRunLoopPrerequisiteRequired,
        nsApplicationCreationActivationScopeAdmission
            .didConfirmAutoClosePrerequisiteRequired,
        nsApplicationCreationActivationScopeAdmission
            .didKeepHeadlessCiFailClosedRoute,
        nsApplicationCreationActivationScopeAdmission
            .didConfirmNativeVisibleOrderStillBlocked,
        nsApplicationCreationActivationScopeAdmission
            .didConfirmProductionDrawableStillBlocked,
        nsApplicationCreationActivationScopeAdmission.didConfirmRenderStillBlocked,
        scopeFacts.didConfirmNoApplicationCreationOrActivation,
        scopeFacts.didConfirmNoPointerHandleClassIdReturn,
        scopeFacts.didConfirmNoPublicSurface,
        scopeFacts.didConfirmNoRendererStateWrite,
        scopeFacts.didConfirmNoBackendReadyTruth,
        scopeFacts.didKeepScopeFactsValueOnly,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationCreationActivationScopeDraft():
    CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeReadiness {
    let guardPolicyReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationGuardPolicyDraft()
    let scopeFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationCreationActivationScopeFacts(
            guardPolicyReadiness
        )
    let scopeAdmission =
        cjguiInternalBuildRendererVisibleWindowNsApplicationCreationActivationScopeAdmission(
            scopeFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationCreationActivationScopeReadiness(
        guardPolicyReadiness,
        scopeAdmission
    )
}
