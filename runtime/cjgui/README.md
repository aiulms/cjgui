# CJGUI Minimal Runtime Skeleton

日期：2026-04-26

状态：minimal package skeleton / internal lifecycle boundary surface

本目录当前记录的是 `runtime/cjgui` 的默认 internal 运行时骨架。它用于承载未来 app lifecycle、window lifecycle、platform adapter 和 error strategy 的最小边界，不是正式 runtime implementation，不提供稳定 public runtime API，也不提供 public C ABI。

## First Compilable Source Boundary

当前十个 `src/*.cj` 文件都使用同一个 `package cjgui` declaration，并且只承载默认 internal 的最小骨架符号：

- `src/action_router.cj`
  - `CjguiInternalActionSource`
  - `CjguiInternalActionKind`
  - `CjguiInternalActionIntent`
  - `CjguiInternalActionAdmission`
  - `cjguiInternalDefaultActionSource`
  - `cjguiInternalDefaultActionKind`
  - `cjguiInternalBuildActionIntent`
  - `cjguiInternalActionSourceIsValid`
  - `cjguiInternalActionKindIsValid`
  - `cjguiInternalEvaluateActionAdmission`
  - `cjguiInternalExecuteDefaultActionAdmissionDraft`
  - `cjguiInternalActionAdmissionCanAdmit`
- `src/app_lifecycle.cj`
  - `CjguiInternalAppLifecycleState`
  - `CjguiInternalAppLifecycleTransitionMarker`
  - `CjguiInternalAppLifecyclePhaseTaxonomyMarker`
  - `CjguiInternalAppLifecycleWorkHandoffDraft`
  - `CjguiInternalAppLifecycleMutationReadinessDraft`
  - `CjguiInternalAppLifecycleMutationPlanDraft`
  - `CjguiInternalAppLifecycleMutationCommitGateDraft`
  - `CjguiInternalAppLifecycleMutationApplyDraft`
  - `CjguiInternalAppLifecycleMutationResult`
  - `cjguiInternalNoOpAppLifecycleTransition`
  - `cjguiInternalAppLifecyclePhaseMarkerTransition`
  - `cjguiInternalAppLifecycleHasObservedPlatformReady`
  - `cjguiInternalBuildAppLifecycleWorkHandoffDraft`
  - `cjguiInternalBuildAppLifecycleMutationReadinessDraft`
  - `cjguiInternalBuildAppLifecycleMutationPlanDraft`
  - `cjguiInternalBuildAppLifecycleMutationCommitGateDraft`
  - `cjguiInternalBuildAppLifecycleMutationApplyDraft`
  - `cjguiInternalApplyAppLifecycleMutationDraft`
  - `cjguiInternalAppLifecycleWorkHandoffOpenSanity`
  - `cjguiInternalAppLifecycleWorkHandoffBlockedSanity`
  - `cjguiInternalAppLifecycleMutationReadinessOpenSanity`
  - `cjguiInternalAppLifecycleMutationReadinessBlockedSanity`
  - `cjguiInternalAppLifecycleMutationPlanOpenSanity`
  - `cjguiInternalAppLifecycleMutationPlanBlockedSanity`
  - `cjguiInternalAppLifecycleMutationCommitGateOpenSanity`
  - `cjguiInternalAppLifecycleMutationCommitGateBlockedSanity`
  - `cjguiInternalAppLifecycleMutationApplyOpenSanity`
  - `cjguiInternalAppLifecycleMutationApplyBlockedSanity`
  - `cjguiInternalAppLifecycleMutationOpenSanity`
  - `cjguiInternalAppLifecycleMutationBlockedSanity`
- `src/window_lifecycle.cj`
  - `CjguiInternalWindowLifecycleState`
  - `CjguiInternalWindowLifecycleWorkHandoffDraft`
  - `CjguiInternalWindowLifecycleMutationReadinessDraft`
  - `CjguiInternalWindowLifecycleMutationPlanDraft`
  - `CjguiInternalWindowLifecycleMutationCommitGateDraft`
  - `CjguiInternalWindowLifecycleMutationApplyDraft`
  - `CjguiInternalWindowLifecycleMutationResult`
  - `cjguiInternalNoOpWindowLifecycleTransition`
  - `cjguiInternalWindowLifecycleStateMarkerTransition`
  - `cjguiInternalWindowLifecycleHasObservedPlatformReady`
  - `cjguiInternalBuildWindowLifecycleWorkHandoffDraft`
  - `cjguiInternalBuildWindowLifecycleMutationReadinessDraft`
  - `cjguiInternalBuildWindowLifecycleMutationPlanDraft`
  - `cjguiInternalBuildWindowLifecycleMutationCommitGateDraft`
  - `cjguiInternalBuildWindowLifecycleMutationApplyDraft`
  - `cjguiInternalApplyWindowLifecycleMutationDraft`
  - `cjguiInternalWindowLifecycleWorkHandoffOpenSanity`
  - `cjguiInternalWindowLifecycleWorkHandoffBlockedSanity`
  - `cjguiInternalWindowLifecycleMutationReadinessOpenSanity`
  - `cjguiInternalWindowLifecycleMutationReadinessBlockedSanity`
  - `cjguiInternalWindowLifecycleMutationPlanOpenSanity`
  - `cjguiInternalWindowLifecycleMutationPlanBlockedSanity`
  - `cjguiInternalWindowLifecycleMutationCommitGateOpenSanity`
  - `cjguiInternalWindowLifecycleMutationCommitGateBlockedSanity`
  - `cjguiInternalWindowLifecycleMutationApplyOpenSanity`
  - `cjguiInternalWindowLifecycleMutationApplyBlockedSanity`
  - `cjguiInternalWindowLifecycleMutationOpenSanity`
  - `cjguiInternalWindowLifecycleMutationBlockedSanity`
- `src/platform_adapter.cj`
  - `CjguiInternalPlatformAdapterFact`
  - `cjguiInternalNoOpPlatformAdapterFactIngestion`
  - `cjguiInternalProjectPlatformFactToAppLifecycleState`
  - `cjguiInternalProjectPlatformFactToWindowLifecycleState`
  - `CjguiInternalLifecycleCoordinationResult`
  - `cjguiInternalCoordinateLifecycleFromPlatformFact`
  - `cjguiInternalLifecycleCoordinationSanity`
  - `cjguiInternalLifecycleCoordinationSanityObservedPlatformReady`
  - `cjguiInternalLifecycleCoordinationSanityNotObservedPlatformReady`
  - `cjguiInternalLifecycleCoordinationReadinessSanityParity`
- `src/runtime_bootstrap.cj`
  - `CjguiInternalRuntimeReadinessAggregate`
  - `CjguiInternalRuntimeBootstrapSnapshot`
  - `cjguiInternalBuildRuntimeReadinessAggregate`
  - `cjguiInternalBuildRuntimeBootstrapSnapshot`
- `src/runtime_scheduler.cj`
  - `CjguiInternalSchedulerTickSource`
  - `CjguiInternalSchedulerTickKind`
  - `CjguiInternalSchedulerTickIntent`
  - `CjguiInternalSchedulerTickAdmission`
  - `CjguiInternalSchedulerRuntimeIngress`
  - `cjguiInternalDefaultSchedulerTickSource`
  - `cjguiInternalDefaultSchedulerTickKind`
  - `cjguiInternalBuildSchedulerTickIntent`
  - `cjguiInternalSchedulerTickSourceIsValid`
  - `cjguiInternalSchedulerTickKindIsValid`
  - `cjguiInternalEvaluateSchedulerTickAdmission`
  - `cjguiInternalExecuteDefaultSchedulerTickAdmissionDraft`
  - `cjguiInternalBuildSchedulerRuntimeIngress`
  - `cjguiInternalExecuteDefaultSchedulerRuntimeIngressDraft`
- `src/runtime_ingress.cj`
  - `CjguiInternalRuntimeIngressCoordinator`
  - `cjguiInternalCoordinateRuntimeIngress`
  - `cjguiInternalExecuteDefaultRuntimeIngressCoordinatorDraft`
  - `cjguiInternalRuntimeIngressCoordinatorCanEnter`
  - `cjguiInternalRuntimeIngressCoordinatorShouldReportBlocked`
- `src/runtime_queue.cj`
  - `CjguiInternalQueueAdmissionPolicy`
  - `CjguiInternalQueueAdmission`
  - `cjguiInternalDefaultQueueAdmissionPolicy`
  - `cjguiInternalEvaluateQueueAdmission`
  - `cjguiInternalExecuteDefaultQueueAdmissionDraft`
  - `cjguiInternalQueueAdmissionCanAdmit`
