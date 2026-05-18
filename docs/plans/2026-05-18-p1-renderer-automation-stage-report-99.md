# P1 Renderer Automation Stage Report 99

日期：2026-05-18

状态：automation report / continuous engineering stage package / D3 result-envelope renderer-state external packet provenance replay slice

## 本轮目标

本轮接续 stage98 `D3 result-envelope renderer-state external packet promotion admission` 后的 next opening。当前 shell 仍没有 externally verified Metal-capable result packet，因此本轮不执行 runtime native probe、不消费 D3 approval、不写 renderer state；改为推进 external packet provenance replay readiness 的可验证 runtime owner 与 probe suite。

本阶段的核心推进是：把 promotion-admission 之后的 external packet provenance replay 固定成 internal runtime value 和 focused regression suite。该 replay 只承认 replay contract / dehydrated provenance requirement，不把 current shell 的 packet 解释成 external provenance truth；即便未来 external provenance replay 成立，renderer-state write 仍必须等待单独 write decision。

## GitNexus / CodeLattice 预检

- GitNexus repo 使用 `cangjie-live-codelattice`。
- GitNexus impact / context 对 stage98 promotion-admission endpoint 与本轮 planned provenance-replay endpoint 均返回 target not found / `UNKNOWN`，未作为安全证明。
- 进入实现前 `detect-changes --repo cangjie-live-codelattice --scope all` 为 7 tracked files / 3 symbols / 0 affected processes / risk low，但只覆盖 tracked docs heading symbols，未覆盖 untracked owner / scripts。
- CodeLattice sidecar 对 live repo 返回 `path_denied`，未作为安全证明。
- 按项目规则，`UNKNOWN` / not found / path denied 没有被当作安全证明；实际安全证明来自源码阅读、RED/GREEN owner probe、provenance replay packet、classifier、write-decision preflight、source/build guard、focused suite、direct build 与 public / protected / forbidden scans。
- 未出现 HIGH / CRITICAL 风险；没有越过需停止的硬边界。

## 真实工程增量

本轮完成 7 个真实工程增量：

1. RED owner probe
   - 新增 owner probe [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_owner.sh)。
   - 先验证 planned script 不存在返回 127；新增 probe 后按预期失败：缺少 planned owner `runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay.cj`。

2. External packet provenance replay internal owner
   - 新增 owner [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay.cj)。
   - Endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStateExternalPacketProvenanceReplayReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStateExternalPacketProvenanceReplayDraft()`。
   - Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStateExternalPacketPromotionAdmissionReadiness`。
   - GREEN：owner probe 验证 promotion-admission input、provenance replay route、promotion admission packet replay requirement、external Metal-capable provenance replay requirement、shape/provenance separation、current-shell replay denial、separate renderer-state write decision requirement 与 no-truth-upgrade facts。

3. Provenance replay packet
   - 新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_packet.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_packet.sh)。
   - Packet 消费 stage98 focused promotion-admission suite packet，生成 provenance replay packet。
   - GREEN：`d3_result_envelope_renderer_state_external_packet_provenance_replay_packet_passed=true`、`external_packet_provenance_replay_ready=true`、`current_shell_provenance_replay_denied=true`、`renderer_state_write_decision_after_external_provenance_required=true`。

4. Provenance replay classifier
   - 新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_classifier.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_classifier.sh)。
   - Classifier 区分 replay contract、shape admission 与 provenance truth，确认 current shell replay 不被 admission。
   - GREEN：`d3_result_envelope_renderer_state_external_packet_provenance_replay_classifier_passed=true`、`shape_admission_is_not_provenance_truth=true`、`current_shell_provenance_replay_admitted=false`、`renderer_state_write_permission_from_replay=false`。

5. Write-decision preflight
   - 新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_write_decision_preflight.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_write_decision_preflight.sh)。
   - Preflight 消费 replay packet 与 classifier packet，固定 provenance replay 不是 renderer-state write permission。
   - GREEN：`d3_result_envelope_renderer_state_external_packet_provenance_replay_write_decision_preflight_passed=true`、`separate_renderer_state_write_decision_required=true`、`renderer_state_write_after_provenance_replay_allowed=false`。

