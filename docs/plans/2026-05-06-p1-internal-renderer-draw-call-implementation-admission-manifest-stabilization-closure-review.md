# P1 渲染器绘制调用实现准入 manifest 封账复核

日期：2026-05-06

状态：docs-only manifest stabilization closure review

## 收口结论

本轮完成 `P1 internal Renderer draw call implementation admission manifest stabilization bundle implementation`。新增 manifest：

- [2026-05-06-p1-renderer-draw-call-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-admission-manifest.md)

本轮只做 docs-only 封账，不修改任何 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

Manifest 固定 owner file：

- [runtime_renderer_draw_call_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_call_admission.cj)

Canonical endpoint 固定为 `CjguiInternalRendererNoDrawCallImplementationReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()`；runtime input 固定为 `CjguiInternalRendererNoPipelineStateImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()`。

Current truth 仅限 draw call implementation intent / primitive command admission policy / geometry binding admission guard / draw ordering admission policy / no-draw-call-implementation readiness value facts。

## manifest 固定内容

`PrimitiveCommandAdmissionPolicy` 不发出 draw call，不调用 `drawPrimitives` / `drawIndexedPrimitives`，不进入 encoder command stream。

`GeometryBindingAdmissionGuard` 不绑定 vertex buffer / index buffer / texture / sampler / resource，不保存 geometry payload，不持有 resource token。

`DrawOrderingAdmissionPolicy` 不排序真实 GPU draw，不执行 material grouping，不做 render pass mutation，不提交 GPU work。

`NoDrawCallImplementationReadiness` 不是 draw call permission、primitive command permission、geometry / resource binding permission、pipeline binding permission、encoder permission、command buffer permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

后续新增 runtime owner 文件仍必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释，且注释只能解释维护边界，不得把 admission facts 写成真实 implementation permission。

## 同构边界刹车（Same-shape Boundary Brake）

本轮只做 manifest 封账，不新增 tail wrapper。明确拒绝：

- draw-call implementation receipt / record / publication
- draw-ready permission wrapper
- primitive-command permission wrapper
- geometry-binding permission wrapper
- resource-binding permission wrapper
- pipeline-binding permission wrapper
- encoder permission wrapper
- command-buffer permission wrapper
- native-handle permission wrapper
- C-ABI / FFI permission wrapper
- GPU-submission wrapper
- render-permission wrapper
- renderer-state-write wrapper

`CjguiInternalRendererNoDrawCallImplementationReadiness` 不得继续包装成新的 tail wrapper。未来靠近 render execution implementation、resource binding admission、draw call admission hardening、pipeline state admission hardening、真实 draw call / primitive command、geometry / resource binding、pipeline binding、encoder / command buffer、GPU submission、render 或 renderer state write，必须先通过 docs-only preflight。

## 停止线

本轮继续保持：

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
- no Metal / AppKit / Objective-C
- no GPU submission
- no render
- no renderer state write
- no public API

## 文档同步

已同步：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [draw call implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-preflight-decision.md)
- [draw call implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-admission-next-boundary-decision.md)
- [pipeline state implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-admission-manifest.md)
- [draw call lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md)

同步后的唯一 next opening 是：

`P1 internal Renderer render execution implementation preflight decision`

## 验证记录

本轮按 docs-only 要求执行验证，结果如下：

- `git diff --check`：通过。
- 新 manifest / closure no-index whitespace check：通过。
- Markdown absolute link missing target check：通过，限定 project docs scope，避开 `reference_repos/`。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability：通过。
- Markdown 中文标题与中文正文抽查：通过。
- forbidden check：无 tracked `.cj` diff，protected paths 无 diff/status，`runtime_state.cj` 行数仍为 `10065`。
- public declaration scan：仍只包含 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：`risk_level=low`，`affected_count=0`，`affected_processes=[]`。

本轮未运行 `cjpm build` / smoke，未修改 `.cj`。

## 下游入口

唯一 next opening：

`P1 internal Renderer render execution implementation preflight decision`
