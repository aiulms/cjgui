# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Call Preflight 后续边界决策

## 当前阶段出口

Accessor call preflight value-boundary stage 已完成。当前 canonical endpoint 转为：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightDraft()`

Runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness`

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor call native side-effect containment preflight decision`

## 下一段只允许预检的问题

- 是否需要新增 native side-effect containment guard，以便把 future accessor-call discussion 与 actual accessor-call implementation 继续隔离。
- native side-effect containment guard 是否只能返回 dehydrated integer facts，不调用 application singleton accessor。
- 如何继续证明 no application creation、no activation、no activation policy mutation、no event loop、no visible order、no drawable、no render、no state write 与 no backend-ready truth。
- 如何避免把 preflight facts 包成 application-ready / visible-ready / drawable-ready / render-ready / backend-ready wrapper。

## 不自动继承的权限

- 本阶段不授权 actual application singleton accessor call。
- 本阶段不授权 `NSApplication` creation / activation side effect。
- 本阶段不授权 activation policy mutation。
- 本阶段不授权 AppKit event loop。
- 本阶段不授权 native visible order implementation。
- 本阶段不授权 production drawable acquisition。
- 本阶段不授权 color attachment、command buffer、encoder、draw、GPU submission 或 render。
- 本阶段不授权 renderer state write、public API、public C ABI 或 build config integration。

## 设计意图出口自检

- 下一 opening 是 native side-effect containment preflight decision，不是 accessor call implementation。
- 已保留 upstream / downstream 指向：上游为 accessor call preflight readiness；downstream 为 future native containment preflight。
- Same-shape Boundary Brake：下一段仍必须证明不是 application-ready / visible-ready / drawable-ready / render-ready wrapper。
