# P1 Renderer render pass lifecycle manifest

日期：2026-05-03

状态：manifest stabilization

## Purpose

本 manifest 固定 `runtime_renderer_render_pass.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-render-pass lifecycle endpoint。

它不是 render pass implementation manifest，也不是 encoder-readiness manifest 或 backend-readiness manifest。它只记录 render pass lifecycle intent、attachment policy、load-store policy、clear-color policy 与 no-render-pass readiness 的 internal value facts。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_pass.cj`

Canonical upstream endpoint：

- `CjguiInternalRendererNoCommandBufferReadiness`
- `cjguiInternalExecuteDefaultRendererCommandBufferLifecycleDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoRenderPassReadiness`
- `cjguiInternalExecuteDefaultRendererRenderPassLifecycleDraft()`

Current truth：

- render pass lifecycle intent value facts。
- render pass attachment policy value facts。
- render pass load-store policy value facts。
- render pass clear-color policy value facts。
- no-render-pass readiness value facts。

## Current Pipeline

当前 render pass lifecycle value pipeline：

1. `CjguiInternalRendererNoCommandBufferReadiness`
2. `CjguiInternalRendererRenderPassLifecycleIntent`
3. `CjguiInternalRendererRenderPassAttachmentPolicy`
4. `CjguiInternalRendererRenderPassLoadStorePolicy`
5. `CjguiInternalRendererRenderPassClearColorPolicy`
6. `CjguiInternalRendererNoRenderPassReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererRenderPassLifecycleDraft()`
- 只调用 `cjguiInternalExecuteDefaultRendererCommandBufferLifecycleDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不接 backend / Metal / AppKit implementation。
- 不创建 render pass。
- 不创建 `MTLRenderPassDescriptor`。
- 不创建 `MTLRenderCommandEncoder`。
- 不创建 texture / attachment object。
- 不获取 drawable。
- 不创建 command buffer。
- 不执行 render。
- 不写 renderer state。

## Value Semantics

`CjguiInternalRendererRenderPassLifecycleIntent` 只表达 future render pass lifecycle intent，不是 render pass implementation、backend readiness、encoder readiness 或 render permission。

`CjguiInternalRendererRenderPassAttachmentPolicy` 只表达 future attachment role / target relation facts；它不创建 texture、attachment object、render pass descriptor、drawable、backend object 或 platform object。

`CjguiInternalRendererRenderPassLoadStorePolicy` 只表达 future load / store intent；它不操作 attachment，不 mutate descriptor，不 encode，不 present，不写 renderer state。

`CjguiInternalRendererRenderPassClearColorPolicy` 只表达 dehydrated clear-color facts；它不设置 platform descriptor，不进入 encoder lifecycle，不绑定 pipeline state，不触发 draw call。

`CjguiInternalRendererNoRenderPassReadiness` 是当前 no-render-pass lifecycle endpoint。Readiness 只表示该 internal value boundary 可以继续评估，不代表任何 side effect permission。

## Relationship Facts

Render pass 与 command buffer / drawable / color space / resize 的关系只能作为 dehydrated lifecycle facts 表达：

- command-buffer relation as value facts only。
- drawable-size relation。
- color-space relation。
- resize relation。
- attachment role / target relation。
- load / store intent。
- clear-color facts。
- failure / no-draw fallback。
- rollback expectation as value facts only。

这些 facts 不能携带 `MTLRenderPassDescriptor`、`MTLRenderCommandEncoder`、drawable、texture、attachment object、command buffer、native handle、raw pointer、platform object、backend-local resource token、callback 或 renderer state write。

## Explicit Non-Truth

`CjguiInternalRendererNoRenderPassReadiness` 明确不是：

- render pass permission。
- render pass descriptor creation。
- attachment object creation。
- texture ownership。
- drawable permission。
- command buffer permission。
- encoder permission。
- backend readiness。
- backend object readiness。
- platform object readiness。
- render permission。
- render execution。
- renderer state write。
- Metal / AppKit implementation。
- `MTLRenderPassDescriptor` ownership。
- `MTLRenderCommandEncoder` ownership。
- drawable / texture / attachment ownership。
- native handle / raw pointer surface。
- encoder lifecycle owner。
- draw call lifecycle owner。
- render execution gate。
- draw call。
- GPU batching。
- public API / public C ABI。

当前没有 `MTLRenderPassDescriptor`、encoder、drawable、texture、attachment object、command buffer、native handle 或 raw pointer。当前没有 backend implementation、render execution 或 renderer state write。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 manifest 生效。

本轮选择 manifest 封账，明确拒绝：

- render pass receipt / record / publication。
- backend-readiness wrapper。
- encoder readiness wrapper。
- render permission wrapper。
- render pass permission wrapper。

`CjguiInternalRendererNoRenderPassReadiness` 已经是当前 no-render-pass lifecycle endpoint。继续新增 receipt / record / publication 或 readiness wrapper 会把同一结果换名包装，缺少新的 owner truth、consumer、lifecycle 或 platform evidence。

若未来靠近 encoder / draw call / platform lifecycle，必须先做 docs-only preflight，并引用 [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 的具体 evidence。

## Stop-line

继续禁止：

- no runtime code in this manifest round。
- no `.cj` modifications。
- no render pass creation。
- no render pass descriptor creation。
- no render command encoder creation。
- no texture / attachment object creation。
- no drawable acquisition。
- no command buffer creation。
- no backend / Metal / AppKit implementation。
- no platform resource implementation。
- no render execution / draw call。
- no GPU batching / draw-call merge。
- no sorting side effect。
- no packet mutation。
- no renderer state write。
- no native handle / raw pointer / platform object。
- no backend-readiness wrapper。
- no encoder readiness wrapper。
- no render pass receipt / record / publication。
- no observer callback / event bus / telemetry / logging / public diagnostics。
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

### A. P1 internal Renderer encoder lifecycle preflight decision

推荐为下一阶段 opening。

理由：

- Render pass lifecycle endpoint 已封账后，下一步若继续靠近 backend lifecycle，应先 docs-only 评估 encoder owner / lifecycle / readiness runway。
- Encoder lifecycle 必须仍保持 no-encoder / no-render / no-platform-object 边界。
- 该 preflight 不创建 render command encoder，不绑定 pipeline state，不绑定 resources，不发 draw calls，不接 backend implementation。

### B. P1 internal Renderer draw call lifecycle preflight decision

暂缓。

Draw call lifecycle 通常应等 encoder lifecycle preflight 后再开。它更靠近 pipeline state、resource binding、draw command 与 GPU submission。

### C. Render pass lifecycle hardening

暂缓。

只有发现 attachment / load-store / clear-color 表达不足时才选。当前 manifest 未发现硬化缺口。

### D. Backend-readiness preflight revisit

暂缓。

Backend-readiness 仍太容易变成 wrapper。等 encoder / draw call lifecycle 进一步拆清后再评估。

### E. Render pass / Metal implementation

拒绝。

### F. Render execution / renderer state write

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

本 manifest 固定 `runtime_renderer_render_pass.cj` owner / truth / canonical endpoint / stop-line，并封账 no-render-pass lifecycle endpoint。

唯一 next opening：

`P1 internal Renderer encoder lifecycle preflight decision`

下一轮必须 docs-only，不得创建 encoder，不得创建 render pass descriptor，不得创建 command buffer，不得获取 drawable，不得接 backend / Metal / AppKit implementation，不得 render，不得写 renderer state。

## Downstream Encoder Lifecycle Preflight

Renderer encoder lifecycle preflight 已完成：

- [2026-05-03-p1-renderer-encoder-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-preflight-decision.md)

该 preflight 判定可以打开 encoder lifecycle runway，但下一步仍只能是 internal value boundary，不是真实 encoder。若下一轮实现，建议 owner 是 `runtime/cjgui/src/runtime_renderer_encoder.cj`，只消费 `CjguiInternalRendererNoRenderPassReadiness`，只输出 encoder lifecycle intent / encoding scope policy / pipeline binding guard / end-encoding policy / no-encoder readiness value facts。

Same-shape Boundary Brake 继续生效：不得把 no-render-pass endpoint 包成 encoder receipt / record / publication、backend-readiness wrapper、draw call readiness wrapper 或 render permission wrapper；不得创建或引用 `MTLRenderCommandEncoder`、`MTLRenderPassDescriptor`、command buffer、drawable、texture、attachment object、pipeline state、native handle 或 raw pointer，不得实现 backend / Metal / AppKit、render execution 或 renderer state write。

## Downstream Encoder Lifecycle Value Boundary

Renderer encoder lifecycle value boundary 已完成：

- [2026-05-03-p1-internal-renderer-encoder-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-encoder-lifecycle-value-boundary-closure-review.md)

该 boundary 新增 `runtime/cjgui/src/runtime_renderer_encoder.cj`，canonical endpoint 是 `CjguiInternalRendererNoEncoderReadiness` / `cjguiInternalExecuteDefaultRendererEncoderLifecycleDraft()`。它只表达 encoder lifecycle intent / encoding scope policy / pipeline binding guard / end-encoding policy / no-encoder readiness value facts，不是 no-render-pass endpoint 的 receipt / record / publication，也不批准真实 encoder、pipeline state、draw call、backend、render execution 或 renderer state write。

## Downstream Encoder Lifecycle Next-boundary Decision

Renderer encoder lifecycle next-boundary decision 已完成：

- [2026-05-03-p1-renderer-encoder-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoEncoderReadiness` 已足够作为 no-encoder lifecycle endpoint，下一步先做 docs-only manifest stabilization。Same-shape Boundary Brake 继续拒绝 encoder receipt / record / publication、backend-readiness wrapper、draw-call readiness wrapper、pipeline state lifecycle wrapper 或真实 render execution。

