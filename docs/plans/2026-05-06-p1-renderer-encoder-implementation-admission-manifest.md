# P1 渲染器编码器实现准入 manifest 封账

日期：2026-05-06

状态：docs-only manifest stabilization

## 封账结论

本 manifest 固定 [runtime_renderer_encoder_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_encoder_admission.cj) 的 owner、truth、canonical endpoint、default draft、runtime input、stop-line 与 Same-shape Boundary Brake。

本轮只做文档封账：不修改任何 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本 manifest 不批准创建真实 encoder，不批准调用 `renderCommandEncoder` 或 `endEncoding`，不批准绑定 pipeline / buffer / texture / resource，不批准创建 command buffer / render pass descriptor / attachment / texture / drawable，不批准调用 `commandBuffer`、`commit`、`present` 或 `nextDrawable`，不批准 native handle / raw pointer、C ABI、FFI declaration、bridge call、retain / release / destroy、Metal / AppKit / Objective-C / FFI、GPU submission、render / draw call、renderer state write 或 public API expansion。

后续若新增任何 runtime owner 文件，仍必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释，且注释不得把 admission facts 写成真实 implementation permission。

## 固定 owner

Owner 文件：

- [runtime_renderer_encoder_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_encoder_admission.cj)

唯一 runtime input 固定为：

- 输入类型：`CjguiInternalRendererNoRenderPassImplementationReadiness`
- 输入 draft：`cjguiInternalExecuteDefaultRendererRenderPassAdmissionDraft()`

Canonical endpoint 固定为：

- endpoint 类型：`CjguiInternalRendererNoEncoderImplementationReadiness`
- 端点 draft：`cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()`

Default draft 固定为：

- 默认 draft：`cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()`

默认 draft 只从 `cjguiInternalExecuteDefaultRendererRenderPassAdmissionDraft()` 获取 `CjguiInternalRendererNoRenderPassImplementationReadiness`，再构造 encoder implementation intent、encoder creation admission policy、encoding scope admission guard、end-encoding admission policy 与 no-encoder-implementation readiness value facts。它不创建 encoder，不调用 `renderCommandEncoder`，不调用 `endEncoding`，不绑定 pipeline / buffer / texture / resource，不创建 command buffer、render pass descriptor、attachment、texture 或 drawable。

## 当前 truth

Current truth 仅限：

- 记录 encoder implementation intent value facts。
- 记录 encoder creation admission policy value facts。
- 记录 encoding scope admission guard value facts。
- 记录 end-encoding admission policy value facts。
- 记录 no-encoder-implementation readiness value facts。

Canonical value chain 固定为：

1. 上游输入：`CjguiInternalRendererNoRenderPassImplementationReadiness`
2. 意图事实：`CjguiInternalRendererEncoderImplementationIntent`
3. 创建准入事实：`CjguiInternalRendererEncoderCreationAdmissionPolicy`
4. 编码范围准入事实：`CjguiInternalRendererEncodingScopeAdmissionGuard`
5. 结束编码准入事实：`CjguiInternalRendererEndEncodingAdmissionPolicy`
6. 封账 endpoint：`CjguiInternalRendererNoEncoderImplementationReadiness`

## 值语义

`CjguiInternalRendererEncoderImplementationIntent` 只记录未来 encoder implementation intent、encoder creation admission need、encoding scope admission need 与 end-encoding admission need。它不是 encoder-ready permission、backend implementation permission、GPU submission permission、render permission 或 public API permission。

`CjguiInternalRendererEncoderCreationAdmissionPolicy` 只记录 encoder creation admission facts。它不创建 encoder，不调用 `renderCommandEncoder`，不保存 encoder token，不表达 command buffer permission。

`CjguiInternalRendererEncodingScopeAdmissionGuard` 只记录 encoding scope admission facts、no command encoding facts 与 resource binding placeholder facts。它不打开真实 encoding scope，不绑定 pipeline / buffer / texture / resource，不发 draw call，不写 renderer state。

`CjguiInternalRendererEndEncodingAdmissionPolicy` 只记录 end-encoding admission facts、post-encoding invalidation facts 与 no completion observation facts。它不调用 `endEncoding`，不注册 completion callback，不观察真实 GPU completion。

`CjguiInternalRendererNoEncoderImplementationReadiness` 是当前 no-encoder-implementation endpoint。它不是 encoder permission、`renderCommandEncoder` permission、`endEncoding` permission、pipeline / buffer / texture / resource binding permission、command buffer permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

