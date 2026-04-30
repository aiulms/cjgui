# P1 Action Router Same-owner Bundle Runway Decision

## Current Landed Facts

- Action Router owner file is `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/action_router.cj`.
- Current runway is `ActionIntent -> ActionAdmission -> ActionRoutingResult -> ActionDispatchAdmission -> ActionDispatchPlan -> ActionDispatchConvergence -> ActionDispatchCommitCandidate -> ActionDispatchFinalization -> ActionDispatchRecord`.
- [Action Router manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-action-router-manifest.md) and [dispatch record / manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-internal-action-router-dispatch-record-manifest-stabilization-closure-review.md) are sealed.
- [AI resource-efficient bundle granularity governance](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-ai-resource-efficient-bundle-granularity-governance-update.md) is active: same owner / truth / write set / stop-line should default to W2 / W3 same-owner bundles.
- Current stop-lines still hold: no action execution, no queue storage / enqueue / drain, no AI provider / prompt / external agent, no public API / C ABI, no event loop / scheduler / platform callback, no runtime cycle execution, and no `runtime_state.cj` growth.

## Why Not Another Micro-slice

- The last Action Router steps intentionally protected stop-lines, but repeated one-symbol value stages now cost more context loading, GitNexus review, build / smoke time, and human review than they return.
- `no execution`, `no queue`, and `no provider` are boundary guards, not a rule that only one value type can land per implementation round.
- The next implementation should carry a coherent same-owner concept bundle or explicitly consolidate the tail; it should not produce another single value type + builder + helper opening.

## Candidate Comparison

- A. `P1 internal Action Router effect model / execution guard same-owner bundle implementation`: recommended. Dispatch record is stable enough to define internal effect category, execution guard, and execution readiness as one same-owner value bundle while still forbidding real execution.
- B. Action Router tail consolidation: reasonable fallback if implementation review finds low-value tail duplication, but the current manifest records a coherent dispatch boundary and does not require consolidation before the next capability runway.
- C. Direct action execution: rejected. There is no effect model, execution guard, or policy yet, so direct execution would skip the safety boundary.
- D. Queue enqueue / drain: deferred. Queue still only has admission readiness; storage / drain would move toward scheduler / event loop too early.
- E. AI provider / semantic projection: deferred. Action Router remains an internal runtime contract and must not attach model, prompt, external agent, or public surface.

## Decision

Choose A: enter a W3 same-owner internal Action Router effect model / execution guard bundle.

This is a resource-efficiency correction, not a high-risk boundary opening: the next slice may add a small adjacent set of internal value-style concepts in one owner file, but the same stop-lines remain hard.

## Approved Next Opening

`P1 internal Action Router effect model / execution guard same-owner bundle implementation`

## Guardrails For Next Implementation

- Default owner / write set: `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/action_router.cj` + docs.
- The implementation may add adjacent internal value-style concepts in one round, instead of one-symbol micro-slices.
- Suggested bundle: `CjguiInternalActionEffectModel`, `CjguiInternalActionExecutionGuard`, `CjguiInternalActionExecutionReadiness`, direct builders / default draft, and 1-2 pure derived helpers.
- Consume only `CjguiInternalActionDispatchRecord` or the current Action Router tail.
- Express only future action execution effect category / guard / readiness.
- Do not execute action.
- Do not write queue storage, enqueue, or drain.
- Do not connect AI provider, model, prompt, or external agent.
- Do not add public API / C ABI.
- Do not connect event loop, scheduler, platform callback, native handle, or raw pointer.
- Do not call runtime cycle or `cjguiInternalExecuteRuntimeCycle`.
- Do not touch critical `runtime_state.cj`; if future code reality proves otherwise, file-size / owner split check is mandatory before editing.
- Do not add Request+Report double layer, five-piece sanity, or wrapper-chain rebound.
- The closure must explain why the implementation is a W3 same-owner bundle, not another micro-slice.

## Verification Note

- This round is docs-only.
- Do not run `cjpm build` or smoke guard for this decision.
- Run `git diff --check`, link check, Markdown absolute-link target check, and forbidden-scope check.
