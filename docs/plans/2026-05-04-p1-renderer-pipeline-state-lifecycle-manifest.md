# P1 渲染器 pipeline state lifecycle manifest

日期：2026-05-04

状态：manifest stabilization

## 用途

本 manifest 固定 `runtime_renderer_pipeline_state.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-pipeline-state lifecycle endpoint。

它不是 pipeline state implementation manifest，也不是 shader / library lifecycle manifest、render-execution readiness manifest、backend-readiness manifest 或 Metal / AppKit implementation plan。它只记录 pipeline state lifecycle intent、shader function policy、pipeline descriptor policy、pipeline compatibility guard 与 no-pipeline-state readiness 的 internal value facts。

## Owner 与 truth

Owner 文件：

- Owner 路径：`/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state.cj`

Canonical upstream endpoint 固定为：

- 上游 endpoint 类型：`CjguiInternalRendererNoDrawCallReadiness`
- 上游 draft：`cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft()`

Canonical endpoint 固定为：

- endpoint 类型：`CjguiInternalRendererNoPipelineStateReadiness`
- 端点 draft：`cjguiInternalExecuteDefaultRendererPipelineStateLifecycleDraft()`

Current truth 仅限：

- 记录 pipeline state lifecycle intent value facts。
- 记录 shader function policy value facts。
- 记录 pipeline descriptor policy value facts。
- 记录 pipeline compatibility guard value facts。
- 记录 no-pipeline-state readiness value facts。

## 当前 pipeline

当前 pipeline state lifecycle value pipeline：

1. 上游输入：`CjguiInternalRendererNoDrawCallReadiness`
2. lifecycle 意图：`CjguiInternalRendererPipelineStateLifecycleIntent`
3. shader function 策略：`CjguiInternalRendererShaderFunctionPolicy`
4. pipeline descriptor 策略：`CjguiInternalRendererPipelineDescriptorPolicy`
5. compatibility guard 事实：`CjguiInternalRendererPipelineCompatibilityGuard`
6. 封账 endpoint：`CjguiInternalRendererNoPipelineStateReadiness`

默认 draft：

- 默认 draft：`cjguiInternalExecuteDefaultRendererPipelineStateLifecycleDraft()`
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

## value 语义

`CjguiInternalRendererPipelineStateLifecycleIntent` 只表达 future pipeline state lifecycle intent，不是 pipeline state implementation、backend readiness、render execution gate、shader library permission 或 render permission。

`CjguiInternalRendererShaderFunctionPolicy` 只表达 shader role placeholder 与 future shader selection facts；它不加载 shader library，不解析 shader function，不创建 shader object。

`CjguiInternalRendererPipelineDescriptorPolicy` 只表达 vertex layout placeholder、color attachment format relation、blend placeholder 与 depth / stencil placeholder facts；它不创建 `MTLRenderPipelineDescriptor`，不设置 platform descriptor，不持有 platform object。

`CjguiInternalRendererPipelineCompatibilityGuard` 只表达 material key / render pass / encoder / draw call compatibility relation 与 failure / no-pipeline fallback facts；它不编译 pipeline，不缓存 pipeline，不绑定 pipeline，不触发 render execution。

`CjguiInternalRendererNoPipelineStateReadiness` 是当前 no-pipeline-state lifecycle endpoint。Readiness 只表示该 internal value boundary 可以继续评估，不代表任何 side effect permission。

## 关系事实

Pipeline state 与 material key / render pass / encoder / draw call 的关系只能作为 dehydrated lifecycle facts 表达：

- 记录 material key relation。
- 记录 shader role placeholder。
- 记录 vertex layout placeholder。
- 记录 color attachment format relation。
- 记录 blend placeholder。
- 记录 depth / stencil placeholder。
- 记录 pipeline compatibility relation。
- 记录 render pass compatibility relation。
- 记录 encoder binding precondition as guard facts only。
- 记录 draw call shape compatibility relation。
- 记录 failure / no-pipeline fallback。
- 记录 rollback expectation as value facts only。

这些 facts 不能携带 `MTLRenderPipelineState`、`MTLRenderPipelineDescriptor`、shader library、shader function、encoder、buffer、texture、command buffer、render pass descriptor、drawable、native handle、raw pointer、platform object、backend-local resource token、compile callback、cache object、pipeline object 或 renderer state write。

Material key / render pass / encoder / draw call compatibility 只作为 dehydrated lifecycle facts。它们不是 pipeline compile plan、shader lookup plan、descriptor construction plan、encoder binding plan、buffer binding plan、texture binding plan、draw-call execution plan 或 GPU submission plan。

## 明确的非 truth

`CjguiInternalRendererNoPipelineStateReadiness` 明确不是：

- 不是 pipeline-state permission。
- 不是 shader loading permission。
- 不是 shader library permission。
- 不是 shader function permission。
- 不是 pipeline descriptor permission。
- 不是 pipeline compile permission。
- 不是 pipeline cache permission。
- 不是 encoder binding permission。
- 不是 buffer / texture binding permission。
- 不是 draw-call permission。
- 不是 backend readiness。
- 不是 backend object readiness。
- 不是 render execution permission。
- 不是 renderer state write。
- 不是 Metal / AppKit implementation。
- 不是 `MTLRenderPipelineState` ownership。
- 不是 `MTLRenderPipelineDescriptor` ownership。
- 不是 shader library / function ownership。
- 不是 encoder ownership。
- 不是 buffer ownership。
- 不是 texture ownership。
- 不是 command buffer ownership。
- 不是 render pass ownership。
- 不是 native handle / raw pointer surface。
- 不是 shader / library lifecycle owner。
- 不是 render execution owner。
- 不是 backend-readiness wrapper。
- 不是 render-execution readiness wrapper。
- 不是 pipeline-state receipt / record / publication。
- 不是 public API / public C ABI。

当前没有 `MTLRenderPipelineState`、`MTLRenderPipelineDescriptor`、shader function、shader library、encoder binding、buffer binding、texture binding、native handle 或 raw pointer。当前没有 backend implementation 或 render execution。

## 同构边界刹车（Same-shape Boundary Brake）

Same-shape Boundary Brake 在本 manifest 生效。

本轮选择 manifest 封账，明确拒绝：

- 拒绝 pipeline-state receipt / record / publication。
- 拒绝 backend-readiness wrapper。
- 拒绝 render-execution readiness wrapper。
- 拒绝 shader-library readiness wrapper。
- 拒绝 pipeline compile / cache wrapper。
- 拒绝 pipeline-state permission wrapper。
- 拒绝 render permission wrapper。

`CjguiInternalRendererNoPipelineStateReadiness` 已经是当前 no-pipeline-state lifecycle endpoint。继续新增 receipt / record / publication 或 readiness wrapper 会把同一结果换名包装，缺少新的 owner truth、consumer、lifecycle 或 platform evidence。

若未来靠近 render execution / shader library / platform lifecycle，必须先做 docs-only preflight，并引用 [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 的具体 evidence。不得直接创建 pipeline state、加载 shader library / function、创建 descriptor、绑定 pipeline、调用 encoder、绑定 buffer / texture、执行 draw call、GPU submission、backend / Metal / AppKit implementation、render execution 或 renderer state write。

## 停止线（Stop-line）

继续禁止：

- 不新增 runtime code in this manifest round。
- 不修改 `.cj`。
- 不创建 pipeline state。
- 不加载 shader library / function。
- 不创建 pipeline descriptor。
- 不执行 pipeline compile / cache mutation。
- 不调用 encoder。
- 不绑定 pipeline。
- 不绑定 buffer / texture。
- 不执行 draw call。
- 不提交 GPU submission。
- 不创建 command buffer。
- 不创建 render pass。
- 不获取 drawable。
- 不接 backend / Metal / AppKit implementation。
- 不实现 platform resource。
- 不执行 render。
- 不写 renderer state。
- 不做 GPU batching / draw-call merge。
- 不做 sorting side effect。
- 不做 packet mutation。
- 不创建 native handle / raw pointer / platform object。
- 不新增 backend-readiness wrapper。
- 不新增 render-execution readiness wrapper。
- 不新增 shader-library readiness wrapper。
- 不新增 pipeline-state receipt / record / publication。
- 不新增 observer callback / event bus / telemetry / logging / public diagnostics。
- 不做 dirty-region / diff / patch / incremental render。
- 不实现 Widget / Layout / Text / IME / Accessibility / ECS。
- 不扩 public surface。
- 不修改 `cjguiExperimentalQueueSubmitShellReady(): Bool` signature。
- 不触碰 `runtime_state.cj`。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 smoke / harness / native bridge / entry。

## 公共 surface

public symbol allowlist 未变：

- 唯一允许：`cjguiExperimentalQueueSubmitShellReady(): Bool`

本 manifest 不批准第二个 public symbol、不修改 Bool-only signature、不新增 structured public return、不开放 public C ABI。

## 下一阶段候选比较

### 候选 A：P1 internal Renderer render execution preflight decision

推荐为下一阶段 opening。

理由：

- Pipeline state lifecycle endpoint 已封账后，下一步若继续靠近 backend lifecycle，应先 docs-only 评估 render execution owner / lifecycle / readiness runway。
- Render execution preflight 必须仍保持 no-render / no-GPU-submission / no-renderer-state-write 边界。
- 该 preflight 不创建 pipeline state，不加载 shader library，不绑定 pipeline，不调用 encoder，不发 draw call，不接 backend implementation。

### 候选 B：P1 internal Renderer shader/library lifecycle preflight decision

暂缓。

当前 `ShaderFunctionPolicy` 已足够表达 shader role placeholder / future shader selection facts，manifest 未发现 shader owner truth 缺口。只有后续 render execution preflight 或 pipeline hardening 明确暴露 shader owner 缺口时，才另开 docs-only preflight。

### 候选 C：Pipeline state lifecycle hardening

暂缓。

只有发现 shader role / descriptor policy / compatibility 表达不足时才选。当前 manifest 未发现硬化缺口。

### 候选 D：Backend-readiness preflight revisit

暂缓。

等 render execution lifecycle 进一步拆清后再评估，避免 backend-readiness wrapper。

### 候选 E：Pipeline state / Metal implementation

拒绝。

### 候选 F：Render execution / renderer state write

拒绝。

### 候选 G：Metal / AppKit / platform resource / native handle implementation

拒绝。

### 候选 H：Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### 候选 I：Public surface expansion

拒绝。

### 候选 J：Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前没有这类 evidence。

## 封账结论

本 manifest 固定 `runtime_renderer_pipeline_state.cj` owner / truth / canonical endpoint / stop-line，并封账 no-pipeline-state lifecycle endpoint。

唯一 next opening：

原 downstream opening 是 `P1 internal Renderer render execution preflight decision`。

下一轮必须 docs-only，评估 render execution owner / lifecycle / readiness runway；不得创建 pipeline state，不得加载 shader library / function，不得创建 descriptor，不得绑定 pipeline，不得调用 encoder，不得绑定 buffer / texture，不得执行 draw call，不得 GPU submission，不得创建 command buffer / render pass / drawable / platform object，不得接 backend / Metal / AppKit implementation，不得 render，不得写 renderer state。

## 验证记录

验证结果已记录在 [2026-05-04-p1-internal-renderer-pipeline-state-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-pipeline-state-lifecycle-manifest-stabilization-closure-review.md)。

## 下游 render execution preflight

Renderer render execution preflight 已完成：

- [2026-05-04-p1-renderer-render-execution-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-preflight-decision.md)

该 preflight 判定可以打开 render execution runway，但下一步仍只能是 internal no-op value boundary，不是真实 render execution。若下一轮实现，建议 owner 是 `runtime/cjgui/src/runtime_renderer_render_execution.cj`，只消费 `CjguiInternalRendererNoPipelineStateReadiness`，只输出 render execution intent / execution ordering policy / no-submit guard / completion observation policy / no-render-execution readiness value facts。

Same-shape Boundary Brake 继续生效：不得把 no-pipeline-state endpoint 包成 render-execution receipt / record / publication、backend-readiness wrapper、renderer-state-write readiness wrapper、command-buffer-commit readiness wrapper 或 GPU-submission wrapper；不得执行 render、commit command buffer、submit GPU work、present drawable、调用 encoder、发 draw call、绑定 pipeline / buffer / texture、创建 platform object、接 backend / Metal / AppKit implementation 或写 renderer state。

## 下游 render execution no-op value boundary

Renderer render execution no-op value boundary 已完成：

- [2026-05-04-p1-internal-renderer-render-execution-no-op-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-render-execution-no-op-boundary-closure-review.md)

该 boundary 新增 `runtime/cjgui/src/runtime_renderer_render_execution.cj`，只消费 `CjguiInternalRendererNoPipelineStateReadiness`，canonical endpoint 是 `CjguiInternalRendererNoRenderExecutionReadiness` / `cjguiInternalExecuteDefaultRendererRenderExecutionNoOpDraft()`。Pipeline state manifest 的 stop-line 继续生效：render execution owner 只能表达 no-op value facts，不得执行 render、commit command buffer、submit GPU work、present drawable、调用 encoder、绑定 pipeline、接 backend / Metal / AppKit implementation 或写 renderer state。

## 下游 render execution no-op next-boundary decision

Renderer render execution no-op next-boundary decision 已完成：

- [2026-05-04-p1-renderer-render-execution-no-op-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoRenderExecutionReadiness` 已经是当前 no-render-execution endpoint。下一步选择 docs-only `P1 internal Renderer render execution no-op manifest stabilization bundle implementation`，而不是新增 render-execution receipt / record / publication、backend-readiness wrapper、command-buffer-commit readiness wrapper、GPU-submission wrapper 或 renderer-state-write wrapper。

