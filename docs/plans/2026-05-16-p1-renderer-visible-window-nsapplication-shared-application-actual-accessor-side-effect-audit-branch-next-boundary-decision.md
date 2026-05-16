# P1 Renderer 可见窗口 NSApplication Shared-Application Actual Accessor Side-Effect Audit Branch 后续边界决策

状态：next-boundary decision / docs-only / no runtime truth

## 当前阶段出口

Actual accessor side-effect audit branch closure 已完成。当前 canonical endpoint 保持：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditDraft()`

Runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSingletonAccessorAdmissionReadiness`

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor call preflight guard preflight decision`

## 下一段只允许预检的问题

- 是否允许新增 internal no-call actual accessor call preflight guard owner。
- 是否确认 actual application singleton accessor call 仍 blocked。
- 是否确认 preflight guard 只表达 future first-slice guard facts，而不是 AppKit permission。
- 是否继续保持 artifact write、artifact publication、public diagnostics、actual teardown execution、event loop、bounded pump、visible order、drawable、render 与 renderer state write blocked。

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

- 下一 opening 是 actual accessor call preflight guard preflight，不是 actual accessor call implementation。
- Same-shape Boundary Brake：下一段不得制造 application-ready、accessor-ready、visible-ready、drawable-ready、render-ready 或 backend-ready wrapper。
