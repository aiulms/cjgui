// Owner: native handle token ownership internal-only value boundary.
// Truth: 只消费 CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness，并记录
// native handle token ownership intent、opaque token admission policy、
// token ownership domain policy、token invalidation / revocation policy、
// double-release / dangling pointer denial policy 与
// no-native-handle-token readiness facts。
// Stop-line: 只产出 internal-only dehydrated facts；不创建 native handle
// / raw pointer，不返回 native pointer，不新增 production .h / .m，不实现
// C ABI / FFI，不触碰 Metal / AppKit / Objective-C，不写 renderer state，
// 不发布 public API。
// Same-shape Boundary Brake: 不得把本 value boundary 包成 native handle
// permission、native bridge implementation、C ABI implementation、Metal、
// backend-ready、GPU-submission、render、public API、receipt、record 或
// publication wrapper。
package cjgui

struct CjguiInternalRendererNativeHandleTokenOwnershipIntent {
    let noNativeBridgeCAbiSurfaceReadiness:
        CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness
    let didPrepareRendererNativeHandleTokenOwnershipIntent: Bool
    let shouldDeferRendererNativeHandleTokenOwnershipIntent: Bool
    let shouldReportRendererNativeHandleTokenOwnershipIntentBlocked: Bool
    let didPreserveRendererNoNativeBridgeCAbiSurfaceReadiness: Bool
    let didDefineFutureNativeHandleTokenOwnershipIntent: Bool
    let didRequireOpaqueTokenInsteadOfRawPointer: Bool
    let didKeepTokenBridgeLocalIdentifier: Bool
    let didKeepTokenOutOfPublicApi: Bool
    let didKeepNativeHandleTokenOwnershipIntentDehydrated: Bool
    let didAvoidNativeHandlePermissionWrapper: Bool
    let didAvoidCAbiImplementationWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        noNativeBridgeCAbiSurfaceReadiness:
            CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness,
        didPrepareRendererNativeHandleTokenOwnershipIntent: Bool,
        shouldDeferRendererNativeHandleTokenOwnershipIntent: Bool,
        shouldReportRendererNativeHandleTokenOwnershipIntentBlocked: Bool,
        didPreserveRendererNoNativeBridgeCAbiSurfaceReadiness: Bool,
        didDefineFutureNativeHandleTokenOwnershipIntent: Bool,
        didRequireOpaqueTokenInsteadOfRawPointer: Bool,
        didKeepTokenBridgeLocalIdentifier: Bool,
        didKeepTokenOutOfPublicApi: Bool,
        didKeepNativeHandleTokenOwnershipIntentDehydrated: Bool,
        didAvoidNativeHandlePermissionWrapper: Bool,
        didAvoidCAbiImplementationWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noNativeBridgeCAbiSurfaceReadiness =
            noNativeBridgeCAbiSurfaceReadiness
        this.didPrepareRendererNativeHandleTokenOwnershipIntent =
            didPrepareRendererNativeHandleTokenOwnershipIntent
        this.shouldDeferRendererNativeHandleTokenOwnershipIntent =
            shouldDeferRendererNativeHandleTokenOwnershipIntent
        this
            .shouldReportRendererNativeHandleTokenOwnershipIntentBlocked =
            shouldReportRendererNativeHandleTokenOwnershipIntentBlocked
        this.didPreserveRendererNoNativeBridgeCAbiSurfaceReadiness =
            didPreserveRendererNoNativeBridgeCAbiSurfaceReadiness
        this.didDefineFutureNativeHandleTokenOwnershipIntent =
            didDefineFutureNativeHandleTokenOwnershipIntent
        this.didRequireOpaqueTokenInsteadOfRawPointer =
            didRequireOpaqueTokenInsteadOfRawPointer
        this.didKeepTokenBridgeLocalIdentifier =
            didKeepTokenBridgeLocalIdentifier
        this.didKeepTokenOutOfPublicApi = didKeepTokenOutOfPublicApi
        this.didKeepNativeHandleTokenOwnershipIntentDehydrated =
            didKeepNativeHandleTokenOwnershipIntentDehydrated
        this.didAvoidNativeHandlePermissionWrapper =
            didAvoidNativeHandlePermissionWrapper
        this.didAvoidCAbiImplementationWrapper =
            didAvoidCAbiImplementationWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererOpaqueTokenAdmissionPolicy {
    let ownershipIntent:
        CjguiInternalRendererNativeHandleTokenOwnershipIntent
    let didPrepareRendererOpaqueTokenAdmissionPolicy: Bool
    let shouldDeferRendererOpaqueTokenAdmissionPolicy: Bool
    let shouldReportRendererOpaqueTokenAdmissionPolicyBlocked: Bool
    let didPreserveRendererNativeHandleTokenOwnershipIntent: Bool
    let didDefineOwnerLocalOpaqueTokenAdmissionPolicy: Bool
    let didAdmitTokenAllocationPlanningOnly: Bool
    let didConfirmNoRuntimeNativeHandleAllocation: Bool
    let didConfirmNoRawPointerReturn: Bool
    let didConfirmNoCAbiOrFfiSurfaceImplementation: Bool
    let didKeepOpaqueTokenAdmissionPolicyDehydrated: Bool
    let didAvoidNativePointerWrapper: Bool
    let didAvoidPublicApiWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        ownershipIntent:
            CjguiInternalRendererNativeHandleTokenOwnershipIntent,
        didPrepareRendererOpaqueTokenAdmissionPolicy: Bool,
        shouldDeferRendererOpaqueTokenAdmissionPolicy: Bool,
        shouldReportRendererOpaqueTokenAdmissionPolicyBlocked: Bool,
        didPreserveRendererNativeHandleTokenOwnershipIntent: Bool,
        didDefineOwnerLocalOpaqueTokenAdmissionPolicy: Bool,
        didAdmitTokenAllocationPlanningOnly: Bool,
        didConfirmNoRuntimeNativeHandleAllocation: Bool,
        didConfirmNoRawPointerReturn: Bool,
        didConfirmNoCAbiOrFfiSurfaceImplementation: Bool,
        didKeepOpaqueTokenAdmissionPolicyDehydrated: Bool,
        didAvoidNativePointerWrapper: Bool,
        didAvoidPublicApiWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.ownershipIntent = ownershipIntent
        this.didPrepareRendererOpaqueTokenAdmissionPolicy =
            didPrepareRendererOpaqueTokenAdmissionPolicy
        this.shouldDeferRendererOpaqueTokenAdmissionPolicy =
            shouldDeferRendererOpaqueTokenAdmissionPolicy
        this.shouldReportRendererOpaqueTokenAdmissionPolicyBlocked =
            shouldReportRendererOpaqueTokenAdmissionPolicyBlocked
        this.didPreserveRendererNativeHandleTokenOwnershipIntent =
            didPreserveRendererNativeHandleTokenOwnershipIntent
        this.didDefineOwnerLocalOpaqueTokenAdmissionPolicy =
            didDefineOwnerLocalOpaqueTokenAdmissionPolicy
        this.didAdmitTokenAllocationPlanningOnly =
            didAdmitTokenAllocationPlanningOnly
        this.didConfirmNoRuntimeNativeHandleAllocation =
            didConfirmNoRuntimeNativeHandleAllocation
        this.didConfirmNoRawPointerReturn = didConfirmNoRawPointerReturn
        this.didConfirmNoCAbiOrFfiSurfaceImplementation =
            didConfirmNoCAbiOrFfiSurfaceImplementation
        this.didKeepOpaqueTokenAdmissionPolicyDehydrated =
            didKeepOpaqueTokenAdmissionPolicyDehydrated
        this.didAvoidNativePointerWrapper = didAvoidNativePointerWrapper
        this.didAvoidPublicApiWrapper = didAvoidPublicApiWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererTokenOwnershipDomainPolicy {
    let tokenAdmissionPolicy:
        CjguiInternalRendererOpaqueTokenAdmissionPolicy
    let didPrepareRendererTokenOwnershipDomainPolicy: Bool
    let shouldDeferRendererTokenOwnershipDomainPolicy: Bool
    let shouldReportRendererTokenOwnershipDomainPolicyBlocked: Bool
    let didPreserveRendererOpaqueTokenAdmissionPolicy: Bool
    let didDefineBridgeLocalTokenOwnershipDomainPolicy: Bool
    let didRequireOwnerLocalTokenIdentity: Bool
    let didSeparateTokenFromNativePointerIdentity: Bool
    let didConfirmNoObjectiveCTruthSource: Bool
    let didConfirmNoCrossPublicApiLeak: Bool
    let didKeepTokenOwnershipDomainPolicyDehydrated: Bool
    let didAvoidBridgeReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        tokenAdmissionPolicy:
            CjguiInternalRendererOpaqueTokenAdmissionPolicy,
        didPrepareRendererTokenOwnershipDomainPolicy: Bool,
        shouldDeferRendererTokenOwnershipDomainPolicy: Bool,
        shouldReportRendererTokenOwnershipDomainPolicyBlocked: Bool,
        didPreserveRendererOpaqueTokenAdmissionPolicy: Bool,
        didDefineBridgeLocalTokenOwnershipDomainPolicy: Bool,
        didRequireOwnerLocalTokenIdentity: Bool,
        didSeparateTokenFromNativePointerIdentity: Bool,
        didConfirmNoObjectiveCTruthSource: Bool,
        didConfirmNoCrossPublicApiLeak: Bool,
        didKeepTokenOwnershipDomainPolicyDehydrated: Bool,
        didAvoidBridgeReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.tokenAdmissionPolicy = tokenAdmissionPolicy
        this.didPrepareRendererTokenOwnershipDomainPolicy =
            didPrepareRendererTokenOwnershipDomainPolicy
        this.shouldDeferRendererTokenOwnershipDomainPolicy =
            shouldDeferRendererTokenOwnershipDomainPolicy
        this.shouldReportRendererTokenOwnershipDomainPolicyBlocked =
            shouldReportRendererTokenOwnershipDomainPolicyBlocked
        this.didPreserveRendererOpaqueTokenAdmissionPolicy =
            didPreserveRendererOpaqueTokenAdmissionPolicy
        this.didDefineBridgeLocalTokenOwnershipDomainPolicy =
            didDefineBridgeLocalTokenOwnershipDomainPolicy
        this.didRequireOwnerLocalTokenIdentity =
            didRequireOwnerLocalTokenIdentity
        this.didSeparateTokenFromNativePointerIdentity =
            didSeparateTokenFromNativePointerIdentity
        this.didConfirmNoObjectiveCTruthSource =
            didConfirmNoObjectiveCTruthSource
        this.didConfirmNoCrossPublicApiLeak =
            didConfirmNoCrossPublicApiLeak
        this.didKeepTokenOwnershipDomainPolicyDehydrated =
            didKeepTokenOwnershipDomainPolicyDehydrated
        this.didAvoidBridgeReadyWrapper = didAvoidBridgeReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererTokenInvalidationRevocationPolicy {
    let ownershipDomainPolicy:
        CjguiInternalRendererTokenOwnershipDomainPolicy
    let didPrepareRendererTokenInvalidationRevocationPolicy: Bool
    let shouldDeferRendererTokenInvalidationRevocationPolicy: Bool
    let shouldReportRendererTokenInvalidationRevocationPolicyBlocked: Bool
    let didPreserveRendererTokenOwnershipDomainPolicy: Bool
    let didDefineTokenInvalidationPolicy: Bool
    let didDefineTokenRevocationPolicy: Bool
    let didConfirmNoDestroyImplementation: Bool
    let didConfirmNoRetainReleaseImplementation: Bool
    let didConfirmNoNativeLifecycleCall: Bool
    let didConfirmMainThreadConfinementPlanning: Bool
    let didKeepTokenInvalidationRevocationPolicyDehydrated: Bool
    let didAvoidNativeLifecyclePermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        ownershipDomainPolicy:
            CjguiInternalRendererTokenOwnershipDomainPolicy,
        didPrepareRendererTokenInvalidationRevocationPolicy: Bool,
        shouldDeferRendererTokenInvalidationRevocationPolicy: Bool,
        shouldReportRendererTokenInvalidationRevocationPolicyBlocked: Bool,
        didPreserveRendererTokenOwnershipDomainPolicy: Bool,
        didDefineTokenInvalidationPolicy: Bool,
        didDefineTokenRevocationPolicy: Bool,
        didConfirmNoDestroyImplementation: Bool,
        didConfirmNoRetainReleaseImplementation: Bool,
        didConfirmNoNativeLifecycleCall: Bool,
        didConfirmMainThreadConfinementPlanning: Bool,
        didKeepTokenInvalidationRevocationPolicyDehydrated: Bool,
        didAvoidNativeLifecyclePermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.ownershipDomainPolicy = ownershipDomainPolicy
        this.didPrepareRendererTokenInvalidationRevocationPolicy =
            didPrepareRendererTokenInvalidationRevocationPolicy
        this.shouldDeferRendererTokenInvalidationRevocationPolicy =
            shouldDeferRendererTokenInvalidationRevocationPolicy
        this
            .shouldReportRendererTokenInvalidationRevocationPolicyBlocked =
            shouldReportRendererTokenInvalidationRevocationPolicyBlocked
        this.didPreserveRendererTokenOwnershipDomainPolicy =
            didPreserveRendererTokenOwnershipDomainPolicy
        this.didDefineTokenInvalidationPolicy =
            didDefineTokenInvalidationPolicy
        this.didDefineTokenRevocationPolicy =
            didDefineTokenRevocationPolicy
        this.didConfirmNoDestroyImplementation =
            didConfirmNoDestroyImplementation
        this.didConfirmNoRetainReleaseImplementation =
            didConfirmNoRetainReleaseImplementation
        this.didConfirmNoNativeLifecycleCall =
            didConfirmNoNativeLifecycleCall
        this.didConfirmMainThreadConfinementPlanning =
            didConfirmMainThreadConfinementPlanning
        this.didKeepTokenInvalidationRevocationPolicyDehydrated =
            didKeepTokenInvalidationRevocationPolicyDehydrated
        this.didAvoidNativeLifecyclePermissionWrapper =
            didAvoidNativeLifecyclePermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererTokenSafetyDenialPolicy {
    let invalidationRevocationPolicy:
        CjguiInternalRendererTokenInvalidationRevocationPolicy
    let didPrepareRendererTokenSafetyDenialPolicy: Bool
    let shouldDeferRendererTokenSafetyDenialPolicy: Bool
    let shouldReportRendererTokenSafetyDenialPolicyBlocked: Bool
    let didPreserveRendererTokenInvalidationRevocationPolicy: Bool
    let didDefineDoubleReleaseDenialPolicy: Bool
    let didDefineDanglingPointerDenialPolicy: Bool
    let didConfirmFailClosedOnStaleToken: Bool
    let didConfirmFailClosedOnWrongThread: Bool
    let didConfirmDestroyContractCompatibilityPlanning: Bool
    let didKeepTokenSafetyDenialPolicyDehydrated: Bool
    let didAvoidTokenReadyWrapper: Bool
    let didAvoidNativeHandlePermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        invalidationRevocationPolicy:
            CjguiInternalRendererTokenInvalidationRevocationPolicy,
        didPrepareRendererTokenSafetyDenialPolicy: Bool,
        shouldDeferRendererTokenSafetyDenialPolicy: Bool,
        shouldReportRendererTokenSafetyDenialPolicyBlocked: Bool,
        didPreserveRendererTokenInvalidationRevocationPolicy: Bool,
        didDefineDoubleReleaseDenialPolicy: Bool,
        didDefineDanglingPointerDenialPolicy: Bool,
        didConfirmFailClosedOnStaleToken: Bool,
        didConfirmFailClosedOnWrongThread: Bool,
        didConfirmDestroyContractCompatibilityPlanning: Bool,
        didKeepTokenSafetyDenialPolicyDehydrated: Bool,
        didAvoidTokenReadyWrapper: Bool,
        didAvoidNativeHandlePermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.invalidationRevocationPolicy = invalidationRevocationPolicy
        this.didPrepareRendererTokenSafetyDenialPolicy =
            didPrepareRendererTokenSafetyDenialPolicy
        this.shouldDeferRendererTokenSafetyDenialPolicy =
            shouldDeferRendererTokenSafetyDenialPolicy
        this.shouldReportRendererTokenSafetyDenialPolicyBlocked =
            shouldReportRendererTokenSafetyDenialPolicyBlocked
        this.didPreserveRendererTokenInvalidationRevocationPolicy =
            didPreserveRendererTokenInvalidationRevocationPolicy
        this.didDefineDoubleReleaseDenialPolicy =
            didDefineDoubleReleaseDenialPolicy
        this.didDefineDanglingPointerDenialPolicy =
            didDefineDanglingPointerDenialPolicy
        this.didConfirmFailClosedOnStaleToken =
            didConfirmFailClosedOnStaleToken
        this.didConfirmFailClosedOnWrongThread =
            didConfirmFailClosedOnWrongThread
        this.didConfirmDestroyContractCompatibilityPlanning =
            didConfirmDestroyContractCompatibilityPlanning
        this.didKeepTokenSafetyDenialPolicyDehydrated =
            didKeepTokenSafetyDenialPolicyDehydrated
        this.didAvoidTokenReadyWrapper = didAvoidTokenReadyWrapper
        this.didAvoidNativeHandlePermissionWrapper =
            didAvoidNativeHandlePermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoNativeHandleTokenReadiness {
    let tokenSafetyDenialPolicy:
        CjguiInternalRendererTokenSafetyDenialPolicy
    let didPrepareRendererNoNativeHandleTokenReadiness: Bool
    let didConfirmRendererNoNativeHandleTokenReadiness: Bool
    let shouldDeferRendererNoNativeHandleTokenReadiness: Bool
    let shouldReportRendererNoNativeHandleTokenReadinessBlocked: Bool
    let didPreserveRendererTokenSafetyDenialPolicy: Bool
    let didConfirmNoNativeHandleCreation: Bool
    let didConfirmNoRawPointerCreationOrReturn: Bool
    let didConfirmNoProductionNativeFileCreation: Bool
    let didConfirmNoSmokeNativeFileModification: Bool
    let didConfirmNoCAbiImplementation: Bool
    let didConfirmNoFfiDeclaration: Bool
    let didConfirmNoNativeBridgeModification: Bool
    let didConfirmNoMetalOrAppKitCall: Bool
    let didConfirmNoRetainReleaseDestroyCall: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didConfirmNoGpuSubmissionOrRender: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoPublicApiOrDiagnostics: Bool
    let didKeepNoNativeHandleTokenReadinessDehydrated: Bool
    let didAvoidPermissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        tokenSafetyDenialPolicy:
            CjguiInternalRendererTokenSafetyDenialPolicy,
        didPrepareRendererNoNativeHandleTokenReadiness: Bool,
        didConfirmRendererNoNativeHandleTokenReadiness: Bool,
        shouldDeferRendererNoNativeHandleTokenReadiness: Bool,
        shouldReportRendererNoNativeHandleTokenReadinessBlocked: Bool,
        didPreserveRendererTokenSafetyDenialPolicy: Bool,
        didConfirmNoNativeHandleCreation: Bool,
        didConfirmNoRawPointerCreationOrReturn: Bool,
        didConfirmNoProductionNativeFileCreation: Bool,
        didConfirmNoSmokeNativeFileModification: Bool,
        didConfirmNoCAbiImplementation: Bool,
        didConfirmNoFfiDeclaration: Bool,
        didConfirmNoNativeBridgeModification: Bool,
        didConfirmNoMetalOrAppKitCall: Bool,
        didConfirmNoRetainReleaseDestroyCall: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didConfirmNoGpuSubmissionOrRender: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoPublicApiOrDiagnostics: Bool,
        didKeepNoNativeHandleTokenReadinessDehydrated: Bool,
        didAvoidPermissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.tokenSafetyDenialPolicy = tokenSafetyDenialPolicy
        this.didPrepareRendererNoNativeHandleTokenReadiness =
            didPrepareRendererNoNativeHandleTokenReadiness
        this.didConfirmRendererNoNativeHandleTokenReadiness =
            didConfirmRendererNoNativeHandleTokenReadiness
        this.shouldDeferRendererNoNativeHandleTokenReadiness =
            shouldDeferRendererNoNativeHandleTokenReadiness
        this.shouldReportRendererNoNativeHandleTokenReadinessBlocked =
            shouldReportRendererNoNativeHandleTokenReadinessBlocked
        this.didPreserveRendererTokenSafetyDenialPolicy =
            didPreserveRendererTokenSafetyDenialPolicy
        this.didConfirmNoNativeHandleCreation =
            didConfirmNoNativeHandleCreation
        this.didConfirmNoRawPointerCreationOrReturn =
            didConfirmNoRawPointerCreationOrReturn
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
        this.didConfirmNoRetainReleaseDestroyCall =
            didConfirmNoRetainReleaseDestroyCall
        this.didConfirmNoBackendReadyTruth =
            didConfirmNoBackendReadyTruth
        this.didConfirmNoGpuSubmissionOrRender =
            didConfirmNoGpuSubmissionOrRender
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoPublicApiOrDiagnostics =
            didConfirmNoPublicApiOrDiagnostics
        this.didKeepNoNativeHandleTokenReadinessDehydrated =
            didKeepNoNativeHandleTokenReadinessDehydrated
        this.didAvoidPermissionWrapper = didAvoidPermissionWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererNativeHandleTokenOwnershipIntent(
    noNativeBridgeCAbiSurfaceReadiness:
        CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness
): CjguiInternalRendererNativeHandleTokenOwnershipIntent {
    let upstreamReady =
        noNativeBridgeCAbiSurfaceReadiness
            .didConfirmRendererNoNativeBridgeCAbiSurfaceReadiness &&
        noNativeBridgeCAbiSurfaceReadiness
            .shouldDeferRendererNoNativeBridgeCAbiSurfaceReadiness == false &&
        noNativeBridgeCAbiSurfaceReadiness
            .shouldReportRendererNoNativeBridgeCAbiSurfaceReadinessBlocked ==
            false
    let upstreamDeferred =
        noNativeBridgeCAbiSurfaceReadiness
            .shouldDeferRendererNoNativeBridgeCAbiSurfaceReadiness &&
        noNativeBridgeCAbiSurfaceReadiness
            .shouldReportRendererNoNativeBridgeCAbiSurfaceReadinessBlocked ==
            false
    let upstreamInconsistent =
        noNativeBridgeCAbiSurfaceReadiness
            .shouldReportRendererNoNativeBridgeCAbiSurfaceReadinessBlocked ||
        (
            noNativeBridgeCAbiSurfaceReadiness
                .didPrepareRendererNoNativeBridgeCAbiSurfaceReadiness &&
            upstreamReady == false &&
            upstreamDeferred == false
        )

    return CjguiInternalRendererNativeHandleTokenOwnershipIntent(
        noNativeBridgeCAbiSurfaceReadiness,
        upstreamReady,
        upstreamDeferred,
        upstreamInconsistent,
        upstreamReady,
        upstreamReady,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererOpaqueTokenAdmissionPolicy(
    ownershipIntent:
        CjguiInternalRendererNativeHandleTokenOwnershipIntent
): CjguiInternalRendererOpaqueTokenAdmissionPolicy {
    let proofReady =
        ownershipIntent
            .didPrepareRendererNativeHandleTokenOwnershipIntent &&
        ownershipIntent
            .didPreserveRendererNoNativeBridgeCAbiSurfaceReadiness &&
        ownershipIntent.didDefineFutureNativeHandleTokenOwnershipIntent &&
        ownershipIntent.didRequireOpaqueTokenInsteadOfRawPointer &&
        ownershipIntent.didKeepTokenBridgeLocalIdentifier &&
        ownershipIntent.didKeepTokenOutOfPublicApi &&
        ownershipIntent
            .didKeepNativeHandleTokenOwnershipIntentDehydrated &&
        ownershipIntent.didAvoidNativeHandlePermissionWrapper &&
        ownershipIntent.didAvoidCAbiImplementationWrapper &&
        ownershipIntent.didAvoidThinWrapper &&
        ownershipIntent
            .shouldDeferRendererNativeHandleTokenOwnershipIntent == false &&
        ownershipIntent
            .shouldReportRendererNativeHandleTokenOwnershipIntentBlocked ==
            false
    let proofDeferred =
        ownershipIntent
            .didPrepareRendererNativeHandleTokenOwnershipIntent == false &&
        ownershipIntent
            .shouldDeferRendererNativeHandleTokenOwnershipIntent &&
        ownershipIntent
            .shouldReportRendererNativeHandleTokenOwnershipIntentBlocked ==
            false
    let proofInconsistent =
        ownershipIntent
            .shouldReportRendererNativeHandleTokenOwnershipIntentBlocked ||
        (
            ownershipIntent
                .didPrepareRendererNativeHandleTokenOwnershipIntent &&
            proofReady == false
        )

    return CjguiInternalRendererOpaqueTokenAdmissionPolicy(
        ownershipIntent,
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

func cjguiInternalBuildRendererTokenOwnershipDomainPolicy(
    tokenAdmissionPolicy:
        CjguiInternalRendererOpaqueTokenAdmissionPolicy
): CjguiInternalRendererTokenOwnershipDomainPolicy {
    let proofReady =
        tokenAdmissionPolicy
            .didPrepareRendererOpaqueTokenAdmissionPolicy &&
        tokenAdmissionPolicy
            .didPreserveRendererNativeHandleTokenOwnershipIntent &&
        tokenAdmissionPolicy.didDefineOwnerLocalOpaqueTokenAdmissionPolicy &&
        tokenAdmissionPolicy.didAdmitTokenAllocationPlanningOnly &&
        tokenAdmissionPolicy.didConfirmNoRuntimeNativeHandleAllocation &&
        tokenAdmissionPolicy.didConfirmNoRawPointerReturn &&
        tokenAdmissionPolicy.didConfirmNoCAbiOrFfiSurfaceImplementation &&
        tokenAdmissionPolicy.didKeepOpaqueTokenAdmissionPolicyDehydrated &&
        tokenAdmissionPolicy.didAvoidNativePointerWrapper &&
        tokenAdmissionPolicy.didAvoidPublicApiWrapper &&
        tokenAdmissionPolicy.didAvoidThinWrapper &&
        tokenAdmissionPolicy
            .shouldDeferRendererOpaqueTokenAdmissionPolicy == false &&
        tokenAdmissionPolicy
            .shouldReportRendererOpaqueTokenAdmissionPolicyBlocked == false
    let proofDeferred =
        tokenAdmissionPolicy
            .didPrepareRendererOpaqueTokenAdmissionPolicy == false &&
        tokenAdmissionPolicy.shouldDeferRendererOpaqueTokenAdmissionPolicy &&
        tokenAdmissionPolicy
            .shouldReportRendererOpaqueTokenAdmissionPolicyBlocked == false
    let proofInconsistent =
        tokenAdmissionPolicy
            .shouldReportRendererOpaqueTokenAdmissionPolicyBlocked ||
        (
            tokenAdmissionPolicy.didPrepareRendererOpaqueTokenAdmissionPolicy &&
            proofReady == false
        )

    return CjguiInternalRendererTokenOwnershipDomainPolicy(
        tokenAdmissionPolicy,
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

func cjguiInternalBuildRendererTokenInvalidationRevocationPolicy(
    ownershipDomainPolicy:
        CjguiInternalRendererTokenOwnershipDomainPolicy
): CjguiInternalRendererTokenInvalidationRevocationPolicy {
    let proofReady =
        ownershipDomainPolicy
            .didPrepareRendererTokenOwnershipDomainPolicy &&
        ownershipDomainPolicy
            .didPreserveRendererOpaqueTokenAdmissionPolicy &&
        ownershipDomainPolicy.didDefineBridgeLocalTokenOwnershipDomainPolicy &&
        ownershipDomainPolicy.didRequireOwnerLocalTokenIdentity &&
        ownershipDomainPolicy.didSeparateTokenFromNativePointerIdentity &&
        ownershipDomainPolicy.didConfirmNoObjectiveCTruthSource &&
        ownershipDomainPolicy.didConfirmNoCrossPublicApiLeak &&
        ownershipDomainPolicy.didKeepTokenOwnershipDomainPolicyDehydrated &&
        ownershipDomainPolicy.didAvoidBridgeReadyWrapper &&
        ownershipDomainPolicy.didAvoidBackendReadyWrapper &&
        ownershipDomainPolicy.didAvoidThinWrapper &&
        ownershipDomainPolicy
            .shouldDeferRendererTokenOwnershipDomainPolicy == false &&
        ownershipDomainPolicy
            .shouldReportRendererTokenOwnershipDomainPolicyBlocked == false
    let proofDeferred =
        ownershipDomainPolicy
            .didPrepareRendererTokenOwnershipDomainPolicy == false &&
        ownershipDomainPolicy.shouldDeferRendererTokenOwnershipDomainPolicy &&
        ownershipDomainPolicy
            .shouldReportRendererTokenOwnershipDomainPolicyBlocked == false
    let proofInconsistent =
        ownershipDomainPolicy
            .shouldReportRendererTokenOwnershipDomainPolicyBlocked ||
        (
            ownershipDomainPolicy
                .didPrepareRendererTokenOwnershipDomainPolicy &&
            proofReady == false
        )

    return CjguiInternalRendererTokenInvalidationRevocationPolicy(
        ownershipDomainPolicy,
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

func cjguiInternalBuildRendererTokenSafetyDenialPolicy(
    invalidationRevocationPolicy:
        CjguiInternalRendererTokenInvalidationRevocationPolicy
): CjguiInternalRendererTokenSafetyDenialPolicy {
    let proofReady =
        invalidationRevocationPolicy
            .didPrepareRendererTokenInvalidationRevocationPolicy &&
        invalidationRevocationPolicy
            .didPreserveRendererTokenOwnershipDomainPolicy &&
        invalidationRevocationPolicy.didDefineTokenInvalidationPolicy &&
        invalidationRevocationPolicy.didDefineTokenRevocationPolicy &&
        invalidationRevocationPolicy.didConfirmNoDestroyImplementation &&
        invalidationRevocationPolicy.didConfirmNoRetainReleaseImplementation &&
        invalidationRevocationPolicy.didConfirmNoNativeLifecycleCall &&
        invalidationRevocationPolicy.didConfirmMainThreadConfinementPlanning &&
        invalidationRevocationPolicy
            .didKeepTokenInvalidationRevocationPolicyDehydrated &&
        invalidationRevocationPolicy
            .didAvoidNativeLifecyclePermissionWrapper &&
        invalidationRevocationPolicy.didAvoidThinWrapper &&
        invalidationRevocationPolicy
            .shouldDeferRendererTokenInvalidationRevocationPolicy == false &&
        invalidationRevocationPolicy
            .shouldReportRendererTokenInvalidationRevocationPolicyBlocked ==
            false
    let proofDeferred =
        invalidationRevocationPolicy
            .didPrepareRendererTokenInvalidationRevocationPolicy == false &&
        invalidationRevocationPolicy
            .shouldDeferRendererTokenInvalidationRevocationPolicy &&
        invalidationRevocationPolicy
            .shouldReportRendererTokenInvalidationRevocationPolicyBlocked ==
            false
    let proofInconsistent =
        invalidationRevocationPolicy
            .shouldReportRendererTokenInvalidationRevocationPolicyBlocked ||
        (
            invalidationRevocationPolicy
                .didPrepareRendererTokenInvalidationRevocationPolicy &&
            proofReady == false
        )

    return CjguiInternalRendererTokenSafetyDenialPolicy(
        invalidationRevocationPolicy,
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
        true
    )
}

func cjguiInternalBuildRendererNoNativeHandleTokenReadiness(
    tokenSafetyDenialPolicy:
        CjguiInternalRendererTokenSafetyDenialPolicy
): CjguiInternalRendererNoNativeHandleTokenReadiness {
    let proofReady =
        tokenSafetyDenialPolicy
            .didPrepareRendererTokenSafetyDenialPolicy &&
        tokenSafetyDenialPolicy
            .didPreserveRendererTokenInvalidationRevocationPolicy &&
        tokenSafetyDenialPolicy.didDefineDoubleReleaseDenialPolicy &&
        tokenSafetyDenialPolicy.didDefineDanglingPointerDenialPolicy &&
        tokenSafetyDenialPolicy.didConfirmFailClosedOnStaleToken &&
        tokenSafetyDenialPolicy.didConfirmFailClosedOnWrongThread &&
        tokenSafetyDenialPolicy
            .didConfirmDestroyContractCompatibilityPlanning &&
        tokenSafetyDenialPolicy.didKeepTokenSafetyDenialPolicyDehydrated &&
        tokenSafetyDenialPolicy.didAvoidTokenReadyWrapper &&
        tokenSafetyDenialPolicy.didAvoidNativeHandlePermissionWrapper &&
        tokenSafetyDenialPolicy.didAvoidThinWrapper &&
        tokenSafetyDenialPolicy
            .shouldDeferRendererTokenSafetyDenialPolicy == false &&
        tokenSafetyDenialPolicy
            .shouldReportRendererTokenSafetyDenialPolicyBlocked == false
    let proofDeferred =
        tokenSafetyDenialPolicy
            .didPrepareRendererTokenSafetyDenialPolicy == false &&
        tokenSafetyDenialPolicy.shouldDeferRendererTokenSafetyDenialPolicy &&
        tokenSafetyDenialPolicy
            .shouldReportRendererTokenSafetyDenialPolicyBlocked == false
    let proofInconsistent =
        tokenSafetyDenialPolicy
            .shouldReportRendererTokenSafetyDenialPolicyBlocked ||
        (
            tokenSafetyDenialPolicy
                .didPrepareRendererTokenSafetyDenialPolicy &&
            proofReady == false
        )

    return CjguiInternalRendererNoNativeHandleTokenReadiness(
        tokenSafetyDenialPolicy,
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

func cjguiInternalExecuteDefaultRendererNativeHandleTokenDraft():
    CjguiInternalRendererNoNativeHandleTokenReadiness {
    let noNativeBridgeCAbiSurfaceReadiness =
        cjguiInternalExecuteDefaultRendererNativeBridgeCAbiSurfaceDraft()
    let ownershipIntent =
        cjguiInternalBuildRendererNativeHandleTokenOwnershipIntent(
            noNativeBridgeCAbiSurfaceReadiness
        )
    let tokenAdmissionPolicy =
        cjguiInternalBuildRendererOpaqueTokenAdmissionPolicy(
            ownershipIntent
        )
    let ownershipDomainPolicy =
        cjguiInternalBuildRendererTokenOwnershipDomainPolicy(
            tokenAdmissionPolicy
        )
    let invalidationRevocationPolicy =
        cjguiInternalBuildRendererTokenInvalidationRevocationPolicy(
            ownershipDomainPolicy
        )
    let tokenSafetyDenialPolicy =
        cjguiInternalBuildRendererTokenSafetyDenialPolicy(
            invalidationRevocationPolicy
        )
    return cjguiInternalBuildRendererNoNativeHandleTokenReadiness(
        tokenSafetyDenialPolicy
    )
}
