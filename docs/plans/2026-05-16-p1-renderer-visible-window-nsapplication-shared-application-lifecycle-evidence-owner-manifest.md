# P1 Renderer visible-window NSApplication shared-application lifecycle evidence owner manifest

状态：manifest / internal runtime owner / no runtime truth escalation

## 上游

- [lifecycle / run-loop / teardown evidence gap classification manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-lifecycle-run-loop-teardown-evidence-gap-classification-manifest.md)
- [lifecycle evidence owner preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-lifecycle-evidence-owner-preflight-decision.md)
- [lifecycle evidence owner closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-lifecycle-evidence-owner-stage-closure-review.md)
- [lifecycle evidence owner next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-lifecycle-evidence-owner-next-boundary-decision.md)

## Canonical endpoint

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness`

owner file：

- [runtime_renderer_visible_window_nsapplication_shared_application_lifecycle_evidence.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_lifecycle_evidence.cj)

owner probe：

- [verify_renderer_visible_window_nsapplication_shared_application_lifecycle_evidence_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_lifecycle_evidence_owner.sh)

## Current truth

本 manifest 固定 lifecycle evidence owner 的 truth：

- cleanup / headless safety readiness 被保留为上游 input。
- lifecycle owner evidence 仍 required。
- application singleton ownership evidence 仍 required。
- run-loop execution evidence 仍 required。
- teardown ordering evidence 仍 required。
- headless artifact policy 仍是 evidence-only。
- side-effect containment evidence 仍 required before actual accessor call。
- actual application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、event loop、native visible order、drawable、render、renderer state write、backend-ready truth、public API 与 public C ABI 仍 blocked。

## Same-shape Boundary Brake

本 owner 不是 cleanup / headless safety endpoint 的同构包装。它只新增 lifecycle ownership 与证据缺口 facts，不把任何 facts 升级为 application-ready、visible-ready、drawable-ready、render-ready、backend-ready、state-write、receipt、record 或 publication。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application lifecycle evidence owner stop-line reconciliation decision`
