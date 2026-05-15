# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Call Stop-Line Reconciliation 后续边界决策

## 当前阶段出口

Accessor call stop-line reconciliation 已完成 docs-only 封账。当前 canonical endpoint 保持：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyDraft()`

Runtime input 保持：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness`

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor call preflight decision`

## 下一段只允许预检的问题

- 是否允许从 accessor guard policy facts 进入 application singleton accessor call feasibility route。
- 是否必须先新增 no-call preflight guard，把 accessor-call discussion 与 accessor-call implementation 分离。
- future actual accessor call 是否必须保持 main-thread gate、bounded run loop、auto-close、teardown-before-visible、non-user-visible 与 headless fail-closed constraints。
- 如何避免把 accessor preflight facts 包成 application-ready / visible-ready / drawable-ready / render-ready / backend-ready truth。

## 不自动继承的权限

- 本阶段不授权 application singleton accessor call。
- 本阶段不授权 `NSApplication` creation / activation side effect。
- 本阶段不授权 activation policy mutation。
- 本阶段不授权 AppKit event loop。
- 本阶段不授权 native visible order implementation。
- 本阶段不授权 production drawable acquisition。
- 本阶段不授权 color attachment、command buffer、encoder、draw、GPU submission 或 render。
- 本阶段不授权 renderer state write、public API、public C ABI 或 build config integration。

## 设计意图出口自检

- 下一 opening 是 accessor call preflight decision，不是 accessor call implementation。
- 已保留 upstream / downstream 指向：上游为 accessor guard policy；downstream 为 future accessor call preflight。
- Same-shape Boundary Brake：下一段仍必须证明不是 application-ready / visible-ready / drawable-ready / render-ready wrapper。
