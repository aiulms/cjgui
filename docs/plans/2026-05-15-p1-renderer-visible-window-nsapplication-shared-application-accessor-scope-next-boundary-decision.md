# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Scope 后续边界决策

## 当前阶段出口

Shared-application accessor scope preflight 已完成。下一步不是 accessor implementation，而是 internal value-style scope boundary。

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor scope value boundary implementation`

## 下一段只允许回答的问题

- 如何把 `sharedApplication` accessor scope 表达为 value facts，而不执行 accessor。
- 如何保持 singleton creation、activation policy mutation、activation、event loop 与 visible order 继续 blocked。
- 如何证明下一段不是 application-ready / visible-ready / drawable-ready / render-ready / backend-ready wrapper。

## 不自动继承的权限

- 不授权 application singleton accessor call。
- 不授权 `NSApplication` creation / activation。
- 不授权 activation policy mutation。
- 不授权 AppKit event loop。
- 不授权 native visible order implementation。
- 不授权 production drawable acquisition。
- 不授权 color attachment、encoder、draw、GPU submission 或 render。
- 不授权 renderer state write、public API、public C ABI 或 build config integration。

## 设计意图出口自检

- 已保留 upstream / downstream 指向：上游为 shared-application guard policy；downstream 为 accessor scope value boundary。
- Same-shape Boundary Brake：下一段必须是 value boundary，不得新增 readiness publication / receipt / record wrapper。
