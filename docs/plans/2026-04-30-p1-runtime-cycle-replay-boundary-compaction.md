# P1 Runtime Cycle Replay Boundary Compaction

日期：2026-04-30

## Landed Facts

- NextCycleRequest draft 只消费 `CjguiInternalRuntimeCycleFeedbackDraft`，并构造 value-style `CjguiInternalRuntimeCycleRequest` candidate。
- CycleHandoff draft 只消费 `CjguiInternalRuntimeNextCycleRequestDraft`，并表达该 candidate 是否可 hand off 给 future runtime boundary。
- 当前仍没有执行 next-cycle request。
- 当前仍没有调用 `cjguiInternalExecuteRuntimeCycle`。
- 当前仍没有 event loop、queue / drain、scheduler、runtime global state write 或 public API。

## Still Not

- 不是 next-cycle execution。
- 不是 runtime cycle / step execution。
- 不是 event loop、queue / drain 或 scheduler。
- 不是 runtime global state write。
- 不是 public runtime API 或 C ABI。
- 不是 platform callback。
- 不是 app run / shutdown。
- 不是 window create / close / destroy / release。

## Decision

可以进入 internal-only / value-style runtime cycle replay draft。

Replay draft 必须只消费 `CjguiInternalRuntimeCycleHandoffDraft`。它只能表达 handoff 后的 cycle request candidate 是否具备 replay readiness；可以读取 handoff 中持有的 `CjguiInternalRuntimeCycleRequest` candidate，但不能执行该 candidate，不能调用 `cjguiInternalExecuteRuntimeCycle`，不能执行 runtime step，不能写 global state，不能 mutate app/window state，也不能绕过 CycleHandoffDraft 读取 NextCycleRequestDraft / CycleFeedbackDraft / lower-level facts。

## Owner Decision

- owner 继续建议为 `runtime_state.cj`，因为这是 runtime-level replay readiness summary。
- `app_lifecycle.cj` / `window_lifecycle.cj` 不应拥有 cross-owner cycle replay summary。
- `platform_adapter.cj` / `runtime_bootstrap.cj` 不应接管该 owner。

## Recommended Next Opening

`P1 runtime cycle replay draft bundle implementation`

## Next Implementation Boundary

允许下一刀新增：

- `CjguiInternalRuntimeCycleReplayRequest`
- `CjguiInternalRuntimeCycleReplayDraft` 或等价 type
- builder / evaluator / executor / default executor
- open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked sanity helpers
- value-style 持有或检查 `CjguiInternalRuntimeCycleRequest` candidate

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
- 修改 `cjpm.toml`、smoke、harness、native bridge、仓颉入口、`src/main.cj`、`package_anchor.cj`
