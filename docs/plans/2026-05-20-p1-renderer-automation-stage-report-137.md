# P1 Renderer Automation Stage Report 137

Run time: 2026-05-20T02:27:08+0800

本轮接续 [stage report 136](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-20-p1-renderer-automation-stage-report-136.md)，完成 `render encoder contract -> pipeline / vertex preparation -> pipeline / vertex binding -> no-submit draw-call` 连续阶段包。本轮不写 [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)，不改 [runtime/cjgui/cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)、native bridge header / impl、public API 或 public C ABI；所有新增 owner 只表达 internal readiness 与 stop-line，不执行 native runtime。

## 连续工程闭环

1. Pipeline / vertex preparation after render encoder contract first slice：新增 owner [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_pipeline_vertex_preparation_after_render_encoder_contract_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_pipeline_vertex_preparation_after_render_encoder_contract_first_slice.cj)、owner probe、packet 与 focused suite。该 packet 消费 stage136 suite；当前宿主沿 stage136 no-device envelope fail-closed，输出 `pipeline_vertex_preparation_route_classification=host_metal_device_unavailable`、`bounded_pipeline_vertex_preparation_executed=false`、`pipeline_state_created=false`、`vertex_buffer_created=false`。
2. Pipeline / vertex binding after preparation contract first slice：新增 owner [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_pipeline_vertex_binding_after_preparation_contract_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_pipeline_vertex_binding_after_preparation_contract_first_slice.cj)、owner probe、packet 与 focused suite。该 packet 消费 stage137 suite；当前输出 `pipeline_vertex_binding_route_classification=host_metal_device_unavailable`、`bounded_pipeline_vertex_binding_executed=false`、`pipeline_state_bound=false`、`vertex_buffer_bound=false`。
3. No-submit draw-call after pipeline / vertex binding contract first slice：新增 owner [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_after_pipeline_vertex_binding_contract_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_after_pipeline_vertex_binding_contract_first_slice.cj)、owner probe、packet 与 focused suite。该 packet 消费 stage138 suite；当前输出 `draw_call_route_classification=host_metal_device_unavailable`、`bounded_draw_call_executed=false`、`draw_called=false`、`commit_called=false`、`present_called=false`。

## 能力推进

