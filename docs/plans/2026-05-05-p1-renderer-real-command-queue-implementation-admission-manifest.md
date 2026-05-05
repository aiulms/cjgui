# P1 Renderer real command queue implementation admission manifest

Date: 2026-05-05

Status: docs-only manifest stabilization.

## Scope

This manifest fixes `runtime_renderer_real_command_queue_admission.cj` owner / truth / canonical endpoint / default draft / stop-line and closes the current no-real-command-queue-implementation endpoint.

This round is docs-only. It does not modify `.cj`, does not run `cjpm build` or smoke, and does not touch `runtime_state.cj`, `runtime/cjgui/cjpm.toml`, smoke, harness, native bridge, entry, AGENTS / CLAUDE or CANGJIE_ISSUE_LEDGER.

This manifest does not create backend shell object, backend object, platform object, native handle, raw pointer, C ABI, FFI declaration, bridge call, retain / release / destroy call, `MTLDevice`, `CAMetalLayer`, `MTLCommandQueue`, drawable, command buffer, `newCommandQueue`, `commit`, `present`, `nextDrawable`, Metal / AppKit / Objective-C / FFI call, GPU submission, render execution, renderer state write or public API.

## Canonical Owner

Owner file:

- [runtime_renderer_real_command_queue_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_command_queue_admission.cj)

Runtime input:

- `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft()`

Canonical endpoint:

- `CjguiInternalRendererNoRealCommandQueueImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererRealCommandQueueAdmissionDraft()`

Default draft:

- `cjguiInternalExecuteDefaultRendererRealCommandQueueAdmissionDraft()` first obtains `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` from `cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft()`.
- It builds real command queue implementation intent, queue creation admission policy, queue ownership admission guard, queue teardown failure policy and no-real-command-queue-implementation readiness in owner-local value facts.
- It does not create `MTLCommandQueue`, does not call `newCommandQueue`, does not create `MTLDevice`, `CAMetalLayer`, drawable, command buffer, render pass, encoder or pipeline state.
- It does not create or save native handle / raw pointer / foreign resource token, does not add C ABI or FFI declarations, does not call bridge code, retain, release, destroy, Metal / AppKit / Objective-C / FFI, `commit`, `present` or `nextDrawable`.
- It does not submit GPU work, execute render, write renderer state, modify bridge / smoke / harness / native entry or expand public API.

## Current Truth

The current truth is exactly:

- real command queue implementation intent value facts.
- queue creation admission policy value facts.
- queue ownership admission guard value facts.
- queue teardown failure policy value facts.
- no-real-command-queue-implementation readiness value facts.

The canonical value chain is:

1. `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness`
2. `CjguiInternalRendererRealCommandQueueImplementationIntent`
3. `CjguiInternalRendererRealCommandQueueCreationAdmissionPolicy`
4. `CjguiInternalRendererRealCommandQueueOwnershipAdmissionGuard`
5. `CjguiInternalRendererRealCommandQueueTeardownFailurePolicy`
6. `CjguiInternalRendererNoRealCommandQueueImplementationReadiness`

## Value Semantics

`CjguiInternalRendererRealCommandQueueImplementationIntent` only records future real command queue implementation intent facts. It is not queue-ready permission, backend implementation permission, GPU submission permission, render permission or public API permission.

`CjguiInternalRendererRealCommandQueueCreationAdmissionPolicy` only records queue creation admission facts. It does not create `MTLCommandQueue`, does not call `newCommandQueue`, does not create command buffer and does not call Metal / AppKit / Objective-C / FFI.

`CjguiInternalRendererRealCommandQueueOwnershipAdmissionGuard` only records queue ownership admission facts. It does not save a native queue handle, does not expose raw pointer, does not create pointer-like resource, and does not export foreign resource token.

`CjguiInternalRendererRealCommandQueueTeardownFailurePolicy` only records queue teardown failure / shutdown ordering / rollback facts. It does not execute retain, release, destroy, bridge teardown callback, native cleanup or renderer state mutation.

`CjguiInternalRendererNoRealCommandQueueImplementationReadiness` seals current no-real-command-queue-implementation readiness facts. It is not `MTLCommandQueue` permission, `newCommandQueue` permission, native handle permission, C ABI permission, FFI permission, command buffer permission, GPU submission permission, render permission, renderer state write permission or public API permission.

## Relationship Facts

Real command queue implementation admission facts relate to upstream Metal device-layer implementation admission facts only as dehydrated value facts:

- `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` remains the only runtime input.
- Metal device-layer implementation admission facts remain no-device / no-layer / no-platform-object / no-native-handle / no-bridge / no-submit input value facts, not queue creation permission.
- Real command queue lifecycle manifest remains docs evidence for creation / ownership / teardown vocabulary only; `CjguiInternalRendererNoRealCommandQueueReadiness` is not a runtime input for this owner.
- Native resource bridge manifest remains docs evidence for no-handle, no-C-ABI, no-FFI, no-bridge and teardown vocabulary only; `CjguiInternalRendererNoNativeResourceBridgeReadiness` is not a runtime input for this owner.
- Backend / Metal reference pack and smoke evidence remain evidence only and are not runtime truth.
- Future real drawable implementation, real command buffer implementation, real `MTLCommandQueue` / `newCommandQueue`, GPU submission or renderer state write work requires a separate docs-only preflight before any implementation can be considered.

## Explicit Non-Truth

The no-real-command-queue-implementation endpoint is not:

