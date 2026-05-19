# P1 Renderer Automation Stage Report 114

时间：2026-05-18T16:29:24+08:00

## 本轮工程单元

本轮完成 Renderer visible-window `NSApplication` shared-application runtime native-readiness D3 bounded result-envelope command-buffer commit no-present first-slice stage package。阶段目标是消费 stage113 draw-call positive suite packet，在 probe-local draw / endEncoding 后进入 command-buffer commit / bounded completion 分类，并继续保持 present、production render truth、renderer-state write、runtime_state 写入和 public C ABI 全部 blocked。

工程增量：

- 新增 internal owner：[runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice.cj)。
- 新增 owner probe：[verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_owner.sh)。
- 新增 bounded native commit no-present probe：[verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_command_buffer_commit_no_present_first_slice.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_command_buffer_commit_no_present_first_slice.sh)。
- 新增 packet / classifier / source-build guard / focused suite：
  [packet](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_packet.sh)，
  [classifier](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_classifier.sh)，
  [source-build guard](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_source_build_guard.sh)，
  [suite](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_suite.sh)。

Canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceDraft()`

## 能力闭环

Stage114 owner 固定了 draw-call readiness 到 command-buffer commit no-present first slice 的 contract：必须先消费 positive stage113 draw envelope，再允许 probe-local command buffer commit 和 bounded completion classification；仍不得 present，不得把 isolated GPU submission evidence 升级为 production render truth。

本轮实现了可复用的 bounded native commit probe：在 current-shell MTL device 可用时，它会创建 visible window / NSView / CAMetalLayer / drawable / command queue / command buffer / render pass / encoder / pipeline / vertex buffer，执行 draw、endEncoding、`commit`，用 completion handler + 2 秒 semaphore wait 分类 `bounded_gpu_submission_completed`，并确认 `present_called=false` / `drawable_presented=false`。

本轮当前 automation shell 出现 host capability 限制：系统硬件报告 Metal Supported，但同一 shell 中 native bridge metal-device probe 返回 `metal_default_device_available=-111`，stage113 direct draw probe 返回 `isolated_metal_device_available=false`，stage114 direct commit probe 也返回 `current_shell_commit_probe_isolated_metal_device_available=false` / `command_buffer_commit_no_present_first_slice_failure_classification=host_metal_device_unavailable`。这不是 CJGUI harness 缺口：probe 在 MTL device 之前失败，未进入 drawable / command queue / command buffer / commit 路径。

Fresh stage114 suite 生成 result envelope：

- Packet：`/tmp/cjgui-stage114-final-suite-check.FOVMrE/cjgui-stage114-command-buffer-commit-no-present-first-slice-suite/d3-bounded-result-envelope-command-buffer-commit-no-present-first-slice-suite.packet`
- `d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_suite_passed=true`
- `command_buffer_commit_no_present_first_slice_envelope_ready=true`
- `stage113_current_shell_draw_call_first_slice_ready=true`
- `stage113_bounded_draw_call_first_slice_executed=true`
- `stage113_draw_call_first_slice_failure_classification=none`
- `current_shell_commit_probe_isolated_metal_device_available=false`
- `bounded_commit_no_present_first_slice_should_execute=true`
- `bounded_command_buffer_commit_no_present_first_slice_executed=false`
- `current_shell_command_buffer_commit_no_present_first_slice_ready=false`
- `command_buffer_commit_no_present_first_slice_failure_classification=host_metal_device_unavailable`
- `command_buffer_commit_no_present_first_slice_classifier_route=host_metal_device_unavailable`
- `commit_called=false`
- `bounded_completion_wait_completed=false`
- `command_buffer_status_completed=false`
- `bounded_gpu_submission_completed=false`
- `gpu_work_submitted=false`
- `present_called=false`
- `drawable_presented=false`
- `production_gpu_submission=false`
- `production_render_truth=false`
- `renderer_state_write=false`
- `runtime_state_write=false`
- `native_bridge_expansion=false`
- `production_public_c_abi_added=false`

本轮执行了 bounded D3 runtime native probe first slice，但当前 shell 未取得 MTL device，因此未执行 command-buffer commit。Stage114 evidence 仍是 isolated probe / host classification evidence，不升级为 production truth / backend-ready truth。

## 验证结果

- TDD RED：stage114 owner probe 在 owner 缺失时按预期失败，exit 3。
- TDD GREEN：stage114 owner probe 通过。
- Bugfix：stage114 direct native probe 首次编译发现 Objective-C completion handler block 内修改局部变量缺少 `__block`；修复为 `__block int completion_handler_called` 后重新编译通过。
- Direct bounded commit no-present native probe：编译通过；当前 shell 返回 `isolated_metal_device_available=false`、`command_buffer_commit_no_present_first_slice_failure_domain=metal_device_unavailable`、exit 20。
- Host classification cross-check：
  - `system_profiler SPDisplaysDataType` 显示 Apple M5 Pro / Metal Supported。
  - `verify_native_bridge_metal_device_layer_binding.sh` 输出 `metal_default_device_available=-111` / `skipped_no_device`。
  - stage113 direct draw probe 输出 `isolated_metal_device_available=false` / `draw_call_first_slice_failure_domain=metal_device_unavailable`。
- Fresh stage114 focused suite：通过，route 为 `host_metal_device_unavailable`，packet 如上。
- Direct `cjpm build --target-dir <tmp>/target --skip-script`：通过，230 warnings generated / printed。新增 stage114 default draft 作为 internal owner-only endpoint 仍被 unused warning 覆盖。
- `git diff --check`：通过。
- Protected path scan：`runtime/cjgui/src/runtime_state.cj` 与 `runtime/cjgui/cjpm.toml` 未修改。
- Public / foreign scan：stage114 owner 未发现 public / foreign declaration；tracked `.cj` diff 未发现意外 public / foreign declaration。
- Forbidden owner token scan：stage114 owner 未发现 native / AppKit / render call token。
- Production native bridge diff scan：未发现 native bridge AppKit / Metal / C ABI 扩张。
- New stage114 files trailing whitespace / nonempty scan：通过。
- `runtime_state.cj` 行数：10065，未变化。
- GitNexus impact：
  - `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceReadiness`：target not found / UNKNOWN。
  - `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceReadiness`：target not found / UNKNOWN。
- GitNexus detect-changes：`Changes: 5 files, 3 symbols`，`Risk level: low`。Graph 仅覆盖 tracked docs 变化，未覆盖本轮 untracked stage114 owner / scripts / report；本轮未把 UNKNOWN 或未覆盖结果当作安全证明，已用源码读取、build、probe、protected/public/forbidden scans 兜底。

未 stage、未 commit、未 push。

## Stop-line

本轮只承认 stage114 command-buffer commit no-present envelope / classifier 已落地：

- `stage113_current_shell_draw_call_first_slice_ready=true`
- `current_shell_commit_probe_isolated_metal_device_available=false`
- `bounded_commit_no_present_first_slice_should_execute=true`
- `bounded_command_buffer_commit_no_present_first_slice_executed=false`
- `command_buffer_commit_no_present_first_slice_failure_classification=host_metal_device_unavailable`
- `commit_called=false`
- `bounded_gpu_submission_completed=false`
- `gpu_work_submitted=false`
- `present_called=false`
- `production_gpu_submission=false`
- `production_render_truth=false`
- `renderer_state_write=false`
- `result_envelope_promoted_to_production_truth=false`
- `backend_ready_truth=false`
- `native_bridge_expansion=false`
- `production_public_c_abi_added=false`

第一帧链路目前已有 source/probe package 覆盖到：`NSApplication -> NSWindow -> NSView -> CAMetalLayer -> MTLDevice -> drawable -> command queue -> command buffer -> render pass -> encoder -> pipeline -> vertex buffer -> draw -> commit no-present contract`。当前 shell 未能执行 commit positive path；剩余缺口是 Metal-capable shell 中正向跑通 command-buffer commit no-present completion、随后再进入 present / no-present 分支、bounded first-frame completion envelope、production write admission 与 renderer-state write admission。

## 下一段最值得推进

下一段建议在 Metal-capable shell 中重跑 stage114 focused suite，目标是让 `current_shell_command_buffer_commit_no_present_first_slice_ready=true`、`commit_called=true`、`bounded_completion_wait_completed=true`、`command_buffer_status_completed=true`、`bounded_gpu_submission_completed=true`、`gpu_work_submitted=true`，同时继续保持 `present_called=false`、`production_render_truth=false`、`renderer_state_write=false`。

建议 next opening：

`P1 Renderer visible-window NSApplication shared-application runtime native-readiness command-buffer commit no-present positive execution: rerun stage114 focused suite in a Metal-capable shell until bounded command-buffer commit completion is classified with commit_called=true and bounded_gpu_submission_completed=true, then implement the smallest present/no-present branch envelope while keeping production render truth / renderer-state write / public C ABI blocked.`
