# P1 Lifecycle Mutation Plan Draft Boundary Compaction

日期：2026-04-29

## Context

本轮压缩现有 lifecycle mutation readiness draft 结论，并判断下一刀是否可以进入 lifecycle mutation plan draft。读取的 recent closure / compaction 文件均存在，未使用 fallback。

本轮不写 runtime code，不创建 preflight / execution card，不进入 public API / C ABI、真实 lifecycle mutation、platform callback、queue 或 event loop。

## Current Mutation Readiness Capability

- App mutation readiness facts live in `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj` as `CjguiInternalAppLifecycleMutationReadinessDraft`。
- Window mutation readiness facts live in `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj` as `CjguiInternalWindowLifecycleMutationReadinessDraft`。
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj` only owns the cross-owner readiness summary through `CjguiInternalLifecycleMutationReadinessRequest` / `CjguiInternalLifecycleMutationReadinessReport`。
- Mutation readiness consumes `CjguiInternalLifecycleOwnerHandoffReport.appDraft` / `windowDraft` only, then projects owner readiness facts.
- Readiness expresses `canMutate` / `shouldDefer` / `shouldReportBlocked` only.
- Open、runtime-blocked、input-blocked、shutdown-blocked、cancellation-blocked paths exist; blocked paths fail closed as defer + blocked for both app and window readiness.

## Still Not Opened

- 不是 app lifecycle mutation。
- 不是 window lifecycle mutation。
- 不是 app/window state change。
- 不是 transition execution。
- 不是 queue / drain。
- 不是 event loop。
- 不是 platform callback。
- 不是 public API / C ABI。

## Mutation Plan Draft Decision

可以开始定义 internal-only lifecycle mutation plan draft。

下一刀应继续保持 owner split：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj` 可以从 `CjguiInternalAppLifecycleMutationReadinessDraft` 派生 app mutation plan summary。
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj` 可以从 `CjguiInternalWindowLifecycleMutationReadinessDraft` 派生 window mutation plan summary。
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj` 可以继续只做 cross-owner mutation plan routing summary，消费 mutation readiness report，但不得拥有 lifecycle mutation semantics。

这仍然不是 lifecycle mutation。下一刀不能修改 app/window state，不能调用 existing state-changing transition functions 来改变 state，不能进入 platform callback、queue / drain、event loop 或 public surface。Plan draft 只能表达 `shouldPlanMutation` / `shouldDeferPlan` / `shouldReportPlanBlocked`。

## Recommended Next Opening

`P1 lifecycle mutation plan draft bundle implementation`

## Next Slice Authorization Suggestion

Prompt weight: W3 internal subsystem draft。

允许下一刀一次完成：

- `app_lifecycle.cj`
  - `CjguiInternalAppLifecycleMutationPlanDraft`
  - builder / evaluator / sanity
- `window_lifecycle.cj`
  - `CjguiInternalWindowLifecycleMutationPlanDraft`
  - builder / evaluator / sanity
- `runtime_state.cj`
  - cross-owner mutation plan request / report
  - 只消费 mutation readiness report，不越级读取 owner handoff report 或 lower-level facts

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

App mutation plan facts live in `app_lifecycle.cj`。

Window mutation plan facts live in `window_lifecycle.cj`。

`runtime_state.cj` may host the cross-owner mutation plan summary but must not own lifecycle mutation semantics。
