# P1 Renderer platform resource owner preflight decision

日期：2026-05-03

状态：docs-only preflight decision

## Purpose

本 preflight 基于 backend-readiness preflight 与 backend / Metal reference pack，评估是否可以打开 platform resource owner runway。

本轮只做 decision，不批准 platform resource implementation，不创建 `MTLDevice` / `CAMetalLayer` / command queue / drawable / command buffer，不修改 `.cj`，不运行 build / smoke。

Upstream references：

- [2026-05-03-p1-renderer-backend-readiness-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-readiness-preflight-decision.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [2026-05-03-p1-renderer-packet-owner-truth-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-packet-owner-truth-milestone-manifest.md)
- [2026-05-03-p1-renderer-command-packet-ordering-material-grouping-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-packet-ordering-material-grouping-manifest.md)

## Current Packet Anchor

Current canonical packet truth 仍是：

- `CjguiInternalRendererPacketOrderingHardeningResult`
- `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`

当前没有 runtime backend-readiness owner，因此下一条 runtime value boundary 若打开，只能把 `CjguiInternalRendererPacketOrderingHardeningResult` 作为 no-render packet anchor。

Reference pack / backend-readiness preflight 只能作为 docs constraints，不应变成 runtime input type。旧 `CjguiInternalRendererPacketHandoffReceipt` 也不得复用。

为避免 packet thin wrapper，下一轮 runtime owner 必须新增 platform resource ownership / confinement / no-platform-resource 语义，而不是复制 ordering hardening result。

## Reference Evidence

Reference pack 支撑 platform resource owner runway 的 evidence：

- `MTLDevice` 是创建 command queue / buffers / textures 等 device-specific objects 的根，必须由 future backend / platform owner 管理。
- `MTLCommandQueue` 创建 command buffers 并组织 command buffer execution order，不能污染 Action / Queue / Runtime lower-level mutable facts。
- `MTLCommandBuffer` 是 per-frame / per-submit backend object，commit 后不可复用，不能进入 core packet。
- `CAMetalLayer` 拥有 drawable pool，`nextDrawable()` 可等待、失败或返回 `nil`，drawable acquisition 必须 late-bound。
- `CAMetalDrawable` / drawable texture 是临时 borrowed render target，不能成为 stable renderer packet state。
- AppKit `NSView` / layer-backed / layer-hosting policy 属于 platform owner；只有 dehydrated resize / scale / color facts 可以跨边界。
- Frame pacing 可能来自 `MTKView` draw loop、AppKit display link、`CADisplayLink`、`CVDisplayLink`，不能由 packet readiness 推导。
- Retina scale / drawable size / color space / pixel format 可以成为 future dehydrated facts，但不能携带 AppKit / Core Animation / Metal objects。

这些 evidence 足以证明 platform resource owner 有独立语义，可以打开 value boundary runway。

## Decision

允许打开 platform resource owner runway，但下一步只能是 internal value boundary，不是真实平台资源。

下一阶段选择：

`P1 internal Renderer platform resource owner value boundary bundle implementation`

建议下一步 owner：

- `runtime/cjgui/src/runtime_renderer_platform_resource.cj`

该 owner 必须只表达 value facts，不创建或持有任何 platform resource。

## Runtime Input Decision

下一轮 runtime owner 的输入应只消费：

- `CjguiInternalRendererPacketOrderingHardeningResult`

理由：

- 当前没有 runtime backend-readiness result 可以消费。
- Reference pack / backend-readiness preflight 是 docs evidence，不是 runtime fact。
- 旧 `CjguiInternalRendererPacketHandoffReceipt` 是 legacy batching-packet tail，不能复用。
- 只消费 current packet anchor 可以保持 owner chain 清晰，但输出必须新增 platform resource semantics，避免 thin wrapper。

## Output Truth Shape

下一轮如果实现，只允许输出 internal value facts：

- platform resource owner intent。
- resource confinement policy。
- drawable acquisition policy。
- command queue ownership policy。
- no-platform-resource readiness。

这些 facts 必须明确：

- 当前没有 `MTLDevice`。
- 当前没有 `CAMetalLayer`。
- 当前没有 command queue。
- 当前没有 drawable。
- 当前没有 command buffer。
- 当前没有 render pass / render encoder。
- 当前没有 native handle / raw pointer。
- 当前没有 backend object。
- 当前没有 render permission。

## Resource Ownership Boundary

只能由 future backend owner 持有或临时借用的 resources：

- device / `MTLDevice`。
- layer / `CAMetalLayer`。
- command queue / `MTLCommandQueue`。
- drawable / `CAMetalDrawable`。
- drawable texture。
- command buffer / `MTLCommandBuffer`。
- render pass descriptor。
- render command encoder。

这些 resources 不得进入 core renderer packet、normalization、ordering、material grouping、Action、Queue、Runtime lower-level mutable facts 或 public surface。

## Dehydrated Facts Allowed Toward Core

可作为 future dehydrated facts 进入 core-adjacent value vocabulary 的内容：

- resize facts。
- backing scale / Retina scale facts。
- drawable size facts。
- color space facts。
- pixel format facts。
- frame pacing hint facts。
- display refresh classification facts。
- drawable availability classification facts。

这些 facts 只能是 value facts，不得携带 platform object、native handle、raw pointer、callback、display link object、drawable 或 command buffer。

## Never-in-core Objects

以下对象绝不能进入 core packet：

- `MTLDevice`。
- `CAMetalLayer`。
- `CAMetalDrawable`。
- drawable texture。
- `MTLCommandQueue`。
- `MTLCommandBuffer`。
- render pass descriptor。
- render command encoder。
- `NSView`。
- `CALayer`。
- display link object。
- native handle。
- raw pointer。
- platform object。

## No-draw / Failure / Rollback Path

No-draw / failure / rollback path 应以 value facts 表达：

- drawable unavailable。
- drawable acquisition timed out。
- layer not ready。
- scale / color / size facts incomplete。
- command queue unavailable。
- resource confinement blocked。
- platform owner absent。
- backend execution intentionally not opened。
- no command buffer created。
- no render submitted。

这些 facts 不抛异常，不写日志，不回调 observer，不发布事件，不创建 backend object，不触发 render execution。

## Candidate Comparison

### A. P1 internal Renderer platform resource owner value boundary bundle implementation

选择。

理由：

- Reference pack 与 backend-readiness preflight 已证明 platform resource owner 有独立 resource ownership / confinement / no-platform-resource 语义。
- 下一轮可以只消费 `CjguiInternalRendererPacketOrderingHardeningResult`，输出 platform resource owner intent / confinement / drawable acquisition / command queue ownership / no-platform-resource readiness value facts。
- 它仍不创建 `MTLDevice` / `CAMetalLayer` / command queue / drawable / command buffer。

### B. P1 internal Renderer platform resource ownership reference hardening docs bundle implementation

暂缓。

当前 reference pack 已足够支持 value boundary。若后续发现官方链接、resource ownership 或 no-draw evidence 不足，再开 docs hardening。

### C. Command queue lifecycle preflight

暂缓。

通常应等 platform resource owner truth 落地后，再拆 command queue lifecycle。

### D. Drawable acquisition preflight

暂缓。

通常应等 platform resource owner truth 落地后，再拆 drawable acquisition。

### E. Backend-readiness value boundary

暂缓。

上一轮已明确先拆 platform owner，避免 backend-readiness wrapper。

### F. Backend / Metal implementation

拒绝。

### G. Command buffer / render execution / renderer state write

拒绝。

### H. Metal / AppKit / platform resource / native handle implementation

拒绝。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### J. Public surface expansion

拒绝。

### K. Receipt / record / publication

拒绝。

不得新增 platform resource receipt / record / publication，也不得把 reference pack 或 packet anchor 包成 platform readiness wrapper。

### L. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮通过 preflight 生效：

- 证明 platform resource owner 有新增 resource ownership / confinement / no-platform-resource 语义。
- 不把 `CjguiInternalRendererPacketOrderingHardeningResult` 直接包成 platform readiness wrapper。
- 不把 reference pack 变成 runtime readiness wrapper。
- 不复用旧 `runtime_renderer_handoff.cj` handoff receipt。
- 不新增 receipt / record / publication。

若下一轮选择 value boundary，必须继续禁止 `MTLDevice` / `CAMetalLayer` / command queue / drawable / command buffer implementation。

## Stop-line

继续禁止：

- no runtime code in this preflight round。
- no `.cj` modifications。
- no backend / Metal / AppKit implementation。
- no platform resource implementation。
- no `MTLDevice` / `CAMetalLayer` / command queue / drawable / command buffer creation。
- no native handle / raw pointer / platform object。
- no command buffer submission。
- no render pass / render encoder creation。
- no render execution / draw call。
- no GPU batching / draw-call merge。
- no sorting side effect。
- no packet mutation。
- no renderer state write。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no public surface expansion。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。
- no smoke / harness / native bridge / entry modifications。

## Downstream Manifest Stabilization

Renderer platform resource owner manifest stabilization 已完成：

- [2026-05-03-p1-renderer-platform-resource-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-manifest.md)
- [2026-05-03-p1-internal-renderer-platform-resource-owner-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-platform-resource-owner-manifest-stabilization-closure-review.md)

该 downstream manifest 将本 preflight 中批准的 platform resource owner value boundary 收束为 no-platform-resource endpoint：`CjguiInternalRendererNoPlatformResourceReadiness` / `cjguiInternalExecuteDefaultRendererPlatformResourceOwnerDraft()`。下一步只做 command queue lifecycle docs-only preflight，不创建 command queue / drawable / command buffer / backend object。

## Next Opening

`P1 internal Renderer platform resource owner value boundary bundle implementation`

下一轮允许新增 internal-only runtime owner file，但必须保持 no-platform-resource / no-backend / no-render boundary。不得创建 `MTLDevice`、`CAMetalLayer`、command queue、drawable、command buffer、render pass、render encoder、native handle 或 raw pointer。

## Downstream Value Boundary Closure

Renderer platform resource owner value boundary 已完成：

- [2026-05-03-p1-internal-renderer-platform-resource-owner-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-platform-resource-owner-value-boundary-closure-review.md)

新增 owner：

- [runtime_renderer_platform_resource.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_platform_resource.cj)

Canonical endpoint：

- `CjguiInternalRendererNoPlatformResourceReadiness`
- `cjguiInternalExecuteDefaultRendererPlatformResourceOwnerDraft()`

该 boundary 只表达 platform resource owner intent / resource confinement policy / drawable acquisition policy / command queue ownership policy / no-platform-resource readiness value facts；不创建平台资源，不复用旧 handoff receipt，不接 backend / Metal / AppKit implementation，不写 renderer state，不触发 render execution。

最终 next opening 是 `P1 internal Renderer platform resource owner closure / next platform resource decision`。

## Downstream Next-boundary Decision

Renderer platform resource owner next-boundary decision 已完成：

- [2026-05-03-p1-renderer-platform-resource-owner-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-next-boundary-decision.md)

该 decision 判定 no-platform-resource endpoint 已足够，下一步应先做 `P1 internal Renderer platform resource owner manifest stabilization bundle implementation`，不得把 endpoint 包成 receipt / record / publication 或 backend-readiness wrapper。
