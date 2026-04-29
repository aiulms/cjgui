# P1 Runtime Replay Outcome Boundary Compaction

日期：2026-04-30

## Landed Facts

- CycleHandoff draft 只消费 `CjguiInternalRuntimeNextCycleRequestDraft`，并持有 next-cycle `CjguiInternalRuntimeCycleRequest` candidate。
- CycleReplay draft 只消费 `CjguiInternalRuntimeCycleHandoffDraft`，并表达 candidate 是否具备 replay readiness。
- 当前仍没有执行 candidate。
- 当前仍没有调用 `cjguiInternalExecuteRuntimeCycle`。
- 当前仍没有 runtime step execution、event loop、queue / drain、scheduler、runtime global state write 或 public API。

## Decision

可以进入 internal-only / value-style runtime replay outcome draft。

Replay outcome draft 必须只消费 `CjguiInternalRuntimeCycleReplayDraft`。它只能表达 replay readiness 的 accepted / deferred / blocked outcome summary；可以持有 `CjguiInternalRuntimeCycleRequest` candidate 作为 trace，但不能执行它，不能调用 `cjguiInternalExecuteRuntimeCycle`，不能执行 runtime step，不能写 global state，不能 mutate app/window state，也不能绕过 CycleReplayDraft 读取 CycleHandoffDraft / NextCycleRequestDraft / lower-level facts。

## Important Judgment

不建议继续无限增加 wrapper 层。Replay outcome draft 的用途是把 replay readiness 收束成可供后续“真实 execution boundary”判断的最终 internal summary。outcome 后应考虑暂停 runtime replay chain，转向 owner cleanup / model compression / readiness-to-execution boundary review，而不是继续堆 report。

## Owner Decision

- owner 继续建议为 `runtime_state.cj`，因为这是 runtime-level replay outcome summary。
- `app_lifecycle.cj` / `window_lifecycle.cj` 不应拥有 cross-owner replay outcome。
- `platform_adapter.cj` / `runtime_bootstrap.cj` 不应接管该 owner。

## Recommended Next Opening

`P1 runtime replay outcome draft bundle implementation`

## Next Implementation Boundary

允许下一刀新增：

- `CjguiInternalRuntimeReplayOutcomeRequest`
- `CjguiInternalRuntimeReplayOutcomeReport` 或等价 type
- builder / evaluator / executor / default executor
- open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked sanity helpers
- value-style 持有 `CjguiInternalRuntimeCycleRequest` candidate 作为 trace

下一刀仍不允许：

- public API / C ABI
- global mutable singleton
- event loop / queue / drain / scheduler
- platform callback
- app run / shutdown
- window create / close / destroy / release
- 执行 candidate 或调用 `cjguiInternalExecuteRuntimeCycle`
- 执行 runtime step
- runtime global state write
- app/window state mutation
- 绕过 CycleReplayDraft 读取 CycleHandoffDraft / NextCycleRequestDraft / lower-level facts
- 修改 `cjpm.toml`、smoke、harness、native bridge、仓颉入口、`src/main.cj`、`package_anchor.cj`
