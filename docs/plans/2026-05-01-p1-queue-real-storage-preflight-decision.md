# P1 Queue Real Storage Preflight Decision

## Status

- Tail Endpoint Exit Gate is active.
- Queue value-style storage runway has reached `CjguiInternalQueueSnapshotPublicationCandidate`.
- Completed upstream queue path:
  `queue admission -> action handoff queue integration -> queue handoff consumer -> queue permission gate -> queue staging model -> enqueue dry-run / shadow plan -> value-style storage model -> storage commit gate -> committed snapshot value`.
- None of the above writes real queue storage, enqueues, drains, starts scheduler / event loop work, runs a runtime cycle, or mutates runtime global state.
- `runtime_state.cj` remains 10065 lines and in critical warning.

## Preflight Conclusion

Real queue storage may open a first bounded implementation, but only as an internal immutable value-store shell. The first cut must define owner / lifecycle / capacity / ordering / failure-readiness facts around a store snapshot and version marker. It must not write a real queue, create a global mutable singleton, enqueue, drain, call scheduler / event loop / platform, or mutate runtime state.

The correct next opening is:

`P1 internal Queue real storage owner/value-store boundary bundle implementation`

## 1. Owner

- The real storage owner should be a dedicated queue owner file, preferably `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_store.cj`.
- It should consume `CjguiInternalQueueSnapshotPublicationCandidate` as the only upstream input.
- It should not live in `runtime_state.cj` because that file is already 10065 lines and in critical warning, and queue storage would introduce ownership, lifecycle, and future mutation pressure that must stay split.
- It should not be folded into `runtime_queue.cj`; that file owns queue admission readiness, while real storage needs a separate lifecycle / capacity / ordering / rollback runway.
- Existing files such as `runtime_queue_snapshot.cj`, `runtime_queue_commit.cj`, and `runtime_queue_storage.cj` should be read-only unless a compile-required signature issue is explicitly recorded first.

## 2. Truth

- Minimal queue storage truth for the first cut:
  - store owner shell present;
  - immutable store snapshot candidate;
  - version marker or equivalent generation facts;
  - lifecycle marker such as initialized / deferred / blocked;
  - capacity policy facts;
  - ordering policy facts;
  - blocked / inconsistent state facts.
- `CjguiInternalQueueSnapshotPublicationCandidate` remains a value-style candidate, not stored queue state.
- The first implementation may create a real internal state value in the sense of an immutable queue store shell / snapshot value, but it must not be a persisted queue, a global singleton, or mutable runtime state.
- Item list / actual stored items should remain dehydrated or empty-shell facts in the first cut unless a later storage-write decision approves actual queue contents.

## 3. Mutability

- First cut must not allow `var`, in-place mutation, or global mutable queue storage.
- The store should be immutable-copy / value-style only.
- Mutation can be reconsidered only after a separate decision covers lifecycle ownership, capacity enforcement, rollback, failure recovery, and tests for mutation behavior.
- A later mutable implementation would need a much stronger owner split, rollback plan, and scheduler / drain stop-line review.

## 4. Capacity / Ordering

- Capacity should exist as value facts in the first cut, not as enforced mutable storage capacity.
- FIFO ordering should be declared as the intended ordering policy, but without drain / scheduler behavior.
- Duplicate guard may be represented as a policy fact or placeholder readiness, not as a real item de-duplication table.
- Actual ordering over stored items, capacity enforcement, and duplicate detection should wait until a real storage-write boundary is approved.

## 5. Failure / Rollback

- Enqueue failure is still out of scope because the first cut must not enqueue.
- Blocked or inconsistent store facts must fail closed as blocked.
- Rollback should be modeled as a future requirement and may appear as value facts, but there is no state mutation to roll back in the first cut.
- The first implementation should be a non-mutating store owner / snapshot / version marker candidate, not a storage write or commit.

## 6. Integration

- Input must only be `CjguiInternalQueueSnapshotPublicationCandidate`.
- The implementation must not bypass the canonical endpoint by reading lower-level permission / staging / enqueue / commit facts.
- It must not connect to runtime state, scheduler, drain, event loop, platform callback, or runtime cycle.
- Exact next stop-line:
  no real storage write, no global mutable queue, no enqueue, no drain, no scheduler / event loop / runtime cycle, no runtime global state write, no public API / C ABI, no provider / prompt / external agent.

## 7. Verification

- Required for next implementation:
  - `cjpm build --target-dir /tmp/cjgui-queue-real-storage-owner-value-store-boundary-target --skip-script`
  - `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
  - `git diff --check`
  - Markdown absolute link check
  - closure links from `GUI_TASK_TRACKER.md` and `docs/plans/README.md`
  - GitNexus impact before editing any existing symbol
  - GitNexus `detect_changes(scope=unstaged)`
  - forbidden file check
  - file-size / owner split guard for `runtime_state.cj`
- No new five-piece sanity helper should be added by default. If a small derived helper is needed, it must be used by the value pipeline or manifest and not become wrapper debt.

## Candidate Comparison

### A. P1 internal Queue real storage owner/value-store boundary bundle implementation

- Pros: owner / truth / mutability are now clear enough to proceed.
- Pros: opens a real storage runway without writing real queue storage or creating a global mutable queue.
- Pros: keeps the first cut bounded to immutable owner shell / store snapshot / version marker facts.
- Decision: selected.

### B. P1 internal Queue real storage preflight follow-up / manifest stabilization

- Pros: safest if owner / truth / mutability remain unclear.
- Cons: this preflight has resolved the minimum owner, truth, mutability, integration, and verification questions; another docs-only stabilization would likely stall.
- Decision: not selected.

### C. P1 internal Queue storage rollback/failure model boundary bundle implementation

- Pros: rollback and failure will matter before mutable queue writes.
- Cons: failure can be represented as fail-closed facts in the first owner/value-store shell; a standalone rollback model before any store shell would be premature.
- Decision: deferred.

### D. P1 internal Queue drain/scheduler preflight decision

- Pros: eventually needed once queue storage exists.
- Cons: too early and too close to scheduler / event loop before storage owner and lifecycle are bounded.
- Decision: deferred.

### E. P1 internal Queue storage-to-runtime state integration decision

- Pros: eventually needed for runtime cycle visibility.
- Cons: too close to `runtime_state.cj`, runtime global state, and runtime cycle. It should follow a storage owner / value-store shell, not precede it.
- Decision: deferred.

## Final Decision

Choose A:

`P1 internal Queue real storage owner/value-store boundary bundle implementation`

## Next Implementation Scope

- Default owner / write set:
  - `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_store.cj`
  - docs only as needed
- Input: only `CjguiInternalQueueSnapshotPublicationCandidate`.
- Suggested value-stage bundle:
  - `CjguiInternalQueueStoreOwner`
  - `CjguiInternalQueueStoreSnapshot`
  - `CjguiInternalQueueStoreVersionMarker` or equivalent endpoint
- The first cut may define immutable value-store shell / snapshot / version marker facts.
- The first cut must not write real queue storage, must not create a global mutable queue, must not enqueue, must not drain, and must not touch `runtime_state.cj`.

## Current Next Opening

`P1 internal Queue real storage owner/value-store boundary bundle implementation`
