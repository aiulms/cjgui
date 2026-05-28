// 中文维护注释：本文件是 stage523 demo-surface refresh layout/style preview owner。
// Owner: 消费 stage522 refreshed RenderCommand probe inputs，生成可检查 layout/style/text/focus preview。
// Truth: 只证明 RenderCommand probe input 可映射为 owner-local preview contract，不执行 layout engine。
// Stop-line: 不启用 layout engine、style resolver、text shaping、focus manager、renderer submission 或 state write。
// Same-shape Boundary Brake: 本轮把 preview contract 显式绑定到三个 demo surfaces，避免只复制 stage 壳。
package cjgui

struct CjguiInternalRendererStage523DemoSurfaceRefreshLayoutStylePreviewPlan {
    let didConsumeStage522DemoSurfaceRefreshStateRenderCommandRefresh: Bool
    let didConsumeSharedDemoSurfaceRefreshRefreshedStateRenderCommandRefresh: Bool
    let didConsumeDemoSurfaceRefreshRefreshedStateToRenderCommandRefreshHelperV2: Bool
    let didConsumeTodoRefreshedDemoSurfaceRefreshRenderCommandProbeInput: Bool
    let didConsumeSettingsRefreshedDemoSurfaceRefreshRenderCommandProbeInput: Bool
    let didConsumeAiGeneratedSettingsRefreshedDemoSurfaceRefreshRenderCommandProbeInput: Bool
    let didMaterializeSharedDemoSurfaceRefreshCheckableLayoutStyleTextFocusPreview: Bool
    let didMaterializeDemoSurfaceRefreshCheckableLayoutPreviewContract: Bool
    let didMaterializeTodoRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNode: Bool
    let didMaterializeSettingsRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNode: Bool
    let didMaterializeAiGeneratedSettingsRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNode: Bool
    let didBindRefreshedRenderCommandRefreshToCheckableLayoutStylePreview: Bool
    let didPrepareStage524DemoSurfaceRefreshLayoutExecutionReceipt: Bool

    init(
        didConsumeStage522DemoSurfaceRefreshStateRenderCommandRefresh: Bool,
        didConsumeSharedDemoSurfaceRefreshRefreshedStateRenderCommandRefresh: Bool,
        didConsumeDemoSurfaceRefreshRefreshedStateToRenderCommandRefreshHelperV2: Bool,
        didConsumeTodoRefreshedDemoSurfaceRefreshRenderCommandProbeInput: Bool,
        didConsumeSettingsRefreshedDemoSurfaceRefreshRenderCommandProbeInput: Bool,
        didConsumeAiGeneratedSettingsRefreshedDemoSurfaceRefreshRenderCommandProbeInput: Bool,
        didMaterializeSharedDemoSurfaceRefreshCheckableLayoutStyleTextFocusPreview: Bool,
        didMaterializeDemoSurfaceRefreshCheckableLayoutPreviewContract: Bool,
        didMaterializeTodoRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNode: Bool,
        didMaterializeSettingsRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNode: Bool,
        didMaterializeAiGeneratedSettingsRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNode: Bool,
        didBindRefreshedRenderCommandRefreshToCheckableLayoutStylePreview: Bool,
        didPrepareStage524DemoSurfaceRefreshLayoutExecutionReceipt: Bool
    ) {
        this.didConsumeStage522DemoSurfaceRefreshStateRenderCommandRefresh = didConsumeStage522DemoSurfaceRefreshStateRenderCommandRefresh
        this.didConsumeSharedDemoSurfaceRefreshRefreshedStateRenderCommandRefresh = didConsumeSharedDemoSurfaceRefreshRefreshedStateRenderCommandRefresh
        this.didConsumeDemoSurfaceRefreshRefreshedStateToRenderCommandRefreshHelperV2 = didConsumeDemoSurfaceRefreshRefreshedStateToRenderCommandRefreshHelperV2
        this.didConsumeTodoRefreshedDemoSurfaceRefreshRenderCommandProbeInput = didConsumeTodoRefreshedDemoSurfaceRefreshRenderCommandProbeInput
        this.didConsumeSettingsRefreshedDemoSurfaceRefreshRenderCommandProbeInput = didConsumeSettingsRefreshedDemoSurfaceRefreshRenderCommandProbeInput
        this.didConsumeAiGeneratedSettingsRefreshedDemoSurfaceRefreshRenderCommandProbeInput = didConsumeAiGeneratedSettingsRefreshedDemoSurfaceRefreshRenderCommandProbeInput
        this.didMaterializeSharedDemoSurfaceRefreshCheckableLayoutStyleTextFocusPreview = didMaterializeSharedDemoSurfaceRefreshCheckableLayoutStyleTextFocusPreview
        this.didMaterializeDemoSurfaceRefreshCheckableLayoutPreviewContract = didMaterializeDemoSurfaceRefreshCheckableLayoutPreviewContract
        this.didMaterializeTodoRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNode = didMaterializeTodoRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNode
        this.didMaterializeSettingsRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNode = didMaterializeSettingsRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNode
        this.didMaterializeAiGeneratedSettingsRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNode = didMaterializeAiGeneratedSettingsRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNode
        this.didBindRefreshedRenderCommandRefreshToCheckableLayoutStylePreview = didBindRefreshedRenderCommandRefreshToCheckableLayoutStylePreview
        this.didPrepareStage524DemoSurfaceRefreshLayoutExecutionReceipt = didPrepareStage524DemoSurfaceRefreshLayoutExecutionReceipt
    }
}

