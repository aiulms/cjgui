# P1 Renderer 可见窗口 NSApplication Shared-Application 隔离 Actual Accessor Call Probe 下一边界决策

状态：next-boundary decision / docs-only / human approval required

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application isolated actual accessor call probe explicit human approval decision`

## 下一段只允许判断的问题

- 是否由人工明确批准 actual application singleton accessor call first slice。
- 是否继续保持 no-call branch，不进入 actual accessor call。
- 若批准，是否接受 main-thread confined、isolated / probe-first、no activation、no activation policy mutation、no AppKit event loop、no bounded pump、no visible order、no drawable、no render、no artifact publication、no public API、no public C ABI、no `runtime_state.cj` write 与 no `cjpm.toml` change。

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

- 下一 opening 是 explicit human approval decision，不是 actual call implementation。
- 上游为 actual accessor call preflight guard branch manifest 与 isolated probe preflight decision。
- Same-shape Boundary Brake：下一段不得继续包装 no-call facts，也不得把 approval gate 误读为 application-ready、accessor-ready、visible-ready、drawable-ready、render-ready 或 backend-ready wrapper。
