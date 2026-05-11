# Drawable 可见窗口 probe 清单

## 固定尾点

- Endpoint：`CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererDrawableVisibleWindowProbeDraft()`
- Runtime input：`CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness`
- Upstream owner：[runtime_renderer_drawable_environment_visibility.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_environment_visibility.cj)

## Owner 文件

- [runtime_renderer_drawable_visible_window_probe.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_visible_window_probe.cj)

## Probe

- [verify_native_bridge_drawable_visible_window_environment.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_visible_window_environment.sh)

## 实际路线

本阶段完成 A：isolated visible-window environment probe。

本阶段未进入 B/C：

- 没有调用 `nextDrawable`。
- 没有做 no-present acquisition。
- 没有建立 drawable token。
- 没有创建 command queue / command buffer / encoder。

## 固定事实

- Isolated probe 可以创建临时 `NSWindow` / `NSView` / `CAMetalLayer` / `MTLDevice`。
- Isolated probe 可以观察 visible window、attached view、attached layer、device-bound layer、display-backed layer 与 bounded run loop。
- Cleanup 以 window hidden、`view.wantsLayer` disabled、`layer.device` cleared 与 production token table counts zero 证明。
- Production runtime 没有新增 window semantics。
- Probe evidence 不是 production runtime truth。
- `nextDrawable` 仍未被调用。
- Present、command queue / command buffer、GPU submission、render 与 renderer state write 仍禁止。

## 上游与下游指向

上游固定：

- [Drawable environment / window visibility manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-environment-window-visibility-manifest.md)
- [Drawable acquisition first implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-acquisition-first-implementation-manifest.md)
- [Drawable acquisition runway manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-acquisition-runway-manifest.md)
- [Metal device binding runway manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-metal-device-binding-runway-manifest.md)
- [CAMetalLayer runtime attachment FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-runtime-attachment-ffi-call-owner-manifest.md)

下游唯一接续：

- 已由 [Drawable no-present acquisition 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-no-present-acquisition-manifest.md) 接续。
- 当前唯一后续入口转为 `P1 internal Renderer command queue creation planning preflight decision`。

## 停止线

不 present，不调用 `presentDrawable` / `present`，不创建 command queue / command buffer / encoder，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`，不把 isolated probe facts 解释成 backend-ready truth、drawable-ready truth、render permission、GPU submission permission 或 state write permission。

## 唯一后续入口

`P1 internal Renderer command queue creation planning preflight decision`
