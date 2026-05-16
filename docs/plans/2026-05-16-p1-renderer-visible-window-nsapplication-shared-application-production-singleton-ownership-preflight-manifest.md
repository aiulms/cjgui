# P1 Renderer 可见窗口 NSApplication Shared-Application Production Singleton Ownership Preflight Manifest

状态：manifest / docs-only ownership preflight / source-selection required / no implementation

## 阶段定位

本 manifest 记录 production singleton ownership preflight 阶段。该阶段由用户明确批准
开启，但仅限 docs / preflight / decision。它消费 isolated actual accessor probe、
preexisting harness decision、throwaway creation probe 与 approval reconciliation evidence，
并把后续 runway 固定为 source-and-cleanup boundary decision。

该阶段不是 production singleton ownership implementation，不创建 runtime truth，不调用
`NSApplication.sharedApplication`。

## 上游

- [throwaway creation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-throwaway-creation-probe-first-slice-manifest.md)
- [preexisting harness manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-preexisting-application-harness-manifest.md)
- [isolated actual accessor call first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-first-slice-manifest.md)
- [production singleton ownership approval reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-preflight-approval-reconciliation-manifest.md)

## 本阶段文档

- [production singleton ownership preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-preflight-decision.md)
- [production singleton ownership preflight closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-preflight-closure-review.md)
- [production singleton ownership preflight next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-preflight-next-boundary-decision.md)

## Owner / Probe

本阶段不新增 owner 或 probe。继续复用并验证上游 evidence：

- Throwaway evidence owner：
  [runtime_renderer_visible_window_nsapplication_shared_application_throwaway_creation_probe_evidence.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_throwaway_creation_probe_evidence.cj)
- Throwaway owner probe：
  [verify_renderer_visible_window_nsapplication_shared_application_throwaway_creation_probe_evidence_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_throwaway_creation_probe_evidence_owner.sh)
- Throwaway isolated native probe：
  [verify_native_bridge_nsapplication_shared_application_throwaway_creation_probe.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nsapplication_shared_application_throwaway_creation_probe.sh)
- Isolated no-create owner probe：
  [verify_renderer_visible_window_nsapplication_shared_application_isolated_actual_accessor_call_probe_evidence_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_isolated_actual_accessor_call_probe_evidence_owner.sh)
- Isolated no-create native probe：
  [verify_native_bridge_nsapplication_shared_application_isolated_actual_accessor_call_probe.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nsapplication_shared_application_isolated_actual_accessor_call_probe.sh)
- Preflight guard owner probe：
  [verify_renderer_visible_window_nsapplication_shared_application_actual_accessor_call_preflight_guard_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_actual_accessor_call_preflight_guard_owner.sh)

## Canonical 状态

- Canonical endpoint：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness`
- Default draft：
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceDraft()`
- Runtime input：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness`

## Truth

- `production_singleton_ownership_preflight_opened=true`
- `production_singleton_ownership_truth=false`
- `production_singleton_owner_boundary_required=true`
- `production_singleton_source_selection_required=true`
- `production_singleton_cleanup_responsibility_required=true`
- `production_singleton_headless_fail_closed_required=true`
- `production_singleton_main_thread_confinement_required=true`
- `production_singleton_implementation_allowed=false`
- `production_actual_accessor_call_site_allowed=false`
- `production_public_c_abi_added=false`
- `public_api_modified=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`

## Evidence carry-forward

- Throwaway creation evidence remains evidence only:
  `classification=241` / `side_effect_classification=throwaway_singleton_created_by_accessor`。
- Isolated no-create evidence remains fail-closed:
  `classification=-240` / `side_effect_classification=fail_closed_preexisting_application_missing`。
- `labs/macos_bridge_smoke` remains feasibility / regression evidence and cannot be moved into
  production singleton ownership.

## Stop-line

不实现 production singleton owner；不新增 runtime owner 表示 production singleton
ownership truth；不新增 native C ABI；不调用 `NSApplication.sharedApplication`；
不调用 `setActivationPolicy` / `activateIgnoringOtherApps` / `run` / `stop` /
`terminate`；不创建 `NSWindow` / `NSView` / `CAMetalLayer`；不 visible order；不
`nextDrawable`；不创建 command queue / command buffer / encoder；不 render / commit /
present / GPU submission；不写 artifact；不发布 diagnostics；不新增 public API /
public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application production singleton ownership source-and-cleanup boundary decision`
