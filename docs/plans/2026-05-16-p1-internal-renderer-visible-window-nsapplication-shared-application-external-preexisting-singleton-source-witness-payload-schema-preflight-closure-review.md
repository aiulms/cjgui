# P1 Internal Renderer NSApplication Shared-Application External Preexisting Singleton Source Witness Payload Schema Preflight Closure Review

状态：closure / owner sealed / no production accessor

## Closure

external preexisting singleton source witness payload schema preflight 已完成 value-only owner 封账。

本阶段没有实现 production singleton owner，没有新增 production actual accessor call site，没有调用 application singleton accessor，也没有新增 native C ABI。payload schema 只描述 future witness payload 的字段和 fail-closed 分类，且 payload 仍保持 dehydrated。

## Closed Facts

- `schema_before_witness_truth_required=true`
- `payload_version_field_required=true`
- `external_owner_identity_field_required=true`
- `preexisting_singleton_observed_field_required=true`
- `main_thread_observation_field_required=true`
- `source_lifetime_field_required=true`
- `cleanup_ownership_field_required=true`
- `no_renderer_accessor_invariant_field_required=true`
- `no_renderer_creation_invariant_field_required=true`
- `headless_fail_closed_classification_field_required=true`
- `payload_remain_dehydrated_required=true`
- `pointer_handle_class_id_payload_allowed=false`
- `native_object_payload_allowed=false`
- `diagnostics_or_artifact_payload_allowed=false`
- `missing_field_fail_closed_required=true`
- `ambiguous_owner_fail_closed_required=true`
- `wrong_thread_fail_closed_required=true`
- `renderer_created_singleton_fail_closed_required=true`
- `throwaway_singleton_fail_closed_required=true`
- `external_preexisting_singleton_source_witness_truth=false`
- `external_preexisting_singleton_source_readiness_truth=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation_allowed=false`
- `production_actual_accessor_call_site_allowed=false`

## Verification Scope

Closure evidence is owned by:

- [runtime owner](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_payload_schema_preflight.cj)
- [owner probe](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_payload_schema_preflight_owner.sh)

The probe protects against production native bridge diff additions, public runtime surface, forbidden visible/render tokens, `runtime_state.cj` writes, and `cjpm.toml` changes.

## Stop-Line

Stop-line remains unchanged: no production singleton owner implementation, no production actual accessor call site, no native C ABI, no `NSApplication` creation / activation, no activation policy mutation, no AppKit event loop / bounded pump, no cleanup / teardown execution, no visible order, no drawable, no render / commit / present / GPU submission, no artifact / diagnostics publication, no public API / production C ABI, no renderer state write, no backend-ready truth, no `runtime_state.cj` write, and no `cjpm.toml` change.