- `src/runtime_state.cj`
  - `CjguiInternalRuntimeRootState`
  - `CjguiInternalRuntimeStepResult`
  - `CjguiInternalRuntimeStepInput`
  - `CjguiInternalRuntimeStepPolicy`
  - `CjguiInternalRuntimeStepDecision`
  - `CjguiInternalRuntimeCycleRequest`
  - `CjguiInternalRuntimeCycleResult`
  - `CjguiInternalRuntimeCommandDraft`
  - `CjguiInternalRuntimeCommandPipelineRequest`
  - `CjguiInternalRuntimeCommandPipelineResult`
  - `CjguiInternalRuntimeDriverRequest`
  - `CjguiInternalRuntimeDriverResult`
  - `CjguiInternalRuntimeDriverInput`
  - `CjguiInternalRuntimeDriverPolicy`
  - `CjguiInternalRuntimeDriverDecision`
  - `CjguiInternalRuntimeDriverReport`
  - `CjguiInternalRuntimeRunIntent`
  - `CjguiInternalRuntimeRunRequest`
  - `CjguiInternalRuntimeRunRequestReport`
  - `CjguiInternalRuntimeShutdownIntent`
  - `CjguiInternalRuntimeShutdownRequest`
  - `CjguiInternalRuntimeShutdownReport`
  - `CjguiInternalRunBoundaryRequest`
  - `CjguiInternalRunBoundaryReport`
  - `CjguiInternalAppRunState`
  - `CjguiInternalAppRunRequest`
  - `CjguiInternalAppRunReport`
  - `CjguiInternalAppRunControllerRequest`
  - `CjguiInternalAppRunControllerDecision`
  - `CjguiInternalAppRunControllerReport`
  - `CjguiInternalAppRunExecutionPlanRequest`
  - `CjguiInternalAppRunExecutionPlan`
  - `CjguiInternalAppRunExecutionPlanReport`
  - `CjguiInternalAppRunDispatchRequest`
  - `CjguiInternalAppRunDispatchSummary`
  - `CjguiInternalAppRunDispatchReport`
  - `CjguiInternalRunLoopDraftRequest`
  - `CjguiInternalRunLoopDraftIntent`
  - `CjguiInternalRunLoopDraftReport`
  - `CjguiInternalLoopIterationDraftRequest`
  - `CjguiInternalLoopIterationDraftIntent`
  - `CjguiInternalLoopIterationDraftReport`
  - `CjguiInternalIterationWorkPacketDraftRequest`
  - `CjguiInternalIterationWorkPacketDraft`
  - `CjguiInternalIterationWorkPacketDraftReport`
  - `CjguiInternalLifecycleWorkDraftRequest`
  - `CjguiInternalLifecycleWorkDraft`
  - `CjguiInternalLifecycleWorkDraftReport`
  - `CjguiInternalLifecycleOwnerHandoffRequest`
  - `CjguiInternalLifecycleOwnerHandoffReport`
  - `CjguiInternalLifecycleMutationReadinessRequest`
  - `CjguiInternalLifecycleMutationReadinessReport`
  - `CjguiInternalLifecycleMutationPlanRequest`
  - `CjguiInternalLifecycleMutationPlanReport`
  - `CjguiInternalLifecycleMutationCommitGateRequest`
  - `CjguiInternalLifecycleMutationCommitGateReport`
  - `CjguiInternalLifecycleMutationApplyRequest`
  - `CjguiInternalLifecycleMutationApplyReport`
  - `CjguiInternalLifecycleStateMutationRequest`
  - `CjguiInternalLifecycleStateMutationReport`
  - `CjguiInternalLifecycleStateMutationOutcomeRequest`
  - `CjguiInternalLifecycleStateMutationOutcomeReport`
  - `CjguiInternalLifecycleMutatedStatePublicationRequest`
  - `CjguiInternalLifecycleMutatedStatePublicationReport`
  - `CjguiInternalRuntimeStateCarryForwardRequest`
  - `CjguiInternalRuntimeStateCarryForwardReport`
  - `CjguiInternalRuntimeCarriedStateContainerRequest`
  - `CjguiInternalRuntimeCarriedStateContainer`
  - `CjguiInternalRuntimeStateHolderRequest`
  - `CjguiInternalRuntimeStateHolderDraft`
  - `CjguiInternalRuntimeCommittedStateStoreRequest`
  - `CjguiInternalRuntimeCommittedStateStoreDraft`
  - `CjguiInternalRuntimeCycleFeedbackRequest`
  - `CjguiInternalRuntimeCycleFeedbackDraft`
  - `CjguiInternalRuntimeNextCycleRequestDraftRequest`
  - `CjguiInternalRuntimeNextCycleRequestDraft`
  - `CjguiInternalRuntimeCycleHandoffRequest`
  - `CjguiInternalRuntimeCycleHandoffDraft`
  - `CjguiInternalRuntimeCycleReplayRequest`
  - `CjguiInternalRuntimeCycleReplayDraft`
  - `CjguiInternalRuntimeReplayOutcomeRequest`
  - `CjguiInternalRuntimeReplayOutcomeReport`
  - `cjguiInternalBuildRuntimeRootState`
  - `cjguiInternalRuntimeRootStateReadySanity`
  - `cjguiInternalRuntimeStep`
  - `cjguiInternalRuntimeStepReadySanity`
  - `cjguiInternalDefaultRuntimeStepInput`
  - `cjguiInternalDefaultRuntimeStepPolicy`
  - `cjguiInternalDecideRuntimeStep`
  - `cjguiInternalRuntimeStepWithInput`
  - `cjguiInternalDefaultRuntimeCycleRequest`
  - `cjguiInternalExecuteRuntimeCycle`
  - `cjguiInternalRuntimeStepInputPolicyReadySanity`
  - `cjguiInternalRuntimeStepInputPolicyNotReadyBlockedSanity`
  - `cjguiInternalRuntimeStepInputPolicyInputBlockedSanity`
  - `cjguiInternalRuntimeStepReadyOutcomeSanity`
  - `cjguiInternalRuntimeStepBlockedOutcomeSanity`
  - `cjguiInternalRuntimeCycleReadySanity`
  - `cjguiInternalRuntimeCycleNotReadyBlockedSanity`
  - `cjguiInternalRuntimeCycleInputBlockedSanity`
  - `cjguiInternalRuntimeCycleProgressReadySanity`
  - `cjguiInternalRuntimeCycleProgressBlockedSanity`
  - `cjguiInternalBuildRuntimeCommandDraft`
  - `cjguiInternalExecuteRuntimeCycleDraftCommand`
  - `cjguiInternalDefaultRuntimeCommandPipelineRequest`
  - `cjguiInternalExecuteRuntimeCommandPipeline`
  - `cjguiInternalExecuteDefaultRuntimeCommandPipeline`
  - `cjguiInternalDefaultRuntimeDriverRequest`
  - `cjguiInternalExecuteRuntimeDriverPass`
  - `cjguiInternalExecuteDefaultRuntimeDriverPass`
  - `cjguiInternalDefaultRuntimeDriverInput`
  - `cjguiInternalDefaultRuntimeDriverPolicy`
  - `cjguiInternalDecideRuntimeDriverPass`
  - `cjguiInternalExecuteRuntimeDriverPassWithInput`
  - `cjguiInternalBuildRuntimeDriverReport`
  - `cjguiInternalExecuteRuntimeDriverPassReport`
  - `cjguiInternalExecuteDefaultRuntimeDriverPassReport`
  - `cjguiInternalBuildRuntimeRunIntent`
  - `cjguiInternalExecuteRuntimeRunIntentDraft`
  - `cjguiInternalExecuteDefaultRuntimeRunIntentDraft`
  - `cjguiInternalBuildRuntimeRunRequest`
  - `cjguiInternalEvaluateRuntimeRunRequest`
  - `cjguiInternalExecuteRuntimeRunRequestDraft`
  - `cjguiInternalExecuteDefaultRuntimeRunRequestDraft`
  - `cjguiInternalDefaultRuntimeShutdownIntent`
  - `cjguiInternalBuildRuntimeShutdownIntent`
  - `cjguiInternalBuildRuntimeShutdownRequest`
  - `cjguiInternalEvaluateRuntimeShutdownRequest`
  - `cjguiInternalBuildRunBoundaryRequest`
  - `cjguiInternalEvaluateRunBoundaryRequest`
  - `cjguiInternalExecuteRunBoundaryDraft`
  - `cjguiInternalExecuteDefaultRunBoundaryDraft`
  - `cjguiInternalBuildAppRunState`
  - `cjguiInternalBuildAppRunRequest`
  - `cjguiInternalEvaluateAppRunRequest`
  - `cjguiInternalExecuteAppRunSurfaceDraft`
  - `cjguiInternalExecuteDefaultAppRunSurfaceDraft`
  - `cjguiInternalBuildAppRunControllerRequest`
  - `cjguiInternalDecideAppRunController`
  - `cjguiInternalEvaluateAppRunController`
  - `cjguiInternalExecuteAppRunControllerDraft`
  - `cjguiInternalExecuteDefaultAppRunControllerDraft`
  - `cjguiInternalBuildAppRunExecutionPlanRequest`
  - `cjguiInternalBuildAppRunExecutionPlan`
  - `cjguiInternalEvaluateAppRunExecutionPlan`
  - `cjguiInternalExecuteAppRunExecutionPlanDraft`
  - `cjguiInternalExecuteDefaultAppRunExecutionPlanDraft`
  - `cjguiInternalBuildAppRunDispatchRequest`
  - `cjguiInternalBuildAppRunDispatchSummary`
  - `cjguiInternalEvaluateAppRunDispatch`
  - `cjguiInternalExecuteAppRunDispatchDraft`
  - `cjguiInternalExecuteDefaultAppRunDispatchDraft`
  - `cjguiInternalBuildRunLoopDraftRequest`
  - `cjguiInternalBuildRunLoopDraftIntent`
  - `cjguiInternalEvaluateRunLoopDraft`
  - `cjguiInternalExecuteRunLoopDraft`
  - `cjguiInternalExecuteDefaultRunLoopDraft`
  - `cjguiInternalBuildLoopIterationDraftRequest`
  - `cjguiInternalBuildLoopIterationDraftIntent`
  - `cjguiInternalEvaluateLoopIterationDraft`
  - `cjguiInternalExecuteLoopIterationDraft`
  - `cjguiInternalExecuteDefaultLoopIterationDraft`
  - `cjguiInternalBuildIterationWorkPacketDraftRequest`
  - `cjguiInternalBuildIterationWorkPacketDraft`
  - `cjguiInternalEvaluateIterationWorkPacketDraft`
  - `cjguiInternalExecuteIterationWorkPacketDraft`
  - `cjguiInternalExecuteDefaultIterationWorkPacketDraft`
  - `cjguiInternalBuildLifecycleWorkDraftRequest`
  - `cjguiInternalBuildLifecycleWorkDraft`
  - `cjguiInternalEvaluateLifecycleWorkDraft`
  - `cjguiInternalExecuteLifecycleWorkDraft`
  - `cjguiInternalExecuteDefaultLifecycleWorkDraft`
  - `cjguiInternalBuildLifecycleOwnerHandoffRequest`
  - `cjguiInternalEvaluateLifecycleOwnerHandoff`
  - `cjguiInternalExecuteLifecycleOwnerHandoffDraft`
  - `cjguiInternalExecuteDefaultLifecycleOwnerHandoffDraft`
  - `cjguiInternalBuildLifecycleMutationReadinessRequest`
  - `cjguiInternalEvaluateLifecycleMutationReadiness`
  - `cjguiInternalExecuteLifecycleMutationReadinessDraft`
  - `cjguiInternalExecuteDefaultLifecycleMutationReadinessDraft`
  - `cjguiInternalBuildLifecycleMutationPlanRequest`
  - `cjguiInternalEvaluateLifecycleMutationPlan`
  - `cjguiInternalExecuteLifecycleMutationPlanDraft`
  - `cjguiInternalExecuteDefaultLifecycleMutationPlanDraft`
  - `cjguiInternalBuildLifecycleMutationCommitGateRequest`
  - `cjguiInternalEvaluateLifecycleMutationCommitGate`
  - `cjguiInternalExecuteLifecycleMutationCommitGateDraft`
  - `cjguiInternalExecuteDefaultLifecycleMutationCommitGateDraft`
  - `cjguiInternalBuildLifecycleMutationApplyRequest`
  - `cjguiInternalEvaluateLifecycleMutationApply`
  - `cjguiInternalExecuteLifecycleMutationApplyDraft`
  - `cjguiInternalExecuteDefaultLifecycleMutationApplyDraft`
  - `cjguiInternalBuildLifecycleStateMutationRequest`
  - `cjguiInternalEvaluateLifecycleStateMutation`
  - `cjguiInternalExecuteLifecycleStateMutationDraft`
  - `cjguiInternalExecuteDefaultLifecycleStateMutationDraft`
  - `cjguiInternalBuildLifecycleStateMutationOutcomeRequest`
  - `cjguiInternalEvaluateLifecycleStateMutationOutcome`
  - `cjguiInternalLifecycleStateMutationOutcomeDidMutateBothOwners`
  - `cjguiInternalExecuteLifecycleStateMutationOutcomeDraft`
  - `cjguiInternalExecuteDefaultLifecycleStateMutationOutcomeDraft`
  - `cjguiInternalBuildLifecycleMutatedStatePublicationRequest`
  - `cjguiInternalEvaluateLifecycleMutatedStatePublication`
  - `cjguiInternalExecuteLifecycleMutatedStatePublicationDraft`
  - `cjguiInternalExecuteDefaultLifecycleMutatedStatePublicationDraft`
  - `cjguiInternalBuildRuntimeStateCarryForwardRequest`
  - `cjguiInternalEvaluateRuntimeStateCarryForward`
  - `cjguiInternalExecuteRuntimeStateCarryForwardDraft`
  - `cjguiInternalExecuteDefaultRuntimeStateCarryForwardDraft`
  - `cjguiInternalBuildRuntimeCarriedStateContainerRequest`
  - `cjguiInternalEvaluateRuntimeCarriedStateContainer`
  - `cjguiInternalExecuteRuntimeCarriedStateContainerDraft`
  - `cjguiInternalExecuteDefaultRuntimeCarriedStateContainerDraft`
  - `cjguiInternalBuildRuntimeStateHolderRequest`
  - `cjguiInternalEvaluateRuntimeStateHolder`
  - `cjguiInternalExecuteRuntimeStateHolderDraft`
  - `cjguiInternalExecuteDefaultRuntimeStateHolderDraft`
  - `cjguiInternalBuildRuntimeCommittedStateStoreRequest`
  - `cjguiInternalEvaluateRuntimeCommittedStateStore`
  - `cjguiInternalExecuteRuntimeCommittedStateStoreDraft`
  - `cjguiInternalExecuteDefaultRuntimeCommittedStateStoreDraft`
  - `cjguiInternalBuildRuntimeCycleFeedbackRequest`
  - `cjguiInternalEvaluateRuntimeCycleFeedback`
  - `cjguiInternalExecuteRuntimeCycleFeedbackDraft`
  - `cjguiInternalExecuteDefaultRuntimeCycleFeedbackDraft`
  - `cjguiInternalBuildRuntimeNextCycleRequestDraftRequest`
  - `cjguiInternalEvaluateRuntimeNextCycleRequestDraft`
  - `cjguiInternalExecuteRuntimeNextCycleRequestDraft`
  - `cjguiInternalExecuteDefaultRuntimeNextCycleRequestDraft`
  - `cjguiInternalBuildRuntimeCycleHandoffRequest`
  - `cjguiInternalEvaluateRuntimeCycleHandoff`
  - `cjguiInternalExecuteRuntimeCycleHandoffDraft`
  - `cjguiInternalExecuteDefaultRuntimeCycleHandoffDraft`
  - `cjguiInternalBuildRuntimeCycleReplayRequest`
  - `cjguiInternalEvaluateRuntimeCycleReplay`
  - `cjguiInternalExecuteRuntimeCycleReplayDraft`
  - `cjguiInternalExecuteDefaultRuntimeCycleReplayDraft`
  - `cjguiInternalBuildRuntimeReplayOutcomeRequest`
  - `cjguiInternalEvaluateRuntimeReplayOutcome`
  - `cjguiInternalExecuteRuntimeReplayOutcomeDraft`
  - `cjguiInternalExecuteDefaultRuntimeReplayOutcomeDraft`
  - `cjguiInternalRuntimeCommandDraftReadySanity`
  - `cjguiInternalRuntimeCommandDraftNotReadyBlockedSanity`
  - `cjguiInternalRuntimeCommandDraftInputBlockedSanity`
  - `cjguiInternalRuntimeCommandPipelineReadySanity`
  - `cjguiInternalRuntimeCommandPipelineNotReadyBlockedSanity`
  - `cjguiInternalRuntimeCommandPipelineInputBlockedSanity`
  - `cjguiInternalRuntimeDriverReadySanity`
  - `cjguiInternalRuntimeDriverNotReadyBlockedSanity`
  - `cjguiInternalRuntimeDriverInputBlockedSanity`
  - `cjguiInternalRuntimeDriverInputPolicyReadySanity`
  - `cjguiInternalRuntimeDriverInputPolicyRuntimeBlockedSanity`
  - `cjguiInternalRuntimeDriverInputPolicyInputBlockedSanity`
  - `cjguiInternalRuntimeDriverReportReadySanity`
  - `cjguiInternalRuntimeDriverReportRuntimeBlockedSanity`
  - `cjguiInternalRuntimeDriverReportInputBlockedSanity`
  - `cjguiInternalRuntimeRunIntentReadySanity`
  - `cjguiInternalRuntimeRunIntentRuntimeBlockedSanity`
  - `cjguiInternalRuntimeRunIntentInputBlockedSanity`
  - `cjguiInternalRuntimeRunRequestReadySanity`
  - `cjguiInternalRuntimeRunRequestRuntimeBlockedSanity`
  - `cjguiInternalRuntimeRunRequestInputBlockedSanity`
  - `cjguiInternalRuntimeShutdownIdleSanity`
  - `cjguiInternalRuntimeShutdownRequestedSanity`
  - `cjguiInternalRuntimeCancellationRequestedSanity`
  - `cjguiInternalRuntimeShutdownAndCancellationRequestedSanity`
  - `cjguiInternalRunBoundaryOpenSanity`
  - `cjguiInternalRunBoundaryRuntimeBlockedSanity`
  - `cjguiInternalRunBoundaryInputBlockedSanity`
  - `cjguiInternalRunBoundaryShutdownBlockedSanity`
  - `cjguiInternalRunBoundaryCancellationBlockedSanity`
  - `cjguiInternalAppRunSurfaceOpenSanity`
  - `cjguiInternalAppRunSurfaceRuntimeBlockedSanity`
  - `cjguiInternalAppRunSurfaceInputBlockedSanity`
  - `cjguiInternalAppRunSurfaceShutdownBlockedSanity`
  - `cjguiInternalAppRunSurfaceCancellationBlockedSanity`
  - `cjguiInternalAppRunControllerOpenSanity`
  - `cjguiInternalAppRunControllerRuntimeBlockedSanity`
  - `cjguiInternalAppRunControllerInputBlockedSanity`
  - `cjguiInternalAppRunControllerShutdownBlockedSanity`
  - `cjguiInternalAppRunControllerCancellationBlockedSanity`
  - `cjguiInternalAppRunExecutionPlanOpenSanity`
  - `cjguiInternalAppRunExecutionPlanRuntimeBlockedSanity`
  - `cjguiInternalAppRunExecutionPlanInputBlockedSanity`
  - `cjguiInternalAppRunExecutionPlanShutdownBlockedSanity`
  - `cjguiInternalAppRunExecutionPlanCancellationBlockedSanity`
  - `cjguiInternalAppRunDispatchOpenSanity`
  - `cjguiInternalAppRunDispatchRuntimeBlockedSanity`
  - `cjguiInternalAppRunDispatchInputBlockedSanity`
  - `cjguiInternalAppRunDispatchShutdownBlockedSanity`
  - `cjguiInternalAppRunDispatchCancellationBlockedSanity`
  - `cjguiInternalRunLoopDraftOpenSanity`
  - `cjguiInternalRunLoopDraftRuntimeBlockedSanity`
  - `cjguiInternalRunLoopDraftInputBlockedSanity`
  - `cjguiInternalRunLoopDraftShutdownBlockedSanity`
  - `cjguiInternalRunLoopDraftCancellationBlockedSanity`
  - `cjguiInternalLoopIterationDraftOpenSanity`
  - `cjguiInternalLoopIterationDraftRuntimeBlockedSanity`
  - `cjguiInternalLoopIterationDraftInputBlockedSanity`
  - `cjguiInternalLoopIterationDraftShutdownBlockedSanity`
  - `cjguiInternalLoopIterationDraftCancellationBlockedSanity`
  - `cjguiInternalIterationWorkPacketDraftOpenSanity`
  - `cjguiInternalIterationWorkPacketDraftRuntimeBlockedSanity`
  - `cjguiInternalIterationWorkPacketDraftInputBlockedSanity`
  - `cjguiInternalIterationWorkPacketDraftShutdownBlockedSanity`
  - `cjguiInternalIterationWorkPacketDraftCancellationBlockedSanity`
  - `cjguiInternalLifecycleWorkDraftOpenSanity`
  - `cjguiInternalLifecycleWorkDraftRuntimeBlockedSanity`
  - `cjguiInternalLifecycleWorkDraftInputBlockedSanity`
  - `cjguiInternalLifecycleWorkDraftShutdownBlockedSanity`
  - `cjguiInternalLifecycleWorkDraftCancellationBlockedSanity`
  - `cjguiInternalLifecycleOwnerHandoffOpenSanity`
  - `cjguiInternalLifecycleOwnerHandoffRuntimeBlockedSanity`
  - `cjguiInternalLifecycleOwnerHandoffInputBlockedSanity`
  - `cjguiInternalLifecycleOwnerHandoffShutdownBlockedSanity`
  - `cjguiInternalLifecycleOwnerHandoffCancellationBlockedSanity`
  - `cjguiInternalLifecycleMutationReadinessOpenSanity`
  - `cjguiInternalLifecycleMutationReadinessRuntimeBlockedSanity`
  - `cjguiInternalLifecycleMutationReadinessInputBlockedSanity`
  - `cjguiInternalLifecycleMutationReadinessShutdownBlockedSanity`
  - `cjguiInternalLifecycleMutationReadinessCancellationBlockedSanity`
  - `cjguiInternalLifecycleMutationPlanOpenSanity`
  - `cjguiInternalLifecycleMutationPlanRuntimeBlockedSanity`
  - `cjguiInternalLifecycleMutationPlanInputBlockedSanity`
  - `cjguiInternalLifecycleMutationPlanShutdownBlockedSanity`
  - `cjguiInternalLifecycleMutationPlanCancellationBlockedSanity`
  - `cjguiInternalLifecycleMutationCommitGateOpenSanity`
  - `cjguiInternalLifecycleMutationCommitGateRuntimeBlockedSanity`
  - `cjguiInternalLifecycleMutationCommitGateInputBlockedSanity`
  - `cjguiInternalLifecycleMutationCommitGateShutdownBlockedSanity`
  - `cjguiInternalLifecycleMutationCommitGateCancellationBlockedSanity`
  - `cjguiInternalLifecycleMutationApplyOpenSanity`
  - `cjguiInternalLifecycleMutationApplyRuntimeBlockedSanity`
  - `cjguiInternalLifecycleMutationApplyInputBlockedSanity`
  - `cjguiInternalLifecycleMutationApplyShutdownBlockedSanity`
  - `cjguiInternalLifecycleMutationApplyCancellationBlockedSanity`
  - `cjguiInternalLifecycleStateMutationOpenSanity`
  - `cjguiInternalLifecycleStateMutationRuntimeBlockedSanity`
  - `cjguiInternalLifecycleStateMutationInputBlockedSanity`
  - `cjguiInternalLifecycleStateMutationShutdownBlockedSanity`
  - `cjguiInternalLifecycleStateMutationCancellationBlockedSanity`
  - `cjguiInternalLifecycleStateMutationOutcomeOpenSanity`
  - `cjguiInternalLifecycleStateMutationOutcomeRuntimeBlockedSanity`
  - `cjguiInternalLifecycleStateMutationOutcomeInputBlockedSanity`
  - `cjguiInternalLifecycleStateMutationOutcomeShutdownBlockedSanity`
  - `cjguiInternalLifecycleStateMutationOutcomeCancellationBlockedSanity`
  - `cjguiInternalLifecycleMutatedStatePublicationOpenSanity`
  - `cjguiInternalLifecycleMutatedStatePublicationRuntimeBlockedSanity`
  - `cjguiInternalLifecycleMutatedStatePublicationInputBlockedSanity`
  - `cjguiInternalLifecycleMutatedStatePublicationShutdownBlockedSanity`
  - `cjguiInternalLifecycleMutatedStatePublicationCancellationBlockedSanity`
  - `cjguiInternalRuntimeStateCarryForwardOpenSanity`
  - `cjguiInternalRuntimeStateCarryForwardRuntimeBlockedSanity`
  - `cjguiInternalRuntimeStateCarryForwardInputBlockedSanity`
  - `cjguiInternalRuntimeStateCarryForwardShutdownBlockedSanity`
  - `cjguiInternalRuntimeStateCarryForwardCancellationBlockedSanity`
  - `cjguiInternalRuntimeCarriedStateContainerOpenSanity`
  - `cjguiInternalRuntimeCarriedStateContainerRuntimeBlockedSanity`
  - `cjguiInternalRuntimeCarriedStateContainerInputBlockedSanity`
  - `cjguiInternalRuntimeCarriedStateContainerShutdownBlockedSanity`
  - `cjguiInternalRuntimeCarriedStateContainerCancellationBlockedSanity`
  - `cjguiInternalRuntimeStateHolderOpenSanity`
  - `cjguiInternalRuntimeStateHolderRuntimeBlockedSanity`
  - `cjguiInternalRuntimeStateHolderInputBlockedSanity`
  - `cjguiInternalRuntimeStateHolderShutdownBlockedSanity`
  - `cjguiInternalRuntimeStateHolderCancellationBlockedSanity`
  - `cjguiInternalRuntimeCommittedStateStoreOpenSanity`
  - `cjguiInternalRuntimeCommittedStateStoreRuntimeBlockedSanity`
  - `cjguiInternalRuntimeCommittedStateStoreInputBlockedSanity`
  - `cjguiInternalRuntimeCommittedStateStoreShutdownBlockedSanity`
  - `cjguiInternalRuntimeCommittedStateStoreCancellationBlockedSanity`
  - `cjguiInternalRuntimeCycleFeedbackOpenSanity`
  - `cjguiInternalRuntimeCycleFeedbackRuntimeBlockedSanity`
  - `cjguiInternalRuntimeCycleFeedbackInputBlockedSanity`
  - `cjguiInternalRuntimeCycleFeedbackShutdownBlockedSanity`
  - `cjguiInternalRuntimeCycleFeedbackCancellationBlockedSanity`
  - `cjguiInternalRuntimeNextCycleRequestOpenSanity`
  - `cjguiInternalRuntimeNextCycleRequestRuntimeBlockedSanity`
  - `cjguiInternalRuntimeNextCycleRequestInputBlockedSanity`
  - `cjguiInternalRuntimeNextCycleRequestShutdownBlockedSanity`
  - `cjguiInternalRuntimeNextCycleRequestCancellationBlockedSanity`
  - `cjguiInternalRuntimeCycleHandoffOpenSanity`
  - `cjguiInternalRuntimeCycleHandoffRuntimeBlockedSanity`
  - `cjguiInternalRuntimeCycleHandoffInputBlockedSanity`
  - `cjguiInternalRuntimeCycleHandoffShutdownBlockedSanity`
  - `cjguiInternalRuntimeCycleHandoffCancellationBlockedSanity`
  - `cjguiInternalRuntimeCycleReplayOpenSanity`
  - `cjguiInternalRuntimeCycleReplayRuntimeBlockedSanity`
  - `cjguiInternalRuntimeCycleReplayInputBlockedSanity`
  - `cjguiInternalRuntimeCycleReplayShutdownBlockedSanity`
  - `cjguiInternalRuntimeCycleReplayCancellationBlockedSanity`
  - `cjguiInternalRuntimeReplayOutcomeOpenSanity`
  - `cjguiInternalRuntimeReplayOutcomeRuntimeBlockedSanity`
  - `cjguiInternalRuntimeReplayOutcomeInputBlockedSanity`
  - `cjguiInternalRuntimeReplayOutcomeShutdownBlockedSanity`
  - `cjguiInternalRuntimeReplayOutcomeCancellationBlockedSanity`
