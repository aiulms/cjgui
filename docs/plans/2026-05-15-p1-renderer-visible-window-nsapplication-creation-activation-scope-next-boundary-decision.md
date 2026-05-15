# P1 Renderer 可见窗口 NSApplication Creation / Activation Scope 下一边界决策

## 当前阶段出口

`NSApplication` creation / activation scope preflight 已完成。当前上游 endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationGuardPolicyDraft()`

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication creation and activation scope value boundary bundle implementation`

## 下一段只允许固定的事实

- application singleton creation 仍 blocked。
- activation policy mutation 仍 blocked。
- application activation 仍 blocked。
- AppKit event loop 仍 blocked。
- bounded run loop prerequisite 与 auto-close prerequisite 必须继续保持 required。
- headless / CI-like route 必须继续 fail-closed。
- native visible order、production drawable、render、GPU submission、renderer state write 与 backend-ready truth 仍 blocked。

## 不自动继承的权限

- 本阶段不授权 `NSApplication` creation / activation side effect。
- 本阶段不授权 activation policy mutation。
- 本阶段不授权 AppKit event loop。
- 本阶段不授权 native visible order implementation。
- 本阶段不授权 production drawable acquisition。
- 本阶段不授权 color attachment、command buffer、encoder、draw、GPU submission 或 render。
- 本阶段不授权 renderer state write、public API、public C ABI 或 build config integration。

## 设计意图出口自检

- 下一 opening 是 scope value boundary implementation，不是 application implementation 或 visible-order implementation 直通。
- 已保留 upstream / downstream 指向：上游为 `NSApplication` guard policy；downstream 为 future creation / activation policy refinement。
- Same-shape Boundary Brake：下一段仍必须证明不是 application-ready / visible-ready / drawable-ready / render-ready wrapper。
