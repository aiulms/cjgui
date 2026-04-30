# P1 Runtime State Integration / Tail Consolidation Decision

Date: 2026-04-30

## Current Landed Facts

- The first internal execution attempt can execute one `CjguiInternalRuntimeCycleRequest` candidate on the allowed path.
- Execution convergence, commit candidate, commit readiness, commit record, and commit finalization now form a closed value-style tail.
- The current execution chain reaches `CjguiInternalRuntimeExecutionCommitFinalization`.
- The tracker has been compacted into a current-state dashboard.
- The pure post-attempt outcome wrapper has been removed and should not return.

## Why Next Step Must Be Larger

The runtime tail has enough small boundary objects. Continuing with another tiny one-value boundary would add naming debt without improving runtime behavior. The next implementation should connect execution commit finalization back toward the existing runtime state tail chain and consolidate repeated projections where safe.

The next slice should inspect the state / replay / execution tail as one bundle rather than adding another isolated report.

## Approved Next Opening

`P1 runtime state integration / tail chain consolidation bundle implementation`

## Allowed W4 Scope

- Allow a 200-500 line focused diff across `runtime_state.cj`, `runtime/cjgui/README.md`, tracker, plans README, and a closure review.
- Use `CjguiInternalRuntimeExecutionCommitFinalization` as the new integration entry.
- Connect commit finalization to the appropriate existing runtime state tail boundary.
- Inspect and consolidate `RuntimeStateCarryForward`, `RuntimeCarriedStateContainer`, `RuntimeStateHolder`, `RuntimeCommittedStateStore`, `RuntimeCycleFeedback`, `RuntimeNextCycleRequest`, `RuntimeCycleHandoff`, `RuntimeCycleReplay`, `RuntimeReplayOutcome`, `RuntimeExecutionAdmission`, `RuntimeDryRunExecutionPlan`, `RuntimeExecutionAttempt`, `RuntimeExecutionConvergence`, and `RuntimeExecutionCommit*`.
- Add only 1-3 integration values / functions if they replace, connect, or compress existing chain semantics.
- Delete or merge behavior-preserving duplicate helpers, always-true markers, stored derived booleans, or tail projection logic when GitNexus / source review shows the blast radius is safe.
- Compress runtime README tail history if it has become a liability for future implementation sessions.

## Guardrails

- No public runtime API or public C ABI.
- No platform callback, AppKit / Metal / Objective-C expansion, event loop, queue, drain, or scheduler.
- No app run / shutdown or window create / close / destroy / release.
- No runtime global state write or global mutable singleton.
- No second cycle execution and no new `cjguiInternalExecuteRuntimeCycle` call site outside the existing attempt path.
- No Request + Report double layer.
- No five-sanity helper bundle.
- No return to outcome / admission / dry-run / replay wrapper layering.

## Verification Note

This round is docs-only. It should run `git diff --check`, link checks, and forbidden-file checks only; no `cjpm build` or smoke guard is required unless runtime code is accidentally touched.
