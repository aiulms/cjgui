# P1 Renderer 可见窗口 NSApplication Shared-Application Production Singleton Ownership Source-Cleanup Boundary Manifest

状态：manifest / value-only owner / source-cleanup boundary closed

## 阶段定位

本 manifest 记录 production singleton ownership source-cleanup boundary。该阶段消费
production singleton ownership preflight 与 throwaway creation probe evidence，把 source selection
和 cleanup responsibility 固定为后续 external preexisting singleton source readiness preflight 的
入口。

该阶段不是 production singleton owner implementation，不创建 runtime ownership truth，不调用
application singleton accessor，也不新增 native C ABI。

## 上游

- [production singleton ownership preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-preflight-manifest.md)
- [throwaway creation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-throwaway-creation-probe-first-slice-manifest.md)
- [preexisting harness manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-preexisting-application-harness-manifest.md)

## 本阶段文档

- [source-cleanup boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-source-cleanup-boundary-decision.md)
- [source-cleanup boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-source-cleanup-boundary-closure-review.md)
- [source-cleanup boundary next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-source-cleanup-boundary-next-boundary-decision.md)

## Owner / Probe

- Owner：
  [runtime_renderer_visible_window_nsapplication_shared_application_production_singleton_ownership_source_cleanup_boundary.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_production_singleton_ownership_source_cleanup_boundary.cj)
- Owner probe：
  [verify_renderer_visible_window_nsapplication_shared_application_production_singleton_ownership_source_cleanup_boundary_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_production_singleton_ownership_source_cleanup_boundary_owner.sh)

## Canonical 状态

- Canonical endpoint：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryReadiness`
- Default draft：
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryDraft()`
- Runtime input：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness`

## Truth

- `production_singleton_ownership_source_cleanup_boundary_ready=true`
- `throwaway_singleton_rejected_as_production_source=true`
- `external_preexisting_singleton_source_required=true`
- `future_runtime_owner_explicit_approval_required=true`
- `cleanup_responsibility_before_implementation_required=true`
- `cleanup_execution_blocked=true`
- `main_thread_confinement_required=true`
- `headless_fail_closed_required=true`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation_allowed=false`
- `production_actual_accessor_call_site_allowed=false`
- `public_api_modified=false`
- `production_public_c_abi_added=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`

## Evidence carry-forward

- Throwaway creation evidence remains evidence only:
  `classification=241` / `side_effect_classification=throwaway_singleton_created_by_accessor`。
- no-create isolated actual accessor call probe remains fail-closed when no preexisting singleton
  exists:
  `classification=-240` / `side_effect_classification=fail_closed_preexisting_application_missing`。
- `labs/macos_bridge_smoke` remains regression / feasibility evidence and cannot be moved into
  production singleton ownership.

## Stop-line

不实现 production singleton owner；不新增 runtime owner 表示 production singleton ownership
truth；不新增 native C ABI；不调用 `NSApplication.sharedApplication`；不 activation；
不修改 activation policy；不运行 AppKit event loop / bounded pump；不执行 cleanup /
teardown；不创建 window / view / layer；不 visible order；不 `nextDrawable`；不创建
command queue / command buffer / encoder；不 render / commit / present / GPU submission；
不写 artifact；不发布 diagnostics；不新增 public API / public C ABI；不修改
`runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source readiness preflight decision`
