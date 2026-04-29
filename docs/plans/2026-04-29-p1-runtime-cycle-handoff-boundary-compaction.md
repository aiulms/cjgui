# P1 Runtime Cycle Handoff Boundary Compaction

日期：2026-04-29

## Landed Facts

- CycleFeedback draft 只消费 `CjguiInternalRuntimeCommittedStateStoreDraft`，并产生 next-cycle app/window state candidates。
- NextCycleRequest draft 只消费 `CjguiInternalRuntimeCycleFeedbackDraft`，并构造 value-style `CjguiInternalRuntimeCycleRequest` candidate。
- 当前仍没有执行下一轮 cycle。
- 当前仍没有 event loop、queue / drain、scheduler、runtime global state write 或 public API。

## Boundary Decision

可以进入 internal-only / value-style runtime cycle handoff draft。

下一刀必须只消费 `CjguiInternalRuntimeNextCycleRequestDraft`，并且只能表达 prepared next-cycle request candidate 是否可 hand off 给 future runtime boundary。它可以持有 `CjguiInternalRuntimeCycleRequest` candidate，但不能执行该 candidate，不能执行 runtime cycle / step，不能写 global state，不能 mutate app/window state，也不能绕过 NextCycleRequestDraft 读取 CycleFeedbackDraft / CommittedStateStoreDraft / lower-level facts。

## Owner Decision

owner 建议继续是 `runtime_state.cj`，因为 cycle handoff 是 runtime-level summary。

`app_lifecycle.cj` / `window_lifecycle.cj` 不应拥有 cross-owner cycle handoff。`platform_adapter.cj` / `runtime_bootstrap.cj` 也不应接管该 owner。

## Recommended Next Opening

`P1 runtime cycle handoff draft bundle implementation`

## Next Implementation Boundary

下一刀可新增：

- `CjguiInternalRuntimeCycleHandoffRequest`
- `CjguiInternalRuntimeCycleHandoffDraft` 或等价 type
- builder / evaluator / executor / default executor
- open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked sanity helpers

下一刀仍不允许：

- public API / C ABI
- global mutable singleton
- event loop / queue / drain / scheduler
- next-cycle request execution
- runtime cycle / step execution
- platform callback
- app run / shutdown
- window create / close / destroy / release
- 修改 `cjpm.toml`、smoke、harness、native bridge、仓颉入口、`src/main.cj`、`package_anchor.cj`

## Stop-Line

Cycle handoff draft 只能是 prepared request candidate 的 internal handoff summary。它不是 runtime execution，不是 scheduler handoff，不是 event loop request，不是 committed global state，也不是 public runtime surface。
