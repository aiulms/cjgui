# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Witness Truth Admission Preflight Manifest

状态：manifest / value-only owner / witness truth admission preflight closed

## 阶段定位

本 manifest 记录 external preexisting singleton source witness truth admission preflight。该阶段消费 witness acceptance gate preflight，把 accepted dehydrated payload、acceptance gate prerequisite、classification carry-forward、pre-truth witness truth admission 与 source readiness deferred 状态固定下来。

该阶段不是 production singleton owner implementation，不创建 source readiness truth，不调用 application singleton accessor，也不新增 native C ABI。

## 上游

- [witness acceptance gate preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-acceptance-gate-preflight-manifest.md)
- [witness payload validation preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-payload-validation-preflight-manifest.md)
- [witness payload schema preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-payload-schema-preflight-manifest.md)

## 本阶段文档

- [witness truth admission preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-truth-admission-preflight-decision.md)
- [witness truth admission preflight closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-truth-admission-preflight-closure-review.md)
- [witness truth admission preflight next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-truth-admission-preflight-next-boundary-decision.md)

## Owner / Probe

- Owner：
  [runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_truth_admission_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_truth_admission_preflight.cj)
- Owner probe：
  [verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_truth_admission_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_truth_admission_preflight_owner.sh)

## Canonical 状态

- Canonical endpoint：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthAdmissionPreflightReadiness`
- Default draft：
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthAdmissionPreflightDraft()`
- Runtime input：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAcceptanceGatePreflightReadiness`

## Truth

- `witness_truth_admission_preflight_ready=true`
- `acceptance_gate_before_witness_truth_admission_required=true`
- `accepted_payload_readiness_carry_forward_required=true`
- `accepted_payload_remain_dehydrated_required=true`
- `accepted_payload_version_carry_forward_required=true`
- `accepted_external_owner_identity_carry_forward_required=true`
- `accepted_preexisting_singleton_observation_carry_forward_required=true`
- `accepted_main_thread_observation_carry_forward_required=true`
- `accepted_source_lifetime_carry_forward_required=true`
- `accepted_cleanup_ownership_carry_forward_required=true`
- `accepted_no_renderer_accessor_invariant_carry_forward_required=true`
- `accepted_no_renderer_creation_invariant_carry_forward_required=true`
- `acceptance_classification_carry_forward_required=true`
- `witness_truth_admission_remain_pre_truth_required=true`
- `witness_truth_admission_remain_dehydrated_required=true`
- `witness_truth_admission_fail_closed_when_acceptance_missing_required=true`
- `witness_truth_admission_fail_closed_when_acceptance_blocked_required=true`
- `witness_truth_admission_fail_closed_when_payload_ambiguous_required=true`
- `witness_truth_admission_fail_closed_when_headless_required=true`
- `source_readiness_admission_deferred=true`
- `pointer_handle_class_id_witness_truth_payload_allowed=false`
- `native_object_witness_truth_payload_allowed=false`
- `diagnostics_or_artifact_witness_truth_payload_allowed=false`
- `external_preexisting_singleton_source_witness_truth=false`
- `external_preexisting_singleton_source_readiness_truth=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation_allowed=false`
- `production_actual_accessor_call_site_allowed=false`
- `public_api_modified=false`
- `production_public_c_abi_added=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`

## Stop-line

不实现 production singleton owner；不新增 runtime owner 表示 production singleton ownership truth；不新增 native C ABI；不调用 application singleton accessor；不返回 pointer / handle / `id` / `Class`；不 activation；不修改 activation policy；不运行 AppKit event loop / bounded pump；不执行 cleanup / teardown；不创建 window / view / layer；不 visible order；不 `nextDrawable`；不创建 command queue / command buffer / encoder；不 render / commit / present / GPU submission；不写 artifact；不发布 diagnostics；不新增 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source readiness admission preflight decision`
