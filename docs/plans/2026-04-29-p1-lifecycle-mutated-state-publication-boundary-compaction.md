# P1 Lifecycle Mutated State Publication Boundary Compaction

## Current Related Capability

- First internal lifecycle state mutation uses owner-local immutable-copy transitions.
- App open path returns a new `CjguiInternalAppLifecycleState(true, true, state.hasObservedPlatformReady)` value.
- Window open path returns a new `CjguiInternalWindowLifecycleState(true, state.hasObservedPlatformReady)` value.
- Blocked / deferred paths return the original app/window state unchanged.
- The outcome layer verifies already-produced mutation results and blocked-state preservation.
- Apply / commit gate normalization removed low-value always-true markers and derived aggregate stored fields from the runtime-level apply / commit gate reports.

## Still Not

- Not public state publication.
- Not app/window public lifecycle API.
- Not platform callback.
- Not queue / drain.
- Not event loop.
- Not window create / close / destroy.
- Not renderer / layout / input behavior.

## Publication Draft Decision

It is safe to start defining an internal-only lifecycle mutated state publication draft.

The publication draft should express whether already-produced owner `nextState` values may become inputs to the next internal runtime chain:

- `shouldPublishAppState`
- `shouldPublishWindowState`
- `shouldDeferPublication`
- `shouldReportPublicationBlocked`

The publication draft must not mutate state again. It must not expose state as public API. It must not call platform, queue, drain, or event loop behavior.

## Recommended Next Opening

`P1 lifecycle mutated state publication draft bundle implementation`

## Next-Slice Authorization Suggestion

- Prompt weight: W3 internal subsystem draft.
- Suggested owner: `runtime_state.cj`, because publication is a cross-owner internal summary.
- Allow one bundle to add `CjguiInternalLifecycleMutatedStatePublicationRequest`.
- Allow one bundle to add `CjguiInternalLifecycleMutatedStatePublicationReport`.
- Allow builder / evaluator / default executor.
- Allow open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked sanity helpers.
- Do not allow new mutation.
- Do not allow state shape change.
- Do not allow public API / C ABI.
- Do not allow platform callback.
- Do not allow queue / drain.
- Do not allow event loop.
- Do not allow window create / close / destroy.

## Design Choice

Recommended consumption source is `CjguiInternalLifecycleStateMutationOutcomeReport`, because it is already the verification layer.

If the implementation needs actual next state values, it may read them through the outcome traceability chain:

- `outcome.request.mutationReport.appResult.nextState`
- `outcome.request.mutationReport.windowResult.nextState`

It must not read lower-level ApplyReport, CommitGate, Plan, Readiness, OwnerHandoff, or LifecycleWork facts. This is not a circular dependency; it is traceability from the verification summary back to already-produced owner mutation results.

## Stop-Line

This compaction writes no runtime code, creates no preflight or execution card, does not add public API / C ABI, does not modify `runtime/cjgui/src/*.cj`, does not modify `AGENTS.md` / `CLAUDE.md`, and does not add `CJGUI_TRUTH_MANIFEST.md`.
