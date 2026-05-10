// Owner: platform object native callable admission value boundary。
// Truth: 只消费 CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness，
// 固定 platform object native callable intent、no-object admission policy、
// main-thread prerequisite、token issue/revoke prerequisite、
// no-token-return-before-object policy 与 no-platform-object-native-callable facts。
// Stop-line: 不新增 platform object native C ABI，不创建 NSWindow / NSView /
// CAMetalLayer，不返回 token / handle / pointer，不改 runtime_state.cj，不把
// admission 解释成 platform object exists 或 backend-ready truth。
// Same-shape Boundary Brake: 不得把本 owner 包成 platform object creation
// permission、native object permission、AppKit/Metal、native handle、public API、
// receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererPlatformObjectNativeCallableIntent {
    let tokenIssueRevokeReadiness:
        CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness
    let didPrepareRendererPlatformObjectNativeCallableIntent: Bool
    let shouldDeferRendererPlatformObjectNativeCallableIntent: Bool
    let shouldReportRendererPlatformObjectNativeCallableIntentBlocked: Bool
    let didPreserveRendererNativeTokenTableIssueRevokeReadiness: Bool
    let didDefinePlatformObjectNativeCallableIntent: Bool
    let didRequireNoObjectAdmissionFirst: Bool
    let didKeepPlatformObjectNativeCallableInternalOnly: Bool
    let didAvoidPlatformObjectCreationWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        tokenIssueRevokeReadiness:
            CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness,
        didPrepareRendererPlatformObjectNativeCallableIntent: Bool,
        shouldDeferRendererPlatformObjectNativeCallableIntent: Bool,
        shouldReportRendererPlatformObjectNativeCallableIntentBlocked: Bool,
        didPreserveRendererNativeTokenTableIssueRevokeReadiness: Bool,
        didDefinePlatformObjectNativeCallableIntent: Bool,
        didRequireNoObjectAdmissionFirst: Bool,
        didKeepPlatformObjectNativeCallableInternalOnly: Bool,
        didAvoidPlatformObjectCreationWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.tokenIssueRevokeReadiness = tokenIssueRevokeReadiness
        this.didPrepareRendererPlatformObjectNativeCallableIntent =
            didPrepareRendererPlatformObjectNativeCallableIntent
        this.shouldDeferRendererPlatformObjectNativeCallableIntent =
            shouldDeferRendererPlatformObjectNativeCallableIntent
        this.shouldReportRendererPlatformObjectNativeCallableIntentBlocked =
            shouldReportRendererPlatformObjectNativeCallableIntentBlocked
        this.didPreserveRendererNativeTokenTableIssueRevokeReadiness =
            didPreserveRendererNativeTokenTableIssueRevokeReadiness
        this.didDefinePlatformObjectNativeCallableIntent =
            didDefinePlatformObjectNativeCallableIntent
        this.didRequireNoObjectAdmissionFirst =
            didRequireNoObjectAdmissionFirst
        this.didKeepPlatformObjectNativeCallableInternalOnly =
            didKeepPlatformObjectNativeCallableInternalOnly
        this.didAvoidPlatformObjectCreationWrapper =
            didAvoidPlatformObjectCreationWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererPlatformObjectNoObjectAdmissionPolicy {
    let platformObjectNativeCallableIntent:
        CjguiInternalRendererPlatformObjectNativeCallableIntent
    let didPrepareRendererPlatformObjectNoObjectAdmissionPolicy: Bool
    let shouldDeferRendererPlatformObjectNoObjectAdmissionPolicy: Bool
    let shouldReportRendererPlatformObjectNoObjectAdmissionPolicyBlocked:
        Bool
    let didPreserveRendererPlatformObjectNativeCallableIntent: Bool
    let didConfirmNoObjectAdmissionOnly: Bool
    let didForbidNSWindowCreation: Bool
    let didForbidNSViewCreation: Bool
    let didForbidCAMetalLayerCreation: Bool
    let didForbidMetalDeviceOrQueueCreation: Bool
    let didForbidCocoaAppKitMetalQuartzCoreImport: Bool
    let didForbidNativePointerHandleReturn: Bool
    let didKeepAdmissionStatusOnly: Bool
    let didAvoidThinWrapper: Bool

    init(
        platformObjectNativeCallableIntent:
            CjguiInternalRendererPlatformObjectNativeCallableIntent,
        didPrepareRendererPlatformObjectNoObjectAdmissionPolicy: Bool,
        shouldDeferRendererPlatformObjectNoObjectAdmissionPolicy: Bool,
        shouldReportRendererPlatformObjectNoObjectAdmissionPolicyBlocked:
            Bool,
        didPreserveRendererPlatformObjectNativeCallableIntent: Bool,
        didConfirmNoObjectAdmissionOnly: Bool,
        didForbidNSWindowCreation: Bool,
        didForbidNSViewCreation: Bool,
        didForbidCAMetalLayerCreation: Bool,
        didForbidMetalDeviceOrQueueCreation: Bool,
        didForbidCocoaAppKitMetalQuartzCoreImport: Bool,
        didForbidNativePointerHandleReturn: Bool,
        didKeepAdmissionStatusOnly: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.platformObjectNativeCallableIntent =
            platformObjectNativeCallableIntent
        this.didPrepareRendererPlatformObjectNoObjectAdmissionPolicy =
            didPrepareRendererPlatformObjectNoObjectAdmissionPolicy
        this.shouldDeferRendererPlatformObjectNoObjectAdmissionPolicy =
            shouldDeferRendererPlatformObjectNoObjectAdmissionPolicy
        this
            .shouldReportRendererPlatformObjectNoObjectAdmissionPolicyBlocked =
            shouldReportRendererPlatformObjectNoObjectAdmissionPolicyBlocked
        this.didPreserveRendererPlatformObjectNativeCallableIntent =
            didPreserveRendererPlatformObjectNativeCallableIntent
        this.didConfirmNoObjectAdmissionOnly =
            didConfirmNoObjectAdmissionOnly
        this.didForbidNSWindowCreation = didForbidNSWindowCreation
        this.didForbidNSViewCreation = didForbidNSViewCreation
        this.didForbidCAMetalLayerCreation = didForbidCAMetalLayerCreation
        this.didForbidMetalDeviceOrQueueCreation =
            didForbidMetalDeviceOrQueueCreation
        this.didForbidCocoaAppKitMetalQuartzCoreImport =
            didForbidCocoaAppKitMetalQuartzCoreImport
        this.didForbidNativePointerHandleReturn =
            didForbidNativePointerHandleReturn
        this.didKeepAdmissionStatusOnly = didKeepAdmissionStatusOnly
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererPlatformObjectPrerequisitePolicy {
    let noObjectAdmissionPolicy:
        CjguiInternalRendererPlatformObjectNoObjectAdmissionPolicy
    let didPrepareRendererPlatformObjectPrerequisitePolicy: Bool
    let shouldDeferRendererPlatformObjectPrerequisitePolicy: Bool
    let shouldReportRendererPlatformObjectPrerequisitePolicyBlocked: Bool
    let didPreserveRendererPlatformObjectNoObjectAdmissionPolicy: Bool
    let didRequireMainThreadGateBeforePlatformObjectCallable: Bool
    let didRequireTokenIssueRevokeFactsBeforePlatformObjectCallable: Bool
    let didRequireTeardownCallablePolicyBeforeObjectCreation: Bool
    let didRequireNoTokenReturnBeforeObjectCreation: Bool
    let didRequireFailClosedAdmissionPath: Bool
    let didKeepPrerequisitePolicyDehydrated: Bool
    let didAvoidThinWrapper: Bool

    init(
        noObjectAdmissionPolicy:
            CjguiInternalRendererPlatformObjectNoObjectAdmissionPolicy,
        didPrepareRendererPlatformObjectPrerequisitePolicy: Bool,
        shouldDeferRendererPlatformObjectPrerequisitePolicy: Bool,
        shouldReportRendererPlatformObjectPrerequisitePolicyBlocked: Bool,
        didPreserveRendererPlatformObjectNoObjectAdmissionPolicy: Bool,
        didRequireMainThreadGateBeforePlatformObjectCallable: Bool,
        didRequireTokenIssueRevokeFactsBeforePlatformObjectCallable: Bool,
        didRequireTeardownCallablePolicyBeforeObjectCreation: Bool,
        didRequireNoTokenReturnBeforeObjectCreation: Bool,
        didRequireFailClosedAdmissionPath: Bool,
        didKeepPrerequisitePolicyDehydrated: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noObjectAdmissionPolicy = noObjectAdmissionPolicy
        this.didPrepareRendererPlatformObjectPrerequisitePolicy =
            didPrepareRendererPlatformObjectPrerequisitePolicy
        this.shouldDeferRendererPlatformObjectPrerequisitePolicy =
            shouldDeferRendererPlatformObjectPrerequisitePolicy
        this.shouldReportRendererPlatformObjectPrerequisitePolicyBlocked =
            shouldReportRendererPlatformObjectPrerequisitePolicyBlocked
        this.didPreserveRendererPlatformObjectNoObjectAdmissionPolicy =
            didPreserveRendererPlatformObjectNoObjectAdmissionPolicy
        this.didRequireMainThreadGateBeforePlatformObjectCallable =
            didRequireMainThreadGateBeforePlatformObjectCallable
        this
            .didRequireTokenIssueRevokeFactsBeforePlatformObjectCallable =
            didRequireTokenIssueRevokeFactsBeforePlatformObjectCallable
        this.didRequireTeardownCallablePolicyBeforeObjectCreation =
            didRequireTeardownCallablePolicyBeforeObjectCreation
        this.didRequireNoTokenReturnBeforeObjectCreation =
            didRequireNoTokenReturnBeforeObjectCreation
        this.didRequireFailClosedAdmissionPath =
            didRequireFailClosedAdmissionPath
        this.didKeepPrerequisitePolicyDehydrated =
            didKeepPrerequisitePolicyDehydrated
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoPlatformObjectNativeCallableReadiness {
    let platformObjectNativeCallableIntent:
        CjguiInternalRendererPlatformObjectNativeCallableIntent
    let noObjectAdmissionPolicy:
        CjguiInternalRendererPlatformObjectNoObjectAdmissionPolicy
    let prerequisitePolicy:
        CjguiInternalRendererPlatformObjectPrerequisitePolicy
    let didPrepareRendererNoPlatformObjectNativeCallableReadiness: Bool
    let shouldDeferRendererNoPlatformObjectNativeCallableReadiness: Bool
    let shouldReportRendererNoPlatformObjectNativeCallableReadinessBlocked:
        Bool
    let didPreserveRendererPlatformObjectNativeCallableIntent: Bool
    let didPreserveRendererPlatformObjectNoObjectAdmissionPolicy: Bool
    let didPreserveRendererPlatformObjectPrerequisitePolicy: Bool
    let didConfirmNoObjectAdmissionPolicy: Bool
    let didConfirmMainThreadPrerequisite: Bool
    let didConfirmTokenIssueRevokePrerequisite: Bool
    let didConfirmTeardownPolicyPrerequisite: Bool
    let didConfirmNoTokenReturnBeforeObjectPolicy: Bool
    let didConfirmNoNativeCallableImplementation: Bool
    let didConfirmNoPlatformObjectCreation: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoResourceCallable: Bool
    let didConfirmNoNativeObjectHandleOrPointer: Bool
    let didConfirmNoCocoaAppKitMetalQuartzCoreUsage: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoPlatformObjectNativeCallableReadinessDehydrated: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        platformObjectNativeCallableIntent:
            CjguiInternalRendererPlatformObjectNativeCallableIntent,
        noObjectAdmissionPolicy:
            CjguiInternalRendererPlatformObjectNoObjectAdmissionPolicy,
        prerequisitePolicy:
            CjguiInternalRendererPlatformObjectPrerequisitePolicy,
        didPrepareRendererNoPlatformObjectNativeCallableReadiness: Bool,
        shouldDeferRendererNoPlatformObjectNativeCallableReadiness: Bool,
        shouldReportRendererNoPlatformObjectNativeCallableReadinessBlocked:
            Bool,
        didPreserveRendererPlatformObjectNativeCallableIntent: Bool,
        didPreserveRendererPlatformObjectNoObjectAdmissionPolicy: Bool,
        didPreserveRendererPlatformObjectPrerequisitePolicy: Bool,
        didConfirmNoObjectAdmissionPolicy: Bool,
        didConfirmMainThreadPrerequisite: Bool,
        didConfirmTokenIssueRevokePrerequisite: Bool,
        didConfirmTeardownPolicyPrerequisite: Bool,
        didConfirmNoTokenReturnBeforeObjectPolicy: Bool,
        didConfirmNoNativeCallableImplementation: Bool,
        didConfirmNoPlatformObjectCreation: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoResourceCallable: Bool,
        didConfirmNoNativeObjectHandleOrPointer: Bool,
        didConfirmNoCocoaAppKitMetalQuartzCoreUsage: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoPlatformObjectNativeCallableReadinessDehydrated: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.platformObjectNativeCallableIntent =
            platformObjectNativeCallableIntent
        this.noObjectAdmissionPolicy = noObjectAdmissionPolicy
        this.prerequisitePolicy = prerequisitePolicy
        this.didPrepareRendererNoPlatformObjectNativeCallableReadiness =
            didPrepareRendererNoPlatformObjectNativeCallableReadiness
        this.shouldDeferRendererNoPlatformObjectNativeCallableReadiness =
            shouldDeferRendererNoPlatformObjectNativeCallableReadiness
        this
            .shouldReportRendererNoPlatformObjectNativeCallableReadinessBlocked =
            shouldReportRendererNoPlatformObjectNativeCallableReadinessBlocked
        this.didPreserveRendererPlatformObjectNativeCallableIntent =
            didPreserveRendererPlatformObjectNativeCallableIntent
        this.didPreserveRendererPlatformObjectNoObjectAdmissionPolicy =
            didPreserveRendererPlatformObjectNoObjectAdmissionPolicy
        this.didPreserveRendererPlatformObjectPrerequisitePolicy =
            didPreserveRendererPlatformObjectPrerequisitePolicy
        this.didConfirmNoObjectAdmissionPolicy =
            didConfirmNoObjectAdmissionPolicy
        this.didConfirmMainThreadPrerequisite =
            didConfirmMainThreadPrerequisite
        this.didConfirmTokenIssueRevokePrerequisite =
            didConfirmTokenIssueRevokePrerequisite
        this.didConfirmTeardownPolicyPrerequisite =
            didConfirmTeardownPolicyPrerequisite
        this.didConfirmNoTokenReturnBeforeObjectPolicy =
            didConfirmNoTokenReturnBeforeObjectPolicy
        this.didConfirmNoNativeCallableImplementation =
            didConfirmNoNativeCallableImplementation
        this.didConfirmNoPlatformObjectCreation =
            didConfirmNoPlatformObjectCreation
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoResourceCallable = didConfirmNoResourceCallable
        this.didConfirmNoNativeObjectHandleOrPointer =
            didConfirmNoNativeObjectHandleOrPointer
        this.didConfirmNoCocoaAppKitMetalQuartzCoreUsage =
            didConfirmNoCocoaAppKitMetalQuartzCoreUsage
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNoPlatformObjectNativeCallableReadinessDehydrated =
            didKeepNoPlatformObjectNativeCallableReadinessDehydrated
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererPlatformObjectNativeCallableReadiness(
    tokenIssueRevokeReadiness:
        CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness
): CjguiInternalRendererNoPlatformObjectNativeCallableReadiness {
    let upstreamReady =
        tokenIssueRevokeReadiness
            .didPrepareRendererNoNativeTokenTableIssueRevokeReadiness &&
        tokenIssueRevokeReadiness.didConfirmFixedCapacity &&
        tokenIssueRevokeReadiness.didConfirmIssueOpaqueToken &&
        tokenIssueRevokeReadiness.didConfirmIssuedTokenValid &&
        tokenIssueRevokeReadiness.didConfirmRevokeWithoutResourceTeardown &&
        tokenIssueRevokeReadiness.didConfirmRevokedTokenInvalidated &&
        tokenIssueRevokeReadiness.didConfirmDoubleRevokeFailClosed &&
        tokenIssueRevokeReadiness.didConfirmNoResourceBinding &&
        tokenIssueRevokeReadiness.didConfirmNoPublicSurface &&
        tokenIssueRevokeReadiness.didConfirmNoResourceCallable &&
        tokenIssueRevokeReadiness.didConfirmNoNativeObjectHandleOrPointer &&
        tokenIssueRevokeReadiness.didConfirmNoMetalOrAppKitUsage &&
        tokenIssueRevokeReadiness.didConfirmNoRendererStateWrite &&
        tokenIssueRevokeReadiness.didConfirmNoBackendReadyTruth
    let readinessReady = upstreamReady
    let intent =
        CjguiInternalRendererPlatformObjectNativeCallableIntent(
            tokenIssueRevokeReadiness,
            readinessReady,
            !readinessReady,
            !readinessReady,
            upstreamReady,
            true,
            true,
            true,
            true,
            true
        )
    let noObjectAdmissionPolicy =
        CjguiInternalRendererPlatformObjectNoObjectAdmissionPolicy(
            intent,
            readinessReady,
            !readinessReady,
            !readinessReady,
            readinessReady,
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
    let prerequisitePolicy =
        CjguiInternalRendererPlatformObjectPrerequisitePolicy(
            noObjectAdmissionPolicy,
            readinessReady,
            !readinessReady,
            !readinessReady,
            readinessReady,
            true,
            true,
            true,
            true,
            true,
            true,
            true
        )
    return CjguiInternalRendererNoPlatformObjectNativeCallableReadiness(
        intent,
        noObjectAdmissionPolicy,
        prerequisitePolicy,
        readinessReady,
        !readinessReady,
        !readinessReady,
        readinessReady,
        readinessReady,
        readinessReady,
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

func cjguiInternalExecuteDefaultRendererPlatformObjectNativeCallableDraft():
    CjguiInternalRendererNoPlatformObjectNativeCallableReadiness {
    let tokenIssueRevokeReadiness =
        cjguiInternalExecuteDefaultRendererNativeTokenTableIssueRevokeDraft()
    return cjguiInternalBuildRendererPlatformObjectNativeCallableReadiness(
        tokenIssueRevokeReadiness
    )
}