## 下游 render execution no-op manifest

Renderer render execution no-op manifest stabilization 已完成：

- [2026-05-04-p1-renderer-render-execution-no-op-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md)
- [2026-05-04-p1-internal-renderer-render-execution-no-op-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-render-execution-no-op-manifest-stabilization-closure-review.md)

该 manifest 封账 `runtime_renderer_render_execution.cj`，并确认 render execution owner 仍只表达 no-op value facts。Pipeline state manifest 的 stop-line 继续生效：不得把 no-pipeline-state endpoint 或 no-render-execution endpoint 包成 backend-readiness wrapper、renderer-state-write wrapper、command-buffer-commit readiness wrapper、GPU-submission wrapper 或 render-execution receipt / record / publication。

## 下游 pipeline state implementation preflight

Renderer pipeline state implementation preflight 已完成：

- [2026-05-06-p1-renderer-pipeline-state-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-preflight-decision.md)

该 preflight 只将本 manifest 作为 pipeline state lifecycle vocabulary evidence。`CjguiInternalRendererNoPipelineStateReadiness` 不是 pipeline state implementation runtime input，也不是 pipeline state、shader function、pipeline descriptor、pipeline binding、GPU submission、render、renderer state write 或 public API permission。

新的 implementation admission runway 只建议消费 `CjguiInternalRendererNoEncoderImplementationReadiness` / `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()`，并只输出 pipeline state implementation intent / shader function admission policy / pipeline descriptor admission policy / pipeline compatibility admission guard / no-pipeline-state-implementation readiness value facts。

