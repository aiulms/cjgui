# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Witness Payload Schema Preflight Manifest

状态：manifest / value-only owner / payload schema preflight closed

## 阶段定位

本 manifest 记录 external preexisting singleton source witness payload schema preflight。该阶段消费 witness admission policy preflight，把 future witness payload 必须携带的字段、fail-closed classification 与 dehydration rules 固定下来。

该阶段不是 production singleton owner implementation，不创建 runtime ownership truth，不调用 application singleton accessor，也不新增 native C ABI。

## 上游

- [witness admission policy preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-admission-policy-preflight-manifest.md)
- [source witness contract shape manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-contract-shape-manifest.md)
- [external source readiness preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-preflight-manifest.md)

## 本阶段文档

- [witness payload schema preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-payload-schema-preflight-decision.md)
- [witness payload schema preflight closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-payload-schema-preflight-closure-review.md)
- [witness payload schema preflight next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-payload-schema-preflight-next-boundary-decision.md)

## Owner / Probe

- Owner：
  [runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_payload_schema_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_payload_schema_preflight.cj)
- Owner probe：
  [verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_payload_schema_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_payload_schema_preflight_owner.sh)

## Canonical 状态

- Canonical endpoint：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightReadiness`
- Default draft：
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightDraft()`
- Runtime input：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightReadiness`

## Truth

- `witness_payload_schema_preflight_ready=true`
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
- `public_api_modified=false`
- `production_public_c_abi_added=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`

## Stop-line

不实现 production singleton owner；不新增 runtime owner 表示 production singleton ownership truth；不新增 native C ABI；不调用 application singleton accessor；不返回 pointer / handle / `id` / `Class`；不 activation；不修改 activation policy；不运行 AppKit event loop / bounded pump；不执行 cleanup / teardown；不创建 window / view / layer；不 visible order；不 `nextDrawable`；不创建 command queue / command buffer / encoder；不 render / commit / present / GPU submission；不写 artifact；不发布 diagnostics；不新增 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness payload validation preflight decision`
