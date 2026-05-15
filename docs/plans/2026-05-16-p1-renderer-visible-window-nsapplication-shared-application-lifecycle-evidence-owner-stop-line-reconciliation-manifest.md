# P1 Renderer visible-window NSApplication shared-application lifecycle evidence owner stop-line reconciliation manifest

状态：docs-only / manifest / no runtime truth escalation

## 上游

- [lifecycle evidence owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-lifecycle-evidence-owner-manifest.md)
- [lifecycle evidence owner stop-line decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-lifecycle-evidence-owner-stop-line-reconciliation-decision.md)
- [lifecycle evidence owner stop-line closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-lifecycle-evidence-owner-stop-line-reconciliation-closure-review.md)
- [lifecycle evidence owner stop-line next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-lifecycle-evidence-owner-stop-line-reconciliation-next-boundary-decision.md)

## Canonical endpoint

当前 endpoint 保持：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness`

## Current truth

本 manifest 只固定 stop-line reconciliation 结论：

- lifecycle evidence owner 足够作为当前 lifecycle ownership evidence boundary。
- 不继续新增同构 lifecycle wrapper。
- run-loop execution evidence 仍是下游缺口。
- teardown ordering evidence、headless artifact policy 与 side-effect containment 仍未补齐。
- actual application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、event loop、visible order、drawable、render、renderer state write、backend-ready truth、public API 与 public C ABI 仍 blocked。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application run-loop execution evidence owner preflight decision`
