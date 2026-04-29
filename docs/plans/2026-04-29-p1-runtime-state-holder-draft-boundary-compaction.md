# P1 Runtime State Holder Draft Boundary Compaction

## Current Carried State Container Capability

- Runtime carried state container consumes `CjguiInternalRuntimeStateCarryForwardReport` only.
- Carried app/window states come from carry-forward candidates.
- Open path can carry app/window states.
- Runtime/input/shutdown/cancellation blocked paths defer, report blocked, and do not carry app/window state.
- It performs no mutation, exposes no public state, and writes no runtime global state.
- GitNexus narrow impact check for `runtime_state.cj` currently reports LOW risk with direct callers 0.

## Still Not

- Not committed runtime global state.
- Not a global mutable singleton.
- Not public state API.
- Not state store.
- Not app/window public lifecycle result.
- Not platform callback.
- Not queue / drain.
- Not event loop.

## Runtime State Holder Draft Decision

It is safe to start defining an internal-only runtime state holder draft.

The state holder draft should consume `CjguiInternalRuntimeCarriedStateContainer` and only express:

- `heldAppState`.
- `heldWindowState`.
- `didHoldAppState`.
- `didHoldWindowState`.
- `shouldDeferHoldingState`.
- `shouldReportHoldingBlocked`.

It must remain value-style / immutable holder draft. It must not be a global mutable singleton. It must not write runtime global state. It must not mutate state. It must not publish public state. It cannot bypass `CjguiInternalRuntimeCarriedStateContainer` to read CarryForwardReport, PublicationReport, OutcomeReport, MutationReport, or lower-level facts.

## Recommended Next Opening

`P1 runtime state holder draft bundle implementation`

## Next-Slice Authorization Suggestion

- Prompt weight: W3 high-risk internal state holder slice.
- Owner: `runtime_state.cj`.
- Allow one bundle to add `CjguiInternalRuntimeStateHolderRequest`.
- Allow one bundle to add `CjguiInternalRuntimeStateHolderDraft`.
- Allow builder / evaluator / default executor.
- Allow open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked sanity helpers.
- Do not allow global mutable state.
- Do not allow public API / C ABI.
- Do not allow state mutation.
- Do not allow platform callback.
- Do not allow queue / drain.
- Do not allow event loop.
- Do not allow window create / close / destroy.

## Design Choice

The holder draft may store app/window state values because those values already come from `CjguiInternalRuntimeCarriedStateContainer`.

The holder draft must remain an immutable value summary, not an owning runtime singleton. This is a boundary toward future runtime state ownership, not the ownership implementation itself.

## Stop-Line

This compaction writes no runtime code, creates no preflight or execution card, does not add public API / C ABI, does not modify `runtime/cjgui/src/*.cj`, does not modify `AGENTS.md` / `CLAUDE.md`, and does not add `CJGUI_TRUTH_MANIFEST.md`.
