# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Readiness Preflight Manifest

状态：manifest / value-only owner / readiness preflight closed

## 阶段定位

本 manifest 记录 external preexisting singleton source readiness preflight。该阶段消费
production singleton ownership source-cleanup boundary，把 external source readiness 固定为
后续 source witness contract shape decision 的入口。

该阶段不是 production singleton owner implementation，不创建 runtime ownership truth，不调用
application singleton accessor，也不新增 native C ABI。

## 上游

- [source-cleanup boundary manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-source-cleanup-boundary-manifest.md)
- [production singleton ownership preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-preflight-manifest.md)
- [throwaway creation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-throwaway-creation-probe-first-slice-manifest.md)

## 本阶段文档

- [external source readiness preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-preflight-decision.md)
- [external source readiness preflight closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-preflight-closure-review.md)
- [external source readiness preflight next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-preflight-next-boundary-decision.md)

## Owner / Probe

- Owner：
  [runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_preflight.cj)
- Owner probe：
  [verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_preflight_owner.sh)

## Canonical 状态

- Canonical endpoint：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightReadiness`
- Default draft：
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightDraft()`
- Runtime input：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryReadiness`

## Truth

- `external_preexisting_singleton_source_readiness_preflight_ready=true`
- `external_owner_provided_preexisting_singleton_required=true`
- `external_source_witness_before_runtime_owner_required=true`
- `throwaway_singleton_rejected_as_external_source=true`
- `renderer_created_singleton_allowed=false`
- `source_lifetime_outlives_renderer_observation_required=true`
- `cleanup_owned_by_external_source_required=true`
- `renderer_cleanup_execution_blocked=true`
- `main_thread_confinement_required=true`
- `headless_fail_closed_required=true`
- `future_runtime_owner_explicit_approval_required=true`
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
truth；不新增 native C ABI；不调用 application singleton accessor；不 activation；
不修改 activation policy；不运行 AppKit event loop / bounded pump；不执行 cleanup /
teardown；不创建 window / view / layer；不 visible order；不 `nextDrawable`；不创建
command queue / command buffer / encoder；不 render / commit / present / GPU submission；
不写 artifact；不发布 diagnostics；不新增 public API / public C ABI；不修改
`runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness contract shape decision`
