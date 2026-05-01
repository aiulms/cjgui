# P1 Queue Immutable Write Commit Next Storage Decision

## Current Facts

- `P1 internal Queue immutable store write commit boundary bundle implementation` is closed.
- New owner file exists: `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_store_commit.cj`.
- Current immutable queue write commit runway:
  `CjguiInternalQueueStoreWriteReadiness -> CjguiInternalQueueImmutableWriteCommit -> CjguiInternalQueueImmutableCommittedStore -> CjguiInternalQueueImmutableWriteCommitResult -> CjguiInternalQueueImmutableCommitPublicationCandidate`.
- `CjguiInternalQueueImmutableCommitPublicationCandidate` is an internal immutable value endpoint only. It is not a process-wide queue storage write, global mutable queue, enqueue record, drain plan, scheduler task, event loop task, runtime cycle, public audit log, or real action execution.
- Blocked / inconsistent paths preserve the previous snapshot and fail closed.
- `runtime_state.cj` remains 10065 lines and in critical warning; it must not be touched.

## Candidate Comparison

- A. `P1 internal Queue immutable write commit milestone / manifest stabilization bundle implementation`: lowest risk, but the immutable commit endpoint is already documented in the closure and manifest. Not chosen because it would slow the storage runway without adding missing semantics.
- B. `P1 internal Queue write failure / rollback model boundary bundle implementation`: chosen. It consumes only `CjguiInternalQueueImmutableCommitPublicationCandidate` and establishes write failure, rollback, and previous-snapshot preservation facts before any mutable storage preflight. This fills the most important safety gap before process-local storage is discussed.
- C. `P1 internal Queue real mutable storage preflight decision`: useful soon, but slightly early. The immutable commit publication candidate needs an explicit failure / rollback model first so later mutable storage can inherit a fail-closed rollback vocabulary.
- D. `P1 internal Queue process-local storage admission boundary bundle implementation`: too close to storage write admission without failure semantics. It remains possible after rollback is modeled, but choosing it now would skip the failure path.
- E. `P1 internal Queue runtime integration preflight decision`: premature. It would move toward `runtime_state.cj`, runtime cycle, or global state before queue write failure and rollback boundaries exist.
- F. `P1 internal Queue drain / scheduler preflight decision`: premature. Drain and scheduler require stable storage write semantics, failure handling, and ownership decisions first.
- G. `P1 internal Queue immutable commit tail consolidation bundle implementation`: not chosen because no concrete dead helper, repeated projection, or low-value symbol has been identified. Cleanup without a target would become churn.

## Decision

Choose B: `P1 internal Queue write failure / rollback model boundary bundle implementation`.

This is a queue storage-write boundary decision, not approval for process-wide mutable queue storage. The next implementation should model failure / rollback facts around the immutable commit publication candidate and explicitly preserve previous snapshots on blocked, inconsistent, or failed paths.

## Why This Is Not Thin Tail Wrapping

- The next boundary adds missing failure semantics required before mutable storage can be responsibly considered.
- It does not create a commit publication record, outcome wrapper, readiness wrapper, report wrapper, or public audit log.
- It should live in a new rollback / failure owner rather than extending `runtime_queue_store_commit.cj` with self-wrapping tail stages.

## Next Implementation Scope

- Default owner / write set: new `runtime/cjgui/src/runtime_queue_store_rollback.cj` or equivalently named queue write failure owner plus docs.
- Input: only `CjguiInternalQueueImmutableCommitPublicationCandidate`.
- Allowed output: write failure policy / rollback candidate / previous-snapshot preservation value facts.
- Allowed bundle shape: W2/W3 same-owner bundle; do not turn this into one-symbol micro-slicing.
- Required behavior:
  - open path: immutable commit publication candidate ready with no defer/block can mark rollback-not-required and preserve the committed immutable value facts.
  - defer-only path: preserves defer and does not fabricate failure or rollback completion.
  - blocked, failed, or inconsistent facts fail closed as blocked and preserve the previous snapshot.
- Required comments: Chinese owner / truth / stop-line header, Chinese comments for key boundary types, fail-closed / rollback branches, and default draft.

## Stop Lines

- No real action side effect.
- No process-wide queue storage write.
- No global mutable queue / singleton.
- No enqueue side effect.
- No drain.
- No AI provider / prompt / external agent / model session.
- No public API / C ABI.
- No event loop / scheduler / platform callback.
- No runtime cycle.
- No runtime global state write.
- No `runtime_state.cj` touch.
- No `runtime_queue_store_commit.cj` commit publication record / outcome / thin wrapper.

## Verification For This Decision

- `git diff --check`.
- README / GUI_TASK_TRACKER / docs/plans README can find this decision and next opening.
- Markdown absolute-link missing target check.
- Forbidden-file check confirms no runtime code or forbidden scope was modified.
- Docs-only round: no `cjpm build` / smoke guard required.
- `CANGJIE_ISSUE_LEDGER.md` not updated because no new Cangjie language / SDK / FFI / toolchain / docs issue was found.

## Current Next Opening

`P1 internal Queue write failure / rollback model boundary bundle implementation`
