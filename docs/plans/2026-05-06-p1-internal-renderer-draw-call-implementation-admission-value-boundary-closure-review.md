# P1 渲染器绘制调用实现准入值边界封账复核

日期：2026-05-06

状态：implementation closure review

## 收口结论

本轮完成 `P1 internal Renderer draw call implementation admission value boundary bundle implementation`，新增 internal-only owner：

- [runtime_renderer_draw_call_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_call_admission.cj)

该 owner 的唯一 runtime input 是 `CjguiInternalRendererNoPipelineStateImplementationReadiness`，默认从 `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()` 获取。Canonical endpoint 是 `CjguiInternalRendererNoDrawCallImplementationReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()`。

本轮只新增 draw call implementation intent / primitive command admission policy / geometry binding admission guard / draw ordering admission policy / no-draw-call-implementation readiness value facts。它不发出 draw call，不调用 `drawPrimitives` / `drawIndexedPrimitives`，不绑定 vertex / index buffer、texture、sampler、resource 或 pipeline，不创建 encoder / command buffer，不提交 GPU work，不执行 render，不写 renderer state，不扩 public API。

## GitNexus 影响面

实施前已按要求对上游 symbols 做 GitNexus impact：

- `CjguiInternalRendererNoPipelineStateImplementationReadiness`：结果为 `UNKNOWN / target not found`，`impactedCount=0`。
- `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft`：结果为 `UNKNOWN / target not found`，`impactedCount=0`。

两项均未返回 `HIGH` 或 `CRITICAL`。因近期新增 owner 尚未进入索引，本轮以源码读取、`cjpm build`、smoke、stop-line scan 与 GitNexus detect changes 兜底确认。

## 新增 runtime owner

新增 internal symbols：

- `CjguiInternalRendererDrawCallImplementationIntent`
- `CjguiInternalRendererPrimitiveCommandAdmissionPolicy`
- `CjguiInternalRendererGeometryBindingAdmissionGuard`
- `CjguiInternalRendererDrawOrderingAdmissionPolicy`
- `CjguiInternalRendererNoDrawCallImplementationReadiness`
- `cjguiInternalBuildRendererDrawCallImplementationIntent`
- `cjguiInternalBuildRendererPrimitiveCommandAdmissionPolicy`
- `cjguiInternalBuildRendererGeometryBindingAdmissionGuard`
- `cjguiInternalBuildRendererDrawOrderingAdmissionPolicy`
- `cjguiInternalBuildRendererNoDrawCallImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()`

文件头维护注释已覆盖 Owner / Truth / Stop-line / Same-shape Boundary Brake。注释只说明维护边界，不把 admission facts 写成真实 implementation permission。

## 语义边界

`CjguiInternalRendererDrawCallImplementationIntent` 只表达未来 draw call implementation intent 与 primitive / geometry / ordering admission need，不是 draw-ready permission、backend implementation permission、GPU submission permission、render permission 或 public API permission。

`CjguiInternalRendererPrimitiveCommandAdmissionPolicy` 只表达 primitive command admission value facts，不发出 draw command，不调用 `drawPrimitives` / `drawIndexedPrimitives`，不进入 encoder command stream。

`CjguiInternalRendererGeometryBindingAdmissionGuard` 只表达 geometry binding admission guard，不保存 geometry payload，不持有 texture / sampler / resource token，不表达 pipeline / resource binding permission。

`CjguiInternalRendererDrawOrderingAdmissionPolicy` 只表达 ordering admission facts，不排序、不 batching、不改变 renderer state，不提交 GPU work。

`CjguiInternalRendererNoDrawCallImplementationReadiness` 是当前 no-draw-call-implementation endpoint。它不是 draw call permission、primitive command permission、geometry binding permission、resource binding permission、pipeline binding permission、encoder permission、command buffer permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

## 同构边界刹车

本轮新增的是 primitive command admission / geometry binding admission / draw ordering admission / no-draw-call-implementation 语义，不是把以下 evidence 换名包装：

- `CjguiInternalRendererNoPipelineStateImplementationReadiness`
- `CjguiInternalRendererNoDrawCallReadiness`
- encoder admission endpoint
- backend / Metal reference evidence

明确拒绝 draw-call implementation receipt / record / publication、draw-ready permission wrapper、primitive-command permission wrapper、geometry-binding permission wrapper、resource-binding permission wrapper、pipeline-binding permission wrapper、encoder permission wrapper、native-handle permission wrapper、C-ABI / FFI permission wrapper、GPU-submission wrapper 或 render-permission wrapper。

## 停止线

本轮新增 owner 与文档同步继续保持：

- no draw call
- no `drawPrimitives`
- no `drawIndexedPrimitives`
- no vertex / index buffer binding
- no texture / sampler / resource binding
- no pipeline binding
- no pipeline state / shader / descriptor creation
- no encoder creation
- no `renderCommandEncoder`
- no `endEncoding`
- no command buffer
- no `commandBuffer`
- no `commit`
- no drawable acquisition
- no `nextDrawable`
- no `present`
- no native handle
- no raw pointer
- no C ABI
- no FFI declaration
- no bridge call
- no retain / release / destroy
- no Metal / AppKit / Objective-C / FFI
- no GPU submission
- no render
- no renderer state write
- no public API
- no module-level `var`

## 验证记录

已执行：

- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-renderer-draw-call-admission-value-boundary-target --skip-script`：通过；仅保留项目既有 unused warnings。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过；auto-close log assertions passed。

最终收口验证：

- `git diff --check`：通过。
- 新 runtime / closure no-index whitespace check：通过。
- Markdown absolute link missing target check：通过，限定 project docs scope，避开 `reference_repos/`。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability：通过，四个入口均指向本 closure、owner 与下一步。
- Markdown 中文标题与中文正文抽查：通过；标题主体保持中文，英文只保留代码符号、路径、API 名称、工具命令和固定治理术语。
- forbidden check：protected paths 无 diff/status；`runtime_state.cj` 行数仍为 `10065`。
- public declaration scan：仍只包含 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- new owner stop-line scan：通过，未出现真实 draw call API、真实 resource / pipeline binding、Metal / AppKit / Objective-C / FFI、native handle / raw pointer、C ABI、`commit` / `present` / `nextDrawable`、public 或 module-level `var`。
- 文件头维护注释检查：通过，Owner / Truth / Stop-line / Same-shape Boundary Brake 均存在。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：`risk_level=low`，`affected_count=0`。

## 下游入口

唯一 next opening：

`P1 internal Renderer draw call implementation admission closure / next draw call implementation decision`