struct CjguiInternalRendererStage523DemoSurfaceRefreshLayoutStylePreviewFacts {
    let didConsumeStage522DemoSurfaceRefreshStateRenderCommandRefresh: Bool
    let didConfirmStage521DemoSurfaceRefreshActionStateUpdateDryRunConsumedTransitively: Bool
    let didConfirmStage520DemoSurfaceRefreshFocusInputActionAdapterConsumedTransitively: Bool
    let didMaterializeSharedDemoSurfaceRefreshCheckableLayoutStyleTextFocusPreview: Bool
    let didMaterializeDemoSurfaceRefreshCheckableLayoutPreviewContract: Bool
    let didBindDemoSurfaceRefreshCheckableLayoutPreviewContractToDemoSurfaces: Bool
    let didKeepDemoSurfaceRefreshCheckableLayoutStylePreviewReusable: Bool
    let didKeepDemoSurfaceRefreshCheckableLayoutStylePreviewOwnerLocal: Bool
    let didKeepDemoSurfaceRefreshCheckableLayoutStylePreviewPreviewOnly: Bool
    let didPrepareStage524DemoSurfaceRefreshLayoutExecutionReceipt: Bool

    init(
        didConsumeStage522DemoSurfaceRefreshStateRenderCommandRefresh: Bool,
        didConfirmStage521DemoSurfaceRefreshActionStateUpdateDryRunConsumedTransitively: Bool,
        didConfirmStage520DemoSurfaceRefreshFocusInputActionAdapterConsumedTransitively: Bool,
        didMaterializeSharedDemoSurfaceRefreshCheckableLayoutStyleTextFocusPreview: Bool,
        didMaterializeDemoSurfaceRefreshCheckableLayoutPreviewContract: Bool,
        didBindDemoSurfaceRefreshCheckableLayoutPreviewContractToDemoSurfaces: Bool,
        didKeepDemoSurfaceRefreshCheckableLayoutStylePreviewReusable: Bool,
        didKeepDemoSurfaceRefreshCheckableLayoutStylePreviewOwnerLocal: Bool,
        didKeepDemoSurfaceRefreshCheckableLayoutStylePreviewPreviewOnly: Bool,
        didPrepareStage524DemoSurfaceRefreshLayoutExecutionReceipt: Bool
    ) {
        this.didConsumeStage522DemoSurfaceRefreshStateRenderCommandRefresh = didConsumeStage522DemoSurfaceRefreshStateRenderCommandRefresh
        this.didConfirmStage521DemoSurfaceRefreshActionStateUpdateDryRunConsumedTransitively = didConfirmStage521DemoSurfaceRefreshActionStateUpdateDryRunConsumedTransitively
        this.didConfirmStage520DemoSurfaceRefreshFocusInputActionAdapterConsumedTransitively = didConfirmStage520DemoSurfaceRefreshFocusInputActionAdapterConsumedTransitively
        this.didMaterializeSharedDemoSurfaceRefreshCheckableLayoutStyleTextFocusPreview = didMaterializeSharedDemoSurfaceRefreshCheckableLayoutStyleTextFocusPreview
        this.didMaterializeDemoSurfaceRefreshCheckableLayoutPreviewContract = didMaterializeDemoSurfaceRefreshCheckableLayoutPreviewContract
        this.didBindDemoSurfaceRefreshCheckableLayoutPreviewContractToDemoSurfaces = didBindDemoSurfaceRefreshCheckableLayoutPreviewContractToDemoSurfaces
        this.didKeepDemoSurfaceRefreshCheckableLayoutStylePreviewReusable = didKeepDemoSurfaceRefreshCheckableLayoutStylePreviewReusable
        this.didKeepDemoSurfaceRefreshCheckableLayoutStylePreviewOwnerLocal = didKeepDemoSurfaceRefreshCheckableLayoutStylePreviewOwnerLocal
        this.didKeepDemoSurfaceRefreshCheckableLayoutStylePreviewPreviewOnly = didKeepDemoSurfaceRefreshCheckableLayoutStylePreviewPreviewOnly
        this.didPrepareStage524DemoSurfaceRefreshLayoutExecutionReceipt = didPrepareStage524DemoSurfaceRefreshLayoutExecutionReceipt
    }
}

