// 中文维护注释：本文件是 draw input bundle no-submit owner。
// Truth: 只消费 CjguiInternalRendererNoDrawCallStillBlockedReadiness，
// 聚合 pipeline state / vertex buffer runtime facts 与 encoder-missing blockers。
// Stop-line: 不创建 render command encoder，不调用 setVertexBuffer 或
// setRenderPipelineState，不 draw，不创建 index buffer，不 commit，不 present，
// 不提交 GPU work，不执行 render，不写 runtime_state.cj，不发布 public API。
// Same-shape Boundary Brake: draw input bundle facts 不得包装成 draw
// permission、render permission、GPU submission、backend-ready、state write、
// receipt、record 或 publication。
package cjgui

struct CjguiInternalRendererDrawInputBundleFacts {
    let stillBlockedReadiness:
        CjguiInternalRendererNoDrawCallStillBlockedReadiness
    let didAcceptPipelineStateRuntimeFacts: Bool
    let didAcceptVertexBufferRuntimeFacts: Bool
    let didConfirmRenderCommandEncoderStillMissing: Bool
    let didConfirmPipelineAndVertexBindingsStillBlocked: Bool
    let didConfirmDrawEmissionStillBlocked: Bool
    let didConfirmCommitPresentGpuRenderStillBlocked: Bool
    let didConfirmNoTokenPersistence: Bool

    init(
        stillBlockedReadiness:
            CjguiInternalRendererNoDrawCallStillBlockedReadiness,
        didAcceptPipelineStateRuntimeFacts: Bool,
        didAcceptVertexBufferRuntimeFacts: Bool,
        didConfirmRenderCommandEncoderStillMissing: Bool,
        didConfirmPipelineAndVertexBindingsStillBlocked: Bool,
        didConfirmDrawEmissionStillBlocked: Bool,
        didConfirmCommitPresentGpuRenderStillBlocked: Bool,
        didConfirmNoTokenPersistence: Bool
    ) {
        this.stillBlockedReadiness = stillBlockedReadiness
        this.didAcceptPipelineStateRuntimeFacts =
            didAcceptPipelineStateRuntimeFacts
        this.didAcceptVertexBufferRuntimeFacts = didAcceptVertexBufferRuntimeFacts
        this.didConfirmRenderCommandEncoderStillMissing =
            didConfirmRenderCommandEncoderStillMissing
        this.didConfirmPipelineAndVertexBindingsStillBlocked =
            didConfirmPipelineAndVertexBindingsStillBlocked
        this.didConfirmDrawEmissionStillBlocked =
            didConfirmDrawEmissionStillBlocked
        this.didConfirmCommitPresentGpuRenderStillBlocked =
            didConfirmCommitPresentGpuRenderStillBlocked
        this.didConfirmNoTokenPersistence = didConfirmNoTokenPersistence
    }
}

struct CjguiInternalRendererNoDrawInputBundleReadiness {
    let stillBlockedReadiness:
        CjguiInternalRendererNoDrawCallStillBlockedReadiness
    let drawInputBundleFacts: CjguiInternalRendererDrawInputBundleFacts
    let didPrepareRendererNoDrawInputBundleReadiness: Bool
    let shouldDeferRendererNoDrawInputBundleReadiness: Bool
    let didConfirmPipelineStateRuntimeFactsAccepted: Bool
    let didConfirmVertexBufferRuntimeFactsAccepted: Bool
    let didConfirmEncoderMissing: Bool
    let didConfirmPipelineBindingBlocked: Bool
    let didConfirmVertexBindingBlocked: Bool
    let didConfirmDrawCommitPresentGpuOrRenderBlocked: Bool
    let didConfirmNoTokenPersistence: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepDrawInputBundleReadinessDehydrated: Bool
    let didAvoidDrawPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        stillBlockedReadiness:
            CjguiInternalRendererNoDrawCallStillBlockedReadiness,
        drawInputBundleFacts: CjguiInternalRendererDrawInputBundleFacts,
        didPrepareRendererNoDrawInputBundleReadiness: Bool,
        shouldDeferRendererNoDrawInputBundleReadiness: Bool,
        didConfirmPipelineStateRuntimeFactsAccepted: Bool,
        didConfirmVertexBufferRuntimeFactsAccepted: Bool,
        didConfirmEncoderMissing: Bool,
        didConfirmPipelineBindingBlocked: Bool,
        didConfirmVertexBindingBlocked: Bool,
        didConfirmDrawCommitPresentGpuOrRenderBlocked: Bool,
        didConfirmNoTokenPersistence: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepDrawInputBundleReadinessDehydrated: Bool,
        didAvoidDrawPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.stillBlockedReadiness = stillBlockedReadiness
        this.drawInputBundleFacts = drawInputBundleFacts
        this.didPrepareRendererNoDrawInputBundleReadiness =
            didPrepareRendererNoDrawInputBundleReadiness
        this.shouldDeferRendererNoDrawInputBundleReadiness =
            shouldDeferRendererNoDrawInputBundleReadiness
        this.didConfirmPipelineStateRuntimeFactsAccepted =
            didConfirmPipelineStateRuntimeFactsAccepted
        this.didConfirmVertexBufferRuntimeFactsAccepted =
            didConfirmVertexBufferRuntimeFactsAccepted
        this.didConfirmEncoderMissing = didConfirmEncoderMissing
        this.didConfirmPipelineBindingBlocked =
            didConfirmPipelineBindingBlocked
        this.didConfirmVertexBindingBlocked = didConfirmVertexBindingBlocked
        this.didConfirmDrawCommitPresentGpuOrRenderBlocked =
            didConfirmDrawCommitPresentGpuOrRenderBlocked
        this.didConfirmNoTokenPersistence = didConfirmNoTokenPersistence
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepDrawInputBundleReadinessDehydrated =
            didKeepDrawInputBundleReadinessDehydrated
        this.didAvoidDrawPermissionWrapper = didAvoidDrawPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
    }
}

