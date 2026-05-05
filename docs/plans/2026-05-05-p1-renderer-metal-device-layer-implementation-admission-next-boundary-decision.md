# P1 Renderer Metal device-layer implementation admission next-boundary decision

日期：2026-05-05

状态：docs-only next-boundary decision

## Scope

本轮复核 `runtime_renderer_metal_device_layer_admission.cj` 新增的 no-metal-device-layer-implementation endpoint，并决定下一步是否继续包装、硬化或进入 manifest stabilization。

本轮 docs-only：不修改 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮不创建 backend shell object、backend object、platform object、native handle 或 raw pointer；不新增 C ABI，不新增 FFI declaration，不调用 bridge，不调用 retain / release / destroy；不创建 `MTLDevice`、不创建或绑定 `CAMetalLayer`、不创建 `MTLCommandQueue`、drawable 或 command buffer；不调用 `commit`、`present`、`nextDrawable`、Metal / AppKit / Objective-C / FFI；不提交 GPU work，不执行 render，不写 renderer state，不扩 public API。

## Inputs Read

- [runtime_renderer_metal_device_layer_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_admission.cj)
- [Metal device-layer implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-metal-device-layer-implementation-admission-value-boundary-closure-review.md)
- [Metal device-layer implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-preflight-decision.md)
- [Platform object implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)
- [Native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)

## Decision

`CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft()` is sufficient as the current no-metal-device-layer-implementation endpoint.

Choose A:

`P1 internal Renderer Metal device-layer implementation admission manifest stabilization bundle implementation`

Reasoning:

- The endpoint consumes only `CjguiInternalRendererNoPlatformObjectImplementationReadiness`.
- The endpoint preserves platform-object implementation admission stop-lines before naming device / layer implementation admission facts.
- The owner-local value chain already covers Metal device-layer implementation intent, device creation admission policy, layer binding admission guard, scale-color-space admission policy and no-metal-device-layer-implementation readiness.
- The open path only produces value facts.
- Deferred path remains deferred.
- Blocked / inconsistent paths fail closed.
- The endpoint already rejects device-ready permission, layer-ready permission, native-handle permission, C-ABI / FFI permission, platform-object wrapper, backend implementation wrapper, GPU-submission wrapper, render-permission wrapper, renderer-state-write wrapper and receipt / record / publication.

The next step should stabilize the manifest rather than add a new tail wrapper or split hardening docs.

## Current Endpoint Truth

Current canonical owner:

- [runtime_renderer_metal_device_layer_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_admission.cj)

Runtime input:

- `CjguiInternalRendererNoPlatformObjectImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()`

Canonical endpoint:

- `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft()`

Current endpoint truth is only:

- Metal device-layer implementation intent value facts.
- device creation admission policy value facts.
- layer binding admission guard value facts.
- scale-color-space admission policy value facts.
- no-metal-device-layer-implementation readiness value facts.

`CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` is not:

- `MTLDevice` permission.
- `CAMetalLayer` permission.
- native handle permission.
- raw pointer permission.
- C ABI permission.
- FFI permission.
- bridge call permission.
- retain / release / destroy permission.
- platform object permission.
- backend shell object permission.
- backend object permission.
- `MTLCommandQueue` permission.
- drawable permission.
- command buffer permission.
- `commit` / `present` / `nextDrawable` permission.
- GPU submission permission.
- render permission.
- renderer state write permission.
- public API / public C ABI permission.

## Candidate Comparison

### A. P1 internal Renderer Metal device-layer implementation admission manifest stabilization bundle implementation

推荐。

This is the right next move because the endpoint is now sufficient and should be sealed with owner file, canonical endpoint, default draft, current truth, stop-line and downstream reopening conditions.

### B. Metal device creation admission hardening

暂缓。

Choose only if a future review finds the device creation admission policy cannot express device selection, no-device fallback, no-device-query and no-command-queue facts clearly enough. Current expression is sufficient.

### C. Metal layer binding admission hardening

暂缓。

Choose only if a future review finds the layer binding admission guard cannot express layer binding, drawable pool boundary, no-layer fallback, no-layer-creation and no-drawable-acquisition facts clearly enough. Current expression is sufficient.

### D. Scale / color-space / resize admission hardening

暂缓。

Choose only if a future review finds drawable size, backing scale, pixel format, color space or resize admission facts insufficient. Current dehydrated scale-color-space admission policy is sufficient.

### E. Real command queue implementation preflight

暂缓。

Real command queue implementation remains downstream of manifest-stabilized device-layer implementation admission and must not be opened from this decision.

### F. Real backend shell implementation preflight

暂缓。

