# P1 Lifecycle Mutation Commit Gate Draft Boundary Compaction

日期：2026-04-29

## Context

本轮压缩现有 lifecycle mutation plan draft 结论，并判断下一刀是否可以进入 lifecycle mutation commit gate draft。读取的 recent closure / compaction 文件均存在，未使用 fallback。

本轮不写 runtime code，不创建 preflight / execution card，不进入 public API / C ABI、真实 lifecycle mutation、transition execution、platform callback、queue 或 event loop。

## Current Mutation Plan Capability

- App mutation plan facts live in `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj` as `CjguiInternalAppLifecycleMutationPlanDraft`。
- Window mutation plan facts live in `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj` as `CjguiInternalWindowLifecycleMutationPlanDraft`。
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj` only owns the cross-owner mutation plan summary through `CjguiInternalLifecycleMutationPlanRequest` / `CjguiInternalLifecycleMutationPlanReport`。
- Mutation plan consumes `CjguiInternalLifecycleMutationReadinessReport.appReadiness` / `windowReadiness` only, then projects owner plan facts.
- Plan expresses `shouldPlanMutation` / `shouldDeferPlan` / `shouldReportPlanBlocked` only.
- Open、runtime-blocked、input-blocked、shutdown-blocked、cancellation-blocked paths exist; blocked paths fail closed as defer-plan + blocked-plan for both app and window plans.

## Still Not Opened

- 不是 app lifecycle mutation。
- 不是 window lifecycle mutation。
- 不是 app/window state change。
- 不是 transition execution。
- 不是 commit。
- 不是 queue / drain。
- 不是 event loop。
- 不是 platform callback。
- 不是 public API / C ABI。

## Commit Gate Draft Decision

可以开始定义 internal-only lifecycle mutation commit gate draft。

下一刀应继续保持 owner split：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj` 可以从 `CjguiInternalAppLifecycleMutationPlanDraft` 派生 app commit gate summary。
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj` 可以从 `CjguiInternalWindowLifecycleMutationPlanDraft` 派生 window commit gate summary。
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj` 可以继续只做 cross-owner commit gate summary，消费 mutation plan report，但不得拥有 lifecycle mutation semantics。

这仍然不是 lifecycle mutation 或 commit execution。下一刀不能修改 app/window state，不能调用 existing state-changing transition functions，不能进入 platform callback、queue / drain、event loop 或 public surface。Commit gate draft 只能表达 `canEnterCommit` / `shouldDeferCommit` / `shouldReportCommitBlocked`。

## Recommended Next Opening

`P1 lifecycle mutation commit gate draft bundle implementation`

## Next Slice Authorization Suggestion

Prompt weight: W3 internal subsystem draft。

允许下一刀一次完成：

- `app_lifecycle.cj`
  - `CjguiInternalAppLifecycleMutationCommitGateDraft`
  - builder / evaluator / sanity
- `window_lifecycle.cj`
  - `CjguiInternalWindowLifecycleMutationCommitGateDraft`
  - builder / evaluator / sanity
- `runtime_state.cj`
  - cross-owner commit gate request / report
  - 只消费 mutation plan report，不越级读取 mutation readiness report、owner handoff report 或 lower-level facts

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

App commit gate facts live in `app_lifecycle.cj`。

Window commit gate facts live in `window_lifecycle.cj`。

`runtime_state.cj` may host the cross-owner commit gate summary but must not own lifecycle mutation semantics。
