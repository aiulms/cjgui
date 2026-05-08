# P1 Renderer backend platform object owner manifest

日期：2026-05-04

状态：manifest stabilization

## Purpose

本 manifest 固定 `runtime_renderer_backend_platform_object.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-platform-object endpoint。

它不是 platform object implementation manifest，不是 native handle / raw pointer plan，不是 Metal / AppKit implementation plan，不是 backend implementation plan，也不是 command buffer commit / GPU submission / render execution / renderer state write plan。它只记录 backend platform object owner intent、native resource ownership policy、lifecycle teardown policy、confinement failure policy 与 no-platform-object readiness 的 internal value facts。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_platform_object.cj`

Canonical upstream endpoint：

- `CjguiInternalRendererNoBackendReadyReadiness`
- `cjguiInternalExecuteDefaultRendererBackendReadinessDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoPlatformObjectReadiness`
- `cjguiInternalExecuteDefaultRendererBackendPlatformObjectOwnerDraft()`

Current truth：

- backend platform object owner intent value facts。
- native resource ownership policy value facts。
- lifecycle teardown policy value facts。
- confinement failure policy value facts。
- no-platform-object readiness value facts。

## Current Pipeline

当前 backend platform object owner value pipeline：

1. `CjguiInternalRendererNoBackendReadyReadiness`
2. `CjguiInternalRendererBackendPlatformObjectOwnerIntent`
3. `CjguiInternalRendererNativeResourceOwnershipPolicy`
4. `CjguiInternalRendererLifecycleTeardownPolicy`
5. `CjguiInternalRendererConfinementFailurePolicy`
6. `CjguiInternalRendererNoPlatformObjectReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererBackendPlatformObjectOwnerDraft()`
- 只调用 `cjguiInternalExecuteDefaultRendererBackendReadinessDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不接 backend / Metal / AppKit implementation。
- 不创建 backend object。
- 不创建 platform object。
- 不创建 native handle。
- 不创建 raw pointer。
- 不创建或引用 `MTLDevice` / `CAMetalLayer`。
- 不创建 command queue / drawable / command buffer / render pass / encoder / pipeline state。
- 不定义真实 retain / release / destroy FFI call。
- 不修改 bridge / smoke / harness / native entry。
- 不提交 command buffer。
- 不提交 GPU work。
- 不执行 render。
- 不写 renderer state。
- 不写或触碰 `runtime_state.cj`。
- 不注册 callback / observer / event bus / telemetry。
- 不开放 public diagnostics / public API / C ABI。
- 不新增 module-level `var`。
- 不新增 public declaration。

## Value Semantics

`CjguiInternalRendererBackendPlatformObjectOwnerIntent` 只表达 future backend platform object owner intent。它不是 platform object creation，不是 backend implementation permission，不是 Metal device readiness wrapper，也不是 backend-ready permission wrapper。

`CjguiInternalRendererNativeResourceOwnershipPolicy` 只表达 future owner-local native resource vocabulary、no-handle surface facts 与 resource confinement facts。它不创建 native handle，不创建 raw pointer，不创建 platform object，不创建 resource token，不暴露 native resource surface。

`CjguiInternalRendererLifecycleTeardownPolicy` 只表达 future acquire / retain / release / destroy ordering facts、failure rollback teardown facts 与 no-draw teardown fallback facts。它不执行 retain / release / destroy FFI 调用，不定义真实 destroy call surface，不管理真实 platform resource lifetime。

`CjguiInternalRendererConfinementFailurePolicy` 只表达 future confinement / degraded / no-draw failure facts。它不隔离真实 platform resource failure，不观察真实 native failure，不注册 callback，不把 platform object 交给 core packet，也不把 failure fact 升格为 backend implementation permission。

`CjguiInternalRendererNoPlatformObjectReadiness` 是当前 no-platform-object endpoint。Readiness 只表示该 internal value boundary 可以继续评估，不代表 platform object permission、native handle permission、raw pointer permission、Metal device permission、backend implementation permission、render permission、GPU submission permission、command buffer commit permission、renderer state write permission、public diagnostics permission、public API permission 或 C ABI permission。

## Explicit Non-Truth

`CjguiInternalRendererNoPlatformObjectReadiness` 明确不是：

- platform object permission。
- backend object permission。
- native handle permission。
- raw pointer permission。
- native resource token。
- real retain / release / destroy FFI call permission。
- bridge / smoke / harness / native entry modification permission。
- Metal device permission。
- `MTLDevice` ownership。
- `CAMetalLayer` ownership。
- command queue ownership。
- drawable ownership。
- command buffer ownership。
- command buffer commit permission。
- GPU submission permission。
- render pass ownership。
- encoder ownership。
- pipeline state ownership。
- render execution permission。
- render permission。
- renderer state write permission。
- backend implementation permission。
- backend-ready permission。
- diagnostics publication。
- public diagnostics permission。
- public API permission。
- public C ABI。
- platform object receipt / record / publication。
- native-handle readiness wrapper。
- backend implementation wrapper。
- Metal device readiness wrapper。
- backend-ready permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。
- renderer-state-write wrapper。

当前没有 platform object、backend object、native handle、raw pointer、resource token、real FFI retain / release / destroy call、Metal implementation、AppKit implementation、backend implementation、`MTLDevice`、`CAMetalLayer`、command queue、drawable、command buffer、render pass、encoder、pipeline state、command buffer commit、GPU submission、render execution、renderer state write、bridge / smoke / harness / native entry change、diagnostics / event bus / observer / telemetry 或 public API expansion。

## Relationship Facts

Backend platform object owner 与 backend-readiness branch / real backend first-slice / backend platform object preflight 的关系只能作为 dehydrated value facts 表达：

- no-backend-ready input preservation facts。
- future backend platform object owner intent facts。
- owner-local native resource vocabulary facts。
- no-handle / no-pointer surface facts。
- lifecycle teardown ordering facts。
- failure rollback / degraded / no-draw confinement facts。
- no-platform-object stop-line facts。
- future Metal device-layer owner preflight dependency facts。

这些 facts 不能携带 platform object、backend object、`MTLDevice`、`CAMetalLayer`、command queue、drawable、command buffer、render pass descriptor、encoder、pipeline state、GPU object、native handle、raw pointer、resource token、retain / release callback、destroy callback、observer callback、event bus、telemetry event、diagnostics output、renderer state object、public API handle 或 C ABI handle。

## Evidence Chain

[Backend platform object owner next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-next-boundary-decision.md) 已确认 `CjguiInternalRendererNoPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererBackendPlatformObjectOwnerDraft()` 足够作为当前 no-platform-object endpoint，并选择本 manifest stabilization。

[Backend platform object owner value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-platform-object-owner-value-boundary-closure-review.md) 已确认 owner file、canonical endpoint、default draft、open / defer / blocked fail-closed path、source stop-line 与 validation fallback。

[Backend platform object owner preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-preflight-decision.md) 只批准 internal value facts，不批准真实 platform object creation、native handle / raw pointer、real FFI retain / release / destroy calls、Metal / AppKit implementation 或 backend implementation。

[Real backend first-slice owner preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-real-backend-first-slice-owner-preflight-decision.md) 选择 platform object / native resource ownership 作为真实 backend 第一刀前的 docs-only preflight，不批准直接实现 Metal / AppKit backend。

[Backend-readiness branch milestone manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md) 与 [backend-readiness manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-manifest.md) 固定 upstream no-backend-ready tail；它们只作为 docs evidence，不授予 platform object permission。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 manifest 生效。

本轮选择 manifest 封账，明确拒绝：

- platform object receipt / record / publication。
- native-handle readiness wrapper。
- raw-pointer readiness wrapper。
- backend implementation wrapper。
- Metal device readiness wrapper。
- backend-ready permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。
- renderer-state-write wrapper。
- public API / C ABI wrapper。
- real platform object implementation。
- real native handle implementation。
- direct Metal / AppKit implementation。

`CjguiInternalRendererNoPlatformObjectReadiness` 已经是当前 no-platform-object endpoint。继续新增 receipt / record / publication 或 permission wrapper 会把同一 no-platform-object result 换名包装，缺少新的 owner truth、native resource lifecycle、teardown、confinement failure 或 implementation permission evidence。

若未来靠近 Metal device-layer、no-draw backend shell、real platform object、native handle、bridge / smoke / harness changes、command queue / drawable real lifecycle、command buffer commit、GPU submission、render execution、renderer state write、diagnostics / event bus / observer / telemetry 或 public API，必须先做 docs-only preflight，并引用本 manifest、[2026-05-04-p1-renderer-backend-platform-object-owner-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-next-boundary-decision.md) 与 backend / Metal reference evidence。

## Stop-line

继续禁止：

- no runtime code in this manifest round。
- no `.cj` modifications。
- no platform object creation。
- no backend object creation。
- no native handle。
- no raw pointer。
- no native resource token。
- no real retain / release / destroy FFI call。
- no bridge / smoke / harness / native entry modification。
- no backend implementation。
- no Metal implementation。
- no AppKit implementation。
- no `MTLDevice` / `CAMetalLayer` ownership。
- no command queue creation。
- no drawable acquisition。
- no command buffer creation or commit。
- no GPU submission。
- no render pass / encoder / pipeline state creation。
- no draw call execution。
- no render execution。
- no renderer state write。
- no diagnostics / event bus / observer / telemetry / public diagnostics。
- no public API / public C ABI expansion。
- no module-level `var`。
- no public declaration。
- no receipt / record / publication。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。
- no smoke / harness / native bridge / entry modifications。

## Public Surface

public symbol allowlist 未变：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本 manifest 不批准第二个 public symbol、不修改 Bool-only signature、不新增 structured public return、不开放 public C ABI。

## Next Stage Candidate Comparison

### A. P1 internal Renderer Metal device-layer owner preflight decision

推荐为下一阶段 opening。

理由：

- Backend platform object owner manifest 已固定 no-platform-object endpoint、native ownership vocabulary、teardown policy、confinement failure policy 与 stop-line。
- Metal device-layer owner 是下一层更具体的 platform resource owner question，但下一轮仍必须 docs-only，不创建 `MTLDevice` / `CAMetalLayer`。
- 该 preflight 应评估 device / layer ownership、resize / scale / color relation、failure / no-layer path、platform confinement 与 smoke strategy，而不是直接实现。

### B. No-draw backend shell preflight

暂缓。

No-draw shell 需要先引用本 manifest；它通常应等 Metal device-layer owner preflight 后再拆，避免退化成 backend shell wrapper。

### C. Command queue / drawable real lifecycle preflight

暂缓。

Command queue / drawable real lifecycle 必须晚于 device / layer owner preflight。当前仍没有 `MTLDevice` / `CAMetalLayer` permission。

### D. Backend platform object hardening

仅在发现不足时选择。

当前没有 native ownership / teardown / confinement 表达不足的 evidence；本轮不选择 hardening。

### E. Direct platform object / native handle implementation

拒绝。

### F. Direct Metal / AppKit implementation

拒绝。

### G. Command buffer commit / GPU submission / render execution

拒绝。

### H. Renderer state write

拒绝。

### I. Public API / C ABI expansion

拒绝。

### J. Receipt / record / publication

拒绝。

### K. Consolidation

暂缓。

仅在明确 duplicate / self-wrapping evidence 出现时选择。当前需要 Metal device-layer owner preflight，不是 consolidation。

## 决策结论

This manifest stabilizes and closes the renderer backend platform object owner no-platform-object endpoint.

Unique next opening:

`P1 internal Renderer Metal device-layer owner preflight decision`

下一轮仍必须 docs-only。它只能评估 `MTLDevice` / `CAMetalLayer` device-layer owner、layer drawable relation、resize / scale / color relation、failure / no-layer path、platform confinement 与 smoke strategy；不得创建 platform object、native handle、raw pointer、`MTLDevice`、`CAMetalLayer`、command queue、drawable、command buffer、render pass、encoder、pipeline state，不得修改 bridge / smoke / harness，不得 GPU submission、render execution、renderer state write、public API 或 C ABI。

## Downstream Metal Device-layer Owner Preflight

Renderer Metal device-layer owner preflight 已完成：

- [2026-05-04-p1-renderer-metal-device-layer-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-preflight-decision.md)

该 preflight 允许打开 Metal device-layer owner runway，并选择 `P1 internal Renderer Metal device-layer owner value boundary bundle implementation` 作为唯一 next opening。下一轮仍只是 internal value facts，不是真实 `MTLDevice` / `CAMetalLayer` creation。

Default owner candidate 是 `runtime/cjgui/src/runtime_renderer_metal_device_layer.cj`；runtime input 只建议消费 `CjguiInternalRendererNoPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererBackendPlatformObjectOwnerDraft()`。Output truth 仅限 Metal device-layer owner intent / device selection policy / layer binding policy / scale-color-space policy / no-metal-device-layer-readiness value facts。

Same-shape Boundary Brake 继续刹住 no-platform-object endpoint：不得把它包成 Metal device-layer receipt / record / publication、native-handle readiness wrapper、device-ready permission wrapper、layer-ready permission wrapper、backend implementation wrapper 或 GPU-submission wrapper。

唯一 next opening：

`P1 internal Renderer Metal device-layer owner value boundary bundle implementation`

## Downstream Metal Device-layer Owner Value Boundary

Renderer Metal device-layer owner value boundary 已完成：

- [2026-05-04-p1-internal-renderer-metal-device-layer-owner-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-metal-device-layer-owner-value-boundary-closure-review.md)

该 boundary 新增 `runtime/cjgui/src/runtime_renderer_metal_device_layer.cj`，只消费 `CjguiInternalRendererNoPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererBackendPlatformObjectOwnerDraft()`，canonical endpoint 是 `CjguiInternalRendererNoMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()`。

Current truth 仅限 Metal device-layer owner intent / device selection policy / layer binding policy / scale-color-space policy / no-metal-device-layer-readiness value facts。它不创建 `MTLDevice` / `CAMetalLayer`、platform object、native handle、raw pointer、command queue、drawable、command buffer、render pass、encoder 或 pipeline state，不调用 FFI / Objective-C / Metal / AppKit API，不修改 bridge / smoke / harness，不 GPU submission，不 render execution，不写 renderer state，不扩 public API / C ABI。

Same-shape Boundary Brake 继续刹住 no-platform-object endpoint：不得把它包成 Metal device-layer receipt / record / publication、native-handle readiness wrapper、device-ready permission wrapper、layer-ready permission wrapper、backend implementation wrapper 或 GPU-submission wrapper。

唯一 next opening：

`P1 internal Renderer Metal device-layer owner closure / next device-layer decision`

## Downstream Metal Device-layer Owner Next-boundary Decision

Renderer Metal device-layer owner next-boundary decision 已完成：

- [2026-05-04-p1-renderer-metal-device-layer-owner-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()` 已足够作为当前 no-metal-device-layer endpoint，并选择 `P1 internal Renderer Metal device-layer owner manifest stabilization bundle implementation` 作为唯一 next opening。

