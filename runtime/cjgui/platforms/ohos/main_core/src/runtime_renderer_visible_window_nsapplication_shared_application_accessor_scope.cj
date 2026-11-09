// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application accessor scope value boundary owner。
// Owner: runtime renderer internal NSApplication shared-application accessor
// scope owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness，
// 固定 application singleton accessor scope / accessor call / singleton creation
// 仍 blocked，并保留 main-thread gate、bounded run loop、auto-close、teardown /
// non-user-visible mode、activation policy / activation / event loop blocked、
// visible-order / drawable / render still-blocked facts。
// Stop-line: 不调用 application singleton accessor，不创建 NSApplication，不
// activation，不修改 activation policy，不运行 event loop，不做 native visible
// order implementation，不获取 drawable，不创建 encoder，不 draw，不提交 GPU work，
// 不执行 render，不返回 Class / id / pointer / handle，不写 runtime_state.cj，
// 不扩 public API。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、visible-ready、
// drawable-ready、render-ready、backend-ready、renderer state write、receipt、record
// 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeFacts {
    let didKeepApplicationSingletonAccessorScopeBlocked: Bool
    let didKeepApplicationSingletonAccessorBlocked: Bool
    let didKeepApplicationSingletonCreationBlocked: Bool
    let didRequireSharedApplicationMainThreadGate: Bool
    let didRequireBoundedRunLoopBeforeAccessorScope: Bool
    let didRequireAutoCloseBeforeAccessorScope: Bool
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
    let didKeepAccessorScopeFactsValueOnly: Bool

    init(
        didKeepApplicationSingletonAccessorScopeBlocked: Bool,
        didKeepApplicationSingletonAccessorBlocked: Bool,
        didKeepApplicationSingletonCreationBlocked: Bool,
        didRequireSharedApplicationMainThreadGate: Bool,
        didRequireBoundedRunLoopBeforeAccessorScope: Bool,
        didRequireAutoCloseBeforeAccessorScope: Bool,
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
        didKeepAccessorScopeFactsValueOnly: Bool
    ) {
        this.didKeepApplicationSingletonAccessorScopeBlocked =
            didKeepApplicationSingletonAccessorScopeBlocked
        this.didKeepApplicationSingletonAccessorBlocked =
            didKeepApplicationSingletonAccessorBlocked
        this.didKeepApplicationSingletonCreationBlocked =
            didKeepApplicationSingletonCreationBlocked
        this.didRequireSharedApplicationMainThreadGate =
            didRequireSharedApplicationMainThreadGate
        this.didRequireBoundedRunLoopBeforeAccessorScope =
            didRequireBoundedRunLoopBeforeAccessorScope
        this.didRequireAutoCloseBeforeAccessorScope =
            didRequireAutoCloseBeforeAccessorScope
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
        this.didKeepAccessorScopeFactsValueOnly =
            didKeepAccessorScopeFactsValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeAdmission {
    let scopeFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeFacts
    let didAdmitNsApplicationSharedApplicationAccessorScopeBoundary: Bool
    let shouldDeferNsApplicationSharedApplicationAccessorScopeBoundary: Bool
    let shouldReportNsApplicationSharedApplicationAccessorScopeBlocked: Bool
    let didConfirmApplicationSingletonAccessorScopeStillBlocked: Bool
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
    let didKeepNsApplicationSharedApplicationAccessorScopeValueOnly: Bool

    init(
        scopeFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeFacts,
        didAdmitNsApplicationSharedApplicationAccessorScopeBoundary: Bool,
        shouldDeferNsApplicationSharedApplicationAccessorScopeBoundary: Bool,
        shouldReportNsApplicationSharedApplicationAccessorScopeBlocked: Bool,
        didConfirmApplicationSingletonAccessorScopeStillBlocked: Bool,
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
        didKeepNsApplicationSharedApplicationAccessorScopeValueOnly: Bool
    ) {
        this.scopeFacts = scopeFacts
        this.didAdmitNsApplicationSharedApplicationAccessorScopeBoundary =
            didAdmitNsApplicationSharedApplicationAccessorScopeBoundary
        this.shouldDeferNsApplicationSharedApplicationAccessorScopeBoundary =
            shouldDeferNsApplicationSharedApplicationAccessorScopeBoundary
        this.shouldReportNsApplicationSharedApplicationAccessorScopeBlocked =
            shouldReportNsApplicationSharedApplicationAccessorScopeBlocked
        this.didConfirmApplicationSingletonAccessorScopeStillBlocked =
            didConfirmApplicationSingletonAccessorScopeStillBlocked
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
        this.didKeepNsApplicationSharedApplicationAccessorScopeValueOnly =
            didKeepNsApplicationSharedApplicationAccessorScopeValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness {
    let nsApplicationSharedApplicationGuardPolicyReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness
    let nsApplicationSharedApplicationAccessorScopeAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeAdmission
    let didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness:
        Bool
    let shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness:
        Bool
    let shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeBlocked:
        Bool
    let didPreserveNsApplicationSharedApplicationGuardPolicyReadiness: Bool
    let didConfirmApplicationSingletonAccessorScopeStillBlocked: Bool
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
    let didKeepNsApplicationSharedApplicationAccessorScopeReadinessDehydrated:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        nsApplicationSharedApplicationGuardPolicyReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness,
        nsApplicationSharedApplicationAccessorScopeAdmission:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeAdmission,
        didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness:
            Bool,
        shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness:
            Bool,
        shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeBlocked:
            Bool,
        didPreserveNsApplicationSharedApplicationGuardPolicyReadiness: Bool,
        didConfirmApplicationSingletonAccessorScopeStillBlocked: Bool,
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
        didKeepNsApplicationSharedApplicationAccessorScopeReadinessDehydrated:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.nsApplicationSharedApplicationGuardPolicyReadiness =
            nsApplicationSharedApplicationGuardPolicyReadiness
        this.nsApplicationSharedApplicationAccessorScopeAdmission =
            nsApplicationSharedApplicationAccessorScopeAdmission
        this.didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness =
            didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness
        this.shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness =
            shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness
        this.shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeBlocked =
            shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeBlocked
        this.didPreserveNsApplicationSharedApplicationGuardPolicyReadiness =
            didPreserveNsApplicationSharedApplicationGuardPolicyReadiness
        this.didConfirmApplicationSingletonAccessorScopeStillBlocked =
            didConfirmApplicationSingletonAccessorScopeStillBlocked
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
        this.didKeepNsApplicationSharedApplicationAccessorScopeReadinessDehydrated =
            didKeepNsApplicationSharedApplicationAccessorScopeReadinessDehydrated
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeFacts(
    nsApplicationSharedApplicationGuardPolicyReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeFacts {
    let upstreamReady =
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmApplicationSingletonAccessorStillBlocked &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmApplicationSingletonCreationStillBlocked &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmSharedApplicationMainThreadGateRequired &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmBoundedRunLoopPrerequisiteRequired &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmAutoClosePrerequisiteRequired &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didKeepHeadlessCiFailClosedRoute &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmTeardownBeforeVisibleModeRequired &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmNonUserVisibleModeRequired &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmActivationPolicyMutationStillBlocked &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmApplicationActivationStillBlocked &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmEventLoopStillBlocked &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmNativeVisibleOrderStillBlocked &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmProductionDrawableStillBlocked &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmRenderStillBlocked &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmNoApplicationSingletonAccessorCall &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmNoApplicationCreationOrActivation &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmNoPointerHandleClassIdReturn &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmNoPublicSurface &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmNoRendererStateWrite &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmNoBackendReadyTruth &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didKeepNsApplicationSharedApplicationGuardPolicyReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeFacts(
        upstreamReady,
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmApplicationSingletonAccessorStillBlocked,
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmApplicationSingletonCreationStillBlocked,
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmSharedApplicationMainThreadGateRequired,
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmBoundedRunLoopPrerequisiteRequired,
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmAutoClosePrerequisiteRequired,
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didKeepHeadlessCiFailClosedRoute,
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmTeardownBeforeVisibleModeRequired,
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmNonUserVisibleModeRequired,
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmActivationPolicyMutationStillBlocked,
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmApplicationActivationStillBlocked,
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmEventLoopStillBlocked,
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmNativeVisibleOrderStillBlocked,
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmProductionDrawableStillBlocked,
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmRenderStillBlocked,
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmNoApplicationSingletonAccessorCall,
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmNoApplicationCreationOrActivation,
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmNoPointerHandleClassIdReturn,
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmNoPublicSurface,
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmNoRendererStateWrite,
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmNoBackendReadyTruth,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeAdmission(
    scopeFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeAdmission {
    let didAdmit =
        scopeFacts.didKeepApplicationSingletonAccessorScopeBlocked &&
        scopeFacts.didKeepApplicationSingletonAccessorBlocked &&
        scopeFacts.didKeepApplicationSingletonCreationBlocked &&
        scopeFacts.didRequireSharedApplicationMainThreadGate &&
        scopeFacts.didRequireBoundedRunLoopBeforeAccessorScope &&
        scopeFacts.didRequireAutoCloseBeforeAccessorScope &&
        scopeFacts.didKeepHeadlessCiFailClosedRoute &&
        scopeFacts.didRequireTeardownBeforeVisibleMode &&
        scopeFacts.didRequireNonUserVisibleMode &&
        scopeFacts.didKeepActivationPolicyMutationBlocked &&
        scopeFacts.didKeepApplicationActivationBlocked &&
        scopeFacts.didKeepEventLoopBlocked &&
        scopeFacts.didKeepNativeVisibleOrderImplementationBlocked &&
        scopeFacts.didKeepProductionDrawablePermissionBlocked &&
        scopeFacts.didKeepRenderPermissionBlocked &&
        scopeFacts.didConfirmNoApplicationSingletonAccessorCall &&
        scopeFacts.didConfirmNoApplicationCreationOrActivation &&
        scopeFacts.didConfirmNoPointerHandleClassIdReturn &&
        scopeFacts.didConfirmNoPublicSurface &&
        scopeFacts.didConfirmNoRendererStateWrite &&
        scopeFacts.didConfirmNoBackendReadyTruth &&
        scopeFacts.didKeepAccessorScopeFactsValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeAdmission(
        scopeFacts,
        didAdmit,
        !didAdmit,
        !didAdmit,
        scopeFacts.didKeepApplicationSingletonAccessorScopeBlocked,
        scopeFacts.didKeepApplicationSingletonAccessorBlocked,
        scopeFacts.didKeepApplicationSingletonCreationBlocked,
        scopeFacts.didRequireSharedApplicationMainThreadGate,
        scopeFacts.didRequireBoundedRunLoopBeforeAccessorScope,
        scopeFacts.didRequireAutoCloseBeforeAccessorScope,
        scopeFacts.didKeepHeadlessCiFailClosedRoute,
        scopeFacts.didRequireTeardownBeforeVisibleMode,
        scopeFacts.didRequireNonUserVisibleMode,
        scopeFacts.didKeepActivationPolicyMutationBlocked,
        scopeFacts.didKeepApplicationActivationBlocked,
        scopeFacts.didKeepEventLoopBlocked,
        scopeFacts.didKeepNativeVisibleOrderImplementationBlocked,
        scopeFacts.didKeepProductionDrawablePermissionBlocked,
        scopeFacts.didKeepRenderPermissionBlocked,
        scopeFacts.didConfirmNoApplicationSingletonAccessorCall,
        scopeFacts.didKeepAccessorScopeFactsValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness(
    nsApplicationSharedApplicationGuardPolicyReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness,
    nsApplicationSharedApplicationAccessorScopeAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeAdmission
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness {
    let upstreamReady =
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmNoRendererStateWrite &&
        nsApplicationSharedApplicationGuardPolicyReadiness
            .didConfirmNoBackendReadyTruth
    let admissionReady =
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didAdmitNsApplicationSharedApplicationAccessorScopeBoundary &&
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmApplicationSingletonAccessorScopeStillBlocked &&
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmApplicationSingletonAccessorStillBlocked &&
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmApplicationSingletonCreationStillBlocked &&
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmSharedApplicationMainThreadGateRequired &&
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmBoundedRunLoopPrerequisiteRequired &&
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmAutoClosePrerequisiteRequired &&
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didKeepHeadlessCiFailClosedRoute &&
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmTeardownBeforeVisibleModeRequired &&
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmNonUserVisibleModeRequired &&
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmActivationPolicyMutationStillBlocked &&
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmApplicationActivationStillBlocked &&
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmEventLoopStillBlocked &&
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmNativeVisibleOrderStillBlocked &&
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmProductionDrawableStillBlocked &&
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmRenderStillBlocked &&
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmNoApplicationSingletonAccessorCall &&
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didKeepNsApplicationSharedApplicationAccessorScopeValueOnly
    let readinessReady = upstreamReady && admissionReady
    let scopeFacts = nsApplicationSharedApplicationAccessorScopeAdmission
        .scopeFacts

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness(
        nsApplicationSharedApplicationGuardPolicyReadiness,
        nsApplicationSharedApplicationAccessorScopeAdmission,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmApplicationSingletonAccessorScopeStillBlocked,
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmApplicationSingletonAccessorStillBlocked,
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmApplicationSingletonCreationStillBlocked,
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmSharedApplicationMainThreadGateRequired,
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmBoundedRunLoopPrerequisiteRequired,
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmAutoClosePrerequisiteRequired,
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didKeepHeadlessCiFailClosedRoute,
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmTeardownBeforeVisibleModeRequired,
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmNonUserVisibleModeRequired,
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmActivationPolicyMutationStillBlocked,
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmApplicationActivationStillBlocked,
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmEventLoopStillBlocked,
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmNativeVisibleOrderStillBlocked,
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmProductionDrawableStillBlocked,
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmRenderStillBlocked,
        nsApplicationSharedApplicationAccessorScopeAdmission
            .didConfirmNoApplicationSingletonAccessorCall,
        scopeFacts.didConfirmNoApplicationCreationOrActivation,
        scopeFacts.didConfirmNoPointerHandleClassIdReturn,
        scopeFacts.didConfirmNoPublicSurface,
        scopeFacts.didConfirmNoRendererStateWrite,
        scopeFacts.didConfirmNoBackendReadyTruth,
        scopeFacts.didKeepAccessorScopeFactsValueOnly,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness {
    let guardPolicyReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyDraft()
    let scopeFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeFacts(
            guardPolicyReadiness
        )
    let scopeAdmission =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeAdmission(
            scopeFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness(
        guardPolicyReadiness,
        scopeAdmission
    )
}
