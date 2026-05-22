// 中文维护注释：本文件是 stage386 edited text -> render refresh demo probe owner。
// Owner: 消费 stage385 text input/focus editing readiness，产出 edited text demo surface 与 RenderCommand refresh preview。
// Truth: 只证明编辑后的 text/focus delta 可进入 owner-local state/render dry-run，不执行提交或 renderer submission。
// Stop-line: 不扩 public API、不启用 input event pipeline、不 dispatch、不提交 state、不提交 renderer、不写 renderer/runtime state。
// Same-shape Boundary Brake: 本轮消费 stage385 editing 输出，形成相邻 render refresh 链路。
package cjgui

struct CjguiInternalRendererStage386EditedTextDemoSurfaceRefresh {
    let didConsumeStage385SharedTextInputFocusEditingDemoProbe: Bool
    let didConsumeEditedTextBufferDelta: Bool
    let didMaterializeTodoEditedTextSurfaceRefreshPreview: Bool
    let didMaterializeSettingsFocusSurfaceRefreshPreview: Bool
    let didMaterializeCaretRenderCommandRefreshPreview: Bool
    let didKeepDemoSurfaceRefreshOwnerLocal: Bool
    let didKeepEditedTextRefreshPreviewOnly: Bool
    let didKeepVisibilityNotPublished: Bool

    init(
        didConsumeStage385SharedTextInputFocusEditingDemoProbe: Bool,
        didConsumeEditedTextBufferDelta: Bool,
        didMaterializeTodoEditedTextSurfaceRefreshPreview: Bool,
        didMaterializeSettingsFocusSurfaceRefreshPreview: Bool,
        didMaterializeCaretRenderCommandRefreshPreview: Bool,
        didKeepDemoSurfaceRefreshOwnerLocal: Bool,
        didKeepEditedTextRefreshPreviewOnly: Bool,
        didKeepVisibilityNotPublished: Bool
    ) {
        this.didConsumeStage385SharedTextInputFocusEditingDemoProbe =
            didConsumeStage385SharedTextInputFocusEditingDemoProbe
        this.didConsumeEditedTextBufferDelta = didConsumeEditedTextBufferDelta
        this.didMaterializeTodoEditedTextSurfaceRefreshPreview =
            didMaterializeTodoEditedTextSurfaceRefreshPreview
        this.didMaterializeSettingsFocusSurfaceRefreshPreview =
            didMaterializeSettingsFocusSurfaceRefreshPreview
        this.didMaterializeCaretRenderCommandRefreshPreview =
            didMaterializeCaretRenderCommandRefreshPreview
        this.didKeepDemoSurfaceRefreshOwnerLocal = didKeepDemoSurfaceRefreshOwnerLocal
        this.didKeepEditedTextRefreshPreviewOnly = didKeepEditedTextRefreshPreviewOnly
        this.didKeepVisibilityNotPublished = didKeepVisibilityNotPublished
    }
}

struct CjguiInternalRendererStage386EditedTextRenderCommandRefreshPlan {
    let didMaterializeEditedTextRenderCommandRefreshPlan: Bool
    let didBindEditedTextRefreshToStage383RenderBridge: Bool
    let didBindEditedTextRefreshToStage384InputAdapter: Bool
    let didBindEditedTextRefreshToStage385EditingDryRun: Bool
    let didBindRefreshPlanToTodoEditedTextSurface: Bool
    let didBindRefreshPlanToSettingsFocusSurface: Bool
    let didKeepRenderCommandRefreshPreviewOnly: Bool
    let didKeepRendererSubmissionBlocked: Bool

    init(
        didMaterializeEditedTextRenderCommandRefreshPlan: Bool,
        didBindEditedTextRefreshToStage383RenderBridge: Bool,
        didBindEditedTextRefreshToStage384InputAdapter: Bool,
        didBindEditedTextRefreshToStage385EditingDryRun: Bool,
        didBindRefreshPlanToTodoEditedTextSurface: Bool,
        didBindRefreshPlanToSettingsFocusSurface: Bool,
        didKeepRenderCommandRefreshPreviewOnly: Bool,
        didKeepRendererSubmissionBlocked: Bool
    ) {
        this.didMaterializeEditedTextRenderCommandRefreshPlan =
            didMaterializeEditedTextRenderCommandRefreshPlan
        this.didBindEditedTextRefreshToStage383RenderBridge =
            didBindEditedTextRefreshToStage383RenderBridge
        this.didBindEditedTextRefreshToStage384InputAdapter =
            didBindEditedTextRefreshToStage384InputAdapter
        this.didBindEditedTextRefreshToStage385EditingDryRun =
            didBindEditedTextRefreshToStage385EditingDryRun
        this.didBindRefreshPlanToTodoEditedTextSurface = didBindRefreshPlanToTodoEditedTextSurface
        this.didBindRefreshPlanToSettingsFocusSurface = didBindRefreshPlanToSettingsFocusSurface
        this.didKeepRenderCommandRefreshPreviewOnly = didKeepRenderCommandRefreshPreviewOnly
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
    }
}

