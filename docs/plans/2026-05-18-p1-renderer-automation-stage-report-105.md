# P1 Renderer Automation Stage Report 105

日期：2026-05-18

状态：automation report / continuous engineering stage package / D3 bounded result-envelope command-pipeline readiness envelope

## 本轮目标

本轮接续 stage104 `D3 bounded result-envelope admission to renderer-state write-decision join preflight`，把 Renderer visible-window 主线从 write-decision join 推进到 command-pipeline readiness envelope。目标不是继续证明 approval / external packet / guard，而是把第一帧链路中 `NSApplication -> NSWindow -> NSView -> CAMetalLayer -> MTLDevice -> drawable -> command queue / buffer -> render pass -> encoder -> pipeline -> vertex buffer -> draw -> commit / present` 的下一段输入合同拆清楚，并给后续 Metal-capable shell 的 bounded command-pipeline first slice 留出可复用 packet。

当前 shell 的 AppKit visible-window harness 已经能创建 isolated window、visible view、CAMetalLayer、bounded run loop 并完成 cleanup；但 `MTLCreateSystemDefaultDevice()` 返回 nil，visible-window environment probe 分类为 `metal_device_unavailable`。因此本轮没有执行 command queue / command buffer / draw / present，也没有写 renderer state；本轮把该情况分类为当前宿主 Metal device unavailable，同时继续推进 host-independent command-pipeline probes、packet、classifier、source/build guard 与 focused suite。

## GitNexus / CodeLattice 预检

- GitNexus repo 使用 `cangjie-live-codelattice`。
- GitNexus MCP / Tool CLI 对 stage104 join endpoint 与 planned stage105 command-pipeline readiness endpoint 返回 symbol not found / `UNKNOWN` / 0 impacted；未作为安全证明。
- CodeLattice 在 runtime/cjgui live root 对 planned stage105 endpoint 返回 low / 0 callers；全仓 root 曾返回 `path_denied`。
- Final GitNexus MCP / CLI `detect-changes --repo cangjie-live-codelattice --scope all` 均未覆盖本轮所有 worktree / untracked 变更，因此只作为辅助证据；源码读取、RED/GREEN probes、direct build、protected scan、public / foreign scan 与 forbidden native bridge scan 是本轮主验证。

## 真实工程增量

本轮完成 8 个真实工程增量：

1. Current-shell visible-window / Metal capability classification
   - Fresh visible-window environment probe 输出 `isolated_window_created=true`、`isolated_window_visible_observed=true`、`isolated_view_attached_observed=true`、`isolated_cametallayer_attached_observed=true`、`bounded_run_loop_observed=true`、`cleanup_observed=true`、`isolated_metal_device_available=false`、`visible_window_environment_failure_domain=metal_device_unavailable`。
   - 结论：当前不是 AppKit harness 缺口；当前 shell 的 command-pipeline native execution 被 Metal device unavailable 阻断。

2. Stage105 RED probes
   - stage105 owner / packet / classifier / source-build / suite 在修复前出现 missing / non-executable / packet failure path，确认本轮不是纯文档推进。

