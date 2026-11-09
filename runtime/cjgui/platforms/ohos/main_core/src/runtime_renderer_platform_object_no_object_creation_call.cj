// Owner: platform object no-object creation callable internal owner。
// Truth: 只消费 CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness，
// 调用 platform object creation fail-closed C ABI，并把返回值脱水为 internal facts。
// Stop-line: 只证明 creation entry 仍被 no-object / main-thread / token contract /
// allocation blocked 分类约束；不创建 AppKit / Metal / QuartzCore object，
// 不返回 Class / id / pointer / handle，不写 runtime_state.cj。
// Same-shape Boundary Brake: 不得把本 owner 包成 platform object creation、
// AppKit object permission、native handle、Metal、public API、backend-ready、
// renderer state write、render、receipt、record 或 publication wrapper。
package cjgui

foreign func cjgui_native_bridge_platform_object_create_no_object_admission():
    Int32
foreign func cjgui_native_bridge_platform_object_create_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_platform_object_create_requires_token_contract():
    Int32
foreign func cjgui_native_bridge_platform_object_create_allocation_blocked():
    Int32

struct CjguiInternalRendererPlatformObjectNoObjectCreationObservation {
    let noObjectAdmissionValue: Int32
    let requiresMainThreadValue: Int32
    let requiresTokenContractValue: Int32
    let allocationBlockedValue: Int32
    let didObserveNoObjectAdmission: Bool
    let didObserveMainThreadRequirement: Bool
    let didObserveTokenContractRequirement: Bool
    let didObserveAllocationBlocked: Bool
    let didConfirmCreationEntryFailClosed: Bool
    let didConfirmNoClassIdPointerOrHandleReturn: Bool
    let didConfirmNoAppKitObjectAllocation: Bool
    let didConfirmNoMetalQuartzCoreUsage: Bool

    init(
        noObjectAdmissionValue: Int32,
        requiresMainThreadValue: Int32,
        requiresTokenContractValue: Int32,
        allocationBlockedValue: Int32,
        didObserveNoObjectAdmission: Bool,
        didObserveMainThreadRequirement: Bool,
        didObserveTokenContractRequirement: Bool,
        didObserveAllocationBlocked: Bool,
        didConfirmCreationEntryFailClosed: Bool,
        didConfirmNoClassIdPointerOrHandleReturn: Bool,
        didConfirmNoAppKitObjectAllocation: Bool,
        didConfirmNoMetalQuartzCoreUsage: Bool
    ) {
        this.noObjectAdmissionValue = noObjectAdmissionValue
        this.requiresMainThreadValue = requiresMainThreadValue
        this.requiresTokenContractValue = requiresTokenContractValue
        this.allocationBlockedValue = allocationBlockedValue
        this.didObserveNoObjectAdmission = didObserveNoObjectAdmission
        this.didObserveMainThreadRequirement =
            didObserveMainThreadRequirement
        this.didObserveTokenContractRequirement =
            didObserveTokenContractRequirement
        this.didObserveAllocationBlocked = didObserveAllocationBlocked
        this.didConfirmCreationEntryFailClosed =
            didConfirmCreationEntryFailClosed
        this.didConfirmNoClassIdPointerOrHandleReturn =
            didConfirmNoClassIdPointerOrHandleReturn
        this.didConfirmNoAppKitObjectAllocation =
            didConfirmNoAppKitObjectAllocation
        this.didConfirmNoMetalQuartzCoreUsage =
            didConfirmNoMetalQuartzCoreUsage
    }
}