- `src/error.cj`
  - `CjguiInternalCompileSanityMarker`
  - `CjguiInternalErrorFact`
  - `CjguiInternalErrorTaxonomyMarker`

当前已落地的最小脱水形状如下：

- app lifecycle state: `isStateMachineActive: Bool`、`hasLifecyclePhase: Bool`、`hasObservedPlatformReady: Bool`
- window lifecycle state: `hasWindowState: Bool`、`hasObservedPlatformReady: Bool`
- platform adapter fact: `isPlatformReady: Bool`
- error fact: `hasNativePayload: Bool = false`

当前 app/window lifecycle 各有一个默认 internal readiness predicate helper，只读取 `hasObservedPlatformReady`，不改变 state shape、constructor shape 或 projection behavior。platform adapter 另有默认 internal coordination readiness sanity helpers：positive helper 复用既有 sanity 链路并确认 app/window 都观察到 platform readiness；negative helper 使用 `isPlatformReady=false` 的 fact 确认默认 app/window 不会被标记为 observed platform ready；parity helper 同时确认 positive / negative sanity 都成立。`src/runtime_bootstrap.cj` 是默认 internal bootstrap owner 文件，承载 runtime readiness aggregate type / builder 与 bootstrap snapshot type / builder；它只聚合 app/window readiness coordination summary 与 bootstrap readiness Bool，不拥有 app/window state truth，也不实现 runtime 启动行为。`src/runtime_state.cj` 是默认 internal runtime root state owner 文件，只聚合 bootstrap snapshot 与 runtime readiness Bool；其 step result 聚合 root state、didAdvance Bool 与最小 blocked outcome，step input / policy / decision 只表达 internal step gate、policy 与脱水 decision summary，step-with-input-policy 只根据 decision 返回原 state 与 didAdvance / blocked outcome，cycle request / result 只组合一次 root state、step input、step policy、decision、step result 与 internal cycle progress marker，command draft 只表达一次 cycle 后的 internal runtime intent summary，command pipeline 只把 cycle request、cycle result 与 command draft 串成 internal summary pipeline，driver draft 只组织一次 pipeline pass 并投影 driver-level summary，driver input / policy / decision 只作为 driver pass 的脱水 gate，driver pass with input 只在 gate 允许时复用既有 pipeline pass，driver report 只把 driver result 规整成 internal next-action summary，run intent 只把 driver report 投影为 internal run-boundary intent summary，run request 只把 run intent 包装并评估为 internal request summary，shutdown / cancellation intent 只表达退出方向的 internal 脱水意图与 defer-run 影响，run boundary draft 只聚合 run request report 与 shutdown report 并判断 boundary open / deferred / blocked，app run surface 只消费 run boundary report 并投影为脱水 AppRun state/request/report summary，app run controller draft 只消费 AppRun report 并派生 accepted / deferred / blocked / future-boundary next-action summary，app run execution plan draft 只消费 AppRun controller report 并投影 future execution phases 的脱水 plan summary，app run dispatch draft 只消费 AppRun execution plan report 并投影 dispatch-facing 脱水 summary，run loop draft 只消费 AppRun dispatch report 并投影 loop-intent 脱水 summary，ready / blocked sanity helpers 只验证 default advance、not-ready fail-closed、input-blocked fail-closed、outcome 字段一致性、一次 cycle request/result 一致性、progress marker 一致性、command draft intent summary 一致性、pipeline summary 一致性、driver summary pass 一致性、driver input/policy gate 一致性、driver report projection 一致性、run intent projection 一致性、run request evaluation 一致性、shutdown/cancellation intent evaluation 一致性、run boundary readiness 一致性、AppRun surface projection 一致性、AppRun controller decision projection 一致性、AppRun execution plan projection 一致性、AppRun dispatch projection 一致性与 RunLoopDraft intent projection 一致性，并不定义 runtime state machine、event loop、queue / drain、frame/render/layout progress、renderer command list、run behavior 或真实 shutdown behavior。

