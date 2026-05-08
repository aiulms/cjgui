# P1 Renderer render pass implementation admission manifest 封账

日期：2026-05-06

状态：docs-only manifest stabilization

## 封账结论

本 manifest 固定 [runtime_renderer_render_pass_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_pass_admission.cj) 的 owner、truth、canonical endpoint、default draft、stop-line 与 Same-shape Boundary Brake。

本轮只做文档封账：不修改任何 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本 manifest 不批准创建 render pass descriptor，不批准创建 attachment object / texture / drawable，不批准创建 encoder / pipeline state / command buffer，不批准调用 `renderCommandEncoder`、`commandBuffer`、`commit`、`present` 或 `nextDrawable`，不批准 native handle / raw pointer、C ABI、FFI declaration、bridge call、retain / release / destroy、Metal / AppKit / Objective-C / FFI、GPU submission、render execution、renderer state write 或 public API expansion。

后续若新增任何 `.cj` owner file，仍必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释，且注释不得引入真实 implementation permission。

## 固定 owner

Owner 文件：

- [runtime_renderer_render_pass_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_pass_admission.cj)

唯一 runtime input：

- `CjguiInternalRendererNoRealCommandBufferImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererRealCommandBufferAdmissionDraft()`

Canonical endpoint 固定为：

- `CjguiInternalRendererNoRenderPassImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererRenderPassAdmissionDraft()`

默认 draft：

- `cjguiInternalExecuteDefaultRendererRenderPassAdmissionDraft()` 先从 `cjguiInternalExecuteDefaultRendererRealCommandBufferAdmissionDraft()` 获取 `CjguiInternalRendererNoRealCommandBufferImplementationReadiness`。
- 它只构造 render pass implementation intent、attachment admission policy、load-store admission guard、clear-color target admission policy 与 no-render-pass-implementation readiness value facts。
- 它不创建 render pass descriptor，不创建 attachment object / texture / drawable，不创建 encoder / pipeline state / command buffer。
- 它不调用 `renderCommandEncoder`、`commandBuffer`、`commit`、`present` 或 `nextDrawable`。
- 它不创建 native handle / raw pointer，不新增 C ABI / FFI declaration，不调用 bridge / retain / release / destroy / Metal / AppKit / Objective-C / FFI。
- 它不提交 GPU work，不执行 render，不写 renderer state，不修改 bridge / smoke / harness / native entry，不扩 public API。

## 当前 truth

Current truth 仅限：

- render pass implementation intent value facts。
- attachment admission policy value facts。
- load-store admission guard value facts。
- clear-color target admission policy value facts。
- no-render-pass-implementation readiness value facts。

Canonical value chain 是：

1. `CjguiInternalRendererNoRealCommandBufferImplementationReadiness`
2. `CjguiInternalRendererRenderPassImplementationIntent`
3. `CjguiInternalRendererRenderPassAttachmentAdmissionPolicy`
4. `CjguiInternalRendererRenderPassLoadStoreAdmissionGuard`
5. `CjguiInternalRendererRenderPassClearColorTargetAdmissionPolicy`
6. `CjguiInternalRendererNoRenderPassImplementationReadiness`

## value 语义

`CjguiInternalRendererRenderPassImplementationIntent` 只记录未来 render pass implementation intent facts，并确认下一步需要 attachment admission、load-store admission 与 clear-color target admission。它不是 render-pass-ready permission、backend implementation permission、GPU submission permission、render permission 或 public API permission。

`CjguiInternalRendererRenderPassAttachmentAdmissionPolicy` 只记录 attachment admission facts、target relation facts 与 no pass platform resource facts。它不创建 render pass descriptor、attachment object、texture 或 drawable，也不接外部 surface。

`CjguiInternalRendererRenderPassLoadStoreAdmissionGuard` 只记录 load-store admission facts。它不执行 load / store，不绑定 attachment，不构造 stage entry，也不表达 render permission。

`CjguiInternalRendererRenderPassClearColorTargetAdmissionPolicy` 只记录 clear-color target admission facts、size relation facts 与 color relation facts。它不查询真实 screen / layer / color space，不创建 target texture。

