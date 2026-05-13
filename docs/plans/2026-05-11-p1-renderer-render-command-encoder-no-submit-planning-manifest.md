# Render command encoder no-submit 规划清单

日期：2026-05-11

状态：manifest / completed through planning value boundary

## 固定尾点

- Actual route：A，planning / blocker facts。
- Endpoint：`CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererRenderCommandEncoderNoSubmitPlanningDraft()`
- Runtime input：`CjguiInternalRendererNoCommandBufferRuntimeCallReadiness`
- Owner：[runtime_renderer_render_command_encoder_no_submit_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_command_encoder_no_submit_planning.cj)

## 实际路线

本阶段只完成 planning value boundary：

- 固定 descriptor attachment missing facts。
- 固定 production drawable texture lifetime missing facts。
- 固定 encoder creation still blocked facts。
- 固定 draw / pipeline / vertex buffer still blocked facts。
- 固定 commit / present / GPU submit / render still blocked facts。
- 保留 drawable lifetime recovery 为独立分支。

本阶段未进入：

- native still-blocked callable。
- encoder feasibility probe。
- `MTLRenderCommandEncoder` creation。
- `renderCommandEncoderWithDescriptor`。
- color attachment configuration。
- drawable texture binding。
- pipeline state / vertex buffer creation。
- draw / `commit` / `present` / GPU submission / render。

## 上游与下游指向

上游固定：

- [Command buffer creation runway manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-command-buffer-creation-runway-manifest.md)
- [Render pass descriptor runway manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-runway-manifest.md)
- [Render pass descriptor color attachment planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-color-attachment-manifest.md)
- [Render pass descriptor color attachment recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-color-attachment-recovery-manifest.md)
- [Drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md)
- [Drawable no-present acquisition manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-no-present-acquisition-manifest.md)
- [Command queue creation runway manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-command-queue-creation-runway-manifest.md)
- [Metal device binding runway manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-metal-device-binding-runway-manifest.md)

下游已接续：

- [Render command encoder 创建阻塞归因清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-creation-blocker-reconciliation-manifest.md)

该接续确认 production drawable texture lifetime 与 `colorAttachments[0]` 是 encoder creation 的双重缺口，并把当时唯一后续入口转为 `P1 internal Renderer pipeline state no-draw planning preflight decision`。该入口现已由 [pipeline state no-draw planning 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-12-p1-renderer-pipeline-state-no-draw-planning-manifest.md) 接续。

## 停止线

不创建 encoder，不调用 `renderCommandEncoderWithDescriptor`，不 draw，不调用 `drawPrimitives` / `drawIndexedPrimitives`，不创建 pipeline state，不创建 vertex buffer，不调用 `commit`，不 present，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`，不把 planning facts 包装成 render permission、GPU submission permission、backend-ready truth 或 state write permission。

## 验证摘要

- GitNexus upstream impact：上游 endpoint / default draft 为 `UNKNOWN` / not found / impactedCount `0`；按近期新增 owner 未索引记录。
- 本轮不新增 native C ABI，不新增 native probe。
- 需以 `cjpm build`、既有 probe 回归、forbidden scan、public declaration scan 与 protected path scan 兜底。

## 唯一后续入口

`P1 internal Renderer pipeline descriptor no-draw planning preflight decision`
