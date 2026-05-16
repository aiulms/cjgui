# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Readiness Admission Preflight Manifest

状态：manifest / value-only owner / source readiness admission preflight closed

## 阶段定位

本 manifest 记录 external preexisting singleton source readiness admission preflight。该阶段消费 witness truth admission preflight，把 witness truth admission prerequisite、accepted dehydrated payload、source readiness pre-truth admission、fail-closed source readiness classification 与 production ownership deferred 状态固定下来。

该阶段不是 external source readiness truth，不是 production singleton owner implementation，不调用 application singleton accessor，也不新增 native C ABI。

## 上游

- [witness truth admission preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-truth-admission-preflight-manifest.md)
- [witness acceptance gate preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-acceptance-gate-preflight-manifest.md)
- [witness payload validation preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-payload-validation-preflight-manifest.md)

## 本阶段文档

- [source readiness admission preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-admission-preflight-decision.md)
- [source readiness admission preflight closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-admission-preflight-closure-review.md)
- [source readiness admission preflight next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-admission-preflight-next-boundary-decision.md)

## Owner / Probe

- Owner：
  [runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_admission_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_admission_preflight.cj)
- Owner probe：
  [verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_admission_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_admission_preflight_owner.sh)

## Canonical 状态

- Canonical endpoint：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessAdmissionPreflightReadiness`
- Default draft：
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessAdmissionPreflightDraft()`
- Runtime input：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthAdmissionPreflightReadiness`

## Truth

- `source_readiness_admission_preflight_ready=true`
- `witness_truth_admission_before_source_readiness_admission_required=true`
- `witness_truth_admission_preflight_carry_forward_required=true`
- `witness_truth_admission_remain_pre_truth_carry_forward_required=true`
- `witness_truth_admission_remain_dehydrated_carry_forward_required=true`
- `accepted_payload_readiness_carry_forward_for_source_readiness_required=true`
- `accepted_payload_remain_dehydrated_for_source_readiness_required=true`
- `accepted_external_owner_identity_carry_forward_for_source_readiness_required=true`
- `accepted_preexisting_singleton_observation_carry_forward_for_source_readiness_required=true`
- `accepted_main_thread_observation_carry_forward_for_source_readiness_required=true`
- `accepted_source_lifetime_carry_forward_for_source_readiness_required=true`
- `accepted_cleanup_ownership_carry_forward_for_source_readiness_required=true`
- `accepted_no_renderer_accessor_invariant_carry_forward_for_source_readiness_required=true`
- `accepted_no_renderer_creation_invariant_carry_forward_for_source_readiness_required=true`
- `acceptance_classification_carry_forward_for_source_readiness_required=true`
- `source_readiness_admission_remain_pre_truth_required=true`
- `source_readiness_admission_remain_dehydrated_required=true`
- `source_readiness_admission_fail_closed_when_witness_truth_missing_required=true`
- `source_readiness_admission_fail_closed_when_witness_truth_blocked_required=true`
- `source_readiness_admission_fail_closed_when_payload_ambiguous_required=true`
- `source_readiness_admission_fail_closed_when_headless_required=true`
- `production_singleton_ownership_admission_deferred=true`
- `pointer_handle_class_id_source_readiness_payload_allowed=false`
- `native_object_source_readiness_payload_allowed=false`
- `diagnostics_or_artifact_source_readiness_payload_allowed=false`
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

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source readiness truth explicit approval decision`
