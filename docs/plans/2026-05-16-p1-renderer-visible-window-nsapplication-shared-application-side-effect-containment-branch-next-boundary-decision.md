# P1 Renderer 可见窗口 NSApplication Shared-Application Side-Effect Containment 分支下一边界决策

状态：next-boundary decision / docs-only / no runtime truth

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application singleton accessor admission preflight decision`

## 下一段只允许判断的问题

- 是否允许新增 internal fail-closed value owner，消费 side-effect containment evidence readiness。
- 是否能把 lifecycle / run-loop / teardown / headless artifact / side-effect containment evidence 共同作为 future singleton accessor admission 的前置 facts。
- 是否继续保持 actual application singleton accessor call blocked。
- 是否明确 future actual accessor call 必须另有 explicit decision。
- 是否避免把 admission facts 包成 application-ready / accessor-ready / visible-ready / drawable-ready / render-ready / backend-ready wrapper。

## 不自动继承的权限

- 不授权 application singleton accessor call。
- 不授权 `NSApplication` creation / activation。
- 不授权 activation policy mutation。
- 不授权 AppKit event loop 或 bounded pump。
- 不授权 actual teardown execution、artifact write、artifact publication 或 public diagnostics。
- 不授权 native visible order implementation。
- 不授权 production drawable acquisition。
- 不授权 color attachment、command buffer、encoder、draw、GPU submission 或 render。
- 不授权 renderer state write、public API、public C ABI 或 build config integration。

## 设计意图出口自检

- 下一 opening 是 singleton accessor admission preflight，不是 accessor call implementation。
- 上游为 side-effect containment evidence endpoint；下游为 fail-closed admission value boundary candidate。
- Same-shape Boundary Brake：下一段不得制造 application-ready、accessor-ready、visible-ready、drawable-ready、render-ready 或 backend-ready wrapper。
