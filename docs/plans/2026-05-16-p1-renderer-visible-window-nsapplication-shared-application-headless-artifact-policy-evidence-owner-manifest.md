# P1 Renderer visible-window NSApplication shared-application headless artifact policy evidence owner manifest

状态：manifest / internal runtime owner / no artifact output truth

## 上游

- [teardown ordering evidence owner stop-line reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-teardown-ordering-evidence-owner-stop-line-reconciliation-manifest.md)
- [headless artifact policy evidence owner preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-headless-artifact-policy-evidence-owner-preflight-decision.md)
- [headless artifact policy evidence owner closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-headless-artifact-policy-evidence-owner-stage-closure-review.md)
- [headless artifact policy evidence owner next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-headless-artifact-policy-evidence-owner-next-boundary-decision.md)

## Canonical endpoint

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness`

owner file：

- [runtime_renderer_visible_window_nsapplication_shared_application_headless_artifact_policy_evidence.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_headless_artifact_policy_evidence.cj)

owner probe：

- [verify_renderer_visible_window_nsapplication_shared_application_headless_artifact_policy_evidence_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_headless_artifact_policy_evidence_owner.sh)

## Current truth

本 manifest 固定 headless artifact policy evidence owner 的 truth：

- teardown ordering evidence readiness 被保留为上游 input。
- headless artifact policy evidence 仍 required。
- CI artifact policy 仍 evidence-only。
- headless artifact path containment 仍 required。
- headless artifact retention policy 仍 required。
- non-user-visible artifact mode 仍 required。
- fail-closed artifact route 仍 required。
- actual artifact write、artifact publication、public diagnostics、actual teardown execution、actual AppKit event loop、bounded run-loop pump、actual application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、visible order、drawable、render、renderer state write、backend-ready truth、public API 与 public C ABI 仍 blocked。

## Same-shape Boundary Brake

本 owner 不是 teardown ordering evidence endpoint 的同构包装。它只新增 headless artifact policy、CI artifact containment、retention、non-user-visible artifact mode 与 fail-closed artifact route evidence facts，不把任何 facts 升级为 artifact-ready、diagnostics-ready、teardown-ready、event-loop-ready、visible-ready、drawable-ready、render-ready、backend-ready、state-write、receipt、record 或 publication。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application headless artifact policy evidence owner stop-line reconciliation decision`
