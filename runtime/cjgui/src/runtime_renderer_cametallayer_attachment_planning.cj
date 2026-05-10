// 维护注释：本文件是 CAMetalLayer attachment planning 的内部 no-attach owner。
// Truth: 只消费 CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness，
// 固定 QuartzCore / CAMetalLayer class availability 与 NSView attachment 的
// planning facts。
// Stop-line: 不 import QuartzCore / Metal，不创建 CAMetalLayer / CALayer，
// 不设置 NSView.layer / wantsLayer，不创建 MTLDevice / drawable，不写
// runtime_state.cj，不新增 public API。
// Same-shape Boundary Brake: 不得把本 owner 包成 layer-ready、Metal-ready、
// backend-ready、render-ready、GPU-submission、renderer state write、receipt、
// record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererNoCAMetalLayerAttachmentReadiness {
    let didPrepareRendererNoCAMetalLayerAttachmentReadiness: Bool
    let shouldDeferRendererNoCAMetalLayerAttachmentReadiness: Bool
    let shouldReportRendererNoCAMetalLayerAttachmentBlocked: Bool
    let didPreserveRendererBackendNsViewPlatformIntegrationReadiness:
        Bool
    let didConfirmCAMetalLayerAttachmentIntent: Bool
    let didConfirmQuartzCoreImportAdmissionPolicy: Bool
    let didConfirmCAMetalLayerClassAvailabilityObservationPolicy:
        Bool
    let didConfirmNsViewLayerAttachmentStillBlocked: Bool
    let didConfirmNoCAMetalLayerOrCALayerCreation: Bool
    let didConfirmNoWantsLayerMutation: Bool
    let didConfirmNoMetalDeviceOrDrawableBinding: Bool
    let didConfirmMainThreadAttachmentGate: Bool
    let didConfirmDetachBeforeDestroyDependency: Bool
    let didConfirmFailClosedAttachmentClassifications: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoDiagnosticsPublication: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNoCAMetalLayerAttachmentReadinessDehydrated: Bool
    let didAvoidLayerReadyWrapper: Bool
    let didAvoidMetalReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidGPUSubmissionWrapper: Bool
    let didAvoidRendererStateWriteWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        didPrepareRendererNoCAMetalLayerAttachmentReadiness: Bool,
        shouldDeferRendererNoCAMetalLayerAttachmentReadiness: Bool,
        shouldReportRendererNoCAMetalLayerAttachmentBlocked: Bool,
        didPreserveRendererBackendNsViewPlatformIntegrationReadiness:
            Bool,
        didConfirmCAMetalLayerAttachmentIntent: Bool,
        didConfirmQuartzCoreImportAdmissionPolicy: Bool,
        didConfirmCAMetalLayerClassAvailabilityObservationPolicy:
            Bool,
        didConfirmNsViewLayerAttachmentStillBlocked: Bool,
        didConfirmNoCAMetalLayerOrCALayerCreation: Bool,
        didConfirmNoWantsLayerMutation: Bool,
        didConfirmNoMetalDeviceOrDrawableBinding: Bool,
        didConfirmMainThreadAttachmentGate: Bool,
        didConfirmDetachBeforeDestroyDependency: Bool,
        didConfirmFailClosedAttachmentClassifications: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoDiagnosticsPublication: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNoCAMetalLayerAttachmentReadinessDehydrated: Bool,
        didAvoidLayerReadyWrapper: Bool,
        didAvoidMetalReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidGPUSubmissionWrapper: Bool,
        didAvoidRendererStateWriteWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.didPrepareRendererNoCAMetalLayerAttachmentReadiness =
            didPrepareRendererNoCAMetalLayerAttachmentReadiness
        this.shouldDeferRendererNoCAMetalLayerAttachmentReadiness =
            shouldDeferRendererNoCAMetalLayerAttachmentReadiness
        this.shouldReportRendererNoCAMetalLayerAttachmentBlocked =
            shouldReportRendererNoCAMetalLayerAttachmentBlocked
        this
            .didPreserveRendererBackendNsViewPlatformIntegrationReadiness =
            didPreserveRendererBackendNsViewPlatformIntegrationReadiness
        this.didConfirmCAMetalLayerAttachmentIntent =
            didConfirmCAMetalLayerAttachmentIntent
        this.didConfirmQuartzCoreImportAdmissionPolicy =
            didConfirmQuartzCoreImportAdmissionPolicy
        this
            .didConfirmCAMetalLayerClassAvailabilityObservationPolicy =
            didConfirmCAMetalLayerClassAvailabilityObservationPolicy
        this.didConfirmNsViewLayerAttachmentStillBlocked =
            didConfirmNsViewLayerAttachmentStillBlocked
        this.didConfirmNoCAMetalLayerOrCALayerCreation =
            didConfirmNoCAMetalLayerOrCALayerCreation
        this.didConfirmNoWantsLayerMutation =
            didConfirmNoWantsLayerMutation
        this.didConfirmNoMetalDeviceOrDrawableBinding =
            didConfirmNoMetalDeviceOrDrawableBinding
        this.didConfirmMainThreadAttachmentGate =
            didConfirmMainThreadAttachmentGate
        this.didConfirmDetachBeforeDestroyDependency =
            didConfirmDetachBeforeDestroyDependency
        this.didConfirmFailClosedAttachmentClassifications =
            didConfirmFailClosedAttachmentClassifications
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoDiagnosticsPublication =
            didConfirmNoDiagnosticsPublication
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth =
            didConfirmNoBackendReadyTruth
        this.didKeepNoCAMetalLayerAttachmentReadinessDehydrated =
            didKeepNoCAMetalLayerAttachmentReadinessDehydrated
        this.didAvoidLayerReadyWrapper = didAvoidLayerReadyWrapper
        this.didAvoidMetalReadyWrapper = didAvoidMetalReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
        this.didAvoidRenderPermissionWrapper =
            didAvoidRenderPermissionWrapper
        this.didAvoidGPUSubmissionWrapper = didAvoidGPUSubmissionWrapper
        this.didAvoidRendererStateWriteWrapper =
            didAvoidRendererStateWriteWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalExecuteDefaultRendererCAMetalLayerAttachmentDraft():
    CjguiInternalRendererNoCAMetalLayerAttachmentReadiness {
    let backendNsViewPlatformIntegrationReadiness =
        cjguiInternalExecuteDefaultRendererBackendNsViewPlatformIntegrationDraft()
    let backendIntegrationReady =
        backendNsViewPlatformIntegrationReadiness
            .didPrepareRendererNoBackendNsViewPlatformIntegrationReadiness &&
        backendNsViewPlatformIntegrationReadiness
            .didConfirmNsViewRuntimeCallEvidenceAccepted &&
        backendNsViewPlatformIntegrationReadiness
            .didConfirmBackendShellPlatformCandidateIntent &&
        backendNsViewPlatformIntegrationReadiness
            .didConfirmTokenLocalityPreserved &&
        backendNsViewPlatformIntegrationReadiness
            .didConfirmNoRendererStateWrite &&
        backendNsViewPlatformIntegrationReadiness
            .didConfirmNoMetalLayerBinding &&
        backendNsViewPlatformIntegrationReadiness
            .didConfirmNoBackendReadyTruth &&
        backendNsViewPlatformIntegrationReadiness
            .didConfirmTeardownBeforeBackendReadyDependency &&
        backendNsViewPlatformIntegrationReadiness
            .didConfirmMainThreadBackendPlatformAdmissionGuard &&
        backendNsViewPlatformIntegrationReadiness
            .didConfirmInvalidTokenFailureClassification &&
        backendNsViewPlatformIntegrationReadiness
            .didConfirmBackgroundThreadFailureClassification &&
        backendNsViewPlatformIntegrationReadiness
            .didConfirmNoPublicSurface &&
        backendNsViewPlatformIntegrationReadiness
            .didConfirmNoDiagnosticsPublication
    let attachmentPlanningReady = backendIntegrationReady
    return CjguiInternalRendererNoCAMetalLayerAttachmentReadiness(
        attachmentPlanningReady,
        !attachmentPlanningReady,
        !attachmentPlanningReady,
        backendIntegrationReady,
        backendIntegrationReady,
        true,
        backendIntegrationReady,
        true,
        true,
        true,
        true,
        backendNsViewPlatformIntegrationReadiness
            .didConfirmMainThreadBackendPlatformAdmissionGuard,
        backendNsViewPlatformIntegrationReadiness
            .didConfirmTeardownBeforeBackendReadyDependency,
        backendNsViewPlatformIntegrationReadiness
            .didConfirmInvalidTokenFailureClassification &&
            backendNsViewPlatformIntegrationReadiness
                .didConfirmBackgroundThreadFailureClassification,
        true,
        backendNsViewPlatformIntegrationReadiness
            .didConfirmNoDiagnosticsPublication,
        backendNsViewPlatformIntegrationReadiness
            .didConfirmNoRendererStateWrite,
        backendNsViewPlatformIntegrationReadiness
            .didConfirmNoBackendReadyTruth,
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
