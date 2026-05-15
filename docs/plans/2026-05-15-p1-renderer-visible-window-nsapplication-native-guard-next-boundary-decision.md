# P1 Renderer 可见窗口 NSApplication Native Guard 下一边界决策

## 当前阶段出口

`NSApplication` native guard preflight 已完成 docs-only admission。下一阶段可以实现 internal-only no-side-effect native guard，但必须继续保持 application creation / activation stop-line。

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication native guard no-side-effect implementation`

## 下一段只允许的问题

- production native bridge 是否能暴露 no-side-effect `NSApplication` guard integer facts。
- runtime owner 是否能消费 application activation policy endpoint，并把 guard facts 脱水为 internal readiness。
- probes 是否能证明没有 application creation、activation、event loop、visible order side effect、drawable acquisition、render 或 pointer / handle / `id` / `Class` return。

## 不自动继承的权限

- 不授权 `NSApplication` creation / activation side effect。
- 不授权 native visible order implementation。
- 不授权 production drawable acquisition。
- 不授权 color attachment、command buffer、encoder、draw、GPU submission 或 render。
- 不授权 renderer state write、public API、public C ABI 或 build config integration。

## 设计意图出口自检

下一 opening 是 no-side-effect guard implementation，不是 application implementation 或 visible-order implementation 直通。Same-shape Boundary Brake：implementation 后必须证明该 owner 不是 application-ready、visible-ready、drawable-ready、render-ready 或 backend-ready wrapper。
