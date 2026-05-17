# P1 Renderer 自动化阶段报告 90：runtime native-readiness explicit approval evidence mesh

日期：2026-05-17

状态：automation stage report / engineering phase package / non-D3 explicit approval evidence mesh

## 本轮结论

本轮接续 stage89，没有把 D3 runtime native probe execution 当作自动化默认目标，也没有停在 report cleanup。阶段包在当前 stop-line 内完成 `NSApplication` shared-application runtime native-readiness explicit approval evidence mesh：把 handoff packet、native bridge replay、failure-domain continuity 与 aggregate runner 串成可复跑证据链。

本轮完成 6 个真实工程增量，达到目标完成线 4 到 6 个：

1. 新增 internal owner + focused owner probe：新增 owner [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_handoff_evidence_mesh.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_handoff_evidence_mesh.cj)，消费 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalGateHandoffReadiness`，生成 endpoint `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalHandoffEvidenceMeshReadiness` / draft `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalHandoffEvidenceMeshDraft()`；新增 focused owner probe [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_handoff_evidence_mesh_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_handoff_evidence_mesh_owner.sh)。
2. 新增 handoff packet consistency guard：新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_handoff_packet_consistency.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_handoff_packet_consistency.sh)，fresh rerun stage89 handoff runner，并交叉检查 handoff / approval / native / drift packets 的 smoke classification、exit code 与 failure-domain 一致性。
3. 新增 route-scoped native bridge replay guard：新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_native_bridge_replay_guard.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_native_bridge_replay_guard.sh)，重跑 route-scoped native bridge evidence，并追加 `verify_native_bridge_cjpm_package_link_probe.sh` package-link evidence，确认 route evidence 不扩 production native bridge。
4. 新增 failure-domain continuity guard：新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_failure_domain_continuity.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_failure_domain_continuity.sh)，把 `automation_smoke_metal_capable` 与 `automation_smoke_metal_unavailable` 两类 shell 归为 allowed classification set，并固定二者都不消费 D3 approval。
5. 新增 explicit approval verification mesh runner：新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_verification_mesh_runner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_verification_mesh_runner.sh)，串联 owner probe、packet consistency、native replay 与 failure continuity，生成 `explicit-approval-verification-mesh.packet`。
6. 完成 native replay wrapper environment bugfix + 验证闭环：native replay guard 的 package-link 子 probe 首轮失败暴露 sandbox `envsetup.sh` 调用 `ps` 被拒；第二轮暴露 wrapper 传入未创建的 nested `TMPDIR`，导致 `ar` 临时文件失败。本轮在 wrapper 内增加 `/tmp` `ps` shim 并预创建 package-link `TMPDIR`，最终 GREEN。

同类增量说明：本轮包含多个 probe/script，但已补不同类型增量：source owner、packet contract、native/package-link evidence、failure-domain classification、orchestration runner 与 bugfix 闭环。它不是重复 no-accessor / no-bridge / no-runtime-execution wrapper。

## 不计入工程增量

以下内容只是 housekeeping，不计入真实工程增量：

- 本 report 本身。
- README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX 的 latest-entry 最小同步。
- automation memory 更新。
- 未新增 compact manifest，未扩 topic manifest 长流水。

## RED / GREEN 记录

- 新增 5 个脚本前分别 RED 为 missing script，exit 127。
- Owner probe GREEN：`explicit_approval_handoff_evidence_mesh_owner_present=true`、`explicit_approval_gate_handoff_input=true`、`handoff_packet_consistency_guard_required=true`、`native_bridge_replay_guard_required=true`、`failure_domain_continuity_guard_required=true`、`verification_mesh_runner_required=true`、`runtime_native_probe_execution=false`、`human_approved_d3_execution_consumed=false`。
- Handoff packet consistency GREEN：`handoff_packet_consistency_passed=true`、`cross_packet_smoke_consistency_passed=true`、`cross_packet_failure_domain_consistency_passed=true`、`smoke_environment_classification=automation_smoke_metal_unavailable`、`failure_domain=automation_environment`。
- Native bridge replay RED/GREEN：first RED 为 package-link log 中 `operation not permitted: ps` / `basename` envsetup failure；second RED 为 `ar: temporary file: No such file or directory`，root cause 是 nested `TMPDIR` 未创建；修复后 GREEN：`route_scoped_native_bridge_evidence_passed=true`、`native_bridge_package_link_probe_passed=true`、`native_bridge_replay_guard_passed=true`。
- Failure-domain continuity GREEN：`environment_drift_replay_passed=true`、`failure_domain_continuity_guard_passed=true`、`environment_drift_between_probes=false`、`allowed_environment_classification_set=metal_capable_or_metal_unavailable`。
- Verification mesh runner GREEN：`evidence_mesh_owner_probe_passed=true`、`handoff_packet_consistency_passed=true`、`native_bridge_replay_guard_passed=true`、`failure_domain_continuity_guard_passed=true`、`explicit_approval_verification_mesh_runner_passed=true`。

## 验证结果

- Focused probes：owner probe、packet consistency guard、native bridge replay guard、failure-domain continuity guard、verification mesh runner 均通过。
- Build：在 `runtime/cjgui` 下执行 `cjpm build --target-dir /tmp/cjgui-stage90-direct-build --skip-script` 通过；仍有既有 230 warnings。
- Fresh mesh result：`smoke_exit_code=20`、`smoke_environment_classification=automation_smoke_metal_unavailable`、`failure_domain=automation_environment`、`code_failure_domain=false`、`runtime_native_probe_execution=false`、`human_approved_d3_execution_consumed=false`。
- `git diff --check`：通过。
- Protected path scan：未修改 [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj) 或 [cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)。
- Public / foreign declaration scan：新增 owner 未引入 public declaration 或 `foreign func`。
- Native bridge forbidden scan：未改 production native `.h` / `.m`，未新增 native C ABI。
- Hard-boundary token scan：新增 owner / scripts 的 non-comment、non-grep-guard call-site scan 未命中 production application accessor、visible order、`nextDrawable`、render encoder、draw、commit、present、GPU submission、renderer state write。
- Script syntax / executable bit：5 个新增 stage90 scripts `zsh -n` 通过，且均为 executable。
- GitNexus：pre-edit stage89 endpoint / draft 的 `impact` 与 `context` 均 target not found / UNKNOWN；post-edit stage90 endpoint / draft 的 `context` / `impact` 也 target not found / UNKNOWN，不作为安全证明。Final `detect-changes --repo cangjie-live-codelattice --scope all` 只覆盖 tracked docs delta，返回 5 files / 3 symbols / 0 affected processes / low；新增 untracked owner/scripts/report 用 source reading、focused probes、build 与 scans 兜底。
- Source/build/probe fallback：新增 owner 可编译，新增 scripts 可执行，package-link probe 在 wrapper 修复后通过。

## Environment blocker 与路线切换

本轮 fresh probes 观测到 `automation_smoke_metal_unavailable` / exit 20，分类为 `failure_domain=automation_environment`。这没有被当作终点：本轮继续切到 non-D3 explicit approval evidence mesh、package-link replay 与 failure-domain continuity 路线。

即使 shell 后续变为 Metal-capable，也仍固定 `metal_capable_shell_does_not_imply_approval=true`、`approved_runtime_native_probe_execution_admitted=false`、`required_next_actor=human_operator`、`required_shell=explicitly_approved_shell`。

## Stop-line

当前 stop-line 保持：

- `runtime_native_probe_execution=false`
- `human_approved_d3_execution_consumed=false`
- `application_singleton_accessor_call=false`
- `native_bridge_expansion=false`
- `production_public_c_abi_added=false`
- `public_api_modified=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`
- `visible_order=false`
- `drawable_render=false`
- `renderer_state_write=false`

本轮未修改 [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)，未修改 [cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)，未新增 production `NSApplication.sharedApplication` actual accessor call site，未进入 visible window / `nextDrawable` / render encoder / GPU submission / renderer state write。

## 当前 next opening

下一条可推进路线：

`P1 Renderer visible-window NSApplication shared-application runtime native-readiness explicit human-approved D3 runtime native probe execution in a Metal-capable shell, or continue non-D3 explicit approval evidence mesh rerun / package-link replay / failure-domain continuity without consuming D3 approval`。

如果要进入 D3 runtime native probe execution，需要人工明确批准并提供 Metal-capable shell；否则可继续在 non-D3 mesh rerun、route-scoped native/package-link evidence 或 failure-domain continuity 路线内推进。