`CjguiInternalRendererNoRenderPassImplementationReadiness` 封住当前 no-render-pass-implementation readiness facts。它不是 render pass descriptor permission、attachment permission、texture permission、encoder permission、command buffer permission、native handle permission、C ABI permission、FFI permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

## 关系事实

Render pass implementation admission facts 只把上游 no-real-command-buffer-implementation endpoint 作为 runtime input：

- `CjguiInternalRendererNoRealCommandBufferImplementationReadiness` 是唯一 runtime input。
- [real command buffer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-command-buffer-implementation-admission-manifest.md) 只提供 no-real-command-buffer-implementation endpoint，不授予 render pass、encoder、command buffer、`commit`、GPU submission、render 或 public API permission。
- [render pass lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md) 只作为 render pass lifecycle vocabulary evidence；`CjguiInternalRendererNoRenderPassReadiness` 不是本 owner 的 runtime input。
- [render pass implementation preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-pass-implementation-preflight-decision.md) 已把下一刀限定为 value-only implementation admission facts，不是真实 render pass implementation。
- [render pass implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-pass-implementation-admission-next-boundary-decision.md) 已确认当前 endpoint 足够，不需要继续包装 tail wrapper。
- [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md) 继续约束后续 Markdown 中文写作和 `.cj` owner 文件头维护注释。

## 明确的非 truth

`CjguiInternalRendererNoRenderPassImplementationReadiness` 不是：

- render pass descriptor permission。
- render-pass-ready permission。
- attachment permission。
- attachment object creation permission。
- texture permission。
- drawable permission。
- encoder permission。
- `renderCommandEncoder` permission。
- command buffer permission。
- `commandBuffer` permission。
- `commit` permission。
- `present` permission。
- `nextDrawable` permission。
- native handle permission。
- raw pointer permission。
- C ABI permission。
- FFI permission。
- bridge call permission。
- retain / release / destroy permission。
- Metal / AppKit / Objective-C permission。
- GPU submission permission。
- render execution permission。
- backend implementation permission。
- renderer state write permission。
- diagnostics / event bus / observer / telemetry permission。
- public API / public C ABI permission。

当前 truth 没有 render pass descriptor、没有 attachment object、没有 texture、没有 drawable、没有 encoder、没有 pipeline state、没有 command buffer、没有 native handle、没有 raw pointer、没有 C ABI、没有 FFI declaration、没有 bridge call、没有 GPU work、没有 render work、没有 renderer state mutation，也没有外部 API surface。

## 同构边界刹车

本轮是 manifest 封账，明确拒绝：

- render-pass-ready permission wrapper。
- attachment permission wrapper。
- texture permission wrapper。
- encoder permission wrapper。
- command-buffer permission wrapper。
- native-handle permission wrapper。
- C-ABI / FFI permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。
- renderer-state-write wrapper。
- receipt / record / publication。

`CjguiInternalRendererNoRenderPassImplementationReadiness` 不得继续包装成新的 tail wrapper，除非未来 docs-only preflight 证明存在新的 owner / lifecycle / teardown / failure / verification 语义，并且这些语义没有被本 manifest 捕获。

未来靠近 encoder implementation、pipeline implementation、render pass attachment admission hardening、load-store admission hardening、render target size-color admission、真实 render pass descriptor / encoder、GPU submission 或 renderer state write，必须先通过 docs-only preflight。

## 停止线

在后续 docs-only preflight 明确打开更窄 runway 前：

