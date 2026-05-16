# P1 Renderer 可见窗口 NSApplication Shared-Application Production Singleton Ownership Preflight Approval Reconciliation Manifest

状态：manifest / docs-only approval reconciliation / no production ownership truth

## 阶段定位

本 manifest 记录 throwaway creation probe first slice 之后的 production singleton
ownership approval reconciliation。本阶段不新增 owner，不打开 production singleton
ownership preflight，只确认当前输入不是 production singleton ownership approval。

## 上游

- [throwaway creation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-throwaway-creation-probe-first-slice-manifest.md)
- [preexisting harness manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-preexisting-application-harness-manifest.md)
- [first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-first-slice-manifest.md)
- [approval reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-approval-reconciliation-manifest.md)

## 本阶段文档

- [production singleton ownership approval reconciliation decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-preflight-approval-reconciliation-decision.md)
- [production singleton ownership approval reconciliation closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-preflight-approval-reconciliation-closure-review.md)
- [production singleton ownership approval reconciliation next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-preflight-approval-reconciliation-next-boundary-decision.md)

## Owner / Probe

本阶段不新增 owner 或 probe。继续复用并验证上游：

- Owner file：
  [runtime_renderer_visible_window_nsapplication_shared_application_throwaway_creation_probe_evidence.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_throwaway_creation_probe_evidence.cj)
- Owner probe：
  [verify_renderer_visible_window_nsapplication_shared_application_throwaway_creation_probe_evidence_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_throwaway_creation_probe_evidence_owner.sh)
- Isolated native probe：
  [verify_native_bridge_nsapplication_shared_application_throwaway_creation_probe.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nsapplication_shared_application_throwaway_creation_probe.sh)

## Canonical 状态

- Canonical endpoint：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness`
- Default draft：
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceDraft()`
- Runtime input：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness`

## Truth

- `accessor_call_attempted=true`
- `accessor_returned_nonnull=true`
- `singleton_exists_after=true`
- `throwaway_application_created=true`
- `classification=241`
- `side_effect_classification=throwaway_singleton_created_by_accessor`
- `throwaway_creation_evidence=true`
- `production_singleton_ownership_truth=false`
- `production_singleton_ownership_approval_granted=false`

## Stop-line

不授权 production singleton ownership、activation policy mutation、activation、AppKit run
loop、bounded pump、application lifecycle control、window / view / layer creation、
visible order、drawable acquisition、command queue / command buffer / encoder
creation、render、commit、present、GPU submission、artifact write、diagnostics
publication、public API、production public C ABI、pointer / handle / `id` / `Class`
return、renderer state write、backend-ready truth、`runtime_state.cj` write 或
`cjpm.toml` change。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application production singleton ownership preflight approval decision`
