# P1 Lifecycle Mutation Readiness Draft Boundary Compaction

日期：2026-04-29

## Context

本轮压缩现有 lifecycle owner handoff draft 结论，并判断下一刀是否可以进入 app/window lifecycle mutation readiness draft。读取的 recent closure / compaction 文件均存在，未使用 fallback。

本轮不写 runtime code，不创建 preflight / execution card，不进入 public API / C ABI、真实 lifecycle mutation、platform callback、queue 或 event loop。

## Current Owner Handoff Capability

- App owner draft lives in `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj` as `CjguiInternalAppLifecycleWorkHandoffDraft`。
- Window owner draft lives in `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj` as `CjguiInternalWindowLifecycleWorkHandoffDraft`。
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj` only owns the cross-owner routing summary through `CjguiInternalLifecycleOwnerHandoffRequest` / `CjguiInternalLifecycleOwnerHandoffReport`。
- Owner handoff consumes `CjguiInternalLifecycleWorkDraftReport.draft` only, then projects accept / defer / blocked handoff facts to app and window owner builders。
- Open、runtime-blocked、input-blocked、shutdown-blocked、cancellation-blocked paths exist; blocked paths fail closed as defer + blocked for both app and window owner drafts。

## Still Not Opened

- 不是 app lifecycle execution。
- 不是 window lifecycle execution。
- 不是 app/window state mutation。
- 不是 queue / drain。
- 不是 event loop。
- 不是 platform callback。
- 不是 public API / C ABI。
- 不是 window create / close / destroy。

## Mutation Readiness Draft Decision

可以开始定义 internal-only mutation readiness draft。

下一刀应保持 owner split：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj` 可以从 `CjguiInternalAppLifecycleWorkHandoffDraft` 派生 app mutation readiness summary。
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj` 可以从 `CjguiInternalWindowLifecycleWorkHandoffDraft` 派生 window mutation readiness summary。
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj` 可以继续只做 cross-owner readiness routing summary，消费 owner handoff report，但不得拥有 lifecycle mutation semantics。

这仍然不是 lifecycle mutation。下一刀不能修改 app/window state，不能调用 existing state-changing transition functions 来改变 state，不能进入 platform callback、queue / drain、event loop 或 public surface。Readiness draft 只能表达 `canMutate` / `shouldDefer` / `shouldReportBlocked`。

## Recommended Next Opening

`P1 lifecycle mutation readiness draft bundle implementation`

## Next Slice Authorization Suggestion

Prompt weight: W3 internal subsystem draft。

允许下一刀一次完成：

- `app_lifecycle.cj`
  - `CjguiInternalAppLifecycleMutationReadinessDraft`
  - builder / evaluator / sanity
- `window_lifecycle.cj`
  - `CjguiInternalWindowLifecycleMutationReadinessDraft`
  - builder / evaluator / sanity
- `runtime_state.cj`
  - cross-owner mutation readiness request / report
  - 只消费 owner handoff report，不越级读取 LifecycleWorkDraftReport 或 lower-level facts

禁止下一刀打开：

- real app/window lifecycle mutation
- modifying existing app/window state fields
- invoking existing state-changing transition functions
- public API / C ABI
- queue / drain
- platform callback
- window create / close / destroy
- AppKit / Metal bridge

## Owner Recommendation

App mutation readiness facts live in `app_lifecycle.cj`。

Window mutation readiness facts live in `window_lifecycle.cj`。

`runtime_state.cj` may host the cross-owner mutation readiness summary but must not own lifecycle mutation semantics。
