# P1 Renderer Metal device-layer owner preflight decision

日期：2026-05-04

状态：docs-only preflight decision

## Scope

本轮评估是否可以打开 Metal device-layer owner runway。

本轮 docs-only：不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER，不创建 `MTLDevice` / `CAMetalLayer`，不创建 command queue / drawable / command buffer / render pass / encoder / pipeline state，不创建 platform object / native handle / raw pointer，不 commit / present / submit GPU work，不写 renderer state，不接 public API / C ABI。

## Inputs Read

- [2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [2026-05-04-p1-internal-renderer-backend-platform-object-owner-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-platform-object-owner-manifest-stabilization-closure-review.md)
- [2026-05-04-p1-renderer-backend-platform-object-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-preflight-decision.md)
- [2026-05-04-p1-renderer-real-backend-first-slice-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-real-backend-first-slice-owner-preflight-decision.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [2026-05-03-p1-renderer-platform-resource-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-manifest.md)
- [2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md)
- [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)

## Decision

允许打开 Metal device-layer owner runway。

下一步选择：

`P1 internal Renderer Metal device-layer owner value boundary bundle implementation`

下一步仍只能是 internal value boundary，不是真实 `MTLDevice` / `CAMetalLayer` creation。它不得创建 device / layer / command queue / drawable / command buffer / render pass / encoder / pipeline state，不得创建 platform object、native handle 或 raw pointer，不得调用 FFI / Objective-C / Metal API，不得修改 bridge、smoke、harness 或 native entry，不得 GPU submission、render execution、renderer state write、public API 或 C ABI expansion。

## Proposed Runtime Boundary

默认候选 owner：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer.cj`

建议唯一 runtime input：

- `CjguiInternalRendererNoPlatformObjectReadiness`
- `cjguiInternalExecuteDefaultRendererBackendPlatformObjectOwnerDraft()`

Docs evidence 可以引用 backend / Metal reference pack、bridge preflight / cleanup closure、platform resource owner manifest、backend platform object owner manifest 和 risk ledger，但不得作为多 runtime input，也不得把 lab smoke 的 Objective-C implementation 升格为 runtime truth。

允许 output truth 仅限：

- Metal device-layer owner intent value facts。
- device selection policy value facts。
- layer binding policy value facts。
- scale-color-space policy value facts。
- no-metal-device-layer-readiness value facts。

## Required Boundary Truth

下一轮 value boundary 必须明确：

- Metal device-layer owner 不等于真实 `MTLDevice`。
- Metal device-layer owner 不等于真实 `CAMetalLayer`。
- Metal device-layer owner 不等于 backend implementation。
- Device selection policy 只表达 future device selection / capability / no-device fallback facts，不调用 `MTLCreateSystemDefaultDevice()` 或任何 Metal API。
- Layer binding policy 只表达 future layer binding / layer-hosting relation facts，不创建、持有、绑定或配置 `CAMetalLayer`。
- Scale-color-space policy 只表达 future drawable size / backing scale / pixel format / color space value facts，不读取 `NSView` / `NSWindow` / `NSScreen` 或 platform layer。
- No-metal-device-layer readiness 不是 device permission、layer permission、platform object permission、native handle permission、backend implementation permission、render permission、GPU submission permission 或 renderer state write permission。
- Default draft 只消费 no-platform-object endpoint，并 fail closed on blocked / inconsistent input。

## Reference Evidence

Evidence 足够选择 A：

- Backend platform object owner manifest 已封账 `CjguiInternalRendererNoPlatformObjectReadiness`，并固定 native resource ownership / teardown / confinement vocabulary。Device-layer owner 可以在该 no-platform-object endpoint 之后表达更具体的 device / layer facts。
- Backend / Metal reference pack 固定 `MTLDevice` 是 GPU interface 和 command queue / buffer / texture 等 device-specific object 的根，`CAMetalLayer` 管理 drawable pool，并配置 device、pixel format、color space、drawable size、presentation behavior 和 display sync。
- Reference pack 同时固定 drawable acquisition must be late-bound / backend-local，resize / backing scale / drawable size / color space 只能作为 dehydrated facts 过界。
- Platform resource owner manifest 已允许 device / layer 作为 future policy targets 命名，但仍禁止 `MTLDevice` / `CAMetalLayer` / native handle / raw pointer 进入 core packet。
- AppKit / Metal bridge preflight 记录了 bridge 层负责创建和持有 Metal device / command queue / `CAMetalLayer` 的 smoke reality，也记录了 handle lifecycle、main-thread owner、capability query、teardown ordering 和 narrow bridge shape；这些可作为 docs evidence，不是 runtime truth。
- Bridge cleanup closure 证明 lab bridge 内部持有并清理 `NSWindow`、Metal view、`CAMetalLayer`、`MTLDevice`、command queue 可行，但也明确没有正式 GUI runtime、handle table、generation table、message queue 或 long-term ABI。
- Risk ledger 明确 GPU resource lifecycle、FFI ownership、main-thread exclusivity、runloop overfitting、pixel hash illusion 和 foreign surface containment 是后续 implementation 风险。

Evidence 不足以直接实现：

- 还没有 runtime Metal device-layer owner。
- 还没有正式 platform object / native handle representation。
- 还没有 bridge ownership ABI 或 handle table / generation table。
- 还没有 device selection failure taxonomy 的 runtime shape。
- 还没有 layer binding / resize / scale / color update owner truth。
- 还没有 command queue / drawable real lifecycle owner。
- `labs/macos_bridge_smoke` 仍是 lab-only feasibility evidence，不能成为 runtime owner truth。

## Candidate Comparison

### A. P1 internal Renderer Metal device-layer owner value boundary bundle implementation

推荐。

Evidence 足以新增 internal-only value facts owner。该 boundary 的新增语义是 device selection / layer binding / scale-color-space / no-metal-device-layer-readiness，不是真实 `MTLDevice` / `CAMetalLayer` creation。

### B. No-draw backend shell preflight

暂缓。

No-draw backend shell 应晚于 device-layer owner manifest，或至少等 device / layer absence、no-device、no-layer、failure / no-draw facts 固定后再拆。否则 shell 容易变成 backend implementation wrapper 或 no-platform-object tail wrapper。

### C. Command queue / drawable real lifecycle preflight

暂缓。

Command queue / drawable real lifecycle 应晚于 device-layer owner vocabulary。当前没有 `MTLDevice` / `CAMetalLayer` permission，也没有 command queue / drawable real owner truth。

### D. Metal reference hardening docs

暂缓。

现有 backend / Metal reference pack、platform resource owner manifest、bridge preflight、bridge cleanup closure 和 risk ledger 足以支撑 value boundary。若下一轮实现发现 device selection / layer binding / scale-color-space evidence 表达不足，再选择 docs hardening。

### E. Direct `MTLDevice` / `CAMetalLayer` implementation

拒绝。

本轮不批准真实 device / layer creation。

### F. Direct Objective-C / Metal / AppKit bridge modification

拒绝。

不得修改 bridge、smoke、harness 或 native entry。

### G. Command queue / drawable / command buffer implementation

拒绝。

这些必须晚于 device-layer owner、command queue real lifecycle preflight 和 drawable real lifecycle preflight。

### H. GPU submission / render execution

拒绝。

Current branch 仍然 no-submit / no-render-execution。

### I. Renderer state write

拒绝。

Current branch 仍然 no-state-write。

### J. Public API / C ABI expansion

拒绝。

Public allowlist 不变；bridge smoke 的 experimental C ABI 不能升级为 runtime public surface。

### K. Receipt / record / publication / backend-ready permission wrapper

拒绝。

这些会把 no-platform-object endpoint 换名包装，缺少 device selection / layer binding / scale-color-space / no-metal-device-layer-readiness 新语义。

### L. Consolidation

暂缓。

仅在明确 duplicate / self-wrapping evidence 出现时选择。当前需要的是 device-layer owner value boundary，不是 consolidation。

## Same-shape Boundary Brake

本轮不能把 `CjguiInternalRendererNoPlatformObjectReadiness` 包成：

- Metal device-layer receipt / record / publication。
- native-handle readiness wrapper。
- device-ready permission wrapper。
- layer-ready permission wrapper。
- backend implementation wrapper。
- backend-ready permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。

若下一轮选择 A，必须证明新增的是 device selection / layer binding / scale-color-space / no-metal-device-layer-readiness 语义，而不是 no-platform-object tail wrapper。

## Future Stop-line

下一轮即使实现 value boundary，也继续禁止：

- no `MTLDevice` creation。
- no `CAMetalLayer` creation。
- no command queue creation。
- no drawable acquisition。
- no command buffer creation。
- no render pass creation。
- no encoder creation。
- no pipeline state creation。
- no platform object creation。
- no native handle。
- no raw pointer。
- no bridge / smoke / harness / native entry modification。
- no FFI / Objective-C / Metal API call。
- no command buffer commit。
- no drawable present。
- no GPU submission。
- no render execution。
- no renderer state write。
- no public API。
- no public C ABI expansion。
- no diagnostics output / telemetry / observer / event bus。

## Unique Next Opening

`P1 internal Renderer Metal device-layer owner value boundary bundle implementation`

下一轮允许新增 internal-only runtime owner file，但必须严格保持 no-device / no-layer / no-native-handle / no-render 边界。The owner should consume only `CjguiInternalRendererNoPlatformObjectReadiness` and emit only Metal device-layer owner intent / device selection policy / layer binding policy / scale-color-space policy / no-metal-device-layer-readiness value facts.

## Downstream Value Boundary Closure

Renderer Metal device-layer owner value boundary 已完成：

- [2026-05-04-p1-internal-renderer-metal-device-layer-owner-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-metal-device-layer-owner-value-boundary-closure-review.md)

该 implementation 新增 internal-only owner：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer.cj`

Canonical endpoint：

- `CjguiInternalRendererNoMetalDeviceLayerReadiness`
- `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()`

Runtime input 只消费 `CjguiInternalRendererNoPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererBackendPlatformObjectOwnerDraft()`。Output truth 仅限 Metal device-layer owner intent / device selection policy / layer binding policy / scale-color-space policy / no-metal-device-layer-readiness value facts。

Same-shape Boundary Brake 已在 source fields / comments / closure 中落实：该 owner 新增 device selection / layer binding / scale-color-space / no-metal-device-layer-readiness 语义，不把 no-platform-object endpoint 包成 Metal device-layer receipt / record / publication、native-handle readiness wrapper、device-ready permission wrapper、layer-ready permission wrapper、backend implementation wrapper 或 GPU-submission wrapper。

唯一 next opening：

`P1 internal Renderer Metal device-layer owner closure / next device-layer decision`

## Downstream Next-boundary Decision

Renderer Metal device-layer owner next-boundary decision 已完成：

- [2026-05-04-p1-renderer-metal-device-layer-owner-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()` 已足够作为当前 no-metal-device-layer endpoint，并选择 manifest stabilization，而不是 no-draw backend shell preflight、command queue / drawable real lifecycle preflight、Metal reference hardening 或任何真实 implementation。

Same-shape Boundary Brake 明确 `NoMetalDeviceLayerReadiness` 不再继续包装成 tail wrapper；当前 endpoint 只代表 Metal device-layer owner intent / device selection policy / layer binding policy / scale-color-space policy / no-metal-device-layer-readiness value facts，不是 `MTLDevice` permission、`CAMetalLayer` permission、platform object permission、native handle permission、backend implementation permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

唯一 next opening：

`P1 internal Renderer Metal device-layer owner manifest stabilization bundle implementation`

## Downstream Manifest Stabilization

Renderer Metal device-layer owner manifest stabilization 已完成：

- [2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)
- [2026-05-04-p1-internal-renderer-metal-device-layer-owner-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-metal-device-layer-owner-manifest-stabilization-closure-review.md)

该 manifest 固定 owner file、canonical endpoint、default draft、current truth 与 stop-line。`MetalDeviceSelectionPolicy` 不创建 `MTLDevice`；`MetalLayerBindingPolicy` 不创建 / 绑定 `CAMetalLayer`；`MetalScaleColorSpacePolicy` 不读取真实 display scale / color space，只表达 dehydrated policy facts；`NoMetalDeviceLayerReadiness` 不是 device / layer / platform object / native handle / backend implementation / GPU submission / render / renderer state write / public API permission。

唯一 next opening：

`P1 internal Renderer no-draw backend shell preflight decision`
