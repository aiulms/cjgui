// 中文维护注释：本文件是 stage834 publishable state text/focus measurement plan owner。
// Owner: 消费 stage833 layout/style resolver input，建立文本、选择、caret 与焦点测量占位。
// Truth: 只证明 resolver preview 能携带 text/focus measurement input，不启用 text shaping / focus manager。
// Stop-line: 不执行文本排版、不移动焦点、不提交状态、不写 renderer_state/runtime_state。
// Same-shape Boundary Brake: 本 slice 用共享 measurement plan 替代后续 per-demo text/focus 模板。
package cjgui

struct CjguiInternalRendererStage834PublishableStateTextFocusMeasurementPlan {
    let didConsumeStage833PublishableStateLayoutStyleResolver: Bool
    let didConsumeLayoutStyleResolverInput: Bool
    let didMaterializeTextRunMeasurementInput: Bool
    let didMaterializeSelectionRangeMeasurementInput: Bool
    let didMaterializeCaretGeometryPlaceholder: Bool
    let didMaterializeFocusTraversalMeasurementLedger: Bool
    let didBindMeasurementPlanToLayoutStyleResolver: Bool
    let didPrepareStage835PublishableStateLayoutStyleDemoSurface: Bool
    let didKeepTextShapingDisabled: Bool
    let didKeepFocusManagerDisabled: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool

    init(
        didConsumeStage833PublishableStateLayoutStyleResolver: Bool,
        didConsumeLayoutStyleResolverInput: Bool,
        didMaterializeTextRunMeasurementInput: Bool,
        didMaterializeSelectionRangeMeasurementInput: Bool,
        didMaterializeCaretGeometryPlaceholder: Bool,
        didMaterializeFocusTraversalMeasurementLedger: Bool,
        didBindMeasurementPlanToLayoutStyleResolver: Bool,
        didPrepareStage835PublishableStateLayoutStyleDemoSurface: Bool,
        didKeepTextShapingDisabled: Bool,
        didKeepFocusManagerDisabled: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool
    ) {
        this.didConsumeStage833PublishableStateLayoutStyleResolver = didConsumeStage833PublishableStateLayoutStyleResolver
        this.didConsumeLayoutStyleResolverInput = didConsumeLayoutStyleResolverInput
        this.didMaterializeTextRunMeasurementInput = didMaterializeTextRunMeasurementInput
        this.didMaterializeSelectionRangeMeasurementInput = didMaterializeSelectionRangeMeasurementInput
        this.didMaterializeCaretGeometryPlaceholder = didMaterializeCaretGeometryPlaceholder
        this.didMaterializeFocusTraversalMeasurementLedger = didMaterializeFocusTraversalMeasurementLedger
        this.didBindMeasurementPlanToLayoutStyleResolver = didBindMeasurementPlanToLayoutStyleResolver
        this.didPrepareStage835PublishableStateLayoutStyleDemoSurface = didPrepareStage835PublishableStateLayoutStyleDemoSurface
        this.didKeepTextShapingDisabled = didKeepTextShapingDisabled
        this.didKeepFocusManagerDisabled = didKeepFocusManagerDisabled
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
    }
}

struct CjguiInternalRendererStage834PublishableStateTextFocusMeasurementFacts {
    let measurementPlan: CjguiInternalRendererStage834PublishableStateTextFocusMeasurementPlan
    let didKeepPublicComponentApiAdded: Bool
    let didKeepNoNewPublicSurfaceAdded: Bool
    let didKeepStablePublicApiNotAdded: Bool
    let didKeepPublicCAbiNotAdded: Bool
    let didKeepStateStoreCommitNotPublished: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepNativeBridgeExpansionBlocked: Bool

    init(
        measurementPlan: CjguiInternalRendererStage834PublishableStateTextFocusMeasurementPlan,
        didKeepPublicComponentApiAdded: Bool,
        didKeepNoNewPublicSurfaceAdded: Bool,
        didKeepStablePublicApiNotAdded: Bool,
        didKeepPublicCAbiNotAdded: Bool,
        didKeepStateStoreCommitNotPublished: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepNativeBridgeExpansionBlocked: Bool
    ) {
        this.measurementPlan = measurementPlan
        this.didKeepPublicComponentApiAdded = didKeepPublicComponentApiAdded
        this.didKeepNoNewPublicSurfaceAdded = didKeepNoNewPublicSurfaceAdded
        this.didKeepStablePublicApiNotAdded = didKeepStablePublicApiNotAdded
        this.didKeepPublicCAbiNotAdded = didKeepPublicCAbiNotAdded
        this.didKeepStateStoreCommitNotPublished = didKeepStateStoreCommitNotPublished
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepStateUpdateCommittedBlocked = didKeepStateUpdateCommittedBlocked
        this.didKeepNativeBridgeExpansionBlocked = didKeepNativeBridgeExpansionBlocked
    }
}

