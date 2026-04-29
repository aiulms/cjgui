# P1 Runtime Committed State Store Boundary Compaction

## Landed Facts

- Carry-forward draft only produces next app/window state candidates.
- Carried state container only wraps carried app/window state values.
- State holder draft consumes only `CjguiInternalRuntimeCarriedStateContainer` and expresses held app/window state with did-hold / defer / blocked summary.
- There is still no committed runtime global state store.

## Still Not

- Not a committed runtime global state store.
- Not a global mutable singleton.
- Not a public state API or public lifecycle result.
- Not a runtime global state write.
- Not a new app/window state mutation.
- Not a platform callback.
- Not queue / drain / scheduler / event loop behavior.
- Not app run / shutdown.
- Not window create / close / destroy / release.

## Committed State Store Draft Decision

The next slice may enter a first internal-only committed state store draft, but only as a value-style committed summary. It must consume only `CjguiInternalRuntimeStateHolderDraft`.

The draft may express:

- `committedAppState`
- `committedWindowState`
- `didCommitRuntimeState`
- `shouldDeferRuntimeStateCommit`
- `shouldReportRuntimeStateCommitBlocked`

It must not be a global mutable singleton. It must not write runtime global state, expose app/window state, execute new mutation, or bypass `CjguiInternalRuntimeStateHolderDraft` to read `CjguiInternalRuntimeCarriedStateContainer`, `CjguiInternalRuntimeStateCarryForwardReport`, publication reports, outcome reports, mutation reports, or lower-level facts.

## Owner Decision

- The owner should remain `runtime_state.cj` because this is a runtime-level committed summary.
- `app_lifecycle.cj` and `window_lifecycle.cj` should not own cross-owner runtime committed store summary.
- App/window owner files should keep owner-local lifecycle state facts, transitions, and owner draft facts.

## Recommended Next Opening

`P1 runtime committed state store draft bundle implementation`

## Next Implementation Boundary

The next implementation may add:

- `CjguiInternalRuntimeCommittedStateStoreRequest`
- `CjguiInternalRuntimeCommittedStateStoreDraft` or equivalent internal value type
- builder / evaluator / executor / default executor
- open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked sanity helpers

The next implementation must not add public API / C ABI, global mutable singleton, runtime global state write, event loop / queue / drain / scheduler, platform callback, app run / shutdown, window create / close / destroy / release, or new mutation. It must not modify `cjpm.toml`, smoke scripts, harness, native bridge, Cangjie entry, `src/main.cj`, or `package_anchor.cj`.

## Stop-Line

This compaction writes no runtime code and creates no preflight / execution card. It only records that a value-style internal committed state store draft is the next bounded opening, not a committed global runtime state implementation.