## 关系事实

Encoder implementation admission facts 只把上游 no-render-pass-implementation endpoint 作为 runtime input：

- [render pass implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-pass-implementation-admission-manifest.md) 固定 `CjguiInternalRendererNoRenderPassImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderPassAdmissionDraft()`，但不授予 encoder、`renderCommandEncoder`、`endEncoding`、pipeline binding、command buffer、GPU submission、render、renderer state write 或 public API permission。
- [encoder implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-preflight-decision.md) 已把 runway 限定为 admission value boundary，不是真实 encoder implementation。
- [encoder implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-encoder-implementation-admission-value-boundary-closure-review.md) 已记录 owner、新增 internal symbols、GitNexus impact、build / smoke 兜底与 stop-line scan。
- [encoder implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-admission-next-boundary-decision.md) 已确认 `CjguiInternalRendererNoEncoderImplementationReadiness` / `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()` 足够作为当前 endpoint，不需要继续包装 tail wrapper。
- [encoder lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md) 只提供 lifecycle vocabulary evidence；`CjguiInternalRendererNoEncoderReadiness` 不是本 owner 的 runtime input，也不是 implementation permission。
- [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md) 继续要求中文 Markdown 与后续 runtime owner 文件头维护注释。

## 明确的非 truth

`CjguiInternalRendererNoEncoderImplementationReadiness` 不是：

- 不是 encoder permission。
- 不是 `renderCommandEncoder` permission。
- 不是 `endEncoding` permission。
- 不是 pipeline binding permission。
- 不是 buffer binding permission。
- 不是 texture binding permission。
- 不是 resource binding permission。
- 不是 command buffer permission。
- 不是 `commandBuffer` permission。
- 不是 `commit` permission。
- 不是 drawable permission。
- 不是 `nextDrawable` permission。
- 不是 `present` permission。
- 不是 render pass descriptor permission。
- 不是 attachment permission。
- 不是 texture permission。
- 不是 native handle permission。
- 不是 raw pointer permission。
- 不是 C ABI permission。
- 不是 FFI permission。
- 不是 bridge call permission。
- 不是 retain / release / destroy permission。
- 不是 Metal / AppKit / Objective-C permission。
- 不是 GPU submission permission。
- 不是 render / draw call permission。
- 不是 renderer state write permission。
- 不是 public API permission。

当前 truth 没有真实 encoder，没有 encoder token，没有 command buffer，没有 render pass descriptor，没有 attachment object，没有 texture，没有 drawable，没有 pipeline state，没有 native handle，没有 raw pointer，没有 C ABI，没有 FFI declaration，没有 bridge call，没有 GPU work，没有 render work，没有 draw call，没有 renderer state mutation，也没有外部 API surface。

## 同构边界刹车

本轮是 manifest 封账，明确拒绝：

- 拒绝 encoder implementation receipt / record / publication。
- 拒绝 encoder-ready permission wrapper。
- 拒绝 `renderCommandEncoder` permission wrapper。
- 拒绝 `endEncoding` permission wrapper。
- 拒绝 pipeline-binding permission wrapper。
- 拒绝 command-buffer permission wrapper。
- 拒绝 native-handle permission wrapper。
- 拒绝 C-ABI / FFI permission wrapper。
- 拒绝 GPU-submission wrapper。
- 拒绝 render-permission wrapper。
- 拒绝 renderer-state-write wrapper。

`CjguiInternalRendererNoEncoderImplementationReadiness` 不得继续包装成新的 tail wrapper。未来靠近 pipeline state implementation、draw call implementation、encoder admission hardening、end-encoding admission hardening、真实 encoder creation、`renderCommandEncoder` / `endEncoding`、pipeline / buffer / texture / resource binding、command buffer、GPU submission、render 或 renderer state write，必须先通过 docs-only preflight。

## 停止线

在后续 docs-only preflight 明确打开更窄 runway 前：

- 不修改 `.cj`。
- 不新建 runtime owner。
- 不运行 `cjpm build` / smoke。
- 不触碰 `runtime_state.cj`。
- 不触碰 `runtime/cjgui/cjpm.toml`。
- 不触碰 smoke / harness / native bridge / entry。
- 不触碰 AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- 不创建真实 encoder。
- 不调用 `renderCommandEncoder`。
- 不调用 `endEncoding`。
- 不绑定 pipeline / buffer / texture / resource。
- 不创建 command buffer。
- 不创建 render pass descriptor。
- 不创建 attachment。
- 不创建 texture。
- 不获取 drawable。
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
- 不执行 render / draw call。
- 不写 renderer state。
- 不扩 public API。

