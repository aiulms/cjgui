# P1 Runtime Ingress Manifest

日期：2026-04-30

## Runtime Ingress Mainline

- Input mainline: `CjguiInternalInputIntent` -> `CjguiInternalInputIntentAdmission` -> `CjguiInternalInputRoutingResult` -> `CjguiInternalInputRuntimeIngress`.
- Scheduler mainline: `CjguiInternalSchedulerTickIntent` -> `CjguiInternalSchedulerTickAdmission` -> `CjguiInternalSchedulerRuntimeIngress`.
- Coordinator front door: `CjguiInternalRuntimeIngressCoordinator` combines input ingress and scheduler ingress.

## Coordinator Semantics

- Input candidate + scheduler pacing candidate both ready => `canEnterRuntimeIngressFrontDoor=true`.
- Either side defer-only => `shouldDeferRuntimeIngress=true`.
- Blocked or inconsistent flags => fail-closed `shouldReportRuntimeIngressBlocked=true`.
- Front-door ready means value-style ingress readiness only; it is not enqueue, dispatch, or execute.

## Owner / Truth Boundary

- Input ingress currently lives in `runtime_state.cj`.
- Scheduler tick and scheduler-runtime ingress live in `runtime_scheduler.cj`.
- Runtime ingress coordinator lives in `runtime_ingress.cj`.
- `runtime_state.cj` is in critical warning range; new ingress work should not move back there.
- This is not platform adapter truth, not app/window lifecycle mutation, and not public API.

## Stop Lines

- No queue / event loop / scheduler implementation.
- No runtime cycle execution.
- No global state write.
- No public API / C ABI.
- No platform object / native handle.
- No Request + Report layer.
- No five-piece sanity.

## Next Reasonable Boundary

`P1 internal runtime ingress manifest stabilization closure / next action-router-or-queue decision`
