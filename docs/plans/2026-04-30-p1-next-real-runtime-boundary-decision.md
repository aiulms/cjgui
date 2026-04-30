# P1 Next Real Runtime Boundary Decision

Date: 2026-04-30

## Current Milestone

- Default tail path is `cjguiInternalExecuteDefaultRuntimeTailDraft()` -> `CjguiInternalRuntimeExecutionStateLoopClosure`.
- Loop closure consumes `CjguiInternalRuntimeExecutionStateIntegration` and prepares a next internal cycle request candidate without executing it.
- Old replay / outcome / admission / dry-run symbols are legacy diagnostics / trace, not default path.
- Tail work should stop for now: the milestone is readable, documented, and no longer needs another wrapper layer.

## Candidate Comparison

- A, internal runtime state store transition: strongest fit after tail closure because the next truth boundary is runtime state transition, not more tail projection. Risk is state owner confusion, so it must stay value-style and non-global.
- B, internal event input intent: useful later, but likely to become another dehydrated intent wrapper before state truth is settled.
- C, scheduler tick intent: too easy to become empty scheduler vocabulary without queue / loop semantics.
- D, app/window lifecycle mutation follow-up: app/window owner facts exist, but this would duplicate the already-landed lifecycle mutation chain before runtime state ownership is clarified.
- E, platform adapter fact ingestion: important later, but it moves toward native/platform truth before runtime state transition has a stable owner.

## Decision

Choose candidate A.

The recommended next boundary is an internal runtime state store transition boundary. The current tail already closes execution-state feedback into a next internal cycle candidate; the next meaningful step is to define how a value-style runtime state store transition/version marker can accept or defer that tail result without creating a process-wide global store.

The other candidates are deferred because event input, scheduler tick, lifecycle expansion, and platform adapter ingestion all depend on a clearer runtime state truth boundary to avoid another wrapper-only chain.

## Approved Next Opening

`P1 internal runtime state store transition boundary bundle implementation`

## Guardrails For Next Implementation

- Only allow value-style internal state store transition.
- Do not create a global mutable singleton.
- Do not write process-wide runtime global state.
- Do not publish app/window state.
- Do not connect event loop, queue, drain, scheduler, platform callback, or native bridge.
- Do not add public runtime API / C ABI.
- Do not return to wrapper / report / draft layering.
- The implementation may consume `CjguiInternalRuntimeExecutionStateLoopClosure` or the current default tail.
- A state store transition / version marker is allowed only if ownership is explicit and remains internal.

## Verification Note

This round is docs-only. Run `git diff --check`, link checks, and forbidden-scope checks only; do not run build or smoke.
