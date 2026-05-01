# P1 Action Router Handoff Endpoint Next Boundary Decision

## Current Landed Facts

- Tail Endpoint Exit Gate is active.
- Current Action Router canonical endpoint is `CjguiInternalActionGuardedExecutionHandoffCandidate` via `cjguiInternalExecuteDefaultActionGuardedExecutionResultPublicationDraft()`.
- Current runway reaches `ActionIntent -> ... -> ActionGuardedExecutionResultPublication -> ActionGuardedExecutionHandoffCandidate`.
- `ActionGuardedExecutionHandoffCandidate` is internal value-style handoff facts only. It is not queue enqueue, queue drain, public audit, provider response, observer callback, platform callback, or real action execution.
- `runtime_state.cj` remains `10065` lines and in critical warning; this decision does not touch runtime code.

## Candidate Comparison

- A. `P1 internal Action Router handoff milestone closure / manifest stabilization bundle implementation`: lowest risk and would clearly close the milestone, but it does not make the canonical endpoint useful to a downstream boundary.
- B. `P1 internal Action Router handoff downstream consumer boundary bundle implementation`: consumes the canonical endpoint from a separate downstream owner and expresses receiver / acceptance facts without queue, enqueue, drain, or execution. This best matches the Tail Endpoint Exit Gate.
- C. `P1 internal Action Router real execution permission gate decision`: still value-style and could be safe with strong stop-lines, but it is closer to side effects and should wait until the handoff endpoint has a concrete internal consumer.
- D. `P1 internal Action Router tail consolidation bundle implementation`: valid only if there are clear dead helpers or duplicated projections. No specific compression target is established for this decision, so it should not be chosen just to look safe.
- E. `P1 internal Action Router observer/report publication boundary`: rejected because observer/report naming risks recreating a thin report wrapper and could be mistaken for public publication.

## Decision

Choose B: `P1 internal Action Router handoff downstream consumer boundary bundle implementation`.

This is not a continuation of Action Router local tail wrapping. It moves from a canonical endpoint to a downstream consumer boundary with a new owner/write set, while preserving the same internal value-style constraints. The next implementation should consume `CjguiInternalActionGuardedExecutionHandoffCandidate` and express handoff receiver / consumer acceptance facts only.

## Approved Next Opening

`P1 internal Action Router handoff downstream consumer boundary bundle implementation`

## Guardrails For Next Implementation

- Default owner/write set: new `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/action_handoff.cj` or equivalent downstream handoff owner file, plus docs.
- Do not default back into `action_router.cj`; only add imports / signatures there if code reality proves unavoidable and impact is checked first.
- Do not touch `runtime_state.cj`; if future work proves it absolutely necessary, run file-size / owner split check first and explain why the downstream owner cannot carry the boundary.
- Consume only `CjguiInternalActionGuardedExecutionHandoffCandidate`.
- Express internal handoff consumer / receiver / acceptance facts only.
- No real action execution or side effect.
- No queue storage, enqueue, or drain.
- No AI provider, prompt, external agent, or model session.
- No public API / C ABI.
- No event loop, scheduler, platform callback, observer callback, or runtime cycle.
- No runtime global state write.
- No Request+Report double layer, five-piece sanity, or new Action Router local thin tail wrapper.

## Verification Note

- This was a docs-only decision, so `cjpm build` and smoke guard were not run.
- Required checks: `git diff --check`, README / tracker / plans README lookup, Markdown absolute-link check, and forbidden-file check.
- `CANGJIE_ISSUE_LEDGER.md`: 未触发更新。
