# P1 Renderer platform object implementation admission manifest

日期：2026-05-05

状态：docs-only manifest stabilization

## Scope

本 manifest 固定 `runtime_renderer_platform_object_admission.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-platform-object-implementation endpoint。

本轮 docs-only：不修改 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮不创建 backend shell object、backend object、platform object、native handle 或 raw pointer；不新增 C ABI，不新增 FFI declaration，不调用 bridge，不调用 retain / release / destroy；不创建 `MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer；不调用 `commit`、`present`、`nextDrawable`、Metal / AppKit / Objective-C / FFI；不提交 GPU work，不执行 render，不写 renderer state，不扩 public API。

## Canonical Owner

Owner file：

- [runtime_renderer_platform_object_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_platform_object_admission.cj)

Runtime input：

- `CjguiInternalRendererNoNativeResourceBridgeReadiness`
- `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoPlatformObjectImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()`

Default draft：

- `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()` first obtains `CjguiInternalRendererNoNativeResourceBridgeReadiness` from `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()`.
- It builds platform object implementation intent, native handle admission policy, platform object lifecycle admission guard, teardown failure policy and no-platform-object-implementation readiness in owner-local value facts.
- It does not create backend shell object, backend object, platform object, native handle, raw pointer, `MTLDevice`, `CAMetalLayer`, `MTLCommandQueue`, drawable, command buffer, render pass, encoder or pipeline state.
- It does not add C ABI or FFI declarations, does not call bridge code, retain, release, destroy, `commit`, `present`, `nextDrawable`, Metal / AppKit / Objective-C / FFI.
- It does not submit GPU work, execute render, write renderer state, modify bridge / smoke / harness / native entry, or expand public API.

## Current Truth

The current truth is exactly:

- platform object implementation intent value facts.
- native handle admission policy value facts.
- platform object lifecycle admission guard value facts.
- teardown failure policy value facts.
- no-platform-object-implementation readiness value facts.

The canonical value chain is:

1. `CjguiInternalRendererNoNativeResourceBridgeReadiness`
2. `CjguiInternalRendererPlatformObjectImplementationIntent`
3. `CjguiInternalRendererNativeHandleAdmissionPolicy`
4. `CjguiInternalRendererPlatformObjectLifecycleAdmissionGuard`
5. `CjguiInternalRendererPlatformObjectTeardownFailurePolicy`
6. `CjguiInternalRendererNoPlatformObjectImplementationReadiness`

## Value Semantics

`CjguiInternalRendererPlatformObjectImplementationIntent` only records future platform object implementation intent facts. It is not platform object implementation permission, backend implementation permission, native handle permission, C ABI permission, FFI permission, Metal / AppKit bridge permission, GPU submission permission, render permission or public API permission.

`CjguiInternalRendererNativeHandleAdmissionPolicy` only records native handle admission facts. It does not create, save, expose, retain or release native handle, raw pointer, pointer-like resource, foreign resource token, platform object or backend object.

`CjguiInternalRendererPlatformObjectLifecycleAdmissionGuard` only records lifecycle admission guard facts. It does not create platform object, does not call bridge code, does not modify bridge / smoke / harness / native entry and does not call Metal / AppKit / Objective-C / FFI.

`CjguiInternalRendererPlatformObjectTeardownFailurePolicy` only records teardown ordering and failure rollback facts. It does not execute retain / release / destroy, does not register finalizer or callback, does not perform resource finalization side effects and does not mutate renderer state.

`CjguiInternalRendererNoPlatformObjectImplementationReadiness` seals current no-platform-object-implementation readiness facts. It is not platform object implementation permission, native handle permission, C ABI permission, FFI permission, Metal / AppKit bridge permission, GPU submission permission, render permission, renderer state write permission or public API permission.

## Relationship Facts

Platform object implementation admission facts relate to upstream native resource bridge facts only as dehydrated value facts:

- `CjguiInternalRendererNoNativeResourceBridgeReadiness` remains the only runtime input.
- Native resource bridge facts remain no-bridge / no-handle / no-C-ABI / no-FFI input value facts, not platform object permission.
- Backend platform object owner manifest remains docs evidence for native ownership, lifecycle teardown and confinement vocabulary only.
- Backend shell skeleton manifest remains docs evidence for no-resource lifecycle, rollback and teardown confinement only.
- `labs/macos_bridge_smoke` remains feasibility / teardown / smoke evidence only and is not runtime truth.
- Future native handle token, native teardown contract, Metal device-layer implementation, real backend shell, real platform object creation or real bridge / FFI work requires separate docs-only preflight before any implementation can be considered.

Downstream Metal device-layer implementation preflight has now opened and landed the admission value boundary:

