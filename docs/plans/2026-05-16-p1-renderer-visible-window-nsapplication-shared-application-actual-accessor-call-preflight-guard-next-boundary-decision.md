# P1 Renderer 可见窗口 NSApplication Shared-Application Actual Accessor Call Preflight Guard 后续边界决策

状态：next-boundary decision / docs-only / no runtime truth

## 当前阶段出口

Actual accessor call preflight guard value-boundary stage 已完成。当前 canonical endpoint 转为：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft()`

Runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor call preflight guard stop-line reconciliation decision`

## 下一段只允许预检的问题

- 是否确认 actual accessor call preflight guard owner 足够作为 no-call preflight endpoint。
- 是否确认 actual application singleton accessor call 仍 blocked。
- 是否避免把 guard facts 包成 application-ready / accessor-ready / visible-ready / drawable-ready / render-ready / backend-ready wrapper。
- 是否需要继续新增同构 guard wrapper，还是应封账进入 branch closure。

## 不自动继承的权限

- 本阶段不授权 actual application singleton accessor call。
- 本阶段不授权 `NSApplication` creation / activation side effect。
- 本阶段不授权 activation policy mutation。
- 本阶段不授权 AppKit event loop 或 bounded pump。
- 本阶段不授权 actual teardown execution、artifact write、artifact publication 或 public diagnostics。
- 本阶段不授权 native visible order implementation。
- 本阶段不授权 production drawable acquisition。
- 本阶段不授权 color attachment、command buffer、encoder、draw、GPU submission 或 render。
- 本阶段不授权 renderer state write、public API、public C ABI 或 build config integration。

## 设计意图出口自检

- 下一 opening 是 actual accessor call preflight guard stop-line reconciliation，不是 accessor call implementation。
- 已保留 upstream / downstream 指向：上游为 actual accessor side-effect audit readiness；downstream 为 no-call stop-line reconciliation。
- Same-shape Boundary Brake：下一段仍必须证明不是 application-ready / accessor-ready / visible-ready / drawable-ready / render-ready wrapper。
