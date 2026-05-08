# P1 Renderer Metal device-layer owner manifest

日期：2026-05-04

状态：manifest stabilization

## Purpose

本 manifest 固定 `runtime_renderer_metal_device_layer.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-metal-device-layer endpoint。

它不是 `MTLDevice` implementation manifest，不是 `CAMetalLayer` implementation manifest，不是 Objective-C / Metal / AppKit / FFI bridge plan，不是 backend implementation plan，也不是 command queue / drawable / command buffer / render execution / renderer state write plan。它只记录 Metal device-layer owner intent、device selection policy、layer binding policy、scale-color-space policy 与 no-metal-device-layer readiness 的 internal value facts。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer.cj`

Canonical upstream endpoint：

- `CjguiInternalRendererNoPlatformObjectReadiness`
- `cjguiInternalExecuteDefaultRendererBackendPlatformObjectOwnerDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoMetalDeviceLayerReadiness`
- `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()`

Current truth：

- Metal device-layer owner intent value facts。
- Device selection policy value facts。
- Layer binding policy value facts。
- Scale-color-space policy value facts。
- No-metal-device-layer-readiness value facts。

## Current Pipeline

当前 Metal device-layer owner value pipeline：

1. `CjguiInternalRendererNoPlatformObjectReadiness`
2. `CjguiInternalRendererMetalDeviceLayerOwnerIntent`
3. `CjguiInternalRendererMetalDeviceSelectionPolicy`
4. `CjguiInternalRendererMetalLayerBindingPolicy`
5. `CjguiInternalRendererMetalScaleColorSpacePolicy`
6. `CjguiInternalRendererNoMetalDeviceLayerReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()`
- 只调用 `cjguiInternalExecuteDefaultRendererBackendPlatformObjectOwnerDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不接 backend / Metal / AppKit implementation。
- 不创建 `MTLDevice`。
- 不创建 `CAMetalLayer`。
- 不创建 platform object。
- 不创建 native handle。
- 不创建 raw pointer。
- 不创建 command queue / drawable / command buffer / render pass / encoder / pipeline state。
- 不调用 FFI / Objective-C / Metal / AppKit API。
- 不修改 bridge / smoke / harness / native entry。
- 不提交 command buffer。
- 不 present drawable。
- 不提交 GPU work。
- 不执行 render。
- 不写 renderer state。
- 不写或触碰 `runtime_state.cj`。
- 不注册 callback / observer / event bus / telemetry。
- 不开放 public diagnostics / public API / C ABI。
- 不新增 module-level `var`。
- 不新增 public declaration。

## Value Semantics

`CjguiInternalRendererMetalDeviceLayerOwnerIntent` 只表达 future Metal device-layer owner intent。它不是 `MTLDevice` creation，不是 `CAMetalLayer` creation，不是 backend implementation permission，也不是 no-platform-object receipt / record / publication。

`CjguiInternalRendererMetalDeviceSelectionPolicy` 只表达 future device choice、capability fallback 与 no-device fallback facts。它不创建 `MTLDevice`，不查询真实 device，不调用 Metal API，不授予 device-ready permission，也不授予 command queue creation permission。

`CjguiInternalRendererMetalLayerBindingPolicy` 只表达 future layer host relation、drawable pool boundary 与 no-layer fallback facts。它不创建、绑定、持有或配置 `CAMetalLayer`，不 acquire drawable，不配置 platform layer state，不授予 layer-ready permission，也不授予 command queue / drawable / command buffer / render pass / encoder / pipeline creation permission。

`CjguiInternalRendererMetalScaleColorSpacePolicy` 只表达 dehydrated drawable size、backing scale、pixel format 与 color space policy facts。它不读取真实 display scale，不读取真实 color space，不读取 `NSView` / `NSWindow` / `NSScreen` / platform layer，不配置 layer state，不写 renderer state，也不开放 external observation surface。

`CjguiInternalRendererNoMetalDeviceLayerReadiness` 是当前 no-metal-device-layer endpoint。Readiness 只表示该 internal value boundary 可以继续评估，不代表 `MTLDevice` permission、`CAMetalLayer` permission、platform object permission、native handle permission、raw pointer permission、backend implementation permission、command queue permission、drawable acquisition permission、command buffer commit permission、GPU submission permission、render permission、renderer state write permission、public diagnostics permission、public API permission 或 C ABI permission。

## Explicit Non-Truth

`CjguiInternalRendererNoMetalDeviceLayerReadiness` 明确不是：

- `MTLDevice` permission。
- `MTLDevice` ownership。
- `CAMetalLayer` permission。
- `CAMetalLayer` ownership。
- platform object permission。
- backend object permission。
- native handle permission。
- raw pointer permission。
- native resource token。
- Objective-C / Metal / AppKit / FFI bridge permission。
- bridge / smoke / harness / native entry modification permission。
- backend implementation permission。
- backend-ready permission。
- command queue ownership。
- drawable ownership。
- drawable acquisition permission。
- command buffer ownership。
- command buffer commit permission。
- drawable present permission。
- GPU submission permission。
- render pass ownership。
- encoder ownership。
- pipeline state ownership。
- render execution permission。
- render permission。
- renderer state write permission。
- diagnostics publication。
- public diagnostics permission。
- public API permission。
- public C ABI。
- Metal device-layer receipt / record / publication。
- native-handle readiness wrapper。
- device-ready permission wrapper。
- layer-ready permission wrapper。
- backend implementation wrapper。
- GPU-submission wrapper。
- render-permission wrapper。
- renderer-state-write wrapper。

当前没有 `MTLDevice`、`CAMetalLayer`、platform object、backend object、native handle、raw pointer、resource token、Objective-C / Metal / AppKit / FFI call、Metal implementation、AppKit implementation、backend implementation、command queue、drawable、command buffer、render pass、encoder、pipeline state、command buffer commit、drawable present、GPU submission、render execution、renderer state write、bridge / smoke / harness / native entry change、diagnostics / event bus / observer / telemetry 或 public API expansion。

## Relationship Facts

Metal device-layer owner 与 backend platform object owner / backend readiness branch / backend Metal reference pack / future no-draw backend shell 的关系只能作为 dehydrated value facts 表达：

- no-platform-object input preservation facts。
- future Metal device-layer owner intent facts。
- future device selection / no-device fallback facts。
- future layer binding / no-layer fallback facts。
- future drawable pool boundary facts without drawable acquisition。
- future drawable size / backing scale / pixel format / color space facts。
- no-device / no-layer / no-metal-device-layer stop-line facts。
- future no-draw backend shell preflight and value-boundary dependency facts。
- future command queue / drawable real lifecycle preflight dependency facts。

这些 facts 不能携带 `MTLDevice`、`CAMetalLayer`、platform object、backend object、command queue、drawable、command buffer、render pass descriptor、encoder、pipeline state、GPU object、native handle、raw pointer、resource token、Objective-C object, Metal object, FFI pointer, callback, observer, event bus, telemetry event, diagnostics output, renderer state object, public API handle 或 C ABI handle。

## Evidence Chain

[Metal device-layer owner next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-next-boundary-decision.md) 已确认 `CjguiInternalRendererNoMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()` 足够作为当前 no-metal-device-layer endpoint，并选择本 manifest stabilization。

[Metal device-layer owner value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-metal-device-layer-owner-value-boundary-closure-review.md) 已确认 owner file、canonical endpoint、default draft、open / defer / blocked fail-closed path、source stop-line 与 validation fallback。

[Metal device-layer owner preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-preflight-decision.md) 只批准 internal value facts，不批准真实 `MTLDevice` / `CAMetalLayer` creation、Objective-C / Metal / AppKit / FFI calls、bridge modification、command queue / drawable / command buffer implementation、GPU submission 或 renderer state write。

[Backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md) 固定 upstream no-platform-object endpoint、native ownership vocabulary、teardown policy 与 confinement failure facts；它只作为 docs evidence，不授予 device / layer permission。

[Backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 固定 `MTLDevice`、`CAMetalLayer`、drawable pool、resize / backing scale / color space 与 frame pacing evidence；reference pack 只作为 evidence，不是 runtime input，不批准 implementation。

[No-draw backend shell preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-no-draw-backend-shell-preflight-decision.md) 已选择只做 internal value boundary，不批准真实 backend shell implementation。

[No-draw backend shell value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-no-draw-backend-shell-value-boundary-closure-review.md) 已新增 downstream owner `runtime_renderer_no_draw_backend_shell.cj`，只消费 `CjguiInternalRendererNoMetalDeviceLayerReadiness`，并固定 downstream canonical endpoint `CjguiInternalRendererNoBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()`。

[No-draw backend shell next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-no-draw-backend-shell-next-boundary-decision.md) 已确认 downstream no-backend-shell endpoint 足够，并选择下一步先做 no-draw backend shell manifest stabilization；command queue / drawable real lifecycle、real platform object implementation、command buffer commit / GPU submission 仍暂缓。

[Metal device-layer implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-preflight-decision.md) 已在后续 implementation-admission runway 中引用本 manifest 作为 docs evidence，但没有把 `CjguiInternalRendererNoMetalDeviceLayerReadiness` 升格为 runtime input 或 device / layer permission。

[Metal device-layer implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-metal-device-layer-implementation-admission-value-boundary-closure-review.md) 已新增 downstream owner `runtime_renderer_metal_device_layer_admission.cj`，只消费 `CjguiInternalRendererNoPlatformObjectImplementationReadiness`，并固定 downstream canonical endpoint `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft()`。

[Metal device-layer implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-next-boundary-decision.md) 已确认 downstream no-metal-device-layer-implementation endpoint 足够，并选择下一步做 Metal device-layer implementation admission manifest stabilization；device-ready wrapper、layer-ready wrapper、native-handle wrapper、C-ABI / FFI wrapper、GPU-submission wrapper、render-permission wrapper、receipt / record / publication 均拒绝。

[Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md) 与 [Metal device-layer implementation admission manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-metal-device-layer-implementation-admission-manifest-stabilization-closure-review.md) 已固定 downstream implementation admission owner / truth / canonical endpoint / stop-line，并选择下一步 docs-only real command queue implementation preflight；本 manifest 仍只是 upstream docs evidence，不变成 runtime input。

[Real Metal device-layer first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-preflight-decision.md) 已回看本 manifest 作为 owner vocabulary evidence，并选择下一步进入极窄 first implementation slice。该 decision 不把 `CjguiInternalRendererNoMetalDeviceLayerReadiness` 升格为 `MTLDevice` permission、`CAMetalLayer` permission、native handle permission、C ABI / FFI permission、command queue permission、drawable permission、GPU submission permission、renderer state write permission 或 public API permission。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 manifest 生效。

本轮选择 manifest 封账，明确拒绝：

- Metal device-layer receipt / record / publication。
- native-handle readiness wrapper。
- device-ready permission wrapper。
- layer-ready permission wrapper。
- backend implementation wrapper。
- backend-ready permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。
- renderer-state-write wrapper。
- public API / C ABI wrapper。
- real `MTLDevice` implementation。
- real `CAMetalLayer` implementation。
- direct Objective-C / Metal / AppKit / FFI bridge modification。

`CjguiInternalRendererNoMetalDeviceLayerReadiness` 已经是当前 no-metal-device-layer endpoint。继续新增 receipt / record / publication 或 permission wrapper 会把同一 no-metal-device-layer result 换名包装，缺少新的 owner truth、device selection、layer binding、scale-color-space、failure fallback 或 implementation permission evidence。

若未来靠近 no-draw backend shell、command queue / drawable real lifecycle、real Metal object、Objective-C / Metal / AppKit / FFI bridge, command buffer commit、GPU submission、render execution、renderer state write、diagnostics / event bus / observer / telemetry 或 public API，必须先做 docs-only preflight，并引用本 manifest、[2026-05-04-p1-renderer-metal-device-layer-owner-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-next-boundary-decision.md) 与 backend / Metal reference evidence。

## Stop-line

继续禁止：

- no runtime code in this manifest round。
- no `.cj` modifications。
- no `MTLDevice` creation。
- no `CAMetalLayer` creation。
- no platform object creation。
- no backend object creation。
- no native handle。
- no raw pointer。
- no native resource token。
- no FFI call。
- no Objective-C call。
- no Metal API call。
- no AppKit API call。
- no bridge / smoke / harness / native entry modification。
- no backend implementation。
- no Metal implementation。
- no AppKit implementation。
- no command queue creation。
- no drawable acquisition。
- no command buffer creation or commit。
- no drawable present。
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

### A. P1 internal Renderer no-draw backend shell preflight decision

推荐为下一阶段 opening。

理由：

- Metal device-layer owner manifest 已固定 no-metal-device-layer endpoint、device selection、layer binding、scale-color-space 与 stop-line。
- No-draw backend shell 是靠近真实 backend implementation 前更安全的 docs-only owner question，能评估 backend shell lifecycle、no-device / no-layer fallback、teardown / failure path 与 smoke strategy。
- 下一轮仍必须 docs-only，不创建 backend object、platform object、`MTLDevice`、`CAMetalLayer`、command queue、drawable、command buffer、render pass、encoder、pipeline state，不实现 scheduler / render loop / GPU submission / renderer state write。

### B. Command queue / drawable real lifecycle preflight

暂缓。

Command queue / drawable real lifecycle 应晚于 no-draw backend shell preflight 或至少晚于 device-layer owner manifest stabilization。当前没有真实 device / layer permission，也没有 no-draw backend shell owner truth。

### C. Metal device-layer hardening

仅在发现不足时选择。

当前没有 device selection / layer binding / scale-color-space 表达不足的 evidence；本轮不选择 hardening。

### D. Direct `MTLDevice` / `CAMetalLayer` implementation

拒绝。

### E. Direct Objective-C / Metal / AppKit bridge modification

拒绝。

### F. Command buffer commit / GPU submission / render execution

拒绝。

### G. Renderer state write

拒绝。

### H. Public API / C ABI expansion

拒绝。

### I. Receipt / record / publication

拒绝。

### J. Consolidation

暂缓。

仅在明确 duplicate / self-wrapping evidence 出现时选择。当前需要 no-draw backend shell preflight，不是 consolidation。

## 当前封账结论

本 manifest 稳定并封账 renderer Metal device-layer owner 的 no-metal-device-layer endpoint。

唯一后续入口：

`P1 internal Renderer no-draw backend shell preflight decision`

下一轮仍必须 docs-only。它只能评估 no-draw backend shell owner、backend lifecycle shell、no-device / no-layer fallback、teardown / failure path 与 smoke strategy；不得创建 backend object、platform object、native handle、raw pointer、`MTLDevice`、`CAMetalLayer`、command queue、drawable、command buffer、render pass、encoder、pipeline state，不得修改 bridge / smoke / harness，不得 GPU submission、render execution、renderer state write、public API 或 C ABI。

## 下游 Metal device-layer 实现预检

Renderer Metal device-layer implementation preflight 已完成：

- [2026-05-05-p1-renderer-metal-device-layer-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-preflight-decision.md)
- [2026-05-05-p1-renderer-metal-device-layer-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-next-boundary-decision.md)
- [2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md)
- [2026-05-05-p1-internal-renderer-metal-device-layer-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-metal-device-layer-implementation-admission-manifest-stabilization-closure-review.md)

该 downstream preflight 使用本 manifest 作为 docs evidence：`CjguiInternalRendererNoMetalDeviceLayerReadiness` 提供 device selection policy、layer binding policy、scale-color-space policy 与 no-metal-device-layer vocabulary，但仍不授予 `MTLDevice` creation、`CAMetalLayer` creation / binding、native handle、raw pointer、C ABI、FFI declaration、bridge call、backend implementation、GPU submission、render execution 或 public API permission。

Metal device-layer implementation preflight 的 runtime input candidate 只消费 downstream platform object implementation admission manifest 的 `CjguiInternalRendererNoPlatformObjectImplementationReadiness`；本 manifest 不作为 runtime input，不进入 implementation admission owner。

唯一 downstream next opening：

`P1 internal Renderer real command queue implementation preflight decision`

## 下游 no-draw backend shell 预检

Renderer no-draw backend shell preflight 已完成：

- [2026-05-04-p1-renderer-no-draw-backend-shell-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-no-draw-backend-shell-preflight-decision.md)

该 preflight 允许打开 no-draw backend shell runway，并选择 `P1 internal Renderer no-draw backend shell value boundary bundle implementation` 作为唯一 next opening。下一轮仍只是 internal value facts，不是真实 backend shell implementation。

默认 owner candidate 是 `runtime/cjgui/src/runtime_renderer_no_draw_backend_shell.cj`；runtime input 只建议消费 `CjguiInternalRendererNoMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()`。Output truth 仅限 no-draw backend shell intent / backend shell lifecycle policy / no-draw execution gate / shell teardown policy / no-backend-shell-readiness value facts。

Same-shape Boundary Brake 继续刹住 no-metal-device-layer endpoint：不得把它包成 no-draw backend shell receipt / record / publication、backend-shell-ready permission wrapper、backend implementation wrapper、GPU-submission wrapper 或 render-permission wrapper。

唯一 next opening：

`P1 internal Renderer no-draw backend shell value boundary bundle implementation`

## 下游 no-draw backend shell manifest 稳定化

Renderer no-draw backend shell manifest stabilization 已完成：

- [2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md)
- [2026-05-05-p1-internal-renderer-no-draw-backend-shell-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-no-draw-backend-shell-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime_renderer_no_draw_backend_shell.cj` owner / truth / canonical endpoint / stop-line。Canonical endpoint 是 `CjguiInternalRendererNoBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()`；current truth 是 no-draw backend shell intent / backend shell lifecycle policy / no-draw execution gate / shell teardown policy / no-backend-shell readiness value facts。

