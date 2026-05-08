# P1 渲染器 encoder lifecycle manifest

日期：2026-05-03

状态：manifest stabilization

## 用途

本 manifest 固定 `runtime_renderer_encoder.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-encoder lifecycle endpoint。

它不是 encoder implementation manifest，也不是 draw-call readiness manifest、pipeline-state readiness manifest 或 backend-readiness manifest。它只记录 encoder lifecycle intent、encoding scope policy、pipeline binding guard、end-encoding policy 与 no-encoder readiness 的 internal value facts。

## Owner 与 truth

Owner 文件：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_encoder.cj`

Canonical upstream endpoint 固定为：

- `CjguiInternalRendererNoRenderPassReadiness`
- `cjguiInternalExecuteDefaultRendererRenderPassLifecycleDraft()`

Canonical endpoint 固定为：

- `CjguiInternalRendererNoEncoderReadiness`
- `cjguiInternalExecuteDefaultRendererEncoderLifecycleDraft()`

当前 truth：

- encoder lifecycle intent value facts。
- encoding scope policy value facts。
- pipeline binding guard value facts。
- end-encoding policy value facts。
- no-encoder readiness value facts。

## 当前 pipeline

当前 encoder lifecycle value pipeline：

1. `CjguiInternalRendererNoRenderPassReadiness`
2. `CjguiInternalRendererEncoderLifecycleIntent`
3. `CjguiInternalRendererEncodingScopePolicy`
4. `CjguiInternalRendererPipelineBindingGuard`
5. `CjguiInternalRendererEndEncodingPolicy`
6. `CjguiInternalRendererNoEncoderReadiness`

默认 draft：

