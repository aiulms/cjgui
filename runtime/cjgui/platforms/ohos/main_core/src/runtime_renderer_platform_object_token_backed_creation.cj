// Owner: platform object token-backed creation planning value boundary owner。
// Truth: 只消费 CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness，
// 固定 token-backed platform object creation 的准入合同、失败分类与 no-object stop-line。
// Stop-line: 不新增 native platform object C ABI，不创建 AppKit / Metal / QuartzCore
// object，不返回 Class / id / pointer / handle，不绑定 token 到真实 native object，
// 不写 runtime_state.cj。
// Same-shape Boundary Brake: 不得把本 owner 包成 platform object creation
// permission、native object permission、native handle、backend-ready、renderer state
// write、render、receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererPlatformObjectTokenBackedCreationIntent {
    let appkitMainThreadAdmissionReadiness:
        CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness
    let didPrepareRendererPlatformObjectTokenBackedCreationIntent: Bool
    let shouldDeferRendererPlatformObjectTokenBackedCreationIntent: Bool
    let shouldReportRendererPlatformObjectTokenBackedCreationIntentBlocked:
        Bool
    let didPreserveRendererPlatformObjectAppKitMainThreadAdmissionReadiness:
        Bool
    let didDefinePlatformObjectCreationIntent: Bool
    let didConfirmTokenBackedObjectIdentityPolicy: Bool
    let didRequireMainThreadCreationAdmissionGuard: Bool
    let didKeepCreationIntentPlanningOnly: Bool
    let didAvoidThinWrapper: Bool

    init(
        appkitMainThreadAdmissionReadiness:
            CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness,
        didPrepareRendererPlatformObjectTokenBackedCreationIntent: Bool,
        shouldDeferRendererPlatformObjectTokenBackedCreationIntent: Bool,
        shouldReportRendererPlatformObjectTokenBackedCreationIntentBlocked:
            Bool,
        didPreserveRendererPlatformObjectAppKitMainThreadAdmissionReadiness:
            Bool,
        didDefinePlatformObjectCreationIntent: Bool,
        didConfirmTokenBackedObjectIdentityPolicy: Bool,
        didRequireMainThreadCreationAdmissionGuard: Bool,
        didKeepCreationIntentPlanningOnly: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.appkitMainThreadAdmissionReadiness =
            appkitMainThreadAdmissionReadiness
        this.didPrepareRendererPlatformObjectTokenBackedCreationIntent =
            didPrepareRendererPlatformObjectTokenBackedCreationIntent
        this.shouldDeferRendererPlatformObjectTokenBackedCreationIntent =
            shouldDeferRendererPlatformObjectTokenBackedCreationIntent
        this
            .shouldReportRendererPlatformObjectTokenBackedCreationIntentBlocked =
            shouldReportRendererPlatformObjectTokenBackedCreationIntentBlocked
        this
            .didPreserveRendererPlatformObjectAppKitMainThreadAdmissionReadiness =
            didPreserveRendererPlatformObjectAppKitMainThreadAdmissionReadiness
        this.didDefinePlatformObjectCreationIntent =
            didDefinePlatformObjectCreationIntent
        this.didConfirmTokenBackedObjectIdentityPolicy =
            didConfirmTokenBackedObjectIdentityPolicy
        this.didRequireMainThreadCreationAdmissionGuard =
            didRequireMainThreadCreationAdmissionGuard
        this.didKeepCreationIntentPlanningOnly =
            didKeepCreationIntentPlanningOnly
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererPlatformObjectTokenBackedCreationGuard {
    let creationIntent:
        CjguiInternalRendererPlatformObjectTokenBackedCreationIntent
    let didPrepareRendererPlatformObjectTokenBackedCreationGuard: Bool
    let shouldDeferRendererPlatformObjectTokenBackedCreationGuard: Bool
    let shouldReportRendererPlatformObjectTokenBackedCreationGuardBlocked:
        Bool
    let didPreserveRendererPlatformObjectTokenBackedCreationIntent: Bool
    let didConfirmMainThreadGateRequired: Bool
    let didConfirmAllocationStillBlockedProof: Bool
    let didConfirmNoPointerHandleReturnPolicy: Bool
    let didConfirmTokenIssueBeforeBindDenied: Bool
    let didConfirmRevokeBeforeDestroyRequired: Bool
    let didConfirmNoObjectTableImplementation: Bool
    let didAvoidThinWrapper: Bool

    init(
        creationIntent:
            CjguiInternalRendererPlatformObjectTokenBackedCreationIntent,
        didPrepareRendererPlatformObjectTokenBackedCreationGuard: Bool,
        shouldDeferRendererPlatformObjectTokenBackedCreationGuard: Bool,
        shouldReportRendererPlatformObjectTokenBackedCreationGuardBlocked:
            Bool,
        didPreserveRendererPlatformObjectTokenBackedCreationIntent: Bool,
        didConfirmMainThreadGateRequired: Bool,
        didConfirmAllocationStillBlockedProof: Bool,
        didConfirmNoPointerHandleReturnPolicy: Bool,
        didConfirmTokenIssueBeforeBindDenied: Bool,
        didConfirmRevokeBeforeDestroyRequired: Bool,
        didConfirmNoObjectTableImplementation: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.creationIntent = creationIntent
        this.didPrepareRendererPlatformObjectTokenBackedCreationGuard =
            didPrepareRendererPlatformObjectTokenBackedCreationGuard
        this.shouldDeferRendererPlatformObjectTokenBackedCreationGuard =
            shouldDeferRendererPlatformObjectTokenBackedCreationGuard
        this
            .shouldReportRendererPlatformObjectTokenBackedCreationGuardBlocked =
            shouldReportRendererPlatformObjectTokenBackedCreationGuardBlocked
        this.didPreserveRendererPlatformObjectTokenBackedCreationIntent =
            didPreserveRendererPlatformObjectTokenBackedCreationIntent
        this.didConfirmMainThreadGateRequired =
            didConfirmMainThreadGateRequired
        this.didConfirmAllocationStillBlockedProof =
            didConfirmAllocationStillBlockedProof
        this.didConfirmNoPointerHandleReturnPolicy =
            didConfirmNoPointerHandleReturnPolicy
        this.didConfirmTokenIssueBeforeBindDenied =
            didConfirmTokenIssueBeforeBindDenied
        this.didConfirmRevokeBeforeDestroyRequired =
            didConfirmRevokeBeforeDestroyRequired
        this.didConfirmNoObjectTableImplementation =
            didConfirmNoObjectTableImplementation
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererPlatformObjectTokenBackedCreationFailurePolicy {
    let creationGuard:
        CjguiInternalRendererPlatformObjectTokenBackedCreationGuard
    let didPrepareRendererPlatformObjectTokenBackedCreationFailurePolicy:
        Bool
    let shouldDeferRendererPlatformObjectTokenBackedCreationFailurePolicy:
        Bool
    let shouldReportRendererPlatformObjectTokenBackedCreationFailurePolicyBlocked:
        Bool
    let didPreserveRendererPlatformObjectTokenBackedCreationGuard: Bool
    let didClassifyClassUnavailableFailure: Bool
    let didClassifyBackgroundThreadFailure: Bool
    let didClassifyAllocationBlockedFailure: Bool
    let didClassifyTokenTableDisabledFailure: Bool
    let didKeepFailurePolicyFailClosed: Bool
    let didAvoidThinWrapper: Bool

    init(
        creationGuard:
            CjguiInternalRendererPlatformObjectTokenBackedCreationGuard,
        didPrepareRendererPlatformObjectTokenBackedCreationFailurePolicy:
            Bool,
        shouldDeferRendererPlatformObjectTokenBackedCreationFailurePolicy:
            Bool,
        shouldReportRendererPlatformObjectTokenBackedCreationFailurePolicyBlocked:
            Bool,
        didPreserveRendererPlatformObjectTokenBackedCreationGuard: Bool,
        didClassifyClassUnavailableFailure: Bool,
        didClassifyBackgroundThreadFailure: Bool,
        didClassifyAllocationBlockedFailure: Bool,
        didClassifyTokenTableDisabledFailure: Bool,
        didKeepFailurePolicyFailClosed: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.creationGuard = creationGuard
        this
            .didPrepareRendererPlatformObjectTokenBackedCreationFailurePolicy =
            didPrepareRendererPlatformObjectTokenBackedCreationFailurePolicy
        this
            .shouldDeferRendererPlatformObjectTokenBackedCreationFailurePolicy =
            shouldDeferRendererPlatformObjectTokenBackedCreationFailurePolicy
        this
            .shouldReportRendererPlatformObjectTokenBackedCreationFailurePolicyBlocked =
            shouldReportRendererPlatformObjectTokenBackedCreationFailurePolicyBlocked
        this.didPreserveRendererPlatformObjectTokenBackedCreationGuard =
            didPreserveRendererPlatformObjectTokenBackedCreationGuard
        this.didClassifyClassUnavailableFailure =
            didClassifyClassUnavailableFailure
        this.didClassifyBackgroundThreadFailure =
            didClassifyBackgroundThreadFailure
        this.didClassifyAllocationBlockedFailure =
            didClassifyAllocationBlockedFailure
        this.didClassifyTokenTableDisabledFailure =
            didClassifyTokenTableDisabledFailure
        this.didKeepFailurePolicyFailClosed =
            didKeepFailurePolicyFailClosed
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness {
    let creationIntent:
        CjguiInternalRendererPlatformObjectTokenBackedCreationIntent
    let creationGuard:
        CjguiInternalRendererPlatformObjectTokenBackedCreationGuard
    let failurePolicy:
        CjguiInternalRendererPlatformObjectTokenBackedCreationFailurePolicy
    let didPrepareRendererNoPlatformObjectTokenBackedCreationReadiness:
        Bool
    let shouldDeferRendererNoPlatformObjectTokenBackedCreationReadiness:
        Bool
    let shouldReportRendererNoPlatformObjectTokenBackedCreationReadinessBlocked:
        Bool
    let didPreserveRendererPlatformObjectTokenBackedCreationIntent: Bool
    let didPreserveRendererPlatformObjectTokenBackedCreationGuard: Bool
    let didPreserveRendererPlatformObjectTokenBackedCreationFailurePolicy:
        Bool
    let didConfirmPlatformObjectCreationIntent: Bool
    let didConfirmTokenBackedObjectIdentityPolicy: Bool
    let didConfirmMainThreadCreationAdmissionGuard: Bool
    let didConfirmAllocationStillBlockedProof: Bool
    let didConfirmNoPointerHandleReturnPolicy: Bool
    let didConfirmTokenIssueBeforeBindDenied: Bool
    let didConfirmRevokeBeforeDestroyRequired: Bool
    let didConfirmClassUnavailableFailureClassification: Bool
    let didConfirmBackgroundThreadFailureClassification: Bool
    let didConfirmAllocationBlockedFailureClassification: Bool
    let didConfirmTokenTableDisabledFailureClassification: Bool
    let didConfirmNoNativePlatformObjectCAbi: Bool
    let didConfirmNoPlatformObjectCreation: Bool
    let didConfirmNoNativeObjectStorage: Bool
    let didConfirmNoObjectTableImplementation: Bool
    let didConfirmNoTokenBindingToNativeObject: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoPlatformObjectTokenBackedCreationReadinessDehydrated:
        Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        creationIntent:
            CjguiInternalRendererPlatformObjectTokenBackedCreationIntent,
        creationGuard:
            CjguiInternalRendererPlatformObjectTokenBackedCreationGuard,
        failurePolicy:
            CjguiInternalRendererPlatformObjectTokenBackedCreationFailurePolicy,
        didPrepareRendererNoPlatformObjectTokenBackedCreationReadiness:
            Bool,
        shouldDeferRendererNoPlatformObjectTokenBackedCreationReadiness:
            Bool,
        shouldReportRendererNoPlatformObjectTokenBackedCreationReadinessBlocked:
            Bool,
        didPreserveRendererPlatformObjectTokenBackedCreationIntent: Bool,
        didPreserveRendererPlatformObjectTokenBackedCreationGuard: Bool,
        didPreserveRendererPlatformObjectTokenBackedCreationFailurePolicy:
            Bool,
        didConfirmPlatformObjectCreationIntent: Bool,
        didConfirmTokenBackedObjectIdentityPolicy: Bool,
        didConfirmMainThreadCreationAdmissionGuard: Bool,
        didConfirmAllocationStillBlockedProof: Bool,
        didConfirmNoPointerHandleReturnPolicy: Bool,
        didConfirmTokenIssueBeforeBindDenied: Bool,
        didConfirmRevokeBeforeDestroyRequired: Bool,
        didConfirmClassUnavailableFailureClassification: Bool,
        didConfirmBackgroundThreadFailureClassification: Bool,
        didConfirmAllocationBlockedFailureClassification: Bool,
        didConfirmTokenTableDisabledFailureClassification: Bool,
        didConfirmNoNativePlatformObjectCAbi: Bool,
        didConfirmNoPlatformObjectCreation: Bool,
        didConfirmNoNativeObjectStorage: Bool,
        didConfirmNoObjectTableImplementation: Bool,
        didConfirmNoTokenBindingToNativeObject: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoPlatformObjectTokenBackedCreationReadinessDehydrated:
            Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.creationIntent = creationIntent
        this.creationGuard = creationGuard
        this.failurePolicy = failurePolicy
        this.didPrepareRendererNoPlatformObjectTokenBackedCreationReadiness =
            didPrepareRendererNoPlatformObjectTokenBackedCreationReadiness
        this.shouldDeferRendererNoPlatformObjectTokenBackedCreationReadiness =
            shouldDeferRendererNoPlatformObjectTokenBackedCreationReadiness
        this
            .shouldReportRendererNoPlatformObjectTokenBackedCreationReadinessBlocked =
            shouldReportRendererNoPlatformObjectTokenBackedCreationReadinessBlocked
        this.didPreserveRendererPlatformObjectTokenBackedCreationIntent =
            didPreserveRendererPlatformObjectTokenBackedCreationIntent
        this.didPreserveRendererPlatformObjectTokenBackedCreationGuard =
            didPreserveRendererPlatformObjectTokenBackedCreationGuard
        this
            .didPreserveRendererPlatformObjectTokenBackedCreationFailurePolicy =
            didPreserveRendererPlatformObjectTokenBackedCreationFailurePolicy
        this.didConfirmPlatformObjectCreationIntent =
            didConfirmPlatformObjectCreationIntent
        this.didConfirmTokenBackedObjectIdentityPolicy =
            didConfirmTokenBackedObjectIdentityPolicy
        this.didConfirmMainThreadCreationAdmissionGuard =
            didConfirmMainThreadCreationAdmissionGuard
        this.didConfirmAllocationStillBlockedProof =
            didConfirmAllocationStillBlockedProof
        this.didConfirmNoPointerHandleReturnPolicy =
            didConfirmNoPointerHandleReturnPolicy
        this.didConfirmTokenIssueBeforeBindDenied =
            didConfirmTokenIssueBeforeBindDenied
        this.didConfirmRevokeBeforeDestroyRequired =
            didConfirmRevokeBeforeDestroyRequired
        this.didConfirmClassUnavailableFailureClassification =
            didConfirmClassUnavailableFailureClassification
        this.didConfirmBackgroundThreadFailureClassification =
            didConfirmBackgroundThreadFailureClassification
        this.didConfirmAllocationBlockedFailureClassification =
            didConfirmAllocationBlockedFailureClassification
        this.didConfirmTokenTableDisabledFailureClassification =
            didConfirmTokenTableDisabledFailureClassification
        this.didConfirmNoNativePlatformObjectCAbi =
            didConfirmNoNativePlatformObjectCAbi
        this.didConfirmNoPlatformObjectCreation =
            didConfirmNoPlatformObjectCreation
        this.didConfirmNoNativeObjectStorage =
            didConfirmNoNativeObjectStorage
        this.didConfirmNoObjectTableImplementation =
            didConfirmNoObjectTableImplementation
        this.didConfirmNoTokenBindingToNativeObject =
            didConfirmNoTokenBindingToNativeObject
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth =
            didConfirmNoBackendReadyTruth
        this.didKeepNoPlatformObjectTokenBackedCreationReadinessDehydrated =
            didKeepNoPlatformObjectTokenBackedCreationReadinessDehydrated
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererPlatformObjectTokenBackedCreationIntent(
    appkitMainThreadAdmissionReadiness:
        CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness
): CjguiInternalRendererPlatformObjectTokenBackedCreationIntent {
    let upstreamReady =
        appkitMainThreadAdmissionReadiness
            .didPrepareRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness &&
        appkitMainThreadAdmissionReadiness
            .didConfirmPlatformObjectMainThreadRequired &&
        appkitMainThreadAdmissionReadiness
            .didConfirmPlatformObjectMainThreadAdmitted &&
        appkitMainThreadAdmissionReadiness
            .didConfirmPlatformObjectBackgroundThreadDenied &&
        appkitMainThreadAdmissionReadiness
            .didConfirmPlatformObjectCreationStillBlocked &&
        appkitMainThreadAdmissionReadiness
            .didConfirmMainThreadGateRequired &&
        appkitMainThreadAdmissionReadiness
            .didConfirmNoClassIdPointerOrHandleReturn &&
        appkitMainThreadAdmissionReadiness.didConfirmNoAppKitObjectAllocation &&
        appkitMainThreadAdmissionReadiness.didConfirmNoMetalQuartzCoreUsage &&
        appkitMainThreadAdmissionReadiness.didConfirmNoPublicSurface &&
        appkitMainThreadAdmissionReadiness.didConfirmNoRendererStateWrite &&
        appkitMainThreadAdmissionReadiness.didConfirmNoBackendReadyTruth
    return CjguiInternalRendererPlatformObjectTokenBackedCreationIntent(
        appkitMainThreadAdmissionReadiness,
        upstreamReady,
        !upstreamReady,
        !upstreamReady,
        upstreamReady,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererPlatformObjectTokenBackedCreationGuard(
    creationIntent:
        CjguiInternalRendererPlatformObjectTokenBackedCreationIntent
): CjguiInternalRendererPlatformObjectTokenBackedCreationGuard {
    let intentReady =
        creationIntent
            .didPrepareRendererPlatformObjectTokenBackedCreationIntent &&
        creationIntent.didConfirmTokenBackedObjectIdentityPolicy &&
        creationIntent.didRequireMainThreadCreationAdmissionGuard &&
        creationIntent.didKeepCreationIntentPlanningOnly
    return CjguiInternalRendererPlatformObjectTokenBackedCreationGuard(
        creationIntent,
        intentReady,
        !intentReady,
        !intentReady,
        intentReady,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererPlatformObjectTokenBackedCreationFailurePolicy(
    creationGuard:
        CjguiInternalRendererPlatformObjectTokenBackedCreationGuard
): CjguiInternalRendererPlatformObjectTokenBackedCreationFailurePolicy {
    let guardReady =
        creationGuard
            .didPrepareRendererPlatformObjectTokenBackedCreationGuard &&
        creationGuard.didConfirmMainThreadGateRequired &&
        creationGuard.didConfirmAllocationStillBlockedProof &&
        creationGuard.didConfirmNoPointerHandleReturnPolicy &&
        creationGuard.didConfirmTokenIssueBeforeBindDenied &&
        creationGuard.didConfirmRevokeBeforeDestroyRequired &&
        creationGuard.didConfirmNoObjectTableImplementation
    return CjguiInternalRendererPlatformObjectTokenBackedCreationFailurePolicy(
        creationGuard,
        guardReady,
        !guardReady,
        !guardReady,
        guardReady,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererPlatformObjectTokenBackedCreationReadiness(
    appkitMainThreadAdmissionReadiness:
        CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness
): CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness {
    let creationIntent =
        cjguiInternalBuildRendererPlatformObjectTokenBackedCreationIntent(
            appkitMainThreadAdmissionReadiness
        )
    let creationGuard =
        cjguiInternalBuildRendererPlatformObjectTokenBackedCreationGuard(
            creationIntent
        )
    let failurePolicy =
        cjguiInternalBuildRendererPlatformObjectTokenBackedCreationFailurePolicy(
            creationGuard
        )
    let readinessReady =
        creationIntent
            .didPrepareRendererPlatformObjectTokenBackedCreationIntent &&
        creationGuard
            .didPrepareRendererPlatformObjectTokenBackedCreationGuard &&
        failurePolicy
            .didPrepareRendererPlatformObjectTokenBackedCreationFailurePolicy &&
        failurePolicy.didKeepFailurePolicyFailClosed
    return CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness(
        creationIntent,
        creationGuard,
        failurePolicy,
        readinessReady,
        !readinessReady,
        !readinessReady,
        creationIntent
            .didPrepareRendererPlatformObjectTokenBackedCreationIntent,
        creationGuard
            .didPrepareRendererPlatformObjectTokenBackedCreationGuard,
        failurePolicy
            .didPrepareRendererPlatformObjectTokenBackedCreationFailurePolicy,
        creationIntent.didDefinePlatformObjectCreationIntent,
        creationIntent.didConfirmTokenBackedObjectIdentityPolicy,
        creationIntent.didRequireMainThreadCreationAdmissionGuard,
        creationGuard.didConfirmAllocationStillBlockedProof,
        creationGuard.didConfirmNoPointerHandleReturnPolicy,
        creationGuard.didConfirmTokenIssueBeforeBindDenied,
        creationGuard.didConfirmRevokeBeforeDestroyRequired,
        failurePolicy.didClassifyClassUnavailableFailure,
        failurePolicy.didClassifyBackgroundThreadFailure,
        failurePolicy.didClassifyAllocationBlockedFailure,
        failurePolicy.didClassifyTokenTableDisabledFailure,
        true,
        true,
        true,
        creationGuard.didConfirmNoObjectTableImplementation,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererPlatformObjectTokenBackedCreationDraft():
    CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness {
    let appkitMainThreadAdmissionReadiness =
        cjguiInternalExecuteDefaultRendererPlatformObjectAppKitMainThreadAdmissionDraft()
    return cjguiInternalBuildRendererPlatformObjectTokenBackedCreationReadiness(
        appkitMainThreadAdmissionReadiness
    )
}
