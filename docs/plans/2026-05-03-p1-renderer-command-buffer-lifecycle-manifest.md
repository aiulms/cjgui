# P1 Renderer command buffer lifecycle manifest

日期：2026-05-03

状态：manifest stabilization

## Purpose

本 manifest 固定 `runtime_renderer_command_buffer.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-command-buffer lifecycle endpoint。

它不是 command buffer implementation manifest，也不是 backend-readiness manifest。它只记录 command buffer lifecycle intent、creation policy、commit timing guard、single-use policy 与 no-command-buffer readiness 的 internal value facts。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_buffer.cj`

Canonical upstream endpoint：

- `CjguiInternalRendererNoDrawableReadiness`
- `cjguiInternalExecuteDefaultRendererDrawableAcquisitionDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoCommandBufferReadiness`
- `cjguiInternalExecuteDefaultRendererCommandBufferLifecycleDraft()`

Current truth：

- command buffer lifecycle intent value facts。
- command buffer creation policy value facts。
- command buffer commit timing guard value facts。
- command buffer single-use policy value facts。
- no-command-buffer readiness value facts。

## Current Pipeline

当前 command buffer lifecycle value pipeline：

1. `CjguiInternalRendererNoDrawableReadiness`
2. `CjguiInternalRendererCommandBufferLifecycleIntent`
3. `CjguiInternalRendererCommandBufferCreationPolicy`
4. `CjguiInternalRendererCommandBufferCommitTimingGuard`
5. `CjguiInternalRendererCommandBufferSingleUsePolicy`
6. `CjguiInternalRendererNoCommandBufferReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererCommandBufferLifecycleDraft()`
- 只调用 `cjguiInternalExecuteDefaultRendererDrawableAcquisitionDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不接 backend / Metal / AppKit implementation。
- 不创建 command buffer。
- 不创建 `MTLCommandBuffer` / `MTLCommandQueue`。
- 不获取 drawable。
- 不创建 render pass / encoder。
- 不 commit / submit command buffer。
- 不执行 render。
- 不写 renderer state。

## Value Semantics

`CjguiInternalRendererCommandBufferLifecycleIntent` 只表达 future command buffer lifecycle intent，不是 command buffer implementation，也不是 backend readiness wrapper。

`CjguiInternalRendererCommandBufferCreationPolicy` 只表达 future creation preconditions；它不创建 command buffer，不创建 platform object，不获取 drawable，不创建 render pass 或 encoder。

`CjguiInternalRendererCommandBufferCommitTimingGuard` 只表达 future commit timing constraints；它不 commit，不 submit，不 present，不注册 completion callback，不写 renderer state。

`CjguiInternalRendererCommandBufferSingleUsePolicy` 只表达 future single-use / post-commit invalidation / completion-failure / rollback / no-draw fallback facts；它不管理真实 buffer lifetime，不持有真实 command buffer，不管理 resource retention。

`CjguiInternalRendererNoCommandBufferReadiness` 是当前 no-command-buffer lifecycle endpoint。Readiness 只表示该 internal value boundary 可以继续评估，不代表任何 side effect permission。

## Relationship Facts

Command buffer 与 queue / drawable / render pass / frame pacing 的关系只能作为 dehydrated lifecycle facts 表达：

- creation phase。
- encoding phase boundary。
- commit timing。
- completion / failure phase。
- rollback / no-draw fallback。
- queue relationship as value facts only。
- drawable relationship as value facts only。
- render pass relationship as future boundary facts only。
- frame pacing relationship as value facts only。

这些 facts 不能携带 `MTLCommandBuffer`、`MTLCommandQueue`、drawable、render pass、encoder、native handle、raw pointer、platform object、callback、backend-local resource token 或 renderer state write。

## Explicit Non-Truth

`CjguiInternalRendererNoCommandBufferReadiness` 明确不是：

- command buffer permission。
- command buffer creation。
- command buffer commit / submission。
- command queue permission。
- drawable permission。
- render pass permission。
- encoder permission。
- backend readiness。
- backend object readiness。
- platform object readiness。
- render permission。
- renderer state write。
- Metal / AppKit implementation。
- `MTLCommandBuffer` / `MTLCommandQueue` ownership。
- drawable / render pass / encoder ownership。
- native handle / raw pointer surface。
- render pass lifecycle owner。
- encoder lifecycle owner。
- render execution gate。
- draw call。
- GPU batching。
- public API / public C ABI。

当前没有 `MTLCommandBuffer`、render pass、encoder、drawable、command queue、native handle 或 raw pointer。当前没有 backend implementation、render execution 或 renderer state write。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 manifest 生效。

本轮选择 manifest 封账，明确拒绝：

- command buffer receipt / record / publication。
- backend-readiness wrapper。
- render pass readiness wrapper。
- encoder readiness wrapper。
- command buffer permission wrapper。

`CjguiInternalRendererNoCommandBufferReadiness` 已经是当前 no-command-buffer lifecycle endpoint。继续新增 receipt / record / publication 或 readiness wrapper 会把同一结果换名包装，缺少新的 owner truth、consumer、lifecycle 或 platform evidence。

若未来靠近 render pass / encoder / platform lifecycle，必须先做 docs-only preflight，并引用 [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 的具体 evidence。

## Stop-line

继续禁止：

- no runtime code in this manifest round。
- no `.cj` modifications。
- no command buffer creation。
- no command buffer commit / submission。
- no backend / Metal / AppKit implementation。
- no platform resource implementation。
- no `MTLCommandBuffer` / `MTLCommandQueue` creation。
- no drawable acquisition。
- no render pass / render encoder creation。
- no render execution / draw call。
- no GPU batching / draw-call merge。
- no sorting side effect。
- no packet mutation。
- no renderer state write。
- no native handle / raw pointer / platform object。
- no backend-readiness wrapper。
- no render pass readiness wrapper。
- no encoder readiness wrapper。
- no command buffer receipt / record / publication。
- no completion callback / observer callback / event bus / telemetry / logging / public diagnostics。
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

### A. P1 internal Renderer render pass lifecycle preflight decision

推荐为下一阶段 opening。

理由：

- command buffer lifecycle endpoint 已封账后，下一步若继续靠近 backend lifecycle，应先 docs-only 评估 render pass owner / lifecycle / readiness runway。
- Render pass lifecycle 必须仍保持 no-render-pass / no-encoder / no-render / no-platform-object 边界。
- 该 preflight 不创建 render pass descriptor，不创建 render encoder，不提交 GPU work，不接 backend implementation。

### B. P1 internal Renderer encoder lifecycle preflight decision

暂缓。

Encoder lifecycle 通常应等 render pass lifecycle preflight 后再开。它更靠近 command encoding、pipeline state、resource binding 与 draw calls。

### C. Command buffer lifecycle hardening

暂缓。

只有发现 creation / commit timing / single-use / failure rollback 表达不足时才选。当前 manifest 未发现硬化缺口。

### D. Backend-readiness preflight revisit

暂缓。

Backend-readiness 仍太容易变成 wrapper。等 render pass / encoder lifecycle 进一步拆清后再评估。

### E. Command buffer / Metal implementation

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

本 manifest 固定 `runtime_renderer_command_buffer.cj` owner / truth / canonical endpoint / stop-line，并封账 no-command-buffer lifecycle endpoint。

唯一 next opening：

`P1 internal Renderer render pass lifecycle preflight decision`

下一轮必须 docs-only，不得创建 render pass，不得创建 encoder，不得创建 command buffer，不得获取 drawable，不得接 backend / Metal / AppKit implementation，不得 render，不得写 renderer state。

## Downstream Render Pass Lifecycle Preflight

Renderer render pass lifecycle preflight 已完成：

- [2026-05-03-p1-renderer-render-pass-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-preflight-decision.md)

该 preflight 判定可以打开 render pass lifecycle runway，但下一步仍只能是 internal value boundary，不是真实 render pass。若下一轮实现，建议 owner 是 `runtime/cjgui/src/runtime_renderer_render_pass.cj`，只消费 `CjguiInternalRendererNoCommandBufferReadiness`，只输出 render pass lifecycle intent / attachment policy / load-store policy / clear-color policy / no-render-pass readiness value facts。

Same-shape Boundary Brake 继续生效：不得把 no-command-buffer endpoint 包成 render pass receipt / record / publication、backend-readiness wrapper、encoder readiness wrapper 或 render permission wrapper；不得创建或引用 `MTLRenderPassDescriptor`、`MTLRenderCommandEncoder`、`MTLCommandBuffer`、drawable、texture、attachment object、native handle 或 raw pointer，不得实现 backend / Metal / AppKit、render execution 或 renderer state write。

## Downstream Render Pass Lifecycle Value Boundary

Renderer render pass lifecycle value boundary 已完成：

- [2026-05-03-p1-internal-renderer-render-pass-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-render-pass-lifecycle-value-boundary-closure-review.md)

该 boundary 新增 `runtime/cjgui/src/runtime_renderer_render_pass.cj`，只消费 `CjguiInternalRendererNoCommandBufferReadiness`，canonical endpoint 是 `CjguiInternalRendererNoRenderPassReadiness` / `cjguiInternalExecuteDefaultRendererRenderPassLifecycleDraft()`。Current truth 仅为 render pass lifecycle intent / attachment policy / load-store policy / clear-color policy / no-render-pass readiness value facts。

该 downstream 不创建 `MTLRenderPassDescriptor`、encoder、drawable、texture、attachment object、command buffer、backend object、platform object、native handle 或 raw pointer，不实现 backend / Metal / AppKit、render execution 或 renderer state write。下一步进入 docs-only `P1 internal Renderer render pass lifecycle closure / next render pass decision`。

## Downstream Render Pass Lifecycle Next-Boundary Decision

Renderer render pass lifecycle next-boundary decision 已完成：

- [2026-05-03-p1-renderer-render-pass-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-next-boundary-decision.md)

该 decision 确认 render pass lifecycle endpoint 已足够，下一步选择 docs-only manifest stabilization。Command buffer manifest 的 downstream stop-line 不变：不批准 render pass receipt / record / publication、backend-readiness wrapper、encoder readiness wrapper、render pass / Metal implementation、render execution 或 renderer state write。

## Downstream Render Pass Lifecycle Manifest

Renderer render pass lifecycle manifest stabilization 已完成：

- [2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-render-pass-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-render-pass-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 封账 no-render-pass lifecycle endpoint，并选择 docs-only `P1 internal Renderer encoder lifecycle preflight decision` 作为唯一 next opening。Command buffer manifest 的 stop-line 继续禁止 backend-readiness wrapper、encoder readiness wrapper、render execution、renderer state write 或真实 Metal / AppKit implementation。

## Downstream Encoder Lifecycle Preflight

Renderer encoder lifecycle preflight 已完成：

- [2026-05-03-p1-renderer-encoder-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-preflight-decision.md)

该 preflight 只允许下一步进入 internal value boundary，不批准 encoder implementation。Command buffer manifest 的 downstream stop-line 不变：不批准 encoder receipt / record / publication、backend-readiness wrapper、draw call readiness wrapper、encoder / Metal implementation、render execution 或 renderer state write。

## Downstream Render Execution Preflight

Renderer render execution preflight 已完成：

- [2026-05-04-p1-renderer-render-execution-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-preflight-decision.md)

该 preflight 将 command buffer lifecycle manifest 作为 docs evidence：creation phase、commit timing guard、single-use / post-commit invalidation 与 completion-failure facts 只能进入 no-submit guard / completion observation policy vocabulary。它不批准 command buffer creation、commit、GPU submission、completion callback registration、backend implementation、render execution implementation 或 renderer state write。
