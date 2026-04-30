# P1 Action Execution Or Queue Next Boundary Decision

Date: 2026-04-30

## Current Landed Facts

- Action Router manifest is closed and records `action_router.cj` as the owner file.
- Current internal-only runway is `ActionIntent -> ActionAdmission -> ActionRoutingResult`.
- `CjguiInternalActionAdmission` consumes `CjguiInternalQueueAdmission` as the downstream gate.
- Routing only produces a runtime boundary route candidate / defer / blocked result.
- There is still no action execution, AI provider / prompt / external agent, public API / C ABI, queue storage / enqueue / drain, event loop / scheduler, or runtime cycle execution.
- `runtime_state.cj` remains in critical warning range and must not receive Action Router growth.

## Candidate Comparison

- A. `P1 internal Action Router dispatch admission boundary bundle implementation`: recommended. Routing is stable enough to introduce a narrow dispatch-admission readiness value without executing an action or writing queue state.
- B. Direct action execution: deferred. Intent / admission / routing exist, but execution would skip a required dispatch-admission guard.
- C. Queue enqueue / drain: deferred. Queue admission is still a readiness value, not storage, enqueue, drain, scheduler, or event loop machinery.
- D. AI provider / semantic projection: deferred. Action Router remains an internal runtime contract and must not attach model, prompt, external agent, or public surface yet.

## Decision

Choose A: move next to internal Action Router dispatch admission.

Dispatch admission is the safe next boundary because it consumes the already stabilized `CjguiInternalActionRoutingResult` and turns a route candidate into dispatch readiness only. It is not action execution, does not bypass queue admission readiness, and does not create queue storage or runtime cycle execution.

## Approved Next Opening

`P1 internal Action Router dispatch admission boundary bundle implementation`

## Guardrails For Next Implementation

- Default owner / write set: `runtime/cjgui/src/action_router.cj` plus docs.
- Only consume `CjguiInternalActionRoutingResult`.
- Only express dispatch admission candidate / defer / blocked.
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
