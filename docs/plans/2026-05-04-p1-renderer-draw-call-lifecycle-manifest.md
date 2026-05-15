# P1 渲染器绘制调用 lifecycle manifest 封账

日期：2026-05-04

状态：manifest stabilization

## 用途

本 manifest 固定 `runtime_renderer_draw_call.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-draw-call lifecycle endpoint。

它不是 draw call implementation manifest，也不是 pipeline-state readiness manifest、render-execution readiness manifest、backend-readiness manifest 或 Metal / AppKit implementation plan。它只记录 draw call lifecycle intent、draw command shape policy、geometry source policy、draw sequencing guard 与 no-draw-call readiness 的 internal value facts。

## 归属与 truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_call.cj`

Canonical upstream endpoint：

- `CjguiInternalRendererNoEncoderReadiness`
- `cjguiInternalExecuteDefaultRendererEncoderLifecycleDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoDrawCallReadiness`
- `cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft()`

Current truth：

- draw call lifecycle intent value facts。
- draw command shape policy value facts。
- geometry source policy value facts。
- draw sequencing guard value facts。
- no-draw-call readiness value facts。

## 当前 value pipeline

当前 draw call lifecycle value pipeline：

1. `CjguiInternalRendererNoEncoderReadiness`
2. `CjguiInternalRendererDrawCallLifecycleIntent`
3. `CjguiInternalRendererDrawCommandShapePolicy`
4. `CjguiInternalRendererGeometrySourcePolicy`
5. `CjguiInternalRendererDrawSequencingGuard`
6. `CjguiInternalRendererNoDrawCallReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft()`
- 只调用 `cjguiInternalExecuteDefaultRendererEncoderLifecycleDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不接 backend / Metal / AppKit implementation。
- 不执行 draw call。
- 不调用 encoder。
- 不绑定 pipeline state。
- 不绑定 vertex / index buffer。
- 不绑定 texture。
- 不提交 GPU work。
- 不创建 command buffer。
- 不创建 render pass。
- 不获取 drawable。
- 不执行 render。
- 不写 renderer state。

## 值语义

`CjguiInternalRendererDrawCallLifecycleIntent` 只表达 future draw call lifecycle intent，不是 draw call implementation、backend readiness、render execution gate、pipeline-state readiness 或 render permission。

`CjguiInternalRendererDrawCommandShapePolicy` 只表达 primitive kind placeholder、instance count placeholder 与 draw command shape facts；它不发 draw command，不调用 encoder，不进入 render execution。

`CjguiInternalRendererGeometrySourcePolicy` 只表达 future vertex / index source policy facts；它不绑定 vertex / index buffer，不绑定 texture，不持有 platform resource。

`CjguiInternalRendererDrawSequencingGuard` 只表达 draw order relation、material grouping hints、sequencing constraints 与 failure / no-draw fallback facts；它不排序、不提交、不执行，不做 draw-call merge 或 GPU batching。

`CjguiInternalRendererNoDrawCallReadiness` 是当前 no-draw-call lifecycle endpoint。Readiness 只表示该 internal value boundary 可以继续评估，不代表任何 side effect permission。

## 关系事实

Draw call 与 encoder / pipeline binding / material grouping / render command packet 的关系只能作为 dehydrated lifecycle facts 表达：

- primitive kind placeholder。
- vertex source policy。
- index source policy。
- instance count placeholder。
- draw order relation。
- material grouping hints as sequencing facts only。
- pipeline binding precondition as guard facts only。
- render command packet relation as value facts only。
- failure / no-draw fallback。
- rollback expectation as value facts only。

## 近线下游接续

当前 native / runtime 主线已由 [绘制调用 no-submit 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-draw-call-no-submit-manifest.md) 接续。该下游只把 pipeline state runtime facts、vertex buffer runtime facts 与 encoder missing / binding blocked / draw blocked facts 聚合成 internal draw input bundle；它不改变本 lifecycle manifest 的 no-draw-call 语义，也不授权 encoder creation、`setRenderPipelineState`、`setVertexBuffer`、draw、commit、present、GPU submission 或 render。

这些 facts 不能携带 `MTLRenderCommandEncoder`、pipeline state object、vertex buffer、index buffer、texture、command buffer、render pass descriptor、drawable、native handle、raw pointer、platform object、backend-local resource token、callback 或 renderer state write。

Primitive kind / vertex-index source / instance count / draw order relation / material grouping hints 只作为 dehydrated lifecycle facts。它们不是 draw-call execution plan、encoder command stream、pipeline binding plan、buffer binding plan、texture binding plan 或 GPU submission plan。

## 显式非 truth

`CjguiInternalRendererNoDrawCallReadiness` 明确不是：

- draw-call permission。
- draw command emission。
- encoder call permission。
- pipeline binding permission。
- resource binding permission。
- vertex / index buffer binding permission。
- texture binding permission。
- GPU submission permission。
- backend readiness。
- backend object readiness。
- render execution permission。
- renderer state write。
- Metal / AppKit implementation。
- `MTLRenderCommandEncoder` ownership。
- pipeline state ownership。
- vertex buffer ownership。
- index buffer ownership。
- texture ownership。
- command buffer ownership。
- render pass ownership。
- native handle / raw pointer surface。
- pipeline state lifecycle owner。
- render execution owner。
- backend-readiness wrapper。
- render-execution readiness wrapper。
- pipeline-state readiness wrapper。
- public API / public C ABI。

当前没有 draw call、encoder call、pipeline binding、buffer binding、texture binding、GPU submission、native handle 或 raw pointer。当前没有 backend implementation 或 render execution。

## 同构边界刹车（Same-shape Boundary Brake）

Same-shape Boundary Brake 在本 manifest 生效。

本轮选择 manifest 封账，明确拒绝：

- draw-call receipt / record / publication。
- backend-readiness wrapper。
- render-execution readiness wrapper。
- pipeline-state readiness wrapper。
- draw permission wrapper。
- render permission wrapper。

`CjguiInternalRendererNoDrawCallReadiness` 已经是当前 no-draw-call lifecycle endpoint。继续新增 receipt / record / publication 或 readiness wrapper 会把同一结果换名包装，缺少新的 owner truth、consumer、lifecycle 或 platform evidence。

若未来靠近 pipeline state / render execution / platform lifecycle，必须先做 docs-only preflight，并引用 [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 的具体 evidence。不得直接实现 draw call、pipeline binding、GPU submission、backend / Metal / AppKit implementation、render execution 或 renderer state write。

## 停止线

继续禁止：

- no runtime code in this manifest round。
- no `.cj` modifications。
- no draw call execution。
- no encoder call。
- no pipeline state binding。
- no vertex / index buffer binding。
- no texture binding。
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
- no pipeline-state readiness wrapper。
- no draw-call receipt / record / publication。
- no observer callback / event bus / telemetry / logging / public diagnostics。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no public surface expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。
- no smoke / harness / native bridge / entry modifications。

## 公共 surface 边界

public symbol allowlist 未变：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本 manifest 不批准第二个 public symbol、不修改 Bool-only signature、不新增 structured public return、不开放 public C ABI。

## 下一阶段候选比较

### 候选 A：`P1 internal Renderer pipeline state lifecycle preflight decision`

推荐为下一阶段 opening。

理由：

- Draw call lifecycle endpoint 已封账后，下一步若继续靠近 backend lifecycle，应先 docs-only 评估 pipeline state owner / lifecycle / readiness runway。
- Pipeline state lifecycle 必须仍保持 no-pipeline-state / no-platform-object / no-render 边界。
- 该 preflight 不创建 pipeline state，不绑定 pipeline，不调用 encoder，不发 draw call，不接 backend implementation。

### 候选 B：`P1 internal Renderer render execution preflight decision`

暂缓。

Render execution 通常应等 pipeline state lifecycle preflight 后再开。当前仍不得靠近 GPU submission、render execution 或 renderer state write。

### 候选 C：draw call lifecycle hardening

暂缓。

只有发现 draw command shape / geometry source / sequencing 表达不足时才选。当前 manifest 未发现硬化缺口。

### 候选 D：backend-readiness preflight revisit

暂缓。

等 pipeline state / render execution lifecycle 进一步拆清后再评估，避免 backend-readiness wrapper。

### 候选 E：draw call / Metal implementation

拒绝。

### 候选 F：render execution / renderer state write

拒绝。

### 候选 G：Metal / AppKit / platform resource / native handle implementation

拒绝。

### 候选 H：Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### 候选 I：public surface expansion

拒绝。

### 候选 J：consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前没有这类 evidence。

## 封账结论

本 manifest 固定 `runtime_renderer_draw_call.cj` owner / truth / canonical endpoint / stop-line，并封账 no-draw-call lifecycle endpoint。

唯一 next opening：

`P1 internal Renderer pipeline state lifecycle preflight decision`

下一轮必须 docs-only，评估 pipeline state owner / lifecycle / readiness runway；不得创建 pipeline state，不得绑定 pipeline，不得调用 encoder，不得执行 draw call，不得创建 command buffer / render pass / drawable / platform object，不得接 backend / Metal / AppKit implementation，不得 render，不得写 renderer state。

## 下游 pipeline state lifecycle preflight

Renderer pipeline state lifecycle preflight 已完成：

- [2026-05-04-p1-renderer-pipeline-state-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-preflight-decision.md)

该 preflight 判定可以打开 pipeline state lifecycle runway，但下一步仍只能是 internal value boundary，不是真实 pipeline state。若下一轮实现，建议 owner 是 `runtime/cjgui/src/runtime_renderer_pipeline_state.cj`，只消费 `CjguiInternalRendererNoDrawCallReadiness`，只输出 pipeline state lifecycle intent / shader function policy / pipeline descriptor policy / pipeline compatibility guard / no-pipeline-state readiness value facts。

Same-shape Boundary Brake 继续生效：不得把 no-draw-call endpoint 包成 pipeline-state receipt / record / publication、backend-readiness wrapper、render-execution readiness wrapper 或 shader-library readiness wrapper；不得创建 pipeline state、pipeline descriptor、shader library / function、encoder、buffer、texture、platform object，不得实现 backend / Metal / AppKit、draw call execution、render execution 或 renderer state write。

## 下游 pipeline state lifecycle value boundary

Renderer pipeline state lifecycle value boundary 已完成：

- [2026-05-04-p1-internal-renderer-pipeline-state-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-pipeline-state-lifecycle-value-boundary-closure-review.md)

该 closure 新增 `runtime/cjgui/src/runtime_renderer_pipeline_state.cj`，只消费 `CjguiInternalRendererNoDrawCallReadiness`。Canonical endpoint 是 `CjguiInternalRendererNoPipelineStateReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateLifecycleDraft()`。

该 downstream owner 的新增语义是 shader role / descriptor policy / material-key and render-pass compatibility / no-pipeline-state readiness，不是 draw-call endpoint 的 receipt / record / publication。下一步必须先 docs-only 做 pipeline state lifecycle closure / next-boundary decision，决定是否 manifest stabilization；不批准直接进入 real pipeline state、shader library lifecycle、backend-readiness wrapper、render execution 或 renderer state write。

Renderer pipeline state lifecycle next-boundary decision 已完成：

- [2026-05-04-p1-renderer-pipeline-state-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoPipelineStateReadiness` 已足够作为当前 no-pipeline-state endpoint，并选择下一步 docs-only manifest stabilization；继续拒绝 pipeline-state receipt / record / publication、backend-readiness wrapper、render-execution readiness wrapper、pipeline state / Metal implementation、render execution 或 renderer state write。

