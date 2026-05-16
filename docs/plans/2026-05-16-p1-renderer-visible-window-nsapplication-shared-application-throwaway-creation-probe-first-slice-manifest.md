# P1 Renderer 可见窗口 NSApplication Shared-Application Throwaway Creation Probe First Slice Manifest

状态：manifest / isolated native probe evidence / no production ownership truth

## 阶段定位

本 manifest 记录用户批准的 throwaway creation probe first slice。它是
preexisting-application harness decision 之后的极窄 actual accessor observation：
允许 isolated native probe 调用 shared-application accessor，并允许该 accessor 在无
preexisting singleton 时创建 throwaway singleton。

该事实只作为 throwaway creation evidence，不是 production singleton ownership
truth。

## 上游

- [preexisting harness manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-preexisting-application-harness-manifest.md)
- [first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-first-slice-manifest.md)
- [approval reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-approval-reconciliation-manifest.md)

## 本阶段文档

- [throwaway creation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-throwaway-creation-probe-first-slice-preflight-decision.md)
- [throwaway creation closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-throwaway-creation-probe-first-slice-closure-review.md)
- [throwaway creation next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-throwaway-creation-probe-first-slice-next-boundary-decision.md)

## Owner / Probe

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

## Stop-line

不授权 activation policy mutation、activation、AppKit run loop、bounded pump、
application lifecycle control、window / view / layer creation、visible order、
drawable acquisition、command queue / command buffer / encoder creation、render、
commit、present、GPU submission、artifact write、diagnostics publication、public API、
production public C ABI、pointer / handle / `id` / `Class` return、renderer state
write、backend-ready truth、`runtime_state.cj` write 或 `cjpm.toml` change。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application production singleton ownership preflight approval decision`
