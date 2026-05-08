# P1 Renderer Metal device-layer implementation admission manifest

日期：2026-05-05

状态：docs-only manifest stabilization

## Scope

本 manifest 固定 `runtime_renderer_metal_device_layer_admission.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-metal-device-layer-implementation endpoint。

本轮 docs-only：不修改 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮不创建 backend shell object、backend object、platform object、native handle 或 raw pointer；不新增 C ABI，不新增 FFI declaration，不调用 bridge，不调用 retain / release / destroy；不创建 `MTLDevice`、不创建或绑定 `CAMetalLayer`、不创建 `MTLCommandQueue`、drawable 或 command buffer；不调用 `commit`、`present`、`nextDrawable`、Metal / AppKit / Objective-C / FFI；不提交 GPU work，不执行 render，不写 renderer state，不扩 public API。

## Canonical Owner

Owner file：

- [runtime_renderer_metal_device_layer_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_admission.cj)

Runtime input：

- `CjguiInternalRendererNoPlatformObjectImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft()`

Default draft：

- `cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft()` first obtains `CjguiInternalRendererNoPlatformObjectImplementationReadiness` from `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()`.
- It builds Metal device-layer implementation intent, device creation admission policy, layer binding admission guard, scale-color-space admission policy and no-metal-device-layer-implementation readiness in owner-local value facts.
- It does not create backend shell object, backend object, platform object, native handle, raw pointer, `MTLDevice`, `CAMetalLayer`, `MTLCommandQueue`, drawable, command buffer, render pass, encoder or pipeline state.
- It does not add C ABI or FFI declarations, does not call bridge code, retain, release, destroy, `commit`, `present`, `nextDrawable`, Metal / AppKit / Objective-C / FFI.
- It does not submit GPU work, execute render, write renderer state, modify bridge / smoke / harness / native entry, or expand public API.

## Current Truth

The current truth is exactly:

- Metal device-layer implementation intent value facts.
- device creation admission policy value facts.
- layer binding admission guard value facts.
- scale-color-space admission policy value facts.
- no-metal-device-layer-implementation readiness value facts.

The canonical value chain is:

1. `CjguiInternalRendererNoPlatformObjectImplementationReadiness`
2. `CjguiInternalRendererMetalDeviceLayerImplementationIntent`
3. `CjguiInternalRendererMetalDeviceCreationAdmissionPolicy`
4. `CjguiInternalRendererMetalLayerBindingAdmissionGuard`
5. `CjguiInternalRendererMetalScaleColorSpaceAdmissionPolicy`
6. `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness`

## Value Semantics

`CjguiInternalRendererMetalDeviceLayerImplementationIntent` only records future Metal device-layer implementation intent value facts. It is not device-ready permission, layer-ready permission, platform-object permission, native-handle permission, backend implementation permission, GPU submission permission, render permission or public API permission.

`CjguiInternalRendererMetalDeviceCreationAdmissionPolicy` only records future device creation admission facts. It does not create `MTLDevice`, query a real device, create command queue, hold native handle, expose raw pointer or call Metal / AppKit / Objective-C / FFI.

`CjguiInternalRendererMetalLayerBindingAdmissionGuard` only records future layer binding admission facts. It does not create, bind, configure or hold `CAMetalLayer`; it does not acquire drawable, create platform object, call bridge code or grant backend implementation permission.

`CjguiInternalRendererMetalScaleColorSpaceAdmissionPolicy` only records dehydrated drawable size / backing scale / pixel format / color-space admission facts. It does not query real screen, real layer or real color space, and it does not mutate renderer state.

`CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` seals current no-metal-device-layer-implementation readiness facts. It is not `MTLDevice` permission, `CAMetalLayer` permission, native handle permission, C ABI permission, FFI permission, platform object permission, GPU submission permission, render permission, renderer state write permission or public API permission.

## Relationship Facts

Metal device-layer implementation admission facts relate to upstream platform object implementation admission facts only as dehydrated value facts:

- `CjguiInternalRendererNoPlatformObjectImplementationReadiness` remains the only runtime input.
- Platform object implementation admission facts remain no-platform-object / no-handle / no-bridge / no-C-ABI / no-FFI input value facts, not device / layer permission.
- Native resource bridge manifest remains docs evidence for no-handle, no-bridge and teardown contract vocabulary only.
- Metal device-layer owner manifest remains docs evidence for device selection, layer binding and scale-color-space vocabulary only.
- Backend / Metal reference pack and smoke evidence remain evidence only and are not runtime inputs.
- Future real command queue implementation, real backend shell implementation, native handle token, real `MTLDevice` / `CAMetalLayer`, GPU submission or renderer state write work requires separate docs-only preflight before any implementation can be considered.

Downstream real command queue implementation preflight is now the only next opening after this manifest:

- `P1 internal Renderer real command queue implementation preflight decision`

Downstream real command queue implementation preflight is now recorded in:

- [2026-05-05-p1-renderer-real-command-queue-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-preflight-decision.md)

That decision uses this manifest's `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft()` as the next runtime input candidate and chooses a value-only real command queue implementation admission boundary. It does not approve `MTLCommandQueue`, `newCommandQueue`, command buffer creation, native handle, C ABI, FFI declaration, bridge call, GPU submission, render execution, renderer state write or public API.

Downstream real command queue implementation admission value boundary is now recorded in:

- [2026-05-05-p1-internal-renderer-real-command-queue-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-command-queue-implementation-admission-value-boundary-closure-review.md)

That closure consumes this manifest's `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` as the only runtime input and seals `CjguiInternalRendererNoRealCommandQueueImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueAdmissionDraft()` as value-only no-real-command-queue-implementation facts. It does not turn this manifest into `MTLCommandQueue` permission, `newCommandQueue` permission, command buffer permission, native-handle permission, C ABI / FFI permission, GPU-submission permission, render permission, renderer-state-write permission or public API permission.

Downstream real command queue implementation admission next-boundary decision is now recorded in:

- [2026-05-05-p1-renderer-real-command-queue-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-admission-next-boundary-decision.md)

That decision confirms the downstream no-real-command-queue-implementation endpoint is sufficient and selects manifest stabilization next. This manifest remains the upstream no-metal-device-layer-implementation input; it does not become queue-ready permission, `newCommandQueue` permission, command-buffer permission, native-handle permission, GPU-submission permission, render permission, renderer-state-write permission or public API permission.

Downstream real command queue implementation admission manifest stabilization is now recorded in:

- [2026-05-05-p1-renderer-real-command-queue-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-admission-manifest.md)
- [2026-05-05-p1-internal-renderer-real-command-queue-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-command-queue-implementation-admission-manifest-stabilization-closure-review.md)

That manifest seals `CjguiInternalRendererNoRealCommandQueueImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueAdmissionDraft()` as no-real-command-queue-implementation value facts. This manifest remains upstream device-layer implementation admission evidence only; it does not become queue-ready permission, `MTLCommandQueue` permission, `newCommandQueue` permission, command-buffer permission, GPU-submission permission, render permission, renderer-state-write permission or public API permission. The downstream chain now points to real drawable implementation preflight.

Downstream real drawable implementation preflight is now recorded in:

- [2026-05-05-p1-renderer-real-drawable-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-implementation-preflight-decision.md)

That decision keeps this manifest as device-layer implementation admission evidence only. `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` remains not a runtime input, not layer-ready permission, not drawable-ready permission, not `nextDrawable` permission, not present permission, not command-buffer permission, not GPU-submission permission, not render permission, not renderer-state-write permission and not public API permission for the next real drawable admission slice.

## 下游真实 Metal device-layer 第一刀预检

下游 real Metal device-layer first implementation preflight decision 已完成：

- [real Metal device-layer first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-preflight-decision.md)

该 downstream decision 回看本 manifest 的 Metal device-layer implementation admission facts 作为 evidence，但不把 `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` 升格为 `MTLDevice` permission、`CAMetalLayer` permission、native handle permission、C ABI / FFI permission、command queue permission、drawable permission、command buffer permission、GPU submission permission、renderer state write permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer real Metal device-layer first implementation slice bundle`

