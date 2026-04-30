# P1 Runtime Internal Tail Milestone Manifest

Date: 2026-04-30

## Default Tail Path

The current internal runtime tail baseline is:

- `cjguiInternalExecuteDefaultRuntimeTailDraft()`
- `CjguiInternalRuntimeExecutionStateLoopClosure`
- `CjguiInternalRuntimeExecutionStateIntegration`
- `CjguiInternalRuntimeExecutionCommitFinalization`
- `CjguiInternalRuntimeExecutionCommitRecord`
- `CjguiInternalRuntimeExecutionCommitReadiness`
- `CjguiInternalRuntimeExecutionCommitCandidate`
- `CjguiInternalRuntimeExecutionConvergenceReport`
- `CjguiInternalRuntimeExecutionAttemptReport`

The default tail prepares a next internal cycle request candidate through loop closure. It does not execute that candidate, start an event loop, write global state, or publish app/window state.

## Legacy Diagnostics / Trace

These old tail symbols are retained for diagnostics / trace only. They are not the default path, and no new work should extend them unless a later decision explicitly reopens legacy diagnostics:

- `CjguiInternalRuntimeCycleReplayRequest`
- `CjguiInternalRuntimeCycleReplayDraft`
- `CjguiInternalRuntimeReplayOutcomeRequest`
- `CjguiInternalRuntimeReplayOutcomeReport`
- `CjguiInternalRuntimeExecutionAdmissionRequest`
- `CjguiInternalRuntimeExecutionAdmissionReport`
- `CjguiInternalRuntimeDryRunExecutionPlanRequest`
- `CjguiInternalRuntimeDryRunExecutionPlan`

The old replay / outcome / admission / dry-run open-default sanity helpers have been removed. Blocked legacy sanity remains diagnostic-only.

## Current Stop Lines

- No public API / C ABI.
- No platform callback, event loop, queue, drain, or scheduler.
- No global runtime state write or global mutable singleton.
- No second cycle execution and no new `cjguiInternalExecuteRuntimeCycle` call site.
- No new Request + Report layer.
- No five-piece sanity helper bundle.
- No replay / admission / dry-run wrapper revival.

## Next Reasonable Boundary

Recommended next opening:

`P1 runtime internal tail milestone closure / next real runtime boundary decision`

That next step should decide the first real runtime boundary after this stabilized internal tail baseline. It should not add another runtime tail wrapper by default.
