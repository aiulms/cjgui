# Production drawable texture lifetime 后续边界结论

日期：2026-05-11

## 候选评估

- A：`P1 internal Renderer drawable texture lifetime implementation recovery decision`（已接续，并继续由 no-submit planning 与 blocker reconciliation 接续；当前转为 `P1 internal Renderer pipeline state no-draw planning preflight decision`）
- B：`P1 internal Renderer render pass descriptor color attachment first slice preflight decision`
- C：`P1 internal Renderer command queue / command buffer recovery decision`
- D：拒绝直接进入 encoder、present、GPU submission、render 或 renderer state write。

## 选择

选择 A。

Production drawable texture lifetime 仍停在 planning-only facts；当前没有足够证据进入 production drawable acquire / classify / release，也没有足够证据进入 descriptor color attachment first slice。

## 固定理由

- Isolated visible-window no-present `nextDrawable` 不是 production runtime truth。
- Production drawable token / texture lifetime support 尚未实现。
- Production drawable release / stale / double release classification 尚未实现。
- Descriptor / drawable / layer / device cleanup co-ownership 尚未证明。
- 继续进入 color attachment 会把 planning blocker 包装成 implementation permission。

## 停止线

下游 recovery 之前，不得新增 production drawable acquire / classify / release C ABI，不得在 production bridge 调用 `nextDrawable`，不得 present，不得创建 command buffer / encoder，不得调用 `commit`，不得提交 GPU work，不得 render，不得写 renderer state，不得新增 public API / diagnostics，不得返回 pointer / handle / `id` / `Class`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，后续边界从 color attachment recovery 切到 drawable texture lifetime recovery。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 为 `CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，truth 固定为 planning-only，不允许被解释成 drawable lifetime implementation。
- 本轮是否改变唯一 next opening：是，当时唯一 next opening 固定为 `P1 internal Renderer drawable texture lifetime implementation recovery decision`；现已由 implementation recovery、no-submit planning 与 blocker reconciliation 接续，并转为 `P1 internal Renderer pipeline state no-draw planning preflight decision`。

## 下游已接续

[Drawable texture lifetime implementation recovery decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-texture-lifetime-implementation-recovery-decision.md) 已接续本 decision。该接续选择 B：暂停 production drawable lifetime implementation，保留 visible-window production harness 为独立 recovery 分支，并将主线下一步转为 render command encoder no-submit planning。
- 是否同步 topic manifest：待 manifest stabilization 完成同步。
- 已同步哪些 topic manifest：待同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
