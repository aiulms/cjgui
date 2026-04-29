# CJGUI Minimal Runtime Skeleton

日期：2026-04-26

状态：minimal package skeleton / internal lifecycle boundary surface

本目录当前记录的是 `runtime/cjgui` 的默认 internal 运行时骨架。它用于承载未来 app lifecycle、window lifecycle、platform adapter 和 error strategy 的最小边界，不是正式 runtime implementation，不提供稳定 public runtime API，也不提供 public C ABI。

## First Compilable Source Boundary

当前六个 `src/*.cj` 文件都使用同一个 `package cjgui` declaration，并且只承载默认 internal 的最小骨架符号：

- `src/app_lifecycle.cj`
  - `CjguiInternalAppLifecycleState`
  - `CjguiInternalAppLifecycleTransitionMarker`
  - `CjguiInternalAppLifecyclePhaseTaxonomyMarker`
  - `CjguiInternalAppLifecycleWorkHandoffDraft`
  - `CjguiInternalAppLifecycleMutationReadinessDraft`
  - `CjguiInternalAppLifecycleMutationPlanDraft`
  - `cjguiInternalNoOpAppLifecycleTransition`
  - `cjguiInternalAppLifecyclePhaseMarkerTransition`
  - `cjguiInternalAppLifecycleHasObservedPlatformReady`
  - `cjguiInternalBuildAppLifecycleWorkHandoffDraft`
  - `cjguiInternalBuildAppLifecycleMutationReadinessDraft`
  - `cjguiInternalBuildAppLifecycleMutationPlanDraft`
  - `cjguiInternalAppLifecycleWorkHandoffOpenSanity`
  - `cjguiInternalAppLifecycleWorkHandoffBlockedSanity`
  - `cjguiInternalAppLifecycleMutationReadinessOpenSanity`
  - `cjguiInternalAppLifecycleMutationReadinessBlockedSanity`
  - `cjguiInternalAppLifecycleMutationPlanOpenSanity`
  - `cjguiInternalAppLifecycleMutationPlanBlockedSanity`
- `src/window_lifecycle.cj`
  - `CjguiInternalWindowLifecycleState`
  - `CjguiInternalWindowLifecycleWorkHandoffDraft`
  - `CjguiInternalWindowLifecycleMutationReadinessDraft`
  - `CjguiInternalWindowLifecycleMutationPlanDraft`
  - `cjguiInternalNoOpWindowLifecycleTransition`
  - `cjguiInternalWindowLifecycleStateMarkerTransition`
  - `cjguiInternalWindowLifecycleHasObservedPlatformReady`
  - `cjguiInternalBuildWindowLifecycleWorkHandoffDraft`
  - `cjguiInternalBuildWindowLifecycleMutationReadinessDraft`
  - `cjguiInternalBuildWindowLifecycleMutationPlanDraft`
  - `cjguiInternalWindowLifecycleWorkHandoffOpenSanity`
  - `cjguiInternalWindowLifecycleWorkHandoffBlockedSanity`
  - `cjguiInternalWindowLifecycleMutationReadinessOpenSanity`
  - `cjguiInternalWindowLifecycleMutationReadinessBlockedSanity`
  - `cjguiInternalWindowLifecycleMutationPlanOpenSanity`
  - `cjguiInternalWindowLifecycleMutationPlanBlockedSanity`
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
- 当前六个 `.cj` source 允许已经落地的默认 internal marker / fact / transition / coordination / bootstrap / root state owner skeleton。
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
