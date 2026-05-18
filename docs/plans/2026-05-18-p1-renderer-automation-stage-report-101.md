# P1 Renderer Automation Stage Report 101

日期：2026-05-18

状态：automation report / continuous engineering stage package / D3 result-envelope renderer-state two-key handoff carrier slice

## 本轮目标

本轮接续 stage100 `D3 result-envelope renderer-state write-decision contract` 后的 next opening。最终 verification 发现当前 shell 已重新呈现 `automation_smoke_metal_capable` / `smoke_exit_code=0`，但仍没有 externally verified result packet，也没有可由 automation 默认消费的 D3 approval，因此本轮不执行 runtime native probe、不消费 D3 approval、不写 renderer state；改为把 stage100 的 two-key join contract 推进成可交接 artifact carrier：external provenance packet slot 与 independent write-decision packet slot 被固定为 packet-path handoff contract，供后续显式批准的 Metal-capable shell 生产真实 external packet 后独立接入。

本阶段的核心推进是：让下一位 AI / 外部 shell 不再只看到抽象 “两把钥匙” 条件，而是看到可重放、可校验、可 source/build 兜底的 handoff packet 与 matrix。当前 shell 仍没有两把真实钥匙，synthetic both-key case 也不被接纳；Metal-capable 只解除旧环境 blocker，不等于 approval 或 provenance truth，因此 renderer-state write 继续 fail-closed。

## GitNexus / CodeLattice 预检

- GitNexus repo 使用 `cangjie-live-codelattice`。
- GitNexus MCP / CLI impact 对 stage100 write-decision-contract endpoint / draft 与 planned stage101 two-key handoff endpoint 返回 target not found / `UNKNOWN`，未作为安全证明。
- GitNexus `query` 对 `renderer state write decision two key join D3 result envelope external provenance packet` 未返回 execution flow。
- CodeLattice impact preview 对 stage100 readiness 返回 ambiguous candidates；对 planned stage101 symbol 在 final production assist 中给出 LOW / 0 callers，但缺少文件定位，未作为唯一安全证明。
- GitNexus final `detect-changes --repo cangjie-live-codelattice --scope all` 返回 7 tracked files / 3 symbols / 0 affected / low；该结果仍未覆盖 untracked owner / scripts / report。
- 按项目规则，`UNKNOWN` / not found / ambiguous / untracked gap 没有被当作安全证明；实际安全证明来自源码阅读、RED/GREEN probes、handoff packet、matrix、source/build guard、focused suite、direct build 与 public / protected / forbidden scans。
- 未出现 HIGH / CRITICAL 风险；没有越过需停止的硬边界。

## 真实工程增量

本轮完成 8 个真实工程增量：

1. RED planned probe checks
   - planned owner / packet / matrix / source-build / suite scripts 在新增前均返回 missing script / exit 127，确认本轮 probes 覆盖新能力。

2. Renderer-state two-key handoff internal owner
   - 新增 owner [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff.cj)。
   - Endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStateTwoKeyHandoffReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStateTwoKeyHandoffDraft()`。
   - Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStateWriteDecisionContractReadiness`。
   - Owner 固定 external provenance packet slot、independent write-decision packet slot、packet-path artifact handoff、external-shell produced provenance requirement、synthetic packet admission denial、source/build replay before handoff 与 no-truth-upgrade facts。

3. Focused owner probe
   - 新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff_owner.sh)。
   - GREEN：`d3_result_envelope_renderer_state_two_key_handoff_owner_present=true`、`write_decision_contract_input=true`、`external_provenance_packet_slot_bound=true`、`independent_write_decision_packet_slot_bound=true`、`synthetic_packet_admission_denied=true`。

4. Two-key handoff packet
   - 新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff_packet.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff_packet.sh)。
   - Packet 优先消费 stage100 write-decision-contract suite packet；若旧 stage94 environment-recovery replay 因当前 shell 已是 Metal-capable 而不再成立，则生成 `capability_drift_compatibility` input packet，要求 stage100 owner probe、capability detector、no approval consumption 与 no runtime native probe。
   - GREEN：`d3_result_envelope_renderer_state_two_key_handoff_packet_passed=true`、`two_key_handoff_carrier_ready=true`、`two_key_handoff_ready_for_external_shell=true`、`write_decision_contract_input_mode=capability_drift_compatibility`、`renderer_state_write_after_two_key_handoff_allowed=false`。

5. Two-key handoff matrix
   - 新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff_matrix.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff_matrix.sh)。
   - Matrix 验证 no-key、external-key-only、write-decision-key-only 与 synthetic-both-key case 均不能在当前 shell 触发 renderer-state write。
   - GREEN：`d3_result_envelope_renderer_state_two_key_handoff_matrix_passed=true`、`synthetic_both_key_case_admitted=false`、`external_shell_real_both_key_case_requires_separate_admission=true`。

6. Source/build two-key handoff guard
   - 新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff_source_build_guard.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff_source_build_guard.sh)。
   - Guard 串联 owner、handoff packet、matrix、`cjpm build --skip-script`、protected path scan、public / foreign scan 与 native bridge forbidden scan。
   - GREEN：`source_build_two_key_handoff_guard_passed=true`、`runtime_package_build_passed=true`。

