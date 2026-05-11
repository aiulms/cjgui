# Drawable 可见窗口 probe 后续边界选择

## 当前证据

`CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness` 已固定 isolated visible-window environment facts：

- 可见 `NSWindow` 环境可由 isolated probe 创建并清理。
- `NSView` / `CAMetalLayer` / `MTLDevice` 可形成 display-backed layer environment。
- Bounded run loop 可执行。
- Production runtime 未新增 window semantics。
- `nextDrawable` 仍未调用。
- Present、command queue / command buffer、GPU submission 与 render 仍禁止。

## 后续候选

- A：`P1 internal Renderer drawable no-present acquisition recovery/preflight decision`
- B：`P1 internal Renderer command queue creation planning preflight decision`
- C：继续新增同构 visible-window wrapper
- D：直接进入 present / command buffer / render

## 选择

选择 A。

理由：isolated visible-window environment 已稳定，但尚未证明 no-present `nextDrawable` acquisition 不阻塞、可 cleanup、且不需要 command buffer / present / render。因此下一步只能先进入 no-present acquisition recovery / preflight。

拒绝 B/C/D：当前没有 drawable acquisition 事实，不能跳到 command queue；也不继续新增同形 wrapper；更不能进入 present、command buffer、render 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，后续边界从 visible-window probe 转向 no-present acquisition recovery / preflight。
- 本轮是否改变 canonical tail / endpoint：是，tail 为 `CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定 isolated probe facts；truth 不包含 `nextDrawable` acquisition。
- 本轮是否改变唯一 next opening：是，唯一 next opening 为 `P1 internal Renderer drawable no-present acquisition recovery/preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer drawable no-present acquisition recovery/preflight decision`
