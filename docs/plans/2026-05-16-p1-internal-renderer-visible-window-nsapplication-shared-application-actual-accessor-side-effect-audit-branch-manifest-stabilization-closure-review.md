# P1 Renderer 可见窗口 NSApplication Shared-Application Actual Accessor Side-Effect Audit 分支 Manifest 稳定化 Closure 复核

状态：manifest stabilization closure / docs-only / no runtime truth

## Closure 范围

本 closure 复核 [actual accessor side-effect audit branch manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-side-effect-audit-branch-manifest.md) 是否稳定记录 branch closure / next actual-call preflight decision。

## 通过项

- Manifest 保留当前 endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`。
- Manifest 保留 default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditDraft()`。
- Manifest 保留 runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSingletonAccessorAdmissionReadiness`。
- Manifest 明确 branch sealed 不等于 actual application singleton accessor call permission。
- Manifest 下游只开放 actual accessor call preflight guard preflight。

## 未改变项

- 未新增 runtime owner、native C ABI、probe、public API、public diagnostics 或 renderer state write。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未触碰 [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)。

## Closure 结论

Actual accessor side-effect audit branch manifest 可以作为当前 branch closure 的导航锚点。下一步进入 actual accessor call preflight guard preflight；该 opening 仍保持 no-call stop-line。