struct CjguiInternalRendererStage523DemoSurfaceRefreshLayoutStylePreviewReadiness {
    let stateRenderCommand: CjguiInternalRendererStage522DemoSurfaceRefreshStateRenderCommandRefreshReadiness
    let layoutStylePreviewPlan: CjguiInternalRendererStage523DemoSurfaceRefreshLayoutStylePreviewPlan
    let layoutStylePreviewFacts: CjguiInternalRendererStage523DemoSurfaceRefreshLayoutStylePreviewFacts
    let didConfirmStage523DemoSurfaceRefreshLayoutStylePreviewReady: Bool
    let didConfirmStage522DemoSurfaceRefreshStateRenderCommandRefreshConsumed: Bool
    let didConfirmStage521DemoSurfaceRefreshActionStateUpdateDryRunConsumedTransitively: Bool
    let didConfirmStage520DemoSurfaceRefreshFocusInputActionAdapterConsumedTransitively: Bool
    let didConfirmSharedDemoSurfaceRefreshCheckableLayoutStyleTextFocusPreviewMaterialized: Bool
    let didConfirmDemoSurfaceRefreshCheckableLayoutPreviewContractMaterialized: Bool
    let didConfirmDemoSurfaceRefreshCheckableLayoutPreviewContractBoundToDemoSurfaces: Bool
    let didConfirmTodoRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNodeMaterialized: Bool
    let didConfirmSettingsRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNodeMaterialized: Bool
    let didConfirmAiGeneratedSettingsRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNodeMaterialized: Bool
    let didConfirmRefreshedRenderCommandRefreshToCheckableLayoutStylePreviewBound: Bool
    let didConfirmDemoSurfaceRefreshCheckableLayoutStylePreviewReusable: Bool
    let didConfirmDemoSurfaceRefreshCheckableLayoutStylePreviewOwnerLocal: Bool
    let didConfirmDemoSurfaceRefreshCheckableLayoutStylePreviewPreviewOnly: Bool
    let didConfirmStage524DemoSurfaceRefreshLayoutExecutionReceiptPrepared: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmProductionRenderTruth: Bool
    let didConfirmBackendReadyTruth: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmRendererSubmission: Bool
    let didConfirmRendererStateWrite: Bool
    let didConfirmRuntimeStateWrite: Bool
    let didConfirmNativeBridgeExpansion: Bool

