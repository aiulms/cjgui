# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Call Stop-Line Reconciliation 决策

## 决策结论

本阶段选择 A/C 路线：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness` 足够支撑下一轮进入 application singleton accessor call preflight discussion，但仍不足以授权实际调用 `sharedApplication`、创建 `NSApplication`、activation、activation policy mutation、AppKit event loop、native visible order、drawable、render、renderer state write 或 backend-ready truth。

本阶段是 decision-only stop-line reconciliation。它只回答“是否可以把下一刀命名为 accessor call preflight”，不回答“是否可以实现 accessor call”。结论是可以开 preflight gate，但 preflight 的第一条 stop-line 必须仍是 no-call：下一刀只能审查 main-thread、bounded run loop、auto-close、teardown-before-visible、non-user-visible、headless fail-closed 与 cleanup co-ownership 是否足够承载一个 future accessor-call feasibility route。

## 上游

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyDraft()`
- [accessor guard policy manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-nsapplication-shared-application-accessor-guard-policy-value-boundary-manifest.md)

## Reconciliation 判定

- accessor guard policy facts 仍只是 value facts，不是 application singleton accessor call permission。
- application singleton accessor call 的风险边界不同于 native guard / policy facts：它可能触发 AppKit singleton lifecycle，因此必须先做 explicit preflight gate。
- future preflight 必须把 `sharedApplication` call、`NSApplication` creation、activation、activation policy mutation、event loop、visible order 与 backend-ready truth 拆开，不能把其中任一项打包成“application ready”。
- 若未来要进入 actual call implementation，必须另有 decision 明确批准，并在 implementation 前跑 impact、source/probe/build/smoke/forbidden scans。

## 不授权项

- 不调用 `sharedApplication`。
- 不创建 `NSApplication`。
- 不 activation，不 mutation activation policy。
- 不运行 AppKit event loop。
- 不调用 `makeKeyAndOrderFront` / `orderFront`。
- 不调用 production `nextDrawable`。
- 不创建 color attachment、render command encoder、command buffer 或 draw call。
- 不 `commit` / `present`，不提交 GPU work，不执行 render。
- 不写 renderer state。
- 不新增 public API / public C ABI / public diagnostics。
- 不修改 `runtime/cjgui/cjpm.toml` 或 `runtime/cjgui/src/runtime_state.cj`。

## GitNexus 结果

GitNexus 对当前 accessor guard policy endpoint / default draft 返回 target not found / UNKNOWN / 0 impacted。该结果只说明近期新增符号未被索引覆盖，不能作为安全证明；本阶段为 docs-only reconciliation，并以 source reading、manifest reachability、forbidden scan、protected path scan 与最终 `detect-changes` 兜底。

## 下一边界

若本 decision / closure / manifest 同步与 docs-only scans 通过，当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor call preflight decision`

该 next opening 仍不是 `sharedApplication` call implementation，也不是 application creation / activation、event loop、visible order、drawable、render、renderer state write、backend-ready truth 或 public API permission。
