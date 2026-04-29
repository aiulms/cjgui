# P1 Runtime Next-Cycle Request Boundary Compaction

## Landed Facts

- CommittedStateStore draft consumes only `CjguiInternalRuntimeStateHolderDraft` and expresses committed app/window state with did-commit / defer / blocked summary.
- CycleFeedback draft consumes only `CjguiInternalRuntimeCommittedStateStoreDraft` and projects committed app/window state into next-cycle app/window state candidates.
- The current runtime chain still does not form a next runtime cycle request.
- There is still no next-cycle execution, event loop, queue / drain, scheduler, or runtime global state write.

## Still Not

- Not execution of `cjguiInternalExecuteRuntimeCycle`.
- Not runtime step execution.
- Not event loop / queue / drain / scheduler behavior.
- Not runtime global state write.
- Not app/window state mutation.
- Not public API / C ABI.
- Not platform callback.
- Not app run / shutdown.
- Not window create / close / destroy / release.

## Next-Cycle Request Draft Decision

The next slice may enter an internal-only / value-style runtime next-cycle request draft. It must consume only `CjguiInternalRuntimeCycleFeedbackDraft`.

The draft may express:

- next-cycle root state candidate
- next-cycle input candidate
- next-cycle policy candidate
- request allowed / defer / blocked summary

It may construct a value-style `CjguiInternalRuntimeCycleRequest` candidate, but must not execute it. It must not call `cjguiInternalExecuteRuntimeCycle`, execute runtime step, write runtime global state, mutate app/window state, or bypass CycleFeedbackDraft to read CommittedStateStoreDraft, StateHolderDraft, or lower-level facts.

## Owner Decision

- The owner should remain `runtime_state.cj` because this is a runtime-level next-cycle request summary.
- `app_lifecycle.cj` and `window_lifecycle.cj` should not own cross-owner cycle request construction.
- `platform_adapter.cj` and `runtime_bootstrap.cj` should not take over this owner boundary.

## Recommended Next Opening

`P1 runtime next-cycle request draft bundle implementation`

## Next Implementation Boundary

The next implementation may add:

- `CjguiInternalRuntimeNextCycleRequestDraftRequest`
- `CjguiInternalRuntimeNextCycleRequestDraft` or equivalent internal value type
- builder / evaluator / executor / default executor
- open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked sanity helpers

The next implementation may construct a value-style next-cycle `CjguiInternalRuntimeCycleRequest` candidate, but must not execute it. It must not add public API / C ABI, global mutable singleton, runtime global state write, event loop / queue / drain / scheduler, platform callback, app run / shutdown, window create / close / destroy / release, or state mutation. It must not modify `cjpm.toml`, smoke scripts, harness, native bridge, Cangjie entry, `src/main.cj`, or `package_anchor.cj`.

## Stop-Line

This compaction writes no runtime code and creates no preflight / execution card. It only records that a value-style internal next-cycle request draft is the next bounded opening, not cycle execution or scheduler implementation.