## 公共 surface

Public declaration allowlist 仍保持：

- 唯一允许：`cjguiExperimentalQueueSubmitShellReady(): Bool`

本 manifest 不批准第二个 public symbol，不修改 Bool-only signature，不新增 public C ABI，不接 diagnostics / event bus / observer / telemetry 或 public API。

## 下一阶段候选

### 候选 A：推荐 pipeline state implementation preflight

推荐下一步：

`P1 internal Renderer pipeline state implementation preflight decision`

理由：encoder implementation admission 已封账为 no-encoder-implementation endpoint。下一步可以 docs-only 评估 pipeline state implementation runway、pipeline creation / binding relation、shader / descriptor stop-line 与 no-pipeline-state-implementation facts，但仍不得创建 pipeline state，不得绑定 pipeline，不得创建 encoder，不得发 draw call，不得提交 GPU work。

### 候选 B：暂缓 draw call implementation preflight

Draw call 更靠近 render execution、resource binding、command encoding 与 GPU submission，应晚于 pipeline state implementation preflight。

### 候选 C：暂缓 encoder admission hardening

`EncoderCreationAdmissionPolicy` 与 `EncodingScopeAdmissionGuard` 已表达 no encoder object、no encoder factory call、no pipeline / buffer / texture / resource binding facts。只有未来 review 发现 admission facts 表达不足时才选择 hardening。

### 候选 D：暂缓 end-encoding admission hardening

`EndEncodingAdmissionPolicy` 已表达 no `endEncoding`、post-encoding invalidation 与 no completion observation facts。当前不需要新增 hardening owner。

### 候选 E 到 K：拒绝直接实现或发布

拒绝 direct encoder creation implementation、direct `renderCommandEncoder` / `endEncoding`、direct pipeline / buffer / texture / resource binding、direct command buffer / GPU submission / render、renderer state write、public API / C ABI expansion、receipt / record / publication。

### 候选 L：仅限明确重复时 consolidation

只有出现明确 duplicate / self-wrapping evidence 时才选择 consolidation。当前 evidence 指向 downstream pipeline state implementation preflight，而不是删除或合并。

## 封账决定

`runtime/cjgui/src/runtime_renderer_encoder_admission.cj` 是当前 no-encoder-implementation endpoint 的固定 owner。

`CjguiInternalRendererNoEncoderImplementationReadiness` / `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()` 是 encoder implementation admission value facts 的 canonical tail。它不授予 encoder、`renderCommandEncoder`、`endEncoding`、pipeline / buffer / texture / resource binding、command buffer、native handle、C ABI、FFI、GPU submission、render、renderer state write 或 public API permission。

下游 pipeline state implementation preflight 已记录在：

- [2026-05-06-p1-renderer-pipeline-state-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-preflight-decision.md)

该 preflight 只把本 manifest 固定的 `CjguiInternalRendererNoEncoderImplementationReadiness` / `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()` 作为唯一 runtime input candidate。`CjguiInternalRendererNoPipelineStateReadiness`、render pass admission endpoint 与 backend / Metal reference evidence 只能作为 docs evidence。

该 preflight 选择下一步进入 value-only pipeline state implementation admission boundary。Output truth 仅限 pipeline state implementation intent / shader function admission policy / pipeline descriptor admission policy / pipeline compatibility admission guard / no-pipeline-state-implementation readiness value facts；仍不批准 pipeline state creation、shader library / shader function、pipeline descriptor、pipeline binding、encoder、command buffer、GPU submission、render / draw call、renderer state write 或 public API permission。

下游 pipeline state implementation admission value boundary 已记录在：

- [2026-05-06-p1-internal-renderer-pipeline-state-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-pipeline-state-implementation-admission-value-boundary-closure-review.md)
- [runtime_renderer_pipeline_state_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_admission.cj)

该 owner 只消费本 manifest 固定的 `CjguiInternalRendererNoEncoderImplementationReadiness` / `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()`，canonical endpoint 是 `CjguiInternalRendererNoPipelineStateImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()`。它新增 shader function admission、pipeline descriptor admission、compatibility admission 与 no-pipeline-state-implementation readiness value facts，不把 no-encoder-implementation endpoint 包成 pipeline-ready permission wrapper、shader-function permission wrapper、pipeline-descriptor permission wrapper、pipeline-binding permission wrapper、GPU-submission wrapper、render-permission wrapper、receipt / record / publication。