Current downstream truth 仍仅限 Metal device-layer owner intent / device selection policy / layer binding policy / scale-color-space policy / no-metal-device-layer-readiness value facts。它不是 `MTLDevice` permission、`CAMetalLayer` permission、platform object permission、native handle permission、backend implementation permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

唯一 next opening：

`P1 internal Renderer Metal device-layer owner manifest stabilization bundle implementation`

## Downstream Metal Device-layer Owner Manifest Stabilization

Renderer Metal device-layer owner manifest stabilization 已完成：

- [2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)
- [2026-05-04-p1-internal-renderer-metal-device-layer-owner-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-metal-device-layer-owner-manifest-stabilization-closure-review.md)

该 manifest 固定 downstream owner file `runtime/cjgui/src/runtime_renderer_metal_device_layer.cj`，canonical endpoint 是 `CjguiInternalRendererNoMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()`。Current truth 仅限 Metal device-layer owner intent / device selection policy / layer binding policy / scale-color-space policy / no-metal-device-layer-readiness value facts。

Same-shape Boundary Brake 继续刹住 no-platform-object / no-metal-device-layer endpoint：不得把它包成 Metal device-layer receipt / record / publication、native-handle readiness wrapper、device-ready permission wrapper、layer-ready permission wrapper、backend implementation wrapper、GPU-submission wrapper 或 render-permission wrapper。

