# P1 Renderer Automation Stage Report 135

Run time: 2026-05-20T00:48:59+0800

本轮接续 [stage report 134](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-20-p1-renderer-automation-stage-report-134.md)，完成 `positive-host token gate robustness -> drawable readiness after visible-order -> command pipeline contract after drawable readiness` 连续阶段包。本轮不写 [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)，不扩 [cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)、native bridge、public API 或 public C ABI；本轮允许 isolated bounded probe 调用 `nextDrawable` no-present acquisition，但不创建 render command encoder，不 draw，不 commit / present，不写 renderer state。

## 连续工程闭环

1. Positive-host robustness bugfix：当前 shell 重新变为 Metal-capable，stage133 materialization / stage134 visible-order suite 暴露出旧 no-device hardcoded facts。修复 [positive-probe materialization packet](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_positive_probe_materialization_first_slice_packet.sh)、stage133 suite 与 stage134 suite，让它们接受 tokenized positive-host evidence，同时继续保持 `backend_ready_truth=false`、`renderer_state_write=false`、`runtime_state_write=false`。
2. Drawable readiness after visible-order first slice：新增 owner [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_readiness_after_visible_order_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_readiness_after_visible_order_first_slice.cj)、owner probe 与 packet。该 packet 消费 stage134 visible-order suite，确认 `metal_device_binding_probe=passed` 后执行 isolated visible-window no-present drawable acquisition，产出 `drawable_readiness_route_classification=isolated_no_present_acquisition`、`next_drawable_called=true`、`drawable_acquired=true`。
3. Command pipeline contract after drawable readiness first slice：新增 owner [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_pipeline_contract_after_drawable_readiness_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_pipeline_contract_after_drawable_readiness_first_slice.cj)、owner probe、packet 与 focused suite [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_readiness_after_visible_order_first_slice_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_readiness_after_visible_order_first_slice_suite.sh)。该 packet 验证 `command_queue_create_destroy_probe=passed` 与 `render_pass_descriptor_create_destroy_probe=passed`，但仍固定 `command_buffer_created=false`、`render_command_encoder_created=false`、`draw_called=false`、`commit_called=false`、`present_called=false`。

## 能力推进

