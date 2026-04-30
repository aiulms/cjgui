# P1 Runtime State Store Transition Next Boundary Decision

Date: 2026-04-30

## Current Landed Facts

- `CjguiInternalRuntimeStateStoreVersion`, `CjguiInternalRuntimeStateStoreSnapshot`, and `CjguiInternalRuntimeStateStoreTransition` have landed.
- The transition is value-style only. It is not global mutable state, does not publish state, and does not write process-wide runtime state.
- Default path: `cjguiInternalExecuteDefaultRuntimeTailDraft()` produces `CjguiInternalRuntimeExecutionStateLoopClosure`; `cjguiInternalExecuteDefaultRuntimeStateStoreTransitionDraft()` builds the previous snapshot from `loopClosure.integration.committedState` with version `0`.
- Open path builds the next snapshot from feedback next-cycle app/window candidates and advances version by one.
- Deferred, blocked, or inconsistent paths preserve the previous snapshot and fail closed as defer or blocked.

## Candidate Comparison

- A. `P1 runtime state store transition stabilization bundle implementation`: best fit now; stabilizes version/snapshot/transition owner, manifest, README wording, and small safe helpers before moving state truth forward.
- B. `P1 internal input intent boundary bundle implementation`: useful later, but opening input before state truth is stabilized risks a new intent wrapper chain.
- C. `P1 internal scheduler tick intent boundary bundle implementation`: too abstract right now; likely to become scheduler-shaped wrapper work without a stable store boundary.
- D. `P1 platform adapter input fact boundary bundle implementation`: valuable later, but too close to native/platform truth before internal state transition ownership is settled.

## Decision

Choose A: `P1 runtime state store transition stabilization bundle implementation`.

The state store transition has just become the new runtime state truth boundary. Before introducing input, scheduler, or platform facts, the project should stabilize its owner contract, manifest, README description, and any clearly derived helper semantics. This keeps later boundaries from carrying an underspecified state truth model.

Input intent, scheduler tick, and platform adapter fact work are intentionally deferred. They are not blocked forever; they are simply premature until version/snapshot/transition semantics are easy to hand off and verify.

## Approved Next Opening

`P1 runtime state store transition stabilization bundle implementation`

## Guardrails For Next Implementation

- Do not add global mutable state.
- Do not write process-wide runtime global state.
- Do not publish or expose state.
- Do not connect event loop, queue, scheduler, platform callback, AppKit, Metal, Objective-C, native handle, or raw pointer.
- Do not add public runtime API or public C ABI.
- Do not execute a second cycle or add a new `cjguiInternalExecuteRuntimeCycle` call site.
- Do not return to wrapper / report / draft chains.
- Allowed work: concise state store transition manifest, runtime README compression, owner section comments, small behavior-preserving cleanup, and 1-2 necessary derived helpers such as accepted/deferred/blocked transition predicates.
- If `runtime_state.cj` is modified, run GitNexus impact first, then run build and smoke guard.

## Verification Note

This round is docs-only. Build and smoke guard were not run. Verification is limited to `git diff --check`, link check, and forbidden-file check.
