# P1 Renderer Automation Stage Report 107

日期：2026-05-18

状态：automation report / continuous engineering stage package / D3 bounded drawable and render-pass color attachment readiness

## 本轮目标

本轮接续 stage106 `command queue / command buffer first-slice route`，把 Renderer visible-window 主线推进到 drawable / render-pass color attachment readiness。目标是让第一帧链路在 `MTLDevice -> command queue -> command buffer` first slice 已 admitted 后，明确停在 drawable texture lifetime、descriptor / drawable / layer / device cleanup coownership 和 color attachment configuration 之前；不写 renderer state，不提交 GPU work，不 present。

## GitNexus / CodeLattice 预检

- 使用 GitNexus repo `cangjie-live-codelattice`。
- GitNexus 对 planned stage107 endpoint `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentReadiness` 返回 symbol not found / `UNKNOWN`。
- GitNexus 对既有 `CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness` 也返回 symbol not found / `UNKNOWN`。
- 上述结果未作为安全证明；本轮用源码读取、RED/GREEN probes、focused suite、direct `cjpm build --skip-script`、protected path scan、public / foreign scan 与 production native bridge forbidden scan 兜底。
- Final GitNexus `detect-changes --repo cangjie-live-codelattice --scope all` 返回 6 tracked files / 3 symbols / 0 affected processes / low，但未覆盖新增 untracked stage107 owner/scripts/report；已用本轮 source/build/probe/scans 兜底。
- `/Users/jiangxuanyang/Desktop/codelattice/scripts/cangjie-production-alias-check.sh --status` 显示 live repo 为 `/Users/jiangxuanyang/Desktop/cangjie`，registry path 为 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui`，dirty=24，stable window 为 YELLOW；仅作状态记录。

## 真实工程增量

本轮完成 8 个真实工程增量：

1. Stage107 RED/GREEN owner probe
   - 先新增 owner probe 并确认因缺少 Cangjie owner 失败。
   - 补入 owner 后，owner probe 通过，固定 stage106 first-slice envelope -> drawable / render-pass color attachment readiness contract。

2. Drawable / render-pass color attachment readiness owner
   - 新 owner：[runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness.cj)。
   - Endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentDraft()`。
   - Runtime inputs：stage106 `CommandQueueCommandBufferFirstSliceReadiness` + existing `CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness`。

3. Stage107 readiness packet
   - 新 packet script：[verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_packet.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_packet.sh)。
   - Packet 支持外部提供 stage106 suite packet；未提供时，使用 stage106 owner + visible-window capability probe，并在当前 shell Metal 可用时直接执行 command queue / command buffer bounded first slice。
   - 本轮 current shell 输出 `isolated_metal_device_available=true`、`command_queue_probe_passed=true`、`command_buffer_probe_passed=true`、`bounded_command_queue_command_buffer_first_slice_executed=true`、`current_shell_first_slice_admitted=true`、`runtime_native_probe_execution=true`。

4. Drawable / color attachment failure classifier
   - 新 classifier 区分 host Metal unavailable、pending first-slice admission、pending drawable texture lifetime support。
   - 本轮分类为 `drawable_color_attachment_failure_classification=blocked_pending_drawable_texture_lifetime_support`。

5. Host-independent prerequisite probe integration
   - Packet 串联 `verify_native_bridge_render_pass_descriptor_create_destroy.sh`、`verify_native_bridge_drawable_acquisition_planning.sh`、`verify_native_bridge_drawable_texture_lifetime.sh`、`verify_native_bridge_render_pass_descriptor_color_attachment_recovery.sh`。
   - 验证 render-pass descriptor create/destroy、drawable acquisition still blocked、drawable texture lifetime planning-only、color attachment recovery-only 都为 GREEN。

6. Source/build guard
   - 新 source/build guard 验证 owner、packet、classifier、runtime package build、protected path scan、public / foreign scan、production native bridge forbidden diff scan。
   - 输出 `source_build_drawable_render_pass_color_attachment_readiness_guard_passed=true`、`runtime_package_build_passed=true`。

7. Focused suite
   - 新 suite：[verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_suite.sh)。
   - Fresh suite 统一输出 owner / packet / classifier / source-build packets，并固定 `d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_suite_passed=true`。

