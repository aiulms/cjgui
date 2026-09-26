// 中文维护注释：本文件是 embedded shader source contract owner。
// Truth: 只消费 CjguiInternalRendererNoShaderLibraryNoDrawPlanningReadiness，
// 固定最小 shader source 仅用于 native no-draw compile evidence。
// Stop-line: 不新增 public shader API，不创建 MTLRenderPipelineState，不创建
// encoder，不 draw，不 commit，不 present，不提交 GPU work，不写 runtime_state.cj。
// Same-shape Boundary Brake: shader source contract 不得包装成 pipeline-ready、
// render permission、GPU submission、backend-ready、state write、receipt、record
// 或 publication。
package cjgui

struct CjguiInternalRendererShaderSourceContractFacts {
    let sourceContractValue: Int32
    let pipelineStateStillBlockedValue: Int32
    let encoderBindingStillBlockedValue: Int32
    let drawStillBlockedValue: Int32
    let didConfirmEmbeddedSourceContractAvailable: Bool
    let didConfirmSourceOnlyForNativeNoDrawCompilation: Bool
    let didConfirmNoPublicShaderApi: Bool
    let didConfirmPipelineStateEncoderDrawStillBlocked: Bool

    init(
        sourceContractValue: Int32,
        pipelineStateStillBlockedValue: Int32,
        encoderBindingStillBlockedValue: Int32,
        drawStillBlockedValue: Int32,
        didConfirmEmbeddedSourceContractAvailable: Bool,
        didConfirmSourceOnlyForNativeNoDrawCompilation: Bool,
        didConfirmNoPublicShaderApi: Bool,
        didConfirmPipelineStateEncoderDrawStillBlocked: Bool
    ) {
        this.sourceContractValue = sourceContractValue
        this.pipelineStateStillBlockedValue = pipelineStateStillBlockedValue
        this.encoderBindingStillBlockedValue = encoderBindingStillBlockedValue
        this.drawStillBlockedValue = drawStillBlockedValue
        this.didConfirmEmbeddedSourceContractAvailable =
            didConfirmEmbeddedSourceContractAvailable
        this.didConfirmSourceOnlyForNativeNoDrawCompilation =
            didConfirmSourceOnlyForNativeNoDrawCompilation
        this.didConfirmNoPublicShaderApi = didConfirmNoPublicShaderApi
        this.didConfirmPipelineStateEncoderDrawStillBlocked =
            didConfirmPipelineStateEncoderDrawStillBlocked
    }
}

struct CjguiInternalRendererNoShaderSourceContractReadiness {
    let shaderLibraryNoDrawPlanningReadiness:
        CjguiInternalRendererNoShaderLibraryNoDrawPlanningReadiness
    let sourceContractFacts: CjguiInternalRendererShaderSourceContractFacts
    let didPrepareRendererNoShaderSourceContractReadiness: Bool
    let shouldDeferRendererNoShaderSourceContractReadiness: Bool
    let didConfirmEmbeddedMinimalShaderSourceContract: Bool
    let didConfirmNoPublicShaderApi: Bool
    let didConfirmPipelineStateEncoderDrawStillBlocked: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepShaderSourceContractReadinessDehydrated: Bool
    let didAvoidPipelineReadyWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool

    init(
        shaderLibraryNoDrawPlanningReadiness:
            CjguiInternalRendererNoShaderLibraryNoDrawPlanningReadiness,
        sourceContractFacts: CjguiInternalRendererShaderSourceContractFacts,
        didPrepareRendererNoShaderSourceContractReadiness: Bool,
        shouldDeferRendererNoShaderSourceContractReadiness: Bool,
        didConfirmEmbeddedMinimalShaderSourceContract: Bool,
        didConfirmNoPublicShaderApi: Bool,
        didConfirmPipelineStateEncoderDrawStillBlocked: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepShaderSourceContractReadinessDehydrated: Bool,
        didAvoidPipelineReadyWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool
    ) {
        this.shaderLibraryNoDrawPlanningReadiness =
            shaderLibraryNoDrawPlanningReadiness
        this.sourceContractFacts = sourceContractFacts
        this.didPrepareRendererNoShaderSourceContractReadiness =
            didPrepareRendererNoShaderSourceContractReadiness
        this.shouldDeferRendererNoShaderSourceContractReadiness =
            shouldDeferRendererNoShaderSourceContractReadiness
        this.didConfirmEmbeddedMinimalShaderSourceContract =
            didConfirmEmbeddedMinimalShaderSourceContract
        this.didConfirmNoPublicShaderApi = didConfirmNoPublicShaderApi
        this.didConfirmPipelineStateEncoderDrawStillBlocked =
            didConfirmPipelineStateEncoderDrawStillBlocked
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepShaderSourceContractReadinessDehydrated =
            didKeepShaderSourceContractReadinessDehydrated
        this.didAvoidPipelineReadyWrapper = didAvoidPipelineReadyWrapper
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
    }
}