func cjguiInternalBuildRendererDrawInputBundleReadiness(
    stillBlockedReadiness:
        CjguiInternalRendererNoDrawCallStillBlockedReadiness
): CjguiInternalRendererNoDrawInputBundleReadiness {
    let upstreamReady =
        stillBlockedReadiness.didPrepareRendererNoDrawCallStillBlockedReadiness &&
        stillBlockedReadiness.didConfirmEncoderRequired &&
        stillBlockedReadiness.didConfirmPipelineBindingRequired &&
        stillBlockedReadiness.didConfirmVertexBindingRequired &&
        stillBlockedReadiness.didConfirmDrawStillBlocked &&
        stillBlockedReadiness.didConfirmNoDrawCommitPresentGpuOrRender &&
        stillBlockedReadiness.didConfirmNoPublicSurface &&
        stillBlockedReadiness.didConfirmNoRendererStateWrite &&
        stillBlockedReadiness.didConfirmNoBackendReadyTruth
    let bundleFacts =
        CjguiInternalRendererDrawInputBundleFacts(
            stillBlockedReadiness,
            upstreamReady,
            upstreamReady,
            true,
            true,
            true,
            true,
            true
        )
    let readinessReady =
        upstreamReady &&
        bundleFacts.didAcceptPipelineStateRuntimeFacts &&
        bundleFacts.didAcceptVertexBufferRuntimeFacts &&
        bundleFacts.didConfirmRenderCommandEncoderStillMissing &&
        bundleFacts.didConfirmPipelineAndVertexBindingsStillBlocked &&
        bundleFacts.didConfirmDrawEmissionStillBlocked &&
        bundleFacts.didConfirmCommitPresentGpuRenderStillBlocked &&
        bundleFacts.didConfirmNoTokenPersistence

    return CjguiInternalRendererNoDrawInputBundleReadiness(
        stillBlockedReadiness,
        bundleFacts,
        readinessReady,
        !readinessReady,
        bundleFacts.didAcceptPipelineStateRuntimeFacts,
        bundleFacts.didAcceptVertexBufferRuntimeFacts,
        bundleFacts.didConfirmRenderCommandEncoderStillMissing,
        bundleFacts.didConfirmPipelineAndVertexBindingsStillBlocked,
        bundleFacts.didConfirmPipelineAndVertexBindingsStillBlocked,
        bundleFacts.didConfirmDrawEmissionStillBlocked &&
            bundleFacts.didConfirmCommitPresentGpuRenderStillBlocked,
        bundleFacts.didConfirmNoTokenPersistence,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererDrawInputBundleDraft():
    CjguiInternalRendererNoDrawInputBundleReadiness {
    let stillBlockedReadiness =
        cjguiInternalExecuteDefaultRendererDrawCallStillBlockedDraft()
    return cjguiInternalBuildRendererDrawInputBundleReadiness(
        stillBlockedReadiness
    )
}