## Explicit Non-Truth

The no-metal-device-layer-implementation endpoint is not:

- `MTLDevice` permission.
- `MTLDevice` ownership.
- `CAMetalLayer` permission.
- `CAMetalLayer` ownership.
- native handle permission.
- raw pointer permission.
- pointer-like resource permission.
- foreign resource token permission.
- C ABI permission.
- FFI permission.
- bridge call permission.
- retain / release / destroy permission.
- platform object permission.
- backend object permission.
- backend shell object permission.
- `MTLCommandQueue` permission.
- drawable permission.
- command buffer permission.
- `commit` / `present` / `nextDrawable` permission.
- GPU submission permission.
- render execution permission.
- renderer state write permission.
- diagnostics / event bus / observer / telemetry permission.
- public API / public C ABI permission.

Current truth has no backend shell object, no backend object, no platform object, no native handle, no raw pointer, no foreign resource token, no bridge call, no C ABI, no FFI declaration, no retain / release / destroy call, no `MTLDevice`, no `CAMetalLayer`, no command queue, no drawable, no command buffer, no work submit, no render execution, no renderer state mutation and no external API surface.

## Evidence Chain

- [Metal device-layer implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-next-boundary-decision.md) confirmed `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft()` is sufficient as the current no-metal-device-layer-implementation endpoint.
- [Metal device-layer implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-metal-device-layer-implementation-admission-value-boundary-closure-review.md) added the internal-only owner and verified the no-device / no-layer / no-platform-object / no-native-handle / no-bridge / no-submit / no-render / no-state-write stop-line.
- [Metal device-layer implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-preflight-decision.md) proved enough device creation admission, layer binding admission, scale-color-space admission and no-metal-device-layer-implementation evidence to open the value boundary.
- [Platform object implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-manifest.md) fixed the upstream no-platform-object-implementation endpoint and denied platform object, native handle, bridge, C ABI, FFI, GPU submission, render and renderer state write permission.
- [Native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md) fixed no-native-resource-bridge facts and remains upstream docs evidence only.
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md) remains device / layer owner vocabulary evidence only and does not become runtime input for implementation admission.