- 不修改 `.cj`。
- 不触碰 `runtime_state.cj`。
- 不触碰 `runtime/cjgui/cjpm.toml`。
- 不触碰 smoke / harness / native bridge / entry。
- 不触碰 AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- 不创建 render pass descriptor。
- 不创建 attachment object。
- 不创建 texture。
- 不获取 drawable。
- 不创建 encoder。
- 不创建 pipeline state。
- 不创建 command buffer。
- 不调用 `renderCommandEncoder`。
- 不调用 `commandBuffer`。
- 不调用 `commit`。
- 不调用 `present`。
- 不调用 `nextDrawable`。
- 不创建 native handle。
- 不创建 raw pointer。
- 不新增 C ABI。
- 不新增 FFI declaration。
- 不调用 bridge。
- 不调用 retain / release / destroy。
- 不调用 Metal / AppKit / Objective-C / FFI。
- 不提交 GPU work。
- 不执行 render。
- 不写 renderer state。
- 不扩 public API。
- 不新增 module-level `var`。

## 公共 surface

Public declaration allowlist 仍保持：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

## 下一阶段候选

### 候选 A：推荐 encoder implementation preflight

推荐下一步：

`P1 internal Renderer encoder implementation preflight decision`

理由：render pass implementation admission 已封账为 no-render-pass-implementation endpoint。下一步可以 docs-only 评估 encoder implementation admission runway、`renderCommandEncoder` stop-line、pipeline relation 与 no-encoder-implementation facts，但仍不得创建 encoder，不得调用 `renderCommandEncoder`，不得创建 pipeline state，不得提交 GPU work。

### 候选 B：暂缓 pipeline implementation preflight

Pipeline implementation 更靠近 shader function、pipeline descriptor、pipeline state creation 与 encoder binding，应晚于 encoder implementation preflight。

### 候选 C：暂缓 render pass attachment admission hardening

`RenderPassAttachmentAdmissionPolicy` 已表达 no render pass descriptor、no attachment object、no texture、no drawable facts。只有未来 review 发现 attachment relation 表达不足时才选择 hardening。

### 候选 D：暂缓 render pass load-store admission hardening

`RenderPassLoadStoreAdmissionGuard` 已表达 no load / store execution、no attachment binding 与 no stage entry facts。当前不需要引入 hardening owner。

### 候选 E：暂缓 render target size-color admission hardening

`RenderPassClearColorTargetAdmissionPolicy` 已表达 no display lookup、no color lookup 与 no target image built facts。只有未来靠近真实 screen / layer / color space 或 target texture 时才需要更窄 preflight。

### 候选 F 到 R：拒绝直接实现或发布

拒绝 direct render pass descriptor implementation、direct attachment / texture implementation、direct `renderCommandEncoder` call、direct encoder / pipeline implementation、direct command buffer / commit implementation、direct drawable acquisition / present implementation、direct native handle / raw pointer implementation、direct C ABI / FFI declaration、direct Metal / AppKit / Objective-C implementation、GPU submission / render execution、renderer state write、public API / C ABI expansion、receipt / record / publication。

### 候选 S：仅限明确重复时 consolidation

只有出现明确 duplicate / self-wrapping evidence 时才选择 consolidation。当前 evidence 指向 downstream encoder implementation preflight，而不是删除或合并。

## 封账决定

`runtime/cjgui/src/runtime_renderer_render_pass_admission.cj` 是当前 no-render-pass-implementation endpoint 的固定 owner。

`CjguiInternalRendererNoRenderPassImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderPassAdmissionDraft()` 是 render pass implementation admission value facts 的 canonical tail。它不授予 render pass descriptor、attachment、texture、encoder、command buffer、native handle、C ABI、FFI、GPU submission、render、renderer state write 或 public API permission。

下游 encoder implementation preflight 已记录在：

- [2026-05-06-p1-renderer-encoder-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-preflight-decision.md)

该 preflight 只把本 manifest 固定的 `CjguiInternalRendererNoRenderPassImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderPassAdmissionDraft()` 作为唯一 runtime input candidate。`CjguiInternalRendererNoEncoderReadiness`、`CjguiInternalRendererNoRealCommandBufferImplementationReadiness` 与 backend / Metal reference evidence 只能作为 docs evidence。

该 preflight 选择下一步进入 value-only encoder implementation admission boundary。Output truth 仅限 encoder implementation intent / encoder creation admission policy / encoding scope admission guard / end-encoding admission policy / no-encoder-implementation readiness value facts；仍不批准 encoder creation、`renderCommandEncoder`、`endEncoding`、pipeline / buffer / texture / resource binding、command buffer、`commit`、drawable acquisition、GPU submission、render / draw call、renderer state write 或 public API permission。

