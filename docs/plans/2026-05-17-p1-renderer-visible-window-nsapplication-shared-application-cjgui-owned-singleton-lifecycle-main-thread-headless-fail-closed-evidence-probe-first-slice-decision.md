# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle main-thread headless fail-closed evidence probe first slice decision

状态：decision / scan-only no-singleton owner

## 决策

本阶段消费 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness`，打开 scan-only evidence probe first slice。

本阶段只允许 internal-only owner 记录以下 facts：

- `evidence_probe_first_slice_opened=true`
- `scan_only_main_thread_confinement_evidence_recorded=true`
- `scan_only_headless_fail_closed_evidence_recorded=true`
- `scan_only_no_singleton_creation=true`
- `scan_only_no_application_accessor_call=true`
- `native_bridge_expansion=false`
- `runtime_probe_execution=false`
- `no_side_effect_evidence_only=true`
- `production_singleton_owner_implementation=false`
- `application_singleton_accessor_call=false`
- `cleanup_teardown_execution=false`

## Owner

[runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_first_slice.cj)

Owner probe：

[verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_first_slice_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_first_slice_owner.sh)

## Canonical endpoint

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceDraft()`

Runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness`

## Stop-line

本阶段不授权 production singleton owner implementation、application singleton accessor call、native bridge expansion、runtime native probe execution、cleanup / teardown execution、activation、activation policy mutation、event loop / bounded pump、visible `NSWindow`、visible order、drawable、render、renderer state write、public API、public C ABI、`runtime_state.cj` write 或 `runtime/cjgui/cjpm.toml` change。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread confinement and headless fail-closed evidence probe native-readiness preflight / no-accessor no-bridge-expansion decision`
