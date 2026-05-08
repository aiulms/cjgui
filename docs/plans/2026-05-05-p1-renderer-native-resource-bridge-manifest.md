# P1 Renderer native resource bridge manifest

日期：2026-05-05

状态：docs-only manifest stabilization

## Scope

本 manifest 固定 `runtime_renderer_native_resource_bridge.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-native-resource-bridge endpoint。

本轮 docs-only：不修改 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮不创建 backend shell object、backend object、platform object、native handle 或 raw pointer；不新增 C ABI，不新增 FFI declaration，不调用 bridge，不调用 retain / release / destroy；不创建 `MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer；不调用 `commit`、`present`、`nextDrawable`、Metal / AppKit / Objective-C / FFI；不提交 GPU work，不执行 render，不写 renderer state，不扩 public API。

## Canonical Owner

Owner file：

- [runtime_renderer_native_resource_bridge.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_resource_bridge.cj)

Runtime input：

- `CjguiInternalRendererNoResourceBackendShellReadiness`
- `cjguiInternalExecuteDefaultRendererBackendShellSkeletonDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoNativeResourceBridgeReadiness`
- `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()`

Default draft：

- `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()` first obtains `CjguiInternalRendererNoResourceBackendShellReadiness` from `cjguiInternalExecuteDefaultRendererBackendShellSkeletonDraft()`.
- It builds native resource bridge intent, handle confinement policy, bridge call admission guard, native teardown contract policy and no-native-resource-bridge readiness in owner-local value facts.
- It does not create backend shell object, backend object, platform object, native handle, raw pointer, `MTLDevice`, `CAMetalLayer`, `MTLCommandQueue`, drawable, command buffer, render pass, encoder or pipeline state.
- It does not add C ABI or FFI declarations, does not call bridge code, retain, release, destroy, `commit`, `present`, `nextDrawable`, Metal / AppKit / Objective-C / FFI.
- It does not submit GPU work, execute render, write renderer state, modify bridge / smoke / harness / native entry, or expand public API.

## Current Truth

The current truth is exactly:

- native resource bridge intent value facts.
- handle confinement policy value facts.
- bridge call admission guard value facts.
- native teardown contract policy value facts.
- no-native-resource-bridge readiness value facts.

The canonical value chain is:

1. `CjguiInternalRendererNoResourceBackendShellReadiness`
2. `CjguiInternalRendererNativeResourceBridgeIntent`
3. `CjguiInternalRendererNativeHandleConfinementPolicy`
4. `CjguiInternalRendererBridgeCallAdmissionGuard`
5. `CjguiInternalRendererNativeTeardownContractPolicy`
6. `CjguiInternalRendererNoNativeResourceBridgeReadiness`

## Value Semantics

`CjguiInternalRendererNativeResourceBridgeIntent` only records future native resource bridge intent facts. It is not native bridge implementation permission, C ABI permission, FFI permission, native handle permission, platform object permission or backend implementation permission.

`CjguiInternalRendererNativeHandleConfinementPolicy` only records handle confinement facts. It does not create, save, expose, retain, release or destroy native handle, raw pointer, pointer-like resource, foreign resource token or platform object.

`CjguiInternalRendererBridgeCallAdmissionGuard` only records future bridge call admission / denial facts. It does not call bridge code, does not modify bridge / smoke / harness / native entry and does not add C ABI, FFI declaration or foreign function declaration.

`CjguiInternalRendererNativeTeardownContractPolicy` only records native teardown contract ordering / rollback / no-finalization value facts. It does not execute retain / release / destroy, does not run teardown callback, does not register finalizer and does not perform resource finalization side effects.

`CjguiInternalRendererNoNativeResourceBridgeReadiness` seals current no-native-resource-bridge readiness facts. It is not native bridge implementation permission, native handle permission, C ABI permission, FFI permission, platform object permission, Metal / AppKit bridge permission, GPU submission permission, render permission, renderer state write permission, diagnostics permission or public API permission.

