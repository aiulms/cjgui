// Owner: platform object NSView allocation feasibility planning owner。
// Truth: 只消费 CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness，
// 固定 isolated NSView allocation feasibility、main-thread gate、immediate-release
// probe route、token-backed retention blocked 与 object table absent facts。
// Stop-line: 不新增 production allocation C ABI，不保存 NSView，不返回 Class / id /
// pointer / handle，不实现 object table，不写 runtime_state.cj。
// Same-shape Boundary Brake: 不得把本 owner 包成 NSView retention、platform object
// creation permission、native handle、backend-ready、renderer state write、render、
// receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererPlatformObjectNsViewAllocationFeasibilityFacts {
    let didConfirmNsViewAllocationFeasibilityIntent: Bool
    let didRequireIsolatedProbeBeforeProductionCallable: Bool
    let didRequireMainThreadAllocationGate: Bool
    let didConfirmImmediateReleaseOnlyProbePolicy: Bool
    let didConfirmTokenBackedRetentionStillBlocked: Bool
    let didConfirmObjectTableStillAbsent: Bool
    let didConfirmDestroyRevokeDependencyStillRequired: Bool
    let didConfirmNoProductionAllocationCallable: Bool
    let didConfirmNoLongLivedNsViewStorage: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoNsWindowNsApplicationLayerMetal: Bool
    let didKeepNsViewAllocationPlanningDehydrated: Bool

    init(
        didConfirmNsViewAllocationFeasibilityIntent: Bool,
        didRequireIsolatedProbeBeforeProductionCallable: Bool,
        didRequireMainThreadAllocationGate: Bool,
        didConfirmImmediateReleaseOnlyProbePolicy: Bool,
        didConfirmTokenBackedRetentionStillBlocked: Bool,
        didConfirmObjectTableStillAbsent: Bool,
        didConfirmDestroyRevokeDependencyStillRequired: Bool,
        didConfirmNoProductionAllocationCallable: Bool,
        didConfirmNoLongLivedNsViewStorage: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoNsWindowNsApplicationLayerMetal: Bool,
        didKeepNsViewAllocationPlanningDehydrated: Bool
    ) {
        this.didConfirmNsViewAllocationFeasibilityIntent =
            didConfirmNsViewAllocationFeasibilityIntent
        this.didRequireIsolatedProbeBeforeProductionCallable =
            didRequireIsolatedProbeBeforeProductionCallable
        this.didRequireMainThreadAllocationGate =
            didRequireMainThreadAllocationGate
        this.didConfirmImmediateReleaseOnlyProbePolicy =
            didConfirmImmediateReleaseOnlyProbePolicy
        this.didConfirmTokenBackedRetentionStillBlocked =
            didConfirmTokenBackedRetentionStillBlocked
        this.didConfirmObjectTableStillAbsent =
            didConfirmObjectTableStillAbsent
        this.didConfirmDestroyRevokeDependencyStillRequired =
            didConfirmDestroyRevokeDependencyStillRequired
        this.didConfirmNoProductionAllocationCallable =
            didConfirmNoProductionAllocationCallable
        this.didConfirmNoLongLivedNsViewStorage =
            didConfirmNoLongLivedNsViewStorage
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoNsWindowNsApplicationLayerMetal =
            didConfirmNoNsWindowNsApplicationLayerMetal
        this.didKeepNsViewAllocationPlanningDehydrated =
            didKeepNsViewAllocationPlanningDehydrated
    }
}

