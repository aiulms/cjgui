# P1 Renderer drawable acquisition lifecycle manifest

日期：2026-05-03

状态：manifest stabilization

## Purpose

本 manifest 固定 `runtime_renderer_drawable_acquisition.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-drawable lifecycle endpoint。

它不是 drawable acquisition implementation manifest，也不是 backend-readiness manifest。它只记录 drawable lifecycle intent、drawable availability policy、acquisition timing guard、presentation ownership policy 与 no-drawable readiness 的 internal value facts。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_acquisition.cj`

Canonical upstream endpoint：

- `CjguiInternalRendererNoCommandQueueReadiness`
- `cjguiInternalExecuteDefaultRendererCommandQueueLifecycleDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoDrawableReadiness`
- `cjguiInternalExecuteDefaultRendererDrawableAcquisitionDraft()`

Current truth：

- drawable lifecycle intent value facts。
- drawable availability policy value facts。
- acquisition timing guard value facts。
- presentation ownership policy value facts。
- no-drawable readiness value facts。

## Current Pipeline

当前 drawable acquisition lifecycle value pipeline：

1. `CjguiInternalRendererNoCommandQueueReadiness`
2. `CjguiInternalRendererDrawableLifecycleIntent`
3. `CjguiInternalRendererDrawableAvailabilityPolicy`
4. `CjguiInternalRendererDrawableAcquisitionTimingGuard`
5. `CjguiInternalRendererPresentationOwnershipPolicy`
6. `CjguiInternalRendererNoDrawableReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererDrawableAcquisitionDraft()`
- 只调用 `cjguiInternalExecuteDefaultRendererCommandQueueLifecycleDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不接 backend / Metal / AppKit implementation。
- 不获取 drawable。
- 不创建 `CAMetalLayer` / `CAMetalDrawable` / `MTLDrawable`。
- 不创建 command buffer / render pass / encoder。
- 不执行 render。
- 不写 renderer state。

## Value Semantics

`CjguiInternalRendererDrawableLifecycleIntent` 只表达 future drawable lifecycle intent，不是 drawable acquisition implementation。

`CjguiInternalRendererDrawableAvailabilityPolicy` 只表达 future drawable availability / unavailable / failure facts；它不调用或持有 drawable。

`CjguiInternalRendererDrawableAcquisitionTimingGuard` 只表达 future acquisition timing constraints；它不获取 drawable，不阻塞平台调用，不调度 frame callback。

`CjguiInternalRendererPresentationOwnershipPolicy` 只表达 future presentation ownership facts；它不 present drawable，不创建 command buffer、render pass 或 encoder。

`CjguiInternalRendererNoDrawableReadiness` 是当前 no-drawable lifecycle endpoint。Readiness 只表示该 internal value boundary 可以继续评估，不代表任何 side effect permission。

## Relationship Facts

Drawable acquisition 与 command queue / layer / frame pacing / resize 的关系只能作为 dehydrated lifecycle facts 表达：

- drawable availability phase。
- acquisition timing。
- resize / scale / color relation。
- frame pacing relationship。
- presentation ownership。
- failure / unavailable / no-draw fallback。
- rollback / release expectation as value facts only。

这些 facts 不能携带 `CAMetalLayer`、`CAMetalDrawable`、`MTLDrawable`、drawable texture、command buffer、render pass、encoder、native handle、raw pointer、platform object、callback 或 backend-local resource token。

## Explicit Non-Truth

`CjguiInternalRendererNoDrawableReadiness` 明确不是：

- drawable permission。
- drawable acquisition。
- drawable texture exposure。
- layer ownership。
- backend readiness。
- backend object readiness。
- platform object readiness。
- command buffer permission。
- render pass / encoder permission。
- render permission。
- renderer state write。
- Metal / AppKit implementation。
- `CAMetalLayer` / `CAMetalDrawable` / `MTLDrawable` ownership。
- native handle / raw pointer surface。
- command buffer lifecycle owner。
- render pass lifecycle owner。
- render execution gate。
- draw call。
- GPU batching。
- public API / public C ABI。

当前没有 `CAMetalLayer`、`CAMetalDrawable`、`MTLDrawable`、command buffer、render pass、encoder、native handle 或 raw pointer。当前没有 backend implementation、render execution 或 renderer state write。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 manifest 生效。

本轮选择 manifest 封账，明确拒绝：

- drawable receipt / record / publication。
- backend-readiness wrapper。
- command buffer readiness wrapper。
- render pass readiness wrapper。
- drawable permission wrapper。

`CjguiInternalRendererNoDrawableReadiness` 已经是当前 no-drawable lifecycle endpoint。继续新增 receipt / record / publication 或 readiness wrapper 会把同一结果换名包装，缺少新的 owner truth、consumer、lifecycle 或 platform evidence。

若未来靠近 command buffer / render pass / platform lifecycle，必须先做 docs-only preflight，并引用 [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 的具体 evidence。

## Stop-line

继续禁止：

- no runtime code in this manifest round。
- no `.cj` modifications。
- no drawable acquisition。
- no backend / Metal / AppKit implementation。
- no platform resource implementation。
- no `CAMetalLayer` / `CAMetalDrawable` / `MTLDrawable` creation。
- no command queue creation。
- no command buffer creation or submission。
- no render pass / render encoder creation。
- no render execution / draw call。
- no GPU batching / draw-call merge。
- no sorting side effect。
- no packet mutation。
- no renderer state write。
- no native handle / raw pointer / platform object。
- no backend-readiness wrapper。
- no command buffer readiness wrapper。
- no render pass readiness wrapper。
- no drawable receipt / record / publication。
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

### A. P1 internal Renderer command buffer lifecycle preflight decision

推荐为下一阶段 opening。

理由：

- drawable acquisition lifecycle endpoint 已封账后，下一步若继续靠近 backend lifecycle，应先 docs-only 评估 command buffer owner / lifecycle / readiness runway。
- Command buffer lifecycle 必须仍保持 no-command-buffer / no-render / no-platform-object 边界。
- 该 preflight 不创建 command buffer，不创建 render pass / encoder，不提交 GPU work，不接 backend implementation。

### B. P1 internal Renderer render pass lifecycle preflight decision

暂缓。

Render pass lifecycle 通常应等 command buffer lifecycle preflight 后再开。它更靠近 render pass descriptor、encoder 与 draw calls。

### C. Drawable lifecycle hardening

暂缓。

只有发现 availability / timing / presentation ownership 表达不足时才选。当前 manifest 未发现硬化缺口。

### D. Backend-readiness preflight revisit

暂缓。

Backend-readiness 仍太容易变成 wrapper。等 command buffer / render pass lifecycle 进一步拆清后再评估。

### E. Drawable / Metal implementation

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

本 manifest 固定 `runtime_renderer_drawable_acquisition.cj` owner / truth / canonical endpoint / stop-line，并封账 no-drawable lifecycle endpoint。

唯一 next opening：

`P1 internal Renderer command buffer lifecycle preflight decision`

下一轮必须 docs-only，不得创建 command buffer，不得创建 render pass / encoder，不得获取 drawable，不得接 backend / Metal / AppKit implementation，不得 render，不得写 renderer state。

## Downstream Command Buffer Lifecycle Preflight

Renderer command buffer lifecycle preflight 已完成：

- [2026-05-03-p1-renderer-command-buffer-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-preflight-decision.md)

该 preflight 判定可以打开 command buffer lifecycle runway，但下一步仍只能是 internal value boundary，不是真实 command buffer。若下一轮实现，建议 owner 是 `runtime/cjgui/src/runtime_renderer_command_buffer.cj`，只消费 `CjguiInternalRendererNoDrawableReadiness`，只输出 command buffer lifecycle intent / buffer creation policy / commit timing guard / single-use policy / no-command-buffer readiness value facts。

Same-shape Boundary Brake 继续生效：不得把 no-drawable endpoint 包成 command buffer receipt / record / publication、backend-readiness wrapper、render pass readiness wrapper 或 encoder readiness wrapper；不得创建或引用 `MTLCommandBuffer`、`MTLCommandQueue`、`CAMetalLayer`、drawable、render pass、encoder、native handle 或 raw pointer，不得实现 backend / Metal / AppKit、render execution 或 renderer state write。

## Downstream Command Buffer Lifecycle Value Boundary

Renderer command buffer lifecycle value boundary 已完成：

- [2026-05-03-p1-internal-renderer-command-buffer-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-buffer-lifecycle-value-boundary-closure-review.md)

该 boundary 新增 `runtime/cjgui/src/runtime_renderer_command_buffer.cj`，只消费 `CjguiInternalRendererNoDrawableReadiness`，canonical endpoint 是 `CjguiInternalRendererNoCommandBufferReadiness` / `cjguiInternalExecuteDefaultRendererCommandBufferLifecycleDraft()`。

它不创建 command buffer，不创建或引用 `MTLCommandBuffer` / `MTLCommandQueue`、drawable、render pass、encoder、native resource token 或 pointer-like resource，不实现 backend / Metal / AppKit、render execution 或 renderer state write。下一步唯一 opening 是 docs-only `P1 internal Renderer command buffer lifecycle closure / next command buffer decision`。

## Downstream Command Buffer Lifecycle Next-Boundary Decision

Renderer command buffer lifecycle next-boundary decision 已完成：

- [2026-05-03-p1-renderer-command-buffer-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoCommandBufferReadiness` 已足够作为当前 no-command-buffer lifecycle endpoint。下一步先做 docs-only command buffer lifecycle manifest stabilization；render pass lifecycle preflight 暂缓到 manifest 后再评估。

