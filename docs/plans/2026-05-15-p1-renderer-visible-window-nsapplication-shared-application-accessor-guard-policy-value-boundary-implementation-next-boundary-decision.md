# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Guard Policy Value Boundary 实现后续边界决策

## 当前阶段出口

Shared-application accessor guard policy value boundary 已完成 implementation 封账。当前 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyDraft()`

Runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness`

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor call stop-line reconciliation decision`

## 下一段只允许预检的问题

- 是否允许从 accessor guard policy facts 进入 application singleton accessor call preflight。
- 如果继续前进，是否仍必须先保持 no-call、no-create、no-activation、no-event-loop、no-visible-order 与 no-backend-ready truth。
- 如何避免把 accessor call blocked native facts 误读为 application singleton accessor call permission。
- 是否需要一个 additional decision-only guard，把 accessor call readiness 与 actual call implementation 分离。

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

- 下一 opening 是 accessor call stop-line reconciliation decision，不是 accessor call implementation。
- 已保留 upstream / downstream 指向：上游为 accessor native guard 与 accessor guard policy；downstream 为 future accessor call preflight。
- Same-shape Boundary Brake：下一段仍必须证明不是 application-ready / visible-ready / drawable-ready / render-ready wrapper。
