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

## Decision

`runtime/cjgui/src/runtime_renderer_native_resource_bridge.cj` is now the fixed native resource bridge owner for the current no-native-resource-bridge endpoint.

`CjguiInternalRendererNoNativeResourceBridgeReadiness` / `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()` is the canonical tail for native resource bridge value facts. It is not permission to implement native bridge, hold native handle, add C ABI / FFI, create platform object, call Metal / AppKit bridge, submit GPU work, render, write renderer state or expose public API.

唯一 next opening：

`P1 internal Renderer platform object implementation preflight decision`

Downstream implementation admission value boundary is now complete:

- [2026-05-05-p1-internal-renderer-platform-object-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-platform-object-implementation-admission-value-boundary-closure-review.md)

The new downstream canonical endpoint is `CjguiInternalRendererNoPlatformObjectImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()`.

## Downstream Platform Object Implementation Preflight

Renderer platform object implementation preflight 已完成：

- [2026-05-05-p1-renderer-platform-object-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-preflight-decision.md)

该 preflight 使用本 manifest 的 `CjguiInternalRendererNoNativeResourceBridgeReadiness` / `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()` 作为下一步 runtime input candidate，并选择 `P1 internal Renderer platform object implementation admission value boundary bundle implementation` 作为唯一 next opening。

Output truth 仅限 platform object implementation intent / native handle admission policy / platform object lifecycle admission guard / teardown failure policy / no-platform-object-implementation readiness value facts。

该 downstream preflight 不批准 platform object、native handle、raw pointer、C ABI、FFI declaration、bridge call、retain / release / destroy、Metal / AppKit / Objective-C、GPU submission、render execution、renderer state write 或 public API。

唯一 next opening：

`P1 internal Renderer platform object implementation admission value boundary bundle implementation`
