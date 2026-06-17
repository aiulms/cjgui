// 中文维护注释：本文件是 stage862 text input acceptance decision reducer owner。
// Owner: 消费 stage861 review gate，构造 accept/reject/request-changes 的非分发 decision reducer。
// Truth: 只证明 owner review 可产出可检查 decision candidates 与 rollback/not-published receipt。
// Stop-line: 不授予 owner acceptance、不提交 state-store、不写 renderer_state/runtime_state、不扩 public API。
// Same-shape Boundary Brake: 本 slice 将 acceptance decision 收敛为共享 reducer，供 demo-host surface 复用。
package cjgui

struct CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerPlan {
    let didConsumeStage861TextInputOwnerAcceptanceReviewGate: Bool
    let didConsumeStage860OwnerLocalTextInputCommitRuntimeManagerTransitively: Bool
    let didMaterializeAcceptedDecisionCandidate: Bool
    let didMaterializeRejectedDecisionCandidate: Bool
    let didMaterializeRequestChangesDecisionCandidate: Bool
    let didMaterializeRollbackSnapshotSelection: Bool
    let didMaterializeNotPublishedAcceptanceReceipt: Bool
    let didBindDecisionReducerToStage861ReviewGate: Bool
    let didPrepareStage863TextInputAcceptanceDemoHostSurface: Bool
    let didKeepOwnerAcceptanceNotGranted: Bool
    let didKeepTextInputCommitNotCommitted: Bool
    let didKeepStateStoreCommitNotPublished: Bool
    let didKeepActionDispatchBlocked: Bool
    let didKeepStateUpdateCommittedBlocked: Bool
    let didKeepVisibilityPublicationAdmittedBlocked: Bool
    let didKeepVisibilityPublishedBlocked: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool

    init(
        didConsumeStage861TextInputOwnerAcceptanceReviewGate: Bool,
        didConsumeStage860OwnerLocalTextInputCommitRuntimeManagerTransitively: Bool,
        didMaterializeAcceptedDecisionCandidate: Bool,
        didMaterializeRejectedDecisionCandidate: Bool,
        didMaterializeRequestChangesDecisionCandidate: Bool,
        didMaterializeRollbackSnapshotSelection: Bool,
        didMaterializeNotPublishedAcceptanceReceipt: Bool,
        didBindDecisionReducerToStage861ReviewGate: Bool,
        didPrepareStage863TextInputAcceptanceDemoHostSurface: Bool,
        didKeepOwnerAcceptanceNotGranted: Bool,
        didKeepTextInputCommitNotCommitted: Bool,
        didKeepStateStoreCommitNotPublished: Bool,
        didKeepActionDispatchBlocked: Bool,
        didKeepStateUpdateCommittedBlocked: Bool,
        didKeepVisibilityPublicationAdmittedBlocked: Bool,
        didKeepVisibilityPublishedBlocked: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool
    ) {
        this.didConsumeStage861TextInputOwnerAcceptanceReviewGate = didConsumeStage861TextInputOwnerAcceptanceReviewGate
        this.didConsumeStage860OwnerLocalTextInputCommitRuntimeManagerTransitively = didConsumeStage860OwnerLocalTextInputCommitRuntimeManagerTransitively
        this.didMaterializeAcceptedDecisionCandidate = didMaterializeAcceptedDecisionCandidate
        this.didMaterializeRejectedDecisionCandidate = didMaterializeRejectedDecisionCandidate
        this.didMaterializeRequestChangesDecisionCandidate = didMaterializeRequestChangesDecisionCandidate
        this.didMaterializeRollbackSnapshotSelection = didMaterializeRollbackSnapshotSelection
        this.didMaterializeNotPublishedAcceptanceReceipt = didMaterializeNotPublishedAcceptanceReceipt
        this.didBindDecisionReducerToStage861ReviewGate = didBindDecisionReducerToStage861ReviewGate
        this.didPrepareStage863TextInputAcceptanceDemoHostSurface = didPrepareStage863TextInputAcceptanceDemoHostSurface
        this.didKeepOwnerAcceptanceNotGranted = didKeepOwnerAcceptanceNotGranted
        this.didKeepTextInputCommitNotCommitted = didKeepTextInputCommitNotCommitted
        this.didKeepStateStoreCommitNotPublished = didKeepStateStoreCommitNotPublished
        this.didKeepActionDispatchBlocked = didKeepActionDispatchBlocked
        this.didKeepStateUpdateCommittedBlocked = didKeepStateUpdateCommittedBlocked
        this.didKeepVisibilityPublicationAdmittedBlocked = didKeepVisibilityPublicationAdmittedBlocked
        this.didKeepVisibilityPublishedBlocked = didKeepVisibilityPublishedBlocked
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
    }
}

