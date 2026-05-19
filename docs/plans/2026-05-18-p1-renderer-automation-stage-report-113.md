# P1 Renderer Automation Stage Report 113

时间：2026-05-18T15:40:52+08:00

## 本轮工程单元

本轮完成 Renderer visible-window `NSApplication` shared-application runtime native-readiness D3 bounded result-envelope draw-call first-slice stage package。阶段目标是消费 stage112 pipeline-state / static triangle vertex-buffer binding positive envelope，在同一 isolated native probe 中调用 probe-local `drawPrimitives`，然后在 `commit` / `present` / GPU submission / render execution / renderer-state write 前停住。

工程增量：

- 新增 internal owner：[runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_first_slice.cj)。
- 新增 owner probe：[verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_first_slice_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_first_slice_owner.sh)。
- 新增 bounded native draw-call probe：[verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_draw_call_first_slice.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_draw_call_first_slice.sh)。
- 新增 packet / classifier / source-build guard / focused suite：
  [packet](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_first_slice_packet.sh)，
  [classifier](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_first_slice_classifier.sh)，
  [source-build guard](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_first_slice_source_build_guard.sh)，
  [suite](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_first_slice_suite.sh)。

Canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceDraft()`

## 能力闭环

Stage112 在本轮当前 shell 重新正向执行，确认 `current_shell_pipeline_vertex_binding_first_slice_ready=true`、`pipeline_state_bound=true`、`vertex_buffer_bound=true`，因此 stage113 允许进入 draw-call first slice。

Stage113 focused suite 生成 result envelope：

- Packet：`/tmp/cjgui-stage113-suite-check/cjgui-stage113-draw-call-first-slice-suite/d3-bounded-result-envelope-draw-call-first-slice-suite.packet`
- `d3_bounded_result_envelope_draw_call_first_slice_suite_passed=true`
- `isolated_metal_device_available=true`
- `stage112_current_shell_pipeline_vertex_binding_first_slice_ready=true`
- `stage112_bounded_pipeline_vertex_binding_first_slice_executed=true`
- `bounded_draw_call_first_slice_should_execute=true`
- `bounded_draw_call_first_slice_executed=true`
- `current_shell_draw_call_first_slice_ready=true`
- `draw_call_first_slice_failure_classification=none`
- `draw_call_first_slice_classifier_route=admitted_bounded_draw_call_first_slice`
- `render_command_encoder_created=true`
- `end_encoding_called=true`
- `pipeline_state_bound=true`
- `vertex_buffer_bound=true`
- `draw_called=true`
- `production_draw_call=false`
- `commit_called=false`
- `present_called=false`
- `gpu_work_submitted=false`
- `render_executed=false`
- `renderer_state_write=false`
- `runtime_state_write=false`
- `native_bridge_expansion=false`
- `production_public_c_abi_added=false`

本轮执行了 bounded D3 runtime native probe first slice；当前 shell Metal-capable，未遇到 CJGUI harness 缺口或宿主限制。Stage113 evidence 仍是 isolated probe evidence，不升级为 production truth / backend-ready truth。

## 验证结果

- TDD RED：stage113 owner probe 在 owner 缺失时按预期失败。
- TDD GREEN：stage113 owner probe 通过。
- GREEN：stage112 focused suite 在当前 shell 正向 rerun，输出 `isolated_metal_device_available=true`、`current_shell_pipeline_vertex_binding_first_slice_ready=true`、`pipeline_state_bound=true`、`vertex_buffer_bound=true`。
- GREEN：direct bounded draw-call native probe 通过，输出 `draw_called=true`、`commit_called=false`、`present_called=false`、`gpu_work_submitted=false`、`render_executed=false`、`cleanup_observed=true`、`bridge_table_counts_clean=true`。
- GREEN：stage113 packet / classifier / source-build guard / focused suite 均通过。
- Direct `cjpm build --target-dir /tmp/cjgui-stage113-final-direct-build/target --skip-script`：通过，230 warnings generated / printed。新增 stage113 default draft 作为 internal owner-only endpoint 仍被 unused warning 覆盖。
- `git diff --check`：通过。
- Protected path scan：`runtime/cjgui/src/runtime_state.cj` 与 `runtime/cjgui/cjpm.toml` 未修改。
- Public / foreign scan：stage113 owner 未发现 public / foreign declaration；tracked `.cj` diff 未发现意外 public / foreign declaration。
- Forbidden owner token scan：stage113 owner 未发现 native / AppKit / render call token。
- Production native bridge diff scan：未发现 native bridge AppKit / Metal / C ABI 扩张。
- `runtime_state.cj` 行数：10065，未变化。
- GitNexus impact：
  - `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingFirstSliceReadiness`：target not found / UNKNOWN。
  - `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallFirstSliceReadiness`：target not found / UNKNOWN。
- GitNexus detect-changes：`Changes: 5 files, 3 symbols`，`Risk level: low`。Graph 仅覆盖 tracked docs 变化，未覆盖本轮 untracked stage113 owner / scripts / report；本轮未把 UNKNOWN 或未覆盖结果当作安全证明，已用源码读取、build、probe、protected/public/forbidden scans 兜底。
- Alias status：`Dirty: 29 total`，`Stable window: YELLOW`，readonly analyze / MCP OK。

未 stage、未 commit、未 push。

## Stop-line

本轮只承认 probe-local draw-call encoding 已完成：

- `draw_called=true`
- `production_draw_call=false`
- `commit_called=false`
- `present_called=false`
- `gpu_work_submitted=false`
- `render_executed=false`
- `renderer_state_write=false`
- `result_envelope_promoted_to_production_truth=false`
- `backend_ready_truth=false`
- `native_bridge_expansion=false`
- `production_public_c_abi_added=false`

第一帧链路现在已经走到：`NSApplication -> NSWindow -> NSView -> CAMetalLayer -> MTLDevice -> drawable -> command queue -> command buffer -> render pass -> encoder -> pipeline -> vertex buffer -> draw` 的 isolated bounded probe-local first slice。剩余缺口是 command buffer commit、present / no-present 分支、bounded GPU submission completion envelope、production write admission 与 renderer-state write admission。

## 下一段最值得推进

下一段建议推进 `command-buffer commit no-present first slice`：消费 stage113 suite packet，在 probe-local draw 后执行 bounded command-buffer commit，并用 completion / wait envelope 分类 GPU submission readiness；仍禁止 present、production render truth、renderer-state write、runtime_state 写入和 public C ABI 扩张。

建议 next opening：

`P1 Renderer visible-window NSApplication shared-application runtime native-readiness command-buffer commit no-present first slice: consume the stage113 draw-call suite packet, commit the probe-local command buffer after draw without present, classify bounded GPU submission completion, and keep present / production render truth / renderer-state write / public C ABI blocked.`