当前边界如下：

- 所有非 `package cjgui` 声明均保持默认 `internal`。
- 允许最小 `struct`、最小构造初始化、最小 no-op / marker transition 和最小 coordination 函数形状。
- 不提供 public runtime API。
- 不提供 public C ABI。
- 不实现真实 app run / request quit / shutdown / queue / drain。
- 不实现真实 window create / request close / destroy / release。
- 不实现真实 platform adapter / event loop / callback binding。
- 不实现完整 error strategy、error enum、`Result` type 或 exception-like mechanism。
- 不暴露 platform object、native handle、raw pointer 或 platform truth public surface。

## App Lifecycle Owner

未来 app lifecycle owner 属于正式 runtime core 的 app lifecycle 模块。当前 `src/app_lifecycle.cj` 只定义内部 state、transition marker、phase taxonomy marker，以及两个最小 transition 函数。

边界如下：

- app lifecycle 是未来 app-level state、request quit、shutdown、queue acceptance 和 main-thread queue / drain policy 的概念 owner。
- platform adapter 未来可以发送脱水 lifecycle facts 驱动 app lifecycle，但不得把 runloop truth、callback ownership 或 native handle 编码成 core truth。
- `run`、`request quit`、`shutdown`、queue / drain 仍只是 future slot；当前没有真实行为。
- app lifecycle 不默认引入 global tick、blind redraw、Dirty Rect 或 frame scheduler。
- app lifecycle 不打开 Text / Input / IME / Accessibility、semantic tree 或 Action Router。