下游 encoder implementation admission value boundary 已记录在：

- [2026-05-06-p1-internal-renderer-encoder-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-encoder-implementation-admission-value-boundary-closure-review.md)
- [runtime_renderer_encoder_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_encoder_admission.cj)

该 owner 只消费本 manifest 固定的 `CjguiInternalRendererNoRenderPassImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderPassAdmissionDraft()`，canonical endpoint 是 `CjguiInternalRendererNoEncoderImplementationReadiness` / `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()`。它只表达 encoder implementation admission value facts，不批准真实 encoder creation、外部编码 API、resource binding、command buffer、GPU submission、render / draw call、renderer state write 或 public API。

下游 encoder implementation admission next-boundary decision 已记录在：

- [2026-05-06-p1-renderer-encoder-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-admission-next-boundary-decision.md)

该 decision 确认 no-encoder-implementation endpoint 足够封账，并选择下一步进入 docs-only manifest stabilization，不允许继续包装成 encoder-ready permission wrapper 或外部编码 API permission。

下游 encoder implementation admission manifest stabilization 已记录在：

- [2026-05-06-p1-renderer-encoder-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-encoder-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-encoder-implementation-admission-manifest-stabilization-closure-review.md)

该 manifest 只把本 manifest 固定的 no-render-pass-implementation endpoint 作为 runtime input evidence，并封账为 no-encoder-implementation endpoint；仍不批准 encoder creation、`renderCommandEncoder`、`endEncoding`、pipeline / buffer / texture / resource binding、GPU submission、render 或 renderer state write。

下游 pipeline state implementation preflight 已记录在：

- [2026-05-06-p1-renderer-pipeline-state-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-preflight-decision.md)

该 preflight 将本 manifest 作为 render pass / target relation evidence，但 runtime input candidate 只消费 encoder implementation admission manifest 固定的 `CjguiInternalRendererNoEncoderImplementationReadiness`。它仍不批准 pipeline state、shader library / shader function、pipeline descriptor、pipeline binding、encoder、command buffer、GPU submission、render 或 renderer state write。

下游 pipeline state implementation admission value boundary 已记录在：

- [2026-05-06-p1-internal-renderer-pipeline-state-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-pipeline-state-implementation-admission-value-boundary-closure-review.md)
- [runtime_renderer_pipeline_state_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_admission.cj)

该 owner 只把本 manifest 作为 render pass / target relation evidence，不消费本 manifest endpoint。Runtime input 仍是 `CjguiInternalRendererNoEncoderImplementationReadiness` / `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()`，canonical endpoint 是 `CjguiInternalRendererNoPipelineStateImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()`。

新的唯一后续入口：

`P1 internal Renderer pipeline state implementation admission closure / next pipeline state implementation decision`

## 下游 real render pass 第一刀切片

后续 real render pass first-slice macro 已记录在：

- [real render pass first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-render-pass-first-implementation-preflight-decision.md)
- [real render pass first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-render-pass-first-implementation-slice-closure-review.md)
- [real render pass first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-render-pass-first-implementation-slice-next-boundary-decision.md)
- [real render pass first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-render-pass-first-implementation-slice-manifest.md)

该 downstream 只把本 manifest 的 no-render-pass-implementation facts 作为 docs evidence，不消费 `CjguiInternalRendererNoRenderPassImplementationReadiness`。新的 runtime input 是 `CjguiInternalRendererNoRealCommandBufferShellReadiness`，canonical endpoint 是 `CjguiInternalRendererNoRealRenderPassShellReadiness` / `cjguiInternalExecuteDefaultRendererRealRenderPassShellDraft()`；它不改变本 manifest 的 no-render-pass-implementation endpoint，也不批准真实 render pass descriptor、attachment、texture view、encoder、`renderCommandEncoder`、`endEncoding`、GPU submission、render、renderer state write 或 public API。
