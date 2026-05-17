# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle main-thread headless fail-closed evidence probe preflight manifest

状态：manifest / stage 69 / internal-only owner

## Canonical endpoint

本阶段新增 internal-only runtime endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightDraft()`

Runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryReadiness`

## Files

- [decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-renderer-visible-window-nsapplication-shared-application-cjgui-owned-singleton-lifecycle-main-thread-headless-fail-closed-evidence-probe-preflight-decision.md)
- [preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-renderer-visible-window-nsapplication-shared-application-cjgui-owned-singleton-lifecycle-main-thread-headless-fail-closed-evidence-probe-preflight.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-internal-renderer-visible-window-nsapplication-shared-application-cjgui-owned-singleton-lifecycle-main-thread-headless-fail-closed-evidence-probe-preflight-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-renderer-visible-window-nsapplication-shared-application-cjgui-owned-singleton-lifecycle-main-thread-headless-fail-closed-evidence-probe-preflight-next-boundary-decision.md)
- [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-internal-renderer-visible-window-nsapplication-shared-application-cjgui-owned-singleton-lifecycle-main-thread-headless-fail-closed-evidence-probe-preflight-manifest-stabilization-closure-review.md)
- [stage report 69](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-renderer-automation-stage-report-69.md)
- [owner](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_preflight.cj)
- [owner probe](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_preflight_owner.sh)

## Truth

- `evidence_probe_preflight_opened=true`
- `main_thread_confinement_evidence_probe_preflight_required=true`
- `headless_fail_closed_evidence_probe_preflight_required=true`
- `no_singleton_creation_during_probe=true`
- `application_singleton_accessor_call=false`
- `native_bridge_expansion=false`
- `probe_uses_existing_no_side_effect_evidence_only=true`
- `teardown_cleanup_responsibility_owner_required=true`
- `main_thread_creation_confinement_required=true`
- `main_thread_cleanup_confinement_required=true`
- `headless_ci_fail_closed_before_singleton_creation_required=true`
- `production_singleton_owner_implementation=false`
- `cleanup_teardown_execution=false`
- `production_singleton_ownership_truth=false`
- `activation_deferred=true`
- `activation_policy_mutation_deferred=true`
- `appkit_event_loop_deferred=true`
- `bounded_run_loop_pump_deferred=true`
- `visible_order_deferred=true`
- `drawable_render_deferred=true`
- `artifact_public_diagnostics_publication=false`
- `public_api_modified=false`
- `production_public_c_abi_added=false`
- `renderer_state_write=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`

## Stop-line

本 manifest 不授权 production singleton owner implementation、application singleton accessor call、cleanup / teardown execution、activation、activation policy mutation、event loop / bounded pump、visible `NSWindow`、visible order、drawable、render、renderer state write、public API、public C ABI、`runtime_state.cj` write 或 `runtime/cjgui/cjpm.toml` change。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread confinement and headless fail-closed evidence probe first slice / scan-only no-singleton owner decision`