## Relationship Facts

Native resource bridge facts relate to upstream no-resource backend shell facts only as dehydrated value facts:

- `CjguiInternalRendererNoResourceBackendShellReadiness` remains the only runtime input.
- Backend shell skeleton facts remain input value facts, not native bridge permission, native handle permission, platform object permission, C ABI permission, FFI permission or backend implementation permission.
- Backend platform object owner and Metal device-layer owner manifests remain docs evidence only; they are not runtime inputs for this owner.
- `labs/macos_bridge_smoke` remains feasibility / teardown / smoke evidence only and is not runtime truth.
- Future platform object implementation, native handle token, native teardown contract, Metal device-layer implementation or real bridge / FFI work requires separate docs-only preflight before any implementation can be considered.

Downstream platform object implementation preflight is now the only next opening after this manifest:

- `P1 internal Renderer platform object implementation preflight decision`

Downstream platform object implementation admission value boundary is now complete:

- [2026-05-05-p1-internal-renderer-platform-object-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-platform-object-implementation-admission-value-boundary-closure-review.md)

That downstream owner consumes `CjguiInternalRendererNoNativeResourceBridgeReadiness` only as value input and seals `CjguiInternalRendererNoPlatformObjectImplementationReadiness` without creating platform object, native handle, raw pointer, C ABI, FFI declaration, bridge call, retain / release / destroy, Metal / AppKit / Objective-C object, GPU submission, render execution, renderer state write or public API.

## Explicit Non-Truth

The no-native-resource-bridge endpoint is not:

- native bridge implementation permission.
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

- [Native resource bridge next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-next-boundary-decision.md) confirmed `CjguiInternalRendererNoNativeResourceBridgeReadiness` / `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()` is sufficient as the current no-native-resource-bridge endpoint.
- [Native resource bridge value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-native-resource-bridge-value-boundary-closure-review.md) added the internal-only owner and verified the no-handle / no-bridge / no-C-ABI / no-FFI / no-submit / no-render / no-state-write stop-line.
- [Native resource bridge preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-preflight-decision.md) proved enough handle confinement / bridge admission / teardown contract evidence to open the value boundary.
- [Backend shell skeleton manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-backend-shell-skeleton-manifest.md) fixed the upstream no-resource-backend-shell endpoint and denied native handle, raw pointer, bridge call, platform object, Metal / AppKit bridge, GPU submission, render and renderer state write permission.
- [Backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md) remains native ownership / teardown / confinement evidence only and does not become runtime input.
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md) remains device / layer vocabulary evidence only and does not become native bridge permission.

## Same-shape Boundary Brake

This round chooses manifest stabilization and closes the current no-native-resource-bridge endpoint.

It explicitly rejects:

- native bridge receipt / record / publication.
- native-handle permission wrapper.
- C-ABI permission wrapper.
- FFI permission wrapper.
- platform-object permission wrapper.
- Metal-device permission wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- render-permission wrapper.
- renderer-state-write wrapper.
- public API wrapper.

`CjguiInternalRendererNoNativeResourceBridgeReadiness` must not be wrapped into another tail endpoint unless a future docs-only preflight proves new owner / lifecycle / teardown / failure / verification semantics that are not already captured here.

Future work approaching platform object implementation, native handle token, native teardown contract, Metal device-layer implementation or real bridge / FFI must first pass docs-only preflight.

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

### A. P1 internal Renderer platform object implementation preflight decision

推荐为下一阶段 opening。

Reasoning：native resource bridge is now manifest-stabilized as a no-native-resource-bridge endpoint. The next docs-only question can evaluate platform object create / retain / release / teardown / failure / confinement implementation risk without creating platform object, native handle, raw pointer, C ABI, FFI declaration, bridge call, Metal / AppKit object, GPU submission, render or renderer state write.

### B. Native handle token preflight

暂缓。

Handle identity / nullability / ownership-token shape should wait until platform object implementation preflight proves a narrower need. Current handle confinement facts are enough for the sealed endpoint.

