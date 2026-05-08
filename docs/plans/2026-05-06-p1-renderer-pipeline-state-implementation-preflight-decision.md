# P1 渲染器 pipeline state implementation preflight 决策

日期：2026-05-06

状态：docs-only preflight decision

## 决策结论

本轮允许打开 pipeline state implementation runway，但下一步仍只能是 internal value boundary / implementation admission facts，不是真实 pipeline state implementation。

推荐唯一后续入口：

`P1 internal Renderer pipeline state implementation admission value boundary bundle implementation`

下一步若进入 runtime owner，默认候选 owner 可评估为 `runtime/cjgui/src/runtime_renderer_pipeline_state_admission.cj` 或等价 internal-only owner；本轮不新建该 owner，不修改任何 `.cj`。后续若新增 runtime owner 文件，必须继续保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释，且注释不得把 admission facts 写成真实 implementation permission。

下一步 value boundary 的唯一 runtime input 建议只消费：

- 输入类型：`CjguiInternalRendererNoEncoderImplementationReadiness`
- 输入 draft：`cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()`

下一步 output truth 只能限定为：

- 记录 pipeline state implementation intent value facts。
- 记录 shader function admission policy value facts。
- 记录 pipeline descriptor admission policy value facts。
- 记录 pipeline compatibility admission guard value facts。
- 记录 no-pipeline-state-implementation readiness value facts。

本 preflight 不批准创建 pipeline state，不批准创建 shader library / shader function，不批准创建 pipeline descriptor，不批准调用 Metal / AppKit / Objective-C / FFI，不批准 native handle / raw pointer、C ABI、FFI declaration、bridge call、retain / release / destroy，不批准绑定 pipeline / buffer / texture / resource，不批准创建 encoder，不批准调用 `renderCommandEncoder` 或 `endEncoding`，不批准 command buffer、`commandBuffer`、`commit`、drawable acquisition、`nextDrawable`、`present`、GPU submission、render / draw call、renderer state write 或 public API expansion。

## 证据读取

本轮读取并采用以下 evidence，但 reference evidence 不能升格为 runtime truth：

- [encoder implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-admission-manifest.md)：固定 `CjguiInternalRendererNoEncoderImplementationReadiness` / `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()`，只代表 encoder implementation intent / encoder creation admission policy / encoding scope admission guard / end-encoding admission policy / no-encoder-implementation readiness value facts；不授予 pipeline state、shader function、pipeline descriptor、pipeline binding、GPU submission、render、renderer state write 或 public API permission。
- [pipeline state lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md)：提供 pipeline state lifecycle intent、shader function policy、pipeline descriptor policy、pipeline compatibility guard 与 no-pipeline-state readiness vocabulary。该 manifest 不是 pipeline state implementation admission manifest，`CjguiInternalRendererNoPipelineStateReadiness` 也不是本轮 runtime input。
- [render pass implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-pass-implementation-admission-manifest.md)：提供 render pass / attachment / load-store / target relation evidence，继续拒绝 render pass descriptor、attachment、texture、encoder、pipeline state、command buffer、GPU submission、render、renderer state write 或 public API permission。
- [backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)：提供官方 Metal evidence，说明 render pipeline state / resources / fixed-function state 通常在 render command encoder 上绑定后才进入 draw calls；但它只作为 docs evidence，不是 runtime input，不批准 Metal / AppKit / Objective-C / FFI implementation。
- [GUI 风险账本](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)：继续提醒 GPU resource lifecycle、FFI ownership、主线程边界、错误边界和自动化验证风险；本轮只把这些风险转为 stop-line，不实现任何资源。
- [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md)：要求新增 / 修改 Markdown 使用中文正文与中文章节标题，并要求后续新增 runtime owner 文件保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释。

## 预检判断

结论：evidence 足够打开 pipeline state implementation runway，但只够打开 admission value boundary，不足以进入真实 pipeline state creation、shader lookup、descriptor construction 或 pipeline binding。

理由：

