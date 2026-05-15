# 绘制调用 no-submit 下一口裁定

本轮 draw call no-submit slice 已具备 pipeline state runtime facts、vertex buffer runtime facts、still-blocked native classification 与 draw input bundle facts。下一口不能跳到 encoder binding 或真实 draw，只能做 no-submit render pipeline branch reconciliation。

## 候选

- A：`P1 internal Renderer no-submit render pipeline branch reconciliation decision`。
- B：`P1 internal Renderer render command encoder creation blocker recovery decision`。
- C：`P1 internal Renderer draw call encoder binding first slice preflight decision`。
- D：拒绝直接 encoder / `setRenderPipelineState` / `setVertexBuffer` / draw / commit / present / GPU submit / render。

## 选择

选择 A。理由是当前 draw input facts 已经把 pipeline state 与 vertex buffer 两条 no-submit resource runway 聚合，但仍缺合法 render command encoder；encoder 又受 production drawable texture lifetime 与 color attachment blocker 约束。直接进入 binding 或 draw 会跨越尚未解除的显示环境与 attachment blocker。

## 后续补记

本下一口已由 no-submit render pipeline branch reconciliation 执行并封成 [里程碑清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-no-submit-render-pipeline-branch-milestone-manifest.md)，并继续由 [production drawable texture lifetime first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-production-drawable-texture-lifetime-first-slice-manifest.md) 与 [drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md) 接续。归因结果已更新为：no-submit branch 不再继续堆叠同构 wrapper，production drawable lifetime 暂停，当前唯一后续入口转为 `P1 internal Renderer visible-window production harness preflight decision`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，next boundary 从 draw call no-submit 转向 no-submit render pipeline branch reconciliation。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 固定为 `CjguiInternalRendererNoDrawInputBundleReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，draw input bundle facts 不得扩展成 draw permission。
- 本轮是否改变唯一 next opening：是，唯一 next opening 为 `P1 internal Renderer no-submit render pipeline branch reconciliation decision`。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：将在 manifest stabilization 中同步三个 Renderer 主题 manifest。