该 preflight 选择下一步进入：

新的 implementation admission value boundary 已完成：

- [2026-05-06-p1-internal-renderer-pipeline-state-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-pipeline-state-implementation-admission-value-boundary-closure-review.md)
- [runtime_renderer_pipeline_state_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_admission.cj)

该 owner 只把本 manifest 作为 lifecycle vocabulary evidence，不消费 `CjguiInternalRendererNoPipelineStateReadiness`。它只消费 `CjguiInternalRendererNoEncoderImplementationReadiness` / `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()`，canonical endpoint 是 `CjguiInternalRendererNoPipelineStateImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()`。

新的 implementation admission next-boundary decision 已完成：

- [2026-05-06-p1-renderer-pipeline-state-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-admission-next-boundary-decision.md)

该 decision 只把本 manifest 作为 pipeline state lifecycle vocabulary evidence，并确认 `CjguiInternalRendererNoPipelineStateImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()` 足够作为当前 no-pipeline-state-implementation endpoint。`CjguiInternalRendererNoPipelineStateReadiness` 仍不是 implementation runtime input，也不是 pipeline state、shader library / shader function、pipeline descriptor、pipeline binding、GPU submission、render、renderer state write 或 public API permission。

新的 implementation admission manifest stabilization 已完成：

- [2026-05-06-p1-renderer-pipeline-state-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-pipeline-state-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-pipeline-state-implementation-admission-manifest-stabilization-closure-review.md)