func cjguiInternalObserveRendererShaderSourceContractFacts():
    CjguiInternalRendererShaderSourceContractFacts {
    let sourceContract = unsafe {
        cjgui_native_bridge_shader_source_contract_available()
    }
    let pipelineStateBlocked = unsafe {
        cjgui_native_bridge_shader_pipeline_state_creation_still_blocked()
    }
    let encoderBlocked = unsafe {
        cjgui_native_bridge_shader_encoder_binding_still_blocked()
    }
    let drawBlocked = unsafe {
        cjgui_native_bridge_shader_draw_still_blocked()
    }

    return CjguiInternalRendererShaderSourceContractFacts(
        sourceContract,
        pipelineStateBlocked,
        encoderBlocked,
        drawBlocked,
        sourceContract == Int32(240),
        true,
        true,
        pipelineStateBlocked == Int32(-252) &&
            encoderBlocked == Int32(-253) &&
            drawBlocked == Int32(-254)
    )
}

func cjguiInternalBuildRendererShaderSourceContractReadiness(
    shaderLibraryNoDrawPlanningReadiness:
        CjguiInternalRendererNoShaderLibraryNoDrawPlanningReadiness,
    sourceContractFacts: CjguiInternalRendererShaderSourceContractFacts
): CjguiInternalRendererNoShaderSourceContractReadiness {
    let upstreamReady =
        shaderLibraryNoDrawPlanningReadiness
            .didPrepareRendererNoShaderLibraryNoDrawPlanningReadiness &&
        shaderLibraryNoDrawPlanningReadiness
            .didConfirmPipelineStateEncoderDrawStillBlocked &&
        shaderLibraryNoDrawPlanningReadiness.didConfirmNoPublicSurface &&
        shaderLibraryNoDrawPlanningReadiness.didConfirmNoRendererStateWrite &&
        shaderLibraryNoDrawPlanningReadiness.didConfirmNoBackendReadyTruth
    let contractReady =
        sourceContractFacts.didConfirmEmbeddedSourceContractAvailable &&
        sourceContractFacts.didConfirmSourceOnlyForNativeNoDrawCompilation &&
        sourceContractFacts.didConfirmNoPublicShaderApi &&
        sourceContractFacts.didConfirmPipelineStateEncoderDrawStillBlocked
    let readinessReady = upstreamReady && contractReady

    return CjguiInternalRendererNoShaderSourceContractReadiness(
        shaderLibraryNoDrawPlanningReadiness,
        sourceContractFacts,
        readinessReady,
        !readinessReady,
        contractReady,
        sourceContractFacts.didConfirmNoPublicShaderApi,
        sourceContractFacts.didConfirmPipelineStateEncoderDrawStillBlocked,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererShaderSourceContractDraft():
    CjguiInternalRendererNoShaderSourceContractReadiness {
    let shaderLibraryNoDrawPlanningReadiness =
        cjguiInternalExecuteDefaultRendererShaderLibraryNoDrawPlanningDraft()
    let sourceContractFacts =
        cjguiInternalObserveRendererShaderSourceContractFacts()
    return cjguiInternalBuildRendererShaderSourceContractReadiness(
        shaderLibraryNoDrawPlanningReadiness,
        sourceContractFacts
    )
}