当前 canonical endpoint 推进到：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceDraft()`。

Stage136 只把链路推进到 command-buffer / render-encoder contract envelope。Stage137-139 把后续 pipeline state creation、vertex buffer creation、pipeline/vertex binding 与 draw-call 的 packet contract 接成连续可复用路线；当前宿主 no-device 阻止正向 probe 执行，但不再需要下一位从 stage136 重新设计下游 envelope。

## Runtime Probe / 环境分类

本轮执行 stage137 / stage138 / stage139 focused suites，并由这些 suite 递归执行 stage136 suite。当前 host 仍不暴露默认 Metal device：stage136 产出 `render_encoder_contract_route_classification=host_metal_device_unavailable`，因此 stage137-139 的新增 isolated pipeline / binding / draw probes 均未执行，分别保持 `probe_exit_code=not_run` / `bounded_*_executed=false`。

本轮未发现新的 CJGUI harness 缺口。宿主限制证据来自 stage136 no-device envelope 以及本轮所有下游 packet 对该 envelope 的 fail-closed 传播；本轮没有把 no-device 当作成功，也没有伪造 `pipeline_state_created`、`vertex_buffer_bound` 或 `draw_called`。

## 验证结果

- TDD RED：stage137 / stage138 / stage139 各自先新增 focused suite，均先失败于缺少对应 owner script，退出码 3。
- Stage137 focused suite：通过，suite packet 为 `/tmp/cjgui-stage138-pipeline-vertex-binding-packet-2253/stage137/stage137-pipeline-vertex-preparation-after-render-encoder-contract-suite.packet`，确认 `pipeline_vertex_preparation_route_classification=host_metal_device_unavailable`、`bounded_pipeline_vertex_preparation_executed=false`、`pipeline_state_created=false`、`vertex_buffer_created=false`、`draw_called=false`、`commit_called=false`、`present_called=false`、`renderer_state_write=false`。
- Stage138 focused suite：通过，suite packet 为 `/tmp/cjgui-stage139-draw-call-packet-2160/stage138/stage138-pipeline-vertex-binding-after-preparation-contract-suite.packet`，确认 `pipeline_vertex_binding_route_classification=host_metal_device_unavailable`、`bounded_pipeline_vertex_binding_executed=false`、`pipeline_state_bound=false`、`vertex_buffer_bound=false`、`draw_called=false`、`commit_called=false`、`present_called=false`、`renderer_state_write=false`。
- Stage139 focused suite：通过，suite packet 为 `/tmp/cjgui-stage139-draw-call-after-binding-suite-2127/stage139-draw-call-after-pipeline-vertex-binding-contract-suite.packet`，确认 `draw_call_route_classification=host_metal_device_unavailable`、`bounded_draw_call_executed=false`、`draw_called=false`、`commit_called=false`、`present_called=false`、`gpu_work_submitted=false`、`render_executed=false`、`renderer_state_write=false`、`runtime_state_write=false`。
- Runtime package build：由 stage137 / stage138 / stage139 focused suites 执行 `cjpm build --skip-script`，均通过。
- 新增 shell scripts `zsh -n`：通过。
- Public / foreign declaration scan：通过，新增 owner 未新增 public surface。
- Forbidden native/render token scan：通过，新增 owner 未含 native execution token。
- Protected path scan：通过，[runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)、[runtime/cjgui/cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)、native bridge header / impl 未被修改。
- `git diff --check`：通过。
- `runtime_state.cj` 行数：10065，未变化。

## GitNexus / CodeLattice

GitNexus MCP / Tool CLI 使用 `cangjie-live-codelattice`：

- 对 stage136 endpoint 的 GitNexus impact 查询返回 target not found、risk `UNKNOWN`，未作为安全证明；CodeLattice sidecar 对同名 stage136 symbol 给出低风险本地预览，但也未替代 build/probe/scan。
- 对新增 stage137 / stage138 endpoints 的 GitNexus impact 查询返回 target not found、risk `UNKNOWN`，未作为安全证明。
- `detect-changes --repo cangjie-live-codelattice --scope all` 仍只覆盖已跟踪 README/docs 的 5 files / 2 symbols，affected processes `0`，risk `low`；当前图仍不覆盖未跟踪新增 owner / scripts。
- CodeLattice `changed_symbols` 对 repo root 返回 `path_denied`，对 `runtime/cjgui` 返回 `not_a_git_repo`，未作为安全证明。

最终安全判断依赖 RED/GREEN focused suites、源码读取、runtime build、public/protected/forbidden scans 与 `git diff --check`。

## 第一帧链路剩余缺口

第一条真实渲染链路当前已具备源码 / packet route 到：

`NSApplication -> NSWindow -> NSView -> CAMetalLayer -> MTLDevice / layer binding -> drawable readiness -> command queue / render pass descriptor contract -> command buffer / render encoder contract envelope -> pipeline / vertex preparation envelope -> pipeline / vertex binding envelope -> no-submit draw-call envelope`。

当前实际 positive runtime observation 仍受当前宿主 no-device 限制，本轮没有正向观测 `pipeline_state_created=true`、`vertex_buffer_created=true`、`pipeline_state_bound=true`、`vertex_buffer_bound=true` 或 `draw_called=true`。仍未完成 `commit / present -> first-frame observation -> production truth / renderer-state write admission`，也未升级 backend-ready truth 或 renderer-state write。

## Next Route

当前 canonical endpoint 是 no-submit draw-call after pipeline / vertex binding contract first slice。下一条最值得推进的工程目标：

`P1 Renderer visible-window NSApplication shared-application runtime native-readiness draw-call positive rerun or command-buffer commit no-present after draw-call contract: in a Metal-capable shell, rerun stage139 focused suite until pipeline_state_bound=true, vertex_buffer_bound=true and draw_called=true; then add the smallest command-buffer commit no-present envelope after draw-call while keeping present / first-frame production truth / renderer_state_write / runtime_state_write / native bridge expansion / public C ABI blocked. If the current host remains no-device, implement only the fail-closed commit-no-present-after-draw result contract that consumes stage139 without executing GPU submission.`

本轮完成三个相邻工程闭环，不适用“只完成 1 个闭环”的停止说明。
