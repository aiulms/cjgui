// 中文维护注释：本文件是 visible-window production harness policy value boundary owner。
// Owner: runtime renderer internal visible-window production harness policy owner。
// Truth: 只消费 CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness 与
// CjguiInternalRendererNoDrawInputBundleReadiness，固定 production visible-window
// harness 的 ownership / run loop / display-backed layer / cleanup / fail-closed
// policy value facts。
// Stop-line: 不创建 NSWindow / NSView / CAMetalLayer / MTLDevice，不调用 production
// nextDrawable，不新增 native C ABI 或 foreign func，不配置 color attachment，不创建
// command buffer / render command encoder，不 draw，不 commit，不 present，不提交 GPU work，
// 不执行 render，不写 runtime_state.cj，不扩 public API。
// Same-shape Boundary Brake: harness policy facts 不得包装成 native harness、
// drawable-ready、color attachment permission、render permission、GPU submission、
// backend-ready、renderer state write、receipt、record 或 publication。
package cjgui

struct CjguiInternalRendererVisibleWindowProductionHarnessPolicyFacts {
    let drawableTextureLifetimePlanningReadiness:
        CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness
    let drawInputBundleReadiness: CjguiInternalRendererNoDrawInputBundleReadiness
    let didObserveDrawableTextureLifetimePlanningTail: Bool
    let didObserveNoSubmitDrawInputBundleTail: Bool
    let didRecordProductionNsWindowOwnershipPolicy: Bool
    let didRecordBoundedRunLoopPolicy: Bool
    let didRecordDisplayBackedCAMetalLayerPrerequisite: Bool
    let didRecordTokenBackedViewLayerDeviceAlignmentPolicy: Bool
    let didRecordCleanupCoOwnershipPolicy: Bool
    let didRecordHeadlessCiLikeFailClosedPolicy: Bool
    let didKeepNativeNsWindowHarnessBlocked: Bool
    let didKeepProductionNextDrawableBlocked: Bool
    let didKeepColorAttachmentEncoderDrawCommitPresentGpuRenderBlocked: Bool
    let didKeepPolicyFactsDehydrated: Bool

