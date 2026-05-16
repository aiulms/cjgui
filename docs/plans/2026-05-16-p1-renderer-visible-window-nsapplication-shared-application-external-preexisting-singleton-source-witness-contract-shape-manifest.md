# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Witness Contract Shape Manifest

状态：manifest / value-only owner / contract shape closed

## 阶段定位

本 manifest 记录 external preexisting singleton source witness contract shape。该阶段消费
external source readiness preflight，把未来 source witness contract 的必备字段和禁止误读点
固定为后续 admission policy preflight 的入口。

该阶段不是 production singleton owner implementation，不创建 runtime ownership truth，不调用
application singleton accessor，也不新增 native C ABI。

## 上游

- [external source readiness preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-preflight-manifest.md)
- [source-cleanup boundary manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-source-cleanup-boundary-manifest.md)
- [throwaway creation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-throwaway-creation-probe-first-slice-manifest.md)

## 本阶段文档

- [source witness contract shape decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-contract-shape-decision.md)
- [source witness contract shape closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-contract-shape-closure-review.md)
- [source witness contract shape next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-contract-shape-next-boundary-decision.md)

## Owner / Probe

- Owner：
  [runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_contract_shape.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_contract_shape.cj)
- Owner probe：
  [verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_contract_shape_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_contract_shape_owner.sh)

## Canonical 状态

- Canonical endpoint：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeReadiness`
- Default draft：
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeDraft()`
- Runtime input：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightReadiness`

## Truth

- `external_preexisting_singleton_source_witness_contract_shape_ready=true`
- `witness_provided_by_external_owner_required=true`
- `preexisting_singleton_before_renderer_observation_required=true`
- `witness_captured_before_runtime_owner_required=true`
- `main_thread_witness_declaration_required=true`
- `no_renderer_creation_invariant_required=true`
- `no_renderer_accessor_call_invariant_required=true`
- `pointer_handle_class_id_return=false`
- `source_lifetime_outlives_renderer_observation_required=true`
- `cleanup_ownership_retained_by_external_source=true`
- `renderer_cleanup_execution_blocked=true`
- `headless_fail_closed_witness_required=true`
- `non_user_visible_observation_required=true`
- `throwaway_singleton_as_witness=false`
- `smoke_harness_as_production_witness=false`
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

不实现 production singleton owner；不新增 runtime owner 表示 production singleton ownership
truth；不新增 native C ABI；不调用 application singleton accessor；不返回 pointer / handle /
`id` / `Class`；不 activation；不修改 activation policy；不运行 AppKit event loop / bounded
pump；不执行 cleanup / teardown；不创建 window / view / layer；不 visible order；不
`nextDrawable`；不创建 command queue / command buffer / encoder；不 render / commit /
present / GPU submission；不写 artifact；不发布 diagnostics；不新增 public API / public
C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness admission policy preflight decision`
