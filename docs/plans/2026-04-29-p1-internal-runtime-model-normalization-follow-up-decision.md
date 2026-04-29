# P1 Internal Runtime Model Normalization Follow-up Decision

## Context

This decision reviews the completed lifecycle state mutation outcome model normalization and decides whether the runtime should continue local model normalization or return to runtime behavior progression. It is docs-only: no runtime code, no behavior change, no preflight, and no execution card.

## Previous Normalization Result

- Removed the always-true stored `didBuildMutationOutcome` field from the outcome report.
- Removed the stored derived `didMutateBothLifecycleOwners` field.
- Introduced `cjguiInternalLifecycleStateMutationOutcomeDidMutateBothOwners(...)` as a derived helper for both-owner mutation checks.
- Preserved behavior: open path still reports app/window mutation, and runtime/input/shutdown/cancellation blocked paths still report no owner mutation with blocked state preserved.
- `cjpm build`, smoke guard, and `git diff --check` passed in the closure review.

## Retained Shape

- `OutcomeReport -> OutcomeRequest -> StateMutationReport` traceability nesting was retained.
- Long internal scaffolding names were retained.
- No broad renaming was attempted.
- No app/window state shape changed.
- No lifecycle mutation semantics changed.

## Current Model Debt

- Outcome-layer local debt is now reduced.
- `runtime_state.cj` remains large because it still hosts many runtime-level routing and summary layers.
- Request/report nesting remains deep, although the outcome nesting is currently traceability rather than a recursive ownership loop.
- Many sanity helpers still exist.
- Long names still exist, but a global rename is not worth the churn yet.

## Decision

Do not start full-chain normalization now. Do not start full-chain renaming now.

A smaller second normalization trial is allowed:

`lifecycle mutation apply / commit gate marker normalization`

The trial should only inspect the apply / commit gate neighborhood for low-risk always-true markers or derived stored Bool fields. If such fields can be removed without changing behavior, semantics, owner boundaries, or state shape, the slice may remove them locally. If there are no safe removable fields, the slice should fail closed with a docs-only closure and return to runtime behavior progression.

## Recommended Next Opening

`P1 lifecycle mutation apply / commit gate model normalization bundle implementation`

## Next-Slice Authorization Suggestion

- Prompt weight: W2 behavior-preserving refactor slice.
- Allowed: local ApplyDraft / CommitGate model normalization in `runtime_state.cj` only if a low-value marker or derived stored field exists.
- Allowed: `app_lifecycle.cj` / `window_lifecycle.cj` owner draft edits only if necessary for the same local behavior-preserving normalization.
- Allowed: README, tracker, plans README, and closure review updates.
- Not allowed: behavior change.
- Not allowed: app/window state shape change.
- Not allowed: transition semantics change.
- Not allowed: public API / C ABI.
- Not allowed: global renaming.
- Not allowed: moving owner boundaries.

## Stop Condition

If the scan finds no safe removable ApplyDraft / CommitGate fields, the next slice should stop instead of forcing normalization. That closure should explicitly say no low-risk field was removed and recommend returning to runtime behavior progression.

## Stop-Line

This decision writes no runtime code, creates no preflight or execution card, does not refactor, does not change behavior, does not add `CJGUI_TRUTH_MANIFEST.md`, and does not modify `AGENTS.md` or `CLAUDE.md`.