    init(
        drawableTextureLifetimePlanningReadiness:
            CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness,
        drawInputBundleReadiness: CjguiInternalRendererNoDrawInputBundleReadiness,
        didObserveDrawableTextureLifetimePlanningTail: Bool,
        didObserveNoSubmitDrawInputBundleTail: Bool,
        didRecordProductionNsWindowOwnershipPolicy: Bool,
        didRecordBoundedRunLoopPolicy: Bool,
        didRecordDisplayBackedCAMetalLayerPrerequisite: Bool,
        didRecordTokenBackedViewLayerDeviceAlignmentPolicy: Bool,
        didRecordCleanupCoOwnershipPolicy: Bool,
        didRecordHeadlessCiLikeFailClosedPolicy: Bool,
        didKeepNativeNsWindowHarnessBlocked: Bool,
        didKeepProductionNextDrawableBlocked: Bool,
        didKeepColorAttachmentEncoderDrawCommitPresentGpuRenderBlocked: Bool,
        didKeepPolicyFactsDehydrated: Bool
    ) {
        this.drawableTextureLifetimePlanningReadiness =
            drawableTextureLifetimePlanningReadiness
        this.drawInputBundleReadiness = drawInputBundleReadiness
        this.didObserveDrawableTextureLifetimePlanningTail =
            didObserveDrawableTextureLifetimePlanningTail
        this.didObserveNoSubmitDrawInputBundleTail =
            didObserveNoSubmitDrawInputBundleTail
        this.didRecordProductionNsWindowOwnershipPolicy =
            didRecordProductionNsWindowOwnershipPolicy
        this.didRecordBoundedRunLoopPolicy = didRecordBoundedRunLoopPolicy
        this.didRecordDisplayBackedCAMetalLayerPrerequisite =
            didRecordDisplayBackedCAMetalLayerPrerequisite
        this.didRecordTokenBackedViewLayerDeviceAlignmentPolicy =
            didRecordTokenBackedViewLayerDeviceAlignmentPolicy
        this.didRecordCleanupCoOwnershipPolicy =
            didRecordCleanupCoOwnershipPolicy
        this.didRecordHeadlessCiLikeFailClosedPolicy =
            didRecordHeadlessCiLikeFailClosedPolicy
        this.didKeepNativeNsWindowHarnessBlocked =
            didKeepNativeNsWindowHarnessBlocked
        this.didKeepProductionNextDrawableBlocked =
            didKeepProductionNextDrawableBlocked
        this.didKeepColorAttachmentEncoderDrawCommitPresentGpuRenderBlocked =
            didKeepColorAttachmentEncoderDrawCommitPresentGpuRenderBlocked
        this.didKeepPolicyFactsDehydrated = didKeepPolicyFactsDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowProductionHarnessAdmission {
    let policyFacts: CjguiInternalRendererVisibleWindowProductionHarnessPolicyFacts
    let didAdmitVisibleWindowProductionHarnessPolicyBoundary: Bool
    let shouldDeferVisibleWindowProductionHarnessPolicyBoundary: Bool
    let shouldReportVisibleWindowProductionHarnessPolicyBoundaryBlocked: Bool
    let didPreserveDrawableTextureLifetimePlanningReadiness: Bool
    let didPreserveNoSubmitDrawInputBundleReadiness: Bool
    let didConfirmProductionNsWindowOwnershipPolicyRecorded: Bool
    let didConfirmBoundedRunLoopPolicyRecorded: Bool
    let didConfirmDisplayBackedCAMetalLayerPrerequisiteRecorded: Bool
    let didConfirmTokenBackedViewLayerDeviceAlignmentPolicyRecorded: Bool
    let didConfirmCleanupCoOwnershipPolicyRecorded: Bool
    let didConfirmHeadlessCiLikeFailClosedPolicyRecorded: Bool
    let didConfirmNoNativeNsWindowHarness: Bool
    let didConfirmNoProductionNextDrawableCall: Bool
    let didConfirmNoColorAttachmentEncoderDrawCommitPresentGpuOrRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepVisibleWindowHarnessPolicyValueOnly: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidNativeHarnessWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        policyFacts: CjguiInternalRendererVisibleWindowProductionHarnessPolicyFacts,
        didAdmitVisibleWindowProductionHarnessPolicyBoundary: Bool,
        shouldDeferVisibleWindowProductionHarnessPolicyBoundary: Bool,
        shouldReportVisibleWindowProductionHarnessPolicyBoundaryBlocked: Bool,
        didPreserveDrawableTextureLifetimePlanningReadiness: Bool,
        didPreserveNoSubmitDrawInputBundleReadiness: Bool,
        didConfirmProductionNsWindowOwnershipPolicyRecorded: Bool,
        didConfirmBoundedRunLoopPolicyRecorded: Bool,
        didConfirmDisplayBackedCAMetalLayerPrerequisiteRecorded: Bool,
        didConfirmTokenBackedViewLayerDeviceAlignmentPolicyRecorded: Bool,
        didConfirmCleanupCoOwnershipPolicyRecorded: Bool,
        didConfirmHeadlessCiLikeFailClosedPolicyRecorded: Bool,
        didConfirmNoNativeNsWindowHarness: Bool,
        didConfirmNoProductionNextDrawableCall: Bool,
        didConfirmNoColorAttachmentEncoderDrawCommitPresentGpuOrRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepVisibleWindowHarnessPolicyValueOnly: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidNativeHarnessWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.policyFacts = policyFacts
        this.didAdmitVisibleWindowProductionHarnessPolicyBoundary =
            didAdmitVisibleWindowProductionHarnessPolicyBoundary
        this.shouldDeferVisibleWindowProductionHarnessPolicyBoundary =
            shouldDeferVisibleWindowProductionHarnessPolicyBoundary
        this.shouldReportVisibleWindowProductionHarnessPolicyBoundaryBlocked =
            shouldReportVisibleWindowProductionHarnessPolicyBoundaryBlocked
        this.didPreserveDrawableTextureLifetimePlanningReadiness =
            didPreserveDrawableTextureLifetimePlanningReadiness
        this.didPreserveNoSubmitDrawInputBundleReadiness =
            didPreserveNoSubmitDrawInputBundleReadiness
        this.didConfirmProductionNsWindowOwnershipPolicyRecorded =
            didConfirmProductionNsWindowOwnershipPolicyRecorded
        this.didConfirmBoundedRunLoopPolicyRecorded =
            didConfirmBoundedRunLoopPolicyRecorded
        this.didConfirmDisplayBackedCAMetalLayerPrerequisiteRecorded =
            didConfirmDisplayBackedCAMetalLayerPrerequisiteRecorded
        this.didConfirmTokenBackedViewLayerDeviceAlignmentPolicyRecorded =
            didConfirmTokenBackedViewLayerDeviceAlignmentPolicyRecorded
        this.didConfirmCleanupCoOwnershipPolicyRecorded =
            didConfirmCleanupCoOwnershipPolicyRecorded
        this.didConfirmHeadlessCiLikeFailClosedPolicyRecorded =
            didConfirmHeadlessCiLikeFailClosedPolicyRecorded
        this.didConfirmNoNativeNsWindowHarness = didConfirmNoNativeNsWindowHarness
        this.didConfirmNoProductionNextDrawableCall =
            didConfirmNoProductionNextDrawableCall
        this.didConfirmNoColorAttachmentEncoderDrawCommitPresentGpuOrRender =
            didConfirmNoColorAttachmentEncoderDrawCommitPresentGpuOrRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepVisibleWindowHarnessPolicyValueOnly =
            didKeepVisibleWindowHarnessPolicyValueOnly
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidNativeHarnessWrapper = didAvoidNativeHarnessWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
    }
}

struct CjguiInternalRendererNoVisibleWindowProductionHarnessReadiness {
    let harnessAdmission:
        CjguiInternalRendererVisibleWindowProductionHarnessAdmission
    let didPrepareRendererNoVisibleWindowProductionHarnessReadiness: Bool
    let shouldDeferRendererNoVisibleWindowProductionHarnessReadiness: Bool
    let shouldReportRendererNoVisibleWindowProductionHarnessBlocked: Bool
    let canEvaluateFutureNativeVisibleWindowHarnessPreflight: Bool
    let didPreserveVisibleWindowProductionHarnessPolicyAdmission: Bool
    let didConfirmProductionNsWindowOwnershipPolicy: Bool
    let didConfirmBoundedRunLoopPolicy: Bool
    let didConfirmDisplayBackedCAMetalLayerPrerequisite: Bool
    let didConfirmTokenBackedViewLayerDeviceAlignmentPolicy: Bool
    let didConfirmCleanupCoOwnershipPolicy: Bool
    let didConfirmHeadlessCiLikeFailClosedPolicy: Bool
    let didConfirmNativeNsWindowHarnessStillBlocked: Bool
    let didConfirmProductionNextDrawableStillBlocked: Bool
    let didConfirmDrawableAcquireStillBlocked: Bool
    let didConfirmColorAttachmentEncoderDrawCommitPresentGpuOrRenderBlocked: Bool
    let didConfirmNoNativePointerHandleIdClassReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepVisibleWindowProductionHarnessReadinessDehydrated: Bool
    let didAvoidNativeHarnessWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        harnessAdmission:
            CjguiInternalRendererVisibleWindowProductionHarnessAdmission,
        didPrepareRendererNoVisibleWindowProductionHarnessReadiness: Bool,
        shouldDeferRendererNoVisibleWindowProductionHarnessReadiness: Bool,
        shouldReportRendererNoVisibleWindowProductionHarnessBlocked: Bool,
        canEvaluateFutureNativeVisibleWindowHarnessPreflight: Bool,
        didPreserveVisibleWindowProductionHarnessPolicyAdmission: Bool,
        didConfirmProductionNsWindowOwnershipPolicy: Bool,
        didConfirmBoundedRunLoopPolicy: Bool,
        didConfirmDisplayBackedCAMetalLayerPrerequisite: Bool,
        didConfirmTokenBackedViewLayerDeviceAlignmentPolicy: Bool,
        didConfirmCleanupCoOwnershipPolicy: Bool,
        didConfirmHeadlessCiLikeFailClosedPolicy: Bool,
        didConfirmNativeNsWindowHarnessStillBlocked: Bool,
        didConfirmProductionNextDrawableStillBlocked: Bool,
        didConfirmDrawableAcquireStillBlocked: Bool,
        didConfirmColorAttachmentEncoderDrawCommitPresentGpuOrRenderBlocked: Bool,
        didConfirmNoNativePointerHandleIdClassReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepVisibleWindowProductionHarnessReadinessDehydrated: Bool,
        didAvoidNativeHarnessWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.harnessAdmission = harnessAdmission
        this.didPrepareRendererNoVisibleWindowProductionHarnessReadiness =
            didPrepareRendererNoVisibleWindowProductionHarnessReadiness
        this.shouldDeferRendererNoVisibleWindowProductionHarnessReadiness =
            shouldDeferRendererNoVisibleWindowProductionHarnessReadiness
        this.shouldReportRendererNoVisibleWindowProductionHarnessBlocked =
            shouldReportRendererNoVisibleWindowProductionHarnessBlocked
        this.canEvaluateFutureNativeVisibleWindowHarnessPreflight =
            canEvaluateFutureNativeVisibleWindowHarnessPreflight
        this.didPreserveVisibleWindowProductionHarnessPolicyAdmission =
            didPreserveVisibleWindowProductionHarnessPolicyAdmission
        this.didConfirmProductionNsWindowOwnershipPolicy =
            didConfirmProductionNsWindowOwnershipPolicy
        this.didConfirmBoundedRunLoopPolicy = didConfirmBoundedRunLoopPolicy
        this.didConfirmDisplayBackedCAMetalLayerPrerequisite =
            didConfirmDisplayBackedCAMetalLayerPrerequisite
        this.didConfirmTokenBackedViewLayerDeviceAlignmentPolicy =
            didConfirmTokenBackedViewLayerDeviceAlignmentPolicy
        this.didConfirmCleanupCoOwnershipPolicy =
            didConfirmCleanupCoOwnershipPolicy
        this.didConfirmHeadlessCiLikeFailClosedPolicy =
            didConfirmHeadlessCiLikeFailClosedPolicy
        this.didConfirmNativeNsWindowHarnessStillBlocked =
            didConfirmNativeNsWindowHarnessStillBlocked
        this.didConfirmProductionNextDrawableStillBlocked =
            didConfirmProductionNextDrawableStillBlocked
        this.didConfirmDrawableAcquireStillBlocked =
            didConfirmDrawableAcquireStillBlocked
        this.didConfirmColorAttachmentEncoderDrawCommitPresentGpuOrRenderBlocked =
            didConfirmColorAttachmentEncoderDrawCommitPresentGpuOrRenderBlocked
        this.didConfirmNoNativePointerHandleIdClassReturn =
            didConfirmNoNativePointerHandleIdClassReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepVisibleWindowProductionHarnessReadinessDehydrated =
            didKeepVisibleWindowProductionHarnessReadinessDehydrated
        this.didAvoidNativeHarnessWrapper = didAvoidNativeHarnessWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowProductionHarnessPolicyFacts(
    drawableTextureLifetimePlanningReadiness:
        CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness,
    drawInputBundleReadiness: CjguiInternalRendererNoDrawInputBundleReadiness
): CjguiInternalRendererVisibleWindowProductionHarnessPolicyFacts {
    let upstreamReady =
        drawableTextureLifetimePlanningReadiness
            .didPrepareRendererNoDrawableTextureLifetimePlanningReadiness &&
        drawableTextureLifetimePlanningReadiness
            .didConfirmProductionVisibleWindowSemanticsRequired &&
        drawableTextureLifetimePlanningReadiness
            .didConfirmDisplayBackedLayerOwnershipRequired &&
        drawableTextureLifetimePlanningReadiness
            .didConfirmDescriptorDrawableLayerDeviceCleanupStillUnproven &&
        drawableTextureLifetimePlanningReadiness
            .didConfirmNoProductionNextDrawableCall &&
        drawableTextureLifetimePlanningReadiness
            .didConfirmNoPresentCommandBufferEncoderCommitGpuOrRender &&
        drawableTextureLifetimePlanningReadiness.didConfirmNoPointerHandleClassIdReturn &&
        drawableTextureLifetimePlanningReadiness.didConfirmNoPublicSurface &&
        drawableTextureLifetimePlanningReadiness.didConfirmNoRendererStateWrite &&
        drawableTextureLifetimePlanningReadiness.didConfirmNoBackendReadyTruth &&
        drawableTextureLifetimePlanningReadiness
            .didKeepDrawableTextureLifetimePlanningReadinessDehydrated &&
        drawInputBundleReadiness.didPrepareRendererNoDrawInputBundleReadiness &&
        drawInputBundleReadiness.didConfirmEncoderMissing &&
        drawInputBundleReadiness.didConfirmPipelineBindingBlocked &&
        drawInputBundleReadiness.didConfirmVertexBindingBlocked &&
        drawInputBundleReadiness.didConfirmDrawCommitPresentGpuOrRenderBlocked &&
        drawInputBundleReadiness.didConfirmNoTokenPersistence &&
        drawInputBundleReadiness.didConfirmNoPublicSurface &&
        drawInputBundleReadiness.didConfirmNoRendererStateWrite &&
        drawInputBundleReadiness.didConfirmNoBackendReadyTruth &&
        drawInputBundleReadiness.didKeepDrawInputBundleReadinessDehydrated

    return CjguiInternalRendererVisibleWindowProductionHarnessPolicyFacts(
        drawableTextureLifetimePlanningReadiness,
        drawInputBundleReadiness,
        upstreamReady,
        upstreamReady,
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

func cjguiInternalBuildRendererVisibleWindowProductionHarnessAdmission(
    policyFacts: CjguiInternalRendererVisibleWindowProductionHarnessPolicyFacts
): CjguiInternalRendererVisibleWindowProductionHarnessAdmission {
    let admitted =
        policyFacts.didObserveDrawableTextureLifetimePlanningTail &&
        policyFacts.didObserveNoSubmitDrawInputBundleTail &&
        policyFacts.didRecordProductionNsWindowOwnershipPolicy &&
        policyFacts.didRecordBoundedRunLoopPolicy &&
        policyFacts.didRecordDisplayBackedCAMetalLayerPrerequisite &&
        policyFacts.didRecordTokenBackedViewLayerDeviceAlignmentPolicy &&
        policyFacts.didRecordCleanupCoOwnershipPolicy &&
        policyFacts.didRecordHeadlessCiLikeFailClosedPolicy &&
        policyFacts.didKeepNativeNsWindowHarnessBlocked &&
        policyFacts.didKeepProductionNextDrawableBlocked &&
        policyFacts.didKeepColorAttachmentEncoderDrawCommitPresentGpuRenderBlocked &&
        policyFacts.didKeepPolicyFactsDehydrated

    return CjguiInternalRendererVisibleWindowProductionHarnessAdmission(
        policyFacts,
        admitted,
        !admitted,
        false,
        policyFacts.didObserveDrawableTextureLifetimePlanningTail,
        policyFacts.didObserveNoSubmitDrawInputBundleTail,
        policyFacts.didRecordProductionNsWindowOwnershipPolicy,
        policyFacts.didRecordBoundedRunLoopPolicy,
        policyFacts.didRecordDisplayBackedCAMetalLayerPrerequisite,
        policyFacts.didRecordTokenBackedViewLayerDeviceAlignmentPolicy,
        policyFacts.didRecordCleanupCoOwnershipPolicy,
        policyFacts.didRecordHeadlessCiLikeFailClosedPolicy,
        policyFacts.didKeepNativeNsWindowHarnessBlocked,
        policyFacts.didKeepProductionNextDrawableBlocked,
        policyFacts.didKeepColorAttachmentEncoderDrawCommitPresentGpuRenderBlocked,
        true,
        true,
        true,
        true,
        policyFacts.didKeepPolicyFactsDehydrated,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowProductionHarnessReadiness(
    harnessAdmission:
        CjguiInternalRendererVisibleWindowProductionHarnessAdmission
): CjguiInternalRendererNoVisibleWindowProductionHarnessReadiness {
    let readinessReady =
        harnessAdmission.didAdmitVisibleWindowProductionHarnessPolicyBoundary &&
        harnessAdmission.didPreserveDrawableTextureLifetimePlanningReadiness &&
        harnessAdmission.didPreserveNoSubmitDrawInputBundleReadiness &&
        harnessAdmission.didConfirmProductionNsWindowOwnershipPolicyRecorded &&
        harnessAdmission.didConfirmBoundedRunLoopPolicyRecorded &&
        harnessAdmission
            .didConfirmDisplayBackedCAMetalLayerPrerequisiteRecorded &&
        harnessAdmission
            .didConfirmTokenBackedViewLayerDeviceAlignmentPolicyRecorded &&
        harnessAdmission.didConfirmCleanupCoOwnershipPolicyRecorded &&
        harnessAdmission.didConfirmHeadlessCiLikeFailClosedPolicyRecorded &&
        harnessAdmission.didConfirmNoNativeNsWindowHarness &&
        harnessAdmission.didConfirmNoProductionNextDrawableCall &&
        harnessAdmission
            .didConfirmNoColorAttachmentEncoderDrawCommitPresentGpuOrRender &&
        harnessAdmission.didConfirmNoPointerHandleClassIdReturn &&
        harnessAdmission.didConfirmNoPublicSurface &&
        harnessAdmission.didConfirmNoRendererStateWrite &&
        harnessAdmission.didConfirmNoBackendReadyTruth &&
        harnessAdmission.didKeepVisibleWindowHarnessPolicyValueOnly &&
        harnessAdmission.didAvoidDrawableReadyWrapper &&
        harnessAdmission.didAvoidNativeHarnessWrapper &&
        harnessAdmission.didAvoidReceiptRecordPublication

    return CjguiInternalRendererNoVisibleWindowProductionHarnessReadiness(
        harnessAdmission,
        readinessReady,
        !readinessReady,
        false,
        readinessReady,
        harnessAdmission.didAdmitVisibleWindowProductionHarnessPolicyBoundary,
        harnessAdmission.didConfirmProductionNsWindowOwnershipPolicyRecorded,
        harnessAdmission.didConfirmBoundedRunLoopPolicyRecorded,
        harnessAdmission.didConfirmDisplayBackedCAMetalLayerPrerequisiteRecorded,
        harnessAdmission.didConfirmTokenBackedViewLayerDeviceAlignmentPolicyRecorded,
        harnessAdmission.didConfirmCleanupCoOwnershipPolicyRecorded,
        harnessAdmission.didConfirmHeadlessCiLikeFailClosedPolicyRecorded,
        harnessAdmission.didConfirmNoNativeNsWindowHarness,
        harnessAdmission.didConfirmNoProductionNextDrawableCall,
        harnessAdmission.didConfirmNoProductionNextDrawableCall,
        harnessAdmission
            .didConfirmNoColorAttachmentEncoderDrawCommitPresentGpuOrRender,
        harnessAdmission.didConfirmNoPointerHandleClassIdReturn,
        harnessAdmission.didConfirmNoPublicSurface,
        harnessAdmission.didConfirmNoRendererStateWrite,
        harnessAdmission.didConfirmNoBackendReadyTruth,
        harnessAdmission.didKeepVisibleWindowHarnessPolicyValueOnly,
        harnessAdmission.didAvoidNativeHarnessWrapper,
        harnessAdmission.didAvoidDrawableReadyWrapper,
        true,
        harnessAdmission.didAvoidReceiptRecordPublication,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowProductionHarnessDraft():
    CjguiInternalRendererNoVisibleWindowProductionHarnessReadiness {
    let drawableTextureLifetimePlanningReadiness =
        cjguiInternalExecuteDefaultRendererDrawableTextureLifetimePlanningDraft()
    let drawInputBundleReadiness =
        cjguiInternalExecuteDefaultRendererDrawInputBundleDraft()
    let policyFacts =
        cjguiInternalBuildRendererVisibleWindowProductionHarnessPolicyFacts(
            drawableTextureLifetimePlanningReadiness,
            drawInputBundleReadiness
        )
    let harnessAdmission =
        cjguiInternalBuildRendererVisibleWindowProductionHarnessAdmission(
            policyFacts
        )
    return cjguiInternalBuildRendererVisibleWindowProductionHarnessReadiness(
        harnessAdmission
    )
}