struct CjguiInternalRendererStage386EditedTextStateRenderExecutorDryRun {
    let didMaterializeOwnerLocalEditedTextStateRenderDryRun: Bool
    let didBindEditedTextStateRenderDryRunToSurfaceRefresh: Bool
    let didBindEditedTextStateRenderDryRunToRenderCommandRefreshPlan: Bool
    let didKeepEditedTextStateUpdateUncommitted: Bool
    let didKeepEditedTextRefreshPreviewOnly: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepInputEventPipelineBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool

    init(
        didMaterializeOwnerLocalEditedTextStateRenderDryRun: Bool,
        didBindEditedTextStateRenderDryRunToSurfaceRefresh: Bool,
        didBindEditedTextStateRenderDryRunToRenderCommandRefreshPlan: Bool,
        didKeepEditedTextStateUpdateUncommitted: Bool,
        didKeepEditedTextRefreshPreviewOnly: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepInputEventPipelineBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool
    ) {
        this.didMaterializeOwnerLocalEditedTextStateRenderDryRun =
            didMaterializeOwnerLocalEditedTextStateRenderDryRun
        this.didBindEditedTextStateRenderDryRunToSurfaceRefresh =
            didBindEditedTextStateRenderDryRunToSurfaceRefresh
        this.didBindEditedTextStateRenderDryRunToRenderCommandRefreshPlan =
            didBindEditedTextStateRenderDryRunToRenderCommandRefreshPlan
        this.didKeepEditedTextStateUpdateUncommitted = didKeepEditedTextStateUpdateUncommitted
        this.didKeepEditedTextRefreshPreviewOnly = didKeepEditedTextRefreshPreviewOnly
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepInputEventPipelineBlocked = didKeepInputEventPipelineBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
    }
}

