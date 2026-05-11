# Drawable acquisition 后续入口结论

## 选择结果

唯一后续入口：

`P1 internal Renderer drawable acquisition first implementation recovery/preflight decision`

## 选择原因

本轮已经固定 drawable acquisition planning 与 availability / still-blocked facts，但没有执行 `nextDrawable`，也没有建立 drawable lifecycle、drawable cleanup、present denial implementation、command queue / command buffer prerequisite 或 headless / CI-like stability proof。

因此下一步不能直接进入 command queue creation planning，也不能把 no-acquire facts 解释成 drawable exists。下一步必须先围绕 drawable acquisition first implementation 做 recovery / preflight，明确 `nextDrawable` 是否仍应停在 blocked callable、是否需要 isolated feasibility、以及如何在不 present、不创建 command buffer、不提交 GPU work 的前提下处理 drawable lifecycle。

## 拒绝路线

- 拒绝把 drawable availability facts 包装成 backend-ready truth。
- 拒绝直接进入 present / command queue / command buffer / render。
- 拒绝新增 public API / diagnostics。
- 拒绝返回 drawable pointer / handle / `id` / `Class`。
- 拒绝写 renderer state 或触碰 `runtime_state.cj`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，drawable acquisition A/B 已封账，C 仍未打开。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 为 `CjguiInternalRendererNoDrawableAvailabilityReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 链增加 planning / availability；truth 是 no-acquire / still-blocked facts；stop-line 继续禁止 `nextDrawable`、present、command queue / buffer、GPU work、render、state write 与 public API。
- 本轮是否改变唯一 next opening：是，唯一 next opening 为 `P1 internal Renderer drawable acquisition first implementation recovery/preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

## 下游接续

本后续入口已由 [Drawable acquisition first implementation 后续边界选择](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-acquisition-first-implementation-next-boundary-decision.md) 接续，并进一步选择 `P1 internal Renderer drawable acquisition environment/window visibility planning decision`。该接续不批准 `nextDrawable`、present、command queue / command buffer、GPU submission、render、state write 或 public API。
