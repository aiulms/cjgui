# P1 Renderer 可见窗口 NSApplication Shared-Application Actual Accessor Call Preflight Guard Stop-Line Reconciliation 决策

状态：docs-only decision / stop-line reconciliation / no actual accessor call

## 输入

- [actual accessor call preflight guard manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-manifest.md)
- [actual accessor call preflight guard manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-manifest-stabilization-closure-review.md)

当前 endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`

## 决策

选择 A：将 actual accessor call preflight guard owner 封账为 no-call preflight endpoint，不再追加同构 application-ready / accessor-ready wrapper。

理由：当前 owner 已充分表达 future actual-call first slice 仍缺 explicit approval、main-thread confined、isolated / probe-first、no activation、no activation policy mutation、no AppKit event loop、no bounded pump、no visible order、no drawable、no render、no artifact publication、no public API、no `runtime_state.cj` write 与 no `cjpm.toml` change facts，以及 actual application singleton accessor call still blocked。继续包装只会增加同构 readiness，并提高把 preflight guard facts 误读为 actual AppKit permission 的风险。

## 仍需保持的缺口

- actual application singleton accessor call 仍 blocked。
- `NSApplication` creation / activation 与 activation policy mutation 仍 blocked。
- actual AppKit event loop / bounded pump 仍 blocked。
- actual teardown execution、artifact write、artifact publication 与 public diagnostics 仍 blocked。
- visible order、drawable、render 与 renderer state write 仍 blocked。
- future actual accessor call 必须另有 explicit decision，且必须先有 main-thread confined isolated probe plan 与 rollback / cleanup evidence。

## 拒绝项

本 decision 不批准 actual artifact writing、artifact publication、public diagnostics、actual teardown execution、actual AppKit event loop、bounded run-loop pump、application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、visible order、drawable、render、renderer state write、backend-ready truth、public API 或 public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor call preflight guard branch closure / next isolated actual accessor call probe decision`
