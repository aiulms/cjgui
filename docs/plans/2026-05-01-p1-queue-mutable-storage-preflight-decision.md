# P1 Queue Mutable Storage Preflight Decision

## Current Facts

- `P1 internal Queue write failure / rollback model boundary bundle implementation` is closed.
- New owner file exists: `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_store_rollback.cj`.
- Current queue write failure / rollback runway:
  `CjguiInternalQueueImmutableCommitPublicationCandidate -> CjguiInternalQueueWriteFailurePolicy -> CjguiInternalQueueWriteRollbackPlan -> CjguiInternalQueueWriteRollbackResult`.
- Open path marks no failure, carries previous snapshot fallback, and reports rollback model ready / no rollback needed.
- Blocked / inconsistent path fails closed as blocked, marks rollback required, and preserves previous snapshot facts.
- `CjguiInternalQueueWriteRollbackResult` is not a real rollback side effect, process-wide queue storage write, global mutable queue, enqueue, drain, scheduler / event loop task, runtime cycle, public audit log, or real action execution.
- `runtime_state.cj` remains 10065 lines and in critical warning; it must not be touched.

## Owner / File

- The first mutable storage owner should be a new file: `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_mutable_store.cj`.
- It should not live in `runtime_state.cj` because that file is already critical-size, owns runtime state transition history, and would turn queue storage into runtime global state too early.
- It should not live in `runtime_queue.cj` because that file currently owns admission readiness only. Reusing it would mix queue admission with mutable storage lifecycle and blur the stop-line.
- The new owner may read only the rollback endpoint from `runtime_queue_store_rollback.cj`; it should not reach around into lower-level queue facts unless a later preflight explicitly approves it.

## State Shape

- Minimal mutable store truth is a process-local internal holder shell with lifecycle / snapshot / version facts derived from `CjguiInternalQueueWriteRollbackResult`.
- The first shape should carry:
  - rollback result input
  - current snapshot value
  - fallback previous snapshot value
  - version marker copied from the chosen snapshot
  - lifecycle facts such as initialized / deferred / blocked
  - mutation-admission facts saying whether the shell may hold the committed value
- It should not introduce a real queue item collection yet. Item list, capacity enforcement, FIFO storage, and duplicate guard can remain value facts until the mutable shell owner is proven safe.
- `CjguiInternalQueueStoreSnapshot` remains the source value for snapshot truth. The mutable shell may hold that value locally, but must not become process-wide storage.

## Mutability Boundary

- Owner-local mutable state is allowed in the next implementation, but only inside the new `runtime_queue_mutable_store.cj` owner.
- Allowed mutability: function-local `var` or instance-local holder fields used to initialize / update an internal shell during one value pipeline.
- Forbidden mutability: module-level `var`, global singleton, static mutable queue, public mutable API, cross-owner mutable reference, background worker, thread / coroutine state, or runtime global state write.
- The first implementation should prefer a narrow holder / shell with no public surface and no exported mutating API. Any mutation must be deterministic from the rollback result and must not escape as a process-wide singleton.

## Write Semantics

- The next implementation may model a mutable store shell accepting a snapshot value, but it must not perform a process-wide queue storage write.
- The shell may initialize current snapshot from the committed value when rollback result is ready / no rollback required.
- On rollback-required or blocked paths, the shell must preserve previous snapshot fallback and mark the shell blocked.
- This is not enqueue. It must not append an item, drain an item, expose queue length as authoritative process state, or create a scheduler-visible task.

## Rollback / Failure

- Input must be only `CjguiInternalQueueWriteRollbackResult`.
- The rollback result supplies the previous snapshot fallback and whether rollback is required.
- A rollback-required result should keep current snapshot at the fallback value and report blocked / rollback-required facts.
- A version check should be value-style in the first cut: compare / preserve version marker facts, but do not implement rollback token storage or mutable transaction log yet.
- A full rollback token / transaction log can be opened later, after the mutable shell owner and lifecycle are verified.

## Ordering / Capacity

- FIFO ordering should remain a value fact in the first mutable shell. Do not introduce a real item collection yet.
- Capacity can be recorded as a policy fact or default marker, but should not enforce real storage mutation in the first cut.
- Duplicate guard can remain a future fact. It should not scan or mutate a real collection yet.
- The first implementation should focus on snapshot lifecycle and rollback-safe holder facts, not item-level queue semantics.

## Integration Stop-Line

- Continue to forbid public enqueue API, queue drain, scheduler / event loop, platform callback, runtime cycle, runtime global state write, and `runtime_state.cj` edits.
- Continue to forbid process-wide queue storage write and global mutable singleton.
- Continue to forbid AI provider / prompt / external agent / model session and public API / C ABI.
- The next implementation may create an internal owner-local mutable shell, but the shell must not be globally reachable or scheduler-visible.

