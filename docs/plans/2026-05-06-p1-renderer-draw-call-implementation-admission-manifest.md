# P1 渲染器绘制调用实现准入 manifest 封账

日期：2026-05-06

状态：docs-only manifest stabilization

## 封账结论

本 manifest 固定 [runtime_renderer_draw_call_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_call_admission.cj) 的 owner、truth、canonical endpoint、default draft、runtime input、stop-line 与 Same-shape Boundary Brake。

本轮只做文档封账：不修改任何 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本 manifest 不批准发出 draw call，不批准调用 `drawPrimitives` / `drawIndexedPrimitives`，不批准创建或绑定 vertex buffer、index buffer、texture、sampler 或 resource，不批准 pipeline binding，不批准创建 pipeline state、shader 或 descriptor，不批准创建 encoder 或 command buffer，不批准调用 `renderCommandEncoder`、`endEncoding`、`commandBuffer`、`commit`、`present` 或 `nextDrawable`，不批准 native handle / raw pointer、C ABI、FFI declaration、bridge call、retain / release / destroy、Metal / AppKit / Objective-C / FFI、GPU submission、render、renderer state write 或 public API expansion。

后续若新增任何 runtime owner 文件，仍必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释，且注释不得把 admission facts 写成真实 implementation permission。

## 固定 owner

Owner 文件：

- [runtime_renderer_draw_call_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_call_admission.cj)

唯一 runtime input 固定为：

- 输入类型：`CjguiInternalRendererNoPipelineStateImplementationReadiness`
- 输入 draft：`cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()`

Canonical endpoint 固定为：

- endpoint 类型：`CjguiInternalRendererNoDrawCallImplementationReadiness`
- endpoint draft：`cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()`

Default draft 固定为：

- 默认 draft：`cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()`

默认 draft 只从 `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()` 获取 `CjguiInternalRendererNoPipelineStateImplementationReadiness`，再构造 draw call implementation intent、primitive command admission policy、geometry binding admission guard、draw ordering admission policy 与 no-draw-call-implementation readiness value facts。它不发出 draw call，不调用 primitive command API，不绑定 geometry / resource / pipeline，不创建 encoder，不创建 command buffer，不提交 GPU work，不执行 render，不写 renderer state。

## 当前 truth

Current truth 仅限：

- 记录 draw call implementation intent value facts。
- 记录 primitive command admission policy value facts。
- 记录 geometry binding admission guard value facts。
- 记录 draw ordering admission policy value facts。
- 记录 no-draw-call-implementation readiness value facts。

Canonical value chain 固定为：

1. 上游输入：`CjguiInternalRendererNoPipelineStateImplementationReadiness`
2. 意图事实：`CjguiInternalRendererDrawCallImplementationIntent`
3. primitive command 准入事实：`CjguiInternalRendererPrimitiveCommandAdmissionPolicy`
4. geometry / resource 准入事实：`CjguiInternalRendererGeometryBindingAdmissionGuard`
5. ordering 准入事实：`CjguiInternalRendererDrawOrderingAdmissionPolicy`
6. 封账 endpoint：`CjguiInternalRendererNoDrawCallImplementationReadiness`

Open path 只能形成 dehydrated admission facts；defer-only 保持 defer；blocked / inconsistent path 必须 fail-closed，并保留 no draw command、no primitive command invocation、no geometry resource held、no texture / sampler resource held、no pipeline use、no encoder object、no command buffer object、no foreign declaration / invocation、no external handle、no pointer resource、no GPU work、no render execution、no renderer state mutation 与 no publication facts。

## 值语义

`CjguiInternalRendererDrawCallImplementationIntent` 只记录未来 draw call implementation intent，以及 primitive command admission、geometry binding admission 与 draw ordering admission 的需要。它不是 draw-ready permission、backend implementation permission、GPU submission permission、render permission 或 public API permission。

`CjguiInternalRendererPrimitiveCommandAdmissionPolicy` 只记录 primitive kind、vertex count 与 instance count admission facts。`PrimitiveCommandAdmissionPolicy` 不发出 draw call，不调用 `drawPrimitives` / `drawIndexedPrimitives`，不进入 encoder command stream。

`CjguiInternalRendererGeometryBindingAdmissionGuard` 只记录 geometry source、index source 与 resource placeholder facts。`GeometryBindingAdmissionGuard` 不绑定 vertex buffer / index buffer / texture / sampler / resource，不保存 geometry payload，不持有 resource token。

`CjguiInternalRendererDrawOrderingAdmissionPolicy` 只记录 draw order、material grouping 与 state dependency admission facts。`DrawOrderingAdmissionPolicy` 不排序真实 GPU draw，不执行 material grouping，不做 render pass mutation，不提交 GPU work。

`CjguiInternalRendererNoDrawCallImplementationReadiness` 是当前 no-draw-call-implementation endpoint。`NoDrawCallImplementationReadiness` 不是 draw call permission、primitive command permission、geometry / resource binding permission、pipeline binding permission、encoder permission、command buffer permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

## 关系事实

