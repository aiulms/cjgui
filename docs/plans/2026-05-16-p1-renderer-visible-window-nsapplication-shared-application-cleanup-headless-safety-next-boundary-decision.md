# P1 Renderer 可见窗口 NSApplication Shared-Application Cleanup / Headless Safety 下一边界决策

状态：next-boundary decision / no runtime truth

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application cleanup / headless safety stop-line reconciliation decision`

## 下一段只允许判断的问题

- Cleanup / headless safety value facts 是否足够作为当前 non-call evidence endpoint。
- 是否继续保持 actual accessor call blocked。
- 是否仍缺 lifecycle / run-loop / teardown / artifact evidence，或可以转向下一 visible-window harness prerequisite。
- 是否需要人类产品 / 风险判断才可讨论 actual application singleton accessor call。

## 不自动继承的权限

本阶段不授权 application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、event loop、native visible order、production drawable、color attachment、encoder、draw、GPU submission、render、renderer state write、public API、public C ABI、public diagnostics 或 build config integration。

## 设计意图出口自检

- 下一 opening 是 stop-line reconciliation，不是 accessor call implementation。
- 上游为 cleanup / headless safety endpoint。
- Same-shape Boundary Brake：下一段不得把 cleanup facts 包成 application-ready、visible-ready、drawable-ready、render-ready 或 backend-ready wrapper。
