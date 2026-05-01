# P1 Queue Enqueue Dry-Run Next Storage Boundary Decision

## Current Landed Facts

- Tail Endpoint Exit Gate is active.
- `runtime_queue_enqueue.cj` is the queue enqueue dry-run owner file.
- Current runway: `CjguiInternalQueueStagingReadiness` -> `CjguiInternalQueueEnqueueDryRunPlan` -> `CjguiInternalQueueEnqueueShadowCandidate` -> `CjguiInternalQueueEnqueueDryRunReadiness`.
- `CjguiInternalQueueEnqueueDryRunReadiness` is internal value-style dry-run readiness only.
- It is not queue storage, enqueue record, drain plan, scheduler task, event-loop task, runtime cycle, public audit log, or real action execution.
- `runtime_state.cj` remains 10065 lines and in critical warning.

## Candidate Comparison

- A. Queue enqueue dry-run milestone / manifest stabilization: lowest risk, but it would stop after a clear dry-run endpoint and would not move toward queue storage modeling.
- B. Queue value-style storage model boundary: best next step because it consumes dry-run readiness and models pending store / storage candidate / commit candidate facts without writing real queue storage or enqueueing.
- C. Queue enqueue commit gate: still side-effect-free, but it risks adding a permission tail without first defining the value-style storage shape the gate would protect.
- D. Queue real storage preflight: useful later, but real in-memory storage ownership / lifecycle is a higher-risk stateful boundary and should follow a value-style storage model.
- E. Queue drain / scheduler preflight: too early; enqueue dry-run has not yet produced storage-adjacent facts, and drain would move toward scheduler / event-loop stop-lines.
- F. Queue enqueue dry-run tail consolidation: only appropriate with concrete duplicate helpers or dead symbols; this decision found no cleanup target requiring a consolidation opening.

## Decision

Choose B: `P1 internal Queue value-style storage model boundary bundle implementation`.

This is not approval for real queue storage. It moves the queue runway from dry-run enqueue facts into storage-adjacent value facts while keeping the next slice dehydrated and side-effect-free. The next bundle should describe how an enqueue dry-run readiness would become a pending store / storage candidate / commit candidate, but must not allocate or mutate a real queue, create a global mutable singleton, enqueue, drain, schedule, or execute runtime cycles.

## Approved Next Opening

`P1 internal Queue value-style storage model boundary bundle implementation`

## Guardrails For Next Implementation

- Default owner/write set: prefer new `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_storage.cj` plus docs.
- Do not continue appending dry-run receipt / record / outcome / readiness wrappers to `runtime_queue_enqueue.cj`.
- Do not touch `runtime_state.cj`.
- Consume only `CjguiInternalQueueEnqueueDryRunReadiness`.
- Express internal value-style queue storage candidate / pending store / commit candidate facts only.
- The storage model is not a real queue storage write, not a global mutable queue, not an enqueue side effect, not an enqueue record, not a drain plan, not a scheduler task, and not a runtime cycle.
- No real action side effect, queue storage write, global mutable singleton, enqueue side effect, drain, AI provider, prompt, external agent, model session, public API, C ABI, event loop, scheduler, platform callback, runtime cycle, or runtime global state write.
- No Request+Report double layer, no five-piece sanity bundle, and no local thin tail wrapper.

## Verification Note

- This round is docs-only, so `cjpm build` and smoke guard are intentionally not run.
- Required checks: `git diff --check`, README / tracker / plans README lookup, Markdown absolute-link check, and forbidden-file guard.
- `CANGJIE_ISSUE_LEDGER.md` should remain unchanged unless a new Cangjie language / SDK / FFI / toolchain / docs issue is discovered.
