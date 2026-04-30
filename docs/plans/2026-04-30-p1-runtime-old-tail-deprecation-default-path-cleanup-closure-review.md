# P1 Runtime Old Tail Deprecation / Default-Path Cleanup Closure Review

Date: 2026-04-30

## Scope

This bundle made `CjguiInternalRuntimeExecutionStateLoopClosure` the current internal default tail endpoint and downgraded the old replay / outcome / admission / dry-run tail to legacy diagnostics / trace.

Modified files:

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-runtime-old-tail-deprecation-default-path-cleanup-closure-review.md`

## Landed Changes

- Added `cjguiInternalExecuteDefaultRuntimeTailDraft(): CjguiInternalRuntimeExecutionStateLoopClosure` as the explicit default tail alias.
- Marked replay / replay outcome / execution admission / dry-run execution plan sections as legacy diagnostics in source comments and README wording.
- Removed old open-default sanity helpers that made legacy tail layers look like the main path:
  - `cjguiInternalRuntimeCycleReplayOpenSanity`
  - `cjguiInternalRuntimeReplayOutcomeOpenSanity`
  - `cjguiInternalRuntimeExecutionAdmissionOpenSanity`
  - `cjguiInternalRuntimeDryRunExecutionPlanOpenSanity`

## Retained Legacy Trace

Core replay / replay outcome / admission / dry-run types and executors are retained because existing traceability and blocked diagnostics still depend on them. Their blocked sanity helpers remain legacy diagnostics, not default-path proof.

## Boundary

This is not wrapper rebound: no new Request + Report layer, no new replay / admission / dry-run / outcome wrapper, and no five-helper sanity chain was added.

This is not global state commit: no runtime global state write, no global mutable singleton, no public state, no platform callback, no event loop / queue / scheduler, no second cycle execution, and no new `cjguiInternalExecuteRuntimeCycle` call site.

## GitNexus Impact

Symbol-level impact for newly landed loop-closure and old-tail helpers returned UNKNOWN / not found. Fallback `runtime_state.cj` file-level upstream impact returned LOW with direct callers 0 and affected processes 0. No HIGH / CRITICAL risk was reported.

## Verification

- `cjpm build --target-dir /tmp/cjgui-runtime-old-tail-deprecation-cleanup-target --skip-script`: passed.
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`: passed.
- `git diff --check`: passed.
- Forbidden scope check: passed.

## Next Opening

`P1 runtime old tail deprecation closure / next runtime boundary decision`