6. Source/build provenance-replay guard
   - 新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_source_build_guard.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_source_build_guard.sh)。
   - Guard 串联 owner、replay packet、classifier、write-decision preflight、`cjpm build --skip-script`、protected path scan、public / foreign scan 与 native bridge forbidden scan。
   - GREEN：`source_build_external_packet_provenance_replay_guard_passed=true`、`runtime_package_build_passed=true`。

7. Focused provenance-replay suite
   - 新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_suite.sh)。
   - Suite 串联 owner probe、replay packet、classifier、write-decision preflight 与 source/build guard，并重放 upstream promotion-admission suite 以避免依赖临时 packet。
   - GREEN：`d3_result_envelope_renderer_state_external_packet_provenance_replay_suite_passed=true`。

这些增量覆盖 runtime owner、provenance replay packet、replay classifier、write-decision preflight、source/build integration、focused suite integration 与 TDD RED/GREEN 收口。Housekeeping 不计入上述 7 个工程增量。

## Housekeeping

以下内容不计入真实工程增量：

- 本 report 本身。
- README / tracker / plans README / DESIGN_INTENT_INDEX / runtime README 的 latest-entry 最小同步。
- automation memory 更新。
- 本轮未新增 compact manifest 或 topic manifest 长流水；当前没有 truth / authority 扩张、public surface、protected path、GPU / renderer state 等硬边界变化。

## 验证结果

- RED：planned provenance-replay owner probe 先因缺少 script 返回 127；新增 owner probe 后因缺少 owner file 返回 expected missing。
- RED：planned replay packet / classifier / write-decision preflight / source-build guard / focused suite 在新增前均返回 missing script。
- `zsh -n`：新增 6 个 scripts 通过。
- Owner probe：通过。
- Provenance replay packet：通过。
- Provenance replay classifier：通过。
- Write-decision preflight：通过。
- Source/build guard：通过，包含 `cjpm build --skip-script`。
- Focused provenance-replay suite：通过；`d3_result_envelope_renderer_state_external_packet_provenance_replay_suite_passed=true`。
- Direct `cjpm build --target-dir /tmp/cjgui-stage99-direct-build/target --skip-script`：通过；仍有既有 230 warnings。
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
- `application_singleton_accessor_call=false`
- `native_bridge_expansion=false`
- `protected_path_modified=false`
- `production_public_c_abi_added=false`
- `renderer_state_write=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`
- `external_packet_provenance_replay_ready=true`
- `current_shell_provenance_replay_denied=true`
- `current_shell_provenance_replay_admitted=false`
- `external_packet_provenance_replay_allowed=false`
- `shape_admission_is_not_provenance_truth=true`
- `separate_renderer_state_write_decision_required=true`
- `renderer_state_write_after_provenance_replay_allowed=false`
- `renderer_state_write_blocked_until_external_provenance_and_write_decision=true`
- no production singleton ownership truth upgrade
- no backend-ready truth upgrade
- no pointer / native object payload acceptance
- no `nextDrawable`
- no render encoder / draw / commit / present / GPU submission

## 当前 next route

下一条可推进路线：

`P1 Renderer visible-window NSApplication shared-application runtime native-readiness external validated packet production / provenance replay in an externally verified Metal-capable shell, or external-packet-provenance-replay/source-build replay while current shell lacks external provenance; renderer-state write remains blocked until external provenance packet plus a separate renderer-state write decision without automation-default approval consumption`。

当前 blocker 状态：

- `automation_blocker=false_for_external_packet_provenance_replay_and_source_build_guard`
- `automation_blocker=false_for_replay_classifier_and_write_decision_preflight_rerun`
- `automation_blocker=true_for_actual_external_result_packet_production_in_current_non_metal_shell`
- `automation_blocker=true_for_renderer_state_write_without_external_provenance_packet_and_separate_write_decision`
- `requires_external_metal_capable_shell=true_for_actual_external_result_packet`
