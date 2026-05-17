# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle main-thread headless fail-closed evidence probe preflight decision

状态：decision / internal-only preflight / no singleton creation

## 决策

在 route C 的 CJGUI-owned mode recovery route 内继续推进。

本阶段消费 `CJGUI-owned NSApplication singleton lifecycle main-thread / headless fail-closed value boundary` readiness，但不进入 production singleton owner implementation，也不执行 cleanup / teardown。它只把 main-thread confinement evidence probe 与 headless / CI fail-closed evidence probe 的前置条件固定为 no-singleton-creation preflight facts。

## 本阶段固定的 preflight

- `evidence_probe_preflight_opened=true`
- `main_thread_confinement_evidence_probe_preflight_required=true`
- `headless_fail_closed_evidence_probe_preflight_required=true`
- `no_singleton_creation_during_probe=true`
- `application_singleton_accessor_call=false`
- `native_bridge_expansion=false`
- `probe_uses_existing_no_side_effect_evidence_only=true`
- `production_singleton_owner_implementation=false`
- `cleanup_teardown_execution=false`
- `activation_deferred=true`
- `activation_policy_mutation_deferred=true`
- `appkit_event_loop_deferred=true`
- `bounded_run_loop_pump_deferred=true`
- `visible_order_deferred=true`
- `drawable_render_deferred=true`

## Runtime owner

新增 internal-only owner：

[runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_preflight.cj)

新增 owner probe：

[verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_preflight_owner.sh)

该 owner 只消费：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryReadiness`

并输出：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightDraft()`

## Stop-line

本阶段不授权 production singleton owner implementation、新的 application singleton accessor call、cleanup / teardown execution、`setActivationPolicy`、`activateIgnoringOtherApps`、`run` / `stop` / `terminate`、visible `NSWindow`、visible order、production `nextDrawable`、render pass drawable texture、render command encoder、draw、commit、present、GPU submission、renderer state write、`runtime_state.cj` 修改、`runtime/cjgui/cjpm.toml` 修改、public API 或 public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread confinement and headless fail-closed evidence probe first slice / scan-only no-singleton owner decision`
