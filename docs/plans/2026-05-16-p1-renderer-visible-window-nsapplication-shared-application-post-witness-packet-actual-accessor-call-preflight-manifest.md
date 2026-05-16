# P1 Renderer 可见窗口 NSApplication Shared-Application Post-Witness-Packet Actual-Call Preflight Manifest

状态：manifest / value-only owner / explicit approval required

## 阶段定位

本 manifest 记录 post-witness-packet actual-call preflight revalidation。本阶段接续 witness packet truth admission preflight，并复用既有 no-call preflight guard readiness，明确当前只打开 actual-call preflight，不执行 actual application singleton accessor call。

该阶段不是 actual accessor call implementation，不是 production singleton owner implementation，不新增 native C ABI，也不升级 witness truth、source readiness truth 或 production singleton ownership truth。

## 上游

- [witness packet truth admission preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-packet-truth-admission-preflight-manifest.md)
- [actual accessor call preflight guard manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-manifest.md)
- [actual accessor side-effect audit branch manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-side-effect-audit-branch-manifest.md)

## 本阶段文档

- [post-witness-packet actual-call preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-post-witness-packet-actual-accessor-call-preflight-decision.md)
- [post-witness-packet actual-call preflight closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-post-witness-packet-actual-accessor-call-preflight-closure-review.md)
- [post-witness-packet actual-call preflight next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-post-witness-packet-actual-accessor-call-preflight-next-boundary-decision.md)

## Owner / Probe

Owner file：

[runtime_renderer_visible_window_nsapplication_shared_application_post_witness_packet_actual_accessor_call_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_post_witness_packet_actual_accessor_call_preflight.cj)

Owner probe：

[verify_renderer_visible_window_nsapplication_shared_application_post_witness_packet_actual_accessor_call_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_post_witness_packet_actual_accessor_call_preflight_owner.sh)

## Canonical 状态

当前 canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightReadiness`

当前 default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightDraft()`

当前 runtime inputs：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightReadiness`
- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`

## Truth

- `post_witness_packet_actual_accessor_call_preflight_opened=true`
- `only_actual_call_preflight_opened=true`
- `actual_accessor_call_implementation=false`
- `production_actual_accessor_call_site=false`
- `packet_truth_admission_as_witness_truth=false`
- `packet_truth_admission_as_source_readiness_truth=false`
- `packet_truth_admission_as_production_singleton_ownership_truth=false`
- `explicit_human_decision_before_actual_call_first_slice_required=true`
- `main_thread_confined_future_first_slice_required=true`
- `isolated_probe_first_future_first_slice_required=true`
- `source_readiness_truth_recovered=false`
- `external_preexisting_singleton_source_witness_truth=false`
- `external_preexisting_singleton_source_readiness_truth=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation_allowed=false`
- `production_actual_accessor_call_site_allowed=false`
- `activation_policy_mutated=false`
- `activation_called=false`
- `appkit_event_loop_started=false`
- `bounded_run_loop_pump_implemented=false`
- `cleanup_teardown_executed=false`
- `window_view_layer_created=false`
- `visible_order=false`
- `drawable_acquired=false`
- `render_commit_present_gpu_submission=false`
- `artifact_or_diagnostics_publication=false`
- `pointer_handle_class_id_return=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`
- `public_api_modified=false`
- `production_public_c_abi_added=false`
- `renderer_state_write=false`
- `backend_ready_truth=false`

## Stop-line

不调用 application singleton accessor；不创建或激活 `NSApplication`；不修改 activation policy；不运行 AppKit event loop / bounded pump；不执行 cleanup / teardown；不创建 window / view / layer；不 visible order；不 `nextDrawable`；不创建 command queue / command buffer / encoder；不 render / commit / present / GPU submission；不写 artifact；不发布 diagnostics；不返回 pointer / handle / `id` / `Class`；不新增 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor call first-slice explicit human approval decision`
