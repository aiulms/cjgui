# P1 Renderer 可见窗口 NSApplication Shared-Application witness packet field validation preflight manifest

状态：manifest / value-only owner / no-call branch

## 阶段定位

本 manifest 记录 external preexisting singleton source witness packet field validation preflight。本阶段接续 witness packet recovery preflight，把“外部 owner packet 的 required fields 已被 recovery owner 要求”的结果收束为字段级 validation readiness，再进入后续 consistency gate。

## 上游

- [witness packet recovery preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-packet-recovery-preflight-manifest.md)
- [source readiness truth evidence recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-truth-evidence-recovery-manifest.md)
- [source readiness admission preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-admission-preflight-manifest.md)
- [witness truth admission preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-truth-admission-preflight-manifest.md)
- [witness acceptance gate preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-acceptance-gate-preflight-manifest.md)

## 本阶段文档

- [witness packet field validation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-packet-field-validation-preflight-decision.md)
- [witness packet field validation preflight closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-packet-field-validation-preflight-closure-review.md)
- [witness packet field validation preflight next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-packet-field-validation-preflight-next-boundary-decision.md)

## Owner / Probe

Owner file：

[runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_field_validation_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_field_validation_preflight.cj)

Owner probe：

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

## Stop-line

不升级 source readiness truth；不升级 witness truth；不实现 production singleton owner；不新增 production actual accessor call site；不新增 native C ABI；不调用 `NSApplication.sharedApplication`；不创建或激活 `NSApplication`；不修改 activation policy；不运行 AppKit event loop / bounded pump；不执行 cleanup / teardown；不创建 window / view / layer；不 visible order；不 `nextDrawable`；不创建 command queue / command buffer / encoder；不 render / commit / present / GPU submission；不写 artifact；不发布 diagnostics；不返回 pointer / handle / `id` / `Class`；不新增 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness packet consistency gate preflight decision`