struct CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness {
    let tokenBackedCreationReadiness:
        CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness
    let noObjectCreationObservation:
        CjguiInternalRendererPlatformObjectNoObjectCreationObservation
    let didPrepareRendererNoPlatformObjectNoObjectCreationCallReadiness:
        Bool
    let shouldDeferRendererNoPlatformObjectNoObjectCreationCallReadiness:
        Bool
    let shouldReportRendererNoPlatformObjectNoObjectCreationCallBlocked:
        Bool
    let didPreserveRendererPlatformObjectTokenBackedCreationReadiness:
        Bool
    let didConfirmNoObjectCreationAdmission: Bool
    let didConfirmMainThreadRequirement: Bool
    let didConfirmTokenContractRequirement: Bool
    let didConfirmAllocationBlocked: Bool
    let didConfirmCreationEntryFailClosed: Bool
    let didConfirmNoClassIdPointerOrHandleReturn: Bool
    let didConfirmNoAppKitObjectAllocation: Bool
    let didConfirmNoMetalQuartzCoreUsage: Bool
    let didConfirmNoObjectTableImplementation: Bool
    let didConfirmNoTokenBindingToNativeObject: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoPlatformObjectNoObjectCreationCallDehydrated: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        tokenBackedCreationReadiness:
            CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness,
        noObjectCreationObservation:
            CjguiInternalRendererPlatformObjectNoObjectCreationObservation,
        didPrepareRendererNoPlatformObjectNoObjectCreationCallReadiness:
            Bool,
        shouldDeferRendererNoPlatformObjectNoObjectCreationCallReadiness:
            Bool,
        shouldReportRendererNoPlatformObjectNoObjectCreationCallBlocked:
            Bool,
        didPreserveRendererPlatformObjectTokenBackedCreationReadiness:
            Bool,
        didConfirmNoObjectCreationAdmission: Bool,
        didConfirmMainThreadRequirement: Bool,
        didConfirmTokenContractRequirement: Bool,
        didConfirmAllocationBlocked: Bool,
        didConfirmCreationEntryFailClosed: Bool,
        didConfirmNoClassIdPointerOrHandleReturn: Bool,
        didConfirmNoAppKitObjectAllocation: Bool,
        didConfirmNoMetalQuartzCoreUsage: Bool,
        didConfirmNoObjectTableImplementation: Bool,
        didConfirmNoTokenBindingToNativeObject: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoPlatformObjectNoObjectCreationCallDehydrated: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.tokenBackedCreationReadiness =
            tokenBackedCreationReadiness
        this.noObjectCreationObservation = noObjectCreationObservation
        this
            .didPrepareRendererNoPlatformObjectNoObjectCreationCallReadiness =
            didPrepareRendererNoPlatformObjectNoObjectCreationCallReadiness
        this
            .shouldDeferRendererNoPlatformObjectNoObjectCreationCallReadiness =
            shouldDeferRendererNoPlatformObjectNoObjectCreationCallReadiness
        this
            .shouldReportRendererNoPlatformObjectNoObjectCreationCallBlocked =
            shouldReportRendererNoPlatformObjectNoObjectCreationCallBlocked
        this
            .didPreserveRendererPlatformObjectTokenBackedCreationReadiness =
            didPreserveRendererPlatformObjectTokenBackedCreationReadiness
        this.didConfirmNoObjectCreationAdmission =
            didConfirmNoObjectCreationAdmission
        this.didConfirmMainThreadRequirement =
            didConfirmMainThreadRequirement
        this.didConfirmTokenContractRequirement =
            didConfirmTokenContractRequirement
        this.didConfirmAllocationBlocked = didConfirmAllocationBlocked
        this.didConfirmCreationEntryFailClosed =
            didConfirmCreationEntryFailClosed
        this.didConfirmNoClassIdPointerOrHandleReturn =
            didConfirmNoClassIdPointerOrHandleReturn
        this.didConfirmNoAppKitObjectAllocation =
            didConfirmNoAppKitObjectAllocation
        this.didConfirmNoMetalQuartzCoreUsage =
            didConfirmNoMetalQuartzCoreUsage
        this.didConfirmNoObjectTableImplementation =
            didConfirmNoObjectTableImplementation
        this.didConfirmNoTokenBindingToNativeObject =
            didConfirmNoTokenBindingToNativeObject
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth =
            didConfirmNoBackendReadyTruth
        this.didKeepNoPlatformObjectNoObjectCreationCallDehydrated =
            didKeepNoPlatformObjectNoObjectCreationCallDehydrated
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererPlatformObjectNoObjectCreationValues():
    CjguiInternalRendererPlatformObjectNoObjectCreationObservation {
    let noObjectAdmission = unsafe {
        cjgui_native_bridge_platform_object_create_no_object_admission()
    }
    let requiresMainThread = unsafe {
        cjgui_native_bridge_platform_object_create_requires_main_thread()
    }
    let requiresTokenContract = unsafe {
        cjgui_native_bridge_platform_object_create_requires_token_contract()
    }
    let allocationBlocked = unsafe {
        cjgui_native_bridge_platform_object_create_allocation_blocked()
    }
    return CjguiInternalRendererPlatformObjectNoObjectCreationObservation(
        noObjectAdmission,
        requiresMainThread,
        requiresTokenContract,
        allocationBlocked,
        noObjectAdmission == Int32(27),
        requiresMainThread == Int32(28),
        requiresTokenContract == Int32(29),
        allocationBlocked == Int32(-24),
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererPlatformObjectNoObjectCreationCallReadiness(
    tokenBackedCreationReadiness:
        CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness,
    noObjectCreationObservation:
        CjguiInternalRendererPlatformObjectNoObjectCreationObservation
): CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness {
    let upstreamReady =
        tokenBackedCreationReadiness
            .didPrepareRendererNoPlatformObjectTokenBackedCreationReadiness &&
        tokenBackedCreationReadiness.didConfirmPlatformObjectCreationIntent &&
        tokenBackedCreationReadiness.didConfirmTokenBackedObjectIdentityPolicy &&
        tokenBackedCreationReadiness
            .didConfirmMainThreadCreationAdmissionGuard &&
        tokenBackedCreationReadiness.didConfirmAllocationStillBlockedProof &&
        tokenBackedCreationReadiness.didConfirmNoPointerHandleReturnPolicy &&
        tokenBackedCreationReadiness.didConfirmTokenIssueBeforeBindDenied &&
        tokenBackedCreationReadiness.didConfirmRevokeBeforeDestroyRequired &&
        tokenBackedCreationReadiness.didConfirmNoObjectTableImplementation &&
        tokenBackedCreationReadiness.didConfirmNoTokenBindingToNativeObject &&
        tokenBackedCreationReadiness.didConfirmNoPublicSurface &&
        tokenBackedCreationReadiness.didConfirmNoRendererStateWrite &&
        tokenBackedCreationReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        noObjectCreationObservation.didObserveNoObjectAdmission &&
        noObjectCreationObservation.didObserveMainThreadRequirement &&
        noObjectCreationObservation.didObserveTokenContractRequirement &&
        noObjectCreationObservation.didObserveAllocationBlocked &&
        noObjectCreationObservation.didConfirmCreationEntryFailClosed &&
        noObjectCreationObservation
            .didConfirmNoClassIdPointerOrHandleReturn &&
        noObjectCreationObservation.didConfirmNoAppKitObjectAllocation &&
        noObjectCreationObservation.didConfirmNoMetalQuartzCoreUsage
    let readinessReady = upstreamReady && observationReady
    return CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness(
        tokenBackedCreationReadiness,
        noObjectCreationObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        noObjectCreationObservation.didObserveNoObjectAdmission,
        noObjectCreationObservation.didObserveMainThreadRequirement,
        noObjectCreationObservation.didObserveTokenContractRequirement,
        noObjectCreationObservation.didObserveAllocationBlocked,
        noObjectCreationObservation.didConfirmCreationEntryFailClosed,
        noObjectCreationObservation
            .didConfirmNoClassIdPointerOrHandleReturn,
        noObjectCreationObservation.didConfirmNoAppKitObjectAllocation,
        noObjectCreationObservation.didConfirmNoMetalQuartzCoreUsage,
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

func cjguiInternalExecuteDefaultRendererPlatformObjectNoObjectCreationCallDraft():
    CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness {
    let tokenBackedCreationReadiness =
        cjguiInternalExecuteDefaultRendererPlatformObjectTokenBackedCreationDraft()
    let noObjectCreationObservation =
        cjguiInternalObserveRendererPlatformObjectNoObjectCreationValues()
    return cjguiInternalBuildRendererPlatformObjectNoObjectCreationCallReadiness(
        tokenBackedCreationReadiness,
        noObjectCreationObservation
    )
}
