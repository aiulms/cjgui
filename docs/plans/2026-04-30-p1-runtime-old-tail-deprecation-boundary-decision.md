# P1 Runtime Old Tail Deprecation Boundary Decision

Date: 2026-04-30

## Current Landed Facts

- `CjguiInternalRuntimeExecutionStateLoopClosure` is now the direct execution-state tail endpoint.
- Loop closure consumes `CjguiInternalRuntimeExecutionStateIntegration` and can derive a next internal cycle request candidate from `integration.feedback`.
- The new path bypasses old replay / admission / dry-run tail wrappers.
- `RuntimeCycleReplay`, `RuntimeReplayOutcome`, `RuntimeExecutionAdmission`, and `RuntimeDryRunExecutionPlan` remain only because current trace / sanity helpers still depend on them.

## Decision

The next implementation should enter old tail deprecation / default-path cleanup.

The default tail endpoint should be `CjguiInternalRuntimeExecutionStateLoopClosure`. Old replay / admission / dry-run symbols may remain as legacy diagnostics / trace only, but should no longer be documented or treated as the main default path.

The next bundle may delete, downgrade, or rename old helper / sanity surfaces when the change is behavior-preserving and GitNexus impact is acceptable.

## Approved Next Opening

`P1 runtime old tail deprecation / default-path cleanup bundle implementation`

## Allowed Scope

- W3/W4 `runtime_state.cj` cleanup centered on old tail deprecation and default-path clarity.
- Remove old replay / admission / dry-run default sanity / helper surfaces when safe.
- Update runtime README default-path wording.
- Update tracker, plans README, and closure review.
- Keep necessary legacy trace symbols when removing them would lose useful diagnostics or break current sanity coverage.

## Guardrails

- No new wrapper, Request + Report pair, or five-sanity helper bundle.
- No platform callback, event loop, queue, drain, scheduler, app run, shutdown, or window lifecycle behavior.
- No second cycle execution and no new `cjguiInternalExecuteRuntimeCycle` call site.
- No runtime global state write and no global mutable singleton.
- No public runtime API or public C ABI.

## Verification Note

This round is docs-only. It should run `git diff --check`, link checks, and forbidden-file checks only; no `cjpm build` or smoke guard is required.

