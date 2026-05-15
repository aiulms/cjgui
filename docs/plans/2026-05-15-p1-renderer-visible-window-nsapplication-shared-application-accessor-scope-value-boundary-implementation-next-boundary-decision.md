# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Scope Value Boundary 后续边界决策

## 当前阶段出口

Shared-application accessor scope value boundary 已完成。当前 endpoint 只证明 accessor scope 被拆成 internal value facts，且 accessor / singleton creation / activation / event loop / visible order / drawable / render 仍全部 blocked。

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor native guard preflight decision`

## 下一段只允许回答的问题

- 是否存在一个 production native no-side-effect guard，可以只声明 accessor 调用仍被禁止。
- 如何在 native guard 层继续证明 `sharedApplication` accessor 没有被调用。
- 如何保持 singleton creation、activation policy mutation、activation、event loop、visible order、drawable 与 render 继续 blocked。

## 不自动继承的权限

- 不授权 application singleton accessor call。
- 不授权 `NSApplication` creation。
- 不授权 activation policy mutation。
- 不授权 application activation。
- 不授权 AppKit event loop。
- 不授权 native visible order implementation。
- 不授权 production drawable acquisition。
- 不授权 color attachment、encoder、draw、GPU submission 或 render。
- 不授权 renderer state write、public API、public C ABI、diagnostics 或 build config integration。

## 设计意图出口自检

- 已保留 upstream / downstream 指向：上游为 shared-application guard policy；当前 endpoint 为 accessor scope value boundary；downstream 为 accessor native guard preflight。
- Same-shape Boundary Brake：下一段必须仍是 no-side-effect guard preflight，不得实现 accessor、不得新增 readiness publication / receipt / record wrapper。