struct CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerFacts {
    let decisionReducerPlan: CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerPlan
    let didKeepNoPublicComponentApiAdded: Bool
    let didKeepNoNewPublicSurfaceAdded: Bool
    let didKeepStablePublicApiNotAdded: Bool
    let didKeepPublicCAbiNotAdded: Bool
    let didKeepNativeBridgeExpansionBlocked: Bool

    init(
        decisionReducerPlan: CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerPlan,
        didKeepNoPublicComponentApiAdded: Bool,
        didKeepNoNewPublicSurfaceAdded: Bool,
        didKeepStablePublicApiNotAdded: Bool,
        didKeepPublicCAbiNotAdded: Bool,
        didKeepNativeBridgeExpansionBlocked: Bool
    ) {
        this.decisionReducerPlan = decisionReducerPlan
        this.didKeepNoPublicComponentApiAdded = didKeepNoPublicComponentApiAdded
        this.didKeepNoNewPublicSurfaceAdded = didKeepNoNewPublicSurfaceAdded
        this.didKeepStablePublicApiNotAdded = didKeepStablePublicApiNotAdded
        this.didKeepPublicCAbiNotAdded = didKeepPublicCAbiNotAdded
        this.didKeepNativeBridgeExpansionBlocked = didKeepNativeBridgeExpansionBlocked
    }
}

struct CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerReadiness {
    let reviewGate: CjguiInternalRendererStage861TextInputOwnerAcceptanceReviewGateReadiness
    let decisionReducerPlan: CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerPlan
    let decisionReducerFacts: CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerFacts
    let didConfirmStage862TextInputAcceptanceDecisionReducerReady: Bool
    let didConfirmStage861TextInputOwnerAcceptanceReviewGateConsumed: Bool
    let didConfirmStage860OwnerLocalTextInputCommitRuntimeManagerConsumedTransitively: Bool
    let didConfirmAcceptedDecisionCandidateMaterialized: Bool
    let didConfirmRejectedDecisionCandidateMaterialized: Bool
    let didConfirmRequestChangesDecisionCandidateMaterialized: Bool
    let didConfirmRollbackSnapshotSelectionMaterialized: Bool
    let didConfirmNotPublishedAcceptanceReceiptMaterialized: Bool
    let didConfirmDecisionReducerBoundToStage861ReviewGate: Bool
    let didConfirmStage863TextInputAcceptanceDemoHostSurfacePrepared: Bool
    let didConfirmPublicComponentApiAdded: Bool
    let didConfirmNewPublicSurfaceAdded: Bool
    let didConfirmStablePublicApiAdded: Bool
    let didConfirmPublicCAbiAdded: Bool
    let didConfirmOwnerAcceptanceGranted: Bool
    let didConfirmTextInputCommitCommitted: Bool
    let didConfirmStateStoreCommitPublished: Bool
    let didConfirmActionDispatch: Bool
    let didConfirmStateUpdateCommitted: Bool
    let didConfirmVisibilityPublicationAdmitted: Bool
    let didConfirmVisibilityPublished: Bool
    let didConfirmRendererSubmission: Bool
    let didConfirmRendererStateWrite: Bool
    let didConfirmRuntimeStateWrite: Bool
    let didConfirmNativeBridgeExpansionBlocked: Bool

