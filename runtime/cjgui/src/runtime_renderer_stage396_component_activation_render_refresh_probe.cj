// 中文维护注释：本文件是 stage396 component activation render refresh probe owner。
// Owner: 消费 stage395 component activation probe，产出 component result / semantic render refresh preview。
// Truth: 只证明 component activation result refresh 的 owner-local dry-run，不提交真实状态或渲染。
// Stop-line: 不扩 public API、不启用 input pipeline、不 dispatch、不提交 state、不写 renderer/runtime state。
// Same-shape Boundary Brake: 本轮消费 component probe 形成 result/render refresh，不新增同构 readiness 包装。
package cjgui

struct CjguiInternalRendererStage396ComponentActivationResultEnvelope {
    let didConsumeStage395SharedActivationExecutorComponentProbe: Bool
    let didMaterializeComponentActivationAcceptedResultRefresh: Bool
    let didMaterializeComponentActivationRejectedRollbackRefresh: Bool
    let didBindResultEnvelopeToComponentOwnerAcceptanceGate: Bool
    let didKeepComponentActivationResultOwnerLocal: Bool
    let didKeepActionDispatchBlocked: Bool

    init(
        didConsumeStage395SharedActivationExecutorComponentProbe: Bool,
        didMaterializeComponentActivationAcceptedResultRefresh: Bool,
        didMaterializeComponentActivationRejectedRollbackRefresh: Bool,
        didBindResultEnvelopeToComponentOwnerAcceptanceGate: Bool,
        didKeepComponentActivationResultOwnerLocal: Bool,
        didKeepActionDispatchBlocked: Bool
    ) {
        this.didConsumeStage395SharedActivationExecutorComponentProbe = didConsumeStage395SharedActivationExecutorComponentProbe
        this.didMaterializeComponentActivationAcceptedResultRefresh = didMaterializeComponentActivationAcceptedResultRefresh
        this.didMaterializeComponentActivationRejectedRollbackRefresh = didMaterializeComponentActivationRejectedRollbackRefresh
        this.didBindResultEnvelopeToComponentOwnerAcceptanceGate = didBindResultEnvelopeToComponentOwnerAcceptanceGate
        this.didKeepComponentActivationResultOwnerLocal = didKeepComponentActivationResultOwnerLocal
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
    }
}

struct CjguiInternalRendererStage396ComponentActivationStateRefresh {
    let didBindTodoComponentActivationResultToSurfaceRefresh: Bool
    let didBindSettingsComponentActivationResultToSurfaceRefresh: Bool
    let didBindAiGeneratedSettingsComponentActivationResultToSurfaceRefresh: Bool
    let didBindAcceptedComponentResultToStateDeltaRefresh: Bool
    let didBindRejectedComponentResultToRollbackRefresh: Bool
    let didKeepComponentActivationStateRefreshPreviewOnly: Bool
    let didKeepStateUpdateCommittedBlocked: Bool

    init(
        didBindTodoComponentActivationResultToSurfaceRefresh: Bool,
        didBindSettingsComponentActivationResultToSurfaceRefresh: Bool,
        didBindAiGeneratedSettingsComponentActivationResultToSurfaceRefresh: Bool,
        didBindAcceptedComponentResultToStateDeltaRefresh: Bool,
        didBindRejectedComponentResultToRollbackRefresh: Bool,
        didKeepComponentActivationStateRefreshPreviewOnly: Bool,
        didKeepStateUpdateCommittedBlocked: Bool
    ) {
        this.didBindTodoComponentActivationResultToSurfaceRefresh = didBindTodoComponentActivationResultToSurfaceRefresh
        this.didBindSettingsComponentActivationResultToSurfaceRefresh = didBindSettingsComponentActivationResultToSurfaceRefresh
        this.didBindAiGeneratedSettingsComponentActivationResultToSurfaceRefresh = didBindAiGeneratedSettingsComponentActivationResultToSurfaceRefresh
        this.didBindAcceptedComponentResultToStateDeltaRefresh = didBindAcceptedComponentResultToStateDeltaRefresh
        this.didBindRejectedComponentResultToRollbackRefresh = didBindRejectedComponentResultToRollbackRefresh
        this.didKeepComponentActivationStateRefreshPreviewOnly = didKeepComponentActivationStateRefreshPreviewOnly
        this.didKeepStateUpdateCommittedBlocked = didKeepStateUpdateCommittedBlocked
    }
}

