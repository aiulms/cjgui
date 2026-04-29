# P1 Lifecycle State Mutation Outcome Boundary Compaction

日期：2026-04-29

## Context

本轮压缩 first internal lifecycle state mutation 结论，并判断下一刀是否可以进入 lifecycle state mutation outcome draft。读取的 closure / compaction 文件均存在，未使用 fallback。

本轮不写 runtime code，不创建 preflight / execution card，不进入 public API / C ABI、platform callback、queue、event loop 或 real window lifecycle 实现。

## Current First Mutation Capability

- App owner mutation result lives in `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj` as `CjguiInternalAppLifecycleMutationResult`。
- Window owner mutation result lives in `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj` as `CjguiInternalWindowLifecycleMutationResult`。
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj` only owns the cross-owner mutation result summary through `CjguiInternalLifecycleStateMutationRequest` / `CjguiInternalLifecycleStateMutationReport`。
- Open path app next state is `CjguiInternalAppLifecycleState(true, true, state.hasObservedPlatformReady)`。
- Open path window next state is `CjguiInternalWindowLifecycleState(true, state.hasObservedPlatformReady)`。
- Blocked / deferred path returns the original state unchanged。
- The slice uses no `var`, no in-place mutation, and no existing state-changing transition-function call。

## Still Not Opened

- 不是 public lifecycle API。
- 不是 platform lifecycle behavior。
- 不是 app run / shutdown。
- 不是 window create / close / destroy。
- 不是 event loop。
- 不是 queue / drain。
- 不是 renderer / input / layout behavior。

## Mutation Outcome Draft Decision

可以开始定义 internal-only lifecycle state mutation outcome draft。

Outcome draft 应消费 `CjguiInternalLifecycleStateMutationReport`，只能聚合 / 验证 already-produced mutation result：

- `didMutateApp`
- `didMutateWindow`
- `didMutateBothOwners`
- `didPreserveBlockedState`
- `shouldReportMutationBlocked`

它不能执行新的 mutation，不能修改 state，不能调用 owner transition function。它也不能绕过 `CjguiInternalLifecycleStateMutationReport` 去读取 ApplyReport、CommitGate、MutationPlan、MutationReadiness、OwnerHandoff 或 lower-level facts。

## Recommended Next Opening

`P1 lifecycle state mutation outcome draft bundle implementation`

## Next Slice Authorization Suggestion

Prompt weight: W3 internal subsystem draft。

允许下一刀一次完成：

- `runtime_state.cj`
  - `CjguiInternalLifecycleStateMutationOutcomeRequest`
  - `CjguiInternalLifecycleStateMutationOutcomeReport`
  - builder / evaluator / default executor
  - open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked sanity

禁止下一刀打开：

- new app/window state mutation
- modifying existing app/window state fields
- invoking state-changing transition functions
- public API / C ABI
- queue / drain
- platform callback
- window create / close / destroy
- AppKit / Metal bridge

## Owner Recommendation

Outcome summary can live in `runtime_state.cj` because it aggregates already-produced owner mutation results。

App/window owner modules should not receive new mutation semantics in the next slice unless outcome verification proves a strictly necessary owner-local fact is missing。
