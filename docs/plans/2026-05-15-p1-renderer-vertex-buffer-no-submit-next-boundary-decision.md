# 顶点缓冲 no-submit 下一口裁定

本轮 vertex buffer no-submit first slice 已具备 fixed-capacity `MTLBuffer` table、static triangle data upload 与 runtime-local FFI call evidence。下一口不能跳到 encoder binding 或 draw，只能继续做 draw call no-submit planning。

## 候选

- A：`P1 internal Renderer draw call no-submit planning preflight decision`。
- B：`P1 internal Renderer render command encoder creation blocker recovery decision`。
- C：`P1 internal Renderer vertex buffer encoder binding preflight decision`。
- D：拒绝直接 `setVertexBuffer` / draw / commit / present / GPU submit / render。

## 选择

选择 A。理由是 vertex buffer facts 只证明 draw input resource 可以以 token-local no-submit 形式存在；它不补齐 render command encoder、color attachment 或 drawable texture lifetime。直接进入 encoder binding 会跨越尚未解除的 blocker。

## 设计意图出口自检

- 本轮是否改变主题状态：是，next boundary 从 vertex buffer no-submit 转向 draw call no-submit planning。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 固定为 `CjguiInternalRendererNoVertexBufferRuntimeCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，vertex buffer facts 不得扩展成 draw permission。
- 本轮是否改变唯一 next opening：是，唯一 next opening 为 `P1 internal Renderer draw call no-submit planning preflight decision`。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：将在 manifest stabilization 中同步三个 Renderer 主题 manifest。

## 下游接续

该 next opening 已由 [绘制调用 no-submit 预检裁定](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-draw-call-no-submit-preflight-decision.md) 接续；最新唯一后续入口已转为 `P1 internal Renderer no-submit render pipeline branch reconciliation decision`。
