# P1 Renderer 可见窗口 NSApplication Shared-Application witness packet truth admission preflight next-boundary 决策

状态：next-boundary / actual accessor decision only

## Decision

本阶段的 witness packet truth admission preflight 只把 acceptance gate readiness 固定为 pre-truth / dehydrated packet truth admission prerequisite。它不能直接升级成 source readiness truth，也不能打开 production actual accessor call。

下一阶段只能进入 actual accessor side-effect audit branch closure / next actual accessor call decision：明确继续 no-call audit branch，或只打开极窄 actual-call preflight。下一阶段仍不得直接实现 actual accessor call。

## 当前 canonical 状态

当前 canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightReadiness`

当前 default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightDraft()`

当前 runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketAcceptanceGatePreflightReadiness`

## 下一阶段允许内容

下一阶段只允许：

- 读取 packet truth admission preflight readiness；
- 做 branch closure / next actual accessor call decision；
- 明确是否继续 no-call audit branch；
- 或仅打开 actual-call preflight，且必须 main-thread confined、isolated / probe-first、no activation、no activation policy mutation、no AppKit event loop、no bounded pump、no visible order、no drawable、no render、no artifact publication、no public API、no `runtime_state.cj` write、no `cjpm.toml` change；
- 保持 source readiness truth、witness truth、production singleton ownership truth、production implementation 与 production actual accessor call site blocked，除非未来 human decision 明确授权更窄 preflight。

## 下一阶段禁止内容

下一阶段仍禁止：

- 直接实现 actual `NSApplication.sharedApplication` production call；
- witness truth 或 source readiness truth 升级；
- production singleton owner implementation；
- production actual accessor call site；
- native C ABI；
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
- public API / public C ABI；
- `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml` 修改。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor side-effect audit branch closure / next actual accessor call decision`