    init(
        reviewGate: CjguiInternalRendererStage861TextInputOwnerAcceptanceReviewGateReadiness,
        decisionReducerPlan: CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerPlan,
        decisionReducerFacts: CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerFacts,
        didConfirmStage862TextInputAcceptanceDecisionReducerReady: Bool,
        didConfirmStage861TextInputOwnerAcceptanceReviewGateConsumed: Bool,
        didConfirmStage860OwnerLocalTextInputCommitRuntimeManagerConsumedTransitively: Bool,
        didConfirmAcceptedDecisionCandidateMaterialized: Bool,
        didConfirmRejectedDecisionCandidateMaterialized: Bool,
        didConfirmRequestChangesDecisionCandidateMaterialized: Bool,
        didConfirmRollbackSnapshotSelectionMaterialized: Bool,
        didConfirmNotPublishedAcceptanceReceiptMaterialized: Bool,
        didConfirmDecisionReducerBoundToStage861ReviewGate: Bool,
        didConfirmStage863TextInputAcceptanceDemoHostSurfacePrepared: Bool,
        didConfirmPublicComponentApiAdded: Bool,
        didConfirmNewPublicSurfaceAdded: Bool,
        didConfirmStablePublicApiAdded: Bool,
        didConfirmPublicCAbiAdded: Bool,
        didConfirmOwnerAcceptanceGranted: Bool,
        didConfirmTextInputCommitCommitted: Bool,
        didConfirmStateStoreCommitPublished: Bool,
        didConfirmActionDispatch: Bool,
        didConfirmStateUpdateCommitted: Bool,
        didConfirmVisibilityPublicationAdmitted: Bool,
        didConfirmVisibilityPublished: Bool,
        didConfirmRendererSubmission: Bool,
        didConfirmRendererStateWrite: Bool,
        didConfirmRuntimeStateWrite: Bool,
        didConfirmNativeBridgeExpansionBlocked: Bool
    ) {
        this.reviewGate = reviewGate
        this.decisionReducerPlan = decisionReducerPlan
        this.decisionReducerFacts = decisionReducerFacts
        this.didConfirmStage862TextInputAcceptanceDecisionReducerReady = didConfirmStage862TextInputAcceptanceDecisionReducerReady
        this.didConfirmStage861TextInputOwnerAcceptanceReviewGateConsumed = didConfirmStage861TextInputOwnerAcceptanceReviewGateConsumed
        this.didConfirmStage860OwnerLocalTextInputCommitRuntimeManagerConsumedTransitively = didConfirmStage860OwnerLocalTextInputCommitRuntimeManagerConsumedTransitively
        this.didConfirmAcceptedDecisionCandidateMaterialized = didConfirmAcceptedDecisionCandidateMaterialized
        this.didConfirmRejectedDecisionCandidateMaterialized = didConfirmRejectedDecisionCandidateMaterialized
        this.didConfirmRequestChangesDecisionCandidateMaterialized = didConfirmRequestChangesDecisionCandidateMaterialized
        this.didConfirmRollbackSnapshotSelectionMaterialized = didConfirmRollbackSnapshotSelectionMaterialized
        this.didConfirmNotPublishedAcceptanceReceiptMaterialized = didConfirmNotPublishedAcceptanceReceiptMaterialized
        this.didConfirmDecisionReducerBoundToStage861ReviewGate = didConfirmDecisionReducerBoundToStage861ReviewGate
        this.didConfirmStage863TextInputAcceptanceDemoHostSurfacePrepared = didConfirmStage863TextInputAcceptanceDemoHostSurfacePrepared
        this.didConfirmPublicComponentApiAdded = didConfirmPublicComponentApiAdded
        this.didConfirmNewPublicSurfaceAdded = didConfirmNewPublicSurfaceAdded
        this.didConfirmStablePublicApiAdded = didConfirmStablePublicApiAdded
        this.didConfirmPublicCAbiAdded = didConfirmPublicCAbiAdded
        this.didConfirmOwnerAcceptanceGranted = didConfirmOwnerAcceptanceGranted
        this.didConfirmTextInputCommitCommitted = didConfirmTextInputCommitCommitted
        this.didConfirmStateStoreCommitPublished = didConfirmStateStoreCommitPublished
        this.didConfirmActionDispatch = didConfirmActionDispatch
        this.didConfirmStateUpdateCommitted = didConfirmStateUpdateCommitted
        this.didConfirmVisibilityPublicationAdmitted = didConfirmVisibilityPublicationAdmitted
        this.didConfirmVisibilityPublished = didConfirmVisibilityPublished
        this.didConfirmRendererSubmission = didConfirmRendererSubmission
        this.didConfirmRendererStateWrite = didConfirmRendererStateWrite
        this.didConfirmRuntimeStateWrite = didConfirmRuntimeStateWrite
        this.didConfirmNativeBridgeExpansionBlocked = didConfirmNativeBridgeExpansionBlocked
    }
}

