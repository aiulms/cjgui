# Drawable acquisition first implementation 后续边界选择

## 选择

选择 A 后续：`P1 internal Renderer drawable acquisition environment/window visibility planning decision`。

理由：本轮 recovery probe 证明 token-backed layer / device binding 路径可以清理回零，但 production bridge 仍缺少可见 window、display-backed layer 与 run loop non-blocking 证据；因此不应直接进入 `nextDrawable` no-present feasibility 或 token-local drawable table。

## 拒绝项

- 不进入 `P1 internal Renderer command queue creation planning preflight decision`，因为本轮没有完成 B/C acquisition。
- 不进入 drawable token table，因为没有 acquisition lifecycle cleanup evidence。
- 拒绝 present、command queue / command buffer、GPU submission、render、renderer state write 与 public API。

## 后续入口要求

下一轮必须先回答：

- 是否需要可见 `NSWindow` / display-backed `CAMetalLayer` 才能稳定调用 `nextDrawable`。
- 是否能在 no-present、no-command-buffer 下证明 `nextDrawable` 不阻塞。
- 是否需要专门 window visibility planning，而不是 production acquisition callable。
- 如果需要 run loop 或 visible window，则应继续 recovery，不得伪造 implementation manifest。

## 后续接续

该选择已由 [drawable environment / window visibility planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-environment-window-visibility-manifest.md) 接续，当前下游 endpoint 是 `CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness` / `cjguiInternalExecuteDefaultRendererDrawableEnvironmentVisibilityDraft()`。该接续仍未调用 `nextDrawable`，未 present，未创建 command queue / command buffer / encoder，也未把 smoke evidence 搬入 production runtime。

## 设计意图出口自检

- 本轮是否改变主题状态：是，drawable acquisition first implementation 已选择 recovery 后续。
- 本轮是否改变 canonical tail / endpoint：是，tail 指向 `CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，truth 限 blocker / recovery facts；stop-line 不变。
- 本轮是否改变唯一 next opening：是，唯一 next opening 为 `P1 internal Renderer drawable acquisition environment/window visibility planning decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
