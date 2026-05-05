# P1 Renderer native resource bridge next-boundary decision

日期：2026-05-05

状态：docs-only next-boundary decision

## Scope

本轮评估 `CjguiInternalRendererNoNativeResourceBridgeReadiness` 是否已经足够作为当前 no-native-resource-bridge endpoint，并决定下一步是否先做 manifest stabilization。

本轮 docs-only：不修改 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮不创建 backend shell object、backend object、platform object、native handle、raw pointer、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer；不新增 C ABI / FFI declaration；不调用 bridge、retain / release / destroy、`commit`、`present`、`nextDrawable`、Metal / AppKit / Objective-C / FFI；不提交 GPU work，不执行 render，不写 renderer state，不扩 public API。

## Inputs Read

- [runtime_renderer_native_resource_bridge.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_resource_bridge.cj)
- [Native resource bridge value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-native-resource-bridge-value-boundary-closure-review.md)
- [Native resource bridge preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-preflight-decision.md)
- [Backend shell skeleton manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-backend-shell-skeleton-manifest.md)
- [Backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)

## Decision

`CjguiInternalRendererNoNativeResourceBridgeReadiness` / `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()` is sufficient as the current no-native-resource-bridge endpoint.

Choose A：`P1 internal Renderer native resource bridge manifest stabilization bundle implementation`。

The next round must remain docs-only. It should fix `runtime_renderer_native_resource_bridge.cj` owner / truth / canonical endpoint / stop-line and close the no-native-resource-bridge endpoint. It must not implement native bridge, native handle, C ABI, FFI declaration, platform object, Metal / AppKit bridge, GPU submission, render execution, renderer state write or public API.

唯一 next opening：

`P1 internal Renderer native resource bridge manifest stabilization bundle implementation`

## Endpoint Sufficiency

The endpoint is sufficient because it preserves the full owner-local value chain:

1. `CjguiInternalRendererNoResourceBackendShellReadiness`
2. `CjguiInternalRendererNativeResourceBridgeIntent`
3. `CjguiInternalRendererNativeHandleConfinementPolicy`
4. `CjguiInternalRendererBridgeCallAdmissionGuard`
5. `CjguiInternalRendererNativeTeardownContractPolicy`
6. `CjguiInternalRendererNoNativeResourceBridgeReadiness`

Current endpoint truth is limited to:

- native resource bridge intent value facts.
- handle confinement policy value facts.
- bridge call admission guard value facts.
- native teardown contract policy value facts.
- no-native-resource-bridge readiness value facts.

`CjguiInternalRendererNoNativeResourceBridgeReadiness` is not native bridge implementation permission, native handle permission, raw pointer permission, C ABI permission, FFI permission, platform object permission, Metal / AppKit bridge permission, GPU submission permission, render permission, renderer state write permission, diagnostics permission or public API permission.

The endpoint explicitly confirms no native resource handle, no pointer-like resource, no foreign resource token, no handle exposure, no bridge call, no foreign function declaration, no external ABI surface, no resource finalization side effect, no bridge / smoke / harness / entry change, no work submit, no render execution, no renderer state mutation and no external API surface.

## Candidate Comparison

### A. P1 internal Renderer native resource bridge manifest stabilization bundle implementation

推荐。

`CjguiInternalRendererNoNativeResourceBridgeReadiness` is already a complete no-native-resource-bridge endpoint with owner intent, handle confinement, bridge admission, teardown contract and fail-closed readiness facts. The next useful step is manifest stabilization, not another runtime wrapper.

### B. Platform object implementation preflight

暂缓。

Platform object implementation remains downstream of native resource bridge manifest stabilization. The current endpoint does not grant platform object permission.

### C. Native handle token preflight

暂缓。

Handle identity / nullability / ownership token work should wait until the native resource bridge owner is manifest-stabilized. Current handle confinement vocabulary is sufficient for the present endpoint.

### D. Native teardown contract hardening

暂缓，仅在发现不足时选择。

