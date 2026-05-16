# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Witness Admission Policy Preflight Manifest

状态：manifest / value-only owner / admission policy preflight closed

## 阶段定位

本 manifest 记录 external preexisting singleton source witness admission policy preflight。该阶段消费 source witness contract shape，把 admission policy 必须先校验的外部 owner 身份、preexisting observation、main-thread proof、source lifetime、cleanup ownership 与 no-creation / no-accessor invariants 固定下来。

该阶段不是 production singleton owner implementation，不创建 runtime ownership truth，不调用 application singleton accessor，也不新增 native C ABI。

## 上游

- [source witness contract shape manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-contract-shape-manifest.md)
- [external source readiness preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-preflight-manifest.md)
- [source-cleanup boundary manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-source-cleanup-boundary-manifest.md)

## 本阶段文档

- [witness admission policy preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-admission-policy-preflight-decision.md)
- [witness admission policy preflight closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-admission-policy-preflight-closure-review.md)
- [witness admission policy preflight next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-admission-policy-preflight-next-boundary-decision.md)

## Owner / Probe

- Owner：
  [runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_admission_policy_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_admission_policy_preflight.cj)
- Owner probe：
  [verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_admission_policy_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_admission_policy_preflight_owner.sh)

## Canonical 状态

- Canonical endpoint：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightReadiness`
- Default draft：
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightDraft()`
- Runtime input：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeReadiness`

## Truth

- `witness_admission_policy_preflight_ready=true`
- `admission_policy_before_witness_truth_required=true`
- `witness_fields_complete_before_admission_required=true`
- `external_owner_identity_before_admission_required=true`
- `preexisting_singleton_observation_before_admission_required=true`
- `main_thread_observation_proof_before_admission_required=true`
- `source_lifetime_proof_before_admission_required=true`
- `external_cleanup_ownership_before_admission_required=true`
- `no_renderer_accessor_call_during_admission_required=true`
- `no_renderer_creation_during_admission_required=true`
- `no_cleanup_execution_during_admission_required=true`
- `headless_fail_closed_admission_required=true`
- `non_user_visible_admission_required=true`
- `admission_result_remain_dehydrated_required=true`
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

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness payload schema preflight decision`