### C. Native teardown contract hardening

暂缓。

Choose only if a future review finds teardown contract / failure rollback evidence insufficient. Current native teardown contract policy is enough to close the endpoint.

### D. Metal device-layer implementation preflight

暂缓。

Device / layer implementation remains downstream of platform object implementation risk and native bridge constraints.

### E. Real backend shell implementation preflight

暂缓。

Real backend shell implementation still needs platform object and native bridge implementation stop-lines to be evaluated first.

### F. Direct native bridge implementation

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

`runtime/cjgui/src/runtime_renderer_native_resource_bridge.cj` is now the fixed native resource bridge owner for the current no-native-resource-bridge endpoint.

`CjguiInternalRendererNoNativeResourceBridgeReadiness` / `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()` is the canonical tail for native resource bridge value facts. It is not permission to implement native bridge, hold native handle, add C ABI / FFI, create platform object, call Metal / AppKit bridge, submit GPU work, render, write renderer state or expose public API.

唯一 next opening：

`P1 internal Renderer platform object implementation preflight decision`

Downstream implementation admission value boundary is now complete:

- [2026-05-05-p1-internal-renderer-platform-object-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-platform-object-implementation-admission-value-boundary-closure-review.md)

The new downstream canonical endpoint is `CjguiInternalRendererNoPlatformObjectImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()`.

Downstream platform object implementation admission next-boundary decision is now complete:

- [2026-05-05-p1-renderer-platform-object-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-next-boundary-decision.md)

The downstream no-platform-object-implementation endpoint is sufficient and now points to manifest stabilization, not platform object creation or native bridge implementation.

## Downstream Platform Object Implementation Preflight

Renderer platform object implementation preflight 已完成：

- [2026-05-05-p1-renderer-platform-object-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-preflight-decision.md)

该 preflight 使用本 manifest 的 `CjguiInternalRendererNoNativeResourceBridgeReadiness` / `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()` 作为下一步 runtime input candidate，并选择 `P1 internal Renderer platform object implementation admission value boundary bundle implementation` 作为唯一 next opening。

Output truth 仅限 platform object implementation intent / native handle admission policy / platform object lifecycle admission guard / teardown failure policy / no-platform-object-implementation readiness value facts。

该 downstream preflight 不批准 platform object、native handle、raw pointer、C ABI、FFI declaration、bridge call、retain / release / destroy、Metal / AppKit / Objective-C、GPU submission、render execution、renderer state write 或 public API。

唯一 next opening：

`P1 internal Renderer platform object implementation admission value boundary bundle implementation`

## Downstream Platform Object Implementation Admission Next-boundary Decision

Renderer platform object implementation admission next-boundary decision 已完成：

- [2026-05-05-p1-renderer-platform-object-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-next-boundary-decision.md)

该 downstream decision 确认 `CjguiInternalRendererNoPlatformObjectImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()` 已足够作为当前 no-platform-object-implementation endpoint。Native resource bridge manifest remains upstream evidence and does not become platform object permission, native handle permission, C ABI / FFI permission, GPU submission permission, render permission or public API permission.

唯一 downstream next opening：

`P1 internal Renderer platform object implementation admission manifest stabilization bundle implementation`

## Downstream Platform Object Implementation Admission Manifest Stabilization

Renderer platform object implementation admission manifest stabilization 已完成：

- [2026-05-05-p1-renderer-platform-object-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-manifest.md)
- [2026-05-05-p1-internal-renderer-platform-object-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-platform-object-implementation-admission-manifest-stabilization-closure-review.md)

该 downstream manifest consumes only `CjguiInternalRendererNoNativeResourceBridgeReadiness` as runtime input and seals `CjguiInternalRendererNoPlatformObjectImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()`.

Native resource bridge remains upstream no-bridge / no-handle / no-C-ABI / no-FFI value evidence only. It does not become platform object implementation permission, native handle permission, C ABI / FFI permission, Metal / AppKit bridge permission, GPU submission permission, render permission, renderer state write permission or public API permission.

