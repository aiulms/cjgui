# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle value boundary manifest

状态：manifest / stage 67 / internal-only owner

## Canonical endpoint

本阶段新增 internal-only runtime endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryDraft()`

Runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightReadiness`

## Files

- [decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-renderer-visible-window-nsapplication-shared-application-cjgui-owned-singleton-lifecycle-value-boundary-decision.md)
- [value boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-renderer-visible-window-nsapplication-shared-application-cjgui-owned-singleton-lifecycle-value-boundary.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-internal-renderer-visible-window-nsapplication-shared-application-cjgui-owned-singleton-lifecycle-value-boundary-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-renderer-visible-window-nsapplication-shared-application-cjgui-owned-singleton-lifecycle-value-boundary-next-boundary-decision.md)
- [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-internal-renderer-visible-window-nsapplication-shared-application-cjgui-owned-singleton-lifecycle-value-boundary-manifest-stabilization-closure-review.md)
- [stage report 67](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-renderer-automation-stage-report-67.md)
- [owner](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_value_boundary.cj)
- [owner probe](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_value_boundary_owner.sh)

## Truth

- `cjgui_owned_singleton_lifecycle_value_boundary_opened=true`
- `teardown_cleanup_responsibility_owner_required=true`
- `cleanup_before_production_singleton_implementation_required=true`
- `main_thread_cleanup_required=true`
- `cleanup_idempotency_required=true`
- `cleanup_before_visible_order_required=true`
- `cleanup_before_drawable_render_required=true`
- `headless_ci_fail_closed_required=true`
- `cleanup_execution_deferred=true`
- `activation_deferred=true`
- `activation_policy_mutation_deferred=true`
- `appkit_event_loop_deferred=true`
- `bounded_run_loop_pump_deferred=true`
- `visible_order_deferred=true`
- `drawable_render_deferred=true`
- `artifact_public_diagnostics_publication=false`
- `hosted_owner_truth=false`
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

本 manifest 不授权 production singleton owner implementation、application singleton accessor call、cleanup / teardown execution、activation、activation policy mutation、event loop / bounded pump、visible `NSWindow`、visible order、drawable、render、renderer state write、public API、public C ABI、`runtime_state.cj` write 或 `cjpm.toml` change。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread and headless fail-closed value boundary / internal readiness owner decision`