Current native teardown contract facts cover teardown ordering, failure rollback, no-resource-finalization and no bridge / harness mutation. No hardening is required before manifest stabilization.

### E. Metal device-layer implementation preflight

暂缓。

Device / layer implementation remains downstream of native bridge and platform object implementation preflight.

### F. Real backend shell implementation preflight

暂缓。

Real backend shell implementation still needs native bridge, platform object and implementation stop-line evidence to be stabilized first.

### G. Direct native bridge implementation

拒绝。

No native bridge implementation, bridge call or bridge entry modification is approved.

### H. Direct native handle / raw pointer implementation

拒绝。

No native handle, raw pointer, pointer-like resource or foreign resource token implementation is approved.

### I. Direct C ABI / FFI declaration

拒绝。

No public C ABI, private C ABI, FFI declaration, foreign function declaration or signature expansion is approved.

### J. Direct retain / release / destroy implementation

拒绝。

No retain, release, destroy, finalizer, resource finalization side effect or native teardown callback is approved.

### K. Direct Metal / AppKit / Objective-C implementation

拒绝。

No `MTLDevice`, `CAMetalLayer`, `MTLCommandQueue`, drawable, command buffer, Metal / AppKit / Objective-C / FFI call or bridge modification is approved.

### L. GPU submission / render execution

拒绝。

No command buffer commit, drawable present, GPU submission, render execution, render pass, encoder, pipeline state or draw call is approved.

### M. Renderer state write

拒绝。

No renderer state mutation and no `runtime_state.cj` write are approved.

### N. Public API / C ABI expansion

拒绝。

The public declaration allowlist remains unchanged and no public C ABI is opened.

### O. Receipt / record / publication

拒绝。

Do not add native bridge receipt / record / publication, native-handle permission wrapper, C-ABI permission wrapper, FFI permission wrapper, platform-object permission wrapper, Metal-device permission wrapper, backend implementation wrapper, GPU-submission wrapper, render-permission wrapper or renderer-state-write wrapper.

### P. Consolidation

仅在发现明确 duplicate / low-value / self-wrapping evidence 时选择。

No duplicate / low-value / self-wrapping evidence was found. The next useful move is manifest stabilization.

## Same-shape Boundary Brake

`CjguiInternalRendererNoNativeResourceBridgeReadiness` must not be wrapped into another tail endpoint.

This decision explicitly rejects:

- native bridge receipt / record / publication.
- native-handle permission wrapper.
- raw-pointer permission wrapper.
- C-ABI permission wrapper.
- FFI permission wrapper.
- platform-object permission wrapper.
- Metal-device permission wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- render-permission wrapper.
- renderer-state-write wrapper.
- public API wrapper.

The current endpoint only represents native resource bridge intent / handle confinement policy / bridge call admission guard / native teardown contract policy / no-native-resource-bridge readiness value facts.

It is not native bridge implementation permission, native handle permission, C ABI permission, FFI permission, platform object permission, Metal / AppKit bridge permission, GPU submission permission, render permission, renderer state write permission or public API permission.

## Stop-line

Until a later docs-only preflight explicitly opens a narrower runway:

- no `.cj` modification in this decision round.
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

## Downstream Manifest Stabilization

Renderer native resource bridge manifest stabilization 已完成：

- [2026-05-05-p1-renderer-native-resource-bridge-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [2026-05-05-p1-internal-renderer-native-resource-bridge-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-native-resource-bridge-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime/cjgui/src/runtime_renderer_native_resource_bridge.cj` owner / truth / canonical endpoint / stop-line。

Canonical endpoint 是 `CjguiInternalRendererNoNativeResourceBridgeReadiness` / `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()`；current truth 仅限 native resource bridge intent / handle confinement policy / bridge call admission guard / native teardown contract policy / no-native-resource-bridge readiness value facts。

该 endpoint 不批准 native bridge implementation、native handle、C ABI、FFI、platform object、Metal / AppKit bridge、GPU submission、render、renderer state write 或 public API。

唯一 next opening：

`P1 internal Renderer platform object implementation preflight decision`
