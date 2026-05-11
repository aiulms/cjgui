# Drawable no-present acquisition 清单

日期：2026-05-11

状态：manifest / completed through isolated no-present acquisition facts

## 固定尾点

- Endpoint：`CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererDrawableNoPresentAcquisitionDraft()`
- Runtime input：`CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness`
- Upstream owner：[runtime_renderer_drawable_visible_window_probe.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_visible_window_probe.cj)

## Owner 文件

- [runtime_renderer_drawable_no_present_acquisition.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_no_present_acquisition.cj)

## Probe

- [verify_native_bridge_drawable_no_present_acquisition.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_no_present_acquisition.sh)

## 实际路线

本阶段完成 B/C：

- isolated visible-window no-present `nextDrawable` probe。
- internal value owner 记录脱水 facts。

本阶段未进入：

- production drawable acquisition C ABI。
- production drawable token table。
- present。
- command queue / command buffer / encoder。
- GPU submission。
- render。

## 固定事实

- Isolated probe 可以创建临时 `NSWindow` / `NSView` / `CAMetalLayer` / `MTLDevice`。
- Isolated probe 可以在 bounded run loop 内调用 `nextDrawable`。
- 当前环境观察到 `drawable_acquired=true`。
- Drawable 没有保存，没有返回到 public surface，也没有跨函数持久化。
- Probe 没有 present。
- Probe 没有创建 command queue / command buffer / encoder。
- Probe 没有提交 GPU work 或执行 render。
- Cleanup 后 window hidden、view layer disabled、layer device cleared，production token table counts 仍为 `0`。
- Production runtime window semantics 没有改变。
- Isolated probe evidence 不是 production runtime truth。

## 上游与下游指向

上游固定：

- [Drawable visible-window acquisition probe manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-visible-window-acquisition-probe-manifest.md)
- [Drawable environment / window visibility manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-environment-window-visibility-manifest.md)
- [Drawable acquisition first implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-acquisition-first-implementation-manifest.md)
- [Drawable acquisition runway manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-acquisition-runway-manifest.md)
- [Metal device binding runway manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-metal-device-binding-runway-manifest.md)
- [CAMetalLayer runtime attachment FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-runtime-attachment-ffi-call-owner-manifest.md)

下游唯一接续：

- `P1 internal Renderer command queue creation planning preflight decision`

## 下游已接续

本阶段已由 [Command queue creation 路线封账清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-command-queue-creation-runway-manifest.md) 接续。下游只打开 token-backed `MTLCommandQueue` create / classify / destroy 与 runtime-local FFI call facts；未创建 command buffer，未调用 `commandBuffer`，未创建 encoder，未 `commit` / `present`，未提交 GPU work，未执行 render，未写 renderer state。

## 停止线

不 present，不调用 `presentDrawable` / `present`，不创建 command queue / command buffer / encoder，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`，不把 isolated no-present drawable acquisition facts 解释成 production backend-ready truth、render permission、GPU submission permission 或 state write permission。

## 唯一后续入口

`P1 internal Renderer command queue creation planning preflight decision`
