// Owner: native bridge package link integration planning value boundary.
// Truth: 只消费 CjguiInternalRendererNoNativeBridgeFfiLinkReadiness，
// 并记录 package-adjacent probe evidence、macOS-only package link gate、
// runtime package config admission / fallback 与 no-resource callable link boundary。
// Stop-line: 不写真实 runtime FFI call，不修改 cjpm.toml，不接 resource callable，
// 不创建 native object / handle，不写 renderer state，不发布 public API。
// Same-shape Boundary Brake: 不得把本 value boundary 包成 package integration
// permission、runtime-call permission、native bridge implementation、Metal/AppKit、
// backend-ready、public API、receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererNativeBridgePackageLinkIntent {
    let ffiLinkReadiness:
        CjguiInternalRendererNoNativeBridgeFfiLinkReadiness
    let didPrepareRendererNativeBridgePackageLinkIntent: Bool
    let shouldDeferRendererNativeBridgePackageLinkIntent: Bool
    let shouldReportRendererNativeBridgePackageLinkIntentBlocked: Bool
    let didPreserveRendererNativeBridgeFfiLinkReadiness: Bool
    let didUseDirectCjcLinkEvidence: Bool
    let didRequirePackageAdjacentProbeBeforeCjpmConfig: Bool
    let didKeepPackageLinkIntentDehydrated: Bool
    let didAvoidPackageReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        ffiLinkReadiness:
            CjguiInternalRendererNoNativeBridgeFfiLinkReadiness,
        didPrepareRendererNativeBridgePackageLinkIntent: Bool,
        shouldDeferRendererNativeBridgePackageLinkIntent: Bool,
        shouldReportRendererNativeBridgePackageLinkIntentBlocked: Bool,
        didPreserveRendererNativeBridgeFfiLinkReadiness: Bool,
        didUseDirectCjcLinkEvidence: Bool,
        didRequirePackageAdjacentProbeBeforeCjpmConfig: Bool,
        didKeepPackageLinkIntentDehydrated: Bool,
        didAvoidPackageReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.ffiLinkReadiness = ffiLinkReadiness
        this.didPrepareRendererNativeBridgePackageLinkIntent =
            didPrepareRendererNativeBridgePackageLinkIntent
        this.shouldDeferRendererNativeBridgePackageLinkIntent =
            shouldDeferRendererNativeBridgePackageLinkIntent
        this.shouldReportRendererNativeBridgePackageLinkIntentBlocked =
            shouldReportRendererNativeBridgePackageLinkIntentBlocked
        this.didPreserveRendererNativeBridgeFfiLinkReadiness =
            didPreserveRendererNativeBridgeFfiLinkReadiness
        this.didUseDirectCjcLinkEvidence = didUseDirectCjcLinkEvidence
        this.didRequirePackageAdjacentProbeBeforeCjpmConfig =
            didRequirePackageAdjacentProbeBeforeCjpmConfig
        this.didKeepPackageLinkIntentDehydrated =
            didKeepPackageLinkIntentDehydrated
        this.didAvoidPackageReadyWrapper = didAvoidPackageReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeBridgePackageLinkPolicy {
    let packageLinkIntent:
        CjguiInternalRendererNativeBridgePackageLinkIntent
    let didPrepareRendererNativeBridgePackageLinkPolicy: Bool
    let shouldDeferRendererNativeBridgePackageLinkPolicy: Bool
    let shouldReportRendererNativeBridgePackageLinkPolicyBlocked: Bool
    let didPreserveRendererNativeBridgePackageLinkIntent: Bool
    let didConfirmPackageAdjacentProbeEvidence: Bool
    let didAdmitMacOsOnlyPackageLinkGate: Bool
    let didDenyRuntimePackageConfigModificationThisStage: Bool
    let didRequireNonMacOsFallbackBeforeCjpmConfig: Bool
    let didDenyResourceCallableLinkRoute: Bool
    let didKeepPackageLinkPolicyDehydrated: Bool
    let didAvoidRuntimeCallPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        packageLinkIntent:
            CjguiInternalRendererNativeBridgePackageLinkIntent,
        didPrepareRendererNativeBridgePackageLinkPolicy: Bool,
        shouldDeferRendererNativeBridgePackageLinkPolicy: Bool,
        shouldReportRendererNativeBridgePackageLinkPolicyBlocked: Bool,
        didPreserveRendererNativeBridgePackageLinkIntent: Bool,
        didConfirmPackageAdjacentProbeEvidence: Bool,
        didAdmitMacOsOnlyPackageLinkGate: Bool,
        didDenyRuntimePackageConfigModificationThisStage: Bool,
        didRequireNonMacOsFallbackBeforeCjpmConfig: Bool,
        didDenyResourceCallableLinkRoute: Bool,
        didKeepPackageLinkPolicyDehydrated: Bool,
        didAvoidRuntimeCallPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.packageLinkIntent = packageLinkIntent
        this.didPrepareRendererNativeBridgePackageLinkPolicy =
            didPrepareRendererNativeBridgePackageLinkPolicy
        this.shouldDeferRendererNativeBridgePackageLinkPolicy =
            shouldDeferRendererNativeBridgePackageLinkPolicy
        this.shouldReportRendererNativeBridgePackageLinkPolicyBlocked =
            shouldReportRendererNativeBridgePackageLinkPolicyBlocked
        this.didPreserveRendererNativeBridgePackageLinkIntent =
            didPreserveRendererNativeBridgePackageLinkIntent
        this.didConfirmPackageAdjacentProbeEvidence =
            didConfirmPackageAdjacentProbeEvidence
        this.didAdmitMacOsOnlyPackageLinkGate =
            didAdmitMacOsOnlyPackageLinkGate
        this.didDenyRuntimePackageConfigModificationThisStage =
            didDenyRuntimePackageConfigModificationThisStage
        this.didRequireNonMacOsFallbackBeforeCjpmConfig =
            didRequireNonMacOsFallbackBeforeCjpmConfig
        this.didDenyResourceCallableLinkRoute =
            didDenyResourceCallableLinkRoute
        this.didKeepPackageLinkPolicyDehydrated =
            didKeepPackageLinkPolicyDehydrated
        this.didAvoidRuntimeCallPermissionWrapper =
            didAvoidRuntimeCallPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoNativeBridgePackageLinkReadiness {
    let packageLinkPolicy:
        CjguiInternalRendererNativeBridgePackageLinkPolicy
    let didPrepareRendererNoNativeBridgePackageLinkReadiness: Bool
    let shouldDeferRendererNoNativeBridgePackageLinkReadiness: Bool
    let shouldReportRendererNoNativeBridgePackageLinkReadinessBlocked: Bool
    let didPreserveRendererNativeBridgePackageLinkPolicy: Bool
    let didConfirmNoRuntimeFfiCall: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoNativeObjectCreation: Bool
    let didConfirmNoMetalOrAppKitUsage: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoNativeBridgePackageLinkReadinessDehydrated: Bool
    let didAvoidPackageLinkPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        packageLinkPolicy:
            CjguiInternalRendererNativeBridgePackageLinkPolicy,
        didPrepareRendererNoNativeBridgePackageLinkReadiness: Bool,
        shouldDeferRendererNoNativeBridgePackageLinkReadiness: Bool,
        shouldReportRendererNoNativeBridgePackageLinkReadinessBlocked: Bool,
        didPreserveRendererNativeBridgePackageLinkPolicy: Bool,
        didConfirmNoRuntimeFfiCall: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoNativeObjectCreation: Bool,
        didConfirmNoMetalOrAppKitUsage: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoNativeBridgePackageLinkReadinessDehydrated: Bool,
        didAvoidPackageLinkPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.packageLinkPolicy = packageLinkPolicy
        this.didPrepareRendererNoNativeBridgePackageLinkReadiness =
            didPrepareRendererNoNativeBridgePackageLinkReadiness
        this.shouldDeferRendererNoNativeBridgePackageLinkReadiness =
            shouldDeferRendererNoNativeBridgePackageLinkReadiness
        this.shouldReportRendererNoNativeBridgePackageLinkReadinessBlocked =
            shouldReportRendererNoNativeBridgePackageLinkReadinessBlocked
        this.didPreserveRendererNativeBridgePackageLinkPolicy =
            didPreserveRendererNativeBridgePackageLinkPolicy
        this.didConfirmNoRuntimeFfiCall = didConfirmNoRuntimeFfiCall
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoNativeObjectCreation =
            didConfirmNoNativeObjectCreation
        this.didConfirmNoMetalOrAppKitUsage =
            didConfirmNoMetalOrAppKitUsage
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNoNativeBridgePackageLinkReadinessDehydrated =
            didKeepNoNativeBridgePackageLinkReadinessDehydrated
        this.didAvoidPackageLinkPermissionWrapper =
            didAvoidPackageLinkPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererNativeBridgePackageLinkReadiness(
    ffiLinkReadiness:
        CjguiInternalRendererNoNativeBridgeFfiLinkReadiness,
    didConfirmPackageAdjacentProbeEvidence: Bool,
    didAdmitMacOsOnlyPackageLinkGate: Bool,
    didDenyRuntimePackageConfigModificationThisStage: Bool
): CjguiInternalRendererNoNativeBridgePackageLinkReadiness {
    let intent = CjguiInternalRendererNativeBridgePackageLinkIntent(
        ffiLinkReadiness,
        true,
        !didConfirmPackageAdjacentProbeEvidence,
        !didConfirmPackageAdjacentProbeEvidence,
        true,
        true,
        true,
        true,
        true,
        true
    )
    let policy = CjguiInternalRendererNativeBridgePackageLinkPolicy(
        intent,
        true,
        didDenyRuntimePackageConfigModificationThisStage,
        didDenyRuntimePackageConfigModificationThisStage,
        true,
        didConfirmPackageAdjacentProbeEvidence,
        didAdmitMacOsOnlyPackageLinkGate,
        didDenyRuntimePackageConfigModificationThisStage,
        didDenyRuntimePackageConfigModificationThisStage,
        true,
        true,
        true,
        true
    )
    return CjguiInternalRendererNoNativeBridgePackageLinkReadiness(
        policy,
        true,
        didDenyRuntimePackageConfigModificationThisStage,
        didDenyRuntimePackageConfigModificationThisStage,
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

func cjguiInternalExecuteDefaultRendererNativeBridgePackageLinkDraft():
    CjguiInternalRendererNoNativeBridgePackageLinkReadiness {
    let ffiLinkReadiness =
        cjguiInternalExecuteDefaultRendererNativeBridgeFfiLinkDraft()
    return cjguiInternalBuildRendererNativeBridgePackageLinkReadiness(
        ffiLinkReadiness,
        true,
        true,
        true
    )
}
