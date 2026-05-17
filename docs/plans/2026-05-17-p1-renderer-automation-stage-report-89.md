# P1 Renderer 自动化阶段报告 89：runtime native-readiness explicit approval gate handoff

日期：2026-05-17

状态：automation stage report / engineering phase package / non-D3 explicit approval handoff

## 本轮结论

本轮没有把 `next opening` 当作单点终点，而是在不跨 D3 runtime native probe execution 硬边界的前提下，完成 `NSApplication` shared-application runtime native-readiness explicit approval gate handoff 阶段包。

本轮完成 6 个真实工程增量，达到目标完成线 4 到 6 个：

1. 新增 internal owner + focused owner probe：新增 owner [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_gate_handoff.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_gate_handoff.cj)，消费 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeNonD3RerunMaintenanceReadiness`，生成 endpoint `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalGateHandoffReadiness` / draft `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalGateHandoffDraft()`；新增 focused owner probe [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_gate_handoff_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_gate_handoff_owner.sh)。
2. 新增 explicit approval gate packet / handoff contract：新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_gate_packet.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_gate_packet.sh)，重跑 stage88 maintenance aggregate guard，生成 approval gate packet，并拒绝把 `CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED=true` 当作自动化默认通行证。
3. 新增 route-scoped native bridge evidence route：新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_route_scoped_native_bridge_evidence.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_route_scoped_native_bridge_evidence.sh)，把 approval gate、native skeleton compile、no-resource symbol probe 串成 route-scoped native evidence，不扩 native bridge。
4. 新增 environment drift replay / failure-domain classification 后续路线：新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_environment_drift_replay.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_environment_drift_replay.sh)，对比 approval gate 与 external capability detector 的 smoke classification，确认环境能力漂移与 D3 approval 是两个不同事实。
5. 新增 explicit approval handoff orchestration runner：新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_handoff_runner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_handoff_runner.sh)，聚合 owner probe、approval packet、route-scoped native evidence、environment drift replay，输出 handoff packet。
6. 完成 probe orchestration runner bugfix + 验证闭环：runner 初始 GREEN 前暴露 nested high-frequency rerun 使用固定 `${TMPDIR}/cjgui-*` 目录导致 child packet/log 被复用或覆盖；本轮在新增脚本内部给 nested child probes 分配独立 `TMPDIR`，完成 RED/GREEN 闭环。

同类增量说明：本轮包含多个 probe/script，但不是同构 no-accessor / no-bridge / no-runtime-execution wrapper。除 owner/probe 外，还补了 handoff contract、route-scoped native evidence、environment drift replay、orchestration runner 和 failure-domain bugfix，满足“若同类过多需补不同类型增量”的要求。

## 不计入工程增量

以下内容只是 housekeeping，不计入真实工程增量：

- 本 report 本身。
- README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX 的 latest-entry 最小同步。
- automation memory 更新。
- 未新增 compact manifest，未扩 topic manifest 长流水。

## RED / GREEN 记录

- 新增 5 个脚本前分别 RED 为 missing script，exit 127。
- 新增脚本后 `zsh -n` 均通过。
- Owner probe GREEN：`explicit_approval_gate_handoff_owner_present=true`、`non_d3_rerun_maintenance_input=true`、`explicit_approval_gate_packet_required=true`、`route_scoped_native_bridge_evidence_required=true`、`environment_drift_replay_required=true`、`runtime_native_probe_execution=false`、`human_approved_d3_execution_consumed=false`、`same_shape_no_accessor_wrapper=false`。
- Approval gate packet GREEN：`route_classification=runtime_native_probe_explicit_approval_gate_packet`、`aggregate_guard_passed=true`、`approval_packet_created=true`、`smoke_exit_code=20`、`smoke_environment_classification=automation_smoke_metal_unavailable`、`failure_domain=automation_environment`、`d3_runtime_native_probe_approval_required=true`、`approved_runtime_native_probe_execution_admitted=false`。
- Route-scoped native bridge evidence GREEN：`native_skeleton_compile_passed=true`、`native_no_resource_symbols_passed=true`、`route_scoped_native_bridge_evidence_passed=true`。
- Environment drift replay GREEN：`environment_drift_replay_passed=true`、`environment_drift_between_probes=false`、`metal_capable_shell_does_not_imply_approval=true`。
- Explicit approval handoff runner 最终 GREEN：`explicit_approval_handoff_runner_passed=true`、`handoff_packet_path=.../explicit-approval-handoff-runner.packet`、`required_next_actor=human_operator`、`required_shell=explicitly_approved_shell`、`runtime_native_probe_execution=false`、`human_approved_d3_execution_consumed=false`。

## 验证结果

- Focused probes：owner probe、approval gate packet、route-scoped native bridge evidence、environment drift replay、explicit approval handoff runner 均通过。
- Build：在 `runtime/cjgui` 下执行 `cjpm build --target-dir /tmp/cjgui-stage89-direct-build --skip-script` 通过；仍有既有 unused warnings。
- `git diff --check`：通过。
- Protected path scan：未修改 [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj) 或 [cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)。
- Public / foreign declaration scan：新增 owner 未引入 public declaration 或 `foreign func`。
- Native bridge forbidden scan：未改 production native `.h` / `.m`，未新增 native C ABI。
- Hard-boundary token scan：新增 owner 未包含 production `NSApplication.sharedApplication` actual accessor call site、visible order、`nextDrawable`、render encoder、draw、commit、present、GPU submission、renderer state write。
- Executable bit check：5 个新增 script 均为 executable。
- GitNexus：pre-edit 和 post-edit 对 stage88 / stage89 endpoint 与 draft 的 `context` / `impact` 均 target not found 或 UNKNOWN，不作为安全证明；final `detect-changes --repo cangjie-live-codelattice --scope all` 只覆盖 tracked docs 变化，返回 low risk / 0 affected processes。新增 untracked owner/scripts/report 以 source reading、focused probes、build 与 scans 兜底。

## Environment blocker 与路线切换

本轮 fresh runner 重新观测到 `automation_smoke_metal_unavailable` / exit 20，分类为 `failure_domain=automation_environment`。这没有被当作终点：路线切换为 non-D3 explicit approval handoff、route-scoped native evidence 与 environment drift replay，继续在 stop-line 内推进。

即使外部 shell 显示 Metal-capable，也不等于 D3 runtime native probe execution 已获人工批准。本轮固定 `metal_capable_shell_does_not_imply_approval=true` 与 `approved_runtime_native_probe_execution_admitted=false`。

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

`P1 Renderer visible-window NSApplication shared-application runtime native-readiness explicit human-approved D3 runtime native probe execution in a Metal-capable shell, or continue non-D3 explicit approval handoff / route-scoped native evidence rerun without consuming D3 approval`。

如果要进入 D3 runtime native probe execution，需要人工明确批准并提供 Metal-capable shell；否则可继续在 non-D3 handoff / native evidence rerun / environment drift replay 路线内推进。