唯一 next opening：

`P1 internal Renderer no-draw backend shell preflight decision`

## Downstream No-draw Backend Shell Preflight

Renderer no-draw backend shell preflight 已完成：

- [2026-05-04-p1-renderer-no-draw-backend-shell-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-no-draw-backend-shell-preflight-decision.md)

该 preflight 在 downstream no-metal-device-layer endpoint 之后允许打开 no-draw backend shell runway，并选择 `P1 internal Renderer no-draw backend shell value boundary bundle implementation` 作为唯一 next opening。下一轮仍只是 internal value facts，不是真实 backend shell implementation。

It consumes only `CjguiInternalRendererNoMetalDeviceLayerReadiness` as proposed runtime input, while this backend platform object manifest remains docs evidence for native ownership / teardown / confinement stop-lines.

唯一 next opening：

`P1 internal Renderer no-draw backend shell value boundary bundle implementation`

## Downstream Native Resource Bridge Preflight

Renderer native resource bridge preflight 已完成：

- [2026-05-05-p1-renderer-native-resource-bridge-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-preflight-decision.md)

该 preflight 使用本 manifest 作为 docs evidence：`CjguiInternalRendererNoPlatformObjectReadiness` 提供 native resource ownership policy、lifecycle teardown policy 与 confinement failure policy vocabulary，但仍不授予 platform object、native handle、raw pointer、retain / release / destroy FFI call、bridge modification、backend implementation、GPU submission、render execution 或 public C ABI permission。

