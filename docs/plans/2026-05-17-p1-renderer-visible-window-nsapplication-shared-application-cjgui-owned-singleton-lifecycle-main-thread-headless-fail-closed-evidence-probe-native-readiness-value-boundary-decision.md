# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle main-thread headless fail-closed evidence probe native-readiness value boundary decision

状态：decision / stage 72 artifact reconciliation / internal-only owner accepted

## Decision

接纳当前工作树已有的 stage 72 候选 artifacts，不重新生成同构 owner 或同构 probe：

- [owner](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_native_readiness_value_boundary.cj)
- [owner probe](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_native_readiness_value_boundary_owner.sh)

复核结论：这两个 artifacts 与 stage 71 暴露的 next opening 一致，只消费 native-readiness preflight readiness，并把 native-readiness value boundary 固定为 no-accessor / no-bridge-expansion / no-runtime-probe / no-singleton-creation / scan-only evidence facts。

## Canonical endpoint

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessValueBoundaryDraft()`

Runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightReadiness`

## Truth

本阶段 truth 仅限：

- `native_readiness_value_boundary_opened=true`
- `no_application_accessor_call_for_native_readiness_value=true`
- `no_native_bridge_expansion_for_native_readiness_value=true`
- `runtime_probe_execution=false`
- `no_singleton_creation=true`
- `scan_only_native_readiness_evidence=true`
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

本 decision 不授权 `NSApplication.sharedApplication`、production native C ABI、native bridge expansion、runtime native probe execution、production singleton owner implementation、cleanup / teardown execution、activation、activation policy mutation、AppKit event loop、bounded pump、visible `NSWindow`、visible order、`nextDrawable`、render、commit、present、GPU submission、renderer state write、`runtime_state.cj` write、`runtime/cjgui/cjpm.toml` change 或 public API。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread confinement and headless fail-closed evidence probe runtime native-readiness probe preflight / no-accessor no-bridge-expansion no-runtime-execution owner decision`
