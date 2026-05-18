# P1 Renderer Automation Stage Report 94

日期：2026-05-18

状态：automation report / continuous engineering stage package / D3 environment recovery route switch

## 本轮目标

本轮接续 stage93 `explicit approval replay checkpoint`。用户给出 limited D3 standing approval 后，先用既有 capability detector 复核当前 shell 是否满足 D3 runtime native probe execution 的 Metal-capable precondition。

Fresh preflight 结果是 `automation_smoke_metal_unavailable` / exit 20、`failure_domain=automation_environment`、`metal_capable_shell_observed=false`。因此本轮没有消费 D3 approval，也没有执行 runtime native probe；改为在同一 stop-line 内完成 D3 environment recovery 阶段包：保留 stage93 checkpoint，新增 runtime owner，生成 bounded native fail-closed packet，分类 recovery route，并用 source/build guard 与 focused suite 固化当前 blocker 是 environment 而不是代码。

## GitNexus / CodeLattice 预检

- GitNexus repo 使用 `cangjie-live-codelattice`。
- GitNexus CLI `context` / `impact` 对 stage93 endpoint / draft 与本轮计划新增 D3 recovery endpoint / draft 返回 not found / `UNKNOWN`，因此没有把图谱缺失当作安全证明。
- 本轮 blast radius 由 GitNexus 视角未覆盖；实际安全证明来自源码阅读、focused probes、runtime package build、protected path scan、public declaration scan、forbidden scan 与最终 `detect-changes`。
- 未出现 HIGH / CRITICAL 风险；没有越过需停止的硬边界。

## 真实工程增量

本轮完成 6 个真实工程增量：

1. D3 precondition failure classification / route switch
   - Fresh capability detector 输出 `smoke_exit_code=20`、`smoke_environment_classification=automation_smoke_metal_unavailable`、`failure_domain=automation_environment`、`external_metal_capable_shell_required=true`。
   - 结论：当前 shell 不满足 D3 runtime native probe execution precondition；D3 approval 保持 available but unconsumed。

2. 新 internal owner + focused owner probe
   - 新增 owner [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery.cj)。
   - 新增 focused owner probe [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery_owner.sh)。
   - Endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3EnvironmentRecoveryReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3EnvironmentRecoveryDraft()`。
   - Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayCheckpointReadiness`。

3. Bounded native fail-closed packet
   - 新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery_native_packet.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery_native_packet.sh)。
   - 该 packet 串联 capability detector、stage93 replay checkpoint suite、isolated actual-accessor native probe disabled path、throwaway creation native probe disabled path。
   - GREEN：`bounded_native_fail_closed_packet_ready=true`、`isolated_accessor_disabled_fail_closed=true`、`throwaway_creation_disabled_fail_closed=true`、`stage93_replay_checkpoint_suite_passed=true`。

4. D3 recovery classifier
   - 新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery_classifier.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery_classifier.sh)。
   - 它消费 native packet，固定 `d3_execution_precondition_met=false`、`d3_execution_denied_by_current_environment=true`、`d3_execution_failure_domain=automation_environment`。

5. Source/build/probe recovery guard
   - 新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery_source_build_guard.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery_source_build_guard.sh)。
   - Guard 串联 owner probe、native packet、classifier、runtime package build、public declaration scan、protected path scan 与 native forbidden scan。
   - GREEN：`runtime_package_build_passed=true`、`source_build_recovery_guard_passed=true`、`code_failure_domain=false`。

6. Focused recovery suite
   - 新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery_suite.sh)。
   - Suite 串联 owner probe、bounded native packet、classifier 与 source/build guard。
   - GREEN：`d3_environment_recovery_suite_passed=true`。

这些增量覆盖 runtime/source owner、native/probe implementation、integration/recovery、focused regression、build/smoke verification 与 stage closure。Housekeeping 不计入上述 6 个工程增量。

## Housekeeping

以下内容不计入真实工程增量：

- 本 report 本身。
- README / tracker / plans README / DESIGN_INTENT_INDEX / runtime README 的 latest-entry 最小同步。
- automation memory 更新。
- 本轮未新增 compact manifest、topic manifest reconciliation 或完整 decision / closure / manifest 包；当前没有 truth / authority 扩张、public surface、protected path、GPU / renderer state 等硬边界变化。

## 验证结果

- RED：计划的 stage94 owner / scripts 缺失检查返回 expected missing。
- Precondition capability detector：通过；当前 shell 分类为 `automation_smoke_metal_unavailable` / exit 20、`failure_domain=automation_environment`、`metal_capable_shell_observed=false`。
- `zsh -n`：新增 scripts 通过。
- Owner probe：通过。
- Bounded native packet：通过；`capability_detector_passed=true`、`stage93_replay_checkpoint_suite_passed=true`、`isolated_accessor_disabled_fail_closed=true`、`throwaway_creation_disabled_fail_closed=true`。
- Recovery classifier：通过；`d3_execution_precondition_met=false`、`d3_execution_denied_by_current_environment=true`、`d3_execution_failure_domain=automation_environment`。
- Source/build guard：通过，包含 `cjpm build --skip-script`；构建仍有既有 warning，但无新增失败。
- Focused recovery suite：通过。
- Direct `cjpm build --target-dir /tmp/cjgui-stage94-direct-build --skip-script`：通过；需 envsetup + `/tmp` ps shim，仍有既有 230 warnings。
- `git diff --check`：通过。
- Protected path scan：未修改 `runtime/cjgui/src/runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。
- `runtime_state.cj` 行数：10065。
- Public declaration scan：新 owner 未新增 `public` / `foreign` declaration。
- Forbidden scan：未发现 production native bridge diff 或新 owner / new scripts 的 non-comment / non-guard hard-boundary token 越线。
- Script executable bit 检查：通过。
- GitNexus `detect-changes --repo cangjie-live-codelattice --scope all`：7 tracked files / 3 symbols / 0 affected processes / risk low；图谱仍主要识别 tracked docs heading symbols，未覆盖本轮 untracked owner/scripts/report，已用 source/build/probe/scans 兜底。

## D3 Approval / Environment

本轮触发 D3 limited approval precondition check，但没有消费 approval。

原因：当前 shell fresh classification 是 `automation_smoke_metal_unavailable`，不满足 `Metal-capable shell` precondition。为了不把 environment blocker 当终点，本轮切换到 recovery route：保留 checkpoint、验证 native probe harness disabled fail-closed path、分类 failure domain，并给下一位 AI 留出 packet reuse route。

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
- no production singleton ownership truth upgrade
- no `nextDrawable`
- no render encoder / draw / commit / present / GPU submission

## 当前 next route

下一条可推进路线：

`P1 Renderer visible-window NSApplication shared-application runtime native-readiness D3 execution in an externally verified Metal-capable shell using the standing approval, or continue D3 environment recovery packet reuse / source-build guard rerun without consuming approval until the shell is Metal-capable`。

当前 blocker 状态：

- `automation_blocker=false_for_recovery_packet_reuse`
- `automation_blocker=true_for_d3_execution_in_current_shell`
- `requires_external_metal_capable_shell=true`
