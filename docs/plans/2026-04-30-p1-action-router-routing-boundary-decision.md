# P1 Action Router Routing Boundary Decision

## Current Landed Facts

- Action intent / admission has landed in `action_router.cj`.
- `action_router.cj` is the Action Router owner file; Action Router work must not move back into critical `runtime_state.cj`.
- `CjguiInternalQueueAdmission` is the downstream readiness gate for admitted action intent.
- The current slice has no action execution, AI model provider, prompt, external agent, public API, public C ABI, queue side effect, event loop, scheduler, platform bridge, or runtime cycle execution.

## Decision

- Next step enters internal action routing.
- Routing must consume only `CjguiInternalActionAdmission`.
- Routing may express only runtime boundary route candidate / defer / blocked.
- Routing must not execute action, write queue / enqueue / drain, call runtime cycle, expose public API, or connect AI provider / prompt / external agent.

## Approved Next Opening

`P1 internal Action Router routing boundary bundle implementation`

## Guardrails For Next Implementation

- Default owner / write set: `action_router.cj`.
- No `runtime_state.cj` modification.
- No public API / C ABI.
- No AI model provider / prompt / external agent.
- No action execution.
- No queue storage / enqueue / drain.
- No event loop / scheduler / platform.
- No runtime cycle execution.
- No Request + Report double layer.
- No five-piece sanity.
- Routing value should stay small and direct.
- If `runtime_state.cj` must be touched, file-size / owner split check is mandatory before implementation continues.

## Verification Note

- This round is docs-only, so build / smoke are intentionally not run.
- Required checks are `git diff --check`, link check, and forbidden-file check.
