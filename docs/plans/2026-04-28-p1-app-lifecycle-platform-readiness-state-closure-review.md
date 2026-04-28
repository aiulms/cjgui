# P1 app lifecycle platform readiness state closure review

日期: 2026-04-28

类型: closure review

Authority:

- [2026-04-28-p1-app-lifecycle-platform-readiness-state-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-app-lifecycle-platform-readiness-state-execution-card.md)
- [2026-04-28-p1-platform-readiness-fact-semantics-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-platform-readiness-fact-semantics-closure-review.md)

## Landed Reality

本轮进入 bounded implementation，未创建新的 preflight 或 execution card。

`CjguiInternalAppLifecycleState` 新增一个默认 internal immutable Bool fact:

```cangjie
let hasObservedPlatformReady: Bool
```

该 fact 只表示 app lifecycle internal state 已观察到脱水 platform readiness fact，不定义 app run、shutdown、request quit、event loop、queue / drain 或真实 platform readiness protocol。

构造期初始化同步更新:

- `init()` 默认写入 `isStateMachineActive = false`、`hasLifecyclePhase = false`、`hasObservedPlatformReady = false`
- 带参 `init` 增加 `hasObservedPlatformReady: Bool`

`cjguiInternalAppLifecyclePhaseMarkerTransition` 仍只把 `hasLifecyclePhase` 推进为 `true`，并保留输入 state 的 `isStateMachineActive` 与 `hasObservedPlatformReady`。

`cjguiInternalProjectPlatformFactToAppLifecycleState` 在 `fact.isPlatformReady == true` 时返回:

- `isStateMachineActive` 保留输入值
- `hasLifecyclePhase = true`
- `hasObservedPlatformReady = true`

在 `fact.isPlatformReady == false` 时原样返回输入 app state。

## Closure Facts

- `app_lifecycle_platform_readiness_state_added=true`
- `app_lifecycle_state_field_added=hasObservedPlatformReady`
- `app_lifecycle_state_field_type=Bool`
- `app_lifecycle_state_field_immutable=true`
- `default_constructor_sets_has_observed_platform_ready_false=true`
- `parameterized_constructor_includes_has_observed_platform_ready=true`
- `phase_marker_transition_preserves_has_observed_platform_ready=true`
- `platform_readiness_projection_sets_has_observed_platform_ready_true=true`
- `platform_readiness_projection_preserves_is_state_machine_active=true`
- `platform_readiness_projection_keeps_has_lifecycle_phase_marker=true`
- `platform_not_ready_projection_changes_state=false`
- `sanity_function_shape_kept=true`
- `runtime_readme_updated=true`
- `app_lifecycle_modified=true`
- `platform_adapter_modified=true`
- `public_api_present=false`
- `public_c_abi_present=false`
- `public_present=false`
- `app_run_shutdown_request_quit_present=false`
- `event_loop_present=false`
- `callback_binding_present=false`
- `queue_drain_present=false`
- `appkit_metal_objective_c_reference_added=false`
- `platform_object_present=false`
- `native_handle_present=false`
- `raw_pointer_present=false`
- `window_create_close_destroy_release_present=false`
- `handle_table_present=false`
- `generation_present=false`
- `cjpm_toml_changed=false`
- `smoke_changed=false`
- `harness_changed=false`
- `native_bridge_changed=false`
- `cangjie_entry_changed=false`
- `build_success=true`

## Verification

- `cjpm build --target-dir /tmp/cjgui-app-lifecycle-platform-readiness-state-target --skip-script` passed with exit code 0. Output ended with `cjpm build success`; current internal skeleton unused-symbol warnings remain expected.
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` passed with exit code 0 and ended with `auto-close log assertions passed`.
- `git diff --check` passed with exit code 0.
- Forbidden surface stayed closed: no `runtime/cjgui/cjpm.toml` change, no `labs/macos_bridge_smoke` change, no harness change, no native bridge change, no Cangjie entry change.

## Next Opening

`P1 app lifecycle platform readiness state closure / next functional slice decision`

This does not automatically open implementation.
