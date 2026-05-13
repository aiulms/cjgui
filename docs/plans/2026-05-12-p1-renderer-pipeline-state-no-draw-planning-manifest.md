# Pipeline state no-draw planning 清单

日期：2026-05-12

状态：manifest / completed through A/B planning facts

## 固定尾点

- Endpoint：`CjguiInternalRendererNoPipelineStateNoDrawPlanningReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPipelineStateNoDrawPlanningDraft()`
- Runtime input：`CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness`
- Upstream owner：[runtime_renderer_render_command_encoder_no_submit_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_command_encoder_no_submit_planning.cj)
- Owner：[runtime_renderer_pipeline_state_no_draw_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_no_draw_planning.cj)

## 实际路线

本阶段完成 A/B：

- pipeline state no-draw planning / blocker facts。
- shader source / library / function availability planning facts。
- pipeline descriptor requirement planning facts。

本阶段未进入 C/D：

- 未创建 token-backed pipeline descriptor。
- 未创建 pipeline state。
- 未创建 shader library / shader function。
- 未新增 native C ABI。
- 未新增 runtime FFI call。

## 固定事实

- Pipeline state no-draw planning 可以独立于 encoder creation 推进。
- Shader library、vertex function、fragment function 是 pipeline state 的前置 requirement。
- Pipeline descriptor 是 pipeline state 的前置 requirement。
- Pipeline state create / destroy 仍 deferred。
- Encoder creation / binding 与 `setRenderPipelineState` 仍 blocked。
- Draw、vertex buffer、`commit`、`present`、GPU submission 与 render 仍 blocked。
- Planning facts 不代表 backend-ready truth、render permission、GPU submission permission 或 renderer state write permission。

## 停止线

不创建 render command encoder，不绑定 encoder，不调用 `setRenderPipelineState`，不 draw，不调用 `drawPrimitives` / `drawIndexedPrimitives`，不创建 vertex buffer，不创建 shader library / function，不创建 pipeline descriptor，不创建 pipeline state，不调用 `commit` / `present`，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 pointer / handle / `id` / `Class`。

## 上游与下游

上游固定：

- [render command encoder 创建阻塞归因清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-creation-blocker-reconciliation-manifest.md)
- [render command encoder no-submit planning 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-no-submit-planning-manifest.md)
- [command buffer creation runway 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-command-buffer-creation-runway-manifest.md)
- [pipeline state lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md)
- [pipeline state implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-admission-manifest.md)
- [real pipeline state first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-pipeline-state-first-implementation-slice-manifest.md)

下游唯一后续入口：

`P1 internal Renderer pipeline descriptor no-draw planning preflight decision`

下游接续：

- [pipeline descriptor no-draw preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-13-p1-renderer-pipeline-descriptor-no-draw-preflight-decision.md)
- [pipeline descriptor no-draw closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-13-p1-internal-renderer-pipeline-descriptor-no-draw-stage-closure-review.md)
- [pipeline descriptor no-draw manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-13-p1-renderer-pipeline-descriptor-no-draw-manifest.md)

## GitNexus 记录

上游 endpoint / default draft 在当前索引中返回 `UNKNOWN` / not found / impactedCount `0`。本清单使用源码、build、scan 与文档链兜底，不把图缺口解释为安全证明。