struct CjguiInternalRendererStage834PublishableStateTextFocusMeasurementReadiness {
    let layoutStyleResolver: CjguiInternalRendererStage833PublishableStateLayoutStyleResolverReadiness
    let measurementPlan: CjguiInternalRendererStage834PublishableStateTextFocusMeasurementPlan
    let measurementFacts: CjguiInternalRendererStage834PublishableStateTextFocusMeasurementFacts
    let didConfirmStage834PublishableStateTextFocusMeasurementPlanReady: Bool
    let didConfirmStage833PublishableStateLayoutStyleResolverConsumed: Bool
    let didConfirmStage832ComponentStateStorePublishableRuntimeManagerConsumedTransitively: Bool
    let didConfirmLayoutStyleResolverInputConsumed: Bool
    let didConfirmTextRunMeasurementInputMaterialized: Bool
    let didConfirmSelectionRangeMeasurementInputMaterialized: Bool
    let didConfirmCaretGeometryPlaceholderMaterialized: Bool
    let didConfirmFocusTraversalMeasurementLedgerMaterialized: Bool
    let didConfirmMeasurementPlanBoundToLayoutStyleResolver: Bool
    let didConfirmStage835PublishableStateLayoutStyleDemoSurfacePrepared: Bool
    let didConfirmTextShapingEnabled: Bool
    let didConfirmFocusManagerEnabled: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmNewPublicSurfaceAdded: Bool
    let didConfirmStablePublicApiAdded: Bool
    let didConfirmPublicCAbiAdded: Bool
    let didConfirmStateStoreCommitPublished: Bool
    let didConfirmActionDispatch: Bool
    let didConfirmStateUpdateCommitted: Bool
    let didConfirmRendererSubmission: Bool
    let didConfirmRendererStateWrite: Bool
    let didConfirmRuntimeStateWrite: Bool
    let didConfirmNativeBridgeExpansionBlocked: Bool

