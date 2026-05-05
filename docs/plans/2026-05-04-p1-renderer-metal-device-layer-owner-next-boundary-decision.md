# P1 Renderer Metal device-layer owner next-boundary decision

日期：2026-05-04

状态：docs-only next-boundary decision

## Scope

本轮评估 `CjguiInternalRendererNoMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()` 是否足够作为当前 no-metal-device-layer endpoint，并决定下一步是否先做 manifest stabilization。

本轮 docs-only：不修改 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER，不创建 `MTLDevice` / `CAMetalLayer`，不接 Objective-C / Metal / AppKit / FFI，不创建 command queue / drawable / command buffer / render pass / encoder / pipeline state，不 commit / present / submit GPU work，不写 renderer state，不扩 public API / C ABI。

## Inputs Read

- [runtime_renderer_metal_device_layer.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer.cj)
- [2026-05-04-p1-internal-renderer-metal-device-layer-owner-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-metal-device-layer-owner-value-boundary-closure-review.md)
- [2026-05-04-p1-renderer-metal-device-layer-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-preflight-decision.md)
- [2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [runtime/cjgui README](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans README](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## Decision

`CjguiInternalRendererNoMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()` 已足够作为当前 no-metal-device-layer lifecycle endpoint。

下一步选择：

`P1 internal Renderer Metal device-layer owner manifest stabilization bundle implementation`

下一步必须继续 docs-only，固定 `runtime_renderer_metal_device_layer.cj` 的 owner / truth / canonical endpoint / stop-line；不创建真实 `MTLDevice` / `CAMetalLayer`，不接 platform object、native handle、raw pointer、Objective-C / Metal / AppKit / FFI，不进入 command queue / drawable / command buffer / render pass / encoder / pipeline state，不 commit / present / submit GPU work，不写 renderer state，不扩 public API / C ABI。

## Endpoint Sufficiency

`CjguiInternalRendererNoMetalDeviceLayerReadiness` 足够作为当前 endpoint，原因是它已经具备独立于 upstream no-platform-object endpoint 的新增语义：

- Metal device-layer owner intent：只表达 future device-layer ownership runway，不是 backend implementation permission。
- Device selection policy：只表达 future device selection / no-device fallback value facts，不创建或查询真实 device。
- Layer binding policy：只表达 future layer binding / no-layer fallback value facts，不创建、绑定、持有或配置真实 layer。
- Scale-color-space policy：只表达 backing scale / drawable size / pixel format / color space value facts，不读取 platform view、window、screen 或 layer。
- No-metal-device-layer readiness：明确当前没有 device、layer、platform resource、foreign resource token、pointer-like resource、command queue、drawable、command buffer、render pass、encoder、pipeline state、command buffer commit、GPU submission、render execution、renderer state mutation、bridge / smoke / harness / entry change 或 external API surface。
- Open / defer / blocked path fail closed：default draft 只消费 `CjguiInternalRendererNoPlatformObjectReadiness`，defer-only 不伪造 readiness，blocked / inconsistent input 保持 blocked。

Closure evidence 证明该 owner 的 fields / source comments / closure 已经落实 no-device / no-layer / no-native-handle / no-render stop-line；本轮不需要 hardening 先于 manifest stabilization。

## Candidate Comparison

### A. P1 internal Renderer Metal device-layer owner manifest stabilization bundle implementation

推荐。

它固定 owner file、canonical endpoint、default draft、current truth 与 stop-line，并封账当前 no-metal-device-layer endpoint。该选择只做 docs-only manifest，不写 runtime code，也不批准真实 device / layer creation。

### B. No-draw backend shell preflight

暂缓。

No-draw backend shell 应等 Metal device-layer owner manifest 固定后再评估。否则容易绕过 device selection / layer binding / scale-color-space stop-line，退化成 backend shell wrapper。

### C. Command queue / drawable real lifecycle preflight

暂缓。

Command queue / drawable real lifecycle 必须晚于 Metal device-layer owner manifest。当前没有真实 `MTLDevice` / `CAMetalLayer` permission，也没有 command queue / drawable real owner truth。

### D. Metal reference hardening

暂缓。

Reference evidence 已足以支持 manifest stabilization。只有在 manifest round 发现 device selection、layer binding、scale-color-space 或 no-metal-device-layer facts 表达不足时，才重新打开 docs hardening。

### E. Metal device-layer receipt / record / publication

拒绝。

这些会把 endpoint 变成同构尾巴，缺少新的 owner / lifecycle / stop-line evidence。

### F. Native-handle readiness wrapper

拒绝。

No-metal-device-layer endpoint 不携带 native handle、raw pointer 或 platform resource token。

### G. Device-ready permission wrapper

拒绝。

Device selection policy 不是 `MTLDevice` permission。

### H. Layer-ready permission wrapper

拒绝。

Layer binding policy 不是 `CAMetalLayer` permission。

### I. Backend implementation wrapper

拒绝。

当前 endpoint 不是 backend implementation permission，也不授予 no-draw backend shell。

### J. GPU-submission wrapper

拒绝。

当前 endpoint 没有 command buffer commit、drawable present、GPU submission 或 render execution permission。

### K. Public API / C ABI expansion

拒绝。

本 branch 仍保持 internal-only value facts，不扩 public declaration 或 public C ABI。

### L. Direct `MTLDevice` / `CAMetalLayer` implementation

拒绝。

真实 device / layer creation 必须另开 docs-only implementation preflight，不得由本 endpoint 直接批准。

### M. Direct Objective-C / Metal / AppKit / FFI / bridge modification

拒绝。

不得修改 bridge、smoke、harness 或 native entry，不调用 Objective-C / Metal / AppKit / FFI API。

### N. Command queue / drawable / command buffer implementation

拒绝。

这些必须晚于 device-layer manifest、对应 real lifecycle preflight 与 platform owner evidence。

### O. Renderer state write / render execution

拒绝。

当前仍是 no-render / no-state-write boundary。

### P. Consolidation

暂缓。

仅在明确 duplicate / low-value / self-wrapping evidence 出现时选择。当前 evidence 指向 manifest stabilization，而不是 consolidation。

## Same-shape Boundary Brake

`CjguiInternalRendererNoMetalDeviceLayerReadiness` 不再继续包装成 tail wrapper。

当前 endpoint 只代表：

- Metal device-layer owner intent value facts。
- Device selection policy value facts。
- Layer binding policy value facts。
- Scale-color-space policy value facts。
- No-metal-device-layer-readiness value facts。

它不是 `MTLDevice` permission、`CAMetalLayer` permission、platform object permission、native handle permission、backend implementation permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

本轮不批准 Metal device-layer receipt / record / publication、native-handle readiness wrapper、device-ready permission wrapper、layer-ready permission wrapper、backend implementation wrapper、GPU-submission wrapper、render-permission wrapper 或 public API / C ABI expansion。

若未来靠近 no-draw backend shell、command queue / drawable real lifecycle、real Metal device-layer implementation、Objective-C / Metal / AppKit / FFI bridge、GPU submission、render execution 或 renderer state write，必须先做 docs-only preflight，不能直接实现。

## Stop-line

继续禁止：

- no `.cj` modifications in this docs-only round。
- no `MTLDevice` creation。
- no `CAMetalLayer` creation。
- no platform object creation。
- no native handle。
- no raw pointer。
- no Objective-C / Metal / AppKit / FFI API call。
- no bridge / smoke / harness / native entry modification。
- no command queue creation。
- no drawable acquisition。
- no command buffer creation or commit。
- no drawable present。
- no GPU submission。
- no render pass / encoder / pipeline state creation。
- no render execution。
- no renderer state write。
- no diagnostics / telemetry / observer / event bus。
- no public API。
- no public C ABI expansion。

## Unique Next Opening

`P1 internal Renderer Metal device-layer owner manifest stabilization bundle implementation`

下一轮必须 docs-only，固定 owner / truth / canonical endpoint / stop-line，并继续保持 no-device / no-layer / no-platform-object / no-native-handle / no-render boundary。

## Downstream Manifest Stabilization

Renderer Metal device-layer owner manifest stabilization 已完成：

- [2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)
- [2026-05-04-p1-internal-renderer-metal-device-layer-owner-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-metal-device-layer-owner-manifest-stabilization-closure-review.md)

该 manifest 封账 `CjguiInternalRendererNoMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()`，并明确拒绝 Metal device-layer receipt / record / publication、native-handle readiness wrapper、device-ready permission wrapper、layer-ready permission wrapper、backend implementation wrapper、GPU-submission wrapper 与 render-permission wrapper。

唯一 next opening：

`P1 internal Renderer no-draw backend shell preflight decision`
