// Owner: native bridge build system integration implementation admission value boundary.
// Truth: 只消费 CjguiInternalRendererNoNativeBridgeBuildIntegrationReadiness，
// 并记录 build system implementation intent、macOS-only build gate admission、
// native source inclusion denial、Objective-C compile/link admission、
// framework link denial、failure classification 与 no-build-system-implementation facts。
// Stop-line: 只产出 internal-only dehydrated facts；不修改 build config，不接入
// production .m，不实现 C ABI / FFI，不创建 native object，不写 renderer state，
// 不发布 public API。
// Same-shape Boundary Brake: 不得把本 value boundary 包成 cjpm integration
// permission、callable surface、FFI、native-handle、Metal/AppKit、backend-ready、
// public API、receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererNativeBridgeBuildSystemImplementationIntent {
    let noNativeBridgeBuildIntegrationReadiness:
        CjguiInternalRendererNoNativeBridgeBuildIntegrationReadiness
    let didPrepareRendererNativeBridgeBuildSystemImplementationIntent:
        Bool
    let shouldDeferRendererNativeBridgeBuildSystemImplementationIntent:
        Bool
    let shouldReportRendererNativeBridgeBuildSystemImplementationIntentBlocked:
        Bool
    let didPreserveRendererNoNativeBridgeBuildIntegrationReadiness: Bool
    let didConfirmIsolatedProbeAsFeasibilityEvidenceOnly: Bool
    let didOpenBuildSystemAdmissionWithoutConfigChange: Bool
    let didKeepBuildSystemImplementationIntentDehydrated: Bool
    let didAvoidCjpmIntegrationPermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        noNativeBridgeBuildIntegrationReadiness:
            CjguiInternalRendererNoNativeBridgeBuildIntegrationReadiness,
        didPrepareRendererNativeBridgeBuildSystemImplementationIntent:
            Bool,
        shouldDeferRendererNativeBridgeBuildSystemImplementationIntent:
            Bool,
        shouldReportRendererNativeBridgeBuildSystemImplementationIntentBlocked:
            Bool,
        didPreserveRendererNoNativeBridgeBuildIntegrationReadiness: Bool,
        didConfirmIsolatedProbeAsFeasibilityEvidenceOnly: Bool,
        didOpenBuildSystemAdmissionWithoutConfigChange: Bool,
        didKeepBuildSystemImplementationIntentDehydrated: Bool,
        didAvoidCjpmIntegrationPermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noNativeBridgeBuildIntegrationReadiness =
            noNativeBridgeBuildIntegrationReadiness
        this
            .didPrepareRendererNativeBridgeBuildSystemImplementationIntent =
            didPrepareRendererNativeBridgeBuildSystemImplementationIntent
        this
            .shouldDeferRendererNativeBridgeBuildSystemImplementationIntent =
            shouldDeferRendererNativeBridgeBuildSystemImplementationIntent
        this
            .shouldReportRendererNativeBridgeBuildSystemImplementationIntentBlocked =
            shouldReportRendererNativeBridgeBuildSystemImplementationIntentBlocked
        this.didPreserveRendererNoNativeBridgeBuildIntegrationReadiness =
            didPreserveRendererNoNativeBridgeBuildIntegrationReadiness
        this.didConfirmIsolatedProbeAsFeasibilityEvidenceOnly =
            didConfirmIsolatedProbeAsFeasibilityEvidenceOnly
        this.didOpenBuildSystemAdmissionWithoutConfigChange =
            didOpenBuildSystemAdmissionWithoutConfigChange
        this.didKeepBuildSystemImplementationIntentDehydrated =
            didKeepBuildSystemImplementationIntentDehydrated
        this.didAvoidCjpmIntegrationPermissionWrapper =
            didAvoidCjpmIntegrationPermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeBridgeMacOSBuildGateAdmission {
    let implementationIntent:
        CjguiInternalRendererNativeBridgeBuildSystemImplementationIntent
    let didPrepareRendererNativeBridgeMacOSBuildGateAdmission: Bool
    let shouldDeferRendererNativeBridgeMacOSBuildGateAdmission: Bool
    let shouldReportRendererNativeBridgeMacOSBuildGateAdmissionBlocked:
        Bool
    let didPreserveRendererNativeBridgeBuildSystemImplementationIntent:
        Bool
    let didDefineMacOSOnlyBuildGateAdmission: Bool
    let didRequireNonMacOSFallbackPolicy: Bool
    let didRequireCiHeadlessPolicy: Bool
    let didConfirmNoPackageConfigModification: Bool
    let didKeepMacOSBuildGateAdmissionDehydrated: Bool
    let didAvoidBuildGatePermissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        implementationIntent:
            CjguiInternalRendererNativeBridgeBuildSystemImplementationIntent,
        didPrepareRendererNativeBridgeMacOSBuildGateAdmission: Bool,
        shouldDeferRendererNativeBridgeMacOSBuildGateAdmission: Bool,
        shouldReportRendererNativeBridgeMacOSBuildGateAdmissionBlocked:
            Bool,
        didPreserveRendererNativeBridgeBuildSystemImplementationIntent:
            Bool,
        didDefineMacOSOnlyBuildGateAdmission: Bool,
        didRequireNonMacOSFallbackPolicy: Bool,
        didRequireCiHeadlessPolicy: Bool,
        didConfirmNoPackageConfigModification: Bool,
        didKeepMacOSBuildGateAdmissionDehydrated: Bool,
        didAvoidBuildGatePermissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.implementationIntent = implementationIntent
        this.didPrepareRendererNativeBridgeMacOSBuildGateAdmission =
            didPrepareRendererNativeBridgeMacOSBuildGateAdmission
        this.shouldDeferRendererNativeBridgeMacOSBuildGateAdmission =
            shouldDeferRendererNativeBridgeMacOSBuildGateAdmission
        this
            .shouldReportRendererNativeBridgeMacOSBuildGateAdmissionBlocked =
            shouldReportRendererNativeBridgeMacOSBuildGateAdmissionBlocked
        this
            .didPreserveRendererNativeBridgeBuildSystemImplementationIntent =
            didPreserveRendererNativeBridgeBuildSystemImplementationIntent
        this.didDefineMacOSOnlyBuildGateAdmission =
            didDefineMacOSOnlyBuildGateAdmission
        this.didRequireNonMacOSFallbackPolicy =
            didRequireNonMacOSFallbackPolicy
        this.didRequireCiHeadlessPolicy = didRequireCiHeadlessPolicy
        this.didConfirmNoPackageConfigModification =
            didConfirmNoPackageConfigModification
        this.didKeepMacOSBuildGateAdmissionDehydrated =
            didKeepMacOSBuildGateAdmissionDehydrated
        this.didAvoidBuildGatePermissionWrapper =
            didAvoidBuildGatePermissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeBridgeNativeSourceInclusionDenialProof {
    let macOSBuildGateAdmission:
        CjguiInternalRendererNativeBridgeMacOSBuildGateAdmission
    let didPrepareRendererNativeBridgeNativeSourceInclusionDenialProof:
        Bool
    let shouldDeferRendererNativeBridgeNativeSourceInclusionDenialProof:
        Bool
    let shouldReportRendererNativeBridgeNativeSourceInclusionDenialProofBlocked:
        Bool
    let didPreserveRendererNativeBridgeMacOSBuildGateAdmission: Bool
    let didDenyProductionNativeSourceInclusion: Bool
    let didKeepProbeAndProductionBuildSeparated: Bool
    let didConfirmNoCjpmTomlModification: Bool
    let didConfirmNoBuildScriptModification: Bool
    let didKeepNativeSourceInclusionDenialProofDehydrated: Bool
    let didAvoidSourceIncludedWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        macOSBuildGateAdmission:
            CjguiInternalRendererNativeBridgeMacOSBuildGateAdmission,
        didPrepareRendererNativeBridgeNativeSourceInclusionDenialProof:
            Bool,
        shouldDeferRendererNativeBridgeNativeSourceInclusionDenialProof:
            Bool,
        shouldReportRendererNativeBridgeNativeSourceInclusionDenialProofBlocked:
            Bool,
        didPreserveRendererNativeBridgeMacOSBuildGateAdmission: Bool,
        didDenyProductionNativeSourceInclusion: Bool,
        didKeepProbeAndProductionBuildSeparated: Bool,
        didConfirmNoCjpmTomlModification: Bool,
        didConfirmNoBuildScriptModification: Bool,
        didKeepNativeSourceInclusionDenialProofDehydrated: Bool,
        didAvoidSourceIncludedWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.macOSBuildGateAdmission = macOSBuildGateAdmission
        this
            .didPrepareRendererNativeBridgeNativeSourceInclusionDenialProof =
            didPrepareRendererNativeBridgeNativeSourceInclusionDenialProof
        this
            .shouldDeferRendererNativeBridgeNativeSourceInclusionDenialProof =
            shouldDeferRendererNativeBridgeNativeSourceInclusionDenialProof
        this
            .shouldReportRendererNativeBridgeNativeSourceInclusionDenialProofBlocked =
            shouldReportRendererNativeBridgeNativeSourceInclusionDenialProofBlocked
        this.didPreserveRendererNativeBridgeMacOSBuildGateAdmission =
            didPreserveRendererNativeBridgeMacOSBuildGateAdmission
        this.didDenyProductionNativeSourceInclusion =
            didDenyProductionNativeSourceInclusion
        this.didKeepProbeAndProductionBuildSeparated =
            didKeepProbeAndProductionBuildSeparated
        this.didConfirmNoCjpmTomlModification =
            didConfirmNoCjpmTomlModification
        this.didConfirmNoBuildScriptModification =
            didConfirmNoBuildScriptModification
        this.didKeepNativeSourceInclusionDenialProofDehydrated =
            didKeepNativeSourceInclusionDenialProofDehydrated
        this.didAvoidSourceIncludedWrapper = didAvoidSourceIncludedWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy {
    let sourceInclusionDenialProof:
        CjguiInternalRendererNativeBridgeNativeSourceInclusionDenialProof
    let didPrepareRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy:
        Bool
    let shouldDeferRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy:
        Bool
    let shouldReportRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicyBlocked:
        Bool
    let didPreserveRendererNativeBridgeNativeSourceInclusionDenialProof:
        Bool
    let didDefineObjectiveCCompileLinkAdmissionPolicy: Bool
    let didRequireCompilerPathPolicy: Bool
    let didRequireSdkRootDiscoveryPolicy: Bool
    let didRequireDeploymentTargetPolicy: Bool
    let didKeepCompilerInvocationUnwired: Bool
    let didKeepObjectiveCCompileLinkAdmissionPolicyDehydrated: Bool
    let didAvoidCallableSurfaceWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        sourceInclusionDenialProof:
            CjguiInternalRendererNativeBridgeNativeSourceInclusionDenialProof,
        didPrepareRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy:
            Bool,
        shouldDeferRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy:
            Bool,
        shouldReportRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicyBlocked:
            Bool,
        didPreserveRendererNativeBridgeNativeSourceInclusionDenialProof:
            Bool,
        didDefineObjectiveCCompileLinkAdmissionPolicy: Bool,
        didRequireCompilerPathPolicy: Bool,
        didRequireSdkRootDiscoveryPolicy: Bool,
        didRequireDeploymentTargetPolicy: Bool,
        didKeepCompilerInvocationUnwired: Bool,
        didKeepObjectiveCCompileLinkAdmissionPolicyDehydrated: Bool,
        didAvoidCallableSurfaceWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.sourceInclusionDenialProof = sourceInclusionDenialProof
        this
            .didPrepareRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy =
            didPrepareRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy
        this
            .shouldDeferRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy =
            shouldDeferRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy
        this
            .shouldReportRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicyBlocked =
            shouldReportRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicyBlocked
        this
            .didPreserveRendererNativeBridgeNativeSourceInclusionDenialProof =
            didPreserveRendererNativeBridgeNativeSourceInclusionDenialProof
        this.didDefineObjectiveCCompileLinkAdmissionPolicy =
            didDefineObjectiveCCompileLinkAdmissionPolicy
        this.didRequireCompilerPathPolicy = didRequireCompilerPathPolicy
        this.didRequireSdkRootDiscoveryPolicy =
            didRequireSdkRootDiscoveryPolicy
        this.didRequireDeploymentTargetPolicy =
            didRequireDeploymentTargetPolicy
        this.didKeepCompilerInvocationUnwired =
            didKeepCompilerInvocationUnwired
        this.didKeepObjectiveCCompileLinkAdmissionPolicyDehydrated =
            didKeepObjectiveCCompileLinkAdmissionPolicyDehydrated
        this.didAvoidCallableSurfaceWrapper =
            didAvoidCallableSurfaceWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeBridgeFrameworkLinkDenialProof {
    let compileLinkAdmissionPolicy:
        CjguiInternalRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy
    let didPrepareRendererNativeBridgeFrameworkLinkDenialProof: Bool
    let shouldDeferRendererNativeBridgeFrameworkLinkDenialProof: Bool
    let shouldReportRendererNativeBridgeFrameworkLinkDenialProofBlocked:
        Bool
    let didPreserveRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy:
        Bool
    let didDenyImplicitFrameworkLinking: Bool
    let didRequireExplicitFrameworkListFuturePolicy: Bool
    let didConfirmNoPlatformFrameworkImportOrCall: Bool
    let didKeepFrameworkLinkUnwired: Bool
    let didKeepFrameworkLinkDenialProofDehydrated: Bool
    let didAvoidFrameworkReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        compileLinkAdmissionPolicy:
            CjguiInternalRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy,
        didPrepareRendererNativeBridgeFrameworkLinkDenialProof: Bool,
        shouldDeferRendererNativeBridgeFrameworkLinkDenialProof: Bool,
        shouldReportRendererNativeBridgeFrameworkLinkDenialProofBlocked:
            Bool,
        didPreserveRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy:
            Bool,
        didDenyImplicitFrameworkLinking: Bool,
        didRequireExplicitFrameworkListFuturePolicy: Bool,
        didConfirmNoPlatformFrameworkImportOrCall: Bool,
        didKeepFrameworkLinkUnwired: Bool,
        didKeepFrameworkLinkDenialProofDehydrated: Bool,
        didAvoidFrameworkReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.compileLinkAdmissionPolicy = compileLinkAdmissionPolicy
        this.didPrepareRendererNativeBridgeFrameworkLinkDenialProof =
            didPrepareRendererNativeBridgeFrameworkLinkDenialProof
        this.shouldDeferRendererNativeBridgeFrameworkLinkDenialProof =
            shouldDeferRendererNativeBridgeFrameworkLinkDenialProof
        this
            .shouldReportRendererNativeBridgeFrameworkLinkDenialProofBlocked =
            shouldReportRendererNativeBridgeFrameworkLinkDenialProofBlocked
        this
            .didPreserveRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy =
            didPreserveRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy
        this.didDenyImplicitFrameworkLinking =
            didDenyImplicitFrameworkLinking
        this.didRequireExplicitFrameworkListFuturePolicy =
            didRequireExplicitFrameworkListFuturePolicy
        this.didConfirmNoPlatformFrameworkImportOrCall =
            didConfirmNoPlatformFrameworkImportOrCall
        this.didKeepFrameworkLinkUnwired = didKeepFrameworkLinkUnwired
        this.didKeepFrameworkLinkDenialProofDehydrated =
            didKeepFrameworkLinkDenialProofDehydrated
        this.didAvoidFrameworkReadyWrapper = didAvoidFrameworkReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeBridgeBuildFailureClassification {
    let frameworkLinkDenialProof:
        CjguiInternalRendererNativeBridgeFrameworkLinkDenialProof
    let didPrepareRendererNativeBridgeBuildFailureClassification: Bool
    let shouldDeferRendererNativeBridgeBuildFailureClassification: Bool
    let shouldReportRendererNativeBridgeBuildFailureClassificationBlocked:
        Bool
    let didPreserveRendererNativeBridgeFrameworkLinkDenialProof: Bool
    let didClassifyMissingCompilerFailure: Bool
    let didClassifyMissingSdkRootFailure: Bool
    let didClassifyPackageIntegrationUnsupportedFailure: Bool
    let didClassifyNonMacOSFallbackFailure: Bool
    let didClassifyCiHeadlessFailure: Bool
    let didRequireFailClosedBuildSystemAdmission: Bool
    let didKeepBuildFailureClassificationDehydrated: Bool
    let didAvoidProbeSuccessAsIntegrationWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        frameworkLinkDenialProof:
            CjguiInternalRendererNativeBridgeFrameworkLinkDenialProof,
        didPrepareRendererNativeBridgeBuildFailureClassification: Bool,
        shouldDeferRendererNativeBridgeBuildFailureClassification: Bool,
        shouldReportRendererNativeBridgeBuildFailureClassificationBlocked:
            Bool,
        didPreserveRendererNativeBridgeFrameworkLinkDenialProof: Bool,
        didClassifyMissingCompilerFailure: Bool,
        didClassifyMissingSdkRootFailure: Bool,
        didClassifyPackageIntegrationUnsupportedFailure: Bool,
        didClassifyNonMacOSFallbackFailure: Bool,
        didClassifyCiHeadlessFailure: Bool,
        didRequireFailClosedBuildSystemAdmission: Bool,
        didKeepBuildFailureClassificationDehydrated: Bool,
        didAvoidProbeSuccessAsIntegrationWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.frameworkLinkDenialProof = frameworkLinkDenialProof
        this.didPrepareRendererNativeBridgeBuildFailureClassification =
            didPrepareRendererNativeBridgeBuildFailureClassification
        this.shouldDeferRendererNativeBridgeBuildFailureClassification =
            shouldDeferRendererNativeBridgeBuildFailureClassification
        this
            .shouldReportRendererNativeBridgeBuildFailureClassificationBlocked =
            shouldReportRendererNativeBridgeBuildFailureClassificationBlocked
        this.didPreserveRendererNativeBridgeFrameworkLinkDenialProof =
            didPreserveRendererNativeBridgeFrameworkLinkDenialProof
        this.didClassifyMissingCompilerFailure =
            didClassifyMissingCompilerFailure
        this.didClassifyMissingSdkRootFailure =
            didClassifyMissingSdkRootFailure
        this.didClassifyPackageIntegrationUnsupportedFailure =
            didClassifyPackageIntegrationUnsupportedFailure
        this.didClassifyNonMacOSFallbackFailure =
            didClassifyNonMacOSFallbackFailure
        this.didClassifyCiHeadlessFailure = didClassifyCiHeadlessFailure
        this.didRequireFailClosedBuildSystemAdmission =
            didRequireFailClosedBuildSystemAdmission
        this.didKeepBuildFailureClassificationDehydrated =
            didKeepBuildFailureClassificationDehydrated
        this.didAvoidProbeSuccessAsIntegrationWrapper =
            didAvoidProbeSuccessAsIntegrationWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoNativeBridgeBuildSystemImplementationReadiness {
    let buildFailureClassification:
        CjguiInternalRendererNativeBridgeBuildFailureClassification
    let didPrepareRendererNoNativeBridgeBuildSystemImplementationReadiness:
        Bool
    let didConfirmRendererNoNativeBridgeBuildSystemImplementationReadiness:
        Bool
    let shouldDeferRendererNoNativeBridgeBuildSystemImplementationReadiness:
        Bool
    let shouldReportRendererNoNativeBridgeBuildSystemImplementationReadinessBlocked:
        Bool
    let didPreserveRendererNativeBridgeBuildFailureClassification: Bool
    let didConfirmNoBuildConfigModification: Bool
    let didConfirmNoProductionNativeSourceIntegration: Bool
    let didConfirmNoCallableCAbiImplementation: Bool
    let didConfirmNoFfiDeclaration: Bool
    let didConfirmNoNativeObjectCreation: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoPublicApiOrDiagnostics: Bool
    let didKeepNoNativeBridgeBuildSystemImplementationReadinessDehydrated:
        Bool
    let didAvoidBuildSystemPermissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        buildFailureClassification:
            CjguiInternalRendererNativeBridgeBuildFailureClassification,
        didPrepareRendererNoNativeBridgeBuildSystemImplementationReadiness:
            Bool,
        didConfirmRendererNoNativeBridgeBuildSystemImplementationReadiness:
            Bool,
        shouldDeferRendererNoNativeBridgeBuildSystemImplementationReadiness:
            Bool,
        shouldReportRendererNoNativeBridgeBuildSystemImplementationReadinessBlocked:
            Bool,
        didPreserveRendererNativeBridgeBuildFailureClassification: Bool,
        didConfirmNoBuildConfigModification: Bool,
        didConfirmNoProductionNativeSourceIntegration: Bool,
        didConfirmNoCallableCAbiImplementation: Bool,
        didConfirmNoFfiDeclaration: Bool,
        didConfirmNoNativeObjectCreation: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoPublicApiOrDiagnostics: Bool,
        didKeepNoNativeBridgeBuildSystemImplementationReadinessDehydrated:
            Bool,
        didAvoidBuildSystemPermissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.buildFailureClassification = buildFailureClassification
        this
            .didPrepareRendererNoNativeBridgeBuildSystemImplementationReadiness =
            didPrepareRendererNoNativeBridgeBuildSystemImplementationReadiness
        this
            .didConfirmRendererNoNativeBridgeBuildSystemImplementationReadiness =
            didConfirmRendererNoNativeBridgeBuildSystemImplementationReadiness
        this
            .shouldDeferRendererNoNativeBridgeBuildSystemImplementationReadiness =
            shouldDeferRendererNoNativeBridgeBuildSystemImplementationReadiness
        this
            .shouldReportRendererNoNativeBridgeBuildSystemImplementationReadinessBlocked =
            shouldReportRendererNoNativeBridgeBuildSystemImplementationReadinessBlocked
        this.didPreserveRendererNativeBridgeBuildFailureClassification =
            didPreserveRendererNativeBridgeBuildFailureClassification
        this.didConfirmNoBuildConfigModification =
            didConfirmNoBuildConfigModification
        this.didConfirmNoProductionNativeSourceIntegration =
            didConfirmNoProductionNativeSourceIntegration
        this.didConfirmNoCallableCAbiImplementation =
            didConfirmNoCallableCAbiImplementation
        this.didConfirmNoFfiDeclaration = didConfirmNoFfiDeclaration
        this.didConfirmNoNativeObjectCreation =
            didConfirmNoNativeObjectCreation
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoPublicApiOrDiagnostics =
            didConfirmNoPublicApiOrDiagnostics
        this
            .didKeepNoNativeBridgeBuildSystemImplementationReadinessDehydrated =
            didKeepNoNativeBridgeBuildSystemImplementationReadinessDehydrated
        this.didAvoidBuildSystemPermissionWrapper =
            didAvoidBuildSystemPermissionWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererNativeBridgeBuildSystemImplementationIntent(
    noNativeBridgeBuildIntegrationReadiness:
        CjguiInternalRendererNoNativeBridgeBuildIntegrationReadiness
): CjguiInternalRendererNativeBridgeBuildSystemImplementationIntent {
    let upstreamReady =
        noNativeBridgeBuildIntegrationReadiness
            .didConfirmRendererNoNativeBridgeBuildIntegrationReadiness &&
        noNativeBridgeBuildIntegrationReadiness
            .shouldDeferRendererNoNativeBridgeBuildIntegrationReadiness ==
            false &&
        noNativeBridgeBuildIntegrationReadiness
            .shouldReportRendererNoNativeBridgeBuildIntegrationReadinessBlocked ==
            false
    let upstreamDeferred =
        noNativeBridgeBuildIntegrationReadiness
            .shouldDeferRendererNoNativeBridgeBuildIntegrationReadiness &&
        noNativeBridgeBuildIntegrationReadiness
            .shouldReportRendererNoNativeBridgeBuildIntegrationReadinessBlocked ==
            false
    let upstreamInconsistent =
        noNativeBridgeBuildIntegrationReadiness
            .shouldReportRendererNoNativeBridgeBuildIntegrationReadinessBlocked ||
        (
            noNativeBridgeBuildIntegrationReadiness
                .didPrepareRendererNoNativeBridgeBuildIntegrationReadiness &&
            upstreamReady == false &&
            upstreamDeferred == false
        )

    return CjguiInternalRendererNativeBridgeBuildSystemImplementationIntent(
        noNativeBridgeBuildIntegrationReadiness,
        upstreamReady,
        upstreamDeferred,
        upstreamInconsistent,
        upstreamReady,
        true,
        upstreamReady,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererNativeBridgeMacOSBuildGateAdmission(
    implementationIntent:
        CjguiInternalRendererNativeBridgeBuildSystemImplementationIntent
): CjguiInternalRendererNativeBridgeMacOSBuildGateAdmission {
    let proofReady =
        implementationIntent
            .didPrepareRendererNativeBridgeBuildSystemImplementationIntent &&
        implementationIntent
            .didPreserveRendererNoNativeBridgeBuildIntegrationReadiness &&
        implementationIntent.didConfirmIsolatedProbeAsFeasibilityEvidenceOnly &&
        implementationIntent.didOpenBuildSystemAdmissionWithoutConfigChange &&
        implementationIntent.didKeepBuildSystemImplementationIntentDehydrated &&
        implementationIntent.didAvoidCjpmIntegrationPermissionWrapper &&
        implementationIntent.didAvoidThinWrapper &&
        implementationIntent
            .shouldDeferRendererNativeBridgeBuildSystemImplementationIntent ==
            false &&
        implementationIntent
            .shouldReportRendererNativeBridgeBuildSystemImplementationIntentBlocked ==
            false
    let proofDeferred =
        implementationIntent
            .didPrepareRendererNativeBridgeBuildSystemImplementationIntent ==
            false &&
        implementationIntent
            .shouldDeferRendererNativeBridgeBuildSystemImplementationIntent &&
        implementationIntent
            .shouldReportRendererNativeBridgeBuildSystemImplementationIntentBlocked ==
            false
    let proofInconsistent =
        implementationIntent
            .shouldReportRendererNativeBridgeBuildSystemImplementationIntentBlocked ||
        (
            implementationIntent
                .didPrepareRendererNativeBridgeBuildSystemImplementationIntent &&
            proofReady == false
        )

    return CjguiInternalRendererNativeBridgeMacOSBuildGateAdmission(
        implementationIntent,
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

func cjguiInternalBuildRendererNativeBridgeNativeSourceInclusionDenialProof(
    macOSBuildGateAdmission:
        CjguiInternalRendererNativeBridgeMacOSBuildGateAdmission
): CjguiInternalRendererNativeBridgeNativeSourceInclusionDenialProof {
    let proofReady =
        macOSBuildGateAdmission
            .didPrepareRendererNativeBridgeMacOSBuildGateAdmission &&
        macOSBuildGateAdmission
            .didPreserveRendererNativeBridgeBuildSystemImplementationIntent &&
        macOSBuildGateAdmission.didDefineMacOSOnlyBuildGateAdmission &&
        macOSBuildGateAdmission.didRequireNonMacOSFallbackPolicy &&
        macOSBuildGateAdmission.didRequireCiHeadlessPolicy &&
        macOSBuildGateAdmission.didConfirmNoPackageConfigModification &&
        macOSBuildGateAdmission.didKeepMacOSBuildGateAdmissionDehydrated &&
        macOSBuildGateAdmission.didAvoidBuildGatePermissionWrapper &&
        macOSBuildGateAdmission.didAvoidThinWrapper &&
        macOSBuildGateAdmission
            .shouldDeferRendererNativeBridgeMacOSBuildGateAdmission ==
            false &&
        macOSBuildGateAdmission
            .shouldReportRendererNativeBridgeMacOSBuildGateAdmissionBlocked ==
            false
    let proofDeferred =
        macOSBuildGateAdmission
            .didPrepareRendererNativeBridgeMacOSBuildGateAdmission == false &&
        macOSBuildGateAdmission
            .shouldDeferRendererNativeBridgeMacOSBuildGateAdmission &&
        macOSBuildGateAdmission
            .shouldReportRendererNativeBridgeMacOSBuildGateAdmissionBlocked ==
            false
    let proofInconsistent =
        macOSBuildGateAdmission
            .shouldReportRendererNativeBridgeMacOSBuildGateAdmissionBlocked ||
        (
            macOSBuildGateAdmission
                .didPrepareRendererNativeBridgeMacOSBuildGateAdmission &&
            proofReady == false
        )

    return CjguiInternalRendererNativeBridgeNativeSourceInclusionDenialProof(
        macOSBuildGateAdmission,
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

func cjguiInternalBuildRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy(
    sourceInclusionDenialProof:
        CjguiInternalRendererNativeBridgeNativeSourceInclusionDenialProof
): CjguiInternalRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy {
    let proofReady =
        sourceInclusionDenialProof
            .didPrepareRendererNativeBridgeNativeSourceInclusionDenialProof &&
        sourceInclusionDenialProof
            .didPreserveRendererNativeBridgeMacOSBuildGateAdmission &&
        sourceInclusionDenialProof.didDenyProductionNativeSourceInclusion &&
        sourceInclusionDenialProof.didKeepProbeAndProductionBuildSeparated &&
        sourceInclusionDenialProof.didConfirmNoCjpmTomlModification &&
        sourceInclusionDenialProof.didConfirmNoBuildScriptModification &&
        sourceInclusionDenialProof
            .didKeepNativeSourceInclusionDenialProofDehydrated &&
        sourceInclusionDenialProof.didAvoidSourceIncludedWrapper &&
        sourceInclusionDenialProof.didAvoidThinWrapper &&
        sourceInclusionDenialProof
            .shouldDeferRendererNativeBridgeNativeSourceInclusionDenialProof ==
            false &&
        sourceInclusionDenialProof
            .shouldReportRendererNativeBridgeNativeSourceInclusionDenialProofBlocked ==
            false
    let proofDeferred =
        sourceInclusionDenialProof
            .didPrepareRendererNativeBridgeNativeSourceInclusionDenialProof ==
            false &&
        sourceInclusionDenialProof
            .shouldDeferRendererNativeBridgeNativeSourceInclusionDenialProof &&
        sourceInclusionDenialProof
            .shouldReportRendererNativeBridgeNativeSourceInclusionDenialProofBlocked ==
            false
    let proofInconsistent =
        sourceInclusionDenialProof
            .shouldReportRendererNativeBridgeNativeSourceInclusionDenialProofBlocked ||
        (
            sourceInclusionDenialProof
                .didPrepareRendererNativeBridgeNativeSourceInclusionDenialProof &&
            proofReady == false
        )

    return CjguiInternalRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy(
        sourceInclusionDenialProof,
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
        true
    )
}

func cjguiInternalBuildRendererNativeBridgeFrameworkLinkDenialProof(
    compileLinkAdmissionPolicy:
        CjguiInternalRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy
): CjguiInternalRendererNativeBridgeFrameworkLinkDenialProof {
    let proofReady =
        compileLinkAdmissionPolicy
            .didPrepareRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy &&
        compileLinkAdmissionPolicy
            .didPreserveRendererNativeBridgeNativeSourceInclusionDenialProof &&
        compileLinkAdmissionPolicy
            .didDefineObjectiveCCompileLinkAdmissionPolicy &&
        compileLinkAdmissionPolicy.didRequireCompilerPathPolicy &&
        compileLinkAdmissionPolicy.didRequireSdkRootDiscoveryPolicy &&
        compileLinkAdmissionPolicy.didRequireDeploymentTargetPolicy &&
        compileLinkAdmissionPolicy.didKeepCompilerInvocationUnwired &&
        compileLinkAdmissionPolicy
            .didKeepObjectiveCCompileLinkAdmissionPolicyDehydrated &&
        compileLinkAdmissionPolicy.didAvoidCallableSurfaceWrapper &&
        compileLinkAdmissionPolicy.didAvoidThinWrapper &&
        compileLinkAdmissionPolicy
            .shouldDeferRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy ==
            false &&
        compileLinkAdmissionPolicy
            .shouldReportRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicyBlocked ==
            false
    let proofDeferred =
        compileLinkAdmissionPolicy
            .didPrepareRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy ==
            false &&
        compileLinkAdmissionPolicy
            .shouldDeferRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy &&
        compileLinkAdmissionPolicy
            .shouldReportRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicyBlocked ==
            false
    let proofInconsistent =
        compileLinkAdmissionPolicy
            .shouldReportRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicyBlocked ||
        (
            compileLinkAdmissionPolicy
                .didPrepareRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy &&
            proofReady == false
        )

    return CjguiInternalRendererNativeBridgeFrameworkLinkDenialProof(
        compileLinkAdmissionPolicy,
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

func cjguiInternalBuildRendererNativeBridgeBuildFailureClassification(
    frameworkLinkDenialProof:
        CjguiInternalRendererNativeBridgeFrameworkLinkDenialProof
): CjguiInternalRendererNativeBridgeBuildFailureClassification {
    let proofReady =
        frameworkLinkDenialProof
            .didPrepareRendererNativeBridgeFrameworkLinkDenialProof &&
        frameworkLinkDenialProof
            .didPreserveRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy &&
        frameworkLinkDenialProof.didDenyImplicitFrameworkLinking &&
        frameworkLinkDenialProof.didRequireExplicitFrameworkListFuturePolicy &&
        frameworkLinkDenialProof.didConfirmNoPlatformFrameworkImportOrCall &&
        frameworkLinkDenialProof.didKeepFrameworkLinkUnwired &&
        frameworkLinkDenialProof.didKeepFrameworkLinkDenialProofDehydrated &&
        frameworkLinkDenialProof.didAvoidFrameworkReadyWrapper &&
        frameworkLinkDenialProof.didAvoidThinWrapper &&
        frameworkLinkDenialProof
            .shouldDeferRendererNativeBridgeFrameworkLinkDenialProof ==
            false &&
        frameworkLinkDenialProof
            .shouldReportRendererNativeBridgeFrameworkLinkDenialProofBlocked ==
            false
    let proofDeferred =
        frameworkLinkDenialProof
            .didPrepareRendererNativeBridgeFrameworkLinkDenialProof == false &&
        frameworkLinkDenialProof
            .shouldDeferRendererNativeBridgeFrameworkLinkDenialProof &&
        frameworkLinkDenialProof
            .shouldReportRendererNativeBridgeFrameworkLinkDenialProofBlocked ==
            false
    let proofInconsistent =
        frameworkLinkDenialProof
            .shouldReportRendererNativeBridgeFrameworkLinkDenialProofBlocked ||
        (
            frameworkLinkDenialProof
                .didPrepareRendererNativeBridgeFrameworkLinkDenialProof &&
            proofReady == false
        )

    return CjguiInternalRendererNativeBridgeBuildFailureClassification(
        frameworkLinkDenialProof,
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

func cjguiInternalBuildRendererNoNativeBridgeBuildSystemImplementationReadiness(
    buildFailureClassification:
        CjguiInternalRendererNativeBridgeBuildFailureClassification
): CjguiInternalRendererNoNativeBridgeBuildSystemImplementationReadiness {
    let proofReady =
        buildFailureClassification
            .didPrepareRendererNativeBridgeBuildFailureClassification &&
        buildFailureClassification
            .didPreserveRendererNativeBridgeFrameworkLinkDenialProof &&
        buildFailureClassification.didClassifyMissingCompilerFailure &&
        buildFailureClassification.didClassifyMissingSdkRootFailure &&
        buildFailureClassification
            .didClassifyPackageIntegrationUnsupportedFailure &&
        buildFailureClassification.didClassifyNonMacOSFallbackFailure &&
        buildFailureClassification.didClassifyCiHeadlessFailure &&
        buildFailureClassification.didRequireFailClosedBuildSystemAdmission &&
        buildFailureClassification.didKeepBuildFailureClassificationDehydrated &&
        buildFailureClassification.didAvoidProbeSuccessAsIntegrationWrapper &&
        buildFailureClassification.didAvoidThinWrapper &&
        buildFailureClassification
            .shouldDeferRendererNativeBridgeBuildFailureClassification ==
            false &&
        buildFailureClassification
            .shouldReportRendererNativeBridgeBuildFailureClassificationBlocked ==
            false
    let proofDeferred =
        buildFailureClassification
            .didPrepareRendererNativeBridgeBuildFailureClassification ==
            false &&
        buildFailureClassification
            .shouldDeferRendererNativeBridgeBuildFailureClassification &&
        buildFailureClassification
            .shouldReportRendererNativeBridgeBuildFailureClassificationBlocked ==
            false
    let proofInconsistent =
        buildFailureClassification
            .shouldReportRendererNativeBridgeBuildFailureClassificationBlocked ||
        (
            buildFailureClassification
                .didPrepareRendererNativeBridgeBuildFailureClassification &&
            proofReady == false
        )

    return CjguiInternalRendererNoNativeBridgeBuildSystemImplementationReadiness(
        buildFailureClassification,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererNativeBridgeBuildSystemAdmissionDraft():
    CjguiInternalRendererNoNativeBridgeBuildSystemImplementationReadiness {
    let buildIntegrationReadiness =
        cjguiInternalExecuteDefaultRendererNativeBridgeBuildIntegrationDraft()
    let implementationIntent =
        cjguiInternalBuildRendererNativeBridgeBuildSystemImplementationIntent(
            buildIntegrationReadiness
        )
    let macOSBuildGateAdmission =
        cjguiInternalBuildRendererNativeBridgeMacOSBuildGateAdmission(
            implementationIntent
        )
    let sourceInclusionDenialProof =
        cjguiInternalBuildRendererNativeBridgeNativeSourceInclusionDenialProof(
            macOSBuildGateAdmission
        )
    let compileLinkAdmissionPolicy =
        cjguiInternalBuildRendererNativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy(
            sourceInclusionDenialProof
        )
    let frameworkLinkDenialProof =
        cjguiInternalBuildRendererNativeBridgeFrameworkLinkDenialProof(
            compileLinkAdmissionPolicy
        )
    let buildFailureClassification =
        cjguiInternalBuildRendererNativeBridgeBuildFailureClassification(
            frameworkLinkDenialProof
        )

    return cjguiInternalBuildRendererNoNativeBridgeBuildSystemImplementationReadiness(
        buildFailureClassification
    )
}
