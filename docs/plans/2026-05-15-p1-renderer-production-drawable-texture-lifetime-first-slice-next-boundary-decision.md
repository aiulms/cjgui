# 生产 drawable texture lifetime 第一切片后续边界裁定

## 候选路线

A：`P1 internal Renderer drawable texture lifetime implementation recovery decision`

B：`P1 internal Renderer visible-window production harness preflight decision`

C：`P1 internal Renderer render pass descriptor color attachment first slice recovery/preflight decision`

D：拒绝直接 production drawable acquire / release、color attachment、encoder、draw、commit、present 或 render。

## 选择

选择 A。

本轮已经确认 production drawable lifetime 第一切片不能安全打开 implementation。直接选择 B 会过早把 visible-window harness 作为生产 runtime 目标；直接选择 C 会跳过 drawable texture lifetime 的生产 ownership 证明。因此下一步先进入 recovery decision，把缺口拆清楚，再决定是 visible-window production harness、production drawable lifetime first slice，还是继续保持 color attachment blocked。

后续已由 [drawable texture lifetime implementation recovery decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-drawable-texture-lifetime-implementation-recovery-decision.md) 接续，并选择 A：暂停 production drawable lifetime implementation，拆出 visible-window production harness 分支。当前唯一后续入口转为：

`P1 internal Renderer visible-window production harness preflight decision`

## 下一步必须回答

- production visible-window harness 是否应该成为主线，还是保持 isolated experiment。
- production drawable token table 是否能在不 present、不 command buffer、不 encoder 的前提下建立。
- `nextDrawable` 是否仍依赖可见窗口 / bounded run loop / display-backed layer。
- cleanup co-ownership 是否能覆盖 drawable / layer / device / view。
- render pass descriptor color attachment 是否必须等待 production drawable lifetime。

## 本轮禁止的误读

- first-slice preflight blocked 不等于 Renderer 失败。
- isolated no-present `nextDrawable` 不等于 production drawable lifetime。
- no-submit milestone 不等于 display chain 已完成。
- token-backed layer/device facts 不等于 drawable texture 可安全获取。
- 本轮不授予 color attachment、encoder、draw、commit、present、GPU submission、render、renderer state write 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是。第一切片 next boundary 明确转入 recovery。
- 本轮是否改变 canonical tail / endpoint：否。
- 本轮是否改变 owner / truth / stop-line：是。truth 增加 recovery 优先级；stop-line 保持禁止 production `nextDrawable`。
- 本轮是否改变唯一 next opening：是。当时唯一后续入口为 `P1 internal Renderer drawable texture lifetime implementation recovery decision`；后续已由 recovery decision 接续并转为 `P1 internal Renderer visible-window production harness preflight decision`。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
