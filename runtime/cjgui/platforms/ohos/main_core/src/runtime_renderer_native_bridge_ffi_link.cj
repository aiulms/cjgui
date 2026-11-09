// Owner: native bridge FFI syntax / link planning value boundary.
// Truth: 只消费 CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness，
// 并记录 isolated probe evidence、no-resource callable link admission、
// runtime package link fallback 与 no-public-surface facts。
// Stop-line: 不写真实 runtime FFI call，不接 resource callable，不改 build config，
// 不创建 native object / handle，不写 renderer state，不发布 public API。
// Same-shape Boundary Brake: 不得把本 value boundary 包成 FFI permission、
// runtime-call permission、native bridge implementation、Metal/AppKit、backend-ready、
// public API、receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererNativeBridgeFfiSyntaxLinkIntent {
    let ffiDeclarationReadiness:
        CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness
    let didPrepareRendererNativeBridgeFfiSyntaxLinkIntent: Bool
    let shouldDeferRendererNativeBridgeFfiSyntaxLinkIntent: Bool
    let shouldReportRendererNativeBridgeFfiSyntaxLinkIntentBlocked: Bool
    let didPreserveRendererNativeBridgeFfiDeclarationReadiness: Bool
    let didUseForeignDeclarationSyntaxEvidence: Bool
    let didUseDirectCjcLinkEvidence: Bool
    let didRequireIsolatedProbeBeforeRuntimePackageLink: Bool
    let didKeepFfiSyntaxLinkIntentDehydrated: Bool
    let didAvoidFfiReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        ffiDeclarationReadiness:
            CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness,
        didPrepareRendererNativeBridgeFfiSyntaxLinkIntent: Bool,
        shouldDeferRendererNativeBridgeFfiSyntaxLinkIntent: Bool,
        shouldReportRendererNativeBridgeFfiSyntaxLinkIntentBlocked: Bool,
        didPreserveRendererNativeBridgeFfiDeclarationReadiness: Bool,
        didUseForeignDeclarationSyntaxEvidence: Bool,
        didUseDirectCjcLinkEvidence: Bool,
        didRequireIsolatedProbeBeforeRuntimePackageLink: Bool,
        didKeepFfiSyntaxLinkIntentDehydrated: Bool,
        didAvoidFfiReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.ffiDeclarationReadiness = ffiDeclarationReadiness
        this.didPrepareRendererNativeBridgeFfiSyntaxLinkIntent =
            didPrepareRendererNativeBridgeFfiSyntaxLinkIntent
        this.shouldDeferRendererNativeBridgeFfiSyntaxLinkIntent =
            shouldDeferRendererNativeBridgeFfiSyntaxLinkIntent
        this.shouldReportRendererNativeBridgeFfiSyntaxLinkIntentBlocked =
            shouldReportRendererNativeBridgeFfiSyntaxLinkIntentBlocked
        this.didPreserveRendererNativeBridgeFfiDeclarationReadiness =
            didPreserveRendererNativeBridgeFfiDeclarationReadiness
        this.didUseForeignDeclarationSyntaxEvidence =
            didUseForeignDeclarationSyntaxEvidence
        this.didUseDirectCjcLinkEvidence = didUseDirectCjcLinkEvidence
        this.didRequireIsolatedProbeBeforeRuntimePackageLink =
            didRequireIsolatedProbeBeforeRuntimePackageLink
        this.didKeepFfiSyntaxLinkIntentDehydrated =
            didKeepFfiSyntaxLinkIntentDehydrated
        this.didAvoidFfiReadyWrapper = didAvoidFfiReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeBridgeFfiLinkPolicy {
    let syntaxLinkIntent:
        CjguiInternalRendererNativeBridgeFfiSyntaxLinkIntent
    let didPrepareRendererNativeBridgeFfiLinkPolicy: Bool
    let shouldDeferRendererNativeBridgeFfiLinkPolicy: Bool
    let shouldReportRendererNativeBridgeFfiLinkPolicyBlocked: Bool
    let didPreserveRendererNativeBridgeFfiSyntaxLinkIntent: Bool
    let didConfirmIsolatedNoResourceProbeEvidence: Bool
    let didAdmitNoResourceCallableLinkRoute: Bool
    let didDenyRuntimePackageLinkThisStage: Bool
    let didDenyResourceCallableLinkRoute: Bool
    let didRequirePackageLinkPreflightBeforeRuntimeCall: Bool
    let didKeepFfiLinkPolicyDehydrated: Bool
    let didAvoidRuntimeCallPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        syntaxLinkIntent:
            CjguiInternalRendererNativeBridgeFfiSyntaxLinkIntent,
        didPrepareRendererNativeBridgeFfiLinkPolicy: Bool,
        shouldDeferRendererNativeBridgeFfiLinkPolicy: Bool,
        shouldReportRendererNativeBridgeFfiLinkPolicyBlocked: Bool,
        didPreserveRendererNativeBridgeFfiSyntaxLinkIntent: Bool,
        didConfirmIsolatedNoResourceProbeEvidence: Bool,
        didAdmitNoResourceCallableLinkRoute: Bool,
        didDenyRuntimePackageLinkThisStage: Bool,
        didDenyResourceCallableLinkRoute: Bool,
        didRequirePackageLinkPreflightBeforeRuntimeCall: Bool,
        didKeepFfiLinkPolicyDehydrated: Bool,
        didAvoidRuntimeCallPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.syntaxLinkIntent = syntaxLinkIntent
        this.didPrepareRendererNativeBridgeFfiLinkPolicy =
            didPrepareRendererNativeBridgeFfiLinkPolicy
        this.shouldDeferRendererNativeBridgeFfiLinkPolicy =
            shouldDeferRendererNativeBridgeFfiLinkPolicy
        this.shouldReportRendererNativeBridgeFfiLinkPolicyBlocked =
            shouldReportRendererNativeBridgeFfiLinkPolicyBlocked
        this.didPreserveRendererNativeBridgeFfiSyntaxLinkIntent =
            didPreserveRendererNativeBridgeFfiSyntaxLinkIntent
        this.didConfirmIsolatedNoResourceProbeEvidence =
            didConfirmIsolatedNoResourceProbeEvidence
        this.didAdmitNoResourceCallableLinkRoute =
            didAdmitNoResourceCallableLinkRoute
        this.didDenyRuntimePackageLinkThisStage =
            didDenyRuntimePackageLinkThisStage
        this.didDenyResourceCallableLinkRoute =
            didDenyResourceCallableLinkRoute
        this.didRequirePackageLinkPreflightBeforeRuntimeCall =
            didRequirePackageLinkPreflightBeforeRuntimeCall
        this.didKeepFfiLinkPolicyDehydrated =
            didKeepFfiLinkPolicyDehydrated
        this.didAvoidRuntimeCallPermissionWrapper =
            didAvoidRuntimeCallPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoNativeBridgeFfiLinkReadiness {
    let ffiLinkPolicy: CjguiInternalRendererNativeBridgeFfiLinkPolicy
    let didPrepareRendererNoNativeBridgeFfiLinkReadiness: Bool
    let shouldDeferRendererNoNativeBridgeFfiLinkReadiness: Bool
    let shouldReportRendererNoNativeBridgeFfiLinkReadinessBlocked: Bool
    let didPreserveRendererNativeBridgeFfiLinkPolicy: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoNativeObjectCreation: Bool
    let didConfirmNoMetalOrAppKitUsage: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoNativeBridgeFfiLinkReadinessDehydrated: Bool
    let didAvoidFfiPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        ffiLinkPolicy: CjguiInternalRendererNativeBridgeFfiLinkPolicy,
        didPrepareRendererNoNativeBridgeFfiLinkReadiness: Bool,
        shouldDeferRendererNoNativeBridgeFfiLinkReadiness: Bool,
        shouldReportRendererNoNativeBridgeFfiLinkReadinessBlocked: Bool,
        didPreserveRendererNativeBridgeFfiLinkPolicy: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoNativeObjectCreation: Bool,
        didConfirmNoMetalOrAppKitUsage: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoNativeBridgeFfiLinkReadinessDehydrated: Bool,
        didAvoidFfiPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.ffiLinkPolicy = ffiLinkPolicy
        this.didPrepareRendererNoNativeBridgeFfiLinkReadiness =
            didPrepareRendererNoNativeBridgeFfiLinkReadiness
        this.shouldDeferRendererNoNativeBridgeFfiLinkReadiness =
            shouldDeferRendererNoNativeBridgeFfiLinkReadiness
        this.shouldReportRendererNoNativeBridgeFfiLinkReadinessBlocked =
            shouldReportRendererNoNativeBridgeFfiLinkReadinessBlocked
        this.didPreserveRendererNativeBridgeFfiLinkPolicy =
            didPreserveRendererNativeBridgeFfiLinkPolicy
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoNativeObjectCreation =
            didConfirmNoNativeObjectCreation
        this.didConfirmNoMetalOrAppKitUsage =
            didConfirmNoMetalOrAppKitUsage
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNoNativeBridgeFfiLinkReadinessDehydrated =
            didKeepNoNativeBridgeFfiLinkReadinessDehydrated
        this.didAvoidFfiPermissionWrapper = didAvoidFfiPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererNativeBridgeFfiLinkReadiness(
    ffiDeclarationReadiness:
        CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness,
    didConfirmIsolatedNoResourceProbeEvidence: Bool,
    didAdmitNoResourceCallableLinkRoute: Bool,
    didDenyRuntimePackageLinkThisStage: Bool
): CjguiInternalRendererNoNativeBridgeFfiLinkReadiness {
    let intent = CjguiInternalRendererNativeBridgeFfiSyntaxLinkIntent(
        ffiDeclarationReadiness,
        true,
        !didConfirmIsolatedNoResourceProbeEvidence,
        !didConfirmIsolatedNoResourceProbeEvidence,
        true,
        didConfirmIsolatedNoResourceProbeEvidence,
        didAdmitNoResourceCallableLinkRoute,
        true,
        true,
        true,
        true
    )
    let policy = CjguiInternalRendererNativeBridgeFfiLinkPolicy(
        intent,
        true,
        !didAdmitNoResourceCallableLinkRoute,
        !didAdmitNoResourceCallableLinkRoute,
        true,
        didConfirmIsolatedNoResourceProbeEvidence,
        didAdmitNoResourceCallableLinkRoute,
        didDenyRuntimePackageLinkThisStage,
        true,
        didDenyRuntimePackageLinkThisStage,
        true,
        true,
        true
    )
    return CjguiInternalRendererNoNativeBridgeFfiLinkReadiness(
        policy,
        true,
        didDenyRuntimePackageLinkThisStage,
        didDenyRuntimePackageLinkThisStage,
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

func cjguiInternalExecuteDefaultRendererNativeBridgeFfiLinkDraft():
    CjguiInternalRendererNoNativeBridgeFfiLinkReadiness {
    let ffiDeclarationReadiness =
        cjguiInternalExecuteDefaultRendererNativeBridgeFfiDeclarationDraft()
    return cjguiInternalBuildRendererNativeBridgeFfiLinkReadiness(
        ffiDeclarationReadiness,
        true,
        true,
        true
    )
}