struct CjguiInternalRendererStage396ComponentActivationSemanticRenderRefresh {
    let didMaterializeSemanticComponentActivationRefresh: Bool
    let didBindComponentActivationRefreshToRenderCommandPlan: Bool
    let didBindComponentActivationRefreshToStage394DemoRenderRefreshHelper: Bool
    let didBindComponentActivationRefreshToStage383RenderBridge: Bool
    let didKeepComponentActivationRefreshPreviewOnly: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool

    init(
        didMaterializeSemanticComponentActivationRefresh: Bool,
        didBindComponentActivationRefreshToRenderCommandPlan: Bool,
        didBindComponentActivationRefreshToStage394DemoRenderRefreshHelper: Bool,
        didBindComponentActivationRefreshToStage383RenderBridge: Bool,
        didKeepComponentActivationRefreshPreviewOnly: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool
    ) {
        this.didMaterializeSemanticComponentActivationRefresh = didMaterializeSemanticComponentActivationRefresh
        this.didBindComponentActivationRefreshToRenderCommandPlan = didBindComponentActivationRefreshToRenderCommandPlan
        this.didBindComponentActivationRefreshToStage394DemoRenderRefreshHelper = didBindComponentActivationRefreshToStage394DemoRenderRefreshHelper
        this.didBindComponentActivationRefreshToStage383RenderBridge = didBindComponentActivationRefreshToStage383RenderBridge
        this.didKeepComponentActivationRefreshPreviewOnly = didKeepComponentActivationRefreshPreviewOnly
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
    }
}

struct CjguiInternalRendererStage396ComponentActivationRenderRefreshProbeFacts {
    let didConsumeStage395SharedActivationExecutorComponentProbe: Bool
    let didConfirmRouteConvergenceNotNeeded: Bool
    let didConfirmStage381ConvergenceExitAlreadyMaterialized: Bool
    let didConfirmStage394SharedActivationExecutorDemoRefreshHelperConsumedTransitively: Bool
    let didMaterializeComponentActivationAcceptedResultRefresh: Bool
    let didMaterializeComponentActivationRejectedRollbackRefresh: Bool
    let didBindTodoComponentActivationResultToSurfaceRefresh: Bool
    let didBindSettingsComponentActivationResultToSurfaceRefresh: Bool
    let didBindAiGeneratedSettingsComponentActivationResultToSurfaceRefresh: Bool
    let didMaterializeSemanticComponentActivationRefresh: Bool
    let didBindComponentActivationRefreshToRenderCommandPlan: Bool
    let didBindComponentActivationRefreshToStage394DemoRenderRefreshHelper: Bool
    let didKeepComponentActivationRefreshPreviewOnly: Bool
    let didPrepareStage397SharedComponentEventBindingMatrix: Bool
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didKeepBackendReadyTruthBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool
    let didKeepLayoutEngineBlocked: Bool
    let didKeepInputEventPipelineBlocked: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepVisibilityNotPublished: Bool

