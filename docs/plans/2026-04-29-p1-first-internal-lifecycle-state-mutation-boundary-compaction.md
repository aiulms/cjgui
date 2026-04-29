# P1 First Internal Lifecycle State Mutation Boundary Compaction

日期：2026-04-29

## Context

本轮压缩现有 lifecycle mutation apply draft 结论，并判断下一刀是否可以首次进入 actual internal lifecycle state mutation。读取的 recent closure / compaction 文件均存在，未使用 fallback。

本轮不写 runtime code，不创建 preflight / execution card，不进入 public API / C ABI、platform callback、queue、drain 或 event loop。

## Current Apply Capability

- App apply facts live in `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj` as `CjguiInternalAppLifecycleMutationApplyDraft`。
- Window apply facts live in `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj` as `CjguiInternalWindowLifecycleMutationApplyDraft`。
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj` only owns the cross-owner apply summary through `CjguiInternalLifecycleMutationApplyRequest` / `CjguiInternalLifecycleMutationApplyReport`。
- Apply consumes `CjguiInternalLifecycleMutationCommitGateReport.appCommitGate` / `windowCommitGate` only, then projects owner apply intent facts.
- Apply expresses `shouldApplyMutation` / `shouldDeferApply` / `shouldReportApplyBlocked` only.
- Open、runtime-blocked、input-blocked、shutdown-blocked、cancellation-blocked paths exist; blocked paths fail closed as defer-apply + blocked-apply for both app and window apply facts.

## Still Not Opened

- 不是 app lifecycle mutation。
- 不是 window lifecycle mutation。
- 不是 app/window state change。
- 不是 transition execution。
- 不是 queue / drain。
- 不是 event loop。
- 不是 platform callback。
- 不是 public API / C ABI。

## First Mutation Decision

可以考虑进入 first actual internal lifecycle state mutation，但必须极窄。

下一刀只允许 owner-local immutable-state-copy transition：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj` 从 `CjguiInternalAppLifecycleMutationApplyDraft` + `CjguiInternalAppLifecycleState` 生成新的 `CjguiInternalAppLifecycleState`。
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj` 从 `CjguiInternalWindowLifecycleMutationApplyDraft` + `CjguiInternalWindowLifecycleState` 生成新的 `CjguiInternalWindowLifecycleState`。
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj` 只能做 cross-owner mutation result summary，消费 apply report 与 prior app/window states，不得直接修改 app/window state。

仍然禁止 var mutation、in-place mutation、platform callback、queue / drain、event loop、window create / close / destroy、public API / C ABI、改变既有 state field semantics。

## Expected Safe Mutation Semantics

- App open path 可以返回 `CjguiInternalAppLifecycleState(true, true, state.hasObservedPlatformReady)`，或由下一刀基于当前字段给出同等极窄且可验证的最小语义。
- Window open path 可以返回 `CjguiInternalWindowLifecycleState(true, state.hasObservedPlatformReady)`。
- Blocked path 必须返回原 state unchanged。
- 如果 constructor / field shape 无法安全支持上述语义，下一刀必须 fail closed，不得创造新的 state truth 或扩大字段含义。

## Why This Is Higher Risk

- 这是第一次可能产生新的 lifecycle state values。
- 它仍是 internal-only，但会从 draft / intent 进入 state transition semantics。
- 因此下一刀的验证必须同时覆盖 open path 与 blocked path，并确认 blocked path 保持原 state unchanged。

## Recommended Next Opening

`P1 first internal lifecycle state mutation bundle implementation`

## Next Slice Authorization Suggestion

Prompt weight: W3 high-risk internal mutation slice。

允许下一刀一次完成：

- `app_lifecycle.cj`
  - `CjguiInternalAppLifecycleMutationResult`
  - owner-local apply function returning new `CjguiInternalAppLifecycleState`
  - open / blocked sanity
- `window_lifecycle.cj`
  - `CjguiInternalWindowLifecycleMutationResult`
  - owner-local apply function returning new `CjguiInternalWindowLifecycleState`
  - open / blocked sanity
- `runtime_state.cj`
  - cross-owner mutation result request / report
  - consume `CjguiInternalLifecycleMutationApplyReport` and prior app/window states

禁止下一刀打开：

- public API / C ABI
- platform callback
- queue / drain
- event loop
- in-place mutation
- changing existing state field semantics
- window create / close / destroy
- AppKit / Metal bridge

## Owner Recommendation

App state mutation semantics must live in `app_lifecycle.cj`。

Window state mutation semantics must live in `window_lifecycle.cj`。

`runtime_state.cj` may host a cross-owner mutation result summary but must not directly own or mutate app/window lifecycle state。
