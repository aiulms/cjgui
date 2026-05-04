# P1 Renderer platform resource owner manifest

日期：2026-05-03

状态：manifest stabilization

## Purpose

本 manifest 固定 `runtime_renderer_platform_resource.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-platform-resource endpoint。

它不是 backend-readiness manifest，也不是 platform resource implementation manifest。它只记录 platform resource owner intent、resource confinement policy、drawable acquisition policy、command queue ownership policy 与 no-platform-resource readiness 的 internal value facts。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_platform_resource.cj`

Canonical upstream packet truth：

- `CjguiInternalRendererPacketOrderingHardeningResult`
- `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoPlatformResourceReadiness`
- `cjguiInternalExecuteDefaultRendererPlatformResourceOwnerDraft()`

Current truth：

- platform resource owner intent value facts。
- resource confinement policy value facts。
- drawable acquisition policy value facts。
- command queue ownership policy value facts。
- no-platform-resource readiness value facts。

## Current Pipeline

当前 platform resource owner value pipeline：

1. `CjguiInternalRendererPacketOrderingHardeningResult`
2. `CjguiInternalRendererPlatformResourceOwnerIntent`
3. `CjguiInternalRendererResourceConfinementPolicy`
4. `CjguiInternalRendererDrawableAcquisitionPolicy`
5. `CjguiInternalRendererCommandQueueOwnershipPolicy`
6. `CjguiInternalRendererNoPlatformResourceReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererPlatformResourceOwnerDraft()`
- 只调用 `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不接 backend / Metal / AppKit implementation。
- 不创建 platform resource。
- 不创建 command queue。
- 不获取 drawable。
- 不创建 command buffer / render pass / encoder。
- 不执行 render。
- 不写 renderer state。

## Resource Vocabulary

Future resources 在当前 manifest 中只能作为 policy targets 命名：

- device。
- layer。
- command queue。
- drawable。
- command buffer。
- render pass。
- encoder。

这些词只用于说明 future backend owner 的 resource confinement / ownership policy，不表示当前 runtime owner 创建、持有、借用或暴露任何平台对象。

## Allowed Dehydrated Facts

未来可以进入 core-adjacent value vocabulary 的 facts 只能是脱水事实：

- resize hints。
- scale / Retina backing scale hints。
- color / color space hints。
- frame pacing hints。

这些 facts 不能携带 platform object、native handle、raw pointer、drawable、command buffer、render pass、encoder、callback、display link object 或 backend-local resource token。

## Forbidden Core Packet Objects

以下对象不得进入 core packet、renderer packet、normalization、ordering、platform resource owner value facts、Action / Queue / Runtime lower-level mutable facts 或 public surface：

- `MTLDevice`。
- `CAMetalLayer`。
- native handle。
- raw pointer。
- drawable。
- command buffer。
- render pass。
- encoder。

本 manifest 允许在文档中用这些名字描述禁止项和 future policy targets，但不批准任何 import、type、field、function call、handle table 或 resource ownership。

## Explicit Non-Truth

`CjguiInternalRendererNoPlatformResourceReadiness` 明确不是：

- backend readiness。
- platform resource permission。
- command queue permission。
- drawable acquisition permission。
- command buffer permission。
- render permission。
- renderer state write。
- backend object readiness。
- Metal / AppKit implementation。
- `MTLDevice` / `CAMetalLayer` ownership。
- native handle / raw pointer surface。
- command queue lifecycle owner。
- drawable lifecycle owner。
- command buffer lifecycle owner。
- render pass / encoder lifecycle owner。
- render execution gate。
- draw call。
- GPU batching。
- public API / public C ABI。

当前没有 Metal / AppKit implementation，没有 backend object，没有 command buffer，没有 render execution。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 manifest 生效。

本轮选择 manifest 封账，明确拒绝：

- platform resource receipt / record / publication。
- backend-readiness wrapper。
- command queue readiness wrapper。
- drawable acquisition readiness wrapper。
- platform resource permission wrapper。

`CjguiInternalRendererNoPlatformResourceReadiness` 已经是当前 no-platform-resource endpoint。继续新增 receipt / record / publication 或 readiness wrapper 会把同一结果换名包装，缺少新的 owner truth、consumer、lifecycle 或 platform evidence。

若未来靠近 command queue / drawable / platform lifecycle，必须先做 docs-only preflight，并引用 [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 的具体 evidence。

## Stop-line

继续禁止：

- no runtime code in this manifest round。
- no `.cj` modifications。
- no backend / Metal / AppKit implementation。
- no platform resource implementation。
- no `MTLDevice` / `CAMetalLayer` creation。
- no command queue creation。
- no drawable acquisition。
- no command buffer creation or submission。
- no render pass / encoder creation。
- no render execution / draw call。
- no GPU batching / draw-call merge。
- no sorting side effect。
- no packet mutation。
- no renderer state write。
- no native handle / raw pointer / platform object。
- no backend-readiness wrapper。
- no command queue readiness wrapper。
- no drawable acquisition readiness wrapper。
- no receipt / record / publication。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no public surface expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。
- no smoke / harness / native bridge / entry modifications。

## Public Surface

public symbol allowlist 未变：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本 manifest 不批准第二个 public symbol、不修改 Bool-only signature、不新增 structured public return、不开放 public C ABI。

## Next Stage Candidate Comparison

### A. P1 internal Renderer command queue lifecycle preflight decision

推荐为下一阶段 opening。

理由：

- no-platform-resource endpoint 已封账后，下一步若继续接近平台 lifecycle，应先 docs-only 评估 command queue owner / lifecycle / readiness runway。
- 该 preflight 不创建 command queue，不创建 command buffer，不接 backend implementation。
- 该 preflight 必须继续证明新增 command queue owner / lifecycle / no-command-queue semantics，而不是把 no-platform-resource endpoint 包成 command queue readiness wrapper。

### B. P1 internal Renderer drawable acquisition lifecycle preflight decision

暂缓。

Drawable acquisition 通常依赖 command queue / backend owner lifecycle 与 layer / drawable timing evidence。应等 command queue lifecycle preflight 后再开。

### C. Platform resource owner hardening

暂缓。

只有发现 resource confinement / drawable acquisition policy / command queue ownership policy 表达不足时才选。当前 manifest 未发现硬化缺口。

### D. Backend-readiness preflight revisit

暂缓。

Backend-readiness 仍太容易变成 wrapper。等 command queue / drawable lifecycle 进一步拆清后再评估。

### E. Backend / Metal implementation

拒绝。

### F. Command buffer / render execution / renderer state write

拒绝。

### G. Metal / AppKit / platform resource / native handle implementation

拒绝。

### H. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### I. Public surface expansion

拒绝。

### J. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前没有这类 evidence。

## Decision

本 manifest 固定 `runtime_renderer_platform_resource.cj` owner / truth / canonical endpoint / stop-line，并封账 no-platform-resource endpoint。

唯一 next opening：

`P1 internal Renderer command queue lifecycle preflight decision`

下一轮必须 docs-only，不得创建 command queue，不得创建 backend object，不得接 Metal / AppKit / CAMetalLayer，不得创建 command buffer / render pass / encoder，不得 render，不得写 renderer state。

## Downstream Command Queue Lifecycle Preflight

Renderer command queue lifecycle preflight 已完成：

- [2026-05-03-p1-renderer-command-queue-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-preflight-decision.md)

该 preflight 选择 `P1 internal Renderer command queue lifecycle value boundary bundle implementation` 作为下一阶段 opening。若下一轮实现，owner 必须只消费 `CjguiInternalRendererNoPlatformResourceReadiness`，只输出 command queue lifecycle intent / queue ownership policy / queue creation guard / queue lifetime policy / no-command-queue readiness value facts；不得创建 `MTLCommandQueue`、`MTLDevice`、`CAMetalLayer`、drawable、command buffer、render pass、encoder、native handle 或 raw pointer。

## Downstream Command Queue Lifecycle Value Boundary

Renderer command queue lifecycle value boundary 已完成：

- [2026-05-03-p1-internal-renderer-command-queue-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-queue-lifecycle-value-boundary-closure-review.md)

新增 owner `runtime/cjgui/src/runtime_renderer_command_queue.cj` 只消费 `CjguiInternalRendererNoPlatformResourceReadiness`，canonical endpoint 是 `CjguiInternalRendererNoCommandQueueReadiness` / `cjguiInternalExecuteDefaultRendererCommandQueueLifecycleDraft()`。该 boundary 不创建 command queue、不创建平台对象、不接 backend / Metal / AppKit implementation、不创建 drawable / command buffer / render pass / encoder、不 render、不写 renderer state。

## Downstream Command Queue Lifecycle Next-boundary Decision

Renderer command queue lifecycle next-boundary decision 已完成：

- [2026-05-03-p1-renderer-command-queue-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-next-boundary-decision.md)

该 decision 选择先做 command queue lifecycle manifest stabilization，固定 `runtime_renderer_command_queue.cj` owner / truth / canonical endpoint / stop-line；drawable acquisition lifecycle 与 command buffer lifecycle 仍暂缓。

## Downstream Command Queue Lifecycle Manifest

Renderer command queue lifecycle manifest stabilization 已完成：

- [2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-command-queue-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-queue-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 固定 `CjguiInternalRendererNoCommandQueueReadiness` / `cjguiInternalExecuteDefaultRendererCommandQueueLifecycleDraft()` 为 no-command-queue lifecycle endpoint；下一阶段只允许 docs-only drawable acquisition lifecycle preflight，不直接获取 drawable。

## Downstream Drawable Acquisition Lifecycle Preflight

Renderer drawable acquisition lifecycle preflight 已完成：

- [2026-05-03-p1-renderer-drawable-acquisition-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-preflight-decision.md)

该 preflight 选择 `P1 internal Renderer drawable acquisition lifecycle value boundary bundle implementation` 作为下一阶段 opening。若下一轮实现，owner 必须只消费 `CjguiInternalRendererNoCommandQueueReadiness`，只输出 drawable acquisition lifecycle intent / drawable availability policy / acquisition timing guard / presentation ownership policy / no-drawable readiness value facts；不得获取 drawable，不得创建 `CAMetalLayer`、`CAMetalDrawable` / `MTLDrawable`、command buffer、render pass、encoder、native handle 或 raw pointer。