    init(
        didConsumeStage395SharedActivationExecutorComponentProbe: Bool,
        didConfirmRouteConvergenceNotNeeded: Bool,
        didConfirmStage381ConvergenceExitAlreadyMaterialized: Bool,
        didConfirmStage394SharedActivationExecutorDemoRefreshHelperConsumedTransitively: Bool,
        didMaterializeComponentActivationAcceptedResultRefresh: Bool,
        didMaterializeComponentActivationRejectedRollbackRefresh: Bool,
        didBindTodoComponentActivationResultToSurfaceRefresh: Bool,
        didBindSettingsComponentActivationResultToSurfaceRefresh: Bool,
        didBindAiGeneratedSettingsComponentActivationResultToSurfaceRefresh: Bool,
        didMaterializeSemanticComponentActivationRefresh: Bool,
        didBindComponentActivationRefreshToRenderCommandPlan: Bool,
        didBindComponentActivationRefreshToStage394DemoRenderRefreshHelper: Bool,
        didKeepComponentActivationRefreshPreviewOnly: Bool,
        didPrepareStage397SharedComponentEventBindingMatrix: Bool,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didKeepBackendReadyTruthBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool,
        didKeepLayoutEngineBlocked: Bool,
        didKeepInputEventPipelineBlocked: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepVisibilityNotPublished: Bool
    ) {
        this.didConsumeStage395SharedActivationExecutorComponentProbe = didConsumeStage395SharedActivationExecutorComponentProbe
        this.didConfirmRouteConvergenceNotNeeded = didConfirmRouteConvergenceNotNeeded
        this.didConfirmStage381ConvergenceExitAlreadyMaterialized = didConfirmStage381ConvergenceExitAlreadyMaterialized
        this.didConfirmStage394SharedActivationExecutorDemoRefreshHelperConsumedTransitively = didConfirmStage394SharedActivationExecutorDemoRefreshHelperConsumedTransitively
        this.didMaterializeComponentActivationAcceptedResultRefresh = didMaterializeComponentActivationAcceptedResultRefresh
        this.didMaterializeComponentActivationRejectedRollbackRefresh = didMaterializeComponentActivationRejectedRollbackRefresh
        this.didBindTodoComponentActivationResultToSurfaceRefresh = didBindTodoComponentActivationResultToSurfaceRefresh
        this.didBindSettingsComponentActivationResultToSurfaceRefresh = didBindSettingsComponentActivationResultToSurfaceRefresh
        this.didBindAiGeneratedSettingsComponentActivationResultToSurfaceRefresh = didBindAiGeneratedSettingsComponentActivationResultToSurfaceRefresh
        this.didMaterializeSemanticComponentActivationRefresh = didMaterializeSemanticComponentActivationRefresh
        this.didBindComponentActivationRefreshToRenderCommandPlan = didBindComponentActivationRefreshToRenderCommandPlan
        this.didBindComponentActivationRefreshToStage394DemoRenderRefreshHelper = didBindComponentActivationRefreshToStage394DemoRenderRefreshHelper
        this.didKeepComponentActivationRefreshPreviewOnly = didKeepComponentActivationRefreshPreviewOnly
        this.didPrepareStage397SharedComponentEventBindingMatrix = didPrepareStage397SharedComponentEventBindingMatrix
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didKeepOwnerAcceptanceNotGranted = didKeepOwnerAcceptanceNotGranted
        this.didKeepBackendReadyTruthBlocked = didKeepBackendReadyTruthBlocked
        this.didKeepPublicComponentApiBlocked = didKeepPublicComponentApiBlocked
        this.didKeepLayoutEngineBlocked = didKeepLayoutEngineBlocked
        this.didKeepInputEventPipelineBlocked = didKeepInputEventPipelineBlocked
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepStateUpdateCommittedBlocked = didKeepStateUpdateCommittedBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didKeepVisibilityNotPublished = didKeepVisibilityNotPublished
    }
}

struct CjguiInternalRendererStage396ComponentActivationRenderRefreshProbeReadiness {
    let sharedActivationExecutorComponentProbe: CjguiInternalRendererStage395SharedActivationExecutorComponentProbeReadiness
    let componentActivationResultEnvelope: CjguiInternalRendererStage396ComponentActivationResultEnvelope
    let componentActivationStateRefresh: CjguiInternalRendererStage396ComponentActivationStateRefresh
    let componentActivationSemanticRenderRefresh: CjguiInternalRendererStage396ComponentActivationSemanticRenderRefresh
    let componentActivationRenderRefreshProbeFacts: CjguiInternalRendererStage396ComponentActivationRenderRefreshProbeFacts
    let didPrepareStage396ComponentActivationRenderRefreshProbeReadiness: Bool
    let didConfirmStage396ComponentActivationRenderRefreshProbeReady: Bool
    let didConfirmRouteConvergenceNotNeeded: Bool
    let didConfirmStage395SharedActivationExecutorComponentProbeConsumed: Bool
    let didConfirmStage394SharedActivationExecutorDemoRefreshHelperConsumedTransitively: Bool
    let didConfirmComponentActivationAcceptedResultRefreshMaterialized: Bool
    let didConfirmComponentActivationRejectedRollbackRefreshMaterialized: Bool
    let didConfirmTodoComponentActivationResultBoundToSurfaceRefresh: Bool
    let didConfirmSettingsComponentActivationResultBoundToSurfaceRefresh: Bool
    let didConfirmAiGeneratedSettingsComponentActivationResultBoundToSurfaceRefresh: Bool
    let didConfirmSemanticComponentActivationRefreshMaterialized: Bool
    let didConfirmComponentActivationRefreshBoundToRenderCommandPlan: Bool
    let didConfirmComponentActivationRefreshBoundToStage394DemoRenderRefreshHelper: Bool
    let didConfirmComponentActivationRefreshPreviewOnly: Bool
    let didConfirmStage397SharedComponentEventBindingMatrixPrepared: Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmBackendReadyTruth: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmLayoutEngineEnabled: Bool
    let didConfirmInputEventPipelineEnabled: Bool
    let didConfirmActionDispatch: Bool
    let didConfirmStateUpdateCommitted: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmVisibilityPublished: Bool

