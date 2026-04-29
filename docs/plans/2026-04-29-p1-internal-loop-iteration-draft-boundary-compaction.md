# P1 Internal Loop Iteration Draft Boundary Compaction

日期：2026-04-29

## Context

本轮压缩现有 internal RunLoopDraft 结论，用于判断是否可以进入第一个 internal-only single loop iteration draft surface。读取的 recent closure / compaction 文件均存在，未使用 fallback。

当前链路仍由 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj` 承载；本 compaction 不修改 runtime code，不创建 preflight / execution card。

## Current RunLoopDraft Capability

- `CjguiInternalRunLoopDraftRequest` 只包装 `CjguiInternalAppRunDispatchReport`，不表示 real event loop request、queue item、platform callback 或 scheduler task。
- `CjguiInternalRunLoopDraftIntent` 只从 dispatch summary 投影 `shouldEnterLoopDraft`、`shouldDeferLoopDraft`、`shouldReportLoopBlocked` 与 `shouldRequestFutureBoundary`。
- `CjguiInternalRunLoopDraftReport` 只表示 loop draft 已构建，`didBuildLoopDraft` 只是 internal loop-intent planning completed。
- 现有 sanity 覆盖 open、runtime-blocked、input-blocked、shutdown-blocked、cancellation-blocked paths；blocked paths 都保持 fail-closed。
- RunLoopDraft 只消费 `CjguiInternalAppRunDispatchReport`，不越级读取 ExecutionPlanReport、ControllerReport、AppRunReport、RunBoundaryReport 或 lower-level readiness / platform / lifecycle facts。

## Still Not Opened

- 不是 real event loop。
- 不是 `while` loop。
- 不是 scheduling loop。
- 不是 queue / drain。
- 不是 platform callback。
- 不是 public run API。
- 不是 AppKit / Metal bridge。
- 不是 window create / close / destroy。
- 不是 renderer command list。

## Decision

可以开始定义第一个 internal-only single loop iteration draft。LoopIterationDraft 只能从 `CjguiInternalRunLoopDraftReport` 派生 single-iteration summary：

- `shouldAttemptIteration`
- `shouldDeferIteration`
- `shouldReportIterationBlocked`
- `shouldRequestFutureBoundary`

LoopIterationDraft 仍不能执行 loop、不能 `while`、不能 schedule、不能 drain queue、不能调平台。它也不能绕过 RunLoopDraftReport 直接读取 DispatchReport、ExecutionPlanReport、ControllerReport、AppRunReport、RunBoundaryReport 或 lower-level facts。

## Recommended Next Opening

`P1 internal loop iteration draft bundle implementation`

## Next Slice Authorization Suggestion

Prompt weight: W3 internal subsystem draft.

允许下一刀一次完成：

- `CjguiInternalLoopIterationDraftRequest`
- `CjguiInternalLoopIterationDraftIntent`
- `CjguiInternalLoopIterationDraftReport`
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

下一刀仍建议放在 `runtime_state.cj`，因为 LoopIterationDraft 是 runtime-level iteration draft boundary，不是 platform adapter implementation。

不要放进 `platform_adapter.cj`；platform adapter 不能在本阶段拥有 loop truth。