Same-shape Boundary Brake 同步拒绝 no-draw backend shell receipt / record / publication、backend-shell-ready permission wrapper、backend implementation wrapper、GPU-submission wrapper、render-permission wrapper 与 platform-object wrapper。

当前下游后续入口：

`P1 internal Renderer command queue / drawable real lifecycle preflight decision`

## 下游 command queue / drawable 真实生命周期预检

Renderer command queue / drawable real lifecycle preflight 已完成：

- [2026-05-05-p1-renderer-command-queue-drawable-real-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-queue-drawable-real-lifecycle-preflight-decision.md)

该 preflight 判定 command queue / drawable real lifecycle runway 可以打开，但不批准 combined value boundary 或真实 `MTLCommandQueue` / drawable implementation。下一步先做 docs-only `P1 internal Renderer real command queue lifecycle preflight decision`；real drawable lifecycle 暂缓到 real command queue owner vocabulary 之后。

Metal device-layer owner manifest 仍只是 upstream evidence：`CjguiInternalRendererNoMetalDeviceLayerReadiness` 不授予 `MTLDevice`、`CAMetalLayer`、command queue、drawable、command buffer、GPU submission、render execution、renderer state write、public API 或 C ABI permission。

## 下游真实 Metal device-layer 第一刀切片

下游 real Metal device-layer first implementation slice 已完成：