    init(
        sharedActivationExecutorComponentProbe: CjguiInternalRendererStage395SharedActivationExecutorComponentProbeReadiness,
        componentActivationResultEnvelope: CjguiInternalRendererStage396ComponentActivationResultEnvelope,
        componentActivationStateRefresh: CjguiInternalRendererStage396ComponentActivationStateRefresh,
        componentActivationSemanticRenderRefresh: CjguiInternalRendererStage396ComponentActivationSemanticRenderRefresh,
        componentActivationRenderRefreshProbeFacts: CjguiInternalRendererStage396ComponentActivationRenderRefreshProbeFacts,
        didPrepareStage396ComponentActivationRenderRefreshProbeReadiness: Bool,
        didConfirmStage396ComponentActivationRenderRefreshProbeReady: Bool,
        didConfirmRouteConvergenceNotNeeded: Bool,
        didConfirmStage395SharedActivationExecutorComponentProbeConsumed: Bool,
        didConfirmStage394SharedActivationExecutorDemoRefreshHelperConsumedTransitively: Bool,
        didConfirmComponentActivationAcceptedResultRefreshMaterialized: Bool,
        didConfirmComponentActivationRejectedRollbackRefreshMaterialized: Bool,
        didConfirmTodoComponentActivationResultBoundToSurfaceRefresh: Bool,
        didConfirmSettingsComponentActivationResultBoundToSurfaceRefresh: Bool,
        didConfirmAiGeneratedSettingsComponentActivationResultBoundToSurfaceRefresh: Bool,
        didConfirmSemanticComponentActivationRefreshMaterialized: Bool,
        didConfirmComponentActivationRefreshBoundToRenderCommandPlan: Bool,
        didConfirmComponentActivationRefreshBoundToStage394DemoRenderRefreshHelper: Bool,
        didConfirmComponentActivationRefreshPreviewOnly: Bool,
        didConfirmStage397SharedComponentEventBindingMatrixPrepared: Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmBackendReadyTruth: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmLayoutEngineEnabled: Bool,
        didConfirmInputEventPipelineEnabled: Bool,
        didConfirmActionDispatch: Bool,
        didConfirmStateUpdateCommitted: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmVisibilityPublished: Bool
    ) {
        this.sharedActivationExecutorComponentProbe = sharedActivationExecutorComponentProbe
        this.componentActivationResultEnvelope = componentActivationResultEnvelope
        this.componentActivationStateRefresh = componentActivationStateRefresh
        this.componentActivationSemanticRenderRefresh = componentActivationSemanticRenderRefresh
        this.componentActivationRenderRefreshProbeFacts = componentActivationRenderRefreshProbeFacts
        this.didPrepareStage396ComponentActivationRenderRefreshProbeReadiness = didPrepareStage396ComponentActivationRenderRefreshProbeReadiness
        this.didConfirmStage396ComponentActivationRenderRefreshProbeReady = didConfirmStage396ComponentActivationRenderRefreshProbeReady
        this.didConfirmRouteConvergenceNotNeeded = didConfirmRouteConvergenceNotNeeded
        this.didConfirmStage395SharedActivationExecutorComponentProbeConsumed = didConfirmStage395SharedActivationExecutorComponentProbeConsumed
        this.didConfirmStage394SharedActivationExecutorDemoRefreshHelperConsumedTransitively = didConfirmStage394SharedActivationExecutorDemoRefreshHelperConsumedTransitively
        this.didConfirmComponentActivationAcceptedResultRefreshMaterialized = didConfirmComponentActivationAcceptedResultRefreshMaterialized
        this.didConfirmComponentActivationRejectedRollbackRefreshMaterialized = didConfirmComponentActivationRejectedRollbackRefreshMaterialized
        this.didConfirmTodoComponentActivationResultBoundToSurfaceRefresh = didConfirmTodoComponentActivationResultBoundToSurfaceRefresh
        this.didConfirmSettingsComponentActivationResultBoundToSurfaceRefresh = didConfirmSettingsComponentActivationResultBoundToSurfaceRefresh
        this.didConfirmAiGeneratedSettingsComponentActivationResultBoundToSurfaceRefresh = didConfirmAiGeneratedSettingsComponentActivationResultBoundToSurfaceRefresh
        this.didConfirmSemanticComponentActivationRefreshMaterialized = didConfirmSemanticComponentActivationRefreshMaterialized
        this.didConfirmComponentActivationRefreshBoundToRenderCommandPlan = didConfirmComponentActivationRefreshBoundToRenderCommandPlan
        this.didConfirmComponentActivationRefreshBoundToStage394DemoRenderRefreshHelper = didConfirmComponentActivationRefreshBoundToStage394DemoRenderRefreshHelper
        this.didConfirmComponentActivationRefreshPreviewOnly = didConfirmComponentActivationRefreshPreviewOnly
        this.didConfirmStage397SharedComponentEventBindingMatrixPrepared = didConfirmStage397SharedComponentEventBindingMatrixPrepared
        this.didConfirmOwnerAcceptanceRequired = didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted = didConfirmOwnerAcceptanceGranted
        this.didConfirmBackendReadyTruth = didConfirmBackendReadyTruth
        this.didConfirmPublicComponentApiAdded = didConfirmPublicComponentApiAdded
        this.didConfirmLayoutEngineEnabled = didConfirmLayoutEngineEnabled
        this.didConfirmInputEventPipelineEnabled = didConfirmInputEventPipelineEnabled
        this.didConfirmActionDispatch = didConfirmActionDispatch
        this.didConfirmStateUpdateCommitted = didConfirmStateUpdateCommitted
        this.didConfirmRendererSubmissionBlocked = didConfirmRendererSubmissionBlocked
        this.didConfirmRendererStateWriteBlocked = didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked = didConfirmRuntimeStateWriteBlocked
        this.didConfirmVisibilityPublished = didConfirmVisibilityPublished
    }
}

