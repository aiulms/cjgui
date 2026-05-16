# P1 Renderer 可见窗口 NSApplication Shared-Application Actual Accessor Call Preflight Guard 分支 Manifest 稳定化 Closure 复核

状态：manifest stabilization closure / docs-only branch closure / no actual accessor call

## Closure 范围

本 closure 复核 [actual accessor call preflight guard branch manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-branch-manifest.md) 是否稳定记录 branch closure。

## 通过项

- Manifest 保留当前 endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`。
- Manifest 保留 default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft()`。
- Manifest 保留 runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`。
- Manifest 明确 branch closure 不等于 actual application singleton accessor call permission。
- Manifest 下游只开放 isolated actual accessor call probe preflight decision。

## 未改变项

- 未新增 runtime owner、native C ABI、probe、public API、public diagnostics 或 renderer state write。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未触碰 [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)。

## Closure 结论

Actual accessor call preflight guard branch manifest 可以作为当前 branch closure 的导航锚点。下一步只能进入 isolated actual accessor call probe preflight decision；该 opening 仍保持 no-call stop-line。