func cjguiInternalRendererStage862TextInputAcceptanceDecisionReducerMaterialized(): Bool {
    return true
}

func cjguiInternalBuildRendererStage862TextInputAcceptanceDecisionReducerPlan(
    reviewGate: CjguiInternalRendererStage861TextInputOwnerAcceptanceReviewGateReadiness): CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerPlan {
    let stage861Ready = reviewGate.didConfirmStage861TextInputOwnerAcceptanceReviewGateReady && reviewGate
        .didConfirmStage862TextInputAcceptanceDecisionReducerPrepared
    let gateReady = reviewGate.didConfirmOwnerAcceptanceReviewGateMaterialized && reviewGate
        .didConfirmAcceptDecisionLaneMaterialized && reviewGate.didConfirmRejectReasonLaneMaterialized && reviewGate
        .didConfirmRequestChangesLaneMaterialized && reviewGate.didConfirmRollbackSnapshotReviewLaneMaterialized
    let reducerReady = stage861Ready && gateReady &&
        cjguiInternalRendererStage862TextInputAcceptanceDecisionReducerMaterialized()
    return CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerPlan(
        stage861Ready,
        reviewGate.didConfirmStage860OwnerLocalTextInputCommitRuntimeManagerConsumed,
        reducerReady,
        reducerReady,
        reducerReady,
        reducerReady,
        reducerReady,
        reviewGate.didConfirmReviewGateBoundToStage860RuntimeManager,
        reducerReady,
        reviewGate.didConfirmOwnerAcceptanceGranted == false,
        reviewGate.didConfirmTextInputCommitCommitted == false,
        reviewGate.didConfirmStateStoreCommitPublished == false,
        reviewGate.didConfirmActionDispatch == false,
        reviewGate.didConfirmStateUpdateCommitted == false,
        reviewGate.didConfirmVisibilityPublicationAdmitted == false,
        reviewGate.didConfirmVisibilityPublished == false,
        reviewGate.didConfirmRendererSubmission == false,
        reviewGate.didConfirmRendererStateWrite == false,
        reviewGate.didConfirmRuntimeStateWrite == false
    )
}

func cjguiInternalBuildRendererStage862TextInputAcceptanceDecisionReducerFacts(
    reviewGate: CjguiInternalRendererStage861TextInputOwnerAcceptanceReviewGateReadiness,
    decisionReducerPlan: CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerPlan
): CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerFacts {
    return CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerFacts(
        decisionReducerPlan,
        reviewGate.didConfirmPublicComponentApiAdded == false,
        reviewGate.didConfirmNewPublicSurfaceAdded == false,
        reviewGate.didConfirmStablePublicApiAdded == false,
        reviewGate.didConfirmPublicCAbiAdded == false,
        reviewGate.didConfirmNativeBridgeExpansionBlocked
    )
}

