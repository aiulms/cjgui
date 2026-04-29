# P1 Runtime Dry-Run Execution Closure / Next Boundary Decision

日期：2026-04-30

性质：closure_review + architecture_decision

## Landed Facts

- Runtime dry-run execution plan draft 已完成并封账为 [2026-04-30-p1-runtime-dry-run-execution-plan-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-runtime-dry-run-execution-plan-draft-bundle-closure-review.md)。
- Dry-run plan 只消费 `CjguiInternalRuntimeExecutionAdmissionReport`。
- Dry-run plan 已能表达 future execution candidate、`isExecutionAllowed`、`shouldDeferExecution` 与 `shouldReportExecutionBlocked`。
- Dry-run plan 可以持有 `CjguiInternalRuntimeCycleRequest` candidate 作为 trace。
- 当前仍没有执行 candidate，没有调用 `cjguiInternalExecuteRuntimeCycle`，没有执行 runtime step。
- 当前仍没有 event loop、scheduler、queue / drain、runtime global state write、platform callback、public API 或 C ABI。

## What Dry-Run Means

Dry-run plan 是 execution boundary 前的 value-style plan summary。它回答“如果未来允许执行，会使用哪个 candidate，以及当前是 allowed / deferred / blocked 哪一种状态”。

Dry-run plan 不是 execution，原因是：

- 它不调用 `cjguiInternalExecuteRuntimeCycle`。
- 它不执行 `CjguiInternalRuntimeCycleRequest` candidate。
- 它不执行 runtime step。
- 它不写 runtime global state。
- 它不改变 app/window state。
- 它不接入 event loop、queue、scheduler 或 platform callback。

## Decision

可以进入第一个极窄 internal-only execution attempt boundary。

批准理由：

- admission 与 dry-run plan 已经把 accepted / deferred / blocked path 收束到单一 truth boundary。
- candidate 来源已经固定为 dry-run plan，不需要绕回 ReplayOutcome / CycleReplay / lower-level facts。
- 下一刀可以限定为“只在 allowed path 执行一个 internal cycle candidate，并把结果包装成 attempt report”，风险仍可被边界约束住。

这不是批准真实 runtime execution。下一刀只允许打开 first internal execution attempt，不允许进入 loop、scheduler、queue、platform callback 或 public surface。

## Recommended Next Opening

`P1 runtime first internal execution attempt bundle implementation`

## Next Slice Allow List

- 只消费 `CjguiInternalRuntimeDryRunExecutionPlan`。
- 只在 `isExecutionAllowed == true` 且没有 defer / blocked 时执行一个 `CjguiInternalRuntimeCycleRequest` candidate。
- 只允许调用一次 existing internal cycle executor。
- 只返回 internal execution attempt summary / report。
- blocked / deferred path 必须不执行 candidate。
- attempt report 只能表达 didAttempt / didExecuteOneCycle / deferred / blocked / cycle result trace 这类 internal facts。

## Next Slice Stop-Line

- 不执行 loop。
- 不执行多个 cycle。
- 不写 runtime global state。
- 不公开 state。
- 不接 event loop / queue / scheduler / platform callback。
- 不新增 public runtime API / public C ABI。
- 不新增 platform handle / native object / raw pointer。
- 不做 app run / shutdown。
- 不做 window create / close / destroy / release。
- 不绕过 dry-run plan 读取 ExecutionAdmissionReport / ReplayOutcomeReport / CycleReplayDraft / lower-level facts。
- 不把 first internal execution attempt 宣称为 event loop、app run 或 public runtime behavior。

## Cleanup Note

`runtime_state.cj` 仍偏胖。进入 first internal execution attempt 可以接受，但任何进一步接近 loop / scheduler / queue / platform callback 的 slice 之前，应再次做 owner cleanup / subsystem split decision。