## Same-shape Boundary Brake

This round chooses manifest stabilization and closes the current no-metal-device-layer-implementation endpoint.

It explicitly rejects:

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
- receipt / record / publication.
- public API wrapper.

`CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` must not be wrapped into another tail endpoint unless a future docs-only preflight proves new owner / lifecycle / teardown / failure / verification semantics that are not already captured here.

Future work approaching real command queue implementation, real backend shell implementation, native handle token, real `MTLDevice` / `CAMetalLayer`, GPU submission or renderer state write must first pass docs-only preflight.

## Stop-line

Until a later docs-only preflight explicitly opens a narrower runway:

- no `.cj` modification for this manifest.
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
- no completion callback.
- no diagnostics / event bus / observer / telemetry.
- no public API / public C ABI expansion.
- no module-level `var`.

## Public Surface

The public declaration allowlist remains unchanged:

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

## Next Stage Candidate Comparison

### A. P1 internal Renderer real command queue implementation preflight decision

推荐为下一阶段 opening。

Reasoning：Metal device-layer implementation admission is now manifest-stabilized as a no-metal-device-layer-implementation endpoint. The next docs-only question can evaluate real command queue implementation risk while preserving the no-device / no-layer / no-native-handle / no-bridge / no-GPU-submission stop-line.

### B. Real backend shell implementation preflight

暂缓。

Real backend shell implementation should wait until command queue implementation admission risk is evaluated, because backend shell implementation may otherwise imply resource ownership too broadly.

### C. Native handle token preflight

暂缓。

Handle identity / nullability / ownership-token shape should wait until a narrower implementation preflight proves an actual native handle gap. Current no-handle and handle-admission facts are enough for the sealed endpoint.

### D. Metal device creation admission hardening

暂缓。

Choose only if a future review finds device creation admission policy cannot express device selection, no-device fallback, no-device-query or no-command-queue facts clearly enough.

### E. Metal layer binding admission hardening

暂缓。

Choose only if a future review finds layer binding admission guard cannot express layer binding, drawable pool boundary, no-layer fallback, no-layer-creation or no-drawable-acquisition facts clearly enough.

