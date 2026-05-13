# Pipeline state no-draw planning 预检判断

日期：2026-05-12

状态：已选择 A/B，暂缓 C/D

## 背景

上游 [render command encoder 创建阻塞归因清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-creation-blocker-reconciliation-manifest.md) 已固定路线 C：encoder creation 的直接缺口是 production drawable texture lifetime 与 `colorAttachments[0]`，主线转向 pipeline state no-draw planning。

本阶段 runtime input 固定为 `CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness`，上游 owner 是 [runtime_renderer_render_command_encoder_no_submit_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_command_encoder_no_submit_planning.cj)。

## 预检结论

本轮选择 A/B：

- A：新增 pipeline state no-draw planning owner。
- B：固定 shader library / vertex function / fragment function / pipeline descriptor requirement planning facts。

本轮暂缓 C/D：

- C 需要更窄的 pipeline descriptor token-backed planning preflight，避免把 descriptor requirement 写成 descriptor object permission。
- D 需要 shader library / function / descriptor 与 cleanup 证据，不在本轮创建 pipeline state。

## 关键判断

- Pipeline state no-draw planning 可以独立推进，因为它只固定 shader/library/function 与 descriptor 合同，不依赖 encoder creation。
- Shader library / function 目前只能作为 requirement facts，不创建 `MTLLibrary` / `MTLFunction`，不做 function lookup。
- Pipeline descriptor 目前只能作为 requirement facts，不创建 `MTLRenderPipelineDescriptor`，不写 pixel format / attachment relation 到 native object。
- Pipeline state create / destroy 不能进入本轮，因为缺 shader object、descriptor object 与 cleanup ownership 证据。
- Encoder binding 明确 blocked；不得调用 `setRenderPipelineState`。
- Draw / vertex buffer / `commit` / `present` / GPU submission / render 均继续 blocked。

## GitNexus 记录

对上游 endpoint 与 default draft 运行 impact：

- `CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness`：当前索引返回 not found / impactedCount `0` / risk `UNKNOWN`。
- `cjguiInternalExecuteDefaultRendererRenderCommandEncoderNoSubmitPlanningDraft`：当前索引返回 not found / impactedCount `0` / risk `UNKNOWN`。

该结果只说明近期新增 owner 未覆盖到图索引，不视为安全证明。本轮用源码阅读、build、owner header scan、forbidden scan 与 manifest 检查兜底。

## 停止线

本轮不得创建 render command encoder，不得绑定 encoder，不得调用 `setRenderPipelineState`，不得 draw，不得创建 vertex buffer，不得 `commit` / `present`，不得提交 GPU work，不得执行 render，不得写 renderer state，不得触碰 `runtime_state.cj`，不得修改 `runtime/cjgui/cjpm.toml`，不得修改 smoke native files，不得新增 public API / diagnostics，不得返回 native pointer / handle / `id` / `Class`。

## 选择结果

新增 owner：

- [runtime_renderer_pipeline_state_no_draw_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_no_draw_planning.cj)

Canonical endpoint：

- `CjguiInternalRendererNoPipelineStateNoDrawPlanningReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererPipelineStateNoDrawPlanningDraft()`

唯一后续入口：

`P1 internal Renderer pipeline descriptor no-draw planning preflight decision`

## 设计意图出口自检

- 本轮改变主题状态：是，Renderer implementation admission chain 从 encoder blocker reconciliation 进入 pipeline state no-draw planning。
- 本轮改变 canonical tail / endpoint：是，新增 no-draw planning endpoint，但不覆盖上游 encoder endpoint。
- 本轮改变 owner / truth / stop-line：是，新增 owner 与 planning truth；stop-line 继续禁止 encoder / draw / submit / render。
- 本轮改变唯一 next opening：是，转为 `P1 internal Renderer pipeline descriptor no-draw planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