当前 canonical endpoint 已推进到：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceDraft()`。

Stage134 只把 AppKit visible-order / cleanup 证明到位，并把 next route 指向 drawable readiness。Stage135 在当前 Metal-capable shell 中实际跨过了 `CAMetalLayer -> drawable` 这一节点，并把 `MTLDevice -> command queue` 与 `render pass descriptor` contract 重新验证到 positive-host packet；第一帧链路现在离 `command buffer -> render pass -> encoder` 只剩下一段 bounded contract。

## Runtime Probe / 环境分类

本轮执行 bounded runtime native probe：

- stage133 fresh bounded first-frame probe：当前 shell 为 positive host，`positive_live_probe_observed=true`、`nonzero_frame_hash_observed=true`、`backing_store_token_issued=true`、`frame_hash_persistence_commit_admitted=true`、`result_envelope_promoted_to_production_truth=true`，但 `backend_ready_truth=false`、`renderer_state_write=false`。
- stage134 visible-order smoke：`visible_order_smoke_observed=true`、`metal_device_binding_probe=passed`、`visible_order_to_metal_next_gap=none_metal_device_binding_available`。
- stage135 drawable readiness：`drawable_readiness_route_classification=isolated_no_present_acquisition`、`next_drawable_called=true`、`drawable_acquired=true`、`present_called=false`。
- stage135 command pipeline contract：`command_queue_create_destroy_probe=passed`、`render_pass_descriptor_create_destroy_probe=passed`，未创建 command buffer / encoder，未提交 GPU work。

本轮未遇到新的 CJGUI harness 缺口。宿主限制从 stage134 的 no-device 状态变为 Metal-capable；本轮修复了脚本对旧宿主状态的脆弱假设，并利用当前宿主能力推进真实链路。

## 验证结果

- TDD RED：先新增 stage135 focused suite，失败于缺少 stage135 drawable readiness owner script。
- Debug RED：补齐 stage135 后 suite 失败于 stage134 rerun；根因是 stage133 materialization packet 硬要求 `frame_hash_persistence_commit_admitted=false`，而当前 positive-host stage132 packet 已产生 `true`。
- Stage133 token gate suite：通过，suite packet 确认 `positive_probe_materialization_route_classification=positive_probe_materialized`、`positive_live_probe_observed=true`、`nonzero_frame_hash_observed=true`、`backing_store_token_issued=true`、`frame_hash_persistence_commit_admitted=true`、`result_envelope_promoted_to_production_truth=true`、`backend_ready_truth=false`、`renderer_state_write=false`。
- Stage134 visible-order suite：通过，suite packet 确认 `metal_device_binding_probe=passed`、`visible_order_to_metal_next_gap=none_metal_device_binding_available`、`drawable_requested=false`、`renderer_state_write=false`。
- Stage135 focused suite：通过，suite packet 确认 `drawable_readiness_route_classification=isolated_no_present_acquisition`、`command_pipeline_contract_route_classification=command_queue_and_render_pass_descriptor_contract_ready`、`metal_device_binding_probe=passed`、`command_queue_create_destroy_probe=passed`、`render_pass_descriptor_create_destroy_probe=passed`、`next_drawable_called=true`、`drawable_acquired=true`、`command_buffer_created=false`、`render_command_encoder_created=false`、`draw_called=false`、`commit_called=false`、`present_called=false`、`renderer_state_write=false`、`runtime_state_write=false`。
- Runtime package build：由 stage135 focused suite 执行 `cjpm build --skip-script`，通过。
- Stage135 / touched stage133 / stage134 shell scripts `zsh -n`：通过。
- `git diff --check`：通过。
- Public / foreign declaration scan：通过，新增 owner 未新增 public surface。
- Forbidden native/render token scan：通过，新增 owner 未含 native execution token。
- Protected path scan：通过，[runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)、[cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)、native bridge header / impl 未被修改。
- `runtime_state.cj` 行数：10065，未变化。

## GitNexus / CodeLattice

GitNexus Tool CLI 使用 `cangjie-live-codelattice`：

- 对 planned stage135 endpoint / default draft 与 stage134 consumed endpoint 的 impact 查询返回 target not found、risk `UNKNOWN`，未作为安全证明。
- 对 stage133 positive-host robustness touched symbols 的 impact 查询也返回 target not found、risk `UNKNOWN`，未作为安全证明。
- `detect-changes --repo cangjie-live-codelattice --scope all` 仅覆盖已跟踪 README/docs 的 5 files / 2 symbols，affected processes `0`，risk `low`；当前 GitNexus 图仍未覆盖未跟踪新增 owner / scripts，未作为完整安全证明。

最终安全判断依赖 RED/GREEN suite、源码读取、bounded probes、runtime build、public/protected/forbidden scans 与 `git diff --check`。

## 第一帧链路剩余缺口

第一条真实渲染链路现在能表达并验证到：

`NSApplication -> NSWindow -> NSView -> CAMetalLayer -> MTLDevice / layer binding -> drawable no-present acquisition -> command queue create/destroy contract -> render pass descriptor create/destroy contract`。

仍未完成：

- `command buffer -> render pass color attachment -> render command encoder` 尚未作为 stage135 后的 positive bounded contract 接续。
- `pipeline -> vertex buffer -> draw -> commit / present` 尚未在本轮执行。
- `backend_ready_truth=false`，所以 `renderer_state_write_admission_ready=false`、`renderer_state_write=false`、`runtime_state_write=false`。
- 未扩 public C ABI / native bridge / stable public API。

## Next Route

当前 canonical endpoint 是 command pipeline contract after drawable readiness first slice。下一条最值得推进的工程目标：

`P1 Renderer visible-window NSApplication shared-application runtime native-readiness command buffer / render encoder contract after drawable readiness first slice: consume stage135 suite packet, create a bounded positive contract for command buffer creation plus render-pass color attachment and render command encoder creation/endEncoding, keep draw / commit / present / backend-ready truth / renderer_state_write / runtime_state_write / native bridge expansion / public C ABI blocked until the encoder contract is separately verified.`

本轮完成三个相邻工程闭环，不适用“只完成 1 个闭环”的停止说明。