8. Legacy recursive suite drift containment
   - 初版 stage107 packet 复跑 stage106 suite 时，旧 stage100 -> stage98 嵌套链仍要求 `smoke_exit_code=20`，与当前 shell Metal-capable reality 冲突。
   - 本轮没有把该历史 drift 当作 blocker，也没有继续加固旧 recovery 链；改为让 stage107 支持 stage106 suite packet injection，同时默认使用 stage106 owner + visible-window capability + direct first-slice probes，保持 Renderer 主线推进。

## 验证结果

- RED：stage107 owner probe 首次失败于 missing owner。
- GREEN：stage107 owner probe 通过。
- GREEN：stage107 packet 通过，输出 `stage106_first_slice_input_mode=direct_owner_visible_window_probe`、`stage106_first_slice_contract_input_ready=true`、`isolated_metal_device_available=true`、`bounded_command_queue_command_buffer_first_slice_executed=true`、`current_shell_first_slice_admitted=true`、`runtime_native_probe_execution=true`。
- GREEN：stage107 classifier 通过，输出 `current_shell_drawable_color_attachment_native_execution_ready=false`、`drawable_color_attachment_failure_classification=blocked_pending_drawable_texture_lifetime_support`。
- GREEN：stage107 source/build guard 通过。
- GREEN：stage107 focused suite 通过，输出 `d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_suite_passed=true`、`production_drawable_texture_lifetime=false`、`descriptor_drawable_cleanup_coownership=false`、`next_drawable_called=false`、`color_attachment_configured=false`、`encoder_created=false`、`draw_called=false`、`commit_called=false`、`present_called=false`、`gpu_work_submitted=false`、`render_executed=false`、`renderer_state_write=false`。
- Direct `cjpm build --target-dir /tmp/cjgui-stage107-final-direct-build/target --skip-script`：通过，仍有既有 230 warnings。
- `git diff --check`：通过。
- Protected path scan：`runtime/cjgui/src/runtime_state.cj`、`runtime/cjgui/cjpm.toml` 未修改。
- Public / foreign scan：stage107 owner 未发现意外 public / foreign declaration。
- Production native bridge forbidden diff scan：无命中，未改 `cjgui_native_bridge.h/.m`。
- Script executable / final newline：stage107 5 个新增脚本通过。
- `runtime_state.cj` 行数：10065，未变化。

## Stop-line

- `isolated_metal_device_available=true`
- `bounded_command_queue_command_buffer_first_slice_executed=true`
- `current_shell_first_slice_admitted=true`
- `first_slice_failure_classification=none`
- `current_shell_drawable_color_attachment_native_execution_ready=false`
- `drawable_color_attachment_failure_classification=blocked_pending_drawable_texture_lifetime_support`
- `production_drawable_texture_lifetime=false`
- `production_drawable_acquire_callable=false`
- `descriptor_drawable_cleanup_coownership=false`
- `next_drawable_called=false`
- `color_attachment_configured=false`
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

当前链路已经在本 shell 真实走到 visible-window / Metal device / command queue / command buffer first slice admitted。下一段缺口不是宿主 Metal，而是 CJGUI harness / native runtime 能力：需要 token-backed drawable acquisition、drawable texture lifetime ownership、descriptor / drawable / layer / device cleanup coownership，然后才能配置 `colorAttachments[0]`。之后仍需 render command encoder、pipeline state binding、vertex buffer、draw、commit/present、bounded result envelope、production write admission、renderer-state write admission。

## 当前 next route

当前 canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentDraft()`

下一条最值得推进的工程目标：

`P1 Renderer visible-window NSApplication shared-application runtime native-readiness drawable texture lifetime first slice: implement the smallest token-backed drawable acquisition / drawable texture lifetime readiness owner and bounded probe that can feed render-pass descriptor color attachment configuration later, while keeping present / encoder / draw / commit / GPU submission / renderer-state write blocked.`

当前 blocker 状态：

- `automation_blocker=false_for_stage107_drawable_render_pass_color_attachment_readiness`
- `automation_blocker=false_for_current_shell_command_queue_command_buffer_first_slice`
- `automation_blocker=true_for_color_attachment_configuration_until_drawable_texture_lifetime_and_cleanup_coownership_are_implemented`
- `renderer_state_write_blocked=true`