func cjguiInternalBuildRendererStage396ComponentActivationResultEnvelope(
    sharedActivationExecutorComponentProbe: CjguiInternalRendererStage395SharedActivationExecutorComponentProbeReadiness): CjguiInternalRendererStage396ComponentActivationResultEnvelope {
    let componentProbeReady = sharedActivationExecutorComponentProbe
        .didConfirmStage395SharedActivationExecutorComponentProbeReady && sharedActivationExecutorComponentProbe
        .didConfirmComponentActivationProbePreviewOnly

    return CjguiInternalRendererStage396ComponentActivationResultEnvelope(
        componentProbeReady,
        componentProbeReady && sharedActivationExecutorComponentProbe.didConfirmComponentStateDeltaPreviewMaterialized,
        componentProbeReady && sharedActivationExecutorComponentProbe.didConfirmComponentOwnerAcceptanceGateMaterialized,
        componentProbeReady && sharedActivationExecutorComponentProbe.didConfirmComponentOwnerAcceptanceGateMaterialized,
        componentProbeReady,
        componentProbeReady && sharedActivationExecutorComponentProbe.didConfirmActionDispatch == false
    )
}

func cjguiInternalBuildRendererStage396ComponentActivationStateRefresh(
    sharedActivationExecutorComponentProbe: CjguiInternalRendererStage395SharedActivationExecutorComponentProbeReadiness,
    componentActivationResultEnvelope: CjguiInternalRendererStage396ComponentActivationResultEnvelope
): CjguiInternalRendererStage396ComponentActivationStateRefresh {
    let resultReady = componentActivationResultEnvelope.didMaterializeComponentActivationAcceptedResultRefresh && componentActivationResultEnvelope
        .didMaterializeComponentActivationRejectedRollbackRefresh && componentActivationResultEnvelope
        .didKeepComponentActivationResultOwnerLocal

    return CjguiInternalRendererStage396ComponentActivationStateRefresh(
        resultReady && sharedActivationExecutorComponentProbe.didConfirmTodoAddComponentActivationSlotMaterialized,
        resultReady && sharedActivationExecutorComponentProbe
            .didConfirmSettingsToggleComponentActivationSlotMaterialized,
        resultReady && sharedActivationExecutorComponentProbe
            .didConfirmAiGeneratedSettingsComponentActivationSlotMaterialized,
        resultReady && sharedActivationExecutorComponentProbe.didConfirmComponentStateDeltaPreviewMaterialized,
        resultReady && componentActivationResultEnvelope.didBindResultEnvelopeToComponentOwnerAcceptanceGate,
        resultReady,
        resultReady && sharedActivationExecutorComponentProbe.didConfirmStateUpdateCommitted == false
    )
}

