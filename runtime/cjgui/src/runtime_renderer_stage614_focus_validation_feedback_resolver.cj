// 中文维护注释：本文件是 stage614 focus/validation feedback resolver owner。
// Owner: 消费 stage613 manager，把 validation/focus/input feedback 解析为 style/text/display surface。
// Truth: 只证明共享 resolver 能生成 validation text run、focus ring token 与 input affordance。
// Stop-line: 不启用真实 style resolver、不执行 layout/text shaping、不提交 state。
// Same-shape Boundary Brake: 本轮把四个 demo 的 feedback display 解析路径压缩成 shared resolver。
package cjgui

struct CjguiInternalRendererStage614FocusValidationFeedbackResolverPlan {
    let didConsumeStage613FocusValidationManager: Bool
    let didConsumeFocusValidationLedgers: Bool
    let didMaterializeSharedFocusValidationFeedbackResolver: Bool
    let didMaterializeValidationMessageTextRun: Bool
    let didMaterializeFocusRingStyleToken: Bool
    let didMaterializeInputFeedbackAffordance: Bool
    let didMaterializeTodoFocusValidationFeedbackSurface: Bool
    let didMaterializeSettingsFocusValidationFeedbackSurface: Bool
    let didMaterializeAiGeneratedSettingsFocusValidationFeedbackSurface: Bool
    let didMaterializeChatComposerFocusValidationFeedbackSurface: Bool
    let didBindResolverToStage613Manager: Bool
    let didPrepareStage615FocusValidationDemoHostReceipt: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool

    init(
        didConsumeStage613FocusValidationManager: Bool,
        didConsumeFocusValidationLedgers: Bool,
        didMaterializeSharedFocusValidationFeedbackResolver: Bool,
        didMaterializeValidationMessageTextRun: Bool,
        didMaterializeFocusRingStyleToken: Bool,
        didMaterializeInputFeedbackAffordance: Bool,
        didMaterializeTodoFocusValidationFeedbackSurface: Bool,
        didMaterializeSettingsFocusValidationFeedbackSurface: Bool,
        didMaterializeAiGeneratedSettingsFocusValidationFeedbackSurface: Bool,
        didMaterializeChatComposerFocusValidationFeedbackSurface: Bool,
        didBindResolverToStage613Manager: Bool,
        didPrepareStage615FocusValidationDemoHostReceipt: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool
    ) {
        this.didConsumeStage613FocusValidationManager = didConsumeStage613FocusValidationManager
        this.didConsumeFocusValidationLedgers = didConsumeFocusValidationLedgers
        this.didMaterializeSharedFocusValidationFeedbackResolver = didMaterializeSharedFocusValidationFeedbackResolver
        this.didMaterializeValidationMessageTextRun = didMaterializeValidationMessageTextRun
        this.didMaterializeFocusRingStyleToken = didMaterializeFocusRingStyleToken
        this.didMaterializeInputFeedbackAffordance = didMaterializeInputFeedbackAffordance
        this.didMaterializeTodoFocusValidationFeedbackSurface = didMaterializeTodoFocusValidationFeedbackSurface
        this.didMaterializeSettingsFocusValidationFeedbackSurface = didMaterializeSettingsFocusValidationFeedbackSurface
        this.didMaterializeAiGeneratedSettingsFocusValidationFeedbackSurface = didMaterializeAiGeneratedSettingsFocusValidationFeedbackSurface
        this.didMaterializeChatComposerFocusValidationFeedbackSurface = didMaterializeChatComposerFocusValidationFeedbackSurface
        this.didBindResolverToStage613Manager = didBindResolverToStage613Manager
        this.didPrepareStage615FocusValidationDemoHostReceipt = didPrepareStage615FocusValidationDemoHostReceipt
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
    }
}

struct CjguiInternalRendererStage614FocusValidationFeedbackResolverFacts {
    let focusValidationFeedbackResolverPlan: CjguiInternalRendererStage614FocusValidationFeedbackResolverPlan
    let didKeepOwnerAcceptanceRequired: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didKeepProductionRenderTruthBlocked: Bool
    let didKeepBackendReadyTruthBlocked: Bool
    let didKeepStyleResolverBlocked: Bool
    let didKeepFocusManagerBlocked: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepNativeBridgeExpansionBlocked: Bool

    init(
        focusValidationFeedbackResolverPlan: CjguiInternalRendererStage614FocusValidationFeedbackResolverPlan,
        didKeepOwnerAcceptanceRequired: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didKeepProductionRenderTruthBlocked: Bool,
        didKeepBackendReadyTruthBlocked: Bool,
        didKeepStyleResolverBlocked: Bool,
        didKeepFocusManagerBlocked: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepNativeBridgeExpansionBlocked: Bool
    ) {
        this.focusValidationFeedbackResolverPlan = focusValidationFeedbackResolverPlan
        this.didKeepOwnerAcceptanceRequired = didKeepOwnerAcceptanceRequired
        this.didKeepOwnerAcceptanceNotGranted = didKeepOwnerAcceptanceNotGranted
        this.didKeepProductionRenderTruthBlocked = didKeepProductionRenderTruthBlocked
        this.didKeepBackendReadyTruthBlocked = didKeepBackendReadyTruthBlocked
        this.didKeepStyleResolverBlocked = didKeepStyleResolverBlocked
        this.didKeepFocusManagerBlocked = didKeepFocusManagerBlocked
        this.didKeepStateUpdateCommittedBlocked = didKeepStateUpdateCommittedBlocked
        this.didKeepNativeBridgeExpansionBlocked = didKeepNativeBridgeExpansionBlocked
    }
}

struct CjguiInternalRendererStage614FocusValidationFeedbackResolverReadiness {
    let focusValidationManager: CjguiInternalRendererStage613FocusValidationManagerReadiness
    let focusValidationFeedbackResolverPlan: CjguiInternalRendererStage614FocusValidationFeedbackResolverPlan
    let focusValidationFeedbackResolverFacts: CjguiInternalRendererStage614FocusValidationFeedbackResolverFacts
    let didConfirmStage614FocusValidationFeedbackResolverReady: Bool
    let didConfirmStage613FocusValidationManagerConsumed: Bool
    let didConfirmStage612SharedFeedbackHostInspectionCycleExecutorContractConsumedTransitively: Bool
    let didConfirmSharedFocusValidationFeedbackResolverMaterialized: Bool
    let didConfirmValidationMessageTextRunMaterialized: Bool
    let didConfirmFocusRingStyleTokenMaterialized: Bool
    let didConfirmInputFeedbackAffordanceMaterialized: Bool
    let didConfirmTodoFocusValidationFeedbackSurfaceMaterialized: Bool
    let didConfirmSettingsFocusValidationFeedbackSurfaceMaterialized: Bool
    let didConfirmAiGeneratedSettingsFocusValidationFeedbackSurfaceMaterialized: Bool
    let didConfirmChatComposerFocusValidationFeedbackSurfaceMaterialized: Bool
    let didConfirmResolverBoundToStage613Manager: Bool
    let didConfirmStage615FocusValidationDemoHostReceiptPrepared: Bool
    let didConfirmOwnerAcceptanceRequired: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmProductionRenderTruth: Bool
    let didConfirmBackendReadyTruth: Bool
    let didConfirmStyleResolverEnabled: Bool
    let didConfirmFocusManagerEnabled: Bool
    let didConfirmStateUpdateCommitted: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmNativeBridgeExpansionBlocked: Bool

    init(
        focusValidationManager: CjguiInternalRendererStage613FocusValidationManagerReadiness,
        focusValidationFeedbackResolverPlan: CjguiInternalRendererStage614FocusValidationFeedbackResolverPlan,
        focusValidationFeedbackResolverFacts: CjguiInternalRendererStage614FocusValidationFeedbackResolverFacts,
        didConfirmStage614FocusValidationFeedbackResolverReady: Bool,
        didConfirmStage613FocusValidationManagerConsumed: Bool,
        didConfirmStage612SharedFeedbackHostInspectionCycleExecutorContractConsumedTransitively: Bool,
        didConfirmSharedFocusValidationFeedbackResolverMaterialized: Bool,
        didConfirmValidationMessageTextRunMaterialized: Bool,
        didConfirmFocusRingStyleTokenMaterialized: Bool,
        didConfirmInputFeedbackAffordanceMaterialized: Bool,
        didConfirmTodoFocusValidationFeedbackSurfaceMaterialized: Bool,
        didConfirmSettingsFocusValidationFeedbackSurfaceMaterialized: Bool,
        didConfirmAiGeneratedSettingsFocusValidationFeedbackSurfaceMaterialized: Bool,
        didConfirmChatComposerFocusValidationFeedbackSurfaceMaterialized: Bool,
        didConfirmResolverBoundToStage613Manager: Bool,
        didConfirmStage615FocusValidationDemoHostReceiptPrepared: Bool,
        didConfirmOwnerAcceptanceRequired: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmProductionRenderTruth: Bool,
        didConfirmBackendReadyTruth: Bool,
        didConfirmStyleResolverEnabled: Bool,
        didConfirmFocusManagerEnabled: Bool,
        didConfirmStateUpdateCommitted: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmNativeBridgeExpansionBlocked: Bool
    ) {
        this.focusValidationManager = focusValidationManager
        this.focusValidationFeedbackResolverPlan = focusValidationFeedbackResolverPlan
        this.focusValidationFeedbackResolverFacts = focusValidationFeedbackResolverFacts
        this.didConfirmStage614FocusValidationFeedbackResolverReady = didConfirmStage614FocusValidationFeedbackResolverReady
        this.didConfirmStage613FocusValidationManagerConsumed = didConfirmStage613FocusValidationManagerConsumed
        this.didConfirmStage612SharedFeedbackHostInspectionCycleExecutorContractConsumedTransitively = didConfirmStage612SharedFeedbackHostInspectionCycleExecutorContractConsumedTransitively
        this.didConfirmSharedFocusValidationFeedbackResolverMaterialized = didConfirmSharedFocusValidationFeedbackResolverMaterialized
        this.didConfirmValidationMessageTextRunMaterialized = didConfirmValidationMessageTextRunMaterialized
        this.didConfirmFocusRingStyleTokenMaterialized = didConfirmFocusRingStyleTokenMaterialized
        this.didConfirmInputFeedbackAffordanceMaterialized = didConfirmInputFeedbackAffordanceMaterialized
        this.didConfirmTodoFocusValidationFeedbackSurfaceMaterialized = didConfirmTodoFocusValidationFeedbackSurfaceMaterialized
        this.didConfirmSettingsFocusValidationFeedbackSurfaceMaterialized = didConfirmSettingsFocusValidationFeedbackSurfaceMaterialized
        this.didConfirmAiGeneratedSettingsFocusValidationFeedbackSurfaceMaterialized = didConfirmAiGeneratedSettingsFocusValidationFeedbackSurfaceMaterialized
        this.didConfirmChatComposerFocusValidationFeedbackSurfaceMaterialized = didConfirmChatComposerFocusValidationFeedbackSurfaceMaterialized
        this.didConfirmResolverBoundToStage613Manager = didConfirmResolverBoundToStage613Manager
        this.didConfirmStage615FocusValidationDemoHostReceiptPrepared = didConfirmStage615FocusValidationDemoHostReceiptPrepared
        this.didConfirmOwnerAcceptanceRequired = didConfirmOwnerAcceptanceRequired
        this.didConfirmOwnerAcceptanceGranted = didConfirmOwnerAcceptanceGranted
        this.didConfirmProductionRenderTruth = didConfirmProductionRenderTruth
        this.didConfirmBackendReadyTruth = didConfirmBackendReadyTruth
        this.didConfirmStyleResolverEnabled = didConfirmStyleResolverEnabled
        this.didConfirmFocusManagerEnabled = didConfirmFocusManagerEnabled
        this.didConfirmStateUpdateCommitted = didConfirmStateUpdateCommitted
        this.didConfirmRendererSubmissionBlocked = didConfirmRendererSubmissionBlocked
        this.didConfirmRendererStateWriteBlocked = didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked = didConfirmRuntimeStateWriteBlocked
        this.didConfirmNativeBridgeExpansionBlocked = didConfirmNativeBridgeExpansionBlocked
    }
}

