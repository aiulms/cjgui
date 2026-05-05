# P1 Renderer real command queue implementation preflight decision

Date: 2026-05-05

Status: docs-only preflight decision complete.

## Decision

This preflight allows opening the real command queue implementation runway, but it does not approve a real `MTLCommandQueue`, `newCommandQueue`, native handle, bridge call, GPU submission or render implementation.

The next step should be:

`P1 internal Renderer real command queue implementation admission value boundary bundle implementation`

That next step must still be an internal value boundary. It may only express real command queue implementation admission facts, not real command queue creation.

## Evidence Read

- [Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md) fixes `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft()` as a no-device-layer-implementation endpoint.
- [Real command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md) provides queue creation policy, ownership guard, teardown policy and no-real-command-queue vocabulary without creating `MTLCommandQueue`.
- [Native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md) keeps native handle, C ABI, FFI declaration, bridge call, retain / release / destroy and platform object behavior out of runtime truth.
- [Platform object implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-manifest.md) freezes platform object implementation admission facts without platform object creation or native handle ownership.
- [No-draw backend shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md) keeps backend shell lifecycle, no-resource guard, teardown and no-draw facts separate from backend object creation.
- [Backend Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) is evidence only: Metal's command queue is device-created, creates command buffers, orders command execution and sits before command buffer commit / GPU submission.
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md) requires explicit ownership, teardown, failure and thread / FFI boundaries before any manually managed GPU or native object is introduced.
- [macOS bridge smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/) remains feasibility, teardown and smoke evidence only. It is not runtime truth and does not approve `MTLCommandQueue`, `newCommandQueue`, FFI, bridge, GPU submission or render behavior.

## Preflight Answer

The evidence is sufficient to open a real command queue implementation runway only as a value-only implementation admission boundary.

The first admission slice should not split further into command queue creation admission, queue ownership token or teardown contract preflight because the existing chain already provides enough frozen vocabulary:

- Metal device-layer implementation admission provides the upstream no-device-layer-implementation endpoint.
- Real command queue lifecycle provides creation, ownership and teardown vocabulary as dehydrated value facts.
- Native bridge and platform object admission manifests keep native handle / bridge / FFI / platform object behavior outside runtime truth.
- The risk ledger makes admission facts necessary before any real native or GPU object is created.

The next value boundary should use this runtime input candidate only:

`CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness`

`CjguiInternalRendererNoRealCommandQueueReadiness`, `CjguiInternalRendererNoNativeResourceBridgeReadiness` and smoke evidence may be cited as documentation evidence only. They should not become additional runtime inputs.

The next value boundary output truth must be limited to:

- real command queue implementation intent.
- queue creation admission policy.
- queue ownership admission guard.
- queue teardown failure policy.
- no-real-command-queue-implementation readiness value facts.

Recommended owner candidate for that value boundary:

`runtime/cjgui/src/runtime_renderer_real_command_queue_admission.cj`

## Candidate Comparison

### A. P1 internal Renderer real command queue implementation admission value boundary bundle implementation

Recommended.

Reasoning: this is the narrowest useful next slice. It adds queue creation admission, queue ownership admission, teardown failure and no-real-command-queue-implementation semantics without creating `MTLCommandQueue`, calling `newCommandQueue`, adding native handles, adding FFI / C ABI or touching GPU submission.

### B. P1 internal Renderer real command queue creation admission preflight decision

Not selected.

Reasoning: queue creation owner / device relation evidence is adequate for a value-only admission boundary because Metal device-layer implementation admission already freezes the upstream no-device-layer endpoint and the reference pack clarifies that command queues are device-created without approving creation.

### C. P1 internal Renderer real command queue ownership token preflight decision

Not selected.

Reasoning: queue identity / lifetime / ownership evidence is sufficient at the admission-facts level. A concrete token would be premature because no native handle or queue object is allowed yet.

### D. P1 internal Renderer real command queue teardown contract preflight decision

Not selected.

Reasoning: teardown / release ordering / failure rollback concerns are real, but the next value boundary can express teardown failure policy without implementing retain / release / destroy.

### E. Real drawable implementation preflight

Deferred. Drawable implementation should wait until command queue implementation admission is manifest-stabilized.

### F. Real command buffer implementation preflight

Deferred. Command buffer creation remains downstream of command queue admission and drawable admission.

### G. Real backend shell implementation preflight

Deferred. Backend shell implementation remains separate from command queue implementation admission.

### H. Native handle token preflight

Deferred. No native handle token is needed until a later docs-only preflight proves a concrete handle identity / nullability need.

### I. Direct `MTLCommandQueue` creation implementation

