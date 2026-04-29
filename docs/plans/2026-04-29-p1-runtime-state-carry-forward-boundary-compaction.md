# P1 Runtime State Carry-Forward Boundary Compaction

## Current Mutated State Publication Capability

- Publication draft consumes `CjguiInternalLifecycleStateMutationOutcomeReport` only.
- App/window state values come from already-produced owner mutation result `nextState`.
- Open path can mark app/window states publishable.
- Runtime/input/shutdown/cancellation blocked paths defer publication, report blocked publication, and do not publish app/window state.
- Publication draft performs no new mutation, exposes no public state, and writes no runtime global state.

## Still Not

- Not public state API.
- Not runtime global state write.
- Not app/window public lifecycle result.
- Not platform callback.
- Not queue / drain.
- Not event loop.
- Not renderer / layout / input behavior.

## Carry-Forward Draft Decision

It is safe to start defining an internal-only runtime state carry-forward draft.

Carry-forward draft should consume `CjguiInternalLifecycleMutatedStatePublicationReport` and only express:

- `nextAppState` candidate.
- `nextWindowState` candidate.
- `shouldCarryForwardAppState`.
- `shouldCarryForwardWindowState`.
- `shouldDeferCarryForward`.
- `shouldReportCarryForwardBlocked`.

It must not write runtime global state. It must not mutate state. It must not publish public state. It must not bypass `CjguiInternalLifecycleMutatedStatePublicationReport` to read OutcomeReport, MutationReport, ApplyReport, CommitGateReport, MutationPlanReport, MutationReadinessReport, OwnerHandoffReport, or lower-level facts.

## Recommended Next Opening

`P1 runtime state carry-forward draft bundle implementation`

## Next-Slice Authorization Suggestion

- Prompt weight: W3 internal subsystem draft.
- Owner: `runtime_state.cj`.
- Allow one bundle to add `CjguiInternalRuntimeStateCarryForwardRequest`.
- Allow one bundle to add `CjguiInternalRuntimeStateCarryForwardReport`.
- Allow builder / evaluator / default executor.
- Allow open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked sanity helpers.
- Do not allow runtime global state write.
- Do not allow public API / C ABI.
- Do not allow state mutation.
- Do not allow platform callback.
- Do not allow queue / drain.
- Do not allow event loop.
- Do not allow window create / close / destroy.

## Design Choice

Carry-forward may store candidate app/window states because those values already come from publication report.

It must remain a candidate summary, not a committed runtime state store. This is the bridge from lifecycle mutation results toward a future internal runtime state container, but not the container itself.

## Stop-Line

This compaction writes no runtime code, creates no preflight or execution card, does not add public API / C ABI, does not modify `runtime/cjgui/src/*.cj`, does not modify `AGENTS.md` / `CLAUDE.md`, and does not add `CJGUI_TRUTH_MANIFEST.md`.
