# P1 Renderer real command queue implementation admission next-boundary decision

Date: 2026-05-05

Status: docs-only next-boundary decision complete.

## Scope

This round is docs-only. It does not modify `.cj`, does not create a runtime owner, does not run `cjpm build` or smoke, and does not touch `runtime_state.cj`, `runtime/cjgui/cjpm.toml`, smoke, harness, native bridge, entry, AGENTS / CLAUDE or CANGJIE_ISSUE_LEDGER.

This decision does not create backend shell object, backend object, platform object, native handle, raw pointer, C ABI, FFI declaration, bridge call, retain / release / destroy call, `MTLDevice`, `CAMetalLayer`, `MTLCommandQueue`, drawable, command buffer, `newCommandQueue`, `commit`, `present`, `nextDrawable`, Metal / AppKit / Objective-C / FFI call, GPU submission, render execution, renderer state write or public API.

## Evidence Read

- [runtime_renderer_real_command_queue_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_command_queue_admission.cj) defines the current internal-only admission owner.
- [Real command queue implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-command-queue-implementation-admission-value-boundary-closure-review.md) records the source shape, GitNexus impact fallback, build / smoke evidence from the prior implementation round and stop-line scans.
- [Real command queue implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-preflight-decision.md) selected the value-only implementation admission boundary and rejected direct `MTLCommandQueue` / `newCommandQueue` work.
- [Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md) provides the sole runtime input endpoint for the admission owner.
- [Real command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md) remains docs evidence for queue lifecycle vocabulary only.
- [Native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md) remains docs evidence for no-handle, no-C-ABI, no-FFI, no-bridge and teardown vocabulary only.

## Decision

`CjguiInternalRendererNoRealCommandQueueImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueAdmissionDraft()` is sufficient as the current no-real-command-queue-implementation endpoint.

The current endpoint represents only:

- real command queue implementation intent value facts.
- queue creation admission policy value facts.
- queue ownership admission guard value facts.
- queue teardown failure policy value facts.
- no-real-command-queue-implementation readiness value facts.

It is not:

- `MTLCommandQueue` permission.
- `newCommandQueue` permission.
- native handle permission.
- raw pointer permission.
- C ABI permission.
- FFI permission.
- command buffer permission.
- drawable permission.
- GPU submission permission.
- render permission.
- backend implementation permission.
- renderer state write permission.
- public API permission.

## Candidate Comparison

### A. P1 internal Renderer real command queue implementation admission manifest stabilization bundle implementation

Recommended.

Reasoning: the admission owner already has a clear canonical endpoint and a verified no-queue / no-factory-call / no-native-handle / no-C-ABI / no-FFI / no-GPU-submission stop-line. The useful next step is to manifest-stabilize owner file, endpoint, default draft, current truth and reopening conditions.

### B. Real drawable implementation preflight

Deferred.

Drawable implementation should wait until the command queue implementation admission endpoint is manifest-stabilized, because drawable acquisition must not inherit an unstabilized queue-admission tail.

### C. Real command buffer implementation preflight

Deferred.

Command buffer creation remains downstream of queue implementation admission and drawable implementation preflight. It is too close to real GPU work for this decision.

### D. Real command queue creation admission hardening

Deferred.

Choose only if manifest stabilization exposes a concrete expression gap in queue creation admission facts. Current creation admission facts are sufficient for the endpoint.

### E. Real command queue ownership token preflight

Deferred.

No ownership token is needed until a later docs-only preflight proves a concrete native identity / nullability / lifetime need. Current ownership admission guard is value-only and does not store a native queue handle.

### F. Real command queue teardown contract hardening

Deferred.

Choose only if a future review finds teardown failure policy cannot express shutdown ordering, rollback or no-cleanup-invocation facts clearly enough.

### G. Direct `MTLCommandQueue` creation implementation

Rejected.

### H. Direct `newCommandQueue` call

Rejected.

### I. Direct native handle / raw pointer implementation

Rejected.

### J. Direct C ABI / FFI declaration

Rejected.

### K. Direct Metal / AppKit / Objective-C implementation

Rejected.

### L. GPU submission / render execution

Rejected.

### M. Renderer state write

Rejected.

### N. Public API / C ABI expansion

Rejected.

### O. Receipt / record / publication

Rejected.

### P. Consolidation

Not selected.

Choose consolidation only if explicit duplicate / low-value / self-wrapping evidence appears. Current evidence points to manifest stabilization, not deletion or merging.

## Same-shape Boundary Brake

`CjguiInternalRendererNoRealCommandQueueImplementationReadiness` must not be wrapped into another tail endpoint.

This decision explicitly rejects:

- queue-ready permission wrapper.
- `newCommandQueue` permission wrapper.
- native-handle permission wrapper.
- C-ABI permission wrapper.
- FFI permission wrapper.
- command-buffer permission wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- render-permission wrapper.
- renderer-state-write wrapper.
- receipt / record / publication.

The next step must stabilize the existing endpoint. It must not add another receipt, record, publication, ready-permission, handle-permission, command-buffer-permission, GPU-submission or render-permission layer.

## Stop-line

Until a later docs-only preflight explicitly opens a narrower runway:

- no `.cj` modification.
- no `runtime_state.cj` touch.
- no `runtime/cjgui/cjpm.toml` touch.
- no smoke / harness / native bridge / entry touch.
- no backend shell object.
- no backend object.
- no platform object.
- no native handle.
- no raw pointer.
- no C ABI.
- no FFI declaration.
- no bridge call.
- no retain / release / destroy.
- no `MTLDevice`.
- no `CAMetalLayer`.
- no `MTLCommandQueue`.
- no `newCommandQueue`.
- no drawable.
- no command buffer.
- no `commit`.
- no `present`.
- no `nextDrawable`.
- no Metal / AppKit / Objective-C / FFI.
- no GPU submission.
- no render execution.
- no renderer state write.
- no public API / C ABI expansion.

## Public Surface

The public declaration allowlist remains unchanged:

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

## Next Opening

`P1 internal Renderer real command queue implementation admission manifest stabilization bundle implementation`

## Downstream Manifest Stabilization

Renderer real command queue implementation admission manifest stabilization is now recorded in:

- [2026-05-05-p1-renderer-real-command-queue-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-admission-manifest.md)
- [2026-05-05-p1-internal-renderer-real-command-queue-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-command-queue-implementation-admission-manifest-stabilization-closure-review.md)

The manifest fixes `runtime/cjgui/src/runtime_renderer_real_command_queue_admission.cj` owner / truth / canonical endpoint / default draft / stop-line. `CjguiInternalRendererNoRealCommandQueueImplementationReadiness` remains no-real-command-queue-implementation value facts only and does not become `MTLCommandQueue` permission, `newCommandQueue` permission, native handle permission, C ABI permission, FFI permission, command buffer permission, GPU submission permission, render permission, renderer state write permission or public API permission.

Unique downstream next opening:

`P1 internal Renderer real drawable implementation preflight decision`
