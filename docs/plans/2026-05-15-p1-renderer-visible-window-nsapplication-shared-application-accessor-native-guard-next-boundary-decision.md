# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Native Guard 后续边界决策

## 当前阶段出口

Accessor native guard preflight 已确认下一刀只允许 runtime internal owner 复用既有 no-side-effect shared-application guard C ABI。该 decision 不新增 native C ABI，也不允许调用 application singleton accessor。

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor native guard implementation`

## 下一段只允许回答的问题

- 如何让 accessor scope value boundary 之后的 runtime owner 继续观察 accessor call still blocked。
- 如何证明 `sharedApplication` accessor 没有被调用，且 singleton creation / activation / event loop 仍 blocked。
- 如何保持该 owner 只是 internal FFI guard facts，不成为 application-ready 或 backend-ready truth。

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

- 已保留 upstream / downstream 指向：上游为 accessor scope value boundary；downstream 为 accessor native guard implementation。
- Same-shape Boundary Brake：下一段必须仍是 no-side-effect native guard owner，不得新增 readiness publication / receipt / record wrapper，不得新增 native bridge surface。
