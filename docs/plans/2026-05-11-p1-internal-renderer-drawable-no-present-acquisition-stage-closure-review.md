# Drawable no-present acquisition 阶段封账

日期：2026-05-11

## 本轮实际完成

- 新增 probe：[verify_native_bridge_drawable_no_present_acquisition.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_no_present_acquisition.sh)
- 新增 runtime owner：[runtime_renderer_drawable_no_present_acquisition.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_no_present_acquisition.cj)
- 新 endpoint：`CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness`
- 新 default draft：`cjguiInternalExecuteDefaultRendererDrawableNoPresentAcquisitionDraft()`
- Runtime input：`CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness`

## Probe 结果

本轮实际路线是 B/C：isolated visible-window no-present `nextDrawable` acquisition + internal dehydrated facts。

Probe 观察到：

- `drawable_no_present_acquisition_route=isolated_no_present_acquisition`
- `isolated_visible_window_probe_executed=true`
- `isolated_window_visible_observed=true`
- `display_backed_layer_observed=true`
- `bounded_run_loop_observed=true`
- `next_drawable_called=true`
- `next_drawable_bounded_observed=true`
- `next_drawable_elapsed_ms=1`
- `drawable_acquired=true`
- `drawable_saved=false`
- `present_called=false`
- `command_queue_created=false`
- `command_buffer_created=false`
- `encoder_created=false`
- `gpu_work_submitted=false`
- `render_executed=false`
- `cleanup_observed=true`
- `view_table_occupied_after=0`
- `layer_table_occupied_after=0`
- `device_table_occupied_after=0`

## 未进入范围

- 没有 present。
- 没有创建 command queue / command buffer / encoder。
- 没有提交 GPU work。
- 没有执行 render。
- 没有把 drawable 保存到 production table。
- 没有新增 production drawable token table。
- 没有修改 production runtime window semantics。
- 没有修改 `runtime/cjgui/cjpm.toml`。
- 没有修改 smoke native files。
- 没有触碰 `runtime_state.cj`。
- 没有新增 public API / diagnostics。

## 封账判断

本阶段证明当前本机 isolated visible-window environment 可以在 bounded run loop 内 no-present 调用 `nextDrawable` 并获得 drawable，随后立即清理。该事实只作为 internal dehydrated facts 进入 runtime owner。

它不证明 production runtime 可以获取 drawable，不证明可 present，不证明 command queue / command buffer / encoder 可创建，不证明 render permission、GPU submission permission、renderer state write permission或 backend-ready truth。

## GitNexus 记录

上游 endpoint 与 default draft 的 GitNexus impact 均为 `UNKNOWN` / target not found / impactedCount `0`；按近期新增 owner 未索引记录。本轮已用源码、probe、build 与 forbidden scan 兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，drawable 路线从 visible-window probe 推进到 isolated no-present `nextDrawable` acquisition facts。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 更新为 `CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 owner 与 no-present acquisition probe；truth 限 isolated probe facts；stop-line 继续禁止 present、command queue / buffer、GPU work、render、state write 与 public API。
- 本轮是否改变唯一 next opening：是，唯一 next opening 更新为 `P1 internal Renderer command queue creation planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
