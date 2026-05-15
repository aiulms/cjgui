# P1 Renderer 可见窗口 Content View Attachment Manifest

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness NSWindow content-view attachment preflight decision` 到 bounded first slice implementation。阶段完成后，runtime 内部新增 token-backed content-view attachment readiness，production native bridge 新增极窄 C ABI，并通过 native / build / scan 兜底验证。

## 新增或更新的 owner

- Native bridge：`cjgui_native_bridge_nswindow_harness_content_view_*`
- Runtime owner：`CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowContentViewAttachmentDraft()`
- Probe：`verify_native_bridge_nswindow_content_view_attachment.sh`

## 新增 native C ABI

- `cjgui_native_bridge_nswindow_harness_content_view_attach`
- `cjgui_native_bridge_nswindow_harness_content_view_detach`
- `cjgui_native_bridge_nswindow_harness_content_view_attachment_classify`
- `cjgui_native_bridge_nswindow_harness_content_view_double_attach_classify`
- `cjgui_native_bridge_nswindow_harness_content_view_double_detach_classify`
- `cjgui_native_bridge_nswindow_harness_content_view_attach_requires_main_thread`
- `cjgui_native_bridge_nswindow_harness_content_view_visible_order_still_blocked`

## 事实边界

只承认既有 token-backed `NSWindow` 与既有 token-backed `NSView` 之间的 content-view attach / classify / detach lifecycle、main-thread guard、invalid / stale token fail-closed、double attach / detach fail-closed、destroy-before-detach fail-closed 与 cleanup count facts。`NSView` / `NSWindow` token 不是 pointer，不返回 `NSView *`、`NSWindow *`、`id` 或 `Class`。

## 停止线

不调用 `makeKeyAndOrderFront`；不 visible order；不创建 `NSApplication`；不调用 production `nextDrawable`；不创建 command buffer / encoder；不 present / commit / draw / render；不提交 GPU work；不写 renderer state；不扩 public API；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 上游 / 下游

- Upstream：`CjguiInternalRendererVisibleWindowNsWindowHarnessReadiness`
- Current：`CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness`
- Downstream next opening：`P1 internal Renderer visible-window production harness visible-order preflight decision`

## 设计意图出口自检

- manifest 已同步当前 owner、truth、stop-line、canonical tail 与 next opening。
- topic manifest / README / tracker / design intent index 需要同步本 manifest。
- Same-shape Boundary Brake：本 manifest 不授权 visible-ready、drawable-ready、backend-ready、render-ready、GPU submission、renderer state write 或 public API。
