# P1 Renderer visible-window NSApplication shared-application source witness truth recovery value boundary decision

状态：decision / internal-only value boundary owner selected

## 结论

本轮选择 A：在当前用户预授权范围内，推进 `external preexisting singleton source witness truth recovery value boundary` 的 internal-only readiness owner。

该阶段只消费上一段 `source witness truth recovery preflight` readiness，把 recovery preflight 中的 external owner witness、accepted witness packet、preexisting singleton observation、main-thread observation、source lifetime、cleanup ownership、renderer non-creation / non-accessor invariant 与 headless fail-closed facts 汇入 value boundary。它不恢复 source witness truth，不恢复 source readiness truth，也不授权 production singleton ownership implementation 或 production actual accessor call site。

Canonical endpoint 转为：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthRecoveryValueBoundaryReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthRecoveryValueBoundaryDraft()`

## Runtime input

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthRecoveryPreflightReadiness`

## 写集

- 新增 internal owner：[runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_truth_recovery_value_boundary.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_truth_recovery_value_boundary.cj)
- 新增 owner probe：[verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_truth_recovery_value_boundary_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_truth_recovery_value_boundary_owner.sh)

## Truth

- `source_witness_truth_recovery_preflight_readiness_preserved=true`
- `source_witness_truth_recovery_value_boundary_opened=true`
- `external_preexisting_singleton_source_witness_before_truth_recovery_value_required=true`
- `accepted_external_owner_witness_packet_before_truth_recovery_value_required=true`
- `source_witness_truth_recovery_value_boundary_dehydrated=true`
- `external_preexisting_singleton_source_witness_truth=false`
- `source_readiness_truth_value=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation=false`
- `production_actual_accessor_call_site=false`
- `actual_accessor_call_isolated_native_probe_only=true`
- `runtime_state_write=false`
- `cjpm_toml_change=false`
- `public_api_modified=false`
- `production_public_c_abi_added=false`

## Stop-line

继续禁止：`setActivationPolicy`、`activateIgnoringOtherApps`、`run` / `stop` / `terminate`、production visible `NSWindow` creation、`makeKeyAndOrderFront` / `orderFront`、AppKit event loop / bounded pump、production `nextDrawable`、production drawable texture color attachment、render command encoder、draw / commit / present、GPU submission、renderer state write、`runtime_state.cj` write、`runtime/cjgui/cjpm.toml` mutation、public API、public / production C ABI、pointer / handle / `id` / `Class` return、artifact / diagnostics publication。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness truth recovery false-branch downstream / next readiness owner decision`