唯一 downstream next opening：

`P1 internal Renderer Metal device-layer implementation preflight decision`

## Downstream Metal Device-layer Implementation Preflight

Renderer Metal device-layer implementation preflight 已完成：

- [2026-05-05-p1-renderer-metal-device-layer-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-preflight-decision.md)

该 downstream preflight uses platform object implementation admission as its runtime input candidate and keeps this native resource bridge manifest as upstream docs evidence only. `CjguiInternalRendererNoNativeResourceBridgeReadiness` does not become `MTLDevice` permission, `CAMetalLayer` permission, native handle permission, C ABI / FFI permission, Metal / AppKit bridge permission, GPU submission permission, render permission, renderer state write permission or public API permission.

The downstream output truth is limited to Metal device-layer implementation intent / device creation admission policy / layer binding admission guard / scale-color-space admission policy / no-metal-device-layer-implementation readiness value facts.

唯一 downstream next opening：

`P1 internal Renderer Metal device-layer implementation admission value boundary bundle implementation`

## Downstream Real Command Queue Implementation Preflight

Renderer real command queue implementation preflight 已完成：

- [2026-05-05-p1-renderer-real-command-queue-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-preflight-decision.md)

该 downstream preflight uses the Metal device-layer implementation admission endpoint as its runtime input candidate and keeps this native resource bridge manifest as upstream docs evidence only. `CjguiInternalRendererNoNativeResourceBridgeReadiness` does not become runtime input, native handle permission, C ABI / FFI permission, platform object permission, Metal-device permission, command queue permission, GPU submission permission, render permission, renderer state write permission or public API permission.

The downstream output truth is limited to real command queue implementation intent / queue creation admission policy / queue ownership admission guard / queue teardown failure policy / no-real-command-queue-implementation readiness value facts.

Downstream real command queue implementation admission next-boundary decision is now complete:

- [2026-05-05-p1-renderer-real-command-queue-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-admission-next-boundary-decision.md)

That downstream decision confirms `CjguiInternalRendererNoRealCommandQueueImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueAdmissionDraft()` is sufficient as the current no-real-command-queue-implementation endpoint. This native resource bridge manifest remains docs evidence only; it does not become runtime input, native handle permission, C ABI / FFI permission, command queue permission, command buffer permission, GPU submission permission, render permission, renderer state write permission or public API permission.

Downstream real command queue implementation admission manifest stabilization is now complete:

- [2026-05-05-p1-renderer-real-command-queue-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-admission-manifest.md)
- [2026-05-05-p1-internal-renderer-real-command-queue-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-command-queue-implementation-admission-manifest-stabilization-closure-review.md)

That downstream manifest keeps this native resource bridge manifest as docs evidence only and seals `CjguiInternalRendererNoRealCommandQueueImplementationReadiness` as no-real-command-queue-implementation value facts. This manifest still does not become runtime input, native handle permission, C ABI / FFI permission, command queue permission, `newCommandQueue` permission, command buffer permission, GPU submission permission, render permission, renderer state write permission or public API permission.

唯一 downstream next opening：

`P1 internal Renderer real drawable implementation preflight decision`

## 下游真实 platform object 第一刀预检

Renderer real backend platform object first implementation preflight decision 已完成：

- [2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-preflight-decision.md)