- `P1 internal Renderer Metal device-layer implementation preflight decision`
- [Metal device-layer implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-preflight-decision.md)
- [Metal device-layer implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-metal-device-layer-implementation-admission-value-boundary-closure-review.md)
- [Metal device-layer implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-next-boundary-decision.md)
- [Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md)
- [Metal device-layer implementation admission manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-metal-device-layer-implementation-admission-manifest-stabilization-closure-review.md)
- Downstream endpoint: `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft()`.
- Downstream truth remains value-only: Metal device-layer implementation intent / device creation admission policy / layer binding admission guard / scale-color-space admission policy / no-metal-device-layer-implementation readiness facts.

## Explicit Non-Truth

The no-platform-object-implementation endpoint is not:

- platform object implementation permission.
- platform object permission.
- platform object creation permission.
- native handle permission.
- raw pointer permission.
- pointer-like resource permission.
- foreign resource token permission.
- C ABI permission.
- FFI permission.
- bridge call permission.
- retain / release / destroy permission.
- backend object permission.
- backend shell object permission.
- Metal / AppKit bridge permission.
- `MTLDevice` permission.
- `CAMetalLayer` permission.
- `MTLCommandQueue` permission.
- drawable permission.
- command buffer permission.
- `commit` / `present` / `nextDrawable` permission.
- GPU submission permission.
- render execution permission.
- renderer state write permission.
- diagnostics / event bus / observer / telemetry permission.
- public API / public C ABI permission.

Current truth has no backend shell object, no backend object, no platform object, no native handle, no raw pointer, no foreign resource token, no bridge call, no C ABI, no FFI declaration, no retain / release / destroy call, no resource finalization side effect, no work submit, no render execution, no renderer state mutation and no external API surface.

## Evidence Chain

- [Platform object implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-next-boundary-decision.md) confirmed `CjguiInternalRendererNoPlatformObjectImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()` is sufficient as the current no-platform-object-implementation endpoint.
- [Platform object implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-platform-object-implementation-admission-value-boundary-closure-review.md) added the internal-only owner and verified the no-platform-object / no-native-handle / no-bridge / no-submit / no-render / no-state-write stop-line.
- [Platform object implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-preflight-decision.md) proved enough implementation admission / native handle admission / lifecycle admission / teardown failure evidence to open the value boundary.
- [Native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md) fixed the upstream no-native-resource-bridge endpoint and denied native handle, raw pointer, C ABI, FFI, bridge call, platform object, GPU submission, render and renderer state write permission.
- [Backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md) remains native ownership / teardown / confinement evidence only and does not become runtime input.

## Same-shape Boundary Brake

This round chooses manifest stabilization and closes the current no-platform-object-implementation endpoint.

It explicitly rejects:

- platform-object permission wrapper.
- native-handle permission wrapper.
- C-ABI permission wrapper.
- FFI permission wrapper.
- Metal-device permission wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- render-permission wrapper.
- renderer-state-write wrapper.
- receipt / record / publication.
- public API wrapper.

`CjguiInternalRendererNoPlatformObjectImplementationReadiness` must not be wrapped into another tail endpoint unless a future docs-only preflight proves new owner / lifecycle / teardown / failure / verification semantics that are not already captured here.

Future work approaching native handle token, native teardown contract, Metal device-layer implementation, real backend shell, real platform object creation or real bridge / FFI must first pass docs-only preflight.

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

### A. P1 internal Renderer Metal device-layer implementation preflight decision

推荐为下一阶段 opening。

Reasoning：platform object implementation admission is now manifest-stabilized as a no-platform-object-implementation endpoint. The next docs-only question can evaluate device / layer implementation admission risk while preserving the no-platform-object / no-native-handle / no-bridge / no-FFI stop-line.

### B. Native handle token preflight

暂缓。

Handle identity / nullability / ownership-token shape should wait until Metal device-layer implementation preflight proves a narrower need. Current native handle admission facts are enough for the sealed endpoint.

### C. Native teardown contract hardening

暂缓。

Choose only if a future review finds teardown contract / failure rollback evidence insufficient. Current teardown failure policy is enough to close the endpoint.

### D. Real backend shell implementation preflight

暂缓。

Real backend shell implementation still needs Metal device-layer implementation risk and resource lifetime stop-lines to be evaluated first.

### E. Real platform object creation preflight

暂缓。

Real platform object creation remains too early until implementation admission and Metal device-layer implementation preflights define resource ownership and bridge stop-lines.

### F. Direct platform object implementation

拒绝。

### G. Direct native handle / raw pointer implementation

拒绝。

### H. Direct C ABI / FFI declaration

拒绝。

### I. Direct retain / release / destroy implementation

拒绝。

### J. Direct Metal / AppKit / Objective-C implementation

拒绝。

