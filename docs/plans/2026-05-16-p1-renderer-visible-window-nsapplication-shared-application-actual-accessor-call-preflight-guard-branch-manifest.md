# P1 Renderer 可见窗口 NSApplication Shared-Application Actual Accessor Call Preflight Guard 分支清单

状态：branch manifest / docs-only / no actual accessor call

## 文档链

- [actual accessor call preflight guard stop-line manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-stop-line-reconciliation-manifest.md)
- [actual accessor call preflight guard branch decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-branch-closure-next-isolated-actual-accessor-call-probe-decision.md)
- [actual accessor call preflight guard branch closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-branch-closure-review.md)
- [actual accessor call preflight guard branch next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-branch-next-boundary-decision.md)
- [actual accessor call preflight guard branch manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-branch-manifest-stabilization-closure-review.md)

## 当前 endpoint

- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`

## Branch truth

Branch truth 只包含：

- preflight guard branch sealed。
- actual accessor call still blocked。
- explicit approval for actual-call first slice still missing。
- next opening may only be isolated actual accessor call probe preflight discussion。
- no same-shape no-call guard wrapper should be added before that decision.
- main-thread confinement、isolated / probe-first、no activation、no activation policy mutation、no AppKit event loop、no bounded pump、no visible order、no drawable、no render、no artifact publication、no public API、no `runtime_state.cj` write 与 no `cjpm.toml` change remain mandatory future gates.

## Stop-line

不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不实现 bounded pump；不执行 actual teardown；不写 artifact；不发布 diagnostics；不做 native visible order implementation；不获取 drawable；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不新增 public API 或 public C ABI；不修改 `runtime/cjgui/cjpm.toml` 或 `runtime_state.cj`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application isolated actual accessor call probe preflight decision`

后续 isolated actual accessor call probe preflight 已完成，并把当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application isolated actual accessor call probe explicit human approval decision`
