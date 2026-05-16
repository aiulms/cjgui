# P1 Renderer 可见窗口 NSApplication Shared-Application Production Singleton Ownership Source-Cleanup Boundary Decision

状态：decision / value-only owner / source-cleanup boundary closed / no production ownership

## 决策输入

上游 [production singleton ownership preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-preflight-manifest.md)
已经把当前 runway 打开到 source / cleanup / fail-closed boundary。该 preflight 只允许
明确 source selection、cleanup responsibility、main-thread confinement、headless
fail-closed 与 stop-line carry-forward，不允许 production singleton owner implementation。

本轮新增 value-only owner：
[runtime_renderer_visible_window_nsapplication_shared_application_production_singleton_ownership_source_cleanup_boundary.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_production_singleton_ownership_source_cleanup_boundary.cj)。
它只消费 throwaway creation probe evidence readiness，不新增 native probe，不新增 C ABI，
不调用 application singleton accessor。

## 上游证据

- [throwaway creation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-throwaway-creation-probe-first-slice-manifest.md)
- [production singleton ownership preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-preflight-manifest.md)
- [preexisting harness manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-preexisting-application-harness-manifest.md)
- [isolated actual accessor call first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-first-slice-manifest.md)

## Decision

production singleton ownership source-cleanup boundary 现在可以作为 value-only owner
封账。结论是：throwaway creation probe 只能证明 isolated native probe 在无 preexisting
singleton 时调用 accessor 会创建 throwaway singleton；该 side effect 不能成为 production
singleton ownership source，也不能升级为 production ownership truth。

后续只保留两条候选 source route：

- external / user app shell preexisting singleton source：Renderer 只消费外部已拥有的
  readiness，不创建 singleton。
- future runtime owner source：必须另有明确人工批准，且先完成 implementation preflight，
  不能由本阶段自动进入。

cleanup responsibility 必须在 implementation 前固定：谁创建或拥有 production singleton，
谁负责 cleanup / shutdown policy。本轮只记录边界事实，不执行 cleanup、teardown、
activation、event loop 或 visible-order 行为。

## Canonical 状态

- Canonical endpoint：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryReadiness`
- Default draft：
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryDraft()`
- Runtime input：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness`
- Owner probe：
  [verify_renderer_visible_window_nsapplication_shared_application_production_singleton_ownership_source_cleanup_boundary_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_production_singleton_ownership_source_cleanup_boundary_owner.sh)

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

## Stop-line

不实现 production singleton owner；不新增 runtime owner 表示 production singleton ownership
truth；不新增 native C ABI；不调用 `NSApplication.sharedApplication`；不调用
`setActivationPolicy` / `activateIgnoringOtherApps` / `run` / `stop` / `terminate`；
不创建 `NSWindow` / `NSView` / `CAMetalLayer`；不 visible order；不 `nextDrawable`；
不创建 command queue / command buffer / encoder；不 render / commit / present / GPU
submission；不执行 cleanup / teardown；不写 artifact；不发布 diagnostics；不新增
public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source readiness preflight decision`