func cjguiInternalRendererStage614FocusValidationFeedbackResolverMaterialized(): Bool {
    return true
}

func cjguiInternalBuildRendererStage614FocusValidationFeedbackResolverPlan(
    focusValidationManager: CjguiInternalRendererStage613FocusValidationManagerReadiness): CjguiInternalRendererStage614FocusValidationFeedbackResolverPlan {
    let stage613Ready = focusValidationManager.didConfirmStage613FocusValidationManagerReady && focusValidationManager
        .didConfirmStage614FocusValidationFeedbackResolverPrepared
    let ledgersReady = focusValidationManager.didConfirmValidationStateLedgerMaterialized && focusValidationManager
        .didConfirmFocusCandidateLedgerMaterialized && focusValidationManager
        .didConfirmInputFeedbackIntentLedgerMaterialized && focusValidationManager
        .didConfirmChatComposerFocusValidationRouteMaterialized
    let resolverReady = stage613Ready && ledgersReady &&
        cjguiInternalRendererStage614FocusValidationFeedbackResolverMaterialized()
    return CjguiInternalRendererStage614FocusValidationFeedbackResolverPlan(
        stage613Ready,
        ledgersReady,
        resolverReady,
        resolverReady,
        resolverReady,
        resolverReady,
        resolverReady,
        resolverReady,
        resolverReady,
        resolverReady,
        resolverReady,
        resolverReady,
        focusValidationManager.didConfirmRendererSubmissionBlocked,
        focusValidationManager.didConfirmRendererStateWriteBlocked,
        focusValidationManager.didConfirmRuntimeStateWriteBlocked
    )
}

func cjguiInternalBuildRendererStage614FocusValidationFeedbackResolverFacts(
    focusValidationManager: CjguiInternalRendererStage613FocusValidationManagerReadiness,
    focusValidationFeedbackResolverPlan: CjguiInternalRendererStage614FocusValidationFeedbackResolverPlan
): CjguiInternalRendererStage614FocusValidationFeedbackResolverFacts {
    return CjguiInternalRendererStage614FocusValidationFeedbackResolverFacts(
        focusValidationFeedbackResolverPlan,
        focusValidationManager.didConfirmOwnerAcceptanceRequired,
        focusValidationManager.didConfirmOwnerAcceptanceGranted == false,
        focusValidationManager.didConfirmProductionRenderTruth == false,
        focusValidationManager.didConfirmBackendReadyTruth == false,
        false,
        focusValidationManager.didConfirmFocusManagerEnabled == false,
        focusValidationManager.didConfirmStateUpdateCommitted == false,
        focusValidationManager.didConfirmNativeBridgeExpansionBlocked
    )
}