## 下游 pipeline state lifecycle manifest

Renderer pipeline state lifecycle manifest stabilization 已完成：

- [2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md)
- [2026-05-04-p1-internal-renderer-pipeline-state-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-pipeline-state-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime_renderer_pipeline_state.cj` owner / truth / canonical endpoint / stop-line，并确认 `CjguiInternalRendererNoPipelineStateReadiness` 是当前 no-pipeline-state lifecycle endpoint。下一步只能 docs-only 进入 render execution preflight；不批准 pipeline-state receipt / record / publication、backend-readiness wrapper、render-execution readiness wrapper、shader library implementation、pipeline state implementation 或 renderer state write。

## 下游 render execution preflight

Renderer render execution preflight 已完成：

- [2026-05-04-p1-renderer-render-execution-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-preflight-decision.md)

该 preflight 只允许从 `CjguiInternalRendererNoPipelineStateReadiness` 进入 render execution no-op value boundary runway；draw call manifest 只作为 docs evidence，说明 draw command shape / geometry source / sequencing facts 如何进入 execution ordering vocabulary。它不批准 draw call execution、encoder call、pipeline binding、buffer binding、texture binding、GPU submission、backend implementation、render execution implementation 或 renderer state write。

## 下游 draw call implementation preflight

Renderer draw call implementation preflight 已完成：

- [2026-05-06-p1-renderer-draw-call-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-preflight-decision.md)

该 decision 引用本 manifest 的 draw command shape、geometry source、instance count、draw order relation 与 material grouping hints 作为 docs evidence，但不把 `CjguiInternalRendererNoDrawCallReadiness` 包成 draw-call implementation receipt / record / publication、draw-ready permission wrapper、primitive-command permission wrapper、geometry-binding permission wrapper、resource-binding permission wrapper、pipeline-binding permission wrapper、GPU-submission wrapper 或 render-permission wrapper。

该 decision 选择下一步进入 internal value boundary / implementation admission facts。下一步 runtime input candidate 只能消费 `CjguiInternalRendererNoPipelineStateImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()`；output truth 仅限 draw call implementation intent / primitive command admission policy / geometry binding admission guard / draw ordering admission policy / no-draw-call-implementation readiness value facts。它仍不批准 draw call、`drawPrimitives` / `drawIndexedPrimitives`、vertex / index buffer binding、texture / sampler / resource binding、pipeline binding、encoder、command buffer、GPU submission、render、renderer state write 或 public API permission。

## 下游 draw call implementation admission value boundary

Renderer draw call implementation admission value boundary 已完成：

- [2026-05-06-p1-internal-renderer-draw-call-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-draw-call-implementation-admission-value-boundary-closure-review.md)

该 closure 新增 [runtime_renderer_draw_call_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_call_admission.cj)，但不把本 manifest 的 `CjguiInternalRendererNoDrawCallReadiness` 包成 draw-call implementation receipt / record / publication 或 draw-ready permission wrapper。`CjguiInternalRendererNoDrawCallReadiness` 仍只是 lifecycle vocabulary evidence。

新增 owner 只消费 pipeline state implementation admission endpoint，输出 `CjguiInternalRendererNoDrawCallImplementationReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()`。新增 truth 是 primitive command admission / geometry binding admission / draw ordering admission / no-draw-call-implementation value facts；仍不批准 draw call、primitive command invocation、geometry / resource binding、pipeline binding、GPU submission、render、renderer state write 或 public API permission。

## 下游 draw call implementation admission next-boundary decision

Renderer draw call implementation admission next-boundary decision 已完成：

- [2026-05-06-p1-renderer-draw-call-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-admission-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoDrawCallImplementationReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()` 足够作为当前 no-draw-call-implementation endpoint。`CjguiInternalRendererNoDrawCallReadiness` 继续只作为 lifecycle vocabulary evidence，不被包装成 draw-ready permission、implementation receipt / record / publication、GPU-submission wrapper 或 render-permission wrapper。

下一步只能 docs-only 固定 draw call implementation admission owner / truth / canonical endpoint / stop-line；不批准真实 draw call、resource binding、pipeline binding、encoder、command buffer、GPU submission、render、renderer state write 或 public API permission。

## 下游 draw call implementation admission manifest

Renderer draw call implementation admission manifest stabilization 已完成：

- [2026-05-06-p1-renderer-draw-call-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-draw-call-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-draw-call-implementation-admission-manifest-stabilization-closure-review.md)

该 manifest 固定 no-draw-call-implementation endpoint。`CjguiInternalRendererNoDrawCallReadiness` 继续只作为 lifecycle vocabulary evidence，不是本 owner 的 runtime input，也不被包装成 draw-ready permission、implementation receipt / record / publication、GPU-submission wrapper 或 render-permission wrapper。

新的唯一后续入口是 docs-only `P1 internal Renderer render execution implementation preflight decision`。下一步仍不批准真实 draw call、resource binding、pipeline binding、encoder、command buffer、GPU submission、render、renderer state write 或 public API permission。

## 下游真实 draw call 第一切片

Renderer real draw call first-slice macro 已完成：

- [real draw call first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-draw-call-first-implementation-preflight-decision.md)
- [real draw call first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-draw-call-first-implementation-slice-closure-review.md)
- [real draw call first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-draw-call-first-implementation-slice-manifest.md)

该 first slice 使用 `CjguiInternalRendererNoRealPipelineStateShellReadiness` 作为 runtime input，不复用本 lifecycle manifest 的 `CjguiInternalRendererNoDrawCallReadiness`。本 lifecycle manifest 仍只是 vocabulary evidence，不是 draw-ready permission、primitive command permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

## 验证记录

验证结果记录在 [2026-05-04-p1-internal-renderer-draw-call-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-draw-call-lifecycle-manifest-stabilization-closure-review.md)。
