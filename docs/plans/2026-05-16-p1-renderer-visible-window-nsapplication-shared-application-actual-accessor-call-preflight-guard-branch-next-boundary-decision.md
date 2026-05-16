# P1 Renderer 可见窗口 NSApplication Shared-Application Actual Accessor Call Preflight Guard 分支下一边界决策

状态：next-boundary decision / docs-only / no runtime truth

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application isolated actual accessor call probe preflight decision`

## 下一段只允许判断的问题

- 是否允许进入 isolated actual accessor call probe preflight discussion。
- 是否确认 actual accessor call 仍不得在本阶段直接实现。
- 是否能把 main-thread confinement、isolated / probe-first、no activation、no activation policy mutation、no AppKit event loop、no bounded pump、no visible order、no drawable、no render、no artifact publication、no public API、no `runtime_state.cj` write 与 no `cjpm.toml` change 做成先验闸门。
- 是否需要人工产品 / 风险决策才能从 preflight 进入任何 actual-call first slice。

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

- 下一 opening 是 isolated actual accessor call probe preflight，不是 actual call implementation。
- 上游为 actual accessor call preflight guard endpoint；下游只允许 preflight discussion。
- Same-shape Boundary Brake：下一段不得继续包装 no-call facts，也不得制造 application-ready、accessor-ready、visible-ready、drawable-ready、render-ready 或 backend-ready wrapper。
