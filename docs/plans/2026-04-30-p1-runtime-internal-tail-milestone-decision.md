# P1 Runtime Internal Tail Milestone Decision

Date: 2026-04-30

## Current Landed Facts

- Default runtime tail endpoint is `cjguiInternalExecuteDefaultRuntimeTailDraft()`.
- That endpoint returns `CjguiInternalRuntimeExecutionStateLoopClosure`.
- Loop closure consumes `CjguiInternalRuntimeExecutionStateIntegration` and prepares a next internal cycle request candidate without executing it.
- Old replay / replay outcome / admission / dry-run core symbols are now legacy diagnostics / trace, not the default path.
- Old default-path open sanity helpers for replay / outcome / admission / dry-run have been removed.

## Milestone Decision

P1 runtime internal tail has reached a milestone baseline. The project should not continue indefinite old-tail cleanup or add another behavior wrapper just to rename the tail.

Before opening platform callbacks, event loop / queue, global runtime state, or public API, the next step should stabilize the internal tail manifest and docs so later runtime boundary work has a compact, auditable baseline.

## Approved Next Opening

`P1 runtime internal tail milestone stabilization bundle implementation`

## Allowed Next Scope

- Create or update a concise manifest of main tail symbols and legacy diagnostics symbols.
- Compress runtime README tail-history wording.
- Keep `GUI_TASK_TRACKER.md` as a current-state dashboard.
- Optionally add light owner section comments / grouping in `runtime_state.cj` if it improves navigation.
- Optionally remove small dead helpers if impact is LOW and behavior-preserving.

## Guardrails

- No public API / C ABI.
- No platform callback, event loop, queue, drain, or scheduler.
- No global runtime state write or global mutable singleton.
- No second cycle execution and no new `cjguiInternalExecuteRuntimeCycle` call site.
- No new Request + Report layer.
- No five-piece sanity helper bundle.
- No replay / admission / dry-run wrapper revival.

## Verification Note

This round is docs-only. Run `git diff --check`, link checks, and forbidden-scope checks only; do not run build or smoke unless runtime source is edited.
