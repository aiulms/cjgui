# P1 Renderer 可见窗口 NSApplication Shared-Application Cleanup / Headless Safety 停止线复核下一边界决策

状态：next-boundary decision / docs-only / no runtime truth

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application lifecycle / run-loop / teardown evidence gap classification decision`

## 下一段只允许判断的问题

- cleanup / headless safety facts 是否已经足够支撑 lifecycle / run-loop / teardown evidence gap 分类。
- 哪些 evidence 仍只是 value facts，哪些需要 future probe / owner / manifest 承接。
- 是否需要继续保持 actual accessor call blocked。
- 是否存在必须人工产品 / 风险判断的问题。

## 不自动继承的权限

下一段不授权 actual `sharedApplication` call、`NSApplication` creation / activation、activation policy mutation、event loop、native visible order、production drawable、color attachment、encoder、draw、GPU submission、render、renderer state write、public API、public C ABI、public diagnostics 或 build config integration。

## Same-shape Boundary Brake

下一段不得新增同构 cleanup/headless wrapper，也不得把当前 endpoint 包成 application-ready、visible-ready、drawable-ready、render-ready 或 backend-ready truth。若需要实现，只能在新决策明确批准后进入极窄 internal evidence owner 或 probe。
