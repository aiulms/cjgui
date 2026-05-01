# P1 Queue Permission Next Staging Decision

## Current Landed Facts

- Tail Endpoint Exit Gate is active.
- `runtime_queue_permission.cj` is the queue permission owner file.
- Current runway: `CjguiInternalQueueHandoffGate` -> `CjguiInternalQueuePermissionPolicy` -> `CjguiInternalQueuePermissionGate` -> `CjguiInternalQueuePermissionReadiness`.
- `CjguiInternalQueuePermissionReadiness` is enqueue-before internal permission / policy readiness facts only.
- No queue storage, enqueue record, enqueue side effect, drain plan, scheduler task, event-loop task, runtime cycle, runtime global state write, public API / C ABI, provider, model session, public audit, or real action execution is approved.
- `runtime_state.cj` remains 10065 lines and in critical warning.

## Candidate Comparison

- A. Queue permission milestone / manifest stabilization: lowest risk, but it would pause after a clear permission endpoint and would not move the queue runway forward.
- B. Queue staging model boundary: best next step because permission readiness naturally feeds value-style staging facts while still forbidding real queue storage, enqueue, and drain.
- C. Queue enqueue permission final gate: too close to permission self-wrapping right now; without a staging model it risks becoming another permission tail wrapper.
- D. Queue drain preflight: too early; it would move toward scheduler / event loop concerns before a staged queue shape exists.
- E. Queue permission tail consolidation: only appropriate if concrete duplicate helpers or dead symbols are found; this decision found no required cleanup target.
- F. Queue milestone plus staging decision hybrid: not better than B because the closure already fixed permission truth, and the next useful bounded implementation is staging.

## Decision

Choose B: `P1 internal Queue staging model boundary bundle implementation`.

This is a forward move, not safety theater. The permission endpoint has enough shape to feed a downstream staging model. The next slice must not add permission record / outcome / publication wrappers in `runtime_queue_permission.cj`; it should move to a staging owner and keep the facts value-style.

## Approved Next Opening

`P1 internal Queue staging model boundary bundle implementation`

## Guardrails For Next Implementation

- Default owner/write set: prefer new `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_staging.cj` plus docs.
- Do not touch `runtime_state.cj`.
- Do not extend `runtime_queue_permission.cj` with permission record / outcome / publication / readiness thin tail wrappers.
- Consume only `CjguiInternalQueuePermissionReadiness`.
- Express value-style queue staging model / staging candidate / staging readiness facts only.
- Staging facts are not queue storage, not enqueue authorization side effect, not enqueue record, not drain plan, not scheduler task, not event-loop task, not public audit, and not real action execution.
- No queue storage, enqueue side effect, drain, scheduler implementation, event loop, runtime cycle, runtime global state write, real action side effect, platform callback, provider, prompt, external agent, model session, public API, or C ABI.
- No Request+Report double layer and no five-piece sanity bundle.

## Verification Note

- This round is docs-only, so `cjpm build` and smoke guard were not run.
- Required checks: `git diff --check`, README / tracker / plans README next-opening lookup, Markdown absolute-link check, and forbidden-file guard.
- `CANGJIE_ISSUE_LEDGER.md` was not updated because no new Cangjie language / SDK / FFI / toolchain / docs issue was found.
