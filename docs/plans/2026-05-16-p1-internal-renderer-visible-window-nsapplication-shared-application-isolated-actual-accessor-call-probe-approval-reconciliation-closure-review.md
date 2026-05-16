# P1 Internal Renderer 可见窗口 NSApplication Shared-Application 隔离 Actual Accessor Call Probe Approval Reconciliation Closure Review

状态：closure review / docs-only / approval hold / no actual accessor call

## 封账结论

本轮 approval reconciliation 已完成：

- 确认用户本轮输入包含“不得直接实现 actual accessor call”约束。
- 确认该输入不是 actual-call first slice approval。
- 确认旧 opening 已由 stage 30 到 stage 32 接续完成，当前仓库唯一 opening 已是 explicit human approval decision。
- 保持 no-call approval hold branch，不新增 runtime owner、native C ABI、probe 或 package route。

## 对齐文件

- [approval reconciliation decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-approval-reconciliation-decision.md)
- [isolated actual accessor call probe preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-preflight-manifest.md)
- [actual accessor call preflight guard branch manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-branch-manifest.md)

## 当前 endpoint

- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`

## Closure facts

- `generic continue` remains not explicit actual-call approval。
- 本轮 explicit “do not directly implement actual accessor call” 进一步确认 approval missing。
- Actual accessor call first slice 仍 blocked。
- No-call preflight guard owner 仍是当前 canonical runtime endpoint。
- `runtime/cjgui/src/runtime_state.cj` 与 `runtime/cjgui/cjpm.toml` 继续受保护。
- Public declaration allowlist 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Stop-line

Stop-line 保持不放宽：不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不实现 bounded pump；不执行 actual teardown；不写 artifact；不发布 diagnostics；不做 native visible order implementation；不获取 drawable；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不新增 public API 或 public C ABI；不修改 `runtime/cjgui/cjpm.toml` 或 `runtime_state.cj`。

## Closure 判定

该 closure 只关闭 approval wording ambiguity，不关闭 actual-call blocker。后续若要进入 actual-call first slice，仍需要人工明确批准，并在批准中覆盖 main-thread confined、isolated / probe-first、no activation、no activation policy mutation、no AppKit event loop、no bounded pump、no visible order、no drawable、no render、no artifact publication、no public API、no public C ABI、no `runtime_state.cj` write 与 no `cjpm.toml` change。
