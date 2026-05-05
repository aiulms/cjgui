# P1 Renderer platform object implementation preflight decision

日期：2026-05-05

状态：docs-only preflight decision

## Scope

本轮评估在 native resource bridge manifest 封账后，是否可以打开 platform object implementation runway。

本轮 docs-only：不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮不创建 backend shell object、backend object、platform object、native handle 或 raw pointer；不新增 C ABI，不新增 FFI declaration，不调用 bridge，不调用 retain / release / destroy；不创建 `MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer；不调用 `commit`、`present`、`nextDrawable`、Metal / AppKit / Objective-C / FFI；不提交 GPU work，不执行 render，不写 renderer state，不扩 public API。

## Inputs Read

- [Native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [Backend shell skeleton manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-backend-shell-skeleton-manifest.md)
- [Backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)
- [Real backend shell implementation preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-backend-shell-implementation-preflight-decision.md)
- [Backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [macOS bridge smoke README](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md), read-only for feasibility / teardown / smoke evidence only.
- [macOS bridge smoke auto-close verifier](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh), read-only for feasibility / teardown / smoke evidence only.

## Preflight Decision

允许打开 platform object implementation runway，但下一步仍不能直接创建真实 platform object。

选择 A：`P1 internal Renderer platform object implementation admission value boundary bundle implementation`。

下一步必须仍是 internal value boundary / implementation admission facts。它不得创建 platform object、backend object、backend shell object、native handle、raw pointer、C ABI、FFI declaration、bridge call、retain / release / destroy call、Metal / AppKit / Objective-C object、GPU work、render execution、renderer state write 或 public API。

唯一 next opening：

`P1 internal Renderer platform object implementation admission value boundary bundle implementation`

## Owner And Truth Shape For The Next Boundary

Default owner candidate：

- `runtime/cjgui/src/runtime_renderer_platform_object_implementation_admission.cj`

Downstream implementation note：本轮后续 implementation 使用显式允许的 owner file [runtime_renderer_platform_object_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_platform_object_admission.cj)。该文件名差异不改变本 preflight 的 owner / truth shape。

Runtime input candidate：

- `CjguiInternalRendererNoNativeResourceBridgeReadiness`
- `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()`

The next boundary should consume only `CjguiInternalRendererNoNativeResourceBridgeReadiness` as runtime input. Backend shell skeleton, backend platform object owner, Metal device-layer, backend / Metal reference pack, risk ledger and smoke evidence remain docs evidence only.

Allowed output truth only:

- platform object implementation intent value facts.
- native handle admission policy value facts.
- platform object lifecycle admission guard value facts.
- teardown failure policy value facts.
- no-platform-object-implementation readiness value facts.

Suggested canonical endpoint for the next value boundary:

- `CjguiInternalRendererNoPlatformObjectImplementationReadiness`

Suggested default draft:

- `cjguiInternalExecuteDefaultRendererPlatformObjectImplementationAdmissionDraft()`
- Downstream implementation uses the explicit default draft `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()` in [runtime_renderer_platform_object_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_platform_object_admission.cj).

## Split Assessment

The next step does not need to split first into separate native handle token preflight, native teardown contract preflight, platform object admission gate preflight or Metal device-layer implementation preflight.

Reasoning:

- Native resource bridge manifest already closes `CjguiInternalRendererNoNativeResourceBridgeReadiness` with handle confinement policy, bridge call admission guard and native teardown contract policy.
- Backend platform object owner manifest already provides native resource ownership policy, lifecycle teardown policy, confinement failure policy and no-platform-object stop-line vocabulary.
- Backend shell skeleton manifest keeps no-resource backend shell lifecycle, rollback and teardown confinement separate from platform object implementation.
- Backend / Metal reference pack proves platform and Metal objects must remain backend-local and never enter core packet truth.
- GUI risk ledger explicitly identifies FFI ownership, retain / release / destroy ordering, raw pointer exposure, main-thread / AppKit boundary and bridge optimism as risks that can be named in admission facts without implementing them.
- Smoke evidence proves only feasibility / teardown / lifecycle logging shape, not runtime truth. It can support admission policy vocabulary but cannot replace native handle token or teardown contract truth.

If the next value-boundary implementation cannot express native handle identity, nullability, ownership labels, teardown ordering, failure rollback and bridge admission as value facts without creating handles or declarations, it must stop and fall back to B or C. That fallback is not required before opening A.

## Evidence Assessment

### Native resource bridge evidence

`CjguiInternalRendererNoNativeResourceBridgeReadiness` is the current no-native-resource-bridge endpoint. It preserves native resource bridge intent, handle confinement policy, bridge call admission guard, native teardown contract policy and no-native-resource-bridge readiness facts.

It is not native bridge implementation permission, native handle permission, C ABI permission, FFI permission, platform object permission, Metal / AppKit bridge permission, GPU submission permission, render permission, renderer state write permission or public API permission.

For this preflight, it is the right runtime input candidate because it already names the no-bridge / no-handle / no-C-ABI / no-FFI stop-line that platform object implementation admission must preserve.

### Backend platform object owner evidence

`CjguiInternalRendererNoPlatformObjectReadiness` provides native resource ownership policy, lifecycle teardown policy and confinement failure policy vocabulary.

It is docs evidence only. It does not grant platform object creation, native handle, raw pointer, real retain / release / destroy FFI calls, bridge / smoke / harness / native entry modifications, backend implementation, GPU submission, render execution or public C ABI.

### Backend shell skeleton evidence

`CjguiInternalRendererNoResourceBackendShellReadiness` confirms the backend shell skeleton remains no-resource. It can inform lifecycle envelope, rollback and teardown confinement but does not become runtime input for platform object implementation admission.

### Metal device-layer evidence

`CjguiInternalRendererNoMetalDeviceLayerReadiness` provides future device / layer vocabulary while denying `MTLDevice`, `CAMetalLayer`, native handle, Objective-C / Metal / AppKit / FFI call, bridge modification, GPU submission and renderer state write.

It is docs evidence only and should remain downstream of platform object implementation admission.

### Backend / Metal reference evidence

The reference pack proves future backend owners must keep `MTLDevice`, `CAMetalLayer`, command queue, drawable, command buffer, completion callback, resource retention, native handle and raw pointer out of core packet truth.

For this preflight, that evidence supports platform object lifecycle admission and no-resource stop-lines. It does not approve real platform object creation, real Metal device / layer creation, command queue creation, drawable acquisition, command buffer commit, GPU submission or renderer state write.

### Risk ledger evidence

The risk ledger identifies FFI ownership, retain / release / destroy ordering, dangling pointer, double free, main-thread / AppKit boundary, GPU lifecycle and bridge optimism as high-risk areas.

For this preflight, those risks argue for a value-only platform object implementation admission boundary before any native handle, platform object, bridge call, C ABI or FFI declaration is allowed.

### Smoke evidence boundary

`labs/macos_bridge_smoke` can only remain feasibility / teardown / smoke evidence.

It can inform:

- C ABI and Objective-C bridge reachability on this machine.
- AppKit / Metal smoke feasibility.
- lifecycle log shape such as bridge init, window created, setup complete, close requested, destroy complete and event loop exited.
- auto-close verifier expectations as a future smoke strategy reference.
- dehydrated frame metadata and readback feasibility diagnostics.

It cannot become:

- runtime truth.
- platform object owner truth.
- native handle truth.
- C ABI / FFI declaration truth.
- backend shell truth.
- Metal device / layer truth.
- renderer state write truth.
- visual baseline truth.
- GPU submission or render correctness proof.

## Candidate Comparison

### A. P1 internal Renderer platform object implementation admission value boundary bundle implementation

谨慎推荐。

Evidence is sufficient to add internal-only value facts for platform object implementation intent, native handle admission policy, platform object lifecycle admission guard, teardown failure policy and no-platform-object-implementation readiness.

The next implementation must remain value-only and must not create platform object, native handle, raw pointer, C ABI, FFI declaration, bridge call, retain / release / destroy call, Metal / AppKit object, GPU work, render execution, renderer state write or public API.

### B. P1 internal Renderer native handle token preflight decision

备选，暂不选择。

Choose B only if the next value-boundary implementation finds handle identity, nullability, generation, ownership label or no-handle token vocabulary cannot be expressed safely inside the admission value boundary.

Current native resource bridge and backend platform object owner evidence is enough to include native handle admission policy as value facts, so B is not needed first.

### C. P1 internal Renderer native teardown contract preflight decision

备选，暂不选择。

Choose C only if teardown / release ordering / failure rollback evidence proves too coarse for the admission value boundary.

Current native teardown contract policy, backend platform lifecycle teardown policy, backend shell teardown confinement, risk ledger and smoke teardown logs are enough to express value-only teardown failure policy.

### D. Metal device-layer implementation preflight

暂缓。

Device / layer implementation should wait until platform object implementation admission facts are stabilized. Current preflight does not grant `MTLDevice` or `CAMetalLayer` permission.

### E. Real backend shell implementation preflight

暂缓。

Real backend shell implementation remains downstream of platform object admission, native bridge constraints and resource lifetime stop-lines.

### F. Real command queue implementation preflight

暂缓。

Command queue implementation is still too close to Metal resource creation and must wait until platform object and device / layer implementation risks are evaluated.

### G. Direct platform object implementation

拒绝。

No platform object creation, ownership, retain / release / destroy or bridge call is approved.

### H. Direct native handle / raw pointer implementation

拒绝。

No native handle, raw pointer, pointer-like resource or foreign resource token implementation is approved.

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

Do not add platform object implementation receipt / record / publication, platform-object permission wrapper, native-handle permission wrapper, C-ABI / FFI permission wrapper, Metal-device permission wrapper, backend implementation wrapper, GPU-submission wrapper or render-permission wrapper.

### P. Consolidation

仅在发现明确 duplicate / low-value / self-wrapping evidence 时选择。

No duplicate / low-value / self-wrapping evidence was found. The next useful move is admission value boundary.

## Same-shape Boundary Brake

This preflight must not wrap any existing endpoint into a new permission-shaped tail.

Forbidden wrappers:

- platform object implementation receipt / record / publication.
- platform-object permission wrapper.
- native-handle permission wrapper.
- C-ABI permission wrapper.
- FFI permission wrapper.
- Metal-device permission wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- render-permission wrapper.
- renderer-state-write wrapper.
- public API wrapper.

Do not treat these as platform object implementation permission:

- `CjguiInternalRendererNoNativeResourceBridgeReadiness`
- `CjguiInternalRendererNoPlatformObjectReadiness`
- `CjguiInternalRendererNoResourceBackendShellReadiness`
- smoke evidence
- backend platform object owner manifest
- native resource bridge manifest
- backend / Metal reference pack

If the next value boundary proceeds, it must prove new implementation admission / native handle admission / lifecycle admission / teardown failure / no-platform-object-implementation semantics rather than wrapping the no-native-resource-bridge or no-platform-object tail.

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

## Downstream Platform Object Implementation Admission Value Boundary

Renderer platform object implementation admission value boundary 已完成：

- [2026-05-05-p1-internal-renderer-platform-object-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-platform-object-implementation-admission-value-boundary-closure-review.md)

该 implementation 新增 [runtime_renderer_platform_object_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_platform_object_admission.cj)，只消费 `CjguiInternalRendererNoNativeResourceBridgeReadiness` / `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()`，canonical endpoint 是 `CjguiInternalRendererNoPlatformObjectImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()`。

Current truth 仅限 platform object implementation intent / native handle admission policy / platform object lifecycle admission guard / teardown failure policy / no-platform-object-implementation readiness value facts。它不创建 platform object、backend object、backend shell object、native handle、raw pointer，不新增 C ABI / FFI declaration，不调用 bridge / retain / release / destroy / Metal / AppKit / Objective-C / FFI，不创建 `MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer，不 GPU submission，不 render execution，不写 renderer state，不扩 public API。

