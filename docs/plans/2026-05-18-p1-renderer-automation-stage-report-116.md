# P1 Renderer Automation Stage Report 116

时间：2026-05-18T17:20:58+08:00

## 本轮工程单元

本轮完成 Renderer visible-window `NSApplication` shared-application runtime native-readiness D3 bounded result-envelope command-buffer commit no-present cleanup lifecycle integration stage package。阶段目标不是新增 present / first-frame 行为，而是修复 stage114 已有 direct native probe 的 cleanup lifecycle evidence 没有进入 packet / classifier / suite 的断点，让 command-buffer commit no-present envelope 可被后续 present / first-frame 路线稳定消费。

本轮修改：

- [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice.cj)：补入 post-commit cleanup lifecycle contract。
- [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_owner.sh)：验证 cleanup lifecycle owner facts。
- [packet](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_packet.sh)、[classifier](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_classifier.sh)、[source-build guard](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_source_build_guard.sh)、[focused suite](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_first_slice_suite.sh)：传播 `cleanup_observed`、`bridge_table_counts_clean`、`post_commit_cleanup_lifecycle_observed` 与 cleanup classifier route。

Canonical touched endpoint 仍是 stage114 command-buffer commit no-present endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentFirstSliceDraft()`

## 能力闭环

Stage114 direct native probe 原本已经在 cleanup path 输出 `cleanup_observed` 与 `bridge_table_counts_clean`，但 suite packet 没有携带这些 facts。本轮把 cleanup lifecycle 变成 stage114 envelope 的一等 contract：

- owner 要求 post-commit cleanup lifecycle observation。
- direct probe 运行后，packet 保留 `cleanup_lifecycle_probe_executed`、`cleanup_observed` 与 `bridge_table_counts_clean`。
- 只有 `commit_called=true && cleanup_observed=true && bridge_table_counts_clean=true` 时，才承认 `post_commit_cleanup_lifecycle_observed=true`。
- 当前 shell 如果在 MTL device 之前失败，仍分类为 `host_metal_device_unavailable`，不会把 cleanup facts 误升格为 post-commit cleanup、production render truth 或 renderer-state write。

Fresh suite packet：

- `/tmp/cjgui-stage115-cleanup-integration-check/cjgui-stage114-command-buffer-commit-no-present-first-slice-suite/d3-bounded-result-envelope-command-buffer-commit-no-present-first-slice-suite.packet`

关键 facts：

- `post_commit_cleanup_lifecycle_envelope_ready=true`
- `cleanup_lifecycle_probe_executed=true`
- `cleanup_observed=true`
- `bridge_table_counts_clean=true`
- `post_commit_cleanup_lifecycle_observed=false`
- `cleanup_lifecycle_failure_classification=host_metal_device_unavailable`
- `post_commit_cleanup_lifecycle_classifier_route=host_metal_device_unavailable`
- `commit_called=false`
- `bounded_gpu_submission_completed=false`
- `present_called=false`
- `production_render_truth=false`
- `renderer_state_write=false`

本轮执行了 bounded D3 runtime native probe path；当前 shell 仍在 stage114 direct commit probe 的 `MTLCreateSystemDefaultDevice()` 前后分类为 `host_metal_device_unavailable`，因此没有正向 command-buffer commit / post-commit cleanup observation。该宿主限制不作为安全证明，cleanup integration 由源码、RED/GREEN probe、focused suite、build 与 scans 兜底。

## 验证结果

- TDD RED：基于 baseline stage114 suite packet 检查 `cleanup_observed` / `bridge_table_counts_clean` / `post_commit_cleanup_lifecycle_envelope_ready=true`，按预期 exit 42。
- TDD GREEN：同一检查在 fresh suite packet 上通过。
- Owner probe：通过，新增 cleanup lifecycle facts。
- Script syntax：packet / classifier / source-build guard / suite `zsh -n` 通过。
- Focused stage114 suite：通过，route 仍为 `host_metal_device_unavailable`，但 cleanup lifecycle facts 已进入 suite packet。
- Direct `cjpm build --target-dir /tmp/cjgui-stage115-direct-build-target --skip-script`：通过，仍为既有 `230 warnings generated, 230 warnings printed`。第一次 direct build 失败于 sandbox 中 envsetup 调 `ps` 被拒；复用 source-build guard 的 `ps` shim 后通过。
- `git diff --check`：通过。
- Protected path scan：`runtime/cjgui/src/runtime_state.cj` 与 `runtime/cjgui/cjpm.toml` 未修改。
- Public / foreign scan：stage114 command-buffer owner 未发现 public / foreign declaration。
- Forbidden owner token scan：stage114 command-buffer owner 未发现 native / AppKit / render call token。
- Production native bridge diff scan：未发现 AppKit / Metal / C ABI 扩张。
- Touched-file trailing whitespace scan：通过。
- `runtime_state.cj` 行数：10065，未变化。
- GitNexus impact：stage114 command-buffer owner 相关 symbols 均 `UNKNOWN / target not found`；CodeLattice sidecar 对 live repo path 返回 `path_denied`。本轮没有把图谱缺口当作安全证明。

未 stage、未 commit、未 push。

## Stop-line

本轮只补强 isolated command-buffer commit no-present cleanup lifecycle envelope：

- 不新增 production native bridge call。
- 不新增 public C ABI / `foreign func`。
- 不 present。
- 不把 `cleanup_observed=true` 解释成 post-commit cleanup success，除非同包也有 `commit_called=true`。
- 不写 `runtime_state.cj`，不写 renderer state。
- 不升级 production render truth / backend-ready truth。

## 第一帧链路剩余缺口

源码 / probe package 覆盖链路仍然停在 command-buffer commit no-present contract 与上游 stage115 present scheduling artifacts 之间。当前 fresh shell 未能正向复跑 stage114 commit；因此第一帧链路剩余缺口是：

- 在 Metal-capable shell 中重跑 stage114 cleanup-integrated suite，目标 `commit_called=true`、`bounded_gpu_submission_completed=true`、`post_commit_cleanup_lifecycle_observed=true`。
- 重新消费 cleanup-integrated stage114 positive packet 跑 stage115 present/no-present branch。
- 再进入 first-frame observation / frame-hash / visible-output envelope。
- production render truth、renderer-state write、public C ABI 仍 blocked。

## 下一段最值得推进

下一段建议在 Metal-capable shell 中重跑 cleanup-integrated stage114 suite 与已有 stage115 present/no-present suite：先确认 `post_commit_cleanup_lifecycle_observed=true`，再推进 `P1 Renderer visible-window NSApplication shared-application runtime native-readiness first-frame observation envelope`，补最小 bounded visible-output / frame-hash evidence，同时继续保持 production render truth、renderer-state write 与 public C ABI blocked。
