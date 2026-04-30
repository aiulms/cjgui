# P1 Action Boundary Next Decision

Date: 2026-04-30

## Current Landed Facts

- Action Router owner file is `runtime/cjgui/src/action_router.cj`.
- Current mainline is `ActionIntent -> ActionAdmission -> ActionRoutingResult -> ActionDispatchAdmission -> ActionDispatchPlan -> ActionDispatchConvergence -> ActionDispatchCommitCandidate -> ActionDispatchFinalization`.
- The dispatch convergence bundle landed convergence / commit candidate / finalization as adjacent value-style stages.
- The bundle is not wrapper rebound: no Request + Report double layer, no five-piece sanity, and no wrapper chain.
- Current finalization is still an internal value-style boundary summary, not action execution.
- There is still no queue storage / enqueue / drain, AI provider / prompt / external agent, public API / C ABI, event loop / scheduler / platform, runtime cycle execution, or runtime global state write.
- `runtime_state.cj` remains at 10065 lines in critical warning range and must not receive Action Router symbols.

## Candidate Comparison

- A. `P1 internal Action Router dispatch record / manifest stabilization bundle implementation`
  Recommended. Dispatch finalization now exists, so the next step should freeze owner / truth / stop-lines with a lightweight record or manifest rather than jump to execution.
- B. Direct action execution
  Deferred. Finalization is a value summary, not execution authorization; action effect model, queue commit, and execution policy are still absent.
- C. Queue enqueue / drain
  Deferred. Queue currently has admission readiness only; storage / drain would jump too close to event loop and scheduler truth.
- D. AI provider / semantic projection
  Deferred. Action Router is still an internal runtime contract and must not connect to model, prompt, external agent, or public surface yet.

## Decision

Choose A: `P1 internal Action Router dispatch record / manifest stabilization bundle implementation`.

This keeps the next slice close to the newly landed dispatch finalization, records the Action Router dispatch boundary as internal value truth, and prevents premature execution / queue / provider work.

## Approved Next Opening

`P1 internal Action Router dispatch record / manifest stabilization bundle implementation`

## Guardrails For Next Implementation

- Default owner / write set: `runtime/cjgui/src/action_router.cj` + docs.
- A lightweight value-style dispatch record may consume `CjguiInternalActionDispatchFinalization`.
- Action Router manifest may be added or updated to freeze the current runway and stop-lines.
- Only 1-2 pure derived helpers are allowed.
- No action execution.
- No queue storage / enqueue / drain.
- No AI provider / prompt / external agent.
- No public API / C ABI.
- No event loop / scheduler / platform callback.
- No runtime cycle execution.
- No `runtime_state.cj` modification unless a future prompt first performs mandatory file-size / owner split check and explains why touching it is unavoidable.
- No Request + Report double layer, five-piece sanity bundle, or wrapper chain rebound.

## Verification Note

- This round is docs-only, so `cjpm build` and smoke guard were intentionally not run.
- Required checks are `git diff --check`, link check, Markdown absolute-link check, and forbidden-file check.
