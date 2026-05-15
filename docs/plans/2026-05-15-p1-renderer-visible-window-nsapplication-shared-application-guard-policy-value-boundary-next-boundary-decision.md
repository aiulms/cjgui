# P1 Renderer 可见窗口 NSApplication Shared-Application Guard Policy Value Boundary 下一边界决策

## 当前阶段出口

`NSApplication` shared-application guard policy value boundary decision 已完成 docs-only 封账。当前 canonical endpoint 仍是：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationNativeGuardReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationNativeGuardDraft()`

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application guard policy value boundary bundle implementation`

## 下一段只允许的问题

- 以 internal value owner 固定 shared-application native guard policy facts。
- 明确 application singleton accessor blocked、singleton creation blocked、main-thread gate、bounded run loop、auto-close、teardown-before-visible、non-user-visible、headless fail-closed 与 visible order 之间的关系。
- 固定仍未授权 application singleton accessor call、native application creation、activation、activation policy mutation、event loop、visible order、production drawable、encoder、draw、present、render 与 backend-ready truth。

## 不自动继承的权限

- 不授权 application singleton accessor call。
- 不授权 `NSApplication` creation / activation side effect。
- 不授权 activation policy mutation。
- 不授权 AppKit event loop。
- 不授权 `makeKeyAndOrderFront` / `orderFront`。
- 不授权 production `nextDrawable`。
- 不授权 color attachment、command buffer、encoder、draw、commit、present、GPU submission 或 render。
- 不授权 renderer state write、public API、public C ABI 或 build config integration。

## 设计意图出口自检

- 下一 opening 是 value boundary implementation，可以新增 `.cj` owner，但不能新增 native bridge code。
- Same-shape Boundary Brake：下一段仍必须避免 thin wrapper、receipt / record / publication wrapper 与 backend-ready 命名。
