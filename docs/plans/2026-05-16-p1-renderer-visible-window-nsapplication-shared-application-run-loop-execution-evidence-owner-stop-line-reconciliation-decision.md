# P1 Renderer visible-window NSApplication shared-application run-loop execution evidence owner stop-line reconciliation decision

状态：docs-only / stop-line reconciliation / no runtime implementation

## 输入

本决策消费 [run-loop execution evidence owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-run-loop-execution-evidence-owner-manifest.md) 与 [run-loop execution evidence owner closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-run-loop-execution-evidence-owner-stage-closure-review.md)。

当前 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness`

## 决策

选择 A：当前 run-loop execution evidence owner endpoint 足够作为 run-loop evidence boundary，不继续新增同构 run-loop wrapper。

该 endpoint 只确认：

- lifecycle evidence readiness 已被保留为上游 input。
- run-loop execution evidence 已被显式建模为 required fact。
- bounded run-loop owner、stop-condition、auto-close 与 main-thread affinity evidence 已被显式建模为 required facts。
- teardown ordering evidence、headless artifact policy 与 side-effect containment 仍是后续缺口。

## 拒绝项

本 decision 不批准 actual AppKit event loop、bounded run-loop pump、application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、native visible order、production drawable、color attachment、encoder、draw、`commit` / `present`、GPU submission、render、renderer state write、backend-ready truth、public diagnostics、public API 或 public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application teardown ordering evidence owner preflight decision`