struct CjguiInternalRendererStage386EditedTextRenderRefreshDemoProbeFacts {
    let didConsumeStage385SharedTextInputFocusEditingDemoProbe: Bool
    let didConfirmRouteConvergenceNotNeeded: Bool
    let didConfirmStage381ConvergenceExitAlreadyMaterialized: Bool
    let didConfirmStage384SharedInputEventAdapterConsumedTransitively: Bool
    let didConsumeEditedTextBufferDelta: Bool
    let didMaterializeTodoEditedTextSurfaceRefreshPreview: Bool
    let didMaterializeSettingsFocusSurfaceRefreshPreview: Bool
    let didMaterializeCaretRenderCommandRefreshPreview: Bool
    let didMaterializeEditedTextRenderCommandRefreshPlan: Bool
    let didBindEditedTextRefreshToStage383RenderBridge: Bool
    let didBindEditedTextRefreshToStage384InputAdapter: Bool
    let didBindEditedTextRefreshToStage385EditingDryRun: Bool
    let didMaterializeOwnerLocalEditedTextStateRenderDryRun: Bool
    let didKeepEditedTextRefreshPreviewOnly: Bool
    let didPrepareStage387SharedTextEditActionCommitDryRun: Bool
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
        didConsumeStage385SharedTextInputFocusEditingDemoProbe: Bool,
        didConfirmRouteConvergenceNotNeeded: Bool,
        didConfirmStage381ConvergenceExitAlreadyMaterialized: Bool,
        didConfirmStage384SharedInputEventAdapterConsumedTransitively: Bool,
        didConsumeEditedTextBufferDelta: Bool,
        didMaterializeTodoEditedTextSurfaceRefreshPreview: Bool,
        didMaterializeSettingsFocusSurfaceRefreshPreview: Bool,
        didMaterializeCaretRenderCommandRefreshPreview: Bool,
        didMaterializeEditedTextRenderCommandRefreshPlan: Bool,
        didBindEditedTextRefreshToStage383RenderBridge: Bool,
        didBindEditedTextRefreshToStage384InputAdapter: Bool,
        didBindEditedTextRefreshToStage385EditingDryRun: Bool,
        didMaterializeOwnerLocalEditedTextStateRenderDryRun: Bool,
        didKeepEditedTextRefreshPreviewOnly: Bool,
        didPrepareStage387SharedTextEditActionCommitDryRun: Bool,
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
        this.didConsumeStage385SharedTextInputFocusEditingDemoProbe =
            didConsumeStage385SharedTextInputFocusEditingDemoProbe
        this.didConfirmRouteConvergenceNotNeeded = didConfirmRouteConvergenceNotNeeded
        this.didConfirmStage381ConvergenceExitAlreadyMaterialized =
            didConfirmStage381ConvergenceExitAlreadyMaterialized
        this.didConfirmStage384SharedInputEventAdapterConsumedTransitively =
            didConfirmStage384SharedInputEventAdapterConsumedTransitively
        this.didConsumeEditedTextBufferDelta = didConsumeEditedTextBufferDelta
        this.didMaterializeTodoEditedTextSurfaceRefreshPreview =
            didMaterializeTodoEditedTextSurfaceRefreshPreview
        this.didMaterializeSettingsFocusSurfaceRefreshPreview =
            didMaterializeSettingsFocusSurfaceRefreshPreview
        this.didMaterializeCaretRenderCommandRefreshPreview =
            didMaterializeCaretRenderCommandRefreshPreview
        this.didMaterializeEditedTextRenderCommandRefreshPlan =
            didMaterializeEditedTextRenderCommandRefreshPlan
        this.didBindEditedTextRefreshToStage383RenderBridge =
            didBindEditedTextRefreshToStage383RenderBridge
        this.didBindEditedTextRefreshToStage384InputAdapter =
            didBindEditedTextRefreshToStage384InputAdapter
        this.didBindEditedTextRefreshToStage385EditingDryRun =
            didBindEditedTextRefreshToStage385EditingDryRun
        this.didMaterializeOwnerLocalEditedTextStateRenderDryRun =
            didMaterializeOwnerLocalEditedTextStateRenderDryRun
        this.didKeepEditedTextRefreshPreviewOnly = didKeepEditedTextRefreshPreviewOnly
        this.didPrepareStage387SharedTextEditActionCommitDryRun =
            didPrepareStage387SharedTextEditActionCommitDryRun
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

struct CjguiInternalRendererStage386EditedTextRenderRefreshDemoProbeReadiness {
    let sharedTextInputFocusEditingDemoProbe:
        CjguiInternalRendererStage385SharedTextInputFocusEditingDemoProbeReadiness
    let editedTextDemoSurfaceRefresh: CjguiInternalRendererStage386EditedTextDemoSurfaceRefresh
    let editedTextRenderCommandRefreshPlan: CjguiInternalRendererStage386EditedTextRenderCommandRefreshPlan
    let editedTextStateRenderExecutorDryRun:
        CjguiInternalRendererStage386EditedTextStateRenderExecutorDryRun
    let editedTextRenderRefreshDemoProbeFacts:
        CjguiInternalRendererStage386EditedTextRenderRefreshDemoProbeFacts
    let didPrepareStage386EditedTextRenderRefreshDemoProbeReadiness: Bool
    let didConfirmStage386EditedTextRenderRefreshDemoProbeReady: Bool
    let didConfirmRouteConvergenceNotNeeded: Bool
    let didConfirmStage385SharedTextInputFocusEditingDemoProbeConsumed: Bool
    let didConfirmStage384SharedInputEventAdapterConsumedTransitively: Bool
    let didConfirmEditedTextBufferDeltaConsumed: Bool
    let didConfirmTodoEditedTextSurfaceRefreshPreviewMaterialized: Bool
    let didConfirmSettingsFocusSurfaceRefreshPreviewMaterialized: Bool
    let didConfirmCaretRenderCommandRefreshPreviewMaterialized: Bool
    let didConfirmEditedTextRenderCommandRefreshPlanMaterialized: Bool
    let didConfirmEditedTextRefreshBoundToStage383RenderBridge: Bool
    let didConfirmEditedTextRefreshBoundToStage384InputAdapter: Bool
    let didConfirmEditedTextRefreshBoundToStage385EditingDryRun: Bool
    let didConfirmOwnerLocalEditedTextStateRenderDryRunMaterialized: Bool
    let didConfirmEditedTextRefreshPreviewOnly: Bool
    let didConfirmStage387SharedTextEditActionCommitDryRunPrepared: Bool
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
        sharedTextInputFocusEditingDemoProbe:
            CjguiInternalRendererStage385SharedTextInputFocusEditingDemoProbeReadiness,
        editedTextDemoSurfaceRefresh: CjguiInternalRendererStage386EditedTextDemoSurfaceRefresh,
        editedTextRenderCommandRefreshPlan:
            CjguiInternalRendererStage386EditedTextRenderCommandRefreshPlan,
        editedTextStateRenderExecutorDryRun:
            CjguiInternalRendererStage386EditedTextStateRenderExecutorDryRun,
        editedTextRenderRefreshDemoProbeFacts:
            CjguiInternalRendererStage386EditedTextRenderRefreshDemoProbeFacts,
        didPrepareStage386EditedTextRenderRefreshDemoProbeReadiness: Bool,
        didConfirmStage386EditedTextRenderRefreshDemoProbeReady: Bool,
        didConfirmRouteConvergenceNotNeeded: Bool,
        didConfirmStage385SharedTextInputFocusEditingDemoProbeConsumed: Bool,
        didConfirmStage384SharedInputEventAdapterConsumedTransitively: Bool,
        didConfirmEditedTextBufferDeltaConsumed: Bool,
        didConfirmTodoEditedTextSurfaceRefreshPreviewMaterialized: Bool,
        didConfirmSettingsFocusSurfaceRefreshPreviewMaterialized: Bool,
        didConfirmCaretRenderCommandRefreshPreviewMaterialized: Bool,
        didConfirmEditedTextRenderCommandRefreshPlanMaterialized: Bool,
        didConfirmEditedTextRefreshBoundToStage383RenderBridge: Bool,
        didConfirmEditedTextRefreshBoundToStage384InputAdapter: Bool,
        didConfirmEditedTextRefreshBoundToStage385EditingDryRun: Bool,
        didConfirmOwnerLocalEditedTextStateRenderDryRunMaterialized: Bool,
        didConfirmEditedTextRefreshPreviewOnly: Bool,
        didConfirmStage387SharedTextEditActionCommitDryRunPrepared: Bool,
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
        this.sharedTextInputFocusEditingDemoProbe = sharedTextInputFocusEditingDemoProbe
        this.editedTextDemoSurfaceRefresh = editedTextDemoSurfaceRefresh
        this.editedTextRenderCommandRefreshPlan = editedTextRenderCommandRefreshPlan
        this.editedTextStateRenderExecutorDryRun = editedTextStateRenderExecutorDryRun
        this.editedTextRenderRefreshDemoProbeFacts = editedTextRenderRefreshDemoProbeFacts
        this.didPrepareStage386EditedTextRenderRefreshDemoProbeReadiness =
            didPrepareStage386EditedTextRenderRefreshDemoProbeReadiness
        this.didConfirmStage386EditedTextRenderRefreshDemoProbeReady =
            didConfirmStage386EditedTextRenderRefreshDemoProbeReady
        this.didConfirmRouteConvergenceNotNeeded = didConfirmRouteConvergenceNotNeeded
        this.didConfirmStage385SharedTextInputFocusEditingDemoProbeConsumed =
            didConfirmStage385SharedTextInputFocusEditingDemoProbeConsumed
        this.didConfirmStage384SharedInputEventAdapterConsumedTransitively =
            didConfirmStage384SharedInputEventAdapterConsumedTransitively
        this.didConfirmEditedTextBufferDeltaConsumed = didConfirmEditedTextBufferDeltaConsumed
        this.didConfirmTodoEditedTextSurfaceRefreshPreviewMaterialized =
            didConfirmTodoEditedTextSurfaceRefreshPreviewMaterialized
        this.didConfirmSettingsFocusSurfaceRefreshPreviewMaterialized =
            didConfirmSettingsFocusSurfaceRefreshPreviewMaterialized
        this.didConfirmCaretRenderCommandRefreshPreviewMaterialized =
            didConfirmCaretRenderCommandRefreshPreviewMaterialized
        this.didConfirmEditedTextRenderCommandRefreshPlanMaterialized =
            didConfirmEditedTextRenderCommandRefreshPlanMaterialized
        this.didConfirmEditedTextRefreshBoundToStage383RenderBridge =
            didConfirmEditedTextRefreshBoundToStage383RenderBridge
        this.didConfirmEditedTextRefreshBoundToStage384InputAdapter =
            didConfirmEditedTextRefreshBoundToStage384InputAdapter
        this.didConfirmEditedTextRefreshBoundToStage385EditingDryRun =
            didConfirmEditedTextRefreshBoundToStage385EditingDryRun
        this.didConfirmOwnerLocalEditedTextStateRenderDryRunMaterialized =
            didConfirmOwnerLocalEditedTextStateRenderDryRunMaterialized
        this.didConfirmEditedTextRefreshPreviewOnly = didConfirmEditedTextRefreshPreviewOnly
        this.didConfirmStage387SharedTextEditActionCommitDryRunPrepared =
            didConfirmStage387SharedTextEditActionCommitDryRunPrepared
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

func cjguiInternalBuildRendererStage386EditedTextDemoSurfaceRefresh(
    sharedTextInputFocusEditingDemoProbe:
        CjguiInternalRendererStage385SharedTextInputFocusEditingDemoProbeReadiness
): CjguiInternalRendererStage386EditedTextDemoSurfaceRefresh {
    let editingReady =
        sharedTextInputFocusEditingDemoProbe.didConfirmStage385SharedTextInputFocusEditingDemoProbeReady &&
        sharedTextInputFocusEditingDemoProbe.didConfirmOwnerLocalTextBufferDeltaMaterialized &&
        sharedTextInputFocusEditingDemoProbe.didConfirmCaretAndSelectionPreviewMaterialized &&
        sharedTextInputFocusEditingDemoProbe.didConfirmFocusAfterEditingPreviewMaterialized &&
        sharedTextInputFocusEditingDemoProbe.didConfirmTextEditingDryRunOnly

    return CjguiInternalRendererStage386EditedTextDemoSurfaceRefresh(
        sharedTextInputFocusEditingDemoProbe.didConfirmStage385SharedTextInputFocusEditingDemoProbeReady,
        editingReady,
        editingReady && sharedTextInputFocusEditingDemoProbe.didConfirmSharedTextModelConsumedByEditing,
        editingReady &&
            sharedTextInputFocusEditingDemoProbe.didConfirmSettingsFocusTargetPreservedDuringTextEditing,
        editingReady && sharedTextInputFocusEditingDemoProbe.didConfirmCaretAndSelectionPreviewMaterialized,
        editingReady && sharedTextInputFocusEditingDemoProbe.didConfirmVisibilityPublished == false,
        editingReady,
        editingReady && sharedTextInputFocusEditingDemoProbe.didConfirmVisibilityPublished == false
    )
}

func cjguiInternalBuildRendererStage386EditedTextRenderCommandRefreshPlan(
    sharedTextInputFocusEditingDemoProbe:
        CjguiInternalRendererStage385SharedTextInputFocusEditingDemoProbeReadiness,
    editedTextDemoSurfaceRefresh: CjguiInternalRendererStage386EditedTextDemoSurfaceRefresh
): CjguiInternalRendererStage386EditedTextRenderCommandRefreshPlan {
    let stage384Probe = sharedTextInputFocusEditingDemoProbe.sharedInputEventToActionIntentAdapterDemoProbe
    let stage383Bridge =
        stage384Probe.sharedActionStateRenderBridgeDemoProbe.sharedActionRenderCommandRefreshBridge
    let surfaceReady =
        editedTextDemoSurfaceRefresh.didConsumeEditedTextBufferDelta &&
        editedTextDemoSurfaceRefresh.didMaterializeTodoEditedTextSurfaceRefreshPreview &&
        editedTextDemoSurfaceRefresh.didMaterializeSettingsFocusSurfaceRefreshPreview &&
        editedTextDemoSurfaceRefresh.didMaterializeCaretRenderCommandRefreshPreview &&
        editedTextDemoSurfaceRefresh.didKeepEditedTextRefreshPreviewOnly

    return CjguiInternalRendererStage386EditedTextRenderCommandRefreshPlan(
        surfaceReady,
        surfaceReady && stage383Bridge.didMaterializeRenderCommandRefreshBridgeFromSharedAction,
        surfaceReady && stage384Probe.didConfirmInputEventToActionIntentAdapterMaterialized,
        surfaceReady && sharedTextInputFocusEditingDemoProbe.didConfirmTextEditingDryRunOnly,
        surfaceReady && editedTextDemoSurfaceRefresh.didMaterializeTodoEditedTextSurfaceRefreshPreview,
        surfaceReady && editedTextDemoSurfaceRefresh.didMaterializeSettingsFocusSurfaceRefreshPreview,
        surfaceReady && stage383Bridge.didKeepRenderCommandRefreshPreviewOnly,
        surfaceReady && sharedTextInputFocusEditingDemoProbe.didConfirmRendererSubmissionBlocked
    )
}

func cjguiInternalBuildRendererStage386EditedTextStateRenderExecutorDryRun(
    sharedTextInputFocusEditingDemoProbe:
        CjguiInternalRendererStage385SharedTextInputFocusEditingDemoProbeReadiness,
    editedTextDemoSurfaceRefresh: CjguiInternalRendererStage386EditedTextDemoSurfaceRefresh,
    editedTextRenderCommandRefreshPlan:
        CjguiInternalRendererStage386EditedTextRenderCommandRefreshPlan
): CjguiInternalRendererStage386EditedTextStateRenderExecutorDryRun {
    let refreshReady =
        editedTextRenderCommandRefreshPlan.didMaterializeEditedTextRenderCommandRefreshPlan &&
        editedTextRenderCommandRefreshPlan.didBindEditedTextRefreshToStage383RenderBridge &&
        editedTextRenderCommandRefreshPlan.didBindEditedTextRefreshToStage384InputAdapter &&
        editedTextRenderCommandRefreshPlan.didBindEditedTextRefreshToStage385EditingDryRun &&
        editedTextRenderCommandRefreshPlan.didKeepRenderCommandRefreshPreviewOnly &&
        editedTextRenderCommandRefreshPlan.didKeepRendererSubmissionBlocked

    return CjguiInternalRendererStage386EditedTextStateRenderExecutorDryRun(
        refreshReady,
        refreshReady && editedTextDemoSurfaceRefresh.didKeepDemoSurfaceRefreshOwnerLocal,
        refreshReady,
        refreshReady && sharedTextInputFocusEditingDemoProbe.didConfirmStateUpdateCommitted == false,
        refreshReady && editedTextDemoSurfaceRefresh.didKeepEditedTextRefreshPreviewOnly,
        refreshReady && sharedTextInputFocusEditingDemoProbe.didConfirmActionDispatch == false,
        refreshReady && sharedTextInputFocusEditingDemoProbe.didConfirmInputEventPipelineEnabled == false,
        refreshReady && sharedTextInputFocusEditingDemoProbe.didConfirmRendererStateWriteBlocked
    )
}

func cjguiInternalBuildRendererStage386EditedTextRenderRefreshDemoProbeFacts(
    sharedTextInputFocusEditingDemoProbe:
        CjguiInternalRendererStage385SharedTextInputFocusEditingDemoProbeReadiness,
    editedTextDemoSurfaceRefresh: CjguiInternalRendererStage386EditedTextDemoSurfaceRefresh,
    editedTextRenderCommandRefreshPlan: CjguiInternalRendererStage386EditedTextRenderCommandRefreshPlan,
    editedTextStateRenderExecutorDryRun:
        CjguiInternalRendererStage386EditedTextStateRenderExecutorDryRun
): CjguiInternalRendererStage386EditedTextRenderRefreshDemoProbeFacts {
    return CjguiInternalRendererStage386EditedTextRenderRefreshDemoProbeFacts(
        editedTextDemoSurfaceRefresh.didConsumeStage385SharedTextInputFocusEditingDemoProbe,
        sharedTextInputFocusEditingDemoProbe.didConfirmRouteConvergenceNotNeeded,
        sharedTextInputFocusEditingDemoProbe
            .sharedTextInputFocusEditingDemoProbeFacts
            .didConfirmStage381ConvergenceExitAlreadyMaterialized,
        sharedTextInputFocusEditingDemoProbe
            .didConfirmStage384SharedInputEventToActionIntentAdapterDemoProbeConsumed,
        editedTextDemoSurfaceRefresh.didConsumeEditedTextBufferDelta,
        editedTextDemoSurfaceRefresh.didMaterializeTodoEditedTextSurfaceRefreshPreview,
        editedTextDemoSurfaceRefresh.didMaterializeSettingsFocusSurfaceRefreshPreview,
        editedTextDemoSurfaceRefresh.didMaterializeCaretRenderCommandRefreshPreview,
        editedTextRenderCommandRefreshPlan.didMaterializeEditedTextRenderCommandRefreshPlan,
        editedTextRenderCommandRefreshPlan.didBindEditedTextRefreshToStage383RenderBridge,
        editedTextRenderCommandRefreshPlan.didBindEditedTextRefreshToStage384InputAdapter,
        editedTextRenderCommandRefreshPlan.didBindEditedTextRefreshToStage385EditingDryRun,
        editedTextStateRenderExecutorDryRun.didMaterializeOwnerLocalEditedTextStateRenderDryRun,
        editedTextStateRenderExecutorDryRun.didKeepEditedTextRefreshPreviewOnly,
        editedTextStateRenderExecutorDryRun.didKeepEditedTextStateUpdateUncommitted &&
            editedTextStateRenderExecutorDryRun.didKeepEditedTextRefreshPreviewOnly,
        sharedTextInputFocusEditingDemoProbe.didConfirmOwnerAcceptanceRequired,
        sharedTextInputFocusEditingDemoProbe.didConfirmOwnerAcceptanceGranted == false,
        sharedTextInputFocusEditingDemoProbe.didConfirmBackendReadyTruth == false,
        sharedTextInputFocusEditingDemoProbe.didConfirmPublicComponentApiAdded == false,
        sharedTextInputFocusEditingDemoProbe.didConfirmLayoutEngineEnabled == false,
        sharedTextInputFocusEditingDemoProbe.didConfirmInputEventPipelineEnabled == false,
        sharedTextInputFocusEditingDemoProbe.didConfirmActionDispatch == false,
        sharedTextInputFocusEditingDemoProbe.didConfirmStateUpdateCommitted == false,
        sharedTextInputFocusEditingDemoProbe.didConfirmRendererSubmissionBlocked,
        sharedTextInputFocusEditingDemoProbe.didConfirmRendererStateWriteBlocked,
        sharedTextInputFocusEditingDemoProbe.didConfirmRuntimeStateWriteBlocked,
        sharedTextInputFocusEditingDemoProbe.didConfirmVisibilityPublished == false
    )
}

func cjguiInternalBuildRendererStage386EditedTextRenderRefreshDemoProbeReadiness(
    sharedTextInputFocusEditingDemoProbe:
        CjguiInternalRendererStage385SharedTextInputFocusEditingDemoProbeReadiness,
    editedTextDemoSurfaceRefresh: CjguiInternalRendererStage386EditedTextDemoSurfaceRefresh,
    editedTextRenderCommandRefreshPlan: CjguiInternalRendererStage386EditedTextRenderCommandRefreshPlan,
    editedTextStateRenderExecutorDryRun:
        CjguiInternalRendererStage386EditedTextStateRenderExecutorDryRun,
    editedTextRenderRefreshDemoProbeFacts:
        CjguiInternalRendererStage386EditedTextRenderRefreshDemoProbeFacts
): CjguiInternalRendererStage386EditedTextRenderRefreshDemoProbeReadiness {
    let refreshReady =
        editedTextRenderRefreshDemoProbeFacts.didConsumeStage385SharedTextInputFocusEditingDemoProbe &&
        editedTextRenderRefreshDemoProbeFacts.didConfirmRouteConvergenceNotNeeded &&
        editedTextRenderRefreshDemoProbeFacts.didConfirmStage381ConvergenceExitAlreadyMaterialized &&
        editedTextRenderRefreshDemoProbeFacts
            .didConfirmStage384SharedInputEventAdapterConsumedTransitively &&
        editedTextRenderRefreshDemoProbeFacts.didConsumeEditedTextBufferDelta &&
        editedTextRenderRefreshDemoProbeFacts.didMaterializeTodoEditedTextSurfaceRefreshPreview &&
        editedTextRenderRefreshDemoProbeFacts.didMaterializeSettingsFocusSurfaceRefreshPreview &&
        editedTextRenderRefreshDemoProbeFacts.didMaterializeCaretRenderCommandRefreshPreview &&
        editedTextRenderRefreshDemoProbeFacts.didMaterializeEditedTextRenderCommandRefreshPlan &&
        editedTextRenderRefreshDemoProbeFacts.didBindEditedTextRefreshToStage383RenderBridge &&
        editedTextRenderRefreshDemoProbeFacts.didBindEditedTextRefreshToStage384InputAdapter &&
        editedTextRenderRefreshDemoProbeFacts.didBindEditedTextRefreshToStage385EditingDryRun &&
        editedTextRenderRefreshDemoProbeFacts
            .didMaterializeOwnerLocalEditedTextStateRenderDryRun &&
        editedTextRenderRefreshDemoProbeFacts.didKeepEditedTextRefreshPreviewOnly &&
        editedTextRenderRefreshDemoProbeFacts.didPrepareStage387SharedTextEditActionCommitDryRun
    let stopLineReady =
        editedTextRenderRefreshDemoProbeFacts.didKeepOwnerAcceptanceRequired &&
        editedTextRenderRefreshDemoProbeFacts.didKeepOwnerAcceptanceNotGranted &&
        editedTextRenderRefreshDemoProbeFacts.didKeepBackendReadyTruthBlocked &&
        editedTextRenderRefreshDemoProbeFacts.didKeepPublicComponentApiBlocked &&
        editedTextRenderRefreshDemoProbeFacts.didKeepLayoutEngineBlocked &&
        editedTextRenderRefreshDemoProbeFacts.didKeepInputEventPipelineBlocked &&
        editedTextRenderRefreshDemoProbeFacts.didKeepActionDispatchBlocked &&
        editedTextRenderRefreshDemoProbeFacts.didKeepStateUpdateCommittedBlocked &&
        editedTextRenderRefreshDemoProbeFacts.didKeepRendererSubmissionBlocked &&
        editedTextRenderRefreshDemoProbeFacts.didKeepRendererStateWriteBlocked &&
        editedTextRenderRefreshDemoProbeFacts.didKeepRuntimeStateWriteBlocked &&
        editedTextRenderRefreshDemoProbeFacts.didKeepVisibilityNotPublished

    return CjguiInternalRendererStage386EditedTextRenderRefreshDemoProbeReadiness(
        sharedTextInputFocusEditingDemoProbe,
        editedTextDemoSurfaceRefresh,
        editedTextRenderCommandRefreshPlan,
        editedTextStateRenderExecutorDryRun,
        editedTextRenderRefreshDemoProbeFacts,
        refreshReady && stopLineReady,
        refreshReady && stopLineReady,
        editedTextRenderRefreshDemoProbeFacts.didConfirmRouteConvergenceNotNeeded,
        editedTextRenderRefreshDemoProbeFacts.didConsumeStage385SharedTextInputFocusEditingDemoProbe,
        editedTextRenderRefreshDemoProbeFacts
            .didConfirmStage384SharedInputEventAdapterConsumedTransitively,
        editedTextRenderRefreshDemoProbeFacts.didConsumeEditedTextBufferDelta,
        editedTextRenderRefreshDemoProbeFacts.didMaterializeTodoEditedTextSurfaceRefreshPreview,
        editedTextRenderRefreshDemoProbeFacts.didMaterializeSettingsFocusSurfaceRefreshPreview,
        editedTextRenderRefreshDemoProbeFacts.didMaterializeCaretRenderCommandRefreshPreview,
        editedTextRenderRefreshDemoProbeFacts.didMaterializeEditedTextRenderCommandRefreshPlan,
        editedTextRenderRefreshDemoProbeFacts.didBindEditedTextRefreshToStage383RenderBridge,
        editedTextRenderRefreshDemoProbeFacts.didBindEditedTextRefreshToStage384InputAdapter,
        editedTextRenderRefreshDemoProbeFacts.didBindEditedTextRefreshToStage385EditingDryRun,
        editedTextRenderRefreshDemoProbeFacts.didMaterializeOwnerLocalEditedTextStateRenderDryRun,
        editedTextRenderRefreshDemoProbeFacts.didKeepEditedTextRefreshPreviewOnly,
        editedTextRenderRefreshDemoProbeFacts.didPrepareStage387SharedTextEditActionCommitDryRun,
        editedTextRenderRefreshDemoProbeFacts.didKeepOwnerAcceptanceRequired,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        editedTextRenderRefreshDemoProbeFacts.didKeepRendererSubmissionBlocked,
        editedTextRenderRefreshDemoProbeFacts.didKeepRendererStateWriteBlocked,
        editedTextRenderRefreshDemoProbeFacts.didKeepRuntimeStateWriteBlocked,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage386EditedTextRenderRefreshDemoProbeDraft():
    CjguiInternalRendererStage386EditedTextRenderRefreshDemoProbeReadiness {
    let sharedTextInputFocusEditingDemoProbe =
        cjguiInternalExecuteDefaultRendererStage385SharedTextInputFocusEditingDemoProbeDraft()
    let editedTextDemoSurfaceRefresh =
        cjguiInternalBuildRendererStage386EditedTextDemoSurfaceRefresh(
            sharedTextInputFocusEditingDemoProbe)
    let editedTextRenderCommandRefreshPlan =
        cjguiInternalBuildRendererStage386EditedTextRenderCommandRefreshPlan(
            sharedTextInputFocusEditingDemoProbe,
            editedTextDemoSurfaceRefresh
        )
    let editedTextStateRenderExecutorDryRun =
        cjguiInternalBuildRendererStage386EditedTextStateRenderExecutorDryRun(
            sharedTextInputFocusEditingDemoProbe,
            editedTextDemoSurfaceRefresh,
            editedTextRenderCommandRefreshPlan
        )
    let facts = cjguiInternalBuildRendererStage386EditedTextRenderRefreshDemoProbeFacts(
        sharedTextInputFocusEditingDemoProbe,
        editedTextDemoSurfaceRefresh,
        editedTextRenderCommandRefreshPlan,
        editedTextStateRenderExecutorDryRun
    )
    return cjguiInternalBuildRendererStage386EditedTextRenderRefreshDemoProbeReadiness(
        sharedTextInputFocusEditingDemoProbe,
        editedTextDemoSurfaceRefresh,
        editedTextRenderCommandRefreshPlan,
        editedTextStateRenderExecutorDryRun,
        facts
    )
}