func cjguiInternalBuildRendererStage862TextInputAcceptanceDecisionReducerReadiness(
    reviewGate: CjguiInternalRendererStage861TextInputOwnerAcceptanceReviewGateReadiness,
    decisionReducerPlan: CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerPlan,
    decisionReducerFacts: CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerFacts
): CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerReadiness {
    let reducerReady = decisionReducerPlan.didConsumeStage861TextInputOwnerAcceptanceReviewGate && decisionReducerPlan
        .didConsumeStage860OwnerLocalTextInputCommitRuntimeManagerTransitively && decisionReducerPlan
        .didMaterializeAcceptedDecisionCandidate && decisionReducerPlan.didMaterializeRejectedDecisionCandidate && decisionReducerPlan
        .didMaterializeRequestChangesDecisionCandidate && decisionReducerPlan.didMaterializeRollbackSnapshotSelection && decisionReducerPlan
        .didMaterializeNotPublishedAcceptanceReceipt && decisionReducerPlan.didBindDecisionReducerToStage861ReviewGate &&
        decisionReducerPlan.didPrepareStage863TextInputAcceptanceDemoHostSurface
    let stopLineReady = decisionReducerFacts.didKeepNoPublicComponentApiAdded && decisionReducerFacts
        .didKeepNoNewPublicSurfaceAdded && decisionReducerFacts.didKeepStablePublicApiNotAdded && decisionReducerFacts
        .didKeepPublicCAbiNotAdded && decisionReducerPlan.didKeepOwnerAcceptanceNotGranted && decisionReducerPlan
        .didKeepTextInputCommitNotCommitted && decisionReducerPlan.didKeepStateStoreCommitNotPublished && decisionReducerPlan
        .didKeepActionDispatchBlocked && decisionReducerPlan.didKeepStateUpdateCommittedBlocked && decisionReducerPlan
        .didKeepVisibilityPublicationAdmittedBlocked && decisionReducerPlan.didKeepVisibilityPublishedBlocked && decisionReducerPlan
        .didKeepRendererSubmissionBlocked && decisionReducerPlan.didKeepRendererStateWriteBlocked && decisionReducerPlan
        .didKeepRuntimeStateWriteBlocked && decisionReducerFacts.didKeepNativeBridgeExpansionBlocked
    return CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerReadiness(
        reviewGate,
        decisionReducerPlan,
        decisionReducerFacts,
        reducerReady && stopLineReady,
        decisionReducerPlan.didConsumeStage861TextInputOwnerAcceptanceReviewGate,
        decisionReducerPlan.didConsumeStage860OwnerLocalTextInputCommitRuntimeManagerTransitively,
        decisionReducerPlan.didMaterializeAcceptedDecisionCandidate,
        decisionReducerPlan.didMaterializeRejectedDecisionCandidate,
        decisionReducerPlan.didMaterializeRequestChangesDecisionCandidate,
        decisionReducerPlan.didMaterializeRollbackSnapshotSelection,
        decisionReducerPlan.didMaterializeNotPublishedAcceptanceReceipt,
        decisionReducerPlan.didBindDecisionReducerToStage861ReviewGate,
        decisionReducerPlan.didPrepareStage863TextInputAcceptanceDemoHostSurface,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        decisionReducerFacts.didKeepNativeBridgeExpansionBlocked
    )
}

func cjguiInternalExecuteDefaultRendererStage862TextInputAcceptanceDecisionReducerDraft(): CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerReadiness {
    let reviewGate = cjguiInternalExecuteDefaultRendererStage861TextInputOwnerAcceptanceReviewGateDraft()
    let decisionReducerPlan = cjguiInternalBuildRendererStage862TextInputAcceptanceDecisionReducerPlan(reviewGate)
    let decisionReducerFacts = cjguiInternalBuildRendererStage862TextInputAcceptanceDecisionReducerFacts(
        reviewGate,
        decisionReducerPlan
    )
    return cjguiInternalBuildRendererStage862TextInputAcceptanceDecisionReducerReadiness(
        reviewGate,
        decisionReducerPlan,
        decisionReducerFacts
    )
}
