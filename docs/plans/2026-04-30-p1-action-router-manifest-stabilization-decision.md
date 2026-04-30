# P1 Action Router Manifest Stabilization Decision

## Current Landed Facts

- Action intent / admission / routing now form an internal-only Action Router runway.
- Routing consumes only `CjguiInternalActionAdmission` and produces runtime boundary route candidate / defer / blocked.
- Routing is still not action execution, AI provider integration, prompt handling, external agent integration, public API, or C ABI.
- Routing stops at a runtime boundary route candidate; it does not write queue state, enqueue, drain, dispatch, enter an event loop, implement scheduler behavior, or execute a runtime cycle.

## Candidate Comparison

- A: Action Router manifest stabilization. Recommended, because the owner / truth / stop-line should be fixed before any execution-facing expansion.
- B: Action execution admission. Deferred, because the route candidate just landed and execution would be premature without a stable manifest.
- C: AI provider / semantic projection runway. Deferred, because the current target remains an internal runtime contract, not model / prompt / external agent integration.
- D: Queue enqueue / drain. Deferred, because queue admission is still only a readiness value and must not jump to storage or drain.

## Decision

Choose A: stabilize the internal Action Router manifest before opening execution, provider, public surface, or queue mechanics.

## Approved Next Opening

`P1 internal Action Router manifest stabilization bundle implementation`

## Guardrails For Next Implementation

- Default owner / write set: `runtime/cjgui/src/action_router.cj` plus docs.
- May add an Action Router manifest document.
- May add 1-2 pure derived helpers if they only project existing facts.
- No Request + Report double layer.
- No five-piece sanity.
- No wrapper chain.
- Do not touch `runtime_state.cj` unless a file-size / owner split check first explains why it is mandatory.
- No action execution.
- No AI model provider, prompt, or external agent.
- No public API / C ABI.
- No queue storage, enqueue, drain, event loop, scheduler, platform bridge, or runtime cycle execution.

## Verification Note

- This round is docs-only, so build / smoke are intentionally not run.
- Required checks are `git diff --check`, entry-link check, Markdown absolute-link check, and forbidden-file check.
