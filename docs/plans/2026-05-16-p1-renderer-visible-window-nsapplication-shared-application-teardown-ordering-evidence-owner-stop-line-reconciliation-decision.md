# P1 Renderer visible-window NSApplication shared-application teardown ordering evidence owner stop-line reconciliation decision

状态：docs-only / stop-line reconciliation / no runtime implementation

## 输入

本决策消费 [teardown ordering evidence owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-teardown-ordering-evidence-owner-manifest.md) 与 [teardown ordering evidence owner closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-teardown-ordering-evidence-owner-stage-closure-review.md)。

当前 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness`

## 决策

选择 A：当前 teardown ordering evidence owner endpoint 足够作为 teardown ordering evidence boundary，不继续新增同构 teardown wrapper。

该 endpoint 只确认：

- run-loop evidence readiness 已被保留为上游 input。
- teardown ordering evidence 已被显式建模为 required fact。
- teardown-before-visible、bounded owner shutdown、stop-condition-before-teardown、auto-close cleanup 与 fail-closed teardown route 已被显式建模为 required facts。
- headless artifact policy 与 side-effect containment 仍是后续缺口。

## 拒绝项

本 decision 不批准 actual teardown execution、actual AppKit event loop、bounded run-loop pump、application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、native visible order、production drawable、color attachment、encoder、draw、`commit` / `present`、GPU submission、render、renderer state write、backend-ready truth、public diagnostics、public API 或 public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application headless artifact policy evidence owner preflight decision`
