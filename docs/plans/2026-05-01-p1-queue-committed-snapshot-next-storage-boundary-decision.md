# P1 Queue Committed Snapshot Next Storage Boundary Decision

## Status

- `P1 internal Queue committed snapshot value boundary bundle implementation` is closed.
- Current queue committed snapshot runway:
  `CjguiInternalQueueStorageCommitFinalizationCandidate -> CjguiInternalQueueCommittedSnapshot -> CjguiInternalQueueCommittedStateCandidate -> CjguiInternalQueueSnapshotPublicationCandidate`.
- `CjguiInternalQueueSnapshotPublicationCandidate` is only an internal value-style snapshot publication candidate.
- It is not a real queue storage write, runtime global state, global mutable queue, enqueue record, drain plan, scheduler task, event-loop task, runtime cycle, public audit log, or real action execution.
- Important bookkeeping: the previous implementation reported that `runtime_queue_snapshot.cj` already existed and matched the current index / HEAD, so the source owner was compiled and documented but the current git diff did not show a source delta.
- Tail Endpoint Exit Gate remains active: do not append snapshot receipt / snapshot record / snapshot outcome / thin wrapper to `runtime_queue_snapshot.cj`.

## Candidate Comparison

### A. P1 internal Queue committed snapshot milestone / manifest stabilization bundle implementation

- Pros: lowest risk; labels `QueueSnapshotPublicationCandidate` as the current value-style queue storage endpoint.
- Cons: does not advance the queue toward real storage readiness, and the milestone is already captured in tracker, manifest, and closure.
- Decision: not selected.

### B. P1 internal Queue real storage preflight decision

- Pros: the value-style queue storage runway has reached committed snapshot publication, so the next responsible move is to evaluate real storage prerequisites.
- Pros: can define owner, lifecycle, capacity, ordering, failure, rollback, verification, and extraction constraints before any storage write exists.
- Pros: keeps Tail Endpoint Exit Gate healthy by moving from snapshot self-wrapping to a storage-readiness decision.
- Safety: this is still docs-only preflight / decision and does not approve real queue storage write, global mutable queue, enqueue, drain, scheduler, event loop, runtime cycle, or global state write.
- Decision: selected.

### C. P1 internal Queue storage-to-runtime state integration decision

- Pros: eventually needed once a safe queue storage model exists.
- Cons: too close to critical `runtime_state.cj`, runtime global state, and runtime cycle integration before real storage ownership is even defined.
- Decision: deferred until after real storage preflight.

### D. P1 internal Queue drain / scheduler preflight decision

- Pros: eventually needed for queue consumption.
- Cons: too early; drain / scheduler should not be discussed before storage owner, ordering, capacity, failure, and rollback are bounded.
- Decision: deferred.

### E. P1 internal Queue committed snapshot tail consolidation bundle implementation

- Pros: useful if duplicate helpers or dead symbols are identified.
- Cons: no concrete compressible target is known; choosing cleanup without evidence would stall the storage runway.
- Decision: not selected.

### F. Alternative: P1 internal Queue enqueue commit implementation

- Pros: could look like the natural next step after committed snapshot.
- Cons: it would be too close to enqueue side effects without first defining real storage owner and lifecycle.
- Decision: not selected.

## Final Decision

Choose B:

`P1 internal Queue real storage preflight decision`

## Next Scope

- Nature: docs-only preflight / decision, not runtime implementation.
- Default write set: docs only unless a later explicit implementation opening says otherwise.
- Required topics:
  - queue storage owner candidate and owner split;
  - lifecycle and initialization boundary;
  - capacity / ordering / identity model;
  - failure / rollback / blocked semantics;
  - verification and smoke implications;
  - extraction strategy that avoids `runtime_state.cj` growth;
  - stop-line before real storage write.
- Must explicitly record that `CjguiInternalQueueSnapshotPublicationCandidate` is a value-style input, not a stored queue state.

## Stop Lines

- No real action side effect.
- No real queue storage write.
- No global mutable queue / singleton.
- No enqueue side effect.
- No drain.
- No AI provider / prompt / external agent / model session.
- No public API / C ABI.
- No event loop / scheduler / platform callback.
- No runtime cycle.
- No runtime global state write.
- No `runtime_state.cj` growth.
- No `runtime_queue_snapshot.cj` local thin-tail wrapper.

## Owner Split Guard

- `runtime_state.cj` remains at 10065 lines and in critical warning.
- The next preflight must not touch `runtime_state.cj`.
- The next preflight must not modify runtime `.cj` files.
- Any future real storage implementation must prefer a dedicated queue storage owner, not `runtime_state.cj` or a global mutable singleton.

## Current Next Opening

`P1 internal Queue real storage preflight decision`
