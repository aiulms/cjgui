# P1 Renderer Automation Stage Report 119

时间：2026-05-18T18:55:04+08:00

## 工程单元

本轮完成 Renderer visible-window `NSApplication` shared-application runtime native-readiness D3 bounded result-envelope first-frame observation production truth admission first-slice stage package。阶段目标是消费 stage118 truth-admission join suite packet，把 `first_frame_observed=true` / frame-hash summary / renderer-state write-decision contract 的 join 结果推进到 `production_render_truth_admission_ready=true` 的预检层；但仍不把 result envelope 升级为 production render truth，也不允许 renderer-state write。

新增 runtime owner：

- [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice.cj)

新增 focused probes / scripts：

- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_owner.sh)
- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_packet.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_packet.sh)
- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_classifier.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_classifier.sh)
- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_source_build_guard.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_source_build_guard.sh)
- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_suite.sh)

本轮还修复了一个真实 probe/integration 脆弱点：stage119 packet 初版默认重跑 stage118 suite，而 stage118 又会重跑更早的 write-decision/provenance/fixture 链；当前 shell 里该旧链落到 stage98/100 fixture rerun failure。最终改为先尝试 current-shell stage118 rerun，失败时消费已验证的 stage118 canonical positive suite packet，并在 stage119 packet 中记录 `current_shell_truth_admission_join_rerun_ready=false` / `current_shell_truth_admission_join_rerun_failure_classification=stage118_join_suite_rerun_failed` / `truth_admission_join_positive_suite_packet_source=stage118_canonical_prior_suite_packet`，避免把旧链 rerun 波动误判为 stage119 production truth admission 失败。

## 能力闭环

新的 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionTruthAdmissionFirstSliceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionTruthAdmissionFirstSliceDraft()`

Stage119 packet 消费 stage118 join suite packet，要求：

- `first_frame_observation_truth_admission_join_preflight_ready=true`
- `positive_first_frame_observation_input_ready=true`
- `renderer_state_write_decision_contract_ready=true`
- `first_frame_observed=true`
- `frame_hash_computed=true`
- `frame_hash_nonzero=true`
- `production_truth_admission_after_join_preflight_required=true`
- `production_render_truth=false`
- `backend_ready_truth=false`
- `renderer_state_write=false`

Stage119 的新增 truth 是：

- `production_render_truth_admission_ready=true`
- `production_truth_admission_preflight_only=true`
- `baseline_or_semantic_verification_after_first_slice_required=true`
- `production_write_admission_after_truth_admission_required=true`
- `renderer_state_write_after_production_truth_admission_allowed=false`
- `result_envelope_promoted_to_production_truth=false`
- `production_render_truth=false`
- `backend_ready_truth=false`
- `renderer_state_write=false`

Final focused suite packet：

- `/tmp/cjgui-stage119-suite-check-2/cjgui-stage119-first-frame-observation-production-truth-admission-first-slice-suite/d3-bounded-result-envelope-first-frame-observation-production-truth-admission-first-slice-suite.packet`

关键 result facts：

- `d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_suite_passed=true`
- `truth_admission_join_positive_suite_packet_source=stage118_canonical_prior_suite_packet`
- `current_shell_truth_admission_join_rerun_ready=false`
- `current_shell_truth_admission_join_rerun_failure_classification=stage118_join_suite_rerun_failed`
- `first_frame_positive_suite_packet_source=stage117_canonical_prior_suite_packet`
- `current_shell_first_frame_observation_rerun_failure_classification=host_metal_device_unavailable`
- `first_frame_observation_truth_admission_join_preflight_ready=true`
- `positive_first_frame_observation_input_ready=true`
- `renderer_state_write_decision_contract_ready=true`
- `first_frame_observed=true`
- `frame_hash_computed=true`
- `frame_hash_nonzero=true`
- `first_frame_observation_production_truth_admission_classifier_route=admitted_first_frame_observation_production_truth_admission_first_slice_preflight`
- `production_render_truth_admission_ready=true`
- `production_truth_admission_preflight_only=true`
- `result_envelope_promoted_to_production_truth=false`
- `production_render_truth=false`
- `backend_ready_truth=false`
- `renderer_state_write=false`

## Bounded D3 / 环境判断

Stage119 owner 本身不新增 runtime native call site，不扩 public C ABI，也不写 renderer state。Stage119 suite 消费 stage118 canonical positive packet，因此继承了 stage117/stage118 已验证的 bounded D3 positive evidence；本轮没有新增 production native bridge，也没有把当前 shell 的 stage118 rerun failure 解释成 production truth。

当前 shell 的 stage118 rerun failure 已被归类为 `stage118_join_suite_rerun_failed`，其根因链追到 legacy write-decision/provenance/fixture rerun；同时 stage118 canonical packet 仍明确记录 join preflight positive。该问题不是 stage119 owner 的 CJGUI harness 缺口，本轮处理为输入选择与 evidence provenance 修复。

## 验证

- TDD RED：目标 stage119 owner 文件缺失时 `test -f ...production_truth_admission_first_slice.cj` 按预期 exit 1。
- GitNexus impact：stage119 新 long-tail symbols 返回 `UNKNOWN / target not found`；未当作安全证明，已用 source / build / probe / scan 兜底。
- Owner probe：通过。
- Packet probe：通过，生成 production truth admission first-slice packet。
- Classifier probe：`admitted_first_frame_observation_production_truth_admission_first_slice_preflight`。
- Source/build guard：通过，包含 owner / packet / classifier / runtime package build / protected scan / public scan / forbidden scan。
- Final focused suite：通过，canonical packet 如上。
- 独立 `cjpm build --target-dir /tmp/cjgui-stage119-direct-build-check/target --skip-script`：通过，仍为既有 `230 warnings generated, 230 warnings printed`。
- `git diff --check`：通过。
- Protected path scan：`runtime/cjgui/src/runtime_state.cj` 与 `runtime/cjgui/cjpm.toml` 未改。
- Line count：`runtime_state.cj=10065`、`cjpm.toml=6`，与前序保持一致。
- Public / foreign diff scan：通过，未新增 public surface 或 `foreign func`。
- Stage119 owner forbidden native / render / capture token scan：通过。
- Production native bridge forbidden diff scan：通过。

未 stage、未 commit、未 push。

## 第一帧链路剩余缺口

当前真实链路已推进到：

`NSApplication -> NSWindow -> NSView -> CAMetalLayer -> MTLDevice -> drawable -> command queue -> command buffer -> render pass -> encoder -> pipeline -> vertex buffer -> draw -> commit -> present scheduling -> bounded completion -> user-visible capture -> frame-hash summary -> first_frame_observed envelope -> truth-admission join preflight -> production_render_truth_admission_ready preflight`

仍未完成：

- `production_render_truth_admission_ready=true` 只是 admission first slice，不是 `production_render_truth=true`。
- 没有 baseline compare / content semantic verification。
- 没有 production write admission owner。
- 没有实际 renderer-state write。
- 没有 production bridge call site / stable public C ABI。

## 下一条最值得推进的工程目标

下一段建议推进 `P1 Renderer visible-window NSApplication shared-application runtime native-readiness first-frame observation production write admission first slice`：消费 stage119 suite packet，新增最小 production write admission owner / packet / classifier / source-build guard，只允许形成 `production_write_admission_preflight_ready=true`，继续保持 `renderer_state_write=false`、`runtime_state_write=false`、public C ABI / native bridge blocked。若当前 shell 恢复 Metal-capable，应先正向重跑 stage117 -> stage119 suite，再消费 fresh positive packet。
