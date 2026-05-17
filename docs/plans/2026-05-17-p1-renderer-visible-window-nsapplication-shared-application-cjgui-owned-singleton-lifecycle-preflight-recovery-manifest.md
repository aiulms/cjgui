# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle preflight recovery manifest

状态：manifest / stage 66 / internal-only owner

## Canonical endpoint

本阶段新增 internal-only runtime endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightDraft()`

Runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthRecoveryFalseBranchDownstreamReadiness`

## Files

- [decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-renderer-visible-window-nsapplication-shared-application-cjgui-owned-singleton-lifecycle-preflight-recovery-decision.md)
- [preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-renderer-visible-window-nsapplication-shared-application-cjgui-owned-singleton-lifecycle-preflight.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-internal-renderer-visible-window-nsapplication-shared-application-cjgui-owned-singleton-lifecycle-preflight-recovery-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-renderer-visible-window-nsapplication-shared-application-cjgui-owned-singleton-lifecycle-preflight-recovery-next-boundary-decision.md)
- [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-internal-renderer-visible-window-nsapplication-shared-application-cjgui-owned-singleton-lifecycle-preflight-recovery-manifest-stabilization-closure-review.md)
- [stage report 66](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-renderer-automation-stage-report-66.md)
- [owner](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_preflight.cj)
- [owner probe](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_preflight_owner.sh)

## Truth

- `route_c_hosted_owned_dual_mode_design=true`
- `hosted_mode_external_owner_witness_evidence_absent=true`
- `hosted_mode_current_route_available=false`
- `hosted_owner_truth=false`
- `owned_mode_current_recovery_route=true`
- `main_thread_creation_required=true`
- `headless_ci_fail_closed_required=true`
- `teardown_cleanup_responsibility_before_implementation_required=true`
- `activation_deferred=true`
- `activation_policy_mutation_deferred=true`
- `appkit_event_loop_deferred=true`
- `bounded_run_loop_pump_deferred=true`
- `visible_order_deferred=true`
- `drawable_render_deferred=true`
- `artifact_public_diagnostics_publication=false`
- `source_readiness_truth_value=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation=false`
- `production_actual_accessor_call_site=false`
- `new_application_singleton_accessor_call=false`
- `public_api_modified=false`
- `production_public_c_abi_added=false`
- `renderer_state_write=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`

## Stop-line

本 manifest 不授权 production singleton owner implementation、application singleton accessor call、activation、activation policy mutation、event loop / bounded pump、visible `NSWindow`、visible order、drawable、render、renderer state write、public API、public C ABI、`runtime_state.cj` write 或 `cjpm.toml` change。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle value boundary / teardown-cleanup responsibility owner decision`