Same-shape Boundary Brake 继续刹住 no-native-resource-bridge / no-platform-object endpoint：不得把它包成 platform-object permission wrapper、native-handle permission wrapper、C-ABI / FFI permission wrapper、Metal-device permission wrapper、backend implementation wrapper、GPU-submission wrapper、render-permission wrapper、receipt / record / publication。

唯一 downstream next opening：

`P1 internal Renderer platform object implementation admission closure / next platform object implementation decision`

## Downstream Platform Object Implementation Admission Next-boundary Decision

Renderer platform object implementation admission next-boundary decision 已完成：

- [2026-05-05-p1-renderer-platform-object-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoPlatformObjectImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()` 已足够作为当前 no-platform-object-implementation endpoint，并选择 `P1 internal Renderer platform object implementation admission manifest stabilization bundle implementation` 作为唯一 next opening。

Same-shape Boundary Brake：`NoPlatformObjectImplementationReadiness` 不再继续包装成 tail wrapper；拒绝 platform-object permission wrapper、native-handle permission wrapper、C-ABI / FFI permission wrapper、Metal-device permission wrapper、backend implementation wrapper、GPU-submission wrapper、render-permission wrapper、renderer-state-write wrapper、receipt / record / publication。

唯一 downstream next opening：

`P1 internal Renderer platform object implementation admission manifest stabilization bundle implementation`

## Downstream Platform Object Implementation Admission Manifest Stabilization

Renderer platform object implementation admission manifest stabilization 已完成：

- [2026-05-05-p1-renderer-platform-object-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-manifest.md)
- [2026-05-05-p1-internal-renderer-platform-object-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-platform-object-implementation-admission-manifest-stabilization-closure-review.md)

该 manifest 固定 downstream owner file [runtime_renderer_platform_object_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_platform_object_admission.cj)，canonical endpoint 是 `CjguiInternalRendererNoPlatformObjectImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()`。

Current truth 仅限 platform object implementation intent / native handle admission policy / platform object lifecycle admission guard / teardown failure policy / no-platform-object-implementation readiness value facts。`NativeHandleAdmissionPolicy` 不创建、保存或暴露 native handle / raw pointer；`PlatformObjectLifecycleAdmissionGuard` 不创建 platform object、不调用 bridge；`PlatformObjectTeardownFailurePolicy` 不执行 retain / release / destroy；`NoPlatformObjectImplementationReadiness` 不是 platform object implementation、native handle、C ABI、FFI、Metal / AppKit bridge、GPU submission、render、renderer state write 或 public API permission。

Same-shape Boundary Brake 继续刹住 no-native-resource-bridge / no-platform-object endpoints：不得把它们包成 platform-object permission wrapper、native-handle permission wrapper、C-ABI / FFI permission wrapper、Metal-device permission wrapper、backend implementation wrapper、GPU-submission wrapper、render-permission wrapper、renderer-state-write wrapper、receipt / record / publication。

唯一 downstream next opening：

`P1 internal Renderer Metal device-layer implementation preflight decision`
