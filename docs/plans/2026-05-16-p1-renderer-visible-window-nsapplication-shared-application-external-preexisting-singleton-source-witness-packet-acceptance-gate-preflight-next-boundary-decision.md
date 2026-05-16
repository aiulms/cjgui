# P1 Renderer 可见窗口 NSApplication Shared-Application witness packet acceptance gate preflight next-boundary 决策

状态：next-boundary / packet truth admission preflight only

## Decision

本阶段的 witness packet acceptance gate preflight 已经把 consistency gate readiness 收束为 pre-truth acceptance gate。下一步不能把 acceptance gate 直接升级成 source readiness truth，也不能打开 production actual accessor call。

下一阶段只能进入 external preexisting singleton source witness packet truth admission preflight：读取 acceptance gate readiness，把 accepted dehydrated packet 作为 truth admission prerequisite，仍保持 pre-truth / no-call。

## 当前 canonical 状态

当前 canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketAcceptanceGatePreflightReadiness`

当前 default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketAcceptanceGatePreflightDraft()`

当前 runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketConsistencyGatePreflightReadiness`

## 下一阶段允许内容

下一阶段只允许：

- 读取 witness packet acceptance gate preflight readiness；
- 固定 packet truth admission prerequisite；
- 要求 acceptance gate 在 truth admission 前成立；
- 保持 consistency gate readiness carry-forward；
- 保持 packet version、external owner identity、preexisting singleton observation、main-thread observation、source lifetime、cleanup ownership、Renderer non-creation / non-accessor invariant 的 acceptance gate 要求；
- 保持 missing / blocked / invariant mismatch fail-closed；
- 保持 pointer / handle / `id` / `Class` / native object forbidden；
- 继续不恢复 source readiness truth。

## 下一阶段禁止内容

下一阶段仍禁止：

- witness truth 或 source readiness truth 升级；
- production singleton owner implementation；
- production actual accessor call site；
- native C ABI；
- `NSApplication.sharedApplication` call；
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

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness packet truth admission preflight decision`
