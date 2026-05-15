# P1 Renderer 可见窗口生产 Harness 原生 NSWindow 下一边界决策

## 当前阶段出口

`NSWindow` harness create / destroy first slice 已完成封账。当前 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsWindowHarnessReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsWindowHarnessDraft()`

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSWindow content-view attachment preflight decision`

## 下一段只允许预检的问题

- 是否允许把既有 token-backed `NSView` 作为 `NSWindow.contentView` 的 bounded first slice。
- 是否需要新增 production native bridge 窄 C ABI 来表达 attach / detach / classify。
- 如何确保该路径仍不调用 production `nextDrawable`、不 visible order、不 present、不 commit、不创建 render encoder、不执行 render。
- 如何维持 token table cleanup 顺序，避免 `NSWindow` / `NSView` 双向生命周期泄漏。

## 不自动继承的权限

- 本阶段不授权 `makeKeyAndOrderFront`。
- 本阶段不授权 production `nextDrawable`。
- 本阶段不授权 color attachment、command buffer、encoder、draw、commit、present、GPU submission 或 render。
- 本阶段不授权 renderer state write、public API 或 build config integration。

## 设计意图出口自检

- 下一 opening 是 content-view attachment preflight，不是 implementation 直通。
- 已保留 upstream / downstream 指向：上游为 visible-window policy value boundary 与 native `NSWindow` harness， downstream 为可能的 `NSView` content-view attachment。
- Same-shape Boundary Brake：下一段仍必须先证明不是 drawable-ready / render-ready wrapper。
