# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Native Guard Implementation 后续边界决策

## 当前阶段出口

Accessor native guard owner 已完成。当前 endpoint 只证明 accessor scope 之后仍可用 no-side-effect native guard facts 观察 accessor call blocked，不表示 accessor 可调用，也不表示 application ready。

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor guard policy value boundary decision`

## 下一段只允许回答的问题

- accessor native guard facts 是否只能进入 internal policy value boundary。
- 是否需要把 accessor call blocked / scope blocked / singleton creation blocked / downstream still-blocked facts 固定成 policy facts。
- 如何避免把 accessor native guard 误读为 application singleton accessor call permission。

## 不自动继承的权限

下一段不授权 application singleton accessor call、`NSApplication` creation、activation policy mutation、application activation、AppKit event loop、native visible order implementation、production drawable acquisition、color attachment、encoder、draw、GPU submission、render、renderer state write、public API、public C ABI、diagnostics 或 build config integration。

## 设计意图出口自检

- 上游：accessor native guard endpoint。
- Downstream：accessor guard policy value boundary decision。
- Same-shape Boundary Brake：下一段若实现，只能是 policy owner；不得新增 native C ABI、foreign resource call、receipt / record / publication wrapper 或 backend-ready truth。
