# P1 渲染器 pipeline state implementation admission value boundary closure

日期：2026-05-06

状态：runtime value boundary closure

## 封账结论

本轮新增 internal-only owner：

- [runtime_renderer_pipeline_state_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_admission.cj)

该 owner 的唯一 runtime input 是 `CjguiInternalRendererNoEncoderImplementationReadiness`，默认从 `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()` 取得。Canonical endpoint 是 `CjguiInternalRendererNoPipelineStateImplementationReadiness`，默认 draft 是 `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()`。

本轮只落地 pipeline state implementation admission value facts，不创建 pipeline state，不创建 shader library / shader function，不创建 pipeline descriptor，不绑定 pipeline / buffer / texture / resource，不创建 encoder，不调用 `renderCommandEncoder` 或 `endEncoding`，不创建 command buffer，不调用 `commandBuffer` / `commit`，不调用 `present` / `nextDrawable`，不接 native handle / raw pointer、C ABI、FFI declaration、bridge / retain / release / destroy、Metal / AppKit / Objective-C / FFI，不提交 GPU work，不执行 render / draw call，不写 renderer state，不扩 public API。

## GitNexus 影响面

实施前按要求检查：

- `CjguiInternalRendererNoEncoderImplementationReadiness`：GitNexus `impact(direction=upstream)` 返回 `UNKNOWN / not found`，`impactedCount=0`。
- `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft`：GitNexus `impact(direction=upstream)` 返回 `UNKNOWN / not found`，`impactedCount=0`。

这两个符号属于近期新增 renderer admission owner，当前 GitNexus 索引未命中；未出现 HIGH / CRITICAL 阻断。本轮因此继续执行，并用源码读取、`cjpm build`、smoke guard、stop-line scan 与 GitNexus `detect_changes` 兜底。

## 新增符号

新增 internal symbols：

- `CjguiInternalRendererPipelineStateImplementationIntent`
- `CjguiInternalRendererShaderFunctionAdmissionPolicy`
- `CjguiInternalRendererPipelineDescriptorAdmissionPolicy`
- `CjguiInternalRendererPipelineCompatibilityAdmissionGuard`
- `CjguiInternalRendererNoPipelineStateImplementationReadiness`
- `cjguiInternalBuildRendererPipelineStateImplementationIntent`
- `cjguiInternalBuildRendererShaderFunctionAdmissionPolicy`
- `cjguiInternalBuildRendererPipelineDescriptorAdmissionPolicy`
- `cjguiInternalBuildRendererPipelineCompatibilityAdmissionGuard`
- `cjguiInternalBuildRendererNoPipelineStateImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft`

Value chain 固定为：

1. `CjguiInternalRendererNoEncoderImplementationReadiness`
2. `CjguiInternalRendererPipelineStateImplementationIntent`
3. `CjguiInternalRendererShaderFunctionAdmissionPolicy`
4. `CjguiInternalRendererPipelineDescriptorAdmissionPolicy`
5. `CjguiInternalRendererPipelineCompatibilityAdmissionGuard`
6. `CjguiInternalRendererNoPipelineStateImplementationReadiness`

## 当前 truth

当前 truth 仅限：

- pipeline state implementation intent value facts。
- shader function admission policy value facts。
- pipeline descriptor admission policy value facts。
- pipeline compatibility admission guard value facts。
- no-pipeline-state-implementation readiness value facts。

Open path 只形成 dehydrated admission facts；defer-only 继续保持 defer；blocked / inconsistent path fail-closed，并继续保留 no object、no binding、no foreign call、no GPU work、no render execution、no renderer state mutation 与 no publication facts。

## 边界事实

`CjguiInternalRendererPipelineStateImplementationIntent` 只记录 future pipeline state implementation intent、shader function admission need、pipeline descriptor admission need 与 compatibility admission need。它不是 pipeline-ready permission、backend implementation permission、GPU submission permission、render permission 或 public API permission。

`CjguiInternalRendererShaderFunctionAdmissionPolicy` 只记录 shader role admission、no shader asset resolution 与 failure fallback facts。它不创建 shader library，不解析 shader function，不输出 shader-ready permission。