- `CjguiInternalRendererNoEncoderImplementationReadiness` 已经是新的 no-encoder-implementation endpoint，可作为下一步 pipeline state admission 的唯一 runtime input candidate。
- Pipeline state lifecycle manifest 已经提供 shader function policy、pipeline descriptor policy、pipeline compatibility guard 与 no-pipeline-state vocabulary，足以让下一步表达 shader function admission、pipeline descriptor admission 与 compatibility admission。
- Backend / Metal reference pack 确认 pipeline state 与 shader functions、pipeline descriptors、render pass / target formats、encoder binding 和 draw calls 关系紧密，因此下一步必须停在 admission facts，不能创建真实 pipeline state。
- Render pass implementation admission manifest 与 encoder implementation admission manifest 共同证明当前没有 render pass descriptor、encoder、pipeline binding、command buffer、GPU submission 或 render permission。
- 风险账本要求 GPU / FFI / platform resource lifecycle 在真实资源前先冻结 owner、teardown、failure 与 validation strategy；本轮只能把这些写入 stop-line。

不需要先选择更窄 B / C / D 的原因：

- Shader role、function lookup 与 library ownership 已由 pipeline state lifecycle manifest 和 backend / Metal reference pack 提供足够 vocabulary，可在下一步 admission value boundary 中只表达 no shader library / no shader function facts。
- Pipeline descriptor field、render target relation 与 pixel format relation 已在 pipeline descriptor policy vocabulary、render pass admission manifest 和 reference pack 中覆盖到足够 preflight 深度；下一步不创建 descriptor，因此无需先拆 descriptor preflight。
- Compatibility relation 已由 pipeline compatibility guard vocabulary、encoder admission endpoint 和 render pass admission endpoint共同提供 evidence；下一步只表达 compatibility admission facts，不进入 pipeline binding 或 draw call。

## 候选比较

### 候选 A：谨慎推荐 pipeline state implementation admission value boundary

选择：

`P1 internal Renderer pipeline state implementation admission value boundary bundle implementation`

该候选只允许表达 pipeline state implementation intent / shader function admission policy / pipeline descriptor admission policy / pipeline compatibility admission guard / no-pipeline-state-implementation readiness facts。

它不创建 pipeline state，不创建 shader library / shader function，不创建 pipeline descriptor，不绑定 pipeline，不调用 Metal / AppKit / Objective-C / FFI。

### 候选 B：备选 shader function admission preflight

暂不选择。

当前 shader role / function lookup / library ownership evidence 足够支撑 value boundary。只有未来发现 shader function admission owner、runtime input、failure semantics 或 library ownership evidence 不足时，才回到更窄 preflight。

### 候选 C：备选 pipeline descriptor admission preflight

暂不选择。

Descriptor field、render target relation 与 pixel format evidence 已由 pipeline state lifecycle manifest、render pass implementation admission manifest 和 reference pack 覆盖到可做 admission facts 的程度。下一步不创建 descriptor，因此不需要先单独拆分。

### 候选 D：备选 pipeline compatibility admission preflight

暂不选择。

Render pass / encoder / draw-call compatibility relation 已由 pipeline compatibility guard vocabulary、encoder admission endpoint 与 render pass admission endpoint共同支持。下一步只表达 compatibility admission guard，不绑定 pipeline，不发 draw call。

### 候选 E 到 G：暂缓后续渲染切口

Draw call implementation preflight、encoder admission hardening 与 render pass admission hardening 均暂缓。它们分别更靠近 render execution、command encoding、resource binding 或已有 admission facts 的局部补强。

### 候选 H 到 Q：拒绝直接实现或发布

拒绝 direct pipeline state creation implementation、direct shader library / shader function implementation、direct pipeline descriptor implementation、direct pipeline / buffer / texture / resource binding、direct encoder / command buffer implementation、direct Metal / AppKit / Objective-C / FFI implementation、GPU submission / render execution、renderer state write、public API / C ABI expansion、receipt / record / publication。

### 候选 R：仅限明确重复时 consolidation

当前没有 duplicate / self-wrapping evidence，不选择 consolidation。

## 同构边界刹车（Same-shape Boundary Brake）

不得把 `CjguiInternalRendererNoEncoderImplementationReadiness`、`CjguiInternalRendererNoPipelineStateReadiness`、render pass admission endpoint 或 reference evidence 包成：

- 包装成 pipeline-state implementation receipt / record / publication。
- 包装成 pipeline-ready permission wrapper。
- 包装成 shader-function permission wrapper。
- 包装成 pipeline-descriptor permission wrapper。
- 包装成 pipeline-binding permission wrapper。
- 包装成 encoder permission wrapper。
- 包装成 native-handle permission wrapper。
- 包装成 C-ABI / FFI permission wrapper。
- 包装成 GPU-submission wrapper。
- 包装成 render-permission wrapper。

