# P1 Renderer 可见窗口 NSApplication Shared-Application Actual Accessor Call Preflight Guard Stop-Line Reconciliation 清单

状态：manifest / docs-only stop-line reconciliation / no actual accessor call

## 上游

- [actual accessor call preflight guard manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-manifest.md)
- [actual accessor call preflight guard stop-line decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-stop-line-reconciliation-decision.md)
- [actual accessor call preflight guard stop-line closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-stop-line-reconciliation-closure-review.md)
- [actual accessor call preflight guard stop-line next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-stop-line-reconciliation-next-boundary-decision.md)
- [actual accessor call preflight guard stop-line manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-stop-line-reconciliation-manifest-stabilization-closure-review.md)

## Canonical endpoint

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`

## Current truth

本 manifest 固定 stop-line reconciliation 结论：

- actual accessor call preflight guard owner 已足够作为 no-call preflight endpoint。
- actual-call first slice explicit approval missing、main-thread confined preflight required、isolated / probe-first route required、no activation、no activation policy mutation、no AppKit event loop、no bounded pump、no visible order、no drawable、no render、no artifact publication、no public API、no `runtime_state.cj` write 与 no `cjpm.toml` change 仍是 internal facts。
- actual application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、actual AppKit event loop、bounded run-loop pump、actual teardown execution、artifact write、artifact publication、public diagnostics、visible order、drawable、render、renderer state write、backend-ready truth、public API 与 public C ABI 仍 blocked。

## Same-shape Boundary Brake

本 stop-line 不新增 application-ready、accessor-ready、visible-ready、drawable-ready、render-ready、backend-ready、state-write、receipt、record 或 publication wrapper。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor call preflight guard branch closure / next isolated actual accessor call probe decision`

后续 branch closure 已完成，并把当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application isolated actual accessor call probe preflight decision`
