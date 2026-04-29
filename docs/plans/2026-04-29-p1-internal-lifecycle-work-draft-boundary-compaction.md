# P1 Internal Lifecycle Work Draft Boundary Compaction

日期：2026-04-29

## Context

本轮压缩现有 internal IterationWorkPacketDraft 结论，用于判断是否可以进入第一个 internal-only LifecycleWorkDraft surface。读取的 recent closure / compaction 文件均存在，未使用 fallback。

当前链路仍由 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj` 承载；本 compaction 不修改 runtime code，不创建 preflight / execution card。

## Current IterationWorkPacketDraft Capability

- `CjguiInternalIterationWorkPacketDraftRequest` 只包装 `CjguiInternalLoopIterationDraftReport`，不表示 queue item、work execution request、platform callback、input task、layout task 或 render task。
- `CjguiInternalIterationWorkPacketDraft` 只从 LoopIterationDraft intent 投影 runtime work、lifecycle work、future-boundary work、defer work 与 blocked-work categories。
- `CjguiInternalIterationWorkPacketDraftReport` 只表示 work packet draft 已构建，`didBuildWorkPacket` 只是 internal packet planning completed。
- 现有 sanity 覆盖 open、runtime-blocked、input-blocked、shutdown-blocked、cancellation-blocked paths；blocked paths 都保持 fail-closed。
- IterationWorkPacketDraft 只消费 `CjguiInternalLoopIterationDraftReport`，不越级读取 RunLoopDraftReport、DispatchReport、ExecutionPlanReport、ControllerReport、AppRunReport、RunBoundaryReport 或 lower-level readiness / platform / lifecycle facts。

## Still Not Opened

- 不是 real work execution。
- 不是 app lifecycle execution。
- 不是 window lifecycle execution。
- 不是 queue / drain。
- 不是 input processing。
- 不是 layout / render。
- 不是 platform callback。
- 不是 public run API。

## Decision

可以开始定义第一个 internal-only lifecycle work draft。LifecycleWorkDraft 只能从 `CjguiInternalIterationWorkPacketDraftReport` 派生 lifecycle-work summary：

- `shouldProcessLifecycleWork`
- `shouldDeferLifecycleWork`
- `shouldReportLifecycleBlocked`
- `shouldPrepareFutureBoundaryAfterLifecycle`

LifecycleWorkDraft 仍不能执行 app lifecycle / window lifecycle，不能修改 app/window state，不能调用 platform。它也不能绕过 IterationWorkPacketDraftReport 直接读取 LoopIterationDraftReport、RunLoopDraftReport 或 lower-level facts。

## Recommended Next Opening

`P1 internal lifecycle work draft bundle implementation`

## Next Slice Authorization Suggestion

Prompt weight: W3 internal subsystem draft.

允许下一刀一次完成：

- `CjguiInternalLifecycleWorkDraftRequest`
- `CjguiInternalLifecycleWorkDraft`
- `CjguiInternalLifecycleWorkDraftReport`
- builder / evaluator
- open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked sanity

禁止下一刀打开：

- public API / C ABI
- real app lifecycle execution
- real window lifecycle execution
- app/window state mutation
- queue / drain
- input processing
- layout / render
- platform callback
- AppKit / Metal bridge

## Owner Recommendation

下一刀仍建议放在 `runtime_state.cj`，因为 LifecycleWorkDraft 是 runtime-level lifecycle work draft，不是 `app_lifecycle.cj` / `window_lifecycle.cj` 的真实生命周期执行。

不要放进 `app_lifecycle.cj` 或 `window_lifecycle.cj`，除非下一阶段明确要进入真实 lifecycle mutation owner。
