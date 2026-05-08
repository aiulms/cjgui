# P1 渲染器管线状态实现准入 manifest 封账

日期：2026-05-06

状态：docs-only manifest stabilization

## 封账结论

本 manifest 固定 [runtime_renderer_pipeline_state_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_admission.cj) 的 owner、truth、canonical endpoint、default draft、runtime input、stop-line 与 Same-shape Boundary Brake。

本轮只做文档封账：不修改任何 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本 manifest 不批准创建 pipeline state，不批准创建 shader library / shader function，不批准创建 pipeline descriptor，不批准绑定 pipeline / buffer / texture / resource，不批准创建 encoder，不批准调用 `renderCommandEncoder` 或 `endEncoding`，不批准创建 command buffer，不批准调用 `commandBuffer`、`commit`、`present` 或 `nextDrawable`，不批准 native handle / raw pointer、C ABI、FFI declaration、bridge call、retain / release / destroy、Metal / AppKit / Objective-C / FFI、GPU submission、render / draw call、renderer state write 或 public API expansion。

后续若新增任何 runtime owner 文件，仍必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释，且注释不得把 admission facts 写成真实 implementation permission。

## 固定 owner

Owner 文件：

- [runtime_renderer_pipeline_state_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_admission.cj)

唯一 runtime input 固定为：

- 输入类型：`CjguiInternalRendererNoEncoderImplementationReadiness`
- 输入 draft：`cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()`

Canonical endpoint 固定为：

- endpoint 类型：`CjguiInternalRendererNoPipelineStateImplementationReadiness`
- endpoint draft：`cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()`

Default draft 固定为：

- 默认 draft：`cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()`

默认 draft 只从 `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()` 获取 `CjguiInternalRendererNoEncoderImplementationReadiness`，再构造 pipeline state implementation intent、shader function admission policy、pipeline descriptor admission policy、pipeline compatibility admission guard 与 no-pipeline-state-implementation readiness value facts。它不创建 pipeline state，不加载 shader library，不解析 shader function，不创建 pipeline descriptor，不绑定 pipeline / buffer / texture / resource，不创建 encoder，不创建 command buffer，不提交 GPU work，不执行 render / draw call。

## 当前 truth

Current truth 仅限：

- 记录 pipeline state implementation intent value facts。
- 记录 shader function admission policy value facts。
- 记录 pipeline descriptor admission policy value facts。
- 记录 pipeline compatibility admission guard value facts。
- 记录 no-pipeline-state-implementation readiness value facts。

Canonical value chain 固定为：

1. 上游输入：`CjguiInternalRendererNoEncoderImplementationReadiness`
2. 意图事实：`CjguiInternalRendererPipelineStateImplementationIntent`
3. shader 准入事实：`CjguiInternalRendererShaderFunctionAdmissionPolicy`
4. descriptor 准入事实：`CjguiInternalRendererPipelineDescriptorAdmissionPolicy`
5. compatibility 准入事实：`CjguiInternalRendererPipelineCompatibilityAdmissionGuard`
6. 封账 endpoint：`CjguiInternalRendererNoPipelineStateImplementationReadiness`

Open path 只能形成 dehydrated admission facts；defer-only 保持 defer；blocked / inconsistent path 必须 fail-closed，并保留 no object、no descriptor resource、no binding、no foreign call、no GPU work、no render execution、no draw command、no renderer state mutation 与 no publication facts。

## 值语义

`CjguiInternalRendererPipelineStateImplementationIntent` 只记录未来 pipeline state implementation intent、shader function admission need、pipeline descriptor admission need 与 compatibility admission need。它不是 pipeline-ready permission、backend implementation permission、GPU submission permission、render permission 或 public API permission。

`CjguiInternalRendererShaderFunctionAdmissionPolicy` 只记录 shader role admission、no shader asset resolution 与 shader failure fallback facts。它不创建 shader library / shader function，不执行 function lookup，不保存 shader token，也不表达 shader-ready permission。

`CjguiInternalRendererPipelineDescriptorAdmissionPolicy` 只记录 descriptor field admission、render target compatibility 与 no descriptor resource facts。它不创建 pipeline descriptor，不写入 descriptor field，不绑定 render target / pixel format，不创建 pipeline state，也不保存 platform descriptor resource。

`CjguiInternalRendererPipelineCompatibilityAdmissionGuard` 只记录 render pass、encoder 与 draw-call compatibility admission facts。它不执行真实 compatibility check，不绑定 pipeline，不绑定 buffer / texture / resource，不调用 encoder，不发 draw call。

`CjguiInternalRendererNoPipelineStateImplementationReadiness` 是当前 no-pipeline-state-implementation endpoint。它不是 pipeline state permission、shader permission、pipeline descriptor permission、pipeline binding permission、encoder permission、command buffer permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

## 关系事实

Pipeline state implementation admission facts 只把上游 no-encoder-implementation endpoint 作为 runtime input：

