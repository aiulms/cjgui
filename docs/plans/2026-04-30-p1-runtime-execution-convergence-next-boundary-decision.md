# P1 Runtime Execution Convergence Next Boundary Decision

Date: 2026-04-30

## Current Landed Facts

- First internal execution attempt can execute exactly one `CjguiInternalRuntimeCycleRequest` candidate on the allowed path.
- `CjguiInternalRuntimeExecutionConvergenceReport` consumes `CjguiInternalRuntimeExecutionAttemptReport` and classifies the attempt as converged / deferred / blocked, with inconsistent combinations fail-closed blocked.
- The pure post-attempt outcome wrapper has been removed.
- `GUI_TASK_TRACKER.md` has been compacted into a current-state dashboard.

## Boundary Decision

Do not continue by adding outcome / replay / dry-run / admission wrapper layers.

The next implementation may enter commit candidate, but only as an internal-only value-style convergence step. Commit candidate must consume only `CjguiInternalRuntimeExecutionConvergenceReport` and express whether the already executed attempt / progress fact can become a future internal commit candidate.

It must not execute a new cycle, call `cjguiInternalExecuteRuntimeCycle`, execute runtime step, write global state, publish state, connect platform / queue / event loop / scheduler, or expose public API / C ABI.

## Next Opening

`P1 runtime execution convergence commit candidate bundle implementation`

## Guardrails

- No `cjguiInternalExecuteRuntimeCycle` call.
- No runtime step execution.
- No Request + Report double layer unless a hard language constraint forces it.
- No five-sanity helper bundle.
- No platform callback, event loop, queue / drain, or scheduler.
- No app run / shutdown.
- No window create / close / destroy / release.
- No public runtime API or public C ABI.
- If a type is added, it must be commit-candidate semantics, not another outcome report.

## Verification Note

This is a docs-only boundary decision. Build and smoke are intentionally not run. Verification is limited to `git diff --check`, entry link checks, absolute-link checks, and forbidden-file checks.
