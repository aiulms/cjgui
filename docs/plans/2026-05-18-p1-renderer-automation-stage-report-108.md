# P1 Renderer Automation Stage Report 108

日期：2026-05-18

状态：automation report / continuous engineering stage package / D3 bounded drawable texture lifetime first slice

## 本轮目标

本轮接续 stage107 `drawable / render-pass color attachment readiness`，把 Renderer visible-window 主线推进到 bounded isolated drawable texture lifetime first slice。目标是补上第一帧链路中 `CAMetalLayer -> nextDrawable -> drawable.texture` 的 probe-local token / texture observation envelope，让后续 render-pass color attachment configuration 可以消费明确的 lifetime 前置证据；本阶段仍不 present、不创建 encoder、不 draw / commit、不提交 GPU work、不写 renderer state、不扩 production native bridge C ABI。

## GitNexus / CodeLattice 预检

- 使用 GitNexus repo `cangjie-live-codelattice`。
- GitNexus 对 stage107 endpoint `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableRenderPassColorAttachmentReadiness` 返回 symbol not found / `UNKNOWN`。
- GitNexus 对既有 `CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness` 返回 symbol not found / `UNKNOWN`。
- CodeLattice 对 `cjguiInternalExecuteDefaultRendererDrawableTextureLifetimePlanningDraft` 的 upstream impact preview 为 `LOW`、0 callers；对 readiness struct 名称返回 ambiguous；未当作完整安全证明。
- Final GitNexus `detect-changes --repo cangjie-live-codelattice --scope all` 返回 6 tracked files / 3 symbols / 0 affected processes / low，但未覆盖新增 untracked stage108 owner/scripts/report；已用本轮 source/build/probe/scans 兜底。
- CodeLattice `changed_symbols` 指向 live repo root 时返回 `path_denied`；runtime/cjgui root 又不是 git repo，故未覆盖最终 diff。
- `/Users/jiangxuanyang/Desktop/codelattice/scripts/cangjie-production-alias-check.sh --status` 显示 dirty=32、stable window YELLOW；仅作状态记录。

## 真实工程增量

本轮完成 7 个真实工程增量：

1. Stage108 RED/GREEN suite gap
   - RED：source-build guard 与 focused suite 首次执行失败于 missing script / exit 127。
   - GREEN：补齐 source-build guard 与 suite 后，完整 stage108 suite 通过。

