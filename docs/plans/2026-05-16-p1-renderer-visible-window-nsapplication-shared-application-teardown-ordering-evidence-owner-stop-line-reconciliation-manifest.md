# P1 Renderer visible-window NSApplication shared-application teardown ordering evidence owner stop-line reconciliation manifest

状态：docs-only / manifest / no runtime truth escalation

## 上游

- [teardown ordering evidence owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-teardown-ordering-evidence-owner-manifest.md)
- [teardown ordering evidence owner stop-line decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-teardown-ordering-evidence-owner-stop-line-reconciliation-decision.md)
- [teardown ordering evidence owner stop-line closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-teardown-ordering-evidence-owner-stop-line-reconciliation-closure-review.md)
- [teardown ordering evidence owner stop-line next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-teardown-ordering-evidence-owner-stop-line-reconciliation-next-boundary-decision.md)

## Canonical endpoint

当前 endpoint 保持：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness`

## Current truth

本 manifest 只固定 stop-line reconciliation 结论：

- teardown ordering evidence owner 足够作为当前 teardown ordering evidence boundary。
- 不继续新增同构 teardown ordering wrapper。
- teardown-before-visible、bounded owner shutdown、stop-condition-before-teardown、auto-close cleanup 与 fail-closed teardown route evidence 已被显式保留为 required facts。
- headless artifact policy 仍是下游缺口。
- side-effect containment 仍需后续 hardening。
- actual teardown execution、actual AppKit event loop、bounded run-loop pump、application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、visible order、drawable、render、renderer state write、backend-ready truth、public diagnostics、public API 与 public C ABI 仍 blocked。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application headless artifact policy evidence owner preflight decision`
