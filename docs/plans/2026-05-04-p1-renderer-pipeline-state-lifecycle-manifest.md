# P1 Renderer pipeline state lifecycle manifest

日期：2026-05-04

状态：manifest stabilization

## Purpose

本 manifest 固定 `runtime_renderer_pipeline_state.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-pipeline-state lifecycle endpoint。

它不是 pipeline state implementation manifest，也不是 shader / library lifecycle manifest、render-execution readiness manifest、backend-readiness manifest 或 Metal / AppKit implementation plan。它只记录 pipeline state lifecycle intent、shader function policy、pipeline descriptor policy、pipeline compatibility guard 与 no-pipeline-state readiness 的 internal value facts。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state.cj`

Canonical upstream endpoint：

- `CjguiInternalRendererNoDrawCallReadiness`
- `cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoPipelineStateReadiness`
- `cjguiInternalExecuteDefaultRendererPipelineStateLifecycleDraft()`

Current truth：

- pipeline state lifecycle intent value facts。
- shader function policy value facts。
- pipeline descriptor policy value facts。
- pipeline compatibility guard value facts。
- no-pipeline-state readiness value facts。

## Current Pipeline

当前 pipeline state lifecycle value pipeline：

1. `CjguiInternalRendererNoDrawCallReadiness`
2. `CjguiInternalRendererPipelineStateLifecycleIntent`
3. `CjguiInternalRendererShaderFunctionPolicy`
4. `CjguiInternalRendererPipelineDescriptorPolicy`
5. `CjguiInternalRendererPipelineCompatibilityGuard`
6. `CjguiInternalRendererNoPipelineStateReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererPipelineStateLifecycleDraft()`
- 只调用 `cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不接 backend / Metal / AppKit implementation。
- 不创建 pipeline state。
- 不加载 shader library / function。
- 不创建 pipeline descriptor。
- 不编译 pipeline。
- 不缓存 pipeline。
- 不调用 encoder。
- 不绑定 pipeline。
- 不绑定 buffer / texture。
- 不提交 GPU work。
- 不执行 draw call。
- 不执行 render。
- 不写 renderer state。

## Value Semantics

`CjguiInternalRendererPipelineStateLifecycleIntent` 只表达 future pipeline state lifecycle intent，不是 pipeline state implementation、backend readiness、render execution gate、shader library permission 或 render permission。

`CjguiInternalRendererShaderFunctionPolicy` 只表达 shader role placeholder 与 future shader selection facts；它不加载 shader library，不解析 shader function，不创建 shader object。

`CjguiInternalRendererPipelineDescriptorPolicy` 只表达 vertex layout placeholder、color attachment format relation、blend placeholder 与 depth / stencil placeholder facts；它不创建 `MTLRenderPipelineDescriptor`，不设置 platform descriptor，不持有 platform object。

`CjguiInternalRendererPipelineCompatibilityGuard` 只表达 material key / render pass / encoder / draw call compatibility relation 与 failure / no-pipeline fallback facts；它不编译 pipeline，不缓存 pipeline，不绑定 pipeline，不触发 render execution。

`CjguiInternalRendererNoPipelineStateReadiness` 是当前 no-pipeline-state lifecycle endpoint。Readiness 只表示该 internal value boundary 可以继续评估，不代表任何 side effect permission。

## Relationship Facts

Pipeline state 与 material key / render pass / encoder / draw call 的关系只能作为 dehydrated lifecycle facts 表达：

- material key relation。
- shader role placeholder。
- vertex layout placeholder。
- color attachment format relation。
- blend placeholder。
- depth / stencil placeholder。
- pipeline compatibility relation。
- render pass compatibility relation。
- encoder binding precondition as guard facts only。
- draw call shape compatibility relation。
- failure / no-pipeline fallback。
- rollback expectation as value facts only。

这些 facts 不能携带 `MTLRenderPipelineState`、`MTLRenderPipelineDescriptor`、shader library、shader function、encoder、buffer、texture、command buffer、render pass descriptor、drawable、native handle、raw pointer、platform object、backend-local resource token、compile callback、cache object、pipeline object 或 renderer state write。

Material key / render pass / encoder / draw call compatibility 只作为 dehydrated lifecycle facts。它们不是 pipeline compile plan、shader lookup plan、descriptor construction plan、encoder binding plan、buffer binding plan、texture binding plan、draw-call execution plan 或 GPU submission plan。

## Explicit Non-Truth

`CjguiInternalRendererNoPipelineStateReadiness` 明确不是：

- pipeline-state permission。
- shader loading permission。
- shader library permission。
- shader function permission。
- pipeline descriptor permission。
- pipeline compile permission。
- pipeline cache permission。
- encoder binding permission。
- buffer / texture binding permission。
- draw-call permission。
- backend readiness。
- backend object readiness。
- render execution permission。
- renderer state write。
- Metal / AppKit implementation。
- `MTLRenderPipelineState` ownership。
- `MTLRenderPipelineDescriptor` ownership。
- shader library / function ownership。
- encoder ownership。
- buffer ownership。
- texture ownership。
- command buffer ownership。
- render pass ownership。
- native handle / raw pointer surface。
- shader / library lifecycle owner。
- render execution owner。
- backend-readiness wrapper。
- render-execution readiness wrapper。
- pipeline-state receipt / record / publication。
- public API / public C ABI。

当前没有 `MTLRenderPipelineState`、`MTLRenderPipelineDescriptor`、shader function、shader library、encoder binding、buffer binding、texture binding、native handle 或 raw pointer。当前没有 backend implementation 或 render execution。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 manifest 生效。

本轮选择 manifest 封账，明确拒绝：

- pipeline-state receipt / record / publication。
- backend-readiness wrapper。
- render-execution readiness wrapper。
- shader-library readiness wrapper。
- pipeline compile / cache wrapper。
- pipeline-state permission wrapper。
- render permission wrapper。

`CjguiInternalRendererNoPipelineStateReadiness` 已经是当前 no-pipeline-state lifecycle endpoint。继续新增 receipt / record / publication 或 readiness wrapper 会把同一结果换名包装，缺少新的 owner truth、consumer、lifecycle 或 platform evidence。

若未来靠近 render execution / shader library / platform lifecycle，必须先做 docs-only preflight，并引用 [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 的具体 evidence。不得直接创建 pipeline state、加载 shader library / function、创建 descriptor、绑定 pipeline、调用 encoder、绑定 buffer / texture、执行 draw call、GPU submission、backend / Metal / AppKit implementation、render execution 或 renderer state write。

## Stop-line

继续禁止：

- no runtime code in this manifest round。
- no `.cj` modifications。
- no pipeline state creation。
- no shader library / function loading。
- no pipeline descriptor creation。
- no pipeline compile / cache mutation。
- no encoder call。
- no pipeline binding。
- no buffer / texture binding。
- no draw call execution。
- no GPU submission。
- no command buffer creation。
- no render pass creation。
- no drawable acquisition。
- no backend / Metal / AppKit implementation。
- no platform resource implementation。
- no render execution。
- no renderer state write。
- no GPU batching / draw-call merge。
- no sorting side effect。
- no packet mutation。
- no native handle / raw pointer / platform object。
- no backend-readiness wrapper。
- no render-execution readiness wrapper。
- no shader-library readiness wrapper。
- no pipeline-state receipt / record / publication。
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

### A. P1 internal Renderer render execution preflight decision

推荐为下一阶段 opening。

理由：

- Pipeline state lifecycle endpoint 已封账后，下一步若继续靠近 backend lifecycle，应先 docs-only 评估 render execution owner / lifecycle / readiness runway。
- Render execution preflight 必须仍保持 no-render / no-GPU-submission / no-renderer-state-write 边界。
- 该 preflight 不创建 pipeline state，不加载 shader library，不绑定 pipeline，不调用 encoder，不发 draw call，不接 backend implementation。

### B. P1 internal Renderer shader/library lifecycle preflight decision

暂缓。

当前 `ShaderFunctionPolicy` 已足够表达 shader role placeholder / future shader selection facts，manifest 未发现 shader owner truth 缺口。只有后续 render execution preflight 或 pipeline hardening 明确暴露 shader owner 缺口时，才另开 docs-only preflight。

### C. Pipeline state lifecycle hardening

暂缓。

只有发现 shader role / descriptor policy / compatibility 表达不足时才选。当前 manifest 未发现硬化缺口。

### D. Backend-readiness preflight revisit

暂缓。

等 render execution lifecycle 进一步拆清后再评估，避免 backend-readiness wrapper。

### E. Pipeline state / Metal implementation

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

本 manifest 固定 `runtime_renderer_pipeline_state.cj` owner / truth / canonical endpoint / stop-line，并封账 no-pipeline-state lifecycle endpoint。

唯一 next opening：

`P1 internal Renderer render execution preflight decision`

下一轮必须 docs-only，评估 render execution owner / lifecycle / readiness runway；不得创建 pipeline state，不得加载 shader library / function，不得创建 descriptor，不得绑定 pipeline，不得调用 encoder，不得绑定 buffer / texture，不得执行 draw call，不得 GPU submission，不得创建 command buffer / render pass / drawable / platform object，不得接 backend / Metal / AppKit implementation，不得 render，不得写 renderer state。

## Validation

Validation results will be recorded in [2026-05-04-p1-internal-renderer-pipeline-state-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-pipeline-state-lifecycle-manifest-stabilization-closure-review.md).

## Downstream Render Execution Preflight

Renderer render execution preflight 已完成：

- [2026-05-04-p1-renderer-render-execution-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-preflight-decision.md)

该 preflight 判定可以打开 render execution runway，但下一步仍只能是 internal no-op value boundary，不是真实 render execution。若下一轮实现，建议 owner 是 `runtime/cjgui/src/runtime_renderer_render_execution.cj`，只消费 `CjguiInternalRendererNoPipelineStateReadiness`，只输出 render execution intent / execution ordering policy / no-submit guard / completion observation policy / no-render-execution readiness value facts。

Same-shape Boundary Brake 继续生效：不得把 no-pipeline-state endpoint 包成 render-execution receipt / record / publication、backend-readiness wrapper、renderer-state-write readiness wrapper、command-buffer-commit readiness wrapper 或 GPU-submission wrapper；不得执行 render、commit command buffer、submit GPU work、present drawable、调用 encoder、发 draw call、绑定 pipeline / buffer / texture、创建 platform object、接 backend / Metal / AppKit implementation 或写 renderer state。

## Downstream Render Execution No-op Value Boundary

Renderer render execution no-op value boundary 已完成：

- [2026-05-04-p1-internal-renderer-render-execution-no-op-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-render-execution-no-op-boundary-closure-review.md)

该 boundary 新增 `runtime/cjgui/src/runtime_renderer_render_execution.cj`，只消费 `CjguiInternalRendererNoPipelineStateReadiness`，canonical endpoint 是 `CjguiInternalRendererNoRenderExecutionReadiness` / `cjguiInternalExecuteDefaultRendererRenderExecutionNoOpDraft()`。Pipeline state manifest 的 stop-line 继续生效：render execution owner 只能表达 no-op value facts，不得执行 render、commit command buffer、submit GPU work、present drawable、调用 encoder、绑定 pipeline、接 backend / Metal / AppKit implementation 或写 renderer state。

## Downstream Render Execution No-op Next-boundary Decision

Renderer render execution no-op next-boundary decision 已完成：

- [2026-05-04-p1-renderer-render-execution-no-op-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoRenderExecutionReadiness` 已经是当前 no-render-execution endpoint。下一步选择 docs-only `P1 internal Renderer render execution no-op manifest stabilization bundle implementation`，而不是新增 render-execution receipt / record / publication、backend-readiness wrapper、command-buffer-commit readiness wrapper、GPU-submission wrapper 或 renderer-state-write wrapper。

## Downstream Render Execution No-op Manifest

Renderer render execution no-op manifest stabilization 已完成：

- [2026-05-04-p1-renderer-render-execution-no-op-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md)
- [2026-05-04-p1-internal-renderer-render-execution-no-op-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-render-execution-no-op-manifest-stabilization-closure-review.md)

该 manifest 封账 `runtime_renderer_render_execution.cj`，并确认 render execution owner 仍只表达 no-op value facts。Pipeline state manifest 的 stop-line 继续生效：不得把 no-pipeline-state endpoint 或 no-render-execution endpoint 包成 backend-readiness wrapper、renderer-state-write wrapper、command-buffer-commit readiness wrapper、GPU-submission wrapper 或 render-execution receipt / record / publication。
