# P1 Renderer 可见窗口 NSApplication Shared-Application Actual Accessor Call First Slice Explicit Human Approval 后续边界决策

状态：next-boundary / explicit approval required / blocker

## 当前阶段出口

当前阶段确认：post-witness-packet actual-call preflight 已经完成，但 actual accessor call first slice 未获明确人工批准。

Canonical endpoint 保持：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightReadiness`

Default draft 保持：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightDraft()`

## 下一主线

当前唯一 next opening 仍是：

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor call first-slice explicit human approval decision`

## 下一段只允许判断的问题

- 是否明确批准 actual-call first slice。
- 若批准，是否仍限定为 main-thread confined、isolated / probe-first、no activation、no activation policy mutation、no AppKit event loop、no bounded pump、no visible order、no drawable、no render、no artifact publication、no public API、no `runtime_state.cj` write、no `cjpm.toml` change。
- 若拒绝或继续缺少批准，是否继续保持当前 no-call preflight endpoint 作为 stop-line。

## 下一段禁止内容

下一段仍禁止自动进入：

- production actual accessor call site；
- production singleton owner implementation；
- native C ABI / public C ABI；
- `NSApplication.sharedApplication` production call；
- `NSApplication` creation / activation；
- activation policy mutation；
- AppKit event loop / bounded pump；
- cleanup / teardown execution；
- window / view / layer creation；
- visible order；
- drawable、command queue、command buffer、encoder；
- render / commit / present / GPU submission；
- artifact / diagnostics publication；
- pointer / handle / `id` / `Class` return；
- public API；
- `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml` 修改。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor call first-slice explicit human approval decision`
