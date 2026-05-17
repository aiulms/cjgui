# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle main-thread headless fail-closed evidence probe runtime native-readiness probe execution value boundary decision

状态：decision / stage 76 / internal-only owner

## Decision

本阶段接续 stage 75 runtime native-readiness probe execution preflight，只允许打开 runtime native-readiness probe execution value boundary。

本阶段新增：

- internal-only runtime owner。
- owner probe。
- value-boundary docs / closure / manifest。

## Canonical endpoint

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionValueBoundaryDraft()`

Runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionPreflightReadiness`

## Truth

本阶段 truth 仅限：

- `runtime_native_readiness_probe_execution_value_boundary_opened=true`
- `runtime_native_readiness_probe_execution_preflight_input=true`
- `no_application_accessor_call_for_runtime_native_probe_execution_value=true`
- `no_native_bridge_expansion_for_runtime_native_probe_execution_value=true`
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

本阶段不授权 actual accessor call、native bridge expansion、runtime native probe execution、production singleton owner implementation、cleanup / teardown execution、activation、event loop、visible order、drawable、render、public API 或 production public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread confinement and headless fail-closed evidence probe runtime native-readiness probe execution first slice / no-accessor no-bridge-expansion no-runtime-execution owner decision`