- `MTLCommandQueue` permission.
- `MTLCommandQueue` ownership.
- `newCommandQueue` permission.
- native handle permission.
- raw pointer permission.
- pointer-like resource permission.
- foreign resource token permission.
- C ABI permission.
- FFI permission.
- bridge call permission.
- retain / release / destroy permission.
- `MTLDevice` permission.
- `CAMetalLayer` permission.
- command buffer permission.
- drawable permission.
- render pass / encoder / pipeline state permission.
- `commit` / `present` / `nextDrawable` permission.
- GPU submission permission.
- render execution permission.
- backend implementation permission.
- renderer state write permission.
- diagnostics / event bus / observer / telemetry permission.
- public API / public C ABI permission.

Current truth has no backend shell object, no backend object, no platform object, no native handle, no raw pointer, no foreign resource token, no bridge call, no C ABI, no FFI declaration, no retain / release / destroy call, no `MTLDevice`, no `CAMetalLayer`, no `MTLCommandQueue`, no `newCommandQueue`, no drawable, no command buffer, no work submit, no render execution, no renderer state mutation and no external API surface.

## Evidence Chain

- [Real command queue implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-admission-next-boundary-decision.md) confirmed `CjguiInternalRendererNoRealCommandQueueImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueAdmissionDraft()` is sufficient as the current no-real-command-queue-implementation endpoint.
- [Real command queue implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-command-queue-implementation-admission-value-boundary-closure-review.md) added the internal-only owner and verified the no-queue / no-factory-call / no-handle / no-C-ABI / no-FFI / no-submit / no-render / no-state-write stop-line.
- [Real command queue implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-preflight-decision.md) proved enough queue creation admission, queue ownership admission, teardown failure and no-real-command-queue-implementation evidence to open the value boundary.
- [Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md) fixed the upstream no-metal-device-layer-implementation endpoint and denied device / layer / command queue / command buffer / GPU submission permission.
- [Real command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md) remains lifecycle vocabulary evidence only and does not become runtime input.
- [Native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md) remains no-handle / no-C-ABI / no-FFI / no-bridge vocabulary evidence only and does not become runtime input.

## Same-shape Boundary Brake

This round chooses manifest stabilization and closes the current no-real-command-queue-implementation endpoint.

It explicitly rejects:

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
- public API wrapper.

`CjguiInternalRendererNoRealCommandQueueImplementationReadiness` must not be wrapped into another tail endpoint unless a future docs-only preflight proves new owner / lifecycle / teardown / failure / verification semantics that are not already captured here.

Future work approaching real drawable implementation, real command buffer implementation, real `MTLCommandQueue` / `newCommandQueue`, GPU submission or renderer state write must first pass docs-only preflight.

## Stop-line

Until a later docs-only preflight explicitly opens a narrower runway:

- no `.cj` modification for this manifest.
- no `runtime_state.cj` touch.
- no `runtime/cjgui/cjpm.toml` touch.
- no smoke / harness / native bridge / entry touch.
- no backend shell object.
- no backend object.
- no platform object.
- no native handle.
- no raw pointer.
- no pointer-like resource.
- no foreign resource token.
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
- no render pass.
- no encoder.
- no pipeline state.
- no `commit`.
- no `present`.
- no `nextDrawable`.
- no Metal / AppKit / Objective-C / FFI call.
- no GPU submission.
- no render execution.
- no renderer state write.
- no diagnostics / event bus / observer / telemetry.
- no public API / public C ABI expansion.
- no module-level `var`.

## Public Surface

The public declaration allowlist remains unchanged:

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

## Next Stage Candidate Comparison

### A. P1 internal Renderer real drawable implementation preflight decision

Recommended as the next opening.

Reasoning: real command queue implementation admission is now manifest-stabilized as a no-real-command-queue-implementation endpoint. The next docs-only question can evaluate real drawable implementation risk while preserving the no-drawable / no-command-buffer / no-present / no-GPU-submission stop-line.

### B. Real command buffer implementation preflight

Deferred.

Command buffer creation remains downstream of drawable implementation preflight and command queue implementation admission manifest stabilization.

### C. Real command queue creation admission hardening

Deferred.

Choose only if a future review finds queue creation admission policy cannot express device relation, queue factory admission or no-queue availability facts clearly enough.

### D. Real command queue ownership token preflight

Deferred.

Choose only if a future review proves a concrete native identity / nullability / ownership-token need. Current ownership admission guard is enough for the sealed endpoint.

### E. Real command queue teardown contract hardening

Deferred.

Choose only if a future review finds teardown failure policy cannot express shutdown ordering, rollback or no-cleanup-invocation facts clearly enough.

### F. Direct `MTLCommandQueue` creation implementation

Rejected.

### G. Direct `newCommandQueue` call

Rejected.

### H. Direct native handle / raw pointer implementation

Rejected.

### I. Direct C ABI / FFI declaration

Rejected.

### J. Direct Metal / AppKit / Objective-C implementation

Rejected.

### K. GPU submission / render execution

Rejected.

### L. Renderer state write

Rejected.

### M. Public API / C ABI expansion

Rejected.

### N. Receipt / record / publication

Rejected.

### O. Consolidation

Not selected.

Choose consolidation only if explicit duplicate / low-value / self-wrapping evidence appears. Current evidence points to downstream real drawable implementation preflight, not deletion or merging.

## Decision

`runtime/cjgui/src/runtime_renderer_real_command_queue_admission.cj` is now the fixed real command queue implementation admission owner for the current no-real-command-queue-implementation endpoint.

`CjguiInternalRendererNoRealCommandQueueImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueAdmissionDraft()` is the canonical tail for real command queue implementation admission value facts. It is not permission to create `MTLCommandQueue`, call `newCommandQueue`, hold native handles, add C ABI / FFI, create command buffer, submit GPU work, render, write renderer state or expose public API.

Unique next opening:

`P1 internal Renderer real drawable implementation preflight decision`