Native resource bridge preflight 的 runtime input candidate 只消费 downstream backend shell skeleton manifest 的 `CjguiInternalRendererNoResourceBackendShellReadiness`；本 manifest 不作为 runtime input，不进入 native bridge owner。

唯一 next opening：

`P1 internal Renderer native resource bridge value boundary bundle implementation`

## Downstream Platform Object Implementation Preflight

Renderer platform object implementation preflight 已完成：

- [2026-05-05-p1-renderer-platform-object-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-preflight-decision.md)

该 preflight 使用本 manifest 作为 docs evidence：`CjguiInternalRendererNoPlatformObjectReadiness` 提供 native resource ownership policy、lifecycle teardown policy 与 confinement failure policy vocabulary，但仍不授予 platform object creation、native handle、raw pointer、retain / release / destroy FFI call、bridge modification、backend implementation、GPU submission、render execution 或 public C ABI permission。

Platform object implementation preflight 的 runtime input candidate 只消费 downstream native resource bridge manifest 的 `CjguiInternalRendererNoNativeResourceBridgeReadiness`；本 manifest 不作为 runtime input，不进入 implementation admission owner。

唯一 next opening：

`P1 internal Renderer platform object implementation admission value boundary bundle implementation`

## Downstream Platform Object Implementation Admission Value Boundary

