# P1 Renderer Automation Stage Report 118

时间：2026-05-18T18:34:37+08:00

## 工程单元

本轮完成 Renderer visible-window `NSApplication` shared-application runtime native-readiness D3 bounded result-envelope first-frame observation truth-admission join stage package。阶段目标是消费 stage117 positive first-frame observation suite packet，并把 isolated `first_frame_observed=true` / frame-hash summary 与现有 renderer-state write-decision contract 绑定成一个可复用 preflight，而不是继续扩写 blocker / approval / recovery 包。

新增 runtime owner：

- [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join.cj)

新增 focused probes / scripts：

- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join_owner.sh)
- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join_packet.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join_packet.sh)
- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join_classifier.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join_classifier.sh)
- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join_source_build_guard.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join_source_build_guard.sh)
- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join_suite.sh)

实现中修复了一处真实 build 风险：初版 owner 在返回 readiness 中持有两个上游巨大 readiness struct，触发新栈帧 warning；最终改为只持有本 owner 的 join facts 和布尔型结论，独立 build 已确认不再出现 `FirstFrameObservationTruthAdmissionJoin` 相关 stack-frame warning。

## 能力闭环

新的 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationTruthAdmissionJoinReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationTruthAdmissionJoinDraft()`

Stage118 packet 消费两个输入：

- stage117 positive first-frame observation suite packet，要求 `first_frame_observed=true`、`frame_hash_computed=true`、`frame_hash_nonzero=true`、`frame_hash_persisted=false`、`frame_hash_value_logged=false`、`baseline_compared=false`。
- renderer-state write-decision contract suite packet，要求 `renderer_state_write_decision_contract_ready=true`、`write_decision_contract_is_independent=true`、`renderer_state_write_after_two_key_join_allowed=false`。

Stage118 的新增 truth 是：

- `positive_first_frame_observation_input_ready=true`
- `renderer_state_write_decision_contract_ready=true`
- `first_frame_observation_truth_admission_join_preflight_ready=true`
- `isolated_first_frame_observation_bound_to_write_decision_contract=true`
- `truth_admission_join_is_not_production_render_truth=true`
- `production_truth_admission_after_join_preflight_required=true`
- `production_write_admission_after_truth_admission_join_required=true`
- `production_render_truth_after_join_preflight_allowed=false`
- `renderer_state_write_after_truth_admission_join_allowed=false`

Final focused suite packet：

- `/tmp/cjgui-stage118-final-suite-check/cjgui-stage118-first-frame-observation-truth-admission-join-suite/d3-bounded-result-envelope-first-frame-observation-truth-admission-join-suite.packet`

关键 result facts：

- `d3_bounded_result_envelope_first_frame_observation_truth_admission_join_suite_passed=true`
- `first_frame_positive_suite_packet_source=stage117_canonical_prior_suite_packet`
- `stage117_current_shell_first_frame_observation_first_slice_ready=true`
- `stage117_bounded_first_frame_observation_first_slice_executed=true`
- `stage117_first_frame_observation_first_slice_failure_classification=none`
- `stage117_first_frame_observation_first_slice_classifier_route=admitted_bounded_first_frame_observed_first_slice`
- `first_frame_observed=true`
- `frame_hash_computed=true`
- `frame_hash_nonzero=true`
- `positive_first_frame_observation_input_ready=true`
- `renderer_state_write_decision_contract_ready=true`
- `first_frame_observation_truth_admission_join_classifier_route=admitted_bounded_first_frame_observation_truth_admission_join_preflight`
- `first_frame_observation_truth_admission_join_preflight_ready=true`
- `result_envelope_promoted_to_production_truth=false`
- `production_render_truth=false`
- `backend_ready_truth=false`
- `renderer_state_write=false`

## Bounded D3 / 环境判断

本轮 stage118 owner 本身不新增 production native call site，不扩 public C ABI，也不写 renderer state。Packet script 会先尝试重跑 stage117 focused suite；本次当前 shell 重跑分类为 `current_shell_first_frame_observation_rerun_ready=false` / `current_shell_first_frame_observation_rerun_failure_classification=host_metal_device_unavailable`。这没有被当成 CJGUI harness 缺口：同一主线已有 stage117 canonical prior positive suite packet，且该 packet 记录了 `first_frame_observed=true`、`frame_hash_computed=true`、`frame_hash_nonzero=true`、`failure_classification=none`。

因此 stage118 消费的 positive input 来源明确为 `stage117_canonical_prior_suite_packet`，同时在 packet 中保留当前 shell rerun failure classification，避免把 transient host Metal 状态误写成 production truth。

本轮未新增 production render truth、backend-ready truth、production write permission、renderer-state write、runtime_state write、`cjpm.toml` 变更、native bridge expansion 或 public C ABI。

## 验证

- TDD RED：目标 stage118 owner 文件缺失时 `test -f ...truth_admission_join.cj` 按预期 exit 1。
- GitNexus impact：stage118 新 long-tail symbols 返回 `UNKNOWN / target not found`；未当作安全证明，已用 source / build / probe / scan 兜底。
- Owner probe：通过。
- Packet probe：通过，生成 first-frame observation truth-admission join packet。
- Classifier probe：`admitted_bounded_first_frame_observation_truth_admission_join_preflight`。
- Source/build guard：通过，包含 owner / packet / classifier / runtime package build / protected scan / public scan / forbidden scan。
- Final focused suite：通过，canonical packet 如上。
- 独立 `cjpm build --target-dir /tmp/cjgui-stage118-post-stackfix-build-check/target --skip-script`：通过，仍为既有 `230 warnings generated, 230 warnings printed`；未再出现 stage118 owner stack-frame warning。
- `git diff --check`：通过。
- Protected path scan：`runtime/cjgui/src/runtime_state.cj` 与 `runtime/cjgui/cjpm.toml` 未改。
- Line count：`runtime_state.cj=10065`、`cjpm.toml=6`，与前序保持一致。
- Public / foreign diff scan：通过，未新增 public surface 或 `foreign func`。
- Stage118 owner forbidden native / render / capture token scan：通过。
- Production native bridge forbidden diff scan：通过。
- GitNexus MCP `detect_changes`：`changed_count=3`、`changed_files=5`、`affected_count=0`、`risk=low`，当前 graph 仍未覆盖新增 untracked stage owner/scripts。
- Tool CLI `detect-changes --repo cangjie-live-codelattice --scope all`：`Changes: 5 files, 3 symbols`、`Affected processes: 0`、`Risk level: low`；同样未把 graph 不覆盖目标当成安全证明。
- `cangjie-production-alias-check.sh --status`：repo 指向 `cangjie-live-codelattice`，branch `main`，dirty window 仍来自既有未提交自动化文件。

未 stage、未 commit、未 push。

## 第一帧链路剩余缺口

当前真实链路已推进到：

`NSApplication -> NSWindow -> NSView -> CAMetalLayer -> MTLDevice -> drawable -> command queue -> command buffer -> render pass -> encoder -> pipeline -> vertex buffer -> draw -> commit -> present scheduling -> bounded completion -> user-visible capture -> frame-hash summary -> first_frame_observed envelope -> truth-admission join preflight -> renderer-state write-decision contract`

仍未完成：

- `first_frame_observed` 已接入 truth-admission join preflight，但还不是 production render truth。
- 没有 baseline compare / content semantic verification。
- 没有 production truth admission owner。
- 没有 production renderer-state write admission。
- 没有实际 renderer-state write。
- 没有 production bridge call site / stable public C ABI。

## 下一条最值得推进的工程目标

下一段建议推进 `P1 Renderer visible-window NSApplication shared-application runtime native-readiness first-frame observation production truth admission first slice`：消费 stage118 join suite packet，新增最小 production truth admission owner / packet / classifier / source-build guard，只允许形成 `production_render_truth_admission_ready=true` 的 preflight 事实，仍保持 `renderer_state_write_allowed=false`、`renderer_state_write=false`、public C ABI / native bridge blocked。若后续 shell 恢复 Metal-capable，应先用当前 shell 正向重跑 stage117 -> stage118 suite，再消费 fresh positive packet。
