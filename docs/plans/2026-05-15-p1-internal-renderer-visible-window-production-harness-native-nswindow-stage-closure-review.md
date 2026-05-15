# P1 内部 Renderer 可见窗口生产 Harness 原生 NSWindow 阶段封账复核

## 完成内容

本阶段完成 token-backed `NSWindow` harness bounded first slice：

- 在 [cjgui_native_bridge.h](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.h) / [cjgui_native_bridge.m](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.m) 新增 `NSWindow` harness 固定容量 table、create / destroy / classify / double-destroy / still-blocked C ABI。
- 新增 [runtime_renderer_visible_window_nswindow_harness.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nswindow_harness.cj)，固定 runtime internal owner `CjguiInternalRendererVisibleWindowNsWindowHarnessReadiness` 与 default draft `cjguiInternalExecuteDefaultRendererVisibleWindowNsWindowHarnessDraft()`。
- 新增 [verify_native_bridge_nswindow_harness_create_destroy.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nswindow_harness_create_destroy.sh)，覆盖 main-thread gate、opaque token、table lifecycle、background deny、stale / double-destroy fail-closed 与 still-blocked facts。
- 更新 native guard allowlist，使已批准的 `NSWindow` harness 不被旧 no-object guard 误拦截。

## 未越过的停止线

- 未调用 production `nextDrawable`。
- 未调用 `present` / `commit`。
- 未创建 render command encoder。
- 未执行 draw / render / GPU submission。
- 未写 renderer state，未修改 `runtime_state.cj`。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未新增 public API / public diagnostics。
- 未返回 pointer / handle / `id` / `Class` 到仓颉 public surface。

## 验证摘录

- 新增 native probe：通过。
- `cjpm build --target-dir /tmp/cjgui-renderer-automation-stage-target --skip-script`：通过。
- 全量 native bridge probe 回归：通过。
- 旧 guard 已重新确认仍阻断 `NSApplication`、drawable / present / commit / encoder / pointer return。

## 风险与边界

本阶段创建的是不可见 `NSWindow` 对象 token，不执行 visible order，不创建 `NSApplication`，不接入 content view，不接入 `CAMetalLayer`，不接入 production drawable acquisition。当前事实只能说明 native token lifecycle 可被 runtime 内部观测。

## 设计意图出口自检

- 新 owner 有中文维护注释，声明 owner / truth / stop-line / Same-shape Boundary Brake。
- canonical tail 从 policy value boundary 推进到 `CjguiInternalRendererVisibleWindowNsWindowHarnessReadiness`，但没有形成 backend-ready truth。
- stop-line 与用户硬约束一致。
- Same-shape Boundary Brake：没有把 probe 或 token lifecycle 包装成 render permission、GPU submission 或 public API。