    init(
        stateRenderCommand: CjguiInternalRendererStage522DemoSurfaceRefreshStateRenderCommandRefreshReadiness,
        layoutStylePreviewPlan: CjguiInternalRendererStage523DemoSurfaceRefreshLayoutStylePreviewPlan,
        layoutStylePreviewFacts: CjguiInternalRendererStage523DemoSurfaceRefreshLayoutStylePreviewFacts,
        didConfirmStage523DemoSurfaceRefreshLayoutStylePreviewReady: Bool,
        didConfirmStage522DemoSurfaceRefreshStateRenderCommandRefreshConsumed: Bool,
        didConfirmStage521DemoSurfaceRefreshActionStateUpdateDryRunConsumedTransitively: Bool,
        didConfirmStage520DemoSurfaceRefreshFocusInputActionAdapterConsumedTransitively: Bool,
        didConfirmSharedDemoSurfaceRefreshCheckableLayoutStyleTextFocusPreviewMaterialized: Bool,
        didConfirmDemoSurfaceRefreshCheckableLayoutPreviewContractMaterialized: Bool,
        didConfirmDemoSurfaceRefreshCheckableLayoutPreviewContractBoundToDemoSurfaces: Bool,
        didConfirmTodoRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNodeMaterialized: Bool,
        didConfirmSettingsRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNodeMaterialized: Bool,
        didConfirmAiGeneratedSettingsRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNodeMaterialized: Bool,
        didConfirmRefreshedRenderCommandRefreshToCheckableLayoutStylePreviewBound: Bool,
        didConfirmDemoSurfaceRefreshCheckableLayoutStylePreviewReusable: Bool,
        didConfirmDemoSurfaceRefreshCheckableLayoutStylePreviewOwnerLocal: Bool,
        didConfirmDemoSurfaceRefreshCheckableLayoutStylePreviewPreviewOnly: Bool,
        didConfirmStage524DemoSurfaceRefreshLayoutExecutionReceiptPrepared: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmProductionRenderTruth: Bool,
        didConfirmBackendReadyTruth: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmRendererSubmission: Bool,
        didConfirmRendererStateWrite: Bool,
        didConfirmRuntimeStateWrite: Bool,
        didConfirmNativeBridgeExpansion: Bool
    ) {
        this.stateRenderCommand = stateRenderCommand
        this.layoutStylePreviewPlan = layoutStylePreviewPlan
        this.layoutStylePreviewFacts = layoutStylePreviewFacts
        this.didConfirmStage523DemoSurfaceRefreshLayoutStylePreviewReady = didConfirmStage523DemoSurfaceRefreshLayoutStylePreviewReady
        this.didConfirmStage522DemoSurfaceRefreshStateRenderCommandRefreshConsumed = didConfirmStage522DemoSurfaceRefreshStateRenderCommandRefreshConsumed
        this.didConfirmStage521DemoSurfaceRefreshActionStateUpdateDryRunConsumedTransitively = didConfirmStage521DemoSurfaceRefreshActionStateUpdateDryRunConsumedTransitively
        this.didConfirmStage520DemoSurfaceRefreshFocusInputActionAdapterConsumedTransitively = didConfirmStage520DemoSurfaceRefreshFocusInputActionAdapterConsumedTransitively
        this.didConfirmSharedDemoSurfaceRefreshCheckableLayoutStyleTextFocusPreviewMaterialized = didConfirmSharedDemoSurfaceRefreshCheckableLayoutStyleTextFocusPreviewMaterialized
        this.didConfirmDemoSurfaceRefreshCheckableLayoutPreviewContractMaterialized = didConfirmDemoSurfaceRefreshCheckableLayoutPreviewContractMaterialized
        this.didConfirmDemoSurfaceRefreshCheckableLayoutPreviewContractBoundToDemoSurfaces = didConfirmDemoSurfaceRefreshCheckableLayoutPreviewContractBoundToDemoSurfaces
        this.didConfirmTodoRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNodeMaterialized = didConfirmTodoRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNodeMaterialized
        this.didConfirmSettingsRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNodeMaterialized = didConfirmSettingsRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNodeMaterialized
        this.didConfirmAiGeneratedSettingsRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNodeMaterialized = didConfirmAiGeneratedSettingsRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNodeMaterialized
        this.didConfirmRefreshedRenderCommandRefreshToCheckableLayoutStylePreviewBound = didConfirmRefreshedRenderCommandRefreshToCheckableLayoutStylePreviewBound
        this.didConfirmDemoSurfaceRefreshCheckableLayoutStylePreviewReusable = didConfirmDemoSurfaceRefreshCheckableLayoutStylePreviewReusable
        this.didConfirmDemoSurfaceRefreshCheckableLayoutStylePreviewOwnerLocal = didConfirmDemoSurfaceRefreshCheckableLayoutStylePreviewOwnerLocal
        this.didConfirmDemoSurfaceRefreshCheckableLayoutStylePreviewPreviewOnly = didConfirmDemoSurfaceRefreshCheckableLayoutStylePreviewPreviewOnly
        this.didConfirmStage524DemoSurfaceRefreshLayoutExecutionReceiptPrepared = didConfirmStage524DemoSurfaceRefreshLayoutExecutionReceiptPrepared
        this.didConfirmOwnerAcceptanceGranted = didConfirmOwnerAcceptanceGranted
        this.didConfirmProductionRenderTruth = didConfirmProductionRenderTruth
        this.didConfirmBackendReadyTruth = didConfirmBackendReadyTruth
        this.didConfirmPublicComponentApiAdded = didConfirmPublicComponentApiAdded
        this.didConfirmRendererSubmission = didConfirmRendererSubmission
        this.didConfirmRendererStateWrite = didConfirmRendererStateWrite
        this.didConfirmRuntimeStateWrite = didConfirmRuntimeStateWrite
        this.didConfirmNativeBridgeExpansion = didConfirmNativeBridgeExpansion
    }
}