Draw call implementation admission facts 只把上游 no-pipeline-state-implementation endpoint 作为 runtime input：

- [pipeline state implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-admission-manifest.md) 固定 `CjguiInternalRendererNoPipelineStateImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()`，但不授予 draw call、primitive command、resource binding、pipeline binding、encoder、command buffer、GPU submission、render、renderer state write 或 public API permission。
- [draw call implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-preflight-decision.md) 已把 runway 限定为 admission value boundary，不是真实 draw call implementation。
- [draw call implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-draw-call-implementation-admission-value-boundary-closure-review.md) 已记录 owner、新增 internal symbols、GitNexus impact、build / smoke 兜底与 stop-line scan。
- [draw call implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-admission-next-boundary-decision.md) 已确认 `CjguiInternalRendererNoDrawCallImplementationReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()` 足够作为当前 endpoint，不需要继续包装 tail wrapper。
- [draw call lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md) 只提供 lifecycle vocabulary evidence；`CjguiInternalRendererNoDrawCallReadiness` 不是本 owner 的 runtime input，也不是 implementation permission。
- [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md) 继续要求中文 Markdown 与后续 runtime owner 文件头维护注释。

## 明确的非 truth

`CjguiInternalRendererNoDrawCallImplementationReadiness` 不是：

- 不是 draw call permission。
- 不是 `drawPrimitives` permission。
- 不是 `drawIndexedPrimitives` permission。
- 不是 primitive command permission。
- 不是 vertex buffer binding permission。
- 不是 index buffer binding permission。
- 不是 texture binding permission。
- 不是 sampler binding permission。
- 不是 resource binding permission。
- 不是 pipeline binding permission。
- 不是 pipeline state permission。
- 不是 shader permission。
- 不是 descriptor permission。
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
- 不是 render permission。
- 不是 renderer state write permission。
- 不是 public API permission。

当前 truth 没有 draw command，没有 primitive command invocation，没有 geometry resource，没有 texture / sampler resource，没有 resource token，没有 pipeline binding，没有 pipeline state object，没有 shader object，没有 descriptor object，没有 encoder，没有 command buffer，没有 drawable，没有 native handle，没有 raw pointer，没有 C ABI，没有 FFI declaration，没有 bridge call，没有 GPU work，没有 render work，没有 renderer state mutation，也没有外部 API surface。

## 同构边界刹车（Same-shape Boundary Brake）

本轮是 manifest 封账，不新增 tail wrapper。明确拒绝：

- 拒绝 draw-call implementation receipt / record / publication。
- 拒绝 draw-ready permission wrapper。
- 拒绝 primitive-command permission wrapper。
- 拒绝 geometry-binding permission wrapper。
- 拒绝 resource-binding permission wrapper。
- 拒绝 pipeline-binding permission wrapper。
- 拒绝 encoder permission wrapper。
- 拒绝 command-buffer permission wrapper。
- 拒绝 native-handle permission wrapper。
- 拒绝 C-ABI / FFI permission wrapper。
- 拒绝 GPU-submission wrapper。
- 拒绝 render-permission wrapper。
- 拒绝 renderer-state-write wrapper。

`CjguiInternalRendererNoDrawCallImplementationReadiness` 不得继续包装成新的 tail wrapper。未来靠近 render execution implementation、resource binding admission、draw call admission hardening、pipeline state admission hardening、真实 draw call / primitive command、geometry / resource binding、pipeline binding、encoder / command buffer、GPU submission、render 或 renderer state write，必须先通过 docs-only preflight。

## 停止线

在后续 docs-only preflight 明确打开更窄 runway 前：

- 不修改 `.cj`。
- 不新建 runtime owner。
- 不运行 `cjpm build` / smoke。
- 不触碰 `runtime_state.cj`。
- 不触碰 `runtime/cjgui/cjpm.toml`。
- 不触碰 smoke / harness / native bridge / entry。
- 不触碰 AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- 不发出 draw call。
- 不调用 `drawPrimitives`。
- 不调用 `drawIndexedPrimitives`。
- 不创建 / 绑定 vertex buffer。
- 不创建 / 绑定 index buffer。
- 不创建 / 绑定 texture。
- 不创建 / 绑定 sampler。
- 不创建 / 绑定 resource。
- 不绑定 pipeline。
- 不创建 pipeline state。
- 不创建 shader。
- 不创建 descriptor。
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
- 不执行 render。
- 不写 renderer state。
- 不扩 public API。

## 公共 surface

Public declaration allowlist 仍保持：

- 唯一允许：`cjguiExperimentalQueueSubmitShellReady(): Bool`

本 manifest 不批准第二个 public symbol，不修改 Bool-only signature，不新增 public C ABI，不接 diagnostics / event bus / observer / telemetry 或 public API。

## 下一阶段候选

### 候选 A：已执行 render execution implementation admission value boundary

已执行下游：

`P1 internal Renderer render execution implementation admission value boundary bundle implementation`

当前唯一后续入口已转为：

`P1 internal Renderer renderer state write implementation preflight decision`

