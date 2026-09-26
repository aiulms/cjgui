// Owner: native bridge runtime FFI declaration planning value boundary.
// Truth: 只消费 CjguiInternalRendererNoCallableCAbiReadiness，并记录 internal-only
// declaration intent、no-resource callable allowlist、link separation / fallback policy
// 与 no-native-bridge-FFI-declaration readiness facts。
// Stop-line: 只产出 internal-only dehydrated facts；不写真实 FFI declaration，不接
// runtime call，不改 build config，不创建 native object / handle，不写 renderer state，
// 不发布 public API。
// Same-shape Boundary Brake: 不得把本 value boundary 包成 FFI permission、
// runtime-call permission、native bridge implementation、native-handle、Metal/AppKit、
// backend-ready、public API、receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererNativeBridgeFfiDeclarationIntent {
    let noCallableCAbiReadiness:
        CjguiInternalRendererNoCallableCAbiReadiness
    let didPrepareRendererNativeBridgeFfiDeclarationIntent: Bool
    let shouldDeferRendererNativeBridgeFfiDeclarationIntent: Bool
    let shouldReportRendererNativeBridgeFfiDeclarationIntentBlocked: Bool
    let didPreserveRendererNoCallableCAbiReadiness: Bool
    let didConfirmNoResourceCallableSurfaceExists: Bool
    let didOpenFfiDeclarationRunwayAsPlanningOnly: Bool
    let didKeepFfiSyntaxUnwritten: Bool
    let didKeepFfiDeclarationIntentDehydrated: Bool
    let didAvoidFfiPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        noCallableCAbiReadiness:
            CjguiInternalRendererNoCallableCAbiReadiness,
        didPrepareRendererNativeBridgeFfiDeclarationIntent: Bool,
        shouldDeferRendererNativeBridgeFfiDeclarationIntent: Bool,
        shouldReportRendererNativeBridgeFfiDeclarationIntentBlocked: Bool,
        didPreserveRendererNoCallableCAbiReadiness: Bool,
        didConfirmNoResourceCallableSurfaceExists: Bool,
        didOpenFfiDeclarationRunwayAsPlanningOnly: Bool,
        didKeepFfiSyntaxUnwritten: Bool,
        didKeepFfiDeclarationIntentDehydrated: Bool,
        didAvoidFfiPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noCallableCAbiReadiness = noCallableCAbiReadiness
        this.didPrepareRendererNativeBridgeFfiDeclarationIntent =
            didPrepareRendererNativeBridgeFfiDeclarationIntent
        this.shouldDeferRendererNativeBridgeFfiDeclarationIntent =
            shouldDeferRendererNativeBridgeFfiDeclarationIntent
        this.shouldReportRendererNativeBridgeFfiDeclarationIntentBlocked =
            shouldReportRendererNativeBridgeFfiDeclarationIntentBlocked
        this.didPreserveRendererNoCallableCAbiReadiness =
            didPreserveRendererNoCallableCAbiReadiness
        this.didConfirmNoResourceCallableSurfaceExists =
            didConfirmNoResourceCallableSurfaceExists
        this.didOpenFfiDeclarationRunwayAsPlanningOnly =
            didOpenFfiDeclarationRunwayAsPlanningOnly
        this.didKeepFfiSyntaxUnwritten = didKeepFfiSyntaxUnwritten
        this.didKeepFfiDeclarationIntentDehydrated =
            didKeepFfiDeclarationIntentDehydrated
        this.didAvoidFfiPermissionWrapper = didAvoidFfiPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererInternalCallableDeclarationPolicy {
    let ffiDeclarationIntent:
        CjguiInternalRendererNativeBridgeFfiDeclarationIntent
    let didPrepareRendererInternalCallableDeclarationPolicy: Bool
    let shouldDeferRendererInternalCallableDeclarationPolicy: Bool
    let shouldReportRendererInternalCallableDeclarationPolicyBlocked: Bool
    let didPreserveRendererNativeBridgeFfiDeclarationIntent: Bool
    let didRequireInternalOnlyDeclarationPolicy: Bool
    let didRequireNoPublicApiExposure: Bool
    let didLimitDeclarationToNoResourceCallables: Bool
    let didDenyResourceCallableDeclaration: Bool
    let didKeepCallableDeclarationPolicyDehydrated: Bool
    let didAvoidRuntimeCallablePermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        ffiDeclarationIntent:
            CjguiInternalRendererNativeBridgeFfiDeclarationIntent,
        didPrepareRendererInternalCallableDeclarationPolicy: Bool,
        shouldDeferRendererInternalCallableDeclarationPolicy: Bool,
        shouldReportRendererInternalCallableDeclarationPolicyBlocked:
            Bool,
        didPreserveRendererNativeBridgeFfiDeclarationIntent: Bool,
        didRequireInternalOnlyDeclarationPolicy: Bool,
        didRequireNoPublicApiExposure: Bool,
        didLimitDeclarationToNoResourceCallables: Bool,
        didDenyResourceCallableDeclaration: Bool,
        didKeepCallableDeclarationPolicyDehydrated: Bool,
        didAvoidRuntimeCallablePermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.ffiDeclarationIntent = ffiDeclarationIntent
        this.didPrepareRendererInternalCallableDeclarationPolicy =
            didPrepareRendererInternalCallableDeclarationPolicy
        this.shouldDeferRendererInternalCallableDeclarationPolicy =
            shouldDeferRendererInternalCallableDeclarationPolicy
        this.shouldReportRendererInternalCallableDeclarationPolicyBlocked =
            shouldReportRendererInternalCallableDeclarationPolicyBlocked
        this.didPreserveRendererNativeBridgeFfiDeclarationIntent =
            didPreserveRendererNativeBridgeFfiDeclarationIntent
        this.didRequireInternalOnlyDeclarationPolicy =
            didRequireInternalOnlyDeclarationPolicy
        this.didRequireNoPublicApiExposure = didRequireNoPublicApiExposure
        this.didLimitDeclarationToNoResourceCallables =
            didLimitDeclarationToNoResourceCallables
        this.didDenyResourceCallableDeclaration =
            didDenyResourceCallableDeclaration
        this.didKeepCallableDeclarationPolicyDehydrated =
            didKeepCallableDeclarationPolicyDehydrated
        this.didAvoidRuntimeCallablePermissionWrapper =
            didAvoidRuntimeCallablePermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoResourceCallableAllowlist {
    let declarationPolicy:
        CjguiInternalRendererInternalCallableDeclarationPolicy
    let didPrepareRendererNoResourceCallableAllowlist: Bool
    let shouldDeferRendererNoResourceCallableAllowlist: Bool
    let shouldReportRendererNoResourceCallableAllowlistBlocked: Bool
    let didPreserveRendererInternalCallableDeclarationPolicy: Bool
    let didAllowSurfaceVersionCallable: Bool
    let didAllowSurfaceCapabilitiesCallable: Bool
    let didAllowStatusOkCallable: Bool
    let didAllowNoResourceAdmissionCallable: Bool
    let didDeferMainThreadCallable: Bool
    let didDenyPointerHandleOrTokenReturn: Bool
    let didKeepNoResourceCallableAllowlistDehydrated: Bool
    let didAvoidCallableReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        declarationPolicy:
            CjguiInternalRendererInternalCallableDeclarationPolicy,
        didPrepareRendererNoResourceCallableAllowlist: Bool,
        shouldDeferRendererNoResourceCallableAllowlist: Bool,
        shouldReportRendererNoResourceCallableAllowlistBlocked: Bool,
        didPreserveRendererInternalCallableDeclarationPolicy: Bool,
        didAllowSurfaceVersionCallable: Bool,
        didAllowSurfaceCapabilitiesCallable: Bool,
        didAllowStatusOkCallable: Bool,
        didAllowNoResourceAdmissionCallable: Bool,
        didDeferMainThreadCallable: Bool,
        didDenyPointerHandleOrTokenReturn: Bool,
        didKeepNoResourceCallableAllowlistDehydrated: Bool,
        didAvoidCallableReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.declarationPolicy = declarationPolicy
        this.didPrepareRendererNoResourceCallableAllowlist =
            didPrepareRendererNoResourceCallableAllowlist
        this.shouldDeferRendererNoResourceCallableAllowlist =
            shouldDeferRendererNoResourceCallableAllowlist
        this.shouldReportRendererNoResourceCallableAllowlistBlocked =
            shouldReportRendererNoResourceCallableAllowlistBlocked
        this.didPreserveRendererInternalCallableDeclarationPolicy =
            didPreserveRendererInternalCallableDeclarationPolicy
        this.didAllowSurfaceVersionCallable = didAllowSurfaceVersionCallable
        this.didAllowSurfaceCapabilitiesCallable =
            didAllowSurfaceCapabilitiesCallable
        this.didAllowStatusOkCallable = didAllowStatusOkCallable
        this.didAllowNoResourceAdmissionCallable =
            didAllowNoResourceAdmissionCallable
        this.didDeferMainThreadCallable = didDeferMainThreadCallable
        this.didDenyPointerHandleOrTokenReturn =
            didDenyPointerHandleOrTokenReturn
        this.didKeepNoResourceCallableAllowlistDehydrated =
            didKeepNoResourceCallableAllowlistDehydrated
        this.didAvoidCallableReadyWrapper = didAvoidCallableReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeBridgeLinkSeparationFallbackPolicy {
    let callableAllowlist: CjguiInternalRendererNoResourceCallableAllowlist
    let didPrepareRendererNativeBridgeLinkSeparationFallbackPolicy: Bool
    let shouldDeferRendererNativeBridgeLinkSeparationFallbackPolicy: Bool
    let shouldReportRendererNativeBridgeLinkSeparationFallbackPolicyBlocked:
        Bool
    let didPreserveRendererNoResourceCallableAllowlist: Bool
    let didConfirmCjpmNativeSourceStillSeparated: Bool
    let didRequireFfiSyntaxLinkPreflightBeforeDeclaration: Bool
    let didRequireNativeSymbolProbeBeforeRuntimeCall: Bool
    let didDenyRuntimeCallThisStage: Bool
    let didKeepLinkSeparationFallbackPolicyDehydrated: Bool
    let didAvoidLinkReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        callableAllowlist: CjguiInternalRendererNoResourceCallableAllowlist,
        didPrepareRendererNativeBridgeLinkSeparationFallbackPolicy: Bool,
        shouldDeferRendererNativeBridgeLinkSeparationFallbackPolicy: Bool,
        shouldReportRendererNativeBridgeLinkSeparationFallbackPolicyBlocked:
            Bool,
        didPreserveRendererNoResourceCallableAllowlist: Bool,
        didConfirmCjpmNativeSourceStillSeparated: Bool,
        didRequireFfiSyntaxLinkPreflightBeforeDeclaration: Bool,
        didRequireNativeSymbolProbeBeforeRuntimeCall: Bool,
        didDenyRuntimeCallThisStage: Bool,
        didKeepLinkSeparationFallbackPolicyDehydrated: Bool,
        didAvoidLinkReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.callableAllowlist = callableAllowlist
        this.didPrepareRendererNativeBridgeLinkSeparationFallbackPolicy =
            didPrepareRendererNativeBridgeLinkSeparationFallbackPolicy
        this.shouldDeferRendererNativeBridgeLinkSeparationFallbackPolicy =
            shouldDeferRendererNativeBridgeLinkSeparationFallbackPolicy
        this
            .shouldReportRendererNativeBridgeLinkSeparationFallbackPolicyBlocked =
            shouldReportRendererNativeBridgeLinkSeparationFallbackPolicyBlocked
        this.didPreserveRendererNoResourceCallableAllowlist =
            didPreserveRendererNoResourceCallableAllowlist
        this.didConfirmCjpmNativeSourceStillSeparated =
            didConfirmCjpmNativeSourceStillSeparated
        this.didRequireFfiSyntaxLinkPreflightBeforeDeclaration =
            didRequireFfiSyntaxLinkPreflightBeforeDeclaration
        this.didRequireNativeSymbolProbeBeforeRuntimeCall =
            didRequireNativeSymbolProbeBeforeRuntimeCall
        this.didDenyRuntimeCallThisStage = didDenyRuntimeCallThisStage
        this.didKeepLinkSeparationFallbackPolicyDehydrated =
            didKeepLinkSeparationFallbackPolicyDehydrated
        this.didAvoidLinkReadyWrapper = didAvoidLinkReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness {
    let linkSeparationFallbackPolicy:
        CjguiInternalRendererNativeBridgeLinkSeparationFallbackPolicy
    let didPrepareRendererNoNativeBridgeFfiDeclarationReadiness: Bool
    let didConfirmRendererNoNativeBridgeFfiDeclarationReadiness: Bool
    let shouldDeferRendererNoNativeBridgeFfiDeclarationReadiness: Bool
    let shouldReportRendererNoNativeBridgeFfiDeclarationReadinessBlocked:
        Bool
    let didPreserveRendererNativeBridgeLinkSeparationFallbackPolicy: Bool
    let didConfirmNoActualRuntimeFfiDeclaration: Bool
    let didConfirmNoBuildConfigModification: Bool
    let didConfirmNoPublicApiOrDiagnostics: Bool
    let didConfirmNoNativeObjectHandleOrPointer: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoNativeBridgeFfiDeclarationReadinessDehydrated: Bool
    let didAvoidFfiReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        linkSeparationFallbackPolicy:
            CjguiInternalRendererNativeBridgeLinkSeparationFallbackPolicy,
        didPrepareRendererNoNativeBridgeFfiDeclarationReadiness: Bool,
        didConfirmRendererNoNativeBridgeFfiDeclarationReadiness: Bool,
        shouldDeferRendererNoNativeBridgeFfiDeclarationReadiness: Bool,
        shouldReportRendererNoNativeBridgeFfiDeclarationReadinessBlocked:
            Bool,
        didPreserveRendererNativeBridgeLinkSeparationFallbackPolicy: Bool,
        didConfirmNoActualRuntimeFfiDeclaration: Bool,
        didConfirmNoBuildConfigModification: Bool,
        didConfirmNoPublicApiOrDiagnostics: Bool,
        didConfirmNoNativeObjectHandleOrPointer: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoNativeBridgeFfiDeclarationReadinessDehydrated: Bool,
        didAvoidFfiReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.linkSeparationFallbackPolicy = linkSeparationFallbackPolicy
        this.didPrepareRendererNoNativeBridgeFfiDeclarationReadiness =
            didPrepareRendererNoNativeBridgeFfiDeclarationReadiness
        this.didConfirmRendererNoNativeBridgeFfiDeclarationReadiness =
            didConfirmRendererNoNativeBridgeFfiDeclarationReadiness
        this.shouldDeferRendererNoNativeBridgeFfiDeclarationReadiness =
            shouldDeferRendererNoNativeBridgeFfiDeclarationReadiness
        this
            .shouldReportRendererNoNativeBridgeFfiDeclarationReadinessBlocked =
            shouldReportRendererNoNativeBridgeFfiDeclarationReadinessBlocked
        this.didPreserveRendererNativeBridgeLinkSeparationFallbackPolicy =
            didPreserveRendererNativeBridgeLinkSeparationFallbackPolicy
        this.didConfirmNoActualRuntimeFfiDeclaration =
            didConfirmNoActualRuntimeFfiDeclaration
        this.didConfirmNoBuildConfigModification =
            didConfirmNoBuildConfigModification
        this.didConfirmNoPublicApiOrDiagnostics =
            didConfirmNoPublicApiOrDiagnostics
        this.didConfirmNoNativeObjectHandleOrPointer =
            didConfirmNoNativeObjectHandleOrPointer
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNoNativeBridgeFfiDeclarationReadinessDehydrated =
            didKeepNoNativeBridgeFfiDeclarationReadinessDehydrated
        this.didAvoidFfiReadyWrapper = didAvoidFfiReadyWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererNativeBridgeFfiDeclarationIntent(
    noCallableCAbiReadiness: CjguiInternalRendererNoCallableCAbiReadiness
): CjguiInternalRendererNativeBridgeFfiDeclarationIntent {
    let upstreamReady =
        noCallableCAbiReadiness.didConfirmRendererNoCallableCAbiReadiness &&
        noCallableCAbiReadiness.shouldDeferRendererNoCallableCAbiReadiness ==
            false &&
        noCallableCAbiReadiness
            .shouldReportRendererNoCallableCAbiReadinessBlocked == false
    let upstreamDeferred =
        noCallableCAbiReadiness.shouldDeferRendererNoCallableCAbiReadiness &&
        noCallableCAbiReadiness
            .shouldReportRendererNoCallableCAbiReadinessBlocked == false
    let upstreamInconsistent =
        noCallableCAbiReadiness
            .shouldReportRendererNoCallableCAbiReadinessBlocked ||
        (
            noCallableCAbiReadiness
                .didPrepareRendererNoCallableCAbiReadiness &&
            upstreamReady == false &&
            upstreamDeferred == false
        )

    return CjguiInternalRendererNativeBridgeFfiDeclarationIntent(
        noCallableCAbiReadiness,
        upstreamReady,
        upstreamDeferred,
        upstreamInconsistent,
        upstreamReady,
        upstreamReady,
        upstreamReady,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererInternalCallableDeclarationPolicy(
    ffiDeclarationIntent:
        CjguiInternalRendererNativeBridgeFfiDeclarationIntent
): CjguiInternalRendererInternalCallableDeclarationPolicy {
    let proofReady =
        ffiDeclarationIntent
            .didPrepareRendererNativeBridgeFfiDeclarationIntent &&
        ffiDeclarationIntent.didPreserveRendererNoCallableCAbiReadiness &&
        ffiDeclarationIntent.didConfirmNoResourceCallableSurfaceExists &&
        ffiDeclarationIntent.didOpenFfiDeclarationRunwayAsPlanningOnly &&
        ffiDeclarationIntent.didKeepFfiSyntaxUnwritten &&
        ffiDeclarationIntent.didKeepFfiDeclarationIntentDehydrated &&
        ffiDeclarationIntent.didAvoidFfiPermissionWrapper &&
        ffiDeclarationIntent.didAvoidThinWrapper &&
        ffiDeclarationIntent
            .shouldDeferRendererNativeBridgeFfiDeclarationIntent == false &&
        ffiDeclarationIntent
            .shouldReportRendererNativeBridgeFfiDeclarationIntentBlocked ==
            false
    let proofDeferred =
        ffiDeclarationIntent
            .didPrepareRendererNativeBridgeFfiDeclarationIntent == false &&
        ffiDeclarationIntent
            .shouldDeferRendererNativeBridgeFfiDeclarationIntent &&
        ffiDeclarationIntent
            .shouldReportRendererNativeBridgeFfiDeclarationIntentBlocked ==
            false
    let proofInconsistent =
        ffiDeclarationIntent
            .shouldReportRendererNativeBridgeFfiDeclarationIntentBlocked ||
        (
            ffiDeclarationIntent
                .didPrepareRendererNativeBridgeFfiDeclarationIntent &&
            proofReady == false
        )

    return CjguiInternalRendererInternalCallableDeclarationPolicy(
        ffiDeclarationIntent,
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

func cjguiInternalBuildRendererNoResourceCallableAllowlist(
    declarationPolicy:
        CjguiInternalRendererInternalCallableDeclarationPolicy
): CjguiInternalRendererNoResourceCallableAllowlist {
    let proofReady =
        declarationPolicy
            .didPrepareRendererInternalCallableDeclarationPolicy &&
        declarationPolicy
            .didPreserveRendererNativeBridgeFfiDeclarationIntent &&
        declarationPolicy.didRequireInternalOnlyDeclarationPolicy &&
        declarationPolicy.didRequireNoPublicApiExposure &&
        declarationPolicy.didLimitDeclarationToNoResourceCallables &&
        declarationPolicy.didDenyResourceCallableDeclaration &&
        declarationPolicy.didKeepCallableDeclarationPolicyDehydrated &&
        declarationPolicy.didAvoidRuntimeCallablePermissionWrapper &&
        declarationPolicy.didAvoidThinWrapper &&
        declarationPolicy
            .shouldDeferRendererInternalCallableDeclarationPolicy == false &&
        declarationPolicy
            .shouldReportRendererInternalCallableDeclarationPolicyBlocked ==
            false
    let proofDeferred =
        declarationPolicy
            .didPrepareRendererInternalCallableDeclarationPolicy == false &&
        declarationPolicy
            .shouldDeferRendererInternalCallableDeclarationPolicy &&
        declarationPolicy
            .shouldReportRendererInternalCallableDeclarationPolicyBlocked ==
            false
    let proofInconsistent =
        declarationPolicy
            .shouldReportRendererInternalCallableDeclarationPolicyBlocked ||
        (
            declarationPolicy
                .didPrepareRendererInternalCallableDeclarationPolicy &&
            proofReady == false
        )

    return CjguiInternalRendererNoResourceCallableAllowlist(
        declarationPolicy,
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

func cjguiInternalBuildRendererNativeBridgeLinkSeparationFallbackPolicy(
    callableAllowlist: CjguiInternalRendererNoResourceCallableAllowlist
): CjguiInternalRendererNativeBridgeLinkSeparationFallbackPolicy {
    let proofReady =
        callableAllowlist.didPrepareRendererNoResourceCallableAllowlist &&
        callableAllowlist
            .didPreserveRendererInternalCallableDeclarationPolicy &&
        callableAllowlist.didAllowSurfaceVersionCallable &&
        callableAllowlist.didAllowSurfaceCapabilitiesCallable &&
        callableAllowlist.didAllowStatusOkCallable &&
        callableAllowlist.didAllowNoResourceAdmissionCallable &&
        callableAllowlist.didDeferMainThreadCallable &&
        callableAllowlist.didDenyPointerHandleOrTokenReturn &&
        callableAllowlist.didKeepNoResourceCallableAllowlistDehydrated &&
        callableAllowlist.didAvoidCallableReadyWrapper &&
        callableAllowlist.didAvoidThinWrapper &&
        callableAllowlist.shouldDeferRendererNoResourceCallableAllowlist ==
            false &&
        callableAllowlist
            .shouldReportRendererNoResourceCallableAllowlistBlocked ==
            false
    let proofDeferred =
        callableAllowlist.didPrepareRendererNoResourceCallableAllowlist ==
            false &&
        callableAllowlist.shouldDeferRendererNoResourceCallableAllowlist &&
        callableAllowlist
            .shouldReportRendererNoResourceCallableAllowlistBlocked ==
            false
    let proofInconsistent =
        callableAllowlist
            .shouldReportRendererNoResourceCallableAllowlistBlocked ||
        (
            callableAllowlist.didPrepareRendererNoResourceCallableAllowlist &&
            proofReady == false
        )

    return CjguiInternalRendererNativeBridgeLinkSeparationFallbackPolicy(
        callableAllowlist,
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

func cjguiInternalBuildRendererNoNativeBridgeFfiDeclarationReadiness(
    linkSeparationFallbackPolicy:
        CjguiInternalRendererNativeBridgeLinkSeparationFallbackPolicy
): CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness {
    let proofReady =
        linkSeparationFallbackPolicy
            .didPrepareRendererNativeBridgeLinkSeparationFallbackPolicy &&
        linkSeparationFallbackPolicy
            .didPreserveRendererNoResourceCallableAllowlist &&
        linkSeparationFallbackPolicy.didConfirmCjpmNativeSourceStillSeparated &&
        linkSeparationFallbackPolicy
            .didRequireFfiSyntaxLinkPreflightBeforeDeclaration &&
        linkSeparationFallbackPolicy
            .didRequireNativeSymbolProbeBeforeRuntimeCall &&
        linkSeparationFallbackPolicy.didDenyRuntimeCallThisStage &&
        linkSeparationFallbackPolicy
            .didKeepLinkSeparationFallbackPolicyDehydrated &&
        linkSeparationFallbackPolicy.didAvoidLinkReadyWrapper &&
        linkSeparationFallbackPolicy.didAvoidThinWrapper &&
        linkSeparationFallbackPolicy
            .shouldDeferRendererNativeBridgeLinkSeparationFallbackPolicy ==
            false &&
        linkSeparationFallbackPolicy
            .shouldReportRendererNativeBridgeLinkSeparationFallbackPolicyBlocked ==
            false
    let proofDeferred =
        linkSeparationFallbackPolicy
            .didPrepareRendererNativeBridgeLinkSeparationFallbackPolicy ==
            false &&
        linkSeparationFallbackPolicy
            .shouldDeferRendererNativeBridgeLinkSeparationFallbackPolicy &&
        linkSeparationFallbackPolicy
            .shouldReportRendererNativeBridgeLinkSeparationFallbackPolicyBlocked ==
            false
    let proofInconsistent =
        linkSeparationFallbackPolicy
            .shouldReportRendererNativeBridgeLinkSeparationFallbackPolicyBlocked ||
        (
            linkSeparationFallbackPolicy
                .didPrepareRendererNativeBridgeLinkSeparationFallbackPolicy &&
            proofReady == false
        )

    return CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness(
        linkSeparationFallbackPolicy,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererNativeBridgeFfiDeclarationDraft():
    CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness {
    let callableCAbiReadiness =
        cjguiInternalExecuteDefaultRendererCallableCAbiDraft()
    let ffiDeclarationIntent =
        cjguiInternalBuildRendererNativeBridgeFfiDeclarationIntent(
            callableCAbiReadiness
        )
    let declarationPolicy =
        cjguiInternalBuildRendererInternalCallableDeclarationPolicy(
            ffiDeclarationIntent
        )
    let callableAllowlist =
        cjguiInternalBuildRendererNoResourceCallableAllowlist(
            declarationPolicy
        )
    let linkSeparationFallbackPolicy =
        cjguiInternalBuildRendererNativeBridgeLinkSeparationFallbackPolicy(
            callableAllowlist
        )

    return cjguiInternalBuildRendererNoNativeBridgeFfiDeclarationReadiness(
        linkSeparationFallbackPolicy
    )
}
