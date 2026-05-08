// Owner: native bridge teardown implementation planning internal-only value boundary.
// Truth: 只消费 CjguiInternalRendererNoNativeHandleTokenReadiness，并记录
// native bridge teardown planning intent、destroy admission guard policy、
// token invalidation before destroy policy、double-destroy / dangling-token
// denial policy、main-thread destroy confinement policy、teardown failure
// classification 与 no-native-bridge-teardown-implementation readiness facts。
// Stop-line: 只产出 internal-only dehydrated facts；不调用 retain / release
// / destroy，不实现 destroy callback，不创建 native handle / raw pointer，
// 不新增 production .h / .m，不实现 C ABI / FFI，不触碰 Metal / AppKit /
// Objective-C，不写 renderer state，不发布 public API。
// Same-shape Boundary Brake: 不得把本 value boundary 包成 native bridge
// implementation、destroy permission、native handle、C ABI implementation、
// Metal、backend-ready、GPU-submission、render、public API、receipt、record 或
// publication wrapper。
package cjgui

struct CjguiInternalRendererNativeBridgeTeardownPlanningIntent {
    let noNativeHandleTokenReadiness:
        CjguiInternalRendererNoNativeHandleTokenReadiness
    let didPrepareRendererNativeBridgeTeardownPlanningIntent: Bool
    let shouldDeferRendererNativeBridgeTeardownPlanningIntent: Bool
    let shouldReportRendererNativeBridgeTeardownPlanningIntentBlocked: Bool
    let didPreserveRendererNoNativeHandleTokenReadiness: Bool
    let didDefineFutureNativeBridgeTeardownPlanningIntent: Bool
    let didRequirePlanningBeforeImplementation: Bool
    let didKeepSmokeDestroyEvidenceAsEvidenceOnly: Bool
    let didKeepNativeBridgeTeardownPlanningIntentDehydrated: Bool
    let didAvoidDestroyPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        noNativeHandleTokenReadiness:
            CjguiInternalRendererNoNativeHandleTokenReadiness,
        didPrepareRendererNativeBridgeTeardownPlanningIntent: Bool,
        shouldDeferRendererNativeBridgeTeardownPlanningIntent: Bool,
        shouldReportRendererNativeBridgeTeardownPlanningIntentBlocked: Bool,
        didPreserveRendererNoNativeHandleTokenReadiness: Bool,
        didDefineFutureNativeBridgeTeardownPlanningIntent: Bool,
        didRequirePlanningBeforeImplementation: Bool,
        didKeepSmokeDestroyEvidenceAsEvidenceOnly: Bool,
        didKeepNativeBridgeTeardownPlanningIntentDehydrated: Bool,
        didAvoidDestroyPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noNativeHandleTokenReadiness = noNativeHandleTokenReadiness
        this.didPrepareRendererNativeBridgeTeardownPlanningIntent =
            didPrepareRendererNativeBridgeTeardownPlanningIntent
        this.shouldDeferRendererNativeBridgeTeardownPlanningIntent =
            shouldDeferRendererNativeBridgeTeardownPlanningIntent
        this
            .shouldReportRendererNativeBridgeTeardownPlanningIntentBlocked =
            shouldReportRendererNativeBridgeTeardownPlanningIntentBlocked
        this.didPreserveRendererNoNativeHandleTokenReadiness =
            didPreserveRendererNoNativeHandleTokenReadiness
        this.didDefineFutureNativeBridgeTeardownPlanningIntent =
            didDefineFutureNativeBridgeTeardownPlanningIntent
        this.didRequirePlanningBeforeImplementation =
            didRequirePlanningBeforeImplementation
        this.didKeepSmokeDestroyEvidenceAsEvidenceOnly =
            didKeepSmokeDestroyEvidenceAsEvidenceOnly
        this.didKeepNativeBridgeTeardownPlanningIntentDehydrated =
            didKeepNativeBridgeTeardownPlanningIntentDehydrated
        this.didAvoidDestroyPermissionWrapper =
            didAvoidDestroyPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererDestroyAdmissionGuardPolicy {
    let teardownPlanningIntent:
        CjguiInternalRendererNativeBridgeTeardownPlanningIntent
    let didPrepareRendererDestroyAdmissionGuardPolicy: Bool
    let shouldDeferRendererDestroyAdmissionGuardPolicy: Bool
    let shouldReportRendererDestroyAdmissionGuardPolicyBlocked: Bool
    let didPreserveRendererNativeBridgeTeardownPlanningIntent: Bool
    let didDefineFutureDestroyAdmissionGuardPolicy: Bool
    let didRequireValidTokenBeforeDestroyAdmission: Bool
    let didConfirmNoActualDestroyCall: Bool
    let didConfirmNoDestroyCallbackImplementation: Bool
    let didKeepDestroyAdmissionGuardPolicyDehydrated: Bool
    let didAvoidNativeBridgeImplementationWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        teardownPlanningIntent:
            CjguiInternalRendererNativeBridgeTeardownPlanningIntent,
        didPrepareRendererDestroyAdmissionGuardPolicy: Bool,
        shouldDeferRendererDestroyAdmissionGuardPolicy: Bool,
        shouldReportRendererDestroyAdmissionGuardPolicyBlocked: Bool,
        didPreserveRendererNativeBridgeTeardownPlanningIntent: Bool,
        didDefineFutureDestroyAdmissionGuardPolicy: Bool,
        didRequireValidTokenBeforeDestroyAdmission: Bool,
        didConfirmNoActualDestroyCall: Bool,
        didConfirmNoDestroyCallbackImplementation: Bool,
        didKeepDestroyAdmissionGuardPolicyDehydrated: Bool,
        didAvoidNativeBridgeImplementationWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.teardownPlanningIntent = teardownPlanningIntent
        this.didPrepareRendererDestroyAdmissionGuardPolicy =
            didPrepareRendererDestroyAdmissionGuardPolicy
        this.shouldDeferRendererDestroyAdmissionGuardPolicy =
            shouldDeferRendererDestroyAdmissionGuardPolicy
        this.shouldReportRendererDestroyAdmissionGuardPolicyBlocked =
            shouldReportRendererDestroyAdmissionGuardPolicyBlocked
        this.didPreserveRendererNativeBridgeTeardownPlanningIntent =
            didPreserveRendererNativeBridgeTeardownPlanningIntent
        this.didDefineFutureDestroyAdmissionGuardPolicy =
            didDefineFutureDestroyAdmissionGuardPolicy
        this.didRequireValidTokenBeforeDestroyAdmission =
            didRequireValidTokenBeforeDestroyAdmission
        this.didConfirmNoActualDestroyCall =
            didConfirmNoActualDestroyCall
        this.didConfirmNoDestroyCallbackImplementation =
            didConfirmNoDestroyCallbackImplementation
        this.didKeepDestroyAdmissionGuardPolicyDehydrated =
            didKeepDestroyAdmissionGuardPolicyDehydrated
        this.didAvoidNativeBridgeImplementationWrapper =
            didAvoidNativeBridgeImplementationWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererTokenInvalidationBeforeDestroyPolicy {
    let destroyAdmissionGuardPolicy:
        CjguiInternalRendererDestroyAdmissionGuardPolicy
    let didPrepareRendererTokenInvalidationBeforeDestroyPolicy: Bool
    let shouldDeferRendererTokenInvalidationBeforeDestroyPolicy: Bool
    let shouldReportRendererTokenInvalidationBeforeDestroyPolicyBlocked: Bool
    let didPreserveRendererDestroyAdmissionGuardPolicy: Bool
    let didDefineTokenInvalidationBeforeDestroyPolicy: Bool
    let didRequireTokenInvalidationBeforeNativeDestroy: Bool
    let didConfirmNoTokenMutationSideEffect: Bool
    let didConfirmNoNativePointerReturn: Bool
    let didKeepTokenInvalidationBeforeDestroyPolicyDehydrated: Bool
    let didAvoidNativeHandlePermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        destroyAdmissionGuardPolicy:
            CjguiInternalRendererDestroyAdmissionGuardPolicy,
        didPrepareRendererTokenInvalidationBeforeDestroyPolicy: Bool,
        shouldDeferRendererTokenInvalidationBeforeDestroyPolicy: Bool,
        shouldReportRendererTokenInvalidationBeforeDestroyPolicyBlocked:
            Bool,
        didPreserveRendererDestroyAdmissionGuardPolicy: Bool,
        didDefineTokenInvalidationBeforeDestroyPolicy: Bool,
        didRequireTokenInvalidationBeforeNativeDestroy: Bool,
        didConfirmNoTokenMutationSideEffect: Bool,
        didConfirmNoNativePointerReturn: Bool,
        didKeepTokenInvalidationBeforeDestroyPolicyDehydrated: Bool,
        didAvoidNativeHandlePermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.destroyAdmissionGuardPolicy = destroyAdmissionGuardPolicy
        this.didPrepareRendererTokenInvalidationBeforeDestroyPolicy =
            didPrepareRendererTokenInvalidationBeforeDestroyPolicy
        this.shouldDeferRendererTokenInvalidationBeforeDestroyPolicy =
            shouldDeferRendererTokenInvalidationBeforeDestroyPolicy
        this
            .shouldReportRendererTokenInvalidationBeforeDestroyPolicyBlocked =
            shouldReportRendererTokenInvalidationBeforeDestroyPolicyBlocked
        this.didPreserveRendererDestroyAdmissionGuardPolicy =
            didPreserveRendererDestroyAdmissionGuardPolicy
        this.didDefineTokenInvalidationBeforeDestroyPolicy =
            didDefineTokenInvalidationBeforeDestroyPolicy
        this.didRequireTokenInvalidationBeforeNativeDestroy =
            didRequireTokenInvalidationBeforeNativeDestroy
        this.didConfirmNoTokenMutationSideEffect =
            didConfirmNoTokenMutationSideEffect
        this.didConfirmNoNativePointerReturn =
            didConfirmNoNativePointerReturn
        this.didKeepTokenInvalidationBeforeDestroyPolicyDehydrated =
            didKeepTokenInvalidationBeforeDestroyPolicyDehydrated
        this.didAvoidNativeHandlePermissionWrapper =
            didAvoidNativeHandlePermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeBridgeTeardownSafetyDenialPolicy {
    let invalidationBeforeDestroyPolicy:
        CjguiInternalRendererTokenInvalidationBeforeDestroyPolicy
    let didPrepareRendererNativeBridgeTeardownSafetyDenialPolicy: Bool
    let shouldDeferRendererNativeBridgeTeardownSafetyDenialPolicy: Bool
    let shouldReportRendererNativeBridgeTeardownSafetyDenialPolicyBlocked:
        Bool
    let didPreserveRendererTokenInvalidationBeforeDestroyPolicy: Bool
    let didDefineDoubleDestroyDenialPolicy: Bool
    let didDefineDanglingTokenDenialPolicy: Bool
    let didConfirmIdempotentNoOpPlanning: Bool
    let didConfirmFailClosedOnUnsafeTeardown: Bool
    let didKeepNativeBridgeTeardownSafetyDenialPolicyDehydrated: Bool
    let didAvoidDestroyPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        invalidationBeforeDestroyPolicy:
            CjguiInternalRendererTokenInvalidationBeforeDestroyPolicy,
        didPrepareRendererNativeBridgeTeardownSafetyDenialPolicy: Bool,
        shouldDeferRendererNativeBridgeTeardownSafetyDenialPolicy: Bool,
        shouldReportRendererNativeBridgeTeardownSafetyDenialPolicyBlocked:
            Bool,
        didPreserveRendererTokenInvalidationBeforeDestroyPolicy: Bool,
        didDefineDoubleDestroyDenialPolicy: Bool,
        didDefineDanglingTokenDenialPolicy: Bool,
        didConfirmIdempotentNoOpPlanning: Bool,
        didConfirmFailClosedOnUnsafeTeardown: Bool,
        didKeepNativeBridgeTeardownSafetyDenialPolicyDehydrated: Bool,
        didAvoidDestroyPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.invalidationBeforeDestroyPolicy =
            invalidationBeforeDestroyPolicy
        this.didPrepareRendererNativeBridgeTeardownSafetyDenialPolicy =
            didPrepareRendererNativeBridgeTeardownSafetyDenialPolicy
        this.shouldDeferRendererNativeBridgeTeardownSafetyDenialPolicy =
            shouldDeferRendererNativeBridgeTeardownSafetyDenialPolicy
        this
            .shouldReportRendererNativeBridgeTeardownSafetyDenialPolicyBlocked =
            shouldReportRendererNativeBridgeTeardownSafetyDenialPolicyBlocked
        this.didPreserveRendererTokenInvalidationBeforeDestroyPolicy =
            didPreserveRendererTokenInvalidationBeforeDestroyPolicy
        this.didDefineDoubleDestroyDenialPolicy =
            didDefineDoubleDestroyDenialPolicy
        this.didDefineDanglingTokenDenialPolicy =
            didDefineDanglingTokenDenialPolicy
        this.didConfirmIdempotentNoOpPlanning =
            didConfirmIdempotentNoOpPlanning
        this.didConfirmFailClosedOnUnsafeTeardown =
            didConfirmFailClosedOnUnsafeTeardown
        this.didKeepNativeBridgeTeardownSafetyDenialPolicyDehydrated =
            didKeepNativeBridgeTeardownSafetyDenialPolicyDehydrated
        this.didAvoidDestroyPermissionWrapper =
            didAvoidDestroyPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererMainThreadDestroyConfinementPolicy {
    let safetyDenialPolicy:
        CjguiInternalRendererNativeBridgeTeardownSafetyDenialPolicy
    let didPrepareRendererMainThreadDestroyConfinementPolicy: Bool
    let shouldDeferRendererMainThreadDestroyConfinementPolicy: Bool
    let shouldReportRendererMainThreadDestroyConfinementPolicyBlocked: Bool
    let didPreserveRendererNativeBridgeTeardownSafetyDenialPolicy: Bool
    let didDefineMainThreadDestroyConfinementPolicy: Bool
    let didRequireMainThreadConfinementPlanning: Bool
    let didConfirmNoMainThreadDispatch: Bool
    let didConfirmNoAppKitMetalObjectiveCCall: Bool
    let didKeepMainThreadDestroyConfinementPolicyDehydrated: Bool
    let didAvoidThreadReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        safetyDenialPolicy:
            CjguiInternalRendererNativeBridgeTeardownSafetyDenialPolicy,
        didPrepareRendererMainThreadDestroyConfinementPolicy: Bool,
        shouldDeferRendererMainThreadDestroyConfinementPolicy: Bool,
        shouldReportRendererMainThreadDestroyConfinementPolicyBlocked: Bool,
        didPreserveRendererNativeBridgeTeardownSafetyDenialPolicy: Bool,
        didDefineMainThreadDestroyConfinementPolicy: Bool,
        didRequireMainThreadConfinementPlanning: Bool,
        didConfirmNoMainThreadDispatch: Bool,
        didConfirmNoAppKitMetalObjectiveCCall: Bool,
        didKeepMainThreadDestroyConfinementPolicyDehydrated: Bool,
        didAvoidThreadReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.safetyDenialPolicy = safetyDenialPolicy
        this.didPrepareRendererMainThreadDestroyConfinementPolicy =
            didPrepareRendererMainThreadDestroyConfinementPolicy
        this.shouldDeferRendererMainThreadDestroyConfinementPolicy =
            shouldDeferRendererMainThreadDestroyConfinementPolicy
        this.shouldReportRendererMainThreadDestroyConfinementPolicyBlocked =
            shouldReportRendererMainThreadDestroyConfinementPolicyBlocked
        this.didPreserveRendererNativeBridgeTeardownSafetyDenialPolicy =
            didPreserveRendererNativeBridgeTeardownSafetyDenialPolicy
        this.didDefineMainThreadDestroyConfinementPolicy =
            didDefineMainThreadDestroyConfinementPolicy
        this.didRequireMainThreadConfinementPlanning =
            didRequireMainThreadConfinementPlanning
        this.didConfirmNoMainThreadDispatch =
            didConfirmNoMainThreadDispatch
        this.didConfirmNoAppKitMetalObjectiveCCall =
            didConfirmNoAppKitMetalObjectiveCCall
        this.didKeepMainThreadDestroyConfinementPolicyDehydrated =
            didKeepMainThreadDestroyConfinementPolicyDehydrated
        this.didAvoidThreadReadyWrapper = didAvoidThreadReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeBridgeTeardownFailureClassification {
    let mainThreadDestroyConfinementPolicy:
        CjguiInternalRendererMainThreadDestroyConfinementPolicy
    let didPrepareRendererNativeBridgeTeardownFailureClassification: Bool
    let shouldDeferRendererNativeBridgeTeardownFailureClassification: Bool
    let shouldReportRendererNativeBridgeTeardownFailureClassificationBlocked:
        Bool
    let didPreserveRendererMainThreadDestroyConfinementPolicy: Bool
    let didDefineTeardownFailureClassification: Bool
    let didClassifyDoubleDestroy: Bool
    let didClassifyDanglingToken: Bool
    let didClassifyWrongThreadDestroy: Bool
    let didClassifyBridgeOptimism: Bool
    let didClassifyRollbackBlocked: Bool
    let didKeepTeardownFailureClassificationDehydrated: Bool
    let didAvoidDiagnosticsWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        mainThreadDestroyConfinementPolicy:
            CjguiInternalRendererMainThreadDestroyConfinementPolicy,
        didPrepareRendererNativeBridgeTeardownFailureClassification: Bool,
        shouldDeferRendererNativeBridgeTeardownFailureClassification: Bool,
        shouldReportRendererNativeBridgeTeardownFailureClassificationBlocked:
            Bool,
        didPreserveRendererMainThreadDestroyConfinementPolicy: Bool,
        didDefineTeardownFailureClassification: Bool,
        didClassifyDoubleDestroy: Bool,
        didClassifyDanglingToken: Bool,
        didClassifyWrongThreadDestroy: Bool,
        didClassifyBridgeOptimism: Bool,
        didClassifyRollbackBlocked: Bool,
        didKeepTeardownFailureClassificationDehydrated: Bool,
        didAvoidDiagnosticsWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.mainThreadDestroyConfinementPolicy =
            mainThreadDestroyConfinementPolicy
        this.didPrepareRendererNativeBridgeTeardownFailureClassification =
            didPrepareRendererNativeBridgeTeardownFailureClassification
        this.shouldDeferRendererNativeBridgeTeardownFailureClassification =
            shouldDeferRendererNativeBridgeTeardownFailureClassification
        this
            .shouldReportRendererNativeBridgeTeardownFailureClassificationBlocked =
            shouldReportRendererNativeBridgeTeardownFailureClassificationBlocked
        this.didPreserveRendererMainThreadDestroyConfinementPolicy =
            didPreserveRendererMainThreadDestroyConfinementPolicy
        this.didDefineTeardownFailureClassification =
            didDefineTeardownFailureClassification
        this.didClassifyDoubleDestroy = didClassifyDoubleDestroy
        this.didClassifyDanglingToken = didClassifyDanglingToken
        this.didClassifyWrongThreadDestroy =
            didClassifyWrongThreadDestroy
        this.didClassifyBridgeOptimism = didClassifyBridgeOptimism
        this.didClassifyRollbackBlocked = didClassifyRollbackBlocked
        this.didKeepTeardownFailureClassificationDehydrated =
            didKeepTeardownFailureClassificationDehydrated
        this.didAvoidDiagnosticsWrapper = didAvoidDiagnosticsWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness {
    let failureClassification:
        CjguiInternalRendererNativeBridgeTeardownFailureClassification
    let didPrepareRendererNoNativeBridgeTeardownImplementationReadiness:
        Bool
    let didConfirmRendererNoNativeBridgeTeardownImplementationReadiness:
        Bool
    let shouldDeferRendererNoNativeBridgeTeardownImplementationReadiness:
        Bool
    let shouldReportRendererNoNativeBridgeTeardownImplementationReadinessBlocked:
        Bool
    let didPreserveRendererNativeBridgeTeardownFailureClassification: Bool
    let didConfirmNoActualDestroyReleaseRetain: Bool
    let didConfirmNoDestroyCallbackImplementation: Bool
    let didConfirmNoNativeHandleOrRawPointer: Bool
    let didConfirmNoProductionNativeFileCreation: Bool
    let didConfirmNoSmokeNativeFileModification: Bool
    let didConfirmNoCAbiImplementation: Bool
    let didConfirmNoFfiDeclaration: Bool
    let didConfirmNoNativeBridgeModification: Bool
    let didConfirmNoMetalOrAppKitCall: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didConfirmNoGpuSubmissionOrRender: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoPublicApiOrDiagnostics: Bool
    let didKeepNoNativeBridgeTeardownImplementationReadinessDehydrated:
        Bool
    let didAvoidPermissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        failureClassification:
            CjguiInternalRendererNativeBridgeTeardownFailureClassification,
        didPrepareRendererNoNativeBridgeTeardownImplementationReadiness:
            Bool,
        didConfirmRendererNoNativeBridgeTeardownImplementationReadiness:
            Bool,
        shouldDeferRendererNoNativeBridgeTeardownImplementationReadiness:
            Bool,
        shouldReportRendererNoNativeBridgeTeardownImplementationReadinessBlocked:
            Bool,
        didPreserveRendererNativeBridgeTeardownFailureClassification: Bool,
        didConfirmNoActualDestroyReleaseRetain: Bool,
        didConfirmNoDestroyCallbackImplementation: Bool,
        didConfirmNoNativeHandleOrRawPointer: Bool,
        didConfirmNoProductionNativeFileCreation: Bool,
        didConfirmNoSmokeNativeFileModification: Bool,
        didConfirmNoCAbiImplementation: Bool,
        didConfirmNoFfiDeclaration: Bool,
        didConfirmNoNativeBridgeModification: Bool,
        didConfirmNoMetalOrAppKitCall: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didConfirmNoGpuSubmissionOrRender: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoPublicApiOrDiagnostics: Bool,
        didKeepNoNativeBridgeTeardownImplementationReadinessDehydrated:
            Bool,
        didAvoidPermissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.failureClassification = failureClassification
        this
            .didPrepareRendererNoNativeBridgeTeardownImplementationReadiness =
            didPrepareRendererNoNativeBridgeTeardownImplementationReadiness
        this
            .didConfirmRendererNoNativeBridgeTeardownImplementationReadiness =
            didConfirmRendererNoNativeBridgeTeardownImplementationReadiness
        this
            .shouldDeferRendererNoNativeBridgeTeardownImplementationReadiness =
            shouldDeferRendererNoNativeBridgeTeardownImplementationReadiness
        this
            .shouldReportRendererNoNativeBridgeTeardownImplementationReadinessBlocked =
            shouldReportRendererNoNativeBridgeTeardownImplementationReadinessBlocked
        this.didPreserveRendererNativeBridgeTeardownFailureClassification =
            didPreserveRendererNativeBridgeTeardownFailureClassification
        this.didConfirmNoActualDestroyReleaseRetain =
            didConfirmNoActualDestroyReleaseRetain
        this.didConfirmNoDestroyCallbackImplementation =
            didConfirmNoDestroyCallbackImplementation
        this.didConfirmNoNativeHandleOrRawPointer =
            didConfirmNoNativeHandleOrRawPointer
        this.didConfirmNoProductionNativeFileCreation =
            didConfirmNoProductionNativeFileCreation
        this.didConfirmNoSmokeNativeFileModification =
            didConfirmNoSmokeNativeFileModification
        this.didConfirmNoCAbiImplementation =
            didConfirmNoCAbiImplementation
        this.didConfirmNoFfiDeclaration = didConfirmNoFfiDeclaration
        this.didConfirmNoNativeBridgeModification =
            didConfirmNoNativeBridgeModification
        this.didConfirmNoMetalOrAppKitCall =
            didConfirmNoMetalOrAppKitCall
        this.didConfirmNoBackendReadyTruth =
            didConfirmNoBackendReadyTruth
        this.didConfirmNoGpuSubmissionOrRender =
            didConfirmNoGpuSubmissionOrRender
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoPublicApiOrDiagnostics =
            didConfirmNoPublicApiOrDiagnostics
        this
            .didKeepNoNativeBridgeTeardownImplementationReadinessDehydrated =
            didKeepNoNativeBridgeTeardownImplementationReadinessDehydrated
        this.didAvoidPermissionWrapper = didAvoidPermissionWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererNativeBridgeTeardownPlanningIntent(
    noNativeHandleTokenReadiness:
        CjguiInternalRendererNoNativeHandleTokenReadiness
): CjguiInternalRendererNativeBridgeTeardownPlanningIntent {
    let upstreamReady =
        noNativeHandleTokenReadiness
            .didConfirmRendererNoNativeHandleTokenReadiness &&
        noNativeHandleTokenReadiness
            .shouldDeferRendererNoNativeHandleTokenReadiness == false &&
        noNativeHandleTokenReadiness
            .shouldReportRendererNoNativeHandleTokenReadinessBlocked ==
            false
    let upstreamDeferred =
        noNativeHandleTokenReadiness
            .shouldDeferRendererNoNativeHandleTokenReadiness &&
        noNativeHandleTokenReadiness
            .shouldReportRendererNoNativeHandleTokenReadinessBlocked ==
            false
    let upstreamInconsistent =
        noNativeHandleTokenReadiness
            .shouldReportRendererNoNativeHandleTokenReadinessBlocked ||
        (
            noNativeHandleTokenReadiness
                .didPrepareRendererNoNativeHandleTokenReadiness &&
            upstreamReady == false &&
            upstreamDeferred == false
        )

    return CjguiInternalRendererNativeBridgeTeardownPlanningIntent(
        noNativeHandleTokenReadiness,
        upstreamReady,
        upstreamDeferred,
        upstreamInconsistent,
        upstreamReady,
        upstreamReady,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererDestroyAdmissionGuardPolicy(
    teardownPlanningIntent:
        CjguiInternalRendererNativeBridgeTeardownPlanningIntent
): CjguiInternalRendererDestroyAdmissionGuardPolicy {
    let proofReady =
        teardownPlanningIntent
            .didPrepareRendererNativeBridgeTeardownPlanningIntent &&
        teardownPlanningIntent
            .didPreserveRendererNoNativeHandleTokenReadiness &&
        teardownPlanningIntent
            .didDefineFutureNativeBridgeTeardownPlanningIntent &&
        teardownPlanningIntent.didRequirePlanningBeforeImplementation &&
        teardownPlanningIntent.didKeepSmokeDestroyEvidenceAsEvidenceOnly &&
        teardownPlanningIntent
            .didKeepNativeBridgeTeardownPlanningIntentDehydrated &&
        teardownPlanningIntent.didAvoidDestroyPermissionWrapper &&
        teardownPlanningIntent.didAvoidThinWrapper &&
        teardownPlanningIntent
            .shouldDeferRendererNativeBridgeTeardownPlanningIntent == false &&
        teardownPlanningIntent
            .shouldReportRendererNativeBridgeTeardownPlanningIntentBlocked ==
            false
    let proofDeferred =
        teardownPlanningIntent
            .didPrepareRendererNativeBridgeTeardownPlanningIntent == false &&
        teardownPlanningIntent
            .shouldDeferRendererNativeBridgeTeardownPlanningIntent &&
        teardownPlanningIntent
            .shouldReportRendererNativeBridgeTeardownPlanningIntentBlocked ==
            false
    let proofInconsistent =
        teardownPlanningIntent
            .shouldReportRendererNativeBridgeTeardownPlanningIntentBlocked ||
        (
            teardownPlanningIntent
                .didPrepareRendererNativeBridgeTeardownPlanningIntent &&
            proofReady == false
        )

    return CjguiInternalRendererDestroyAdmissionGuardPolicy(
        teardownPlanningIntent,
        proofReady,
        proofDeferred,
        proofInconsistent,
        proofReady,
        proofReady,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererTokenInvalidationBeforeDestroyPolicy(
    destroyAdmissionGuardPolicy:
        CjguiInternalRendererDestroyAdmissionGuardPolicy
): CjguiInternalRendererTokenInvalidationBeforeDestroyPolicy {
    let proofReady =
        destroyAdmissionGuardPolicy
            .didPrepareRendererDestroyAdmissionGuardPolicy &&
        destroyAdmissionGuardPolicy
            .didPreserveRendererNativeBridgeTeardownPlanningIntent &&
        destroyAdmissionGuardPolicy.didDefineFutureDestroyAdmissionGuardPolicy &&
        destroyAdmissionGuardPolicy.didRequireValidTokenBeforeDestroyAdmission &&
        destroyAdmissionGuardPolicy.didConfirmNoActualDestroyCall &&
        destroyAdmissionGuardPolicy
            .didConfirmNoDestroyCallbackImplementation &&
        destroyAdmissionGuardPolicy
            .didKeepDestroyAdmissionGuardPolicyDehydrated &&
        destroyAdmissionGuardPolicy
            .didAvoidNativeBridgeImplementationWrapper &&
        destroyAdmissionGuardPolicy.didAvoidThinWrapper &&
        destroyAdmissionGuardPolicy
            .shouldDeferRendererDestroyAdmissionGuardPolicy == false &&
        destroyAdmissionGuardPolicy
            .shouldReportRendererDestroyAdmissionGuardPolicyBlocked == false
    let proofDeferred =
        destroyAdmissionGuardPolicy
            .didPrepareRendererDestroyAdmissionGuardPolicy == false &&
        destroyAdmissionGuardPolicy
            .shouldDeferRendererDestroyAdmissionGuardPolicy &&
        destroyAdmissionGuardPolicy
            .shouldReportRendererDestroyAdmissionGuardPolicyBlocked == false
    let proofInconsistent =
        destroyAdmissionGuardPolicy
            .shouldReportRendererDestroyAdmissionGuardPolicyBlocked ||
        (
            destroyAdmissionGuardPolicy
                .didPrepareRendererDestroyAdmissionGuardPolicy &&
            proofReady == false
        )

    return CjguiInternalRendererTokenInvalidationBeforeDestroyPolicy(
        destroyAdmissionGuardPolicy,
        proofReady,
        proofDeferred,
        proofInconsistent,
        proofReady,
        proofReady,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererNativeBridgeTeardownSafetyDenialPolicy(
    invalidationBeforeDestroyPolicy:
        CjguiInternalRendererTokenInvalidationBeforeDestroyPolicy
): CjguiInternalRendererNativeBridgeTeardownSafetyDenialPolicy {
    let proofReady =
        invalidationBeforeDestroyPolicy
            .didPrepareRendererTokenInvalidationBeforeDestroyPolicy &&
        invalidationBeforeDestroyPolicy
            .didPreserveRendererDestroyAdmissionGuardPolicy &&
        invalidationBeforeDestroyPolicy
            .didDefineTokenInvalidationBeforeDestroyPolicy &&
        invalidationBeforeDestroyPolicy
            .didRequireTokenInvalidationBeforeNativeDestroy &&
        invalidationBeforeDestroyPolicy.didConfirmNoTokenMutationSideEffect &&
        invalidationBeforeDestroyPolicy.didConfirmNoNativePointerReturn &&
        invalidationBeforeDestroyPolicy
            .didKeepTokenInvalidationBeforeDestroyPolicyDehydrated &&
        invalidationBeforeDestroyPolicy
            .didAvoidNativeHandlePermissionWrapper &&
        invalidationBeforeDestroyPolicy.didAvoidThinWrapper &&
        invalidationBeforeDestroyPolicy
            .shouldDeferRendererTokenInvalidationBeforeDestroyPolicy ==
            false &&
        invalidationBeforeDestroyPolicy
            .shouldReportRendererTokenInvalidationBeforeDestroyPolicyBlocked ==
            false
    let proofDeferred =
        invalidationBeforeDestroyPolicy
            .didPrepareRendererTokenInvalidationBeforeDestroyPolicy == false &&
        invalidationBeforeDestroyPolicy
            .shouldDeferRendererTokenInvalidationBeforeDestroyPolicy &&
        invalidationBeforeDestroyPolicy
            .shouldReportRendererTokenInvalidationBeforeDestroyPolicyBlocked ==
            false
    let proofInconsistent =
        invalidationBeforeDestroyPolicy
            .shouldReportRendererTokenInvalidationBeforeDestroyPolicyBlocked ||
        (
            invalidationBeforeDestroyPolicy
                .didPrepareRendererTokenInvalidationBeforeDestroyPolicy &&
            proofReady == false
        )

    return CjguiInternalRendererNativeBridgeTeardownSafetyDenialPolicy(
        invalidationBeforeDestroyPolicy,
        proofReady,
        proofDeferred,
        proofInconsistent,
        proofReady,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererMainThreadDestroyConfinementPolicy(
    safetyDenialPolicy:
        CjguiInternalRendererNativeBridgeTeardownSafetyDenialPolicy
): CjguiInternalRendererMainThreadDestroyConfinementPolicy {
    let proofReady =
        safetyDenialPolicy
            .didPrepareRendererNativeBridgeTeardownSafetyDenialPolicy &&
        safetyDenialPolicy
            .didPreserveRendererTokenInvalidationBeforeDestroyPolicy &&
        safetyDenialPolicy.didDefineDoubleDestroyDenialPolicy &&
        safetyDenialPolicy.didDefineDanglingTokenDenialPolicy &&
        safetyDenialPolicy.didConfirmIdempotentNoOpPlanning &&
        safetyDenialPolicy.didConfirmFailClosedOnUnsafeTeardown &&
        safetyDenialPolicy
            .didKeepNativeBridgeTeardownSafetyDenialPolicyDehydrated &&
        safetyDenialPolicy.didAvoidDestroyPermissionWrapper &&
        safetyDenialPolicy.didAvoidThinWrapper &&
        safetyDenialPolicy
            .shouldDeferRendererNativeBridgeTeardownSafetyDenialPolicy ==
            false &&
        safetyDenialPolicy
            .shouldReportRendererNativeBridgeTeardownSafetyDenialPolicyBlocked ==
            false
    let proofDeferred =
        safetyDenialPolicy
            .didPrepareRendererNativeBridgeTeardownSafetyDenialPolicy ==
            false &&
        safetyDenialPolicy
            .shouldDeferRendererNativeBridgeTeardownSafetyDenialPolicy &&
        safetyDenialPolicy
            .shouldReportRendererNativeBridgeTeardownSafetyDenialPolicyBlocked ==
            false
    let proofInconsistent =
        safetyDenialPolicy
            .shouldReportRendererNativeBridgeTeardownSafetyDenialPolicyBlocked ||
        (
            safetyDenialPolicy
                .didPrepareRendererNativeBridgeTeardownSafetyDenialPolicy &&
            proofReady == false
        )

    return CjguiInternalRendererMainThreadDestroyConfinementPolicy(
        safetyDenialPolicy,
        proofReady,
        proofDeferred,
        proofInconsistent,
        proofReady,
        proofReady,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererNativeBridgeTeardownFailureClassification(
    mainThreadDestroyConfinementPolicy:
        CjguiInternalRendererMainThreadDestroyConfinementPolicy
): CjguiInternalRendererNativeBridgeTeardownFailureClassification {
    let proofReady =
        mainThreadDestroyConfinementPolicy
            .didPrepareRendererMainThreadDestroyConfinementPolicy &&
        mainThreadDestroyConfinementPolicy
            .didPreserveRendererNativeBridgeTeardownSafetyDenialPolicy &&
        mainThreadDestroyConfinementPolicy
            .didDefineMainThreadDestroyConfinementPolicy &&
        mainThreadDestroyConfinementPolicy
            .didRequireMainThreadConfinementPlanning &&
        mainThreadDestroyConfinementPolicy.didConfirmNoMainThreadDispatch &&
        mainThreadDestroyConfinementPolicy
            .didConfirmNoAppKitMetalObjectiveCCall &&
        mainThreadDestroyConfinementPolicy
            .didKeepMainThreadDestroyConfinementPolicyDehydrated &&
        mainThreadDestroyConfinementPolicy.didAvoidThreadReadyWrapper &&
        mainThreadDestroyConfinementPolicy.didAvoidThinWrapper &&
        mainThreadDestroyConfinementPolicy
            .shouldDeferRendererMainThreadDestroyConfinementPolicy == false &&
        mainThreadDestroyConfinementPolicy
            .shouldReportRendererMainThreadDestroyConfinementPolicyBlocked ==
            false
    let proofDeferred =
        mainThreadDestroyConfinementPolicy
            .didPrepareRendererMainThreadDestroyConfinementPolicy == false &&
        mainThreadDestroyConfinementPolicy
            .shouldDeferRendererMainThreadDestroyConfinementPolicy &&
        mainThreadDestroyConfinementPolicy
            .shouldReportRendererMainThreadDestroyConfinementPolicyBlocked ==
            false
    let proofInconsistent =
        mainThreadDestroyConfinementPolicy
            .shouldReportRendererMainThreadDestroyConfinementPolicyBlocked ||
        (
            mainThreadDestroyConfinementPolicy
                .didPrepareRendererMainThreadDestroyConfinementPolicy &&
            proofReady == false
        )

    return CjguiInternalRendererNativeBridgeTeardownFailureClassification(
        mainThreadDestroyConfinementPolicy,
        proofReady,
        proofDeferred,
        proofInconsistent,
        proofReady,
        proofReady,
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

func cjguiInternalBuildRendererNoNativeBridgeTeardownImplementationReadiness(
    failureClassification:
        CjguiInternalRendererNativeBridgeTeardownFailureClassification
): CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness {
    let proofReady =
        failureClassification
            .didPrepareRendererNativeBridgeTeardownFailureClassification &&
        failureClassification
            .didPreserveRendererMainThreadDestroyConfinementPolicy &&
        failureClassification.didDefineTeardownFailureClassification &&
        failureClassification.didClassifyDoubleDestroy &&
        failureClassification.didClassifyDanglingToken &&
        failureClassification.didClassifyWrongThreadDestroy &&
        failureClassification.didClassifyBridgeOptimism &&
        failureClassification.didClassifyRollbackBlocked &&
        failureClassification
            .didKeepTeardownFailureClassificationDehydrated &&
        failureClassification.didAvoidDiagnosticsWrapper &&
        failureClassification.didAvoidThinWrapper &&
        failureClassification
            .shouldDeferRendererNativeBridgeTeardownFailureClassification ==
            false &&
        failureClassification
            .shouldReportRendererNativeBridgeTeardownFailureClassificationBlocked ==
            false
    let proofDeferred =
        failureClassification
            .didPrepareRendererNativeBridgeTeardownFailureClassification ==
            false &&
        failureClassification
            .shouldDeferRendererNativeBridgeTeardownFailureClassification &&
        failureClassification
            .shouldReportRendererNativeBridgeTeardownFailureClassificationBlocked ==
            false
    let proofInconsistent =
        failureClassification
            .shouldReportRendererNativeBridgeTeardownFailureClassificationBlocked ||
        (
            failureClassification
                .didPrepareRendererNativeBridgeTeardownFailureClassification &&
            proofReady == false
        )

    return CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness(
        failureClassification,
        proofReady,
        proofReady,
        proofDeferred,
        proofInconsistent,
        proofReady,
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

func cjguiInternalExecuteDefaultRendererNativeBridgeTeardownPlanDraft():
    CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness {
    let tokenReadiness =
        cjguiInternalExecuteDefaultRendererNativeHandleTokenDraft()
    let intent =
        cjguiInternalBuildRendererNativeBridgeTeardownPlanningIntent(
            tokenReadiness
        )
    let guard =
        cjguiInternalBuildRendererDestroyAdmissionGuardPolicy(intent)
    let invalidation =
        cjguiInternalBuildRendererTokenInvalidationBeforeDestroyPolicy(
            guard
        )
    let safety =
        cjguiInternalBuildRendererNativeBridgeTeardownSafetyDenialPolicy(
            invalidation
        )
    let confinement =
        cjguiInternalBuildRendererMainThreadDestroyConfinementPolicy(
            safety
        )
    let failureClassification =
        cjguiInternalBuildRendererNativeBridgeTeardownFailureClassification(
            confinement
        )

    return cjguiInternalBuildRendererNoNativeBridgeTeardownImplementationReadiness(
        failureClassification
    )
}
