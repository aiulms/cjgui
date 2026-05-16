# P1 Renderer 可见窗口 NSApplication Shared-Application witness packet consistency gate preflight next-boundary 决策

状态：next-boundary / packet acceptance gate preflight only

## Decision

本阶段的 witness packet consistency gate preflight 已经把 recovery 与 field validation 的 carry-forward 条件收束为一致性门禁。下一步不能把 consistency gate 直接升级成 witness truth，也不能打开 production actual accessor call。

下一阶段只能进入 external preexisting singleton source witness packet acceptance gate preflight：读取 consistency gate readiness，把一致性门禁结果收束成 acceptance gate，仍保持 pre-truth / dehydrated。

## 当前 canonical 状态

当前 canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketConsistencyGatePreflightReadiness`

当前 default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketConsistencyGatePreflightDraft()`

当前 runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketFieldValidationPreflightReadiness`

## 下一阶段允许内容

下一阶段只允许：

- 读取 witness packet consistency gate preflight readiness；
- 固定 packet acceptance gate readiness；
- 要求 consistency gate 在 acceptance 前成立；
- 保持 recovery / field validation carry-forward consistent；
- 保持 packet version、external owner identity、preexisting singleton observation、main-thread observation、source lifetime、cleanup ownership、Renderer non-creation / non-accessor invariant 的一致性要求；
- 保持 missing / ambiguous / wrong-thread / renderer-created / throwaway / headless fail-closed；
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

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness packet acceptance gate preflight decision`
