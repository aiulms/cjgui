# P1 Queue Handoff Gate Next Boundary Decision

## Current Landed Facts

- Tail Endpoint Exit Gate is active.
- `runtime_queue_handoff.cj` is the queue-side handoff consumer owner file.
- Current runway: `CjguiInternalActionHandoffQueueCandidate` -> `CjguiInternalQueueHandoffConsumer` -> `CjguiInternalQueueHandoffAcceptance` -> `CjguiInternalQueueHandoffGate`.
- `CjguiInternalQueueHandoffGate` is an internal value-style queue-side gate fact only.
- No queue storage, enqueue, drain, scheduler task, event loop task, runtime cycle, runtime global state write, public API / C ABI, provider, model session, public audit, or real action execution is approved.
- `runtime_state.cj` remains 10065 lines and in critical warning.

## Candidate Comparison

- A. Queue handoff gate milestone / manifest stabilization: safe, but it would pause forward movement after a clear gate endpoint.
- B. Queue permission gate boundary: best next step because `CjguiInternalQueueHandoffGate` naturally feeds an enqueue-before-permission model while still forbidding queue storage, enqueue, and drain.
- C. Queue staging model boundary: useful later, but it is closer to queue item shape and should follow permission / policy facts.
- D. Queue drain preflight: too early; it risks drifting into scheduler / event loop territory before enqueue permission is modeled.
- E. Queue handoff tail consolidation: only appropriate if concrete dead helpers or duplicate projections are found; this decision found no required cleanup target.

## Decision

Choose B: `P1 internal Queue permission gate boundary bundle implementation`.

This is a forward move, not safety theater. The current gate has enough shape to define enqueue-before-permission facts. It is still not queue storage, enqueue side effect, drain, scheduler, event loop, runtime cycle, or runtime mutation.

## Approved Next Opening

`P1 internal Queue permission gate boundary bundle implementation`

## Guardrails For Next Implementation

- Default owner/write set: prefer new `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_permission.cj` plus docs.
- Do not touch `runtime_state.cj`.
- Do not extend `runtime_queue_handoff.cj` with gate receipt / record / outcome / readiness thin tail wrappers.
- Consume only `CjguiInternalQueueHandoffGate`.
- Express enqueue-before-permission / policy gate value facts only.
- No queue storage, enqueue side effect, drain, scheduler implementation, event loop, runtime cycle, runtime global state write, real action side effect, platform callback, provider, prompt, external agent, model session, public API, or C ABI.
- No Request+Report double layer and no five-piece sanity bundle.

## Verification Note

- This round is docs-only, so `cjpm build` and smoke guard were not run.
- Required checks: `git diff --check`, README / tracker / plans README next-opening lookup, Markdown absolute-link check, and forbidden-file guard.
- `CANGJIE_ISSUE_LEDGER.md` was not updated because no new Cangjie language / SDK / FFI / toolchain / docs issue was found.