## Downstream Encoder Lifecycle Manifest

Renderer encoder lifecycle manifest stabilization 已完成：

- [2026-05-03-p1-renderer-encoder-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-encoder-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-encoder-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime_renderer_encoder.cj` owner / truth / canonical endpoint / stop-line，并封账 `CjguiInternalRendererNoEncoderReadiness` / `cjguiInternalExecuteDefaultRendererEncoderLifecycleDraft()`。下一步只允许 docs-only `P1 internal Renderer draw call lifecycle preflight decision`，不得直接创建 encoder、绑定 pipeline state、发 draw call、接 backend / Metal implementation、render execution 或 renderer state write。

## Downstream Draw Call Lifecycle Preflight

Renderer draw call lifecycle preflight 已完成：

- [2026-05-03-p1-renderer-draw-call-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-draw-call-lifecycle-preflight-decision.md)

该 preflight 只允许从 `CjguiInternalRendererNoEncoderReadiness` 进入 draw call lifecycle value boundary runway，并明确 draw command shape / geometry source / draw sequencing / no-draw-call 是 value facts，不是 draw call execution、encoder call、pipeline state binding、buffer binding、texture binding、backend implementation、render execution 或 renderer state write。

## Downstream Render Execution Preflight

Renderer render execution preflight 已完成：

- [2026-05-04-p1-renderer-render-execution-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-preflight-decision.md)

该 preflight 将 render pass lifecycle manifest 作为 docs evidence：attachment / load-store / clear-color / no-render-pass facts 只能进入 render execution command sequencing summary、failure / no-draw fallback 与 frame relation vocabulary，不是 render pass descriptor permission、encoder permission、backend implementation、render execution implementation 或 renderer state write。
