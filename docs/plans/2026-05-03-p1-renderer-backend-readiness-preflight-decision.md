# P1 Renderer backend-readiness preflight decision

日期：2026-05-03

状态：docs-only preflight decision

## Purpose

本 preflight 基于 Renderer backend / Metal reference pack，评估是否可以打开 backend-readiness runway。

本轮只做 decision，不批准 backend implementation，不创建 platform resource owner，不新建 runtime owner，不修改 `.cj`，不运行 build / smoke。

Upstream references：

- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [2026-05-03-p1-internal-renderer-backend-metal-reference-pack-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-backend-metal-reference-pack-closure-review.md)
- [2026-05-03-p1-renderer-packet-owner-truth-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-packet-owner-truth-milestone-manifest.md)
- [2026-05-03-p1-renderer-packet-integration-owner-truth-preflight-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-packet-integration-owner-truth-preflight-manifest.md)
- [2026-05-03-p1-renderer-command-packet-ordering-material-grouping-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-packet-ordering-material-grouping-manifest.md)

## Current Upstream Truth

Current canonical packet truth 仍是：

- `CjguiInternalRendererPacketOrderingHardeningResult`
- `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`

该 endpoint 只表达 ordering basis / material grouping scope / hint preservation policy / no-sort-no-merge gate / hardening result value facts。

它不是：

- backend packet。
- backend readiness。
- platform resource owner。
- command buffer readiness。
- render pass readiness。
- renderer state write permission。
- render permission。
- stable backend API promise。

旧 `CjguiInternalRendererPacketHandoffReceipt` 属于 batching-packet handoff / backend no-render legacy tail，不得复用为 post-normalization backend-readiness evidence。

## Reference Pack Evidence

Reference pack 支撑 backend-readiness preflight 的 evidence：

- Metal command buffer lifecycle：`MTLDevice` 创建 command queue / resources，`MTLCommandQueue` 创建 command buffers，`MTLCommandBuffer` 承载 encoded commands，commit 后不可复用。
- Metal render command encoder / render pass lifecycle：render pass descriptor / render encoder / attachments / pipeline state / draw calls 都属于 backend-local execution vocabulary，不是 packet truth。
- `CAMetalLayer` drawable lifecycle：drawable pool 由 Core Animation 管理，`nextDrawable()` 可能等待、失败或返回 `nil`，drawable 应 late-bound 并 quickly released。
- AppKit layer-backed lifecycle：`NSView` / backing layer / layer-hosting policy 属于 platform owner，只有 dehydrated size / scale / color facts 可以跨边界。
- Frame pacing：`MTKView` draw loop、AppKit display link、`CADisplayLink`、`CVDisplayLink` 都是 platform / backend pacing evidence，不能由 packet readiness 推出。
- Retina scale / color：backing scale、drawable size、pixel format、color space 必须作为 dehydrated facts 进入 future owner，而不能携带 AppKit / Core Animation / Metal objects。
- Resource ownership：`MTLDevice` / layer / command queue / drawable / render pass / command buffer 都必须由 future backend / platform owner 约束；core packet 不能持有 native handle / raw pointer。

这些 evidence 足以说明 backend-readiness 需要独立 owner / policy / resource ownership 语义，不能直接由 ordering hardening result 推导。

## Current Evidence Gaps

当前不批准 backend-readiness value boundary implementation，因为仍缺：

- platform resource owner truth：谁拥有 `MTLDevice` / `CAMetalLayer` / command queue / drawable / command buffer。
- platform resource confinement：资源如何保证不进入 core packet。
- command queue lifecycle：何时创建、谁持有、何时释放、如何不读取 Queue / Action / Runtime lower-level mutable facts。
- drawable acquisition policy：`nextDrawable()` 在何处发生，如何 late-bound，如何表达 timeout / unavailable / `nil`。
- no-draw failure path：drawable unavailable、scale/color invalid、resource unavailable、command setup blocked 时如何 fail-closed。
- scale / color / resize dehydration：AppKit / layer-backed / backing scale / drawable size / color space 如何成为 value facts。
- frame pacing owner：AppKit display link、MTKView draw loop、scheduler owner、backend owner或独立 pacing owner谁负责。
- resource lifetime / retention：command buffer completion 前 drawable / texture / buffer 的 retention policy。

因此，本轮允许打开 backend-readiness 讨论 runway，但不批准下一刀直接新建 `runtime_renderer_backend_readiness.cj`。

## Backend-readiness Boundary Shape If Reopened Later

如果未来 evidence 足够，候选 owner 可以是：

- `runtime/cjgui/src/runtime_renderer_backend_readiness.cj`

但它必须满足：

- 只消费 `CjguiInternalRendererPacketOrderingHardeningResult`，或消费经过明确 owner-truth preflight 批准的 packet endpoint。
- 不复用 `CjguiInternalRendererPacketHandoffReceipt`。
- 输出 truth 只能是 backend readiness intent / platform boundary policy / resource ownership preflight / no-command-buffer readiness / no-render readiness value facts。
- 不持有 `MTLDevice` / `CAMetalLayer` / command queue / drawable / command buffer / native handle / raw pointer。
- 不创建 backend object。
- 不提交 command buffer。
- 不 render，不 draw call，不 GPU batching，不 renderer state write。

