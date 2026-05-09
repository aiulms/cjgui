// Owner: native bridge runtime package link call support value boundary.
// Truth: 只消费 CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness，
// 记录 runtime-adjacent call evidence、package link call support blocker、
// macOS-only gate 与 no-runtime-package-call-support readiness facts。
// Stop-line: 不调用 FFI，不修改 runtime/cjgui/cjpm.toml，不扩 public API，
// 不接 resource callable，不创建 native object / handle / pointer，不改
// runtime_state.cj，不把 call support facts 解释成 backend-ready truth。
// Same-shape Boundary Brake: 不得把本 value boundary 包成 runtime-call
// permission、public API、native object、Metal/AppKit、backend-ready、receipt、
// record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererNativeBridgePackageCallSupportIntent {
    let runtimeFfiCallReadiness:
        CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness
    let didPrepareRendererNativeBridgePackageCallSupportIntent: Bool
    let shouldDeferRendererNativeBridgePackageCallSupportIntent: Bool
    let shouldReportRendererNativeBridgePackageCallSupportIntentBlocked: Bool
    let didPreserveRendererNativeBridgeRuntimeFfiCallReadiness: Bool
    let didConfirmRuntimeAdjacentNoResourceCallEvidence: Bool
    let didConfirmRuntimePackageConfigStillDeferred: Bool
    let didIdentifyRuntimePackageCallSupportBlocker: Bool
    let didKeepPackageCallSupportIntentDehydrated: Bool
    let didAvoidRuntimeFfiCallPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        runtimeFfiCallReadiness:
            CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness,
        didPrepareRendererNativeBridgePackageCallSupportIntent: Bool,
        shouldDeferRendererNativeBridgePackageCallSupportIntent: Bool,
        shouldReportRendererNativeBridgePackageCallSupportIntentBlocked:
            Bool,
        didPreserveRendererNativeBridgeRuntimeFfiCallReadiness: Bool,
        didConfirmRuntimeAdjacentNoResourceCallEvidence: Bool,
        didConfirmRuntimePackageConfigStillDeferred: Bool,
        didIdentifyRuntimePackageCallSupportBlocker: Bool,
        didKeepPackageCallSupportIntentDehydrated: Bool,
        didAvoidRuntimeFfiCallPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.runtimeFfiCallReadiness = runtimeFfiCallReadiness
        this.didPrepareRendererNativeBridgePackageCallSupportIntent =
            didPrepareRendererNativeBridgePackageCallSupportIntent
        this.shouldDeferRendererNativeBridgePackageCallSupportIntent =
            shouldDeferRendererNativeBridgePackageCallSupportIntent
        this
            .shouldReportRendererNativeBridgePackageCallSupportIntentBlocked =
            shouldReportRendererNativeBridgePackageCallSupportIntentBlocked
        this.didPreserveRendererNativeBridgeRuntimeFfiCallReadiness =
            didPreserveRendererNativeBridgeRuntimeFfiCallReadiness
        this.didConfirmRuntimeAdjacentNoResourceCallEvidence =
            didConfirmRuntimeAdjacentNoResourceCallEvidence
        this.didConfirmRuntimePackageConfigStillDeferred =
            didConfirmRuntimePackageConfigStillDeferred
        this.didIdentifyRuntimePackageCallSupportBlocker =
            didIdentifyRuntimePackageCallSupportBlocker
        this.didKeepPackageCallSupportIntentDehydrated =
            didKeepPackageCallSupportIntentDehydrated
        this.didAvoidRuntimeFfiCallPermissionWrapper =
            didAvoidRuntimeFfiCallPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeBridgePackageCallSupportPolicy {
    let packageCallSupportIntent:
        CjguiInternalRendererNativeBridgePackageCallSupportIntent
    let didPrepareRendererNativeBridgePackageCallSupportPolicy: Bool
    let shouldDeferRendererNativeBridgePackageCallSupportPolicy: Bool
    let shouldReportRendererNativeBridgePackageCallSupportPolicyBlocked: Bool
    let didPreserveRendererNativeBridgePackageCallSupportIntent: Bool
    let didConfirmRuntimeAdjacentProbeEvidencePolicy: Bool
    let didRequireRuntimePackageLinkBeforeOwnerCall: Bool
    let didConfirmDylibPathEvidenceRemainsProbeOnly: Bool
    let didConfirmObjectPathEvidenceRemainsProbeOnly: Bool
    let didRequireMacOsOnlyPackageCallSupportGate: Bool
    let didKeepNonMacOsFallbackFailClosed: Bool
    let didDenyRuntimeCjpmTomlMutationThisStage: Bool
    let didDenyActualRuntimeFfiCall: Bool
    let didDenyResourceCallableSupport: Bool
    let didKeepPackageCallSupportPolicyDehydrated: Bool
    let didAvoidPublicApiWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        packageCallSupportIntent:
            CjguiInternalRendererNativeBridgePackageCallSupportIntent,
        didPrepareRendererNativeBridgePackageCallSupportPolicy: Bool,
        shouldDeferRendererNativeBridgePackageCallSupportPolicy: Bool,
        shouldReportRendererNativeBridgePackageCallSupportPolicyBlocked:
            Bool,
        didPreserveRendererNativeBridgePackageCallSupportIntent: Bool,
        didConfirmRuntimeAdjacentProbeEvidencePolicy: Bool,
        didRequireRuntimePackageLinkBeforeOwnerCall: Bool,
        didConfirmDylibPathEvidenceRemainsProbeOnly: Bool,
        didConfirmObjectPathEvidenceRemainsProbeOnly: Bool,
        didRequireMacOsOnlyPackageCallSupportGate: Bool,
        didKeepNonMacOsFallbackFailClosed: Bool,
        didDenyRuntimeCjpmTomlMutationThisStage: Bool,
        didDenyActualRuntimeFfiCall: Bool,
        didDenyResourceCallableSupport: Bool,
        didKeepPackageCallSupportPolicyDehydrated: Bool,
        didAvoidPublicApiWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.packageCallSupportIntent = packageCallSupportIntent
        this.didPrepareRendererNativeBridgePackageCallSupportPolicy =
            didPrepareRendererNativeBridgePackageCallSupportPolicy
        this.shouldDeferRendererNativeBridgePackageCallSupportPolicy =
            shouldDeferRendererNativeBridgePackageCallSupportPolicy
        this
            .shouldReportRendererNativeBridgePackageCallSupportPolicyBlocked =
            shouldReportRendererNativeBridgePackageCallSupportPolicyBlocked
        this.didPreserveRendererNativeBridgePackageCallSupportIntent =
            didPreserveRendererNativeBridgePackageCallSupportIntent
        this.didConfirmRuntimeAdjacentProbeEvidencePolicy =
            didConfirmRuntimeAdjacentProbeEvidencePolicy
        this.didRequireRuntimePackageLinkBeforeOwnerCall =
            didRequireRuntimePackageLinkBeforeOwnerCall
        this.didConfirmDylibPathEvidenceRemainsProbeOnly =
            didConfirmDylibPathEvidenceRemainsProbeOnly
        this.didConfirmObjectPathEvidenceRemainsProbeOnly =
            didConfirmObjectPathEvidenceRemainsProbeOnly
        this.didRequireMacOsOnlyPackageCallSupportGate =
            didRequireMacOsOnlyPackageCallSupportGate
        this.didKeepNonMacOsFallbackFailClosed =
            didKeepNonMacOsFallbackFailClosed
        this.didDenyRuntimeCjpmTomlMutationThisStage =
            didDenyRuntimeCjpmTomlMutationThisStage
        this.didDenyActualRuntimeFfiCall = didDenyActualRuntimeFfiCall
        this.didDenyResourceCallableSupport = didDenyResourceCallableSupport
        this.didKeepPackageCallSupportPolicyDehydrated =
            didKeepPackageCallSupportPolicyDehydrated
        this.didAvoidPublicApiWrapper = didAvoidPublicApiWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness {
    let packageCallSupportPolicy:
        CjguiInternalRendererNativeBridgePackageCallSupportPolicy
    let didPrepareRendererNoNativeBridgePackageCallSupportReadiness: Bool
    let shouldDeferRendererNoNativeBridgePackageCallSupportReadiness: Bool
    let shouldReportRendererNoNativeBridgePackageCallSupportReadinessBlocked:
        Bool
    let didPreserveRendererNativeBridgePackageCallSupportPolicy: Bool
    let didConfirmRuntimePackageCallSupportStillBlocked: Bool
    let didConfirmRuntimeAdjacentEvidenceOnly: Bool
    let didConfirmNoActualRuntimeFfiCall: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoResourceCallable: Bool
    let didConfirmNoNativeObjectHandleOrPointer: Bool
    let didConfirmNoMetalOrAppKitUsage: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoNativeBridgePackageCallSupportReadinessDehydrated: Bool
    let didAvoidPackageCallSupportPermissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        packageCallSupportPolicy:
            CjguiInternalRendererNativeBridgePackageCallSupportPolicy,
        didPrepareRendererNoNativeBridgePackageCallSupportReadiness: Bool,
        shouldDeferRendererNoNativeBridgePackageCallSupportReadiness: Bool,
        shouldReportRendererNoNativeBridgePackageCallSupportReadinessBlocked:
            Bool,
        didPreserveRendererNativeBridgePackageCallSupportPolicy: Bool,
        didConfirmRuntimePackageCallSupportStillBlocked: Bool,
        didConfirmRuntimeAdjacentEvidenceOnly: Bool,
        didConfirmNoActualRuntimeFfiCall: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoResourceCallable: Bool,
        didConfirmNoNativeObjectHandleOrPointer: Bool,
        didConfirmNoMetalOrAppKitUsage: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoNativeBridgePackageCallSupportReadinessDehydrated: Bool,
        didAvoidPackageCallSupportPermissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.packageCallSupportPolicy = packageCallSupportPolicy
        this.didPrepareRendererNoNativeBridgePackageCallSupportReadiness =
            didPrepareRendererNoNativeBridgePackageCallSupportReadiness
        this.shouldDeferRendererNoNativeBridgePackageCallSupportReadiness =
            shouldDeferRendererNoNativeBridgePackageCallSupportReadiness
        this
            .shouldReportRendererNoNativeBridgePackageCallSupportReadinessBlocked =
            shouldReportRendererNoNativeBridgePackageCallSupportReadinessBlocked
        this.didPreserveRendererNativeBridgePackageCallSupportPolicy =
            didPreserveRendererNativeBridgePackageCallSupportPolicy
        this.didConfirmRuntimePackageCallSupportStillBlocked =
            didConfirmRuntimePackageCallSupportStillBlocked
        this.didConfirmRuntimeAdjacentEvidenceOnly =
            didConfirmRuntimeAdjacentEvidenceOnly
        this.didConfirmNoActualRuntimeFfiCall =
            didConfirmNoActualRuntimeFfiCall
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoResourceCallable = didConfirmNoResourceCallable
        this.didConfirmNoNativeObjectHandleOrPointer =
            didConfirmNoNativeObjectHandleOrPointer
        this.didConfirmNoMetalOrAppKitUsage =
            didConfirmNoMetalOrAppKitUsage
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNoNativeBridgePackageCallSupportReadinessDehydrated =
            didKeepNoNativeBridgePackageCallSupportReadinessDehydrated
        this.didAvoidPackageCallSupportPermissionWrapper =
            didAvoidPackageCallSupportPermissionWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererNativeBridgePackageCallSupportReadiness(
    runtimeFfiCallReadiness:
        CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness,
    didConfirmRuntimeAdjacentNoResourceCallEvidence: Bool,
    didConfirmRuntimePackageConfigStillDeferred: Bool,
    didIdentifyRuntimePackageCallSupportBlocker: Bool
): CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness {
    let runtimeDeclarationReady =
        runtimeFfiCallReadiness
            .didPrepareRendererNoNativeBridgeRuntimeFfiCallReadiness &&
        runtimeFfiCallReadiness
            .didConfirmInternalForeignDeclarationsPresent &&
        runtimeFfiCallReadiness.didConfirmNoRuntimeFfiCall &&
        runtimeFfiCallReadiness.didConfirmNoPublicSurface &&
        runtimeFfiCallReadiness.didConfirmNoResourceCallable &&
        runtimeFfiCallReadiness.didConfirmNoNativeObjectHandleOrPointer &&
        runtimeFfiCallReadiness.didConfirmNoMetalOrAppKitUsage &&
        runtimeFfiCallReadiness.didConfirmNoRendererStateWrite &&
        runtimeFfiCallReadiness.didConfirmNoBackendReadyTruth
    let packageCallSupportFactsReady =
        runtimeDeclarationReady &&
        didConfirmRuntimeAdjacentNoResourceCallEvidence &&
        didConfirmRuntimePackageConfigStillDeferred &&
        didIdentifyRuntimePackageCallSupportBlocker

    let intent =
        CjguiInternalRendererNativeBridgePackageCallSupportIntent(
            runtimeFfiCallReadiness,
            packageCallSupportFactsReady,
            !packageCallSupportFactsReady,
            !packageCallSupportFactsReady,
            runtimeDeclarationReady,
            didConfirmRuntimeAdjacentNoResourceCallEvidence,
            didConfirmRuntimePackageConfigStillDeferred,
            didIdentifyRuntimePackageCallSupportBlocker,
            true,
            true,
            true
        )
    let policy =
        CjguiInternalRendererNativeBridgePackageCallSupportPolicy(
            intent,
            packageCallSupportFactsReady,
            !packageCallSupportFactsReady,
            !packageCallSupportFactsReady,
            packageCallSupportFactsReady,
            didConfirmRuntimeAdjacentNoResourceCallEvidence,
            didIdentifyRuntimePackageCallSupportBlocker,
            didIdentifyRuntimePackageCallSupportBlocker,
            didIdentifyRuntimePackageCallSupportBlocker,
            true,
            true,
            didConfirmRuntimePackageConfigStillDeferred,
            true,
            true,
            true,
            true,
            true
        )

    return CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness(
        policy,
        packageCallSupportFactsReady,
        !packageCallSupportFactsReady,
        !packageCallSupportFactsReady,
        packageCallSupportFactsReady,
        didIdentifyRuntimePackageCallSupportBlocker,
        didConfirmRuntimeAdjacentNoResourceCallEvidence,
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

func cjguiInternalExecuteDefaultRendererNativeBridgePackageCallSupportDraft():
    CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness {
    let runtimeFfiCallReadiness =
        cjguiInternalExecuteDefaultRendererNativeBridgeRuntimeFfiDeclarationDraft()
    return cjguiInternalBuildRendererNativeBridgePackageCallSupportReadiness(
        runtimeFfiCallReadiness,
        true,
        true,
        true
    )
}
