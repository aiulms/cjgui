# No-submit 渲染管线分支里程碑清单

## 里程碑状态

状态：docs-only / milestone / sealed

No-submit render pipeline branch 已形成 milestone。它完成未来 draw 输入链的 internal facts，但没有解除 display-backed drawable、color attachment 或 render command encoder blocker。

## Runtime canonical tail

Runtime canonical tail 保持：

- endpoint：`CjguiInternalRendererNoDrawInputBundleReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererDrawInputBundleDraft()`
- runtime input：`CjguiInternalRendererNoVertexBufferRuntimeCallReadiness`
- owner：[runtime_renderer_draw_input_bundle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_input_bundle.cj)

本 milestone 不新增 runtime owner，不改变 `.cj` 文件。

## 已封账事实

- Pipeline descriptor runtime facts：[pipeline descriptor no-draw manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-13-p1-renderer-pipeline-descriptor-no-draw-manifest.md)
- Shader library / function runtime facts：[shader library no-draw manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-13-p1-renderer-shader-library-no-draw-manifest.md)
- Pipeline state runtime facts：[pipeline state create/destroy no-draw manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-13-p1-renderer-pipeline-state-create-destroy-no-draw-manifest.md)
- Vertex buffer runtime facts：[vertex buffer no-submit manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-vertex-buffer-no-submit-manifest.md)
- Draw input bundle facts：[draw call no-submit manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-draw-call-no-submit-manifest.md)

这些事实足以说明 no-submit 分支不需要继续堆叠同构 wrapper；后续应回到阻塞链。

## 阻塞链

Encoder / draw 仍被以下链路阻断：

1. Production drawable texture lifetime 未成立。
2. Render pass descriptor color attachment 尚未实现。
3. Render command encoder creation 仍无稳定合法 descriptor。
4. Pipeline state 与 vertex buffer 不能绑定到不存在的 encoder。
5. Draw call 不能在无 encoder / 无 binding 的情况下执行。

最小下一步已由 production drawable texture lifetime first slice preflight 与 implementation recovery decision 接续。该接续证明 production drawable lifetime 仍不稳，且 isolated visible-window / no-present evidence 不能直接升格为 production runtime truth；当前需要打开 visible-window production harness preflight，单独审查 visible-window ownership、bounded run loop、display-backed layer ownership 与 cleanup co-ownership。

## 停止线

本 milestone 不授权 production `nextDrawable`、color attachment configuration、render command encoder creation、encoder binding、`setRenderPipelineState`、`setVertexBuffer`、draw、`commit`、`present`、GPU submission、render、renderer state write、backend-ready truth、public API、public diagnostics、pointer / handle / `id` / `Class` return。

## 唯一后续入口

`P1 internal Renderer visible-window production harness preflight decision`

## 上游与下游

上游固定：

- [draw call no-submit manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-draw-call-no-submit-manifest.md)
- [vertex buffer no-submit manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-vertex-buffer-no-submit-manifest.md)
- [pipeline state encoder binding blocker reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-14-p1-renderer-pipeline-state-encoder-binding-blocker-reconciliation-manifest.md)
- [render command encoder creation blocker reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-creation-blocker-reconciliation-manifest.md)
- [drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md)
- [production drawable texture lifetime manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-production-drawable-texture-lifetime-manifest.md)
- [render pass descriptor color attachment recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-color-attachment-recovery-manifest.md)

下游已接续：

- [production drawable texture lifetime first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-production-drawable-texture-lifetime-first-slice-manifest.md)
- [drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md)

下游唯一入口：

- `P1 internal Renderer visible-window production harness preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是，no-submit render pipeline branch 已封为 milestone。
- 本轮是否改变 canonical tail / endpoint：否，仍为 `CjguiInternalRendererNoDrawInputBundleReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 milestone truth 与 blocker chain 结论；stop-line 不放宽。
- 本轮是否改变唯一 next opening：是，后续已由 first slice blocker refresh 与 recovery decision 转为 `P1 internal Renderer visible-window production harness preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
