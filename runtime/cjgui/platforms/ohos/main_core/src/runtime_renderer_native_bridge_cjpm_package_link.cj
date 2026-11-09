// Owner: native bridge cjpm package link implementation planning value boundary.
// Truth: 只消费 CjguiInternalRendererNoNativeBridgePackageLinkReadiness，
// 并记录 script-managed cjpm package link route、macOS-only gate、
// runtime package config admission / fallback 与 no-resource native link policy。
// Stop-line: 不写 runtime FFI call，不扩 public API，不创建 native object / handle，
// 不修改 runtime_state.cj，不把 package link 解释成 backend-ready truth。
// Same-shape Boundary Brake: 不得把本 value boundary 包成 runtime FFI call
// permission、public API、native object、Metal/AppKit、backend-ready、receipt、
// record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererNativeBridgeCjpmPackageLinkIntent {
    let packageLinkReadiness:
        CjguiInternalRendererNoNativeBridgePackageLinkReadiness
    let didPrepareRendererNativeBridgeCjpmPackageLinkIntent: Bool
    let shouldDeferRendererNativeBridgeCjpmPackageLinkIntent: Bool
    let shouldReportRendererNativeBridgeCjpmPackageLinkIntentBlocked: Bool
    let didPreserveRendererNativeBridgePackageLinkReadiness: Bool
    let didChooseScriptManagedCjpmPackageLinkRoute: Bool
    let didDeferRuntimeCjpmTomlMutation: Bool
    let didKeepCjpmPackageLinkIntentDehydrated: Bool
    let didAvoidRuntimeFfiCallPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        packageLinkReadiness:
            CjguiInternalRendererNoNativeBridgePackageLinkReadiness,
        didPrepareRendererNativeBridgeCjpmPackageLinkIntent: Bool,
        shouldDeferRendererNativeBridgeCjpmPackageLinkIntent: Bool,
        shouldReportRendererNativeBridgeCjpmPackageLinkIntentBlocked: Bool,
        didPreserveRendererNativeBridgePackageLinkReadiness: Bool,
        didChooseScriptManagedCjpmPackageLinkRoute: Bool,
        didDeferRuntimeCjpmTomlMutation: Bool,
        didKeepCjpmPackageLinkIntentDehydrated: Bool,
        didAvoidRuntimeFfiCallPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.packageLinkReadiness = packageLinkReadiness
        this.didPrepareRendererNativeBridgeCjpmPackageLinkIntent =
            didPrepareRendererNativeBridgeCjpmPackageLinkIntent
        this.shouldDeferRendererNativeBridgeCjpmPackageLinkIntent =
            shouldDeferRendererNativeBridgeCjpmPackageLinkIntent
        this.shouldReportRendererNativeBridgeCjpmPackageLinkIntentBlocked =
            shouldReportRendererNativeBridgeCjpmPackageLinkIntentBlocked
        this.didPreserveRendererNativeBridgePackageLinkReadiness =
            didPreserveRendererNativeBridgePackageLinkReadiness
        this.didChooseScriptManagedCjpmPackageLinkRoute =
            didChooseScriptManagedCjpmPackageLinkRoute
        this.didDeferRuntimeCjpmTomlMutation =
            didDeferRuntimeCjpmTomlMutation
        this.didKeepCjpmPackageLinkIntentDehydrated =
            didKeepCjpmPackageLinkIntentDehydrated
        this.didAvoidRuntimeFfiCallPermissionWrapper =
            didAvoidRuntimeFfiCallPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeBridgeCjpmPackageLinkPolicy {
    let cjpmPackageLinkIntent:
        CjguiInternalRendererNativeBridgeCjpmPackageLinkIntent
    let didPrepareRendererNativeBridgeCjpmPackageLinkPolicy: Bool
    let shouldDeferRendererNativeBridgeCjpmPackageLinkPolicy: Bool
    let shouldReportRendererNativeBridgeCjpmPackageLinkPolicyBlocked: Bool
    let didPreserveRendererNativeBridgeCjpmPackageLinkIntent: Bool
    let didConfirmTemporaryCjpmPackageLinkEvidence: Bool
    let didRequireMacOsOnlyCjpmPackageLinkGate: Bool
    let didKeepNonMacOsFallbackFailClosed: Bool
    let didDenyRuntimePackageConfigMutationThisStage: Bool
    let didDenyResourceCallablePackageLink: Bool
    let didKeepCjpmPackageLinkPolicyDehydrated: Bool
    let didAvoidNativeBridgeImplementationWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        cjpmPackageLinkIntent:
            CjguiInternalRendererNativeBridgeCjpmPackageLinkIntent,
        didPrepareRendererNativeBridgeCjpmPackageLinkPolicy: Bool,
        shouldDeferRendererNativeBridgeCjpmPackageLinkPolicy: Bool,
        shouldReportRendererNativeBridgeCjpmPackageLinkPolicyBlocked: Bool,
        didPreserveRendererNativeBridgeCjpmPackageLinkIntent: Bool,
        didConfirmTemporaryCjpmPackageLinkEvidence: Bool,
        didRequireMacOsOnlyCjpmPackageLinkGate: Bool,
        didKeepNonMacOsFallbackFailClosed: Bool,
        didDenyRuntimePackageConfigMutationThisStage: Bool,
        didDenyResourceCallablePackageLink: Bool,
        didKeepCjpmPackageLinkPolicyDehydrated: Bool,
        didAvoidNativeBridgeImplementationWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.cjpmPackageLinkIntent = cjpmPackageLinkIntent
        this.didPrepareRendererNativeBridgeCjpmPackageLinkPolicy =
            didPrepareRendererNativeBridgeCjpmPackageLinkPolicy
        this.shouldDeferRendererNativeBridgeCjpmPackageLinkPolicy =
            shouldDeferRendererNativeBridgeCjpmPackageLinkPolicy
        this.shouldReportRendererNativeBridgeCjpmPackageLinkPolicyBlocked =
            shouldReportRendererNativeBridgeCjpmPackageLinkPolicyBlocked
        this.didPreserveRendererNativeBridgeCjpmPackageLinkIntent =
            didPreserveRendererNativeBridgeCjpmPackageLinkIntent
        this.didConfirmTemporaryCjpmPackageLinkEvidence =
            didConfirmTemporaryCjpmPackageLinkEvidence
        this.didRequireMacOsOnlyCjpmPackageLinkGate =
            didRequireMacOsOnlyCjpmPackageLinkGate
        this.didKeepNonMacOsFallbackFailClosed =
            didKeepNonMacOsFallbackFailClosed
        this.didDenyRuntimePackageConfigMutationThisStage =
            didDenyRuntimePackageConfigMutationThisStage
        this.didDenyResourceCallablePackageLink =
            didDenyResourceCallablePackageLink
        this.didKeepCjpmPackageLinkPolicyDehydrated =
            didKeepCjpmPackageLinkPolicyDehydrated
        this.didAvoidNativeBridgeImplementationWrapper =
            didAvoidNativeBridgeImplementationWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness {
    let cjpmPackageLinkPolicy:
        CjguiInternalRendererNativeBridgeCjpmPackageLinkPolicy
    let didPrepareRendererNoNativeBridgeCjpmPackageLinkReadiness: Bool
    let shouldDeferRendererNoNativeBridgeCjpmPackageLinkReadiness: Bool
    let shouldReportRendererNoNativeBridgeCjpmPackageLinkReadinessBlocked: Bool
    let didPreserveRendererNativeBridgeCjpmPackageLinkPolicy: Bool
    let didConfirmNoRuntimeFfiCall: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoResourceCallable: Bool
    let didConfirmNoNativeObjectCreation: Bool
    let didConfirmNoMetalOrAppKitUsage: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoNativeBridgeCjpmPackageLinkReadinessDehydrated: Bool
    let didAvoidPackageReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        cjpmPackageLinkPolicy:
            CjguiInternalRendererNativeBridgeCjpmPackageLinkPolicy,
        didPrepareRendererNoNativeBridgeCjpmPackageLinkReadiness: Bool,
        shouldDeferRendererNoNativeBridgeCjpmPackageLinkReadiness: Bool,
        shouldReportRendererNoNativeBridgeCjpmPackageLinkReadinessBlocked:
            Bool,
        didPreserveRendererNativeBridgeCjpmPackageLinkPolicy: Bool,
        didConfirmNoRuntimeFfiCall: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoResourceCallable: Bool,
        didConfirmNoNativeObjectCreation: Bool,
        didConfirmNoMetalOrAppKitUsage: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoNativeBridgeCjpmPackageLinkReadinessDehydrated: Bool,
        didAvoidPackageReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.cjpmPackageLinkPolicy = cjpmPackageLinkPolicy
        this.didPrepareRendererNoNativeBridgeCjpmPackageLinkReadiness =
            didPrepareRendererNoNativeBridgeCjpmPackageLinkReadiness
        this.shouldDeferRendererNoNativeBridgeCjpmPackageLinkReadiness =
            shouldDeferRendererNoNativeBridgeCjpmPackageLinkReadiness
        this.shouldReportRendererNoNativeBridgeCjpmPackageLinkReadinessBlocked =
            shouldReportRendererNoNativeBridgeCjpmPackageLinkReadinessBlocked
        this.didPreserveRendererNativeBridgeCjpmPackageLinkPolicy =
            didPreserveRendererNativeBridgeCjpmPackageLinkPolicy
        this.didConfirmNoRuntimeFfiCall = didConfirmNoRuntimeFfiCall
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoResourceCallable = didConfirmNoResourceCallable
        this.didConfirmNoNativeObjectCreation =
            didConfirmNoNativeObjectCreation
        this.didConfirmNoMetalOrAppKitUsage =
            didConfirmNoMetalOrAppKitUsage
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNoNativeBridgeCjpmPackageLinkReadinessDehydrated =
            didKeepNoNativeBridgeCjpmPackageLinkReadinessDehydrated
        this.didAvoidPackageReadyWrapper = didAvoidPackageReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererNativeBridgeCjpmPackageLinkReadiness(
    packageLinkReadiness:
        CjguiInternalRendererNoNativeBridgePackageLinkReadiness,
    didConfirmTemporaryCjpmPackageLinkEvidence: Bool,
    didRequireMacOsOnlyCjpmPackageLinkGate: Bool,
    didDenyRuntimePackageConfigMutationThisStage: Bool
): CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness {
    let intent = CjguiInternalRendererNativeBridgeCjpmPackageLinkIntent(
        packageLinkReadiness,
        true,
        !didConfirmTemporaryCjpmPackageLinkEvidence,
        !didConfirmTemporaryCjpmPackageLinkEvidence,
        true,
        true,
        didDenyRuntimePackageConfigMutationThisStage,
        true,
        true,
        true
    )
    let policy = CjguiInternalRendererNativeBridgeCjpmPackageLinkPolicy(
        intent,
        true,
        didDenyRuntimePackageConfigMutationThisStage,
        didDenyRuntimePackageConfigMutationThisStage,
        true,
        didConfirmTemporaryCjpmPackageLinkEvidence,
        didRequireMacOsOnlyCjpmPackageLinkGate,
        true,
        didDenyRuntimePackageConfigMutationThisStage,
        true,
        true,
        true,
        true
    )
    return CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness(
        policy,
        true,
        didDenyRuntimePackageConfigMutationThisStage,
        didDenyRuntimePackageConfigMutationThisStage,
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

func cjguiInternalExecuteDefaultRendererNativeBridgeCjpmPackageLinkDraft():
    CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness {
    let packageLinkReadiness =
        cjguiInternalExecuteDefaultRendererNativeBridgePackageLinkDraft()
    return cjguiInternalBuildRendererNativeBridgeCjpmPackageLinkReadiness(
        packageLinkReadiness,
        true,
        true,
        true
    )
}