func cjguiInternalBuildRendererStage396ComponentActivationSemanticRenderRefresh(
    sharedActivationExecutorComponentProbe: CjguiInternalRendererStage395SharedActivationExecutorComponentProbeReadiness,
    componentActivationStateRefresh: CjguiInternalRendererStage396ComponentActivationStateRefresh
): CjguiInternalRendererStage396ComponentActivationSemanticRenderRefresh {
    let stateRefreshReady = componentActivationStateRefresh.didBindTodoComponentActivationResultToSurfaceRefresh && componentActivationStateRefresh
        .didBindSettingsComponentActivationResultToSurfaceRefresh && componentActivationStateRefresh
        .didBindAiGeneratedSettingsComponentActivationResultToSurfaceRefresh && componentActivationStateRefresh
        .didKeepComponentActivationStateRefreshPreviewOnly

    return CjguiInternalRendererStage396ComponentActivationSemanticRenderRefresh(
        stateRefreshReady && sharedActivationExecutorComponentProbe
            .didConfirmComponentActivationSlotsBoundToSharedComponentModel,
        stateRefreshReady && sharedActivationExecutorComponentProbe.didConfirmComponentRenderRefreshBindingMaterialized,
        stateRefreshReady && sharedActivationExecutorComponentProbe
            .didConfirmComponentActivationSlotsBoundToStage394DemoRefreshHelper,
        stateRefreshReady && sharedActivationExecutorComponentProbe
            .sharedActivationExecutorDemoRefreshHelper
            .didConfirmDemoRefreshHelperBoundToStage383RenderBridge,
        stateRefreshReady,
        stateRefreshReady && sharedActivationExecutorComponentProbe.didConfirmRendererSubmissionBlocked,
        stateRefreshReady && sharedActivationExecutorComponentProbe.didConfirmRendererStateWriteBlocked,
        stateRefreshReady && sharedActivationExecutorComponentProbe.didConfirmRuntimeStateWriteBlocked
    )
}

func cjguiInternalBuildRendererStage396ComponentActivationRenderRefreshProbeFacts(
    sharedActivationExecutorComponentProbe: CjguiInternalRendererStage395SharedActivationExecutorComponentProbeReadiness,
    componentActivationResultEnvelope: CjguiInternalRendererStage396ComponentActivationResultEnvelope,
    componentActivationStateRefresh: CjguiInternalRendererStage396ComponentActivationStateRefresh,
    componentActivationSemanticRenderRefresh: CjguiInternalRendererStage396ComponentActivationSemanticRenderRefresh
): CjguiInternalRendererStage396ComponentActivationRenderRefreshProbeFacts {
    return CjguiInternalRendererStage396ComponentActivationRenderRefreshProbeFacts(
        componentActivationResultEnvelope.didConsumeStage395SharedActivationExecutorComponentProbe,
        sharedActivationExecutorComponentProbe.didConfirmRouteConvergenceNotNeeded,
        sharedActivationExecutorComponentProbe
            .sharedActivationExecutorComponentProbeFacts
            .didConfirmStage381ConvergenceExitAlreadyMaterialized,
        sharedActivationExecutorComponentProbe.didConfirmStage394SharedActivationExecutorDemoRefreshHelperConsumed,
        componentActivationResultEnvelope.didMaterializeComponentActivationAcceptedResultRefresh,
        componentActivationResultEnvelope.didMaterializeComponentActivationRejectedRollbackRefresh,
        componentActivationStateRefresh.didBindTodoComponentActivationResultToSurfaceRefresh,
        componentActivationStateRefresh.didBindSettingsComponentActivationResultToSurfaceRefresh,
        componentActivationStateRefresh.didBindAiGeneratedSettingsComponentActivationResultToSurfaceRefresh,
        componentActivationSemanticRenderRefresh.didMaterializeSemanticComponentActivationRefresh,
        componentActivationSemanticRenderRefresh.didBindComponentActivationRefreshToRenderCommandPlan,
        componentActivationSemanticRenderRefresh.didBindComponentActivationRefreshToStage394DemoRenderRefreshHelper,
        componentActivationSemanticRenderRefresh.didKeepComponentActivationRefreshPreviewOnly,
        componentActivationSemanticRenderRefresh.didKeepComponentActivationRefreshPreviewOnly,
        sharedActivationExecutorComponentProbe.didConfirmOwnerAcceptanceRequired,
        sharedActivationExecutorComponentProbe.didConfirmOwnerAcceptanceGranted == false,
        sharedActivationExecutorComponentProbe.didConfirmBackendReadyTruth == false,
        sharedActivationExecutorComponentProbe.didConfirmPublicComponentApiAdded == false,
        sharedActivationExecutorComponentProbe.didConfirmLayoutEngineEnabled == false,
        sharedActivationExecutorComponentProbe.didConfirmInputEventPipelineEnabled == false,
        sharedActivationExecutorComponentProbe.didConfirmActionDispatch == false,
        sharedActivationExecutorComponentProbe.didConfirmStateUpdateCommitted == false,
        sharedActivationExecutorComponentProbe.didConfirmRendererSubmissionBlocked,
        sharedActivationExecutorComponentProbe.didConfirmRendererStateWriteBlocked,
        sharedActivationExecutorComponentProbe.didConfirmRuntimeStateWriteBlocked,
        sharedActivationExecutorComponentProbe.didConfirmVisibilityPublished == false
    )
}

