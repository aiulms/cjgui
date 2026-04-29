# P1 Internal Iteration Work Packet Boundary Compaction

日期：2026-04-29

## Context

本轮压缩现有 internal LoopIterationDraft 结论，用于判断是否可以进入第一个 internal-only iteration work packet draft surface。读取的 recent closure / compaction 文件均存在，未使用 fallback。

当前链路仍由 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj` 承载；本 compaction 不修改 runtime code，不创建 preflight / execution card。

## Current LoopIterationDraft Capability

- `CjguiInternalLoopIterationDraftRequest` 只包装 `CjguiInternalRunLoopDraftReport`，不表示 real loop iteration request、queue item、platform callback 或 scheduler task。
- `CjguiInternalLoopIterationDraftIntent` 只从 RunLoopDraft intent 投影 `shouldAttemptIteration`、`shouldDeferIteration`、`shouldReportIterationBlocked` 与 `shouldRequestFutureBoundary`。
- `CjguiInternalLoopIterationDraftReport` 只表示 single iteration draft 已构建，`didBuildIterationDraft` 只是 internal iteration planning completed。
- 现有 sanity 覆盖 open、runtime-blocked、input-blocked、shutdown-blocked、cancellation-blocked paths；blocked paths 都保持 fail-closed。
- LoopIterationDraft 只消费 `CjguiInternalRunLoopDraftReport`，不越级读取 AppRunDispatchReport、ExecutionPlanReport、ControllerReport、AppRunReport、RunBoundaryReport 或 lower-level readiness / platform / lifecycle facts。

## Still Not Opened

- 不是 real loop iteration。
- 不是 `while` loop。
- 不是 scheduling loop。
- 不是 queue / drain。
- 不是 platform callback。
- 不是 public run API。
- 不是 renderer pass。
- 不是 input processing pass。
- 不是 layout pass。
- 不是 window lifecycle execution。

## Decision

可以开始定义第一个 internal-only iteration work packet draft。IterationWorkPacketDraft 只能从 `CjguiInternalLoopIterationDraftReport` 派生 work-category summary：

- `shouldPrepareRuntimeWork`
- `shouldProcessLifecycleWork`
- `shouldPrepareFutureBoundaryWork`
- `shouldDeferWork`
- `shouldReportBlockedWork`

IterationWorkPacketDraft 仍不能执行 work、不能 drain queue、不能 process input、不能 layout / render、不能调平台。它也不能绕过 LoopIterationDraftReport 直接读取 RunLoopDraftReport、DispatchReport、ExecutionPlanReport 或 lower-level facts。

## Recommended Next Opening

`P1 internal iteration work packet draft bundle implementation`

## Next Slice Authorization Suggestion

Prompt weight: W3 internal subsystem draft.

允许下一刀一次完成：

- `CjguiInternalIterationWorkPacketDraftRequest`
- `CjguiInternalIterationWorkPacketDraft`
- `CjguiInternalIterationWorkPacketDraftReport`
- builder / evaluator
- open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked sanity

禁止下一刀打开：

- public API / C ABI
- real `run()`
- real event loop
- `while` loop / scheduling loop
- queue / drain
- input processing
- layout / render
- platform callback
- window create / close / destroy
- AppKit / Metal bridge

## Owner Recommendation

下一刀仍建议放在 `runtime_state.cj`，因为 IterationWorkPacketDraft 是 runtime-level iteration work packet draft，不是 renderer、input、platform、app lifecycle 或 window lifecycle implementation。

不要放进 `platform_adapter.cj`、`app_lifecycle.cj` 或 `window_lifecycle.cj`；这些 owner 不能在本阶段拥有 iteration work packet truth。
