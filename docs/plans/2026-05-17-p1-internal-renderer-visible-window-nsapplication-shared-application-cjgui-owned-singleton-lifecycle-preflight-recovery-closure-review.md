# P1 internal Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle preflight recovery closure review

状态：closure / internal owner added / stop-line preserved

## Closure

本阶段完成 `CJGUI-owned NSApplication singleton lifecycle preflight / recovery` macro bundle 的 implementation slice：

- 消费路线 C：hosted / owned 双模式长期保留。
- hosted mode 因 external owner source witness evidence absent 标记为 unavailable。
- owned mode 选为当前 recovery route。
- 新增 internal-only owner 与 owner probe。
- 只输出 CJGUI-owned lifecycle planning/readiness facts。
- 不新增 production singleton ownership truth。
- 不实现 production singleton owner。
- 不调用新的 application singleton accessor。

## Runtime endpoint

Canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightDraft()`

Runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthRecoveryFalseBranchDownstreamReadiness`

## Files

- [decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-renderer-visible-window-nsapplication-shared-application-cjgui-owned-singleton-lifecycle-preflight-recovery-decision.md)
- [preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-renderer-visible-window-nsapplication-shared-application-cjgui-owned-singleton-lifecycle-preflight.md)
- [owner](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_preflight.cj)
- [owner probe](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_preflight_owner.sh)

## Truth closure

- `route_c_hosted_owned_dual_mode_design=true`
- `hosted_mode_external_owner_witness_evidence_absent=true`
- `hosted_mode_current_route_available=false`
- `hosted_owner_truth=false`
- `owned_mode_current_recovery_route=true`
- `source_readiness_truth_value=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation=false`
- `production_actual_accessor_call_site=false`
- `new_application_singleton_accessor_call=false`
- `activation_deferred=true`
- `activation_policy_mutation_deferred=true`
- `appkit_event_loop_deferred=true`
- `bounded_run_loop_pump_deferred=true`
- `visible_order_deferred=true`
- `drawable_render_deferred=true`
- `renderer_state_write=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`

## Stop-line review

Stop-line 保持。未新增 production singleton owner implementation、application singleton accessor call、activation、activation policy mutation、event loop / bounded pump、visible `NSWindow`、visible order、drawable、render、renderer state write、public API、public C ABI、`runtime_state.cj` write 或 `cjpm.toml` change。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle value boundary / teardown-cleanup responsibility owner decision`
