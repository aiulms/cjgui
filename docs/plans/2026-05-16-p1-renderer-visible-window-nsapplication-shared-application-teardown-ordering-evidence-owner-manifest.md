# P1 Renderer visible-window NSApplication shared-application teardown ordering evidence owner manifest

状态：manifest / internal runtime owner / no teardown execution truth

## 上游

- [run-loop execution evidence owner stop-line reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-run-loop-execution-evidence-owner-stop-line-reconciliation-manifest.md)
- [teardown ordering evidence owner preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-teardown-ordering-evidence-owner-preflight-decision.md)
- [teardown ordering evidence owner closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-teardown-ordering-evidence-owner-stage-closure-review.md)
- [teardown ordering evidence owner next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-teardown-ordering-evidence-owner-next-boundary-decision.md)

## Canonical endpoint

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness`

owner file：

- [runtime_renderer_visible_window_nsapplication_shared_application_teardown_ordering_evidence.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_teardown_ordering_evidence.cj)

owner probe：

- [verify_renderer_visible_window_nsapplication_shared_application_teardown_ordering_evidence_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_teardown_ordering_evidence_owner.sh)

## Current truth

本 manifest 固定 teardown ordering evidence owner 的 truth：

- run-loop evidence readiness 被保留为上游 input。
- teardown ordering evidence 仍 required。
- teardown-before-visible evidence 仍 required。
- bounded owner shutdown evidence 仍 required。
- stop-condition-before-teardown evidence 仍 required。
- auto-close cleanup evidence 仍 required。
- fail-closed teardown route 仍 required。
- actual teardown execution、actual AppKit event loop、bounded run-loop pump、actual application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、visible order、drawable、render、renderer state write、backend-ready truth、public diagnostics、public API 与 public C ABI 仍 blocked。

## Same-shape Boundary Brake

本 owner 不是 run-loop evidence endpoint 的同构包装。它只新增 teardown ordering 与 teardown-before-visible / bounded shutdown / stop-condition-before-teardown / auto-close cleanup / fail-closed route evidence facts，不把任何 facts 升级为 teardown-ready、event-loop-ready、visible-ready、drawable-ready、render-ready、backend-ready、state-write、receipt、record 或 publication。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application teardown ordering evidence owner stop-line reconciliation decision`