func cjguiInternalBuildRendererStage614FocusValidationFeedbackResolverReadiness(
    focusValidationManager: CjguiInternalRendererStage613FocusValidationManagerReadiness,
    focusValidationFeedbackResolverPlan: CjguiInternalRendererStage614FocusValidationFeedbackResolverPlan,
    focusValidationFeedbackResolverFacts: CjguiInternalRendererStage614FocusValidationFeedbackResolverFacts
): CjguiInternalRendererStage614FocusValidationFeedbackResolverReadiness {
    let resolverReady = focusValidationFeedbackResolverPlan.didConsumeStage613FocusValidationManager && focusValidationFeedbackResolverPlan
        .didConsumeFocusValidationLedgers && focusValidationFeedbackResolverPlan
        .didMaterializeSharedFocusValidationFeedbackResolver && focusValidationFeedbackResolverPlan
        .didMaterializeValidationMessageTextRun && focusValidationFeedbackResolverPlan
        .didMaterializeFocusRingStyleToken && focusValidationFeedbackResolverPlan.didMaterializeInputFeedbackAffordance &&
        focusValidationFeedbackResolverPlan.didMaterializeChatComposerFocusValidationFeedbackSurface && focusValidationFeedbackResolverPlan
        .didBindResolverToStage613Manager && focusValidationFeedbackResolverPlan
        .didPrepareStage615FocusValidationDemoHostReceipt
    let stopLineReady = focusValidationFeedbackResolverFacts.didKeepOwnerAcceptanceRequired && focusValidationFeedbackResolverFacts
        .didKeepOwnerAcceptanceNotGranted && focusValidationFeedbackResolverFacts.didKeepProductionRenderTruthBlocked && focusValidationFeedbackResolverFacts
        .didKeepBackendReadyTruthBlocked && focusValidationFeedbackResolverFacts.didKeepStyleResolverBlocked && focusValidationFeedbackResolverFacts
        .didKeepFocusManagerBlocked && focusValidationFeedbackResolverFacts.didKeepStateUpdateCommittedBlocked && focusValidationFeedbackResolverPlan
        .didKeepRendererSubmissionBlocked && focusValidationFeedbackResolverPlan.didKeepRendererStateWriteBlocked && focusValidationFeedbackResolverPlan
        .didKeepRuntimeStateWriteBlocked && focusValidationFeedbackResolverFacts.didKeepNativeBridgeExpansionBlocked
    return CjguiInternalRendererStage614FocusValidationFeedbackResolverReadiness(
        focusValidationManager,
        focusValidationFeedbackResolverPlan,
        focusValidationFeedbackResolverFacts,
        resolverReady && stopLineReady,
        focusValidationFeedbackResolverPlan.didConsumeStage613FocusValidationManager,
        focusValidationManager.didConfirmStage612SharedFeedbackHostInspectionCycleExecutorContractConsumed,
        focusValidationFeedbackResolverPlan.didMaterializeSharedFocusValidationFeedbackResolver,
        focusValidationFeedbackResolverPlan.didMaterializeValidationMessageTextRun,
        focusValidationFeedbackResolverPlan.didMaterializeFocusRingStyleToken,
        focusValidationFeedbackResolverPlan.didMaterializeInputFeedbackAffordance,
        focusValidationFeedbackResolverPlan.didMaterializeTodoFocusValidationFeedbackSurface,
        focusValidationFeedbackResolverPlan.didMaterializeSettingsFocusValidationFeedbackSurface,
        focusValidationFeedbackResolverPlan.didMaterializeAiGeneratedSettingsFocusValidationFeedbackSurface,
        focusValidationFeedbackResolverPlan.didMaterializeChatComposerFocusValidationFeedbackSurface,
        focusValidationFeedbackResolverPlan.didBindResolverToStage613Manager,
        focusValidationFeedbackResolverPlan.didPrepareStage615FocusValidationDemoHostReceipt,
        focusValidationFeedbackResolverFacts.didKeepOwnerAcceptanceRequired,
        false,
        false,
        false,
        false,
        false,
        false,
        focusValidationFeedbackResolverPlan.didKeepRendererSubmissionBlocked,
        focusValidationFeedbackResolverPlan.didKeepRendererStateWriteBlocked,
        focusValidationFeedbackResolverPlan.didKeepRuntimeStateWriteBlocked,
        focusValidationFeedbackResolverFacts.didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage614FocusValidationFeedbackResolverDraft(): CjguiInternalRendererStage614FocusValidationFeedbackResolverReadiness {
    let focusValidationManager = cjguiInternalExecuteDefaultRendererStage613FocusValidationManagerDraft()
    let focusValidationFeedbackResolverPlan = cjguiInternalBuildRendererStage614FocusValidationFeedbackResolverPlan(
        focusValidationManager)
    let focusValidationFeedbackResolverFacts = cjguiInternalBuildRendererStage614FocusValidationFeedbackResolverFacts(
        focusValidationManager,
        focusValidationFeedbackResolverPlan
    )
    return cjguiInternalBuildRendererStage614FocusValidationFeedbackResolverReadiness(
        focusValidationManager,
        focusValidationFeedbackResolverPlan,
        focusValidationFeedbackResolverFacts
    )
}
