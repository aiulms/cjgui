# P1 Renderer 可见窗口生产 Harness NSWindow Content View Attachment 预检决策

## 决策结论

本阶段选择 A 路线：允许打开 token-backed `NSWindow.contentView` attachment 的 bounded first slice。

下一刀可以在 production native bridge 中新增极窄 C ABI，把既有 token-backed `NSView` 作为既有 token-backed `NSWindow` harness 的 `contentView`，并新增 runtime internal owner 把 attach / classify / detach / cleanup facts 脱水为 internal readiness。该阶段仍只允许不可见窗口上的 content-view wiring，不允许 visible order、production `nextDrawable`、drawable texture lifetime、color attachment、render encoder、draw、`commit`、`present`、GPU submission、render execution、renderer state write、public diagnostics 或 public API。

## 上游

- `CjguiInternalRendererVisibleWindowNsWindowHarnessReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsWindowHarnessDraft()`
- 既有 token-backed `NSView` create / destroy facts。

## 允许的实现面

- 新增 `cjgui_native_bridge_nswindow_harness_content_view_*` internal C ABI。
- 新增 native probe 覆盖 main-thread gate、attach / classify / detach、double attach / detach fail-closed、invalid / stale token fail-closed、destroy-before-detach fail-closed、occupied count cleanup 与 still-blocked facts。
- 新增 runtime internal owner，默认文件为 `runtime_renderer_visible_window_content_view_attachment.cj`。

## 停止线

本阶段不允许调用 `makeKeyAndOrderFront`、production `nextDrawable`、`renderCommandEncoder`、`drawPrimitives`、`commit`、`presentDrawable` 或任何真实 render execution。不得返回 pointer / handle / `id` / `Class`，不得新增 public declaration，仍不得修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 下一边界

若本阶段 probe / build / smoke / forbidden scan 全部通过，下一 opening 只能转为：

`P1 internal Renderer visible-window production harness visible-order preflight decision`

该 next opening 仍只是预检；content-view attachment facts 不自动授权 visible order 或 drawable acquisition。