## Window Lifecycle Owner

未来 window lifecycle owner 属于正式 runtime core 的 window lifecycle 模块。当前 `src/window_lifecycle.cj` 只定义内部 state、最小 no-op transition 和最小 state marker transition。

边界如下：

- window lifecycle 是未来 window-target state、request close、destroyed / stale target classification 的概念 owner。
- app lifecycle 仍是 app-level queue acceptance、shutdown policy 和 main-thread queue / drain policy 的概念 owner。
- platform adapter 仍是平台对象、平台 close event、平台 release 事实和平台 runloop callback 的 owner。
- `create window`、`request close`、`destroy`、`release` 仍只是 future slot；当前不实现。
- request close 未来应经过 app lifecycle queue acceptance 与 platform-adapter main-thread drain 后再推进 window state。
- handle table / generation 现在保持关闭；只有出现 public handle、多窗口、target update、async UI message targeting、destroyed-target identity reuse 或跨线程 target validation 时才应另开边界。
- destroyed window state 必须是 terminal；stale close / stale message 不得复活窗口。

## Platform Adapter / Core Boundary

当前 `src/platform_adapter.cj` 已经承载默认 internal 的 readiness fact shape、最小 no-op ingestion、platform readiness fact 到 app/window lifecycle 的投影、最小 lifecycle coordination 结果与入口，以及默认 internal sanity 调用。它仍不是正式 platform adapter implementation。

边界如下：

- platform adapter 未来负责平台 event loop、platform callback、平台对象生命周期以及 platform readiness / failure 事实。
- core runtime 只应消费脱水 facts，不应消费平台对象、raw event object、runloop truth 或 callback ownership。
- app lifecycle 可在未来消费 adapter 发出的脱水 app facts，例如 readiness、failure、queue drain request、quit request、shutdown observed。
- window lifecycle 可在未来消费 adapter 发出的脱水 window facts，例如 create observed、close requested、visibility summary、destroyed、release completed、stale message。
- `NSRunLoop`、`NSEvent`、`dispatch_main`、AppKit / Metal / CoreGraphics / Objective-C 对象、native handle、raw pointer 只能作为 adapter-internal truth 或 README 中的禁止事项出现。
- platform adapter boundary 不意味着默认 global tick、blind redraw、frame scheduler、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree、Action Router、command-list hash、pixel diff、baseline 或 offscreen renderer 已打开。

## Runtime Bootstrap Owner

当前 `src/runtime_bootstrap.cj` 承载默认 internal runtime readiness aggregate 与 bootstrap snapshot owner symbols。它只组合既有 coordination sanity 与 readiness parity summary，不拥有 app lifecycle truth、window lifecycle truth 或 platform object truth。

边界如下：

- readiness aggregate 只聚合 app/window state 与 readiness parity Bool。
- bootstrap snapshot 只聚合 readiness aggregate 与 `isBootstrapReady` Bool。
- builder 只复用现有 internal coordination sanity helper，不改变 projection / coordination behavior。
- 当前不实现 app run、event loop、callback binding、queue / drain、window create、shutdown 或真实 runtime behavior。
- 当前不新增 public runtime API、public C ABI、platform object、native handle 或 raw pointer。

## Runtime Root State Owner

当前 `src/runtime_state.cj` 承载默认 internal runtime root state summary。它只聚合 bootstrap snapshot 与 `isRuntimeReady` Bool，不拥有 app lifecycle truth、window lifecycle truth 或 platform object truth。

边界如下：

