# P1 Renderer Automation Stage Report 128

日期：2026-05-19

## 阶段包

本轮是 Renderer visible-window `NSApplication` shared-application runtime native-readiness first-frame observation semantic-comparison-admitted renderer-state visibility publication denial / rollback fallback denial / terminal write denial 连续阶段包，接续 [stage report 127](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-19-p1-renderer-automation-stage-report-127.md) 的 guarded executor result envelope。

本轮完成 3 个相邻工程闭环：

1. visibility publication denial first slice：新增 owner [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_visibility_publication_denial_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_visibility_publication_denial_first_slice.cj)、owner probe 与 packet，消费 guarded executor result envelope，把 `visibility_publication_denied=true` 固化为 dry-run denial fact。
2. rollback fallback denial envelope first slice：新增 owner [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_first_slice.cj)、owner probe 与 packet，消费 visibility denial，把 rollback fallback 绑定到 stop-line，固定 `rollback_fallback_state_write_denied=true`。
3. terminal write denial envelope first slice：新增 owner [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_first_slice.cj)、owner probe、packet 与 focused suite [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_first_slice_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_first_slice_suite.sh)，汇总 visibility denial 与 rollback fallback denial，固定 `terminal_renderer_state_write_denied=true`。

## 能力推进

stage127 的 endpoint 已被接到新的 canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateTerminalWriteDenialEnvelopeFirstSliceReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateTerminalWriteDenialEnvelopeFirstSliceDraft()`。

这条链路现在从 first-frame observation semantic comparison admitted 继续向后覆盖：

`guarded executor result envelope -> visibility publication denial -> rollback fallback denial envelope -> terminal renderer-state write denial envelope`。

本轮没有执行或批准真实 renderer-state write，没有写 `runtime_state.cj`，没有修改 `runtime/cjgui/cjpm.toml`，没有扩 native bridge、public API 或 public C ABI。

## 验证结果

- stage128 focused suite：`d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_envelope_first_slice_suite_passed=true`。
- suite packet：`semantic_comparison_admitted_renderer_state_visibility_publication_denial_ready=true`、`semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_ready=true`、`semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_ready=true`、`terminal_renderer_state_write_denied=true`、`runtime_native_probe_execution=true`、`renderer_state_write=false`、`runtime_state_write=false`。
- 直接 `cjpm build --skip-script`：通过。
- `git diff --check`：通过。
- stage128 shell scripts `zsh -n`：通过。
- public / foreign declaration scan：通过，未新增 public surface。
- forbidden native/render token scan：通过，新增 owner 未含 AppKit / Metal / capture 调用 token。
- protected path scan：通过，`runtime/cjgui/cjpm.toml`、`runtime/cjgui/src/runtime_state.cj`、native bridge header / impl 未被修改。
- `runtime_state.cj` 行数：10065，未变化。

## Runtime Probe

本轮执行了 bounded runtime native probe。当前 shell 是 Metal-capable：

- `isolated_metal_device_available=true`
- `next_drawable_called=true`
- `drawable_texture_observed=true`
- `command_queue_created=true`
- `command_buffer_created=true`
- `render_pass_descriptor_created=true`
- `render_command_encoder_created=true`
- `pipeline_state_created=true`
- `vertex_buffer_created=true`
- `draw_called=true`
- `present_called=true`
- `commit_called=true`
- `bounded_gpu_submission_completed=true`
- `first_frame_observed=true`
- `frame_hash_computed=true`
- `frame_hash_nonzero=true`
- `production_render_truth=false`
- `backend_ready_truth=false`
- `result_envelope_promoted_to_production_truth=false`
- `renderer_state_write=false`

Metal binding probe 也通过：`metal_default_device_available=101`、`metal_device_binding_probe=passed`。

本轮没有遇到新的 CJGUI harness 缺口；也没有宿主限制。相反，当前宿主可运行 bounded native first-frame probe。该 evidence 仍只按 isolated / bounded probe 处理，不升级为 production truth。

## GitNexus / CodeLattice

GitNexus CLI 使用 `cangjie-live-codelattice`：

- `impact cjguiInternalExecuteDefault...TerminalWriteDenialEnvelopeFirstSliceDraft --repo cangjie-live-codelattice` 返回 `UNKNOWN/not found`，因此不能作为安全证明。
- `context cjguiInternalExecuteDefault...TerminalWriteDenialEnvelopeFirstSliceDraft --repo cangjie-live-codelattice` 返回 symbol not found。
- `detect-changes --repo cangjie-live-codelattice --scope all` 只覆盖 README 中 2 个 changed symbols，未覆盖本轮 untracked owner / script。

CodeLattice sidecar：

- `codelattice_impact_preview` 在 `runtime/cjgui` 上识别 terminal draft，risk `LOW`，caller count `0`。
- `codelattice_production_assist` 对三个新增 draft 给出 overall risk `LOW`、quality gates passed `6`、diagnostics `0`。
- `codelattice_changed_symbols` 在 repo 根被 live-repo deny list 拒绝，在 `runtime/cjgui` 子目录因不是 git repo 无法运行；未作为安全证明。

最终安全判断依赖源码读取、owner/packet/focused suite、直接 build、bounded runtime probe、public/protected/forbidden scans 和 `git diff --check`。

## 当前缺口

第一条真实渲染链路已经在 bounded probe 中到达 first-frame observation：`NSApplication -> NSWindow -> NSView -> CAMetalLayer -> MTLDevice -> drawable -> command queue -> command buffer -> render pass -> encoder -> pipeline -> vertex buffer -> draw -> present -> commit -> first-frame observation`。

仍未完成的 production 缺口：

- first-frame hash 未持久化：`frame_hash_persisted=false`。
- baseline / semantic result 未被提升为 production truth：`result_envelope_promoted_to_production_truth=false`。
- `production_render_truth=false`、`backend_ready_truth=false`。
- visibility publication 仍被 denial envelope 阻断。
- rollback fallback state write 仍被 denial envelope 阻断。
- terminal renderer-state write 仍为 dry-run denial：`renderer_state_write=false`。
- 未扩 public C ABI / native bridge / stable public API。
- `runtime_state.cj` 未写入，也不应在缺少 production truth admission 时写入。

## Next Route

当前 canonical endpoint 是 terminal write denial envelope first slice。下一条最值得推进的工程目标：

`P1 Renderer visible-window NSApplication shared-application runtime native-readiness first-frame observation semantic-comparison-admitted terminal write denial envelope production-truth gap matrix / renderer-state write readiness closure first slice: consume stage128 terminal write denial suite packet, materialize the exact missing predicates for production render truth, backend-ready truth, visibility publication, rollback fallback and renderer_state_write admission, and keep runtime_state_write / public C ABI / native bridge blocked until those predicates are verified by focused build/probe/scan.`

这个目标应继续服务真实渲染链路，不要退回到 approval / handoff /同构 guard wrapper。当前 shell Metal-capable，下一轮可以继续执行 bounded runtime native probe 并复用本轮 terminal denial packet。