下游 pipeline state implementation admission next-boundary decision 已记录在：

- [2026-05-06-p1-renderer-pipeline-state-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-admission-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoPipelineStateImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()` 足够作为 no-pipeline-state-implementation endpoint。该 endpoint 仍只代表 pipeline state implementation intent / shader function admission policy / pipeline descriptor admission policy / pipeline compatibility admission guard / no-pipeline-state-implementation readiness value facts，不授予 pipeline state、shader library / shader function、pipeline descriptor、pipeline binding、encoder、command buffer、GPU submission、render、renderer state write 或 public API permission。

下游 pipeline state implementation admission manifest stabilization 已记录在：

- [2026-05-06-p1-renderer-pipeline-state-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-pipeline-state-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-pipeline-state-implementation-admission-manifest-stabilization-closure-review.md)

该 manifest 固定 pipeline state implementation admission owner 的 current truth 与 stop-line。它只把本 manifest 固定的 no-encoder-implementation endpoint 作为 upstream runtime input，不创建 pipeline state、shader library / shader function、pipeline descriptor，不绑定 pipeline / buffer / texture / resource，不授予 encoder、command buffer、GPU submission、render、renderer state write 或 public API permission。

新的唯一后续入口：

`P1 internal Renderer draw call implementation admission closure / next draw call implementation decision`

下游 draw call implementation preflight 已记录在：

- [2026-05-06-p1-renderer-draw-call-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-preflight-decision.md)

该 decision 不把本 manifest 固定的 `CjguiInternalRendererNoEncoderImplementationReadiness` 直接包装成 draw-ready permission。它只把 encoder admission endpoint 作为 relation evidence，并要求下一步唯一 runtime input candidate 消费 `CjguiInternalRendererNoPipelineStateImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()`。

该 decision 选择下一步进入 value-only draw call implementation admission boundary。Output truth 仅限 draw call implementation intent / primitive command admission policy / geometry binding admission guard / draw ordering admission policy / no-draw-call-implementation readiness value facts；仍不批准 draw call、`drawPrimitives` / `drawIndexedPrimitives`、pipeline / buffer / texture / resource binding、encoder、command buffer、GPU submission、render、renderer state write 或 public API permission。

下游 draw call implementation admission value boundary 已记录在：

- [2026-05-06-p1-internal-renderer-draw-call-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-draw-call-implementation-admission-value-boundary-closure-review.md)

该 closure 新增 [runtime_renderer_draw_call_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_call_admission.cj)。它不把本 manifest 的 `CjguiInternalRendererNoEncoderImplementationReadiness` 直接包装成 draw-ready permission；唯一 runtime input 是 pipeline state implementation admission endpoint，encoder admission endpoint 只作为 relation evidence。新增 truth 仅限 primitive command admission / geometry binding admission / draw ordering admission / no-draw-call-implementation value facts，不批准 draw call、resource binding、pipeline binding、encoder、command buffer、GPU submission、render 或 renderer state write。

## 下游 real encoder 第一刀

real encoder first-slice macro 已完成：

- [real render pass branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-render-pass-branch-next-boundary-decision.md)
- [real encoder first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-encoder-first-implementation-preflight-decision.md)
- [real encoder first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-encoder-first-implementation-slice-closure-review.md)
- [real encoder first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-encoder-first-implementation-slice-manifest.md)
- [real encoder first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-encoder-first-implementation-slice-manifest-stabilization-closure-review.md)

该 downstream 不复用本 manifest 的 `CjguiInternalRendererNoEncoderImplementationReadiness` 作为 runtime input；它只把本 manifest 的 no-encoder-implementation stop-line 作为 evidence，并由 `runtime/cjgui/src/runtime_renderer_encoder_real.cj` 消费 `CjguiInternalRendererNoRealRenderPassShellReadiness`。`CjguiInternalRendererNoRealEncoderShellReadiness` 只表达 real encoder shell / denial proof / teardown failure facts，不是真实 encoder、`renderCommandEncoder`、`endEncoding`、pipeline / buffer / texture / resource binding、GPU submission、render、renderer state write 或 public API permission。