### K. GPU submission / render execution

拒绝。

### L. Renderer state write

拒绝。

### M. Public API / C ABI expansion

拒绝。

### N. Receipt / record / publication

拒绝。

### O. Consolidation

仅在发现明确 duplicate / low-value / self-wrapping evidence 时选择。

## 决策结论

`runtime/cjgui/src/runtime_renderer_platform_object_admission.cj` is now the fixed platform object implementation admission owner for the current no-platform-object-implementation endpoint.

`CjguiInternalRendererNoPlatformObjectImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()` is the canonical tail for platform object implementation admission value facts. It is not permission to implement platform objects, hold native handles, add C ABI / FFI, call bridge code, create Metal / AppKit objects, submit GPU work, render, write renderer state or expose public API.

唯一 next opening：

`P1 internal Renderer Metal device-layer implementation preflight decision`

## Downstream Metal Device-layer Implementation Preflight

Renderer Metal device-layer implementation preflight 已完成：

- [2026-05-05-p1-renderer-metal-device-layer-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-preflight-decision.md)
- [2026-05-05-p1-renderer-metal-device-layer-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-next-boundary-decision.md)
- [2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md)
- [2026-05-05-p1-internal-renderer-metal-device-layer-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-metal-device-layer-implementation-admission-manifest-stabilization-closure-review.md)

该 downstream preflight 使用本 manifest 的 `CjguiInternalRendererNoPlatformObjectImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()` 作为 runtime input candidate。downstream admission value boundary 已落地，next-boundary decision 已确认 `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft()` 足够作为当前 no-metal-device-layer-implementation endpoint。

Output truth 仅限 Metal device-layer implementation intent / device creation admission policy / layer binding admission guard / scale-color-space admission policy / no-metal-device-layer-implementation readiness value facts。

该 downstream preflight 不批准 `MTLDevice`、`CAMetalLayer`、platform object、native handle、raw pointer、C ABI、FFI declaration、bridge call、retain / release / destroy、Metal / AppKit / Objective-C、GPU submission、render execution、renderer state write 或 public API。

唯一 downstream next opening：

`P1 internal Renderer real command queue implementation preflight decision`

## 下游真实 platform object 第一刀预检

Renderer real backend platform object first implementation preflight decision 已完成：

- [2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-preflight-decision.md)

该 downstream 回看本 manifest 的 `CjguiInternalRendererNoPlatformObjectImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()` 作为 planning evidence，确认下一步只可新增极窄 internal runtime owner shell。它不把本 manifest 升格为 platform object creation permission，不授权 native handle、raw pointer、C ABI、FFI declaration、bridge call、retain / release / destroy、Metal / AppKit / Objective-C、GPU submission、renderer state write 或 public API。

新的 downstream 后续入口：

`P1 internal Renderer real backend platform object first implementation slice bundle`

## 下游真实 platform object 第一刀切片闭环

Renderer real backend platform object first implementation slice 已完成：

- [2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-closure-review.md)
- [runtime_renderer_backend_platform_object_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_platform_object_real.cj)

该 downstream owner 只消费本 manifest 固定的 `CjguiInternalRendererNoPlatformObjectImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()`，canonical endpoint 是 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()`。

它只表达 owner-local shell intent / shell policy / teardown proof / failure policy / no-real-backend-platform-object readiness facts。本 manifest 仍不被升格为 platform object creation permission、native handle permission、C ABI / FFI permission、Metal / AppKit permission、GPU submission permission、renderer state write permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer real backend platform object first implementation slice closure / next real backend platform object decision`

## 下游真实 platform object 第一刀后续边界决策

Renderer real backend platform object first implementation slice next-boundary decision 已完成：

- [2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-next-boundary-decision.md)

该 downstream decision 确认 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()` 足够作为当前 no-real-backend-platform-object shell endpoint。它仍只把本 manifest 固定的 `CjguiInternalRendererNoPlatformObjectImplementationReadiness` 作为 upstream runtime input，不把本 manifest 升格为 platform object creation permission、native handle permission、C ABI / FFI permission、Metal / AppKit permission、GPU submission permission、renderer state write permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer real backend platform object first implementation slice manifest stabilization bundle implementation`

## 下游真实 platform object 第一刀切片 manifest 稳定化

Renderer real backend platform object first implementation slice manifest stabilization 已完成：

- [2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)
- [2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-manifest-stabilization-closure-review.md)

该 downstream manifest 仍只消费本 manifest 固定的 `CjguiInternalRendererNoPlatformObjectImplementationReadiness`。它不把本 manifest 升格为 platform object creation permission、native handle permission、C ABI / FFI permission、Metal / AppKit permission、GPU submission permission、renderer state write permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer real backend platform object branch closure / next real platform object decision`
