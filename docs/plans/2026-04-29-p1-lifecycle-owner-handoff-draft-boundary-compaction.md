# P1 Lifecycle Owner Handoff Draft Boundary Compaction

日期：2026-04-29

## Context

本轮压缩现有 internal LifecycleWorkDraft 结论，并判断下一层 lifecycle owner handoff draft 是否应从 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj` 切回 lifecycle owner modules。读取的 recent closure / compaction 文件均存在，未使用 fallback。

本轮不写 runtime code，不创建 preflight / execution card，不进入 public API / C ABI、真实 lifecycle mutation、platform callback、queue 或 event loop。

## Current LifecycleWorkDraft Capability

- `CjguiInternalLifecycleWorkDraftRequest` 只包装 `CjguiInternalIterationWorkPacketDraftReport`，不表示 lifecycle execution request、app/window state mutation request、platform callback 或 queue item。
- `CjguiInternalLifecycleWorkDraft` 只从 IterationWorkPacketDraft packet 投影 `shouldProcessLifecycleWork`、`shouldDeferLifecycleWork`、`shouldReportLifecycleBlocked` 与 `shouldPrepareFutureBoundaryAfterLifecycle`。
- `CjguiInternalLifecycleWorkDraftReport` 只表示 lifecycle work draft 已构建，`didBuildLifecycleWorkDraft` 只是 internal planning completed。
- 现有 sanity 覆盖 open、runtime-blocked、input-blocked、shutdown-blocked、cancellation-blocked paths；blocked paths 都保持 fail-closed。
- LifecycleWorkDraft 只消费 `CjguiInternalIterationWorkPacketDraftReport`，不越级读取 LoopIterationDraftReport、RunLoopDraftReport、DispatchReport、ExecutionPlanReport、ControllerReport、AppRunReport、RunBoundaryReport 或 lower-level readiness / platform / lifecycle facts。

## Still Not Opened

- 不是 app lifecycle execution。
- 不是 window lifecycle execution。
- 不是 app/window state mutation。
- 不是 platform callback。
- 不是 queue / drain。
- 不是 event loop。
- 不是 public API / C ABI。

## Owner Handoff Decision

可以开始定义 internal-only lifecycle owner handoff draft。下一层应把 owner-specific draft facts 切回 lifecycle owner modules：

- app lifecycle owned draft 放在 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj`。
- window lifecycle owned draft 放在 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj`。
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj` 只负责把 `CjguiInternalLifecycleWorkDraftReport` 交给 owner-facing handoff draft，并保留 cross-owner routing summary。

这不是进入真实 lifecycle mutation。下一刀只能定义 owner-facing draft facts / request / report，不能执行 app lifecycle、window lifecycle、state mutation、queue / drain 或 platform callback。

## Recommended Next Opening

`P1 lifecycle owner handoff draft bundle implementation`

## Next Slice Authorization Suggestion

Prompt weight: W3 internal subsystem draft.

允许下一刀一次完成：

- `app_lifecycle.cj`
  - `CjguiInternalAppLifecycleWorkHandoffDraft`
  - builder / evaluator / sanity
- `window_lifecycle.cj`
  - `CjguiInternalWindowLifecycleWorkHandoffDraft`
  - builder / evaluator / sanity
- `runtime_state.cj`
  - owner handoff request / report
  - 只做 routing summary，消费 `CjguiInternalLifecycleWorkDraftReport`

禁止下一刀打开：

- real app/window lifecycle mutation
- modifying existing app/window state fields
- public API / C ABI
- queue / drain
- platform callback
- window create / close / destroy
- AppKit / Metal bridge

## Owner Recommendation

App lifecycle owner-specific facts should live in `app_lifecycle.cj`。

Window lifecycle owner-specific facts should live in `window_lifecycle.cj`。

`runtime_state.cj` may host the cross-owner routing summary but must not own lifecycle semantics.
