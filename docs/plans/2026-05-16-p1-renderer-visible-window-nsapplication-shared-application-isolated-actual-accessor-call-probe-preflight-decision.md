# P1 Renderer 可见窗口 NSApplication Shared-Application 隔离 Actual Accessor Call Probe 预检决策

状态：preflight decision / docs-only / no actual accessor call / human approval required

## 本轮裁定

本轮选择 C：

- C：不把用户的泛化“继续”解释为 actual application singleton accessor call 授权；只完成 isolated actual accessor call probe preflight，并把下一口转为 explicit human approval decision。

本轮不选择 A：直接实现 actual `sharedApplication` call first slice。

本轮不选择 B：继续新增同构 no-call wrapper。

## 当前上游

- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`
- 上游 branch manifest：[actual accessor call preflight guard branch manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-branch-manifest.md)

## 为什么不能自动进入 actual call

Actual application singleton accessor call 是 AppKit singleton side effect 边界。它和现有 no-call preflight guard facts 的性质不同：

- 它会跨过“无 application singleton accessor call”的 stop-line。
- 它可能触发 AppKit singleton lifecycle / global application state。
- 它虽然可以被设计为 isolated / probe-first，但仍需要明确接受风险和范围。
- 当前输入“继续”只授权继续自动化推进 preflight / closure / report，不等于授权 actual side effect。

因此，本轮只能把后续 first slice 的最低审批条件写清楚，而不能把它落为 runtime owner、native C ABI、probe 或 actual call。

## 如果未来批准 actual-call first slice

任何未来 approval 必须显式覆盖以下约束：

- main-thread confined。
- isolated / probe-first。
- no activation。
- no activation policy mutation。
- no AppKit event loop。
- no bounded pump。
- no visible order。
- no drawable。
- no render。
- no artifact publication。
- no public API。
- no public C ABI。
- no `runtime_state.cj` write。
- no `runtime/cjgui/cjpm.toml` change。
- no renderer state write。
- no backend-ready truth。
- fail closed on unsupported / headless / non-main-thread conditions。

## 本轮不授权项

不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不实现 bounded pump；不执行 actual teardown；不写 artifact；不发布 diagnostics；不做 native visible order implementation；不获取 drawable；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不新增 public API 或 public C ABI；不修改 `runtime/cjgui/cjpm.toml` 或 `runtime_state.cj`。

## GitNexus 结果

`impact CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness --repo cangjie-live-codelattice` 返回 target not found、UNKNOWN、0 impacted。该结果只说明近期新增符号未被 registry graph 覆盖，不能作为安全证明。

## 下一边界

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application isolated actual accessor call probe explicit human approval decision`

该 opening 需要人工明确批准或拒绝 actual-call first slice；自动化在批准前不得实现 actual accessor call。

## 设计意图出口自检

- 本轮是否改变主题状态：是，isolated actual accessor call probe preflight 已完成。
- 本轮是否改变 canonical endpoint：否。
- 本轮是否改变 owner / truth / stop-line：是，truth 新增 explicit human approval required；stop-line 不放宽。
- 本轮是否改变唯一 next opening：是，转为 isolated actual accessor call probe explicit human approval decision。
- 是否同步 topic manifest：是。