## Decision

本轮不批准 `P1 internal Renderer backend-readiness value boundary bundle implementation`。

选择下一阶段：

`P1 internal Renderer platform resource owner preflight decision`

理由：

- Reference pack 已经证明 backend-readiness 有新增语义空间，但核心缺口先在 platform resource owner。
- 如果不先固定 platform resource owner truth，backend-readiness value boundary 很容易把 `CjguiInternalRendererPacketOrderingHardeningResult` 包成 readiness thin wrapper。
- Platform resource owner preflight 仍是 docs-only，可以先回答 resource owner / confinement / lifecycle / no-draw gate，而不创建 `MTLDevice`、`CAMetalLayer`、command queue、command buffer 或 native handle。

## Candidate Comparison

### A. P1 internal Renderer backend-readiness value boundary bundle implementation

暂缓，不选择。

Reference pack 支撑 backend-readiness 需要独立语义，但当前 owner / gate / resource ownership evidence 仍不足。若现在直接实现，风险是把 ordering hardening result 包成 backend-readiness wrapper。

### B. P1 internal Renderer platform resource owner preflight decision

选择。

先 docs-only 拆 platform resource owner，可以回答：

- 谁拥有 `MTLDevice` / `CAMetalLayer` / command queue / drawable / command buffer。
- platform resources 如何限制在 backend owner 内。
- drawable acquisition 与 no-draw path 如何表达。
- scale / color / resize facts 如何 dehydrated。

它仍不实现 backend，不创建 platform resource，不写 runtime code。

### C. P1 internal Renderer command buffer lifecycle preflight decision

暂缓。

Command buffer lifecycle 应等 platform resource owner preflight 后再拆；否则会过早靠近 command buffer creation / submission / completion callback。

### D. P1 internal Renderer backend-readiness reference hardening docs bundle implementation

暂缓。

当前 reference pack 已足够支持 platform resource owner preflight。若后续发现 Apple 官方链接或 evidence coverage 不足，再开 hardening docs。

### E. Backend / Metal implementation

拒绝。

### F. Command buffer / render execution / renderer state write

拒绝。

### G. Metal / AppKit / platform resource / native handle implementation

拒绝。

### H. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

P1 仍是 full DisplayList / command list rebuild；UI system 与 incremental render 需要独立 owner truth。

### I. Public surface expansion

拒绝。

public allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

### J. Packet integration runtime boundary

拒绝。

Packet integration owner-truth manifest 已确认 downstream owner / consumer / gate / integration evidence 不足。

### K. Receipt / record / publication

拒绝。

不得新增 backend readiness receipt / record / publication，也不得把 packet truth 包成 readiness wrapper。

### L. Consolidation

暂缓。

只有发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前主要缺口是 platform resource owner truth。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮通过 preflight 生效：

- 不把 `CjguiInternalRendererPacketOrderingHardeningResult` 直接包成 backend-readiness wrapper。
- 不复用旧 `runtime_renderer_handoff.cj` 的 batching-packet receipt。
- 不新增 backend readiness receipt / record / publication。
- 不新增 `runtime_renderer_backend_readiness.cj`。

Backend-readiness 有新增语义空间，但 platform resource owner evidence 不足，因此下一步优先选择 platform resource owner preflight，而不是 runtime value boundary。

## Stop-line

继续禁止：

- no runtime code。
- no `.cj` modifications。
- no backend / Metal / AppKit implementation。
- no `MTLDevice` / `CAMetalLayer` / native handle / raw pointer in core packet。
- no platform resource owner implementation。
- no command queue / command buffer creation。
- no render pass / render encoder creation。
- no command buffer submission。
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

## Next Opening

`P1 internal Renderer platform resource owner preflight decision`

下一轮仍必须 docs-only，基于 reference pack 和本 preflight，评估 platform resource owner / confinement / lifecycle / no-draw path 是否可以成为下一条 value-style runway；不得实现 backend、Metal / AppKit、CAMetalLayer、MTLDevice、command queue、command buffer、render execution、renderer state write 或 public surface expansion。

## Downstream Platform Resource Owner Preflight

Renderer platform resource owner preflight 已完成：

- [2026-05-03-p1-renderer-platform-resource-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-preflight-decision.md)

该 preflight 判定 platform resource owner 有足够新增 resource ownership / confinement / no-platform-resource 语义，可以进入 `P1 internal Renderer platform resource owner value boundary bundle implementation`。

下一步若实现，候选 owner 是 `runtime/cjgui/src/runtime_renderer_platform_resource.cj` 或等价 internal-only owner，只消费 `CjguiInternalRendererPacketOrderingHardeningResult`，输出 platform resource owner intent / resource confinement policy / drawable acquisition policy / command queue ownership policy / no-platform-resource readiness value facts；仍不创建 `MTLDevice` / `CAMetalLayer` / command queue / drawable / command buffer / render pass / render encoder，不接 native handle / raw pointer，不 render，不写 renderer state，不扩 public surface。