2. Drawable texture lifetime first-slice owner
   - Owner：[runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_texture_lifetime_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_texture_lifetime_first_slice.cj)。
   - Endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceDraft()`。
   - Runtime inputs：stage107 `DrawableRenderPassColorAttachmentReadiness` + existing `CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness`。

3. Bounded isolated drawable native first-slice probe
   - Probe：[verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_drawable_texture_lifetime_first_slice.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_drawable_texture_lifetime_first_slice.sh)。
   - Probe 在隔离 visible-window harness 内调用一次 `CAMetalLayer.nextDrawable`，只记录 probe-local drawable token、drawable texture width/height、release/cleanup facts。
   - Stop-line：不 present、不配置 color attachment、不创建 encoder、不 draw / commit、不提交 GPU work，不写 production table，不改 production bridge。

4. Stage108 readiness packet
   - Packet：[verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_texture_lifetime_first_slice_packet.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_texture_lifetime_first_slice_packet.sh)。
   - Packet 消费 stage107 readiness packet；只有 `current_shell_first_slice_admitted=true` 且 `isolated_metal_device_available=true` 时才执行 bounded drawable probe。
   - 本轮当前 shell 输出 `isolated_metal_device_available=false`、`current_shell_first_slice_admitted=false`，因此没有执行 `nextDrawable`。

5. Failure classifier
   - Classifier：[verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_texture_lifetime_first_slice_classifier.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_texture_lifetime_first_slice_classifier.sh)。
   - 本轮分类为 `drawable_texture_lifetime_classifier_route=host_metal_device_unavailable`，没有把宿主 Metal device 不可用误判为 CJGUI harness gap。

6. Source/build guard
   - 新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_texture_lifetime_first_slice_source_build_guard.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_texture_lifetime_first_slice_source_build_guard.sh)。
   - 绑定 owner、packet、classifier、runtime package build、protected path scan、public / foreign scan、production native bridge forbidden diff scan。
   - 输出 `source_build_drawable_texture_lifetime_first_slice_guard_passed=true`、`runtime_package_build_passed=true`。

7. Focused suite
   - 新增 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_texture_lifetime_first_slice_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_texture_lifetime_first_slice_suite.sh)。
   - Suite 串联 owner -> packet -> classifier -> source-build guard，输出可交接 suite packet。
   - Fresh suite 固定 `d3_bounded_result_envelope_drawable_texture_lifetime_first_slice_suite_passed=true`。

## 验证结果

- RED：planned stage108 source-build guard / suite 缺失，exit 127。
- GREEN：stage108 owner probe 通过。
- GREEN：stage108 packet 通过，输出 `drawable_texture_lifetime_failure_classification=host_metal_device_unavailable`、`renderer_state_write=false`。
- GREEN：stage108 classifier 通过，输出 `route_classification=host_metal_device_unavailable`、`renderer_state_write=false`。
- GREEN：stage108 source-build guard 通过，内部 `cjpm build --skip-script` 通过。
- GREEN：stage108 focused suite 通过，输出 `d3_bounded_result_envelope_drawable_texture_lifetime_first_slice_suite_passed=true`、`bounded_drawable_texture_lifetime_first_slice_executed=false`、`drawable_texture_lifetime_failure_classification=host_metal_device_unavailable`、`renderer_state_write=false`。
- Direct `cjpm build --target-dir /tmp/cjgui-stage108-final-direct-build/target --skip-script`：通过，仍有既有 230 warnings。
- `git diff --check`：通过。
- Protected path scan：`runtime/cjgui/src/runtime_state.cj`、`runtime/cjgui/cjpm.toml` 未修改。
- Public / foreign scan：stage108 owner/scripts 未发现意外 public / foreign declaration。
- Production native bridge forbidden diff scan：无命中，未改 `cjgui_native_bridge.h/.m`。
- Owner forbidden token scan：stage108 owner 非注释代码未包含 AppKit / Metal runtime call token。
- New stage108 scripts executable bit：通过。
- `runtime_state.cj` 行数：10065，未变化。

## Bounded D3 / 环境分类

- 本轮当前 shell 没有执行 bounded drawable native first slice，因为 stage108 packet 消费到的 stage107 path 给出 `isolated_metal_device_available=false`、`current_shell_first_slice_admitted=false`、`first_slice_failure_classification=host_metal_device_unavailable`。
- 该分类有明确 packet 证据；本轮没有把 `Metal unavailable` 直接归因到宿主，也没有把它当作终点，而是完成了可复用的 owner / native first-slice probe / packet / classifier / source-build / suite 闭环。
- 若在 Metal-capable shell 重跑 suite，stage108 packet 会执行 isolated `nextDrawable` first slice，并产出 `drawable_acquired`、`probe_local_drawable_token_*`、`drawable_texture_observed`、texture size 与 cleanup facts。

## Stop-line

- `isolated_metal_device_available=false`
- `current_shell_first_slice_admitted=false`
- `bounded_drawable_texture_lifetime_first_slice_should_execute=false`
- `bounded_drawable_texture_lifetime_first_slice_executed=false`
- `current_shell_drawable_texture_lifetime_first_slice_ready=false`
- `drawable_texture_lifetime_failure_classification=host_metal_device_unavailable`
- `next_drawable_called=false`
- `drawable_acquired=false`
- `drawable_texture_observed=false`
- `current_shell_color_attachment_native_execution_ready=false`
- `color_attachment_configured=false`
- `encoder_created=false`
- `draw_called=false`
- `commit_called=false`
- `present_called=false`
- `gpu_work_submitted=false`
- `render_executed=false`
- `production_drawable_texture_lifetime=false`
- `result_envelope_promoted_to_production_truth=false`
- `backend_ready_truth=false`
- `renderer_state_write=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`
- `native_bridge_expansion=false`
- `production_public_c_abi_added=false`

## 第一帧链路剩余缺口

当前 source/build/probe 闭环已经把 stage107 的 drawable / color-attachment readiness 接到 stage108 的 bounded isolated drawable token / texture observation contract。剩余缺口是：在 Metal-capable shell 中执行 stage108 bounded drawable first slice，拿到正向 `drawable_texture_observed=true` envelope；之后才能推进 render-pass descriptor color attachment first slice。再往后仍需 encoder creation、pipeline state、vertex buffer、draw、commit/present、bounded result envelope admission、production write admission 与 renderer-state write admission。

## 当前 next route

当前 canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableTextureLifetimeFirstSliceDraft()`

下一条最值得推进的工程目标：

`P1 Renderer visible-window NSApplication shared-application runtime native-readiness drawable texture lifetime first slice to render-pass color attachment configuration: rerun stage108 suite in a Metal-capable shell to produce a positive drawable texture lifetime envelope, then implement the smallest color attachment configuration first slice that consumes that envelope while keeping encoder / draw / commit / present / GPU submission / renderer-state write blocked.`

当前 blocker 状态：

- `automation_blocker=false_for_stage108_source_build_probe_suite`
- `automation_blocker=true_for_current_shell_bounded_drawable_first_slice_execution_due_to_host_metal_device_unavailable`
- `automation_blocker=false_for_metal_capable_shell_stage108_rerun`
- `automation_blocker=true_for_color_attachment_configuration_until_positive_drawable_texture_lifetime_envelope`
- `renderer_state_write_blocked=true`
