# P1 Queue Mutable Store Next Write Decision

## Current Facts

- `P1 internal Queue mutable store shell boundary bundle implementation` is closed.
- New owner file exists: `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_mutable_store.cj`.
- Current mutable store shell runway:
  `CjguiInternalQueueWriteRollbackResult -> CjguiInternalQueueMutableStoreLifecycle -> CjguiInternalQueueMutableStoreHolder -> CjguiInternalQueueMutableStoreVersionMarker -> CjguiInternalQueueMutableStoreShell`.
- The implementation used function-local `var`: `selectedSnapshot`, `didPrepareHolder`, and `selectedVersion`.
- It did not add instance-local mutable holder fields, module-level `var`, global singleton, public mutable API, or cross-owner mutable references.
- `CjguiInternalQueueMutableStoreShell` remains owner-local value facts. It is not queue item collection mutation, process-wide queue storage write, enqueue, drain, scheduler / event loop task, runtime cycle, or runtime global state write.
- `runtime_state.cj` remains 10065 lines and in critical warning; it must not be touched.

## Candidate Comparison

- A. `P1 internal Queue mutable store shell milestone / manifest stabilization bundle implementation`: safe but not chosen. The shell closure already records the milestone and stop-lines, so another stabilization-only round would slow the mutable write runway without reducing a concrete risk.
- B. `P1 internal Queue mutable store write admission boundary bundle implementation`: chosen. It consumes the shell and adds the missing owner-local can-write / version-check / defer / blocked facts before any mutable write commit is considered.
- C. `P1 internal Queue owner-local mutable write commit boundary bundle implementation`: too early. A commit result would be easier to reason about after write admission has fixed the version-check and can-write truth.
- D. `P1 internal Queue mutable store rollback strengthening bundle implementation`: not chosen now. Rollback already preserves previous snapshot fallback; the current gap is write admission, not rollback token storage. Version mismatch can be modeled inside the write admission gate first.
- E. `P1 internal Queue enqueue surface preflight decision`: premature. Public/API/item semantics are still beyond the current storage-write boundary.
- F. `P1 internal Queue drain / scheduler preflight decision`: premature. Drain and scheduler require proven mutable write admission / commit semantics first.
- G. `P1 internal Queue mutable store tail consolidation bundle implementation`: not chosen because no concrete duplicate helper, dead symbol, or low-value projection has been identified.

## Decision

Choose B: `P1 internal Queue mutable store write admission boundary bundle implementation`.

This is the safest forward step because it advances toward mutable write capability while still refusing item collection mutation, process-wide storage write, enqueue, drain, public queue API, scheduler / event loop, runtime cycle, and runtime global state.

## Owner-Local Mutable State

Owner-local mutable state remains allowed, but only within the next bounded owner and only when needed for local value construction.

- Allowed: function-local `var` for can-write / version-check calculations.
- Allowed with caution: instance-local holder fields only if the holder remains internal, owner-local, and has no public mutable API.
- Forbidden: module-level `var`, global singleton, public mutable API, cross-owner mutable reference, real queue item collection mutation, process-wide storage write, runtime global state write, enqueue, or drain.

## Next Implementation Scope

- Recommended owner / write set: new `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_mutable_write.cj` plus docs.
- Input: only `CjguiInternalQueueMutableStoreShell`.
- Output: owner-local mutable write policy / version check / write admission / readiness value facts.
- Suggested adjacent concepts:
  - `CjguiInternalQueueMutableWritePolicy`
  - `CjguiInternalQueueMutableWriteVersionCheck`
  - `CjguiInternalQueueMutableWriteAdmission`
  - optional endpoint such as `CjguiInternalQueueMutableWriteReadiness` if it clarifies the canonical endpoint
- Default draft should start from `cjguiInternalExecuteDefaultQueueMutableStoreShellDraft()`.
- Open path: shell ready / owner-local / no defer / no blocked, version marker consistent, write admission open.
- Defer-only path: preserve defer and do not fabricate write readiness.
- Blocked / inconsistent path: fail closed blocked and preserve previous snapshot fallback facts.

## Stop Lines

- No real action side effect.
- No public enqueue API.
- No real queue item collection mutation.
- No process-wide queue storage write.
- No module-level `var`.
- No global mutable queue / singleton.
- No cross-owner mutable reference.
- No enqueue side effect.
- No drain.
- No scheduler / event loop / platform callback.
- No runtime cycle.
- No runtime global state write.
- No `runtime_state.cj` touch.
- No public API / C ABI.
- No AI provider / prompt / external agent / model session.

## Verification For This Decision

- `git diff --check`.
- README / GUI_TASK_TRACKER / docs/plans README can find this decision and next opening.
- Markdown absolute-link missing target check.
- Forbidden-file check confirms no runtime code or forbidden scope was modified in this docs-only round.
- Docs-only round: no `cjpm build` / smoke guard required.
- `CANGJIE_ISSUE_LEDGER.md` not updated because no new Cangjie language / SDK / FFI / toolchain / docs issue was found.

## Current Next Opening

`P1 internal Queue mutable store write admission boundary bundle implementation`
