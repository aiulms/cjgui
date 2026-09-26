// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared application creation feasibility value boundary owner。
// Owner: runtime renderer internal NSApplication shared application feasibility owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeReadiness，
// 固定 shared application singleton access、application singleton creation、activation
// policy mutation、activation、event loop 仍 blocked，并保留 main-thread affinity、
// bounded run loop、auto-close、headless fail-closed、teardown / non-user-visible mode、
// visible-order / drawable / render still-blocked facts。
// Stop-line: 不创建 NSApplication，不调用 application singleton accessor，不 activation，
// 不修改 activation policy，不运行 event loop，不做 native visible order implementation，
// 不获取 drawable，不创建 encoder，不 draw，不提交 GPU work，不执行 render，不返回
// Class / id / pointer / handle，不写 runtime_state.cj，不扩 public API。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、visible-ready、
// drawable-ready、render-ready、backend-ready、renderer state write、receipt、record
// 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityFacts {
    let didKeepSharedApplicationCallBlocked: Bool
    let didKeepApplicationSingletonCreationBlocked: Bool
    let didRequireMainThreadAffinity: Bool
    let didKeepHeadlessCiFailClosedRoute: Bool
    let didRequireBoundedRunLoopPrerequisite: Bool
    let didRequireAutoClosePrerequisite: Bool
    let didRequireTeardownBeforeVisibleMode: Bool
    let didRequireNonUserVisibleMode: Bool
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
    let didKeepFeasibilityFactsValueOnly: Bool

    init(
        didKeepSharedApplicationCallBlocked: Bool,
        didKeepApplicationSingletonCreationBlocked: Bool,
        didRequireMainThreadAffinity: Bool,
        didKeepHeadlessCiFailClosedRoute: Bool,
        didRequireBoundedRunLoopPrerequisite: Bool,
        didRequireAutoClosePrerequisite: Bool,
        didRequireTeardownBeforeVisibleMode: Bool,
        didRequireNonUserVisibleMode: Bool,
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
        didKeepFeasibilityFactsValueOnly: Bool
    ) {
        this.didKeepSharedApplicationCallBlocked =
            didKeepSharedApplicationCallBlocked
        this.didKeepApplicationSingletonCreationBlocked =
            didKeepApplicationSingletonCreationBlocked
        this.didRequireMainThreadAffinity = didRequireMainThreadAffinity
        this.didKeepHeadlessCiFailClosedRoute =
            didKeepHeadlessCiFailClosedRoute
        this.didRequireBoundedRunLoopPrerequisite =
            didRequireBoundedRunLoopPrerequisite
        this.didRequireAutoClosePrerequisite =
            didRequireAutoClosePrerequisite
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
        this.didConfirmNoApplicationCreationOrActivation =
            didConfirmNoApplicationCreationOrActivation
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepFeasibilityFactsValueOnly =
            didKeepFeasibilityFactsValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityAdmission {
    let feasibilityFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityFacts
    let didAdmitNsApplicationSharedApplicationFeasibilityBoundary: Bool
    let shouldDeferNsApplicationSharedApplicationFeasibilityBoundary: Bool
    let shouldReportNsApplicationSharedApplicationFeasibilityBlocked: Bool
    let didConfirmSharedApplicationCallStillBlocked: Bool
    let didConfirmApplicationSingletonCreationStillBlocked: Bool
    let didConfirmMainThreadAffinityRequired: Bool
    let didConfirmHeadlessCiFailClosedRoute: Bool
    let didConfirmBoundedRunLoopPrerequisiteRequired: Bool
    let didConfirmAutoClosePrerequisiteRequired: Bool
    let didConfirmTeardownBeforeVisibleModeRequired: Bool
    let didConfirmNonUserVisibleModeRequired: Bool
    let didConfirmActivationPolicyMutationStillBlocked: Bool
    let didConfirmApplicationActivationStillBlocked: Bool
    let didConfirmEventLoopStillBlocked: Bool
    let didConfirmNativeVisibleOrderStillBlocked: Bool
    let didConfirmProductionDrawableStillBlocked: Bool
    let didConfirmRenderStillBlocked: Bool
    let didKeepNsApplicationSharedApplicationFeasibilityValueOnly: Bool

    init(
        feasibilityFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityFacts,
        didAdmitNsApplicationSharedApplicationFeasibilityBoundary: Bool,
        shouldDeferNsApplicationSharedApplicationFeasibilityBoundary: Bool,
        shouldReportNsApplicationSharedApplicationFeasibilityBlocked: Bool,
        didConfirmSharedApplicationCallStillBlocked: Bool,
        didConfirmApplicationSingletonCreationStillBlocked: Bool,
        didConfirmMainThreadAffinityRequired: Bool,
        didConfirmHeadlessCiFailClosedRoute: Bool,
        didConfirmBoundedRunLoopPrerequisiteRequired: Bool,
        didConfirmAutoClosePrerequisiteRequired: Bool,
        didConfirmTeardownBeforeVisibleModeRequired: Bool,
        didConfirmNonUserVisibleModeRequired: Bool,
        didConfirmActivationPolicyMutationStillBlocked: Bool,
        didConfirmApplicationActivationStillBlocked: Bool,
        didConfirmEventLoopStillBlocked: Bool,
        didConfirmNativeVisibleOrderStillBlocked: Bool,
        didConfirmProductionDrawableStillBlocked: Bool,
        didConfirmRenderStillBlocked: Bool,
        didKeepNsApplicationSharedApplicationFeasibilityValueOnly: Bool
    ) {
        this.feasibilityFacts = feasibilityFacts
        this.didAdmitNsApplicationSharedApplicationFeasibilityBoundary =
            didAdmitNsApplicationSharedApplicationFeasibilityBoundary
        this.shouldDeferNsApplicationSharedApplicationFeasibilityBoundary =
            shouldDeferNsApplicationSharedApplicationFeasibilityBoundary
        this.shouldReportNsApplicationSharedApplicationFeasibilityBlocked =
            shouldReportNsApplicationSharedApplicationFeasibilityBlocked
        this.didConfirmSharedApplicationCallStillBlocked =
            didConfirmSharedApplicationCallStillBlocked
        this.didConfirmApplicationSingletonCreationStillBlocked =
            didConfirmApplicationSingletonCreationStillBlocked
        this.didConfirmMainThreadAffinityRequired =
            didConfirmMainThreadAffinityRequired
        this.didConfirmHeadlessCiFailClosedRoute =
            didConfirmHeadlessCiFailClosedRoute
        this.didConfirmBoundedRunLoopPrerequisiteRequired =
            didConfirmBoundedRunLoopPrerequisiteRequired
        this.didConfirmAutoClosePrerequisiteRequired =
            didConfirmAutoClosePrerequisiteRequired
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
        this.didKeepNsApplicationSharedApplicationFeasibilityValueOnly =
            didKeepNsApplicationSharedApplicationFeasibilityValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness {
    let nsApplicationCreationActivationScopeReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeReadiness
    let nsApplicationSharedApplicationFeasibilityAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityAdmission
    let didPrepareRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness:
        Bool
    let shouldDeferRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness:
        Bool
    let shouldReportRendererVisibleWindowNsApplicationSharedApplicationFeasibilityBlocked:
        Bool
    let didPreserveNsApplicationCreationActivationScopeReadiness: Bool
    let didConfirmSharedApplicationCallStillBlocked: Bool
    let didConfirmApplicationSingletonCreationStillBlocked: Bool
    let didConfirmMainThreadAffinityRequired: Bool
    let didConfirmHeadlessCiFailClosedRoute: Bool
    let didConfirmBoundedRunLoopPrerequisiteRequired: Bool
    let didConfirmAutoClosePrerequisiteRequired: Bool
    let didConfirmTeardownBeforeVisibleModeRequired: Bool
    let didConfirmNonUserVisibleModeRequired: Bool
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
    let didKeepNsApplicationSharedApplicationFeasibilityReadinessDehydrated:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        nsApplicationCreationActivationScopeReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeReadiness,
        nsApplicationSharedApplicationFeasibilityAdmission:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityAdmission,
        didPrepareRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness:
            Bool,
        shouldDeferRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness:
            Bool,
        shouldReportRendererVisibleWindowNsApplicationSharedApplicationFeasibilityBlocked:
            Bool,
        didPreserveNsApplicationCreationActivationScopeReadiness: Bool,
        didConfirmSharedApplicationCallStillBlocked: Bool,
        didConfirmApplicationSingletonCreationStillBlocked: Bool,
        didConfirmMainThreadAffinityRequired: Bool,
        didConfirmHeadlessCiFailClosedRoute: Bool,
        didConfirmBoundedRunLoopPrerequisiteRequired: Bool,
        didConfirmAutoClosePrerequisiteRequired: Bool,
        didConfirmTeardownBeforeVisibleModeRequired: Bool,
        didConfirmNonUserVisibleModeRequired: Bool,
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
        didKeepNsApplicationSharedApplicationFeasibilityReadinessDehydrated:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.nsApplicationCreationActivationScopeReadiness =
            nsApplicationCreationActivationScopeReadiness
        this.nsApplicationSharedApplicationFeasibilityAdmission =
            nsApplicationSharedApplicationFeasibilityAdmission
        this.didPrepareRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness =
            didPrepareRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness
        this.shouldDeferRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness =
            shouldDeferRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness
        this.shouldReportRendererVisibleWindowNsApplicationSharedApplicationFeasibilityBlocked =
            shouldReportRendererVisibleWindowNsApplicationSharedApplicationFeasibilityBlocked
        this.didPreserveNsApplicationCreationActivationScopeReadiness =
            didPreserveNsApplicationCreationActivationScopeReadiness
        this.didConfirmSharedApplicationCallStillBlocked =
            didConfirmSharedApplicationCallStillBlocked
        this.didConfirmApplicationSingletonCreationStillBlocked =
            didConfirmApplicationSingletonCreationStillBlocked
        this.didConfirmMainThreadAffinityRequired =
            didConfirmMainThreadAffinityRequired
        this.didConfirmHeadlessCiFailClosedRoute =
            didConfirmHeadlessCiFailClosedRoute
        this.didConfirmBoundedRunLoopPrerequisiteRequired =
            didConfirmBoundedRunLoopPrerequisiteRequired
        this.didConfirmAutoClosePrerequisiteRequired =
            didConfirmAutoClosePrerequisiteRequired
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
        this.didConfirmNoApplicationCreationOrActivation =
            didConfirmNoApplicationCreationOrActivation
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNsApplicationSharedApplicationFeasibilityReadinessDehydrated =
            didKeepNsApplicationSharedApplicationFeasibilityReadinessDehydrated
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationFeasibilityFacts(
    nsApplicationCreationActivationScopeReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityFacts {
    let upstreamReady =
        nsApplicationCreationActivationScopeReadiness
            .didPrepareRendererVisibleWindowNsApplicationCreationActivationScopeReadiness &&
        nsApplicationCreationActivationScopeReadiness
            .didConfirmApplicationSingletonCreationStillBlocked &&
        nsApplicationCreationActivationScopeReadiness
            .didConfirmActivationPolicyMutationStillBlocked &&
        nsApplicationCreationActivationScopeReadiness
            .didConfirmApplicationActivationStillBlocked &&
        nsApplicationCreationActivationScopeReadiness
            .didConfirmEventLoopStillBlocked &&
        nsApplicationCreationActivationScopeReadiness
            .didConfirmBoundedRunLoopPrerequisiteRequired &&
        nsApplicationCreationActivationScopeReadiness
            .didConfirmAutoClosePrerequisiteRequired &&
        nsApplicationCreationActivationScopeReadiness
            .didKeepHeadlessCiFailClosedRoute &&
        nsApplicationCreationActivationScopeReadiness
            .didConfirmNativeVisibleOrderStillBlocked &&
        nsApplicationCreationActivationScopeReadiness
            .didConfirmProductionDrawableStillBlocked &&
        nsApplicationCreationActivationScopeReadiness
            .didConfirmRenderStillBlocked &&
        nsApplicationCreationActivationScopeReadiness
            .didConfirmNoApplicationCreationOrActivation &&
        nsApplicationCreationActivationScopeReadiness
            .didConfirmNoPointerHandleClassIdReturn &&
        nsApplicationCreationActivationScopeReadiness.didConfirmNoPublicSurface &&
        nsApplicationCreationActivationScopeReadiness
            .didConfirmNoRendererStateWrite &&
        nsApplicationCreationActivationScopeReadiness
            .didConfirmNoBackendReadyTruth &&
        nsApplicationCreationActivationScopeReadiness
            .didKeepNsApplicationCreationActivationScopeReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityFacts(
        upstreamReady,
        upstreamReady,
        upstreamReady,
        nsApplicationCreationActivationScopeReadiness
            .didKeepHeadlessCiFailClosedRoute,
        nsApplicationCreationActivationScopeReadiness
            .didConfirmBoundedRunLoopPrerequisiteRequired,
        nsApplicationCreationActivationScopeReadiness
            .didConfirmAutoClosePrerequisiteRequired,
        upstreamReady,
        upstreamReady,
        nsApplicationCreationActivationScopeReadiness
            .didConfirmActivationPolicyMutationStillBlocked,
        nsApplicationCreationActivationScopeReadiness
            .didConfirmApplicationActivationStillBlocked,
        nsApplicationCreationActivationScopeReadiness
            .didConfirmEventLoopStillBlocked,
        nsApplicationCreationActivationScopeReadiness
            .didConfirmNativeVisibleOrderStillBlocked,
        nsApplicationCreationActivationScopeReadiness
            .didConfirmProductionDrawableStillBlocked,
        nsApplicationCreationActivationScopeReadiness.didConfirmRenderStillBlocked,
        nsApplicationCreationActivationScopeReadiness
            .didConfirmNoApplicationCreationOrActivation,
        nsApplicationCreationActivationScopeReadiness
            .didConfirmNoPointerHandleClassIdReturn,
        nsApplicationCreationActivationScopeReadiness.didConfirmNoPublicSurface,
        nsApplicationCreationActivationScopeReadiness
            .didConfirmNoRendererStateWrite,
        nsApplicationCreationActivationScopeReadiness.didConfirmNoBackendReadyTruth,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationFeasibilityAdmission(
    feasibilityFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityAdmission {
    let didAdmit =
        feasibilityFacts.didKeepSharedApplicationCallBlocked &&
        feasibilityFacts.didKeepApplicationSingletonCreationBlocked &&
        feasibilityFacts.didRequireMainThreadAffinity &&
        feasibilityFacts.didKeepHeadlessCiFailClosedRoute &&
        feasibilityFacts.didRequireBoundedRunLoopPrerequisite &&
        feasibilityFacts.didRequireAutoClosePrerequisite &&
        feasibilityFacts.didRequireTeardownBeforeVisibleMode &&
        feasibilityFacts.didRequireNonUserVisibleMode &&
        feasibilityFacts.didKeepActivationPolicyMutationBlocked &&
        feasibilityFacts.didKeepApplicationActivationBlocked &&
        feasibilityFacts.didKeepEventLoopBlocked &&
        feasibilityFacts.didKeepNativeVisibleOrderImplementationBlocked &&
        feasibilityFacts.didKeepProductionDrawablePermissionBlocked &&
        feasibilityFacts.didKeepRenderPermissionBlocked &&
        feasibilityFacts.didConfirmNoApplicationCreationOrActivation &&
        feasibilityFacts.didConfirmNoPointerHandleClassIdReturn &&
        feasibilityFacts.didConfirmNoPublicSurface &&
        feasibilityFacts.didConfirmNoRendererStateWrite &&
        feasibilityFacts.didConfirmNoBackendReadyTruth &&
        feasibilityFacts.didKeepFeasibilityFactsValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityAdmission(
        feasibilityFacts,
        didAdmit,
        !didAdmit,
        !didAdmit,
        feasibilityFacts.didKeepSharedApplicationCallBlocked,
        feasibilityFacts.didKeepApplicationSingletonCreationBlocked,
        feasibilityFacts.didRequireMainThreadAffinity,
        feasibilityFacts.didKeepHeadlessCiFailClosedRoute,
        feasibilityFacts.didRequireBoundedRunLoopPrerequisite,
        feasibilityFacts.didRequireAutoClosePrerequisite,
        feasibilityFacts.didRequireTeardownBeforeVisibleMode,
        feasibilityFacts.didRequireNonUserVisibleMode,
        feasibilityFacts.didKeepActivationPolicyMutationBlocked,
        feasibilityFacts.didKeepApplicationActivationBlocked,
        feasibilityFacts.didKeepEventLoopBlocked,
        feasibilityFacts.didKeepNativeVisibleOrderImplementationBlocked,
        feasibilityFacts.didKeepProductionDrawablePermissionBlocked,
        feasibilityFacts.didKeepRenderPermissionBlocked,
        feasibilityFacts.didKeepFeasibilityFactsValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness(
    nsApplicationCreationActivationScopeReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeReadiness,
    nsApplicationSharedApplicationFeasibilityAdmission:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityAdmission
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness {
    let upstreamReady =
        nsApplicationCreationActivationScopeReadiness
            .didPrepareRendererVisibleWindowNsApplicationCreationActivationScopeReadiness &&
        nsApplicationCreationActivationScopeReadiness
            .didConfirmNoRendererStateWrite &&
        nsApplicationCreationActivationScopeReadiness.didConfirmNoBackendReadyTruth
    let admissionReady =
        nsApplicationSharedApplicationFeasibilityAdmission
            .didAdmitNsApplicationSharedApplicationFeasibilityBoundary &&
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmSharedApplicationCallStillBlocked &&
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmApplicationSingletonCreationStillBlocked &&
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmMainThreadAffinityRequired &&
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmHeadlessCiFailClosedRoute &&
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmBoundedRunLoopPrerequisiteRequired &&
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmAutoClosePrerequisiteRequired &&
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmTeardownBeforeVisibleModeRequired &&
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmNonUserVisibleModeRequired &&
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmActivationPolicyMutationStillBlocked &&
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmApplicationActivationStillBlocked &&
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmEventLoopStillBlocked &&
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmNativeVisibleOrderStillBlocked &&
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmProductionDrawableStillBlocked &&
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmRenderStillBlocked &&
        nsApplicationSharedApplicationFeasibilityAdmission
            .didKeepNsApplicationSharedApplicationFeasibilityValueOnly
    let readinessReady = upstreamReady && admissionReady
    let feasibilityFacts =
        nsApplicationSharedApplicationFeasibilityAdmission.feasibilityFacts

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness(
        nsApplicationCreationActivationScopeReadiness,
        nsApplicationSharedApplicationFeasibilityAdmission,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmSharedApplicationCallStillBlocked,
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmApplicationSingletonCreationStillBlocked,
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmMainThreadAffinityRequired,
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmHeadlessCiFailClosedRoute,
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmBoundedRunLoopPrerequisiteRequired,
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmAutoClosePrerequisiteRequired,
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmTeardownBeforeVisibleModeRequired,
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmNonUserVisibleModeRequired,
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmActivationPolicyMutationStillBlocked,
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmApplicationActivationStillBlocked,
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmEventLoopStillBlocked,
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmNativeVisibleOrderStillBlocked,
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmProductionDrawableStillBlocked,
        nsApplicationSharedApplicationFeasibilityAdmission
            .didConfirmRenderStillBlocked,
        feasibilityFacts.didConfirmNoApplicationCreationOrActivation,
        feasibilityFacts.didConfirmNoPointerHandleClassIdReturn,
        feasibilityFacts.didConfirmNoPublicSurface,
        feasibilityFacts.didConfirmNoRendererStateWrite,
        feasibilityFacts.didConfirmNoBackendReadyTruth,
        feasibilityFacts.didKeepFeasibilityFactsValueOnly,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationFeasibilityDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness {
    let creationActivationScopeReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationCreationActivationScopeDraft()
    let feasibilityFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationFeasibilityFacts(
            creationActivationScopeReadiness
        )
    let feasibilityAdmission =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationFeasibilityAdmission(
            feasibilityFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness(
        creationActivationScopeReadiness,
        feasibilityAdmission
    )
}