## Verification Plan

- Run GitNexus impact before modifying any existing symbol. New owner symbols may return UNKNOWN / not found and should be recorded.
- Run GitNexus `detect_changes(scope=unstaged)` after implementation.
- Run `cjpm build --target-dir /tmp/cjgui-queue-mutable-store-shell-boundary-target --skip-script`.
- Run `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`.
- Run `git diff --check`.
- Run markdown absolute-link missing target checks for docs touched.
- Run forbidden-file checks confirming no `runtime_state.cj`, `runtime_queue.cj`, scheduler / ingress, harness, native bridge, smoke tracked source, public entry, or build config changes.
- Check there is no module-level `var`, no global singleton, no public API / C ABI, and no enqueue / drain implementation in the new owner.

## Candidate Comparison

- A. `P1 internal Queue mutable store shell boundary bundle implementation`: chosen. The owner, truth, rollback source, mutability boundary, and stop-lines are now clear enough for a bounded implementation. It may allow owner-local `var`, but only inside a new `runtime_queue_mutable_store.cj` shell and never as global mutable queue.
- B. `P1 internal Queue mutable write admission boundary bundle implementation`: safe but too cautious after rollback is already modeled. A separate admission-only stage would risk another value tail before we test the actual owner-local mutable shell.
- C. `P1 internal Queue rollback-capable immutable store bridge bundle implementation`: safer, but it would keep the runway in immutable value facts and postpone the central question of owner-local mutability.
- D. `P1 internal Queue mutable storage manifest stabilization`: not chosen because owner / truth / mutability / verification are clear enough. A docs-only stabilization would be cautious without adding capability.
- E. `P1 internal Queue drain / scheduler preflight decision`: premature. Drain / scheduler require real storage lifecycle, item semantics, and mutation ownership to be proven first.
- F. `P1 internal Queue runtime state integration preflight`: premature and risky because it approaches `runtime_state.cj` and runtime global state before process-local queue ownership is isolated.

## Decision

Choose A: `P1 internal Queue mutable store shell boundary bundle implementation`.

This opens the first bounded mutable storage boundary, but only as a new-owner, process-local, internal mutable shell. It does not approve process-wide queue storage write, global mutable singleton, enqueue side effect, queue drain, scheduler / event loop integration, runtime cycle, runtime global state write, public API, or C ABI.

## Next Implementation Scope

- Default owner / write set: new `runtime/cjgui/src/runtime_queue_mutable_store.cj` plus docs.
- Input: only `CjguiInternalQueueWriteRollbackResult`.
- Allowed output: mutable store shell / holder / lifecycle / version marker facts.
- Owner-local mutable state: allowed only as function-local or instance-local state inside `runtime_queue_mutable_store.cj`.
- Forbidden mutable state: module-level `var`, static/global singleton, public mutable API, cross-owner mutable reference, runtime global state write, or real queue item collection mutation.
- Suggested adjacent concepts:
  - `CjguiInternalQueueMutableStoreShell`
  - `CjguiInternalQueueMutableStoreHolder`
  - `CjguiInternalQueueMutableStoreLifecycle`
  - optional endpoint such as `CjguiInternalQueueMutableStoreReadiness` if it is necessary for a clear canonical endpoint
- Required behavior:
  - open path: rollback result ready / no rollback needed initializes an owner-local mutable shell from the committed snapshot value and records lifecycle ready.
  - rollback-required or blocked path: preserves previous snapshot fallback and marks shell blocked / rollback required.
  - defer-only path: preserves defer and does not fabricate mutable store readiness.
- Required comments: Chinese owner / truth / stop-line header, Chinese comments for key mutable boundary types, fail-closed / rollback branches, and default draft.

## Stop Lines

- No real action side effect.
- No process-wide queue storage write.
- No global mutable queue / singleton.
- No public queue API.
- No enqueue side effect.
- No drain.
- No scheduler / event loop / platform callback.
- No runtime cycle.
- No runtime global state write.
- No `runtime_state.cj` touch.
- No `runtime_queue.cj` expansion unless a compile failure proves it is necessary and the reason is recorded first.
- No AI provider / prompt / external agent / model session.
- No public API / C ABI.

## Verification For This Decision

- `git diff --check`.
- README / GUI_TASK_TRACKER / docs/plans README can find this preflight / decision and next opening.
- Markdown absolute-link missing target check.
- Forbidden-file check confirms no runtime code or forbidden scope was modified.
- Docs-only round: no `cjpm build` / smoke guard required.
- `CANGJIE_ISSUE_LEDGER.md` not updated because no new Cangjie language / SDK / FFI / toolchain / docs issue was found.

## Current Next Opening

`P1 internal Queue mutable store shell boundary bundle implementation`
