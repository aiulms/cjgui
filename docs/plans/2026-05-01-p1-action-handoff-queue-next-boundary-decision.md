# P1 Action Handoff Queue Next Boundary Decision

## Current Landed Facts

- Tail Endpoint Exit Gate is active.
- `action_handoff_queue.cj` is the queue-adjacent handoff integration owner file.
- Current runway: `CjguiInternalActionHandoffReceipt` + `CjguiInternalQueueAdmission` -> `CjguiInternalActionHandoffQueueAdmission` -> `CjguiInternalActionHandoffQueueIntegration` -> `CjguiInternalActionHandoffQueueCandidate`.
- `CjguiInternalActionHandoffQueueCandidate` is an internal value-style queue-adjacent integration candidate only.
- No queue storage, enqueue, drain, event loop, scheduler task, platform callback, runtime cycle, public API / C ABI, provider, model session, or real action execution is approved.
- `runtime_state.cj` remains 10065 lines and in critical warning.

## Candidate Comparison

- A. Action Handoff queue integration milestone / manifest stabilization: lowest risk, but it would not move the queue-handoff endpoint toward a downstream owner.
- B. Queue owner handoff consumer boundary: best next step because it exits `action_handoff_queue.cj` self-wrapping and lets a queue-side owner consume `CjguiInternalActionHandoffQueueCandidate` without writing queue storage.
- C. Action Handoff queue permission gate: useful later, but it is closer to enqueue permission and should follow a queue-side consumer boundary.
- D. Action Handoff queue-to-runtime ingress: too cross-owner for this moment and risks sliding toward runtime cycle / scheduler / `runtime_state.cj`.
- E. Action Handoff queue tail consolidation: only appropriate if concrete dead helpers or duplicate projections are found; no such target is required for this decision.

## Decision

Choose B: `P1 internal Queue owner handoff consumer boundary bundle implementation`.

This is not safety theater and not a pause. The current queue-adjacent candidate has enough shape to be handed to a queue-side owner. The next slice should consume the candidate from a queue owner boundary instead of adding another local receipt / record / outcome / readiness wrapper in `action_handoff_queue.cj`.

## Approved Next Opening

`P1 internal Queue owner handoff consumer boundary bundle implementation`

## Guardrails For Next Implementation

- Default owner/write set: prefer new `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_handoff.cj` plus docs.
- Do not touch `runtime_state.cj`.
- Do not default to `runtime_queue.cj` unless code reality proves the new owner file is worse; if `runtime_queue.cj` is touched, file-size / owner split check is mandatory.
- Consume only `CjguiInternalActionHandoffQueueCandidate`.
- Express queue owner consumer / acceptance / gate value facts only.
- No queue storage, enqueue side effect, drain, scheduler implementation, event loop, runtime cycle, runtime global state write, real action side effect, platform callback, provider, prompt, external agent, model session, public API, or C ABI.
- No `action_handoff_queue.cj` local thin tail wrapper such as queue candidate receipt / record / outcome / readiness.
- No Request+Report double layer and no five-piece sanity bundle.

## Verification Note

- This round is docs-only, so `cjpm build` and smoke guard were not run.
- Required checks: `git diff --check`, README / tracker / plans README next-opening lookup, Markdown absolute-link check, and forbidden-file guard.
- `CANGJIE_ISSUE_LEDGER.md` was not updated because no new Cangjie language / SDK / FFI / toolchain / docs issue was found.