Renderer platform object implementation admission value boundary 已完成：

- [2026-05-05-p1-internal-renderer-platform-object-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-platform-object-implementation-admission-value-boundary-closure-review.md)

该 downstream owner file 是 [runtime_renderer_platform_object_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_platform_object_admission.cj)。它只消费 `CjguiInternalRendererNoNativeResourceBridgeReadiness`，而本 backend platform object owner manifest 仍是 docs evidence，不作为 runtime input。

Canonical endpoint 是 `CjguiInternalRendererNoPlatformObjectImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()`。Current truth 仅限 platform object implementation intent / native handle admission policy / platform object lifecycle admission guard / teardown failure policy / no-platform-object-implementation readiness value facts。

Same-shape Boundary Brake 继续刹住 no-platform-object / no-native-resource-bridge endpoints：不得把它们包成 platform-object permission wrapper、native-handle permission wrapper、C-ABI / FFI permission wrapper、Metal-device permission wrapper、backend implementation wrapper、GPU-submission wrapper、render-permission wrapper、receipt / record / publication。

唯一 downstream next opening：

`P1 internal Renderer platform object implementation admission closure / next platform object implementation decision`

## Downstream Platform Object Implementation Admission Next-boundary Decision

Renderer platform object implementation admission next-boundary decision 已完成：

- [2026-05-05-p1-renderer-platform-object-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-next-boundary-decision.md)

该 downstream decision 确认 `CjguiInternalRendererNoPlatformObjectImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()` 已足够作为当前 no-platform-object-implementation endpoint。This backend platform object owner manifest remains docs evidence for native ownership / teardown / confinement only; it is not runtime input and does not grant platform object implementation, native handle, C ABI / FFI, Metal / AppKit bridge, GPU submission, render, renderer state write or public API permission.

唯一 downstream next opening：

`P1 internal Renderer platform object implementation admission manifest stabilization bundle implementation`

## Downstream Platform Object Implementation Admission Manifest Stabilization

Renderer platform object implementation admission manifest stabilization 已完成：

- [2026-05-05-p1-renderer-platform-object-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-manifest.md)
- [2026-05-05-p1-internal-renderer-platform-object-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-platform-object-implementation-admission-manifest-stabilization-closure-review.md)

该 downstream manifest 固定 [runtime_renderer_platform_object_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_platform_object_admission.cj) owner / truth / canonical endpoint / stop-line。It consumes only `CjguiInternalRendererNoNativeResourceBridgeReadiness`; this backend platform object owner manifest remains docs evidence for native resource ownership, lifecycle teardown and confinement failure vocabulary only.

Canonical endpoint 是 `CjguiInternalRendererNoPlatformObjectImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()`。Current truth 仅限 platform object implementation intent / native handle admission policy / platform object lifecycle admission guard / teardown failure policy / no-platform-object-implementation readiness value facts。

