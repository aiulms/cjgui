# P1 Renderer 可见窗口 NSApplication Shared-Application external preexisting singleton source witness packet truth admission preflight 决策

状态：decision / preflight / no-call branch

## Decision

本阶段打开 `external preexisting singleton source witness packet truth admission preflight`。它只接续 witness packet acceptance gate preflight：读取 accepted dehydrated packet prerequisite，把 acceptance gate、packet readiness carry-forward 与 fail-closed classification 固定为 truth admission 前置条件。

本阶段继续 no-call audit branch，不打开 production actual accessor call，也不打开 actual-call first slice。

## Branch 选择

当前输入不是 explicit actual-call first slice approval。即使本阶段靠近 `NSApplication.sharedApplication` actual accessor call，当前唯一允许动作仍是 no-call branch decision / preflight：

- 继续 no-call audit branch；
- 只新增 value-only runtime owner 与 owner probe；
- 不实现 actual accessor call；
- 不新增 production native C ABI；
- 不把 packet truth admission 解释为 witness truth、source readiness truth 或 production singleton ownership truth。

## Canonical 状态

本阶段 canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightReadiness`

本阶段 default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightDraft()`

本阶段 runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketAcceptanceGatePreflightReadiness`

## Truth

- `witness_packet_truth_admission_preflight_opened=true`
- `witness_packet_acceptance_gate_before_truth_admission_required=true`
- `accepted_packet_readiness_carry_forward_required=true`
- `accepted_packet_remain_dehydrated_required=true`
- `accepted_packet_version_carry_forward_required=true`
- `accepted_external_owner_identity_carry_forward_required=true`
- `accepted_preexisting_singleton_observation_carry_forward_required=true`
- `accepted_main_thread_observation_carry_forward_required=true`
- `accepted_source_lifetime_carry_forward_required=true`
- `accepted_cleanup_ownership_carry_forward_required=true`
- `accepted_renderer_non_creation_invariant_carry_forward_required=true`
- `accepted_renderer_non_accessor_invariant_carry_forward_required=true`
- `acceptance_classification_carry_forward_required=true`
- `witness_packet_truth_admission_remain_pre_truth_required=true`
- `witness_packet_truth_admission_remain_dehydrated_required=true`
- `witness_packet_truth_admission_fail_closed_when_acceptance_missing_required=true`
- `witness_packet_truth_admission_fail_closed_when_acceptance_blocked_required=true`
- `witness_packet_truth_admission_fail_closed_when_invariant_mismatch_required=true`
- `witness_packet_truth_admission_fail_closed_when_headless_required=true`
- `source_readiness_truth_recovery_deferred=true`
- `pointer_handle_class_id_witness_packet_truth_payload_allowed=false`
- `native_object_witness_packet_truth_payload_allowed=false`
- `diagnostics_or_artifact_witness_packet_truth_payload_allowed=false`
- `source_readiness_truth_recovered=false`
- `external_preexisting_singleton_source_witness_truth=false`
- `external_preexisting_singleton_source_readiness_truth=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation_allowed=false`
- `production_actual_accessor_call_site_allowed=false`

## Stop-line

不升级 source readiness truth；不升级 witness truth；不实现 production singleton owner；不新增 production actual accessor call site；不新增 native C ABI；不调用 `NSApplication.sharedApplication`；不创建或激活 `NSApplication`；不修改 activation policy；不运行 AppKit event loop / bounded pump；不执行 cleanup / teardown；不创建 window / view / layer；不 visible order；不 `nextDrawable`；不创建 command queue / command buffer / encoder；不 render / commit / present / GPU submission；不写 artifact；不发布 diagnostics；不返回 pointer / handle / `id` / `Class`；不新增 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor side-effect audit branch closure / next actual accessor call decision`
