# P1 Renderer native resource bridge preflight decision

日期：2026-05-05

状态：docs-only preflight decision

## Scope

本轮评估在 backend shell skeleton no-resource endpoint 封账后，是否可以打开 native resource bridge runway。

本轮 docs-only：不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮不创建 backend shell object、backend object、platform object、native handle、raw pointer、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer；不新增 C ABI，不新增 FFI declaration，不调用 retain / release / destroy，不调用 `commit`、`present`、`nextDrawable`、Metal / AppKit / Objective-C / FFI；不提交 GPU work，不执行 render，不写 renderer state，不扩 public API。

## Inputs Read

- [Backend shell skeleton manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-backend-shell-skeleton-manifest.md)
- [Backend shell skeleton next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-backend-shell-skeleton-next-boundary-decision.md)
- [Backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)
- [Real backend shell implementation preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-backend-shell-implementation-preflight-decision.md)
- [Backend shell first implementation slice preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-backend-shell-first-implementation-slice-preflight-decision.md)
- [Backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [macOS bridge smoke README](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md), read-only for feasibility / teardown / smoke evidence only.
- [macOS bridge smoke auto-close verifier](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh), read-only for feasibility / teardown / smoke evidence only.

## Preflight Decision

允许打开 native resource bridge runway。

选择 A：`P1 internal Renderer native resource bridge value boundary bundle implementation`。

下一步仍只能是 internal value boundary，不是真实 native bridge / FFI / handle implementation。它不得新增 C ABI、FFI declaration、native handle、raw pointer、bridge call、retain / release / destroy call、platform object、Metal / AppKit / Objective-C object、GPU work、render execution、renderer state write 或 public API。

唯一 next opening：

`P1 internal Renderer native resource bridge value boundary bundle implementation`

## Owner And Truth Shape For The Next Boundary

Default owner candidate：

- `runtime/cjgui/src/runtime_renderer_native_resource_bridge.cj`

Runtime input candidate：

- `CjguiInternalRendererNoResourceBackendShellReadiness`
- `cjguiInternalExecuteDefaultRendererBackendShellSkeletonDraft()`

The next boundary should consume only `CjguiInternalRendererNoResourceBackendShellReadiness` as runtime input. Backend platform object, Metal device-layer, backend / Metal reference pack, risk ledger and smoke evidence remain docs evidence only.

Allowed output truth only:

- native resource bridge intent value facts.
- handle confinement policy value facts.
- bridge call admission guard value facts.
- native teardown contract policy value facts.
- no-native-resource-bridge readiness value facts.

## Split Assessment

The next step does not need to split first into separate handle-token owner, teardown owner or bridge contract owner.

Reasoning:

- Backend shell skeleton manifest now provides a closed no-resource endpoint and explicit no-bridge / no-handle / teardown confinement stop-line.
- Backend platform object owner manifest already provides native resource ownership vocabulary, lifecycle teardown policy and confinement failure facts while denying real platform object, native handle, raw pointer and FFI permission.
- GUI risk ledger identifies FFI ownership, retain / release / destroy order, handle lifetime, main-thread / AppKit boundary and bridge thickness as risks that the next value boundary can name as guards.
- Smoke evidence demonstrates feasibility and teardown logging only; it cannot become runtime truth, but it is enough to motivate value-only bridge admission and teardown contract vocabulary.

If the next implementation cannot keep handle identity, nullability, teardown ordering and bridge admission as value facts without creating handles or declarations, it must stop and fall back to B or C as docs-only hardening. That fallback is not required before opening A.

## Evidence Assessment

### Backend shell skeleton evidence

`CjguiInternalRendererNoResourceBackendShellReadiness` is the current no-resource-backend-shell endpoint. It preserves backend shell skeleton intent, lifecycle envelope, no-resource guard, failure rollback policy and teardown confinement policy.

It is not backend shell implementation permission, native handle permission, raw pointer permission, platform object permission, Metal / AppKit bridge permission, GPU submission permission, render permission, renderer state write permission, public API permission or C ABI permission.

### Backend platform object evidence

`CjguiInternalRendererNoPlatformObjectReadiness` provides native resource ownership policy, lifecycle teardown policy and confinement failure policy vocabulary. It explicitly denies platform object creation, native handle, raw pointer, real retain / release / destroy FFI calls, bridge / smoke / harness / native entry modifications, backend implementation, GPU submission, render execution and public C ABI.

It is docs evidence only for the next boundary, not a runtime input.

### Metal device-layer evidence

`CjguiInternalRendererNoMetalDeviceLayerReadiness` provides device selection, layer binding and scale / color-space policy vocabulary while denying real `MTLDevice`, `CAMetalLayer`, native handle, Objective-C / Metal / AppKit / FFI calls and bridge modification.

It is docs evidence only and does not make native resource bridge a Metal owner.

### Backend / Metal reference evidence

The reference pack proves real backend work will eventually need backend-local ownership for device, layer, command queue, drawable, command buffer, render pass, encoder, pipeline state, completion and resource retention.

It also states that core packet truth must not hold drawable, command buffer, completion callback, native handle or raw pointer. For this preflight, that evidence supports handle confinement and bridge call admission guards, not implementation.

### Risk ledger evidence

The risk ledger identifies FFI ownership, unclear release ownership, double free, dangling pointer, GPU resource lifecycle, main-thread / AppKit boundary, over-thin bridge illusion and native error boundary as high-risk areas.

For this preflight, those risks argue for a value-only native resource bridge boundary before any C ABI / FFI / handle implementation.

### Smoke evidence boundary

`labs/macos_bridge_smoke` can only remain feasibility / teardown / smoke evidence.

It can inform:

- C ABI and Objective-C bridge reachability on this machine.
- teardown log shape and auto-close lifecycle smoke strategy.
- Metal capability smoke and clear-color readback feasibility.
- user-visible screenshot feasibility and target-window verification constraints.

It cannot become:

- runtime truth.
- backend shell owner truth.
- native bridge truth.
- backend object lifecycle truth.
- public ABI truth.
- handle ownership truth.
- renderer state write truth.
- visual baseline truth.
- GPU submission or render correctness proof.

## Candidate Comparison

### A. P1 internal Renderer native resource bridge value boundary bundle implementation

谨慎推荐。

Evidence is sufficient to add internal-only value facts for native resource bridge intent, handle confinement policy, bridge call admission guard, native teardown contract policy and no-native-resource-bridge readiness.

The next implementation must remain value-only and must not create native handle, raw pointer, C ABI, FFI declaration, bridge call, retain / release / destroy call, platform object or Metal object.

### B. P1 internal Renderer native handle token preflight decision

备选，暂不选择。

Choose B only if the next implementation finds handle identity, nullability, ownership label or no-handle token vocabulary cannot be expressed safely inside the bridge value boundary.

Current evidence is enough to include handle confinement policy as value facts, so B is not needed first.

### C. P1 internal Renderer native teardown contract preflight decision

备选，暂不选择。

Choose C only if teardown / release ordering / failure rollback evidence proves too coarse for the value boundary.

Current backend shell teardown confinement, backend platform lifecycle teardown policy, risk ledger warnings and smoke teardown logs are enough to express a value-only native teardown contract policy.

### D. Platform object implementation preflight

暂缓。

Platform object implementation should wait until native resource bridge value facts are stabilized.

### E. Metal device-layer implementation preflight

暂缓。

Device / layer implementation should wait until native resource bridge and platform object implementation risks are evaluated.

### F. Real backend shell implementation preflight

暂缓。

Real backend shell implementation remains downstream of native bridge / platform object / resource lifetime evidence.

### G. Direct native bridge implementation

拒绝。

No bridge implementation, bridge call, bridge entry modification or native bridge owner is approved.

### H. Direct native handle / raw pointer implementation

拒绝。

No native handle, raw pointer, foreign resource token or pointer-like storage is approved.

### I. Direct C ABI / FFI declaration

拒绝。

No public C ABI, private C ABI, FFI declaration, foreign function declaration or signature expansion is approved.

### J. Direct retain / release / destroy implementation

拒绝。

No retain, release, destroy, teardown call, finalizer or callback is approved.

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

Do not add native bridge receipt / record / publication, native-handle permission wrapper, platform-object permission wrapper, backend implementation wrapper, GPU-submission wrapper or render-permission wrapper.

### P. Consolidation

暂缓。

No duplicate / low-value / self-wrapping evidence was found. The next useful move is a narrow value boundary, not deletion.

## Same-shape Boundary Brake

The next boundary must not wrap existing endpoints or smoke evidence into a permission-shaped tail.

Do not wrap:

- `CjguiInternalRendererNoResourceBackendShellReadiness`
- `CjguiInternalRendererNoPlatformObjectReadiness`
- `CjguiInternalRendererNoMetalDeviceLayerReadiness`
- backend / Metal reference pack
- `labs/macos_bridge_smoke` evidence

Forbidden wrapper shapes:

- native bridge receipt / record / publication.
- native-handle permission wrapper.
- raw-pointer permission wrapper.
- platform-object permission wrapper.
- Metal-device permission wrapper.
- layer-ready permission wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- render-permission wrapper.
- renderer-state-write wrapper.
- public API / C ABI wrapper.

If the next implementation proceeds, it must prove new handle confinement / bridge call admission / teardown contract / no-native-resource-bridge semantics rather than renaming no-resource-backend-shell readiness.

## Stop-line

Future native resource bridge value boundary must still keep:

- no native handle.
- no raw pointer.
- no foreign resource token.
- no C ABI.
- no FFI declaration.
- no bridge call.
- no retain / release / destroy.
- no Metal / AppKit / Objective-C call.
- no platform object.
- no backend object.
- no backend shell object.
- no `MTLDevice`.
- no `CAMetalLayer`.
- no `MTLCommandQueue`.
- no drawable.
- no command buffer.
- no render pass / encoder / pipeline state.
- no `commit`.
- no `present`.
- no `nextDrawable`.
- no GPU submission.
- no render execution.
- no renderer state write.
- no public API.
- no diagnostics / event bus / observer / telemetry.
- no bridge / smoke / harness / native entry modification.
- no `runtime_state.cj` touch.
- no `runtime/cjgui/cjpm.toml` change.

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

## Downstream Value Boundary Implementation

Renderer native resource bridge value boundary 已完成：

- [2026-05-05-p1-internal-renderer-native-resource-bridge-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-native-resource-bridge-value-boundary-closure-review.md)

Implementation outcome:

- Owner file：`runtime/cjgui/src/runtime_renderer_native_resource_bridge.cj`
- Runtime input：`CjguiInternalRendererNoResourceBackendShellReadiness`
- Canonical endpoint：`CjguiInternalRendererNoNativeResourceBridgeReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()`
- Current truth：native resource bridge intent / handle confinement policy / bridge call admission guard / native teardown contract policy / no-native-resource-bridge readiness value facts。

Same-shape Boundary Brake remained active：the implementation adds handle confinement / bridge call admission / teardown contract / no-native-resource-bridge semantics and does not wrap `CjguiInternalRendererNoResourceBackendShellReadiness`, `CjguiInternalRendererNoPlatformObjectReadiness`, `CjguiInternalRendererNoMetalDeviceLayerReadiness` or smoke evidence into native bridge receipt / record / publication, native-handle permission wrapper, platform-object permission wrapper, Metal-device permission wrapper, backend implementation wrapper, GPU-submission wrapper or render-permission wrapper.

唯一 next opening：

`P1 internal Renderer native resource bridge closure / next native resource bridge decision`

## Downstream Next-Boundary Decision

Renderer native resource bridge next-boundary decision 已完成：

- [2026-05-05-p1-renderer-native-resource-bridge-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-next-boundary-decision.md)

Decision：`CjguiInternalRendererNoNativeResourceBridgeReadiness` / `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()` 已足够作为当前 no-native-resource-bridge endpoint。

Current endpoint truth 仅限 native resource bridge intent / handle confinement policy / bridge call admission guard / native teardown contract policy / no-native-resource-bridge readiness value facts；它不是 native bridge implementation permission、native handle permission、C ABI permission、FFI permission、platform object permission、Metal / AppKit bridge permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

唯一 next opening：

`P1 internal Renderer native resource bridge manifest stabilization bundle implementation`

## Downstream Manifest Stabilization

Renderer native resource bridge manifest stabilization 已完成：

- [2026-05-05-p1-renderer-native-resource-bridge-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [2026-05-05-p1-internal-renderer-native-resource-bridge-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-native-resource-bridge-manifest-stabilization-closure-review.md)

Manifest outcome:

- Owner file：`runtime/cjgui/src/runtime_renderer_native_resource_bridge.cj`
- Runtime input：`CjguiInternalRendererNoResourceBackendShellReadiness`
- Canonical endpoint：`CjguiInternalRendererNoNativeResourceBridgeReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()`
- Current truth：native resource bridge intent / handle confinement policy / bridge call admission guard / native teardown contract policy / no-native-resource-bridge readiness value facts。

Same-shape Boundary Brake remained active：the manifest closes the no-native-resource-bridge endpoint and rejects native bridge receipt / record / publication, native-handle permission wrapper, C-ABI permission wrapper, FFI permission wrapper, platform-object permission wrapper, Metal-device permission wrapper, backend implementation wrapper, GPU-submission wrapper, render-permission wrapper and renderer-state-write wrapper.

唯一 next opening：

`P1 internal Renderer platform object implementation preflight decision`
