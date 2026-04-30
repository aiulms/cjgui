# P1 Action Dispatch Next Boundary Decision

Date: 2026-04-30

## Current Landed Facts

- Action Router dispatch admission is closed.
- Current internal-only runway is `ActionIntent -> ActionAdmission -> ActionRoutingResult -> ActionDispatchAdmission`.
- `CjguiInternalActionDispatchAdmission` consumes only `CjguiInternalActionRoutingResult`.
- Open path requires route candidate + preserved route + no defer / blocked flags.
- Defer-only remains deferred; blocked or inconsistent flags fail closed.
- There is still no action execution, AI provider / prompt / external agent, public API / C ABI, queue storage / enqueue / drain, event loop / scheduler / platform callback, or runtime cycle execution.

## Candidate Comparison

- A. `P1 internal Action Router dispatch plan boundary bundle implementation`: recommended. Dispatch admission can now feed a value-style dispatch plan summary without executing an action or writing queue state.
- B. Direct action execution: deferred. The system has admission but not a plan / commit / execution guard, so execution would skip governance boundaries.
- C. Queue enqueue / drain: deferred. Queue remains admission readiness only; storage / drain would move too close to event loop and scheduler implementation.
- D. AI provider / semantic projection: deferred. Action Router is still an internal runtime contract and must not attach model, prompt, external agent, or public surface.

## Decision

Choose A: move next to internal Action Router dispatch plan.

Dispatch plan is the right next boundary because it consumes the already closed `CjguiInternalActionDispatchAdmission` and produces only a value-style plan candidate / defer / blocked summary. It creates a guardable step before any future execution boundary and keeps action execution, queue write, provider attachment, and runtime cycle execution out of scope.

## Approved Next Opening

`P1 internal Action Router dispatch plan boundary bundle implementation`

## Guardrails For Next Implementation

- Default owner / write set: `runtime/cjgui/src/action_router.cj` plus docs.
- Only consume `CjguiInternalActionDispatchAdmission`.
- Only express dispatch plan candidate / defer / blocked.
- Do not execute an action.
- Do not write queue storage, enqueue, or drain.
- Do not attach AI provider, model, prompt, or external agent.
- Do not add public API / C ABI.
- Do not attach event loop, scheduler, or platform callback.
- Do not call or execute runtime cycle.
- Do not touch `runtime_state.cj`; if future work proves this unavoidable, run file-size / owner split check first and explain why.
- Do not reintroduce Request + Report double layer, five-piece sanity bundle, or wrapper chain.

## Verification Note

This round is docs-only. Do not run `cjpm build` or smoke guard for this decision; run `git diff --check`, link checks, absolute markdown target checks, and forbidden-file checks.
