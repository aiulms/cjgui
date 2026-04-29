# P1 Runtime Dry-Run Execution Plan Boundary Decision

日期：2026-04-30

性质：architecture decision / execution boundary review

## Landed Facts

- Runtime replay outcome 已能表达 accepted / deferred / blocked。
- Runtime execution admission draft 只消费 `CjguiInternalRuntimeReplayOutcomeReport`，并把 replay outcome 投影为 admission summary。
- 当前仍没有执行 `CjguiInternalRuntimeCycleRequest` candidate。
- 当前仍没有调用 `cjguiInternalExecuteRuntimeCycle`。
- 当前仍没有执行 runtime step。
- 当前仍没有 event loop、scheduler、queue / drain、runtime global state write、platform callback、public API 或 C ABI。

## Decision

可以考虑进入 internal-only / value-style dry-run execution plan draft。

Dry-run plan 不是 execution。下一刀必须保持以下边界：

- 只消费 `CjguiInternalRuntimeExecutionAdmissionReport`。
- 只表达如果未来执行，将采用哪个 `CjguiInternalRuntimeCycleRequest` candidate、是否 allowed、是否 deferred / blocked。
- 可以持有 `CjguiInternalRuntimeCycleRequest` candidate 作为 dry-run plan trace。
- 不执行 candidate。
- 不调用 `cjguiInternalExecuteRuntimeCycle`。
- 不执行 runtime step。
- 不写 runtime global state。
- 不 mutate app/window state。
- 不绕过 ExecutionAdmissionReport 读取 ReplayOutcomeReport / lower-level facts。

## Recommended Next Opening

`P1 runtime dry-run execution plan draft bundle implementation`

## Next Implementation Boundary

- 可新增 `CjguiInternalRuntimeDryRunExecutionPlanRequest`。
- 可新增 `CjguiInternalRuntimeDryRunExecutionPlan` 或等价 report type。
- 可新增 builder / evaluator / executor / default executor。
- 可新增 open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked sanity helpers。
- 允许持有 `CjguiInternalRuntimeCycleRequest` candidate 作为 dry-run plan trace。
- 不允许执行 candidate。
- 不允许 public API / C ABI。
- 不允许 event loop / queue / drain / scheduler。
- 不允许 platform callback。
- 不允许 app run / shutdown。
- 不允许 window create / close / destroy / release。

## Stop-Line

- Dry-run plan 之后不要继续无限增加同义 wrapper。
- 下一次进入更真实 execution 前，应再次判断是否需要拆 `runtime_state.cj` 或做 owner cleanup。
- 任何真正调用 `cjguiInternalExecuteRuntimeCycle` 的 slice 必须另开 high-risk execution boundary decision。
- 本 decision 不应变成每轮 implementation 的默认必读项。