Real backend shell implementation must wait for a stabilized no-metal-device-layer-implementation manifest and a later docs-only preflight.

### G. Native handle token preflight

暂缓。

Native handle token work remains downstream unless manifest stabilization reveals an actual handle identity / nullability / ownership gap.

### H. Direct `MTLDevice` creation implementation

拒绝。

No `MTLDevice` creation, query, ownership, native object storage or Metal API call is approved.

### I. Direct `CAMetalLayer` creation / binding implementation

拒绝。

No `CAMetalLayer` creation, binding, configuration, drawable pool ownership or AppKit layer modification is approved.

### J. Direct native handle / raw pointer implementation

拒绝。

No native handle, raw pointer, pointer-like resource or foreign resource token implementation is approved.

### K. Direct C ABI / FFI declaration

拒绝。

No public or private C ABI, FFI declaration, foreign function declaration or signature expansion is approved.

### L. Direct Metal / AppKit / Objective-C implementation

拒绝。

No Metal / AppKit / Objective-C / FFI call, bridge modification, platform object or native object is approved.

### M. GPU submission / render execution

拒绝。

No command buffer commit, drawable present, GPU submission, render execution, render pass, encoder, pipeline state or draw call is approved.

### N. Renderer state write

拒绝。

No renderer state mutation and no `runtime_state.cj` write are approved.

### O. Public API / C ABI expansion

拒绝。

The public declaration allowlist remains unchanged and no public C ABI is opened.

### P. Receipt / record / publication

拒绝。

Do not add Metal device-layer implementation receipt / record / publication, device-ready permission wrapper, layer-ready permission wrapper, native-handle permission wrapper, C-ABI / FFI permission wrapper, platform-object wrapper, backend implementation wrapper, GPU-submission wrapper, render-permission wrapper or renderer-state-write wrapper.

### Q. Consolidation

仅在发现明确 duplicate / low-value / self-wrapping evidence 时选择。

No duplicate / low-value / self-wrapping evidence was found. The next useful move is manifest stabilization.

## Same-shape Boundary Brake

`CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` must not continue as a wrapped tail endpoint.

Forbidden wrappers:

- device-ready permission wrapper.
- layer-ready permission wrapper.
- native-handle permission wrapper.
- C-ABI permission wrapper.
- FFI permission wrapper.
- platform-object wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- render-permission wrapper.
- renderer-state-write wrapper.
- public API wrapper.
- receipt / record / publication.

The current endpoint already represents Metal device-layer implementation intent / device creation admission policy / layer binding admission guard / scale-color-space admission policy / no-metal-device-layer-implementation readiness value facts. A follow-up owner must add new owner / lifecycle / teardown / failure / verification semantics before it can be considered; otherwise it is a self-wrapping tail.

## Stop-line

Until a later docs-only preflight explicitly opens a narrower runway:

- no `.cj` modification in this decision round.
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
- no drawable.
- no command buffer.
- no render pass.
- no encoder.
- no pipeline state.
- no `commit`.
- no `present`.
- no `nextDrawable`.
- no Metal / AppKit / Objective-C / FFI call.
- no bridge / smoke / harness / native entry modification.
- no GPU submission.
- no render execution.
- no renderer state write.
- no diagnostics / event bus / observer / telemetry.
- no public API / public C ABI expansion.
- no receipt / record / publication.

## Validation Plan

This docs-only decision should be verified with:

- `git diff --check`
- new decision no-index whitespace check.
- Markdown absolute link missing target check, scoped to project docs and excluding `reference_repos/`.
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability.
- forbidden check: no tracked `.cj` diff, no protected path diff / status, `runtime_state.cj` line count remains `10065`.
- public declaration scan still finds only `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`.

Build and smoke must not be run in this docs-only round.

## Downstream

This next-boundary decision now points downstream to:

- [Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md)
- [Metal device-layer implementation admission manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-metal-device-layer-implementation-admission-manifest-stabilization-closure-review.md)

The downstream manifest fixes:

- owner file: [runtime_renderer_metal_device_layer_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_admission.cj)
- canonical endpoint: `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness`
- default draft: `cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft()`
- current truth: Metal device-layer implementation intent / device creation admission policy / layer binding admission guard / scale-color-space admission policy / no-metal-device-layer-implementation readiness value facts.

The downstream manifest does not approve `MTLDevice`, `CAMetalLayer`, native handle, C ABI, FFI, platform object, GPU submission, render, renderer state write or public API permission.

The downstream next opening is:

`P1 internal Renderer real command queue implementation preflight decision`

## Next Opening

唯一 next opening：

`P1 internal Renderer Metal device-layer implementation admission manifest stabilization bundle implementation`