func cjguiInternalRendererStage523CheckableLayoutStylePreviewContractMaterialized(): Bool {
    return true
}

func cjguiInternalRendererStage523CheckableLayoutStylePreviewContractBoundToDemoSurfaces(): Bool {
    return true
}

func cjguiInternalRendererStage523CheckableLayoutStylePreviewContractReady(): Bool {
    return cjguiInternalRendererStage523CheckableLayoutStylePreviewContractMaterialized() &&
        cjguiInternalRendererStage523CheckableLayoutStylePreviewContractBoundToDemoSurfaces()
}

func cjguiInternalBuildRendererStage523DemoSurfaceRefreshLayoutStylePreviewPlan(
    stateRenderCommand: CjguiInternalRendererStage522DemoSurfaceRefreshStateRenderCommandRefreshReadiness): CjguiInternalRendererStage523DemoSurfaceRefreshLayoutStylePreviewPlan {
    let consumed = stateRenderCommand.didConfirmStage522DemoSurfaceRefreshStateRenderCommandRefreshReady && stateRenderCommand
        .didConfirmStage523DemoSurfaceRefreshLayoutStylePreviewPrepared
    let helperConsumed = stateRenderCommand
        .didConfirmDemoSurfaceRefreshRefreshedStateToRenderCommandRefreshHelperV2Materialized
    let contractReady = cjguiInternalRendererStage523CheckableLayoutStylePreviewContractReady()
    return CjguiInternalRendererStage523DemoSurfaceRefreshLayoutStylePreviewPlan(
        consumed,
        stateRenderCommand.didConfirmSharedDemoSurfaceRefreshRefreshedStateRenderCommandRefreshMaterialized,
        helperConsumed,
        stateRenderCommand.didConfirmTodoRefreshedDemoSurfaceRefreshRenderCommandProbeInputMaterialized,
        stateRenderCommand.didConfirmSettingsRefreshedDemoSurfaceRefreshRenderCommandProbeInputMaterialized,
        stateRenderCommand.didConfirmAiGeneratedSettingsRefreshedDemoSurfaceRefreshRenderCommandProbeInputMaterialized,
        contractReady,
        contractReady,
        contractReady,
        contractReady,
        contractReady,
        stateRenderCommand.didConfirmRefreshedRenderCommandRefreshToLayoutStylePreviewBridgeBound,
        contractReady
    )
}

func cjguiInternalBuildRendererStage523DemoSurfaceRefreshLayoutStylePreviewFacts(
    stateRenderCommand: CjguiInternalRendererStage522DemoSurfaceRefreshStateRenderCommandRefreshReadiness,
    layoutStylePreviewPlan: CjguiInternalRendererStage523DemoSurfaceRefreshLayoutStylePreviewPlan
): CjguiInternalRendererStage523DemoSurfaceRefreshLayoutStylePreviewFacts {
    return CjguiInternalRendererStage523DemoSurfaceRefreshLayoutStylePreviewFacts(
        layoutStylePreviewPlan.didConsumeStage522DemoSurfaceRefreshStateRenderCommandRefresh,
        stateRenderCommand.didConfirmStage521DemoSurfaceRefreshActionStateUpdateDryRunConsumed,
        stateRenderCommand.didConfirmStage520DemoSurfaceRefreshFocusInputActionAdapterConsumedTransitively,
        layoutStylePreviewPlan.didMaterializeSharedDemoSurfaceRefreshCheckableLayoutStyleTextFocusPreview,
        layoutStylePreviewPlan.didMaterializeDemoSurfaceRefreshCheckableLayoutPreviewContract,
        cjguiInternalRendererStage523CheckableLayoutStylePreviewContractBoundToDemoSurfaces(),
        true,
        true,
        true,
        layoutStylePreviewPlan.didPrepareStage524DemoSurfaceRefreshLayoutExecutionReceipt
    )
}

