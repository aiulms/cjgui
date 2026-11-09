// Owner: native bridge runtime internal FFI declaration first slice.
// Truth: 只消费 CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness，
// 并声明四个 internal-only no-resource foreign func；当前只记录 declaration
// allowlist、package link requirement 与 no-runtime-call readiness facts。
// Stop-line: 不调用 FFI，不扩 public API，不接 resource callable，不创建
// native object / handle / pointer，不改 runtime_state.cj，不把 declaration
// 解释成 backend-ready truth。
// Same-shape Boundary Brake: 不得把本 declaration first slice 包成 runtime-call
// permission、public API、native object、Metal/AppKit、backend-ready、receipt、
// record 或 publication wrapper。
package cjgui

foreign func cjgui_native_bridge_surface_version(): UInt32
foreign func cjgui_native_bridge_surface_capabilities(): UInt32
foreign func cjgui_native_bridge_status_ok(): UInt32
foreign func cjgui_native_bridge_no_resource_admission(): UInt32

struct CjguiInternalRendererNativeBridgeRuntimeFfiDeclarationIntent {
    let cjpmPackageLinkReadiness:
        CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness
    let didPrepareRendererNativeBridgeRuntimeFfiDeclarationIntent: Bool
    let shouldDeferRendererNativeBridgeRuntimeFfiDeclarationIntent: Bool
    let shouldReportRendererNativeBridgeRuntimeFfiDeclarationIntentBlocked:
        Bool
    let didPreserveRendererNativeBridgeCjpmPackageLinkReadiness: Bool
    let didConfirmScriptManagedPackageLinkEvidence: Bool
    let didDeclareInternalNoResourceForeignFuncs: Bool
    let didAcknowledgeRuntimePackageConfigStillDeferred: Bool
    let didKeepRuntimeFfiDeclarationIntentDehydrated: Bool
    let didAvoidRuntimeCallPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        cjpmPackageLinkReadiness:
            CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness,
        didPrepareRendererNativeBridgeRuntimeFfiDeclarationIntent: Bool,
        shouldDeferRendererNativeBridgeRuntimeFfiDeclarationIntent: Bool,
        shouldReportRendererNativeBridgeRuntimeFfiDeclarationIntentBlocked:
            Bool,
        didPreserveRendererNativeBridgeCjpmPackageLinkReadiness: Bool,
        didConfirmScriptManagedPackageLinkEvidence: Bool,
        didDeclareInternalNoResourceForeignFuncs: Bool,
        didAcknowledgeRuntimePackageConfigStillDeferred: Bool,
        didKeepRuntimeFfiDeclarationIntentDehydrated: Bool,
        didAvoidRuntimeCallPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.cjpmPackageLinkReadiness = cjpmPackageLinkReadiness
        this.didPrepareRendererNativeBridgeRuntimeFfiDeclarationIntent =
            didPrepareRendererNativeBridgeRuntimeFfiDeclarationIntent
        this.shouldDeferRendererNativeBridgeRuntimeFfiDeclarationIntent =
            shouldDeferRendererNativeBridgeRuntimeFfiDeclarationIntent
        this
            .shouldReportRendererNativeBridgeRuntimeFfiDeclarationIntentBlocked =
            shouldReportRendererNativeBridgeRuntimeFfiDeclarationIntentBlocked
        this.didPreserveRendererNativeBridgeCjpmPackageLinkReadiness =
            didPreserveRendererNativeBridgeCjpmPackageLinkReadiness
        this.didConfirmScriptManagedPackageLinkEvidence =
            didConfirmScriptManagedPackageLinkEvidence
        this.didDeclareInternalNoResourceForeignFuncs =
            didDeclareInternalNoResourceForeignFuncs
        this.didAcknowledgeRuntimePackageConfigStillDeferred =
            didAcknowledgeRuntimePackageConfigStillDeferred
        this.didKeepRuntimeFfiDeclarationIntentDehydrated =
            didKeepRuntimeFfiDeclarationIntentDehydrated
        this.didAvoidRuntimeCallPermissionWrapper =
            didAvoidRuntimeCallPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeBridgeRuntimeFfiDeclarationPolicy {
    let declarationIntent:
        CjguiInternalRendererNativeBridgeRuntimeFfiDeclarationIntent
    let didPrepareRendererNativeBridgeRuntimeFfiDeclarationPolicy: Bool
    let shouldDeferRendererNativeBridgeRuntimeFfiDeclarationPolicy: Bool
    let shouldReportRendererNativeBridgeRuntimeFfiDeclarationPolicyBlocked:
        Bool
    let didPreserveRendererNativeBridgeRuntimeFfiDeclarationIntent: Bool
    let didUseForeignFuncSyntaxEvidence: Bool
    let didAllowSurfaceVersionDeclaration: Bool
    let didAllowSurfaceCapabilitiesDeclaration: Bool
    let didAllowStatusOkDeclaration: Bool
    let didAllowNoResourceAdmissionDeclaration: Bool
    let didDenyResourceCallableDeclaration: Bool
    let didDenyPointerHandleOrTokenReturn: Bool
    let didRequirePackageLinkBeforeRuntimeCall: Bool
    let didKeepRuntimeFfiDeclarationPolicyDehydrated: Bool
    let didAvoidPublicApiWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        declarationIntent:
            CjguiInternalRendererNativeBridgeRuntimeFfiDeclarationIntent,
        didPrepareRendererNativeBridgeRuntimeFfiDeclarationPolicy: Bool,
        shouldDeferRendererNativeBridgeRuntimeFfiDeclarationPolicy: Bool,
        shouldReportRendererNativeBridgeRuntimeFfiDeclarationPolicyBlocked:
            Bool,
        didPreserveRendererNativeBridgeRuntimeFfiDeclarationIntent: Bool,
        didUseForeignFuncSyntaxEvidence: Bool,
        didAllowSurfaceVersionDeclaration: Bool,
        didAllowSurfaceCapabilitiesDeclaration: Bool,
        didAllowStatusOkDeclaration: Bool,
        didAllowNoResourceAdmissionDeclaration: Bool,
        didDenyResourceCallableDeclaration: Bool,
        didDenyPointerHandleOrTokenReturn: Bool,
        didRequirePackageLinkBeforeRuntimeCall: Bool,
        didKeepRuntimeFfiDeclarationPolicyDehydrated: Bool,
        didAvoidPublicApiWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.declarationIntent = declarationIntent
        this.didPrepareRendererNativeBridgeRuntimeFfiDeclarationPolicy =
            didPrepareRendererNativeBridgeRuntimeFfiDeclarationPolicy
        this.shouldDeferRendererNativeBridgeRuntimeFfiDeclarationPolicy =
            shouldDeferRendererNativeBridgeRuntimeFfiDeclarationPolicy
        this
            .shouldReportRendererNativeBridgeRuntimeFfiDeclarationPolicyBlocked =
            shouldReportRendererNativeBridgeRuntimeFfiDeclarationPolicyBlocked
        this.didPreserveRendererNativeBridgeRuntimeFfiDeclarationIntent =
            didPreserveRendererNativeBridgeRuntimeFfiDeclarationIntent
        this.didUseForeignFuncSyntaxEvidence =
            didUseForeignFuncSyntaxEvidence
        this.didAllowSurfaceVersionDeclaration =
            didAllowSurfaceVersionDeclaration
        this.didAllowSurfaceCapabilitiesDeclaration =
            didAllowSurfaceCapabilitiesDeclaration
        this.didAllowStatusOkDeclaration = didAllowStatusOkDeclaration
        this.didAllowNoResourceAdmissionDeclaration =
            didAllowNoResourceAdmissionDeclaration
        this.didDenyResourceCallableDeclaration =
            didDenyResourceCallableDeclaration
        this.didDenyPointerHandleOrTokenReturn =
            didDenyPointerHandleOrTokenReturn
        this.didRequirePackageLinkBeforeRuntimeCall =
            didRequirePackageLinkBeforeRuntimeCall
        this.didKeepRuntimeFfiDeclarationPolicyDehydrated =
            didKeepRuntimeFfiDeclarationPolicyDehydrated
        this.didAvoidPublicApiWrapper = didAvoidPublicApiWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness {
    let declarationPolicy:
        CjguiInternalRendererNativeBridgeRuntimeFfiDeclarationPolicy
    let didPrepareRendererNoNativeBridgeRuntimeFfiCallReadiness: Bool
    let shouldDeferRendererNoNativeBridgeRuntimeFfiCallReadiness: Bool
    let shouldReportRendererNoNativeBridgeRuntimeFfiCallReadinessBlocked:
        Bool
    let didPreserveRendererNativeBridgeRuntimeFfiDeclarationPolicy: Bool
    let didConfirmInternalForeignDeclarationsPresent: Bool
    let didConfirmNoRuntimeFfiCall: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoResourceCallable: Bool
    let didConfirmNoNativeObjectHandleOrPointer: Bool
    let didConfirmNoMetalOrAppKitUsage: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoNativeBridgeRuntimeFfiCallReadinessDehydrated: Bool
    let didAvoidFfiCallReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        declarationPolicy:
            CjguiInternalRendererNativeBridgeRuntimeFfiDeclarationPolicy,
        didPrepareRendererNoNativeBridgeRuntimeFfiCallReadiness: Bool,
        shouldDeferRendererNoNativeBridgeRuntimeFfiCallReadiness: Bool,
        shouldReportRendererNoNativeBridgeRuntimeFfiCallReadinessBlocked:
            Bool,
        didPreserveRendererNativeBridgeRuntimeFfiDeclarationPolicy: Bool,
        didConfirmInternalForeignDeclarationsPresent: Bool,
        didConfirmNoRuntimeFfiCall: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoResourceCallable: Bool,
        didConfirmNoNativeObjectHandleOrPointer: Bool,
        didConfirmNoMetalOrAppKitUsage: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoNativeBridgeRuntimeFfiCallReadinessDehydrated: Bool,
        didAvoidFfiCallReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.declarationPolicy = declarationPolicy
        this.didPrepareRendererNoNativeBridgeRuntimeFfiCallReadiness =
            didPrepareRendererNoNativeBridgeRuntimeFfiCallReadiness
        this.shouldDeferRendererNoNativeBridgeRuntimeFfiCallReadiness =
            shouldDeferRendererNoNativeBridgeRuntimeFfiCallReadiness
        this
            .shouldReportRendererNoNativeBridgeRuntimeFfiCallReadinessBlocked =
            shouldReportRendererNoNativeBridgeRuntimeFfiCallReadinessBlocked
        this.didPreserveRendererNativeBridgeRuntimeFfiDeclarationPolicy =
            didPreserveRendererNativeBridgeRuntimeFfiDeclarationPolicy
        this.didConfirmInternalForeignDeclarationsPresent =
            didConfirmInternalForeignDeclarationsPresent
        this.didConfirmNoRuntimeFfiCall = didConfirmNoRuntimeFfiCall
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoResourceCallable = didConfirmNoResourceCallable
        this.didConfirmNoNativeObjectHandleOrPointer =
            didConfirmNoNativeObjectHandleOrPointer
        this.didConfirmNoMetalOrAppKitUsage =
            didConfirmNoMetalOrAppKitUsage
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNoNativeBridgeRuntimeFfiCallReadinessDehydrated =
            didKeepNoNativeBridgeRuntimeFfiCallReadinessDehydrated
        this.didAvoidFfiCallReadyWrapper = didAvoidFfiCallReadyWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererNativeBridgeRuntimeFfiDeclarationReadiness(
    cjpmPackageLinkReadiness:
        CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness,
    didConfirmInternalForeignDeclarationsPresent: Bool,
    didRequirePackageLinkBeforeRuntimeCall: Bool
): CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness {
    let packageEvidenceReady =
        cjpmPackageLinkReadiness
            .didPrepareRendererNoNativeBridgeCjpmPackageLinkReadiness &&
        cjpmPackageLinkReadiness.didConfirmNoRuntimeFfiCall &&
        cjpmPackageLinkReadiness.didConfirmNoPublicSurface &&
        cjpmPackageLinkReadiness.didConfirmNoResourceCallable &&
        cjpmPackageLinkReadiness.didConfirmNoNativeObjectCreation &&
        cjpmPackageLinkReadiness.didConfirmNoMetalOrAppKitUsage &&
        cjpmPackageLinkReadiness.didConfirmNoRendererStateWrite &&
        cjpmPackageLinkReadiness.didConfirmNoBackendReadyTruth
    let declarationReady =
        packageEvidenceReady &&
        didConfirmInternalForeignDeclarationsPresent &&
        didRequirePackageLinkBeforeRuntimeCall

    let intent =
        CjguiInternalRendererNativeBridgeRuntimeFfiDeclarationIntent(
            cjpmPackageLinkReadiness,
            declarationReady,
            !declarationReady,
            false,
            packageEvidenceReady,
            packageEvidenceReady,
            didConfirmInternalForeignDeclarationsPresent,
            didRequirePackageLinkBeforeRuntimeCall,
            true,
            true,
            true
        )
    let policy =
        CjguiInternalRendererNativeBridgeRuntimeFfiDeclarationPolicy(
            intent,
            declarationReady,
            !declarationReady,
            false,
            declarationReady,
            didConfirmInternalForeignDeclarationsPresent,
            didConfirmInternalForeignDeclarationsPresent,
            didConfirmInternalForeignDeclarationsPresent,
            didConfirmInternalForeignDeclarationsPresent,
            didConfirmInternalForeignDeclarationsPresent,
            true,
            true,
            didRequirePackageLinkBeforeRuntimeCall,
            true,
            true,
            true
        )

    return CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness(
        policy,
        declarationReady,
        !declarationReady,
        false,
        declarationReady,
        didConfirmInternalForeignDeclarationsPresent,
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

func cjguiInternalExecuteDefaultRendererNativeBridgeRuntimeFfiDeclarationDraft():
    CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness {
    let cjpmPackageLinkReadiness =
        cjguiInternalExecuteDefaultRendererNativeBridgeCjpmPackageLinkDraft()
    return cjguiInternalBuildRendererNativeBridgeRuntimeFfiDeclarationReadiness(
        cjpmPackageLinkReadiness,
        true,
        true
    )
}
