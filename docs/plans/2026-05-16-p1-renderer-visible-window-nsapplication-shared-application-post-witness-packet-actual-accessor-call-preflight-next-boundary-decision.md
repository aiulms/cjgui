# P1 Renderer 可见窗口 NSApplication Shared-Application Post-Witness-Packet Actual-Call Preflight 后续边界决策

状态：next-boundary / explicit approval required / no actual accessor call

## 当前阶段出口

Post-witness-packet actual-call preflight revalidation 已完成。当前 canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightReadiness`

当前 default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightDraft()`

当前 runtime inputs：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightReadiness`
- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor call first-slice explicit human approval decision`

## 下一段只允许判断的问题

- 是否明确批准 actual-call first slice。
- 若批准，是否仍限定为 main-thread confined、isolated / probe-first、no activation、no activation policy mutation、no AppKit event loop、no bounded pump、no visible order、no drawable、no render、no artifact publication、no public API、no `runtime_state.cj` write、no `cjpm.toml` change。
- 若未批准，是否继续保持 no-call preflight endpoint 作为当前 stop-line。

## 下一段禁止内容

下一段仍禁止自动进入：

- production actual accessor call site；
- production singleton owner implementation；
- native C ABI / public C ABI；
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
