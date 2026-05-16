# P1 Renderer 可见窗口 NSApplication Shared-Application external preexisting singleton source witness packet consistency gate preflight 决策

状态：decision / value-only owner preflight / no actual accessor call

## Decision

本阶段打开 `external preexisting singleton source witness packet consistency gate preflight`。它接续 witness packet field validation preflight：field validation 只证明 recovered witness packet 的字段级验证已经固定，本阶段进一步把 recovery preflight 与 field validation preflight 的 carry-forward 条件收束成一致性门禁。

结论：继续 no-call audit branch。本阶段新增 runtime internal owner 与 owner probe，但不实现 production singleton owner，不调用 `NSApplication.sharedApplication`，不恢复 witness truth、source readiness truth 或 production singleton ownership truth。

## Consistency Gate Preflight Contract

本 preflight 只表达外部 owner witness packet 在恢复 truth 前必须完成的一致性门禁：

- 必须先消费 witness packet field validation preflight readiness；
- recovery 与 field validation 的 carry-forward 必须一致；
- packet version、external owner identity、preexisting singleton observation、main-thread observation、source lifetime、cleanup ownership 必须保持一致；
- Renderer non-creation invariant 与 Renderer non-accessor invariant 必须保持一致；
- missing packet、ambiguous owner、wrong thread、Renderer-created singleton、throwaway singleton 与 headless classification 必须保持 fail closed；
- pointer、handle、`id`、`Class`、native object、diagnostics packet 或 artifact packet 不能作为 consistency gate payload；
- source readiness truth recovered 仍为 false。

## Owner / Probe

新增 owner file：

[runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_consistency_gate_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_consistency_gate_preflight.cj)

新增 owner probe：

[verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_consistency_gate_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_consistency_gate_preflight_owner.sh)

## Canonical 状态

当前 canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketConsistencyGatePreflightReadiness`

当前 default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketConsistencyGatePreflightDraft()`

当前 runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketFieldValidationPreflightReadiness`

## Truth

- `external_preexisting_singleton_source_witness_packet_consistency_gate_preflight_opened=true`
- `witness_packet_field_validation_preflight_preserved=true`
- `witness_packet_field_validation_preflight_before_consistency_gate_required=true`
- `recovery_and_field_validation_carry_forward_consistent=true`
- `packet_version_consistency_gate=true`
- `external_owner_identity_consistency_gate=true`
- `preexisting_singleton_observation_consistency_gate=true`
- `main_thread_observation_consistency_gate=true`
- `source_lifetime_consistency_gate=true`
- `cleanup_ownership_consistency_gate=true`
- `renderer_non_creation_invariant_consistency_gate=true`
- `renderer_non_accessor_invariant_consistency_gate=true`
- `headless_fail_closed_consistency_gate=true`
- `missing_packet_fail_closed_consistency_gate=true`
- `ambiguous_owner_fail_closed_consistency_gate=true`
- `wrong_thread_fail_closed_consistency_gate=true`
- `renderer_created_singleton_fail_closed_consistency_gate=true`
- `throwaway_singleton_fail_closed_consistency_gate=true`
- `pointer_handle_class_id_consistency_gate_allowed=false`
- `native_object_consistency_gate_allowed=false`
- `diagnostics_or_artifact_consistency_gate_allowed=false`
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

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness packet acceptance gate preflight decision`