若下一步进入 value boundary，必须证明新增的是 shader function admission、pipeline descriptor admission、compatibility admission 与 no-pipeline-state-implementation 语义，而不是把 no-encoder-implementation endpoint、no-pipeline-state lifecycle endpoint 或 reference evidence 换名包装。

`CjguiInternalRendererNoPipelineStateReadiness` 只作为既有 pipeline state lifecycle vocabulary evidence，不能被升级为 pipeline state implementation permission，也不能成为本次 implementation admission owner 的 runtime input。

## 停止线

在后续 docs-only preflight 或 value boundary 明确批准前，继续禁止：

- 不修改 `.cj`。
- 不新建 runtime owner。
- 不运行 `cjpm build` / smoke。
- 不触碰 `runtime_state.cj`。
- 不触碰 `runtime/cjgui/cjpm.toml`。
- 不触碰 smoke / harness / native bridge / entry。
- 不触碰 AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- 不创建 pipeline state。
- 不创建 shader library / shader function。
- 不创建 pipeline descriptor。
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
- 不调用 Metal / AppKit / Objective-C。
- 不提交 GPU submission。
- 不执行 render / draw call。
- 不写 renderer state。
- 不扩 public API。

## 公共 surface

Public declaration allowlist 仍保持：

- 唯一允许：`cjguiExperimentalQueueSubmitShellReady(): Bool`

本 preflight 不批准新增 public declaration，不批准 public C ABI，不批准 diagnostics / event bus / observer / telemetry 或 public API。

## 文档同步

本 decision 成为以下文档的 downstream 指向：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [encoder implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-admission-manifest.md)
- [pipeline state lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md)
- [render pass implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-pass-implementation-admission-manifest.md)

本 decision 的下游 value boundary closure 已记录在：

- [pipeline state implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-pipeline-state-implementation-admission-value-boundary-closure-review.md)
- [runtime_renderer_pipeline_state_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_admission.cj)

该 owner 只消费 `CjguiInternalRendererNoEncoderImplementationReadiness` / `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()`，canonical endpoint 是 `CjguiInternalRendererNoPipelineStateImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()`。它只表达 pipeline state implementation admission value facts，不批准 pipeline state、shader library / shader function、pipeline descriptor、pipeline binding、encoder、command buffer、GPU submission、render / draw call、renderer state write 或 public API permission。

下游 next-boundary decision 已记录在：

- [pipeline state implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-admission-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoPipelineStateImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()` 足够作为当前 no-pipeline-state-implementation endpoint。下一步只进入 manifest stabilization，固定 owner / truth / canonical endpoint / stop-line，不新增 pipeline-ready、shader-function、pipeline-descriptor、pipeline-binding、GPU-submission、render-permission、renderer-state-write wrapper 或 receipt / record / publication。

下游 manifest stabilization 已记录在：

- [pipeline state implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-admission-manifest.md)
- [pipeline state implementation admission manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-pipeline-state-implementation-admission-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime_renderer_pipeline_state_admission.cj` 的 owner / truth / canonical endpoint / default draft / runtime input / stop-line。它确认 `ShaderFunctionAdmissionPolicy` 不创建 shader library / shader function、不执行 function lookup；`PipelineDescriptorAdmissionPolicy` 不创建 pipeline descriptor、不写入 descriptor field、不绑定 render target / pixel format；`PipelineCompatibilityAdmissionGuard` 不执行真实 compatibility check、不绑定 pipeline。

## 验证记录

本轮 docs-only 验证结果：

- `git diff --check` 通过。
- 新 decision no-index whitespace check 通过。
- Markdown absolute link missing target check 通过；检查范围限定 project docs scope，并避开 `reference_repos/`。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability 检查通过。
- Markdown 中文标题与中文正文抽查通过。
- forbidden check 通过：无 tracked `.cj` diff，无 protected path diff/status，`runtime_state.cj` 行数仍为 `10065`。
- public declaration scan 通过：仍只能看到 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)` 完成：`changed_count=33`、`affected_count=0`、`changed_files=12`、`risk_level=low`，没有 affected processes。

本轮按约束不运行 `cjpm build`，不运行 smoke，也没有触碰 `.cj` runtime owner。

## 唯一后续入口

候选 A 的 manifest stabilization 已完成；唯一后续入口是：

`P1 internal Renderer draw call implementation preflight decision`
