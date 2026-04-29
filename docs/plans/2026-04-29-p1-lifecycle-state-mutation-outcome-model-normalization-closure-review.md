# P1 Lifecycle State Mutation Outcome Model Normalization Closure Review

## Scope Closed

- `runtime_state.cj` OutcomeDraft 局部完成 behavior-preserving normalization。
- 移除 `CjguiInternalLifecycleStateMutationOutcomeReport.didBuildMutationOutcome` stored field；它只是 always-true marker，sanity 不再依赖它。
- 移除 `didMutateBothLifecycleOwners` stored field；新增 `cjguiInternalLifecycleStateMutationOutcomeDidMutateBothOwners(report)` 从 app/window mutation flags 推导。
- 更新 open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked outcome sanity helpers。

## Behavior Preserved

- Open path 仍表示 app/window 均已 mutation。
- Runtime / input / shutdown / cancellation blocked path 仍表示 app/window 均未 mutation，且 blocked state preserved。
- `didPreserveBlockedLifecycleState` 与 `shouldReportLifecycleMutationBlocked` 语义不变。
- Outcome draft 仍只消费 `CjguiInternalLifecycleStateMutationReport`，不读取 ApplyReport、CommitGateReport、MutationPlanReport、MutationReadinessReport 或 lower-level facts。

## What Remains

`OutcomeReport -> OutcomeRequest -> StateMutationReport` 嵌套保留。它当前用于 traceability，不是递归循环；本轮不做深层解嵌，避免把局部 normalization 扩成跨链路结构重构。

长类型名也保留。本轮不做跨全链路命名重构；后续可在更明确的 owner / alias strategy 下再压缩。

## Verification

- `cjpm build --target-dir /tmp/cjgui-lifecycle-state-mutation-outcome-normalization-target --skip-script` passed after envsetup, with existing unused warnings only。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` passed。
- `git diff --check` passed。

## Stop-Line

本轮没有修改 app/window state shape，没有修改 owner mutation functions，没有改变 lifecycle state mutation behavior，没有新增 public runtime API / public C ABI，没有接入 platform callback、queue / drain、event loop 或跨全链路重命名。

## Next Opening

`P1 lifecycle state mutation outcome normalization closure / next runtime behavior decision`