- root state 只持有 `bootstrap: CjguiInternalRuntimeBootstrapSnapshot` 与 `isRuntimeReady: Bool`。
- root state builder 只调用 `cjguiInternalBuildRuntimeBootstrapSnapshot()`，并用 `bootstrap.isBootstrapReady` 作为 `isRuntimeReady`。
- root ready sanity helper 只调用 `cjguiInternalBuildRuntimeRootState()` 并返回 `root.isRuntimeReady`。
- runtime step result 只持有 `state: CjguiInternalRuntimeRootState`、`didAdvance: Bool`、`isBlocked: Bool`、`isBlockedByRuntimeNotReady: Bool` 与 `isBlockedByInput: Bool`。
- runtime step function 只返回原 state，并把 `state.isRuntimeReady` 映射为 `didAdvance` 与 runtime-not-ready blocked outcome。
- runtime step ready sanity helper 只调用 root state builder 与 runtime step，并返回 `step.didAdvance`。
- runtime step input 只持有 `allowsAdvance: Bool` 与 `hasExternalWork: Bool`；`hasExternalWork` 只是脱水 marker，不代表真实 queue、event loop 或 platform callback。
- runtime step policy 只持有 `requiresRuntimeReady: Bool` 与 `requiresInputAllowsAdvance: Bool`。
- runtime step decision 只持有 `shouldAdvance: Bool`、`isBlockedByRuntimeNotReady: Bool` 与 `isBlockedByInput: Bool`。
- runtime step-with-input-policy 只调用 decision function，返回原 state，并用 `decision.shouldAdvance` 与 blocker facts 形成 step result outcome。
- step input / policy sanity helpers 只覆盖 default advance、not-ready blocked 与 input-blocked 三条 internal path。
- step outcome sanity helpers 只覆盖 ready outcome 与 blocked outcome 字段一致性。
- runtime cycle request 只持有 `state: CjguiInternalRuntimeRootState`、`input: CjguiInternalRuntimeStepInput` 与 `policy: CjguiInternalRuntimeStepPolicy`。
- runtime cycle result 只持有 `request: CjguiInternalRuntimeCycleRequest`、`step: CjguiInternalRuntimeStepResult`、`decision: CjguiInternalRuntimeStepDecision` 与 `didProduceProgress: Bool`。
- default runtime cycle request 只组合 root state builder、default step input 与 default step policy。
- runtime cycle executor 只用 request 运行一次 decision 与 step-with-input-policy，返回 request / step / decision / progress summary；它用 `step.didAdvance` 派生 `didProduceProgress`，不改变 request state、不循环、不消费 queue 或 platform callback。
- runtime cycle sanity helpers 只覆盖 default ready、runtime-not-ready blocked、input-blocked 与 progress marker consistency。
- cycle progress 只是 internal cycle outcome marker，不是 frame progress、render progress、layout progress、event loop tick、queue drain 或 app run。
- runtime command draft 只持有 `shouldRequestNextCycle: Bool`、`shouldReportBlocked: Bool` 与 `didObserveProgress: Bool`。
- command draft builder 只从 cycle result 派生意图摘要：`didObserveProgress = cycle.didProduceProgress`、`shouldReportBlocked = cycle.step.isBlocked`、`shouldRequestNextCycle = cycle.didProduceProgress`。
- cycle draft command helper 只执行一次 internal cycle 并构造 command draft；它不创建 public command、不消费 queue、不触发 callback。
- command draft 不是 renderer command list、public runtime API、event loop task、queue item、platform callback 或 AppKit / Metal command。
- runtime command pipeline request 只包装一次 `CjguiInternalRuntimeCycleRequest`。
- runtime command pipeline result 只聚合 pipeline request、cycle result、command draft 与 `didCompletePipeline` Bool。
- runtime command pipeline executor 只串联一次 cycle executor 与 command draft builder；`didCompletePipeline=true` 只表示 internal summary 已生成，不代表真实 runtime run。
- runtime command pipeline 不是 public API、renderer command list、event loop、queue / drain、platform callback、AppKit / Metal command 或 app run。
- runtime driver request 只包装一次 `CjguiInternalRuntimeCommandPipelineRequest`。
- runtime driver result 只聚合 driver request、pipeline result，以及从 command draft 投影出的 `shouldRequestNextCycle`、`shouldReportBlocked`、`didObserveProgress` 与 `didCompleteDriverPass`。
- runtime driver pass executor 只组织一次 internal pipeline pass；`didCompleteDriverPass` 来自 `pipeline.didCompletePipeline`，不代表真实 runtime driver。
- runtime driver draft 不是 public API、event loop、queue / drain、platform callback、app run、window create、renderer command list 或 AppKit / Metal command。
- runtime driver input 只持有 `allowsDriverPass: Bool` 与 `hasExternalDriverWork: Bool`；后者只是脱水 marker，不代表 event queue、platform event、callback、render command 或 native task。
- runtime driver policy 只持有 `requiresRuntimeReady: Bool` 与 `requiresInputAllowsDriverPass: Bool`；它不是 scheduling policy、threading policy、queue drain policy 或 platform runloop policy。
- runtime driver decision 只持有 `shouldRunPipeline: Bool`、`isBlockedByRuntimeNotReady: Bool` 与 `isBlockedByInput: Bool`。
- runtime driver pass with input / policy 只在 decision 允许时复用既有 driver pass；blocked path 只返回 fail-closed summary，不执行 pipeline pass、不改变 root state、不消费 queue、不产生 platform callback。
- driver input / policy layer 只是 internal driver pass gate，不是 event loop、queue、scheduler、platform runloop、public API 或 public C ABI。
- runtime driver report 只持有原始 `CjguiInternalRuntimeDriverResult` 以及从 result 投影出的 `didCompleteDriverPass`、`shouldRequestNextCycle`、`shouldReportBlocked`、`didObserveProgress` 与 `isReadyForNextInternalPass`。
- driver report builder 只从 driver result 复制 / 派生字段；`isReadyForNextInternalPass` 等价于 `didCompleteDriverPass` 且 `shouldRequestNextCycle`。
- driver report executor 只组合 gated driver pass 与 report builder，不实现 scheduler、event loop、queue / drain、runloop policy、renderer command list 或真实 next action。
- runtime run intent 只持有 driver report，以及从 report 投影出的 `mayRequestRuntimeRun`、`shouldContinueInternalCycles`、`shouldSurfaceBlockedReport` 与 `didObserveInternalProgress`。
- run intent builder 只把 `mayRequestRuntimeRun` 派生为 `report.isReadyForNextInternalPass`，其余字段直接投影 driver report。
- run intent draft executor 只组合 driver pass report 与 run intent builder；它只是 internal run-boundary intent summary，不是 run loop、scheduler、queue item、event loop command 或 public runtime run API。
- runtime run request 只持有 run intent 与 `isRequestAllowed`，其中 `isRequestAllowed` 等价于 `intent.mayRequestRuntimeRun`。
- runtime run request report 只持有 request evaluation summary：`didAcceptRequest`、`shouldDeferRequest`、`shouldSurfaceBlockedReport` 与 `didObserveInternalProgress`。
- run request draft executor 只组合 run intent draft、run request builder 与 request evaluator；它不是 public `run()` 调用、event loop start、scheduler、queue item、platform callback 或 public runtime API。
- runtime shutdown intent 只持有 `shouldRequestShutdown: Bool` 与 `shouldRequestCancellation: Bool`，只表达 internal exit-direction intent summary。
- runtime shutdown request 只把 intent 包装为 `isShutdownRequested` 与 `isCancellationRequested` summary。
- runtime shutdown report 只表达 shutdown/cancel request 对 run request 的内部影响：`shouldDeferRunRequest`、`shouldEnterShutdownPath` 与 `shouldEnterCancellationPath`。
- shutdown / cancellation intent layer 不是真实 app shutdown、event loop stop、queue drain、platform close callback、task cancellation、public API 或 public C ABI。
- run boundary request 只聚合 `CjguiInternalRuntimeRunRequestReport` 与 `CjguiInternalRuntimeShutdownReport`。
- run boundary report 只持有 internal readiness summary：`isBoundaryOpen`、`isBoundaryDeferred`、`isBoundaryBlocked`、`isBlockedByRunRequest`、`isBlockedByShutdown` 与 `isBlockedByCancellation`。
- run boundary draft executor 只组合 run request draft 与 shutdown request evaluator；它不是真实 `run()`、event loop、queue / drain、scheduler、platform callback、public API 或 public C ABI。
- app run state 只持有 `CjguiInternalRunBoundaryReport` 与从 boundary report 投影出的 `isAppRunAllowed`、`isAppRunDeferred`、`isAppRunBlocked`。
- app run request 只包装 `CjguiInternalRunBoundaryReport`；它不是 public `run()` request 或 platform run request。
- app run report 只持有 request、state、`didAcceptAppRun`、`shouldDeferAppRun` 与 `shouldReportAppRunBlocked`。
- app run surface draft 只消费 run boundary report 并投影脱水 summary；它不执行 `run()`，不启动 event loop，不 drain queue，不调用平台，不绕过 run boundary 读取 lower-level readiness / platform / lifecycle facts。
- app run controller request 只包装 `CjguiInternalAppRunReport`；controller decision 只从 AppRun report 派生 accepted / deferred / blocked / future-boundary next-action summary；controller report 只表示 internal evaluation completed。
- app run controller draft 不执行 action，不启动 event loop，不 drain queue，不调用平台，也不绕过 AppRunReport 读取 RunBoundaryReport 或 lower-level readiness / platform / lifecycle facts。
- app run execution plan request 只包装 `CjguiInternalAppRunControllerReport`；execution plan 只从 controller decision 投影 `shouldPrepareRuntime`、`shouldEnterRunLoopDraft`、`shouldDeferExecution`、`shouldReportBlockedExecution` 与 `shouldRequestFutureBoundary`。
- app run execution plan draft 不执行 plan、不执行 `run()`、不启动 event loop、不 drain queue、不调用平台，也不绕过 ControllerReport 读取 AppRunReport、RunBoundaryReport 或 lower-level readiness / platform / lifecycle facts。
- app run dispatch request 只包装 `CjguiInternalAppRunExecutionPlanReport`；dispatch summary 只从 execution plan 投影 prepare-runtime、run-loop-draft、deferred notice、blocked notice 与 future-boundary request signals。
- app run dispatch draft 不执行 dispatch、不写 queue、不执行 `run()`、不启动 event loop、不 drain queue、不调用平台，也不绕过 ExecutionPlanReport 读取 ControllerReport、AppRunReport、RunBoundaryReport 或 lower-level readiness / platform / lifecycle facts。
- run loop draft request 只包装 `CjguiInternalAppRunDispatchReport`；run loop draft intent 只从 dispatch summary 投影 enter-loop-draft、defer-loop-draft、blocked-loop-report 与 future-boundary signals。
- run loop draft 不执行 loop、不写 `while` / scheduling loop、不写 queue、不 drain queue、不调用平台，也不绕过 DispatchReport 读取 ExecutionPlanReport、ControllerReport、AppRunReport、RunBoundaryReport 或 lower-level readiness / platform / lifecycle facts。
- loop iteration draft request 只包装 `CjguiInternalRunLoopDraftReport`；loop iteration draft intent 只从 RunLoopDraft intent 投影 attempt-iteration、defer-iteration、blocked-iteration-report 与 future-boundary signals。
- loop iteration draft 不执行 loop、不执行 iteration、不 schedule、不写 queue、不 drain queue、不调用平台，也不绕过 RunLoopDraftReport 读取 DispatchReport、ExecutionPlanReport、ControllerReport、AppRunReport、RunBoundaryReport 或 lower-level readiness / platform / lifecycle facts。
- iteration work packet draft request 只包装 `CjguiInternalLoopIterationDraftReport`；work packet draft 只从 loop iteration intent 投影 prepare-runtime work、lifecycle work、future-boundary work、defer work 与 blocked-work signals。
- iteration work packet draft 不执行 work、不写 queue、不 drain queue、不 process input、不 layout / render、不调用平台，也不绕过 LoopIterationDraftReport 读取 RunLoopDraftReport、DispatchReport、ExecutionPlanReport、ControllerReport、AppRunReport、RunBoundaryReport 或 lower-level readiness / platform / lifecycle facts。
- lifecycle work draft request 只包装 `CjguiInternalIterationWorkPacketDraftReport`；lifecycle work draft 只从 work packet 投影 process-lifecycle、defer-lifecycle、blocked-lifecycle 与 future-boundary-after-lifecycle signals。
- lifecycle work draft 不执行 app/window lifecycle、不修改 app/window state、不写 queue、不 drain queue、不调用平台，也不绕过 IterationWorkPacketDraftReport 读取 LoopIterationDraftReport、RunLoopDraftReport、DispatchReport、ExecutionPlanReport、ControllerReport、AppRunReport、RunBoundaryReport 或 lower-level readiness / platform / lifecycle facts。
- lifecycle owner handoff draft 将 owner-specific handoff facts 切回 `app_lifecycle.cj` 与 `window_lifecycle.cj`；app/window handoff draft 只表达 accept / defer / blocked facts，不执行 lifecycle transition 或 state mutation。
- runtime owner handoff request / report 留在 `runtime_state.cj`，只消费 `CjguiInternalLifecycleWorkDraftReport.draft` 并路由到 app/window owner builders；它不越级读取 IterationWorkPacketDraftReport、LoopIterationDraftReport、RunLoopDraftReport 或 lower-level facts，也不执行 lifecycle work。
- lifecycle mutation readiness draft 将 owner-specific readiness facts 留在 `app_lifecycle.cj` 与 `window_lifecycle.cj`；app/window readiness draft 只表达 canMutate / shouldDefer / shouldReportBlocked，不修改 state、不调用 transition functions、不执行 lifecycle work。
- runtime mutation readiness request / report 留在 `runtime_state.cj`，只消费 `CjguiInternalLifecycleOwnerHandoffReport.appDraft` / `windowDraft` 并汇总 cross-owner readiness；它不越级读取 LifecycleWorkDraftReport 或 lower-level facts，也不执行 mutation。
- lifecycle mutation plan draft 将 owner-specific plan facts 留在 `app_lifecycle.cj` 与 `window_lifecycle.cj`；app/window plan draft 只表达 shouldPlan / shouldDeferPlan / shouldReportPlanBlocked，不修改 state、不调用 transition functions、不执行 lifecycle work。
- runtime mutation plan request / report 留在 `runtime_state.cj`，只消费 `CjguiInternalLifecycleMutationReadinessReport.appReadiness` / `windowReadiness` 并汇总 cross-owner plan；它不越级读取 OwnerHandoffReport、LifecycleWorkDraftReport 或 lower-level facts，也不执行 mutation。
- lifecycle mutation commit gate draft 将 owner-specific commit gate facts 留在 `app_lifecycle.cj` 与 `window_lifecycle.cj`；app/window commit gate draft 只表达 canEnterCommit / shouldDeferCommit / shouldReportCommitBlocked，不修改 state、不调用 transition functions、不执行 lifecycle work。
- runtime mutation commit gate request / report 留在 `runtime_state.cj`，只消费 `CjguiInternalLifecycleMutationPlanReport.appPlan` / `windowPlan` 并汇总 cross-owner commit gate；normalization 后 report 不再存储 always-true `didBuildMutationCommitGate`，也不再存储可由 app/window gates 推导的 both-owner can-enter field，both-owner can-enter 由局部 helper 推导。它不越级读取 MutationReadinessReport、OwnerHandoffReport、LifecycleWorkDraftReport 或 lower-level facts，也不执行 mutation 或 commit state。
- lifecycle mutation apply draft 将 owner-specific apply facts 留在 `app_lifecycle.cj` 与 `window_lifecycle.cj`；app/window apply draft 只表达 shouldApplyMutation / shouldDeferApply / shouldReportApplyBlocked，不修改 state、不调用 transition functions、不执行 lifecycle work。
- runtime mutation apply request / report 留在 `runtime_state.cj`，只消费 `CjguiInternalLifecycleMutationCommitGateReport.appCommitGate` / `windowCommitGate` 并汇总 cross-owner apply intent；normalization 后 report 不再存储 always-true `didBuildMutationApply`，也不再存储可由 app/window apply facts 推导的 both-owner should-apply field，both-owner should-apply 由局部 helper 推导。它不越级读取 MutationPlanReport、MutationReadinessReport、OwnerHandoffReport、LifecycleWorkDraftReport 或 lower-level facts，也不执行 mutation 或 apply state。
- first internal lifecycle state mutation 将 owner-local immutable-copy state transition 放在 `app_lifecycle.cj` 与 `window_lifecycle.cj`；app open path 生成 `CjguiInternalAppLifecycleState(true, true, state.hasObservedPlatformReady)`，window open path 生成 `CjguiInternalWindowLifecycleState(true, state.hasObservedPlatformReady)`，blocked / deferred path 返回原 state 不变。
- runtime lifecycle state mutation request / report 留在 `runtime_state.cj`，只消费 `CjguiInternalLifecycleMutationApplyReport.appApply` / `windowApply` 与 prior app/window states 并汇总 cross-owner result；它不越级读取 CommitGateReport、MutationPlanReport、MutationReadinessReport 或 lower-level facts，不做 in-place mutation，不调用 existing state-changing transition functions，不执行 platform callback、queue、event loop 或 window create / close / destroy。
- lifecycle state mutation outcome draft 留在 `runtime_state.cj`，只消费 `CjguiInternalLifecycleStateMutationReport` 并聚合 / 验证 already-produced owner mutation results；normalization 后 report 只存储 app/window mutation flags、blocked-state preservation 与 blocked report flag，已移除 always-true `didBuildMutationOutcome` marker 和可推导的 stored both-mutated field，both-mutated 由局部 helper 推导。OutcomeReport -> OutcomeRequest -> StateMutationReport 嵌套保留为 traceability，不是递归循环；本层不执行第二次 mutation、不修改 app/window state、不读取 ApplyReport / CommitGateReport / MutationPlanReport 或 lower-level facts。
- lifecycle mutated state publication draft 留在 `runtime_state.cj`，只消费 `CjguiInternalLifecycleStateMutationOutcomeReport`，并通过 outcome traceability 读取 already-produced `appResult.nextState` / `windowResult.nextState`，表达这些 nextState values 是否可作为后续 internal runtime 输入；本层不执行新的 mutation、不修改 app/window state、不公开 state、不写 runtime global state、不读取 ApplyReport / CommitGateReport / MutationPlanReport 或 lower-level facts。
- runtime state carry-forward draft 留在 `runtime_state.cj`，只消费 `CjguiInternalLifecycleMutatedStatePublicationReport`，并把 publication report 中的 app/window state 标记为下一轮 internal runtime cycle 的 candidate；model consolidation 后不再存储恒为 true 的 `didBuildCarryForwardDraft` marker。本层只是 candidate summary，不是 committed runtime state store，不写 runtime global state、不公开 state、不执行 mutation、不读取 OutcomeReport / MutationReport / ApplyReport 或 lower-level facts。
- runtime carried state container draft 留在 `runtime_state.cj`，只消费 `CjguiInternalRuntimeStateCarryForwardReport`，并把 carry-forward candidate app/window state 包装为下一轮 internal runtime cycle 可携带的 container draft；本层不是 committed runtime state store，不写 runtime global state、不公开 state、不执行 mutation、不读取 PublicationReport / OutcomeReport / MutationReport 或 lower-level facts。
- runtime state holder draft 留在 `runtime_state.cj`，只消费 `CjguiInternalRuntimeCarriedStateContainer`，并把 carried app/window state 包装成 value-style held state summary；本层不是 committed runtime state store，不是 global mutable singleton，不写 runtime global state、不公开 state、不执行 mutation、不读取 CarryForwardReport / PublicationReport / OutcomeReport 或 lower-level facts。
- runtime committed state store draft 留在 `runtime_state.cj`，只消费 `CjguiInternalRuntimeStateHolderDraft`，并把 held app/window state 包装成 value-style committed state summary；本层不是 committed runtime global state store，不是 global mutable singleton，不写 runtime global state、不公开 state、不执行 mutation、不读取 CarriedStateContainer / CarryForwardReport / PublicationReport / lower-level facts。
- runtime cycle feedback draft 留在 `runtime_state.cj`，只消费 `CjguiInternalRuntimeCommittedStateStoreDraft`，并把 committed app/window state 投影为下一轮 internal runtime cycle 的 value-style feedback candidates；本层不执行下一轮 cycle，不写 runtime global state，不创建 global mutable singleton，不公开 state、不执行 mutation、不读取 StateHolderDraft / CarriedStateContainer / CarryForwardReport / lower-level facts。
- runtime internal tail milestone：current default tail endpoint 是 `cjguiInternalExecuteDefaultRuntimeTailDraft()`，返回 `CjguiInternalRuntimeExecutionStateLoopClosure`；loop closure 只消费 `CjguiInternalRuntimeExecutionStateIntegration`，从 integration feedback 归拢下一轮 internal cycle request candidate，但不执行 candidate、不调用 `cjguiInternalExecuteRuntimeCycle`、不写 runtime global state。主线符号与 stop-line 见 [P1 runtime internal tail milestone manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-runtime-internal-tail-milestone-manifest.md)。
- runtime state store transition boundary 留在 `runtime_state.cj`，通过 `CjguiInternalRuntimeStateStoreVersion` / `CjguiInternalRuntimeStateStoreSnapshot` / `CjguiInternalRuntimeStateStoreTransition` 表达 value-style snapshot transition；`cjguiInternalExecuteDefaultRuntimeStateStoreTransitionDraft()` 从 default tail 取得 loop closure，并从 integration committed state 构造 previous snapshot。open path 只返回 version+1 的 next snapshot，defer / blocked / inconsistent path 保留 previous snapshot；本层不是 global mutable state，不写 process-wide runtime global state，不公开 state、不执行 second cycle、不接 event loop / queue / platform。state-store transition 的 owner / truth / stop-line 见 [P1 runtime state store transition manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-runtime-state-store-transition-manifest.md)；`cjguiInternalRuntimeStateStoreTransitionDidOpen` / `ShouldDefer` / `ShouldReportBlocked` 仅为 derived predicates，不改变 transition behavior。
- internal input intent boundary 留在 `runtime_state.cj`，通过 `CjguiInternalInputIntentSource` / `CjguiInternalInputIntentKind` / `CjguiInternalInputIntent` / `CjguiInternalInputIntentAdmission` 表达脱水 runtime ingress facts。source 必须在 synthetic / platform-origin / user-origin 中 exactly one，kind 必须在 activation / text / pointer / lifecycle 中 exactly one；absent intent defer，invalid source / kind fail-closed blocked，默认 draft 为 synthetic activation present。它不是 platform event object，不保存 native handle / raw pointer / callback，不写 queue / event loop / scheduler，不执行 runtime cycle，不写 global state。
- internal input routing boundary 留在 `runtime_state.cj`，通过 `CjguiInternalInputRoutingResult` 只消费 `CjguiInternalInputIntentAdmission`，把 admitted input intent 标记为 future runtime ingress candidate；defer / blocked path 保持 defer / fail-closed blocked。`didPreserveInputIntent` 只表示继续携带脱水 intent candidate，不是 enqueue、event dispatch、scheduler tick 或 runtime cycle execution；本层不接 platform、不写 queue / event loop / scheduler、不调用 `cjguiInternalExecuteRuntimeCycle`、不写 global state。
- internal input-to-runtime ingress boundary 留在 `runtime_state.cj`，通过 `CjguiInternalInputRuntimeIngress` 组合 `CjguiInternalInputRoutingResult` 与 `CjguiInternalRuntimeStateStoreTransition`，只判断脱水 input candidate 是否可被当前 runtime state boundary 接受。`didPreserveRuntimeIngressCandidate` 只表示 input candidate 与 state boundary context 作为 value 一起携带，不是 enqueue、dispatch、scheduler tick、runtime cycle execution 或 global state write；本层不接 platform event object / native handle / raw pointer，不写 queue / event loop / scheduler，不调用 `cjguiInternalExecuteRuntimeCycle`。主线、acceptance 语义与 stop-line 见 [P1 input-to-runtime ingress manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-input-to-runtime-ingress-manifest.md)；`runtime_state.cj` 已处于 single-file critical warning 区间，后续新增 ingress subsystem 应优先考虑 split / module extraction。
- internal scheduler tick intent boundary 已拆到 `runtime_scheduler.cj`，通过 `CjguiInternalSchedulerTickSource` / `Kind` / `Intent` / `Admission` 表达脱水 tick ingress facts。source 必须在 synthetic / frame-pacing / deferred-work 中 exactly one，kind 必须在 cycle-preparation / render-preparation / idle-maintenance 中 exactly one；absent tick defer，invalid source / kind fail-closed blocked，默认 draft 为 synthetic cycle-preparation present admitted。它不是 platform timer、runloop source、callback、scheduler implementation、queue / drain、event loop 或 runtime cycle execution；owner split 避免继续增大 critical `runtime_state.cj`。
- internal scheduler-to-runtime ingress boundary 留在 `runtime_scheduler.cj`，通过 `CjguiInternalSchedulerRuntimeIngress` 组合 scheduler tick admission 与 `CjguiInternalRuntimeStateStoreTransition` context。open path 需要 admitted tick 与 open state transition，defer-only 保持 defer，blocked / inconsistent fail-closed blocked；`didPreserveSchedulerTick` 只表示脱水 tick candidate 与 state boundary context 被 value-style 携带，不是 enqueue、dispatch、scheduler implementation、event loop 或 runtime cycle execution。default draft 只调用 scheduler admission default 与 state-store transition default，不调用 `cjguiInternalExecuteRuntimeCycle`，也不写 queue / global state。
- internal runtime ingress coordinator 已拆到 `runtime_ingress.cj`，通过 `CjguiInternalRuntimeIngressCoordinator` 组合 `CjguiInternalInputRuntimeIngress` 与 `CjguiInternalSchedulerRuntimeIngress`。open path 要求 input candidate 与 scheduler pacing candidate 同时 ready，defer-only 保持 defer，blocked / inconsistent fail-closed blocked；它只表达 unified internal front door readiness，不是 enqueue、dispatch、event loop、scheduler implementation、runtime cycle execution 或 global state write。default draft 只组合已有 input ingress / scheduler ingress default values，不调用 `cjguiInternalExecuteRuntimeCycle`；`cjguiInternalRuntimeIngressCoordinatorCanEnter` / `ShouldReportBlocked` 只是 derived predicates，不改变 coordinator behavior。runtime ingress 主线、owner / truth 与 stop-line 见 [P1 runtime ingress manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-runtime-ingress-manifest.md)；`runtime_state.cj` critical warning 仍保留，新 ingress owner 不回塞该文件。
- internal queue admission boundary 已拆到 `runtime_queue.cj`，通过 `CjguiInternalQueueAdmissionPolicy` / `CjguiInternalQueueAdmission` 只消费 `CjguiInternalRuntimeIngressCoordinator`，表达 future queue admission readiness。default policy 要求 ingress front door ready 且不允许 deferred admission；open path 只保留 dehydrated ingress candidate，defer / blocked / inconsistent fail-closed。它不是 queue storage、enqueue side effect、drain、scheduler implementation、event loop、runtime cycle execution 或 global state write；`runtime_state.cj` critical warning 仍保留，queue symbols 不回塞该文件。
- internal Action Router action intent boundary 已拆到 `action_router.cj`，通过 `CjguiInternalActionSource` / `Kind` / `Intent` / `Admission` 表达 dehydrated action facts。source 必须在 human / agent / system 中 exactly one，kind 必须在 input / scheduler / runtime-boundary / diagnostic 中 exactly one；default draft 使用 system origin + runtime-boundary action，并消费 `CjguiInternalQueueAdmission` 作为下游 gate。`CjguiInternalActionRoutingResult` 只消费 action admission，将 admitted action intent 投影为 runtime boundary route candidate；defer / blocked / inconsistent 保持 defer 或 fail-closed blocked。`CjguiInternalActionDispatchAdmission` 只消费 routing result，将 route candidate 投影为 future dispatch boundary readiness；`CjguiInternalActionDispatchPlan` 只消费 dispatch admission，将 ready admission 投影为 value-style dispatch plan candidate / defer / blocked。dispatch convergence / commit candidate / finalization 继续只消费上一阶段 value，将 plan 收束为可提交的 internal dispatch candidate 和 finalization summary；`CjguiInternalActionDispatchRecord` 只记录 finalization 形成的 internal value-style dispatch boundary。effect model / execution guard / execution readiness 继续只从 dispatch record 投影 future action execution 的 effect category、guard readiness 和 readiness summary；first execution attempt / attempt result 只从 readiness 投影 attempt accepted / deferred / blocked summary；execution convergence / commit candidate / finalization 只从 attempt result 收束 accepted / deferred / blocked facts，形成 value-style future execution boundary summary；`CjguiInternalActionExecutionRecord` 只记录 finalization 形成的 internal value-style execution boundary。tail consolidation 已移除无 `.cj` 调用点的低价值 route / execution-record derived helper，并补充 canonical endpoint 中文维护注释；execution policy model bundle 已落地，`CjguiInternalActionExecutionPolicyModel` / `Gate` / `Readiness` 只消费 execution record 并表达 future execution constraints / gate / readiness。它们不是真实 action execution、action side effect、queue enqueue / drain、AI provider、public API、event loop、scheduler、platform callback、runtime cycle、provider response 或 public audit log。Action Router owner / truth / stop-line 见 [P1 Action Router manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-action-router-manifest.md)。`runtime_state.cj` critical warning 仍保留，Action Router symbols 不回塞该文件。
- guarded execution attempt boundary 已落地在 `action_router.cj`：`CjguiInternalActionGuardedExecutionAttempt` / `AttemptResult` / `Acceptance` 只消费 `CjguiInternalActionExecutionPolicyReadiness`，将 policy readiness 投影为 guarded attempt accepted / deferred / blocked facts。它仍不是真实 action execution，不产生 side effect，不写 queue / enqueue / drain，不接 AI provider / prompt / external agent，不公开 API / C ABI，不接 event loop / scheduler / platform callback，不调用 runtime cycle。
- guarded execution commit / effect boundary 已落地在 `action_router.cj`：`CjguiInternalActionGuardedExecutionEffectPlan` / `CommitCandidate` / `Finalization` 只消费 `CjguiInternalActionGuardedExecutionAcceptance`，将 guarded acceptance 收束为 future execution effect plan / commit candidate / finalization facts。它仍不是真实 action execution，不产生 side effect，不写 queue / enqueue / drain，不接 AI provider / prompt / external agent / model session，不公开 API / C ABI，不接 event loop / scheduler / platform callback，不调用 runtime cycle。
- guarded execution result publication boundary 已落地在 `action_router.cj`：`CjguiInternalActionGuardedExecutionResultPublication` / `HandoffCandidate` 只消费 `CjguiInternalActionGuardedExecutionFinalization` 和 downstream publication value，将 guarded finalization 投影为 internal result publication / handoff candidate facts。它仍不是真实 action execution 或 public publication，不产生 side effect，不写 queue / enqueue / drain，不接 AI provider / prompt / external agent / model session，不公开 API / C ABI，不接 observer callback、event loop、scheduler、platform callback 或 runtime cycle。
- internal Action Router handoff downstream consumer boundary 已拆到 `action_handoff.cj`：`CjguiInternalActionHandoffConsumer` / `Acceptance` / `Receipt` 只消费 `CjguiInternalActionGuardedExecutionHandoffCandidate`，将 Action Router canonical endpoint 投影为 downstream receiver / acceptance / receipt value facts。它仍不是真实 action execution、queue enqueue record、public audit log、observer callback、external notification、AI provider response、public API / C ABI、event loop、scheduler、platform callback 或 runtime cycle。
- internal Action Handoff queue integration boundary 已拆到 `action_handoff_queue.cj`：`CjguiInternalActionHandoffQueueAdmission` / `Integration` / `Candidate` 只消费 `CjguiInternalActionHandoffReceipt` 与 `CjguiInternalQueueAdmission` readiness，将 handoff receipt 投影为 queue-adjacent admission / integration / candidate value facts。它仍不是 queue storage、enqueue side effect、drain plan、真实 action execution、public audit log、observer callback、AI provider response、public API / C ABI、event loop、scheduler、platform callback 或 runtime cycle。
- internal Queue owner handoff consumer boundary 已拆到 `runtime_queue_handoff.cj`：`CjguiInternalQueueHandoffConsumer` / `Acceptance` / `Gate` 只消费 `CjguiInternalActionHandoffQueueCandidate`，将 queue-adjacent handoff candidate 投影为 queue-side consumer / acceptance / gate value facts。它仍不是 queue storage、enqueue side effect、drain plan、scheduler task、真实 action execution、public audit log、observer callback、AI provider response、public API / C ABI、event loop、platform callback 或 runtime cycle。
- internal Queue permission gate boundary 已拆到 `runtime_queue_permission.cj`：`CjguiInternalQueuePermissionPolicy` / `Gate` / `Readiness` 只消费 `CjguiInternalQueueHandoffGate`，将 queue-side handoff gate 投影为 enqueue 前 permission / policy / readiness value facts。它仍不是 queue storage、enqueue side effect、drain plan、scheduler task、真实 action execution、public audit log、observer callback、AI provider response、public API / C ABI、event loop、platform callback 或 runtime cycle。
- current main tail path：`CjguiInternalRuntimeExecutionAttemptReport` -> `CjguiInternalRuntimeExecutionConvergenceReport` -> `CjguiInternalRuntimeExecutionCommitCandidate` -> `CjguiInternalRuntimeExecutionCommitReadiness` -> `CjguiInternalRuntimeExecutionCommitRecord` -> `CjguiInternalRuntimeExecutionCommitFinalization` -> `CjguiInternalRuntimeExecutionStateIntegration` -> `CjguiInternalRuntimeExecutionStateLoopClosure`。这些 value-style summaries 只收束 already-produced internal attempt / integration facts，不新增 public API / C ABI、event loop、queue、scheduler、platform callback、global state write 或 second cycle execution。
- legacy diagnostics / trace：`CjguiInternalRuntimeCycleReplay*`、`CjguiInternalRuntimeReplayOutcome*`、`CjguiInternalRuntimeExecutionAdmission*`、`CjguiInternalRuntimeDryRunExecutionPlan*` 仍保留为 diagnostics / trace 或 first execution attempt 的 legacy input trace，但不再是 default tail path；旧 replay / outcome / admission / dry-run open-default sanity helper 已删除，blocked legacy sanity 仅作 diagnostics。
- step outcome bundle 已封账；下一步应转向更大的 runtime behavior decision，而不是继续堆 helper 链。
- root sanity 已封账；下一步应转向 first internal runtime step / step result，而不是继续堆 root helper。
- root state 不定义 runtime state machine、app run、event loop、queue / drain、window create 或 shutdown。
- 当前不新增 public runtime API、public C ABI、platform object、native handle 或 raw pointer。