    init(
        layoutStyleResolver: CjguiInternalRendererStage833PublishableStateLayoutStyleResolverReadiness,
        measurementPlan: CjguiInternalRendererStage834PublishableStateTextFocusMeasurementPlan,
        measurementFacts: CjguiInternalRendererStage834PublishableStateTextFocusMeasurementFacts,
        didConfirmStage834PublishableStateTextFocusMeasurementPlanReady: Bool,
        didConfirmStage833PublishableStateLayoutStyleResolverConsumed: Bool,
        didConfirmStage832ComponentStateStorePublishableRuntimeManagerConsumedTransitively: Bool,
        didConfirmLayoutStyleResolverInputConsumed: Bool,
        didConfirmTextRunMeasurementInputMaterialized: Bool,
        didConfirmSelectionRangeMeasurementInputMaterialized: Bool,
        didConfirmCaretGeometryPlaceholderMaterialized: Bool,
        didConfirmFocusTraversalMeasurementLedgerMaterialized: Bool,
        didConfirmMeasurementPlanBoundToLayoutStyleResolver: Bool,
        didConfirmStage835PublishableStateLayoutStyleDemoSurfacePrepared: Bool,
        didConfirmTextShapingEnabled: Bool,
        didConfirmFocusManagerEnabled: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmNewPublicSurfaceAdded: Bool,
        didConfirmStablePublicApiAdded: Bool,
        didConfirmPublicCAbiAdded: Bool,
        didConfirmStateStoreCommitPublished: Bool,
        didConfirmActionDispatch: Bool,
        didConfirmStateUpdateCommitted: Bool,
        didConfirmRendererSubmission: Bool,
        didConfirmRendererStateWrite: Bool,
        didConfirmRuntimeStateWrite: Bool,
        didConfirmNativeBridgeExpansionBlocked: Bool
    ) {
        this.layoutStyleResolver = layoutStyleResolver
        this.measurementPlan = measurementPlan
        this.measurementFacts = measurementFacts
        this.didConfirmStage834PublishableStateTextFocusMeasurementPlanReady = didConfirmStage834PublishableStateTextFocusMeasurementPlanReady
        this.didConfirmStage833PublishableStateLayoutStyleResolverConsumed = didConfirmStage833PublishableStateLayoutStyleResolverConsumed
        this.didConfirmStage832ComponentStateStorePublishableRuntimeManagerConsumedTransitively = didConfirmStage832ComponentStateStorePublishableRuntimeManagerConsumedTransitively
        this.didConfirmLayoutStyleResolverInputConsumed = didConfirmLayoutStyleResolverInputConsumed
        this.didConfirmTextRunMeasurementInputMaterialized = didConfirmTextRunMeasurementInputMaterialized
        this.didConfirmSelectionRangeMeasurementInputMaterialized = didConfirmSelectionRangeMeasurementInputMaterialized
        this.didConfirmCaretGeometryPlaceholderMaterialized = didConfirmCaretGeometryPlaceholderMaterialized
        this.didConfirmFocusTraversalMeasurementLedgerMaterialized = didConfirmFocusTraversalMeasurementLedgerMaterialized
        this.didConfirmMeasurementPlanBoundToLayoutStyleResolver = didConfirmMeasurementPlanBoundToLayoutStyleResolver
        this.didConfirmStage835PublishableStateLayoutStyleDemoSurfacePrepared = didConfirmStage835PublishableStateLayoutStyleDemoSurfacePrepared
        this.didConfirmTextShapingEnabled = didConfirmTextShapingEnabled
        this.didConfirmFocusManagerEnabled = didConfirmFocusManagerEnabled
        this.didConfirmPublicComponentApiAdded = didConfirmPublicComponentApiAdded
        this.didConfirmNewPublicSurfaceAdded = didConfirmNewPublicSurfaceAdded
        this.didConfirmStablePublicApiAdded = didConfirmStablePublicApiAdded
        this.didConfirmPublicCAbiAdded = didConfirmPublicCAbiAdded
        this.didConfirmStateStoreCommitPublished = didConfirmStateStoreCommitPublished
        this.didConfirmActionDispatch = didConfirmActionDispatch
        this.didConfirmStateUpdateCommitted = didConfirmStateUpdateCommitted
        this.didConfirmRendererSubmission = didConfirmRendererSubmission
        this.didConfirmRendererStateWrite = didConfirmRendererStateWrite
        this.didConfirmRuntimeStateWrite = didConfirmRuntimeStateWrite
        this.didConfirmNativeBridgeExpansionBlocked = didConfirmNativeBridgeExpansionBlocked
    }
}

func cjguiInternalRendererStage834PublishableStateTextFocusMeasurementMaterialized(): Bool {
    return true
}

func cjguiInternalBuildRendererStage834PublishableStateTextFocusMeasurementPlan(
    layoutStyleResolver: CjguiInternalRendererStage833PublishableStateLayoutStyleResolverReadiness): CjguiInternalRendererStage834PublishableStateTextFocusMeasurementPlan {
    let stage833Ready = layoutStyleResolver.didConfirmStage833PublishableStateLayoutStyleResolverReady && layoutStyleResolver
        .didConfirmStage834PublishableStateTextFocusMeasurementPlanPrepared
    let resolverInputReady = layoutStyleResolver.didConfirmPublishableStateLayoutResolverInputMaterialized && layoutStyleResolver
        .didConfirmPublishableStateStyleResolverInputMaterialized && layoutStyleResolver
        .didConfirmLayoutSlotConstraintLedgerMaterialized && layoutStyleResolver
        .didConfirmStyleTokenResolutionLedgerMaterialized
    let measurementReady = stage833Ready && resolverInputReady &&
        cjguiInternalRendererStage834PublishableStateTextFocusMeasurementMaterialized()
    return CjguiInternalRendererStage834PublishableStateTextFocusMeasurementPlan(
        stage833Ready,
        resolverInputReady,
        measurementReady,
        measurementReady,
        measurementReady,
        measurementReady,
        layoutStyleResolver.didConfirmResolverInputBoundToStage832RuntimeManager,
        measurementReady,
        true,
        true,
        layoutStyleResolver.didConfirmRendererSubmission == false,
        layoutStyleResolver.didConfirmRendererStateWrite == false,
        layoutStyleResolver.didConfirmRuntimeStateWrite == false
    )
}

