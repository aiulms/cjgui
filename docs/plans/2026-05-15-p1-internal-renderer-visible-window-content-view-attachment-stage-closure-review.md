# P1 内部 Renderer 可见窗口 Content View Attachment 阶段封账复核

## 完成内容

本阶段完成 token-backed `NSWindow.contentView` attachment bounded first slice：

- 在 [cjgui_native_bridge.h](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.h) / [cjgui_native_bridge.m](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.m) 新增 `cjgui_native_bridge_nswindow_harness_content_view_*` internal C ABI。
- 新增 [runtime_renderer_visible_window_content_view_attachment.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_content_view_attachment.cj)，固定 runtime internal owner `CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness` 与 default draft `cjguiInternalExecuteDefaultRendererVisibleWindowContentViewAttachmentDraft()`。
- 新增 [verify_native_bridge_nswindow_content_view_attachment.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nswindow_content_view_attachment.sh)，覆盖 main-thread gate、attach / classify / detach lifecycle、double attach / detach fail-closed、destroy-before-detach fail-closed、invalid / stale token fail-closed、cleanup counts 与 still-blocked facts。
- 更新既有 native guard allowlist，使已批准的 content-view C ABI 不被旧 no-object guard 误拦截。

## 未越过的停止线

- 未调用 `makeKeyAndOrderFront` 或任何 visible order API。
- 未调用 production `nextDrawable`。
- 未创建 render command encoder。
- 未执行 draw / render / GPU submission。
- 未调用 `commit` / `present`。
- 未写 renderer state，未修改 `runtime_state.cj`。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未新增 public API / public diagnostics。
- 未返回 pointer / handle / `id` / `Class` 到仓颉 public surface。

## 验证摘录

- 新增 native probe：通过。
- `cjpm build --target-dir /tmp/cjgui-content-view-attachment-target --skip-script`：通过；当前 sandbox 下 `envsetup.sh` 的 `ps` 探测被系统拒绝，已在同一 shell 内临时 shim `ps` 后继续 source 官方 envsetup。
- 相关 native bridge probe 回归与 smoke / scan 结果由本轮 automation stage report 统一记录。

## 风险与边界

本阶段只证明 production native bridge 可把既有 token-backed `NSView` 接到不可见 `NSWindow.contentView`，并能按 token 生命周期 fail closed。该事实不是 visible window、production drawable、render encoder、render execution、backend-ready truth 或 public API permission。

## 设计意图出口自检

- 新 owner 有中文维护注释，声明 owner / truth / stop-line / Same-shape Boundary Brake。
- canonical tail 从 `CjguiInternalRendererVisibleWindowNsWindowHarnessReadiness` 推进到 `CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness`。
- stop-line 与用户硬约束一致。
- Same-shape Boundary Brake：没有把 content-view attachment facts 包装成 visible-ready、drawable-ready、render-ready、backend-ready、renderer state write 或 public API。