该 manifest 固定 implementation admission owner 的 current truth 与 stop-line。它仍只把本 manifest 作为 lifecycle vocabulary evidence，不消费 `CjguiInternalRendererNoPipelineStateReadiness`，也不授予 pipeline state、shader library / shader function、pipeline descriptor、pipeline binding、GPU submission、render、renderer state write 或 public API permission。

新的唯一后续入口是 `P1 internal Renderer draw call implementation preflight decision`。

## 当前 no-draw 回流

2026-05-12 的 [pipeline state no-draw planning 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-12-p1-renderer-pipeline-state-no-draw-planning-manifest.md) 已复用本 manifest 的 shader function policy、pipeline descriptor policy 与 compatibility guard vocabulary，但只固定 planning facts；它不创建 shader library / function、pipeline descriptor、pipeline state 或 encoder，不调用 `setRenderPipelineState`，不 draw，不 `commit` / `present`，不提交 GPU work，不执行 render。

## 下游 real pipeline state first-slice macro

real pipeline state first-slice macro 已完成：

- [real encoder branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-encoder-branch-next-boundary-decision.md)
- [real pipeline state first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-pipeline-state-first-implementation-preflight-decision.md)
- [real pipeline state first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-pipeline-state-first-implementation-slice-closure-review.md)
- [real pipeline state first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-pipeline-state-first-implementation-slice-next-boundary-decision.md)
- [real pipeline state first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-pipeline-state-first-implementation-slice-manifest.md)
- [real pipeline state first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-pipeline-state-first-implementation-slice-manifest-stabilization-closure-review.md)