func cjguiInternalBuildRendererStage834PublishableStateTextFocusMeasurementFacts(
    layoutStyleResolver: CjguiInternalRendererStage833PublishableStateLayoutStyleResolverReadiness,
    measurementPlan: CjguiInternalRendererStage834PublishableStateTextFocusMeasurementPlan
): CjguiInternalRendererStage834PublishableStateTextFocusMeasurementFacts {
    return CjguiInternalRendererStage834PublishableStateTextFocusMeasurementFacts(
        measurementPlan,
        layoutStyleResolver.didConfirmPublicComponentApiAdded,
        layoutStyleResolver.didConfirmNewPublicSurfaceAdded == false,
        layoutStyleResolver.didConfirmStablePublicApiAdded == false,
        layoutStyleResolver.didConfirmPublicCAbiAdded == false,
        layoutStyleResolver.didConfirmStateStoreCommitPublished == false,
        layoutStyleResolver.didConfirmActionDispatch == false,
        layoutStyleResolver.didConfirmStateUpdateCommitted == false,
        layoutStyleResolver.didConfirmNativeBridgeExpansionBlocked
    )
}

func cjguiInternalBuildRendererStage834PublishableStateTextFocusMeasurementReadiness(
    layoutStyleResolver: CjguiInternalRendererStage833PublishableStateLayoutStyleResolverReadiness,
    measurementPlan: CjguiInternalRendererStage834PublishableStateTextFocusMeasurementPlan,
    measurementFacts: CjguiInternalRendererStage834PublishableStateTextFocusMeasurementFacts
): CjguiInternalRendererStage834PublishableStateTextFocusMeasurementReadiness {
    let measurementReady = measurementPlan.didConsumeStage833PublishableStateLayoutStyleResolver && measurementPlan
        .didConsumeLayoutStyleResolverInput && measurementPlan.didMaterializeTextRunMeasurementInput && measurementPlan
        .didMaterializeSelectionRangeMeasurementInput && measurementPlan.didMaterializeCaretGeometryPlaceholder && measurementPlan
        .didMaterializeFocusTraversalMeasurementLedger && measurementPlan.didBindMeasurementPlanToLayoutStyleResolver && measurementPlan
        .didPrepareStage835PublishableStateLayoutStyleDemoSurface
    let stopLineReady = measurementPlan.didKeepTextShapingDisabled && measurementPlan.didKeepFocusManagerDisabled && measurementFacts
        .didKeepPublicComponentApiAdded && measurementFacts.didKeepNoNewPublicSurfaceAdded && measurementFacts
        .didKeepStablePublicApiNotAdded && measurementFacts.didKeepPublicCAbiNotAdded && measurementFacts
        .didKeepStateStoreCommitNotPublished && measurementFacts.didKeepActionDispatchBlocked && measurementFacts
        .didKeepStateUpdateCommittedBlocked && measurementPlan.didKeepRendererSubmissionBlocked && measurementPlan
        .didKeepRendererStateWriteBlocked && measurementPlan.didKeepRuntimeStateWriteBlocked && measurementFacts
        .didKeepNativeBridgeExpansionBlocked
    return CjguiInternalRendererStage834PublishableStateTextFocusMeasurementReadiness(
        layoutStyleResolver,
        measurementPlan,
        measurementFacts,
        measurementReady && stopLineReady,
        measurementPlan.didConsumeStage833PublishableStateLayoutStyleResolver,
        layoutStyleResolver.didConfirmStage832ComponentStateStorePublishableRuntimeManagerConsumed,
        measurementPlan.didConsumeLayoutStyleResolverInput,
        measurementPlan.didMaterializeTextRunMeasurementInput,
        measurementPlan.didMaterializeSelectionRangeMeasurementInput,
        measurementPlan.didMaterializeCaretGeometryPlaceholder,
        measurementPlan.didMaterializeFocusTraversalMeasurementLedger,
        measurementPlan.didBindMeasurementPlanToLayoutStyleResolver,
        measurementPlan.didPrepareStage835PublishableStateLayoutStyleDemoSurface,
        false,
        false,
        measurementFacts.didKeepPublicComponentApiAdded,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        measurementFacts.didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage834PublishableStateTextFocusMeasurementDraft(): CjguiInternalRendererStage834PublishableStateTextFocusMeasurementReadiness {
    let layoutStyleResolver = cjguiInternalExecuteDefaultRendererStage833PublishableStateLayoutStyleResolverDraft()
    let measurementPlan = cjguiInternalBuildRendererStage834PublishableStateTextFocusMeasurementPlan(
        layoutStyleResolver)
    let measurementFacts = cjguiInternalBuildRendererStage834PublishableStateTextFocusMeasurementFacts(
        layoutStyleResolver,
        measurementPlan
    )
    return cjguiInternalBuildRendererStage834PublishableStateTextFocusMeasurementReadiness(
        layoutStyleResolver,
        measurementPlan,
        measurementFacts
    )
}
