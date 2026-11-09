// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application accessor call preflight value boundary owner。
// Owner: runtime renderer internal NSApplication shared-application accessor
// call preflight owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness，
// 固定 actual application singleton accessor call 仍 blocked、future native
// accessor call guard required、main-thread gate、bounded run loop、auto-close、
// teardown / non-user-visible mode、activation policy / activation / event loop
// blocked、visible-order / drawable / render still-blocked facts。
// Stop-line: 不调用 application singleton accessor，不创建 NSApplication，不
// activation，不修改 activation policy，不运行 event loop，不做 native visible
// order implementation，不获取 drawable，不创建 encoder，不 draw，不提交 GPU work，
// 不执行 render，不返回 Class / id / pointer / handle，不写 runtime_state.cj，
// 不扩 public API，不新增 native bridge C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、visible-ready、
// drawable-ready、render-ready、backend-ready、renderer state write、receipt、record
// 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightFacts {
    let didPreserveAccessorGuardPolicyReadiness: Bool
    let didKeepActualApplicationSingletonAccessorCallBlocked: Bool
    let didKeepApplicationSingletonAccessorScopeBlocked: Bool
    let didKeepApplicationSingletonCreationBlocked: Bool
    let didRequireFutureNativeAccessorCallGuard: Bool
    let didRequireMainThreadGateBeforeFutureAccessorCall: Bool
    let didRequireBoundedRunLoopBeforeFutureAccessorCall: Bool
    let didRequireAutoCloseBeforeFutureAccessorCall: Bool
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
    let didKeepAccessorCallPreflightFactsValueOnly: Bool

    init(
        didPreserveAccessorGuardPolicyReadiness: Bool,
        didKeepActualApplicationSingletonAccessorCallBlocked: Bool,
        didKeepApplicationSingletonAccessorScopeBlocked: Bool,
        didKeepApplicationSingletonCreationBlocked: Bool,
        didRequireFutureNativeAccessorCallGuard: Bool,
        didRequireMainThreadGateBeforeFutureAccessorCall: Bool,
        didRequireBoundedRunLoopBeforeFutureAccessorCall: Bool,
        didRequireAutoCloseBeforeFutureAccessorCall: Bool,
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
        didKeepAccessorCallPreflightFactsValueOnly: Bool
    ) {
        this.didPreserveAccessorGuardPolicyReadiness =
            didPreserveAccessorGuardPolicyReadiness
        this.didKeepActualApplicationSingletonAccessorCallBlocked =
            didKeepActualApplicationSingletonAccessorCallBlocked
        this.didKeepApplicationSingletonAccessorScopeBlocked =
            didKeepApplicationSingletonAccessorScopeBlocked
        this.didKeepApplicationSingletonCreationBlocked =
            didKeepApplicationSingletonCreationBlocked
        this.didRequireFutureNativeAccessorCallGuard =
            didRequireFutureNativeAccessorCallGuard
        this.didRequireMainThreadGateBeforeFutureAccessorCall =
            didRequireMainThreadGateBeforeFutureAccessorCall
        this.didRequireBoundedRunLoopBeforeFutureAccessorCall =
            didRequireBoundedRunLoopBeforeFutureAccessorCall
        this.didRequireAutoCloseBeforeFutureAccessorCall =
            didRequireAutoCloseBeforeFutureAccessorCall
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
        this.didKeepAccessorCallPreflightFactsValueOnly =
            didKeepAccessorCallPreflightFactsValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightAdmission {
    let preflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightFacts
    let didAdmitNsApplicationSharedApplicationAccessorCallPreflightBoundary:
        Bool
    let shouldDeferNsApplicationSharedApplicationAccessorCallPreflightBoundary:
        Bool
    let shouldReportNsApplicationSharedApplicationAccessorCallPreflightBlocked:
        Bool
    let didConfirmFutureNativeAccessorCallGuardRequired: Bool
    let didConfirmActualApplicationSingletonAccessorCallStillBlocked: Bool
    let didConfirmApplicationSingletonAccessorScopeStillBlocked: Bool
    let didConfirmApplicationSingletonCreationStillBlocked: Bool
    let didConfirmMainThreadGateRequired: Bool
    let didConfirmBoundedRunLoopPrerequisiteRequired: Bool
    let didConfirmAutoClosePrerequisiteRequired: Bool
    let didConfirmTeardownBeforeVisibleModeRequired: Bool
    let didConfirmNonUserVisibleModeRequired: Bool
    let didConfirmNoApplicationSingletonAccessorCall: Bool
    let didKeepNsApplicationSharedApplicationAccessorCallPreflightValueOnly:
        Bool

    init(
        preflightFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightFacts,
        didAdmitNsApplicationSharedApplicationAccessorCallPreflightBoundary:
            Bool,
        shouldDeferNsApplicationSharedApplicationAccessorCallPreflightBoundary:
            Bool,
        shouldReportNsApplicationSharedApplicationAccessorCallPreflightBlocked:
            Bool,
        didConfirmFutureNativeAccessorCallGuardRequired: Bool,
        didConfirmActualApplicationSingletonAccessorCallStillBlocked: Bool,
        didConfirmApplicationSingletonAccessorScopeStillBlocked: Bool,
        didConfirmApplicationSingletonCreationStillBlocked: Bool,
        didConfirmMainThreadGateRequired: Bool,
        didConfirmBoundedRunLoopPrerequisiteRequired: Bool,
        didConfirmAutoClosePrerequisiteRequired: Bool,
        didConfirmTeardownBeforeVisibleModeRequired: Bool,
        didConfirmNonUserVisibleModeRequired: Bool,
        didConfirmNoApplicationSingletonAccessorCall: Bool,
        didKeepNsApplicationSharedApplicationAccessorCallPreflightValueOnly:
            Bool
    ) {
        this.preflightFacts = preflightFacts
        this.didAdmitNsApplicationSharedApplicationAccessorCallPreflightBoundary =
            didAdmitNsApplicationSharedApplicationAccessorCallPreflightBoundary
        this.shouldDeferNsApplicationSharedApplicationAccessorCallPreflightBoundary =
            shouldDeferNsApplicationSharedApplicationAccessorCallPreflightBoundary
        this.shouldReportNsApplicationSharedApplicationAccessorCallPreflightBlocked =
            shouldReportNsApplicationSharedApplicationAccessorCallPreflightBlocked
        this.didConfirmFutureNativeAccessorCallGuardRequired =
            didConfirmFutureNativeAccessorCallGuardRequired
        this.didConfirmActualApplicationSingletonAccessorCallStillBlocked =
            didConfirmActualApplicationSingletonAccessorCallStillBlocked
        this.didConfirmApplicationSingletonAccessorScopeStillBlocked =
            didConfirmApplicationSingletonAccessorScopeStillBlocked
        this.didConfirmApplicationSingletonCreationStillBlocked =
            didConfirmApplicationSingletonCreationStillBlocked
        this.didConfirmMainThreadGateRequired =
            didConfirmMainThreadGateRequired
        this.didConfirmBoundedRunLoopPrerequisiteRequired =
            didConfirmBoundedRunLoopPrerequisiteRequired
        this.didConfirmAutoClosePrerequisiteRequired =
            didConfirmAutoClosePrerequisiteRequired
        this.didConfirmTeardownBeforeVisibleModeRequired =
            didConfirmTeardownBeforeVisibleModeRequired
        this.didConfirmNonUserVisibleModeRequired =
            didConfirmNonUserVisibleModeRequired
        this.didConfirmNoApplicationSingletonAccessorCall =
            didConfirmNoApplicationSingletonAccessorCall
        this.didKeepNsApplicationSharedApplicationAccessorCallPreflightValueOnly =
            didKeepNsApplicationSharedApplicationAccessorCallPreflightValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness {
    let nsApplicationSharedApplicationAccessorGuardPolicyReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness
    let nsApplicationSharedApplicationAccessorCallPreflightAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightAdmission
    let didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness:
        Bool
    let shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness:
        Bool
    let shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightBlocked:
        Bool
    let didPreserveNsApplicationSharedApplicationAccessorGuardPolicyReadiness:
        Bool
    let didConfirmFutureNativeAccessorCallGuardRequired: Bool
    let didConfirmActualApplicationSingletonAccessorCallStillBlocked: Bool
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
    let didKeepNsApplicationSharedApplicationAccessorCallPreflightReadinessDehydrated:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness,
        nsApplicationSharedApplicationAccessorCallPreflightAdmission:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightAdmission,
        didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness:
            Bool,
        shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness:
            Bool,
        shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightBlocked:
            Bool,
        didPreserveNsApplicationSharedApplicationAccessorGuardPolicyReadiness:
            Bool,
        didConfirmFutureNativeAccessorCallGuardRequired: Bool,
        didConfirmActualApplicationSingletonAccessorCallStillBlocked: Bool,
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
        didKeepNsApplicationSharedApplicationAccessorCallPreflightReadinessDehydrated:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.nsApplicationSharedApplicationAccessorGuardPolicyReadiness =
            nsApplicationSharedApplicationAccessorGuardPolicyReadiness
        this.nsApplicationSharedApplicationAccessorCallPreflightAdmission =
            nsApplicationSharedApplicationAccessorCallPreflightAdmission
        this.didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness =
            didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness
        this.shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness =
            shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness
        this.shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightBlocked =
            shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightBlocked
        this.didPreserveNsApplicationSharedApplicationAccessorGuardPolicyReadiness =
            didPreserveNsApplicationSharedApplicationAccessorGuardPolicyReadiness
        this.didConfirmFutureNativeAccessorCallGuardRequired =
            didConfirmFutureNativeAccessorCallGuardRequired
        this.didConfirmActualApplicationSingletonAccessorCallStillBlocked =
            didConfirmActualApplicationSingletonAccessorCallStillBlocked
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
        this.didKeepNsApplicationSharedApplicationAccessorCallPreflightReadinessDehydrated =
            didKeepNsApplicationSharedApplicationAccessorCallPreflightReadinessDehydrated
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightFacts(
    nsApplicationSharedApplicationAccessorGuardPolicyReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightFacts {
    let upstreamReady =
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmApplicationSingletonAccessorCallStillBlocked &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmApplicationSingletonAccessorScopeStillBlocked &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmApplicationSingletonCreationStillBlocked &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmSharedApplicationMainThreadGateRequired &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmBoundedRunLoopPrerequisiteRequired &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmAutoClosePrerequisiteRequired &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmHeadlessCiFailClosedRoute &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmTeardownBeforeVisibleModeRequired &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmNonUserVisibleModeRequired &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmActivationPolicyMutationStillBlocked &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmApplicationActivationStillBlocked &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmEventLoopStillBlocked &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmNativeVisibleOrderStillBlocked &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmProductionDrawableStillBlocked &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmRenderStillBlocked &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmNoApplicationSingletonAccessorCall &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmNoApplicationCreationOrActivation &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmNoPointerHandleClassIdReturn &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmNoPublicSurface &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmNoRendererStateWrite &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmNoBackendReadyTruth &&
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didKeepNsApplicationSharedApplicationAccessorGuardPolicyReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightFacts(
        upstreamReady,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmApplicationSingletonAccessorCallStillBlocked,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmApplicationSingletonAccessorScopeStillBlocked,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmApplicationSingletonCreationStillBlocked,
        true,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmSharedApplicationMainThreadGateRequired,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmBoundedRunLoopPrerequisiteRequired,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmAutoClosePrerequisiteRequired,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmHeadlessCiFailClosedRoute,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmTeardownBeforeVisibleModeRequired,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmNonUserVisibleModeRequired,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmActivationPolicyMutationStillBlocked,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmApplicationActivationStillBlocked,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmEventLoopStillBlocked,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmNativeVisibleOrderStillBlocked,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmProductionDrawableStillBlocked,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmRenderStillBlocked,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmNoApplicationSingletonAccessorCall,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmNoApplicationCreationOrActivation,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmNoPointerHandleClassIdReturn,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmNoPublicSurface,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmNoRendererStateWrite,
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didConfirmNoBackendReadyTruth,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightAdmission(
    preflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightAdmission {
    let didAdmit =
        preflightFacts.didPreserveAccessorGuardPolicyReadiness &&
        preflightFacts.didKeepActualApplicationSingletonAccessorCallBlocked &&
        preflightFacts.didKeepApplicationSingletonAccessorScopeBlocked &&
        preflightFacts.didKeepApplicationSingletonCreationBlocked &&
        preflightFacts.didRequireFutureNativeAccessorCallGuard &&
        preflightFacts.didRequireMainThreadGateBeforeFutureAccessorCall &&
        preflightFacts.didRequireBoundedRunLoopBeforeFutureAccessorCall &&
        preflightFacts.didRequireAutoCloseBeforeFutureAccessorCall &&
        preflightFacts.didKeepHeadlessCiFailClosedRoute &&
        preflightFacts.didRequireTeardownBeforeVisibleMode &&
        preflightFacts.didRequireNonUserVisibleMode &&
        preflightFacts.didKeepActivationPolicyMutationBlocked &&
        preflightFacts.didKeepApplicationActivationBlocked &&
        preflightFacts.didKeepEventLoopBlocked &&
        preflightFacts.didKeepNativeVisibleOrderImplementationBlocked &&
        preflightFacts.didKeepProductionDrawablePermissionBlocked &&
        preflightFacts.didKeepRenderPermissionBlocked &&
        preflightFacts.didConfirmNoApplicationSingletonAccessorCall &&
        preflightFacts.didConfirmNoApplicationCreationOrActivation &&
        preflightFacts.didConfirmNoPointerHandleClassIdReturn &&
        preflightFacts.didConfirmNoPublicSurface &&
        preflightFacts.didConfirmNoRendererStateWrite &&
        preflightFacts.didConfirmNoBackendReadyTruth &&
        preflightFacts.didKeepAccessorCallPreflightFactsValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightAdmission(
        preflightFacts,
        didAdmit,
        !didAdmit,
        !didAdmit,
        preflightFacts.didRequireFutureNativeAccessorCallGuard,
        preflightFacts.didKeepActualApplicationSingletonAccessorCallBlocked,
        preflightFacts.didKeepApplicationSingletonAccessorScopeBlocked,
        preflightFacts.didKeepApplicationSingletonCreationBlocked,
        preflightFacts.didRequireMainThreadGateBeforeFutureAccessorCall,
        preflightFacts.didRequireBoundedRunLoopBeforeFutureAccessorCall,
        preflightFacts.didRequireAutoCloseBeforeFutureAccessorCall,
        preflightFacts.didRequireTeardownBeforeVisibleMode,
        preflightFacts.didRequireNonUserVisibleMode,
        preflightFacts.didConfirmNoApplicationSingletonAccessorCall,
        preflightFacts.didKeepAccessorCallPreflightFactsValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness(
    nsApplicationSharedApplicationAccessorGuardPolicyReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness,
    nsApplicationSharedApplicationAccessorCallPreflightAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightAdmission
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness {
    let preflightFacts = nsApplicationSharedApplicationAccessorCallPreflightAdmission
        .preflightFacts
    let admissionReady =
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didAdmitNsApplicationSharedApplicationAccessorCallPreflightBoundary &&
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didConfirmFutureNativeAccessorCallGuardRequired &&
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didConfirmActualApplicationSingletonAccessorCallStillBlocked &&
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didConfirmApplicationSingletonAccessorScopeStillBlocked &&
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didConfirmApplicationSingletonCreationStillBlocked &&
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didConfirmMainThreadGateRequired &&
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didConfirmBoundedRunLoopPrerequisiteRequired &&
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didConfirmAutoClosePrerequisiteRequired &&
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didConfirmTeardownBeforeVisibleModeRequired &&
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didConfirmNonUserVisibleModeRequired &&
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didConfirmNoApplicationSingletonAccessorCall &&
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didKeepNsApplicationSharedApplicationAccessorCallPreflightValueOnly
    let readinessReady =
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness &&
        preflightFacts.didPreserveAccessorGuardPolicyReadiness &&
        admissionReady

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness(
        nsApplicationSharedApplicationAccessorGuardPolicyReadiness,
        nsApplicationSharedApplicationAccessorCallPreflightAdmission,
        readinessReady,
        !readinessReady,
        !readinessReady,
        preflightFacts.didPreserveAccessorGuardPolicyReadiness,
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didConfirmFutureNativeAccessorCallGuardRequired,
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didConfirmActualApplicationSingletonAccessorCallStillBlocked,
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didConfirmApplicationSingletonAccessorScopeStillBlocked,
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didConfirmApplicationSingletonCreationStillBlocked,
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didConfirmMainThreadGateRequired,
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didConfirmBoundedRunLoopPrerequisiteRequired,
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didConfirmAutoClosePrerequisiteRequired,
        preflightFacts.didKeepHeadlessCiFailClosedRoute,
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didConfirmTeardownBeforeVisibleModeRequired,
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didConfirmNonUserVisibleModeRequired,
        preflightFacts.didKeepActivationPolicyMutationBlocked,
        preflightFacts.didKeepApplicationActivationBlocked,
        preflightFacts.didKeepEventLoopBlocked,
        preflightFacts.didKeepNativeVisibleOrderImplementationBlocked,
        preflightFacts.didKeepProductionDrawablePermissionBlocked,
        preflightFacts.didKeepRenderPermissionBlocked,
        nsApplicationSharedApplicationAccessorCallPreflightAdmission
            .didConfirmNoApplicationSingletonAccessorCall,
        preflightFacts.didConfirmNoApplicationCreationOrActivation,
        preflightFacts.didConfirmNoPointerHandleClassIdReturn,
        preflightFacts.didConfirmNoPublicSurface,
        preflightFacts.didConfirmNoRendererStateWrite,
        preflightFacts.didConfirmNoBackendReadyTruth,
        preflightFacts.didKeepAccessorCallPreflightFactsValueOnly,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness {
    let accessorGuardPolicyReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyDraft()
    let preflightFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightFacts(
            accessorGuardPolicyReadiness
        )
    let preflightAdmission =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightAdmission(
            preflightFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness(
        accessorGuardPolicyReadiness,
        preflightAdmission
    )
}