该 downstream 回看本 manifest 的 native resource bridge facts 作为 planning evidence，但不把 `CjguiInternalRendererNoNativeResourceBridgeReadiness` 升格为 native handle permission、C ABI permission、FFI permission、bridge call permission、retain / release / destroy permission、platform object permission、Metal / AppKit permission、GPU submission permission、renderer state write permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer real backend platform object first implementation slice bundle`

## 下游真实 platform object 第一刀切片闭环

Renderer real backend platform object first implementation slice 已完成：

- [2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-closure-review.md)
- [runtime_renderer_backend_platform_object_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_platform_object_real.cj)

该 downstream owner 不直接消费 `CjguiInternalRendererNoNativeResourceBridgeReadiness`；它只把本 manifest 作为 upstream docs evidence，并以 platform object implementation admission endpoint 作为唯一 runtime input。

该 downstream closure 不把 native resource bridge facts 升格为 native handle permission、C ABI permission、FFI permission、bridge call permission、retain / release / destroy permission、platform object permission、Metal / AppKit permission、GPU submission permission、renderer state write permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer real backend platform object first implementation slice closure / next real backend platform object decision`

## 下游真实 platform object 第一刀后续边界决策

Renderer real backend platform object first implementation slice next-boundary decision 已完成：

- [2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-next-boundary-decision.md)

该 downstream decision 确认 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()` 足够作为当前 no-real-backend-platform-object shell endpoint。它不直接消费 `CjguiInternalRendererNoNativeResourceBridgeReadiness`，也不把 native resource bridge facts 升格为 native handle permission、C ABI permission、FFI permission、bridge call permission、retain / release / destroy permission、platform object permission、Metal / AppKit permission、GPU submission permission、renderer state write permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer real backend platform object first implementation slice manifest stabilization bundle implementation`

## 下游真实 platform object 第一刀切片 manifest 稳定化

Renderer real backend platform object first implementation slice manifest stabilization 已完成：

- [2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)
- [2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-manifest-stabilization-closure-review.md)

该 downstream manifest 不直接消费 `CjguiInternalRendererNoNativeResourceBridgeReadiness`，也不把 native resource bridge facts 升格为 native handle permission、C ABI permission、FFI permission、bridge call permission、retain / release / destroy permission、platform object permission、Metal / AppKit permission、GPU submission permission、renderer state write permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer real backend platform object branch closure / next real platform object decision`

## 下游真实 platform object 分支后续边界决策

Renderer real backend platform object branch next-boundary decision 已完成：

- [2026-05-07-p1-renderer-real-backend-platform-object-branch-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-branch-next-boundary-decision.md)

该 downstream decision 继续把本 native resource bridge manifest 作为 upstream docs evidence，不直接消费 `CjguiInternalRendererNoNativeResourceBridgeReadiness`，也不把 native resource bridge facts 升格为 native handle permission、C ABI permission、FFI permission、bridge call permission、retain / release / destroy permission、platform object permission、Metal / AppKit permission、GPU submission permission、renderer state write permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native teardown contract hardening preflight decision`

## 下游 native teardown 合约硬化预检

Renderer native teardown contract hardening preflight decision 已完成：

- [2026-05-07-p1-renderer-native-teardown-contract-hardening-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-preflight-decision.md)

该 downstream decision 判定本 manifest 中已有 native teardown contract policy 与 handle confinement facts 仍不足以直接授权 native bridge / Objective-C / Metal / AppKit implementation。它只选择下一步新增 internal-only teardown hardening value boundary facts，不把 `CjguiInternalRendererNoNativeResourceBridgeReadiness` 升格为 native handle permission、C ABI permission、FFI permission、bridge-ready permission、retain / release / destroy permission、Metal-ready permission、GPU submission permission、renderer state write permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native teardown contract hardening value boundary bundle implementation`

## 下游 native teardown 合约硬化 value boundary

Renderer native teardown contract hardening value boundary 已完成：

- [native teardown contract hardening value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-native-teardown-contract-hardening-value-boundary-closure-review.md)
- [runtime_renderer_native_teardown_contract.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_teardown_contract.cj)

该 downstream owner 不消费 `CjguiInternalRendererNoNativeResourceBridgeReadiness`，而是消费更下游 shell endpoint `CjguiInternalRendererNoRealBackendPlatformObjectReadiness`。它只表达 native teardown contract hardening intent、ownership release policy、teardown failure classification、main-thread confinement guard 与 no-native-teardown-implementation readiness facts；不把本 manifest 的 native resource bridge facts 升格为 native handle permission、C ABI / FFI permission、bridge-ready permission、retain / release / destroy permission、Metal-ready permission、GPU submission permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer native teardown contract hardening closure / next native teardown decision`