- [encoder implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-admission-manifest.md) 固定 `CjguiInternalRendererNoEncoderImplementationReadiness` / `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()`，但不授予 pipeline state、shader library / shader function、pipeline descriptor、pipeline binding、command buffer、GPU submission、render、renderer state write 或 public API permission。
- [pipeline state implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-preflight-decision.md) 已把 runway 限定为 admission value boundary，不是真实 pipeline state implementation。
- [pipeline state implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-pipeline-state-implementation-admission-value-boundary-closure-review.md) 已记录 owner、新增 internal symbols、GitNexus impact、build / smoke 兜底与 stop-line scan。
- [pipeline state implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-admission-next-boundary-decision.md) 已确认 `CjguiInternalRendererNoPipelineStateImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()` 足够作为当前 endpoint，不需要继续包装 tail wrapper。
- [pipeline state lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md) 只提供 lifecycle vocabulary evidence；`CjguiInternalRendererNoPipelineStateReadiness` 不是本 owner 的 runtime input，也不是 implementation permission。
- [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md) 继续要求中文 Markdown 与后续 runtime owner 文件头维护注释。

## 明确的非 truth

`CjguiInternalRendererNoPipelineStateImplementationReadiness` 不是：

- 不是 pipeline state permission。
- 不是 shader library permission。
- 不是 shader function permission。
- 不是 shader lookup permission。
- 不是 pipeline descriptor permission。
- 不是 descriptor field write permission。
- 不是 render target binding permission。
- 不是 pixel format binding permission。
- 不是 pipeline binding permission。
- 不是 buffer binding permission。
- 不是 texture binding permission。
- 不是 resource binding permission。
- 不是 encoder permission。
- 不是 `renderCommandEncoder` permission。
- 不是 `endEncoding` permission。
- 不是 command buffer permission。
- 不是 `commandBuffer` permission。
- 不是 `commit` permission。
- 不是 drawable permission。
- 不是 `nextDrawable` permission。
- 不是 `present` permission。
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

当前 truth 没有 pipeline state object，没有 shader library，没有 shader function，没有 pipeline descriptor，没有 descriptor resource，没有 pipeline binding，没有 encoder，没有 command buffer，没有 drawable，没有 native handle，没有 raw pointer，没有 C ABI，没有 FFI declaration，没有 bridge call，没有 GPU work，没有 render work，没有 draw call，没有 renderer state mutation，也没有外部 API surface。

## 同构边界刹车（Same-shape Boundary Brake）

本轮是 manifest 封账，不新增 tail wrapper。明确拒绝：

- 拒绝 pipeline-state implementation receipt / record / publication。
- 拒绝 pipeline-ready permission wrapper。
- 拒绝 shader-function permission wrapper。
- 拒绝 pipeline-descriptor permission wrapper。
- 拒绝 pipeline-binding permission wrapper。
- 拒绝 encoder permission wrapper。
- 拒绝 command-buffer permission wrapper。
- 拒绝 native-handle permission wrapper。
- 拒绝 C-ABI / FFI permission wrapper。
- 拒绝 GPU-submission wrapper。
- 拒绝 render-permission wrapper。
- 拒绝 renderer-state-write wrapper。

`CjguiInternalRendererNoPipelineStateImplementationReadiness` 不得继续包装成新的 tail wrapper。未来靠近 draw call implementation、pipeline state admission hardening、shader function admission hardening、pipeline descriptor admission hardening、encoder admission hardening、真实 pipeline state / shader / descriptor implementation、pipeline / buffer / texture / resource binding、encoder / command buffer、GPU submission、render 或 renderer state write，必须先通过 docs-only preflight。

## 停止线

在后续 docs-only preflight 明确打开更窄 runway 前：

- 不修改 `.cj`。
- 不新建 runtime owner。
- 不运行 `cjpm build` / smoke。
- 不触碰 `runtime_state.cj`。
- 不触碰 `runtime/cjgui/cjpm.toml`。
- 不触碰 smoke / harness / native bridge / entry。
- 不触碰 AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- 不创建 pipeline state。
- 不创建 shader library。
- 不创建 shader function。
- 不执行 function lookup。
- 不创建 pipeline descriptor。
- 不写入 descriptor field。
- 不绑定 render target / pixel format。
- 不绑定 pipeline / buffer / texture / resource。
- 不创建 encoder。
- 不调用 `renderCommandEncoder`。
- 不调用 `endEncoding`。
- 不创建 command buffer。
- 不调用 `commandBuffer`。
- 不调用 `commit`。
- 不获取 drawable。
- 不调用 `nextDrawable`。
- 不调用 `present`。
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

### 候选 A：推荐 draw call implementation preflight

推荐下一步：

`P1 internal Renderer draw call implementation preflight decision`

