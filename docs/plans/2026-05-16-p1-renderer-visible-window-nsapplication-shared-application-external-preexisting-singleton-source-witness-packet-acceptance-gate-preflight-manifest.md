# P1 Renderer 可见窗口 NSApplication Shared-Application witness packet acceptance gate preflight manifest

状态：manifest / value-only owner / no-call branch

## 阶段定位

本 manifest 记录 external preexisting singleton source witness packet acceptance gate preflight。本阶段接续 witness packet consistency gate preflight，把“recovery packet 与 field validation carry-forward 已经被 consistency gate 收束”的结果承接为 acceptance gate readiness，再进入后续 packet truth admission preflight。

## 上游

- [witness packet consistency gate preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-packet-consistency-gate-preflight-manifest.md)
- [witness packet field validation preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-packet-field-validation-preflight-manifest.md)
- [witness packet recovery preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-packet-recovery-preflight-manifest.md)
- [source readiness truth evidence recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-truth-evidence-recovery-manifest.md)
- [source readiness admission preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-admission-preflight-manifest.md)

## 本阶段文档

- [witness packet acceptance gate preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-packet-acceptance-gate-preflight-decision.md)
- [witness packet acceptance gate preflight closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-packet-acceptance-gate-preflight-closure-review.md)
- [witness packet acceptance gate preflight next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-packet-acceptance-gate-preflight-next-boundary-decision.md)

## Owner / Probe

Owner file：

[runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_acceptance_gate_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_acceptance_gate_preflight.cj)

Owner probe：

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

## Stop-line

不升级 source readiness truth；不升级 witness truth；不实现 production singleton owner；不新增 production actual accessor call site；不新增 native C ABI；不调用 `NSApplication.sharedApplication`；不创建或激活 `NSApplication`；不修改 activation policy；不运行 AppKit event loop / bounded pump；不执行 cleanup / teardown；不创建 window / view / layer；不 visible order；不 `nextDrawable`；不创建 command queue / command buffer / encoder；不 render / commit / present / GPU submission；不写 artifact；不发布 diagnostics；不返回 pointer / handle / `id` / `Class`；不新增 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness packet truth admission preflight decision`
