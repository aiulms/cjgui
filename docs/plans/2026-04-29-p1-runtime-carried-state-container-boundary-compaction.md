# P1 Runtime Carried State Container Boundary Compaction

## Current Carry-Forward Capability

- Runtime state carry-forward consumes `CjguiInternalLifecycleMutatedStatePublicationReport` only.
- App/window nextState candidates come from publication report `appState` / `windowState`.
- Open path can mark app/window states as carry-forward candidates.
- Runtime/input/shutdown/cancellation blocked paths defer carry-forward, report blocked carry-forward, and do not carry app/window state.
- Carry-forward performs no new mutation, exposes no public state, and writes no runtime global state.

## Still Not

- Not committed runtime global state.
- Not public state API.
- Not state store.
- Not app/window public lifecycle result.
- Not platform callback.
- Not queue / drain.
- Not event loop.
- Not renderer / layout / input behavior.

## Carried State Container Draft Decision

It is safe to start defining an internal-only runtime carried state container draft.

The carried state container should consume `CjguiInternalRuntimeStateCarryForwardReport` and only express:

- `carriedAppState`.
- `carriedWindowState`.
- `didCarryAppState`.
- `didCarryWindowState`.
- `shouldDeferCarriedState`.
- `shouldReportCarriedStateBlocked`.

It must not write runtime global state. It must not mutate state. It must not publish public state. It must not bypass `CjguiInternalRuntimeStateCarryForwardReport` to read PublicationReport, OutcomeReport, MutationReport, ApplyReport, CommitGateReport, or lower-level facts.

## Recommended Next Opening

`P1 runtime carried state container draft bundle implementation`

## Next-Slice Authorization Suggestion

- Prompt weight: W3 internal subsystem draft.
- Owner: `runtime_state.cj`.
- Allow one bundle to add `CjguiInternalRuntimeCarriedStateContainerRequest`.
- Allow one bundle to add `CjguiInternalRuntimeCarriedStateContainer`.
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

The carried state container may store app/window state values because those values already come from carry-forward candidates.

It must remain a container draft, not a committed runtime state store. This is the bridge from carry-forward candidates toward a future internal runtime state holder, but not the holder itself.

## Stop-Line

This compaction writes no runtime code, creates no preflight or execution card, does not add public API / C ABI, does not modify `runtime/cjgui/src/*.cj`, does not modify `AGENTS.md` / `CLAUDE.md`, and does not add `CJGUI_TRUTH_MANIFEST.md`.