Same-shape Boundary Brake 继续刹住 no-platform-object / no-native-resource-bridge endpoints：不得把它们包成 platform-object permission wrapper、native-handle permission wrapper、C-ABI / FFI permission wrapper、Metal-device permission wrapper、backend implementation wrapper、GPU-submission wrapper、render-permission wrapper、renderer-state-write wrapper、receipt / record / publication。

唯一 downstream next opening：

`P1 internal Renderer Metal device-layer implementation preflight decision`

## 下游真实 platform object 第一刀预检

Renderer real backend platform object first implementation preflight decision 已完成：

- [2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-preflight-decision.md)

该 downstream 回看本 manifest 的 native resource ownership、lifecycle teardown 与 confinement failure vocabulary 作为 planning evidence，并确认下一步只允许极窄 internal runtime owner shell。它不把 `CjguiInternalRendererNoPlatformObjectReadiness` 升格为 platform object permission、native handle permission、raw pointer permission、real retain / release / destroy permission、bridge modification permission、Metal / AppKit permission、GPU submission permission、renderer state write permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer real backend platform object first implementation slice bundle`

## 下游真实 platform object 第一刀切片闭环

Renderer real backend platform object first implementation slice 已完成：

- [2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-closure-review.md)
- [runtime_renderer_backend_platform_object_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_platform_object_real.cj)

该 downstream owner 只把本 manifest 的 native resource ownership、lifecycle teardown 与 confinement failure vocabulary 作为 planning evidence；它不把 `CjguiInternalRendererNoPlatformObjectReadiness` 升格为 runtime input，也不授予 platform object permission、native handle permission、raw pointer permission、real retain / release / destroy permission、bridge modification permission、Metal / AppKit permission、GPU submission permission、renderer state write permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer real backend platform object first implementation slice closure / next real backend platform object decision`

## 下游真实 platform object 第一刀后续边界决策

Renderer real backend platform object first implementation slice next-boundary decision 已完成：

- [2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-next-boundary-decision.md)

该 downstream decision 确认 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()` 足够作为当前 shell endpoint。它只把本 manifest 的 native resource ownership、lifecycle teardown 与 confinement failure vocabulary 作为 planning evidence，不把 `CjguiInternalRendererNoPlatformObjectReadiness` 升格为 runtime input，也不授予 platform object permission、native handle permission、raw pointer permission、real retain / release / destroy permission、bridge modification permission、Metal / AppKit permission、GPU submission permission、renderer state write permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer real backend platform object first implementation slice manifest stabilization bundle implementation`

## 下游真实 platform object 第一刀切片 manifest 稳定化

Renderer real backend platform object first implementation slice manifest stabilization 已完成：

- [2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)
- [2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-manifest-stabilization-closure-review.md)

该 downstream manifest 只把本 manifest 的 native resource ownership、lifecycle teardown 与 confinement failure vocabulary 作为 planning evidence，不把 `CjguiInternalRendererNoPlatformObjectReadiness` 升格为 runtime input、platform object permission、native handle permission、raw pointer permission、bridge modification permission、Metal / AppKit permission、GPU submission permission、renderer state write permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer real backend platform object branch closure / next real platform object decision`

## 下游真实 platform object 分支后续边界决策

Renderer real backend platform object branch next-boundary decision 已完成：

- [2026-05-07-p1-renderer-real-backend-platform-object-branch-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-branch-next-boundary-decision.md)

该 downstream decision 继续把本 manifest 的 native resource ownership、lifecycle teardown 与 confinement failure vocabulary 作为 planning evidence，不把 `CjguiInternalRendererNoPlatformObjectReadiness` 升格为 runtime input、platform object permission、native handle permission、raw pointer permission、bridge modification permission、Metal / AppKit permission、GPU submission permission、renderer state write permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native teardown contract hardening preflight decision`

## 下游 native teardown 合约硬化 value boundary

下游 native teardown contract hardening value boundary 已完成：

- [native teardown contract hardening value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-native-teardown-contract-hardening-value-boundary-closure-review.md)
- [runtime_renderer_native_teardown_contract.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_teardown_contract.cj)

该 boundary 位于 real backend platform object shell 之后，唯一 runtime input 是 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness`。它不改变本 manifest 的 `CjguiInternalRendererNoPlatformObjectReadiness` truth，也不把 backend platform object owner facts 升格为 native handle、C ABI / FFI、retain / release / destroy、Objective-C、Metal、AppKit、backend-ready、GPU submission、renderer state write 或 public API permission。

新的下游后续入口：

`P1 internal Renderer native teardown contract hardening closure / next native teardown decision`