`CjguiInternalRendererPipelineDescriptorAdmissionPolicy` 只记录 descriptor field admission、render target compatibility 与 no descriptor resource facts。它不创建 pipeline descriptor，不创建 pipeline state，不保存 platform descriptor resource。

`CjguiInternalRendererPipelineCompatibilityAdmissionGuard` 只记录 render pass、encoder 与 draw-call compatibility admission facts。它不绑定 pipeline / buffer / texture / resource，不调用 encoder，不发 draw call。

`CjguiInternalRendererNoPipelineStateImplementationReadiness` 是当前 no-pipeline-state-implementation endpoint。它不是 pipeline state permission、shader function permission、pipeline descriptor permission、pipeline binding permission、encoder permission、command buffer permission、native handle permission、C ABI permission、FFI permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

## 同构边界刹车

本轮新增的是 shader function admission、pipeline descriptor admission、compatibility admission 与 no-pipeline-state-implementation 语义。

它不是把 `CjguiInternalRendererNoEncoderImplementationReadiness`、`CjguiInternalRendererNoPipelineStateReadiness`、render pass admission endpoint 或 reference evidence 包成：

- pipeline-state implementation receipt / record / publication。
- pipeline-ready permission wrapper。
- shader-function permission wrapper。
- pipeline-descriptor permission wrapper。
- pipeline-binding permission wrapper。
- encoder permission wrapper。
- native-handle permission wrapper。
- C-ABI / FFI permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。

`CjguiInternalRendererNoPipelineStateReadiness` 仍只是 lifecycle vocabulary evidence，不是本轮 runtime input，也不是 pipeline state implementation permission。

## 文件头维护注释

新增 owner 文件保留了文件头维护注释，并覆盖：

- Owner：固定 pipeline state implementation admission 的 internal-only owner 边界。
- Truth：唯一 runtime input 与 canonical endpoint。
- Stop-line：只生成 value facts，不创建资源、不调用外部图形入口、不提交工作、不执行绘制、不写状态、不开放接口。
- Same-shape Boundary Brake：新增 shader / descriptor / compatibility admission 语义，不把上一层 readiness 包成 permission wrapper、receipt、record 或发布凭据。

## 文档同步

本轮同步更新以下入口和下游指向：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [pipeline state implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-preflight-decision.md)
- [encoder implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-admission-manifest.md)
- [pipeline state lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md)
- [render pass implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-pass-implementation-admission-manifest.md)

## 验证记录

本轮验证结果：

- `cjpm build --target-dir /tmp/cjgui-renderer-pipeline-state-admission-value-boundary-target --skip-script`：裸 `cjpm` 不在 PATH，改用本机 toolchain env 后通过；输出仍包含既有 unused warnings。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过；日志断言显示 auto-close、main-thread drain、window close、destroy complete 与 event loop exited 均正常。
- `git diff --check` 通过。
- 新 runtime / closure no-index whitespace check 通过。
- Markdown absolute link missing target check 通过，范围限定 project docs scope，并避开 `reference_repos/`。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability 检查通过。
- Markdown 中文标题与中文正文新增行抽查通过。
- Forbidden check 通过：protected paths 无 diff/status，`runtime_state.cj` 行数仍为 `10065`。
- Public declaration scan 通过：仍只看到 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- New owner stop-line scan 通过：未出现真实 pipeline state / shader library / shader function / pipeline descriptor creation、pipeline / buffer / texture binding、Metal / AppKit / Objective-C / FFI、native handle / raw pointer、C ABI、`commit` / `present` / `nextDrawable`、`public` 或 module-level `var` 的真实执行语义。
- 文件头维护注释检查通过：Owner / Truth / Stop-line / Same-shape Boundary Brake 均存在。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)` 完成：`changed_count=33`、`affected_count=0`、`changed_files=12`、`risk_level=low`，没有 affected processes。

## 唯一后续入口

`P1 internal Renderer pipeline state implementation admission closure / next pipeline state implementation decision`