- [real Metal device-layer first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-preflight-decision.md)
- [real Metal device-layer first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-closure-review.md)
- [runtime_renderer_metal_device_layer_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj)

该 downstream slice 只把本 owner manifest 作为 historical evidence，不消费 `CjguiInternalRendererNoMetalDeviceLayerReadiness` 作为 runtime input。新的 shell endpoint `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` 仍不是 `MTLDevice` / `CAMetalLayer` creation permission、Metal-ready wrapper、device-ready wrapper、layer-ready wrapper、backend-ready wrapper、GPU submission permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer first implementation slice closure / next real Metal device-layer decision`

## 下游真实 Metal device-layer manifest 封账

下游 real Metal device-layer first implementation slice manifest stabilization 已完成：

- [real Metal device-layer first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-manifest.md)
- [real Metal device-layer first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-manifest-stabilization-closure-review.md)

该 downstream manifest 只把本 owner manifest 作为 historical evidence，不消费 `CjguiInternalRendererNoMetalDeviceLayerReadiness` 作为 runtime input，也不把它升格为真实 `MTLDevice` / `CAMetalLayer` creation permission、Metal-ready wrapper、device-ready wrapper、layer-ready wrapper、backend-ready wrapper、GPU submission permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer branch closure / next real Metal device-layer decision`

## 下游真实 Metal device-layer 分支后续边界决策

下游 real Metal device-layer branch next-boundary decision 已完成：

- [real Metal device-layer branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-metal-device-layer-branch-next-boundary-decision.md)

该 downstream decision 只把本 owner manifest 作为 historical evidence，不消费 `CjguiInternalRendererNoMetalDeviceLayerReadiness` 作为 runtime input，也不把它升格为真实 `MTLDevice` / `CAMetalLayer` creation permission、Metal-ready wrapper、device-ready wrapper、layer-ready wrapper、`MTLCommandQueue` permission、drawable permission、GPU submission permission、renderer state write permission、backend-ready truth 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real command queue first implementation preflight decision`
