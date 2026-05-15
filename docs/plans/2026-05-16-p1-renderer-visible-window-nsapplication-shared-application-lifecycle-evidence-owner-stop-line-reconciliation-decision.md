# P1 Renderer visible-window NSApplication shared-application lifecycle evidence owner stop-line reconciliation decision

状态：docs-only / stop-line reconciliation / no runtime implementation

## 输入

本决策消费 [lifecycle evidence owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-lifecycle-evidence-owner-manifest.md) 与 [lifecycle evidence owner closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-lifecycle-evidence-owner-stage-closure-review.md)。

当前 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceDraft()`

## 决策

选择 A：当前 lifecycle evidence owner endpoint 足够作为 lifecycle ownership evidence boundary，不继续新增同构 lifecycle wrapper。

该 endpoint 只确认：

- lifecycle owner evidence 已被显式建模为 required fact。
- application singleton ownership evidence 已被显式建模为 required fact。
- run-loop execution evidence、teardown ordering evidence、headless artifact policy 与 side-effect containment 仍未补齐。

## 拒绝项

本 decision 不批准 actual application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、AppKit event loop、native visible order、production drawable、color attachment、encoder、draw、`commit` / `present`、GPU submission、render、renderer state write、backend-ready truth、public API、public C ABI 或 diagnostics。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application run-loop execution evidence owner preflight decision`
