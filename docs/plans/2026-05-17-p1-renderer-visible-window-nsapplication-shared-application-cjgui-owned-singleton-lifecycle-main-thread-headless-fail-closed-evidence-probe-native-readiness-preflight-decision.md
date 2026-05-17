# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle main-thread headless fail-closed evidence probe native-readiness preflight decision

状态：decision / no-accessor no-bridge-expansion native-readiness preflight

## 决策

本阶段消费 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness`，打开 evidence probe native-readiness preflight。

本阶段只允许 internal-only owner 记录以下 facts：

- `native_readiness_preflight_opened=true`
- `no_application_accessor_call_for_native_readiness=true`
- `no_native_bridge_expansion_for_native_readiness=true`
- `runtime_probe_execution=false`
- `no_singleton_creation=true`
- `scan_only_evidence_inputs=true`
- `no_side_effect_evidence_only=true`
- `production_singleton_owner_implementation=false`
- `application_singleton_accessor_call=false`
- `cleanup_teardown_execution=false`
- `production_singleton_ownership_truth=false`

## Owner

[runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_native_readiness_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_native_readiness_preflight.cj)

Owner probe：

[verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_native_readiness_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_native_readiness_preflight_owner.sh)

## Canonical endpoint

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeNativeReadinessPreflightDraft()`

Runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness`

## Stop-line

本阶段不授权 production singleton owner implementation、application singleton accessor call、native bridge expansion、runtime native probe execution、cleanup / teardown execution、activation、activation policy mutation、event loop / bounded pump、visible `NSWindow`、visible order、drawable、render、renderer state write、public API、public C ABI、`runtime_state.cj` write 或 `runtime/cjgui/cjpm.toml` change。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread confinement and headless fail-closed evidence probe native-readiness value boundary / no-accessor no-bridge-expansion owner decision`