func cjguiInternalBuildRendererStage396ComponentActivationRenderRefreshProbeReadiness(
    sharedActivationExecutorComponentProbe: CjguiInternalRendererStage395SharedActivationExecutorComponentProbeReadiness,
    componentActivationResultEnvelope: CjguiInternalRendererStage396ComponentActivationResultEnvelope,
    componentActivationStateRefresh: CjguiInternalRendererStage396ComponentActivationStateRefresh,
    componentActivationSemanticRenderRefresh: CjguiInternalRendererStage396ComponentActivationSemanticRenderRefresh,
    componentActivationRenderRefreshProbeFacts: CjguiInternalRendererStage396ComponentActivationRenderRefreshProbeFacts
): CjguiInternalRendererStage396ComponentActivationRenderRefreshProbeReadiness {
    let componentRefreshReady = componentActivationRenderRefreshProbeFacts
        .didConsumeStage395SharedActivationExecutorComponentProbe && componentActivationRenderRefreshProbeFacts
        .didConfirmRouteConvergenceNotNeeded && componentActivationRenderRefreshProbeFacts
        .didConfirmStage381ConvergenceExitAlreadyMaterialized && componentActivationRenderRefreshProbeFacts
        .didConfirmStage394SharedActivationExecutorDemoRefreshHelperConsumedTransitively && componentActivationRenderRefreshProbeFacts
        .didMaterializeComponentActivationAcceptedResultRefresh && componentActivationRenderRefreshProbeFacts
        .didMaterializeComponentActivationRejectedRollbackRefresh && componentActivationRenderRefreshProbeFacts
        .didBindTodoComponentActivationResultToSurfaceRefresh && componentActivationRenderRefreshProbeFacts
        .didBindSettingsComponentActivationResultToSurfaceRefresh && componentActivationRenderRefreshProbeFacts
        .didBindAiGeneratedSettingsComponentActivationResultToSurfaceRefresh && componentActivationRenderRefreshProbeFacts
        .didMaterializeSemanticComponentActivationRefresh && componentActivationRenderRefreshProbeFacts
        .didBindComponentActivationRefreshToRenderCommandPlan && componentActivationRenderRefreshProbeFacts
        .didBindComponentActivationRefreshToStage394DemoRenderRefreshHelper && componentActivationRenderRefreshProbeFacts
        .didKeepComponentActivationRefreshPreviewOnly && componentActivationRenderRefreshProbeFacts
        .didPrepareStage397SharedComponentEventBindingMatrix
    let stopLineReady = componentActivationRenderRefreshProbeFacts.didKeepOwnerAcceptanceRequired && componentActivationRenderRefreshProbeFacts
        .didKeepOwnerAcceptanceNotGranted && componentActivationRenderRefreshProbeFacts.didKeepBackendReadyTruthBlocked &&
        componentActivationRenderRefreshProbeFacts.didKeepPublicComponentApiBlocked && componentActivationRenderRefreshProbeFacts
        .didKeepLayoutEngineBlocked && componentActivationRenderRefreshProbeFacts.didKeepInputEventPipelineBlocked && componentActivationRenderRefreshProbeFacts
        .didKeepActionDispatchBlocked && componentActivationRenderRefreshProbeFacts.didKeepStateUpdateCommittedBlocked &&
        componentActivationRenderRefreshProbeFacts.didKeepRendererSubmissionBlocked && componentActivationRenderRefreshProbeFacts
        .didKeepRendererStateWriteBlocked && componentActivationRenderRefreshProbeFacts.didKeepRuntimeStateWriteBlocked &&
        componentActivationRenderRefreshProbeFacts.didKeepVisibilityNotPublished

    return CjguiInternalRendererStage396ComponentActivationRenderRefreshProbeReadiness(
        sharedActivationExecutorComponentProbe,
        componentActivationResultEnvelope,
        componentActivationStateRefresh,
        componentActivationSemanticRenderRefresh,
        componentActivationRenderRefreshProbeFacts,
        componentRefreshReady && stopLineReady,
        componentRefreshReady && stopLineReady,
        componentActivationRenderRefreshProbeFacts.didConfirmRouteConvergenceNotNeeded,
        componentActivationRenderRefreshProbeFacts.didConsumeStage395SharedActivationExecutorComponentProbe,
        componentActivationRenderRefreshProbeFacts
            .didConfirmStage394SharedActivationExecutorDemoRefreshHelperConsumedTransitively,
        componentActivationRenderRefreshProbeFacts.didMaterializeComponentActivationAcceptedResultRefresh,
        componentActivationRenderRefreshProbeFacts.didMaterializeComponentActivationRejectedRollbackRefresh,
        componentActivationRenderRefreshProbeFacts.didBindTodoComponentActivationResultToSurfaceRefresh,
        componentActivationRenderRefreshProbeFacts.didBindSettingsComponentActivationResultToSurfaceRefresh,
        componentActivationRenderRefreshProbeFacts.didBindAiGeneratedSettingsComponentActivationResultToSurfaceRefresh,
        componentActivationRenderRefreshProbeFacts.didMaterializeSemanticComponentActivationRefresh,
        componentActivationRenderRefreshProbeFacts.didBindComponentActivationRefreshToRenderCommandPlan,
        componentActivationRenderRefreshProbeFacts.didBindComponentActivationRefreshToStage394DemoRenderRefreshHelper,
        componentActivationRenderRefreshProbeFacts.didKeepComponentActivationRefreshPreviewOnly,
        componentActivationRenderRefreshProbeFacts.didPrepareStage397SharedComponentEventBindingMatrix,
        componentActivationRenderRefreshProbeFacts.didKeepOwnerAcceptanceRequired,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        componentActivationRenderRefreshProbeFacts.didKeepRendererSubmissionBlocked,
        componentActivationRenderRefreshProbeFacts.didKeepRendererStateWriteBlocked,
        componentActivationRenderRefreshProbeFacts.didKeepRuntimeStateWriteBlocked,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage396ComponentActivationRenderRefreshProbeDraft(): CjguiInternalRendererStage396ComponentActivationRenderRefreshProbeReadiness {
    let sharedActivationExecutorComponentProbe = cjguiInternalExecuteDefaultRendererStage395SharedActivationExecutorComponentProbeDraft()
    let componentActivationResultEnvelope = cjguiInternalBuildRendererStage396ComponentActivationResultEnvelope(
        sharedActivationExecutorComponentProbe)
    let componentActivationStateRefresh = cjguiInternalBuildRendererStage396ComponentActivationStateRefresh(
        sharedActivationExecutorComponentProbe,
        componentActivationResultEnvelope
    )
    let componentActivationSemanticRenderRefresh = cjguiInternalBuildRendererStage396ComponentActivationSemanticRenderRefresh(
        sharedActivationExecutorComponentProbe,
        componentActivationStateRefresh
    )
    let facts = cjguiInternalBuildRendererStage396ComponentActivationRenderRefreshProbeFacts(
        sharedActivationExecutorComponentProbe,
        componentActivationResultEnvelope,
        componentActivationStateRefresh,
        componentActivationSemanticRenderRefresh
    )
    return cjguiInternalBuildRendererStage396ComponentActivationRenderRefreshProbeReadiness(
        sharedActivationExecutorComponentProbe,
        componentActivationResultEnvelope,
        componentActivationStateRefresh,
        componentActivationSemanticRenderRefresh,
        facts
    )
}
