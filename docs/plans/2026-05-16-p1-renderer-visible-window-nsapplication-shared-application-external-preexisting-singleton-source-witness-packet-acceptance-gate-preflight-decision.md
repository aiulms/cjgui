# P1 Renderer 可见窗口 NSApplication Shared-Application external preexisting singleton source witness packet acceptance gate preflight 决策

状态：decision / value-only owner preflight / no actual accessor call

## Decision

本阶段打开 `external preexisting singleton source witness packet acceptance gate preflight`。它接续 witness packet consistency gate preflight：consistency gate 只证明 recovery / field validation carry-forward 已经一致，本阶段进一步把该一致性结果收束为 acceptance gate readiness。

结论：继续 no-call audit branch。本阶段新增 runtime internal owner 与 owner probe，但不实现 production singleton owner，不调用 `NSApplication.sharedApplication`，不恢复 witness truth、source readiness truth 或 production singleton ownership truth。

## Acceptance Gate Preflight Contract

本 preflight 只表达外部 owner witness packet 在恢复 truth 前必须完成的 acceptance gate：

- 必须先消费 witness packet consistency gate preflight readiness；
- consistency gate readiness 必须 carry-forward 到 acceptance gate；
- recovery 与 field validation carry-forward 必须已被 acceptance gate 接收；
- packet version、external owner identity、preexisting singleton observation、main-thread observation、source lifetime、cleanup ownership 必须保持 acceptance gate 要求；
- Renderer non-creation invariant 与 Renderer non-accessor invariant 必须保持 acceptance gate 要求；
- missing consistency、blocked consistency 与 invariant mismatch 必须 fail closed；
- pointer、handle、`id`、`Class`、native object、diagnostics packet 或 artifact packet 不能作为 acceptance gate payload；
- source readiness truth recovered 仍为 false。

## Owner / Probe

新增 owner file：

[runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_acceptance_gate_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_acceptance_gate_preflight.cj)

新增 owner probe：

[verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_acceptance_gate_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_acceptance_gate_preflight_owner.sh)

## Canonical 状态

当前 canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketAcceptanceGatePreflightReadiness`

当前 default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketAcceptanceGatePreflightDraft()`

当前 runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketConsistencyGatePreflightReadiness`

## Truth

- `external_preexisting_singleton_source_witness_packet_acceptance_gate_preflight_opened=true`
- `witness_packet_consistency_gate_preflight_preserved=true`
- `witness_packet_consistency_gate_before_acceptance_gate_required=true`
- `consistency_gate_readiness_carry_forward_required=true`
- `recovery_and_field_validation_carry_forward_accepted=true`
- `packet_version_acceptance_gate=true`
- `external_owner_identity_acceptance_gate=true`
- `preexisting_singleton_observation_acceptance_gate=true`
- `main_thread_observation_acceptance_gate=true`
- `source_lifetime_acceptance_gate=true`
- `cleanup_ownership_acceptance_gate=true`
- `renderer_non_creation_invariant_acceptance_gate=true`
- `renderer_non_accessor_invariant_acceptance_gate=true`
- `fail_closed_classification_acceptance_gate=true`
- `acceptance_gate_remain_pre_truth_required=true`
- `acceptance_gate_remain_dehydrated_required=true`
- `acceptance_gate_fail_closed_when_consistency_missing_required=true`
- `acceptance_gate_fail_closed_when_consistency_blocked_required=true`
- `acceptance_gate_fail_closed_when_invariant_mismatch_required=true`
- `pointer_handle_class_id_acceptance_gate_allowed=false`
- `native_object_acceptance_gate_allowed=false`
- `diagnostics_or_artifact_acceptance_gate_allowed=false`
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

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness packet truth admission preflight decision`
