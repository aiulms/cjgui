# P1 Renderer 可见窗口 NSApplication Shared-Application 隔离 Actual Accessor Call Probe 预检 Manifest 稳定化 Closure 复核

状态：manifest stabilization closure / docs-only preflight / human approval required

## Closure 范围

本 closure 复核 [isolated actual accessor call probe preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-preflight-manifest.md) 是否稳定记录 explicit human approval gate。

## 通过项

- Manifest 保留当前 endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`。
- Manifest 保留 default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft()`。
- Manifest 保留 runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`。
- Manifest 明确 generic continue 不是 actual application singleton accessor call approval。
- Manifest 下游只开放 explicit human approval decision。

## 未改变项

- 未新增 runtime owner、native C ABI、probe、public API、public diagnostics 或 renderer state write。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未触碰 [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)。

## Closure 结论

Isolated actual accessor call probe preflight manifest 可以作为当前 approval gate 的导航锚点。下一步需要人工明确批准或拒绝 actual-call first slice；自动化在批准前不得实现 actual accessor call。
