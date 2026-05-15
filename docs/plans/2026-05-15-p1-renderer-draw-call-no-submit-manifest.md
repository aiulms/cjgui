# 绘制调用 no-submit 清单

## 阶段路线

本阶段完成 A/B/C：

- A：draw call no-submit planning / dependency facts。
- B：draw call still-blocked native callable + runtime facts。
- C：draw input bundle planning facts。

## 固定接口

Production native callable list 固定为：

- `cjgui_native_bridge_draw_call_encoder_required(void)` -> `int32_t`
- `cjgui_native_bridge_draw_call_pipeline_binding_required(void)` -> `int32_t`
- `cjgui_native_bridge_draw_call_vertex_binding_required(void)` -> `int32_t`
- `cjgui_native_bridge_draw_call_still_blocked(void)` -> `int32_t`

这些 callable 只返回负向 classification，不创建 encoder，不绑定 pipeline / vertex buffer，不发 draw，不提交 GPU work。

## runtime tail

- endpoint：`CjguiInternalRendererNoDrawInputBundleReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererDrawInputBundleDraft()`
- runtime input：`CjguiInternalRendererNoVertexBufferRuntimeCallReadiness`
- owner chain：[runtime_renderer_draw_call_no_submit_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_call_no_submit_planning.cj)、[runtime_renderer_draw_call_still_blocked.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_call_still_blocked.cj)、[runtime_renderer_draw_input_bundle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_input_bundle.cj)

## draw input facts

Draw input bundle 只聚合 pipeline state runtime facts 与 vertex buffer runtime facts。pipeline state 表示 token-backed `MTLRenderPipelineState` lifecycle 已可被 runtime-local call 观察；vertex buffer 表示 token-backed `MTLBuffer` lifecycle 与 static triangle data upload 已可被 runtime-local call 观察。二者都不是 encoder binding permission，也不携带跨函数 token persistence。

## stop-line

本 manifest 不授权 render command encoder creation，不授权 `setRenderPipelineState`，不授权 `setVertexBuffer`，不授权 draw，不授权 index buffer，不授权 `commit` / `present`，不授权 GPU submission，不授权 render，不授权 renderer state write，不授权 backend-ready truth，不授权 public API / diagnostics，不授权 pointer / handle / `id` / `Class` return。

## 证据链

- Preflight：[绘制调用 no-submit 预检裁定](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-draw-call-no-submit-preflight-decision.md)
- Closure：[绘制调用 no-submit 阶段收束复核](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-internal-renderer-draw-call-no-submit-stage-closure-review.md)
- Next-boundary：[绘制调用 no-submit 下一口裁定](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-draw-call-no-submit-next-boundary-decision.md)

## 上游与下游

上游固定：

- [顶点缓冲 no-submit 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-vertex-buffer-no-submit-manifest.md)
- [pipeline state create/destroy no-draw manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-13-p1-renderer-pipeline-state-create-destroy-no-draw-manifest.md)
- [pipeline state encoder 绑定阻塞归因清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-14-p1-renderer-pipeline-state-encoder-binding-blocker-reconciliation-manifest.md)
- [render command encoder 创建阻塞归因清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-creation-blocker-reconciliation-manifest.md)
- [绘制调用 lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md)
- [绘制调用实现准入 manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-admission-manifest.md)

下游唯一入口：

`P1 internal Renderer no-submit render pipeline branch reconciliation decision`

该下一步只能对 no-submit pipeline branch 做 docs-first reconciliation，不得创建 encoder，不得绑定 pipeline 或 vertex buffer，不得 draw，不得提交 GPU work。

后续补记：

- 已由 [No-submit 渲染管线分支归因裁定](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-no-submit-render-pipeline-branch-reconciliation-decision.md) 与 [No-submit 渲染管线分支里程碑清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-no-submit-render-pipeline-branch-milestone-manifest.md) 接续。
- 后续又由 [production drawable texture lifetime first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-production-drawable-texture-lifetime-first-slice-manifest.md) 与 [drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md) 接续。
- 当前唯一后续入口已转为 `P1 internal Renderer visible-window production harness preflight decision`。
- 该接续不改变本 manifest 的 stop-line：draw input bundle facts 仍不是 encoder、binding、draw、commit、present、GPU submission、render 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，draw call no-submit 从规划推进到 still-blocked C ABI 与 draw input bundle facts 封账。
- 本轮是否改变 canonical tail / endpoint：是，tail 固定为 `CjguiInternalRendererNoDrawInputBundleReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 owner chain 只产出 internal dehydrated facts；truth 仍不写 renderer state；stop-line 继续禁止 encoder / bind / draw / commit / present / GPU submission / render。
- 本轮是否改变唯一 next opening：是，唯一后续入口固定为 `P1 internal Renderer no-submit render pipeline branch reconciliation decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
