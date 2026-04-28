# P1 platform readiness fact semantics closure review

日期: 2026-04-28

类型: closure review

Authority:

- [2026-04-28-p1-platform-readiness-fact-semantics-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-platform-readiness-fact-semantics-execution-card.md)
- [2026-04-28-p1-internal-lifecycle-coordination-sanity-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-lifecycle-coordination-sanity-closure-review.md)

## Landed Reality

本轮进入 bounded implementation，未创建新的 preflight 或 execution card。

`CjguiInternalPlatformAdapterFact` 的核心 Bool fact 已从泛化 marker 语义窄口替换为 readiness 语义:

```cangjie
struct CjguiInternalPlatformAdapterFact {
    let isPlatformReady: Bool
}
```

构造期初始化同步更新:

- `init()` 默认写入 `isPlatformReady = false`
- `init(isPlatformReady: Bool)` 写入调用方传入的 readiness fact

本轮没有保留 `hasPlatformFact` 兼容字段。原因是该 symbol 仍属于默认 internal runtime skeleton，尚未形成 public runtime API 或 public C ABI；窄口替换可以避免 `hasPlatformFact` 与 `isPlatformReady` 并存造成双字段语义膨胀。

以下 internal functions 已更新为 readiness 语义:

- `cjguiInternalNoOpPlatformAdapterFactIngestion`
- `cjguiInternalProjectPlatformFactToAppLifecycleState`
- `cjguiInternalProjectPlatformFactToWindowLifecycleState`
- `cjguiInternalCoordinateLifecycleFromPlatformFact`
- `cjguiInternalLifecycleCoordinationSanity`

`cjguiInternalLifecycleCoordinationSanity()` 仍构造 `CjguiInternalPlatformAdapterFact(true)`，但该 `true` 现在表示 `isPlatformReady = true` 的脱水 readiness fact。

## Closure Facts

- `platform_readiness_fact_semantics_added=true`
- `platform_fact_field_replaced=true`
- `old_platform_fact_field=hasPlatformFact`
- `new_platform_fact_field=isPlatformReady`
- `compatibility_field_retained=false`
- `constructor_default_sets_is_platform_ready_false=true`
- `constructor_parameter_name=isPlatformReady`
- `no_op_ingestion_kept=true`
- `projection_functions_consume_readiness=true`
- `coordination_function_shape_kept=true`
- `sanity_function_constructs_ready_fact=true`
- `source_has_platform_fact_residual=false`
- `runtime_readme_updated=true`
- `platform_adapter_modified=true`
- `public_api_present=false`
- `public_c_abi_present=false`
- `public_present=false`
- `appkit_metal_objective_c_reference_added=false`
- `platform_object_present=false`
- `native_handle_present=false`
- `raw_pointer_present=false`
- `event_loop_present=false`
- `callback_binding_present=false`
- `queue_drain_present=false`
- `app_run_shutdown_present=false`
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

- `cjpm build --target-dir /tmp/cjgui-platform-readiness-fact-semantics-target --skip-script` passed with exit code 0. Output ended with `cjpm build success`; current internal skeleton unused-symbol warnings remain expected.
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` passed with exit code 0 and ended with `auto-close log assertions passed`.
- `git diff --check` passed with exit code 0.
- Source residual check for `runtime/cjgui/src/platform_adapter.cj` reported no `hasPlatformFact` occurrences.
- Forbidden surface stayed closed: no `runtime/cjgui/cjpm.toml` change, no `labs/macos_bridge_smoke` change, no harness change, no native bridge change, no Cangjie entry change.

## Next Opening

`P1 platform readiness fact semantics closure / next functional slice decision`

This does not automatically open implementation.
