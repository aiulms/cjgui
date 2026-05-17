# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle main-thread headless fail-closed evidence probe runtime native-readiness probe execution preflight decision

状态：decision / stage 75 / internal-only owner

## Decision

进入 stage 75：新增 runtime native-readiness probe execution preflight owner 与 owner probe。该 owner 只消费 stage 74 runtime native-readiness probe value boundary readiness，并把 probe execution preflight 固定为 no-accessor / no-bridge-expansion / no-runtime-execution。

本阶段新增：

- [owner](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_execution_preflight.cj)
- [owner probe](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_execution_preflight_owner.sh)

## Canonical endpoint

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightDraft()`

Runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeValueBoundaryReadiness`

## Truth

本阶段 truth 仅限：

- `runtime_native_readiness_probe_execution_preflight_opened=true`
- `runtime_native_readiness_probe_value_boundary_input=true`
- `no_application_accessor_call_for_runtime_native_probe_execution_preflight=true`
- `no_native_bridge_expansion_for_runtime_native_probe_execution_preflight=true`
- `runtime_native_probe_execution=false`
- `no_singleton_creation=true`
- `no_side_effect_evidence_only=true`
- `production_singleton_owner_implementation=false`
- `application_singleton_accessor_call=false`
- `cleanup_teardown_execution=false`
- `production_singleton_ownership_truth=false`
- `activation_deferred=true`
- `activation_policy_mutation_deferred=true`
- `appkit_event_loop_deferred=true`
- `bounded_run_loop_pump_deferred=true`
- `visible_order_deferred=true`
- `drawable_render_deferred=true`
- `public_api_modified=false`
- `production_public_c_abi_added=false`
- `renderer_state_write=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`

## Stop-line

本 decision 不授权 application singleton accessor、production native C ABI、native bridge expansion、runtime native probe execution、production singleton owner implementation、cleanup / teardown execution、activation、activation policy mutation、AppKit event loop、bounded pump、visible `NSWindow`、visible order、`nextDrawable`、render、commit、present、GPU submission、renderer state write、`runtime_state.cj` write、`runtime/cjgui/cjpm.toml` change 或 public API。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread confinement and headless fail-closed evidence probe runtime native-readiness probe execution value boundary / no-accessor no-bridge-expansion no-runtime-execution owner decision`