3. Command-pipeline readiness owner activation
   - 固定 endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineReadinessDraft()`。
   - Runtime input：stage104 bounded result-envelope renderer-state write-decision join readiness。
   - Stop-line：不执行 native command pipeline，不写 renderer state，不扩 public API / public C ABI / native bridge，不修改 `runtime_state.cj` / `cjpm.toml`。

4. Stage105 packet child `TMPDIR` bugfix
   - Packet script 原先把 child probes 的 `TMPDIR` 指到尚不存在的子目录，导致 render-pass descriptor probe 的 `mktemp -d "$TMPDIR/..."` 报错。
   - 已预创建 `visible-window`、`render-pass`、`pipeline-descriptor`、`drawable-texture`、`draw-call` 子目录，避免把环境隔离 bug 误分类为 native probe failure。

5. Host-independent command-pipeline probes replay
   - Packet 串联并验证 render-pass descriptor create/destroy、pipeline descriptor configuration、drawable texture lifetime stop-line、draw-call still-blocked probe。
   - 输出 `command_pipeline_host_independent_probes_ready=true`，但仍保持 `next_drawable_called=false`、`draw_called=false`、`commit_called=false`、`present_called=false`、`gpu_work_submitted=false`。

6. Command-pipeline readiness packet
   - Packet 消费 stage104 join suite packet，重跑 visible-window environment probe，并把 AppKit harness readiness、Metal device readiness 与 command-pipeline host-independent readiness 分离。
   - Fresh packet 输出 `visible_window_appkit_harness_ready=true`、`host_metal_unavailable_classified=true`、`command_pipeline_readiness_envelope_ready=true`、`current_shell_command_pipeline_native_execution_ready=false`、`renderer_state_write=false`。

7. Command-pipeline classifier
   - Classifier 将当前 shell 分类为 `host_metal_device_unavailable`，同时确认 `command_pipeline_readiness_envelope_ready=true` 与 `current_shell_command_pipeline_native_execution_ready=false`。
   - 该分类只对当前 automation shell 生效，不升级 production backend-ready truth。

8. Source/build guard 与 focused suite
   - Source/build guard 串联 owner、packet、classifier、`cjpm build --skip-script`、protected path scan、public / foreign scan、forbidden native bridge scan。
   - 新增 focused suite，输出统一 suite packet，作为后续 Metal-capable command queue / command buffer first slice 的 canonical input。

Housekeeping 不计入上述真实工程增量：本 report、latest-entry 文档同步、automation memory 更新。

## 验证结果

- RED：stage105 packet 首次运行失败于 child `TMPDIR` 未预创建；standalone render-pass descriptor probe 通过，定位为 packet isolation bug。
- GREEN：stage105 owner probe 通过。
- GREEN：stage105 packet 通过，输出 `visible_window_appkit_harness_ready=true`、`isolated_metal_device_available=false`、`host_metal_unavailable_classified=true`、`command_pipeline_readiness_envelope_ready=true`、`current_shell_command_pipeline_native_execution_ready=false`、`renderer_state_write=false`。
- GREEN：stage105 classifier 通过，输出 `current_shell_failure_classification=host_metal_device_unavailable`。
- GREEN：stage105 source/build guard 通过，输出 `runtime_package_build_passed=true`、`source_build_command_pipeline_readiness_guard_passed=true`。
- GREEN：stage105 focused suite 通过，输出 `d3_bounded_result_envelope_command_pipeline_readiness_suite_passed=true`、`visible_window_appkit_harness_ready=true`、`isolated_metal_device_available=false`、`current_shell_failure_classification=host_metal_device_unavailable`、`command_pipeline_readiness_envelope_ready=true`、`current_shell_command_pipeline_native_execution_ready=false`、`renderer_state_write=false`。
- `zsh -n`：stage105 scripts 通过。
- Direct `cjpm build --target-dir /tmp/cjgui-stage105-final-direct-build-shim/target --skip-script`：通过，仍有既有 230 warnings。
- `git diff --check`：通过。
- Protected path scan：`runtime/cjgui/src/runtime_state.cj`、`runtime/cjgui/cjpm.toml` 未修改。
- `runtime_state.cj` 行数：10065，未变化。
- Public / foreign scan：未发现意外 public / foreign declaration。
- Production native bridge forbidden diff scan：无命中，未改 `cjgui_native_bridge.h/.m`。
- GitNexus MCP / CLI `detect-changes --repo cangjie-live-codelattice --scope all` 未覆盖本轮所有 worktree / untracked 变更；已用 source/build/probe/scans 兜底。

## Stop-line

- `visible_window_appkit_harness_ready=true`
- `isolated_metal_device_available=false`
- `visible_window_environment_failure_domain=metal_device_unavailable`
- `current_shell_failure_classification=host_metal_device_unavailable`
- `cjgui_harness_gap_detected=false`
- `command_pipeline_host_independent_probes_ready=true`
- `command_pipeline_readiness_envelope_ready=true`
- `current_shell_command_pipeline_native_execution_ready=false`
- `bounded_d3_command_pipeline_should_execute=false`
- `runtime_native_probe_execution=false`
- `next_drawable_called=false`
- `command_queue_created_by_stage=false`
- `command_buffer_created_by_stage=false`
- `encoder_created=false`
- `draw_called=false`
- `commit_called=false`
- `present_called=false`
- `gpu_work_submitted=false`
- `render_executed=false`
- `result_envelope_promoted_to_production_truth=false`
- `backend_ready_truth=false`
- `production_write_admission_before_renderer_state_write_required=true`
- `renderer_state_write=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`
- `native_bridge_expansion=false`
- `production_public_c_abi_added=false`

## 第一帧链路剩余缺口

当前已经验证 AppKit visible-window harness 和 CAMetalLayer attachment；当前 shell 缺口是可用 `MTLDevice`。第一帧链路剩余需要在 Metal-capable shell 中继续验证：layer.device binding、drawable readiness / `nextDrawable`、command queue、command buffer、render pass color attachment、encoder、pipeline state、vertex buffer、draw、commit、present、bounded result envelope、production write admission、renderer-state write admission。

## 当前 next route

当前 canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineReadinessDraft()`

下一条最值得推进的工程目标：

`P1 Renderer visible-window NSApplication shared-application runtime native-readiness command-pipeline readiness to Metal-capable command queue / command buffer execution first slice: when the shell has a Metal device, consume the stage105 readiness envelope and run a bounded command queue / command buffer first slice; while current shell remains Metal unavailable, continue the host-independent drawable / encoder / pipeline attachment contract without renderer-state write.`

当前 blocker 状态：

- `automation_blocker=false_for_stage105_command_pipeline_readiness_envelope`
- `automation_blocker=true_for_current_shell_command_pipeline_native_execution_without_metal_device`
- `automation_blocker=true_for_renderer_state_write_without_production_write_admission`
- `renderer_state_write_blocked=true`
