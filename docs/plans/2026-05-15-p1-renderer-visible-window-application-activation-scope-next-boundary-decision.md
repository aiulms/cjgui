# P1 Renderer 可见窗口 Application Activation Scope 下一边界决策

## 当前阶段出口

application activation scope preflight 已完成 docs-only 封账。当前 canonical endpoint 仍是：

- `CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowVisibleOrderNativeGuardDraft()`

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness application activation policy value boundary bundle implementation`

## 下一段只允许的问题

- 以 internal value owner 固定 application creation / activation scope policy facts。
- 明确 application singleton ownership、main-thread gate、creation / activation deferred、bounded run loop、auto-close、content-view prerequisite 与 headless / CI-like fallback 的关系。
- 固定仍未授权 native application creation、activation、visible order、production drawable、encoder、draw、present、render 与 backend-ready truth。

## 不自动继承的权限

- 不授权 `NSApplication` creation / activation side effect。
- 不授权 `makeKeyAndOrderFront` / `orderFront`。
- 不授权 production `nextDrawable`。
- 不授权 color attachment、command buffer、encoder、draw、commit、present、GPU submission 或 render。
- 不授权 renderer state write、public API 或 build config integration。

## 设计意图出口自检

- 下一 opening 是 value boundary implementation，可以新增 `.cj` owner，但不能新增 native bridge code。
- Same-shape Boundary Brake：下一段仍必须避免 thin wrapper、receipt / record / publication wrapper 与 backend-ready 命名。

