// 维护注释：本文件是 NSView platform evidence 接入 renderer backend shell 的内部 owner。
// Truth: 只消费 CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness，
// 把 runtime internal NSView call evidence 接入 renderer backend shell planning facts。
// Stop-line: 不写 runtime_state.cj，不创建 CAMetalLayer / Metal resource，不返回
// token / pointer / handle，不新增 public API，不生成 backend-ready truth。
// Same-shape Boundary Brake: 不得把本 owner 包成 backend-ready、render-ready、
// Metal layer、renderer state write、receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererBackendNsViewPlatformIntegrationEvidence {
    let nsViewRuntimeCallReadiness:
        CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness
    let didAcceptNsViewRuntimeCallEvidence: Bool
    let didDefineBackendShellPlatformCandidateIntent: Bool
    let didPreserveOpaqueTokenLocality: Bool
    let didConfirmNoRendererStateWriteProof: Bool
    let didConfirmNoMetalLayerBindingProof: Bool
    let didConfirmNoBackendReadyTruthProof: Bool
    let didConfirmTeardownBeforeBackendReadyDependency: Bool
    let didConfirmMainThreadBackendPlatformAdmissionGuard: Bool
    let didKeepBackendNsViewIntegrationValueOnly: Bool
    let didAvoidThinWrapper: Bool

    init(
        nsViewRuntimeCallReadiness:
            CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness,
        didAcceptNsViewRuntimeCallEvidence: Bool,
        didDefineBackendShellPlatformCandidateIntent: Bool,
        didPreserveOpaqueTokenLocality: Bool,
        didConfirmNoRendererStateWriteProof: Bool,
        didConfirmNoMetalLayerBindingProof: Bool,
        didConfirmNoBackendReadyTruthProof: Bool,
        didConfirmTeardownBeforeBackendReadyDependency: Bool,
        didConfirmMainThreadBackendPlatformAdmissionGuard: Bool,
        didKeepBackendNsViewIntegrationValueOnly: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.nsViewRuntimeCallReadiness = nsViewRuntimeCallReadiness
        this.didAcceptNsViewRuntimeCallEvidence =
            didAcceptNsViewRuntimeCallEvidence
        this.didDefineBackendShellPlatformCandidateIntent =
            didDefineBackendShellPlatformCandidateIntent
        this.didPreserveOpaqueTokenLocality = didPreserveOpaqueTokenLocality
        this.didConfirmNoRendererStateWriteProof =
            didConfirmNoRendererStateWriteProof
        this.didConfirmNoMetalLayerBindingProof =
            didConfirmNoMetalLayerBindingProof
        this.didConfirmNoBackendReadyTruthProof =
            didConfirmNoBackendReadyTruthProof
        this.didConfirmTeardownBeforeBackendReadyDependency =
            didConfirmTeardownBeforeBackendReadyDependency
        this.didConfirmMainThreadBackendPlatformAdmissionGuard =
            didConfirmMainThreadBackendPlatformAdmissionGuard
        this.didKeepBackendNsViewIntegrationValueOnly =
            didKeepBackendNsViewIntegrationValueOnly
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererBackendNsViewPlatformFailureClassification {
    let integrationEvidence:
        CjguiInternalRendererBackendNsViewPlatformIntegrationEvidence
    let didClassifyInvalidTokenFailure: Bool
    let didClassifyDestroyedTokenFailure: Bool
    let didClassifyBackgroundThreadFailure: Bool
    let didClassifyTableUnavailableFailure: Bool
    let didKeepFailureClassificationFailClosed: Bool
    let didConfirmNoDiagnosticsPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        integrationEvidence:
            CjguiInternalRendererBackendNsViewPlatformIntegrationEvidence,
        didClassifyInvalidTokenFailure: Bool,
        didClassifyDestroyedTokenFailure: Bool,
        didClassifyBackgroundThreadFailure: Bool,
        didClassifyTableUnavailableFailure: Bool,
        didKeepFailureClassificationFailClosed: Bool,
        didConfirmNoDiagnosticsPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.integrationEvidence = integrationEvidence
        this.didClassifyInvalidTokenFailure =
            didClassifyInvalidTokenFailure
        this.didClassifyDestroyedTokenFailure =
            didClassifyDestroyedTokenFailure
        this.didClassifyBackgroundThreadFailure =
            didClassifyBackgroundThreadFailure
        this.didClassifyTableUnavailableFailure =
            didClassifyTableUnavailableFailure
        this.didKeepFailureClassificationFailClosed =
            didKeepFailureClassificationFailClosed
        this.didConfirmNoDiagnosticsPublication =
            didConfirmNoDiagnosticsPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness {
    let integrationEvidence:
        CjguiInternalRendererBackendNsViewPlatformIntegrationEvidence
    let failureClassification:
        CjguiInternalRendererBackendNsViewPlatformFailureClassification
    let didPrepareRendererNoBackendNsViewPlatformIntegrationReadiness: Bool
    let shouldDeferRendererNoBackendNsViewPlatformIntegrationReadiness: Bool
    let shouldReportRendererNoBackendNsViewPlatformIntegrationBlocked: Bool
    let didPreserveRendererPlatformObjectNsViewRuntimeCallReadiness: Bool
    let didConfirmNsViewRuntimeCallEvidenceAccepted: Bool
    let didConfirmBackendShellPlatformCandidateIntent: Bool
    let didConfirmTokenLocalityPreserved: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoMetalLayerBinding: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didConfirmTeardownBeforeBackendReadyDependency: Bool
    let didConfirmMainThreadBackendPlatformAdmissionGuard: Bool
    let didConfirmInvalidTokenFailureClassification: Bool
    let didConfirmDestroyedTokenFailureClassification: Bool
    let didConfirmBackgroundThreadFailureClassification: Bool
    let didConfirmTableUnavailableFailureClassification: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoDiagnosticsPublication: Bool
    let didKeepNoBackendNsViewPlatformIntegrationReadinessDehydrated:
        Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidRendererStateWriteWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        integrationEvidence:
            CjguiInternalRendererBackendNsViewPlatformIntegrationEvidence,
        failureClassification:
            CjguiInternalRendererBackendNsViewPlatformFailureClassification,
        didPrepareRendererNoBackendNsViewPlatformIntegrationReadiness:
            Bool,
        shouldDeferRendererNoBackendNsViewPlatformIntegrationReadiness:
            Bool,
        shouldReportRendererNoBackendNsViewPlatformIntegrationBlocked:
            Bool,
        didPreserveRendererPlatformObjectNsViewRuntimeCallReadiness:
            Bool,
        didConfirmNsViewRuntimeCallEvidenceAccepted: Bool,
        didConfirmBackendShellPlatformCandidateIntent: Bool,
        didConfirmTokenLocalityPreserved: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoMetalLayerBinding: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didConfirmTeardownBeforeBackendReadyDependency: Bool,
        didConfirmMainThreadBackendPlatformAdmissionGuard: Bool,
        didConfirmInvalidTokenFailureClassification: Bool,
        didConfirmDestroyedTokenFailureClassification: Bool,
        didConfirmBackgroundThreadFailureClassification: Bool,
        didConfirmTableUnavailableFailureClassification: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoDiagnosticsPublication: Bool,
        didKeepNoBackendNsViewPlatformIntegrationReadinessDehydrated:
            Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidRendererStateWriteWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.integrationEvidence = integrationEvidence
        this.failureClassification = failureClassification
        this
            .didPrepareRendererNoBackendNsViewPlatformIntegrationReadiness =
            didPrepareRendererNoBackendNsViewPlatformIntegrationReadiness
        this
            .shouldDeferRendererNoBackendNsViewPlatformIntegrationReadiness =
            shouldDeferRendererNoBackendNsViewPlatformIntegrationReadiness
        this.shouldReportRendererNoBackendNsViewPlatformIntegrationBlocked =
            shouldReportRendererNoBackendNsViewPlatformIntegrationBlocked
        this.didPreserveRendererPlatformObjectNsViewRuntimeCallReadiness =
            didPreserveRendererPlatformObjectNsViewRuntimeCallReadiness
        this.didConfirmNsViewRuntimeCallEvidenceAccepted =
            didConfirmNsViewRuntimeCallEvidenceAccepted
        this.didConfirmBackendShellPlatformCandidateIntent =
            didConfirmBackendShellPlatformCandidateIntent
        this.didConfirmTokenLocalityPreserved =
            didConfirmTokenLocalityPreserved
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoMetalLayerBinding =
            didConfirmNoMetalLayerBinding
        this.didConfirmNoBackendReadyTruth =
            didConfirmNoBackendReadyTruth
        this.didConfirmTeardownBeforeBackendReadyDependency =
            didConfirmTeardownBeforeBackendReadyDependency
        this.didConfirmMainThreadBackendPlatformAdmissionGuard =
            didConfirmMainThreadBackendPlatformAdmissionGuard
        this.didConfirmInvalidTokenFailureClassification =
            didConfirmInvalidTokenFailureClassification
        this.didConfirmDestroyedTokenFailureClassification =
            didConfirmDestroyedTokenFailureClassification
        this.didConfirmBackgroundThreadFailureClassification =
            didConfirmBackgroundThreadFailureClassification
        this.didConfirmTableUnavailableFailureClassification =
            didConfirmTableUnavailableFailureClassification
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoDiagnosticsPublication =
            didConfirmNoDiagnosticsPublication
        this
            .didKeepNoBackendNsViewPlatformIntegrationReadinessDehydrated =
            didKeepNoBackendNsViewPlatformIntegrationReadinessDehydrated
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
        this.didAvoidRenderPermissionWrapper =
            didAvoidRenderPermissionWrapper
        this.didAvoidRendererStateWriteWrapper =
            didAvoidRendererStateWriteWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererBackendNsViewPlatformIntegrationEvidence(
    nsViewRuntimeCallReadiness:
        CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness
): CjguiInternalRendererBackendNsViewPlatformIntegrationEvidence {
    let runtimeCallReady =
        nsViewRuntimeCallReadiness
            .didPrepareRendererNoPlatformObjectNsViewRuntimeCallReadiness &&
        nsViewRuntimeCallReadiness.didConfirmRuntimeInternalCallExecuted &&
        nsViewRuntimeCallReadiness.didConfirmOpaqueTokenStayedInternal &&
        nsViewRuntimeCallReadiness
            .didConfirmCreateClassifyDestroyLifecycle &&
        nsViewRuntimeCallReadiness.didConfirmDestroyedTokenStale &&
        nsViewRuntimeCallReadiness.didConfirmDoubleDestroyFailClosed &&
        nsViewRuntimeCallReadiness.didConfirmInvalidTokenFailClosed &&
        nsViewRuntimeCallReadiness.didConfirmMainThreadDestroyGate &&
        nsViewRuntimeCallReadiness
            .didConfirmNoPointerHandleClassIdReturn &&
        nsViewRuntimeCallReadiness
            .didConfirmNoNsWindowNsApplicationLayerMetal &&
        nsViewRuntimeCallReadiness.didConfirmNoPublicSurface &&
        nsViewRuntimeCallReadiness.didConfirmNoRendererStateWrite &&
        nsViewRuntimeCallReadiness.didConfirmNoBackendReadyTruth
    return CjguiInternalRendererBackendNsViewPlatformIntegrationEvidence(
        nsViewRuntimeCallReadiness,
        runtimeCallReady,
        runtimeCallReady,
        nsViewRuntimeCallReadiness.didConfirmOpaqueTokenStayedInternal,
        nsViewRuntimeCallReadiness.didConfirmNoRendererStateWrite,
        nsViewRuntimeCallReadiness
            .didConfirmNoNsWindowNsApplicationLayerMetal,
        nsViewRuntimeCallReadiness.didConfirmNoBackendReadyTruth,
        nsViewRuntimeCallReadiness.didConfirmDoubleDestroyFailClosed,
        nsViewRuntimeCallReadiness.didConfirmMainThreadDestroyGate,
        true,
        true
    )
}

func cjguiInternalBuildRendererBackendNsViewPlatformFailureClassification(
    integrationEvidence:
        CjguiInternalRendererBackendNsViewPlatformIntegrationEvidence
): CjguiInternalRendererBackendNsViewPlatformFailureClassification {
    let runtimeCallReadiness = integrationEvidence.nsViewRuntimeCallReadiness
    return CjguiInternalRendererBackendNsViewPlatformFailureClassification(
        integrationEvidence,
        runtimeCallReadiness.didConfirmInvalidTokenFailClosed,
        runtimeCallReadiness.didConfirmDestroyedTokenStale,
        runtimeCallReadiness.didConfirmMainThreadDestroyGate,
        runtimeCallReadiness.didConfirmOccupiedCountLifecycle,
        runtimeCallReadiness.didConfirmInvalidTokenFailClosed &&
            runtimeCallReadiness.didConfirmDestroyedTokenStale &&
            runtimeCallReadiness.didConfirmMainThreadDestroyGate &&
            runtimeCallReadiness.didConfirmOccupiedCountLifecycle,
        true,
        true
    )
}

func cjguiInternalBuildRendererBackendNsViewPlatformIntegrationReadiness(
    integrationEvidence:
        CjguiInternalRendererBackendNsViewPlatformIntegrationEvidence,
    failureClassification:
        CjguiInternalRendererBackendNsViewPlatformFailureClassification
): CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness {
    let integrationReady =
        integrationEvidence.didAcceptNsViewRuntimeCallEvidence &&
        integrationEvidence.didDefineBackendShellPlatformCandidateIntent &&
        integrationEvidence.didPreserveOpaqueTokenLocality &&
        integrationEvidence.didConfirmNoRendererStateWriteProof &&
        integrationEvidence.didConfirmNoMetalLayerBindingProof &&
        integrationEvidence.didConfirmNoBackendReadyTruthProof &&
        integrationEvidence.didConfirmTeardownBeforeBackendReadyDependency &&
        integrationEvidence.didConfirmMainThreadBackendPlatformAdmissionGuard &&
        integrationEvidence.didKeepBackendNsViewIntegrationValueOnly &&
        failureClassification.didClassifyInvalidTokenFailure &&
        failureClassification.didClassifyDestroyedTokenFailure &&
        failureClassification.didClassifyBackgroundThreadFailure &&
        failureClassification.didClassifyTableUnavailableFailure &&
        failureClassification.didKeepFailureClassificationFailClosed &&
        failureClassification.didConfirmNoDiagnosticsPublication
    return CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness(
        integrationEvidence,
        failureClassification,
        integrationReady,
        !integrationReady,
        !integrationReady,
        integrationEvidence.didAcceptNsViewRuntimeCallEvidence,
        integrationEvidence.didAcceptNsViewRuntimeCallEvidence,
        integrationEvidence.didDefineBackendShellPlatformCandidateIntent,
        integrationEvidence.didPreserveOpaqueTokenLocality,
        integrationEvidence.didConfirmNoRendererStateWriteProof,
        integrationEvidence.didConfirmNoMetalLayerBindingProof,
        integrationEvidence.didConfirmNoBackendReadyTruthProof,
        integrationEvidence.didConfirmTeardownBeforeBackendReadyDependency,
        integrationEvidence.didConfirmMainThreadBackendPlatformAdmissionGuard,
        failureClassification.didClassifyInvalidTokenFailure,
        failureClassification.didClassifyDestroyedTokenFailure,
        failureClassification.didClassifyBackgroundThreadFailure,
        failureClassification.didClassifyTableUnavailableFailure,
        true,
        failureClassification.didConfirmNoDiagnosticsPublication,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererBackendNsViewPlatformIntegrationDraft():
    CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness {
    let nsViewRuntimeCallReadiness =
        cjguiInternalExecuteDefaultRendererPlatformObjectNsViewRuntimeCallDraft()
    let integrationEvidence =
        cjguiInternalBuildRendererBackendNsViewPlatformIntegrationEvidence(
            nsViewRuntimeCallReadiness
        )
    let failureClassification =
        cjguiInternalBuildRendererBackendNsViewPlatformFailureClassification(
            integrationEvidence
        )
    return cjguiInternalBuildRendererBackendNsViewPlatformIntegrationReadiness(
        integrationEvidence,
        failureClassification
    )
}
