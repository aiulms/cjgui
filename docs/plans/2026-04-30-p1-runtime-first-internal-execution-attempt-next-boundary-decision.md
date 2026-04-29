# P1 Runtime First Internal Execution Attempt Next Boundary Decision

日期：2026-04-30

性质：architecture_decision / docs-only boundary decision

## Landed Reality

- First internal execution attempt 已完成并封账为 [2026-04-30-p1-runtime-first-internal-execution-attempt-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-runtime-first-internal-execution-attempt-bundle-closure-review.md)。
- Execution attempt 只消费 `CjguiInternalRuntimeDryRunExecutionPlan`。
- allowed path 只执行一次 `cjguiInternalExecuteRuntimeCycle(plan.cycleRequestCandidate)`。
- blocked / deferred path 不执行 candidate。
- attempt report 不持有伪造的 `CjguiInternalRuntimeCycleResult`；它只保留 candidate、did-attempt / did-execute / did-progress 与 defer / blocked summary。

## Still Not Execution Runtime

当前能力仍然不是 event loop、scheduler、queue / drain、app run / shutdown、global state commit、public state publication、public runtime API 或 public C ABI。

它不执行多个 cycle，不写 runtime global state，不公开 app/window state，不接 platform callback，不实现 window create / close / destroy / release，也不把 first attempt 结果宣称为 public lifecycle 或 runtime behavior。

## Decision

可以继续进入一个极窄 internal-only / value-style post-attempt boundary。

推荐下一刀命名为：

`P1 runtime execution attempt outcome draft bundle implementation`

批准理由：

- first attempt 已经把唯一允许执行点收束到 `CjguiInternalRuntimeExecutionAttemptReport`。
- 下一刀若只消费 attempt report，就能观察 did-attempt / did-execute / did-progress / defer / blocked，不需要回读 dry-run、admission、replay 或 lower-level facts。
- post-attempt outcome 可以把“已经尝试过的结果”转成后续 execution boundary review 可用的 value summary，而不再次执行 candidate。
- `runtime_state.cj` 仍偏胖，但上一轮已做 tail-chain cleanup；再推进一个只读 attempt report 的 outcome layer 风险可控。进入 loop / scheduler / queue / platform callback 前仍需再次做 owner cleanup / subsystem split decision。

## Next Slice Allow List

- 只消费 `CjguiInternalRuntimeExecutionAttemptReport`。
- 只从 attempt report 投影 execution result / progress / deferred / blocked summary。
- 可以保留 `CjguiInternalRuntimeCycleRequest` candidate 作为 trace。
- 可以新增 request / outcome report、builder / evaluator / default executor、open / blocked sanity helpers。
- blocked / deferred path 只能表达 no execution / no progress 的 outcome。

## Next Slice Stop-Line

- 不再次执行 candidate。
- 不调用 `cjguiInternalExecuteRuntimeCycle`。
- 不执行 runtime step。
- 不执行 loop 或多个 cycle。
- 不写 runtime global state。
- 不创建 global mutable singleton。
- 不公开 state。
- 不接 event loop、queue / drain、scheduler 或 platform callback。
- 不新增 public runtime API 或 public C ABI。
- 不新增 platform handle、native object 或 raw pointer。
- 不做 app run / shutdown。
- 不做 window create / close / destroy / release。
- 不绕过 attempt report 读取 dry-run plan、execution admission、replay outcome 或 lower-level facts。

## Cangjie Upstream Feedback Check

本轮是 docs-only decision，只复盘既有 runtime attempt closure，没有发现新的仓颉语言、SDK、FFI、工具链或文档问题。

未触发 `CANGJIE_ISSUE_LEDGER` 更新。
