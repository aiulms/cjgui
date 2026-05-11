# Drawable 环境与窗口可见性下一步裁定

## 裁定结果

选择 A/B 的后续入口：

`P1 internal Renderer drawable visible-window acquisition probe recovery/preflight decision`

## 依据

- 本轮只完成 environment / window visibility planning value boundary。
- Planning probe 未创建 isolated window，也未调用 `nextDrawable`。
- Production runtime 仍不创建 `NSWindow` / `NSApplication`。
- Display-backed layer、bounded run loop、visible window cleanup 与 no-present acquisition cleanup 仍需要 isolated probe 证明。

## 拒绝路线

- 拒绝直接进入 command queue creation planning，因为 `nextDrawable` 尚未被稳定执行。
- 拒绝直接进入 no-present drawable acquisition first slice，因为当前没有 visible-window acquisition probe 证据。
- 拒绝 present、command buffer、GPU submission、render、renderer state write 或 public API。

## 设计意图出口自检

- 本轮是否改变主题状态：是，环境规划封账为 no-window / no-acquire planning facts。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 为 `CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 environment visibility owner；truth 限 visible window / run loop / display backing 前置要求；stop-line 继续禁止 `nextDrawable`、present、command queue / buffer、GPU work、render、state write 与 public API。
- 本轮是否改变唯一 next opening：是，唯一 next opening 为 `P1 internal Renderer drawable visible-window acquisition probe recovery/preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