7. Focused two-key handoff suite
   - 新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff_suite.sh)。
   - Suite 串联 owner probe、handoff packet、matrix 与 source/build guard。
   - GREEN：`d3_result_envelope_renderer_state_two_key_handoff_suite_passed=true`、`two_key_handoff_ready_for_external_shell=true`。

8. Capability-drift compatibility bugfix
   - 修复 final verification 暴露的递归 replay 漂移：旧 stage94 recovery suite 仍要求 `smoke_exit_code=20`，但当前 capability detector 返回 `smoke_exit_code=0` / `automation_smoke_metal_capable`。
   - 修复后 stage101 handoff packet 不把 Metal-capable shell 误解释为 approval / provenance truth，只把它记录为 compatibility input mode；renderer-state write 继续 blocked。

这些增量覆盖 runtime owner、focused owner probe、handoff packet、combination matrix、source/build integration、focused suite integration、capability-drift bugfix 与 RED/GREEN 收口。Housekeeping 不计入上述 8 个工程增量。

## Housekeeping

以下内容不计入真实工程增量：

- 本 report 本身。
- README / tracker / plans README / DESIGN_INTENT_INDEX / runtime README 的 latest-entry 最小同步。
- automation memory 更新。
- 本轮未新增 compact manifest 或 topic manifest 长流水；当前没有 production truth / authority 扩张、public surface、protected path、GPU / renderer state 等硬边界变化。

## 验证结果

- RED：planned two-key handoff owner / packet / matrix / source-build / suite scripts 在新增前返回 missing script / exit 127。
- `zsh -n`：新增 5 个 scripts 通过。
- Owner probe：通过。
- Two-key handoff packet：通过；最终 replay 使用 `write_decision_contract_input_mode=capability_drift_compatibility`，因为当前 capability detector 返回 `smoke_exit_code=0` / `automation_smoke_metal_capable`，而旧 recovery replay 仍绑定 `smoke_exit_code=20`。
- Two-key handoff matrix：通过。
- Source/build guard：通过，包含 `cjpm build --skip-script`。
- Focused two-key handoff suite：通过；`d3_result_envelope_renderer_state_two_key_handoff_suite_passed=true`。
- Direct `cjpm build --target-dir /tmp/cjgui-stage101-direct-build/target --skip-script`：通过，仍有既有 230 warnings。
- `git diff --check`：通过。
- Protected path scan：未修改 `runtime/cjgui/src/runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。
- `runtime_state.cj` 行数：10065，未变化。
- Public / foreign scan：新 owner 未新增 public / foreign declaration。
- Forbidden scan：新 owner non-comment forbidden token scan 无命中；production native bridge diff forbidden scan 无命中。
- Script executable bit / syntax / final newline 检查：通过。

## Stop-line

当前 stop-line 保持：

- `runtime_native_probe_execution=false`
- `human_approved_d3_execution_consumed=false`
- `metal_capable_shell_observed=true`
- `metal_capable_shell_does_not_imply_approval=true`
- `write_decision_contract_input_mode=capability_drift_compatibility`
- `application_singleton_accessor_call=false`
- `native_bridge_expansion=false`
- `protected_path_modified=false`
- `production_public_c_abi_added=false`
- `renderer_state_write=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`
- `two_key_handoff_carrier_ready=true`
- `two_key_handoff_ready_for_external_shell=true`
- `external_provenance_packet_slot_bound=true`
- `independent_write_decision_packet_slot_bound=true`
- `current_shell_external_provenance_packet_present=false`
- `current_shell_independent_write_decision_packet_present=false`
- `synthetic_packet_admission_denied=true`
- `synthetic_both_key_case_admitted=false`
- `external_shell_real_both_key_case_requires_separate_admission=true`
- `renderer_state_write_after_two_key_handoff_allowed=false`
- `renderer_state_write_blocked_until_external_provenance_and_write_decision=true`
- no production singleton ownership truth upgrade
- no backend-ready truth upgrade
- no pointer / native object payload acceptance
- no `nextDrawable`
- no render encoder / draw / commit / present / GPU submission

## 当前 next route

下一条可推进路线：

`P1 Renderer visible-window NSApplication shared-application runtime native-readiness external-shell production of an externally verified provenance packet using the two-key handoff carrier plus independent write-decision packet, or two-key-handoff/source-build replay while current shell lacks external provenance; renderer-state write remains blocked until both real keys are externally produced and separately admitted without automation-default approval consumption`。

当前 blocker 状态：

- `automation_blocker=false_for_two_key_handoff_replay_and_source_build_guard`
- `automation_blocker=false_for_two_key_handoff_matrix_and_packet_reuse`
- `automation_blocker=true_for_actual_external_result_packet_production_without_explicit_approval_and_external_provenance`
- `automation_blocker=true_for_renderer_state_write_without_real_external_provenance_packet_and_independent_write_decision`
- `requires_external_metal_capable_shell=false_current_shell_is_metal_capable`
- `requires_explicit_human_approval=true_for_D3_runtime_native_probe_execution`
