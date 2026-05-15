# Render command encoder 创建阻塞归因清单

日期：2026-05-11

状态：docs-only / manifest / no runtime truth

## 固定结论

本阶段固定路线 C：render command encoder creation 不进入 implementation；主线转向 pipeline state no-draw planning。

runtime canonical tail 不变：

- Endpoint：`CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererRenderCommandEncoderNoSubmitPlanningDraft()`
- Owner：`runtime/cjgui/src/runtime_renderer_render_command_encoder_no_submit_planning.cj`
- Runtime input：`CjguiInternalRendererNoCommandBufferRuntimeCallReadiness`

## 阻塞事实

- production drawable texture lifetime 尚未成立。
- isolated visible-window no-present drawable acquisition 不等于 production drawable token / texture lifetime。
- descriptor / drawable / layer / device cleanup 共同所有权尚未证明。
- `MTLRenderPassDescriptor.colorAttachments[0]` 尚未配置。
- 没有不依赖 drawable texture / color attachment 的稳定 encoder creation route。
- encoder creation 仍必须 fail-closed。

## Pipeline state no-draw 前置判断

pipeline state no-draw planning 可以独立推进，因为它可以先固定 contract：

- shader library / shader function admission policy。
- pipeline descriptor admission policy。
- pixel format / attachment compatibility planning。
- no-encoder-binding policy。
- no-draw / no-submit / no-render stop-line。

它不能直接创建 shader library、shader function、pipeline descriptor 或 pipeline state；如果下一步要求 encoder binding、draw、commit、present、GPU submission 或 render，必须停在 planning / blocker。

## 禁止误读

本清单不是 runtime truth，不授权：

- 创建 `MTLRenderCommandEncoder`。
- 调用 `renderCommandEncoderWithDescriptor`。
- 配置 `colorAttachments[0]`。
- 绑定 drawable texture。
- 创建 pipeline state / vertex buffer。
- 调用 draw / `commit` / `present`。
- 提交 GPU work 或执行 render。
- 写 renderer state 或触碰 `runtime_state.cj`。
- 新增 public API / diagnostics。
- 返回 pointer / handle / `id` / `Class`。

## 下游

唯一后续入口：

`P1 internal Renderer pipeline state no-draw planning preflight decision`

本 manifest 由 [render command encoder 创建阻塞归因判断](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-creation-blocker-reconciliation-decision.md) 与 [render command encoder 创建阻塞归因封账](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-internal-renderer-render-command-encoder-creation-blocker-reconciliation-closure-review.md) 固定。

## 下游已接续

本 manifest 已由 [pipeline state no-draw planning 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-12-p1-renderer-pipeline-state-no-draw-planning-manifest.md) 接续。该下游新增 `CjguiInternalRendererNoPipelineStateNoDrawPlanningReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateNoDrawPlanningDraft()`，只固定 shader/library/function requirement、pipeline descriptor requirement、pipeline state create deferred、encoder binding blocked、draw blocked 与 GPU submission blocked facts；仍不创建 shader library / function、pipeline descriptor、pipeline state 或 encoder，不调用 `setRenderPipelineState`，不 draw，不 `commit` / `present`，不提交 GPU work，不执行 render。

当前最新后续入口已转为：

`P1 internal Renderer pipeline descriptor no-draw planning preflight decision`

## 下游补充接续

后续 pipeline descriptor no-draw、shader library no-draw、pipeline state create/destroy no-draw、vertex buffer no-submit、draw call no-submit 与 no-submit render pipeline branch milestone 已继续推进到 [No-submit 渲染管线分支里程碑清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-no-submit-render-pipeline-branch-milestone-manifest.md)，并由 production drawable texture lifetime first slice blocker refresh 与 [drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md) 接续。该补充接续确认：即使 token-backed `MTLRenderPipelineState` lifecycle、token-backed `MTLBuffer` lifecycle 与 draw input bundle facts 已成立，encoder binding 仍必须等待 render command encoder；而 render command encoder 仍受 production drawable texture lifetime 与 color attachment 缺口阻断。当前后续入口转为 `P1 internal Renderer visible-window production harness preflight decision`。