## 下游 native teardown 后续边界决策

Renderer native teardown contract hardening closure / next decision 已完成：

- [native teardown contract hardening next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-next-boundary-decision.md)

该 downstream decision 继续把本 native resource bridge manifest 作为 upstream docs evidence，不直接消费 `CjguiInternalRendererNoNativeResourceBridgeReadiness`，也不把 native resource bridge facts 升格为 native bridge permission、C ABI / FFI permission、retain / release / destroy permission、native handle permission、Objective-C / Metal / AppKit permission、GPU submission permission、renderer state write permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native teardown contract hardening manifest stabilization bundle implementation`

## 下游 native teardown manifest 稳定化

Renderer native teardown contract hardening manifest stabilization 已完成：

- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [native teardown contract hardening manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-native-teardown-contract-hardening-manifest-stabilization-closure-review.md)

该 downstream manifest 继续把本 native resource bridge manifest 作为 upstream docs evidence，不直接消费 `CjguiInternalRendererNoNativeResourceBridgeReadiness`，也不把 native resource bridge facts 升格为 native bridge permission、C ABI / FFI permission、retain / release / destroy permission、native handle permission、Objective-C / Metal / AppKit permission、GPU submission permission、renderer state write permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer real Metal device-layer first implementation preflight decision`

## 下游 native bridge 写集规划重置

下游 [native bridge write-set planning reset decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-native-bridge-write-set-planning-reset-decision.md) 已完成。该 decision 重新使用本 manifest 的 native bridge intent、handle confinement、bridge call admission guard、teardown contract policy 与 no-native-resource-bridge readiness facts 作为正式 C ABI surface contract preflight 的证据。

该 downstream decision 不把 `CjguiInternalRendererNoNativeResourceBridgeReadiness` 升格为 native bridge implementation permission、native handle permission、raw pointer permission、C ABI / FFI permission、bridge call permission、retain / release / destroy permission、Objective-C / Metal / AppKit permission、GPU submission permission、renderer state write permission、backend-ready permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native bridge C ABI surface contract preflight decision`

## 下游 C ABI surface contract 封账

下游 [native bridge C ABI surface contract manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-c-abi-surface-contract-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-c-abi-surface-contract-manifest-stabilization-closure-review.md) 已完成。该 downstream 继续把本 manifest 的 native bridge intent、handle confinement、bridge call admission guard、teardown contract policy 与 no-native-resource-bridge readiness facts 作为 planning evidence，不直接消费本 endpoint，也不把 `CjguiInternalRendererNoNativeResourceBridgeReadiness` 升格为 native bridge implementation permission、C ABI implementation permission、FFI permission、native handle permission、raw pointer permission、bridge call permission、retain / release / destroy permission、Objective-C / Metal / AppKit permission、GPU submission permission、renderer state write permission、backend-ready permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native handle token ownership planning preflight decision`

## 下游 native handle token ownership 封账

下游 [native handle token ownership manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-handle-token-ownership-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-handle-token-ownership-manifest-stabilization-closure-review.md) 已完成。该 downstream 继续把本 manifest 的 native bridge intent、handle confinement、bridge call admission guard、teardown contract policy 与 no-native-resource-bridge readiness facts 作为 planning evidence，不直接消费本 endpoint，也不把 `CjguiInternalRendererNoNativeResourceBridgeReadiness` 升格为 native handle permission、raw pointer permission、native pointer return permission、native bridge implementation permission、C ABI implementation permission、FFI permission、bridge call permission、retain / release / destroy permission、Objective-C / Metal / AppKit permission、GPU submission permission、renderer state write permission、backend-ready permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native bridge teardown implementation planning preflight decision`
