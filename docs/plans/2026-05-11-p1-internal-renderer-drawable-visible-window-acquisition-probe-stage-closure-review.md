# Drawable 可见窗口 probe 阶段封账

## 本轮实际完成

- 新增 runtime owner：[runtime_renderer_drawable_visible_window_probe.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_visible_window_probe.cj)
- 更新 isolated probe：[verify_native_bridge_drawable_visible_window_environment.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_visible_window_environment.sh)
- 新 endpoint：`CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness`
- 新 default draft：`cjguiInternalExecuteDefaultRendererDrawableVisibleWindowProbeDraft()`
- Runtime input：`CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness`

## Probe 结果

当前 probe 路线是 A：isolated visible-window environment。

Probe 已观察并输出：

- `isolated_visible_window_probe_executed=true`
- `production_window_created=false`
- `isolated_window_created=true`
- `isolated_window_visible_observed=true`
- `isolated_view_attached_observed=true`
- `isolated_cametallayer_attached_observed=true`
- `isolated_metal_device_bound_observed=true`
- `display_backed_layer_observed=true`
- `bounded_run_loop_observed=true`
- `cleanup_observed=true`
- `next_drawable_called=false`
- `present_called=false`
- `command_buffer_created=false`
- `gpu_work_submitted=false`

## 调试记录

旧 probe 只输出 planning facts，`isolated_visible_window_probe_executed=true` 红灯失败。本轮实现 isolated window 后，第一次运行发现 cleanup 判定过严：AppKit 关闭窗口后不适合用 `view.layer == nil` 作为唯一 cleanup 标志。最终改为可证明的 `window hidden`、`view.wantsLayer` disabled、`layer.device` cleared 与 production token tables zero。

## 未进入范围

- 未调用 `nextDrawable`。
- 未 present。
- 未创建 command queue / command buffer / encoder。
- 未提交 GPU work 或执行 render。
- 未修改 production runtime window semantics。
- 未新增 public API / diagnostics。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未触碰 `runtime_state.cj`。

## 封账判断

本阶段证明 isolated visible-window、display-backed `CAMetalLayer`、main-thread bounded run loop 与 cleanup 可以被 probe 复核。它不证明 production runtime 可以创建窗口，也不证明 drawable acquisition、backend-ready truth、render permission、GPU submission 或 renderer state write permission。

## 设计意图出口自检

- 本轮是否改变主题状态：是，drawable visible-window acquisition probe 已从 planning 进入 isolated environment proof。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 更新为 `CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 owner 与 isolated probe facts；stop-line 仍禁止 `nextDrawable`、present、command queue / buffer、GPU work、render、state write 与 public API。
- 本轮是否改变唯一 next opening：是，唯一 next opening 更新为 `P1 internal Renderer drawable no-present acquisition recovery/preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