## Error Strategy Surface Boundary

当前 `src/error.cj` 已经承载默认 internal 的 compile sanity marker、最小 error fact 和 taxonomy marker，但仍不是正式 error strategy implementation。

边界如下：

- error strategy future owner 属于 `runtime/cjgui` error strategy 模块；它只分类 future failure / degraded diagnostics，不拥有 app state、window state 或 platform truth。
- app lifecycle 汇报 app-level outcome，window lifecycle 汇报 window-target outcome，platform adapter 汇报 native capability / failure summary；error strategy 只接收脱水 summary。
- smoke `last_error` 不迁移为正式 runtime error system。
- future runtime error 必须是 call-associated、structured、non-global 且 concurrency-safe。
- 当前不定义 error enum、`Result` type、exception-like mechanism、稳定函数签名或 diagnostics 第二状态真相源。

## Package / Build Metadata Boundary

当前 `cjpm.toml` 只建立 minimal runtime package metadata boundary，不代表 runtime behavior、public runtime API 或 public C ABI 已经存在。

边界如下：

- package owner 候选是 `runtime/cjgui`，不属于 `labs/macos_bridge_smoke`。
- 当前十个 `.cj` source 允许已经落地的默认 internal marker / fact / transition / coordination / bootstrap / root state / scheduler tick / scheduler ingress / unified ingress owner skeleton / queue admission owner skeleton / Action Router action intent owner skeleton。
- 除已封账的 internal skeleton 外，不应顺手新增 public API、public C ABI、真实 runtime behavior、`main` entry、额外 build script 或 smoke 迁移。
- build / check 结果只能作为工具链证据，不能替代 source truth。

## Smoke Guard Relationship

`labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 继续作为旧链路 guard。它不是正式 runtime test framework，也不定义本目录的 public API。

## Red-team Guardrails

当前 skeleton 继续遵守：

- 不扩大每轮必读历史文档集。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。
- 不进入 pixel diff / baseline。
- 不保存或输出 hash value。
- 不实现 command-list hash。
- 不定义 Display List / Command Buffer API。
- 不让 core runtime 持有 AppKit runloop truth。
- 不实现 semantic tree / Action Router。
- render hot path 不维护完整 semantic tree。
