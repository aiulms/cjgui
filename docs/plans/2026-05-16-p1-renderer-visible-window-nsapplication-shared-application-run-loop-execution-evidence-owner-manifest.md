# P1 Renderer visible-window NSApplication shared-application run-loop execution evidence owner manifest

状态：manifest / internal runtime owner / no event-loop truth

## 上游

- [lifecycle evidence owner stop-line reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-lifecycle-evidence-owner-stop-line-reconciliation-manifest.md)
- [run-loop execution evidence owner preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-run-loop-execution-evidence-owner-preflight-decision.md)
- [run-loop execution evidence owner closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-run-loop-execution-evidence-owner-stage-closure-review.md)
- [run-loop execution evidence owner next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-run-loop-execution-evidence-owner-next-boundary-decision.md)

## Canonical endpoint

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness`

owner file：

- [runtime_renderer_visible_window_nsapplication_shared_application_run_loop_evidence.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_run_loop_evidence.cj)

owner probe：

- [verify_renderer_visible_window_nsapplication_shared_application_run_loop_evidence_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_run_loop_evidence_owner.sh)

## Current truth

本 manifest 固定 run-loop execution evidence owner 的 truth：

- lifecycle evidence readiness 被保留为上游 input。
- run-loop execution evidence 仍 required。
- bounded run-loop owner evidence 仍 required。
- stop-condition evidence 仍 required。
- auto-close evidence before visible mode 仍 required。
- main-thread run-loop affinity evidence 仍 required。
- actual AppKit event loop 与 bounded run-loop pump 仍 blocked。
- actual application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、visible order、drawable、render、renderer state write、backend-ready truth、public API 与 public C ABI 仍 blocked。

## Same-shape Boundary Brake

本 owner 不是 lifecycle evidence endpoint 的同构包装。它只新增 run-loop execution 与 bounded/stop-condition/auto-close/main-thread affinity evidence facts，不把任何 facts 升级为 event-loop-ready、visible-ready、drawable-ready、render-ready、backend-ready、state-write、receipt、record 或 publication。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application run-loop execution evidence owner stop-line reconciliation decision`
