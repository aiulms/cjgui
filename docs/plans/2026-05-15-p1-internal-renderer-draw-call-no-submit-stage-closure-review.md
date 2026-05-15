# 绘制调用 no-submit 阶段收束复核

本阶段完成 draw call no-submit route A/B/C。新增 production still-blocked C ABI、runtime internal owner 与 probe，但仍不接 renderer backend truth。

## 本轮新增

- native callable：`cjgui_native_bridge_draw_call_encoder_required`、`cjgui_native_bridge_draw_call_pipeline_binding_required`、`cjgui_native_bridge_draw_call_vertex_binding_required`、`cjgui_native_bridge_draw_call_still_blocked`。
- runtime owner：[runtime_renderer_draw_call_no_submit_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_call_no_submit_planning.cj)、[runtime_renderer_draw_call_still_blocked.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_call_still_blocked.cj)、[runtime_renderer_draw_input_bundle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_input_bundle.cj)。
- native probe：[verify_native_bridge_draw_call_still_blocked.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_draw_call_still_blocked.sh)。

## 当前事实

Draw call no-submit 现在只接受已封账的 pipeline state runtime facts 与 vertex buffer runtime facts。新增 C ABI 只返回 fail-closed / still-blocked 分类：encoder required、pipeline binding required、vertex binding required 与 draw still blocked。runtime owner 调用这些 callable 后只保留 dehydrated facts，不保存 token，不写 state，不发布 backend-ready truth。

## 保持关闭

本阶段没有创建 render command encoder，没有调用 `setRenderPipelineState`，没有调用 `setVertexBuffer`，没有 draw，没有 index buffer，没有 command buffer commit，没有 present，没有 GPU submission，没有 render，没有 renderer state write，没有 public API，没有 pointer / handle / `id` / `Class` return。

## GitNexus 记录

GitNexus impact 对 `CjguiInternalRendererNoVertexBufferRuntimeCallReadiness`、`cjguiInternalExecuteDefaultRendererVertexBufferRuntimeCallDraft()` 与新增 `cjgui_native_bridge_draw_call_*` symbol 返回 UNKNOWN / not found。该结果未被当成安全证明；本轮以源码阅读、native probe、target `cjpm build`、symbol / forbidden scan 与后续全量回归兜底。

## 后续补记

本阶段已由 [No-submit 渲染管线分支归因裁定](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-no-submit-render-pipeline-branch-reconciliation-decision.md)、[里程碑清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-no-submit-render-pipeline-branch-milestone-manifest.md)、[production drawable texture lifetime first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-production-drawable-texture-lifetime-first-slice-manifest.md) 与 [drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md) 接续。当前主线转为 `P1 internal Renderer visible-window production harness preflight decision`；draw call no-submit facts 仍不得解释成 encoder / binding / draw / submit / render 权限。

## 设计意图出口自检

- 本轮是否改变主题状态：是，draw call 从 no-submit planning 进入 still-blocked native facts 与 draw input bundle facts。
- 本轮是否改变 canonical tail / endpoint：是，tail 更新为 `CjguiInternalRendererNoDrawInputBundleReadiness` / `cjguiInternalExecuteDefaultRendererDrawInputBundleDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 draw call owner 与 native callable；stop-line 明确禁止 encoder、binding、draw、commit、present、GPU submission、render 与 state write。
- 本轮是否改变唯一 next opening：是，建议 `P1 internal Renderer no-submit render pipeline branch reconciliation decision`。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：将在 manifest stabilization 中同步三个 Renderer 主题 manifest。