Rejected.

### J. Direct `newCommandQueue` call

Rejected.

### K. Direct native handle / raw pointer implementation

Rejected.

### L. Direct C ABI / FFI declaration

Rejected.

### M. Direct Metal / AppKit / Objective-C implementation

Rejected.

### N. GPU submission / render execution

Rejected.

### O. Renderer state write

Rejected.

### P. Public API / C ABI expansion

Rejected.

### Q. Receipt / record / publication

Rejected.

### R. Consolidation

Not selected. There is no duplicate / low-value / self-wrapping evidence in this slice.

## Same-shape Boundary Brake

The next step must not wrap `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness`, `CjguiInternalRendererNoRealCommandQueueReadiness`, `CjguiInternalRendererNoNativeResourceBridgeReadiness` or smoke evidence into any of these shapes:

- real command queue implementation receipt / record / publication.
- queue-ready permission wrapper.
- native-handle permission wrapper.
- C ABI / FFI permission wrapper.
- Metal-device permission wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- render-permission wrapper.

If the next value boundary proceeds, it must add these semantics instead:

- queue creation admission.
- queue ownership admission.
- queue teardown failure.
- no-real-command-queue-implementation readiness.

## Stop-line

This decision does not approve:

- `MTLCommandQueue` creation.
- `newCommandQueue`.
- command buffer creation.
- native handle.
- raw pointer.
- C ABI.
- FFI declaration.
- bridge call.
- retain / release / destroy.
- Metal / AppKit / Objective-C call.
- GPU submission.
- render execution.
- renderer state write.
- public API.

## Smoke Evidence Boundary

`labs/macos_bridge_smoke` can remain feasibility / teardown / smoke evidence. Its command queue capability logs and auto-close path do not become runtime truth, do not define a runtime command queue owner, do not authorize `newCommandQueue`, and do not authorize native handles, C ABI / FFI, GPU submission, render correctness or renderer state write.

## Next Opening

`P1 internal Renderer real command queue implementation admission value boundary bundle implementation`

## Downstream Value Boundary Closure

Renderer real command queue implementation admission value boundary is now recorded in:

- [2026-05-05-p1-internal-renderer-real-command-queue-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-command-queue-implementation-admission-value-boundary-closure-review.md)

That closure adds `runtime/cjgui/src/runtime_renderer_real_command_queue_admission.cj`, consumes only `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness`, and seals `CjguiInternalRendererNoRealCommandQueueImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueAdmissionDraft()` as value facts.

The downstream owner keeps this preflight's stop-line intact: no `MTLCommandQueue`, no `newCommandQueue`, no command buffer, no native handle, no raw pointer, no C ABI, no FFI declaration, no bridge call, no retain / release / destroy, no Metal / AppKit / Objective-C, no GPU submission, no render execution, no renderer state write and no public API.

Unique downstream next opening:

`P1 internal Renderer real command queue implementation admission closure / next real command queue implementation decision`

## Downstream Next-boundary Decision

Renderer real command queue implementation admission next-boundary decision is now recorded in:

- [2026-05-05-p1-renderer-real-command-queue-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-admission-next-boundary-decision.md)

That decision confirms `CjguiInternalRendererNoRealCommandQueueImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueAdmissionDraft()` is sufficient as the current no-real-command-queue-implementation endpoint. It chooses manifest stabilization next and does not approve `MTLCommandQueue`, `newCommandQueue`, native handle, C ABI, FFI declaration, command buffer, GPU submission, render execution, renderer state write or public API.

Unique downstream next opening:

`P1 internal Renderer real command queue implementation admission manifest stabilization bundle implementation`

## Downstream Manifest Stabilization

Renderer real command queue implementation admission manifest stabilization is now recorded in:

- [2026-05-05-p1-renderer-real-command-queue-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-admission-manifest.md)
- [2026-05-05-p1-internal-renderer-real-command-queue-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-command-queue-implementation-admission-manifest-stabilization-closure-review.md)

The manifest fixes `runtime/cjgui/src/runtime_renderer_real_command_queue_admission.cj` as the owner, `CjguiInternalRendererNoRealCommandQueueImplementationReadiness` as the canonical endpoint and `cjguiInternalExecuteDefaultRendererRealCommandQueueAdmissionDraft()` as the default draft. It keeps this preflight's stop-line intact: no `MTLCommandQueue`, no `newCommandQueue`, no native handle, no C ABI, no FFI declaration, no command buffer, no GPU submission, no render execution, no renderer state write and no public API.

Unique downstream next opening:

`P1 internal Renderer real drawable implementation preflight decision`
