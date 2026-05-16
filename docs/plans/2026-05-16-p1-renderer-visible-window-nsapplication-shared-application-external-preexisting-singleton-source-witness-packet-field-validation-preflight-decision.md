# P1 Renderer 可见窗口 NSApplication Shared-Application external preexisting singleton source witness packet field validation preflight 决策

状态：decision / value-only owner preflight / no actual accessor call

## Decision

本阶段打开 `external preexisting singleton source witness packet field validation preflight`。它接续 witness packet recovery preflight：recovery 只定义外部 owner packet 的 dehydrated 字段与 fail-closed 分类，本阶段进一步把这些字段逐项验证为 value-only readiness。

结论：继续 no-call audit branch。本阶段新增 runtime internal owner 与 owner probe，但不实现 production singleton owner，不调用 `NSApplication.sharedApplication`，不恢复 witness truth、source readiness truth 或 production singleton ownership truth。

## Field Validation Preflight Contract

本 preflight 只表达外部 owner witness packet 在恢复 truth 前必须完成的字段级验证：

- 必须先消费 witness packet recovery preflight readiness；
- packet version、external owner identity、preexisting singleton observed before Renderer、main-thread observation、source lifetime covers runtime admission、cleanup ownership retained by external source 必须逐项验证；
- Renderer non-creation invariant 与 Renderer non-accessor invariant 必须逐项验证；
- missing packet、ambiguous owner、wrong thread、Renderer-created singleton、throwaway singleton 与 headless classification 必须保持 fail closed；
- pointer、handle、`id`、`Class`、native object、diagnostics packet 或 artifact packet 不能作为 field validation payload；
- source readiness truth recovered 仍为 false。

## Owner / Probe

新增 owner file：

[runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_field_validation_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_field_validation_preflight.cj)

新增 owner probe：

[verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_field_validation_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_field_validation_preflight_owner.sh)

## Canonical 状态

当前 canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketFieldValidationPreflightReadiness`

当前 default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketFieldValidationPreflightDraft()`

当前 runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketRecoveryPreflightReadiness`

## Truth

- `external_preexisting_singleton_source_witness_packet_field_validation_preflight_opened=true`
- `witness_packet_recovery_preflight_preserved=true`
- `witness_packet_recovery_preflight_before_field_validation_required=true`
- `packet_version_field_validated=true`
- `external_owner_identity_field_validated=true`
- `preexisting_singleton_observed_before_renderer_field_validated=true`
- `main_thread_observation_field_validated=true`
- `source_lifetime_covers_runtime_admission_field_validated=true`
- `cleanup_ownership_retained_by_external_source_field_validated=true`
- `renderer_non_creation_invariant_field_validated=true`
- `renderer_non_accessor_invariant_field_validated=true`
- `headless_fail_closed_classification_field_validated=true`
- `missing_packet_fail_closed_validation_required=true`
- `ambiguous_owner_fail_closed_validation_required=true`
- `wrong_thread_fail_closed_validation_required=true`
- `renderer_created_singleton_fail_closed_validation_required=true`
- `throwaway_singleton_fail_closed_validation_required=true`
- `pointer_handle_class_id_field_validation_allowed=false`
- `native_object_field_validation_allowed=false`
- `diagnostics_or_artifact_field_validation_allowed=false`
- `source_readiness_truth_recovered=false`
- `external_preexisting_singleton_source_witness_truth=false`
- `external_preexisting_singleton_source_readiness_truth=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation_allowed=false`
- `production_actual_accessor_call_site_allowed=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`
- `public_api_modified=false`
- `production_public_c_abi_added=false`

## Stop-Line

本阶段禁止：

- source readiness truth 升级；
- external preexisting singleton source witness truth 升级；
- production singleton owner implementation；
- production actual accessor call site；
- native C ABI；
- `NSApplication.sharedApplication` call；
- `NSApplication` creation / activation；
- activation policy mutation；
- AppKit event loop / bounded pump；
- cleanup / teardown execution；
- window / view / layer creation；
- visible order；
- `nextDrawable`；
- command queue / command buffer / encoder；
- render / commit / present / GPU submission；
- artifact write / diagnostics publication；
- pointer / handle / `id` / `Class` return；
- public API / public C ABI；
- `runtime_state.cj` / `runtime/cjgui/cjpm.toml` change。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness packet consistency gate preflight decision`