## Downstream Command Buffer Lifecycle Manifest

Renderer command buffer lifecycle manifest stabilization 已完成：

- [2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-command-buffer-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-buffer-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 固定 `CjguiInternalRendererNoCommandBufferReadiness` / `cjguiInternalExecuteDefaultRendererCommandBufferLifecycleDraft()` 为 current no-command-buffer lifecycle endpoint。下一步可进入 docs-only render pass lifecycle preflight，但不得直接创建 render pass、encoder、command buffer、backend object、platform object、render execution 或 renderer state write。

## Downstream Render Pass Lifecycle Preflight

Renderer render pass lifecycle preflight 已完成：

- [2026-05-03-p1-renderer-render-pass-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-preflight-decision.md)

该 preflight 只把 drawable-size / color-space / resize relation 作为脱水 lifecycle facts 引入 render pass runway；不获取 drawable，不暴露 drawable texture，不创建 render pass descriptor / encoder / attachment object。下一步若实现，也只能从 `CjguiInternalRendererNoCommandBufferReadiness` 形成 render pass lifecycle intent / attachment policy / load-store policy / clear-color policy / no-render-pass readiness value facts。

Same-shape Boundary Brake 继续生效：不得把 no-drawable 或 no-command-buffer endpoint 包成 render pass receipt / record / publication、backend-readiness wrapper 或 encoder readiness wrapper。
