# P1 Renderer 可见窗口 NSApplication Shared-Application Actual Accessor Call Preflight Guard Stop-Line Reconciliation 后续边界决策

状态：next-boundary decision / docs-only / no runtime truth

## 当前阶段出口

Actual accessor call preflight guard stop-line reconciliation 已完成。当前 canonical endpoint 保持：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft()`

Runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor call preflight guard branch closure / next isolated actual accessor call probe decision`

## 下一段只允许判断的问题

- actual accessor call preflight guard branch 是否可以封账。
- actual application singleton accessor call 是否仍 blocked。
- 是否允许未来只打开 isolated actual accessor call probe preflight，或继续保持 no-call branch。
- 如果未来开启 isolated probe preflight，是否必须先明确 main-thread confinement、no activation、no activation policy mutation、no AppKit event loop、no bounded pump、no visible order、no drawable、no render、no artifact publication、no public API、no `runtime_state.cj` write 与 no `cjpm.toml` change。

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

- 下一 opening 是 branch closure / next isolated actual accessor call probe decision，不是 actual call implementation。
- Same-shape Boundary Brake：下一段不得制造 application-ready、accessor-ready、visible-ready、drawable-ready、render-ready 或 backend-ready wrapper。