- `cjguiInternalExecuteDefaultRendererEncoderLifecycleDraft()`
- 只调用 `cjguiInternalExecuteDefaultRendererRenderPassLifecycleDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不接 backend / Metal / AppKit implementation。
- 不创建 encoder。
- 不 begin encoding。
- 不绑定 pipeline / resources。
- 不设置 viewport / scissor platform state。
- 不 end encoding。
- 不发 draw call。
- 不创建 render pass descriptor。
- 不创建 command buffer。
- 不获取 drawable。
- 不执行 render。
- 不写 renderer state。

## Value 语义

`CjguiInternalRendererEncoderLifecycleIntent` 只表达 future encoder lifecycle intent，不是 encoder implementation、backend readiness、draw-call readiness、pipeline-state readiness 或 render permission。

`CjguiInternalRendererEncodingScopePolicy` 只表达 future encoding scope、command sequencing boundary、viewport / scissor placeholder 与 failure / no-draw fallback facts；它不 begin encoding，不设置 viewport / scissor platform state，不 encode command，不写 renderer state。

`CjguiInternalRendererPipelineBindingGuard` 只表达 future pipeline / resource binding preconditions；它不绑定 pipeline，不绑定 resources，不创建 pipeline state，不发 draw call。

`CjguiInternalRendererEndEncodingPolicy` 只表达 future end-encoding boundary、post-encoding invalidation 与 failure rollback facts；它不 end encoding，不提交 command buffer，不触发 completion / presentation。

`CjguiInternalRendererNoEncoderReadiness` 是当前 no-encoder lifecycle endpoint。Readiness 只表示该 internal value boundary 可以继续评估，不代表任何 side effect permission。

## 关系事实

Encoder 与 render pass / command buffer / draw call / pipeline state 的关系只能作为 dehydrated lifecycle facts 表达：

- render-pass upstream gate relation。
- command-buffer target relation as value facts only。
- encoding scope。
- command sequencing guard。
- pipeline binding intent。
- resource binding placeholder。
- viewport / scissor placeholder。
- end-encoding boundary。
- post-encoding invalidation。
- failure / no-draw fallback。
- rollback expectation as value facts only。

这些 facts 不能携带 `MTLRenderCommandEncoder`、pipeline state object、draw command object、`MTLRenderPassDescriptor`、command buffer、drawable、texture、attachment object、native handle、raw pointer、platform object、backend-local resource token、callback 或 renderer state write。

## 明确非事实

`CjguiInternalRendererNoEncoderReadiness` 明确不是：

- encoder permission。
- encoder creation。
- begin-encoding permission。
- end-encoding permission。
- pipeline binding permission。
- resource binding permission。
- viewport / scissor state setting。
- draw-call permission。
- draw command sequencing implementation。
- backend readiness。
- backend object readiness。
- platform object readiness。
- render pass descriptor ownership。
- command buffer permission。
- drawable permission。
- pipeline state ownership。
- render permission。
- render execution。
- renderer state write。
- Metal / AppKit implementation。
- `MTLRenderCommandEncoder` ownership。
- native handle / raw pointer surface。
- draw call lifecycle owner。
- pipeline state lifecycle owner。
- backend-readiness wrapper。
- render execution gate。
- draw call。
- GPU batching。
- public API / public C ABI。

当前没有 `MTLRenderCommandEncoder`、pipeline state、draw call、render pass descriptor、command buffer、drawable、texture、attachment object、native handle 或 raw pointer。当前没有 backend implementation、render execution 或 renderer state write。

## 同构边界刹车（Same-shape Boundary Brake）

Same-shape Boundary Brake 在本 manifest 生效。

本轮选择 manifest 封账，明确拒绝：

- encoder receipt / record / publication。
- backend-readiness wrapper。
- draw-call readiness wrapper。
- pipeline-state readiness wrapper。
- encoder permission wrapper。
- render permission wrapper。

`CjguiInternalRendererNoEncoderReadiness` 已经是当前 no-encoder lifecycle endpoint。继续新增 receipt / record / publication 或 readiness wrapper 会把同一结果换名包装，缺少新的 owner truth、consumer、lifecycle 或 platform evidence。

若未来靠近 draw call / pipeline state / platform lifecycle，必须先做 docs-only preflight，并引用 [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 的具体 evidence。

## 停止线（Stop-line）

继续禁止：

- no runtime code in this manifest round。
- no `.cj` modifications。
- no encoder creation。
- no render command encoder creation。
- no begin encoding。
- no pipeline state binding。
- no resource binding。
- no viewport / scissor platform state setting。
- no end encoding。
- no draw call。
- no render pass descriptor creation。
- no command buffer creation。
- no drawable acquisition。
- no backend / Metal / AppKit implementation。
- no platform resource implementation。
- no render execution。
- no GPU batching / draw-call merge。
- no sorting side effect。
- no packet mutation。
- no renderer state write。
- no native handle / raw pointer / platform object。
- no backend-readiness wrapper。
- no draw-call readiness wrapper。
- no encoder receipt / record / publication。
- no observer callback / event bus / telemetry / logging / public diagnostics。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no public surface expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。
- no smoke / harness / native bridge / entry modifications。

## 公共 surface

public symbol allowlist 未变：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本 manifest 不批准第二个 public symbol、不修改 Bool-only signature、不新增 structured public return、不开放 public C ABI。

## 下一阶段候选比较

### A. P1 internal Renderer draw call lifecycle preflight decision 推荐

推荐为下一阶段 opening。

理由：

- Encoder lifecycle endpoint 已封账后，下一步若继续靠近 backend lifecycle，应先 docs-only 评估 draw call owner / lifecycle / readiness runway。
- Draw call lifecycle 必须仍保持 no-draw-call / no-render / no-platform-object 边界。
- 该 preflight 不创建 encoder，不绑定 pipeline state，不绑定 resources，不发 draw call，不接 backend implementation。

### B. P1 internal Renderer pipeline state lifecycle preflight decision 暂缓

暂缓。

Pipeline state lifecycle 通常应等 draw call lifecycle preflight 后再拆。当前仍不得靠近 pipeline object creation、shader state、resource binding implementation 或 GPU submission。

### C. Encoder lifecycle hardening 暂缓

暂缓。

只有发现 encoding scope / pipeline binding guard / end-encoding 表达不足时才选。当前 manifest 未发现硬化缺口。

### D. Backend-readiness preflight revisit 暂缓

暂缓。

Backend-readiness 仍太容易变成 wrapper。等 draw call / pipeline state lifecycle 进一步拆清后再评估。

### E. Encoder / Metal implementation 拒绝

拒绝。

### F. Render execution / renderer state write / draw call implementation 拒绝

拒绝。

### G. Metal / AppKit / platform resource / native handle implementation 拒绝

拒绝。

### H. Dirty-region / Widget / Layout / Text / IME / Accessibility 暂缓

暂缓。

### I. Public surface expansion 拒绝

拒绝。

### J. Consolidation 暂缓

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前没有这类 evidence。

## 封账决定

本 manifest 固定 `runtime_renderer_encoder.cj` owner / truth / canonical endpoint / stop-line，并封账 no-encoder lifecycle endpoint。

唯一 next opening：

`P1 internal Renderer draw call lifecycle preflight decision`

下一轮必须 docs-only，不得创建 encoder，不得绑定 pipeline state，不得绑定 resources，不得发 draw call，不得创建 command buffer / render pass / drawable / platform object，不得接 backend / Metal / AppKit implementation，不得 render，不得写 renderer state。

## 下游 draw call lifecycle preflight

Renderer draw call lifecycle preflight 已完成：

- [2026-05-03-p1-renderer-draw-call-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-draw-call-lifecycle-preflight-decision.md)

该 preflight 判定可以打开 draw call lifecycle runway，但下一步仍只能是 internal value boundary，不是真实 draw call。若下一轮实现，建议 owner 是 `runtime/cjgui/src/runtime_renderer_draw_call.cj`，只消费 `CjguiInternalRendererNoEncoderReadiness`，只输出 draw call lifecycle intent / draw command shape policy / geometry source policy / draw sequencing guard / no-draw-call readiness value facts。

Same-shape Boundary Brake 继续生效：不得把 no-encoder endpoint 包成 draw-call receipt / record / publication、backend-readiness wrapper、pipeline-state readiness wrapper 或 render permission wrapper；不得执行 draw call、调用 encoder、绑定 pipeline state、绑定 vertex / index buffer、绑定 texture、创建 command buffer / render pass / drawable / platform object，不得实现 backend / Metal / AppKit、render execution 或 renderer state write。

## 下游 draw call lifecycle value boundary

Renderer draw call lifecycle value boundary 已完成：

- [2026-05-03-p1-internal-renderer-draw-call-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-draw-call-lifecycle-value-boundary-closure-review.md)

新增 owner 是 `runtime/cjgui/src/runtime_renderer_draw_call.cj`，只消费 `CjguiInternalRendererNoEncoderReadiness`，canonical endpoint 是 `CjguiInternalRendererNoDrawCallReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft()`。Same-shape Boundary Brake 通过 draw command shape / geometry source / sequencing / no-draw-call readiness 语义生效，不是 no-encoder receipt / record / publication wrapper。

唯一 next opening：

`P1 internal Renderer draw call lifecycle closure / next draw call decision`

## 下游 draw call lifecycle next decision

Renderer draw call lifecycle next-boundary decision 已完成：

- [2026-05-04-p1-renderer-draw-call-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-next-boundary-decision.md)

该 decision 判定 `CjguiInternalRendererNoDrawCallReadiness` 已足够作为当前 no-draw-call endpoint；下一步选择 draw call lifecycle manifest stabilization，继续拒绝 draw-call receipt / record / publication、backend-readiness wrapper、pipeline-state readiness wrapper、render execution wrapper 或真实 draw call / Metal implementation。

## 下游 draw call lifecycle manifest

Renderer draw call lifecycle manifest stabilization 已完成：

- [2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md)
- [2026-05-04-p1-internal-renderer-draw-call-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-draw-call-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 固定 draw call lifecycle owner / truth / canonical endpoint / stop-line。`CjguiInternalRendererNoDrawCallReadiness` 仍只是 no-draw-call lifecycle endpoint，不是 pipeline binding permission、render execution permission、backend readiness 或 renderer state write。

## 下游 pipeline state lifecycle preflight

Renderer pipeline state lifecycle preflight 已完成：

- [2026-05-04-p1-renderer-pipeline-state-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-preflight-decision.md)

该 preflight 只允许下一步 internal value boundary，表达 pipeline state lifecycle intent / shader function policy / pipeline descriptor policy / pipeline compatibility guard / no-pipeline-state readiness value facts。它不批准 `MTLRenderPipelineState` / `MTLRenderPipelineDescriptor` creation、shader library / function resolution、pipeline binding、encoder call、draw call execution、backend implementation、render execution 或 renderer state write。

## 下游 render execution preflight

Renderer render execution preflight 已完成：

- [2026-05-04-p1-renderer-render-execution-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-preflight-decision.md)

该 preflight 将 encoder lifecycle manifest 作为 docs evidence：encoding scope、pipeline binding guard、end-encoding policy 与 no-encoder facts 只能进入 render execution ordering / no-submit / completion observation vocabulary，不是 encoder call、end encoding permission、draw call permission、backend implementation、render execution implementation 或 renderer state write。

## 下游 encoder implementation preflight

Renderer encoder implementation preflight 已完成：

- [2026-05-06-p1-renderer-encoder-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-preflight-decision.md)

该 preflight 将本 manifest 作为 encoder lifecycle vocabulary evidence：encoding scope、pipeline binding guard、end-encoding policy 与 no-encoder facts 只能进入 encoder implementation admission vocabulary。`CjguiInternalRendererNoEncoderReadiness` 不是本轮 runtime input，也不是 encoder permission、`renderCommandEncoder` permission、`endEncoding` permission、pipeline-binding permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

下游 encoder implementation admission value boundary 已完成：

- [2026-05-06-p1-internal-renderer-encoder-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-encoder-implementation-admission-value-boundary-closure-review.md)
- [runtime_renderer_encoder_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_encoder_admission.cj)

该 owner 只将本 manifest 作为 vocabulary evidence，runtime input 仍只消费 `CjguiInternalRendererNoRenderPassImplementationReadiness`。`CjguiInternalRendererNoEncoderReadiness` 未升级为 encoder implementation permission，也未成为 runtime input。

下游 encoder implementation admission next-boundary decision 已完成：

- [2026-05-06-p1-renderer-encoder-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-admission-next-boundary-decision.md)

该 decision 继续确认本 manifest 只是 encoder lifecycle vocabulary evidence。`CjguiInternalRendererNoEncoderReadiness` 不是 encoder implementation permission，也不能被包装成 `renderCommandEncoder` / `endEncoding` / pipeline-binding permission wrapper。

下游 encoder implementation admission manifest stabilization 已完成：

- [2026-05-06-p1-renderer-encoder-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-encoder-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-encoder-implementation-admission-manifest-stabilization-closure-review.md)

该 manifest 只将本 manifest 作为 lifecycle vocabulary evidence。`CjguiInternalRendererNoEncoderReadiness` 仍不是 implementation runtime input，也不是 encoder、`renderCommandEncoder`、`endEncoding`、pipeline binding、GPU submission、render 或 renderer state write permission。

新的 downstream opening：

`P1 internal Renderer pipeline state implementation preflight decision`

## 下游 real encoder 第一刀

real encoder first-slice macro 已完成：

- [real render pass branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-render-pass-branch-next-boundary-decision.md)
- [real encoder first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-encoder-first-implementation-preflight-decision.md)
- [real encoder first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-encoder-first-implementation-slice-closure-review.md)
- [real encoder first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-encoder-first-implementation-slice-manifest.md)
- [real encoder first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-encoder-first-implementation-slice-manifest-stabilization-closure-review.md)

该 downstream 不把 `CjguiInternalRendererNoEncoderReadiness` 包装成真实 encoder readiness，也不把 lifecycle facts 当作 `renderCommandEncoder`、`endEncoding`、pipeline binding、GPU submission、render 或 renderer state write permission。real encoder first slice 的 runtime input 是 `CjguiInternalRendererNoRealRenderPassShellReadiness`，canonical endpoint 是 `CjguiInternalRendererNoRealEncoderShellReadiness` / `cjguiInternalExecuteDefaultRendererRealEncoderShellDraft()`。
