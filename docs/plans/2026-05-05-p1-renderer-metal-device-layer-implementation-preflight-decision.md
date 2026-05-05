# P1 Renderer Metal device-layer implementation preflight decision

日期：2026-05-05

状态：docs-only preflight decision

## Scope

本轮评估在 platform object implementation admission manifest 封账后，是否可以打开 Metal device-layer implementation runway。

本轮 docs-only：不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮不创建 backend shell object、backend object、platform object、native handle 或 raw pointer；不新增 C ABI，不新增 FFI declaration，不调用 bridge，不调用 retain / release / destroy；不创建 `MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer；不调用 `commit`、`present`、`nextDrawable`、Metal / AppKit / Objective-C / FFI；不提交 GPU work，不执行 render，不写 renderer state，不扩 public API。

## Inputs Read

- [Platform object implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-manifest.md)
- [Native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)
- [Backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [Backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [macOS bridge smoke README](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md), read-only for feasibility / teardown / smoke evidence only.
- [macOS bridge smoke auto-close verifier](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh), read-only for feasibility / teardown / smoke evidence only.

## Preflight Decision

允许打开 Metal device-layer implementation runway，但下一步仍不能创建真实 `MTLDevice` / `CAMetalLayer`。

选择 A：`P1 internal Renderer Metal device-layer implementation admission value boundary bundle implementation`。

下一步必须仍是 internal value boundary / implementation admission facts。它不得创建 `MTLDevice`、`CAMetalLayer`、platform object、native handle、raw pointer、C ABI、FFI declaration、bridge call、retain / release / destroy call、Metal / AppKit / Objective-C object、GPU work、render execution、renderer state write 或 public API。

唯一 next opening：

`P1 internal Renderer Metal device-layer implementation admission value boundary bundle implementation`

## Owner And Truth Shape For The Next Boundary

Default owner candidate：

- `runtime/cjgui/src/runtime_renderer_metal_device_layer_admission.cj`

Runtime input candidate：

- `CjguiInternalRendererNoPlatformObjectImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()`

The next boundary should consume only `CjguiInternalRendererNoPlatformObjectImplementationReadiness` as runtime input. Native resource bridge, Metal device-layer owner, backend platform object owner, backend / Metal reference pack, risk ledger and smoke evidence remain docs evidence only.

Allowed output truth only:

- Metal device-layer implementation intent value facts.
- device creation admission policy value facts.
- layer binding admission guard value facts.
- scale-color-space admission policy value facts.
- no-metal-device-layer-implementation readiness value facts.

Suggested canonical endpoint for the next value boundary:

- `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness`

Suggested default draft:

- `cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft()`

## Split Assessment

The next step does not need to split first into separate Metal device creation admission preflight, Metal layer binding admission preflight, Metal scale-color-space admission preflight or native handle token preflight.

Reasoning:

- Platform object implementation admission manifest already seals `CjguiInternalRendererNoPlatformObjectImplementationReadiness` with native handle admission, lifecycle admission, teardown failure and no-platform-object-implementation stop-lines.
- Native resource bridge manifest already closes no-handle / no-bridge / no-C-ABI / no-FFI facts and denies native bridge implementation permission.
- Metal device-layer owner manifest already provides device selection, layer binding and scale-color-space vocabulary while denying real `MTLDevice` / `CAMetalLayer` creation.
- Backend / Metal reference pack provides official evidence for device, layer, drawable pool, backing scale, color space and presentation responsibilities without approving implementation.
- GUI risk ledger identifies FFI ownership, platform object lifetime, GPU resource lifecycle and main-thread / AppKit boundaries as risks that can be named in admission facts before implementation.
- Smoke evidence proves only feasibility / teardown / lifecycle / diagnostics shape, not runtime truth. It can support admission policy vocabulary but cannot replace device, layer or native handle truth.

If the next value-boundary implementation cannot express device creation admission, layer binding admission, scale / color-space admission and no-metal-device-layer-implementation facts without creating device / layer / handle / bridge declarations, it must stop and fall back to B, C or D. That fallback is not required before opening A.

## Evidence Assessment

### Platform object implementation admission evidence

`CjguiInternalRendererNoPlatformObjectImplementationReadiness` is the current no-platform-object-implementation endpoint. It preserves platform object implementation intent, native handle admission policy, platform object lifecycle admission guard, teardown failure policy and no-platform-object-implementation readiness facts.

It is not platform object implementation permission, native handle permission, C ABI permission, FFI permission, Metal / AppKit bridge permission, GPU submission permission, render permission, renderer state write permission or public API permission.

For this preflight, it is the right runtime input candidate because Metal device-layer implementation admission must preserve the no-platform-object / no-native-handle / no-bridge / no-FFI stop-line before any device / layer work can be considered.

### Native resource bridge evidence

`CjguiInternalRendererNoNativeResourceBridgeReadiness` provides handle confinement, bridge call admission and native teardown contract vocabulary.

It is docs evidence only. It does not grant native bridge implementation, native handle, C ABI, FFI, platform object, Metal / AppKit bridge, GPU submission, render, renderer state write or public API permission.

### Metal device-layer owner evidence

`CjguiInternalRendererNoMetalDeviceLayerReadiness` provides device selection policy, layer binding policy, scale-color-space policy and no-metal-device-layer vocabulary.

It is docs evidence only for this implementation preflight. It does not grant `MTLDevice`, `CAMetalLayer`, platform object, native handle, raw pointer, Objective-C / Metal / AppKit / FFI call, command queue, drawable, command buffer, GPU submission, render execution or renderer state write permission.

### Backend platform object owner evidence

`CjguiInternalRendererNoPlatformObjectReadiness` provides native resource ownership policy, lifecycle teardown policy and confinement failure policy vocabulary.

It is docs evidence only. It does not become runtime input, platform object implementation permission, native handle permission, `MTLDevice` permission, `CAMetalLayer` permission, GPU submission permission or public API permission.

### Backend / Metal reference evidence

The reference pack proves future backend owners must keep `MTLDevice`, `CAMetalLayer`, command queue, drawable, command buffer, completion callback, resource retention, native handle and raw pointer out of core packet truth.

For this preflight, that evidence supports device creation admission, layer binding admission, backing scale / color space admission and no-device / no-layer fallback vocabulary. It does not approve real `MTLDevice`, real `CAMetalLayer`, command queue creation, drawable acquisition, command buffer commit, GPU submission or renderer state write.

### Risk ledger evidence

The risk ledger identifies FFI ownership, retain / release / destroy ordering, dangling pointer, double free, main-thread / AppKit boundary, GPU lifecycle and bridge optimism as high-risk areas.

For this preflight, those risks argue for a value-only Metal device-layer implementation admission boundary before any `MTLDevice`, `CAMetalLayer`, native handle, platform object, bridge call, C ABI or FFI declaration is allowed.

### Smoke evidence boundary

`labs/macos_bridge_smoke` can only remain feasibility / teardown / smoke evidence.

It can inform:

- C ABI and Objective-C bridge reachability on this machine.
- AppKit / Metal smoke feasibility.
- lifecycle log shape such as bridge init, metal capability check, command queue capability check, window created, metal setup complete, close requested, destroy complete and event loop exited.
- dehydrated frame metadata such as drawable size, scale and pixel format.
- auto-close verifier expectations as a future smoke strategy reference.
- smoke-only clear-color readback summary as feasibility diagnostics.

It cannot become:

- runtime truth.
- `MTLDevice` owner truth.
- `CAMetalLayer` owner truth.
- platform object owner truth.
- native handle truth.
- C ABI / FFI declaration truth.
- backend shell truth.
- renderer state write truth.
- visual baseline truth.
- GPU submission or render correctness proof.

## Candidate Comparison

### A. P1 internal Renderer Metal device-layer implementation admission value boundary bundle implementation

谨慎推荐。

Evidence is sufficient to add internal-only value facts for Metal device-layer implementation intent, device creation admission policy, layer binding admission guard, scale-color-space admission policy and no-metal-device-layer-implementation readiness.

The next implementation must remain value-only and must not create `MTLDevice`, `CAMetalLayer`, platform object, native handle, raw pointer, C ABI, FFI declaration, bridge call, retain / release / destroy call, Metal / AppKit / Objective-C object, command queue, drawable, command buffer, GPU work, render execution, renderer state write or public API.

### B. P1 internal Renderer Metal device creation admission preflight decision

备选，暂不选择。

Choose B only if the next value-boundary implementation finds device selection, no-device fallback, creation ownership or no-device-implementation vocabulary cannot be expressed safely inside the admission value boundary.

Current Metal device-layer owner manifest and reference pack evidence is enough to include device creation admission policy as value facts, so B is not needed first.

### C. P1 internal Renderer Metal layer binding admission preflight decision

备选，暂不选择。

Choose C only if `CAMetalLayer` / AppKit layer ownership, layer binding, drawable pool boundary or no-layer fallback evidence proves too coarse for the admission value boundary.

Current Metal device-layer owner manifest, platform object admission and reference pack evidence are enough to express value-only layer binding admission guard.

### D. P1 internal Renderer Metal scale-color-space admission preflight decision

备选，暂不选择。

Choose D only if Retina scale, drawable size, color space, pixel format or resize evidence proves insufficient for a combined admission value boundary.

Current Metal device-layer owner manifest, reference pack and smoke metadata evidence are enough to express dehydrated scale-color-space admission policy, without reading real display scale or color space.

### E. Native handle token preflight

暂缓。

Handle token identity / nullability / ownership remains downstream unless the next value-boundary implementation finds native handle admission facts insufficient. Current no-handle and handle admission stop-lines are enough for this preflight.

### F. Real backend shell implementation preflight

暂缓。

Real backend shell implementation must wait until device-layer implementation admission facts are stabilized and must still pass separate docs-only preflight.

### G. Real command queue implementation preflight

暂缓。

Command queue implementation is still downstream of device / layer implementation admission and remains too close to real Metal resource creation.

### H. Direct `MTLDevice` creation implementation

拒绝。

No `MTLDevice` creation, selection call, ownership, native object storage or Metal API call is approved.

### I. Direct `CAMetalLayer` creation / binding implementation

拒绝。

No `CAMetalLayer` creation, binding, configuration, drawable pool ownership or AppKit layer modification is approved.

### J. Direct native handle / raw pointer implementation

拒绝。

No native handle, raw pointer, pointer-like resource or foreign resource token implementation is approved.

### K. Direct C ABI / FFI declaration

拒绝。

No public C ABI, private C ABI, FFI declaration, foreign function declaration or signature expansion is approved.

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

Do not add Metal device-layer implementation receipt / record / publication, device-ready permission wrapper, layer-ready permission wrapper, native-handle permission wrapper, C-ABI / FFI permission wrapper, platform-object wrapper, backend implementation wrapper, GPU-submission wrapper or render-permission wrapper.

### Q. Consolidation

仅在发现明确 duplicate / low-value / self-wrapping evidence 时选择。

No duplicate / low-value / self-wrapping evidence was found. The next useful move is admission value boundary.

## Same-shape Boundary Brake

This preflight must not wrap any existing endpoint into a new permission-shaped tail.

Forbidden wrappers:

- Metal device-layer implementation receipt / record / publication.
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

Do not treat these as Metal device-layer implementation permission:

- `CjguiInternalRendererNoPlatformObjectImplementationReadiness`
- `CjguiInternalRendererNoNativeResourceBridgeReadiness`
- `CjguiInternalRendererNoMetalDeviceLayerReadiness`
- smoke evidence
- platform object implementation admission manifest
- native resource bridge manifest
- Metal device-layer owner manifest
- backend / Metal reference pack

If the next value boundary proceeds, it must prove new device creation admission / layer binding admission / scale-color-space admission / no-metal-device-layer-implementation semantics rather than wrapping the no-platform-object-implementation, no-native-resource-bridge or no-metal-device-layer tail.

## Stop-line

Until a later docs-only preflight explicitly opens a narrower runway:

- no `.cj` modification in this decision round.
- no backend shell object.
- no backend object.
- no platform object creation.
- no native handle.
- no raw pointer.
- no pointer-like resource.
- no foreign resource token.
- no C ABI.
- no FFI declaration.
- no bridge call.
- no retain / release / destroy.
- no `MTLDevice` creation.
- no `CAMetalLayer` creation / binding.
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

## Downstream

This preflight now points downstream to:

- [Metal device-layer implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-metal-device-layer-implementation-admission-value-boundary-closure-review.md)
- [Metal device-layer implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-next-boundary-decision.md)
- [Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md)
- [Metal device-layer implementation admission manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-metal-device-layer-implementation-admission-manifest-stabilization-closure-review.md)

The downstream owner is:

- [runtime_renderer_metal_device_layer_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_admission.cj)

The downstream canonical endpoint is:

- `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft()`

Downstream truth remains limited to Metal device-layer implementation intent / device creation admission policy / layer binding admission guard / scale-color-space admission policy / no-metal-device-layer-implementation readiness value facts. It still does not approve `MTLDevice`, `CAMetalLayer`, platform object, native handle, bridge, FFI, GPU submission, render execution, renderer state write or public API.

The downstream next-boundary decision confirms this endpoint is sufficient and selects:

`P1 internal Renderer Metal device-layer implementation admission manifest stabilization bundle implementation`

The downstream manifest stabilization has now sealed this endpoint and selects:

`P1 internal Renderer real command queue implementation preflight decision`

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
