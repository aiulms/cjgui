# P1 Renderer 可见窗口 NSApplication Shared-Application 隔离 Actual Accessor Call Probe Approval Reconciliation 决策

状态：decision / docs-only / no actual accessor call / approval not granted

## 本轮裁定

本轮选择 B：

- B：把本轮用户输入裁定为 approval reconciliation，而不是 actual-call approval；保持 no-call approval hold branch，不实现 actual accessor call，也不打开 runtime / native first slice。

本轮不选择 A：把“继续”解释为 actual application singleton accessor call 授权。

本轮不选择 C：直接进入 actual-call first slice implementation。

## 输入消歧

用户本轮要求继续推进旧式 opening：

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor side-effect audit branch closure / next actual accessor call decision`

但当前仓库已经由 [automation stage report 32](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-automation-stage-report-32.md) 推进到：

`P1 internal Renderer visible-window production harness NSApplication shared-application isolated actual accessor call probe explicit human approval decision`

同时，用户明确要求不得直接实现 actual accessor call，必须先完成 branch decision / preflight，并明确是否继续 no-call audit branch 或是否只打开 actual-call preflight。因此，本轮不能把该输入升级为 actual-call approval；它只允许关闭 approval ambiguity，并继续保持 no-call approval hold。

## 当前上游

- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`
- 上游 manifest：[isolated actual accessor call probe preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-preflight-manifest.md)
- 上游 branch manifest：[actual accessor call preflight guard branch manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-branch-manifest.md)

## 本轮允许结论

- 当前 opening 的实际仓库状态是 explicit human approval decision，而不是旧的 side-effect audit branch closure。
- 本轮输入明确禁止直接实现 actual accessor call，因此不构成 actual-call first slice approval。
- Actual-call first slice 仍必须显式批准，且批准文本需要覆盖 main-thread confined、isolated / probe-first、no activation、no activation policy mutation、no AppKit event loop、no bounded pump、no visible order、no drawable、no render、no artifact publication、no public API、no public C ABI、no `runtime_state.cj` write 与 no `cjpm.toml` change。
- 在批准前，当前 runtime endpoint、default draft、runtime input 与 owner/probe 保持不变。

## 本轮不授权项

不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不实现 bounded pump；不执行 actual teardown；不写 artifact；不发布 diagnostics；不做 native visible order implementation；不获取 drawable；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不新增 public API 或 public C ABI；不修改 `runtime/cjgui/cjpm.toml` 或 `runtime_state.cj`。

## GitNexus 预检

`impact CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness --repo cangjie-live-codelattice` 与 `impact cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft --repo cangjie-live-codelattice` 均返回 target not found、UNKNOWN、0 impacted。该结果只说明近期新增符号未被 registry graph 覆盖，不能作为安全证明。

## 下一边界

当前唯一 next opening 保持：

`P1 internal Renderer visible-window production harness NSApplication shared-application isolated actual accessor call probe explicit human approval decision`

这仍需要人工明确批准或拒绝 actual-call first slice；自动化在批准前不得实现 actual accessor call。

## 设计意图出口自检

- 本轮是否改变主题状态：是，新增 approval reconciliation，确认本轮输入不是 actual-call approval。
- 本轮是否改变 canonical endpoint：否。
- 本轮是否改变 owner / truth / stop-line：truth 新增 approval ambiguity closed；stop-line 不放宽。
- 本轮是否改变唯一 next opening：否，仍是 explicit human approval decision。
- 是否同步 topic manifest：是。
