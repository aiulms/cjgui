# P1 Renderer 可见窗口 NSApplication Shared-Application Native Guard 实现 Closure Review

## Closure 结论

本阶段完成 internal-only no-side-effect `NSApplication` shared-application native guard implementation bundle。

新增 runtime owner [runtime_renderer_visible_window_nsapplication_shared_application_native_guard.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_native_guard.cj)，canonical endpoint 为 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationNativeGuardReadiness`，default draft 为 `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationNativeGuardDraft()`，runtime input 为 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness`。

新增 production native bridge internal guard callables：

- `cjgui_native_bridge_nsapplication_shared_application_guard_accessor_blocked`
- `cjgui_native_bridge_nsapplication_shared_application_guard_singleton_creation_blocked`
- `cjgui_native_bridge_nsapplication_shared_application_guard_main_thread_required`
- `cjgui_native_bridge_nsapplication_shared_application_guard_bounded_run_loop_required`
- `cjgui_native_bridge_nsapplication_shared_application_guard_auto_close_required`
- `cjgui_native_bridge_nsapplication_shared_application_guard_headless_fail_closed`
- `cjgui_native_bridge_nsapplication_shared_application_guard_teardown_before_visible_required`
- `cjgui_native_bridge_nsapplication_shared_application_guard_non_user_visible_required`
- `cjgui_native_bridge_nsapplication_shared_application_guard_activation_policy_blocked`
- `cjgui_native_bridge_nsapplication_shared_application_guard_activation_blocked`
- `cjgui_native_bridge_nsapplication_shared_application_guard_event_loop_blocked`
- `cjgui_native_bridge_nsapplication_shared_application_guard_visible_order_still_blocked`
- `cjgui_native_bridge_nsapplication_shared_application_guard_drawable_still_blocked`
- `cjgui_native_bridge_nsapplication_shared_application_guard_render_still_blocked`

这些 callables 只返回 deterministic `int32_t` dehydrated facts，不返回 pointer / handle / `id` / `Class`，不创建 application，不运行 AppKit event loop，不触发 visible order、drawable、encoder、draw、commit、present、GPU submission 或 render。

## 验证摘要

新增 RED probes 已先失败，原因分别是缺失 runtime owner 与缺失 native callable；implementation 后已转绿：

- [verify_native_bridge_nsapplication_shared_application_guard.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nsapplication_shared_application_guard.sh)
- [verify_renderer_visible_window_nsapplication_shared_application_native_guard_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_native_guard_owner.sh)

`cjpm build --target-dir /tmp/cjgui-shared-application-native-guard-build --skip-script` 已通过；existing native bridge skeleton / no-resource / package link / cjpm package link / cjpm boundary probes 已通过。build 仍输出既有 unused warnings，未新增 error。

## 边界保持

- 未修改 [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)。
- 未修改 [cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)。
- 未新增 public runtime declaration。
- 未调用 application singleton accessor。
- 未创建 `NSApplication`。
- 未 mutation activation policy、activation、event loop、native visible order、production `nextDrawable`、color attachment、encoder、draw、commit、present、GPU submission、render、renderer state write 或 backend-ready truth。

## GitNexus 结果

pre-edit impact / context 对 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness`、`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationFeasibilityDraft()` 与既有 `cjgui_native_bridge_nsapplication_guard_ownership_required` 返回 not found / UNKNOWN / 0 impacted。该结果只说明近期新增 symbols 未被索引覆盖，不能作为安全证明；本阶段以源码读取、TDD probe、build、native probe、forbidden scan、protected path scan 与 manifest reachability 兜底。

## Closure 判定

阶段完成，可以封账并进入 manifest stabilization。下一唯一 opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application guard policy value boundary decision`
