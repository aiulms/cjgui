# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle value boundary decision

状态：decision / internal-only value boundary / teardown-cleanup responsibility owner

## 决策

在 route C 的 owned mode recovery route 内继续推进。

本阶段消费 `CJGUI-owned NSApplication singleton lifecycle preflight / recovery`，但不进入 production singleton owner implementation。它只把 owned mode 的 teardown / cleanup responsibility 固定成下一步 implementation 之前必须满足的 value-boundary owner facts。

## 本阶段固定的 value boundary

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

## Runtime owner

新增 internal-only owner：

[runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_value_boundary.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_value_boundary.cj)

新增 owner probe：

[verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_value_boundary_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_value_boundary_owner.sh)

该 owner 只消费：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightReadiness`

并输出：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryDraft()`

## Stop-line

本阶段不授权 production singleton owner implementation、新的 application singleton accessor call、cleanup / teardown execution、`setActivationPolicy`、`activateIgnoringOtherApps`、`run` / `stop` / `terminate`、visible `NSWindow`、visible order、production `nextDrawable`、render pass drawable texture、render command encoder、draw、commit、present、GPU submission、renderer state write、`runtime_state.cj` 修改、`runtime/cjgui/cjpm.toml` 修改、public API 或 public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread and headless fail-closed value boundary / internal readiness owner decision`
