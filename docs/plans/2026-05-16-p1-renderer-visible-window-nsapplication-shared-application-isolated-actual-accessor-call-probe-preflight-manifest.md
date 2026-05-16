# P1 Renderer 可见窗口 NSApplication Shared-Application 隔离 Actual Accessor Call Probe 预检清单

状态：preflight manifest / docs-only / human approval required

## 文档链

- [actual accessor call preflight guard branch manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-branch-manifest.md)
- [isolated actual accessor call probe preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-preflight-decision.md)
- [isolated actual accessor call probe preflight closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-preflight-closure-review.md)
- [isolated actual accessor call probe next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-next-boundary-decision.md)
- [isolated actual accessor call probe manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-preflight-manifest-stabilization-closure-review.md)

## 当前 endpoint

- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`

## Current truth

Current truth 只包含：

- isolated actual accessor call probe preflight completed。
- generic continue is not explicit actual-call approval。
- actual application singleton accessor call still blocked。
- explicit human approval required before any actual-call first slice。
- future approved slice, if any, must be main-thread confined、isolated / probe-first、no activation、no activation policy mutation、no AppKit event loop、no bounded pump、no visible order、no drawable、no render、no artifact publication、no public API、no public C ABI、no `runtime_state.cj` write、no `cjpm.toml` change、no renderer state write、no backend-ready truth。

## Stop-line

不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不实现 bounded pump；不执行 actual teardown；不写 artifact；不发布 diagnostics；不做 native visible order implementation；不获取 drawable；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不新增 public API 或 public C ABI；不修改 `runtime/cjgui/cjpm.toml` 或 `runtime_state.cj`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application isolated actual accessor call probe explicit human approval decision`
