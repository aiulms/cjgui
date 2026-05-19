# P1 Renderer Automation Stage Report 115

时间：2026-05-18 17:07:29 CST

## 工程单元

本轮完成 Renderer visible-window `NSApplication` shared-application runtime native-readiness D3 bounded result-envelope `present/no-present branch` first-slice stage package。

新增 runtime owner：

- [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_no_present_branch_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_no_present_branch_first_slice.cj)

新增 focused probes / scripts：

- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_present_no_present_branch_first_slice.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_present_no_present_branch_first_slice.sh)
- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_no_present_branch_first_slice_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_no_present_branch_first_slice_owner.sh)
- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_no_present_branch_first_slice_packet.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_no_present_branch_first_slice_packet.sh)
- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_no_present_branch_first_slice_classifier.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_no_present_branch_first_slice_classifier.sh)
- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_no_present_branch_first_slice_source_build_guard.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_no_present_branch_first_slice_source_build_guard.sh)
- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_no_present_branch_first_slice_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_no_present_branch_first_slice_suite.sh)

本轮先复跑 stage114 suite 并确认当前 shell 已经 Metal-capable：`bounded_command_buffer_commit_no_present_first_slice_executed=true`、`commit_called=true`、`bounded_gpu_submission_completed=true`、`gpu_work_submitted=true`、`present_called=false`。随后 stage115 在同一个 isolated visible-window / `CAMetalLayer` / `MTLDevice` / command pipeline 链路上完成 `presentDrawable` scheduling、commit 与 bounded completion wait。

## 能力闭环

新的 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentNoPresentBranchFirstSliceDraft()`

Stage115 packet 会消费 stage114 command-buffer commit no-present positive suite packet。只有 stage114 positive commit envelope 同时满足 `commit_called=true`、`bounded_gpu_submission_completed=true`、`gpu_work_submitted=true` 时，才进入 present branch；否则保持 no-present / host classification 分支。

Fresh suite canonical packet：

- `/tmp/cjgui-stage115-final-suite-check.bjOkFM/cjgui-stage115-present-no-present-branch-first-slice-suite/d3-bounded-result-envelope-present-no-present-branch-first-slice-suite.packet`

关键 result facts：

- `present_no_present_branch_first_slice_classifier_route=admitted_bounded_present_scheduled_branch_first_slice`
- `bounded_present_no_present_branch_first_slice_executed=true`
- `present_branch_selected=true`
- `present_after_encoding_before_commit=true`
- `present_called=true`
- `drawable_present_scheduled=true`
- `bounded_drawable_present_scheduled=true`
- `commit_called=true`
- `bounded_completion_wait_completed=true`
- `command_buffer_status_completed=true`
- `bounded_gpu_submission_completed=true`
- `gpu_work_submitted=true`
- `drawable_presented=false`
- `production_present_call=false`
- `production_gpu_submission=false`
- `production_render_truth=false`
- `renderer_state_write=false`

## 验证

- TDD RED：新增 owner probe 后先失败于缺失 stage115 owner。
- Owner probe：通过。
- Direct bounded native present/no-present branch probe：通过，确认 `present_called=true`、`drawable_present_scheduled=true`、`bounded_drawable_present_scheduled=true`。
- Focused packet smoke：通过。
- Focused classifier smoke：`admitted_bounded_present_scheduled_branch_first_slice`。
- Source/build guard smoke：通过。
- Final focused suite：通过，canonical packet 如上。
- 独立 `cjpm build --skip-script`：通过，仍为既有 `230 warnings generated, 230 warnings printed`。
- `git diff --check`：通过。
- Protected path scan：`runtime/cjgui/src/runtime_state.cj` 与 `runtime/cjgui/cjpm.toml` 未改。
- Line count：`runtime_state.cj=10065`、`cjpm.toml=6`，与前序保持一致。
- Stage115 owner public / foreign scan：通过。
- Stage115 owner forbidden native token scan：通过。
- Production native bridge forbidden diff scan：通过。
- Production public C ABI diff scan：通过。
- Stage115 production truth forbidden scan：通过。
- GitNexus `detect-changes --repo cangjie-live-codelattice --scope all`：返回 `Changes: 5 files, 3 symbols, Affected processes: 0, Risk level: low`，但当前 graph 未覆盖新增 untracked stage115 owner/scripts；安全结论依赖源码读取、focused probes、build 与 scans 兜底。
- `cangjie-production-alias-check.sh --status`：`cangjie-live-codelattice`，stable window `YELLOW`，dirty workspace。

## Bounded D3 / 环境判断

本轮执行了 bounded D3 runtime native probe。当前 shell 可用 `MTLDevice`，未遇到宿主限制；stage114 的前序 `host_metal_device_unavailable` 状态已由本轮 fresh suite 正向复核解除。

本轮没有把 isolated probe evidence 升级为 production render truth；没有修改 production native bridge；没有新增 public C ABI / `foreign func`；没有写 `runtime_state.cj` 或 renderer state。

## 第一帧链路剩余缺口

当前真实链路已推进到：

`NSApplication -> NSWindow -> NSView -> CAMetalLayer -> MTLDevice -> drawable -> command queue -> command buffer -> render pass -> encoder -> pipeline -> vertex buffer -> draw -> commit -> present scheduling -> bounded completion`

仍未完成：

- `drawable_presented` / first-frame visible output truth。
- frame hash / screenshot / pixel evidence envelope。
- production render truth admission。
- renderer state write admission。
- production bridge call site / stable public C ABI。

## 下一条最值得推进的工程目标

下一段建议推进 `P1 Renderer visible-window NSApplication shared-application runtime native-readiness first-frame observation envelope`：消费 stage115 positive suite packet，在仍不写 renderer state、不扩 production bridge、不升级 production truth 的前提下，补一个 bounded visible-output / frame-hash 或 equivalent observable first-frame evidence first slice，区分 `present scheduled` 与 `first frame observed`。
