# P1 Renderer backend shell skeleton manifest

日期：2026-05-05

状态：docs-only manifest stabilization

## Scope

本 manifest 固定 `runtime_renderer_backend_shell_skeleton.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-resource-backend-shell endpoint。

本轮 docs-only：不修改 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮不创建 backend shell object、backend object、platform object、native handle、raw pointer、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer；不调用 `commit`、`present`、`nextDrawable`、Metal / AppKit / Objective-C / FFI；不提交 GPU work，不执行 render，不写 renderer state，不扩 public API / C ABI。

## Canonical Owner

Owner file：

- [runtime_renderer_backend_shell_skeleton.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_shell_skeleton.cj)

Runtime input：

- `CjguiInternalRendererNoGpuSubmissionReadiness`
- `cjguiInternalExecuteDefaultRendererCommandSubmissionDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoResourceBackendShellReadiness`
- `cjguiInternalExecuteDefaultRendererBackendShellSkeletonDraft()`

Default draft：

- `cjguiInternalExecuteDefaultRendererBackendShellSkeletonDraft()` first obtains `CjguiInternalRendererNoGpuSubmissionReadiness` from `cjguiInternalExecuteDefaultRendererCommandSubmissionDraft()`.
- It builds backend shell skeleton intent, lifecycle envelope, no-resource guard, failure rollback policy, teardown confinement policy and no-resource-backend-shell readiness in owner-local value facts.
- It does not create a backend shell object, backend object, platform object, native handle, raw pointer, `MTLDevice`, `CAMetalLayer`, `MTLCommandQueue`, drawable, command buffer, render pass, encoder or pipeline state.
- It does not call `commit`, `present`, `nextDrawable`, Metal / AppKit / Objective-C / FFI, bridge code, retain, release or destroy.
- It does not submit GPU work, execute render, write renderer state, modify bridge / smoke / harness / native entry, or expand public API / C ABI.

## Current Truth

The current truth is exactly:

- backend shell skeleton intent value facts.
- backend shell lifecycle envelope value facts.
- backend shell no-resource guard value facts.
- backend shell failure rollback policy value facts.
- backend shell teardown confinement policy value facts.
- no-resource-backend-shell readiness value facts.

The canonical value chain is:

1. `CjguiInternalRendererNoGpuSubmissionReadiness`
2. `CjguiInternalRendererBackendShellSkeletonIntent`
3. `CjguiInternalRendererBackendShellLifecycleEnvelope`
4. `CjguiInternalRendererBackendShellNoResourceGuard`
5. `CjguiInternalRendererBackendShellFailureRollbackPolicy`
6. `CjguiInternalRendererBackendShellTeardownConfinementPolicy`
7. `CjguiInternalRendererNoResourceBackendShellReadiness`

## Value Semantics

`CjguiInternalRendererBackendShellSkeletonIntent` only records future backend shell skeleton intent facts. It is not backend shell implementation permission, backend-ready permission, native handle permission, platform object permission or GPU submission permission.

`CjguiInternalRendererBackendShellLifecycleEnvelope` only records future create / active / degraded / no-object / no-draw fallback phase facts. It does not create a backend shell object or backend object and does not manage a real backend lifecycle.

`CjguiInternalRendererBackendShellNoResourceGuard` only records no-resource guard facts. It does not hold native handle, raw pointer, platform object, backend object, backend shell instance, foreign resource token or bridge object.

`CjguiInternalRendererBackendShellFailureRollbackPolicy` only records dehydrated failure reason, no-draw rollback and degraded fallback value facts. It does not execute real rollback callback, observe completion, register callback, emit telemetry or publish diagnostics.

`CjguiInternalRendererBackendShellTeardownConfinementPolicy` only records teardown ordering, idempotent teardown and confinement facts. It does not call bridge code, does not execute retain / release / destroy, does not release resources and does not mutate renderer state.

`CjguiInternalRendererNoResourceBackendShellReadiness` seals current no-resource-backend-shell readiness facts. It is not backend shell implementation permission, native handle permission, platform object permission, Metal / AppKit bridge permission, GPU submission permission, render permission, renderer state write permission, diagnostics permission, public API permission or C ABI permission.

## Relationship Facts

Backend shell skeleton facts relate to upstream command submission facts only as dehydrated value facts:

- `CjguiInternalRendererNoGpuSubmissionReadiness` remains the only runtime input.
- Command submission manifest facts remain upstream evidence only; they do not grant command buffer creation, `commit`, `present`, drawable acquisition, GPU submission, render execution, backend implementation, renderer state write, public API or C ABI permission.
- No-draw backend shell, backend platform object, Metal device-layer, real command queue and real drawable manifests remain docs evidence only; they are not runtime inputs for this owner.
- `labs/macos_bridge_smoke` remains feasibility / teardown / smoke evidence only and is not runtime truth.
- Future native resource bridge, platform object implementation, Metal device-layer implementation, real backend shell implementation, GPU submission or renderer state write requires separate docs-only preflight before any implementation can be considered.

## Explicit Non-Truth

The no-resource-backend-shell endpoint is not:

- backend shell object permission.
- backend shell implementation permission.
- backend object permission.
- backend-ready permission.
- native handle permission.
- raw pointer permission.
- foreign resource token permission.
- platform object permission.
- Metal / AppKit bridge permission.
- `MTLDevice` permission.
- `CAMetalLayer` permission.
- `MTLCommandQueue` permission.
- drawable permission.
- command buffer permission.
- render pass / encoder / pipeline state permission.
- `commit` / `present` / `nextDrawable` permission.
- GPU submission permission.
- render execution permission.
- renderer state write permission.
- completion callback permission.
- diagnostics / event bus / observer / telemetry permission.
- public API / public C ABI permission.

Current truth has no backend shell instance, no backend object, no platform object, no native handle, no raw pointer, no bridge call, no resource release side effect, no work submit, no render execution, no renderer state mutation and no external API surface.

## Evidence Chain

- [Backend shell skeleton next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-backend-shell-skeleton-next-boundary-decision.md) confirmed `CjguiInternalRendererNoResourceBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererBackendShellSkeletonDraft()` is sufficient as the current no-resource-backend-shell endpoint.
- [Backend shell skeleton no-resource value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-backend-shell-skeleton-no-resource-value-boundary-closure-review.md) added the internal-only owner and verified the no-resource / no-bridge / no-submit / no-render / no-state-write stop-line.
- [Backend shell first implementation slice preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-backend-shell-first-implementation-slice-preflight-decision.md) chose backend shell skeleton / no-resource as the first implementation slice before native bridge or platform resource reopening.
- [Command submission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md) fixed the upstream no-gpu-submission endpoint and denied command buffer commit, drawable present, GPU submission and render permission.
- [No-draw backend shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md) remains backend shell lifecycle evidence only and does not become runtime input or backend shell object permission.

## Same-shape Boundary Brake

This round chooses manifest stabilization and closes the current no-resource-backend-shell endpoint.

It explicitly rejects:

- backend-shell-ready permission wrapper.
- native-handle wrapper.
- platform-object wrapper.
- Metal-device wrapper.
- GPU-submission wrapper.
- render-permission wrapper.
- renderer-state-write wrapper.
- receipt / record / publication.

`CjguiInternalRendererNoResourceBackendShellReadiness` must not be wrapped into another tail endpoint unless a future docs-only preflight proves new owner / lifecycle / teardown / failure / verification semantics that are not already captured here.

Future work approaching native resource bridge, platform object implementation, Metal device-layer implementation, real backend shell implementation, GPU submission, render execution or renderer state write must first pass docs-only preflight.

## Stop-line

Until a later docs-only preflight explicitly opens a narrower runway:

- no `.cj` modification for this manifest.
- no backend shell object.
- no backend object.
- no platform object.
- no native handle.
- no raw pointer.
- no foreign resource token.
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

### A. P1 internal Renderer native resource bridge preflight decision

推荐为下一阶段 opening。

Reasoning：the no-resource backend shell skeleton endpoint is now manifest-stabilized. The next docs-only question can evaluate whether a native resource bridge runway has enough owner / handle confinement / teardown / failure / smoke strategy evidence without creating a native handle, raw pointer, platform object, Metal object, bridge call or public C ABI.

### B. Platform object implementation preflight

暂缓。

Platform object implementation should wait until native resource bridge ownership and handle confinement have been evaluated in docs-only form.

### C. Metal device-layer implementation preflight

暂缓。

Device / layer implementation remains downstream of native resource bridge and platform object implementation preflight.

### D. Render completion / frame completion tracking preflight

暂缓。

Completion tracking remains close to callbacks, observers, telemetry and renderer state visibility.

### E. Backend shell lifecycle hardening

暂缓，仅在发现不足时选择。

Current lifecycle envelope / rollback / teardown confinement expression is enough to close the endpoint.

### F. Direct backend shell implementation

拒绝。

### G. Direct native handle / raw pointer implementation

拒绝。

### H. Direct Metal / AppKit / Objective-C / FFI implementation

拒绝。

### I. GPU submission / render execution

拒绝。

### J. Renderer state write

拒绝。

### K. Public API / C ABI expansion

拒绝。

### L. Receipt / record / publication

拒绝。

### M. Consolidation

仅在发现明确 duplicate / low-value / self-wrapping evidence 时选择。

## Decision

`runtime/cjgui/src/runtime_renderer_backend_shell_skeleton.cj` is now the fixed backend shell skeleton owner for the current no-resource-backend-shell endpoint.

`CjguiInternalRendererNoResourceBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererBackendShellSkeletonDraft()` is the canonical tail for backend shell skeleton value facts. It is not permission to implement backend shell, hold native handle, create platform object, call Metal / AppKit bridge, submit GPU work, render, write renderer state or expose public API.

唯一 next opening：

`P1 internal Renderer native resource bridge preflight decision`

## Downstream Native Resource Bridge Preflight

Renderer native resource bridge preflight 已完成：

- [2026-05-05-p1-renderer-native-resource-bridge-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-preflight-decision.md)

该 preflight 允许打开 native resource bridge runway，但下一步仍只能是 internal value boundary，不是真实 native bridge / FFI / handle implementation。Runtime input candidate 只消费本 manifest 的 `CjguiInternalRendererNoResourceBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererBackendShellSkeletonDraft()`。

Output truth 仅限 native resource bridge intent / handle confinement policy / bridge call admission guard / native teardown contract policy / no-native-resource-bridge readiness value facts。

唯一 next opening：

`P1 internal Renderer native resource bridge value boundary bundle implementation`

## Downstream Native Resource Bridge Value Boundary

Renderer native resource bridge value boundary 已完成：

- [2026-05-05-p1-internal-renderer-native-resource-bridge-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-native-resource-bridge-value-boundary-closure-review.md)

该 implementation 新增 `runtime/cjgui/src/runtime_renderer_native_resource_bridge.cj`，只消费本 manifest 的 `CjguiInternalRendererNoResourceBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererBackendShellSkeletonDraft()`。

Canonical endpoint 是 `CjguiInternalRendererNoNativeResourceBridgeReadiness` / `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()`；current truth 仅限 native resource bridge intent / handle confinement policy / bridge call admission guard / native teardown contract policy / no-native-resource-bridge readiness value facts。

该 downstream owner 不创建 backend shell object、backend object、platform object、native handle、raw pointer，不新增 C ABI / FFI declaration，不调用 bridge / retain / release / destroy / Metal / AppKit / Objective-C / FFI，不提交 GPU work，不执行 render，不写 renderer state，不扩 public API。

唯一 next opening：

`P1 internal Renderer native resource bridge closure / next native resource bridge decision`

## Downstream Native Resource Bridge Next-Boundary Decision

Renderer native resource bridge next-boundary decision 已完成：

- [2026-05-05-p1-renderer-native-resource-bridge-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-next-boundary-decision.md)

该 decision 确认 downstream `CjguiInternalRendererNoNativeResourceBridgeReadiness` / `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()` 已足够作为当前 no-native-resource-bridge endpoint，并选择下一步先做 native resource bridge manifest stabilization。

该 downstream endpoint 只代表 native resource bridge intent / handle confinement policy / bridge call admission guard / native teardown contract policy / no-native-resource-bridge readiness value facts；不批准 native bridge implementation、native handle、C ABI、FFI、platform object、Metal / AppKit bridge、GPU submission、render、renderer state write 或 public API。

唯一 next opening：

`P1 internal Renderer native resource bridge manifest stabilization bundle implementation`

## Downstream Native Resource Bridge Manifest Stabilization

Renderer native resource bridge manifest stabilization 已完成：

- [2026-05-05-p1-renderer-native-resource-bridge-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [2026-05-05-p1-internal-renderer-native-resource-bridge-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-native-resource-bridge-manifest-stabilization-closure-review.md)

该 downstream manifest 固定 `runtime/cjgui/src/runtime_renderer_native_resource_bridge.cj` owner / truth / canonical endpoint / stop-line，并继续只消费本 manifest 的 `CjguiInternalRendererNoResourceBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererBackendShellSkeletonDraft()`。

Canonical endpoint 是 `CjguiInternalRendererNoNativeResourceBridgeReadiness` / `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()`；current truth 仅限 native resource bridge intent / handle confinement policy / bridge call admission guard / native teardown contract policy / no-native-resource-bridge readiness value facts。

该 downstream endpoint 不批准 native bridge implementation、native handle、C ABI、FFI、platform object、Metal / AppKit bridge、GPU submission、render、renderer state write 或 public API。

唯一 next opening：

`P1 internal Renderer platform object implementation preflight decision`
