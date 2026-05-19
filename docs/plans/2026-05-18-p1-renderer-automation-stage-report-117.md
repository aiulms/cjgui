# P1 Renderer Automation Stage Report 117

时间：2026-05-18T17:55:40+08:00

## 工程单元

本轮完成 Renderer visible-window `NSApplication` shared-application runtime native-readiness D3 bounded result-envelope first-frame observation first-slice stage package。阶段目标是消费 stage115 positive present scheduling envelope，在 isolated visible-window / `CAMetalLayer` / `MTLDevice` / command pipeline 已经完成 draw、commit、present scheduling 后，增加第一帧可观察 evidence envelope。

新增 runtime owner：

- [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_first_slice.cj)

新增 focused probes / scripts：

- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_first_frame_observation_first_slice.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_first_frame_observation_first_slice.sh)
- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_first_slice_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_first_slice_owner.sh)
- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_first_slice_packet.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_first_slice_packet.sh)
- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_first_slice_classifier.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_first_slice_classifier.sh)
- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_first_slice_source_build_guard.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_first_slice_source_build_guard.sh)
- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_first_slice_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_first_slice_suite.sh)

本轮还修复了两个真实 probe bug：direct probe 对显式 `TMPDIR` 父目录不存在时先 `mkdir -p`；macOS 15 SDK 已将 `CGWindowListCreateImage` / `CGDisplayCreateImageForRect` 标为 unavailable，因此 first-frame observation 改为 bounded `screencapture -R` 临时截图，读取 bytes 计算 frame-hash summary 后立即删除临时文件。

## 能力闭环

新的 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceDraft()`

Stage117 packet 只在 stage115 positive present scheduling envelope 满足 `present_called=true`、`bounded_drawable_present_scheduled=true`、`bounded_gpu_submission_completed=true` 后执行 first-frame observation probe。Probe 成功后只记录 capture / hash summary facts；不保存截图、不输出 hash 值、不做 baseline compare。

Fresh suite canonical packet：

- `/tmp/cjgui-stage117-suite-check/cjgui-stage117-first-frame-observation-first-slice-suite/d3-bounded-result-envelope-first-frame-observation-first-slice-suite.packet`

关键 result facts：

- `first_frame_observation_first_slice_classifier_route=admitted_bounded_first_frame_observed_first_slice`
- `current_shell_first_frame_observation_first_slice_ready=true`
- `present_called=true`
- `bounded_drawable_present_scheduled=true`
- `bounded_gpu_submission_completed=true`
- `first_frame_capture_attempted=true`
- `window_capture_requested=true`
- `frame_capture_image_created=true`
- `frame_pixel_width=180`
- `frame_pixel_height=168`
- `frame_hash_computed=true`
- `frame_hash_nonzero=true`
- `captured_nonzero_pixel_sample_count=255`
- `frame_hash_persisted=false`
- `frame_hash_value_logged=false`
- `baseline_compared=false`
- `first_frame_observed=true`
- `production_present_call=false`
- `production_render_truth=false`
- `renderer_state_write=false`

## 验证

- TDD RED：目标 stage117 owner 文件缺失时 `test -f ...first_frame_observation_first_slice.cj` 按预期 exit 1。
- Owner probe：通过。
- Direct bounded native first-frame observation probe：通过，确认 draw / present / commit / bounded wait / `screencapture -R` / frame-hash summary 全链路正向。
- Focused packet smoke：通过。
- Focused classifier smoke：`admitted_bounded_first_frame_observed_first_slice`。
- Source/build guard smoke：通过。
- Final focused suite：通过，canonical packet 如上。
- 独立 `cjpm build --target-dir /tmp/cjgui-stage117-direct-build-check/target --skip-script`：通过，仍为既有 `230 warnings generated, 230 warnings printed`。
- `git diff --check`：通过。
- Protected path scan：`runtime/cjgui/src/runtime_state.cj` 与 `runtime/cjgui/cjpm.toml` 未改。
- Line count：`runtime_state.cj=10065`、`cjpm.toml=6`，与前序保持一致。
- Stage117 owner public / foreign scan：通过。
- Stage117 owner forbidden native token scan：通过。
- Production native bridge forbidden diff scan：通过。
- Production public C ABI diff scan：通过。
- GitNexus impact：stage115 / stage117 相关新增 long-tail owner symbols 均 `UNKNOWN / target not found`，未当作安全证明。
- GitNexus `detect-changes --repo cangjie-live-codelattice --scope all`：返回 `Changes: 5 files, 3 symbols, Affected processes: 0, Risk level: low`；当前 graph 仍未覆盖新增 untracked stage111-stage117 owner/scripts，安全结论依赖源码读取、focused probes、build 与 scans 兜底。

未 stage、未 commit、未 push。

## Bounded D3 / 环境判断

本轮执行了 bounded D3 runtime native probe。当前 shell 可用 `MTLDevice`，并可通过 `screencapture -R` 获得临时用户可见窗口截图；未遇到 host Metal 或 host capture 限制。

本轮没有把 isolated first-frame observation 升级为 production render truth；没有修改 production native bridge；没有新增 public C ABI / `foreign func`；没有写 `runtime_state.cj` 或 renderer state。

## 第一帧链路剩余缺口

当前真实链路已推进到：

`NSApplication -> NSWindow -> NSView -> CAMetalLayer -> MTLDevice -> drawable -> command queue -> command buffer -> render pass -> encoder -> pipeline -> vertex buffer -> draw -> commit -> present scheduling -> bounded completion -> user-visible capture -> frame-hash summary -> first_frame_observed envelope`

仍未完成：

- `first_frame_observed` 仍是 isolated observation envelope，不是 production render truth。
- 没有 baseline compare / content semantic verification。
- 没有 production renderer state write admission。
- 没有 production bridge call site / stable public C ABI。
- 没有把 first-frame observation 接入 renderer-state decision join。

## 下一条最值得推进的工程目标

下一段建议推进 `P1 Renderer visible-window NSApplication shared-application runtime native-readiness first-frame observation truth-admission join`：消费 stage117 positive suite packet，把 `first_frame_observed=true` 作为 isolated observation input 接入 renderer-state write decision / production truth admission 的前置 contract；继续保持 production render truth、renderer-state write 与 public C ABI blocked，直到 admission owner 和 focused suite 同时证明可写边界。
