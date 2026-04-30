# P1 Runtime State Store Transition Manifest

Date: 2026-04-30

## State Store Transition Model

- Version: `CjguiInternalRuntimeStateStoreVersion` is an internal value marker. Default version is `0`; an open transition returns `version + 1`.
- Snapshot: `CjguiInternalRuntimeStateStoreSnapshot` carries app state, window state, and version as a value-style runtime store snapshot.
- Transition: `CjguiInternalRuntimeStateStoreTransition` carries previous snapshot, next snapshot, loop closure, and open/defer/blocked flags.
- Default executor: `cjguiInternalExecuteDefaultRuntimeStateStoreTransitionDraft()` gets loop closure from `cjguiInternalExecuteDefaultRuntimeTailDraft()`, builds previous from `loopClosure.integration.committedState`, and evaluates the transition.
- Derived helpers: `cjguiInternalRuntimeStateStoreTransitionDidOpen`, `cjguiInternalRuntimeStateStoreTransitionShouldDefer`, and `cjguiInternalRuntimeStateStoreTransitionShouldReportBlocked` project the transition flags without changing behavior.

## Truth / Owner Boundary

- The transition owns only value-style candidate movement from previous runtime snapshot to next runtime snapshot.
- It is not global mutable state, not a process-wide state store, and not public state.
- App/window state truth remains owner-local value facts owned by app lifecycle and window lifecycle.
- Runtime transition only aggregates app/window next-state candidates already exposed through committed-state / feedback / loop-closure values.

## Open / Deferred / Blocked Semantics

- Open path: previous -> next, version + 1.
- Deferred path: previous snapshot is preserved and defer is reported.
- Blocked path: previous snapshot is preserved and blocked is reported.
- Inconsistent flags fail closed to blocked and preserve previous snapshot.

## Stop Lines

- No global singleton or global mutable runtime state.
- No public API or public C ABI.
- No platform callback, AppKit, Metal, Objective-C, native handle, or raw pointer.
- No event loop, queue, drain, scheduler, app run, or window create / close / destroy / release.
- No second cycle and no new `cjguiInternalExecuteRuntimeCycle` call site.
- No Request + Report layer.
- No five-piece sanity bundle.
- No replay / admission / dry-run / outcome wrapper revival.

## Next Reasonable Boundary

After stabilization, the next decision can choose between internal input intent boundary and internal scheduler tick boundary. This manifest does not choose that boundary. Current tracker next opening is:

`P1 runtime state store transition stabilization closure / next runtime input-or-scheduler boundary decision`