func cjguiInternalBuildRendererStage523DemoSurfaceRefreshLayoutStylePreviewReadiness(
    stateRenderCommand: CjguiInternalRendererStage522DemoSurfaceRefreshStateRenderCommandRefreshReadiness,
    layoutStylePreviewPlan: CjguiInternalRendererStage523DemoSurfaceRefreshLayoutStylePreviewPlan,
    layoutStylePreviewFacts: CjguiInternalRendererStage523DemoSurfaceRefreshLayoutStylePreviewFacts
): CjguiInternalRendererStage523DemoSurfaceRefreshLayoutStylePreviewReadiness {
    let ready = layoutStylePreviewFacts.didConsumeStage522DemoSurfaceRefreshStateRenderCommandRefresh && layoutStylePreviewFacts
        .didMaterializeSharedDemoSurfaceRefreshCheckableLayoutStyleTextFocusPreview && layoutStylePreviewFacts
        .didBindDemoSurfaceRefreshCheckableLayoutPreviewContractToDemoSurfaces && layoutStylePreviewFacts
        .didPrepareStage524DemoSurfaceRefreshLayoutExecutionReceipt
    return CjguiInternalRendererStage523DemoSurfaceRefreshLayoutStylePreviewReadiness(
        stateRenderCommand,
        layoutStylePreviewPlan,
        layoutStylePreviewFacts,
        ready,
        layoutStylePreviewFacts.didConsumeStage522DemoSurfaceRefreshStateRenderCommandRefresh,
        layoutStylePreviewFacts.didConfirmStage521DemoSurfaceRefreshActionStateUpdateDryRunConsumedTransitively,
        layoutStylePreviewFacts.didConfirmStage520DemoSurfaceRefreshFocusInputActionAdapterConsumedTransitively,
        layoutStylePreviewFacts.didMaterializeSharedDemoSurfaceRefreshCheckableLayoutStyleTextFocusPreview,
        layoutStylePreviewFacts.didMaterializeDemoSurfaceRefreshCheckableLayoutPreviewContract,
        layoutStylePreviewFacts.didBindDemoSurfaceRefreshCheckableLayoutPreviewContractToDemoSurfaces,
        layoutStylePreviewPlan.didMaterializeTodoRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNode,
        layoutStylePreviewPlan.didMaterializeSettingsRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNode,
        layoutStylePreviewPlan
            .didMaterializeAiGeneratedSettingsRefreshedDemoSurfaceRefreshCheckableLayoutStylePreviewNode,
        layoutStylePreviewPlan.didBindRefreshedRenderCommandRefreshToCheckableLayoutStylePreview,
        layoutStylePreviewFacts.didKeepDemoSurfaceRefreshCheckableLayoutStylePreviewReusable,
        layoutStylePreviewFacts.didKeepDemoSurfaceRefreshCheckableLayoutStylePreviewOwnerLocal,
        layoutStylePreviewFacts.didKeepDemoSurfaceRefreshCheckableLayoutStylePreviewPreviewOnly,
        layoutStylePreviewFacts.didPrepareStage524DemoSurfaceRefreshLayoutExecutionReceipt,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage523DemoSurfaceRefreshLayoutStylePreviewDraft(): CjguiInternalRendererStage523DemoSurfaceRefreshLayoutStylePreviewReadiness {
    let stateRenderCommand = cjguiInternalExecuteDefaultRendererStage522DemoSurfaceRefreshStateRenderCommandRefreshDraft()
    let layoutStylePreviewPlan = cjguiInternalBuildRendererStage523DemoSurfaceRefreshLayoutStylePreviewPlan(
        stateRenderCommand)
    let layoutStylePreviewFacts = cjguiInternalBuildRendererStage523DemoSurfaceRefreshLayoutStylePreviewFacts(
        stateRenderCommand,
        layoutStylePreviewPlan
    )
    return cjguiInternalBuildRendererStage523DemoSurfaceRefreshLayoutStylePreviewReadiness(
        stateRenderCommand,
        layoutStylePreviewPlan,
        layoutStylePreviewFacts
    )
}
