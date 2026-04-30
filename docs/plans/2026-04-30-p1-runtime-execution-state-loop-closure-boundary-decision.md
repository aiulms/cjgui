# P1 Runtime Execution-State Loop Closure Boundary Decision

Date: 2026-04-30

## Current Landed Facts

- The internal chain now closes from execution attempt through convergence, commit candidate, commit readiness, commit record, commit finalization, and execution-state integration.
- `CjguiInternalRuntimeExecutionStateIntegration` connects execution finalization back to existing `CjguiInternalRuntimeCommittedStateStoreDraft` / `CjguiInternalRuntimeCycleFeedbackDraft` tail values.
- `CjguiInternalRuntimeStateCarryForwardReport.didBuildCarryForwardDraft` was removed as an always-true marker.
- The tracker remains a current-state dashboard rather than a long execution log.

## Why Next Step Should Be Loop Closure

The current tail has enough small value boundaries. The next implementation should not add another one-value wrapper. It should decide whether integrated execution-state output can become the single entry into next internal cycle closure / handoff, while continuing to reduce duplicate tail projections.

The next bundle should inspect `NextCycleRequest`, `CycleHandoff`, `CycleReplay`, `ReplayOutcome`, `ExecutionAdmission`, and `DryRunExecutionPlan` for behavior-preserving compression or bypass opportunities. It should not revive admission / dry-run / replay / outcome wrapper layering.

## Approved Next Opening

`P1 runtime execution-state loop closure bundle implementation`

## Allowed Scope For Next Implementation

- Modify `runtime_state.cj`, `runtime/cjgui/README.md`, tracker, plans README, and a closure review.
- Allow a focused 200-500 line diff if it stays centered on execution-state loop closure and tail consolidation.
- Add only 1-3 necessary integration / loop-closure values or functions.
- Delete or merge duplicate helpers, stored derived booleans, always-true markers, or same-meaning projections when source review and GitNexus impact show the change is safe.
- Bypass or compress old tail wrappers only when behavior remains preserved and traceability remains clear.

## Guardrails

- No platform callback, AppKit / Metal / Objective-C expansion, event loop, queue, drain, or scheduler.
- No runtime global state write and no global mutable singleton.
- No second cycle execution and no new `cjguiInternalExecuteRuntimeCycle` call site.
- No public runtime API or public C ABI.
- No Request + Report double layer.
- No five-sanity helper bundle.
- No return to outcome / admission / dry-run / replay wrapper layering.

## Verification Note

This round is docs-only. It should run `git diff --check`, link checks, and forbidden-file checks only; no `cjpm build` or smoke guard is required unless runtime code is accidentally touched.
