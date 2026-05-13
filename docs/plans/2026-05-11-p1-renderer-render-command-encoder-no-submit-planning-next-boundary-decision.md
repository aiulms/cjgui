# Render command encoder no-submit 后续边界判断

日期：2026-05-11

状态：next-boundary decision / completed

## 当前尾点是否足够

`CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness` 足够作为当前 no-submit planning 尾点。它证明的不是 encoder creation，而是：

- encoder creation 仍被 color attachment 与 production drawable texture lifetime 缺口阻断。
- command buffer runtime call facts 只允许规划 no-submit 前置条件。
- draw / pipeline / vertex buffer / commit / present / GPU submission / render 都仍被拒绝。

## 选择

选择 A：

`P1 internal Renderer render command encoder creation blocker reconciliation decision`

该入口已由 [render command encoder 创建阻塞归因清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-creation-blocker-reconciliation-manifest.md) 接续；当前唯一后续入口已转为 `P1 internal Renderer pipeline state no-draw planning preflight decision`。

理由：

- 下一步应先对账 encoder creation 的 blocker 来源：command buffer、descriptor lifecycle、color attachment recovery、drawable texture lifetime recovery 与 native still-blocked facts。
- 不应直接进入 pipeline state no-draw planning，因为真实 encoder 尚未创建。
- 不应直接创建 encoder feasibility probe，因为 color attachment 与 drawable texture lifetime 仍未成立。

## 暂缓

- `P1 internal Renderer render command encoder still-blocked callable first implementation preflight decision`
- `P1 internal Renderer render command encoder no-submit feasibility probe preflight decision`
- `P1 internal Renderer pipeline state no-draw planning preflight decision`

这些入口必须等 blocker reconciliation 明确是否需要新增 native callable、是否仍停在 planning、是否可安全进入 isolated feasibility。

## 拒绝

拒绝 direct encoder creation、`renderCommandEncoderWithDescriptor`、draw、pipeline state、vertex buffer、`commit`、present、GPU submission、render、renderer state write、public API / diagnostics、pointer / handle / `id` / `Class` return。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 no-submit planning implementation 转入 blocker reconciliation。
- 本轮是否改变 canonical tail / endpoint：不再新增 endpoint，本轮确认当前尾点足够。
- 本轮是否改变 owner / truth / stop-line：不改变 owner；确认 truth 只限 no-submit planning blocker facts。
- 本轮是否改变唯一 next opening：是，当时固定为 `P1 internal Renderer render command encoder creation blocker reconciliation decision`；现已由 blocker reconciliation 接续，当前唯一 next opening 为 `P1 internal Renderer pipeline state no-draw planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer pipeline state no-draw planning preflight decision`
