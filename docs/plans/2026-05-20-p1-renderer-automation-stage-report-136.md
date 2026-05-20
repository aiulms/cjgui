# P1 Renderer Automation Stage Report 136

Run time: 2026-05-20T01:19:47+0800

本轮接续 [stage report 135](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-20-p1-renderer-automation-stage-report-135.md)，完成 `command buffer contract after drawable readiness -> render encoder contract after command buffer` 连续阶段包。本轮不写 [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)，不扩 [cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)、native bridge、public API 或 public C ABI；本轮新增 stage136 owner / packets / focused suite，让 stage135 后续路线具备 command-buffer 与 render-encoder contract envelope，但当前宿主不暴露默认 Metal device，因此正向 render encoder probe 未执行。

## 连续工程闭环

1. Command buffer contract after drawable readiness first slice：新增 owner [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_render_encoder_contract_after_drawable_readiness_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_render_encoder_contract_after_drawable_readiness_first_slice.cj)、owner probe 与 command-buffer packet。该 packet 消费 stage135 command-pipeline packet，并执行 command-buffer create/destroy probe；当前输出 `command_buffer_create_destroy_probe=skipped_no_device`、`command_buffer_contract_route_classification=host_metal_device_unavailable`。
2. Render encoder contract after command buffer first slice：新增 render-encoder packet，消费 stage136 command-buffer packet；当前在 host no-device 下 fail-closed，输出 `render_encoder_contract_route_classification=host_metal_device_unavailable`、`bounded_render_encoder_probe_executed=false`、`render_command_encoder_created=false`、`end_encoding_called=false`。
3. Focused suite / source-build integration：新增 focused suite [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_render_encoder_contract_after_drawable_readiness_first_slice_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_render_encoder_contract_after_drawable_readiness_first_slice_suite.sh)，串联 owner、command-buffer packet、render-encoder packet、runtime package build、public/protected/forbidden scans，并产出 stage136 suite packet。

## 能力推进

当前 canonical endpoint 推进到：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferRenderEncoderContractAfterDrawableReadinessFirstSliceDraft()`。

Stage135 已把链路推进到 drawable + command queue + render-pass descriptor contract。Stage136 在源码和 packet 层补齐下一段 contract shape：`command buffer -> probe-local render pass color attachment -> render encoder/endEncoding`。当前宿主 no-device 阻止正向执行，但 failure envelope 已经可复用，并明确不升级 production render truth / backend-ready truth / renderer-state write。

## Runtime Probe / 环境分类

本轮执行的 runtime/native probes：

- `verify_native_bridge_metal_device_layer_binding.sh`：`metal_default_device_available=-111`、`metal_device_binding_probe=skipped_no_device`。
- `verify_native_bridge_command_queue_create_destroy.sh`：`metal_default_device_available=-111`、`command_queue_create_destroy_probe=skipped_no_device`。
- `verify_native_bridge_drawable_no_present_acquisition.sh`：visible-window / layer binding path 可执行，但最终 `drawable_acquired=false`，route 进入 `recovery_next_drawable_timeout`。
- stage136 focused suite：`command_buffer_contract_route_classification=host_metal_device_unavailable`、`render_encoder_contract_route_classification=host_metal_device_unavailable`。

本轮未发现新的 CJGUI harness 缺口。当前宿主限制有明确证据：同一轮 direct Metal device / command queue probes 均返回 no-device，stage135 command-pipeline packet 也回落到 `command_queue_blocked_by_host_metal_device_unavailable_render_pass_descriptor_ready`。因此本轮没有把 no-device 当作安全成功，也没有执行或伪造 render encoder positive facts。

## 验证结果

- TDD RED：先新增 stage136 focused suite，失败于缺少 stage136 owner script，退出码 3。
- Debug RED：补齐 owner/packets 后，suite 先失败于期望 `command_buffer_create_destroy_probe=passed`；根因是当前宿主不暴露默认 Metal device，stage135 command-pipeline packet 生成 `skipped_no_device`。已修正为 fail-closed host classification，并仍执行 command-buffer probe 取得 `skipped_no_device` 证据。
- Stage136 focused suite：通过，最终 suite packet 为 `/tmp/cjgui-stage136-command-buffer-render-encoder-suite-53212/stage136-command-buffer-render-encoder-contract-suite.packet`，确认 `runtime_package_build_passed=true`、`command_buffer_create_destroy_probe=skipped_no_device`、`bounded_render_encoder_probe_executed=false`、`next_drawable_called=false`、`command_buffer_created=false`、`render_command_encoder_created=false`、`draw_called=false`、`commit_called=false`、`present_called=false`、`renderer_state_write=false`、`runtime_state_write=false`。
- Runtime package build：由 stage136 focused suite 执行 `cjpm build --skip-script`，通过。
- Stage136 touched shell scripts `zsh -n`：通过。
- `git diff --check`：通过。
- Public / foreign declaration scan：通过，新增 owner 未新增 public surface。
- Forbidden native/render token scan：通过，新增 owner 未含 native execution token。
- Protected path scan：通过，[runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)、[cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)、native bridge header / impl 未被修改。
- `runtime_state.cj` 行数：10065，未变化。

## GitNexus / CodeLattice

GitNexus Tool CLI 使用 `cangjie-live-codelattice`：

- 对 stage136 endpoint / default draft 的 impact 查询返回 target not found、risk `UNKNOWN`，未作为安全证明。
- `detect-changes --repo cangjie-live-codelattice --scope all` 与 MCP `detect_changes` 均只覆盖已跟踪 README/docs 的 5 files / 2 symbols，affected processes `0`，risk `low`；当前 GitNexus 图仍未覆盖未跟踪新增 owner / scripts，未作为完整安全证明。
- CodeLattice sidecar before-edit review 对 live repo 返回 `path_denied`，未作为安全证明。

最终安全判断依赖 RED/GREEN suite、源码读取、focused probes、runtime build、public/protected/forbidden scans 与 `git diff --check`。

## 第一帧链路剩余缺口

第一条真实渲染链路当前已具备源码 / packet route 到：

`NSApplication -> NSWindow -> NSView -> CAMetalLayer -> MTLDevice / layer binding -> drawable readiness -> command queue / render pass descriptor contract -> command buffer / render encoder contract envelope`。

当前实际 positive runtime observation 仍停在 stage135 的上一轮 Metal-capable evidence；本轮宿主 no-device，未正向观测 `command_buffer_created=true`、`color_attachment_configured=true`、`render_command_encoder_created=true` 或 `end_encoding_called=true`。仍未完成 `pipeline -> vertex buffer -> draw -> commit / present -> first-frame observation -> production truth / renderer-state write admission`。

## Next Route

当前 canonical endpoint 是 command buffer / render encoder contract after drawable readiness first slice。下一条最值得推进的工程目标：

`P1 Renderer visible-window NSApplication shared-application runtime native-readiness command buffer / render encoder positive rerun or pipeline/vertex binding contract after render encoder: in a Metal-capable shell, rerun stage136 focused suite until command_buffer_created=true, color_attachment_configured=true, render_command_encoder_created=true and end_encoding_called=true; then add the smallest pipeline-state / vertex-buffer binding contract while keeping draw / commit / present / backend-ready truth / renderer_state_write / runtime_state_write / native bridge expansion / public C ABI blocked.`

本轮完成三个相邻工程闭环，不适用“只完成 1 个闭环”的停止说明。
