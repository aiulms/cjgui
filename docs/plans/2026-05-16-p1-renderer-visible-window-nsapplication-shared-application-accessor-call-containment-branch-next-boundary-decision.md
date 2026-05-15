# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Call Containment 分支下一边界决策

状态：next-boundary decision / docs-only / no runtime truth

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application cleanup / headless safety preflight decision`

## 下一段只允许判断的问题

- 是否允许新增 internal value-style owner，消费 containment policy readiness。
- 是否能把 cleanup co-ownership、headless fail-closed、CI artifact policy、main-thread ownership proof 与 teardown proof 固化为 value facts。
- 是否继续保持 actual application singleton accessor call blocked。
- 是否避免把 smoke / CI artifact / probe evidence 升级成 runtime truth。

## 不自动继承的权限

- 不授权 application singleton accessor call。
- 不授权 `NSApplication` creation / activation。
- 不授权 activation policy mutation。
- 不授权 AppKit event loop。
- 不授权 native visible order implementation。
- 不授权 production drawable acquisition。
- 不授权 color attachment、command buffer、encoder、draw、GPU submission 或 render。
- 不授权 renderer state write、public API、public C ABI、public diagnostics 或 build config integration。

## 设计意图出口自检

- 下一 opening 是 cleanup / headless safety preflight，不是 accessor call implementation。
- 上游为 containment policy endpoint；下游为 cleanup / headless safety value boundary candidate。
- Same-shape Boundary Brake：下一段不得继续包装 no-call facts，也不得制造 application-ready、visible-ready、drawable-ready、render-ready 或 backend-ready wrapper。