该 downstream 只把本 manifest 作为 lifecycle vocabulary evidence，不消费 `CjguiInternalRendererNoPipelineStateReadiness`。真实 first slice 的 runtime input 是 `CjguiInternalRendererNoRealEncoderShellReadiness`，canonical endpoint 是 `CjguiInternalRendererNoRealPipelineStateShellReadiness` / `cjguiInternalExecuteDefaultRendererRealPipelineStateShellDraft()`。

该 downstream 不把 lifecycle endpoint 包成 pipeline-ready、shader-ready、descriptor-ready、binding-ready、GPU-submission、render-permission、renderer-state-write、receipt、record 或 publication wrapper，也不创建真实 pipeline state、shader function、pipeline descriptor、pipeline binding、encoder、GPU submission、render、renderer state write 或 public API。

## 当前下游回流

2026-05-11 的 [render command encoder 创建阻塞归因清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-creation-blocker-reconciliation-manifest.md) 已确认 encoder creation 被 production drawable texture lifetime 与 `colorAttachments[0]` 双重缺口阻塞，并把主线转向 `P1 internal Renderer pipeline state no-draw planning preflight decision`。

该回流只允许重新审视 pipeline state no-draw contract；不改变本 manifest 的 stop-line，不授权创建 pipeline state、shader library / shader function、pipeline descriptor、encoder、draw、commit、present、GPU submission、render、renderer state write 或 public API。