理由：pipeline state implementation admission 已封账为 no-pipeline-state-implementation endpoint。下一步可以 docs-only 评估 draw call implementation runway、pipeline / encoder / command buffer relation、resource binding stop-line 与 no-draw-call-implementation facts，但仍不得执行 draw call，不得绑定 pipeline / buffer / texture / resource，不得创建 encoder 或 command buffer，不得提交 GPU work。

### 候选 B 到 E：暂缓 admission hardening

Pipeline state admission hardening、shader function admission hardening、pipeline descriptor admission hardening 与 encoder admission hardening 均暂缓。当前 manifest 已固定 no shader library / no shader function、no descriptor field write、no compatibility check、no pipeline binding 与 no encoder facts；只有未来 review 发现表达不足时才选择 hardening。

### 候选 F 到 K：拒绝直接实现或发布

拒绝 direct pipeline state / shader / descriptor implementation、direct pipeline / buffer / texture / resource binding、direct encoder / command buffer / GPU submission / render、renderer state write、public API / C ABI expansion、receipt / record / publication。

### 候选 L：仅限明确重复时 consolidation

只有出现明确 duplicate / self-wrapping evidence 时才选择 consolidation。当前 evidence 指向 downstream draw call implementation preflight，而不是删除或合并。

## 封账决定

`runtime/cjgui/src/runtime_renderer_pipeline_state_admission.cj` 是当前 no-pipeline-state-implementation endpoint 的固定 owner。

`CjguiInternalRendererNoPipelineStateImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()` 是 pipeline state implementation admission value facts 的 canonical tail。它不授予 pipeline state、shader library / shader function、pipeline descriptor、pipeline binding、encoder、command buffer、native handle、C ABI、FFI、GPU submission、render、renderer state write 或 public API permission。

新的唯一后续入口：

`P1 internal Renderer render execution implementation preflight decision`

## 下游 draw call implementation preflight

Renderer draw call implementation preflight 已完成：

- [2026-05-06-p1-renderer-draw-call-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-preflight-decision.md)

该 decision 只把本 manifest 固定的 `CjguiInternalRendererNoPipelineStateImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()` 作为唯一 runtime input candidate。`CjguiInternalRendererNoDrawCallReadiness`、encoder admission endpoint 与 backend / Metal reference evidence 只能作为 docs evidence，不是 draw-call implementation permission。

该 decision 选择下一步进入 value-only draw call implementation admission boundary。Output truth 仅限 draw call implementation intent / primitive command admission policy / geometry binding admission guard / draw ordering admission policy / no-draw-call-implementation readiness value facts；仍不批准 draw call、`drawPrimitives` / `drawIndexedPrimitives`、vertex / index buffer binding、texture / sampler / resource binding、pipeline binding、encoder、command buffer、GPU submission、render、renderer state write 或 public API permission。

## 下游 draw call implementation admission value boundary

Renderer draw call implementation admission value boundary 已完成：

- [2026-05-06-p1-internal-renderer-draw-call-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-draw-call-implementation-admission-value-boundary-closure-review.md)

该 closure 新增 [runtime_renderer_draw_call_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_call_admission.cj)。它只把本 manifest 固定的 `CjguiInternalRendererNoPipelineStateImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()` 作为 runtime input，输出 `CjguiInternalRendererNoDrawCallImplementationReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()`。

新增 truth 仅限 primitive command admission / geometry binding admission / draw ordering admission / no-draw-call-implementation value facts。它不是 pipeline-state endpoint 的 draw-ready wrapper，也不批准 draw call、primitive command invocation、geometry / resource binding、pipeline binding、GPU submission、render、renderer state write 或 public API permission。

## 下游 draw call implementation admission next-boundary decision

Renderer draw call implementation admission next-boundary decision 已完成：

- [2026-05-06-p1-renderer-draw-call-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-admission-next-boundary-decision.md)

该 decision 确认 downstream `CjguiInternalRendererNoDrawCallImplementationReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()` 足够封账，并选择下一步 docs-only manifest stabilization。它不把本 manifest 的 no-pipeline-state-implementation endpoint 包成 draw-ready permission，也不批准 draw call、resource binding、pipeline binding、encoder、command buffer、GPU submission、render、renderer state write 或 public API permission。

## 下游 draw call implementation admission manifest

Renderer draw call implementation admission manifest stabilization 已完成：

- [2026-05-06-p1-renderer-draw-call-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-draw-call-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-draw-call-implementation-admission-manifest-stabilization-closure-review.md)

该 manifest 固定 downstream [runtime_renderer_draw_call_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_call_admission.cj) owner / truth / canonical endpoint / default draft / runtime input / stop-line。它只把本 manifest 的 `CjguiInternalRendererNoPipelineStateImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()` 作为 runtime input，并输出 `CjguiInternalRendererNoDrawCallImplementationReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()`。它不把 no-pipeline-state-implementation endpoint 包成 draw-ready permission，也不批准 draw call、primitive command、resource binding、pipeline binding、GPU submission、render、renderer state write 或 public API permission。
