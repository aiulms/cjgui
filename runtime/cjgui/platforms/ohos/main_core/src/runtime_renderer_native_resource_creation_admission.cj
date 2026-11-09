// Owner: native bridge resource creation admission value boundary。
// Truth: 只消费 CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness，
// 记录 native resource creation admission intent、main-thread gate
// prerequisite、token table prerequisite、teardown callable prerequisite、
// token-return-only future policy 与 no-native-resource-creation-admission
// readiness facts。
// Stop-line: 不新增 native resource C ABI，不创建 native object / handle /
// pointer，不返回 native pointer，不实现 token table，不调用 retain /
// release / destroy，不改 runtime_state.cj，不把 resource creation
// admission 解释成 resource exists 或 backend-ready truth。
// Same-shape Boundary Brake: 不得把本 owner 包成 resource creation
// permission、native object permission、native handle permission、
// Metal/AppKit、backend-ready、public API、receipt、record 或 publication
// wrapper。
package cjgui

struct CjguiInternalRendererNativeResourceCreationAdmissionIntent {
    let teardownCallableReadiness:
        CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness
    let didPrepareRendererNativeResourceCreationAdmissionIntent: Bool
    let shouldDeferRendererNativeResourceCreationAdmissionIntent: Bool
    let shouldReportRendererNativeResourceCreationAdmissionIntentBlocked:
        Bool
    let didPreserveRendererNativeBridgeTeardownCallableReadiness: Bool
    let didDefineFutureNativeResourceCreationAdmissionIntent: Bool
    let didRequireValueBoundaryBeforeNativeCallable: Bool
    let didKeepResourceCreationAdmissionIntentDehydrated: Bool
    let didAvoidResourceCreationPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        teardownCallableReadiness:
            CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness,
        didPrepareRendererNativeResourceCreationAdmissionIntent: Bool,
        shouldDeferRendererNativeResourceCreationAdmissionIntent: Bool,
        shouldReportRendererNativeResourceCreationAdmissionIntentBlocked:
            Bool,
        didPreserveRendererNativeBridgeTeardownCallableReadiness: Bool,
        didDefineFutureNativeResourceCreationAdmissionIntent: Bool,
        didRequireValueBoundaryBeforeNativeCallable: Bool,
        didKeepResourceCreationAdmissionIntentDehydrated: Bool,
        didAvoidResourceCreationPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.teardownCallableReadiness = teardownCallableReadiness
        this.didPrepareRendererNativeResourceCreationAdmissionIntent =
            didPrepareRendererNativeResourceCreationAdmissionIntent
        this.shouldDeferRendererNativeResourceCreationAdmissionIntent =
            shouldDeferRendererNativeResourceCreationAdmissionIntent
        this
            .shouldReportRendererNativeResourceCreationAdmissionIntentBlocked =
            shouldReportRendererNativeResourceCreationAdmissionIntentBlocked
        this.didPreserveRendererNativeBridgeTeardownCallableReadiness =
            didPreserveRendererNativeBridgeTeardownCallableReadiness
        this.didDefineFutureNativeResourceCreationAdmissionIntent =
            didDefineFutureNativeResourceCreationAdmissionIntent
        this.didRequireValueBoundaryBeforeNativeCallable =
            didRequireValueBoundaryBeforeNativeCallable
        this.didKeepResourceCreationAdmissionIntentDehydrated =
            didKeepResourceCreationAdmissionIntentDehydrated
        this.didAvoidResourceCreationPermissionWrapper =
            didAvoidResourceCreationPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeResourceMainThreadGatePrerequisitePolicy {
    let creationAdmissionIntent:
        CjguiInternalRendererNativeResourceCreationAdmissionIntent
    let didPrepareRendererNativeResourceMainThreadGatePrerequisitePolicy:
        Bool
    let shouldDeferRendererNativeResourceMainThreadGatePrerequisitePolicy:
        Bool
    let shouldReportRendererNativeResourceMainThreadGatePrerequisitePolicyBlocked:
        Bool
    let didPreserveRendererNativeResourceCreationAdmissionIntent: Bool
    let didRequireMainThreadGateBeforeResourceCreation: Bool
    let didRequireMainThreadObservationFactsOnly: Bool
    let didForbidMainThreadDispatchInCurrentSlice: Bool
    let didKeepMainThreadGatePrerequisitePolicyDehydrated: Bool
    let didAvoidAppKitPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        creationAdmissionIntent:
            CjguiInternalRendererNativeResourceCreationAdmissionIntent,
        didPrepareRendererNativeResourceMainThreadGatePrerequisitePolicy:
            Bool,
        shouldDeferRendererNativeResourceMainThreadGatePrerequisitePolicy:
            Bool,
        shouldReportRendererNativeResourceMainThreadGatePrerequisitePolicyBlocked:
            Bool,
        didPreserveRendererNativeResourceCreationAdmissionIntent: Bool,
        didRequireMainThreadGateBeforeResourceCreation: Bool,
        didRequireMainThreadObservationFactsOnly: Bool,
        didForbidMainThreadDispatchInCurrentSlice: Bool,
        didKeepMainThreadGatePrerequisitePolicyDehydrated: Bool,
        didAvoidAppKitPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.creationAdmissionIntent = creationAdmissionIntent
        this
            .didPrepareRendererNativeResourceMainThreadGatePrerequisitePolicy =
            didPrepareRendererNativeResourceMainThreadGatePrerequisitePolicy
        this
            .shouldDeferRendererNativeResourceMainThreadGatePrerequisitePolicy =
            shouldDeferRendererNativeResourceMainThreadGatePrerequisitePolicy
        this
            .shouldReportRendererNativeResourceMainThreadGatePrerequisitePolicyBlocked =
            shouldReportRendererNativeResourceMainThreadGatePrerequisitePolicyBlocked
        this.didPreserveRendererNativeResourceCreationAdmissionIntent =
            didPreserveRendererNativeResourceCreationAdmissionIntent
        this.didRequireMainThreadGateBeforeResourceCreation =
            didRequireMainThreadGateBeforeResourceCreation
        this.didRequireMainThreadObservationFactsOnly =
            didRequireMainThreadObservationFactsOnly
        this.didForbidMainThreadDispatchInCurrentSlice =
            didForbidMainThreadDispatchInCurrentSlice
        this.didKeepMainThreadGatePrerequisitePolicyDehydrated =
            didKeepMainThreadGatePrerequisitePolicyDehydrated
        this.didAvoidAppKitPermissionWrapper =
            didAvoidAppKitPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeResourceTokenTablePrerequisitePolicy {
    let mainThreadGatePolicy:
        CjguiInternalRendererNativeResourceMainThreadGatePrerequisitePolicy
    let didPrepareRendererNativeResourceTokenTablePrerequisitePolicy: Bool
    let shouldDeferRendererNativeResourceTokenTablePrerequisitePolicy: Bool
    let shouldReportRendererNativeResourceTokenTablePrerequisitePolicyBlocked:
        Bool
    let didPreserveRendererNativeResourceMainThreadGatePrerequisitePolicy:
        Bool
    let didRequireTokenTableBeforeResourceCreation: Bool
    let didRequireBridgeLocalOpaqueTokenOwnership: Bool
    let didRequireGenerationEpochInvalidationFacts: Bool
    let didForbidTokenTableImplementationInCurrentSlice: Bool
    let didKeepTokenTablePrerequisitePolicyDehydrated: Bool
    let didAvoidTokenTableImplementationWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        mainThreadGatePolicy:
            CjguiInternalRendererNativeResourceMainThreadGatePrerequisitePolicy,
        didPrepareRendererNativeResourceTokenTablePrerequisitePolicy: Bool,
        shouldDeferRendererNativeResourceTokenTablePrerequisitePolicy: Bool,
        shouldReportRendererNativeResourceTokenTablePrerequisitePolicyBlocked:
            Bool,
        didPreserveRendererNativeResourceMainThreadGatePrerequisitePolicy:
            Bool,
        didRequireTokenTableBeforeResourceCreation: Bool,
        didRequireBridgeLocalOpaqueTokenOwnership: Bool,
        didRequireGenerationEpochInvalidationFacts: Bool,
        didForbidTokenTableImplementationInCurrentSlice: Bool,
        didKeepTokenTablePrerequisitePolicyDehydrated: Bool,
        didAvoidTokenTableImplementationWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.mainThreadGatePolicy = mainThreadGatePolicy
        this.didPrepareRendererNativeResourceTokenTablePrerequisitePolicy =
            didPrepareRendererNativeResourceTokenTablePrerequisitePolicy
        this.shouldDeferRendererNativeResourceTokenTablePrerequisitePolicy =
            shouldDeferRendererNativeResourceTokenTablePrerequisitePolicy
        this
            .shouldReportRendererNativeResourceTokenTablePrerequisitePolicyBlocked =
            shouldReportRendererNativeResourceTokenTablePrerequisitePolicyBlocked
        this
            .didPreserveRendererNativeResourceMainThreadGatePrerequisitePolicy =
            didPreserveRendererNativeResourceMainThreadGatePrerequisitePolicy
        this.didRequireTokenTableBeforeResourceCreation =
            didRequireTokenTableBeforeResourceCreation
        this.didRequireBridgeLocalOpaqueTokenOwnership =
            didRequireBridgeLocalOpaqueTokenOwnership
        this.didRequireGenerationEpochInvalidationFacts =
            didRequireGenerationEpochInvalidationFacts
        this.didForbidTokenTableImplementationInCurrentSlice =
            didForbidTokenTableImplementationInCurrentSlice
        this.didKeepTokenTablePrerequisitePolicyDehydrated =
            didKeepTokenTablePrerequisitePolicyDehydrated
        this.didAvoidTokenTableImplementationWrapper =
            didAvoidTokenTableImplementationWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeResourceTeardownPrerequisitePolicy {
    let tokenTablePolicy:
        CjguiInternalRendererNativeResourceTokenTablePrerequisitePolicy
    let didPrepareRendererNativeResourceTeardownPrerequisitePolicy: Bool
    let shouldDeferRendererNativeResourceTeardownPrerequisitePolicy: Bool
    let shouldReportRendererNativeResourceTeardownPrerequisitePolicyBlocked:
        Bool
    let didPreserveRendererNativeResourceTokenTablePrerequisitePolicy:
        Bool
    let didRequireTeardownCallableBeforeResourceCreation: Bool
    let didRequireRevokeBeforeDestroyCompatibility: Bool
    let didRequireDoubleDestroyDanglingTokenFailClosed: Bool
    let didForbidDestroyImplementationInCurrentSlice: Bool
    let didKeepTeardownPrerequisitePolicyDehydrated: Bool
    let didAvoidDestroyPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        tokenTablePolicy:
            CjguiInternalRendererNativeResourceTokenTablePrerequisitePolicy,
        didPrepareRendererNativeResourceTeardownPrerequisitePolicy: Bool,
        shouldDeferRendererNativeResourceTeardownPrerequisitePolicy: Bool,
        shouldReportRendererNativeResourceTeardownPrerequisitePolicyBlocked:
            Bool,
        didPreserveRendererNativeResourceTokenTablePrerequisitePolicy:
            Bool,
        didRequireTeardownCallableBeforeResourceCreation: Bool,
        didRequireRevokeBeforeDestroyCompatibility: Bool,
        didRequireDoubleDestroyDanglingTokenFailClosed: Bool,
        didForbidDestroyImplementationInCurrentSlice: Bool,
        didKeepTeardownPrerequisitePolicyDehydrated: Bool,
        didAvoidDestroyPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.tokenTablePolicy = tokenTablePolicy
        this.didPrepareRendererNativeResourceTeardownPrerequisitePolicy =
            didPrepareRendererNativeResourceTeardownPrerequisitePolicy
        this.shouldDeferRendererNativeResourceTeardownPrerequisitePolicy =
            shouldDeferRendererNativeResourceTeardownPrerequisitePolicy
        this
            .shouldReportRendererNativeResourceTeardownPrerequisitePolicyBlocked =
            shouldReportRendererNativeResourceTeardownPrerequisitePolicyBlocked
        this.didPreserveRendererNativeResourceTokenTablePrerequisitePolicy =
            didPreserveRendererNativeResourceTokenTablePrerequisitePolicy
        this.didRequireTeardownCallableBeforeResourceCreation =
            didRequireTeardownCallableBeforeResourceCreation
        this.didRequireRevokeBeforeDestroyCompatibility =
            didRequireRevokeBeforeDestroyCompatibility
        this.didRequireDoubleDestroyDanglingTokenFailClosed =
            didRequireDoubleDestroyDanglingTokenFailClosed
        this.didForbidDestroyImplementationInCurrentSlice =
            didForbidDestroyImplementationInCurrentSlice
        this.didKeepTeardownPrerequisitePolicyDehydrated =
            didKeepTeardownPrerequisitePolicyDehydrated
        this.didAvoidDestroyPermissionWrapper =
            didAvoidDestroyPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeResourceTokenReturnOnlyFuturePolicy {
    let teardownPrerequisitePolicy:
        CjguiInternalRendererNativeResourceTeardownPrerequisitePolicy
    let didPrepareRendererNativeResourceTokenReturnOnlyFuturePolicy: Bool
    let shouldDeferRendererNativeResourceTokenReturnOnlyFuturePolicy: Bool
    let shouldReportRendererNativeResourceTokenReturnOnlyFuturePolicyBlocked:
        Bool
    let didPreserveRendererNativeResourceTeardownPrerequisitePolicy: Bool
    let didRequireFutureResourceCreationReturnTokenOnly: Bool
    let didForbidFutureResourceCreationPointerReturn: Bool
    let didForbidFutureResourceCreationPublicSurface: Bool
    let didForbidFutureResourceCreationBackendReadyTruth: Bool
    let didKeepTokenReturnOnlyFuturePolicyDehydrated: Bool
    let didAvoidNativeHandlePermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        teardownPrerequisitePolicy:
            CjguiInternalRendererNativeResourceTeardownPrerequisitePolicy,
        didPrepareRendererNativeResourceTokenReturnOnlyFuturePolicy: Bool,
        shouldDeferRendererNativeResourceTokenReturnOnlyFuturePolicy: Bool,
        shouldReportRendererNativeResourceTokenReturnOnlyFuturePolicyBlocked:
            Bool,
        didPreserveRendererNativeResourceTeardownPrerequisitePolicy: Bool,
        didRequireFutureResourceCreationReturnTokenOnly: Bool,
        didForbidFutureResourceCreationPointerReturn: Bool,
        didForbidFutureResourceCreationPublicSurface: Bool,
        didForbidFutureResourceCreationBackendReadyTruth: Bool,
        didKeepTokenReturnOnlyFuturePolicyDehydrated: Bool,
        didAvoidNativeHandlePermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.teardownPrerequisitePolicy = teardownPrerequisitePolicy
        this.didPrepareRendererNativeResourceTokenReturnOnlyFuturePolicy =
            didPrepareRendererNativeResourceTokenReturnOnlyFuturePolicy
        this.shouldDeferRendererNativeResourceTokenReturnOnlyFuturePolicy =
            shouldDeferRendererNativeResourceTokenReturnOnlyFuturePolicy
        this
            .shouldReportRendererNativeResourceTokenReturnOnlyFuturePolicyBlocked =
            shouldReportRendererNativeResourceTokenReturnOnlyFuturePolicyBlocked
        this.didPreserveRendererNativeResourceTeardownPrerequisitePolicy =
            didPreserveRendererNativeResourceTeardownPrerequisitePolicy
        this.didRequireFutureResourceCreationReturnTokenOnly =
            didRequireFutureResourceCreationReturnTokenOnly
        this.didForbidFutureResourceCreationPointerReturn =
            didForbidFutureResourceCreationPointerReturn
        this.didForbidFutureResourceCreationPublicSurface =
            didForbidFutureResourceCreationPublicSurface
        this.didForbidFutureResourceCreationBackendReadyTruth =
            didForbidFutureResourceCreationBackendReadyTruth
        this.didKeepTokenReturnOnlyFuturePolicyDehydrated =
            didKeepTokenReturnOnlyFuturePolicyDehydrated
        this.didAvoidNativeHandlePermissionWrapper =
            didAvoidNativeHandlePermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoNativeResourceCreationAdmissionReadiness {
    let tokenReturnOnlyFuturePolicy:
        CjguiInternalRendererNativeResourceTokenReturnOnlyFuturePolicy
    let didPrepareRendererNoNativeResourceCreationAdmissionReadiness: Bool
    let shouldDeferRendererNoNativeResourceCreationAdmissionReadiness: Bool
    let shouldReportRendererNoNativeResourceCreationAdmissionReadinessBlocked:
        Bool
    let didPreserveRendererNativeResourceTokenReturnOnlyFuturePolicy: Bool
    let didConfirmNativeResourceCreationAdmissionIntent: Bool
    let didConfirmMainThreadGatePrerequisitePolicy: Bool
    let didConfirmTokenTablePrerequisitePolicy: Bool
    let didConfirmTeardownCallablePrerequisitePolicy: Bool
    let didConfirmTokenReturnOnlyFuturePolicy: Bool
    let didConfirmNoNativeResourceCallable: Bool
    let didConfirmNoActualNativeResourceCreation: Bool
    let didConfirmNoTokenTableImplementation: Bool
    let didConfirmNoDestroyImplementation: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoNativeObjectHandleOrPointer: Bool
    let didConfirmNoMetalOrAppKitUsage: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoNativeResourceCreationAdmissionReadinessDehydrated: Bool
    let didAvoidResourceCreationPermissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        tokenReturnOnlyFuturePolicy:
            CjguiInternalRendererNativeResourceTokenReturnOnlyFuturePolicy,
        didPrepareRendererNoNativeResourceCreationAdmissionReadiness: Bool,
        shouldDeferRendererNoNativeResourceCreationAdmissionReadiness: Bool,
        shouldReportRendererNoNativeResourceCreationAdmissionReadinessBlocked:
            Bool,
        didPreserveRendererNativeResourceTokenReturnOnlyFuturePolicy: Bool,
        didConfirmNativeResourceCreationAdmissionIntent: Bool,
        didConfirmMainThreadGatePrerequisitePolicy: Bool,
        didConfirmTokenTablePrerequisitePolicy: Bool,
        didConfirmTeardownCallablePrerequisitePolicy: Bool,
        didConfirmTokenReturnOnlyFuturePolicy: Bool,
        didConfirmNoNativeResourceCallable: Bool,
        didConfirmNoActualNativeResourceCreation: Bool,
        didConfirmNoTokenTableImplementation: Bool,
        didConfirmNoDestroyImplementation: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoNativeObjectHandleOrPointer: Bool,
        didConfirmNoMetalOrAppKitUsage: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoNativeResourceCreationAdmissionReadinessDehydrated: Bool,
        didAvoidResourceCreationPermissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.tokenReturnOnlyFuturePolicy = tokenReturnOnlyFuturePolicy
        this.didPrepareRendererNoNativeResourceCreationAdmissionReadiness =
            didPrepareRendererNoNativeResourceCreationAdmissionReadiness
        this.shouldDeferRendererNoNativeResourceCreationAdmissionReadiness =
            shouldDeferRendererNoNativeResourceCreationAdmissionReadiness
        this
            .shouldReportRendererNoNativeResourceCreationAdmissionReadinessBlocked =
            shouldReportRendererNoNativeResourceCreationAdmissionReadinessBlocked
        this.didPreserveRendererNativeResourceTokenReturnOnlyFuturePolicy =
            didPreserveRendererNativeResourceTokenReturnOnlyFuturePolicy
        this.didConfirmNativeResourceCreationAdmissionIntent =
            didConfirmNativeResourceCreationAdmissionIntent
        this.didConfirmMainThreadGatePrerequisitePolicy =
            didConfirmMainThreadGatePrerequisitePolicy
        this.didConfirmTokenTablePrerequisitePolicy =
            didConfirmTokenTablePrerequisitePolicy
        this.didConfirmTeardownCallablePrerequisitePolicy =
            didConfirmTeardownCallablePrerequisitePolicy
        this.didConfirmTokenReturnOnlyFuturePolicy =
            didConfirmTokenReturnOnlyFuturePolicy
        this.didConfirmNoNativeResourceCallable =
            didConfirmNoNativeResourceCallable
        this.didConfirmNoActualNativeResourceCreation =
            didConfirmNoActualNativeResourceCreation
        this.didConfirmNoTokenTableImplementation =
            didConfirmNoTokenTableImplementation
        this.didConfirmNoDestroyImplementation =
            didConfirmNoDestroyImplementation
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoNativeObjectHandleOrPointer =
            didConfirmNoNativeObjectHandleOrPointer
        this.didConfirmNoMetalOrAppKitUsage =
            didConfirmNoMetalOrAppKitUsage
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this
            .didKeepNoNativeResourceCreationAdmissionReadinessDehydrated =
            didKeepNoNativeResourceCreationAdmissionReadinessDehydrated
        this.didAvoidResourceCreationPermissionWrapper =
            didAvoidResourceCreationPermissionWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererNativeResourceCreationAdmissionReadiness(
    teardownCallableReadiness:
        CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness
): CjguiInternalRendererNoNativeResourceCreationAdmissionReadiness {
    let upstreamEvidenceReady =
        teardownCallableReadiness
            .didPrepareRendererNoNativeBridgeTeardownCallableReadiness &&
        teardownCallableReadiness.didConfirmNoDestroyCallablePolicy &&
        teardownCallableReadiness
            .didConfirmRevokeBeforeDestroyCallablePolicy &&
        teardownCallableReadiness
            .didConfirmDoubleDestroyDanglingTokenClassification &&
        teardownCallableReadiness
            .didConfirmMainThreadDestroyCallableGatePolicy &&
        teardownCallableReadiness.didConfirmNoTeardownCAbiImplementation &&
        teardownCallableReadiness.didConfirmNoActualDestroyRetainRelease &&
        teardownCallableReadiness.didConfirmNoTokenTableImplementation &&
        teardownCallableReadiness.didConfirmNoPublicSurface &&
        teardownCallableReadiness.didConfirmNoResourceCallable &&
        teardownCallableReadiness.didConfirmNoNativeObjectHandleOrPointer &&
        teardownCallableReadiness.didConfirmNoMetalOrAppKitUsage &&
        teardownCallableReadiness.didConfirmNoRendererStateWrite &&
        teardownCallableReadiness.didConfirmNoBackendReadyTruth &&
        teardownCallableReadiness
            .shouldReportRendererNoNativeBridgeTeardownCallableReadinessBlocked ==
            false
    let shouldDeferResourceCreationImplementation = true
    let intent =
        CjguiInternalRendererNativeResourceCreationAdmissionIntent(
            teardownCallableReadiness,
            upstreamEvidenceReady,
            shouldDeferResourceCreationImplementation,
            false,
            upstreamEvidenceReady,
            true,
            true,
            true,
            true,
            true
        )
    let mainThreadGatePolicy =
        CjguiInternalRendererNativeResourceMainThreadGatePrerequisitePolicy(
            intent,
            upstreamEvidenceReady,
            shouldDeferResourceCreationImplementation,
            false,
            upstreamEvidenceReady,
            true,
            true,
            true,
            true,
            true,
            true
        )
    let tokenTablePolicy =
        CjguiInternalRendererNativeResourceTokenTablePrerequisitePolicy(
            mainThreadGatePolicy,
            upstreamEvidenceReady,
            shouldDeferResourceCreationImplementation,
            false,
            upstreamEvidenceReady,
            true,
            true,
            true,
            true,
            true,
            true,
            true
        )
    let teardownPolicy =
        CjguiInternalRendererNativeResourceTeardownPrerequisitePolicy(
            tokenTablePolicy,
            upstreamEvidenceReady,
            shouldDeferResourceCreationImplementation,
            false,
            upstreamEvidenceReady,
            true,
            true,
            true,
            true,
            true,
            true,
            true
        )
    let tokenReturnPolicy =
        CjguiInternalRendererNativeResourceTokenReturnOnlyFuturePolicy(
            teardownPolicy,
            upstreamEvidenceReady,
            shouldDeferResourceCreationImplementation,
            false,
            upstreamEvidenceReady,
            true,
            true,
            true,
            true,
            true,
            true,
            true
        )
    return CjguiInternalRendererNoNativeResourceCreationAdmissionReadiness(
        tokenReturnPolicy,
        upstreamEvidenceReady,
        shouldDeferResourceCreationImplementation,
        false,
        upstreamEvidenceReady,
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
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererNativeResourceCreationAdmissionDraft():
    CjguiInternalRendererNoNativeResourceCreationAdmissionReadiness {
    let teardownCallableReadiness =
        cjguiInternalExecuteDefaultRendererNativeBridgeTeardownCallableDraft()
    return cjguiInternalBuildRendererNativeResourceCreationAdmissionReadiness(
        teardownCallableReadiness
    )
}
