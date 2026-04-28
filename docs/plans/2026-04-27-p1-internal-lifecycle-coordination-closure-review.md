# P1 internal lifecycle coordination closure review

日期: 2026-04-27

类型: closure review

Authority:

- [2026-04-27-p1-internal-lifecycle-coordination-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-internal-lifecycle-coordination-execution-card.md)
- [2026-04-27-p1-platform-fact-to-lifecycle-ingestion-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-platform-fact-to-lifecycle-ingestion-closure-review.md)
- [2026-04-27-p1-runtime-internal-concept-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-runtime-internal-concept-compaction.md)

## Landed Reality

本轮进入 bounded implementation，未创建新的 preflight 或 execution card。

新增默认 internal result type:

```cangjie
struct CjguiInternalLifecycleCoordinationResult {
    let appState: CjguiInternalAppLifecycleState
    let windowState: CjguiInternalWindowLifecycleState
}
```

该 type 只通过构造期初始化保存 projected app/window state，不是 public API、public C ABI、error `Result` type、platform object wrapper、handle、handle table 或 generation。

新增默认 internal coordination function:

```cangjie
func cjguiInternalCoordinateLifecycleFromPlatformFact(
    fact: CjguiInternalPlatformAdapterFact,
    appState: CjguiInternalAppLifecycleState,
    windowState: CjguiInternalWindowLifecycleState
): CjguiInternalLifecycleCoordinationResult
```

该 function 调用既有:

- `cjguiInternalProjectPlatformFactToAppLifecycleState`
- `cjguiInternalProjectPlatformFactToWindowLifecycleState`

并返回包含 projected app/window state 的 `CjguiInternalLifecycleCoordinationResult`。它只组合 internal marker facts: `hasPlatformFact=true` 时 app projection 可推进 `hasLifecyclePhase=true`，window projection 可推进 `hasWindowState=true`。

## Closure Facts

- `lifecycle_coordination_result_added=true`
- `lifecycle_coordination_result_name=CjguiInternalLifecycleCoordinationResult`
- `coordination_result_fields=appState:CjguiInternalAppLifecycleState,windowState:CjguiInternalWindowLifecycleState`
- `coordination_result_constructor_shape=default_internal_explicit_init`
- `lifecycle_coordination_function_added=true`
- `lifecycle_coordination_function_name=cjguiInternalCoordinateLifecycleFromPlatformFact`
- `coordination_function_inputs=CjguiInternalPlatformAdapterFact,CjguiInternalAppLifecycleState,CjguiInternalWindowLifecycleState`
- `coordination_function_output=CjguiInternalLifecycleCoordinationResult`
- `calls_app_projection=true`
- `calls_window_projection=true`
- `only_marker_facts_progressed=true`
- `platform_adapter_modified=true`
- `app_lifecycle_modified=false`
- `window_lifecycle_modified=false`
- `app_run_shutdown_present=false`
- `window_create_close_destroy_release_present=false`
- `queue_drain_present=false`
- `event_loop_present=false`
- `callback_binding_present=false`
- `handle_table_present=false`
- `generation_present=false`
- `platform_object_present=false`
- `native_handle_present=false`
- `raw_pointer_present=false`
- `appkit_metal_objective_c_reference_present=false`
- `public_api_present=false`
- `public_c_abi_present=false`
- `public_present=false`
- `import_present=false`
- `diagnostics_truth_system_present=false`
- `cjpm_toml_changed=false`
- `smoke_changed=false`
- `build_success=true`

## Verification

- `cjpm build --target-dir /tmp/cjgui-internal-lifecycle-coordination-target --skip-script` passed with exit code 0. Output ended with `cjpm build success`; unused internal symbol warnings remain expected for current skeleton.
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` passed with exit code 0.
- `git diff --check` passed with exit code 0.
- Absolute markdown link check for touched docs reported no missing target.
- Forbidden surface stayed closed: no `cjpm.toml` change, no `src/main.cj` / `package_anchor.cj`, no smoke / harness / native bridge / Cangjie entry change.

## Next Opening

`P1 internal lifecycle coordination closure / next functional slice decision`

This does not automatically open implementation.
