# P1 Renderer 可见窗口 NSApplication Shared-Application witness packet truth admission preflight manifest

状态：manifest / value-only owner / no-call branch

## 阶段定位

本 manifest 记录 external preexisting singleton source witness packet truth admission preflight。本阶段接续 witness packet acceptance gate preflight，把 accepted dehydrated packet、acceptance gate prerequisite、carry-forward facts、classification carry-forward 与 pre-truth packet truth admission 固定下来。

该阶段不是 production singleton owner implementation，不创建 source readiness truth，不调用 application singleton accessor，也不新增 native C ABI。

## 上游

- [witness packet acceptance gate preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-packet-acceptance-gate-preflight-manifest.md)
- [witness packet consistency gate preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-packet-consistency-gate-preflight-manifest.md)
- [source readiness truth evidence recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-truth-evidence-recovery-manifest.md)

## 本阶段文档

- [witness packet truth admission preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-packet-truth-admission-preflight-decision.md)
- [witness packet truth admission preflight closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-packet-truth-admission-preflight-closure-review.md)
- [witness packet truth admission preflight next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-packet-truth-admission-preflight-next-boundary-decision.md)

## Owner / Probe

Owner file：

[runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_truth_admission_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_truth_admission_preflight.cj)

Owner probe：

[verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_truth_admission_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_truth_admission_preflight_owner.sh)

## Canonical 状态

当前 canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightReadiness`

当前 default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightDraft()`

当前 runtime input：

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
- `runtime_state_write=false`
- `cjpm_toml_change=false`
- `public_api_modified=false`
- `production_public_c_abi_added=false`

## Stop-line

不升级 source readiness truth；不升级 witness truth；不实现 production singleton owner；不新增 production actual accessor call site；不新增 native C ABI；不调用 `NSApplication.sharedApplication`；不创建或激活 `NSApplication`；不修改 activation policy；不运行 AppKit event loop / bounded pump；不执行 cleanup / teardown；不创建 window / view / layer；不 visible order；不 `nextDrawable`；不创建 command queue / command buffer / encoder；不 render / commit / present / GPU submission；不写 artifact；不发布 diagnostics；不返回 pointer / handle / `id` / `Class`；不新增 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor side-effect audit branch closure / next actual accessor call decision`
