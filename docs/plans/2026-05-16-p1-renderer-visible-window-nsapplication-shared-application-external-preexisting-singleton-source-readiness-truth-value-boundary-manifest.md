# P1 Renderer visible-window NSApplication shared-application source readiness truth value boundary manifest

状态：manifest / internal-only / source readiness truth value false

## 阶段定位

本 manifest 记录 external preexisting singleton source readiness truth value boundary。该阶段新增 internal owner，用来承接 preauthorized actual accessor first-slice、source readiness admission preflight 与 witness packet truth admission preflight，并固定 source readiness truth 仍 conditional / false。

它不是 production singleton owner implementation，不是 production actual accessor call site，不调用 application singleton accessor，也不新增 native C ABI。

## 上游

- [preauthorized actual accessor first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-preauthorized-actual-accessor-first-slice-manifest.md)
- [source readiness admission preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-admission-preflight-manifest.md)
- [witness packet truth admission preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-packet-truth-admission-preflight-manifest.md)

## 本阶段文档

- [decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-truth-value-boundary-decision.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-truth-value-boundary-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-truth-value-boundary-next-boundary-decision.md)

## Owner / Probe

- Owner：[runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_truth_value_boundary.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_truth_value_boundary.cj)
- Owner probe：[verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_truth_value_boundary_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_truth_value_boundary_owner.sh)

## Canonical 状态

- Endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessTruthValueBoundaryReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessTruthValueBoundaryDraft()`
- Runtime inputs：
  - `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPreauthorizedActualAccessorFirstSliceReadiness`
  - `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessAdmissionPreflightReadiness`
  - `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightReadiness`

## Truth

- `source_readiness_truth_value_boundary_opened=true`
- `source_readiness_truth_conditional=true`
- `external_preexisting_singleton_source_readiness_truth=false`
- `external_preexisting_singleton_source_witness_truth=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation=false`
- `production_actual_accessor_call_site=false`
- `throwaway_creation_rejected_as_production_ownership_truth=true`
- `actual_accessor_call_isolated_native_probe_only=true`
- `artifact_publication=false`
- `public_api_modified=false`
- `production_public_c_abi_added=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`

## Stop-line

不升级 source readiness truth；不实现 production singleton owner；不新增 production actual accessor call site；不新增 native C ABI；不调用 `NSApplication.sharedApplication`；不创建或激活 `NSApplication`；不修改 activation policy；不运行 AppKit event loop / bounded pump；不执行 cleanup / teardown；不创建 window / view / layer；不 visible order；不 `nextDrawable`；不创建 command queue / command buffer / encoder；不 render / commit / present / GPU submission；不写 artifact；不发布 diagnostics；不返回 pointer / handle / `id` / `Class`；不新增 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application production singleton ownership value boundary / internal readiness owner decision`