struct CjguiInternalRendererNoPlatformObjectNsViewAllocationReadiness {
    let noObjectCreationCallReadiness:
        CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness
    let feasibilityFacts:
        CjguiInternalRendererPlatformObjectNsViewAllocationFeasibilityFacts
    let didPrepareRendererNoPlatformObjectNsViewAllocationReadiness: Bool
    let shouldDeferRendererNoPlatformObjectNsViewAllocationReadiness: Bool
    let shouldReportRendererNoPlatformObjectNsViewAllocationBlocked: Bool
    let didPreserveRendererPlatformObjectNoObjectCreationCallReadiness:
        Bool
    let didConfirmNsViewAllocationFeasibilityIntent: Bool
    let didConfirmMainThreadAllocationGate: Bool
    let didConfirmImmediateReleaseFeasibilityRoute: Bool
    let didConfirmTokenBackedRetentionStillBlocked: Bool
    let didConfirmObjectTableStillAbsent: Bool
    let didConfirmDestroyRevokeDependencyStillRequired: Bool
    let didConfirmNoProductionAllocationCallable: Bool
    let didConfirmNoLongLivedNsViewStorage: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoNsWindowNsApplicationLayerMetal: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNsViewAllocationReadinessDehydrated: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        noObjectCreationCallReadiness:
            CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness,
        feasibilityFacts:
            CjguiInternalRendererPlatformObjectNsViewAllocationFeasibilityFacts,
        didPrepareRendererNoPlatformObjectNsViewAllocationReadiness: Bool,
        shouldDeferRendererNoPlatformObjectNsViewAllocationReadiness: Bool,
        shouldReportRendererNoPlatformObjectNsViewAllocationBlocked: Bool,
        didPreserveRendererPlatformObjectNoObjectCreationCallReadiness:
            Bool,
        didConfirmNsViewAllocationFeasibilityIntent: Bool,
        didConfirmMainThreadAllocationGate: Bool,
        didConfirmImmediateReleaseFeasibilityRoute: Bool,
        didConfirmTokenBackedRetentionStillBlocked: Bool,
        didConfirmObjectTableStillAbsent: Bool,
        didConfirmDestroyRevokeDependencyStillRequired: Bool,
        didConfirmNoProductionAllocationCallable: Bool,
        didConfirmNoLongLivedNsViewStorage: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoNsWindowNsApplicationLayerMetal: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNsViewAllocationReadinessDehydrated: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noObjectCreationCallReadiness =
            noObjectCreationCallReadiness
        this.feasibilityFacts = feasibilityFacts
        this.didPrepareRendererNoPlatformObjectNsViewAllocationReadiness =
            didPrepareRendererNoPlatformObjectNsViewAllocationReadiness
        this.shouldDeferRendererNoPlatformObjectNsViewAllocationReadiness =
            shouldDeferRendererNoPlatformObjectNsViewAllocationReadiness
        this.shouldReportRendererNoPlatformObjectNsViewAllocationBlocked =
            shouldReportRendererNoPlatformObjectNsViewAllocationBlocked
        this
            .didPreserveRendererPlatformObjectNoObjectCreationCallReadiness =
            didPreserveRendererPlatformObjectNoObjectCreationCallReadiness
        this.didConfirmNsViewAllocationFeasibilityIntent =
            didConfirmNsViewAllocationFeasibilityIntent
        this.didConfirmMainThreadAllocationGate =
            didConfirmMainThreadAllocationGate
        this.didConfirmImmediateReleaseFeasibilityRoute =
            didConfirmImmediateReleaseFeasibilityRoute
        this.didConfirmTokenBackedRetentionStillBlocked =
            didConfirmTokenBackedRetentionStillBlocked
        this.didConfirmObjectTableStillAbsent =
            didConfirmObjectTableStillAbsent
        this.didConfirmDestroyRevokeDependencyStillRequired =
            didConfirmDestroyRevokeDependencyStillRequired
        this.didConfirmNoProductionAllocationCallable =
            didConfirmNoProductionAllocationCallable
        this.didConfirmNoLongLivedNsViewStorage =
            didConfirmNoLongLivedNsViewStorage
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoNsWindowNsApplicationLayerMetal =
            didConfirmNoNsWindowNsApplicationLayerMetal
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth =
            didConfirmNoBackendReadyTruth
        this.didKeepNsViewAllocationReadinessDehydrated =
            didKeepNsViewAllocationReadinessDehydrated
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalDefaultRendererPlatformObjectNsViewAllocationFeasibilityFacts():
    CjguiInternalRendererPlatformObjectNsViewAllocationFeasibilityFacts {
    return CjguiInternalRendererPlatformObjectNsViewAllocationFeasibilityFacts(
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererPlatformObjectNsViewAllocationReadiness(
    noObjectCreationCallReadiness:
        CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness,
    feasibilityFacts:
        CjguiInternalRendererPlatformObjectNsViewAllocationFeasibilityFacts
): CjguiInternalRendererNoPlatformObjectNsViewAllocationReadiness {
    let upstreamReady =
        noObjectCreationCallReadiness
            .didPrepareRendererNoPlatformObjectNoObjectCreationCallReadiness &&
        noObjectCreationCallReadiness.didConfirmNoObjectCreationAdmission &&
        noObjectCreationCallReadiness.didConfirmMainThreadRequirement &&
        noObjectCreationCallReadiness.didConfirmTokenContractRequirement &&
        noObjectCreationCallReadiness.didConfirmAllocationBlocked &&
        noObjectCreationCallReadiness.didConfirmCreationEntryFailClosed &&
        noObjectCreationCallReadiness.didConfirmNoClassIdPointerOrHandleReturn &&
        noObjectCreationCallReadiness.didConfirmNoAppKitObjectAllocation &&
        noObjectCreationCallReadiness.didConfirmNoMetalQuartzCoreUsage &&
        noObjectCreationCallReadiness.didConfirmNoObjectTableImplementation &&
        noObjectCreationCallReadiness.didConfirmNoTokenBindingToNativeObject &&
        noObjectCreationCallReadiness.didConfirmNoPublicSurface &&
        noObjectCreationCallReadiness.didConfirmNoRendererStateWrite &&
        noObjectCreationCallReadiness.didConfirmNoBackendReadyTruth
    let feasibilityReady =
        feasibilityFacts.didConfirmNsViewAllocationFeasibilityIntent &&
        feasibilityFacts.didRequireIsolatedProbeBeforeProductionCallable &&
        feasibilityFacts.didRequireMainThreadAllocationGate &&
        feasibilityFacts.didConfirmImmediateReleaseOnlyProbePolicy &&
        feasibilityFacts.didConfirmTokenBackedRetentionStillBlocked &&
        feasibilityFacts.didConfirmObjectTableStillAbsent &&
        feasibilityFacts.didConfirmDestroyRevokeDependencyStillRequired &&
        feasibilityFacts.didConfirmNoProductionAllocationCallable &&
        feasibilityFacts.didConfirmNoLongLivedNsViewStorage &&
        feasibilityFacts.didConfirmNoPointerHandleClassIdReturn &&
        feasibilityFacts.didConfirmNoNsWindowNsApplicationLayerMetal &&
        feasibilityFacts.didKeepNsViewAllocationPlanningDehydrated
    let readinessReady = upstreamReady && feasibilityReady
    return CjguiInternalRendererNoPlatformObjectNsViewAllocationReadiness(
        noObjectCreationCallReadiness,
        feasibilityFacts,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        feasibilityFacts.didConfirmNsViewAllocationFeasibilityIntent,
        feasibilityFacts.didRequireMainThreadAllocationGate,
        feasibilityFacts.didConfirmImmediateReleaseOnlyProbePolicy,
        feasibilityFacts.didConfirmTokenBackedRetentionStillBlocked,
        feasibilityFacts.didConfirmObjectTableStillAbsent,
        feasibilityFacts.didConfirmDestroyRevokeDependencyStillRequired,
        feasibilityFacts.didConfirmNoProductionAllocationCallable,
        feasibilityFacts.didConfirmNoLongLivedNsViewStorage,
        feasibilityFacts.didConfirmNoPointerHandleClassIdReturn,
        feasibilityFacts.didConfirmNoNsWindowNsApplicationLayerMetal,
        true,
        true,
        true,
        feasibilityFacts.didKeepNsViewAllocationPlanningDehydrated,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererPlatformObjectNsViewAllocationDraft():
    CjguiInternalRendererNoPlatformObjectNsViewAllocationReadiness {
    let noObjectCreationCallReadiness =
        cjguiInternalExecuteDefaultRendererPlatformObjectNoObjectCreationCallDraft()
    let feasibilityFacts =
        cjguiInternalDefaultRendererPlatformObjectNsViewAllocationFeasibilityFacts()
    return cjguiInternalBuildRendererPlatformObjectNsViewAllocationReadiness(
        noObjectCreationCallReadiness,
        feasibilityFacts
    )
}
