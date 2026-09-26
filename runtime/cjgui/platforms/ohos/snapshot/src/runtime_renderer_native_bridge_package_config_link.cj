// Owner: native bridge package config link implementation value boundary.
// Truth: 只消费 CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness，
// 记录 no-resource native artifact policy、macOS-only package config gate、
// non-macOS fallback、script-managed route fallback 与 no-package-config-link facts。
// Stop-line: 不修改 runtime/cjgui/cjpm.toml，不调用 FFI，不扩 public API，
// 不接 resource callable，不创建 native object / handle / pointer，不改
// runtime_state.cj，不把 package config link facts 解释成 backend-ready truth。
// Same-shape Boundary Brake: 不得把本 value boundary 包成 runtime-call
// permission、public API、native object、Metal/AppKit、backend-ready、receipt、
// record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererNativeBridgePackageConfigLinkIntent {
    let packageCallSupportReadiness:
        CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness
    let didPrepareRendererNativeBridgePackageConfigLinkIntent: Bool
    let shouldDeferRendererNativeBridgePackageConfigLinkIntent: Bool
    let shouldReportRendererNativeBridgePackageConfigLinkIntentBlocked: Bool
    let didPreserveRendererNativeBridgePackageCallSupportReadiness: Bool
    let didChooseScriptManagedPackageConfigLinkRoute: Bool
    let didDeferRuntimeCjpmTomlMutation: Bool
    let didKeepPackageConfigLinkIntentDehydrated: Bool
    let didAvoidRuntimeFfiCallPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        packageCallSupportReadiness:
            CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness,
        didPrepareRendererNativeBridgePackageConfigLinkIntent: Bool,
        shouldDeferRendererNativeBridgePackageConfigLinkIntent: Bool,
        shouldReportRendererNativeBridgePackageConfigLinkIntentBlocked: Bool,
        didPreserveRendererNativeBridgePackageCallSupportReadiness: Bool,
        didChooseScriptManagedPackageConfigLinkRoute: Bool,
        didDeferRuntimeCjpmTomlMutation: Bool,
        didKeepPackageConfigLinkIntentDehydrated: Bool,
        didAvoidRuntimeFfiCallPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.packageCallSupportReadiness = packageCallSupportReadiness
        this.didPrepareRendererNativeBridgePackageConfigLinkIntent =
            didPrepareRendererNativeBridgePackageConfigLinkIntent
        this.shouldDeferRendererNativeBridgePackageConfigLinkIntent =
            shouldDeferRendererNativeBridgePackageConfigLinkIntent
        this
            .shouldReportRendererNativeBridgePackageConfigLinkIntentBlocked =
            shouldReportRendererNativeBridgePackageConfigLinkIntentBlocked
        this.didPreserveRendererNativeBridgePackageCallSupportReadiness =
            didPreserveRendererNativeBridgePackageCallSupportReadiness
        this.didChooseScriptManagedPackageConfigLinkRoute =
            didChooseScriptManagedPackageConfigLinkRoute
        this.didDeferRuntimeCjpmTomlMutation =
            didDeferRuntimeCjpmTomlMutation
        this.didKeepPackageConfigLinkIntentDehydrated =
            didKeepPackageConfigLinkIntentDehydrated
        this.didAvoidRuntimeFfiCallPermissionWrapper =
            didAvoidRuntimeFfiCallPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeBridgePackageConfigLinkPolicy {
    let packageConfigLinkIntent:
        CjguiInternalRendererNativeBridgePackageConfigLinkIntent
    let didPrepareRendererNativeBridgePackageConfigLinkPolicy: Bool
    let shouldDeferRendererNativeBridgePackageConfigLinkPolicy: Bool
    let shouldReportRendererNativeBridgePackageConfigLinkPolicyBlocked: Bool
    let didPreserveRendererNativeBridgePackageConfigLinkIntent: Bool
    let didConfirmNoResourceNativeArtifactPolicy: Bool
    let didRequireMacOsOnlyPackageConfigGate: Bool
    let didKeepNonMacOsFallbackFailClosed: Bool
    let didConfirmSkipScriptArtifactGenerationRisk: Bool
    let didPreferScriptManagedRouteFallback: Bool
    let didDenyRuntimePackageConfigMutationThisStage: Bool
    let didDenyActualRuntimeFfiCall: Bool
    let didDenyResourceCallableSupport: Bool
    let didKeepPackageConfigLinkPolicyDehydrated: Bool
    let didAvoidPublicApiWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        packageConfigLinkIntent:
            CjguiInternalRendererNativeBridgePackageConfigLinkIntent,
        didPrepareRendererNativeBridgePackageConfigLinkPolicy: Bool,
        shouldDeferRendererNativeBridgePackageConfigLinkPolicy: Bool,
        shouldReportRendererNativeBridgePackageConfigLinkPolicyBlocked: Bool,
        didPreserveRendererNativeBridgePackageConfigLinkIntent: Bool,
        didConfirmNoResourceNativeArtifactPolicy: Bool,
        didRequireMacOsOnlyPackageConfigGate: Bool,
        didKeepNonMacOsFallbackFailClosed: Bool,
        didConfirmSkipScriptArtifactGenerationRisk: Bool,
        didPreferScriptManagedRouteFallback: Bool,
        didDenyRuntimePackageConfigMutationThisStage: Bool,
        didDenyActualRuntimeFfiCall: Bool,
        didDenyResourceCallableSupport: Bool,
        didKeepPackageConfigLinkPolicyDehydrated: Bool,
        didAvoidPublicApiWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.packageConfigLinkIntent = packageConfigLinkIntent
        this.didPrepareRendererNativeBridgePackageConfigLinkPolicy =
            didPrepareRendererNativeBridgePackageConfigLinkPolicy
        this.shouldDeferRendererNativeBridgePackageConfigLinkPolicy =
            shouldDeferRendererNativeBridgePackageConfigLinkPolicy
        this
            .shouldReportRendererNativeBridgePackageConfigLinkPolicyBlocked =
            shouldReportRendererNativeBridgePackageConfigLinkPolicyBlocked
        this.didPreserveRendererNativeBridgePackageConfigLinkIntent =
            didPreserveRendererNativeBridgePackageConfigLinkIntent
        this.didConfirmNoResourceNativeArtifactPolicy =
            didConfirmNoResourceNativeArtifactPolicy
        this.didRequireMacOsOnlyPackageConfigGate =
            didRequireMacOsOnlyPackageConfigGate
        this.didKeepNonMacOsFallbackFailClosed =
            didKeepNonMacOsFallbackFailClosed
        this.didConfirmSkipScriptArtifactGenerationRisk =
            didConfirmSkipScriptArtifactGenerationRisk
        this.didPreferScriptManagedRouteFallback =
            didPreferScriptManagedRouteFallback
        this.didDenyRuntimePackageConfigMutationThisStage =
            didDenyRuntimePackageConfigMutationThisStage
        this.didDenyActualRuntimeFfiCall = didDenyActualRuntimeFfiCall
        this.didDenyResourceCallableSupport = didDenyResourceCallableSupport
        this.didKeepPackageConfigLinkPolicyDehydrated =
            didKeepPackageConfigLinkPolicyDehydrated
        this.didAvoidPublicApiWrapper = didAvoidPublicApiWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness {
    let packageConfigLinkPolicy:
        CjguiInternalRendererNativeBridgePackageConfigLinkPolicy
    let didPrepareRendererNoNativeBridgePackageConfigLinkReadiness: Bool
    let shouldDeferRendererNoNativeBridgePackageConfigLinkReadiness: Bool
    let shouldReportRendererNoNativeBridgePackageConfigLinkReadinessBlocked:
        Bool
    let didPreserveRendererNativeBridgePackageConfigLinkPolicy: Bool
    let didConfirmPackageConfigLinkStillDeferred: Bool
    let didConfirmScriptManagedRouteStable: Bool
    let didConfirmNoActualRuntimeFfiCall: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoResourceCallable: Bool
    let didConfirmNoNativeObjectHandleOrPointer: Bool
    let didConfirmNoMetalOrAppKitUsage: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoNativeBridgePackageConfigLinkReadinessDehydrated: Bool
    let didAvoidPackageConfigLinkPermissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        packageConfigLinkPolicy:
            CjguiInternalRendererNativeBridgePackageConfigLinkPolicy,
        didPrepareRendererNoNativeBridgePackageConfigLinkReadiness: Bool,
        shouldDeferRendererNoNativeBridgePackageConfigLinkReadiness: Bool,
        shouldReportRendererNoNativeBridgePackageConfigLinkReadinessBlocked:
            Bool,
        didPreserveRendererNativeBridgePackageConfigLinkPolicy: Bool,
        didConfirmPackageConfigLinkStillDeferred: Bool,
        didConfirmScriptManagedRouteStable: Bool,
        didConfirmNoActualRuntimeFfiCall: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoResourceCallable: Bool,
        didConfirmNoNativeObjectHandleOrPointer: Bool,
        didConfirmNoMetalOrAppKitUsage: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoNativeBridgePackageConfigLinkReadinessDehydrated: Bool,
        didAvoidPackageConfigLinkPermissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.packageConfigLinkPolicy = packageConfigLinkPolicy
        this.didPrepareRendererNoNativeBridgePackageConfigLinkReadiness =
            didPrepareRendererNoNativeBridgePackageConfigLinkReadiness
        this.shouldDeferRendererNoNativeBridgePackageConfigLinkReadiness =
            shouldDeferRendererNoNativeBridgePackageConfigLinkReadiness
        this
            .shouldReportRendererNoNativeBridgePackageConfigLinkReadinessBlocked =
            shouldReportRendererNoNativeBridgePackageConfigLinkReadinessBlocked
        this.didPreserveRendererNativeBridgePackageConfigLinkPolicy =
            didPreserveRendererNativeBridgePackageConfigLinkPolicy
        this.didConfirmPackageConfigLinkStillDeferred =
            didConfirmPackageConfigLinkStillDeferred
        this.didConfirmScriptManagedRouteStable =
            didConfirmScriptManagedRouteStable
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
        this.didKeepNoNativeBridgePackageConfigLinkReadinessDehydrated =
            didKeepNoNativeBridgePackageConfigLinkReadinessDehydrated
        this.didAvoidPackageConfigLinkPermissionWrapper =
            didAvoidPackageConfigLinkPermissionWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererNativeBridgePackageConfigLinkReadiness(
    packageCallSupportReadiness:
        CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness,
    didConfirmScriptManagedRouteStable: Bool,
    didConfirmRuntimeCjpmTomlStillDeferred: Bool,
    didConfirmSkipScriptArtifactGenerationRisk: Bool
): CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness {
    let shouldDeferPackageConfigLink =
        didConfirmRuntimeCjpmTomlStillDeferred ||
        didConfirmSkipScriptArtifactGenerationRisk
    let intent = CjguiInternalRendererNativeBridgePackageConfigLinkIntent(
        packageCallSupportReadiness,
        true,
        shouldDeferPackageConfigLink,
        shouldDeferPackageConfigLink,
        true,
        didConfirmScriptManagedRouteStable,
        didConfirmRuntimeCjpmTomlStillDeferred,
        true,
        true,
        true
    )
    let policy = CjguiInternalRendererNativeBridgePackageConfigLinkPolicy(
        intent,
        true,
        shouldDeferPackageConfigLink,
        shouldDeferPackageConfigLink,
        true,
        true,
        true,
        true,
        didConfirmSkipScriptArtifactGenerationRisk,
        didConfirmScriptManagedRouteStable,
        didConfirmRuntimeCjpmTomlStillDeferred,
        true,
        true,
        true,
        true,
        true
    )
    return CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness(
        policy,
        true,
        shouldDeferPackageConfigLink,
        shouldDeferPackageConfigLink,
        true,
        didConfirmRuntimeCjpmTomlStillDeferred,
        didConfirmScriptManagedRouteStable,
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

func cjguiInternalExecuteDefaultRendererNativeBridgePackageConfigLinkDraft():
    CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness {
    let packageCallSupport =
        cjguiInternalExecuteDefaultRendererNativeBridgePackageCallSupportDraft()
    return cjguiInternalBuildRendererNativeBridgePackageConfigLinkReadiness(
        packageCallSupport,
        true,
        true,
        true
    )
}
