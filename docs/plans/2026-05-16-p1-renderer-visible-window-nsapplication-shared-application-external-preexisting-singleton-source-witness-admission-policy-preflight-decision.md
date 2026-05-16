# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Witness Admission Policy Preflight Decision

状态：decision / preflight / no-call audit branch

## 决策

继续 no-call audit branch。当前阶段只打开 external preexisting singleton source witness admission policy preflight，不实现 production actual accessor call，也不把 stage 41 的 witness contract shape 升级成 production singleton ownership truth。

本轮允许新增 internal-only value owner，用来表达 admission policy 必须先校验：

- external owner identity；
- preexisting singleton observation；
- main-thread observation proof；
- source lifetime proof；
- external cleanup ownership；
- witness fields complete；
- admission result remains dehydrated；
- no Renderer creation / no Renderer accessor call / no cleanup execution during admission。

## 上游

- [source witness contract shape manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-contract-shape-manifest.md)
- [external source readiness preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-preflight-manifest.md)

## Runtime 落点

- canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightDraft()`
- runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeReadiness`
- owner file：[runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_admission_policy_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_admission_policy_preflight.cj)
- owner probe：[verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_admission_policy_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_admission_policy_preflight_owner.sh)

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

## Stop-line

不实现 production singleton owner；不调用 application singleton accessor；不新增 native C ABI；不创建或激活 `NSApplication`；不修改 activation policy；不运行 AppKit event loop / bounded pump；不执行 cleanup / teardown；不创建 window / view / layer；不 visible order；不取 drawable；不创建 command queue / command buffer / encoder；不 render / commit / present / GPU submission；不写 artifact；不发布 diagnostics；不返回 pointer / handle / `id` / `Class`；不新增 public API / production C ABI；不写 renderer state / backend-ready truth；不修改 `runtime/cjgui/src/runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness payload schema preflight decision`
