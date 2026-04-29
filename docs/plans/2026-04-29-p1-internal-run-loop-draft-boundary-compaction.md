# P1 Internal Run Loop Draft Boundary Compaction

日期：2026-04-29

## Context

本轮压缩现有 internal AppRun-to-dispatch 链路，用于判断是否可以进入第一个 internal-only RunLoopDraft surface。读取的 recent closure 文件均存在，未使用 fallback。

当前链路仍由 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj` 承载；本 compaction 不修改 runtime code，不创建 preflight / execution card。

## Current AppRun-To-Dispatch Capability

- AppRun surface：消费 `CjguiInternalRunBoundaryReport`，投影 internal `AppRunState` / `AppRunRequest` / `AppRunReport`；它不是 public run API，也不执行 `run()`。
- AppRun controller：只消费 `CjguiInternalAppRunReport`，派生 accepted / deferred / blocked / future-boundary next-action summary；它不执行任何 action。
- AppRun execution plan：只消费 `CjguiInternalAppRunControllerReport`，投影 prepare-runtime / run-loop-draft / defer / blocked / future-boundary plan summary；它不执行 plan。
- AppRun dispatch draft：只消费 `CjguiInternalAppRunExecutionPlanReport`，投影 prepare-runtime / run-loop-draft / deferred notice / blocked notice / future-boundary request dispatch summary；它不执行 dispatch、不写 queue。
- 现有 sanity 覆盖 open、runtime-blocked、input-blocked、shutdown-blocked、cancellation-blocked paths，blocked paths 都保持 fail-closed。
- Dispatch draft 明确不越级读取 ControllerReport、AppRunReport、RunBoundaryReport 或 lower-level readiness / platform / lifecycle facts。

## Still Not Opened

- 不是 public run API。
- 不是 real app run implementation。
- 不是 real event loop。
- 不是 queue / drain。
- 不是 platform callback。
- 不是 AppKit / Metal bridge。
- 不是 window create / close / destroy。
- 不是 renderer command list。

## Decision

可以开始定义第一个 internal-only run loop draft boundary，但它只能从 `CjguiInternalAppRunDispatchReport` 派生 loop-intent summary：

- `shouldEnterLoopDraft`
- `shouldDeferLoopDraft`
- `shouldReportLoopBlocked`
- `shouldRequestFutureBoundary`

RunLoopDraft 仍不能执行 loop、不能 `while`、不能 schedule、不能 drain queue、不能调平台。它也不能绕过 DispatchReport 直接读取 ExecutionPlanReport、ControllerReport、AppRunReport、RunBoundaryReport 或 lower-level facts。

## Recommended Next Opening

`P1 internal run loop draft bundle implementation`

## Next Slice Authorization Suggestion

Prompt weight: W3 internal subsystem draft.

允许下一刀一次完成：

- `CjguiInternalRunLoopDraftRequest`
- `CjguiInternalRunLoopDraftIntent`
- `CjguiInternalRunLoopDraftReport`
- builder / evaluator
- open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked sanity

禁止下一刀打开：

- public API / C ABI
- real `run()`
- real event loop
- `while` loop / scheduling loop
- queue / drain
- platform callback
- window create / close / destroy
- AppKit / Metal bridge

## Owner Recommendation

下一刀仍建议放在 `runtime_state.cj`，因为 RunLoopDraft 是 runtime-level run-loop boundary summary，不是 platform adapter implementation。

不要放进 `platform_adapter.cj`；platform adapter 不能在本阶段拥有 run loop truth。

