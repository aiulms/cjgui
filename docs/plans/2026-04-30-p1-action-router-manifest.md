# P1 Action Router Manifest

## Owner

- Action Router owner file: `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/action_router.cj`
- Upstream dependency: `CjguiInternalQueueAdmission`
- Current runway: `ActionIntent -> ActionAdmission -> ActionRoutingResult -> ActionDispatchAdmission -> ActionDispatchPlan -> ActionDispatchConvergence -> ActionDispatchCommitCandidate -> ActionDispatchFinalization -> ActionDispatchRecord`

## Current Truth Model

- `CjguiInternalActionSource` records dehydrated origin facts only.
- `CjguiInternalActionKind` records dehydrated action category facts only.
- `CjguiInternalActionIntent` combines source, kind, and presence.
- `CjguiInternalActionAdmission` consumes intent plus `CjguiInternalQueueAdmission` as the downstream gate.
- `CjguiInternalActionRoutingResult` consumes admission and carries a runtime boundary route candidate / defer / blocked fact.
- `CjguiInternalActionDispatchAdmission` consumes routing and carries future dispatch-boundary readiness.
- `CjguiInternalActionDispatchPlan` consumes dispatch admission and carries a value-style dispatch plan candidate.
- `CjguiInternalActionDispatchConvergence` consumes dispatch plan and converges ready / defer / blocked facts.
- `CjguiInternalActionDispatchCommitCandidate` consumes convergence and marks an internal dispatch commit candidate.
- `CjguiInternalActionDispatchFinalization` consumes commit candidate and summarizes the dispatch boundary.
- `CjguiInternalActionDispatchRecord` consumes finalization and records that the internal value-style dispatch boundary has formed; it is not an action execution record, not a queue enqueue record, and not a public audit log.

## Defaults

- Default source is system origin, so the default path does not pretend to be a human, external agent, AI provider, prompt, or model session.
- Default kind is runtime-boundary action, matching the current downstream runtime / queue readiness gate.
- Default routing calls the default admission draft and then routes the resulting admission.
- Default dispatch record calls default dispatch convergence and then records the finalization value.

## Routing Boundary

- Open path: admitted + preserved action intent with no defer / blocked flags becomes a runtime boundary route candidate.
- Defer-only remains deferred.
- Blocked or inconsistent flags fail closed as blocked.
- Preserving action intent means carrying a dehydrated route candidate, not executing an action.

## Dispatch Boundary

- Dispatch admission, plan, convergence, commit candidate, finalization, and record each consume only the previous value.
- Open path carries a preserved internal dispatch candidate through finalization and records the value-style boundary.
- Defer-only remains deferred through the dispatch chain.
- Blocked or inconsistent flags fail closed as blocked.
- Dispatch record is stabilization evidence for the internal boundary, not action execution, queue enqueue, queue drain, or public audit.

## Stop Lines

- No action execution.
- No AI provider / prompt / external agent.
- No public API / C ABI.
- No queue storage / enqueue / drain.
- No event loop / scheduler / platform callback.
- No runtime cycle execution.
- No `runtime_state.cj` growth.

## Next Reasonable Boundary

`P1 internal Action Router dispatch record stabilization closure / next action boundary decision`
