# P1 渲染器 pipeline state implementation admission next-boundary 决策

日期：2026-05-06

状态：docs-only next-boundary decision

## 决策结论

`CjguiInternalRendererNoPipelineStateImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()` 已足够作为当前 no-pipeline-state-implementation endpoint。

本轮选择候选 A，唯一后续入口固定为：

`P1 internal Renderer pipeline state implementation admission manifest stabilization bundle implementation`

下一步只能固定 owner / truth / canonical endpoint / stop-line，不得新增 tail wrapper，不得靠近真实 pipeline state、shader library / shader function、pipeline descriptor、pipeline binding、encoder、command buffer、GPU submission、render / draw call、renderer state write 或 public API。

若后续新增 runtime owner 文件，必须继续保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释，且注释只说明维护边界，不得把 admission facts 写成真实 implementation permission。

## 证据读取

本轮读取并采用以下证据：

- [runtime_renderer_pipeline_state_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_admission.cj)：确认唯一 runtime input 是 `CjguiInternalRendererNoEncoderImplementationReadiness`，默认 draft 通过 `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()` 取得；value chain 最终封账到 `CjguiInternalRendererNoPipelineStateImplementationReadiness`。
- [pipeline state implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-pipeline-state-implementation-admission-value-boundary-closure-review.md)：确认新增 owner 只表达 shader function admission、pipeline descriptor admission、compatibility admission 与 no-pipeline-state-implementation readiness value facts，并记录 GitNexus / build / smoke / stop-line scan 兜底。
- [pipeline state implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-preflight-decision.md)：确认 runway 只允许 admission value boundary，不允许真实 pipeline state implementation。
- [encoder implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-admission-manifest.md)：固定上游 `CjguiInternalRendererNoEncoderImplementationReadiness` / `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()`，且该 endpoint 不授予 pipeline binding、GPU submission、render 或 public API permission。
- [pipeline state lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md)：只作为 pipeline state lifecycle vocabulary evidence；`CjguiInternalRendererNoPipelineStateReadiness` 不是本 implementation admission owner 的 runtime input，也不是 implementation permission。
- [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md)：继续要求新增 / 修改 Markdown 使用中文正文与中文章节标题，并要求后续 runtime owner 文件头维护注释覆盖 Owner / Truth / Stop-line / Same-shape Boundary Brake。

## endpoint 确认

当前 endpoint 只代表以下 value facts：

- pipeline state implementation intent。
- shader function admission policy。
- pipeline descriptor admission policy。
- pipeline compatibility admission guard。
- no-pipeline-state-implementation readiness。

`CjguiInternalRendererNoPipelineStateImplementationReadiness` 不是：

- 不是 pipeline state permission。
- 不是 shader library / shader function permission。
- 不是 pipeline descriptor permission。
- 不是 pipeline binding permission。
- 不是 encoder permission。
- 不是 command buffer permission。
- 不是 GPU submission permission。
- 不是 render permission。
- 不是 renderer state write permission。
- 不是 public API permission。

因此当前 endpoint 足够封账，但只足够进入 manifest stabilization；它不允许任何真实资源创建、绑定、提交或绘制。

## 候选比较

### 候选 A：推荐 manifest stabilization

选择：

`P1 internal Renderer pipeline state implementation admission manifest stabilization bundle implementation`

理由：value boundary 已经形成完整 endpoint，closure 也证明没有 HIGH / CRITICAL 风险、没有真实资源或 public surface 行为。下一步应固定 owner file、canonical endpoint、default draft、runtime input、current truth 与 stop-line，而不是继续添加包装层。

### 候选 B 到 E：暂缓更靠后的实现或硬化

Draw call implementation preflight 暂缓，因为它更靠近 render execution、resource binding 与 GPU submission。

Shader function admission hardening、pipeline descriptor admission hardening 与 pipeline compatibility admission hardening 均暂缓。当前 owner 已经表达 no shader library / no shader function、no descriptor resource、no pipeline / buffer / texture / resource binding 与 compatibility facts；只有未来 manifest review 发现表达不足时才回到 hardening。

### 候选 F 到 S：拒绝同构包装或直接实现

拒绝 pipeline-state receipt / record / publication、pipeline-ready permission wrapper、shader-function permission wrapper、pipeline-descriptor permission wrapper、pipeline-binding permission wrapper、encoder / command-buffer permission wrapper、GPU-submission wrapper、render-permission wrapper、direct pipeline state creation implementation、direct shader library / shader function implementation、direct pipeline descriptor implementation、direct Metal / AppKit / Objective-C / FFI implementation、renderer state write、public API / C ABI expansion。

### 候选 T：仅限明确重复时 consolidation

当前没有 duplicate / self-wrapping evidence，不选择 consolidation。

## 同构边界刹车（Same-shape Boundary Brake）

`CjguiInternalRendererNoPipelineStateImplementationReadiness` 不得继续包装成：

- pipeline-state receipt / record / publication。
- pipeline-ready permission wrapper。
- shader-function permission wrapper。
- pipeline-descriptor permission wrapper。
- pipeline-binding permission wrapper。
- encoder permission wrapper。
- command-buffer permission wrapper。
- native-handle permission wrapper。
- C-ABI / FFI permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。
- renderer-state-write wrapper。

下一步若选择 manifest stabilization，只能固定 owner / truth / canonical endpoint / default draft / stop-line，并明确当前 truth 不授予真实 implementation permission。

## 停止线

继续禁止：

- no pipeline state creation。
- no shader library / shader function creation。
- no pipeline descriptor creation。
- no pipeline / buffer / texture / resource binding。
- no encoder creation。
- no `renderCommandEncoder`。
- no `endEncoding`。
- no command buffer。
- no `commandBuffer`。
- no `commit`。
- no drawable acquisition。
- no `nextDrawable`。
- no `present`。
- no native handle。
- no raw pointer。
- no C ABI。
- no FFI declaration。
- no bridge call。
- no retain / release / destroy。
- no Metal / AppKit / Objective-C。
- no GPU submission。
- no render / draw call。
- no renderer state write。
- no public API。

本轮也继续保持 docs-only：不修改任何 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

## 文档同步

本决策同步更新：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [pipeline state implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-preflight-decision.md)
- [encoder implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-admission-manifest.md)
- [pipeline state lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md)

本决策的下游 manifest stabilization 已记录在：

- [pipeline state implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-admission-manifest.md)
- [pipeline state implementation admission manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-pipeline-state-implementation-admission-manifest-stabilization-closure-review.md)

该 manifest 只固定 [runtime_renderer_pipeline_state_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_admission.cj) 的 owner / truth / canonical endpoint / default draft / runtime input / stop-line，不新增 tail wrapper，也不批准真实 pipeline state、shader library / shader function、pipeline descriptor、pipeline binding、encoder、command buffer、GPU submission、render、renderer state write 或 public API permission。

## 验证记录

本轮 docs-only 验证结果：

- `git diff --check` 通过。
- 新 decision no-index whitespace check 通过。
- Markdown absolute link missing target check 通过；检查范围限定 project docs scope，并避开 `reference_repos/`。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability 检查通过。
- Markdown 中文标题与中文正文抽查通过。
- forbidden check 通过：无 tracked `.cj` diff，无 protected path diff/status，`runtime_state.cj` 行数仍为 `10065`。
- public declaration scan 通过：仍只能看到 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)` 完成：`changed_count=34`、`affected_count=0`、`changed_files=12`、`risk_level=low`，没有 affected processes。

本轮按约束未运行 `cjpm build`，未运行 smoke，也未修改 `.cj`。

## 唯一后续入口

`P1 internal Renderer draw call implementation preflight decision`