## 下游 render execution implementation preflight

Renderer render execution implementation preflight 已完成：

- [2026-05-06-p1-renderer-render-execution-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-execution-implementation-preflight-decision.md)

该 decision 只把本 manifest 固定的 `CjguiInternalRendererNoDrawCallImplementationReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()` 作为 runtime input candidate。`CjguiInternalRendererNoRenderExecutionReadiness`、`CjguiInternalRendererNoGpuSubmissionReadiness`、command buffer / drawable admission endpoint 与 backend / Metal reference evidence 只能作为 docs evidence，不是 render execution implementation permission。

该 decision 选择下一步进入 value-only render execution implementation admission boundary。Output truth 仅限 render execution implementation intent / execution admission policy / completion observation admission guard / rollback admission policy / no-render-execution-implementation readiness facts；仍不批准 render execution、GPU submission、`commit`、`present`、`nextDrawable`、command buffer creation / submission、encoder creation、draw call、resource binding、renderer state write 或 public API permission。

理由：draw call implementation admission 已封账为 no-draw-call-implementation endpoint。下一步可以 docs-only 评估 render execution implementation runway、draw call / encoder / command buffer / submission relation、render completion stop-line 与 no-render-execution facts，但仍不得发出 draw call，不得绑定 resource / pipeline，不得创建 encoder 或 command buffer，不得提交 GPU work，不得执行 render。

## 下游 render execution implementation admission value boundary

Renderer render execution implementation admission value boundary 已完成：

- [2026-05-06-p1-internal-renderer-render-execution-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-render-execution-implementation-admission-value-boundary-closure-review.md)
- [runtime_renderer_render_execution_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_execution_admission.cj)
- [2026-05-06-p1-renderer-render-execution-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-execution-implementation-admission-next-boundary-decision.md)
- [2026-05-06-p1-renderer-render-execution-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-execution-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-render-execution-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-render-execution-implementation-admission-manifest-stabilization-closure-review.md)

该 closure 只把本 manifest 固定的 `CjguiInternalRendererNoDrawCallImplementationReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()` 作为 runtime input。Canonical endpoint 是 `CjguiInternalRendererNoRenderExecutionImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderExecutionAdmissionDraft()`；truth 仅限 render execution implementation intent / execution admission policy / completion observation admission guard / rollback admission policy / no-render-execution-implementation readiness value facts。

该 downstream 仍不批准 render execution、GPU submission、`commit`、`present`、`nextDrawable`、command buffer creation / submission、encoder creation、draw call、resource binding、renderer state write 或 public API permission。Next-boundary decision 已确认 no-render-execution-implementation endpoint 足够封账，manifest stabilization 已固定 downstream owner / truth / stop-line；新的唯一后续入口转向 docs-only renderer state write implementation preflight。

### 候选 B 到 D：暂缓 admission hardening

Resource binding admission preflight、draw call admission hardening 与 pipeline state admission hardening 均暂缓。当前 manifest 已固定 no draw call、no primitive command invocation、no resource binding、no pipeline binding、no encoder、no command buffer、no GPU work 与 no renderer state mutation facts；只有未来 review 发现表达不足时才选择 hardening。

### 候选 E 到 K：拒绝直接实现或发布

拒绝 direct draw call / primitive command implementation、direct geometry / resource binding、direct pipeline binding、direct encoder / command buffer / GPU submission / render、renderer state write、public API / C ABI expansion、receipt / record / publication。

### 候选 L：仅限明确重复时 consolidation

只有出现明确 duplicate / self-wrapping evidence 时才选择 consolidation。当前 evidence 指向 downstream render execution implementation preflight，而不是删除或合并。

## 封账决定

`runtime/cjgui/src/runtime_renderer_draw_call_admission.cj` 是当前 no-draw-call-implementation endpoint 的固定 owner。

`CjguiInternalRendererNoDrawCallImplementationReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()` 是 draw call implementation admission value facts 的 canonical tail。它不授予 draw call、primitive command、geometry / resource binding、pipeline binding、encoder、command buffer、native handle、C ABI、FFI、GPU submission、render、renderer state write 或 public API permission。

新的唯一后续入口：

`P1 internal Renderer renderer state write implementation preflight decision`

## 下游设计意图导航

plans 设计意图导航已建立，后续追踪 draw call 到 render execution 的 implementation admission 链时，可先读取：

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [Renderer implementation admission chain topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)

该导航只追加历史设计意图入口，不改变本 manifest 的 owner / truth / stop-line 或当前后续入口。

## 验证记录

本轮 docs-only 封账必须验证：

- `git diff --check`
- 新 manifest / closure no-index whitespace check
- Markdown absolute link missing target check，限定 project docs scope，避开 `reference_repos/`
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability
- Markdown 中文标题与中文正文抽查
- forbidden check：确认无 tracked `.cj` diff、无 protected path diff/status，`runtime_state.cj` 行数仍为 `10065`
- public declaration scan：仍只能有 `cjguiExperimentalQueueSubmitShellReady(): Bool`
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`
