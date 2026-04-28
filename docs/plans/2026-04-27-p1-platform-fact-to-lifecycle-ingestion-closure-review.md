# P1 Platform Fact To Lifecycle Ingestion Closure Review

日期: 2026-04-27

类型: closure review / W2 light internal concept slice
状态: 完成

## Authority

- [2026-04-27-p1-platform-fact-to-lifecycle-ingestion-execution-card.md]
(/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-platform-fact-to-lifecycle-ingestion-execution-card.md)
- [2026-04-27-p1-runtime-internal-concept-compaction.md]
(/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-runtime-internal-concept-compaction.md)

## Syntax Sources

- [function/README.md]
(/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/function/README.md)
- [struct/README.md]
(/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/struct/README.md)
- [package/README.md]
(/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/package/README.md)
- [cangjie-regulations/SKILL.md]
(/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-regulations/SKILL.md)

`temporary_probe_used=false`；本 slice 复用已验证的同包顶层函数、struct 构造和默认 internal 规则，最终以 `cjpm build` 作为语法与包内引用验证。

## Landed Reality

- 在 [platform_adapter.cj]
(/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj) 中新增两个默认 internal projection function。
- [app_lifecycle.cj]
(/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj) 未修改。
- [window_lifecycle.cj]
(/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj) 未修改。
- [runtime README](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md) 补充 internal capability 说明。

## Added Functions

```cangjie
func cjguiInternalProjectPlatformFactToAppLifecycleState(
    fact: CjguiInternalPlatformAdapterFact,
    state: CjguiInternalAppLifecycleState
): CjguiInternalAppLifecycleState
```

行为：`fact.hasPlatformFact == true` 时返回 `CjguiInternalAppLifecycleState(state.isStateMachineActive, true)`；否则返回输入 app state。

```cangjie
func cjguiInternalProjectPlatformFactToWindowLifecycleState(
    fact: CjguiInternalPlatformAdapterFact,
    state: CjguiInternalWindowLifecycleState
): CjguiInternalWindowLifecycleState
```

行为：`fact.hasPlatformFact == true` 时返回 `CjguiInternalWindowLifecycleState(true)`；否则返回输入 window state。

## Closure Facts

- `platform_fact_to_app_lifecycle_ingestion_added=true`
- `platform_fact_to_window_lifecycle_ingestion_added=true`
- `app_projection_preserves_is_state_machine_active=true`
- `app_projection_only_sets_has_lifecycle_phase_true=true`
- `window_projection_only_sets_has_window_state_true=true`
- `false_fact_returns_input_state=true`
- `app_lifecycle_source_modified=false`
- `window_lifecycle_source_modified=false`
- `field_added=false`
- `enum_present=false`
- `result_type_present=false`
- `taxonomy_defined=false`
- `platform_object_present=false`
- `native_handle_present=false`
- `raw_pointer_present=false`
- `callback_binding_present=false`
- `event_loop_present=false`
- `runloop_truth_present=false`
- `delegate_identity_present=false`
- `event_object_present=false`
- `app_run_shutdown_present=false`
- `queue_drain_present=false`
- `window_create_close_destroy_release_present=false`
- `handle_table_present=false`
- `generation_present=false`
- `public_api_present=false`
- `public_c_abi_present=false`
- `public_present=false`
- `import_present=false`
- `cjpm_toml_changed=false`
- `smoke_changed=false`
- `diagnostics_truth_system_present=false`

## Verification

Runtime build:

- command: `cjpm build --target-dir /tmp/cjgui-platform-fact-to-lifecycle-ingestion-target --skip-script`
- exit code: 0
- key output: `cjpm build success`
- warnings: 12 unused warnings for existing internal constructors/functions plus the new internal projection functions; no errors.

Smoke guard:

- command: `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- exit code: 0
- key output: `cjgui verify: auto-close log assertions passed`

Diff hygiene:

- `git diff --check`: exit code 0.

## Forbidden File Check

- `runtime/cjgui/cjpm.toml` not modified.
- `runtime/cjgui/src/main.cj` not added.
- `runtime/cjgui/src/package_anchor.cj` not added.
- `labs/macos_bridge_smoke` not modified by this slice.
- No harness, native bridge, or Cangjie entry changes.

## Current Next Opening

`P1 platform fact to lifecycle ingestion closure / next functional slice decision`

This opening does not automatically start implementation.