### F. Scale / color-space / resize admission hardening

暂缓。

Choose only if a future review finds drawable size, backing scale, pixel format, color space or resize admission facts insufficient.

### G. Direct `MTLDevice` creation implementation

拒绝。

### H. Direct `CAMetalLayer` creation / binding implementation

拒绝。

### I. Direct native handle / raw pointer implementation

拒绝。

### J. Direct C ABI / FFI declaration

拒绝。

### K. Direct Metal / AppKit / Objective-C implementation

拒绝。

### L. GPU submission / render execution

拒绝。

### M. Renderer state write

拒绝。

### N. Public API / C ABI expansion

拒绝。

### O. Receipt / record / publication

拒绝。

### P. Consolidation

仅在发现明确 duplicate / low-value / self-wrapping evidence 时选择。

## 当前封账结论

`runtime/cjgui/src/runtime_renderer_metal_device_layer_admission.cj` 是当前 no-metal-device-layer-implementation endpoint 的固定 Metal device-layer implementation admission owner。

`CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft()` 是 Metal device-layer implementation admission value facts 的 canonical tail。它不是创建 `MTLDevice`、绑定 `CAMetalLayer`、持有 native handle、新增 C ABI / FFI、调用 bridge code、提交 GPU work、render、写 renderer state 或暴露 public API 的 permission。

唯一 downstream next opening：

`P1 internal Renderer real drawable implementation admission value boundary bundle implementation`

## 下游真实 Metal device-layer 第一刀切片

下游 real Metal device-layer first implementation slice 已完成：

- [real Metal device-layer first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-preflight-decision.md)
- [real Metal device-layer first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-closure-review.md)
- [runtime_renderer_metal_device_layer_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj)

该 downstream slice 没有消费本 implementation admission endpoint 作为 runtime input；它只把本 manifest 作为 evidence，并把 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` 作为唯一 runtime input。新的 canonical endpoint 是 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`，仍不是 `MTLDevice` / `CAMetalLayer` creation permission、command queue permission、drawable permission、GPU submission permission、renderer state write permission、backend-ready truth 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer first implementation slice closure / next real Metal device-layer decision`

## 下游真实 Metal device-layer 切片后续边界决策

下游 real Metal device-layer first implementation slice next-boundary decision 已完成：

- [real Metal device-layer first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-next-boundary-decision.md)

该 downstream decision 继续把本 manifest 的 `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` 只作为 evidence，不作为 runtime input 或 device permission。它确认 downstream shell endpoint 足够，但由于 `cjpm build` 在上一轮未完成，下一步优先补 build verification follow-up，不把本 manifest、downstream shell 或 build gap 升格为 `MTLDevice` / `CAMetalLayer` creation permission、native bridge permission、command queue permission、drawable permission、GPU submission permission、renderer state write permission、backend-ready truth 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer first implementation slice build verification follow-up`

## 下游真实 Metal device-layer manifest 封账

下游 real Metal device-layer first implementation slice manifest stabilization 已完成：

- [real Metal device-layer first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-manifest.md)
- [real Metal device-layer first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-manifest-stabilization-closure-review.md)

该 downstream manifest 回看本 manifest 的 Metal device-layer implementation admission facts 作为 evidence，但不消费 `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` 作为 runtime input，也不把它升格为真实 `MTLDevice` permission、真实 `CAMetalLayer` permission、native handle permission、command queue permission、drawable permission、GPU submission permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer branch closure / next real Metal device-layer decision`

## 下游真实 Metal device-layer 分支后续边界决策

下游 real Metal device-layer branch next-boundary decision 已完成：

- [real Metal device-layer branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-metal-device-layer-branch-next-boundary-decision.md)

该 downstream decision 回看本 manifest 的 Metal device-layer implementation admission facts 作为 evidence，但不消费 `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` 作为 runtime input，也不把它升格为真实 `MTLDevice` permission、真实 `CAMetalLayer` permission、native handle permission、`MTLCommandQueue` permission、drawable permission、command buffer permission、GPU submission permission、renderer state write permission、backend ready truth 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real command queue first implementation preflight decision`
